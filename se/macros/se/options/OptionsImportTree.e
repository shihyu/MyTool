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
#require "ExportImportGroupManager.e"
#require "OptionsTree.e"
#require "se/messages/Message.e"
#require "se/messages/MessageCollection.e"
#import "box.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "OptionsCheckBoxTree.e"
#import "optionsxml.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "taggui.e"
#import "treeview.e"
#endregion Imports

using namespace se.messages;

namespace se.options;

static const OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE=        "Import Options";
static const OPTIONS_IMPORT_ERROR_MESSAGE_TYPE=          "Import Options Error Message";

class OptionsImportTree : OptionsTree {

   // we gots to keep track of what we're importing
   private se.options.ExportImportGroupManager m_imports;
   // keep track of the location of the import package path
   private _str m_importPath = "";
   // handles the GUI part of export status
   private se.options.OptionsCheckboxTree * m_checkBoxTree;

   OptionsImportTree()
   { }

   /**
    * Initializes the options tree.
    *
    * @param treeID        window ID of main tree
    * @param frameID       window ID of right frame on form
    * @param helpID        window ID of lower help panel on form
    * @param file          where the options xml info should come from
    */
   public bool init(int treeID = 0, int frameID = 0, int helpID = 0, _str file = "")
   {
      m_optionsTreePurpose = OP_IMPORT;
      m_importPath = file;
      export_file := file :+ FILESEP :+ "export.xml";

      if (OptionsTree.init(treeID, frameID, helpID, export_file)) {
   
         // we don't want to see actual dialogs, only summaries
         m_dialogsAsSummaries = true;
   
         // see if the version of the options matches this version...there could be trouble
         if (!checkExportFileVersion()) {
            close();
            return false;
         }
#if 0
         // see if the import file originated on the same platform - the user should be warned 
         // before continuing if not
         if (m_parser.checkCrossPlatformImport(auto curPlat, auto importPlat)) {
            // through up a message box to make sure they want to continue...
            result := _message_box('The options you have selected to import were exported from '_cap_word(importPlat)'. ':+
                                   'You are currently using '_cap_word(curPlat)'. You may end up with paths, filenames, and fonts ':+
                                   'that won''t work for this platform. Continue with import anyway?',
                                   'Import Options', MB_YESNO | MB_ICONQUESTION);
            if (result != IDYES) {
               close();
               return false;
            }
         }
#endif
         defaultStatus := _file_eq(file, _get_default_options_package_path())? EIIS_FALSE:EIIS_TRUE;
         se.options.ExportImportGroupManager temp(defaultStatus, &m_parser);
         m_imports = temp;
         m_imports.initImports();
   
         if (treeID) {
            // set up our checkbox tree - it does a lot of our work for us
            OptionsCheckboxTree ocbt(treeID);
            m_checkBoxTree = _GetDialogInfoHtPtr(sc.controls.CheckboxTree.CHECKBOXTREE, m_treeHandle, true);
            m_checkBoxTree -> init(&m_relations, &m_imports);

            // rebuild the tree to account for brand new import information
            clearTree();
            buildNextLayer();
         }

         // hey, we made it
         return true;
      }

      // uh-oh
      _message_box("There was an error importing your options.  The export package is corrupted or incorrect.");

      return false;
   }

   /**
    * Check the version listed in the options.xml file to make sure it is the
    * same as the current version.
    *
    * @return              true if options version is same as SlickEdit version
    */
   private bool checkExportFileVersion()
   {
      // grab the SlickEdit version
      version := m_parser.getOptionsXMLVersion();

      curVersion := _version();

      // trim down the version to the major version only...
      typeless majVer, majCur;
      parse version with majVer"." .;
      parse curVersion with majCur"." .;

      diff := abs(majVer - majCur);

      goAhead := false;
      if (diff == 0 || (majVer>=17 && majVer<=majCur)) {
         goAhead = true;
      } else if (majVer>=15 && majVer<=majCur) {
         // throw up a message box to make sure they want to continue...
         result := _message_box("The options you have selected to import were exported from a different version of ":+
                      "SlickEdit ("version"). Because of the changes between versions, some settings may not import. ":+
                      "Continue with import anyway?",
                      "Import Options", MB_YESNO | MB_ICONQUESTION);
         goAhead = (result == IDYES);
      } else if (majVer>majCur) {
         // nope, not gonna do it.  wouldn't be prudent.
         result := _message_box("The options you have selected to import were exported from a newer version of ":+
                      "SlickEdit ("version"). Importing from this version is not supported.",
                      "Import Options", MB_OK | MB_ICONEXCLAMATION);
         goAhead = false;
      } else {
         // nope, not gonna do it.  wouldn't be prudent.
         result := _message_box("The options you have selected to import were exported from a very old version of ":+
                      "SlickEdit ("version"). Importing from this version is not supported.",
                      "Import Options", MB_OK | MB_ICONEXCLAMATION);
         goAhead = false;
      }

      return goAhead;
   }

