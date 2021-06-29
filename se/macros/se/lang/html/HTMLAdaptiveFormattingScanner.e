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
#import "stdcmds.e"
#import "stdprocs.e"
#import "main.e"
#import "sellist2.e"
#require "se/adapt/GenericAdaptiveFormattingScanner.e"
#require "se/adapt/AdaptiveFormattingScannerBase.e"
#endregion Imports

#define AD_DEBUG_HTMLSCAN 0
namespace se.lang.html;  

/** 
 * This class acts as the scanner for adaptive formatting
 * settings for HTML and derived languages.  This class makes 
 * use of the tagging engine to work. 
 * 
 */
class HTMLAdaptiveFormattingScanner : se.adapt.AdaptiveFormattingScannerBase {
 
   protected _str m_tag = '<[~/]';
   protected _str m_equals = '=';
   protected _str m_hexValue = '=[ \t]*("|''|)\#[a-fA-F]:6';

   HTMLAdaptiveFormattingScanner(int available = AFF_TAG_CASING | AFF_ATTRIBUTE_CASING | 
                                 AFF_VALUE_CASING | AFF_HEX_VALUE_CASING, _str lang = '')
   { 
      AdaptiveFormattingScannerBase(available, lang);
   } 

   private _str createSearchString(int flags)
   {
      ss := "";
      if (flags & AFF_TAG_CASING) {
         ss = '('m_tag')|';
      }
      if (flags & AFF_HEX_VALUE_CASING) {
         ss :+= '('m_hexValue')|';
      }
      if (flags & (AFF_ATTRIBUTE_CASING | AFF_VALUE_CASING)) {
         ss :+= '('m_equals')|';
      }
      if (_last_char(ss) == '|') ss = substr(ss, 1, ss._length() - 1);
      return(ss);
   }

   protected void examineTags(int cap,int orig_flags,_str embedLex) {
      int flags=orig_flags & (AFF_TAG_CASING|AFF_ATTRIBUTE_CASING|AFF_VALUE_CASING|AFF_HEX_VALUE_CASING);
      doCasing := flags && (m_available & (AFF_TAG_CASING|AFF_ATTRIBUTE_CASING|AFF_VALUE_CASING|AFF_HEX_VALUE_CASING));
      if (!doCasing) return;
      _str searchString= createSearchString(flags);
      //_message_box('start searchString='searchString);
      _str tag=m_tag;
      _str equals=m_equals;
      _str hexValue=m_hexValue;

      _str idChars=_clex_identifier_chars();
      searchOptions := "hR@xcs";
      posOptions := 'R';
      if (!p_EmbeddedCaseSensitive) {
         searchOptions='I'searchOptions;
         posOptions='I'posOptions;
      }

      tcount := 0;
      acount := 0;
      vcount := 0;
      hcount := 0;
      top();
      findNextEmbeddedRegion(embedLex);
      status := search(searchString,'r@xcs');
      int col;
      typeless prev_pt='';
      prev_col := 0;
      while (flags && !status) {
         //messageNwait('start= pline='p_line' col='p_col);
         status=search(searchString,searchOptions);
         if (!status && prev_pt==point() && prev_col==p_col) {
            status=repeat_search();
         }
         if (status) break;
         prev_pt=point();prev_col=p_col;
         if (embedLex != p_EmbeddedLexerName) {
            if (findNextEmbeddedRegion(embedLex)) break;
            status=repeat_search();
            continue;
         }
         match := get_match_text();
         //messageNwait('match='match' pline='p_line' col='p_col);
         if (flags & AFF_TAG_CASING) {
            if (pos(tag, match, 1, 'R') == 1) {
               right();
               tcount += examineKeywordCasing(cur_identifier(col),'T');
               if (cap && tcount >= cap) {
                  flags = flags & ~AFF_TAG_CASING;
                  searchString= createSearchString(flags);
               }
            }
         }

         // attributes and values
         if (flags & (AFF_ATTRIBUTE_CASING | AFF_VALUE_CASING | AFF_HEX_VALUE_CASING)) {
            if (pos(equals, match, 1, 'R') == 1) {
               // Require a '<' at beginning of line
               get_line(auto line);
               tPos := pos('[~ \t]', line, 1, 'r');
               if (tPos && substr(line,tPos,1):=='<') {
                  orig_line := p_line;
                  orig_col := p_col;
                  left();_clex_skip_blanks('-');
                  if (p_line==orig_line && pos('['idChars']',get_text(),1,posOptions)) {
                     _str attrName=cur_identifier(col);
                     // attribute
                     acount += examineKeywordCasing(attrName,'A');
                     if ((flags & AFF_ATTRIBUTE_CASING) && 
                         acount >= cap) {
                        flags = flags & ~AFF_ATTRIBUTE_CASING;
                        searchString= createSearchString(flags);
                     }
                     p_line=orig_line;p_col=orig_col;
                     right();
                     if (get_text()=='') {
                        right();
                     }
                     ch := get_text();
                     if ((flags & AFF_VALUE_CASING) && 
                         ch!='"' && ch!="'") {
                        // value
                        vcount += examineKeywordCasing(cur_identifier(col),'V');
                        if (vcount >= cap) {
                           flags = flags & ~AFF_VALUE_CASING;
                           searchString= createSearchString(flags);
                        }
                     }
                     //messageNwait('hexValue='hexValue' match='match' attrName='attrName);
                     if ((flags & AFF_HEX_VALUE_CASING) && 
                         pos(hexValue, match, 1, 'R') == 1) {
                        //messageNwait('attrName='attrName);
                        if( strieq(attrName,"alink") ||
                            strieq(attrName,"bgcolor") ||
                            strieq(attrName,"bordercolor") ||
                            strieq(attrName,"color") ||
                            strieq(attrName,"link") ||
                            strieq(attrName,"text") ||
                            strieq(attrName,"vlink") ) {
                           //_message_box('match='match' col='p_col);
                           parse match with '#' auto rest;
                           hcount += examineKeywordCasing(rest,'H');
                           if (hcount >= cap) {
                              flags = flags & ~AFF_HEX_VALUE_CASING;
                              searchString= createSearchString(flags);
                           }
                        }
                     }
                  }
                  p_line=orig_line;p_col=orig_col;
               }
            }
         }
      }
      //_message_box('done');
   }

