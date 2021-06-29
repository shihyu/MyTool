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
#include "project.sh"
#import "adaptiveformatting.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/ui/AutoBracketMarker.e"
#require "se/debug/dbgp/DBGpOptions.e"
#require "se/debug/dbgp/dbgp.e"
#require "se/debug/pydbgp/pydbgp.e"
#require "se/net/ServerConnection.e"
#import "alias.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "c.e"
#import "cfcthelp.e"
#import "cjava.e"
#import "compile.e"
#import "csymbols.e"
#import "cutil.e"
#import "debug.e"
#import "debuggui.e"
#import "diffprog.e"
#import "dir.e"
#import "env.e"
#import "gradle.e"
#import "groovy.e"
#import "help.e"
#import "hotspots.e"
#import "java.e"
#import "javacompilergui.e"
#import "main.e"
#import "notifications.e"
#import "optionsxml.e"
#import "os2cmds.e"
#import "pythonopts.e"
#import "picture.e"
#import "pmatch.e"
#import "projconv.e"
#import "project.e"
#import "refactor.e"
#import "slickc.e"
#import "smartp.e"
#import "sbt.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "vc.e"
#import "wkspace.e"
#import "surround.e"
#endregion

using se.lang.api.LanguageSettings;
using se.ui.AutoBracketMarker;
using namespace se.debug.dbgp;

static se.debug.pydbgp.PydbgpConnectionMonitor g_ScalaDbgpMonitor;

static const SCALA_LANG_ID=    'scala';
static const SCALA_SINGLE_FILE_APPTYPE = 'scala';

_str def_scala_home;
_str gCancelledCompiler;   // Used to cancel an auto-tagging of the scala compiler libraries.
static _str lastDebugXmlFile;

/**
 * Version of Scala we should tag libraries for.  We should 
 * only use this as a fallback if we can't determine the version 
 * for the configured Scala compiler. 
 */
_str def_default_scala_compiler_version = '2.12.2';

// States the auto-tagging process can be in.
#define SAS_UNKNOWN 0
#define SAS_NOT_TAGGED 1
#define SAS_TAGGED 2
#define SAS_CANCELLED 3
int def_scala_autotag_state = SAS_UNKNOWN;

definit()
{
   gCancelledCompiler='';
}

_command void scala_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(SCALA_LANG_ID);
}

static SYNTAX_EXPANSION_INFO scala_space_words:[] = {
   'def'       => { "def" },
   'object'    => { "object" },
   'catch'     => { "catch { ... }" },
   'class'     => { "class" },
   'else if'   => { "else if ( ... ) { ... }" },
   'else'      => { "else { ... }" },
   'trait'     => { "trait" },
   'package'   => { "package" },
   'for'       => { "for (...)" },
   'if'        => { "if (...)" },
   'try'       => { "try { ... } catch { ... }" },
   'while'     => { "while (...)" },
};

int _scala_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, scala_space_words, prefix, min_abbrev);
}
bool _scala_find_surround_lines(int &first_line, int &last_line,
                               int &num_first_lines, int &num_last_lines,
                               bool &indent_change,
                               bool ignoreContinuedStatements=false) {
   return _c_find_surround_lines(first_line,last_line,num_first_lines,num_last_lines,indent_change,ignoreContinuedStatements);
}

// Returns the start column of the statement associated with the innermost
// brace.  If no leading '{' is found, returns 0.
static int enclosing_stmt_start_col() {
   save_pos(auto pp);
   balance := 0;

   for (;;) {
      status := search('[{}]', '-L@XCS');
      if (status != 0) {
         restore_pos(pp);
         return 0;
      }
      got := get_text();
      if (got == '{') {
         if (balance == 0) {
            _first_non_blank();
            cc := p_col;
            restore_pos(pp);
            return cc;
         } else {
            balance -= 1;
         }
      } else if (got == '}') {
         balance += 1;
      }

      if (prev_char() < 0) {
         restore_pos(pp);
         return 0;
      }
   }
}

