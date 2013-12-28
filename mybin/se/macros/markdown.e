////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47780 $
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
#import "markfilt.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

using se.lang.api.LanguageSettings;

#define MARKDOWN_LANGUAGE_ID   'markdown'
#define MARKDOWN_MODE_NAME     'Markdown'
#define MARKDOWN_WORDCHARS     'A-Za-z0-9_'

// TODO OPTION: blockquote continuation on enter
// TODO OPTION: list continuation on enter
// TODO OPTION: delete empty list item on enter
// TODO OPTION: autobracket **
// TODO OPTION: autobracket __
// TODO OPTION: autobracket ``

defload()
{
   _str setup_info='MN='MARKDOWN_MODE_NAME',TABS=+4,MA=1 74 1,':+
                   'KEYTAB='MARKDOWN_LANGUAGE_ID'-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC='MARKDOWN_WORDCHARS',LN=Markdown,CF=1,';
   _str compile_info='';
   _str syntax_info='4 1 1 0 4 1 1';
   _str be_info='';
   _CreateLanguage(MARKDOWN_LANGUAGE_ID, MARKDOWN_MODE_NAME, setup_info, compile_info, syntax_info, be_info);
   _CreateExtension("md", MARKDOWN_LANGUAGE_ID);
   _CreateExtension("markdown", MARKDOWN_LANGUAGE_ID);
   _CreateExtension("mdown", MARKDOWN_LANGUAGE_ID);

   LanguageSettings.setAutoBracket(MARKDOWN_LANGUAGE_ID, AUTO_BRACKET_ENABLE|AUTO_BRACKET_PAREN|AUTO_BRACKET_BRACKET|AUTO_BRACKET_ANGLE_BRACKET);
}

_command void markdown_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(MARKDOWN_LANGUAGE_ID);
}

defeventtab markdown_keys;
def 'ENTER'=markdown_enter;
// maybe a horizontal rule <hr/> or header element <h1/>
static boolean _markdown_hr_element()
{
   get_line(auto line);
   if (pos("^[ ]{0,3}(([*]+[ \t]*){3,}|([-]+[ \t]*){3,}|([_]+[ \t]*){3,})", line, 1, 'u')) {
      return(true);

   } else if (pos("^[-]{2,}", line, 1, 'u')) {
      return(true);
   }
   return(false);
}

static int _markdown_get_blockquote(_str& blockquote)
{
   col := 0;
   get_line(auto line);
   if (pos("^([ ]{0,3}>[ ]{0,1})+", line, 1, 'u')) {
      len := pos('');
      blockquote = _expand_tabsc(1, len);
      col = len + 1;
   }
   return(col);
}

static void _markdown_skip_blockquote()
{
   get_line(auto line);
   if (pos("^([ ]{0,3}>[ ]{0,1})+[ \t]*", line, 1, 'u')) {
      p_col = pos('') + 1;
   }
}

static boolean _markdown_list_expansion(boolean line_splits)
{
   save_pos(auto p);
   search('[~ \t]|$', "@r");
   // Check at end of line
   if (line_splits && p_col <= _text_colc(0, 'E')) {
      restore_pos(p);
      return(false);
   }


   blockquote := '';
   first_non_blank();
   ch := get_text();
   if (ch == '>' && p_col < 5) {
      p_col = _markdown_get_blockquote(blockquote);
      search('[~ \t]|$', "@r"); // skip whitespace
   }

   start_col := p_col;
   ch = get_text();
   // continue bullet list?
   if (ch == '+' || ((ch == '*' || ch == '-') && !_markdown_hr_element())) {
      list_ch := ch;
      right(); ch = get_text();
      if (pos(ch, " \t")) {
         search('[~ \t]|$', "@r");
         if (p_col > _text_colc(0, 'E')) {
            // empty list item, remove
            replace_line(blockquote);
            indent_on_enter(0, start_col);
            if (blockquote != '') {
               replace_line(blockquote);
            }
            return(true);

         } else {
            col := p_col;
            line := _expand_tabsc(1, col - 1);
            restore_pos(p);
            indent_on_enter(0, col);
            replace_line(line);
            return(true);
         }
      }

   // continue numbered list?
   } else if (pos('[0-9]', ch, 1, 'r')) {
      if (!search('[~0-9]|$', "@rh")) {
         ch = get_text();
         if (ch == '.') {
            num := _expand_tabsc(start_col, p_col - start_col);
            if (isinteger(num)) {
               right();  ch = get_text();
               if (pos(ch, " \t")) {
                  search('[~ \t]|$', "@r");
                  if (p_col > _text_colc(0, 'E')) {
                     // empty list item, remove
                     replace_line(blockquote);
                     indent_on_enter(0, start_col);
                     if (blockquote != '') {
                        replace_line(blockquote);
                     }
                     return(true);

                  } else {
                     col := p_col;
                     line := _expand_tabsc(1, start_col - 1) :+ ((int)num + 1) :+ ". ";
                     if (length(line) >= col) {
                        col = length(line) + 1;
                     }
                     restore_pos(p);
                     indent_on_enter(0, col);
                     replace_line(line);
                     return(true);
                  }
               }
            }
         }
      }
   }

   if (blockquote != '') {
      restore_pos(p);
      indent_on_enter(0, start_col);
      replace_line(blockquote);
      return(true);
   }

   restore_pos(p);
   return(false);
}

