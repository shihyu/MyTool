////////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 SlickEdit Inc. 
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
#include "slick.sh"
#include "tagsdb.sh"
#include "refactor.sh"
#import "beautifier.e"
#import "c.e"
#import "cfcthelp.e"
#import "cjava.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "env.e"
#import "gradle.e"
#import "optionsxml.e"
#import "main.e"
#import "picture.e"
#import "pmatch.e"
#import "projconv.e"
#import "refactor.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "wkspace.e"
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"

using se.lang.api.LanguageSettings;

static int gCompilerPromptTimer = -1;
static _str gCancelledCompiler = '';
_str def_groovy_home;

/**
 * If > 0, calc_nextline_indent_from_tags will print out debug 
 * information on the tag contexts in the debug window. 
 */
int def_tag_edit_debug;

definit()
{
   gCompilerPromptTimer=-1;
   gCancelledCompiler = '';
   def_tag_edit_debug=0;
}


static _str groovyActiveCompiler()
{
   // For now, just a single compiler. 
   return 'groovy';
}

static _str groovyCompilerTagfile(_str compilerName)
{
   return _tagfiles_path():+compilerName:+TAG_FILE_EXT;
}

bool ensureJavaCompilerConfigured()
{
   //say("javaCompiler="javaCompiler);
   return (java_get_active_compile_tag_file() != '');
}

static _str getJavaConfigJars() 
{
   if (!_haveBuild()) {
      return "";
   }

   filename       := _ConfigPath():+COMPILER_CONFIG_FILENAME;
   config_is_open := refactor_config_is_open( filename )!=0;
   paths          := '';
   javaConfig     := refactor_get_active_config_name(-1, 'java');

   refactor_config_open( filename );
   if (javaConfig != '') {
      numJars := refactor_config_count_jars(javaConfig);
      i := 0;

      for (i = 0; i < numJars; i++) {
         if (refactor_config_get_jar(javaConfig, i, auto jarPath) == 0) {
            paths :+= _maybe_quote_filename(jarPath)' ';
         }
      }
   }

   if (!config_is_open) {
      refactor_config_close();
   }
   return paths;
}

static void _groovyPromptCompiler()
{
   if (_timer_is_valid(gCompilerPromptTimer)) {
      _kill_timer(gCompilerPromptTimer);
      gCompilerPromptTimer=-1;
   }
   config('_java_compiler_properties_form', 'D');
}
int _groovy_delete_char(_str force_wrap='') {
   return _c_delete_char(force_wrap);
}

// Hook functions.
int _groovy_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   status := 0; 
   _str compiler_name = groovyActiveCompiler();

   if (compiler_name != '' && compiler_name != gCancelledCompiler) {
      tagfile := groovyCompilerTagfile(compiler_name);

      if (!file_exists(tagfile)
          && ensureJavaCompilerConfigured()) {
         paths := getJavaConfigJars();
         paths :+= ' 'ext_builtins_path('groovy', 'groovyDK');
         status = ext_BuildTagFile(tfindex, tagfile, 'groovy', 'Groovy Language', false, paths, '', withRefs, useThread);

         if (status) {
            message('Problem building Groovy language tag file: 'status);
            gCancelledCompiler = compiler_name;
         } else {
            gCancelledCompiler = '';
         }
      }
   }

   return 0;
}

