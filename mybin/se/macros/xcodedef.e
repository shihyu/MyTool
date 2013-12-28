////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50146 $
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

def  'F5'= list_symbols;
def  'ENTER'= maybe_split_insert_line;
def  'TAB'= move_text_tab;
def  'BACKSPACE'= linewrap_rubout;
def  'HOME'= scroll_top;
def  'END'= scroll_bottom;
def  'LEFT'= cursor_left;
def  'RIGHT'= cursor_right;
def  'UP'= cursor_up;
def  'DOWN'= cursor_down;
def  'PGUP'= scroll_page_up;
def  'PGDN'= scroll_page_down;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
def  'CONTEXT'= context_menu;
def  'M-,'= config;
def  'M-0'= activate_projects;
def  'M-1'= cursor_error;
def  'M-3'= activate_watch;
def  'M-4'= activate_variables;
def  'M-5'= activate_registers;
def  'M-6'= activate_memory;
def  'M-7'= activate_call_stack;
def  'M-='= next_error;
def  'M-A'= select_all;
def  'M-B'= project_build;
def  'M-C'= copy_to_clipboard;
def  'M-D'= toggle_bookmark;
def  'M-E'= set_find;
def  'M-F'= gui_find;
def  'M-G'= find_next;
def  'M-I'= i_search;
def  'M-K'= project_compile;
def  'M-L'= gui_goto_line;
def  'M-M'= iconize_mdi;
def  'M-N'= new;
def  'M-O'= gui_open;
def  'M-P'= gui_print;
def  'M-Q'= safe_exit;
def  'M-S'= save;
def  'M-T'= macos_font_config;
def  'M-U'= revert_or_refresh;
def  'M-V'= paste;
def  'M-W'= quit;
def  'M-X'= cut;
def  'M-Z'= undo;
def  'M-['= shift_selection_left;
def  'M-\'= debug_toggle_breakpoint;
def  'M-]'= shift_selection_right;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'M-HOME'= scroll_line_up;
def  'M-END'= scroll_line_down;
def  'M-LEFT'= begin_line;
def  'M-RIGHT'= end_line;
def  'M-UP'= top_of_buffer;
def  'M-DOWN'= bottom_of_buffer;
def  'S- '= keyin_space;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= move_text_backtab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-HOME'= cua_select;
def  'S-END'= cua_select;
def  'S-LEFT'= cua_select;
def  'S-RIGHT'= cua_select;
def  'S-UP'= cua_select;
def  'S-DOWN'= cua_select;
def  'S-PGUP'= cua_select;
def  'S-PGDN'= cua_select;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  "S-M-'"= hsplit_window;
def  'S-M-.'= debug_go;
def  'S-M-/'= help;
def  'S-M-;'= spell_check;
def  'S-M-='= prev_error;
def  'S-M-B'= start_process;
def  'S-M-C'= macos_show_colors;
def  'S-M-D'= project_load;
def  'S-M-F'= find_in_files;
def  'S-M-G'= find_prev;
def  'S-M-I'= debug_step_into;
def  'S-M-K'= project_clean;
def  'S-M-N'= new_file;
def  'S-M-O'= debug_step_over;
def  'S-M-R'= activate_build;
def  'S-M-S'= gui_save_as;
def  'S-M-T'= debug_step_out;
def  'S-M-V'= list_clipboards;
def  'S-M-W'= close_buffer;
def  'S-M-Z'= redo;
def  'S-M-ENTER'= debug_stop;
def  'S-M-HOME'= cua_select;
def  'S-M-END'= cua_select;
def  'S-M-LEFT'= cua_select;
def  'S-M-RIGHT'= cua_select;
def  'S-M-UP'= cua_select;
def  'S-M-DOWN'= cua_select;
def  'C- '= codehelp_complete;
def  'C-,'= pop_bookmark;
def  'C-.'= push_tag;
def  'C-/'= push_ref;
def  'C-0'-'C-9'= alt_bookmark;
def  'C-='= diff;
def  'C-A'= begin_line;
def  'C-B'= cursor_left;
def  'C-C'= copy_to_clipboard;
def  'C-D'= linewrap_delete_char;
def  'C-E'= end_line;
def  'C-F'= cursor_right;
def  'C-G'= find_next;
def  'C-H'= linewrap_rubout;
def  'C-I'= indent_selection;
def  'C-J'= gui_goto_line;
def  'C-K'= delete_end_line;
def  'C-L'= select_line;
def  'C-M'= project_build;
def  'C-N'= cursor_down;
def  'C-O'= gui_open;
def  'C-P'= cursor_up;
def  'C-Q'= quote_key;
def  'C-R'= gui_replace;
def  'C-S'= save;
def  'C-T'= transpose_chars;
def  'C-U'= show_all;
def  'C-V'= page_down;
def  'C-W'= select_whole_word;
def  'C-X'= cut;
def  'C-Y'= redo;
def  'C-Z'= undo;
def  'C-['= next_hotspot;
def  'C-\'= plusminus;
def  'C-]'= find_matching_paren;
def  'C-`'= edit_associated_file;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= next_window;
def  'C-BACKSPACE'= cut_line;
def  'C-HOME'= top_of_buffer;
def  'C-END'= bottom_of_buffer;
def  'C-PGUP'= page_up;
def  'C-PGDN'= page_down;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-M-A'= activate_autos;
def  'C-M-C'= activate_call_stack;
def  'C-M-H'= activate_threads;
def  'C-M-I'= debug_step_instr;
def  'C-M-L'= activate_locals;
def  'C-M-M'= activate_members;
def  'C-M-N'= project_new_maybe_wizard;
def  'C-M-O'= workspace_open;
def  'C-M-S'= save_all;
def  'C-M-V'= activate_variables;
def  'C-M-W'= workspace_close;
def  'C-M-\'= debug_disable_all_breakpoints;
def  'C-M-BACKSPACE'= cut_prev_sexp;
def  'C-M-LEFT'= hide_code_block;
def  'C-M-RIGHT'= plusminus;
def  'C-M-UP'= show_procs;
def  'C-M-DOWN'= forward_down_sexp;
def  'C-S- '= complete_more;
def  'C-S-,'= complete_prev;
def  'C-S-.'= complete_next;
def  'C-S-0'-'C-S-9'= alt_gtbookmark;
def  'C-S-A'= cap_selection;
def  'C-S-B'= select_prev_sexp;
def  'C-S-C'= append_to_clipboard;
def  'C-S-D'= activate_bookmarks;
def  'C-S-E'= list_errors;
def  'C-S-F'= select_next_sexp;
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
def  'C-S-HOME'= cua_select;
def  'C-S-END'= cua_select;
def  'C-S-LEFT'= cua_select;
def  'C-S-RIGHT'= cua_select;
def  'C-S-UP'= prev_error;
def  'C-S-DOWN'= next_error;
def  'C-S-DEL'= unsurround;
def  'C-S-M-\'= debug_clear_all_breakpoints;
def  'C-S-M-LEFT'= select_prev_sexp;
def  'C-S-M-RIGHT'= select_next_sexp;
def  'C-S-M-UP'= hide_all_comments;
def  'A-F1'= api_index;
def  'A-F2'= move_edge;
def  'A-F3'= create_tile;
def  'A-F4'= safe_exit;
def  'A-F5'= restore_mdi;
def  'A-F9'= debug_breakpoints;
def  'A-F10'= maximize_mdi;
def  'A-F12'= load;
def  'A-ESC'= codehelp_complete;
def  'A-BACKSPACE'= delete_prev_word;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-LEFT'= prev_word;
def  'A-RIGHT'= next_word;
def  'A-UP'= prev_paragraph;
def  'A-DOWN'= next_paragraph;
def  'A-DEL'= delete_word;
def  'A-M-B'= activate_breakpoints;
def  'A-M-F'= activate_search;
def  'A-M-M'= iconize_all;
def  'A-M-N'= add_item;
def  'A-M-P'= debug_suspend;
def  'A-M-R'= project_execute;
def  'A-M-S'= save_all;
def  'A-M-W'= close_all;
def  'A-M-\'= debug_toggle_breakpoint_enabled;
def  'A-M-LEFT'= back;
def  'A-M-RIGHT'= forward;
def  'A-M-UP'= edit_associated_file;
def  'A-M-ENTER'= project_debug;
def  'A-S-LEFT'= cua_select;
def  'A-S-RIGHT'= cua_select;
def  'A-S-UP'= cua_select;
def  'A-S-DOWN'= cua_select;
def  'A-S-M-LEFT'= prev_buffer;
def  'A-S-M-RIGHT'= next_buffer;
def  'C-A-A'= activate_autos;
def  'C-A-C'= activate_call_stack;
def  'C-A-H'= activate_threads;
def  'C-A-L'= activate_locals;
def  'C-A-M'= activate_members;
def  'C-A-V'= activate_variables;
def  'C-A-W'= activate_watch;
def  'C-A-BACKSPACE'= cut_prev_sexp;
def  'C-A-LEFT'= prev_sexp;
def  'C-A-RIGHT'= next_sexp;
def  'C-A-UP'= backward_up_sexp;
def  'C-A-DOWN'= forward_down_sexp;
def  'C-A-M-B'= activate_deltasave;
def  'C-A-M-R'= clear_pbuffer;
def  'C-A-S-LEFT'= select_prev_sexp;
def  'C-A-S-RIGHT'= select_next_sexp;
def  'LBUTTON-DOWN'= mou_click;
def  'RBUTTON-DOWN'= mou_click_menu_block;
def  'MBUTTON-DOWN'= mou_paste;
def  'BACK-BUTTON-DOWN'= back;
def  'FORWARD-BUTTON-DOWN'= forward;
def  'LBUTTON-DOUBLE-CLICK'= mou_select_word;
def  'LBUTTON-TRIPLE-CLICK'= mou_select_line;
def  'MOUSE-MOVE'= _mouse_move;
def  'WHEEL-UP'= fast_scroll;
def  'WHEEL-DOWN'= fast_scroll;
def  'WHEEL-LEFT'= fast_scroll;
def  'WHEEL-RIGHT'= fast_scroll;
def  'S-LBUTTON-DOWN'= mou_extend_selection;
def  'C-LBUTTON-DOWN'= mou_click_copy;
def  'C-RBUTTON-DOWN'= mou_move_to_cursor;
def  'C-WHEEL-UP'= scroll_page_up;
def  'C-WHEEL-DOWN'= scroll_page_down;
def  'C-WHEEL-LEFT'= fast_scroll;
def  'C-WHEEL-RIGHT'= fast_scroll;
def  'C-S-RBUTTON-DOWN'= mou_copy_to_cursor;
def  'A-LBUTTON-DOWN'= mou_click_copy;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;
def  'S-M-Y'= debug_stop;
def  'A-M-Y'= project_debug;


