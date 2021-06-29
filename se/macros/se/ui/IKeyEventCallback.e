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
#endregion

namespace se.ui;

interface IKeyEventCallback {
   // key callback
   bool onKey(_str &key);

   // handlers for state changes
   void onRemove();
   void onPush();
   void onPop();

   // save/restore stream markers offsets for beautifer
   bool save(long (&markers)[], long (&cursorMarkerIndices)[], long start_offset, long end_offset);
   void restore(long (&markers)[], int start_index);
};

