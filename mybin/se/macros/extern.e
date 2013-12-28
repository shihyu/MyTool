////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45237 $
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
#import "files.e"
#import "main.e"
#import "optionsxml.e"
#import "recmacro.e"
#import "stdprocs.e"
#endregion

#if 0
_command page()
{
   return(external_command('page'));
}
#endif
/**
 * Opens the file "asciitab" which contains a table of the ASCII characters 
 * with the corresponding hex and decimal character codes.
 * 
 * @return Returns 0 if successful
 * @categories Miscellaneous_Functions
 */
_command ascii_table() name_info(','VSARG2_REQUIRES_MDI)
{
   _str ascii_tab=(__PCDOS__)?'asciitab':'asciitab.u';
   _str filename=slick_path_search(ascii_tab);
   if ( filename=='' ) {
      _message_box(nls("File '%s' not found",ascii_tab));
      return(FILE_NOT_FOUND_RC);
   }
   return(edit('"-*read_only_mode 1" +66 'maybe_quote_filename(filename),EDIT_NOADDHIST));
}
#if __EBCDIC__
// Returns 0 if successful
_command ebcdic_table() name_info(','VSARG2_REQUIRES_MDI)
{
   ebcdic_tab='ebcdictb.u';
   filename=slick_path_search(ebcdic_tab);
   if ( filename=='' ) {
      _message_box(nls("File '%s' not found",ebcdic_tab));
      return(FILE_NOT_FOUND_RC);
   }
   return(edit('+66 'maybe_quote_filename(filename),EDIT_NOADDHIST));
}
#endif


int _OnUpdate_color(CMDUI &cmdui,int target_wid,_str command)
{
   if (_jaws_mode()) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

/** 
 * Displays the <b>Color Settings dialog box</b> which is used
 * to change the default colors.  Select the screen element.
 * Then set the foreground and background colors and press the
 * Apply or OK button.  The Apply button updates the colors you
 * have modified without closing the dialog box.
 * <pre>
 * <b>   Screen Element</b>   Select the screen element before changing the foreground and background colors.  Most of the screen element items are obvious except for the Cursor screen element.  The Cursor Screen Element is displayed in the active edit window when the cursor is placed on the SlickEdit command line.  It is not the color of the blinking cursor (wish we could change this color).
 * <b>   Apply</b>            Updates all modified screen elements.  The dialog box is not closed.
 * <b>   Reset</b>            Restores all colors to the values they were when the editor was invoked.
 * <b>   Cancel</b>           Restores all colors to the values they were when the colors dialog box was displayed.
 * </pre>
 * 
 * @categories Miscellaneous_Functions
 */
_command void color() name_info(COLOR_FIELD_ARG',')
{
   _macro_delete_line();
   config('_color_form', 'D');
}
#if 0
_command setupkbd()
{
   shell('setupkbd');
   return(rc);

}
#endif

/**
 * Batch program which draws lines as you press the cursor keys.  To call a 
 * batch program from a Slick-C&reg; macro, quote the command line.  For example, 
 * the statement <b>"draw 1"</b> including quotes.  From the command line no 
 * quotes are necessary.
 * <pre>
 * Argument description
 *   1   Single line top/bottom sides and left/right sides.
 *   2   Double line top/bottom sides and left/right sides.
 *   3   Single line sides and double line top/bottom sides.
 *   4   Double line sides and single line top/bottom sides.
 *   B   Draw with blank character.  Used to erase drawing.
 * Any character  Any character may be used as the draw character.
 * </pre>
 * @appliesTo  Edit_Window
 * @categories Miscellaneous_Functions
 */
_command draw(...) name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   shell('draw 'arg(1));
   return(rc);

}


_command external_command(_str a="")
{
   _str name='';
   shell(a);
   parse a with name .;
   if ( rc==FILE_NOT_FOUND_RC ) {
      message(nls("External macro or program '%s' not found",name));
   } else if ( isinteger(rc) && rc<0 ) {
      message(nls("Error executing macro or program '%s'",name)".  "get_message(rc));
   }
   return(rc);
}
/**
 * The <b>gui_draw</b> command is used to draw lines in the current buffer 
 * using the PCDOS graphics characters.  Line drawing characters are not 
 * available under most UNIX systems.  The Draw Lines dialog box is displayed 
 * which prompts you for a box character set.  You will want to use the OEM 
 * Fixed Font (default) in order to view the graphic characters.  Under UNIX, we 
 * don't know which font if any supports the line drawing characters.
 * 
 * @see draw
 * @see box
 *
 * @categories Miscellaneous_Functions
 * 
 */
_command void gui_draw() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   typeless result = show('-modal _draw_form');
   if (result=='') {
      return;
   }
   _macro('m',_macro('s'));
   _macro_call('draw',result);
   draw(result);
}

defeventtab _draw_form;

//12:02pm 8/27/1997
//Added this so that there are not uninitiallized radio buttons
_ok.on_create()
{
   _sl.p_value=1;
}

_ok.lbutton_up()
{
   if (_sl.p_value) {
      p_active_form._delete_window(1);
      return(1);
   }
   if (_dl.p_value) {
      p_active_form._delete_window(2);
      return(2);
   }
   if (_hdl.p_value) {
      p_active_form._delete_window(3);
      return(3);
   }
   if (_vdl.p_value) {
      p_active_form._delete_window(4);
      return(4);
   }
   if (_ascii.p_value) {
      p_active_form._delete_window('A');
      return('A');
   }
   if (_blank.p_value) {
      p_active_form._delete_window('B');
      return('B');
   }
}
