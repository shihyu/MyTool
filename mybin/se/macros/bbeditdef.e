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
#import "main.e"
#import "options.e"
#import "stdcmds.e"
#endregion


defeventtab default_keys;

def  'F11'= debug_step_into;
def  'F12'= load;
def  'ENTER'= maybe_split_insert_line;
def  'TAB'= move_text_tab;
def  'BACKSPACE'= linewrap_rubout;
def  'HOME'= scroll_top;
def  'END'= scroll_bottom;
def  'PGUP'= scroll_page_up;
def  'PGDN'= scroll_page_down;
def  'DEL'= linewrap_delete_char;
def  'INS'= insert_toggle;
def  'M-,'= config;
def  'M-.'= push_tag;
def  'M-/'= push_ref;
def  'M-='= execute_selection;
def  'M-A'= select_all;
def  'M-B'= find_matching_paren;
def  'M-C'= copy_to_clipboard;
def  'M-D'= cursor_error;
def  'M-E'= set_find;
def  'M-F'= gui_find;
def  'M-G'= find_next;
def  'M-L'= select_line;
def  'M-N'= new;
def  'M-O'= gui_open;
def  'M-P'= gui_print;
def  'M-Q'= safe_exit;
def  'M-S'= save;
def  'M-V'= paste;
def  'M-W'= close_window;
def  'M-X'= cut;
def  'M-Z'= undo;
def  'M-['= move_text_backtab;
def  'M-\'= plusminus;
def  'M-]'= move_text_tab;
def  'M-`'= transpose_chars;
def  'M-BACKSPACE'= cut_line;
def  'M-PAD-STAR'= debug_show_next_statement;
def  'M-HOME'= top_of_buffer;
def  'M-END'= bottom_of_buffer;
def  'M-PGUP'= scroll_page_up;
def  'M-PGDN'= scroll_page_down;
def  'S-F11'= debug_step_out;
def  'S-F12'= save;
def  'S-ENTER'= keyin_enter;
def  'S-TAB'= move_text_backtab;
def  'S-BACKSPACE'= undo_cursor;
def  'S-HOME'= scroll_top;
def  'S-END'= scroll_bottom;
def  'S-PGUP'= scroll_page_up;
def  'S-PGDN'= scroll_page_down;
def  'S-DEL'= cut;
def  'S-INS'= paste;
def  'S-M-/'= help;
def  'S-M-A'= deselect;
def  'S-M-C'= append_to_clipboard;
def  'S-M-G'= find_prev;
def  'S-M-J'= bbedit_center_of_window;
def  'S-M-N'= bbedit_file_new_from_selection;
def  'S-M-V'= bbedit_paste_previous_clipbd;
def  'S-M-X'= append_cut;
def  'S-M-Z'= redo;
def  'S-M-['= shift_selection_left;
def  'S-M-]'= shift_selection_right;
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
def  'C-F11'= record_macro_toggle;
def  'C-F12'= record_macro_end_execute;
def  'C-ENTER'= nosplit_insert_line;
def  'C-TAB'= edit_associated_file;
def  'C-BACKSPACE'= cut_line;
def  'C-HOME'= scroll_top;
def  'C-END'= scroll_bottom;
def  'C-PGUP'= scroll_page_up;
def  'C-PGDN'= scroll_page_down;
def  'C-DEL'= cut_code_block;
def  'C-INS'= copy_to_clipboard;
def  'C-M-/'= next_window;
def  'C-M-N'= bbedit_file_new_html;
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
def  'A-='= execute_selection;
def  'A-BACKSPACE'= undo;
def  'A-PAD-STAR'= debug_show_next_statement;
def  'A-HOME'= scroll_top;
def  'A-END'= scroll_bottom;
def  'A-UP'= top_of_window;
def  'A-DOWN'= bottom_of_window;
def  'A-PGUP'= scroll_page_up;
def  'A-PGDN'= scroll_page_down;
def  'A-M-L'= select_paragraph;
def  'A-M-M'= iconize_all;
def  'A-M-S'= save_all;
def  'A-M-W'= close_all;
def  'A-M-`'= transpose_words;
def  'A-M-UP'= prev_error;
def  'A-M-DOWN'= next_error;
def  'A-S-M-N'= bbedit_file_new_from_clipboard;
def  'A-S-M-W'= close_all;
def  'C-S-F12' '0'-'9'= execute_last_macro_key;
def  'C-S-F12' 'a'-'z'= execute_last_macro_key;
def  'C-S-F12' 'F1'-'F12'= execute_last_macro_key;

