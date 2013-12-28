////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50185 $
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
#endregion

/*
  cmdline commands          gui commands
--------------------------------------------
  reverse_regex_search      gui_find_backward_regex
  regex_search              gui_find_regex
  query_replace             gui_replace
  replace_string            gui_replace_go
  regex_replace             gui_replace_regex

  prompt_load               gui_load
  prompt_cd                 gui_cd
  set_var                   gui_set_var

  visit_file                gui_visit_file
  goto_tag                  gui_push_tag
  prompt_dir                fileman
  goto_line                 gui_goto_line
  get                       gui_insert_file
  put                       gui_write_selection
  edit                      gui_open
  bind_to_key               gui_keybindings
  save_macro                gui_save_macro
*/

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= help;
def  'F2'= cmdline_toggle;
def  'F3'= gui_load;
def  'F4'= bind_to_key;
def  'F5'= project_debug;
def  'F6'= what_is;
def  'F7'= prompt_cd;
def  'F8'= set_var;
def  'F9'= debug_toggle_breakpoint;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= split_insert_line;
def  'TAB'= move_text_tab;
def  'ESC'= esc_alt_prefix;
def  'BACKSPACE'= linewrap_rubout;
def  'HOME'= top_of_buffer;
def  'END'= bottom_of_buffer;
def  'CLEAR'= center_line;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
def  'M--'= alt_argument;
def  'M-/'= complete_prev;
def  'M-1'-'M-0'= ;
def  'M-='= count_lines_region;
def  'M-A'= prev_sentence;
def  'M-B'= prev_word;
def  'M-C'= cap_word;
def  'M-D'= cut_word;
def  'M-E'= next_sentence;
def  'M-F'= next_word;
def  'M-G'= gui_goto_line;
def  'M-H'= select_paragraph;
def  'M-I'= move_text_tab;
def  'M-J'= split_insert_line;
def  'M-K'= cut_sentence;
def  'M-L'= lowcase_selection;
def  'M-M'= first_non_blank;
def  'M-N'= keyin_buf_name;
def  'M-O'= overlay_block_selection;
def  'M-P'= config;
def  'M-Q'= reflow_paragraph;
def  'M-R'= move_window_line;
def  'M-S'= center_paragraph;
def  'M-T'= transpose_words;
def  'M-U'= upcase_word;
def  'M-V'= emacs_scroll_down;
def  'M-W'= copy_region;
def  'M-X'= cmdline_toggle;
def  'M-Y'= list_clipboards;
def  'M-Z'= zap_to_char;
def  'M-\'= gnu_delete_space;
def  'M-^'= join_line;
def  'M-F1'= api_index;
def  'M-F2'= move_edge;
def  'M-F3'= create_tile;
def  'M-F4'= safe_exit;
def  'M-F5'= project_build;
def  'M-F6'= project_compile;
//def  'M-F7'= move_mdi;
def  'M-F8'= prev_buffer;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= next_error;
def  'M-F11'= deselect;
def  'M-F12'= quit;
def  'M-BACKSPACE'= cut_prev_word;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'M-PAD-MINUS'= alt_argument;
def  'M-HOME'= home_next_window;
def  'M-END'= end_next_window;
def  'M-LEFT'= prev_word;
def  'M-RIGHT'= next_word;
def  'M-UP'= prev_paragraph;
def  'M-DOWN'= next_paragraph;
def  'M-PGUP'= page_up_next_window;
def  'M-PGDN'= page_down_next_window;
def  'M-DEL'= delete_prev_word;
def  'S- '= keyin_space;
def  'S-F1'= scroll_up;
def  'S-F2'= scroll_down;
def  'S-F3'= scroll_left;
def  'S-F4'= scroll_right;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= redo;
def  'S-F10'= project_compile;
def  'S-F11'= debug_step_out;
def  'S-F12'= save_all;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-,'= top_of_buffer;
def  'S-M-.'= bottom_of_buffer;
def  'S-M-/'= help;
def  'S-M-0'= find_delimiter;
def  'S-M-1'= shell_command;
def  'S-M-2'= select_next_word;
def  'S-M-4'= spell_check_word;
def  'S-M-5'= query_replace;
def  'S-M-6'= join_line;
def  'S-M-7'= replace_string;
def  'S-M-8'= regex_replace;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'S-M-['= prev_paragraph;
def  'S-M-\'= gnu_filter;
def  'S-M-]'= next_paragraph;
def  'S-M-`'= modify_toggle;
def  'C--'= undo_cursor;
def  'C-/'= undo;
def  'C-0'-'C-9'= gnu_ctrl_argument;
def  'C-A'= begin_line;
def  'C-B'= cursor_left;
def  'C-D'= linewrap_delete_char;
def  'C-E'= end_line;
def  'C-F'= cursor_right;
def  'C-G'= abort;
def  'C-H'= gnu_help;
def  'C-I'= indent_previous;
def  'C-J'= split_insert_line;
def  'C-K'= cut_end_line;
def  'C-L'= center_line;
def  'C-M'= wh;
def  'C-N'= cursor_down;
def  'C-O'= split_line;
def  'C-P'= cursor_up;
def  'C-Q'= quote_key;
def  'C-R'= reverse_i_search;
def  'C-S'= i_search;
def  'C-T'= transpose_chars;
def  'C-U'= argument;
def  'C-V'= emacs_scroll_up;
def  'C-W'= cut_region;
def  'C-Y'= emacs_paste;
def  'C-Z'= minmdi;
def  'C-['= esc_alt_prefix;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-^'= ctrl_prefix;
def  'C-`'= edit_associated_file;
def  'C-F1'= upcase_selection;
def  'C-F2'= toggle_bookmark;
def  'C-F3'= save_config;
def  'C-F4'= lowcase_selection;
def  'C-F5'= project_execute;
def  'C-F6'= project_compile;
def  'C-F7'= gui_copy_to_file;
def  'C-F8'= set_var;
def  'C-F9'= debug_toggle_breakpoint_enabled;
def  'C-F10'= debug_run_to_cursor;
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= cut_prev_word;
def  'C-UP'= prev_sentence;
def  'C-DOWN'= next_sentence;
def  'C-PGUP'= expand_window;
def  'C-PGDN'= shrink_window;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-M-A'= activate_autos;
def  'C-M-B'= prev_level;
def  'C-M-C'= activate_call_stack;
def  'C-M-F'= next_level;
def  'C-M-H'= cut_prev_word;
def  'C-M-K'= cut_level;
def  'C-M-L'= activate_locals;
def  'C-M-M'= activate_members;
def  'C-M-R'= reverse_regex_search;
def  'C-M-S'= regex_search;
def  'C-M-V'= activate_variables;
def  'C-M-W'= append_next_cut;
def  'C-M-\'= indent_region;
def  'C-M-^'= ctrl_prefix;
def  'C-S-,'= mark_beginning_of_buffer;
def  'C-S-.'= mark_end_of_buffer;
def  'C-S-0'-'C-S-1'= alt_gtbookmark;
def  'C-S-2'= emacs_select_char;
def  'C-S-3'-'C-S-9'= alt_gtbookmark;
def  'C-S-B'= list_buffers;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= list_errors;
def  'C-S-F'= find_in_files;
def  'C-S-G'= find_prev;
def  'C-S-H'= hex;
def  'C-S-I'= reverse_i_search;
def  'C-S-J'= goto_bookmark;
def  'C-S-K'= cut_word;
def  'C-S-L'= lowcase_selection;
def  'C-S-M'= start_process;
def  'C-S-N'= activate_bookmarks;
def  'C-S-O'= expand_alias;
def  'C-S-P'= expand_extension_alias;
def  'C-S-S'= set_next_error;
def  'C-S-U'= upcase_selection;
def  'C-S-V'= list_clipboards;
def  'C-S-W'= prev_window;
def  'C-S-X'= append_cut;
def  'C-S-Y'= paste_replace_word;
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-\'= gnu_filter;
def  'C-S-F1'= cap_selection;
def  'C-S-F2'= activate_bookmarks;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F8'= next_buffer;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A--'= alt_argument;
def  'A-/'= complete_prev;
def  'A-0'-'A-9'= gnu_alt_argument;
def  'A-='= count_lines_region;
def  'A-A'= prev_sentence;
def  'A-B'= prev_word;
def  'A-C'= cap_word;
def  'A-D'= cut_word;
def  'A-E'= next_sentence;
def  'A-F'= next_word;
def  'A-G'= gui_goto_line;
def  'A-H'= select_paragraph;
def  'A-I'= move_text_tab;
def  'A-J'= split_insert_line;
def  'A-K'= cut_sentence;
def  'A-L'= lowcase_selection;
def  'A-M'= first_non_blank;
def  'A-N'= keyin_buf_name;
def  'A-O'= overlay_block_selection;
def  'A-P'= config;
def  'A-Q'= reflow_paragraph;
def  'A-R'= move_window_line;
def  'A-S'= center_paragraph;
def  'A-T'= transpose_words;
def  'A-U'= upcase_word;
def  'A-V'= emacs_scroll_down;
def  'A-W'= copy_region;
def  'A-X'= cmdline_toggle;
def  'A-Y'= list_clipboards;
def  'A-Z'= zap_to_char;
def  'A-\'= gnu_delete_space;
def  'A-^'= join_line;
def  'A-F1'= api_index;
def  'A-F2'= move_edge;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= project_build;
def  'A-F6'= project_compile;
//def  'A-F7'= move_mdi;
def  'A-F8'= prev_buffer;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= next_error;
def  'A-F11'= deselect;
def  'A-F12'= quit;
def  'A-BACKSPACE'= cut_prev_word;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-PAD-MINUS'= alt_argument;
def  'A-HOME'= home_next_window;
def  'A-END'= end_next_window;
def  'A-UP'= prev_paragraph;
def  'A-DOWN'= next_paragraph;
def  'A-PGUP'= page_up_next_window;
def  'A-PGDN'= page_down_next_window;
def  'A-DEL'= delete_prev_word;
def  'A-M-M'= iconize_all;
def  'A-M-W'= close_all;
def  'A-S-,'= top_of_buffer;
def  'A-S-.'= bottom_of_buffer;
def  'A-S-/'= help;
def  'A-S-0'= find_delimiter;
def  'A-S-1'= shell_command;
def  'A-S-2'= select_next_word;
def  'A-S-4'= spell_check_word;
def  'A-S-5'= query_replace;
def  'A-S-6'= join_line;
def  'A-S-7'= replace_string;
def  'A-S-8'= regex_replace;
def  'A-S-['= prev_paragraph;
def  'A-S-\'= gnu_filter;
def  'A-S-]'= next_paragraph;
def  'A-S-`'= modify_toggle;
def  'C-A-A'= ;
def  'C-A-B'= prev_level;
def  'C-A-C'= activate_call_stack;
def  'C-A-F'= next_level;
def  'C-A-H'= cut_prev_word;
def  'C-A-K'= cut_level;
def  'C-A-L'= activate_locals;
def  'C-A-M'= activate_members;
def  'C-A-R'= reverse_regex_search;
def  'C-A-S'= regex_search;
def  'C-A-V'= activate_variables;
def  'C-A-W'= append_next_cut;
def  'C-A-\'= indent_region;
def  'C-A-^'= ctrl_prefix;
def  'C-LBUTTON-DOWN'= mou_gnu_track_insert;
def  'C-C' 'C'= case_indirect;
def  'C-C' 'c'= stop_process;
def  'C-C' '{'= shrink_window_vertically;
def  'C-C' '}'= enlarge_window_vertically;
def  'C-X' "'"= next_error;
def  'C-X' '('= record_macro_toggle;
def  'C-X' ')'= end_recording;
def  'C-X' '+'= balance_windows;
def  'C-X' ','= push_tag;
def  'C-X' '-'= shrink_window_if_larger_than_buffer;
def  'C-X' '.'= gnu_goto_tag;
def  'C-X' '/'= alias_cd;
def  'C-X' '0'= kill_window;
def  'C-X' '1'= one_window;
def  'C-X' '2'= hsplit_window;
def  'C-X' '3'= vsplit_window;
def  'C-X' '5'= vsplit_window;
def  'C-X' '<'= scroll_left;
def  'C-X' '='= what_cursor_position;
def  'C-X' '>'= scroll_right;
def  'C-X' 'A'-'Z'= case_indirect;
def  'C-X' 'b'= select_buffer;
def  'C-X' 'c'= compare;
def  'C-X' 'd'= prompt_dir;
def  'C-X' 'e'= last_macro;
def  'C-X' 'f'= margins;
def  'C-X' 'g'= goto_line;
def  'C-X' 'h'= mark_whole_buffer;
def  'C-X' 'i'= get;
def  'C-X' 'k'= emacs_quit;
def  'C-X' 'l'= count_lines;
def  'C-X' 'm'= project_build;
def  'C-X' 'n'-'o'= next_window;
def  'C-X' 'p'= prev_window;
def  'C-X' 's'= list_modified;
def  'C-X' 'u'= undo;
def  'C-X' 'w'= put;
def  'C-X' 'ENTER'= start_process;
def  'C-X' 'TAB'= indent_rigidly;
def  'C-X' 'M-,'= select_tag_file;
def  'C-X' 'M-.'= gui_make_tags;
def  'C-X' 'M-.'= gui_make_tags;
def  'C-X' 'M-B'= list_buffers;
def  'C-X' 'M-I'= untabify_region;
def  'C-X' 'M-N'= save_macro;
def  'C-X' 'M-ESC'= last_command;
def  'C-X' 'S-TAB'= move_text_backtab;
def  'C-X' 'C-A'= copy_word;
def  'C-X' 'C-B'= list_buffers;
def  'C-X' 'C-C'= safe_exit;
def  'C-X' 'C-D'= prompt_dir;
def  'C-X' 'C-E'= dos;
def  'C-X' 'C-F'= edit;
def  'C-X' 'C-H'= pop_bookmark;
def  'C-X' 'C-I'= indent_rigidly;
def  'C-X' 'C-J'= dir;
def  'C-X' 'C-L'= lowcase_selection;
def  'C-X' 'C-M'= start_process;
def  'C-X' 'C-N'= next_error;
def  'C-X' 'C-O'= delete_blank_lines;
def  'C-X' 'C-P'= mark_whole_buffer;
def  'C-X' 'C-R'= find_file_read_only;
def  'C-X' 'C-S'= save;
def  'C-X' 'C-T'= transpose_lines;
def  'C-X' 'C-U'= upcase_selection;
def  'C-X' 'C-V'= visit_file;
def  'C-X' 'C-W'= save_as;
def  'C-X' 'C-X'= exchange_point_and_mark;
def  'C-X' 'C-Y'= list_clipboards;
def  'C-X' 'C-Z'= minmdi;
def  'C-X' 'C-['= page_up;
def  'C-X' 'C-]'= page_down;
def  'C-X' 'C-^'= ctrl_prefix;
def  'C-X' 'C-M-I'= tabify_region;
def  'C-X' 'C-M-['= last_command;
def  'C-X' 'C-M-^'= ctrl_prefix;
def  'C-X' 'A-,'= select_tag_file;
def  'C-X' 'A-.'= gui_make_tags;
def  'C-X' 'A-B'= list_buffers;
def  'C-X' 'A-I'= untabify_region;
def  'C-X' 'A-N'= save_macro;
def  'C-X' 'A-ESC'= last_command;
def  'C-X' 'C-A-I'= tabify_region;
def  'C-X' 'C-A-['= last_command;
def  'C-X' 'C-A-^'= ctrl_prefix;
def  'C-X' '4' '.'= find_other_tag;
def  'C-X' '4' 'b'= switch_other_buffer;
def  'C-X' '4' 'd'= prompt_other_dir;
def  'C-X' '4' 'f'= edit_other_window;
def  'C-X' '4' 'r'= find_file_other_read_only;
def  'C-X' '4' 'ENTER'= dir_other_window;
def  'C-X' '4' 'C-F'= edit_other_window;
def  'C-X' '4' 'C-J'= dir_other_window;
def  'C-X' '6' '2'= vsplit_window;
def  'C-X' 'r' 'd'= delete_selection;
def  'C-X' 'r' 'k'= gnu_kill_rectangle;
def  'C-X' 'r' 'l'= activate_bookmarks;
def  'C-X' 'r' 'o'= gnu_indent_selection;
def  'C-X' 'r' 'y'= gnu_yank_rectangle;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;

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

  // Operate on current word starting from cursor.
  //typeless def_from_cursor;
  //typeless def_word_delim;
  //typeless def_restore_cursor;
  //typeless def_modal_tab;
  //typeless def_one_file;
  //typeless def_leave_selected;
  //typeless def_click_past_end;
  //boolean def_word_continue;