// global variables for slickedit options.
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
//boolean  def_word_continue;

defmain()
{
   def_updown_screen_lines=true;

   _SoftWrapUpdateAll(0,1);
   _default_option('S',IGNORECASE_SEARCH);

   // name of keytable for the emulation
   def_keys                =  'xcode-keys';

   // cd on a switch buffer
   def_switchbuf_cd        =  false;

   // Default extension specific setting
   def_smarttab            =  2;

   // config modified flags
   _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);

   // Default build window output to tab in output toolbar
   def_process_tab_output  =  1;

   // Can't click in virtual space at end of line in Xcode
   def_click_past_end      =  '0';

   // Do we default to a gui interface for find and open/new? yes for Xcode
   def_gui                 =  1;

   // alt menu hot keys: on
   def_alt_menu            =  1;

   // prompt on replace? yes
   def_preplace            =  1;

   // flags for buffer list = Sort list(0x01) & Select active buffer(0x08)
   def_buflist             =  9;

   // deselect after copy? no
   def_deselect_copy       =  0;

   // deselect after paste? yes
   def_deselect_paste      =  1;

   // delete selection before insert
   def_persistent_select   =  'D';

   // specifies a persistent select style for some selection functions
   def_advanced_select     =  'P';

   // default select style
   //   C:selection extends as the cursor moves 
   //   N:specifies a non-inclusive selection
   def_select_style        =  'CN';

   // Shift+cursor select style. 0 specifies character selection
   def_scursor_style       =  '0';

   //Does cursor stay in a straight line when moving up? yes
   def_updown_col          =  1;

   // Delete tab characters one space at a time? no
   def_hack_tabs           =  '0';

   // Line insert style: 'B': before 'A': After
   def_line_insert         =  'B';

   // Next-word and prev-word move the cursor to the 
   // (B)eginning or the (E)nd of the word
   def_next_word_style     =  'B';

   // preserve column when going to top/bottom? no
   def_top_bottom_style    =  '0';

   //Determines whether cursor-left command wraps
   // to column 1 when left margin greater than 1
   def_linewrap            =  '0';

   // joining lines strips leading spaces
   def_join_strips_spaces  = true;

   //Cursor left/right wrap? yes
   def_cursorwrap          =  '1';

   //Does cursor jump over Tab characters? yes
   def_jmp_on_tab          =  '1';

   //Does backspace pull characters when in replace mode? yes
   def_pull                =  '1';

   // Operate on current word starting from cursor. usually set for emacs
   def_from_cursor         =  '0';

   // changes select word behavior if set.
   def_word_delim          =  '0';

   // Do we want the cursor to be replaced when a search & replace operation
   // is completed succesfully? yes
   def_restore_cursor      =  1;

   // Do we want to indent a text selection when the m-[/m-] key is pressed? yes
   def_modal_tab           =  1;

   // Do we want one file per window? yes
   def_one_file            =  '+w';
   _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
   _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);

   // Leave the last occurence of a search string selected? yes
   def_leave_selected      =   1;

   // Multi-line selection allowed for up/low case converions? yes
   def_word_continue       =  true;

   // minimum automatic line numbers width
   _default_option(VSOPTION_LINE_NUMBERS_LEN,1);

   // Line-command read options (primarily used for ISPF emulation)
   _default_option(VSOPTION_LCREADWRITE,0);
   _default_option(VSOPTION_LCREADONLY,0);
   _LCUpdateOptions();
   def_ispf_flags=0;

   // Use smart next-buffer? no
   _default_option(VSOPTION_NEXTWINDOWSTYLE,0);

   // Set global tab settings
   _ModifyTabSetupAll(
      1,         // Fundamental indent with tabs setting
      1,         // Common indent with tabs setting
      '+4'       // Common tabs setting
      );

   // Scroll settings 
   //   C: Center scrolling
   //   S: Smooth scrolling number (number): # of lines from t/b before scrolling
   //   H: Smooth scrolling vertical, center scrolling horizontally:
   _scroll_style('H 2');

   // Case insensitive search by default
   _search_case('I');

   // Notify call-list about event table changes
   call_list('_eventtab_modify_',defeventtab default_keys,'');
   // Update the menus with key binding information if known
   _update_sysmenu_bindings();
   // Determines the key bindings for all menu items on the SlickEdit menu bar.
   menu_mdi_bind_all();

   // Determines the character shown on lines past the EOF.
   _default_option('n','');

   // Colon after line-prefix area? no
   _default_option(VSOPTION_LCNOCOLON,1);

   // brief style word select? no
   def_brief_word       =  0;

   // Visual C++ word select? yes
   def_vcpp_word        =  1;

   // Subword navigation? no
   def_subword_nav      =  false;

   // Visual C++ style bookmarks? no
   def_vcpp_bookmark    =  0;

   // Completion e and edit lists binary files
   def_list_binary_files=true;

   _default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS,0);
   _default_option(VSOPTION_MAC_ALT_KEY_BEHAVIOR,VSOPTION_MAC_ALT_KEY_DEFAULT_IME_BEHAVIOR);

   if (machine()=='MACOSX') {
      _default_option(VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY,1);
      _default_option(VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE,1);
      _default_option(VSOPTION_CLEAR_KEY_NUMLOCK_STATE,1);
   }
   // Clear the global Slick-C translator return code. Mostly deprecated.
   rc                   =  0;
}


