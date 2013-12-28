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

/*
  Things that could still be done

  * Add support to cursor_error for python import statements
*/
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "cutil.e"
#import "csymbols.e"
#import "hotspots.e"
#import "main.e"
#import "markfilt.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "seek.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for Python syntax expansion/indenting may be accessed from the
  Extension Options dialog ("Other", "Configuration...",
  "File Extension Setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             reserved.
       4             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
*/

#define NO_SPACE_BEFORE_PAREN 16   // "if(" or "if ("

#define PY_MODE_NAME    'Python'
#define PY_LANGUAGE_ID  'py'

defeventtab python_keys;
def " "=python_space;
def "TAB"=smarttab;
def "ENTER"=python_enter;
def "("=auto_functionhelp_key;
def "."=auto_codehelp_key;
def ":"=python_colon;

defload()
{
   _str setup_info='MN='PY_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='PY_MODE_NAME'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',';
   _str compile_info='';
   _str syntax_info='4 1 1 0 4 1 0 0 0';
   _str be_info='';
   
   _CreateLanguage(PY_LANGUAGE_ID, PY_MODE_NAME,
                   setup_info, compile_info,
                   syntax_info, be_info, '', '', PY_MODE_NAME);
   _CreateExtension('py', PY_LANGUAGE_ID);
   replace_def_data("def-encoding-"PY_LANGUAGE_ID,'+fautounicode2');
}

/**
 * Switch to Python editing mode
 */
_command void python_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(PY_LANGUAGE_ID);
}

/**
 * Handle ENTER key in Python editing mode.
 * This attempts to intelligently indent the next
 * line, by either indenting to the current indent
 * level, or indenting one more level deep.
 * <P>
 * Because of the nature of Python using indentation
 * to indicate the end of constructs, it is not possible
 * to detect where to automatically move up a level
 * of indentation (DEDENT).
 */
_command void python_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_py_expand_enter, true);
}


/**
 * Handle SPACE key in Python editing mode.
 * This simply does some rudimentory syntax expansion.
 *
 * @return
 */