static _str else_space_words[] = { 'else', 'else if' };
static _str _scala_expand_space()
{
   expansion_start := _QROffset();
   expansion_end := 0L;
   semicolon_case := false; //(last_event()==';');
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT|AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   noSpaceBeforeParen := p_no_space_before_paren;
   _str maybespace=(noSpaceBeforeParen)?'':' ';
   _str parenspace=(p_pad_parens)? ' ':'';
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
   _str word=min_abbrev2(orig_word, scala_space_words, '', aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return(expandResult != 0);
   }
   brace_before := "";
   if_special_case := false;
   pick_else_or_else_if := false;
   else_special_case := false;
   if ( word=='' && doSyntaxExpansion) {
      // Check for } else
      _str first_word, second_word, rest;
      parse orig_line with first_word second_word rest;
      if (!def_always_prompt_for_else_if && first_word=='}' && second_word!='' && rest=='' && second_word=='else') {
         //Can't force user to use modal dialog insead of just typing "} else {"
         //We need a modeless dialog so user can keep typing.
         return(1);
      } else if (!def_always_prompt_for_else_if && second_word=='' && length(first_word)>1 && first_word:=='}else') {
         //Can't force user to use modal dialog insead of just typing "}else {"
         //We need a modeless dialog so user can keep typing.
         return(1);
      } else if (first_word=='}' && second_word!='' && rest=='' && second_word:==substr('else',1,length(second_word))) {
         brace_before='} ';
         first_word=second_word;
         pick_else_or_else_if=true;
      } else if (second_word=='' && length(first_word)>1 && first_word:==substr('}else',1,length(first_word))) {
         brace_before='}';
         first_word=substr(first_word,2);
         pick_else_or_else_if=true;
      } else if (first_word=='}' && second_word!='' && rest=='' && second_word:==substr('catch',1,length(second_word))) {
         word='} catch';
         else_special_case=true;
         //if_special_case=true;
      } else if (second_word=='' && length(first_word)>1 && first_word:==substr('}catch',1,length(first_word))) {
         word='}catch';
         else_special_case=true;
         //if_special_case=true;
      } else if (first_word=='}' && second_word!='' && rest=='' && second_word:==substr('finally',1,length(second_word))) {
         word='} finally';
         else_special_case=true;
      } else if (second_word=='' && length(first_word)>1 && first_word:==substr('}finally',1,length(first_word))) {
         word='}finally';
         else_special_case=true;
      // Check for else if or } else if
      } else if (first_word=='else' && orig_word==substr('else if',1,length(orig_word))) {
         word='else if';
         if_special_case=true;
      } else if (second_word=='else' && rest!='' && orig_word==substr('} else if',1,length(orig_word))) {
         word='} else if';
         if_special_case=true;
      } else if (first_word=='}else' && second_word!='' && orig_word==substr('}else if',1,length(orig_word))) {
         word='}else if';
         if_special_case=true;
      } else {
         return(1);
      }
   } else if (!def_always_prompt_for_else_if && orig_word=='else' && word=='else') {
      //Can't force user to use modal dialog insead of just typing "}else {"
      //We need a modeless dialog so user can keep typing.
      return(1);
   } else if (orig_word=='else' && word=='else') {
      pick_else_or_else_if=true;
   }

   if (pick_else_or_else_if) {
      word=min_abbrev2('els',else_space_words,'','');
      switch (word) {
      case 'else':
         word=brace_before:+word;
         else_special_case=true;
         break;
      case 'elseif':
      case 'else if':
         word=brace_before:+word;
         if_special_case=true;
         break;
      default:
         return(1);
      }
   }

   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   /*if ( semicolon_case ) {
      insertBraceImmediately = false;
      if (!c_semicolon_words._indexin(word)) {
         return 1;
      }
   } */
   bes_style := beaut_style_for_keyword(word, auto gotaval);
   style2 := bes_style == BES_BEGIN_END_STYLE_2;
   style3 := bes_style == BES_BEGIN_END_STYLE_3;
   bracespace := ' ';
   e1 := " {";
   if (! ((word=='do' || word=='try' || word=='finally' || word=='}finally' || word=='} finally') && !style2 && !style3) ) {
      if ( style2 || style3 || !insertBraceImmediately ) {
         e1='';
      } else if (word=='}else' || word=='}finally') {
         e1='{';
      }
   } else if (last_event()=='{') {
      e1='{';
      bracespace='';
   }
   if (semicolon_case) e1=' ;';
   if (word == '') {
      if (orig_word == 'case') {
         // Auto-indent line to the correct indent for our settings.
         enc := enclosing_stmt_start_col();
         if (enc > 0) {
            indent := enc + beaut_case_indent() - 1;
            replace_line(indent_string(indent):+'case');
         }
         end_line();
      }
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
   set_surround_mode_start_line();
   clear_hotspots();
   if (word == 'if' || word=='else if' || word == 'while' || word == 'for' || if_special_case) {
      replace_line(line:+maybespace:+'(':+parenspace:+parenspace:+')':+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word),true);
      //if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
      //_end_line(); add_hotspot();
      //p_col = p_col - 1; add_hotspot();
   } else if ( word=='else') {
      typeless p;
      typeless s1,s2,s3,s4;
      save_pos(p);
      save_search(s1,s2,s3,s4);
      up();_end_line();
      search('[^ \t\n\r]','@-rhXc');
      if (get_text()=='}') {
         insertBraceImmediately = true;
      } else {
         e1=' ';
         insertBraceImmediately = false;
      }
      restore_search(s1,s2,s3,s4);
      restore_pos(p);
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      _end_line();

      doNotify = (insertBraceImmediately || e1 != '');
   } else if (else_special_case || word=='finally' || word == '}finally' || word == '} finally' || word=='catch') {
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
      _end_line();
   } else if ( word=='try' ) {
      surround_end_line := 0;
      num_end_lines := 2;
      if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId)) ++num_end_lines;
      if (style2 || style3) ++num_end_lines;
      replace_line(line:+e1);
      if (!style3) {
         if (style2) {
            insert_line(indent_string(width)'{');
         }
         cuddleElse := LanguageSettings.getCuddleElse(p_LangId);
         if (!cuddleElse) {
            insert_line(indent_string(width)'}');
            surround_end_line=p_line+1;
            insert_line(indent_string(width)'catch':+maybespace'('parenspace:+parenspace')'e1);
            ++num_end_lines;
         } else {
            insert_line(indent_string(width)'}'bracespace'catch':+e1);
            surround_end_line=p_line+1;
         }
         _end_line();
         p_col -= (length(e1)+1);
         add_hotspot();
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
         up(1);
         if (!cuddleElse){
            up(1);
         }
      } else if (style3) {
         insert_line(indent_string(width+syntax_indent)'{');
         insert_line(indent_string(width+syntax_indent)'}');
         surround_end_line=p_line+1;
         insert_line(indent_string(width)'catch':+maybespace'('parenspace:+parenspace')'e1);
         _end_line();
         p_col -= (length(e1)+1+length(parenspace));
         add_hotspot();
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
         up(2);
         ++num_end_lines;
      }
      nosplit_insert_line();
      p_col=width+syntax_indent+1;
      add_hotspot();
      set_surround_mode_end_line(surround_end_line, num_end_lines);
   } else if (word == 'try') {
      _end_line();
      startCol := p_col;
      replace_line(line:+' {} catch {}');
      p_col = startCol + 2;
      add_hotspot();
      p_col = startCol + 11;
      add_hotspot();
      p_col = startCol + 2;
   } else if (word) {
      replace_line(line:+' '); _end_line(); 
      doNotify = false;
   } else {
      status = 1;
      doNotify = false;
   }
   show_hotspots();
   /*if (expansion_end >= expansion_start
       && beautify_syntax_expansion(p_LangId)) {
      long markers[];

      new_beautify_range(expansion_start, expansion_end, markers, true, false, false);
   } else */if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }
   /*if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   } */
   return(status);
}

_command void scala_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()      ||  // Do not expand if the visible cursor is on the command line
       !doExpandSpace(p_LangId)       ||  // Do not expand this if turned OFF
       (p_SyntaxIndent<0)   ||  // Do not expand is syntax_indent spaces are < 0
       _in_comment()        ||  // Do not expand if you are inside of a comment
       _scala_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if ( _argument=='' ) {
      _undo('S');
   }
}

bool _scala_expand_enter()
{
// updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
// syntax_indent := p_SyntaxIndent;
   return(true);
}

static bool _in_one_line_brace_pair()
{
   return should_expand_cuddling_braces(p_LangId);
}

void _scala_auto_bracket_key_mask(_str close_ch, int* keys)
{
   if (close_ch == '}' && _in_one_line_brace_pair()) {
      *keys = *keys & ~AUTO_BRACKET_KEY_ENTER;
   }
}

_command void scala_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   //generic_enter_handler(_scala_expand_enter, true);
   c_enter();
}
bool _scala_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _scala_supports_insert_begin_end_immediately() {
   return true;
}
int _scala_delete_char(_str force_wrap='') {
   return _c_delete_char(force_wrap);
}

int scala_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   return groovy_smartpaste(char_cbtype,first_col,Noflines,allow_col_1);
}


int _scala_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                             _str lastid,int lastidstart_offset,
                             int info_flags,typeless otherinfo,
                             bool find_parents,int max_matches,
                             bool exact_match, bool case_sensitive,
                             SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                             SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                             VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}


int _scala_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                            _str symbol, _str search_class_name,
                            _str file_name, _str return_type, bool isjava,
                            struct VS_TAG_RETURN_TYPE &rt,
                            VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_parse_return_type(errorArgs,tag_files,
                               symbol,search_class_name,
                               file_name,return_type,
                               true,rt,visited,depth);
}

int _scala_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                               _str tag_name, _str class_name,
                               _str type_name, SETagFlags tag_flags,
                               _str file_name, _str return_type,
                               struct VS_TAG_RETURN_TYPE &rt,
                               struct VS_TAG_RETURN_TYPE (&visited):[],
                               int depth=0)
{
   return _c_analyze_return_type(errorArgs,tag_files,tag_name,
                                 class_name,type_name,tag_flags,
                                 file_name,return_type,
                                 rt,visited,depth);
}

/**
 * @see _c_get_type_of_expression
 */
int _scala_get_type_of_expression(_str (&errorArgs)[], 
                                  typeless tag_files,
                                  _str symbol, 
                                  _str search_class_name,
                                  _str file_name,
                                  CodeHelpExpressionPrefixFlags prefix_flags,
                                  _str expr, 
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  struct VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   return _c_get_type_of_expression(errorArgs, tag_files, 
                                    symbol, search_class_name, file_name, 
                                    prefix_flags, expr, 
                                    rt, visited, depth);
}

