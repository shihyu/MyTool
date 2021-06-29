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
#include "vsevents.sh"
#include "eclipse.sh"
#include "mfundo.sh"
#include "markers.sh"
#import "adaptiveformatting.e"
#import "backtag.e"
#import "bind.e"
#import "cfg.e"
#import "clipbd.e"
#import "codehelp.e"
#import "complete.e"
#import "config.e"
#import "context.e"
#import "cua.e"
#import "diff.e"
#import "dir.e"
#import "emacs.e"
#import "fileman.e"
#import "files.e"
#import "filetypemanager.e"
#import "listbox.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "options.e"
#import "optionsxml.e"
#import "project.e"
#import "put.e"
#import "recmacro.e"
#import "savecfg.e"
#import "projutil.e"
#import "saveload.e"
#import "search.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "vi.e"
#import "vlstobjs.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

bool def_do_block_mode_key=true;
bool def_do_block_mode_delete=true;
bool def_do_block_mode_backspace=true;
bool def_do_block_mode_del_key=true;

/**
 * Scrolls the text page one line down.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void scroll_up() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   //This scrolls up, and keeps the cursor at the current line.  Will start moving
   //the cursor when it would otherwise not be on the screen.

   if (line0visible()) {
      return;  //Already scrolled to the top
   }
   _str old_scroll=_scroll_style();
   _scroll_style('S 0');
   cursor_y := p_cursor_y;
   left_edge := p_left_edge;
   int old_updown_col=def_updown_col;def_updown_col=0;
   cursor_up();
   def_updown_col=old_updown_col;
   set_scroll_pos(left_edge,cursor_y);

   bottom_of_window();
   bottom_cursor_y := p_cursor_y;
   p_cursor_y=cursor_y;
   if (p_cursor_y!=bottom_cursor_y) {
      cursor_down();
   }
   _scroll_style(old_scroll);
   _set_scroll_optimization(-1);
}

/**
 * Scrolls the text page one line up.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void scroll_down() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   last_line := (p_line==p_Noflines);
   _str old_scroll=_scroll_style();
   _scroll_style('S 0');
   cursor_y := p_cursor_y;
   left_edge := p_left_edge;
   last := last_index('','C');
   int old_updown_col=def_updown_col;def_updown_col=0;
   cursor_down();
   def_updown_col=old_updown_col;
   last_index(last,'C');
   if ( rc==BOTTOM_OF_FILE_RC ) {
      cursor_y--;
   }
   set_scroll_pos(left_edge,cursor_y);
   top_of_window();
   top_cursor_y := p_cursor_y;
   p_cursor_y=cursor_y;
   if (p_cursor_y!=top_cursor_y) {
      cursor_up();
   }
   if (last_line) {
      cursor_down();
   }
   _scroll_style(old_scroll);
   _set_scroll_optimization(1);
}

static bool line0visible()
{
   save_pos(auto p);
   p_cursor_y=0;
   if (_default_option('T')) {
      //There is a TOF line;
      if (p_line<1) {
         restore_pos(p);
         return(true);
      }
   } else {
      if (p_line==1) {
         restore_pos(p);
         return(true);
      }
   }
   restore_pos(p);
   return(false);
}
/**
 * Scrolls the text page one column to right.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void scroll_left() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str old_scroll=_scroll_style();
   _scroll_style('S 0');
   if ( p_left_edge>0 ) {
      old_left_edge := p_left_edge;
      old_cursor_x := p_cursor_x;
      p_cursor_x=p_windent_x;
      if (p_left_edge==old_left_edge) {
         p_col--;
         _refresh_scroll2('s');
      }
      p_cursor_x=old_cursor_x;
   } else {
      left();
   }
   _scroll_style(old_scroll);
}
_refresh_scroll2(_str style)
{
   _str old_style=_scroll_style();
   _scroll_style(style);
   _refresh_scroll();
   _scroll_style(old_style);
}
/**
 * Scrolls the text page one column to left.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void scroll_right() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (p_SoftWrap) {
      right();
      return;
   }

   _str old_scroll=_scroll_style();
   _scroll_style('S 0');
   old_left_edge := p_left_edge;
   old_cursor_x := p_cursor_x;
   int col=mou_col(p_client_width);
   if (p_fixed_font) {
      p_col=col-1;
      while (p_left_edge==old_left_edge) {
         p_col++;
      }
   } else {
      p_col=col;
      if (p_left_edge==old_left_edge) {
         p_col++;
         _refresh_scroll2('s');
      }
   }
   p_cursor_x=old_cursor_x;
   _scroll_style(old_scroll);
}

/**
 * Centers the current line in the middle of the active window.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void center_line() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
      if (_argument !='') {
         set_scroll_pos(p_left_edge,(p_client_height intdiv p_char_height)*_argument);
         _argument='';     //so argument won't call it again
      } else {
         set_scroll_pos(p_left_edge,p_client_height intdiv 2);
      }
}

_str _scroll_when(_str value = '')
{
   typeless style = '';
   typeless num = '';
   parse _scroll_style() with style num;
   if (value == '') {
      value = num;
   } else {
      if (num != value) {
         style :+= ' ' :+ value;
         scroll_style(style);
         _macro_call('scroll_style('style')');
      }
   }
   return value;
}

/**
 * Centers the current line in the middle of the active window.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
void center_region(int start_line, int end_line)
{
   // make sure that the line number ranges are valid
   if (end_line < start_line) {
      end_line = start_line;
   }

   // make sure region fits on screen
   int num_lines = end_line-p_RLine+1;
   if (num_lines >= p_char_height) {
      num_lines = p_char_height;
   }

   // calculate top lines
   int top_lines = (p_char_height - num_lines) intdiv 2;

   // expand region to include as much of start_line as possible
   int lines_before = p_line - start_line;
   if (lines_before < top_lines*2) {
      top_lines += (lines_before intdiv 2);
   }

   // make sure we leave some lines at top, like scrolling does
   int scroll_border = (int) _scroll_when();
   if (top_lines < scroll_border && scroll_border*2 < p_char_height) {
      top_lines = scroll_border;
   }

   set_scroll_pos(p_left_edge,(p_client_height intdiv p_char_height)*top_lines);
}

/**
 * <p>Sorts the current buffer in ascending or descending order in case
 * sensitivity specified.  Sort defaults to ascending and case sensitive.</p>
 *
 * <p>Multiple options having the following meaning may be specified:</p>
 *
 * <dl>
 * <dt>A</dt><dd>Sort in ascending order.</dd>
 * <dt>D</dt><dd>Sort in descending order.</dd>
 * <dt>I</dt><dd>Case insensitive sort (Ignore case).</dd>
 * <dt>E</dt><dd>Case sensitive sort (Exact case).</dd>
 * <dt>-N</dt><dd>Sort numbers</dd>
 * <dt>-FN</dt><dd>Sort filenames by name part only</dd>
 * <dt>-FC</dt><dd>Sort filenames as strings using file case sensitivity</dd>
 * <dt>-F</dt><dd>Sort filenames.  Sorts by path part then by name. 
 *                This way all the files in a directory are next to each other,
 *                instead of being mixed in with sub-directories.</dd>
 * </dl>
 *
 * <p>Additional options specific to ISPF emulation are also supported by
 * this command.  Refer to ispf_sort for more information about sorting
 * on fields.</p>
 *
 * <p>Command line examples:</p>
 *
 * <dl>
 * <dt>sort-buffer</dt><dd>Sort in ascending order and exact
 * case.</dd>
 * <dt>sort-buffer I</dt><dd>Sort in ascending order and ignore
 * case.</dd>
 * <dt>sort-buffer DI</dt><dd>Sort in descending order and
 * ignore case.</dd>
 * <dt>sort-buffer -n d</dt><dd>Sort numbers in descending order</dd>
 * </dl>
 *
 * @return Returns 0 if successful.  Common return codes are 1 (you tried to sort
 * the build window), NOT_ENOUGH_MEMORY_RC,
 * TOO_MANY_SELECTIONS_RC, and
 * INVALID_SELECTION_HANDLE_RC.  On error, message
 * displayed.
 *
 * @param cmdline is a string in the format: [ A | D]    [ E | I ]    [ -N | -F | -FN | -FC ]
 *
 * @see sort_on_selection
 * @see sort_within_selection
 * @see gui_sort
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command int sort_buffer(_str cmdline='') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   if ( _process_info('B') ) {
      message(nls("You can't mean this"));
      return(1);
   }
   _str orig_cmdline=cmdline;
   // Check for X or NX options and for ISPF labels
   startLabel := endLabel := "";

   cmdline='';
   _str string=orig_cmdline;
   option := "";
   rest := "";
   for (;;) {
      parse string with option string;
      if (option=="") {
         break;
      }
      option=upcase(option);
      if (substr(option,1,1)=='.') {
         startLabel=option;
         parse string with option rest;
         if (substr(option,1,1)=='.') {
            endLabel=option;
            string=rest;
         } else {
            endLabel=startLabel;
         }
      } else {
         cmdline :+= ' 'option;
      }
   }
   typeless mark;
   status := 0;
   start_linenum := 0;
   end_linenum := 0;
   if (startLabel!='') {
      start_linenum=_LCFindLabel(startLabel);
      if (start_linenum<0) {
         return(1);
      }
      if (start_linenum==0) start_linenum=1;
      end_linenum=_LCFindLabel(endLabel);
      if (end_linenum<0) {
         return(1);
      }
      if (end_linenum==0) end_linenum=0;

      if (start_linenum>end_linenum){
         int temp=end_linenum;
         end_linenum=start_linenum;
         start_linenum=temp;
      }
      mark=_alloc_selection();
      p_line=end_linenum;_select_line(mark);
      goto_line(start_linenum);_select_line(mark);
      status=sort_on_selection(cmdline,mark);
      _free_selection(mark);
      return(status);
   }
   if (!p_Noflines) {
      return(0);
   }
   save_pos(auto p);
   mark=_alloc_selection();
   bottom();
   if(_line_length(true)==0) {
      up();
      // IF there are no lines to copy
      if (_on_line0()) {
         restore_pos(p);
         return(0);
      }
   }
   _select_line(mark);
   top();_select_line(mark);
   status=sort_on_selection(cmdline,mark);
   _free_selection(mark);
   return(status);
}
/**
 * <p>Sorts the marked text in ascending order comparing only the columns
 * specified.  If a character mark is used, it is converted to a line mark.</p>
 *
 * <p>Multiple options having the following meaning may be specified:</p>
 *
 * <dl>
 * <dt>A</dt><dd>Sort in ascending order.</dd>
 * <dt>D</dt><dd>Sort in descending order.</dd>
 * <dt>I</dt><dd>Case insensitive sort (Ignore case).</dd>
 * <dt>E</dt><dd>Case sensitive sort (Exact case).</dd>
 * <dt>-N</dt><dd>Sort numbers</dd>
 * <dt>-FN</dt><dd>Sort filenames by name part only</dd>
 * <dt>-FC</dt><dd>Sort filenames as strings using file case sensitivity</dd>
 * <dt>-F</dt><dd>Sort filenames.  Sorts by path part then by name. 
 *                This way all the files in a directory are next to each other,
 *                instead of being mixed in with sub-directories.</dd>
 * </dl>
 *
 * <p>Command line examples:</p>
 *
 * <dl>
 * <dt>sort-on-selection</dt><dd>Sort in ascending order and exact
 * case.</dd>
 * <dt>sort-on-selection I</dt><dd>Sort in ascending order and ignore
 * case.</dd>
 * <dt>sort-on-selection DI</dt><dd>Sort in descending order and
 * ignore case.</dd>
 * <dt>sort-on-selection -n d</dt><dd>Sort numbers in descending order</dd>
 * </dl>
 *
 * @return Returns 0 if successful.  Common return codes are
 * INVALID_OPTION_RC,
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC,
 * NOT_ENOUGH_MEMORY_RC, TOO_MANY_SELECTIONS_RC,
 * and INVALID_SELECTION_HANDLE_RC.  On error, message
 * displayed.
 *
 * @param cmdline is a string in the format: [ A | D]   [ E | I ]    [ -N | -F | -FN | -FC ]
 *
 * @see sort_buffer
 * @see sort_within_selection
 * @see gui_sort
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
_command int sort_on_selection(_str cmdline='',_str markid='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_BLOCK_SELECTION|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   hiddenOption := "";
   _str string=cmdline;
   option := "";
   for (;;) {
      parse string with option string;
      if (option=="") {
         break;
      }
      option=upcase(option);
      if (option=='X' || option=='NX') {
         hiddenOption=option;
      }
   }

   typeless was_in_current_buffer=select_active(markid);
   int Noflines=_sort_selection(cmdline,markid);
   if ( Noflines<0 ) {
      return(Noflines);
   }
   if (!was_in_current_buffer) {
      return(0);
   }
   if ( _select_type(markid)=='BLOCK' ) {
      typeless markid2=_alloc_selection();
      if ( markid2<0 ) return(markid2);
      //updown_col=]=p_col;
      _begin_select();
      cursor_x:=p_cursor_x;
      left_edge:=p_left_edge;
      _select_line(markid2);_end_select();_select_line(markid2);
      _delete_selection(markid2);
      _free_selection(markid2);
      if (!p_IsTempEditor && !p_fixed_font) {
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
      }
      return(0);
   }
   if (_select_type(markid)=='CHAR') {
      _select_type(markid,'t','line');
   }
   typeless p;
   if (hiddenOption!='') {
      save_pos(p);

      _end_select(markid);

      int sourceLineNum=p_line+1;
      typeless markid3=_alloc_selection();
      down();
      _select_line(markid3);
      p_line += Noflines-1;
      _select_line(markid3);

      _begin_select(markid);

      // Sort only hidden lines
      typeless markid2=_alloc_selection();
      if (hiddenOption=='X') {
         while (Noflines--) {
            // Look for a hidden line that does not have NOSAVE_LF
            //messageNwait('h1 l='p_line);
            while (!(_lineflags()& HIDDEN_LF) || (_lineflags() & NOSAVE_LF)) {
               down();
            }
            _select_line(markid2);
            int orig_Noflines=Noflines;
            for (;;) {
               if (!Noflines) {
                  _select_line(markid2);
                  break;
               }
               down();
               --Noflines;
               // Look for a line that is not hidden or has NOSAVE_LF
               if (!(_lineflags()& HIDDEN_LF) || (_lineflags() & NOSAVE_LF)) {
                  up();
                  _select_line(markid2);
                  ++Noflines;
                  break;
               }
            }
            //messageNwait('h2 l='p_line);
            int count=orig_Noflines-Noflines+1;
            _delete_selection(markid2);up();
            //messageNwait('l='p_line' sourceLN='sourceLineNum'c='count);
            _buf_transfer(p_buf_id,sourceLineNum-count,sourceLineNum-1);
            up(count);
            sourceLineNum+=count;
            while (count--) {
               down();
               _lineflags(HIDDEN_LF,HIDDEN_LF);
            }
            down();
         }
      } else if (hiddenOption=='NX') {
         while (Noflines--) {
            // Look for a non-hidden line that does not have NOSAVE_LF
            //messageNwait('h1 l='p_line);
            while ((_lineflags()& HIDDEN_LF) || (_lineflags() & NOSAVE_LF)) {
               down();
            }
            _select_line(markid2);
            int orig_Noflines=Noflines;
            for (;;) {
               if (!Noflines) {
                  _select_line(markid2);
                  break;
               }
               down();
               --Noflines;
               // Look for a line that is hidden or has NOSAVE_LF
               if ((_lineflags()& HIDDEN_LF) || (_lineflags() & NOSAVE_LF)) {
                  up();
                  _select_line(markid2);
                  ++Noflines;
                  break;
               }
            }
            //messageNwait('h2 l='p_line);
            int count=orig_Noflines-Noflines+1;
            _delete_selection(markid2);up();
            //messageNwait('l='p_line' sourceLN='sourceLineNum'c='count);
            _buf_transfer(p_buf_id,sourceLineNum-count,sourceLineNum-1);
            up(count);
            sourceLineNum+=count;
            down(count+1);
         }
      }
      _free_selection(markid2);
      _delete_selection(markid3);
      restore_pos(p);
      return(0);
   }
   _delete_selection(markid);
   return(0);
}
/**
 * <p>Sorts the text within the selection in ascending order.  If a character
 * selection is used, it is converted into a line type selection.</p>
 *
 * <p>Multiple options having the following meaning may be specified:</p>
 *
 * <dl>
 * <dt>A</dt><dd>Sort in ascending order.</dd>
 * <dt>D</dt><dd>Sort in descending order.</dd>
 * <dt>I</dt><dd>Case insensitive sort (Ignore case).</dd>
 * <dt>E</dt><dd>Case sensitive sort (Exact case).</dd>
 * <dt>U</dt><dd>Remove duplicate lines.</dd>
 * <dt>-N</dt><dd>Sort numbers</dd>
 * <dt>-FN</dt><dd>Sort filenames by name part only</dd>
 * <dt>-FC</dt><dd>Sort filenames as strings using file case sensitivity</dd>
 * <dt>-F</dt><dd>Sort filenames.  Sorts by path part then by name. 
 *                This way all the files in a directory are next to each other,
 *                instead of being mixed in with sub-directories.</dd>
 * </dl>
 *
 * <p>Command line examples:</p>
 *
 * <dl>
 * <dt>sort-within-selection</dt><dd>Sort in ascending order and exact
 * case.</dd>
 * <dt>sort-within-selection I</dt><dd>Sort in ascending order and ignore
 * case.</dd>
 * <dt>sort-within-selection DI</dt><dd>Sort in descending order and
 * ignore case.</dd>
 * <dt>sort-within-selection -n d</dt><dd>Sort numbers in descending order</dd>
 * </dl>
 *
 * @return Returns 0 if successful.  Common return codes are
 * INVALID_OPTION_RC,
 * LINE_OR_BLOCK_SELECTION_REQUIRED_RC,
 * NOT_ENOUGH_MEMORY_RC, TOO_MANY_SELECTIONS_RC,
 * and INVALID_SELECTION_HANDLE_RC.  On error, message
 * displayed.
 *
 * @param cmdline is a string in the format: [ A | D]   [ E | I ]  [U]  [ -N | -F | -FN | -FC ]
 *
 * @see sort_buffer
 * @see sort_on_selection
 * @see gui_sort
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Selection_Functions
 *
 */
