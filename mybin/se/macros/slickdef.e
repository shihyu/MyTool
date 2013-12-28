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

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= help;
def  'F2'= save;
def  'F3'= quit;
def  'F4'= file;
def  'F5'= config;
def  'F6'= compare;
def  'F7'= gui_open;
def  'F8'= next_buffer;
def  'F9'= undo;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= nosplit_insert_line;
def  'TAB'= ctab;
def  'BACKSPACE'= linewrap_rubout;
def  'DEL'= delete_char;
def  'INS'= insert_toggle;
def  'M-='= execute_selection;
def  'M-A'= adjust_block_selection;
def  'M-B'= select_block;
def  'M-C'= copy_to_cursor;
def  'M-E'= end_select;
def  'M-F'= fill_selection;
def  'M-J'= join_line;
def  'M-K'= cut;
def  'M-L'= select_line;
def  'M-M'= move_to_cursor;
def  'M-N'= keyin_buf_name;
def  'M-O'= overlay_block_selection;
def  'M-P'= reflow_paragraph;
def  'M-R'= root_keydef;
def  'M-S'= split_line;
def  'M-T'= find_matching_paren;
def  'M-U'= deselect;
def  'M-V'= copy_to_clipboard;
def  'M-W'= cut_word;
def  'M-X'= safe_exit;
def  'M-Y'= begin_select;
def  'M-Z'= select_char;
def  'M-F1'= api_index;
def  'M-F2'= move_edge;
def  'M-F3'= create_tile;
def  'M-F4'= delete_tile;
def  'M-F5'= project_build;
def  'M-F6'= project_compile;
//def  'M-F7'= move_mdi;
def  'M-F8'= prev_buffer;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= next_error;
def  'M-BACKSPACE'= undo;
def  'M-PAD-STAR'= debug_show_next_statement;
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
def  'S-F12'= save;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'C-0'-'C-9'= alt_bookmark;
def  'C-A'= cmdline_toggle;
def  'C-B'= next_buffer;
def  'C-C'= stop_process;
def  'C-D'= delete_char;
def  'C-E'= cut_end_line;
def  'C-F'= find_next;
def  'C-G'= abort;
def  'C-H'= push_tag;
def  'C-I'= cursor_up;
def  'C-J'= cursor_left;
def  'C-K'= cursor_down;
def  'C-L'= cursor_right;
def  'C-M'= project_build;
def  'C-N'= page_down;
def  'C-O'= end_line;
def  'C-P'= page_up;
def  'C-Q'= quote_key;
def  'C-R'= record_macro_toggle;
def  'C-S'= i_search;
def  'C-T'= record_macro_end_execute;
def  'C-U'= begin_line_text_toggle;
def  'C-V'= prev_buffer;
def  'C-W'= next_window;
def  'C-Y'= paste;
def  'C-Z'= zoom_window;
def  'C-['= next_hotspot;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-F1'= upcase_word;
def  'C-F2'= lowcase_word;
def  'C-F3'= upcase_selection;
def  'C-F4'= lowcase_selection;
def  'C-F5'= project_execute;
def  'C-F6'= project_compile;
def  'C-F7'= move_window;
def  'C-F8'= prev_buffer;
def  'C-F9'= undo_cursor;
def  'C-F10'= debug_run_to_cursor;
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= cut_line;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-B'= list_buffers;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= list_errors;
def  'C-S-F'= find_prev;
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
def  'C-S-S'= set_next_error;
def  'C-S-U'= upcase_selection;
def  'C-S-V'= list_clipboards;
def  'C-S-W'= prev_window;
def  'C-S-X'= append_cut;
def  'C-S-Y'= paste_replace_word;
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-F1'= cap_word;
def  'C-S-F2'= cap_selection;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A-='= execute_selection;
def  'A-A'= adjust_block_selection;
def  'A-B'= select_block;
def  'A-C'= copy_to_cursor;
def  'A-E'= end_select;
def  'A-F'= fill_selection;
def  'A-J'= join_line;
def  'A-K'= cut;
def  'A-L'= select_line;
def  'A-M'= move_to_cursor;
def  'A-N'= keyin_buf_name;
def  'A-O'= overlay_block_selection;
def  'A-P'= reflow_paragraph;
def  'A-R'= root_keydef;
def  'A-S'= split_line;
def  'A-T'= find_matching_paren;
def  'A-U'= deselect;
def  'A-V'= copy_to_clipboard;
def  'A-W'= cut_word;
def  'A-X'= safe_exit;
def  'A-Y'= begin_select;
def  'A-Z'= select_char;
def  'A-F1'= api_index;
def  'A-F2'= move_edge;
def  'A-F3'= create_tile;
def  'A-F4'= delete_tile;
def  'A-F5'= project_build;
def  'A-F6'= project_compile;
//def  'A-F7'= move_mdi;
def  'A-F8'= prev_buffer;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= next_error;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-M-M'= iconize_all;
def  'A-M-W'= close_all;
def  'C-X' '('= start_recording;
def  'C-X' ')'= end_recording;
def  'C-X' '1'= one_window;
def  'C-X' '2'= hsplit_window;
def  'C-X' 'A'-'Z'= case_indirect;
def  'C-X' 'b'= find_buffer;
def  'C-X' 'e'= last_macro;
def  'C-X' 'k'= quit;
def  'C-X' 'm'= project_build;
def  'C-X' 'n'= set_next_error;
def  'C-X' 'o'= next_window;
def  'C-X' 'r'= redo;
def  'C-X' 's'= split_line;
def  'C-X' 'TAB'= move_text_tab;
def  'C-X' 'S-TAB'= move_text_backtab;
def  'C-X' 'C-B'= list_buffers;
def  'C-X' 'C-C'= safe_exit;
def  'C-X' 'C-D'= alias_cd;
def  'C-X' 'C-E'= dos;
def  'C-X' 'C-F'= gui_open;
def  'C-X' 'C-H'= pop_bookmark;
def  'C-X' 'C-J'= bottom_of_buffer;
def  'C-X' 'C-L'= load;
def  'C-X' 'C-M'= start_process;
def  'C-X' 'C-N'= next_error;
def  'C-X' 'C-O'= insert_toggle;
def  'C-X' 'C-P'= reflow_selection;
def  'C-X' 'C-R'= reverse_i_search;
def  'C-X' 'C-S'= save;
def  'C-X' 'C-U'= top_of_buffer;
def  'C-X' 'C-W'= copy_word;
def  'C-X' 'C-X'= nothing;
def  'C-X' 'C-Y'= list_clipboards;
def  'C-X' 'C-Z'= resume;
def  'C-S-T' '0'-'9'= execute_last_macro_key;
def  'C-S-T' 'a'-'z'= execute_last_macro_key;
def  'C-S-T' 'F1'-'F12'= execute_last_macro_key;
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
   def_updown_screen_lines=true;
   _SoftWrapUpdateAll(0,1);
   def_switchbuf_cd=false;
   def_smarttab=2;   // Default extension specific setting
  _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
  def_process_tab_output=1;
  def_click_past_end=1;
  def_gui=1;
  def_keys = '';

  def_alt_menu=0;
  def_preplace=1;
  def_buflist=3;

  def_deselect_copy=1;
  def_deselect_paste=0;
  def_persistent_select='Y';
  def_advanced_select='P';
  def_select_style = 'EI';
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

  def_from_cursor = '0';
  def_word_delim = '0';
  def_restore_cursor = 0;
  def_modal_tab=0;
  if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW) {
     def_one_file='';
     _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
     _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_STRICT_HALVING);
  }
  def_leave_selected=0;
  def_word_continue=false;

  _default_option(VSOPTION_LINE_NUMBERS_LEN,1);
  _default_option(VSOPTION_LCREADWRITE,0);
  _default_option(VSOPTION_LCREADONLY,0);
  _LCUpdateOptions();
  def_ispf_flags=0;

  _default_option(VSOPTION_NEXTWINDOWSTYLE,0);

  _ModifyTabSetupAll(
     __UNIX__,  // Fundamental indent with tabs setting
     0,         // Common indent with tabs setting
     '+4'       // Common tabs setting
     );

   _scroll_style('H 2');
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
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,0);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,0);
   }
   rc=0;
}
