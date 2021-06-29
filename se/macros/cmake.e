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
#endregion

using se.lang.api.LanguageSettings;

static const CMAKE_LANGUAGE_ID=   'cmake';

_command void cmake_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(CMAKE_LANGUAGE_ID);
}

defeventtab cmake_keys;
def 'ENTER'=cmake_enter;
def ' '= cmake_space;
def '('= cmake_paren;
def 'TAB'=smarttab;

static int _cmake_match_prev_word(_str word)
{
   _str kw_stack[];
   stack_top := 0;
   int status;
   save_pos(auto p);
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }

   kw_stack[stack_top] = word;
   status = search('[()]|\b(if|elseif|else|endif|foreach|endforeach|function|endfunction|macro|endmacro|while|endwhile)\b', "i-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) { // ()
         ch := get_text();
         if (ch == ')') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
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
         _str kw = kw_stack[stack_top];
         word = get_match_text();

         switch (word) {
         case 'if':
            if (kw == 'endif' || kw == 'else' || kw == 'elseif') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'foreach':
            if (kw == 'endforeach') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'function':
            if (kw == 'endfunction') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'macro':
            if (kw == 'endmacro') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'while':
            if (kw == 'endwhile') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'elseif':
         case 'else':
            if (kw == 'endif' || kw == 'elseif' || kw == 'else') {
               kw_stack[stack_top] = word;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'endif':
         case 'endfunction':
         case 'endmacro':
         case 'endwhile':
         case 'endforeach':
            kw_stack[++stack_top] = word;
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

static int _cmake_match_next_word(_str word)
{
   _str kw_stack[];
   stack_top := 0;
   int status;
   save_pos(auto p);
   kw_stack[stack_top] = word;

   int cfg = _clex_find(0, 'g');
   if (cfg == CFG_KEYWORD) {
      status = _clex_find(KEYWORD_CLEXFLAG, 'n');
      if (status) {
         restore_pos(p);
         return(1);
      }
   }

   status = search('[()]|\b(if|elseif|else|endif|foreach|endforeach|function|endfunction|macro|endmacro|while|endwhile)\b', "irh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      cfg = _clex_find(0, 'g');
      if (cfg != CFG_KEYWORD) { // ()
         ch := get_text();
         if (ch == '(') {
            save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
            status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
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
         _str kw = kw_stack[stack_top];
         word = get_match_text();

         switch (word) {
         case 'if':
         case 'foreach':
         case 'function':
         case 'while':
         case 'macro':
            kw_stack[++stack_top] = word;
            break;

         case 'endforeach':
            if (kw == 'foreach') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'endfunction':
            if (kw == 'function') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'endmacro':
            if (kw == 'macro') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'endwhile':
            if (kw == 'while') {
               --stack_top;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'elseif':
         case 'else':
            if (kw == 'if' || kw == 'elseif' || kw == 'else') {
               kw_stack[stack_top] = word;
            } else {
               restore_pos(p);
               return(1);
            }
            break;

         case 'endif':
            if (kw == 'if' || kw == 'elseif' || kw == 'else') {
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
 
static int _cmake_maybe_unindent_keyword()
{
   get_line(auto line); line = strip(line);

   switch (line) {
   case 'else':
   case 'elseif':
   case 'endif':
   case 'endforeach':
   case 'endfunction':
   case 'endmacro':
   case 'endwhile':
      break;

   default:
      return -1;
   }

   // continue
   width := -1;
   orig_col := p_col;
   save_pos(auto p);
   _first_non_blank();
   int status = _cmake_match_prev_word(line);
   if (!status) {
      _first_non_blank();
      if (orig_col != p_col) {
         width = p_col - 1;
      }
   }
   restore_pos(p);
   return width;
}

static int _cmake_indent_col(int syntax_indent)
{
   // search for previous command xxx(...)
   col := 0;
   save_pos(auto p);
   left(); _clex_skip_blanks('-');
   
   int status = search('[()]', "-rh@XSC");
   if (status) {
      top(); _first_non_blank();
      col = p_col;
      restore_pos(p);
      return(col);
   }

   ch := get_text();
   if (ch == '(') {
      // open paren case, indent
      _first_non_blank();
      col = p_col + syntax_indent;
      restore_pos(p);
      return(col);
   }

   // close-paren case, search to open
   status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
   if (status) {
      restore_pos(p);
      return(0);
   }
   
   // search for command name
   left(); status = _clex_skip_blanks('-h');
   if (status < 0) {
      restore_pos(p);
      return(0);
   }

   id := cur_identifier(col);
   cfg := _clex_find(0, 'g');
   if (id != '') {
      // default to command-name indent level
      _first_non_blank();
      col = p_col;

      if (cfg == CFG_KEYWORD) {
         switch (id) {
         case 'function':
         case 'macro':
         case 'foreach':
         case 'while':
         case 'if':
         case 'elseif':
         case 'else':
            col = p_col + syntax_indent;
            break;

         /*
         case 'endfunction':
         case 'endmacro':
         case 'endforeach':
         case 'endwhile':
         case 'endif':
         default:
            col = p_col;
            break;
        */
         }
      }
   }

   restore_pos(p);
   return(col);
}

bool _cmake_expand_enter()
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

   int col = _cmake_indent_col(syntax_indent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void cmake_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   generic_enter_handler(_cmake_expand_enter, true);
}
bool _cmake_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

static SYNTAX_EXPANSION_INFO cmake_space_words:[] = {
   'project'          => { "project()" },
   'message'          => { "message()" },
   'set'              => { "set()" },

   'foreach'          => { "foreach() ... endforeach()" },
   'function'         => { "function() ... endfunction()" },
   'macro'            => { "macro() ... endmacro()" },
   'while'            => { "while() ... endwhile()" },
   'if'               => { "if() ... endif()" },

   'else'             => { "else()" },
   'elseif'           => { "elseif()" },

   'endforeach'       => { "endforeach()" },
   'endfunction'      => { "endfunction()" },
   'endif'            => { "endif()" },
   'endmacro'         => { "endmacro()" },
   'endwhile'         => { "endwhile()" },
};

int _cmake_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, cmake_space_words, prefix, min_abbrev);
}

static _str _cmake_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

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
   _str word=min_abbrev2(orig_word, cmake_space_words, '', aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
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

   if (word == 'set' || word == 'message' || word == 'project') {
      replace_line(line:+"()"); _end_line(); add_hotspot(); p_col -= 1;

   } else if (word == 'function' || word == 'foreach' || word == 'macro' || word == 'if' || word == 'while') {
      replace_line(line:+"()"); _end_line(); add_hotspot();
      insert_line(indent_string(width)'end'word'()');
      up(); _end_line();  p_col -= 1; add_hotspot();

   } else if (word == 'elseif' || word == 'else') {
      col := _cmake_maybe_unindent_keyword();
      if (col >= 0) {
         line = indent_string(col):+word;
      }
      replace_line(line:+"()"); _end_line(); add_hotspot(); p_col -= 1;
      
   } else if (word == 'endforeach' || word == 'endfunction' || word == 'endmacro' || word == 'endwhile' || word == 'endif') {
      col := _cmake_maybe_unindent_keyword();
      if (col >= 0) {
         line = indent_string(col):+word;
      }
      replace_line(line:+"()"); _end_line();

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

_command void cmake_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _cmake_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}

_command void cmake_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   // Called from command line?
   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key('(');
      return;
   }

   if ((p_SyntaxIndent<0) || _in_comment() || _in_string()) {
      keyin('(');
      return;
   }

   col := _cmake_maybe_unindent_keyword();
   if (col >= 0) {
      get_line(auto line); line = strip(line);
      replace_line(indent_string(col):+line); _end_line();
   }
   keyin('(');
  
   // not the syntax expansion case, so try function help
   // auto_functionhelp_key();
}

/**
 * CMake <b>SmartPaste&reg;</b>
 *
 * @return destination column
 */
int cmake_smartpaste(bool char_cbtype, int first_col)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;
   typeless status = _clex_skip_blanks('m');
   if (!status) {
      _begin_select(); up(); _end_line();
   }
   col := _cmake_indent_col(syntax_indent);
   return col;
}

/**
 * Block matching
 *
 * @param quiet   just return status, no messages
 * @return 0 on success, nonzero if no match
 */
int _cmake_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
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

      switch (word) {
      case 'if':
      case 'foreach':
      case 'function':
      case 'macro':
      case 'while':
      case 'elseif':
      case 'else':
         status = _cmake_match_next_word(word);
         return(status);

      case 'endif':
      case 'endfunction':
      case 'endmacro':
      case 'endwhile':
      case 'endforeach':
         status = _cmake_match_prev_word(word);
         return(status);

      default:
         break;
      }
   }
   restore_pos(p);
   return(1);
}