_command sort_within_selection(_str cmdline='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _select_type()!='BLOCK' ) {
      return(sort_on_selection(cmdline));    /* Handle char mark,line mark, or null mark */
   }
   status := 0;
   first_col := last_col := 0;
   typeless junk,utf8,encoding;
   _get_selinfo(first_col,last_col,junk,'',junk,utf8,encoding);
   if (p_TruncateLength && last_col>_TruncateLengthC()) {
      status=VSRC_SELECTION_NOT_VALID_FOR_OPERATION;
      message(get_message(status));
      return(status);
   }
   int mark=_alloc_selection();
   if ( mark<0 ) return(mark);

   /* This new code for handling proportional font block selections
      will mess up sorts that specify columns. The columns
      must be relative to the beginning of the block selection.
   */
   int mark2=_duplicate_selection();
   typeless(p);

   _save_pos2(p);
   int view_id;
   get_window_id(view_id);
   int temp_view_id;
   view_id=_create_temp_view(temp_view_id);
   p_encoding=encoding;
   insert_line('');
   _copy_to_cursor(mark2);
   _free_selection(mark2);
   top();_select_line(mark);
   bottom();_select_line(mark);
   linenum := p_Noflines;
   status=_sort_selection(cmdline,mark);
   if ( status<0 ) {
      /* Quit temp file and copy of user position. */
      _delete_temp_view(temp_view_id);
      activate_window(view_id);
      _restore_pos2(p);
      _free_selection(mark);
      message(get_message(status));
      return(status);
   }
   p_line=linenum;
   _deselect(mark);
   _select_line(mark);top();_select_line(mark);
   _delete_selection(mark);
   top();_select_block(mark);
   bottom();p_col=1;_select_block(mark);
   activate_window(view_id);_begin_select();
   // So we know more precisely what to overlay at the dest for a proportional
   // font overlay, specify the overlay mark.
   status=_overlay_block_selection(mark,VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE,'' /*overlay markid*/ );

#if 0
   status=_sort_selection(cmdline);
   if ( status<0 ) {
      /* Quit temp file and copy of user position. */
      _delete_temp_view(temp_view_id);
      activate_window(view_id);
      _restore_pos2(p);
      _free_selection(mark);
      message(get_message(status));
      return(status);
   }
   top();p_col=first_col;_select_block(mark);bottom();p_col=last_col;_select_block(mark);
   activate_window(view_id);_begin_select();
   status=_overlay_block_selection(mark);
#endif
   _delete_temp_view(temp_view_id);
   activate_window(view_id);
   _restore_pos2(p);
   _free_selection(mark);
   if ( status ) {
      message(get_message(status));
   }
   return(status);

}

static _str enumerate_line_filter(_str string)
{
   return _dec2hex(p_line, 8, 8) :+ ':' :+ string;
}
static _str unenumerate_line_filter(_str string)
{
   return substr(string, 10);
}
/**
 * Reverses the order of the selected lines. 
 * If a character mark is used, it is converted to a line mark
 *
 * @return Returns 0 if successful.
 *
 * @see filter_selection
 * @see sort_on_selection
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Selection_Functions
 */
_command int reverse_line_selection(_str markid='') name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   begin_select(markid, true);
   start_line := p_line;
   end_select(markid);
   end_line := p_line;
   begin_select(markid, true);

   filter_selection(enumerate_line_filter);
   sort_on_selection('D');
   p_line = start_line;
   select_line();
   p_line = end_line;
   filter_selection(unenumerate_line_filter);
   return 0;
}

/**
 * Displays the ASCII code corresponding to the character given on the command
 * line.  If character is not specified, the character at the cursor position in
 * the buffer is used.
 *
 * @see chr
 * @categories String_Functions
 */
_command void asc(_str ch='')
{
   doUTF8 := _UTF8();
   if ( ch=='' ) {
     if (p_UTF8) {
        ch=get_text_raw(-1);
     } else {
        // Could get the dbcs character by passing -1.
        // Just get current byte for now.
        ch=get_text_raw(1);
     }
     doUTF8=p_UTF8;
  } else {
     parse ch with ch '=';
     if ( ch=='' ) ch='=';
     if ( length(ch)>1 && !_UTF8()) {
       message(nls('Character must be of length 1'));
       return;
     }
  }
  msg := "";
  if (doUTF8) {
     msg='asc 'ch'=U+'_dec2hex(_UTF8Asc(ch));
     msg=translate(msg,' ',_UTF8Chr(0));
  } else {
     if (_UTF8() && _asc(ch)>0x7f) {
        msg='asc '_MultiByteToUTF8(ch)'='_asc(ch);
     } else {
        msg='asc 'ch'='_asc(ch);
     }
     msg=translate(msg,' ',_chr(0));
  }
  //_cmdline.set_command(msg);_cmdline._set_focus();
  sticky_message(msg);
}

/**
 * Displays the ASCII character corresponding to <i>number</i> on the command line.
 * The <i>number</i> string argument may be any mathematical expression support by
 * the <b>math</b> command.
 *
 * @categories Miscellaneous_Functions
 */
_command void chr(_str number='')
{
  if ( number=='' ) {
    _message_box(nls('Specify an ascii code number'));
    return;
  }
  parse number with number '=';
  number=strip(number);
  if (upcase(substr(number,1,2))=='U+') {
     number='0x'substr(number,3);
  }  else if (upcase(substr(number,1,1)=='U')) {
     number='0x'substr(number,2);
  }
  typeless result;
  if ( eval_exp(result,number,10) ) {
     return;
  }
  msg := "";
  if (_UTF8()) {
     msg='chr 'number'='_UTF8Chr(result);
  } else {
     msg='chr 'number'='_chr(result);
  }
  command_put(msg);
  //message(msg);
}


/**
 * Executes the commands in a selection.
 *
 * Displays messages if commands are completed successfully or
 * unsuccessfully.
 *
 * @appliesTo  Edit_Window
 * @categories Selection_Functions
 */
_command execute_selection() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  typeless status;
  _str line;
  if ( _select_type()=='' ) {
     get_line(line);
     status=execute(line,'');
  } else {
     filter_init();
     for (;;) {
        _str string;
       status= filter_get_string(string);
       if ( status ) { status=0;break; }
       execute(string,"");
       if ( rc ) { status=rc;break; }
     }
     filter_restore_pos();
  }
  refresh();  /* Don't want message to go to shell window. */
              /* Refresh will close shell window and redraw editor screen. */
  if ( status ) {
    if ( status<0 && isinteger(status) ) {   /* return code internal ? */
      message(nls('Command returned error code %s',status)'. 'get_message(status));
    } else {
      message(nls('Command returned error code %s',status));
    }
  } else {
    message(nls('Command(s) executed successfully'));
  }
  return(status);
}
_command void resume()
{
   rc=1;_resume();

}


/**
 * Executes the key binding for the other case of the alphabetic key pressed.
 * Bind this command to multiple key sequence key bindings that end with an
 * alphabetic key.  For example, if Ctrl+X 'k' is bound to the <b>quit</b>
 * command and Ctrl+X 'K' is bound to the <b>case_indirect</b> command.
 * When Ctrl+X 'K' is pressed, the <b>quit</b> command is executed.
 * ALT KEYS ARE NOT CAPS LOCK SENSITIVE!  This command should not be invoked
 * from the command line.
 *
 * @return If key != '' translated key is returned.  Otherwise '' is returned.
 * @categories Keyboard_Functions
 */
_command case_indirect(_str key='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_EDITORCTL|VSARG2_CMDLINE)
{
   _macro_delete_line();
   _str orig_key=key;
   if ( key:=='' ) {
      key=last_event();
   }
   if ( isalpha(key) ) {
      if ( key>='a' && key<='z' ) {
         key=upcase(key);
      } else {
         key=lowcase(key);
      }
   } else {
      return('');
   }
   if ( orig_key :!= '' ) {
      return(key);
   }
   _macro('m',_macro());
   call_key(key,last_index('','p'));   /* Continue last key sequence */

}

/**
 * UNIX only.  Displays man page(s) a newly created edit buffer for man help
 * item specified.  We attempt to remove special text screen formatting
 * characters.  However, this filter may need to be changed for some UNIX
 * configurations.  Lets us know if our filter does not work on your system.  If
 * <i>ManHelpItem</i> is not given, a dialog box is displayed which allows you
 * to enter one.
 *
 * @return Returns 0 if successful.
 *
 * @categories Miscellaneous_Functions
 *
 */
_command man(_str param='') name_info(','VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   if ( param=='' ) {
      if (_isEditorCtl(false)) {
         param=cur_word(auto start_col);
      }
      if (param=='') {
         typeless result = show('-modal _textbox_form',
                       'Man',          // Form caption
                       TB_RETRIEVE_INIT,     //flags
                       '',             //use default textbox width
                       'man',          //Help item.
                       '',             //Buttons and captions
                       'man',          //Retieve Name
                       'Man Help Item:'
                       );
         if (result=='') {
            return(COMMAND_CANCELLED_RC);
         }
         param=_param1;
      }
   }
   _macro('m',_macro('s'));
   _macro_call('man',param);
   temp_file := _maybe_quote_filename(mktemp());
   message(nls('Searching man pages for %s',param));

   _str program_name;
   _str alternate_shell;
   if (_isUnix()) {
      program_name=file_match('-p /usr/bin/man',1);
      if ( program_name=='' ) {
         program_name=file_match('-p /usr/bin/help',1);
      }
      if ( program_name=='' ) {
         program_name=path_search('man','','P');
      }
      if ( program_name=='' ) {
         message(nls('Program "%s" not found','man'));
         return(1);
      }
      alternate_shell=file_match('-p /bin/sh',1);
      if ( alternate_shell=='' ) {
         alternate_shell=path_search('sh');
      }
   } else {
      // Probably Cygwin
      program_name=path_search('man','','P');
      if ( program_name=='' ) {
         message(nls('Program "%s" not found','man'));
         return(1);
      }
      alternate_shell='';
   }
   // DJB (06/01/2005) - redirect input from /dev/null
   // needed for rare cases where system man insists on paging
   // This problem was observed on SuSE 9.2
   _str line;
   if (_isUnix()) {
      line=program_name' 'param' </dev/null >'temp_file' 2>&1';
   } else {
      line=program_name' 'param' >'temp_file' 2>&1';
   }
   mou_hour_glass(true);
   int status=shell(line,'pq',alternate_shell);
   mou_hour_glass(false);
   // man return code is unreliable on some UNIX's like LINUX
   unreliable := _isLinux(); /*|| (machine()=='???')*/;
   if (!unreliable && status) {
      delete_file(temp_file);
      message(nls('man page for %s not found',param));
      return(status);
   }
   // Don't want temp file name add to file menu.
   orig_buf_id := 0;
   edit('+t');
   delete_line();
   status=get(temp_file);

   // Filter out garbage characters.  Might need to change this
   // for another OS
   top();search('?\8','@r','');

   top();search('\xe2\x94\x82','@r','|');

   top();search('\xe2\x88\x92','@r','-');

   top();search('\xe2\x88','@r','');
   top();search('\xe2\x80\x90','@r','');
   top();p_modify=false;

   docname('man page(s) for 'param);
   delete_file(temp_file);
   if (unreliable && p_Noflines<5) {
      if (p_mdi_child) {
         quit();
      } else {
         _delete_buffer();
         p_buf_id=orig_buf_id;
      }
      message(nls('man page for %s not found',param));
      return(1);
   }
   if ( status ) {
      message(nls('Unable to edit temp file')'. 'get_message(status));
      return(status);
   }
   clear_message();
   return(0);
}


/**
 * Creates the configuration directory if it does not already exist.  The
 * <b>_config_path</b> function is called to determine the configuration directory.
 *
 * @return  Returns 0 if successful.  On error, message box is displayed.
 *
 * @see restore_path
 * @see _config_path
 * @categories File_Functions
 */
_str _create_config_path()
{
   _str local_dir=_ConfigPath();
   /* make sure the local directory is created. */
   if ( ! isdirectory(local_dir) ) {
      int status=make_path(local_dir,'0');  /* Give no shell messages options. */
      if ( status ) {  /* Error trying to create path. */
         _message_box(nls('Unable to create directory "%s"',local_dir)'.  'get_message(status));
         return(1);
      }
   }
   return(0);
/*
   Input filename should be in absolute form.

   This function returns non-zero value if the _config_path()
   should be used instead of the path of the filename given.
*/
}
_str _use_config_path(_str filename)
{
   _str path;
   if (_isUnix()) {
      /* Since UNIX user always have a HOME directory. */
      /* Must allow for null configuration directory. */
      if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ECLIPSE_PLUGIN) {
         path=get_env(_VSECLIPSECONFIGVERSION);
      } else {
         path=get_env(_SLICKCONFIG);
      }
      if ( ! rc && path=='' ) {
         /* Don't use configuration directory. */
         return(0);
      }
   }
   path=_ConfigPath();
   path=absolute(path);
   return ! _file_eq(path,substr(filename,1,pathlen(filename)));

}
#if 1 /* __UNIX__*/
/*
  Kludge to work around bug in RS6000 operating system.  Could not determine
  the exact version of the OS or machine configuration which causes the
  problem.  Can't safely kill or exit the build window.
  Must exit editor before kill process buffer.
*/
_str _rsprocessbug()
{
   if (!_isUnix()) return 0;
   /* If running on RS6000 AND build window is still running */
   /* AND "rs" script executed */
   if ( machine()=='RS6000' && _process_info() && get_env('RSPROCESSBUG')!='' ) {
      return(1);
   }
   return(0);

}
void _exit_rspbug()
{
   if (!_isUnix()) return;
   if ( _rsprocessbug() ) {
      filename := get_env('RSPROCESSBUG')'/kill.slk';
      load_files('+t 'filename);
      if ( ! rc ) {
         _delete_line();
         insert_line('kill -9 '" "_process_info('p'));
         /* If any of these commands fail, we are going to exit any way */
         _save_file('+o');
         _chmod('+x '_maybe_quote_filename(filename));
         _delete_buffer();
      }
   }
}
#endif
/**
 * Used for saving and restoring location within a buffer.  Saves buffer
 * location information into <i>p</i>.  Use the <b>_restore_pos2</b>
 * procedure to restore the location within a buffer.
 *
 * @see restore_pos
 * @see save_pos
 * @see _restore_pos2
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_save_pos2(typeless &p)
{
   p=_alloc_selection('B');
   if (p>=0) {
      _select_char(p);
   }
   return(p=='');
}
/**
 * Restores buffer position saved by <b>_save_pos2</b> procedure.
 *
 * @see restore_pos
 * @see _save_pos2
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
void _restore_pos2(typeless p)
{
   if (p!='') {
      _begin_select(p);
      _free_selection(p);
   }
}
/**
 * Moves the cursor the specified number of lines up.
 *
 * @param NofLines   Number of lines
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions
 */
_command void '-','_'(_str NofLines='') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
  plus_or_minus('Up',NofLines);

}
/**
 * Moves the cursor the specified number of lines down.
 *
 * @param NofLines   Number of lines
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions
 */
_command void '+'(_str NofLines='') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
  plus_or_minus('Down',NofLines);

}
static void plus_or_minus(_str option, typeless param)
{
  param=prompt(translate(param,'  ','+-'),option);
  if ( ! isinteger(param) ) {
     message(nls('Invalid number'));
     return;
  }
  _str old_scroll_style=_scroll_style();
  _scroll_style('c');
  if ( option=='Up' ) {
     up(param);
  } else {
     down(param);
  }
  _scroll_style(old_scroll_style);

}
/**
 * The <b>0</b> command is called if the first character of a command is a digit.  The
 * first parameter to this special function is the entire command line including
 * the first digit. This command moves the cursor to the specified line number.
 * The leading digit 0 zero is not required.  Any line number may be typed on the
 * command line and the (<b>_command</b>) for '0' will be called.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions
 * @param LineNumber
 *
 * @example Command Line Example
 * <DL compact style="margin-left:20pt;">
 * <DT><b>100</b></DT><DD>Moves cursor to line 100.</DD>
 * </DL>
 *
 * @see goto_line
 * @see p_RLine
 * @see p_line
 * @see gui_goto_line
 */
_command void '0'(_str LineNumber='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   goto_line(LineNumber);

}
/**
 * Moves the cursor to the line number specified.  Cursor column position is not
 * changed.  Another way to go to a line is to type the line number on the
 * SlickEdit command line.  Press ESC to get to the command line.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods,
 * Search_Functions
 *
 * @param LineNumber
 * @see goto_line
 * @see p_RLine
 * @see p_line
 * @see gui_goto_line
 */
_command int goto_line(_str lineNumber='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless arg1=prompt(lineNumber);
   typeless result;
   int status=eval_exp(result,arg1,10);
   arg1=result;
   if (status || !isinteger(arg1) ) {
      message(nls('Invalid number'));
      return(1);
   }
   _str old_scroll_style=_scroll_style();
   _scroll_style('c');
   //p_line=arg1;
   p_RLine= arg1;
   _scroll_style(old_scroll_style);
   return(0);
}
_command int goto_col(_str colNo='') name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless arg1=prompt(colNo);
   typeless result;
   int status=eval_exp(result,arg1,10);
   arg1=result;
   if (status || !isinteger(arg1) ) {
      message(nls('Invalid number'));
      return(1);
   }
   p_LCHasCursor=false;
   p_col=arg1;
   return(0);
}
/**
 * Places the cursor on a line number you specify.  A dialog box is displayed which prompts you for a line number.
 *
 * @return Returns 0 if successful
 *
 * @see p_line
 * @see goto_line
 * @see gui_goto_col
 * @see p_RLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, Edit_Window_Methods, CursorMovement_Functions, Search_Functions
 */
_command int gui_goto_line() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   _macro_delete_line();
   typeless result=show('-modal _textbox_form',
        'Go to line',          // Caption
         TB_RETRIEVE,          // flags
         0,                    // Default text box width
         'line navigation',      // help item
         '',                   // Buttons and captions
         'gui_goto_line',      // retrieve name
         '-r 0,2147483647 Line Number (1 - 'p_RNoflines'):'p_RLine
         );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',was_recording);
   _macro_call('goto_line', _param1);
   if (!_MultiCursorAlreadyLooping()) {
      _MultiCursorCallFuncName(_param1,'goto_line');
      return 0;
   }
   return(goto_line(_param1));
}
/**
 * Places the cursor on a column you specify.  A dialog
 * box is displayed which prompts you for the column.
 *
 * @see p_line
 * @see goto_line
 * @see gui_goto_line
 * @see p_RLine
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, CursorMovement_Functions, Search_Functions
 */
_command void gui_goto_col(_str colNo='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   if (colNo != "") {
      p_col = (int) colNo;
      return;
   }
   int was_recording=_macro();
   _macro_delete_line();
   typeless result=show('-modal _textbox_form',
        'Go to Column',       // Caption
         TB_RETRIEVE,         // flags
         0,                   // Default text box width
         'gui_goto_col',      // help item
         '',                  // Buttons and captions
         'gui_goto_col',      // retrieve name
         '-r 1,2147483647 Column:'p_col
         );
   if (result=='') {
      return;
   }
   _macro('m',was_recording);
   _macro_append('p_col='_param1";");
   if (!_MultiCursorAlreadyLooping()) {
      _MultiCursorCallFuncName(_param1,'goto_col');
      return;
   }
   p_col=_param1;
}
static bool continuation_of_previous_line() {
   save_pos(auto p);
   up();
   flags:=_lineflags();
   restore_pos(p);
   return (flags & VSLF_EOL_MISSING)?true:false;
}
/**
 * Use this function to go to an error column
 *  
 * <p>Lines may have been force wrapped for better performance 
 * and this will go to the correct column. 
 *  
 * @param pcol
 */
