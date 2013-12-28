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
#import "compile.e"  
#import "dlgman.e"
#import "main.e"
#import "markfilt.e"
#import "mprompt.e"
#import "recmacro.e"
#import "stdprocs.e"
#import "util.e"
#endregion

int _shell_wid;
boolean _fmcancel;

_control list1,cancelbtn;


/** 
 * Executes <i>command</i> specified on all the lines of the current buffer.  
 * Parts of the line being executed are inserted into the <i>command</i> 
 * specified according to the following specifications:
 * <DL compact style="margin-left:20pt;">
 *    <DT>%E   <DD>File extension with dot (Directory buffers only)
 *    <DT>%F   <DD>Filename  (Directory buffers only)
 *    <DT>%N   <DD>Name without extension (Directory buffers only)
 *    <DT>%L   <DD>Entire line
 *    <DT>%R   <DD>Current project
 *    <DT>%V   <DD>Drive with : (Directory buffers only).  This is not very useful under 
 * UNIX.
 *    <DT>%<i>nnn</i>   <DD>Nth word is inserted
 *    <DT>%(<i>envvar</i>) <DD>Value of environment variable <i>envvar</i>
 *    <DT>%%   <DD>percent character
 * </DL>
 * @example
 * <DL>
 *         <DT>for-all fmsay %L <DD>Displays all lines of the current buffer
 * </DL>
 * @categories Miscellaneous_Functions
 */
_command for_all(_str commandArg='', _str shell_wait='', _str echo_command='', typeless command_view_id='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless arg1=prompt(commandArg);
   if ( shell_wait=='' ) {
      shell_wait=last_index('','W');
   } else {
      shell_wait=1;
   }
   if (command_view_id=='') {
      get_window_id(command_view_id);
   }
   typeless p;
   _save_pos2(p);
   int view_id=0;
   get_window_id(view_id);
   /* The performance of this loop can be enhanced by                */
   /*            1   If command is internal, find index and call it  */
   /*            2   if command is external, get its path so no path */
   /*                search is required.                             */
   top();
   _shell_wid=0;
   _fmcancel=0;
   if (p_line==1 && echo_command) {
      get_window_id(view_id);
      _shell_wid=show(' -new _fmstatus_form');
      _shell_wid.list1._delete_line();
      activate_window(view_id);
      _shell_wid.p_user=_enable_non_modal_forms(0,_shell_wid);
   }
   up();
   int status=0;
   _str select_cmd='';
   _str cmdargs='';
   _str args='';
   parse arg1 with select_cmd args;
   int index=find_index(select_cmd,PROC_TYPE|COMMAND_TYPE);
   for (;;) {
      int b4_view_id=0;
      get_window_id(b4_view_id);
      process_events(_fmcancel);
      activate_window(b4_view_id);
      if ( down() || _fmcancel) { status=0;break; }
      _str line='';
      get_line(line);
      cmdargs=parsecommand(args,line);
      activate_window(command_view_id);
      if ( echo_command) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(select_cmd' 'cmdargs);
            _shell_wid.list1.refresh();
         }
      }
      if (index) {
         status=call_index(cmdargs,index);
      } else {
         status=execute(select_cmd' 'cmdargs,'');
         if (status==FILE_NOT_FOUND_RC) {
            _message_box(nls("Macro or Program '%s' not found",select_cmd));
         }
      }
      get_window_id(command_view_id);
      if (status=='') status=0;
      if ( status) break;
      activate_window(view_id);
   }
   if (!status && _fmcancel) {
      status=COMMAND_CANCELLED_RC;
   }
   typeless result=0;
   int orig_wid=0;
   activate_window(view_id);
   _restore_pos2(p);
   activate_window(command_view_id);
   if ( shell_wait ) {
      if ( status<0 && isinteger(status) ) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(get_message(status));
            _shell_wid.list1.refresh();
         }
      }
      orig_wid=p_window_id;
      if (_iswindow_valid(_shell_wid)) {
         if (!status) _shell_wid.list1.insert_line(nls("Operation completed successfully"));
         _shell_wid.cancelbtn.p_caption='Close';
         p_window_id=_shell_wid.cancelbtn;
         _set_focus();
         _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
         result=_modal_wait(_shell_wid);
         if (result!='' && _iswindow_valid(orig_wid)) {
            p_window_id=orig_wid;
         }
         _shell_wid=0;
      }
   }
   if ( _iswindow_valid(_shell_wid)) {
      _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
      _shell_wid._delete_window();
      if(status==COMMAND_CANCELLED_RC){
         message(get_message(COMMAND_CANCELLED_RC));
      }
   }
   _shell_wid=0;
   return(status);

}


