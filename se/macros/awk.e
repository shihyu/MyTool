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
#include "color.sh"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cutil.e"
#import "notifications.e"
#import "pmatch.e"
#import "se/lang/api/LanguageSettings.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for AWK syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             reserved.
       3             begin/end style.  Begin/end style may be 0,1, or 2
                     as show below.  Add 4 to the begin end style if you
                     want braces inserted when syntax expansion occurs
                     (main and do insert braces anyway).  Typing a begin
                     brace, '{', inserts an end brace when appropriate
                     (unless you unbind the key).  If you want a blank
                     line inserted in between, add 8 to the begin end
                     style.  Default is 4.

                      Style 0
                          if () {
                             ++i;
                          }

                      Style 1
                          if ()
                          {
                             ++i;
                          }

                      Style 2
                          if ()
                            {
                            ++i;
                            }


       4             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
       5             Reserved

       6             Indent CASE from SWITCH.  Default is 0.  Specify
                     1 if you want CASE statements indented from the
                     SWITCH statement. Begin/end style 2 not supported.
*/

static const AWK_LANGUAGE_ID= 'awk';

defeventtab awk_keys;
def  ' '= awk_space;
def  '{'= awk_begin;
def  '}'= awk_endbrace;
def  'ENTER'= awk_enter;

_command void awk_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(AWK_LANGUAGE_ID);
}
_command void awk_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_awk_expand_enter);
}
bool _awk_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _awk_supports_insert_begin_end_immediately() {
   return true;
}
_command void awk_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
         awk_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}
_command void awk_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if ( command_state() || _in_comment() || awk_expand_begin() ) {
      call_root_key('{');
   } else if (_argument=='') {
      _undo('S');
   }

}
_command void awk_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('}');
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      line := "";
      get_line(line);
      if (line=='}') {
         int col=awk_endbrace_col();
         if (col) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

/*

   On entry, the cursor is setting on a } (close brace)

   static void
      main () /* this is a test */ {
   }
   static void main /* this is a test */
     ()
   {
   }

   for (;;) {     for (;;)        for (;;)
                  {                  {
                  }                  }
   }
   style 0        style 1         style 2

   Returns column where end brace should go.
   Returns 0 if this function does not know the column where the
   end brace should go.
*/
int awk_endbrace_col()
{
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   if (p_lexer_name=='') {
      return(0);
   }
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   begin_brace_col := p_col;
   // Check if the first char before open brace is close paren
   int col= find_block_col();
   if (!col) {
      restore_pos(p);
      return(0);
   }
   if (p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3) {
      restore_pos(p);
      return(begin_brace_col);
   }
   restore_pos(p);
   return(col);
}

static int find_block_col()
{
   col := 0;
   word := "";
   --p_col;
   if (_clex_skip_blanks('-')) return(0);
   if (get_text()!=')') {
      if (_clex_find(0,'g')!=CFG_KEYWORD) {
         return(0);
      }
      word=cur_word(col);
      if (word=='do' || word=='else') {
         _first_non_blank();
         return(p_col);
         //return(p_col-length(word)+1);
      }
      return(0);
   }
   int status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) return(0);
   if (p_col==1) return(1);
   --p_col;

   if (_clex_skip_blanks('-')) return(0);
   if (_clex_find(0,'g')!=CFG_KEYWORD) {
      return(0);
   }
   word=cur_word(col);
   if (pos(' 'word' ',' for if while ')) {
      _first_non_blank();
      return(p_col);
      //return(p_col-length(word)+1);
   }
   return(0);
}
   /* Words must be in sorted order */
static const AWK_EXPAND_WORDS= ' else ';

static SYNTAX_EXPANSION_INFO awk_space_words:[] = {
   'begin'      => { "BEGIN" },
   'break'      => { "break" },
   'continue'   => { "continue" },
   'do'         => { "do { ... } while ( ... );" },
   'end'        => { "END" },
   'else'       => { "else" },
   'exit'       => { "exit" },
   'for'        => { "for ( ... ) { ... }" },
   'if'         => { "if ( ... ) { ... }" },
   'printf'     => { "printf(\"" },
   'print'      => { "print" },
   'next'       => { "next" },
   'return'     => { "return" },
   'while'      => { "while ( ... ) { ... }" },
};

