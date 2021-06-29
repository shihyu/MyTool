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
#require "sc/controls/CheckboxTree.e"
#require "se/options/ExportImportGroupManager.e"
#require "se/options/RelationTable.e"
#import "optionsxml.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

namespace se.options;

using namespace sc.controls.CheckboxTree;

class OptionsCheckboxTree : CheckboxTree {

   // relationship between indices in the options tree and the options.xml
   private RelationTable * m_relations;
   // checked/unchecked status data for each node
   private ExportImportGroupManager * m_statusData;
   // the descriptions used to describe the protection status values
   private _str m_protectionStatusDescriptions[];
   // handles to property sheets, indexed by the tree node where they live
   private int m_propertySheets:[];
   // handle to the main options tree
   private int m_mainTreeHandle = 0;

   public OptionsCheckboxTree(int wid = 0)
   {
      m_mainTreeHandle = wid;

      m_protectionStatusDescriptions[EIPS_TRUE] = 'True';
      m_protectionStatusDescriptions[EIPS_FALSE] = 'False';
      m_protectionStatusDescriptions[EIPS_UNPROTECT] = 'Unprotect';

      CheckboxTree(wid);
   }

   /**
    * Initializes the OptionsCheckboxTree by setting up its pointers.
    * 
    * @param relations              xml and tree index relations
    * @param statusData             checked/unchecked data for nodes
    */
   public void init(RelationTable * relations, ExportImportGroupManager * statusData)
   {
      m_relations = relations;
      m_statusData = statusData;
      m_propertySheets._makeempty();
   }

   /**
    * Retrieves the tree index that is associated with the property sheet handle 
    * given. 
    * 
    * @param psHandle               a handle to a property sheet
    * 
    * @return                       the index in the main options tree that 
    *                               leads to the property sheet given
    */
   private int getPropertySheetTreeIndexForTreeHandle(int psHandle)
   {
      treeIndex := -1;
      foreach (auto xmlIndex => auto handle in m_propertySheets) {
         if (psHandle == handle) {
            treeIndex = m_relations -> getTreeIndex(xmlIndex);
            break;
         }
      }

      return treeIndex;
   }

   /**
    * Called when the checkbox associated with a node is clicked.  Will change 
    * the checkbox to the next value.  Values go from checked to unchecked. 
    * You can not go to the "SomeChildren" value by clicking, only by having 
    * children of differing values. 
    * 
    * @param treeIndex           index of item that was clicked
    * 
    * @return                    
    */
   public int onCheckChangedEvent(int treeIndex)
   {
      // make sure we set the tree handle for the current tree
      m_treeHandle = p_window_id;

      newStatus := getNodeStatus(treeIndex);
      // the tree allows the user to click and make something tri-state...it's not ideal
      if (newStatus == CBTNS_SOME_CHILDREN) {
         newStatus = CBTNS_CHECKED;
      }

      // the actual changing was already handled by the tree, so we can
      // just get the current status - it will be the new one
      setNodeStatus(treeIndex, newStatus);

      m_treeHandle = m_mainTreeHandle;

      return 1;
   }

   /**
    * Sets up the property sheet to be a part of this OptionsCheckboxTree.  Ties 
    * it in so that changes in checked status in the tree will trickle down to 
    * the PropertySheet and vice versa. 
    * 
    * @param xmlIndex               xml index associated with this node
    * @param psHandle               handle to the property sheet 
    *                               (_ctl_property_sheet on
    *                               _property_sheet_form)
    * @param changeable             whether the user can click on nodes in this 
    *                               property sheet and change their status
    */
   public void registerPropertySheet(int xmlIndex, int psHandle, bool changeable)
   {
      // save this handle for later
      m_propertySheets:[xmlIndex] = psHandle;

      // make sure the property sheet has a handle to us
      _SetDialogInfoHt(sc.controls.CheckboxTree.CHECKBOXTREE, &this, psHandle, true);

      refreshPropertySheet(xmlIndex, changeable);
   }

