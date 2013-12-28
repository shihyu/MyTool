////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50674 $
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
#require "se/lang/api/LanguageSettings.e"
#import "autocomplete.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelputil.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

#define LUA_LANGUAGE_ID   'lua'
#define LUA_MODE_NAME     'Lua'
#define LUA_LEXERNAME     'Lua'
#define LUA_WORDCHARS     'A-Za-z0-9_'

defload()
{
   _str setup_info='MN='LUA_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='LUA_LANGUAGE_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='LUA_WORDCHARS',LN='LUA_LEXERNAME',CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 4 1 1';
   _str be_info='';
   _CreateLanguage(LUA_LANGUAGE_ID, LUA_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("lua", LUA_LANGUAGE_ID);
}

_command void lua_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(LUA_LANGUAGE_ID);
}

int _lua_MaybeBuildTagFile(int &tfindex)
{
   _str ext = 'lua';
   _str tagfilename = '';
   if (ext_MaybeRecycleTagFile(tfindex, tagfilename, ext, ext)) {
      return(0);
   }

   int status = ext_MaybeBuildTagFile(tfindex, ext, ext, "Lua Builtins");
   return 0;
}

int _lua_fcthelp_get_start(_str (&errorArgs)[],
                         boolean OperatorTyped,
                         boolean cursorInsideArgumentList,
                         int &FunctionNameOffset,
                         int &ArgumentStartOffset,
                         int &flags
                         )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags));
}

int _lua_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
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

int _lua_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