   /**
    * Does some voodoo to a new tree node.  Meant to be overwritten by child 
    * classes. 
    * 
    * @param treeIndex           the newly added node to the options tree
    */
   protected void handleNewNode(int treeIndex)
   {
      // we need to make sure we have a status for this node
      xmlIndex := m_relations.getXMLIndex(treeIndex);
      m_checkBoxTree -> setNodeInitialStatus(treeIndex, m_imports.getItemStatus(xmlIndex));
   }

   /**
    * Initializes a PropertySheet panel when it is first displayed.
    * 
    * @param index         xml index of property sheet
    */
   private void initializePropertySheet(int index)
   {
      // get the wid of this panel
      panelWid := m_data.getWID(index);
      panelType := m_data.getPanelType(index);

      // we need to register this property sheet with the checkbox tree
      m_checkBoxTree -> registerPropertySheet(index, panelWid.p_child, panelType == OPT_PROPERTY_SHEET);
   }

   #region Modify/Apply Functions

   /**
    * Apply all the changes that have been made in the tree since
    * it was opened or last applied.
    *
    */
   public bool apply(bool restoreCurrent = true, bool applyCurrent = true)
   {
      typeless before_table:[]:[];
      
      _update_buffers_from_table('',null,true,true,before_table);

      Property pList[];

      changeEvents := 0;
      _str commentLangs:[];
      _str langUpdateKeys:[][];
      applySuccess := true;

      // see if the user really wants to import the protections...
      if (!warnAboutProtections()) return true;

      protectionCode := m_parser.getImportProtectionCode();

      // set up the error log
      se.messages.MessageCollection* mCollection = setupErrorLog(OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE, OPTIONS_IMPORT_ERROR_MESSAGE_TYPE);

      _str failedBecauseProtections[];

      // back up the good stuff
      progressWid := show_cancel_form("Importing options...", null, false, true);
      progressWid.refresh();
      backupConfig();

      // prepare the status dialog...
      cancel_form_set_labels(progressWid, "Reading import package...");
      progressWid.refresh();

      // we need a list of all the indices containing imported info
      int imports[];

      // MUST DO EMULATION FIRST!
      emulationIndex := m_parser.findDialogNode("_emulation_form");
      if (emulationIndex > 0) {
         if (m_imports.getItemStatus(emulationIndex) == EIIS_TRUE) {
            imports[0] = emulationIndex;
         }
      } 

      m_imports.getAllDialogsAndPropertySheets(imports);

      // calculate these to know how often to update the progress dialog
      len := imports._length();

      caption := "";
      for (i := 0; i < len; i++) {
         itemIndex := imports[i];

         // skip this, we already did it
         if (i != 0 && itemIndex == emulationIndex) continue;

         if (m_parser.isAPropertySheet(itemIndex) || m_parser.isADialogWithProperties(itemIndex)) {
            
            // update progress form
            caption = m_parser.getFrameCaption(itemIndex);
            if (!cancel_form_cancelled()) {
               if (cancel_form_progress(progressWid, i, len)) {
                  cancel_form_set_labels(progressWid, "Importing "caption"...");
               }
            }
                        
            // see if this has already been built
            PropertySheet * ps;
            PropertySheet ps2;
            if (!m_data.hasBeenLoaded(itemIndex)) {
               m_parser.buildRightPanelData(itemIndex, ps2, m_dialogsAsSummaries);
               ps = &ps2;
            } else {
               PropertySheetEmbedder * pse = m_data.getPropertySheet(itemIndex);
               ps = pse -> getPropertySheetData();
            }

            // determine which properties need to be exported
            int properties:[];
            m_imports.getStatusesForProperties(itemIndex, properties);

            // now go through each property in the sheet and gather it
            for (j := 0; j < ps -> getNumItems(); j++) {
               type := ps -> getTypeAtIndex(j);
               if (type == TMT_PROPERTY) {
                  Property * p = ps -> getPropertyByIndex(j);
                  pIndex := p -> getIndex();
                  if (properties:[pIndex] == EIIS_TRUE) {

                     // first we must determine if we're allowed to do anything at all to this node
                     if (m_parser.isItemProtected(pIndex)) {
                        // check and see if protection codes match
                        itemProtectionCode := m_parser.getItemProtectionCode(pIndex);
                        if (itemProtectionCode != "" && itemProtectionCode != protectionCode) {
                           // otherwise add it to a list to show them later
                           failedBecauseProtections[failedBecauseProtections._length()] = m_parser.getXMLNodeCaptionPath(pIndex, true);
                           continue;
                        }
                     }

                     // let's see if we want to protect this item from now on
                     protectionStatus := m_imports.getItemProtectionStatus(pIndex);
                     if (protectionStatus == EIPS_TRUE) {
                        m_parser.addProtection(pIndex, protectionCode);
                     } else if (protectionStatus == EIPS_UNPROTECT) {
                        m_parser.removeProtection(pIndex);
                     }

                     // otherwise, we can just import it
                     importValue := p -> getActualValue();
                     if (importValue != null) {
                        
                        // do a little checking here - if this is a path, we want to make sure it exists first (or is blank)
                        if ((p -> getPropertyType() == FILE_PATH_PROPERTY || 
                            p -> getPropertyType() == DIRECTORY_PATH_PROPERTY) && 
                            importValue != "") {
                           isFilePathProperty := p -> getPropertyType() == FILE_PATH_PROPERTY;

                           // do we have multiple paths?
                           Path pathP = (Path)*p;
                           _str paths[];
                           if (pathP.allowMultiplePaths()) {
                              split(importValue, pathP.getDelimiter(), paths);
                           } else {
                              paths[0] = importValue;
                           }

                           // go through each one and see if it exists
                           importValue = "";
                           error := "";
                           for (k := 0; k < paths._length(); k++) {
                              // see if this exists?
                              if (isFilePathProperty) {
                                 path:=_strip_filename(paths[k],'N');
                                 if (path=="") {
                                    // User never configured this.
                                    // Default VCS executables do path search (i.e cvs.exe git.exe etc.)
                                    // They have no path when they haven't been configured.
                                    continue;
                                 }
                              }
                              if (file_exists(paths[k])) {
                                 if (importValue != "") {
                                    importValue :+= pathP.getDelimiter();
                                 }
                                 importValue :+= paths[k];
                              } else {
                                 error :+= paths[k]" does not exist." :+ OPTIONS_ERROR_DELIMITER;
                              }
                           }

                           if (error != "") {
                              logErrors(mCollection, 
                                        caption" > "p->getCaption(), 
                                        error,
                                        OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE, 
                                        OPTIONS_IMPORT_ERROR_MESSAGE_TYPE);
                              applySuccess = false;
                           }

                           if (importValue == "") continue;
                        }

                        SettingInfo info = p -> getSettingInfo();

                        // see if the current value already equals what we are importing...
                        // we only check this for properties with events, otherwise the performance isn't worth it
                        doImportProperty := true;
                        propChangeEvents := p -> getChangeEventFlags();
                        if (propChangeEvents) {
                           p -> setValue(PropertyGetterSetter.getSetting(info));
                           doImportProperty = (p -> getActualValue() :!= importValue);
                        }

                        // check for errors
                        if (doImportProperty) {
                           if (PropertyGetterSetter.setSetting(info, importValue)) {
                              changeEvents |= propChangeEvents;
                              if (propChangeEvents & OCEF_WRITE_COMMENT_BLOCKS) commentLangs:[info.Language] = info.Language;

                              // if this is a language setting, it may have an update key,
                              // used to update any currently open buffers of that language
                              // with the new settings
                              if (info.SettingType == LANGUAGE_SETTING) {
                                 SetLanguageSettingInfo slsi = info.SettingTypeInfo;
                                 upKey := getLanguageSettingUpdateKey(slsi.Setting);
                                 if (upKey != "") {
                                    // just save the update key for now, we'll get the values at the end
                                    langUpdateKeys:[info.Language][langUpdateKeys:[info.Language]._length()] = upKey;
                                 }
                              }
                           } else {
                              logErrors(mCollection, 
                                        caption" > "p->getCaption(), 
                                        "Error applying property.",
                                        OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE, 
                                        OPTIONS_IMPORT_ERROR_MESSAGE_TYPE);
                              applySuccess = false;
                           }
                        }
                     }
                  }
               }
            }
         } else {
            // update progress form
            caption = m_parser.getFrameCaption(itemIndex);
            if (!cancel_form_cancelled()) {
               if (cancel_form_progress(progressWid, i, len)) {
                  cancel_form_set_labels(progressWid, "Importing "caption"...");
               }
            }

            // this may not have been built already
            DialogExporter * de = m_data.getDialogExporter(itemIndex);
            if (de == null) {
               OptionsPanelInfo opi;
               m_parser.buildRightPanelData(itemIndex, opi, m_dialogsAsSummaries);
               m_data.setPanelInfo(itemIndex, opi);
               de = m_data.getDialogExporter(itemIndex);
            }

            log := de -> import();

            // check for errors
            if (log != "") {
               logErrors(mCollection, 
                         caption, 
                         log,
                         OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE, 
                         OPTIONS_IMPORT_ERROR_MESSAGE_TYPE);
               applySuccess = false;
            } else {
               changeEvents |= de->getChangeEventFlags();
            }
         }
      }

      // mark this in our history
      m_parser.setImportDate();

      // note that we need to write the config file
      _config_modify_flags(CFGMODIFY_DEFVAR);

      // update open buffers with new options
      if (langUpdateKeys._length()) {
         if (!cancel_form_cancelled()) {
            if (cancel_form_progress(progressWid, i, len)) {
               cancel_form_set_labels(progressWid, "Updating open buffers with new settings...");
            }
         }

         handleLanguageUpdateSettings(langUpdateKeys);
      }

      handleChangeEvents(changeEvents, commentLangs);

      // close out our log, letting them know of errors if there are any
      endErrorLog(!applySuccess, OPTIONS_IMPORT_ERROR_MESSAGE_SOURCE);

      if (failedBecauseProtections._length()) {
         show("-modal _list_box_form", failedBecauseProtections, "The following items could not be imported because they ":+
              "are currently protected from a previous import.", "Protected items");
      }

      if (progressWid) {
         cancel_form_set_labels(progressWid, "Closing import package...");
         progressWid.refresh('w');
      }

      if (progressWid) cancel_form_progress(progressWid, 1, 1);
      if (progressWid) close_cancel_form(progressWid);

      typeless after_table:[]:[];
      
      _update_buffers_from_table('',null,true,true,after_table);

      _str lang;
      typeless table:[];
      foreach (lang => table in before_table) {
         if (table!=after_table:[lang]) {
            // Some settings changed for this language
            // Now check which settings changed.
            typeless updateTable:[];
            _str setting;
            typeless value;
            foreach (setting => value in table) {
               if (value!=after_table:[lang]:[setting]) {
                  updateTable:[setting]=value;
               }
            }
            _update_buffers_from_table(lang,updateTable,true);
         }
      }
      

      return applySuccess;
   }

