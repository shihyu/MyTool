////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#require "se/lang/api/LanguageSettings.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "cutil.e"
#import "notifications.e"
#import "pmatch.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#endregion

using se.lang.api.LanguageSettings;

defload()
{
   _str setup_info='MN=Erlang,TABS=+4,MA=1 74 1,':+
                   'KEYTAB=erlang-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_,LN=Erlang,CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 ':+   // <Syntax indent amount>  <expansion on/off>
                    '1 0 4 ':+ // <min abbrev> <not used> <not used>
                    '1 1';     //notused> <notused>

   _str be_info='(begin),(case),(fun),(if),(receive),(try)|(end)';
   _CreateLanguage("erlang", "Erlang", setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("erl", "erlang");
   _CreateExtension("hrl", "erlang");
}

defeventtab erlang_keys;
def 'ENTER'=erlang_enter;
def ' '=erlang_space;

int _erlang_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   _str ext="erlang";
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,ext)) {
      return(0);
   }
   return 0;
}

_command void erlang_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage("erlang");
}

/**
 * SYNTAX EXPANSION
 * 
 */

static SYNTAX_EXPANSION_INFO erlang_space_words:[] = {
   '-define'     => { "-define( ... )." },
   '-export'     => { "-export( ... )." },
   '-ifdef'      => { "-ifdef( ... )." },
   '-ifndef'     => { "-ifndef( ... )." },
   '-include'    => { "-include( ... )." },
   '-module'     => { "-module( ... )." },
   '-record'     => { "-record( ... )." },
   '-undef'      => { "-undef( ... )." },
   '-else'       => { "-else." },
   '-endif'      => { "-endif." },
   'case'        => { "case ... end" },
   'fun'         => { "fun (...) -> end" },
   'if'          => { "if ... end" },
   'receive'     => { "receive ... end" },
   'try'         => { "try ... end" },
   'after'       => { "after" },
   'catch'       => { "catch" },
   'end'         => { "end" },
   'throw'       => { "throw" },
   'when'        => { "when" },
};

static boolean _erlang_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   typeless status=0;
   _str orig_line="";
   get_line(orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word=strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   int width=0;
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,erlang_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=='') return(1);

   typeless block_info="";
   typeless p2=0;
   line=substr(line,1,length(line)-length(orig_word)):+word;
   width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   orig_word=word;
   word=lowcase(word);
   doNotify := true;
   if (word == 'if' || word == 'receive' || word == 'try') {
      replace_line(line:+' ');
      insert_line(indent_string(width)'end');
      up();_end_line();
   } else if (word == 'case') {
      replace_line(line:+'  of');
      insert_line(indent_string(width)'end');
      up();_end_line(); p_col -= 3;
   } else if (word == 'fun') {
      replace_line(line:+"() -> end");
      _end_line(); p_col -= 8;
   } else if (word == '-module' || word == '-export' || word == '-define' ||
              word == '-include' || word == '-undef' || word == '-ifdef' ||
              word == '-ifndef' || word == '-record') {
      replace_line(line:+"().");
      _end_line(); p_col -= 2;
   } else if (word == '-else' || word == '-endif') {
      replace_line(line:+".");
      _end_line();
   } else if (word) {
      replace_line(line:+" ");
      _end_line();
      doNotify = (line != orig_line);
   } else {
      doNotify = false;
      status=1;
   }

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return status;
}

int _erlang_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, erlang_space_words, prefix, min_abbrev);
}