int _groovy_find_context_tags(_str (&errorArgs)[],_str prefixexp,
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


int _groovy_parse_return_type(_str (&errorArgs)[], typeless tag_files,
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

int _groovy_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
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
int _groovy_get_type_of_expression(_str (&errorArgs)[], 
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

int _groovy_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                     int tree_wid, int tree_index,
                                     _str lastid_prefix="", 
                                     bool exact_match=false, bool case_sensitive=true,
                                     _str param_name="", _str param_default="",
                                     struct VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_insert_constants_of_type(rt_expected,tree_wid,tree_index,lastid_prefix,exact_match,case_sensitive,param_name,param_default,visited,depth);
}

int _groovy_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                              struct VS_TAG_RETURN_TYPE &rt_candidate,
                              _str tag_name,_str type_name,
                              SETagFlags tag_flags,
                              _str file_name, int line_no,
                              _str prefixexp,typeless tag_files,
                              int tree_wid, int tree_index,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_match_return_type(rt_expected,rt_candidate,
                               tag_name,type_name,tag_flags,
                               file_name,line_no,
                               prefixexp,tag_files,
                               tree_wid,tree_index,
                               visited,depth);

}

int _groovy_fcthelp_get_start(_str (&errorArgs)[],
                              bool OperatorTyped,
                              bool cursorInsideArgumentList,
                              int &FunctionNameOffset,
                              int &ArgumentStartOffset,
                              int &flags,
                              int depth=0)
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,cursorInsideArgumentList,FunctionNameOffset,ArgumentStartOffset,flags,depth));
}

int _groovy_fcthelp_get(_str (&errorArgs)[],
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

_str _groovy_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   return(_c_get_decl(lang,info,flags,decl_indent_string,access_indent_string));
}

int _groovy_get_syntax_completions(var words)
{
   return _c_get_syntax_completions(words); 
}

bool _groovy_is_continued_statement()
{
   return _c_is_continued_statement();
}

static void getParenPos(_str innerTagType, long origCursorOffset, long startSeek, long endSeek, long& lparenPos, long& rparenPos)
{
   switch (innerTagType) {
   case 'call':
   case 'annotation':
   case "region":
   case "note":
   case "todo":
   case "warning":
   case 'loop':
   case 'if':
   case 'func':
   case 'constr':
   case 'switch':
   case 'try':      // catch clause only.
      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);

      // We assume only the ( as introducing params, since you can't do multi-line paren-less
      // calls without doing ugly escaped newlines.  But we do have to watch out for that case.
      _GoToROffset(startSeek);
      status := search('[([{]', '+<L@');
      if (status == 0) {
         lparenPos = _QROffset();
         find_matching_paren(true);
         rparenPos = _QROffset();

         if (lparenPos < startSeek || lparenPos > endSeek || rparenPos < startSeek || rparenPos > endSeek) {
            // Well, we didnt' find the delimiters inside of this statement.
            lparenPos = -1;
            rparenPos = -1;
         }
      } else {
         lparenPos = -1;
         rparenPos = -1;
      }

      restore_search(s1, s2, s3, s4, s5);
      break;

   case 'clause':
      lparenPos = startSeek;
      rparenPos = endSeek;
      break;

   default:
      lparenPos = -1;
      rparenPos = -1;
   }
   if (def_tag_edit_debug > 0) say('    getParenPos('innerTagType') = 'lparenPos', 'rparenPos);
}

static void get_pos_info(int searchStatus, _str& posChar, long& posOff, int& posLine)
{
   if (searchStatus) {
      posChar = '';
   } else {
      posChar = get_text();
      if (_clex_is_identifier_char(posChar) && _clex_find(0,'g')==CFG_KEYWORD) {
         posChar=cur_identifier(auto junk);
         if (posChar:=='') {
            posChar = get_text();
         }
      }
   }

   posOff = _QROffset();
   posLine = p_line;
}

static void get_chars_around_cursor(_str& leftChar, long& leftOff, int& leftLine, 
                                    _str& rightChar, long& rightOff, int& rightLine)
{
   here := _QROffset();

   // Scan forward for non-space char.
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   status := search('[^ \t\r\n]', '+<@L');
   get_pos_info(status, rightChar, rightOff, rightLine);

   _GoToROffset(here);
   if (status == 0 && here == rightOff) {
      // Move left if cursor is on right char.
      prev_char();
   }

   status = search('[^ \t\r\n]', '-<@L');
   get_pos_info(status, leftChar, leftOff, leftLine);
   restore_search(s1, s2, s3, s4, s5);
}

static int continuation_for_delim(_str ldelim) 
{
   return beaut_expr_paren_alignment();
}

