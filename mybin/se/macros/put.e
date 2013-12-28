////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "guiopen.e"
#import "files.e"
#import "main.e"
#import "print.e"
#import "recmacro.e"
#import "saveload.e"
#import "stdprocs.e"
#endregion


/**
 * Inserts file before or after current line
 *
 * @param src_filename  Name of file to insert
 * @param obsolete      This argument is not used.
 * @param insert_style
 *                   Selects whether to insert after or before the current line.
 *                   'A', 'B', or '' which corresponds to 'After', 'Before', or def_line_insert setting.
 * @param start_line
 * @param end_line
 * @param load_options
 *                 may be "" or only may contain the following
 *                 <UL>
 *                 <LI> +bi &lt;buf_id&gt;
 *                 <LI> +d
 *                 <LI> +b
 *                 </UL>
 * @return Returns 0 if successful.  Common return codes are 
 * FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC, TOO_MANY_SELECTIONS_RC, and 
 * TOO_MANY_FILES_RC.  On error, message is displayed.
 * @see     gui_insert_file
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions
 */
_command int get(_str src_filename='', _str obsolete='', _str insert_style='', int start_line=0, int end_line=0, _str load_options='') name_info(FILE_ARG','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   src_filename=prompt(src_filename,nls('Insert file'));
   int mark=_alloc_selection();
   if ( mark<0 ) {
     return(mark);
   }
   int view_id=0;
   get_window_id(view_id);
   /* Check if this buffer already exists. */
   int buf_id=p_buf_id;
   typeless junk;
   _str filename=absolute(strip_options(src_filename,junk));
   load_files('+bi 'buf_id);
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(filename,
                          temp_view_id,orig_view_id,
                          load_options" "_load_option_encoding(filename));
                          
   if ( status ) {
     _free_selection(mark);
     return(status);
   }
   if ( buf_id==p_buf_id ) {  /* No file loaded.  Arg1 could be '' */
      _free_selection(mark);
      return(COMMAND_CANCELLED_RC);
   }
   boolean LastLineHasNLChars=1;
   boolean RemoveEOF=0;
   if (start_line>0) {
      p_RLine=start_line;
   } else {
      top();
   }
   if (!_on_line0()) {
      _select_line(mark);
      if (end_line>0) {
         p_RLine=end_line;
      } else {
         bottom();
      }
      _select_line(mark);
      // IF this is an ASCII buffer in DOS format AND last line
      //    contains just an EOF character
      if (!p_buf_width && p_newline=="\r\n" && get_text()==_chr(26)) {
         RemoveEOF=1;
      } else {
         LastLineHasNLChars=_line_length()!=_line_length(1);
      }
   }
   int mark_view_id=0;
   get_window_id(mark_view_id);
   int old_buf_flags=p_buf_flags;
   activate_window(view_id);
   _str old_line_insert=def_line_insert;
   if ( insert_style!='' ) {
      def_line_insert=upcase(insert_style);
   }
   status=rc;
   if (_select_type(mark)!='') {
      boolean RemoveNLChars=0;
      if (!p_buf_width && !LastLineHasNLChars && def_line_insert=='A') {
         save_pos(auto p);
         if(down() ){
            RemoveNLChars=1;
         }
         restore_pos(p);
      }
      //Noflines=count_lines_in_selection();
      if ( old_buf_flags&VSBUFFLAG_THROW_AWAY_CHANGES ) {
         status=move_to_cursor(mark);
      } else {
         status=copy_to_cursor(mark);
      }
      if (RemoveEOF || !LastLineHasNLChars) {
         save_pos(auto p);
         _end_select(mark);
         _end_line();
         if (RemoveEOF) {
            left();_delete_text();
         }
         // IF are on the last line of the file
         if (down()) {
            // Remove NLChars
            _delete_text(2);
         }
         if (!_line_length(1)) {
            _delete_line();
         }
         restore_pos(p);
      }
   }
   def_line_insert=old_line_insert;
   _free_selection(mark);
   activate_window(mark_view_id);
   _delete_temp_view(temp_view_id);
   activate_window(view_id);
   if ( status ) {  /* make sure move mark error message is displayed. */
     message(get_message(status));
   }
   return(status);
}
/**
 * Writes selection to <i>dest_filename</i> specified.  The -p
 * option selects to write the selection to the print using the
 * default print options.  The default printer options may be
 * set with the <b>Print Setup dialog box</b> ("File",
 * "Print...", press "Setup..." button) and the <b>Print dialog
 * box</b> ("File", "Print...").
 * 
 * @return Returns 0 if successful.  Common return codes are 
 * TEXT_NOT_SELECTED_RC, and 
 * TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 * 
 * @see gui_write_selection
 * @see get
 * @see gui_append_selection
 * @see append
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Selection_Functions
 * 
 */ 
