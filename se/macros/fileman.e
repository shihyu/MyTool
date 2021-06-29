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
/* Usage: subcopy source dest_path                               */
/*                                                               */
#region Imports
#include "slick.sh"
#import "dir.e"
#import "files.e"
#import "forall.e"
#import "frmopen.e"
#import "fsort.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "mfsearch.e"
#import "mouse.e"
#import "put.e"
#import "recmacro.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "ptoolbar.e"
#endregion

int _shell_wid;

//_command show();
   
/**
 * Displays a dialog box for listing files.  If the <i>append</i> option is 
 * not given or is an empty string (""), a new buffer is created and the files 
 * are listed in the buffer.  Otherwise, the files are listed at the end of the 
 * current buffer.  This command switches to fileman mode when append option is 
 * not specified.  When in fileman mode, there a some new key bindings.  See 
 * help on <b>fileman_mode</b>.
 * 
 * @see dir
 * @see list
 * @categories File_Functions
 */
_command void fileman(_str doAppend='') name_info(','VSARG2_REQUIRES_MDI)
{
   _macro_delete_line();
   append_option := doAppend!='';

   // make sure we have an open file for this
   if (append_option) {
      if (_no_child_windows()) {
         _message_box("Unable to append file list without an open buffer.");
         return;
      }
   }

   typeless result = show('-modal _fileman_form',(append_option)?'Append Files':'');
   if (result == '') {
      return;
   }

   typeless status=0;
   _macro('m',_macro('s'));
   if (append_option) {
      _macro_call('append_dir',result);
      status = append_dir(result);      //Result should have path information
   } else {
      _macro_call('dir',result);
      status = dir(result);      //Result should have path information
   }
   if (status) {
      _message_box(nls("Unable to list files '%s'\n\n",result):+
                   get_message(status));
   }
}

int _OnUpdate_fileman(CMDUI &cmdui,int target_wid,_str command)
{
   parse command with command auto args;
   if (command == 'fileman') {
      // we have arguments, so we need an mdi child
      if (args != '' && _no_child_windows()) {
         return(MF_GRAYED);
      }
   }

   return(MF_ENABLED);
}

defeventtab _fileman_form;


_lffiles.on_create()
{
   _retrieve_prev_form();
}


_ok.on_create(_str caption='')
{
   if (caption != '') {
      p_active_form.p_caption = caption;
   }
}


_ok.lbutton_up()
{
   orig_wid := p_window_id;
   result := _maybe_quote_filename(_lffiles.p_text);
   blankOption := false;
   if (result=='') {
      blankOption = true;
      result=ALLFILES_RE;
   }
   if (result!='' && (_lfsubdir.p_value)) {
      result= '+t 'result;
   }
   ch := "";
   word := "";
   option := "";
   tree_option := "";
   _str line=result;
   Noffiles := 0;
   one_file_found := 0;
   first_file_not_found := "";
   for (;;) {
      word = parse_file(line);
      if (word=='') break;
      ch=substr(word,1,1);
      if (ch=='-' || ch=='+') {
         option=upcase(substr(word,2));
         switch (option) {
         case 'T':
            tree_option='+t';
            break;
         default:
            _message_box('Invalid switch');
            p_window_id=_lffiles;_set_sel(1,length(p_text)+1);_set_focus();
            return(1);
         }
      } else {
         ++Noffiles;
         if(isdirectory(word) || (blankOption == true)){
         } else if (file_match('-pd 'tree_option' 'word,1)=='') {
            _message_box(nls('File "%s" not found',word));
            p_window_id=_lffiles;_set_sel(1,length(p_text)+1);_set_focus();
            return(1);
         }
      }
   }
   result=_maybe_quote_filename(_lffiles.p_text);
   if (result=='') {
      result=ALLFILES_RE;
   }
   ret_val := "";
   if (_lfsubdir.p_value) {
      if (_lfdirs.p_value) {
         ret_val = '+t 'result;
      } else {
         ret_val = '+t -d 'result;
      }
   }else{
      if (_lfdirs.p_value) {
         ret_val='+d 'result;
      } else {
         ret_val='-d 'result;
      }
   }
   if (_lfhidden.p_value) {
      ret_val='+h 'ret_val;
   }
   if (_lfsystem.p_value) {
      ret_val='+s 'ret_val;
   }
   _save_form_response();
   p_active_form._delete_window(ret_val);
}


/**
 * Copies <i>source_file</i> to <i>dest_directory</i> concatenated to 
 * path_no_drive(source_file).  Preserves directory structure.  Destination 
 * directory is created if it does not exist.  Disk is formatted if necessary.  
 * Handles errors necessary for backing up a file.  Used in fileman mode.
 * 
 * @return  Returns 0 if successful.  Common return codes are: 1 (no 
 * parameters specified), ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, 
 * FILE_NOT_FOUND_RC, INSUFFICIENT_DISK_SPACE_RC, ERROR_CREATING_DIRECTORY_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, DRIVE_NOT_READY_RC, and 
 * PATH_NOT_FOUND_RC.  On error, message is displayed.
 *
 * @categories File_Functions
 */
_str _fm_subcopy(_str dest_path, _str doPause='')
{
   _str source=parse_file(dest_path);
   if ( source=='' || dest_path=='' ) {
      message(nls('Usage: subcopy source dest_path'));
      return(1);
   }
   _maybe_strip_filesep(dest_path);
   source_path := _strip_filename(absolute(source),'N');
   add_slash := "";
   for (;;) {
      if ( substr(dest_path,1,3)!='..'FILESEP && dest_path!='..' ) {
         break;
      }
      parse source_path with (FILESEP) source_path (FILESEP) +0 source_path;
      dest_path=substr(dest_path,4);
      add_slash=FILESEP;
   }
   name_part := _strip_filename(source,'P');
   if ( ! _isUnix() && (_Substr(dest_path,2,1)==':' || substr(dest_path,1,2):=='\\') ) {
      add_slash='';
   }
   if ( dest_path=='' ) {
      add_slash='';
   }
   destfilename := add_slash:+dest_path:+_strip_filename(source_path,'d'):+name_part;
   /* messageNwait('df='destfilename' d='dest_path' s='strip_filename(source_path,'d')' n='name_part) */
   return(fileman_command('subcopy 'dest_path,'-simple-copy',source,destfilename,doPause));

}
   _nocheck _control list1;


/** 
 * <pre>Executes a command built with the expression:
 *
 * (<i>operation</i>" "_maybe_quote_filename(<i>source</i>)" "_maybe_quote_filename(<i>destfilename</i>) )
 * 
 * and handles file I/O error recovery.
 * 
 * The <i>operation</i> parameter is typically a file management command 
 * that has already been implemented to be supported by this procedure, such as 
 * <b>_fm_subcopy</b>, <b>_fm_copy</b>, or <b>_fm_move</b>.  If you write a new 
 * command, be sure that it returns 0 when your command completes successfully.
 * 
 * The message, <i>msg</i>, is displayed in a full screen shell window 
 * before the command is executed.  If <i>arg2</i> is not '' , the user must 
 * close the fileman status window before this function will return.
 * </pre>
 * @return  Returns 0 if successful.  If the command returns a non-zero 
 * value, this function returns that value which could be anything.
 * @categories File_Functions
 */
_str fileman_command(_str msg, _str operation, 
                     _str source, _str destfilename,typeless doPause='')
{
   typeless shell_wait=0;
   _str line=operation " "_maybe_quote_filename(source) " "_maybe_quote_filename(destfilename);
   if ( doPause!='' ) {
      shell_wait=doPause & PAUSE_COMMAND;
   } else {
      shell_wait=0;
   }
   path := "";
   proc_name := "";
   args := "";
   typeless status=0;
   parse line with proc_name args;
   index := find_index(proc_name,PROC_TYPE|COMMAND_TYPE);
   typeless first_time=! shell_wait;
   for (;;) {
      if ( ! first_time ) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(msg);
            _shell_wid.list1.refresh();
         }
         first_time=0;
      }
      if (index) {
         status=call_index(args,index);
      } else{
         status=execute(line,"");
      }
      if ( ! status ) break;
      path=substr(destfilename,1,pathlen(destfilename)-1);
      /*  failure caused because directory does not exist */
      if ( status==PATH_NOT_FOUND_RC && ! isdirectory(path) ) {
         /* try to create the directory */
         status= make_path(absolute(path),1);
         if ( status ) {
            /* Can recover from access denied or insufficient disk space */
            status=recover_from_error(status,destfilename);
            if ( status ) {
               break;
            }
         }
         continue;
      }
      status=recover_from_error(status,destfilename);
      if ( status ) {
         break;
      }
   }
   if ( shell_wait ) {
      if ( status<0 && isinteger(status) ) {
         if ( _iswindow_valid(_shell_wid)) {
            _shell_wid.list1.insert_line(get_message(status));
            _shell_wid.list1.refresh();
         }
      }
   }
   if ( status==2 ) {  /* skip status? */
      return(0);
   }
   return(status);


}
/**
 * Creates the necessary multi-level directories in <i>path</i> so that files may be copied to <i>path</i>.
 * 
 * @param path  Input path or filename.  All subdirectories are created.  Last character may be a file separator character.
 * 
 * @return Returns 0 if successful.   Common return codes are PATH_NOT_FOUND_RC, INSUFFICIENT_DISK_SPACE_RC, and ACCESS_DENIED_RC.
 * @categories File_Functions
 */
