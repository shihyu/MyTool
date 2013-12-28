////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#include "search.sh"
#include "slick.sh"
#include "tagsdb.sh"
#include "xml.sh"
#require "se/color/ColorInfo.e"
#require "se/color/SymbolColorRule.e"
#require "se/color/SymbolColorRuleBase.e"
#import "se/color/SymbolColorAnalyzer.e"
#import "se/options/OptionsConfigTree.e"
#import "clipbd.e"
#import "color.e"
#import "ini.e"
#import "listbox.e"
#import "optionsxml.e"
#import "picture.e"
#import "main.e"
#import "math.e"
#import "mprompt.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

/**
 * This is the name of the symbol coloring configuration file. 
 * The standard schemes are stored in sysconfig/color and user 
 * defined color schemes are stored in the user's configuration 
 * directory.  Both files share this name.  The file format is 
 * identical for Windows and Unix platforms. 
 */
const SYMBOL_COLOR_SCHEMES_FILE = "SymbolColoring.xml";
/**
 * This is the name of the always empty scheme.
 */
const SYMBOL_COLOR_NONE = "(None)";
/**
 * Caption for symbol kind represent a symbol which is not found or 
 * other context tagging error. 
 */
const SYMBOL_COLOR_NOT_FOUND = "*SYMBOL NOT FOUND*";

/**
 * The "se.color" namespace contains interfaces and classes that are
 * necessary for managing syntax coloring and other color information 
 * within SlickEdit. 
 */
namespace se.color;

/**
 * The SymbolColorConfig class is used to manage the data necessary 
 * for customizing the symbol coloring rule base(s).  It works closely 
 * with the Symbol Coloring options dialog. 
 */
class SymbolColorConfig {

   /**
    * This is a hash table of symbol coloring schemes.  There are 
    * system schemes, user schemes, and a default empty symbol coloring 
    * scheme (None).  Schemes should be uniquely named. 
    */
   private SymbolColorRuleBase m_schemes:[];

   /**
    * This hash table keeps track of the original versions of system symbol 
    * coloring schemes.   
    */
   private SymbolColorRuleBase m_systemSchemes:[];

   /**
    * This is the symbol color scheme (rule base) which is currently 
    * being edited in the Symbol Coloring options dialog. 
    */
   private SymbolColorRuleBase m_currentScheme;

   /**
    * Has the current symbol coloring scheme (stored in 
    * {@link def_symbol_color_scheme} changed? 
    */
   private boolean m_modified = false;

   /**
    * Temporarily ignore what might appear to be symbol coloring modifications. 
    */
   private boolean m_ignoreModifications = false;

   /** 
    * @return 
    * Return the total number of system and and user-defined symbol 
    * color schemes loaded. 
    */
   int getNumSchemes() {
      return m_schemes._length();
   }

   /** 
    * @return 
    * Return a pointer to the current symbol color scheme being edited. 
    * This function can not return 'null'. 
    */
   SymbolColorRuleBase *getCurrentScheme() {
      return &m_currentScheme;
   }
   /**
    * Replace the current symbol color scheme with the given rule base. 
    *  
    * @param rb      new symbol color scheme (rule base). 
    */
   void setCurrentScheme(SymbolColorRuleBase &rb) {
      m_currentScheme = rb;
   }

   /**
    * Return the names of all the system and user schemes currently loaded 
    * into the configuration GUI. 
    *  
    * @return An array of strings containing scheme names. 
    */
   STRARRAY getSchemeNames() {
      STRARRAY a;
      foreach (auto name => . in m_schemes) {
         a[a._length()] = name;
      }
      return a;
   }

   /**
    * Return the names of all the system and user schemes currently 
    * available.  This method does not require the schemes to be loaded 
    * and is intended only for cases where you want to get the scheme 
    * names very quickly. 
    *  
    * @return An array of strings containing scheme names. 
    */
   static int getSchemeNamesOnly(_str (&schemeNames)[], 
                                 _str (&compatibleWith)[],
                                 _str restrictToColorScheme="") {
      userSchemesFile := getUserSymbolColorConfigFile(true);
      sysSchemesFile  := getSystemSymbolColorConfigFile(true);
      schemeNames = null;
      compatibleWith = null;
      loadAllSchemeNames(userSchemesFile, schemeNames, compatibleWith);
      loadAllSchemeNames(sysSchemesFile, schemeNames, compatibleWith);

      if (restrictToColorScheme != "") {

         // If there are NO symbol coloring schemes that matching this color scheme
         // then consider all symbol color schemes as compatible.  This is most
         // likely a user defined color scheme.
         haveCompatibleScheme := false;
         foreach (auto i => auto name in schemeNames) {
            if (compatibleWith[i] != null && pos(";"restrictToColorScheme";", ";"compatibleWith[i]";") > 0) {
               haveCompatibleScheme = true;
            }
         }

         // and insert the compatible ones into the array
         if (haveCompatibleScheme) {
            _str filteredSchemeNames[];
            _str filteredCompatibleWith[];
            foreach (i => name in schemeNames) {
               if (!haveCompatibleScheme || 
                   compatibleWith[i] == null || compatibleWith[i] == "" || 
                   pos(";"restrictToColorScheme";", ";"compatibleWith[i]";") > 0) {
                  filteredSchemeNames[filteredSchemeNames._length()] = schemeNames[i];
                  filteredCompatibleWith[filteredCompatibleWith._length()] = compatibleWith[i];
               }
            }
            schemeNames = filteredSchemeNames;
            compatibleWith = filteredCompatibleWith;
         }

      }

      return 0;
   }

   /**
    * @return 
    * Return a pointer to the system or user scheme with the given name. 
    * 
    * @param name    symbol color rule base name
    * 
    */
   SymbolColorRuleBase *getScheme(_str name) {
      if (name == null) return null;
      if (m_schemes._indexin(name)) {
         return &m_schemes:[name];
      }
      return null;
   }

   /**
    * Add the given scheme (rule base) to the list of schemes. 
    *  
    * @param rb            symbol color scheme (rule base) 
    * @param isUserScheme  false for system defined default schemes
    * 
    * @return Return a pointer to the copy of the scheme added to the list. 
    */
   SymbolColorRuleBase *addScheme(SymbolColorRuleBase &rb, boolean isUserScheme) {

      if (isUserScheme) {
         // just put these in without a second thought
         m_schemes:[rb.m_name] = rb;
      } else {
         // put this in the systems schemes table
         m_systemSchemes:[rb.m_name] = rb;
         // else make sure we are not overwriting a user scheme
         if (!m_schemes._indexin(rb.m_name)) {
            m_schemes:[rb.m_name] = rb;
         }
      }

      return &m_schemes:[rb.m_name];
   }

   /**
    * Delete the scheme with the given name from the list of schemes. 
    *  
    * @param name    symbol color scheme name 
    */
   void deleteScheme(_str name) {
      if (m_schemes._indexin(name)) {
         m_schemes._deleteel(name);
      }
   }

   /**
    * Resets a modified system scheme back to the original configuration as 
    * specificed in the installed XML file. 
    * 
    * @param name    name of scheme to reset to default
    */
   void resetScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         rb := m_systemSchemes:[name];
         m_schemes:[name] = rb;