void _goto_physical_col(int pcol) {
   if (pcol<1) pcol=1;
   int flags=_lineflags();
   if (!continuation_of_previous_line() && !(flags & VSLF_EOL_MISSING)) {
      p_col=_text_colc(pcol, 'I');
   } else {
      _begin_line();
      for (;;) {
         up();
         flags=_lineflags();
         if (!(flags & VSLF_EOL_MISSING)) {
            down();
            break;
         }
      }
      line_seek:=_nrseek();
      _nrseek(line_seek+pcol-1);
   }
}

defeventtab _SelectModeOS390_form;
void ctlok.lbutton_up()
{
   _macro('m',_macro('s'));
   if (ctlmember.p_value) {
      _param1='M';
   } else {
      _param1='A';
   }
   p_active_form._delete_window(ctllist1._lbget_text());
}
void ctllist1.on_create(_str buf_name,_str cur_lang='',_str cur_mode_name='')
{
   _param1='';
   _str ext=_get_selected_mode(buf_name,true);
   if (ext!='') {
      ctlmember.p_value=1;
   } else {
      ctlallmembers.p_value=1;
   }
   _list_modes(cur_lang,cur_mode_name);
   ctllist1._lbselect_line();
}

static void maybe_add_mode(_str modename,int callback_index)
{
   // If there is a callback call it.  If we get a status, 
   // return w/o adding this item
   if ( callback_index && index_callable(callback_index) ) {
      status := call_index(modename,callback_index);
      if ( status ) {
         return;
      }
   }
   _lbadd_item(modename);
}

static const AUTOMATIC_ITEM= 'Automatic';
static const LIST_MODES_CALLBACK_NAME= '_list_modes_callback';
void _list_modes(_str cur_lang,_str cur_mode_name,bool insert_automatic=true,bool list_all_modes=false)
{
   index := 1;
   ff := 1;

   callback_index := find_index(LIST_MODES_CALLBACK_NAME,PROC_TYPE);

   if(def_record_dataset_mode && insert_automatic) {
      maybe_add_mode(AUTOMATIC_ITEM,callback_index);
   }
   bool AlreadyAdded:[];
   modename := "";
   lang := "";
   _GetAllLangIds(auto langs);
   for (j := 0; j < langs._length(); j++) {
      lang = langs[j];
      modename = _LangGetModeName(lang);

      if (modename=='') {
         maybe_add_mode('.'lang,callback_index);
      } else {
         // If user was not a smart-aleck
         if (substr(modename,1,1)!='.' &&
             (list_all_modes || 
              (!_ModenameEQ(modename,'fileman') && 
               !_ModenameEQ(modename,'process') && 
               !_ModenameEQ(modename,'grep')))) 
         {
            maybe_add_mode(modename,callback_index);
            AlreadyAdded:[lowcase(modename)]=true;
         }
      }
   }
   if (p_object==OI_EDITOR) {
      sort_buffer('i');
      _remove_duplicates();
   } else {
      _lbsort();
      _lbremove_duplicates();
   }
   _lbtop();
   typeless status=0;
   if (p_object==OI_EDITOR) {
      if (cur_mode_name!='') {
         // ick.
         status=search('^ '_escape_re_chars(cur_mode_name)'$','@r');
      } else if (cur_lang!='') {
         status=search(_escape_re_chars(cur_lang)'$','@r');
      } else {
         status=1;
      }
   } else {
      if (cur_mode_name!='') {
         status=_lbsearch('^ '_escape_re_chars(cur_mode_name)'$','@r');
      } else if (cur_lang!='') {
         status=_lbsearch(_escape_re_chars(cur_lang)'$','@r');
      } else {
         status=1;
      }
   }
   if (status) {
      _lbtop();
   } else {
      if (p_object!=OI_COMBO_BOX) line_to_bottom();
   }
}
/**
 * Displays a list of commands which change modes and allow you to
 * execute one to change the current mode.  Modes are typically used for
 * language specific editing features such as syntax expansion when
 * space bar is pressed.  However, they are also used for changing key
 * bindings in other ways (fileman mode, grep mode, read only mode). 
 *  
 * @param mode_name  (optional) Language mode name to switch to. 
 *                   Use "-auto" to select the mode name based on the
 *                   file extension.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void select_mode(_str mode_name='') name_info(MODENAME_ARG','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   int was_recording=_macro();
   _macro_delete_line();
   origLangId := p_LangId;
   cur_mode_name := p_mode_name;
   cur_lang := "";
   lang := "";
   result := "";
   list_all_modes := false;
   if (mode_name != '') {
      cur_lang=_Modename2LangId(mode_name);
      if (cur_lang!='') {
         result=mode_name;
      } else if (_ModenameEQ(mode_name,"-auto")) {
         cur_mode_name = _LangGetModeName(_Ext2LangId(_get_extension(p_buf_name)));
      } else if (_ModenameEQ(mode_name,"-all")) {
         list_all_modes = true;
      }
   }
   if (cur_lang=='') {
      if(p_LangId == FUNDAMENTAL_LANG_ID) {
         cur_lang=_file_case(_get_extension(p_buf_name,true));
      } else {
         cur_lang=p_LangId;
      }
      if (_DataSetIsMember(p_buf_name) && def_record_dataset_mode) {
         result=show('-modal _SelectModeOS390_form',
                     p_buf_name,
                     cur_lang,
                     cur_mode_name
                    );
      } else {
         int temp_view_id;
         int orig_view_id=_create_temp_view(temp_view_id);
         p_window_id=temp_view_id;
         _list_modes(cur_lang,cur_mode_name,true,list_all_modes);
         p_window_id=orig_view_id;
         result=show('-modal _sellist_form',
                     "Select Mode",
                     SL_NOTOP|SL_VIEWID|SL_SELECTCLINE,
                     temp_view_id,
                     "",//Buttons
                     "Select Mode dialog box"//Help Item
                     );
         _param1='M';
      }
      if (result=='') {
         return;
      }
   }
   result=strip(result);
   if (result==AUTOMATIC_ITEM) {
      lang='';
   } else if (substr(result,1,1)=='.') {
      lang=substr(result,2);
   } else {
      lang=_Modename2LangId(result);
   }
   if (lang=='') {
      if (def_record_dataset_mode) {
         int old_record_mode=def_record_dataset_mode;
         def_record_dataset_mode=0;
         _SetEditorLanguage();
         def_record_dataset_mode=old_record_mode;
      } else {
         _SetEditorLanguage();
      }
      _record_selected_mode(lang,_param1);
      _macro('m',was_recording);
      _macro_call('_SetEditorLanguage');
   } else {
      _SetEditorLanguage(lang);
      _UpdateContext(true);
      _record_selected_mode(lang,_param1);
      _macro('m',was_recording);
      _macro_call('_SetEditorLanguage',lang);
   }

   // if they change language modes, make sure it is also updated in the tag files
   if (p_LangId != origLangId) {
      // Need to preserve p_modify here.
      orig_modify:=p_modify;
      p_ModifyFlags = 0;
      p_modify=orig_modify;
      _BGReTag2(true);
   }

   ext := _file_case(_get_extension(p_buf_name));
   if (ext != '' && lang != FUNDAMENTAL_LANG_ID && pos(" ", ext) == 0) {
      if (!ExtensionSettings.isExtensionDefined(ext) && !ExtensionSettings.getExtensionIgnoreSuffix(ext)) {
         answer := _message_box(nls("Would you like to map all files with the extension '.%s1' to '%s2'?",ext,_LangGetModeName(lang)), "File Extension Manager", MB_YESNO);
         if (answer == IDYES) {
            _CreateExtension(ext,lang);
            _update_buffers_for_ext(ext,lang);
         }
      }
   } else if (ext == '' && p_buf_name != '') {
      if (def_prompt_extless_select_mode) {
         show('-modal -xy _map_files_like_this_form', p_buf_name, lang);
      }
   }
}

int _OnUpdate_select_mode(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return MF_GRAYED;
   }

   // Try not to let them change the mode for the Build Window,
   // Search Results, and File Manager windows.
   modename := target_wid.p_mode_name;
   if (substr(modename,1,1) == '.' || 
       _ModenameEQ(modename,'fileman') || 
       _ModenameEQ(modename,'process') || 
       _ModenameEQ(modename,'grep') ||
       target_wid._ConcurProcessName()!=null) { 
      return MF_GRAYED;
   }

   // make sure we have a valid menu handle
   if (cmdui.menu_handle == 0) return 0;

   _menu_get_state(cmdui.menu_handle,command,auto flags,"m",auto caption);
   parse caption with caption "\t" auto keys;

   modeName := target_wid.p_mode_name;
   int status = _menu_set_state(cmdui.menu_handle,
                                cmdui.menu_pos,
                                MF_ENABLED,
                                "p",
                                "Select Mo&de ("modeName")...\t"keys);

   return status;
}

/**
 * Sorts the current buffer or selection.  The <b>Sort dialog box</b> is
 * displayed which allows you to select various sort options.
 * @see sort_buffer
 * @see sort_within_selection
 * @see sort_on_selection
 *
 * @appliesTo Edit_Window
 *
 * @categories Miscellaneous_Functions
 *
 */
_command gui_sort() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _macro_delete_line();
   typeless result = show('-modal _sort_form',
                 p_window_id
                 );
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _macro('m',_macro('s'));
   _str type;
   _str options;
   status := 0;
   parse result with type options;
   switch (type) {
   case 'B':
      _macro_append("sort_buffer('"options"');");
      status=sort_buffer(options);
      break;
   case 'O':
      _macro_append("sort_on_selection('"options"');");
      status=sort_on_selection(options);
      break;
   case 'W':
      _macro_append("sort_within_selection('"options"');");
      status=sort_within_selection(options);
      break;
   }
   if (status) {
      _message_box(nls('Sort failed.')'  'get_message(status));
   }
   return(status);
}

defeventtab _sort_form;
void _numeric.lbutton_up()
{
   ctlcase.p_enabled=!p_value;
}

_ok.on_create(int wid)
{
   bool default_to_sort_on_selection=false;
   if (wid.select_active()) {//User may want a selection sort
      if((_select_type(_duplicate_selection(''), 'T') != 'BLOCK')
       &&(_select_type(_duplicate_selection(''), 'T') != 'LINE')){
  /*Selection sorts can only be performed on Block and Line marks*/
          //_on_selection.p_enabled = false;
          _ctl_within_selection.p_enabled = false;
          //_on_selection.p_caption='Sort Lines Selected'
          //message 'Block or Line Marks Must be used for Selection Sorts';
/*Give the user a message in case they had intended to do a
  selection sort on a character mark.  Disable those radio buttons
  too.*/
       }
       _on_selection.p_value = 1;//Turn Selection Sort on
       default_to_sort_on_selection=true;
   }else{
      _on_selection.p_enabled =
      _ctl_within_selection.p_enabled = false;
   }//Disable the Buttons if there is no selection
   _retrieve_prev_form();
   if (default_to_sort_on_selection) {
      if (!_ctl_within_selection.p_enabled) {
         _on_selection.p_value=1;
      } else if (!_on_selection.p_value && !_ctl_within_selection.p_value) {
         _on_selection.p_value=1;
      }
   }
}

_ok.lbutton_up()
{
   ret_val := "";
   if (_on_buffer.p_value) {
      ret_val = 'B';//Sort-on-Buffer Sort
   }
   if (_on_selection.p_value) {
      ret_val = 'O';//Sort-on-Selection Sort
   }
   if (_ctl_within_selection.p_value) {
      ret_val = 'W';//Sort-Within-Selection Sort
   }
   if (_ascending.p_value) {
      ret_val :+= ' A';//Ascending Sort
   }else{
      ret_val :+= ' D';//Descending Sort
   }
   if (ctlcase.p_value) {
      ret_val :+= 'E';
   }else{
      ret_val :+= 'I';
   }
   if (_uniq.p_value) {
      ret_val :+= 'U';
   }
   if (_numeric.p_value) {
      ret_val :+= ' -N';//Numeric Sort
   }
   _save_form_response();
   p_active_form._delete_window(ret_val);
}

// This command is used when updating to a new version of
// SlickEdit
_command install_update(_str cmdline='')
{
   if (cmdline=='') {
      return(1);
   }
   output_dir := strip(parse_file(cmdline),'B','"');
   //parse arg(1) with output_dir . ;
   typeless status=install_update2(output_dir);
   semaphore_dir := output_dir:+'semaphor';
   status=mkdir(semaphore_dir);
   if (status) {
      _message_box(nls("Unable to create semaphore directory '%s'\n\n",semaphore_dir)get_message(status),"SlickEdit Installation");
   }
   return(0);
}

static install_update2(_str output_dir)
{
   if (!isdirectory(output_dir)) {
      return(1);
   }
   _maybe_append_filesep(output_dir);
   filename := output_dir:+USERDEFS_FILE;
   delete_file(filename);
   filename=output_dir:+USERDATA_FILE;
   delete_file(filename);
   filename=output_dir:+USERKEYS_FILE;
   delete_file(filename);
   filename=output_dir:+USEROBJS_FILE;
   delete_file(filename);
   filename=output_dir:+_getUserSysFileName();
   delete_file(filename);

   old_value := get_env(_SLICKCONFIG);
   old_value2 := get_env(_SLICKPATH);
   set_env(_SLICKCONFIG,output_dir);

   typeless status=list_source();
   if (status) {
      _message_box(nls("See manual for information on transferring your configuration changes"),"SlickEdit Installation");
      set_env(_SLICKCONFIG,old_value);
      return(1);
   }
   status=save('',SV_OVERWRITE);
   if (status) {
      // Message box already displayed.
      _message_box(nls("See manual for information on transferring your configuration changes"),"SlickEdit Installation");
      set_env(_SLICKCONFIG,old_value);
      return(1);
   }

   status=list_objects();
   if (status!=1) {
      if (status) {
         _message_box(nls("See manual for information on transferring your configuration changes"),"SlickEdit Installation");
         set_env(_SLICKCONFIG,old_value);
         return(1);
      }
      status=save('',SV_OVERWRITE);
      if (status) {
         // Message box already displayed.
         _message_box(nls("See manual for information on transferring your configuration changes"),"SlickEdit Installation");
         set_env(_SLICKCONFIG,old_value);
         return(1);
      }
   }

   status=list_usersys_objects();
   if (status) {
      set_env(_SLICKCONFIG,old_value);
      // If no forms defined
      if (status==1) {
         return(0);
      }
      _message_box(nls("See manual for information on manually updating your configuration changes"),"SlickEdit Installation");
      return(1);
   }
   filename=p_buf_name;
#if 0
   _message_box(nls("Template source code for user modified system dialog boxes has been placed in the file '%s'\n\nYou must manually apply these changes yourself by typing \"%s\" on the SlickEdit command line",filename,filename),
                "SlickEdit Installation");
#endif
    status=save('',SV_OVERWRITE);
   if (status) {
      // Message box already displayed.
      set_env(_SLICKCONFIG,old_value);
      _message_box(nls("See manual for information on manually updating your configuration changes"),"SlickEdit Installation");
      return(1);
   }

   set_env(_SLICKCONFIG,old_value);
   return(0);
}
static void adjust_filespec(_str &vslickpathfilename)
{
   if (_isWindows()) {
      comspec := get_env("COMSPEC")" /c";
      if (_file_eq(substr(vslickpathfilename,1,length(comspec)),comspec)) {
         vslickpathfilename=strip(substr(vslickpathfilename,length(comspec)+1));
          if (file_match("-p "vslickpathfilename".bat",1)!="") {
             vslickpathfilename :+= ".bat";
             return;
          }
         if (file_match("-p "vslickpathfilename".cmd",1)!="") {
            vslickpathfilename :+= ".cmd";
            return;
         }
      }
   }
}
/**
 * Searches for <i>filename</i> in VSLICKPATH and PATH and
 * displays the full path filename results on the message line.
 *
 * @categories File_Functions
 *
 */
_command void which(_str filename='')
{
   if (filename=="") {
      return;
   }
   // We want this one to act like user typed command on command line
   // except we don't look for internal editor commands.
   _str vslickpathfilename=slick_path_search(filename,"M");
   // We want this one to act like user is at shell prompt.
   _str pathfilename=path_search(filename,"","P");
   adjust_filespec(vslickpathfilename);
   adjust_filespec(pathfilename);
   _str msg="VSLICKPATH found <"vslickpathfilename">   PATH found <"pathfilename">";
   sticky_message(msg);
}



static typeless cs_ori_position;

/**
 * Convert from spaces to tabs.
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void convert_spaces2tabs() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   clear_message();
   int old_mark_id = _duplicate_selection('');
   mark_id := -1;
   int cur_mark = _alloc_selection('B'); _select_char(cur_mark);
   left_edge := 0;
   cursor_y := 0;
   if (!select_active()) {
      left_edge = p_left_edge; cursor_y = p_cursor_y;
      mark_id = _alloc_selection();
      _show_selection(mark_id);
      top(); _select_line(mark_id);
      bottom(); _select_line(mark_id);
   }

   filter_selection('_tabify_filter','',true);

   if (mark_id > 0) {
      _show_selection(old_mark_id);
      _free_selection(mark_id);
      _begin_select(cur_mark); set_scroll_pos(left_edge,cursor_y);
   }
   _free_selection(cur_mark);

   // clear out the adaptive formatting setting for indent with tabs, we may 
   // need to recalculate it
   adaptive_format_clear_flag_for_buffer(AFF_INDENT_WITH_TABS);
}

/**
 * Convert all tabs to spaces.
 *
 * @categories Buffer_Functions, Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void convert_tabs2spaces() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   clear_message();
   int old_mark_id = _duplicate_selection('');
   mark_id := -1;
   int cur_mark = _alloc_selection('B'); _select_char(cur_mark);
   left_edge := 0;
   cursor_y := 0;
   if (!select_active()) {
      left_edge=p_left_edge;cursor_y=p_cursor_y;
      mark_id = _alloc_selection();
      _show_selection(mark_id);
      top(); _select_line(mark_id);
      bottom(); _select_line(mark_id);
   }

   filter_selection('_untabify-filter','',true);

   if (mark_id > 0) {
      _show_selection(old_mark_id);
      _free_selection(mark_id);
      _begin_select(cur_mark); set_scroll_pos(left_edge,cursor_y);
   }
   _free_selection(cur_mark);

   // clear out the adaptive formatting setting for indent with tabs, we may 
   // need to recalculate it
   adaptive_format_clear_flag_for_buffer(AFF_INDENT_WITH_TABS);
}

/* FORMATCOLUMNSFLAG_NOCOMPRESS
 *   Do not compress inter-column whitespace
 */
static const FORMATCOLUMNSFLAG_NOCOMPRESS= (0x1);
/**
 * Options controlling how the <code>format_columns</code>
 * command works.  Set to FORMATCOLUMNSFLAG_NOCOMPRESS = 1
 * to prevent it from compressing inter-column whitespace.
 * 
 * @default 0
 * @categories Configuration_Variables
 * @see format_columns
 */