_command put(_str dest_filename="", _str save_flags="") name_info(FILENEW_ARG','VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL)
{
   if (is_printer_device(dest_filename) || lowcase(dest_filename)=='-p') {
      return(print_selection());
   }
   return(put2(dest_filename,save_flags,nls('Write mark'),false));
}
/**
 * Appends selected text to filename specified.  This command has no effect 
 * on files already in memory.  Select text first with one of the commands 
 * select_char, select_line, or select_block.
 * 
 * @return Returns 0 if successful.  Common return codes are TEXT_NOT_SELECTED_RC, 
 * BLOCK_SELECTION_REQUIRED_RC, and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 * 
 * @see select_char
 * @see select_line
 * @see select_block
 * @see get
 * @see put
 * @see gui_write_selection
 * @see gui_append_selection
 * @categories File_Functions, Selection_Functions
 */
_command append(_str dest_filename="") name_info(FILE_ARG",")    /* Reasonable to allow completion for append. */
{
   return(put2(dest_filename,SV_OVERWRITE,nls('Append mark'),true));

}
// Old function used for text mode (not-laser printer) printing.
static _str is_printer_device(_str dev_name)
{
    return (
#if __PCDOS__
      file_eq(dev_name,'prn') ||
      /* Check for LPT follow by a digit. */
       (file_eq(substr(dev_name,1,3),'lpt') && isinteger(substr(dev_name,4))) ||
       file_eq(dev_name,def_tprint_device)
#else
      file_eq(dev_name,'/dev/lp') || file_eq(dev_name,'/dev/lp1') ||
      file_eq(dev_name,'/dev/lp2') || file_eq(dev_name,'/dev/lp3') ||
      file_eq(dev_name,'/dev/lp4') || file_eq(dev_name,def_tprint_device)
#endif
    );

}
/**
 *
 * @param dest_filename    Switches and quoted filename or ''
 * @param save_flags       '' or SV_OVERWRITE
 * @param msg              Message to use when prompting for filename.
 * @param doAppend Set to true if appending otherwise set this to false
 * @return        Returns 0 if successful.
 */
static int put2(_str dest_filename,_str save_flags,_str msg,boolean doAppend)
{
   _str dev_name=prompt(dest_filename,msg);
   if ( dev_name=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   /* IF allow popup prompt AND called from key OR command line/arg(2) */
   /* AND file exists */

   typeless flags=save_flags;
   if (flags=='') flags=0;
   boolean preplace=!(flags&SV_OVERWRITE) && def_preplace;
   _str save_options="";
   dev_name=strip_options(dev_name,save_options,true);
   typeless status=0;
   if ( preplace && file_exists(dev_name)) {
      status=overwrite_existing(dev_name,"Write Mark");
      if ( status ) {
         return(status);
      }
   }
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   // Make a copy of the current selection so we dont loose it.
   typeless mark= _duplicate_selection();
   if ( mark<0 ) return(mark);
   typeless junk="";
   int buf_id=0;
   int utf8=0;
   typeless encoding="";
   _get_selinfo(junk,junk,buf_id,'',junk,utf8,encoding);
   int old_buf_id=p_buf_id;
   status=load_files('+bi 'buf_id);
   if ( status ) {
      _free_selection(mark);
      return(status);
   }
   _str selected_buf_name=p_buf_name;
   _str tabs=p_tabs;
   int buf_width=p_buf_width;
   load_files('+bi 'old_buf_id);
#if __UNIX__
   if ( ! pathlen(def_tprint_device) ) {
      def_tprint_device='/dev/'def_tprint_device;
   }
#endif
   if ( lowcase(dev_name)=='-p' ) {
      dev_name=def_tprint_device;
   }
   _str options='';
   if (buf_width) {
      options='+'buf_width;
      if (!doAppend) {
         options=options:+' +t';
      }
   }
   dev_name=strip(dev_name,'B','"');
   int orig_wid=0;
   int temp_wid=0;
   if (doAppend) {
      status=_open_temp_view(dev_name,temp_wid,orig_wid,options);
   } else {
      orig_wid=_create_temp_view(temp_wid,options,absolute(dev_name));
      status=0;
   }
   if ( status ) {
      _free_selection(mark);
      p_window_id=orig_wid;
      return(status);
   }
   if (!doAppend) {
      insert_line('');
      p_encoding=encoding;
   }
   //say('dev_name='dev_name' save_options='save_options);

   // Appending to file?
   if ( doAppend ) {
      // Trying to append to self?
      if (buf_id==p_buf_id) {
         _free_selection(mark);
         _delete_temp_view();
         status=ACCESS_DENIED_RC;
         message(nls("Can't append to self"));
         p_window_id=orig_wid;
         return(status);
      }
      bottom();
      // IF this is an ASCII buffer in DOS format AND last character
      //    of buffer is an EOF character
      if (!p_buf_width && p_newline=="\r\n" &&
          get_text()==_chr(26)) {
         // Delete the EOF character
         if (_line_length(1)==1) {
            // Delete whole line.  It just contains an EOF character.
            _delete_line();
         } else {
            // Delete the EOF character
            left();_delete_text();
         }
      }
   }

   p_tabs=tabs;
   status=_copy_to_cursor(mark);
   _free_selection(mark);
   if ( status ) {
      _delete_temp_view();
      message(get_message(status));
      p_window_id=orig_wid;
      return(status);
   }
   if ( _select_type()=='LINE' && !doAppend) {
      top();_delete_line();
   }
   boolean old_AllowSave=p_AllowSave;
   p_AllowSave=true;
   if (isEclipsePlugin()) {
      status= save_file(maybe_quote_filename(p_buf_name),build_save_options(p_buf_name) " "save_options);
   } else {
      status=save(save_options,SV_OVERWRITE);
   }
   p_AllowSave=old_AllowSave;
   p_modify=0;
   _delete_temp_view();
   if ( status<0 ) {
      message(get_message(status));
   }
   p_window_id=orig_wid;
   return(status);

}


/**
 * Inserts a file you choose into the current buffer.  The <b>Explorer 
 * Standard Open dialog box</b> or <b>Standard Open dialog box</b> is displayed 
 * which prompts you to enter a filename.  The file is inserted before or after 
 * the current line depending on the <b>Line insert style</b>.
 * 
 * @see get
 * 
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 * 
 */
_command gui_insert_file() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro_delete_line();
   typeless result=0;
#if 1
   result=_OpenDialog('-modal',
     'Insert File',
      ALLFILES_RE,
     def_file_types,
     OFN_FILEMUSTEXIST|OFN_EDIT,
     '',
     '',
     '',
     'gui_insert_file',   // Retrieve name
     'Insert File dialog box'
     );
#else
   result=_OpenDialog('-modal',
     'Insert File',
      ALLFILES_RE,
     def_file_types,
     OFN_FILEMUSTEXIST,
     '',
     '',
     '',
     'gui_insert_file',   // Retrieve name
     'Insert File dialog box'
     );
#endif
   if(result == ''){
      return(COMMAND_CANCELLED_RC);
   }
   int status = get(result);
   if (status) {
      clear_message();
      _message_box(nls('Unable to open %s',result)'. 'get_message(status));
      return(status);
   }
   _macro('m',_macro('s'));
   _macro_append('get('_quote(result)');');
   return(0);
}

