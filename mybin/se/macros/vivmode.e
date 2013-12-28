////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48931 $
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
#include "ex.sh"
#import "clipbd.e"
#import "complete.e"
#import "ex.e"
#import "markfilt.e"
#import "pmatch.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "vi.e"
#import "vicmode.e"
#endregion

boolean in_char_visual_mode;
boolean in_line_visual_mode;
boolean in_block_visual_mode;

/**
 * By default this command handles the 'l', 'RIGHT', or 'SPACE' key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_select_right() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count, status;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      } else {
         right();
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   status = vi_cursor_right(repeat_count);
   vi_visual_select(/*status*/);
   return(0);
}

/**
 * By default this command handles the 'HOME' key pressed in 
 * visual mode. Text is selected from the cursor to the 
 * beginning of the line. 
 * 
 * @return 
 */
_command int vi_visual_begin_line() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count, status;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      } 
      return(0);
   }
   vi_visual_select();
   vi_begin_line();
   // Need to grab that last character if in character visual mode
   if(in_char_visual_mode){
      vi_visual_select();
   } else if (in_line_visual_mode){
      vi_visual_select();
   } else {
      int longest = 0;
      int boundary_line = p_line;
      int i, start_col, new_num_lines, difference;
      int num_lines = count_lines_in_selection();
      typeless p, begin_p;
      begin_select();
      _save_pos2(begin_p);
      start_col = p_col;
      // Find the longest line in the entire selection
      // This serves as the boundary for the new selection
      for (i = 0; i < num_lines; i++) {
         if(_line_length() > longest){
            longest = _line_length();
            boundary_line = p_line;
            vi_begin_line();
            _save_pos2(p);
         }
         vi_next_line();
         p_col = start_col;
      }
      deselect();
      // Select from the beginning of the original selection to the boundary
      _restore_pos2(begin_p);
      vi_visual_select();
      _restore_pos2(p);
      vi_visual_select();
      // Find out how many more lines are left out of the selection and grab them
      new_num_lines = count_lines_in_selection();
      difference = num_lines - new_num_lines;
      for (i = 0; i < difference; i++) {
         vi_visual_select_down();
      }
   }
   return(0);
}

/**
 * By default this command handles the 'END' key pressed in visual mode.
 * Text is selected from the cursor to the end of the line.
 * 
 * @return 
 */
_command int vi_visual_end_line() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count, status;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( key:==' ' ) {
         maybe_complete();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      } 
      return(0);
   }
   vi_visual_select();
   vi_end_line();
   // Need to grab that last character if in character visual mode
   if(in_char_visual_mode){
      vi_visual_select(/*1*/);
   } else if (in_line_visual_mode){
      vi_visual_select();
   } else {
      int longest = 0;
      int boundary_line = p_line;
      int i, start_col, new_num_lines, difference;
      int num_lines = count_lines_in_selection();
      typeless p, begin_p;
      begin_select();
      _save_pos2(begin_p);
      start_col = p_col;
      // Find the longest line in the entire selection
      // This serves as the boundary for the new selection
      for (i = 0; i < num_lines; i++) {
         if(_line_length() > longest){
            longest = _line_length();
            boundary_line = p_line;
            vi_end_line();
            _save_pos2(p);
         }
         vi_next_line();
         p_col = start_col;
      }
      deselect();
      // Select from the beginning of the original selection to the boundary
      _restore_pos2(begin_p);
      vi_visual_select();
      _restore_pos2(p);
      vi_visual_select();
      // Find out how many more lines are left out of the selection and grab them
      new_num_lines = count_lines_in_selection();
      difference = num_lines - new_num_lines;
      for (i = 0; i < difference; i++) {
         vi_visual_select_down();
      }
   }
   return(0);
}

/**
 * By default this command handles the 'h', 'LEFT', key pressed 
 * in visual mode and selects the appropriate line, character, 
 * or block. 
 * 
 * @return   
 */
