////////////////////////////////////////////////////////////////////////////////////
// Copyright 2015 SlickEdit Inc.
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
#import "alias.e"
#import "autocomplete.e"
#import "cutil.e"
#import "hotspots.e"
#import "notifications.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

static const NINJA_LANGUAGE_ID=   'ninja';

_command void ninja_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(NINJA_LANGUAGE_ID);
}


defeventtab ninja_keys;
def 'ENTER'=ninja_enter;
def 'TAB'=smarttab;

 
static int _ninja_indent_col(int syntax_indent)
{
   // search for previous command xxx(...)
   col := 0;
   save_pos(auto p);
   _first_non_blank();
   
   id := cur_identifier(col);
   cfg := _clex_find(0, 'g');
   if (id != '') {
      // default to command-name indent level
      _first_non_blank();
      col = p_col;

      if (cfg == CFG_KEYWORD) {
         switch (id) {
         case "rule":
         case "build":
         case "default":
         case "subninja":
         case "include":
         case "pool":
            col = p_col + syntax_indent;
            break;
         }
      }
   } else {
      col = 1;
   }

   restore_pos(p);
   return(col);
}

bool _ninja_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   if (name_on_key(ENTER):=='nosplit-insert-line') {
      _end_line();
   }
   cfg := _clex_find(0, 'g');
   if (cfg == CFG_STRING) {
      // string continuation
      indent_on_enter(0, 1);
      return(false);
   }

   int col = _ninja_indent_col(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void ninja_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_ninja_expand_enter, true);
}
bool _ninja_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

/**
 * CMake <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int ninja_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   typeless status = _clex_skip_blanks('m');
   if (!status) {
      _begin_select(); up(); _end_line();
   }
   col := _ninja_indent_col(syntax_indent);
   return col;
}


/**
 * Search for sections in a Unix Makefile.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int ninja_proc_search(_str &proc_name, int find_first)
{
   static _str re_map:[];
   if (re_map._isempty()) {
      re_map:["TYPE"] = "rule|include|subninja|default|build";
      re_map:["NAME"] = "[a-zA-Z90-9\\.\\$\\-_\\/\\\\\\(\\)\\{\\}\\[\\],\\@\\#\\%\\^\\*\\+\\=]@";
   }

   static _str kw_map:[];
   if (kw_map._isempty()) {
      kw_map:["rule"]     = "rule";
      kw_map:["default"]  = "rule";
      kw_map:["include"]  = "include";
      kw_map:["subninja"] = "call";
      kw_map:["build"]    = "trigger";
   }

   return _generic_regex_proc_search('^[ \t]*<<<TYPE>>>:b<<<NAME>>>', proc_name, find_first!=0, "func", re_map, kw_map);
}