_command int make_path(_str path='', typeless doShellMessages='') name_info(DIRNEW_ARG " "MORE_ARG',')
{
   //Second argument is not documented and is intended for fileman mode.
   shell_messages := doShellMessages!='';

   // prompt for directory if they do not specify one
   if ( path == "" ) {
      newPath := browseForNewPath(true, "creating new directory in", getcwd());
      if ( newPath == "" ) {
         return COMMAND_CANCELLED_RC;
      }
   }

   /* make this directory */
   if ( shell_messages ) {
      if ( _iswindow_valid(_shell_wid)) {
         _shell_wid.list1.insert_line('mkdir 'path);
         _shell_wid.list1.refresh();
      }
   }
   status:=_make_path(path,false);
   return(status);
}



static _str recover_from_error(int status, _str dest)
{
   text := "";
   line := "";
   name := "";
   line2 := "";
   typeless result=0;
   if ( status==INSUFFICIENT_DISK_SPACE_RC || status==ERROR_CREATING_DIRECTORY_RC ) {
      if (_isWindows()) {
         if ( status==INSUFFICIENT_DISK_SPACE_RC ) {
            text=nls('You have run out of disk space');
         } else {
            text=nls('Error creating directory entry.  Assuming you have run out of disk space');
         }
         result=_message_box(text"\n\n"nls('Do you have a spare formatted or unformatted disk?'),'',MB_YESNOCANCEL|MB_ICONQUESTION);
         if ( result!=IDYES ) {
            return(status);
         }
         result=_message_box(nls('Please insert disk in drive %s',upcase(substr(absolute(dest),1,2))),'',MB_OKCANCEL);
         if ( result!=IDOK ) {
            return(status);
         }
      } else {
         if ( status==INSUFFICIENT_DISK_SPACE_RC ) {
            _message_box(nls('You have run out of disk space'));
         } else {
            _message_box(nls("Error creating directory entry.  The possible causes are listed below."):+"\n\n":+
                '    1. 'nls('You may not have access for creating this directory.')"\n":+
                '    2. 'nls('You may have run out of disk space.')"\n":+
                '    3. 'nls('You may have hit an operating system limit.')"\n");
         }
         return(status);
      }
   } else if ( status==DRIVE_NOT_READY_RC ) {
      result=_message_box(nls('Please close the door of drive %s',upcase(substr(absolute(dest),1,2))),
                          '',MB_OKCANCEL);
      if ( result!=IDOK ) {
         return(status);
      }
   } else if ( status==DISK_IS_WRITE_PROTECTED_RC ) {
      result=_message_box(nls('Drive %s is write protected',upcase(substr(absolute(dest),1,2))),
                          '',MB_OKCANCEL);
      if ( result!=IDOK ) {
         return(status);
      }
   } else if ( status==GENERAL_FAILURE_RC || status==SECTOR_NOT_FOUND_RC ) {
      result=_message_box(nls('Drive %s is not formatted',upcase(substr(absolute(dest),1,2)))"\n\n":+
                          nls('Would you like your disk formatted?'),
                          '',MB_YESNOCANCEL|MB_ICONQUESTION);
      if ( result!=IDYES ) {
         return(status);
      }
      for (;;) {
         result = show('-modal _textbox_form',
                       'Format',             //Caption
                       0,                    //Flags
                       '',                   //use default textbox width
                       '',                   //Help item
                       '',                   //Buttons and captions
                       '',                   //Retrieve Name
                                             //Prompt
                       nls('Edit format command:'):+'format 'upcase(substr(absolute(dest),1,2))

                       );
         if (result == '') {
            return(status);
         }
         line=_param1;
         line2=line;
         name=parse_file(line2);
         if ( path_search(name,'PATH','P')=='' ) {
            _message_box(nls("Format program '%s' not found",name));
         } else {
            if ( _iswindow_valid(_shell_wid)) {
               _shell_wid.list1.insert_line(line);
               _shell_wid.list1.refresh();
            }
            status=execute(line,"");
            if (!status) break;
            if ( rc==FILE_NOT_FOUND_RC ) {
               _message_box(nls("Format program '%s' not found",name));
            } else {
               _message_box(nls("Error running format")"\n\n"get_message(status));
            }
         }
      }
      refresh();
   } else if ( rc==ACCESS_DENIED_RC ) {
      result=_message_box(nls('Access has been denied to Source or dest file')"\n\n":+
                      nls('Skip this file?'),
                      '',MB_YESNOCANCEL|MB_ICONQUESTION);
      if ( result==IDCANCEL ) {   /* Escape */
         return(status);
      }
      if ( result==IDNO) {   /* No */
         return(0);
      }
      return(2);            /* Return skip rc */
   } else {
      if (status<0) {
         _message_box(get_message(status));
      }
      return(status);
   }
   return(0);
}

/**
 * Copies <i>filename</i> specified to <i>directory</i> specified.  
 * <i>directory</i> is created if it does not exists.  Used by <b>fileman</b> 
 * mode.  For your own macros, you will probably want to use the 
 * <b>copy_file</b> function to copy files.
 * 
 * @param cmdline is a string in the format: <i>filename directory</i>
 * 
 * @return  Returns 0 if successful.  Common return codes are: 
 * ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, FILE_NOT_FOUND_RC, 
 * INSUFFICIENT_DISK_SPACE_RC, ERROR_CREATING_DIRECTORY_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, DRIVE_NOT_READY_RC, and 
 * PATH_NOT_FOUND_RC.  When invoked from the command line, error messages are 
 * displayed.
 * @categories File_Functions
 */
_str _fm_copy(_str cmdline, _str doPause=false)
{
   return(file_move_or_copy(cmdline,doPause,'copy'));

}

/**
 * Moves the <i>filename</i> specified to the <i>directory</i> specified.  
 * <i>directory</i> is created if it does not exist.  Used by <b>fileman</b> 
 * mode.
 * 
 * @param cmdline is a string in the format: <i>filename directory</i>
 * 
 * @return  Returns 0 if successful.  Common return codes are: 
 * ACCESS_DENIED_RC, ERROR_OPENING_FILE_RC, FILE_NOT_FOUND_RC, 
 * INSUFFICIENT_DISK_SPACE_RC, ERROR_CREATING_DIRECTORY_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, DRIVE_NOT_READY_RC,  and 
 * PATH_NOT_FOUND_RC.  When invoked from the command line, error messages are 
 * displayed.
 * @categories File_Functions
 */
_str _fm_move(_str cmdline, _str doPause=false)
{
   return(file_move_or_copy(cmdline,doPause,'move'));

}
static _str file_move_or_copy(_str cmdline,_str doPause, _str operation)
{
   _str source=parse_file(cmdline);
   _str dest_path=cmdline;
   if ( source=='' || dest_path=='' ) {
      return(1);
   }
   _maybe_append_filesep(dest_path);
   destfilename := dest_path:+_strip_filename(absolute(source),'P');
   return(fileman_command('file-'operation " "cmdline,'-simple-'operation,source,destfilename,doPause));

}
_str _simple_copy(_str dest)
{
   _str source=parse_file(dest);
   _str status=copy_file(source,dest);
   return(status);

}
_str _simple_move(_str dest)
{
   _str source=parse_file(dest);
   copy_file(source,dest);
   if ( ! rc ) {
     delete_file(source);
   }
   return(rc);

}

/** 
 * Erase the <i>filename</i> specified.  Used by fileman mode.  For your own 
 * macros, you will probably want to use the delete_file function to delete 
 * files.
 * 
 * @return  Returns 0 if successful.  Common return codes are 
 * ACCESS_DENIED_RC, FILE_NOT_FOUND_RC, DRIVE_NOT_READY_RC, and 
 * PATH_NOT_FOUND_RC.  When invoked from the command line, error messages are 
 * displayed.
 * @categories File_Functions
 */
