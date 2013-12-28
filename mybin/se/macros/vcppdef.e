////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49581 $
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
#import "guifind.e"
#import "main.e"
#import "options.e"
#import "stdcmds.e"
#import "guifind.e"
#endregion

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= help;
def  'F2'= next_bookmark;
def  'F3'= find_next;
def  'F4'= next_error;
def  'F5'= project_debug;
def  'F6'= compare;
def  'F7'= project_build;
def  'F8'= select_char;
def  'F9'= debug_toggle_breakpoint;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= push_tag;
def  'ENTER'= split_insert_line;
def  'TAB'= move_text_tab;
def  'BACKSPACE'= linewrap_rubout;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
def  'M-0'= activate_project_toolbar;
def  'M-2'= activate_output_toolbar;
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
def  'M-F2'= set_bookmark;
def  'M-F3'= gui_find;
def  'M-F4'= safe_exit;
def  'M-F5'= restore_mdi;
def  'M-F7'= project_edit;
def  'M-F8'= format_selection;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= maximize_mdi;
def  'M-F12'= activate_tag_properties_toolbar;
def  'M-BACKSPACE'= undo;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'S-F2'= prev_bookmark;
def  'S-F3'= find_prev;
def  'S-F4'= prev_error;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= undo_cursor;
def  'S-F10'= project_compile;
def  'S-F11'= debug_step_out;
def  'S-F12'= push_ref;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= cbacktab;
def  'S-BACKSPACE'= linewrap_rubout;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'C-0'-'C-7'= alt_bookmark;
def  'C-8'-'C-9'= alt_bookmark;
def  'C-A'= select_all;
def  'C-B'= select_block;
def  'C-C'= copy_to_clipboard;
def  'C-D'= maybe_active_search_hist_list;
def  'C-E'= find_matching_paren;
def  'C-F'= gui_find;
def  'C-G'= gui_goto;
def  'C-H'= gui_replace;
def  'C-I'= i_search;
def  'C-J'= prev_condition;
def  'C-K'= next_condition;
def  'C-L'= cut_line;
def  'C-M'= move_text_tab;
def  'C-N'= new;
def  'C-O'= gui_open;
def  'C-P'= gui_print;
def  'C-Q'= quote_key;
def  'C-S'= save;
def  'C-T'= function_argument_help;
def  'C-U'= lowcase_selection;
def  'C-V'= paste;
def  'C-W'= select_whole_word;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= next_hotspot;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-F1'= wh;
def  'C-F2'= toggle_bookmark;
def  'C-F3'= quick_search;
def  'C-F4'= close_window;
def  'C-F5'= project_execute;
def  'C-F6'= next_window;
def  'C-F7'= project_compile;
def  'C-F8'= select_line;
def  'C-F9'= debug_toggle_breakpoint_enabled;
def  'C-F10'= debug_run_to_cursor;
def  'C-F12'= load;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= delete_prev_word;
def  'C-PAD-STAR'= pop_bookmark;
def  'C-PAD-PLUS'= find_next;
def  'C-PAD-MINUS'= find_prev;
def  'C-UP'= scroll_up;
def  'C-DOWN'= scroll_down;
def  'C-DEL'= delete_word;
def  'C-INS'= copy_to_clipboard;
def  'C-BREAK'= stop_process;
def  'C-S- '= function_argument_help;
def  'C-S-0'-'C-S-7'= alt_gtbookmark;
def  'C-S-8'= view_specialchars_toggle;
def  'C-S-9'= alt_gtbookmark;
def  'C-S-A'= cap_selection;
def  'C-S-B'= list_buffers;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= select_matching_brace;
def  'C-S-G'= cursor_error;
def  'C-S-H'= hex;
def  'C-S-I'= reverse_i_search;
def  'C-S-J'= select_prev_condition;
def  'C-S-K'= select_next_condition;
def  'C-S-L'= delete_line;
def  'C-S-M'= start_process;
def  'C-S-N'= next_window;
def  'C-S-O'= expand_alias;
def  'C-S-P'= record_macro_end_execute;
def  'C-S-R'= record_macro_toggle;
def  'C-S-S'= set_next_error;
def  'C-S-T'= transpose_words;
def  'C-S-U'= upcase_selection;
def  'C-S-V'= list_clipboards;
def  'C-S-W'= html_preview;
def  'C-S-X'= append_cut;
def  'C-S-Z'= redo;
def  'C-S-['= prev_hotspot;
def  'C-S-F2'= clear_bookmarks;
def  'C-S-F3'= find_prev;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A-0'= activate_project_toolbar;
def  'A-2'= activate_output_toolbar;
def  'A-='= execute_selection;
def  'A-A'= adjust_block_selection;
def  'A-C'= copy_to_cursor;
def  'A-J'= join_line;
def  'A-K'= cut;
def  'A-L'= cut_sentence;
def  'A-N'= keyin_buf_name;
def  'A-R'= root_keydef;
def  'A-U'= deselect;
def  'A-X'= safe_exit;
def  'A-Y'= begin_select;
def  'A-Z'= select_char;
def  'A-F1'= api_index;
def  'A-F2'= set_bookmark;
def  'A-F3'= gui_find;
def  'A-F4'= safe_exit;
def  'A-F5'= restore_mdi;
def  'A-F7'= project_edit;
def  'A-F8'= format_selection;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= maximize_mdi;
def  'A-F12'= activate_tag_properties_toolbar;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-M-M'= iconize_all;
def  'A-M-V'= paste_replace_word;
def  'A-M-W'= close_all;
def  'A-S-T'= transpose_lines;
def  'A-S-F2'= activate_bookmarks;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;
def  'C-A-T'= list_symbols;
def  'C-MBUTTON-DOWN'= mou_select_word;

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
  //typeless def_cursor_beginend_select;

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
   _default_option('S',IGNORECASE_SEARCH|WRAP_SEARCH);
   def_switchbuf_cd=false;
   def_smarttab=2;   // Default extension specific setting
   _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);
   def_process_tab_output=1;
   def_click_past_end=0;
   def_gui=1;
   def_keys = 'vcpp-keys';

   def_alt_menu=1;
   def_preplace=1;
   def_buflist=3;

   def_deselect_copy=1;
   def_deselect_paste=1;
   def_persistent_select='D';
   def_advanced_select='P';
   def_select_style = 'CN';
   def_scursor_style=0;

   def_updown_col=1;
   def_hack_tabs=0;
   def_line_insert = 'B';
   def_cursor_beginend_select=1;

   def_next_word_style = 'B';
   def_top_bottom_style = '0';
   def_linewrap = '0';
   def_join_strips_spaces = true;
   def_cursorwrap= '1';
   def_jmp_on_tab = '1';
   def_pull = '1';

   // Operate on current word starting from cursor.
   def_from_cursor = '0';

   def_word_delim = '0';
   def_restore_cursor = 1;
   def_modal_tab = 1;
   def_one_file='+w';
   _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
   _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);
   def_leave_selected=1;
   def_word_continue=false;

   _default_option(VSOPTION_LINE_NUMBERS_LEN,1);
   _default_option(VSOPTION_LCREADWRITE,0);
   _default_option(VSOPTION_LCREADONLY,0);
   _LCUpdateOptions();
   def_ispf_flags=0;

 #if !__UNIX__
   _default_option(VSOPTION_NEXTWINDOWSTYLE,1);
 #endif
   _ModifyTabSetupAll(
      1,         // Fundamental indent with tabs setting
      1,         // Common indent with tabs setting
      '+4'       // Common tabs setting. Might want +8 when on UNIX
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
   def_vcpp_word=1;
   def_subword_nav=0;
   def_vcpp_bookmark=1;
   // Completion e and edit lists binary files
   def_list_binary_files=true;
   def_mfsearch_init_flags = MFSEARCH_INIT_HISTORY|MFSEARCH_INIT_SELECTION;
   _default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS,1);
   _default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR,VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR);
   if (machine()=='MACOSX') {
      _default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY,1);
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,1);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,1);
   }
   rc=0;
}
