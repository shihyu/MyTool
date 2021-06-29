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
#include "xml.sh"
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "autosave.e"
#import "backtag.e"
#import "bind.e"
#import "box.e"
#import "c.e"
#import "ccontext.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "complete.e"
#import "context.e"
#import "coolfeatures.e"
#import "csymbols.e"
#import "cua.e"
#import "cutil.e"
#import "debug.e"
#import "debugpkg.e"
#import "event.e"
#import "fileman.e"
#import "files.e"
#import "get.e"
#import "guiopen.e"
#import "help.e"
#import "hotfix.e"
#import "hotspots.e"
#import "help.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "menu.e"
#import "notifications.e"
#import "perl.e"
#import "pmatch.e"
#import "python.e"
#import "recmacro.e"
#import "savecfg.e"
#import "cfg.e"
#import "saveload.e"
#import "seek.e"
#import "seldisp.e"
#import "seltree.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tagform.e"
#import "tags.e"
#import "tbview.e"
#import "tcl.e"
#import "util.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#import "last.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

SELECT_PROC_FLAGS def_select_proc_flags=SELECT_PROC_NONE;

#define TAG_BASENAME    (_isUnix()?"uslickc":"slickc")

/*
  Options for SLICK-C syntax expansion/indenting may be accessed from SLICK's
  file extension setup menu (CONFIG, "File extension setup...").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       2             reserved.
       3             begin/end style.  Begin/end style may be 0,1, or 2
                     as show below.  Add 4 to the begin end style if you
                     want braces inserted when syntax expansion occurs
                     (main and do insert braces anyway).  Typing a begin
                     brace, '{', inserts an end brace when appropriate
                     (unless you unbind the key).  If you want a blank
                     line inserted in between, add 8 to the begin end
                     style.  Default is 4.

                      Style 0
                          if () {
                             ++i;
                          }

                      Style 1
                          if ()
                          {
                             ++i;
                          }

                      Style 2
                          if ()
                            {
                            ++i;
                            }


       4             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
       5             (reserved)
       6             Indent CASE from SWITCH.  Default is 0.  Specify
                     1 if you want CASE statements indented from the
                     SWITCH statement. Begin/end style 2 not supported.
*/

int suffix_cmd()
{
   save_pos(auto p);
   _str line;
   top();get_line(line);
   _str b4,startcomment='';
   parse line with b4 '/*' +0 startcomment ;
   if (b4=='' && startcomment!='') {
      index := find_index('rexx-mode',COMMAND_TYPE);
      if (!index) {
         return(1);
      }
      rexx_mode();
   } else {
      restore_pos(p);
      return(1);
      //++recurse;
      //fundamental_mode();
      //--recurse;
   }
   restore_pos(p);
   return(0);
}

/** 
 * Key binding for '*' key.
 * 
 * Attempts to determine if the mode should be switched to REXX
 * by checking if '*' is pressed in a '.cmd' when on line 1.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void rexx_star() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   keyin(last_event());
   if (_MultiCursorAlreadyLooping()) {
      return;
   }
   if (!command_state() && p_line==1 && _file_eq(_get_extension(p_buf_name),'cmd')) {
      suffix_cmd();
   }
}
/**
 * Activates REXX file editing mode.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void rexx_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('rexx');
}

/**
 * Activates HTML file editing mode.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void html_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('html');
}
/**
 * Activates Slick-C&reg; file editing mode.  The ENTER and SPACE BAR
 * bindings are changed as well as the tab and margin settings.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void slickc_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('e');
}

bool ispf_common_enter()
{
   int recording=_macro();
   if (ispf_enter()) return(true);
   _macro('m',recording);
   if (!command_state() && _QReadOnly()) {
      _readonly_error(0);
      return(true);
   }
   return(false);
}

_command bool generic_enter_handler(bool (*lang_expand_enter)()=null, bool checkEmbedded=false)
                 name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   // special handling for ENTER key in ISPF.  
   // This is used to processing ISPF line commands. 
   if (ispf_common_enter()) {
      return false;
   }

   // if the cursor is on the command line, do default handling
   if (command_state() || _in_long_line_split_into_multiples()) {
      call_root_key(ENTER);
      return false;
   }

   // check if we are in an embedded language mode, if so
   // we should handle the key in the appropriate language.
   if (checkEmbedded) {
      typeless orig_values;
      int embedded_status=_EmbeddedStart(orig_values);
      if (embedded_status==1) {
         call_key(last_event(), "\1", "L");
         _EmbeddedEnd(orig_values);
         return false; // Processing done for this key
      }
   }

   // if the window is iconized, syntax indent is turned off, 
   // or smart indent is off, then use default ENTER handling
   if ( p_window_state:=='I' || p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ) {
      call_root_key(ENTER);
      return false;
   }

   // if we are in a block comment, just use defalt handling
   if ( _in_comment(true) ) {  
      call_root_key(ENTER);
      return false;
   }

   // if we are on a line comment, we might need to split it or extend it
   if ( _maybeSplitLineComment() ) {
      return false;
   }

   // now we delegate to the language specific "expand enter" callback
   // the callback will return 'true' if it handled ENTER, false otherwise.
   if (lang_expand_enter != null) {
      if ( (*lang_expand_enter)() ) {  
         call_root_key(ENTER);
         return false;
      }

   } else {
      // if they did not pass in an expand_enter callback function,
      // then try looking up a language specific callback.
      // Note that this callback could be inherited.
      index := _FindLanguageCallbackIndex("_%s_expand_enter");
      if (index <= 0 || call_index(index)) {
         call_root_key(ENTER);
         return false;
      }
   }

   // special case for starting a new undo step
   if (_argument=='') {
      _undo('S');
   }

   // if we made it here, then the callback handled everything
   return true;
}

/**
 * New binding of ENTER key when in Slick-C&reg; mode.  Handles syntax
 * expansion and indenting for files with e, sh, and cmd extensions.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void slick_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (ispf_common_enter()) return;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART) {
      call_root_key(ENTER);
   } else {
      if (_in_comment(true)) {
         // In a block comment
         // start of a Java doc comment?
         get_line(auto first_line);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) &&
             (first_line=='/***/' || first_line=='/*!*/') && get_text(2)=='*/' && _is_line_before_decl()) {
            p_line += 1;
            _first_non_blank();
            int pc = p_col - 1;
            p_line -= 1;
            p_col = 1;
            _delete_end_line(); 
            _insert_text_raw(indent_string(pc));
            if (!expand_alias(substr(strip(first_line), 1, 3), '', getDocAliasProfileName(p_LangId), true)) {
               CW_doccomment_nag();
            }
            commentwrap_SetNewJavadocState();
            return;
         }
         //Try to handle with comment wrap.  If coment wrap
         //handled the keystroke then return.
         if (commentwrap_Enter()) {
            return;
         }

         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK) && commentwrap_Enter(true)) {
            //do nothing
         } else {
            call_root_key(ENTER);
         }
         return;
      }
      if (_in_comment(false)) {
         //line comment

         //Try to handle with comment wrap.  If comment wrap
         //handled the keystroke then return.
         if (commentwrap_Enter()) {
            return;
         }
      }
      if (_maybeSplitLineComment()) {
         return;
      }
      if (_in_string()) {
         delim := "";
         int string_col = _inString(delim);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS) &&
             string_col && p_col > string_col && _will_split_insert_line()) {
            _insert_text(delim);
            _insert_text(":+");
            indent_on_enter(0,string_col);
            keyin(delim);
            return;
         }
      }
      if (_c_expand_enter() ) {
          call_root_key(ENTER);
      } else if (_argument=='') {
         _undo('S');
      }
   }
}
bool _e_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _e_supports_insert_begin_end_immediately() {
   return true;
}

/**
 * (C mode only) Open Parenthesis
 * <p>
 * Handles syntax expansion or auto-function-help for Slick-C&reg;
 * mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void slick_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   // Called from command line?
   if (command_state()) {
      call_root_key('(');
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin('(');
      return;
   }

   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(last_event(), "\1", "L");
      _EmbeddedEnd(orig_values);
      return;
   }

   // Check syntax expansion options
   if (LanguageSettings.getSyntaxExpansion(p_LangId) && p_SyntaxIndent>=0 && !_in_comment() &&
       !slick_expand_space()) {
      return;
   }

   // not the syntax expansion case, so try function help
   auto_functionhelp_key();
}

/**
 * New binding of SPACE key when in Slick-C&reg; mode.  Handles syntax
 * expansion and indenting for files with e, sh, or cmd extension.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void slick_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || !doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      slick_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

   // display auto-list-paramters for completing
   // assignment statements, return statements,
   // and goto statements
   if (!command_state()) {
      if (c_maybe_list_args(true)) {
         return;
      }
      if (c_maybe_list_javadoc(true)) {
         return;
      }
   }
}

/**
 * Handles syntax expansion for one-line if and while
 * statements.  Just type "if", then semicolon, and it
 * expands to "if (&lt;cursor here&gt;) &lt;next hotspot&gt;;
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void slick_semicolon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || 
        !LanguageSettings.getSyntaxExpansion(p_LangId) || 
        p_SyntaxIndent<0 ||
        _in_comment() ||
        slick_expand_space()) {
      if ( command_state() ) {
         call_root_key(';');
      } else {
         keyin(';');
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

   /* Words must be in sorted order */
static const SLICKC_EXPAND_WORDS= (' #define #elif #else #endif #error #if #ifdef #ifndef':+
                ' #import #require #include #pragma #note #todo #region #endregion':+
                ' #undef _buffer _command const def defeventtab':+
                ' else typedef _str struct static union':+
                ' int interface class enum enum_flags namespace':+
                ' extern public protected private this using ');

static SYNTAX_EXPANSION_INFO slickc_semicolon_words:[] = {
   "for"          => { "for ( ... ) { ... }" },
   "foreach"      => { "foreach ( ... in ... ) { ... }" },
   "if"           => { "if ( ... ) { ... }" },
   "while"        => { "while ( ... ) { ... }" },
   "else"         => { "else { ... }" },
   "else if"      => { "else if ( ... ) { ... }" },
   'break'        => { "break" },
   'continue'     => { "continue" },
   'return'       => { "return" },
};

static SYNTAX_EXPANSION_INFO slickc_space_words:[] = {
   '#define'      => { "#define" },
   '#elif'        => { "#elif" },
   '#else'        => { "#else" },
   '#endif'       => { "#endif" },
   '#error'       => { "#error" },
   '#todo'        => { "#todo" },
   '#note'        => { "#note" },
   '#if'          => { "#if" },
   '#ifdef'       => { "#ifdef" },
   '#ifndef'      => { "#ifndef" },
   '#import'      => { "#import" },
   '#include'     => { "#include" },
   '#pragma'      => { "#pragma" },
   '#require'     => { "#require" },
   '#undef'       => { "#undef" },
   '#region'      => { "#region" },
   '#endregion'   => { "#endregion" },
   '_buffer'      => { "_buffer" },
   '_command'     => { "_command void () name_info(',') { ... }" },
   'break'        => { "break" },
   'case'         => { "case" },
   'class'        => { "class" },
   'const'        => { "const" },
   'continue'     => { "continue" },
   'def'          => { "def" },
   'default'      => { "default" },
   'defeventtab'  => { "defeventtab" },
   "definit"      => { "definit() { ... }" },
   "defload"      => { "defload() { ... }" },
   "defmain"      => { "defmain() { ... }" },
   "do"           => { "do { ... } while ( ... );" },
   "else"         => { "else { ... }" },
   "else if"      => { "else if ( ... ) { ... }" },
   'enum'         => { "enum" },
   'enum_flags'   => { "enum_flags" },
   "for"          => { "for ( ... ) { ... }" },
   "foreach"      => { "foreach ( ... in ... ) { ... }" },
   "if"           => { "if ( ... ) { ... }" },
   'int'          => { "int" },
   'interface'    => { "interface" },
   'loop'         => { "loop { ... }" },
   'namespace'    => { "namespace" },
   'private'      => { "private" },
   'protected'    => { "protected" },
   'public'       => { "public" },
   'return'       => { "return" },
   'static'       => { "static" },
   'struct'       => { "struct" },
   "switch"       => { "switch ( ... ) { ... }" },
   '_str'         => { "_str" },
   'this'         => { "this" },
   'typedef'      => { "typedef" },
   'union'        => { "union" },
   'using'        => { "using" },
   "while"        => { "while ( ... ) { ... }" },
};

/**
 * Eclipse-style content assist used in place of auto-expansion for Eclipse
 * emulation.  On the command line, this will perform expand_alias.  In a buffer
 * this will first try for an alias expansion, then a syntax expansion, and then
 * perform codehelp_complete. 
 * 
 * Bound to CTRL-Space by default for Eclipse emulation.
 * 
 */
_command void eclipse_content_assist() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if (!command_state()) {
      if (expand_alias()) {
         origLangSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);
         LanguageSettings.setSyntaxExpansion(p_LangId, true);
         if(slick_expand_space()){
            codehelp_complete();
         }
         LanguageSettings.setSyntaxExpansion(p_LangId, origLangSyntaxExpansion);
      }
   } else {
      expand_alias();
   }
}

static int slick_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style:=p_begin_end_style;
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);

   status := 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   
   set_surround_mode_start_line();
   col := 0;
   open_paren_case := (last_event()=='(');
   semicolon_case := (last_event()==';');
   if_special_case := false;
   else_special_case := false;
   pick_else_or_else_if := false;
   aliasfilename := "";
   brace_before := "";

   word := "";
   if (semicolon_case) {
      word = min_abbrev2(orig_word, slickc_semicolon_words, "", aliasfilename, false, open_paren_case);
   } else {
      word = min_abbrev2(orig_word, slickc_space_words, "", aliasfilename, !open_paren_case, open_paren_case);
   }

   // can we expand an alias?
   if (!semicolon_case && !maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   first_word := "";
   second_word := "";
   rest := "";
   if ( word=='' && doSyntaxExpansion) {
      // Check for } else
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
      word=min_abbrev2('els',slickc_space_words,'','');
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

   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   noSpaceBefore := p_no_space_before_paren;
   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   
   // special case for open parenthesis (see c_paren)
   if ( open_paren_case ) {
      noSpaceBefore = true;
      if ( length(word) != length(orig_word) ) {
         return 1;
      }
      switch ( word ) {
      case 'if':
      case 'while':
      case 'for':
      case 'else if':
      case 'switch':
      case 'return':
         break;
      default:
         return 1;
      }
   } 

   // special case for semicolon
   if ( semicolon_case ) {
      insertBraceImmediately = false;
      if (!slickc_semicolon_words._indexin(word)) {
         return 1;
      }
   }

   // if they type the whole keyword and then space, ignore
   // the "no space before paren" option, always insert the space
   // 11/30/2006 - rb
   // Commented out because the user (me) could have trained themself to
   // type 'if<SPACE>' in order to get an expanded if-statement. This would
   // have always put the SPACE in regardless of the "no space before paren"
   // option.
   //if ( word == orig_word && last_event() :== ' ') {
   //   be_style &= ~VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN;
   //}

   clear_hotspots();
   _str maybespace=(noSpaceBefore)?'':' ';
   _str parenspace=(p_pad_parens)? ' ':'';
   line=substr(line,1,length(line)-length(orig_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   style2 := be_style == BES_BEGIN_END_STYLE_2;
   style3 := be_style == BES_BEGIN_END_STYLE_3;
   e1 := " {";
   if ( word!='do' || style2 || style3 ) {
      if ( style2 || style3 || !insertBraceImmediately ) {
         e1='';
      } else if (word=='}else') {
         e1='{';
      } else if (word=='do' && last_event()=='{') {
         e1='{';
      }
   }
   if (semicolon_case) e1 = ' ;';

   doNotify := true;
   if ( word=='if' || word=='else if' || if_special_case) {
      replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word));
      maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='else') {
      typeless p;
      typeless s1,s2,s3,s4;
      save_pos(p);
      save_search(s1,s2,s3,s4);
      up();_end_line();
      search('[^ \t\n\r]','@-rhXc');
      if (get_text()=='}') {
         be_style |= VS_C_OPTIONS_BRACE_INSERT_FLAG;
      } else {
         e1=' ';
         be_style &= ~VS_C_OPTIONS_BRACE_INSERT_FLAG;
      }
      restore_search(s1,s2,s3,s4);
      restore_pos(p);
      newLine := line:+e1;
      replace_line(newLine);
      maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word);
      _end_line();

      doNotify = (insertBraceImmediately || newLine != orig_line);
   } else if ( else_special_case) {
      replace_line(line:+e1);
      maybe_insert_braces(noSpaceBefore,true,width,word);
      _end_line();
   } else if ( word=='for' ) {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word);
      maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='foreach' ) {
      replace_line(line:+maybespace'('parenspace:+' in ':+parenspace')'e1);
      maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word);
      add_hotspot();
      p_col+=4;
      add_hotspot();
      p_col-=4;
   } else if ( word=='while' ) {
      if (c_while_is_part_of_do_loop()) {
         replace_line(line:+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;
         if (p_pad_parens) --p_col;
         maybe_autobracket_parens();
      } else {
         replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
         maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word);
         maybe_autobracket_parens();
         add_hotspot();
      }
   } else if ( word=='loop' ) {
      replace_line(line:+e1);
      maybe_insert_braces(noSpaceBefore, true,width,word);
      _end_line();
   } else if ( (word=='public' || word=='private' || word=='protected')) {
      replace_line(line' ');_end_line();
      doNotify = (line != orig_line);
   } else if ( word=='switch' ) {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      maybe_insert_braces(noSpaceBefore, insertBraceImmediately,width,word);
      maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='do' ) {
      // Always insert braces for do loop unless braces are on separate
      // line from do and while statements
      replace_line(line:+e1);
      num_end_lines := 1;
      if ( ! style3 ) {
         if ( style2 ) {
            insert_line(indent_string(width)'{');
         }
         insert_line(indent_string(width)'} while':+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;
         if (p_pad_parens) p_col--;
         add_hotspot();
         up();
      } else if ( style3 ) {
         if (be_style & VS_C_OPTIONS_BRACE_INSERT_FLAG) {
            insert_line(indent_string(width+syntax_indent)'{');
            insert_line(indent_string(width+syntax_indent)'}');
            num_end_lines=2;
            insert_line(indent_string(width)'while':+maybespace'('parenspace:+parenspace');');
            _end_line();
            p_col -= 2;
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(2);
            syntax_indent=0;
         } else {
            insert_line(indent_string(width)'while'maybespace:+'('parenspace:+parenspace');');
            _end_line();
            p_col -= 2;
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(1);
            //syntax_indent=0
         }
      }
      nosplit_insert_line();
      p_col += syntax_indent;
      set_surround_mode_end_line(p_line+1, num_end_lines);
      add_hotspot();
   } else if ( word=='printf' ) {
      replace_line(indent_string(width)'printf("');
      _end_line();
   } else if ( word=='return' ) {

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      IsVoid := false;
      context_id := tag_current_context();
      if (context_id>0) {
         tag_type := "";
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,tag_type);
         if (tag_tree_type_is_func(tag_type)) {
            return_type := "";
            tag_get_detail2(VS_TAGDETAIL_context_return,context_id,return_type);
            if (return_type=='void') {
               IsVoid=true;
            }
         }
      }
      newLine := indent_string(width)'return';
      replace_line(newLine);
      _end_line();
      if (IsVoid) {
         keyin(';');
      } else {
         keyin(' ');
         if (semicolon_case) {
            keyin(';');
            left();
         }
         doNotify = (newLine != orig_line);
      }
   } else if ( word=='continue' || word=='break' ) {
      // Slick-C allows labels to follow continue or break
      newLine := '';
      if (orig_word==word && !semicolon_case) {
         newLine = indent_string(width)word' ';
      } else {
         newLine = indent_string(width)word';';
      }
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if ( word=='case' ) {
      if ( name_on_key(ENTER):=='nosplit-insert-line' ) {
         replace_line(indent_string(width)word' :');
         _end_line();_c_do_colon();p_col=p_col-1;
         if ( ! _insert_state() ) _insert_toggle();
      } else {
         // Code which inserts case
         replace_line(indent_string(width)word' :');
         _end_line();_c_do_colon();_rubout();
      }
   } else if ( word=='default' ) {
      replace_line(indent_string(width)word':');_end_line();
      _c_do_colon();
   } else if (word=='_command') {
      command_line := p_line;
      replace_line(word" void () name_info(',')");
      p_col = 15;
      add_hotspot();
      p_col += 1;
      add_hotspot();
      p_col += 12;
      add_hotspot();
      p_col += 3;
      add_hotspot();
      insert_line('{');
      insert_line('}');
      up();
      insert_line('');
      p_col=syntax_indent+1;
      add_hotspot();
      p_line = command_line;
      p_col = 15;
   } else if (word=="class" || word=="interface") {
      command_line := p_line;
      className := _strip_filename(p_buf_name,'PE');
      if (!isupper(_first_char(className))) className = "";
      replace_line(word" "className" {");
      p_col = length(word)+2;
      add_hotspot();
      _end_line();
      p_col = p_col-1;
      add_hotspot();
      insert_line("");
      insert_line('};');
      up();
      p_col=syntax_indent+1;
      add_hotspot();
      p_line = command_line;
      p_col = length(word)+2;
   } else if ( (word=="#import" || word=="#include" || word=="#require") && 
               LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_QUOTED_ON_SPACE ) {
      replace_line(indent_string(width)word' ');
      _end_line();
      AutoBracketKeyin('"');
      _do_list_members(OperatorTyped:false, DisplayImmediate:true);
   } else if ( pos(' 'word' ',SLICKC_EXPAND_WORDS) ) {
      newLine := indent_string(width)word' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if ( pos(' 'word' ',' definit defload defmain ') ) {
      replace_line(word'()');
      insert_line('{');
      insert_line('}');
      up();
      insert_line('');
      p_col=syntax_indent+1;
   } else {
     status=1;
     doNotify = false;
   }
   if (semicolon_case) {
      orig_col := p_col;
      _end_line();
      left();
      add_hotspot();
      p_col = orig_col;
   }
   show_hotspots();

   if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if (open_paren_case) {
      AutoBracketCancel();
   }
   return(status);
}

int _e_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, slickc_space_words, prefix, min_abbrev);
}

int e_indent_col(int non_blank_col,bool pasting_open_block)
{
   return(c_indent_col(non_blank_col,pasting_open_block));
}

/**
 * Check if we are sitting on an else statement.
 * This is used by dynamic surround (see surround.e)
 */
bool _e_is_continued_statement()
{
   get_line(auto line);
   if ( pos('^[ \t]#[}]?[ \t]*else([ \t{]|$)', line, 1, 'r')) {
      return true;
   }

   if (line == '}') {
      save_pos(auto p);
      down();
      get_line(line);
      if ( pos('^[ \t]#else([ \t{(]|$)', line, 1, 'r')) {
         restore_pos(p);
         return true;
      }
      restore_pos(p);
   }

   return false;
}

static _str prev_stat_has_semi()
{
   typeless status=1;
   up();
   if ( ! rc ) {
      col := p_col;_end_line();
      _str line;
      get_line_raw(line);
      parse line with line '\#|/\*',(p_rawpos'r');
      /* parse line with line '{' +0 last_word */ ;
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line='' or last_word='{' or first_word='case' */
      stripped_line := strip(line);
      status=raw_last_char(stripped_line)!=')' && ! pos('(\}|)else$',strip(line),1,p_rawpos'r');
      down();
      p_col=col;
   }
   return(status);
}
static _str stat_has_semi(_str arg1='')
{
   _str line;
   get_line_raw(line);
   parse line with line '/*',p_rawpos;
   line=strip(line,'T');
   _str name=name_on_key(ENTER);
   return(raw_last_char(line):==';' &&
            (
               ! (( _will_split_insert_line()
                    ) && (p_col<=text_col(line) && arg1=='')
                   )
            )
         );

}
static void maybe_insert_braces(bool noSpaceBeforeParen, bool insertBraceImmediately, int width,_str word,bool no_close_brace=false)
{
   int col=width+length(word)+3;

   updateAdaptiveFormattingSettings(AFF_PAD_PARENS | AFF_NO_SPACE_BEFORE_PAREN);
   // do this extra check because we might have forced in the no space before paren setting in c_expand_space
   if ( noSpaceBeforeParen ) --col;
   if ( p_pad_parens ) ++col;

   if ( p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
      width += p_SyntaxIndent;
   }

   if ( insertBraceImmediately) {
      up_count := 1;
      if ( p_begin_end_style == BES_BEGIN_END_STYLE_2 || p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
         up_count++;
         insert_line (indent_string(width)'{');
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
         up_count++;
         insert_line(indent_string(width+p_SyntaxIndent));
      }
      _end_line();
      add_hotspot();
      if (no_close_brace) {
         up_count--;
      } else {
         insert_line(indent_string(width)'}');
         set_surround_mode_end_line();
      }
      up(up_count);
   }
   p_col=col;
   if ( ! _insert_state() ) _insert_toggle();
}