_str _skip_pp;

int awk_get_info(int &Noflines,_str &cur_line,_str &first_word,_str &last_word,
                 _str &rest,int &non_blank_col,int & semi,int & prev_semi,
                 bool in_smart_paste=false)
{
   i := j := 0;
   status := 0;
   kwd := "";
   line := "";
   before_brace := "";
   typeless p2;
   typeless junk;
   typeless old_pos;
   save_pos(old_pos);
   first_word='';last_word='';non_blank_col=p_col;
   if (in_smart_paste) {
      for (j=0; ; ++j) {
         get_line(cur_line);
         if ( cur_line!='' && (substr(strip(cur_line),1,1)!='#' || _skip_pp=='')) {
            parse cur_line with line '/*' ;  /* Strip comment on current line. */
            parse line with line '//' ;     /* Strip comment on current line. */
            parse line with before_brace '{' +0 last_word ;
            parse strip(line,'L') with first_word '[({:; \t]','r' +0 rest;
            last_word=strip(last_word);
            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
            if (last_word=='{' && (p_begin_end_style != BES_BEGIN_END_STYLE_3)) {
               save_pos(p2);
               p_col=text_col(_rawText(before_brace));
               _clex_skip_blanks('-');
               status=1;
               if (get_text()==')') {
                  status=_find_matching_paren(def_pmatch_max_diff_ksize);
               }
               if (!status) {
                  status=1;
                  if (p_col==1) {
                     up();_end_line();
                  } else {
                     left();
                  }
                  _clex_skip_blanks('-');
                  if (_clex_find(0,'g')==CFG_KEYWORD) {
                     kwd=cur_word(junk);
                     status=(int) !pos(' 'kwd' ',' if while switch for ');
                  }
               }
               if (status) {
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
                  restore_pos(p2);
               } else {
                  get_line_raw(line);
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
                  /* Use non blank of start of if, do, while, which, or for. */
               }
            } else {
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
            }
            Noflines=j;
            break;
         }
         if ( up() ) {
            restore_pos(old_pos);
            return(1);
         }
         if (j>=100) {
            restore_pos(old_pos);
            return(1);
         }
      }
   } else {
      orig_col := p_col;
      for (j=0;  ; ++j) {
         get_line(cur_line);
         _begin_line();
         i=verify(cur_line,' '\t);
         if ( i ) p_col=text_col(cur_line,i,'I');
         if ( cur_line!='' && (substr(strip(cur_line),1,1)!='#' || _skip_pp=='') && _clex_find(0,'g')!=CFG_COMMENT) {
            parse cur_line with line '/*' ; /* Strip comment on current line. */
            parse line with line '//' ;     /* Strip comment on current line. */
            parse line with before_brace '{' +0 last_word;
            parse strip(line,'L') with first_word '[({:; \t]','r' +0 rest;
            last_word=strip(last_word);
            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
            if (last_word=='{' && !(p_begin_end_style == BES_BEGIN_END_STYLE_3)) {
               save_pos(p2);
               p_col=text_col(_rawText(before_brace));
               _clex_skip_blanks('-');
               status=1;
               if (get_text()==')') {
                  status=_find_matching_paren(def_pmatch_max_diff_ksize);
               }
               if (!status) {
                  status=1;
                  if (p_col==1) {
                     up();_end_line();
                  } else {
                     left();
                  }
                  _clex_skip_blanks('-');
                  if (_clex_find(0,'g')==CFG_KEYWORD) {
                     kwd=cur_word(junk);
                     status=(int) !pos(' 'kwd' ',' if while switch for ');
                  }
               }
               if (status) {
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
                  restore_pos(p2);
               } else {
                  get_line_raw(line);
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
                  /* Use non blank of start of if, do, while, which, or for. */
               }
            } else {
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
            }
            Noflines=j;
            break;
         }
         if ( up() ) {
            restore_pos(old_pos);
            return(1);
         }
         if (j>=100) {
            restore_pos(old_pos);
            return(1);
         }
      }
      if (!j) p_col=orig_col;
   }
   typeless p='';
   if ( j ) {
      p=1;
   }
   semi=(typeless)stat_has_semi(p);
   prev_semi=prev_stat_has_semi();
   restore_pos(old_pos);
   return(0);
}
/* Returns non-zero number if pass through to enter key required */
bool _awk_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
   syntax_indent := p_SyntaxIndent;
   indent_case := (int)p_indent_case_from_switch;
   
   be_style := LanguageSettings.getBeginEndStyle(p_LangId);
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   Noflines := 0;
   typeless cur_line='';
   first_word := "";
   last_word := "";
   rest := "";
   line := "";
   non_blank_col := 0;
   col := 0;
   typeless semi='';
   typeless prev_semi='';
   int status=awk_get_info(Noflines,cur_line,first_word,last_word,rest,
              non_blank_col,semi,prev_semi);
   if (status) return(true);
   status=0;
   style2 := be_style == BES_BEGIN_END_STYLE_2;
   if ( expand && ! Noflines ) {
      if ( first_word=='for' && name_on_key(ENTER):=='nosplit-insert-line' ) {
         if ( name_on_key(ENTER):!='nosplit-insert-line' ) {
            if ( (style2) || semi ) {
               return(true);
            }
            indent_on_enter(syntax_indent);
            return(false);
         }
         /* tab to fields of C for statement */
         int semi1_col=_posCurLine(';',p_col);
         if ( semi1_col>0 && semi1_col>=p_col ) {
            p_col=semi1_col+1;
         } else {
            int semi2_col=_posCurLine(';',semi1_col+1);
            if ( (semi2_col>0) && (semi2_col>=p_col) ) {
               p_col=semi2_col+1;
            } else {
               if ( style2 || semi ) {
                  return(true);
               }
               indent_on_enter(syntax_indent);
            }
         }
      } else if ( (first_word=='case' || first_word=='default')) {
         eol := "";
         if(_will_split_insert_line()) {
            eol=_expand_tabsc(p_col,-1,'s');
            replace_line(_expand_tabsc(1,p_col-1,'s'));
         }
         /* Indent case based on indent of switch. */
         col=_awk_last_switch_col();
         if ( col && eol:=='') {
            if ((indent_case && indent_case!='') || (be_style == BES_BEGIN_END_STYLE_3)) {
               col += syntax_indent;
            }
            replace_line(indent_string(col-1):+strip(cur_line,'L'));
            _end_line();
         }
         indent_on_enter(syntax_indent);
         if (eol:!='') {
            replace_line(indent_string(p_col-1):+eol);
         }
      } else if ( first_word=='switch' && last_word=='{' ) {
         down();
         get_line(line);
         up();
         extra_case_indent := 0;
         if ((indent_case && indent_case!='') || (be_style == BES_BEGIN_END_STYLE_3)) {
            extra_case_indent=syntax_indent;
         }
         if ( pos('}',line) > 0 ) {
            indent_on_enter(syntax_indent);
            get_line(line);
            if ( line=='' ) {

               col=p_col-syntax_indent;
               replace_line(indent_string(col-1+extra_case_indent)'case :');
               _end_line();left();

               // notify user that we did something unexpected
               notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
            }
         } else {
            indent_on_enter(syntax_indent);
            get_line(line);
            if ( line=='' ) {
               col=p_col-syntax_indent;
               replace_line(indent_string(col-1+extra_case_indent)'case :');
               _end_line();left();

               // notify user that we did something unexpected
               notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
            }
         }
     } else {
       status=1;
     }
   } else {
     status=1;
   }
   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      col=awk_indent_col(non_blank_col);
      indent_on_enter(0,col);
   }

   return(status != 0);

}
// Return column position on switch or 0 if not found
int _awk_last_switch_col()
{
   if (p_lexer_name=='') {
      return(0);
   }
   save_pos(auto p);
   // Find switch at same brace level
   // search for begin brace,end brace, and switch not in comment or string
   status := search('\{|\}|switch','@hr-');
   level := 0;
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      //messageNwait('word='word);
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (word) {
         case '}':
            --level;
            break;
         case '{':
            ++level;
            break;
         default:
            if (color==CFG_KEYWORD && level== 1) {
               result := p_col;
               restore_pos(p);
               return(result);
            }
         }
      }
      status=repeat_search();
   }
}