// If continutationType < 0, we try to pick one by the delimiter character.
static int calc_delimited_list_indent(int continuationType, long cursorOff, long listStart, long listEnd, long leftOff, long rightOff,
                                      bool commaDelimited)
{
   int answer, delimCol;

   if (cursorOff == listStart || cursorOff > listEnd) {
      answer = 0;
   } else {
      _GoToROffset(leftOff);
      leftmostLine := p_line;
      _GoToROffset(listStart);
      ldelim := get_text();
      delimCol = p_col;
      if (def_tag_edit_debug > 0) say('   leftmostLine='leftmostLine', startLine='p_line', cont='continuationType', delimCol='delimCol);

      if (continuationType < 0) {
         continuationType = continuation_for_delim(ldelim);
      }

      if (leftOff == listStart) {
         // This is the first item in the list.
         switch (continuationType) {
         case COMBO_AL_AUTO:
         case COMBO_AL_CONT:
            answer = _first_non_blank_col(1) + beaut_continuation_indent();
            break;

         case COMBO_AL_PARENS:
            answer = delimCol + 1;
            break;
         }
      } else if (p_line == leftmostLine) {
         // Not the first item, but this is the first CR.
         switch (continuationType) {
         case COMBO_AL_AUTO:
         case COMBO_AL_PARENS:
            answer = delimCol + 1;
            break;

         case COMBO_AL_CONT:
            answer = _first_non_blank_col(1) + beaut_continuation_indent();
            break;
         }
      } else {
         // Not on first line or first item, just do what the last line did.
         _GoToROffset(leftOff);
         answer = _first_non_blank_col(1); 
      }
   }

   return answer;
}
static long get_linenum_from_seek(long offset) {
   save_pos(auto p);
   _GoToROffset(offset);
   linenum:=p_line;
   restore_pos(p);
   return p_line;
}

static int indent_in_paren_statement(int continuationType, _str tagType, long cursorOff, long startSeek, long endSeek, long leftOff, 
                                     long rightOff)
{
   answer := 0;

   if (tagType == 'func' && startSeek == 0 && _LanguageInheritsFrom('groovy')) {
      // Special case for the function context that covers the entire groovy file.
      answer = 1;
   } else {
      getParenPos(tagType, cursorOff, startSeek, endSeek, auto lparenPos, auto rparenPos);
      if (cursorOff > startSeek && cursorOff <= lparenPos) {
         // Before the parens, continuation indent.
         _GoToROffset(startSeek);
         answer = _first_non_blank_col(1) + beaut_continuation_indent();
      } else if (cursorOff > lparenPos && cursorOff <= rparenPos) {
         // In the parenthesis
         answer = calc_delimited_list_indent(continuationType, cursorOff, lparenPos, rparenPos, leftOff, rightOff, false);
      } else if (cursorOff > rparenPos && 
                 ( (cursorOff < endSeek) 
                    
                  /* 
                      This case occurs for the following:
                               if (i<j) <Enter-Here>
                           }   // Close paren of function or block
                  */
                    || (tagType != 'call' && leftOff==rparenPos && get_linenum_from_seek(leftOff)==get_linenum_from_seek(cursorOff))
                 )) {
         // Give it an indent if it's right after the rparen, or a {
         _GoToROffset(leftOff);
         lchar := get_text();
         _GoToROffset(startSeek);

         if (leftOff == '}') {
            answer = _first_non_blank_col(1);
         } else {
            answer = _first_non_blank_col(1) + p_SyntaxIndent;
         }
      } else if (cursorOff >= endSeek) {
         // Same indent as this statement.
         _GoToROffset(startSeek);
         answer = _first_non_blank_col(1);
      }
   }

   return answer;
}