_command erlang_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   // Short-circuit "if" operator in action here!
   if( command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)        ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is SyntaxIndent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _erlang_expand_space()
      ) {
      // If this was not the first space character typed, then add another space character
      if( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if( _argument=='' ) {
      _undo('S');
   }
}

/**
 * SYNTAX INDENT
 * 
 */

static int _erlang_find_matching_block_col()
{
   save_pos(auto p);
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   int status = _find_matching_paren(def_pmatch_max_diff, true);
   restore_search(s1, s2, s3, s4, s5);
   if (status) {
      restore_pos(p);   // error'd
      return(1);
   }
   return (0);
}

int _erlang_indent_col(int syntax_indent)
{
   orig_col := p_col;
   orig_linenum := p_line;

   save_pos(auto p);
   if (p_col == 1) {
      up(); _end_line();
   } else {
      left();
   }
   _clex_skip_blanks('-');

   int first_col = 1;
   save_pos(auto last_tk_pos);

   boolean hit_func_sep = false;
   boolean hit_expr_sep = false;
   int nesting = 0;
   _str nest_ch = '';
   int status = search('[.;,(){}]|<<|>>|->|\b(case|catch|end|fun|if|receive|try)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      _str word = get_match_text();
      if (cfg != CFG_KEYWORD) {
         switch (word) {
         case '.':
            if (!nesting) {
               save_pos(last_tk_pos);
               first_non_blank();
               first_col = p_col;
               if (first_col == 1) {
                  restore_pos(p);
                  return (first_col);
               }
               restore_pos(last_tk_pos);
               hit_func_sep = true;
            }
            break;

         case ';':
            if (!nesting) {
               if (!hit_expr_sep && !hit_func_sep) {
                  save_pos(last_tk_pos);
                  first_non_blank();
                  first_col = p_col;
                  if (first_col == 1) {
                     restore_pos(p);
                     return (first_col);
                  }
                  restore_pos(last_tk_pos);
                  hit_func_sep = true;
               }
            }
            break;

         case '->':
            if (!nesting) {
               if (hit_expr_sep) {
                  restore_pos(last_tk_pos);
                  first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  return (first_col);
               } else {
                  first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  if (hit_func_sep) {
                     return (first_col);
                  } else {
                     return (first_col + syntax_indent);
                  }
               }
            }
            break;

         case ',':
            if (!nesting) {
               if (!hit_expr_sep && !hit_func_sep) {
                  save_pos(last_tk_pos);
                  hit_expr_sep = true;
               }
            }
            break;

         case '(':
         case '{':
         case '<<':
            if (nesting > 0 && nest_ch == word) {
               --nesting;
            } else if (!nesting) {
               save_pos(last_tk_pos);
               ++p_col;
               status = _clex_skip_blanks();
               if (!status && (p_line < orig_linenum || (p_line == orig_linenum && p_col < orig_col))) {
                  first_col = p_col + length(word) - 1;
               } else {
                  restore_pos(last_tk_pos);
                  first_non_blank();
                  first_col = p_col + syntax_indent;
               }
               restore_pos(p);
               return first_col;
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

         case '}':
            if (nesting > 0 && nest_ch == '{') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '{';
               ++nesting;
            }
            break;

         case '>>':
            if (nesting > 0 && nest_ch == '<<') {
               ++nesting;
            } else if (!nesting) {
               nest_ch = '<<';
               ++nesting;
            }
            break;
         }
         status = repeat_search();
         continue;
      } else {
         if (nesting > 0) {
            status = repeat_search();
            continue;
         }
         switch (word) {
         case "begin":
         case "case":
         case "fun":
         case "if":
         case "receive":
         case "try":
            if (!hit_func_sep) {
               first_non_blank();
               first_col = p_col;
               restore_pos(p);
               return (first_col + syntax_indent);
            }
            break;

         case "end":
            if (_erlang_find_matching_block_col() == 0) {
               if (!hit_func_sep) {
                  first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  return (first_col);
               }
            }
            break;
         }
         status = repeat_search();
         continue;
      }
      break;
   }
   restore_pos(p);
   return 1;
}

boolean _erlang_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;
   int col = _erlang_indent_col(SyntaxIndent);
   if (col) {
      indent_on_enter(0, col);
      return(0);
   }
   return(1);
}

_command void erlang_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   generic_enter_handler(_erlang_expand_enter);
}