_command void python_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state() ||
       ! doExpandSpace(p_LangId) ||
       p_SyntaxIndent<0 ||
       _in_comment() ||
       python_expand_space()) {
      if (command_state()) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

/**
 * <b>Hook Function</b> -- This function gets called from
 * find_matching_paren() when it fails to find any matching
 * paren to do the ordinary paren-matching.  It tries to match
 * the colon (:) at the end of a class, proc, loop, if or try
 * statement to the end of its respective context, and vise
 * versa. 
 *  
 * This function uses Python's statement tagging functionality.
 */
int _py_find_matching_word(boolean quiet)
{
   _str standard_errmsg = "No match found";

   if (p_col < 2) {
      if (!quiet) {
         message(standard_errmsg);
      }
      return 1;
   }

   // We update context only when the quiet option is on, because this
   // function's parent function, find_matching_paren(), gets called at
   // every key stroke, and we want to avoid unnecessarily updating 
   // context here which would cause vspy_list_tags to be executed twice
   // at every key stroke. (kohei - 2/27/2007)
   if (!quiet) {
      _UpdateContext(true, false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   save_pos(auto p);
   left();
   int cxtid = tag_current_statement();
   restore_pos(p);
   if (cxtid == 0) {
      // No context found.
      if (!quiet) {
         message("No context found");
      }
      return 1;
   }

   // Keep moving to outer contexts until we find one of class, function, for/while,
   // if, or try statement contexts, where a colon is used to indicate the end of 
   // statement.
   struct VS_TAG_BROWSE_INFO cm;
   tag_get_context_info(cxtid, cm);
   while (cm.type_name != 'class' && cm.type_name != 'proc' && cm.type_name != 'loop' &&
          cm.type_name != 'if' && cm.type_name != 'try') {

      int temp_cxtid = 0;
      tag_get_detail2(VS_TAGDETAIL_context_outer, cxtid, temp_cxtid);
      if (temp_cxtid == 0) {
         // No usable context found.
         if (!quiet) {
            message("No usable context found");
         }
         return 1;
      }

      tag_get_context_info(temp_cxtid, cm);
      cxtid = temp_cxtid;
   }

   long begin_seek = cm.seekpos, end_seek = cm.end_seekpos;

   // Get the character at the cursor.
   _str ch = _expand_tabsc(p_col-1, 1);
   if (ch :== ':') {
      // The cursor is at the colon.  Jump to the end of context.
      _GoToROffset(end_seek);
      return 0;
   }

   // Check if the cursor is at the end seek position of a context.
   long cur_seekpos = _QROffset();
   if (cur_seekpos != end_seek) {
      if (!quiet) {
         message(standard_errmsg);
      }
      return 1;
   }

   // The cursor is at the end of a context.  Move to the start position
   // of the context, and find the first colon.
   save_pos(p);
   cur_seekpos = begin_seek;
   _GoToROffset(cur_seekpos);
   int status = search('{[(\[\{:]}', '@rhXcsc');
   while (!status) {
      cur_seekpos = match_length('S0');
      if (cur_seekpos >= end_seek) {
         // Past the end of context.  Bail out.
         restore_pos(p);
         if (!quiet) {
            message("Could not find ':'");
         }
         return 1;
      }
      _GoToROffset(cur_seekpos);
      ch = _expand_tabsc(p_col, 1);
      if (ch :== ':') {
         // A colon is found!
         right();
         return 0;
      } else if (ch :== '(' || ch :== '[' || ch :== '{') {
         // Jump to the closing paren and continue search.
         find_matching_paren(true);
      }
      status = repeat_search();
   }

   if (!quiet) {
      message(standard_errmsg);
   }
   return 1;
}

// Keywords that begin typical multi-line statements in Python.
#define PYTHON_BLOCK_WORDS ' class def elif else except finally for if try while '

// keywords that require syntax expansion
#define PYTHON_EXPAND_WORDS ' for if elif else def class try finally while '

static SYNTAX_EXPANSION_INFO python_space_words:[] = {
   'and'        => { "and" },
   'assert'     => { "assert" },
   'break'      => { "break" },
   'class'      => { "class ... : ..." },
   'continue'   => { "continue" },
   'def'        => { "def ... ( ... ): ..." },
   'del'        => { "del" },
   'elif'       => { "elif ... : ..." },
   'else'       => { "else: ..." },
   'except'     => { "except ... : ..." },
   'exec'       => { "exec" },
   'finally'    => { "finally: ..." },
   'for'        => { "for ... in ... : ..." },
   'from'       => { "from ... import ..." },
   'global'     => { "global" },
   'if'         => { "if ... : ..." },
   'import'     => { "import" },
   'in'         => { "in" },
   'is'         => { "is" },
   'lambda'     => { "lambda" },
   'not'        => { "not" },
   'or'         => { "or" },
   'pass'       => { "pass" },
   'print'      => { "print" },
   'raise'      => { "raise" },
   'return'     => { "return" },
   'self'       => { "self" },
   'try'        => { "try: ..." },
   'while'      => { "while ... : ..." },
};

/**
 * Determines the column position of the next line down based on
 * the content of the anchor line.  The anchor line must include 
 * any leading whitespace if present. 
 * <p> 
 * Please ensure that, before calling this function, the cursor 
 * location is the actual cursor location on screen, because 
 * this function performs parenthesis matching from the current 
 * cursor location. 
 * 
 * @param cur_line         anchor line content, including the 
 *                         leading whitespace.
 *
 * @return indent column position on the next line
 */
int python_indent_col(_str cur_line='', int num_line_ups=0)
{
   // Make sure the syntax indent option is on and we are not at the end of a line comment
   if (!_py_isSyntaxIndentOn()) {
      return 0;
   }
   return(py_getIndentCol());
}


/*
 * Do syntax indentation on the ENTER key.
 * Returns non-zero number if pass through to enter key required
 */
typeless _py_expand_enter()
{
   int orig_col=p_col;
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line' || 
       (enter_cmd:=='maybe-split-insert-line' && !_insert_state())
       ) {
      _end_line();
   }
   int col=py_getIndentCol();
   if (col<=0) {
      col=orig_col;
   }

   indent_on_enter(0,col);
   return 0;
}

/*
 * Do syntax expansion on space bar, eg. for statement or alias
 * completion / expansion.
 *
 * Returns true if nothing is done.
*/
static boolean python_expand_space()
{
   // get current line and check columns
   boolean status = false;
   _str orig_line;get_line(orig_line);
   _str line=strip(orig_line,'T');
   _str orig_word = strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return (true);
   }

   // find matches to word on line
   _str first_word,second_word,aliasfilename='';
   parse orig_word with first_word second_word;
   _str word = min_abbrev2(orig_word, python_space_words, name_info(p_index), aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   // check for special case of 'else' of 'elif'
   _str rest='';
   boolean if_special_case=false;
   if ( word=='') {
      parse orig_line with first_word second_word rest;
      if (first_word=='elif' && orig_word==substr('elif',1,length(orig_word))) {
         word='elif';
         if_special_case=true;
      }
      return(1);
   }

   // replace original word with new word on line
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN);
   _str maybespace=p_no_space_before_paren?'':' ';
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;

   // handle the special cases
   set_surround_mode_start_line();
   doNotify := true;
   if ( word=='if' || word=='elif' || if_special_case || word=='except' || word=='while') {
      if (word=='elif' || word=='except') {
         reindent_block_word(false);
         get_line(line);
      }
      replace_line(line' :');
      _end_line(); left();
      set_surround_mode_end_line(p_line+1, 0);
   } else if ( word=='try' || word=='finally') {
      replace_line(line':');
      _end_line();
      set_surround_mode_end_line(p_line+1, 0);
   } else if (word=='else') {
      replace_line(line);
      _end_line();
      last_event(':');call_key(':');
      set_surround_mode_end_line(p_line+1, 0);
   } else if ( word=='for' ) {
      // TODO: hack alert! - let's find a way to simplify this.
      clear_hotspots();
      replace_line(line' in :');
      p_col += 1;
      add_hotspot();
      _end_line();
      p_col -= 1;
      add_hotspot();
      p_col -= 4;
      keyin(' ');
      set_surround_mode_end_line(p_line+1, 0);
   } else if ( word=='from' ) {
      clear_hotspots();
      replace_line(line'  import ');
      add_hotspot();
      _end_line();
      add_hotspot();
      p_col-=8;
   } else if ( word=='return' ) {
      if (orig_word=='return') {
         keyin(' ');
         doNotify = false;
      } else {
         newLine := indent_string(width)'return ';
         replace_line(newLine);
         _end_line();
         doNotify = (newLine != orig_line);
      }
   } else if ( word=='def' ) {
      clear_hotspots();
      replace_line(line' 'maybespace'():');
      add_hotspot();
      _end_line();
      p_col -= 2;
      add_hotspot();
      p_col -= length(maybespace) + 1;
   } else if ( word=='self' ) {
      replace_line(line);
      _end_line();
      doNotify = (line != orig_line);
   } else if ( word=='class' ) {
      replace_line(line' :');
      _end_line(); left();
   } else if ( word=='continue' || word=='break' ) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if ( pos(' 'word' ',PYTHON_EXPAND_WORDS) || word!=orig_word) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else {
      status=1;
      doNotify = false;
   }
   show_hotspots();

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status);
}