static int generic_statement_indent(long startSeek, long endSeek, long cursorOff, bool indentAfterStmt, _str leftChar='')
{
   answer := 0;

   if (cursorOff == startSeek) {
      // Just use same indent.
      _GoToROffset(startSeek);
      answer = _first_non_blank_col(1);
   } else if (cursorOff > startSeek && cursorOff < endSeek) {
      // Just a continuation indent.
      _GoToROffset(startSeek);
      answer = _first_non_blank_col(1) + ((leftChar=='{' || leftChar=='else') ?p_SyntaxIndent:beaut_continuation_indent());
   } else if (cursorOff > (endSeek-1)) {
      // Indent from start.
      _GoToROffset(startSeek);
      if (indentAfterStmt) {
         answer = _first_non_blank_col(1) + p_SyntaxIndent;
      } else {
         answer = _first_non_blank_col(1);
      }
   }

   return answer;
}


static int indent_in_block_introduction(long startSeek, long endSeek, long cursorOff,_str leftChar)
{
   return generic_statement_indent(startSeek, endSeek, cursorOff, false,leftChar);
}

static int plain_statement_indent(long startSeek, long endSeek, long cursorOff,_str leftChar='')
{
   return generic_statement_indent(startSeek, endSeek, cursorOff, false,leftChar);
}

