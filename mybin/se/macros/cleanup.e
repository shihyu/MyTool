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
#import "fileman.e"
#import "files.e"
#import "main.e"
#endregion

/*

   COPY YOUR "userdefs.e" file to your SlickEdit directory BEFORE running
   this macro.  Otherwise the wrong include file will be found.

   This macro converts a userdefs.e file created by Text Mode SlickEdit to
   Visual SlickEdit 1.0

   Lines which references these variables are deleted.
       popup_window_border
       popup_window_text
       popup_buf_name
       popup_subtitle
       popup_mark
       popup_cursor
       def_erase_command
       def_left_border
       def_right_border
       def_bottom_border
       def_menu_bar
       def_mou_scroll

   Lines which reference
       def_data(def-compile-???
       get_fkeytext
       set_fkeytext
       cursor_shape
       count_cursor_motion
       getkey
       set_color_field
       mou_config
       one_window
       window_border

   defmacro code
*/
#define PROMPT_RE  '(=[ \t]*prompt_(edit|get|unload)[ \t]*$)'
defmain()
{
   int status=edit(slick_path_search(USERDEFS_FILE:+_macro_ext));
   if ( status ) {
      return(status);
   }
   // Get rid of the "include colors.sh" line
   top();
   status=search("^[ \t]*include[ \t]*\'colors.sh\'[ \t]*$","r");
   if ( !status ) {
      _delete_line();
   }

   top();
   unlist_search('popup_(window_border|window_text|buf_name|subtitle|mark|cursor)','','wri*');
   top();
   unlist_search('def_(mou_scroll|erase_command|left_border|right_border|bottom_border|menu_bar)','','wri*');
   top();
   unlist_search('def_data\("def-compile-','','ri*');
   top();
   unlist_search('window_border|get_fkeytext|set_fkeytext|cursor_shape|count_cursor_motion|getkey|call set_color_field|mou_config|one_window','','wri*');
   top();
   status=search('^defmacro','ri');
   if (!status) {
      _deselect();_select_line();
      status=search('^(defkeys|def |defmain|defproc|defc| *universal|include)','ri@');
      if (status) {
         bottom();
      } else {
         up();
      }
      _select_line();
      _delete_selection();
   }
   status=save();
   if (status) {
      stop();
   }
   execute('tconvert');
}
#if 0
static _str delete_h_ext_setup()
{
   top();
   search_string='call replace_def_data\("def-(setup-h|compile-h|begin-end-h|options-h)"';
   search search_string,'ri';
   for (;;) {
      if ( rc ) {
         break;
      }
      _delete_line;
      _begin_line;
      search search_string,'ri';
   }

}
#endif
