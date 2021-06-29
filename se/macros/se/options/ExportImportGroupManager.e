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
#require "ExportImportGroup.e"
#require "OptionsData.e"
#require "OptionsXMLParser.e"
#require "RelationTable.e"
#endregion Imports

namespace se.options;

class ExportImportGroupManager {

   // our export and import groups - we will only ever have one import group
   private ExportImportGroup m_groups:[];
   // the current group that we are working with
   private _str m_currentGroup = '';
   // the default status of a node if it has not yet been added
   private ExportImportItemStatus m_defaultStatus;

   private se.options.OptionsXMLParser * m_parser;

   ExportImportGroupManager(ExportImportItemStatus defaultStatus = EIIS_TRUE, se.options.OptionsXMLParser * parser = null)
   {
      m_defaultStatus = defaultStatus;

      m_parser = parser;
   }
   
   /**
    * Sets up the import group.  There will only be one of these at a time. 
    * Once this is done, the tree can query for status information on specific 
    * nodes. 
    */
   public void initImports()
   {
      // create a default group
      groupName := 'Imports';
      ExportImportGroup eig(groupName);
      m_parser -> buildImportGroup(eig, m_defaultStatus);
      
      // set the group name
      addGroup(eig, groupName);
      setCurrentGroup(groupName);
   }
   
   /**
    * Closes this object and closes the parser's connection to the export group 
    * file. 
    * 
    * @param saveChanges         whether to save changes to the file
    */
   public void close()
   {
      if (m_parser != null) {
         m_parser -> closeExportDOM();
      }
   }

   /**
    * Determines whether the current export group has been modified.
    * 
    * @return                    true if the group has been modified, false 
    *                            otherwise
    */
   public bool isCurrentGroupModified()
   {
      return m_groups:[m_currentGroup].isGroupModified();
   }

   /**
    * Determines whether the current export group has any protected
    * items. 
    * 
    * @return                    true if the group has protected 
    *                            items, false otherwise
    */
   public bool doesCurrentGroupHaveProtections(bool includeUnprotects = false)
   {
      return m_groups:[m_currentGroup].areAnyItemsProtected(includeUnprotects);
   }

   /**
    * Adds an ExportImport group to this collection.
    * 
    * @param eig                 the group to add
    * @param groupName           name of the group
    */
   public void addGroup(ExportImportGroup eig, _str groupName)
   {
      m_groups:[groupName] = eig;
   }

   /**
    * Adds a property to the current group.  Looks up the protection status in 
    * the XML DOM. 
    * 
    * @param index 
    * @param isNew 
    * @return 
    */
   public void addPropertyToGroup(int index, bool isNew = true)
   {
      ExportImportItem eti;
      eti.Status = EIIS_TRUE;
      eti.ProtectStatus = m_parser->getProtectionStatus(index);
      
      m_groups:[m_currentGroup].addGroupItem(eti, index, isNew);
   }
   
   /**
    * Sets the current group in this collection.
    * 
    * @param groupName           the name of the current group
    * 
    * @return                    whether the current group was changed to the 
    *                            group specified
    */
   public bool setCurrentGroup(_str groupName)
   {
      if (!m_groups._indexin(groupName)) {
         ExportImportGroup eig(groupName);
         m_groups:[groupName] = eig;
         m_parser -> buildExportGroup(groupName, m_groups:[groupName]);
         m_currentGroup = groupName;
         markUncheckedItems();
      } 
        
      if (m_groups._indexin(groupName)) {
         m_currentGroup = groupName;
         return true;
      } else return false;
   }

