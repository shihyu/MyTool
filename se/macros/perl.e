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
#include "tagsdb.sh"
#include "color.sh"
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "c.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "main.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "sftp.e"
#import "tags.e"
#import "util.e"
#import "env.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Don't modify this code unless defining extension specific
  aliases do not suit your needs.   For example, if you
  want your brace style to be:

       if () {
          }

  Use the Language Options dialog 
  ("Document", "[Language] Options...]", "Aliases"). 
  and press the the "Alias" button to create a new alias.
  Type "if" for the name of the alias and press Enter.
  Enter the following text into the upper right editor control:

       if (%\c) {
       %\i}

  The  %\c indicates where the cursor will be placed after the
  "if" alias is expanded.  The %\i specifies to indent by the
  Extension Specific "Syntax Indent" amount define in the
  "Extension Options" dialog box.  Check the "Indent With Tabs"
  check box on the Extension Options dialog box if you want
  the %\i option to indent using tab characters.

*/
/*
  Options for Perl syntax expansion/indenting may be accessed from the
  Language Options ("Document", "[Language] Options...]", "Editing").

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
*/

static const PL_LANGUAGE_ID=  'pl';

defeventtab perl_keys;
def  ' '= perl_space;
def  '('= perl_key;
def  '.'= embedded_key;
def  ':'= perl_key;
def  '<'= embedded_key;
def  '='= perl_key;
def  '>'= embedded_key;
def  '{'= perl_begin;
def  '}'= perl_endbrace;
def  'ENTER'= perl_enter;
def  'TAB'= smarttab;

_command void perl_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PL_LANGUAGE_ID);
}

_command void perl_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_pl_expand_enter);
}
bool _pl_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _pl_supports_insert_begin_end_immediately() {
   return true;
}
_command void perl_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if ( command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
        _in_comment() ||
        perl_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

_command void perl_colon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   cfg := 0;
   keyin(':');
   if (!command_state()) {
      left();
      cfg=_clex_find(0,'g');
      right();
   }
   if ( command_state() || p_SyntaxIndent<0 ||
      _in_comment() || cfg==CFG_STRING) {
   } else {
      if (_c_do_colon() &&
          (_GetCodehelpFlags()&VSCODEHELPFLAG_AUTO_LIST_MEMBERS)
         ) {
         _do_list_members(OperatorTyped:true, DisplayImmediate:false);
      }
   /*} else if (_argument=='') {
      _undo('S');*/
   }
}
bool _inPODComment()
{
   if (_clex_find(0,'g')!=CFG_COMMENT) {
      return(false);
   }
   save_pos(auto p);
   typeless status=_clex_find(COMMENT_CLEXFLAG,'n-');
   if (status) {
      top();
   }
   _clex_find(COMMENT_CLEXFLAG);
   status=(get_text()=='=');
   restore_pos(p);
   return(status);
}
static _str gPODTagList[]= {
   '=head1',
   '=head2',
   '=item',
   '=over',
   '=back',
   '=cut',
   '=pod',
   '=for',
   '=begin',
   '=end'
};
_command void perl_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   _str key = last_event();
   if (command_state()) {
      call_root_key(key);
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin(key);
      return;
   }
   if(_EmbeddedLanguageKey(key)) return;
   switch (key) {
   case ':':
   case '>':
      keyin(key);
      if (_GetCodehelpFlags()&VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
         _do_list_members(OperatorTyped:true, DisplayImmediate:false);
      }
      return;
   case '(':
      // Check syntax expansion options
      if (LanguageSettings.getSyntaxExpansion(p_LangId) && p_SyntaxIndent>=0 && !_in_comment() &&
          !perl_expand_space()) {
         return;
      }
      auto_functionhelp_key();
      return;
   case '=':
      if (_in_comment() && _inPODComment()) {
         line := "";
         get_line(line);
         if (line=='' && p_col==_text_colc()+1 ) {
            keyin(key);
            _do_list_members(OperatorTyped:true, 
                             DisplayImmediate:true,
                             gPODTagList);
            return;
         }
      }
      break;
   }
   call_root_key(key);
}
_command void perl_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if ( command_state() || _in_comment() || perl_expand_begin() ) {
      call_root_key('{');
   } else if (_argument=='') {
      _undo('S');
   }

}
_command void perl_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (_isEditorCtl() && _EmbeddedLanguageKey(last_event())) return;
   keyin('}');
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      line := "";
      get_line(line);
      if (line=='}') {
         int col=perl_endbrace_col();
         if (col) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

/* Returns column where end brace should go.
   Returns 0 if this function does not know the column where the
   end brace should go.
 */
int perl_endbrace_col()
{
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

   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
      col+=p_SyntaxIndent;
   }
   restore_pos(p);
   return(col);
}

