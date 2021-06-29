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
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cfcthelp.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "hotspots.e"
#import "notifications.e"
#import "pmatch.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

static const MATLAB_LANG_ID=    'matlab';

_command void matlab_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(MATLAB_LANG_ID);
}

defeventtab matlab_keys;
def 'ENTER' = matlab_enter;
def ' '     = matlab_space;
def 'TAB'   = smarttab;
def '('     = auto_functionhelp_key;

static int _matlab_indent_col(int syntax_indent)
{
   col := 0;
   nesting := 0;
   orig_col := p_col;
   orig_linenum := p_line;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   int status = search('[{}()]|\b(catch|case|classdef|elseif|else|end|enumeration|events|for|function|if|otherwise|methods|properties|switch|try|while)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      cfg := _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) {
         ch := get_text();
         switch (ch) {
         case '{':
            col = p_col + 1;
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
            break;

         case '(':
            if (nesting > 0) {
               --nesting;
            } else {
               col = p_col + 1;
               restore_pos(p);
               return(col);
            }
            break;

         case ')':
            ++nesting;
            break;
         }

      } else {
         word := get_match_text();
         if (word == 'end') {
            status = _matlab_match_prev_word(word);
            if (status) {
               restore_pos(p);
               return(0);
            }
            _first_non_blank();
            col = p_col;
            restore_pos(p);
            return(col);
         }

         _first_non_blank();
         col = p_col + syntax_indent;
         restore_pos(p);
         return(col);
      }

      if (!status) {
         status = repeat_search();
      }
   }
   restore_pos(p);
   return(0);
}

// begin/end words
static int matlab_be_words:[] = {
   "catch"        => 1,
   "classdef"     => 1,
   "elseif"       => 1,
   "else"         => 1,
   "end"          => 1,
   "enumeration"  => 1,
   "events"       => 1,
   "for"          => 1,
   "function"     => 1,
   "if"           => 1,
   "methods"      => 1,
   "parfor"       => 1,
   "properties"   => 1,
   "spmd"         => 1,
   "switch"       => 1,
   "try"          => 1,
   "while"        => 1
};

static int _matlab_get_statement_indent(_str word)
{
   width := -1;
   orig_col := p_col;
   save_pos(auto p);
   _first_non_blank();
   int status = _matlab_match_prev_word(word);
   _first_non_blank();
   if (orig_col != p_col) {
      width = p_col - 1;
   }
   restore_pos(p);
   return(width);
}

static bool _matlab_expand_end(_str word, int syntax_indent)
{
   if (!matlab_be_words._indexin(word) || word == 'end') {
      return(false);
   }

   // assuming indent is consistent/sane here
   save_pos(auto p);
   _first_non_blank();
   start_col := p_col;
   if (down()) {
      restore_pos(p);
      return(false);
   }
   _begin_line(); _clex_skip_blanks();
   col := p_col;
   if (col >= start_col + syntax_indent) {
      restore_pos(p);
      return(false);
   }
   if (col < start_col) {
      restore_pos(p);
      return(true);
   }

   restore_pos(p);
   status := false;
   nw := _matlab_match_next_word(word);
   if (!nw) {
      _first_non_blank(); col = p_col;
      if ((col < start_col) || (col >= start_col + syntax_indent)) {
         status = true;
      }
   }
   restore_pos(p);
   return(status);
}

static int _matlab_expand_case(int syntax_indent)
{
   save_pos(auto p);
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   _clex_skip_blanks('-');
   status := search('\b(switch|case|otherwise|function|classdef)\b', "-rh@XSC");
   if (status) {
      restore_pos(p);
      return(0);
   }
   col := 0;
   cfg := _clex_find(0, 'g');
   if (cfg == CFG_KEYWORD) {
      word := get_match_text();
      _first_non_blank();
      if (word == 'switch') {
         col = p_col + syntax_indent;
      } else if (word == 'case' || word == 'otherwise') {
         col = p_col;
      }
   }
   restore_pos(p);
   return(col);
}

bool _matlab_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   
   if (name_on_key(ENTER):=='nosplit-insert-line') {
      _end_line();
   }

   get_line(auto line);
   save_pos(auto p);
   _first_non_blank();
   start_col := p_col;
   cfg := _clex_find(0, 'g');
   restore_pos(p);
   parse strip(line) with auto word .;

   col := -1;
   if (word == 'end' || word == 'else' || word == 'elseif') {
      p_col = start_col;
      int status = _matlab_match_prev_word(word);
      if (!status) {
         _first_non_blank();
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

   } else if (word == 'otherwise') {
      _first_non_blank();
      col = _matlab_expand_case(syntax_indent);
      restore_pos(p);
      if (col && col < start_col) {
         replace_line(indent_string(col - 1):+strip(line, 'L'));
      }
      col += syntax_indent;

   } else if (word == 'methods' || word == 'properties' || word == 'events' || word == 'enumeration') {
      // insert end?
      expand_end := _matlab_expand_end(word, syntax_indent);
      if (expand_end) {
         insert_line(indent_string(start_col - 1)'end');
         up(); _end_line();
      }
   }

   if (col < 0) {
      col = _matlab_indent_col(syntax_indent);
   }

   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void matlab_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_matlab_expand_enter);
}
bool _matlab_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