_str _fm_erase(_str filename)
{
   filename=strip(filename,'B','"');
   typeless status=delete_file(filename);
   if ( status==FILE_NOT_FOUND_RC ) status=0;
   return(status);
}

_str _fm_edit(_str filename)
{
   filename=strip(filename,'B','"');
   typeless status = edit(_maybe_quote_filename(filename), EDIT_DEFAULT_FLAGS);
   if ( status==FILE_NOT_FOUND_RC ) status=0;
   return(status);
}

_str _fm_open(_str filename)
{
   filename=strip(filename,'B','"');
   _project_open_file(filename);
   //typeless status = edit(_maybe_quote_filename(filename), EDIT_DEFAULT_FLAGS);
   //if ( status==FILE_NOT_FOUND_RC ) status=0;
   return(0);
}

/**
 * NOTE: Under UNIX this function operates like the chmod command.
 * See man page for this command for syntax of arguments.
 * <pre>
 * <i>cmdline</i> is a string in the format: [+|-][R][H][S][A] <i>filename</i>
 * 
 *  Changes the attributes of the <i>filename</i> specified.  + adds the attribute and - removes the attribute.  The attributes have the following meaning:
 *    R        Read-only
 *    H        Hidden
 *    S        System
 *    A        Archive
 * </pre>
 * 
 * @return Returns 0 if successful.  Common return codes are FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC, ERROR_WRITING_FILE_RC, and INVALID_OPTION_RC.  On error, message is displayed.
 * @categories File_Functions
 */
_command chmod(_str files='') name_info(FILE_ARG',')
{
   _macro_delete_line();
   permissions := strip(parse_file(files),'B','"');
   for (;;) {
      p1 := "";
      parse permissions with p1 permissions ;
      if (p1=='') break;
      _chmod(p1' 'files);
   }
   if ( rc && last_index('','w')) {
      message(get_message(rc));
   }
   _macro_call('chmod', files);
   return(rc);

}
_str def_prompt;
static void fileman_prompt(_str &cmdline, _str append_to_prompt,
                           _str caption, _str prompt, _str help_item)
{
   proc_name := "";
   parse append_to_prompt with proc_name . ;
   proc_name=translate(proc_name,'_','-');
   _macro_delete_line();
   if (cmdline=='') {
      typeless result = show('-modal _textbox_form',
                    caption,              //Captions
                    TB_RETRIEVE_INIT,     //Flags
                    '',                   //use default textbox width
                    help_item,            //Help item
                    '',                   //Buttons and captions
                    proc_name,            //Retrieve Name
                    prompt                //Prompt
                    );
      if (result == '') {
         return;
      }
      cmdline=_param1;
   }
   _macro('m',_macro('s'));
   param1 := append_to_prompt' ':+cmdline;
   _macro_append('for_select('_quote(param1)','PAUSE_COMMAND');');
   for_select(param1,PAUSE_COMMAND);

}

/**
 * Displays the Backup dialog box used by the file manager to copy the 
 * selected files while preserving the directory structure of the original 
 * files.  Used by <b>fileman</b> mode.
 * 
 * This command is not supported in a keyboard macro
 * @categories File_Functions
 */
_command void fileman_backup(_str dest_dir='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_prompt(dest_dir,'-fm-subcopy %f',nls('Backup'),nls('Backup Files to Directory'),'backup dialog box');
}
//  This command is not supported in a keyboard macro


/**
 * Displays the <b>Copy dialog box</b> used by the file manager to copy the 
 * selected files to a directory you choose.
 * @categories File_Functions
 */
_command void fileman_copy(_str dest_dir='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_prompt(dest_dir,'-fm-copy %f',nls('Copy'),nls('Copy Files to Directory'),'copy dialog box');
}

/**
 * Displays the <b>Move dialog box</b> used by the file manager to move the 
 * selected files to a directory you choose.   The directory can be on a 
 * different drive.
 * <p>
 * This command is not supported in a keyboard macro
 * @categories File_Functions
 */
_command void fileman_move(_str dest_dir='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_prompt(dest_dir,'-fm-move %f',nls('Move'),nls('Move Files to Directory'),'move dialog box');
}


/**
 * Prompts you whether you wish to delete the selected files.  Used in 
 * <b>fileman</b> mode.
 * @categories File_Functions
 */
_command fileman_delete() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   int result=_message_box(nls('Delete Selected Files?'),'',MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result!=IDYES) {
      cancel();
      return(COMMAND_CANCELLED_RC);
   }
   return(for_select('_fm_erase %f',PAUSE_COMMAND));
}
/**
 * @categories File_Functions
 */
_command fileman_edit() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  return(for_select('_fm_edit %f',0,'1','Edit (File Manager)'));
}


/**
 * Displays the Set Attributes dialog box used by the file manager to change 
 * attributes (UNIX: permissions) on the selected files.  Used by <b>fileman</b> 
 * mode.
 * @categories File_Functions
 */
_command fileman_attr(_str result='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   shell_wait := true;
   _macro_delete_line();
   if (result=='') {
      if (_isUnix()) {
         result=show('-modal _unixfmattr_form','','',nls("?Sets the Read and Write permissions of the selected files."));
      } else {
         result=show('-modal _fmattr_form','','', 'Set Attributes dialog');
      }
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      plus := "";
      minus := "";
      parse result with . plus minus ;
      if (_param2=='+') plus='';
      if (_param3=='-') minus='';
      result=_maybe_quote_filename(_param2' '_param3);
   }
   _macro('m',_macro('s'));
   _str param1='chmod 'result' %f';
   _macro_call('for_select',param1,shell_wait);
   typeless status=for_select(param1,shell_wait);
   return(status);

}


/**
 * If the visible cursor is in the text area, the select character '>' is 
 * toggled on or off.  Otherwise the default binding of space bar is executed.  
 * Used by <b>fileman</b> mode.
 * @categories File_Functions
 */
_command fileman_space() name_info(','VSARG2_CMDLINE|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if ( command_state() ) {
      maybe_normal_character();
   } else {
      line := "";
      get_line(line);
      if ( substr(line,1,1)=='>' ) {
         replace_line(' 'substr(line,2));
         return(-1);
      }
      replace_line('>'substr(line,2));
      return(1);
   }

}


/**
 * Replaces the first character of the current line with '>' and moves the 
 * cursor to previous line.  Used by <b>fileman</b> mode.
 * @categories File_Functions
 */
_command void fileman_select_up() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_set_select_up('>');

}


/**
 * Removes the '>' character at the beginning of the current line and moves 
 * the cursor to previous line.  Used by <b>fileman</b> mode.
 * @categories File_Functions
 */
_command void fileman_deselect_up() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_set_select_up(' ');

}


/**
 * Replaces the first character of the current line with '>' and moves the 
 * cursor to next line.  Used by <b>fileman</b> mode.
 * @categories File_Functions
 */
_command void fileman_select_down() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_set_select_down('>');
}


/**
 * Removes the '>' character at the beginning of the current line and moves 
 * the cursor to next line.  Used by <b>fileman</b> mode.
 * @categories File_Functions
 */
_command void fileman_deselect_down() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   fileman_set_select_down(' ');

}
static void fileman_set_select_up(_str ch)
{
   if ( command_state() ) {
      maybe_normal_character();
   } else {
      line := "";
      get_line(line);
      replace_line(ch:+substr(line,2));
      up();
   }

}
static void fileman_set_select_down(_str ch)
{
   if ( command_state() ) {
      maybe_normal_character();
   } else {
      line := "";
      get_line(line);
      replace_line(ch:+substr(line,2));
      down();
   }

}


/**
 * Displays help for fileman mode.
 * @categories Miscellaneous_Functions
 */
_command void fileman_help() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   help('SlickEdit File Manager');

}


/**
 * Keys in file name at text cursor into the command line.  Used by 
 * <b>fileman</b> mode.
 * 
 * @see  keyin_buf_name
 * @categories File_Functions
 */
_command void fileman_keyin_name() name_info(','VSARG2_CMDLINE)
{
   _macro_delete_line();
   if ( command_state() ) {
      line := "";
      _edit_window().get_line(line);
      keyin(pcfilename(line));
      _macro_call('fileman_keyin_name');
   }
}
/**
 * @categories File_Functions
 */
