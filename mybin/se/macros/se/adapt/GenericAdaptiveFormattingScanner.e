////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45436 $
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
#import "c.e" 
#import "markfilt.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "pmatch.e"
#import "math.e"
#import "main.e"
#require "se/adapt/AdaptiveFormattingScannerBase.e"
#endregion Imports

#define AD_DEBUG_CPPSCAN 0

int def_max_adaptive_format_lines=4000;

namespace se.adapt;  


/*
   BE style
     try,if,while,for,   foreach (C#)

   Pad Parens,no space before paren
     if,while,for,switch  foreach (C#)

   indent case from switch
     switch

   setSwitch('switch','case','default');
   setParenStyle('if|while|for|switch');
   setBeginEndStyle('try|if|while|for');
     

*/

/** 
 * This class is a Generic Adaptive Formatting scanner.  It 
 * handles generic indent, some common C++ formatting, and 
 * keyword casing.
 */ 
class GenericAdaptiveFormattingScanner : se.adapt.AdaptiveFormattingScannerBase {

   // these assist in making the scanner specific to whatever we need 
   // to find - often the syntax differs when the algorithm to determine 
   // the setting is the same

   // RegEx to search for when determining begin/end style
   private _str m_parenStyleRE= '';

   // RegEx to search for when determining begin/end style
   private _str m_beginEndStyleRE= '';

   // Regex to search for beginning of switch.  For C++, this is "switch"
   protected _str m_switchRE = '';
   // RegEx to search for case or default of switch.  For C++, this is "case|default"
   protected _str m_caseRE = '';

   // Used when displaying the _adaptive_format_results dialog.  
   // Displays alternate begin/end styles.
   protected _str m_beStyles[];
   /** 
    * Only calculate indent change if the previous line contains 
    * these characters. 
    */
   protected _str m_indentRequiresPrevChars='';

   // we will only count the indent value if the current line
   // starts in a column greater than this value
   protected int m_indentMinCol=9;

   /** 
    * Sets which settings are available to be inferred for this 
    * extension.  Note that indent settings are automatically ORed 
    * in. 
    * 
    * @param available        available settings (see 
    *                         AdaptiveFormattingFlags)
    */
   GenericAdaptiveFormattingScanner(int available = 0,_str extension = '') 
   {
      AdaptiveFormattingScannerBase(available, extension);
   }

#region Specialization settings

   /** 
    * Creates the search string based on what settings are
    * available for this scanner and what specialization settings
    * have been set.
    */
   private _str createSearchString(int flags)
   {
      _str ss = '';
      if ((flags & AFF_BEGIN_END_STYLE) &&  m_beginEndStyleRE:!='') ss = m_beginEndStyleRE'|';
      if ((flags & AFF_INDENT_CASE) && m_switchRE:!='') ss = ss :+ m_switchRE'|';
      if ((flags & (AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN)) && m_parenStyleRE:!='') ss = ss :+ m_parenStyleRE;

      if (last_char(ss) == '|') ss = substr(ss, 1, ss._length() - 1);

      return ss;
   }
   /**
    * Only calculate indent change if the previous line contains
    * these characters.
    * 
    * @param s
    */
   public void setIndentRequiresPrevChars(_str s) {
      m_indentRequiresPrevChars=s;
   }