int def_format_columns_flags=0;


/**
 * Formats words for each line in a selection based on the words in the first
 * line.
 *  
 * <p>This won't work well for porportional fonts (unicode files
 * always use proportional fonts). It could be improved to
 * count characters for Unicode files but this will only fix
 * some of the limits.
 * 
 * @return  Returns 0 if successful.
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Miscellaneous_Functions
 */
_command int format_columns() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   if( !select_active() ) {
      _message_box('No selection active');
      return(1);
   }

   int nocompress= (def_format_columns_flags&FORMATCOLUMNSFLAG_NOCOMPRESS);

   typeless stype=_select_type();
   if( stype=='CHAR' ) {
      // Convert char selections to line selections
      _select_type('','L','LINE');
      stype='LINE';
   }
   width := 0;
   start_col := 0;
   end_col := 0;
   int columnStartPixel=-1,columnEndPixel=-1;
   if( stype=='LINE' ) {
      width=longest_line_in_selection_raw();
      start_col=1;end_col=width;
   } else {
      // stype=='BLOCK'
      typeless dummy;
      //_get_selinfo(start_col,end_col,dummy);
      //width=end_col-start_col+1;
      _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel);
   }

   save_pos(auto p);
   _begin_select();

   // Find the first non-blank line
   i := 0;
   status := 0;
   if (stype=='BLOCK') {
      //int  firstcol, lastcol, fileid;
      //_get_selinfo(firstcol, lastcol, fileid);
      _begin_select();
      //lastcol = lastcol + 1;
      for(;;) {
         if(_end_select_compare() > 0) break;
         _BlockSelGetStartAndEndCol(start_col,end_col,columnStartPixel,columnEndPixel);
         width=end_col-start_col;
         --end_col;
         if( _expand_tabsc_raw(start_col,width)!='' ) break;
         status=down();
         if( status ) break;
      }
   } else {
      for( ;; ) {
         if( _end_select_compare()>0 ) break;
         if( _expand_tabsc_raw(start_col,width)!='' ) break;
         status=down();
         if( status ) break;
      }
   }
   if( status || _end_select_compare()>0 ) {
      restore_pos(p);
      return(0);   // No non-blank lines to columnize
   }

   // Get the column stops
   typeless cols;
   cols._makeempty();
   line := strip(_expand_tabsc_raw(),'T');
   nofcols := 1;
   // 'temp_end_col' is shrunk if we shift a line to the left in the case of a block selection
   int temp_end_col=end_col;
   col := 0;
   before := "";
   middle := "";
   after := "";
   if( stype=='LINE' ) {
      cols[nofcols]=pos('[~ ]',line,1,p_rawpos'r');   // First column stop is first-non-blank-col of first line
   } else {
      // stype=='BLOCK'
      col=pos('[~ ]',line,start_col,p_rawpos'r');   // First column stop is first non-blank after leftcol of block selection
      if( col>start_col ) {
         // Adjust the text in the selection to start at 'start_col' and shrink 'temp_end_col' by the difference
         before=substr(line,1,start_col-1);
         middle=strip(substr(line,start_col,width),'L');
         after=substr(line,end_col+1);
         line=before:+middle:+after;
         temp_end_col-=col-start_col;
      }
      cols[nofcols]=col;
   }
   col=cols[nofcols];
   colstop := 1;
   non_blank_col := 0;
   for( ;; ) {
      for( ;; ) {
         ++colstop;
         col=pos(' ',line,col,p_rawpos);
         non_blank_col=0;
         if( !col ) {
            // At the end of the line
            col=length(line)+2;
         } else {
            if( stype!='LINE' && col>temp_end_col ) {
               // Beyond the adjusted right edge of the block selection
               col=temp_end_col+2;
            } else if( nocompress ) {
               col=pos('[~ \t]',line,col,p_rawpos'r');
               if( stype!='LINE' && col>temp_end_col ) col=temp_end_col+2;
               non_blank_col=col;
            } else {
               ++col;
               non_blank_col=pos('[~ \t]',line,col,p_rawpos'r');
               if( non_blank_col>temp_end_col ) non_blank_col=0;
            }
         }
         if( cols[colstop]._isempty() || cols[colstop]<col ) {
            if( cols[colstop]._isempty() ) {
               ++nofcols;
            } else {
               // Readjust following column stops by the difference
               int diff=col-cols[colstop];
               for( i=colstop+1;i<=nofcols;++i ) cols[i]+=diff;
            }

            if( col<non_blank_col ) {
               // Adjust the right edge of block selection back accordingly
               temp_end_col-=non_blank_col-col;
            }
            cols[colstop]=col;
            //messageNwait('cols['colstop']='cols[colstop]);
         }
         //if( !cols[7]._isempty() ) messageNwait('cols[7]='cols[7]);
         if( stype=='LINE' ) {
            if( col>length(line) ) break;   // End of the line
         } else {
            if( col>length(line) || col>temp_end_col || cols[colstop]>temp_end_col ) {
               //messageNwait('line='translate(line,'+',' '));
               //messageNwait('col='col'  length='length(line)'  temp_end_col='temp_end_col'  cols['colstop']='cols[colstop]);
               break;   // End of the line or selection
            }
         }

         // Now readjust this line to conform with latest column-stops
         before=strip(substr(line,1,col-1),'T');
         middle=substr('',1,cols[colstop]-length(before)-1);
         after=strip(substr(line,col),'L');
         line=strip(before:+middle:+after,'T');
         col=cols[colstop];
      }

      // Find the next non-blank line
      status=0;
      if (stype=='BLOCK') {
         for( ;; ) {
            status=down();
            if( status ) break;
            if( _end_select_compare()>0 ) break;
            _BlockSelGetStartAndEndCol(start_col,end_col,columnStartPixel,columnEndPixel);
            width=end_col-start_col;
            --end_col;
            if( _expand_tabsc_raw(start_col,width)!='' ) break;
         }
      } else {
         for( ;; ) {
            status=down();
            if( status ) break;
            if( _end_select_compare()>0 ) break;
            if( _expand_tabsc_raw(start_col,width)!='' ) break;
         }
      }
      if( status || _end_select_compare()>0 ) break;   // No more non-blank lines to columnize
      temp_end_col=end_col;
      if( stype=='LINE' ) {
         line=substr('',1,cols[1]-1):+strip(_expand_tabsc_raw());
      } else {
         line=_expand_tabsc_raw(1,start_col-1,'S'):+_expand_tabsc_raw(start_col,width):+_expand_tabsc_raw(end_col+1,-1,'S');
         col=pos('[~ ]',line,start_col,p_rawpos'r');   // First column stop is first non-blank after leftcol of block selection
         if( col>start_col ) {
            // Adjust the text in the selection to start at 'temp_start_col' and shrink 'end_col' by the difference
            before=substr(line,1,start_col-1);
            middle=strip(substr(line,start_col,width),'L');
            after=substr(line,end_col+1);
            line=before:+middle:+after;
            temp_end_col-=col-start_col;
         }
      }
      col=cols[1];  // Always start at first column stop of first line
      colstop=1;
   }

#if 0
   msg='';
   for( i._makeempty();; ) {
      cols._nextel(i);
      if( i._isempty() ) break;
      msg :+= ' 'cols[i];
   }
   messageNwait('cols='msg);
#endif

   // Columnize
   new_line := "";
   _begin_select();
   for( ;; ) {
      if( stype=='LINE' ) {
         line=_expand_tabsc_raw();
      } else {
         line=_expand_tabsc_raw(start_col,width);
      }
      if( line!='' ) {
         i=0;
         // The first column stop is a special case
         if( stype=='LINE' ) {
            new_line=indent_string(cols[++i]-1);
         } else {
            new_line=_expand_tabsc_raw(1,start_col-1,'S');
            ++i;
         }
         parse line with before line;
         before=strip(before);
         new_line :+= before;
         while( line!='' ) {
            parse line with '[~ ]','r' +0 before ':b','r' +0 line;
            before=strip(before);
            //messageNwait('cols['(i+1)']='cols[i+1]'  text_col='text_col(new_line)'  before='translate(before,'+',' '));
            new_line :+= substr('',1,cols[++i]-text_col(new_line)-1):+before;
            if( stype!='LINE' && cols[i]>end_col ) break;   // We are now outside the block selection
         }
         if( stype!='LINE' && text_col(new_line)<end_col ) {
            /* This will pad the block-selected portion with trailing spaces
             * out to the width of the block selection.
             */
            int diff=end_col-text_col(new_line);
            new_line=substr(new_line,1,length(new_line)+diff);
         }

         // There might be some line left, so tack it on
         new_line :+= line;

         new_line :+= _expand_tabsc_raw(end_col+1,-1,'S');
         // Trailing whitespace will throw off finding the next column, so strip it
         new_line=strip(new_line,'T');
         replace_line_raw(new_line);
      } else {
         new_line='';
         if( stype!='LINE' ) {
            new_line=_expand_tabsc_raw(1,start_col-1,'S'):+substr('',1,width):+_expand_tabsc_raw(end_col+1,-1,'S');
            if( new_line=='' ) new_line='';
         }
         replace_line_raw(new_line);
      }
      if( down() ) break;
      if( _end_select_compare()>0 ) break;
   }

   _begin_select();

   return(0);
}

/**
 * Retrieves a data value underneath the latest version subkey under the given 
 * key. 
 * 
 * @param rootKey                one of the HKEY_* constants
 * @param prefixPath             subkey path before the version
 * @param suffixPath             subkey path to be appended after the version
 * @param valuename              name of data value
 * @param versionSpecific        whether to search for the latest version or to 
 *                               just append the suffix directly to the prefix
 * 
 * @return _str 
 *  
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _ntRegGetLatestVersionValue()} for versionSpecific 
 *             data, otherwise use {@link _ntRegQueryValue()}
 */
_str _ntGetRegistryValue(int rootKey, _str prefixPath /* no trailing backslash here*/,
                           _str suffixPath /* no leading \ here*/,
                           _str valuename, bool versionSpecific)
{
   if (_isUnix()) return '';

   if (versionSpecific) {
      return _ntRegGetLatestVersionValue(rootKey, prefixPath, suffixPath, valuename);
   } else {
      _maybe_append_filesep(prefixPath);
      prefixPath :+= suffixPath;
      return _ntRegQueryValue(rootKey, prefixPath, '', valuename);
   }
}


_command void cmdtrace()
{
   trace();
}

/**
 * Finds the latest version among a set of subkeys in the registry.
 * 
 * @param RootKey                one of the HKEY_* constants
 * @param Path                   path to key to check for version subkeys
 * @param subkey                 name of latest version subkey
 * @param requiredMajor          required major version (must find a major 
 *                               version greater than this)
 * 
 * @return int                   0 on success, non-zero on error
 *  
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _ntRegFindLatestVersion()}
 */
int _ntRegFindLatestKey(int RootKey, _str Path, _str &subkey,int requiredMajor=0)
{
   if (_isUnix()) return 1;

   return _ntRegFindLatestVersion(RootKey, Path, subkey, requiredMajor);
}

/* Returns 0      on success and fills ValueName with value name
 *                AND Value with the actual value
 *         1      on failure
 *         2      on no more items to process
 */
int _ntRegFindValue(int RootKey,_str Path,_str ValueName,_str &contents)
{
   if (_isUnix()) return 1;
   typeless name,val;

   name='';
   val='';

   contents="";
   // Find the first value listed
   int status=_ntRegFindFirstValue(RootKey,Path,name,val,1);

   while ( !status ) {
      //If it matches what we want, copy and break
      if ( name==ValueName ) {
         ValueName=name;
         contents=val;
         break;
      }
      //Otherwise, get the next value listed
      status=_ntRegFindFirstValue(0,'',name,val,0);
   }
   //Close the key
   _ntRegFindFirstValue(0,'','','',-1);

   return(status);
}

/*
   root is one of the HKEY_* constants...
      #define HKEY_CLASSES_ROOT           ( 0x80000000 )
      #define HKEY_CURRENT_USER           ( 0x80000001 )
      #define HKEY_LOCAL_MACHINE          ( 0x80000002 )
      #define HKEY_USERS                  ( 0x80000003 )
      #define HKEY_PERFORMANCE_DATA       ( 0x80000004 )
      #define HKEY_CURRENT_CONFIG         ( 0x80000005 )
      #define HKEY_DYN_DATA               ( 0x80000006 )

   Prefix is the name of the key before the version part.
      Ex: if you want to find "Software\Microsoft\DevStudio\6.0\Tools"
          Prefix="SOFTWARE\Microsoft\DevStudio".
          Do not use leading or trailing backslashes in Prefix

   Version is the number of the major version to find

      Ex: if you want to find "Software\Microsoft\DevStudio\6.0\Tools"
          Version=6.  The latest version will be found(this means that
          a version like "6.0a" might actually be returned).

   Suffix is remaining part of the keyname after the version

      Ex: if you want to find "Software\Microsoft\DevStudio\6.0\Tools"
          Suffix="Tools".
          Do not use leading or trailing backslashes in Prefix

   Name returns the complete name of the key found

   returns 0 if succesful.  For other return codes see _ntRegFindLatestKey,
           and _ntRegFindFirstValue.
*/
int _ntRegFindVersionKeyName(int root,_str Prefix,int Version,
                             _str Suffix,_str &Name)
{
   if (_isUnix()) return 1;
   Name='';
   subkey := "";
   int status = _ntRegFindLatestVersion(root, Prefix, subkey, Version);
   if (status) {
      return(status);
   }
   WholeName := Prefix'\'subkey;
   if (Suffix=='') {
      //If this happens the user should have just called _ntRegFindLatestKey
      Name=WholeName;
      return(status);
   }
   _maybe_append_filesep(WholeName);
   WholeName :+= Suffix;
   typeless junk1,junk2;

   // trying to determine if this key exists, i guess
   status=_ntRegFindFirstValue(root,WholeName,junk1,junk2,1);
   if (status) {
      return(status);
   }
   Name=WholeName;
   //Close the key
   _ntRegFindFirstValue(0,'','','',-1);
   return(status);
} 


// look up location of Python in the registry
_str _ntRegGetPythonPath()
{
   if (_isUnix()) return '';
   return _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, "SOFTWARE\\Python\\PythonCore\\", "InstallPath", "");
}


/**
 * Displays and optionally sets the p_TruncateLength property.  See
 * p_TruncateLength property for more information.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, String_Functions
 *
 */
_command void trunc(_str value='') name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   value=prompt(value,'Trunc',p_TruncateLength);
   if (value=='') return;
   if (!isinteger(value)) {
      message(get_message(INVALID_NUMBER_ARGUMENT_RC));
      return;
   }
   if (value<0) {
      message(get_message(INVALID_ARGUMENT_RC));
      return;
   }
   p_TruncateLength=(int)value;

}
/**
 * Exchanges the word to the left of the cursor with the word to the right
 * of the cursor.  If the cursor is on a word character that word is
 * considered the right word.  The cursor is placed on the first non-word
 * character between the words and the non-word characters are not
 * altered.  The default characters in a word are A-Z, a-z ,0-9, '_', and  '$'.
 *
 * @see transpose_words
 * @see transpose_lines
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command transpose_words() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   int state=command_state();
   init_command_op();
   no_word_after_cursor := p_col>_text_colc();
   word_chars := _extra_word_chars:+p_word_chars;
   if (!no_word_after_cursor) {
      save_pos(auto p);
      //search('[\od'p_word_chars']|$','@r');
      _TruncSearchLine('[\od'word_chars']|$','r');
      restore_pos(p);
      if (!match_length()) {
         no_word_after_cursor=true;
      }
   }
   status := 0;
   if (no_word_after_cursor
       //! pos('['p_word_chars']',line,_text_colc(p_col,'P'),'r')
      ) {
      status=search('(^|[~\od'word_chars']#)\c[\od'word_chars']#','@rh');
      if (status) {
         clear_message();
      }
   }
   status=search('(^|[~\od'word_chars']#)\c[\od'word_chars']#','@rh<-');
   if (status && ! state ) {
      clear_message();
      retrieve_command_results();
      return '';
   }

   if ( repeat_search() ) {
      clear_message();
   }
   if ( state && p_line!=p_Noflines ) {
      bottom();
      p_col=1;
   }
   /* search '(^|[~'p_word_chars']#)\c['p_word_chars']#','r>' */
   status=search('[\od'word_chars']#','@rh');
   if (status) {
      clear_message();
      retrieve_command_results();
      return '';
   }
   start_col := 0;
   _str current_word=cur_word(start_col);
   _str before_word=_rawText(current_word);
   typeless bp=point();
   bcol := p_col;
   p_col += length(before_word);
   //messageNwait('h1 before_word='before_word);
   status=repeat_search();
   //message('h2');stop;
   if ( status || (state && p_line!=p_Noflines) ) {
      clear_message();
      retrieve_command_results();
      return '';
   }
   current_word=cur_word(start_col);
   _str after_word=_rawText(current_word);
   typeless ap=point();
   acol := p_col;
   _delete_text(length(after_word));_insert_text(before_word);
   goto_point(bp);p_col=bcol;
   _delete_text(length(before_word));_insert_text(after_word);
   retrieve_command_results();

}
/**
 * Exchanges the character to the left of the cursor with the character to
 * the right of the cursor.  If the cursor is on the first character of the
 * current line, the character to the right if any is exchanged with the
 * character under the cursor.  If the cursor is past the end of line the last
 * two characters are exchanged.  The cursor is placed on the character to
 * the right.  This command has no affect if the current line has less than
 * 2 characters.
 *
 * @see transpose_words
 * @see transpose_lines
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void transpose_chars() name_info(','VSARG2_MULTI_CURSOR|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL)
{
   init_command_op();
   int i=_text_colc(p_col,'p');
   LineLen := _line_length();
   if ( LineLen<2 ) {
      return;
   }
   if ( i>LineLen) {
      _end_line();left();
   }
   ch1 := "";
   ch2 := "";
   if (p_col==1) {
      ch1=get_text();
      right();ch2=get_text();
      left();
   } else {
      ch2=get_text();
      left();ch1=get_text();
   }
   _delete_text(2);
   _insert_text(ch2:+ch1);left();
   retrieve_command_results();
}
/**
 * Exchanges the current line with the line above.  If the cursor is on the
 * first line of the buffer, the line below is exchanged with the current
 * line.  The cursor is placed on the character to the right.  This command
 * has no affect if the current buffer has less than 2 lines.
 *
 * @see transpose_words
 * @see transpose_chars
 *
 * @appliesTo Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 *
 */
_command void transpose_lines()  name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   if ( _on_line0() ) {
      return;
   }
   int markid=_alloc_selection();
   if (markid<0) {
      // This should not happen.
      return;
   }
   _select_line(markid);
   up();
   special_case := 0;
   status := 0;
   if (_on_line0()) {
      status=down(2);
      if (status) return;
      special_case=1;
   } else {
      up();
   }
   _move_to_cursor(markid);
   if (special_case) {
      down();
   } else {
      down(2);
   }
   _free_selection(markid);
}

