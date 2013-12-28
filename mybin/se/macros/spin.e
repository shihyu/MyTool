////////////////////////////////////////////////////////////////////////////////////
// $Revision: 43889 $
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
#import "main.e"
#import "picture.e"
#import "stdprocs.e"
#endregion

//
//    User level 2 inheritance for SPIN control
//
#define CLOSE_ENOUGH_TO_OVERLAP 20  // twips


void _on_spin_up_down(boolean doUp) {
   int textbox_wid=p_prev;
   if (textbox_wid.p_object!=OI_TEXT_BOX && p_increment>0) {
      say(nls("Text box operated on by spin control must have a tab index one less than the spin control."));
      return;
   }
   if (p_increment<=0) {
      if (doUp) {
         p_window_id.call_event(p_window_id,ON_SPIN_UP);
      } else {
         p_window_id.call_event(p_window_id,ON_SPIN_DOWN);
      }
      return;
   }
   typeless text=textbox_wid.p_text;
   if (text=='') {
      text=p_min;
   }
   if (!isnumber(text)) {
      _beep();
      return;
   }
   if (doUp) {
      if (text+p_increment<=p_max) {
         text+=p_increment;
         textbox_wid._set_sel(1,length(text)+1);
         textbox_wid.p_text=text;
      }
   } else {
      if(text-p_increment>=p_min){
         text-=p_increment;
         textbox_wid._set_sel(1,length(text)+1);
         textbox_wid.p_text=text;
      }
   }
}

