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

namespace se.lang.pas;  

/** 
 * This class handles adaptive formatting specifically for
 * Pascal files.  Pascal has a special case on begin/end style
 * that cannot be covered generically.
 * 
 */
class PascalAdaptiveFormattingScanner : se.adapt.GenericAdaptiveFormattingScanner {

   PascalAdaptiveFormattingScanner(_str extension = '') 
   {
      GenericAdaptiveFormattingScanner(AFF_BEGIN_END_STYLE | AFF_INDENT_CASE | AFF_KEYWORD_CASING, extension);
      setSwitch('case','');
      setBeginEndStyle('if|while|for');
      _str bes[];
      bes[0] = "if (expr) then begin\n   <statements>\nend;";
      bes[1] = "if (expr) then \n   begin\n   <statements>\n   end;";
      setBEStyles(bes);
   }
   protected void examineIndentCaseFromSwitch(_str idChars,_str posOptions)
   {
      orig_col := p_col;
      orig_line := p_line;
      _first_non_blank();
      beginCol := p_col;
      // Look for "of" keyword at end of line
      status := search('of|$','ri@ckw=[a-zA-Z]');
      if (status || match_length()==0) {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      p_col+=2;
      _clex_skip_blanks();
      caseCol := p_col;
      _str line;
      get_line(line);
      if (pos(':',line,1,posOptions)) {
         if (caseCol>beginCol) {
            ++m_tally_Indent_Case;
            //messageNwait('m_tally_Indent_Case='m_tally_Indent_Case);
         } else {
            ++m_tally_No_Indent_Case;
            //messageNwait('m_tally_No_Indent_Case='m_tally_No_Indent_Case);
         }
      } else {
         ch := get_text();
         //messageNwait('status='status' len='match_length()' ch='ch);
         if (pos('['idChars']',ch,1,'r')) {
            status=search('['idChars']#','r@');
            if (!status) {
               match := get_match_text('');
               if (pos('else',match,1,posOptions)) {
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
      }
      p_line=orig_line;p_col=orig_col;
   }

 
   /**
    * Examines the begin/end style.  Updates tallies as necessary.
    * 
    * @return int          1 if we were able to determine
    *         something, 0 otherwise
    */
   protected int examineBeginEndStyle()
   {
      orig_col := p_col;
      orig_line := p_line;
      _end_line();
      _clex_skip_blanks('-');
      idChars := stranslate(p_identifier_chars,'',' ');
      ch := get_text();
      if (!pos('['idChars']',ch,1,'r')) {
         p_line=orig_line;p_col=orig_col;
         return(0);
      }
      status := search('['idChars']#','-r@');
      if (status) {
         p_line=orig_line;p_col=orig_col;
         return(0);
      }
      match := get_match_text('');
      ret := 0;
      if (strieq(match,'begin')) {
         ret = 1;
         ++m_tally_BEStyle1;
      } else if (strieq(match,'do') || strieq(match,'then')) {
         ++m_tally_BEStyle2;
         ret = 1;
      }
      p_line=orig_line;p_col=orig_col;
      return ret;
   }
}