/**
 * Searches for a Slick-C&reg; macro tag you specify.  Global functions and
 * event tables are tagged.  In addition, you can enter a static function name
 * defined in the current file.  A dialog box is displayed which allows you to
 * type the tag name in or select from a list of existing tag names.  Completion
 * may be used to assist you in entering the name.
 *
 * @return Returns 0 if successful.
 *
 * @see find_proc
 * @see list_tags
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
_command  int gui_find_proc() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Tagging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   typeless result;
   tfindex := 0;
   int status=_e_MaybeBuildTagFile(tfindex,true);
   if (!status) {
      _macro_delete_line();
      for (;;) {
         result = show('-modal -reinit _tagbookmark_form',"","","e");
         if (result == '') {
            return(COMMAND_CANCELLED_RC);
         }
         status = find_proc(result);
         if(status != 1) {  /* Tag not found? */
            _macro('m',_macro('s'));
            _macro_call('find_proc', result);
            return(status);
         }
         int orig_buf_id = p_buf_id;
         status = load_files('+b .command');
         if (!status) {
            bottom();
            status = search("\\@cb _tagbookmark_form.ctlTag", '@rh-');
            _delete_line(); up(); _delete_line();
            p_buf_id = orig_buf_id;
         }
      }
      return(0);
   }
   result=_list_matches2(
                  'Find Procedure',   // title
                  SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_MUSTEXIST|SL_MATCHCASE,        // flags
                  '',       // buttons
                  'gui_find_proc',   // help_item
                  '',       // font
                  '',       // callback
                  'find_proc',       // retrieve_name
                  MACROTAG_ARG,  // completion
                  0,       // min list width
                  EVENTTAB_TYPE|PCB_TYPE|oi2type(OI_FORM)
                  );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   return(find_proc(result));
}
void _UntagSlickCFile(_str filename)
{
   if (!_haveContextTagging()) {
      return;
   }
   filename=absolute(filename);
   ext:=_get_extension(filename);
   if (ext=="") {
      filename :+= _macro_ext;
   } else if (_file_eq('.'ext,_macro_ext'x')) {
      filename=_strip_filename(filename,'E'):+_macro_ext;
   }

   _str tagfile_list=_replace_envvars(LanguageSettings.getTagFileList('e'));
   doRefresh := false;
   for (;;) {
      _str tagfilename=next_tag_file2(tagfile_list,false,true);
      if (tagfilename=="") {
         break;
      }
      typeless junk;
      int status=tag_get_date(filename,junk);
      if (!status) {
         status=tag_open_db(tagfilename);
         if (status >= 0) {
            doRefresh=true;
            tag_remove_from_file(filename);
            tag_close_db(tagfilename,true);
            _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tagfilename);
         }
      }
   }
   if (doRefresh) {
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   }
}
static void _MaybeTagSlickCFile(_str filename,int tfindex)
{
   if (!_haveContextTagging()) {
      return;
   }
   if (_isPluginFileSpec(filename)) {
      filename=absolute(filename,null,true);
   } else {
      filename=absolute(filename);
   }
   if (_get_extension(filename)=="") {
      filename :+= _macro_ext;
   }
   _str vsroot=_getSlickEditInstallPath();
   // IF this file is not within this installation of VSE AND
   //    this macro file is from a different VSE installation
   path := _strip_filename(filename,'N');
   if (!_file_eq(vsroot,substr(filename,1,length(vsroot))) &&
                (file_match('-p '_maybe_quote_filename(path):+"emulate.ex",1)!=''
                ||
                 file_match('-p '_maybe_quote_filename(path):+"emulate.e",1)!=''
                )
                ) {
      // DON'T tag this file
      return;
   }

   // look up the tag file list index if we don't have it already
   tagfile_list := LanguageSettings.getTagFileList('e');
   if (tagfile_list=='') {
      return;
   }

   status := 0;
   _str date_of_file=_file_date(filename,'B');
   tagfile_list=_replace_envvars(tagfile_list);
   _str tagfilename;
   for (;;) {
      tagfilename=next_tag_file2(tagfile_list,false,true);
      if (tagfilename=="") {
         break;
      }
      date_tagged := "";
      status=tag_get_date(filename,date_tagged);
      if (!status) {
         if (date_tagged==date_of_file) {
            return;
         }
      }
   }
   int temp_view_id,orig_view_id;
   buffer_already_exists := false;
   status=_open_temp_view(filename,temp_view_id,orig_view_id,'',buffer_already_exists,false,true);
   if (!status) {
      tagfile_list = LanguageSettings.getTagFileList('e');
      tagfile_list = _replace_envvars(tagfile_list);
      tagfilename  = next_tag_file2(tagfile_list);
      if (tagfilename!="") {
         status=tag_open_db(tagfilename);
         if (status >= 0) {
            RetagCurrentFile();
            tag_close_db(tagfilename,true);
            _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tagfilename);
            _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}
int _e_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if(!_default_option(VSOPTION_AUTO_BUILD_TAG_FILES)) {
      return COMMAND_CANCELLED_RC;
   }
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
 
   // determine where we should get 'macros' directory from.
   // Normally, this will be the editor's installation macro path, but
   // if they have a workspace open that has a "macros" directory containing
   // a "slick.sh" and "maketags.e", then let's use the "macros" directory
   // from the workspace directory.  This is mainly useful for internal
   // SlickEdit use.  It would be unlikely to happen for a normal SlickEdit user.
   slickc_filename := "";
   using_workspace_slickc := false;
   if (_workspace_filename != "") {
      if (beginsWith(_strip_filename(_workspace_filename, 'P'), "slickedit-")) {
         workspace_slick_sh := _strip_filename(_workspace_filename, 'N');
         workspace_slick_sh :+= "macros" :+ FILESEP;
         if (file_exists(workspace_slick_sh:+"slick.sh") && 
             file_exists(workspace_slick_sh:+"builtins.e") &&
             file_exists(workspace_slick_sh:+"maketags.e")) {
            slickc_filename = workspace_slick_sh :+ "slick.sh";
            using_workspace_slickc = true;
         }
      }
   }

   // maybe we can recycle tag file(s)
   ext := 'e';
   tagfilename := "";
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,TAG_BASENAME) && !forceRebuild) {
      // at this point, we have a slickc.vtg, but it may have built for
      // another installation.  If that is the case, lets try, just once, 
      // to rebuild from scratch for the current SlickEdit installation.  
      static bool rebuilt_slickc_tag_file /*= false*/;
      if (!using_workspace_slickc && rebuilt_slickc_tag_file) {
         return 0;
      }
      rebuilt_slickc_tag_file = true;
      do {
         status := tag_read_db(tagfilename);
         if (status) {
            break;
         }
         if ( slickc_filename=="" ) {
            slickc_filename = _macro_path_search("slick.sh");
         }
         if (slickc_filename == "") {
            break;
         }
         status = tag_find_file(auto found_filename, slickc_filename);
         if (status || !file_eq(found_filename, slickc_filename)) {
            break;
         }
         slickc_filename = _strip_filename(slickc_filename,'N'):+"maketags.e";
         status = tag_find_file(found_filename, slickc_filename);
         if (status || !file_eq(found_filename, slickc_filename)) {
            break;
         }
         slickc_filename = _strip_filename(slickc_filename,'N'):+"builtins.e";
         status = tag_find_file(found_filename, slickc_filename);
         if (status || !file_eq(found_filename, slickc_filename)) {
            break;
         }
         // this Slick-C tag file looks like the real thing, leave it be
         return 0;
      } while (false);
   }

   // try using the pre-tagged version
   if (!using_workspace_slickc && !forceRebuild && !copyInstalledSlickCTagFile()) {
      return 0;
   }

   // make sure that vusrmacs.e is retagged
   getUserMacroFiles(auto config_macfiles, auto new_macfiles);

   // The user does not have an extension specific tag file for Slick-C
   status := 0;
   tag_close_db(tagfilename);
   if (slickc_filename=="") {
      slickc_filename = _macro_path_search('maketags'_macro_ext);
   }
   if (slickc_filename=="") {
      slickc_filename=_macro_path_search('maketags'_macro_ext'x');
   }
   if (slickc_filename!='') {
      macrosPath:=_strip_filename(slickc_filename,'n');
      plugin_macfiles:=" ";
      if (_plugin_get_user_plugins_path()!='') {
         plugin_macfiles = " ":+_maybe_quote_filename(_plugin_get_user_plugins_path():+"*.e"):+" ":+_maybe_quote_filename(_plugin_get_user_plugins_path():+"*.sh");
      }
      plugin_excludes := "-E \"**"FILESEP"com_slickedit.base"FILESEP"sysconfig"FILESEP"\"";
      threadOpt := useThread? " -B ": "";
      status=shell("maketags ":+threadOpt:+" -t -c -x -n \"Slick-C"VSREGISTEREDTM" Libraries\" -o ":+_maybe_quote_filename(tagfilename)" "_maybe_quote_filename(macrosPath:+'*.e')" "_maybe_quote_filename(macrosPath:+'*.sh')" "config_macfiles" "new_macfiles' 'plugin_macfiles' 'plugin_excludes);
      if (!status) {
         removeOldFiles(tagfilename, macrosPath);
      }

      LanguageSettings.setTagFileList('e', tagfilename);
   } else {
      status=1;
   }

   return(status);
}

static void removeOldFiles(_str tagfilename, _str macrosPath)
{
   otherfiles := "";
   if (_isUnix()) {
      //otherfiles=_maybe_quote_filename(path:+'sysobjs.e')' ':+
      otherfiles=_maybe_quote_filename(macrosPath:+'usysobjs.e')' ':+ // UNIX now uses sysobjs.e
                 _maybe_quote_filename(macrosPath:+'vusrobjs.e')' ':+
                 _maybe_quote_filename(macrosPath:+'vusrdefs.e')' ':+
                 _maybe_quote_filename(macrosPath:+'vusrs*.e')' ':+
                 _maybe_quote_filename(macrosPath:+'slick24.sh');
   } else {
      otherfiles=_maybe_quote_filename(macrosPath:+'usysobjs.e')' ':+
                 _maybe_quote_filename(macrosPath:+'vunxobjs.e')' ':+
                 _maybe_quote_filename(macrosPath:+'vunxdefs.e')' ':+
                 _maybe_quote_filename(macrosPath:+'vunxs*.e')' ':+
                 _maybe_quote_filename(macrosPath:+'slick24.sh');
   }
   shell('maketags -d -Q -o '_maybe_quote_filename(tagfilename)' 'otherfiles);

   // files under SCDebug should not be tagged. 
   scDebugFiles := _ConfigPath():+"SCDebug/*.e";
   shell('maketags -t -Q -d -o '_maybe_quote_filename(tagfilename)' '_maybe_quote_filename(scDebugFiles));
}

static void getUserMacroFiles(_str &config_macfiles, _str &new_macfiles)
{
   macroFile := "";
   configDir := _ConfigPath();
   config_macfiles='';
   //config_macfiles = _maybe_quote_filename(configDir:+LASTMAC_FILE:+'*':+_macro_ext);
   foreach (macroFile in USERMACS_FILE" "USERMODS_FILE" "USEROBJS_FILE" "USERDEFS_FILE" "USERDATA_FILE) {
      if (file_exists(configDir:+macroFile:+_macro_ext)) {
         config_macfiles :+= " ":+_maybe_quote_filename(configDir:+macroFile:+".e");
      }
   }

   // translate def_macfiles to a list of source files
   new_macfiles = "";
   foreach (macroFile in def_macfiles) {
      // Does the start of the macro path match the old_default_config? 
      // If so then the macro is underneath the old directory.
      macroFile = strip(macroFile, "B", '"');
      if (_get_extension(macroFile) == "ex") {
         macroFile = substr(macroFile,1,length(macroFile)-1);
      }

      // Paths in def_macfiles can be relative to the config directory
      // already, so force them to be really absolute, so we can make
      // sure they're under the config directory.
      macroFile = absolute(macroFile);
      if (!beginsWith(macroFile, configDir)) {
         continue;
      }

      // Resolve the macro file to an absolute directory
      if (file_exists(configDir:+macroFile)) {
         macroFile = configDir:+macroFile;
      } else {
         foundMacroFile := slick_path_search(macroFile);
         if (foundMacroFile != "" && file_exists(foundMacroFile)) {
            macroFile = foundMacroFile;
         }
      }
      // And then add it to the list of files to be tagged
      new_macfiles :+= " "_maybe_quote_filename(macroFile);
   }
}

int copyInstalledSlickCTagFile()
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // copy the installed file over to the user's config
   sourceFile  := _global_tagfiles_path() :+ 'slickc' :+ TAG_FILE_EXT;
   tagfilename := _tagfiles_path() :+ TAG_BASENAME :+ TAG_FILE_EXT;
   tag_close_db(tagfilename);
   status := copy_file(sourceFile, tagfilename);
   if (status < 0) {
      return status;
   }

   // adjust paths in the tag file to point to our installation dir
   macrosDir := get_env('VSROOT') :+ FILESEP :+ 'macros' :+ FILESEP;
   status = adjustTagfilePaths(tagfilename, _tagfiles_path(), _global_tagfiles_path());
   if (status == BT_CANNOT_WRITE_OBSOLETE_VERSION_RC) {
      status = tag_update_tag_file_to_latest_version(sourceFile, tagfilename);
   }
   if(status) {
      // this is busted, delete it
      delete_file(tagfilename);
      return status;
   }

   // add the user's macros to the tag file
   getUserMacroFiles(auto config_macfiles, auto new_macfiles);

   status = 0;
   if (new_macfiles != '' || config_macfiles != '') {

      // find maketags
      tag_close_db(tagfilename);
      slickc_filename := _macro_path_search('maketags'_macro_ext);
      if (slickc_filename=="") {
         slickc_filename=_macro_path_search('maketags'_macro_ext'x');
      }

      if (slickc_filename!='') {
         removeOldFiles(tagfilename, macrosDir);
         path := _strip_filename(slickc_filename,'n');

         status=shell('maketags -c -B -Q -x -r -o '_maybe_quote_filename(tagfilename)' 'config_macfiles' 'new_macfiles);

         LanguageSettings.setTagFileList('e', tagfilename);
      } else {
         status = 1;
      }
   } 

   return status;
}


/* You can replace this procedure by copying this source into */
/* another macro module and loading the module. */
/* Have this function return a non-zero number if you want */
/* no special processing on main keyword. */

/**
 * Finds Slick-C&reg; source code or help for the Slick-C&reg; identifier
 * <i>tag_name</i> specified.  This function supports tagging global functions,
 * static functions if in current file, event tables, and dialog boxes (form
 * names).  Unlike the <b>find_tag</b> command, the <b>find_proc</b> command
 * does not use a tag file.
 *
 * @return  Returns 0 if successful.  Otherwise a non-zero value is returned
 * and a message box is displayed.
 *
 * @see f
 * @see find_tag
 * @see push_tag
 * @see gui_find_proc
 *
 * @appliesTo  Edit_Window
 * @categories Search_Functions
 */
_command int find_proc,fp(_str name='', bool force_case_sensitivity=false) name_info(MACROTAG_ARG','VSARG2_REQUIRES_MDI)
{
   name=strip(prompt(name));
   _str option,rest;
   parse name with option rest;
   useNamesTable := false;
   // IF use names table
   if (lowcase(option)=='-n') {
      useNamesTable=true;
      name=rest;
   }
   int type;
   _str help_name,type_name;
   parse name with help_name type_name;
   //help_name=translate(help_name,'-','_');
   //if ( type_name=='' ) {
     type=PROC_TYPE|COMMAND_TYPE|oi2type(OI_FORM)|EVENTTAB_TYPE;
   /*} else {
     type=eq_name2value(type_name,PCB_TYPES)
     if ( type=='' ) {
       message nls("Unknown  type.  Use '?' to list types.")
       return(1)
     }
   }
   */
   module_name := "";
   filename := "";
   msg := "";
   module_index := 0;
   tfindex := 0;
   typeless status=0;
   index := find_index(help_name,type);
   orig_view_id := p_window_id;
   if (!useNamesTable) {
      status=_e_MaybeBuildTagFile(tfindex,true);
      if (!status) {
         module_name='';
         filename='';
         // Tag any potential new file if necessary
         if(name_type(index)&(OBJECT_TYPE|EVENTTAB_TYPE) &&
            !(type2oi(name_type(index))==OI_MENU)){
             filename=_find_form_eventtab(help_name,true);
         } else if ( index && ! ((name_type(index) & (PROC_TYPE|COMMAND_TYPE)) &&
                            ! index_callable(index)) ) {
           module_index= index_callable(index);
           module_name=name_name(module_index);
         } else {
            /*if (_isEditorCtl()) {
               filename=p_buf_name;
            } */
         }
         if (_isEditorCtl()) {
            _str ext=_get_extension(p_buf_name);
            if ( p_LangId == 'e' &&
                (_file_eq('.'ext,_macro_ext) || _file_eq(ext,'sh')) ) {
                _MaybeTagSlickCFile(p_buf_name,tfindex);
            }
         }
         if (module_name!='') {
            module_name=substr(module_name,1,length(module_name)-1);
            //messageNwait('module_name='module_name);
            filename= path_search(module_name,'VSLICKMACROS');
            if (filename=='') {
               filename=_macro_path_search(module_name);
            }
            //if (filename=="") slick_path_search(module_name);
         }
         //messageNwait('filename='filename);
         if (filename!='') {
            _MaybeTagSlickCFile(filename,tfindex);
         }
         // This code isn't the greatest
         help_name=translate(help_name,'_','-');
         if(name_type(index)&(DLLCALL_TYPE)){
            p_window_id = orig_view_id;
            if (force_case_sensitivity) return(find_tag('-sc -cs 'help_name));
            else return(find_tag('-sc 'help_name));
         }

         p_window_id = orig_view_id;
         if (force_case_sensitivity) return(find_tag('-e e -cs 'help_name));
         else return(find_tag('-e e 'help_name));
      }

   }


  /* check if this is a macro procedure or command. */
  index= find_index(help_name,type);
  if(name_type(index)&(DLLCALL_TYPE)){
     p_window_id = orig_view_id;
     status = FILE_NOT_FOUND_RC;
     if (_haveContextTagging()) {
        status = find_tag(name);
     }
  } else if(name_type(index)&(OBJECT_TYPE|EVENTTAB_TYPE)){
     status=_find_form_eventtab(help_name);
     return(status);
  } else if ( index && ! ((name_type(index) & (PROC_TYPE|COMMAND_TYPE)) &&
                     ! index_callable(index)) ) {
    /* check if it is unique. */
    if ( find_index(help_name,type & ~name_type(index)) ) {
      command_put('find-proc');
      name=list_matches(help_name,'pcbNt',nls('Select a procedure to find'));
      _cmdline.set_command('',1);cursor_data();
      if ( name=='' ) return(COMMAND_CANCELLED_RC);
      parse name with help_name type_name ;
      type=eq_name2value(type_name,PCB_TYPES);
      p_window_id = orig_view_id;

      index=find_index(help_name,type);
    }
    module_index= index_callable(index);
    module_name=name_name(module_index);
    if ( module_name=='' ) {
       //proc_name=translate(help_name,'_','-')
       //return(find_tag(proc_name));
       msg=nls('No source for %s',help_name);
       status=FILE_NOT_FOUND_RC;
    } else {
       status=search_for_proc(module_name,help_name);
       if (status == FILE_NOT_FOUND_RC) {
          msg=get_message(CMRC_FILE_NOT_FOUND_1ARG, module_name);
       } else {
          msg=nls("Could not find procedure '%s' in '%s'",help_name,module_name);
       }
    }
  } else {

     _str proc_name=translate(help_name,'_','-');
     int mark=_alloc_selection();
     status=(mark<0)?mark:0;
     if ( ! status ) {
        _select_char(mark);
        save_pos(auto p);
        top();
        status=_VirtualProcSearch(proc_name);
        if ( ! status ) {
           _free_selection(mark);
           linenum := p_line;
           col := p_col;
           restore_pos(p);
           goto_line(linenum);p_col=col;
           return(0);
        }
        _begin_select(mark);
        _free_selection(mark);
     }
     help_name=translate(help_name,'_','-');
     if (h_match_exact(help_name)!='') {
        return(help(help_name));
     }
     msg = nls("Can't find proc '%s'",help_name);
     status = BT_RECORD_NOT_FOUND_RC;
  }

  if (module_name == "") {
     if (status) status=search_for_proc("builtins.e",help_name);
     if (status) status=search_for_proc("slick.sh",help_name);
     if (status) msg=nls('No source for %s',help_name);
  }

  if (status < 0) {
     if (msg != "") {
        _message_box(msg);
     } else {
        _message_box(get_message(status));
     }
  }

  return(status);

}
/**
 * Finds Slick-C&reg; source code for the Slick-C&reg; command bound 
 * to a particular key combination.
 *
 * @see find_proc
 * @see gui_find_proc
 *
 * @appliesTo  Edit_Window
 * @categories Search_Functions
 */
_command int find_key_binding,fk()
{
   _macro_delete_line();
   typeless keytab_used,k;
   _str keyname;
   if (prompt_for_key(nls('Find proc bound to key:')' ',keytab_used,k,keyname,'','','',1)) {
      return(1);
   }
   int index=eventtab_index(keytab_used,keytab_used,event2index(k));
   if ( index && (name_type(index)&(COMMAND_TYPE|EVENTTAB_TYPE))) {
     int type=name_type(index) & ~(INFO_TYPE|DLLCALL_TYPE);
     _str type_name=eq_value2name(type& ~INFO_TYPE,HELP_TYPES);
     proc_name := name_name(index);
     _macro_call('find_key_binding', keyname);
     append_retrieve_command('find_proc 'name_name(index));
     proc_name = stranslate(proc_name, '_', '-');
     return find_proc(proc_name);
   }
   _str msg=nls('%s is not defined',keyname);
   if (p_HasBuffer) {
      _message_box(msg);
   } else {
      message(msg);
   }
   return(1);
}

/**
 * Performs a path search for <i>module_name</i>, loads module, and
 * searches for procedure or command with name <i>proc_name</i>
 * placing the cursor on the definition
 *
 * @return Returns 0 if successful.  Otherwise a string message is returned
 * explaining the reason for failure.
 *
 * @appliesTo Edit_Window
 *
 * @categories Search_Functions
 *
 */
static int search_for_proc(_str module_name,_str proc_name)
{
  proc_name= translate(proc_name,'_','-');
  _str ext=_get_extension(module_name);
  if ( ! _file_eq('.'ext,_macro_ext) && ! _file_eq(ext, "sh") ) {
     module_name= substr(module_name,1,length(module_name)-length(ext)-1):+_macro_ext;
  }
  
  _str filename=_macro_path_search(module_name);
  if ( filename=='' ) {
     filename= slick_path_search(module_name);
  }
  if ( filename=='' ) {
    return FILE_NOT_FOUND_RC;
  }
  /* check if file exists in memory already */
  status := 0;
  rc=edit('+b '_maybe_quote_filename(absolute(filename)));
  file_exists := ! rc;
  if ( ! file_exists ) {
    clear_message();
    status= edit(_maybe_quote_filename(filename));
    if ( status ) {
      return status;
    }
  } else {
    top();
  }
  save_pos(auto p);
  status=_VirtualProcSearch(proc_name);
  if ( ! status ) {
     linenum := p_line;
     col := p_col;
     restore_pos(p);
     goto_line(linenum);p_col=col;
     return(0);
  }
  if ( ! file_exists ) { quit(); }
  return BT_RECORD_NOT_FOUND_RC;
}
/**
 * Retrieves or sets the value of a global variable.  The current value is
 * displayed on the command line if the <i>new_value</i> parameter is
 * omitted.
 *
 * @param cmdline is a string in the format: <i>variable</i>
 * [<i>new_value</i>]
 *
 * @see gui_set_var
 * @see _set_var
 * @see _get_var
 *
 * @categories Macro_Programming_Functions
 *
 */
