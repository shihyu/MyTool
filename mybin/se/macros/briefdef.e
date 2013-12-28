////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50186 $
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
  edit                      gui_open
  goto_line                 gui_goto_line
  get                       gui_insert_file
  search_forward            gui_find
  search_backward           gui_find_backward
  translate_forward         gui_replace
  translate_backward        gui_replace_backward
  prompt_load               gui_load
  unload                    gui_unload

*/
defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= change_window;
def  'F2'= move_edge;
def  'F3'= create_tile;
def  'F4'= delete_tile;
def  'F5'= gui_find;
def  'F6'= gui_replace;
def  'F7'= record_macro_toggle;
def  'F8'= last_macro;
def  'F9'= gui_load;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= maybe_split_insert_line;
def  'TAB'= brief_tab;
def  'BACKSPACE'= rubout;
def  'PAD-STAR'= undo;
def  'PAD-PLUS'= copy_to_clipboard;
def  'PAD-MINUS'= cut;
def  'HOME'= brief_home;
def  'END'= brief_end;
def  'DEL'= brief_delete;
def  'INS'= brief_paste;
def  'M--'= prev_buffer;
def  'M-/'= alias_cd;
def  'M-0'-'M-9'= alt_bookmark;
def  'M-='= execute_selection;
def  'M-A'= brief_select_char;
def  'M-B'= list_buffers;
def  'M-C'= brief_select_block;
def  'M-D'= delete_line;
def  'M-E'= edit;
def  'M-F'= fill_selection;
def  'M-G'= goto_line;
def  'M-H'= help;
def  'M-I'= insert_toggle;
def  'M-J'= brief_goto_bookmark;
def  'M-K'= delete_end_line;
def  'M-L'= brief_select_line;
def  'M-M'= brief_iselect_char;
def  'M-N'= next_buffer;
def  'M-O'= name;
def  'M-P'= print_selection;
def  'M-Q'= quote_key;
def  'M-R'= get;
def  'M-S'= search_forward;
def  'M-T'= translate_forward;
def  'M-U'= undo;
def  'M-V'= version;
def  'M-W'= brief_save;
def  'M-X'= safe_exit;
def  'M-Y'= begin_select;
def  'M-Z'= dos;
def  'M-F1'= api_index;
def  'M-F2'= zoom_window;
def  'M-F3'= create_tile;
def  'M-F4'= safe_exit;
def  'M-F5'= search_backward;
def  'M-F6'= translate_backward;
def  'M-F7'= list_macros;
def  'M-F8'= save_macro;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= project_compile;
def  'M-BACKSPACE'= delete_word;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'M-HOME'= left_side_of_window;
def  'M-END'= right_side_of_window;
def  'M-LEFT'= window_left;
def  'M-RIGHT'= window_right;
def  'M-UP'= window_above;
def  'M-DOWN'= window_below;
def  'S-F1'= scroll_up;
def  'S-F2'= scroll_down;
def  'S-F3'= scroll_left;
def  'S-F4'= scroll_right;
def  'S-F5'= search_again;
def  'S-F6'= translate_again;
def  'S-F7'= pause_recording;
def  'S-F8'= shift_selection_right;
def  'S-F9'= gui_unload;
def  'S-F10'= resync;
def  'S-F11'= debug_step_out;
def  'S-F12'= save;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-HOME'= left_side_of_window;
def  'S-END'= right_side_of_window;
def  'S-LEFT'= window_left;
def  'S-RIGHT'= window_right;
def  'S-UP'= window_above;
def  'S-DOWN'= window_below;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-0'-'S-M-9'= alt_gtbookmark;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-J'= activate_bookmarks;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'C--'= quit;
def  'C-0'-'C-9'= alt_bookmark;
def  'C-A'= keyin_buf_name;
def  'C-B'= line_to_bottom;
def  'C-C'= center_line;
def  'C-D'= scroll_down;
def  'C-E'= copy_word;
def  'C-F'= config;
def  'C-G'= list_tags;
def  'C-H'= push_tag;
def  'C-I'= start_process;
def  'C-J'= hsplit_window;
def  'C-K'= delete_word;
def  'C-L'= list_clipboards;
def  'C-M'= project_build;
def  'C-N'= next_error;
def  'C-O'= stop_process;
def  'C-P'= list_errors;
def  'C-Q'= root_keydef;
def  'C-R'= argument;
def  'C-S'= i_search;
def  'C-T'= line_to_top;
def  'C-U'= redo;
def  'C-V'= paste;
def  'C-W'= next_window;
def  'C-X'= save_exit;
def  'C-Y'= brief_paste;
def  'C-Z'= zoom_window;
def  'C-['= keyin_brace;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-F1'= upcase_word;
def  'C-F2'= lowcase_word;
def  'C-F3'= upcase_selection;
def  'C-F4'= lowcase_selection;
def  'C-F5'= case_toggle;
def  'C-F6'= re_toggle;
def  'C-F7'= cap_word;
def  'C-F8'= size_window;
def  'C-F9'= debug_toggle_breakpoint_enabled;
def  'C-F10'= debug_run_to_cursor;
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= delete_prev_word;
def  'C-HOME'= top_of_window;
def  'C-END'= bottom_of_window;
def  'C-PGUP'= top_of_buffer;
def  'C-PGDN'= bottom_of_buffer;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
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
def  'C-S-F1'= cap_word;
def  'C-S-F2'= cap_selection;
def  'C-S-F5'= search_backward;
def  'C-S-F6'= translate_backward;
def  'C-S-F7'= list_macros;
def  'C-S-F8'= save_macro;
def  'C-S-F9'= project_build;
def  'C-S-F10'= project_compile;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A--'= prev_buffer;
def  'A-/'= alias_cd;
def  'A-0'-'A-9'= alt_bookmark;
def  'A-='= execute_selection;
def  'A-A'= brief_select_char;
def  'A-B'= list_buffers;
def  'A-C'= brief_select_block;
def  'A-D'= delete_line;
def  'A-E'= gui_open;
def  'A-F'= fill_selection;
def  'A-G'= gui_goto_line;
def  'A-H'= help;
def  'A-I'= insert_toggle;
def  'A-J'= brief_goto_bookmark;
def  'A-K'= delete_end_line;
def  'A-L'= brief_select_line;
def  'A-M'= brief_iselect_char;
def  'A-N'= next_buffer;
def  'A-O'= name;
def  'A-P'= print_selection;
def  'A-Q'= quote_key;
def  'A-R'= gui_insert_file;
def  'A-S'= gui_find;
def  'A-T'= gui_replace;
def  'A-U'= undo;
def  'A-V'= version;
def  'A-W'= brief_save;
def  'A-X'= safe_exit;
def  'A-Y'= begin_select;
def  'A-Z'= dos;
def  'A-F1'= api_index;
def  'A-F2'= zoom_window;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= gui_find_backward;
def  'A-F6'= gui_replace_backward;
def  'A-F7'= list_macros;
def  'A-F8'= gui_save_macro;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= project_compile;
def  'A-BACKSPACE'= delete_word;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-HOME'= left_side_of_window;
def  'A-END'= right_side_of_window;
def  'A-LEFT'= window_left;
def  'A-RIGHT'= window_right;
def  'A-UP'= window_above;
def  'A-DOWN'= window_below;
def  'A-M-M'= iconize_all;
def  'A-M-W'= close_all;
def  'A-S-0'-'A-S-9'= alt_gtbookmark;
def  'A-S-J'= activate_bookmarks;
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
   _default_option('S',IGNORECASE_SEARCH);
   def_switchbuf_cd=false;
   def_smarttab=2;   // Default extension specific setting
   _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
   def_process_tab_output=1;
   def_click_past_end=1;
   def_gui=0;
   def_keys = 'brief-keys';

   def_alt_menu=0;
   def_preplace=0;
   def_buflist=2;

   def_deselect_copy=1;
   def_deselect_paste=1;
   def_persistent_select='N';
   def_advanced_select='P';
   def_select_style = 'CI';
   def_scursor_style=0;

   def_updown_col=0;
   def_hack_tabs=0;
   def_line_insert = 'B';

   def_next_word_style = 'B';
   def_top_bottom_style = '0';
   def_linewrap = '0';
   def_join_strips_spaces = true;
   def_cursorwrap= '0';
   def_jmp_on_tab = '0';
   def_pull = '0';

   // Operate on current word starting from cursor.
   def_from_cursor = '0';
   def_word_delim = '0';
   def_restore_cursor = '1';
   def_modal_tab = 1;
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
      1,         // Fundamental indent with tabs setting
      1,         // Common indent with tabs setting
      '+4'       // Common tabs setting
      );

   _scroll_style('H 2');
   _search_case('I');
   //_cursor_shape('100 1000 830 1000 100 450 500 1000')

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   _update_sysmenu_bindings();
   menu_mdi_bind_all();

   _default_option('n','');
   _default_option(VSOPTION_LCNOCOLON,0);
   def_brief_word=1;
   def_vcpp_word=0;
   def_subword_nav=0;
   def_vcpp_bookmark=0;
   // Completion e and edit lists binary files
   def_list_binary_files=false;
   _default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS,1);
   _default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR,VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR);
   if (machine()=='MACOSX') {
      _default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY,1);
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,0);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,0);
   }
   rc=0;
}