         setCurrentScheme(rb);
      }
   }

   /**
    * @return 
    * Return 'true' if the scheme with the given name was added as a 
    * user defined symbol color scheme (rule base), as apposed to being 
    * a system defined default scheme. 
    *  
    * @param name    symbol color scheme name 
    */
   boolean isUserScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         return false;
      }

      return true;
   }

   /**
    * @return 
    * Return 'true' if the scheme with the given name was added as a system scheme, 
    * but has been modified from its original form by the user. 
    *  
    * @param name    symbol color scheme name 
    */
   boolean isModifiedSystemScheme(_str name) {
      if (m_systemSchemes._indexin(name)) {
         orig_rb := &m_systemSchemes:[name];
         curr_rb := &m_schemes:[name];
         return (orig_rb == null || curr_rb == null || *orig_rb != *curr_rb);
      }

      return false;
   }

   /**
    * @return Has the current symbol color scheme (rule base) changed since 
    * we started editing it? 
    */
   boolean isModified() {
      return m_modified;
   }

   /**
    * Mark the current symbol color scheme (rule base) as modified or not 
    * modified.  This function will also relay the modification information 
    * to the main options dialog so that it knows that the Symbol Coloring 
    * options panel has unsaved modifications to save. 
    *  
    * @param onoff   'true' for a modification, 'false' if we are resetting modify 
    */
   void setModified(boolean onoff=true) {
      if (m_ignoreModifications) return;
      m_modified = onoff;
   }
   /**
    * Temporarily ignore any modfications being made to the symbol coloring. 
    * This should be used when loading color schemes, to prevent callbacks 
    * that are populating the form from triggering modify callbacks when 
    * on_change() events are generated. 
    *  
    * @param onoff   'true' to ignore modifications, false otherwise. 
    *  
    * @return Returns the original state of ignoring modifications (true/false). 
    */
   void ignoreChanges(boolean onoff=true) {
      m_ignoreModifications = onoff;
   }
   /**
    * @return 
    * Return 'true' if we are ignoring modifications temporilary. 
    */
   boolean isIgnoringChanges() {
      return m_ignoreModifications;
   }

   /**
    * @return 
    * Return the full path to the user symbol color configuration file. 
    * This file is an XML file stored in the user's configuration 
    * directory. 
    *  
    * @param mustExist  Return "" if the file does not exist. 
    */
   static _str getUserSymbolColorConfigFile(boolean mustExist=true) {

      // first check the user's configuration directory
      filename := _ConfigPath();
      _maybe_append_filesep(filename);
      filename :+= SYMBOL_COLOR_SCHEMES_FILE;
      if (mustExist && !file_exists(filename)) {
         filename = "";
      }
      return filename;
   }

   /**
    * @return 
    * Return the full path to the system default symbol color 
    * configuration file.  This file is an XML file stored under the 
    * installation directory in sysconfig/color.
    *  
    * @param mustExist  Return "" if the file does not exist. 
    */
   static _str getSystemSymbolColorConfigFile(boolean mustExist=true) {
      // now check sysconfig/color
      filename := get_env("VSROOT");
      _maybe_append_filesep(filename);
      filename :+= "sysconfig";
      filename :+= FILESEP;
      filename :+= "color";
      filename :+= FILESEP;
      filename :+= SYMBOL_COLOR_SCHEMES_FILE;
      if (mustExist && !file_exists(filename)) {
         filename = "";
      }
      return filename;
   }

   /**
    * Load the empty symbol coloring scheme into the Symbol Coloring 
    * config dialog. 
    */
   void loadEmptyScheme() {
      SymbolColorRuleBase none;
      none.m_name = SYMBOL_COLOR_NONE;
      m_schemes:[SYMBOL_COLOR_NONE] = none;
   }
   /**
    * Set the symbol coloring settings displayed in the Symbol Coloring 
    * option dialog to the options currently in use. 
    */
   void loadCurrentScheme() {
      m_currentScheme = def_symbol_color_scheme;

      addScheme(def_symbol_color_scheme, true);
   }

   /**
    * Load the system default symbol color schemes into the Symbol 
    * Coloring config dialog.  The schemes are loaded from 
    * [slickedit]/sysconfig/color/SymbolColoring.xml.
    * 
    * @return 0 on success, <0 on error
    */
   int loadSystemSchemes() {
      filename := getSystemSymbolColorConfigFile(true);
      return loadAllSchemes(filename);
   }
   /**
    * Load the user defined symbol color schemes into the Symbol 
    * Coloring config dialog.  The schemes are loaded from 
    * [config]/SymbolColoring.xml.
    * 
    * @return 0 on success, <0 on error
    */
   int loadUserSchemes() {
      filename := getUserSymbolColorConfigFile(true);
      return loadAllSchemes(filename,true);
   }

   /**
    * Imports a file with user-defined symbol color schemes.
    * 
    * @param filename           the file containing schemes to be imported
    * 
    * @return                   0 on success, <0 on error
    */
   int importUserSchemes(_str filename)
   {
      status := loadAllSchemes(filename, true);
      if (status) return status;

      status = saveUserSchemes();
      return status;
   }

   /**
    * Load one symbol coloring rule from the given XML file. 
    *  
    * @param xmlcfgHandle     XML configuration file handle 
    * @param ruleNode         index of XML node to load information from
    * 
    * @return Return the rule that was stored at the given node. 
    */
   private SymbolColorRule loadOneRule(int xmlcfgHandle, int ruleNode)
   {
      ColorInfo c;
      SymbolColorRule rule;
      rule.m_colorInfo = c;

      rule.m_ruleName            = _xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "name");
      rule.m_regexOptions        = _xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "regexType");
      rule.m_classRegex          = _xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "classRE");
      rule.m_nameRegex           = _xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "nameRE");
      rule.setTagTypes(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "kinds"));
      rule.m_attributeFlagsOn    = parseTagFlags(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "attributesOn"));
      rule.m_attributeFlagsOff   = parseTagFlags(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "attributesOff"));

      ColorInfo color;
      color.m_parentName = parseColorName(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "parentColor"));
      fg := hex2dec(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "fg"));
      if (fg=="") fg=0x000000;
      color.m_foreground = fg;
      bg := hex2dec(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "bg"));
      if (bg=="") bg=0xffffff;
      color.m_background = bg;
      color.m_fontFlags  = ColorInfo.parseFontFlags(_xmlcfg_get_attribute(xmlcfgHandle, ruleNode, "fontFlags"));
      rule.m_colorInfo = color;

      return rule;
   }

   /**
    * Load one symbol coloring scheme (rule base) from the given XML file. 
    *  
    * @param xmlcfgHandle     XML configuration file handle 
    * @param ruleNode         index of XML node to load information from
    * 
    * @return Return the scheme (rule base) that was stored at the given node. 
    */
   private SymbolColorRuleBase loadOneScheme(int xmlcfgHandle, int schemeNode)
   {  
      SymbolColorRuleBase rb;
      rb.m_name = _xmlcfg_get_attribute(xmlcfgHandle, schemeNode, "name");
      
      compatibleSchemes := _xmlcfg_get_attribute(xmlcfgHandle,  schemeNode, "compatibleWith");
      if (compatibleSchemes == null) compatibleSchemes="";
      rb.setCompatibleColorSchemes(split2array(compatibleSchemes, ";"));

      status := _xmlcfg_find_simple_array(xmlcfgHandle, "Rule", auto nodeIndexes, schemeNode);
      if (status) {
         return null;
      }

      foreach (auto node in nodeIndexes) {
         rule := loadOneRule(xmlcfgHandle, (int)node);
         if (rule != null) {
            rb.addRule(rule);
         }
      }

      return rb;
   }

   /**
    * Load all the symbol coloring schemes from the given XML file. 
    *  
    * @param filename         configuration file to load 
    * @param isUserScheme     Is this the system configuration file, 
    *                         or a user defined config file? 
    * 
    * @return 0 on success, <0 on error
    */
   protected int loadAllSchemes(_str filename, boolean isUserScheme=false) {

      if (filename == "") {
         return FILE_NOT_FOUND_RC;
      }

      xmlcfgHandle := _xmlcfg_open(filename, auto status=0);
      if (xmlcfgHandle < 0) {
         return xmlcfgHandle;
      }
      if (status < 0) {
         return status;
      }
       
      status = _xmlcfg_find_simple_array(xmlcfgHandle, "SymbolColoring/Scheme", auto nodeIndexes);
      if (status == 0) {
         foreach (auto node in nodeIndexes) {
            rb := loadOneScheme(xmlcfgHandle, (int)node);
            if (rb != null) {
               addScheme(rb, isUserScheme);
            }
         }
      }

      _xmlcfg_close(xmlcfgHandle);
      return 0;
   }

   /**
    * Load all the symbol coloring scheme names from the given XML file. 
    *  
    * @param filename         configuration file to load 
    * 
    * @return Array containing list of scheme names
    */
   static protected int loadAllSchemeNames(_str filename, _str (&schemeNames)[], _str (&compatibleWith)[]) {

      if (filename == "") {
         return FILE_NOT_FOUND_RC;
      }

      xmlcfgHandle := _xmlcfg_open(filename, auto status=0);
      if (xmlcfgHandle < 0) {
         return xmlcfgHandle;
      }
      if (status < 0) {
         return status;
      }
       
      status = _xmlcfg_find_simple_array(xmlcfgHandle, "SymbolColoring/Scheme", auto nodeIndexes);
      if (status == 0) {
         foreach (auto node in nodeIndexes) {
            name := _xmlcfg_get_attribute(xmlcfgHandle, (int)node, "name");
            if (name != null && name != "") {
               n := schemeNames._length();
               schemeNames[n] = name;
               compatibleWith[n] = _xmlcfg_get_attribute(xmlcfgHandle, (int)node, "compatibleWith");
               if (compatibleWith[n] == null) compatibleWith[n] = "";
            }
         }
      }

      _xmlcfg_close(xmlcfgHandle);
      return 0;
   }

   /**
    * Save one symbol coloring rule to the given XML configuration file. 
    *  
    * @param xmlcfgHandle     XML configuration file handle 
    * @param schemeNode       index of XML node to add information under
    * @param rule             Symbol coloring rule to save
    * 
    * @return Returns the index of the symbol coloring rule that was added, 
    *         or <0 on error. 
    */
   private int saveOneRule(int xmlcfgHandle, int schemeNode, SymbolColorRule &rule)
   {
      ruleNode := _xmlcfg_add(xmlcfgHandle, schemeNode, 'Rule',
                              VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (ruleNode < 0) {
         return ruleNode;
      }
      status := _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'name', rule.m_ruleName);
      if (status < 0) {
         return status;
      }
      if (rule.m_regexOptions != null) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'regexType', rule.m_regexOptions);
         if (status < 0) {
            return status;
         }
      }
      if (rule.m_classRegex != null) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'classRE', rule.m_classRegex);
         if (status < 0) {
            return status;
         }
      }
      if (rule.m_nameRegex != null) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'nameRE', rule.m_nameRegex);
         if (status < 0) {
            return status;
         }
      }
      tagTypeArray := rule.getTagTypes();
      status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'kinds', join(tagTypeArray, ","));
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'attributesOn', tagFlagsToString(rule.m_attributeFlagsOn));
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'attributesOff', tagFlagsToString(rule.m_attributeFlagsOff));
      if (status < 0) {
         return status;
      }

      if (rule.m_colorInfo.m_parentName != null) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'parentColor', colorIndexToString(rule.m_colorInfo.m_parentName));
         if (status < 0) {
            return status;
         }
      }
      if (rule.m_colorInfo.m_foreground >= 0) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'fg', dec2hex(rule.m_colorInfo.m_foreground));
         if (status < 0) {
            return status;
         }
      }
      if (rule.m_colorInfo.m_background >= 0) {
         status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'bg', dec2hex(rule.m_colorInfo.m_background));
         if (status < 0) {
            return status;
         }
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, ruleNode, 'fontFlags', ColorInfo.fontFlagsToString(rule.m_colorInfo.m_fontFlags));
      if (status < 0) {
         return status;
      }

      return ruleNode;
   }

   /**
    * Save one symbol coloring scheme to the XML configuration file. 
    *  
    * @param xmlcfgHandle     XML configuration file handle 
    * @param rootNode         Symbol coloring configuration file root node
    * @param rb               Rule base to insert into config file
    * 
    * @return Returns the index of the rule inserted, or <0 on error. 
    */
   private int saveOneScheme(int xmlcfgHandle, int rootNode, SymbolColorRuleBase &rb)
   {
      schemeNode := _xmlcfg_add(xmlcfgHandle, rootNode, 'Scheme',
                                VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (schemeNode < 0) {
         return schemeNode;
      }
      status := _xmlcfg_add_attribute(xmlcfgHandle, schemeNode, "name", rb.m_name);
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, schemeNode, "compatibleWith", join(rb.m_compatibleSchemes, ";"));
      if (status < 0) {
         return status;
      }

      foreach (auto i in rb.getNumRules()) {
         SymbolColorRule *rule = rb.getRule(i-1);
         if (rule != null) {
            saveOneRule(xmlcfgHandle, schemeNode, *rule); 
         }
      }

      return schemeNode;
   }

   /**
    * Save the top-level information for this symbol color scheme, including 
    * the xml declaration, doctype declaration, and root &lt;SymbolColoring&gt; 
    * node. 
    *  
    * @param xmlcfgHandle     XML configuration file handle 
    * 
    * @return Return the index of the root node on success, <0 on error. 
    */
   private int saveXMLHeader(int xmlcfgHandle)
   {
      //Create the XML declaration.
      xmldecl_index := _xmlcfg_add(xmlcfgHandle, TREE_ROOT_INDEX, 'xml',
                                   VSXMLCFG_NODE_XML_DECLARATION,
                                   VSXMLCFG_ADD_AS_CHILD);
      if (xmldecl_index < 0) {
         return xmldecl_index;
      }
      status := _xmlcfg_set_attribute(xmlcfgHandle, xmldecl_index, 'version', '1.0');
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_set_attribute(xmlcfgHandle, xmldecl_index, 'encoding', 'UTF-8');
      if (status < 0) {
         return status;
      }

      // Create the doctype declaration
      xmldoctype_index := _xmlcfg_add(xmlcfgHandle,  TREE_ROOT_INDEX, 'DOCTYPE',
                                      VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
      if (xmldoctype_index < 0) {
         return xmldoctype_index;
      }
      status = _xmlcfg_set_attribute(xmlcfgHandle, xmldoctype_index, "root", "SymbolColoring");
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_set_attribute(xmlcfgHandle, xmldoctype_index, "SYSTEM", 
                                     "http://www.slickedit.com/dtd/vse/14.0/SymbolColoring.dtd");

      //Create the top most SymbolColoring tag
      rootNode := _xmlcfg_add(xmlcfgHandle, TREE_ROOT_INDEX, 'SymbolColoring',
                              VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if (rootNode < 0) {
         return rootNode;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, rootNode, 'version', '1.0');
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, rootNode, 
                                     'productName', _getApplicationName());
      if (status < 0) {
         return status;
      }
      status = _xmlcfg_add_attribute(xmlcfgHandle, rootNode, 
                                     'productVersion', _getVersion());
      if (status < 0) {
         return status;
      }

      return rootNode;
   }

   /**
    * Save all the user symbol coloring schemes to the XMl configuration file. 
    * 
    * @return 0 on success, <0 on error. 
    */
   int saveUserSchemes() {
      filename := getUserSymbolColorConfigFile(false);
      if (filename == '') {
         return FILE_NOT_FOUND_RC;
      }

      xmlcfgHandle := _xmlcfg_create(filename, VSCP_ACTIVE_CODEPAGE);
      if (xmlcfgHandle < 0) {
         return xmlcfgHandle;
      }
       
      rootNode := saveXMLHeader(xmlcfgHandle);

      foreach (auto schemeName => auto rb in m_schemes) {
         // we only write it if it's a user scheme or a system scheme that 
         // the user has modified
         if (isUserScheme(schemeName) || isModifiedSystemScheme(schemeName)) {
            saveOneScheme(xmlcfgHandle, rootNode, m_schemes:[schemeName]);
         } 
      }

      _xmlcfg_save(xmlcfgHandle, -1, 0);
      _xmlcfg_close(xmlcfgHandle);
      return 0;
   }

   /**
    * @return
    * Convert symbol tag attribute flags to a string representation for 
    * writing to the XML configuration file.  This way the information in 
    * the configuration file is symbolic and readable. 
    *  
    * @param tag_flags    Tag attribute flags to convert. 
    */
   private static _str tagFlagsToString(int tag_flags) {
      s := "";
      if (tag_flags & VS_TAGFLAG_virtual      ) s :+= "virtual|";
      if (tag_flags & VS_TAGFLAG_static       ) s :+= "static|";
      if (tag_flags & VS_TAGFLAG_protected    ) s :+= "protected|";
      if (tag_flags & VS_TAGFLAG_private      ) s :+= "private|";
      if (tag_flags & VS_TAGFLAG_const        ) s :+= "const|";
      if (tag_flags & VS_TAGFLAG_final        ) s :+= "final|";
      if (tag_flags & VS_TAGFLAG_abstract     ) s :+= "abstract|";
      if (tag_flags & VS_TAGFLAG_inline       ) s :+= "inline|";
      if (tag_flags & VS_TAGFLAG_operator     ) s :+= "operator|";
      if (tag_flags & VS_TAGFLAG_constructor  ) s :+= "constructor|";
      if (tag_flags & VS_TAGFLAG_volatile     ) s :+= "volatile|";
      if (tag_flags & VS_TAGFLAG_template     ) s :+= "template|";
      if (tag_flags & VS_TAGFLAG_inclass      ) s :+= "inclass|";
      if (tag_flags & VS_TAGFLAG_destructor   ) s :+= "destructor|";
      if (tag_flags & VS_TAGFLAG_synchronized ) s :+= "synchronized|";
      if (tag_flags & VS_TAGFLAG_transient    ) s :+= "transient|";
      if (tag_flags & VS_TAGFLAG_native       ) s :+= "native|";
      if (tag_flags & VS_TAGFLAG_macro        ) s :+= "macro|";
      if (tag_flags & VS_TAGFLAG_extern       ) s :+= "extern|";
      if (tag_flags & VS_TAGFLAG_maybe_var    ) s :+= "maybe_var|";
      if (tag_flags & VS_TAGFLAG_anonymous    ) s :+= "anonymous|";
      if (tag_flags & VS_TAGFLAG_mutable      ) s :+= "mutable|";
      if (tag_flags & VS_TAGFLAG_extern_macro ) s :+= "extern_macro|";
      if (tag_flags & VS_TAGFLAG_linkage      ) s :+= "linkage|";
      if (tag_flags & VS_TAGFLAG_partial      ) s :+= "partial|";
      if (tag_flags & VS_TAGFLAG_ignore       ) s :+= "ignore|";
      if (tag_flags & VS_TAGFLAG_forward      ) s :+= "forward|";
      if (tag_flags & VS_TAGFLAG_opaque       ) s :+= "opaque|";
      if (tag_flags & VS_TAGFLAG_uniq_public  ) s :+= "public|";
      if (tag_flags & VS_TAGFLAG_uniq_package ) s :+= "package|";
      if (last_char(s) == '|') s = substr(s, 1, length(s)-1);
      return s;
   }
   /** 
    * @return 
    * Parse a list of tag attribute flags and return their integer value. 
    *  
    * @param s    string containing tag attribute flags from XML config file. 
    */
   private static int parseTagFlags(_str s) {
      tag_flags := 0;
      split(s, "|", auto flag_names);
      foreach (auto flag in flag_names) {
         switch (flag) {
         case "virtual":      tag_flags |= VS_TAGFLAG_virtual; break;      
         case "static":       tag_flags |= VS_TAGFLAG_static; break;       
         case "public":       tag_flags |= VS_TAGFLAG_uniq_public; break;       
         case "protected":    tag_flags |= VS_TAGFLAG_protected; break;    
         case "private":      tag_flags |= VS_TAGFLAG_private; break;      
         case "package":      tag_flags |= VS_TAGFLAG_uniq_package; break;      
         case "const":        tag_flags |= VS_TAGFLAG_const; break;        
         case "final":        tag_flags |= VS_TAGFLAG_final; break;        
         case "abstract":     tag_flags |= VS_TAGFLAG_abstract; break;     
         case "inline":       tag_flags |= VS_TAGFLAG_inline; break;       
         case "operator":     tag_flags |= VS_TAGFLAG_operator; break;     
         case "constructor":  tag_flags |= VS_TAGFLAG_constructor; break;  
         case "volatile":     tag_flags |= VS_TAGFLAG_volatile; break;     
         case "template":     tag_flags |= VS_TAGFLAG_template; break;     
         case "inclass":      tag_flags |= VS_TAGFLAG_inclass; break;      
         case "destructor":   tag_flags |= VS_TAGFLAG_destructor; break;   
         case "synchronized": tag_flags |= VS_TAGFLAG_synchronized; break; 
         case "transient":    tag_flags |= VS_TAGFLAG_transient; break;    
         case "native":       tag_flags |= VS_TAGFLAG_native; break;       
         case "macro":        tag_flags |= VS_TAGFLAG_macro; break;        
         case "extern":       tag_flags |= VS_TAGFLAG_extern; break;       
         case "maybe_var":    tag_flags |= VS_TAGFLAG_maybe_var; break;    
         case "anonymous":    tag_flags |= VS_TAGFLAG_anonymous; break;    
         case "mutable":      tag_flags |= VS_TAGFLAG_mutable; break;      
         case "extern_macro": tag_flags |= VS_TAGFLAG_extern_macro; break; 
         case "linkage":      tag_flags |= VS_TAGFLAG_linkage; break;      
         case "partial":      tag_flags |= VS_TAGFLAG_partial; break;      
         case "ignore":       tag_flags |= VS_TAGFLAG_ignore; break;       
         case "forward":      tag_flags |= VS_TAGFLAG_forward; break;      
         case "opaque":       tag_flags |= VS_TAGFLAG_opaque; break;       
         }
      }
      return tag_flags;
   }

   /**
    * @return
    * Convert a standard color index to a string for storage in the 
    * XML symbol coloring configuration file.  This way the information 
    * in the configuration file is symbolic and readable. 
    *  
    * @param color   color index (CFG_*)
    */
   private static _str colorIndexToString(_str color) {
      switch (color) {
      case CFG_WINDOW_TEXT:          return "*CFG_WINDOW_TEXT*";         
      case CFG_KEYWORD:              return "*CFG_KEYWORD*";             
      case CFG_PPKEYWORD:            return "*CFG_PPKEYWORD*";           
      case CFG_LIBRARY_SYMBOL:       return "*CFG_LIBRARY_SYMBOL*";      
      case CFG_USER_DEFINED:         return "*CFG_USER_DEFINED*";        
      case CFG_FUNCTION:             return "*CFG_FUNCTION*";            
      case CFG_HILIGHT:              return "*CFG_HILIGHT*";             
      case CFG_SYMBOL_HIGHLIGHT:     return "*CFG_SYMBOL_HIGHLIGHT*";    
      default: return color;   
      }
   }
   /**
    * @return 
    * Return the color index corresponding to the given symbol color 
    * string from the XML configuration file.  Will return the same string 
    * that was passed in if it doesn't match any of the standard colors. 
    *  
    * @param s    Color name string 
    */
   private static _str parseColorName(_str s) {
      switch (s) {
      case "":
      case "*CFG_WINDOW_TEXT*":          return CFG_WINDOW_TEXT;         
      case "*CFG_KEYWORD*":              return CFG_KEYWORD;             
      case "*CFG_PPKEYWORD*":            return CFG_PPKEYWORD;           
      case "*CFG_LIBRARY_SYMBOL*":       return CFG_LIBRARY_SYMBOL;      
      case "*CFG_USER_DEFINED*":         return CFG_USER_DEFINED;        
      case "*CFG_FUNCTION*":             return CFG_FUNCTION;            
      case "*CFG_HILIGHT*":              return CFG_HILIGHT;             
      case "*CFG_SYMBOL_HIGHLIGHT*":     return CFG_SYMBOL_HIGHLIGHT;    
      default:
         return s;
      }
   }

};