int _scala_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                     int tree_wid, int tree_index,
                                     _str lastid_prefix="", 
                                     bool exact_match=false, bool case_sensitive=true,
                                    _str param_name="", _str param_default="",
                                     struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_insert_constants_of_type(rt_expected,
                                         tree_wid,tree_index,
                                         lastid_prefix,
                                         exact_match,case_sensitive,
                                         param_name, param_default,
                                         visited, depth);
}

int _scala_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                             struct VS_TAG_RETURN_TYPE &rt_candidate,
                             _str tag_name,_str type_name,
                             SETagFlags tag_flags,
                             _str file_name, int line_no,
                             _str prefixexp,typeless tag_files,
                             int tree_wid, int tree_index)
{
   return 0;
}

int _scala_fcthelp_get_start(_str (&errorArgs)[],
                             bool OperatorTyped,
                             bool cursorInsideArgumentList,
                             int &FunctionNameOffset,
                             int &ArgumentStartOffset,
                             int &flags,
                             int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _scala_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      bool &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   int status=_c_fcthelp_get(errorArgs,
                             FunctionHelp_list,FunctionHelp_list_changed,
                             FunctionHelp_cursor_x,
                             FunctionHelp_HelpWord,
                             FunctionNameStartOffset,
                             flags, symbol_info,
                             visited, depth);
   return(status);
}

_str _scala_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   rv := '';

   switch (info.type_id) {
   case SE_TAG_TYPE_FUNCTION:
      rv :+= info.member_name'('info.arguments')';
      if (info.return_type != '' && info.return_type != 'Unit') {
         rv :+= ': 'info.return_type;
      }
      break;

   case SE_TAG_TYPE_GVAR:
   case SE_TAG_TYPE_LVAR:
   case SE_TAG_TYPE_VAR:
   case SE_TAG_TYPE_PARAMETER:
      if (info.return_type != '' && info.return_type != 'Unit') {
         rv = info.member_name': 'info.return_type;
      } else {
         rv = info.member_name;
      }
      break;

   case SE_TAG_TYPE_CLASS:
   case SE_TAG_TYPE_INTERFACE:
      if (info.type_id == SE_TAG_TYPE_CLASS) {
         if (info.flags & SE_TAG_FLAG_STATIC) {
            rv = 'object ';
         } else {
            rv = 'class ';
         }
      } else {
         rv = 'trait ';
      }
      if (info.qualified_name != '') {
         rv :+= translate(info.qualified_name, '.', '/')'.';
      }
      rv :+= info.member_name;
      break;

   default:
      rv = info.member_name:+': 'info.type_name;
   }
   return rv;
}

bool _scala_is_continued_statement()
{
   return _c_is_continued_statement();
}
static _str scala_exe_path(_str scalaHome, _str exeName)
{
   rv := scalaHome;
   _maybe_append(rv, FILESEP);

   return rv :+ 'bin' :+ FILESEP :+ exeName :+ EXTENSION_BAT;
}

static bool valid_scala_home(_str sh)
{
   rv := false;

   if (file_exists(scala_exe_path(sh, 'scala'))) {
      // Almost there. This test alone can give a false match for /usr on linux which
      // won't work because there's no /usr/lib/scala-*.jar, so check for the jar too.
      jp := sh;
      _maybe_append(jp, FILESEP);
      jp = _maybe_quote_filename(jp'lib'FILESEP'scala-library.jar');
      fn := file_match(jp' -P', 1);
      rv = (fn != '');
   }
   return rv;
}

_str calc_scala_home()         
{
   if (def_scala_home != '' && valid_scala_home(def_scala_home)) {
      return def_scala_home;
   }

   ev := get_env('SCALA_HOME');
   if (ev != '' && valid_scala_home(ev)) {
      if (def_scala_home == '') {
         def_scala_home = ev;
      }
      return ev;
   }

   if (_isUnix() && valid_scala_home('/usr/share/scala')) {
      if (def_scala_home == '') {
         def_scala_home = '/usr/share/scala';
         return def_scala_home;
      }
   }

   return '';
}

_str ensure_scala_home()
{
   rv := calc_scala_home();

   if (rv == '') {
      rv = show('_scala_home_selection_form -modal');
      if (valid_scala_home(rv)) {
         def_scala_home = rv;
      } else {
         rv = '';
      }
   }

   return rv;
}

int setup_sbt_environment()
{
   rv := 1;
   sbth := sbt_install_location();
   if (sbth == '') {
      // Not set yet for this configuration.
      //prompt_for_sbt_home();
      //sbth = def_sbt_home;
   }

   if (sbth != '') {
      set_env('SE_SBT_HOME', sbth);
      _restore_origenv(false);
      set('SE_SBT_HOME='sbth);
      rv = 0;
   }
   return rv;
}

// Callback for the project support, so we can set the SCALA_HOME environent 
// variable so it can be used inside of the projects.
int _scala_set_environment(int projectHandle, _str config, _str target, 
                            bool quite, _str error_hint)
{
   rv := 1;
   appType := _ProjectGet_AppType(projectHandle, config);

   if (appType == 'gradle') {
      rv = setup_gradle_environment();
   } else if (appType == 'sbt') {
      rv = setup_sbt_environment();
   } else {
      gh := ensure_scala_home();

      if (gh != '') {
         // Set for this process....
         set_env('SCALA_HOME', gh);

         // And also add it to the environment for the build system (which may
         // already have a shell spawned).
         _restore_origenv(false);
         set('SCALA_HOME='gh);
         rv = 0;
      }
   }

   return rv;
}

_str scala_classpath()
{
   sh := ensure_scala_home();
   _maybe_append(sh, FILESEP);
   root := _maybe_quote_filename(sh :+ 'lib' :+ FILESEP :+ '*.jar');
   return build_classpath_from_jar_dir(root);
}

static _str scalaCompilerTagfile(_str compilerName)
{
   return _tagfiles_path():+compilerName:+TAG_FILE_EXT;
}

static void update_autotag_state()
{
   _str tf;

   st := def_scala_autotag_state;
   checking := true;
   while (checking) {
      checking = false;

      switch (st) {
      case SAS_UNKNOWN:
         tf = scalaCompilerTagfile('scala');
         if (file_exists(tf)) {
            st = SAS_TAGGED;
         } else {
            st = SAS_NOT_TAGGED;
         }
         break;

      case SAS_NOT_TAGGED:
         tf = scalaCompilerTagfile('scala');
         if (file_exists(tf)) {
            st = SAS_TAGGED;
         }
         break;

      case SAS_TAGGED:
         tf = scalaCompilerTagfile('scala');
         if (!file_exists(tf)) {
            st = SAS_NOT_TAGGED;
         }
         break;

      case SAS_CANCELLED:
         break;

      default:
         st = SAS_UNKNOWN;
         checking=true;
      }
   }

   def_scala_autotag_state=st;
}

static _str get_configured_scala_version(_str scala_home)
{
   // Nothing worked, return the default, which should be the latest version.
   return def_default_scala_compiler_version;
}

static _str scala_library_tag_file(_str version)
{
   return _ConfigPath()'tagfiles'FILESEP'scala-'version'.vtg';
}

static _str src_jar_path(_str file)
{
   p := _ConfigPath()'scala';

   if (!file_exists(p)) {
      mkdir(p);
   }
   return p:+FILESEP:+file;
}