int _lua_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          boolean find_parents,int max_matches,
                          boolean exact_match,boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_clear_matches();
   errorArgs._makeempty();
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // get the current class from the context
   num_matches := 0;
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_locals) ||
       (context_flags & VS_TAGCONTEXT_ONLY_this_file)) {
      tag_files._makeempty();
   }

   // no prefix expression, update globals and symbols from current context
   if (prefixexp == '') {
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         tag_list_class_locals(0, 0, tag_files, lastid, "",
                               filter_flags, context_flags,
                               num_matches,max_matches,
                               exact_match, case_sensitive,
                               null, visited, depth);
      }

      // now update the globals in the current buffer
      if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) &&
          !(context_flags & VS_TAGCONTEXT_NO_globals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_class)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
      }

      // now update the external globals
      if (!(context_flags & VS_TAGCONTEXT_NO_globals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_file) &&
          !(context_flags & VS_TAGCONTEXT_ONLY_this_class)) {
         tag_list_context_globals(0, 0, lastid,
                                  true, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
         tag_list_context_imports(0, 0, lastid, tag_files,
                                  filter_flags, context_flags,
                                  num_matches, max_matches,
                                  exact_match, case_sensitive,
                                  visited, depth);
      }

      // all done
      errorArgs[1] = lastid;
      return (num_matches>0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // evaluate prefix expression and list members of class
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   int status = _c_get_type_of_prefix_recursive(errorArgs, tag_files, prefixexp, rt, visited);
   //say("MATCH_CLASS="rt.return_type" status="status" lua_return_flags="rt.return_flags);
   if (status && !(num_matches>0)) {
      return status;
   }

   context_flags = _CodeHelpTranslateReturnTypeFlagsToContextFlags(rt.return_flags);
   if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      context_flags |= VS_TAGCONTEXT_ALLOW_locals;
   }
   tag_clear_matches();
   tag_list_in_class(lastid, rt.return_type,
                     0, 0, tag_files,
                     num_matches, max_matches,
                     filter_flags, context_flags,
                     exact_match, case_sensitive,
                     rt.template_args, null,
                     visited, depth);

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

void _lua_disable_props()
{
   ctl_static_check_box.p_enabled       = 0;
   ctl_proto_check_box.p_enabled        = 0;
   ctl_access_check_box.p_enabled       = 0;
   ctl_transient_check_box.p_enabled    = 0;
   ctl_native_check_box.p_enabled       = 0;
   ctl_partial_check_box.p_enabled      = 0;
   ctl_const_check_box.p_enabled        = 0;
   ctl_inline_check_box.p_enabled       = 0;
   ctl_abstract_check_box.p_enabled     = 0;
   ctl_synchronized_check_box.p_enabled = 0;
   ctl_extern_check_box.p_enabled       = 0;
   ctl_forward_check_box.p_enabled      = 0;
   ctl_final_check_box.p_enabled        = 0;
   ctl_volatile_check_box.p_enabled     = 0;
   ctl_virtual_check_box.p_enabled      = 0;
   ctl_template_check_box.p_enabled     = 0;
   ctl_mutable_check_box.p_enabled      = 0;
}

defeventtab lua_keys;
def '('=auto_functionhelp_key;
def '.'=auto_codehelp_key;
def 'ENTER'=lua_enter;
def ' '= lua_space;
def '}'=lua_endbrace;
def 'TAB'=smarttab;

enum {
   TK_DO = 1,
   TK_ELSE,
   TK_ELSEIF,
   TK_END,
   TK_FOR,
   TK_FUNCTION,
   TK_IF,
   TK_LOCAL,
   TK_REPEAT,
   TK_THEN,
   TK_UNTIL,
   TK_WHILE
};

static int lua_tk:[] = {
   "do"        => TK_DO,
   "else"      => TK_ELSE,
   "elseif"    => TK_ELSEIF,
   "end"       => TK_END,
   "for"       => TK_FOR,
   "function"  => TK_FUNCTION,
   "if"        => TK_IF,
   "local"     => TK_LOCAL,
   "repeat"    => TK_REPEAT,
   "then"      => TK_THEN,
   "until"     => TK_UNTIL,
   "while"     => TK_WHILE
};

/**
 * Lua Begin/End statements
 *
 * Keyword:
 *    function ... end
 *    if ... then ... [ elseif ... then ... ] [ else ... ] end
 *    while ... do ... end
 *    for ... do ... end
 *    for ... in ... do ... end
 *    do ... end
 *    repeat ... until
 *
 * Punctuation:
 *    { ... }
 *    [ ... ]
 *    ( ... )
 *
 * Comment:
 *    --[[ ... ]]
 *
 * String:
 *    [[ ... ]]
 *
 */

/*
   Find begin statement for matching end statment (end | until)

   end   -> function ... end
            if ... then ... [ elseif ... then ... ] [ else ... ] end
            while ... do ... end
            for ... do ... end
            for ... in ... do ... end
            do ... end

            (requires special checks to handle empty do ... end vs. for ... do ... end and while ... do ... end)

   until -> repeat
*/
static int _lua_match_prev_word(_str word)
{
   int tk_stack[];
   int status;
   int tk = 0;
   int stack_top = 0;

   save_pos(auto p);
   if (lua_tk:[word]._varformat() == VF_EMPTY) {
      return(1);
   }
   tk_stack[stack_top] = lua_tk:[word];
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   status = search('[{}()\[\]]|\b(do|end|elseif|else|function|for|if|repeat|then|until|while)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) { // skip {} [] ()
         _str ch = get_text();
         if (ch == '}' || ch == ')' || ch == ']') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);
               return(1);
            }
         } else {
            restore_pos(p);
            return(1);
         }
      } else {
         word = get_match_text();
         int tktop = tk_stack[stack_top];
         tk = lua_tk:[word];
         switch (tk) {
         case TK_DO:
            if (tktop == TK_END) {
               // test for while/for ... do statements
               get_line(auto line);
               int col = pos('while|for', expand_tabs(line), 1, 'r');
               if (col > 0 && col < p_col) {
                  p_col = col;
               }
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_FOR:
         case TK_WHILE:
            // not likely to get here (see TK_DO), but implemented anyway
            if (tktop == TK_DO) {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_FUNCTION:
            // function() ... end
            if (tktop == TK_END) {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_REPEAT:
            // repeat ... until
            if (tktop == TK_UNTIL) {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_IF:
            // if ... then ...
            if (tktop == TK_THEN) {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_ELSEIF:
            // elseif ... then ...
            if (tktop == TK_THEN) {
               tk_stack[stack_top] = tk;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_ELSE:
            // else ... end
            if (tktop == TK_END) {
               tk_stack[stack_top] = tk;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_THEN:
            // if ... then ... elseif ... then ... else ... end
            if (tktop == TK_ELSE || tktop == TK_ELSEIF || tktop == TK_END) {
               tk_stack[stack_top] = tk;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case TK_END:
         case TK_UNTIL:
            // found end statement, increment token stack
            tk_stack[++stack_top] = tk;
            break;
         }
         if (stack_top < 0) {
            return(0);
         }
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(1);
}


/*
   Find next control statement

   function -> end
   if -> then -> [ elseif -> then -> ] [ else -> ] end
   while -> do -> end
   for -> do -> end
   do -> end
   repeat -> until
*/
static int _lua_match_next_word(_str word)
{
   int tk_stack[];
   int tk = 0;
   int stack_top = 0;
   int status;

   if (word == 'local') { // no can do
      return(1);
   }
   save_pos(auto p);
   if (lua_tk:[word]._varformat() == VF_EMPTY) {
      return(1);
   }
   tk_stack[stack_top] = lua_tk:[word];

   int cfg = _clex_find(0, 'g');
   if (cfg == CFG_KEYWORD) {
      status = _clex_find(KEYWORD_CLEXFLAG, 'n');
      if (status) {
         restore_pos(p);
         return(1);
      }
   }

   status = search('[{}()\[\]]|\b(do|end|elseif|else|function|for|if|repeat|then|until|while)\b', "rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);   // eof
         return(1);
      }
      cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) {  // skip {} () []
         _str ch = get_text();
         if (ch == '{' || ch == '(' || ch == '[') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff, true);
            restore_search(s1, s2, s3, s4, s5);
            if (status) {
               restore_pos(p);   // error'd
               return(1);
            }
         } else {
            restore_pos(p);   // error'd
            return(1);
         }
      } else {
         word = get_match_text();
         int tktop = tk_stack[stack_top];
         tk = lua_tk:[word];
         if (tk._varformat() == VF_EMPTY) {
            return(1);
         }
         switch (tk) {
         case TK_DO:
            // check for continuation of for/while statement
            if (tktop == TK_WHILE || tktop == TK_FOR) {
               tk_stack[stack_top] = tk;
               break;
            }
            // empty do statement, fall through
         case TK_FUNCTION:
         case TK_FOR:
         case TK_IF:
         case TK_REPEAT:
         case TK_WHILE:
            // begin new statement, increment token stack
            tk_stack[++stack_top] = tk;
            break;

         case TK_ELSE:
         case TK_ELSEIF:
            // check for continuation of if/then
            if (tktop == TK_THEN) {
               if (stack_top > 0) {
                  tk_stack[stack_top] = tk;  // if not top level then continue
               } else {
                  --stack_top;   // top-level of stack, stop on elseif/else
               }
            } else {
               restore_pos(p);   // error'd
               return(1);
            }
            break;

         case TK_END:
            switch (tktop) {  // end of statment, decrement token stack
            case TK_DO:
            case TK_ELSE:
            case TK_FUNCTION:
            case TK_THEN:
               --stack_top;
               break;
            default:
               restore_pos(p);   // error'd
               return(1);
            }
            break;

         case TK_THEN:
            // check for continuation of if/elseif
            if (tktop == TK_ELSEIF || tktop == TK_IF) {
               tk_stack[stack_top] = tk;
            } else {
               restore_pos(p);   // error'd
               return(1);
            }
            break;

         case TK_UNTIL:
            // end of statment for repeat
            if (tktop == TK_REPEAT) {
               --stack_top;
            } else {
               restore_pos(p);   // error'd
               return(1);
            }
            break;
         }
         if (stack_top < 0) {
            return(0);
         }
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(1);
}

/**
 * Block matching
 *
 * @param quiet   just return status, no messages
 * @return 0 on success, nonzero if no match
 */
int _lua_find_matching_word(boolean quiet)
{
   int status;
   save_pos(auto p);
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_KEYWORD && p_col > 0) {
      left(); cfg = _clex_find(0, 'g');
   }
   if (cfg == CFG_KEYWORD) {
      int start_col = 0;
      word := cur_identifier(start_col);
      restore_pos(p);
      if (lua_tk._indexin(word)) {
         _str dir = "";
         if (word == 'local') {
            restore_pos(p);
            return(1);

         } else if (word == 'end' || word == 'until') {
            p_col = start_col;
            status = _lua_match_prev_word(word);

         } else {
            status = _lua_match_next_word(word);
         }
         return(status);
      }
   }
   restore_pos(p);
   return(1);
}

/*
   Search backwards for statements to indent from
 */
static int _lua_indent_col(int syntax_indent)
{
   int col;
   save_pos(auto p);
   if (p_col > 1) {
      left();
   } else {
      up(); _end_line();
   }
   if (_clex_skip_blanks('-')) {
      restore_pos(p);
      return(0);
   }

   orig_col := p_col;
   orig_linenum := p_line;
   int nesting = 0;
   _str nest_ch = '';
   int status = search('[{}()]|\b(do|end|elseif|else|function|for|if|repeat|then|until|while)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) {
         _str ch = get_text();
         switch (ch) {
         case '(':
            if (nesting > 0 && nest_ch == ch) {
               --nesting;
            } else if (!nesting) {
               save_pos(auto p2);
               ++p_col;
               status = _clex_skip_blanks();
               if (!status && (p_line < orig_linenum || (p_line == orig_linenum && p_col < orig_col))) {
                  col = p_col;
               } else {
                  restore_pos(p2);
                  first_non_blank();
                  col = p_col + syntax_indent;
               }
               restore_pos(p);
               return col;
            }
            break;

         case ')':
            if (nesting > 0 && nest_ch == '(') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '(';
               ++nesting;
            }
            break;

         case '{':
            if (nesting > 0 && nest_ch == ch) {
               --nesting;
            } else if (!nesting) {
               // indent here
               first_non_blank();
               col = p_col + syntax_indent;
               restore_pos(p);
               return(col);
            }
            break;

         case '}':
            if (nesting > 0 && nest_ch == '{') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '{';
               ++nesting;
            }
            break;
         }
      } else {
         if (nesting > 0) {
            status = repeat_search();
            continue;
         }
         _str word = get_match_text();

         if (lua_tk:[word]._varformat() == VF_EMPTY) {
            return(1);
         }
         switch (lua_tk:[word]) {
         case TK_DO:
         case TK_ELSE:
         case TK_FUNCTION:
         case TK_REPEAT:
         case TK_THEN:
            // indent here
            first_non_blank();
            col = p_col + syntax_indent;
            restore_pos(p);
            return(col);

         case TK_ELSEIF:
         case TK_FOR:
         case TK_IF:
         case TK_WHILE:
            // you could maybe indent here, but still need a continuation keyword, so just use first col here
            first_non_blank();
            col = p_col;
            restore_pos(p);
            return(col);

         case TK_END:
         case TK_UNTIL:
            // column is matching begin statement
            status = _lua_match_prev_word(word);
            if (status) {
               restore_pos(p);
               return(0);
            }
            first_non_blank();
            col = p_col;
            restore_pos(p);
            return(col);
         }
      }
      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

/**
 * Find prev matching control block statement and return its
 * indent width
 *
 *    function ... end
 *    if ... then ... [ elseif ... then ... ] [ else ... ] end
 *    while ... do ... end
 *    for ... do ... end
 *    for ... in ... do ... end
 *    do ... end
 *    repeat ... until
 */
static int _lua_get_statement_indent(_str word)
{
   int width = -1;
   int orig_col = p_col;
   save_pos(auto p);
   first_non_blank();
   int status = _lua_match_prev_word(word);
   first_non_blank();
   if (orig_col != p_col) {
      width = p_col - 1;
   }
   restore_pos(p);
   return width;
}

/**
 * Return true if no matching end statement found at same indent
 * level
 */
static boolean _lua_expand_end(_str word)
{
   int status = 1;
   save_pos(auto p);
   first_non_blank();
   width := p_col;
   restore_pos(p);
   status = _lua_match_next_word(word);
   if (!status) { // found end statement
      first_non_blank();
      if (p_col != width) {
         status = 1;  // not matching indent
      }
   }
   restore_pos(p);
   return (status != 0);
}

boolean _lua_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);
   if (name_on_key(ENTER):=='nosplit-insert-line') {
      _end_line();
   }

   get_line(auto line);
   save_pos(auto p);
   first_non_blank();
   start_col := p_col;
   cfg := _clex_find(0, 'g');
   restore_pos(p);
   parse strip(line) with auto word .;

   if (cfg == CFG_KEYWORD && doSyntaxExpansion && (p_col >= start_col + length(word))) {
      if (word == 'repeat') {
         p_col = start_col;
         status := _lua_match_next_word(word);
         if (status) {
            insert_line(indent_string(start_col - 1):+'until');
            up(); _end_line();
         }
         restore_pos(p);
      }
   }

   col := -1;
   if (word == 'end' || word == 'until' || word == 'else' || word == 'elseif') {
      p_col = start_col;
      int status = _lua_match_prev_word(word);
      if (!status) {
         first_non_blank();
         indent_col := p_col;
         restore_pos(p);

         col = indent_col;
         if (word == 'else' || word == 'elseif') {
            col = col + syntax_indent;
         }

         // reindent current line?
         if (p_col >= start_col + length(word)) {
            if (start_col > indent_col) {
               replace_line(indent_string(indent_col - 1):+strip(line, 'L'));
               p_col = p_col - (start_col - indent_col);

            }
         }
      } else {
         restore_pos(p);
      }
   }

   if (col < 0) {
      col = _lua_indent_col(syntax_indent);
   }
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void lua_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_lua_expand_enter, true);
}

static SYNTAX_EXPANSION_INFO lua_space_words:[] = {
   'break'            => { "break" },
   'do'               => { "do ... end" },
   'elseif'           => { "elseif ... then" },
   'else'             => { "else ... end" },
   'end'              => { "end" },
   'for'              => { "for ... do ... end" },
   'function'         => { "function () ... end" },
   'if'               => { "if ... then" },
   'local'            => { "local" },
   'repeat'           => { "repeat ... until" },
   'return'           => { "return" },
   'then'             => { "then" },
   'until'            => { "until" },
   'while'            => { "while ... do ... end" },
};

int _lua_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, lua_space_words, prefix, min_abbrev);
}

