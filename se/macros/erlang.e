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
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autocomplete.e"
#import "c.e"
#import "cfcthelp.e"
#import "codehelputil.e"
#import "context.e"
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

defeventtab erlang_keys;
def 'ENTER'=erlang_enter;
def ' '=erlang_space;


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

static bool _erlang_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   typeless status=0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(true);
   }
   width := 0;
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,erlang_space_words,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   if ( word=='') return(true);

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

_command erlang_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
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
   int status = _find_matching_paren(def_pmatch_max_diff_ksize, true);
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

   first_col := 1;
   save_pos(auto last_tk_pos);

   hit_func_sep := false;
   hit_expr_sep := false;
   nesting := 0;
   nest_ch := "";
   int status = search('[.;,(){}]|<<|>>|->|\b(case|catch|end|fun|if|receive|try)\b', "-rh@XSC");
   for (;;) {
      if (status) {
         restore_pos(p);
         return(1);
      }
      int cfg = _clex_find(0, 'g');
      word := get_match_text();
      if (cfg != CFG_KEYWORD) {
         switch (word) {
         case '.':
            if (!nesting) {
               save_pos(last_tk_pos);
               _first_non_blank();
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
                  _first_non_blank();
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
                  _first_non_blank();
                  first_col = p_col;
                  restore_pos(p);
                  return (first_col);
               } else {
                  _first_non_blank();
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
                  _first_non_blank();
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
               _first_non_blank();
               first_col = p_col;
               restore_pos(p);
               return (first_col + syntax_indent);
            }
            break;

         case "end":
            if (_erlang_find_matching_block_col() == 0) {
               if (!hit_func_sep) {
                  _first_non_blank();
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

bool _erlang_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   SyntaxIndent := p_SyntaxIndent;
   int col = _erlang_indent_col(SyntaxIndent);
   if (col) {
      indent_on_enter(0, col);
      return(false);
   }
   return(true);
}

_command void erlang_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   generic_enter_handler(_erlang_expand_enter);
}
bool _erlang_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}

static int erlang_before_id(VS_TAG_IDEXP_INFO &idexp_info,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth)
{
   status := 0;

   return VSCODEHELPRC_CONTEXT_NOT_VALID;
}

int _erlang_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                                VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   status := _do_default_get_expression_info(PossibleOperator, idexp_info, visited, depth);
   if (status) {
      return status;
   }

   save_pos(auto orig_pos);
   _GoToROffset(idexp_info.lastidstart_offset);
   if (p_col > 1) {
      left();
      _clex_skip_blanks('-');
      ch := get_text();
      if (ch == ":" || ch == '#' || ch == '.') {
         left();
         _clex_skip_blanks('-');

         tag_idexp_info_init(auto before_info);
         status = _do_default_get_expression_info(false, before_info, visited, depth);
         if (status) {
            return status;
         }

         idexp_info.prefixexp = before_info.lastid :+ ":" :+ idexp_info.prefixexp;
         idexp_info.prefixexpstart_offset = before_info.lastidstart_offset;
      }
   }

   restore_pos(orig_pos);
   return(0);
}

int _erlang_fcthelp_get_start(_str (&errorArgs)[],
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
int _erlang_fcthelp_get(_str (&errorArgs)[],
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

int _erlang_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                              _str lastid,int lastidstart_offset,
                              int info_flags,typeless otherinfo,
                              bool find_parents,int max_matches,
                              bool exact_match,bool case_sensitive,
                              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   if (_chdebug) {
      isay(depth, "_erlang_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   }
   // make sure that the context doesn't get modified by a background thread.
   errorArgs._makeempty();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   // find more details about the current tag
   cur_scope_seekpos := 0;
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_flags, 
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_context, auto cur_class, auto cur_package,
                                         visited, depth+1);
   if (cur_context == "" && (context_flags & SE_TAG_CONTEXT_ONLY_INCLASS)) {
      errorArgs[1]=lastid;
      if (_chdebug) {
         isay(depth, "_erlang_find_context_tags: NO CURRENT CONTEXT");
      }
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   search_class := "";
   if (_last_char(prefixexp) == ':') {
      search_class = prefixexp;
      search_class = stranslate(search_class, VS_TAGSEPARATOR_package, ':');
   }

   // get the tag file list
   tag_clear_matches();
   tag_files := tag_find_context_tags_filenamea(p_LangId, context_flags);

   // try to match the symbol in the current context
   num_matches := 0;
   if (_haveContextTagging()) {
      context_flags |= SE_TAG_CONTEXT_FIND_LENIENT;
   } else {
      tag_files._makeempty();
      context_flags |= SE_TAG_CONTEXT_ONLY_CONTEXT;
   }
   tag_list_symbols_in_context(lastid, search_class, 
                               0, 0, tag_files, "",
                               num_matches, max_matches,
                               filter_flags, context_flags,
                               exact_match, case_sensitive,
                               visited, depth+1);

   if (_chdebug) {
      isay(depth, "_erlang_find_context_tags: found "num_matches);
      tag_dump_matches("_erlang_find_context_tags: ", depth+1);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1]=lastid;
   int status=(num_matches == 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
   return(status);
}

int _erlang_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   ext := "erlang";
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"erlang") && !forceRebuild) {
      return(0);
   }

   // The user does not have an extension specific tag file for erlang
   erlang_dir := "";
   if (_isWindows()) {
      //erlang_dir = _ntRegGetErlangPath();
   }
   if (erlang_dir=="") {
      erlang_dir=path_search("erlc","","P");
      if (erlang_dir!="") {
         erlang_dir=_strip_filename(erlang_dir,"n");
      }
   }
   //say("_erlang_MaybeBuildTagFile H"__LINE__": erlang_dir="erlang_dir);
   if (_isUnix()) {
      if (erlang_dir=="" || erlang_dir=="/" || erlang_dir=="/usr/" || erlang_dir=="/usr/bin/") {
         erlang_dir=latest_version_path("/usr/local/erlang");
         if (erlang_dir=="") {
            erlang_dir=latest_version_path("/opt/erlang");
         }
      }
   }
   
   erl_modules := "";
   erl_headers := "";
   if (erlang_dir != "") {
      _maybe_strip(erlang_dir, FILESEP);
      _maybe_strip(erlang_dir, FILESEP:+"bin");
      path := erlang_dir;
      _maybe_append_filesep(path);
      source_path := file_match("-p "_maybe_quote_filename(path:+"lib"), 1);
      if (source_path != "") {
         path=path:+"lib":+FILESEP;
      }
      erl_modules = _maybe_quote_filename(path:+"*.erl");
      erl_headers = _maybe_quote_filename(path:+"*.hrl");
      //say("_erlang_MaybeBuildTagFile H"__LINE__": erl_modules="erl_modules);
      //say("_erlang_MaybeBuildTagFile H"__LINE__": erl_headers="erl_headers);
   }

   erlang_builtins := ext_builtins_path(ext,"erlang");
   //say("_erlang_MaybeBuildTagFile H"__LINE__": erlang_builtins="erlang_builtins);
   return ext_BuildTagFile(tfindex,tagfilename,ext,"Erlang Libraries", 
                           recursive:true, 
                           _maybe_quote_filename(erl_modules):+" ":+_maybe_quote_filename(erl_headers),
                           erlang_builtins, withRefs, useThread);
}

