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
#require "sc/lang/IComparable.e"
#include "VCCache.sh"
#endregion Imports

namespace se.vc.vccache;

/**
 * Represents a file under source control
 * 
 * @author shackett (9/11/2009)
 */
class VCFile {
   private int m_fileID = -1;
   private _str m_fileSpec = '';
   private _str m_lastUpdateTimestamp = '';

   // constructor
   VCFile(_str fileSpec='') {
      m_fileSpec = fileSpec;
   }

   // ----------------------------------
   public int get_FileID() {
      return m_fileID;
   }

   // ----------------------------------
   public _str get_FileSpec() {
      return m_fileSpec;
   }
   public void set_FileSpec(_str value) {
      m_fileSpec = value;
   }

   // ----------------------------------
   public _str get_LastUpdateTimestamp() {
      return m_lastUpdateTimestamp;
   }
   public void set_LastUpdateTimestamp(_str value) {
      m_lastUpdateTimestamp = value;
   }
};
