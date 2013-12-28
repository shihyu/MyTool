////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50396 $
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
#import "compile.e"
#import "dlgman.e"
#import "eclipse.e"
#import "files.e"
#import "main.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "window.e"
#endregion

_str _no_resize;

// This event does not get called when you switch focus from a maximized
// window to a minimized window.   In this case, the SetFocus call causes
// the new window to be maximized and the old window to be minimized.  The
// later of which screws things up.  You won't see either event. */
void _on_resize()
{
#ifdef not_finished
   if (!p_mdi_child || p_window_id==VSWID_HIDDEN) {
      return;
   }
   if (_no_resize!='' || p_window_state!='N') return;
   if (_mdi.p_child.p_window_state=='M') return;
   // If this editor control is inside a form
   //if (p_object!=OI_FORM) return;
   /* If window was moved, create new tile id and set old window size */
   int x,y,width,height;
   _MDIChildGetWindow(x,y,width,height);
   //say("w="width" ow="p_old_width" h="height" oh="p_old_height);
   int changed_height=height-p_old_height;
   int changed_width=width-p_old_width;
   /* message 'changed_width='changed_width' changed_height='changed_height */
   if ((p_old_x!=x && p_old_y!=y) || (changed_width && changed_height) ) {
      /* message 'window was moved id='p_window_id' old_x='p_old_x' x='x' old_y='p_old_y' y='y' ch_width='changed_width' ch_height='changed_height */
      p_tile_id=_create_tile_id();
      p_old_x=x;p_old_y=y;p_old_width=width;p_old_height=height;
      return;
   }
   zap_iconized_tile_ids(p_tile_id);
   //say('wid='p_window_id' changed_width='changed_width' changed_height='changed_height);
   int x2=0,y2=0,width2=0,height2=0;
   int edge_x1=0, edge_y1=0;
   int edge_x2=0, edge_y2=0;
   int create_new_tile_id=0;
   typeless view_id=0;
   int orig_view_id=0;
   get_window_id(orig_view_id);
   /* IF height changed */
   if (changed_height) {
      create_new_tile_id=1;
      /* Look for a tile edge above. */
      edge_x1=p_old_x;edge_y1=p_old_y;
      edge_x2=p_old_x+p_old_width;edge_y2=edge_y1;
      /* message 'height changed id='p_window_id' ow='p_old_width' oy='p_old_y */
      view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
      //say(p_old_x" "x" "p_old_y" "y" "p_old_width" "width" "p_old_height" "height);
      if (view_id) {
         create_new_tile_id=0;
         /* Fix height of window above this one. */
         activate_window(view_id);
         _MDIChildGetWindow(x2,y2,width2,height2);
         _no_resize=1;_MDIChildSetWindow(x2,y2,width2,y-y2);_no_resize='';

         activate_window(orig_view_id);
      }
      edge_x1=p_old_x;edge_y1=p_old_y+p_old_height;
      edge_x2=p_old_x+p_old_width;edge_y2=edge_y1;
      view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
      if ( view_id) {
         create_new_tile_id=0;
         /* Fix height of window below this one. */
         activate_window(view_id);
         _MDIChildGetWindow(x2,y2,width2,height2);
         _no_resize=1;_MDIChildSetWindow(x2,y+height,width2,y2+height2-y-height);_no_resize='';
         activate_window(orig_view_id);
      }
      if (create_new_tile_id) {
         p_tile_id=_create_tile_id();
      }
   }
   if (changed_width) {
      create_new_tile_id=1;
      edge_x1=p_old_x;edge_y1=p_old_y;
      edge_x2=edge_x1;edge_y2=p_old_y+p_old_height;
      view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
      //message 'ox='p_old_x' x='p_x' ow='p_old_width' w='p_width' view_id='view_id;
      if ( view_id ) {
         create_new_tile_id=0;
         /* Fix width of window to left of this one. */
         activate_window(view_id);
         _MDIChildGetWindow(x2,y2,width2,height2);
         _no_resize=1;_MDIChildSetWindow(x2,y2,x-x2,height2);_no_resize='';
         activate_window(orig_view_id);
      }
      edge_x1=p_old_x+p_old_width;edge_y1=p_old_y;
      edge_x2=edge_x1;edge_y2=p_old_y+p_old_height;
      view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
      if ( view_id ) {
         create_new_tile_id=0;
         /* Fix width of window to right of this one. */
         activate_window(view_id);
         _MDIChildGetWindow(x2,y2,width2,height2);
         _no_resize=1;_MDIChildSetWindow(x+width,y2,x2+width2-x-width,height2);_no_resize='';
         activate_window(orig_view_id);
      }
      if (create_new_tile_id) {
         p_tile_id=_create_tile_id();
      }
      /* message 'width changed id='p_window_id */
   }
   p_old_x=x;p_old_y=y;p_old_width=width;p_old_height=height;
#endif
}

boolean _islast_window()
{
   int count=0;
   int wid=window_match(p_buf_name,1,'xna');
   for (;;) {
      if (!wid) break;
      if (wid.p_mdi_child && wid.p_buf_id==p_buf_id) ++count;
      wid=window_match(p_buf_name,0,'xna');
   }
   return((count<=1));
}

static void _close_tile_or_window()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
      typeless view_id=0;
      if (p_window_state=='N') {
         if ( _tile_above(view_id,true)) {
            activate_window(view_id);
            delete_tile('','','',DOWN);
            return;
         } else if (_tile_below(view_id,true)){
            activate_window(view_id);
            delete_tile('','','',UP);
            return;
         } else if (_tile_left(view_id,true)){
            activate_window(view_id);
            delete_tile('','','',RIGHT);
            return;
         } else if (_tile_right(view_id,true)){
            activate_window(view_id);
            delete_tile('','','',LEFT);
            return;
         }
      }
   }
   int mdi_wid=0;
   if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
      mdi_wid=_MDIFromChild(p_window_id);
   }
   _delete_window();
   if (p_window_flags & HIDE_WINDOW_OVERLAP) {
      int i;
      for (i=1;i<=_last_window_id();++i) {
         if (_iswindow_valid(i) && i.p_mdi_child &&
             !(i.p_window_flags & HIDE_WINDOW_OVERLAP)) {
            p_window_id=i;
            break;
         }
      }
   }
   _maybe_maximize_window(mdi_wid);
}

/**
 * Closes the current window and optionally deletes the buffer.  Prompts the 
 * user to save changes if the buffer is deleted.
 *
 * @param doDeleteBufferIf_1FPW
 *               Determines wheter buffer is deleted. <BR>
 *               IF =='' AND one file per window, the buffer is deleted.<BR>
 *               IF =='W' the buffer is deleted.<BR>
 *               Otherwise the buffer is not deleted.  
 * @param saveBufferPos
 *               If true, the buffer position information is saved.
 * @return Returns 0 if successful.
 * @categories Window_Functions
 */