int awk_indent_col(int non_blank_col,bool pasting_open_block = false)
{
   Noflines := 0;
   typeless cur_line='';
   first_word := "";
   last_word := "";
   rest := "";
   typeless semi='';
   typeless prev_semi='';
   int nbc = non_blank_col;
   int status=awk_get_info(Noflines,cur_line,first_word,last_word,rest,
              non_blank_col,semi,prev_semi);
   if (status) {
      return nbc;
   }

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      return(non_blank_col);
   }
   style2 := (p_begin_end_style == BES_BEGIN_END_STYLE_3);
   is_structure := pos(' 'first_word' ',' if do while switch for ');
   level1_brace := substr(cur_line,1,1)=='{';
   past_non_blank := p_col>non_blank_col || name_on_key(ENTER)=='nosplit-insert-line';

#if 0
   save_pos(p);
   up(Noflines);get_line(line);
   parse line with line '/*' ; /* Strip comment on current line. */
   parse line with line '//' ; /* Strip comment on current line. */
   parse line with before ');' +0 rest
   if (rest==');' && p_col>text_col(before)+2) {
      p_col=text_col(before)+1;
      status=_find_matching_paren(def_pmatch_max_diff_ksize);
      if (!status) {
         get_line(line);
         non_blank_col=text_col(line,pos('[~ \t]|$',line,1,'r'),'I');
      }
      restore_pos(p);
      return(non_blank_col);
   }
   down(Noflines);
