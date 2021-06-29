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

namespace se.lang.xml;
using se.autobracket.DefaultAutoBracket;

class XMLAutoBracket : DefaultAutoBracket {
   protected bool checkAngleBracket() {
      status := 0;
      if (p_col <= _text_colc(0,'E')) {
         parse p_identifier_chars with auto idchars .;
         // look ahead
         ch := get_text();
         if (ch == ' ' || ch == '\t') {
            save_pos(auto p);
            search('[~ \t]|$','r@');
            ch = get_text();
            restore_pos(p);
         }
         switch (ch) {
         case '!':
         case '?':
         case '/':
         case '>':
            status = 1;
            break;

         default:
            if (isalnum(ch) || pos('['idchars']', ch, 1, 'r')) {
               status = 1;
            }
            break;
         }
      }
      return(status > 0);
   }

   protected bool checkQuote(_str &key)
   {
      status := 0;
      if (p_col <= _text_colc(0,'E')) {
         save_pos(auto p);
         _end_line();
         if (_clex_find(0, 'g') == CFG_STRING) {
            status = 1;
         }
         if (!status) {
            // look ahead
            restore_pos(p);
            search('[~ \t]|$','r@');
            ch := get_text();
            switch (ch) {
            case '"':
            case "'": // awkward...
               status = 1;
               break;
            }
         }
         restore_pos(p);
      }
      return(status > 0);
   }
};

