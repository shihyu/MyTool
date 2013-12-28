////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47890 $
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
#import "main.e"
#import "math.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbcmds.e"
#import "treeview.e"
#import "OptionsCheckBoxTree.e"
#require "ExportImportGroupManager.e"
#require "OptionsTree.e"
#require "se/messages/Message.e"
#require "se/messages/MessageCollection.e"
#endregion Imports

using se.messages.Message;
using se.messages.MessageCollection;

namespace se.options;

// we use these to report any errors that happen when we try and export
#define OPTIONS_EXPORT_ERROR_MESSAGE_SOURCE      'Export Options'
#define OPTIONS_EXPORT_ERROR_MESSAGE_TYPE        'Export Options Error Message';

class OptionsExportTree : OptionsTree {

   // keeps track of what is in each export group
   private ExportImportGroupManager m_exportGroups;
   // handles the GUI part of export status
   private se.options.OptionsCheckboxTree * m_checkBoxTree;

   /** 
    * Initializes the options tree.
    * 
    * @param treeID        window ID of main tree
    * @param frameID       window ID of right frame on form 
    * @param helpID        window ID of lower help panel on form 
    * @param file          where the options xml info should come from 
    */
   public boolean init(int treeID = 0, int frameID = 0, int helpID = 0, _str file = '')
   {
      m_optionsTreePurpose = OP_EXPORT;

      if (OptionsTree.init(treeID, frameID, helpID, file)) {
   
         se.options.ExportImportGroupManager temp(EIIS_FALSE, &m_parser);
         m_exportGroups = temp;

         // set up our checkbox tree - it does a lot of our work for us
         OptionsCheckboxTree ocbt(treeID);
         m_checkBoxTree = _GetDialogInfoHtPtr(CHECKBOXTREE, m_treeHandle, true);
         m_checkBoxTree -> init(&m_relations, &m_exportGroups);
   
         // we don't want to see actual dialogs, only summaries
         m_dialogsAsSummaries = true;

         return true;
      }

      _message_box("There is a problem with the Options XML file.  Please contact Product Support.");

      return false;
   }

   /**
    * Retrieves all the names of the different export groups.
    * 
    * @param names         list of names to be populated
    */
   public void getExportGroupNames(_str (&names)[])
   {
      m_exportGroups.getAllGroupNames(names);
   }
   
   /**
    * Retrieves the list of export group names and whether they have any 
    * protected items within. 
    * 
    * @param groups        list of group names, associated with true/false value 
    *                      that indicates whether each group has any protected
    *                      items
    */
   public void getExportGroupNamesAndProtections(_str (&groups):[])
   {
      m_exportGroups.getAllGroupNamesWithProtections(groups);
   }

   /**
    * Shows the selected export group.  Clears the tree and re-adds it.
    * 
    * @param name          name of export group to show
    */
   public void showExportGroup(_str name)
   {
      // first we save the old export group that we were looking at
      m_exportGroups.saveGroups(false);

      if (m_exportGroups.setCurrentGroup(name)) {
         currentIndex := getCurrentXMLIndex();
         clearTree();
         buildNextLayer(TREE_ROOT_INDEX, false, currentIndex);
         selectXMLIndexInTree(currentIndex);
      }
   }