_command fileman_open() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  return(for_select('_fm_open %f',0,'1','Edit (File Manager)'));
}
/**
 * Appends the list specified to the current file.  All columns are updated 
 * to the current file info.  Files read by this command can be written 
 * using <b>write_list</b>, <b>put</b>, or any save command.  A file 
 * list of absolute or relative file names starting in column one is 
 * accepted.  This command is intended to be used when in 
 * <b>fileman</b> mode.
 * 
 * @return Returns 0 if successful.  Common return codes are 
 * FILE_NOT_FOUND_RC, and PATH_NOT_FOUND_RC.  On error, 
 * message is displayed.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */ 
_command read_list(_str filename='', _str arg2='', _str options='') name_info(FILE_ARG','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless result=0;
   if (filename=='') {
      _macro_delete_line();
      result=_OpenDialog('-modal',
           'Read List', ALLFILES_RE,
           "All Files ("ALLFILES_RE")",
           OFN_FILEMUSTEXIST,
           '',          // Default extensions
           '',          // Initial filename
           '',          // Initial directory
           'read_list', // Retrieve name
           'read list dialog box'  // Help item
           );
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',_macro('s'));
      _macro_call('read_list',result);
      filename=result;
   }
   bottom();
   typeless status=get(filename,'','A');   /* Get list from disk */
   if ( status ) {
      return(status);
   }
   message(nls('Reading new file size, date, time , and attributes...'));
   down();
   linenum := 0;
   start_col := 0;
   line := "";
   name := "";
   get_line(line);
   first_ch := substr(line,1,2);
   if ( first_ch=='' || first_ch=='>' ) {
      start_col=DIR_FILE_COL;
   } else {
      start_col=1;
   }
   for (;;) {
      if ( start_col!=1 ) {
         get_line(line);
         name=pcfile(line);
      } else {
         get_line(name);
      }
      if ( name!='.' && name!='..' ) {
         if ( start_col!=1 ) {
            name=pcfilename(line);
         }
         linenum=p_line;
         _delete_line();
         if ( p_line==linenum ) {
            up();
         }
         if ( iswildcard(name) && !file_exists(name) ) {
            status=insert_file_list('+P 'options " "name);
         } else {
            status=insert_file_list('+RHSDP 'options " "name);
            /* get_line line */
            /* up;_delete_line */
            /* replace_line ' 'substr(line,2) */
         }
         if ( status && ! iswildcard(name) ) {
            message(nls("Error reading '%s'",name)". "get_message(status));
            return(status);
         } else if (status) {
            message(get_message(status));
         }
      }

      if ( down() ) {
         rc=0;
         break;
      }
   }
   clear_message();
   old_line := p_line;
   top();get_line(line);
   if ( line=='' ) {
      _delete_line();
      old_line--;
   }
   p_line=old_line;
   return(0);


}
/**
 * Writes the current buffer to <i>filename</i>.  If <i>filename</i> is 
 * not specified you are prompted for a filename.  The <b>write_list</b> 
 * command may be used to create a list of file names for the 
 * <b>make_tags</b> command.  The save command is the fastest way 
 * to save a file manager list.  However, its format is not accepted by the 
 * <b>make_tags</b> command and may not be accepted by other 
 * programs.  Used in fileman mode.
 * 
 * @return Returns 0 if successful.  Common return codes are 1 (select file(s) 
 * first), INVALID_OPTION_RC, ACCESS_DENIED_RC, 
 * ERROR_OPENING_FILE_RC, INSUFFICIENT_DISK_SPACE_RC, 
 * ERROR_READING_FILE_RC, ERROR_WRITING_FILE_RC, 
 * DRIVE_NOT_READY_RC, and PATH_NOT_FOUND_RC.  On 
 * error, message displayed.
 * 
 * @categories File_Functions
 * 
 */ 
_command write_list(_str params='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (params=='') {
      _macro_delete_line();
      typeless result=_OpenDialog('-new -mdi -modal',
           'Write List',
           '',     // Initial wildcards
           "All Files ("ALLFILES_RE")",
           OFN_SAVEAS|OFN_KEEPOLDFILE,
           '',      // Default extensions
           '',      // Initial filename
           '',          // Initial directory
           'write_list', // Retrieve name
           'write list dialog box'  // Help item
           );
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',_macro('s'));
      _macro_call('write',result);
      params=result;
   }
   _str options;
   params = strip_options(params, options);
   _str filename=parse_file(params,false);
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id,'',absolute(filename));
   if ( params=='' ) {
      params='%f';
   }
   activate_window(orig_view_id);
   top();
   typeless status=search('^>','@r');
   if ( status ) {
      message(nls('Select file(s) first.'));
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return(1);
   }
   line := "";
   name := "";
   for (;;) {
      if ( status ) {
         break;
      }
      get_line(line);
      activate_window(temp_view_id);
      name=pcfile(line);
      if ( name!='.' && name!='..' && ! pos('<DIR>',line)  ) {
         insert_line(parsecommand(params,line));
      }
      activate_window(orig_view_id);
      status=repeat_search();
   }
   activate_window(temp_view_id);
   status=save();
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(status);

}

/**
 * Loads the <i>filename</i> specified and executes the <i>command</i> specified.  
 * If <i>command</i> modifies the file, a prompt appears asking whether to save 
 * the file.  The file is quit if it has been saved or is not modified.  This 
 * command is useful in <b>fileman</b> mode for executing the change command 
 * on the selected files.
 * 
 * @param cmdline   a string in the format: <i>filename command</i>
 * 
 * @example
 * <pre>
 *    <b>for-select edit-with %f  c/string1/string2</b>  
 *    <b>for-select edit-with %f  c/string1/string2/</b><b>**</b>   No prompting
 * </pre>
 * @return  Returns 0 if <i>command</i> executes successfully.  If <i>command</i> 
 * returns a non-zero value, the <b>edit_with</b> function returns the commands 
 * return code which could be anything.
 *
 * @categories Miscellaneous_Functions
 */
_command edit_with(_str command='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _str filename=parse_file(command);
   typeless status= edit(filename);
   if ( status ) {
      return(status);
   }
   top();
   execute(command,"");
   if ( rc==STRING_NOT_FOUND_RC ) {
      rc=0;
   }
   status=rc;
   if ( p_modify ) {
      typeless select=nls_letter_prompt(nls('File has been modified.  Save file (~y or ~n)?'));
      if ( select==1 ) {
         status=save();
         if ( status ) {
            return(status);
         }
      }
   }
   if ( ! status ) {
      quit(false);
   }
   return(status);

}
/**
 * Repeat search function used as input to the <b>process_list</b> 
 * procedure.
 * 
 * @return Returns 0 if search string found.
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */ 
_str prepeat_search()
{
   repeat_search();
   return(rc);

}
/**
 * Search function used as input to the <b>process_list</b> procedure.  
 * Uses <b>search</b> built-in to search for <i>string</i> in specified 
 * search <i>options</i>.  See <b>search</b> built-in for options 
 * allowed.
 * 
 * @return Returns 0 if the search string specified is found.  Common return 
 * codes are STRING_NOT_FOUND_RC, INVALID_OPTION_RC, and 
 * INVALID_REGULAR_EXPRESSION_RC.  On error, message is 
 * displayed.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */ 
_str psearch(_str string, _str options)
{
   search(string, options);
   return(rc);

}
/**
 * Deletes the current line and moves the cursor to column one.  This 
 * function is used as input to the <b>process_list</b> procedure.
 * 
 * @return Returns 0.
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 */ 
int zap_line()
{
   typeless p=point();
   _delete_line();
   if ( p==point() ) { /* On same line number? */
      /* Got to end of previous line. */
      up();
   }
   _end_line();
   return(0);

}
defeventtab _fmulsrch_form;
_findok.lbutton_up()
{
   _save_form_response();
   _param1=text1.p_text;
   _param2='';
   if (_findcase.p_value) {
      _param2='E';
   } else {
      _param2='I';
   }
   if (_findword.p_value) {
      _param2 :+= 'W';
   }
   if (_findre.p_value) {
      _param2 :+= 'R';
   }
   p_active_form._delete_window(0);
}
_findok.on_create()
{
   _retrieve_prev_form();
}
/**
 * Delete lines that match.
 *  
 * <p>Typically used in fileman mode.
 * 
 * @categories File_Functions
 * 
 */ 