#endif
#if 1
   save_pos(auto p);
   line := "";
   up(Noflines);get_line_raw(line);
   // Check for statement like this
   //
   //   if ( func(a,b,
   //          c,(d),(e) )) return;
   //
   //  look for last paren which matches to paren on different line.
   //
   i := 0;
   j := 0;
   if (Noflines) {
      i=length(line);
   } else {
      i=text_col(line,p_col,'p')-1;
   }
   //i=text_col(expand_tabs(line,1,p_col-1));
   //messageNwait('line='line' i='i);
   //old_col=p_col;
   word := "";
   typeless pline=point();
   for (;;) {
      if (i<=0) break;
      j=lastpos(')',line,i,p_rawpos);
      if (!j) break;
      p_col=text_col(line,j,'I');
      int color=_clex_find(0,'g');
      //messageNwait('h1');
      if (color==CFG_COMMENT || color==CFG_STRING) {
         i=j-1;
         continue;
      }
      //messageNwait('try');
      status=_find_matching_paren(def_pmatch_max_diff_ksize);
      if (status) break;
      if (pline!=point()) {
         //messageNwait('special case');
         _first_non_blank();
         non_blank_col=p_col;
         get_line_raw(line);
         parse line with word .;
         is_structure=pos(' 'word' ',' if do while switch for ',1,p_rawpos);
      }
      i=j-1;
   }
   restore_pos(p);
#endif
   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   if (
      (last_word=='{' && (! style2 || level1_brace) && indent_fl && past_non_blank) ||     /* Line end with '{' ?*/
      (is_structure && ! semi && past_non_blank && pasting_open_block!=1) ||
       pos('(\}|)else$',strip(cur_line),1,'r') || (first_word=='else' && !semi) ||
       first_word=='case' || first_word=='default' ||
       (first_word=='main' && indent_fl && past_non_blank) ||
       (is_structure && last_word=='{' && past_non_blank) ) {
      //messageNwait('case1');
      return(non_blank_col+syntax_indent);
      /* Look for spaces, end brace, spaces, comment */
   } else if ( (pos('^([ \t])*\}([ \t]*)(\\|/\*|$)',cur_line,1,'r') && style2)|| (semi && ! prev_semi)) {
      // OK we are a little lazy here. If the dangling statement is not indented
      // correctly, then neither will this statement.
      //
      //     if (
      //             )
      //             i=1;
      //         <end up here> and should be aligned with if
      //
      //messageNwait('case2');
      int col=non_blank_col-syntax_indent;
      if ( col<=0 ) {
         col=1;
      }
      if ( col==1 && indent_fl ) {
         return(non_blank_col);
      }
      return(col);
   }
   return(non_blank_col);

}