_command int close_window(_str doDeleteBufferIf_1FPW='',boolean saveBufferPos=true, ...) name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Special case for Eclipse plugin. Close the editor window the Eclipse's way.
   if (isEclipsePlugin() && !isInternalCallFromEclipse()) {
      return(_eclipse_close_editor(p_window_id, p_buf_name, (int)p_modify));
   }

   // IF current buffer has the build window running in it
   if (_process_info('b') && def_one_file!='') {
      if(_DebugMaybeTerminate()) {
         return(1);
      }
   }
   /* Don't allow hidden window to be deleted. */
   if ( (p_window_flags&HIDE_WINDOW_OVERLAP)) {
      return(1);
   }
   if (def_one_file=='' && def_close_window_like_1fpw && doDeleteBufferIf_1FPW=='' && Nofwindows()==1) {
      if (p_window_state=='M') {
         return quit();
      }
      doDeleteBufferIf_1FPW='w';
   }
   typeless status=0;
   _str old_buffer_name='';
   typeless swold_pos=0;
   typeless swold_buf_id=0;
   int buf_id=0;
   boolean do_switch_buffer = false;
   if ((doDeleteBufferIf_1FPW=='' && def_one_file!='') || lowcase(doDeleteBufferIf_1FPW)=='w') {
      // check if there are any other windows displaying this file
      if (_islast_window()) {
         set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
         buf_id=p_buf_id;
         status=_window_quit(false,saveBufferPos);
         if (buf_id!=p_buf_id) {
            do_switch_buffer = true;
         }
         if (status) {
            return(status);
         }
      }
   }
   _close_tile_or_window();
   if (do_switch_buffer) {
      switch_buffer(old_buffer_name,'Q',swold_pos,swold_buf_id);
   }
   return(0);
}
static void maybe_zoom_window(int new_x,int new_y,int new_width,int new_height)
{
   int x,y,width,height;
   _get_max_window(x,y,width,height);
   if (new_x==x && new_y==y && new_width==width && new_height==height) {
      p_window_state='M';
   } else {
      _MDIChildSetWindow(new_x,new_y,new_width,new_height,'N');
   }
}

static int doTiledSplitWindow(boolean vertical, _str filename, boolean restorePos)
{
   int x=0, y=0, width=0, height=0;
   p_window_id = _mdi.p_child;
   int orig_wid = p_window_id;
   one_tile();
   if ( p_window_state == 'M' ) {
      // Window is maximized
      if ( def_one_file != '' ) {
         p_tile_id = _create_tile_id();
      }
      // Get the size of the mdi frame draw area
      p_window_state = 'N';
      _get_max_window(x, y, width, height);
   } else {
      _mdi.p_child._MDIChildGetWindow(x, y, width, height);
   }
   int tile_id = p_tile_id;
   int top_width = width intdiv 2;
   int top_height = height intdiv 2;
   if ( !vertical ) {
      if ( p_object == OI_FORM ) {
         if ( top_height < (_top_height() + _bottom_height() + p_font_height) ) {
            _message_box(nls('Window too small'));
            return 1;
         }
      } else {
         if ( top_height < (p_font_height * 3) ) {
            _message_box(nls('Window too small'));
            return 1;
         }
      }
   }

   _no_resize = 1;
   save_pos(auto p);
   int status = 0;
   if ( vertical ) {
      status = load_files('+i:'(x+top_width)' 'y' '(width-top_width)' 'height' n 'filename);
   } else {
      status = load_files('+i:'x' '(y+top_height)' 'width' '(height-top_height)' n 'filename);
   }
   _no_resize = '';

   if ( status ) {
      // Not sure why geometry needs to be restored in error case,
      // but keep it around just in case.
      _MDIChildSetWindow(x, y, width, height);
      if ( vertical ) {
         p_old_width = width;
      } else {
         p_old_height = height;
      }
      return status;
   }
   if ( restorePos ) {
      restore_pos(p);
   }

   int new_wid = p_window_id;

   if ( vertical ) {
      p_old_x = x + top_width;
      p_old_y = y;
      p_old_width = width - top_width;
      p_old_height = height;

      _no_resize = 1;
      p_window_id = orig_wid;
      _MDIChildSetWindow(x, y, top_width, height);
      p_old_x = x;
      p_old_y = y;
      p_old_width = top_width;
      p_old_height = height;
      p_window_id = new_wid;
      _no_resize = '';
   } else {
      p_old_x = x;
      p_old_y = y + top_height;
      p_old_width = width;
      p_old_height = height - top_height;

      _no_resize = 1;
      p_window_id = orig_wid;
      _MDIChildSetWindow(x, y, width, top_height);
      p_old_x = x;
      p_old_y = y;
      p_old_width = width;
      p_old_height = top_height;
      _no_resize = '';
   }

   p_window_id = new_wid;
   p_tile_id = tile_id;

   // All good
   return 0;
}

static int doTabgroupSplitWindow(boolean vertical, _str filename, boolean restorePos,boolean insertAfter)
{
   _no_resize = 1;
   if (def_one_file=='' && _mdi.p_child.p_window_state=='M') {
      _mdi.p_child.one_window();
   }
   save_pos(auto p);
   int status = load_files('+ih 'filename);
   _no_resize = '';

   if ( status ) {
      return status;
   }

   if ( vertical ) {
      _MDIChildNewVerticalTabGroup(_mdi.p_child,insertAfter);
   } else {
      _MDIChildNewHorizontalTabGroup(_mdi.p_child,insertAfter);
   }

   if ( restorePos ) {
      restore_pos(p);
   }

   // All good
   return 0;
}

/**
 * Splits the current window horizontally in half.
 * Optionally load buffer into split window.
 * 
 * @appliesTo Edit_Window
 * @categories Window_Functions
 * @param load_options
 *               Option to load buffer into split window. See
 *               load_files.
 * 
 * @return Returns 0 if successful.  Common return codes are
 *         TOO_MANY_WINDOWS_RC and TOO_MANY_SELECTIONS_RC.  On error, message is
 *         displayed.
 * @see vsplit_window
 */