///////////////////////////////////////////////////////////////////////////
// Switch to the global namespace
//
namespace default;

using se.color.SymbolColorAnalyzer;

/** 
 * Active symbol coloring rule base. 
 * This is modified using the GUI only. 
 *
 * @default ACTAPP_AUTORELOADON|ACTAPP_AUTOREADONLY
 * @categories Configuration_Variables
 */
se.color.SymbolColorRuleBase def_symbol_color_scheme = null;

/**
 * Reset the symbol coloring scheme to defaults. 
 * This function is no longer necessary, but left in for 
 * debugging or emergency purposes. 
 */
_command void reset_symbol_color_scheme() name_info(',')
{
   se.color.SymbolColorConfig scc;
   scc.loadSystemSchemes();

   // Start by finding a compatible color scheme
   compatibleSchemeName := null;
   foreach (auto schemeName in scc.getSchemeNames()) {
      if (compatibleSchemeName != null) break;
      switch (schemeName) {
      case "All symbols - Default":
      case "All symbols - Light background":
      case "All symbols - Dark background":
      case "All symbols - Silver":
      case "All symbols - Iceberge":
         rb := scc.getScheme(schemeName);
         if (rb == null) continue;
         if (rb->isCompatibleWithColorScheme(def_color_scheme)) {
            compatibleSchemeName = schemeName;
            break;
         }
         break;
      default:
         continue;
      }
   }

   // didn't find one, try selecting a color by looking
   // at the background used for CFG_WINDOW_TEXT.
   if (compatibleSchemeName == null) {
      typeless fg_color, bg_color;
      parse _default_color(CFG_WINDOW_TEXT) with fg_color bg_color .;
      red := fg_color & 0xFF;
      fg_color = (fg_color >> 8);
      blue := fg_color & 0xFF;
      fg_color = (fg_color >> 8);
      green := fg_color & 0xFF;
   
      // for white, this sum would be 765, 
      // so if their background is 2/3 that or more
      // use the "Default - White" color scheme.
      if (red + blue + green > 512) {
         compatibleSchemeName = "All symbols - Light background";
      }

      // for black, this sum would be 0, so if we are close to bloack,
      // use the "Default - Black" color scheme
      if (red + blue + green < 256) {
         compatibleSchemeName = "All symbols - Dark background";
      }
   }

   // set the color scheme to match the default scheme we found
   if (compatibleSchemeName != null) {
      rb := scc.getScheme(compatibleSchemeName);
      if (rb != null) {
         def_symbol_color_scheme = *rb;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme);
         return;
      }
   }

   // use the default settings, which may not match their colors
   se.color.SymbolColorRuleBase default_rb;
   default_rb.initDefaultRuleBase();
   def_symbol_color_scheme = default_rb;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme);
}

/**
 * This is for the first time user, so that the symbol coloring object 
 * gets initialized. 
 */
void _UpgradeSymbolColoringScheme() 
{
   if (def_symbol_color_scheme == null ||
       !(def_symbol_color_scheme instanceof se.color.SymbolColorRuleBase)) {
      reset_symbol_color_scheme();
   } else {
      // remove the (modified) if it's there
      parse def_symbol_color_scheme.m_name with auto schemeName ' (modified)';
      if (schemeName != '') def_symbol_color_scheme.m_name = schemeName;
      // rename the "Undefined only" scheme
      if (def_symbol_color_scheme.m_name == "Undefined Only") {
         def_symbol_color_scheme.m_name == "Unidentified Symbols Only";
      }
   }
}

/**
 * This function is used to migrate symbol coloring from version 14.0.0 
 * forward to subsequent versions of SlickEdit which will have Symbol Coloring 
 * disabled by default.  It will prompt the user whether they want to continue 
 * using symbol coloring or disable it.  It will also let them turn unknown 
 * symbol coloring on or off. 
 * 
 * @param old_config_version   Version of SlickEdit that configuration was 
 *                             migrated from.  Only matters if it is 14.0.0. 
 */