int _py_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,python_space_words);
}
/**
 * Handle <b>SmartPaste&reg;</b> in Python. 
 * <p> 
 * In Python mode, only a line selection can be SmartPaste'd, 
 * and the line selection must be such that the first selected 
 * line always has the least amount of indentation. 
 *
 * @param char_cbtype pasting character selection?
 * @param first_col first column where pasting
 * @return destination column position based on current context, 
 *         or 0 on failure.  When 0 is returned, the calling
 *         function performs a normal paste.
 */
int py_smartpaste(boolean char_cbtype, int first_col,int Noflines,boolean allow_col_1=false)
{
   _begin_select();up();
   _end_line();
   save_pos(auto p4);
   // Look for first piece of code not in a comment
   typeless status=_clex_skip_blanks('m');
   if (status) {
      restore_pos(p4);
   } else {
      auto word=cur_word(auto junk_col);
      int col=0;
      if (word=='elif') {
         col=find_block_start_col('if');
      } else if (word=='else') {
         col=find_block_start_col('while|for|if|try');
      } else if ((word=='except') || word=='finally') {
         col=find_block_start_col('try');
      }
      restore_pos(p4);
      if (col) {
         return(col);
      }
   }
   _begin_select();up();
   _end_line();
   int col=python_indent_col();
   return col;
}

/**
 * Build a tag file for Python.  Looks in the
 * registry on Windows to find the installation
 * path for the CygWin distribution of the Python
 * interpreter.  Failing that does a path search
 * for the python interpreter executable (python.exe),
 * and tags any .py files under the "lib" directory,
 * excluding the "test" directory.
 *
 * @param tfindex Set to the index of the extension specific
 *                tag file for Python.
 * @return 0 on success, nonzero on error
 */
int _py_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   _str ext='py';
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,"python")) {
      return(0);
   }

   // The user does not have an extension specific tag file for Python
   _str python_dir='';
#if !__UNIX__
   python_dir=_ntRegGetPythonPath();
#endif
   if (python_dir=='') {
      python_dir=path_search("python","","P");
      if (python_dir!='') {
         python_dir=_strip_filename(python_dir,"n");
      }
   }
#if __UNIX__
   if (python_dir=='' || python_dir=='/' || python_dir=='/usr/' || python_dir=='/usr/bin/') {
      python_dir=latest_version_path('/usr/lib/python');
      //_message_box('python_dir='python_dir);
      if (python_dir=='') {
         python_dir=latest_version_path('/opt/python');
      }
   }
#endif
   _str std_libs="";
   _str tk_libs="";
   _str win_libs="";
   if (python_dir!="") {
      _str path=python_dir;
      if (last_char(path)!=FILESEP) {
         path=path:+FILESEP;
      }
      _str source_path=file_match('-p 'maybe_quote_filename(path:+"lib"), 1);
      if (source_path!='') {
         path=path:+"lib":+FILESEP;
      }
      std_libs=maybe_quote_filename(path:+"*.py");
      tk_libs=maybe_quote_filename(path:+"lib-tk":+FILESEP:+"*.py");
      win_libs=maybe_quote_filename(path:+"Plat-Win":+FILESEP:+"*.py");
      //say("_py_MaybeBuildTagFile: path="path" std_libs="std_libs);
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"Python Libraries",
                           false,std_libs' 'tk_libs' 'win_libs,
                           ext_builtins_path(ext,"python"));
}

/**
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.
 *
 * @param errorArgs array of strings for error message arguments
 *                  refer to codehelp.e VSCODEHELPRC_
 * @param OperatorTyped
 *                  When true, user has just typed last
 *                  character of operator.
 *                  Example: <CODE>self.</CODE>&lt;Cursor Here&gt;
 *                  This should be false if cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList
 *                  When true, user requested function help
 *                  when the cursor was inside an argument list.
 *                  Example: <CODE>MessageBox(...,</CODE>&lt;Cursor Here&gt;<CODE>...)</CODE>
 *                  Here we give help on MessageBox
 * @param FunctionNameOffset
 *                  (reference) Offset to start of function name.
 * @param ArgumentStartOffset
 *                  (reference) Offset to start of first argument
 * @param flags     (reference) function help flags
 * @return <UL>
 *         <LI>0    Successful
 *         <LI>VSCODEHELPRC_CONTEXT_NOT_VALID
 *         <LI>VSCODEHELPRC_NOT_IN_ARGUMENT_LIST
 *         <LI>VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 *         </UL>
 */