_command int unlist_search(_str search_string='', _str search_options=null) name_info(','VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Backward compatibility for all argument signature
   // This may be pulled at a later time.
   if (arg()>=3) {
      search_options=arg(3);
   }
   if (search_options==null) {
      parse search_string with  1 auto delim +1  search_string (delim) search_options;
   }
   if (_default_option('s')&IGNORECASE_SEARCH) {
      search_options='I':+search_options;
   } else {
      search_options='E':+search_options;
   }
   if (search_string=='') {
      _macro_delete_line();
      typeless result=show('-modal _fmulsrch_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      search_string=_param1;
      search_options=_param2;
      _macro('m',_macro('s'));
      _macro_call('unlist_search',search_string,search_options);
   }
   typeless status=process_list('psearch',search_string,search_options,'psearch','zap-line');
   return(status);
}
/**
 * Deletes all lines of the current buffer.  The lines may be retrieved with 
 * the command <b>paste</b>.  Used in fileman mode
 * 
 * @see _lbclear
 * 
 * @categories File_Functions
 * 
 */ 
_command unlist_all() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   top();_select_line(mark);
   bottom();_select_line(mark);
   _delete_selection(mark);
   _free_selection(mark);
   _begin_line();p_modify=false;
   return(0);

}
/**
 * Lines beginning with the character '>' are deleted.  Used in fileman 
 * mode.
 *  
 * @categories File_Functions
 * 
 */ 
_command void unlist_select() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   column_process_list(1,1,'^>','zap-line','r');
}
/** 
 * Deletes lines of files with a specified <i>extension</i>.  A dialog box 
 * is displayed which prompts you for an extension.  Used in fileman mode.
 * 
 * @see unlist_ext
 * 
 * @categories File_Functions
 * 
 */
_command gui_unlist_ext() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   typeless result = show('-modal _textbox_form',
                 'Unlist Extension',             //Captions
                 TB_RETRIEVE_INIT,               //Flags
                 '',                             //use default textbox width
                 'Unlist Files With Extension dialog',               //Help item
                 '',                             //Buttons and captions
                 'unlist_ext',                   //Retrieve Name
                 'Unlist files with extension'   //Prompt
                 );
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   result=_param1;
   _macro('m',_macro('s'));
   _macro_call('unlist_ext',result);
   return(unlist_ext(result));
}
/**
 * Deletes lines of files with the specified <i>extension</i>.  Used in 
 * fileman mode.
 * 
 * @categories File_Functions
 * 
 */ 
_command unlist_ext(_str extension='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if (substr(extension,1,1)=='.') {
      extension=substr(extension,2);
   }
   if ( extension=='<' ) {
      extension=prompt();
   }
   search_string := "";
   sep := "";
   sep1 := "";
   sep2 := "";
   if ( extension=='' ) {
      //search_string='(\\|\:)([~.\[\]\:\\/<>|=+;, \t]#)$'
      if (_isWindows()) {
         sep1='(\\|\:)';
         sep2='\\';
      } else {
         sep1='//';
         sep2='//';
      }
      sep='\'FILESEP;
      search_string=sep1'[~.'sep1']*$';
   } else {
      search_string='.'extension'$';
   }
   typeless status=column_process_list(DIR_FILE_COL,255-DIR_FILE_COL,
                            search_string,'zap_line','r'_fpos_case);
   return(status);
}
/**
 * Deletes lines of files with the specified attribute(s).  If more than one 
 * file attribute is given, they must appear in the same order as the 
 * attributes column with dashes present if necessary so that a column 
 * search can be performed.  Used in fileman mode
 * 
 * @see fileman_attr
 * 
 * @categories File_Functions
 * 
 */ 
_command unlist_attr(_str result='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   if (result=='') {
      if (_isUnix()) {
         result=show('-modal _unixfmattr_form',nls('Unlist Files With Attribute'),'unlist_attr',
             'Unlist Files with Attributes dialog');
      } else {
         result=show('-modal _fmattr_form',nls('Unlist Files With Permissions'),'unlist_attr',
             'Unlist Files with Attributes dialog');
      }
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      result=_param1;
   }
   _macro('m',_macro('s'));
   _macro_call('unlist_attr',result);
   typeless status=column_process_list(DIR_ATTR_COL,DIR_ATTR_WIDTH,
                            attr_case(result),'zap-line','r');
   return(status);
}
_command void fileman_select_all() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   select_all_line();
}
/**
 * If the current mode is fileman mode, a '>' character is placed in column
 * one of all lines of the current buffer.  Otherwise, all lines in the
 * current buffer are selected with a LINE selection or CHAR
 * selection depending on the argument and def_select_all_line.
 * 
 * @param optionstr   If optionstr=='LINE' or 
 *                    def_select_all_line is true, a LINE
 *                    selection is used to select all the text
 *                    in the current buffer. Set optionstr to
 *                    'CHAR' if you want character selection.
 *                    The def_select_all_line option is used if
 *                    optionstr is ''.
 * 
 * @see select_all
 * @see select_all_char
 * @see select_all_line
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 * 
 */
_command void select_all(_str optionstr='LINE') name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_READ_ONLY)
{
   if (command_state()) {
      _set_sel(1,length(p_text)+1);
      return;
   }
   if (p_LangId == 'fileman') {
      set_select('>');
   } else {
      //save_pos(p);

      // maybe they want to select text in the editor mouse over dialog
      if (_ECCommandCallback("selectall")) return;
      save_pos(auto p);
      top();deselect();
      if (_on_line0()) {
         return;
      }
      mstyle := "";
      if ( def_persistent_select=='Y' ) {
         mstyle='EP';
      } else {
         mstyle='E';
      }
      bool do_select_line=false;
      if (optionstr=='') {
         do_select_line=def_select_all_line;
      } else {
         do_select_line=optionstr=='LINE';
      }
      if (do_select_line) {
         if ( _select_type()=='' ) {
            status:=_select_line('',mstyle);
            if (status) {
               message(get_message(status));
               return;
            }
         }
         bottom();
         if(_line_length(true)==0) {
            up();
            // IF there are no lines to copy
            if (_on_line0()) {
               deselect();
               restore_pos(p);
               return;
            }
         }
         _select_line('',mstyle);
      } else {
         if ( _select_type()=='' ) {
            status:=_select_char('',mstyle);
            if (status) {
               message(get_message(status));
               return;
            }
         }
         bottom();
         int len1=_line_length();
         int len2=_line_length(true);
         if(len1!=len2) {
            if (p_hex_mode==HM_HEX_ON && def_hex_binary_copy) {
               while (len1<len2) {
                  ++len1;
                  ++p_col;
               }
            } else {
               right();
            }
         }
         _select_char('',mstyle);
      }
   }
}

/**
 * If the current mode is fileman mode, a '>' character is placed in column 
 * one of all lines of the current buffer.  Otherwise, all lines in the 
 * current buffer are selected with a LINE selection.
 * 
 * @see select_all
 * @see select_all_char
 * @see select_all_line
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command void select_all_line() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_READ_ONLY)
{
   select_all('LINE');
}
/**
 * If the current mode is fileman mode, a '>' character is placed in column 
 * one of all lines of the current buffer.  Otherwise, use a non-inclusive CHAR
 * selection to select the entire file.
 * 
 * @see select_all
 * @see select_all_char
 * @see select_all_line
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command void select_all_char() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_TEXT_BOX|VSARG2_READ_ONLY)
{
   select_all('CHAR');
}


/**
 * Removes the character '>' from the beginning of each line of the 
 * current buffer.  Typically used in fileman mode.  Use the <b>fileman</b> 
 * command ("File", "File Manager...", "New List...") to start fileman mode.
 * @categories Miscellaneous_Functions
 */
_command void deselect_all() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // maybe they want to deselect text in the editor mouse over dialog
   if (_ECCommandCallback("deselect")) return;

   set_select(' ');
}
/**
 * Replaces the first character of each line of the current buffer with 
 * <i>ch</i>.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
void set_select(_str ch)
{
   line := "";
   top();
   for (;;) {
      get_line(line);
      replace_line(ch:+substr(line,2));
      down();
      if ( rc ) {
         break;
      }
   }

}
/**
 * Places the character '>' in column one for all the selected lines.  Used 
 * in fileman mode.
 * 
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command void select_mark() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   set_mark_select('>');
}

/**
 * Removes the character '>' from the beginning of each line of the marked 
 * text.  Typically used in fileman mode.  Use the <b>fileman</b> command 
 * ("File", "File Manager...", "New List...") to start fileman mode.
 * @categories Selection_Functions
 */
_command void deselect_mark() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   set_mark_select(' ');

}
/**
 * Replaces the first character of each line of the marked text with 
 * <i>ch</i>.
 * 
 * @categories Selection_Functions
 * 
 */ 
