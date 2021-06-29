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
#import "seek.e"
#endregion

/**
 * By default this command handles the 'l', 'RIGHT', or 'SPACE' key pressed in visual mode
 * and selects the appropriate line, character, or block.
 * 
 * @return 
 */
_command int vi_visual_select_right() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_begin_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
   vi_begin_line();
   vi_visual_select();
#if 0
   vi_visual_select();
   vi_begin_line();
   // Need to grab that last character if in character visual mode
   if(in_char_visual_mode){
      vi_visual_select();
   } else if (in_line_visual_mode){
      vi_visual_select();
   } else {
      longest := 0;
      boundary_line := p_line;
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
#endif
   return(0);
}

/**
 * By default this command handles the 'END' key pressed in visual mode.
 * Text is selected from the cursor to the end of the line.
 * 
 * @return 
 */
_command int vi_visual_end_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
   if (_select_type()!='BLOCK') {
      vi_end_line();
      if( _line_length() ) right();
      vi_visual_select();
      return 0;
   }
   longest := 0;
   int i;
   int num_lines = count_lines_in_selection();
   save_pos(auto p);
   _str pp=_select_type('','P');
   _begin_select();
   up();
   // Find the longest line in the entire selection
   // This serves as the boundary for the new selection.
   // This could work better for proportional fonts by
   // determining the longest line in pixels.
   for (i = 0; i < num_lines; ++i) {
      down();
      _TruncEndLine();
      if (p_fixed_font) {
         if(p_col > longest){
            longest = p_col;
         }
      } else {
         width:=_TextWidthFromCol(p_col);
         if (width>longest) {
            longest=width;
         }
      }
   }
   _select_type('','P','BB');
   _end_select();

   restore_pos(p);
   _select_type('','P',pp);
   if (p_fixed_font) {
      p_col=longest;
   } else {
      p_col=_ColFromTextWidth(longest);
   }
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the 'h', 'LEFT', key pressed 
 * in visual mode and selects the appropriate line, character, 
 * or block. 
 * 
 * @return   
 */
_command int vi_visual_select_left() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_backspace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_select_up() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_select_begin_down() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_select_down() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
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
_command int vi_visual_delete(typeless count="", _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      begin_select();
      vi_cut(false,cb_name);
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
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
_command int vi_visual_replace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      fill_selection();
      begin_select();
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
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
_command int vi_visual_change_to_end() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      // Remove C from selection
      _vi_visual_select('','');
      if(_select_type()=='CHAR'){
         //int num_lines = count_lines_in_selection();
         begin_select();
         _select_type('','T','LINE');
         vi_cut(false, '', "1");
#if 0
         int i;
         begin_select();
         cut_line("1");
         for (i = 1; i < num_lines; i++) {
            cut_line("1");
         }
#endif
         vi_above_newline_mode();
         if (_MultiCursorLastLoopIteration()) {
            vi_visual_toggle_off();
            vi_switch_mode('I');
         }
      } else if (_select_type()=='LINE') {
         begin_select();
         vi_cut(false, '', "1");
         vi_visual_toggle_off();
         vi_above_newline_mode();
         vi_switch_mode('I');                   
      } else if (_select_type()=='BLOCK') {
         _save_pos2(auto p);
         new_mark:=_duplicate_selection();
         orig_mark:=_duplicate_selection('');
         // Extend the block selection to longest line
         vi_visual_end_line();
         vi_cut(false, '', "1");
         _restore_pos2(p);
         _show_selection(new_mark);
         _free_selection(orig_mark);
         vi_visual_insert_mode();
      }
   }
   return(0);
}

/**
 * By default this command handles the 'c' or 's' key pressed in visual mode.                 
 * The currently selected text is deleted and copied to the clipboard, and insert mode 
 * is turned on.                                                                       
 *                                                                                     
 * @return                                                                             
 */
