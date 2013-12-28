////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50157 $
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
#import "bind.e"
#import "files.e"
#import "main.e"
#import "options.e"
#import "stdcmds.e"
#import "ex.e"
#endregion

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  ')'= vi_maybe_keyin_match_paren;
def  '}'= vi_maybe_keyin_match_paren;
def  'F1'= help;
def  'F2'= save;
def  'F3'= quit;
def  'F4'= file;
def  'F5'= project_debug;
def  'F6'= compare;
def  'F7'= gui_open;
def  'F8'= select_char;
def  'F9'= debug_toggle_breakpoint;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= split_insert_line;
def  'TAB'= move_text_tab;
def  'ESC'= vi_escape;
def  'BACKSPACE'= vi_backspace;
def  'PAD-STAR'= undo;
def  'PAD-PLUS'= copy_to_clipboard;
def  'PGUP'= vi_page_up;
def  'PGDN'= vi_page_down;
def  'DEL'= delete_char;
def  'INS'= insert_toggle;
def  'M-/'= alias_cd;
def  'M-0'= alt_bookmark;
def  'M-2'-'M-9'= alt_bookmark;
def  'M-='= execute_selection;
def  'M-A'= select_all;
def  'M-C'= copy_to_clipboard;
def  'M-E'= set_find;
def  'M-F'= gui_find;
def  'M-G'= find_next;
def  'M-M'= iconize_window;
def  'M-N'= new;
def  'M-O'= gui_open;
def  'M-P'= gui_print;
def  'M-Q'= safe_exit;
def  'M-S'= save;
def  'M-T'= macos_font_config;
def  'M-V'= paste;
def  'M-W'= close_window;
def  'M-X'= cut;
def  'M-Z'= undo;
def  'M-F2'= move_edge;
def  'M-F3'= create_tile;
def  'M-F4'= safe_exit;
def  'M-F5'= restore_mdi;
//def  'M-F7'= move_mdi;
//def  'M-F8'= size_mdi;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= maximize_mdi;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= undo_cursor;
def  'S-F10'= project_compile;
def  'S-F11'= debug_step_out;
def  'S-F12'= save;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= vi_backspace;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-0'= alt_gtbookmark;
def  'S-M-2'-'S-M-9'= alt_gtbookmark;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'C-0'-'C-1'= alt_bookmark;
def  'C-2'= vi_repeat_last_insert;
def  'C-3'-'C-5'= alt_bookmark;
def  'C-6'= ex_prev_edit;
def  'C-7'-'C-9'= alt_bookmark;
def  'C-A'= cmdline_toggle;
def  'C-B'= vi_page_up;
def  'C-C'= copy_to_clipboard;
def  'C-D'= vi_pbacktab;
def  'C-E'= cut_end_line;
def  'C-F'= vi_page_down;
def  'C-G'= vi_status;
def  'C-H'= next_window;
def  'C-I'= i_search;
def  'C-J'= gui_goto_line;
def  'C-K'= copy_word;
def  'C-L'= select_line;
def  'C-M'= project_build;
def  'C-N'= vi_next_line;
def  'C-O'= gui_open;
def  'C-P'= vi_prev_line;
def  'C-Q'= abort;
def  'C-R'= gui_replace;
def  'C-S'= save;
def  'C-T'= vi_ptab;
def  'C-U'= deselect;
def  'C-V'= paste;
def  'C-W'= vi_restart_word;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= vi_escape;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-F1'= wh;
def  'C-F2'= wh2;
def  'C-F4'= close_window;
def  'C-F5'= project_execute;
def  'C-F6'= next_window;
def  'C-F7'= move_window;
def  'C-F8'= size_window;
def  'C-F9'= debug_toggle_breakpoint_enabled;
def  'C-F10'= debug_run_to_cursor;
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= cut_line;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-A'= cap_selection;
def  'C-S-B'= list_buffers;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= list_errors;
def  'C-S-F'= find_in_files;
def  'C-S-G'= find_prev;
def  'C-S-H'= hex;
def  'C-S-I'= reverse_i_search;
def  'C-S-J'= toggle_bookmark;
def  'C-S-K'= cut_word;
def  'C-S-L'= lowcase_selection;
def  'C-S-M'= start_process;
def  'C-S-N'= activate_bookmarks;
def  'C-S-O'= expand_alias;
def  'C-S-P'= expand_extension_alias;
def  'C-S-R'= replace_in_files;
def  'C-S-S'= set_next_error;
def  'C-S-U'= upcase_selection;
def  'C-S-V'= list_clipboards;
def  'C-S-W'= prev_window;
def  'C-S-X'= append_cut;
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A-/'= alias_cd;
def  'A-0'= alt_bookmark;
def  'A-2'-'A-9'= alt_bookmark;
def  'A-='= execute_selection;
def  'A-F2'= move_edge;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= restore_mdi;
//def  'A-F7'= move_mdi;
//def  'A-F8'= size_mdi;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= maximize_mdi;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-M-M'= iconize_all;
def  'A-M-W'= close_all;
def  'A-S-0'= alt_gtbookmark;
def  'A-S-2'-'A-S-9'= alt_gtbookmark;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;