static bool isClosure(long startSeek) 
{
   save_pos(auto pp);
   _GoToROffset(startSeek);
   rv := get_text() == '{';
   restore_pos(pp);

   return rv;
}
static bool kotlin_when_has_parens(int ctx) {
   tag_get_detail2(VS_TAGDETAIL_statement_name, ctx, auto name);
   return name!='when';
}
static bool statement_starts_at_first_non_blank(long startSeek) {
   save_pos(auto p);
   _GoToROffset(startSeek);
   statement_start_col:=p_col;
   _first_non_blank();
   fnb_col:=p_col;
   restore_pos(p);

   return statement_start_col==fnb_col;
}
int calc_nextline_indent_from_tags()
{
   se.tags.TaggingGuard sentry;
   _str intro;

   save_pos(auto startPos);
   cursorOff := _QROffset();
   get_chars_around_cursor(auto leftChar, auto leftOff, auto leftLine, 
                           auto rightChar, auto rightOff, auto rightLine);

   if (def_tag_edit_debug > 0) say('calc_nextline_indent_from_tags here='cursorOff', lc='leftChar', lo='leftOff', ll='leftLine', rc='rightChar', ro='rightOff', rl='rightLine);
   sentry.lockContext(false);
   _UpdateStatements(true,true);
   ctx := tag_current_statement();
   if (ctx <= 0) {
      status:=_clex_skip_blanks('-');
      if (!status) {
         _first_non_blank();
         col:=p_col;
         restore_pos(startPos);
         return col;
      }
      restore_pos(startPos);
      return p_col;
   }
   
   answer := 0;
   innerCtx := ctx;
   innerType := '';

   while (ctx > 0) {
      tag_get_detail2(VS_TAGDETAIL_statement_start_seekpos, ctx, auto startSeek);
      tag_get_detail2(VS_TAGDETAIL_statement_end_seekpos, ctx, auto endSeek);
      tag_get_detail2(VS_TAGDETAIL_statement_type, ctx, auto tagType);
      tag_get_detail2(VS_TAGDETAIL_statement_outer, ctx, auto outer);
      if (answer != 0 && ctx != innerCtx && 
          ( (tagType == 'func' && startSeek == 0 && _LanguageInheritsFrom('groovy')) ||
            (endSeek>=p_buf_size && _LanguageInheritsFrom('kotlin') && get_extension(p_buf_name)=='kts')
          )
          ) {
         // If we have gone from a more specific context to the top level function
         // context that covers the entire file, then we have nothing helpful 
         // we can add to the answer.
         break;
      }

      if (innerType == '') {
         innerType = tagType;
      }

      if (def_tag_edit_debug > 0) say('   ctx='ctx', tagType='tagType' @ 'startSeek' -> 'endSeek);
      //say('   ctx='ctx', tagType='tagType' @ 'startSeek' -> 'endSeek);
      switch (tagType) {
      case 'block':
         // We're in an area the parser had to skip.  Default to AUTO indent behavior.
         _GoToROffset(leftOff);
         answer = _first_non_blank_col(1);
         if (leftChar == '{') {
            answer += p_SyntaxIndent;
         }
         ctx = -1;
         break;

      case 'clause':
         // Some sort of delimited list, like [a,b,c].  Or a closure.
         if (isClosure(startSeek)) {
            _GoToROffset(startSeek);
            answer = _first_non_blank_col(1) + p_SyntaxIndent;
            ctx = -1;
         } else {
            answer = calc_delimited_list_indent(-1, cursorOff, startSeek, endSeek, leftOff, rightOff, true);
            if (answer <= 0) {
               ctx = outer;
            } else {
               ctx = -1;
            }
         }
         break;

      case 'if':
         _GoToROffset(startSeek);
         intro = cur_identifier(auto junk_if);
         if (intro == 'if' || intro == 'switch'|| (intro=='when' && _LanguageInheritsFrom('kotlin') && kotlin_when_has_parens(ctx))) {
            // Control statements with an expression in (), and indent after the end.
            answer = indent_in_paren_statement(COMBO_AL_PARENS, tagType, cursorOff, startSeek, endSeek, leftOff, 
                                               rightOff);
         } else {
            // The else clause, has no parens to deal with.
            answer = indent_in_block_introduction(startSeek, endSeek, cursorOff,leftChar);
         }

         if (answer == 0) {
            ctx = outer;
         } else {
            ctx = -1;
         }
         break;

      case 'switch':
         if (p_LangId == 'scala') {
            // Scala's match statement differs enough where we need to 
            // special case it here.
            _GoToROffset(startSeek);
            answer = _first_non_blank_col(1) + p_SyntaxIndent;
            ctx = -1;
         } else {
            answer = indent_in_paren_statement(COMBO_AL_PARENS, tagType, cursorOff, startSeek, endSeek, leftOff, 
                                               rightOff);
            if (answer == 0) {
               ctx = outer;
            } else {
               ctx = -1;
            }
         }
         break;

      case 'loop':
      case 'func':
      case 'constr':
         // Control statements with an expression in (), and indent after the end.
         if (tagType == 'func' && isClosure(startSeek)) {
            // Closure {} has NO parens and must be handled specially here.
            _GoToROffset(startSeek);
            if (cursorOff>=endSeek) {
               answer = _first_non_blank_col(1);
               ctx=outer;
            } else { 
               answer = _first_non_blank_col(1) + p_SyntaxIndent;
               ctx = -1;
            }
            break;
         } else if (_LanguageInheritsFrom('kotlin') && tagType:=='loop') {
            typeless p;
            save_pos(p);
            _GoToROffset(startSeek);
            intro = cur_identifier(auto dont_care);
            // support for "do { ... } while(...)
            if (intro=='do') {
               restore_pos(p);
               tag_get_detail2(VS_TAGDETAIL_statement_scope_seekpos, ctx, auto scopeSeek);
               scopeEnd:=-1;
               endBraceCol:=-1;
               if (cursorOff>scopeSeek) {
                  // Check if cursor is after close brace do {}
                  _GoToROffset(scopeSeek-1);
                  // double check there is an open brace here
                  if (get_text(1):=='{') {
                     status:=find_matching_paren(true);
                     if (!status) {
                        endBraceCol=p_col;
                        scopeEnd=_QROffset();
                        if (cursorOff<=scopeEnd) {
                           scopeEnd=-1;
                        }
                     }
                  }
                  restore_pos(p);
                  if (scopeEnd>=0) {
                     // Skip blanks
                     _GoToROffset(cursorOff);
                     search('[^ \t]','@hr');
                     if(_clex_find(0,'g')==CFG_KEYWORD && get_text(1):=='w' && cur_identifier(auto junk2):=='while') {
                        /* 
                           Special processing for this:
                                do {
                                } <ENTER>while ()

                           Might need to check if cursor is in this area to do more works (maybe even support beautifier options)
                        */
                        answer=endBraceCol;
                     } else {
                        /* 
                           Make it look like this "while (expr)" is being processed.
                        */
                        restore_pos(p);
                        answer = indent_in_paren_statement(COMBO_AL_PARENS, 'loop', cursorOff, scopeSeek+1/*startSeek*/, endSeek, leftOff, 
                                                              rightOff);
                     }
                  }
               }
               if (scopeEnd==-1) {
                  answer = indent_in_paren_statement(COMBO_AL_PARENS, tagType, cursorOff, startSeek, endSeek, leftOff, 
                                                        rightOff);
               }

               if (answer == 0) {
                  ctx = outer;
               } else {
                  ctx = -1;
               }
               break;
            } else {
               restore_pos(p);
            }
         }
         // Handle parenthesized arguments for function definitions for other languages like C++ functions.
         // For C++, the beaut_funcall_param_alignment() setting is used and that's what we do here.
         answer = indent_in_paren_statement(
            tagType=='loop'?COMBO_AL_PARENS:beaut_funcall_param_alignment(), tagType, cursorOff, startSeek, endSeek, leftOff, 
            rightOff);
         if (answer == 0) {
            ctx = outer;
         } else {
            ctx = -1;
         }
         break;

      case 'call':
         // Function call continuation inside of parens, no indent after statement.
         answer = indent_in_paren_statement(beaut_funcall_param_alignment(), tagType, 
                                            cursorOff, startSeek, endSeek, leftOff, rightOff);
         if (cursorOff >= endSeek) {
            ctx = outer;
            if (outer<=0) {
               _GoToROffset(startSeek);
               answer = _first_non_blank_col(1);
               ctx = -1;
            }
         } else {
            ctx = -1;                   
         }
         break;

      case 'try':
         {
            _GoToROffset(startSeek);
            intro = cur_word(auto dont_care);
            if (intro == 'catch') {
               if (p_LangId == 'scala') {
                  // No parens after catch in Scala.
                  _GoToROffset(startSeek);
                  if (cursorOff>=endSeek && leftChar=='{') {
                     answer = _first_non_blank_col(1);
                  } else {
                     answer = _first_non_blank_col(1) + p_SyntaxIndent;
                  }
               } else {
                  answer = indent_in_paren_statement(COMBO_AL_PARENS, tagType, cursorOff, startSeek, endSeek, leftOff, rightOff);
               }
            } else {
               // try or finally
               answer = indent_in_block_introduction(startSeek, endSeek, cursorOff,leftChar);
            }

            if (answer == 0) {
               ctx = outer;
            } else {
               ctx = -1;
            }
         }
         break;

      case 'class':
      case 'enum':
      case 'interface':
         answer = indent_in_block_introduction(startSeek, endSeek, cursorOff,leftChar);
         if (answer == 0) {
            ctx = outer;
         } else {
            ctx = -1;
         }
         break;

      case 'lvar':
      case 'gvar':
      case 'var':
      case 'statement':
      case 'assign':
         answer = plain_statement_indent(startSeek, endSeek, cursorOff,leftChar);
         /* Make the assumption that if the cursor is in the middle of this statement AND
            this startment starts at the first non blank that we can use the indent result from plain_statement_indent().
            We could also check that there is a continuation operator (binary operator). Not sure if that
            would work better. Odds are the user wants an indented statement continuation.
         */
         if (cursorOff >= endSeek || cursorOff<=startSeek || !statement_starts_at_first_non_blank(startSeek)) {
            ctx = outer;
         } else {
            ctx = -1;                   
         }
         break;
      case 'annotation':
      case "region":
      case "note":
      case "todo":
      case "warning":
         answer = plain_statement_indent(startSeek, endSeek, cursorOff);
         ctx = outer;
         break;

      case 'import':
      case 'package':
         // We know the answer is 1 when we see this.
         answer = 1;
         ctx = -1;

      default:
         ctx = outer;
      }
      if (def_tag_edit_debug > 0) say('    answer so far:'answer);
   }

   if (answer == 0) {
      // Just default to last line indent.
      _GoToROffset(leftOff);
      answer = _first_non_blank_col(1);
   }


   if (def_tag_edit_debug > 0) say('   ANSWER='answer);
   restore_pos(startPos);
   return answer;
}

