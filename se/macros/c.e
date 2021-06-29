/////////////////////////////////////////////////////////////////////////////////////
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
#import "se/autobracket/AutoBracketListener.e"
#import "se/ui/AutoBracketMarker.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "autobracket.e"
#import "autocomplete.e"
#import "beautifier.e"
#import "box.e"
#import "caddmem.e"
#import "cfcthelp.e"
#import "cidexpr.e"
#import "clipbd.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "commentformat.e"
#import "context.e"
#import "csymbols.e"
#import "cua.e"
#import "cutil.e"
#import "hotspots.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "notifications.e"
#import "pmatch.e"
#import "mouse.e"
#import "objc.e"
#import "seek.e"
#import "seldisp.e"
#import "setupext.e"
#import "slickc.e"
#import "smartp.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#import "xmldoc.e"
#import "aliasedt.e"
#import "ps1.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Don't modify this code unless defining extension specific
  aliases does not suite your needs.   For example, if you
  want your brace style to be:

       if () {
          }

  Use the Language Options dialog 
  ("Document", "[Language] Options...]", "Aliases"). 
  and press the the "Alias" button to create a new alias.
  Type "if" for the name of the alias and press Enter.
  Enter the following text into the upper right editor control:

       if (%\c) {
       %\i}

  The  %\c indicates where the cursor will be placed after the
  "if" alias expanded.  The %\i specifies to indent by the
  Extension Specific "Syntax Indent" amount define in the
  Extension Options dialog box.  Check the "Indent With Tabs"
  check box on the Extension Options dialog box if you want
  the %\i option to indent using tab characters.

*/
/*
  Options for C syntax expansion/indenting may be accessed from the
  Language Options ("Document", "[Language] Options...]", "Editing").

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:

    Position       Option
       1             Syntax indent amount
       2             expansion on/off.
       3             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       4             Indent after open parenthesis.  Effects argument
                     lists and if/while/switch.
       5             begin/end style.  Begin/end style may be 0,1, or 2
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


       6             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
       7             Main style.  Main style may be 0,1, or 2 which
                     correspond to old C style, ansi C, or no expansion.
                     Default is 0.
       8             Indent CASE from SWITCH.  Default is 0.  Specify
                     1 if you want CASE statements indented from the
                     SWITCH statement. Begin/end style 2 not supported.
       9             Not always present.
                     UseContOnParameters
*/


// style3 refers to out C extension options dialog
int def_style3_indent_all_braces;

// always prompt for else or else if,
// even if "else" is completely typed out
bool def_always_prompt_for_else_if=false;

// indent public:|private:|protected: specifiers inside class/struct
bool def_indent_member_access_specifier=false;

// leave single line statements hanging
//
// if (condition)
//    doSomething();
//
// instead of:
//
// if (condition) doSomething();
//
int def_hanging_statements_after_col=40;

/**
 * By default, when you type a space after a #include, we will not
 * do anything special.  Set this value to
 * AC_POUND_INCLUDE_QUOTED_ON_SPACE to list quoted include files
 * after typing "#include&lt;space&gt;".  To list include files
 * (no quotes) after typing "#include "" or "#include &lt;", set 
 * this value to AC_POUND_INCLUDE_ON_QUOTELT. 
 *
 * This variable only applies to C/C++.  It is best to access
 * this by calling the LanguageSettings API for the language you
 * are interested in
 * (LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId)).
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_c_expand_include=AC_POUND_INCLUDE_NONE;

/**
 * Controls how virtual functions are declared by 
 * override-method and related code generation functions. 
 * If non-zero, virtual function overrides will be written 
 * with the override keyword: 
 *
 *    <code>int getCount() override;</code>
 *  
 * If set to zero, virtual function declarations go back to the 
 * older syntax: 
 *
 *    <code>virtual int getCount();</code>
 * 
 */
int def_use_override_keyword = 1;


/**
 * Activates C/C++ file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('c');
}

/**
 * (C mode only) ENTER
 * <pre>
 * New binding of ENTER key when in C mode.  Handles syntax expansion and indenting for files
 * with C or H extension.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (ispf_common_enter()) return;
   if (command_state()) {
      call_root_key(ENTER);
      return;
   }

   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(ENTER, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (p_window_state:=='I' ||
      p_SyntaxIndent<0) {
      call_root_key(ENTER);
      return;
   }
   if (!_LanguageInheritsFrom('r')) {
      if (_in_comment(true)) {
         // start of a Java doc comment?
         get_line(auto first_line);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) &&
             (first_line=='/***/' || first_line=='/*!*/') && get_text(2)=='*/' && _is_line_before_decl()) {
            //_document_comment(DocCommentTrigger1);commentwrap_SetNewJavadocState();return;
            //get_line_raw(auto recoverLine);
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
         //Try to handle with comment wrap.  If comment wrap
         //handled the keystroke then return.
         if (commentwrap_Enter()) {
            return;
         }
         // multi-line comment
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK) && commentwrap_Enter(true)) {
            //do nothing
         } else {
            call_root_key(ENTER);
         }
         return;
      }
      if (_in_comment(false)) {
         // single line comment

         //Check for case of '//!'
         _str line; get_line(line);
         double_slash_bang := (substr(strip(line), 1, 3) == '//!');
         commentChars := "";
         save_pos(auto before_up_down_test);
         up();
         comment_before := _in_comment(false);
         restore_pos(before_up_down_test);
         down();
         comment_after := _in_comment(false);
         restore_pos(before_up_down_test);
         int line_col = _inExtendableLineComment(commentChars, double_slash_bang);
         if (((_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS) && _will_split_insert_line()) || 
              (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS) && at_end_of_line()) ||
              (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT    ) && at_end_of_line() && !comment_before && !comment_after && strip(line) == "//!") ||
              (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT ) && at_end_of_line() && !comment_before && !comment_after && strip(line) == "///")) &&
             (line_col && p_col - line_col > 2)) {
            // check for xmldoc comment
            orig_col := p_col;
            p_col = line_col;
            triple_slash := (get_text(3)=='///' && get_text(4)!='////');
            double_slash := (get_text(2)=='//' && get_text(3)!='///' && !double_slash_bang);
            //messageNwait('Checking double slash bang');
            double_slash_bang = (get_text(3)=='//!');
            p_col = orig_col;
            if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT) &&
                triple_slash && _is_xmldoc_supported() &&
               (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) && 
                c_maybe_create_xmldoc_comment('///', true)) ) {
               CW_doccomment_nag();
               return;
            }
            if ((triple_slash || double_slash_bang) &&
               (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) && 
                c_maybe_create_xmldoc_comment(double_slash_bang ? '//!' : '///', true)) ) {
               CW_doccomment_nag();
               return;
            }
            //Try to handle with comment wrap.  If comment wrap
            //handled the keystroke then return.
            if (commentwrap_Enter()) {
               return;
            }

            indent_on_enter(0,line_col);
            if (get_text(2)!='//') {
               delimToInsert := "";
               if (double_slash_bang) {
                  delimToInsert = '//!';
               }
               else if (double_slash) {
                  delimToInsert = '//';
               }
               else if (triple_slash) {
                  delimToInsert = '///';
               } else {
                  //Get possible line comment delimiters
                  _str lineCommentDelims[];
                  if (_getLineCommentChars(lineCommentDelims)) {
                     keyin('// ');
                  } else {
                     delimToInsert = lineCommentDelims[0];
                  }
               }
               if (substr(strip(line, 'L'), delimToInsert._length() + 1, 1) == '') {
                  keyin(delimToInsert' ');
               } else {
                  keyin(delimToInsert);
               }
            }
            return;
         } 
      }
   }

   //Try to handle with comment wrap.  If comment wrap
   //handled the keystroke then return.
   if (commentwrap_Enter()) {
      return;
   }

   if (_in_string() && !_in_mlstring()) {
      if (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('java') || _LanguageInheritsFrom('kotlin')) {
         delim := "";
         int string_col = _inString(delim,false);
         if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS) &&
             string_col && p_col > string_col && _will_split_insert_line()) {
            save_pos(auto delim_pos);
            indent_on_enter(0,string_col);
            _undo('s');
            _save_pos2(auto new_pos);
            restore_pos(delim_pos);
            _insert_text(delim);
            if (_LanguageInheritsFrom('java')) _insert_text('+');
            if (_LanguageInheritsFrom('cs')) _insert_text('+');
            _restore_pos2(new_pos);
            keyin(delim);
            return;
         }
      }
   }

   if (p_indent_style!=INDENT_SMART ||_c_expand_enter()) {
       call_root_key(ENTER);
   } else if (_argument=='') {
      _undo('S');
   }
}
bool _yaml_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _r_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _r_supports_insert_begin_end_immediately() {
   return true;
}
bool _c_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _c_supports_insert_begin_end_immediately() {
   return true;
}
static int find_class_col(bool in_c = false)
{
   _str search_text = in_c ? 'class|struct|[{}]' : 'class|[{}]';
   save_pos(auto p);
   status := search(search_text,'@-rh');
   nest_level := 0;
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      int cfg=_clex_find(0,'g');
      if (nest_level>=0 || cfg!=CFG_KEYWORD) {
         ch := get_text();
         if (ch=='{') {
            --nest_level;
         } else if (ch=='}') {
            ++nest_level;
         }
         status=repeat_search();
         continue;
      }
      _first_non_blank();
      col := p_col;
      restore_pos(p);
      return(col);
   }
}
bool _c_do_colon()
{
   bool colon_is_first_char_on_line=false;
   save_pos(auto colon_p);
   {
      colon_line:=p_line;
      left();
      colon_col:=p_col;
      first_non_blank();
      colon_is_first_char_on_line=p_col==colon_col;
      restore_pos(colon_p);
   }
   if (_LanguageInheritsFrom('c') && colon_is_first_char_on_line) {
      save_pos(auto p1);
      left();
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      bool probably_constructor_initializer_list_colon;
      save_pos(auto p2);
      _isQmarkExpression(probably_constructor_initializer_list_colon);
      if (probably_constructor_initializer_list_colon &&
          beaut_should_indent_leading_cons_colon()) {
         restore_pos(p2);
         int begin_col=c_begin_stat_col(false /* No RestorePos */,
                                        false /* Don't skip first begin statement marker */,
                                        false /* Don't return first non-blank */);
         if (begin_col) {
            /*
              myclass::myclass()
                  : <-- typed constructor colon
                    m_Buffer(0),
                    m_End(0),
                    m_Count(0) {
            */
            // This is how the C++ beautifier handles this when the 
            // "indent leading constructor colon" setting is "on".
            restore_pos(colon_p);
            get_line(auto line);
            replace_line(indent_string(begin_col+p_SyntaxIndent-1):+strip(line,'L'));
            p_col=begin_col+p_SyntaxIndent+1;
            return true;
         }
      }
      restore_pos(p1);
   }
   if (p_col<=2) return(true);
   orig_col := p_col;
   left();left();
   _str word, line;
   junk := 0;
   int cfg=_clex_find(0,'g');
   get_line(line);
   _str maybe_slots,rest;
   parse line with word maybe_slots rest;
   if (cfg==CFG_KEYWORD || (line=='signals:' && _LanguageInheritsFrom('c')) ||
       ( maybe_slots=='slots:' && _LanguageInheritsFrom('c') &&
         (word=='public' || word=='private' || word=='protected') && rest==''
        )
      ) {
      word=cur_word(junk);
      if (word=='public' || word=='private' || word=='protected' ||
          word=='slots' || word=='signals'
          ) {
         if (word!='slots') {
            _first_non_blank();
            if (p_col!=orig_col-length(word)-1) {
               p_col=orig_col;
               return(true);
            }
         }
         int class_col=find_class_col(true);
         if (!class_col) {
            p_col=orig_col;
            return(true);
         }
         get_line(line);line=strip(line);
         updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
         ma_indent := beaut_member_access_indent();
         if (ma_indent > 0) {
            class_col+=ma_indent;
         }
         if (beaut_style_for_keyword('class', auto jfound) == BES_BEGIN_END_STYLE_3) {
            class_col += p_SyntaxIndent;
         }
         replace_line(indent_string(class_col-1):+strip(line,'L'));
         if (word=='slots') {
            _end_line();
         } else {
            p_col=class_col+length(word)+1;
         }

         return(false);
      }
   }

   orig_linenum := p_line;
   save_pos(auto p);
   int begin_col=c_begin_stat_col(false /* No RestorePos */,
                                  false /* Don't skip first begin statement marker */,
                                  false /* Don't return first non-blank */);
   // IF we found the beginning of this statement and it starts on
   //    the same line as the colon
   if (begin_col && p_line==orig_linenum) {
      word=cur_word(junk);
      if (word=='case' || word=='default') {
         case_offset:=_QROffset();
         updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
         _first_non_blank();
         // IF the 'case' word is the first non-blank on this line
         if (p_col==begin_col) {
            _str cur_line;
            get_line_raw(cur_line);
            int col=_c_last_switch_col(auto found_offset);
            if ( col) {
               save_pos(auto p2);
               goto_point(found_offset);
               updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
               indent_case:=beaut_case_indent();
               _c_maybe_determine_case_indent_for_this_switch_statement(auto modified_indent_case,indent_case,null,case_offset);
               restore_pos(p2);
               
               updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE | AFF_INDENT_CASE);
               col = col + indent_case;
               if (!modified_indent_case && beaut_style_for_keyword('switch', auto jfound) == BES_BEGIN_END_STYLE_3) {
                  col = col + p_SyntaxIndent;
               }
               _str new_cur_line=indent_string(col-1):+strip(cur_line,'L');
               replace_line_raw(new_cur_line);
               // adjust cursor column based on new length of line
               p_col=orig_col+length(expand_tabs(new_cur_line))-length(expand_tabs(cur_line));
            } else {
               p_col=orig_col;
            }
            return(false);
         }
      }
   }
   restore_pos(p);

   p_col=orig_col;
   return(true);
}
_command void c_colon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   keyin(':');
   if (_MultiCursorAlreadyLooping()) {
      return;
   }
   cfg := 0;
   if (!command_state()) {
      left();
      cfg=_clex_find(0,'g');
      right();
   }
   if ( command_state() || cfg == CFG_STRING) {
      return;
   } 
   if (_in_comment()) {
      tag := "";
      if (!_inDocComment() || !_inJavadocSeeTag(tag)) {
         return;
      }
   }

   if (p_SyntaxIndent >= 0) {
      if (_LanguageInheritsFrom('m') && !_objectivec_do_colon()) {
         return;
      }
      if (!_c_do_colon()) {
         return;
      }
   }
   if (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) {
      _do_list_members(OperatorTyped:true, DisplayImmediate:false);
   }
}

_command void c_pound() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key(last_event());
      return;
   }
   if ( !(_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS) || !_haveContextTagging()) {
      keyin('#');
      return;
   }
   if (_in_comment() && _inJavadocSeeTag()) {
      auto_codehelp_key();
      return;
   }
   keyin('#');
   get_line(auto line);
   if (strip(line) == '#' && (_GetCodehelpFlags() & VSCODEHELPFLAG_AUTO_LIST_MEMBERS)) {
      _do_list_members(OperatorTyped:true, DisplayImmediate:false);
   }
#if 0
   if (_in_comment()) {
      return;
   }
   c_expand_space();
#endif
}
/**
 * If the user just typed <code>/*</code> to open a multiple line comment,
 * complete the comment with <code>*/</code>.  Do not complete the comment
 * if there is text after the cursor, since they are probably trying to
 * surround something.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_asterisk() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key(last_event());
      return;
   }
   if (_in_comment() || _in_string()) {
      doInsert := false;
      if (p_col>2) {
         p_col-=2;_str temp = get_text(4);p_col+=2;
         if (temp == '/**/') {
            doInsert = true;
         }
      }
      if (doInsert) {
         _insert_text('*');
      } else {
         keyin('*');
      }
      return;
   }

   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   if ( p_col != text_col(_rawText(line))+1 ) {
      keyin('*');
      return;
   }

   if (def_auto_complete_block_comment) {
      save_pos(auto p);
      left();
      if (get_text() == '/' && search('*/','@hXcs') < 0) {
         restore_pos(p);
         _insert_text_raw('*');
         //Insert an undo step here, so user can undo just the auto insertion of '*/'
         _undo('S');
         _insert_text_raw('*/');
         p_col -= 2;
         message("Type '*/' on a subsequent line to finish this block comment.");
         return;
      }

      restore_pos(p);
   }
   keyin('*');
}

/**
 * Is the location under the cursor a reasonable place for an
 * xmlDoc style comment? 
 *  
 * @param last_slash_keyed_in Should be set to true if the last 
 *                            character of the comment delimiter
 *                            has already been keyed into the
 *                            buffer.
 */
bool c_maybe_create_xmldoc_comment(_str slcomment_start = '///', bool last_char_keyed_in = false)
{
   // save our current position
   save_pos(auto p);

   // break look for default handling
   do {

      // option is disabled
      if (slcomment_start == "//!" && !_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT   )) break;
      if (slcomment_start == "///" && !_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT)) break;

      // multiple-line comment or string?
      if (_in_comment(true) || _in_string()) break;

      // not in a single line comment?
      if (!_in_comment()) break;

      // not C#?
      if (slcomment_start == "///" && !_is_xmldoc_supported() ) break;

      // the line must start with //
      line := "";
      get_line(line);
      if ( substr(strip(line),1,2)!='//') break;

      // cursor must be at the end of line
      if ( p_col != text_col(_rawText(line))+1 ) break;

      // Don't expand over any comment text the user has typed in.
      line = strip(line, 'B');
      if ((last_char_keyed_in && line != slcomment_start)
          ||( !last_char_keyed_in && line"/" != slcomment_start))
         break;

      // the previous line can not have a comment
      up(); _end_line();
      if (_in_comment()) break;

      // the next line can not have a comment
      restore_pos(p);
      down(); _end_line();
      if (_in_comment()) break;

      // update the current context
      restore_pos(p);
      if (!_is_line_before_decl()) break;

      // finally, we are ready to lay down a really cool comment
      p_line += 1;
      _first_non_blank();
      int pc = p_col - 1;
      p_line -= 1;
      p_col = 1;
      _delete_end_line();
      _insert_text_raw(indent_string(pc));
      expand_alias(slcomment_start, '', getDocAliasProfileName(p_LangId), true);

      return true;

   } while ( false );

   // handle like normal slash
   restore_pos(p);
   return false;
}

/**
 * If they just typed <code>///</code> to open a xmlDoc comment,
 * and we are not already inside a xmlDoc comment, and the current
 * scope is outside of a function, create a skeleton xmlDoc comment.
 * <p>
 * This feature is enabled for C# only
 *
 * @see xmldoc_comment
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_slash() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   // cursor is on command line?
   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key(last_event());
      return;
   }

   // if the previous character is '*' and we are not in
   // a string or comment, then the slash should look for
   // a /**/ that needs to be fixed to create a block comment.
   int cfg = _clex_find(0,'g');
   if (p_col > 1 && get_text(1,(int)_QROffset()-1)=='*' &&
       cfg!=CFG_STRING && cfg!=CFG_COMMENT && cfg!=CFG_IMAGINARY_LINE) {

      start_line := 0;
      orig_line := p_line;
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      orig_offset := _QROffset();

      status := search('\/\*\*\/[ \t]*$','@-rhCc');
      if (!status) {
         start_line=p_line;
         p_col+=2;
         _delete_text(2);
      }

      restore_search(s1,s2,s3,s4,s5);
      if (start_line > 0) {
         _GoToROffset(orig_offset-2);
         message("Finished comment starting on line ":+start_line);
      } else {
         _GoToROffset(orig_offset);
      }

      keyin('/');
      return;
   }

   // the line must only contain the leading // of the comment
   line := "";
   get_line(line);
   if (_first_char(line) == '#' && (strip(line)!='//' || !_LanguageInheritsFrom('cs'))) {
      // handle like normal slash
      keyin('/');
      // start list members if we are on a line containing a #include
         line = strip(substr(line, 2));
         if (pos("include|import|require", line, 1, "r") == 1) {
            if (LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_ON_QUOTELT) {
               _macro_delete_line();
               _do_list_members(OperatorTyped:false, DisplayImmediate:true);
            }
         }
         return;
   }

   // see if we can create an xmlDoc comment
   if (_GetCommentEditingFlags(VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT) && c_maybe_create_xmldoc_comment('///', false)) {
      CW_doccomment_nag();
      return;
   } else {
      keyin('/');
      return;
   }
}