static SYNTAX_EXPANSION_INFO matlab_space_words:[] = {
   'break'            => { "break" },
   'case'             => { "case" },
   'catch'            => { "catch" },
   'classdef'         => { "classdef ... end" },
   'continue'         => { "continue" },
   'do'               => { "do ... end" },
   'elseif'           => { "elseif" },
   'else'             => { "else ... end" },
   'end'              => { "end" },
   'enumeration'      => { "enumeration ... end" },
   'events'           => { "events ... end" },
   'for'              => { "for ... end" },
   'function'         => { "function ... end" },
   'if'               => { "if" },
   'methods'          => { "methods ... end" },
   'otherwise'        => { "otherwise" },
   'parfor'           => { "parfor ... end" },
   'properties'       => { "properties ... end" },
   'spmd'             => { "spmd ... end" },
   'switch'           => { "switch ... end" },
   'try'              => { "try ... catch ... end" },
   'return'           => { "return" },
   'while'            => { "while ... end" },
};

int _matlab_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, matlab_space_words, prefix, min_abbrev);
}
_str _matlab_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

static _str _matlab_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);
   typeless status = 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line, 'T');
   orig_word := strip(line);
   if (p_col != text_col(_rawText(line)) + 1) {
      return(1);
   }

   width := -1;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word, matlab_space_words, '', aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return(expandResult != 0);
   }
   if (word == '') {
      return(1);
   }
   typeless block_info = "";
   line = substr(line, 1, length(line) - length(orig_word)):+word;
   if (width < 0) {
      width = text_col(_rawText(line), _rawLength(line) - _rawLength(word) + 1, 'i') - 1;
   }
   orig_word = word;
   word = lowcase(word);
   doNotify := true;
   clear_hotspots();

   if (word == 'if') {
      replace_line(line:+' '); _end_line();

   } else if (word == 'elseif') {
      width = _matlab_get_statement_indent(word);
      replace_line(indent_string(width):+'elseif '); _end_line(); add_hotspot();

   } else if (word == 'else') {
      width = _matlab_get_statement_indent(word);
      replace_line(indent_string(width)'else '); _end_line();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end'); _end_line();
         up(); nosplit_insert_line();
         p_col = width + syntax_indent + 1;
      }

   } else if (word == 'for') {
      replace_line(line:+' '); _end_line();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end');
         up(); _end_line();
      }

   } else if (word == 'function') {
      replace_line(line:+" "); _end_line(); add_hotspot();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end');
         up(); _end_line();
      }

   } else if (word == 'while') {
      replace_line(line:+' '); _end_line();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end');
         up(); _end_line();  add_hotspot();
      }

   } else if (word == 'classdef' || word == 'methods' || word == 'properties' || word == 'events' || word == 'enumeration' || word == 'spmd') {
      replace_line(line:+' '); _end_line();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end');
         up();_end_line();  p_col -= 1; add_hotspot();
      }

   } else if (word == 'end') {
      width = _matlab_get_statement_indent(word);
      replace_line(indent_string(width)'end '); _end_line();

   } else if (word == 'try') {
      replace_line(line:+' '); _end_line();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'catch '); _end_line(); add_hotspot();
         insert_line(indent_string(width)'end'); _end_line();
         up(); up(); _end_line();  add_hotspot();
      }

   } else if (word == 'catch') {
      width = _matlab_get_statement_indent(word);
      replace_line(indent_string(width):+'catch '); _end_line(); add_hotspot();
      if (_matlab_expand_end(word, syntax_indent)) {
         insert_line(indent_string(width)'end'); _end_line();
      }

   } else if (word == 'case' || word == 'otherwise') {
      save_pos(auto p);
      _first_non_blank();
      col := _matlab_expand_case(syntax_indent);
      restore_pos(p);
      if (col && (col < width + 1)) {
         replace_line(indent_string(col - 1):+word:+' '); _end_line();
      } else {
         replace_line(line:+' '); _end_line();
      }

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
   return(status);
}

_command void matlab_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _matlab_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}

