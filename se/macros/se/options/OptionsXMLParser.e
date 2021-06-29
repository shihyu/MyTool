////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "xml.sh"
#require "BooleanProperty.e"
#require "CategoryHelpPanel.e"
#require "ColorProperty.e"
#require "Condition.e"
#require "DependencyTree.e"
#require "DialogEmbedder.e"
#require "DialogExporter.e"
#require "DialogTagger.e"
#require "ExportImportGroup.e"
#require "NumericProperty.e"
#require "OptionsConfigurationXMLParser.e"
#require "Path.e"
#require "Property.e"
#require "PropertySheet.e"
#require "Select.e"
#require "SelectChoice.e"
#require "TextProperty.e"
#require "se/vc/VersionControlSettings.e"
#import "codehelp.e"
#import "main.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbprops.e"
#import "xmlcfg.e"
#endregion Imports

static const MAX_SEARCH_ADD_COUNT= 1000;
using se.vc.VersionControlSettings;

namespace se.options;

/**
 * Used with options searching and favorites.  Specifies if the
 * node was found itself, or if it has children that were found,
 * or both.
 */
enum_flags NodeFoundFlags {
   CHILD_FOUND,
   SELF_FOUND,
   PARENT_FOUND,
   CAPTION_MATCH,
};

struct CategoryTemplateInfo {
   // index where template is stored
   int node;
   // list of attributes of category
   _str attributes:[];
};

static const VERSION_ATTRIBUTE_NAME=   "SlickEditVersion";

static const NODE_PATH_SEP=   " > ";

static const CATEGORY_TEMPLATE_ATTRIBUTE=             "CategoryTemplate";
static const LANGUAGE_TEMPLATE_NAME=                  "DefaultLanguageInfo";
static const VERSION_CONTROL_PROVIDER_TEMPLATE_NAME=  "DefaultVersionControlInfo";

class OptionsXMLParser {

   // the handle to our XML DOM
   private int m_xmlHandle = 0;
   // the name of the XML file containing our options info
   private _str m_xmlFile = "options.xml";
   // whether we used the default file or one that was sent to us
   private bool m_defaultFile = true;
   // templates of the dialogs which are used as templates
   private DialogTransformer m_templates:[];
   // templates of properties
   private Property m_propTemplates:[];
   // inclusion info to determine if nodes are included in this context
   private bool m_included:[];
   // hashtable of nodes that were found in a search and their parents
   private int m_shownNodes:[];
   // hash table of nodes which are favorites
   private _str m_favorites:[];
   // hash table of protection information for items
   private ProtectedSetting m_protections:[];

   // reads and writes options configuration (history, favorites, protections)
   private OptionsConfigurationXMLParser m_configParser;

   // handle to the file containing user's export groups
   private int m_xmlExportHandle = 0;
   // name of the export groups file
   private _str m_xmlExportFile = "optionsExportGroups.xml";

   // special nodes that we need to know their location
   private int m_topNode = 0;                      // top node of the options tree
   private int m_languageBegin = 0;                // node where Languages section begins
   private int m_categoryTemplates = 0;            // node where category templates section begins
   private int m_dialogTemplates = 0;              // node where dialog templates section begins
   private int m_propertyTemplates = 0;            // node where property template section begins
   private int m_versionControlBegin = 0;          // parent node of version control section

   // what kind of options tree is using us
   private int m_optionsTreePurpose = -1;
   // whether we are importing options from a different platform
   private bool m_crossPlatformImport = false;

   /**
    * Constructor.  Empties the hashtables.  Doesn't initialize
    * anything yet, as we don't have an XML DOM to work with.
    *
    */
   OptionsXMLParser()
   {
      m_templates._makeempty();
      m_included._makeempty();
      m_shownNodes._makeempty();
      m_favorites._makeempty();
   }

   /**
    * Initializes the parser.  Does lots of prep work to the XML file after opening
    * it.
    *
    * @param purpose             the purpose of this run of the options parser (see
    *                            the OptionsPurpose enum)
    * @param file                xml file containing the options
    *
    * @return                    true if file was opened successfully, false
    *                            otherwise
    */
   public bool initParser(int purpose, _str file = "")
   {
      m_optionsTreePurpose = purpose;

      // if we have a file, then we're probably importing
      if (file != "") {
         if (file_exists(file)) {
            m_defaultFile = false;

            // open the file
            if (m_xmlHandle <= 0) {
               m_xmlHandle = _xmlcfg_open(file, auto status, 0, VSENCODING_UTF8);
            }
         }

         // if we were successful, we need to find our special nodes and
         // populate the languages sections
         if (m_xmlHandle > 0) {
            if (!findSpecialNodes()) return false;

            fillInCategoryTemplates();

            bool lang_already_in_category:[];
            initLanguages(lang_already_in_category);
            initVersionControlProviders();

            // load up the relevant configuration stuff
            if (m_configParser.init()) {
               typeless items:[];
               items._makeempty();
               m_configParser.readProtectedItems(items);
               mapConfigurationPathsToXML(items, m_protections);
            }
         }

      } else {
         // otherwise, just use the regular one
         initOptionsDOM();
      }

      // return our success
      return (m_xmlHandle > 0);
   }