void _MigrateV14SymbolColoringOptions(_str old_config_version)
{
   // not migrating setting from 14.0.0, then forget about this step
   if (old_config_version != "14.0.0") {
      return;
   }

   // long-winded description of what this dialog is for
   explanation := "":+
                  "<b>Symbol Coloring</b> allows you to define rules to assign ":+
                  "colors to specific symbol types, like variables, class names ":+
                  "or functions. Each rule assigns a foreground and background ":+
                  "color based on the symbol's type ":+
                  "(e.g. Function, Parameter, Local variable) and a list of ":+
                  "attributes (e.g. Abstract, Public Scope, Const). ":+
                  "<p>":+
                  "Future versions of SlickEdit will have ":+
                  "<u>Symbol Coloring turned off by default</u>. ":+
                  "This feature was turned on by default in SlickEdit 2009. ":+
                  "<p>":+
                  "In addition, the option to highlight unidentified symbols will ":+
                  "also be turned off by default in future versions.  Check the ":+
                  "option below if you want to continue to highlight unidentified ":+
                  "symbols.":+
                  "";
   status := textBoxDialog("Confirm Symbol Coloring Options", 0, 6500,
                           "Symbol Coloring Options",
                           "Continue to use Symbol Coloring,Disable Symbol Coloring\t-html "explanation,
                           "",
                           "-CHECKBOX Highlight unidentified symbols:0" );

   // The idiot just hit cancel, their symbol coloring will now be disabled
   // unless they had explicitely enabled it themselves.
   if (status == COMMAND_CANCELLED_RC) {
      return;
   }

   // check results of dialog
   showUnknownSymbols    := (_param1==0)? SYMBOL_COLOR_SHOW_NO_ERRORS:0;
   disableSymbolColoring := (status ==2)? SYMBOL_COLOR_DISABLED:0;

   // collect all the language ID's into an array of strings
   _str languageIDs[];
   index := name_match("def-language-", 1, MISC_TYPE);
   while (index > 0) {
      languageIDs[languageIDs._length()] = substr(name_name(index), 14); 
      index = name_match("def-language-", 0, MISC_TYPE);
   }

   // for each language set up within SlickEdit
   // new user-defined languages will have symbol coloring
   // turned off by default. 
   foreach (auto langId in languageIDs) {

      // not a valid language ID
      if (langId=="") continue;
      if (!_QSymbolColoringSupported(langId)) {
         continue;
      }

      // if the options aren't explicitly set, use the V14.0.0 defaults
      options := _GetSymbolColoringOptions(langId);
      index = find_index("def-symbolcoloring-"langId, MISC_TYPE);
      if (!index) {
         options = SYMBOL_COLOR_BOLD_DEFINITIONS;
      }

      // do not highlight unidentified symbols 
      options |= showUnknownSymbols;

      // disable symbol coloring if they are disabling it
      // and it wasn't already explicitely disabled.
      if (!(options & SYMBOL_COLOR_DISABLED)) {
         options |= disableSymbolColoring;
      }

      // only set the symbol coloring options if they differ from
      // the v14.0.1 interpretation of the defaults.
      if (options != _GetSymbolColoringOptions(langId)) {
         _SetSymbolColoringOptions(langId, options);
      }
   }
}

/**
 * This hash table maps tag attribute flags to their message 
 * index codes so that we can find the localized strings describing 
 * the tag attributes. 
 */
static int gTagAttributeMap:[] = {
   VS_TAGFLAG_virtual      => VS_TAG_FLAG_VIRTUAL_RC,
   VS_TAGFLAG_static       => VS_TAG_FLAG_STATIC_RC,
   VS_TAGFLAG_uniq_public  => VS_TAG_FLAG_PUBLIC_RC,
   VS_TAGFLAG_protected    => VS_TAG_FLAG_PROTECTED_RC,
   VS_TAGFLAG_private      => VS_TAG_FLAG_PRIVATE_RC,
   VS_TAGFLAG_uniq_package => VS_TAG_FLAG_PACKAGE_RC,
   VS_TAGFLAG_const        => VS_TAG_FLAG_CONST_RC,
   VS_TAGFLAG_final        => VS_TAG_FLAG_FINAL_RC,
   VS_TAGFLAG_abstract     => VS_TAG_FLAG_ABSTRACT_RC,
   VS_TAGFLAG_inline       => VS_TAG_FLAG_INLINE_RC,
   VS_TAGFLAG_operator     => VS_TAG_FLAG_OPERATOR_RC,
   VS_TAGFLAG_constructor  => VS_TAG_FLAG_CONSTRUCTOR_RC,
   VS_TAGFLAG_volatile     => VS_TAG_FLAG_VOLATILE_RC,
   VS_TAGFLAG_template     => VS_TAG_FLAG_TEMPLATE_RC,
   VS_TAGFLAG_inclass      => VS_TAG_FLAG_INCLASS_RC,
   VS_TAGFLAG_destructor   => VS_TAG_FLAG_DESTRUCTOR_RC,
   VS_TAGFLAG_synchronized => VS_TAG_FLAG_SYNCHRONIZED_RC,
   VS_TAGFLAG_transient    => VS_TAG_FLAG_TRANSIENT_RC,
   VS_TAGFLAG_native       => VS_TAG_FLAG_NATIVE_RC,
   VS_TAGFLAG_macro        => VS_TAG_FLAG_MACRO_RC,
   VS_TAGFLAG_extern       => VS_TAG_FLAG_EXTERN_RC,
   VS_TAGFLAG_maybe_var    => VS_TAG_FLAG_MAYBE_VAR_RC,
   VS_TAGFLAG_anonymous    => VS_TAG_FLAG_ANONYMOUS_RC,
   VS_TAGFLAG_mutable      => VS_TAG_FLAG_MUTABLE_RC,
   VS_TAGFLAG_extern_macro => VS_TAG_FLAG_EXTERN_MACRO_RC,
   VS_TAGFLAG_linkage      => VS_TAG_FLAG_LINKAGE_RC,
   VS_TAGFLAG_partial      => VS_TAG_FLAG_PARTIAL_RC,
   VS_TAGFLAG_ignore       => VS_TAG_FLAG_IGNORE_RC,
   VS_TAGFLAG_forward      => VS_TAG_FLAG_FORWARD_RC,
   VS_TAGFLAG_opaque       => VS_TAG_FLAG_OPAQUE_RC,
};


///////////////////////////////////////////////////////////////////////////
// The following code is used to implement the Symbol Coloring
// configuration dialog.
///////////////////////////////////////////////////////////////////////////

defeventtab _symbol_color_form;

/**
 * Get the SymbolColorConfig class instance, which is stored in 
 * the p_user of the schemes control. 
 * 
 * @return se.color.SymbolColorConfig* 
 */
static se.color.SymbolColorConfig *getSymbolColorConfig()
{
   if (ctl_scheme.p_user instanceof se.color.SymbolColorConfig) {
      return &ctl_scheme.p_user;
   }
   return null;
}
/**
 * Get the SymbolColorRuleBase class instance being edited. 
 * It is obtained thought the master SymbolColorConfig object. 
 * 
 * @return se.color.SymbolColorRuleBase* 
 */
static se.color.SymbolColorRuleBase *getSymbolColorRuleBase()
{
   scc := getSymbolColorConfig();
   if (scc == null) return null;

   return scc->getCurrentScheme();

}
/**
 * Get the current SymbolColorRule being edited. 
 * It is obtained by looking at the rule name currently 
 * selected in the symbol coloring configuration dialog. 
 * 
 * @return se.color.SymbolColorRule* 
 */
static se.color.SymbolColorRule *getSymbolColorRule()
{
   rb := getSymbolColorRuleBase();
   if (rb == null) return null;

   index := ctl_rules._TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return null;

   caption := ctl_rules._TreeGetCaption(index);
   parse caption with auto ruleName "\t" . ;
   return rb->getRuleByName(ruleName);
}

/**
 * Gets the scheme name that was in place when the user opened the dialog OR the 
 * most recently applied on. 
 * 
 * @return scheme name
 */
static _str getOriginalColorSchemeName()
{
   return ctl_scheme_label.p_user;
}

/**
 * Insert all default color names and rule names for the current rule 
 * base into the parent rule combo box. 
 *  
 * @param rb   Symbol coloring scheme (rule base) 
 */
static void loadParentRuleList(se.color.SymbolColorRuleBase *rb)
{
   ctl_parent_color._lbclear();
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_WINDOW_TEXT)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_FUNCTION)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_KEYWORD)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_PREPROCESSOR)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_LIBRARY_SYMBOL)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_USER_DEFINED_SYMBOL)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_HIGHLIGHT)"--");
   ctl_parent_color._lbadd_item("--"get_message(VSRC_CFG_SYMBOL_HIGHLIGHT)"--");

   foreach (auto i in rb->getNumRules()) {
      se.color.SymbolColorRule *rule = rb->getRule(i-1);
      if (rule == null) continue;
      ctl_parent_color._lbadd_item(rule->m_ruleName);
   }
}

/**
 * Load all the information about the scheme with the given name into 
 * the symbol coloring configuration dialog.  Generally speaking, this 
 * function fills in the tree control containing the list of rules. 
 *  
 * @param name    Symbol coloring scheme name 
 */
static void loadScheme(_str name, boolean loadCurrentScheme=false) 
{
   scc := getSymbolColorConfig();
   if (scc == null) return;

   // find the selected rule base by name
   se.color.SymbolColorRuleBase *rb = scc->getCurrentScheme();
   if (!loadCurrentScheme || rb == null || rb->m_name != name) {
      rb = scc->getScheme(name);
      if (rb == null) return;
      scc->setCurrentScheme(*rb);
   }

   origIgnore := scc->isIgnoringChanges();
   scc->ignoreChanges(true);

   // set up the list of compatible color schemes
   compatibleCaption := ctl_compatibility_label.p_caption;
   parse compatibleCaption with auto compatibleLabel ":" auto compatibleList;
   compatibleList = (rb != null)? rb->getCompatibleColorSchemes() : "";
   if (compatibleList == "") compatibleList = "All color schemes";
   ctl_compatibility_label.p_caption = compatibleLabel ": " compatibleList;
   
   // set up the parent rule list with the default colors
   // and this scheme's rule names 
   ctl_parent_color.loadParentRuleList(rb);

   // load all the individual symbol color rules
   ctl_rules._TreeBeginUpdate(TREE_ROOT_INDEX);
   ctl_rules._TreeDelete(TREE_ROOT_INDEX,'c');
   foreach (auto i in rb->getNumRules()) {
      se.color.SymbolColorRule *rule = rb->getRule(i-1);
      if (rule == null) continue;
      treeIndex := ctl_rules._TreeAddItem(TREE_ROOT_INDEX, rule->m_ruleName, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
      loadRuleIntoTreeNode(rule, treeIndex);
   }
   ctl_rules._TreeEndUpdate(TREE_ROOT_INDEX);

   // save the scheme
   scc->setCurrentScheme(*rb);
   scc->ignoreChanges(origIgnore);
   scc->setModified(false);

   // finally, load the first rule
   ctl_rules._TreeTop();
   ctl_rules._TreeRefresh();
   rule := getSymbolColorRule();
   loadRule(rule);
}

/**
 * Refresh all the information about the currently selected rule
 * in the list of rule names and descriptions.
 */
static void updateCurrentRuleInTree()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;

   rule := getSymbolColorRule();
   if (rule == null) return;
   index := ctl_rules._TreeCurIndex();
   loadRuleIntoTreeNode(rule, index);
   ctl_rules.p_redraw=true;

   rb := getSymbolColorRuleBase();
   if (rb == null) return;
   scc->setModified(true);
}

/**
 * Update all the rules in the list of rule names and descriptions.
 * This needs to be called when a rule which other rules derive from 
 * changes color or font attributes. 
 */
static void updateAllRulesInTree()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;

   rb := getSymbolColorRuleBase();
   if (rb == null) return;

   treeIndex := ctl_rules._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (treeIndex > 0) {
      caption := ctl_rules._TreeGetCaption(treeIndex);
      parse caption with caption "\t" . ;
      rule := rb->getRuleByName(caption);
      if (rule != null) {
         loadRuleIntoTreeNode(rule, treeIndex);
      }
      treeIndex = ctl_rules._TreeGetNextSiblingIndex(treeIndex);
   }
}

/**
 * Load the given rule into the list of rules at the given tree index.
 *  
 * @param rule    Symbol coloring rule 
 * @param index   tree index
 */
static void loadRuleIntoTreeNode(se.color.SymbolColorRule *rule, int index)
{
   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   name := rule->m_ruleName;

   regex := "";
   if (rule->m_classRegex != null && rule->m_classRegex != "") {
      regex = "Class=\"":+rule->m_classRegex"\"";
   }
   if (rule->m_nameRegex != null && rule->m_nameRegex != "") {
      if (regex != "") {
         regex :+= ", ";
      }
      regex :+= "Name=\"":+rule->m_nameRegex"\"";
   }
   if (regex != "") {
      regex = ", ":+regex;
   }

   // need table to fill in attributes
   _str attrsOn[];
   _str attrsOff[];
   foreach (auto tagFlag => auto rc_code in gTagAttributeMap) {
      if ((rule->m_attributeFlagsOn & tagFlag) == tagFlag) {
         attrsOn[attrsOn._length()] = get_message(rc_code);
      } else if ((rule->m_attributeFlagsOff & tagFlag) == tagFlag) {
         attrsOff[attrsOff._length()] = get_message(rc_code);
      }
   }

   tagTypeArray := rule->getTagTypes();
   kinds := join(tagTypeArray, ", ");

   attrs := "";
   if (attrsOn._length() > 0) {
      attrs :+= ": ";
      attrs :+= join(attrsOn, ", ");
   }
   if (attrsOff._length() > 0) {
      attrs :+= (attrs != "")? ",":":";
      attrs :+= " EXCLUDE ";
      attrs :+= join(attrsOff, ", ");
   }
   
   ctl_rules._TreeSetCaption(index, name"\t"kinds:+regex:+attrs);

   if (rule->m_colorInfo != null) {
      font_flags := rule->m_colorInfo.getFontFlags(rb);
      font_flags &= ~(F_INHERIT_BG_COLOR|F_INHERIT_FG_COLOR|F_INHERIT_STYLE|F_INHERIT_COLOR_ADD_STYLE);
      ctl_rules._TreeSetColor(index, 1, 
                              rule->m_colorInfo.getForegroundColor(rb),
                              rule->m_colorInfo.getBackgroundColor(rb),
                              font_flags);
   }
}