static int find_block_col()
{
   word := "";
   col := 0;
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
   typeless status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) return(0);
   if (p_col==1) return(1);
   --p_col;

   if (_clex_skip_blanks('-')) return(0);
   if (_clex_find(0,'g')!=CFG_KEYWORD) {
      return(0);
   }
   word=cur_word(col);
   if (pos(' 'word' ',' if while foreach for elsif ')) {
      _first_non_blank();
      return(p_col);
      //return(p_col-length(word)+1);
   }
   return(0);
}
static const PL_EXPAND_WORDS= ' do else elsif for foreach last next package require unless ';
static SYNTAX_EXPANSION_INFO perl_space_words:[] = {
   'do'        => { "do" },
   'else'      => { "else { ... }" },
   'elsif'     => { "elsif ( ... ) { ... }" },
   'for'       => { "for ( ... ) { ... }" },
   'foreach'   => { "foreach ( ... ) { ... }" },
   'if'        => { "if ( ... ) { ... }" },
   'last'      => { "last" },
   'local'     => { "local" },
   'next'      => { "next" },
   'package'   => { "package" },
   'print'     => { "print" },
   'require'   => { "require" },
   'return'    => { "return" },
   'select'    => { "select ( ... );" },
   'sub'       => { "sub ... { ... }" },
   'unless'    => { "unless" },
   'while'     => { "while ( ... ) { ... }" },
};