defmain()
{
   def_updown_screen_lines=false;
   _SoftWrapUpdateAll(1,1);
   _default_option('S',IGNORECASE_SEARCH);
   def_switchbuf_cd=true;
   def_smarttab=3;   // Default extension specific setting
  _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
  def_process_tab_output=0;
  def_click_past_end=0;
  def_gui=0;
  def_keys = 'gnuemacs-keys';

  def_alt_menu=0;
  def_preplace=0;
  def_buflist=3;

  def_deselect_copy=1;
  def_deselect_paste=1;
  def_persistent_select='N';
  def_advanced_select='P';
  def_select_style = 'CN';
  def_scursor_style=0;

  def_updown_col=1;
  def_hack_tabs=1;
  def_line_insert = 'A';

  def_next_word_style = 'E';
  def_top_bottom_style = '0';
  def_linewrap = '0';
  def_join_strips_spaces = true;
  def_cursorwrap= '1';
  def_jmp_on_tab = '1';
  def_pull = '0';

  // Operate on current word starting from cursor.
  def_from_cursor = '1';
  def_word_delim = '0';
  def_restore_cursor = '1';
  def_modal_tab = 0;
  if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW) {
     def_one_file='';
     _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
     _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_STRICT_HALVING);
  }
  def_leave_selected=0;
  def_word_continue=true;

  _default_option(VSOPTION_LINE_NUMBERS_LEN,1);
  _default_option(VSOPTION_LCREADWRITE,0);
  _default_option(VSOPTION_LCREADONLY,0);
  _LCUpdateOptions();
  def_ispf_flags=0;

  _default_option(VSOPTION_NEXTWINDOWSTYLE,0);

  _ModifyTabSetupAll(
     1,         // Fundamental indent with tabs setting
     1,         // Common indent with tabs setting
     (__UNIX__)?'+8':'+4'  // Common tabs setting
     );

   _scroll_style('H 1');
   _search_case('I');

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   _update_sysmenu_bindings();
   menu_mdi_bind_all();

   _default_option('n','');
   _default_option(VSOPTION_LCNOCOLON,0);
   def_brief_word=0;
   def_vcpp_word=0;
   def_subword_nav=0;
   def_vcpp_bookmark=0;
   // Completion e and edit lists binary files
   def_list_binary_files=true;
   _default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS,1);
   _default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR,VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR);
   if (machine()=='MACOSX') {
      _default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY,1);
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,1);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,1);
   }
   rc=0;
}