   /**
    * Makes sure that all properties in this sheet have up-to-date status info, 
    * including checked/unchecked status and protection status.   Sometimes the 
    * change in status causes changes for other properties.  Also, changing the 
    * export group that is currently visible would change status for properties.
    * 
    * @param xmlIndex               xml index of property sheet being updated
    * @param changeable             whether these properties' check status can 
    *                               be changed by the user
    */
   public void refreshPropertySheet(int xmlIndex, bool changeable)
   {
      if (!m_propertySheets._indexin(xmlIndex)) return;

      // retrieve the handle to the property sheet
      psHandle := m_propertySheets:[xmlIndex];

      m_treeHandle = psHandle;

      // go ahead and set some initial status info for these properties
      if (changeable) {
         setPropertiesStatus(psHandle, TREE_ROOT_INDEX);
      } else {
         // we just set everything to be like the parent
         status := m_statusData -> getItemStatus(xmlIndex);

         setPropertiesStatus(psHandle, TREE_ROOT_INDEX, status);
      }

      m_treeHandle = m_mainTreeHandle;
   }

   /**
    * Returns whether the current tree handle (which better be a 
    * PropertySheet...or else!) has a column for protections. 
    * 
    * @return                          true if property sheet has column for 
    *                                  protections, false otherwise
    */
   private bool propertySheetHasProtections()
   {
      return (m_treeHandle._TreeGetNumColButtons() == 4);
   }

   /**
    * Sets the status for properties in a property sheet.
    * 
    * @param psHandle                  handle to the property tree
    * @param treeIndex                 index of property sheet in main options 
    *                                  tree
    * @param status                    status to set for all properties, send -1 
    *                                  to retrieve the status for each
    *                                  individual property
    */
   private void setPropertiesStatus(int psHandle, int treeIndex, int status = -1)
   {
      // go down the tree
      treeIndex = getFirstChild(treeIndex);
      doSetProtections := propertySheetHasProtections();

      while (treeIndex > 0) {
         // get the xml index from the info
         xmlIndex := getPropertyXMLIndex(treeIndex);

         // get and set the status
         itemStatus := status;
         if (itemStatus == -1 && xmlIndex > 0) {
            itemStatus = m_statusData -> getItemStatus(xmlIndex);
         } 

         // just do it already
         if (itemStatus >= 0) {
            setNodeInitialStatus(treeIndex, itemStatus);
         }

         if (doSetProtections && xmlIndex > 0) {
            setProtectionStatus(treeIndex, xmlIndex);
         }
         
         // next, please               
         treeIndex = getNextSibling(treeIndex);
      }
   }

   /**
    * Sets the current protection status for the given property
    * sheet item.  If the protection combo box has not been set up,
    * it will be done here.
    *
    * @param treeIndex
    * @param xmlIndex
    */
   private void setProtectionStatus(int treeIndex, int xmlIndex)
   {
      caption := m_treeHandle._TreeGetTextForCol(treeIndex, 3);

      // if the caption is empty, then it has never been set before, so we need to set
      // up the combo box descriptions
      if (caption == null || caption == '') {
         m_treeHandle._TreeSetComboDataNodeCol(treeIndex, 3, m_protectionStatusDescriptions);
         m_treeHandle._TreeSetNodeEditStyle(treeIndex, 3, TREE_EDIT_COMBOBOX);
      }

      // now set the current protection status
      protectStatus := getItemProtectionStatusDescription(xmlIndex);;
      if (caption != protectStatus) {
         m_treeHandle._TreeSetTextForCol(treeIndex, 3, protectStatus);
         m_treeHandle._TreeRefresh();
      }
   }

   /**
    * Determines if the tree that we are currently working with is a 
    * PropertySheet or the main options tree. 
    * 
    * @return                          true if the tree is a property sheet, 
    *                                  false if it's the main options tree
    */
   private bool isPropertySheet()
   {
      // m_treeHandle points to our main tree.  Thus if this tree is not that one, 
      // it must be a property sheet
      return (m_treeHandle != m_mainTreeHandle);
   }

   /**
    * Changes a property's protection status to a new value.
    * 
    * @param propIndex                 index of property in property sheet tree
    * @param desc                      new protection status (description)
    */
   public void setPropertyProtectionStatus(int propIndex, _str desc)
   {
      // make sure we set the tree handle for the current tree
      m_treeHandle = p_window_id;

      // get the xml index for the property using the user info
      xmlIndex := getPropertyXMLIndex(propIndex);

      // get the checked/unchecked status so we can tell if it changes
      oldStatus := m_statusData -> getItemStatus(xmlIndex);

      // set our new status
      protectStatus := getProtectionStatusForDescription(desc);
      m_statusData -> setItemProtectionStatus(xmlIndex, protectStatus);

      // we might have had to change the status of this node, so we need to 
      // update the tree and whatnot
      newStatus := m_statusData -> getItemStatus(xmlIndex);
      if (newStatus != oldStatus) {
         setNodeStatus(propIndex, newStatus);
      }

      m_treeHandle = m_mainTreeHandle;
   }