int perl_get_info(var Noflines,var cur_line,var first_word,var last_word,
              var rest,var non_blank_col,var semi,var prev_semi,
              bool in_smart_paste=false)
{
   typeless old_pos;
   save_pos(old_pos);
   first_word='';last_word='';non_blank_col=p_col;
   j := 0;
   line := "";
   before_brace := "";
   syntax_indent := 0;
   typeless p2=0;
   typeless junk="";
   typeless status=0;
   if (in_smart_paste) {
      for (j=0; ; ++j) {
         get_line_raw(cur_line);
         if ( cur_line!='' ) {
            parse cur_line with line '#',p_rawpos ; /* Strip comment on current line. */
            parse line with before_brace '{',p_rawpos +0 last_word ;
            parse strip(line,'L') with first_word '[({:; \t]',(p_rawpos'r') +0 rest ;
            last_word=strip(last_word);

            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
            syntax_indent=p_SyntaxIndent;
            if (last_word=='{' && !(p_begin_end_style == BES_BEGIN_END_STYLE_3)) {
               save_pos(p2);
               p_col=text_col(before_brace);
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
                     _str kwd=cur_word(junk);
                     status=!pos(' 'kwd' ',' if while foreach for ');
                  }
               }
               if (status) {
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
                  restore_pos(p2);
               } else {
                  get_line_raw(line);
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
                  /* Use non blank of start of if, do, while, foreach, unless, or for. */
               }
            } else {
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
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
         get_line_raw(cur_line);
         _begin_line();
         int i=verify(cur_line,' '\t);
         if ( i ) p_col=text_col(cur_line,i,'I');
         if ( cur_line!='' && _clex_find(0,'g')!=CFG_COMMENT) {
            parse cur_line with line '#',p_rawpos ; /* Strip comment on current line. */
            parse line with before_brace '{',p_rawpos +0 last_word ;
            parse strip(line,'L') with first_word '[({:; \t]',(p_rawpos'r') +0 rest ;
            last_word=strip(last_word);

            updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
            syntax_indent=p_SyntaxIndent;
            if (last_word=='{' && !(p_begin_end_style == BES_BEGIN_END_STYLE_3)) {
               save_pos(p2);
               p_col=text_col(before_brace);
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
                     _str kwd=cur_word(junk);
                     status=!pos(' 'kwd' ',' if while foreach for ');
                  }
               }
               if (status) {
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
                  restore_pos(p2);
               } else {
                  get_line_raw(line);
                  non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
                  /* Use non blank of start of if, do, while, unless, foreach, or for. */
               }
            } else {
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
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
   p := "";
   if ( j ) {
      p=1;
   }
   semi=stat_has_semi(p);
   prev_semi=prev_stat_has_semi();
   restore_pos(old_pos);
   return(0);
}
/* Returns non-zero number if pass through to enter key required */
typeless _pl_expand_enter()
{
   if(_EmbeddedLanguageKey(last_event())) return(0);

   Noflines := 0;
   non_blank_col := 0;
   cur_line := "";
   first_word := "";
   last_word := "";
   rest := "";
   typeless semi="";
   typeless prev_semi="";
   line := "";
   int status=perl_get_info(Noflines,cur_line,first_word,last_word,rest,
                        non_blank_col,semi,prev_semi);
   if (status) return(1);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);

   status=0;
   semi1_col := 0;
   semi2_col := 0;
   if ( expand && ! Noflines ) {
      if ( (first_word=='for' || first_word=='foreach') &&
            name_on_key(ENTER):=='nosplit-insert-line' ) {
         if ( name_on_key(ENTER):!='nosplit-insert-line' ) {
            
            if ( be_style == BES_BEGIN_END_STYLE_2 || semi ) return(1);
            
            indent_on_enter(syntax_indent);
            return(0);
         }
         /* tab to fields of Perl for statement */
         line=expand_tabs(cur_line);
         semi1_col=pos(';',line,p_col,p_rawpos);
         if ( semi1_col>0 && semi1_col>=p_col ) {
            p_col=semi1_col+2;
         } else {
            semi2_col=pos(';',line,semi1_col+1);
            if ( (semi2_col>0) && (semi2_col>=p_col) ) {
               p_col=semi2_col+2;
            } else {
               if ( be_style == BES_BEGIN_END_STYLE_2 || semi ) return(1);
               
               indent_on_enter(syntax_indent);
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
      int col=pl_indent_col(non_blank_col);
      indent_on_enter(0,col);
   }
   return(status);

}

int pl_indent_col(int non_blank_col, bool pasting_open_block = false)
{
   Noflines := 0;
   int nbc=non_blank_col;
   cur_line := "";
   first_word := "";
   last_word := "";
   rest := "";
   semi := "";
   prev_semi := "";
   int status=perl_get_info(Noflines,cur_line,first_word,last_word,rest,
                        non_blank_col,semi,prev_semi);
   if (status) return(nbc);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent:=p_SyntaxIndent;
   style3 := (p_begin_end_style == BES_BEGIN_END_STYLE_3);
   is_structure := pos(' 'first_word' ',' if do while foreach for ');
   level1_brace := substr(cur_line,1,1)=='{';
   past_non_blank := p_col>non_blank_col || name_on_key(ENTER)=='nosplit-insert-line';
   /* messageNwait('is_struct='is_structure' semi='semi' psemi='prev_semi' firstw='first_word' lastw='last_word) */

   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   
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
   i := j := 0;
   color := 0;
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
      color=_clex_find(0,'g');
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
         parse line with word '[ \t]',(p_rawpos'r');
         is_structure=pos(' 'word' ',' if do while foreach for ');
         //restore_pos(p);
         //return(col);
      }
      i=j-1;
   }
   restore_pos(p);
   if (
      (last_word=='{' && (! style3 || level1_brace) && indent_fl && past_non_blank) ||     /* Line end with '{' ?*/
      (is_structure && ! semi && past_non_blank && pasting_open_block!=1) ||
       pos('(\}|)else$',strip(cur_line),1,'r') || (first_word=='else' && !semi) ||
       (is_structure && last_word=='{' && past_non_blank) ) {
      //messageNwait('case1');
      return(non_blank_col+syntax_indent);
      /* Look for spaces, end brace, spaces, comment */
   } else if ( (pos('^([ \t])*\}([ \t]*)(\\|\#|$)',cur_line,1,'r') && style3)|| (semi && ! prev_semi)) {
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

static long add_stmt_parens()
{
//   replace_line(line:+maybespace:+'(':+parenspace:+parenspace:+')':+e1); 
   get_line(auto line);
   maybespace := (p_no_space_before_paren) ? '' :' ';
   padspace := (p_pad_parens) ? ' ' : '';

   line = strip(line, 'T');
   replace_line(line:+maybespace'('padspace);
   _end_line();
   rv := _QROffset();
   if (p_pad_parens) {
      keyin(' ');
   }
   keyin(')');
   _GoToROffset(rv);
   add_hotspot();
   return rv;
}

static typeless perl_expand_space()
{
   if(_EmbeddedLanguageKey(last_event())) return(0);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;

   // since perk_key calls this function in the case of an open paren, 
   // we need to know when to jump out of this
   openParenCase := (last_event()=='(');

   typeless status=0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   if_special_case := 0;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,perl_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   #if 1
   first_word := "";
   second_word := "";
   rest := "";
   if ( word=='') {
      // Check for ) unless
      parse orig_line with . '\)|last|next','r' +0 first_word second_word rest ;
      if ((first_word==')' || first_word=='last' || first_word=='next') &&
           second_word!='' && rest=='' && second_word:==substr('unless',1,length(second_word))) {
         keyin(substr('unless ',length(second_word)+1));

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
         return(0);
      }
      first_word='';
      if (substr(orig_line,1,1)=='}') {
         first_word='}';
         if (substr(orig_line,2,1)==' ') {
            first_word='} ';
         }
      }
      parse strip(substr(orig_line,2)) with second_word rest;
      if (second_word!='' && rest=='' &&
          (second_word:==substr('elsif',1,length(second_word)) ||
           second_word:==substr('else',1,length(second_word)))) {
         word=min_abbrev2(second_word,perl_space_words,'',aliasfilename);
         word=first_word :+ word;
         if_special_case=1;
      }
   }
   #endif
   if ( word=='') return(1);

   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN);
   _str maybespace=(p_no_space_before_paren)?'':' ';
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   e1 := " {";
   if (word !='do' && (be_style == BES_BEGIN_END_STYLE_2 || be_style == BES_BEGIN_END_STYLE_3 ||
       !LanguageSettings.getInsertBeginEndImmediately(p_LangId))) {
      e1='';
   }

   // special case for open parenthesis (see c_paren)
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   noSpaceBeforeParen := p_no_space_before_paren;
   parenspace := (p_pad_parens)? ' ':'';
   if (openParenCase) {
      noSpaceBeforeParen = true;
      if ( length(word) != length(orig_word) ) {
         return 1;
      }
      switch ( word ) {
      case 'if':
      case 'elsif':
      case 'while':
      case 'for':
      case 'else if':
      case 'foreach':
         break;
      default:
         return 1;
      }
   } 

   set_surround_mode_start_line();
   clear_hotspots();

   if (pos(orig_word, word) == 1 && orig_word._length() < word._length()) {
      // They picked an expansion, but we haven't put the expansion in the buffer yet.
      _insert_text(substr(word, 1+orig_word._length()), false);
   }

   doNotify := true;
   if ( pos('else',word) ) {
      keyin(' ');
      maybe_brace_it(be_style);
      doNotify = (LanguageSettings.getInsertBeginEndImmediately(p_LangId));
   } else if ( word=='elsif' || word=='if' || if_special_case) {
      firstSpot := add_stmt_parens();
      maybe_brace_it(be_style);
      _GoToROffset(firstSpot);
      maybe_autobracket_parens();
   } else if ( word=='for' ) {
      firstSpot := add_stmt_parens();
      maybe_brace_it(be_style);
      _GoToROffset(firstSpot);
      maybe_autobracket_parens();
   } else if ( word=='foreach' ) {
      firstSpot := add_stmt_parens();
      maybe_brace_it(be_style);
      _GoToROffset(firstSpot);
      maybe_autobracket_parens();
   #if 0
   } else if( word=='local' ) {
      replace_line(line:+maybespace:+'();');
      p_col=width+length(word:+maybespace)+2;
   #endif
   } else if ( word=='next' || word=='last' ) {
      if ( orig_word==word ) {
         keyin(' ');
         doNotify = false;
      } else {
         newLine := indent_string(width)word;
         replace_line(newLine);
         _end_line();
         doNotify = (newLine != orig_line);
      }
   } else if ( word=='print'|| word=='return' ) {
      if ( orig_word==word ) {
         keyin(' ');
         doNotify = false;
      } else {
         newLine := indent_string(width)word' ';
         replace_line(newLine);
         _end_line();
         doNotify = (newLine != orig_line);
      }
   } else if ( word=='private') {
      replace_line(line:+':');
      _end_line();
   } else if( word=='select' ) {
      _GoToROffset(add_stmt_parens());
      maybe_autobracket_parens();
   } else if ( word=='sub' ) {
      perl_insert_sub();
      doNotify = LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   #if 0
   } else if ( word=='unless' ) {
      replace_line(line:+maybespace'()'e1);
      maybe_insert_braces(syntax_indent,be_style,width,word);
   #endif
   } else if ( word=='while' ) {
      firstSpot := add_stmt_parens();
      maybe_brace_it(be_style);
      _GoToROffset(firstSpot);
      maybe_autobracket_parens();
   } else if ( pos(' 'word' ',PL_EXPAND_WORDS) ) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else {
      doNotify = false;
      status=1;
   }

   show_hotspots();

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if (openParenCase) {
      AutoBracketCancel();
   }

   return status;
}

int _pl_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, perl_space_words, prefix, min_abbrev);
}

static perl_expand_begin()
{
   if(_EmbeddedLanguageKey(last_event())) return(0);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);

   brace_indent := 0;
   keyin('{');
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);
   line := "";
   get_line_raw(line);
   int pcol=text_col(line,p_col,'P');
   last_word := "";
   col := 0;
   i := 0;
   if ( pcol-2 > 0 ) {
      i=lastpos('[~ ]',line,pcol-2,p_rawpos'r');
      if ( i && substr(line,i,1)==')' ) {
         parse substr(line,pcol-1) with  last_word '/\*|//',(p_rawpos'r');
      } else {
         i=lastpos('[~ ]',line,MAXINT,p_rawpos'r');
         if (i >= pcol) {
            restore_pos(AfterKeyinPos);
            return(0);
         }
      }
   }
   
   old_linenum := p_line;
   insertBE := LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId);
   if ( line!='{' ) {
      if ( last_word!='{' ) {
         first_word := second_word := word := "";
         parse line with first_word second_word;
         parse line with '}' word '{',p_rawpos +0 last_word '#',p_rawpos;
         if ( (last_word!='{' || word!='else') &&
              first_word!='do' && first_word!='for' && first_word!='foreach' && first_word!='sub') {
            return(0);
         }
      }
      if ( be_style == BES_BEGIN_END_STYLE_3 ) {
         brace_indent=syntax_indent;
         be_style = 0;
         insertBE = false;
      }
   } else if ( be_style != BES_BEGIN_END_STYLE_3 ) {
      if ( ! prev_stat_has_semi() ) {
         old_col := p_col;
         up();
         if ( ! rc ) {
            _first_non_blank();
            p_col += syntax_indent+1;
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
      indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
      if ( (col && be_style == BES_BEGIN_END_STYLE_3) || (!(indent_fl + col)) ) {
         syntax_indent=0;
      }
      insert_line(indent_string(col+brace_indent));

      set_surround_mode_start_line(old_linenum);
      perl_endbrace();
      up();_end_line();
      if (insertBE) {
         perl_enter();
      }

      set_surround_mode_end_line(p_line+1);
   } else {
      _end_line();
   }

   // do block surround only if we are already in a function scope
   if (_in_function_scope()) {
      do_surround_mode_keys();
   } else {
      clear_surround_mode_line();
   }
   return(0);

}
static typeless prev_stat_has_semi()
{
   typeless status=1;
   typeless p=0;
   line := "";
   col := 0;
   up();
   if ( ! rc ) {
      col=p_col;_end_line();get_line_raw(line);
      parse line with line '\#',(p_rawpos'r');
      /* parse line with line '{' +0 last_word ; */
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line='' or last_word='{' */
      line=strip(line,'T');
      if (raw_last_char(line)==')') {
         save_pos(p);
         p_col=text_col(line);
         status=_find_matching_paren(def_pmatch_max_diff_ksize);
         if (!status) {
            status=search('[~( \t]','@-rh');
            if (!status) {
               if (!_clex_find(0,'g')==CFG_KEYWORD) {
                  status=1;
               } else {
                  typeless junk=0;
                  _str kwd=cur_word(junk);
                  status=!pos(' 'kwd' ',' if do while foreach for ');
               }
            }
         }
         restore_pos(p);
      } else {
         status=raw_last_char(line)!=')' && !pos('(\}|)else$',line,1,p_rawpos'r');
      }
      down();
      p_col=col;
   }
   return(status);
}
static typeless stat_has_semi(...)
{
   line := "";
   get_line_raw(line);
   parse line with line '#',p_rawpos;
   line=strip(line,'T');
   return((raw_last_char(line):==';' || raw_last_char(line):=='}') &&
            (
               ! (( _will_split_insert_line()
                    ) && (p_col<=text_col(line) && arg(1)=='')
                   )
            )
         );

}

static bool open_brace_follows()
{
   rv := false;

   save_pos(auto pp);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

   if (search('\S', 'L@') == 0) {
      rv = get_text() == '{';
   }

   restore_search(s1, s2, s3, s4, s5);
   restore_pos(pp);

   return rv;
}

static void maybe_blank_line(int style, int stmtIndent)
{
   if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) {
      ind := stmtIndent + p_SyntaxIndent;
      insert_line(indent_string(ind));
      _end_line();
   }
}