   /**
    * Given a language setting, determine the update key used to
    * update open buffers of that language.
    *
    * @param setting
    *
    * @return _str
    */
   private _str getLanguageSettingUpdateKey(_str setting)
   {
      // turn from camel case into underscores
      key := "";

      ss := "[A-Z]";
      nextCap := pos(ss, setting, 2, 'R');
      while (nextCap > 1) {
         // get the stuff before
         key :+= substr(setting, 1, nextCap - 1);

         // add the underscore
         key :+= "_";

         // shorten the string
         setting = substr(setting, nextCap);

         // look for the next one
         nextCap = pos(ss, setting, 2, 'R');
      }

      // add what's left of the string
      key :+= setting;

      // add suffix
      key :+= "_UPDATE_KEY";

      // upcase the whole thing
      key = upcase(key);

      // now see if this maps to anything useful
      key = _const_value(key, auto status);

      if (!status) {
         return key;
      } else return "";
   }

   /**
    * Updates open buffers with new language settings.
    *
    * @param langUpdateKeys
    */
   private void handleLanguageUpdateSettings(_str (&langUpdateKeys):[][])
   {
      // go through each language
      _str lang;
      foreach (lang => . in langUpdateKeys) {
         // get the values that goes with each of our keys

         // first, get the table of values found in the language definition
         typeless defTable:[];
         _get_update_table_for_language_from_settings(lang, defTable);

         // now make a table of keys and values for this language
         typeless updateTable:[];
         for (i := 0; i < langUpdateKeys:[lang]._length(); i++) {
            key := langUpdateKeys:[lang][i];
            if (defTable._indexin(key)) {
               updateTable:[key] = defTable:[key];
            }
         }

         // update open buffers of this language
         _update_buffers_from_table(lang, updateTable);
      }
   }

