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
#import "setupext.e"
#import "search.e"
#endregion

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
//bool  def_word_continue;

defmain()
{
   def_re_search_flags=VSSEARCHFLAG_PERLRE;
   def_inclusive_block_sel=1;
   def_display_buffer_id=false;
   def_updown_screen_lines=true;
   _default_option('S',IGNORECASE_SEARCH);

   // name of keytable for the emulation
   def_keys                =  'bbedit-keys';
   def_block_mode_fill_only_if_line_long_enough=false;

   // cd on a switch buffer
   def_switchbuf_cd        =  false;

   _SmartTabSetAll(2);

   // config modified flags
   _config_modify_flags(CFGMODIFY_DEFVAR);

   // Default build window output to tab in output toolbar
   def_process_tab_output  =  true;

   // Can't click in virtual space at end of line in BBEdit
   def_click_past_end      =  '0';

   // Do we default to a gui interface for find and open/new? yes for BBEdit
   def_gui                 =  1;

   // alt menu hot keys: on
   def_alt_menu            =  1;

   // Alt+Shift+Left/Right/Up/Down/Home/End create a block selection?
   def_cua_select_alt_shift_block=!_isMac();

   // prompt on replace? yes
   def_preplace            =  1;

   // flags for buffer list = Sort list(0x01) & Select active buffer(0x08)
   def_buflist             =  9;

   // deselect after copy? no
   def_deselect_copy       =  false;

   // deselect after paste? yes
   def_deselect_paste      =  true;

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
   _SoftWrapUpdateAll(false,true);
   _str updateTable:[];
   updateTable:[VSLANGPROPNAME_TABS]='';
   updateTable:[VSLANGPROPNAME_INDENT_WITH_TABS]='';
   updateTable:[VSLANGPROPNAME_SOFT_WRAP]='';
   updateTable:[VSLANGPROPNAME_SOFT_WRAP_ON_WORD]='';
   if(index_callable(find_index('_update_buffer_from_new_setting',PROC_TYPE))) _update_buffer_from_new_setting(updateTable);

   // Scroll settings 
   //   C: Center scrolling
   //   S: Smooth scrolling number (number): # of lines from t/b before scrolling
   //   H: Smooth scrolling vertical, center scrolling horizontally:
   _scroll_style('H 2');

   // Case insensitive search by default
   _search_case('I');

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