   /**
    * Retrieves the protection status value that goes with the given 
    * description. 
    * 
    * @param desc             protection status description
    * 
    * @return                 protection status that matches the description
    */
   private ExportImportProtectionStatus getProtectionStatusForDescription(_str desc)
   {
      status := (ExportImportProtectionStatus)0;
      for (i := 0; i < m_protectionStatusDescriptions._length(); i++) {
         if (m_protectionStatusDescriptions[i] == desc) {
            status = (ExportImportProtectionStatus)i;
            break;
         }
      }

      return status;
   }

   /**
    * Retrieves the string description of the given item's protection status. 
    * This description is used to display to the user the current protection 
    * status of the item. 
    *    
    * @param xmlIndex            xml index of item to check protection status 
    *                            for
    * 
    * @return                    description of protection status
    */
   private _str getItemProtectionStatusDescription(int xmlIndex)
   {
      return m_protectionStatusDescriptions[m_statusData -> getItemProtectionStatus(xmlIndex)];
   }

   /**
    * Retrieves the XML index that corresponds to the property found at the 
    * given index in the current tree.  Current tree (m_treeHandle) must be a 
    * property sheet. 
    * 
    * @param treeIndex           index in property sheet
    * 
    * @return                    xml index of property, 0 if item is not a 
    *                            property
    */
   private int getPropertyXMLIndex(int treeIndex)
   {
      // property sheets have their XML indexes built right in!

      xmlIndex := 0;
      userInfo := m_treeHandle._TreeGetUserInfo(treeIndex);
      if (isinteger(userInfo)) {
         xmlIndex = (int)userInfo;
      }

      return xmlIndex;
   }

   #region Override Methods
   /**
    * Changes the GUI such that a node displays its new status.  Does not handle 
    * changing the parent and children of this node. 
    * 
    * @param treeIndex           tree item to change
    * @param status              new status of tree item 
    * @param addIfEmpty          true to set the picture even if no picture is 
    *                            currently there, false otherwise
    */
   protected void changeNodeStatus(int treeIndex, int status)
   {
      // update the export group information
      xmlIndex := 0;
      if (isPropertySheet()) {
         // get the xml index for the property
         xmlIndex = getPropertyXMLIndex(treeIndex);
      } else {
         // get the xml index from the relations table
         xmlIndex = m_relations -> getXMLIndex(treeIndex);
      }

      // only do these things for "true" properties, instead of property sheet items
      // which have no xml item
      if (xmlIndex) {
         m_statusData -> setItemStatus(xmlIndex, (ExportImportItemStatus)status);

         // see if we need to update the protection status - sometimes they get
         // changed based on a new status
         if (propertySheetHasProtections()) {
            setProtectionStatus(treeIndex, xmlIndex);
         }
      }

      if (isPropertySheet()) {
         m_treeHandle._TreeSetCheckState(treeIndex, status);
      } else {
         // is it a leaf?
         m_treeHandle._TreeGetInfo(treeIndex, auto sc);
         if (sc == TREE_NODE_LEAF) {
            m_treeHandle._TreeSetCheckState(treeIndex, status);
         }
      }
   }

   /**
    * Updates the children of a node based on a status change by a parent.  If a
    * parent's status changes to CBTNS_CHECKED or CBTNS_UNCHECKED, then all the 
    * children will change to that status as well.  This method is recursive, 
    * affecting all descendents of the parent node. 
    *  
    * If a parent's status changes to CBTNS_SOME_CHILDREN, this method should 
    * not be called. 
    * 
    * @param treeIndex           parent 
    * @param status              parent's new status
    * @return 
    */
   protected void changeNodeChildrenStatus(int treeIndex, int status)
   {
      // save the current tree info before we do anything crazy
      treeHandle := m_treeHandle;

      // nothing to do here, why was this even called?
      if (status == CBTNS_SOME_CHILDREN) return;

      // see if these children have already been exposed in the tree
      child := getFirstChild(treeIndex);

      // only make this check AFTER we have the first child (which is when we 
      // move to the property sheet tree handle)
      onPropertySheet := isPropertySheet();

      if (child > 0) {

         while (child > 0) {
            // make sure and set the info in our table
            changeNodeStatus(child, status);
   
            // call this recursively on any children this node has
            if (!onPropertySheet) changeNodeChildrenStatus(child, status);
   
            child = getNextSibling(child);
         }
      } else if (!onPropertySheet) {
         // this item is currently a leaf, but it might have children in the xml.  
         // we need to make sure those get hit, too
         xmlIndex := m_relations -> getXMLIndex(treeIndex);
         m_statusData -> changeXMLNodeChildrenStatus(xmlIndex, (ExportImportItemStatus)status);
      }

      // reset to the old handle, because it might have changed
      m_treeHandle = treeHandle;
   }