int _py_fcthelp_get_start(_str (&errorArgs)[],
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
/**
 * Context Tagging&reg; hook function for retrieving the information about
 * each function possibly matching the current function call that
 * function help has been requested on.
 * <p>
 * <b>Note:</b> If there is no help for the first function,
 * a non-zero value is returned and message is usually displayed.
 * <p>
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 * <p>
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <pre>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type=0;
 * </pre>
 *
 * @param errorArgs                  array of strings for error message arguments
 *                                   refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list          Structure is initially empty.
 *                                   FunctionHelp_list._isempty()==true
 *                                   You may set argument lengths to 0.
 *                                   See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed  (reference)Indicates whether the data in
 *                                   FunctionHelp_list has been changed.
 *                                   Also indicates whether current
 *                                   parameter being edited has changed.
 * @param FunctionHelp_cursor_x      (reference) Indicates the cursor x position
 *                                   in pixels relative to the edit window
 *                                   where to display the argument help.
 * @param FunctionHelp_HelpWord      Help topic to look up for this item
 * @param FunctionNameStartOffset    The text between this point and
 *                                   ArgumentEndOffset needs to be parsed
 *                                   to determine the new argument help.
 * @param flags                      function help flags (from fcthelp_get_start)
 *
 * @return int
 *    Returns 0 if we want to continue with function argument
 *    help.  Otherwise a non-zero value is returned and a
 *    message is usually displayed.
 *    <dl compact>
 *    <dt> 1    <dd> Not a valid context
 *    <dt> 2-9  <dd> (not implemented yet)
 *    <dt> 10   <dd> Context expression too complex
 *    <dt> 11   <dd> No help found for current function
 *    <dt> 12   <dd> Unable to evaluate context expression
 *    </dl>
 */
int _py_fcthelp_get(_str (&errorArgs)[],
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
int _py_get_expression_info(boolean PossibleOperator,
                            VS_TAG_IDEXP_INFO &info,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, 
                            int depth=0)
{
#if 0
   _str line;
   info.info_flags = 0;
   info.lastid = "main";
   info.prefixexp = "import";
   //return 0;
#endif 
   status := _c_get_expression_info(PossibleOperator, info, visited, depth);
   return status;
}

static void dump_context() 
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int i;
   for (i=1;i<=tag_get_num_of_context();++i) {
      _str tag_name;
      tag_get_detail2(VS_TAGDETAIL_context_name,i,tag_name);
      _str tag_args;
      tag_get_detail2(VS_TAGDETAIL_context_args,i,tag_args);
      _str return_only;
      tag_get_detail2(VS_TAGDETAIL_context_return_only,i,return_only);
      _str type;
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type);
      _str className;
      tag_get_detail2(VS_TAGDETAIL_context_class,i,className);
      int start_seekpos;
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,i,start_seekpos);
      int start_linenum;
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,start_linenum);


      int name_seekpos;
      tag_get_detail2(VS_TAGDETAIL_context_name_seekpos,i,name_seekpos);
      int name_linenum;
      tag_get_detail2(VS_TAGDETAIL_context_name_linenum,i,name_linenum);

      int scope_seekpos;
      tag_get_detail2(VS_TAGDETAIL_context_scope_seekpos,i,scope_seekpos);
      int end_seekpos;
      tag_get_detail2(VS_TAGDETAIL_context_end_seekpos,i,end_seekpos);
      int end_linenum;
      tag_get_detail2(VS_TAGDETAIL_context_end_linenum,i,end_linenum);
      _str parents;
      tag_get_detail2(VS_TAGDETAIL_context_parents,i,parents);
      int outer;
      tag_get_detail2(VS_TAGDETAIL_context_outer,i,outer);
      int flags;
      tag_get_detail2(VS_TAGDETAIL_context_flags,i,flags);
      _str tempArgs;
      tag_get_detail2(VS_TAGDETAIL_context_template_args,i,tempArgs);
      say(' i='i' c='className' v='type' tgn='tag_name' ta='tag_args' p='parents' st='start_seekpos' stln='start_linenum' scp='scope_seekpos' e='end_seekpos' eln='end_linenum' outer='outer' tempArgs='tempArgs);
      say('    nameloc ln='name_linenum' ofs='name_seekpos);
      say('    return_only='return_only);
      say('    inclass='(flags&VS_TAGFLAG_inclass));
      say('    private='((flags&VS_TAGFLAG_access)==VS_TAGFLAG_private));

   }
}
/**
 * <B>Hook Function</B> -- _[ext]_find_context_tags
 * <p>
 * Find a list of tags matching the given identifier after
 * evaluating the prefix expression.
 *
 * @param errorArgs         array of strings for error message arguments
 *                          refer to codehelp.e VSCODEHELPRC_*
 * @param prefixexp         prefix of expression (from _&lt;ext&gt;_get_expression_info
 * @param lastid            last identifier in expression
 * @param lastidstart_offset seek position of last identifier
 * @param info_flags        bitset of VS_CODEHELPFLAG_*
 * @param otherinfo         used in some cases for extra information
 *                          tied to info_flags
 * @param find_parents      for a virtual class function, list all
 *                          overloads of this function
 * @param max_matches       maximum number of matches to locate
 * @param exact_match       if true, do an exact match, otherwise
 *                          perform a prefix match on lastid
 * @param case_sensitive    if true, do case sensitive name comparisons
 * @param visited           hash table of prior results
 * @param depth             depth of recursive search
 *
 * @return return 0 on success, or VSCODEHELPRC_NO_SYMBOLS_FOUND
 * on failure.
 */