static _str scala_source_jar_path(_str basename, _str version)
{
   return src_jar_path(basename'-'version'-sources.jar');
}

static _str ivy_artifacts[] = {
   'scala-compiler', 'scala-library' 
};

static _str ivy_jar_file() 
{
   return _getSlickEditInstallPath()'toolconfig'FILESEP'ivy'FILESEP'ivy-2.4.0.jar';
}

_str get_active_java_root()
{
   if (!_haveBuild()) {
      return "";
   }

   src := '';
   cfg_file := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   config_is_open := refactor_config_is_open( cfg_file )!=0;

   if (!config_is_open) {
      refactor_config_open(cfg_file);
   }

   java_comp := refactor_get_active_config_name(-1, 'java');
   status := refactor_config_get_java_source(java_comp, src);

   if (!config_is_open) {
      refactor_config_close();
   }
   return src;
}

// Number of seconds to wait on ivy to download a file before giving up.
long def_ivy_download_timeout = 30;

static int drain_pipe_to_output_win(int handle)
{
   _str buf;

   while (_PipeIsReadable(handle)) {
      rc := _PipeRead(handle, buf, 1024, 0);
      if (rc < 0) {
         return rc;
      }
      _SccDisplayOutput(buf, false, false, true);
   }

   return 0;
}

// Returns space separated list of source jars files for the given
// scala compiler version. Returns '' on error, or if the download was
// refused/cancelled.
static _str ivy_download_scala_lib_src(_str version)
{
   rv := '';
   ivy := ivy_jar_file();
   if (!file_exists(ivy)) {
      message('Could not find packaged ivy jar file, can not get scala library source.');
      return '';
   }

   javaRoot := get_active_java_root();

   dldir := mktempdir(1, 'slk-ivy', true);
   mkdir(dldir);

   message('Getting Scala library source for tagging...');

   errMsg := '';
   OutputDisplayClear();
   startTime := (long)_time('B');
   maxEndTime := startTime + def_ivy_download_timeout * 1000;
   numTicks := def_ivy_download_timeout * 2;
   progBar := progress_show('Fetching scala library source for tagging...', (int)numTicks);
   progress_set_min_max(progBar, 0, (int)numTicks);

   foreach (auto art in ivy_artifacts) {
      cmd := '"'javaRoot'bin'FILESEP'java" -jar 'ivy' -dependency org.scala-lang 'art' 'version' -retrieve "'dldir'[artifact]-([classifier]).[ext]"';
      _SccDisplayOutput('IVY command: 'cmd, false, false, true);
      int stdin, stdout, stderr;

      proc := _PipeProcess(cmd, stdout, stdin, stderr, '');
      if (proc < 0) {
         _SccDisplayOutput('Error running Ivy command: 'proc, false, false, true);
         rv = '';
         break;
      }

      while (!_PipeIsProcessExited(proc)) {
         rc := drain_pipe_to_output_win(stdout);
         if (rc < 0) {
            errMsg = 'Error reading pipe from 'art'-'version': 'rc;
            break;
         }

         rc = drain_pipe_to_output_win(stderr);
         if (rc < 0) {
            errMsg = 'Error reading pipe from 'art'-'version': 'rc;
            break;
         }

         now := (long)_time('B');
         if (now > maxEndTime) {
            _PipeCloseProcess(proc);
            errMsg = 'Timed out downloading 'art'-'version' after 'def_ivy_download_timeout' seconds.';
            break;
         }
         ticky := (now - startTime) intdiv 500;
         progress_set(progBar, (int)ticky);
         delay(10);
      }
      if (errMsg != '') {
         _SccDisplayOutput('\n'errMsg, false, false, true);
         message(errMsg);
         rv = '';
         break;
      }

      dlfile := dldir:+art:+'-sources.jar';
      destfile := scala_source_jar_path(art, version);
      rc = copy_file(dlfile, destfile);
      if (rc != 0) {
         _SccDisplayOutput('Error copying 'dlfile': 'rc, false, false, true);
         rv = '';
         break;
      }

      if (rv != '') {
         rv :+= ' ';
      }
      rv :+= destfile;
   }
   progress_close(progBar);

   rmdir(dldir);
   return rv;
}

int _scala_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   status := 0; 
   compiler_name := "scala";

   if (compiler_name != '' && compiler_name != gCancelledCompiler) {
      update_autotag_state();
      if (def_scala_autotag_state == SAS_NOT_TAGGED) {
         tagfile := scalaCompilerTagfile(compiler_name);
         if (!ensureJavaCompilerConfigured()) {
            prompt_for_new_java_compiler();
            if (!ensureJavaCompilerConfigured()) {
               message('Configure Java compiler to tag Scala libraries.');
               def_scala_autotag_state = SAS_CANCELLED;
               return 0;
            }
         }
         // This will force setting of the scala compiler location, if necessary.
         sh := ensure_scala_home();
         scalaVer := get_configured_scala_version(sh);
         verTagFile := scala_library_tag_file(scalaVer);
         extraJars := '';

         if (!file_exists(verTagFile)) {
            extraJars = ivy_download_scala_lib_src(scalaVer);
            if (extraJars == '') {
               def_scala_autotag_state = SAS_CANCELLED;
               return 0;
            }
         }
         status = ext_BuildTagFile(tfindex, tagfile, 'scala', 'Scala Language', false, extraJars, '', withRefs, useThread);

         if (status) {
            message('Problem building Scala language tag file: 'status);
            gCancelledCompiler = compiler_name;
         } else {
            gCancelledCompiler = '';
         }
      }
   }

   return 0;
}

// Quick check to see if 'args' makes a valid argument list for
// a main() entry point. We can be a little lazy, since
// the scala compiler won't compile public static methods
// named "main" that don't have the right signature.
bool scala_is_main_args(_str args)
{
   if (pos(',', args) > 0) {
      // Only one argument.
      return false;
   }
   _str name, type;
   parse args with name ':' type;
   return strip(type) == 'Array[String]';
}


defeventtab _scala_home_selection_form;

static void update_paths_state(typeless dummy = null)
{
   homedir := strip(_ctl_scala_home.p_text);

   if (valid_scala_home(homedir)) {
      _ctl_home_error.p_visible = false;
   } else {
      _ctl_home_error.p_caption = "* '"homedir"' is not a valid Scala install";
      _ctl_home_error.p_visible = true;
   }
}

void _ctl_scala_home.on_change()
{
   update_paths_state(0);
}

void _ctl_scala_home.on_create()
{
   _ctl_scala_home.p_text = calc_scala_home();
   update_paths_state(0);

   sizeBrowseButtonToTextBox(_ctl_scala_home.p_window_id, 
                             _browsedir1.p_window_id, 0, 
                             p_active_form.p_width - _ctl_scala_home.p_prev.p_x);
}

void _ctl_scala_home.'ENTER'()
{
   p_active_form._delete_window(_ctl_scala_home.p_text);
}

void _ctl_scala_home_ok.lbutton_up()
{
   p_active_form._delete_window(_ctl_scala_home.p_text);
}

// Support for same dialog embedded into the options tree.
void _scala_home_selection_form_init_for_options(_str langid)
{
   _nocheck _control _ctl_scala_home;
   _nocheck _control _ctl_scala_home_ok;

   gh := calc_scala_home();
   if (gh == '') {
      gh = def_scala_home;
   }

   _ctl_scala_home.p_text = gh;
   update_paths_state(0);
   _ctl_scala_home_ok.p_visible = false;
}