/** 
 * Executes <i>command</i> specified on the selection.  See help on 
 * <b>for_all</b> command form information on inserting parts of line in the 
 * <i>command</i>.
 * @categories Selection_Functions
 */
_command for_mark(_str commandArg='', _str shell_wait='', _str echo_command='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless arg1=prompt(commandArg);
   if ( _select_type()=='' ) {
      message(get_message(TEXT_NOT_SELECTED_RC));
      return(TEXT_NOT_SELECTED_RC);
   }
   if ( shell_wait=='' ) {
      shell_wait=last_index('','W');
   } else {
      shell_wait=1;
   }
   int command_view_id=0;
   get_window_id(command_view_id);
   typeless p;
   _save_pos2(p);
   int view_id=0;
   get_window_id(view_id);
   filter_init();
   _str select_cmd='', args='';
   parse arg1 with select_cmd args;
   int index=find_index(select_cmd,PROC_TYPE|COMMAND_TYPE);
   _shell_wid=0;
   _fmcancel=0;
   if (echo_command) {
      get_window_id(view_id);
      _shell_wid=show(' -new _fmstatus_form');
      _shell_wid.list1._delete_line();
      activate_window(view_id);
      _shell_wid.p_user=_enable_non_modal_forms(0,_shell_wid);
   }
   _str line='';
   _str string='';
   _str cmdargs='';
   typeless status=0;
   for (;;) {
      int b4_view_id=0;
      get_window_id(b4_view_id);
      process_events(_fmcancel);
      activate_window(b4_view_id);
      if (_fmcancel) {
         status=0;break;
      }
      status = filter_get_string(string);
      if ( status ) { break; }
      line=string;
      cmdargs=parsecommand(args,line);
      activate_window(command_view_id);
      if (echo_command) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(select_cmd' 'cmdargs);
            _shell_wid.list1.refresh();
         }
      }
      if (index) {
         status=call_index(cmdargs,index);
      } else {
         status=execute(select_cmd' 'cmdargs,'');
         if (status==FILE_NOT_FOUND_RC) {
            _message_box(nls("Macro or Program '%s' not found",select_cmd));
         }
      }
      get_window_id(command_view_id);
      if (status=='') status=0;
      if ( status ) break;
      activate_window(view_id);
   }
   if (!status && _fmcancel) {
      status=COMMAND_CANCELLED_RC;
   }
   int orig_wid=0;
   typeless result=0;
   activate_window(view_id);
   _restore_pos2(p);
   activate_window(command_view_id);
   filter_restore_pos();
   if ( shell_wait ) {
      if ( status<0 && isinteger(status) ) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(get_message(status));
            _shell_wid.list1.refresh();
         }
      }
      orig_wid=p_window_id;
      if (_iswindow_valid(_shell_wid)) {
         if (!status) _shell_wid.list1.insert_line(nls("Operation completed successfully"));
         _shell_wid.cancelbtn.p_caption='Close';
         p_window_id=_shell_wid.cancelbtn;
         _set_focus();
         _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
         result=_modal_wait(_shell_wid);
         if (result!='' && _iswindow_valid(orig_wid)) {
            p_window_id=orig_wid;
         }
         _shell_wid=0;
      }
   }
   if ( _iswindow_valid(_shell_wid)) {
      _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
      _shell_wid._delete_window();
      if(status==COMMAND_CANCELLED_RC){
         message(get_message(COMMAND_CANCELLED_RC));
      }
   }
   _shell_wid=0;
   return(status);
}
void _fmrefresh_attr()
{
   _str line='';
   get_line(line);
   insert_file_list('+RHSDP 'pcfilename(line));
   get_line(line);
   up();_delete_line();
   replace_line('>'substr(line,2));

}
void _fmrefresh_move(_str &newpath)
{
   _str name=parse_file(newpath);
   newpath=strip(newpath,'B','"');
   _str line='';
   get_line(line);
   if ( last_char(newpath)!=FILESEP ) {
      newpath=newpath:+FILESEP;
   }
   replace_line(substr(line,1,DIR_FILE_COL-1):+absolute(newpath:+
                _strip_filename(substr(line,DIR_FILE_COL),'P')));
}