void set_mark_select(_str ch)
{
   first_col := last_col := buf_id := 0;
   _get_selinfo(first_col,last_col,buf_id);
   if ( rc || buf_id!=p_buf_id ) {
      message (get_message(TEXT_NOT_SELECTED_RC));
      return;
   }
   _begin_select();
   line := "";
   for (;;) {
      get_line(line);
      replace_line(ch:+substr(line,2));
      down();
      if ( rc || _end_select_compare()>0 ) {
         break;
      }
   }

}
/**
 * Places the character '>' in column one for each line of the current 
 * buffer which does not have a '>' in column one.  For each line of the 
 * current buffer which does have the character '>' in column, a space is 
 * entered in column one.  Used in fileman mode.
 * 
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command void select_reverse() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   line := "";
   top();
   for (;;) {
      get_line(line);
      if ( substr(line,1,1)=='>' ) {
         replace_line(' ':+substr(line,2));
      } else {
         replace_line('>':+substr(line,2));
      }
      down();
      if ( rc ) {
         break;
      }
   }

}
/** 
 * Places the character '>' in column one for all files that have the 
 * <i>extension</i> specified.  A dialog box is displayed to prompt you for an 
 * extension.  Used in <b>fileman</b> mode.
 * 
 * @see select_ext
 *
 * @categories File_Functions
 * 
 */
_command gui_select_ext() name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   typeless result = show('-modal _textbox_form',
                 'Select Extension',             //Captions
                 TB_RETRIEVE_INIT,               //Flags
                 '',                             //use default textbox width
                 'Select Files With Extension dialog',               //Help item
                 '',                             //Buttons and captions
                 'select_ext',                   //Retrieve Name
                 'Select files with extension'   //Prompt
                 );
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   result=_param1;
   _macro('m',_macro('s'));
   _macro_call('select_ext',result);
   return(select_ext(result));
}

/**
 * Places the character '>' in column one for all files that have the 
 * <i>extension</i> specified.  Used in fileman mode.
 * 
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command void select_ext(_str extensions='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Go thru the list of extensions:
   while (1) {
      arg1 := "";
      parse extensions with arg1 extensions;
      if (arg1 == "") break;
      if (substr(arg1,1,1)=='.') arg1=substr(arg1,2);
      if ( arg1=='<' ) {
         arg1=prompt();
      }
      sep := "";
      sep1 := "";
      sep2 := "";
      search_string := "";
      if ( arg1=='' ) {
         //search_string='(\\|\:)([~.\[\]\:\\/<>|=+;, \t]#)$'
         if (_isWindows()) {
            sep1='(\\|\:)';
            sep2='\\';
         } else {
            sep1='//';
            sep2='//';
         }
         sep='\'FILESEP;
         search_string=sep1'[~.'sep1']*$';
      } else {
         search_string='.'arg1'$';
      }
      column_process_list(DIR_FILE_COL,255-DIR_FILE_COL,
                               search_string,'_fselect_line','r'_fpos_case);
   }
}
/**
 * Places the character '>' in column one for all files that have the 
 * attribute(s) specified.  If more than one file attribute is given, they 
 * must appear in the same order as the attributes column with dashes 
 * present if necessary so that a column search match can be performed.  
 * Used in fileman mode.
 * 
 * @see dir
 * @see list
 * @see fileman
 * 
 * @categories File_Functions
 * 
 */ 
_command select_attr(_str result='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   if (result=='') {
      if (_isUnix()) {
         result=show('-modal _unixfmattr_form',nls('Select Files With Permissions'),'select_attr','Select Files With Attribute dialog');
      } else {
         result=show('-modal _fmattr_form',nls('Select Files With Attribute'),'select_attr','Select Files With Attribute dialog');
      }
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      result=_param1;
   }
   _macro('m',_macro('s'));
   _macro_call('select_attr',result);
   typeless status=column_process_list(DIR_ATTR_COL,DIR_ATTR_WIDTH,
                            attr_case(result),'_fselect_line','r');
   return(status);

}

/**
 * Replaces the first character of the current line with '>'.  This function 
 * is used as input to the process_list procedure.
 * 
 * @return  Returns 0.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_str _fselect_line()
{
   line := "";
   get_line(line);
   replace_line('>':+substr(line,2));
   return(0);
}
/*

   The filemanager uses this function to delete entries from the file
   list and select entries in the file list.

   INPUT

      search_fun        Name of procedure to perform first search.
                        The call looks like this:

                          search_fun(search_string,search_options)

                        Search function must return non zero status
                        if string is not found.  Use a pre-existing
                        search function such as "psearch" if possible.

      search_string     Search string given as argument to search_fun
                        and repeat_search_fun.

      search_options    Options given as argument to search_fun and
                        repeat_search_fun.  The character 'm' must
                        mean searching within a marked area.  The
                        character '*' means perform action without
                        prompting.  By default, the user is prompted
                        with "Yes/No/Last/Go/Quit?" before the action
                        is performed.


      repeat_search_fun Name of procedure to proform subsequent searching.
                        The call looks like this:

                          repeat_search_fun(search_string,search_options)

                        Search function must return non zero status
                        if string is not found.  Use a pre-existing
                        search function such as "psearch" or
                        "prepeat-search" if possible.

      action_fun        Name of procedure which operates on lines.
                        Use a pre-existing action function
                        such as "zap-line" or "_fselect_line" if
                        possible.


  OUTPUT

    *  Returns 0 if successful

*/
/**
 * <b>process_list</b> is a generic list processing function.  The file manager 
 * uses this function to delete or select entries from the file list.
 * 
 * @return Returns 0 if successful.  Otherwise a non-zero value is returned.  On 
 * error, message is displayed.
 * 
 * @param search_fun
 *         Name of procedure to perform first search. The call looks like this:
 * 
 * <p>The call looks like this:</p>
 * 
 * <p><i>search_fun</i>(<i>search_string</i>, 
 * <i>search_options</i>)</p>
 * 
 * <p>Search function must return non-zero status if 
 * string is not found.  Use a pre-existing search 
 * function such as "psearch" if possible.</p>
 * 
 * <dl>
 * <dt><i>search_string</i></dt><dd>Search string given as argument to 
 * <i>search_fun</i> and <i>repeat_search_fun</i>.</dd>
 * 
 * <dt><i>search_options</i></dt><dd>Options given as argument to 
 * <i>search_fun</i> and <i>repeat_search_fun</i>.  The character 'm' 
 * must mean searching within a marked area.  The character '*' means perform action 
 * without prompting.  By default, the user is prompted with "Yes/No/Last/Go/Quit?" 
 * before the action is performed.</dd>
 * 
 * <dt><i>repeat_search_fun</i></dt><dd>Name of procedure to perform 
 * subsequent searching.  The call looks like this:</dd>
 * </dl>
 *           
 * <p><i>repeat_search_fun</i>(<i>search_string</
 * i>, <i>search_options</i>)</p>
 * 
 * <p>Search function must return non-zero status if 
 * string is not found.  Use a pre-existing search 
 * function such as "psearch" or 
 * "prepeat_search" if possible.</p>
 * 
 * <dl>
 * <dt><i>action_fun</i></dt><dd>Name of procedure which operates on lines 
 * found by search functions.  Use a pre-existing 
 * action function such as "zap_line" or 
 * "_fselect_line" if possible.</dd>
 * </dl>
 * 
 * <p>The cursor position is left at the position after the last call to the 
 * <i>action_fun</i> or <i>repeat_search_fun</i>.</p>
 * 
 * @example
 * <pre>
 *           defmain()
 *           {
 *              // Remove all lines in the current buffer containing the word 
 *              //  junk in any case without prompting.
 *              top();
 *              process_list('psearch','junk','I*','prepeat_search','zap_line');
 *           }
 * </pre>
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 * 
 */ 
