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
#import "stdprocs.e"
#require "se/autobracket/DefaultAutoBracket.e"
#endregion

namespace se.lang.generic;
using se.autobracket.DefaultAutoBracket;

class GenericAutoBracket : DefaultAutoBracket {
   protected boolean checkBracket()
   {
      status := 0;
      save_pos(auto p);
      // limit to current line
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id, '');
      _show_selection(mark_id);
      // look ahead
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

            case ']':
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
            case CFG_PUNCTUATION:
            case CFG_OPERATOR:
               break;

            case CFG_KEYWORD:
            case CFG_STRING:
            case CFG_NUMBER:
               status = 1;
               break;

            default:
               parse p_identifier_chars with auto idchars .;
               if (isalnum(ch) || pos('['idchars']', ch, 1, 'r')) {
                  restore_pos(p);
                  status = testBracketOp(get_text()) ? 0 : 1;
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

   // test if bracket [] auto-close preceding idchar allowed (DEFAULT IMPLEMENTATION)
   protected boolean testBracketOp(_str ch)
   {
      return(false);
   }

   protected boolean checkParens()
   {
      status := 0;
      save_pos(auto p);
      // limit to current line
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id, '');
      _show_selection(mark_id);
      // look ahead
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

   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      return (ch == '+');
   }

   protected boolean genericCheckQuote(_str &key) {
      save_pos(auto p);
      // limit scan to current line
      orig_mark_id := _duplicate_selection('');
      mark_id := _alloc_selection();
      _select_line(mark_id, '');
      _show_selection(mark_id);

      // look ahead
      status := _clex_skip_blanks('m');  // STRING_NOT_FOUND_RC is ok
      if (!status) {
         _end_line();
         if (_clex_find(0, 'g') == CFG_STRING) {
            // possible unterminated string or mismatch quotes
            status = 1;
         } else {
            restore_pos(p);
            ch := get_text();
            switch (ch) {
            case '"':
            case "'": // awkward...
               status = 1;
               break;

            case ')':
            case ']':
            case '}':
            case ',':
            case ';':
            case '=':
            case ':':
               // allow following punctuation and operators
               break;

            default:
               if (!testStringOp(ch, 1)) {
                  right();
                  if (p_col < _text_colc()) {
                     status = 1;
                  }
               }
               break;
            }
         }
      }
      restore_pos(p);

      // look behind
      left();
      if (!status && !_clex_skip_blanks('-m')) {
         switch (_clex_find(0, 'g')) {
         case CFG_PPKEYWORD:
         case CFG_KEYWORD:
         case CFG_PUNCTUATION:
            break;

         default:
            ch := get_text();
            switch (ch) {
            case '"':
            case "'": // awkward...
               status = 1;
               break;

            case '(':
            case '[':
            case '{':
            case ',':
            case ';':
            case '=':
            case ':':
               // allow preceding punctuation and operators
               break;

            default:
               if (!testStringOp(ch, -1)) { 
                  status = 1;
               }
               break;
            }
            break;
         }
      }
      restore_pos(p);
      if (status == STRING_NOT_FOUND_RC) {
         status = 0; // must be EOL, go ahead and autoquote
      } else if (status < 0) {
         status = 1;
      }

      _show_selection(orig_mark_id);
      _free_selection(mark_id);
      return(status > 0);
   }

   protected boolean checkQuote(_str &key)
   {
      return (genericCheckQuote(key));
   }
};

// TODO: move following to se\lang\<LangName>\<LangName>AutoBracket.e

class DAutoBracket : GenericAutoBracket 
{
   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      return (ch == '~');
   }
};

class LuaAutoBracket : GenericAutoBracket 
{
   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      status := false;
      if (ch == '.') {
         if (dir < 0 && p_col > 1) {
            left();
         }
         if (get_text(2) == '..') {
            status = true;
         }
      }
      return status;
   }
};

class PerlAutoBracket : GenericAutoBracket
{
   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      return (ch == '.');
   }
};

class CSharpAutoBracket : GenericAutoBracket
{
   // test for specific concating operator for auto-quoting
   protected boolean testStringOp(_str ch, int dir)
   {
      status := false;
      switch (ch) {
      case '@':   // verbatim literal
      case '+':   // common to overload + for strcat
         status = true;
         break;
      }
      return status;
   }
};

// add quote checks for triple quote languages
class TQAutoBracket : GenericAutoBracket {

   protected boolean checkQuote(_str &key)
   {
      if (genericCheckQuote(key)) {
         return true;
      }
      status := 0;
      if (p_col > 2) {
         save_pos(auto p);
         left();
         if (get_text() == '"') {
            left();
            if (get_text() == '"') {
               status = 1;
            }
         }
         restore_pos(p);
      }
      return(status > 0);
   }
};


class PythonAutoBracket : TQAutoBracket {
};

class CoffeeScriptAutoBracket : TQAutoBracket {
};

class ScalaAutoBracket : TQAutoBracket {
};