static _str _lua_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);

   typeless status = 0;
   _str orig_line = "";
   get_line(orig_line);
   _str line = strip(orig_line, 'T');
   _str orig_word = strip(line);
   if (p_col != text_col(_rawText(line)) + 1) {
      return(1);
   }

   int width = -1;
   _str aliasfilename = '';
   _str word=min_abbrev2(orig_word, lua_space_words, name_info(p_index), aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if (word=='' && doSyntaxExpansion) {
      min_len := LanguageSettings.getMinimumAbbreviation(p_LangId);
      start_col := 0;
      idword := cur_identifier(start_col);
      if (idword:==substr('function', 1, length(idword)) && length(idword) > min_len) {
         parse orig_line with auto first_word auto second_word auto rest;
         // local function
         if (first_word:=='local' && second_word:==idword && rest == '') {
            word = 'local function';

         } else if (start_col > 1) {
            // [local] f = function
            parse orig_line with first_word '=' auto last_word;
            if (strip(last_word) :== idword) {
               word = 'function';
               orig_word = idword;
               save_pos(auto p);
               first_non_blank();
               width = p_col - 1;
               restore_pos(p);
            }
         }
      }

      if (word == '') {
         return(1);
      }
   }

   typeless block_info = "";
   typeless p2 = 0;
   line=substr(line, 1, length(line) - length(orig_word)):+word;
   if (width < 0) {
      width = text_col(_rawText(line), _rawLength(line) - _rawLength(word) + 1, 'i') - 1;
   }
   orig_word = word;
   word = lowcase(word);
   doNotify := true;
   clear_hotspots();

   if (word == 'if') {
      replace_line(line:+'  then'); _end_line(); add_hotspot();
      p_col -= 5; add_hotspot();

   } else if (word == 'elseif') {
      width = _lua_get_statement_indent(word);
      replace_line(indent_string(width):+'elseif  then'); _end_line(); add_hotspot();
      p_col -= 5; add_hotspot();

   } else if (word == 'else') {
      width = _lua_get_statement_indent(word);
      replace_line(indent_string(width)'else');
      if (_lua_expand_end(word)) {
         insert_line(indent_string(width)'end'); _end_line();
         up(); nosplit_insert_line();
         p_col = width + syntax_indent + 1;
      } else {
         _end_line();
         status = 1;
      }
     
   } else if (word == 'do') {
      if (_lua_expand_end(word)) {
         replace_line(line);
         insert_line(indent_string(width)'end');
         up(); nosplit_insert_line();
         p_col = width + syntax_indent + 1;
      } else {
         status = 1;
         doNotify = false;
      }

   } else if (word == 'for') {
      replace_line(line:+'  do'); _end_line(); add_hotspot();
      insert_line(indent_string(width)'end');
      up(); _end_line();  p_col -= 3; add_hotspot();

   } else if (word == 'function' || word == 'local function') {
      replace_line(line:+" ()"); _end_line(); add_hotspot();
      p_col -= 1; add_hotspot();
      insert_line(indent_string(width)'end');
      up(); _end_line();  p_col -= 2; add_hotspot();

   } else if (word == 'repeat') {
      save_pos(auto p);
      status = _lua_match_next_word(word);
      restore_pos(p);
      if (status) {
         replace_line(line);
         insert_line(indent_string(width)'until'); _end_line(); add_hotspot();
         up(); nosplit_insert_line();
         p_col = width+syntax_indent+1; add_hotspot();
         status = 0;
      } else {
         replace_line(line:+' '); _end_line();
         doNotify = false;
      }

   } else if (word == 'while') {
      replace_line(line:+'  do'); _end_line(); add_hotspot();
      insert_line(indent_string(width)'end');
      up();_end_line();  p_col -= 3; add_hotspot();

   } else if (word == 'until') {
      width = _lua_get_statement_indent(word);
      replace_line(indent_string(width)'until '); _end_line();

   } else if (word == 'end') {
      width = _lua_get_statement_indent(word);
      replace_line(indent_string(width)'end '); _end_line();

   } else if (word) {
      replace_line(line:+' '); _end_line();
      doNotify = false;

   } else {
      status = 1;
      doNotify = false;
   }
   show_hotspots();

   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

_command void lua_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _lua_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}