   /**
    * Determines if the current export group has any protections associated with 
    * it. 
    * 
    * @return              true if the export group has protections, false 
    *                      otherwise
    */
   public boolean doesGroupHaveProtections()
   {
      return m_exportGroups.doesCurrentGroupHaveProtections(true);
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
   private boolean getNodeInfo(int xmlIndex, _str &caption, int &picIndex, int &children, 
                               int &flags, int startNode, boolean &recurseThis)
   {
      // whether to insert this node as a parent or a leaf - this value will
      // be used as an argument when we insert into tree
      children = m_parser.getFirstChild(xmlIndex);

      // if it has no children or is a property sheet, then it's a leaf
      if (children < 0 || m_parser.isAPropertySheet(xmlIndex) || m_parser.isADialog(xmlIndex)) {
         children = TREE_NODE_LEAF;                   // leaf value
         recurseThis = false;
      } else {
         // and we expand the entire path to the starting node
         if (startNode > 0 && recurseThis) {
            children = TREE_NODE_EXPANDED;                 // expanded parent
         } else {
            children = TREE_NODE_COLLAPSED;                 // non-expanded parent
         }
      }

      // get the caption, nothing special here
      caption = m_parser.getCaption(xmlIndex);

      // we don't use any flags for exporting
      flags = 0;
      picIndex = -1;

      return true;
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
      m_checkBoxTree -> setNodeInitialStatus(treeIndex, m_exportGroups.getItemStatus(xmlIndex));
   }

   /**
    * Creates a brand spanking new export group.  Can optionally copy the 
    * settings from another group in the creation of the new one. 
    * 
    * @param newGroup               name of new export group
    * @param copyFromGroup          group to copy settings from
    */
   public void createNewExportGroup(_str newGroup, _str copyFromGroup)
   {
      m_exportGroups.createNewGroup(newGroup, copyFromGroup);
   }

   /** 
    * Closes the options tree by saving and closing the XML DOM and
    * deleting all the created child windows.
    * 
    */
   public void close()
   {
      m_exportGroups.close();
      OptionsTree.close();
   }

   /**
    * Apply all the changes that have been made to export groups 
    * since the form was opened or last saved. 
    *
    */
   public boolean apply(boolean restoreCurrent = true, boolean applyCurrent = true)
   {
      m_exportGroups.saveGroups(true);

      return true;
   }

   /**
    * Removes any and all disabled properties (and resulting empty property 
    * groups) from a PropertySheet before it is displayed. 
    * 
    * @param ps            pointer to PropertySheet to be processed
    */
   private void processPropertySheet(PropertySheet * ps)
   {
      // go through and get all the values
      for (i := 0; i < ps -> getNumItems(); i++) {
         if (ps -> getTypeAtIndex(i) == TMT_PROPERTY) {
            Property * p = ps -> getPropertyByIndex(i);

            SettingInfo info = p -> getSettingInfo();
            p -> setValue(PropertyGetterSetter.getSetting(info));
         }
      }

      int removedXMLIndices[];
      ps -> removeDisabledProperties(removedXMLIndices);

      foreach (auto index in removedXMLIndices) {
         m_parser.removePropertySheetItem(index);
         m_exportGroups.setItemStatus(index, EIIS_FALSE);
      }
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

   /**
    * Refreshes the view of a property sheet.  
    * 
    * @param index   index of property sheet to refresh
    */
   private void refreshPropertySheet(int index)
   {
      // we need to register this property sheet with the checkbox tree
      m_checkBoxTree -> refreshPropertySheet(index, true);
   }

   /**
    * Exports an export group, either the current one or one specified by 
    * parameters. 
    * 
    * @param package                name of package (zip file where exported 
    *                               items will go)
    * @param protectionCode         protection code to protect any items within
    * @param groupName              name of group to export (if blank, currently 
    *                               selected group will be used)
    */
   public void export(_str package, _str protectionCode = '', _str groupName = '')
   {
      // make sure we're using the current group
      if (groupName != '') m_exportGroups.setCurrentGroup(groupName);
      
      int nodes[];
      if (groupName == '') {
         // this means we want ALL of the nodes
         m_parser.getAllExportableNodes(nodes);
      } else {
         // get all our indices for this group
         m_exportGroups.getAllDialogsAndPropertySheets(nodes);
      }
      nodes._sort();

      // get where the user wants to save this mess
      path := _strip_filename(package, 'N');
    
      // set up the error log
      se.messages.MessageCollection* mCollection = setupErrorLog();
      
      // prepare the status dialog...
      progressWid := show_cancel_form("Export settings", null, true, true);
      progressWid.refresh();
      len := nodes._length();

      // now go through all the stuff and build info if we don't have it
      error := false;
      typeless exportItems[];

      // a list of files that we are including in the export package
      _str exportFiles:[];

      caption := '';
      itemIndex := 0;
      for (i := 0; i < len; i++) {

         itemIndex = nodes[i];

         // we might have removed this node...
         if (!m_parser.isNodeValid(itemIndex)) continue;

         if (m_parser.isAPropertySheet(itemIndex) || m_parser.isADialogWithProperties(itemIndex)) {
            
            // see if this has already been built
            PropertySheet ps;
            if (!m_data.hasBeenLoaded(itemIndex)) {
               m_parser.buildRightPanelData(itemIndex, ps, m_dialogsAsSummaries);

               processPropertySheet(&ps);
            } else {
               PropertySheetEmbedder * pse = m_data.getPropertySheet(itemIndex);
               ps = *(pse -> getPropertySheetData());
            }

            // determine which properties need to be exported
            int properties:[];
            if (groupName != '') m_exportGroups.getStatusesForProperties(itemIndex, properties);

            // now go through each property in the sheet and gather it
            for (j := 0; j < ps.getNumItems(); j++) {
               type := ps.getTypeAtIndex(j);
               if (type == TMT_PROPERTY) {

                  Property * p = ps.getPropertyByIndex(j);
                  pIndex := p -> getIndex();
                  if (groupName == '' || properties:[pIndex] == EIIS_TRUE) {
                     if (p -> getDisplayValue() == RETRIEVE_ERROR) {
                        // log this as an error
                        errorCaption := m_parser.getFrameCaption(itemIndex) ' > 'p -> getCaption();
                        logErrors(mCollection, errorCaption, RETRIEVE_ERROR);
                     } else {
                        // now save it!
                        exportItems[exportItems._length()] = *p;
                     }
                  }
               }
            }
         } else if (m_parser.isADialog(itemIndex)) {
            caption = m_parser.getFrameCaption(itemIndex);

            // see if this has already been built
            if (!m_data.hasBeenLoaded(itemIndex)) {
               OptionsPanelInfo opi;
               m_parser.buildRightPanelData(itemIndex, opi, m_dialogsAsSummaries);
               m_data.setPanelInfo(itemIndex, opi);
            }
            
            DialogExporter * de = m_data.getDialogExporter(itemIndex);
            log := de -> export(path);

            // check for errors
            if (log != '') {
               logErrors(mCollection, caption, log);
               error = true;
            } else {
               // now save it!
               exportItems[exportItems._length()] = *de;

               // grab the file that was created
               if (de -> getPanelType() == OPT_DIALOG_FORM_EXPORTER) {
                  dialogFiles := de -> getImportFilenamesAsString();
                  if (dialogFiles != '') {
                     _str dialogFilesArray[];
                     split(dialogFiles, ',', dialogFilesArray);
   
                     foreach (auto filename in dialogFilesArray) {
                        thisPath := path :+ filename;
                        if (!exportFiles._indexin(thisPath)) {
                           exportFiles:[thisPath] = thisPath;
                        } 
                     }
                  }
               }
            }
         }

         if (cancel_form_cancelled()) {
            // uh-oh, the user cancelled it!
            // delete any files we created
            foreach (auto filename in exportFiles) {
               delete_file(filename);
            }

            return;
         } else {
            // continuing along
            if (cancel_form_progress(progressWid, i, len)) {
               cancel_form_set_labels(progressWid, 'Exporting 'caption'...');
            }
         }

      }
      
      if (!exportItems._length()) {
          if (progressWid) cancel_form_progress(progressWid, 1, 1);
          if (progressWid) close_cancel_form(progressWid);

          _message_box('No options could be exported.', 'Options Export', MB_OK | MB_ICONEXCLAMATION);
      } else {
    
          if (progressWid) {
             cancel_form_set_labels(progressWid, "Writing export package...");
             progressWid.refresh('w');
          }
    
          // okay we've saved all the properties - now we need to write their data to the xml file
          ExportImportGroup eig = m_exportGroups.getCurrentGroup();
          status := m_parser.writeExportXML(exportItems, path, eig, protectionCode);
          if (status < 0) {
             // sometimes the dialogs and whatnot don't actually return anything, so we end up writing an empty file
             _message_box('No options could be exported.', 'Options Export', MB_OK | MB_ICONEXCLAMATION);
             return;
          }
    
          _str filesArray[];
          filesArray[0] = path;
          foreach (auto filename in exportFiles) {
             filesArray[filesArray._length()] = filename;
          }

          status = buildExportPackage(package, filesArray);
          if (status) {
             logErrors(mCollection, 'Options Export', 'Error creating export package.  Error code 'status);
             error =  true;
          }
    
          if (progressWid) cancel_form_progress(progressWid, 1, 1);
          if (progressWid) close_cancel_form(progressWid);
      }

      // if there was a problem, activate the message list so they see it
      if (error) {
         _message_box(nls("There were errors exporting your options.  Please see the Message List for detailed information."));
         activate_messages();
      }
   }

   /**
    * Sets up an error log to log any errors found while exporting.
    */
   private se.messages.MessageCollection * setupErrorLog()
   {
      se.messages.MessageCollection* mCollection = get_messageCollection();
      mCollection -> removeMessages(OPTIONS_EXPORT_ERROR_MESSAGE_SOURCE);

      // create a message type
      Message newMsgType;
      newMsgType.m_creator = OPTIONS_EXPORT_ERROR_MESSAGE_SOURCE;
      newMsgType.m_type = OPTIONS_EXPORT_ERROR_MESSAGE_TYPE;
      newMsgType.m_sourceFile = '';
      newMsgType.m_date = '';
      newMsgType.m_autoClear = MSGCLEAR_EDITOR;
      mCollection -> newMessageType(newMsgType);

      return mCollection;
   }

   /**
    * Logs errors found while exporting options.
    * 
    * @param mCollection            pointer to the message collection which 
    *                               collects the error messages
    * @param caption                caption of new error messages
    * @param log                    list of errors
    */
   private void logErrors(se.messages.MessageCollection * mCollection, _str caption, _str log)
   {
      // each error is one sentence long
      _str errors[];
      split(log, OPTIONS_ERROR_DELIMITER, errors);

      foreach (auto errorMsg in errors) {

         if (strip(errorMsg)) {
            // send this stuff to the logger
            Message newMsg;
            newMsg.m_creator = OPTIONS_EXPORT_ERROR_MESSAGE_SOURCE;
            newMsg.m_type = OPTIONS_EXPORT_ERROR_MESSAGE_TYPE;
            newMsg.m_description = 'Error exporting 'caption':  'errorMsg;

            mCollection -> newMessage(newMsg);

				// add this to vs.log
				dsay(newMsg.m_description);
         }
      }
   }

   /**
    * Builds an export package by combining all the files needed in the export 
    * into a zip file. 
    * 
    * @param zipFile                name of export package (zip file)
    * @param files                  array of files to be packaged
    * 
    * @return                       0 for success, error code otherwise (from 
    *                               _CreateZipFile)
    */
   private int buildExportPackage(_str zipFile, _str (&files)[])
   {
      // create the zip file
      int zipStatus[];
      status := _CreateZipFile(zipFile, files, zipStatus);

      // delete the extra files, we are done with them...
      foreach (auto file in files) {
         ret := delete_file(file);
      }

      return status;
   }

}