/** 
 * Executes <i>command</i> specified on the selected files.  Used by 
 * <b>fileman</b> mode.  Directory files are skipped.  See <b>for_all</b> for 
 * help on inserting parts of line in <i>command</i>.
 * @categories File_Functions
 */
_command for_select(_str commandArg='',_str shell_wait='',_str echo_command='', _str help_str = '') name_info(PC_ARG','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (shell_wait=='') shell_wait=1;
   return(for_select_attr(commandArg, shell_wait, echo_command, 0, help_str));
}


/** 
 * Executes <i>command</i> specified on the selected files.  Used by fileman 
 * mode.  Unlike the for_select command, directory files are not skipped.  See 
 * help on for_all command for information on inserting parts of line in the 
 * <i>command</i>.
 * @categories File_Functions
 */
_command for_dir(_str commandArg='',_str shell_wait='',_str  echo_command='') name_info(COMMAND_ARG','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (shell_wait=='') shell_wait=1;
   return(for_select_attr(commandArg, shell_wait, echo_command, 1));
}

static _str for_select_attr(var arg1,var shell_wait,var echo_command,var allow_dir, _str help_str = '')
{
   if (arg1=='') {
      _macro_delete_line();
      arg1=show('-modal _forsel_form');
      if (arg1=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro_call('for_select',arg1,shell_wait,echo_command,allow_dir);
   }
   if (shell_wait=='') {
      shell_wait=0;
   }
   _str select_cmd='', args='';
   parse arg1 with select_cmd args;
   if (lowcase(select_cmd)=='-nostatus') {
      echo_command=0;
      parse args with select_cmd args;
   }
   int after_index=0;
   int index=find_index(select_cmd,PROC_TYPE|COMMAND_TYPE);
   select_cmd=translate(select_cmd,'-','_');
   if ( select_cmd=='-fm-erase' ) {
      after_index=find_index('zap-line',PROC_TYPE);
   } else if ( select_cmd=='-fm-move' ) {
      after_index=find_index('_fmrefresh_move',PROC_TYPE);
   } else if ( select_cmd=='chmod' ) {
      after_index=find_index('_fmrefresh_attr',PROC_TYPE);
   } else {
      after_index=0;
   }
   int command_buf_id=p_buf_id;
   int buf_id=command_buf_id;
   top();_begin_line();
   typeless status=search('^>','@r');
   typeless search_string, search_options, word_re;
   save_search(search_string,search_options,word_re);
   int hit_one=0;
   _shell_wid=0;
   _fmcancel=0;
   int view_id=0;
   if (!status && echo_command) {
      get_window_id(view_id);
      _shell_wid=show(' -new _fmstatus_form');
      _shell_wid.list1._delete_line();
      activate_window(view_id);
      _shell_wid.p_user=_enable_non_modal_forms(0,_shell_wid);
   }
   _str line='';
   _str cmdargs='';
   for (;;) {
      int b4_view_id=0;
      get_window_id(b4_view_id);
      process_events(_fmcancel);
      activate_window(b4_view_id);
      if ( status || _fmcancel) {
         status=0;
         clear_message();
         break;
      }
      hit_one=1;
      get_line(line);
      if ( allow_dir || ! pos('<DIR>',line) ) {
         if ( substr(line,1,1)=='>' ) {
            cmdargs=parsecommand(args,line);
            if ( _iswindow_valid(_shell_wid)) {
               _shell_wid.list1.insert_line(select_cmd' 'cmdargs);
               _shell_wid.list1.refresh();
            }
            _mdi.p_child.load_files('+bi 'command_buf_id);
            if (index) {
               status=call_index(cmdargs,index);
            } else {
               status=execute(select_cmd' 'cmdargs,'');
               if (status==FILE_NOT_FOUND_RC) {
                  _message_box(nls("Macro or Program '%s' not found",select_cmd));
               }
            }
            command_buf_id=_mdi.p_child.p_buf_id;
            if (status=='') status=0;
            if ( status ) {
               break;
            }
            _mdi.p_child.load_files('+bi 'buf_id);
            if ( after_index ) {
               down();
               int done=rc;
               if ( ! done ) {
                  up();
               }
               call_index(cmdargs,after_index);
               if ( done ) { status=0;break; }
            }
         }
         if ( select_cmd=='file-erase' ) {
            _begin_line();status=search('^>','@r');
         } else {
            restore_search(search_string,search_options,word_re);
            status=repeat_search();
         }
      } else {
         status=repeat_search();
      }
   }
   _mdi.p_child.load_files('+bi 'command_buf_id);
   if ( ! hit_one ) {
      // 1-AD6YD
      // Formerly was telling user to press F1, but then nothing happened.  Added 
      // help button and info (had to switch to textboxform instead of message box.  
      // Help is sent by caling method, default is nothing.
      _str buttons = '';
      if (help_str == '') {
         buttons = "OK\tSelect file(s) first.";
      } else {
         buttons = "OK, Help:_help\tSelect file(s) first.";
      }
      textBoxDialog("SlickEdit",             // Form caption
                               0,            // Flags
                               0,            // Use default textbox width
                               help_str,     // Help item
                               buttons);     // Buttons and captions
      _shell_wid=0;
      return(0);
   }
   if (!status && _fmcancel) {
      status=COMMAND_CANCELLED_RC;
   }
   if ( shell_wait) {
      if ( status<0 && isinteger(status) ) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(get_message(status));
            _shell_wid.list1.refresh();
         }
      }
      if ( _iswindow_valid(_shell_wid)) {
         int orig_wid=p_window_id;
         if (!status) _shell_wid.list1.insert_line(nls("Operation completed successfully"));
         _shell_wid.cancelbtn.p_caption='Close';
         p_window_id=_shell_wid.cancelbtn;
         _set_focus();
         _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
         typeless result=_modal_wait(_shell_wid);
         if (result!='' && _iswindow_valid(orig_wid)) {
            p_window_id=orig_wid;
         }
         _shell_wid=0;
      }
   }
   if ( _iswindow_valid(_shell_wid)) {
      _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
      _shell_wid._delete_window();
      if(status==COMMAND_CANCELLED_RC){
         message(get_message(COMMAND_CANCELLED_RC));
      }
   }
   _shell_wid=0;
   return(status);
}
/**
 * @return Returns command with parts of <i>fileman_line</i> in the format of 
 * the file manager list parsed into <i>command</i>.  See help on 
 * <b>for_all</b> command for information on parse parts of 
 * <i>fileman_line</i> into <i>command.</i>
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_str parsecommand(_str command,_str line)
{
    return(_parse_project_command(command,pcfilename(line),_project_name,'',line));
}
#if 0
_str pcfilename(_str line)
{
   return(maybe_quote_filename(substr(line,DIR_FILE_COL)));
}
#else
/**
 * @return Returns filename field of <i>fileman_line</i>.  <i>fileman_line</i> 
 * must be in the column format of the file manager.
 * 
 * @categories File_Functions
 * 
 */ 
