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
#import "c.e"
#import "stdprocs.e"
#require "se/autobracket/IAutoBracket.e"
#endregion

namespace se.autobracket;

class DefaultAutoBracket : IAutoBracket {
   protected boolean checkCommentsAndStrings()
   {
      // options to allow auto brackets in string/comment?
      if (_text_colc() == 0) {  // handle multiline comment/string continuation
         flags := _lineflags();
         return (_clex_InComment(flags) || _clex_InString(flags));
      }

      clexflags := _clex_translate(_clex_find(0, 'g'));
      if (clexflags & (COMMENT_CLEXFLAG|STRING_CLEXFLAG)) {
         if (p_col > 1) {
            left(); status := _clex_find(clexflags, 't'); right();
            return(status != 0);
         }
      }
      return(false);
   }

   protected boolean checkParens()
   {
      status := 0;
      if (p_col <= _text_colc(0,'E')) {
         parse p_identifier_chars with auto idchars .;
         // look ahead
         ch := get_text();
         if (ch == ' ' || ch == '\t') {
            save_pos(auto p);
            search('[~ \t]|$','r@');
            ch = get_text();
            if (ch == ')') {
               status = 1;
            }
            restore_pos(p);

         } else if (isalnum(ch) || pos('['idchars']', ch, 1, 'r')) {
            status = 1;
         }
      }
      return(status > 0);
   }

   protected boolean checkBracket()
   {
      status := 0;
      if (p_col <= _text_colc(0,'E')) {
         parse p_identifier_chars with auto idchars .;
         // look ahead
         ch := get_text();
         if (ch == ' ' || ch == '\t') {
            save_pos(auto p);
            search('[~ \t]|$','r@');
            ch = get_text();
            if (ch == ']') {
               status = 1;
            }
            restore_pos(p);

         } else if (isalnum(ch) || pos('['idchars']', ch, 1, 'r')) {
            status = 1;
         }
      }
      return(status > 0);
   }

   protected boolean checkAngleBracket()
   {
      return(false);
   }

   protected boolean checkQuote(_str &key)
   {
      return(false);
   }

   protected boolean checkKey(_str &key)
   {
      return(false);
   }

   void init(_str (&keyarray)[])
   {
   }

   boolean getSettings(_str& key, int opt, _str &close_ch, boolean &insertPad) 
   {
      return(false);
   }

   boolean onKey(_str& key)
   {      
      if (checkCommentsAndStrings()) {
         return(false);
      }
      switch (key) {
      case '(':
         return (!checkParens());

      case '[':
         return (!checkBracket());

      case '<':
         return (!checkAngleBracket());

      case "'":
      case '"':
         return (!checkQuote(key));

      default:
         return (!checkKey(key));
      }
      return(false);
   }
};