/** 
 * Writes the selection to a file you specify.  The <b>Explorer Standard 
 * Open dialog box</b> or <b>Standard Open dialog box</b> is displayed to prompt 
 * you for a file to write the selection to.
 * 
 * @return Returns 0 if successful.
 * 
 * @see put
 * @see append
 * @see gui_append_selection
 * @see get
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Selection_Functions
 * 
 */
_command gui_write_selection() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_MARK)
{
   _macro_delete_line();
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   typeless result=_OpenDialog('-modal',
     'Write Selection',
     '',
     def_file_types,
     OFN_SAVEAS|OFN_SAVEAS_FORMAT|OFN_APPEND|OFN_PREFIXFLAGS,
     '',
     '',
     '',
     'gui_insert_file',   // Retrieve name
     'write selection dialog box'
     );
   if(result == ''){
      return(COMMAND_CANCELLED_RC);
   }
   int status=0;
   _str option="", rest="";
   parse result with option rest ;
   if (lowcase(option)=='-a') {
      status = append(result);
      if (status) {
         clear_message();
         typeless junk="";
         _message_box(nls('Unable to write selection to %s',strip_options(rest,junk,true))'. 'get_message(status));
         return(status);
      }
      _macro('m',_macro('s'));
      _macro_append('append('_quote(result)');');
      return(0);
   }
   status = put(result,SV_OVERWRITE);
   if (status) {
      clear_message();
      _message_box(nls('Unable to write selection to %s',result)'. 'get_message(status));
      return(status);
   }
   _macro('m',_macro('s'));
   _macro_append('put('_quote(result)',SV_OVERWRITE);');
   return(0);
}

/** 
 * Appends the selection to a file you specify.  The Explorer Standard Open 
 * dialog box or Standard Open dialog box is displayed to prompt you for a file 
 * to append the selection to.
 * 
 * @return Returns 0 if successful.
 * 
 * @see append
 * @see put
 * @see gui_write_selection
 *
 * @categories Selection_Functions
 * 
 */
_command gui_append_selection() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   _macro_delete_line();
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   typeless result=_OpenDialog('-modal',
     'Append Selection',
     ALLFILES_RE,
     def_file_types,
     OFN_FILEMUSTEXIST,
     '',
     '',
     '',
     'gui_insert_file',  //Retrieve name
     'append selection dialog box'
     );
   if(result == ''){
      return(COMMAND_CANCELLED_RC);
   }
   int status = append(result);
   if (status) {
      clear_message();
      _message_box(nls('Unable to write selection to %s',result)'. 'get_message(status));
      return(status);
   }
   _macro('m',_macro('s'));
   _macro_append('append('_quote(result)');');
   return(0);
}