_str pcfilename(_str line)
{
  //return(maybe_quote_filename(substr(line,DIR_FILE_COL)));
  _str filename=substr(line,DIR_FILE_COL);
  _str path='';
  if (_strip_filename(filename,'p'):==filename) {
     //This is a directory list with the -p options(No path)
     //parse p_buf_name with . . path;
     if (command_state()) {
        if (_mdi.p_child._isEditorCtl(false)) {
           return('');
        }
        parse _mdi.p_child.p_DocumentName with '(Directory|List) of ','r' path;
     } else {
        parse p_DocumentName with '(Directory|List) of ','r' path;
     }
     path=_strip_filename(path,'n');
     if (last_char(path)!=FILESEP) {
        path=path:+FILESEP;
     }
     filename=path:+filename;
  }
  return(maybe_quote_filename(filename));
}
#endif
/**
 * @return Returns name without extension or path of <i>fileman_line</i>.  
 * <i>fileman_line</i> must be in the column format of the file manager.
 * 
 * @categories File_Functions
 * 
 */ 
_str pcname(_str line)
{
   return(_strip_filename(substr(line,DIR_FILE_COL),'pe'));
}
/**
 * @return Returns name with extension, but without path of 
 * <i>fileman_line</i>.  <i>fileman_line</i> must be in the column 
 * format of the file manager.
 * 
 * @categories File_Functions
 * 
 */ 
