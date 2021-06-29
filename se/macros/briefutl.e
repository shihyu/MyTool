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
#import "complete.e"
#import "cua.e"
#import "files.e"
#import "hex.e"
#import "main.e"
#import "markfilt.e"
#import "put.e"
#import "seldisp.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "window.e"
#import "clipbd.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#endregion

/**
 * If on, saves and restores the cursor position before
 * pasting text in Brief emulation.
 * 
 * @default 0
 * @categories Configuration_Variables
 * 
 * @see brief_paste
 */
int def_brief_paste_restore = 0;

_str s_match(_str name,bool find_first)
{
   name=f_match(name,find_first);
   for (;;) {
      if ( name=='' ) {
         return('');
      }
      if ( _file_eq('.'_get_extension(name),_macro_ext) ) {
         break;
      }
      name=f_match(name,false);
   }
   return(name);

}

/** 
 * If no selection exists in the current buffer, the character under the cursor is 
 * deleted.  The next line is joined with the current line when the cursor is past 
 * the end of the current line.
 * <p>
 * If the current buffer has a selection, the selected text is deleted.  No clipboard is created.  
 * The deleted text may only be retrieved with the undo command.
 * 
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * 
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command brief_delete() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      return(linewrap_delete_char());
   }
   if ( _select_type()!='' ) {
      first_col := 0;
      last_col := 0;
      buf_id := 0;
      _get_selinfo(first_col,last_col,buf_id);
      if ( buf_id==p_buf_id ) {
         return(delete_selection());
      }
   }
   linewrap_delete_char();

}

/** 
 * Inserts the clipboard at the cursor.  The text inserted is not highlighted.  
 * LINE type clipboards are inserted before or after the current line depending 
 * upon the Line insert style.
 * By default, they are inserted before the cursor.  By default, BLOCK type clipboards are inserted 
 * even when the cursor is in replace mode.  If you want BLOCK type clipboards to overwrite the
 * destination text when your cursor is in replace mode,  invoke the command "set-var def-modal-paste 1".  
 * Works on command line or text line.
 * 
 * @return  Returns 0 if successful.  Common return codes are 1 (Clipboard empty, or 
 * clipboard text too long for command line) TOO_MANY_MARKS_RC.
 * 
 * @see list_clipboards
 * @see copy_to_clipboard
 * @see copy_word
 * @see cut_end_line
 * @see cut_line
 * @see cut
 * @see cut_word
 * @see cut_prev_word
 * @see paste
 * 
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * 
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command brief_paste(_str name='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_CLIPBOARD)
{
   if (command_state()) {
      return paste(name);
   }
   int mark=_duplicate_selection();
   if ( mark<0 ) {
      return(mark);
   }
   int old_mark=_duplicate_selection('');
   _show_selection(mark);
   unmark_paste := def_deselect_paste;
   int orig_paste_block_cursor_end=def_paste_block_cursor_end;
   def_paste_block_cursor_end=1;
   def_deselect_paste=false;
   last_index(find_index("brief_paste",COMMAND_TYPE));
   typeless p;
   if (def_brief_paste_restore) {
      _save_pos2(p);
   }
   cursor_x := -1;
   left_edge := -1;
   if ( p_object==OI_EDITOR ) {
      cursor_x=p_cursor_x;
      left_edge=p_left_edge;
   }
   col := 0;
   int status=paste(name);
   def_deselect_paste=unmark_paste;
   def_paste_block_cursor_end=orig_paste_block_cursor_end;
   if ( ! status ) {
      if ( ! command_state() ) {
         if(!(_process_info('b') && p_line==p_Noflines) ) {
            if ( _select_type()=='LINE') {
               if ( down() ) {
                  if (p_fixed_font) {
                     col=p_col;
                     insert_line('');
                     p_col=col;
                  }
               } 
               if (!p_fixed_font && p_object==OI_EDITOR) {
                  set_scroll_pos(left_edge,p_cursor_y);
                  p_cursor_x=cursor_x;
               }
            }
         }
      }
      if (def_brief_paste_restore) {
         _restore_pos2(p);
      }
   }
   if ( def_deselect_paste ) {
      new_asel:=_duplicate_selection();
      _show_selection(old_mark);
      _free_selection(new_asel);
      if ( def_persistent_select=='D' ) {
         _deselect();
      }
   } else {
      _free_selection(old_mark);
   }
   return(status);

}
_command brief_tab() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      maybe_list_matches('','',true);
      return(0);
   }
   if ( select_active() && _within_char_selection()) {
      indent_selection();
      return(0);
   }
   if ( _insert_state() ) {
      move_text_tab();
   } else {
      init_command_op();
      ptab();
      retrieve_command_results();
   }

}
static int ghomeend_count[];
static int gmulticursor_index;

/**
 * For a text box or combo box, the cursor is placed in column 1 of the text box.
 * <p>
 * Edit Window and Editor Control:  Pressing the HOME key once moves the cursor to column one. 
 * Pressing the HOME key again moves the cursor to the top of the window.  Pressing the HOME key 
 * again moves the cursor to the top of the buffer.  This command may only be bound to the HOME key.
 * 
 * @see brief_end
 * 
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * 
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command brief_home() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      return(begin_line());
   }
   index := last_index('','C');
   prev := prev_index('','C');
   _str last_name = name_name(prev_index('','C'));
   _str first = last_name!='brief-home' /*&& last_name!='process-begin-line'*/;

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      gmulticursor_index=0;
      if (first) ghomeend_count._makeempty();
   } else if (_MultiCursorAlreadyLooping()) {
      ++gmulticursor_index;
   }

   if (first || ghomeend_count[gmulticursor_index]._varformat()==VF_EMPTY || ghomeend_count[gmulticursor_index]>=3) {
      ghomeend_count[gmulticursor_index]=0;
   }
   ++ghomeend_count[gmulticursor_index];
   _macro_delete_line();
   switch (ghomeend_count[gmulticursor_index]) {
   case 1:
      _macro_call('begin_line');
      begin_line();
      break;
   case 2:
      _macro_call('top_of_window');
      top_of_window();
      break;
   case 3:
      _macro_call('top_of_buffer');
      top_of_buffer();
      break;
   }
   last_index(index,'C');
   prev_index(prev,'C');
}