defeventtab vi_visual_keys;
def  '#'= vi_quick_reverse_search;
def  '*'= vi_quick_search;
def  '='= beautify_selection;
def  '@'= vi_visual_maybe_command;
def  'q'= vi_visual_maybe_command;
def  'K'= vi_visual_maybe_command;
def  '\'= vi_visual_maybe_command;
def  '_'= vi_visual_maybe_command;
def  ''= vi_visual_maybe_command;
def  'TAB'= vi_visual_maybe_command;
def  'S-TAB'= vi_visual_maybe_command;
def  '-'= vi_visual_maybe_command;
def  '0'= vi_visual_maybe_command;
def  '^'= vi_visual_begin_line;
def  '|'= vi_visual_maybe_command;
def  '('= vi_visual_prev_sentence;
def  ')'= vi_visual_next_sentence;
def  '{'= vi_visual_prev_paragraph;
def  '}'= vi_visual_next_paragraph;
def  '['= vi_open_bracket_cmd;
def  ']'= vi_closed_bracket_cmd;
def  '%'= vi_find_matching_paren;
def  "'"= vi_visual_maybe_command;
def  '`'= vi_visual_maybe_command;
def  'C-^'= vi_visual_maybe_command;
def  'C-D'= vi_visual_maybe_command;
def  'C-U'= vi_visual_maybe_command;
def  '!'= vi_visual_maybe_command;
def  '<'= vi_visual_shift_left;
def  '>'= vi_visual_shift_right;
def  '"'= vi_cb_name;
def  ';'= vi_visual_maybe_command;
def  ','= vi_visual_maybe_command;
def  '&'= vi_visual_maybe_command;
def  '.'= vi_visual_maybe_command;
def  ':'= vi_visual_ex_mode;
def  'a'= vi_visual_a_cmd;
def  'A'= vi_visual_maybe_command;
def  'b'= vi_visual_prev_word;
def  'B'= vi_visual_prev_word2;
def  'D'= vi_visual_maybe_command;
def  'e'= vi_visual_end_word;
def  'E'= vi_visual_end_word2;
def  'f'= vi_visual_maybe_command;
def  'F'= vi_visual_maybe_command;
def  'g'= vi_maybe_text_motion;
def  'G'= vi_goto_line;
def  'H'= vi_visual_maybe_command;
def  'i'= vi_visual_i_cmd;
def  'I'= vi_visual_maybe_command;
def  'L'= vi_visual_maybe_command;
def  'm'= vi_visual_maybe_command;
def  'M'= vi_visual_maybe_command;
def  'n'= ex_repeat_search;
def  'N'= ex_reverse_repeat_search;
def  'O'= vi_visual_maybe_command;
def  'P'= vi_visual_maybe_command;
def  'Q'= vi_visual_maybe_command;
def  'R'= vi_visual_maybe_command;
def  's'= vi_visual_maybe_command;
def  'S'= vi_visual_maybe_command;
def  't'= vi_visual_maybe_command;
def  'T'= vi_visual_maybe_command;
def  'w'= vi_visual_next_word;
def  'W'= vi_visual_next_word2;
def  'X'= vi_visual_maybe_command;
def  'Y'= vi_visual_maybe_command;
def  'Z'= vi_visual_maybe_command;
def  'z'= vi_visual_maybe_command;
def  'END'= vi_visual_end_line;
def  '$'= vi_visual_end_line;
def  '1'-'9'= vi_count;
def  '/'= vi_visual_search;
def  '?'= vi_visual_reverse_search;
def  'x'= vi_visual_delete;
def  'd'= vi_visual_delete;
def  'DEL'= vi_visual_delete;
def  'r'= vi_visual_replace;
def  'c'= vi_visual_change;
def  'C'= vi_visual_change_to_end;
def  'y'= vi_visual_yank;
def  'p'= vi_visual_put;
def  'u'= vi_visual_downcase;
def  'U'= vi_visual_upcase;
def  'J'= vi_visual_join;
def  '~'= vi_visual_toggle_case;
def  'o'= vi_visual_begin_select;
def  'v'= vi_toggle_char_visual;
def  'V'= vi_toggle_line_visual;
def  'C-V'= vi_toggle_block_visual;
def  'HOME'= vi_visual_begin_line;
def  'RIGHT'= vi_visual_select_right;
def  'l'= vi_visual_select_right;
def  ' '= vi_visual_select_right;
def  'S- '= vi_visual_select_right;
def  'LEFT'= vi_visual_select_left;
def  'h'= vi_visual_select_left;
def  'BACKSPACE'= vi_visual_backspace;
def  'S-BACKSPACE'= vi_visual_backspace;
def  'UP'= vi_visual_select_up;
def  'k'= vi_visual_select_up;
def  'C-P'= vi_visual_select_up;
def  '-'= vi_visual_select_up;
def  'DOWN'= vi_visual_select_down;
def  'j'= vi_visual_select_down;
def  'ENTER'= vi_visual_select_begin_down;
def  'S-ENTER'= vi_visual_select_begin_down;
def  '+'= vi_visual_select_begin_down;
def  'C-N'= vi_visual_select_down;
def  'C-E'= vi_scroll_window_up;
def  'C-Y'= vi_scroll_window_down;
def  'C-R'= vi_visual_maybe_command;