/**
 * Change the text in the color selection box depending on whether
 * it is currently enabled or not.  Display slashes when it is
 * disabled, and a message saying to click here when it is enabled.
 */
static void enableColorControl()
{
   boolean inherit = (p_prev.p_value != 0);
   orig_width := p_width;
   p_forecolor = 0x606060;
   if (inherit) {
      p_caption = "/////////////////////////////";
   } else {
      p_caption = "Click to change color...";
   }
   p_width = orig_width; 
}

/**
 * Load the given rule into the Symbol coloring dialog. 
 *  
 * @param rule    Symbol coloring rule 
 */
static void loadRule(se.color.SymbolColorRule *rule)
{
   // get the symbol color configuration manager object
   scc := getSymbolColorConfig();
   if (scc == null) return;

   // if they gave us a null rule, disable everything, otherwise enable form
   if (rule == null) {
      enableEntireRuleForm(false);
      return;
   }
   if (ctl_rule_name.p_enabled == false) {
      enableEntireRuleForm(true);
   }

   // disable all on_change callbacks
   origIgnore := scc->isIgnoringChanges();
   scc->ignoreChanges(true);

   // fill in the rule name an dregular expression options
   ctl_rule_name.p_text = rule->m_ruleName;
   ctl_regex_type.p_text = getRegexCaption(rule->m_regexOptions);
   ctl_regex_type._lbfind_and_select_item(rule->m_regexOptions);
   ctl_class_re.p_text  = rule->m_classRegex? rule->m_classRegex:"";
   ctl_name_re.p_text   = rule->m_nameRegex?  rule->m_nameRegex:"";
   
   // fill in the parent rule, it may be a default color
   parentRuleName := rule->m_colorInfo.m_parentName;
   if (parentRuleName == null) {
      ctl_parent_color.p_text = "Window Text";
   } else {
      switch(parentRuleName) {
      case "":
      case CFG_WINDOW_TEXT:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_WINDOW_TEXT)"--");
         break;
      case CFG_FUNCTION:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_FUNCTION)"--");
         break;
      case CFG_KEYWORD:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_KEYWORD)"--");
         break;
      case CFG_PPKEYWORD:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_PREPROCESSOR)"--");
         break;
      case CFG_LIBRARY_SYMBOL:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_LIBRARY_SYMBOL)"--");
         break;
      case CFG_USER_DEFINED:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_USER_DEFINED_SYMBOL)"--");
         break;
      case CFG_HILIGHT:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_HIGHLIGHT)"--");
         break;
      case CFG_SYMBOL_HIGHLIGHT:
         ctl_parent_color.p_text = ("--"get_message(VSRC_CFG_SYMBOL_HIGHLIGHT)"--");
         break;
      default:
         ctl_parent_color.p_text = parentRuleName;
         break;
      }
   }

   // fill in the color information
   rb := getSymbolColorRuleBase();
   ctl_foreground_color.p_backcolor = rule->m_colorInfo.getForegroundColor(rb);
   ctl_background_color.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
   ctl_foreground_inherit.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_INHERIT_FG_COLOR)? 1:0;  
   ctl_background_inherit.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_INHERIT_BG_COLOR)? 1:0;
   ctl_foreground_color.enableColorControl();
   ctl_background_color.enableColorControl();

   // fill in the font information
   ctl_font_inherit.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_INHERIT_STYLE)? 1:0;
   ctl_italic.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_ITALIC)? 1:0;  
   ctl_bold.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_BOLD)? 1:0;  
   ctl_underline.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_UNDERLINE)? 1:0;  
   ctl_normal.p_value = (rule->m_colorInfo.getFontFlags(rb) & (F_ITALIC|F_BOLD|F_UNDERLINE))? 0:1;
   ctl_italic.p_enabled = (ctl_font_inherit.p_value == 0);
   ctl_bold.p_enabled = (ctl_font_inherit.p_value == 0);
   ctl_underline.p_enabled = (ctl_font_inherit.p_value == 0);
   ctl_normal.p_enabled = (ctl_font_inherit.p_value == 0);
   
   // fill in the sample color display
   ctl_sample.p_forecolor = ctl_foreground_color.p_backcolor;  
   ctl_sample.p_backcolor = ctl_background_color.p_backcolor;
   ctl_sample.p_font_bold = (rule->m_colorInfo.getFontFlags(rb) & F_BOLD) != 0;
   ctl_sample.p_font_italic = (rule->m_colorInfo.getFontFlags(rb) & F_ITALIC) != 0;
   ctl_sample.p_font_underline = (rule->m_colorInfo.getFontFlags(rb) & F_UNDERLINE) != 0;

   // fill in tag types
   index := ctl_types._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      type_name := ctl_types._TreeGetUserInfo(index);
      state := rule->hasTagType(type_name)? TCB_CHECKED:TCB_UNCHECKED;
      ctl_types._TreeSetCheckState(index, state);
      index = ctl_types._TreeGetNextSiblingIndex(index);
   }
 
   // fill in tag attributes   
   index = ctl_attributes._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      state := TCB_PARTIALLYCHECKED;
      tag_flag := ctl_attributes._TreeGetUserInfo(index);
      if ((rule->m_attributeFlagsOn & tag_flag) == tag_flag) {
         state = TCB_CHECKED;
      } else if ((rule->m_attributeFlagsOff & tag_flag) == tag_flag) {
         state = TCB_UNCHECKED;
      }
      ctl_attributes._TreeSetCheckState(index, state);
      index = ctl_attributes._TreeGetNextSiblingIndex(index);
   }

   // done, back to business as usual 
   scc->ignoreChanges(origIgnore);
}

/**
 * Load the symbol coloring scheme names into a combo box 
 *  
 * @param scc              symbol coloring configuration manager object 
 * @param colorSchemeName  only load schemes compatible with this master scheme
 */
void _lbaddSymbolColoringSchemeNames(se.color.SymbolColorConfig &scc, _str colorSchemeName="")
{
   // load all the scheme names into the combo box, putting
   // user defined schemes at the top of the list.
   parse colorSchemeName with colorSchemeName "(modified)";
   colorSchemeName = strip(colorSchemeName);
   schemeNames := scc.getSchemeNames();
   name := "";
   _lbclear();

   foreach (name in schemeNames) {
      if (!scc.isUserScheme(name)) continue;
      rb := scc.getScheme(name);
      if (rb != null && rb->isCompatibleWithColorScheme(colorSchemeName)) {
         _lbadd_item(name,60,"");
      }
   }

   p_picture = _pic_lbvs;

   foreach (name in schemeNames) {
      if (scc.isUserScheme(name)) continue;
      rb := scc.getScheme(name);
      if (rb != null && rb->isCompatibleWithColorScheme(colorSchemeName)) {
         _lbadd_item(name,60,_pic_lbvs);
      }
   }
   p_pic_space_y = 60;
   p_pic_point_scale = 8;
}

/**
 * Initialize the Symbol coloring configuration dialog. 
 * The default scheme is which is loaded is whatever 
 * 'def_symbol_color_scheme' is set to. 
 */
void _symbol_color_form.on_create()
{
   _symbol_color_form_initial_alignment();

   // The symbol color configuration dialog manager object goes
   // in the p_user of 'ctl_scheme'
   ctl_scheme.p_user = null;
   se.color.SymbolColorConfig scc;

   // load default schemes and the current symbol coloring scheme
   scc.loadSystemSchemes();
   scc.loadUserSchemes();
   scc.loadCurrentScheme();
   
   // load all the scheme names into the combo box, putting
   // user defined schemes at the top of the list.
   ctl_scheme._lbaddSymbolColoringSchemeNames(scc);

   // determine the current scheme, select none if we do not have one
   currentSchemeName := "";
   if (currentSchemeName == "" && def_symbol_color_scheme != null) {
      currentSchemeName = def_symbol_color_scheme.m_name;
   }
   ctl_scheme.p_text = currentSchemeName;
   rb := scc.getScheme(currentSchemeName);

   // enable and disable buttons based on whether this scheme is 
   // a user/system scheme
   ctl_delete_scheme.p_enabled = ctl_rename_scheme.p_enabled = scc.isUserScheme(currentSchemeName);
   ctl_reset_scheme.p_enabled = scc.isModifiedSystemScheme(currentSchemeName);

   // set up the list of compatible color schemes
   compatibleCaption := ctl_compatibility_label.p_caption;
   parse compatibleCaption with auto compatibleLabel ":" auto compatibleList;
   if (rb == null) {
      compatibleList = "";
   } else {
      compatibleList = rb->getCompatibleColorSchemes();
   }
   if (compatibleList == "") compatibleList = "All color schemes";
   ctl_compatibility_label.p_caption = compatibleLabel ": " compatibleList; 
   
   // set up the symbol rule list tree control
   columnWidth := ctl_rules.p_width intdiv 3;
   ctl_rules._TreeSetColButtonInfo(0, columnWidth, TREE_BUTTON_AUTOSIZE, -1, "Rule name"); 
   ctl_rules._TreeSetColButtonInfo(1, columnWidth*2, TREE_BUTTON_WRAP, -1, "Symbol declaration");
   ctl_rules._TreeAdjustLastColButtonWidth(); 

   // insert all of the standard tag types, as well as the special
   // item for symbol not found
   tree_index := 0;
   ctl_types._TreeBeginUpdate(TREE_ROOT_INDEX);
   for (i:=1; i<=VS_TAGTYPE_MAXIMUM; i++) {
      tag_get_type(i, auto type_name);
      if (tag_tree_type_is_statement(type_name)) continue;
      if (type_name == '') continue;
      if (type_name == "tag" || type_name == "taguse") continue;
      description := tag_type_get_description(i);
      if (description == null || description == '') description = type_name;
      tree_index = ctl_types._TreeAddItem(TREE_ROOT_INDEX, description, TREE_ADD_AS_CHILD,
                                          0, 0, TREE_NODE_LEAF, 0, type_name);
      ctl_types._TreeSetCheckable(tree_index, 1, 0);
   }
   tree_index = ctl_types._TreeAddItem(TREE_ROOT_INDEX, SYMBOL_COLOR_NOT_FOUND, TREE_ADD_AS_CHILD,
                                        0, 0, TREE_NODE_LEAF, 0, "UNKNOWN");
   ctl_types._TreeSetCheckable(tree_index, 1, 0);
   ctl_types._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_types._TreeSortCaption(TREE_ROOT_INDEX);

   // insert all the the symbol tag attributes
   ctl_attributes._TreeBeginUpdate(TREE_ROOT_INDEX);
   foreach (auto tag_flag => auto rc_code in gTagAttributeMap) {
      attr_description := get_message(rc_code);
      if (attr_description == null || attr_description=='') continue;
      tree_index = ctl_attributes._TreeAddItem(TREE_ROOT_INDEX, 
                                               attr_description, TREE_ADD_AS_CHILD,
                                               0, 0, TREE_NODE_LEAF, 0, tag_flag);
      ctl_attributes._TreeSetCheckable(tree_index, 1, 1);
   }
   ctl_attributes._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_attributes._TreeSortCaption(TREE_ROOT_INDEX);

   // load regular expression types
   ctl_regex_type._lbadd_item(RE_TYPE_UNIX_STRING);
   ctl_regex_type._lbadd_item(RE_TYPE_BRIEF_STRING);
   ctl_regex_type._lbadd_item(RE_TYPE_SLICKEDIT_STRING);
   ctl_regex_type._lbadd_item(RE_TYPE_PERL_STRING);
   ctl_regex_type._lbadd_item(RE_TYPE_WILDCARD_STRING);
   ctl_regex_type._lbadd_item(RE_TYPE_NONE);
   ctl_regex_type.p_enabled = true;
   ctl_regex_type._lbfind_and_select_item(RE_TYPE_NONE);
   ctl_sample._use_edit_font();

   // finally, load the current symbol coloring scheme into the form 
   ctl_scheme.p_user = scc;
   loadScheme(currentSchemeName,true);

   // check if there is a rule we should pre-select, corresponding to the
   // current symbol under the cursor.
   if (!_no_child_windows()) {
      se.color.SymbolColorAnalyzer *analyzer = _mdi.p_child._GetBufferInfoHtPtr("SymbolColorAnalyzer");
      if (analyzer != null) {
         orig_wid := p_window_id;
         p_window_id = _mdi.p_child;
         currentRule := analyzer->getSymbolColorUnderCursor();
         p_window_id = orig_wid;
         if (currentRule != null) {
            treeIndex := ctl_rules._TreeSearch(TREE_ROOT_INDEX, currentRule->m_ruleName, "P");
            if (treeIndex > 0) {
               ctl_rules._TreeSetCurIndex(treeIndex);
            }
         }
      }
   }

}