_command int vi_visual_change() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      if (_select_type()=='CHAR') {
         begin_select();
         vi_cut(false,'', "1");
         if (_MultiCursorLastLoopIteration()) {
            vi_visual_toggle_off(1,true);
            vi_switch_mode('I');
         }
      } else if (_select_type()=='LINE') {
         begin_select();
         vi_cut(false,'', "1");
         vi_above_newline_mode();
         if (_MultiCursorLastLoopIteration()) {
            vi_visual_toggle_off(1,true);
            vi_switch_mode('I');
         }
      } else {
         _save_pos2(auto p);
         new_mark:=_duplicate_selection();
         orig_mark:=_duplicate_selection('');
         vi_cut(false, '', "1");
         _restore_pos2(p);
         _show_selection(new_mark);
         _free_selection(orig_mark);
         vi_visual_insert_mode();
      }
      return(0);
   }
   return(0);
}
/**
 * By default this command handles the 'A' key pressed in visual mode.                 
 * The currently selected text is deleted and copied to the clipboard, and insert mode 
 * is turned on.                                                                       
 *                                                                                     
 * @return                                                                             
 */
_command int vi_visual_append() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      if (_select_type()=='CHAR' || _select_type()=='LINE') {
         //begin_select();
         //vi_cut(false,'', "1");
         if (_MultiCursorLastLoopIteration()) {
            vi_visual_toggle_off(1,true);
            vi_append_mode();
         }
      } else {
         new_mark:=_alloc_selection();
         orig_mark:=_duplicate_selection('');
         _save_pos2(auto p);
         _begin_select();//messageNwait('h1');
         int startcol,endcol;
         _get_selinfo(startcol,endcol,auto buf_id);
         int BlockSelStartPixel,BlockSelEndPixel;
         _BlockSelGetStartAndEndPixel(BlockSelStartPixel,BlockSelEndPixel);
         if (BlockSelStartPixel>=0) {
            _BlockSelGetStartAndEndCol(startcol,endcol, BlockSelStartPixel,BlockSelEndPixel);
            p_col=endcol;
         } else {
            p_col=endcol+((def_inclusive_block_sel)?1:0);
         }
         _show_selection(new_mark);
         _vi_visual_select('BLOCK','C','P');//messageNwait('h2 t='_select_type());
         _end_select(orig_mark);if (def_inclusive_block_sel) ++p_col;

         if ( _select_type('','S')=='C' && def_advanced_select!="") {
            //int first_col,last_col,buf_id2;
            //_get_selinfo(first_col,last_col,buf_id2);
            if ( p_buf_id==buf_id ) {
               select_it(_select_type(),"",_select_type('','I'):+def_advanced_select);
            }
         }

         _free_selection(orig_mark);
         vi_visual_insert_mode();
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
_command int vi_visual_yank(int count=1, _str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|
                                                       VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (!vi_visual_maybe_command()) {
      begin_select();
      clear_message();
      vi_cut(true,cb_name);
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off(0);
      }
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
_command int vi_visual_put(typeless count="",_str cb_name="") name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   int repeat_count,i;
   if (!vi_visual_maybe_command()) {
      vi_repeat_info(last_index(),last_event(),count,cb_name);
      repeat_count=vi_repeat_info('C',count);
      if( ! isinteger(repeat_count) || repeat_count<1 ) {
         repeat_count=1;
      }
      for (i = 0; i < repeat_count; i++) {
         // Don't begin select cause the selection to be lock so paste 
         // replace doesn't work. Switch this selection to be a non-persistant selection
         // so we can do a paste replace.
         _vi_visual_select('','','');
         _begin_select();
         vi_put_after_cursor("",cb_name);
      }
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
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
_command int vi_visual_downcase() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      lowcase_selection();
      begin_select();
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
      return(0);
   }
   return(0);
}

/**
 * By default this command handles '!' pressed.
 */
_command int vi_visual_filter() name_info(','VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (vi_visual_maybe_command()) return 0;
   ex_mode('',"'<,'>!");
   return 0;
}
/**
 * By default this command handles the 'U' key pressed in visual mode.
 * The currently selected text (if any) is replaced by whatever is currently in the clipboard.
 * 
 * @return 
 */
_command int vi_visual_upcase() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      upcase_selection();
      begin_select();
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
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
_command int vi_visual_join(int count = 1, int start_addr = 0) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      int i;
      num_lines := 1;
      if (start_addr) {
         p_line=start_addr;
         num_lines=count;
      }  else if (select_active() && !start_addr) {
         num_lines= count_lines_in_selection();
         if (!isinteger(num_lines)) {
            // ?
            vi_message('Bad selection.');
            return(1);
         }
         begin_select();
         --num_lines;
      } else {
         if (isinteger(count)) {
            num_lines=count;
         }
      }
      //say('count='count' a1='start_addr' a2='end_addr);
      //say('num_lines='num_lines);
      typeless p;
      _save_pos2(p);
      status := 0;
      for (i = 0; i < num_lines; ++i) {
         status=vi_join_line();
         if (status) break;
      }
      _restore_pos2(p);
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
      return(status);
   }
   return(0);
}