_command set_var(_str cmdline='') name_info(VAR_ARG' 'WORD_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _str var_name, content;
   cmdline=prompt(cmdline);
   parse cmdline with var_name ' ' content ;
   index := find_index(var_name,VAR_TYPE|BUFFER_TYPE);
   if ( ! index ) {
     message(nls("Can't find variable '%s'",var_name));
     return(1);
   }
   if ( content=='' ) {
      typeless *pv;
      pv= &_get_var(index);
      int format=pv->_varformat();
      if (format==VF_HASHTAB || format==VF_ARRAY || format==VF_OBJECT) {
         // Assume variable is modified.
         if (substr(var_name,1,3)=='def') {
            _config_modify_flags(CFGMODIFY_DEFVAR);
         } else {
            _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
         }
         show('_var_editor_form',var_name,pv);
         return(0);
      }
      if (format==VF_EMPTY) {
         if ( get_string(content,nls('Variable value(EMPTY):')' ',';.set_var','') ) {
            return 1;
         }
      } else {
         if ( get_string(content,nls('Variable value:')' ',';.set_var',_get_var(index)) ) {
            return 1;
         }
      }
   }
   if (substr(var_name,1,3)=='def') {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else {
      _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
   }
   _set_var(index,content);
   return(0);

}

defeventtab _set_var_form;

/**
 * Displays <b>Set Variable dialog box</b>.  This dialog box sets a
 * global Slick-C&reg; variable.
 *
 * @example void show('_set_var_form')
 *
 * @categories Forms
 *
 */
_ok.on_create()
{
   combo1._insert_name_list(VAR_TYPE|BUFFER_TYPE);
   combo1._lbsort();
   _ctlsv_edit.p_enabled=false;
   text1.p_enabled=false;//Had to have these to compile
   text1.p_prev.p_enabled=false;
}

combo1.on_change(int reason)
{
   _str lbtext=_lbget_text();
   var_name := strip(combo1.p_text);
   index := find_index(var_name, VAR_TYPE|BUFFER_TYPE);
   if ( ! index ) {
      _ctlsv_edit.p_enabled=false;
      return('');
   }
   typeless var_p=&_get_var(index);
   switch (var_p->_varformat()) {
   case VF_LSTR:
   case VF_INT:
   case VF_WID:
   case VF_INT64:
      _ctlsv_edit.p_enabled=false;
      text1.p_enabled=true;
      text1.p_prev.p_enabled=true;
      text1.p_text=*var_p;
      break;
   case VF_PTR:
   case VF_ARRAY:
   case VF_HASHTAB:
   case VF_OBJECT:
      _ctlsv_edit.p_enabled=true;
      text1.p_enabled=false;
      text1.p_text='';
      text1.p_prev.p_enabled=false;
   }
}

void _ctlsv_edit.lbutton_up()
{
   var_name := strip(combo1.p_text);
   index := find_index(var_name, VAR_TYPE|BUFFER_TYPE);
   if ( ! index ) {
     return;
   }
   typeless var_p=&_get_var(index);
   int wid=show('-mdi -hidden _var_editor_form',var_name,var_p);
   wid.p_x=p_active_form.p_x_extent;
   wid._show_entire_form();
   wid.p_visible=true;
   text1.p_text='';
   text1.p_enabled=false;
}

void _ok.lbutton_up()
{
   var_name := strip(combo1.p_text);
   index := find_index(var_name, VAR_TYPE|BUFFER_TYPE);
   if ( ! index ) {
     _message_box("Macro variable \""var_name"\" does not exist.");
     combo1._set_focus();
     return;
   }
   if (text1.p_enabled) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _set_var(index, text1.p_text);
      _macro('m',_macro('s'));
      _macro_append(combo1.p_text'='text1.p_text";");
      value := text1.p_text;
      if (!isnumber(value)) {
         value = _quote(value);
      }
      _macro_append(var_name'='value";");
      p_active_form._delete_window(0);
   }
}

/**
 * Displays and optionally sets a macro variable you specify.  A dialog
 * box is displayed to prompt you for the macro variable and value.
 *
 * @see set_var
 *
 * @categories Macro_Programming_Functions
 *
 */
_command gui_set_var()  name_info(VAR_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _macro_delete_line();
   typeless result = show('_set_var_form');
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   return(0);
}


/**
 * @return  Returns the default state file name that should be used if
 * the user is prompted to save the configuration or if the configuration
 * is automatically saved.
 *
 * @categories Miscellaneous_Functions
 */
_str _default_state_filename()
{
   filename := editor_name('s');
   if ( filename=='' || '.'_get_extension(filename)=='.'_macro_ext'x' ) {
      filename=slick_path_search(STATE_FILENAME);
      if ( filename=='' ) {
         filename=STATE_FILENAME;
      }
   }
   /* If state file not local to user or _SLICKCONFIG directory. */
   if ( _use_config_path(absolute(filename)) || pos('.ver.',filename,1,_fpos_case)) {
      _str local_dir=_ConfigPath();
      filename=local_dir:+STATE_FILENAME;
   }
   return(filename);
}
/**
 * Saves macro module(s), name table, key table(s), global/static variable
 * value(s), and editor options to <i>filename</i>.  When the editor is
 * invoked, it searches for the state file.  First the directory from which
 * the editor was loaded is searched and then the PATH directories are
 * searched.  The editor will not search for a state file if the editor is
 * invoked with the '-x' option in the command line.  State files (.sta) or
 * normal pcode files (.ex) may be specified with the -x option.
 *
 * <p>UNIX:  Note that you should use the <b>save_config</b> command
 * under normal circumstances instead of this command.  The
 * <b>save_config</b> command save source code for configuration
 * changes which gets applied to the state file when the editor is invoked.</p>
 *
 * @return Returns 0 if successful.  Common return codes are:
 * INVALID_OPTION_RC, ACCESS_DENIED_RC,
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC,
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC,
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC.  On
 * error, message displayed.
 *
 * @example
 * <pre>
 *         _write_state('rich.sta');
 *         // now the editor may be invoked with "vs -xrich.sta".
 * </pre>
 *
 * @see clear_message
 *
 * @categories File_Functions
 *
 */
_command write_state(_str arg1='',bool ignore_errors=false,bool quiet=false) name_info(FILE_ARG',')
{
   cant_write_config_files := _default_option(VSOPTION_CANT_WRITE_CONFIG_FILES);
   if (cant_write_config_files) return(0);
   if ( arg1=='' ) {
      validLocation := false;
      while (!validLocation) {
         _str filename=_default_state_filename();
         arg1=prompt('',nls('Save config to'),filename);
         // Do not allow specifying a directory, they need to give file name
         if (isdirectory(arg1) && !ignore_errors) {
           popup_message("Cannot create file "arg1" because it is an existing directory.  Please specify a path with a file name.");
         } else {
           validLocation = true;
         }
      }
   } else {
      if (isdirectory(arg1) && !ignore_errors) {
        message("Cannot create file "arg1" because it is an existing directory.  Please specify a path with a file name.");
        return (INVALID_OPTION_RC);
      }
   }
   if(!quiet) message(nls('Saving configuration to %s',arg1));
   /* If path on filename is users config directory. */
   if ( _file_eq(_ConfigPath(),substr(arg1,1,pathlen(arg1))) ) {
      if ( _create_config_path() ) {
         return(1);
      }
   }
   call_list("_before_write_state_");
   _delete_unused();
   mou_hour_glass(true);
   int status=_write_state(arg1);
   mou_hour_glass(false);
   if ( status ) {
      // Don't show warning message when running as Tools
      if(!isVisualStudioPlugin() && !ignore_errors) {
         popup_message(nls("Failed to save configuration to '%s'.",arg1)"\n\n"get_message(status));
      }
      return(status);
   }
   if(!quiet) clear_message();
   if (_need_to_save_cfgfiles()) {
      _config_modify_flags(0, ~(CFGMODIFY_MUSTSAVESTATE|CFGMODIFY_DELRESOURCE));
   } else {
      _config_modify_flags(0, 0);
   }
   return(0);
}
/**
 * Loads a Slick-C&reg; macro module.  The <b>Explorer Standard Open dialog
 * box</b> or <b>Standard Open dialog box</b> is displayed to prompt you for a
 * macro file to load.
 *
 * @return Returns 0 if successful.
 *
 * @see gui_unload
 * @see load
 * @see unload
 *
 * @categories Macro_Programming_Functions
 *
 */
_command gui_load()
{
   _macro_delete_line();
   initial_filename := "";
   if (p_HasBuffer) {
      initial_filename=p_buf_name;
      _str extension=_get_extension(initial_filename);
      if ( ! _file_eq('.'extension,_macro_ext) && ! _file_eq(extension,'cmd') ) {
         initial_filename='';
      }
   }
   typeless result=_OpenDialog('-modal',
        'Load Module', '*.e',
        "SlickEdit (*.e),All Files ("ALLFILES_RE")",
        OFN_FILEMUSTEXIST,
        substr(_macro_ext, 2), // Default extensions
        initial_filename,      // Initial filename
        '',                    // Initial directory
        'gui_load',             // Retrieve name
        'load module dialog box' // Help item
        );
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',_macro('s'));
   _macro_call('load', result);
   typeless status = load(result);
   return(status);
}

/*
   DLL interface.  Load DLL.
*/

/**
 * Returns 'true' if the given path points to a DLL that 
 * is shipped with SlickEdit, as apposed to a user-written 
 * DLL or an OEM partner's DLL. 
 */
bool isShippedDLL(_str path)
{
   bindir  := get_env("VSLICKBIN");
   dlldir  := _strip_filename(path,"N");
   if (dlldir!='' && !_file_eq(dlldir,bindir)) {
      return false; 
   }

   dllname := _strip_filename(path,"PE");
   switch (lowcase(dllname)) {
   case "cformat":
   case "cparse":
   case "filewatcher":
   case "tagsdb":
   case "vsdebug":
   case "vshlp":
   case "vsockapi":
   case "vsrefactor":
   case "vsRTE":
   case "vsscc":
   case "vsvcs":
   case "vsxmlutl":
   case "wwts":
      return true;
   default:
      return false;
   }
}

/**
 * Loads a DLL which uses our DLL Interface functions.
 * The entry point function of the DLL registers DLL functions
 * that can be bound to keys and called from Slick-C&reg; macros.
 * If <i>DllFilename</i> is not given, you are prompted for one.
 * See simple.c for an example of a DLL that can be loaded.
 * <p>
 * This function is not yet available in the UNIX version.
 *
 * @return  Returns 0 if successful.
 *
 * @see dunload
 * @see _dllload
 * @categories Macro_Programming_Functions
 */
_command dload(_str filename='') name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Shared libraries");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (filename=='') {
     filename=prompt('',nls('Load DLL'));
   }
   if (filename=='') {
      return(1);
   }
   _str ext=_get_extension(filename);
   if (ext=='') {
      filename :+= DLLEXT;
   }
   _str oriFilename;
   oriFilename = filename;

   if (_isUnix()) {
      // UNIX version does not have DLL support yet.  Faking DLL support
      // for cparse.dll.  Which actually code linked into the editor.
      if (isShippedDLL(filename)) {
         filename = _strip_filename(filename,'PE') :+ ".dll";
         _config_modify_flags(CFGMODIFY_LOADDLL);
         _dllload(filename);
         return(0);
      }
      // Translate NAME.dll to libNAME.so to do a file existence check.
      modExt := substr(filename,lastpos(".",filename));
      if (modExt == DLLEXT) {
         sharedLibExt := ".so";
         if (machine() == "HP9000") sharedLibExt = ".sl";
         filename = _strip_filename(filename, "EN") :+ "lib" :+ _strip_filename(filename, "PE") :+ sharedLibExt;
      }
   }
   _str path=slick_path_search(filename);
   if (path=='') {
      _message_box(nls('File %s not found',oriFilename));
      return(FILE_NOT_FOUND_RC);
   }
   if (_isUnix()) {
      // Convert name back to original format:  NAME.dll
      path = oriFilename;
   }

   present := _macfile_present(path,DLLEXT);
   status := _dllload(path);
   if (status) {
      _message_box(nls('Failed to load DLL %s',path)'.  'get_message(status));
   }
   if (!status) {
      _config_modify_flags(CFGMODIFY_LOADDLL);
      if (!isShippedDLL(path)) {
         _macfile_add(path,DLLEXT,present);
      }
   }
   return(status);
}

/**
 * This function is not yet available in the UNIX version.  Unloads a DLL.
 * All functions registered to this DLL with the <b>vsDllExport</b> function
 * are deleted.  Do not specify a path in <i>DllFilename</i>.  If
 * <i>DllFilename</i> is not given, you a prompted for one.
 *
 * @return  Returns 0 if successful.
 *
 * @see dload
 * @see _dllload
 *
 * @appliesTo  Edit_Window
 * @categories Macro_Programming_Functions
 */
_command dunload(_str filename='') name_info(DLLMODULE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveProMacros()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Shared libraries");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (filename=='') {
     filename=prompt('',nls('Unload DLL'));
   }
   if (filename=='') {
      return(1);
   }
   _str ext=_get_extension(filename);
   if (ext=='') {
      filename :+= DLLEXT;
   }
   if (_isUnix()) {
      // UNIX version does not have DLL support yet.  Faking DLL support
      // for cparse.dll.  Which actually code linked into the editor.
      switch (filename) {
      case 'cparse':
      case 'cparse.dll':
         _config_modify_flags(CFGMODIFY_LOADDLL);
         _dllload('cparse.dll','u');
         return(0);
      }
   }
   int status=_dllload(filename,'u');
   if (status==FILE_NOT_FOUND_RC) {
      _message_box(nls('File %s not loaded',filename));
   }
   if (!status) {
      _config_modify_flags(CFGMODIFY_LOADDLL);
      _macfile_delete(filename,DLLEXT);
   }
   return(status);
}

_str scfile_match(_str name,bool find_first)
{
   name=f_match(name,find_first);
   for (;;) {
      if ( name=='' ) {
         return('');
      }
      if ( _last_char(name)==FILESEP || _file_eq('.'_get_extension(name),_macro_ext) ) {
         break;
      }
      name=f_match(name,false);
   }
   return(name);

}

/**
 * Find the module associated with the given Slick-C header file (.sh). 
 * The associated module is found using the metadata program. 
 */