   /**
    * Marks all the "other" nodes.  When we save an export group, we don't save 
    * every single thing that is checked, only ranges of items which are 
    * checked.  This method goes through checked nodes and ensures that their 
    * children are checked with the proper status.  Then it makes sure that 
    * parent nodes properly reflect status as well. 
    */
   private void markUncheckedItems()
   {
      // first we get all the nodes in this group which are checked
      int nodes[] = m_groups:[m_currentGroup].getAllIndices(false);

      // now we mark the children of these nodes to make sure that 
      // everything has an up to date status
      foreach (auto index in nodes) {
         if (!m_parser -> isAProperty(index)) {
            changeXMLNodeChildrenStatus(index, EIIS_TRUE);
         }
      }

      // finally we mark the parents, so they have up to date status
      //  as well
      foreach (index in nodes) {
         // see if the parent is in there
         parent := m_parser -> getParent(index);
         if (parent > 0) {
            if (m_groups:[m_currentGroup].getItemStatus(parent) == null) {
               // we have to mark it...first get all the chillens
               changeXMLNodeParentStatus(index, getItemStatus(index));
            }
         }
      }
   }

   /**
    * Returns the name of the current group.
    * 
    * @return                    name of the current group
    */
   public _str getCurrentGroupName()
   {
      return m_currentGroup;
   }
   
   /**
    * Retrieves the current export/Import group.
    * 
    * @return                    current group
    */
   public ExportImportGroup getCurrentGroup()
   {
      return m_groups:[m_currentGroup];
   }
   
   /**
    * Renames a group.
    * 
    * @param origName            old name of group
    * @param newName             new name of group
    */
   public void renameGroup(_str origName, _str newName)
   {
      if (m_groups._indexin(origName)) {
         ExportImportGroup eig = m_groups:[origName];
         eig.setName(newName);
         m_groups:[newName] = eig;
         m_groups:[origName] = null;
         m_parser -> deleteExportGroup(origName);
      }
   }

   /**
    * Deletes a group.
    * 
    * @param groupName           name of group to delete
    */
   public void deleteGroup(_str groupName)
   {
      if (m_groups._indexin(groupName)) {
         m_groups:[groupName] = null;
         
         // delete it from the parser
         m_parser -> deleteExportGroup(groupName);
      }
   }

   /**
    * Sets an item's status.  This status determines whether the item is to be 
    * exported or imported as part of the current group. 
    * 
    * @param index               xml index of item
    * @param value               item status
    */
   public void setItemStatus(int index, ExportImportItemStatus value)
   {
      if (m_currentGroup != '') {
         m_groups:[m_currentGroup].setItemStatus(index, value);
      }
   }

   /**
    * Retrieves the current status of the given item in the current group.
    * 
    * @param index               xml index of item
    * 
    * @return                    current status of item
    */
   public ExportImportItemStatus getItemStatus(int index)
   {
      status := m_defaultStatus;
      if (m_currentGroup != '') {
         status = m_groups:[m_currentGroup].getItemStatus(index);
         if (status == null) status = m_defaultStatus;
      }

      return status;
   }

   /**
    * Sets an item's protection status.  This status determines whether an item 
    * is to be exported/imported with a protection.  A protection, upon import, 
    * prevents an item from being overwritten. 
    * 
    * @param index               xml index of item
    * @param value               protection status
    */
   public void setItemProtectionStatus(int index, ExportImportProtectionStatus value)
   {
      if (m_currentGroup != '') {
         m_groups:[m_currentGroup].setItemProtectionStatus(index, value);
      }
   }

   /**
    * Retrieves an item's protection status.  This status determines whether an item 
    * is to be exported/imported with a protection.  A protection, upon import, 
    * prevents an item from being overwritten. 
    * 
    * @param index               xml index of item
    * 
    * @return                    item's protection status
    */
   public int getItemProtectionStatus(int index)
   {
      if (m_currentGroup != '') {
         return m_groups:[m_currentGroup].getItemProtectionStatus(index);
      }
      
      return EIPS_FALSE;
   }

   public void getAllDialogsAndPropertySheets(int (&nodes)[])
   {
      // get all the items which have status of TRUE or SOME_CHILDREN
      int allNodes[] = m_groups:[m_currentGroup].getAllIndices();

      // we only want property sheets and dialogs here
      foreach (auto node in allNodes) {
         // sometimes nodes become invalid...it's very sad
         if (!m_parser -> isNodeValid(node)) continue;

         // we only want dialogs and property sheets.  For reals.
         if (m_parser -> isAPropertySheet(node) || m_parser -> isADialog(node)) nodes[nodes._length()] = node;
      }
   }

