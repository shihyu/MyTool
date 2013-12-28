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
#require "sc/lang/IComparable.e"
#require "VCBaseRevisionItem.e"
#endregion Imports

namespace se.vc.vccache;


/**
 * Represents a revision, or "check in" in the source control system.
 * 
 * @author shackett (9/11/2009)
 */
class VCRevision : VCBaseRevisionItem
{
   private int m_revisionID = -1;

   // constructor
   VCRevision(int parentBranchID=-1, _str number='', _str name='', _str timestamp='', _str author='', _str comments='') {
      m_parentBranchID = parentBranchID;
      m_number = number;
      m_name = name;
      m_timestamp = timestamp;
      m_author = author;
      m_comments = comments;
   }

   // ----------------------------------
   public int get_RevisionID() {
      return m_revisionID;
   }

};