   /**
    * Gets the language sections ready for the options dialog.
    */
   private void initLanguages(bool (&lang_already_in_category):[])
   {
      // we are so confused
      if (m_languageBegin <= 0) return;

      // find all the nodes with LangId attributes
      _str langNodes[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@"OPTIONS_XML_LANGUAGE_ATTRIBUTE, langNodes, m_languageBegin);

      for (i := 0; i < langNodes._length();i ++) {
         node := _xmlcfg_get_parent(m_xmlHandle, (int)langNodes[i]);

         // get the mode name and set it as the caption
         langId := _xmlcfg_get_attribute(m_xmlHandle, node, OPTIONS_XML_LANGUAGE_ATTRIBUTE);
         caption := "";
         if (langId != "") {
            lang_already_in_category:[langId]=true;
            caption = _LangGetModeName(langId);
            if (caption == "") {
               caption = getCaption(node);
               if (caption == "") caption = langId;
            }
         }

         _xmlcfg_add_attribute(m_xmlHandle, node, "Caption", caption, VSXMLCFG_ADD_ATTR_AT_BEGINNING);
      }

      // now sort them all by caption
      sortLanguages();
   }

   /**
    * Prepares the version control section.
    */
   private void initVersionControlProviders()
   {
      if (m_versionControlBegin <= 0) return;

      // set the captions to the names
      _str vcps[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@"OPTIONS_XML_VC_PROVIDER_ATTRIBUTE, vcps, m_versionControlBegin);

      for (i := 0; i < vcps._length(); i ++) {
         node := _xmlcfg_get_parent(m_xmlHandle, (int)vcps[i]);

         provId := _xmlcfg_get_attribute(m_xmlHandle, node, OPTIONS_XML_VC_PROVIDER_ATTRIBUTE);
         caption := VersionControlSettings.getProviderName(provId);
         if (caption == "") {
            caption = provId;
         }

         _xmlcfg_add_attribute(m_xmlHandle, node, "Caption", caption, VSXMLCFG_ADD_ATTR_AT_BEGINNING);
      }

      _xmlcfg_sort_on_attribute(m_xmlHandle, m_versionControlBegin, "Caption", 'I');
   }

   /**
    * Initializes the parser for the very specific task of generating search terms
    * for the embedded dialogs.
    *
    * @return              true if the XML DOM was opened properly
    */
   public bool initParserForSearchTagGeneration()
   {
      m_optionsTreePurpose = OP_CONFIG;
      
      file := _getSysconfigPath() :+ "options" :+ FILESEP;
      altLocation := get_env("BUILDSEARCHTAGSALTLOCATION");
      if (altLocation != "") {
         file = altLocation :+ FILESEP"sysconfig"FILESEP"options"FILESEP;
      }
      file :+= m_xmlFile;

      if (file_exists(file)) {

         // open the file
         if (m_xmlHandle <= 0) {
            m_xmlHandle = _xmlcfg_open(file, auto status, 0, VSENCODING_UTF8);
         }
      }

      // if we were successful, we need to find our special nodes
      if (m_xmlHandle > 0) {
         if (!findSpecialNodes()) return false;
      }


      // return our success
      return (m_xmlHandle > 0);
   }

   /**
    * Constructs a property sheet from an XML string.
    * 
    * @param xmlInfo       xml info defining the sheet
    * @param ps            property sheet to be populated
    * 
    * @return int          handle to xml file if success, negative 
    *                      value otherwise
    */
   public int buildPropertySheetFromXMLString(_str xmlInfo, PropertySheet &ps)
   {
      // straight xml, no chaser
      tempView := 0;
      origView := _create_temp_view(tempView);

      status := 0;
      do {
   
         // now shove the string in there...gee, i hope it's valid
         insert_line(xmlInfo);
         m_xmlHandle = _xmlcfg_open_from_buffer(tempView, auto openStatus);
   
         // if error, just return that
         if (m_xmlHandle < 0) {
            status = m_xmlHandle;
            break;
         }
   
         // cool, it was a success!
         // there should be only one property sheet in here, so just take the first one
         psNode := _xmlcfg_find_simple(m_xmlHandle, "//PropertySheet");
         if (psNode < 0) {
            status = psNode;
            break;
         }

         ps = buildPropertySheetData(psNode);
         if (ps == null) {
            status = m_xmlHandle;
            break;
         }
      } while (false);

      return status;
   }

   public int buildPropertySheetFromFile(_str psName, PropertySheet &ps)
   {
      status := 0;
      do {
         // use the property sheets file
         file := _getSysconfigMaybeFixPath("options":+FILESEP:+"propertysheets.xml");
         if (!file_exists(file)) {
            status = FILE_NOT_FOUND_RC;
            break;
         }

         // open it up
         m_xmlHandle = _xmlcfg_open(file, auto openStatus, 0, VSENCODING_UTF8);

         // if error, just return that
         if (m_xmlHandle < 0) {
            status = m_xmlHandle;
            break;
         }
   
         // cool, it was a success!
         // there should be only one property sheet in here, so just take the first one
         psNode := _xmlcfg_find_simple(m_xmlHandle, "/PropertySheets/PropertySheet[@Name='"psName"']");
         if (psNode < 0) {
            status = psNode;
            break;
         }

         ps = buildPropertySheetData(psNode);
         if (ps == null) {
            status = m_xmlHandle;
            break;
         }
      } while (false);

      return status;
   }

   /**
    * Initializes the XML DOM used to create the options dialog.
    *
    *
    * @return bool         success of opening XML file and creating
    *                      DOM
    */
   private bool initOptionsDOM()
   {
      // first we check to see if the options have been hotfixed!
      file := _ConfigPath();
      _maybe_append_filesep(file);
      file :+= "hotfixes"FILESEP:+m_xmlFile;

      // make sure we can open this file and that the version is correct
      status := 0;
      if (file_exists(file)) {

         // open the file
         if (m_xmlHandle <= 0) {
            m_xmlHandle = _xmlcfg_open(file, status, 0, VSENCODING_UTF8);
         }

         // check to make sure our version is current
         if (!checkSlickEditVersion()) {
            _xmlcfg_close(m_xmlHandle);
            m_xmlHandle = -1;

            // delete the file so no one can accuse us of being passive aggressive
            delete_file(file);
         }
      }

      // the hotfixes dir file wasn't there or wasn't the right version
      if (m_xmlHandle <= 0) {
         // get xml file sysconfig/options directory
         file = _getSysconfigPath() :+ "options" :+ FILESEP :+ m_xmlFile;

         // open the file
         m_xmlHandle = _xmlcfg_open(file, status, 0, VSENCODING_UTF8);
      }

      // if we were successful, we need to find our special nodes and
      // populate the languages sections
      if (m_xmlHandle > 0) {
         if (!findSpecialNodes()) return false;

         // take out the properties that come under dialogs - they slow
         // down searching and we won't be using them
         if (m_optionsTreePurpose == OP_CONFIG) {
            removeDialogProperties();
         }

         // load up languages
         fillInCategoryTemplates();

         // get the languages ready to go
         bool lang_already_in_category:[];
         initLanguages(lang_already_in_category);

         // add any user-defined languages to the options
         insertUserDefinedLanguages(lang_already_in_category);

         // get the vcps
         initVersionControlProviders();
         // add user vcps
         insertUserDefinedVersionControlProviders();

         generateDynamicSearchTags();

         // load up the relevant configuration stuff
         if (m_configParser.init()) {
            typeless items:[];
            m_configParser.readFavorites(items);
            mapConfigurationPathsToXML(items, m_favorites);
            items._makeempty();
            m_configParser.readProtectedItems(items);
            mapConfigurationPathsToXML(items, m_protections);
         }
      }

      // return our success
      return (m_xmlHandle > 0);
   }

   /**
    * Initializes the user's options export groups file.  This file stores their
    * export groups.  If the file does not yet exist for this user, the default
    * one is used.
    *
    * @return bool         success of opening XML file and creating
    *                      DOM
    */
   private bool initExportGroupsDOM()
   {
      if (m_xmlExportHandle <= 0) {
         // get xml file from user's config directory
         file := _ConfigPath();
         _maybe_append_filesep(file);
         file :+= m_xmlExportFile;

         // if file does not exist, then we use the default one
         int status;
         if (file_exists(file)) {
            m_xmlExportHandle = _xmlcfg_open(file, status, 0, VSENCODING_UTF8);
         } else {
            file = _getSysconfigPath():+"options":+FILESEP:+m_xmlExportFile;
            m_xmlExportHandle = _xmlcfg_open(file, status, 0, VSENCODING_UTF8);
         }
      }

      // return our success
      return (m_xmlExportHandle > 0);
   }

   /**
    * Check the version listed in the options.xml file to make sure it is the
    * same as the current version.
    *
    * @return              true if options version is same as SlickEdit version
    */
   public bool checkSlickEditVersion(bool majorOnly = false)
   {
      // grab the SlickEdit version
      version := getOptionsXMLVersion();

      curVersion := _version();
      return (_version_compare(curVersion, version, majorOnly ? 1 : 3) == 0);
   }

   /**
    * Retrieves the version of SlickEdit associated with the 
    * current xml file. 
    * 
    * @return _str 
    */
   public _str getOptionsXMLVersion()
   {
      // grab the SlickEdit version
      index := _xmlcfg_find_child_with_name(m_xmlHandle, TREE_ROOT_INDEX, "Options");
      return _xmlcfg_get_attribute(m_xmlHandle, index, VERSION_ATTRIBUTE_NAME);
   }

   /**
    * Retrieves the platform listed in the XML file to see where it 
    * originated.  Also retrieves the current platform (as defined 
    * by options dialog). 
    * 
    * @param curPlatform 
    * @param importFilePlatform 
    *  
    * @return                 true if this is a cross-platform 
    *                         import
    */
   public bool checkCrossPlatformImport(_str &curPlatform, _str &importFilePlatform)
   {
      // grab the platform this import originated on
      index := _xmlcfg_find_child_with_name(m_xmlHandle, TREE_ROOT_INDEX, "Options");
      importFilePlatform = _xmlcfg_get_attribute(m_xmlHandle, index, "Platform");

      // get the current platform
      curPlatform = getPlatform();

      m_crossPlatformImport = (!strieq(curPlatform, importFilePlatform));

      return m_crossPlatformImport;
   }

   /**
    * Occasionally, we may want for the options dialog to have a default start
    * size.  We can get this info from the XML.
    *
    * @param height           default height
    * @param width            default width
    */
   public void getDefaultOptionsDialogSize(int &height, int &width)
   {
      // get the top of the tree and see if it has these attributes
      height = (int)_xmlcfg_get_attribute(m_xmlHandle, m_topNode, "DefaultHeight", "0");
      width = (int)_xmlcfg_get_attribute(m_xmlHandle, m_topNode, "DefaultWidth", "0");
   }

   /**
    * Clears the current search.
    *
    */
   public void clearSearch()
   {
      m_shownNodes._makeempty();
   }

   /**
    * Determines whether a node was found in a search.
    *
    * @param index            the node to look for
    *
    * @return bool            whether the node was found in the search
    */
   public bool wasNodeFoundInSearch(int index)
   {
      return (m_shownNodes:[index] != null && m_shownNodes:[index] & SELF_FOUND);
   }

   /**
    * Determines whether a node caption matched a search.
    *
    * @param index            the node to look for
    *
    * @return bool            whether the node's caption matched 
    *                         the search
    */
   public bool wasNodeCaptionMatchedInSearch(int index)
   {
      return (m_shownNodes:[index] != null && m_shownNodes:[index] & CAPTION_MATCH);
   }

   /**
    * Determines whether a descendant of a node was found in a
    * search.
    *
    * @param index            the node whose children to look for
    *
    * @return bool            whether the node had any descendants
    *                         found in the search
    */
   public bool wasChildOfNodeFoundInSearch(int index)
   {
      return (m_shownNodes:[index] != null && m_shownNodes:[index] & CHILD_FOUND);
   }

   /**
    * Determines whether a parent of a node was found in a
    * search.  Must be a direct parent rather than any ancestor.
    *
    * @param index            the node whose parent to look for
    *
    * @return bool            whether the node had its parent
    *                         found in the search
    */
   public bool wasParentOfNodeFoundInSearch(int index)
   {
      return (m_shownNodes:[index] != null && m_shownNodes:[index] & PARENT_FOUND);
   }

   /**
    * Determines any nodes were found in a search.
    *
    * @return bool            whether any nodes were
    *                         found in the search
    */
   public bool wereAnyNodesFound()
   {
      return !m_shownNodes._isempty();
   }

   /**
    * Returns a list of indices that map to properties in the given 
    * property sheet that were found in the last search. 
    * 
    * @param children         list of indices found in the search
    * @param index            parent to check
    */
   public void getFoundPropertiesInSheet(int (&properties)[], int index)
   {
      // go through all the direct children only
      child := _xmlcfg_get_first_child(m_xmlHandle, index);
      while (child > 0) {

         // this was found, so add it
         if (wasNodeCaptionMatchedInSearch(child)) {
            properties :+= child;
         }

         // if this is a property group, then we want to check the properties 
         // inside, too
         if (isAPropertyGroup(child)) {
            getFoundPropertiesInSheet(properties, child);
         }

         // get the next one
         child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
      }
   }

   /**
    * This function goes through the XML and finds all the dialogs which contain
    * tag generation functions.  These functions generate search tags for the
    * dialog.  These tags are then added to existing tags. 
    *  
    * These are dynamic search tags, which means they are generated 
    * every time we run the options dialog.  These values may 
    * change as the user configures SlickEdit.  Static search tags 
    * are generated during the product build process. 
    */
   private void generateDynamicSearchTags()
   {
      // find the default language elements
      _str tagFunctions[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//OptionsTree//Dialog/@TagFunction", tagFunctions);
      _xmlcfg_find_simple_array(m_xmlHandle, "//DialogTemplates//DialogTemplate/@TagFunction", tagFunctions,
                                TREE_ROOT_INDEX, VSXMLCFG_FIND_APPEND);

      foreach (auto node in tagFunctions) {
         // get the function
         function := _xmlcfg_get_value(m_xmlHandle, (int)node);

         index := find_index(function, PROC_TYPE);
         if (index) {
            tags := "";

            // call the function
            dialogNode := _xmlcfg_get_parent(m_xmlHandle, (int)node);
            lang := getLanguage(dialogNode);

            if (lang == "") tags = call_index(index);
            else tags = call_index(lang, index);

            if (tags != "") {

               // check for hyphens...they can be tricksy
               lastPos := pos('-', tags);
               while (lastPos){

                  prevSpace := lastpos(' ', substr(tags, 1,  lastPos - 1)) + 1;

                  nextSpace := pos(' ', tags, lastPos);
                  if (nextSpace > 0) nextSpace = nextSpace - prevSpace;
                  else nextSpace = -1;

                  word := substr(tags, prevSpace, nextSpace);
                  tags :+= " "stranslate(word, '', '-');

                  lastPos = pos('-', tags, lastPos + 1);
               }

               // add these to the existing tags
               tags = _xmlcfg_get_attribute(m_xmlHandle, dialogNode, "Tags", "") :+ lowcase(tags);
               _xmlcfg_set_attribute(m_xmlHandle, dialogNode, "Tags", tags);
            }
         }
      }
   }

   /**
    * Sometimes we keep the templates in a separate file.  This
    * finds the template file and loads the templates into the main
    * xml file.
    */
   private void maybeLoadTemplateFile()
   {
      // see if the templates are kept in another file
      optionsNode := _xmlcfg_find_child_with_name(m_xmlHandle, TREE_ROOT_INDEX, "Options");
      templateFile := _xmlcfg_get_attribute(m_xmlHandle, optionsNode, "TemplateFile", "");
      if (templateFile != "") {

         // the template file is kept in the same dir as the options file
         templateFile = absolute(templateFile, _strip_filename(_xmlcfg_get_filename(m_xmlHandle), 'N'));

         if (file_exists(templateFile)) {
            templateHandle := _xmlcfg_open(templateFile, auto status);

            // get the top level templates node
            templatesNode := _xmlcfg_find_child_with_name(templateHandle, TREE_ROOT_INDEX, "Templates");
            
            // copy everything underneath the top level node
            _xmlcfg_copy(m_xmlHandle, optionsNode, templateHandle, templatesNode, VSXMLCFG_COPY_CHILDREN);
            _xmlcfg_close(templateHandle);
         }
      }
   }

   /**
    * Finds any categories that are using templates inserts the
    * named template into place.
    */
   private void fillInCategoryTemplates()
   {
      // in the case of import, we don't deal with this
      if (m_categoryTemplates == -1) return;

      // we keep template info in here
      CategoryTemplateInfo templatesTable:[];

      // find everything that is using a CategoryTemplate
      _str ctnodes[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@"CATEGORY_TEMPLATE_ATTRIBUTE, ctnodes, m_topNode);

      // now go through each one and fill in the template
      for (i := 0; i < ctnodes._length(); i++) {
         // get the parent element - not just the attribute node
         categoryNode := _xmlcfg_get_parent(m_xmlHandle, (int)ctnodes[i]);

         // get the template name
         templateName := _xmlcfg_get_attribute(m_xmlHandle, categoryNode, CATEGORY_TEMPLATE_ATTRIBUTE);

         // have we already got the info on this one?
         if (!templatesTable._indexin(templateName)) {

            // no, better find it
            CategoryTemplateInfo templateInfo;
            getCategoryTemplateInfo(templateName, templateInfo);

            // save it!
            if (!templateInfo._isempty()) {
               templatesTable:[templateName] = templateInfo;
            }
         }

         // get the template info for this one
         if (!templatesTable._indexin(templateName)) {
            // if we can't fill in the category, we might as well delete this node
            _xmlcfg_delete(m_xmlHandle, categoryNode);
         } else {
            // do the dirty work
            CategoryTemplateInfo templateInfo = templatesTable:[templateName];
            populateCategoryWithTemplate(categoryNode, templateInfo);
         }
      }
   }

   /**
    * Gets the information needed to insert a template.
    * 
    * @param templateName     name of template
    * @param templateInfo     struct where we're putting the goods
    */
   private void getCategoryTemplateInfo(_str templateName, CategoryTemplateInfo &templateInfo)
   {
      // start with a clean slate
      templateInfo._makeempty();

      // find the template by name
      templateNode := findNodeWithAttribute(templateName, m_categoryTemplates, "Name");
      if (templateNode > 0) {
         // get the info
         templateInfo.node = templateNode;
         _xmlcfg_get_attribute_ht(m_xmlHandle, templateNode, templateInfo.attributes);
      }
   }

   /**
    * Replaces a node with the template specified. 
    *  
    * Copies template children and attributes in.  If the original 
    * node has any attributes or children with the same names, then 
    * the original node values have precedence. 
    * 
    * @param categoryNode        node being replaced with the 
    *                            template
    * @param templateInfo        template info
    */
   private void populateCategoryWithTemplate(int categoryNode, CategoryTemplateInfo &templateInfo)
   {
      // go through the template attributes - if this category node does not have 
      // its own attributes, use the template ones
      foreach (auto attrName => auto attrValue in templateInfo.attributes) {
         // is this already there?
         if (_xmlcfg_get_attribute(m_xmlHandle, categoryNode, attrName) == "") {
            // no, add it with the template value
            _xmlcfg_set_attribute(m_xmlHandle, categoryNode, attrName, attrValue);
         }
      }

      // now copy the children
      firstCopy := _xmlcfg_copy(m_xmlHandle, categoryNode, m_xmlHandle, templateInfo.node, VSXMLCFG_COPY_CHILDREN);

      // now, we see if this category had any nodes of its own - we need to integrate 
      // them with the copied template nodes
      // also check for any nodes that might override the template nodes
      int templateCaptions:[];
      int toDelete:[];
      child := _xmlcfg_get_first_child(m_xmlHandle, categoryNode);
      while (child != firstCopy) {

         // this determines where we are going to put this node
         sib := firstCopy;

         // see if this node has the same caption as something in the template - then we replace it
         caption := getCaption(child);

         // if we have not compiled the list of captions under this template, do it now
         // we have do this after the copy, since it is specific to the exact nodes we copied in
         if (!templateCaptions._length()) {
            temp := firstCopy;
            while (temp > 0) {
               templateCaptions:[getCaption(temp)] = temp;
               temp = _xmlcfg_get_next_sibling(m_xmlHandle, temp);
            }
         }

         // see if this caption is in the template already
         if (templateCaptions._indexin(caption)) {
            // get the index
            temp := templateCaptions:[caption];

            // get the next sibling and save it
            sib = _xmlcfg_get_next_sibling(m_xmlHandle, temp);

            // mark the other one to be deleted
            toDelete:[temp] = temp;
         } else {
            // determine the target position from the XML - if there is no attribute,
            // then we just -1 - it will shove this node at the end
            targetPos := (int)_xmlcfg_get_attribute(m_xmlHandle, child, "PositionUnderParent", -1);
            if (targetPos > 0) {
               for (j := 1; j < targetPos && sib > 0; j++) {
                  sib = _xmlcfg_get_next_sibling(m_xmlHandle, sib);
               }
            } else {
               // set this to -1, that way we know to just put it at the end
               sib = -1;
            }
         }

         // copy this node to the proper position
         if (sib > 0) {
            // copy this before the sibling
            _xmlcfg_copy(m_xmlHandle, sib, m_xmlHandle, child, VSXMLCFG_COPY_BEFORE);
         } else {
            // we ran out of sibling nodes, so just copy this as the last thing
            _xmlcfg_copy(m_xmlHandle, categoryNode, m_xmlHandle, child, VSXMLCFG_COPY_AS_CHILD);
         }

         // get next sibling
         nextChild := _xmlcfg_get_next_sibling(m_xmlHandle, child);

         // delete the original
         _xmlcfg_delete(m_xmlHandle, child);

         child = nextChild;
      }

      // go through and delete the template-copied nodes
      // we do this at the end, because sometimes we have 2 child nodes
      // with the same name that are used according to different exclusions
      foreach (auto temp => . in toDelete) {
         _xmlcfg_delete(m_xmlHandle, temp);
      }
   }

   /**
    * Searches for any user-defined languages and puts them in the
    * options tree so that options can be set for them.
    */
   private void insertUserDefinedLanguages(bool (&lang_already_in_category):[])
   {
      userDef := -1;

      CategoryTemplateInfo templateInfo;
      getCategoryTemplateInfo(LANGUAGE_TEMPLATE_NAME, templateInfo);

      // get language specific primary extensions
      _str langs[];
      _GetAllLangIds(langs);
      for (i := 0; i < langs._length(); i++) {
         langId := langs[i];

        // make sure this isn't an installed language
        if (!lang_already_in_category._indexin(langId)) {
            if (userDef < 0) {
               userDef = findOrCreateUserDefinedLanguages();
            }

            // add our new language
            addNewLanguageToXML(langId, userDef, templateInfo);
        }
      }
   }

   /**
    * Adds any user-defined version control providers to the
    * options.
    */
   private void insertUserDefinedVersionControlProviders()
   {
      // make sure we have a version control section
      if (m_versionControlBegin < 0) return;

      // get the version control template that defines the info common to them all
      CategoryTemplateInfo templateInfo;
      getCategoryTemplateInfo(VERSION_CONTROL_PROVIDER_TEMPLATE_NAME, templateInfo);
      if (templateInfo._isempty()) return;

      // get the list of providers
      _str providerList[];
      VersionControlSettings.getProviderList(providerList);

      for (i := 0; i < providerList._length(); i++) {
         // for non-system providers, add them to the XML
         // make sure it's not already there
         if (!VersionControlSettings.isSystemProvider(providerList[i]) && findVersionControlNode(providerList[i]) < 0) {
            addNewVersionControlProviderToXML(providerList[i], templateInfo);
         }
      }

   }

   /**
    * Adds a new version control provider to the Options XML.  This
    * is added to the DOM, but is not saved to the actual
    * XML file.
    *
    * @param vcName      name of new vc provider
    */
   public int addNewVersionControlProviderToXML(_str vcName, CategoryTemplateInfo &templateInfo = null)
   {
      if (m_versionControlBegin < 0) return -1;

      if (templateInfo == null) {
         getCategoryTemplateInfo(VERSION_CONTROL_PROVIDER_TEMPLATE_NAME, templateInfo);
         if (templateInfo._isempty()) return -1;
      }

      // now add in this new vcp
      vcIndex := 0;
      child := _xmlcfg_get_first_child(m_xmlHandle, m_versionControlBegin);
      if (child > 0) {
         // put it in alphabetically
         while (child > 0 && strcmp(vcName, getCaption(child)) > 0) {
            child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
         }

         if (child < 0) {
            vcIndex = _xmlcfg_add(m_xmlHandle, m_versionControlBegin, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_AS_CHILD);
         } else {
            vcIndex = _xmlcfg_add(m_xmlHandle, child, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_BEFORE);
         }
      } else {
         // just put it in
         vcIndex = _xmlcfg_add(m_xmlHandle, m_versionControlBegin, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                             VSXMLCFG_ADD_AS_CHILD);
      }

      // set caption attribute
      _xmlcfg_add_attribute(m_xmlHandle, vcIndex, "Caption", vcName);

      // set provider id attribute
      _xmlcfg_add_attribute(m_xmlHandle, vcIndex, OPTIONS_XML_VC_PROVIDER_ATTRIBUTE, VersionControlSettings.getProviderID(vcName));

      populateCategoryWithTemplate(vcIndex, templateInfo);

      return vcIndex;
   }

   /**
    * Removes a version control provider from the XML DOM.
    *
    * @param providerName   provider to be removed
    *
    * @return _str      topmost path that was deleted (the
    *                   category for the provider)
    */
   public _str removeVersionControlProviderFromXML(_str providerName, int (&removedIndices)[])
   {
      _str path;

      // look in the languages section - is there a category with this mode name as caption?
      index := findNodeWithAttribute(providerName, m_versionControlBegin);
      if (index > 0) {

         // save the path (to update our navigation history)
         path = getXMLNodeCaptionPath(index);

         // delete it then
         // go through it's children - we want their indices so we know what we deleted
         child := _xmlcfg_get_first_child(m_xmlHandle, index);
         while (child > 0) {
            removedIndices :+= child;
            child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
         }

         removedIndices :+= index;
         _xmlcfg_delete(m_xmlHandle, index);

         removePathFromFavorites(path);
         removePathFromProtections(path);
      }
      return path;
   }

   /**
    * Renames a language in the currently opened XML DOM.  We don't
    * need to make this change permanently in the original XML file
    * because that is keyed off the language ID which will not be
    * changed.  However, we do need to make it for the options
    * dialog as it is currently opened.
    *
    * @param oldName old name of the language
    * @param newName new name of the language
    *
    * @return the XML index of the language category
    */
   public int renameLanguage(_str oldName, _str newName)
   {
      index := renameNode(m_languageBegin, oldName, newName);

      return index;
   }

   /**
    * Maps the paths to nodes marked as favorites to their indices in the
    * current XML DOM.  Saves these path/index pairs in a hash table.
    *
    * @param items                  table of paths to objects (input)
    * @param table                  table of index to objects (output)
    */
   private void mapConfigurationPathsToXML(typeless (&items):[], typeless (&table):[], bool objectAsKey = false)
   {
      _str foundPaths:[];
      foundPaths:[""] = m_topNode;

      // for each path, we split it up and find each part individually
      _str path;
      typeless object;
      foreach (path => object in items) {

         if (path == "") continue;

         // maybe we already found this path?  that would be AWESOME.
         if (foundPaths._indexin(path)) {
            table:[foundPaths:[path]] = object;
            continue;
         }

         // split up the path
         _str splitPath[];
         split(path, NODE_PATH_SEP, splitPath);

         pathSoFar := "";
         newPath := "";
         index := 0;
         for (j := 0; j < splitPath._length(); j++) {
            section := strip(splitPath[j]);

            // assemble the path so far
            if (newPath == "") newPath :+= section;
            else newPath :+= NODE_PATH_SEP :+ section;

            // have we already found this path?
            if (foundPaths:[newPath] != null) {
               pathSoFar = newPath;
               continue;
            }

            // search for this part
            index = getIndexOfCaptionPathSection(section, (int)foundPaths:[pathSoFar]);

            // uh-oh...
            if (index < 0) break;

            // add this to what has been found so we don't have to look up
            // the same stuff over and over
            pathSoFar = newPath;
            foundPaths:[pathSoFar] = index;
         }

         // at the end, save the whole path and index to new table
         if (index > 0) {
            if (!objectAsKey) {
                table:[index] = object;
            } else {
                table:[object] = index;
            }
         }

      }

   }

   /**
    * Specifies that a node in the tree is a favorite.  Updates
    * this info in the user's configuration XML.
    *
    * @param index  The node to be favorited
    */
   public void addFavorite(int index)
   {
      // add to our storage
      path := getXMLNodeCaptionPath(index);
      m_favorites:[index] = path;
   }

   /**
    * Specifies that a node in the tree is no longer a favorite.
    * Updates this info in the user's configuration XML.
    *
    * @param index  The node to be un-favorited
    */
   public void removeFavorite(int index)
   {
      // remove from our storage
      m_favorites._deleteel(index);
   }


   /**
    * Determines whether a node has been marked as a favorite.
    *
    * @param index         the node to check
    *
    * @return bool         true if node is favorite, false otherwise
    */
   public bool isNodeFavorited(int index)
   {
      return m_favorites._indexin(index);
   }

   /**
    * Determines whether any nodes have been favorited.
    *
    * @return true if we have any favorite nodes, false otherwise
    */
   public bool doWeHaveAnyFavorites()
   {
      return (m_favorites._length() > 0);
   }

   /**
    * Determines whether the parser is currently connected to an
    * opened XML DOM.
    *
    * @return bool         whether an XML DOM is open
    */
   public bool isOpen()
   {
      return (m_xmlHandle > 0);
   }

   /**
    * Determines whether the given index is a valid node in the options XML DOM.
    *
    * @param index         index to check
    *
    * @return              true if index is valid, false otherwise
    */
   public bool isNodeValid(int index)
   {
      return (_xmlcfg_is_node_valid(m_xmlHandle, index) != 0);
   }

   /**
    * Determines if the given index corresponds to a CHOICE in the XML DOM.  A
    * CHOICE is one of the possible selections for a SELECT property.
    *
    * @param index         index to check
    *
    * @return              true if index points to a CHOICE node, false otherwise
    */
   public bool isAChoice(int index)
   {
      if (index > 0) {
         return (_xmlcfg_get_name(m_xmlHandle, index) == "Choice");
      }

      return false;
   }

   /**
    * Determines whether the given node defines a Property.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a Property, false
    *                      otherwise
    */
   public bool isAProperty(int index)
   {
      if (index > 0) {
         name := _xmlcfg_get_name(m_xmlHandle, index);
         switch (name) {
         case "Select":
         case "Numeric":
         case "Color":
         case "Boolean":
         case "FilePath":
         case "DirectoryPath":
         case "Text":
         case "Property":
            return true;
            break;
         }
      }

      return false;
   }

   /**
    * Determines whether the given node defines a PropertyTemplate.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a PropertyTemplate, false
    *                      otherwise
    */
   public bool isAPropertyTemplate(int index)
   {
      if (index > 0) {
         name := _xmlcfg_get_name(m_xmlHandle, index);
         switch (name) {
         case "SelectTemplate":
         case "NumericTemplate":
         case "ColorTemplate":
         case "BooleanTemplate":
         case "FilePathTemplate":
         case "DirectoryPathTemplate":
         case "TextTemplate":
            return true;
            break;
         }
      }

      return false;
   }

   /**
    * Determines whether the given node defines a PropertySheet.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a PropertySheet, false
    *                      otherwise
    */
   public bool isAPropertySheet(int index)
   {
      if (index > 0) {
         return (_xmlcfg_get_name(m_xmlHandle, index) == "PropertySheet");
      }

      return false;
   }

   /**
    * Determines whether the given node defines a PropertyGroup.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a PropertyGroup, 
    *                      false otherwise
    */
   public bool isAPropertyGroup(int index)
   {
      if (index > 0) {
         return (_xmlcfg_get_name(m_xmlHandle, index) == "PropertyGroup");
      }

      return false;
   }

   /**
    * Determines whether the given node defines a Dialog.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a Dialog, false
    *                      otherwise
    */
   public bool isADialog(int index)
   {
      if (index > 0) {
         return (_xmlcfg_get_name(m_xmlHandle, index) == "Dialog");
      }

      return false;
   }

   /**
    * Determines whether the given node is a template of any kind
    * (Dialog or Property).  This determines whether the node is in
    * its actual options tree context or is in the templates
    * section.
    *
    * @param index
    *
    * @return bool
    */
   private bool isATemplate(int index)
   {
      return (isADialogTemplate(index) || isAPropertyTemplate(index));
   }

   /**
    * Determines whether the given node defines a DialogTemplate.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a DialogTemplate, false
    *                      otherwise
    */
   public bool isADialogTemplate(int index)
   {
      if (index > 0) {
         return (_xmlcfg_get_name(m_xmlHandle, index) == "DialogTemplate");
      }

      return false;
   }

   /**
    * Determines whether the given node defines a Dialog.
    *
    * @param index         node to check
    *
    * @return bool         true if node defines a Dialog, false
    *                      otherwise
    */
   public bool isADialogWithSummaryItems(int index)
   {
      do {

         // is a valid node
         if (index < 0) break;

         // is a dialog
         if (_xmlcfg_get_name(m_xmlHandle, index) != "Dialog") break;

         // has children
         firstChild := _xmlcfg_get_first_child(m_xmlHandle, index);
         if (firstChild < 0) break;

         // child is a summary item
         if (_xmlcfg_get_name(m_xmlHandle, firstChild) != "SummaryItem") break;

         return true;
      } while (false);

      return false;
   }

   /**
    * Determines if the given node is a dialog node containing 
    * properties. 
    * 
    * @param index         node to check
    * 
    * @return bool         true/false
    */
   public bool isADialogWithProperties(int index)
   {
      return isADialog(index) && canDialogBeBuiltAsPropertySheet(index);
   }

   /**
    * Determines whether one node is a descendant of another.
    *
    * @param parent        possible ancestor node
    * @param child         possible descendant node
    *
    * @return bool         whether node is a descendant
    */
   public bool isChildOf(int parent, int child)
   {
      // keep getting parent until we have a match or until we reach the top of the tree
      ancestor := _xmlcfg_get_parent(m_xmlHandle, child);
      while (ancestor != 0 && ancestor != parent) {
         ancestor = _xmlcfg_get_parent(m_xmlHandle, ancestor);
      }

      return (ancestor == parent);
   }

   /**
    * We keep track of certain nodes to help navigation around the
    * tree.  In this method, we find them.
    *
    * @return bool         true if successful, false otherwise
    */
   private bool findSpecialNodes()
   {
      // find the very top node
      m_topNode = _xmlcfg_find_simple(m_xmlHandle, "//OptionsTree");

      // if we can't find this one, there's no hope
      if (m_topNode < 0) return false;

      // find our language specific and version control begin
      m_languageBegin = findNodeWithAttribute("Languages");
      m_versionControlBegin = findNodeWithAttribute("Version Control Providers");

      // see if the templates are kept in another file
      maybeLoadTemplateFile();

      // find category templates section
      m_categoryTemplates = _xmlcfg_find_simple(m_xmlHandle, "//CategoryTemplates");

      // find beginning of dialog templates
      m_dialogTemplates = _xmlcfg_find_simple(m_xmlHandle, "//DialogTemplates");

      // find beginning of property templates
      m_propertyTemplates = _xmlcfg_find_simple(m_xmlHandle, "//PropertyTemplates");

      return true;
   }

   /**
    * Closes the options dialog, writing changes made within.  Made only for the
    * specific case of generating search tags for the dialogs.  You better know
    * what you're doing if you call this.
    */
   public void closeAndWriteOptionsDOM()
   {
      _xmlcfg_save(m_xmlHandle, 4, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);
      _xmlcfg_close(m_xmlHandle);

      m_xmlHandle = 0;
   }

   /**
    * Closes connections with XML files, doing any saving that
    * needs to be done.
    *
    */
   public void closeOptionsDOM()
   {
      // close the regular DOM
      _xmlcfg_close(m_xmlHandle);

      if (m_defaultFile) {
         m_configParser.writeFavorites(m_favorites);
      } else m_configParser.writeProtections(m_protections);

      m_configParser.close();

      m_xmlHandle = 0;
   }

   /**
    * Closes the connection to an Export XML DOM.  Optionally saves any changes we
    * have made.
    */
   public void closeExportDOM()
   {
      if (m_xmlExportHandle > 0) {
         _xmlcfg_close(m_xmlExportHandle);
      }

      m_xmlExportHandle = 0;
   }

   /**
    * Clears all the info saved within the parser.
    *
    */
   public void clear()
   {
      m_xmlHandle = m_languageBegin = 0;
      m_templates._makeempty();
      m_included._makeempty();
      m_shownNodes._makeempty();
      m_favorites._makeempty();
   }

   /**
    * Determines whether the given node is the Search Results node.
    *
    * @param index         the node to check
    *
    * @return bool         true if node is search node, false
    *                      otherwise
    */
   public bool isSearchResultsNode(int index)
   {
      return (getCaption(index) == "Search Results");
   }


   /**
    * Determines whether a particular index still maps to a particular path.
    *
    * @param path   path to check
    * @param index  index to check
    *
    * @return true if path maps to index, false otherwise
    */
   public bool isIndexPathPairValid(_str path, int index)
   {
      // follow the path and see if it winds up at the index
      pathIndex := findNodeByPath(path);
      return (pathIndex == index);
   }

   /**
    * Finds a node by examining its caption path.  Also finds the index of each caption in the path.
    *
    * @param path          node path to find
    * @param pathIndices   array of indices that will be populated
    *                         with all the indices found in the
    *                         path
    *
    * @return int          index of node that path describes
    */
   public int findNodeByPath(_str path, int (&pathIndices)[] = null)
   {
      // check for delimiter - they designate children
      _str a[];
      split(path, NODE_PATH_SEP, a);
      index := m_topNode;

      if (a._length() == 1) {
         return getIndexOfCaptionPathSection(path, index);
      }

      // find each section of the path and save it
      int i;
      for (i = 0; i < a._length(); i++) {
         index = getIndexOfCaptionPathSection(strip(a[i]), index);

         if (index < 0 && i == a._length() - 1) {
            index = maybeFindPropertyWithCaption(strip(a[i]), pathIndices[i - 1]);
         }
         if (index < 0) break;

         pathIndices[i] = index;
      }

      // did we find it?
      if (pathIndices != null && !pathIndices._isempty()) {
         return pathIndices[pathIndices._length() - 1];
      } else {
         return -1;
      }
   }

   /**
    * Tries to find a property with the given caption under the parent node (which 
    * must be a property sheet or property group if you expect to find anything.) 
    * This checks the property templates for the caption and then determines if any 
    * properties referencing matching templates fall under the parent node. 
    * 
    * @param caption                caption we are seeking
    * @param parent                 property sheet or group node
    * 
    * @return                       matching property
    */
   private int maybeFindPropertyWithCaption(_str caption, int parent)
   {
      // we may be dealing with templates, which might not necessarily have captions...
      if (isAPropertySheet(parent) || isAPropertyGroup(parent)) {
         // see if we can find a template with this caption
         // find the attribute node(s)
         searchString := "//@Caption[file-eq(., '"caption"')]";
         _str a[];

         if (m_propertyTemplates > 0) {
            firstTemplate := _xmlcfg_get_first_child(m_xmlHandle, m_propertyTemplates);
            _xmlcfg_find_simple_array(m_xmlHandle, searchString, a, firstTemplate);

            // now see if this template is used by any properties in our group
            for (i := 0; i < a._length(); i++) {
               templateIndex := _xmlcfg_get_parent(m_xmlHandle, (int)a[i]);
               templateName := _xmlcfg_get_attribute(m_xmlHandle, templateIndex, "Name");
               propertyIndex := findNodeWithAttribute(templateName, parent, "PropertyTemplate");
               if (propertyIndex > 0) {
                  return propertyIndex;
               }
            }
         }
      }

      return -1;
   }

   /**
    * Returns the index of a partial caption path.  This path may contain version
    * control or language information rather than the explicity caption text.
    *
    * @param section             caption of section (or language/vc provider info)
    * @param parent              parent of section that we are looking for
    *
    * @return                    index of section, -1 if not found
    */
   private int getIndexOfCaptionPathSection(_str section, int parent)
   {
      caption := section;
      attribName := "Caption";

      if (pos(OPTIONS_XML_LANGUAGE_ATTRIBUTE"=", section) == 1) {
         parse section with (OPTIONS_XML_LANGUAGE_ATTRIBUTE"=") caption;
         attribName = OPTIONS_XML_LANGUAGE_ATTRIBUTE;
      } else if (pos(OPTIONS_XML_VC_PROVIDER_ATTRIBUTE"=", section) == 1) {
         parse section with (OPTIONS_XML_VC_PROVIDER_ATTRIBUTE"=")caption;
         if (VersionControlSettings.getProviderName(caption) == "") caption = section;
         else attribName = OPTIONS_XML_VC_PROVIDER_ATTRIBUTE;
      }

      return findNodeWithAttribute(caption, parent, attribName);
   }

   /**
    * Deletes a property sheet item.  This should only be used during export, when
    * some nodes are not applicable during the process.
    *
    * @param index               property to be removed
    */
   public void removePropertySheetItem(int index)
   {
      _xmlcfg_delete(m_xmlHandle, index);
   }

   /**
    * Adds a new language to the Options XML.  This language is added to
    * the DOM, but is not saved to the actual XML file.
    *
    * @param langId        langid of new language
    * @param userDef       index of user defined languages node
    * @param templateInfo  default template used to populate the 
    *                      languages in the options
    *
    * @return              index of new language
    */
   public int addNewLanguageToXML(_str langId, int userDef = -1, CategoryTemplateInfo &templateInfo = null)
   {
      if (userDef == -1) {
         // look in the languages section - is there a category called "User-Defined"?
         userDef = findOrCreateUserDefinedLanguages();
         if (userDef < 0) return -1;
      }

      if (templateInfo == null) {
         getCategoryTemplateInfo(LANGUAGE_TEMPLATE_NAME, templateInfo);
         if (templateInfo._isempty()) return -1;
      }

      modeName := _LangGetModeName(langId);

      // now add in this new language
      modeIndex := 0;
      child := _xmlcfg_get_first_child(m_xmlHandle, userDef);
      if (child > 0) {
         // put it in alphabetically
         while (child > 0 && strcmp(modeName, getCaption(child)) > 0) {
            child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
         }

         if (child < 0) {
            modeIndex = _xmlcfg_add(m_xmlHandle, userDef, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_AS_CHILD);
         } else {
            modeIndex = _xmlcfg_add(m_xmlHandle, child, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                                VSXMLCFG_ADD_BEFORE);
         }
      } else {
         // just put it in
         modeIndex = _xmlcfg_add(m_xmlHandle, userDef, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                             VSXMLCFG_ADD_AS_CHILD);
      }

      // set caption attribute
      _xmlcfg_add_attribute(m_xmlHandle, modeIndex, "Caption", modeName);

      // set language attribute
      _xmlcfg_add_attribute(m_xmlHandle, modeIndex, OPTIONS_XML_LANGUAGE_ATTRIBUTE, langId);

      populateCategoryWithTemplate(modeIndex, templateInfo);

      return modeIndex;
   }

   /**
    * Finds the index where the User-Defined Languages section begins.
    * If that section does not yet exist, it is created and the
    * newly created index is returned.
    *
    * @return int          index of User-Defined Languages section
    */
   private int findOrCreateUserDefinedLanguages()
   {
      userDef := findNodeWithAttribute("User-Defined Languages", m_languageBegin);
      if (userDef < 0) {
         // create a new category
         userDef = _xmlcfg_add(m_xmlHandle, m_languageBegin, "Category", VSXMLCFG_NODE_ELEMENT_START_END,
                               VSXMLCFG_ADD_AS_CHILD);

         // set caption attribute
         _xmlcfg_add_attribute(m_xmlHandle, userDef, "Caption", "User-Defined Languages");

         // set the picture attribute
         _xmlcfg_add_attribute(m_xmlHandle, userDef, "Picture", "user.svg");

         // set help attributes
         _xmlcfg_add_attribute(m_xmlHandle, userDef, "SystemHelp", "");
         _xmlcfg_add_attribute(m_xmlHandle, userDef, "DialogHelp", "");
      }

      return userDef;
   }

   /**
    * Removes a language from the XML DOM.  This must be a
    * language from the user-defined section, as installed
    * languages cannot be deleted.  If the given language was the
    * only one in the user-defined section, that section is removed
    * as well.
    *
    * @param modeName language to be removed
    *
    * @return _str      topmost path that was deleted (either the
    *                   category for the language or the user-defined section)
    */
   public _str removeLanguageFromXML(_str modeName, int (&removedIndices)[])
   {
      _str path;

      // look in the languages section - is there a category with this mode name as caption?
      index := findNodeWithAttribute(modeName, m_languageBegin);
      if (index > 0) {

         // check out the parent - should be the user defined section
         uDef := _xmlcfg_get_parent(m_xmlHandle, index);

         // delete it then
         // go through it's children - we want their indices so we know what we deleted
         child := _xmlcfg_get_first_child(m_xmlHandle, index);
         while (child > 0) {
            removedIndices :+= child;
            child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
         }

         removedIndices :+= index;
         _xmlcfg_delete(m_xmlHandle, index);

         // save the path (to update our navigation history)
         path = getXMLNodeCaptionPath(uDef);

         // if the user-defined section has no children, then delete it as well
         if (_xmlcfg_get_first_child(m_xmlHandle, uDef) < 0) {
            _xmlcfg_delete(m_xmlHandle, uDef);
            removedIndices :+= uDef;
         } else {
            path :+= NODE_PATH_SEP :+ modeName;
         }

         removePathFromFavorites(path);
         removePathFromProtections(path);
      }
      return path;
   }

   /**
    * If a language is deleted, it's possible that it was a
    * favorite.  To maintain a tidy configuration file, we delete
    * it from the favorites list.
    *
    * @param path   path of deleted language
    */
   private void removePathFromFavorites(_str path)
   {
      // see if a favorite has the magic path in it - if so, remove it
      typeless i;
      for (i._makeempty();;) {
         m_favorites._nextel(i);
         if (i._isempty()) break;

         favePath := m_favorites:[i];
         if (pos(path, favePath) == 1) {
            m_favorites._deleteel(i);
         }
      }
   }

   /**
    * Renames a version control provider in the currently opened
    * XML DOM. We don't need to make this change permanently in the
    * original XML file because that is keyed off the provider ID
    * which will not be changed.  However, we do need to make it
    * for the options dialog as it is currently opened.
    *
    * @param oldName old name of the provider
    * @param newName new name of the provider
    *
    * @return the XML index of the provider category
    */
   public int renameVersionControlProvider(_str oldName, _str newName)
   {
      return renameNode(m_versionControlBegin, oldName, newName);
   }

   /**
    * Renames a node.  This comes up in case a user has changed the name of a
    * language or a version control provider and we have to rename that category.
    *
    * Do not need to explicitly change anything in the favorites list, because
    * those are stored by the langID and VCID, which will not be changed when the
    * name changes.
    *
    * @param parent           parent node of whatever node is being changed
    * @param oldName          old name of the node
    * @param newName          new name of the node
    *
    * @return                 the index of the node whose name was changed
    */
   private int renameNode(int parent, _str oldName, _str newName)
   {
      // if only this were the only case...
      if (oldName == newName) return -1;

      // find our old set - look in the appropriate section - is there a category with this name as caption?
      index := findNodeWithAttribute(oldName, parent);
      if (index > 0) {

         // get the old path to rename our favorites
         oldPath := getXMLNodeCaptionPath(index);
         newPath := stranslate(oldPath, newName, oldName"$", 'R');

         // we definitely rename the category
         _xmlcfg_set_attribute(m_xmlHandle, index, "Caption", newName);

         // sort the parent node's children
         parent = _xmlcfg_get_parent(m_xmlHandle, index);
         _xmlcfg_sort_on_attribute(m_xmlHandle, parent, "Caption", 'I');
      }

      return index;
   }

   /**
    * Finds a node with the given attribute name and value.
    *
    * @param value         value of attribute that we are seeking
    * @param parent        node whose children to search
    * @param attribName    attribute name we seek
    *
    * @return              index of node matching our parameters, -1 if none exists.
    */
   private int findNodeWithAttribute(_str value, int parent = -1, _str attribName = "Caption")
   {
      // our default parent is the tree's root
      if (parent < 0) {
         parent = m_topNode;
      }

      // find the attribute node(s)
      searchString := "//@"attribName"[file-eq(., '"value"')]";
      _str a[];
      _xmlcfg_find_simple_array(m_xmlHandle, searchString, a, parent);

      if (a._length()) {

         int intA[];
         for (i := 0; i < a._length(); i++) {
            if ((int)a[i] > 0) {
               // the search returned the attribute, get the parent
               index := _xmlcfg_get_parent(m_xmlHandle, (int)a[i]);

               // make sure it's visible
               if (isNodeCurrentlyVisible(index, true)) {
                  intA :+= index;
               }
            }
         }

         // maybe we found nothing
         if (intA._length() == 0) return -1;

         if (intA._length() == 1) {
            // only one choice
            return intA[0];
         } else {
            // we want the node closest to our parent
            return findHighestLevelNode(intA);
         }
      }

      return -1;
   }

   /**
    * Finds the "highest level" node out of an array of nodes.  The
    * highest level is defined as being closest to the root.
    * Children are closer than grandchildren, and siblings are
    * compared by their order in the tree.
    *
    * @param array  array of nodes to compare
    *
    * @return highest level node
    */
   private int findHighestLevelNode(int array[])
   {
      int levelArray[];
      highLevel := -1;
      i := 0;
      // make an array of all the nodes which are on the same level -
      // the closest level to the root (level 1)
      for (i = 0; i < array._length(); i++) {
         level := determineNodeLevel(array[i]);

         if (highLevel < 0 || level < highLevel) {
            levelArray._makeempty();
            levelArray[0] = array[i];
            highLevel = level;
         } else if (level == highLevel) {
            levelArray :+= array[i];
         }
      }

      // now see which of these nodes is highest up in the tree
      highest := levelArray[0];
      for (i = 1; i < levelArray._length(); i++) {
         if (compareNodePositions(highest, levelArray[i]) == -1) {
            highest = levelArray[0];
         }
      }

      return highest;
   }

   /**
    * Compares two nodes which are on the same level.  Sees which
    * is higher up in the tree.
    *
    * @return                    1  => node1 is higher than node2
    *                            -1 => node2 is higher than node1
    *                            0  => we are confused
    */
   private int compareNodePositions(int node1, int node2)
   {
      // these nodes should have be on the same "level" already
      parent1 := _xmlcfg_get_parent(m_xmlHandle, node1);
      parent2 := _xmlcfg_get_parent(m_xmlHandle, node2);
      while (parent1 != parent2 && parent1 > 0 && parent2 > 0) {
         node1 = parent1;
         node2 = parent2;
         parent1 = _xmlcfg_get_parent(m_xmlHandle, node1);
         parent2 = _xmlcfg_get_parent(m_xmlHandle, node2);
      }

      if (parent1 == parent2) {
         // these nodes are siblings, now figure out which one comes first
         while (node1 > 0) {
            node1 = _xmlcfg_get_next_sibling(m_xmlHandle, node1);
            if (node1 == node2) return 1;
         }

         // we got to the end of the siblings without seeing the second
         // node, so it must have been above this one
         return -1;
      } else if (parent1 < 0) {     // got to the top first - shouldn't happen
         return 1;
      } else if (parent2 < 0) {     // got to the top first - shouldn't happen
         return -1;
      }

      return 0;
   }

   /**
    * Figures out the "level" of the given node.  A level is a
    * generation from the root node.
    *
    * @return level of given node
    */
   private int determineNodeLevel(int node)
   {
      level := -1;
      while (node > 0) {
         level++;
         node = _xmlcfg_get_parent(m_xmlHandle, node);
      }

      return level;
   }

   /**
    * Retrieves the "node caption path,' that is, a path of
    * captions from the root of the tree to this node.
    *
    * @param index         node whose path we want
    *
    * @return              node caption path
    */
   public _str getXMLNodeCaptionPath(int index, bool exactCaption = false, bool includeThis = true)
   {
      if (index < 0) return "";

      // include the current node
      path := "";
      if (includeThis) {
         if (exactCaption) {
            path = _xmlcfg_get_attribute(m_xmlHandle, index, "Caption");
         } else path = getSectionForCaptionPath(index);
      }

      index = _xmlcfg_get_parent(m_xmlHandle, index);

      while (index > 0) {
         // we don't include property groups in this hierarchy
         caption := "";
         if (exactCaption){
            caption = _xmlcfg_get_attribute(m_xmlHandle, index, "Caption");
         } else caption = getSectionForCaptionPath(index);

         // add this section to our path
         if (caption != "") {
            if (path != "") {
               path = caption :+ NODE_PATH_SEP :+ path;
            } else {
               path = caption;
            }
         }
         // get the next one
         index = _xmlcfg_get_parent(m_xmlHandle, index);
      }

      return path;
   }

   /**
    * Returns a section descriptor of this node.  If the node is NOT a language or
    * VC category node, then the caption is returned.  Otherwise, a descriptor is
    * returned which defines the specific vc provider or language.
    *
    * @param index         node to check
    *
    * @return              section descriptor
    */
   private _str getSectionForCaptionPath(int index)
   {
      caption := "";
      language := _xmlcfg_get_attribute(m_xmlHandle, index, OPTIONS_XML_LANGUAGE_ATTRIBUTE);
      vcProvider := _xmlcfg_get_attribute(m_xmlHandle, index, OPTIONS_XML_VC_PROVIDER_ATTRIBUTE);

      if (language != "") caption = OPTIONS_XML_LANGUAGE_ATTRIBUTE"="language;
      else if (vcProvider != "") caption = OPTIONS_XML_VC_PROVIDER_ATTRIBUTE"="vcProvider;
      else caption = _xmlcfg_get_attribute(m_xmlHandle, index, "Caption");

      return caption;
   }

   /**
    * Load up our favorites into the search hash - to the
    * OptionsTree, searching is the same mechanism as seeing only
    * the favorites.
    */
   public void findFavorites()
   {
      int faves[];
      foreach (auto faveIndex => .in m_favorites) {
         faves :+= faveIndex;
      }

      // put them in the search node hash
      createShownNodeTable(faves);
   }

   /**
    * Searches the options for a search term.  Loads the results
    * into the search hash so that only the appropriate nodes can
    * be viewed in the tree.
    *
    * @param searchTerm       the search term to find
    * @param searchOptions    options to send to the search
    *                         D - search help descriptions
    */
   public void searchOptions(_str searchTerm, _str searchOptions = "")
   {
      intersectionSearch(searchTerm, searchOptions);
   }

   private void intersectionSearch(_str searchTerm, _str searchOptions)
   {
      // split the search string up into words
      _str searchWords[];
      split(searchTerm, " ", searchWords);

      int searchHash:[];

      // empty out the search table
      m_shownNodes._makeempty();

      // do a search for each one
      isFirstWord := true;
      foreach (auto word in searchWords) {
         //searchTerm = generateSearchRegex(word);
         searchTerm = word;

         _str found[];
         _str captionsFound[];
         // Without this check, the performance is really bad.
         if (length(word)>1) {
            searchXML(searchTerm, captionsFound, found, searchOptions);
            // add this info to our table
            //captionsFound._
            createIntersectionSearchTable(captionsFound, found, isFirstWord);
            isFirstWord = false;
         }
      }
   }

   private void createIntersectionSearchTable(typeless (&captionsFound)[], typeless (&found)[], bool isFirst = false)
   {
      int combinedHash:[];

      // first the caption matches
      for (i := 0; i < captionsFound._length(); i++) {

         node := (int)captionsFound[i];

         // make sure this node is under the top node, otherwise it's not part of the tree
         if (!isChildOf(m_topNode, node)) continue;

         // make sure this node is even visible
         if (!isNodeCurrentlyVisible(node, true)) continue;

         // if it is the first word, we definitely put it in the table
         if (isFirst) {
            combinedHash:[node] = CAPTION_MATCH | SELF_FOUND;
         } else if (m_shownNodes._indexin(node)) {
            // otherwise, we just keep what it had in the previous round - we only want 
            // something to be SELF_FOUND if that's what it was for each word
            combinedHash:[node] = m_shownNodes:[node];
         } else continue;

         // if the node has children, note that they have a found parent
         markFoundChildren(node, combinedHash, isFirst);
         // same with ancestors
         markFoundAncestors(node, combinedHash, isFirst);
      }


      // now we find the parents of these fine nodes, so we know how to populate the tree
      for (i = 0; i < found._length(); i++) {

         node := (int)found[i];

         // make sure this node is under the top node, otherwise it's not part of the tree
         if (!isChildOf(m_topNode, node)) continue;

         // make sure this node is even visible
         if (!isNodeCurrentlyVisible(node, true)) continue;

         // if already caught this round, then was in the caption list
         if (combinedHash._indexin(node)) continue;

         if (isFirst) {
            // just shove it in there
            combinedHash:[node] = SELF_FOUND;
         } else if (m_shownNodes._indexin(node)) {
            if ((m_shownNodes:[node] | CAPTION_MATCH) != 0) {
               // previously, there was a caption match, but not in this round.  so remove it
               combinedHash:[node] = SELF_FOUND;
            } else {
               // otherwise, we just keep what it had in the previous round - we only want 
               // something to be SELF_FOUND if that's what it was for each word
               combinedHash:[node] = m_shownNodes:[node];
            }
         } else continue;

         // if the node has children, note that they have a found parent
         markFoundChildren(node, combinedHash, isFirst);
         // same with ancestors
         markFoundAncestors(node, combinedHash, isFirst);
      }

      m_shownNodes = combinedHash;
   }

   private void markFoundChildren(int node, int (&combinedHash):[], bool isFirst)
   {
      // if the node has children, note that they have a found parent
      child := _xmlcfg_get_first_child(m_xmlHandle, node);
      while (child != -1) {

         // if this doesn't have a caption, then it's not an option node (just a child of one), so leave it out
         if (getCaption(child) == "") break;

         // we have been here before, break it up
         if (combinedHash._indexin(child) && (combinedHash:[child] & PARENT_FOUND)) {
            break;
         }

         // may not even be visible
         if (isNodeCurrentlyVisible(child)) {
            // we mark PARENT_FOUND as SELF_FOUND - that way, a node's path is considered a matching candidate
            // this is most useful for languages
            if (isFirst) {
               // mark this as just plain SELF_FOUND
               combinedHash:[child] = SELF_FOUND;
            } else if (m_shownNodes._indexin(child)) {
               // add SELF_FOUND to our list of finds
               combinedHash:[child] = SELF_FOUND | m_shownNodes:[child];
            }

            // i <3 recursion
            markFoundChildren(child, combinedHash, isFirst);
         }

         child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
      }
   }

   private void markFoundAncestors(int node, int (&combinedHash):[], bool isFirst)
   {
      // loop through the ancestors and mark them
      parent := _xmlcfg_get_parent(m_xmlHandle, node);
      while (parent != -1) {

         // we have been here before, break it up
         if (combinedHash._indexin(parent) && (combinedHash:[parent] & (SELF_FOUND | CHILD_FOUND))) {
            break;
         }

         if (isFirst) {
            // mark this as just plain CHILD_FOUND
            combinedHash:[parent] = CHILD_FOUND;
         } else if (m_shownNodes._indexin(parent)) {
            // add CHILD_FOUND to our list of finds
            // remove the SELF_FOUND, since it was not SELF_FOUND in this round
            combinedHash:[parent] = CHILD_FOUND | m_shownNodes:[parent];
            combinedHash:[parent] &= ~SELF_FOUND;
         } else break;

         parent = _xmlcfg_get_parent(m_xmlHandle, parent);
      }
   }


   /**
    * Searches the options xml for a search term (which has already been
    * translated into a UNIX regex).
    *
    * @param searchTerm          term to be searched for
    * @param searchOptions       set of search options
    *                            D - advanced search - searches the help
    *                            descriptions
    *
    * @return                    array of nodes found by search
    */
   private void searchXML(_str searchTerm, _str (&captionsFound)[], _str (&found)[], _str searchOptions = "")
   {
      searchOptions = upcase(searchOptions);
      searchCaptions(searchTerm, captionsFound, searchOptions);
      searchDialogs(searchTerm, found, searchOptions);
   }

   /**
    * Removes any properties that fall under a dialog.  These are not used
    * during options configuration.
    */
   private void removeDialogProperties()
   {
      _str a[];

      // delete property groups first, which will get rid of some properties
      searchStr := "//Dialog/PropertyGroup";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode);

      int node;
      foreach (node in a) {
         _xmlcfg_delete(m_xmlHandle, node);
      }

      searchStr = "//Dialog/Property";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode);
      searchStr = "//Dialog/Select";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/Numeric";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/Color";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/Boolean";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/FilePath";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/DirectoryPath";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);
      searchStr = "//Dialog/Text";
      _xmlcfg_find_simple_array(m_xmlHandle, searchStr, a, m_topNode, VSXMLCFG_FIND_APPEND);

      foreach (node in a) {
         _xmlcfg_delete(m_xmlHandle, node);
      }
   }
//#define MAX_SEARCH_ADD_COUNT2 100
   // Now that there's a maximum add count,
   // try to get some resonable samples for many categories.
   private void find_simple_array_special(int handle,_str queryStr, _str (&found)[],bool search_OptionsTree_node_only=false) {
      if (search_OptionsTree_node_only) {
         _xmlcfg_find_simple_array(handle,queryStr,found,m_topNode,VSXMLCFG_FIND_APPEND/*,MAX_SEARCH_ADD_COUNT*/);
      } else {
         _xmlcfg_find_simple_array(handle,queryStr,found,0,VSXMLCFG_FIND_APPEND/*,MAX_SEARCH_ADD_COUNT*/);
      }
      return;
#if 0
      //_message_box('in='found._length());
      int node;
      node=_xmlcfg_get_document_element(handle);
      if (!node) return;
      node=_xmlcfg_get_first_child_element(handle,node);
      while (node>=0) {
         if (_xmlcfg_get_name(handle,node)=='OptionsTree') {
            node2:=_xmlcfg_get_first_child_element(handle,node);
            while (node2>=0) {
#if 0
               //Category Caption="Languages
               if (_xmlcfg_get_name(handle,node2)=='Category' && _xmlcfg_get_attribute(handle,node2,'Caption')=='Languages') {
                  node3:=_xmlcfg_get_first_child_element(handle,node2);
                  while (node3>=0) {
                     _xmlcfg_find_simple_array(handle,queryStr,found,node2,VSXMLCFG_FIND_APPEND,MAX_SEARCH_ADD_COUNT2);
                     node3=_xmlcfg_get_next_sibling_element(handle,node3);
                  }

               } else {
                  _xmlcfg_find_simple_array(handle,queryStr,found,node2,VSXMLCFG_FIND_APPEND,MAX_SEARCH_ADD_COUNT);
               }
#endif
               _xmlcfg_find_simple_array(handle,queryStr,found,node2,VSXMLCFG_FIND_APPEND,MAX_SEARCH_ADD_COUNT);
               node2=_xmlcfg_get_next_sibling_element(handle,node2);
            }
            if (search_OptionsTree_node_only) break;
         } else {
            if (!search_OptionsTree_node_only) {
               _xmlcfg_find_simple_array(handle,queryStr,found,node,VSXMLCFG_FIND_APPEND,MAX_SEARCH_ADD_COUNT);
            }
         }
         node=_xmlcfg_get_next_sibling_element(handle,node);
      }
#endif
   }
   /**
    * Performs a search of all the captions in the XML DOM.  Puts the found nodes
    * into an array.
    *
    * @param searchTerm             term to search for (SlickEdit regex)
    * @param found                  list of found indices to be filled with search
    *                               results
    * @param searchOptions          D - search captions AND help descriptions
    */
   private void searchCaptions(_str searchTerm, _str (&found)[], _str searchOptions)
   {
      _str a[];
      xmlfind_options := "I";

      // first search through the captions
      searchStr := "//@Caption[contains(., '"searchTerm"', '"xmlfind_options"')]";
      find_simple_array_special(m_xmlHandle, searchStr, a);

      // also check for ManualTags
      searchStr = "//@ManualTags[contains(., '"searchTerm"', '"xmlfind_options"')]";
      find_simple_array_special(m_xmlHandle, searchStr, a);

      // we can specify to do a more thorough search
      if (pos('D', searchOptions)) {
         // now search through the help descriptions
         searchStr = "//@DialogHelp[contains(., '"searchTerm"', '"xmlfind_options"')]";
         find_simple_array_special(m_xmlHandle, searchStr, a);
      }

      // translate these nodes from attribute nodes into element nodes
      propertySearchTerm := "";
      dialogSearchTerm := "";
      int attrNode;
      foreach (attrNode in a) {
         node :=_xmlcfg_get_parent(m_xmlHandle, attrNode);

         // if this is a choice under a select, we need to go up until we find the select
         if (isAChoice(node)) {
            // this gets us the choices section
            node = _xmlcfg_get_parent(m_xmlHandle, node);
            // and this gets us the select
            node = _xmlcfg_get_parent(m_xmlHandle, node);
         }

         if (isAPropertyTemplate(node)) {
            name := _xmlcfg_get_attribute(m_xmlHandle, node, "Name");
            propertySearchTerm :+= name'|';

         } else if (isADialogTemplate(node)) {
            // we grab the name of the shared dialog so we can search for other dialogs which use it
            name := _xmlcfg_get_attribute(m_xmlHandle, node, "Name");
            dialogSearchTerm :+= name'|';
         } else {
            found :+= node;
         }
      }
      if (propertySearchTerm != "") {
         // remove last |
         propertySearchTerm = substr(propertySearchTerm, 1, length(propertySearchTerm) - 1);
         searchStr = "//Property"XPATH_CONTAINS("PropertyTemplate", propertySearchTerm, xmlfind_options);
         find_simple_array_special(m_xmlHandle, searchStr, found);
      }

      if (dialogSearchTerm != "") {
         // remove last |
         dialogSearchTerm = substr(dialogSearchTerm, 1, length(dialogSearchTerm) - 1);
         searchStr = "//Dialog"XPATH_CONTAINS("DialogTemplate", dialogSearchTerm, xmlfind_options);
         find_simple_array_special(m_xmlHandle, searchStr, found);
      }
   }

   /**
    * Searches for dialogs in the xml file which contain the specified search
    * text.
    *
    * @param searchTerm          search term to find
    * @param found               array to be populated with found dialogs
    * @param searchOptions       search options
    */
   private void searchDialogs(_str searchTerm, _str (&found)[], _str searchOptions)
   {
      _str a[];
      xmlfind_options := 'I';

      // now search through the dialog search terms
      searchStr := "//Dialog"XPATH_CONTAINS("Tags", searchTerm, xmlfind_options);
      find_simple_array_special(m_xmlHandle, searchStr, a);

      // add these to the found list - they can't be templates because they were found in the main list
      int node;
      foreach (node in a) {
         found :+= node;
      }

      // now search through the dialog templates
      searchStr = "//DialogTemplate"XPATH_CONTAINS("Tags", searchTerm, xmlfind_options);
      find_simple_array_special(m_xmlHandle, searchStr, a);

      // we can specify to do a more thorough search
      if (pos('D', searchOptions)) {
         // now search through the help descriptions
         searchStr = "//DialogTemplate"XPATH_CONTAINS("DialogHelp", searchTerm, xmlfind_options);
         find_simple_array_special(m_xmlHandle, searchStr, a);
      }

      // maybe someone added manual tags to a property sheet
      searchStr = "//PropertySheet"XPATH_CONTAINS("ManualTags", searchTerm, xmlfind_options);
      find_simple_array_special(m_xmlHandle, searchStr, a);

      // are any of these shared dialogs?
      dialogSearchTerm := "";
      int attrNode;
      foreach (node in a) {
         // this is a shared dialog
         if (isADialogTemplate(node)) {
            // we grab the name of the shared dialog so we can search for other dialogs which use it
            name := _xmlcfg_get_attribute(m_xmlHandle, node, "Name");
            dialogSearchTerm :+= name"|";
         } else {
            found :+= node;
         }
      }

      // maybe one last search - phew, i am tired
      if (dialogSearchTerm != "") {
         // remove last |
         dialogSearchTerm = substr(dialogSearchTerm, 1, length(dialogSearchTerm) - 1);

         // one last search, i promise
         searchStr = "//Dialog"XPATH_CONTAINS("DialogTemplate", dialogSearchTerm, 'IU');
         //_xmlcfg_find_simple_array(m_xmlHandle, searchStr, found, m_topNode, VSXMLCFG_FIND_APPEND,MAX_SEARCH_ADD_COUNT);
         find_simple_array_special(m_xmlHandle, searchStr, found, true);
      }
   }

   /**
    * Takes a list of indices and creates a hashtable of the
    * indices and their parents.  Each key in the hash is marked
    * with a NodeFoundStatus.
    *
    * @param found  array of found indices
    */
   private void createShownNodeTable(typeless (&found)[])
   {
      m_shownNodes._makeempty();
      // now we find the parents of these fine nodes, so we know how to populate the tree
      int i;
      for (i = 0; i < found._length(); i++) {

         node := (int)found[i];

         // make sure this node is under the top node, otherwise it's not part of the tree
         if (!isChildOf(m_topNode, node)) continue;

         // make sure this node is even visible
         if (!isNodeCurrentlyVisible(node, true)) continue;

         // insert this node into the hash to note that it is found
         if (m_shownNodes:[node] == null) {                // a new one, note that it is found
            m_shownNodes:[node] = SELF_FOUND;
         } else {
            m_shownNodes:[node] |= SELF_FOUND;             // we already have its child, note that it is found, too
         }

         // if the node has children, note that they have a found parent
         child := _xmlcfg_get_first_child(m_xmlHandle, node);
         while (child != -1) {

            if (m_shownNodes:[child] == null) {                   // a new one, note parent found
               m_shownNodes:[child] = PARENT_FOUND;
            } else {
               m_shownNodes:[child] |= PARENT_FOUND;
            }

            child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
         }

         // loop through the ancestors and mark them
         parent := _xmlcfg_get_parent(m_xmlHandle, node);
         while (parent != -1) {

            if (m_shownNodes:[parent] == null) {                   // a new one, note child found
               m_shownNodes:[parent] = CHILD_FOUND;
            } else {
               m_shownNodes:[parent] |= CHILD_FOUND;

               // break, because everything about here has already been marked previously
               if (m_shownNodes:[parent] & SELF_FOUND) break;
            }

            parent = _xmlcfg_get_parent(m_xmlHandle, parent);
         }
      }
   }

   /**
    * Builds the list of search nodes for use in the Search Results
    * node.  Creates a list of the found nodes and their paths.
    *
    * @return     list of search nodes
    */
   public void buildSearchNodeList(_str (&list)[])
   {
      foreach (auto index => auto foundState in m_shownNodes) {
         if (foundState == null) continue;

         if (((foundState & SELF_FOUND) != 0) && !isSearchResultsNode(index)) {
            list :+= getCaption(index)\tgetXMLNodeCaptionPath(index, true, false);
         }
      }

   }

   /**
    * Builds the options history for the given flags.
    *
    * @param changeFlags         options change flags defining a time range that
    *                            we are interested in.  Only retrieves history
    *                            items that were changed within that range.
    *
    * @return                    array of history items
    */
   public void buildOptionsHistory(int changeFlags, _str (&history)[])
   {
      m_configParser.buildOptionsHistory(changeFlags, history);
   }

   /**
    * Generates a search regex given a string of words.  Regex
    * should search for all possible orders in which search words
    * could be arranged.
    *
    * @param searchTerm          string of search words
    *
    * @return                    search regex
    */
   private _str generateSearchRegex(_str searchTerm)
   {
      _str a[];
      term := stranslate(searchTerm, ' ', '( )#', 'R');

      // make sure and escape any characters that are spooky
      term = _escape_re_chars(term, 'U');

      split(strip(term), ' ',  a);

      ss := '^';
      int i;
      for (i = 0; i < a._length(); i++) {
         ss :+= '(?=.*'a[i]')';
      }

      return ss;

   }

   /**
    * Returns the caption of the given index in the XML DOM.
    *
    * @param xmlIndex      node to check
    *
    * @return              caption of index, null if there is none.
    */
   public _str getCaption(int xmlIndex)
   {
      if (xmlIndex < 0) return "";

      caption := _xmlcfg_get_attribute(m_xmlHandle, xmlIndex, "Caption");
      if (caption == "") {
         // if this is a template node, we may need to get the caption from the template
         template_name := _xmlcfg_get_attribute(m_xmlHandle, xmlIndex, "PropertyTemplate");
         if (template_name != "") {
            if (m_propTemplates._indexin(template_name)) {
               caption = ((Property)m_propTemplates:[template_name]).getCaption();
            } else {          // nope, we must find it
               // find the template
               templateIndex := findNodeWithAttribute(template_name, m_propertyTemplates, "Name");
               caption = getCaption(templateIndex);
            }
         } else {
            template_name = _xmlcfg_get_attribute(m_xmlHandle, xmlIndex, "DialogTemplate");
            if (template_name != "") {
               // have we already retrieved this template?
               if (m_templates:[template_name] != null) {
                  caption = m_templates:[template_name].getCaption();
               } else {          // nope, we must build it
                  // find the shared dialog
                  templateIndex := findNodeWithAttribute(template_name, m_dialogTemplates, "Name");
                  caption = getCaption(templateIndex);
               }
            }
         }
      }

      return caption;
   }

   /**
    * Returns the bitmap picture for the given index inthe XML DOM.
    *
    * @param xmlIndex      node to check
    *
    * @return              picture to use for index, null if there is none.
    */
   public _str getPicture(int xmlIndex)
   {
      if (xmlIndex < 0) return "";
      picture := _xmlcfg_get_attribute(m_xmlHandle, xmlIndex, "Picture");
      if (picture == "") {
         template_name := _xmlcfg_get_attribute(m_xmlHandle, xmlIndex, "DialogTemplate");
         if (template_name != "") {
            // have we already retrieved this template?
            if (m_templates:[template_name] != null) {
               picture = m_templates:[template_name].getPicture();
            } else {          // nope, we must build it
               // find the shared dialog
               templateIndex := findNodeWithAttribute(template_name, m_dialogTemplates, "Name");
               picture = getPicture(templateIndex);
            }
         }
      }
      return picture;
   }

   /**
    * Returns a caption to be used on the options right panel frame.
    *
    * @param xmlIndex      node to get caption for
    *
    * @return              frame caption
    */
   public _str getFrameCaption(int xmlIndex)
   {
      if (xmlIndex < 1) return "";

      // if this is a language node, then we grab the language and the node name
      caption := "";
      if (isLanguageNode(xmlIndex, false)) {
         caption = getCaption(_xmlcfg_get_parent(m_xmlHandle,  xmlIndex)) :+ NODE_PATH_SEP :+ getCaption(xmlIndex);
      } else if (isVersionControlProviderNode(xmlIndex, false)) {
         caption = getCaption(_xmlcfg_get_parent(m_xmlHandle,  xmlIndex)) :+ NODE_PATH_SEP :+ getCaption(xmlIndex);
      } else {
         caption = getCaption(xmlIndex);
      }

      caption = stranslate(caption,  '&&',  '&');
      return caption;
   }

   /**
    * Gets the value of a const, enum, or enum_flag using the
    * string representation of the name.  Can also get the value if
    * a ~ (NOT) has been placed in front of the name.
    *
    * @param flag       name representing a const, enum, or
    *                   enum_flag, either with a preceding ~ or
    *                   not.
    *
    * @return int
    */
   private int getConstWithPossibleNot(_str num, int &status)
   {
      typeless value;
      notPos := pos('[\~]', num, 1, 'ir');
      if (notPos) {
         num = substr(num, 2);

         value = ~(_const_value(num, status));
      } else {
         value = _const_value(num, status);
      }

      // see if this is an int
      if (!status && !isinteger(value)) {
         status = INVALID_NAME_INDEX_RC;
         value = 0;
      }

      return value;
   }

   /**
    * Parses a string representing either 1 or 2 const, enums, or
    * enum_flags ORed or ANDed together.  OR is represented with a
    * pipe (|), while AND is represented as an ampersand (&).
    * Flags can also have a NOT (~) in front.
    *
    * Valid :  VSSEARCHFLAG_PROMPT_WRAP & VSSEARCHFLAG_WRAP
    *          VS_AUTOCLOSE_ENABLED | VS_AUTO_CLOSE_CONFIRMATION
    *          ~VS_AUTOCLOSE_ENABLED | VS_AUTO_CLOSE_CONFIRMATION
    *          ~RF_NOSELDISP
    *
    * @param flag       flag to be parsed
    *
    * @return int       int value
    */
   private int parseFlag(_str flag, int &status)
   {
      value := -1;
      status = 0;

      // first things first...
      if (isnumber(flag)) return (int)flag;

      // check for any ORs, or ANDs
      if (pos('[A-Z|\_]# [\||&] [A-Z|\_]#$', flag, 1, 'R')) {
         _str flag1, flag2, op;
         int nflag1, nflag2;
         status1 := status2 := 0;

         // get values of individual flags
         parse flag with flag1 op flag2;
         nflag1 = getConstWithPossibleNot(flag1, status1);
         nflag2 = getConstWithPossibleNot(flag2, status2);

         status = status1 | status2;

         if (!status) {
            if (strieq(op, '|')) {           // OR them together
               value = nflag1 | nflag2;
            } else {                         // AND them together
               value = nflag1 & nflag2;
            }
         }
      } else {
         value = getConstWithPossibleNot(flag, status);
      }

      return value;
   }


   /**
    * Parses info found in XML regarding how an option is retrieved
    * and set.
    *
    * @param attr       hashtable of attributes
    * @param isBool     whether the option is a boolean
    *
    * @return SettingInfo     SettingInfo object containing
    *                         function's findings
    */
   private SettingInfo parseSettings(_str attr:[], bool isBool, _str langID, _str vcProvider)
   {
      SettingInfo info;
      info.Language = langID;
      info.VCProvider = vcProvider;
      status := 0;
      typeless *pv=attr._indexin("Variable");
      if (pv && *pv:=="def_editorconfig") {
         attr._deleteel("Variable");
         pv=null;
         attr:["DefaultOption"]="VSOPTION_EDITORCONFIG_FLAGS";
      }

      // first we parse HOW the setting is set
      if (pv) {             // setting is retrieved/set by variable

         info.SettingType = VARIABLE;

         // we save the variable name and the index in the names table
         SetVariableInfo svi;
         svi.Name = attr:["Variable"];
         svi.Index = find_index(svi.Name, VAR_TYPE);

         info.SettingTypeInfo = svi;

      } else if (attr._indexin("Function")) {      // setting is retrieved/set by function
         info.SettingType = FUNCTION;

         // we save the function name and the index in the names table
         SetFunctionInfo sfi;
         sfi.Name = attr:["Function"];
         sfi.Index = find_index(sfi.Name, PROC_TYPE);

         info.SettingTypeInfo = sfi;
      } else if (attr._indexin("DefaultOption")) { // setting is retrieved/set by _default_option
         info.SettingType = DEFAULT_OPTION;

         // we save the name of the option and its 'value' - either a flag value or the string (single character)
         SetOptionInfo soi;
         soi.Name = attr:["DefaultOption"];
         if (soi.Name._length() > 1) {
            soi.Value = _const_value(soi.Name, status);
            if (status) return null;
         } else {
            soi.Value = soi.Name;
         }

         info.SettingTypeInfo = soi;

      } else if (attr._indexin("DefaultColor")) {  // setting is retrieved/set by _default_color
         info.SettingType = DEFAULT_COLOR;

         // we save the name of the option and its flag value
         SetDefaultColorInfo scoi;
         scoi.Name = attr:["DefaultColor"];
         scoi.Value = _const_value(scoi.Name, status);
         if (status) return null;

         info.SettingTypeInfo = scoi;
      } else if (attr._indexin("SpellOption")) { // setting is retrieved/set by _spell_option
         info.SettingType = SPELL_OPTION;

         // we save the name of the option and its 'value' - either a flag value or the string (single character)
         SetOptionInfo soi;
         soi.Name = attr:["SpellOption"];
         if (soi.Name._length() > 1) {
            soi.Value = _const_value(soi.Name, status);
            if (status) return null;
         } else {
            soi.Value = soi.Name;
         }

         info.SettingTypeInfo = soi;
      } else if (attr._indexin("LanguageSetting")) { // setting is retrieved/set by se.lang.api.LanguageSettings
         info.SettingType = LANGUAGE_SETTING;

         SetLanguageSettingInfo sloi;
         sloi.Setting = attr:["LanguageSetting"];
         sloi.GetIndex = find_index("se.lang.api.LanguageSettings.get"sloi.Setting, PROC_TYPE);
         sloi.SetIndex = find_index("se.lang.api.LanguageSettings.set"sloi.Setting, PROC_TYPE);
         sloi.CreateNewLang = (m_optionsTreePurpose == OP_IMPORT);

         info.SettingTypeInfo = sloi;
      } else if (attr._indexin("VersionControlSetting")) { // setting is retrieved/set by se.lang.api.LanguageSettings
         info.SettingType = VERSION_CONTROL_SETTING;

         SetVersionControlSettingInfo svcsi;
         svcsi.Setting = attr:["VersionControlSetting"];
         svcsi.GetIndex = find_index("se.vc.VersionControlSettings.get"svcsi.Setting, PROC_TYPE);
         svcsi.SetIndex = find_index("se.vc.VersionControlSettings.set"svcsi.Setting, PROC_TYPE);

         info.SettingTypeInfo = svcsi;
      }

      // now we look at the type of the setting
      if (attr:["Type"] != null) {
         switch (attr:["Type"]) {
         case "bool":
            info.ValueType = BOOL;
            info.BoolInfo.TrueValue = true;
            info.BoolInfo.FalseValue = false;
            break;
         case "int":
            if (isBool) {
               info.ValueType = BOOL;
               info.BoolInfo.TrueValue = 1;
               info.BoolInfo.FalseValue = 0;
            } else {
               info.ValueType = INT;               // any old thing
            }
            break;
         case "long":
            info.ValueType = LONG;
            break;
         case "float":
            info.ValueType = FLOAT;
            break;
         case "string":
            if (isBool) {
               info.ValueType = BOOL;
               info.BoolInfo.TrueValue = "y";
               info.BoolInfo.FalseValue = "n";
            } else {
               info.ValueType = STRING;            // any old thing
            }
            break;
         case "flag":
            // probably a Select - I hope...
            info.ValueType = SELECT_AS_FLAG;
            break;
         }
      } else if (attr:["Flag"] != null) {
         info.ValueType = FLAG;
         FlagInformation f;
         f.Name = attr:["Flag"];
         f.Value = parseFlag(f.Name, status);
         if (status) return null;

         info.Flags._makeempty();
         info.Flags[0] = f;
      } else if (attr:["BackwardsFlag"] != null) {
         info.ValueType = BACKWARDS_FLAG;
         FlagInformation f;
         f.Name = attr:["BackwardsFlag"];
         f.Value = parseFlag(f.Name, status);

         if (status) return null;
         info.Flags._makeempty();
         info.Flags[0] = f;
      }

      // the resolution is used to change number values by either dividing or multiplying them by a factor
      if (attr:["Resolution"] != null) {
         _str oper, res;
         parse attr:["Resolution"] with oper res;
         info.ResInfo.Value = (int)res;
         info.ResInfo.Divide = (strieq(oper, "/"));
      }

      // for booleans, we can set them to something other than a simple true/false or 1/0
      if (attr._indexin("TrueValue")) {
         if (attr:["Type"] == "int") {
            info.BoolInfo.TrueValue = parseFlag(attr:["TrueValue"], status);
         } else {
            info.BoolInfo.TrueValue = attr:["TrueValue"];
         }
      }
      if (attr._indexin("FalseValue")) {
         if (attr:["Type"] == "int") {
            info.BoolInfo.FalseValue = parseFlag(attr:["FalseValue"], status);
         } else {
            info.BoolInfo.FalseValue = attr:["FalseValue"];
         }
      }
      // Allow per item checkable items
      checkbox := (attr:["Checkbox"] == "True");
      if (checkbox) {
         info.GetCheckState=true;
      }

      return info;
   }

   /**
    * Determines whether a string is the name of a const, enum, or
    * enum_flag, then translates it and returns the value.
    *
    * @param string     string that possibly is a const, enum, or
    *                   enum_flag
    * @param value      integer value represented by string
    *
    * @return bool      whether string was a const in disguise
    */
   private bool isConstValue(_str string, _str& value)
   {
      status := 0;
      constValue := parseFlag(string, status);
      if (!status) {
         value = constValue;
         return true;
      }

      return false;
   }

   /**
    * Parses the XML containing info about any events that need to happen whenever
    * a property or dialog is modified.
    *
    * @param index         index to check for events
    * @return              int representing the events associated with this node
    */
   private OptionsChangeEventFlags parseChangeEvents(int index)
   {
      eventFlags := OCEF_NONE;

      index = _xmlcfg_get_first_child(m_xmlHandle, index);
      while (index > 0) {

         // see if this has any restrictions based on the options purpose
         type := _xmlcfg_get_attribute(m_xmlHandle, index, "OptionsTreeType");
         if (type == "" || isThisOptionsTreePurposeInList(type)) {
            // now get the flag and use it!
            type = _xmlcfg_get_attribute(m_xmlHandle, index, "Type");
            if (type != "") {
               status := 0;
               flag := (OptionsChangeEventFlags)_const_value(type, status);
               if (!status) {
                  eventFlags |= flag;
               }
            }
         }

         index = _xmlcfg_get_next_sibling(m_xmlHandle, index);
      }

      return eventFlags;
   }

   /**
    * Parses the XML containing info about the choices in a Select
    * option.  Add these choices to the Select s.
    *
    * @param s       Select to receive choices
    * @param index   index in the XML of the Select
    */
   private void parseSelectChoices(Select &s, int index)
   {
      index = _xmlcfg_get_first_child(m_xmlHandle, index);
      while (index > 0) {
         _str attr:[];
         _xmlcfg_get_attribute_ht(m_xmlHandle, index, attr);

         caption :=  attr:["Caption"];
         value :=  attr:["Value"];

         // check for flags
         constValue := "";
         if (isConstValue(value, constValue)) {
            value = constValue;
         }

         SelectChoice ch(caption, value);

         // make sure this choice does not have any exclusions which
         // would prevent it from being used in this case
         if (checkExclusions(index, attr:["Exclusions"])) {

            conditions :=  attr:["Conditions"];
            if (conditions != null) {
               _str variable;
               parse conditions with variable"="value","conditions;

               while (variable != "") {
                  ch.addCondition(variable, value);
                  parse conditions with variable"="value","conditions;
               }
            }

            choosable := attr:["CanChoose"];
            if (choosable != null && choosable == "False") {
               ch.setChoosable(false);
            }

            isDefault := attr:["Default"];
            if (isDefault != null && isDefault == "True") {
               ch.setDefault(true);
            }

            s.addChoice(ch);
         }

         index = _xmlcfg_get_next_sibling(m_xmlHandle, index);
      }
   }

   /**
    * Parses the XML containing info about the choices in a Select
    * option.  Add these choices to the Select s.
    *
    * @param s       Select to receive choices
    * @param index   index in the XML of the Select
    */
   private void retrieveSelectChoices(Select &s, _str info)
   {
      // this should be a function name that takes an array by reference
      index := find_index(info, PROC_TYPE);

      // get our array
      _str list;
      call_index(list, index);

      // add the choices
      if (list != null) {
         foreach (auto choice in list) {
            // sometimes the choices are Caption <comma> value, other times, the caption is the value
            caption := value := "";
            parse choice with caption (OPTIONS_CHOICE_DELIMITER) value;

            // sometimes the value and caption are the same!
            if (value :== "") {
               value = caption;
            } else if (value == "") {
               // I know, this looks RIDICULOUS.  But if the value is only spaces, that means we 
               // want to have an actual blank value, instead of being the same as the caption.
               // I promise that I am not crazy, at least with regards to this.
               value = "";
            }

            // we check and see if this is the default choice
            v := defChoice := "";
            parse value with v (OPTIONS_CHOICE_DELIMITER) defChoice;

            isDefault := defChoice == "default";
            if (isDefault) value = v;

            SelectChoice ch(caption, value);

            if (isDefault) ch.setDefault(true);

            s.addChoice(ch);
         }
      }
   }

   /**
    * Determines if a particular platform is listed as included or excluded.
    *
    *
    * @param platform               platform to look for
    * @param excl                   string of exclusions to check
    * @param checkForNot            whether we are looking for this platform to be
    *                               excluded or NOT excluded
    *
    * @return                       position of exclusion if it is found, 0 if not
    *                               found
    */
   private int findExclusion(_str platform, _str excl, bool checkForNot = false)
   {
      if (checkForNot) {
         return pos('(^| |,)!'platform'(,|$)', excl, 1, 'IR');
      } else {
         return pos('(^| |,)'platform'(,|$)', excl, 1, 'IR');
      }
   }

   /**
    * Sometimes certain properties of the options.xml file are only relevant during
    * particular uses of the options tree (e.g. only during Configuration or
    * Export).  This checks whether our current options purpose
    * (m_optionsTreePurpose) is included in the given list of purposes.
    *
    * @param list                   list of purposes, delimited by comma
    *
    * @return                       true if our current purpose is in list, false
    *                               otherwise
    */
   private bool isThisOptionsTreePurposeInList(_str list)
   {
      _str listArray[];
      split(list, ',', listArray);

      foreach (auto purpose in listArray) {
         // find the int value of this exclusion
         value := _const_value(purpose);
         if (value == m_optionsTreePurpose) return true;

         // OP_CP_IMPORT does not have a const value, so we have 
         // to check it manually
         if (purpose == "OP_CP_IMPORT" && m_crossPlatformImport) return true;
      }

      return false;
   }

   /**
    * Determines whether a propery is to be included from this run
    * of the program.  When a property is included, it is not
    * visible (as opposed to when it is disabled).  Exclusions
    * include Operating System, Eclipse Plugin, etc.
    *
    * @param excl       exclusion string
    *
    * @return bool      whether property is to be included
    */
   private bool isNodeIncluded(_str excl, _str argument = "")
   {
      included := true;

      do {
         // check for UNIX
         if (_isUnix()) {
            if (findExclusion('UNIX', excl)) {
               included = false;
               break;
            }
         } else {
            // maybe we're excluding everything BUT UNIX
            if (findExclusion('UNIX', excl, true)) {
               included = false;
               break;
            }
         }

         // check for Linux
         if (_isLinux()) {
            if (findExclusion('Linux', excl)) {
               included = false;
               break;
            }
         } else {
            // maybe we're excluding everything BUT Linux
            if (findExclusion('Linux', excl, true)) {
               included = false;
               break;
            }
         }

         // check for Solaris
         if (_isSolaris()) {
            if (findExclusion('Solaris', excl)) {
               included = false;
               break;
            }
         } else {
            // maybe we're excluding everything BUT Linux
            if (findExclusion('Solaris', excl, true)) {
               included = false;
               break;
            }
         }

         // check for NT
         if (_isWindows()) {
            if (findExclusion("NT", excl)) {
               included = false;
               break;
            }
            if (findExclusion("WINDOWS", excl)) {
               included = false;
               break;
            }
         } else {
            if (findExclusion("NT", excl, true)) {
               included = false;
               break;
            }
            if (findExclusion("WINDOWS", excl, true)) {
               included = false;
               break;
            }
         }

         // check for macOS
         if (_isMac()) {
            if (findExclusion("MAC", excl)) {
               included = false;
               break;
            }
         } else {
            if (findExclusion("MAC", excl, true)) {
               included = false;
               break;
            }
         }

         if (findExclusion("OS390", excl, true)) {
            included = false;
            break;
         }

         // check for 64-bit version
         if (machine_bits() == 64) {
            if (findExclusion('64', excl)) {
               included = false;
               break;
            }
         } else {
            // maybe we're excluding everything BUT 64-bit
            if (findExclusion('64', excl, true)) {
               included = false;
               break;
            }
         }
         // check for 32-bit version
         if (machine_bits() == 32) {
            if (findExclusion('32', excl)) {
               included = false;
               break;
            }
         } else {
            // maybe we're excluding everything BUT 64-bit
            if (findExclusion('32', excl, true)) {
               included = false;
               break;
            }
         }

         // check for Eclipse plug-in
         if (isEclipsePlugin()) {
            if (findExclusion("Eclipse", excl)) {
               included = false;
               break;
            }
         } else if (findExclusion("Eclipse", excl, true)) {
            included = false;
            break;
         }

         // OS2386
         if (findExclusion("OS2386", excl, true)) {
            included = false;
            break;
         }
         // now check for feature exclusions
         if (!_haveBackupHistory() && findExclusion("BACKUP_HISTORY", excl, true)) {
            included = false;
            break;
         } else if (_haveBackupHistory() && findExclusion("BACKUP_HISTORY", excl)) {
            included = false;
            break;
         }
         // now check for feature exclusions
         if (!_haveSmartOpen() && findExclusion("SMART_OPEN", excl, true)) {
            included = false;
            break;
         } else if (_haveSmartOpen() && findExclusion("SMART_OPEN", excl)) {
            included = false;
            break;
         }

         if (!_haveCtags() && findExclusion("CTAGS", excl, true)) {
            included = false;
            break;
         } else if (_haveCtags() && findExclusion("CTAGS", excl)) {
            included = false;
            break;
         }

         // now check for feature exclusions
         if (!_haveBuild() && findExclusion("PRO_BUILD", excl, true)) {
            included = false;
            break;
         } else if (_haveBuild() && findExclusion("PRO_BUILD", excl)) {
            included = false;
            break;
         }

         if (!_haveDebugging() && findExclusion("PRO_DB", excl, true)) {
            included = false;
            break;
         } else if (_haveDebugging() && findExclusion("PRO_DB", excl)) {
            included = false;
            break;
         }

         if (!_haveContextTagging() && findExclusion("PRO_CT", excl, true)) {
            included = false;
            break;
         } else if (_haveContextTagging() && findExclusion("PRO_CT", excl)) {
            included = false;
            break;
         }

         if (!_haveVersionControl() && findExclusion("PRO_VC", excl, true)) {
            included = false;
            break;
         } else if (_haveVersionControl() && findExclusion("PRO_VC", excl)) {
            included = false;
            break;
         }

         // now check for feature exclusions
         if (!_haveDiff() && findExclusion("DIFF", excl, true)) {
            included = false;
            break;
         } else if (_haveDiff() && findExclusion("DIFF", excl)) {
            included = false;
            break;
         }

         if (!_haveProMacros() && findExclusion("PRO_MACROS", excl, true)) {
            included = false;
            break;
         }

         if (!_haveBeautifiers()) {
            if (findExclusion("PRO_BEAUT", excl, true)) {
               included = false;
               break;
            }
         } else if (findExclusion("PRO_BEAUT", excl)) {
            included = false;
            break;
         }

         // if we get here then we're still enabled, but we still want to check for functional exclusions
         _str a[];
         split(excl, ",", a);
         int i;
         for (i = 0; i < a._length(); i++) {
            // if it doesn't have any of those things, it must be a function!
            fun := strip(a[i]);
            if (!pos('^!:0,1(WINDOWS|UNIX|NT|OS390|ECLIPSE|MAC|PRO_)', fun, 1, 'IR')) {

               // we allow the use of ! here
               bangFound := false;
               if (pos("!", fun) == 1) {
                  fun = substr(fun, 2);
                  bangFound = true;
               }

               funIndex := find_index(fun, PROC_TYPE);

               // this function should be an exclusion function - that is, when the
               // function returns true, then the node is excluded.
               if (funIndex > 0) {
                  if (argument == "") {
                     included = !call_index(funIndex);
                  } else {
                     included = !call_index(argument, funIndex);
                  }

                  // reverse the value if necessary
                  if (bangFound) {
                     included = !included;
                  }

                  if (!included) return included;
               }
            }
         }

      } while (false);

      return included;
   }

   /**
    * Returns the index of the top node in the Options tree.
    *
    * @return index of top node
    */
   public int getTopOfTree()
   {
      return m_topNode;
   }

   /**
    * Returns a node's first child.  If the actual first child is
    * not visible in this context, then the first visible child is.
    * If a node has no visible children, -1 is returned.
    *
    * @param index      the node to check
    *
    * @return           first visible child index, -1 if there are none
    */
   public int getFirstChild(int index)
   {
      child := _xmlcfg_get_first_child(m_xmlHandle, index);

      // see if this is invisible - we don't want to look at it!
      while (child > 0) {
         if (isNodeCurrentlyVisible(child)) break;

         // get the child after this one (which means the next sibling to the child)
         child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
      }

      return child;
   }

   /**
    * Returns a node's next sibling.  If the actual next sibling is
    * not visible in this context, then the first next sibling
    * is. If a node has no visible siblings, -1 is returned.
    *
    * @param index      the node to check
    *
    * @return           first visible sibling index, -1 if there
    *                   are none
    */
   public int getNextSibling(int index)
   {
      sibling := _xmlcfg_get_next_sibling(m_xmlHandle, index);

      // see if this is invisible - we don't want to look at it!
      while (sibling > 0) {
         if (isNodeCurrentlyVisible(sibling)) break;

         sibling = _xmlcfg_get_next_sibling(m_xmlHandle, sibling);
      }

      return sibling;
   }

   /**
    * Returns a node's previous sibling.  If the actual previous sibling is
    * not visible in this context, then the first previous sibling is. If a node
    * has no visible previous siblings, -1 is returned.
    *
    * @param index      the node to check
    *
    * @return           first visible sibling index, -1 if there
    *                   are none
    */
   public int getPrevSibling(int index)
   {
      sibling := _xmlcfg_get_prev_sibling(m_xmlHandle, index);

      // see if this is invisible - we don't want to look at it!
      while (sibling > 0) {
         if (isNodeCurrentlyVisible(sibling)) break;

         sibling = _xmlcfg_get_prev_sibling(m_xmlHandle, sibling);
      }

      return sibling;
   }

   /**
    * Finds the index of the PropertySheet that contains the given property.
    *
    * @param index                  index of property we want to check
    * @param allowDialogs           whether we want a dialog that may be parent of
    *                               this property
    *
    * @return                       index of PropertySheet (or Dialog), -1 if none
    *                               exists
    */
   public int getPropertySheetWithProperty(int index, bool allowDialogs = false)
   {
      parent := _xmlcfg_get_parent(m_xmlHandle, index);

      while (parent > 0) {
         if (isAPropertySheet(parent)) break;
         if (allowDialogs && isADialog(parent)) break;

         parent = _xmlcfg_get_parent(m_xmlHandle, parent);
      }

      return parent;

   }

   /**
    * Returns the node's parent node in the XML DOM.
    *
    * @param index   node whose parent to return
    *
    * @return        node's parent, -1 if there was an error
    */
   public int getParent(int index)
   {
      if (index < 0) {
         return -1;
      } else return _xmlcfg_get_parent(m_xmlHandle, index);
   }

   /**
    * Searches for a sibling node of the input index with the given
    * caption.
    *
    * @param index      node whose siblings to search
    * @param caption    caption we wish to find
    *
    * @return           index of sibling with given caption, -1 if
    *                   none are found
    */
   public int getSiblingNodeWithCaption(int index, _str caption)
   {
      // get the parent of this node
      index = _xmlcfg_get_parent(m_xmlHandle, index);

      // now we search for the sibling with the name we want
      index = findNodeWithAttribute(caption, index, "Caption");

      // if it's not visible, we can't see it (obviously)
      if (!isNodeCurrentlyVisible(index)) {
         index = -1;
      }

      return index;
   }

   /**
    * Determines if the given node is a 'language' node, meaning it
    * is part of the language subtree.  To be a language node, a
    * node must have a parent node that is a language category.
    *
    * @param index   index to check
    *
    * @return        true if index is language node, false otherwise
    */
   public bool isLanguageNode(int index, bool includeCategories = true)
   {
      // sometimes we do not allow the categories to be included - if this is
      // a category node, the this function will return false after we grab parent
      if (!includeCategories) {
         index = _xmlcfg_get_parent(m_xmlHandle, index);
      }

      // check for the 'Language' attribute
      while (index > 0) {

         language := _xmlcfg_get_attribute(m_xmlHandle, index, OPTIONS_XML_LANGUAGE_ATTRIBUTE, null);
         if (language != null) return true;

         index = _xmlcfg_get_parent(m_xmlHandle, index);
      }

      return false;
   }

   /**
    * Determines if the given node is a 'version control provider'
    * node, meaning it is part of the VC subtree.  To be a VC
    * node, a node must have a parent node that is a VCP
    * category.
    *
    * @param index   index to check
    *
    * @return        true if index is VCP node, false otherwise
    */
   public bool isVersionControlProviderNode(int index, bool includeCategories = true)
   {
      // sometimes we do not allow the categories to be included - if this is
      // a category node, the this function will return false after we grab parent
      if (!includeCategories) {
         index = _xmlcfg_get_parent(m_xmlHandle, index);
      }

      // check for the 'Language' attribute
      while (index > 0) {

         provID := _xmlcfg_get_attribute(m_xmlHandle, index, OPTIONS_XML_VC_PROVIDER_ATTRIBUTE, null);
         if (provID != null) return true;

         index = _xmlcfg_get_parent(m_xmlHandle, index);
      }

      return false;
   }

   /**
    * Checks to see if a node is currently visible.  A node can be
    * invisible in two ways:  it is excluded, which means it is
    * permanently invisible for this run of the options dialog, or
    * it can be invisible, which means it's only currently
    * invisible because of a changeable value.
    *
    * @param index               the node to check
    * @param checkParents        whether to check if the parents of this
    *                            node are invisible (thus rendering
    *                            it invisible)
    *
    * @return                    true if visible, false otherwise
    */
   private bool isNodeCurrentlyVisible(int index, bool checkParents = false)
   {
      // add this for recursion purposes
      if (index <= 0) return true;

      visible := true;
      actualIndex := index;


      // maybe we already saved it?
      if (m_included:[index] == null) {
         // for templates, we don't want to check this, as they are in the templates section,
         // not in their proper options tree context (so may not have language or version control info)
         if (isATemplate(index)) {
            visible=m_included:[index] = true;
         } else {

            // is this a dialog template?  if so we'll have to look at the original
            tempD := _xmlcfg_get_attribute(m_xmlHandle, index, "DialogTemplate");
            if (tempD != "") {

               // see if we have loaded this dialog template
               DialogTransformer dt = m_templates:[tempD];
               if (dt == null) {
                  // nope, but we can still look it up
                  index = findNodeWithAttribute(tempD, m_dialogTemplates, "Name");
               } else {
                  index = dt.getIndex();
               }
            }

            // is this a property template?  if so we'll have to look at the original
            tempD = _xmlcfg_get_attribute(m_xmlHandle, index, "PropertyTemplate");
            if (tempD != "") {

               // see if we have loaded this dialog template
               if (m_propTemplates._indexin(tempD)) {
                  Property p = m_propTemplates:[tempD];
                  index = p.getIndex();
               } else {
                  // nope, but we can still look it up
                  index = findNodeWithAttribute(tempD, m_propertyTemplates, "Name");
               }
            }

            // check for exclusions first - they are not temporary, but permanent for this session of the dialog
            exclusions := _xmlcfg_get_attribute(m_xmlHandle, index, "Exclusions");
            visible = checkExclusions(actualIndex, exclusions);

            // check for options tree purpose exclusions
            if (visible) {
               exclusions = _xmlcfg_get_attribute(m_xmlHandle, index, "OptionsTreeExclusions");
               if (exclusions != null && exclusions != "") {
                  visible = !isThisOptionsTreePurposeInList(exclusions);
               }
            }

            // if it's excluded, we save that value - it won't be changing
            if (!visible) {
               m_included:[actualIndex] = false;
            } else {

               // check for invisible functions
               invisible := _xmlcfg_get_attribute(m_xmlHandle, index, "Invisible");

               if (invisible != null && invisible != "") {
                  // get the index of the function
                  funIndex := find_index(invisible, PROC_TYPE);

                  if (funIndex) visible = call_index(funIndex);
                  else visible = true;
               } else {             // if this node doesn't have an Invisible attribute, we know it's always there
                  m_included:[actualIndex] = true;
               }
            }
         }

      } else {
         visible = m_included:[actualIndex];
      }

      // recurse on parents unless we already know it's invisible
      if (checkParents && visible) {
         index = _xmlcfg_get_parent(m_xmlHandle, actualIndex);
         return isNodeCurrentlyVisible(index, true);
      }

      return visible;
   }

   /**
    * Determines if a node's exclusions prevent it from being used
    * in the options dialog.
    *
    * @param index               index of node
    * @param exclusions          node's exclusions
    *
    * @return bool               true if node can be used, false if
    *                            exclusions prevent it
    */
   private bool checkExclusions(int index, _str exclusions)
   {
      visible := true;
      if (exclusions != null && exclusions != "") {

         // if this is a language node, we call the function using its language
         langOrVCS := "";
         if (isLanguageNode(index)) {
            // get this node's language
            langOrVCS = getLanguage(index);
         } else if (isVersionControlProviderNode(index)) {
            // get this node's version control provider
            langOrVCS = getVersionControlProvider(index);
         }

         visible = isNodeIncluded(exclusions, langOrVCS);
      }
      return visible;
   }

   /**
    * Find a node with the given language as its caption.  Can
    * optionally find a sub-node of the language with a specified
    * caption.
    *
    * @param modeName   mode name (language) to look for
    * @param option     a subnode of this language category to find
    *
    * @return           language node index in XML DOM.  -1 if not found.
    */
   public int findLanguageNode(_str modeName, _str option = "")
   {
      // first find the language node
      index := findNodeWithAttribute(modeName, m_languageBegin);

      // do we find a sub-node?
      if (index != 0 && option != "") {
         index = findNodeWithAttribute(option, index);
      }

      return index;
   }

   /**
    * Find a node with the given version control provider as its
    * caption. Can optionally find a sub-node of the category with
    * a specified caption.
    *
    * @param modeName   version control provider name to look for
    * @param option     a subnode of this version control category
    *                   to find
    *
    * @return           version control node index in XML DOM.  -1
    *                   if not found.
    */
   public int findVersionControlNode(_str vcName, _str option = "")
   {
      // first find the language node
      index := findNodeWithAttribute(vcName, m_versionControlBegin);

      // do we find a sub-node?
      if (index != 0 && option != "") {
         index = findNodeWithAttribute(option, index);
      }

      return index;
   }

   /**
    * Finds the node that refers to the given form name (e.g.
    * _emulation_form).
    *
    * @param form    form name to search for
    *
    * @return        index of referring form, -1 if none are found
    */
   public int findDialogNode(_str form)
   {
      index := findNodeWithAttribute(form, m_topNode, "Form");

      return index;
   }

   /**
    * Constructs a dependency condition based on XML info.
    *
    * @param index   index in XML DOM where Condition info can be found
    *
    * @return        the constructed Condition; if information
    *                cannot be parsed, then null is returned
    */
   private Condition parseCondition(int index, _str langID)
   {
      _str attr:[];
      _xmlcfg_get_attribute_ht(m_xmlHandle, index, attr);
      Condition c = null;
      status := 0;

      // check for the various kinds of condition
      if (attr._indexin("Option")) {
         Condition cond(DT_OPTION);
         cond.setInfo(attr:["Option"]);
         cond.setValue(attr:["Value"]);
         c = cond;
      } else if (attr._indexin("VSAPIFlag")) {
         Condition cond(DT_APIFLAG);
         cond.setValue(_const_value(attr:["VSAPIFlag"], status));

         if (!status) {
            c = null;
         } else {
            c = cond;
         }
      } else if (attr._indexin("Variable")) {
         variable := find_index(attr:["Variable"], VAR_TYPE);
         if (variable > 0) {
            Condition cond(DT_VARIABLE);
            if (attr:["Value"] != null) {
               cond.setComparisonType(CT_STRING);
               cond.setInfo(variable);
               cond.setValue(attr:["Value"]);
            } else if (attr:["Flag"] != null) {
               cond.setComparisonType(CT_FLAG);
               cond.setInfo((int)variable);
               cond.setValue(parseFlag(attr:["Value"], status));

               if (status) cond = null;
            }
            c = cond;
         }
      } else if (attr._indexin("Function")) {
         func := find_index(attr:["Function"], PROC_TYPE);
         if (func > 0) {
            Condition cond(DT_FUNCTION);
            cond.setInfo(func);
            if (attr:["Value"] != null) {
               cond.setValue(attr:["Value"]);
               cond.setComparisonType(CT_STRING);
            } else if (attr:["Flag"] != null) {
               cond.setComparisonType(CT_FLAG);
               cond.setValue(parseFlag(attr:["Flag"], status));

               if (status) cond = null;
            }
            c = cond;
         }
      } else if (attr._indexin("LangCallback")) {
         Condition cond(DT_LANG_CALLBACK);
         cond.setInfo(attr:["LangCallback"]);
         c = cond;
      } else if (attr._indexin("LangInheritsFrom")) {
         Condition cond(DT_LANG_INHERITANCE);
         cond.setInfo(attr:["LangInheritsFrom"]);
         c = cond;
      }

      if (c != null) {
         // check for equals and not equals
         type := _xmlcfg_get_name(m_xmlHandle, index);
         c.setEquals(strieq(type, "Condition"));
         c.setLanguage(langID);
      }

      return c;
   }

   /**
    * Constructs a property dependency set based on XML
    * information.
    *
    * @param index      index in XML to get the info
    *
    * @return           PropertyDependencySet constructed
    */
   private void buildPropertyDependencySet(int index, PropertyDependencySet &pds, _str langID)
   {
      pds.m_all = (strieq(_xmlcfg_get_attribute(m_xmlHandle, index, "Evaluate"), "All"));
      index = _xmlcfg_get_first_child(m_xmlHandle, index);

      while (index > 0) {
         type := _xmlcfg_get_name(m_xmlHandle, index);
         switch (type) {
         // we know this is the bottom level, so parse what we got and get out
         case "Condition":
         case "NotCondition":
            Condition c = parseCondition(index, langID);
            if (c != null) {
               pds.addDependency(c);
            }
            break;
         // recurse for me, sweetheart
         case "CompoundDependency":
            PropertyDependencySet pds2;
            buildPropertyDependencySet(index, pds2, langID);
            pds.addDependency(pds2);
            break;
         // anything else is bad news, so we better just return
         }

         index = _xmlcfg_get_next_sibling(m_xmlHandle, index);
      }
   }

   /**
    * Builds a property object by reading the XML DOM.
    *
    * @param propIndex     index in XML DOM where property info is
    *                      found
    *
    * @return Property     the constructed property.  null if error
    *                      occurred
    */
   private Property buildProperty(int propIndex, _str language, _str vcProvider)
   {
      Property p;
      _str attr:[];
      type := _xmlcfg_get_name(m_xmlHandle, propIndex);
      _xmlcfg_get_attribute_ht(m_xmlHandle, propIndex, attr);

      _str *pVariable=attr._indexin("Variable");
      //translate old def_var names to new def_var names
      actualValue := attr:["ActualValue"];
      if (pVariable) {
         switch (*pVariable) {
         case "def_tagging_cache_size":
            attr:["Variable"]="def_tagging_cache_ksize";
            break;
         case "def_tagging_cache_max":
            attr:["Variable"]="def_tagging_cache_max_ksize";
            break;
         case "def_background_tagging_maximum_kbytes":
            attr:["Variable"]="def_background_tagging_max_ksize";
            break;
         case "def_update_context_max_file_size":
            attr:["Variable"]="def_update_context_max_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_update_statements_max_file_size":
            attr:["Variable"]="def_update_statements_max_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_update_tokenlist_max_file_size":
            attr:["Variable"]="def_update_tokenlist_max_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_max_autosave":
            attr:["Variable"]="def_max_autosave_ksize";
            break;
         case "def_max_mffind_output":
            attr:["Variable"]="def_max_mffind_output_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_maxbackup":
            attr:["Variable"]="def_maxbackup_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_autoreload_compare_contents_max_size":
            attr:["Variable"]="def_autoreload_compare_contents_max_ksize";
            attr._deleteel("Resolution");
            break;
         case "def_background_mfsearch_kbufsize":
            attr:["Variable"]="def_background_mfsearch_ksize";
            break;
         /*case 'def_copy_to_clipboard_warn_mbsize':
            attr:["Variable"]='def_copy_to_clipboard_warn_ksize';
            if ( isinteger(actualValue)) {
               actualValue=(int)actualValue * 1024;
               attr:['ActualValue']=actualValue;
            }
            break;*/
         case "def_word_completion_kmax":
            attr:["Variable"]="def_word_completion_max_ksize";
            break;
         case "def_pmatch_max_kfile_size":
            attr:["Variable"]="def_pmatch_max_ksize";
            break;
         case "def_pmatch_max_diff":
            attr:["Variable"]="def_pmatch_max_diff_ksize";
            break;
         case "def_xml_max_smart_editing":
            attr:["Variable"]="def_xml_max_smart_editing_ksize";
            attr._deleteel("Resolution");
            break;
         }
      }

      // first see if this uses a template
      if (attr:["PropertyTemplate"] != null) {
         pt := attr:["PropertyTemplate"];

         // have we already retrieved this template?
         if (m_propTemplates._indexin(pt)) {
            p = (Property)m_propTemplates:[pt];
         } else {          // nope, we must build it
            // find the template
            tempIndex := findNodeWithAttribute(pt, m_propertyTemplates, "Name");

            // build the template
            p = buildProperty(tempIndex, "", "");

            // save it for posterity
            if (p != null) {
               m_propTemplates:[pt] = p;
            }
         }

         // if this happens, then something is screwy, but it would be nice
         // to handle it gracefully in any case
         if (p != null) {
            p.setLanguage(language);
            p.setVCProvider(vcProvider);
            p.setIndex(propIndex);
            if (actualValue != null) p.setValue(actualValue);
            if (attr._indexin("Caption")) p.setCaption(attr:["Caption"]);
         }

      } else {

         type = stranslate(type, "", "Template");

         // switch on the type of property, then create that type
         switch (type) {
         case "Select":
            Select s(attr:["Caption"], propIndex, attr:["Type"] == "flag");
            if (attr:["Choices"] != null) {     // sometimes we load the choices with a function
               retrieveSelectChoices(s, attr:["Choices"]);
            } else {                            // sometimes we load the choices from xml
               choiceIndex := _xmlcfg_find_child_with_name(m_xmlHandle, propIndex, "Choices");
               parseSelectChoices(s, choiceIndex);
            }

            // do we insert the actual value as a choice if it isn't in there?
            if (attr._indexin("InsertActualValue") && attr:["InsertActualValue"] == "True") s.setInsertChoiceIfNotAvailable(true);
            // maybe turn off sorting of choices
            if (attr._indexin("Sorted") && attr:["Sorted"] == "False") s.setSorted(false);

            p = (Property)s;
            break;
         case "Numeric":
            isInt := (attr:["Type"] == "int");
            NumericProperty n(attr:["Caption"], propIndex, (int)attr:["Min"], (int)attr:["Max"], isInt);
            p = (Property)n;
            break;
         case "Color":
            ColorProperty c(attr:["Caption"], propIndex);
            p = (Property)c;
            break;
         case "Boolean":
            BooleanProperty b(attr:["Caption"], propIndex);
            if (attr._indexin("Choices")) {
               parse attr:["Choices"] with auto fVal "," auto tVal;
               b.setDisplayValues(strip(fVal), strip(tVal));
            }

            p = (Property)b;
            break;
         case "FilePath":
            fileDelim := "";
            if (attr._indexin("SeparatePathsWith")) {
               fileDelim = attr:["SeparatePathsWith"];
            }
            encodeFilePath := (attr._indexin("EncodeEnvironmentVariables")) && (attr:["EncodeEnvironmentVariables"] == "True");

            // we might need to switch the fileseps here
            if (actualValue != null && m_crossPlatformImport) {
               actualValue = stranslate(actualValue, FILESEP, FILESEP2);
            }

            Path f(attr:["Caption"], propIndex, Path.FILEPATH, fileDelim, encodeFilePath);
            p = (Property)f;
            break;
         case "DirectoryPath":
            dirDelim := "";
            if (attr._indexin("SeparatePathsWith")) {
               dirDelim = attr:["SeparatePathsWith"];
            }
            encodeDirPath := (attr._indexin("EncodeEnvironmentVariables")) && (attr:["EncodeEnvironmentVariables"] == "True");

            // we might need to switch the fileseps here
            if (actualValue != null && m_crossPlatformImport) {
               actualValue = stranslate(actualValue, FILESEP, FILESEP2);
            }

            Path d(attr:["Caption"], propIndex, Path.DIRECTORYPATH, dirDelim, encodeDirPath);
            p = (Property)d;
            break;
         case "Text":
            TextProperty t(attr:["Caption"], propIndex);
            p = (Property)t;
            break;
         default:
            p = null;
         }

         if (p != null) {
            if (actualValue != null) p.setValue(actualValue);

            // get the help information
            p.setHelp(attr:["DialogHelp"]);
            addHTMLTagsToPropertyHelp(p);

            if (attr._indexin("Key")) p.setKey(attr:["Key"]);

            // get the setting info and find value
            SettingInfo info = parseSettings(attr, type == "Boolean", language, vcProvider);
            if (info == null) {
               return null;      // if we can't get the value, it's useless.  USELESS!
            }
            p.setSettingInfo(info);

            // check for dependencies
            depIndex := _xmlcfg_find_child_with_name(m_xmlHandle, propIndex, "Dependencies");
            if (depIndex > 0) {
               buildPropertyDependencySet(depIndex, p.m_dependencies, language);
            }

            // check if this property has a special click event
            click := attr:["ChangeFunction"];
            if (click != null) {
               // this should be a function name - change it to an index
               index := find_index(click, PROC_TYPE);
               if (index > 0) {
                  p.setClickEvent(index);
               }
            }

            // see if there are any events
            eventsIndex := _xmlcfg_find_child_with_name(m_xmlHandle, propIndex, "ChangeEvents");
            if (eventsIndex > 0) {
               p.setChangeEventFlags(parseChangeEvents(eventsIndex));
            }

            if (attr._indexin("FunctionKey")) {
               p.setFunctionKey(attr:["FunctionKey"]);
            }

         }

      }

      return p;
   }

   /**
    * Adds HTML tags to specific items in the Property's help info.
    *
    * @param p             Property
    */
   void addHTMLTagsToPropertyHelp(Property &p)
   {
      help := p.getHelp();
      help = addHTMLTagsToPathsInHelp(help);

      // look for property names or values to embolden
      ss := "";
      if (p.getPropertyType() == BOOLEAN_PROPERTY) {
         ss = "{On|Off}";
      } else if (p.getPropertyType() == SELECT_PROPERTY) {
         ((Select)p).getChoices(auto choices, false);
         if (choices._length()) {
            ss = "{";
            for (i := 0; i < choices._length(); i++) {
               item := choices[i];
               // some things have (default) on the end - get rid of it
               if (endsWith(item, "(default)", false, 'I')) {
                  parse item with item "(default)", 'I';
               }
               item = strip(item);
               item = _escape_re_chars(item, 'R');
               if (i) ss :+= "|";
               ss :+= item;
            }
            ss :+= "}";
         }
      }

      if (ss != "") {
         ss = '(^|[~a-z])'ss'([~a-z]|$)';
         addHTMLTags(help, ss, 'b');
      }

      p.setHelp(help);
   }

   /**
    * Makes menu paths bold.  For other options dialog paths,
    * creates a link that will take the user directly to that page.
    *
    * @param help
    *
    * @return _str
    */
   _str addHTMLTagsToPathsInHelp(_str help)
   {
      if (help != null && help != "") {

         // look for menu paths
         ss := '{(File|Edit|Search|View|Project|Build|Debug|Document|Macro|Tools|Window|Help)( >( [A-Z]([a-z]|\x{00AE})#)#)#}';
         addHTMLTags(help, ss, 'b');

         // look for paths to other options...we can make them links!
         ss = '{Tools > Options( >( [A-Z]([a-z]|\x{00AE})#)#)#}';
         addHTMLTags(help, ss, 'a');
      }

      return help;
   }

   /**
    * Adds HTML tags to text in a string.
    *
    * @param string              full string
    * @param searchString        search string - needs to use {}
    *                            matching
    * @param tagType             type of html tag (b, a)
    */
   void addHTMLTags(_str &string, _str searchString, _str tagType)
   {
      if (searchString != "") {

         tagType = lowcase(tagType);

         startPos := 1;
         valPos := pos(searchString, string, startPos, 'R');
         while (valPos > 0) {
            // get the start point and length of our match
            matchStart := pos('S0');
            matchLength := pos('0');

            // split up the string
            before := substr(string, 1, matchStart - 1);
            mid := substr(string, matchStart, matchLength);
            after := substr(string, matchStart + matchLength);

            newMid := mid;
            if (tagType == 'b') {
               // add the boldness - now with new EXTRA BOLD
               if (!pos("Tools > Options",  mid)) {
                  newMid = "<b>"mid"</b>";
               }
            } else if (tagType == "a") {
               // strip off the Tools > Options mess
               path := substr(mid, 19);

               // see if we can even find this path...
               // it might have a property on the end of it, we'll try it
               newPath := path;
               node := findNodeByPath(newPath);
               if (node < 0) {

                  // chop off the last part of the path
                  lp := lastpos(NODE_PATH_SEP, path);
                  newPath = strip(substr(newPath, 1, lp - 1));

                  // try again with a short path
                  node = findNodeByPath(newPath);

                  if (node < 0) {
                     // just forget it
                     newPath = "";
                  }
               }

               if (newPath != "") {
                  // we add this back to the after part
                  pathDiff := substr(path, length(newPath) + 1);
                  mid = substr(mid, 1, length(mid) - length(pathDiff));
                  after = pathDiff :+ after;
                  newMid = '<a href="slickc:config 'newPath'">'mid'</a>';
               }
            }

            // put it back together
            string = before :+ newMid :+ after;

            // now try again!
            startPos = matchStart + matchLength + (length(newMid) - length(mid));
            valPos = pos(searchString, string, startPos, 'R');
         }
      }
   }

   /**
    * Builds the property sheet data from the XML DOM.  This is not
    * to be confused with building the property sheet GUI, which
    * takes the info compiled here and creates the GUI
    * representation of such.
    *
    * @param sheetIndex          XML DOM index where property sheet
    *                            is located
    *
    * @return PropertySheet      the completed property sheet. May
    *                            be null if error occurred
    */
   private PropertySheet buildPropertySheetData(int sheetIndex)
   {
      // can't build the property sheet without this info
      if (m_xmlHandle < 0 || sheetIndex < 0) {
         return null;
      }

      caption := _xmlcfg_get_attribute(m_xmlHandle, sheetIndex, "Caption");
      sysHelp := _xmlcfg_get_attribute(m_xmlHandle, sheetIndex, "SystemHelp", "");
      dialogHelp := addHTMLTagsToPathsInHelp(_xmlcfg_get_attribute(m_xmlHandle, sheetIndex, "DialogHelp", ""));
      PropertySheet ps(caption, sysHelp, dialogHelp);

      checkbox := (_xmlcfg_get_attribute(m_xmlHandle, sheetIndex, "Checkbox", "False") == "True");

      // is this property sheet language specific?
      lang := getLanguage(sheetIndex);
      vcProvider := getVersionControlProvider(sheetIndex);

      // loop through the properties under this PropertySheet
      indexInSheet := 0;
      propIndex := getFirstChild(sheetIndex);
      groupIndex := 0;
      while (propIndex > 0) {

         type := _xmlcfg_get_name(m_xmlHandle, propIndex);
         if (type == "PropertyGroup") {

            // we must build a property group
            groupIndex = propIndex;
            ++indexInSheet;

            numChildren := _xmlcfg_get_num_children(m_xmlHandle, groupIndex);
            PropertyGroup pg(_xmlcfg_get_attribute(m_xmlHandle, groupIndex, "Caption"), numChildren, groupIndex);
            ps.addPropertyTreeMember(pg);

            // loop through the properties under this PropertyGroup
            propIndex = getFirstChild(groupIndex);

         } else {
            // just building a regular property
            Property p = buildProperty(propIndex, lang, vcProvider);
            if (p != null) {
               p.setAddress(sheetIndex, indexInSheet);
               if (checkbox) {
                  p.setCheckable(checkbox);
               }
               ps.addPropertyTreeMember(p);
               ++indexInSheet;
            }

            propIndex = getNextSibling(propIndex);
            if (propIndex < 0 && groupIndex) {
               propIndex = getNextSibling(groupIndex);
               groupIndex = 0;
            }
         }
      }

      return ps;
   }

   /**
    * Determines if the dialog defined at an index is shared.
    * Assumes that the index is already a dialog.
    *
    * @param index      index to check
    *
    * @return           true if the index is shared, false otherwise
    */
   public bool isDialogShared(int index)
   {
      return (_xmlcfg_get_attribute(m_xmlHandle, index, "Shared", "False") == "True");
   }

   /**
    * Builds the right panel of a node which contains reference to
    * a dialog.  Finds the form referenced and loads the template
    * into the right panel of the options form.
    *
    * @param index      index of node in XML DOM
    * @param data       DialogTransformer (or inherited object) to be populated.
    *                   Make sure this object if of the correct type when you call
    *                   this function or things won't work right and you'll have no
    *                   one to blame but yourself.
    *
    * @return int       window id of loaded template
    */
   private void buildDialogTransformer(int index, DialogTransformer &data)
   {
      _str attr:[];
      _xmlcfg_get_attribute_ht(m_xmlHandle, index, attr);
      cap := attr:["Caption"];
      if (cap == null) cap = "";
      pic := attr:["Picture"];
      if (pic == null) pic = "";

      // first see if this uses a dialog template
      if (attr:["DialogTemplate"] != null) {
         dt := attr:["DialogTemplate"];

         // have we already retrieved this template?
         if (m_templates:[dt] != null) {
            data = m_templates:[dt];
         } else {          // nope, we must build it
            // find the shared dialog
            sdIndex := findNodeWithAttribute(dt, m_dialogTemplates, "Name");

            // build the shared dialog transformer
            buildDialogTransformer(sdIndex, data);

            // save it for posterity
            m_templates:[dt] = data;
         }

         data.setCaption(cap);
         data.setPicture(pic);

         // we may also use our own help info
         if (attr:["DialogHelp"] != null) {
            data.setPanelHelp(addHTMLTagsToPathsInHelp(attr:["DialogHelp"]));
         }
         if (attr:["SystemHelp"] != null) {
            data.setSystemHelp(attr:["SystemHelp"]);
         }

      } else {
         data.setCaption(cap);
         data.setPicture(pic);
         data.setPanelHelp(addHTMLTagsToPathsInHelp(attr:["DialogHelp"]));
         data.setSystemHelp(attr:["SystemHelp"]);

         // set form name and parent form name, if one exists
         parentForm := getAllFormAncestors(attr:["InheritsFromForm"]);
         data.setFormName(attr:["Form"], parentForm);

         // we do some special stuff for the specific transformer types...TRANS-FOR-MERS!
         panelType := data.getPanelType();
         switch (panelType) {
         case OPT_DIALOG_EMBEDDER:
            DialogEmbedder dem = (DialogEmbedder)data;

            if (attr:["Height"] != null && attr:["Width"] != null) {
               dem.setDimensions((int)attr:["Height"], (int)attr:["Width"]);
            }

            buildDialogControlList(index, dem);
            data = dem;
            break;
         case OPT_DIALOG_SUMMARY_EXPORTER:
            DialogExporter dex = (DialogExporter)data;

            // see if there are any events
            eventsIndex := _xmlcfg_find_child_with_name(m_xmlHandle, index, "ChangeEvents");
            if (eventsIndex > 0) {
               dex.setChangeEventFlags(parseChangeEvents(eventsIndex));
            }

            data = dex;
            break;
         case OPT_DIALOG_TAGGER:
            if (attr:["TagComplexControls"] != null) {
               DialogTagger dt = (DialogTagger)data;
               dt.setComplexControlsToTag(attr:["TagComplexControls"]);

               data = dt;
            }
            break;
         }
      }

      panelType := data.getPanelType();
      if (panelType == OPT_DIALOG_FORM_EXPORTER) {
         DialogExporter dex = (DialogExporter)data;

         // import stuff...
         if (attr:["ImportArguments"] != null) {
            dex.setImportArguments(attr:["ImportArguments"]);
         }

         if (attr:["ImportFiles"] != null) {
            path := _strip_filename(_xmlcfg_get_filename(m_xmlHandle), 'N');
            files := attr:["ImportFiles"];
            dex.setImportFilenames(path, files);
         }
         data = dex;
      } else if (panelType == OPT_DIALOG_SUMMARY_EXPORTER) {
         DialogExporter dex = (DialogExporter)data;
         if (_xmlcfg_find_child_with_name(m_xmlHandle, index, "SummaryItem") > 0) buildDialogSummary(index, dex);

         data = dex;
      }

      data.setIndex(index);
      data.setLanguage(getLanguage(index));
      data.setVersionControlProvider(getVersionControlProvider(index));
   }

   private _str getAllFormAncestors(_str formName)
   {
      // there is nothing interesting to look at here
      if (formName == null || formName == "") return "";

      ancestorList := formName;

      do {
         // what we need to do now is to find this form
         formNode := findDialogNode(formName);
         if (formNode < 0) break;
            
         // see if we have an inherits from node here
         nextForm := _xmlcfg_get_attribute(m_xmlHandle, formNode, "InheritsFromForm", "");

         // we better call this function again on this next node
         ancestorList = formName","getAllFormAncestors(nextForm);

      } while (false);

      return ancestorList;
   }

   /**
    * Builds a Dialog Summary, which is a list of Properties and values found in a
    * dialog.
    *
    * @param dialogIndex            index of dialog
    * @param de                     DialogExporter object to be populated
    */
   private void buildDialogSummary(int dialogIndex, DialogExporter &dse)
   {
      // grab each child
      PropertySheetItem psi;
      itemIndex := _xmlcfg_get_first_child(m_xmlHandle, dialogIndex);
      while (itemIndex > 0) {
         // get the caption
         caption := _xmlcfg_get_attribute(m_xmlHandle, itemIndex, "Caption");

         // and value
         value := _xmlcfg_get_attribute(m_xmlHandle, itemIndex, "Value");

         // change events?
         events := _xmlcfg_get_attribute(m_xmlHandle, itemIndex, "ChangeEvents", "0");

         psi.Caption = caption;
         psi.Value = value;
         psi.ChangeEvents = events;
         dse.addSummaryItem(psi);

         // and the next one
         itemIndex = _xmlcfg_get_next_sibling(m_xmlHandle, itemIndex);
      }
   }

   /**
    * Builds the list of controls which corresponds to the given dialog.
    *
    * @param dialogIndex            index of a dialog node in the options XML DOM
    * @param dt                     DialogEmbedder object to add controls to
    */
   private void buildDialogControlList(int dialogIndex, DialogEmbedder &dt)
   {
      // grab each child
      ctrlIndex := _xmlcfg_get_first_child(m_xmlHandle, dialogIndex);
      while (ctrlIndex > 0) {
         // if this is a property group, then we need to fetch the children
         if (isAPropertyGroup(ctrlIndex)) {
            buildDialogControlList(ctrlIndex, dt);
         } else {
            // get the list of controls
            controls := _xmlcfg_get_attribute(m_xmlHandle, ctrlIndex, "Controls", "");

            if (controls != "") {
               Control c;
               c.Modified = false;
               c.Protected = isItemProtected(ctrlIndex);
               c.PreserveSpaces = (_xmlcfg_get_attribute(m_xmlHandle, ctrlIndex, "PreserveSpaces", "False") == "True");

               // caption next
               c.Caption = _xmlcfg_get_attribute(m_xmlHandle, ctrlIndex, "Caption");
               c.Index = ctrlIndex;

               // the first one is the "main one"
               _str array[];
               split(controls, ",", array);
               foreach (auto ctrl in array) {
                  c.DialogControl = strip(ctrl);
                  dt.addControl(c);
               }
            }
         }

         // and the next one
         ctrlIndex = _xmlcfg_get_next_sibling(m_xmlHandle, ctrlIndex);
      }
   }

   /**
    * Retrieves the language of a node if it's in the
    * language-specific section.
    *
    * @param index      index of node we want the language for
    *
    * @return           the node's language or empty string if
    *                   it is not a language node
    */
   private _str getLanguage(int index, int handle = -1)
   {
      if (handle == -1) handle = m_xmlHandle;

      // check for the 'Language' attribute
      while (index > 0) {
         language := _xmlcfg_get_attribute(handle, index, OPTIONS_XML_LANGUAGE_ATTRIBUTE, null);
         if (language != null) return language;

         index = _xmlcfg_get_parent(handle, index);
      }

      // not a language node
      return "";
   }

   /**
    * Retrieves the version control provider of a node if it's in
    * the version control provider setup section.
    *
    * @param index      index of node
    *
    * @return           the node's VC provider or empty string if
    *                   it is not a VC node
    */
   private _str getVersionControlProvider(int index, int handle = -1)
   {
      if (handle == -1) handle = m_xmlHandle;

      // check for the 'VCProviderID' attribute
      while (index > 0) {
         provider := _xmlcfg_get_attribute(handle, index, OPTIONS_XML_VC_PROVIDER_ATTRIBUTE, null);
         if (provider != null) return provider;

         index = _xmlcfg_get_parent(handle, index);
      }

      // not a version control node
      return "";
   }

   /**
    * Builds the data required to construct the right panel of the
    * options dialog.
    *
    * @param index   index in XML where we should get the data
    * @param data    data object where we put stuff
    *
    * @return        true if we were able to build something, false otherwise
    */
   public bool buildRightPanelData(int index, typeless &data, bool buildDialogAsSummary)
   {
      // first we figure out if this should show a dialog or a property sheet
      if (index == null) return false;
      type := _xmlcfg_get_name(m_xmlHandle, index);

      // then we let the appropriate function do all the work
      switch (type) {
      case "PropertySheet":
         data = buildPropertySheetData(index);
         break;
      case "Dialog":
      case "DialogTemplate":
         if (buildDialogAsSummary) {
            if (canDialogBeBuiltAsPropertySheet(index)) {
               data = buildPropertySheetData(index);
            } else {
               DialogExporter de;
               buildDialogTransformer(index, de);
               data = de;
            }
         } else {
            DialogEmbedder de;
            buildDialogTransformer(index, de);
            data = de;
         }
         break;
      case "Category":
      case "OptionsTree":
         data = buildCategoryHelpPanel(index);
         break;
      }

      if (data == null) return false;

      return true;
   }

   /**
    * Builds an object designed to look through a dialog and find all its labels
    * and whatnot so that it can be later searched.
    *
    * @param index            index of dialog node in options XML DOM
    * @param dt               DialogTagger object to be populated with info
    *
    * @return                 true if DialogTagger was found and populated, false
    *                         otherwise
    */
   public bool buildDialogTagger(int index, DialogTagger &dt)
   {
      // first we figure out if this should show a dialog or a property sheet
      if (index == null) return false;

      //dt = null;
      type := _xmlcfg_get_name(m_xmlHandle, index);
      if (type == "Dialog" || type == "DialogTemplate") {
         buildDialogTransformer(index, dt);
      }

      return (dt != null);
   }

   /**
    * Constructs a CategoryHelpPanel for the given index, which is
    * presumed to be a category.
    *
    * @param index      index in XML for which the panel will be built
    *
    * @return           the newly constructed CategoryHelpPanel
    */
   private CategoryHelpPanel buildCategoryHelpPanel(int index)
   {
      _str attr:[];
      _xmlcfg_get_attribute_ht(m_xmlHandle, index, attr);

      // get the size expected for the bitmap
      bmSize := 3*tbGetAutomaticBitmapSize("tree");
      bmSizeAttr := "width="bmSize" height="bmSize" ";

      // if there is no caption attribute, add one
      if (!attr._indexin("Caption")) {
         attr:["Caption"] = "Options";
      }

      // get the location for options bitmaps
      optionsBitmapsDir := get_env("VSROOT"):+FILESEP:+VSE_BITMAPS_DIR:+FILESEP:+"options":+FILESEP;

      // set the caption as a bolded title
      dh := "";
      if (attr._indexin("DialogHelp") && attr:["DialogHelp"] != "") {
         // then add any description if it exists
         dh :+= addHTMLTagsToPathsInHelp(attr:["DialogHelp"]);
      }

      if (m_optionsTreePurpose == OP_CONFIG) {
         // now add a list of the child nodes
         child := getFirstChild(index);
         if (child > 0) {
            dh :+= "<br>";
            dh :+= "<br>";
            dh :+= "Click a link to visit a specific options page or use the tree on the left.";
            dh :+= "<br>";
            dh :+= "<dl compact>";
            is_left := true;
            while (child > 0) {
               // get the picture and caption for the left-hand side
               left_caption := getCaption(child);
               left_picture := getPicture(child);
               if (left_caption == "Search Results") {
                  left_caption = "";
               }
               child = getNextSibling(child);

               // get the picture and caption for the middle column
               middle_caption := "";
               middle_picture := "";
               if (child > 0) {
                  middle_caption = getCaption(child);
                  middle_picture = getPicture(child);
                  if (middle_caption == "Search Results") {
                     middle_caption = "";
                  }
                  child = getNextSibling(child);
               }

               // get the picture and caption for the right-hand side
               right_caption := "";
               right_picture := "";
               if (child > 0) {
                  right_caption = getCaption(child);
                  right_picture = getPicture(child);
                  if (right_caption == "Search Results") {
                     right_caption = "";
                  }
                  child = getNextSibling(child);
               }

               // construct the line containg the image links
               ih := "";
               if (left_picture != "" || middle_picture != "" || right_picture != "") {
                  ih :+= "<dt>";
                  ih :+= "<br>";
                  if (left_picture != "") {
                     ih :+= '<a href="slickc:goToChildNode 'left_caption'">';
                     ih :+= '<img 'bmSizeAttr' src="'optionsBitmapsDir:+left_picture'">';
                     ih :+= "</a>";
                  }
                  ih :+= "</dt>";
                  if (middle_picture != "") {
                     ih :+= '<dd style="margin-left:200pt">';
                     ih :+= '<a href="slickc:goToChildNode 'middle_caption'">';
                     ih :+= '<img 'bmSizeAttr' src="'optionsBitmapsDir:+middle_picture'">';
                     ih :+= "</a>";
                     ih :+= "</dd>";
                  }
                  if (right_picture != "") {
                     ih :+= '<dd style="margin-left:400pt">';
                     ih :+= '<a href="slickc:goToChildNode 'right_caption'">';
                     ih :+= '<img 'bmSizeAttr' src="'optionsBitmapsDir:+right_picture'">';
                     ih :+= "</a>";
                     ih :+= "</dd>";
                  }
               }

               // construct the line containing the text links
               nh := "<dt>";
               if (left_caption != "") {
                  nh :+= '<a href="slickc:goToChildNode 'left_caption'">';
                  _escape_html_chars(left_caption);
                  nh :+= left_caption;
                  nh :+= "</a>";
               }
               nh :+= "</dt>";
               if (middle_caption != "") {
                  nh :+= '<dd style="margin-left:200pt">';
                  nh :+= '<a href="slickc:goToChildNode 'middle_caption'">';
                  _escape_html_chars(middle_caption);
                  nh :+= middle_caption;
                  nh :+= "</a>";
                  nh :+= "</dd>";
               }
               if (right_caption != "") {
                  nh :+= '<dd style="margin-left:400pt">';
                  nh :+= '<a href="slickc:goToChildNode 'right_caption'">';
                  _escape_html_chars(right_caption);
                  nh :+= right_caption;
                  nh :+= "</a>";
                  nh :+= "</dd>";
               }
               
               // now append both to the master string
               dh :+= ih;
               dh :+= nh;
               dh :+= "<dt></dt><dd></dd>";
            }
            dh :+= "</dl>";
         }
      }

      CategoryHelpPanel chp(attr:["Caption"], dh, attr:["SystemHelp"]);

      return chp;
   }

   /**
    * Determines whether a dialog described at the given options XML DOM node can
    * be built as a PropertySheet object for the purpose of exporting/importing.
    *
    * @param index      index of dialog in options XML DOM
    *
    * @return           true if dialog can be built as a property sheet, false
    *                   otherwise
    */
   private bool canDialogBeBuiltAsPropertySheet(int index)
   {
      firstChild := _xmlcfg_get_first_child(m_xmlHandle, index);
      if (firstChild > 0) {
         return isAProperty(firstChild) || isAPropertyGroup(firstChild);
      }

      return false;
   }

   /**
    * Adds an item to the options history saying that an Options Import was done on
    * this date.
    */
   public void setImportDate()
   {
      m_configParser.setImportDate();
   }

   /**
    * Adds options history items for the given list of options paths, saying that
    * they were changed on this date by Configuration. 
    *
    * @param paths            array of options node caption paths of options which
    *                         were just changed
    */
   public void setDateChanged(_str (&paths)[])
   {
      m_configParser.setDateChanged(paths, OCM_CONFIGURATION);
   }

   /**
    * Retrieves a list of the indices of all the XML nodes that define dialogs.
    *
    * @param nodes         list of indices to be populated
    */
   public void getAllFormNodes(int (&nodes)[])
   {
      _str list[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@Form", list, TREE_ROOT_INDEX);
      foreach (auto strIndex in list) {
         // turn this into a int
         nodes :+= _xmlcfg_get_parent(m_xmlHandle, (int)strIndex);
      }
   }

   /**
    * Retrieves the current search tags for a dialog.
    *
    * @param index         index of dialog in XML DOM
    *
    * @return              current search tags
    */
   public _str getDialogSearchTags(int index)
   {
      return _xmlcfg_get_attribute(m_xmlHandle, index, "ManualTags", "");
   }

   /**
    * Adds search tags to an existing dialog node.
    *
    * @param index            index of dialog
    * @param tags             search tags to add
    */
   public void setDialogSearchTags(int index, _str tags)
   {
      _xmlcfg_set_attribute(m_xmlHandle, index, "Tags", strip(tags));
   }

   /**
    * Gets a list of all nodes - properties and dialogs - which are available to be
    * exported at this time.
    *
    * @param nodes            array of nodes to be populated with exportable nodes
    */
   public void getAllExportableNodes(int (&nodes)[])
   {
      // first grab all the properties
      _str list[];
      _xmlcfg_find_simple_array(m_xmlHandle, "/Options/OptionsTree//PropertySheet", list, m_topNode);
      foreach (auto strIndex in list) {
         // make sure node is visible
         if (isNodeCurrentlyVisible((int)strIndex, true)) {
            nodes :+= (int)strIndex;
         }
      }

      _xmlcfg_find_simple_array(m_xmlHandle, "/Options/OptionsTree//Dialog", list, m_topNode);
      foreach (strIndex in list) {
         // make sure node is visible
         if (isNodeCurrentlyVisible((int)strIndex, true)) {

            // this could either be a straight dialog or a dialog with properties...
            propIndex := getFirstChild((int)strIndex);
            // nope, just the dialog then
            nodes :+= (int)strIndex;
         }
      }
   }

   /**
    * Retrieves the child indices that refer to properties.
    *
    * @param parent           parent node to retrieve children of
    * @param nodes            array to be populated with property indices
    */
   private void getAllPropertyIndices(int parent, int (&nodes)[])
   {
      propIndex := getFirstChild(parent);

      while (propIndex > 0) {
         if (isAPropertyGroup(propIndex)) {
            getAllPropertyIndices(propIndex, nodes);
         } else {
            nodes :+= propIndex;
         }

         propIndex = getNextSibling(propIndex);
      }
   }

   /**
    * Gets a description of the current platform.
    *
    * @return                 current platform
    */
   private _str getPlatform()
   {
      return machine();
   }

   /**
    * Deletes any attributes of a dialog node not needed for 
    * exporting options. 
    * 
    * @param node             dialog node
    */
   private void deleteDialogAttributesForExport(int node)
   {
      // delete some extra baggage to slim down the xml files
      _xmlcfg_delete_attribute(m_xmlHandle, node, "TagFunction");
      _xmlcfg_delete_attribute(m_xmlHandle, node, "Tags");
      _xmlcfg_delete_attribute(m_xmlHandle, node, "ManualTags");
      _xmlcfg_delete_attribute(m_xmlHandle, node, "TagComplexControls");
      _xmlcfg_delete_attribute(m_xmlHandle, node, "Width");
      _xmlcfg_delete_attribute(m_xmlHandle, node, "Height");
   }

   /**
    * Writes the XML file associated with an export/import package.  This file
    * defines the settings being exported and their current values.
    *
    * @param properties          the list of properties being exported
    * @param path                the path where the file should be saved
    */
   public int writeExportXML(typeless (&exportItems)[], _str &path, ExportImportGroup eig, _str protectionCode)
   {
      // write protection code attribute
      hasProtectionCode := false;
      if (protectionCode != "") {
         _xmlcfg_add_attribute(m_xmlHandle, m_topNode, "ProtectionCode", protectionCode);
         hasProtectionCode = true;
      }

      // write what platform was used to create this
      index := _xmlcfg_find_child_with_name(m_xmlHandle, TREE_ROOT_INDEX, "Options");
      _xmlcfg_add_attribute(m_xmlHandle, index, "Platform", getPlatform());

      // sets the options version to match the current editor version.
      _xmlcfg_set_attribute(m_xmlHandle, index, VERSION_ATTRIBUTE_NAME, _version());

      int nodes[];
      for (i := 0; i < exportItems._length(); i++) {
         switch (exportItems[i]._typename()) {
         case "se.options.DialogExporter":
            DialogExporter de = (DialogExporter)exportItems[i];
            dialogIndex := de.getIndex();
            if (de.getPanelType() == OPT_DIALOG_FORM_EXPORTER) {

               importFiles := de.getImportFilenamesAsString();
               importArgs := de.getImportArguments();
               if (importFiles != "" || importArgs != "") {

                  // add the file and any import args
                  if (importFiles != "") {
                     _xmlcfg_add_attribute(m_xmlHandle, dialogIndex, "ImportFiles", importFiles);
                  }
                  if (importArgs != "") {
                     _xmlcfg_add_attribute(m_xmlHandle, dialogIndex, "ImportArguments", importArgs);
                  }

                  nodes :+= dialogIndex;
               }
            } else {
               for (j := 0; j < de.getNumSummaryItems(); j++) {
                  PropertySheetItem * item = de.getSummaryItem(j);

                  itemIndex := _xmlcfg_add(m_xmlHandle, dialogIndex, "SummaryItem", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
                  _xmlcfg_add_attribute(m_xmlHandle, itemIndex, "Caption", item -> Caption);
                  _xmlcfg_add_attribute(m_xmlHandle, itemIndex, "Value", item -> Value);

                  if (item -> ChangeEvents != null && item -> ChangeEvents != 0) {
                     _xmlcfg_add_attribute(m_xmlHandle, itemIndex, "ChangeEvents", item -> ChangeEvents);
                  }

                  nodes :+= itemIndex;
               }
            }

            // delete some extra baggage to slim down the xml files
            deleteDialogAttributesForExport(dialogIndex);
            break;
         default:
            Property p = (Property)exportItems[i];
            propIndex := p.getIndex();
            nodes :+= propIndex;

            protectionStatus := EIPS_FALSE;
            if (hasProtectionCode) protectionStatus = eig.getItemProtectionStatus(propIndex);

            if (protectionStatus == EIPS_UNPROTECT) {
               // if we are unprotecting, then we don't care about the value
               _xmlcfg_add_attribute(m_xmlHandle, propIndex, "Protected", "Unprotect");
            } else {
               // we add the value to the XML
               actualValue := p.getActualValue();
               displayValue := p.getDisplayValue();

               _xmlcfg_add_attribute(m_xmlHandle, propIndex, "ActualValue", actualValue);
               if (actualValue != displayValue) {
                  _xmlcfg_add_attribute(m_xmlHandle, propIndex, "DisplayValue", displayValue);
               }

               if (protectionStatus == EIPS_TRUE) {
                  _xmlcfg_add_attribute(m_xmlHandle, propIndex, "Protected", "True");
               }
            }

            // delete this extra baggage
            child := _xmlcfg_find_child_with_name(m_xmlHandle, propIndex, "Dependencies");
            if (child > 0) _xmlcfg_delete(m_xmlHandle, child);

            // if this is part of a dialog node, it may have some extra baggage
            parent := _xmlcfg_get_parent(m_xmlHandle, propIndex);
            while (isAPropertyGroup(parent)) {
               parent = _xmlcfg_get_parent(m_xmlHandle, parent);
            }
            if (isADialog(parent)) {
               deleteDialogAttributesForExport(parent);
            }


            break;
         }

      }

      // did we write anything?
      if (!nodes._length()) {
         _xmlcfg_close(m_xmlHandle);

         return -1;
      }

      // remove any XML we're not using
      trimXML(nodes);
      deleteCaptions();

      // now write the XML file to somewhere super cool
      path :+= "export.xml";
      _xmlcfg_save(m_xmlHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE, path);
      _xmlcfg_close(m_xmlHandle);

      return 0;
   }

   /**
    * Removes captions that were added for a language or version control provider.
    * We do not want to export these captions because the languages/VCPs may have
    * different names on the machine that imports them.
    */
   private void deleteCaptions()
   {
      // search for anything with an "OriginalCaption", restore that...
      _str array[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@"OPTIONS_XML_LANGUAGE_ATTRIBUTE, array, m_topNode, VSXMLCFG_FIND_APPEND);
      _xmlcfg_find_simple_array(m_xmlHandle, "//@"OPTIONS_XML_VC_PROVIDER_ATTRIBUTE, array, m_topNode, VSXMLCFG_FIND_APPEND);

      int index;
      foreach (index in array) {
         index = _xmlcfg_get_parent(m_xmlHandle, index);
         _xmlcfg_delete_attribute(m_xmlHandle, index, "Caption");
      }
   }

   /**
    * Trims the XML DOM down to the list of nodes and the paths to 
    * get to them.  Used for export.
    *
    * @param nodes            the list of nodes we want to keep intact
    */
   private void trimXML(int nodes[])
   {
      // let's make that search hash
      createShownNodeTable(nodes);

      // now we check every node in town
      deleteExtraNodes(m_topNode);

      clearSearch();

      // remove some extra stuff that we don't want
      if (m_categoryTemplates > 0) _xmlcfg_delete(m_xmlHandle, m_categoryTemplates);

      // check if we are using templates - if we are using some, keep them all, because it's not worth it to get rid of them
      // if we are using none, just delete the template parent node
      _str tempNodes[];
      if (m_dialogTemplates > 0) {
         // see if we are using any dialog templates - we might could chuck them
         _xmlcfg_find_simple_array(m_xmlHandle, "//Dialog/@DialogTemplate", tempNodes, m_topNode);
         if (!tempNodes._length()) {
            _xmlcfg_delete(m_xmlHandle, m_dialogTemplates);
         } 
      }

      if (m_propertyTemplates > 0) {
         // see if we are using any property templates - we might could chuck them
         _xmlcfg_find_simple_array(m_xmlHandle, "//Property/@PropertyTemplate", tempNodes, m_topNode);
         if (!tempNodes._length()) {
            _xmlcfg_delete(m_xmlHandle, m_propertyTemplates);
         } 
      }
   }

   /**
    * Deletes all the child nodes that are not currently marked in the search hash.
    *
    * @param parent           parent of nodes to be checked and possibly deleted
    */
   private void deleteExtraNodes(int parent)
   {
      index := _xmlcfg_get_first_child(m_xmlHandle, parent);

      while (index > 0) {
         nextIndex := _xmlcfg_get_next_sibling(m_xmlHandle, index);
         if (wasNodeFoundInSearch(index)) {
            // we don't want to do any deleting, in this case
         } else if (wasChildOfNodeFoundInSearch(index)) {
            // recurse!
            deleteExtraNodes(index);
         } else {
            // nothing interesting here...
            _xmlcfg_delete(m_xmlHandle, index);
         }

         index = nextIndex;
      }
   }

   public _str getImportProtectionCode()
   {
      return _xmlcfg_get_attribute(m_xmlHandle, m_topNode, "ProtectionCode");
   }

   public void buildImportGroup(ExportImportGroup &eig, ExportImportItemStatus status=EIIS_TRUE)
   {
      child := getFirstChild(m_topNode);
      while (child > 0) {
         addImportNode(eig, child, status);
         child = getNextSibling(child);
      }
   }

   private void addImportNode(ExportImportGroup &eig, int index, ExportImportItemStatus status)
   {
      // read this node's info
      protect := getProtectionStatus(index);

      if (!isAProperty(index)) {
         child := getFirstChild(index);
         while (child > 0) {
            addImportNode(eig, child, status);
            child = getNextSibling(child);
         }
      } 

      ExportImportItem eii;
      eii.ProtectStatus = protect;
      eii.Status = status;
      eig.addGroupItem(eii, index, false);
   }

   /**
    * Determines whether any of the items in this import package are to have
    * their protection status set upon import.  For this to be true, at least
    * one item has to have a protect status of True or Unprotect.
    *
    * @return           true if any items are protected, false otherwise
    */
   public bool areAnyItemsProtected()
   {
      _str nodes[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@Protected", nodes);

      // if we didn't find anything, then we know there are none
      if (nodes._length() == 0) return false;

      foreach (auto node in nodes) {
         // as soon as we find one that does something, we know it's true
         status := getProtectionStatusForString(_xmlcfg_get_value(m_xmlHandle, (int)node));
         if (status == EIPS_TRUE || status == EIPS_UNPROTECT ) return true;
      }

      // nothing to report, i suppose
      return false;
   }

   /**
    * Retrieves the protection value of the given node in the given XML DOM.
    *
    * @param handle           handle to xml file to check
    * @param index            index of item to check
    *
    * @return                 the protection item status of the node in question
    */
   public ExportImportProtectionStatus getProtectionStatus(int index, int handle = -1)
   {
      if (handle == -1) handle = m_xmlHandle;

      protectStr := _xmlcfg_get_attribute(handle, index, "Protected", "False");
      return getProtectionStatusForString(protectStr);
   }

   /**
    * Returns a list of indices that map to properties in the given 
    * property sheet that have protections in place. 
    * 
    * @param children         list of indices found in the search
    * @param index            parent to check
    */
   public void getProtectedPropertiesInSheet(int (&properties)[], int index)
   {
      // go through all the direct children only
      child := _xmlcfg_get_first_child(m_xmlHandle, index);
      while (child > 0) {

         // this was found, so add it
         if (isItemProtected(child)) {
            properties :+= child;
         }

         // if this is a property group, then we want to check the properties 
         // inside, too
         if (isAPropertyGroup(child)) {
            getProtectedPropertiesInSheet(properties, child);
         }

         // get the next one
         child = _xmlcfg_get_next_sibling(m_xmlHandle, child);
      }
   }

   private ExportImportProtectionStatus getProtectionStatusForString(_str string)
   {
      protect := EIPS_FALSE;
      switch (string) {
      case "True":
         protect = EIPS_TRUE;
         break;
      case "False":
         protect = EIPS_FALSE;
         break;
      case "Unprotect":
         protect = EIPS_UNPROTECT;
         break;
      }

      return protect;
   }

   public bool doesExportGroupHaveProtections(_str name)
   {
      protection := false;

      // see if there are any protections in this group
      _str nodes[];
      _xmlcfg_find_simple_array(m_xmlHandle, "//@Protected", nodes);

      foreach (auto node in nodes) {
         // as soon as we find one that does something, we know it's true
         status := getProtectionStatusForString(_xmlcfg_get_value(m_xmlHandle, (int)node));
         if (status == EIPS_TRUE || status == EIPS_UNPROTECT ) {
            protection = true;
            break;
         }
      }

      return protection;
   }

   /**
    * Finds the export group with the given name in the xml.
    * 
    * @param groupName     group to search for
    * 
    * @return int          index of group, negative if not found
    */
   private int getExportGroupIndex(_str groupName)
   {
      searchString := "//ExportGroup[@Name='"groupName"']";
      // sometimes the group names have apostrophes in them, which screws everything up
      if (pos("'", groupName)) {
         searchString = '//ExportGroup[@Name="'groupName'"]';
      }

      return _xmlcfg_find_simple(m_xmlExportHandle, searchString);
   }

   public void getExportGroupNames(_str (&names)[])
   {
      // open up export group file
      initExportGroupsDOM();

      _str xmlGroups[];
      _xmlcfg_find_simple_array(m_xmlExportHandle, "//ExportGroup", xmlGroups);

      int groupIndex;
      foreach (groupIndex in xmlGroups) {

         // set our group's name
         names :+= _xmlcfg_get_attribute(m_xmlExportHandle, groupIndex, "Name");
      }

      names._sort('I');
   }

   /**
    * Sorts the languages within their categories by the given
    * attribute.  The order of the language categories is not
    * affected.
    *
    * @param attribute
    */
   private void sortLanguages(_str attribute = "Caption")
   {
      if (m_languageBegin <= 0) return;

      index := getFirstChild(m_languageBegin);
      while (index > 0) {
         if (getLanguage(index) != ALL_LANGUAGES_ID) {
            _xmlcfg_sort_on_attribute(m_xmlHandle, index, attribute, 'I');
         }

         index = getNextSibling(index);
      }
   }

   /**
    * Sorts the list of Version Control Providers by the given
    * attribute.
    *
    * @param attribute
    */
   private void sortVCProviders(_str attribute = "Caption")
   {
      if (m_versionControlBegin <= 0) return;

      _xmlcfg_sort_on_attribute(m_xmlHandle, m_versionControlBegin, attribute, 'I');
   }

   /**
    * Retrieves all the dialog nodes of dialogs which reference the 
    * given dialog template. 
    * 
    * @param templateNode 
    * @param nodes 
    */
   public void getDialogsUsingTemplate(int templateNode, _str (&nodes)[])
   {
      // first get the template name
      templateName := _xmlcfg_get_attribute(m_xmlHandle, templateNode, "Name", "");
      if (templateName != "") {
         // now find all the dialogs which use this template
         _xmlcfg_find_simple_array(m_xmlHandle, "//Dialog[@DialogTemplate='"templateName"']", nodes, m_topNode);
      }
   }

   private void readExportGroupRanges(int groupIndex, ExportImportGroup &group)
   {
      // sort the languages and the version control stuff by their IDs
      sortLanguages(OPTIONS_XML_LANGUAGE_ATTRIBUTE);
      sortVCProviders(OPTIONS_XML_VC_PROVIDER_ATTRIBUTE);

      typeless allPaths:[];
      _str allRanges[];

      ranges := _xmlcfg_find_simple(m_xmlExportHandle, "//ExportRanges", groupIndex);
      rangeIndex := _xmlcfg_get_first_child(m_xmlExportHandle, ranges);
      while (rangeIndex > 0) {
         startPath := _xmlcfg_get_attribute(m_xmlExportHandle, rangeIndex, "StartPath");
         endPath := _xmlcfg_get_attribute(m_xmlExportHandle, rangeIndex, "EndPath");

         allPaths:[startPath] = startPath;
         if (endPath != "") {
             allPaths:[endPath] = endPath;
             allRanges :+= startPath","endPath;
         } else {
             allRanges :+= startPath;
         }
         rangeIndex = _xmlcfg_get_next_sibling(m_xmlExportHandle, rangeIndex);
      }

      typeless pathTable:[];
      mapConfigurationPathsToXML(allPaths, pathTable, true);

      _str range;
      foreach (range in allRanges) {
          _str startPath, endPath;
          parse range with startPath","endPath;

          if (pathTable._indexin(startPath)) {
              startIndex := pathTable:[startPath];
              if (endPath != "") {
                 if (pathTable._indexin(endPath)) {
                     endIndex := pathTable:[endPath];
                     addGroupItemsInRange(startIndex, endIndex, group);
                 }
              } else {
                 // just the start node, add it by itself
                 ExportImportItem eii;
                 eii.ProtectStatus = EIPS_FALSE;
                 eii.Status = EIIS_TRUE;
                 group.addGroupItem(eii, startIndex, false);
              }
          }
      }

      // now undo that sorting stuff
      sortLanguages("Caption");
      sortVCProviders("Caption");
   }

   private int findCommonLevel(int index1, int index2)
   {
       // get all the ancestors of the first one
       _str parentArray[];
       do {
           parentArray :+= index1;
           index1 = getParent(index1);
       } while (index1 > 0);

       // now check and see if any of these parents are in the original array
       do {
           if (_inarray(index2, parentArray)) {
               // this is the parent they have in common, the level + 1
               return _xmlcfg_get_depth(m_xmlHandle, index2) + 1;
           }
           index2 = getParent(index2);
       } while (index2 > 0);

       return 0;
   }

   private void addGroupItemsInRange(int startIndex, int endIndex, ExportImportGroup &group)
   {
      ExportImportItem defaultItem;
      defaultItem.ProtectStatus = EIPS_FALSE;
      defaultItem.Status = EIIS_TRUE;
      group.addGroupItem(defaultItem, startIndex, false);
      group.addGroupItem(defaultItem, endIndex, false);

      // we need to come up with the nodes in between these two...
      startDepth := _xmlcfg_get_depth(m_xmlHandle, startIndex);
      endDepth := _xmlcfg_get_depth(m_xmlHandle, endIndex);
      minDepth := findCommonLevel(startIndex, endIndex);

      // go forward until we are on the min depth
      curIndex := startIndex;
      depthCount := 2;

      while (startDepth > minDepth) {

         sibling := getNextSibling(curIndex);
         while (sibling > 0) {
            // mark this node
            group.addGroupItem(defaultItem, sibling, false);

            sibling = getNextSibling(sibling);
         }

         curIndex = getParent(curIndex);
         startDepth--;
         depthCount++;
         if (curIndex < 0) break;
      }
      startIndex = curIndex;

      // now go backward from the end until we are at the min depth
      curIndex = endIndex;
      depthCount = 2;
      while (endDepth > minDepth) {

         sibling := getPrevSibling(curIndex);
         while (sibling > 0) {
            // mark this node
            group.addGroupItem(defaultItem, sibling, false);

            sibling = getPrevSibling(sibling);
         }

         curIndex = getParent(curIndex);
         endDepth--;
         depthCount++;
         if (curIndex < 0) break;
      }
      endIndex = curIndex;

      // now we simply go through these siblings until we have marked
      // everything between these two paths
      curIndex = getNextSibling(startIndex);

      while (curIndex > 0 && curIndex != endIndex) {
         // mark this node
         group.addGroupItem(defaultItem, curIndex, false);

         curIndex = getNextSibling(curIndex);
      }

   }

   private void readExportGroupProtections(int groupIndex, ExportImportGroup &group)
   {
       protections := _xmlcfg_find_simple(m_xmlExportHandle, "//Protections", groupIndex);
       if (protections > 0) {

           int pathTable:[];
           protectIndex := _xmlcfg_get_first_child(m_xmlExportHandle, protections);
           while (protectIndex > 0) {
              path := _xmlcfg_get_attribute(m_xmlExportHandle, protectIndex, "Path");
              status := getProtectionStatusForString(_xmlcfg_get_attribute(m_xmlExportHandle, protectIndex, "Protected", "False"));

              // save each path and protection status
              pathTable:[path] = status;

              protectIndex = _xmlcfg_get_next_sibling(m_xmlExportHandle, protectIndex);
           }

           // now map these paths to indices
           if (pathTable._length()) {
               ExportImportProtectionStatus protectTable:[];
               mapConfigurationPathsToXML(pathTable, protectTable);

               // go through each index in the table and mark it in the group
               ExportImportProtectionStatus status;
               foreach (auto index => status in protectTable) {
                   group.setItemProtectionStatus(index, status);
               }
           }
       }
   }

   /**
    * Builds an ExportGroup by reading the info from the export groups XML file.
    *
    * @param groupName           name of group
    * @param eig                 group object to be populated
    */
   public void buildExportGroup(_str groupName, ExportImportGroup &eig)
   {
      groupIndex := getExportGroupIndex(groupName);
      if (groupIndex > 0) {
         index := _xmlcfg_get_first_child(m_xmlExportHandle, groupIndex);
         readExportGroupRanges(groupIndex, eig);
         readExportGroupProtections(groupIndex, eig);
      }
   }

   /**
    * Deletes the export group with the given name from the ExportGroups file.
    *
    * @param groupName        name of group to be deleted
    */
   public void deleteExportGroup(_str groupName)
   {
      // see if we already have this group in xml
      index := getExportGroupIndex(groupName);
      if (index > 0) _xmlcfg_delete(m_xmlExportHandle, index);
   }

   /**
    * Writes the user's export groups to the configuration file.  If a group has
    * not changed, it is not updated.
    *
    * @param groups           the current list of groups
    */
   public void writeExportGroups(ExportImportGroup groups:[], bool writeToFile)
   {
      changed := false;

      // find the top node under which we'll add stuff
      topNode := _xmlcfg_find_simple(m_xmlExportHandle, "//ExportGroups");

      // sort the languages and the version control stuff by their IDs
      sortLanguages(OPTIONS_XML_LANGUAGE_ATTRIBUTE);
      sortVCProviders(OPTIONS_XML_VC_PROVIDER_ATTRIBUTE);

      // go through our list and add them all
      foreach (auto group in groups) {

         // see if this is new or modified
         if (group.isGroupModified()) {
            changed = true;

            // see if we already have this group in xml
            groupIndex := getExportGroupIndex(group.getName());
            if (groupIndex > 0) {
               // clear out all the childrens
               _xmlcfg_delete(m_xmlExportHandle, groupIndex, true);
            } else {
               // this must be new, so let's add it
               groupIndex = _xmlcfg_add(m_xmlExportHandle, topNode, "ExportGroup", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_add_attribute(m_xmlExportHandle, groupIndex, "Name", group.getName());
            }

            // write the group
            writeExportGroupRanges(groupIndex, group);

            // write the protections
            writeExportGroupProtections(groupIndex, group);

         }
      }

      // only write the file if something changed
      if (changed && writeToFile) {
         // write and close file
         file := _ConfigPath();
         _maybe_append_filesep(file);
         file :+= m_xmlExportFile;

         _xmlcfg_save(m_xmlExportHandle, -1, VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE, file);
      }

      // sort the languages and the version control stuff by their IDs
      sortLanguages("Caption");
      sortVCProviders("Caption");
   }

   private void writeExportGroupRanges(int groupIndex, ExportImportGroup &group)
   {
       groupRangesIndex := _xmlcfg_add(m_xmlExportHandle, groupIndex, "ExportRanges",
                                       VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

       // first get the list
       int statusTable:[];
       group.getAllIndicesWithStatus(statusTable);

       // find the first node
       nodePosition := getFirstChild(m_topNode);

       int startRangeNode = -1, endRangeNode = -1;
       while (nodePosition > 0) {
          getNextExportRange(nodePosition, startRangeNode, endRangeNode, statusTable);

          if (nodePosition > 0) {
             // write this range
             rangeIndex := _xmlcfg_add(m_xmlExportHandle, groupRangesIndex, "ExportRange",
                                       VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
             _xmlcfg_add_attribute(m_xmlExportHandle, rangeIndex, "StartPath", getXMLNodeCaptionPath(startRangeNode));
             if (startRangeNode != endRangeNode) {
                _xmlcfg_add_attribute(m_xmlExportHandle, rangeIndex, "EndPath", getXMLNodeCaptionPath(endRangeNode));
             }
          }
       }
   }

   private void writeExportGroupProtections(int groupIndex, ExportImportGroup &group)
   {
       int protectTable:[];
       group.getAllIndicesWithProtections(protectTable);

       protectionsIndex := _xmlcfg_add(m_xmlExportHandle, groupIndex, "Protections",
                                       VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);

       int index, status;
       foreach (index => status in protectTable) {
           protectIndex := _xmlcfg_add(m_xmlExportHandle, protectionsIndex, "Protection",
                                       VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
           _xmlcfg_add_attribute(m_xmlExportHandle, protectIndex, "Path", getXMLNodeCaptionPath(index));

           protectString := "";
           if (status == EIPS_TRUE) protectString = "True";
           if (status == EIPS_UNPROTECT) protectString = "Unprotect";

           _xmlcfg_add_attribute(m_xmlExportHandle, protectIndex, "Protected", protectString);
       }
   }

   private void getNextExportRange(int &nodePosition, int &startRangeNode, int &endRangeNode, int (&statusTable):[])
   {
      int lastOldStatusNode = -1, firstNewStatusNode = -1;

      startNodeStatus := getStatusFromTable(nodePosition, statusTable);
      if (startNodeStatus == EIIS_TRUE) {
         // we have found the start of the range
         startRangeNode = nodePosition;
      } else if (startNodeStatus == EIIS_SOME_CHILDREN) {
         // go find us the beginning of something
         startRangeNode = findNextNodeWithExportStatus(nodePosition, EIIS_TRUE, lastOldStatusNode, statusTable);
         if (startRangeNode < 0) {
            startRangeNode = endRangeNode = nodePosition = -1;
            return;
         }
      } else {
         // we need to find the start of the next range
         findNextStatusChange(nodePosition, lastOldStatusNode, firstNewStatusNode, statusTable);

         // now we are sitting at the beginning of a true range
         startRangeNode = firstNewStatusNode;
         if (startRangeNode < 0) {
            startRangeNode = endRangeNode = nodePosition = -1;
            return;
         }
      }

      // find the end of it
      findNextStatusChange(startRangeNode, lastOldStatusNode, firstNewStatusNode, statusTable);

      endRangeNode = lastOldStatusNode;         // set the end of the range
      nodePosition = firstNewStatusNode;        // set the new position
   }

   private void findNextStatusChange(int nodePosition, int &lastOldStatusNode, int &firstNewStatusNode, int (&statusTable):[])
   {
      // get the status of the start node - the is the current state we are in
      status := getStatusFromTable(nodePosition, statusTable);

      // get the opposite status - the one we are looking for
      if (status == EIIS_TRUE) status = EIIS_FALSE;
      else if (status == EIIS_FALSE) status = EIIS_TRUE;

      lastOldStatusNode = nodePosition;

      // find the next node
      nodePosition = getNextNode(nodePosition);
      firstNewStatusNode = nodePosition = findNextNodeWithExportStatus(nodePosition, status, lastOldStatusNode, statusTable);

   }

   private int findNextNodeWithExportStatus(int nodePosition, int status, int &lastOppNode, int (&statusTable):[])
   {
      // first check this node
      while (nodePosition > 0) {
         nodeStatus := getStatusFromTable(nodePosition, statusTable);

         if (nodeStatus == status) {
            return nodePosition;
         } else if (nodeStatus == EIIS_SOME_CHILDREN || isAPropertyGroup(nodePosition)) {
            child := getFirstChild(nodePosition);
            if (isAPropertyGroup(child)) {
               child = getFirstChild(child);
            }
            return findNextNodeWithExportStatus(child, status, lastOppNode, statusTable);
         } else {
            lastOppNode = nodePosition;
         }

         nodePosition = getNextNode(nodePosition);
      }


      return -1;
   }

   private int getNextNode(int node)
   {
      // look at siblings first...
      sibling := getNextSibling(node);

      if (isAPropertyGroup(sibling)) {
         sibling = getFirstChild(sibling);
      }

      while (sibling < 0) {
         node = getParent(node);
         if (node < 0) break;
         sibling = getNextSibling(node);
      }

      if (sibling > 0 && isAPropertyGroup(sibling)) {
         sibling = getFirstChild(sibling);
      }

      return sibling;
   }

   private int getStatusFromTable(int node, int (&statusTable):[])
   {
      if (statusTable._indexin(node)) {
         return statusTable:[node];
      } else return EIIS_FALSE;
   }

   /**
    * Determines whether an item is protected.
    *
    * @param index                  index of item to check for protections
    *
    * @return                       true if the item is protected, false otherwise
    */
   public bool isItemProtected(int index)
   {
      return m_protections._indexin(index);
   }

   /**
    * Retrieves the code associated with an item's protection.
    *
    * @param index                  protected index to check
    *
    * @return                       protection code
    */
   public _str getItemProtectionCode(int index)
   {
      if (m_protections._indexin(index)) {
         return m_protections:[index].ProtectionCode;
      }

      return "";
   }

   /**
    * Adds a protection of an option to our collection.
    *
    * @param index                  index of node to protect
    * @param protectionCode         protection code associated with the protection
    */
   public void addProtection(int index, _str protectionCode)
   {
      // add to our storage
      path := getXMLNodeCaptionPath(index);
      ProtectedSetting ps;
      ps.Path = path;
      ps.ProtectionCode = protectionCode;
      m_protections:[index] = ps;
   }

   /**
    * Removes a protection from our list.
    *
    * @param index            index of protection to remove
    */
   public void removeProtection(int index)
   {
      // remove from our storage
      m_protections._deleteel(index);
   }

   /**
    * Fills the given array with all the languages (using langIDs) that have the
    * given option protected.
    *
    * @param optionPath                option we are looking for
    * @param langIDs                   array of lang ids
    */
   public void getLanguagesWithOptionProtected(_str optionPath, _str (&langIDs)[])
   {
      _str paths[];
      m_configParser.getProtectedPathsContainingSubpath(optionPath, paths);

      // now we extract the language ids for each one
      for (i := 0; i < paths._length(); i++) {
         p := paths[i];
         p = substr(p, 1, pos("> "optionPath, p) - 1);
         p = substr(p, pos(" Languages >", p) + 12);

         brack := pos(">", p);
         if (brack > 0) p = substr(p, 1, brack - 1);
         p = strip(p);

         langIDs[i] = p;
      }

   }

   /**
    * If a language is deleted, it's possible that it was a
    * protected.  To maintain a tidy configuration file, we delete
    * it from the protections list.
    *
    * @param path   path of deleted language
    */
   private void removePathFromProtections(_str path)
   {
      // see if a favorite has the magic path in it - if so, remove it
      typeless i;
      for (i._makeempty();;) {
         m_protections._nextel(i);
         if (i._isempty()) break;

         protectPath := m_protections:[i].Path;
         if (pos(path, protectPath) == 1) {
            m_protections._deleteel(i);
         }
      }
   }

};