_command hsplit_window(_str load_options = "") name_info(FILE_ARG'*,'VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if ( isEclipsePlugin() ) {
      _eclipse_split_window_horiz();
      return 0;
   }

   int apiflags = _default_option(VSOPTION_APIFLAGS);
   if ( !(apiflags & (VSAPIFLAG_ALLOW_TILED_WINDOWING | VSAPIFLAG_MDI_TABGROUPS)) ) {
      // Splitting not supported
      return 1;
   }

   int was_recording = _macro();
   _macro_delete_line();

   if ( command_state() && (_mdi.p_child.p_window_flags & HIDE_WINDOW_OVERLAP) ) {
      // In the middle of init_command_op()/retrieve_command_results()
      return 1;
   }

   _str filename = '+bi ':+_mdi.p_child.p_buf_id;
   boolean do_restore_pos = true;
   if ( load_options != '' ) {
      filename = load_options;
      do_restore_pos = false;
   }

   int orig_wid = 0;
   get_window_id(orig_wid);

   int status = 0;
   if ( (apiflags & VSAPIFLAG_MDI_TABGROUPS) ) {
      // Tabgroup split
      p_window_id = _MDICurrentChild(0);
      status = doTabgroupSplitWindow(false, filename, do_restore_pos,true);
   } else {
      // Tiled split
      p_window_id = _mdi.p_child;
      status = doTiledSplitWindow(false, filename, do_restore_pos);
   }
   if( status ) {
      return status;
   }

   if ( orig_wid == _cmdline ) {
      activate_window(orig_wid);
      _set_focus();
   }

   _macro('m', was_recording);
   _macro_call('hsplit_window');

   return 0;
}

/**
 * Splits the current window vertically in half.
 * 
 * @appliesTo Edit_Window
 * @categories Window_Functions
 * @param load_options
 *               Option to load buffer into split window. See
 *               load_files.
 * 
 * @return Returns 0 if successful.
 * @see hsplit_window
 */
_command vsplit_window(_str load_options = "") name_info(FILE_ARG'*,'VSARG2_READ_ONLY|VSARG2_CMDLINE|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if ( isEclipsePlugin() ) {
      _eclipse_split_window_vert();
      return(0);
   }

   int apiflags = _default_option(VSOPTION_APIFLAGS);
   if ( !(apiflags & (VSAPIFLAG_ALLOW_TILED_WINDOWING | VSAPIFLAG_MDI_TABGROUPS)) ){
      return 1;
   }

   int was_recording = _macro();
   _macro_delete_line();

   if ( command_state() && (_mdi.p_child.p_window_flags & HIDE_WINDOW_OVERLAP) ) {
      // In the middle of init_command_op()/retrieve_command_results()
      return 1;
   }

   _str filename = '+bi ':+_mdi.p_child.p_buf_id;
   boolean do_restore_pos = true;
   if ( load_options != '' ) {
      filename = load_options;
      do_restore_pos = false;
   }

   int orig_wid = 0;
   get_window_id(orig_wid);

   int status = 0;
   if ( (apiflags & VSAPIFLAG_MDI_TABGROUPS) ) {
      // Tabgroup split
      p_window_id = _MDICurrentChild(0);
      status = doTabgroupSplitWindow(true, filename, do_restore_pos,true);
   } else {
      // Tiled split
      p_window_id = _mdi.p_child;
      status = doTiledSplitWindow(true, filename, do_restore_pos);
   }
   if( status ) {
      return status;
   }

   if ( orig_wid == _cmdline ) {
      activate_window(orig_wid);
      _set_focus();
   }

   _macro('m',was_recording);
   _macro_call('vsplit_window');

   return 0;
}

_command void untile_windows() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_NOEXIT_SCROLL) {
   if (isEclipsePlugin()) {
      message("Command untile_windows not available from Eclipse");
      return;
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)
      ) {
      message("Command untile_windows not available");
      return;
   }
   _no_resize=1;
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      _MDICurrent()._tile_windows('U');
   } else {
      _mdi._tile_windows('U');
   }
   _no_resize='';
}
/**
 * Resizes and moves MDI edit windows so that they do not overlap.
 * 
 * @see cascade_windows
 * 
 * @categories Window_Functions
 * 
 */ 
_command void tile_windows(_str option="T") name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_NOEXIT_SCROLL)
{
   if (isEclipsePlugin()) {
      message("Command tile_windows not available from Eclipse");
      return;
   }
   if (upcase(option)=='U' 
       && !(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)
      ) {
      message("Untile command not available");
      return;
   }
   _no_resize=1;
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      _MDICurrent()._tile_windows(option);
   } else {
      // V acts like T in old MDI
      if (option=='T') {
         option='V';
      }
      _mdi._tile_windows(option);
   }
   _no_resize='';
}

/**
 * Arranges MDI edit windows to be cascaded (One below and right of the other).  
 * Does not effect MDI edit windows that are iconized.
 * 
 * @example
 *         _mdi._cascade_windows();
 * 
 * 
 * @appliesTo  MDI_Window
 * 
 * @categories Window_Functions
 */
_command void cascade_windows() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_NOEXIT_SCROLL)
{
   if (isEclipsePlugin()) {
      message("Command cascade_windows not available from Eclipse");
      return;
   }
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      message("Command cascade_windows not available.");
      return;
   }

   _no_resize=1;
   _mdi._cascade_windows();
   _no_resize='';

}
/**
 * Shrinks the current window by one row by lowering the top window 
 * border.  If there is no window above the current buffer window, the 
 * bottom window border is raised by one row.
 * 
 * @see expand_window
 * @see move_edge
 * @see delete_tile
 * @see create_tile
 * @see kill_window
 * @see hsplit_window
 * @see vsplit_window
 * @see change_window
 * @see window_left
 * @see window_right
 * @see window_above
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void shrink_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_NOEXIT_SCROLL)
{
   int view_id=0;
   if ( _tile_below(view_id)) {
      delete_tile('','','e',DOWN,UP);
   } else {
      delete_tile('','','e',UP,DOWN);
   }

}


/**
 * Increases the size of the current tile.  If the current window has no 
 * adjacent tile, an error is displayed.
 * 
 * @see shrink_window
 * @see move_edge
 * @see delete_tile
 * @see create_tile
 * @see kill_window
 * @see hsplit_window
 * @see vsplit_window
 * @see change_window
 * @see window_left
 * @see window_right
 * @see window_above
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo  Edit_Window
 * @categories Window_Functions
 */
_command void expand_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING)
{
   int view_id=0;
   if ( _tile_below(view_id)) {
      delete_tile('','','e',DOWN,DOWN);
   } else {
      delete_tile('','','e',UP,UP);
   }

}
/**
 * Moves the edge of a window.  The window edge to move is specified with 
 * the cursor keys.  The new edge position is specified by moving the cursor to 
 * the new edge position and pressing ENTER.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */
_command void move_edge() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING)
{
   delete_tile('','','e');
}

/**
 * Allows you to delete a window tile by pointing to the edge of the window 
 * you wish to delete with the cursor keys.
 * 
 * @param move_edge  '' to delete window, 'e' to move window
 * @param direction  UP, DOWN, LEFT, or RIGHT
 * @param start_key  UP, DOWN, LEFT, RIGHT, or ''
 * 
 * @return  0 if successful.  Common return codes are 1 (there 
 * is no window where the user pointed), and COMMAND_CANCELLED_RC. On error, 
 * message is displayed.
 * 
 * @appliesTo  Edit_Window
 * @categories Window_Functions
 */