static void place_close_brace(int stmtIndent)
{
   save_pos(auto pp);
   insert_line(indent_string(stmtIndent)'}');
   set_surround_mode_end_line();
   restore_pos(pp);
}

static int open_brace_indent(int style, int stmtIndent) {
   if (style == BES_BEGIN_END_STYLE_3) {
      return stmtIndent + p_SyntaxIndent;
   }

   return stmtIndent;
}

static void maybe_brace_it(int style)
{
   startInd := max(0, _first_non_blank_col() - 1);
   line := '';

   if (!open_brace_follows() &&
       LanguageSettings.getInsertBeginEndImmediately(p_LangId)) {
      switch (style) {
      case BES_BEGIN_END_STYLE_1:
         get_line(line);
         replace_line(strip(line, 'T')' {');
         maybe_blank_line(style, startInd);
         _end_line();
         add_hotspot();
         place_close_brace(startInd);
         break;

      case BES_BEGIN_END_STYLE_2:
      case BES_BEGIN_END_STYLE_3:
         braceInd := open_brace_indent(style, startInd);
         insert_line(indent_string(braceInd)'{');
         maybe_blank_line(style, startInd);
         _end_line();
         add_hotspot();
         place_close_brace(braceInd);
         break;
      }
   }
   if ( ! _insert_state() ) { _insert_toggle(); }
}