/**
 * Places the cursor on the first non-blank character of the paragraph
 * at or before the cursor.  If the cursor is already at or before the
 * first non-blank character of the current paragraph, the cursor is
 * placed on the first non-blank character of the previous paragraph.
 * Paragraphs are separated with lines containing just the characters
 * tab, space, and   form feed or blank lines.
 * 
 * @see next_paragraph
 * @see next_sentence
 * @see select_paragraph
 * @see cut_sentence
 * @see center_within_margins
 * @see reflow_region
 * @see margins
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
_command prev_paragraph() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   col := p_col;
   _first_non_blank();
   if ( col<=p_col ) {
      up();
   }
   _begin_line();
   /* skip paragraph separator lines */
   search(SKIP_PARAGRAPH_SEP_RE,'@rh-');
   /* Search for paragraph separator line. */
   search(PARAGRAPH_SEP_RE,'@rh-');
   if ( rc ) {
      top();
   } else {
      down();
      _first_non_blank();
   }
   clear_message();

}
/**
 * Places the cursor in column one of the first line after the paragraph
 * at or after the cursor.  Paragraphs are separated with lines
 * containing just the characters tab, space, and form feed or blank
 * lines.
 * 
 * @see prev_paragraph
 * @see next_sentence
 * @see select_paragraph
 * @see cut_sentence
 * @see center_within_margins
 * @see reflow_region
 * @see margins
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 * 
 */
_command next_paragraph() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _begin_line();
   /* skip paragraph separator lines */
   search(SKIP_PARAGRAPH_SEP_RE,'@rh');
   /* Search for paragraph separator line. */
   search(PARAGRAPH_SEP_RE,'@rh');
   if ( rc ) {
      bottom();
   }
   clear_message();

}

/**
 * Used in EMACS emulation.  Highlights the paragraph at or before the 
 * cursor and places the cursor in column one of the first line after the 
 * paragraph at or after the cursor.  If the cursor is already at or before the 
 * first non-blank character of the current paragraph, the cursor is placed 
 * on the first non-blank character of the previous paragraph.  Paragraphs 
 * are separated with lines containing just the characters tab, space, and 
 * form feed or blank lines.
 * 
 * @see prev_paragraph
 * @see prev_sentence
 * @see next_paragraph
 * @see cut_sentence
 * @see center_within_margins
 * @see reflow_region
 * @see margins
 * @see gui_margins
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 * 
 */ 
_command select_paragraph() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   prev_paragraph();
   emacs_select_char();
   /* Skip paragraph separator lines */
   search('^~([ \t]*$)','@rh');
   /* Search for blank line */
   search('^[ \t]*$','@rh');
   if ( rc ) {
      bottom();
      clear_message();
   }

}

/**
 * Used in EMACS emulation.  Places the cursor after the end of the current
 * sentence.  End of sentence is defined to be one of the character ., !, or ?
 * followed by any number of the characters ., !, ?, ", ', ), or ] followed by
 * first space at the end of sentence.
 *
 * @see next_paragraph
 * @see prev_paragraph
 * @see prev_sentence
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void next_sentence() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless p=point();
   col := p_col;
   status := 0;
   search('[~'PARAGRAPH_SKIP_CHARS']','@rh');
   for (;;) {
      //re=PARAGRAPH_SEP_RE'|'END_OF_SENTENCE_RE;
      //messageNwait("PAR_RE="PARAGRAPH_SEP_RE" END_RE="END_OF_SENTENCE_RE);
      status=search(PARAGRAPH_SEP_RE'\c|'END_OF_SENTENCE_RE,'@rh');
      if ( status ) {
         bottom();
         break;
      }
      if ( ! pos(get_text(1,match_length('S')),END_SENTENCE_CHARS) ) {
         up();_end_line();
      }
      if ( p!=point() || p_col>col ) {
         break;
      }
      down();_begin_line();
      /* Skip paragraph separator lines */
      search(SKIP_PARAGRAPH_SEP_RE,'@rh');
      if ( rc ) {
         bottom();
         break;
      }
   }
   clear_message();

}
/**
 * Used in EMACS emulation.  Places the cursor after the end of the
 * current sentence.  End of sentence is defined to be one of the character
 * ., !, or ?  followed by any number of the characters ., !, ?, ", ', ), or ]
 * followed by end of line or two spaces.  Cursor is placed at the first
 * non-blank character of the sentence.
 *
 * @see next_paragraph
 * @see prev_paragraph
 * @see next_sentence
 * @see select_paragraph
 * @see cut_sentence
 * @see center_within_margins
 * @see reflow_region
 * @see margins
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 *
 */
_command void prev_sentence() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   typeless p=point();
   col := p_col;
   search('(^[ \t]*\c[~ \t'END_SENTENCE_CHARS'])|('END_OF_SENTENCE_RE'\c~$)','@rh-');
   if ( ! rc && p==point() && p_col>=col ) { /* In same place? */
      repeat_search();
   }
   for (;;) {
      if ( rc ) {
         top();
         break;
      }
      if ( pos(get_text(1,match_length('S')),END_SENTENCE_CHARS) ) {
         break;
      }
      up();
      if ( rc ) {
         break;
      }
      get_line(auto line);
      down();
      if ( pos(PARAGRAPH_SEP_RE,line,1,'R') ||
          pos(_last_char(strip(line)),END_SENTENCE_CHARS) ) {
         break;
      }
      repeat_search();
   }
   clear_message();
}


/**
 * Used in EMACS emulation.  Deletes the text from cursor to end of sentence
 * and copies it to the clipboard.  End of sentence is defined to be one of
 * the character ., !, or ?  followed by any number of the characters ., !, ?, ",
 * ', ), or ] followed by end of line or two spaces.  Invoking this command
 * multiple times in succession creates one clipboard.
 *
 * @see prev_paragraph
 * @see prev_sentence
 * @see next_paragraph
 * @see select_paragraph
 * @see center_within_margins
 * @see reflow_region
 * @see margins
 *
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void cut_sentence() name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL)
{
   lindex := last_index('','C');
   push := name_name(prev_index('','C'))!='cut-sentence';
   if (def_keys=='emacs-keys' || def_keys=='gnuemacs-keys') {
      emacs_select_char();
   } else {
      _deselect();
      _select_char('','CN');
   }
   next_sentence();
   cut(push);
   last_index(lindex,'C');
}
static _str filter_ucn_to_unicode(_str s)
{
   re := '\\x{#0:h}{#1}';                // match \xH+
   re :+= '|':+'\\x\{{#0:h}{#1}\}';    // match \x{H+}
   re :+= '|':+'\\u{#0[0-9a-fA-F]:4,4}{#1}';      // match \uHHHH
   re :+= '|':+'\\U{#0[0-9a-fA-F]:8,8}{#1}';      // match \UHHHHHHHH
   re=+re:+'|':+'&\#x{#0:h}{#1};';       // match &#xH+;
   re :+= '|':+'&\#{#1:i}{#0};';        // match &#D+;

   // \x123%%\x123%%
   result := "";
   lastUTF16WasStartOfSurrogate := false;
   lastUTF16WasStartOfSurrogate_number := 0;
   int i,j;
   match_len := 0;
   textdigits := "";
   text := "";
   for (i=1;;) {
      j=pos(re,s,i,'re');
      if (!j) {
         if (lastUTF16WasStartOfSurrogate) {
            result :+= _UTF8Chr(lastUTF16WasStartOfSurrogate_number);
            lastUTF16WasStartOfSurrogate=false;
         }
         j=length(s)+1;
         result :+= substr(s,i,j-i);
         break;
      }
      //say('result='result);
      //say('j='j);
      match_len=pos('');
      textdigits=substr(s,pos('S0'),pos('0'));
      //say('textdigits='textdigits);
      if (textdigits=='') {
         if (lastUTF16WasStartOfSurrogate) {
            result :+= _UTF8Chr(lastUTF16WasStartOfSurrogate_number);
            lastUTF16WasStartOfSurrogate=false;
         }
         // Get decimal digits
         text=_UTF8Chr((int)substr(s,pos('S1'),pos('1')));
      } else {
         typeless number=_hex2dec('0x'textdigits);
         if (number<0x10000 && (number&0xFC00)==0xD800) {
            lastUTF16WasStartOfSurrogate=true;
            lastUTF16WasStartOfSurrogate_number=number;
            text='';
         } else if (number<0x10000 && (number&0xFC00)==0xDC00 && lastUTF16WasStartOfSurrogate) {
            number=((lastUTF16WasStartOfSurrogate_number&0x3ff)<<10)+(number&0x3ff)+0x10000;
            text=_UTF8Chr(number);
            lastUTF16WasStartOfSurrogate=false;
         } else {
            if (lastUTF16WasStartOfSurrogate) {
               result :+= _UTF8Chr(lastUTF16WasStartOfSurrogate_number);
               lastUTF16WasStartOfSurrogate=false;
            }
            text=_UTF8Chr(number);
         }
      }
      result :+= substr(s,i,j-i);
      result :+= text;
      //say('h2 result='result);
      //say('mat='match_len);
      i=j+match_len;
   }
   //say('out result='result);
   return(result);
}
/*int _OnUpdate_ucn_to_unicode(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!p_UTF8) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
} */


/**
 * Copies the selected text which contains various UCN forms (\uHHHH, \xHHHH)
 * as Unicode text.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_ucn_as_unicode(bool doCopy=false) name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   ucn_to_unicode();
}
static void ucn_to_unicode(bool doCopy=true)
{
   int was_command_state=command_state();
   if (was_command_state) {
      init_command_op();
   }
   if (doCopy) {
      filter_selection_copy(filter_ucn_to_unicode);
      message('UCN copied as Unicode');
   } else {
      filter_selection(filter_ucn_to_unicode);
      _deselect();
   }

   if (was_command_state) retrieve_command_results();
}
/*int _OnUpdate_unicode_to_ucn(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!p_UTF8) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
} */
static const VSNUMERICFORMAT_DECIMAL=  0;
static const VSNUMERICFORMAT_UTF16=    1;
static const VSNUMERICFORMAT_UTF32=    2;

struct VSUNICODE_TO_UCN {
   _str prefix;
   _str suffix;
   int numericFormat;
   bool case_of_last_letter_of_prefix_indicates_16_or_32_bit;
};
static VSUNICODE_TO_UCN gU2UCNHashTable:[]={
   "c" => {'\x','',VSNUMERICFORMAT_UTF16},
   "regex" => {'\x{','}',VSNUMERICFORMAT_UTF32},
   "java" => {'\u','',VSNUMERICFORMAT_UTF16},
   "ucn" => {'\u','',VSNUMERICFORMAT_UTF32,true},
   "xml" => {'&#x',';',VSNUMERICFORMAT_UTF32},
   "xmldec" => {'&#',';',VSNUMERICFORMAT_DECIMAL},
};
   static _str gU2UCNprefix;
   static _str gU2UCNsuffix;
   static int gU2UCNnumericFormat;
   static bool gU2UCNcase_of_last_letter_of_prefix_indicates_16_or_32_bit;

static _str filter_unicode_to_ucn(_str s)
{
   slen := length(s);
   result := "";
   isDecimal := gU2UCNnumericFormat==VSNUMERICFORMAT_DECIMAL;
   isUTF16 := gU2UCNnumericFormat==VSNUMERICFORMAT_UTF16;
   i := len := 0;
   charLen := 0;
   typeless number;
   _str hex;
   for (i=1;i<=slen;) {
      _strBeginChar(s,i,charLen,false);
      number=_UTF8Asc(substr(s,i,charLen));
      //say('number='number);
      if (isDecimal) {
         result :+= gU2UCNprefix:+number:+gU2UCNsuffix;
      } else {
         hex=_dec2hex(number);
         len=length(hex);
         if (len<=4) {
            hex=substr('',1,4-len,'0'):+hex;
         } else if(isUTF16){
            // output surrogates
            number-= 0x10000;
            hex=_dec2hex((number>>10)|0xD800);
            hex :+= gU2UCNsuffix:+gU2UCNprefix:+_dec2hex((number&0x3ff)|0xDC00);
         } else {
            hex=substr('',1,8-len,'0'):+hex;
            if (gU2UCNcase_of_last_letter_of_prefix_indicates_16_or_32_bit) {
               result :+= upcase(gU2UCNprefix):+hex:+gU2UCNsuffix;
               i+=charLen;
               continue;
            }
         }
         result :+= gU2UCNprefix:+hex:+gU2UCNsuffix;
      }
      i+=charLen;
   }
   return(result);
}


/**
 * Copies the selected Unicode text as C++ UTF-16 \xHHHH notation.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_c() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('c');
}


/**
 * Copies the selected Unicode text as Regex UTF-32 \x{HHHH} notation.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_regex() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('regex');
}


/**
 * Copies the selected Unicode text as Java/C# UTF-16 \uHHHH notation.
 *
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_java() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('java');
}


/**
 * Copies the selected Unicode text as UCN \uHHHH and \UHHHHHHHH UTF-32 notation.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_ucn() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('ucn');
}

/**
 * Copies the selected Unicode text as SGML/XML hexadecimal UTF-32 &#xHHHH; notation.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_xml() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('xml');
}

/**
 * Copies the selected Unicode text as SGML/XML decimal UTF-32 &#DDDD; notation.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Clipboard_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
_command void copy_unicode_as_xmldec() name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_UNICODE_BUFFER)
{
   unicode_to_ucn('xmldec');
}
static void unicode_to_ucn(_str UCNType='',bool doCopy=true)
{
   int was_command_state=command_state();
   if (was_command_state) {
      init_command_op();
   }
   if (!gU2UCNHashTable._indexin(UCNType)) {
      UCNType='regex';
   }
   VSUNICODE_TO_UCN item=gU2UCNHashTable:[UCNType];
   gU2UCNprefix=item.prefix;
   gU2UCNsuffix=item.suffix;
   gU2UCNnumericFormat=item.numericFormat;
   gU2UCNcase_of_last_letter_of_prefix_indicates_16_or_32_bit=item.case_of_last_letter_of_prefix_indicates_16_or_32_bit;
   if (doCopy) {
      filter_selection_copy(filter_unicode_to_ucn);
      message('Unicode copied as UCN');
   } else {
      filter_selection(filter_unicode_to_ucn);
      _deselect();
   }
   if (was_command_state) retrieve_command_results();
}
/**
 * Same as {@link copy_to_clipboard()} command but preserves
 * source buffer newlines.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no text
 * marked in current buffer) and TOO_MANY_SELECTIONS_RC.  On error, message
 * is displayed.
 * 
 * @see copy_to_clipboard
 * @see cut
 * @see list_clipboards
 * @see paste 
 * @see copy_as_text
 * @see copy_as_binary 
 * @see copy_as_hex_view 
 * @see copy_as_html
 * @see copy_as_plain_text
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_as_binary(_str name="",int MarkFlags=VSMARKFLAG_BINARY|VSMARKFLAG_KEEP_SRC_NLCHARS) name_info(','VSARG2_LASTKEY|VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL) 
{
   return copy_to_clipboard(name,MarkFlags);
}
/**
 * Same as {@link copy_to_clipboard()} command but always
 * translates newlines.
 *
 * @return  Returns 0 if successful.  Common return codes are 1 (no text
 * marked in current buffer) and TOO_MANY_SELECTIONS_RC.  On error, message
 * is displayed.
 * 
 * @see copy_to_clipboard
 * @see cut
 * @see list_clipboards
 * @see paste 
 * @see copy_as_text
 * @see copy_as_binary
 * @see copy_as_hex_view 
 * @see copy_as_html
 * @see copy_as_plain_text
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_as_text(_str name="",int MarkFlags=0) name_info(','VSARG2_LASTKEY|VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_TEXT_BOX|VSARG2_REQUIRES_EDITORCTL) 
{
   return copy_to_clipboard(name,MarkFlags);
}
/**
 * Converts selected bytes to hex view style bytes ex. "41414141
 * 00000000".
 *
 * @return  Returns 0 if successful.
 * 
 * @see copy_to_clipboard
 * @see cut
 * @see list_clipboards
 * @see paste 
 * @see copy_as_text
 * @see copy_as_binary
 * @see copy_as_hex_view 
 * @see copy_as_html
 * @see copy_as_plain_text
 *
 * @appliesTo  Edit_Window, Editor_Control, Text_Box, Combo_Box
 *
 * @categories Clipboard_Functions, Combo_Box_Methods, Edit_Window_Methods, Editor_Control_Methods, Text_Box_Methods
 */
_command int copy_as_hex_view(_str name="",int MarkFlags=-1)  name_info(','VSARG2_TEXT_BOX|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   if (command_state()) {
      return copy_to_clipboard(name,MarkFlags);
   }
   if (_select_type()=='') {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return TEXT_NOT_SELECTED_RC;
   }

   int mark_buf_id;
   _get_selinfo(auto start_col,auto end_col,mark_buf_id);

   orig_markid:=_duplicate_selection('');
   dup_markid:=_duplicate_selection();
   _show_selection(dup_markid);
   _select_type(dup_markid,'S','E');

   orig_buf_id:=p_buf_id;
   p_buf_id=mark_buf_id;
   save_pos(auto p);


   _end_select(dup_markid);
   if (_select_type(dup_markid)=='LINE') {
      pcol:=_line_length(true);
      p_col=_text_colc(pcol+1,'I');
   }
   end_pos:=_nrseek();


   _begin_select(dup_markid);
   if (_select_type(dup_markid)=='LINE') {
      p_col=1;
   }
   start_pos:=_nrseek();
   
   _str orig_max = _default_option(VSOPTION_WARNING_STRING_LENGTH);
   _default_option(VSOPTION_WARNING_STRING_LENGTH,0x7FFFFFFF);
   text:=get_text_raw(end_pos-start_pos,start_pos);
   _default_option(VSOPTION_WARNING_STRING_LENGTH, orig_max);
   //say('len='length(text));
   restore_pos(p);

   load_files("+m +bi "orig_buf_id);

   hex_Nofcols:=p_hex_Nofcols;
   hex_bytes_per_col:=p_hex_bytes_per_col;

   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);

   _BinaryToHexView_insert_text(p_window_id,text,hex_bytes_per_col,hex_Nofcols);
   _deselect();
   top();
   status:=_select_char();
   if (status) {
      message(get_message(status));
   } else {
      bottom();
      len1:=_line_length();
      len2:=_line_length(true);
      for (;len1<len2;++len1) right();
      _select_char();

      orig_warn_ksize:=def_copy_to_clipboard_warn_ksize;
      def_copy_to_clipboard_warn_ksize=(0x7fffffff intdiv 1024);
      status=copy_to_clipboard(name,MarkFlags);
      def_copy_to_clipboard_warn_ksize=orig_warn_ksize;
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

   _show_selection(orig_markid);
   _free_selection(dup_markid);
   if (def_deselect_copy) {
      _deselect();
   }
   if (!status) {
      message('Bytes copied as hex view data');
   }

   return status;
}
defeventtab _block_insert_form;
void ctlok.on_create()
{
   _retrieve_prev_form();
}
void ctlok.lbutton_up()
{
   _save_form_response();
   p_active_form._delete_window(ctlcombo1.p_text);
}
int _OnUpdate_block_insert_text(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid.select_active() || _select_type('')!='BLOCK') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
_command void block_insert_text(_str result='')
{
   if (result:=='') {
      _macro_delete_line();
      result=show('-modal _block_insert_form');
      if (result:=='') {
         return;
      }
      _macro('m',_macro('s'));
      _macro_call('block_insert_text',result);
   }
   doBlockModeKey(result,result,true);
}