int groovy_smartpaste(bool char_cbtype,int first_col,int Noflines,bool allow_col_1=false)
{
   int comment_col=0;
   // Find first non-blank line which could be a comment.
   first_line := "";
   i := j := 0;
   for (j=1;j<=Noflines;++j) {
      get_line(first_line);
      i=verify(first_line,' '\t);
      if ( i ) {
         p_col=text_col(first_line,i,'I');
      }
      if (i) {
         break;
      }
      if(down()) {
         break;
      }
   }
   comment_col=p_col;  // Comment column or code column.
   //IF the lines we are pasting contain a non-blank line
   if (j<=Noflines) {
      // Skip to first code char
      int status=_clex_skip_blanks('m');
      if (!status) {
         updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
         //int syntax_indent=p_SyntaxIndent;
         if (!status && get_text()=='}') {
            // Adjust what we are pasting relative to the comment.
            // It's ok if there was no comment. adjust_col will be 0.
            int adjust_col=comment_col-p_col;
            ++p_col;
            int enter_col=c_endbrace_col();
            if (enter_col) {
               enter_col+=(adjust_col);
               if (enter_col>=1) {
                  _begin_select();up();
                  return enter_col;
               }
            }
         }
      }
   }
   _begin_select();
   up();
   end_line();
   return calc_nextline_indent_from_tags();
}