static _str find_metadata_match(_str header_file, bool &saved_buffer)
{
   // only the Pro version can do this
   if (!_haveProMacros()) {
      return "";
   }

   // check that file extension is .sh
   ext := _get_extension(header_file);
   if (!_file_eq(ext, "sh")) {
      return "";
   }

   // open the file
   temp_wid := orig_wid := 0;
   buffer_already_exists := false;
   status := _open_temp_view(header_file, temp_wid, orig_wid, "", buffer_already_exists);
   if (status < 0) {
      return "";
   }

   // search for the pragma
   top();
   _begin_line();
   status = search("^[ \\t]*[#][ \\t]*pragma[ \\t]+option[ \t]*\\([ \t]*metadata,[ \t]*\\\"{:f}\\\"[ \t]*\\)", "@erh");
   if (status < 0) {
      _delete_temp_view(temp_wid);
      activate_window(orig_wid);
      return "";
   }

   // get the name of the module that was found
   module_path := "";
   if (!status) {
      module_name := get_match_text(0);
      if (module_name != "") {
         module_path = _strip_filename(header_file, 'N');
         _maybe_append_filesep(module_path);
         module_path :+= module_name;
         if (!file_exists(module_path)) {
            module_path = "";
         }
      }
   }

   // save the correlating buffer if it is open and modified, otherwise, just touch it
   // bail out if there is a problem
   if (module_path != "") {
      if (buffer_already_exists && p_modify) {
         status = save();
         if (status < 0) {
            module_path = "";
         } else {
            saved_buffer = true;
         }
      }
   }

   // clean up temp view of header file
   _delete_temp_view(temp_wid);
   activate_window(orig_wid);

   // now open a temp view of the alternate module
   if (module_path != "") {
      status = _open_temp_view(module_path, temp_wid, orig_wid, "+b", buffer_already_exists);
      if (status < 0) {
         if (!file_exists(module_path)) {
            return "";
         }
         status = _file_touch(module_path);
         if (status < 0) {
            module_path = "";
         }
      } else {
         if (buffer_already_exists && p_modify) {
            status = save();
            saved_buffer = true;
         }
         // and clean up
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
   }

   // that's all folks
   return module_path;
}


/**
 * Compiles (if necessary) and loads the <i>modules</i> specified.  If the
 * module is already loaded it is replaced.  If no module is specified and the
 * current buffer has the extension ".e", the current buffer is saved (if
 * necessary) and loaded.
 * <p>
 * Prior to loading the module, it will invoke the <code>_on_unload_XXX</code>
 * callbacks with a single argument indicating the Slick-C&reg; module to be loaded.
 *
 * @return Returns 0 if successful.  Since this command does not actually
 * load the modules until the macro terminates, it is possible that the load can
 * still fail.
 *
 * @see gui_load
 * @see gui_unload
 * @see unload
 *
 * @appliesTo Edit_Window
 *
 * @categories Macro_Programming_Functions
 *
 */
_command int load(_str arg1='') name_info(SLICKC_FILE_ARG',')    /* make and load module */
{
   saved_buffer := false;
   default_buf_name := "";
   module := "";
   arg1=strip(arg1,'B','"');
   if ( arg1=='<' || (arg1=='' && _no_child_windows())) {
      default_buf_name=(_no_child_windows())?'':p_buf_name;
      arg1=prompt('',nls('Load module'),default_buf_name);
   }
   alt_module := "";
   if (arg1=='') {
      alt_module = find_metadata_match(p_buf_name, saved_buffer);
      if (alt_module != "") arg1 = alt_module;
   }
   if ( arg1=='' || (p_HasBuffer && _file_eq(p_buf_name,absolute(arg1)) )) {
      _str extension=_get_extension(p_buf_name);
      if ( ! _file_eq('.'extension,_macro_ext) && ! _file_eq(extension,'cmd') ) {
         _message_box(nls('File %s does not have a macro extension',p_buf_name));
         return(1);
      }
      if ( p_modify ) {
         saved_buffer = true;
         status := save();
         if ( status ) {
            return(status);
         }
      }
      default_buf_name=(_no_child_windows())?'':p_buf_name;
      module=_maybe_quote_filename(default_buf_name);
   } else {
      module=_maybe_quote_filename(arg1);
   }
   if (!_no_child_windows() && arg1=='') {
      Path := strip(p_DocumentName);
      if (substr(Path,1,6)=='ftp://') {
         message('Did not load ftp''d file.');
         return(0);
      }
   }
   is_plugin_macro := false;
   module_nq:=strip(module, "B",'"');
   if (!_isRelative(module_nq)) {
      temp:=_plugin_relative_path(module_nq);
      if (temp!=null) {
         module_nq=VSCFGPLUGIN_DIR:+temp;
         module=_maybe_quote_filename(module_nq);
         is_plugin_macro=true;
      }
   }

   // make sure file even exists before trying to load it
   if ( !file_exists(module_nq) ) {
      popup_message(nls("Can't find module '%s'",module));
      return FILE_NOT_FOUND_RC;
   }

   // This is done when the _load() built-in is called.
   //call_list("_on_load_module_", module, option);

   // do we currently have any hotfixes applied? - if so, we need to 
   // make sure and check for files there
   origInclude := get_env("VSLICKINCLUDE");
   hotfixDir := hotfixGetHotfixesDirectory();
   if (isdirectory(hotfixDir)) {
      // we have a hotfixes directory, so better include it
      set_env("VSLICKINCLUDE", hotfixDir :+ PATHSEP :+ origInclude);
   }

   // call the macro compiler to make sure the .ex is built
   make_done := false;
   if (_macroCompilePermitted(module)) {
       make_done= true;
       message(nls('Making %s',module));
      _make(module);
   } else {
      rc=0;
   }
   typeless make_rc=rc;

   // restore the VSLICKINCLUDE path
   set_env("VSLICKINCLUDE", origInclude);

   // check if we had a compilation error
   if ( make_rc ) {
      if ( make_rc==FILE_NOT_FOUND_RC ) {
         popup_message(nls("Can't find module '%s'",module));
      } else {
         if ( make_rc==1  ) {  /* rc from Slick Translator? */
            /* Don't display message if ST macro already has */
            /* has displayed the error. */
            if ( ! find_index('st',COMMAND_TYPE) ) {
               popup_message(nls("Unable to make '%s",module)'.  ':+
                             nls('Compilation failure.'));
            }
         } else {
            popup_message(nls("Unable to make '%s'",module)".  "get_message(make_rc));
         }
      }
      return(make_rc);
   }
   int already_present=_macfile_present(module,_macro_ext'x');
   // In the standard version, if we are loading a system macro, 
   // just load the pcode if it it exists (it was supposed to be installed)
   if (!make_done) {
      module_filename:=strip(module,'B','"');
      pcode_filename:=module_filename;
      if (_last_char(pcode_filename)!='x') {
         pcode_filename :+= 'x';
      } else {
         module_filename=substr(module_filename,1,length(module_filename)-1);
      }
      if (!file_exists(pcode_filename) || saved_buffer) {
         clear_message();
         popup_message(nls("Compiling macro '%s1' requires Pro version",module));
         return VSRC_FEATURE_REQUIRES_PRO_EDITION;
      }
      // If the soruce coce was modified, do not just blindly load the .ex file.
      module_date := (long)_file_date(module_filename, 'B');
      pcode_date  := (long)_file_date(pcode_filename, 'B');
      if (module_date > pcode_date && _message_box(nls("Module '%s1' is out of date and compiling requires Pro version.\n\nLoad out of date bytecode anyway?",module),"SlickEdit",MB_YESNO) != IDYES) {
         clear_message();
         return VSRC_FEATURE_REQUIRES_PRO_EDITION;
      }
   }
  // Load needed a global variable since, defload and d  efinit are executed
  // after the _load opcode completes.  We could change t   his if defload
  // and definit executed immediately.
   _loadrc=0;
   _load(module,'r');
   int status=_loadrc;
   if ( !status) {
      if (is_plugin_macro) {
         if (!_in_firstinit) {
            tfindex := 0;
            if(!_e_MaybeBuildTagFile(tfindex) ) {
               _MaybeTagSlickCFile(module_nq, tfindex);
            }
         }
      } else {
         _macfile_add(module,_macro_ext'x',already_present);
      }
      if (alt_module != "") {
         message(nls('Module "%s" loaded',_strip_filename(alt_module,'P')));
      } else {
         message(nls('Module(s) loaded'));
      }
      name := _strip_filename(module,'P');
      if (_file_eq(USERMACS_FILE:+_macro_ext,name)) {
         _config_modify_flags(CFGMODIFY_USERMACS);
      } else {
         _config_modify_flags(CFGMODIFY_LOADMACRO);
      }
     // Event tables may have changed
      if (_display_wid) {
        // LOAD command must post_command since modules are not
        // loaded immediately.
         _post_call(find_index('_deupdate',PROC_TYPE));
      }
      _post_call(find_index('_MaybeUpgradeLanguageSetup',PROC_TYPE),module);
   } else {
      _message_box(nls("Unable to load module '%s'.",module)"  "get_message(status));
   }
   return(status);
   /* call messageNwait('rc='rc) */
}

static _str list_macfiles_edit_callback()
{
   _str result=_OpenDialog('-modal',
                    'Choose File',        // Dialog Box Title
                    '',                   // Initial Wild Cards
                    "Macro file (*.ex)",  // File Type List
                    OFN_FILEMUSTEXIST     // Flags
                    );
   result=strip(result,'B','"');
   if (result != '') {
      if (_message_box('Load "'result'"?',"SlickEdit",MB_YESNO) == IDYES) {
         ext := _get_extension(result);
         load(result);
      }
   }
   return result;
}
static void list_macfiles_delete_callback(_str item)
{
   if (_message_box('Unload "'item'"?',"SlickEdit",MB_YESNO) == IDYES) {
      module := _strip_filename(item, 'P');
      unload(module);
   }
}

/**
 * Display a list of the user's loaded macros and allow them 
 * to load, unload, or re-order them.  This is essentially a 
 * fancy editor for {@link def_macfiles}. 
 *  
 * @see def_macfiles 
 * @see list_macros 
 * @see load 
 * @see unload 
 * @see gui_load 
 * @see gui_unload 
 *  
 * @categories Macro_Programming_Functions
 */
_command void gui_list_macfiles() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   // convert def_macfiles to an array of filenames (unquoted)
   _str macfiles[];
   foreach (auto module in def_macfiles) {
      macfiles[macfiles._length()] = strip(module,'B','"');
   }

   // use the generic list editor to modify the list
   result := show('-modal -xy _list_editor_form',
                  'User-Loaded Modules',
                  'Macro file (.ex):',
                  macfiles,
                  list_macfiles_edit_callback,
                  '',
                  'User-Loaded Modules dialog',
                  false,
                  list_macfiles_delete_callback);

   // update def_macfiles if they hit 'ok'
   if (result == 'ok') {
      list := "";
      foreach (module in _param1) {
         if (list != "") list :+= " ";
         list :+= _maybe_quote_filename(module);
      }
      if (list != def_macfiles ) {
         def_macfiles = list;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }
}

/**
 * Unloads a Slick-C&reg; macro module you choose.  A dialog box is displayed
 * which prompts you for a macro module.  Type in a Slick-C&reg; module name or
 * select a module name from the list box.
 *
 * @see unload
 *
 * @categories Macro_Programming_Functions
 *
 */
_command gui_unload()
{
   typeless result=_list_matches2(
                  'Unload Module',   // title
                  SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_MUSTEXIST,        // flags
                  '',       // buttons
                  'unload module',       // help_item
                  '',       // font
                  '',       // callback
                  'unload',    // retrieve_name
                  MODULE_ARG); // completion
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   unload(result);
}
/**
 * Unloads module specified.  If the module is currently running it may
 * not be unloaded.  Do not specify a path for <i>module_name</i>.
 * <p>
 * Prior to unloading the module, it will invoke the
 * <code>_on_unload_module_XXX</code> callbacks with a single argument
 * indicating the Slick-C&reg; module to be unloaded.
 *
 * @see load
 * @see gui_load
 * @see gui_unload
 *
 * @categories Macro_Programming_Functions
 *
 */
_command void unload(_str filename='', bool quiet=false, bool plugin_rebuild_tag_file=true) name_info(MODULE_ARG',')
{
   filename=prompt(filename,'Unload module');
   filename=strip(filename,'B','"');

   // notify callbacks of pending unload
   call_list("_on_unload_module_", filename);

   is_plugin_module := pathlen(filename)!=0 && _isRelative(filename);

   int status=_load(_maybe_quote_filename(filename),'u');
   if (status) {
      if (!quiet) _message_box("Problems unloading "filename": "get_message(status));
      return;
   }
   if (is_plugin_module) {
      if (plugin_rebuild_tag_file) {
         _e_MaybeBuildTagFile(auto tfindex,true,true,true);
      }
   } else {
      _UntagSlickCFile(strip(filename,'B','"'));
   }
   _str name=filename;  // this fill must be relative or _load() call will fail
   if (_file_eq(USERMACS_FILE:+_macro_ext,name)) {
      _config_modify_flags(CFGMODIFY_USERMACS);
   } else {
      _config_modify_flags(CFGMODIFY_LOADMACRO);
      if (!is_plugin_module) {
         _macfile_delete(filename,_macro_ext'x');
      }
   }
}
/**
 * @return Returns <b>true</b> if the name specified 
 * is a valid Slick-C&reg; identifier.
 *
 * @categories Miscellaneous_Functions
 *
 */
bool isid_valid(_str name)
{
   /* name must not be null */
   if (name=='') {
      return(false);
   }
   /*  name must consist of valid identifier characters. */
   if ( pos('[~A-Za-z0-9_$]',name,1,'r') ) {
      return(false);
   }
   /*  First character must not be number. */
   if (isinteger(substr(name,1,1))) {
      return(false);
   }
   if (name_eq(substr(name,1,2),'p_')) {
      return(false);
   }
   return(true);
}

static void setLanguageOptions(_str pszLangId,
                       VS_LANGUAGE_OPTIONS &langOptions,_str info)
{

   // these things are in common among all the languages
   /*******************************************************
    * 0. LOI_SYNTAX_INDENT                                *
    * 1. LOI_SYNTAX_EXPANSION                             *
    ******************************************************/

   parse info with auto SyntaxIndent auto SyntaxExpansion info;
   if (isinteger(SyntaxIndent)) {
      _LangOptionsSetProperty(langOptions,LOI_SYNTAX_INDENT,(int)SyntaxIndent);
   }
   if (isinteger(SyntaxExpansion)) {
      _LangOptionsSetProperty(langOptions,LOI_SYNTAX_EXPANSION,(int)SyntaxExpansion!=0);
   }

   // different languages have different ways of parsing this info
   if (_LanguageInheritsFrom("html", pszLangId) || _LanguageInheritsFrom("xml", pszLangId)) {
      /*******************************************************
       * 2. LOI_TAG_CASE                                     *
       * 3. LOI_ATTRIBUTE_CASE                               *
       * 4. LOI_WORD_VALUE_CASE                              *
       * 11. LOI_HEX_VALUE_CASE                              *
       ******************************************************/
      parse info with auto tag_case auto attribute_case auto word_value_case auto s5 auto s6 auto s7 auto s8 auto s9 auto s10 auto hex_value_case info;
      if (isinteger(tag_case)) {
         _LangOptionsSetProperty(langOptions,LOI_TAG_CASE,(int)tag_case);
      }
      if (isinteger(attribute_case)) {
         _LangOptionsSetProperty(langOptions,LOI_ATTRIBUTE_CASE,(int)attribute_case);
      }
      if (isinteger(word_value_case)) {
         _LangOptionsSetProperty(langOptions,LOI_WORD_VALUE_CASE,(int)word_value_case);
      }
      if (isinteger(hex_value_case)) {
         _LangOptionsSetProperty(langOptions,LOI_HEX_VALUE_CASE,(int)hex_value_case);
      }
   } else {
       /*******************************************************
        * 2. LOI_MIN_ABBREVIATION                             *
        ******************************************************/
       parse info with auto minAbbrev info;
       if (isinteger(minAbbrev)) {
          _LangOptionsSetProperty(langOptions,LOI_MIN_ABBREVIATION,(int)minAbbrev);
       }

       parse info with auto keyword_case info;
       if (!_LanguageInheritsFrom("ruby", pszLangId)) {
          // ruby doesn't have this item, so just skip it for this language

          /*******************************************************
           * 3. LOI_KEYWORD_CASE                                 *
           ******************************************************/
          if (isinteger(keyword_case)) {
             _LangOptionsSetProperty(langOptions,LOI_KEYWORD_CASE,(int)keyword_case);
          }
       }

       // these languages have no more info
       if (!_LanguageInheritsFrom("for", pszLangId) && !_LanguageInheritsFrom("cob", pszLangId)) {

          /*******************************************************
           * 4. begin/end style                                  *
           ******************************************************/
          // okay, so there are other things stored in this value than what we mess with
          // should we add them to the VS_LANGUAGE_OPTIONS?
          // for now, get the old value
          parse info with auto tbeStyle info;
          
          if (isinteger(tbeStyle)) {
             _LangOptionsSetProperty(langOptions,LOI_BEGIN_END_STYLE,(int)tbeStyle);

             /*int bestyle = (int)tbeStyle;

             // now get rid of the things that are stored in this struct
             bestyle &= ~(0x3 | 0x100 | 0x10 | 0x40 | 0x80 | 0x20);

             // now add stuff back in
             bestyle |= langOptions.BeginEndStyle | langOptions.PointerStyle; 
             if (langOptions.PadParens) bestyle |= 0x100;
             if (langOptions.NoSpaceBeforeParen) bestyle |= 0x10;
             if (langOptions.FunctionBraceOnNewLine) bestyle |= 0x20;
             langOptions.BeginEndStyle=beStyle;*/
          }

          // now these languages are done
          if (!_LanguageInheritsFrom("vhd", pszLangId)) {
             // not used
             parse info with . info;
             if (_LanguageInheritsFrom("pas", pszLangId)) {
                parse info with auto IndentCaseFromSwitch info;
                /*******************************************************
                 * 6. LOI_INDENT_CASE_FROM_SWITCH                      *                        
                 ******************************************************/
                if (isinteger(IndentCaseFromSwitch)) {
                   _LangOptionsSetProperty(langOptions,LOI_INDENT_CASE_FROM_SWITCH,(int)IndentCaseFromSwitch);
                }
             } else {
                parse info with . info;
                /***********************************************************
                 * 6. unused
                 * 7. LOI_INDENT_CASE_FROM_SWITCH                          *
                 **********************************************************/

                parse info with auto IndentCaseFromSwitch info;
                /*******************************************************
                 * 6. LOI_INDENT_CASE_FROM_SWITCH                      *                        
                 ******************************************************/
                if (isinteger(IndentCaseFromSwitch)) {
                   _LangOptionsSetProperty(langOptions,LOI_INDENT_CASE_FROM_SWITCH,(int)IndentCaseFromSwitch);
                }
                parse info with auto use_continuation_indent_on_function_parameters info;
                if (isinteger(use_continuation_indent_on_function_parameters)) {
                   _LangOptionsSetProperty(langOptions,LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS,use_continuation_indent_on_function_parameters);
                }
             }
          }
       } 
   }
}
/**
 * Creates language specific setup data which is used by the Language Options
 * dialog box.  This procedure is typically used when adding support for 
 * languages not already provided by SlickEdit's default configuration.
 * 
 * @example 
 * <pre> 
 *    setup_info := 'MN=Modula,TABS=+3,MA=1 74 1,KEYTAB=ext-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=N/A,LN=,CF=0,LNL=0,TL=0,BNDS=,';
 *    compile_info := '';
 *    syntax_info := '3 1 1 0 0 1 0';
 *    be_info := '(WITH),(IF),(BEGIN),(WHILE),(CASE),(FOR),(LOOP)(RECORD)|(END) (REPEAT)|(UNTIL)';
 *    index := _CreateLanguage('mod',MOD_MODE_NAME,setup_info,compile_info,syntax_info,be_info);
 * </pre>
 *
 * @param langId           Language ID (see {@link p_LangId} 
 * @param mode_name        Name given to the language mode.
 * @param setup_info       A string which specifies the mode_name, tabs, 
 *                         margins, key table name,word wrap setting,
 *                         indent with tabs setting, show tabs
 *                         style, indent style, word chars,
 *                         lexer name, color flags, line
 *                         numbers, truncation length, and
 *                         bounds.
 * @param compile_info     Language specific compile command.
 * @param syntax_info      A string of numbers separated by spaces.<br> 
 *                         The first number specifies "Syntax Indent".<br>
 *                         The second number specifies syntax expansion on or off.<br> 
 *                         The the number specifies the minimum abbreviation
 *                         for syntax expansion when pressing space.<br>
 *                         The numbers that follow specify extension specific options.
 * @param be_info          String of "Begin/end pairs"
 * @param include_info     Default include path or copy book search path
 * @param word_chars       Set of characters used in identifiers/words
 * @param lexer_name       Name of lexer for Color Coding
 * @param color_flags      Color coding flags
 *
 * @return Returns         1 on success
 *  
 * @see _CreateExtension 
 * @see _ExtSetupToInfo 
 *  
 * @categories Configuration_Functions
 */
int _CreateLanguage(_str langId,          _str mode_name='',
                    _str setup_info='',   _str compile_info='',
                    _str syntax_info='',  _str be_info='',    
                    _str include_info='', _str word_chars='',
                    _str lexer_name='',   _str color_flags='')
{
   name := "";
   keytab_name := "";
   int index;
   parse setup_info with 'KEYTAB=' keytab_name ',';
   keytab_name=lowcase(strip(keytab_name));
   if ( keytab_name=='' ) {
      keytab_name='default-keys';
   }
   if ( keytab_name!='default-keys' ) {
      kt_index := find_index(keytab_name,EVENTTAB_TYPE);
      if ( ! kt_index ) {
         kt_index=insert_name(keytab_name,EVENTTAB_TYPE);
      }

      int enter_cmd=find_index(lowcase(mode_name)'-enter',COMMAND_TYPE);
      int space_cmd=find_index(lowcase(mode_name)'-space',COMMAND_TYPE);
      if (!enter_cmd) {
         enter_cmd=find_index(langId'-enter',COMMAND_TYPE);
      }
      if (!space_cmd) {
         space_cmd=find_index(langId'-space',COMMAND_TYPE);
      }
      if (enter_cmd) set_eventtab_index(kt_index,event2index(ENTER),enter_cmd);
      if (space_cmd) set_eventtab_index(kt_index,event2index(' '),space_cmd);
   }

   if ( !LanguageSettings.isLanguageDefined(langId) ) {

      _str bounds, caps, tabs, margins, word_wrap_style;
      _str indent_with_tabs, show_tabs, indent_style;
      _str tword_chars, tlexer_name, tcolor_flags;
      _str line_numbers_len, TruncateLength;
      parse setup_info with 'MN=' mode_name ',' 'TABS=' tabs ',' \
        'MA=' margins ',' 'KEYTAB=' keytab_name ',' 'WW='word_wrap_style ',' \
        'IWT='indent_with_tabs ',' 'ST='show_tabs',' 'IN=' indent_style',' \
        'WC='tword_chars',' 'LN='tlexer_name',' 'CF='tcolor_flags','\
        'LNL='line_numbers_len',' 'TL='TruncateLength',' 'BNDS='bounds',' 'CAPS='caps;
      if (tlexer_name=='') tlexer_name=lexer_name;
      if (tcolor_flags=='') tcolor_flags=color_flags;
      if (tword_chars=='') tword_chars=word_chars;
      if (word_wrap_style=='') word_wrap_style=3;
      if (indent_with_tabs=='') indent_with_tabs=0;
      if (show_tabs=='') show_tabs=0;
      if (indent_style=='') indent_style=INDENT_SMART;
      if(keytab_name=='') keytab_name='default-keys';
      if (!isinteger(line_numbers_len)) line_numbers_len=0;
      if (!isinteger(TruncateLength)) TruncateLength=0;
      keytab_name=lowcase(keytab_name);

      VS_LANGUAGE_OPTIONS langOptions;
      _LangInitOptions(langOptions);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_MODE_NAME,mode_name);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TABS,tabs);
      parse margins with auto left_margin auto right_margin auto new_para_margin;
      if (new_para_margin=='') {
         new_para_margin=left_margin;
      }
      if (isinteger(left_margin) && isinteger(right_margin) && isinteger(new_para_margin)) {
         _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_MARGINS,left_margin' 'right_margin' 'new_para_margin);
      }
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_WORD_WRAP_FLAGS,(int)word_wrap_style);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,indent_with_tabs!=0);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS,(int)show_tabs);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_INDENT_STYLE,(int)indent_style);
      if (tword_chars!='' && tword_chars!=WORD_CHARS_NOT_APPLICABLE) {
         _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_WORD_CHARS,tword_chars);
      }
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_LEXER_NAME,tlexer_name);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_COLOR_FLAGS,(int)tcolor_flags);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_LINE_NUMBERS_LEN,(int)line_numbers_len);
      _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_TRUNCATE_LENGTH,(int)TruncateLength);
      parse bounds with auto BoundsStart auto BoundsEnd;
      if (isinteger(BoundsStart) && isinteger(BoundsEnd)) {
         _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_BOUNDS,BoundsStart' 'BoundsEnd);
      }
      if (isinteger(caps)) {
         _LangOptionsSetProperty(langOptions,VSLANGPROPNAME_AUTO_CAPS,(int)caps);
      }
      setLanguageOptions(langId,langOptions,syntax_info);
      _CreateNewLanguage(langId,langOptions);
      //_CreateNewLanguage(langId, setup_info, syntax_info);
   } else {
      LanguageSettings.setModeName(langId, mode_name);
      LanguageSettings.setKeyTableName(langId, keytab_name);
   }
#if 0
   // Since v3, language specific compile info has not been supported
   if ( compile_info!='' ) {
      name='def-compile-'langId;
      index=find_index(name,MISC_TYPE);
      if ( ! index ) {
         insert_name(name,MISC_TYPE,compile_info);
      }
   }
#endif
   if ( be_info!='' ) {
      LanguageSettings.setBeginEndPairs(langId, be_info);
   }
#if 0
   // Reserved for future use
   if ( include_info!='' ) {
      name='def-include-'langId;
      index=find_index(name,MISC_TYPE)
      if ( ! index ) {
         insert_name(name,MISC_TYPE,include_info);
      }
   }
#endif
   return 1;
}

/**
 * Inserts Slick-C&reg; source code to rebuild current value of the global
 * variable specified.  If <i>GlobalVariableName</i> is not given, you are
 * prompted to select a global variable name.
 *
 * @param binary defaults to <b>false</b>.
 *
 * @param NewLineChars defaults to <b>p_newline</b>.
 *
 * @categories Macro_Programming_Functions
 */
_command insert_var(_str result='') name_info(VAR_ARG','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (result=='') {
      result=_list_matches2(
                     'Insert Variable Source',   // title
                     SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_MUSTEXIST /*|SL_DEFAULTCALLBACK*/,      // flags
                     '',       // buttons
                     'insert_var',   // help_item
                     '',       // font
                     '',  //'_open_form_callback', //callback
                     'insert_var',       // retrieve_name
                     VAR_ARG,            // completion
                     0,                     // min list width
                     ''                     // fast complete
                     );
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
   }
   int index=find_index(strip(result),VAR_TYPE|BUFFER_TYPE);
   if (!index) {
      popup_message(nls('Could not variable "%s".',strip(result)));
      return(1);
   }
   int status=maybe_delete_selection();
   if(status){
      if (status==4) {
         _delete_line();
      } else {
         up();
      }
   }
   int syntax_indent=p_SyntaxIndent;
   if (syntax_indent<=0) syntax_indent=3;
   _insert_var_source(_get_var(index),name_name(index),indent_string(syntax_indent),1);
   return(0);
}
// try to print as naturally as possible
static _str maybe_quote_value(var a)
{
   if (a == null) {
      return "null";
   }
   if (VF_IS_INT(a)) {
      return a;
   }
   if (a._varformat() == VF_LSTR && isnumber(a) && ((int)a) :== a) {
      return a;
   }
   return _quote(a);
}
/*
    Generates source for simple or complex variable.
    No source is genarated for pointer or function pointer values.
*/
void _insert_var_source(_str &a,_str varname,_str indent, int level, bool (&objectvars):[]=null)
{
   //messageNwait('vf='a._varformat()' level='level);
   varname=translate(varname,'_','-');
   switch (a._varformat()) {
   case VF_OBJECT:
   case VF_ARRAY:
   case VF_HASHTAB:
      typeless i,p;
      i._makeempty();
      for (;;) {
         p= &a._nextel(i);
         if (i._isempty()) break;
         switch (p->_varformat()) {
         case VF_EMPTY:
            insert_line(indent:+varname:+makeindex(a,i,level)'=null;');
            break;
         case VF_INT:
         case VF_WID:
         case VF_INT64:
            insert_line(indent:+varname:+makeindex(a,i,level)'='(*p)';');
            break;
         case VF_LSTR:
            insert_line(indent:+varname:+makeindex(a,i,level)'='maybe_quote_value(*p)';');
            break;
         case VF_ARRAY:
         case VF_HASHTAB:
         case VF_OBJECT:
            typeless vnotinit;
            vnotinit._makeempty();
            //if (_varformat(_varnextel(*p,vnotinit))==VF_NOTINIT) {
            if (p->_nextel(vnotinit)._isempty()) {
               // No initialized elements
               break;
            }
            _str tname = maketypename(*p);
            pname :=  'p'level'_'tname;
            pname = stranslate(pname, "_", ".");
            if (tname != '') {
               if (!objectvars._indexin(pname)) {
                  insert_line(indent:+tname' *'pname'=null;');
                  objectvars:[pname]=true;
               }
            } else {
               pname='p'level;
            }
            insert_line(indent:+pname'=&'varname:+makeindex(a,i,level)';');
            _insert_var_source(*p,pname,indent,level+1,objectvars);
            break;
         }
      }
      break;
   case VF_INT:
   case VF_WID:
   case VF_INT64:
   case VF_LSTR:
   case VF_PTR:
   case VF_FUNPTR:
      // Simple variable case
      insert_line(indent:+varname'='maybe_quote_value(a)';');
      break;
      /*
   case VF_OBJECT:
      for (i=0; i<a._length(); i++) {
         typeless p= &a._el(i);
         if (i._isempty()) {
            insert_line(indent:+varname'.'a._fieldname(i)'=null;');
            continue;
         }
         switch (p->_varformat()) {
         case VF_INT:
         case VF_LSTR:
            if (level<=1) {
               insert_line(indent:+varname'.'a._fieldname(i)'='maybe_quote_value(*p)';');
            } else {
               insert_line(indent'p'(level-1)'->'a._fieldname(i)'='maybe_quote_value(*p)';');
            }
            break;
         case VF_ARRAY:
         case VF_HASHTAB:
         case VF_OBJECT:
            typeless vnotinit;
            vnotinit._makeempty();
            //if (_varformat(_varnextel(*p,vnotinit))==VF_NOTINIT) {
            if (p->_nextel(vnotinit)._isempty()) {
               // No initialized elements
               break;
            }
            if (level<=1) {
               insert_line(indent'p'level'=&'varname'.'a._fieldname(i)';');
            } else {
               insert_line(indent'p'level'=&p'(level-1)'->'a._fieldname(i)';');
            }
            _insert_var_source(*p,'',indent,level+1);
            break;
         }
      }
      break;
      */
   }
}
static _str makeindex(var v, int i,int level)
{
   if (v._varformat()==VF_OBJECT) {
      fieldName := v._fieldname(i);
      if (fieldName!='') {
         // special case for stupid union in WORKSPACE_LIST
         if (fieldName=='u' && i==3) {
            if (v._getfield(i)._varformat()==VF_ARRAY) {
               fieldName='u.list';
            } else {
               fieldName='u.description';
            }
         }
         fieldName=stranslate(fieldName,'_','-');
         if (level<=1) {
            return '.'fieldName;
         } else {
            return '->'fieldName;
         }
      }
      if (level<=1) {
         return('['i']');
      } else {
         return('->['i']');
      }
   }
   if (v._varformat()==VF_ARRAY) {
      if (level<=1) {
         return('['i']');
      } else {
         return('->['i']');
      }
   }
   if (level<=1) {
      return(':['_quote(i)']');
   } else {
      return('->:['_quote(i)']');
   }
}
static _str maketypename(var v)
{
   if (v._varformat()==VF_OBJECT) {
      _str name=v._typename();
      _str fld0=v._fieldname(0);
      if (name!='' && name!='[]' && name!=':[]' && name!='null' && fld0!='') {
         return stranslate(name,'_','-');
      }
   }
   return '';
}
int _nocomment_search(_str string,_str options)
{
   return(search(string,'xcs,'options));
}