_command delete_tile(typeless arg1='',
                     typeless arg2='',
                     typeless move_edge='',
                     typeless direction='',
                     typeless start_key=''
                    ) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  if (!isEclipsePlugin()) {
    int apiflags=_default_option(VSOPTION_APIFLAGS);
    if (!(apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING)){
      return 1;
    }
  }
  if (p_window_state=='M') {  /* Current window maximizes? */
      _message_box(nls("This operation is not supported when the window is maximized"));
      return(2);
   }
   int old_mouse_pointer=0;
   int mx=0, my=0;
   if (direction:=='') {
      mou_capture();
      mou_set_pointer(MP_SIZE);
      old_mouse_pointer=p_mouse_pointer;
      p_mouse_pointer=MP_SIZE;
      if (start_key:=='') {  // Moving edge? or deleting tile?
         mou_get_xy(mx,my);
         int child_x=0, child_y=0, child_width=0, child_height=0;
         _MDIChildGetWindow(child_x,child_y,child_width,child_height);
         int x=child_x+child_width intdiv 2;
         int y=child_y+child_height intdiv 2;
         _map_xy(_mdi,0,x,y);
         int add_x=0, add_y=0, add_width=0, add_height=0;
         _mdi._MDIClientGetWindow(add_x,add_y,add_width,add_height);
         x+=add_x;y+=add_y;
         mou_set_xy(x,y);
      }
   }
   _delete_tile2(arg1, arg2, move_edge, direction, start_key);
   if ( direction:=='' ) {
      p_mouse_pointer=old_mouse_pointer;
      mou_release();
      if (start_key:=='') {  // Moving edge? or deleting tile?
         mou_set_xy(mx,my);
      }
   }
}
static _str _delete_tile2(typeless arg1='',
                          typeless arg2='', 
                          typeless move_edge="",
                          typeless direction="",
                          typeless start_key="",
                          typeless quiet="")
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   _str msg='';
   if ( move_edge!='' ) {   /* move edge? */
      msg=nls('Point to window edge to move with cursor keys');
   } else {
      msg=nls('Point to window delete with cursor keys');
   }
   if ( direction:=='' ) {
      message(msg);
   }

   int window_x=0, window_y=0, window_width=0, window_height=0;
   int window_x2=0, window_y2=0, window_width2=0, window_height2=0;
   int edge_x1=0, edge_x2=0, edge_y1=0, edge_y2=0;
   typeless view_id=0;

   typeless key='';
   int tile_id=p_tile_id;
   boolean do_move_edge=move_edge!='';
   boolean join_with_next=false;
   for (;;) {
     key=direction;
     if ( key:=='' ) {
        key=get_event();
     }
     if ( iscancel(key) ) {
       cancel();
       return(COMMAND_CANCELLED_RC);
     }
     key=cv_key(key);
     _MDIChildGetWindow(window_x,window_y,window_width,window_height);
     if ( key:==LEFT ) {
        if (isEclipsePlugin()) {
           _eclipse_delete_window("LEFT");
           return 0;
        }
        edge_x1=window_x;edge_y1=window_y;
        edge_x2=edge_x1;edge_y2=window_y+window_height;
        if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
           view_id=_MDINextDocumentWindow(p_window_id,'L',do_move_edge);
        } else {
           view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
        }
        if ( view_id!=0) {
          activate_window(view_id);
          _MDIChildGetWindow(window_x2,window_y2,window_width2,window_height2);
          activate_window(orig_view_id);
          if ( do_move_edge ) {
            if ( select_new_size(view_id,'L',edge_x1,edge_y1,edge_x1,edge_y2,
                                 'V',window_x2,
                                 window_y2+(window_height intdiv 2),
                                 window_x+window_width,
                                 window_y2+(window_height intdiv 2),
                                 start_key,key) ) {
               return(1);
            }
          } else if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
             _no_resize=1;
             maybe_zoom_window(window_x2,window_y,window_width2+window_width,window_height);
             /* _move_window window_x2,window_y,window_width2+window_width,window_height */
             _no_resize='';
          }
        }
        join_with_next=true;
        break;
     } else if ( key:==RIGHT ) {
        if (isEclipsePlugin()) {
           _eclipse_delete_window("RIGHT");
           return 0;
        }
        edge_x1=window_x+window_width;edge_y1=window_y;
        edge_x2=edge_x1;edge_y2=window_y+window_height;
        if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
           view_id=_MDINextDocumentWindow(p_window_id,'R',do_move_edge);
        } else {
           view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
        }
        if ( view_id!=0) {
          activate_window(view_id);
          _MDIChildGetWindow(window_x2,window_y2,window_width2,window_height2);
          activate_window(orig_view_id);
          if ( do_move_edge ) {
            if ( select_new_size(view_id,'R',edge_x1,edge_y1,edge_x1,edge_y2,
                                 'V',window_x,
                                 window_y2+(window_height intdiv 2),
                                 window_x2+window_width2,
                                 window_y2+(window_height intdiv 2),
                                 start_key,key)) {
               return(1);
            }

          } else if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
             _no_resize=1;
             maybe_zoom_window(window_x,window_y,window_width2+window_width,window_height);
             /* _MDIChildSetWindow window_x,window_y,window_width2+window_width,window_height */
             _no_resize='';
          }
        }
        break;
     } else if ( key:==UP ) {
        if (isEclipsePlugin()) {
           _eclipse_delete_window("UP");
           return 0;
        }
        edge_x1=window_x;edge_y1=window_y;
        edge_x2=window_x+window_width;edge_y2=edge_y1;
        if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
           view_id=_MDINextDocumentWindow(p_window_id,'A',do_move_edge);
        } else {
           view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
        }
        if ( view_id!=0) {
          activate_window(view_id);
          _MDIChildGetWindow(window_x2,window_y2,window_width2,window_height2);
          activate_window(orig_view_id);
          if ( do_move_edge ) {
            if ( select_new_size(view_id,'A',edge_x1,edge_y1,edge_x1,edge_y2,
                                 'H',
                                 window_x+(window_width%2),
                                 window_y2,
                                 window_x+(window_width%2),
                                 window_y+window_height,
                                 start_key,key)) {
               return(1);
            }
          } else if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
             _no_resize=1;
             maybe_zoom_window(window_x,window_y2,window_width,window_height2+window_height);
             /* _MDIChildSetWindow window_x,window_y2,window_width,window_height2+window_height */
             _no_resize='';
          }
        }
        join_with_next=true;
        break;
     } else if ( key:==DOWN ) {
        if (isEclipsePlugin()) {
           _eclipse_delete_window("DOWN");
           return 0;
        }
        edge_x1=window_x;edge_y1=window_y+window_height;
        edge_x2=window_x+window_width;edge_y2=edge_y1;
        if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
           view_id=_MDINextDocumentWindow(p_window_id,'B',do_move_edge);
        } else {
           view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
        }

        if ( view_id!=0) {
          activate_window(view_id);
          _MDIChildGetWindow(window_x2,window_y2,window_width2,window_height2);
          activate_window(orig_view_id);
          if ( do_move_edge ) {
            if ( select_new_size(view_id,'B',edge_x1,edge_y1,edge_x1,edge_y2,
                                 'H',
                                 window_x+(window_width%2),
                                 window_y,
                                 window_x+(window_width%2),
                                 window_y2+window_height2,
                                 start_key,key)) {
               return(1);
            }
          } else if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)) {
             _no_resize=1;
             maybe_zoom_window(window_x,window_y,window_width,window_height2+window_height);
             /* _MDIChildSetWindow window_x,window_y,window_width,window_height2+window_height */
             _no_resize='';
          }
        }
        break;
     }
   }
   if ( view_id==0) {
      if ( quiet=='' ) {
        message(nls('There is no window over there'));
      }
     return(1);
   }
    if ( move_edge=='' ) {
      /* delete window case */
      activate_window(view_id);
      int mdi_wid=0;
      
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) ) {
         _str option=_default_option(VSOPTION_JOIN_WINDOW_WITH_NEXT);
         _default_option(VSOPTION_JOIN_WINDOW_WITH_NEXT,join_with_next);
         mdi_wid=_MDIFromChild(p_window_id);
         _delete_window();
         _default_option(VSOPTION_JOIN_WINDOW_WITH_NEXT,option);
      } else {
         _delete_window();
      }
      activate_window(orig_view_id);
      _maybe_maximize_window(mdi_wid);
   }
   if ( direction:=='' ) clear_message();
   return(0);
}