   /**
    * Only calculate indent values (indent, tabs vs. spaces) if the
    * line starts in a column greater than this amount.
    *
    * @param n
    */
   public void setIndentMinColumn(int n)
   {
      m_indentMinCol = n;
   }
   /** 
    * Sets the switch and case settings for scanning for indent 
    * case from switch.  Can specify a regular expression if 
    * feeling fancy. 
    * 
    * @param s          switch search term SlickEdit regular 
    *                   expression. C++ uses "switch"
    * @param c          case search term SlickEdit regular 
    *                   expression. C++ uses "case|default"
    */
   public void setSwitch(_str s, _str c)
   {
      if (s!='') m_available|=AFF_INDENT_CASE;
      m_switchRE = s;
      m_caseRE = c;
   }
   /**
    * Sets the begin/end style regex.  For C++, this is 
    * "try|if|while|for". 
    * 
    * @param begineEndStyleRE
    */
   public void setBeginEndStyle(_str beginEndStyleRE)
   {
      if (beginEndStyleRE!='') m_available|=AFF_BEGIN_END_STYLE;
      m_beginEndStyleRE=beginEndStyleRE;
   }
   /**
    * Sets the begin/end style regex.  For C++, this is 
    * "if|while|for|switch"
    * 
    * @param begineEndStyleRE
    */
   public void setParenStyle(_str parenStyleRE)
   {
      if (parenStyleRE!='' && (m_available & (AFF_NO_SPACE_BEFORE_PAREN|AFF_PAD_PARENS)) == 0) {
         m_available|=AFF_NO_SPACE_BEFORE_PAREN|AFF_PAD_PARENS;
      }
      m_parenStyleRE=parenStyleRE;
   }

   /** 
    * Sets the begin/end style strings used for displaying results 
    * to user. 
    * 
    * @param beStyle    array of labels used with begin/end style
    */
   public void setBEStyles(_str beStyle[])
   {
      m_beStyles = beStyle;
   }

#endregion Specialization settings

   /*
      These methods examine specific examples of settings we're scanning for.  
      Can override these methods for special cases and the scan() will pick up 
      the child method.
   */
#region Examine methods