/*
   It is no longer necessary to modify this function to
   create your own sub style.  Just define an extension
   specific alias.  See comment at the top of this file.
*/
static typeless perl_insert_sub()
{
   get_line(auto line);

   keyin(' ');
   save_pos(auto pp);
   maybe_brace_it(p_begin_end_style);
   restore_pos(pp);

   if (p_begin_end_style == BES_BEGIN_END_STYLE_1) {
      keyin(' ');
      restore_pos(pp);
   }
   add_hotspot();

   return(0);
}


/* =========== Perl Tagging Support ================== */

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _pl_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_get_expression_info(PossibleOperator, info, visited, depth);
   if (status) {
      return(status);
   }
   if(info.prefixexp!="") {
      firstname := "";
      parse info.prefixexp with firstname"::";
      if (firstname=='main'/* || substr(prefixexp,1,2)=='::'*/) {
         info.prefixexp="::";
      }
      return(0);
   }
   return(0);
}

int _pl_fcthelp_get_start(_str (&errorArgs)[],
                          bool OperatorTyped,
                          bool cursorInsideArgumentList,
                          int &FunctionNameOffset,
                          int &ArgumentStartOffset,
                          int &flags,
                          int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags,
                               depth));
}
int _pl_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return(_c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth));
}

/**
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link _c_get_expression_info()}.
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link _c_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastid_prefix      prefix of identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_*
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _pl_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          bool find_parents,int max_matches,
                          bool exact_match,bool case_sensitive,
                          SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                          SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                          VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= SE_TAG_CONTEXT_ONLY_FUNCS;
   }

   // maybe prefix expression is a package name or prefix of package name
   if (prefixexp != "" && 
       !(context_flags & SE_TAG_CONTEXT_NO_GLOBALS) &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_THIS_FILE) &&
       !(context_flags & SE_TAG_CONTEXT_ONLY_LOCALS)) {
      num_matches := 0;
      tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);
      _CodeHelpListPackages(0, 0, 
                            p_window_id, tag_files,
                            prefixexp,lastid,
                            num_matches, max_matches,
                            exact_match, case_sensitive,
                            visited, depth+1);
   }

   status := _c_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth+1,prefix_rt);
   if (status < 0) {
      first_ch := _first_char(lastid);
      if (status < 0 && first_ch=='$') {
         array_lastid := '@':+substr(lastid,2);
         status = _c_find_context_tags(errorArgs,prefixexp,
                                       array_lastid,lastidstart_offset,
                                       info_flags,otherinfo,false,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
         if (_chdebug) {
            isay(depth, "_pl_find_context_tags: status="status" ARRAY NAME="array_lastid);
         }
      }
      if (status < 0 && first_ch=='$') {
         assoc_lastid := '%':+substr(lastid,2);
         status = _c_find_context_tags(errorArgs,prefixexp,
                                       assoc_lastid,lastidstart_offset,
                                       info_flags,otherinfo,false,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
         if (_chdebug) {
            isay(depth, "_pl_find_context_tags: status="status" ASSOC NAME="assoc_lastid);
         }
      }
      if (status < 0 && first_ch=='$') {
         plain_lastid := substr(lastid,2);
         status = _c_find_context_tags(errorArgs,prefixexp,
                                       plain_lastid,lastidstart_offset,
                                       info_flags,otherinfo,false,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
         if (_chdebug) {
            isay(depth, "_pl_find_context_tags: status="status" PLAIN NAME="plain_lastid);
         }
      }
      if (status < 0 && first_ch!='$' && first_ch!='%' && first_ch!='@') {
         status = _c_find_context_tags(errorArgs,prefixexp,
                                       "$":+lastid,lastidstart_offset,
                                       info_flags,otherinfo,false,max_matches,
                                       exact_match,case_sensitive,
                                       filter_flags,context_flags,
                                       visited,depth+1,prefix_rt);
         if (_chdebug) {
            isay(depth, "_pl_find_context_tags: status="status" STRING NAME=$"lastid);
         }
         if (status < 0) {
            status = _c_find_context_tags(errorArgs,prefixexp,
                                          "@":+lastid,lastidstart_offset,
                                          info_flags,otherinfo,false,max_matches,
                                          exact_match,case_sensitive,
                                          filter_flags,context_flags,
                                          visited,depth+1,prefix_rt);
            if (_chdebug) {
               isay(depth, "_pl_find_context_tags: status="status" ARRAY NAME=@"lastid);
            }
         }
         if (status < 0) {
            status = _c_find_context_tags(errorArgs,prefixexp,
                                          "%":+lastid,lastidstart_offset,
                                          info_flags,otherinfo,false,max_matches,
                                          exact_match,case_sensitive,
                                          filter_flags,context_flags,
                                          visited,depth+1,prefix_rt);
            if (_chdebug) {
               isay(depth, "_pl_find_context_tags: status="status" ASSOC NAME=%"lastid);
            }
         }
      }
   }
   return status;
}

_str get_perl_std_libs(_str perl_binary)
{
   temp_view_id := 0;
   orig_view_id := 0;
   line := "";
   path := "";
   rest := "";
   alternate_shell := "";
   std_libs := "";
   if (perl_binary!="") {
      alternate_shell=file_match('-p '_cygwin2dospath('/bin/sh'),1);
      if ( alternate_shell=='' ) {
         alternate_shell=path_search('sh');
      }
      _str temp_file=mktemp();
      line=_maybe_quote_filename(perl_binary)' -V >'_maybe_quote_filename(temp_file)' 2>&1';
      shell(line,'pq',alternate_shell);
      int status=_open_temp_view(temp_file,temp_view_id,orig_view_id);
      delete_file(temp_file);
      if (!status) {
         status=search('^[ \t]*\@INC\:',"@rh");
         if (!status) {
            get_line(line);
            parse line with ':' rest;
            if (rest!="") {
               for (;;) {
                  parse rest with path rest;
                  if (path=="") {
                     break;
                  }
                  add_to_perl_std_libs(std_libs,path,perl_binary);
               }
            } else {
               for (;;) {
                  if (down()) {
                     break;
                  }
                  get_line(path);
                  if (path=="") {
                     break;
                  }
                  add_to_perl_std_libs(std_libs,path,perl_binary);
               }
            }
         }
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
   }

   return std_libs;
}

static void add_to_perl_std_libs(_str &std_libs, _str path, _str perl_binary)
{
   path=strip(path);
   orig_path := path;
   if (_file_eq((substr(path,1,5)),"/usr/") &&
       !isdirectory(_cygwin2dospath('/usr/lib/perl5')) &&
       isdirectory(_cygwin2dospath('/lib/perl5'))!='') {
      path=substr(path,5);
   }
   path=_cygwin2dospath(path);

   // if we can't find cygwin, base the path on the location of the Perl binary
   if (path== "" && _cygwin_path()=="" && file_exists(perl_binary)) {
      path=substr(orig_path,5);
      perl_binary = _strip_filename(perl_binary, 'N');
      if (substr(perl_binary, length(perl_binary)-4, 5) == FILESEP'bin'FILESEP)
      {
         perl_binary = substr(perl_binary, 1, length(perl_binary)-4);
      }
      path = stranslate(path, FILESEP, FILESEP2);
      path = perl_binary :+ path;
   }

   // clean up and add the path to the list of libs to tag
   if (path == "" || path == '.') return;
   _maybe_append_filesep(path);
   std_libs :+= " "_maybe_quote_filename(path:+"*.pl");
   std_libs :+= " "_maybe_quote_filename(path:+"*.pm");
}
int _pl_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "pl";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"perl") && !forceRebuild) {
      return(0);
   }

   // IF the user does not have an extension specific tag file for Slick-C
   status := 0;
   perl_binary := "";
   if (_isWindows()) {
      status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                               "SOFTWARE\\ActiveWare\\Perl5",
                               "BIN", perl_binary);
      if (!status) {
         perl_binary :+= "\\perl.exe";
      }
   }
   if (perl_binary=='') {
      perl_binary=path_search("perl","","P");
   }
   if (_isWindows()) {
      if (perl_binary=='') {
         perl_binary=_path2cygwin('/bin/perl.exe');
      }
   }

   std_libs := get_perl_std_libs(perl_binary);

   // Build and Save tag file
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Perl Libraries",
                           true,std_libs,ext_builtins_path(ext,'perl'), withRefs, useThread);
}

/**
 * @see _e_is_continued_statement
 */
bool _pl_is_continued_statement()
{
   return _e_is_continued_statement();
}

/**
 * Checks to see if the first thing on the current line is an 
 * open brace.  Used by comment_erase (for reindentation). 
 * 
 * @return Whether the current line begins with an open brace.
 */
bool pl_is_start_block()
{
   return c_is_start_block();
}

bool _pl_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}
