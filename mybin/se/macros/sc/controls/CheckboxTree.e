////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49909 $
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
#require "sc/lang/IControlID.e"
#import "treeview.e"
#import "varedit.e"
#import "stdprocs.e"
#endregion

enum CheckboxTreeNodeStatus {
   CBTNS_UNCHECKED,
   CBTNS_CHECKED,
   CBTNS_SOME_CHILDREN,
}

/**
 * The "sc.controls" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language's
 * form editor system and editor control.  It also contains
 * class wrappers for composite controls.
 */
namespace sc.controls;

#define CHECKBOXTREE       'CheckboxTreeThis'

class CheckboxTree : sc.lang.IControlID {
   // the window ID of the tree we are using
   protected int m_treeHandle;    

   /** 
    * Constructor
    * 
    * @param WID Window ID of tree control for this instance to be 
    *            coupled with
    */
   public CheckboxTree(int wid = 0) 
   {
      m_treeHandle = wid;

      // this needs to be the last thing done in the constructor, so we always have 
      // up to date data
      tieCheckboxToTree(wid);
   }

   /**
    * Sets up the checkbox such that the GUI tree has access to it for event 
    * handling. 
    * 
    * @param wid           window id of treeview object
    * @return 
    */
   protected void tieCheckboxToTree(int wid)
   {
      _SetDialogInfoHt(CHECKBOXTREE, this, m_treeHandle, true);
   }

   /** 
    * @return Window id of the tree control
    */
   public int getWindowID() 
   {
      return m_treeHandle;
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
      // first we change this node's status
      status := getNextStatus(getNodeStatus(treeIndex));
      setNodeStatus(treeIndex, status);

      return 1;
   }

   /**
    * Sets the initial status of a node.  Handles the GUI aspect of this. Does 
    * not handle changes in status for parent and children nodes associated with
    * this node.  This is only meant to set the node's status for the first 
    * time, without affecting any other nodes.  Use setNodeStatus
    * for complete handling.
    * 
    * @param treeIndex           index of item to be changed   
    * @param status              new status of item
    */
   public void setNodeInitialStatus(int treeIndex, int status)
   {
      // doing the actual work here
      m_treeHandle._TreeSetCheckable(treeIndex, 1, 1, status);
   }

   /**
    * Sets the status of a node.  Handles the GUI aspect of this.  Also handles 
    * changes in status for parent and children nodes associated with this node.
    * 
    * @param treeIndex           index of item to be changed   
    * @param status              new status of item
    */
   public void setNodeStatus(int treeIndex, int status)
   {
      // doing the actual work here
      changeNodeStatus(treeIndex, status);

      // we get to do tricksy things with other nodes
      changeNodeChildrenStatus(treeIndex, status);

      // now we look at the parents...
      changeNodeParentStatus(treeIndex, status);
   }

   /**
    * Gets the current status of an item in the tree.  Status is one of 
    * CheckBoxTreeNodeStatus enum. 
    * 
    * @param treeIndex           item to fetch status for
    * 
    * @return                    current status
    */
   protected int getNodeStatus(int treeIndex)
   {
      return m_treeHandle._TreeGetCheckState(treeIndex);
   }

   /**
    * Retrieves the next status.  When a user clicks on a node with the given 
    * status, retrieves the status that the node should switch to. 
    * 
    * @param status              current status
    * 
    * @return                    status that a node with the current status will 
    *                            switch to after a click
    */
   protected int getNextStatus(int status)
   {
      newStatus := -1;
      switch ( status ) {
      case CBTNS_CHECKED:
         newStatus = CBTNS_UNCHECKED;
         break;
      case CBTNS_UNCHECKED:
      case CBTNS_SOME_CHILDREN:
         newStatus = CBTNS_CHECKED;
         break;
      }

      return newStatus;
   }

   /**
    * Changes the GUI such that a node displays its new status.  Does not handle 
    * changing the parent and children of this node. 
    * 
    * @param treeIndex           tree item to change
    * @param status              new status of tree item 
    */
   protected void changeNodeStatus(int treeIndex, int status)
   {
      m_treeHandle._TreeSetCheckState(treeIndex, status);
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
      // nothing to do here, why was this even called?
      if (status == CBTNS_SOME_CHILDREN) return;

      // see if these children have already been exposed in the tree
      child := getFirstChild(treeIndex);
      if (child > 0) {
         while (child > 0) {
            // make sure and set the info in our table
            changeNodeStatus(child, status);
   
            // call this recursively on any children this node has
            changeNodeChildrenStatus(child, status);
   
            child = getNextSibling(child);
         }
      } 
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
      // get our parent...hey, ma!
      parentTreeIndex := getParent(treeIndex);
      if (!parentTreeIndex || parentTreeIndex < 0) return;

      // if our status is tri-state, then it's easy...
      if (childStatus == CBTNS_SOME_CHILDREN) {
         changeNodeStatus(parentTreeIndex, childStatus);
         changeNodeParentStatus(parentTreeIndex, childStatus);
         return;
      }

      // we need more info...                           
      newParentStatus := determineNewParentStatus(parentTreeIndex);

      changeNodeStatus(parentTreeIndex, newParentStatus);
      changeNodeParentStatus(parentTreeIndex, newParentStatus);
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
      // we need more info...
      parentStatus := getNodeStatus(parentTreeIndex);

      // set the parent status to match the first child
      child := getFirstChild(parentTreeIndex);
      if (child < 0) return getNodeStatus(parentTreeIndex);
         
      newParentStatus := getNodeStatus(child);
      
      // now go through the rest of the children and compare
      child = m_treeHandle._TreeGetNextSiblingIndex(child);
      while (child > 0) {

         if (getNodeStatus(child) != newParentStatus) {
            // change status to tri-state for parent
            newParentStatus = CBTNS_SOME_CHILDREN;
            break;
         }

         child = getNextSibling(child);
      }

      return newParentStatus;
   }

   #region Relative Methods
   /**
    * These are intended to be possibly overwritten, just in case any inherited 
    * classes have some strange notions about being a parent, child, or sibling.
    */

   /**
    * Retrieves a node's first child in the tree.  This returns the standard 
    * tree definition of first child.  -1 is returned if the specified node has 
    * no children. 
    * 
    * @param index            index to get first child for
    * 
    * @return                 index of first child, -1 if no children
    */
   protected int getFirstChild(int index)
   {
      return m_treeHandle._TreeGetFirstChildIndex(index);
   }

   /**
    * Retrieves a node's next sibling in the tree.  This returns the standard 
    * tree definition of next sibling.  -1 is returned if the specified node 
    * has no siblings following. 
    * 
    * @param index            index to get next sibling for
    * 
    * @return                 index of next sibling, -1 if no more siblings
    */
   protected int getNextSibling(int index)
   {
      return m_treeHandle._TreeGetNextSiblingIndex(index);
   }

   /**
    * Retrieves a node's parent in the tree.  This returns the standard 
    * tree definition of parent.  -1 is returned if the specified node has no 
    * parent (when index = TREE_ROOT_INDEX). 
    * 
    * @param index            index to get parent for
    * 
    * @return                 index of parent, -1 if index is root
    */
   protected int getParent(int index)
   {
      return m_treeHandle._TreeGetParentIndex(index);
   }

   #endregion Relative Methods

};