int _py_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                          _str lastid,int lastidstart_offset,
                          int info_flags,typeless otherinfo,
                          boolean find_parents,int max_matches,
                          boolean exact_match,boolean case_sensitive,
                          int filter_flags=VS_TAGFILTER_ANYTHING,
                          int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                          VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   // id followed by paren, then limit search to functions
   //say("_py_find_context_tags: lastid="lastid" prefixexp="prefixexp);
   errorArgs._makeempty();
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // get the current class from the context
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) ||
       (context_flags & VS_TAGCONTEXT_ONLY_locals)) {
      tag_files._makeempty();
   }

   // from a referenced module namespace.  Note that only those symbols in the
   // global namespace can be imported.
   // 
   //     from <referenced module> import arg1, arg2, arg3, ....
   //
   num_matches := 0;
   tag_clear_matches();
   if (!(context_flags & VS_TAGCONTEXT_ONLY_locals) &&
       !(context_flags & VS_TAGCONTEXT_NO_globals) &&
       !(context_flags & VS_TAGCONTEXT_ONLY_inclass)) {
      get_line(auto line);
      if ( pos('^[ \t]*from[ \t]#{(:a|[_])#}[ \t]{import}', line, 1, 'r') > 0 ) {
         if (p_col > pos('S1') + pos('1')) {
            module_name := substr(line, pos('S0'), pos('0'), '');
            tag_list_in_class(lastid, module_name, 
                              0, 0, tag_files, 
                              num_matches, max_matches, 
                              filter_flags, context_flags,
                              exact_match, case_sensitive,
                              null, null, visited, depth);
            errorArgs[1] = lastid;
            return (num_matches > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
         }
      }
   }

   _str cur_tag_name='';
   _str cur_type_name='';
   _str cur_class_name='';
   _str cur_class_only='';
   _str cur_package_name='';
   int cur_tag_flags=0;
   int cur_type_id=0;
   int context_id = tag_get_current_context(cur_tag_name,cur_tag_flags,
                                            cur_type_name,cur_type_id,
                                            cur_class_name,cur_class_only,
                                            cur_package_name);

   int context_list_flags = VS_TAGCONTEXT_FIND_all;
   if (find_parents) context_list_flags |= VS_TAGCONTEXT_FIND_parents;

   // no prefix expression, update globals and symbols from current context
   if (prefixexp == '') {
      return _do_default_find_context_tags(errorArgs,
                                           prefixexp,
                                           lastid, 
                                           lastidstart_offset,
                                           info_flags,
                                           otherinfo,
                                           find_parents,
                                           max_matches,
                                           exact_match,
                                           case_sensitive,
                                           filter_flags,
                                           context_flags|context_list_flags,
                                           visited, depth);
   }

   // analyse prefix expression to determine effective class type
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   status := _c_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
   //say("_py_find_context_tags: MATCH_CLASS="rt.return_type" status="status);
   if (status) {
      return status;
   }
   context_flags |= VS_TAGCONTEXT_ONLY_inclass;
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
      context_flags |= VS_TAGCONTEXT_ONLY_static;
   }
   if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      context_flags |= VS_TAGCONTEXT_ALLOW_locals;
   }
   if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS)) {
      context_flags |= VS_TAGCONTEXT_ALLOW_private;
      context_flags |= VS_TAGCONTEXT_ALLOW_protected;
   }

   tag_list_in_class(lastid, rt.return_type,
                     0, 0, tag_files,
                     num_matches, max_matches,
                     filter_flags, context_flags,
                     exact_match, case_sensitive, 
                     null, null, 
                     visited, depth);

   if (num_matches == 0 && rt.return_type!="" && 
       !(context_flags & VS_TAGCONTEXT_NO_globals)) {
      tag_list_symbols_in_context(lastid, "",
                                  0, 0, tag_files, '',
                                  num_matches, max_matches, 
                                  filter_flags, context_flags, 
                                  exact_match, true, visited, depth);

   }

   errorArgs[1] = lastid;
   return (num_matches > 0)? 0 : VSCODEHELPRC_NO_SYMBOLS_FOUND;
}