_command int vi_visual_select_left() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      } else if ( key:==BACKSPACE ) {
         rubout();
      } else {
         left();
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   vi_cursor_left(repeat_count);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the 'BACKSPACE', 'S-BACKSPACE', key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_backspace() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      } else if ( key:==BACKSPACE ) {
         rubout();
      } else {
         left();
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   vi_cmd_backspace(repeat_count);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the 'k' or 'UP' key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_select_up() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count;
   _str key;
   if( command_state() ) {
      key=last_event();
      if( key==UP && p_window_id==_cmdline ) {
         retrieve_prev();
      } else if( key==DOWN && p_window_id==_cmdline ) {
         retrieve_next();
      } else if( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   vi_next_line(repeat_count, '-');
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the 'ENTER', 'S-ENTER', or '+' key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_select_begin_down() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count;
   _str key;
   if ( command_state() ) {
      key=last_event();
      if ( key:==ENTER && p_window_id==_cmdline ) {
         command_execute();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   vi_begin_next_line(repeat_count);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the 'j', 'DOWN', key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_select_down() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   int repeat_count;
   if (command_state()) {
      _str key;
      key=last_event();
      if ( key==UP && p_window_id==_cmdline ) {
         retrieve_prev();
      } else if ( key==DOWN && p_window_id==_cmdline ) {
         retrieve_next();
      } else if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if( ! isinteger(repeat_count) || repeat_count<1 ) {
      repeat_count=1;
   }
   vi_visual_select();
   vi_next_line(repeat_count);
   vi_visual_select();
   return(0);
}                 

/**
 * By default this command handles the 'x', 'd', or 'DEL' key pressed in visual mode.
 * The currently selected text (if any) is deleted and copied to the clipboard.
 * 
 * @return 
 */
_command int vi_visual_delete() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      begin_select();
      vi_cut(0,VI_CB0);
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'r' key pressed in visual mode.
 * The currently selected text (if any) is replaced by the next key pressed by the user.
 * 
 * @return 
 */
_command int vi_visual_replace() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      fill_selection();
      begin_select();
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'C' key pressed in visual mode.
 * The lines involved in the selection are cut to the clipboard from the beginning 
 * of the selection to the end of the line.  In character visual mode the entirety 
 * of the lines is deleted.  Insert mode is then toggled on.
 * 
 * @return 
 */
_command int vi_visual_change_to_end() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      if(in_char_visual_mode){
         int num_lines = count_lines_in_selection();
         int i;
         begin_select();
         cut_line(VI_CB0);
         for (i = 1; i < num_lines; i++) {
            cut_line(VI_CB0);
         }
         vi_visual_toggle();
         vi_above_newline_mode();
         vi_switch_mode('I');                   
      } else if (in_line_visual_mode) {
         begin_select();
         vi_cut(0,VI_CB0);
         vi_visual_toggle();
         vi_above_newline_mode();
         vi_switch_mode('I');                   
      } else if (in_block_visual_mode) {
         // switch to block insert mode for block selections
         typeless start;
         _save_pos2(start);
         int num_lines = count_lines_in_selection();
         end_select();
         typeless p,p2;
         _save_pos2(p);
         begin_select();
         int col = p_col;
         _save_pos2(p2);
         _restore_pos2(start);
         vi_visual_end_line();
         vi_cut(0, VI_CB0);
         _restore_pos2(p);
         _select_block();
         _restore_pos2(p2);
         p_col = col;
         _select_block();
         block_insert_mode();
         vi_visual_toggle();
      }
   }
   return(0);
}

/**
 * By default this command handles the 'c' key pressed in visual mode.                 
 * The currently selected text is deleted and copied to the clipboard, and insert mode 
 * is turned on.                                                                       
 *                                                                                     
 * @return                                                                             
 */
_command int vi_visual_change() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      if (in_char_visual_mode) {
         begin_select();
         vi_cut(0,VI_CB0);
         vi_visual_toggle();
         vi_switch_mode('I');
      } else if (in_line_visual_mode) {
         begin_select();
         vi_cut(0,VI_CB0);
         vi_visual_toggle();
         vi_above_newline_mode();
         vi_switch_mode('I');
      } else {
         // switch to block insert mode for block selections
         int num_lines = count_lines_in_selection();
         end_select();
         typeless p;
         _save_pos2(p);
         begin_select();
         int col = p_col;
         vi_cut(0,VI_CB0);
         _select_block();
         _restore_pos2(p);
         p_col = col;
         _select_block();
         block_insert_mode();
         vi_toggle_block_visual();
      }
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'y' key pressed in visual mode.
 * The currently selected text (if any) is copied to the clipboard.
 * 
 * @return 
 */
_command int vi_visual_yank(int count=1, _str cb_name="") name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|
                                                       VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (!vi_visual_maybe_command()) {
      begin_select();
      clear_message();
      vi_cut(true,cb_name);
      vi_visual_toggle(0);
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'p' key pressed in visual mode.
 * The currently selected text (if any) is replaced by whatever is currently in the clipboard.
 * 
 * @return
 */
_command int vi_visual_put(_str cb_name="") name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   int repeat_count,i;
   if (!vi_visual_maybe_command()) {
      vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
      repeat_count=vi_repeat_info('C',arg(1));
      if( ! isinteger(repeat_count) || repeat_count<1 ) {
         repeat_count=1;
      }
      for (i = 0; i < repeat_count; i++) {
         begin_select();
         vi_put_after_cursor("",cb_name);
      }
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'u' key pressed in visual mode.
 * The currently selected text (if any) all downcased.
 * 
 * @return 
 */
_command int vi_visual_downcase() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      lowcase_selection();
      begin_select();
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'U' key pressed in visual mode.
 * The currently selected text (if any) is replaced by whatever is currently in the clipboard.
 * 
 * @return 
 */
_command int vi_visual_upcase() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      upcase_selection();
      begin_select();
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'J' key pressed in visual mode.
 * The currently selected lines of text (if any) are joined, with 1 leading space inserted.
 *  
 * Only pays attention to count if it's called from the ex 
 * command line (this is how Vim does it). 
 * 
 * @return 
 */
_command int vi_visual_join(int count = 1, int e = 0) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      int i;
      _str num_lines = count_lines_in_selection();
      if (!isinteger(num_lines)) {
         // ?
         vi_message('Bad selection.');
         return(1);
      }
      int nl = (int)num_lines;
      begin_select();
      if (e > 0 && e > p_line) {
         nl = e - p_line + 1;
      }
      typeless p;
      _save_pos2(p);
      for (i = 0; i < nl - 1; i++) {
         end_line();
         _insert_text(' ');
         join_line();
      }
      _restore_pos2(p);
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the '~' key pressed in visual mode.
 * The case of the currently selected text (if any) is toggled.
 * 
 * @return 
 */
_command int vi_visual_toggle_case() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      togglecase_selection();
      begin_select();
      vi_visual_toggle();
      return(0);
   }
   return(0);
}

/**
 * By default this command handles the 'o' key pressed in visual mode.
 * The cursor is moved to the beginning of the current selection.  If the cursor
 * is already at the beginning, then the cursor is moved to the end of the selection.
 * 
 * @return 
 */
_command int vi_visual_begin_select() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (!vi_visual_maybe_command()) {
      int start_line, end_line, start_col, end_col;
      typeless p, p2;
      // Save the original position
      _save_pos2(p);
      start_line = p_line;
      start_col = p_col;
      begin_select();
      end_line = p_line;
      end_col = p_col;
      // If we didn't move by going to the beginning, go to the end
      if(start_line == end_line && start_col == end_col){
         end_select();
      } else if (start_line == end_line && start_col > end_col && in_block_visual_mode) {
         // We were at the TR of the selection
         // Have to reset the original position to the end of the selection
         end_select();
         _save_pos2(p);
         begin_select();
      } else if (start_line > end_line && start_col == end_col && in_block_visual_mode) {
         // We were at the BL of the selection
         // Have to reset the original position to the end of the selection
         end_select();                                  
         _save_pos2(p);
         begin_select();
      }
      // Save the position we're going to move to
      _save_pos2(p2);
      // Go back to the new starting point of the selection and
      // start the selection
      deselect();
      _restore_pos2(p);
      vi_visual_select();
      // Move to the beginning or end of the old selection
      _restore_pos2(p2);
      vi_visual_select();
      return(0);
   }
   return(0);
}

/**
 * This command turns on/off visual mode, based on which of the three visual modes is
 * currently activated
 * 
 * @return 
 */
_command int vi_visual_toggle(int showmsg=1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|
                                          VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (!vi_visual_maybe_command()) {
      if (in_char_visual_mode) {
         vi_toggle_char_visual(showmsg);
      } else if (in_line_visual_mode) {
         vi_toggle_line_visual(showmsg);
      } else if (in_block_visual_mode) {
         vi_toggle_block_visual(showmsg);
      }
      return(0);
   }
   return(1);
}

/**
 * This command handles selecting a character, line, or block
 * depending on the current visual mode.
 */
_command void vi_visual_select() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (in_char_visual_mode) {
      _select_char('','EI');
   } else if (in_line_visual_mode) {
      _select_line();
   } else if (in_block_visual_mode) {
      _select_block();
   }
}

/**
 * By default this command handles '/' pressed in visual mode.
 * Selects to where the search lands.
 * 
 * This is implemented with all the jumping to positions because something
 * in find_next is preventing selections from continuing and this was quicker
 * then debugging that method.
 * 
 * @return 
 */
_command int vi_visual_search() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   typeless begin_p, end_p, final_p;
   _save_pos2(end_p);
   begin_select();
   _save_pos2(begin_p);
   _restore_pos2(end_p);   
   ex_search_mode(arg(1));
   _save_pos2(final_p);
   _restore_pos2(begin_p);
   vi_visual_select();
   _restore_pos2(final_p);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles '?' pressed in visual mode.
 * Selects to where the search lands.
 * 
 * This is implemented with all the jumping to positions because something
 * in find_next is preventing selections from continuing and this was quicker
 * then debugging that method.
 *
 *  @return 
 */
_command int vi_visual_reverse_search() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   typeless begin_p, end_p, final_p;
   _save_pos2(end_p);
   begin_select();
   _save_pos2(begin_p);
   _restore_pos2(end_p);   
   ex_reverse_search_mode(arg(1));
   _save_pos2(final_p);
   _restore_pos2(begin_p);
   vi_visual_select();
   _restore_pos2(final_p);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the '>' pressed while in 
 * visual mode. 
 * 
 * @return int
 */
_command int vi_visual_shift_right() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY) {
   int repeat_count, status;
   _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if (!isinteger(repeat_count)) {
      repeat_count = 1;
   }
   int i;
   for (i = 0; i < repeat_count; i++) {
      indent_selection();
   }
   return(0);
}