_str process_list(_str search_fun, _str search_string, _str search_options,
                  _str repeat_search_fun, _str action_fun)
{
   search_index := find_index(search_fun,PROC_TYPE|COMMAND_TYPE);
   repeat_search_index := find_index(repeat_search_fun,PROC_TYPE|COMMAND_TYPE);
   action_index := find_index(action_fun,PROC_TYPE|COMMAND_TYPE);
   if ( ! index_callable(search_index) ||
       ! index_callable(repeat_search_index) ||
       ! index_callable(action_index) ) {
     message('process-list:  'nls('Could not find function'));
     return(STRING_NOT_FOUND_RC);
   }
   typeless old_scroll_style=_scroll_style();
   _scroll_style('c');
   nls_chars := "";
   _str msg=nls_strip_chars(nls_chars,"~Yes/~No/~Last/~Go/~Quit ?");
   typeless status=call_index(search_string,search_options,search_index);
   found_one := false;
   go := pos('*',search_options);
   done := false;
   for (;;) {
     if ( status ) { break; }
     found_one=true;
     down();
     done=rc;    /* last line of file? */
     if ( ! done ) {
       up();
     }
     if ( go ) {
       status=call_index(action_index);
     } else {
       message(msg);
       for (;;) {
          k := upcase(get_event());
          select := pos(k,nls_chars);
          if ( select==1 ) {
            status=call_index(action_index);
            break;
          } else if ( select==2 ) {
             down();_begin_line();
             break;
          } else if ( select==3 ) {
            status=call_index(action_index);
            done=true;
            break;
          } else if ( select==4 ) {
            go=1;clear_message();
            status=call_index(action_index);
            break;
          } else if ( select==5 || iscancel(k) ) {
            done=true;
            break;
          }
       }
     }
     if ( done || status ) {
        if ( done ) { clear_message(); }
        break;
     }
     status=call_index(search_string,search_options,repeat_search_index);
   }
   _scroll_style(old_scroll_style);
   if ( status==0 ) {
     clear_message();
   }
   if ( found_one && status==STRING_NOT_FOUND_RC ) {
     clear_message();
     status=0;
   }
   return(status);



/*
File Attribute         ; return select-attr   ;popup-help select-attr command
File extension         ; return select-ext    ;popup-help select-ext  command
   unlist-ext */

}


/**
 * Generic column list processing function.
 * For each line in the current buffer containing an occurrence of string 
 * <i>search_string</i> within the columns specified by <i>first_col</i> and 
 * <i>col_width</i>, <i>action_fun</i> is executed with that line as the current 
 * line.  The cursor is placed on the last line with a match.
 * 
 * @param first_col  Start column of area to be searched within.
 * @param col_width  Width of area to be searched.
 * @param search_string String to search for in area specified.
 * @param action_fun Name of procedure which operates on lines found by search.  
 * Use a pre-existing action function such as zap_line or _fselect_line if possible.  
 * The zap_line procedure deletes the current line.  The _fselect_line procedure 
 * replaces the first character of the current line with '>'.
 * @param search_options Optionally specifies that search_string is a regular 
 * expression.  Specify 'r' for regular expression.  See <b>Regular Expressions</b> 
 * for more information.
 * 
 * @return  Returns 0 if successful.  Otherwise TOO_MANY_SELECTIONS_RC is returned.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
_str column_process_list(int first_col, int col_width,
                         _str search_string, _str action_fun, _str search_opts='')
{
   typeless old_mark=_duplicate_selection('');   /* save activae mark id. */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   bottom();p_col=first_col+col_width-1;_select_block(mark);
   top()   ;p_col=first_col;_select_block(mark);
   _show_selection(mark);
   repeat_search_fun := "prepeat-search";
   if ( first_col==1 && action_fun:=='zap-line' ) {
      repeat_search_fun='psearch';
   }
   process_list('psearch',search_string,'*m':+search_opts,repeat_search_fun,action_fun);
   _show_selection(old_mark);
   _free_selection(mark);
   return(0);

}
defeventtab _fmreplace_form;
_replaceok.lbutton_up()
{
   _save_form_response();
   _param1=_findstring.p_text;
   options := "";
   if (_findcase.p_value) {
      options='E';
   } else {
      options='I';
   }
   if (_findword.p_value) {
      options :+= 'W';
   }
   if (_findre.p_value) {
      if (def_re_search_flags&PERLRE_SEARCH) {
         options :+= 'L';
      }else {
         //if (def_re_search_flags&BRIEFRE_SEARCH) {
         //   options=options:+'B';
         //}else{
            options :+= 'R';
         //}
      }
   }
   if (_findcursorend.p_value) {
      options :+= '>';
   }
   _param2=_replacestring.p_text;
   _param3=options;
   p_active_form._delete_window(0);
}
_replaceok.on_create()
{
   _retrieve_prev_form();
}


/**
 * Performs a search and replace on the selected files.  This command is used 
 * while in <b>fileman</b> mode to perform a search and replace across multiple 
 * files and directories.  The dialog box this command displays is similar to 
 * the Replace dialog box (see <b>gui_replace</b> command for more information).
 * 
 * @return  Returns 0 if successful.   Otherwise, a non-zero number is 
 * returned.
 * @categories File_Functions, Search_Functions
 */
_command int fileman_replace(_str search_string='', _str replace_string='', _str options='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   typeless result='';
   _macro_delete_line();
   if (search_string=='') {
      result=show('-modal _fmreplace_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',_macro('s'));
      search_string=_param1;
      replace_string=_param2;
      options=_param3;
   }
   orig_wid := p_window_id;
   int orig_buf_id=p_buf_id;
   typeless atbuflist=fmmulti_select_result('','1');
   if (atbuflist=='') {
      _message_box('No files selected');
      return(1);
   }
   _macro_call('fileman_replace',search_string,replace_string,options);
   typeless status=_mfreplace(search_string,replace_string,options,atbuflist,'');
   typeless last_file=rc;
   if (last_file!='') {
      new_wid := p_window_id;
      int new_buf_id=p_buf_id;
      p_window_id=orig_wid;
      p_buf_id=orig_buf_id;
      // Position cursor in file manager list where user aborted
      save_pos(auto p);
      top();
      status=search(last_file,'@'_fpos_case);
      for (;;) {
         if (status) break;
         if (p_col==DIR_FILE_COL) break;  // Found it
         status=repeat_search();
      }
      if (status) restore_pos(p);
      p_window_id=new_wid;
      p_buf_id=new_buf_id;
   }
   return(status);
}


defeventtab _fmfind_form;
_findok.lbutton_up()
{
   _save_form_response();
   _param1=_findstring.p_text;
   options := "";
   mfflags := 0;
   if (_findcase.p_value) {
      options='E';
   } else {
      options='I';
   }
   if (_findword.p_value) {
      options :+= 'W';
   }
   if (_findre.p_value) {
      if (def_re_search_flags&PERLRE_SEARCH) {
         options :+= 'L';
      }else {
         //if (def_re_search_flags&BRIEFRE_SEARCH) {
         //   options=options:+'B';
         //}else{
            options :+= 'R';
         //}
      }
   }
   if (_findcursorend.p_value) {
      options :+= '>';
   }
   if (_global.p_value) {
      mfflags|=MFFIND_GLOBAL;
   }
   _param2=options;
   _param3=mfflags;
   p_active_form._delete_window(0);
}
_findok.on_create()
{
   _retrieve_prev_form();
}


/**
 * Performs a search on the selected files.  This command is used while in 
 * <b>fileman</b> mode to perform a search across multiple files and 
 * directories.
 * 
 * @return  Returns 0 if successful.   Otherwise, a non-zero number is 
 * returned.
 * @categories File_Functions, Search_Functions
 */
_command int fileman_find(_str search_string='', _str options='', _str mfflags='') name_info(','VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _macro_delete_line();
   typeless result='';
   if (search_string=='') {
      result=show('-modal _fmfind_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',_macro('s'));
      search_string=_param1;
      options=_param2;
      mfflags=_param3;
   }
   orig_wid := p_window_id;
   int orig_buf_id=p_buf_id;
   typeless atbuflist=fmmulti_select_result('','1');
   if (atbuflist=='') {
      _message_box('No files selected');
      return(1);
   }
   _macro_call('fileman_find',search_string,options,mfflags);
   typeless status=_mffind(search_string,options,atbuflist,'',(typeless)mfflags);
   typeless last_file=rc;
   if (last_file!='') {
      new_wid := p_window_id;
      int new_buf_id=p_buf_id;
      p_window_id=orig_wid;
      p_buf_id=orig_buf_id;
      // Position cursor in file manager list where user aborted
      save_pos(auto p);
      top();
      status=search(last_file,'@'_fpos_case);
      for (;;) {
         if (status) break;
         if (p_col==DIR_FILE_COL) break;  // Found it
         status=repeat_search();
      }
      if (status) restore_pos(p);
      p_window_id=new_wid;
      p_buf_id=new_buf_id;
   }
   return(status);
}
static _str fmmulti_select_result(_str cwd="", typeless isfileman_list="")
{
   line := "";
   text := "";
   typeless result='';
   typeless status=fmfind_selected(true);
   for (;;) {
      if (status) break;
      if (isfileman_list != "") {
         get_line(line);
         text=pcfilename(line);
      } else {
         text=_maybe_quote_filename(_lbget_text());
      }
      if (cwd!='') {
         text=_absolute2(text,cwd);
      }
      result :+= " "text;
      status=fmfind_selected(false);
   }
   return(result);
}