/**
  On entry, cursor is on line,column of tag symbol.
  Finds the starting line and ending line for the tag's comments.

  @param first_line   (output) set to first line of comment
  @param last_line    (output) set to last line of comment

  @return 0 if header comment found and first_line,last_line
          set.  Otherwise, 1 is returned.
*/
int _py_get_tag_header_comments(int &first_line,int &last_line)
{
   // skip blank lines after tag
   int count=1;
   typeless orig_pos;
   save_pos(orig_pos);
   for (;;) {
      if (down()) {
         restore_pos(orig_pos);
         return(1);
      }
      _str line;get_line(line);
      if (line!="" && count>10) {
         break;
      }
      first_non_blank('h');
      if (_clex_find(0,'g')==CFG_STRING) {
         break;
      }
      ++count;
   }
   // skip past leading spaces
   first_non_blank('h');
   // check that we have the start of a triple-quoted string
   if (_clex_find(0,'g')!=CFG_STRING) {
      restore_pos(orig_pos);
      return(1);
   }
   // save the starting line of the comment
   first_line=p_line;
   // Search for end of string
   int status=_clex_find(STRING_CLEXFLAG,'n');
   if (status) {
      bottom();
   } else {
      _clex_find(STRING_CLEXFLAG,'O-');
   }
   last_line=p_line;
   // that's all, restore position and return success
   restore_pos(orig_pos);
   return(0);
}

/**
 * <b>Hook Function</b> -- _[ext]_is_smarttab_supported
 * <p>
 * Extension callback function to signal whether the Python
 * language extension supports smart-tab.
 * <p>
 * If supported, the extention options dialog enables the
 * associated controls grouped by label "When tab key reindents
 * the line".  This option value is set to the global
 * <i>def_smarttab_py</i> variable.
 * 
 * @return boolean true if supported, false otherwise.
 */
boolean _py_is_smarttab_supported()
{
   return true;
}

/**
 * Global variable to keep track of the last context ID used for
 * select code block.
 */
static int _py_selectcb_last_context_id = 0;

/**
 * <b>Hook Function</b> -- selectCodeBlock_[ext]
 * <p>
 * Extension callback function to implement select-code-block in
 * python mode.
 * <p>
 * Note that this function relies upon Python statement level
 * tagging to be correctly working.  So, if there is a bug, find
 * out first if it's a bug in select code block, or a bug in
 * statement tagging.
 * 
 * @return int 0 on success, and 1 on failure.
 */
int selectCodeBlock_py()
{
   save_pos(auto p);

   if (!select_active()) {
      // No previous selection.
      _py_selectcb_last_context_id = 0;
   }

   // If current selection not in same file, deselect it:
   int start_sel_col = -1, end_sel_col = -1, buf_id = -1;
   if (_get_selinfo(start_sel_col, end_sel_col, buf_id) == TEXT_NOT_SELECTED_RC ||
       buf_id != p_buf_id) {
      _py_selectcb_last_context_id = 0;
      _deselect();
   }

   _UpdateContext(true, false, VS_UPDATEFLAG_statement|VS_UPDATEFLAG_context);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int cxtid = 0;
   _end_line();
   left();
   if (_py_selectcb_last_context_id) {
      tag_get_detail2(VS_TAGDETAIL_context_outer, _py_selectcb_last_context_id, cxtid);
      if (cxtid == 0) {
         // The last context is the outer-most context.  Simply reuse it.
         cxtid = _py_selectcb_last_context_id;
      }
   } else {
      cxtid = tag_current_statement();
   }

   if (!cxtid) {
      // No usable context.  Bail out.
      deselect();
      _py_selectcb_last_context_id = 0;
      restore_pos(p);
      return 1;
   }
   
   struct VS_TAG_BROWSE_INFO cm;
   tag_get_context_info(cxtid, cm);

   long begin_seek = cm.seekpos, end_seek = cm.end_seekpos;
   if (begin_seek < 0) {
      // A valid seek position is never negative, however, in Python
      // sometimes a seek position of -1 is used for the package context,
      // as an ugly hack to work around the package context not including
      // the first tagged entity on line 1 at seek position of 0.
      begin_seek = 0;
   }

   if (end_seek < begin_seek) {
      end_seek = begin_seek;
   }

   // Do the selection.
   _GoToROffset(begin_seek);
   select_line();
   _GoToROffset(end_seek);
   _select_line('', 'E');

   _py_selectcb_last_context_id = cxtid;
   restore_pos(p);
   return 0;
}

// Extension Options ----------------------------------------------

static boolean _py_isSyntaxIndentOn()
{
   return p_SyntaxIndent>0 && p_indent_style==INDENT_SMART;
}