   public void getStatusesForProperties(int psXMLIndex, int (&indices):[])
   {
      // go through all the children
      property := m_parser -> getFirstChild(psXMLIndex);
      while (property > 0) {

         indices:[property] = getItemStatus(property);

         // if this is a property group, then we want to check the properties
         // inside, too
         if (m_parser -> isAPropertyGroup(property)) {
            getStatusesForProperties(property, indices);
         }

         // get the next one
         property = m_parser -> getNextSibling(property);
      }
   }

   public void getAllIndices(int (&nodes)[], bool onlyLeaves = false)
   {
      int allNodes[] = m_groups:[m_currentGroup].getAllIndices();
      
      if (onlyLeaves) {
         // go through and eliminate anything that is not a leaf
         foreach (auto node in allNodes) {
            if (!m_parser -> isNodeValid(node)) continue;
            // to be a leaf in the options tree, you must be a property or a 
            // dialog with no property children
            if (m_parser -> isAProperty(node)) nodes[nodes._length()] = node;
            else if (m_parser -> isADialog(node) && (m_parser -> getFirstChild(node) < 0)) nodes[nodes._length()] = node;
            else if (m_parser -> isADialogWithSummaryItems(node)) nodes[nodes._length()] = node; 
         }
         
      } else nodes = allNodes;
   }

   /**
    * Retrieves the names of all currently loaded groups.
    * 
    * @param names               array of group names to be filled
    */
   public void getAllGroupNames(_str (&names)[])
   {
      m_parser -> getExportGroupNames(names);
   }

   public void getAllGroupNamesWithProtections(_str (&groups):[])
   {
      _str names[];
      m_parser -> getExportGroupNames(names);
      foreach (auto name in names) {
         groups:[name] = m_parser -> doesExportGroupHaveProtections(name);
      }
   }
   
   public void saveGroups(bool writeToFile)
   {
      m_parser -> writeExportGroups(m_groups, writeToFile);
   }

   public void createNewGroup(_str newGroupName, _str srcGroupName = '')
   {
      ExportImportGroup eig(newGroupName);
      if (srcGroupName != '' && m_groups._indexin(srcGroupName)) {
         m_groups:[srcGroupName].copyItemsToGroup(eig);
      } 
      m_groups:[newGroupName] = eig;
   }

   public void changeXMLNodeChildrenStatus(int xmlIndex, ExportImportItemStatus status)
   {
      if (m_parser -> isAProperty(xmlIndex)) {
         return;
      }

      child := m_parser -> getFirstChild(xmlIndex);
      while (child > 0) {
         setItemStatus(child, status);

         // recurse on the child, please
         if (!m_parser -> isAProperty(child)) {
             changeXMLNodeChildrenStatus(child, status);
         }

         child = m_parser -> getNextSibling(child);
      }
   }

   private void changeXMLNodeParentStatus(int xmlIndex, ExportImportItemStatus childStatus)
   {
      // we need more info...
      parentXMLIndex := m_parser -> getParent(xmlIndex);
      if (parentXMLIndex <= 0) return;

      parentStatus := getItemStatus(parentXMLIndex);

      // if status matches, then we gots nothin' to do
      if (parentStatus == childStatus) return;

      // first we check out all the siblings
      newParentStatus := childStatus;
      child := m_parser -> getFirstChild(parentXMLIndex);
      while (child > 0) {

         if (getItemStatus(child) != childStatus) {
            // change status to tri-state for parent
            newParentStatus = EIIS_SOME_CHILDREN;
            break;
         }

         child = m_parser -> getNextSibling(child);
      }

      setItemStatus(parentXMLIndex, newParentStatus);
      changeXMLNodeParentStatus(parentXMLIndex, newParentStatus);
   }
};