/**
 * By default this command handles the '<' pressed while in 
 * visual mode. 
 * 
 * @return int
 */
_command int vi_visual_shift_left() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY) {
   int repeat_count, status;
   _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_repeat_info(last_index(),last_event(),arg(1),arg(2));
   repeat_count=vi_repeat_info('C',arg(1));
   if (!isinteger(repeat_count)) {
      repeat_count = 1;
   }
   int i;
   for (i = 0; i < repeat_count; i++) {
      unindent_selection();
   }
   return(0);
}

/**
 * This command handles the 'w' pressed in visual mode. 
 * 
 * @return int
 */
_command int vi_visual_next_word(int count = 1, int select_end = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_next_word(count);
   vi_visual_select(/*select_end*/);
   return(0);
}

/**
 * This command handles the 'b' pressed in visual mode. 
 *  
 * @return int
 */
_command int vi_visual_prev_word(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_prev_word(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the 'W' pressed in visual mode. 
 * 
 * @return int
 */
_command int vi_visual_next_word2(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_next_word2(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the 'B' pressed in visual mode. 
 *  
 * h  
 * @return int
 */
_command int vi_visual_prev_word2(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_prev_word2(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the 'e' pressed in visual mode. 
 * 
 * @return int
 */
_command int vi_visual_end_word(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_end_word(count);
   vi_visual_select(/*1*/);
   return(0);
}

/**
 * This command handles the 'E' pressed in visual mode. 
 *  
 * h  
 * @return int
 */
_command int vi_visual_end_word2(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_end_word2(count);
   vi_visual_select(/*1*/);
   return(0);
}

/**
 * This command handles the '{' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_prev_paragraph(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_prev_paragraph(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the '}' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_next_paragraph(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_next_paragraph(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the '(' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_prev_sentence(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_prev_sentence(count);
   vi_visual_select();
   return(0);
}

/**
 * This command handles the ')' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_next_sentence(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return(0);
   }
   vi_next_sentence(count);
   vi_visual_select();
   return(0);
}

/**
 * Returns the "direction" that the current selection is moving 
 * in.  Used in vi_visual_i_cmd and vi_visual_a_cmd in order to 
 * see if we should be moving backwards or forwards 
 *  
 * @param dir set to the direction of the selection 
 *  
 * @see vi_visual_i_cmd 
 */
static void vi_visual_get_sel_dir(_str &dir){
   save_pos(auto p);
   start_col := p_col;
   start_line := p_line;
   begin_select();
   /*
   If the the selection is more than 1 character in size and the 
   cursor is on the beginning of the selection, we are moving 
   backwards. 
   */
   if (p_col == start_col && p_line == start_line && vi_visual_get_num_chars() > 0) {
      dir = "-";
   } else {
      dir = "+";
   }
   restore_pos(p);
}

/**
 * This command handles the 'a' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_a_cmd(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   int status;
   _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }

   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');

   key=vi_get_event();

   _str dir;
   vi_visual_get_sel_dir(dir);

   typeless p = 0;
   typeless p1 = 0;
   switch(event2name(key)){
   case 'w':
      vi_visual_select_inner_word(0,1,count,dir);
      break;
   case 'W':
      vi_visual_select_inner_word(1,1,count,dir);
      break;
// case 's':
//    vi_visual_select_inner_sentence(1,count,dir);
//    break;
// case 'p':
//    vi_visual_select_inner_paragraph(0,0,count,dir);
//    break;
   case 'b':
   case '(':
   case ')':
      vi_find_enclosing_bracket('(', '-', count);
      vi_visual_finish_i_cmd(p,p1,true);
      break;
   case 'B':
   case '{':
   case '}':
      vi_find_enclosing_bracket('{', '-', count);
      vi_visual_finish_i_cmd(p,p1,true);
      break;
   case '[':
   case ']':
      vi_find_enclosing_bracket('[', '-', count);
      vi_visual_finish_i_cmd(p,p1,true);
      break;
   }
   if (p && p1) {
      // Move back to the original paren
      restore_pos(p);
      vi_visual_select();
      restore_pos(p1);
      vi_visual_select();
   }

   return(0);
}

/**
 * This command handles the 'i' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_i_cmd(int count = 1) name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   int status;
   _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }

   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');

   if (in_block_visual_mode) {
      block_insert_mode();
      vi_toggle_block_visual();
      return(0);
   }

   key=vi_get_event();

   _str dir;
   vi_visual_get_sel_dir(dir);

   typeless p = 0;
   typeless p1 = 0;
   switch(event2name(key)){
   case 'w':
      vi_visual_select_inner_word(0,0,count,dir);
      break;
   case 'W':
      vi_visual_select_inner_word(1,0,count,dir);
      break;
   case 's':
      vi_visual_select_inner_sentence(0,count,dir);
      break;
   case 'p':
      vi_visual_select_inner_paragraph(0,0,count,dir);
      break;
   case 'b':
   case '(':
   case ')':
      vi_find_enclosing_bracket('(', '-', count);
      vi_visual_finish_i_cmd(p,p1);
      break;
   case 'B': 
   case '{':
   case '}':
      vi_find_enclosing_bracket('{', '-', count);
      vi_visual_finish_i_cmd(p,p1);
      break;
   case '[':
   case ']':
      vi_find_enclosing_bracket('[', '-', count);
      vi_visual_finish_i_cmd(p,p1);
      break;
   }
   if (p && p1) {
      // Move back to the original paren
      restore_pos(p);
      // Move off the paren
      right();
      // If we are at the end of the line, the selection should start on the next
      // line down because the paren shouldn't be included in the selection
      if (at_end_of_line()) {
         down();
         begin_line();
      }
      vi_visual_select();
      restore_pos(p1);
      vi_visual_select_left();
   }

   return(0);
}

/**
 * Helper function for vi_visual_i_cmd's, used to advance the
 * selection one position...either right or down, depending on
 * whether or not a line ending is encountered.
 */
static void vi_visual_move_right_or_down(){
   int cur_col = p_col;
   vi_visual_select_right();
   if (p_col == cur_col) {
      down();
      first_non_blank();
      left();
      vi_visual_select();
   }
}


/** 
 * This function is used to select any number of consecutive 
 * sentences. 
 *  
 * @param leading_spaces whether or not to include leading or 
 *                       trailing spaces
 * @param count number of selections to perform 
 * @param dir direction of the selection 
 *  
 * @see vi_visual_i_cmd  
 */
void vi_visual_select_inner_sentence(int spaces = 0, int count = 1, _str dir = "+"){
   int i;
   for (i = 0; i < count; i++) {
      size := vi_visual_get_num_chars() + 1;
      if (size > 1) {
         // if the selection is more than 1 character we can just 
         // find the next sentence 
         if (dir == "+") {
            vi_visual_move_right_or_down(); 
            next_sentence();
            vi_visual_select();
            vi_visual_backspace();
         } else {
            vi_visual_backspace(); 
            prev_sentence();
            vi_visual_select();
         }
      } else {
         // for single character selections, we know we are moving forward
         save_pos(auto p);
         startCol := p_col;
         sl := p_line;
         prev_sentence();
         next_sentence();
         boolean on_begin_sentence = false;
         // if we jumped back to a different sentence, we were on the start of a sentence 
         if (p_line < sl || (sl == p_line && p_col < startCol)) on_begin_sentence = true;
         restore_pos(p);
         if (on_begin_sentence) vi_visual_move_right_or_down(); 
         deselect();
         prev_sentence();
         vi_visual_select();
         next_sentence();
         vi_visual_backspace();
      }
      // advance the selection depending on the count
      if (i + 1 < count) {
         if (dir == "+") {
            vi_visual_move_right_or_down();
         } else {
            vi_visual_backspace(); 
         }
      }
   }
}

/** 
 * This function is used to select any number of consecutive 
 * paragraphs. 
 *  
 * @param leading_spaces whether or not to include leading 
 *                       spaces
 * @param trailing_spaces whether or not to include trailing 
 *                        spaces
 * @param count number of selections to perform 
 * @param dir direction of the selection 
 *  
 * @see vi_visual_i_cmd  
 */
void vi_visual_select_inner_paragraph(int leading_spaces = 0, int trailing_spaces = 0, int count = 1, _str dir = "+"){
   int i;
   for (i = 0; i < count; i++) {
      size := vi_visual_get_num_chars() + 1;
      if (size > 1) {
         // if the selection is more than 1 character we can just 
         // find the next paragraph
         if (dir == "+") {
            vi_visual_move_right_or_down(); 
            next_paragraph();
            vi_visual_select();
            vi_visual_backspace();
         } else {
            vi_visual_backspace(); 
            prev_paragraph();
            vi_visual_select();
         }
      } else {
         // for single character selections, we know we are moving forward
         save_pos(auto p);
         startCol := p_col;
         sl := p_line;
         prev_paragraph();
         next_paragraph();
         boolean on_begin_paragraph = false;
         // if we jumped back to a different paragraph, we were on the start of a paragraph
         if (p_line < sl || (sl == p_line && p_col < startCol)) on_begin_paragraph = true;
         restore_pos(p);
         if (on_begin_paragraph) vi_visual_move_right_or_down(); 
         deselect();
         prev_paragraph();
         vi_visual_select();
         next_paragraph();
         vi_visual_backspace();
      }
      // advance the selection depending on the count
      if (i + 1 < count) {
         if (dir == "+") {
            vi_visual_move_right_or_down();
         } else {
            vi_visual_backspace(); 
         }
      }
   }
}

/** 
 * This function is used to select any number of consecutive 
 * words or WORDs. 
 *  
 * @param word_type word or WORD 
 * @param spaces whether or not to include leading or
 *                       trailing spaces
 * @param count number of selections to perform 
 * @param dir direction of the selection 
 *  
 * @see vi_visual_i_cmd  
 */
void vi_visual_select_inner_word(int word_type = 0, int spaces = 0, int count = 1, _str dir = "+"){
   int i;
   for (i = 0; i < count; i++) {
      size := vi_visual_get_num_chars() + 1;
      if (size > 1) {
         if (dir == "+") {
            vi_visual_move_right_or_down(); 
         } else {
            vi_visual_backspace();
         }
      }
      int sc, ec, sl, el;
      // find the begin and end columns for the current word
      if (word_type == 0) {
         vi_cur_word_boundaries(sc, ec, spaces, dir);
      } else if (word_type == 1) {
         vi_cur_word_boundaries2(sc, ec, spaces, dir);
      }
      // if the selection is only 1 character we need to start the selection 
      // at the beginning of the word
      if (size == 1) {
         deselect();    
         p_col = sc;
         vi_visual_select();
      }
      p_col = ec;
      vi_visual_select();
      // increment the selection depending on the count
      if (i + 1 < count || ec == -1) {
         if (dir == "+") {
            vi_visual_move_right_or_down();
         } else {
            vi_visual_backspace();
         }
      }
   }
}

/**
 * This function is used to finish the 'i' block commands
 * because they are so similar.
 */
void vi_visual_finish_i_cmd(typeless &p,typeless &p1,boolean stay_on_paren=false){
   deselect();
   save_pos(p);
   int orig_line = p_line;
   // Can't find a match? Bail. 
   int status = find_matching_paren();
   if (status != 0) {
      return;
   }
   column := p_col;
   save_pos(auto ptemp);
   first_non_blank();
   // Check if the matching paren is the first char of a line
   if (column == p_col && !stay_on_paren) {
      // If so, move up to the previous line because the paren shouldn't 
      // be included in the selection
      up();
      end_line();
   } else {
      // If not, just stay where the matching paren is
      restore_pos(ptemp);
   }
   save_pos(p1);
}

/**
 * Used to count the number of characters in a selection.
 * 
 * @return int
 */
static int vi_visual_get_num_chars(){
   save_pos(auto p);
   begin_select();
   typeless start = _QROffset();
   end_select();
   typeless end_val = _QROffset();
   restore_pos(p);
   return(end_val - start);
}

/**
 * This command handles the case of typing in the SlickEdit
 * command line while in visual mode.
 * 
 * Grabbed from vi_maybe_normal_character
 * 
 * @return 0 if the user is on the command line
 *         1 if the user is not on the command line
 */
_command int vi_visual_maybe_command() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if ( command_state() ) {
      _str key=last_event();
      if ( isnormal_char(key) ) {
         keyin(key);
      }
      return(1);
   }   
   return(0);
}

/**
 * Handles ':' pressed in visual mode with a selection active.
 * Activates ex command line for operating on selections
 */
_command void vi_visual_ex_mode() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY) {
   if ( vi_visual_maybe_command() ) {
      return;
   }
   int sel_id = select_active();
   if (sel_id != 0) {
     lock_selection(); 
   } 
   ex_mode();
}