bool allowBlockModeKey()
{
   _str select_style=_select_type('','S');
   _str persistent_mark=_select_type('','U');
   userLockedSelection := select_style=='E' && persistent_mark=='P';

   if (!def_do_block_mode_key || !select_active() || 
       _select_type('')!='BLOCK' || userLockedSelection ) {
      return(false);
   }

   return _within_selection();
}

bool doBlockModeKey(_str key,_str keya,bool InsertingText)
{
   // DJB 05-02-2007
   // initially false, keep track of if this is our first time in
   static bool EditedSomeTextAlready; 
   _str select_style = _select_type('','S');
   _str persistent_mark = _select_type('','U');
   userLockedSelection := select_style=='E' && persistent_mark=='P';
   if (!def_do_block_mode_key || !select_active() || _select_type('') != 'BLOCK' || userLockedSelection) {
      EditedSomeTextAlready=false;
      return(false);
   }
   bool similarStartAndEndCol;
   if (def_inclusive_block_sel && !_select_type('','I') && InsertingText) {
      similarStartAndEndCol=_BlockSelStartAndEndSimilar('',true);
   } else {
      similarStartAndEndCol=_BlockSelStartAndEndSimilar();
   }
   markid := _duplicate_selection();
   start_mark := _alloc_selection('B');
   //cur_mark := _alloc_selection('B');
   save_pos(auto p);
   _begin_select(markid,true,true,1); _select_char(start_mark);
   _end_select(markid,true,true,true);
   restore_pos(p);
   //restore_pos(p); _select_char(cur_mark);
   cur_col_no := p_col;
   start_col := end_col := buf_id := 0;
   _get_selinfo(start_col, end_col, buf_id, markid);
   inclusive := _select_type(markid,'I');
   
   if (def_do_block_mode_delete && InsertingText && !similarStartAndEndCol) {
      if (p_fixed_font) {
         if (_insert_state()) {
            _delete_selection(markid);
         }
         p_col=start_col;
      } else {
         _BlockSelGetStartAndEndPixel(auto columnStartPixel,auto columnEndPixel,markid);
         if (_insert_state()) {
            _delete_selection(markid);
         }
         p_col=_ColFromTextWidth(columnStartPixel);
      }
   } else if (InsertingText) {
      if (p_fixed_font) {
         p_col=start_col;
      } else {
         _BlockSelGetStartAndEndPixel(auto columnStartPixel,auto columnEndPixel,markid);
         p_col=_ColFromTextWidth(columnStartPixel);
      }
   }

   // DJB 10-30-2006
   // break out of block insert mode if they hit Escape
   // unless this is our first time in here
   if (key :== ESC && similarStartAndEndCol /*end_col == start_col*/ && EditedSomeTextAlready) {
      _deselect();
      restore_pos(p);
      _free_selection(markid);
      _free_selection(start_mark);
      //_free_selection(cur_mark);
      EditedSomeTextAlready = false;
      if (def_keys=='vi-keys') {
         // Want Vim processing of ESC for more exact Vim emulation support.
         return false;
      }
      return(true);
   }

   // DJB 02-18-2006
   // if not inserting text and it is a single column block
   // selection, and the key is BACKSPACE, pretend we are inserting
   // text
   if (!InsertingText && key:==BACKSPACE && def_do_block_mode_backspace &&  similarStartAndEndCol /*start_col:==end_col*/ && !_QReadOnly()) {
      if (p_fixed_font) {
         p_col=start_col;
      } else {
         _BlockSelGetStartAndEndPixel(auto columnStartPixel,auto columnEndPixel,markid);
         p_col=_ColFromTextWidth(columnStartPixel);
      }
      InsertingText=true;
      left();
   }
   if (!InsertingText && key:==DEL && def_do_block_mode_del_key &&  similarStartAndEndCol /*start_col:==end_col*/ && !_QReadOnly()) {
      if (p_fixed_font) {
         p_col=start_col;
      } else {
         _BlockSelGetStartAndEndPixel(auto columnStartPixel,auto columnEndPixel,markid);
         p_col=_ColFromTextWidth(columnStartPixel);
      }
      InsertingText=true;
   }
   _deselect(markid);
   _str event;
   done := false;
   // RH 03-01-2006
   // No inserting in vim visual mode like this
   if(def_keys == 'vi-keys' && vi_get_vi_mode() == 'V'){
      InsertingText = false;
   }
   if (InsertingText) {
      cursor_x := p_cursor_x;
      left_edge := p_left_edge;

      save_pos(p);
      _begin_select(start_mark); 
      set_scroll_pos(left_edge,p_cursor_y);
      p_cursor_x=cursor_x;
      _select_block(markid);
      if (!inclusive) _select_type(markid,'I',0);

      restore_pos(p);
      _select_block(markid);
      if (key :== BACKSPACE) {
         _shift_selection_left(markid);
      } else if (key :== DEL) {
         _shift_selection_left(markid);
      } else {
         event = keya;

         if (!_insert_state()) {
            _shift_selection_left(markid);
         }
         if (def_block_mode_fill_only_if_line_long_enough) {
            _fill_selection(event, markid,VSMARKFLAG_FILL_INSERT_ONCE|VSMARKFLAG_FILL_NO_FILL|VSMARKFLAG_FILL_BLOCK_ONLY_IF_LINE_LONG_ENOUGH);
         } else {
            _fill_selection(event, markid,VSMARKFLAG_FILL_INSERT_ONCE|VSMARKFLAG_FILL_NO_FILL);
         }

         raw_line := substr('', 1, p_col-1):+_rawText(event);
         p_col = length(expand_tabs(raw_line))+1;
      }
      done = true;
   } 
   _free_selection(markid);
   EditedSomeTextAlready = done;
   if (done) {
      save_pos(p);
      _deselect();
      cursor_x := p_cursor_x;
      left_edge := p_left_edge;

      _begin_select(start_mark); 
      set_scroll_pos(left_edge,p_cursor_y);
      p_cursor_x=cursor_x;
      _select_block();
      if (!inclusive) _select_type('','I',0);

      restore_pos(p);
      _select_block();
   }
   _free_selection(start_mark);
   return(done);
}

/**
 * Starts block/column insert mode.  When in block/column insert mode,
 * characters you type as well as other edits (backspace,delete) apply
 * to the entire block/column selection.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions
 */
_command void block_insert_mode() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION)
{
   if (!select_active() ||_select_type()!='BLOCK') {
      _message_box('Block/column selection required');
      return;
   }
   message('Block/column insert mode active.  Press ESC when done');

   int columnStartPixel,columnEndPixel;
   _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel);

   save_pos(auto p);
   start_mark := _alloc_selection('B');
   _begin_select('',true,true,1);_select_char(start_mark);
   _end_select('',true,true,true);
   restore_pos(p);
   int start_col,end_col;
   _BlockSelGetStartAndEndCol(start_col,end_col,columnStartPixel,columnEndPixel);
   p_col=start_col;
   _select_block();
   int inclusive=_select_type('','I');

   _str event;
   name := "";
   i := 0;
   int cursor_x,left_edge;

   for (;;) {
      _undo('s');
      event=get_event();
      if (event:==ESC) {
         event='';
         break;
      }
      name=name_on_key(event);
      switch (name) {
      case 'rubout':
      case 'linewrap-rubout':
         event=BACKSPACE;
         break;
      case 'delete-char':
      case 'linewrap-delete-char':
         event=DEL;
         break;
      case 'cursor-left':
         event=LEFT;
         break;
      case 'cursor-right':
         event=RIGHT;
         break;
      case 'cursor-up':
         event=UP;
         break;
      case 'cursor-down':
         event=DOWN;
         break;
      case 'page-up':
         event=PGUP;
         break;
      case 'page-down':
         event=PGDN;
         break;
      }
      // Check for mouse event
      int event_index=event2index(event);
      if (vsIsMouseEvent(event_index)) {
         break;
      }
      if (event:==BACKSPACE || event:==LEFT) {
         //int orig_col=p_col;
         _deselect();
         left();

         cursor_x=p_cursor_x;
         left_edge=p_left_edge;

         save_pos(p);
         _begin_select(start_mark); 
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
         _select_block();
         if (!inclusive) _select_type('','I',0);

         restore_pos(p);
         _select_block();

         if (event:==BACKSPACE) {
            _shift_selection_left();
            /*for (i=orig_col;i>p_col;--i) {
               _shift_selection_left();
            } */
         }
         continue;
      }
      if (event:==RIGHT) {
         _deselect();
         right();

         cursor_x=p_cursor_x;
         left_edge=p_left_edge;

         save_pos(p);
         _begin_select(start_mark); 
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
         _select_block();
         if (!inclusive) _select_type('','I',0);

         restore_pos(p);
         _select_block();
         continue;
      }
      if (event:==UP) {
         _deselect();
         cursor_x=p_cursor_x;
         left_edge=p_left_edge;
         up();

         save_pos(p);
         _begin_select(start_mark); up();_select_char(start_mark);
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
         _select_block();
         if (!inclusive) _select_type('','I',0);

         restore_pos(p);
         _select_block();

         continue;
      }
      if (event:==DOWN) {
         _deselect();
         cursor_x=p_cursor_x;
         left_edge=p_left_edge;

         down();
         save_pos(p);
         _begin_select(start_mark); down();_select_char(start_mark);
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
         _select_block();
         if (!inclusive) _select_type('','I',0);

         restore_pos(p);
         _select_block();
         continue;
      }
      if (event:==DEL) {
         _shift_selection_left();
         continue;
      }
      if (event:==PGDN || event:==PGUP) {
         _deselect();
         cursor_x=p_cursor_x;
         left_edge=p_left_edge;
         call_key(event);


         save_pos(p);
         _begin_select(start_mark); call_key(event);_select_char(start_mark);
         set_scroll_pos(left_edge,p_cursor_y);
         p_cursor_x=cursor_x;
         _select_block();
         if (!inclusive) _select_type('','I',0);

         restore_pos(p);
         _select_block();
         continue;
      }
      if (name=='undo' || name=='undo-cursor') {
         _undo();
         continue;
      }
      if (name=='deselect') {
         break;
      }

      // if we have just a key here
      if (isnormal_char(event)) {
         if ( length(event)>1 ) {
            event=key2ascii(event);
         }
         _fill_selection(event,'',VSMARKFLAG_FILL_INSERT_ONCE|VSMARKFLAG_FILL_NO_FILL);
         right();
         _deselect();

      } else if (event:!='') {
         // something else going on, better call the event
         _deselect();
         call_key(event);
      } 
      cursor_x=p_cursor_x;
      left_edge=p_left_edge;

      save_pos(p);
      _begin_select(start_mark); 
      set_scroll_pos(left_edge,p_cursor_y);
      p_cursor_x=cursor_x;
      _select_block();
      if (!inclusive) _select_type('','I',0);

      restore_pos(p);
      _select_block();
         
   }
   deselect();
   clear_message();
   if (event:!='') {
      call_key(event);
   }
}
_command void say(_str string="")
{
   say(string);
}

_command void dsay(_str string="")
{
   dsay(string);
}

/** 
 * Dump the contents of the given Slick-C global variable to the
 * debug window. 
 *  
 * @param v  Name of global variable to dump. 
 */
_command void dump_var(_str v='') name_info(VAR_ARG',')
{
   if( v != null && v != '' ) {
      index := find_index(v,VAR_TYPE);
      if( index > 0 ) {
         _dump_var(_get_var(index),v,1,0);
      }
   }
}

/**
 * Search for the JAR file that contains the specified Java class.
 * Examples:<BR>
 * <UL>
 * <LI>findJarForClass org.eclipse.team.PK /pkg/eclipse202/plugins/org.eclipse.team.cvs.ssh/teamcvsssh.jar
 * <LI>findJarForClass org.eclipse.jface.dialogs.MessageDialog /pkg/eclipse202/*.jar
 * </UL>
 *
 * @param cmdLineArg command line args (if this command was entered from the editor's command line). Use "" for a direct call.
 * @param clsName    full class name (for direct call) without the ".class". Example: com.slickedit.vse
 * @param jarFileSpecs
 *                   JAR file specs (for direct call). Wildcards are allowed. Example: /pkg/eclipse202/plugins/org.eclipse.team.cvs.ssh/teamcvsssh.jar
 */
 */
_command void findJarForClass(_str cmdLineArg="", _str clsName="", _str jarFileSpecs="")
{
   // Usage.
   if (cmdLineArg == "") {
      _message_box("Usage: findJarForClass <qualified class name> <search path>\n\nExample:\nfindJarForClass org.eclipse.team.PK /pkg/eclipse202/plugins/*.jar");
      return;
   }

   // Parse the command line arguments, if available.
   if (cmdLineArg != "") {
      parse cmdLineArg with clsName jarFileSpecs;
   }

   // Convert class name from n1.n2.n3 to /n1/n2/n3.class
   _str origClsName = clsName;
   clsName = translate(clsName, FILESEP, ".");
   clsName = FILESEP""clsName".class";

   // Loop and search for the specified class name in all the JAR files.
   fileSpecsAndOptions :=  "+T "jarFileSpecs;
   jarpath := file_match(fileSpecsAndOptions, 1);
   while (jarpath != "") {
      if (file_exists(jarpath""clsName)) {
         dir(jarpath);
         return;
      }
      jarpath = file_match(fileSpecsAndOptions, 0);
   }
   _message_box(nls("Can't find '%s' in\n'%s'",origClsName,jarFileSpecs));
}

/**
 * Filter selected text through an external command. The external command
 * must be capable of redirecting stdin from a file and output to stdout.
 * <p>
 * Takes an optional argument that is the command to run. If "", then user
 * will be prompted for command to run.
 * </p>
 *
 * @return 0 on success, non-zero on error.
 */
_command int filter_command(_str cmd='') name_info(','VSARG2_REQUIRES_AB_SELECTION|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   // Use a loop here to give us an easy mechanism for breaking out
   status := 0;
   for(;;) {
      if( !select_active() ) {
         status=TEXT_NOT_SELECTED_RC;
         break;
      }

      if( cmd=="" ) {
         // Now prompt for the shell command to execute
         //
         if( def_gui ) {
            helpmsg := "?Specifiy the command to run against the selected text. The selected text will be used as input to the command, and the output from the command will replace the selected text.";
            cmd=show("-modal _textbox_form","Command",TB_RETRIEVE,"",helpmsg,"","filter_command","Command");
            if( cmd=="" ) {
               status=COMMAND_CANCELLED_RC;
               break;
            }
            cmd=_param1;
         } else {
            cmd=prompt(cmd,"Command","");
            if( cmd=="" ) {
               status=COMMAND_CANCELLED_RC;
               break;
            }
         }
      }

      int old_mark=_duplicate_selection('');
      int mark=_duplicate_selection();
      //_show_selection(mark);
      was_line_selection := _select_type(mark,'T')=='LINE';

      // Only work with line or char selections
      if( _select_type(mark,'T')=='BLOCK' ) {
         _select_type(mark,'T','LINE');
      }

      // Now make a temporary file to hold the input to the shell and
      // copy the marked lines into it.
      _str temp_in=mktemp(1,'in');
      if( temp_in=='' ) {
         _free_selection(mark);
         message("Unable to create temp file");
         status=1;
         break;
      }
      // Do this in case the working directory changes
      temp_in=absolute(temp_in);

      // Need this so can restore in the case of an editor control
      int orig_buf_id=p_buf_id;
      temp_view_id := orig_view_id := 0;
      status=_open_temp_view(temp_in,temp_view_id,orig_view_id,'+t');
      if( status ) {
         _free_selection(mark);
         break;
      }
      _delete_line();

      // Make sure temporary view uses same UTF-8 and encoding settings as
      // the original buffer.
      typeless junk,utf8,encoding;
      _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
      p_UTF8=utf8;
      p_encoding=encoding;

      _copy_to_cursor(mark);
      _free_selection(mark);
      status=save('+o');
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      if( status ) {
         break;
      }

      // Need this so can restore in the case of an editor control
      p_buf_id=orig_buf_id;

      // Now make a temporary file to hold the output from the shell
      _str temp_out=mktemp(1,'out');
      if( temp_out=='' ) {
         message("Unable to create temp file");
         status=1;
         break;
      }
      // Do this in case the working directory changes
      temp_out=absolute(temp_out);

      cmdline := "";
      for (;;) {
         _str p1;
         parse cmd with p1 '|' cmd;
         if (cmdline == '') {
            cmdline = p1' <'temp_in;
         } else {
            cmdline :+= ' | 'p1;
         }
         if (cmd :== '') {
            break;
         }
      }
      cmdline :+= ' >'temp_out;

      shell(cmdline,'QP');
      if( file_match(temp_out,1)!=temp_out ) {
         message("Error opening results of shell command");
         status=1;
         break;
      }

      // Success
      _begin_select(old_mark);
      if (was_line_selection) {
         _begin_line();
         old_line := p_line;
         _delete_selection(old_mark);
         typeless old_line_insert=def_line_insert;
         if( p_line!=old_line ) {
            // The end of the mark was at the bottom of the buffer,
            // so insert AFTER.
            def_line_insert='A';
         } else {
            def_line_insert='B';
         }
         get(temp_out);
         if( def_line_insert=='A' ) {
            // Must move down so we are back where we started
            down();
         }
         def_line_insert=old_line_insert;   // Quick, change it back
      } else {
         _delete_selection(old_mark);
         status=_open_temp_view(temp_out,temp_view_id,orig_view_id);
         if( !status ) {
            top();
            if (p_line!=0) {
               _select_char();
               bottom();
               no_nls_len:=_line_length();
               nls_len:=_line_length(true);
               if (no_nls_len!=nls_len) {
                  // Just need one more byte even if there are two in order
                  // for _copy_to_cursor() to copy the line ending.
                  right();
               }
               _select_char();
               orig_view_id._copy_to_cursor();
               orig_view_id._begin_select();
               _deselect();
            }
         }
         _delete_temp_view(temp_view_id);
         p_window_id=orig_view_id;
      }

      // Now delete the temp files
      status=delete_file(temp_in);
      if( status ) {
         _message_box("Error deleting temp file: "temp_in);
      }
      status=delete_file(temp_out);
      if( status ) {
         _message_box("Error deleting temp file: "temp_out);
      }
      break;
   }

   if( status ) {
      if( status<0 ) {
         // SlickEdit error code
         message(get_message(status));
      }
   }

   return(status);
}
int _OnUpdate_softwrap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ||
        _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_SoftWrap) {
      return(MF_ENABLED|MF_CHECKED);
   }
   return(MF_ENABLED|MF_UNCHECKED);
}
_command void softwrap_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_SoftWrap=!p_SoftWrap;
   if (_process_info('B') || beginsWith(p_buf_name,'.process')) {
      LanguageSettings.setSoftWrap('process', p_SoftWrap);
   }
   if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_SOFTWRAP_TOGGLE);
   }
}
int _OnUpdate_minimap_toggle(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ||
        _isdiffed(target_wid.p_buf_id)) {
      return(MF_GRAYED|MF_UNCHECKED);
   }
   if (target_wid.p_show_minimap) {
      return(MF_ENABLED|MF_CHECKED);
   }
   return(MF_ENABLED|MF_UNCHECKED);
}
_command void minimap_toggle() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   p_show_minimap=!p_show_minimap;
   /*if (_process_info('B') || p_buf_name=='.process') {
      LanguageSettings.setMinimap('process', p_minimap);
   } */
   /*if (isEclipsePlugin()) {
      _eclipse_dispatchCommand(ECLIPSE_EV_MINIMAP_TOGGLE);
   } */
}
void _minimap_place_cursor(long linenum,bool shift_key_down) {
   if (_MultiCursor()) {
      _MultiCursorClearAll();
   }
   // Exit scroll mode
   p_scroll_left_edge = -1;
   _begin_line();
   goto_line(linenum);
   if (shift_key_down) {
      // Seems like placing the cursor at the beginning of line when we might be extending a selection makes more sense.
   } else {
      // Deselect if 
      if ( select_active() && _select_type('','u')=='' ) _deselect();
      _first_non_blank();
   }
}
/**
 * Retrieves softwrap settings
 *
 * @param lang      Language ID (p_LangId).
 * @param SoftWrap  Output.  Extension specific setting for SoftWrap.
 * @param SoftWrapOnWord  Output.  Extension specific setting for SoftWrapOnWord.
 */