int _macfile_present(_str filename,_str extension)
{
   filename=strip(filename,'B','"');
   // Don't try to support VSLICKEXT environment variable
   if (!_file_eq(_macro_ext,'.e')) return(0);
   // Don't quote module here.  Symbol tables does not quote symbols.
   module := _strip_filename(filename,(extension=='')? 'P':'PE');
   if (_isUnix()) {
      // Convert libDLLNAME.so to DLLNAME.dll for a quick check.
      if (pos("lib", module) == 1) {
         module = substr(module, 4) :+ extension;
      } else {
         module :+= extension;
      }
   } else {
      module :+= extension;
   }
   int index;
   if (extension:==DLLEXT) {
      index=find_index(module,DLLMODULE_TYPE);
   } else {
      index=_find_module_index(filename);
   }
   return(index);
}
void _macfile_delete(_str filename,_str extension, bool doTagging=true)
{
   filename=strip(filename,'B','"');
   // Don't try to support VSLICKEXT environment variable
   if (!_file_eq(_macro_ext,'.e')) return;
   module := _strip_filename(filename,(extension=='')? 'P':'PE');
   module=_maybe_quote_filename(module:+extension);
   _str list=def_macfiles;
   def_macfiles='';
   for (;;) {
      _str word=parse_file(list,false);
      if (word=='') {
         break;
      }
      if (!_file_eq(_strip_filename(word,'P'),module)) {
          if (def_macfiles != '') {
             def_macfiles :+= " ";
          }
          def_macfiles :+= _maybe_quote_filename(word);
      } else {
         _config_modify_flags(CFGMODIFY_DEFVAR);
         if (_get_extension(word)=="ex") {
            word = substr(word, 1, length(word)-1);
         }
         if (doTagging) _UntagSlickCFile(word);
      }
   }
}
void _macfile_add(_str filename,_str extension,int alreadyPresent=0,bool supportMacro=false)
{
   // Make sure that the module has an absolute path
   // This will help us resolve it's path relative to the
   // configuration directory and the user's macro PATH
   filename=strip(filename,'B','"');
   filename = absolute(filename);

   if (!alreadyPresent) {
      // Remove this macro file to ensure it's not listed twice.
      // With a previously absolute file, this can happen.
      _macfile_delete(filename,_macro_ext'x',false);
   }

   // Now make the module relative to the configuration directory
   origFilename := filename;
   filename = relative(filename, _ConfigPath(), true);

   // Only allow one level of dots so that macro files
   // can be relative and be in the unversioned config directory.
   if (substr(filename,1,2)==".." && pos('..',filename,4)) {
      filename = relative(filename, _ConfigPath(), false);
   }

   // Or, if that doesn't work, try to make the module name
   // relative to the macro path
   if (_file_eq(filename, origFilename)) {
      slickCPath := get_env(_SLICKMACROS);
      while (slickCPath != "") {
         parse slickCPath with auto macroPath (PARSE_PATHSEP_RE),'r' slickCPath;
         macroPath=strip(macroPath,'B','"');
         _maybe_append_filesep(macroPath);
         filename = relative(origFilename, macroPath, false);
         if (!_file_eq(filename, origFilename)) {
            break;
         }
      }
   }

   if ((_file_eq(extension,'.e') || _file_eq(extension,'.ex')) && !supportMacro) {
      if (!_in_firstinit) {
         tfindex := 0;
         if(!_e_MaybeBuildTagFile(tfindex) ) {
            _MaybeTagSlickCFile(origFilename, tfindex);
         }
      }
   }

   // Don't try to support VSLICKEXT environment variable
   // say("_macfile_add: filename="filename" orig="origFilename);
   if (!_file_eq(_macro_ext,'.e')) return;
   if (alreadyPresent) return;
   module := _strip_filename(filename,(extension=='')? '':'E');
   module :+= extension;
   _str list=def_macfiles;
   for (;;) {
      _str word=parse_file(list,false);
      if (word=='') {
         break;
      }

      // check to see if the module is already in the list.  since some modules
      // may have full path information stored, it is safer to compare both
      // the module name and the full path than just the stripped name
      if (_file_eq(_strip_filename(word,'P'),module) || _file_eq(word, module)) {
         // This module is already here
         return;
      }
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if (def_macfiles != "") def_macfiles :+= " ";
   def_macfiles :+= _maybe_quote_filename(module);

}
/*
    Call this function when the cursor is at the first character of the
    definition of a procedure and which is usually NOT the name.
*/
static void _start_of_proc_comments()
{
   save_pos(auto p2);
   if (p_col!=1) {
      left();
   } else {
      up();_end_line();
   }
   //Search backward for first non-blank character
   status := search('[~ \t]','rh@-');
   if (!status && _in_comment()) {
      status=_clex_skip_blanks('-');
      if (status) {
         top();
      } else {
         right();
         // Search forward for beginning of line or [blank-chars]non-blank-char
         search('^|[ \t]*[~ \t]','rh@');
         _str before_nonblank = _expand_tabsc(1,p_col-1);
         if( before_nonblank!="" ) {
            // There is something else on this line besides comment/whitespace.
            // Probably a trailing comment stuck on the end of
            // this line.
            // Example: Selecting comments for proc()
            // --------------------------------------
            // void foo() {
            //    ...
            // } // end foo <-- do not include this comment
            // // Comment for proc.
            // void proc() {
            // ...
            // }
            // --------------------------------------
            down(); _begin_line();
         }
      }
      return;  // We found some comments and we may have found blanks and/or blank-lines
   }
   if (status) {
      //messageNwait('case4');
      top();
   } else {
      //messageNwait('case5');
      right();
      // Search forward for beginning of line or [blank-chars]non-blank-char
      search('^|[ \t]*[~ \t]','rh@');
   }
   // No comments found but we may have found blanks and/or blank-lines
}
static int c_select_proc_common(typeless p,int markid, SELECT_PROC_FLAGS options)
{
   _UpdateContext(true,true);
   this_context_id := tag_current_context();
   near_context_id := tag_nearest_context(p_RLine, SE_TAG_FILTER_ANYTHING&~SE_TAG_FILTER_STATEMENT, true);
   if (this_context_id != near_context_id) {
      _clex_skip_blanks('');
      this_context_id = tag_current_context();
   }
   if (this_context_id <= 0) {
      return STRING_NOT_FOUND_RC;
   }
   tag_get_context_browse_info(this_context_id, auto cm);

   p_RLine = cm.line_no;
   _GoToROffset(cm.seekpos);

   if (p_RLine >= 1) {
      _start_of_proc_comments();
   }

   _deselect(markid);
   _select_char(markid,translate(def_select_style,'N','I'));

   p_RLine = cm.end_line_no;
   _GoToROffset(cm.end_seekpos);
   right();
   _clex_skip_blanks('-');
   //show_selection(markid,1);
   return(0);
}
/**
 * Selects current function contents and (optionally) function
 * heading.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * @param count    reserved
 * @param markid   Can be '' for active selection
 * @param notQuiet show message box if not supported
 * @param options  select_proc options - specify
 *                 SELECT_PROC_NO_COMMENTS to not include
 *                 header comments in selection
 *
 * @return Returns 0 if successful.
 */
_command int select_proc(typeless count=0, int markid=-1, _str notQuiet='', SELECT_PROC_FLAGS options=def_select_proc_flags) name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if( markid<0 ) {
      markid=_duplicate_selection("");
   }
   index := _FindLanguageCallbackIndex('%s-select-proc',p_LangId);
   if ( index ) {
      _str old_scroll_style=_scroll_style();
      _scroll_style('c');
      status := call_index(count,markid,options,index);
      _scroll_style(old_scroll_style);
      return(status);
   }  else if (_istagging_supported()) {
      return(_select_proc(count,markid, options));
   }
   if (notQuiet=='') {
      _message_box('Select procedure not supported for files of this language.');
   }
   return(1);
}

int _OnUpdate_select_proc(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }

   if (!_FindLanguageCallbackIndex('%s-select-proc',p_LangId) && !_istagging_supported()) {
      return MF_GRAYED;
   }

   return MF_ENABLED;
}

/*
   This function is a generic select_proc.  It assumes that
   function headers can be selected with a line selection.
   It also assumes that there are no declarations between
   function definitions. To improve this function, write
   a language specific function which finds the end a function.
*/
static int _select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   save_pos(auto orig_pos);

   status := 0;
   begin_tag_successful := false;
   if (tag_lang_has_list_tags(p_LangId)) {
      _UpdateContext(true);
      context_id := tag_current_context();
      if (context_id <= 0) {
         _clex_skip_blanks();
         context_id = tag_current_context();
      }
      if (context_id > 0) {
         begin_tag_successful = (begin_tag() >= 0);
         // some language can have a member variable declared smack in the
         // middle of a function.
         if (begin_tag_successful) {
            tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto tag_type);
            if (tag_tree_type_is_data(tag_type)) {
               tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
               if (context_id > 0) {
                  tag_get_detail2(VS_TAGDETAIL_context_start_seekpos, context_id, auto seekpos);
                  _GoToROffset(seekpos);
               }
            }
         }
      }
   }

   if (!begin_tag_successful) {
      // We could already be sitting on the function cursor down
      // to try to hit this one.
      _clex_skip_blanks();
      down();
      status = prev_tag('q',1);
      if (status) {
         status=next_tag('q',1);
         if (status) {
            restore_pos(orig_pos);
            return(-1);
         }
      }
   }

   _deselect(markid);
   save_pos(auto start_tag_pos);
   _begin_line();
   up();
   if (!(options & SELECT_PROC_NO_COMMENTS) && _in_comment()) {
      status=_clex_skip_blanks('-');
      if (!status) {
         down();
      }
   } else {
      down();
   }
   _select_line(markid,translate(def_select_style,'N','I'));
   restore_pos(start_tag_pos);
   // Here it would be better to search for the end of the
   // function instead of the beginning of the next function
   // because we may pick up declarations we don't want.
   if (begin_tag_successful) {
      status = end_tag();
      if (status) bottom();
   } else {
      status = next_tag('q',1);
      if (status) {
         bottom();
      } else {
         up();
         _clex_skip_blanks('-');
      }
   }

   _select_line(markid,translate(def_select_style,'N','I'));
   return(0);
}
int cs_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count, markid, options);
}
int java_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count, markid, options);
}
int js_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count, markid, options);
}
int cfscript_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count, markid, options);
}
int phpscript_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count, markid, options);
}
/*
    Note that this proc search function does not support Slick-C&reg; function
    definitions which do not start in column 1 (Same limit as find-proc).  The
    work around for this is to modify cparse.dll to support compiling Slick-C&reg;
    source.  This will require support the following extensions:


    Lexer additions.
       *  \ddd
       *  Nested /* */ comments
       *  Single quoted strings like REXX

       _commmand  [type-list] [name,name,string] (...)  [name_info(...)]
       [type-list] name. {string[-string]|name}[, another] (...)


*/
int e_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   return c_select_proc(count,markid,options);
}
int c_select_proc(typeless count, int markid, SELECT_PROC_FLAGS options)
{
   if (!isinteger(count)) count=1;
   typeless orig_offset=_nrseek();
   hit_bottom := false;
   save_pos(auto p);
   i := status := 0;
   for (i=1;i<=count;++i) {
      status=next_proc('q');
      if (status) {
         hit_bottom=true;
         bottom();
         break;
      }
   }
   // Now find the end of the previous procedure.
   status=c_select_proc_common(p,markid,options);
   if (status) {
      return(status);
   }
   // IF we were after the close brace
   if (!hit_bottom && _nrseek()<=orig_offset) {
      // We selected the wrong procedure.  Select the next procedure
      status=next_proc('q');
      status=next_proc('q');
      hit_bottom=true;
      if (status) {
         bottom();
      }
      // Now find the end of the previous procedure.
      status=c_select_proc_common(p,markid, options);
      if (status) {
         return(status);
      }
   }
   _select_char(markid,translate(def_select_style,'N','I'));
   // Now try to select the new line character
   int start_col, end_col;
   typeless junk;
   _get_selinfo(start_col,end_col,junk,markid);
   if (start_col==1) {
      _skip_blanks_or_find_BOL(markid);
   }
   return(0);
}
static int _skip_blanks_or_find_BOL(int markid)
{
   search_options := "@r";
   for (;;) {
      // search backward for non-blank character
      //status=search('[~ \t]|$',search_options);
      status := _TruncSearchLine('[~ \t]|$','r');
      if (status) return(1);
      if (!match_length()) {
         right();
#if 1
            _select_type(markid,'T','LINE');
#else
            if (!down()) _begin_line();
#endif
         return(0);
      }
      if (_in_comment()) {
         old_linenum := p_line;
         save_pos(auto p);
         status=_clex_find(COMMENT_CLEXFLAG,'n');
         if (status) return(1);
         if (p_line!=old_linenum) {
            restore_pos(p);
#if 1
            _select_type(markid,'T','LINE');
#else
            search('$','@rh');right();
            if (!down()) _begin_line();
#endif
            return(0);
         }
         continue;
      }
      return(0);
   }
}

defeventtab slick_keys;
def  ' '= slick_space;
def  '#'= c_pound;
def  '('= slick_paren;
def  '*'= c_asterisk;
def  '.'= auto_codehelp_key;
def  '/'= c_slash;
def  '"'= c_dquote;
def  ';'= slick_semicolon;
def  '>'= auto_codehelp_key;
def  '<'= auto_functionhelp_key;
def  '@'= c_atsign;
def  '\'= c_backslash;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  'ENTER'= slick_enter;
def  'TAB'= smarttab;

defeventtab ext_keys;
def ' '=ext_space;
def '('=auto_functionhelp_key;

/* This command is bound to the SPACE BAR key.  It looks at the text around */
/* the cursor to decide whether insert an expanded template.  If it does not, */
/* the root key table definition for the SPACE BAR key is called. */
_command void ext_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() || !doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
      ext_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' ');
      }
   } else if (_argument=='') {
      _undo('S');
   }

}
static _str space_words2[];

/* Returns non-zero number if fall through to space bar key required */
int ext_expand_space()
{
   /* Put first word of line in lower case into word variable. */
   get_line(auto line);
   line=strip(line,'T');
   orig_word := lowcase(strip(line));
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   aliasfilename := "";
   _str word=min_abbrev2(orig_word,space_words2,'',aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

   /* Insert the appropriate template based on the key word. */
   //line=substr(line,1,length(line)-length(orig_word)):+word
   //width=text_col(line,length(line)-length(word)+1,'i')-1
   return(1);
}

/*
   WARNING:  These lexer names are case senstive.
   If some one changes the case of lexer names in vslick.vlx, we will get
   burned.
*/
_str _EmbeddedLexer2LangId:[]= _reinit {
   'ANSI-SQL'=> 'ansisql',
   'asm'=>'masm',
   'asm390'=> 'asm390',
   'AWK'=> 'awk',                   // djb added 05/30/2002
   'C#'=> 'cs',
   'CFML'=> 'cfml',                 // djb added 05/30/2002
   'Cg'=> 'cg',
   'CFScript'=> 'cfscript',
   'CICS' => 'cics',
   'cobol'=> 'cob',
   'cpp'=> 'c',
   'C++'=> 'c',
   'CSharp'=> 'cs',
   'DB2'=> 'db2',
   'HTML'=> 'html',
   'IDL'=> 'idl',                   // djb added 05/30/2002
   'Java'=> 'java',
   'JavaScript'=> 'js',
   'JCL'=> 'jcl',                   // djb added 05/30/2002
   'Perl'=> 'pl',
   'PHP' => 'phpscript',
   'PL/SQL'=> 'plsql',
   'Progress 4GL'=> 'p4gl',
   'Python'=> 'py',
   'Object REXX' => 'rexx',         // aer added 05/31/2002
   'REXX' => 'rexx',                // djb added 05/30/2002
   'Ruby'=> 'ruby',                 // djb added 12/22/2005
   's'=>'unixasm',
   'SAS' => 'sas',                  // djb added 05/30/2002
   'SQL Server'=> 'sqlserver',
   'VBScript'=> 'vbs',
   'VHDL'=> 'vhd',
   'Visual Basic'=> 'bas',
   'XML'=> 'xml',                   // djb added 05/30/2002
   'XMLSCHEMA'=> 'xsd',             // djb added 10/17/2002
   'XMLDOC'=> 'xmldoc',             // dno added 10/3/2003
   'XMLDTD'=> 'dtd'                 // djb added 05/30/2002
};

void NoEmbeddedLanguageProcessing(_str key)
{
   switch (key) {
   /*case ':':
   case ' ':
   case '{':
   case '}':
      keyin(key);
      return;*/
   case ENTER:
      call_root_key(ENTER);
      break;
   case TAB:
      call_root_key(TAB);
      break;
   default:
      if (length(key):==1) {
         keyin(key);
      }
   }
}
/**
 * If the cursor is in an embedded language section switch to the language 
 * mode of the embedded code. 
 *  
 * @param orig_values   (ref) stores the original
 *                      language-specific settings for the
 *                      current file.  This will be used to
 *                      restore the language state when
 *                      {@link _EmbeddedEnd} is called.
 * @param key           name for new key table (no longer used)
 *  
 * @return 
 *    <li>
 *       Returns 0 if there is no embedded language
 *    <li>
 *       Return 1,  indicates that the mode has been switched to the
 *       embedded language.  Caller must call _EmbeddedEnd(orig_values)
 *    <li>
 *       Returns 2 to indicate that there is embedded language code, but in
 *       comment/in string like default processing should be performed.
 *    <li>
 *       Returns 3 if mode name for the embedded code is the same.
 *  
 * @see _EmbeddedEnd() 
 * @see _GetEmbeddedLangId() 
 * @see p_LangId 
 * @see p_mode_name 
 *  
 * @categories Tagging_Functions
 */
int _EmbeddedStart(typeless &orig_values,_str key="")
{
   orig_values._makeempty();
   //messageNwait('h1');
   _str EmbeddedLexerName=p_EmbeddedLexerName;
   /*if (p_LangId=='html' && p_EmbeddedLexerName!='Java') {
      _StackDump(0,1);
   } */
   if (EmbeddedLexerName=='') {
      // before giving up, check for border case at end of
      // embedded code, for example <% ... <cursor here>%>
      // If the cursor is right before the %, we are technically
      // still in embedded language mode
      _save_pos2(auto p);
      left();
      EmbeddedLexerName=p_EmbeddedLexerName;
      _restore_pos2(p);
      if (EmbeddedLexerName=='') {
         // No embedded language here
         return(0);
      }
   }
   //say("_EmbeddedStart: name="EmbeddedLexerName);
   lang := '';
   if (EmbeddedLexerName:!='') {
      lang = _LexerName2LangId(EmbeddedLexerName);
      if (lang == '') { 
         if (_EmbeddedLexer2LangId._indexin(EmbeddedLexerName)) {
            lang=_EmbeddedLexer2LangId:[EmbeddedLexerName];
         }
      }
      // There is no support for this embedded language
      // However, there may be color coding.
      if (lang == null || lang == '') {
         return(2);
      }
   }
   // are we already in embedded mode?
   if (p_embedded) {
      return(0);
   }
   // Convert EmbeddedLexerName to actual language
   //_str buf_name='.'lang;
   //int setup_index=0;
   //check_and_load_support(lang,setup_index,buf_name);

   VS_LANGUAGE_OPTIONS langOptions;
   _GetDefaultLanguageOptions(lang, langOptions);
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      _LangOptionsApplyOverrides(langOptions,lang,p_buf_name);
   }
#if 0
   // For now, let's not call _GetLanguageSetupOptions 
   // since this is faster and _EmbeddedStart needs to be fast.
   _str mode_name, tabs, margins, keytab_name;
   typeless word_wrap_style, indent_with_tabs, show_tabs;
   typeless indent_style, word_chars, lexer_name, color_flags;
   typeless line_numbers_len, TruncateLength;
   parse name_info(setup_index) with 'MN=' mode_name ','\
      'TABS=' tabs ',' 'MA=' margins ',' 'KEYTAB=' keytab_name ','\
      'WW='word_wrap_style ',' 'IWT='indent_with_tabs ','\
      'ST='show_tabs ',' 'IN='indent_style ','\
      'WC='word_chars',' 'LN='lexer_name',' 'CF='color_flags','\
      'LNL='line_numbers_len',' 'TL='TruncateLength',';
#endif

   // IF we are already in this mode. (ex Embedded Perl in Perl)
   if (_ModenameEQ(_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_MODE_NAME),p_mode_name)) {
      //messageNwait('mode name same')
      return(3);
   }
   typeless syntax_indent=0, tag_case=0, attrib_case=0, sword_case=0, hex_val=0, adFormFlags=0;
   typeless kwCase=0, beStyle=0, indentCase=0, padParens=0, noSpaceBefore=0, pointerStyle=0, fBrace=0;

   // possibly overwrite the settings here in one of those ca-razy do-while-false things
   loaded := false;
   do {
      if (g_AdFormEmbeddedSettings._isempty()) break;
      if (!g_AdFormEmbeddedSettings._indexin(p_buf_id)) break;
      if (g_AdFormEmbeddedSettings:[p_buf_id] == null) break;

      // this should be a hashtable of AdaptiveFormattingSetting structs, keyed by extension
      AdaptiveFormattingSettings * afs = g_AdFormEmbeddedSettings:[p_buf_id]._indexin(lang);
      if (!afs) break;
//    _dump_var(g_AdFormEmbeddedSettings:[p_buf_id]:[extension]);
      // make sure we don't have something corrupted here
      if (afs -> BufferName != p_buf_name) {
         afs = null;
         g_AdFormEmbeddedSettings:[p_buf_id]._deleteel(lang);
         break;
      } else {
         loaded = true;
         adFormFlags = afs -> Flags;

         // we load everything - this would give us old settings, except that when an 
         // extension
         syntax_indent = afs -> SyntaxIndent;
         tag_case = afs -> TagCasing;
         sword_case = afs -> ValueCasing;
         attrib_case = afs -> AttributeCasing;
         hex_val = afs -> HexValueCasing;
         kwCase = afs -> KeywordCasing;
         beStyle = afs -> BeginEndStyle;
         indentCase = afs -> IndentCaseFromSwitch;
         padParens = afs -> PadParens;
         noSpaceBefore = afs -> NoSpaceBeforeParens;

         // we only load the next two for non-html based languages
         if (_LanguageInheritsFrom('html',lang) || _LanguageInheritsFrom('xml',lang)) {
            pointerStyle=0;
            fBrace=0;
            break;
         }

         // we can't get these out of adaptive formatting...yet
         typeless bs=_LangOptionsGetPropertyInt32(langOptions,LOI_POINTER_STYLE,0);
         if (isinteger(pointerStyle)) {
            // pointer style
            if (bs & VS_C_OPTIONS_SPACE_AFTER_POINTER) {
               pointerStyle=VS_C_OPTIONS_SPACE_AFTER_POINTER;
            } else if (bs & VS_C_OPTIONS_SPACE_SURROUNDS_POINTER) {
               pointerStyle=VS_C_OPTIONS_SPACE_SURROUNDS_POINTER;
            } else {
               pointerStyle=0;
            }
            bs=_LangOptionsGetPropertyInt32(langOptions,LOI_FUNCTION_BEGIN_ON_NEW_LINE,0);
            
            // function brace on new line
            if (bs/* & VS_C_OPTIONS_BRACE_INSERT_FUNCTION_FLAG*/) {
               fBrace=1;
            } else {
               fBrace=0;
            }
         } else {
            pointerStyle=0;
            fBrace=0;
         }
      }
   } while (false);
   syntax_indent=_LangOptionsGetPropertyInt32(langOptions,LOI_SYNTAX_INDENT,0);
   // get the standard settings
   if (!loaded) {
      adFormFlags = adaptive_format_get_buffer_flags(lang);

      // these things may get done - if the notFlags 
      if (_LanguageInheritsFrom('html',lang) || _LanguageInheritsFrom('xml',lang)) {
         //parse name_info(options_index) with syntax_indent . tag_case attrib_case sword_case . . . . . . hex_val .;
         //syntax_indent=_LangOptionsGetPropertyInt32(lang,);
         tag_case=_LangOptionsGetPropertyInt32(langOptions,LOI_TAG_CASE,0);
         attrib_case= _LangOptionsGetPropertyInt32(langOptions,LOI_ATTRIBUTE_CASE,0);
         sword_case=_LangOptionsGetPropertyInt32(langOptions,LOI_WORD_VALUE_CASE,0);
         hex_val=_LangOptionsGetPropertyInt32(langOptions,LOI_HEX_VALUE_CASE,0);

         // these aren't used in these languages
         kwCase = 0;
         beStyle = 0;
         indentCase = 0;
         padParens = 0;
         noSpaceBefore = 0;
         pointerStyle = 0;
         fBrace = 0;
      } else {

         kwCase= _LangOptionsGetPropertyInt32(langOptions,LOI_KEYWORD_CASE,0);

         //parse name_info(options_index) with syntax_indent . . kwCase beStyle . . indentCase .;
         //if (indentCase == '') indentCase = 0;
         //if (kwCase == '') kwCase = 0;
         //if (beStyle == '') beStyle = 0;

         // pad parens
         //beStyle=_LangPadParens();
         if (_LangOptionsGetPropertyInt32(langOptions,LOI_PAD_PARENS,0)  /*_LangGetPadParens(lang)*/ /*beStyle & VS_C_OPTIONS_INSERT_PADDING_BETWEEN_PARENS*/) {
            padParens=1;
         } else {
            padParens=0;
         }
   
         // space before paren
         if (_LangGetPropertyInt32(lang,LOI_NO_SPACE_BEFORE_PAREN) /*beStyle & VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN*/) {
            noSpaceBefore=1;
         } else {
            noSpaceBefore=0;
         }
   
         // pointer style
         beStyle=_LangOptionsGetPropertyInt32(langOptions,LOI_POINTER_STYLE,0);// _LangGetPointerStyle(lang);
         if (beStyle & VS_C_OPTIONS_SPACE_AFTER_POINTER) {
            pointerStyle=VS_C_OPTIONS_SPACE_AFTER_POINTER;
         } else if (beStyle & VS_C_OPTIONS_SPACE_SURROUNDS_POINTER) {
            pointerStyle=VS_C_OPTIONS_SPACE_SURROUNDS_POINTER;
         } else {
            pointerStyle=0;
         }
   
         // function brace on new line
         if (_LangGetPropertyInt32(lang,LOI_FUNCTION_BEGIN_ON_NEW_LINE) /*beStyle & VS_C_OPTIONS_BRACE_INSERT_FUNCTION_FLAG*/) {
            fBrace=1;
         } else {
            fBrace=0;
         }
         beStyle=_LangOptionsGetPropertyInt32(langOptions,LOI_BEGIN_END_STYLE,0); //_LangGetBeginEndStyle(lang);
         // begin/end style
         if (beStyle & VS_C_OPTIONS_STYLE1_FLAG) {
            beStyle=VS_C_OPTIONS_STYLE1_FLAG;
         } else if (beStyle & VS_C_OPTIONS_STYLE2_FLAG) {
            beStyle=VS_C_OPTIONS_STYLE2_FLAG;
         } else {
            beStyle=0;
         }
      
         // we don't use these things - HTML based languages only
         tag_case = 0;
         attrib_case = 0;
         sword_case = 0;
         hex_val = 0;
      }
   }

   keytab_name:=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_EVENTTAB_NAME);
   int mode_eventtab=_eventtab_get_mode_keys(keytab_name);
