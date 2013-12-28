////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "listbox.e"
#import "main.e"
#import "stdprocs.e"
#endregion

//
//    User level 2 inheritance for FILE LIST BOX
//
defeventtab _ul2_fillist _inherit _ul2_listbox;
_ul2_fillist.on_create2()
{
   _flfilename('');
}

/**
 * When arguments are given to this function, the file list of a file list 
 * box will display the files from directory <i>path</i> and match any of the 
 * wildcards specified.  <i>wildcards</i> is a string of semicolon delimited 
 * wildcards (Ex. "*.c;*.h").  In addition, this function sends an 
 * <b>on_change</b> event to the current control with CHANGE_FILENAME as the 
 * first argument if the arguments given are different.
 * <p>
 * Returns the current wildcards and path used to fill in a file list box.  
 * The return value is a string in the following format:
 * <pre>      <i>path</i>;<i>wildcards</i></pre>
 * @example
 * <pre>
 * // This examples requires a form with a file list box named list1 and a 
 * button named 
 * // command1
 * defeventtab form1;
 * command1.lbutton_up()
 * {
 *    // If you use double quotes, you need two \\ 
 *    list1._flfilename('*.e;*.h','c:\vslick');
 *    parse list1._flfilenames with path ';' wildcards
 *    messageNwait('path='path'  wildcards='wildcards);
 * }
 * </pre>
 * 
 * @param wildcards wildcards
 * @param dirpath directory path
 * @param forceRefresh
 * @param showDotFiles if true, the file list shows UNIX-style
 *                     dot files.
 * @appliesTo  File_List_Box
 * @categories File_List_Box_Methods
 */
_str _flfilename(_str wildcards=null, _str dirpath='', 
                 boolean forceRefresh=false, boolean showDotFiles=true)
{
   if (wildcards==null) {
      return(p_user2);
   }
   _str param='';
   if (wildcards=='' && dirpath=='') {
      param=p_user2;
   } else {
      if (dirpath!='' && last_char(dirpath)!=FILESEP) {
         dirpath=dirpath:+FILESEP;
      }
      param=dirpath';'wildcards;
   }
   _str old_user2=p_user2;
   boolean do_call_event=false;
   if (param!='') {
      p_user2=param;
      if (p_user2==old_user2 && !forceRefresh) {
         return(p_user2);
      }
      do_call_event=true;
   } else {
      p_user2=';'ALLFILES_RE;
   }
   _str rest='';
   parse p_user2 with dirpath';'rest;
   if (dirpath!='' && last_char(dirpath)!=FILESEP) {
      dirpath=dirpath:+FILESEP;
   }
   _lbclear();
   mou_hour_glass(1);
   for (;;) {
      _str filespec='';
      parse rest with filespec ';' rest;
      filespec=strip(filespec);
      if (filespec=='') break;
      //say("path="path" filespec="filespec);
      _str flagDotFiles = showDotFiles ? '+u' : '-u';
      insert_file_list(flagDotFiles' -v 'maybe_quote_filename(dirpath:+filespec));
   }
   //_lbsort((_fpos_case=='')?'e':_fpos_case);
   _lbsort('I');
   //8/16/2000 Added to remove the duplicate file names.
   _remove_duplicates(_fpos_case);
   mou_hour_glass(0);
   top();
   if (do_call_event) {
      call_event(CHANGE_FILENAME,p_window_id,ON_CHANGE,'');
   }
   return(p_user2);
}
void _ul2_fillist.\27-\255()
{
   typeless was_selected=_lbisline_selected();
   _str key=last_event();
   if (key:==' ') {
      call_event(defeventtab _ul2_listbox,' ','E');
      return;
   }
   _lbdeselect_line();
   curItem := _lbget_text();

   status := _lbsearch('^'key, 'RI');
   if (status) {
      _lbsearch(curItem);
      if (was_selected) {
         _lbselect_line();
      }
      return;
   }

   _lbselect_line();
   curItem2 := _lbget_text();
   if (status || curItem == curItem2/*bp2==bp*/) {
      _lbsearch(curItem);
      _lbselect_line();
      if (!was_selected) {
         call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
      }
   } else {
      call_event(CHANGE_SELECTED,p_window_id,ON_CHANGE,'');
   }
}
