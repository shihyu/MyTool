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
#require "sc/lang/IComparable.e"
#endregion Imports

namespace se.vc.vccache;

/**
 * This is the base class for revisions, branches and labels.
 * 
 * @author shackett (9/11/2009)
 */
class VCBaseRevisionItem : sc.lang.IComparable
{
   protected int m_parentBranchID = -1;
   protected _str m_number ='';
   protected _str m_name ='';
   protected _str m_timestamp;
   protected _str m_author;
   protected _str m_comments;

   // constructor
   VCBaseRevisionItem(int parentBranchID=-1, _str number='', _str name='', _str timestamp='', _str author='', _str comments='') {
      m_parentBranchID = parentBranchID;
      m_number = number;
      m_name = name;
      m_timestamp = timestamp;
      m_author = author;
      m_comments = comments;
   }

   // ----------------------------------
   public int get_ParentBranchID() {
      return m_parentBranchID;
   }
   public void set_ParentBranchID(int value) {
      m_parentBranchID = value;
   }

   // ----------------------------------
   public _str get_Number() {
      return m_number;
   }
   public void set_Number(_str value) {
      m_number = value;
   }

   // ----------------------------------
   public _str get_Name() {
      return m_name;
   }
   public void set_Name(_str value) {
      m_name = value;
   }

   // ----------------------------------
   public _str get_Timestamp() {
      return m_timestamp;
   }
   public void set_Timestamp(_str value) {
      m_timestamp = value;
   }

   // ----------------------------------
   public _str get_Author() {
      return m_author;
   }
   public void set_Author(_str value) {
      m_author = value;
   }

   // ----------------------------------
   public _str get_Comments() {
      return m_comments;
   }
   public void set_Comments(_str value) {
      m_comments = value;
   }

   /**
    * Returns the number for which the item should be inserted in a file's 
    * history.  For revisions, this is the revision number (default).  For 
    * branches and labels, this is the copy-from number. 
    * 
    * @author shackett (9/21/2009)
    */
   public _str get_HistoryInsertionNumber() {
      return m_number;
   }

   /**
    * IComparable implementation for sorting items by their history insertion 
    * number.  If they are equal (in the case of branches and labels) then use 
    * the revision number.  This is an arcane pattern of comparison I figured 
    * out looking through many SVN log files, modify at your own risk. 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param rhs : the item that this item will be compared against.
    * 
    * @return int : -1 if this item comes before the comparison item, 1 if it 
    *         comes after, or 0 if they are the same.
    */
   public int compare(sc.lang.IComparable& rhs) {
      if (rhs == null) {
         return (this == null) ? 0 : -1;
      }
      // cast to a base revision items
      VCBaseRevisionItem rhsObj = (VCBaseRevisionItem)rhs;
      // figure out where it should go in the history
      int historyInsertionNumberThis = (int)get_HistoryInsertionNumber();
      int historyInsertionNumberRhs = (int)rhsObj.get_HistoryInsertionNumber();
      if (historyInsertionNumberThis < historyInsertionNumberRhs) {
         return -1;
      } else if (historyInsertionNumberThis > historyInsertionNumberRhs) {
         return 1;
      } else {
         // is the history insertion numbers are equal, then use the revision number.  This is how
         // it works to determine where multiple adjacent branches are located.
         int revisionNumberThis = (int)get_Number();
         int revisionNumberRhs = (int)rhsObj.get_Number();
         if (revisionNumberThis < revisionNumberRhs) {   
            return -1;
         } else if (revisionNumberThis > revisionNumberRhs) {
            return 1;
         }
      }
      // if we got here, then they truly are equal, and that should n't happen
      return 0;
   }

};