#if 0
   //messageNwait('h4 mode_eventtab='mode_eventtab' mode_name='mode_name' keytab_name='keytab_name);
   if (!mode_eventtab || keytab_name=='' || translate(keytab_name,'_','-'):=='default_keys' ||
      (key:!='' && !eventtab_index(mode_eventtab,mode_eventtab,event2index(key)))
      ) {
      return(2);
   }
#endif
   if (!mode_eventtab) {
      mode_eventtab=_default_keys;
   }
   //messageNwait('YES');
   orig_values[0]=p_mode_name;
   p_mode_name=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_MODE_NAME);

   orig_values[1]=p_mode_eventtab;
   p_mode_eventtab=mode_eventtab;

   orig_values[2]=0;//p_index;
   //p_index=options_index;

   //if ( !isinteger(indent_style)) {
   //   indent_style=INDENT_SMART;
   //}
   orig_values[3]=p_indent_style;
   p_indent_style=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_INDENT_STYLE,INDENT_AUTO);

   orig_values[4]=p_SyntaxIndent;
   if (isinteger(syntax_indent)) {
      p_SyntaxIndent=syntax_indent;
   } else {
      p_SyntaxIndent=0;
   }
   orig_values[5]=p_LangId;
   p_LangId=lang;

   orig_values[7]=p_indent_with_tabs;
   //if (isinteger(indent_with_tabs)) {
   //   p_indent_with_tabs=indent_with_tabs;
   //}
   p_indent_with_tabs=(_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_INDENT_WITH_TABS,0) != 0);

   orig_values[8]=p_margins;
   margins:=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_MARGINS);
   if (margins!="") p_margins=margins;

   orig_values[9]=p_word_wrap_style;
   p_word_wrap_style=_LangOptionsGetPropertyInt32(langOptions,VSLANGPROPNAME_WORD_WRAP_FLAGS,0);

   /*orig_values[10]=p_tabs;
   // If the outer tabs
   if (tabs!='') {
      orig_tabs=p_tabs;
      // This does not work because we will be lost for lines that already have tabs
      p_tabs=tabs;
      if (orig_values[10]!=p_tabs) {
         //say('special case orig='orig_values[10]' new='p_tabs);
         // Don't indent with tabs because display routines only use outer most tab settings
         p_indent_with_tabs=false;
      }
   } */

   orig_values[11]=p_keyword_casing;
   p_keyword_casing=kwCase;

   orig_values[12]=p_begin_end_style;
   p_begin_end_style=beStyle;

   orig_values[13]=p_indent_case_from_switch;
   p_indent_case_from_switch=indentCase;

   orig_values[14]=p_pad_parens;
   p_pad_parens=padParens;

   orig_values[15]=p_no_space_before_paren;
   p_no_space_before_paren=noSpaceBefore;

   orig_values[16]=p_pointer_style;
   p_pointer_style=pointerStyle;

   orig_values[17]=p_function_brace_on_new_line;
   p_function_brace_on_new_line=fBrace;

   orig_values[18]=p_tag_casing;
   p_tag_casing=tag_case;

   orig_values[19]=p_attribute_casing;
   p_attribute_casing=attrib_case;

   orig_values[20]=p_value_casing;
   p_value_casing=sword_case;

   orig_values[21]=p_hex_value_casing;
   p_hex_value_casing=hex_val;

   orig_values[22]=p_adaptive_formatting_flags;
   p_adaptive_formatting_flags = adFormFlags;

   orig_values[23]=p_word_chars;
   p_word_chars = _LangOptionsGetProperty(langOptions,VSLANGPROPNAME_WORD_CHARS);

   p_embedded=VSEMBEDDED_ONLY;
   p_embedded_orig_values=orig_values;
   return(1);

}
void _EmbeddedSave(typeless &orig_values)
{
   orig_values[0]=p_mode_name;
   orig_values[1]=p_mode_eventtab;
   orig_values[2]=0;//p_index;
   orig_values[3]=p_indent_style;
   orig_values[4]=p_SyntaxIndent;
   orig_values[5]=p_LangId;
   orig_values[7]=p_indent_with_tabs;
   orig_values[8]=p_margins;
   orig_values[9]=p_word_wrap_style;
   //orig_values[10]=p_tabs;
   orig_values[10]=p_embedded;
   orig_values[11]=p_keyword_casing;
   orig_values[12]=p_begin_end_style;
   orig_values[13]=p_indent_case_from_switch;
   orig_values[14]=p_pad_parens;
   orig_values[15]=p_no_space_before_paren;
   orig_values[16]=p_pointer_style;
   orig_values[17]=p_function_brace_on_new_line;
   orig_values[18]=p_tag_casing;
   orig_values[19]=p_attribute_casing;
   orig_values[20]=p_value_casing;
   orig_values[21]=p_hex_value_casing;
   orig_values[22]=p_adaptive_formatting_flags;
   orig_values[23]=p_word_chars;
}
void _EmbeddedRestore(typeless &orig_values)
{
   p_mode_name=orig_values[0];
   p_mode_eventtab=orig_values[1];
   //p_index=orig_values[2];
   p_indent_style=orig_values[3];
   p_SyntaxIndent=orig_values[4];
   p_LangId=orig_values[5];
   p_indent_with_tabs=orig_values[7];
   p_margins=orig_values[8];
   p_word_wrap_style=orig_values[9];
   //p_tabs=orig_values[10];
   p_embedded=orig_values[10];
   p_keyword_casing=orig_values[11];
   p_begin_end_style=orig_values[12];
   p_indent_case_from_switch=orig_values[13];
   p_pad_parens=orig_values[14];
   p_no_space_before_paren=orig_values[15];
   p_pointer_style=orig_values[16];
   p_function_brace_on_new_line=orig_values[17];
   p_tag_casing=orig_values[18];
   p_attribute_casing=orig_values[19];
   p_value_casing=orig_values[20];
   p_hex_value_casing=orig_values[21];
   p_adaptive_formatting_flags=orig_values[22];
   p_word_chars=orig_values[23];
}
/**
 * Pop back out of embedded language mode into the previous language mode. 
 * 
 * @param orig_values   Language settings to restore
 * 
 * @categories Tagging_Functions
 */
void _EmbeddedEnd(typeless orig_values)
{
   if (orig_values._isempty()) {
      return;
   }

   _SaveEmbeddedAdaptiveFormattingSettings();

   p_mode_name=orig_values[0];
   p_mode_eventtab=orig_values[1];
   //p_index=orig_values[2];
   p_indent_style=orig_values[3];
   p_SyntaxIndent=orig_values[4];
   p_LangId=orig_values[5];
   //p_tabs=orig_values[6];
   p_indent_with_tabs=orig_values[7];
   p_margins=orig_values[8];
   p_word_wrap_style=orig_values[9];
   //p_tabs=orig_values[10];
   p_embedded=VSEMBEDDED_BOTH;
   p_keyword_casing=orig_values[11];
   p_begin_end_style=orig_values[12];
   p_indent_case_from_switch=orig_values[13];
   p_pad_parens=orig_values[14];
   p_no_space_before_paren=orig_values[15];
   p_pointer_style=orig_values[16];
   p_function_brace_on_new_line=orig_values[17];
   p_tag_casing=orig_values[18];
   p_attribute_casing=orig_values[19];
   p_value_casing=orig_values[20];
   p_hex_value_casing=orig_values[21];
   p_adaptive_formatting_flags=orig_values[22];
   p_word_chars=orig_values[23];
}

void _SaveEmbeddedAdaptiveFormattingSettings()
{
   _str lang = null;
   if (_EmbeddedLexer2LangId._indexin(p_EmbeddedLexerName)) {
      lang = _EmbeddedLexer2LangId:[p_EmbeddedLexerName];
   }
   if (lang != null && lang != '') {
   
      // save adaptive formatting for this extension
      AdaptiveFormattingSettings afs;
      prevFlags := 0;
      if (g_AdFormEmbeddedSettings._indexin(p_buf_id)) {
         if (g_AdFormEmbeddedSettings:[p_buf_id]._indexin(lang)) {
            afs = g_AdFormEmbeddedSettings:[p_buf_id]:[lang];
            prevFlags = afs.Flags;
         }
      }

      // we want to overwrite in two situations:
      // 1:  that we found the setting in this run (p_adaptive_formatting_flags & AFF_WHATEVER == true)
      // 2:  that we hadn't found it previously (prevFlags & AFF_WHATEVER == false)
      // case 2 will insert the default setting, which is groovalicious.
      if ((p_adaptive_formatting_flags & AFF_KEYWORD_CASING) || !(prevFlags & AFF_KEYWORD_CASING)) {
         afs.KeywordCasing = p_keyword_casing;
      }
      if ((p_adaptive_formatting_flags & AFF_BEGIN_END_STYLE) || !(prevFlags & AFF_BEGIN_END_STYLE)) {
         afs.BeginEndStyle = p_begin_end_style;
      }
      if ((p_adaptive_formatting_flags & AFF_INDENT_CASE) || !(prevFlags & AFF_INDENT_CASE)) {
         afs.IndentCaseFromSwitch = (int)p_indent_case_from_switch;
      }
      if ((p_adaptive_formatting_flags & AFF_PAD_PARENS) || !(prevFlags & AFF_PAD_PARENS)) {
         afs.PadParens = (int)p_pad_parens;
      }
      if ((p_adaptive_formatting_flags & AFF_NO_SPACE_BEFORE_PAREN) || !(prevFlags & AFF_NO_SPACE_BEFORE_PAREN)) {
         afs.NoSpaceBeforeParens = (int)p_no_space_before_paren;
      }
      if ((p_adaptive_formatting_flags & AFF_TAG_CASING) || !(prevFlags & AFF_TAG_CASING)) {
         afs.TagCasing = p_tag_casing;
      }
      if ((p_adaptive_formatting_flags & AFF_ATTRIBUTE_CASING) || !(prevFlags & AFF_ATTRIBUTE_CASING)) {
         afs.AttributeCasing = p_attribute_casing;
      } 
      if ((p_adaptive_formatting_flags & AFF_VALUE_CASING) || !(prevFlags & AFF_VALUE_CASING)) {
         afs.ValueCasing = p_value_casing;
      }
      if ((p_adaptive_formatting_flags & AFF_HEX_VALUE_CASING) || !(prevFlags & AFF_HEX_VALUE_CASING)) {
         afs.HexValueCasing = p_hex_value_casing;
      }
      if ((p_adaptive_formatting_flags & AFF_SYNTAX_INDENT) || !(prevFlags & AFF_SYNTAX_INDENT)) {
         afs.SyntaxIndent = p_SyntaxIndent;
      }
      if ((p_adaptive_formatting_flags & AFF_INDENT_WITH_TABS) || !(prevFlags & AFF_INDENT_WITH_TABS)) {
         afs.IndentWithTabs = (int)p_indent_with_tabs;
      }

      afs.BufferName = p_buf_name;

      if (afs.Flags != null) {
         afs.Flags |= p_adaptive_formatting_flags;
      } else {
         afs.Flags = p_adaptive_formatting_flags;
      }
   
      g_AdFormEmbeddedSettings:[p_buf_id]:[lang] = afs;
   }
}
/*
   Returns 1 if all processing for this key was completed.
   Otherwise 0 is returned, which indicates the caller
   needs to process this key.
*/
int _EmbeddedLanguageKey(_str key)
{
   typeless orig_values;
   switch(_EmbeddedStart(orig_values,key)) {
   case 2:
      NoEmbeddedLanguageProcessing(key);
      return(1); // Processing done for this key
   case 0:
   case 3:
      return(0); // Caller needs to process this key
   }
   call_key(key, "\1", "L");
   _EmbeddedEnd(orig_values);
   return(1); // Processing done for this key
}

_command void embedded_key() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_ICON|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(last_event());
      //NoEmbeddedLanguageProcessing(last_event());
      return;
   }
   _str key=last_event();
   if(_EmbeddedLanguageKey(key)) return;
   if (_LanguageInheritsFrom('html') && def_keys=='gnuemacs-keys') {
      switch (key) {
      case TAB:
         //gnu_html_tab();
         move_text_tab();
         return;
      }
   } else if (_LanguageInheritsFrom('pl')) {
      switch (key) {
      case '>':
      case '.':
         perl_key();
         return;
      }
   }
   NoEmbeddedLanguageProcessing(key);
}

/**
 * Generic function for doing a proc-search only within embedded code.
 * Ignores any "outer" proc search for this language.
 *
 * @param pfnouter_proc_search    function pointer containing outer
 *                                (not the embedded language) proc-search
 * @param proc_name               (reference) encoded tag found
 * @param find_first              Find first instance or next instance?
 *
 * @return 0 on success, non-zero on error or end of file
 */
int _EmbeddedOnlyProcSearch(_str &proc_name,int find_first,_str unused_ext='',
                            _str start_seekpos='', _str end_seekpos='')
{
   return _EmbeddedProcSearch(0,proc_name,find_first,unused_ext,start_seekpos,end_seekpos);
}
/**
 * Generic function for doing a proc-search within embedded code.
 *
 * @param pfnouter_proc_search    function pointer containing outer
 *                                (not the embedded language) proc-search
 * @param proc_name               (reference) encoded tag found
 * @param find_first              Find first instance or next instance?
 *
 * @return 0 on success, non-zero on error or end of file
 */
int _EmbeddedProcSearch(typeless pfnouter_proc_search,_str &proc_name,int find_first,
                        _str unused_ext='', _str start_seekpos='', _str end_seekpos='')
{
   // function pointer containing outer proc-search function
   static typeless gpfnouter_proc_search;
   // function pointer containing current proc-search function
   static typeless gpfncur_proc_search;
   // function pointer containing current list-tags function
   static typeless gpfncur_list_tags;
   // list of tags found by list-tags
   static VS_TAG_BROWSE_INFO galist_tags_found[];
   // current item in list of tags found by list tags
   static int  gilist_tags_item;
   // ending seek position (for embedded search)
   static long gend_seekpos;
   // original proc name, as passed in during when find_first==1
   static _str gorig_proc_name;
   // are we calling _EmbeddedProcSearch() recursively?
   static bool grecursion;
   // should we perform proc-search in this loop?
   static bool gdo_search;

   // make sure that seek positions are initialized properly
   long l_start_seekpos = isinteger(start_seekpos) ? (long)start_seekpos : 0;
   long l_end_seekpos = isinteger(end_seekpos) ? (long)end_seekpos : 0;

   // If embedded proc is called recursively, bail out or just call the
   // "outer" proc search function.  This could happen, for example if you
   // had Perl embedded in a here-document in Perl.
   if (grecursion) {
      if (!pfnouter_proc_search) {
         return(1);
      }
      return((*pfnouter_proc_search)(proc_name,find_first,unused_ext,l_start_seekpos,l_end_seekpos));
   }
   grecursion=true;

   // If we are doing a find-first, set up the statics so that this
   // function can work correctly the next time it is called (for find-next).
   first_time := false;
   if (find_first) {
      gpfnouter_proc_search=pfnouter_proc_search;
      gpfncur_proc_search=gpfnouter_proc_search;
      gpfncur_list_tags=0;
      galist_tags_found._makeempty();
      gilist_tags_item=0;
      gend_seekpos=(int)l_end_seekpos;
      gorig_proc_name=proc_name;
      gdo_search=false;
      first_time=true;
      if (gend_seekpos>0) {
         gend_seekpos--;
      }
   }

   // main proc search loop
   for (;;) {
      // debug message
      //messageNwait('do='gdo_search' e='gend_linenum' h1 gpfncur_proc_search='gpfncur_proc_search);
      //say('do='gdo_search' e='gend_seekpos' h1 gpfncur_proc_search='gpfncur_proc_search);

      // Doing proc search or looking for first embedded context?
      status := 1;
      if (gdo_search) {
         // do we have a proc search for the current language?
         // If so, call it, otherwise, pretend it found nothing
         if (gilist_tags_item < galist_tags_found._length()) {
            auto cm = galist_tags_found[gilist_tags_item++];
            proc_name = tag_compose_tag_browse_info(cm);
            _GoToROffset(cm.seekpos);
            _end_line();
            status=0;
         } else if (gpfncur_list_tags) {
            typeless orig_values;
            embedded_status := _EmbeddedStart(orig_values);
            proc_name=gorig_proc_name;
            if (find_first) {
               l_start_seekpos=_QROffset();
            }
            // OK, now defer to list tags function
            tag_lock_context();
            tag_push_context();
            //say("_EmbeddedProcSearch: EMBEDDED PROC SEARCH");
            //tag_clear_context();
            status=(*gpfncur_list_tags)(0, "", "cg", VSLTF_SET_TAG_CONTEXT, 0, 0, l_start_seekpos, gend_seekpos);
            n := tag_get_num_of_context();
            galist_tags_found._makeempty();
            for (i:=1; i<=n; i++) {
               tag_get_context_info(i, auto cm);
               galist_tags_found[i-1] = cm;
            }
            gilist_tags_item=0;
            gpfncur_list_tags=0;
            gpfncur_proc_search=0;
            tag_pop_context();
            tag_unlock_context();
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
            if (n <= 0) {
               _GoToROffset(gend_seekpos);
            } else {
               continue;
            }
         } else if (gpfncur_proc_search) {
            typeless orig_values;
            embedded_status := _EmbeddedStart(orig_values);
            proc_name=gorig_proc_name;
            if (find_first) {
               l_start_seekpos=_QROffset();
            }
            // allocate selection on range to search
            int orig_mark=_duplicate_selection('');
            int mark_id=select_range(l_start_seekpos,gend_seekpos);
            // OK, now defer to proc search function
            status=(*gpfncur_proc_search)(proc_name,find_first,p_LangId,
                                          l_start_seekpos,gend_seekpos);
            // free up mark if we had one allocated
            _show_selection(orig_mark);
            if (mark_id >= 0) {
               _free_selection(mark_id);
            }
            if (embedded_status==1) {
               _EmbeddedEnd(orig_values);
            }
         } else if (gilist_tags_item >= galist_tags_found._length()) {
            galist_tags_found._makeempty();
         }
         // successful proc search, return results, unless we are beyond the end
         if (!status) {
            // IF this line is within this embedded range
            if (_QROffset()<=gend_seekpos) {
               //say('found one proc_name='proc_name' gend_linenum='gend_linenum);
               grecursion=false;
               return(0);
            }
         }
      }

      // if we get here, either the proc search failed or we were not
      // set up for doing a search the last time in, so we find the
      // extent of the next embedded context and plan to do a proc_search
      // next time.
      gdo_search=true;

      // beyond the end of file?
      if (_QROffset() >= p_RBufSize || gend_seekpos>=p_RBufSize) {
         grecursion=false;
         return(STRING_NOT_FOUND_RC);
      }
      _GoToROffset(gend_seekpos);
      l_start_seekpos=_QROffset();

      // Are we in an embedded context?
      if (p_EmbeddedLexerName!='') {
         // YES: then search for the end of the embedded context
         //      in another words, search for non-embedded source
         status=_clex_find(0,'S');
      } else {
         // NO: then search for the beginning of the next embedded context
         status=_clex_find(0,'E');
      }
      if (status) {
         _GoToROffset(p_RBufSize);
      }

      // set the ending line number and position
      gend_seekpos=_QROffset();
      _GoToROffset((int)l_start_seekpos/*+1*/);
      if (gend_seekpos==l_start_seekpos) {
         ++l_start_seekpos;
         ++gend_seekpos;
         _GoToROffset(l_start_seekpos);
      }
      //say("_EmbeddedProcSearch: start="l_start_seekpos" end="gend_seekpos);

      // Switch into embedded mode, if necessary
      typeless orig_values;
      _GoToROffset((int)l_start_seekpos+1);
      embedded_status := _EmbeddedStart(orig_values);
      //say("_EmbeddedProcSearch: EmbeddedStart()="status" ext="p_LangId);
      switch(embedded_status) {
      case 2:
         // Skip this unknown embedded text.
         gdo_search=false;
         break;
      case 1:
         // Must do embedded processing for this mode
         index := _FindLanguageCallbackIndex('vs%s-list-tags');
         if (index) {
            gpfncur_list_tags=name_index2funptr(index);
            find_first=1;
            break;
         }
         index = _FindLanguageCallbackIndex('%s-proc-search');
         if ( !gdo_search || !index ) {
            gdo_search=false;
         } else {
            gpfncur_proc_search=name_index2funptr(index);
            find_first=1;
            break;
         }
      case 3:
         //embedded mode name is the same as current mode name
      case 0:
         // We are not in an embedded language
         gpfncur_proc_search=gpfnouter_proc_search;
         gpfncur_list_tags=0;
         find_first=1;
         break;
      }
      if (embedded_status == 1) {
         _EmbeddedEnd(orig_values);
      }
      _GoToROffset((int)l_start_seekpos);
      first_time=false;
   }

   // nothing found, I think this is unreachable code
   grecursion=false;
   return(1);
}

/**
 * Generic function for doing a list-tags for a language that has
 * embedded code.  It works by doing the following:  First it calls
 * the regular "list-tags" function for the outer language, then it
 * repeatedly calls "EmbeddedProcSearch" until all of the embedded
 * code is tagged.
 *
 * NOTE: THis function has not been tested.  Plan to retrofit it
 * with vscob_list_tags() in the future, to handled embedded SQL.
 *
 * @param pfnouter_list_tags      vs[ext]_list_tags function for "outer"
 *                                (not embedded) language
 * @param unused_view_id          unused, formerlly an output view id
 * @param file_name               If not "" , specifies the name of the file on disk
 *                                to be tagged.  If zero, tag the current buffer.
 * @param unsued_ext              unused
 * @param list_tags_flags         List tags bit flags. Valid flags are:
 *                                      VSLTF_SKIP_OUT_OF_SCOPE      Skip locals that are not in scope
 *                                      VSLTF_SET_TAG_CONTEXT        Set tagging context at cursor position
 *                                      VSLTF_LIST_OCCURRENCES       Insert references into tags database
 *                                      VSLTF_START_LOCALS_IN_CODE   Parse locals without first parsing header
 * @param unused_tree_wid         unused
 * @param unused_bitmap           unused
 * @param start_seekpos           Optional.  IF given, specifies to start scan from
 *                                the current offset in the current buffer.
 * @param end_seekpos             Optional.  If given, specifices the seek
 *                                position to stop searching at.
 *
 * @return 0 on success, non-zero on error. 
 *  
 * @deprecated This function is made obsolete by the infrastructure set up 
 *             for handling embedded tagging with background tagging. 
 */
int _EmbeddedListTags(typeless pfnouter_list_tags,
                      int unused_view_id, _str file_name,
                      _str unused_ext, int list_tags_flags,
                      int unused_tree_wid=0, int unused_bitmap=0,
                      long start_seekpos=0, long end_seekpos=0)
{
   // lock the current context so that other threads can not modify it
   tag_lock_context(true);
   tag_clear_embedded();

   // call the "outer" list-tags function
   int status = (*pfnouter_list_tags)(unused_view_id,file_name,
                                      unused_ext,list_tags_flags,
                                      unused_tree_wid,unused_bitmap,
                                      start_seekpos, end_seekpos);
   if (status) {
      tag_unlock_context();
      return status;
   }

   if (tag_get_num_of_embedded(true) > 0) {
      save_pos(auto p);
      typeless p1,p2,p3,p4;
      save_search(p1,p2,p3,p4);
      top();
      proc_name := "";
      find_first := 1;
      context_id := 0;
      num_symbols := 0;
      for (;;) {
         proc_name='';
         status = _EmbeddedProcSearch(0,proc_name,find_first,unused_ext,start_seekpos,end_seekpos);
         find_first=0;

         //say("proc_name="proc_name" line_no="start_line_no);
         if (context_id > 0) {
            typeless context_pos;
            save_pos(context_pos);
            if (status) {
               bottom();
            } else {
               _GoToROffset(start_seekpos-1);
            }
            _clex_find(~COMMENT_CLEXFLAG,'-O');
            right();
            _GoToROffset(start_seekpos);
            tag_end_context(context_id, p_RLine, (int)_QROffset());
            restore_pos(context_pos);
         }
         if (status) {
            status=0;
            break;
         }
         if (proc_name != "") {
            tag_decompose_tag_browse_info(proc_name, auto cm);
            if (cm.member_name != "") {
               start_line_no := p_RLine;
               start_offset  := _QROffset();
               cm.file_name = p_buf_name;
               cm.line_no = start_line_no;
               cm.seekpos = start_offset;
               cm.scope_line_no = start_line_no;
               cm.scope_seekpos = start_offset;
               cm.end_line_no = 0;
               cm.end_seekpos = 0;
               if (list_tags_flags & VSLTF_SET_TAG_CONTEXT) {
                  status = tag_insert_context_browse_info(0, cm);
                  if (status < 0) break;
                  context_id=status;
                  if (++num_symbols > def_update_context_max_symbols) break;
               } else {
                  status = tag_insert_tag_browse_info(cm);
                  if (status < 0) break;
               }
            }
         }
      }
      restore_search(p1,p2,p3,p4);
      restore_pos(p);
   }

   // unlock the current context so that other threads may now read it
   tag_unlock_context();

   // and return the final success status
   return(status);
}

