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
#require "se/lang/generic/GenericAutoBracket.e"
#endregion

namespace se.lang.matlab;
using se.lang.generic.GenericAutoBracket;

// Support for inline brace expansion
class MatlabAutoBracket : GenericAutoBracket {
   void init(_str (&keyarray)[]) { 
      len := keyarray._length();
      keyarray[len++] = "{";
   }

   bool getSettings(_str& key, int opts, _str &close_ch, bool &insertPad) {
      keyEnabled := false;
      switch (key) {
      case "{":
         close_ch = "}";
         keyEnabled = (opts & AUTO_BRACKET_BRACE) ? true : false;
         insertPad = (opts & AUTO_BRACKET_BRACE_PAD) ? true : false;
         break;
      }
      return(keyEnabled);
   }

   protected bool checkBrace()
   {
      status := 0;
      save_pos(auto p);
      // look ahead
      if (search('[~ \t]|$','r@')) {
         restore_pos(p);
         return(true);
      }
      if (p_col <= _text_colc(0,'E')) {
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

            case '}':
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
      return(status > 0);
   }

   bool checkKey(_str& key) {
      switch (key) {
      case '{':
         return checkBrace();
      }
      return(false);
   }
};