// global variables for slickedit options.
//typeless def_gui;
//typeless def_keys;
//typeless def_alt_menu;
//typeless def_preplace;
//typeless def_buflist;
//typeless def_deselect_paste;
//typeless def_deselect_copy;
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
   def_keys                =  'bbedit-keys';

   // cd on a switch buffer
   def_switchbuf_cd        =  false;

   // Default extension specific setting
   def_smarttab            =  2;

   // config modified flags
   _config_modify_flags(CFGMODIFY_OPTION|CFGMODIFY_KEYS);

   // Default build window output to tab in output toolbar
   def_process_tab_output  =  1;

   // Can't click in virtual space at end of line in BBEdit
   def_click_past_end      =  '0';

   // Do we default to a gui interface for find and open/new? yes for BBEdit
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
   def_hack_tabs           =  false;

   // Line insert style: 'B': before 'A': After
   def_line_insert         =  'B';

   // Next-word and prev-word move the cursor to the 
   // (B)eginning or the (E)nd of the word
   def_next_word_style     =  'B';

   // preserve column when going to top/bottom? no
   def_top_bottom_style    =  '0';

   //Determines whether cursor-left command wraps
   // to column 1 when left margin greater than 1
   def_linewrap            =  false;

   // joining lines strips leading spaces
   def_join_strips_spaces  = true;

   //Cursor left/right wrap? yes
   def_cursorwrap          =  true;

   //Does cursor jump over Tab characters? yes
   def_jmp_on_tab          =  true;

   //Does backspace pull characters when in replace mode? yes
   def_pull                =  true;

   // Operate on current word starting from cursor. usually set for emacs
   def_from_cursor         =  false;

   // changes select word behavior if set.
   def_word_delim          =  '0';

   // Do we want the cursor to be replaced when a search & replace operation
   // is completed succesfully? yes
   def_restore_cursor      =  true;

   // Do we want to indent a text selection when the M-] key is pressed? yes
   def_modal_tab           =  1;

   // Do we want one file per window? yes
   def_one_file            =  '+w';
   _default_option(VSOPTION_TAB_TITLE,VSOPTION_TAB_TITLE_SHORT_NAME);
   _default_option(VSOPTION_SPLIT_WINDOW,VSOPTION_SPLIT_WINDOW_EVENLY);

   // Leave the last occurence of a search string selected? yes
   def_leave_selected      =  1;

   // Multi-line selection allowed for up/low case converions? yes
   def_word_continue       =  true;

   // Max number of displayable characters in prefix area for line numbers
   _default_option(VSOPTION_LINE_NUMBERS_LEN,1);

   // Line-command read options (primarily used for ISPF emulation)
   _default_option(VSOPTION_LCREADWRITE,0);
   _default_option(VSOPTION_LCREADONLY,0);
   _LCUpdateOptions();
   def_ispf_flags=0;

   // Use smart next-buffer? no
   _default_option(VSOPTION_NEXTWINDOWSTYLE,1);

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
   def_brief_word       =  false;

   // Visual C++ word select? yes
   def_vcpp_word        =  true;

   // Visual C++ style bookmarks? no
   def_vcpp_bookmark    =  false;

   // Subword navigation? no
   def_subword_nav      =  false;

   // Completion e and edit lists binary files
   def_list_binary_files=  true;

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