static int fmfind_selected(bool ff)
{
   if ( ff ) {
      top();up();
   }
   return search('^\>','@r>');
}

static int find_search_delim(_str &ch, _str search_string, _str replace_string)
{
   int i,status=1;
   for (i=0; i<=27 ; ++i) {
      ch=_chr(i);
      if ( pos(ch,search_string) ) {
         continue;
      }
      if ( pos(ch,replace_string) ) {
         continue;
      }
      status=0;
      break;
   }
   return(status);
}
#if 1 /* !__UNIX__ */
defeventtab _fmattr_form;
_fmok.on_create(_str caption='', _str formName='', _str helpInfo='')
{
   p_active_form.p_help=helpInfo;
   if (caption!='') {
      p_active_form.p_caption=caption;
      p_active_form.p_name=formName;
   } else {
      _fmddont_care.p_enabled=false;
      _fmdon.p_enabled=false;
      _fmdoff.p_enabled=false;
   }
   _retrieve_prev_form();
}
_fmok.lbutton_up()
{
   _param1='';   // unlist-attr results
   _param2='+';  // +attr results
   _param3='-';  // -attr results

   if (_fmrdont_care.p_value) {
      _param1 :+= '?';
   } else if (_fmron.p_value) {
      _param1 :+= 'R';
      _param2 :+= 'R';
   } else {
      _param1 :+= '-';
      _param3 :+= 'R';
   }
   if (_fmhdont_care.p_value) {
      _param1 :+= '?';
   } else if (_fmhon.p_value) {
      _param1 :+= 'H';
      _param2 :+= 'H';
   } else {
      _param1 :+= '-';
      _param3 :+= 'H';
   }
   if (_fmsdont_care.p_value) {
      _param1 :+= '?';
   } else if (_fmson.p_value) {
      _param1 :+= 'S';
      _param2 :+= 'S';
   } else {
      _param1 :+= '-';
      _param3 :+= 'S';
   }
   if (_fmddont_care.p_value) {
      _param1 :+= '?';
   } else if (_fmdon.p_value) {
      _param1 :+= 'D';
      _param2 :+= 'D';
   } else {
      _param1 :+= '-';
      _param3 :+= 'D';
   }
   if (_fmadont_care.p_value) {
      _param1 :+= '?';
   } else if (_fmaon.p_value) {
      _param1 :+= 'A';
      _param2 :+= 'A';
   } else {
      _param1 :+= '-';
      _param3 :+= 'A';
   }
   _save_form_response();
   p_active_form._delete_window(1);
}
#endif
#if 1 /* __UNIX__ */
defeventtab _unixfmattr_form;
_fmok.on_create(_str caption='', _str formName='', _str helpInfo='')
{
   p_active_form.p_help=helpInfo;
   if (caption!='') {
      p_active_form.p_caption=caption;
      p_active_form.p_name=formName;
   } else {
      //_fmdon.p_enabled=false;
      //_fmdoff.p_enabled=false;
      ctldir.p_enabled=false;
   }
   _retrieve_prev_form();
}
_fmok.lbutton_up()
{
   _param1='';   // unlist-attr results
   _param2='';  // +attr results
   _param3='';  // -attr results


   if (ctldir.p_value==2) {
      _param1 :+= '?';
   } else if (ctldir.p_value) {
      _param1 :+= 'd';
   } else {
      _param1 :+= '-';
   }
   if (ctluserread.p_value==2) {
      _param1 :+= '?';
   } else if (ctluserread.p_value) {
      _param1 :+= 'r';
      _param2 :+= ' u+r';
   } else {
      _param1 :+= '-';
      _param3 :+= ' u-r';
   }
   if (ctluserwrite.p_value==2) {
      _param1 :+= '?';
   } else if (ctluserwrite.p_value) {
      _param1 :+= 'w';
      _param2 :+= ' u+w';
   } else {
      _param1 :+= '-';
      _param3 :+= ' u-w';
   }
   if (ctluserexec.p_value==2) {
      _param1 :+= '?';
   } else if (ctluserexec.p_value) {
      _param1 :+= 'x';
      _param2 :+= ' u+x';
   } else {
      _param1 :+= '-';
      _param3 :+= ' u-x';
   }


   if (ctlgroupread.p_value==2) {
      _param1 :+= '?';
   } else if (ctlgroupread.p_value) {
      _param1 :+= 'r';
      _param2 :+= ' g+r';
   } else {
      _param1 :+= '-';
      _param3 :+= ' g-r';
   }
   if (ctlgroupwrite.p_value==2) {
      _param1 :+= '?';
   } else if (ctlgroupwrite.p_value) {
      _param1 :+= 'w';
      _param2 :+= ' g+w';
   } else {
      _param1 :+= '-';
      _param3 :+= ' g-w';
   }
   if (ctlgroupexec.p_value==2) {
      _param1 :+= '?';
   } else if (ctlgroupexec.p_value) {
      _param1 :+= 'x';
      _param2 :+= ' g+x';
   } else {
      _param1 :+= '-';
      _param3 :+= ' g-x';
   }

   if (ctlotherread.p_value==2) {
      _param1 :+= '?';
   } else if (ctlotherread.p_value) {
      _param1 :+= 'r';
      _param2 :+= ' o+r';
   } else {
      _param1 :+= '-';
      _param3 :+= ' o-r';
   }
   if (ctlotherwrite.p_value==2) {
      _param1 :+= '?';
   } else if (ctlotherwrite.p_value) {
      _param1 :+= 'w';
      _param2 :+= ' o+w';
   } else {
      _param1 :+= '-';
      _param3 :+= ' o-w';
   }
   if (ctlotherexec.p_value==2) {
      _param1 :+= '?';
   } else if (ctlotherexec.p_value) {
      _param1 :+= 'x';
      _param2 :+= ' o+x';
   } else {
      _param1 :+= '-';
      _param3 :+= ' o-x';
   }


   _save_form_response();
   p_active_form._delete_window(1);
}
#endif

// takes the wildcards string and generates a SlickEdit regular expression
static _str _make_wildcard_re(_str wildcards)
{
   re := "";
   _str filter;
   _str ch;
   wildcards = strip(wildcards);
   while (wildcards != '') {
      parse wildcards with filter '[ ]','r' wildcards;
      if (filter != '') {
         if (_last_char(re) == ')') {
            strappend(re, '|(^');
         } else {
            strappend(re, '(^');
         }
         if (filter == '*.*') {
            filter = '*';
         }
         while (filter != '') {
            ch = substr(filter, 1, 1);
            filter = substr(filter, 2);
            if (ch == '*') {
               strappend(re, '?*');
            } else {
               strappend(re, ch);
            }
         }
         strappend(re, '$)');
      }
   }
   return re;
}

/** 
 * Creates a buffer and inserts a list of the files that are currently open
 * specified with columns for size, date, time, attributes
 * (UNIX: permissions), and name.  The mode is changed to
 * fileman mode.  When in fileman mode, there are some additions
 * and changes to the key bindings.  See help on
 * <b>fileman_mode</b>.
 * 
 * @param wildcards  may contain operating system wild cards
 *                   such as '*' and '?'.
 * 
 * @return  Returns 0 if successful.
 * 
 * @see fileman
 * @categories File_Functions
 */
_command fileman_list_buffers(_str wildcard = ALLFILES_RE) name_info(','VSARG2_REQUIRES_MDI)
{
   typeless status = edit('+futf8 +t');
   if (status) {
      return (status);
   }
   _str wildcard_re = _make_wildcard_re(wildcard);
   int undo_steps = p_undo_steps;
   p_undo_steps = 0;
   fileman_mode();
   _str name = buf_match('', 1, 'b');
   while (!rc) {
      if (name != '') {
        line := file_match('-p +VRHS '_maybe_quote_filename(name), 1);
         if (line != '' && pos(wildcard_re, _strip_filename(name,'P'), 1, 'r')) {
            insert_line(substr(line, 1, DIR_FILE_COL-1):+name);
         }
      }
      name = buf_match('',0,'b');
   }
   p_modify = false; p_undo_steps = undo_steps;
   line := "";
   get_line(line);
   if (line == '') {
      quit();
      status = FILE_NOT_FOUND_RC;
   } else {
      if (!status) {
         message('Sorting...');
         fsort('f');
         clear_message();
      }
      if (def_exit_file_list) {
         p_buf_flags = p_buf_flags|VSBUFFLAG_THROW_AWAY_CHANGES;
      }
      top(); _delete_line();
      docname('List of 'wildcard);
      p_modify = false;
   }

   return (status);
}