/**
 * For a text box or combo box, the cursor is placed after the last character in the text box.
 * <p>
 * Edit Window and Editor Control:  Pressing the END key once moves the cursor to the end of the current line.  
 * Pressing the END key again moves the cursor to the bottom of the window.  Pressing the END key again moves 
 * the cursor to the bottom of the buffer.  This command may only be bound to the END key.
 * 
 * @see brief_home
 * 
 * 
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 * 
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command brief_end() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
{
   if ( command_state() ) {
      return(end_line());
   }
   index := last_index('','C');
   prev := prev_index('','C');
   _str first=name_name(prev_index('','C'))!='brief-end';

   if (!_MultiCursorAlreadyLooping() || _MultiCursorFirstLoopIteration()) {
      gmulticursor_index=0;
      if (first) ghomeend_count._makeempty();
   } else if (_MultiCursorAlreadyLooping()) {
      ++gmulticursor_index;
   }
   if (first || ghomeend_count[gmulticursor_index]._varformat()==VF_EMPTY || ghomeend_count[gmulticursor_index]>=3) {
      ghomeend_count[gmulticursor_index]=0;
   }
   ++ghomeend_count[gmulticursor_index];
   _macro_delete_line();
   switch (ghomeend_count[gmulticursor_index]) {
   case 1:
      _macro_call('end_line');
      end_line();
      break;
   case 2:
      _macro_append('bottom_of_window();_end_line();');
      bottom_of_window();_end_line();
      break;
   case 3:
      _macro_call('bottom_of_buffer');
      bottom_of_buffer();
      break;
   }
   last_index(index,'C');
   prev_index(prev,'C');
}
/**
 * Saves all modified buffers and exits the editor.
 * 
 * @return Returns 0 if successful.  Common return values are 1 (must exit 
 * build window) COMMAND_CANCELLED_RC, 
 * ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, 
 * INSUFFICIENT_DISK_SPACE_RC, 
 * ERROR_CREATING_DIRECTORY_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, 
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC.  On 
 * error, message is displayed.
 * 
 * @see gui_save_as
 * @see save
 * @see name
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */ 
_command save_exit()
{
   int status=save_all();
   if ( status ) {
      return(status);
   }
   return(safe_exit());

}
static _str deselect_or_switch(_str type, _str alt_type='')
{
   _cua_select=0;
   if ( _select_type()=='' ) {
      return(0);
   }
   col := p_col;
   start_col := 0;
   end_col := 0;
   buf_id := 0;
   _get_selinfo(start_col,end_col,buf_id);
   if ( buf_id!=p_buf_id ) {
      _deselect();return(0);
   }
   if ( _select_type()==type && (alt_type=='' || _select_type('','I')==alt_type) ) {
      _deselect();return(1);
   }
#if 0  
    // SlickEdit now has support for inclusive and non-inclusve BLOCK selections.
    // Could pick one based on whether CHAR selection is inclusive.
    // This would deviate from how Brief works.
    if (!_select_type('','I') && _select_type()=='CHAR') {
        _select_type('','T',type);
        _select_type('','I',0);
    } else {
        if (!def_inclusive_block_sel) {
           _select_type('','I',0);
        }
    }
#else
   _select_type("",'T',type);
   if (!def_inclusive_block_sel) {
      _select_type('','I',0);
   }
#endif
   return(0);
}
static _str _brief_mstyle()
{
   if ( pos('C',def_select_style,1,'I') ) {
      return('C':+def_advanced_select);
   } else {
      return('E':+def_advanced_select);
   }

}

