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
#import "guifind.e"
#import "main.e"
#import "options.e"
#import "search.e"
#import "stdcmds.e"
#import "quickstart.e"
#endregion

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= help;
def  'F2'= list_symbols;
def  'F3'= push_tag;
def  'F4'= activate_tbclass;
def  'F5'= debug_step_into;
def  'F6'= debug_step_over;
def  'F7'= debug_step_out;
def  'F8'= debug_go;
def  'F9'= debug_toggle_breakpoint;
def  'F10'= debug_step_over;
def  'F11'= project_debug;
def  'F12'= load;
def  'ENTER'= split_insert_line;
def  'TAB'= move_text_tab;
def  'BACKSPACE'= linewrap_rubout;
def  'C- '= eclipse_content_assist;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
def  'M-='= execute_selection;
def  'M-A'= select_all;
def  'M-C'= copy_to_clipboard;
def  'M-E'= set_find;
def  'M-F'= gui_find;
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
def  'M-PAD-STAR'= debug_show_next_statement;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= undo_cursor;
def  'S-F10'= project_compile;
def  'S-F11'= debug_step_out;
def  'S-F12'= save;
def  'S-ENTER'= nosplit_insert_line;
def  'S-TAB'= move_text_backtab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-C'= macos_show_colors;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'C-0'-'C-2'= alt_bookmark;
def  'C-3'= eclipse_gui_quick_access;
def  'C-4'-'C-9'= alt_bookmark;
def  'C-A'= select_all;
def  'C-B'= eclipse_build_all;
def  'C-C'= copy_to_clipboard;
def  'C-D'= delete_line;
def  'C-E'= eclipse_quick_editor_switch;
def  'C-F'= gui_find;
def  'C-H'= activate_find_symbol;
def  'C-I'= force_reindent;
def  'C-J'= i_search;
def  'C-K'= find_next;
def  'C-L'= gui_goto_line;
def  'C-M'= eclipse_maximize_part;
def  'C-N'= eclipse_new_wizard;
def  'C-O'= eclipse_show_outline;
def  'C-P'= gui_print;
def  'C-Q'= undo_cursor;
def  'C-R'= debug_run_to_cursor;
def  'C-S'= save;
def  'C-U'= deselect;
def  'C-V'= paste;
def  'C-W'= close_window;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= next_hotspot;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-PGUP'= prev_buff_tab;
def  'C-PGDN'= next_buff_tab;
def  'C-F1'= wh;
def  'C-F2'= debug_stop;
def  'C-F4'= close_window;
def  'C-F5'= project_execute;
def  'C-F6'= eclipse_next_editor;
def  'C-F7'= eclipse_next_view;
def  'C-F8'= eclipse_next_perspective;
def  'C-F9'= debug_toggle_breakpoint_enabled;
def  'C-F10'= context_menu;
def  'C-F11'= eclipse_run;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= edit_associated_file;
def  'C-BACKSPACE'= delete_prev_word;
def  'C-DEL'= delete_word;
def  'C-INS'= copy_to_clipboard;
def  'C-UP'= scroll_up;
def  'C-DOWN'= scroll_down;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-A'= eclipse_open_plugin_artifact; 
def  'C-S-B'= debug_toggle_breakpoint;
def  'C-S-C'= toggle_comment;
def  'C-S-D'= javadoc_editor;
def  'C-S-E'= list_buffers;
def  'C-S-F'= beautify_selection;
def  'C-S-G'= push_ref;
def  'C-S-H'= activate_tbclass;
def  'C-S-I'= expand_alias;
def  'C-S-J'= reverse_i_search;
def  'C-S-K'= find_prev;
def  'C-S-L'= lowcase_selection;
def  'C-S-M'= jrefactor_add_import;
def  'C-S-N'= activate_bookmarks;
def  'C-S-O'= jrefactor_organize_imports;
def  'C-S-P'= find_matching_paren;
def  'C-S-R'= eclipse_open_resource;
def  'C-S-S'= save_all;
def  'C-S-T'= activate_tbclass;
def  'C-S-U'= quick_mark_all_occurences;
def  'C-S-V'= list_clipboards;
def  'C-S-Q'= toggle_modified_lines;
def  'C-S-W'= close_all;
def  'C-S-X'= upcase_selection;
def  'C-S-Y'= lowcase_selection;
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-F4'= close_all;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= eclipse_prev_editor;
def  'C-S-F7'= eclipse_prev_view;
def  'C-S-F8'= eclipse_prev_perspective;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S- '= function_argument_help;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= delete_end_line;
def  'C-S-UP'= prev_proc;
def  'C-S-DOWN'= next_proc;
def  'C-PAD-MINUS'= hide_code_block;
def  'C-PAD-PLUS'= show_code_block;
def  'C-S-PAD-SLASH'= hide_comments_and_code_blocks;
def  'C-PAD-STAR'= show_all;
def  'C-A-DOWN'= copy_lines_down;
def  'C-A-UP'= copy_lines_up;
def  'C-A-J'= join_lines;
def  'C-A-G'= find_in_workspace;
def  'C-/'= toggle_comment;
def  'C-S-/'= toggle_comment;
def  'A-='= execute_selection;
def  'A--'= eclipse_show_system_menu;
def  'A-F1'= api_index;
def  'A-F2'= move_edge;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= restore_mdi;
//def  'A-F7'= move_mdi;
//def  'A-F8'= size_mdi;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= maximize_mdi;
def  'A-F11'= record_macro_toggle;
def  'A-F12'= record_macro_end_execute;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-DOWN'= move_lines_down;
def  'A-UP'= move_lines_up;
def  'A-LEFT'= eclipse_backward_history;
def  'A-RIGHT'= eclipse_forward_history;
def  'A-M-M'= iconize_all;
def  'A-M-N'= eclipse_new_quick_menu;
def  'A-M-W'= close_all;
def  'A-S-J'= javadoc_comment;
def  'A-S-A'= toggle_select_type;
def  'A-S-Q'= eclipse_show_view;
def  'A-S-W'= eclipse_quick_show_in;
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
   def_click_past_end=0;
   def_gui=1;
   def_keys = 'eclipse-keys';

   def_alt_menu=1;
   def_preplace=1;
   def_buflist=3;

   def_deselect_copy=0;
   def_deselect_paste=1;
   def_persistent_select='D';
   def_advanced_select='P';
   def_select_style = 'CN';
   def_scursor_style=0;

   def_updown_col=1;
   def_hack_tabs=0;
   def_line_insert = 'A';

   def_next_word_style = 'E';
   def_top_bottom_style = '0';
   def_linewrap = '1';
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

 #if !__UNIX__
   _default_option(VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE,0);
 #endif
   _default_option(VSOPTION_LINE_NUMBERS_LEN,1);
   _default_option(VSOPTION_LCREADWRITE,0);
   _default_option(VSOPTION_LCREADONLY,0);
   _LCUpdateOptions();
   def_ispf_flags=0;

   _default_option(VSOPTION_NEXTWINDOWSTYLE,1);

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
   def_vcpp_word=1;
   def_subword_nav=1;
   def_vcpp_bookmark=0;
   _default_option('t', 0);   // Turn "Top of File" line off
#if __OS390__ || __TESTS390__
   // Configuration General
   def_one_file = ''; // one file per window: off
   _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
   _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_STRICT_HALVING);
   def_alt_menu = 1; // alt menu hot keys: on
   _default_option('a',0); // alt menu: off
   _default_option('u',1); // draw box around current line: on
   // Configuration Search
   def_leave_selected = 0; // leave selected: off
   def_mfsearch_init_flags = MFSEARCH_INIT_CURWORD; // word at cursor: on
   def_mfsearch_init_flags |= MFSEARCH_INIT_SELECTION; // selected text: on
   // Configuration More
   _default_option('l', 144); // window left margin: 0.1 ==> 0.1 * 1440 = 144
   def_next_word_style = 'B'; // next word style: begin
#endif
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