bool _scala_home_selection_form_apply()
{
   _nocheck _control _ctl_scala_home;

   def_scala_home = _ctl_scala_home.p_text;
   return true;
}

bool _scala_home_selection_form_is_modified()
{
   _nocheck _control _ctl_scala_home;

   return _ctl_scala_home.p_text != calc_scala_home();
}

// Callback name for the scala dbgp debugger.
_str SCALADBG_CB = 'scaladbgp';

static void scala_make_default_options(DBGpOptions& opts)
{
   opts.serverHost = "127.0.0.1";
   opts.serverPort = "0";
   opts.listenInBackground = true;
   opts.remoteFileMap = null;
   dbgp_make_default_features(opts.dbgp_features);
}

void scala_project_get_options_for_config(int projectHandle, _str config, DBGpOptions& opts, DBGpOptions& default_opts=null)
{
   if( default_opts == null ) {
      scala_make_default_options(default_opts);
   }
   _str serverHost = default_opts.serverHost;
   _str serverPort = default_opts.serverPort;
   listenInBackground := default_opts.listenInBackground;
   DBGpRemoteFileMapping remoteFileMap[] = default_opts.remoteFileMap;
   DBGpFeatures dbgp_features = default_opts.dbgp_features;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='DBGp Options']",node);
      if( opt_node >= 0 ) {

         // ServerHost
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerHost']",opt_node);
         if( node >=0  ) {
            serverHost = _xmlcfg_get_attribute(projectHandle,node,"Value",serverHost);
         }

         // ServerPort
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerPort']",opt_node);
         if( node >=0  ) {
            serverPort = _xmlcfg_get_attribute(projectHandle,node,"Value",serverPort);
         }

         // ListenInBackground
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ListenInBackground']",opt_node);
         if( node >=0  ) {
            listenInBackground = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)listenInBackground) );
         }

         // Remote file mappings
         _str nodes[];
         if( 0 == _xmlcfg_find_simple_array(projectHandle,"List[@Name='Map']",nodes,opt_node,0) ) {
            _str remoteRoot, localRoot;
            foreach( auto map_node in nodes ) {
               remoteRoot = "";
               localRoot = "";
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='RemoteRoot']",(int)map_node);
               if( node >=0  ) {
                  remoteRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='LocalRoot']",(int)map_node);
               if( node >=0  ) {
                  localRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               i := remoteFileMap._length();
               remoteFileMap[i].remoteRoot = remoteRoot;
               remoteFileMap[i].localRoot = localRoot;
            }
         }

         // DBGp features
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='show_hidden']",opt_node);
         if( node >=0  ) {
            dbgp_features.show_hidden = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)dbgp_features.show_hidden) );
         }
      }
   }
   opts.serverHost = serverHost;
   opts.serverPort = serverPort;
   opts.listenInBackground = listenInBackground;
   opts.remoteFileMap   = remoteFileMap;
   opts.dbgp_features = dbgp_features;
}


// Accepting server socket for our dbgp connection listener.
static int g_Socket;
int _scala_project_command_status(int projectHandle, _str config,
                                   int socket_or_status,
                                   _str cmdline,
                                   _str target,
                                   _str buf_name,
                                   _str word,
                                   _str debugStepType,
                                   bool quiet,
                                   _str& error_hint,
                                   _str debugArguments="",
                                   _str debugWorkingDir="")
{
   // Necessary because _project_command will pass us null status when
   // it has executed a target that returns void
   if( socket_or_status._varformat() != VF_INT ) {
      socket_or_status = 0;
   }

   if (g_Socket < 0) {
      return socket_or_status;
   }

   ltarg := lowcase(target);
   if (ltarg != 'debug') {
      // We are only interested in Debug command,
      // so return original status.
      return socket_or_status;
   }

   if( socket_or_status < 0 ) {
      // Debug command failed, so go no further
      return socket_or_status;
   }

   if( _project_DebugCallbackName != SCALADBG_CB ) {
      // Not an Pydbgp debugger project. Nothing wrong with that, but
      // we cannot do anything with it.
      return 0;
   }

   status := 0;

   do {

      // Assemble debugger_args
      debugger_args := "";
      debugger_args :+= ' -socket='socket_or_status;
      debugger_args :+= ' -server-socket='g_Socket;
      // Pass the project remote-directory <=> local-directory mappings

//    PythonOptions python_opts;
//    getProjectPythonOptionsForConfig(projectHandle,config,python_opts);
      DBGpOptions opts;
      scala_project_get_options_for_config(projectHandle,config,opts);
      DBGpRemoteFileMapping map;
      foreach( map in opts.remoteFileMap ) {
         if( map.remoteRoot != "" && map.localRoot != "" ) {
            debugger_args :+= ' -map='map.remoteRoot':::'map.localRoot;
         }
      }
      // DBGp features
      debugger_args :+= ' -feature-set=show_hidden='opts.dbgp_features.show_hidden;
   
      // Attempt to start debug session
      status = debug_begin(SCALADBG_CB,"","",debugArguments,def_debug_timeout,null,debugger_args,debugWorkingDir);

   } while( false );

   if( status != 0 && socket_or_status >= 0 ) {
      // Error
      // Do not want to orphan a connected socket, so close it now.
      vssSocketClose(socket_or_status);
   }
   return status;
}

// Need to explicitly add tools.jar to be able to use the JDI library for debugging.
// tools.jar only exists in JDK installs, not JREs.  ``toolsJar`` is not quoted.
#define NO_JAVA_CONFIG -1
#define JAR_NOT_FOUND -2
#define JAVA_NOT_FOUND -3
static int find_java_tools_jar(_str &javaExe, _str &toolsJar)
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }

   filename       := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   config_is_open := refactor_config_is_open( filename )!=0;
   javaConfig     := refactor_get_active_config_name(-1, 'java');

   refactor_config_open( filename );
   if (javaConfig == '') {
      toolsJar = '';
      if (!config_is_open) {
         refactor_config_close();
      }
      return NO_JAVA_CONFIG;
   }

   needTools := true;
   if (pos('\d+\.(\d+)\.\d+', javaConfig, 1, 'L') > 0) {
      maj := substr(javaConfig, pos('S1'), pos('1'));
      if (isinteger(maj) && (int)maj > 8) {
         // From 1.9 up, tools.jar no longer exists.  It's builtin to the JDK, and has no external jar file.
         needTools = false;
      }
   }

   status := refactor_config_get_java_source(javaConfig, auto jdkRoot);
   if (status != 0) {
      toolsJar = '';
      if (!config_is_open) {
         refactor_config_close();
      }
      return status;
   }

   if (needTools) {
      _maybe_append_filesep(jdkRoot);
      toolsJar = jdkRoot:+'lib'FILESEP'tools.jar';
      if (!file_exists(toolsJar)) {
         if (!config_is_open) {
            refactor_config_close();
         }
         return JAR_NOT_FOUND;
      }
   }

   javaExe = jdkRoot:+'bin':+FILESEP:+'java':+EXTENSION_EXE;
   if (!config_is_open) {
      refactor_config_close();
   }

   if (!file_exists(javaExe)) {
      return JAVA_NOT_FOUND;
   }
   return 0;
}