/**
 * Starts or deselects a non-inclusive character selection.  Used for processing 
 * sentences of text which do not start and end on line boundaries.  If no selection 
 * is active a non-inclusive character selection is started.  if a non-inclusive 
 * character selection is already active, it is unmarked.  If a different select 
 * style than non-inclusive character selection is active, the select style is 
 * switched to a non-inclusive character selection.
 * 
 * @see brief_iselect_char
 * @see brief_select_line
 * @see brief_select_block
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command brief_select_char() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( deselect_or_switch('CHAR','0') ) { return(0); }
   _select_char('',_brief_mstyle()'N');

}

/**
 * Starts or deselects an inclusive character selection.  Used for processing sentences 
 * of text which do not start and end on line boundaries.  If no selection is active an 
 * inclusive character selection is started.  if an inclusive character selection is 
 * already active, it is unmarked.  If a different select style than inclusive character 
 * selection is active, the select style is switched to an inclusive character selection.
 * 
 * @see brief_select_char
 * @see brief_select_line
 * @see brief_select_block
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command brief_iselect_char() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( deselect_or_switch('CHAR','1') ) { return(0); }
   _select_char('',_brief_mstyle()'I');

}

/**
 * Starts or deselects a block selection.  Used for processing columns of text.  
 * If no selection is active a block selection is started.  if a block selection 
 * is already active, it is unmarked.  If a different select style than a block 
 * selection is active, the select style is switched to a block selection.
 * 
 * @see brief_select_char
 * @see brief_select_line
 * @see brief_iselect_char
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command brief_select_block() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
#if !MULTI_CURSOR_SUPPORTS_BLOCK_MARK
   if (_MultiCursor()) {
      _MultiCursorClearAll();
      deselect();
   }
#endif
   if ( deselect_or_switch('BLOCK') ) { return(0); }
   old_sel:=_select_type();
   _select_block('',_brief_mstyle());
   if (old_sel=='') {
      if (!def_inclusive_block_sel) {
         _select_type('','I',0);
      }
   }

}

/**
 * Starts or deselects a line selection.  Used for processing complete lines of text. 
 * If no selection is active a line selection is started.  if a line selection is already 
 * active, it is unmarked.  If a different select style than a line selection is active, 
 * the select style is switched to a line selection.
 * 
 * @see brief_select_char
 * @see brief_select_line
 * @see brief_select_block
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command brief_select_line() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if ( deselect_or_switch('LINE') ) { return(0); }
   _select_line('',_brief_mstyle());

}
/**
 * Moves the cursor to the right side of the window.
 * 
 * @see left_side_of_window
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command right_side_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless old_scroll=_scroll_style();
   _scroll_style('S 0');
   orig_left_edge := p_left_edge;
   p_cursor_x=p_client_width-1;
   while (p_left_edge!=orig_left_edge) {
      --p_col;
      set_scroll_pos(orig_left_edge,p_cursor_y);
   }
   _scroll_style(old_scroll);
}
/** 
 * Moves the cursor to the left side of the window.
 * 
 * @see right_side_of_window
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command left_side_of_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   p_cursor_x=0;
}
// When quiting a file in BRIEF, the next file becomes active
_command void brief_quit() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (def_one_file!='') {
      orig_wid := p_window_id;
      next_buffer();
      next_wid := p_window_id;
      p_window_id=orig_wid;
      quit(true);
      if (p_window_id!=orig_wid && next_wid!=orig_wid) p_window_id=next_wid;
      return;
   }
   int orig_buf_id=p_buf_id;
   next_buffer();
   int next_buf_id=p_buf_id;
   p_buf_id=orig_buf_id;
   quit(true);
   if (p_buf_id!=orig_buf_id && next_buf_id!=orig_buf_id) p_buf_id=next_buf_id;
}

/**
 * Same as save command except that if the current buffer has a selection, 
 * the selection is written to a file you choose.  Another difference, is 
 * that the <b>brief_save</b> command does not save the file if it is not modified.
 * 
 * 
 * @appliesTo  Edit_Window
 * 
 * @categories Editor_Control_Methods
 */
