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

static void _move_selected_lines(int dir = -1, bool use_smart_paste=true)
{
   if (_on_line0()) {
      return;
   }
   had_selection := true;
   if (!select_active2()) {
      _deselect();
      _select_line();
      had_selection=false;
   }
   if (_select_type('') != "LINE") {
      /*
         Mouse selection or more likely Shift+down was used when in column 1. 
         Don't want last line included.
      */
      if (_select_type('') == 'CHAR' && _end_select_compare()==0 && p_col==1 && _begin_select_compare() &&
          ((_select_type('', 'S') == 'C'  && _select_type('','I')==0) || _cua_select==1)
          ) {
         _select_type('', 'T', 'LINE');
         // Shorten this selection by one line and move cursor up.
         _end_select();
         up();
         save_pos(auto p);
         _begin_select();
         _deselect();
         _select_line();
         restore_pos(p);
         _select_line();
      } else {
         _select_type('', 'T', 'LINE');
      }
   }
   int Noflines;
   if (dir>=0) {
      Noflines=count_lines_in_selection();
   }
   // Need to lock the selection here so cursor can always be located at the 
   // top of the selection.
   if (_select_type('', 'S') == 'C') {
      _select_type('', 'S', 'E');
   }
   int left_edge, cursor_y;
   if (dir < 0) {
      _begin_select('',true,false);
      if (up(2) == TOP_OF_FILE_RC) {
         if (!had_selection) _deselect();
         return;
      }
   } else {
      _end_select('',true,false);
      left_edge = p_left_edge; cursor_y = p_cursor_y;
      if (down() == BOTTOM_OF_FILE_RC) {
         if (!had_selection) _deselect();
         return; 
      }
   }
   if (use_smart_paste) {
      smart_paste('', 'M', '', false);
   } else {
      _move_to_cursor('');
   }
   if (dir>=0) {
      down(Noflines);
      if (!had_selection) _deselect();
      set_scroll_pos(left_edge, cursor_y+(p_font_height*1));
   } else {
      down();
      if (!had_selection) _deselect();
   }
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
_command void move_lines_up(bool do_smart_paste=true) name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _move_selected_lines(-1,do_smart_paste);
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
_command void move_lines_down(bool do_smart_paste=true) name_info(','VSARG2_MULTI_CURSOR|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _move_selected_lines(1,do_smart_paste);
}

