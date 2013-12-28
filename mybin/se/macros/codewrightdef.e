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
#import "stdcmds.e"
#endregion

defeventtab default_keys;

def  'C-LEFT'= prev_word;
def  'C-RIGHT'= next_word;
def  'C-UP'= prev_tag;
def  'C-DOWN'= next_tag;
def  'F1'= help;
def  'F2'= save;
def  'F3'= find_next;
def  'F4'= file;
def  'F5'= project_debug;
def  'F6'= compare;
def  'F7'= record_macro_toggle;
def  'F8'= record_macro_end_execute;
def  'F9'= cmdline_toggle;
def  'F10'= debug_step_over;
def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= split_insert_line;
def  'TAB'= move_text_tab;
def  'ESC'= codewright_abort;
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
def  'M-F1'= function_argument_help;
def  'M-F2'= zoom_window;
def  'M-F3'= create_tile;
def  'M-F4'= safe_exit;
def  'M-F5'= restore_mdi;
//def  'M-F7'= move_mdi;
//def  'M-F8'= size_mdi;
def  'M-F9'= debug_breakpoints;
def  'M-F10'= maximize_mdi;
def  'M-BACKSPACE'= undo;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'M-INS'= redo;
def  'S-F5'= debug_stop;
def  'S-F6'= resync;
def  'S-F7'= shift_selection_left;
def  'S-F8'= shift_selection_right;
def  'S-F9'= undo_cursor;
def  'S-F10'= project_compile;
def  'S-F11'= debug_step_out;
def  'S-F12'= save;
def  'S-ENTER'= plusminus;
def  'S-TAB'= move_text_backtab;
def  'S-BACKSPACE'= delete_word;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-C'= macos_show_colors;
def  'S-M-G'= find_prev;
def  'S-M-S'= save_as;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'S-M-LEFT'= back;
def  'S-M-RIGHT'= forward;
def  'C--'= quit;
def  'C-0'-'C-9'= alt_bookmark;
def  'C-A'= select_all;
def  'C-B'= brief_select_block;
def  'C-C'= copy_to_clipboard;
def  'C-D'= delete_line;
def  'C-E'= gui_open;
def  'C-F'= gui_find;
def  'C-G'= find_next;
def  'C-H'= gui_replace;
def  'C-I'= brief_iselect_char;
def  'C-J'= gui_goto_line;
def  'C-K'= copy_word;
def  'C-L'= brief_select_line;
def  'C-M'= brief_select_char;
def  'C-N'= new;
def  'C-O'= gui_open;
def  'C-P'= gui_print;
def  'C-Q'= quote_key;
def  'C-R'= gui_replace;
def  'C-S'= save;
def  'C-T'= line_to_top;
def  'C-U'= undo;
def  'C-V'= paste;
def  'C-W'= gui_write_selection;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= select_paren_block;
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
def  'C-F9'= project_build;
def  'C-F10'= project_compile;
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= delete_prev_word;
def  'C-UP'= scroll_up;
def  'C-DOWN'= scroll_down;
def  'C-PGUP'= page_left;
def  'C-PGDN'= page_right;
def  'C-DEL'= delete_end_line;
def  'C-INS'= copy_to_clipboard;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-A'= cap_selection;
def  'C-S-B'= activate_bookmarks;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= lowcase_selection;
def  'C-S-F'= gui_insert_file;
def  'C-S-G'= show_procs;
def  'C-S-H'= hex;
def  'C-S-I'= i_search;
def  'C-S-J'= toggle_bookmark;
def  'C-S-K'= show_matching_paren;
def  'C-S-L'= gui_goto_line;
def  'C-S-M'= start_process;
def  'C-S-N'= next_doc;
def  'C-S-O'= name;
def  'C-S-P'= prev_doc;
def  'C-S-Q'= quick_search;
def  'C-S-R'= translate_again;
def  'C-S-S'= find_next;
def  'C-S-T'= codewright_abort;
def  'C-S-U'= upcase_selection;
def  'C-S-V'= list_clipboards;
def  'C-S-W'= reflow_paragraph;
def  'C-S-X'= view_specialchars_toggle;
def  'C-S-Z'= zoom_window;
def  'C-S-['= prev_hotspot;
def  'C-S-F4'= iconize_window;
def  'C-S-F5'= debug_restart;
def  'C-S-F6'= prev_window;
def  'C-S-F9'= debug_clear_all_breakpoints;
def  'C-S-ENTER'= nosplit_insert_line_above;
def  'C-S-TAB'= prev_window;
def  'C-S-DEL'= unsurround;
def  'A-='= execute_selection;
def  'A-F1'= function_argument_help;
def  'A-F2'= zoom_window;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= restore_mdi;
//def  'A-F7'= move_mdi;
//def  'A-F8'= size_mdi;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= maximize_mdi;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-INS'= redo;
def  'A-M-M'= iconize_all;
def  'A-M-W'= close_all;
def  'A-S-LEFT'= back;
def  'A-S-RIGHT'= forward;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;

//typeless def_gui;
//typeless def_keys;

//typeless def_alt_menu;
//typeless def_preplace;
//typeless def_buflist;

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
   def_gui=1;
   def_keys='codewright-keys';

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

   def_next_word_style = 'B';
   def_top_bottom_style = '0';
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
   def_mfsearch_init_flags= MFSEARCH_INIT_CURWORD|MFSEARCH_INIT_SELECTION;
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
   _default_option('s', _default_option('s')|WRAP_SEARCH); // wrap to begin/end: on
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
/*
******** codewright4def.e ************

defeventtab default_keys;
def "C-Z"=brief_select_char;
def 'PAD-PLUS'= copy_to_clipboard;
def 'PAD-MINUS'= cut;
def 'PAD-SLASH'= paste;
def 'PAD-STAR'= undo;
def 'c-s'=gui_find;
def 'c-a'=line_to_bottom;
def 'c-o'=center_line;
def 'c-m'=center_line;
def 'c-n'= next_doc;
def 'c-p'= prev_doc;

#include "codewrightdef.e"

*/