/**
 * @see ext_MaybeBuildTagFile
 */
int _tld_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'tld','tld','JSP Tag Library Descriptor Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _html_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'html','html','HTML 4.0 Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _xhtml_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   htmlTagDocFile := ext_builtins_path("html");
   htmlTagDocFile = _maybe_quote_filename(htmlTagDocFile);

   status := ext_MaybeBuildTagFile(tfindex,'xhtml','xml','XHMTL Tags', htmlTagDocFile, false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _bbc_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'bbc','bbc','Bulletin Board Code Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _xml_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'xml','xml','XML Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}

int _vpj_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'vpj','xml','XML Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}

/**
 * @see ext_MaybeBuildTagFile
 */
int _xsd_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'xsd','xsd','XML Schema Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _docbook_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'docbook','docbook','Docbook Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _xmldoc_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   status := ext_MaybeBuildTagFile(tfindex,'xmldoc','xmldoc','XMLDOC Tags', "", false, withRefs, useThread, forceRebuild);
   return(status);
}
/**
 * @see ext_MaybeBuildTagFile
 */
int _cfml_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   htmlTagDocFile := ext_builtins_path("html");
   htmlTagDocFile = _maybe_quote_filename(htmlTagDocFile);

   status := ext_MaybeBuildTagFile(tfindex,'cfml','cfml','HTML and Cold Fusion Tags', htmlTagDocFile, false, withRefs, useThread, forceRebuild);
   return(status);
}
int csh_proc_search(_str &proc_name,int find_first,
                    _str unused_ext='', _str start_seekpos='', _str end_seekpos='')
{
   return _EmbeddedProcSearch(0,proc_name,find_first,unused_ext, start_seekpos, end_seekpos);
}
int bourneshell_proc_search1(_str &proc_name,int find_first)
{
   return _generic_regex_proc_search('^[ \t]*(#|((function:b)<<<NAME>>>[ \t]*((\([ \t]*\)):0,1))|((function:b|)<<<NAME>>>[ \t]*((\([ \t]*\)))))', proc_name, find_first!=0, "func");
}

static int bourne_shell_find_matching_keyword(_str begin,_str end_keyword,_str direction='')
{
   nest_level := 0;
   status := search(end_keyword'|'begin,direction'@rhwck');
   for (;;) {
      //_message_box('status='status' end_keyword='end_keyword);
      if (status) {
         return(1);
      }
      _str word=get_text(match_length(''),match_length('S'));
      if (word:==begin) {
         ++nest_level;
         if (nest_level==0) {
            return(0);
         }
      } else if (word:==end_keyword) {
         --nest_level;
         if (nest_level==0) {
            return(0);
         }
      }
      status=repeat_search();
   }
}

int _bourneshell_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   save_pos(auto p);
   status := 0;
   _str word;
   if (_clex_find(0,'g')==CFG_KEYWORD) {
      word=cur_word(auto start_col);
      if (word!='') {
         p_col=_text_colc(start_col,'I');
      }
      switch (word) {
      case 'if':
         if(!bourne_shell_find_matching_keyword('if','fi')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      case 'fi':
         if(!bourne_shell_find_matching_keyword('if','fi','-')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      case 'do':
         if(!bourne_shell_find_matching_keyword('do','done')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      case 'done':
         if(!bourne_shell_find_matching_keyword('do','done','-')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      case 'case':
         if(!bourne_shell_find_matching_keyword('case','esac')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      case 'esac':
         if(!bourne_shell_find_matching_keyword('case','esac','-')) {
            return(0);
         }
         restore_pos(p);
         return(1);
      }

   }
   restore_pos(p);
   status=1;
   if (!quiet) {
      message(nls('Not on begin/end or paren pair'));
   }
   return(status);
}
int bourneshell_proc_search(_str &proc_name,int find_first,
                    _str unused_ext='', _str start_seekpos='', _str end_seekpos='')
{
   return _EmbeddedProcSearch(bourneshell_proc_search1,proc_name,find_first,
                              unused_ext, start_seekpos, end_seekpos);
}
void _autocase_insert_text(_str text,bool only_keywords=true)
{
   scase := LanguageSettings.getKeywordCase(p_LangId);
   if (scase<0) {
      _insert_text(text);
      return;
   }
   save_pos(auto p);
   _insert_text(text);
   typeless endOffset=point('s');
   save_pos(auto p2);
   restore_pos(p);
   typeless startLine, startWordOffset, endWordOffset;
   status := 0;
   if (only_keywords) {
      for (;;) {
         startLine=point();
         startWordOffset=point('s');
         status=_clex_find(KEYWORD_CLEXFLAG,'O');
         if (status || point('s')>=endOffset) {
            break;
         }
         status=_clex_find(KEYWORD_CLEXFLAG,'N');
         if (status || point()!=startLine) {
            _nrseek(startWordOffset);
            _end_line();
         }
         endWordOffset=point('s');
         _nrseek(startWordOffset);
         text=get_text(endWordOffset-startWordOffset);

         _delete_text(length(text));
         _insert_text(_word_case(text));
      }
   } else {
      word_chars := _clex_identifier_chars();
      re := '['word_chars']';
      not_re := '[^'word_chars']';
      for (;;) {
         startLine=point();
         startWordOffset=point('s');
         status=search(re,'rh@');
         if (status || point('s')>=endOffset) {
            break;
         }
         status=search(not_re,'rh@');
         if (status || point()!=startLine) {
            _nrseek(startWordOffset);
            _end_line();
         }
         endWordOffset=point('s');
         _nrseek(startWordOffset);
         text=get_text(endWordOffset-startWordOffset);

         _delete_text(length(text));
         _insert_text(_word_case(text));
      }
   }
   restore_pos(p2);
}


/**
 * The word case options are typically the fourth item in the
 * name_info() for a given extension.  It may have the following
 * options:
 * <ul>
 * <dt>-1 or <0<dd>Leave case as is
 * <dt>0<dd>lower case
 * <dt>1<dd>UPPER CASE
 * <dt>2<dd>Capitalize Word
 * </ul>
 *
 * @return
 * Returns the string 's' in the specified case, as indicated
 * in the file extension options for the current language.
 *
 * @param s string to change case of
 */
_str _word_case(_str s, bool confirm = true, _str sample='')
{
   if (p_caps) return(upcase(s));

   scase := 1;
   if (_isEditorCtl()) {
      updateAdaptiveFormattingSettings(AFF_KEYWORD_CASING, confirm);
      scase = p_keyword_casing;
   }

   if (scase== WORDCASE_PRESERVE) {
      if (sample != '') {
         // determine the case of the sample and use that
         if (lowcase(sample) == sample) {
            scase = WORDCASE_LOWER;
         } else if (upcase(sample) == sample) {
            scase = WORDCASE_UPPER;
            if (length(sample)==1) {
               // if we only have a one-character sample, then try to force
               // adaptive formatting to calculate the keyword casing setting
               orig_adaptive_formatting_flags := p_adaptive_formatting_flags;
               orig_keyword_casing := p_keyword_casing;
               p_adaptive_formatting_flags &= ~AFF_KEYWORD_CASING;
               updateAdaptiveFormattingSettings(AFF_KEYWORD_CASING, confirm);
               if (p_keyword_casing == WORDCASE_CAPITALIZE) {
                  scase = WORDCASE_CAPITALIZE;
               }
               p_adaptive_formatting_flags = orig_adaptive_formatting_flags;
               p_keyword_casing = orig_keyword_casing;
            }
         } else if (_cap_word(sample) == sample) {
            scase = WORDCASE_CAPITALIZE;
         }
      }
      // if we did not change this value, then just return the same old thing
      if (scase == WORDCASE_PRESERVE) {
         return(s);
      }
   }  

   if ( scase==WORDCASE_LOWER ) {
      return(lowcase(s)); /* Lower case language key words. */
   } else if ( scase==WORDCASE_UPPER ) {
      return(upcase(s));    /* Upper case language key words. */
   }

   // capitalize
   s=lowcase(s);
   return(cap_word_filter(s));
}

void _maybe_case_word(bool autocase,_str &gWord,int &gWordEndOffset) {
   // figure out our last event
   _str event=event2name(last_event());

   // this is the command line, silly
   if (command_state()) {
      keyin(event);
      return;
   }

   // we don't do anything on the first line
   if (p_line == 0) return;

   // where are we?
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || !autocase) {
      keyin(event);
      return;
   }

   keyin(event);
   left();
   cfg=_clex_find(0,'g');
   right();

   // are we looking at a keyword?
   if (cfg==CFG_KEYWORD/* || cfg==CFG_PPKEYWORD*/) {
      save_pos(auto p);
      left();

      word_pcol := 0;
      _str NewWord=cur_identifier(word_pcol);
      if (length(gWord)<length(NewWord) && lowcase(gWord):==lowcase(substr(NewWord,1,length(gWord)))) {
         gWord :+= substr(NewWord,length(gWord)+1);
      } else {
         gWord=NewWord;
      }

      right();
      p_col=word_pcol;
      _delete_text(_rawLength(gWord));
      _insert_text(_word_case(gWord));
      gWordEndOffset=(int)point('s');
      restore_pos(p);

      // tell the user what we did
      notifyUserOfFeatureUse(NF_AUTO_CASE_KEYWORD);

   } else if (gWordEndOffset+1==point('s')) {
      _str prev_cmd=name_name(prev_index('','C'));
      if (pos('maybe-case-word',prev_cmd)==0 &&
          pos('maybe-case-backspace',prev_cmd)==0) {
         return;
      }
      // Put the original word back
      p_col-=_rawLength(gWord)+1;
      _delete_text(_rawLength(gWord)+1);
      _insert_text(gWord:+event);
      gWordEndOffset= -1;gWord="";
   } else {
      // nothing to do here
      gWordEndOffset= -1;gWord="";
   }
}
void _lang_maybe_case_word(_str &gWord,int &gWordEndOffset) {
   _str event=event2name(last_event());
   if (command_state()) {
      keyin(event);
      return;
   }
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);

   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);

   _maybe_case_word(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
}

void _maybe_case_backspace(bool autocase,_str &gWord,int &gWordEndOffset) {
   _str event=event2name(last_event());
   if (command_state()) {
      call_root_key(BACKSPACE);
      return;
   }
   if (p_line==0) {
      return;
   }
   _str prev_cmd=name_name(prev_index('','C'));
   i := last_index('','C');
   call_root_key(BACKSPACE);
   last_index(i,'C');
   if (p_col==1) {
      return;
   }
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING || !autocase) {
      return;
   }
   left();cfg=_clex_find(0,'g');right();
   if (cfg==CFG_KEYWORD) {
      save_pos(auto p);

      left();
      word_pcol := 0;
      _str NewWord=cur_identifier(word_pcol);
      right();
      if (length(NewWord)<length(gWord) && lowcase(NewWord):==lowcase(substr(gWord,1,length(NewWord)))) {
         gWord=substr(gWord,1,length(NewWord));
      } else {
         gWord=NewWord;
      }

      p_col=word_pcol;
      _delete_text(_rawLength(gWord));
      _insert_text(_word_case(gWord));
      gWordEndOffset=(int)point('s');
      restore_pos(p);

      // tell the user what we did
      notifyUserOfFeatureUse(NF_AUTO_CASE_KEYWORD);
   } else if (gWordEndOffset-1==point('s') && length(gWord)>1) {
      if (pos('maybe-case-word',prev_cmd)==0 &&
          pos('maybe-case-backspace',prev_cmd)==0) {
         return;
      }
      // Put the original word back
      p_col-=_rawLength(gWord)-1;
      _delete_text(_rawLength(gWord)-1);
      _insert_text(substr(gWord,1,length(gWord)-1));
   } else {
      gWordEndOffset= -1;gWord="";
   }
}
void _lang_maybe_case_backspace(_str &gWord,int &gWordEndOffset) {
   if (command_state()) {
      call_root_key(BACKSPACE);
      return;
   }
   typeless orig_values='';
   int embedded_status=_EmbeddedStart(orig_values);

   // see if there is a value for this language, if not, we use cobol
   autoCase := LanguageSettings.getAutoCaseKeywords(p_LangId);
   _maybe_case_backspace(autoCase,gWord,gWordEndOffset);

   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
   }
}
///////////////////////////////////////////////////////////////////
// Registry values to find COBOL compiler installation paths
//
#if 1 /*!__UNIX__*/
static _str gCobolProductRegList[] = {
   "Software\\Micro Focus\\NetExpress\\3.0\\COBOL\\3.0\\Setup\tRootDir\tSource",
   "Software\\Micro Focus\\NetExpress\\1.0\\COBOL\\2.0\\Setup\tRootDir\tSource",
   "Software\\Fujitsu\\PowerCOBOL\tProduct_Directory\tclass",
   "Software\\Fujitsu\\COBOL85\tProduct_Directory\tclass",
   "Software\\Egan Systems\\Common\\Environment\tICCODEPATH\t",
   "Software\\Egan Systems\\Common\\Environment\tICROOT\t"
};
#endif
// Executable names to use to find COBOL compiler installation
static _str gCobolProductExeList[] = {
   "cobol\tSource",
   "pcobol\tclass",
   "icobol\t"
};

/**
  Get a list of paths where cobol compilers appear to be installed,
  judging by what we can determine from the registry.
  @return '' if no path found.
*/
void _CobolInstallPaths(_str (&cobolList)[])
{
   int i;
   cobolList._makeempty();
   if (_isWindows()) {
      // search cobol product list in registry
      for (i=0;i<gCobolProductRegList._length();++i) {
         _str reg_path, key_name, sub_dir;
         parse gCobolProductRegList[i] with reg_path "\t" key_name "\t" sub_dir;
         path := _ntRegQueryValue(HKEY_LOCAL_MACHINE,reg_path,"",key_name);
         if (path!="") {
            _maybe_append_filesep(path);
            if (sub_dir!='') {
               path :+= sub_dir:+FILESEP;
            }
            if (isdirectory(path)) {
               cobolList :+= path;
            }
         }
      }
   }
   if (!cobolList._length()) {
      for(i=0;i<gCobolProductExeList._length();++i) {
         _str exe_name, sub_dir;
         parse gCobolProductExeList[i] with exe_name "\t" sub_dir;
         _str path=path_search(exe_name,"PATH","P");
         if (path!="") {
            path2 := substr(path,1,(pathlen(path)-1));
            subdirname := _strip_filename(path2,'PDE');
            if (_file_eq(subdirname,'bin')) {
               path=_strip_filename(path2,'N');
               path=_strip_filename(path, 'NE');
               cobolList[cobolList._length()]= path;
            }
            _maybe_append_filesep(path);
            if (sub_dir!='') {
               if (isdirectory(path:+sub_dir)) {
                  path :+= sub_dir:+FILESEP;
               }
            }
            if (isdirectory(path)) {
               cobolList :+= path;
            }
         }
      }
   }
}

