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
#import "markfilt.e"
#import "stdprocs.e"
#import "util.e"
#import "se/lang/api/LanguageSettings.e"
#import "se/autobracket/AutoBracketListener.e"
#import "se/ui/AutoBracketMarker.e"
#endregion

using namespace se.lang.api;
using namespace se.autobracket;
using namespace se.ui;

int def_autobracket_mode_keys = AUTO_BRACKET_KEY_TAB;

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

bool AutoBracketKeyin(_str key)
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

bool doAutoSurroundChar(_str key) 
{
   if (p_readonly_mode || p_hex_mode == HM_HEX_ON) {
      return(false);
   }

   opts := LanguageSettings.getAutoSurround(p_LangId);
   status := false;
   if (opts & AUTO_BRACKET_ENABLE) {
      switch (key) {
      case '(':
      case ')':
         status = (opts & AUTO_BRACKET_PAREN) ? true : false;
         break;

      case '[':
      case ']':
         status = (opts & AUTO_BRACKET_BRACKET) ? true : false;
         break;

      case '{':
      case '}':
         status = (opts & AUTO_BRACKET_BRACE) ? true : false;
         break;

      case '<':
      case '>':
         status = (opts & AUTO_BRACKET_ANGLE_BRACKET) ? true : false;
         break;

      case '"':
         status = (opts & AUTO_BRACKET_DOUBLE_QUOTE) ? true : false;
         break;

      case "'":
         status = (opts & AUTO_BRACKET_SINGLE_QUOTE) ? true : false;
         break;

      default:
         // allow custom chars per lang?
         break;
      }
   }

   if (!status) {
      return(false);
   }

   // define your own language specific auto surround char callback.
   index := _FindLanguageCallbackIndex('-%s-auto-surround-char',p_LangId);
   if (index_callable(index)) {
      return call_index(key, index);
   }
   return _default_auto_surround_char(key);
}

static _str gsurround_char_pairs='''''""``(){}[]<>';
bool _default_auto_surround_char(_str key)
{
   i := pos(key,gsurround_char_pairs);
   if (!i) {
      return false;
   }
   if ((i&1)==0) {
      --i;
   }
   first_char := substr(gsurround_char_pairs,i,1);
   last_char := substr(gsurround_char_pairs,i+1,1);

   if (_select_type()=='LINE') {
      /* 
          Treat this a lot like a CHAR selection. 
      */
      int temp_mark=_duplicate_selection();
      _save_pos2(auto p);
      _begin_select(temp_mark);
      p_col=1;
      _insert_text(first_char);
      _end_select(temp_mark);_end_line();
      _insert_text(last_char);
      _free_selection(temp_mark);
      _restore_pos2(p);
      return true;
   }
   if (_select_type()=='CHAR') {
      /*
         Place the characters just outside the selection.
      */
      if (substr(_select_type('','P'),2,1)=='B') {
         int temp_mark=_duplicate_selection();
         _save_pos2(auto p);
         _begin_select(temp_mark);
         _insert_text(first_char);
         _end_select(temp_mark);
         _insert_text(last_char);
         _free_selection(temp_mark);
         _restore_pos2(p);left();
      } else {
         int temp_mark=_duplicate_selection();
         _save_pos2(auto p);
         _end_select(temp_mark);
         _insert_text(last_char);
         _begin_select(temp_mark);
         _insert_text(first_char);
         _free_selection(temp_mark);
         _restore_pos2(p);
      }
      return true;
   }
   /*
      Place the characters just outside the selection.
    
      Note: If we want to change the column selection so that the column selection
      is inside the characters inserted, it would be easiest to add a _set_selinfo(start_col,end_col,markid)
   */
   int temp_mark=_duplicate_selection();
   _save_pos2(auto p);
   _begin_select(temp_mark);
   int start_col,end_col;
   int buf_id;
   _get_selinfo(start_col,end_col,buf_id,temp_mark);
   //say('end_col='end_col);
   for (;;) {
      p_col=start_col;
      _insert_text(first_char);
      p_col=end_col+2;
      if (p_col>_text_colc()) {
         _end_line();
      }
      _insert_text(last_char);
      down();
      if(_end_select_compare(temp_mark)>0) break;
   }
   _free_selection(temp_mark);
   _restore_pos2(p);
   return true;
}

bool _generic_auto_surround_char(_str key)
{
   // special case for surround <>
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_STRING && cfg != CFG_COMMENT && pos(key,'<>')) {
      return false;
   }
   return _default_auto_surround_char(key);
}
