////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "markfilt.e"
#import "smartp.e"
#import "stdprocs.e"
#endregion

static void _move_selected_lines(int dir = -1, boolean use_smart_paste=true)
{
   if (_on_line0()) {
      return;
   }
   int markid;
   if (!select_active()) {
      markid = _alloc_selection();
      if (markid < 0) {
         return;
      }
      _show_selection(markid);
      _select_line(markid);
      _select_type(markid, 'S', 'E');
   } else {
      markid = _duplicate_selection('');
      if (_select_type(markid) != "LINE") {
         _select_type(markid, 'T', 'LINE');
      }
      if (_select_type(markid, 'S') == 'C') {
         _select_type(markid, 'S', 'E');
      }
   }
   left_edge := p_left_edge; cursor_y := p_cursor_y;
   if (dir < 0) {
      _begin_select();
      if (up(2) == TOP_OF_FILE_RC || _on_line0()) return;
   } else {
      _end_select();
      if (down() == BOTTOM_OF_FILE_RC) return; 
   }
   if (use_smart_paste) {
      smart_paste(markid, 'M', '', false);
   } else {
      _move_to_cursor(markid);
   }
   down();
   set_scroll_pos(left_edge, cursor_y);
}

/**
 * Moves current line or current selection up one line.  If no 
 * selection is active, a LINE selection is created for the 
 * current line.  If a selection is active, it is changed to 
 * LINE selection and locked.
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void move_lines_up() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _move_selected_lines(-1);

}

/**
 * Moves current line or current selection down line.  If no 
 * selection is active, a LINE selection is created for the 
 * current line.  If a selection is active, it is changed to 
 * LINE selection and locked.
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
_command void move_lines_down(boolean do_smart_paste=true) name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _move_selected_lines(1);
}

