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
#import "stdcmds.e"
#import "pmatch.e"
#require "se/lang/cpp/CPPAutoBracket.e"
#endregion

namespace se.lang.objectivec;
using se.lang.cpp.CPPAutoBracket;

class ObjectiveCAutoBracket : CPPAutoBracket {
   // test if bracket [] auto-close preceding idchar allowed
   protected bool testBracketOp(_str ch)
   {
      status := false;
      if (ch == ' ' || ch == '\t') {
         // look behind
         _clex_skip_blanks('-m');
         ch = get_text();
         if (ch == ':' || ch == '[') {
            status = true;
         }
      }
      return(status);
   }

   // test for specific concating operator for auto-quoting
   protected bool testStringOp(_str ch, int dir)
   {
      status := false;
      switch (ch) {
      case '@':   // NSString literal
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
      return(status);
   }
};