   /**
    * Updates the parents of a node based on a status change by a child.  If a 
    * child's status changes to CBTNS_SOME_CHILDREN, then the parent is changed 
    * to that as well.  However, if the child's status changes to CBTNS_CHECKED 
    * or CBTNS_UNCHECKED, then the statuses of the other siblings must be 
    * consulted before the parent's new status can be determined. 
    *  
    * This method is recursive, affecting all ancestors of the child node. 
    * 
    * @param treeIndex           child
    * @param childStatus         child's new status
    */
   protected void changeNodeParentStatus(int treeIndex, int childStatus)
   {
      // save the current tree info before we do anything crazy
      treeHandle := m_treeHandle;

      CheckboxTree.changeNodeParentStatus(treeIndex, childStatus);

      // reset to the old handle, because it might have changed
      m_treeHandle = treeHandle;
   }

   /**
    * Determines a node's status based on the statuses of its children.  If all 
    * children are either CBTNS_CHECKED or CBTNS_UNCHECKED, then the parent is 
    * changed to that value.  If the children have varying values or are all 
    * CBTNS_SOME_CHILDREN, then the parent status is changed to 
    * CBTNS_SOME_CHILDREN. 
    * 
    * @param parentTreeIndex        parent to determine status for
    *    
    * @return                       new status for parent
    */
   protected int determineNewParentStatus(int parentTreeIndex)
   {
      // save the current tree info before we do anything crazy
      treeHandle := m_treeHandle;

      newParentStatus := CheckboxTree.determineNewParentStatus(parentTreeIndex);

      // reset to the old handle, because it might have changed
      m_treeHandle = treeHandle;

      return newParentStatus;
   }

   protected int getFirstChild(int index)
   {
      // try it the straight way
      child := m_treeHandle._TreeGetFirstChildIndex(index);

      // before we try and jump to a property sheet, make sure we are not already in one
      if (child < 0 && !isPropertySheet()) {

         // this may be a property sheet - see if there is an XML index corresponding
         xmlIndex := m_relations -> getXMLIndex(index);

         // see if the index has a property sheet
         if (m_propertySheets._indexin(xmlIndex)) {

            // get the handle of the sheet, and the first child
            psHandle := m_propertySheets:[xmlIndex];
            child = psHandle._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
            if (child > 0) {
               m_treeHandle = psHandle;
            }
         }
      }

      return child;
   }

   /**
    * Retrieves a node's next sibling in the tree.  -1 is returned if the specified node 
    * has no siblings following. 
    * 
    * @param index            index to get next sibling for
    * 
    * @return                 index of next sibling, -1 if no more siblings
    */
   protected int getNextSibling(int index)
   {
      // get the next one
      sib := m_treeHandle._TreeGetNextSiblingIndex(index);
      
      // if it's negative, then we are done
      // if this is not a property sheet, then we don't need special handling
      if (sib < 0 || !isPropertySheet()) return sib;

      // we have a property sheet, we need to make sure this is not a property group
      int sc, bm1, bm2, flags, line;
      while (sib > 0) {

         // see if this is bold
         m_treeHandle._TreeGetInfo(sib, sc, bm1, bm2, flags);

         // no, break out
         if ((flags & TREENODE_BOLD) == 0) break;

         // keep going - we honestly should not have multiple property groups in 
         // a row, but let's not make dangerous assumptions
         sib = m_treeHandle._TreeGetNextSiblingIndex(sib);
      }

      return sib;
   }

   protected int getParent(int index)
   {
      parent := m_treeHandle._TreeGetParentIndex(index);

      // we are at the top of the tree - are we at the top of a property sheet?
      if (parent == TREE_ROOT_INDEX && isPropertySheet()) {
         // we are in a property sheet, so go up to the appropriate node in the main tree

         // get the property sheet we were looking at
         parent = getPropertySheetTreeIndexForTreeHandle(m_treeHandle);

         // go back to the main tree
         m_treeHandle = m_mainTreeHandle;
      }

      return parent;
   }

   #endregion Override Methods
} 