static _str select_new_size(int view_id,_str letter_edge,
                            int edge_x1,int edge_y1,int edge_x2,int edge_y2,
                            _str edge_option,
                            int x1,int y1,int x2,int y2,
                            _str start_key,_str key)
{

   int font_width=p_font_width;
   int font_height=p_font_height;

   int x= (edge_x1+edge_x2) intdiv 2;
   int y= (edge_y1+edge_y2) intdiv 2;
   int check_y=0;
   int check_x=0;
   if ( x1==x2 ) {
      x=x1;check_y=1;
   }
   if ( y1==y2 ) {
      y=y1;check_x=1;

   }

   int child_x=0, child_y=0, child_width=0, child_height=0;
   int add_x=0, add_y=0, junk1=0, junk2=0;
   int mx=0, my=0;
   int rect_x1=0, rect_y1=0;
   int rect_x2=0, rect_y2=0;
   int color=0;
   typeless draw_setup='';

   if ( start_key=='') {
      font_width=10;
      font_height=10;
      _MDIChildGetWindow(child_x,child_y,child_width,child_height);
      switch (letter_edge) {
      case 'A':  // Window above
         p_mouse_pointer=MP_SIZENS;
         my=child_y;mx=child_x+child_width intdiv 2;
         break;
      case 'B':  // Window below
         my=child_y+child_height;mx=child_x+child_width intdiv 2;
         p_mouse_pointer=MP_SIZENS;
         break;
      case 'L':  // Left Window
         mx=child_x;my=child_y+child_height intdiv 2;
         p_mouse_pointer=MP_SIZEWE;
         break;
      case 'R':  // Right Window
         mx=child_x+child_width;my=child_y+child_height intdiv 2;
         p_mouse_pointer=MP_SIZEWE;
         break;
      }
      mou_set_pointer(p_mouse_pointer);
      _map_xy(_mdi,0,mx,my);
      _mdi._MDIClientGetWindow(add_x,add_y,junk1,junk2);
      mx+=add_x;my+=add_y;
      mou_set_xy(mx,my);

      _MDIChildGetWindow(child_x,child_y,child_width,child_height);
      rect_x1=child_x;rect_y1=child_y;

      _mdi._MDIClientGetWindow(add_x,add_y,junk1,junk2);
      rect_x1+=add_x;rect_y1+=add_y;

      rect_x2=rect_x1+child_width;rect_y2=rect_y1+child_height;

      message(nls('Move to new edge position and press ENTER'));
      /* refresh;set_cursor_xy x,y */
   }

   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      boolean before=key:==LEFT || key:==UP;
      boolean horizontal=key:==LEFT || key:==RIGHT;
      if (horizontal) {
         font_height=font_width;
      }
      mou_mode(1);
      for (;;) {
        key=start_key;
        if ( key:=='' ) {
           key=get_event();
        }
        if ( key:==LEFT && horizontal) {
           if (before) {
              mx-=_MDIChangeDocumentWindowSize(p_window_id,font_height,before);
           } else {
              mx+=_MDIChangeDocumentWindowSize(p_window_id,-font_height,before);
           }
        } else if ( key:==RIGHT && horizontal) {
           if (before) {
              mx-=_MDIChangeDocumentWindowSize(p_window_id,-font_height,before);
           } else {
              mx+=_MDIChangeDocumentWindowSize(p_window_id,font_height,before);
           }
        } else if ( key:==DOWN && !horizontal) {
           if (before) {
              my-=_MDIChangeDocumentWindowSize(p_window_id,-font_height,before);
           } else {
              my+=_MDIChangeDocumentWindowSize(p_window_id,font_height,before);
           }
        } else if ( key:==UP && !horizontal) {
           if (before) {
              my-=_MDIChangeDocumentWindowSize(p_window_id,font_height,before);
           } else {
              my+=_MDIChangeDocumentWindowSize(p_window_id,-font_height,before);
           }
        } else if ( key:==ENTER ) {
           break;
        } else if ( iscancel(key) ) {
           cancel();
           mou_mode(0);
           return(1);
        }
        if ( start_key:!='' ) break;
        mou_set_xy(mx,my);
      }
      if (start_key=='') clear_message();
      mou_mode(0);
      return 0;
   }

   mou_mode(1);
   for (;;) {
     key=start_key;
     if ( key:=='' ) {
        key=get_event();
     }
     if ( key:==LEFT ) {
        if (point_on_edge(x-font_width,y,x1,y1,x2,y2) ) {
           if (start_key=='') {
              if (letter_edge=='L') {
                 rect_x1-=font_height;
              } else {
                 rect_x2-=font_height;
              }
              mx-=font_width;
              mou_set_xy(mx,my);
           }
           x-=font_width;
           /* set_cursor_xy x,y */
        }
     } else if ( key:==RIGHT ) {
        if ( point_on_edge(x+font_width,y,x1,y1,x2,y2) ) {
           if (start_key=='') {
              if (letter_edge=='L') {
                 rect_x1+=font_height;
              } else {
                 rect_x2+=font_height;
              }
              mx+=font_width;
              mou_set_xy(mx,my);
           }
           x+=font_width;
           /* set_cursor_xy x,y */
        }
     } else if ( key:==DOWN ) {
        if (point_on_edge(x,y+1,x1,y1,x2,y2) ) {
           if (start_key=='') {
              if (letter_edge=='A') {
                 rect_y1+=font_height;
              } else {
                 rect_y2+=font_height;
              }
              my+=font_height;
              mou_set_xy(mx,my);
           }
           y+=font_height;
           /* set_cursor_xy x,y */
        }
     } else if ( key:==UP ) {
        if (point_on_edge(x,y-font_height,x1,y1,x2,y2) ) {
           if (start_key=='') {
              if (letter_edge=='A') {
                 rect_y1-=font_height;
              } else {
                 rect_y2-=font_height;
              }
              my-=font_height;
              mou_set_xy(mx,my);
           }
           y-=font_height;
           /* set_cursor_xy x,y */
        }
     } else if ( key:==ENTER ) {
        break;
     } else if ( iscancel(key) ) {
        cancel();
        mou_mode(0);
        return(1);
     }
     if ( start_key:!='' ) break;
   }
   if (start_key=='') clear_message();
   mou_mode(0);
   return(set_new_size(view_id,letter_edge,x,y));
}
static _str set_new_size(int view_id,_str letter_edge,int x,int y)
{
   int tile_id=p_tile_id;
   int orig_view_id=0;
   get_window_id(orig_view_id);
   int window_x, window_y, window_width, window_height;
   _MDIChildGetWindow(window_x,window_y,window_width,window_height);
   int smallest_height=p_height-p_client_height+p_font_height;
   int smallest_width=p_width-p_client_width+p_font_width;
   int client_height=p_client_height;
   activate_window(view_id);
   int window_x2, window_y2, window_width2, window_height2;
   _MDIChildGetWindow(window_x2,window_y2,window_width2,window_height2);
   int client_height2=p_client_height;
   int new_x=0, new_y=0, new_width=0, new_height=0;
   int new_x2=0, new_y2=0, new_width2=0, new_height2=0;
   activate_window(orig_view_id);
   letter_edge=upcase(letter_edge);
   switch (letter_edge) {
   case 'A':   /* current window and window above. */
      /* y is start of this window. */
      new_x=window_x;new_y=y;
      new_width=window_width;new_height=window_height+window_y-y;

      new_x2=window_x2;new_y2=window_y2;
      new_width2=window_width2;new_height2=y-window_y2;
      break;
   case 'B':   /* current window and window below. */
      /* y is start of window below. */

      new_x=window_x;new_y=window_y;
      new_width=window_width;new_height=y-window_y;

      new_x2=window_x2;new_y2=y;
      new_width2=window_width2;new_height2=window_height2+window_y2-y;


      break;
   case 'L':   // current window and to left
      /* x is start of this window. */
      new_x=x;new_y=window_y;
      new_height=window_height;
      new_width=window_width+window_x-x;

      new_x2=window_x2;new_y2=window_y2;
      new_height2=window_height2;
      new_width2=x-window_x2;
      break;
   case 'R':   /* current window and window to right. */
      /* x is start of window to right. */

      new_x=window_x;new_y=window_y;
      new_height=window_height;
      new_width=x-window_x;

      new_x2=x;new_y2=window_y2;
      new_height2=window_height2;
      new_width2=window_width2+window_x2-x;
      break;
   }
   if (letter_edge=='L' || letter_edge=='R') {
      if (new_width2<smallest_width || new_width<smallest_width) {
         _message_box(nls('Window too small'));
         return(1);
      }
   }
   if (letter_edge=='A' || letter_edge=='B') {
      if (new_height2<smallest_height || new_height<smallest_height) {
         _message_box(nls('Window too small'));
         return(1);
      }
   }
   _no_resize=1;
   _MDIChildSetWindow(new_x,new_y,new_width,new_height);
   activate_window(view_id);
   _MDIChildSetWindow(new_x2,new_y2,new_width2,new_height2);
   _no_resize='';
   activate_window(orig_view_id);
   return(0);
}