// Python options event table
void _before_write_state_python()
{
   _py_selectcb_last_context_id = 0;
}
/*
  These callbacks flush the python package cache.
*/
void _cbsave_python(...)
{
   if (file_eq(_strip_filename(p_buf_name,'P'),'__init__.py')) {
      _actapp_python();
   }
}
void _actapp_python(_str arg1="")
{
   int index=find_index('python_reset',COMMAND_TYPE|PROC_TYPE);
   if (index_callable(index)) {
      call_index(index);
   }
}
boolean _py_is_continued_statement()
{
   _str line;
   get_line(line);
   word_chars := _clex_identifier_chars();
   if ( pos('^[ \t]*(else[ \t]*\:|elif[^'word_chars']|except[^'word_chars']|finally[ \t]*\:)', line, 1, 'r')) {
      return true;
   }
   return false;
}
static boolean py_isValidIdentifier(_str id) {
   if (!isalpha(substr(id,1,1))) {
      return(false);
   }
   word_chars := _clex_identifier_chars();
   return(pos('[^'word_chars']',id,1,'r')==0);
}
static boolean py_lineEndsWithBackslash(int truncate_linenum=-1,int truncate_col=-1) {
   boolean linecont=false;
   _str line;
   if (p_line==truncate_linenum) {
      int ilen=_text_colc(0,'L');
      if (truncate_col-1<ilen) {
         line=_expand_tabsc(1,truncate_col-1,'S');
         _message_box('line='line);
      } else {
         get_line(line);
      }
   } else {
      get_line(line);
   }
   if (last_char(line)=='\') {
      _end_line();
      left();
      // Backslash at the end of a comment line is not a line continuation
      linecont=_clex_find(0,'g')!=CFG_COMMENT;
   }
   return(linecont);
}
static boolean py_isLineContuation() {
   boolean linecont=false;
   save_pos(auto p);
   int status=up();
   if (!status) {
      linecont=py_lineEndsWithBackslash();
   }
   restore_pos(p);
   return(linecont);

}

/*
  Determine what we are inside of

  Search backwards for  {[(: ,  blocks,   begin-line-first-non-blank (comment or string )

  a= {
       'a': [1,
          2,
          3]
       'this is a test': (1,
                          2,
                          3)
     }
  if (
       (<enter here>
         a,
        b
       ) +
       (c,
        d)
       
     ) :
       print




*/
static int py_getIndentCol()
{
#define PY_DEBUG_INDENT 0
   save_pos(auto p);
   int orig_linenum=p_line;
   int orig_col=p_col;
   boolean charBeforeCursorIsBackslash=false;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
      if (get_text()=='\') {
         charBeforeCursorIsBackslash=true;
      }
   }
   // Start from non-blank character before cursor.
   // Not sure if we need this.
   //search('[^ \t]','hr@');
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   _str words_re=translate(strip(PYTHON_BLOCK_WORDS),'|',' ');
#define PYTHON_PAREN_CHARS  "{}[]()"
   int status=search('['_escape_re_chars(PYTHON_PAREN_CHARS)'\:]|'words_re'|^[ \t]*[^ \t]','-Rh@');
   int colon_col=0;       // Non-zero if found a colon
   int colon_line=0;
   int begin_line_col=0;  // Non-zero if found beginning of this line
   int begin_line_line=0;

   for (;;) {
      if (status) {
         restore_pos(p);
         if (begin_line_col) {
            return(begin_line_col);
         }
         // Indent to previous line
         status=search('[^ \t]','hr@');
         if (status) return(p_col); // We are lost
         int result_col=p_col;
         restore_pos(p);
         return(result_col);
      }
      int cfg=_clex_find(0,'g');
      _str match=get_match_text();
      _str chLeft=get_text(1,match_length('S')-1);
      _str chRight=get_text(1,match_length('S')+match_length(''));
#if PY_DEBUG_INDENT
      messageNwait('match='match' chLeft='chLeft' chRight='chRight);
#endif
      int matchLen=length(match);
      // IF we have not found the beginning of the line
      if (!begin_line_col && !pos(match,PYTHON_PAREN_CHARS)) {
         if (!py_isLineContuation()) {
            save_pos(auto p2);
            first_non_blank();
            begin_line_col=p_col;
            begin_line_line=p_line;
#if PY_DEBUG_INDENT
            messageNwait('Setting begin_line line='begin_line_line' col='begin_line_col);
#endif
            restore_pos(p2);
         }
      }
      /*if (cfg==CFG_COMMENT) {
         if (matchLen!=1 || pos(match,PYTHON_PAREN_CHARS)) {
            status=repeat_search();
            continue;
         }
      } */
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         status=repeat_search();
         continue;
      }
      if (pos(match,PYTHON_PAREN_CHARS)/* || match==','*/) {
         /*
          * Paren char cases
            + have text after brace but before <cursor>
               ** Use column of text

            +  Dont' have text,
               Use first_non_blank()+syntax_indent
          */
         switch (match) {
         case '}':
         case ']':
         case ')':
             int match_status=_find_matching_paren(MAXINT,true);
             if (match_status) {
                // Indent to previous line
                status=search('[^ \t]','hr@');
                if (status) return(p_col); // We are lost
                int result_col=p_col;
                restore_pos(p);
                return(result_col);
             }
             /*if (p_col==1) {
                up();_end_line();
             } else {
                left();
             } */
             status=repeat_search();
             continue;
         }
         int result_col=0;
         save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
         save_pos(auto p2);
         // Search for a non-blank character after the paren
         right();
         auto search_status=search('[^ \t]','hr@');
         if (!search_status) {
            if (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col)) {
               result_col=p_col;
            }
         }
         restore_search(s1,s2,s3,s4,s5);
         restore_pos(p2);
         if (match!='(') {
            // The sample code shipped with Python seems to indent on braces.
            // Do this for all the other cases too.
            if (result_col) {
               restore_pos(p);
               return(result_col);
            } else {
               // Use the continuation indent.
               first_non_blank();
               result_col=p_col+p_SyntaxIndent;
               restore_pos(p);
               return(result_col);
            }
         }
         // This could be a function call
         boolean isIDChar=false;
         if (p_col!=1) {
            left();
            status=search('[^ \t]|^','-rh@');
            isIDChar=!status && ext_isIdChar(get_text());
         }
         if (_clex_find(0,'g')!=CFG_KEYWORD && isIDChar && 
             !LanguageSettings.getUseContinuationIndentOnFunctionParameters('py', true) &&
             result_col) {
         } else {
            restore_pos(p2);
            // Use the continuation indent.
            first_non_blank();
            result_col=p_col+p_SyntaxIndent;
            restore_pos(p);
            return(result_col);
         }
         // We are inside a paren expression of some kind.
         restore_pos(p);
         return(result_col);
      }
      /*
          if (a,
              b): 
              print a <Enter>

          if (a,
              b): 
          print a <Enter>

          if (a,
              b): <Enter>

          if (a,
              b)+b: <Enter>print i

           (
             a:<enter>

      */
      if (match==':') {
         // IF we got another colon, we must be in a list of some kind (dictionary, 3.0 type specs)
         if (colon_col) {
            p_line=colon_line;
            first_non_blank();
            int result_col=p_col;
            restore_pos(p);
            // We must be in a dictionary list
            return(result_col);
         }
         // Colon is either inside parens chars or it is for a block/lambda

         colon_col=p_col;
         colon_line=p_line;
         status=repeat_search();
         continue;
      }
      if (!pos(' 'match' ',PYTHON_BLOCK_WORDS) || ext_isIdChar(chLeft) || ext_isIdChar(chRight)) {
#if PY_DEBUG_INDENT
         messageNwait('skip match='match' chl='chLeft' chR='chRight);
#endif
         status=repeat_search();
         continue;
      }
      /*
         handle
         i=abc if d \
            else g<enter>
      */
      if (py_isLineContuation()) {
         status=repeat_search();
         continue;
      }
      /*
         handle 
             if x:
                 print i
             a=4<enter>
      */
      int contSyntaxIndent=(charBeforeCursorIsBackslash)?p_SyntaxIndent:0;
      if (colon_col && colon_line<begin_line_line) {
#if PY_DEBUG_INDENT
         _message_box("colon_col && colon_line<begin_line_line\n"begin_line_col' 'contSyntaxIndent);
#endif
         restore_pos(p);
         return(begin_line_col+contSyntaxIndent);
      }
      /*
          handle 
             if x: print i<enter>
      */
      if (colon_col) {
         save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
         save_pos(auto p2);
         p_line=colon_line;
         p_col=colon_col+1;
         // Search for a non-blank character after the colon
         //right();
         auto search_status=search('[^ \t]|$','hr@');
         if (!search_status && _clex_find(0,'g')!=CFG_COMMENT && match_length()) {
            if (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col)) {
#if PY_DEBUG_INDENT
               _message_box('hit : AND cursor on same line as : ');
#endif
               restore_search(s1,s2,s3,s4,s5);
               restore_pos(p2);
               first_non_blank();
               int result_col=p_col;
               restore_pos(p);
               return(result_col+contSyntaxIndent);
            }
         }
         restore_search(s1,s2,s3,s4,s5);
         restore_pos(p2);
      }
      /*if (!colon_col && !charBeforeCursorIsBackslash) {
      } */

      first_non_blank();