   /**
    * Warns the user about any protections associated with the selected set of 
    * options to import.  If any options are protected, asks the user to 
    * continue. 
    * 
    * @return              true if we should continue with the import, false 
    *                      otherwise.
    */
   private bool warnAboutProtections()
   {
      if (m_imports.doesCurrentGroupHaveProtections()) {
         answer := _message_box("Some of the options you have chosen to import have protections associated ":+
                                "with them.  If you import them, you will be unable to change these options ":+
                                "from their imported values.  Do you wish to continue?", "Protected Options", 
                                MB_YESNO | MB_ICONEXCLAMATION);
         return (answer == IDYES);
      }

      return true;
   }

   #region Modify/Apply Functions

   /**
    * Backs up some configuration files before performing an
    * options import.
    */
   private void backupConfig()
   {
      // get the config dir
      configDir := _ConfigPath();

      // copy the user defs file
      file := configDir :+ USERDEFS_FILE :+ ".e";
      copy_file(file, file :+ ".bak");

      // copy the user data file
      file = configDir :+ USERDATA_FILE :+ ".e";
      copy_file(file, file :+ ".bak");

#if 0
      // copy the user defs file
      file = configDir :+ USERKEYS_FILE :+ '.e';
      copy_file(file, file :+ '.bak');
#endif

      // now the user objects
      file = configDir :+ USEROBJS_FILE :+ ".e";
      copy_file(file, file :+ ".bak");

      // finally, the state file
      file = configDir :+ STATE_FILENAME;
      copy_file(file, file :+ ".bak");
   }