_command brief_save() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _select_type()!='' ) {
      first_col := 0;
      last_col := 0;
      buf_id := 0;
      _get_selinfo(first_col,last_col,buf_id);
      if ( buf_id==p_buf_id ) {
         return(gui_write_selection());
#if 0
         _macro_delete_line();
         status=0;
         line=arg(1);
         if (line=='') {
            status=get_string(line,nls('Write mark:')' ','-.put');
            if ( status ) {
               return(COMMAND_CANCELLED_RC);
            }
         }
         _macro_call('put',line);
         status=put(line,PAUSE_COMMAND);
         if ( ! status ) {
            _deselect();
         }
         return(status);
#endif
      }
   }
   if ( ! p_modify ) {
       message(nls('File not modified.  Nothing saved.'));
       return(1);
   }
   return(save());
}
_command void keyin_brace() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   keyin("{");
}

_command void codewright_abort() name_info(','VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      _cmdline.set_command('',1,1);
   }
   if ( command_state() && ! def_stay_on_cmdline ) {
      command_toggle();
      return;
   }

   // Whole-saled from cmdline_toggle() to handle hitting Ctrl+g to dismiss
   // a dialog.
   mdi_with_cmdline := false;
   if ( p_active_form.p_isToolWindow ) {
      mdi_with_cmdline = _MDIWindowHasMDIArea(p_active_form);
   }
   if ( ((!p_mdi_child && !p_active_form.p_isToolWindow)
         || (!p_mdi_child && !mdi_with_cmdline))
        && p_object == OI_EDITOR && p_active_form.p_object == OI_FORM ) {

      ToolWindowInfo* twinfo = tw_find_info(p_active_form.p_name);
      if (last_event() :== ESC && twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
         tw_dismiss(p_active_form);
      } else {
         if ( last_event() :== ESC || last_event() :== A_F4 ) {
            call_event(defeventtab _ainh_dlg_manager, last_event(), 'e');
         }
      }
      return;
   }
   if (_MultiCursor()) {
      _MultiCursorClearAll();
      _deselect();
   }
   if ( select_active2() ) {
      _deselect();
      return;
   }
   if (p_hex_mode) {
      hex_off();
   }
   if (p_Nofhidden) {
      show_all();
   }
}