// Where in the install is our jar file.
static _str debugger_jar_loc() 
{
   _str dir = _getSlickEditInstallPath();
   _maybe_append_filesep(dir);
   return dir'resource'FILESEP'tools'FILESEP'scaladbgp'FILESEP'se-scala-debugger-assembly-1.0.0.jar';
}

// Writes xml spec of the debugger/debuggee options to a temp file, and returns the path to the
// tmp file. We pass parameters in a file to avoid all the varieties of quoting problems
// when shelling out the debugger.
//    setJDWPEnvironment - if true, the debugger sets JAVA_OPTS before launching the target program to configure 
//                         JDWP.  If false, it's assumed jdwp is configured with some other mechanism that doesn't need
//                         our interference.
static int write_debug_xml(_str destFile, _str targetHost, int jdwpPort, DBGpOptions opts, _str debuggee, _str (&extraArgs)[],  _str workingDir, 
                           bool setJDWPEnv)
{
   origWid := _create_temp_view(auto wid);
   p_window_id = wid;
   insert_line('<debug>');
   insert_line('<logging v="'def_debug_logging'"/>');
   insert_line('<setJDWPEnvironment v="'(int)setJDWPEnv'"/>');
   insert_line('<jdwpHost v="'targetHost'"/>');
   insert_line('<jdwpPort v="'jdwpPort'"/>');
   insert_line('<idePort v="'opts.serverPort'"/>');
   if (debuggee != '') {
      insert_line('<arg><![CDATA['debuggee']]></arg>');
   }
   _str argu;
   foreach (argu in extraArgs) {
      insert_line('<arg><![CDATA['argu']]></arg>');
   }
   insert_line('<workingDir v="'workingDir'"/>');
   insert_line('</debug>');
   rc := _save_file('+o '_maybe_quote_filename(destFile));
   p_window_id = origWid;
   _delete_temp_view(wid);
   
   return rc;
}

static _str dbg_xml_for_project()
{
   _str file = 'debug.xml';

   if (_project_name != '') {
      file = _strip_filename(_project_name, 'PDE')'dbg.xml';
   }

   rv := _temp_path();
   _maybe_append_filesep(rv);
   rv :+= file;

   return rv;
}

// Launches the debugger + the debuggee. Assumes toolsJar has already been validated, and
// the build tool location is already configured.   
// NOTES: 
//    o jdwpHost & jdwpPort are ignored unless the appType == 'attach'.
//    o ``opts`` must be updated with the correct host and port, even when the port
//      is dynamically allocated.
static int launch_scala_debugger_with_args(DBGpOptions opts, _str appType, _str javaExe, _str toolsJar, _str extraArgs, _str workingDir, 
                                           _str jdwpHost = 'localhost', int jdwpPort = 9000, _str targetName = 'execute')
{
   status := 0;

   _str cmd = '';
   handle := 0;
   config := "";
   extraCp := '';

   if (appType == SCALA_SINGLE_FILE_APPTYPE) {
      extraCp = _strip_filename(p_buf_name, 'NE');
      _maybe_append_filesep(extraCp);
      extraCp :+= 'classes';
   }

   // Use the command defined in the `Execute` tool.
   if (appType != 'attach') {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
      int node = _ProjectGet_TargetNode(handle,targetName,config);
      if (node >= 0) {
         cmd = _ProjectGet_TargetCmdLine(handle, node);
         cmd = _parse_project_command(cmd, '', _project_name, '', '', '', extraCp);
      } else {
         if (appType == 'sbt') {
            cmd = configured_sbt_exe();
         } else if (appType == 'gradle') {
            cmd = gradle_install_location():+gradle_exe_relpath();
         } else if (appType == 'attach') {
            cmd = '';
         } else if (appType == SCALA_SINGLE_FILE_APPTYPE) {
            cmd = javaExe;
         } else {
            return INVALID_ARGUMENT_RC;
         }
      }
   }

   if (appType == SCALA_SINGLE_FILE_APPTYPE) {
      _helpFindJavaMainClass('', cmd, 'scala_is_main_args');
   }

   idx := 1;
   sbtCmd := '';
   pc := '';
   _str args[];
   int jdwpserverPort = (int)opts.serverPort + 100;

   args._makeempty();
   if (appType == SCALA_SINGLE_FILE_APPTYPE) {
      args[args._length()] = '-Xdebug';
      args[args._length()] = '-Xnoagent';
      args[args._length()] = '-Xrunjdwp:transport=dt_socket,server=y,suspend=y,address='jdwpserverPort;
   }

   for (pc = _pos_parse_wordsep(idx, cmd, ' '); pc != null; pc = _pos_parse_wordsep(idx, cmd, ' ')) {
      if (sbtCmd == '') {
         sbtCmd = pc;
      } else {
         if (appType == 'sbt' && (pc == 'run' || beginsWith(pc, 'runMain ')) && extraArgs != '') {
            // For SBT, we have to cram all the actual program arguments in the same command line
            // argument as 'run', otherwise SBT picks them up as separate commands.
            args[args._length()] = pc' 'extraArgs;
         } else {
            args[args._length()] = pc;
         }
      }
   }

   if (appType == 'gradle') {
      args[args._length()] = '--debug-jvm';
   } else if (appType == SCALA_SINGLE_FILE_APPTYPE) {
   }

   if (workingDir != '') {
      cd(workingDir);
   }

   // NOTE: jdwp port is not configured for launch case.
   _str xmlfile = dbg_xml_for_project();
   bool setJDWPEnvironment = true;

   if (appType == 'gradle') {
      // We invoke debugging on gradle using the --jvm-debug option, which hardcodes the
      // JDWP port to 5005. 
      jdwpserverPort = 5005;
      setJDWPEnvironment = false;
   } else if (appType == 'attach') {
      jdwpserverPort = jdwpPort;
      setJDWPEnvironment = false;
   }
   status = write_debug_xml(xmlfile, jdwpHost, jdwpserverPort, opts, sbtCmd, args, workingDir, 
                            setJDWPEnvironment);
   if (status == 0) {
      status = concur_command(_maybe_quote_filename(javaExe)' -classpath "'toolsJar:+PATHSEP:+debugger_jar_loc()'" com.slickedit.debug.Main "'xmlfile'"', def_process  && !def_process_tab_output);
   }

   return status;
}

static int check_debug_prereqs(_str& javaExe, _str& toolsJar)
{
   rc := find_java_tools_jar(javaExe, toolsJar);
   if (rc == NO_JAVA_CONFIG || rc == JAVA_NOT_FOUND) {
      _message_box("Can not debug a Scala project without a configured JDK.");
      config('_java_compiler_properties_form', 'D');
      return INVALID_ARGUMENT_RC;
   }
   if (rc == JAR_NOT_FOUND) {
      _message_box("Could not find a 'tools.jar' for your configured JDK.");
      return INVALID_ARGUMENT_RC;
   }

   return rc;
}

static int scala_get_opts(DBGpOptions& opts)
{
   scala_make_default_options(opts);
   scala_project_get_options_for_config(_ProjectHandle(),GetCurrentConfigName(),opts);

   if (_project_name == '') {
      if (dbgp_server_is_listening('', SCALADBG_CB, opts.serverHost, opts.serverPort)) {
         opts.listenInBackground = true;
      }
   }

   return 0;
}