int _tagdoc_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                               VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}
int _tagdoc_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                              _str lastid,int lastidstart_offset,
                              int info_flags,typeless otherinfo,
                              bool find_parents,int max_matches,
                              bool exact_match,bool case_sensitive,
                              SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                              SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                              VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return(_c_find_context_tags(errorArgs,
                               prefixexp,
                               lastid,lastidstart_offset,
                               info_flags,otherinfo,find_parents,
                               max_matches,exact_match,case_sensitive,
                               filter_flags,context_flags,
                               visited,depth,prefix_rt));
}
int _tagdoc_fcthelp_get(_str (&errorArgs)[],
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
int _tagdoc_fcthelp_get_start(_str (&errorArgs)[],
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

int _posCurLine(_str needle,int col,_str options='')
{
   save_pos(auto p);
   status := search(needle,'@'options);
   result := p_col;
   restore_pos(p);
   if (status) {
      return(0);
   }
   return(result);
}
_command void list_unresolved()
{
   edit('+t');
   int index=name_match('',1,PROC_TYPE);
   for (;;) {
      if (!index) {
         break;
      }
      if (!index_callable(index)) {
         insert_line(name_name(index));
      }
      index=name_match('',0,PROC_TYPE);
   }
}

bool _e_match_procs(_str match_symbol)
{
   index := find_index(match_symbol,PROC_TYPE|COMMAND_TYPE);
   if (!index || !index_callable(index)) {
      return false;
   }

   int module_index = index_callable(index);
   module_name := name_name(module_index);
   proc_name := name_name(index);
   if (module_name == '') {
      return false;
   }

   proc_name= translate(proc_name,'_','-');
   _str ext=_get_extension(module_name);
   if (! _file_eq('.'ext,_macro_ext)) {
      module_name= substr(module_name,1,length(module_name)-length(ext)-1):+_macro_ext;
   }
   _str filename= slick_path_search(module_name);
   if ( filename=='' ) {
     return false;
   }

   // search for the proc
   temp_view_id := 0;
   orig_view_id := 0;
   typeless inmem;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,'',inmem,false,true);
   if (status) {
      return(false);
   }
   //say("search_proc="proc_name);
   _SetEditorLanguage('e');
   status=_VirtualProcSearch(proc_name);
   line_no := p_RLine;
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   if (!status) {
      tag_decompose_tag_browse_info(proc_name, auto cm);
      cm.file_name = filename;
      cm.line_no = line_no;
      tag_insert_match_browse_info(cm);
      return true;
   }
   return false;
}

///////////////////////////////////////////////////////////////////////////////
// SLICK-C PROFILING SUPPORT
///////////////////////////////////////////////////////////////////////////////

static _str profiler_tree_cb(int sl_event, typeless user_data, typeless info=null)
{
   s := "";
   switch (sl_event) {
   case SL_ONSELECT:
      s = _TreeGetCaption(info);
      break;
   case SL_ONINITFIRST:
      typeless bw,bf,bs,bc;
      _TreeSortCol(4,'nd');
      _TreeGetColButtonInfo(8, bw, bf, bs, bc);
      _TreeSetColButtonInfo(8, bw, bf|TREE_BUTTON_SORT_DESCENDING, bs, bc);
      p_scroll_bars = SB_BOTH;
      _TreeTop();
      select_tree_message("All times are in milliseconds.");
      break;
   case SL_ONDEFAULT:
      profiler_goto_symbol(_TreeGetCaption(info));
      return null;
   }
   return "";
}

static int get_line_from_module_and_offset(_str module_name, int offset)
{
   if (offset < 16) {
      return 0;
   }

   _str module_path = _macro_path_search(module_name);
   if (module_path == '') {
      return 0;
   }

   _str error_file = mktemp();
   if (error_file == "") {
      return 0;
   }

   _maybe_strip(module_path, 'x');

   st_command := "0 vstw";
   _str line = st_command :+ " -f " :+ offset :+
                             " -q -e "_maybe_quote_filename(error_file) :+
                             " " :+ _maybe_quote_filename(module_path);
   int status=shell(line,'n');
   if (status < 0) {
      return status;
   }

   temp_view_id := 0;
   orig_view_id := 0;
   status = _open_temp_view(error_file, temp_view_id, orig_view_id);
   if (status < 0) {
      return status;
   }

   get_line(line);
   if ( substr(line,1,16)=="Slick Translator" ) {
      _delete_line();
      _delete_line();
   }

   if ( p_Noflines>0 ) {
     get_line(line);
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   delete_file(error_file);

   _str filename=parse_file(line);
   typeless line_no,col,msg;
   parse line with line_no col':'msg;
   return line_no;
}
static void profiler_format_time(_str &n)
{
   switch (length(n)) {
   case 1:
      n = "0.00":+n;
      break;
   case 2:
      n = "0.":+n;
      break;
   case 3:
      n = "0.":+n;
      break;
   default:
      n = substr(n, 1, length(n)-3) :+ '.' :+ substr(n, length(n)-3, 3);
      break;
   }
}
static int profiler_get_function_time(_str line)
{
   module_name := "";
   offset := "";
   proc_name := "";
   num_calls := "";
   min_function_time := "";
   max_function_time := "";
   total_function_time := "";
   min_funconly_time := "";
   max_funconly_time := "";
   total_funconly_time := "";
   parse line with module_name "\t" offset "\t" proc_name "\t" line;

   parse line with num_calls "\t" line;
   parse line with min_function_time "\t" line;
   parse line with max_function_time "\t" line;
   parse line with total_function_time "\t" line;
   parse line with min_funconly_time "\t" line;
   parse line with max_funconly_time "\t" line;
   parse line with total_funconly_time "\t" line;

   return (int) total_funconly_time;
}
static _str profiler_get_caption(_str line, int total_time)
{
   module_name := "";
   offset := "";
   proc_name := "";
   num_calls := "";
   min_function_time := "";
   max_function_time := "";
   total_function_time := "";
   min_funconly_time := "";
   max_funconly_time := "";
   total_funconly_time := "";
   parse line with module_name "\t" offset "\t" proc_name "\t" line;

   parse line with num_calls "\t" line;
   parse line with min_function_time "\t" line;
   parse line with max_function_time "\t" line;
   parse line with total_function_time "\t" line;
   parse line with min_funconly_time "\t" line;
   parse line with max_funconly_time "\t" line;
   parse line with total_funconly_time "\t" line;

   if (total_time < (int)total_function_time) total_time=(int)total_function_time;
   if (total_time == 0) total_time=1;
   _str pct_function_time = (int)(((double)total_function_time / total_time) * 100000);
   _str pct_funconly_time = (int)(((double)total_funconly_time / total_time) * 100000);
   _str avg_function_time = (int)total_function_time intdiv (int)num_calls;
   _str avg_funconly_time = (int)total_funconly_time intdiv (int)num_calls;

   profiler_format_time(total_function_time);
   profiler_format_time(pct_function_time);
   profiler_format_time(avg_function_time);
   profiler_format_time(min_function_time);
   profiler_format_time(max_function_time);
   profiler_format_time(total_funconly_time);
   profiler_format_time(pct_funconly_time);
   profiler_format_time(avg_funconly_time);
   profiler_format_time(min_funconly_time);
   profiler_format_time(max_funconly_time);

   if (module_name=="" && proc_name=="") return "";
   _maybe_strip(module_name, 'x');

   // if this looks like an event function, let's try and see if we can
   // query and get a better name for it.
   if (module_name != "" && pos(".", proc_name) && total_funconly_time > 0) {
      orig_proc_name := proc_name;
      status := _GetSlickCFunctionNameFromOffset(module_name, (int)offset, proc_name);
      if (status < 0) proc_name = orig_proc_name;
   }

   typeless d1,d2,d3,d4,d5,d6,visited=null;
   _str module_path = _macro_path_search(module_name);
   if ( module_path != "" && proc_name == "" && total_function_time > 0 ) {
      status := _GetSlickCFunctionNameFromOffset(module_name, (int)offset, proc_name);
      if (status < 0 || proc_name == "") {
         _maybe_strip(module_path, 'x');
         message("Scanning: "module_path);
         temp_view_id := 0;
         orig_view_id := 0;
         status = _open_temp_view(module_path, temp_view_id, orig_view_id, "+d", true, false, true);
         if (!status) {
            line_no := get_line_from_module_and_offset(module_name, (int) offset);
            if (isuinteger(line_no)) {
               p_line=line_no;
               _UpdateContext(true);
               tag_get_current_context(proc_name,d1,d2,d3,d4,d5,d6,visited,1);
            }
         }
         activate_window(orig_view_id);
         _delete_temp_view(temp_view_id);
      } else if (pos(':', proc_name)) {
         parse proc_name with . ":" proc_name;
      }
   }

   return proc_name "\t" module_name "\t" offset "\t" num_calls "\t" :+
          total_function_time "\t" pct_function_time "\t" avg_function_time "\t" min_function_time "\t" max_function_time "\t" :+
          total_funconly_time "\t" pct_funconly_time "\t" avg_funconly_time "\t" min_funconly_time "\t" max_funconly_time;
}
static void profiler_goto_symbol(_str info)
{
   proc_name := "";
   module_name := "";
   offset := "";
   parse info with proc_name "\t" module_name "\t" offset "\t" . ;
   if (module_name == '' && proc_name!='') {
      find_tag("-e c ":+proc_name:+"(func)");
   } else if (module_name != '' && offset != '') {
      _str module_path = _macro_path_search(module_name);
      _maybe_strip(module_path, 'x');
      line_no := 1;
      temp_view_id := 0;
      orig_view_id := 0;
      int status = edit(_maybe_quote_filename(module_path));
      if (!status) {
         line_no  = _GetSlickCLineNumberFromOffset(module_name, proc_name, (int)offset);
         if (line_no < 0) {
            line_no = get_line_from_module_and_offset(module_name, (int) offset);
         }
         if (isuinteger(line_no)) {
            p_line=line_no;
            begin_proc();
             center_line();
         }
      }
   } else if (proc_name!='') {
      find_proc("-e e ":+proc_name);
   } else {
      message("Symbol not found");
   }
}

/**
 * This command is used to load a set of profiling results into the 
 * Slick-C&reg; performance profiler.  It is equivalent to using 
 * "profile load &lt;filename&gt;". 
 *
 * @param filename  tab-separated profiling data file (profile.tsv) 
 *
 * @see _SlickCProfiling 
 * @see profile
 * @categories Macro_Programming_Functions
 */
_command void profile_load(_str filename="") name_info(FILE_ARG',')
{
   profile("load ":+_maybe_quote_filename(filename));
}

/**
 * This command is used to save a set of profiling results from the 
 * Slick-C&reg; performance profiler.  It is equivalent to using 
 * "profile save &lt;filename&gt;". 
 *
 * @param filename  tab-separated profiling output data file (profile.tsv) 
 *
 * @see _SlickCProfiling 
 * @see profile
 * @categories Macro_Programming_Functions
 */
_command void profile_save(_str filename="") name_info(FILENEW_ARG',')
{
   profile("save ":+_maybe_quote_filename(filename));
}

/**
 * This command is used to control the Slick-C&reg; performance profiler.
 * <p>
 * To activate the profiler, execute the command "profile on".
 * To stop collecting profiling information, execute the command
 * "profile off".  To view collected profiling data, execute the command
 * "profile view".  This will also stop profiling data collection.
 * To profile a single Slick-C&reg; command, just pass the command and
 * it's arguments to the profile command.  For example "profile list-tags".
 * <p>
 * The profiler has no effect on performance when it is inactive and
 * only a minimal effect on performance when it is collecting data.
 * <p>
 * Profiling data can be saved and viewed at a later time by using
 * the "profile save" and "profile load" commands, respectively.
 * <p> 
 * The profiler can also be used to profile executing the command tied to a
 * specific key by using the "profile key" command.  It will prompt for a 
 * key and then execute the corresponding command and display the profiling 
 * results. 
 * <p> 
 * Profiling results are displayed in a multi-column non-modal tree
 * dialog.  Each line in the tree represents one function, either a
 * Slick-C&reg; or an exported DLL function, which was called while we were
 * collecting profiling data.  All times are reported in milliseconds.
 * The table columns represent the following information:
 * <ul>
 * <li><b>Function</b>  -- name of function called
 * <li><b>Module</b>    -- the name of the module function comes from
 * <li><b>Offset</b>    -- P-code offset of function within module
 * <li><b>Calls</b>     -- number of calls to function
 * <li><b>F+D Time</b>  -- total time in function and descendants
 * <li><b>Percent</b>   -- percentage of total time spent in function and descendants
 * <li><b>Avg F+D</b>   -- average time in function and descendants
 * <li><b>Min F+D</b>   -- minimum time in function and descendants
 * <li><b>Max F+D</b>   -- maximum time in function and descendants
 * <li><b>Func Time</b> -- total time in function only
 * <li><b>Percent</b>   -- percentage of total time spent in function
 * <li><b>Avg Time</b>  -- average time in function
 * <li><b>Min Time</b>  -- minimum time in function
 * <li><b>Max Time</b>  -- maximum time in function
 * </ul>
 *
 * @param option  [ on | off | view | load [file] | save [file] | &lt;command&gt; ]
 *
 * @see _SlickCProfiling
 * @categories Macro_Programming_Functions
 */
_command void profile(_str option="") name_info(COMMAND_ARG',')
{
   enabled := _SlickCProfiling(false);
   parse option with option auto load_options;

   // Save this in case there it is a command name. We do not want to change
   // the case (find_index is case sensitive)
   origOption := option;
   option = lowcase(option);
   switch (option) {
   case 'start':
   case 'on':
   case '1':
      message("Profiling Slick-C"VSREGISTEREDTM" functions");
      _SlickCProfiling(true);
      return;
   case 'stop':
   case 'off':
   case '0':
      message("Profiling done.");
      return;
   case 'view':
   case 'show':
      break;
   case 'save':
      if (load_options=='') {
         currentDir := getcwd();
         chdir(_ConfigPath());
         load_options = _OpenDialog(ShowArgs:            "-new -mdi -modal",
                                    pszTitle:            "Save Profiling Data",
                                    pszInitialWildCards: "",
                                    pszFileFilters:      "*.tsv;*.txt",
                                    VSOFNFlags:          OFN_SAVEAS,
                                    pszDefaultExt:       "tsv",
                                    pszInitialFilename:  "profile.tsv",
                                    pszInitialDirectory: _log_path(),   // Initial directory
                                    pszHelpName:         "Standard Open dialog box"
                                   );
         chdir(currentDir);
         if (load_options=="") {
            return;
         }
      }
      {
         temp_view_id := 0;
         load_options = strip(load_options,'B','"');
         orig_view_id := _create_temp_view(temp_view_id, "", load_options);
         _lbclear();
         _InsertSlickCProfilingData(p_window_id);
         save("-E");
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      }
      return;
   case 'load':
      if (load_options=='') {
         currentDir := getcwd();
         chdir(_ConfigPath());
         load_options = _OpenDialog(ShowArgs:            "-new -mdi -modal",
                                    pszTitle:            "Load Profiling Data",
                                    pszInitialWildCards: "",
                                    pszFileFilters:      "*.tsv;*.txt",
                                    VSOFNFlags:          OFN_FILEMUSTEXIST,
                                    pszDefaultExt:       "tsv",
                                    pszInitialFilename:  "profile.tsv",
                                    pszInitialDirectory: _log_path(),
                                    pszHelpName:         "Standard Open dialog box"
                                   );
         chdir(currentDir);
         if (load_options=="") {
            return;
         }
      }
      load_options = strip(load_options,'B','"');
      if (!file_exists(load_options)) {
         _message_box("File not found: ", load_options);
         return;
      }
      break;
   case '':
      if (!enabled) {
         message("Profiling Slick-C"VSREGISTEREDTM" functions");
         _SlickCProfiling(true);
         return;
      }
      break;
   case 'key':
      {
         // prompt for a key to profile the command bound to
         typeless keytab_used,k;
         _str keyname;
         if (prompt_for_key(nls('Find proc bound to key:')' ',keytab_used,k,keyname,'','','',1)) {
            return;
         }

         // profile running that key
         _SlickCProfiling(true);
         call_event(keytab_used, k, 'e');
         _SlickCProfiling(false);

         // check if the key was bound to anything
         int index=eventtab_index(keytab_used,keytab_used,event2index(k));
         if (!index) {
            // we might have gotten some profiling data from editor callbacks
            // so check if we got anything.
            temp_view_id := 0;
            int orig_view_id = _create_temp_view(temp_view_id);
            if (orig_view_id < 0) {
               _message_box(get_message(orig_view_id));
               return;
            }
            _InsertSlickCProfilingData(temp_view_id);
            numLines := p_Noflines;
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);

            // if we have no profiling data, then give up
            if (numLines <= 0) {
               _str msg=nls('%s is not defined',keyname);
               if (p_HasBuffer) {
                  _message_box(msg);
               } else {
                  message(msg);
               }
               return;
            }
         }
         break;
      }
   case 'exec':
      parse load_options with option load_options;
      // drop through
   default:
      // maybe they gave us a command to profile?
      _str command_name;
      parse origOption with command_name .;
      if (!find_index(command_name, COMMAND_TYPE)) {
         _message_box("Slick-C"VSREGISTEREDTM" Profiler: unrecognized option or command: \""option"\"");
         return;
      }
      _SlickCProfiling(true);
      execute(command_name' 'load_options);
      _SlickCProfiling(false);
      break;
   }

   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   if (orig_view_id < 0) {
      _message_box(get_message(orig_view_id));
      return;
   }

   if (option == 'load') {
      load_files("-E "_maybe_quote_filename(load_options));
   } else {
      _InsertSlickCProfilingData(temp_view_id);
   }

   line := "";
   total_time := 0;
   top();
   for (;;) {
      get_line(line);
      if (line!="") {
         total_time += profiler_get_function_time(line);
      }
      if (down()) break;
   }

   _str lines[]; lines._makeempty();
   top();
   for (;;) {
      get_line(line);
      if (line != '') {
         line = profiler_get_caption(line,total_time);
         if (line != '') lines[lines._length()]=line;
      }
      if (down()) break;
   }

   clear_message();
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   if (lines._length()==0) {
      _message_box("No profiling data");
      return;
   }

   select_tree(lines,
               null, null, null, null,
               profiler_tree_cb, null,
               "Slick-C"VSREGISTEREDTM" Profiler",
               SL_CLOSEBUTTON|SL_COLWIDTH|SL_SIZABLE|SL_XY_WIDTH_HEIGHT|SL_DEFAULTCALLBACK,
               "Function,Module,Offset,Calls,F+D Time,Percent,Avg F+D,Min F+D,Max F+D,Func Time,Percent,Avg Time,Min Time,Max Time",
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_EXACT|TREE_BUTTON_PUSHBUTTON)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_FILENAME|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_IS_FILENAME)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT)",":+
               (TREE_BUTTON_SORT_COLUMN_ONLY|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_AL_RIGHT),
               false, "Slick-C Profiler dialog", "slickc_profiler"
              );
   activate_window(orig_view_id);
}


///////////////////////////////////////////////////////////////////////////////
// SLICK-C DEBUGGING SUPPORT
///////////////////////////////////////////////////////////////////////////////

int def_debug_slickc_port = 8003;
static int gi_slickc_debug_pid = 0;

/** 
 * @return Return 'true' if Slick-C debugging is currently enabled.
 * @categories Macro_Programming_Functions
 */
bool _SlickCDebuggingEnabled()
{
   return (_SlickCDebugging(SLICKC_DEBUG_ENABLED,def_debug_slickc_port) > 0);
}
      
int _OnUpdate_slickc_debug(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return MF_ENABLED;
}
int _OnUpdate_slickc_debug_start(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_slickc_debug(cmdui,target_wid,command);
}
int _OnUpdate_slickc_debug_attach(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_slickc_debug(cmdui,target_wid,command);
}
int _OnUpdate_slickc_debug_detach(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_slickc_debug(cmdui,target_wid,command);
}

/**
 * This command is used to control the Slick-C&reg; debugging.
 * <p>
 * To activate Slick-C debugging, execute the command "slickc_debug on".
 * To stop Slick-C debugging, execute the command "slickc_debug off".
 * <p> 
 * To activate Slick-C debugging and spawn another instance of 
 * SlickEdit to attach and control the debugging session, execute 
 * the command "slickc_debug attach".  <i>This is the most common 
 * way to launch the debugger.</i>
 * <p>
 * The debugger has no effect on performance when it is inactive and
 * only a minimal effect on performance when it is running.
 * <p>
 * To enable debugging for a single Slick-C command and terminate the 
 * debugger when the command completes, just pass the command name. 
 * 
 * @param option  [ attach | on | off | &lt;command&gt; ]
 * 
 * @see _SlickCProfiling
 * @categories Macro_Programming_Functions
 */
_command void slickc_debug(_str option="") name_info(COMMAND_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return;
   }
   parse option with option auto load_options;
   option = lowcase(option);
   switch (option) {
   case 'start':
   case 'on':
   case '1':
   case '':
      if (_SlickCDebuggingEnabled()) {
         message("Debugger already active.");
         return;
      }
      message("Debugging Slick-C"VSREGISTEREDTM" code");
      _SlickCDebugging(SLICKC_DEBUG_ON,def_debug_slickc_port);
      _autosave_set_timer_alternate();
      return;
   case 'attach':
      if (_SlickCDebuggingEnabled()) {
         message("Debugger already attached.");
         return;
      }
      slickc_debug_start();
      return;
   case 'stop':
   case 'off':
   case '0':
      if (_SlickCDebuggingEnabled()) {
         _SlickCDebugging(SLICKC_DEBUG_OFF,def_debug_slickc_port);
         _autosave_set_timer_alternate();
         message("Debugging stopped.");
      }
      return;
   default:
      // maybe they gave us a command to debug?
      _str command_args = option;
      _str command_name = parse_file(command_args,false);
      if (!find_index(command_name, COMMAND_TYPE) && !file_exists(command_name)) {
         _message_box("Slick-C"VSREGISTEREDTM" Debugger: unrecognized option or command: \""option"\"");
         return;
      }
      if (_SlickCDebuggingEnabled()) {
         message("Debugger already running.");
         return;
      }

      slickc_debug_start();
      message("Debugging Slick-C"VSREGISTEREDTM" command: "option);
      // TBF: need to set a temporary breakpoint on the command
      _SlickCDebugging(SLICKC_DEBUG_SUSPEND,def_debug_slickc_port);
      execute(option);
      _SlickCDebugging(SLICKC_DEBUG_OFF,def_debug_slickc_port);
      _autosave_set_timer_alternate();
      message("Debugging done.");
      break;
   }
}

void _on_slickc_debug()
{
   if (!_SlickCDebuggingEnabled()) {
      slickc_debug_start();
      _SlickCDebugging(SLICKC_DEBUG_SUSPEND,def_debug_slickc_port);
   }
}

_command void slickc_debug_start() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   // make sure the debugger isn't already started
   if (_SlickCDebuggingEnabled()) {
      message("Debugger already attached.");
      return;
   }
   if (gbgm_search_state) {
      message('There is a debugger already running.');
      return;
   }

   // notify the user that the debugger is starting
   if (!_use_timers) _use_timers=1;
   message("Debugging Slick-C"VSREGISTEREDTM" code");
   _SlickCDebugging(SLICKC_DEBUG_ON,def_debug_slickc_port);
   _autosave_set_timer_alternate();
   
   // get the editor name
   exec_name := _maybe_quote_filename(editor_name("E"));

   // put together new configuration directory information
   config_dir := _ConfigPath();
   master_tag_dir  := config_dir:+"tagfiles";
   master_tag_file := master_tag_dir:+FILESEP:+"slickc":+TAG_FILE_EXT;
   config_dir :+= "SCDebug";
   config_dir :+= FILESEP;
   parse _version() with auto major "." auto minor "." auto patch_rev "." auto build_rev;
   version_dir := config_dir;
   version_dir :+= major "." minor "." patch_rev;
   version_dir :+= FILESEP;
   debug_tag_dir  := version_dir:+"tagfiles";
   debug_tag_file := debug_tag_dir:+FILESEP:+"slickc":+TAG_FILE_EXT;

   // check if they have a slick-c tag file
   if (!file_exists(debug_tag_file) && file_exists(master_tag_file)) {
      make_path(debug_tag_dir);
      copy_file(master_tag_file, debug_tag_file);
      adjustTagfilePaths(debug_tag_file, debug_tag_dir, master_tag_dir);
   }

   // check to see if this is the first time in
   extra_time := 0;
   if (!path_exists(config_dir)) {
      extra_time = 60;
   }

   // generic options
   options := " +new -q -st 0 -sc "_maybe_quote_filename(config_dir)" -r slickc_debug_attach ":+def_debug_slickc_port;

   // always invoke background editor using 
   // -sul to disable locking on Unix
   if (_isUnix()) {
      options = " -sul":+options;
   }

   debug_hin  := 0;
   debug_hout := 0;
   debug_herr := 0;

   if (_isWindows()) {
      status := shell(exec_name:+options,'A');
      if (status < 0) {
         message('There was an error starting the debug process');
         _SlickCDebugging(SLICKC_DEBUG_OFF,def_debug_slickc_port);
         return;
      }
   } else {
      gi_slickc_debug_pid=_PipeProcess(exec_name:+options,debug_hin,debug_hout,debug_herr,'');
      if (gi_slickc_debug_pid<0) {
         message('There was an error starting the debug process');
         _SlickCDebugging(SLICKC_DEBUG_OFF,def_debug_slickc_port);
         return;
      }
   }

   // pole until we are connected to the debugger
   stop_time := (typeless)_time('B') + def_debug_timeout*1000 + extra_time*1000;
   loop {
      if (!_SlickCDebuggingEnabled()) break;
      if (_SlickCDebugging(SLICKC_DEBUG_CONNECTED,def_debug_slickc_port)) break;
      if (_time('B') >= stop_time) {
         message('Timed out starting the debug process');
         _SlickCDebugging(SLICKC_DEBUG_OFF,def_debug_slickc_port);
         return;
      }
      _SlickCDebugHandler(0);
      delay(1);
   }

   // pole for commands for another three seconds
   stop_time = (typeless)_time('B') + def_debug_timeout*100;
   loop {
      if (!_SlickCDebuggingEnabled()) break;
      if (_time('B') >= stop_time) break;
      _SlickCDebugHandler(0);
      delay(1);
   }
}

_command void slickc_debug_attach(_str port="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   // initialize the debugger DLL 
   // otherwise, we can't restore breakpoints
   debug_maybe_initialize();

   // create a workspace to keep track of breakpoints, watches
   config_dir := _ConfigPath();
   wkspace_name := config_dir:+"SCDebug.vpw";
   if (_file_eq(wkspace_name, _workspace_filename)) {
      // do nothing, workspace is already open
   } else if (file_exists(wkspace_name)) {
      workspace_open(wkspace_name);
   } else {
      workspace_new(false,"SCDebug",config_dir);
   }

   // create a session ID for this project and make it active
   session_name := debug_get_workspace_session_name();
   if (session_name == '') return;
   int session_id = dbg_find_session(session_name);
   if (session_id < 0) {
      session_id = dbg_create_new_session("jdwp", session_name, true);
   }
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // fake out post install, as if it were already done
   parse get_message(SLICK_EDITOR_VERSION_RC) with . 'Version' auto currentVersion . ;
   _post_install_version = currentVersion;
   if (def_debug_timeout == "" || def_debug_timeout == 0) {
      def_debug_timeout = 30;
   }
   if (def_show_tips_on_startup) {
      def_show_tips_on_startup = false;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // set up the path to the parent configuration directory
   // equivalent to config_dir/version/SCDebug/version/../../
   parent_dir := config_dir;
   parent_dir = strip(parent_dir, 'T', FILESEP);
   parent_dir = _strip_filename(parent_dir,'N');
   parent_dir = strip(parent_dir, 'T', FILESEP);
   parent_dir = _strip_filename(parent_dir,'N');
   _maybe_append_filesep(parent_dir);

   // set up backup directory to point to parent config
   backup_dir := get_env('VSLICKBACKUP');
   if (backup_dir=="") {
      backup_dir = parent_dir;
      backup_dir :+= "vsdelta";
      backup_dir :+= FILESEP;
      _ConfigEnvVar('VSLICKBACKUP',backup_dir,_encode_vsenvvars(backup_dir,false));
   } else {
      backup_dir = stranslate(backup_dir, parent_dir, "%SLICKEDITCONFIGVERSION%");
      _ConfigEnvVar('VSLICKBACKUP',backup_dir,_encode_vsenvvars(backup_dir,false));
   }

   // update the debugger port if they passed in something different
   if (port != "" && isinteger(port) && port != def_debug_slickc_port) {
      def_debug_slickc_port = (int)port;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // now attach to the debugger
   params := 'host=localhost,port='def_debug_slickc_port;
   status := debug_attach('slickc_jdwp', params, session_name);

   if (status==0 && debug_is_suspended()) {
      debug_pkg_update_stack(1);
      dbg_get_frame(1,1,auto method_name,
                    auto signature, auto return_type, auto class_name,
                    auto file_name, auto line_number, auto address);
      dbg_get_frame(1,2,auto method_name2,
                    auto signature2, auto return_type2, auto class_name2,
                    auto file_name2, auto line_number2, auto address2);
      if (method_name=="_SlickCDebugging" && 
          class_name=="sc.lang.procs.Globals" &&
          method_name2!="_on_slickc_debug" && 
          method_name2!="_on_slickc_error") {
         debug_step_into();
      }
   }
}

_command bool slickc_debug_detach() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) return false;
   session_id := dbg_get_current_session();
   if (dbg_get_callback_name(session_id)=="jdwp") {
      dbg_session_version(session_id,
                          auto description,
                          auto major_version, auto minor_version,
                          auto runtime_version, auto debugger_name);
      if (debugger_name == "SlickEdit") {
         return true;
      }
   }
   return false;                             
}

/**
 * Command used to look for unresolved links in a loaded Slick-C&reg;
 * module.  Procedures that cannot be found are listed in the
 * SlickEdit debug window.
 *
 * @categories Macro_Programming_Functions
 *
 */
_command void check_links(_str filename = '') name_info(MODULE_ARG',')
{
   module_name := _strip_filename(prompt(filename, "Check module"), 'P');
   index := _find_module_index(filename);
   if (index > 0) {
      int status = _SlickCCheckModuleLinks(index);
      if (status != 0) {
         message(nls("Module <%s> has %s unresolved link%s", module_name, status, ((status > 1) ? "s" : "")));
      }
   } else {
       message(nls("Module not found: %s" ,module_name));
   }
}

/**
 * Checks to see if the first thing on the current line is an
 * open brace.  Used by comment_erase (for reindentation).
 *
 * @return Whether the current line begins with an open brace.
 */
bool e_is_start_block()
{
   return c_is_start_block();
}

bool ext_isIdChar(_str ch) {
   word_chars := _clex_identifier_chars();
   return(pos('['word_chars']',ch,1,'r')!=0);
}

bool _e_auto_surround_char(_str key) {
   return _generic_auto_surround_char(key);
}

/**
 * Dump Slick-C names table entires to the SlickEdit debug window.
 * 
 * @param prefix_colon_types  A sting of the form "prefix:type_names" indicating 
 *                            a name prefix to search for, and an optional
 *                            list of symbol types to specify from the following:
 *                            proc, var, eventtab, command, gvar, gproc, module,
 *                            picture, bufvar, object, info, dllcall, dllmodule,
 *                            enum, class, interface, const, misc, any
 */
_command void dump_names_table(_str prefix_colon_types="") name_info(',')
{
   prefix := "";
   type_flags := -1;
   if (prefix_colon_types != "") {
      parse prefix_colon_types with prefix ":" auto types;
      if (types != "") {
         type_flags = IGNORECASE_TYPE;
         while (types != "") {
            parse types with auto t ',' types;
            this_flag := eq_name2value(t,HELP_TYPES);
            if (this_flag=="" || !isnumber(this_flag)) {
               message("Invalid type name argument: "t);
               return;
            }
            type_flags |= this_flag;
         }
      }
   }

   index := name_match(prefix,1,type_flags);
   while (index > 0) {
      info_name := "";
      t := name_type(index);
      if ((t & PICTURE_TYPE) && !(type_flags & PICTURE_TYPE)) {
         index = name_match(prefix,0,type_flags);
         continue;
      }
      if (t & INFO_TYPE) {
         info_name :+= "info ";
         t &= ~INFO_TYPE;
      }
      if (t & PROC_TYPE) {
         info_name :+= "proc ";
         t &= ~PROC_TYPE;
      }
      if (t & COMMAND_TYPE) {
         info_name :+= "command ";
         t &= ~COMMAND_TYPE;
      }
      if (t & IGNORECASE_TYPE) {
         t &= ~IGNORECASE_TYPE;
      }
      type_name := eq_value2name(t, HELP_TYPES);
      say("dump_names_table: name["index"]: "info_name:+type_name " "name_name(index));
      index = name_match(prefix,0,type_flags);
   }
}
int _find_module_index(_str filename) {
   result:=_plugin_relative_path(filename);
   if (result==null) {
      filename=_strip_filename(filename,'P');
   } else {
      filename=result;
   }
   _maybe_append(filename, 'x');
   return find_index(filename,MODULE_TYPE);
}
