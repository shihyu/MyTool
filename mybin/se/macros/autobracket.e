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
#import "stdprocs.e"
#import "se/lang/api/LanguageSettings.e"
#import "se/autobracket/AutoBracketListener.e"
#import "se/ui/AutoBracketMarker.e"
#endregion

using namespace se.lang.api;
using namespace se.autobracket;
using namespace se.ui;

int def_autobracket_mode_keys = AUTO_BRACKET_KEY_ENTER | AUTO_BRACKET_KEY_TAB;

void setAutoBracketCallback(_str langID)
{
   keys_enabled := true;
   while (keys_enabled && langID != "") {
      if (!(LanguageSettings.getAutoBracket(langID) & AUTO_BRACKET_ENABLE)) {
         keys_enabled = false; 
         break;
      }
      langID = LanguageSettings.getLangInheritsFrom(langID);
   }

   AutoBracketListener.initCallback(langID, keys_enabled);
}

void AutoBracketCancel()
{
   AutoBracketListener.cancelBracketInsert();
}

void AutoBracketDeleteText()
{
   AutoBracketMarker.checkDeletedMarkers();
}

boolean AutoBracketKeyin(_str key)
{
   if (command_state() || !_isEditorCtl() || !AutoBracketListener.onKeyin(key)) {
      keyin(key);
      return false;
   }
   // closing bracket was put in
   return true;
}

void AutoBracketForBraces(_str lang, long lbrace_offset, long rbrace_offset) {
   AutoBracketMarker.createMarker('}', lbrace_offset, 1, rbrace_offset, 1);
}