void _SoftWrapGetSettings(_str lang,bool &SoftWrap,bool &SoftWrapOnWord)
{
   SoftWrap=LanguageSettings.getSoftWrap(lang);
   SoftWrapOnWord=LanguageSettings.getSoftWrapOnWord(lang);
}
#if 0
_command void mfutest()
{
   _str cmd,param;
   int status;
   parse arg(1) with cmd param;
   if (cmd=="b") {
      _MFUndoBegin(param);
      say("_MFUndoBegin");
   } else if (cmd=="e") {
      status=_MFUndoEnd();
      say("status="status);
   } else if (cmd=="bs") {
      status=_MFUndoBeginStep(param);
      say("status="status);
   } else if (cmd=="es") {
      status=_MFUndoEndStep(param);
      say("status="status);
   } else if (cmd=="u") {
      status=_MFUndo(0);
      say("status="status);
   } else if (cmd=="r") {
      status=_MFUndo(1);
   } else if (cmd=="lu") {  // list
      say("Set Title=<"_MFUndoGetTitle(0)'>');
      int count=_MFUndoGetStepCount(0);
      int i;
      for (i=0;i<count;++i) {
         _str undoFileDate;
         _str redoFileDate;
         _MFUndoGetStepFileDate(i,0,undoFileDate,0);
         _MFUndoGetStepFileDate(i,1,redoFileDate,0);
         say(nls("status=%s1 f=<%s2> uf=<%s3> rf=<%s4>",_MFUndoGetStepStatus(i,0),_MFUndoGetStepFilename(i,0),_MFUndoGetStepBackup(i,0,0),_MFUndoGetStepBackup(i,0,1,0)));
      }
   } else if (cmd=='c') {
      _MFUndoCancel();
   } else if (cmd=="gs") {
      say(nls("undo status==%s1 redo status=%s2",_MFUndoGetStatus(0),_MFUndoGetStatus(1)));
   } else {
      say(nls("Unknown command <%s1>",cmd));
   }
}
#endif
static _str _orig_item_text;
static _str _orig_help_string;
int _OnUpdate_mfundo(CMDUI &cmdui,int target_wid,_str command)
{
   redo := (command=='mfredo');
   _str title;

   _str msg;
   if (redo) {
      msg="Undoes the last undo of a multi-file edit operation";
   } else {
      msg="Undo the last multi-file edit operation";
   }
   enabled := 0;
   if (_MFUndoGetStatus(redo)) {
      if (redo) {
         title="Multi-File Redo";
         //title="Redo Refactoring";
      } else {
         title="Multi-File Undo";
         //title="Undo Refactoring";
      }
      enabled=MF_GRAYED;
   } else {
      if (redo) {
         title=nls("Redo %s1",_MFUndoGetTitle(redo));
      } else {
         title=nls("Undo %s1",_MFUndoGetTitle(redo));
      }
      enabled=MF_ENABLED;
   }
   int menu_handle=cmdui.menu_handle;
   int button_wid=cmdui.button_wid;
   if (button_wid) {
      button_wid.p_message=title;
      return(enabled);
   }
   if (cmdui.menu_handle) {
      int status=_menu_set_state(menu_handle,cmdui.menu_pos,enabled,'p',
                             title"\t"_mdi.p_child.where_is(command,3),'','','',msg);
   }
   return(enabled);
}
int _MFUndoCallbackCopyFile(_str DestFilename,_str SrcFilename)
{
   //say('D='DestFilename' S='SrcFilename);
   int temp_view_id,orig_view_id=p_window_id;
   // IF this buffer is loaded
   int status=_open_temp_view(DestFilename,temp_view_id,orig_view_id,'+b');
   if (!status) {
      _ReloadCurFile(temp_view_id,'',false,false,SrcFilename,false);
      activate_window(temp_view_id);
   } else {
      status=_open_temp_view(SrcFilename,temp_view_id,orig_view_id);
      if (status) {
         // Fail
         return(status);
      }
      // set p_buf_name and call _SetEditorLanguage so tagging will work
      p_buf_name=DestFilename;
      _SetEditorLanguage();
   }
   orig_AllowSave := p_AllowSave;
   p_AllowSave=true;
   // Retag the file and
   status=save(_maybe_quote_filename(DestFilename),SV_OVERWRITE|SV_RETURNSTATUS);

   p_AllowSave=orig_AllowSave;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   if (status && status>0) {
      status=ERROR_WRITING_FILE_RC;
   }
   return(status);
}

_command void mfundo(_str strRedo='',bool CheckCurrent=true) name_info(','VSARG2_EDITORCTL)
{
   _tbSetRefreshBy(VSTBREFRESHBY_UNDO);
   redo := strRedo=='R';

   int RedoCount=_MFUndoGetRedoCount();

   // IF we have an undo/redo set that can be executed
   typeless result;
   if (!_MFUndoGetStatus(redo) && CheckCurrent) {
      result=show('-modal _mfundo_date_mismatch_form',redo);
      if (result=='') {
         return;
      }
#if 0
      // Check if any of the files that will be restored
      // have been modified since a multi-file operation
      // occurred.
      int count=_MFUndoGetStepCount(redo);
      say('step count='count);
      int i;
      for (i=0;i<count;++i) {
         _str filename=_MFUndoGetStepFilename(i,redo);
         _str CurFileDate;
         _MFUndoGetStepFileDate(i,redo,CurFileDate,true);
         if (CurFileDate!=_file_date(filename,'B')) {
            say(nls("Date mismatch.  File '%s1' may have been modified after this multi-file operation completed",filename));
         }
      }
#endif
   }

   _project_disable_auto_build(true);
   int status=_MFUndo(redo);
   //say('undo status='status);
   if (RedoCount!=_MFUndoGetRedoCount()) {
      // IF any files were restored.
      int RedoCount2=(redo)?_MFUndoGetRedoCount()+1:_MFUndoGetRedoCount()-1;
      int NewRedoCount=_MFUndoGetRedoCount();
      // Restore the current undo/redo set
      _MFUndoSetRedoCount(RedoCount2);
      // List the files that failed.
      int count=_MFUndoGetStepCount(redo);
      //say('step count='count);
      int i;
      for (i=0;i<count;++i) {
         _str filename=_MFUndoGetStepFilename(i,redo);
         // IF the restore succeeded for this buffer
         if (!_MFUndoGetStepStatus(i,redo)) {
            int buffer_view_id,orig_view_id;
            status=_open_temp_view(filename,buffer_view_id,orig_view_id,'+b');
            if (!status) {
               if (!(p_buf_flags & VSBUFFLAG_HIDDEN) || p_AllowSave) {
                  p_file_date=(long)_file_date(p_buf_name,'B');
               }
               _delete_temp_view(buffer_view_id);
               activate_window(orig_view_id);
            }
         }
      }
      // Restore the redo count
      _MFUndoSetRedoCount(NewRedoCount);
   }
   _project_disable_auto_build(false);
   // IF there was a file I/O error
   if (status && RedoCount!=_MFUndoGetRedoCount()) {
      result=show('-modal _mfundo_failed_form',redo);
      if (result=='') {
         return;
      }
      // Try again
      mfundo(strRedo,false);
   }
}
int _OnUpdate_mfredo(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_mfundo(cmdui,target_wid,command));
}
_command void mfredo() name_info(','VSARG2_EDITORCTL)
{
   mfundo('R');
}
static int gMFHashtab:[];
defeventtab _mfundo_date_mismatch_form;
static bool MFREDO(...) {
   if (arg()) ctlRestoreFiles.p_user=arg(1);
   return ctlRestoreFiles.p_user;
}
void ctlViewChanges.lbutton_up()
{

   redo := MFREDO();
   filename := ctllist1._lbget_text();
   if (filename=='') {
      return;
   }

   // get the file names for this undo step
   int i=gMFHashtab:[filename];
   _str file1=_MFUndoGetStepFilename(i,redo);
   _str file2=_MFUndoGetStepBackup(i,redo,true);

   // open the back up file in a temporary view
   int temp_view_id,orig_view_id=p_window_id;
   int status=_open_temp_view(file2,temp_view_id,orig_view_id,'+d');
   if (status < 0) {
      _message_box(get_message(ERROR_OPENING_FILE_RC)": \""file2"\"\n\n"get_message(status));
      return;
   }

   // clone the mode for file2 from the mode for file1
   _str lang1 = _Filename2LangId(file1);
   activate_window(temp_view_id);
   _SetEditorLanguage(lang1);

   // display the file differneces
   _DiffModal('-r1 -r2 -file2title "Expected contents" -viewid2 '_maybe_quote_filename(file1)' 'temp_view_id);

   // clean up
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);

}
void ctlRestoreFiles.lbutton_up()
{
   p_active_form._delete_window(1);
}
void ctlRestoreFiles.on_destroy()
{
   gMFHashtab._makeempty();
}
void ctlRestoreFiles.on_create(bool redo=false)
{
   MFREDO(redo);
   // Check if any of the files that will be restored
   // have been modified since a multi-file operation
   // occurred.
   int count=_MFUndoGetStepCount(redo);
   gMFHashtab._makeempty();
   int i;
   for (i=0;i<count;++i) {
      _str filename=_MFUndoGetStepFilename(i,redo);
      _str CurFileDate;
      _MFUndoGetStepFileDate(i,redo,CurFileDate,true);
      typeless buf_id;
      typeless ModifyFlags;
      typeless buf_flags;
      typeless buf_name;
      parse buf_match(filename,1,'XV') with buf_id ModifyFlags buf_flags buf_name;
      if ((ModifyFlags!='' && (ModifyFlags&1)) || CurFileDate!=_file_date(filename,'B')) {
         gMFHashtab:[filename]=i;
         ctllist1._lbadd_item(filename);
         //say(nls("Date mismatch.  File '%s1' may have been modified after this multi-file operation completed",filename));
      }
      if (ModifyFlags!='') {
         int temp_view_id,orig_view_id;
         int status=_open_temp_view(filename,temp_view_id,orig_view_id,'+b');
         if (!status) {
            _ReadEntireFile();
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
         }
      }
   }
   if (gMFHashtab._isempty()) {
      p_active_form._delete_window(1);
      return;
   }
}
defeventtab _mfundo_failed_form;
static bool MFREDO2(...) {
   if (arg()) ctlTryAgain.p_user=arg(1);
   return ctlTryAgain.p_user;
}

void ctlTryAgain.on_create(bool redo=false)
{
   //say('**********************');
   MFREDO2(redo);
   int RedoCount=(redo)?_MFUndoGetRedoCount()+1:_MFUndoGetRedoCount()-1;
   int NewRedoCount=_MFUndoGetRedoCount();
   // Restore the current undo/redo set
   _MFUndoSetRedoCount(RedoCount);
   // List the files that failed.
   int count=_MFUndoGetStepCount(redo);
   //say('step count='count);
   int i;
   for (i=0;i<count;++i) {
      if (_MFUndoGetStepStatus(i,redo)) {
         ctllist1._lbadd_item(_MFUndoGetStepFilename(i,redo));
         //say(nls("undo failed for '%s1' status=%s2",_MFUndoGetStepFilename(i,redo),_MFUndoGetStepStatus(i,redo)));
      }
   }
   // Restore the redo count
   _MFUndoSetRedoCount(NewRedoCount);
   if (!ctllist1.p_Noflines) {
      p_active_form._delete_window('');
   }
}
void ctlTryAgain.lbutton_up()
{
   MFREDO2(redo);
   int RedoCount=(redo)?_MFUndoGetRedoCount()+1:_MFUndoGetRedoCount()-1;
   _MFUndoSetRedoCount(RedoCount);
   p_active_form._delete_window(1);
}


struct FORWARDBACK_INFO {
   _str buf_name;
   int mark_id;
};

FORWARDBACK_INFO gForwardBackStack[];
int gForwardBackItemPos;
bool gForwardBackNoUpdate=false;

/**
 * Enable forward/back history tracking.
 * 
 * @default true
 * @categories Configuration_Variables
 * 
 * @see forward
 * @see back
 */
bool def_forwardback_enabled=true;
/**
 * Maximum number of items to store in the forward/back history.
 * 
 * @default 10
 * @categories Configuration_Variables
 * 
 * @see forward
 * @see back
 */
int def_forwardback_max=10;

#define FORWARDBACK_DEBUG  0

definit()
{
   gForwardBackItemPos= -1;
   gForwardBackStack._makeempty();
}

static bool _ForwardBack_delete(int i,bool doJoin=false)
{
#if FORWARDBACK_DEBUG
   say('_ForwardBack_delete('i', 'doJoin')');
   say('   going to free mark = 'gForwardBackStack[i].mark_id);
#endif
   _free_selection(gForwardBackStack[i].mark_id);
   gForwardBackStack._deleteel(i);
   if (doJoin) {
      if (i>0 && i<gForwardBackStack._length()) {
         // check if [i] and [i-1] point to save buffer and do join
         int mark_id=gForwardBackStack[i].mark_id;
         int mark_id2=gForwardBackStack[i-1].mark_id;
         same := false;
         if (_select_type(mark_id)!='' && _select_type(mark_id2)!='') {
            temp_view_id := 0;
            int orig_view_id=_create_temp_view(temp_view_id);
            int orig_buf_id=p_buf_id;

            typeless junk;
            buf_id := 0;
            _get_selinfo(junk,junk,buf_id,mark_id,junk);
            _begin_select(mark_id);
            typeless pos1;
            save_pos(pos1);

            buf_id2 := 0;
            _get_selinfo(junk,junk,buf_id2,mark_id2,junk);
            _begin_select(mark_id2);
            typeless pos2;
            save_pos(pos2);

            p_buf_id=orig_buf_id;
            activate_window(orig_view_id);
            same= (buf_id==buf_id2 && pos1==pos2);
         } else {
            if (_select_type(mark_id)=='' && _select_type(mark_id2)=='') {
               // Files are same and position is the same
               same=_file_eq(gForwardBackStack[i].buf_name,
                            gForwardBackStack[i-1].buf_name);
            }
         }
         if (same) {
            // Join these stack entries since they are the same
#if FORWARDBACK_DEBUG
            say('special case JOIN ****');
#endif
            _ForwardBack_delete(i);
            return(true);
         }

      }
   }
   return(false);
}

/**
 * Pushes a new location onto the ForwardBack stack.
 */
void _ForwardBack_push()
{
   // sometimes we don't mess with this stuff
   if (gForwardBackNoUpdate) return;

   // when we push, we pop everything off the stack
   // that was ahead of our current position
   if (gForwardBackStack._length() > gForwardBackItemPos+1) {
      for (i:=gForwardBackItemPos+1;i<gForwardBackStack._length();) {
         _ForwardBack_delete(i);
      }
   }

   // create a new marker
   FORWARDBACK_INFO fw;
   fw.mark_id=_alloc_selection('B');
   _select_char(fw.mark_id);
   fw.buf_name=p_buf_name;
   ++gForwardBackItemPos;
   _tbSetRefreshBy(VSTBREFRESHBY_BACK_FORWARD);
#if FORWARDBACK_DEBUG
   say('_ForwardBack_push b='fw.buf_name' m='fw.mark_id);
   say("   put on "gForwardBackStack._length());
   say('   pos is 'gForwardBackItemPos);
#endif
   // add our new marker to the stack
   gForwardBackStack[gForwardBackStack._length()]=fw;

   // if our stack is too large, then delete things at the
   // beginning until it's a reasonable size
   while (gForwardBackStack._length()>def_forwardback_max) {
      _ForwardBack_delete(0);
      --gForwardBackItemPos;
   }
}
void _ForwardBack_update(bool BufferQuit=false,_str buf_name='')
{
   // sometimes we don't want to update
   if (gForwardBackNoUpdate) return;

   // our stack position must be reasonable
   if (gForwardBackItemPos<0) {
      return;
   }

#if FORWARDBACK_DEBUG
   say('_ForwardBack_update');
#endif

   // get the most recent position
   FORWARDBACK_INFO fw;
   int mark_id=fw.mark_id=gForwardBackStack[gForwardBackItemPos].mark_id;

   // if we are not quitting a buffer, then we need to update the position
   if (!BufferQuit) {
      _deselect(mark_id);
      _select_char(mark_id);
#if FORWARDBACK_DEBUG
   say('   updating mark id 'mark_id' to 'p_buf_name);
#endif
      buf_name=p_buf_name;
   }

   // save the updated info in the same spot
   fw.buf_name=buf_name;
   gForwardBackStack[gForwardBackItemPos]=fw;

}
static int _ForwardBack_GoTo(int i)
{
#if FORWARDBACK_DEBUG
   say('_ForwardBack_GoTo: i='i' len='gForwardBackStack._length());
#endif
   int mark_id=gForwardBackStack[i].mark_id;
#if FORWARDBACK_DEBUG
   say('mark_id='mark_id);
#endif
   if (_select_type(mark_id)!='') {
#if FORWARDBACK_DEBUG
      say('case 1 mark_id='mark_id' i='i);
#endif
      int buf_id;
      start_col := end_col := 0;
      mark_buf_name := "";
      _get_selinfo(start_col,end_col,buf_id,mark_id,mark_buf_name);
      //say('mark_buf_name='mark_buf_name);
      begin_select(mark_id,true,true);
      if (p_window_state=='I') {
         p_window_state='N';
      }
      return(0);
   }
   status := 1;
   _str buf_name=gForwardBackStack[i].buf_name;
#if FORWARDBACK_DEBUG
   say('case 2 buf_name='buf_name' i='i);
#endif
   if (buf_name!='' && file_exists(buf_name)) {
      gForwardBackNoUpdate=true;
      status=edit(_maybe_quote_filename(buf_name),EDIT_DEFAULT_FLAGS);
      gForwardBackNoUpdate=false;
      // Edit automatically restore the original cursor position.
   }
   return(status);
}
int _OnUpdate_forward(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (gForwardBackItemPos+1<gForwardBackStack._length()) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
/**
 * Go to the next viewed file and cursor location like a web browser.
 * This function is only available after using the {@link back} command.
 *
 * @categories Edit_Window_Functions
 */
_command void forward() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
   if (gForwardBackItemPos+1<gForwardBackStack._length()) {
      // Update where we are
      _ForwardBack_update();
   }
   while (gForwardBackItemPos+1<gForwardBackStack._length()) {
      ++gForwardBackItemPos;_tbSetRefreshBy(VSTBREFRESHBY_BACK_FORWARD);
      int status=_ForwardBack_GoTo(gForwardBackItemPos);
      if (!status) return;
      // Delete this entry which is not usable.
      _ForwardBack_delete(gForwardBackItemPos,true);
#if FORWARDBACK_DEBUG
      say('delete case 1');
#endif
      --gForwardBackItemPos;
   }
}
int _OnUpdate_back(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (gForwardBackItemPos>=1) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
/**
 * Go to the previously viewed file and cursor location like a web browser.
 *
 * @categories Edit_Window_Functions
 */
_command void back() name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
#if FORWARDBACK_DEBUG
   say('gForwardBackItemPos='gForwardBackItemPos' len='gForwardBackStack._length());
#endif
   if (gForwardBackItemPos>=1) {
      // Update where we are
      _ForwardBack_update();
   }
   while (gForwardBackItemPos>=1) {
      --gForwardBackItemPos;_tbSetRefreshBy(VSTBREFRESHBY_BACK_FORWARD);
      int status=_ForwardBack_GoTo(gForwardBackItemPos);
      if (!status) return;
      // Delete this entry which is not usable.
      if(_ForwardBack_delete(gForwardBackItemPos,true)) {
         // Did a join so we need to decrement
         --gForwardBackItemPos;
      }
#if FORWARDBACK_DEBUG
      say('delete case 2');
#endif
   }
}