static _str awk_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   
   status := 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   col := 0;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,awk_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   set_surround_mode_start_line();
   if_special_case := 0;
   first_word := "";
   second_word := "";
   rest := "";
   if ( word=='') {
      // Check for } else
      parse orig_line with first_word second_word rest ;
      if (first_word=='}' && second_word!='' && rest=='' && second_word:==substr('els',1,length(second_word))) {
         keyin(substr('else ',length(second_word)+1));
         return(0);
      }
      // Check for else if or } else if
      if (first_word=='else' && orig_word==substr('else if',1,length(orig_word))) {
         word='else if';
         if_special_case=1;
      } else if (second_word=='else' && rest!='' && orig_word==substr('} else if',1,length(orig_word))) {
         word='} else if';
         if_special_case=1;
      } else if (first_word=='}else' && second_word!='' && orig_word==substr('}else if',1,length(orig_word))) {
         word='}else if';
         if_special_case=1;
      } else {
         return(1);
      }
   }
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   _str maybespace=(p_no_space_before_paren)?'':' ';
   _str parenspace=(p_pad_parens)? ' ':'';
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   int style2=be_style & BES_BEGIN_END_STYLE_2;
   int style3=be_style & BES_BEGIN_END_STYLE_3;
   e1 := " {";
   if (! (word=='do' && !style3 && !style2) ) {
      if ( (be_style & (BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3)) ||
         (!LanguageSettings.getInsertBeginEndImmediately(p_LangId)) ) {
         e1='';
      }
   }

   // if we only add spacing, do not notify the user
   doNotify := true;
   if ( word=='if' || if_special_case) {
      replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
      maybe_autobracket_parens();
   } else if ( word=='for' ) {
      replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
      maybe_autobracket_parens();
   } else if ( word=='BEGIN' || word=='END') {
      replace_line(line' ');
      _end_line();
      doNotify = (line != orig_line);
   } else if ( word=='while' ) {
      if (c_while_is_part_of_do_loop()) {
         replace_line(line:+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;
         if (p_pad_parens) --p_col;
      } else {
         replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
         maybe_insert_braces(syntax_indent,be_style,width,word);
         maybe_autobracket_parens();
      }
   } else if ( word=='do' ) {
      // Always insert braces for do loop unless braces are on separate
      // line from do and while statements
      replace_line(line:+e1);
      if ( ! style3 ) {
         if (style2 ) insert_line(indent_string(width)'{');
         
         insert_line(indent_string(width)'} while':+maybespace:+'('parenspace:+parenspace');');
         set_surround_mode_end_line();
         up();
      } else {
         if (LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
            insert_line(indent_string(width+syntax_indent)'{');
            insert_line(indent_string(width+syntax_indent)'}');
            insert_line(indent_string(width)'while':+maybespace:+'('parenspace:+parenspace');');
            set_surround_mode_end_line(p_line-1,2);
            up(2);
            syntax_indent=0;
         } else {
            insert_line(indent_string(width)'while':+maybespace:+'('parenspace:+parenspace');');
            up(1);
         }

      }
      nosplit_insert_line();
      p_col += syntax_indent;
   } else if ( word=='printf' ) {
      replace_line(indent_string(width)'printf("');
      _end_line();
   } else if ( word=='return' ) {
      if (orig_word=='return') {
         keyin(' ');
         doNotify = false;
      } else {
         newLine := indent_string(width)'return';
         replace_line(newLine);
         _end_line();
         doNotify = (newLine != orig_line);
      }
   } else if ( pos(' 'word' ',AWK_EXPAND_WORDS) ) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else {
     status=1;
     doNotify = false;
   }

   // maybe do dynamic surround
   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify){
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
   
}

int _awk_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, awk_space_words, prefix, min_abbrev);
}

