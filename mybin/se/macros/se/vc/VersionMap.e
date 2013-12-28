////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

/**
 */
class VersionMap {
   private _str m_versionMap:[][]=null;
   private _str m_labelMap:[]=null;

   public void setVersionMap(_str (&versionMap):[][]) {
      m_versionMap = versionMap;
   }

   public void addVersion(_str version,_str label) {
      len := m_versionMap._length();
      m_versionMap:[version][len]=label;
   }

   private void getLabelMap(){
      foreach ( auto versionIndex => auto array in m_versionMap ) {
         for ( i:=0;i<array._length();++i ) {
            m_labelMap:[array[i]] = versionIndex;
         }
      }
   }

   public _str getVersion(_str label) {
      if ( m_labelMap==null ) {
         getLabelMap();
      }
      _str version = m_labelMap:[label];
      if ( version==null ) version="";
      return version; 
   }
}

_command void test_add_version() name_info(',')
{
   VersionMap v;
   v.addVersion("one","two");
}