static _str groovy_exe_path(_str groovyHome, _str exeName)
{
   rv := groovyHome;
   _maybe_append(rv, FILESEP);

   return rv :+ 'bin' :+ FILESEP :+ exeName :+ EXTENSION_BAT;
}

static bool valid_groovy_home(_str gh)
{
   rv := false;

   if (file_exists(groovy_exe_path(gh, 'groovy'))) {
      // Almost there. This test alone can give a false match for /usr on linux which
      // won't work because there's no /usr/lib/groovy-*.jar, so check for the jar too.
      jp := gh;
      _maybe_append(jp, FILESEP);
      jp = _maybe_quote_filename(jp'lib'FILESEP'groovy-*.jar');
      fn := file_match(jp' -P', 1);
      rv = (fn != '');
   }
   return rv;
}

_str calc_groovy_home()         
{
   if (def_groovy_home != '' && valid_groovy_home(def_groovy_home)) {
      return def_groovy_home;
   }

   ev := get_env('GROOVY_HOME');
   if (ev != '' && valid_groovy_home(ev)) {
      if (def_groovy_home == '') {
         def_groovy_home = ev;
      }
      return ev;
   }

   if (_isUnix() && valid_groovy_home('/usr/share/groovy')) {
      if (def_groovy_home == '') {
         def_groovy_home = '/usr/share/groovy';
         return def_groovy_home;
      }
   }

   return '';
}

_str ensure_groovy_home()
{
   rv := calc_groovy_home();

   if (rv == '') {
      rv = show('_groovy_home_selection_form -modal');
      if (valid_groovy_home(rv)) {
         def_groovy_home = rv;
      } else {
         rv = '';
      }
   }

   return rv;
}

// Callback for the project support, so we can set the GROOVY_HOME environent 
// variable so it can be used inside of the projects.
int _groovy_set_environment(int projectHandle, _str config, _str target, 
                            bool quite, _str error_hint)
{
   rv := 1;

   if (_ProjectGet_AppType(projectHandle, config) == 'gradle') {
      rv = setup_gradle_environment();
   } else {
      gh := ensure_groovy_home();

      if (gh != '') {
         // Set for this process....
         set_env('GROOVY_HOME', gh);

         // And also add it to the environment for the build system (which may
         // already have a shell spawned).
         _restore_origenv(false);
         set('GROOVY_HOME='gh);
         rv = 0;
      }
   }

   return rv;
}