static int _tile_below(int &view_id,boolean move_or_close=false)
{
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      view_id=_MDINextDocumentWindow(p_window_id,'B',move_or_close);
      return view_id;
   }
   /* IF there is not a window above. */
   int window_x, window_y, window_width, window_height;
    _MDIChildGetWindow(window_x,window_y,window_width,window_height);
   int edge_x1=window_x;
   int edge_y1=window_y+window_height;
   int edge_x2=window_x+window_width;
   int edge_y2=edge_y1;
   view_id=find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
   return(view_id);
}
static int _tile_above(int &view_id,boolean move_or_close=false)
{
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      view_id=_MDINextDocumentWindow(p_window_id,'A',move_or_close);
      return view_id;
   }
   /* IF there is not a window above. */
   int window_x, window_y, window_width, window_height;
    _MDIChildGetWindow(window_x,window_y,window_width,window_height);
   int edge_x1=window_x;
   int edge_y1=window_y;
   int edge_x2=window_x+window_width;
   int edge_y2=edge_y1;
   view_id=find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);

   return(view_id);
}
int _tile_left(int &view_id,boolean move_or_close)
{
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      view_id=_MDINextDocumentWindow(p_window_id,'L',move_or_close);
      return view_id;
   }
   /* IF there is not a window above. */
   int window_x, window_y, window_width, window_height;
    _MDIChildGetWindow(window_x,window_y,window_width,window_height);
   int edge_x1=window_x;
   int edge_y1=window_y;
   int edge_x2=edge_x1;
   int edge_y2=window_y+window_height;
   view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
   return(view_id);
}
int _tile_right(int &view_id,boolean move_or_close)
{
   if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
      view_id=_MDINextDocumentWindow(p_window_id,'R',move_or_close);
      return view_id;
   }
   /* IF there is not a window above. */
   int window_x, window_y, window_width, window_height;
    _MDIChildGetWindow(window_x,window_y,window_width,window_height);
   int edge_x1=window_x+window_width;
   int edge_y1=window_y;
   int edge_x2=edge_x1;
   int edge_y2=window_y+window_height;
   view_id= find_window_with_edge(edge_x1,edge_y1,edge_x2,edge_y2);
   return(view_id);
}
/**
 * Used in EMACS emulation.  Deletes the current window.
 * 
 * @see shrink_window
 * @see move_edge
 * @see delete_tile
 * @see create_tile
 * @see hsplit_window
 * @see vsplit_window
 * @see change_window
 * @see window_left
 * @see window_right
 * @see window_above
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Edit_Window_Methods
 * 
 */