/**
 * Cleanup
 */
void _symbol_color_form.on_destroy()
{
   // destroy the config object
   p_user = null;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _symbol_color_form_initial_alignment()
{
   rightAlign := ctl_scheme_divider.p_x + ctl_scheme_divider.p_width;
   alignUpDownListButtons(ctl_rules, rightAlign, ctl_insert_rule.p_window_id,
                          ctl_up_rule.p_window_id, ctl_down_rule.p_window_id, ctl_delete_rule.p_window_id);
}

/**
 * Handle form resizing.  Stretches out the rule list
 * vertically.  Stretches out kinds and attributes horizontally. 
 * Other items remain in the same relative positions. 
 */
void _symbol_color_form.on_resize()
{
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      min_rules_height := ctl_delete_rule.p_y+ctl_delete_rule.p_height - ctl_insert_rule.p_y;
      _set_minimum_size(ctl_save_scheme_as.p_width*6, min_rules_height*5);
   }

   // total size
   width  := _dx2lx(p_xyscale_mode,p_active_form.p_client_width);
   height := _dy2ly(p_xyscale_mode,p_active_form.p_client_height);

   // calculate the horizontal and vertical adjustments
   adjust_x := (width - ctl_rename_scheme.p_width - ctl_rules.p_x) - ctl_rename_scheme.p_x;
   adjust_y := (height - ctl_regex_frame.p_height - ctl_scheme.p_y) - ctl_regex_frame.p_y;

   // adjust the scheme buttons
   ctl_rename_scheme.p_x += adjust_x; 
   ctl_delete_scheme.p_x += adjust_x;
   ctl_reset_scheme.p_x += adjust_x;
   ctl_save_scheme_as.p_x += adjust_x;
   ctl_scheme.p_width += adjust_x;
   ctl_compatibility_label.p_width += adjust_x;
   ctl_compatibility.p_x += adjust_x;
   ctl_scheme_divider.p_width += adjust_x;

   // adjust the rules table and buttons
   orig_tree_width := ctl_rules.p_width;
   ctl_rules.p_width += adjust_x;
   ctl_rules.p_height += adjust_y;
   ctl_insert_rule.p_x += adjust_x;
   ctl_up_rule.p_x += adjust_x;
   ctl_down_rule.p_x += adjust_x;
   ctl_delete_rule.p_x += adjust_x;
   ctl_rules._TreeScaleColButtonWidths(orig_tree_width, true);

   // adjust the frame positions
   ctl_rule_frame.p_y += adjust_y;
   ctl_regex_frame.p_y += adjust_y;
   ctl_color_frame.p_y += adjust_y;
   ctl_type_frame.p_y = ctl_attr_frame.p_y = ctl_rule_frame.p_y;

   // adjust the symbol type frame size
   ctl_type_frame.p_width += (adjust_x intdiv 2);
   ctl_attr_frame.p_width = ctl_type_frame.p_width;
   ctl_attr_frame.p_x += (adjust_x intdiv 2);
   ctl_types.p_width += (adjust_x intdiv 2);
   ctl_attributes.p_width = ctl_types.p_width;

   // adjust the regular expression frame
   ctl_regex_frame.p_width += adjust_x;
   ctl_regex_type.p_width += adjust_x;
   ctl_class_re.p_width += adjust_x;
   ctl_name_re.p_width += adjust_x;
}

/**
 * Callback for handling the [OK] or [Apply] buttons on the
 * master configuration dialog when the symbol coloring
 * properties are modified and need to be recalculated.
 */
void _symbol_color_form_apply()
{
   rb := getSymbolColorRuleBase();
   if (rb == null) return;
   def_symbol_color_scheme = *rb;

   // automatically save the current scheme
   saveCurrentScheme(def_symbol_color_scheme.m_name);

   SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme);
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

/**
 * Callback to check if the symbol coloring has been modified 
 * since it was first loaded into the dialog. 
 *  
 * @return 'true' if the coloring had been modified.
 */
boolean _symbol_color_form_is_modified()
{
   scc := getSymbolColorConfig();
   if (scc == null) return false;
   rb := getSymbolColorRuleBase();
   if (rb == null) return false;
   return scc->isModified();
}

/**
 * Callback to restore the symbol coloring options back to their 
 * original state for the given scheme name. 
 *  
 * @param scheme_name   symbol coloring scheme name 
 */
void _symbol_color_form_restore_state(_str scheme_name)
{
   scc := getSymbolColorConfig();
   if (scc == null) return;

   rb := scc->getScheme(scheme_name);
   if (rb == null) return;

   scc->setCurrentScheme(*rb);
   scc->setModified(false);
   ctl_scheme.p_text = rb->m_name;
}

/**
 * Callback to export the symbol coloring options.
 * 
 * @param path             path where user symbol coloring schemes should be 
 *                         copied
 * @param currentScheme    the current scheme
 * 
 * @return                 any errors from the export
 */
_str _symbol_color_form_export_settings(_str &path, _str &currentScheme)
{
   error := '';

   // copy our user schemes to the given path
   se.color.SymbolColorConfig scc;
   filename := scc.getUserSymbolColorConfigFile();
   if (filename != '' && file_exists(filename)) {
       filenameOnly := _strip_filename(filename, 'P');
       if (!copy_file(filename, path :+ filenameOnly)){
           path = filenameOnly;
       } else error = 'Error copying symbol coloring schemes file, 'filename'.' :+ OPTIONS_ERROR_DELIMITER;
   }

   // save our current scheme
   currentScheme = def_symbol_color_scheme.m_name;

   return error;
}

/**
 * Callback to import the symbol coloring options from a previous export.
 * 
 * @param path                      file where schemes can be found
 * @param currentScheme             name of the current color scheme
 * 
 * @return                          any errors from the import
 */
_str _symbol_color_form_import_settings(_str path, _str currentScheme)
{
   error := '';

   se.color.SymbolColorConfig scc;

   // import the schemes
   scc.loadEmptyScheme();
   scc.loadSystemSchemes();
   scc.loadUserSchemes();
   scc.loadCurrentScheme();
   
   if (path != '') {
      if (scc.importUserSchemes(path)) error = 'Error importing color schemes from 'path'.' :+ OPTIONS_ERROR_DELIMITER;
   }

   se.color.SymbolColorRuleBase * scrb = scc.getScheme(currentScheme);
   if (scrb != null) {
      def_symbol_color_scheme = *scrb;
      SymbolColorAnalyzer.initAllSymbolAnalyzers(&def_symbol_color_scheme);
   } else error :+= 'Error setting current symbol coloring scheme to 'currentScheme'.' :+ OPTIONS_ERROR_DELIMITER;

   return error;
}

/**
 * Enable or disable the symbol coloring form controls for editing 
 * the current rule. 
 *  
 * @param onoff   'true' to enable, 'false' to disable 
 */
static void enableEntireRuleForm(boolean onoff)
{
   ctl_attributes.p_enabled=onoff;
   ctl_background_inherit.p_enabled=onoff;
   ctl_background_label.p_enabled=onoff;
   ctl_bold.p_enabled=onoff;
   ctl_class_re.p_enabled=onoff;
   ctl_class_re_label.p_enabled=onoff;
   ctl_color_frame.p_enabled=onoff;
   ctl_delete_rule.p_enabled=onoff;
   ctl_down_rule.p_enabled=onoff;
   ctl_font_inherit.p_enabled=onoff;
   ctl_foreground_inherit.p_enabled=onoff;
   ctl_foreground_label.p_enabled=onoff;
   ctl_italic.p_enabled=onoff;
   ctl_name_re.p_enabled=onoff;
   ctl_name_re_label.p_enabled=onoff;
   ctl_normal.p_enabled=onoff;
   ctl_parent_color.p_enabled=onoff;
   ctl_parent_label.p_enabled=onoff;
   ctl_regex_frame.p_enabled=onoff;
   ctl_regex_type.p_enabled=onoff;
   ctl_rule_frame.p_enabled=onoff;
   ctl_rule_name.p_enabled=onoff;
   ctl_sample.p_enabled=onoff;
   ctl_type_frame.p_enabled=onoff;
   ctl_attr_frame.p_enabled=onoff;
   ctl_types.p_enabled=onoff;
   ctl_underline.p_enabled=onoff;
   ctl_use_label.p_enabled=onoff;
   ctl_up_rule.p_enabled=onoff;

}

/**
 * Handle actions that occur in the rule list, such as when the 
 * user selects a different node. 
 *  
 * @param reason     type of event 
 * @param index      current tree index
 */
void ctl_rules.on_change(int reason,int index)
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) {
      return;
   }

   if (_TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
      enableEntireRuleForm(false);
      return;
   }

   switch (reason) {
   case CHANGE_CLINE:
   case CHANGE_SELECTED:
      if (ctl_rule_frame.p_enabled==false) {
         enableEntireRuleForm(true);
      }
      
      loadRule(getSymbolColorRule());
      break;
   }

}

/**
 * Handle deleting the currently selected rule.
 */
void ctl_delete_rule.lbutton_up()
{
   index := ctl_rules._TreeCurIndex();
   if (index <= 0) return;

   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   ruleCaption := ctl_rules._TreeGetCaption(index);
   parse ruleCaption with auto ruleName "\t" . ;
   rb->removeRuleByName(ruleName);

   ctl_rules._TreeDelete(index);
   loadRule(getSymbolColorRule());
}
void ctl_rules.DEL()
{
   call_event(ctl_delete_rule,LBUTTON_UP,'w');
}

/**
 * Handle moving the current rule down one step.
 */
void ctl_down_rule.lbutton_up()
{
   index := ctl_rules._TreeCurIndex();
   if (index <= 0) return;

   nextIndex := ctl_rules._TreeGetNextIndex(index);
   if (nextIndex <= 0) return;

   ruleCaption1 := ctl_rules._TreeGetCaption(index);
   parse ruleCaption1 with auto ruleName1 "\t" . ;
   ruleCaption2 := ctl_rules._TreeGetCaption(nextIndex);
   parse ruleCaption2 with auto ruleName2 "\t" . ;

   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   rb->swapRules(ruleName1, ruleName2);
   ctl_rules._TreeMoveDown(index);
}

/**
 * Handle moving the current rule up one step.
 */
void ctl_up_rule.lbutton_up()
{
   index := ctl_rules._TreeCurIndex();
   if (index <= 0) return;

   prevIndex := ctl_rules._TreeGetPrevIndex(index);
   if (prevIndex <= 0) return;

   ruleCaption1 := ctl_rules._TreeGetCaption(prevIndex);
   parse ruleCaption1 with auto ruleName1 "\t" . ;
   ruleCaption2 := ctl_rules._TreeGetCaption(index);
   parse ruleCaption2 with auto ruleName2 "\t" . ;

   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   rb->swapRules(ruleName1, ruleName2);
   ctl_rules._TreeMoveDown(prevIndex);
}

