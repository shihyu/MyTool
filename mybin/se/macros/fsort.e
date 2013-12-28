////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46085 $
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
#import "recmacro.e"
#import "stdprocs.e"
#import "util.e"
#endregion
/*

   This macro requires SLICK 2.0 or after.
   This module contains commands for sorting files in fileman mode.  If
   you want help on this module command, place the help below in
   "slick.doc".  If you want menus for sorting in fileman mode create a
   new file called "user.mnu" which contains the concatenation of
   "slick.mnu" and "fsort.mnu".  Your SLICK environment variable will need
   "-m user.mnu" to point SLICK to the alternate menu file.  This makes
   updating to new versions of SLICK easier.

(command,file): FSORT [type [order]]

   Sorts the directory.
        type = N = name            order = A = ascending
               D = date                    D = descending
               S = size
               E = extension
               P = path
               F = path & name

   When no parameters are given, a menu is displayed.

*/
//--FILEMAN SORT ROUTINES-----------------------------------------------------------------

defeventtab _fsort_form;

_ok.lbutton_up()
{
   _str fs_params = '';
   _str ss_params = '';

   if (_byname.p_value) {
      fs_params = 'n';
   }
   if (_byextension.p_value) {
      fs_params = 'e';
   }
   if (_bydate.p_value) {
      fs_params = 'd';
   }
   if (_bysize.p_value) {
      fs_params = 's';
   }
   if (_bypath.p_value) {
      fs_params = 'f';
   }
   if (_ascending.p_value) {
      fs_params=fs_params :+ ' a';
   }else{
      fs_params=fs_params :+ ' d';
   }
   if(_sec_frame.p_value){
      if (_sec_byname.p_value) {
         ss_params = 'n';
      }
      if (_sec_byextension.p_value) {
         ss_params = 'e';
      }
      if (_sec_bydate.p_value) {
         ss_params = 'd';
      }
      if (_sec_bysize.p_value) {
         ss_params = 's';
      }
      if (_sec_bypath.p_value) {
         ss_params = 'p';
      }
      if (_sec_ascending.p_value) {
         ss_params=ss_params :+ ' a';
      }else{
         ss_params=ss_params :+ ' d';
      }
   }

   _str params = '';
   if (_sec_frame.p_value) {
      params = ss_params' 'fs_params;
   }else{
      params = fs_params;
   }
   p_active_form._delete_window(params);
}

_sec_frame.lbutton_up()
{
   _sec_byname.p_enabled =
   _sec_byextension.p_enabled =
   _sec_bydate.p_enabled =
   _sec_bysize.p_enabled =
   _sec_bypath.p_enabled =
   _sec_ascending.p_enabled =
   _sec_descending.p_enabled =
   frame4.p_enabled = _sec_frame.p_value? true:false;
}


/**
 * Displays the file manager <b>File Sort dialog box</b>.  Used by 
 * <b>fileman</b> mode.
 * @categories File_Functions
 */
_command fileman_sort() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   return(fsort());
}
/**
 * Fileman Sort command
 *
 * @param args    Handle input arguments:<ul>
 *    <li>Type  = N,E,D,S,P ; name, extension, date,size, path
 *    <li>Order = A,D ; ascending, descending
 *    </ul>
 *
 * @return Returns 0 if successful.
 * @categories File_Functions
 */
