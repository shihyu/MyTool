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
#require "se/lang/generic/GenericAutoBracket.e"
#endregion

namespace se.lang.markdown;
using se.lang.generic.GenericAutoBracket;

class MarkdownAutoBracket : GenericAutoBracket {
   void init(_str (&keyarray)[]) {
   }

   boolean getSettings(_str& key, int opts, _str &close_ch, boolean &insertPad) {
      return(false);
   }

   protected boolean checkAngleBracket() {
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

   boolean checkKey(_str& key) {
      return(false);
   }
};