/**
 * Handle inserting a new symbol coloring rule. 
 * Inserts the rule and places focus on the rule name for editing. 
 */
void ctl_insert_rule.lbutton_up()
{
   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   se.color.ColorInfo color;
   color.getColor(CFG_WINDOW_TEXT);
   se.color.SymbolColorRule rule;
   rule.m_ruleName = "(New)";
   rule.m_colorInfo = color;

   position := ctl_rules._TreeCurLineNumber();
   rb->addRule(rule, position);

   treeIndex := ctl_rules._TreeCurIndex();
   if (ctl_rules._TreeGetNumChildren(TREE_ROOT_INDEX)==0) {
      treeIndex = ctl_rules._TreeAddItem(TREE_ROOT_INDEX, rule.m_ruleName, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
   } else {
      treeIndex = ctl_rules._TreeAddItem(treeIndex, rule.m_ruleName, TREE_ADD_AFTER, 0, 0, -1, 0);
   }
   ctl_rules._TreeSetCurIndex(treeIndex);
   loadRule(&rule);
   loadRuleIntoTreeNode(&rule, treeIndex);
   ctl_rule_name._set_focus();

   scc := getSymbolColorConfig();
   if (scc != null) scc->setModified(true);
}

/**
 * Prompt the user for a new symbol color scheme name, this is done both 
 * for saving the current scheme and renaming the scheme. 
 *  
 * @param scc              symbol coloring configuration manager object
 * @param origSchemeName   original scheme name (being renamed or saved) 
 * @param allowSameName    allow them to use the same name (to save a user scheme) 
 * 
 * @return '' if they cancelled, otherwise returns the new scheme name 
 */
static _str getSymbolColorSchemeName(se.color.SymbolColorConfig &scc, 
                                     _str origSchemeName, boolean allowSameName=false)
{
   // prompt the user for a new scheme name
   loop {
      status := textBoxDialog("Enter Scheme Name", 0, 0, 
                              "New Symbol Color Scheme dialog", 
                              "", "", " Scheme name:":+origSchemeName);
      if (status < 0) {
         break;
      }
      newSchemeName := _param1;
      if (newSchemeName == "") {
         break;
      }

      // verify that the new name does not duplicate an existing name
      if (scc.getScheme(newSchemeName) == null) {
         return newSchemeName;
      }

      // allow them to save a scheme with the same name as before
      if (newSchemeName == origSchemeName && allowSameName) {
         return newSchemeName;
      }

      _message_box("There is already a scheme named \""newSchemeName".\"");
      continue;
   }

   // command cancelled due to error
   return "";
}

/**
 * Handle switching schemes.  If the current scheme is modified from it's 
 * saved settings, prompt the user before switching schemes. 
 *  
 * @param reason  event type
 */
void ctl_scheme.on_change(int reason)
{
   if (reason == CHANGE_CLINE) {

      scc := getSymbolColorConfig();
      if (scc == null) return;
      if (scc->isIgnoringChanges()) return;
      rb := getSymbolColorRuleBase();
      if (rb==null) return;
     
      // prompt about saving the former scheme
      orig_rb := scc->getScheme(rb->m_name);
      if (orig_rb == null || *orig_rb != *rb) {
         buttons := "&Save Changes,&Discard Changes,Cancel:_cancel\t-html The current scheme has been modified.  Would you like to save your changes?";

         status := textBoxDialog('SlickEdit Options',
                                 0,
                                 0,
                                 'Modified Color Scheme',
                                 buttons);
         if (status == 1) {            // Save - the first button
            saveCurrentScheme(rb->m_name);
         } else if (status == 2) {     // Discard Changes - the second button
            loadScheme(rb->m_name);
         } else {                      // Cancel our cancellation
            ctl_scheme.p_text = rb->m_name;
            return;
         }
      }

      // warn them if the selected scheme is not compatible with the
      // current color scheme
      schemeName := strip(p_text);
      rb = scc->getScheme(schemeName);
      parse def_color_scheme with auto colorSchemeName '(' . ;
      if (rb != null && !rb->isCompatibleWithColorScheme(strip(colorSchemeName))) {
         result := _message_box(get_message(VSRC_CFG_COLOR_SCHEME_INCOMPATIBLE),'',MB_YESNO|MB_ICONQUESTION);
         if ( result == IDNO ) {
            ctl_scheme.p_text = orig_rb->m_name;
            return; //exit, no change
         }
      }

      loadScheme(schemeName);
      scc->setModified(true);

      // enable and disable buttons based on whether this scheme is 
      // a user/system scheme
      ctl_delete_scheme.p_enabled = ctl_rename_scheme.p_enabled = scc -> isUserScheme(schemeName);
      ctl_reset_scheme.p_enabled = scc -> isModifiedSystemScheme(schemeName);
   }
}

/**
 * Delete the current scheme.  Do not allow them to delete system schemes.
 */
void ctl_delete_scheme.lbutton_up()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   if (!scc->isUserScheme(rb->m_name)) {
      _message_box(get_message(VSRC_CFG_CANNOT_REMOVE_SYSTEM_SCHEMES));
      return;
   }

   scc->setModified();
   scc->deleteScheme(rb->m_name);
   scc->saveUserSchemes();

   ctl_scheme._lbdelete_item();
   ctl_scheme._lbdown();
   ctl_scheme.p_text = ctl_scheme._lbget_text();
   loadScheme(ctl_scheme._lbget_text());
}

/**
 * Resets the current scheme back to its installed configuration.  Only allowed 
 * on System schemes that have been modified. 
 */
void ctl_reset_scheme.lbutton_up()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   rb := getSymbolColorRuleBase();
   if (rb==null) return;

   name := rb->m_name;
   if (scc->isModifiedSystemScheme(name)) {
      scc->resetScheme(name);
      scc->saveUserSchemes();

      loadScheme(name);

      ctl_reset_scheme.p_enabled = false;

      scc->setModified();
   }
}

/**
 * Save the current scheme under a new name as a user-defined scheme.
 */
void ctl_save_scheme_as.lbutton_up()
{
   saveCurrentScheme();
}

static void saveCurrentScheme(_str newSchemeName = "")
{
   // get the configuration object
   scc := getSymbolColorConfig();
   if (scc == null) return;
   rb := getSymbolColorRuleBase();
   if (rb == null) return;

   // prompt the user for a new scheme name
   origSchemeName := rb->m_name;

   if (newSchemeName == "") {
      newSchemeName = getSymbolColorSchemeName(*scc, origSchemeName, scc->isUserScheme(origSchemeName));
   }
   if (newSchemeName == "") return;

   rb->m_name = newSchemeName;
   if (newSchemeName != origSchemeName) {
      scc->addScheme(*rb, true); 
      ctl_scheme._lbbottom();
      ctl_scheme._lbadd_item(newSchemeName,60,"");
      ctl_scheme.p_text = newSchemeName;
   } else {
      saved_rb := scc->getScheme(origSchemeName);
      *saved_rb = *rb;
   }
   if (origSchemeName != newSchemeName) ctl_scheme.p_text = newSchemeName;
   scc->saveUserSchemes();

   scc->setModified(false);
}

/**
 * Rename the current scheme.  Do not allow them to rename system 
 * default schemes. 
 */
void ctl_rename_scheme.lbutton_up()
{
   // get the configuration object
   scc := getSymbolColorConfig();
   if (scc == null) return;
   rb := getSymbolColorRuleBase();
   if (rb == null) return;

   // only allow them to rename user schemes
   origSchemeName := rb->m_name;
   if (!scc->isUserScheme(origSchemeName)) {
      _message_box(get_message(VSRC_CFG_CANNOT_FIND_USER_SCHEME, origSchemeName));
      return;
   }

   // prompt the user for a new scheme name
   newSchemeName  := getSymbolColorSchemeName(*scc, origSchemeName);
   if (newSchemeName == "") return;

   rb->m_name = newSchemeName; 
   scc->addScheme(*rb, true);
   scc->deleteScheme(origSchemeName);
   ctl_scheme._lbset_item(newSchemeName);
   ctl_scheme.p_text = newSchemeName;
   scc->saveUserSchemes();
   scc->setModified(true);
}

/**
 * Rename the current scheme.  Do not allow them to rename system 
 * default schemes. 
 */
void ctl_compatibility.lbutton_up()
{
   // get the configuration object
   scc := getSymbolColorConfig();
   if (scc == null) return;
   rb := getSymbolColorRuleBase();
   if (rb == null) return;

   // find all the user defined color schemes
   orig_wid := p_window_id;
   typeless i;
   schemeName := "";
   _str colorSchemeNames[];
   userini := usercfg_path_search(VSCFGFILE_USER_COLORSCHEMES);
   if (userini != "") {
      _ini_get_sections_list(userini, auto userSchemeNames);
      colorSchemeNames = userSchemeNames;
   }

   // and all the system color schemes
   sysini  := get_env("VSROOT"):+VSCFGFILE_COLORSCHEMES;
   if (sysini != "") {
      _ini_get_sections_list(sysini, auto sysSchemeNames);
      for (i = 0; i < sysSchemeNames._length(); ++i) {
         colorSchemeNames[colorSchemeNames._length()] = sysSchemeNames[i];
      }
   }
   p_window_id = orig_wid;

   // build a list of which ones are compatible
   _str schemeNameIndexes[];
   boolean selectedSchemeNames[];
   selectedSchemeNames[colorSchemeNames._length()-1] = false;
   for (i = 0; i < colorSchemeNames._length(); ++i) {
      schemeName = colorSchemeNames[i];
      schemeNameIndexes[i] = i;
      selectedSchemeNames[i] = rb->isCompatibleWithColorScheme(schemeName);
   }

   // prompt them to select which ones are compatible
   result := '';
   do {
      result = select_tree(colorSchemeNames, 
                                schemeNameIndexes, null, null, 
                                selectedSchemeNames, null, null,
                                "Compatible Color Schemes",
                                SL_CHECKLIST|SL_SELECTALL|SL_INVERT, 
                                null, null, true,
                                "Compatible Color Schemes dialog box");
      if (result == '') {
         _message_box("If no color schemes are marked as compatible, you will not be ":+
                      "able to use this symbol coloring scheme.  Please select at least ":+
                      "one compatible color scheme.", "Compatible Color Schemes");
      }

   } while (result == '');

   p_window_id = orig_wid;

   if (result == null || result == COMMAND_CANCELLED_RC) {
      return;
   }

   // pull the information back in
   _str compatibleSchemes[];
   while (result != "") {
      parse result with i "\n" result;
      if (!isinteger(i)) continue;
      compatibleSchemes[compatibleSchemes._length()] = colorSchemeNames[(int)i];
   }

   // we selected all, so just set it to blank
   if (compatibleSchemes._length() == colorSchemeNames._length()) {
      compatibleSchemes._makeempty();
   }

   rb = getSymbolColorRuleBase();
   rb->setCompatibleColorSchemes(compatibleSchemes);

   // set up the list of compatible color schemes
   compatibleCaption := ctl_compatibility_label.p_caption;
   parse compatibleCaption with auto compatibleLabel ":" auto compatibleList;
   compatibleList = rb->getCompatibleColorSchemes();
   if (compatibleList == "") compatibleList = "All color schemes";
   ctl_compatibility_label.p_caption = compatibleLabel ": " compatibleList;
   scc = getSymbolColorConfig();
   scc->setModified(true);

   // this may renamed the scheme to (modified) if it is a system scheme
   updateCurrentRuleInTree();
}

/**
 * Handle when the user toggles tag attribute flags on/off/don't care 
 * in the tree control containing all the tag attributes. 
 *  
 * @param reason     event type  
 * @param index      current tree index
 */
void ctl_attributes.on_change(int reason,int index)
{
   //say("HERE, reason="reason" index="index);
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;
   rule := getSymbolColorRule();
   if (rule == null) return;
   showChildren := 0;

   switch (reason) {
   case CHANGE_CHECK_TOGGLED:
      showChildren = _TreeGetCheckState(index);
      tree_flag := _TreeGetUserInfo(index);
      if (showChildren == TCB_PARTIALLYCHECKED) {
         rule->m_attributeFlagsOn &= ~tree_flag;
         rule->m_attributeFlagsOff &= ~tree_flag;
      } else if (showChildren == TCB_CHECKED) {
         rule->m_attributeFlagsOn |= tree_flag;
         rule->m_attributeFlagsOff &= ~tree_flag;
      } else if (showChildren == TCB_UNCHECKED) {
         rule->m_attributeFlagsOn &= ~tree_flag;
         rule->m_attributeFlagsOff |= tree_flag;
      }
      updateCurrentRuleInTree();
      break;
   }
}