   /**
    * Determines if any of the items being imported in this group have
    * protection status changes (if protect = true or if they are unprotecting
    * something).
    *
    * @return           true if anything is protected, false otherwise
    */
   public bool areAnyImportedItemsProtected()
   {
      return m_parser.areAnyItemsProtected();
   }


   /** 
    * This method determines if a node should be displayed and how it should be 
    * displayed in the options tree.  Any modifications to captions and icons 
    * should be done in this function. 
    *  
    * This method is meant to be overwritten by child classes in case display of 
    * nodes changes in those classes. 
    * 
    * 
    * @param xmlIndex                  xml index of node that we are considering
    * @param caption                   caption to display for this node
    * @param picIndex                  index of icon to display for this node
    * @param children                  TREE_NODE_LEAF if node is a leaf, 
    *                                  TREE_NODE_COLLAPSED if the node is a
    *                                  non-expanded parent, TREE_NODE_EXPANDED
    *                                  if the node is an expanded parent
    * @param flags                     any flags to send to _TreeAddItem
    * @param startNode                 the index of the node we want to select in 
    *                                  the tree
    * @param recurseThis               whether to continue to recurse through this 
    *                                  node's children
    * 
    * @return                          true if this node should be added to the 
    *                                  tree, false if it should be skipped.
    */
   private bool getNodeInfo(int xmlIndex, _str &caption, int &picIndex, int &children,
                               int &flags, int startNode, bool &recurseThis)
   {
      // whether to insert this node as a parent or a leaf - this value will
      // be used as an argument when we insert into tree
      children = m_parser.getFirstChild(xmlIndex);

      // if it has no children or is a property sheet, then it's a leaf
      if (children < 0 || m_parser.isAPropertySheet(xmlIndex) || m_parser.isADialog(xmlIndex)) {
         children = TREE_NODE_LEAF;                   // leaf value
         recurseThis = false;
      } else {
         // we expand all nodes when searching
         // and we expand the entire path to the starting node
         if (startNode > 0 && recurseThis) {
            children = TREE_NODE_EXPANDED;                 // expanded parent
         } else {
            children = TREE_NODE_COLLAPSED;                 // non-expanded parent
         }
      }

      // get the caption, if this node has been modified, we add a ' *'
      caption = m_parser.getCaption(xmlIndex);

      // no flags
      flags = 0;

      return true;
   }
};