   private void examineIndent(_str &prevLine,int &prevPos) {
      // find our current line information
      spaces := get_text():!="\t";
      int curPos = pos('[~ ]', _expand_tabsc(), 1, 'r');
      if (curPos==0) {
         prevPos=curPos=1;prevLine='';
#if AD_DEBUG_HTMLSCAN
         messageNwait('blank line');
#endif
         return;
      }
      _str line=_expand_tabsc(1,curPos-1,'S');
      // IF line does not start with <, skip it
      if ( _expand_tabsc(curPos,1,'S')!='<') {
         prevPos=curPos;prevLine=line;
#if AD_DEBUG_HTMLSCAN
         messageNwait('no <');
#endif
         return;  
      }
      // Previous line must start with <
      _str tempPrevLine;
      up();get_line(tempPrevLine);
      down();
      tPos := pos('[~ \t]', tempPrevLine, 1, 'r');
      if (!tPos || substr(tempPrevLine,tPos,1)!='<') {
         // Previous line does not start with <, so skip this one
         prevPos=curPos;prevLine=line;
#if AD_DEBUG_HTMLSCAN
         messageNwait('prev no <');
#endif
         return;  
      }
      int curIndent = curPos - prevPos;
#if 0
      if (curIndent>=2 && curIndent!=3) {
         messageNwait('curIndent='curIndent);
      }
#endif
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
      if (curIndent==0 && (length(expand_tabs(line)) % 4)==0 && prevLine:!=line) {
         //IF previous line ends in 4 spaces
         if (length(prevLine)>=4 && substr(prevLine,length(prevLine)-3):=='    ' &&
             line:==substr(prevLine,1,length(prevLine)-4):+"\t") {
            ++m_tally_Probably_Indent4_Tabs8;
            //IF previous line is all tabs and next line adds 4 spaces
         } else if (!pos('[^\t]',prevLine,1,'r') && length(prevLine) &&
                    line:==prevLine:+'    '
                   ) {
            ++m_tally_Probably_Indent4_Tabs8;
         } else if (length(line)>=4 && substr(line,length(line)-3):=='    ' &&
                    prevLine:==substr(line,1,length(line)-4):+"\t") {
            ++m_tally_Probably_Indent4_Tabs8;
            //IF line is all tabs and prev line adds 4 spaces
         } else if (!pos('[^\t]',line,1,'r') && length(line) &&
                    prevLine:==line:+'    '
                   ) {
            ++m_tally_Probably_Indent4_Tabs8;
         } else if (length(prevLine)>0 && length(line)>0) {
            ++m_tally_Probably_Not_Indent4_Tabs8;
#if AD_DEBUG_HTMLSCAN
            messageNwait('m_tally_Probably_Not_Indent4_Tabs8');
#endif
         }

      }
      // IF we indented 2 or more spaces
      if (curIndent>=2) {
#if AD_DEBUG_HTMLSCAN
         messageNwait('curPos='curPos' prevPos='prevPos' curIndent='curIndent' divby4='(((length(line)) % 4)==0)' len='length(line));
#endif
         if (spaces) {
            ++m_tally_Indent_Spaces;
         } else {
            ++m_tally_Indent_Tabs;
         }
         if (m_tallies._indexin('Indent = 'curIndent)) {
            m_tallies:['Indent = 'curIndent]++;
         } else {
            m_tallies:['Indent = 'curIndent] = 1;
         }
      }
      prevPos=curPos;prevLine=line;
   }
   protected _str makeCompleRE(bool doIndent,_str indentStr,_str moreRE) {
      if (doIndent) {
         if (moreRE=='') {
            ///^((~(      [^ \t]))|[ \t]*(if|while|try))/r
            return('^((~('indentStr'[^ \t])))');
         }
         ///^((~(      [^ \t]))|[ \t]*(if|while|try))/r
         return('^((~('indentStr'[^ \t]))|[ \t]*('moreRE'))');
      }
      return('^[ \t]*('moreRE')');
   }