static int _matlab_match_prev_word(_str word)
{
   _str tk_stack[];
   int status;
   stack_top := 0;
   save_pos(auto p);
   if (!matlab_be_words._indexin(word)) {
      return(1);
   }
   tk_stack[stack_top] = word;
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   status = search('[{}()\[\]]|\b(catch|classdef|elseif|else|end|enumeration|events|for|function|if|methods|parfor|properties|spmd|switch|try|while)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      cfg := _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) { // skip {} [] ()
         ch := get_text();
         if (ch == '}' || ch == ')' || ch == ']') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, quiet:true, depth:stack_top+1);
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
         _str tktop = tk_stack[stack_top];
         switch (word) {
         case 'if':
            // if ...
            if (tktop == 'else' || tktop == 'elseif' || tktop == 'end') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'elseif':
            // elseif ...
            if (tktop == 'elseif') {
               // nothing
            } else if (tktop == 'else' || tktop == 'end') {
               tk_stack[stack_top] = word;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'else':
            // else ... end
            if (tktop == 'end') {
               tk_stack[stack_top] = word;
            } else {
               restore_pos(p);
               return(1);
            }
            break;


         case 'try':
            // try ... catch ... end
            if (tktop == 'catch' || tktop == 'end') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'catch':
            // catch ... end
            if (tktop == 'catch') {
               // nothing
            } else if (tktop == 'end') {
               tk_stack[stack_top] = word;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'end':
            // found end statement, increment token stack
            tk_stack[++stack_top] = word;
            break;

         default:
            // block keyword ... end
            if (tktop == 'end') {
               --stack_top;
            } else {
               restore_pos(p);
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

static int _matlab_match_next_word(_str word)
{
   _str tk_stack[];
   stack_top := 0;
   int status;

   save_pos(auto p);
   if (!matlab_be_words._indexin(word)) {
      return(1);
   }
   tk_stack[stack_top] = word;

   cfg := _clex_find(0, 'g');
   if (cfg == CFG_KEYWORD) {
      status = _clex_find(KEYWORD_CLEXFLAG, 'n');
      if (status) {
         restore_pos(p);
         return(1);
      }
   }

   status = search('[{}()\[\]]|\b(catch|classdef|elseif|else|end|enumeration|events|for|function|if|methods|parfor|properties|spmd|switch|try|while)\b', "rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);   // eof
         return(1);
      }
      cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) {  // skip {} () []
         ch := get_text();
         if (ch == '{' || ch == '(' || ch == '[') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, quiet:true, depth:stack_top+1);
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
         _str tktop = tk_stack[stack_top];
         switch (word) {
         case 'else':
         case 'elseif':
            // check for continuation of if
            if (tktop == 'if' || tktop == 'elseif') {
               if (stack_top > 0) {
                  tk_stack[stack_top] = word;  // if not top level then continue
               } else {
                  --stack_top;   // top-level of stack, stop on elseif/else
               }
            } else {
               restore_pos(p);   // error'd
               return(1);
            }
            break;

         case 'catch':
            if (tktop == 'try' || tktop == 'catch') {
               if (stack_top > 0) {
                  tk_stack[stack_top] = word;  // if not top level then continue
               } else {
                  --stack_top;   // top-level of stack
               }
            }
            break;

         case 'end':
            --stack_top;
            break;

         default:
            // begin new statement, increment token stack
            tk_stack[++stack_top] = word;
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
int _matlab_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   int status;
   save_pos(auto p);
   cfg := _clex_find(0, 'g');
   if (cfg != CFG_KEYWORD && p_col > 0) {
      left(); cfg = _clex_find(0, 'g');
   }
   if (cfg == CFG_KEYWORD) {
      start_col := 0;
      word := cur_identifier(start_col);
      restore_pos(p);
      if (matlab_be_words._indexin(word)) {
         dir := "";
         if (word == 'end') {
            p_col = start_col;
            status = _matlab_match_prev_word(word);

         } else {
            status = _matlab_match_next_word(word);
         }
         return(status);
      }
   }
   restore_pos(p);
   return(1);
}

/**
 * Matlab <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int matlab_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   typeless status = _clex_skip_blanks('m');
   if (!status) {
      word := cur_word(auto junk);
      if (word == 'elseif' || word == 'else' || word == 'end') {
         save_pos(auto p);
         status = _matlab_match_prev_word(word);
         if (!status) {
            _first_non_blank(); col := p_col;
            restore_pos(p);
            _begin_select(); up(); _end_line();
            return(col);
         }
         return(0);

      } else if (word == 'case' || word == 'otherwise') {
         _first_non_blank();
         col := _matlab_expand_case(syntax_indent);
         _begin_select(); up(); _end_line();
         return(col);

      } else if (get_text() == '}') {
         ++p_col;

      } else {
         _begin_select(); up(); _end_line();
      }
   }

   col := _matlab_indent_col(syntax_indent);
   return(col);
}

int _matlab_fcthelp_get_start(_str (&errorArgs)[],
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

int _matlab_fcthelp_get(_str (&errorArgs)[],
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

int _matlab_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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
   errorArgs._makeempty();
   tag_return_type_init(prefix_rt);
   tag_clear_matches();
   if (_chdebug) {
      isay(depth,"_matlab_find_context_tags: lastid="lastid" prefixexp="prefixexp" otherinfo="otherinfo);
   }

   // find more details about the current tag
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class, auto cur_package,
                                         visited, depth+1);
   if (cur_context == "" && (context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {
      errorArgs[1] = lastid;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // get the tag file list
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   num_matches := 0;
   tag_list_symbols_in_context(lastid, "", 0, 0, tag_files, '',
                               num_matches, max_matches,
                               filter_flags, context_flags,
                               exact_match, case_sensitive,
                               visited, depth+1);

   // Return 0 indicating success if anything was found
   errorArgs[1] = lastid;
   int status = (num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND : 0;
   return(status);
}

int _matlab_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "matlab", "", "", "", false, withRefs, useThread, forceRebuild);
}