_command kill_window() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (p_window_state=='M') {  /* Current window maximized? */
      _delete_window();
      return(2);
   }
   int view_id=0;
   if ( _tile_below(view_id,true)) {
      activate_window(view_id);
      delete_tile('','','',UP);
   } else if ( _tile_above(view_id,true)) {
      activate_window(view_id);
      delete_tile('','','',DOWN);
   } else if ( _tile_left(view_id,true)) {
      activate_window(view_id);
      delete_tile('','','',RIGHT);
   } else if ( _tile_right(view_id,true)) {
      activate_window(view_id);
      delete_tile('','','',LEFT);
   }
}
static void zap_iconized_tile_ids(int tile_id)
{
  int first_window_id=p_window_id;
  /* for each window in the active ring of windows. */
  int view_id=0;
  get_window_id(view_id);
  for (;;) {
    _next_window('HR');
    if ( p_window_id== first_window_id ) {
      return;
    }
    if ( p_window_state=='I' && tile_id==p_tile_id ) {
       p_tile_id=_create_tile_id();
    }
  }
}

/** 
 * @return  If successful, the view id of the window with edge 
 * (<i>x1</i>,<i>y1</i>) to (<i>x2</i>,<i>y2) and the same tile id 
 * (<b>p_tile_id</b>) as the current window is returned. 
 * Otherwise, 0 is returned. 
 * 
 * @appliesTo  Edit_Window
 * @categories Window_Functions
 */
static int find_window_with_edge(int x1,int y1,int x2,int y2)
{
  int first_window_id=p_window_id;
  int tile_id=p_tile_id;
  /* for each window in the active ring of windows. */
  int view_id=0;
  get_window_id(view_id);
  for (;;) {
    _next_window('HR');
    if ( p_window_id== first_window_id ) {
      return(0);
    }
    // Can't seem to adjust iconized windows.
    // Not sure where the bug is.
    if ( p_window_state!='I' && window_has_edge(x1,y1,x2,y2) && tile_id==p_tile_id ) {
      int result=0;
      get_window_id(result);
      activate_window(view_id);
      return(result);
    }
  }
  return(0);
}

static _str window_has_edge(int x1,int y1,int x2,int y2)
{
  /* top left corner the same? */
   int window_x, window_y, window_width, window_height;
  _MDIChildGetWindow(window_x,window_y,window_width,window_height);
  if ( x1==window_x && y1==window_y ) {
    /* check left edge */
    if ( x2==window_x+window_width && y2==window_y ) { return(1); }
    /* check top edge */
    if ( x2==window_x && y2==window_y +window_height ) { return(1); }
  } else if ( x2==window_x+window_width && y2==window_y+window_height ) {
    /* check left edge */
    if ( x1==window_x+window_width && y1==window_y ) { return(1); }
    /* check bottom edge */
    //say("x1="x1" wx="window_x" y1="y1 " wy="window_y" wheight="window_height);
    if ( x1==window_x && y1==window_y +window_height ) {
       //say('bottom edge');
       return(1);
    }
  }
  return(0);
}


static _str cv_key(_str key)
{
    _str name = name_on_key(key);
    if ( name=='cursor-left' ) {
       key=LEFT;
    } else if ( name=='cursor-right' ) {
       key=RIGHT;
    } else if ( name=='cursor-down' ) {
       key=DOWN;
    } else if ( name=='cursor-up' ) {
       key=UP;
    }
    return(key);
}


/**
 * Switches to window to the left of the current window if one exists.
 * 
 * @see window_above
 * @see window_right
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void window_left() name_info(','VSARG2_READ_ONLY|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
   if (isEclipsePlugin()) {
       _eclipse_change_window("LEFT");
   } else {
       int apiflags=_default_option(VSOPTION_APIFLAGS);
       if (!(apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING)){
          return;
       }
       change_window('','',LEFT);
   }
}

/**
 * Switches to window to the right of the current window if one exists.
 * 
 * @see window_above
 * @see window_left
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Window_Functions
 * 
 */ 
_command void window_right() name_info(','VSARG2_READ_ONLY|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
    if (isEclipsePlugin()) {
        _eclipse_change_window("RIGHT");
    } else {
        int apiflags=_default_option(VSOPTION_APIFLAGS);
        if (!(apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING)){
           return;
        }
        change_window('','',RIGHT);
    }
}

/**
 * Switches to window above the current window if one exists.
 * 
 * @see window_left
 * @see window_right
 * @see window_below
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void window_above() name_info(','VSARG2_READ_ONLY|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_NOEXIT_SCROLL)
{
    if (isEclipsePlugin()) {
        _eclipse_change_window("UP");
    } else {
        int apiflags=_default_option(VSOPTION_APIFLAGS);
        if (!(apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING)){
           return;
        }
        change_window('','',UP);
    }
}

/**
 * Switches to window below the current window if one exists.
 * 
 * @see window_left
 * @see window_right
 * @see window_above
 * @see next_window
 * @see prev_window
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 * 
 */ 
_command void window_below() name_info(','VSARG2_READ_ONLY|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
    if (isEclipsePlugin()) {
        _eclipse_change_window("DOWN");
    } else {
        int apiflags=_default_option(VSOPTION_APIFLAGS);
        if (!(apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING)){
           return;
        }
        change_window('','',DOWN);
    }
}

/**
 * Allows you to point with the cursor keys to the window you wish to change to.
 * 
 * @param direction  UP, DOWN, LEFT, or RIGHT
 * 
 * @return 0 if successful.  Otherwise 1 is returned indicating user cancelled
 *         or there is no window where the user pointed.  On error, message is displayed.
 * 
 * @see next_window
 * @see _prev_window
 * @see move_edge
 * @see window_left
 * @see window_right
 * @see window_above
 * @see window_below
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Window_Functions
 */