   protected void scanIndent(int flags, int cap,_str embedLex)
   {
      _str oldTabs=p_tabs;
      p_tabs='+4';
      int curPos, curIndent;
      indentWithTabs := indentWithSpaces := 0;
      prevLine := "";
      prevPos := 1;
      probablyIndent4Tabs8 := 0;
      probablyNotIndent4Tabs8 := 0;

      searchString := "";
      searchOptions := "hR@xcs";
      //_str searchOptions='R@';
      posOptions := 'R';
      if (!p_EmbeddedCaseSensitive) {
         searchOptions='I'searchOptions;
         posOptions='I'posOptions;
      }
      idChars := stranslate(p_identifier_chars,'',' ');

      _str completeRE=makeCompleRE(true,prevLine,'');
      top();
      findNextEmbeddedRegion(embedLex);
      be_count := 0;
      typeless pt='';
      col := 0;
      //_message_box('h1 cap='cap);

      flags &= (AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS);
//    say('  search string = 'm_searchString);
      while (flags) {
         if (p_line>=def_max_adaptive_format_lines) break;
         // Watch for infinite loop
         status := search(completeRE,searchOptions);
         if (!status && pt==point() && col==p_col) {
            status=repeat_search();
            if (!status && pt==point() && col==p_col) {
               break;
            }
         }
         pt=point();col=p_col;
         //say('status='status' ln='p_line' col='p_col' completeRE='completeRE' searchString='searchString);
         if (status) break;
         if (embedLex != p_EmbeddedLexerName) {
            if (findNextEmbeddedRegion(embedLex)) break;
            continue;
         }

         // Do we need to study the indent?
         examineIndent(prevLine,prevPos);
         if (m_tally_Indent_Spaces + m_tally_Indent_Tabs >=cap) {
            //say('got here p_line='p_line' n='p_Noflines);
            flags&= ~(AFF_INDENT_WITH_TABS|AFF_SYNTAX_INDENT|AFF_TABS);
            break;
         } else {
            completeRE=makeCompleRE(true,prevLine,'');
         }
         //say('h4 status='status' ln='p_line' col='p_col);
         //say('match='match);

//       say('   looking for embedded name - 'embedLex);
      }

      p_tabs=oldTabs;
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
      //say('new text scan lang='p_LangId);
      //message('buf='p_buf_name);
      initTallies();

      save_pos(auto p);

      // check for embedded language
      embedLex := p_EmbeddedLexerName;

      if (orig_flags& (AFF_SYNTAX_INDENT|AFF_INDENT_WITH_TABS|AFF_TABS)) {
         // Get the indent
         scanIndent(orig_flags,cap,embedLex);
      }
      examineTags(cap,orig_flags,embedLex);
      restore_pos(p);
   }
}