/**
 * By default this command handles the '~' key pressed in visual mode.
 * The case of the currently selected text (if any) is toggled.
 * 
 * @return 
 */
_command int vi_visual_toggle_case() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY){
   if (!vi_visual_maybe_command()) {
      togglecase_selection();
      begin_select();
      deselect();
      if (_MultiCursorLastLoopIteration()) {
         vi_visual_toggle_off();
      }
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
_command int vi_visual_begin_select() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   if (!vi_visual_maybe_command()) {
      _begin_select('',false,true,2);
      return(0);
   }
   return(0);
}

/**
 * Exit visual mode to command mode.
 * 
 * @return 
 */
void vi_visual_toggle_off(int showmsg=1,bool keep_recording=false) {
   if (vi_get_vi_mode() == 'V') {
      vi_switch_mode('V',showmsg,'',false,keep_recording);
   }
}
void _vi_visual_select(_str type='',_str extendAsCursorMoves='C',_str persistant='P') {
   if (type=='') {
      type=_select_type();
   }
   // Set _cua_select=1. That way, if the the user creates a 
   // mouse selection, the current selection is deselected. Want 'P' so that when
   // user presses Ctrl+End, selection is extended.
   _cua_select=1;
   if (type=='CHAR') {
      _select_char('',extendAsCursorMoves'I'persistant);
   } else if (type=='LINE') {
      _select_line('',extendAsCursorMoves:+persistant);
   } else if (type=='BLOCK') {
      _select_block('',extendAsCursorMoves'I':+persistant);
      if (!def_inclusive_block_sel) {
         _select_type('','I',0);
      }
   }
}

/**
 * This command handles selecting a character, line, or block
 * depending on the current visual mode.
 */
_command void vi_visual_select(_str type='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY){
   _vi_visual_select(type);
}

bool _vi_visual_auto_deselect() {
   if (vi_get_vi_mode()=='V' && _vi_auto_deselect_vmode && def_persistent_select!='Y') {
      _deselect();
      vi_visual_toggle_off();
      return true;
   }
   return false;
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
   if (_vi_visual_auto_deselect()) {
      ex_search_mode(arg(1));
      return 0;
   }


   int mark;
   save_selection(mark);
   ex_search_mode(arg(1));
   restore_selection(mark);
   vi_visual_select();
   _save_pos2(auto p);
   save_selection(auto mark2);
   _end_select();
   restore_selection(mark2);
   _restore_pos2(p);
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
   int mark;
   save_selection(mark);
   ex_reverse_search_mode(arg(1));
   restore_selection(mark);
   vi_visual_select();
   return(0);
}

/**
 * By default this command handles the '>' pressed while in 
 * visual mode. 
 * 
 * @return int
 */
_command int vi_visual_shift_right() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY) {
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
_command int vi_visual_shift_left() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY) {
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
_command int vi_visual_next_word(int count = 1, int select_end = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_prev_word(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_next_word2(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_prev_word2(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_end_word(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_end_word2(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_prev_paragraph(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_next_paragraph(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_prev_sentence(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
_command int vi_visual_next_sentence(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
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
   bb:=_select_type('','P');
   if (substr(bb,1,1)=='E') {
      dir='-';
      return;
   }
   if (_begin_select_compare()==0 && _end_select_compare()==0 && substr(bb,2,1)=='E') {
      dir='-';
   } else {
      dir='+';
   }
}

/**
 * This command handles the 'a' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_a_cmd(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   int status;
   static _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }

   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key=vi_get_event();
   }

   _str dir;
   vi_visual_get_sel_dir(dir);

   typeless p = 0;
   typeless p1 = 0;
   auto type=_select_type();
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
      vi_visual_select(type);
      restore_pos(p1);
      vi_visual_select(type);
   }

   return(0);
}

/**
 * This command handles the 'I' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_insert_mode() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   if( command_state() ) {
      vi_visual_maybe_command();
      return 0;
   }
   if (vi_get_vi_mode()!='V') {
      return -1;
   }
   if (_select_type()=='BLOCK') {
      // Switch into insert mode WITHOUT starting a new keyboard macro
      
      /*Reduce this column selection to width one so that non-modal 
        block insert mode doesn't delete characters in the selection first.
      */
      int columnStartPixel,columnEndPixel;
      _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel);
      orig_mark:=_duplicate_selection('');
      mark:=_alloc_selection();
      _get_selinfo(auto first_col,auto end_col,auto junk_buf_id);
      _end_select();
      if (p_fixed_font) {
         p_col=first_col;
      } else {
         p_col=_ColFromTextWidth(columnStartPixel);
      }
      _select_block(mark,'CIP');
      if (!def_inclusive_block_sel) _select_type(mark,'I',0);
      _begin_select();
      if (p_fixed_font) {
         p_col=first_col;
      } else {
         p_col=_ColFromTextWidth(columnStartPixel);
      }
      _select_block(mark,'CIP');
      _deselect();
      _vi_mode='C';  // Lie about what the current mode is.
      vi_switch_mode('I');
      _show_selection(mark);
      _free_selection(orig_mark);
      return 0;
   }
   // Switch out of visual mode and turn off recording
   _begin_select();_begin_line();
   vi_switch_mode('V',0);
   // Starting a new keyboard recording here
   last_event('i');
   last_idx := find_index('vi-insert-mode', COMMAND_TYPE);
   last_index(last_idx);
   last_index(last_idx,'C');
   vi_insert_mode();
   return 0;
}
/**
 * This command handles the 'i' character pressed in visual 
 * mode. 
 * 
 * @return int
 */
_command int vi_visual_i_cmd(int count = 1) name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL|VSARG2_LASTKEY|VSARG2_READ_ONLY) {
   int status;
   static _str key;
   if ( vi_visual_maybe_command() ) {
      return(0);
   }

   // Start/initialize the list of events used when playing back
   // recorded macros.
   vi_get_event('S');

   /*
   Use 'I' and not 'i' for block mode inserting to more accurrately emulate
   gvim.
   if (_select_type()=='BLOCK') {
      block_insert_mode();
      vi_toggle_block_visual();
      return(0);
   } 
   */

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      key=vi_get_event();
   }

   _str dir;
   vi_visual_get_sel_dir(dir);

   typeless p = 0;
   typeless p1 = 0;
   auto type=_select_type();
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
      //Vim seems to force CHAR selection when matching parens
      type='CHAR';

      // Move back to the original paren
      //save_pos(auto p3);
      restore_pos(p);
      n:=_nrseek();
      restore_pos(p1);
      n2:=_nrseek();
      if (n2<n) {
         p2:=p;
         p=p1;
         p1=p2;
      }
      restore_pos(p);
      // Move off the paren
      right();
      // If we are at the end of the line, the selection should start on the next
      // line down because the paren shouldn't be included in the selection
      if (at_end_of_line()) {
         down();
         begin_line();
      }
      vi_visual_select(type);
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
   cur_col := p_col;
   vi_visual_select_right();
   if (p_col == cur_col) {
      down();
      _first_non_blank();
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
         on_begin_sentence := false;
         // if we jumped back to a different sentence, we were on the start of a sentence 
         if (p_line < sl || (sl == p_line && p_col < startCol)) on_begin_sentence = true;
         restore_pos(p);
         if (on_begin_sentence) vi_visual_move_right_or_down(); 
         auto type=_select_type();
         deselect();
         prev_sentence();
         vi_visual_select(type);
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
         on_begin_paragraph := false;
         // if we jumped back to a different paragraph, we were on the start of a paragraph
         if (p_line < sl || (sl == p_line && p_col < startCol)) on_begin_paragraph = true;
         restore_pos(p);
         if (on_begin_paragraph) vi_visual_move_right_or_down(); 
         auto type=_select_type();
         deselect();
         prev_paragraph();
         vi_visual_select(type);
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
      _str type=_select_type();
      if (size == 1) {
         deselect();
         p_col = sc;
         vi_visual_select(type);
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
void vi_visual_finish_i_cmd(typeless &p,typeless &p1,bool stay_on_paren=false){
   deselect();
   save_pos(p);
   orig_line := p_line;
   // Can't find a match? Bail. 
   int status = find_matching_paren();
   if (status != 0) {
      return;
   }
   column := p_col;
   save_pos(auto ptemp);
   _first_non_blank();
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
