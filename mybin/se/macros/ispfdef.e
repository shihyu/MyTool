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
def  'F2'= gui_open;
def  'F3'= ispf_end;
def  'F4'= ispf_end;
def  'F5'= ispf_rfind;
def  'F6'= ispf_rchange;
def  'F7'= ispf_up;
def  'F8'= ispf_down;
def  'F9'= ispf_swap;
def  'F10'= page_left;
def  'F11'= page_right;
def  'F12'= ispf_retrieve;
def  'ENTER'= ispf_enter;
def  'TAB'= ctab;
def  'BACKSPACE'= linewrap_rubout;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
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
def  'M-F1'= api_index;
def  'M-F2'= move_edge;
def  'M-F3'= create_tile;
def  'M-F4'= safe_exit;
def  'M-F5'= restore_mdi;
//def  'M-F7'= move_mdi;
//def  'M-F8'= size_mdi;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= maximize_mdi;
def  'M-BACKSPACE'= undo;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'S-F1'= cut;
def  'S-F2'= copy_to_clipboard;
def  'S-F3'= paste;
def  'S-F4'= delete_selection;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= prev_doc;
def  'S-F10'= project_compile;
def  'S-F11'= javadoc_editor;
def  'S-F12'= ispf_retrieve_back;
def  'S-ENTER'= ispf_split_insert_line;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'C-0'-'C-9'= alt_bookmark;
def  'C-A'= select_all;
def  'C-B'= select_block;
def  'C-C'= copy_to_clipboard;
def  'C-D'= gui_cd;
def  'C-E'= cut_end_line;
def  'C-F'= gui_find;
def  'C-G'= find_next;
def  'C-H'= hsplit_window;
def  'C-I'= i_search;
def  'C-J'= gui_goto_line;
def  'C-K'= copy_word;
def  'C-L'= select_line;
def  'C-M'= project_build;
def  'C-N'= next_buffer;
def  'C-O'= gui_open;
def  'C-P'= prev_buffer;
def  'C-Q'= quote_key;
def  'C-R'= gui_replace;
def  'C-S'= save;
def  'C-U'= deselect;
def  'C-V'= paste;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= next_hotspot;
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
def  'C-ENTER'= ispf_do_lc;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= cut_line;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-B'= list_buffers;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= list_errors;
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
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A-='= execute_selection;
def  'A-F1'= api_index;
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
  def_updown_screen_lines=true;
   _SoftWrapUpdateAll(0,1);
  def_switchbuf_cd=false;
  def_smarttab=2;   // Default extension specific setting
  _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
  def_process_tab_output=1;
  def_click_past_end=1;
  def_gui=1;
  def_keys = 'ispf-keys';

  def_alt_menu=1;
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
  def_top_bottom_style = '1';
  def_linewrap = '0';
  def_join_strips_spaces = true;
  def_cursorwrap= '0';
  def_jmp_on_tab = '1';
  def_pull = '1';

  // Operate on current word starting from cursor.
  def_from_cursor = '0';
  def_word_delim = '0';
  def_restore_cursor = 1;
  def_modal_tab = 1;
  if (__OS390__ || __TESTS390__) {
     def_one_file='';
     _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
     _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_STRICT_HALVING);
  } else {
     def_one_file='+w';
     _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
     _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);
  }
  def_leave_selected=1;
  def_word_continue=false;

  _default_option(VSOPTION_LINE_NUMBERS_LEN,6);
  _default_option(VSOPTION_LCREADWRITE,6);
  _default_option(VSOPTION_LCREADONLY,1);
  _LCUpdateOptions();
  def_ispf_flags=0;

  //_default_option(VSOPTION_LCREADONLY,0);
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
   _default_option(VSOPTION_LCNOCOLON,1);
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