/**
 * (C mode only) SPACE BAR
 * <p>
 * New binding of SPACE key when in C mode.  Handles syntax expansion and indenting
 * for files with C or H extension..
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void c_space() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   // Handle Assembler embedded in C
   if (command_state()) {
      call_root_key(' ');
      return;
   }
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(last_event(), "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (_inDocComment()) {
      if (_inJavadoc() || _inDoxygenComment()) {
         if (_MultiCursorAlreadyLooping()) {
            keyin(last_event());
            return;
         }
         auto_codehelp_key();
         if (!AutoCompleteActive()) {
            c_maybe_list_javadoc();
         }
         return;
      }
   }
   do_space := false;
   if ( command_state() || !doExpandSpace(p_LangId) || p_SyntaxIndent<0 ||
      _in_comment() ||
         c_expand_space() ) {
      if ( command_state() ) {
         call_root_key(' ');
      } else {
         keyin(' '); do_space = true;
      }
   } else if (_argument=='') {
      _undo('S');
   }

   // display auto-list-paramters for completing
   // assignment statements, return statements,
   // and goto statements
   if (!command_state() && do_space) {
      if (_MultiCursorAlreadyLooping()) {
         return;
      }
      if (c_maybe_list_args(true)) {
         return;
      }
      if (c_maybe_list_javadoc()) {
         return;
      }
      // we don't do comments or strings
      if (_in_comment() || _in_string()) {
         return;
      }
      if (objectivec_space_codehelp()) {
         return;
      }
   }
}

/**
 * (C mode only) Semicolon
 * <p>
 * Handles syntax expansion for one-line if and while
 * statements.  Just type "if", then semicolon, and it
 * expands to "if (&lt;cursor here&gt;) &lt;next hotspot&gt;
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_semicolon() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key(';');
      return;
   }

   cfg := 0;
   if (p_col>1) {
      cfg=_clex_find(0,'g');
   }

   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(last_event(), "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   in_comment := _in_comment();

   if ( command_state() ||
        !LanguageSettings.getSyntaxExpansion(p_LangId) || 
        p_SyntaxIndent<0 ||
        in_comment ||
        c_expand_space()) {
      keyin(';');
      if (beautify_on_edit()
          && embedded_status != 2
          && !_in_c_preprocessing()
          && !in_comment
          && cfg != CFG_STRING) {
         cp := _QROffset();
         save_pos(auto sp1);
         prev_char(); prev_char();
         if (get_text() == '}') {
            // semi right after a }, probably a class, namespace, etc...
            find_matching_paren(true);
            prev_char();
         }
         if (c_begin_stat_col(false, false, false, true) > 0) {
            bp := _QROffset();
            if (bp < cp) {
               long markers[];
               restore_pos(sp1);
               _GoToROffset(cp);
               if (!_macro('S')) {
                  _undo('S');
               }
               new_beautify_range(bp, cp, markers, true, false, false, BEAUT_FLAG_TYPING);

               // Even when space after semicolon is enabled, we don't want to leave
               // trailing spaces all over the place.
               if (_text_colc()+1 == p_col) {
                  save_pos(sp1);
                  prev_char();
                  if (get_text_safe() != ' ') {
                     restore_pos(sp1);
                  } else {
                     _delete_char();
                  }
               }

            } else {
               restore_pos(sp1);
               _GoToROffset(cp);
            }
         } else {
            restore_pos(sp1);
            _GoToROffset(cp);
         }
      }
   } else if (_argument=='') {
      _undo('S');
   }
}

// Returns true the cursor is at a terminator for a statement
// that can be pulled into a dynamic-surround.  Cursor should
// be at the end of the statement.
bool _c_surroundable_statement_end() {
   save_pos(auto p1);
   prev_char();
   if (get_text() == '}') {
      restore_pos(p1);
      return false;
   }

   _first_non_blank();
   wrd := cur_word(auto junk);
   restore_pos(p1);

   if (wrd == 'break') {
      return true;
   }

   return false;
}

/**
 * (C mode only) Open Parenthesis
 * <p>
 * Handles syntax expansion or auto-function-help for C/C++ mode
 * and several other C-like languages.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_paren() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE|VSARG2_LASTKEY)
{
   // Called from command line?
   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key('(');
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
       !c_expand_space()) {
      return;
   }

   // not the syntax expansion case, so try function help
   auto_functionhelp_key();
}
/**
 * (C mode only) '{'
 * <p>
 * New binding of '{' key when in C mode.  When appropriate, inserts '{' at cursor,
 * inserts blank line, indents cursor on next line, and inserts another line with end brace.
 * Exact action depends on your C extension specific options.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_begin() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   if ( command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key('{');
      return;
   }
   int embedded_status=_EmbeddedStart(auto orig_values);
   if (embedded_status==1) {
      call_key(last_event(), "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }

   cfg := 0;
   if (p_col>1) {
      left();cfg=_clex_find(0,'g');right();
   }

   if ( cfg==CFG_STRING || _in_comment() ||
        c_expand_begin()) {
      call_root_key('{');
   } else if (_argument=='') {
      _undo('S');
   }

   if (beautify_on_edit()
       && embedded_status != 2
       && !_in_c_preprocessing()
       && !_in_comment()
       && cfg != CFG_STRING) {
      endpoint := _QROffset();

      save_pos(auto orig_pos);
      // Ride with {
      typeless rp;
      prev_char();
      riding_brace := get_text() == '{';

      // We ride the brace unless insertBlankLineBetweenBeginAndEnd is enabled.
      if (riding_brace) {
         save_pos(rp);
         next_char();
      } else {
         restore_pos(orig_pos);
         rp = orig_pos;
      }

      _clex_skip_blanks();
      if (get_text_safe() == '}') {
         // If we're immediately followed by the closing brace, beautify it too.
         endpoint = _QROffset();
      }

      // scoot back to where the { was inserted.
      if ( 0 == search('\{', '-r@XCS') ) {
         insert_point := _QROffset();
         if (p_col > 1) {
            left();
         } else {
            up();
            _end_line();
         }
         _clex_skip_blanks('-');
         if (c_begin_stat_col(false, false, false, true) > 0) {
            bp := _QROffset();
            if (bp < insert_point) {
               long markers[];
               restore_pos(rp);
               if (!_macro('S')) {
                  _undo('S');
               }
               new_beautify_range(bp, endpoint, markers, true, riding_brace, false, BEAUT_FLAG_TYPING|BEAUT_FLAG_AUTOBRACKET);
            } else {
               restore_pos(orig_pos);
               do_surround_mode_keys();
            }
         } else {
            restore_pos(orig_pos);
            do_surround_mode_keys();
         }
      } else {
         restore_pos(orig_pos);
         do_surround_mode_keys();
      }
   }
}

static bool handle_objc_block_end(_str line) {
   if (_LanguageInheritsFrom('m')) {
      cur_col := _text_colc(p_col, 'P');
      if (cur_col <= 1 
          || pos('^[ \t]*\}$', substr(line, 1, cur_col-1), 1, 'R') > 0) {
         // Nothing but whitespace behind us, so reindent.
         int col = c_endbrace_col();
         if (col > 0) {
            replace_line(indent_string(col-1):+strip(line));
            p_col = col + 1;
            return true;
         }
      }
   }
   return false;
}

static _c_maybe_reindent_rbrace() {
   get_line(auto line);
   if (false == handle_objc_block_end(line)
       && line=='}') {
      int col=c_endbrace_col();
      if (col) {
         replace_line(indent_string(col-1):+'}');
         p_col=col+1;
      }
   }
   _undo('S');
}


void _c_endbrace(bool inhibit_beautify=false) {
   cfg := 0;
   if (!command_state() && p_col>1) {
      left();cfg=_clex_find(0,'g');right();
   }
   keyin('}');
   if ( command_state() || cfg==CFG_STRING || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _in_comment() || _in_c_preprocessing() ) {
   } else if (!inhibit_beautify
              && beautify_on_edit()) {
      // Ride the } to the new position
      prev_char();
      save_pos(auto sp);
      endo := _QROffset();

      if (find_matching_paren(true) == 0) {
         long markers[];

         // Scan back further if it looks like control statement.
         prev_char();
         _clex_skip_blanks('-');
         if (get_text_safe() == ')') {
            find_matching_paren(true);
         }
         start := _QROffset();
         restore_pos(sp);
         if (!_macro('S')) {
            _undo('S');
         }
         new_beautify_range(start, endo, markers, true, true, false);
      } else {
         restore_pos(sp);
         next_char();
         _c_maybe_reindent_rbrace();
      }
   } else if (_argument=='') {
      _c_maybe_reindent_rbrace();
   }
}

/**
 * (C mode only) '}'
 * <pre>
 * New binding of '}' key when in C mode.  Inserts '}' at cursor and reindents the brace
 * according to your C extension specific options.  No reindenting occurs if the brace is
 * NOT being inserted into a blank line or if the brace is NOT part of an if, switch, while,
 * do, or else block.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void c_endbrace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   _c_endbrace(false);
}
static bool _c_is_special_word_followed_by_colon(_str word) {
   in_c := _LanguageInheritsFrom("c");
   in_csharp := _LanguageInheritsFrom("cs");
  return (!in_csharp && (word=='public' || word=='private' || word=='protected')) || 
       (in_c && word=='signals') || // Qt support
     (word=='case' || word=='default');
}
/*
For now, only return true if there is a label by itself possibly
followed by a comment.

Trying to handle the following works better this way:

label: foo(a,b,c,<Enter>
           d,e)

However, it doesn't handle this well:

label: foo(a,b,c)<Enter>

Maybe we could look at statement tagging to see if the statement on the label 
line is complete.

*/
static bool _in_column1_label() {
   id_chars := _clex_identifier_chars();
   save_pos(auto p);
   
   _begin_line();
   save_search(auto s1,auto s2, auto s3,auto s4,auto s5);
   status:=search('^(['id_chars']#\:([^\:]|$)|)','hr@');
   if (status || !match_length()) {
      restore_search(s1,s2, s3,s4,s5);
      restore_pos(p);
      return false;
   }
   len:=match_length();
   restore_search(s1,s2, s3,s4,s5);
   word:=cur_identifier(auto start_col);
   if (start_col!=1) {
      restore_pos(p);
      return false;
   }
   if (_c_is_special_word_followed_by_colon(word)) {
      restore_pos(p);
      return false;
   }
   p_col=len+1;
   orig_ln:=p_line;
   status=_clex_skip_blanks();
   if (status || p_line==orig_ln) {
      restore_pos(p);
      return false;
   }

   restore_pos(p);
   return true;
}
/**
 * look for beginning of statement by searching for the following
 * <PRE>
 *      '{', '}', ';', ':', 'if', 'while','switch','for', 'with' (perl)
 * </PRE>
 * <P>
 * If a non-alpha symbol is found, we look ahead for the first a non-blank
 * character that is not in a comment.
 * <P>
 * NOTE:  Calling this function for code like the following will
 *        find the beginning of the code block and not the statement:
 * <PRE>
 *    &lt;Find Here&gt;for (...) ++i&lt;Cursor Here&gt;
 *    &lt;Find Here&gt;if/while (...) ++i&lt;Cursor Here&gt;
 * </PRE>
 *
 * @param RestorePos
 * @param SkipFirstHit
 * @param ReturnFirstNonBlank
 * @param FailIfNoPrecedingText
 * @param AlreadyRecursed
 * @param FailWithMinus1_IfNoTextAfterCursor
 *
 * @return int
*/
int c_begin_stat_col(bool RestorePos,bool SkipFirstHit,bool ReturnFirstNonBlank,
                     bool FailIfNoPrecedingText=false,
                     bool AlreadyRecursed=false,
                     bool FailWithMinus1_IfNoTextAfterCursor=false,
                     bool optSemicolon_searches_for_newline=true)
{
   orig_linenum := p_line;
   orig_col := p_col;
   //ReturnCurColIfCursorBetweenOpenBraceAndEOF=1;
   in_c := _LanguageInheritsFrom("c");
   in_csharp := _LanguageInheritsFrom("cs");
   in_objectivec := _LanguageInheritsFrom('m');
   in_powershell := _LanguageInheritsFrom('powershell');
   optSemicolon := (_LanguageInheritsFrom('googlego') || _LanguageInheritsFrom('swift') || in_powershell);
   bracket_count := 0;
   check_label := false;
   if (AlreadyRecursed && get_text() == ':') {
      check_label = true;
   }
   save_pos(auto p);
   if (_in_long_line_split_into_multiples()) {
      if (ReturnFirstNonBlank) {
         _first_non_blank();
      }
      col := p_col;
      if (RestorePos) {
         restore_pos(p);
      }
      return col;
   }

   srch_str := '[{};:()\[\]]|with|elsif|elseif|if|while|lock|switch|for|foreach|foreach_reverse|using';

   if (in_objectivec) {
      srch_str :+= '|\@(class|interface|implementation|protocol|end|property|package|private|protected|public|optional|required|dynamic|synthesize|property)';
   } else if (optSemicolon && optSemicolon_searches_for_newline) {
      srch_str :+= '|\n';
   } else if (_LanguageInheritsFrom('js') || _LanguageInheritsFrom('typescript')) {
      srch_str :+= '|function';
   }

   status := search(srch_str,'-Rh@');
   nesting := 0;
   brace_nesting := 0;                                 
   hit_top := false;
   first_match := true;

   // Association from brace nesting to the paren nesting that was in effect
   // at the time the brace nesting was entered.                            
   int paren_at_brace_nesting:[];         

   paren_at_brace_nesting:[0] = 0;

   int MaxSkipPreprocessing=VSCODEHELP_MAXSKIPPREPROCESSING;
   for (;;) {
      if (status) {
         top();
         hit_top=true;
      } else {
         int cfg=_clex_find(0,'g');
         if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
            if (in_powershell && cfg==CFG_COMMENT && optSemicolon && 
                get_text():==substr(p_newline,1,1) && _powershell_treat_this_newline_like_a_semicolon()) {
            } else {
               SkipFirstHit=false;
               status=repeat_search();
               first_match = false;
               continue;
            }
         }
         // Don't indent based on labels starting in column 1
         if (get_text():==':' && _in_column1_label()) {
            //messageNwait('c_begin_stat_col skipped label');
            _begin_line();
            SkipFirstHit=false;
            status=repeat_search();
            first_match = false;
            continue;
         }
         if (in_powershell && optSemicolon && get_text():==substr(p_newline,1,1) && !_powershell_treat_this_newline_like_a_semicolon()) {
            status=repeat_search();
            continue;
         }
         switch (get_text()) {
         case '(':
            FailIfNoPrecedingText=false;
            if (nesting>0) {
               --nesting;
            }
            SkipFirstHit=false;
            status=repeat_search();
            first_match = false;
            continue;
         case ')':
            FailIfNoPrecedingText=false;
            ++nesting;
            SkipFirstHit=false;
            status=repeat_search();
            first_match = false;
            continue;
         case '[':
            if (in_objectivec) {
               --bracket_count;
            }
            status=repeat_search();
            first_match = false;
            continue;
         case ']':
            if (in_objectivec) {
               ++bracket_count;
            }
            status=repeat_search();
            first_match = false;
            continue;
         case '@':
            if (in_objectivec && cfg == CFG_KEYWORD) {
               if (first_match) {
                  _clex_find_start();
               } else {
                  next_word();
               }
            }
            break;

         case '}':
            brace_nesting++;
            paren_at_brace_nesting:[brace_nesting] = nesting;
            break;

         case '{':
            if (paren_at_brace_nesting:[brace_nesting] != nesting) {
               // We've exited a matched {} pair, and the paren nesting
               // changed somewhere inside of it.  Which probably 
               // means a mismatched paren.  Worst case, mismatched parens 
               // or braces can kick us all the way to the top of the file, so 
               // we respond here with an error.
               restore_pos(p);
               return p_col;
            }
            if (brace_nesting > 0) {
               brace_nesting--;
            }
            break;

         }
         first_match = false;
         if (SkipFirstHit || nesting || (bracket_count > 0)) {
            FailIfNoPrecedingText=false;
            SkipFirstHit=false;
            status=repeat_search();
            continue;
         }
         if (_in_c_preprocessing()) {
            --MaxSkipPreprocessing;
            if (MaxSkipPreprocessing<=0) {
               status=STRING_NOT_FOUND_RC;
               continue;
            }
            SkipFirstHit=false;
            begin_line();
            status=repeat_search();
            continue;
         }

         ch := get_text();
         if (!AlreadyRecursed && ch:==':') {
            save_pos(auto p2);
            if (p_col!=1) {
               left();
               // IF we are seeing  classname::name
               if (get_text()==':') {
                  status=repeat_search();
                  continue;
               }
               right();
            }
            int col = c_begin_stat_col(false,true,false,false,true);
            _str word = cur_word(auto junk);
            ch = get_text();
            if (in_objectivec && (ch == '[' || ch == '-' || ch == '+')) {
               // valid for objective-c, early-out

            } else if (_c_is_special_word_followed_by_colon(word)) {
               restore_pos(p2);
               right();
            }
         } else {
            /*
                Handle where constraint case for csharp.  Need to go back to beginning of class definition.
                The only down side to doing this is that if the constraints are on multiple lines we will
                indent back to the "where" column.  This is not a likely case so we can forget about it.

                class myclass<a>
                    where a: constraint1,constraint2,constraint3
                    where b: constraint1,constraint2,constraint3
            */
            if (AlreadyRecursed && ch:==':') {
               if (in_csharp) {
                  _str line, word, more;
                  get_line(line);
                  parse line with word more':';
                  if (word=='where') {
                     status=repeat_search();
                     continue;
                  }
               } else {
                  if (p_col!=1) {
                     left();
                     // IF we are seeing  classname::name
                     if (get_text()==':') {
                        status=repeat_search();
                        continue;
                     }
                     right();
                  }
                  if (in_objectivec) {
                     if (check_label) {
                        // could be in label, access modifier, or objc method call
                        save_pos(auto p2);
                        right();
                        status = _clex_skip_blanksNpp();
                        if (!status) {
                           _str word = cur_word(auto junk);
                           cfg = _clex_find(0,'g');
                           if (cfg != CFG_COMMENT && cfg != CFG_STRING) {
                              if ((cfg == CFG_KEYWORD && (word=='public' || word=='private' || word=='protected' || word=='case' || word=='default')) ||
                                  (in_c && word=='signals')) {
                                 col := p_col;
                                 if (RestorePos) {
                                    restore_pos(p);
                                 }
                                 return(col);
                              }
                           }
                        }
                        restore_pos(p2);
                     }
                     check_label = true; // repeat check??
                     status=repeat_search();
                     continue;
                  }
               }
            }
            if (isalpha(ch)) {
               if(cfg!=CFG_KEYWORD) {
                  if (cfg!=CFG_STRING && cfg!=CFG_COMMENT) {
                     FailIfNoPrecedingText=false;
                  }
                  status=repeat_search();
                  continue;
               } else {
                  wd := cur_identifier(auto wcol);
                  if (_LanguageInheritsFrom('js') && wd == 'function') {
                     // may be preceded by async.
                     save_pos(auto sp);
                     begin_word();prev_word();
                     wd = cur_identifier(wcol);
                     if (wd == 'async') {
                        p_col = wcol;
                     } else {
                        restore_pos(sp);
                     }
                  }
               }
            } else {
               right();
            }
         }
      }
      status=_clex_skip_blanksNpp('',true);
      if (status) {
         restore_pos(p);
         /*
             Would could have an open brace followed by blanks and eof.
         */
         if (!hit_top) {
            if (!FailWithMinus1_IfNoTextAfterCursor) {
               return(p_col);
            }
            return(-1);
         }
         return(0);
      }
      /*
          We could have the following:

            class name:public name2 {

          recurse to look for "case" keyword

      */
      if (ReturnFirstNonBlank) {
         _first_non_blank();
      }
      col := p_col;
      if (hit_top && FailIfNoPrecedingText && (p_line>orig_linenum || (p_line==orig_linenum)&& p_col>orig_col)) {
         return(0);
      }
      if (RestorePos) {
         restore_pos(p);
      }
      return(col);
   }

}

/**
 * On entry, the cursor is sitting on a } (close brace)
 * <PRE>
 * static void
 *    main () /* this is a test */ {
 * }
 * static void main /* this is a test */
 *   ()
 * {
 * }
 * </PRE>
 *
 * @param be_style  begin-end brace style
 * <PRE>
 * for (;;) {     for (;;)        for (;;)
 *                {                  {
 *                }                  }
 * }
 * style 0        style 1         style 2
 * </PRE>
 *
 * @return
 * Returns column where end brace should go.
 * Returns 0 if this function does not know the column where the
 * end brace should go.
*/
int c_endbrace_col()
{
   updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE);
   style3_MustBackIndent := false;
   return(c_endbrace_col2(p_begin_end_style,style3_MustBackIndent));
}
int c_endbrace_col2(int be_style, bool &style3_MustBackIndent)
{
   style3_MustBackIndent=false;
   if (p_lexer_name=='') {
      return(0);
   }
   save_pos(auto p);
   --p_col;
   // Find matching begin brace
   int status=_find_matching_paren(def_pmatch_max_diff_ksize);
   if (status) {
      restore_pos(p);
      return(0);
   }
   // Assume end brace is at level 0
   if (p_col==1) {
      restore_pos(p);
      return(1);
   }
   save_pos(auto p2);
   begin_brace_col := p_col;
   // Check if the first char before open brace is close paren
   int col= find_block_col();
   if (!col) {
      restore_pos(p2);
      if (_isVarInitList(true,auto indent_from_col)) {
         restore_pos(p2);
         if (indent_from_col) {
            col=indent_from_col;
         } else {
            _first_non_blank();
            col=p_col;
         }
         restore_pos(p);
         return(col);
      }
      restore_pos(p2);
#if 0
      if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
         // check if this parenthesis is on a line by itself;
         get_line(line);
         if (line=="{") {
            style3_MustBackIndent=true;
            first_non_blank();
            col=p_col;
            restore_pos(p);
            return(col);
         }
      }
#endif
      col=c_begin_stat_col(true,true,true);
      restore_pos(p);
      if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
         style3_MustBackIndent=true;
         col+=p_SyntaxIndent;
      }
      return(col);
   }
   style3_MustBackIndent=true;
   if (be_style == BES_BEGIN_END_STYLE_3) {
      restore_pos(p);
      //return(begin_brace_col);
      return(col+p_SyntaxIndent);
   }
   restore_pos(p);
   return(col);
}
/**
 * This function behaves much like _clex_skip_blanks(), but
 * it does not support embedded code sections.  It also does
 * not support the 'c' option.
 *
 * @param options
 * @param clex_options
 *
 * @return  Returns 0 if non-blank character is found, nonzero otherwise.
 * If this functions fails the cursor is moved but its final location may
 * not be the top or bottom of the buffer (we need to change this should
 * be more concrete).
 *
 * @deprecated Use {@link _clex_skip_blanks()} with the 'q' option
 */
int _clex_skip_blanks_quick(_str options='',_str clex_options='n')
{
   return _clex_skip_blanks(options:+clex_options:+"q");

   /*
   search_options := '@rh':+options;
   for (;;) {
      // search for non-blank character
      status := search('[~ \t\r\n]',search_options);
      if (status) return(1);
      if (p_lexer_name!='' && _clex_find(0,'g')==CFG_COMMENT) {
         status=_clex_find(COMMENT_CLEXFLAG,clex_options);
         if (status) {
            /* This changes was made for select_proc() */
            if (pos('-',options)) {
               top();
            } else {
               bottom();
            }
            return(1);
         }
         continue;
      }
      return(0);
   }
   */
}

/**
 * Translates the reults of a _clex_find(0,'g') into one of the
 * CFG_&lt;&gt; constants that can be used in a subsequent _clex_find() call.
 *
 * @param clexflags
 *
 * @return
 */
int _clex_translate(int clexflags)
{
   switch (clexflags) {
   case CFG_KEYWORD:
      return(KEYWORD_CLEXFLAG);
   case CFG_LINENUM:
      return(LINENUM_CLEXFLAG);
   case CFG_NUMBER:
      return(NUMBER_CLEXFLAG);
   case CFG_STRING:
      return(STRING_CLEXFLAG);
   case CFG_COMMENT:
      return(COMMENT_CLEXFLAG);
   case CFG_PPKEYWORD:
      return(PPKEYWORD_CLEXFLAG);
   case CFG_PUNCTUATION:
      return(SYMBOL1_CLEXFLAG);
   case CFG_LIBRARY_SYMBOL:
      return(SYMBOL2_CLEXFLAG);
   case CFG_OPERATOR:
      return(SYMBOL3_CLEXFLAG);
   case CFG_USER_DEFINED:
      return(SYMBOL4_CLEXFLAG);
   case CFG_FUNCTION:
      return(FUNCTION_CLEXFLAG);
   default :
      return(OTHER_CLEXFLAG);
   }
}

/**
 * Given the current color coding element, this function places
 * the cursor on the first character of that element.
 *
 * @return Returns 0 if successful.
 */
int _clex_find_start()
{
   typeless p; save_pos(p);
   int clexflags=_clex_find(0,'g');
   if (!clexflags) {
      return(1);
   }
   clexflags = _clex_translate(clexflags);
   int status=_clex_find(clexflags,'n-');
   if (status) {
      top();
   }
   status=_clex_find(clexflags);
   if (status) {
      // this should not happen, but just in case
      restore_pos(p);
      return(1);
   }
   return(0);
}

/**
 * Given the current color coding element, this function places the cursor on the
 * last character of that element.
 *
 * @return Returns 0 if successful.
 */
int _clex_find_end()
{
   save_pos(auto p);
   int clexflags=_clex_find(0,'g');
   if (!clexflags) {
      return(1);
   }
   clexflags = _clex_translate(clexflags);
   int status=_clex_find(clexflags,'n');
   if (status) {
      bottom();
   }
   status=_clex_find(clexflags,'o-');
   if (status) {
      // this should not happen, but just in case
      restore_pos(p);
      return(1);
   }
   return(0);
}

/**
 * @return Returns a SlickEdit regular expression for
 * matching an identifier, as specified by the color
 * coding engine.
 *
 * @see p_identifier_chars
 * @see _clex_identifier_chars()
 * @see _clex_is_identifier_char()
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Editor_Control_Methods, Edit_Window_Methods
 */
_str _clex_identifier_re()
{
   _str identifierChars = p_identifier_chars;
   if (p_EmbeddedLexerName != '') {
      identifierChars = p_EmbeddedIdentifierChars;
   }

   // p_identifier_chars contains start chars, then end chars
   // example:  a-zA-z 0-9
   parse identifierChars with auto startch auto endch;
   startch = strip(startch);

   // no end chars?
   if (endch=='') {
      // match one or more start characters
      return "["startch"]#";
   }

   // match the start character followed
   // by zero or more ends
   endch = strip(endch);
   return "["startch"]["startch:+endch"]@";
}
/**
 * @return Returns a SlickEdit regular expression for
 * matching a character which is not part of an
 * identifier, as specified by the color coding engine.
 *
 * @see p_identifier_chars
 * @see _clex_identifier_chars()
 * @see _clex_identifier_re()
 * @see _clex_is_identifier_char()
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Editor_Control_Methods, Edit_Window_Methods
 */
