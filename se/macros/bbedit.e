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
#import "optionsxml.e"
#import "util.e"
#endregion

/*
   BBEdit emulation macro
*/

_command void mac_preferences()
{
   show_general_options(0);
}

_command int bbedit_file_new_html() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   cmdline := "+t";
   p_window_id = _mdi._edit_window();
   int result = edit(cmdline);
   select_mode('html');
   return result;
}

_command int bbedit_file_new_from_selection() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   _str new_mark = _duplicate_selection();
   p_window_id = _mdi._edit_window();
   int result = edit('+t');
   if( result!=0 ) {
      return result;
   }
   return _copy_to_cursor(new_mark);
}

_command int bbedit_file_new_from_clipboard() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_MDI)
{
   p_window_id = _mdi._edit_window();
   int result = edit('+t');
   if( result!=0 ) {
      return result;
   }
   return paste();
}

typeless _Nofclipboards;
_command void bbedit_paste_previous_clipbd()
{
   if( _Nofclipboards > 1 ) {
      paste('2');
   }
}

_command void bbedit_search_goto_center_line()
{
   goto_line((p_Noflines+1) intdiv 2);
}

_command void bbedit_center_of_window()
{
   p_cursor_y=((p_client_height-1) intdiv 2);
}


