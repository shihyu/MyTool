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

namespace se.lang.dbase;

/** 
 * This class handles adaptive formatting specifically for
 * dBase files.  dBase has a special case on switch 
 * that cannot be covered generically. 
 * 
 */
class DBaseAdaptiveFormattingScanner : se.adapt.GenericAdaptiveFormattingScanner {

   DBaseAdaptiveFormattingScanner(_str extension = '') 
   {
      GenericAdaptiveFormattingScanner( AFF_INDENT_CASE | AFF_KEYWORD_CASING, extension);
      setSwitch('do case','case|otherwise');
   }
   protected void examineIndentCaseFromSwitch(_str idChars,_str posOptions)
   {
      orig_col := p_col;
      orig_line := p_line;
      _first_non_blank();
      beginCol := p_col;
      _end_line();
      _clex_skip_blanks();
      get_line(auto line);
      _clex_skip_blanks('');
      ch := get_text();
      if (pos('['idChars']',ch,1,'r')) {
         caseCol := p_col;
         status := search('['idChars']#','hr@');
         if (!status) {
            match := get_match_text('');
            if (pos(m_caseRE,match,1,posOptions) && !pos('endcase',match,1,posOptions)) {
               if (caseCol>beginCol) {
                  ++m_tally_Indent_Case;
                  //messageNwait('m_tally_Indent_Case='m_tally_Indent_Case);
               } else {
                  ++m_tally_No_Indent_Case;
                  //messageNwait('m_tally_No_Indent_Case='m_tally_No_Indent_Case);
               }
            }
         }
      }
      p_line=orig_line;p_col=orig_col;
   }
}