static awk_expand_begin()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);

   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   
   brace_indent := 0;
   keyin('{');
   _str line,rline;
   get_line(line);
   rline=_rawText(line);
   int pcol=_text_colc(p_col,'P');
   col := 0;
   word := "";
   first_word := "";
   last_word := "";
   if ( pcol-2>0 ) {
      i := lastpos('[~ ]',rline,pcol-2,p_rawpos'r');
      if ( i && substr(rline,i,1)==')' ) {
         parse substr(rline,pcol-1) with  last_word '/\*|//','yr';
      }
   }

   insertBe := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   
   if ( line!='{' ) {
      if ( last_word!='{' ) {
         parse line with first_word .;
         parse line with '}' word '{' +0 last_word '/*';
         if ( (last_word!='{' || word!='else') && first_word!='typedef' &&
            first_word!='struct' && first_word!='union' && first_word!='class') {
            return(0);
         }
      }
      if ( be_style == BES_BEGIN_END_STYLE_3 ) {
         brace_indent=syntax_indent;
         be_style = 0;
         insertBe = false;
//       be_style= be_style & ~(BES_BEGIN_END_STYLE_2|BES_BEGIN_END_STYLE_3|BRACE_INSERT_FLAG);
      }
   } else if (be_style != BES_BEGIN_END_STYLE_3 ) {
      if ( ! prev_stat_has_semi() ) {
         old_col := p_col;
         up();
         if ( ! rc ) {
            _first_non_blank();p_col=p_col+syntax_indent+1;
            down();
         }
         col=p_col-syntax_indent-1;
         if ( col<1 ) {
            col=1;
         }
         if ( col<old_col ) {
            replace_line(indent_string(col-1)'{');
         }
      }
   }
   _first_non_blank();
   if ( expand ) {
      col=p_col-1;
      if ( (col && (be_style == BES_BEGIN_END_STYLE_3)) || (! (indent_fl+col)) ) {
         syntax_indent=0;
      }
      insert_line(indent_string(col+brace_indent));
      awk_endbrace();
      up();_end_line();
      if (insertBe ) {
         awk_enter();
      }
#if 0
      if ( insertBe ) {
         insert_line(indent_string(col+syntax_indent));
      }
      insert_line(indent_string(col+brace_indent)'}');
      up();_end_line();
#endif
   } else {
      _end_line();
   }

   // notify user that we did something unexpected
   notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

   return(0);

}
static int prev_stat_has_semi()
{
   typeless status=1;
   up();
   if ( ! rc ) {
      col := p_col;_end_line();
      line := "";
      get_line(line);
      parse line with line '\#|/\*|//','r' ;
      /* parse line with line '{' +0 last_word ; */
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line='' or last_word='{' or first_word='case' */
      line=strip(line,'T');
      if (raw_last_char(line)==')') {
         save_pos(auto p);
         p_col=text_col(_rawText(line));
         status=_find_matching_paren(def_pmatch_max_diff_ksize);
         if (!status) {
            status=search('[~( \t]','@-rh');
            if (!status) {
               if (!_clex_find(0,'g')==CFG_KEYWORD) {
                  status=1;
               } else {
                  typeless junk;
                  _str kwd=cur_word(junk);
                  status=!pos(' 'kwd' ',' if do while switch for ');
               }
            }
         }
         restore_pos(p);
      } else {
         status= raw_last_char(line)!=')' && ! pos('(\}|)else$',line,1,p_rawpos'r');
      }
      down();
      p_col=col;
   }
   return(status);
}
static bool stat_has_semi(_str option='')
{
   line := "";
   get_line(line);
   parse line with line '/*';
   parse line with line '/\*|//','r';
   line=strip(line,'T');
   return(raw_last_char(line):==';' &&
            (
               ! (( _will_split_insert_line()
                    ) && (p_col<=text_col(_rawText(line)) && option=='')
                   )
            )
         );

}
static void maybe_insert_braces(int syntax_indent,int be_style,int width,_str word)
{
   int col=width+length(word)+3;
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   if (p_no_space_before_paren) --col;
   if ( p_pad_parens ) ++col;
   if ( be_style == BES_BEGIN_END_STYLE_3 ) {
      width += syntax_indent;
   }
   if ( LanguageSettings.getInsertBeginEndImmediately(p_LangId) ) {
      up_count := 1;
      if ( be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ) {
         up_count++;
         insert_line(indent_string(width)'{');
      }
      if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) {
         up_count++;
         insert_line(indent_string(width+syntax_indent));
      }
      insert_line(indent_string(width)'}');
      set_surround_mode_end_line();
      up(up_count);
   }
   p_col=col;
   if ( ! _insert_state() ) { _insert_toggle(); }
}

int awk_proc_search(_str &proc_name,int find_first)
{
   _str re_map:[];
   re_map:["ARGS"] = "[a-zA-Z0-9=, \\t]#";
   return _generic_regex_proc_search('^(:b|)function:b<<<NAME>>> *\(<<<ARGS>>>', proc_name, find_first!=0, "function", re_map);
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
bool awk_is_start_block()
{
   return c_is_start_block();
}
