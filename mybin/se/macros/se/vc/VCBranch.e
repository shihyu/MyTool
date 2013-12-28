////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#include "VCCache.sh"
#require "VCBaseRevisionItem.e"
#endregion Imports

namespace se.vc.vccache;


/**
 * Represents a branch in the source control system.
 * 
 * @author shackett (9/11/2009)
 */
class VCBranch : VCBaseRevisionItem
{
   private int m_branchID = -1;
   private _str m_copyFromNumber = "";
   private VCBaseRevisionItem m_childItems[];

   // constructor
   VCBranch(int parentBranchID=-1, _str number='', _str copyFromNumber='', _str timestamp='', _str name='', _str author='', _str comments='') {
      m_parentBranchID = parentBranchID;
      m_number = number;
      m_copyFromNumber = copyFromNumber;
      m_timestamp = timestamp;
      m_name = name;
      m_author = author;
      m_comments = comments;
      m_childItems._makeempty();
   }

   // ----------------------------------
   public int get_BranchID() {
      return m_branchID;
   }

   // ----------------------------------
   public _str get_CopyFromNumber() {
      return m_copyFromNumber;
   }
   public void set_CopyFromNumber(_str value) {
      m_copyFromNumber = value;
   }

   // ----------------------------------
   public _str get_HistoryInsertionNumber() {
      return m_copyFromNumber;
   }

   /**
    * Inserts a base revision item into its correct position in the
    * child list. VCRevision, VCBranch or VCLabel items may be 
    * added. To make this perform better, we assume that the item 
    * is most likely going to be added to the end of the list 
    * (debugging shows this to be true) 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param childItem : the item to add to the list of child items 
    */
   public void insertChildItem(VCBaseRevisionItem childItem) {
      int i = 0;

      // determine the preoper location to insert the current branch into it's parent's child list
      int childItemCount = m_childItems._length();
      int insertLocation = 0;
      int iterations = 0;
      for (i = (childItemCount - 1); i >= 0; i--) {
         iterations++;
         VCBaseRevisionItem rhs = m_childItems[i];
         // use the comparison procedure, it's easier and consistent with sorting
         if (childItem.compare(rhs) == 1) {
            insertLocation = i + 1;
            break;
         }
      }
      // if we need to 
      if (insertLocation == childItemCount) {
         m_childItems[childItemCount] = childItem;
      } else {
         m_childItems._insertel(childItem, insertLocation);
      }
   }

   /**
    * Adds a base revision item to the end of the child item list. VCRevision, 
    * VCBranch or VCLabel items may be added.
    * 
    * @author shackett (9/11/2009)
    * 
    * @param childItem : the item to add to the list of child items 
    */
   public void addChildItem(VCBaseRevisionItem childItem) {
      // insert the item into the end of the array
      m_childItems[m_childItems._length()] = childItem;
   }

   /**
    * Sorts the items in the child list based on the implementation 
    * of sc.lang.IComparable 
    */
   public void sortChildren()
   {
      m_childItems._sort();
   }

   /**
    * Gets the number of child items on the branch.
    * 
    * @author shackett (9/11/2009)
    */
   public int getChildItemCount()
   {
      return m_childItems._length();
   }

   /**
    * Returns a child item at a particular index in the list.
    * 
    * @author shackett (9/11/2009)
    * 
    * @param index : the index of the child to be retrieved.
    */
   public VCBaseRevisionItem* getChildItem(int index)
   {
      return &(m_childItems[index]);
   }

};