   /**
    * Examines a specific example of a switch statement.  Adds
    * tallies of cases indented and cases not indented to main
    * tallies table.
    */
   protected void examineIndentCaseFromSwitch(_str idChars,_str posOptions)
   {
      int orig_col=p_col;
      int orig_line=p_line;
      first_non_blank();
      int beginCol=p_col;
      p_col=orig_col;
      _clex_skip_blanks();
      if (get_text():!='(') {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      int status=find_matching_paren(true);
      if (status) {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      right();
      int beginLine=p_line;
      _clex_skip_blanks('');
      if (get_text():!='{') {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      right();
      _clex_skip_blanks('');
      _str ch=get_text();
      if (pos('['idChars']',ch,1,'r')) {
         int caseCol=p_col;
         status=search('['idChars']#','hr@');
         if (!status) {
            _str match=get_match_text('');
            if (pos(m_caseRE,match,1,posOptions)) {
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

   /**
    * Examines a set of parens for paren-related settings.  Updates
    * tallies table as necessary.
    */
   protected void examineParen()
   {
      int orig_col=p_col;
      int orig_line=p_line;
      first_non_blank();
      int beginCol=p_col;
      p_col=orig_col;
      _clex_skip_blanks();
      if (p_LangId=='tcl') {
         if (get_text():!='{') {
            p_line=orig_line;p_col=orig_col;
            return;
         }
      } else if (get_text():!='(') {
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
      if (p_LangId=='tcl') {
         p_line=orig_line;p_col=orig_col;
         return;
      }
      right();
      ch=get_text();
      if (ch:==' ' || ch:=="\t") {
         ++m_tally_Pad_Parens;
      } else if (ch:!="\r" && ch:!="\n") {
         ++m_tally_No_Pad_Parens;
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
      int orig_col=p_col;
      int orig_line=p_line;
      first_non_blank();
      int beginCol=p_col;
      p_col=orig_col;
      _clex_skip_blanks();
      if (get_text():!='(') {
         p_line=orig_line;p_col=orig_col;
         return(0);
      }
      int status=find_matching_paren(true);
      if (status) {
         p_line=orig_line;p_col=orig_col;
         return(0);
      }
      right();
      int beginLine=p_line;
      _clex_skip_blanks('');
      if (get_text():!='{') {
         p_line=orig_line;p_col=orig_col;
         return(0);
      }
      int ret=0;
      boolean isBraceStyle1=p_line==beginLine;
      if (isBraceStyle1) {              // on same line - brace style 1
         ++m_tally_BEStyle1;
         ret = 1;
      } else if (beginCol == p_col) {         // different line, same column - brace style 2
         ++m_tally_BEStyle2;
         ret = 1;
      } else if (p_col > beginCol) {
         ++m_tally_BEStyle3;
         ret = 1;
      } // else we have no idea what this is, but it's probably ugly
      p_line=orig_line;p_col=orig_col;
      return ret;
   }

#endregion Examine methods

   protected _str makeCompleRE(boolean doIndent,_str indentStr,_str moreRE) {
      if (doIndent) {
         if (moreRE=='') {
            return('^((~('indentStr'[^ \t])))');
         }
         return('^((~('indentStr'[^ \t]))|[ \t]*('moreRE'))');
      }
      return('^[ \t]*('moreRE')');
   }

   private void examineIndent(_str &prevLine,int &prevPos,boolean hitPrevChar) {
      // find our current line information
      boolean spaces=get_text():!="\t";
      int curPos = pos('[~ ]', _expand_tabsc(), 1, 'r');
      if (curPos==0 ||  // This is blank line 
          // This will skip python comments
          (curPos && _expand_tabsc(curPos,1,'S')=='#')
          ) {// or is a preprocessing line in column 1
         return;  
      } else {    // check for the first character being a comment - we don't want to count it
         int physical_col=_text_colc(p_col,'P');
         p_col=_text_colc(curPos,'I');
         if (_clex_find(COMMENT_CLEXFLAG, 'T')) return;
         p_col = physical_col;
      }
      
      int curIndent = curPos - prevPos;
#if 0
      if (curIndent>=2 && curIndent!=3) {
         messageNwait('curIndent='curIndent);
      }
#endif
      _str line=_expand_tabsc(1,curPos-1,'S');
      /*
           To handle open source code like the Java source
           which has syntaxIndent=4 and tabs 8, count the occurrences
           of 
           curIndent=0 && (length(expand_tabs(line)) % 4)==0) {
             prevLine
             void foo() {
                  if () {
             <tab>x=1;
             <tab>    if() {
             <tab><tab>x=2;
             <tab>    }
                  }

      */
      /*if (p_line>=710 && p_line<=720) {
         messageNwait('hitPrevChar='hitPrevChar' curIndent='curIndent' %4='((length(expand_tabs(line)) % 4)==0)' !='(prevLine:!=line));
      } */
      boolean lineDiv4=(length(expand_tabs(line)) % 4)==0;
      if (/*hitPrevChar && */curIndent==0 && lineDiv4 && prevLine:!=line) {
         //IF previous line ends in 4 spaces
         if (length(prevLine)>=4 && substr(prevLine,length(prevLine)-3):=='    ' &&
             line:==substr(prevLine,1,length(prevLine)-4):+"\t") {
            ++m_tally_Probably_Indent4_Tabs8;
            ++m_tally_Indent4_Tabs8;
            //IF previous line is all tabs and next line adds 4 spaces
         } else if (!pos('[^\t]',prevLine,1,'r') && length(prevLine) &&
                    line:==prevLine:+'    '
                   ) {
            ++m_tally_Probably_Indent4_Tabs8;
            ++m_tally_Indent4_Tabs8;
         } else if (length(line)>=4 && substr(line,length(line)-3):=='    ' &&
                    prevLine:==substr(line,1,length(line)-4):+"\t") {
            //++m_tally_Probably_Indent4_Tabs8;
            //IF line is all tabs and prev line adds 4 spaces
         } else if (!pos('[^\t]',line,1,'r') && length(line) &&
                    prevLine:==line:+'    '
                   ) {
            //++m_tally_Probably_Indent4_Tabs8;
         } else if (length(prevLine)>0 && length(line)>0) {
            ++m_tally_Probably_Not_Indent4_Tabs8;
#if AD_DEBUG_CPPSCAN
            messageNwait('m_tally_Probably_Not_Indent4_Tabs8');
#endif
         }
      }
      // IF we indented 2 or more spaces
      if (hitPrevChar && curIndent>=2) {
         //say('p_line='p_line' curPos='curPos);
         // IF the indent of this line is divisible by 4 AND this line has tabs
         if (lineDiv4 && !spaces) {
            ++m_tally_Probably_Not_Indent4_Tabs8;
         }
#if AD_DEBUG_CPPSCAN
         messageNwait('curPos='curPos' prevPos='prevPos' curIndent='curIndent' divby4='(((length(line)) % 4)==0)' len='length(line));
#endif
         if (curPos>=m_indentMinCol) {
            if (spaces) {
               ++m_tally_Indent_Spaces;
            } else {
               ++m_tally_Indent_Tabs;
            }
         }
#if 0
         // Could calculate separate counts so files with a lot of
         // single indents will work better.
         if (spaces) {
            ++m_tally_Indent_Spaces;
         } else {
            ++m_tally_Indent_Tabs;
         }
         if (curPos>=9) {
            if (spaces) {
               ++m_tally_Indent4_Tabs8_Spaces;
            } else {
               ++m_tally_Indent4_Tabs8;
            }
         }
#endif
         if (m_tallies._indexin('Indent = 'curIndent)) {
            m_tallies:['Indent = 'curIndent]++;
         } else {
            m_tallies:['Indent = 'curIndent] = 1;
         }
      }
      if (hitPrevChar || curIndent<2) {
         prevPos=curPos;prevLine=line;
      }
   }
   /** 
    * Scans the buffer for examples of settings that we can infer 
    * from. 
    * 
    * @param flags      flags to search for
    * @param cap        maximum number of settings to find
    */
   protected void scan(int orig_flags, int cap = MAX_SCAN)
   {
      int flags=orig_flags;
      if (cap==0) cap=MAXINT;
      initTallies();

      save_pos(auto p);

      // check for embedded language
      embedLex := p_EmbeddedLexerName;

      _str oldTabs=p_tabs;
      p_tabs='+4';
      int curPos, curIndent;
      int indentWithTabs = 0, indentWithSpaces = 0;
      _str prevLine='';
      int prevPos=1;
      int probablyIndent4Tabs8=0;
      int probablyNotIndent4Tabs8=0;
      boolean doIndent=(flags & (AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS))!=0;

      _str searchString=createSearchString(flags);
      _str completeRE=searchString;
      _str searchOptions='hR@xcs';
      _str posOptions='R';
      if (!p_EmbeddedCaseSensitive) {
         searchOptions='I'searchOptions;
         posOptions='I'posOptions;
      }
      _str idChars=_clex_identifier_chars();

      completeRE=makeCompleRE(doIndent,prevLine,searchString);
      top();
      findNextEmbeddedRegion(embedLex);
      int be_count=0;
      typeless pt='';
      int col=0;

      flags=orig_flags & (AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS|
                          AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN|
                          AFF_BEGIN_END_STYLE|
                          AFF_INDENT_CASE);
      while (flags) {
         if (p_line>=def_max_adaptive_format_lines) {
            break;
         }
         // Watch for infinite loop
         int status=search(completeRE,searchOptions);
         if (!status && pt==point() && col==p_col) {
            status=repeat_search();
            if (!status && pt==point() && col==p_col) {
               break;
            }
         }
         pt=point();col=p_col;
         if (status) break;
         if (embedLex != p_EmbeddedLexerName) {
            if (findNextEmbeddedRegion(embedLex)) break;
            continue;
         }

         int len=match_length();

         // Do we need to study the indent?
         _str match;
         if (len==0) {
            int status2=0;
            boolean hitPrevChar=true;
            auto line3=p_line;
            auto col3=p_col;
            _str ch;
            if (length(m_indentRequiresPrevChars)) {
               up();_end_line();
               //--p_col;
               status2=_clex_skip_blanks("-q");
               ch=get_text();
               hitPrevChar=pos(ch,m_indentRequiresPrevChars)!=0;
               p_line=line3;
               p_col=col3;
               /*if (p_line>=700 && p_line<=720 && pos('qapplication_win.cpp',p_buf_name)) {
                  //messageNwait('hitPrevChar='hitPrevChar' m_indentRequiresPrevChars='m_indentRequiresPrevChars' ch='ch);
               } */
            }
            if (!status2) {
               //int total=m_tally_Indent_Tabs+m_tally_Indent_Spaces+m_tally_Indent4_Tabs8;
               examineIndent(prevLine,prevPos,hitPrevChar);
               /*int total2=m_tally_Indent_Tabs+m_tally_Indent_Spaces+m_tally_Indent4_Tabs8;
               if (total!=total2 /*&& p_line>=714*/ && p_line<=720 && pos('qapplication_win.cpp',p_buf_name)) {
                  //messageNwait('p_line='p_line' Indent4_Tabs8='m_tally_Indent4_Tabs8' Indent_Tabs='m_tally_Indent_Tabs' indent_spaces='m_tally_Indent_Spaces);
               } */
               if (m_tally_Indent_Spaces + m_tally_Indent_Tabs >=cap) {
                  doIndent=false;
                  flags&= ~(AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS);
                  if (searchString=='') break;
               }
               completeRE=makeCompleRE(doIndent,prevLine,searchString);
               if (searchString:=='') continue;
            }
            get_line(auto line);
            _str re='^[ \t]*('searchString')';
            if (!pos(re,line,1,'r')) continue;
            status=search(re,'hr@');
            if (status) continue;
            len=match_length();
         }
         match=get_match_text('');
         int physical_col=_text_colc(p_col,'P');
         p_col=_text_colc(physical_col+len,'I');
         _str ch=get_text();
         if ( !pos('[^'idChars']',ch,1,'r')) {
            continue;
         }

         if ((flags & (AFF_BEGIN_END_STYLE)) && 
             pos(m_beginEndStyleRE,match,1,posOptions)) {
            be_count+=examineBeginEndStyle();
            if (be_count>=cap) {
               flags&= ~AFF_BEGIN_END_STYLE;
               searchString=createSearchString(flags);
               if (!doIndent) break;
               completeRE=makeCompleRE(doIndent,prevLine,searchString);
            }
         }
         if ((flags & (AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN)) && 
              pos(m_parenStyleRE,match,1,posOptions)) {
            examineParen();
            if (m_tally_Space_Before_Paren+m_tally_No_Space_Before_Paren>=cap &&
               m_tally_Pad_Parens+m_tally_No_Pad_Parens>=cap) {
               flags&= ~(AFF_PAD_PARENS|AFF_NO_SPACE_BEFORE_PAREN);
               searchString=createSearchString(flags);
               if (!doIndent) break;
               completeRE=makeCompleRE(doIndent,prevLine,searchString);
            }
         }
         if ((flags & (AFF_INDENT_CASE)) && pos(m_switchRE,match,1,posOptions)) {
            examineIndentCaseFromSwitch(idChars,posOptions);
            if (m_tally_Indent_Case+m_tally_No_Indent_Case>=cap) {
                flags&= ~(AFF_INDENT_CASE);
                searchString=createSearchString(flags);
                if (!doIndent) break;
                completeRE=makeCompleRE(doIndent,prevLine,searchString);
            }
         }
      }
      flags=orig_flags & (AFF_KEYWORD_CASING);
      boolean doCasing=flags && (m_available & AFF_KEYWORD_CASING);
      if (doCasing) {
         top();
         findNextEmbeddedRegion(embedLex);
         int kcount=0;
         int clexflags=0;
         while (flags) {
            int status=_clex_find(KEYWORD_CLEXFLAG);
            if (status) break;
            if (embedLex != p_EmbeddedLexerName) {
               if (findNextEmbeddedRegion(embedLex)) break;
               continue;
            }
            _str word=cur_identifier(auto junk_col);
            kcount += examineKeywordCasing(word);
            p_col+=length(word);
            if (length(word) <= 0) p_col++; // keep moving even if we don't find ID
            if (cap && kcount >= cap) flags = flags & ~AFF_KEYWORD_CASING;
         }
      }
      restore_pos(p);
      p_tabs=oldTabs;
   }


   /** 
    * Runs a manual scan of the current buffer and then displays
    * the results.  Scans for all settings supported by this
    * scanner.
    * 
    */
   public void manualAdaptiveFormattingScan()
   {
      scan(m_available);

      // send info to the form for display
      show("_adaptive_format_results", &this, m_available, m_beStyles);
   }
}