/**
 * Handle when the user toggles tag types on/off/don't care 
 * in the tree control containing all the different kinds of symbols. 
 *  
 * @param reason     event type  
 * @param index      current tree index
 */
void ctl_types.on_change(int reason,int index)
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;
   rule := getSymbolColorRule();
   if (rule == null) return;

   switch (reason) {
   case CHANGE_CHECK_TOGGLED:
      // need table to fill in types
      _str typeList[];
      index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         showChildren := _TreeGetCheckState(index);
         if (showChildren > 0) {
            typeList[typeList._length()] = _TreeGetUserInfo(index);
         }
         index = _TreeGetNextSiblingIndex(index);
      }
      rule->setTagTypeArray(typeList);
      updateCurrentRuleInTree();
      break;
   }
}

/**
 * Handle changes to the currently selected symbol coloring rule name. 
 * Rule name changes are processed in the lost-focus event so that 
 * editing rules requires less processing and to minimize the number 
 * of renames. 
 */
void ctl_rule_name.on_lost_focus()
{
   rule := getSymbolColorRule();
   if (rule == null) return;
   rb := getSymbolColorRuleBase();
   if (rb == null) return;

   origRuleName := rule->m_ruleName;
   rule->m_ruleName = p_text;
   rb->renameRuleParents(origRuleName, p_text);
    
   index := ctl_rules._TreeCurIndex();
   loadRuleIntoTreeNode(rule, index);

   scc := getSymbolColorConfig();
   if (scc == null) return;
   scc->setModified(true);
   updateAllRulesInTree();
   loadParentRuleList(rb);
   updateCurrentRuleInTree();
}

/**
 * If the user hits "enter" after typing in a rule name, we should 
 * not dismiss the dialog, just transfer control to the rule list.
 */
void ctl_rule_name.enter()
{
   ctl_rules._set_focus();
}

/**
 * @return Return the search option (needed by {@link pos()} for the
 * selected regular expression.  (Unix='r', Brief='b', SlickEdit='r', 
 * and Wildcards='&').
 */
static _str getRegexSearchOption(_str caption)
{
   // TBF:  names should come from the message file
   switch (caption) {
   case RE_TYPE_UNIX_STRING:        return 'u';
   case RE_TYPE_BRIEF_STRING:       return 'b';
   case RE_TYPE_SLICKEDIT_STRING:   return 'r';
   case RE_TYPE_PERL_STRING:        return 'l';
   case RE_TYPE_WILDCARD_STRING:    return '&';
   case RE_TYPE_NONE:               return '';
   }
   return '';
}

/**
 * Return the caption corresponding to the given regular expression 
 * search option. 
 *  
 * @param searchOption     Regular expression search option, as 
 *                         required by pos() or search(). 
 * 
 * @return String describing this regular expression search option.
 */
static _str getRegexCaption(_str searchOption)
{
   // TBF:  names should come from the message file
   switch (searchOption) {
   case 'u':  return RE_TYPE_UNIX_STRING;
   case 'b':  return RE_TYPE_BRIEF_STRING;
   case 'r':  return RE_TYPE_SLICKEDIT_STRING;
   case 'l':  return RE_TYPE_PERL_STRING;
   case '&':  return RE_TYPE_WILDCARD_STRING;
   case '':   return RE_TYPE_NONE;
   }
   return RE_TYPE_NONE;
}

/**
 * Handle when the user changes the regular expression type. 
 */
void ctl_regex_type.on_change(int reason)
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;
   rule := getSymbolColorRule();
   if (rule == null) return;
   rule->m_regexOptions = getRegexSearchOption(p_text);
   updateCurrentRuleInTree();
}

/**
 * Handle when the user changes the class name regular expression.
 */
void ctl_class_re.on_change()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;
   rule := getSymbolColorRule();
   if (rule == null) return;
   rule->m_classRegex = p_text;
   updateCurrentRuleInTree();
}

/**
 * Handle when the user changes the symbol name regular expression.
 */
void ctl_name_re.on_change()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;
   rule := getSymbolColorRule();
   if (rule == null) return;
   rule->m_nameRegex = p_text;
   updateCurrentRuleInTree();
}

/** 
 * Handle when the user changes the color or rule which the current 
 * rule should inherit color settings from. 
 */
void ctl_parent_color.on_change(int reason)
{
   if (reason == CHANGE_CLINE) {
      rule := getSymbolColorRule();
      if (rule == null) return;
      rb := getSymbolColorRuleBase();
      if (rb == null) return;
      
      if ( p_text == "--"get_message(VSRC_CFG_WINDOW_TEXT)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_WINDOW_TEXT;
      } else if ( p_text == "--"get_message(VSRC_CFG_FUNCTION)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_FUNCTION;
      } else if ( p_text == "--"get_message(VSRC_CFG_KEYWORD)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_KEYWORD;
      } else if ( p_text == "--"get_message(VSRC_CFG_PREPROCESSOR)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_PPKEYWORD;
      } else if ( p_text == "--"get_message(VSRC_CFG_LIBRARY_SYMBOL)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_LIBRARY_SYMBOL;
      } else if ( p_text == "--"get_message(VSRC_CFG_USER_DEFINED_SYMBOL)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_USER_DEFINED;
      } else if ( p_text == "--"get_message(VSRC_CFG_HIGHLIGHT)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_HILIGHT;
      } else if ( p_text == "--"get_message(VSRC_CFG_SYMBOL_HIGHLIGHT)"--" ) {
         rule->m_colorInfo.m_parentName = CFG_SYMBOL_HIGHLIGHT;
      } else {
         rule->m_colorInfo.m_parentName = p_text;
      }

      updateCurrentRuleInTree();
      updateAllRulesInTree();
      ctl_bold.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_BOLD)? 1:0;
      ctl_italic.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_ITALIC)? 1:0;
      ctl_underline.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_UNDERLINE)? 1:0;
      ctl_normal.p_value = (ctl_bold.p_value==0 && ctl_italic.p_value==0 && ctl_underline.p_value==0)? 1:0;

      ctl_sample.p_font_bold = (ctl_bold.p_value != 0);
      ctl_sample.p_font_italic = (ctl_italic.p_value != 0);
      ctl_sample.p_font_underline = (ctl_underline.p_value != 0);

      ctl_foreground_color.p_backcolor = rule->m_colorInfo.getForegroundColor(rb);
      ctl_background_color.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
      ctl_sample.p_forecolor = rule->m_colorInfo.getForegroundColor(rb);
      ctl_sample.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
   }
}

/**
 * Handle changes in font settings.  This event handler is also used by
 * by the Inherit Font, Bold, Italic, and Underline radio buttons
 */
void ctl_normal.lbutton_up()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;

   rb := getSymbolColorRuleBase();
   rule := getSymbolColorRule();
   if (rule == null) return;

   font_flag := 0;
   switch (p_name) {
   case "ctl_normal":       font_flag = 0x0; break;
   case "ctl_bold":         font_flag = F_BOLD; break;
   case "ctl_italic":       font_flag = F_ITALIC; break; 
   case "ctl_underline":    font_flag = F_UNDERLINE; break;
   case "ctl_font_inherit": font_flag = F_INHERIT_STYLE; break;
   }

   inheritColorFlags := (ctl_background_inherit.p_value? F_INHERIT_BG_COLOR:0) |
                        (ctl_foreground_inherit.p_value? F_INHERIT_FG_COLOR:0);
   if (p_value) {
      rule->m_colorInfo.m_fontFlags = font_flag|inheritColorFlags;
   } else {
      rule->m_colorInfo.m_fontFlags &= ~font_flag;
   }

   if (font_flag == 0 && p_value) {
      rule->m_colorInfo.m_fontFlags &= ~(F_BOLD|F_ITALIC|F_UNDERLINE);
   } else if (font_flag == F_INHERIT_STYLE) {
      rule->m_colorInfo.m_fontFlags &= ~(F_BOLD|F_ITALIC|F_UNDERLINE);
      ctl_bold.p_enabled = (p_value == 0);
      ctl_italic.p_enabled = (p_value == 0);
      ctl_underline.p_enabled = (p_value == 0);
      ctl_normal.p_enabled = (p_value == 0);

      ctl_bold.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_BOLD)? 1:0;
      ctl_italic.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_ITALIC)? 1:0;
      ctl_underline.p_value = (rule->m_colorInfo.getFontFlags(rb) & F_UNDERLINE)? 1:0;
      ctl_normal.p_value = (ctl_bold.p_value==0 && ctl_italic.p_value==0 && ctl_underline.p_value==0)? 1:0;
   }

   ctl_sample.p_font_underline = (ctl_underline.p_value != 0);
   ctl_sample.p_font_italic = (ctl_italic.p_value != 0);
   ctl_sample.p_font_bold = (ctl_bold.p_value != 0);
   updateCurrentRuleInTree();
   updateAllRulesInTree();
}

/**
 * Handle changes in foreground or background color inheritance.
 */
void ctl_foreground_inherit.lbutton_up()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;

   p_next.enableColorControl();

   rb := getSymbolColorRuleBase();
   rule := getSymbolColorRule();
   if (rule == null) return;

   if (p_name == "ctl_background_inherit") {
      orig_bg := rule->m_colorInfo.getBackgroundColor(rb);
      if (p_value) {
         rule->m_colorInfo.m_fontFlags |= F_INHERIT_BG_COLOR;
      } else {
         rule->m_colorInfo.m_background = orig_bg;
         rule->m_colorInfo.m_fontFlags &= ~F_INHERIT_BG_COLOR;
      }
   } else {
      orig_fg := rule->m_colorInfo.getForegroundColor(rb);
      if (p_value) {
         rule->m_colorInfo.m_fontFlags |= F_INHERIT_FG_COLOR;
      } else {
         rule->m_colorInfo.m_foreground = orig_fg;
         rule->m_colorInfo.m_fontFlags &= ~F_INHERIT_FG_COLOR;
      }
   }

   ctl_foreground_color.p_backcolor = rule->m_colorInfo.getForegroundColor(rb);
   ctl_background_color.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
   ctl_sample.p_forecolor = rule->m_colorInfo.getForegroundColor(rb);
   ctl_sample.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
   updateCurrentRuleInTree();
   updateAllRulesInTree();
}

/**
 * Handle changes in the foreground or background color setting. 
 */
void ctl_foreground_color.lbutton_up()
{
   scc := getSymbolColorConfig();
   if (scc == null) return;
   if (scc->isIgnoringChanges()) return;

   if (p_prev.p_value) {
      return;
   }
   color := p_backcolor;
   if ((int)color < 0 || (color & 0x80000000) ||
       (int)color == VSDEFAULT_FOREGROUND_COLOR || 
       (int)color == VSDEFAULT_BACKGROUND_COLOR) {
      color = 0x0;
   }
   color = show_color_picker(color);
   if (color == COMMAND_CANCELLED_RC) return;

   p_backcolor = color;

   rule := getSymbolColorRule();
   if (rule == null) return;

   rb := getSymbolColorRuleBase();
   if (p_name == "ctl_foreground_color") {
      rule->m_colorInfo.m_foreground = color;
   } else {
      rule->m_colorInfo.m_background = color;
   }
   ctl_sample.p_backcolor = rule->m_colorInfo.getBackgroundColor(rb);
   ctl_sample.p_forecolor = rule->m_colorInfo.getForegroundColor(rb);
   updateCurrentRuleInTree();
   updateAllRulesInTree();
}

/**
 * If they added a tag file, we should recalculate symbol colors.
 */
void _TagFileAddRemove_symbol_color(_str file_name, _str options)
{
   SymbolColorAnalyzer.resetAllSymbolAnalyzers();
}

void _TagFileRefresh_symbol_color()
{
   SymbolColorAnalyzer.resetAllSymbolAnalyzers();
}
