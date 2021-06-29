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
#endregion Imports

namespace se.vc.vccache;

class VCExclusion
{
   private int m_itemID = -1;
   private _str m_type = "";
   private _str m_name = "";

   // constructor
   VCExclusion(int itemID=-1, _str type='', _str name='') {
      m_itemID = itemID;
      m_type = type;
      m_name = name;
   }

   // ----------------------------------
   public int get_ItemID() {
      return m_itemID;
   }
   public void set_ItemID(int value) {
      m_itemID = value;
   }

   // ----------------------------------
   public _str get_Type() {
      return m_type;
   }
   public void set_Type(_str value) {
      m_type = value;
   }

   // ----------------------------------
   public _str get_Name() {
      return m_name;
   }
   public void set_Name(_str value) {
      m_name = value;
   }

};