_command fsort(_str args='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str type = '';
   _str order = '';
   _str type2 = '';
   _str order2 = '';
   parse args with type order type2 order2;
   /* messageNwait('t1='type ' order=' order ' type2=' type2 ' order2='order2); */
   if ( order == '' ) {
      order = 'A';
   }
   order = upcase(order);
   if ( type == '' ) {
      int view_id=0;
      _macro_delete_line();
      get_window_id(view_id);
      typeless result = show('-modal _fsort_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      activate_window(view_id);
      _macro('m',_macro('s'));
      _macro_call('fsort',result);
      return(fsort(result));
   }
   int status = 0;
   type = upcase(type);
   if ( type == 'N' ) {           /* name */
      status=sort_on_path(order,'P');
   } else if ( type == 'E' ) {    /* extension */
      status=sort_on_extension(order);
   } else if ( type == 'D' ) {    /* date */
      status=sort_on_date(order);
   } else if ( type == 'S'  ) {   /* size */
      status=sort_buf_on_select(1,DIR_SIZE_COL,p_noflines,DIR_SIZE_COL+DIR_SIZE_WIDTH-1,order);
   } else if ( type == 'F'  ) {   /* Path and Name (Filename) */
      status=sort_buf_on_select(1,DIR_FILE_COL,p_noflines,MAX_LINE-2,'-f 'order);
   } else if ( type=='P' ) {      /* Path */
      status=sort_on_path(order,'N');
   } else {
      message('Invalid sort field type');
      return(1);
   }
   if ( ! status ) {
      clear_message();
   }else{
      return(status);
   }
   if (type2 == '') {
      return(status);
   }else{
      type2 = type2' 'order2;
      return(fsort(type2));
   }
}
/**
 * Procedure: sort_buf_on_select; this is the actual workhorse.  It
 * handles all of the mark allocation and sorts the buffer according to
 * the input coordinates.
 *
 * @return
 */
static int sort_buf_on_select(int ul_line, int ul_col,
                               int lr_line, int lr_col, 
                               _str order)
{

   // save the entering line, col, and mark
   int old_line = p_line;
   int old_col  = p_col;
   // duplicate the visable mark
   int mark_id=_duplicate_selection('');
   // get a mark for ourselves
   int id = _alloc_selection();
   if ( id<0 ) {
      return(id);
   }
   // mark the upper left corner
   p_line = ul_line;
   p_col  = ul_col;
   _select_block(id);
   // mark the lower right corner
   p_line = lr_line;
   p_col  = lr_col;
   _select_block(id);
   // show the mark and sort it
   _show_selection(id);
   int status=sort_on_selection(order);
   if ( status ) {
      return(status);
   }
   // show the original mark so we can free ours
   _show_selection(mark_id);
   // free out mark
   _free_selection(id);
   // restore original posistion
   p_line = old_line;
   p_col  = old_col;
   return(0);
}
#define MAX_NUMBER_LEN 10

/**
 * This routine insures stable sorting by appending a right justified
 * line number to the right of the extension.
 *
 * @return
 */
static int sort_on_extension(_str order)
{
   top();
   if ( p_line==0 ) {
      return(0);
   }

   _str line='';
   _str extension='';
   int number=0;
   for (;;) {
      get_line(line);
      extension=_file_case(_get_extension(substr(line,DIR_FILE_COL)));
      number=p_line;
      replace_line(extension:+substr('',1,MAX_NUMBER_LEN-length(number)):+
                   number:+_chr(0):+line);

      if ( down() ) {
         break;
      }
   }
   return(sortNstrip(order));

}
/**
 * This routine insures stable sorting by appending a right justified
 * line number to the right of the date and time.
 *
 * @return
 */
static int sort_on_date(_str order)
{
   top();
   if ( p_line==0 ) {
      return(0);
   }
   _str line='';
   _str date='';
   _str time='';
   int number=0;
   typeless month, day, year;
   typeless hour, minute, ampm;
   for (;;) {
      get_line(line);
      date=substr(line,DIR_DATE_COL,DIR_DATE_WIDTH);
      time=substr(line,DIR_TIME_COL,DIR_TIME_WIDTH);
      if (_dbcs()) {
         number=p_line;
         replace_line(date:+time:+
                      substr('',1,MAX_NUMBER_LEN-length(number)):+
                      number:+_chr(0):+line);
      } else {
         parse date with month '-' day '-' year;
         parse time with hour ':' minute +3 ampm;
         if ( year>70 ) {
            year='19'year;
         } else {
            year='20'year;
         }
         if ( hour==12 ) {
            if ( ampm=='a' ) {
               hour=' 0';
            }
         } else if ( ampm=='p' ) {
            hour=hour+12;
         }
         number=p_line;
         replace_line(year:+month:+day:+hour:+minute:+
                      substr('',1,MAX_NUMBER_LEN-length(number)):+
                      number:+_chr(0):+line);
      }
      if ( down() ) {
         break;
      }
   }
   return(sortNstrip(order));

}
/**
 * This routine insures stable sorting by appending a right justified
 * line number to the right of the path or name.
 *
 * @return
 */
static int sort_on_path(_str order, _str strip_path_or_name)
{
   top();
   if ( p_line==0 ) {
      return(0);
   }
   _str line='';
   int number=0;
   for (;;) {
      get_line(line);
      number=p_line;
      replace_line(_strip_filename(substr(line,DIR_FILE_COL),strip_path_or_name):+
                   substr('',1,MAX_NUMBER_LEN-length(number)):+
                   number:+_chr(0):+line);
      if ( down()){
         break;
      }
   }
   return(sortNstrip(order));

}
static int sortNstrip(_str order)
{
   int status=sort_buffer(order);
   top();
   _str line='';
   _str rest='';
   for (;;) {
      get_line(line);
      parse line with line \0 rest;
      replace_line(rest);
      if ( down()){
         break;
      }
   }
   return(status);
}