defeventtab vi_command_keys;
def  '#'= vi_quick_reverse_search;
def  '*'= vi_quick_search;
def  '='= vi_format;
def  '@'= vi_maybe_normal_character;
def  'q'= vi_maybe_normal_character;
def  'K'= vi_maybe_normal_character;
def  'PAD-MINUS'= vi_maybe_normal_character;
def  'v'= vi_toggle_char_visual;
def  'V'= vi_toggle_line_visual;
def  'C-V'= vi_toggle_block_visual;
def  'C-W'= vi_maybe_split_cmd;
def  '\'= vi_maybe_normal_character;
def  '_'= vi_maybe_normal_character;
def  ''= vi_maybe_normal_character;
def  '~'= vi_toggle_case_char;
def  '1'-'9'= vi_count;
def  ' '= vi_cursor_right;
def  'S- ' = vi_cursor_right;
def  'TAB'= vi_tab;
def  'S-TAB'= vi_backtab;
def  'RIGHT'= vi_cursor_right;
//def  'BACKSPACE'= vi_cursor_left;
//def  'S-BACKSPACE'= vi_cursor_left;
def  'BACKSPACE'= vi_cmd_backspace;
def  'S-BACKSPACE'= vi_cmd_backspace;
def  'DEL'= vi_forward_delete_char;
def  'LEFT'= vi_cursor_left;
def  'END'= vi_end_line;
def  '+'= vi_begin_next_line;
def  'ENTER'= vi_begin_next_line;
def  'S-ENTER'= vi_begin_next_line;
def  'C-E'= vi_scroll_window_up;
def  'C-N'= vi_next_line;
def  'C-Y'= vi_scroll_window_down;
def  'DOWN'= vi_next_line;
def  'C-P'= vi_prev_line;
def  'UP'= vi_prev_line;
def  '-'= vi_begin_prev_line;
def  '0'= vi_begin_line;
def  '^'= vi_begin_text;
def  '$'= vi_end_line;
def  '|'= vi_goto_col;
def  '('= vi_prev_sentence;
def  ')'= vi_next_sentence;
def  '{'= vi_prev_paragraph;
def  '}'= vi_next_paragraph;
//def  '['= vi_prev_section;
def  '['= vi_open_bracket_cmd;
//def  ']'= vi_next_section;
def  ']'= vi_closed_bracket_cmd;
def  '%'= vi_find_matching_paren;
def  "'"= vi_to_mark_line;
def  '`'= vi_to_mark_col;
def  'C-^'= ex_prev_edit;
def  'C-D'= vi_scroll_down;
def  'C-U'= vi_scroll_up;
def  '!'= vi_filter;
def  '<'= vi_shift_text_left;
def  '>'= vi_shift_text_right;
def  '"'= vi_cb_name;
def  ';'= vi_repeat_char_search;
def  ','= vi_reverse_repeat_char_search;
def  '&'= ex_repeat_last_substitute;
def  '.'= vi_repeat_last_insert_or_delete;
def  ':'= ex_mode;
def  '/'= ex_search_mode;
def  '?'= ex_reverse_search_mode;
def  'a'= vi_append_mode;
def  'A'= vi_end_line_append_mode;
def  'b'= vi_prev_word;
def  'B'= vi_prev_word2;
def  'c'= vi_change_line_or_to_cursor;
def  'C'= vi_change_to_end;
def  'd'= vi_delete;
def  'D'= vi_delete_to_end;
def  'e'= vi_end_word;
def  'E'= vi_end_word2;
def  'f'= vi_char_search_forward;
def  'F'= vi_char_search_backward;
def  'g'= vi_maybe_text_motion;
def  'G'= vi_goto_line;
def  'h'= vi_cursor_left;
def  'H'= vi_top_of_window;
def  'i'= vi_insert_mode;
def  'I'= vi_begin_line_insert_mode;
def  'j'= vi_next_line;
def  'J'= vi_join_line;
def  'k'= vi_prev_line;
def  'l'= vi_cursor_right;
def  'L'= vi_bottom_of_window;
def  'm'= vi_set_mark;
def  'M'= vi_middle_of_window;
def  'n'= ex_repeat_search;
def  'N'= ex_reverse_repeat_search;
def  'o'= vi_newline_mode;
def  'O'= vi_above_newline_mode;
def  'p'= vi_put_after_cursor;
def  'P'= vi_put_before_cursor;
def  'Q'= ex_ex_mode;
def  'r'= vi_replace_char;
def  'R'= vi_replace_line;
def  's'= vi_substitute_char;
def  'S'= vi_substitute_line;
def  't'= vi_char_search_forward2;
def  'T'= vi_char_search_backward2;
def  'u'= vi_undo;
def  'U'= vi_undo_cursor;
def  'w'= vi_next_word;
def  'W'= vi_next_word2;
def  'x'= vi_forward_delete_char;
def  'X'= vi_backward_delete_char;
def  'y'= vi_yank_to_cursor;
def  'Y'= vi_yank_line;
def  'z'= vi_zero_line;
def  'Z'= ex_zz;
//def  FKEYTEXT = nls("F1=Help F2=Save F3=Quit F4=File F5=Confg F6=CMP F7=Edit F8=Next F9=Undo F10=Menu")