_str _clex_identifier_notre()
{
   _str identifierChars = p_identifier_chars;
   if (p_EmbeddedLexerName != '') {
      identifierChars = p_EmbeddedIdentifierChars;
   }

   // p_identifier_chars contains start chars, then end chars
   // example:  a-zA-z 0-9
   parse identifierChars with auto startch auto endch;
   startch = strip(startch);
   endch = strip(endch);
   return "[^"startch:+endch"]";
}
bool _clex_is_simple_keyword(int handle,int node) {
   int attrs_node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   doAdd := false;
   if (attrs_node>=0) {
      // check for attrs node with no attributes
      while (attrs_node>=0) {
         // Found simple attrs node.
         _str value;
         value=_xmlcfg_get_attribute(handle,attrs_node,'end');
         if (value:=='') {
            value=_xmlcfg_get_attribute(handle,attrs_node,'color_to_eol');
            if (value:=='') {
               value=' '_xmlcfg_get_attribute(handle,attrs_node,'flags')' ';
               if (!pos(' regex ',value) && !pos(' perlre ',value) && !pos(' check_first ',value) && !pos(' first_non_blank ',value) 
                   &&  _xmlcfg_get_attribute(handle,attrs_node,'start_col'):=='') {
                  value='';
               }
            }
         }
         if (value:=='') {
            doAdd=true;
         }
         attrs_node=_xmlcfg_get_next_sibling(handle,attrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
   } else {
      doAdd=true;
   }
   return doAdd;
}
bool _clex_has_non_regex(int handle,int node) {
   int attrs_node=_xmlcfg_get_first_child(handle,node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
   doAdd := false;
   if (attrs_node>=0) {
      // check for attrs node with no attributes
      while (attrs_node>=0) {
         value:=' '_xmlcfg_get_attribute(handle,attrs_node,'flags')' ';
         if (!pos(' regex ',value) && !pos(' perlre ',value) /*&& !pos(' check_first ',value) && !pos(' first_non_blank ',value) 
             &&  _xmlcfg_get_attribute(handle,attrs_node,'start_col'):==''*/ ) {
            value='';
         }
         if (value:=='') {
            doAdd=true;
         }
         attrs_node=_xmlcfg_get_next_sibling(handle,attrs_node,VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
      }
   } else {
      doAdd=true;
   }
   return doAdd;
}
/**
 * @return Returns an expression containing all the
 *         identifier chars as specified by the color
 *         coding engine.  The results of this function
 *         are intended to be a drop-in replacement
 *         for p_word_chars.
 *
 * @see _clex_identifier_re()
 * @see _clex_identifier_notre()
 * @see _clex_is_identifier_char()
 * @see p_identifier_chars
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Editor_Control_Methods, Edit_Window_Methods
 */
_str _clex_identifier_chars()
{
   _str identifierChars = p_identifier_chars;
   if (p_EmbeddedLexerName != '') {
      identifierChars = p_EmbeddedIdentifierChars;
   }
   return stranslate(identifierChars,'',' ');
}
/**
 * @return Returns true if the given character is an identifier char
 *         as specified by the color coding engine.
 *
 * @param ch   character to test
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Editor_Control_Methods, Edit_Window_Methods
 */
bool _clex_is_identifier_char(_str ch)
{
   _str identifierChars = p_identifier_chars;
   if (p_EmbeddedLexerName != '') {
      identifierChars = p_EmbeddedIdentifierChars;
   }

   // p_identifier_chars contains start chars, then end chars
   // example:  a-zA-z 0-9
   parse identifierChars with auto startch auto endch;
   startch = strip(startch);
   endch = strip(endch);
   return (length(ch)==1 && pos("["startch:+endch"]", ch, 1, 'r') == 1);
}
bool _clex_is_identifier_start_char(_str ch)
{
   _str identifierChars = p_identifier_chars;
   if (p_EmbeddedLexerName != '') {
      identifierChars = p_EmbeddedIdentifierChars;
   }

   // p_identifier_chars contains start chars, then end chars
   // example:  a-zA-z 0-9
   parse identifierChars with auto startch auto endch;
   startch = strip(startch);
   endch = strip(endch);
   return (length(ch)==1 && pos("["startch"]", ch, 1, 'r') == 1);
}

static int find_block_col()
{
   _str word;
   col := 0;
   --p_col;
   if (_clex_skip_blanks('-')) return(0);
   if (_LanguageInheritsFrom('powershell') && get_text():==']') {
      status:=_find_matching_paren(def_pmatch_max_diff_ksize);
      for (;;) {
         if (status) {
            return 0;
         }
         save_pos(auto p3);
         if (p_col==1) { up();_end_line(); } else { left(); }
         _clex_skip_blanksNpp('-');
         //messageNwait(']');
         if (get_text():!=',') {
            restore_pos(p3);
            break;
         }
         if (p_col==1) { up();_end_line(); } else { left(); }
         _clex_skip_blanksNpp('-');
         if (get_text():!=']') {
            restore_pos(p3);
            break;
         }
         status=_find_matching_paren(def_pmatch_max_diff_ksize);
      }
   } else if (get_text()!=')') {
      if (p_LangId == 'c' && lambda_decl_before_cursor()) {
         search('\{', 'U@');
         return p_col;
      }

      if (_clex_find(0,'g')!=CFG_KEYWORD) {
         return(0);
      }
      word=cur_word(col);
      if (word=='do' || word=='else') {
         _first_non_blank();
         return(p_col);
         //return(p_col-length(word)+1);
      }
      return(0);
   } else {
      // Here we match round parens. ()
      int status=_find_matching_paren(def_pmatch_max_diff_ksize);
      if (status) return(0);
   }
   if (p_col==1) return(1);
   --p_col;

   if (_clex_skip_blanks('-')) return(0);
   /*if (_clex_find(0,'g')!=CFG_KEYWORD) {
      return(0);
   }
   */
   if (p_LangId == 'c' && get_text() == ']') {
      // Our friend, the lambda.  Passed it.
      search('\{', 'U@');
      return p_col;
   }
   word=cur_word(col);
   cfg:=_clex_find(0,'g');
   if (cfg==CFG_KEYWORD && pos(' 'word' ',' with for foreach foreach_reverse if elsif elseif switch while lock using trap catch ')) {
      _first_non_blank();
      return(p_col);
      //return(p_col-length(word)+1);
   } else if (_LanguageInheritsFrom('java')) {
      // Check if we have a new construct
      p_col=_text_colc(col,'I');
      if (p_col>1) {
         left();
         if (_clex_skip_blanks('-')) return(0);
         word=cur_word(col);
         if (word=='new') {
            p_col=_text_colc(col,'I');
            col=p_col;
            _first_non_blank();
            if (col!=p_col) {
               p_col+=p_SyntaxIndent;
            }
            return(p_col);
         }
      }
   }
   return(0);
}
static const EXPAND_WORDS= (' #define #elif #else #endif #error #if #ifdef #ifndef':+
                ' #include #pragma #undef #note #todo #warning #fatal #region #endregion':+
                ' else enum typedef static struct class' :+
                ' union public private protected ');

static const JAVA_ONLY_EXPAND_WORDS= ' final import int interface package synchronized ';
static const CS_ONLY_EXPAND_WORDS= ' ';
static const IDL_ONLY_EXPAND_WORDS= ' attribute in inout ';
static const PHP_ONLY_EXPAND_WORDS= ' import ';

static SYNTAX_EXPANSION_INFO c_semicolon_words:[] = {
   'for'              => { "for ( ... ) { ... }" },
   'if'               => { "if  ... ) { ... }" },
   'while'            => { "while ( ... ) { ... }" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'break'            => { "break" },
   'continue'         => { "continue" },
   'return'           => { "return" },
   'co_return'        => { "co_return" },
   'co_yield'         => { "co_yield" },
};

static SYNTAX_EXPANSION_INFO cpp_space_words:[] = {
   '#define'          => { "#define" },
   '#elif'            => { "#elif" },
   '#else'            => { "#else" },
   '#endif'           => { "#endif" },
   '#error'           => { "#error" },
   '#warning'         => { "#warning" },
   '#fatal'           => { "#fatal" },
   '#if'              => { "#if" },
   '#ifdef'           => { "#ifdef" },
   '#ifndef'          => { "#ifndef" },
   '#include'         => { "#include" },
   '#pragma'          => { "#pragma" },
   '#note'            => { "#note" },
   '#todo'            => { "#todo" },
   '#undef'           => { "#undef" },
   '#region'          => { "#region" },
   '#endregion'       => { "#endregion" },
   'break'            => { "break;" },
   'case'             => { "case" },
   'catch'            => { "catch ( ... ) { ... }" },
   'class'            => { "class" },
   'const'            => { "const" },
   'constexpr'        => { "constexpr" },
   'consteval'        => { "consteval" },
   'constinit'        => { "constinit" },
   'const_cast'       => { "const_cast < ... > ( ... )" },
   'continue'         => { "continue;" },
   'default'          => { "default:" },
   'do'               => { "do { ... } while ( ... );" },
   'dynamic_cast'     => { "dynamic_cast < ... > ( ... )" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'enum'             => { "enum" },
   'export'           => { "export" },
   'extern'           => { "extern" },
   'for'              => { "for ( ... ) { ... }" },
   'if'               => { "if  ... ) { ... }" },
   'import'           => { "import" },
   'main'             => { "main(int argc, char *argv[]) { ... }" },
   'module'           => { "module" },
   'printf'           => { "printf(\"" },
   'private'          => { "private:" },
   'protected'        => { "protected:" },
   'public'           => { "public:" },
   'reinterpret_cast' => { "reinterpret_cast < ... > ( ... )" },
   'return'           => { "return" },
   'co_await'         => { "co_await" },
   'co_return'        => { "co_return" },
   'co_yield'         => { "co_yield" },
   'static'           => { "static" },
   'static_cast'      => { "static_cast < ... > ( ... )" },
   'struct'           => { "struct" },
   'switch'           => { "switch ( ... ) { ... }" },
   'template'         => { "template < ... >" },
   'try'              => { "try { ... } catch ( ... ) { ... }" },
   'typedef'          => { "typedef" },
   'union'            => { "union" },
   'while'            => { "while ( ... ) { ... }" },

   '@catch'           => { "@catch" },
   '@class'           => { "@class ... @end" },
   '@defs'            => { "@defs" },
   '@dynamic'         => { "@dynamic" },
   '@encode'          => { "@encode" },
   '@end'             => { "@end" },
   '@finally'         => { "@finally" },
   '@implementation'  => { "@implementation ... @end" },
   '@interface'       => { "@interface ... @end" },
   '@package'         => { "@package" },
   '@private'         => { "@private" },
   '@property'        => { "@property" },
   '@protected'       => { "@protected" },
   '@protocol'        => { "@protocol ... @end" },
   '@public'          => { "@public" },
   '@selector'        => { "@selector" },
   '@synchronized'    => { "@synchronized" },
   '@synthesize'      => { "@synthesize" },
   '@throw'           => { "@throw" },
   '@try'             => { "@try" },
};

static _str else_space_words[] = { 'else', 'else if' };

static SYNTAX_EXPANSION_INFO r_space_words:[] = {
   'break'            => { "break;" },
   'next'             => { "next;" },
   'repeat'           => { "repeat { ... }" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'for'              => { "for ( ... ) { ... }" },
   'if'               => { "if  ... ) { ... }" },
   //'return'           => { "return" },
   'while'            => { "while ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO cs_space_words:[] = {
   '#define'      => { "#define" },
   '#elif'        => { "#elif" },
   '#else'        => { "#else" },
   '#endif'       => { "#endif" },
   '#endregion'   => { "#endregion" },
   '#error'       => { "#error" },
   '#if'          => { "#if" },
   '#ifdef'       => { "#ifdef" },
   '#ifndef'      => { "#ifndef" },
   '#include'     => { "#include" },
   '#pragma'      => { "#pragma" },
   '#region'      => { "#region" },
   '#undef'       => { "#undef" },
   '#note'        => { "#note" },
   '#todo'        => { "#todo" },
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'default'      => { "default:" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'enum'         => { "enum" },
   'else if'      => { "else if ( ... ) { ... }" },
   'finally'      => { "finally { ... }" },
   'fixed'        => { "fixed" },
   'for'          => { "for ( ... ) { ... }" },
   'foreach'      => { "foreach ( ... ) { ... }" },
   'if'           => { "if ( ... ) { ... }" },
   'int'          => { "int" },
   'interface'    => { "interface" },
   'lock'         => { "lock ( ... ) { ... }" },
   'main'         => { "public static void Main (string []args) { ... }" },
   'private'      => { "private" },
   'protected'    => { "protected" },
   'public'       => { "public" },
   'return'       => { "return" },
   'struct'       => { "struct" },
   'switch'       => { "switch ( ... ) { ... }" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'union'        => { "union" },
   'using'        => { "using" },
   'while'        => { "while ( ... ) { ... }" },
   'yield'        => { "yield" },
};
static SYNTAX_EXPANSION_INFO java_space_words:[] = {
   '#define'      => { "#define" },
   '#elif'        => { "#elif" },
   '#else'        => { "#else" },
   '#endif'       => { "#endif" },
   '#error'       => { "#error" },
   '#if'          => { "#if" },
   '#ifdef'       => { "#ifdef" },
   '#ifndef'      => { "#ifndef" },
   '#include'     => { "#include" },
   '#pragma'      => { "#pragma" },
   '#undef'       => { "#undef" },
   '#note'        => { "#note" },
   '#todo'        => { "#todo" },
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'default'      => { "default:" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'enum'         => { "enum" },
   'for'          => { "for ( ... ) { ... }" },
   'if'           => { "if ( ... ) { ... }" },
   'int'          => { "int" },
   'interface'    => { "interface" },
   'main'         => { "public static void main (String args[]) { ... }" },
   'package'      => { "package" },
   'private'      => { "private" },
   'protected'    => { "protected" },
   'public'       => { "public" },
   'return'       => { "return" },
   'switch'       => { "switch ( ... ) { ... )" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'while'        => { "while ( ... ) { ... }" },
   'else if'      => { "else if ( ... ) { ... }" },
   'static'       => { "static" },
   '@interface'   => { "@interface" },
   'final'        => { "final" },
   'finally'      => { "finally" },
   'import'       => { "import" },
   'var'          => { "var" },
   'yield'        => { "yield" },
};

static SYNTAX_EXPANSION_INFO groovy_space_words:[] = {
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'enum'         => { "enum" },
   'for'          => { "for ( ... ) { ... }" },
   'if'           => { "if ( ... ) { ... }" },
   'int'          => { "int" },
   'interface'    => { "interface" },
   'main'         => { "public static void main (String args[]) { ... }" },
   'package'      => { "package" },
   'private'      => { "private" },
   'protected'    => { "protected" },
   'public'       => { "public" },
   'return'       => { "return" },
   'switch'       => { "switch ( ... ) { ... )" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'while'        => { "while ( ... ) { ... }" },
   'else if'      => { "else if ( ... ) { ... }" },
   'static'       => { "static" },
   '@interface'   => { "@interface" },
   'final'        => { "final" },
   'finally'      => { "finally" },
   'import'       => { "import" },
   'trait'        => { "trait" }, 
};
static SYNTAX_EXPANSION_INFO kotlin_space_words:[] = {
   'break'            => { "break" },
   'catch'            => { "catch ( ... ) { ... }" },
   'class'            => { "class" },
   'continue'         => { "continue;" },
   'do'               => { "do { ... } while ( ... );" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'enum'             => { "enum" },
   'for'              => { "for ( ... ) { ... }" },
   'finally'          => { "finally" },
   'if'               => { "if  ... ) { ... }" },
   'import'           => { "import" },
   //'main'             => { "main(int argc, char *argv[]) { ... }" },
   //'printf'           => { "printf(\"" },
   'package'          => { "package" },
   'private'          => { "private" },
   'protected'        => { "protected" },
   'public'           => { "public" },
   'return'           => { "return" },
   'when'             => { "when ( ... ) { ... }" },
   'try'              => { "try { ... } catch ( ... ) { ... }" },
   'typealias'        => { "typealias" },
   'while'            => { "while ( ... ) { ... }" },

};

// Since we don't support context tagging, don't want many expansions
// because "i<space>=" could be expanded to if when the user has a local variable by that name.
static SYNTAX_EXPANSION_INFO rust_space_words:[] = {
   ///'break'        => { "break;" },
   'match'         => { "match" },
   //'catch'        => { "catch ( ... ) { ... }" },
   //'class'        => { "class" },
   ///'continue'     => { "continue;" },
   //'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   ///'enum'         => { "enum" },
   'for'          => { "for ... { ... }" },
   'if'           => { "if ... { ... }" },
   //'int'          => { "int" },
   //'interface'    => { "interface" },
   'loop'           => { "loop { ... }" },
   'main'         => { "fn main() { ... }" },
   'match'           => { "match ... { ... }" },
   //'package'      => { "package" },
   //'private'      => { "private" },
   //'protected'    => { "protected" },
   //'public'       => { "public" },
   ///'return'       => { "return" },
   //'switch'       => { "switch ( ... ) { ... )" },
   ///'trait'        => { "trait" }, 
   //'try'          => { "try { ... } catch ( ... ) { ... }" },
   'while'        => { "while ... { ... }" },
   //'else if'      => { "else if ( ... ) { ... }" },
   ///'static'       => { "static" },
   //'@interface'   => { "@interface" },
   //'final'        => { "final" },
   //'finally'      => { "finally" },
   //'import'       => { "import" },
};

static SYNTAX_EXPANSION_INFO javascript_space_words:[] = {
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'default'      => { "default:" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'else if'      => { "else if ( ... ) { ... }" },
   'finally'      => { "finally { ... }" },
   'for'          => { "for ( ... ) { ... }" },
   'if'           => { "if ( ... ) { ... }" },
   'let'          => { "let" },
   'return'       => { "return" },
   'switch'       => { "switch ( ... ) { ... }" },
   'while'        => { "while ( ... ) { ... }" },
   'export'       => { "export" },
   'function'     => { "function" },
   'import'       => { "import" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'var'          => { "var" },
   'with'         => { "with ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO typescript_space_words:[] = {
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'default'      => { "default" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'else if'      => { "else if ( ... ) { ... }" },
   'finally'      => { "finally { ... }" },
   'for'          => { "for ( ... ) { ... }" },
   'if'           => { "if ( ... ) { ... }" },
   'interface'    => { "interface" },
   'let'          => { "let" },
   'return'       => { "return" },
   'switch'       => { "switch ( ... ) { ... }" },
   'type'         => { "type" },
   'while'        => { "while ( ... ) { ... }" },
   'export'       => { "export" },
   'function'     => { "function" },
   'import'       => { "import" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'var'          => { "var" },
   'with'         => { "with ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO php_space_words:[] = {
   'break'        => { "break;" },
   'case'         => { "case" },
   'class'        => { "class" },
   'continue'     => { "continue;" },
   'default'      => { "default:" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'for'          => { "for ( ... ) { ... )" },
   'if'           => { "if ( ... ) { ... }" },
   'return'       => { "return" },
   'switch'       => { "switch ( ... ) { ... }" },
   'while'        => { "while ( ... ) { ... }" },
   'function'     => { "function" },
   'import'       => { "import" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'finally'      => { "finally { ... }" },
   'var'          => { "var" },
   'elseif'       => { "elseif ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO idl_space_words:[] = {
   'attribute'    => { "attribute" },
   'case'         => { "case" },
   'default'      => { "default:" },
   'exception'    => { "exception ... { ... }" },
   'in'           => { "in" },
   'inout'        => { "inout" },
   'interface'    => { "interface ... { ... }" },
   'module'       => { "module ... { ... }" },
   'sequence'     => { "sequence < ... >" },
   'struct'       => { "struct ... { ... }" },
   'switch'       => { "switch ( ... ) { ... }" },
   'typedef'      => { "typedef" },
   'union'        => { "union ... { ... }" },
};

static SYNTAX_EXPANSION_INFO d_space_words:[] = {
   'abstract'     => { "abstract" },
   'alias'        => { "alias" },
   'assert'       => { "assert" },
   'auto'         => { "auto" },
   'body'         => { "body { ... }" },
   'bool'         => { "bool" },
   'byte'         => { "byte" },
   'break'        => { "break;" },
   'case'         => { "case" },
   'catch'        => { "catch ( ... ) { ... }" },
   'class'        => { "class" },
   'const'        => { "const" },
   'continue'     => { "continue;" },
   'debug'        => { "debug ( ... ) { ... }" },
   'default'      => { "default:" },
   'deprecated'   => { "deprecated" },
   'delegate'     => { "delegate" },
   'do'           => { "do { ... } while ( ... );" },
   'else'         => { "else { ... }" },
   'enum'         => { "enum { ... }" },
   'else if'      => { "else if ( ... ) { ... }" },
   'final'        => { "final" },
   'finally'      => { "finally { ... }" },
   'fixed'        => { "fixed" },
   'for'          => { "for ( ... ) { ... }" },
   'foreach'      => { "foreach ( ... ) { ... }" },
   'foreach_reverse' => { "foreach_reverse ( ... ) { ... }" },
   'function'     => { "function" },
   'if'           => { "if ( ... ) { ... }" },
   'import'       => { "import" },
   'in'           => { "in { ... }" },
   'int'          => { "int" },
   'interface'    => { "interface" },
   'invariant'    => { "invariant { ... }" },
   'main'         => { "void main (char[][] args) { ... }" },
   'mixin'        => { "mixin" },
   'module'       => { "module" },
   'out'          => { "out { ... }" },
   'override'     => { "override" },
   'package'      => { "package" },
   'private'      => { "private" },
   'protected'    => { "protected" },
   'public'       => { "public" },
   'return'       => { "return" },
   'struct'       => { "struct" },
   'switch'       => { "switch ( ... ) { ... }" },
   'synchronized' => { "synchronized" },
   'super'        => { "super" },
   'template'     => { "template  ( ... ) { ... }" },
   'try'          => { "try { ... } catch ( ... ) { ... }" },
   'typeid'       => { "typeid" },
   'typeof'       => { "typeof" },
   'typedef'      => { "typedef" },
   'union'        => { "union  { ... }" },
   'unittest'     => { "unittest { ... }" },
   'version'      => { "version ( ... ) { ... }" },
   'volatile'     => { "volatile" },
   'while'        => { "while ( ... ) { ... }" },
   'with'         => { "with ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO ansic_space_words:[] = {
   '#define'          => { "#define" },
   '#elif'            => { "#elif" },
   '#else'            => { "#else" },
   '#endif'           => { "#endif" },
   '#error'           => { "#error" },
   '#warning'         => { "#warning" },
   '#fatal'           => { "#fatal" },
   '#if'              => { "#if" },
   '#ifdef'           => { "#ifdef" },
   '#ifndef'          => { "#ifndef" },
   '#include'         => { "#include" },
   '#pragma'          => { "#pragma" },
   '#note'            => { "#note" },
   '#todo'            => { "#todo" },
   '#undef'           => { "#undef" },
   '#region'          => { "#region" },
   '#endregion'       => { "#endregion" },

   'break'            => { "break;" },
   'case'             => { "case" },
   'catch'            => { "catch ( ... ) { ... }" },
   'continue'         => { "continue;" },
   'default'          => { "default:" },
   'do'               => { "do { ... } while ( ... );" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'enum'             => { "enum" },
   'for'              => { "for ( ... ) { ... }" },
   'if'               => { "if ( ... ) { ... }" },
   'main'             => { "main(int argc, char *argv[]) { ... }" },
   'printf'           => { "printf(\"" },
   'return'           => { "return" },
   'struct'           => { "struct" },
   'switch'           => { "switch ( ... ) { ... }" },
   'typedef'          => { "typedef" },
   'union'            => { "union" },
   'while'            => { "while ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO objc_space_words:[] = {
   '#define'          => { "#define" },
   '#elif'            => { "#elif" },
   '#else'            => { "#else" },
   '#endif'           => { "#endif" },
   '#error'           => { "#error" },
   '#warning'         => { "#warning" },
   '#fatal'           => { "#fatal" },
   '#if'              => { "#if" },
   '#ifdef'           => { "#ifdef" },
   '#ifndef'          => { "#ifndef" },
   '#include'         => { "#include" },
   '#pragma'          => { "#pragma" },
   '#note'            => { "#note" },
   '#todo'            => { "#todo" },
   '#undef'           => { "#undef" },
   '#region'          => { "#region" },
   '#endregion'       => { "#endregion" },

   '@catch'           => { "@catch" },
   '@class'           => { "@class ... @end" },
   '@defs'            => { "@defs" },
   '@dynamic'         => { "@dynamic" },
   '@encode'          => { "@encode" },
   '@end'             => { "@end" },
   '@finally'         => { "@finally" },
   '@implementation'  => { "@implementation ... @end" },
   '@interface'       => { "@interface ... @end" },
   '@package'         => { "@package" },
   '@private'         => { "@private" },
   '@property'        => { "@property" },
   '@protected'       => { "@protected" },
   '@protocol'        => { "@protocol ... @end" },
   '@public'          => { "@public" },
   '@selector'        => { "@selector" },
   '@synchronized'    => { "@synchronized" },
   '@synthesize'      => { "@synthesize" },
   '@throw'           => { "@throw" },
   '@try'             => { "@try" },

   'break'            => { "break;" },
   'case'             => { "case" },
   'catch'            => { "catch ( ... ) { ... }" },
   'continue'         => { "continue;" },
   'default'          => { "default:" },
   'do'               => { "do { ... } while ( ... );" },
   'else if'          => { "else if ( ... ) { ... }" },
   'else'             => { "else { ... }" },
   'enum'             => { "enum" },
   'for'              => { "for ( ... ) { ... }" },
   'if'               => { "if ( ... ) { ... }" },
   'main'             => { "main(int argc, char *argv[]) { ... }" },
   'printf'           => { "printf(\"" },
   'return'           => { "return" },
   'self'             => { "self" },
   'struct'           => { "struct" },
   'super'            => { "super" },
   'switch'           => { "switch ( ... ) { ... }" },
   'typedef'          => { "typedef" },
   'union'            => { "union" },
   'while'            => { "while ( ... ) { ... }" },
};

static SYNTAX_EXPANSION_INFO googlego_space_words:[] = {
   'default'      => { "default:" },
   'else'         => { "else { ... }" },
   'for'          => { "for ... { ... )" },
   'func'         => { "func ... (...) ... { ... }" },
   'if'           => { "if ... { ... }" },
   'map'          => { "map[ ... ]..." },
   'select'       => { "select { ... }" },
   'switch'       => { "switch { ... }" },
};

_str _skip_pp;

int c_get_info(var Noflines,var cur_line,var first_word,var last_word,
               var rest,var non_blank_col,var semi,var prev_semi,
               bool in_smart_paste=false)
{
   typeless old_pos;
   save_pos(old_pos);
   first_word='';last_word='';non_blank_col=p_col;
   orig_col := p_col;
   int i,j;
   for (j=0;  ; ++j) {
      get_line_raw(cur_line);
      b := false;
      if (in_smart_paste) {
         _begin_line();
         i=verify(cur_line,' '\t);
         if ( i ) p_col=text_col(cur_line,i,'I');
         b=cur_line!='' && (substr(strip(cur_line),1,1)!='#' || _skip_pp=='') && _clex_find(0,'g')!=CFG_COMMENT;
      } else {
         b=cur_line!='' && (substr(strip(cur_line),1,1)!='#' || _skip_pp=='');
      }
      if ( b ){
         _str line;
         _str before_brace;
         parse cur_line with line '/*',p_rawpos; /* Strip comment on current line. */
         parse line with line '//',p_rawpos; /* Strip comment on current line. */
         parse line with before_brace '{',p_rawpos +0 last_word;
         parse strip(line,'L') with first_word '[({:; \t]',(p_rawpos'r') +0 rest;
         last_word=strip(last_word);

         updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
         int syntax_indent=p_SyntaxIndent;
         if (last_word=='{' && (p_begin_end_style != VS_C_OPTIONS_STYLE2_FLAG)) {
            save_pos(auto p2);
            p_col=text_col(before_brace);
            _clex_skip_blanks('-');
            status := 1;
            if (get_text()==')') {
               status=_find_matching_paren(def_pmatch_max_diff_ksize);
            }
            if (!status) {
               status=1;
               if (p_col==1) {
                  up();_end_line();
               } else {
                  left();
               }
               _clex_skip_blanks('-');
               if (_clex_find(0,'g')==CFG_KEYWORD) {
                  int junk;
                  _str kwd=cur_word(junk);
                  status=(int) !pos(' 'kwd' ',' with if elsif elseif while switch for foreach lock using ');
               }
            }
            if (status) {
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
               restore_pos(p2);
            } else {
               get_line_raw(line);
               non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
               /* Use non blank of start of if, do, while, which, or for. */
            }
         } else {
            non_blank_col=text_col(line,pos('[~ \t]|$',line,1,p_rawpos'r'),'I');
         }
         Noflines=j;
         break;
      }
      if ( up() ) {
         restore_pos(old_pos);
         return(1);
      }
      if (j>=100) {
         restore_pos(old_pos);
         return(1);
      }
   }
   if (in_smart_paste) {
      if (!j) p_col=orig_col;
   }
   typeless p='';
   if ( j ) {
      p=1;
   }
   semi=stat_has_semi(p);
   prev_semi=prev_stat_has_semi();
   restore_pos(old_pos);
   return(0);
}


/**
 * Checks to see if the first thing on the current line is an
 * open brace.  Used by comment_erase (for reindentation).
 *
 * @return Whether the current line begins with an open brace.
 */
bool c_is_start_block()
{
   save_pos(auto p);
   _first_non_blank();
   word := get_text();
   restore_pos(p);

   return strieq(word, "{");
}

bool _in_c_preprocessing()
{
   if (p_LangId=='rs'  || p_LangId=='powershell') return false;
   save_pos(auto p);
   //get_line(line);line=strip(line,'L');
   for (;;) {
      get_line(auto line);line=strip(line,'L');
      if (substr(line,1,1)=="#") {
         restore_pos(p);
         return(true);
      }
      up();
      if (_on_line0()) {
         restore_pos(p);
         return(false);
      }
      //get_line(line);line=strip(line,'L');
      _end_line();left();
      if (get_text()=='\') {
      //if (last_char(line)=='\') {
         _end_line();left();
         int cfg=_clex_find(0,'g');
         if (cfg==CFG_COMMENT && cfg==CFG_STRING) {
            restore_pos(p);
            return(false);
         }
      } else {
         restore_pos(p);
         return(false);
      }
   }

}
static bool _at_start_of_function_argument() {
   save_pos(auto p);
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   status:=_clex_skip_blanks('-');
   ch:=get_text();
   restore_pos(p);
   return !status && (ch==',' || ch=='(');
}

static bool c_expand_enter_block(int syntax_indent, int be_style)
{
   if (p_col > _text_colc(0,'E')) {
      return(false);
   }
   orig_seekpos:=_nrseek();
   save_pos(auto p);
   search('[~ \t]|$','@rh');
   cfg := _clex_find(0,'g');
   if (cfg != CFG_COMMENT && cfg != CFG_STRING) {
      ch := get_text();
      if (ch == '}') {
         right();
         col := c_endbrace_col();
         restore_pos(p);
         if (col) {
            indent_on_enter(0, col);
            get_line(auto line);
            replace_line(indent_string(col-1):+strip(line));
            return(true);
         }
         /*
           Special code for handling this:

        enable( <ENTER-HERE><{ STOP_NOW, 0, "myString" },
                5000,
                200 );

        enable( 5000,
                <ENTER-HERE>{ STOP_NOW, 0, "myString" },
                200 );

           which doesn't mess up this case:

              if () <ENTER-HERE>{}
         
         */
      } else if (ch == '{' && (orig_seekpos!=_nrseek() || !_at_start_of_function_argument())) {
         save_pos(auto p2);
         col := find_block_col();
         if (!col) {
            restore_pos(p2);
            col = c_begin_stat_col(true,true,true);
         }
         restore_pos(p);
         if (col) {
            if (be_style == BES_BEGIN_END_STYLE_3) {
               col += syntax_indent;
            }
            indent_on_enter(0, col);
            get_line(auto line);
            replace_line(indent_string(col-1):+strip(line));
            return(true);
         }
      }
   }
   restore_pos(p);
   return(false);
}

static bool lambda_decl_before_cursor(bool skip_nl = false, bool skip_lbrace = false,
                                         int* start_col = null)
{
   _str first_re;

   if (!_LanguageInheritsFrom('c')) {
      return false;
   }

   save_pos(auto p);

   if (skip_lbrace) {
      _clex_skip_blanks('-');
      if (get_text() == '{') {
         left();
      } else {
         restore_pos(p);
         return false;
      }
   }

   if (skip_nl) {
      first_re = '[^ \t\n\r]';
   } else {
      first_re = '[^ \t]';
   }

   status := search(first_re, '-@U');

   ch := get_text();

   if (ch == ';' || ch == '}') {
      // Early bailout, so we don't waste time 
      // looking for the return type.
      restore_pos(p);
      return false;
   }

   if (ch != ')') {
      // Return type check.  ie: [](param p) -> return_type {
      curline := p_line;
      status = search('->', '-@U');
      if (status != 0 || (curline - p_line) > 1) {
         restore_pos(p);
         return false;
      }
      left();
      _clex_skip_blanks('-');
      if (get_text() != ')') {
         restore_pos(p);
         return false;
      }
   }

   status = find_matching_paren(true);
   if (status != 0) {
      restore_pos(p);
      return false;
   }

   left();
   _clex_skip_blanks('-');

   ch = get_text();
   found := ch == ']';

   if (start_col) {
      *start_col = -1;
      if (found) {
         if (find_matching_paren(true) == 0) {
            *start_col = _first_non_blank_col(1);
         }
      }
   }

   restore_pos(p);
   return found;
}

static int enclosing_lparen_col()
{
   nesting := 1;

   save_pos(auto p);

   for (;;) {
      status := search('[()]', '-@U');
      if (status != 0) {
         restore_pos(p);
         return p_col;
      }

      switch (get_text()) {
      case ';':
         restore_pos(p);
         return p_col;

      case ')':
         nesting++;
         left();
         break;

      case '(':
         nesting--;
         if (nesting == 0) {
            c := p_col;
            restore_pos(p);
            return c;
         }
         left();
      }
   }
}

static bool last_is_lbrace()
{
   save_pos(auto p);
   left();
   _clex_skip_blanks('-');
   rv := get_text() == '{';
   restore_pos(p);
   return rv;
}

/** Returns true if the cursor is inside an empty matching
 *  pair of braces that are on the same line. */
bool inside_cuddled_braces(long& rightBracePos)
{
   rv := false;

   save_pos(auto p);
   startline := p_line;
   _clex_skip_blanks();
   if (get_text_safe() == '}' && startline == p_line) {
      rightBracePos = _QROffset();
      restore_pos(p);
      prev_char();
      _clex_skip_blanks('-');
      if (get_text_safe() == '{' && startline == p_line) {
         rv = true;
      }
   }
   restore_pos(p);
   return rv;
}

/**
 * @return non-zero number if pass through to enter key required
 */
bool _c_expand_enter()
{
   // special handling for objective-c
   is_objc := _LanguageInheritsFrom('m');

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   be_style := p_begin_end_style;
   expand := LanguageSettings.getSyntaxExpansion(p_LangId);
   lambdaStartCol := 0;
   is_lambda := lambda_decl_before_cursor(false, false, &lambdaStartCol);
   indent_case := -1;

   save_pos(auto p);
   orig_linenum := p_line;
   orig_col := p_col;
   _str enter_cmd=name_on_key(ENTER);
   line_splits := _will_split_insert_line();
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   if (_in_c_preprocessing()) {
      restore_pos(p);
      return(true);
   }

   long rb_pos;
   if (line_splits
       && enter_cmd != 'nosplit-insert-line'
       && should_expand_cuddling_braces(p_LangId)
       && inside_cuddled_braces(rb_pos)) {
      _GoToROffset(rb_pos);
      c_expand_enter_block(syntax_indent, be_style);
      restore_pos(p);
   }

   if (line_splits && c_expand_enter_block(syntax_indent, be_style)) {
      return(false);
   }

   if (is_lambda && enter_cmd != 'nosplit-insert-line') {
      restore_pos(p);
      lilb := last_is_lbrace();
      split_insert_line();
      p_col = lambdaStartCol;

      if (be_style != BES_BEGIN_END_STYLE_3
          && lilb) {
         p_col += p_SyntaxIndent;
      }
      get_line(auto ln);
      replace_line(indent_string(p_col-1) :+ strip(ln, 'L'));
      return false;
   }

   begin_col := 0; 

   if (p_LangId == 'groovy' || p_LangId == 'scala' || p_LangId=='r' || _LanguageInheritsFrom('kotlin')) {
      idx := find_index('calc_nextline_indent_from_tags', PROC_TYPE);
      if (idx > 0) {
         begin_col = call_index(idx);
         indent_on_enter(p_SyntaxIndent, begin_col);
         return false;
      }
   } else {
      begin_col=c_begin_stat_col(false /* No RestorePos */,
                                 false /* Don't skip first begin statement marker */,
                                 false /* Don't return first non-blank */,
                                 true  /* Return 0 if no code before cursor. */,
                                 false,
                                 true
                                 );
   }
// say('_c_expand_enter begin_col='begin_col', orig_col='orig_col);
   if (!begin_col /*|| (p_line>orig_linenum)*/) {
      restore_pos(p);
      return(true);
   }


   status := 0;
   LineEndsWithBrace := false;
   typeless LineEndsWithBrace_pos;
   java := 0;
   if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('cs')) {
      java=1;
   } else if (_LanguageInheritsFrom('js')  || _LanguageInheritsFrom('typescript') || _LanguageInheritsFrom('cfscript')) {
      java=2;
   }
   if (p_line>orig_linenum) {
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanksNpp("-");
      LineEndsWithBrace= (orig_linenum==p_line && get_text()=='{');
      save_pos(LineEndsWithBrace_pos);
      _first_non_blank();
   } else if (p_line==orig_linenum && begin_col<0) {
      LineEndsWithBrace= (orig_linenum==p_line && get_text()=='{');
      save_pos(LineEndsWithBrace_pos);
      _first_non_blank();
   }
   int col=0,first_word_col=p_col;
   junk := 0;
   _str first_word=cur_word(junk);
   int first_word_color=_clex_find(0,'g');
   _str cur_line, line, orig_line;
   get_line_raw(cur_line);
   BeginningOfStatementOnSameLine := (orig_linenum==p_line);
   restore_pos(p);
   enter_cmd=name_on_key(ENTER);

// say("first_word="first_word", splits="line_splits", orig_line="cur_line);

   if (is_objc || p_LangId == 'java' || p_LangId == 'js' || p_LangId=='typescript') {
      // Check for special case of initial block indent.
      // This may be embedded inside of function or method calls,
      // so we can't just check for brace at the end of the line.
      br_pos := pos('\{[\] \t\)]*$', cur_line, 1, 'R');

      if (br_pos
          && orig_col > br_pos) {
         indent_on_enter(p_SyntaxIndent, c_indent_col2(begin_col, false));
         return false;
      }
   }

   // Re-indent member-access keywords for objective-c.
   if (first_word_color == CFG_KEYWORD
       && is_objc
       && _c_is_member_access_kw('@'first_word)
       && (orig_col <= (first_word_col-1)
           || orig_col >= (first_word_col + length(first_word)))) {
      save_pos(p);
      tcol := c_smartpaste(true, first_word_col, 1);
      restore_pos(p);
      get_line_raw(auto newl);
      replace_line_raw(indent_string(tcol-1) :+ strip(newl));

      if (orig_col <= first_word_col) {
         begin_line();
      } else {
         end_line();
      }
   }

   if ( BeginningOfStatementOnSameLine &&
        !(_expand_tabsc(orig_col)!="" && line_splits) &&
        !def_strict_nosplit_insert_line &&
        first_word_color==CFG_KEYWORD
        ) {
      if ( expand && cur_line=='main' && !java) {
         status=c_insert_main();
      } else if ( first_word=='for' && name_on_key(ENTER):=='nosplit-insert-line' ) {
         /* tab to fields of C for statement */
         p_col=orig_col;
         line=expand_tabs(cur_line);
         int semi1_col=pos(';',line,p_col,p_rawpos);
         if ( semi1_col>0 && semi1_col>=p_col ) {
            p_col=semi1_col+1;
         } else {
            int semi2_col=pos(';',line,semi1_col+1,p_rawpos);
            if ( (semi2_col>0) && (semi2_col>=p_col) ) {
               p_col=semi2_col+1;
            } else {
               status=1;
            }
         }
      } else if ( (first_word=='case' || first_word=='default') &&
                 (orig_col>first_word_col ||
                  enter_cmd=='nosplit-insert-line') ) {
         typeless p2;
         save_pos(p2);
         _first_non_blank();
         case_offset:=_QROffset();
         restore_pos(p2);

         eol := "";
         if (indent_case<0) {
            updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
            indent_case=beaut_case_indent();
         }
         if (line_splits){
            get_line_raw(orig_line);
            eol=expand_tabs(orig_line,p_col,-1,'s');
            replace_line_raw(expand_tabs(orig_line,1,p_col-1,'s'));
         }
         /* Indent case based on indent of switch. */
         col=_c_last_switch_col(auto found_offset);
         if ( col && eol:=='') {
            save_pos(p2);
            goto_point(found_offset);
            _c_maybe_determine_case_indent_for_this_switch_statement(auto modified_indent_case,indent_case,null,case_offset);
            restore_pos(p2);


            if (indent_case && indent_case != '') {
               col = col + indent_case;
            } 
            if (!modified_indent_case && beaut_style_for_keyword('switch', auto jfound) == BES_BEGIN_END_STYLE_3) {
               col += syntax_indent;
            }
            replace_line_raw(indent_string(col-1):+""strip(cur_line,'L'));
            _end_line();
         }
         indent_on_enter(syntax_indent);
         if (eol:!='') {
            replace_line_raw(indent_string(p_col-1):+eol);
         }
      } else if ( first_word=='switch' && LineEndsWithBrace) {
         /* Check if there is an existing case statement and check
            the indent style of this specific switch statement.
         */
         _c_maybe_determine_case_indent_for_this_switch_statement(auto modified_indent_case,indent_case,LineEndsWithBrace_pos);
         if (indent_case<0) {
            updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
            indent_case=beaut_case_indent();
         }
         down();
         get_line_raw(line);
         up();
         extra_case_indent := 0;
         if ((indent_case && indent_case!='') || (be_style&VS_C_OPTIONS_STYLE2_FLAG) || modified_indent_case) {
            extra_case_indent=indent_case;
         }
         indent_on_enter(syntax_indent);
         get_line_raw(line);
         if ( expand && line=='' && p_LangId != 'powershell' ) {
            col=p_col-syntax_indent;
            replace_line_raw(indent_string(col-1+extra_case_indent)'case ');
            _end_line();
            c_maybe_list_args(true);
         }
     } else {
       status=1;
     }
   } else {
     status=1;
   }

   if (!status) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if (status && line_splits && is_objc) {
      col = m_indent_col(syntax_indent);
      if (col > 0) {
         indent_on_enter(0,col);
         return(false);

      } else if (!col) {
         return(false);
      }
   }

   if ( status ) {  /* try some more? Indenting only. */
      status=0;
      col=c_indent_col2(0,false);
      indent_on_enter(0,col);
   }

   return(status != 0);
}

/**
 * Searches backwards for the column position 
 * of the block declaration/statement that is introduced by the 
 * 'intro_keywords' regex.
 * 
 * @param intro_keywords Keywords that introduce the statement. 
 *                       ex: 'class|struct'.  Used in slickedit
 *                       regex, so be sure to escape any '@' in
 *                       objective-c keywords.
 * 
 * @return int Column position for the beginning of the 
 *         statement.
 */
int _c_last_enclosing_control_stmt(_str intro_keywords, _str& kw_found, long* found_offset = null) {
   if (p_lexer_name=='') {
      return(0);
   }
   save_pos(auto p);
   // Find switch at same brace level
   // search for begin brace,end brace, and switch not in comment or string
   status := search('\{|\}|' :+ intro_keywords,'@rh-');
   level := 0;
   for (;;) {
      if (status) {
         restore_pos(p);
         return(0);
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      //messageNwait('word='word);
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (word) {
         case '}':
            --level;
            break;
         case '{':
            ++level;
            break;
         default:
            if (color==CFG_KEYWORD && level== 1) {
               result := p_col;
               kw_found = cur_word(auto junk);
               if (found_offset) {
                  *found_offset = _QROffset();
               }
               // Check for switch expression.
               if (_LanguageInheritsFrom('java') && kw_found=='switch') {
                  _first_non_blank();
                  if (p_col!=result) {
                     // Assume this is a switch expression
                     restore_pos(p);
                     return 0;
                  }
               }
               restore_pos(p);
               return(result);
            }
         }
      }
      status=repeat_search();
   }
}

bool _c_is_member_access_kw(_str w) {
   return (w == 'public:' ||
           w == 'private:' ||
           w == 'protected:' ||
           w == 'signals:' ||
           w == 'slots:' ||
           (p_LangId == 'm' &&
               (w == '@public' ||
                   w == '@private' ||
                   w == '@protected' ||
                   w == '@package')));
}

/**
 * Returns the entire word from the cursor, 
 * including any punctuation that might be attached 
 * to the word if it were a keyword.  (':' for access 
 * modifiers, '@' for objective-c).  Does not guarantee 
 * the word is actually a keyword for the language. Can be used 
 * with _c_is_member_access_kw.  Returns empty string on 
 * failure. 
 * 
 * @return _str 
 */
_str _c_get_wordplus( ) {
   rv := "";
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   save_pos(auto p1);
   idre := '[a-zA-z:]#';
   if (p_LangId == 'm') {
      idre = '\@?'idre;
   }

   start := _QROffset();
   if (search('{'idre'}', 'r@<') == 0) {
      if (start == _QROffset()) {
         // If we moved, we've jumped ahead to another token most likely.
         rv = get_text(match_length('0'), match_length('S0'));
      }
   }

   restore_pos(p1);
   restore_search(s1, s2, s3, s4, s5);
   return rv;
}


/**
 * @return int Column position of last enclosing 
 *         class/struct/union/@interface
 */
int _c_last_struct_col(_str& kw_found) {
   return _c_last_enclosing_control_stmt('class|struct|union|\@class|\@interface', kw_found);
}


/**
 * @return Return column position on switch or 0 if not found
 */
int _c_last_switch_col(long &found_offset=0) {
   _str junk;
   return _c_last_enclosing_control_stmt('switch', junk,&found_offset);
}
static bool always_indent_col1_languages() {
   /* Statements for Javascript are not always terminated with semicolon.
      Javascript could really use statement level tagging for better smart indenting.
      C++ and D is done this way for historical reasons. 
      Historically, all languages but powershell returned false here.
      Feel free to change this function return true for all languages.
   */
   return !(_LanguageInheritsFrom('c') || _LanguageInheritsFrom('d') || _LanguageInheritsFrom('js') );
}

static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   in_powershell:=_LanguageInheritsFrom('powershell');
   //_message_box("This case not handled yet");
   // SmartPaste(R) should set the non_blank_col
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      restore_pos(p);
      return(non_blank_col);
   }
   restore_pos(p);
   int begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                       false /* Don't skip first begin statement marker */,
                                       true  /* Don't return first non-blank */,
                                       false,false,false,!in_powershell
                                       );

   if (begin_stat_col && (p_line<orig_linenum ||
                          (p_line==orig_linenum && p_col<=orig_col)
                         )
      ) {
#if 0
      /*
          We could have code at the top of a file like the following:

             int myproc(int i)<ENTER>

             int myvar=<ENTER>
             class foo :<ENTER>
                public name2

      */
      //messageNwait("fall through case 2");
      restore_pos(p);
      return(begin_stat_col);
#endif
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p2);
      p_line=orig_linenum;p_col=orig_col;
      save_pos(auto p4);
      _clex_skip_blanksNpp("h");
      cursor_ch:=get_text();
      restore_pos(p4);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      int status=_clex_skip_blanksNpp("h-");
      if (status) {
         restore_pos(p);
         return(orig_col);
      }
      bool treat_newline_like_semicolon=false;
      if (in_powershell) {
         save_pos(auto p3);
         _end_line();
         treat_newline_like_semicolon=_powershell_treat_this_newline_like_a_semicolon();
         restore_pos(p3);
      }
      ch := get_text();
      if (ch:==")") {
         /*
           C++
              myclass::myclass()<WANT ENTER HERE>:
                  <TO-END-UP-HERE>
         */
         if (_LanguageInheritsFrom('c') && cursor_ch==':') {
            restore_pos(p);
            return(begin_stat_col+syntax_indent);
         }
         restore_pos(p);
         return(begin_stat_col);
      }
      restore_pos(p2);
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      col := p_col;
      // Here we assume that functions start in column 1 and
      // variable declarations or statement continuations do not.
      // This seems to be a common solution.
      if (p_col==1 && ((!in_powershell && !always_indent_col1_languages() && ch!=',') || (in_powershell && treat_newline_like_semicolon))) {
         restore_pos(p);
         return(col);
      }
      int nextline_indent=syntax_indent;
      restore_pos(p);
      return(col+nextline_indent);
   }
   restore_pos(p);
   get_line(auto line);
   line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   _first_non_blank();
   col := p_col;
   restore_pos(p);
   return(col);
}
/**
 * Skip blanks and preprocessing
 *
 * @param options    search options for {@link _clex_find} and {@link search()}
 *
 * @return 0 on success, nonzero otherwise
 */
int _clex_skip_blanksNpp(_str options='',bool skip_lines_with_labels_starting_in_column1=false)
{
   int MaxSkipPreprocessing=VSCODEHELP_MAXSKIPPREPROCESSING;
   backwards := pos('-',options);
   for (;;) {
      int status=_clex_skip_blanks(options);
      if (status) {
         return(status);
      }
      /*if (p_line>FailIfPastLinenum) {
         messageNwait("p_line="p_line" FailIfPastLinenum="FailIfPastLinenum);
         return(STRING_NOT_FOUND_RC);
      }*/
      if (!_in_c_preprocessing() && (!skip_lines_with_labels_starting_in_column1 || !_in_column1_label())) {
         return(status);
      }
      --MaxSkipPreprocessing;
      if (MaxSkipPreprocessing<=0) {
         return(STRING_NOT_FOUND_RC);
      }
      if (backwards) {
         up();_end_line();
      } else {
         _end_line();
      }
   }
}
static int HandlePartialStatement(int statdelim_linenum,
                                  int sameline_indent,
                                  int nextline_indent,
                                  int orig_linenum,int orig_col)
{
   orig_ch := get_text();
   typeless orig_pos;
   save_pos(orig_pos);
   in_powershell:=_LanguageInheritsFrom('powershell');
   //linenum=p_line;col=p_col;

   /*
       Note that here we don't return first non-blank to handle the
       following case:

       for (;
            ;<ENTER>) {

       However, this does effect the following unusual case
           if (i<j) {abc;<ENTER>def;
           <end up here which is not correct>

       We won't worry about this case because it is unusual.
   */
   int begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                       false /* Don't skip first begin statement marker. */,
                                       false /* Don't return first non-blank */,
                                       false,
                                       false,
                                       true,   // Fail if no text after cursor
                                       !in_powershell
                                       );
   //messageNwait('handle begin_stat_col='begin_stat_col' <='(p_line<orig_linenum)' l='p_line' oln='orig_linenum' c='p_col' 'orig_col);
   if (begin_stat_col>0 && (p_line<orig_linenum || (p_line==orig_linenum && p_col<orig_col))
        /* && (linenum!=p_line || col!=p_col) */
      ) {
      // Now get the first non-blank column.
      begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                      false /* Don't skip first begin statement marker. */,
                                      true /* Return first non-blank */,
                                      false,
                                      false,
                                      false,
                                      !in_powershell
                                      );
      /*
         Check if partial statement ends with close paren.  This
         could be a function declaration.

         Another to handle this is to to indent any way and then
         move the open brace to the correct colmun position when
         the users types it.
      */
      save_pos(auto p);
      p_line=orig_linenum;p_col=orig_col;
      save_pos(auto p4);
      _clex_skip_blanksNpp("h");
      cursor_ch:=get_text();
      restore_pos(p4);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanksNpp("-");
      bool treat_newline_like_semicolon=false;
      if (in_powershell) {
         save_pos(auto p2);
         //messageNwait('b4 end_line');
         //_end_line();
         treat_newline_like_semicolon=_powershell_treat_this_newline_like_a_semicolon();
         //messageNwait('treat_newline_like_semicolon='treat_newline_like_semicolon);
         restore_pos(p2);
      }
      ch := get_text();
      /*
        C++
          class myclass {
              myclass()<WANT ENTER HERE>:
                  <TO-END-UP-HERE>
   
         For now, adjust the position of C++ : for constructor initializer list when the user types 
         it at the start of a line. This is the safest course of action. Visual Studio
         sometimes does this too. It's difficult to handle Enter after a close paren 
         which could be a close paren for a function definition. If it is a function
         definition, need to assume user will type { so want to put them at
         the same indent level as the start of the function. But it could be 
         a statement like "a=foo()<ENTER>". Right now, we assume this is a function 
         definition.
      */
      if (ch:==")" && !(_LanguageInheritsFrom('c') && cursor_ch==':') ) {
         return(begin_stat_col);
      }
      if (orig_ch:=='}' && ch:==',' && statdelim_linenum==p_line) {
         /*
             Also check if this line ends with a comma and handle the
             case where the user is in a declaration list like
             the following.

             MYSTRUCT array[]={
                {a,b,c},<ENTER>
                a,
                {a,b,c},<ENTER>
                {a,b,c},a,b,<ENTER>
                {a,{a,b,c}},<ENTER>
                d,
                {a,
                 {a,b,c}},
                 x,<ENTER>
                },
                b,
         */
         restore_pos(orig_pos);
         int status=_find_matching_paren(def_pmatch_max_diff_ksize);
         if (!status) {
            _first_non_blank();
            return(p_col);
         }
      } else if (ch == ':' && p_LangId != 'py') {
         // Outer calls have already taken care of the 'case', and
         // C++/ObjC access modifier cases, so we know this is a goto label.
         // Labels should not change the indent of the code coming after them, 
         // so we should look around them to see what the indent should be.
         if (p_line > 1) {
            p_line -= 1;
            _end_line();
            col := c_indent_col(1, false);
            restore_pos(p);
            return col;
         }
      }
      restore_pos(p);
      /*
         IF semicolon is on same line as extra characters

         Example
            {b=<ENTER>
      */
      if (p_line==statdelim_linenum && !(in_powershell && treat_newline_like_semicolon)) {
         //messageNwait('handle t1='(begin_stat_col+sameline_indent));
         return(begin_stat_col+sameline_indent);
      }
      /*
         Here we have something like
         int i;
            int k,<ENTER>
               <Cursor goes here>
               OR
         VOID<ENTER>
         <Cursor goes here>myproc()
      */
      col := p_col;
      /* Here we assume that functions start in column 1 and
         variable declarations or statement continuations do not.
         Seems like getIndentFirstLevel should be checked here. 
         v24 checked getIndentFirstLevel() but checked it backwards!!!. 
         For historical reasons, forget about checking getIndentFirstLevel().

         Also if you change this column 1 special case, you'll need to make 
         sure NoSyntaxIndentCase() (top of file case) works the same
         way.
      */
      if (!in_powershell && !always_indent_col1_languages() && p_col==1 && ch!=',' /*&& !LanguageSettings.getIndentFirstLevel(p_LangId)*/) {
         //messageNwait('t2a col='col);
         return(col);
      }
      if (in_powershell && treat_newline_like_semicolon) {
         //messageNwait('t2b col='col);
         return(col);
      }
      //messageNwait('handle t3='(col+nextline_indent));
      return(col+nextline_indent);
   }
   //messageNwait('handle return 0');
   return(0);
}

/**
 * NOTE:  The caller should check if the user is calling this
 * function when inside a comment (use _in_comment(1) function).
 *
 * @param non_blank_col        All parameters are ignored except
 *                             non_blank_col.  Specify non_blank_col==0
 *                             if you want it ignored too.
 * @param pasting_open_block  ignored
 *
 * @return indent column
*/
int c_indent_col(int non_blank_col,bool pasting_open_block,bool pasting_else=false)
{
   return(c_indent_col2(non_blank_col, pasting_open_block,pasting_else));
}

int cs_indent_col(int non_blank_col,bool pasting_open_block)
{
   return(c_indent_col(non_blank_col, pasting_open_block));
}

static bool _isQmarkExpression(bool &probably_constructor_initializer_list_colon=false)
{
   probably_constructor_initializer_list_colon=false;
   // cursor is sitting colon
   /*
      could have
                (c)?s:t,
                MYCLASS():a(1),b(2) {
             class name1:public<ENTER>

            default :
            case 'a':
            case ('a'+'b')-1:
            public:
            private:
            protected:
      Give up on } for now.
   */
   in_objectivec := _LanguageInheritsFrom('m');
   int status=search('[?;{})\[]|struct|class|default|case|public|private|protected','-@rhxcs');
   bool found_paren_first=!status && get_match_text()==')';
   for (;;) {
      if (status) {
         return(false);
      }
      word:=get_match_text();
      switch(word) {
      case '?':
         probably_constructor_initializer_list_colon=false;
         return(true);
      case '[':
         probably_constructor_initializer_list_colon=false;
         if (!in_objectivec) {
            found_paren_first=false;
            status=repeat_search();
            continue;
         }
         return(false);
      case '{':
      case ';':
      case '}':
         return(false);
      case ')':
         probably_constructor_initializer_list_colon=found_paren_first;
         status=find_matching_paren(true);
         if (status) {
            return(false);
         }
         found_paren_first=false;
         status=repeat_search();
         continue;
      default:
         if (_clex_find(0,'g')==CFG_KEYWORD) {
            probably_constructor_initializer_list_colon=false;
            return(false);
         }
         found_paren_first=false;
         status=repeat_search();
         continue;
      }
   }
}
static bool _isVarInitList(bool checkEnum,int &indent_from_col)
{
   /*
      Check for the array/struct initialization case by
      check for equal sign before open brace.  This won't
      work if preprocessing is present.

        int array[]={
           a,
           b,<ENTER>
           int a,
           b,
           c,


      object array[]={
         "a","b",
         "c",{"a",
            "b","c"
         }
      };
      MYTYPE x=(MYTYPE) {
          .planes=1,<ENTER>
          .pitch=2,
      };
      return (MYTYPE) {
          .planes=1,<ENTER>
          .pitch=2,
      };
      return {
          .planes=1,<ENTER>
          .pitch=2,
      };
      foo({
          .planes=1,<ENTER>
          .pitch=2,
      });
    

      also check for enum declaration like

      enum [class|struct] [id] [: type] {enum-list} [id];
      enum_flags [id] {enum-list} [id]
   */
   int brace_col=p_col;
   indent_from_col=0;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   _clex_skip_blanksNpp('-');
   in_powershell:=_LanguageInheritsFrom('powershell');
   bool in_init;
   if (in_powershell) {
      /* 
       Fix for this:
       
       catch [System.Net.WebException],
              [System.IO.IOException] {<Enter-here>
       
      */
      in_init=(get_text()=='=');// || get_text()=='(' || get_text()==',' || get_text()=='{') || cur_identifier(auto junk_col)=='return';
   } else {
      in_init=(get_text()=='=' || get_text()==']' || get_text()=='(' ||
                       get_text()==',' || get_text()=='{') || cur_identifier(auto junk_col)=='return';
   }
   if (get_text()=='(') {
      save_pos(auto p3);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks('-');
      if (!(cur_identifier(auto junk_col3)=='return' && _clex_find(0,'g') == CFG_KEYWORD)) {
         indent_from_col=brace_col;
      }
      restore_pos(p3);
   }
   if (!in_init && get_text()==')') {
      save_pos(auto p2);
      int status2=_find_matching_paren(def_pmatch_max_diff_ksize);
      if (!status2) {
         brace_col=p_col;
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         _clex_skip_blanks('-');
         word:=cur_identifier(auto start_col);
         in_init=(get_text()=='=' || get_text()=='(' ||
                          get_text()==',' || get_text()=='{' || cur_identifier(auto junk_col2)=='return');

         if (get_text()=='(') {
            save_pos(auto p3);
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            _clex_skip_blanks('-');
            if (!(cur_identifier(auto junk_col3)=='return' && _clex_find(0,'g') == CFG_KEYWORD)) {
               indent_from_col=brace_col;
            }
            restore_pos(p3);
         }
         restore_pos(p2);
         if (in_init) {
            return in_init;
         }
      }
   }
   if (!in_init && checkEnum) {
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
      save_pos(auto p);
      status := search('[,;})]|(enum_flags|enum)', "-rh@XSC");
      if (!status) {
         switch(get_match_text()) {
         case 'enum_flags':
         case 'enum':
            if (_clex_find(0,'g') == CFG_KEYWORD) {
               in_init = true;
            }
            break;
         default:
            restore_pos(p);
            break;
         }
      }
      restore_search(s1,s2,s3,s4,s5);
   }
   return(in_init);
}
static void parse_template_args()
{
   nesting := 0;
   for (;;) {
      if (c_sym_gtk()=='>') {
         ++nesting;
      } else if (c_sym_gtk()=='<') {
         --nesting;
         if (nesting<=0) {
            c_prev_sym();
            return;
         }
      } else if (c_sym_gtk()=='') {
         return;
      }
      c_prev_sym();
   }
}

static bool braceIsStandaloneBlock()
{
   save_pos(auto p);
   
   if (find_matching_paren(true) != 0) {
      return false;
   }

   if (prev_char() != 0) {
      restore_pos(p);
      return false;
   }

   if (_clex_skip_blanksNpp('-') != 0) {
      restore_pos(p);
      return false;
   }

   bool rv;
   ch := get_text();

   if (ch == ')') {
      rv = false;
   } else if (_clex_find(0, 'G') == CFG_KEYWORD) {
      rv = false;
   } else {
      rv = true;
   }

   restore_pos(p);
   return rv;
}
static bool dangling_clause_close_brace(int linenum,int col) {
   save_pos(auto p);
   p_line=linenum;p_col=col;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   status:=_clex_skip_blanks('-');
   if (status) {
      restore_pos(p);
      return false;
   }
   ch:=get_text();
   if (ch!='}') {
      restore_pos(p);
      return false;
   }
   status=_find_matching_paren(def_pmatch_max_diff_ksize,true);
   if (status) {
      restore_pos(p);
      return false;
   }
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   _clex_skip_blanks('-');
   if (get_text()==')') {
      status=_find_matching_paren(def_pmatch_max_diff_ksize,true);
      if (status) {
         restore_pos(p);
         return false;
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks('-');
      if (_clex_find(0,'g') != CFG_KEYWORD) {
         restore_pos(p);
         return false;
      }
      word:=cur_identifier(auto start_col);
      p_col=start_col;
      if (word == 'if') {
         save_pos(auto itest);
         prev_word();
         nw := cur_identifier(auto sc);
         if (nw == 'else') {
            p_col = sc;
            word = nw;
         } else {
            restore_pos(itest);
         }
      }
      if (word!='if' && word!='for' && word!='while') {
         restore_pos(p);
         return false;
      }
      dangling_clause_continue(word);
      return true;
   } else {
      if (_clex_find(0,'g') != CFG_KEYWORD) {
         restore_pos(p);
         return false;
      }
      word:=cur_identifier(auto start_col);
      p_col=start_col;
      if (word!='else' && word!='elseif') {
         restore_pos(p);
         return false;
      }
      dangling_clause_continue('else');
      return true;
   }
}
static bool dangling_clause_allow_continue_check_orig(_str begin_stat_word,int linenum,int col) {
   if (begin_stat_word!='while' && begin_stat_word!='for' && begin_stat_word!='if' && begin_stat_word!='else') {
      return false;
   }
   save_pos(auto p);
   p_line=linenum;p_col=col;
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   status:=_clex_skip_blanks('-');
   if (status) {
      restore_pos(p);
      return false;
   }
   ch:=get_text();
   if (ch==';' || ch=='}') {
      restore_pos(p);
      return true;
   }
   restore_pos(p);
   return false;
}
static void dangling_clause_continue(_str word) {
   for (;;) {
      save_pos(auto p);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks('-');
      
      if (word=='else' || word=='elseif') {
         ch:=get_text();
         if (ch!=';' && ch!='}') {
            restore_pos(p);
            return;
         }
         if (ch==';') {
            begin_stat_col:=c_begin_stat_col(false /* No RestorePos */,
                                            true /* skip first begin statement marker */,
                                            false /* return first non-blank */
                                            );
         } else {
            status:=_find_matching_paren(def_pmatch_max_diff_ksize,true);
            if (status) {
               restore_pos(p);
               return;
            }
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            _clex_skip_blanks('-');
            if (get_text()!=')') {
               restore_pos(p);
               return;
            }
         }

      }
      if (get_text()!=')') {
         //restore_pos(p);
         //return;
      } else {
         status:=_find_matching_paren(def_pmatch_max_diff_ksize,true);
         if (status) {
            restore_pos(p);
            return;
         }
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         _clex_skip_blanks('-');
      }
      if (_clex_find(0,'g') != CFG_KEYWORD) {
         restore_pos(p);
         return;
      }
      word=cur_identifier(auto start_col);
      p_col=start_col;
      if (word!='if' && word!='for' && word!='while' && word!='elseif' /* powershell*/) {
         restore_pos(p);
         return;
      }
      save_pos(auto p2);
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanks('-');
      if (_clex_find(0,'g')==CFG_KEYWORD) {
         word2:=cur_identifier(auto start_col2);
         if (_clex_find(0,'g') == CFG_KEYWORD && word2=='else') {
            p_col=start_col2;
            word=word2;
         }
      }
      if (word!='else' && word!='elseif' /* powershell*/) {
         restore_pos(p2);
      }

   }

}
bool  _in_long_line_split_into_multiples() {
   if(_lineflags() & EOL_MISSING_LF) {
      return true;
   }
   save_pos(auto p);
   up();
   eol_missing:=(_lineflags() & EOL_MISSING_LF)!=0;
   restore_pos(p);
   return eol_missing;
}
static int c_indent_col2(int non_blank_col,bool pasting_open_block,bool pasting_else=false)
{
   orig_col := p_col;
   orig_linenum := p_line;
   int orig_embedded=p_embedded;
   int col=orig_col;

   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }
   if (_in_long_line_split_into_multiples()) {
      p_col=1;
      _first_non_blank();
      col = p_col;
      restore_pos(p);
      return col;
   }
   be_style := p_begin_end_style;
   ParameterAlignment := beaut_funcall_param_alignment();
   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   style3 := be_style == BES_BEGIN_END_STYLE_3;

   if (pasting_open_block) {
      // Look for for,while,switch
      save_pos(auto p2);
      col= find_block_col();
      restore_pos(p2);
      if (col) {
         restore_pos(p);
         if (style3) {
            return(col+syntax_indent);
         }
         return(col);
      } else {
         /* For brace style 2 or 3 braces, if we're re-indenting the line with the 
            brace, be sure to put it in the brace column, not the indent for statements
            inside the braces.
          
            Do SMARTTAB with cusor before this brace or SMARTPASTE brace block
          
            ie:  struct blah
                |{
          
            Also need to work for this case:
                if (x)
                   printf("statement present");
                |{
                   //paste block below printf
                }
            Also need to work for this case:
                if (x) {
                   printf("statement present");
                }
                |{
                   //paste block below printf
                }
          */
         save_pos(p2);
         if (_clex_skip_blanks() == 0 && 
             get_text() == '{') {
            restore_pos(p2);
            _clex_skip_blanks('-');
            term_char := get_text();
            if (term_char == ')') {
               // Special case - if this is a function declaration that
               // spans multiple lines, then we want the first_non_blank()
               // call below to go to the beginning of the declaration, 
               // not just where the last parameter line happens to be indented.
               _find_matching_paren(MAXINT, true);
            }
            bool statement_terminated=term_char==';' || term_char=='}';
            _first_non_blank();
            start_word := cur_identifier(auto doNotCare);
            start_kind := _clex_find(0, 'G');
            if (!statement_terminated /*start_kind==CFG_KEYWORD*/) {
               bstyle := beaut_style_for_keyword( start_word, auto found);
               col = p_col;
               if (bstyle == BES_BEGIN_END_STYLE_2 || bstyle == BES_BEGIN_END_STYLE_1) {
                  restore_pos(p);
                  return col;
               } else if (bstyle == BES_BEGIN_END_STYLE_3) {
                  if (get_text() == '}' && col >= syntax_indent) {
                     // If there's an ending brace above us, we want to line
                     // up with whatever control statement introduced the brace.
                     restore_pos(p);
                     return col-syntax_indent;
                  } else if (start_kind == CFG_KEYWORD) {
                     // Bare control statement above us, so indent
                     restore_pos(p);
                     return col+syntax_indent;
                  } else {
                     // Just a regular statement above us, so follow its indent.
                     restore_pos(p);
                     return col;
                  }
               } else {
                  restore_pos(p2);
               }
            } else {
               restore_pos(p2);
            }
         }
      }
      /*
          Note:
             pasting open brace does not yet work well
             for style2 when pasting brace out side class/while/for/switch blocks.
             Braces are not indented.

             pasting open brace does not yet work well
             for style2!=2 when pasting braces for a class.  Braces
             end up indented when they are not supposed to be.
      */
   }

   // locals
   cfg := 0;
   begin_stat_col := 0;
   ch := "";
   word := "";
   junk := 0;
   line := "";
   kwd := "";
   typeless p2,p3;

/*
   beginning of statement
     {,},;,:

   cases
     -  in-comment or in-string
     - for (;;) <ENTER>


     - myproc(myproc() <ENTER>
     - myproc(a,<ENTER>
     - myproc(a);
     - if/while/for/switch (...) <ENTER>
     - (col1)myproc(a)<ENTER>
     - (col>1)myproc(a)<ENTER>
     - (col>1)myproc(a)<ENTER>
     - case a: <ENTER>
     - default: <ENTER>
     -  if (...) {<ENTER>
     -  if (...) <ENTER>
     -  if (...) ++i; else <ENTER>
     -  if (...) ++i; else <ENTER>
     -  myproc (...) {<ENTER>
     -  statement;
         {<ENTER>
     -  if (a && b
     -  if (a && b,b
     -  <ENTER>  no code above
     -  int a,
     -  if {
           }<ENTER>
     -  {
        }<ENTER>
     - for (;<ENTER>;<ENTER>)
     - for (<ENTER>;;<ENTER>)
     - for (i=1;i<j;<ENTER>
     - if (a<b) {
          x=1;
       } else if( sfsdfd) {<ENTER>}

     {sdfsdf;
      ddd


*/

   lambdaStartCol := 0;
   if (lambda_decl_before_cursor(true, true, &lambdaStartCol)) {
      restore_pos(p);
      if (be_style != BES_BEGIN_END_STYLE_3) {
         lambdaStartCol += p_SyntaxIndent;
      }
      return lambdaStartCol;
   }

   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      _end_line();
   }
   /*
       Handle a few special cases where line begins with
         close brace, "case", "default","public", "private",
         and "protected".
   */
   {
      save_pos(p2);

      _clex_skip_blanks('-');
      if (_expand_tabsc(1,p_col-1,'S')=='') {
         _first_non_blank();
         word=cur_word(junk);
         if (word=='case' || word=='default') {
            updateAdaptiveFormattingSettings(AFF_INDENT_CASE);
            col=_c_last_switch_col();
            if (col) {
               col = col + beaut_case_indent() + p_SyntaxIndent;
               restore_pos(p);
               return(col);
            }  else {
               restore_pos(p2);
            }
         } else {
            restore_pos(p2);
         }
      }

      begin_word();
      if (orig_col<=p_col) {
         cfg=_clex_find(0,'g');
         if (cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
            isStandaloneBlock := false;
            word=cur_word(junk);
            ch=get_text();
            if (ch=="}") {
               right();
               if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
                  isStandaloneBlock = braceIsStandaloneBlock();
               }
               col=c_endbrace_col();
               if (col) {
                  restore_pos(p);

                  // For brace style 3, we now have the column of the endbrace.  Which means
                  // we need to back up to be at the right indent for code after the '}'. But only
                  // if the brace is a statement brace, not a standalone brace.
                  if (p_begin_end_style == BES_BEGIN_END_STYLE_3 && col > p_SyntaxIndent && !isStandaloneBlock) {
                     col -= p_SyntaxIndent;
                  }
                  return(col);
               }
            } else if (cfg==CFG_KEYWORD || (word=='signals' && _LanguageInheritsFrom('c'))) {
               if (_LanguageInheritsFrom('c') && (word=='public' || word=='private' || word=='protected' || word=='signals')) {
                  int class_col=find_class_col(true);
                  if (class_col) {
                     ma_indent := beaut_member_access_indent();
                     class_col+=ma_indent;
                     if (beaut_style_for_keyword('class', auto jfound) == BES_BEGIN_END_STYLE_3) {
                        class_col += p_SyntaxIndent;
                     }
                     restore_pos(p);
                     return(class_col);
                  }
               } 

            }
         }
      }
      restore_pos(p2);
   }

   // Are we in an embedded context?
   // Then find the beginning of the embedded code
   embedded_start_pos := 0L;
   if (p_EmbeddedLexerName!='') {
      save_pos(p2);
      if (!_clex_find(0,'-S')) {
         embedded_start_pos=_QROffset();
      }
      restore_pos(p2);
   }

   in_csharp := _LanguageInheritsFrom('cs');
   in_javascript := _LanguageInheritsFrom('js');
   in_typescript := _LanguageInheritsFrom('typescript');
   in_objectivec := _LanguageInheritsFrom('m');
   in_java := _LanguageInheritsFrom('java');
   in_rust := _LanguageInheritsFrom('rs');
   in_powershell := _LanguageInheritsFrom('powershell');
   optSemicolon := (_LanguageInheritsFrom('googlego') || _LanguageInheritsFrom('swift') || in_powershell);
   in_json := false;

   objc_bracket_count := 0;
   nesting := 0;
   OpenParenCol := 0;
   maybeInAttribute := 0;
   if (p_col==1) {
      up();_end_line();
   } else if (!optSemicolon || get_text() :!= substr(p_newline,1,1)) {
      left();
   }

   search_text := '[{;}:()\[\]]|with|if|elsif|elseif|while|lock|for|foreach|switch|using';
   if (in_rust) {
      //search_text='[{;}:()\[\]]|if|while|for';
      search_text='[{;}:()\[\]]|if|while|for|=>';
   }
   if (in_objectivec) {
      // indent rules for objective-c directive
      search_text :+= '|'OBJECTIVEC_CLASS_KEYWORDS_RE;
   } else if (in_java) {
      search_text :+= '|\@';
   } else if (optSemicolon) {
      search_text :+= '|\n';
   }

   status := search(search_text,"@rh-");
   searchCount := 0;

   for (;;) {
      searchCount++;
      if (status) {
         if (nesting<0) {
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      if (_QROffset() < embedded_start_pos && p_embedded) {
         // we are embedded in HTML and hit script start tag
         //return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
         restore_pos(p);
         if (nesting<0) {
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
         /* Cases:
              <%
                  <ENTER>
              %>
              <? <ENTER>
              ?>
              <script ...> <ENTER>
              </script>

             <cfif
                 IsDate(...) and<ENTER>
             </cfif>
         */
         _str orig_EmbeddedLexerName=p_EmbeddedLexerName;
         // Look for first non blank that is in this embedded language
         _first_non_blank();
         int ilen=_text_colc();
         //_message_box('xgot here');
         for(;;) {
            if (p_col>ilen) {
               //_message_box('got here');
               return(orig_col);
            } else if (orig_EmbeddedLexerName==p_EmbeddedLexerName && get_text():!=' ') {
               //refresh();_message_box('break col='p_col' l='p_line);
               break;
            }
            ++p_col;
         }
         col=p_col;
         restore_pos(p);
         return(col);
      }

      cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         if (in_powershell && cfg==CFG_COMMENT && optSemicolon && 
             get_text():==substr(p_newline,1,1) && _powershell_treat_this_newline_like_a_semicolon()) {
         } else {
            status=repeat_search();
            continue;
         }
      }
      ch=get_text();
      if (in_powershell && optSemicolon && ch:==substr(p_newline,1,1) && !_powershell_treat_this_newline_like_a_semicolon()) {
         status=repeat_search();
         continue;
      }
      // Don't indent based on labels starting in column 1
      if (ch:==':' &&_in_column1_label()) {
         //messageNwait('c_indent_col2 skipped label');
         _begin_line();
         status=repeat_search();
         continue;
      }

      //messageNwait('ch='ch);
      switch (ch) {
      case ']':  // maybe C# attribute
         if (in_csharp && !_in_function_scope()) {
            ++maybeInAttribute;
         }
         if (in_objectivec && _in_function_scope()) {
            --objc_bracket_count;
         }
         status=repeat_search();
         continue;
      case '[':
         // maybe C# attribute
         if (in_csharp && !_in_function_scope()) {
            --maybeInAttribute;
            if (maybeInAttribute == 0 && p_col == _first_non_blank_col()) {
               col = p_col;
               restore_pos(p);
               return(col);
            }
         }

         // maybe objective-c message expression [object method]
         if (in_objectivec && _in_function_scope()) {
            ++objc_bracket_count;
            if (objc_bracket_count > 0) {
               if (!_objectivec_index_operator()) {
                  if (ParameterAlignment == COMBO_AL_CONT) {
                     _first_non_blank();
                     col = p_col + beaut_continuation_indent();
                     restore_pos(p);
                     return(col);
                  }
                  col = p_col + 1;
                  restore_pos(p);
                  return(col);
               }
            }
         }
         status=repeat_search();
         continue;
      case '(':
         if (!nesting && !OpenParenCol) {
            save_pos(p3);
#if 1
            save_search(auto ss1,auto ss2,auto ss3,auto ss4, auto ss5);
            col=p_col;
            linenum:=p_line;
            ++p_col;
            status=_clex_skip_blanksNpp();
            /*
               Handle these cases better
             
                foo( /* arg_name */value1,<Enter>
                     /* arg_2*/value2,<Enter>
             
            */
            if (p_line>linenum) {
               _first_non_blank();
            } else {
               restore_pos(p3);++p_col;
               search('[^ \t]|$','r@h');
            }

            if (ParameterAlignment == COMBO_AL_AUTO) {
               if (!status 
                   && (p_line<orig_linenum 
                       || (p_line==orig_linenum && p_col<orig_col))) {
                  ParameterAlignment = COMBO_AL_PARENS;
               } else {
                  ParameterAlignment = COMBO_AL_CONT;
               }
            }
            switch (ParameterAlignment) {
            case COMBO_AL_PARENS:
               col=p_col-1;
               break;

            case COMBO_AL_CONT:
            default:
               /*
                  case: Use continuation indent instead of lining up on
                  open paren.

                  aButton.addActionListener(<Enter here. No args follow>
                      a,
                      b,
               */
               restore_pos(p3);
               goto_point(_nrseek()-1);
               //if (_clex_skip_blanks('-')) return(0);
               //word=cur_word(junk);
               c_prev_sym2();
               if (c_sym_gtk()=='>') {
                  parse_template_args();
               }
               sym:=c_sym_gtk();
               if ((sym==TK_ID && !pos(' 'c_sym_gtkinfo()' ',' with for foreach if elsif elseif switch while lock using ')) || 
                   // probably rust macro like println!(...)
                   (in_rust && sym=='!' && pos('[a-zA-Z_$0-9]',get_text(),1,'r') /*prev char is identifier character */)
                   ) {
                  restore_pos(p3);
                  _first_non_blank();
                  col=p_col+beaut_continuation_indent()-1;
               }
               break;
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#else
            save_search(auto ss1,auto ss2,auto ss3,auto ss4,auto ss5);
            col=p_col;
            ++p_col;
            status=_clex_skip_blanksNpp();
            if (!status && (p_line<orig_linenum ||
                            (p_line==orig_linenum && p_col<=orig_col)
                           )) {
               col=p_col-1;
            }
            restore_search(ss1,ss2,ss3,ss4,ss5);
#endif
            OpenParenCol=col;
            restore_pos(p3);
         }
         --nesting;
         status=repeat_search();
         continue;
      case ')':
         ++nesting;
         status=repeat_search();
         continue;

      case '@':
         if (in_objectivec && cfg == CFG_KEYWORD) {
            switch (get_match_text()) {
            case '@class':
            case '@interface':
            case '@implementation':
            case '@protocol':
               // align to declaration column
               col = p_col;
               restore_pos(p);
               return(col);

            case '@package':
            case '@private':
            case '@protected':
            case '@public':
               if (beaut_indent_members_from_access_spec()) {
                  col = p_col;
                  restore_pos(p);
                  return syntax_indent + col;
               } else {
                  col = p_col;
                  restore_pos(p);
                  return col + syntax_indent - beaut_member_access_indent();
               }
               break;
               
            default:
               _first_non_blank();
               col = p_col;
               restore_pos(p);
               return(col);
            }
         } else if (in_java) {
            // Don't treat it like a continuation indent.
            _first_non_blank();
            col = p_col;
            restore_pos(p);
            return(col);
         }
         break;

      default:
         if (nesting<0) {
            //messageNwait("nesting case");
            restore_pos(p);
            return(OpenParenCol+1/*+def_c_space_after_paren*/);
         }
      }
      if (nesting || 
          maybeInAttribute /* nested in C# brackts probably for attribute*/) {
         status=repeat_search();
         continue;
      }
      if (_in_c_preprocessing()) {
         begin_line();
         status=repeat_search();
         continue;
      }
      switch (ch) {
      case '{':
         //messageNwait("case {");
         openbrace_col := p_col;
         statdelim_linenum := p_line;

         /*
            Could have
              for (;
                    ;) {<ENTER>

              myproc ( xxxx ) {<ENTER>

              myproc (xxx ) {
                 int i,<ENTER>

              {<ENTER>

              else {<ENTER>

              else
                 {<ENTER>

              class name : public name2 {<ENTER>

              if ( xxx ) {<ENTER>

              if ( xxx )
                 {<ENTER>

              if ( xxx )
              {<ENTER>

              int array[]={
                 a,
                 b,<ENTER>
          
              MYTYPE x=(MYTYPE) {
                  .planes=1,<ENTER>
                  .pitch=2,
              };
              return (MYTYPE) {
                  .planes=1,<ENTER>
                  .pitch=2,
              };
              return {
                  .planes=1,<ENTER>
                  .pitch=2,
              };
              foo({
                  .planes=1,<ENTER>
                  .pitch=2,
              });

         */

         save_pos(p2);

         is_block := false;
         override_col := -1;

         if (in_objectivec) {
            // Handle "^{" or "^(typedecls) {"

            left();
            _clex_skip_blanks('-');
            tok := get_text();
            if (tok == '^') {
               is_block = true;
            } else if (tok == ')') {
               find_matching_paren();
               left();
               _clex_skip_blanks('-');
               if (get_text() == '^') {
                  is_block = true;
               }
            }
         } else if (in_javascript || in_typescript) {
            fnstart := 0;
            left();
            _clex_skip_blanks('-');
            tok := get_text();
            if (tok == ')') {
               find_matching_paren();
               left();
               _clex_skip_blanks('-');
               if (cur_identifier(fnstart) == 'function') {
                  is_block = true;
               }
            } else if (tok == ',' || tok == '(') {
               // Not a block, but an object literal in a function call.
               // The beautifier will allow a continuation indent in this case,
               // unless the function parameter alignment is PARENS.
               if (ParameterAlignment == COMBO_AL_PARENS) {
                  col = openbrace_col + p_SyntaxIndent;
               } else {
                  col = c_begin_stat_col(false /* No RestorePos */,
                                        false /* Don't skip first begin statement marker */,
                                        false /* Don't return first non-blank */,
                                        true  /* Return 0 if no code before cursor. */,
                                        false,
                                        true);
                  col += p_SyntaxIndent;
               }
               restore_pos(p);
               return col;
            }
            if (is_block) {
               if (beaut_anon_fn_indent_relative()) {
                  override_col = fnstart;
               } else {
                  // We're part of a larger statement, so find the beginning of that
                  // and use it for the base of the indent.
                  p_col = fnstart;
                  if (p_col == 1 && p_line != 1) {
                     p_line--;
                     _end_line();
                  } else {
                     p_col--;
                  }
                  override_col = c_begin_stat_col(false, false, false, true, false, true);
               }
            }
         }

         if (is_block) {
            if (override_col > 0) {
               col = override_col;
            } else {
               col = c_begin_stat_col(false /* No RestorePos */,
                                     false /* Don't skip first begin statement marker */,
                                     false /* Don't return first non-blank */,
                                     true  /* Return 0 if no code before cursor. */,
                                     false,
                                     true);
            }

            restore_pos(p);
            return col + beaut_initial_anonfn_indent();
         }
         restore_pos(p2);

         prev_char();
         _clex_skip_blanks('-');
         _first_non_blank();
         block_word := cur_word(auto junk1);
         if (block_word == 'namespace') {
            nscol := p_col;
            restore_pos(p);
            if (beaut_should_indent_namespace()) {
               return nscol+p_SyntaxIndent;
            } else {
               return nscol;
            }
         } else if (block_word == 'extern') {
            nscol := p_col;
            restore_pos(p);
            if (beaut_should_indent_extern()) {
               return nscol+p_SyntaxIndent;
            } else {
               return nscol;
            }
         }
         restore_pos(p2);

         if (_isVarInitList(true,auto indent_from_col) || in_json) {
            restore_pos(p2);
            if (indent_from_col) {
               col=indent_from_col;
            } else {
               _first_non_blank();
               col=p_col;
            }
            restore_pos(p);
            return(col+p_SyntaxIndent);
#if 0
            restore_pos(p2);
            begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                            true /* skip first begin statement marker */,
                                            true /* return first non-blank */
                                            );
            restore_pos(p2);
            // Now check if there are any characters between the
            // beginning of the previous statement and the original
            // cursor position
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,0,
                                       orig_linenum,orig_col);
            if (col) {
               restore_pos(p);
               return(col);
            }
#endif
         }
         restore_pos(p2);
         if (p_col==1) {
            up();_end_line();
         } else {
            left();
         }
         _clex_skip_blanksNpp('-');
         status=1;
         if (get_text()==')') {
            status=_find_matching_paren(def_pmatch_max_diff_ksize);
            save_pos(p3);
         } else {
            if (in_powershell) {
               //messageNwait('in_powershell');
               if (get_text()==']') {
                  status=_find_matching_paren(def_pmatch_max_diff_ksize);
                  save_pos(p3);
                  for (;!status;) {
                     if (p_col==1) { up();_end_line(); } else { left(); }
                     _clex_skip_blanksNpp('-');
                     //messageNwait(']');
                     if (get_text():!=',') {
                        restore_pos(p3);
                        break;
                     }
                     if (p_col==1) { up();_end_line(); } else { left(); }
                     _clex_skip_blanksNpp('-');
                     if (get_text():!=']') {
                        restore_pos(p3);
                        break;
                     }
                     status=_find_matching_paren(def_pmatch_max_diff_ksize);
                     save_pos(p3);
                  }
               }
            }
         }
         if (!status) {
            status=1;
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            _clex_skip_blanksNpp('-');
            if (_clex_find(0,'g')==CFG_KEYWORD) {
               kwd=cur_word(junk);
               status=(int) !pos(' 'kwd' ',' trap with if elsif elseif while lock switch for foreach catch using function ');
               // IF this is the beginning of a "if/while/switch/for" block
               if (!status) {
                  _first_non_blank();
                  block_col := p_col;
                  // Now check if there are any characters between the
                  // beginning of the previous statement and the original
                  // cursor position
                  restore_pos(p2);


                  col=HandlePartialStatement(statdelim_linenum,
                                             syntax_indent,syntax_indent,
                                             orig_linenum,orig_col);
                  if (col) {
                     restore_pos(p);
                     return(col);
                  }

                  restore_pos(p);
                  return(block_col+syntax_indent);
               }
            } else if (_LanguageInheritsFrom('java')) {
               /*

                   // case 1:  just blanks after open paren.  Use continuation indent.
                   aButton.addActionListener(
                       a,
                       b,
                       new ActionListener() {
                           public void actionPerformed(ActionEvent e) {
                               createdButtonFired(buttonIndex);
                           }
                       },
                       b,
                       );
                  // case 2:  First argument is new constructor
                  aButton.addActionListener(new ActionListener() {
                          public void actionPerformed(ActionEvent e) {
                              createdButtonFired(buttonIndex);
                          }
                      },
                      b,
                      );

               */
               // Check if we have a new construct
               kwd=cur_word(col);
               p_col=_text_colc(col,'I');
               if (p_col>1) {
                  left();
                  if (_clex_skip_blanks('-')) return(0);
                  word=cur_word(col);
                  if (word=='new') {
                     p_col=_text_colc(col,'I');
                     col=p_col;
                     _first_non_blank();
                     if (col!=p_col) {
                        p_col+=p_SyntaxIndent;
                     }
                     col=p_col+p_SyntaxIndent;
                     restore_pos(p);
                     return(col);
                  }
               }
            }

            // Now check if there are any characters between the
            // beginning of the previous statement and the original
            // cursor position
            restore_pos(p2);
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,syntax_indent,
                                       orig_linenum,orig_col);

            if (col) {
               restore_pos(p);
               return(col);
            }

            //  This open brace is to a function or method or some
            //  very strange preprocessing.
            restore_pos(p2); // Restore cursor to open brace
            _first_non_blank();
            if (p_col==openbrace_col) {
               begin_stat_col=openbrace_col;
            } else {
               restore_pos(p3); // Restore cursor to open paren
               begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                               false /* Don't skip first begin statement marker */,
                                               false /* Don't return first non-blank */
                                               );
               if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
                  begin_stat_col+=syntax_indent;
               }
            }

            if (begin_stat_col==1 && !indent_fl) {
               restore_pos(p);
               return(1);
            }
            restore_pos(p);
            if ((be_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
               return(begin_stat_col);
            }
            return(begin_stat_col+syntax_indent);
         }
         restore_pos(p2);
         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position


         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         restore_pos(p2);
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            restore_pos(p);
            return(col);
         }

         /*
             Probably have one of these case here

              {<ENTER>

              else {<ENTER>

              else
                 {<ENTER>

              class name : public name2 {<ENTER>

              if (a<b) x=1; else {<ENTER>}

              if (a<b) {
                 x=1;
              } else {<ENTER>}

         */
         restore_pos(p2);
         if (style3) {
            _first_non_blank();
            // IF the open brace is the first character in the line
            if (openbrace_col==p_col) {

               begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                               true /* skip first begin statement marker */,
                                               true /* return first non-blank */
                                               );
               // IF there is stuff between the previous statement and
               //    this statement, we must be in a class/struct
               //    definition.  IF/While/FOR Etc. cases have been
               //    handled above.
               if (openbrace_col!=p_col || statdelim_linenum!=p_line) {
                  restore_pos(p);
                  return(begin_stat_col+syntax_indent);
               }
               // We could check here for extra stuff after the
               // open brace
               restore_pos(p);
               return(openbrace_col);
            }
            restore_pos(p2);
         }
         begin_stat_col=c_begin_stat_col(false /* No RestorePos */,
                                         true /* skip first begin statement marker */,
                                         true /* return first non-blank */,
                                         false,false,false,!in_powershell
                                         );
         restore_pos(p);
         return(begin_stat_col+syntax_indent);

      case \r:
      case \n:
         if (!in_powershell) {
            save_pos(p2);
            left();
            _clex_skip_blanksNpp('-');
            cfg=_clex_find(0,'g');

            statdelim_linenum=p_line;
            begin_stat_col=c_begin_stat_col(false /* RestorePos */,
                                            true /* skip first begin statement marker */,
                                            true /* return first non-blank */
                                            );
            if (cfg == CFG_PUNCTUATION || cfg == CFG_OPERATOR) {

               // Now check if there are any characters between the
               // beginning of the previous statement and the original
               // cursor position
               restore_pos(p2);
               col=HandlePartialStatement(statdelim_linenum,
                                          syntax_indent,syntax_indent,
                                          orig_linenum,orig_col);
               if (col) {
                  restore_pos(p);
                  return(col);
               }
            } 

            restore_pos(p);
            return(begin_stat_col);
         }
      case ';':
         //messageNwait("case ;");
         save_pos(p2);

         // check for initializer or declaration
         // int a[] = { 1, 2, 3
         //     4, 5, 6 };
         status = -1;
         left();
         _clex_skip_blanksNpp('-');
         if (get_text() == '}') {
            brace_line := p_line;
            status = find_matching_paren(true);
            if (!status && (p_line == brace_line)) {
               status = -1;
            }
         }
         if (status) {
            restore_pos(p2);
         }
         offset := (int)point('s');
         statdelim_linenum=p_line;
         begin_stat_col=c_begin_stat_col(false /* RestorePos */,
                                         true /* skip first begin statement marker */,
                                         true /* return first non-blank */
                                         );
         //messageNwait('begin_stat_col='begin_stat_col);
         /*
            if () {
                if () printf("");
            } else printf("got here");<ENTER>
         */
         if (get_text()=='}') {
            save_pos(auto semi_p1);
            right();
            _clex_skip_blanks();
            _str semi_word='';
            if (get_text()=='e') {
               semi_word=cur_word(auto semi_junk);
            }
            if (semi_word!='else') {
               restore_pos(semi_p1);
            }
         }

//       say("begin_stat_col="begin_stat_col);
         /* IF there is extra stuff before the beginning of this
               statement
            Example
                x=1;y=2;<ENTER>
                       OR
                for (x=1;<ENTER>
            NOTE:  The following code fragment does not work
                   properly.
                for (i=1;i<j;++i) ++i;<ENTER>
                for (i=1;
                     i<j;<ENTER>
         */
         word=cur_word(junk);
         if (in_objectivec) {
            // Indent for objective-c directive
            cfg = _clex_find(0,'g');
            if (cfg == CFG_KEYWORD && get_text() == '@') {
               switch ('@'word) {
               case '@optional':
               case '@required':
                  p_col += length(word) + 1; // fall-through to check for method decl

               case '@class':
               case '@interface':
               case '@implementation':
               case '@protocol':
                  if (!_objectivec_find_next_class_decl(offset)) {
                     ch = get_text();
                     if (ch == '+'|| ch == '-') {  // start of method decl
                        begin_stat_col = p_col;
                     }
                  }
                  restore_pos(p);
                  return(begin_stat_col);

               case '@package':
               case '@private':
               case '@protected':
               case '@public':
                  if (beaut_indent_members_from_access_spec()) {
                     restore_pos(p);
                     return begin_stat_col + syntax_indent;
                  } else {
                     restore_pos(p);
                     return begin_stat_col + syntax_indent - beaut_member_access_indent();
                  }
                  break;

               case '@dynamic':
               case '@synthesize':
               case '@property':  
               case '@end':
               default:
                  restore_pos(p);
                  return(begin_stat_col);
               }
            }
         }
         save_pos(p3);
         if (word=='for') {
            // Here we try to indent after open brace for
            // loop unless the cursor is after the close paren.
            get_line_raw(line);line=expand_tabs(line);
            col=pos('(',line,1,p_rawpos);
            if (!col) {
               col=p_col;
               restore_pos(p);
               return(col+syntax_indent);
            }
            int result_col=col;
            p_col=col+1;
            search('[~ \t]','@rh');
            cfg=_clex_find(0,'g');
            if (get_text()!='' && cfg!=CFG_COMMENT && cfg!=CFG_STRING) {
               ++result_col;
            }
            p_col=col;
            status=find_matching_paren(true);
            // IF cursor is after close paren of for loop
            if (!status && (orig_linenum>p_line ||
                            (p_line==orig_linenum && orig_col>p_col)
                           )
               ) {
               /*
                   if have the following:
                     while()
                         while ()
                              for ();<ENTER-HERE>
                     <WHAT-TO-BE-HERE>
               */
               if (!pasting_else && dangling_clause_allow_continue_check_orig(word,orig_linenum,orig_col)) {
                  restore_pos(p3);
                  dangling_clause_continue(word);
                  begin_stat_col=p_col;
               }
               // Cursor is after close paren of for loop.
               //messageNwait('f1');
               restore_pos(p);
               return(begin_stat_col);
            }
            // Align cursor after open brace of for loop
            restore_pos(p);
            return(result_col+1);
         }
         /*
             if have the following:
               while()
                   while ()
                        while ();<ENTER-HERE>
               <WHAT-TO-BE-HERE>
         */
         if (!pasting_else && dangling_clause_allow_continue_check_orig(word,orig_linenum,orig_col)) {
            restore_pos(p3);
            dangling_clause_continue(word);
            begin_stat_col=p_col;
         }
         restore_pos(p2);

         // Now check if there are any characters between the
         // beginning of the previous statement and the original
         // cursor position
         //messageNwait('b4');
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         //messageNwait('af col='col' begin_stat_col='begin_stat_col);
         if (col) {
            restore_pos(p);
            return(col);
         }
         restore_pos(p);
         return(begin_stat_col);
      case '}':
         //messageNwait("case }");
         /*
            Don't forget to test

            if (i<j)
               {
               }<ENTER>

            if (i<j)
               {
               }
            else
               {
               }<ENTER>


         */
         if (!pasting_else && dangling_clause_close_brace(orig_linenum,orig_col)) {
            /*
                if have the following:
                  while()
                      while ()
                           while () {}<ENTER-HERE>
                  <WHAT-TO-BE-HERE>
            */
            col=p_col;
            restore_pos(p);
            return(col);
         }
         statdelim_linenum=p_line;
         save_pos(p2);
         /*
            Check if we are in a variable initialization list.
            We don't want to handle this with the HandlePartialStatement statement.
             MYRECORD array[]={
                {a,b,c}
                ,{a,b,c},
                b,<ENTER>
                <End UP HERE, ALIGNED WITH b>

         */
         right();
         _clex_skip_blanks();
         if (get_text()==',') {
            restore_pos(p2);
         } else {
            restore_pos(p2);
            /* Now check if there are any characters between the
               beginning of the previous statement and the original
               cursor position

               Could have
                 struct name {
                 } name1, <ENTER>

                 myproc() {
                 }
                    int i,<ENTER>
            */
            col=HandlePartialStatement(statdelim_linenum,
                                       syntax_indent,syntax_indent,
                                       orig_linenum,orig_col);
            if (col) {
               restore_pos(p);
               return(col);
            }
         }



         /*
             Handle the following cases
             for (;;)
                 {
                 }<ENTER>

                 {
                 }<ENTER>

             MYRECORD array[]={
                {a,b,c}<ENTER>

             MYRECORD array[]={
                {a,b,c}
                ,{a,b,c}<ENTER>

         */
         restore_pos(p2);
         ++p_col;
         style3_MustBackIndent := false;
         col=c_endbrace_col2(be_style, style3_MustBackIndent);
         if (col) {
            if (!style3 || !style3_MustBackIndent) {
               restore_pos(p);
               return(col);
            }
            col-=syntax_indent;
            if (col<1) col=1;
            restore_pos(p);
            return(col);
         }
         restore_pos(p2);
         if (!style3 || !style3_MustBackIndent) {
            col=p_col;
            restore_pos(p);
            return(col);
         }
         col=p_col-syntax_indent;
         if (col<1) col=1;
         restore_pos(p);
         return(col);
      case '=':
         if(in_rust) {
            // Found =>
            save_pos(auto rs_p_eqgt);
            restore_pos(p);
            // If there is a comma at the end of the line, Need to indent to first non-blank (pretty much-- could do more work to be more accurate)
            _end_line();
            search('[^ \t]|^','r@-');
            ch=get_text();
            restore_pos(rs_p_eqgt);
            if (ch==',') {
               _first_non_blank();
               result_col:=p_col;
               restore_pos(p);
               return result_col;
            }
         }
         break;
      case ':':
         bool colon_is_first_char_on_line=false;
         colon_col:=p_col;
         colon_line:=p_line;
         {
            save_pos(auto colon_p);
            first_non_blank();
            colon_is_first_char_on_line=p_col==colon_col;
            restore_pos(colon_p);
         }
         //messageNwait("case :");
         if (_LanguageInheritsFrom('e')){
            // Watch out for :==,:!=, :+, :<=, :>=
            ch=get_text(1,(int)point('s')+1);
            if(ch=='=' || ch=='!' || ch=='<' || ch=='>' || ch=='+' ||  ch=='[' /* :[ ]  Slick-C operator*/) {
               status=repeat_search();
               continue;
            }
         }
         if (p_col!=1) {
            left();
            if (get_text()==":") {
               // skip ::
               //messageNwait('skip ::');
               status=repeat_search();
               continue;
            }
            right();
         }

         if (in_objectivec) {
            // This could be the colon in "@interface ClassName : Superclass
            save_pos(auto ip2);
            left();
            _clex_skip_blanks('-');
            begin_word();
            left();
            _clex_skip_blanks('-');
            begin_word();
            ty := _clex_find(0, 'G');
            if (ty == CFG_KEYWORD && cur_word(junk) == 'interface') {
               _first_non_blank();
               col = p_col;
               restore_pos(p);
               return col;
            }
            if (ty == CFG_KEYWORD && cur_word(junk) == 'class') {
               _first_non_blank();
               col = p_col;
               restore_pos(p);
               return col;
            }
            restore_pos(ip2);

            // need to differentiate label, access modifer, or objc method argument
            _objectivec_message_statement(objc_bracket_count, auto indent_col, auto bracket_col, auto arg_col, auto arg_count);
            if (indent_col > 0) {
               restore_pos(p);
               return(indent_col);
            }
            if (objectivec_inside_dict_literal()) {
               _first_non_blank();
               col = p_col;
               restore_pos(p);
               return col;
            }
         }

         if (_LanguageInheritsFrom('as') || in_javascript || in_typescript) {
            // this could be part of an ActionScript declaration
            // var n:Number
            // function a(n:Number, b:Array
            //
            // this could be in Javascript object literal notation
            // var n = { a : 1, b : 1,
            in_json = in_javascript || in_typescript;
            status=repeat_search();
            continue;
         }

         save_pos(p2);
         typeless t1,t2,t3,t4;
         save_search(t1,t2,t3,t4);
         bool probably_constructor_initializer_list_colon;
         b := _isQmarkExpression(probably_constructor_initializer_list_colon);
         //messageNwait('isQmark='b);
         restore_pos(p2);
         restore_search(t1,t2,t3,t4);

         if (_LanguageInheritsFrom('c') && probably_constructor_initializer_list_colon &&
             beaut_should_indent_leading_cons_colon()) {
            if (colon_is_first_char_on_line) {
               /*
                 myclass::myclass()
                     : <ENTER HERE>
                       m_Buffer(0),<ENTER HERE>
                       m_End(0),
                       m_Count(0) {
               */
               // This is how the C++ beautifier handles this when "indent leading
               // initializer colon" is on.
               restore_pos(p);
               return colon_col+2;
            }
            /*
                 myclass::myclass(): <ENTER HERE>
             
            */
            save_pos(p2);
            restore_pos(p);
            if (p_col==1) {
               up();_end_line();
            } else {
               left();
            }
            _clex_skip_blanks('h-');
            pressed_enter_on_colon:=(p_col==colon_col && p_line==colon_line);
            if (pressed_enter_on_colon) {
               col=HandlePartialStatement(statdelim_linenum,
                                          syntax_indent,syntax_indent,
                                          orig_linenum,orig_col);
               restore_pos(p);
               return(col+syntax_indent);
            }
            restore_pos(p2);
         }
         if (b) {
            //skip this question mark expression colon
            /*
               NOTE: We could handle the following case better here:
               myproc(b,
                     (c)?s:<ENTER>
                     )
               which is different from
               myproc(b,
                     (c)?s:t,<ENTER>
                     )
            */
            status=repeat_search();
            continue;
         }

         /* Now check if there are any characters between the
            beginning of the previous statement and the original
            cursor position

            Could have
             case 'a':
                 int i,<ENTER>

            MyConstructor(): a(1),<ENTER>b(2)
         */
         col=HandlePartialStatement(statdelim_linenum,
                                    syntax_indent,syntax_indent,
                                    orig_linenum,orig_col);
         if (col) {
            //messageNwait('c1');
            restore_pos(p);
            return(col);
         }
         //messageNwait('c2');

         restore_pos(p2);


         /*

             default:<ENTER>
             case ???:<ENTER>
             (abc)? a: b;<ENTER>
             class name1:public<ENTER>
         */
         begin_stat_col=c_begin_stat_col(false /* RestorePos */,
                                         true /* skip first begin statement marker */,
                                         true /* return first non-blank */,
                                         true
                                         );

//       say("colon begin_stat_col:"begin_stat_col);
         if (searchCount == 1) {
            word=cur_word(junk);
            if (word=='case' || word=='default') {
               _first_non_blank();
               // IF the 'case' word is the first non-blank on this line
               if (p_col==begin_stat_col) {
                  col=p_col;
                  restore_pos(p);
                  //messageNwait('c3');
                  return(col);
               }
            } else if (_c_is_member_access_kw(word':')) {
               if (beaut_indent_members_from_access_spec()) {
                  restore_pos(p);
                  return begin_stat_col + syntax_indent;
               } else {
                  restore_pos(p);
                  return begin_stat_col + syntax_indent - beaut_member_access_indent();
               }
            }
         }
         //messageNwait('c4');
         restore_pos(p);
         return(begin_stat_col+syntax_indent);
      default:
         if (cfg==CFG_KEYWORD) {
            /*
               Cases
                 if ()
                    if () <ENTER>
                 for <ENTER>

            */
            _first_non_blank();
            col=p_col+syntax_indent;
            restore_pos(p);
            return(col);
         }
      }

      status=repeat_search();
   }

}
int _kotlin_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, kotlin_space_words, prefix, min_abbrev);
}

int _kotlins_get_syntax_completions(var words, _str prefix="", int min_abbrev=0)
{
   return AutoCompleteGetSyntaxSpaceWords(words, kotlin_space_words, prefix, min_abbrev);
}

int _c_get_syntax_completions(var words)
{
   typeless space_words;
   if (_LanguageInheritsFrom('phpscript')) {
      space_words = php_space_words;
   } else if (_LanguageInheritsFrom('idl')) {
      space_words = idl_space_words;
   } else if (_LanguageInheritsFrom('cs')) {
      space_words = cs_space_words;
   } else if (_LanguageInheritsFrom('js') || _LanguageInheritsFrom('cfscript')) {
      space_words = javascript_space_words;
   } else if (_LanguageInheritsFrom('typescript')) {
      space_words = typescript_space_words;
   } else if (_LanguageInheritsFrom('java')) {
      space_words = java_space_words;
   } else if (_LanguageInheritsFrom('d')) {
      space_words = d_space_words;
   } else if (_LanguageInheritsFrom('ansic')) {
      space_words = ansic_space_words;
   } else if (_LanguageInheritsFrom('m')) {
      space_words = objc_space_words;
   } else if (_LanguageInheritsFrom('groovy')) {
      space_words = groovy_space_words;
   } else {
      space_words = cpp_space_words;
   }

   return AutoCompleteGetSyntaxSpaceWords(words,space_words,0);
}
bool c_else_followed_by_brace_else(_str word)
{
   // this must be an else if
   if (!pos('else',word) || !pos('if',word)) {
      return false;
   }

   status := 0;
   found_brace_else := false;
   typeless p;
   typeless s1,s2,s3,s4;
   save_pos(p);
   save_search(s1,s2,s3,s4);

   _first_non_blank();

   status=search('[^ \t\n\r]','@-rhXc');
   if (status || get_text() != '}') {
      restore_search(s1,s2,s3,s4);
      restore_pos(p);
      return false;
   }

   close_brace_col := p_col;

   restore_pos(p);
   _end_line();
   status=search('[^ \t\n\r]','@rhXc');
   if (status==0 && get_text()=='}' && p_col == close_brace_col) {
      right();
      c_next_sym();
      if (c_sym_gtkinfo()=='else') {
         found_brace_else=true;
      }
   }

   restore_search(s1,s2,s3,s4);
   restore_pos(p);
   return found_brace_else;
}
// is the code above the current line (which contains 'while')
// a partial do {  } while loop?
bool c_while_is_part_of_do_loop()
{
   // save search options and cursor position
   found_do_loop := false;
   save_pos(auto p);
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   do {
      // back up from identifier
      up(); _end_line();
      status := _clex_skip_blanks('h-');
      if (status) {
         break;
      }

      // should find a brace block
      if (get_text() != '}') {
         break;
      }
      status = find_matching_paren(true);
      if (status) {
         break;
      }
      if (get_text() != '{') {
         break;
      }

      // skip backwards to keyword before brace block
      if (_QROffset() <= 0) {
         break;
      }
      _GoToROffset(_QROffset()-1);
      status = _clex_skip_blanks('h-');
      if (status) {
         break;
      }
      if (cur_identifier(auto start_col) == 'do') {
         found_do_loop = true;
      }

   } while (false);

   // restore search options and cursor position
   restore_search(s1,s2,s3,s4,s5);
   restore_pos(p);
   return found_do_loop;
}

static int c_expand_space()
{
   expansion_start := _QROffset();
   expansion_end := 0L;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
   doSyntaxExpansion := LanguageSettings.getSyntaxExpansion(p_LangId);

   status := 0;
   orig_line := "";
   get_line(orig_line);
   line := strip(orig_line,'T');
   orig_word := strip(line);
   if ( p_col!=text_col(_rawText(line))+1 ) {
      return(1);
   }
   was_in_preprocessing := _in_c_preprocessing();

   // check for leading brace
   nobrace_word := orig_word;
   _maybe_strip(nobrace_word, '{', stripFromFront:true);

   set_surround_mode_start_line();
   open_paren_case := (last_event()=='(');
   semicolon_case := (last_event()==';');
   if_special_case := false;
   else_special_case := false;
   pick_else_or_else_if := false;
   brace_before := "";
   aliasfilename := "";
   is_cpp := false;
   is_java := false;
   is_javascript := false;
   is_idl := false;
   is_php := false;
   is_csharp := false;
   is_dlang := false;
   is_go := false;
   is_rust := false;
   is_r := false;
   is_kotlin:=false;
   is_typescript:=_LanguageInheritsFrom('typescript');
   if (_LanguageInheritsFrom('java') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('d')) {
      is_java=true;
   } else if (_LanguageInheritsFrom('js') || _LanguageInheritsFrom('cfscript') || _LanguageInheritsFrom('as')) {
      is_javascript=true;
      is_java=true;
   }
   word := "";
   if (semicolon_case) {
      word=min_abbrev2(nobrace_word,c_semicolon_words,"",
                       aliasfilename,false,open_paren_case);
   } else if (_LanguageInheritsFrom('phpscript')) {
      word=min_abbrev2(nobrace_word,php_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_php=true;
   } else if (_LanguageInheritsFrom('idl')) {
      is_idl=true;
      word=min_abbrev2(nobrace_word,idl_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (_LanguageInheritsFrom('cs')) {
      word=min_abbrev2(nobrace_word,cs_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_csharp=true;
   } else if (_LanguageInheritsFrom('d')) {
      word=min_abbrev2(nobrace_word,d_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_dlang=true;
   } else if (_LanguageInheritsFrom('ansic')) {
      word=min_abbrev2(nobrace_word,ansic_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (_LanguageInheritsFrom('m')) {
      word=min_abbrev2(nobrace_word,objc_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (_LanguageInheritsFrom('googlego')) {
      word=min_abbrev2(nobrace_word,googlego_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_go = true;
   } else if (is_typescript) {
      word=min_abbrev2(nobrace_word,typescript_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (is_javascript) {
      word=min_abbrev2(nobrace_word,javascript_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (is_java) {
      word=min_abbrev2(nobrace_word,java_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (_LanguageInheritsFrom('groovy')) {
      word=min_abbrev2(nobrace_word,groovy_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   } else if (_LanguageInheritsFrom('rs')) {
      word=min_abbrev2(nobrace_word,rust_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_rust = true;
   } else if (_LanguageInheritsFrom('r')) {
      word=min_abbrev2(nobrace_word,r_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_r=true;
   } else if (_LanguageInheritsFrom('kotlin')) {
      word=min_abbrev2(nobrace_word,kotlin_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
      is_kotlin=true;
   } else {
      is_cpp = _LanguageInheritsFrom('c');
      word=min_abbrev2(nobrace_word,cpp_space_words,"",
                       aliasfilename,!open_paren_case,open_paren_case);
   }

   // can we expand an alias?
   if (!semicolon_case && !maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return expandResult;
   }

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
      } else if (is_php && first_word=='}' && second_word!='' && rest=='' && second_word:==substr('elseif',1,length(second_word))) {
         word='} elseif';
         if_special_case=true;
      } else if (is_php && second_word=='' && length(first_word)>1 && first_word:==substr('}elseif',1,length(first_word))) {
         word='}elseif';
         if_special_case=true;
      } else if (!is_idl && first_word=='}' && second_word!='' && rest=='' && second_word:==substr('catch',1,length(second_word))) {
         word='} catch';
         if_special_case=true;
      } else if (!is_idl && second_word=='' && length(first_word)>1 && first_word:==substr('}catch',1,length(first_word))) {
         word='}catch';
         if_special_case=true;
      } else if (!is_idl && first_word=='}' && second_word!='' && rest=='' && second_word:==substr('finally',1,length(second_word))) {
         word='} finally';
         else_special_case=true;
      } else if (!is_idl && second_word=='' && length(first_word)>1 && first_word:==substr('}finally',1,length(first_word))) {
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
      } else if (is_go && first_word == 'type') {
         parse rest with auto third_word rest;
         if (rest == '' && (third_word == 'struct' || third_word == 'interface')) {
            word = 'type';
         }
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
      if (is_php || _LanguageInheritsFrom('rul')) {
         word=min_abbrev2('els',php_space_words,'','');
      } else {
         word=min_abbrev2('els',else_space_words,'','');
      }
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

   // special case for open parenthesis (see c_paren)
   updateAdaptiveFormattingSettings(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS);
   noSpaceBeforeParen := p_no_space_before_paren;
   if ( open_paren_case ) {
      noSpaceBeforeParen = true;
      if ( length(word) != length(nobrace_word) ) {
         return 1;
      }
      switch ( word ) {
      case 'if':
      case 'elseif':
      case 'while':
      case 'for':
      case 'else if':
      case 'catch':
      case 'using':
      case 'with':
      case 'foreach':
      case 'lock':
      case 'fixed':
      case 'switch':
      case 'return':
      case 'yield':
      case 'co_await':
      case 'co_return':
      case 'co_yield':
         break;
      default:
         return 1;
      }
   }

   // special case for semicolon
   insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   if ( semicolon_case ) {
      insertBraceImmediately = false;
      if (!c_semicolon_words._indexin(word)) {
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
   _str maybespace=(noSpaceBeforeParen)?'':' ';
   _str parenspace=(p_pad_parens)? ' ':'';

   // google go doesn't really use parens here
   // maybe make this optional someday
   _str openparen=(is_go || is_rust) ? '' : '(';
   _str closeparen=(is_go || is_rust) ? '' : ')';

   bracespace := ' ';
   line=substr(line,1,length(line)-length(nobrace_word)):+word;
   int width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   bes_style := beaut_style_for_keyword(word, auto gotaval);

   style2 := bes_style == BES_BEGIN_END_STYLE_2;
   style3 := bes_style == BES_BEGIN_END_STYLE_3;
   e1 := " {";
   if (! ((word=='do' || word=='try' || word=='finally' || word=='}finally' || word=='} finally' || word=='when') && !style2 && !style3) ) {
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

   // sometimes we just add some spacing, which is not
   // worth notifying the user over
   doNotify := true;
   if ( word=='main' ) {
      if (_LanguageInheritsFrom('java') || p_LangId == 'groovy') {
         save_pos(auto p);
         int col=find_class_col();
         restore_pos(p);
         // If there is no class in this file
         if (!col) {
            replace_line("public class "_strip_filename(p_buf_name,"pe")" {");
            width=syntax_indent;
            insert_line(indent_string(width)'public static void main (String args[]) {');
         } else {
            replace_line(indent_string(width)'public static void main (String args[]) {');
         }
         insert_line('');
         insert_line(indent_string(width)'}');
         if (!col) {
            insert_line("}");
            expansion_end = _QROffset();
            up();
         }
         up();p_col=width+((indent_fl)?syntax_indent:0)+1;

         // let the user know we did something
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

         return(0);
      } else if (_LanguageInheritsFrom('cs')) {
         save_pos(auto p);
         int col=find_class_col();
         restore_pos(p);
         // If there is no class in this file
         if (!col) {
            replace_line("using System;");
            insert_line("class "_strip_filename(p_buf_name,"pe")" {");
            width=syntax_indent;
            insert_line(indent_string(width)'public static void Main (string []args) {');
         } else {
            replace_line(indent_string(width)'public static void Main (string []args) {');
         }
         insert_line('');
         insert_line(indent_string(width)'}');
         if (!col) {
            insert_line("}");
            up();
         }
         up();p_col=width+((indent_fl)?syntax_indent:0)+1;

         // let the user know we did something
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
         return(0);
      } else if (_LanguageInheritsFrom('d')) {
         // If there is no class in this file
         replace_line(indent_string(width)'void main (char[][] args)');
         insert_line(indent_string(width)'{');
         insert_line("");
         insert_line(indent_string(width)'}');
         up();p_col=width+((indent_fl)?syntax_indent:0)+1;

         // let the user know we did something
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

         return(0);
      } else if (_LanguageInheritsFrom('swift')) {
         // If there is no class in this file
         replace_line(indent_string(width)'func main(args: [String])');
         insert_line(indent_string(width)'{');
         insert_line("");
         insert_line(indent_string(width)'}');
         insert_line(indent_string(width)'main(Process.arguments)');
         up();up();p_col=width+((indent_fl)?syntax_indent:0)+1;

         // let the user know we did something
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

         return(0);
      } else if (_LanguageInheritsFrom('rs')) {
         if (width==0) {
            // If there is no class in this file
            replace_line(indent_string(width)'fn main() {');
            insert_line("");
            insert_line(indent_string(width)'}');
            //insert_line(indent_string(width)'main(Process.arguments)');
            up();p_col=width+((indent_fl)?syntax_indent:0)+1;

            // let the user know we did something
            notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

            return(0);
         } else {
            replace_line(line' ');_end_line();
            return 0;
         }
      } else if (_LanguageInheritsFrom('c')) {
         status=c_insert_main();
      }
   } else if ( word=='if' || word=='elseif' || word=='else if' || word=='catch' || if_special_case) {
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      //replace_line(line:+maybespace:+'('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,c_else_followed_by_brace_else(word),openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
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
   } else if (else_special_case || word=='finally' || word == '}finally' || word == '} finally') {
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
      _end_line();
   } else if ( is_dlang && (word=='body' || word=='in' || word=='out' || word=='invariant' || word=='unittest')) {
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, true, width,word);
      _end_line();
   } else if ( is_dlang && word=='template') {
      replace_line(line:+maybespace' ('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      maybe_autobracket_parens();
      p_col += 1+length(parenspace);
      add_hotspot();
      p_col -= 1+length(parenspace);
      left();
      add_hotspot();
   } else if ( word=='for' || (word=='with' && (is_javascript || is_typescript)) || (word=='with' && is_dlang) ) {
      //replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately, width, word, false, openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='while' ) {
      if (c_while_is_part_of_do_loop()) {
         replace_line(line:+maybespace'('parenspace:+parenspace');');
         _end_line();
         p_col -= 2;
         if (p_pad_parens) --p_col;
         maybe_autobracket_parens();
      } else {
         //replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
         replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,false,!is_rust);
         if(openparen!='') maybe_autobracket_parens();
         add_hotspot();
      }
   } else if ( word=='when' && is_kotlin) {
      /* Kotlin has two forms of when
           when (expr) {...}
               AND
           when {...}
         Here we just expand to the first which is more common. Arguably, the second form should never have been
         supported. If a user doesn't like it, use can define an alias for "when" to do something else.
      */
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      //replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,false,!is_rust);
      if(openparen!='') maybe_autobracket_parens();
      //if(e1!='') left();messageNwait('h1');
      add_hotspot();
   } else if ( word=='match' ) {
      //replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,false,openparen!='');
      if(openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if ( ((word=='loop' && is_rust) || (word=='repeat' && is_r)) && insertBraceImmediately) { 
      replace_line(line:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word,false,openparen!='');
      nosplit_insert_line();
      p_col=width+syntax_indent+1;
      set_surround_mode_end_line(p_line+1);
   } else if ( word=='using' ) {
      if (_in_function_scope()) {
         replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
         add_hotspot();
         maybe_autobracket_parens();
      } else {
         replace_line(line' ');
         _end_line();
         expansion_end = _QROffset();
         // only notify if something changed
         doNotify = (line != orig_line);
      }
   } else if ( word=='foreach' || word=='foreach_reverse' ) {
      if (_LanguageInheritsFrom('d')) {
         replace_line(line:+maybespace'( , )'e1);
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
         add_hotspot();
         p_col+=3;
         add_hotspot();
         p_col-=3;
      } else {
         replace_line(line:+maybespace'( in )'e1);
         expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
         add_hotspot();
         p_col+=4;
         add_hotspot();
         p_col-=4;
      }
   } else if ( word=='lock' || word=='fixed' ) {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
   } else if ( is_dlang && ( word=='debug' || word=='version') ) {
      replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      add_hotspot();
   } else if ((is_idl || is_php || is_dlang) && pos(' 'word' ',' exception interface struct class module union ' )) {
      replace_line(line' 'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      if (maybespace:==' ') {
         left();
      }

      doNotify = (insertBraceImmediately || line != orig_line);
   } else if ((is_idl || is_dlang) && word=='union') {
      replace_line(line'  switch'maybespace'('parenspace:+parenspace')'e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      left();
      maybe_autobracket_parens();
   } else if (word=='enum' && (is_java || is_dlang || is_typescript)) {
      replace_line(line:+maybespace:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      left();
      add_hotspot();
      doNotify = (e1 != '' || insertBraceImmediately || line != orig_line);
   } else if (is_java && word=='@interface') {
      replace_line(line:+maybespace:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      left();
      add_hotspot();
      doNotify = (e1 != '' || insertBraceImmediately || line != orig_line);
   } else if (word=='@class' || word=='@interface' || word=='@implementation' || word=='@protocol') {
      replace_line(line:+' ');
      insert_line(indent_string(width)'@end');
      add_hotspot();
      up(1); _end_line();
   } else if ((is_java && !is_javascript) && (word=='interface' || word=="class")) {
      command_line := p_line;
      classNested := _c_last_struct_col(auto what) > 0;

      className := _strip_filename(p_buf_name,'PE');
      if (classNested) {
         className = '';
      }

      replace_line(line" "className:+e1);
      expansion_end = _c_maybe_insert_braces(false, insertBraceImmediately, width, word);
      p_col = width+length(word)+2;
      add_hotspot();
      if (!classNested) {
         _GoToROffset(expansion_end);
         find_matching_paren(true);
         p_col += 1;
      }
   } else if (is_idl && word=='sequence') {
      replace_line(line:+maybespace:+'<>');
      _end_line();left();
   } else if ( (word=='public' || word=='private' || word=='protected') &&
               !is_kotlin && !is_java && !is_typescript && p_LangId!='tagdoc' && _in_class_scope()) {
      replace_line(line':');_end_line();
      _c_do_colon();
   } else if ( word=='switch' || (is_go && word == 'select') ) {
      //replace_line(line:+maybespace'('parenspace:+parenspace')'e1);
      replace_line(line:+maybespace:+openparen:+parenspace:+parenspace:+closeparen:+e1);
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word, false, openparen!='');
      if (openparen!='') maybe_autobracket_parens();
      add_hotspot();
   } else if ( word=='do' ) {
      insertBraceImmediately=true;  // do doesn't work well when not inserting braces immediately
      // Always insert braces for do loop unless braces are on separate
      // line from do and while statements
      num_end_lines := 1;
      replace_line(line:+e1);
      if ( ! style3 ) {
         if (style2 ) {
            insert_line(indent_string(width)'{');
         }
         insert_line(indent_string(width)'}'bracespace'while':+maybespace'('parenspace:+parenspace');');
         _end_line();
         expansion_end = _QROffset();
         p_col -= 2;

         updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
         if (p_pad_parens) p_col--;
         add_hotspot();
         up();
      } else if ( style3 ) {
         if (insertBraceImmediately) {
            num_end_lines=2;
            insert_line(indent_string(width+syntax_indent)'{');
            insert_line(indent_string(width+syntax_indent)'}');
            insert_line(indent_string(width)'while':+maybespace'('parenspace:+parenspace');');
            _end_line();
            expansion_end = _QROffset();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(2);
            //syntax_indent=0;
         } else {
            insert_line(indent_string(width)'while'maybespace:+'('parenspace:+parenspace');');
            _end_line();
            expansion_end = _QROffset();
            p_col -= 2;
            updateAdaptiveFormattingSettings(AFF_PAD_PARENS);
            if (p_pad_parens) p_col--;
            add_hotspot();
            up(1);
            //syntax_indent=0
         }
      }
      nosplit_insert_line();
      set_surround_mode_end_line(p_line+1, num_end_lines);
      p_col=width+syntax_indent+1;
      add_hotspot();
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
            insert_line(indent_string(width)'}'bracespace'catch':+maybespace'('parenspace:+parenspace')'e1);
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
   } else if ( word=='printf' ) {
      replace_line(indent_string(width)'printf("');
      _end_line();
   } else if ( ((is_javascript || is_typescript) && (word=='export' || word=='function' || word=='import' || word=='var')) || 
               (is_kotlin && word=='import') ||
               (is_cpp && (word=='export'|| word=='import' || word=="module")) ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if ( word=="return" || word=="co_return" || word=="co_yield" ) {
      if (nobrace_word=='return' || nobrace_word=="co_return" || nobrace_word=="co_yield") {
         return(1);
      }
      IsVoid := false;
      tag_lock_context(true);
      _UpdateContext(true);
      int context_id=tag_current_context();
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
      tag_unlock_context();
      newLine := line;
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
   } else if ( word=='continue' || word=='break' || word=='next') {
      // Java allows labels to follow continue or break
      if (nobrace_word==word) {
         if (semicolon_case) {
            replace_line(line';');
         } else {
            replace_line(line' ');
         }
         doNotify = false;
      } else {
         if ((is_java || is_typescript) && !semicolon_case) {
            newLine := line' ';
            replace_line(newLine);
            doNotify = (newLine != orig_line);
         } else {
            if (is_r || is_kotlin) {
               replace_line(line);
            } else {
               replace_line(line';');
            }
         }
      }
      _end_line();
   } else if ( word=='case' ) {
      if ( name_on_key(ENTER):=='nosplit-insert-line' ) {
         replace_line(line' :');
         _end_line();_c_do_colon();p_col=p_col-1;
         if ( ! _insert_state() ) _insert_toggle();
      } else {
#if 1
         // Code which inserts case
         replace_line(line' :');
         _end_line();_c_do_colon();_rubout();
#else
         // Code which inserts case and colon and
         // puts user in insert mode.
         replace_line(line' :');
         _end_line();_c_do_colon();p_col=p_col-1;
         if ( ! _insert_state() ) _insert_toggle();
#endif
      }
   } else if ( word=='default' && !is_typescript) {
      in_switch_statement := true;
      if (_LanguageInheritsFrom("java")) {
         // Use statement tagging to find the matching block start/end for break and continue.  
         in_switch_statement = false;
         _UpdateStatements(true);
         statement_id := tag_current_statement();
         while (statement_id > 0) {
            tag_get_detail2(VS_TAGDETAIL_statement_type, statement_id, auto statement_type);
            tag_get_detail2(VS_TAGDETAIL_statement_name, statement_id, auto statement_name);
            if (statement_type=="switch" || (statement_type=="if" && substr(statement_name, 1, 6)=="switch")) {
               in_switch_statement = true;
               break;
            }
            if (tag_tree_type_is_func(statement_type) || tag_tree_type_is_class(statement_type) || tag_tree_type_is_package(statement_type)) {
               break;
            }
            tag_get_detail2(VS_TAGDETAIL_statement_outer, statement_id, statement_id);
         }
      }
      if (in_switch_statement) {
         replace_line(line':');_end_line();
         _c_do_colon();
      } else {
         replace_line(line' ');_end_line();
      }
   } else if ( word=='template') {
      // auto-insert angle brackets for template
      replace_line(line:+maybespace'<>');
      _end_line(); add_hotspot(); left(); add_hotspot();
   } else if ( word=='static' || word=='const' || word=="extern" ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_cpp && (word=='co_await' || word=='co_yield')) {
      newLine := line;
      replace_line(newLine);
      _end_line();
      keyin(' ');
      doNotify = (newLine != orig_line);
   } else if (is_cpp && (word=='static_cast' || word=='const_cast' || word == 'reinterpret_cast' || word=='dynamic_cast')) {
      cast_op := "";
      int h1, h2;
      cast_op = line:+maybespace'<'parenspace;
      h1 = length(cast_op) + 1;
      cast_op :+= parenspace'>':+maybespace'('parenspace;
      h2 = length(cast_op) + 1;
      cast_op :+= parenspace')';
      replace_line(cast_op);
      p_col = h2; add_hotspot();
      p_col = h1; add_hotspot();
      _end_line(); add_hotspot();
      expansion_end = _QROffset();
      p_col = h1;
   } else if ( word=="#include" && LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_QUOTED_ON_SPACE ) {
      replace_line(indent_string(width)word' ');
      _end_line();
      AutoBracketKeyin('"');
      _do_list_members(OperatorTyped:false, DisplayImmediate:true);
      if (get_text() == '"') {
         message("Press '<' to convert #include "" to #include <>");
      }
   } else if (is_go && word == 'func') {
      replace_line(line' () {');
      start_offset := _QROffset();
      expansion_end = _c_maybe_insert_braces(noSpaceBeforeParen, insertBraceImmediately,width,word);
      p_col = length(line) + 5;
      add_hotspot();
      p_col -= 2;
      add_hotspot();
      close_offset := _QROffset();
      p_col -= 1;
      add_hotspot();
      if (se.autobracket.AutoBracketListener.isEnabledForKey('(')) {
         se.ui.AutoBracketMarker.createMarker(')', start_offset, 1, close_offset, 1, -1, close_offset-1, 1);
      }
   } else if (is_go && word == 'map') {
      replace_line(line:+'[]');
      p_col = length(line) + 3;
      add_hotspot();
      p_col -= 1;
      add_hotspot();
   } else if ( pos(' 'word' ',EXPAND_WORDS) || ((word=='package' || word=='typealias') && is_kotlin) || ((word=='interface' || word=='type' || word=='let' || word=='default') && (is_typescript || is_javascript))) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_java && !is_javascript && pos(' 'word' ',JAVA_ONLY_EXPAND_WORDS) ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_csharp==1 && pos(' 'word' ',CS_ONLY_EXPAND_WORDS) ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_dlang==1 && d_space_words._indexin(word) && d_space_words:[word].statement==word) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_idl==1 && pos(' 'word' ',IDL_ONLY_EXPAND_WORDS) ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
   } else if (is_php==1 && pos(' 'word' ',PHP_ONLY_EXPAND_WORDS) ) {
      newLine := line' ';
      replace_line(newLine);
      _end_line();
      doNotify = (newLine != orig_line);
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

   if (!was_in_preprocessing && expansion_end >= expansion_start
       && beautify_syntax_expansion(p_LangId)) {
      long markers[];

      new_beautify_range(expansion_start, expansion_end, markers, true, false, false);
   } else if (!do_surround_mode_keys(false, NF_SYNTAX_EXPANSION) && doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   if (open_paren_case) {
      AutoBracketCancel();
   }

   return(status);
}


int _java_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _java_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _cs_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _cs_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
bool _cs_is_xmldoc_preferred()
{
   return true;
}
int _e_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _e_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _js_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _js_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _typescript_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _typescript_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _as_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _as_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _awk_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _awk_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _pl_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _pl_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _phpscript_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _phpscript_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _cfscript_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _cfscript_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _ansic_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _ansic_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}
int _m_delete_char(_str force_wrap='')
{
   return _c_delete_char(force_wrap);
}
int _m_rubout_char(_str force_wrap='')
{
   return _c_rubout_char(force_wrap);
}

// Starting with the cursor on an open brace, find the start
// column for the keyword of the current statement.
static int get_statement_kw_column()
{
   status := 0;
   save_pos(auto p);

   loop {
      // skip backwards from open brace
      left();
      status = _clex_skip_blanks('-h');
      if (status < 0) break;

      // if we find a paren block, the skip to open paren
      if (get_text() == ')') {
         status = find_matching_paren(true);
         if (status) return status;
         left();
         status = _clex_skip_blanks('-h');
         if (status < 0) break;
      }

      // we expect to be on a keyword now
      if (_clex_find(0, 'g') != CFG_KEYWORD) {
         break;
      }

      // get the keyword and start column
      save_pos(auto kw_pos);
      kw := cur_identifier(status);
      if (kw == '') {
         status = STRING_NOT_FOUND_RC;
      }

      // check for extended "else if" statement
      if (kw=='if') {
         // skip 'if' keyword and spaces
         p_col -= 2;
         status = _clex_skip_blanks('-h');
         if (status < 0) {
            // Need this for R language but this shouldn't hurt other languages.
            status=p_col+1;
            break;
         }

         // check for an 'else' keyword, drop back if no else
         if (_clex_find(0, 'g') == CFG_KEYWORD) {
            kw = cur_identifier(status);
         }
         if (kw != 'else') {
            restore_pos(kw_pos);
            kw = cur_identifier(status);
         }
      }

      // check for else block.
      if (kw == 'else') {
         // skip 'else' keyword and spaces
         p_col -= 4;
         status = _clex_skip_blanks('-h');
         if (status < 0) break;

         // check for close brace (ending block)
         if (get_text() == '}') {
            status = find_matching_paren(true);
            if (status) return status;
            continue;
         } else {
            origOffset := _QROffset();
            status = begin_statement();
            if (status) return status;
            if (_QROffset() == origOffset) return STRING_NOT_FOUND_RC;
            continue;
         }

         // restore to the position where we found the keyword
         restore_pos(kw_pos);
         kw = cur_identifier(status);
         break;
      }

      // break out for main loop
      break;
   }

   // that's all, status is either an error <0 or column >0
   restore_pos(p);
   return status;
}

int _c_delete_char(_str force_wrap='')
{
   if (get_text() == '{' && _clex_find(0, 'g')==CFG_PUNCTUATION) {

      // make sure the option is enabled for 'C'
      if (!LanguageSettings.getQuickBrace(p_LangId)) {
         return STRING_NOT_FOUND_RC;
      }

      // get the start column for this statement
      start_col := get_statement_kw_column();
      if (start_col <= 0) {
         // It couldn't decide what the start of this statement was, 
         // see if the tagging can tell.
         save_pos(auto pp);
         status := begin_statement("t");
         if (status == 0) {
            start_col = p_col;
            restore_pos(pp);
         } else {
            // Tagging didn't know, assume the beginning of the line the brace is on is the start.
            restore_pos(pp);
            start_col = _first_non_blank_col(1);
         }
      }

      // check if this is an empty brace block
      save_pos(auto p);
      right();
      _clex_skip_blanks('h');
      empty_braces := (get_text()=='}');
      restore_pos(p);

      // check if this brace has a matching brace somewhere
      orig_line := p_line;
      status := find_matching_paren(true,true);
      if (status) return status;

      // examine the last line of the block, make sure we have a close }
      get_line(auto line);
      line=strip(line);
      if (_first_char(line) != '}' && p_line > orig_line) {
         return STRING_NOT_FOUND_RC;
      }

      // check for 'else' or trailing line comment
      parse substr(line, 2) with auto kw .;
      if (substr(line,2,2)=='//') kw='//';
      if (substr(line,2,2)=='//') kw='/*';
      if (p_line>orig_line && kw!='' && kw!='else' && kw!='else{' && kw!='//' && kw!='/*') {
         return STRING_NOT_FOUND_RC;
      }
      end_col := p_col;
      sameLineCase := (orig_line==p_line);
      deleteBraceOnly := (kw != '');
      joinComment := (kw == '//' || kw == '/*');
      last_line := p_line;
      save_pos(auto close_p);

      // check that we did not match to a brace that doesn't really match
      if (end_col < start_col || end_col > start_col+p_SyntaxIndent) {
         return STRING_NOT_FOUND_RC;
      }

      // is the block too big?
      if (last_line > orig_line+8) {
         return STRING_NOT_FOUND_RC;
      }

      // back to where started, check for the
      // first statement in the block
      restore_pos(p);
      status = next_statement(true);
      if (status && p_line > last_line) {
         return STRING_NOT_FOUND_RC;
      }

      // check if there is another statement in the block
      // if so, then we can not un-brace the block
      status = next_sibling(true);
      if (!status && p_line <= last_line) {
         return STRING_NOT_FOUND_RC;
      }

      // delete the closing brace
      p_line = last_line;
      if (sameLineCase) {
         restore_pos(close_p);
         _delete_char();
         while (get_text():==" " || get_text():=="\t") {
            _delete_char();
         }
      } else if (deleteBraceOnly) {
         _first_non_blank();
         _delete_char();
         while (get_text():==" " || get_text():=="\t") {
            _delete_char();
         }
      } else {
         _delete_line();
      }

      // back to the top, now join the one liner with the
      // current line, depending on brace style
      restore_pos(p);
      get_line(line);
      parse line with auto first_kw .;
      first_kw = strip(first_kw, 'L', " \t}");
      if (sameLineCase) {
         _delete_char();
         while (get_text():==" " || get_text():=="\t") {
            _delete_char();
         }
      } else if (line == '{') {
         _delete_line();
         _first_non_blank();
      } else {
         // check if the line ends with a line comment
         save_pos(auto brace_pos);
         _end_line();
         hasLineComment := _in_comment();
         restore_pos(brace_pos);
         // join the single line statement to the condition line
         oneline_unblocked := beaut_oneline_unblocked_statement();
         if (substr(first_kw,1,2)=="el" /*else, elif, elsif, etc*/) {
            oneline_unblocked = beaut_oneline_unblocked_else();
         } else if (substr(first_kw,1,2) == "if") {
            oneline_unblocked = beaut_oneline_unblocked_else();
         }
         if (force_wrap==1 && !empty_braces && p_line+2 == last_line &&
             p_col <= def_hanging_statements_after_col && oneline_unblocked && !hasLineComment) {
            join_line();
            // if the character to the left of the cursor is alphanumeric
            // add a space to separate it from the joining statement.
            if (isalnum(get_text_left())) {
               _insert_text(' ');
            }
         }
         if (joinComment) {
            orig_col := p_col;
            _end_line();
            _insert_text(' ');
            join_line();
            p_col = orig_col;
         }
         _delete_char();
      }

      // done, turn off dynamic surround
      clear_surround_mode_line();
      return 0;
   }

   return STRING_NOT_FOUND_RC;
}

int _c_rubout_char(_str force_wrap='')
{
   if (p_col <= 1) {
      return STRING_NOT_FOUND_RC;
   }
   save_pos(auto p);
   left();
   status := _c_delete_char(force_wrap);
   if (status) restore_pos(p);
   return status;
}

static void _maybe_skip_else_ladder()
{
   // We assume end-statement has been already been called at this point.
   // For if-else chains, end-statement will only skip over the if, so we 
   // do a little extra work to advance to the end of the chain.  
   // (end-statement-block doesn't help us, it skips over multiple statements,
   // which isn't what we want for quickbrace).
   for (;;) {
      save_pos(auto elsecheck);
      status := search('[^ \t]', '@RXC');
      if (status == 0) {
         xkw := cur_identifier(auto dnc);

         if (xkw == 'else') {
            status = end_statement(true);
            if (status != 0) {
               restore_pos(elsecheck);
               return;
            }
         } else {
            restore_pos(elsecheck);
            return;
         }
      } else {
         restore_pos(elsecheck);
         return;
      }
   }
}

static bool maybe_surround_conditional_statement()
{
   // make sure the option is enabled
   if (!LanguageSettings.getQuickBrace(p_LangId)) {
      return false;
   }

   // check if we should create a selective display region here
   doSelDisp := false;
   seldisp_flags := LanguageSettings.getSelectiveDisplayFlags(p_LangId);
   level_lf := (_lineflags() & LEVEL_LF);
   if ((seldisp_flags & SELDISP_STATEMENT_OUTLINE_ON_OPEN) &&
       _are_statements_supported() && p_NofSelDispBitmaps > 0 && 
       _LevelIndex(level_lf) <= def_seldisp_maxlevel) {
      doSelDisp = true;
   }

   // now attempt to find a brace matching the brace we just put in
   // if it falls in a column that matches the expected indentation
   // then do not insert the closing brace.  If the cursor was past the
   // real end of the line, pretend there were real spaces there.
   save_pos(auto p);
   orig_col := p_col;
   _end_line();
   end_col := p_col;
   _first_non_blank();
   indent_col := p_col;
   if (indent_col == end_col && orig_col > indent_col) {
      indent_col = orig_col;
      p_col = indent_col;
   }

   restore_pos(p);
   _insert_text('{');
   if (!find_matching_paren(true,true)) {
      if (p_col >= indent_col && p_col <= indent_col+p_SyntaxIndent) {
         restore_pos(p);
         _delete_text(1);
         return false;
      }
   }
   restore_pos(p);
   _delete_text(1);
   restore_pos(p);

   // save the original cursor position and seach parameters
   status := 0;
   save_search(auto s1,auto s2, auto s3, auto s4, auto s5);
   // do - while - false
   do {
      orig_line := p_line;

      // skip backwards over whitespace
      left();
      status = search("[^ \t]", '-@r');
      if (status) {
         break;
      }

      // skip line comment if we encounter one
      if (_in_comment()) {
         _clex_skip_blanks('-');
      }

      // if we have a paren, skip backwards over it
      paren_line := p_line;
      haveParen := (get_text()==')');
      if (get_text()==')') {
         status = find_matching_paren(true);
         if (status) {
            break;
         }

         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }
      }

      // check keyword under cursor
      left();
      col := 0;
      kw := cur_identifier(col);
      kw_line := p_RLine;
      if (kw != 'if' && kw != 'for' && kw!='while' && kw!='foreach' && kw!='else') {
         status = STRING_NOT_FOUND_RC;
         break;
      }
      if (kw=='else' && haveParen) {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // check for type 2 or 3 braces
      type23_braces := false;
      if (paren_line == orig_line) {
         type23_braces=false;
      } else if (paren_line < orig_line) {
         type23_braces=true;
      } else {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      // check for "else if"
      if (kw == 'if') {
         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }

         save_pos(auto pif);
         left();
         if_col := 0;
         kw = cur_identifier(if_col);
         if (kw!='else') {
            restore_pos(pif);
         } else {
            col = if_col;
         }
      }

      // check for "} else"
      if (kw == 'else') {
         p_col = col;
         left();
         status = search("[^ \t]", '-@r');
         if (status) {
            break;
         }
         if (get_text() == '}') {
            col = p_col;
         }
      }

      // for type2 and type3 braces, have to be at start of line
      if (type23_braces) {
         restore_pos(p);
         orig_col = p_col;
         _first_non_blank();
         if (p_col < orig_col && !at_end_of_line()) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
      }

      // back where we started
      restore_pos(p);
      status = search('[^ \t]', '@rXC');
      if (status) {
         break;
      }

      leading_kw := cur_identifier(auto nu);

      // make sure we land where we expected
      if (p_col <= col) {
         status = STRING_NOT_FOUND_RC;
         break;
      }

      if (_are_statements_supported()) {
         // make sure that the context doesn't get modified by a background thread.
         se.tags.TaggingGuard sentry;
         sentry.lockContext(false);

         // check that the current statement starts here
         _UpdateStatements(true,true);

         cur_statement_id := tag_current_statement();
         if (cur_statement_id <= 0) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
         tag_get_detail2(VS_TAGDETAIL_statement_start_linenum, cur_statement_id, auto cur_statement_line);
         if (cur_statement_line < kw_line || cur_statement_line > p_RLine) {
            status = STRING_NOT_FOUND_RC;
            break;
         }

         // jump to the end of the conditional statement
         status = end_statement(true);
         if (status) {
            break;
         }

         if (leading_kw == "if") {
            // the end_statement() would have only skipped past the "if" part
            // of an if-else chain, when what we really need to do is scan
            // past the rest of the chain.
            _maybe_skip_else_ladder();
         }
      } else {
         // no statement tagging, so just be stupid and search
         // forward for a semicolon in the next five lines.
         if (search("[{};]", "@r") ||
             get_text() != ";"  ||
             _clex_find(0, "g") == CFG_STRING ||
             _clex_find(0, "g") == CFG_COMMENT ||
             p_RLine > orig_line+10) {
            status = STRING_NOT_FOUND_RC;
            break;
         }
      }

      // insert the closing brace
      updateAdaptiveFormattingSettings(AFF_BEGIN_END_STYLE | AFF_SYNTAX_INDENT);
      if (type23_braces && (p_begin_end_style == VS_C_OPTIONS_STYLE2_FLAG)) {
         insert_line(indent_string(col-1+p_SyntaxIndent):+"}");
      } else {
         insert_line(indent_string(col-1):+"}");
      }
      last_line := p_line;

      // check for trailing else and join to close brace
      save_pos(auto pend);
      down();
      _first_non_blank();
      end_col = 0;
      kw = cur_identifier(end_col);
      restore_pos(pend);
      if (kw=='else' && !type23_braces) {
         if (LanguageSettings.getCuddleElse(p_LangId)) {
            join_line(1);
            _insert_text(' ');
         }
      }

      // check for incorrect brace style, I mean,
      // check for something other than style 1
      restore_pos(p);
      if (type23_braces) {
         if (p_begin_end_style == BES_BEGIN_END_STYLE_2) {
            p_col = col;
         } else if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            p_col = col+p_SyntaxIndent;
         } else {
            p_col = col;
         }
         // re-indent the line using user's preferred tab style
         get_line(auto line);
         line = reindent_line(line, 0);
         replace_line(line);
      }

      // finally, insert the opening brace
      if (!_insert_state() && get_text()==' ') _delete_text(1);
      _insert_text('{');
      strip_trailing_spaces();
      save_pos(p);
      status = search('[^ \t]', '@r');
      if (!status && p_line == orig_line && !_in_comment()) {
         split_line();
         strip_trailing_spaces();
         last_line++;
      }

      // re-indent the statement, no matter how many lines
      down();
      while (p_line < last_line) {
         _first_non_blank();
         while (p_col < col+p_SyntaxIndent) {
            _insert_text(' ');
         }
         get_line(auto line);
         line = reindent_line(line, 0);
         replace_line(line);
         if (down()) break;
      }

      // Create selective display region for newly surrounded code block
      p_line = kw_line;
      if (doSelDisp && !(_lineflags() & (PLUSBITMAP_LF|MINUSBITMAP_LF))) {
         level_lf = (_lineflags() & LEVEL_LF);
         _lineflags(MINUSBITMAP_LF|level_lf,MINUSBITMAP_LF|LEVEL_LF);
         down();
         while (p_line < last_line) {
            level_lf = (_lineflags() & LEVEL_LF);
            _lineflags(level_lf+NEXTLEVEL_LF,LEVEL_LF);
            if (down()) break;
         }
      }

      // drop into dynamic surround so they can move
      // single statement out of the loop if they want to
      //set_surround_mode_start_line(orig_line,1);
      //set_surround_mode_end_line(p_line);
      //restore_pos(p);
      //do_surround_mode_keys(false);

   } while (false);

   restore_pos(p);
   restore_search(s1,s2,s3,s4,s5);
   return status==0;
}

// Returns true for languagea that support same-line brace placement
// for Auto Close.
bool supports_advanced_bracket_cfg(_str langId) 
{
   // Arbitrary - the only real initial limitation is what languages
   // use c_begin()
   return new_beautifier_supported_language(langId) || langId=='e' || langId=='as' || langId=='r' || _LanguageInheritsFrom('kotlin', langId) || langId=='kotlins' || langId=='clojure' || langId=='yaml';
}


// Helper that deals with differences between the languages
// that support same-line bracket placement, and the languages that don't.
int get_autobrace_placement(_str lang) {
   if (supports_advanced_bracket_cfg(lang)) {
      return LanguageSettings.getAutoBracePlacement(lang);
   } else if (LanguageSettings.getInsertBlankLineBetweenBeginEnd(lang)) {
      return AUTOBRACE_PLACE_AFTERBLANK;
   } else {
      return AUTOBRACE_PLACE_NEXTLINE;
   }
}

bool should_expand_cuddling_braces(_str lang) {
   // Assume they don't want any fancy newline behaviors if they've not got
   // Smart Indent on.  
   return (LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE));
}

// Helper for c_expand_begin().  Expects cursor to be between braces.
static void maybe_semicolon_brace()
{
    down();
    get_line(auto cur_line);
    if (_LanguageInheritsFrom('c') && !_LanguageInheritsFrom('d') && cur_line=='}') {
       replace_line(strip(cur_line,'T'):+';');
    }
    if (_LanguageInheritsFrom('e') && cur_line=='}') {
       replace_line(strip(cur_line,'T'):+';');
    }
}

static _str braced_decls = '^[ \t]*(struct |class |union |enum )';
static bool cursor_on_braced_decl()
{
    get_line(auto line);

    if (pos(braced_decls, line, 1, 'U')) {
        return true;
    }

    if (p_line > 1) {
        p_line--;
        save_pos(auto p);
        get_line(line);
        if (pos(braced_decls, line, 1, 'U')) {
            restore_pos(p);
            return true;
        }
        restore_pos(p);
    }

    return false;
}
/* 
   Language just has { ... } and no
   complex loop/if constructs (i.e if(){}).
 
*/ 
static bool _simple_brace_language() {
   return _LanguageInheritsFrom('clojure') || _LanguageInheritsFrom('yaml');
}

// Is this a construct that actually needs a semicolon after a brace?
static bool need_semi_after_construct(_str line)
{
   rv := false;

   if (p_LangId == 'c' || p_LangId == 'ansic') {
      rv = pos('^(?:typedef)? *(?:class|struct|union|enum) ', line, 1, 'L') != 0;
   }

   return rv;
}

static int c_expand_begin()
{
   if (maybe_surround_conditional_statement()) {
      return 0;
   }
   // check if they typed "do{" or "try{"
   get_line(auto line);
   if (!_simple_brace_language()) {
      if (line=='do' || (line=='try' && !_LanguageInheritsFrom('e'))) {
         if (!c_expand_space()) {
            return 0;
         }
      }
   }

   // check that brace expansion is enabled
   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);

   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   if (_first_char(strip(line)) == '}') {
      parse line with '}' line;
   }
   if (!_simple_brace_language()) {
      if (line=='if' || line=='while' || line=='for' ||
          line=='else if' || line=='switch' ||
          line=='with' || line=='lock' || line=='catch' ||
          line=='fixed' || line=='using') {

         insertBraceImmediately := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
         if (!insertBraceImmediately) LanguageSettings.setInsertBeginEndImmediately(p_LangId, true);
         status := c_expand_space();
         if (!insertBraceImmediately) LanguageSettings.setInsertBeginEndImmediately(p_LangId, false);
         if (!status) return 0;
      }
   }

   brace_indent := 0;
   lbo := _QROffset();

   keyin('{');
   get_line(line);
   int pcol=_text_colc(p_col,'P');
   last_word := "";
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);
   if (!_simple_brace_language()) {

      // first, back up and look for a parenthesized expression
      // which would be part of the if, while, or for statement
      left();
      left();
      _clex_skip_blanks('-');
      ch:=get_text();
      if (ch == ':'
          && strip(line) == '{') {
         // Might be for a case or default statement - if so, readjust the indent to 
         // match the formatting settings.
         _first_non_blank();
         wd := _c_get_wordplus();
         if (wd == 'case' || wd == 'default:') {
            ccol := p_col;
            if (0 == beaut_brace_indents_with_case()) {
               ccol += p_SyntaxIndent;
            }
            restore_pos(AfterKeyinPos);
            replace_line(indent_string(ccol-1)'{');
            p_col = ccol+1;
            save_pos(AfterKeyinPos);
            lbo = _QROffset() - 1;
         }
      } else if (_LanguageInheritsFrom('powershell') && (ch:==']' || find_matching_paren(true) != 0)) {
         restore_pos(AfterKeyinPos);
      } else if (get_text()!=')' || find_matching_paren(true) != 0) {
         restore_pos(AfterKeyinPos);
      }
   }

   // compute the simple indentation column for this line
   _first_non_blank();
   indent_col := p_col;

   // now attempt to find a brace matching the brace we just put in
   // if it falls in a column that matches the expected indentation
   // then do not insert the closing brace.  As a sanity check, we 
   // do not want to match an existing end brace of a function with
   // the brace we just typed in.
   orig_expand := expand;
   restore_pos(AfterKeyinPos);
   if (expand && !find_matching_paren(true)) {
      if (p_col >= indent_col && p_col <= indent_col+p_SyntaxIndent) {
         // This looks like it could match, but let's double check and see if this closing
         // brace matches a construct that contains us.  If so, do not reuse the brace.
         // The trick here is we're setting an initialNesting level
         // in a way that the brace we just keyin() is not counted.  
         if (_find_matching_paren(quiet:true, initialNestLevel:1) != 0) {
            expand=false;
         }
      }
   }
   restore_pos(AfterKeyinPos);

   /*
        Don't insert end brace for these cases in a variable initializer
        object array={
           {<DONT EXPAND THIS>
        }
        object array={
           a,{<DONT EXPAND THIS>
        }

   */
   left();
   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   _clex_skip_blanksNpp('-');
   if (get_text()==',' || get_text() == '(') {
      restore_pos(AfterKeyinPos);
      return(0);
   }
   if (get_text()=='{') {
      // This won't work for C because of function variable declarations but should work pretty well for C++
      // Worst case, user has to type close brace
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      _clex_skip_blanksNpp('-');
      if (get_text()!=')') {
         restore_pos(AfterKeyinPos);
         return(0);
      }
   }
   restore_pos(AfterKeyinPos);

   old_linenum := p_line;
   int col=0, old_col=p_col;
   begin_brace_col := 0;
   int status=_clex_skip_blanks();
   end_brace_is_last_char := status || p_line>old_linenum;
   lambdaStartCol := 0;

   restore_pos(AfterKeyinPos);

   // If we're snug against an identifier (not kw), 
   // and it's c++, it's the uniform initializer syntax, 
   // or the regular initializer syntax.
   forceSamelineAutobrace := false;
   if (p_LangId == 'c' && line != '') {
      startLine := p_line;
      left(); left();
      save_pos(auto beforeSkip);
      _clex_skip_blanksNpp('-');
      if (startLine == p_line) {
         if (_clex_find(0,'g') == CFG_KEYWORD) {
            // If it's a return or throw, this is a value/array initializer.
            begin_word();
            wd := cur_word(auto dc);
            if (wd == 'throw' || wd == 'return' || wd == "co_return" || wd == "co_yield" || wd == "co_await" || wd == "yield") {
               forceSamelineAutobrace=true;
            }
         } else {
            // If we're snug against an identifier that's not a class/union/etc decl, 
            // it's the C++ uniform initializer syntax, ie: String{somePtr, len}.
            restore_pos(beforeSkip);
            ch := get_text();
            idc := '['_clex_identifier_chars()']';
            restore_pos(AfterKeyinPos);
            if (pos(idc, ch, 1, 'L') == 1) {
               begin_word();
               prev_word();
               wd := cur_word(auto dc);
               if (_clex_find(0, 'g') != CFG_KEYWORD || pos("^(union|struct|enum|class)$", wd, 1, 'L') <= 0) {
                  // not a class, struct, enum, etc...
                  forceSamelineAutobrace=true;
               }
               restore_pos(AfterKeyinPos);
            }
         }
      }
      restore_pos(AfterKeyinPos);
   }

   if (lambda_decl_before_cursor(true, true, &lambdaStartCol)) {
      begin_brace_col = col = lambdaStartCol;
   } else if ( line!='{' ) {
      if (!end_brace_is_last_char) {
         return(0);
      }
   } else if ( p_begin_end_style != BES_BEGIN_END_STYLE_3 ) {
      /*
          Now that "class name<ENTER>" usually indents, we need
          the begin brace to be moved correctly to align under the
          "class" keyword.
      */
      save_pos(auto p);
      left();
      //begin_brace_col=p_col;
      col= find_block_col();
      if (!col) {
         restore_pos(p);left();
         col=c_begin_stat_col(true,true,true);
      } else {
         // Indenting for class/struct/interface/variable initialization
         /*style=(be_style & VS_C_OPTIONS_STYLE2_FLAG);
         if (style!=0) {
            col=begin_brace_col;
         }*/
      }
      restore_pos(p);
      if (col) {
         expand=orig_expand;
         replace_line(indent_string(col-1)'{');
         _end_line();save_pos(AfterKeyinPos);
      }

   } else if ( p_begin_end_style == BES_BEGIN_END_STYLE_3 ) {
      /*
         A few customers like the way 1.7 let them type braces
         for functions indented.

         Brief does not do this.

      */
      /*
          Now that "class name<ENTER>" usually indents, we need
          the begin brace to be moved correctly to align under the
          "class" keyword.
      */
      save_pos(auto p);
      left();
      begin_brace_col=p_col;
      col= find_block_col();
      if (!col) {
         restore_pos(p);left();
         col=c_begin_stat_col(true,true,true);
         if ((p_begin_end_style == BES_BEGIN_END_STYLE_3) && def_style3_indent_all_braces) {
            col+=syntax_indent;
         }
      } else {
         // find_block_col does not account for brace style, it just returns the statement beginning column.
         if (p_begin_end_style == BES_BEGIN_END_STYLE_3) {
            col+=syntax_indent;
         }
      }
      restore_pos(p);
      if (col) {
         expand=orig_expand;
         replace_line(indent_string(col-1)'{');
         _end_line();save_pos(AfterKeyinPos);
      }

   }
   _first_non_blank();
   int placement = get_autobrace_placement(p_LangId);
   if ( expand ) {
      col=p_col-1;

      indent_fl := LanguageSettings.getIndentFirstLevel(p_LangId);
      if ( (col && (p_begin_end_style == BES_BEGIN_END_STYLE_3)) || (! (indent_fl+col)) ) {
         syntax_indent=0;
      }

      if (forceSamelineAutobrace || placement == AUTOBRACE_PLACE_SAMELINE) {
         // Easy case.  Don't bother with all of the placement juggling in _c_endbrace.
         restore_pos(AfterKeyinPos);
         rbo := _QROffset();
         keyin('}');
         if (need_semi_after_construct(line)) {
            keyin(';');
         }
         AutoBracketForBraces(p_LangId, lbo, rbo);
         restore_pos(AfterKeyinPos);
      } else {
         // Inhibit beautify_on_edit for _c_endbrace, otherwise the following restore_pos() 
         // will end up landing on pointy rocks.
         // It's expected the caller of c_expand_begin 
         // will do a post-call beautify, if necessary.
         insert_line(indent_string(col+brace_indent));
         brace_indent=p_col-1;
         set_surround_mode_start_line(old_linenum);
         _c_endbrace(true);      

         switch (placement) {
         case AUTOBRACE_PLACE_NEXTLINE:
            restore_pos(AfterKeyinPos);
            break;

         case AUTOBRACE_PLACE_AFTERBLANK:
            restore_pos(AfterKeyinPos);
            _end_line();
            c_enter();
            break;
         }
         set_surround_mode_end_line(p_line+1);
      }
   } else {
      restore_pos(AfterKeyinPos);//_end_line();
   }
   typeless done_pos;
   save_pos(done_pos);
   if (_haveContextTagging() && (_LanguageInheritsFrom('c') || _LanguageInheritsFrom('java') || _LanguageInheritsFrom('cs') || _LanguageInheritsFrom('e'))) {
      restore_pos(AfterKeyinPos);
      class_name := "";
      implement_list := "";
      _str class_type_name;
      vsImplementFlags := 0;
      indent_col=c_parse_class_definition(class_name,class_type_name,implement_list,vsImplementFlags,AfterKeyinPos);
      if ( _chdebug ) {
         say("c_expand_begin: class_name="class_name" class_type="class_type_name" implement_list="implement_list" flags="vsImplementFlags);
      }
      if (!indent_col) {
         restore_pos(done_pos);
         // do block surround only if we are already in a function scope
         if (_in_function_scope()) {
            if (!beautify_on_edit()) {
               // Only do this if we're not going to beautify it after the call to c_expand_begin().
               // Otherwise, you get a weird looking beautify update once surround mode exits.
               do_surround_mode_keys();
            }
         } else {
            clear_surround_mode_line();
         }
         return(0);
      }

      clear_surround_mode_line();
      restore_pos(AfterKeyinPos);
      /*
         For simplicity, remove blank line that was inserted
      */
      if (expand && placement == AUTOBRACE_PLACE_AFTERBLANK ) {
         down();
         _delete_line();
         restore_pos(AfterKeyinPos);
      }
      int count;
      //messageNwait('class_name='class_name' implement_list='implement_list);
      tag_lock_context();
      _UpdateContext(true);

      int context_id=tag_current_context();

      // The context in this area may be a little bit fidgety,
      // since we're in the process of editing it.  Search upwards
      // for an enclosing package/namespace.
      while (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type, context_id, auto tag_type);

         if (tag_type == 'package') {
            break;
         }
         tag_get_detail2(VS_TAGDETAIL_context_outer, context_id, context_id);
      }

      outer_class := "";
      tag_name := "";

      if (context_id>0) {
         tag_get_detail2(VS_TAGDETAIL_context_name, context_id, outer_class);
      }
      tag_unlock_context();

      if (_chdebug) {
         say("c_expand_begin: class_name="class_name" outer_class="outer_class);
      }
      count=_do_default_get_implement_list(class_name, outer_class, implement_list, vsImplementFlags,false);

      if (count > 0) {
         if (expand && placement == AUTOBRACE_PLACE_SAMELINE) {
            // Go ahead and expand the {} so we have a place to 
            // generate code to.
            c_enter();
         }
         generate_code_for_override(outer_class, class_name);
      }

      maybe_semicolon_brace();
      restore_pos(AfterKeyinPos);
      return(0);
   }

   if (cursor_on_braced_decl()) {
       maybe_semicolon_brace();
   }
   restore_pos(AfterKeyinPos);

   // do block surround only if we are already in a function scope
   if (_in_function_scope()) {
      do_surround_mode_keys();
   } else {
      clear_surround_mode_line();
   }
   return(0);
}

static _str prev_stat_has_semi()
{
   status := 1;
   up();
   if ( ! rc ) {
      col := p_col;
      _end_line();
      _str line;
      get_line_raw(line);
      parse line with line '\#|/\*|//',(p_rawpos'r');
      /* parse line with line '{' +0 last_word ; */
      /* parse line with first_word rest ; */
      /* status=stat_has_semi() or line='}' or line='' or last_word='{' or first_word='case' */
      line=strip(line,'T');
      if (raw_last_char(line)==')') {
         save_pos(auto p);
         p_col=text_col(line);
         status=_find_matching_paren(def_pmatch_max_diff_ksize);
         if (!status) {
            status=search('[~( \t]','@-rh');
            if (!status) {
               if (!_clex_find(0,'g')==CFG_KEYWORD) {
                  status=1;
               } else {
                  junk := 0;
                  _str kwd=cur_word(junk);
                  status=(int) !pos(' 'kwd' ',' if do while switch for ');
               }
            }
         }
         restore_pos(p);
      } else {
         status=(int) (raw_last_char(line)!=')' && (int) !pos('(\}|)else$',line,1,p_rawpos'r'));
      }
      down();
      p_col=col;
   }
   return(status);
}
static _str stat_has_semi(...)
{
   _str line;
   get_line_raw(line);
   parse line with line '/*',p_rawpos;
   parse line with line '/\*|//',(p_rawpos'r');
   line=strip(line,'T');
   _str name=name_on_key(ENTER);
   return((raw_last_char(line):==';' || raw_last_char(line):=='}') &&
            (
               ! ((_will_split_insert_line()
                    ) && (p_col<=text_col(line) && arg(1)=='')
                   )
            )
         );

}

// Returns offset of end of expansion.
long _c_maybe_insert_braces(bool noSpaceBeforeParen, bool insertBraceImmediately, int width,
                                _str word,bool no_close_brace=false, bool parens=true)
{
   long rv; 

   int col=width+length(word)+3;
   updateAdaptiveFormattingSettings(AFF_PAD_PARENS | AFF_NO_SPACE_BEFORE_PAREN);
   // do this extra check because we might have forced in the no space before paren setting in c_expand_space
   bes_style := beaut_style_for_keyword(word, auto foundp);
   if ( noSpaceBeforeParen ) --col;
   if ( p_pad_parens ) ++col;
   if ( !parens ) --col;
   if ( bes_style == BES_BEGIN_END_STYLE_3 ) {
      width += p_SyntaxIndent;
   }
   rv = _QROffset();
   if ( insertBraceImmediately ) {
      up_count := 1;
      if ( bes_style == BES_BEGIN_END_STYLE_2 || bes_style == BES_BEGIN_END_STYLE_3 ) {
         up_count++;
         insert_line(indent_string(width)'{');
      }
      if ( LanguageSettings.getInsertBlankLineBetweenBeginEnd(p_LangId) ) {
         up_count++;
         if ( bes_style == BES_BEGIN_END_STYLE_3) {
            insert_line(indent_string(width));
         } else {
            insert_line(indent_string(width+p_SyntaxIndent));
         }
      }
      _end_line();
      add_hotspot();
      if (no_close_brace) {
         up_count--;
      } else {
         insert_line(indent_string(width)'}');
         set_surround_mode_end_line();
      }
      rv = _QROffset();
      up(up_count);
   }
   p_col=col;
   if ( ! _insert_state() ) _insert_toggle();
   return rv;
}

void maybe_autobracket_parens()
{
	// is auto-close enabled for parens?
	if (!se.autobracket.AutoBracketListener.isEnabledForKey('(')) {
		return;
	}

   // if cursor is inside inserted parens (|)
   offset := _QROffset();
   if (offset > 1) {
      ch := get_text(2, offset-1);
      if (ch == '()') {
         se.ui.AutoBracketMarker.createMarker(')', offset-1, 1, offset, 1);
      }
   }
}

/*
   It is no longer necessary to modify this function to
   create your own main style.  Just define an extension
   specific alias.  See comment at the top of this file.

   NOTE: This function is not called for java.
*/
static int c_insert_main()
{
 //  updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   main_style := LanguageSettings.getMainStyle(p_LangId);
   _begin_line();
   start := _QROffset();

   if ( main_style == CMS_KR/* K&R */) {
      replace_line('main(argc, argv)');
      insert_line('int argc;');
      insert_line('argv[];');
   } else {          /* ANSI / C++ */
      if (_isUnix()) {
         // GNU c++ wants int return type
         replace_line('int main(int argc, char *argv[])');
      } else {
         replace_line('void main(int argc, char* argv[])');
      }
   }

   insert_line('{');
   insert_line('');
   cpt := _QROffset();
   insert_line('}');
   endoff := _QROffset();

   if (new_beautifier_supported_language(p_LangId) && beautify_syntax_expansion(p_LangId)) {
      long markers[];

      markers[0] = cpt;
      rv := new_beautify_range(start, endoff, markers);
      if (rv == 0) {
         _GoToROffset(markers[0]);
      }
      return rv;
   } else {
      _GoToROffset(cpt);
      p_col = p_SyntaxIndent+1;
   }
   return 0;
}

_command void c_dquote() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (command_state()) {
      call_root_key('"');
      return;
   }
   if (_MultiCursorAlreadyLooping()) {
      keyin(last_event());
      return;
   }
   // Handle Assembler embedded in C
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(last_event(), "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }

   /*insertBraceOn := LanguageSettings.getInsertBeginEndImmediately(p_LangId);
   if (insertBraceOn) {
      LanguageSettings.setInsertBeginEndImmediately(p_LangId, false);
   } */

   keyin(last_event());

   // convert #include <"> to #include "" and force list members
   langId := p_LangId;
   VS_TAG_IDEXP_INFO idexp_info;
   if (!_Embeddedget_expression_info(false, langId, idexp_info)) {
      if ((idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
          (idexp_info.prefixexp == '#include' || 
           idexp_info.prefixexp == '#require' || 
           idexp_info.prefixexp == '#import')) {
         get_line(auto line);
         line = stranslate(line,"","[ \t]",'r');
         if ((get_text(2,_nrseek()-2)=="<\"" || get_text(2,_nrseek()-1)=="\"<") &&
             (_last_char(line) == '>') && 
             (!pos('<',line,11))) {
            if (get_text(2,_nrseek()-2)=="<\"") left();
            left();
            _delete_text(2);
            _insert_text('"');
            orig_col := p_col;
            p_col += length(line) - 11;
            if (idexp_info.prefixexp == "#import") right();
            _delete_text(1);
            _insert_text('"');
            p_col = orig_col;
            if (_haveContextTagging() && LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) != AC_POUND_INCLUDE_NONE) {
               if (get_text(2,_nrseek()-1) == "\"\"") {
                  _do_list_members(OperatorTyped:true, DisplayImmediate:true);
               }
            }
            return;
         }
      }
   }

   if (_haveContextTagging() && LanguageSettings.getAutoCompletePoundIncludeOption(p_LangId) == AC_POUND_INCLUDE_ON_QUOTELT) {
      get_line(auto line);
      if (pos("^[ \t]*\\#[ \t]*(include|require|import)",line,1,'r') > 0) {
         _macro_delete_line();
         _do_list_members(OperatorTyped:false, DisplayImmediate:true);
      }
   }
}

bool _c_auto_surround_char(_str key)
{
   cfg := _clex_find(0, 'g');
   // special case for surround <>
   if (cfg != CFG_STRING && cfg != CFG_COMMENT && pos(key,'<>')) {
      get_line(auto line);
      if (!pos("^[ \t]*\\#[ \t]*(include|require|import)",line,1,'r')) {
         return false;
      }
   }
   return _default_auto_surround_char(key);
}
static void _c_find_next_case_sample(bool &modified_indent_case,int beginCol,int &indent_case) {
   if (p_lexer_name=='') {
      return;
   }
   // Find switch at same brace level
   // search for begin brace,end brace, and switch not in comment or string
   idChars:=_clex_identifier_chars();
   status := search('\{|\}|case','@rh');
   level := 1;
   for (;;) {
      if (status) {
         return;
      }
      word := get_match_text();
      int color=_clex_find(0,'g');
      //messageNwait('word='word);
      if (color!=CFG_STRING && color!=CFG_COMMENT) {
         switch (word) {
         case '}':
            --level;
            if (level==0) {  // End of switch
                return;
            }
            break;
         case '{':
            ++level;
            break;
         default:
            if (color==CFG_KEYWORD && level== 1 && cur_identifier(auto start_col)=='case') {
               modified_indent_case=true;
               caseCol := p_col;
               if (caseCol>beginCol) {
                  indent_case=caseCol-beginCol;
                  //messageNwait('m_tally_Indent_Case='m_tally_Indent_Case);
               } else {
                  indent_case=0;
               }
               return;
            }
         }
      }
      status=repeat_search();
   }
}
bool def_case_indent_sampling=true;

void _c_maybe_determine_case_indent_for_this_switch_statement(bool &modified_indent_case,int &indent_case,typeless LineEndsWithBrace_pos=null, long offset_of_case_sample_to_skip=-1) {
   modified_indent_case=false;
   if (!def_case_indent_sampling) {
      return;
   }
   if (p_lexer_name=='') {
      return;
   }
   save_pos(auto p);
   _first_non_blank();
   beginCol := p_col;
   if (LineEndsWithBrace_pos==null) {
      word:=cur_identifier(auto junk);
      p_col+=length(word);
      _clex_skip_blanks();
      if (get_text():!='(') {
         restore_pos(p);
         return;
      }
      int status=find_matching_paren(true);
      if (status) {
         restore_pos(p);
         return;
      }
      right();_clex_skip_blanks('');
   } else {
      //messageNwait('beginCol='beginCol);
      restore_pos(LineEndsWithBrace_pos);
   }
   if (get_text():!='{') {
      restore_pos(p);
      return;
   }
   save_pos(LineEndsWithBrace_pos);
   right();
   _clex_skip_blanks('');
   ch := get_text();
   idChars:=_clex_identifier_chars();
   if (pos('['idChars']',ch,1,'r')) {
      caseCol := p_col;
      status:=search('['idChars']#','hr@');
      if (!status) {
         match := get_match_text('');
         if (match:=='case') {
            if (!status && _QROffset()==offset_of_case_sample_to_skip) {
               p_col+=4;
               _c_find_next_case_sample(modified_indent_case,beginCol,indent_case);
               restore_pos(p);
               return;
            }
            modified_indent_case=true;
            if (caseCol>beginCol) {
               indent_case=caseCol-beginCol;
               //messageNwait('m_tally_Indent_Case='m_tally_Indent_Case);
            } else {
               indent_case=0;
            }
         }
      }
   }
   restore_pos(p);
}


defeventtab c_keys;
def  ' '= c_space;
def  '#'= c_pound;
def  '('= c_paren;
def  '*'= c_asterisk;
def  '.'= auto_codehelp_key;
def  '/'= c_slash;
def  ':'= c_colon;
def  ';'= c_semicolon;
def  '<'= auto_functionhelp_key;
def  '='= auto_codehelp_key;
def  '"'= c_dquote;
def  '>'= auto_codehelp_key;
def  '@'= c_atsign;
def  '\'= c_backslash;
def  '%'= c_percent;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  'ENTER'= c_enter;
def  'TAB'= smarttab;