_command int scala_attach(_str debug_cb_name="", _str session_name="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   rc := check_debug_prereqs(auto javaExe, auto toolsJar);
   if (rc != 0) {
      return rc;
   }

   attach_info:=show("-xy -modal _debug_jdwp_attach_form", session_name);
   _str host_name, port_number;
   parse attach_info with 'host=' host_name ',port=' port_number",session="session_name;
   if (session_name == VSDEBUG_NEW_SESSION) session_name = "";
   if (session_name == "") {
      session_name = "ATTACH: " :+ host_name":"port_number;
   }

   DBGpOptions opts;
   rc = scala_get_opts(opts);
   if (rc != 0) {
      return rc;
   }

   status_or_socket := 0;
   host := opts.serverHost;
   port := opts.serverPort;

   // Get the actual host:port the server is listening on.
   // This is necessary since the user may have elected to use a
   // dynamically allocated port and we need to pass the actual
   // listener address to the scala debugger.
   proto_get_server_address(SCALADBG_CB, host,port);

   // We do not want the possiblility of the passive connection monitor
   // attempting to start a debug session right in the middle of things
   // because it also recognized a pending connection. That would get
   // very confusing.
   int old_almost_active = (int)dbgp_almost_active(1);

   _ProjectGet_ActiveConfigOrExt(_project_name,auto handle,auto config);
   int node = _ProjectGet_TargetNode(handle,'debug',config);
   dbgWorkingDir := '';
   if (node >= 0) {
      dbgWorkingDir = _ProjectGet_TargetRunFromDir(handle, node);
      dbgWorkingDir = _parse_project_command(dbgWorkingDir, '', _project_name, '');
   }

   do {
      already_listening := proto_is_listening(SCALADBG_CB, opts.serverHost,opts.serverPort);
      if( !already_listening || !proto_is_pending(SCALADBG_CB, opts.serverHost,opts.serverPort) ) {

         // Must EXECUTE and listen for resulting connection from debugger engine
         if( !already_listening ) {
            // Must provision a one-shot server before EXECUTE, otherwise scaladbgp will fail
            // the connection test to us.
            proto_watch(SCALADBG_CB, opts.serverHost,opts.serverPort, null);
         }

         launchOpts := opts;
         launchOpts.serverHost = host;
         launchOpts.serverPort = port;
         status_or_socket = launch_scala_debugger_with_args(launchOpts, 'attach', javaExe, toolsJar, '', dbgWorkingDir, 
                                                            host_name, (int)port_number);
         if( status_or_socket != 0 ) {
            // Error. project_execute should have taken care of displaying any message.
            if( !already_listening ) {
               // Clean up the one-shot server we created
               proto_shutdown(SCALADBG_CB, opts.serverHost,opts.serverPort);
            }
            break;
         }
         // Fall through to actively waiting for connection
      }

      //TODO do we need our own version of this? It seems generic enough where it's not specific to pydbgp.
      se.debug.pydbgp.PydbgpConnectionProgressDialog dlg;
      int timeout = 1000*def_debug_timeout;
      status_or_socket = proto_wait_and_accept(SCALADBG_CB, opts.serverHost,opts.serverPort,timeout,&dlg,false);

      if( !already_listening ) {
         // Clean up the one-shot server we created
         proto_shutdown(SCALADBG_CB, opts.serverHost,opts.serverPort);
      } else {
         if( status_or_socket < 0 ) {
            // Error. Was it serious?
            if( status_or_socket != COMMAND_CANCELLED_RC && status_or_socket != SOCK_TIMED_OUT_RC ) {
               _str msg = "You just failed to accept a connection from scaladbgp. The error was:\n\n" :+
                          get_message(status_or_socket)" ("status_or_socket")\n\n" :+
                          "Would you like to stop listening for a connection?";
               int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
               if( result == IDYES ) {
                  proto_shutdown(SCALADBG_CB, opts.serverHost,opts.serverPort);
                  sticky_message(nls("Server listening at %s:%s has been shut down.",opts.serverHost,opts.serverPort));
               } else {
                  // Clear the last error, so the watch timer does not pick
                  // it up and throw up on the user a second time.
                  proto_clear_last_error(SCALADBG_CB, opts.serverHost,opts.serverPort);
               }
            } else {
               // Clear the last error, so the watch timer does not pick
               // it up and throw up on the user a second time.
               proto_clear_last_error(SCALADBG_CB, opts.serverHost,opts.serverPort);
            }
         }

         // Note: The server takes care of resuming any previous watch
      }
   } while( false );

   dbgp_almost_active(old_almost_active);

   session_id := dbg_create_new_session(SCALADBG_CB, session_name, true);
   if (session_id < 0) {
      debug_message("Error creating debugger session", session_id);
      return session_id;
   }
   debug_initialize_runtime_filters(session_id,true);
   debug_gui_update_current_session();

   debugger_args := "-run ";
   debugger_args :+= ' -socket='status_or_socket;
   debugger_args :+= ' -server-socket='g_Socket;

   scala_project_get_options_for_config(handle,config,opts);
   DBGpRemoteFileMapping map;
   foreach( map in opts.remoteFileMap ) {
      if( map.remoteRoot != "" && map.localRoot != "" ) {
         debugger_args :+= ' -map='map.remoteRoot':::'map.localRoot;
      }
   }
   // DBGp features
   debugger_args :+= ' -feature-set=show_hidden='opts.dbgp_features.show_hidden;

   // Attempt to start debug session
   status_or_socket = debug_begin(SCALADBG_CB,"","","",def_debug_timeout,null, debugger_args,dbgWorkingDir);

   return status_or_socket;
}