_command void lua_endbrace() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin('}');
   if (command_state() || p_window_state:=='I' ||
       p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
       _in_comment()) {
   } else if (_argument == '') {
      _str line = "";
      get_line(line);
      if (line == '}') {
         int status;
         save_pos(auto p);
         save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
         status = _find_matching_paren(def_pmatch_max_diff, true);
         restore_search(s1, s2, s3, s4, s5);
         first_non_blank();
         int col = p_col;
         restore_pos(p);
         if (!status && col > 0) {
            replace_line(indent_string(col-1):+'}');
            p_col = col + 1;
         }
      }
      _undo('S');
   }
}

/**
 * Lua <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int lua_smartpaste(boolean char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   typeless status = _clex_skip_blanks('m');
   if (!status) {
      word := cur_word(auto junk);
      if (word == 'elseif' || word == 'else') {
         save_pos(auto p);
         status = _lua_match_prev_word(word);
         if (!status) {
            first_non_blank(); col := p_col;
            restore_pos(p);
            _begin_select(); up(); _end_line();
            return(col);
         }
         return 0;

      } else if (word == 'end' || word == 'until') {
         p_col += length(word);

      } else if (get_text() == '}') {
         ++p_col;

      } else {
         _begin_select(); up(); _end_line();
      }
   }
   col := _lua_indent_col(syntax_indent);
   return col;
}

/**
 * Callback for determining if the current line is the first line
 * of a block statement.
 * <p>
 *
 * @param first_line
 * @param last_line
 * @param num_first_lines
 * @param num_last_lines
 *
 * @return boolean
 */