#if PY_DEBUG_INDENT
      _message_box('p_col='p_col' ln='p_line' cntInd='contSyntaxIndent' synInd='p_SyntaxIndent' hit_colon='colon_col' charBeforeCursorIsBackslash='charBeforeCursorIsBackslash);
#endif
      int result_col=p_col+((colon_col)?p_SyntaxIndent:contSyntaxIndent);
      restore_pos(p);
      return(result_col);
   }

}
/*
 begin_words_re='try'
 begin_words_re='while|for|if|try'
 begin_words_re='if'
*/
static int find_block_start_col(_str begin_words_re) {
   save_pos(auto p);
   int status=search(begin_words_re,'ck-re@w=[_a-zA-Z0-9\p{L}\p{Nl}\p{Mn}\p{Mc}\p{Nd}\p{Pc}\x{B7}]');
   //status=search(begin_words_re,'ck-e@w=[_a-zA-Z0-9]');
   if (status) return(0);
   int col=p_col;
   restore_pos(p);
   return(col);
}
_command void python_colon() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   int cfg=CFG_STRING;
   if (!command_state() && p_col!=1) {
      left();
      cfg=_clex_find(0,'g');
      right();
   }
   if (command_state() || p_SyntaxIndent<0 ||
      _in_comment() || cfg!=CFG_KEYWORD) {
      keyin(':');
      return;
   }
   reindent_block_word();
   keyin(':');
}
static void reindent_block_word(boolean colon_typed=true) {
   get_line(auto line);line=strip(line);
   int orig_col = p_col - length(line);
   int col=0;
   if (line=='elif' && !colon_typed) {
      col=find_block_start_col('if');
   } else if (line=='else') {
      col=find_block_start_col('while|for|if|try');
   } else if ((line=='except') || line=='finally') {
      col=find_block_start_col('try');
   }
   if (col && col < orig_col) {
      replace_line(indent_string(col-1)line);_end_line();
   }
}