_str build_classpath_from_jar_dir(_str root)
{
   rv := "";
   filename:= file_match(root' -P',1);         // find first.
   for (;;) {
       if (filename=='' )  break;
       _maybe_append(rv, PATHSEP);
       rv :+= filename;
       filename= file_match(filename,0);      
   }

   return  rv;
}

_str groovy_classpath()
{
   gh := ensure_groovy_home();
   _maybe_append(gh, FILESEP);
   root := _maybe_quote_filename(gh :+ 'lib' :+ FILESEP :+ '*.jar');
   return build_classpath_from_jar_dir(root);
}

static void update_paths_state(typeless dummy = null)
{
   homedir := strip(_ctl_groovy_home.p_text);

   if (valid_groovy_home(homedir)) {
      _ctl_home_error.p_visible = false;
   } else {
      _ctl_home_error.p_caption = "* '"homedir"' is not a valid Groovy install";
      _ctl_home_error.p_visible = true;
   }
}

defeventtab _groovy_home_selection_form;

void _ctl_groovy_home.on_change()
{
   update_paths_state(0);
}

void _ctl_groovy_home.on_create()
{
   _ctl_groovy_home.p_text = calc_groovy_home();
   update_paths_state(0);

   sizeBrowseButtonToTextBox(_ctl_groovy_home.p_window_id, 
                             _browsedir1.p_window_id, 0, 
                             p_active_form.p_width - _ctl_groovy_home.p_prev.p_x);
}

void _ctl_groovy_home.'ENTER'()
{
   p_active_form._delete_window(_ctl_groovy_home.p_text);
}

void _ctl_groovy_home_ok.lbutton_up()
{
   p_active_form._delete_window(_ctl_groovy_home.p_text);
}

// Support for same dialog embedded into the options tree.
void _groovy_home_selection_form_init_for_options(_str langid)
{
   _nocheck _control _ctl_groovy_home;
   _nocheck _control _ctl_groovy_home_ok;

   gh := calc_groovy_home();
   if (gh == '') {
      gh = def_groovy_home;
   }

   _ctl_groovy_home.p_text = gh;
   update_paths_state(0);
   _ctl_groovy_home_ok.p_visible = false;
}

bool _groovy_home_selection_form_apply()
{
   _nocheck _control _ctl_groovy_home;

   def_groovy_home = _ctl_groovy_home.p_text;
   return true;
}

bool _groovy_home_selection_form_is_modified()
{
   _nocheck _control _ctl_groovy_home;

   return _ctl_groovy_home.p_text != calc_groovy_home();
}

/**
 * Unfortunately, groovy numbers are boxed by default, and have 
 * more variations than can map on the primitive type names.  So 
 * we directly mapped to the boxed types here, otherwise, we 
 * would lose type information. 
 */
int _groovy_get_type_of_number(_str ch, struct VS_TAG_RETURN_TYPE& rt)
{
   first := substr(ch, 1, 1);
   second := substr(ch, 2, 1);
   last := substr(ch, ch._length(), 1);
   ty := "";
   isHex := false;

   if (isdigit(first)) {
      if (first == "0" && (second == "B" || second == "b" || second == "x" || second == "X" || isdigit(second))) {
         // octal, binary, hex - defaults to an ineger type.
         ty = "java/math/BigInteger";
         isHex =  (second == "x") || (second == "X");
      } else if (pos("[.eE]", ch, 1, "L")) {
         ty = "java/math/BigDecimal";
      } else {
         ty = "java/math/BigInteger";
      }
   } else {
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   if (isalpha(last)) {
      // Maybe a type suffix.
      if (last == "G" || last == "g") {
         // ty is already set to the "Big" versions of the numbers.
      } else if (last == "L" || last == "l") {
         ty = "java/lang/Long";
      } else if (last == "I" || last == "i") {
         ty = "java/lang/Integer";
      } else if (last == "D" || last == "d") {
         ty = "java/lang/Double";
      } else if (!isHex && (last == "F" || last == "f")) {
         ty = "java/lang/Float";
      } else {
         // Not a known number suffix.
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
   }
   
   rt.return_type = ty;
   rt.return_flags = 0;
   return 0;
}