/**
 * Determines if the most recent item in the ForwardBack stack
 * is in the same buffer as the current position.
 *
 * @return bool  true if same buffer, false if not
 */
static bool _ForwardBack_on_same_buffer()
{
   // is there a previous entry to check?
   if (gForwardBackItemPos<0) {
      return(false);
   }
   // get the last item
   int mark_id=gForwardBackStack[gForwardBackItemPos].mark_id;

   // this mark is not helpful, so just compare buffer names
   if (_select_type(mark_id)=='') {
#if FORWARDBACK_DEBUG
   say('_ForwardBack_on_same_buffer, comparing buffer name on stack');
   say('   checking pos 'gForwardBackItemPos);
   say('   'gForwardBackStack[gForwardBackItemPos].buf_name);
   say('   'p_buf_name);
#endif
      return(_file_eq(gForwardBackStack[gForwardBackItemPos].buf_name,p_buf_name) );
   }

   // get the buffer id which has the market, compare it to this buffer's id
   int buf_id;
   start_col := end_col := 0;
   mark_buf_name := "";
   _get_selinfo(start_col,end_col,buf_id,mark_id,mark_buf_name);
#if FORWARDBACK_DEBUG
   say('_ForwardBack_on_same_buffer, comparing buffer id with mark 'mark_id);
   say('   checking pos 'gForwardBackItemPos);
   say('   'buf_id);
   say('   'p_buf_id);
#endif
   return(buf_id==p_buf_id);
}
/**
 *
 * @param old_buffer_name
 * @param option Meaning of option:
 *               <dl compact>
 *               <dt>'W'<dd>Window received focus.  old_buffer_name is null
 *               <dt>'Q'<dd>Buffer quit.  old_buffer_name is the p_buf_name property of the buffer that was quit.
 *               </dl
 */
void _switchbuf_forward_back(_str old_buffer_name,_str option='',_str swold_pos=null,_str swold_buf_id= -1)
{
   // do we mess with this forward/back stuff?
   if (!def_forwardback_enabled) return;

#if FORWARDBACK_DEBUG
   say('_switchbuf_forward_back('old_buffer_name', 'option')');
#endif

   // W option means that the window received focus
   if (option=='W') {
      if (p_mdi_child) {
         // are we on the same buffer that we had before?
         if (_ForwardBack_on_same_buffer()) {
            // yes, just update the position
#if FORWARDBACK_DEBUG
            say('_switchbuf_forward_back:  got focus, just update');
#endif
            _ForwardBack_update();
            return;
         }
         // different file,
         _ForwardBack_push();
      }
      return;
   }
   if (swold_buf_id<0) {
      return;
   }

   // we are quitting a buffer
   if (option=='Q') {
      /*
          For quit, we just need to update the buffer name since edit will
          restore the cursor position.
      */
#if FORWARDBACK_DEBUG
            say('_switchbuf_forward_back:  quitting a buffer, better update');
#endif
      _ForwardBack_update(true,old_buffer_name);
      if (!_no_child_windows() &&
          !(_mdi.p_child.p_buf_flags&VSBUFFLAG_HIDDEN)
          ) {
         if (_mdi.p_child._ForwardBack_on_same_buffer()) {
#if FORWARDBACK_DEBUG
            say('_switchbuf_forward_back:  quitting a buffer, not on same one, better update');
#endif
            _mdi.p_child._ForwardBack_update();
            return;
         }
         _mdi.p_child._ForwardBack_push();
      }
      return;
   }
   if (p_mdi_child) {
      if(_ForwardBack_on_same_buffer()) {
#if FORWARDBACK_DEBUG
            say('_switchbuf_forward_back:  same buffer, just update');
#endif
         _ForwardBack_update();
         return;
      }
      _ForwardBack_push();
   }
}
void _lostfocus_forward_back()
{
   if (!def_forwardback_enabled) return;
   if (p_mdi_child && _isEditorCtl(false)) {
      //  Update this buffers navigation info
      if(_mdi.p_child._ForwardBack_on_same_buffer()) {
#if FORWARDBACK_DEBUG
         say('_lostfocus_forward_back:  same buffer, just update');
#endif
         _mdi.p_child._ForwardBack_update();
      } else {
         _mdi.p_child._ForwardBack_push();
      }
   }
}


static const RULER_LINE=   "----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8----|----9----|----0";

/**
 * Insert an imaginary line containing a ruler line for keeping track
 * of column positions.
 * 
 * @param cols    number of columns for ruler to extend to
 *                or user-defined ruler line text
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void ruler(_str cols='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   // default number of columns is 132
   if (cols=='') {
      cols=132;
   }

   // columns is not an integer, then it must be a special ruler line
   line := "";
   if (!isuinteger(cols) || length(cols) > 5 ) {
      line = cols;
   } else {
      // construct a ruler line of 'cols' columns
      i := 0;
      int n=(int)cols;
      while (length(line) < cols) {
         strappend(line,substr(RULER_LINE,1,min(n,100)));
         n -= 100;
      }
   }

   // insert the line and make it imaginary
   orig_col := p_col;
   int ModifyFlags=p_ModifyFlags;
   insert_line(line);
   p_ModifyFlags=ModifyFlags;
   _LCSetFlags(VSLCFLAG_COLS,VSLCFLAG_COLS);
   _lineflags(NOSAVE_LF,NOSAVE_LF);
   p_col=orig_col;
}

/**
 * Remove trailing whitespace characters from end of lines.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_trailing_spaces() name_info(','VSARG2_MULTI_CURSOR|VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   hasselection := 0;
   direction := -1;
   int orig_trunc = p_TruncateLength;
   p_TruncateLength = 0;
   if (select_active()) {
      hasselection = 1;
      if (_select_type() != "LINE") {
         direction = 1;
      }
   }
   clear_message();
   int cur_mark = _alloc_selection('B'); _select_char(cur_mark);
   left_edge := p_left_edge; 
   cursor_y := p_cursor_y;
   if (hasselection) {
      _begin_select();
   } else {
      top();
   }
   search_options :=  "rh@" :+ (hasselection ? "m" : "") :+ ((direction < 0) ? "-" : "");
   _str line;
   for (;;) {
      if (direction > 0) {
         _begin_line();
      } else {
         _end_line();
      }
      orig_line := p_line;
      status := search('[ \t]@$', search_options);
      if (p_line != orig_line) {
         p_line = orig_line;
      } else {
         if (!status && match_length()) {
            _delete_text(match_length());
         }
      }
      status = down();
      if(status || (hasselection && _end_select_compare() > 0)) break;
   }
   _begin_select(cur_mark); set_scroll_pos(left_edge, cursor_y);
   _free_selection(cur_mark);
   p_TruncateLength = orig_trunc;
}

/**
 * Create highlight for selected area.  Use clear_highlights
 * command to clear all highlights or you can also use Undo to
 * remove the highlights.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void highlight_selection() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY | VSARG2_REQUIRES_EDITORCTL | VSARG2_REQUIRES_AB_SELECTION)
{
   int highlight_marker = _GetTextColorMarkerType();
   typeless p; save_pos(p);
   _str orig_markid = _duplicate_selection('');
   _str temp_markid = _duplicate_selection();
   _show_selection(temp_markid);
   long offset_start, offset_end;
   if (_select_type() == "BLOCK") {
      int columnStartPixel,columnEndPixel;
      _BlockSelGetStartAndEndPixel(columnStartPixel,columnEndPixel);
      //int  firstcol, lastcol, fileid;
      //_get_selinfo(firstcol, lastcol, fileid);
      _begin_select();
      //lastcol = lastcol + 1;
      for(;;) {
         if(_end_select_compare() > 0) break;
         int firstcol,lastcol;
         _BlockSelGetStartAndEndCol(firstcol,lastcol,columnStartPixel,columnEndPixel);
         if (firstcol <= _text_colc()) {
            p_col = firstcol;
            offset_start = _nrseek();
            int end_of_line = _text_colc(_line_length(true)+1, 'I');
            if (lastcol < end_of_line) {
               p_col = lastcol;
            } else {
               p_col = end_of_line;
            }
            offset_end = _nrseek();
            int marker_index = _StreamMarkerAdd(p_window_id, offset_start, offset_end - offset_start, true, 0, highlight_marker, null);
            _StreamMarkerSetTextColor(marker_index, CFG_HILIGHT);
         }
         int status = down();
         if(status) break;
      }
   } else {
      if (_select_type() == "LINE") {
         _end_select(temp_markid); p_col = _text_colc(_line_length(true)+1, 'I');
         offset_end = _nrseek() + _select_type(temp_markid, 'I');
         _begin_select(temp_markid); p_col = 1;
         offset_start = _nrseek();
      } else {
         _end_select(temp_markid);
         offset_end=_nrseek() + _select_type(temp_markid, 'I');
         _begin_select(temp_markid);
         offset_start=_nrseek();
      }
      int marker_index = _StreamMarkerAdd(p_window_id, offset_start, offset_end - offset_start, true, 0, highlight_marker, null);
      _StreamMarkerSetTextColor(marker_index, CFG_HILIGHT);
   }
   _free_selection(temp_markid);
   restore_pos(p);
}

/**
 * Delete (all) overlapping highlights in selection.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_highlight_in_selection(_str markid = '') name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY | VSARG2_REQUIRES_EDITORCTL | VSARG2_REQUIRES_AB_SELECTION)
{
   long sel_start, sel_end;
   _str sel_type = _select_type(markid);
   typeless p; save_pos(p);
   if (sel_type == "LINE") {
      _end_select(markid); p_col = _text_colc(_line_length(true)+1, 'I');
      sel_end = _nrseek() + _select_type(markid, 'I');
      _begin_select(markid); p_col = 1;
      sel_start = _nrseek();
   } else {
      _end_select(markid);
      sel_end = _nrseek() + _select_type(markid, 'I');
      _begin_select(markid);
      sel_start = _nrseek();
   }
   restore_pos(p);

   int i;
   int list[];
   int highlight_marker = _GetTextColorMarkerType();
   _StreamMarkerFindList(list, p_window_id, sel_start, sel_end - sel_start, 0, highlight_marker);
   for (i = 0; i < list._length(); ++i) {
      _StreamMarkerRemove(list[i]);
   }
}

/**
 * Delete (all) highlights under cursor if exists.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void remove_highlight() name_info(','VSARG2_MULTI_CURSOR|VSARG2_READ_ONLY | VSARG2_REQUIRES_EDITORCTL)
{
   int i;
   int list[];
   int highlight_marker = _GetTextColorMarkerType();
   _StreamMarkerFindList(list, p_window_id, _nrseek(), 1, 0, highlight_marker);
   for (i = 0; i < list._length(); ++i) {
      _StreamMarkerRemove(list[i]);
   }
}
_command void new_window_size(_str cmdline='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI|VSARG2_NOEXIT_SCROLL|VSARG2_MARK) {
   config('Editor Windows');
}

/**
 * @return Input string with all non-alphanumeric characters converted
 * to hex equivalents.
 * 
 * @param s input string
 */
_str urlencode(_str s)
{
   ts := "";
   scopy := s;
   for(i:=1;i<=length(scopy);++i ) {
      ch := substr(scopy,i,1);
      if(!isalnum(ch)) {
         n := _dec2hex(_asc(ch),16,2);
         ts :+= '%'n;
      }
      else {
         ts :+= ch;
      }
   }
   return(ts);
}
int _OnUpdate_check_line_endings(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   // Could do better here and support some hex encodings here
   if (p_hex_mode==HM_HEX_ON || p_buf_width) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 *  Changes all lines endings in the buffer to the line ending
 *  format specified.
 * 
 * @param newline   One of the following options:
 * <dl>
 *    <dt>"\x0d\x0a"'</dt><dd>Convert line endings to CRLF</dd>
 *    <dt>"\x0a"</dt><dd>Convert line endings to LF</dd>
 *    <dt>"\x0d"</dt><dd>Convert line endings to CR</dd>
 * </dl>
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @see _CheckLineEndings
 * 
 * @categories  Edit_Window_Methods, Editor_Control_Methods
 */
static void _CorrectLineEndings(_str newline) {
   if (newline:!="\x0d\x0a" &&
       newline:!="\x0a" &&
       newline:!="\x0d"
       ) {
      return;
   }
   last_nlchar_changed:=_last_char(p_newline)!=_last_char(newline);
   p_newline=newline;
   _save_pos2(auto p);
   top();
   if (newline:=="\x0d\x0a") {
      if (last_nlchar_changed) {
         search('\13\10|\13(#!\10)|(#<!\13)\10)','r@','\13\10');
         //say('case 1');
      } else {
         //say('case 1f');
         search('\13(#!\10)|(#<!\13)\10','r@','\13\10');
      }
   } else if (newline:=="\x0a") {
      if (last_nlchar_changed) {
         //say('case 2');
         search('(\13\10|\10|\13)','r@','\10');
      } else {
         //say('case 2f');
         search('(\13\10|\13)','r@','\10');
      }
   } else if (newline:=="\x0d") {
      if (last_nlchar_changed) {
         //say('case 3');
         search('(\13\10|\13|\10)','r@','\13');
      } else {
         //say('case 3f');
         search('(\13\10|\10)','r@','\13');
      }
   }
   _restore_pos2(p);
}
/**
 * Toggles line number display on/off.  This command does more than just set the
 * {@link p_line_numbers_len} property.
 *
 * @appliesTo Editor_Control, Edit_Window
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * @return  Returns 1 if line endings are inconsistent and when
 *          prompted Escape key is pressed. Returns 1 if line
 *          endings are inconsistent and file is read only.
 *          Otherwise, 0 is returned.
 */
_command int check_line_endings(_str cmdline='',bool called_on_open=false) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_NOEXIT_SCROLL) {
   // checking line endings for record files not supported.
   if (p_buf_width || p_hex_mode==HM_HEX_ON) {
      return 0;
   }
   nlchars_message:=_CheckLineEndings();
   if (nlchars_message=='') {
      if (!called_on_open) {
         message('Line endings are consistent');
      }
      return 0;
   }
   //message(nlchars_message);
   if (_QReadOnly()) {
      if (!called_on_open) {
         message(nlchars_message);
      }
      return 1;
   }
   if (cmdline=='') {
      cmdline=show('-modal _inconsistent_line_endings_form',nlchars_message,called_on_open,p_buf_name);
      if (cmdline=='') {
         // Still have inconsistent line endings
         return 1;
      }
   }
   cmdline=upcase(cmdline);
   if (cmdline=='D' || cmdline=='CRLF') {
      _CorrectLineEndings("\x0d\x0a");
      return 0;
   }
   if (cmdline=='U' || cmdline=='LF') {
      _CorrectLineEndings("\x0a");
      return 0;
   }
   if (cmdline=='M' || cmdline=='CR') {
      _CorrectLineEndings("\x0d");
      return 0;
   }
   return 0;
}
defeventtab _inconsistent_line_endings_form;
void ctlok.on_create(_str nlchars_message,bool called_on_open,_str buf_name) {
   if (!called_on_open) {
      int adjust=p_active_form.p_height-ctlshowdialog.p_y-p_active_form._bottom_height();
      p_active_form.p_height=p_active_form.p_height-adjust;
      ctlshowdialog.p_visible=false;
   } else {
      ctlshowdialog.p_value=1;
   }
   ctlcombo1._lbadd_item('Windows/DOS (CRLF)');
   ctlcombo1._lbadd_item('Unix/macOS (LF)');
   ctlcombo1._lbadd_item('Class Mac (CR)');

   ctlinfo.p_caption=buf_name"\n\nLine ending information: "nlchars_message;
   parse nlchars_message with auto default_nlchars '(';
   if (default_nlchars=='CRLF') {
      ctlcombo1.p_text='Windows/DOS (CRLF)';
   } else if (default_nlchars=='LF') {
      ctlcombo1.p_text='Unix/macOS (LF)';
   } else if (default_nlchars=='CR') {
      ctlcombo1.p_text='Class Mac (CR)';
   }
}
void ctlok.lbutton_up() {
   if (ctlshowdialog.p_visible && !ctlshowdialog.p_value) {
      def_check_line_endings=false;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   parse ctlcombo1.p_text with '(' auto nlchars ')';
   p_active_form._delete_window(nlchars);
}
void ctlcancel.lbutton_up() {
   if (ctlshowdialog.p_visible && !ctlshowdialog.p_value) {
      def_check_line_endings=false;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window('');
}