_command int scala_debug(_str cmdArgs = '') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   // The targetName inside the project can be overridden by
   // prepending the cmdArgs with '{newTargetName}'.
   targetName := 'execute';
   if (beginsWith(cmdArgs, '{', true)) {
      parse cmdArgs with '{' targetName '}' cmdArgs;
   }

   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   rc := check_debug_prereqs(auto javaExe, auto toolsJar);
   if (rc != 0) {
      return rc;
   }

   // Check for configured jdk now, as we can't do anything without that.
   handle := 0;
   config := "";

   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);

   appType := _ProjectGet_AppType(handle, config);
   if (appType == 'sbt') {
      // Make sure SBT is configured so we can actually run the project.
      if (configured_sbt_exe() == '') {
         _message_box("Could not locate SBT_HOME for this configuration.");
         project_usertool('sbt options');
         return INVALID_ARGUMENT_RC;
      }
   } else if (appType == 'gradle') {
      if (gradle_install_location() == '') {
         _message_box("Could not locate the Gradle install location.");
         project_usertool('gradle options');
         return INVALID_ARGUMENT_RC;
      }
   } else if (appType == SCALA_SINGLE_FILE_APPTYPE) {
      // nothing to check here
   } else {
      _message_box("Unrecognized applcation type for project: "appType);
      return INVALID_ARGUMENT_RC;
   }

   DBGpOptions opts;
   rc = scala_get_opts(opts);
   if (rc != 0) {
      return rc;
   }

   status_or_socket := 0;

   // We do not want the possiblility of the passive connection monitor
   // attempting to start a debug session right in the middle of things
   // because it also recognized a pending connection. That would get
   // very confusing.
   int old_almost_active = (int)dbgp_almost_active(1);
   host := opts.serverHost;
   port := opts.serverPort;


   do {
      already_listening := proto_is_listening(SCALADBG_CB, opts.serverHost,opts.serverPort);
      if( !already_listening || !proto_is_pending(SCALADBG_CB, opts.serverHost,opts.serverPort) ) {

         // Must EXECUTE and listen for resulting connection from debugger engine
         if( !already_listening ) {
            // We need to ensure that secsh is already running, because it will cause us problems
            // if it shares our socket handles.
            concur_command('echo');

            // Must provision a one-shot server before EXECUTE, otherwise scaladbgp will fail
            // the connection test to us.
            proto_watch(SCALADBG_CB, opts.serverHost,opts.serverPort, null);
         }


         // Get the actual host:port the server is listening on.
         // This is necessary since the user may have elected to use a
         // dynamically allocated port and we need to pass the actual
         // listener address to the scala debugger.
         proto_get_server_address(SCALADBG_CB, host,port);
         _str dbgArguments = '';
         _str dbgWorkingDir = '';

         // Pulls out the debug arguments and working dir if they have been overridden for this run.
         if (cmdArgs != '') {
            parseDebugParameters(cmdArgs, dbgArguments, dbgWorkingDir);
         }

         if (dbgWorkingDir == '') {
            // Even when we aren't called from debug-run-with-arguments, we still need to override the
            // workingDir, because we want to use the working directory setting from the "Debug" target
            // when we invoke the execute target below.
            int node = _ProjectGet_TargetNode(handle,'debug',config);
            if (node >= 0) {
               dbgWorkingDir = _ProjectGet_TargetRunFromDir(handle, node);
               dbgWorkingDir = _parse_project_command(dbgWorkingDir, '', _project_name, '');
            }
         }

         launchOpts := opts;
         launchOpts.serverHost = host;
         launchOpts.serverPort = port;
         status_or_socket = launch_scala_debugger_with_args(launchOpts, appType, javaExe, toolsJar, dbgArguments, dbgWorkingDir, 'localhost', 9000, targetName);

         if( status_or_socket != 0 ) {
            // Error. project_execute should have taken care of displaying any message.
            if( !already_listening ) {
               // Clean up the one-shot server we created
               proto_shutdown(SCALADBG_CB, opts.serverHost, opts.serverPort);
            }
            break;
         }
         // Fall through to actively waiting for connection
      }

      //TODO do we need our own version of this? It seems generic enough where it's not specific to pydbgp.
      se.debug.pydbgp.PydbgpConnectionProgressDialog dlg;
      int timeout = 1000*def_debug_timeout;
      status_or_socket = proto_wait_and_accept(SCALADBG_CB, opts.serverHost,opts.serverPort,timeout,&dlg,false);

      if( !already_listening ) {
         // Clean up the one-shot server we created
         proto_shutdown(SCALADBG_CB, opts.serverHost,opts.serverPort);
      } else {
         if( status_or_socket < 0 ) {
            // Error. Was it serious?
            if( status_or_socket != COMMAND_CANCELLED_RC && status_or_socket != SOCK_TIMED_OUT_RC ) {
               _str msg = "You just failed to accept a connection from scaladbgp. The error was:\n\n" :+
                          get_message(status_or_socket)" ("status_or_socket")\n\n" :+
                          "Would you like to stop listening for a connection?";
               int result = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
               if( result == IDYES ) {
                  proto_shutdown(SCALADBG_CB, opts.serverHost,opts.serverPort);
                  sticky_message(nls("Server listening at %s:%s has been shut down.",opts.serverHost,opts.serverPort));
               } else {
                  // Clear the last error, so the watch timer does not pick
                  // it up and throw up on the user a second time.
                  proto_clear_last_error(SCALADBG_CB, opts.serverHost,opts.serverPort);
               }
            } else {
               // Clear the last error, so the watch timer does not pick
               // it up and throw up on the user a second time.
               proto_clear_last_error(SCALADBG_CB, opts.serverHost,opts.serverPort);
            }
         }
         // Note: The server takes care of resuming any previous watch
      }
   } while( false );

   dbgp_almost_active(old_almost_active);

   return status_or_socket;
}

/**
 * Start passively listening for connection from scaladbgp. If 
 * projectName!="" then scaladbgp options are pulled from the 
 * project; otherwise the user is prompted for host:port 
 * settings. 
 * 
 * @param projectName              Name of project to pull 
 *                                 scaldbgp options from.
 *                                 Defaults to current project
 *                                 name.
 * @param honorListenInBackground  If set to true, then the 
 *                                 ListenInBackground setting of
 *                                 the scaladbgp options are
 *                                 checked. If the
 *                                 ListenInBackground setting is
 *                                 false, then listener is not
 *                                 started. Ignored if there is
 *                                 no current project. Defaults
 *                                 to false.
 * 
 * @return 0 on success, <0 on error.
 */
_command int scaladbgp_project_watch(_str projectName=_project_name, bool honorListenInBackground=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( honorListenInBackground && projectName == "" ) {
      // You have to have a project to honor the ListenInBackground options
      return 0;
   }
   DBGpOptions opts;
   scala_project_get_options_for_config(_ProjectHandle(projectName),GetCurrentConfigName(), opts);
   if( projectName != "" ) {
      if( honorListenInBackground && !opts.listenInBackground ) {
         // ListenInBackground is off, so bail
         return 0;
      }
   }

   timeout := -1;

   // Passively listen for a connection from pydbgp
   _str id = proto_server_id(SCALADBG_CB, projectName,opts.serverHost,opts.serverPort);
   se.net.ServerConnection* server = se.net.ServerConnectionPool.allocate(id);
   g_ScalaDbgpMonitor.setCb(SCALADBG_CB);
   status := server->watch(opts.serverHost,opts.serverPort,timeout,&g_ScalaDbgpMonitor);
   if( status != 0 ) {
      _str msg = nls("Failed to start scaladbgp server on %s:%s. %s.",opts.serverHost,opts.serverPort,get_message(status));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      g_Socket = -1;
   } else {
      g_Socket = server->getNativeSocket();
   }
   return status;
}

using namespace se.debug.pydbgp;

/**
 * Called when a project is opened. Start up any scaladbgp 
 * servers for this project. 
 */
void _prjopen_scaladbgp(bool singleFileProject)
{
   if ( !_haveDebugging() ) {
      return;
   }

   // close single file project listener if running
   listening := dbgp_server_is_listening('', SCALADBG_CB, auto host, auto port);
   if (!singleFileProject && listening) {
      dbgp_project_shutdown(SCALADBG_CB, '');
   }

   if( _project_DebugCallbackName != SCALADBG_CB ) {
      return;
   }

   // Register alert for server
   _RegisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   // Start up servers for active config
   scaladbgp_project_watch(_project_name,true);
}

/**
 * Called when a project is closed. Shut down any pydbgp servers 
 * for this project. 
 *
 * @param projectName  Name of project being closed.
 */
void _prjclose_scaladbgp(bool singeFileProject=false)
{
   if ( !_haveDebugging() ) {
      return;
   }
   if (dbgp_almost_active() || _project_DebugCallbackName != SCALADBG_CB ) {
      return;
   }

   // single file project callbacK?
   if (singeFileProject && dbgp_server_is_listening('', SCALADBG_CB, auto host, auto port)) {
      return;
   }

   // Unregister alert for server
   _UnregisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   dbgp_project_shutdown(SCALADBG_CB, _project_name);
}
//-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005
