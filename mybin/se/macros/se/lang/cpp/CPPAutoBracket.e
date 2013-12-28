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
#include "markers.sh"
#import "pmatch.e"
#import "stdcmds.e"
#import "stdprocs.e"
#require "se/lang/generic/GenericAutoBracket.e"
#endregion

namespace se.lang.cpp;
using se.lang.generic.GenericAutoBracket;

class CPPAutoBracket : GenericAutoBracket {
   protected boolean checkParens()
   {
      status := 0;
      save_pos(auto p);
      // limit scan to current line
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id, '');
      _show_selection(mark_id);
      col := p_col;
      // lookahead
      if (_clex_skip_blanks('m') == 0) {
         ch := get_text();
         cfg := _clex_find(0, 'g');
         status = (cfg == CFG_STRING || cfg == CFG_COMMENT) ? 1 : 0;
         if (!status) {
            switch (ch) {
            case '(':
            case '[':
            case '{':
               status = 1;
               break;
            case '&':
               if (get_text(2) == '&&') {
                  break;
               } // fall-through
            case '*':
            case '!':
               status = 1;
               break;
            case ')':
               save_pos(auto p1);
               if (find_matching_paren(true) != 0) {
                  status = 1;
               }
               restore_pos(p1);
               break;
            }
         }
         if (!status) {
            switch (cfg) {
            case CFG_PPKEYWORD:
            case CFG_OPERATOR:
            case CFG_PUNCTUATION:
               break;

            case CFG_KEYWORD:
            case CFG_STRING:
            case CFG_NUMBER:
               status = 1;
               break;

            default:
               parse p_identifier_chars with auto idchars .;
               if (isalnum(ch) || pos('['idchars']', ch, 1, 'r')) {
                  status = 1;
               }
               break;
            }
         }
      }

      restore_pos(p);
      _show_selection(orig_mark_id);
      _free_selection(mark_id);
      return(status > 0);
   }

   // check for preprocessor statement
   //    #include
   //    #import
   //
   // check for keywords
   //    template
   //    dynamic_cast
   //    const_cast
   //    reinterpret_cast
   //    static_cast
   //
   protected boolean checkAngleBracket()
   {
      status := 0;
      save_pos(auto p);
      // limit scan to current line
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id, '');
      _show_selection(mark_id);
      col := p_col;
      // lookbehind
      if (_clex_skip_blanks('m-') == 0) {
         if(col > p_col && _clex_find(KEYWORD_CLEXFLAG|PPKEYWORD_CLEXFLAG, 't')) {
            word := strip(cur_word(auto start_col));
            if (col > start_col) {
               switch(word) {
               // valid keywords
               case 'template':
               case 'dynamic_cast':
               case 'const_cast':
               case 'reinterpret_cast':
               case 'static_cast':
               // valid preproccesing keyword
               case 'include':
               case 'import':
                  status = 1;
                  break;
               }
            }
         }
      }
      restore_pos(p);
      _show_selection(orig_mark_id);
      _free_selection(mark_id);
      return(status == 0);
   }

   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      status := false;
      switch (ch) {
      case '+':   // common to overload + for strcat
         status = true;
         break;

      case '<':  // allow std::cout operator <<
         if (dir < 0 && p_col > 1) {
            left();
         } 
         if (get_text(2) == '<<') {
            status = true;
         }
         break;
      }
      return status;
   }
};