static boolean _markdown_expand_enter()
{
   boolean line_splits = _will_split_insert_line();
   if (_markdown_list_expansion(line_splits)) {
      return(false);
   }
   return(true);
}

_command void markdown_enter() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY)
{
   if (ispf_common_enter()) return;
   if (command_state()) {
      call_root_key(ENTER);
      return;
   }
   if (_markdown_expand_enter()) {
       call_root_key(ENTER);
   } else if (_argument=='') {
      _undo('S');
   }
}

int markdown_smartpaste(boolean char_cbtype, int first_col, int Noflines, boolean allow_col_1=false)
{
   save_pos(auto p);
   int i;
   for (i = 1; i <= Noflines; ++i) {
      first_non_blank();
      ch := get_text();
      if (ch == '>' && p_col < 5) {
         // pasting blockquote, skip re-indent
         restore_pos(p);
         return 0;
      }
      if (down()) break;
   }
   restore_pos(p);

   _begin_select(); up(); _end_line();
   first_non_blank();
   _markdown_skip_blockquote();
   return p_col;
}

static void _markdown_addremove_blockquote(int addremove = 1)
{
   orig_line := p_line; orig_col := p_col;
   in_selection := true;
   if (!select_active2()) {
      select_line();
      in_selection = false;
   }

   type := _select_type();
   if (type == 'BLOCK') {
      return;

   } else if (type == 'CHAR') {
      _select_type('', 'L', 'LINE');
   }

   _begin_select();
   for (;;) {
      first_non_blank();
      ch := get_text();
      if (addremove > 0) {
         get_line(auto line);
         replace_line('> ':+line);

      } else {
         if (ch == '>' && p_col < 5) {
            _delete_char();
            ch = get_text();
            if (ch == ' ') {
               _delete_char();
            }
         }
      }
      if (_end_select_compare() >= 0) break;
      if (down()) break;
   }
   if (!in_selection) {
      deselect();
   }
   p_line = orig_line; p_col = orig_col;
}

_command void markdown_add_blockquote() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _markdown_addremove_blockquote();
}

_command void markdown_remove_blockquote() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _markdown_addremove_blockquote(-1);
}

static void _markdown_toggle_list(_str listmarker="-")
{
   orig_line := p_line; orig_col := p_col;
   in_selection := true;
   if (!select_active2()) {
      select_line();
      in_selection = false;
   }

   type := _select_type();
   if (type == 'BLOCK') {
      return;

   } else if (type == 'CHAR') {
      _select_type('', 'L', 'LINE');
   }
   prefix := listmarker :+ " ";
   len := length(prefix);
   firsttime := true;
   addlist := true;
   _begin_select();
   for (;;) {
      first_non_blank();
      _markdown_skip_blockquote();
      ch := get_text(2);
      if (firsttime) {
         addlist = !(ch :== prefix);
         firsttime = false;
      }

      if (addlist && (ch :!= prefix)) {
         _insert_text(prefix);

      } else if (!addlist && (ch :== prefix)) {
         _delete_text(len);
      }

      if (_end_select_compare() >= 0) break;
      if (down()) break;
   }
   if (!in_selection) {
      deselect();
   }
   p_line = orig_line; p_col = orig_col;
}

_command void markdown_toggle_list() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   _markdown_toggle_list('-');
}

