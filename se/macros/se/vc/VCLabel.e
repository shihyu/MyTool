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
#require "se/vc/VCBaseRevisionItem.e"
#require "sc/lang/IComparable.e"
#endregion Imports

namespace se.vc.vccache;
using sc.lang.IComparable;

/**
 * Represents a label (or tag) in the source control system.
 * 
 * @author shackett (9/11/2009)
 */
class VCLabel : IComparable,VCBaseRevisionItem
{ 
   private int m_labelID = -1;
   private _str m_copyFromNumber = "";

   // constructor
   VCLabel(int parentBranchID=-1, _str number='', _str copyFromNumber='', _str timestamp='', _str name='', _str author='', _str comments='') {
      m_parentBranchID = parentBranchID;
      m_number = number;
      m_copyFromNumber = copyFromNumber;
      m_timestamp = timestamp;
      m_name = name;
      m_author = author;
      m_comments = comments;
   }

   // ----------------------------------
   public int get_LabelID() {
      return m_labelID;
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

   int compare(IComparable &rhs) {
      if (rhs==null) {
         return (this==null)? 0:-1;
      }
      if (((VCLabel)rhs).m_name == null) {
         return (this.m_name==null)? 0:-1;
   }
      if (this.m_name == null) return 1;
      if (this.m_name :== ((VCLabel)rhs).m_name) return 0;
      return (this.m_name < ((VCLabel)rhs).m_name)? -1:1;
   }
};
