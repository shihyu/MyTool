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
#import "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "c.e"
#import "cutil.e"
#import "pmatch.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

using se.lang.api.LanguageSettings;

static const CG_LANG_ID=    'cg';

static const CG_HLSL_LANG_ID=    'cghlsl';

_command void cg_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(CG_LANG_ID);
}

_command void cghlsl_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(CG_HLSL_LANG_ID);
}


int cghlsl_proc_search(_str &proc_name,int find_first,
                       _str unused_ext='', _str start_seekpos='', _str end_seekpos='')
{
   return _EmbeddedProcSearch(0,proc_name,find_first,unused_ext, start_seekpos, end_seekpos);
}

defeventtab cg_keys;
def 'ENTER'=cg_enter;
def 'TAB'= smarttab;
def '}'=cg_endbrace;

static int _cg_indent_brace(int syntax_indent)
{
   col := 0;
   nesting := 0;
   orig_col := p_col;
   orig_linenum := p_line;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   status := search('[{}();]', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      ch := get_text();
      switch (ch) {
      case '{':
         _first_non_blank();
         col = p_col + syntax_indent;
         restore_pos(p);
         return(col);

      case '}':
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
         restore_search(s1, s2, s3, s4, s5);
         if (status) {
            restore_pos(p);
            return(0);
         }
         _first_non_blank();
         col = p_col;
         restore_pos(p);
         return(col);

      case '(':
         if (nesting > 0) {
            --nesting;
         } else {
            col = ++p_col;
            restore_pos(p);
            return(col);
         }
         break;

      case ')':
         ++nesting;
         break;

      case ';':
         restore_pos(p);
         return(0);
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

bool _cg_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   
   if (name_on_key(ENTER):=='nosplit-insert-line') {
      _end_line();
   }
   int col = _cg_indent_brace(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void cg_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_cg_expand_enter);
}
bool _cghlsl_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _cg_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

static int _cg_endbrace_col(int be_style)
{
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
   _first_non_blank();
   col := p_col;
   if (be_style == BES_BEGIN_END_STYLE_3) {
      col+=p_SyntaxIndent;
   }
   restore_pos(p);
   return(col);
}

_command void cg_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('}');
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() ) {
   } else if (_argument=='') {
      line := "";
      get_line(line);
      if (line=='}') {
         int col=_cg_endbrace_col(LanguageSettings.getBeginEndStyle(p_LangId));
         if (col) {
            replace_line(indent_string(col-1):+'}');
            p_col=col+1;
         }
      }
      _undo('S');
   }
}

int cg_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return(c_smartpaste(char_cbtype,first_col,Noflines,allow_col_1));
}

