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
#import "stdcmds.e"
#import "c.e"
#import "stdprocs.e"
#import "main.e"
#require "se/adapt/GenericAdaptiveFormattingScanner.e"
#endregion Imports

namespace se.lang.tcl;  

/** 
 * This class handles adaptive formatting specifically for
 * TCL files.
 * 
 */
class TCLAdaptiveFormattingScanner : se.adapt.GenericAdaptiveFormattingScanner {

   TCLAdaptiveFormattingScanner(_str extension = '') 
   {
      GenericAdaptiveFormattingScanner( AFF_NO_SPACE_BEFORE_PAREN, extension);
      setParenStyle('if|while|for|switch|foreach');
   }
   /**
    * Examines a set of parens for paren-related settings.  Updates
    * tallies table as necessary.
    */
   protected void examineParen()
   {
      orig_col := p_col;
      orig_line := p_line;
      _first_non_blank();
      beginCol := p_col;
      p_col=orig_col;
      _clex_skip_blanks();
      if (get_text():!='{') {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      _str ch;
      if (p_col!=1) {
         left();
         ch=get_text();
         if (ch:==' ' || ch:=="\t") {
            ++m_tally_Space_Before_Paren;
         } else {
            ++m_tally_No_Space_Before_Paren;
         }
         right();
      }
      p_line=orig_line;p_col=orig_col;
   }

}