_str pcfile(_str line)
{
   return(_strip_filename(substr(line,DIR_FILE_COL),'p'));
}
/**
 * @return Returns extension from <i>fileman_line </i>without the dot.  
 * <i>fileman_line</i> must be in the column format of the file manager.
 * 
 * @categories File_Functions
 * 
 */ 
_str pcextension(_str line)
{
   return(_get_extension(substr(line,DIR_FILE_COL)));
}
/**
 * @return Returns path of <i>fileman_line</i>.  <i>fileman_line</i> must be in 
 * the column format of the file manager.
 * 
 * @categories File_Functions
 * 
 */ 
_str pcpath(_str line)
{
   return(_strip_filename(substr(line,DIR_FILE_COL),'n'));
}
/**
 * @return Returns the <i>Nth</i> space or tab delimited word in <i>string</i>.  
 * '' is returned if the <i>Nth</i> word does not exist.
 * 
 * @categories String_Functions
 * 
 */ 
_str word(_str line,int n)
{
   int i=1;
   for (;;) {
     parse line with word line;
     if ( i==n || word=='' ) {
       break;
     }
     i=i+1;
   }
   return(word);

}

/**
 * This function is intended to be called to process "@<i>buffer_name</i>"
 * string returned by the <b>_sellist_form</b> function.  See <b>for_all</b>
 * command for information on parsing parts of each line into <i>command</i>.
 * <p>
 * <i></i>Activates buffer specified by the expression
 * <b>substr</b>(<i>atsign_bufname</i>,2) and applies <i>command</i> to each
 * line in the buffer.  Parts of the line being processed may be inserted into
 * the command.  On completion, the buffer is deleted.
 * 
 * @param word
 * @param command
 * @param echo_command
 * 
 * @return Returns 0 if successful.  Otherwise a non-zero value is returned.
 *         This function may return the return value of the <b>for_all</b> function
 *         which can return anything the command returns.
 * @example 
 * <pre>
 *         status=edit("list");
 *         if (status) {
 *              return(status);
 *         }
 *         for_list("@"absolute("list"), "e %L",0);
 * </pre>
 * @categories Miscellaneous_Functions
 */
_str for_list(_str word,_str command,_str echo_command)
{
   /* load copy of one view of buffer. */
   _str list_name=substr(word,2);
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(list_name,temp_view_id,orig_view_id);
   if ( status ) {
      return(status); /* Probably file not found. */
   }
   status=for_all(command,'',echo_command,temp_view_id);
   int result_view_id=0;
   get_window_id(result_view_id);
   _delete_temp_view(temp_view_id);
   activate_window(result_view_id);
   return(status);
}


/** 
 * This command is intended to be executed by the <b>for_select</b> command 
 * and not directly from the command line.  Displays <i>string</i> in fileman 
 * status window and opens shell window if it is not already open.  Useful for 
 * testing the commands <b>for_all</b>, <b>for_mark</b>, <b>for_select</b>, and 
 * <b>for_dir</b>.
 * <pre>
 *    Command Line Example
 * 
 *          for-all fmsay %L
 * </pre>
 * @return  Returns 0.
 * 
 * @see for_all
 * @see for_mark
 * @see for_select
 * @see for_dir
 * @categories File_Functions
 */
int fmsay(_str msg)
{
   if ( _iswindow_valid(_shell_wid)) {
      _shell_wid.list1.insert_line(msg);
      _shell_wid.list1.refresh();
   }
   return(0);
}
defeventtab _forsel_form;
_ok.on_create()
{
   _retrieve_prev_form();
}
_ok.lbutton_up()
{
   _save_form_response();
   _str result=text1.p_text;
   if (_nostatus.p_value) {
      result='-nostatus 'result;
   }
   p_active_form._delete_window(result);
}


defeventtab _fmstatus_form;
cancelbtn.on_create()
{
   _fmcancel=0;
   p_user=p_caption;
}
cancelbtn.on_destroy()
{
   _enable_non_modal_forms(1,_shell_wid,_shell_wid.p_user);
   _fmcancel=1;
   _shell_wid=0;
}
cancelbtn.lbutton_up()
{
   if (p_caption==p_user) {
      _fmcancel=1;
   } else {
      // Close the dialog box
      p_active_form._delete_window();
   }
}