//typeless def_gui;
//typeless def_keys;

//typeless def_alt_menu;
//typeless def_preplace;
//typeless def_buflist;

//typeless def_deselect_copy;
//typeless def_deselect_paste;
//typeless def_persistent_select;
//typeless def_advanced_select;
//typeless def_select_style;

//typeless def_updown_col;
//typeless def_hack_tabs;
//typeless def_line_insert;

//typeless def_next_word_style;
//typeless def_top_bottom_style;
//typeless def_linewrap;
//typeless def_cursorwrap;
//typeless def_jmp_on_tab;
//typeless def_pull;

//typeless def_from_cursor;
//typeless def_word_delim;
//typeless def_restore_cursor;
//typeless def_modal_tab;
//typeless def_one_file;
//typeless def_leave_selected;

typeless def_vi_insertion_pos;
typeless def_vi_mode;
typeless def_vi_chars;
typeless def_vi_chars2;
typeless def_vi_show_msg;
//typeless def_show_cb_name;
//typeless def_clipboards;
typeless def_vi_left_on_escape;
//boolean def_word_continue;
boolean def_vi_always_highlight_all;

defmain()
{
   def_updown_screen_lines=false;
   _SoftWrapUpdateAll(1,1);
   def_switchbuf_cd=false;
   def_smarttab=2;   // Default extension specific setting
   _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
   def_process_tab_output=1;
   def_click_past_end=0;
   def_gui=1;
   def_keys = 'vi-keys';

   def_alt_menu=!__MACOSX__;
   def_preplace=1;
   def_buflist=3;

   def_deselect_copy=1;
   def_deselect_paste=1;

   def_persistent_select='D';
   def_advanced_select='P';
   def_select_style = 'CN';
   def_scursor_style=0;

   def_updown_col=0;
   def_hack_tabs=0;
   def_line_insert = 'A';

   def_next_word_style = 'E';
   def_top_bottom_style = '0';
   def_linewrap = '0';
   def_join_strips_spaces = true;
   def_cursorwrap= '0';
   def_jmp_on_tab = '1';
   def_pull = '1';

   // Operate on current word starting from cursor.
   def_from_cursor = '0';
   def_word_delim = '0';
   def_restore_cursor = 0;
   def_modal_tab= 1;
   def_one_file='+w';
   _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
   _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);
   def_leave_selected=0;
   def_word_continue=false;

   def_clipboards=46;
   def_vi_insertion_pos='';
   def_vi_mode='C';
   def_vi_chars = 'A-Za-z0-9_';
   def_vi_chars2 = '\!\@\#\$\%\^\&\*\(\)\-\+\|\=\\\{\}\[\]\"\39\`\:\;\~\?\/\,\.\>\<';
   def_vi_show_msg = "1";
   def_show_cb_name= "1";
   def_vi_left_on_escape= "1";
   def_vi_always_highlight_all = true;

   _default_option(VSOPTION_LINE_NUMBERS_LEN,1);
   _default_option(VSOPTION_LCREADWRITE,0);
   _default_option(VSOPTION_LCREADONLY,0);
   _LCUpdateOptions();
   def_ispf_flags=0;

   _default_option(VSOPTION_NEXTWINDOWSTYLE,1);

   _ModifyTabSetupAll(
                     1,         // Fundamental indent with tabs setting
                     1,         // Common indent with tabs setting
                     (__UNIX__)?'+8':'+4'  // Common tabs setting
                     );

   _scroll_style('H 2');
   _search_case('I');

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   _update_sysmenu_bindings();
   menu_mdi_bind_all();

   _default_option('n',"~");
   _default_option(VSOPTION_LCNOCOLON,0);
   def_brief_word=0;
   def_vcpp_word=0;
   def_subword_nav=0;
   def_vcpp_bookmark=0;

   //Need to keep search case options in sync
   _default_option('s',WRAP_SEARCH);__ex_set_ignorecase(0);
   _default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS,1);
   _default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR,VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR);
   if (machine()=='MACOSX') {
      _default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY,1);
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,1);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,1);
   }

   rc=0;
}