boolean _lua_find_surround_lines(int &first_line, int &last_line,
                                 int &num_first_lines, int &num_last_lines,
                                 boolean &indent_change,
                                 boolean ignoreContinuedStatements=false)
{
   indent_change = true;
   first_line = p_RLine;
   first_non_blank();
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return false;
   }
   status := 0;
   start_col := 0;
   word := cur_identifier(start_col);
   if (lua_tk:[word]._varformat() == VF_EMPTY) {
      return false;
   }
   switch (lua_tk:[word]) {
   case TK_LOCAL:
      p_col += length(word);
      c_next_sym();
      if (c_sym_gtkinfo() == 'function') {
         word = "function";
         break;
      }
      return false;

   case TK_DO:
   case TK_FOR:
   case TK_FUNCTION:
   case TK_IF:
   case TK_UNTIL:
   case TK_WHILE:
      break;
   default:
      return false;
   }

   first_line = p_RLine;
   num_first_lines = 1;
   status = _lua_match_next_word(word);
   if (status) {
      return false;
   }
   if (_clex_find(0, 'g') != CFG_KEYWORD) {
      return false;
   }
   word = cur_identifier(start_col);
   if (lua_tk:[word] == TK_END) {
      p_col += length(word);
   }
   num_last_lines=1;
   last_line = p_RLine;

   // make sure that it is at the end of the line
   p_col++;
   _clex_skip_blanks('h');
   if (p_RLine==last_line && !at_end_of_line()) {
      return false;
   }
   // success
   return true;
}