_command int change_window(typeless arg1="",
                           typeless arg2="",
                           typeless direction=""
                          ) name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_TILED_WINDOWING)
{
   _macro_delete_line();
   if (p_window_state=='M') {  // Current window maximizes?
      _message_box(nls("Can't change window when window is maximized"));
      return 2;
   }
   int old_mouse_pointer=0;
   int x=0, y=0, mx=0, my=0;
   int child_x=0, child_y=0, child_width=0, child_height=0;
   int add_x=0, add_y=0, junk1=0, junk2=0;
   if (direction=='') {
      mou_capture();
      mou_set_pointer(MP_SIZE);
      old_mouse_pointer=p_mouse_pointer;
      p_mouse_pointer=MP_SIZE;
      mou_get_xy(mx,my);

      _mdi.p_child._MDIChildGetWindow(child_x,child_y,child_width,child_height);
      x=child_x+child_width intdiv 2;
      y=child_y+child_height intdiv 2;
      _map_xy(_mdi,0,x,y);
      _mdi._MDIClientGetWindow(add_x,add_y,junk1,junk2);
      x+=add_x;y+=add_y;
      mou_set_xy(x,y);
   }
   typeless key = direction;
   int window_x, window_y, window_width, window_height;
   _mdi.p_child._MDIChildGetWindow(window_x,window_y,window_width,window_height);
   _str wid = "";
   for (;;) {
      if ( key == "" ) {
         message(nls('Point to window edge to change to with cursor keys'));
         key=get_event();
      }
      if ( iscancel(key) ) {
         cancel();
         if (direction=='') {
            p_mouse_pointer=old_mouse_pointer;
            mou_release();
            mou_set_xy(mx,my);
         }
         return 1;
      }
      key=cv_key(key);
      if ( key:==LEFT ) {
         if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
            wid=_MDINextDocumentWindow(p_window_id,'L',false);
         } else {
            wid=find_window_with_point(window_x,window_y+p_cursor_y+1);
         }
         _macro_call('window_left');
      } else if ( key:==RIGHT ) {
         if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
            wid=_MDINextDocumentWindow(p_window_id,'R',false);
         } else {
            wid=find_window_with_point(window_x+window_width,window_y+p_cursor_y+1);
         }
        _macro_call('window_right');
      } else if ( key:==DOWN ) {
         if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
            wid=_MDINextDocumentWindow(p_window_id,'B',false);
         } else {
            wid=find_window_with_point(window_x+p_cursor_x+1,window_y+window_height);
         }
        _macro_call('window_below');
      } else if ( key:==UP ) {
         if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) {
            wid=_MDINextDocumentWindow(p_window_id,'A',false);
         } else {
            wid=find_window_with_point(window_x+p_cursor_x+1,window_y);
         }
        _macro_call('window_above');
      } else {
         // Still waiting for LEFT/RIGHT/UP/DOWN
         // Force prompt
         key="";
         continue;
      }
      if( wid == "") {
         // Failed to find a window adjacent and contiguous to this one
         // with the same tile id, so try for the closest window to our
         // current position.
         wid=find_window_closest_to_point(key);
      }
      break;
   }
   if (direction=='') {
      p_mouse_pointer=old_mouse_pointer;
      mou_release();
      mou_set_xy(mx,my);
   }
   if ( wid=="" || wid==0 ) {
      message(nls('There is no window over there'));
      return 1;
   }
   activate_window((int)wid);
   _set_focus();
   clear_message();
   return 0;
}

/** 
 * @return  If successful, the view id of the window with point 
 * (<i>x</i>,<i>y) on window edge and the same tile id (<b>p_tile_id</b>) as the 
 * current window is returned.  Otherwise, '' is returned.
 * 
 * @appliesTo  Edit_Window
 * @categories Window_Functions
 */
static _str find_window_with_point(int x,int y)
{
   int first_window_id=p_window_id;
   int tile_id=p_tile_id;
   int view_id=0;
   get_window_id(view_id);
   for (;;) {
      _next_window('HR');
      if ( p_window_id==first_window_id ) {
         return('');
      }
      if ( tile_id==p_tile_id && point_on_window_edge(x,y)) {
         int result=0;
         get_window_id(result);
         activate_window(view_id);
         return(result);
      }
   }
}

/**
 * Find the window that is closest to current cursor position in
 * the direction indicated (LEFT, RIGHT, UP, DOWN).
 * 
 * @return  If found, the window id of the window closest to the
 * current cursor position; otherwise 0 is returned.
 * 
 * @appliesTo  Edit_Window
 * @categories Window_Functions
 */
static int find_window_closest_to_point(int direction)
{
   int first_window_id = p_window_id;
   int tile_id = p_tile_id;
   int wid = first_window_id;

   int window_x, window_y, window_width, window_height;
   _mdi.p_child._MDIChildGetWindow(window_x,window_y,window_width,window_height);

   // Locate the cursor on the window
   int cursor_x = window_x + p_cursor_x;
   int cursor_y = window_y + p_cursor_y;

   // Only return a window id when we have a window to move to
   int best_window_id = 0;
   int best_window_distance = MAXINT;

   for( ;; ) {
      _next_window('HR');

      if( first_window_id == p_window_id ) {
         break;
      }

      _MDIChildGetWindow(window_x,window_y,window_width,window_height);

      // If this window has content that overlaps the current cursor position, we can simply select it
      if( ( cursor_y > window_y ) && ( cursor_y < ( window_y + window_height ) ) ) {
         if( ( window_x < cursor_x ) && ( ( window_x + window_width ) > cursor_x ) ) {
            /* we have a window with content at our cursor position, we're done */
            get_window_id(best_window_id);
            activate_window(wid);
            return(best_window_id);
         }
      }

      if( direction == LEFT || direction == RIGHT ) {
         // If we want to consider this window, it must have content to the left of our cursor

         // Is our cursor within vertical extent of window?
         if( cursor_y >= window_y && cursor_y < (window_y+window_height) ) {
            int distance;
            if( direction == LEFT ) {
               distance = cursor_x - ( window_x + window_width );
            } else {
               // RIGHT
               distance = window_x - cursor_x;
            }
            if( distance >= 0 && distance < best_window_distance ) {
               get_window_id( best_window_id );
               best_window_distance = distance;
            }
         }
      } else if( ( direction == UP ) || ( direction == DOWN ) ) {
         // If we want to consider this window, it must have content above our cursor

         // Is our cursor within horizontal extent of window?
         if( cursor_x >= window_x && cursor_x < (window_x+window_width) ) {
            int distance;
            if( direction == UP ) {
               distance = cursor_y - ( window_y + window_height );
            } else {
               // DOWN
               distance = window_y - cursor_y;
            }
            if( distance >= 0 && distance < best_window_distance ) {
               get_window_id( best_window_id );
               best_window_distance = distance;
            }
         }
      }
   }

   activate_window(wid);
   return best_window_id;
}

static boolean point_on_window_edge(int x,int y)
{
   int window_x, window_y, window_width, window_height;
  _MDIChildGetWindow(window_x,window_y,window_width,window_height);
  if ( point_on_edge(x,y,window_x,window_y,
                   window_x+window_width ,window_y) ||
     point_on_edge(x,y,window_x,window_y,
                   window_x,window_y +window_height) ||
     point_on_edge(x,y,window_x+window_width,window_y,
                   window_x+window_width,window_y+window_height) ||
     point_on_edge(x,y,window_x,window_y +window_height,
                   window_x+window_width,window_y+window_height) ) {
     return true;
  }
  return false;
}

/**
 * @return true if (x,y) is a point on the edge (x1, y1) to (x2, y2).
 * 
 * @categories Window_Functions
 */ 
boolean point_on_edge(int x, int y, int x1, int y1, int x2, int y2)
{
   if( x1==x2 && x==x1 && y>=y1 && y<=y2 ) {
      return true;
   }
   if( y1==y2 && y==y1 && x>=x1 && x<=x2 ) {
      return true;
   }
   return false;
}

void _get_max_window(int &x,int &y,int &width,int &height)
{
   _mdi._MDIClientGetWindow(x,y,width,height);
   x=0;
   y=0;
}
