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
#import "alias.e"
#import "complete.e"
#import "fileman.e"
#import "files.e"
#import "forall.e"
#import "fsort.e"
#import "listbox.e"
#import "main.e"
#import "os2cmds.e"
#import "recmacro.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vc.e"
//for Unix only
#import "doscmds.e"
#import "codehelp.e"
#endregion

_str def_sort_dir=1;  /* Option to sort directory by name & path  */

/**
 * Temporarily switches to fundamental mode for the next key press.
 * Useful for getting to a fundamental mode key binding when the
 * current mode has changed the binding of that key.
 *
 * @categories Keyboard_Functions
 *
 */
_command void root_keydef() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _macro('m',_macro('s'));
   _macro_delete_line();
   mode_name := p_mode_name;
   langId := p_LangId;
   buf_id:=p_buf_id;
   fundamental_mode();
   _macro_call('fundamental_mode');
   message(nls('Fundamental mode active for next key sequence'));
   typeless k=get_event();
   if ( ! iscancel(k) ) {
      clear_message();
      name:=name_on_key(k);
      if (name=='close-buffer' || name=='close-window' || name=='quit' || name=='close-all' || name=='emacs-quit') {
         _SetEditorLanguage(langId);
      }
      call_key(k);
   }
   if( command_state() ) {
      // Calling mode selection commands while on the command line is bad
      // because things like p_LangId, etc. are checked and assume the
      // active window is an edit window.
      command_toggle();
   }
   _macro_call('_SetEditorLanguage',langId);
   status:=_open_temp_view('',auto temp_wid,auto orig_wid,'+bi 'buf_id);
   if (!status) {
      _SetEditorLanguage(langId);
      _delete_temp_view(temp_wid);
      p_window_id=orig_wid;
   }
   if ( iscancel(k) ) {
      cancel();
      return;
   }

}
_dirs_to_top()
{
   modify := p_modify;
   after_line := 0;
   old_line := 0;
   top();up();
   dirline := "";
   typeless done=0;
   while (!search('<DIR>','>@')) {
      get_line(dirline);
      done=_delete_line();
      old_line=p_line;
      p_line=after_line;++after_line;
      insert_line(dirline);
      p_line=old_line;
      _end_line();
      if (done) break;
   }
   p_modify=modify;
   top();
}

/**
 * Creates a buffer and inserts a list of the files specified with columns
 * for size, date, time, attributes (UNIX: permissions), and name.  The mode
 * is changed to fileman mode.  When in fileman mode, there are some additions
 * and changes to the key bindings.  See help on <b>fileman_mode</b>.
 *
 * @param   command_line   has the following syntax:<br>
 *      {[ [- | +] <i>option_letters</i>] [ [@]<i>filespec </i>]
 *      {-wc wcfiles} {-exclude exfiles}}
 *
 * @param option_letters   may be 'H','S','D','P','T' with the following meaning:
 * <DL compact style="margin-left:20pt;">
 *   <DT>H<DD>Include hidden files.  Default is off.  Ignored by UNIX version.
 *    This option is always turned on under Windows if the "Show all files" explorer option is set.
 *   <DT>S<DD>Include system files.  Default is off.  Ignored by UNIX version.
 *    This option is always turned on under Windows if the "Show all files" explorer option is set.
 *   <DT>D <DD>Include directory files.  Defaults to on.
 *   <DT>P<DD>Append path.  Default is on.
 *   <DT>T<DD>Tree file list.  Default is off.
 * </DL>
 * @param filespec filename with ant-like wildcards or path. 
 * If <i>filespec</i> is not specified, the current directory is used.  '@' sign
 * prefix to <i>filespec</i> indicates that <i>filespec</i> is a file or buffer
 * which contains a list of file names to be used as arguments 
 * to this command. When '@' is used, the -wc and -exclude 
 * options are not supported. 
 *
 *
 * @param filespec may contain operating system wild cards such as '*'
 * and '?'.  If <i>filespec</i> is not specified, current directory is used.
 *
 * @param wcfiles may contain ant-like wild cards. ** represents
 *                0 or more path parts. * represents
 *                exactly one path part. Use of ** only useful
 *                in rare occassions when recursively listing.
 * <pre> 
 *    Example
 *       -wc *.cpp *.h backup\**\*.cpp
 * </pre> 
 *  
 * @example
 * <pre>
 * <dl> 
 * <dt>dir</dt><dd>List file and directory entries of the current directory. </dd> 
 * <dt>dir *.cpp *.h</dt><dd>List file .cpp and .h files in the current directory </dd> 
 * <dt>dir ./ -wc *.cpp *.h -exclude junk*</dt><dd>List file .cpp and .h files in the current directory and exclude junk* files</dd> 
 * <dt>dir @backup.lst</dt><dd>List file or directory entries specified by each line of the file "backup.lst".</dd> 
 * <dt>dir c:\</dt><dd>List file and directory entries in the root directory of drive C. </dd> 
 * <dt>dir +HS c:\</dt><dd>List file and directory entries in the root directory of drive C including hidden and system files.</dd> 
 * </dl>
 * </pre>
 * @return  Returns 0 if successful.  Common return values are TOO_MANY_FILES_RC, FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC, and TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see fileman
 * @categories File_Functions
 */
_command dir,ls(_str path='') name_info(FILENOAUTODIR_ARG'*,'VSARG2_REQUIRES_MDI)
{
  if ( path=='<' ) {
     path=prompt();
  }
  typeless status=edit('-fshowextraline +futf8 +t');
  if ( status ) {
     return(status);
  }
  /* list directory entryies (D). */
  /* show path (P) */
  int undo_steps=p_undo_steps;
  p_undo_steps=0;
  fileman_mode();
  status=append_list(path,'','+DP','Directory of ');
  p_modify=false;p_undo_steps=undo_steps;
  line := "";
  get_line(line);
  if ( line=='' ) {
     quit();
  } else {
     if(!status && def_sort_dir){
        message('Sorting...');
        fsort('f');
        _dirs_to_top();
        clear_message();
        p_modify=false;
     }
  }
  return(status);

}

/** 
 * Locates a list of files and updates their dates on disk to the current time. 
 * This is useful, for example, to force a file to be recompiled. 
 *
 * @param path    file specification which may contain operating system 
 *                wild cards such as '*' and '?'.
 *                If <i>filespec</i> is not specified, current directory is used.
 *  
 * @return  Returns 0 if successful. 
 *          Common return values are TOO_MANY_FILES_RC, FILE_NOT_FOUND_RC,
 *          PATH_NOT_FOUND_RC, and TOO_MANY_SELECTIONS_RC.
 *          On error, a message is displayed.
 *
 * @see fileman 
 * @see dir 
 * @see list
 * @categories File_Functions
 */
_command touch(_str path='') name_info(FILENOAUTODIR_ARG'*,'VSARG2_REQUIRES_MDI)
{
  if ( path=='<' ) {
     path=prompt();
  }
  orig_wid := _create_temp_view(auto temp_wid);
  if (orig_wid < 0) {
     _message_box(get_message(orig_wid, path));
     return orig_wid;
  }

  mou_hour_glass(true);
  status := insert_file_list("-v -d +p " :+ path);
  if (status < 0) {
     _delete_temp_view(temp_wid);
     _message_box(get_message(status, path));
     return status;
  }

  count := 0;
  _SccDisplayOutput("Touching files in Directory of '" :+ path :+ "'", clear_buffer:true, doActivateOutput:true);
  top();
  do {
     get_line(path);
     path = strip(path);
     if (path == "") break;
     if (isdirectory(path)) {
        _SccDisplayOutput("Skipped dir: " :+ path, doActivateOutput:false);
     } else {
        status = _file_touch(path);
        if (status < 0) {
           _SccDisplayOutput("Error: " :+ get_message(status, path), doActivateOutput:false);
        } else {
           _SccDisplayOutput("Touched: " :+ path, doActivateOutput:false);
           count++;
        }
     }

  } while (!down());
  _SccDisplayOutput("Touched " :+ count :+ " files.", doActivateOutput:false);
  mou_hour_glass(false);

  _delete_temp_view(temp_wid);
  activate_window(orig_wid);
  return 0;
}

/**
 * Creates a buffer and inserts a tree directory list of the files specified
 * with columns for size, date, time, attributes, and name.  The mode is changed
 * to fileman mode.  When in fileman mode F1 becomes help on file management
 * keys and the right mouse button brings up a menu of file management commands.
 *
 * @param cmdline has the following syntax:<br>
 * <pre>
 *      {[ [- | +] <i>option_letters</i>] [ [@]<i>filespec </i>] {-wc wcfiles} {-exclude exfiles}}
 * </pre>
 *
 * @param options_letters may be 'H','S','D','P','T'
 * with the following meaning: 
 *
 * <dl>
 * <dt>H</dt><dd>Include hidden files.  Defaults to off.  Ignored by UNIX version.
 * This option is always turned on under Windows if the "Show all
 * files" explorer option is set.</dd>
 * <dt>S</dt><dd>Include system files.  Defaults to off.  Ignored by UNIX version.
 * This option is always turned on under Windows if the "Show all
 * files" explorer option is set.</dd>
 * <dt>D</dt><dd>Include directory files.  Defaults to off.</dd>
 * <dt>P</dt><dd>Append path.  Defaults to on.</dd>
 * <dt>T</dt><dd>Tree file list.  Defaults to on.</dd>
 * </dl>
 *
 * @param filespec filename with ant-like wildcards or path. 
 * If <i>filespec</i> is not specified, the current directory is used.  '@' sign
 * prefix to <i>filespec</i> indicates that <i>filespec</i> is a file or buffer
 * which contains a list of file names to be used as arguments 
 * to this command. When '@' is used, the -wc and -exclude 
 * options are not supported. 
 *
 * @param filespec may contain operating system wild cards such as '*'
 * and '?'.  If <i>filespec</i> is not specified, current directory is used.
 *
 * @param wcfiles may contain ant-like wild cards. ** represents
 *                0 or more path parts. * represents
 *                exactly one path part. Use of ** only useful
 *                in rare occassions when recursively listing.
 * <pre> 
 *    Example
 *       -wc *.cpp *.h backup\**\*.cpp
 * </pre> 
 *  
 * @example
 * <pre>
 * <dl>
 * <dt>list c:\</dt><dd>List all files on drive C.</dd>
 * <dt> *.cpp *.h</dt><dd> List file .cpp and .h files at or 
 * beneath the current directory</dd> 
 * <dr>list ./ -wc *.cpp *.h -exclude junk*</dt><dd>List file
 * .cpp and .h files at or beneath the current directory and 
 * exclude junk* files </dd> 
 * <dt>list @backup.lst</dt><dd>List files specified by each line of the file
 * "backup.lst".</dd>
 * <dt>list</dt><dd>List all files starting from the current directory.</dd>
 * <dt>list +HS c:\</dt><dd>List all files on drive C including hidden and system
 * files.</dd>
 * </dl>
 * </pre>
 *
 * @return Returns 0 if successful.  Common return codes are
 * TOO_MANY_SELECTIONS_RC, FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC, and
 * TOO_MANY_SELECTIONS_RC.  On error, message is displayed.
 *
 * @see dir
 *
 * @appliesTo Edit_Window
 *
 * @categories File_Functions
 *
 */
_command list(_str path='') name_info(FILENOAUTODIR_ARG'*,'VSARG2_REQUIRES_MDI)
{
  if ( path=='<' ) {
     path=prompt();
  }
  typeless status=edit('-fshowextraline +futf8 +t');
  if ( status ) {
     return(status);
  }
  /* Search directory tree(T). */
  /* show path (P) */
  int undo_steps=p_undo_steps;
  p_undo_steps=0;
  fileman_mode();
  get_line(auto line);
  status=append_list(path,'','+TP','List of ');
  p_modify=false;p_undo_steps=undo_steps;
  if (status==CMRC_OPERATION_CANCELLED) {
     if (line=='') {
        p_modify=false;
        quit();
     }
     _message_box(get_message(CMRC_OPERATION_CANCELLED));
  } else {
     get_line(line);
     if ( line=='') {
        quit();
     } else {
        if(!status && def_sort_dir){
           message('Sorting...');
           fsort('f');
           clear_message();
           p_modify=false;
        }
     }
  }
  return(status);

}
/**
 * Appends a directory list of the files specified to the current buffer.  If filespec
 * is not specified, files in the current directory are listed.  This command is
 * useful when in fileman mode.  An '@' sign prefix to filespec indicates that
 * filespec is a file or buffer which contains a list of file names to be used
 * as arguments to this command.  Use the <b>dir</b> or <b>list</b> command to change the mode
 * to fileman mode.
 *
 * <i>cmdline</i> is a string in the format: [@]filespec  [ [@]filespec ... ]
 *
 * @return
 * @see dir
 * @see list
 * @see append_list
 * @categories File_Functions
 */
_command append_dir(_str path='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
  if ( path=='<' ) {
     path=prompt();
  }
  return(append_list(path,'','+PD'));

}
/**
 * Appends a tree directory list of the files specified to the current buffer.
 * If filespec is not specified, the current directory list is used.  This
 * command is useful when in fileman mode.  An '@' sign prefix to filespec
 * indicates that filespec is a file or buffer which contains a list of
 * file names to be used as arguments to this command.  Use the dir or
 * list command to change the mode to fileman mode.
 *
 * @param cmdline a string in the format: [@]filespec [[@]filespec ... ]
 *
 * @return Returns 0 if successful.  Common return codes are
 * TOO_MANY_SELECTIONS_RC, TOO_MANY_FILES_RC, TOO_MANY_OPEN_FILES_RC (OS limit).
 * On error, message is displayed.
 *
 * @see dir
 * @see list
 * @see append_dir
 * @see append_list
 * @see fileman
 * @categories File_Functions
 */
_command append_list(_str path='', _str arg2='', _str arg3='', _str arg4='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   if ( path=='<' ) {
      path=prompt();
   }
   _str cmdline=path;
   options := "";
   if (_fpos_case=='' && def_filematch_case_insensitive) {
      options:+=' +9 ';
   }
   filespec := "";
   ch := "";
   word_nq := "";
   param := "";
   typeless status=0;
   mou_hour_glass(true);
   for (;;) {
      filespec=parse_file(cmdline);
      ch=substr(filespec,1,1);
      if ( (ch:=='-' || ch:=='+') ) {
         if (substr(filespec,2)=='wc' || substr(filespec,2)=='exclude') {
            // dir -wc *.cpp 
            cmdline=filespec' 'cmdline;
            // insert_file_list doesn't support no filespec before -wc or -exclude
            // but maybe it will later. For now, just use current directory here.
            filespec=".":+FILESEP;
         } else {
            options :+= " "filespec;
            continue;
         }
      }
      word_nq=strip(filespec,'B','"');
      if ( substr(word_nq,1,1)=='@' ) {
         arg4='';
         param=_maybe_quote_filename(substr(word_nq,2));

         status=read_list(param,'',arg3);
         if ( status ) {
            break;
         }
/*
         if option<>'' then
            activate_window list_view_id
            quit_view
            activate_window view_id
         endif
*/
      } else {
         suffixOptions := "";
         // See if -wc or -exclude follows
         _str temp=cmdline;
         _str option=parse_file(temp);
         wildcard_specs_follow := false;
         if (option=='-wc') {
            wildcard_specs_follow=true;
            suffixOptions:+=" "option;
            option=parse_file(temp);
            suffixOptions:+=" "option;
            for (;;) {
               cmdline=temp;
               option=parse_file(temp);
               if (option=='') break;
               ch=substr(option,1,1);
               if ( ch:=='-' || ch:=='+' ) {
                  break;
               }
               suffixOptions:+=" "option;
            }
         }
         temp=cmdline;
         option=parse_file(temp);
         if (option=='-exclude') {
            suffixOptions:+=" "option;
            option=parse_file(temp);
            suffixOptions:+=" "option;
            for (;;) {
               cmdline=temp;
               option=parse_file(temp);
               if (option=='') break;
               ch=substr(option,1,1);
               if ( ch:=='-' || ch:=='+' ) {
                  break;
               }
               suffixOptions:+=" "option;
            }
         }
         if ( !wildcard_specs_follow && isdirectory(filespec) ) {
            // isdirectory converts filespec to absolute so we have to
            // add quotes
            param=_maybe_quote_filename(strip(isdirectory(filespec,1):+ALLFILES_RE));
         } else {
            param=filespec;
         }
         /* Search directory tree(T). */
         /* show path (P) */
         bottom();
         if ( arg3!='' ) {
            status=insert_file_list(arg3 " "options " "param" "suffixOptions);
         } else {
            status=insert_file_list('+TP 'options " "param" "suffixOptions);
         }
         if ( status ) {
            message(get_message(status));
            break;
         }
      }
      if ( arg4!='' ) {
        if ( def_exit_file_list ) {
           p_buf_flags |= VSBUFFLAG_THROW_AWAY_CHANGES;
        }
        typeless junk;
        docname(arg4:+absolute(strip(strip_options(param,junk),'B','"')));
        top();_delete_line();
        p_modify=false;
        arg4='';
      } else {
        line := "";
        old_line := p_line;
        top();get_line(line);
        if ( line=='' ) {
           _delete_line();
           old_line--;
        }
        p_line=old_line;
      }
      if ( cmdline=='' ) {
         status=0;
         break;
      }
   }
   mou_hour_glass(false);
   return(status);

}


/**
 * The fileman mode keys are activated after executing the
 * <b>fileman_mode</b>, <b>dir</b>, <b>list</b>, or <b>fileman</b> commands.
 * The keys are redefined as indicated below
 *
 * <DL compact style="margin-left:20pt;">
 *    <DT>Alt+Shift+A   <DD>Select all files.
 *    <DT>Alt+Shift+B   <DD>Backup selected files.
 *    <DT>Alt+Shift+C   <DD>Copy selected files.
 *    <DT>Alt+Shift+D   <DD>Delete selected files.
 *    <DT>Alt+Shift+E   <DD>Edit selected files.
 *    <DT>Alt+Shift+G   <DD>Search and Replace on selected files.
 *    <DT>Alt+Shift+M   <DD>Move select files.
 *    <DT>Alt+Shift+N   <DD>Keyin current line filename.
 *    <DT>Alt+Shift+O   <DD>File Sort dialog box.
 *    <DT>Alt+Shift+R   <DD>Repeat Command on Selected dialog box.
 *    <DT>Alt+Shift+T   <DD>Fileman Set Attributes dialog box.
 *    <DT>ENTER         <DD>Edit current file or insert directory files.
 *    <DT>Space bar     <DD>Select current file toggle.
 *    <DT>'8'           <DD>Select and cursor up.
 *    <DT> '2'          <DD>Select and cursor down.
 *    <DT>'9'           <DD>Deselect and cursor up.
 *    <DT>'3'           <DD>Deselect and cursor down.
 *    <DT>RButtonDown
 *                      <DD>Displays file manager pop-up menu.
 * </DL>
 * Selected directories are skipped by Backup, Move, Delete, Edit, and Set
 * file attribute commands.
 * @categories File_Functions
 */
_command void fileman_mode() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   _SetEditorLanguage('fileman');
}
/**
 * If the cursor is on the command line, the binding to the last key pressed
 * is executed.  Otherwise the command <b>key_not_defined</b> is called.  Used
 * by fileman mode.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Miscellaneous_Functions
 *
 */
_command void maybe_normal_character() name_info(','VSARG2_LASTKEY|VSARG2_CMDLINE|VSARG2_REQUIRES_EDITORCTL)
{
   if ( command_state() ) {
      int index=eventtab_index(_default_keys,
                              _default_keys,event2index(last_event()));
      if ( index ) {
         try_calling(index);
      } else {
         normal_character();
      }
   } else {
      key_not_defined();
   }

}

/**
 * Opens the file at the cursor or inserts directory file list.  Used by
 * <b>fileman</b> mode.
 * @categories File_Functions
 */
_command void fileman_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_MARK)
{
   _deselect();
   if ( command_state() || p_window_state:=='I' ) {
      try_calling(eventtab_index(_default_keys,
                          _default_keys,event2index(ENTER)));
   } else {
      line := "";
      get_line(line);
      ext:=get_extension(strip(pcfilename(line),'B','"'),true);
      ext_list:=_default_option(VSOPTIONZ_ZIP_EXT_LIST);

      if ( pos('<DIR>',line) || 
           (
             !_file_eq(ext,'.xlsx') &&  // Use file association
            !_file_eq(ext,'.docx') &&  // Use file association
            pos(' 'ext' ',' 'ext_list' ',1,_fpos_case)
           ) ||
           _file_eq(ext,'.tar') || 
           _file_eq(ext,'.tgz') || 
           _file_eq(ext,'.cpio') || 
           _file_eq(ext,'.cpgz') || 
           _file_eq(ext,'.rpm') || 
           _file_eq(ext,'.gz') || 
           _file_eq(ext,'.bz2') || 
           _file_eq(ext,'.tbz2') || 
           _file_eq(ext,'.xz') || 
           _file_eq(ext,'.txz') || 
           _file_eq(ext,'.Z')) {
         _lbclear();
         filename := strip(pcfilename(line),'B','"'):+FILESEP:+ALLFILES_RE;
         filename=_maybe_quote_filename(filename);
         int status=insert_file_list('+PRD 'filename);
         if (status) {
            message(get_message(status));
         }
         if(!status && def_sort_dir){
            message('Sorting...');
            fsort('f');
            _dirs_to_top();
            clear_message();
         }
         docname('Directory of 'absolute(strip(filename,'B','"')));
         p_modify=false;
         top();
      } else {
         _fm_open(pcfilename(line));
         //edit(pcfilename(line),EDIT_DEFAULT_FLAGS);
      }
   }

}
static bool gAllowProcessCD;
static _str gDirectoryStack[]= null;
void _clear_dir_stack()
{
   gDirectoryStack._makeempty();
}
void _cd_process()
{
   if (!gAllowProcessCD) {
      return;
   }
   if (isinteger(def_cd) && (def_cd & CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW)) {
      _process_cd(getcwd());
   }
}
static int _cd2(_str cmdline="",_str quiet="", _str arg3='')
{
   _str path=cmdline;
   options := "";
   path=strip_options(path,options,true);
   do_process_cd := (def_cd & CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW) || pos('(^| )\+p',options,1,'ri');
   if (pos('(^| )-p',options,1,'ri')) {
      do_process_cd=false;
   }
   do_terminal_cd := do_process_cd && ((def_cd & CDFLAG_CHANGE_DIR_IN_TERMINAL_WINDOWS) || pos('(^| )\+p',options,1,'ri'));
   if (pos('(^| )-t',options,1,'ri')) {
      do_terminal_cd=false;
   }
   do_alias := (def_cd & CDFLAG_EXPAND_ALIASES_IN_CD_FORM) || pos('(^| )\+a',options,1,'ri');
   if (pos('(^| )-a',options,1,'ri')) {
      do_alias=false;
   }
   if (do_alias && path!='') {
      typeless multi_line_info='';
      _str new_path = get_alias(path,multi_line_info,'','',quiet!='');
      typeless multi_line_flag='';
      typeless file_already_loaded='';
      typeless old_view_id='';
      typeless alias_view_id='';
      parse multi_line_info with multi_line_flag file_already_loaded old_view_id alias_view_id .;
      if ( multi_line_flag ) {
         if (quiet=="") {
            message('Multi-line alias not allowed.');
         }
         return(1);
      }
      if (new_path!='') {
         path=new_path;
      }
   }
   status := 0;
   if ( cmdline!='' ) {
      path=strip(path,'B','"');
      if (_isLinux() && substr(path,1,6)=='smb://') {
         path=absolute(path,'',true);
      }
      if ( ! isdirectory(path) ) {
         if (quiet=='') {
            message(nls('Path "%s" not found',strip(path,'B','"')));
         }
         return(PATH_NOT_FOUND_RC);
      }
      if ( arg3!='' || do_process_cd) {
         _process_cd(path,null,do_terminal_cd);
      }
      path=strip(path,'B','"');
      status=chdir(path,1);    /* change drive and directory. */
      if (status) {
         if (quiet=="") {
            if (status==PATH_NOT_FOUND_RC) {
               message(nls('Path "%s" not found',path));
            } else {
               message(get_message(status));
            }
         }
         return(status);
      }
      gAllowProcessCD=false;
      if (!status) {
         call_list('_cd_',getcwd());
      }
      gAllowProcessCD=true;
   }
   if (quiet=='') {
      _str msg=nls('Current directory is %s',getcwd());
      message(msg);
   }
   gAllowProcessCD=true;
   return(status);

}


/**
 *
 * Changes the current working directory to the drive and path if given.
 * A current directory message is displayed.  By default, this command
 * supports specifying directory aliases for <i>driveNpath</i> and will
 * change directory in the build window.  Use the <b>Change
 * Directory dialog box</b> ("File", "Change Directory...") to change
 * these defaults and press the save settings button.
 *
 * @param cmdline is a  string in the format: [+p | -p] [+a | -a] <i>driveNpath</i>
 * <pre>
 *  The options have the following meaning:
 *  +p      Change directory in the build window.
 *  -p      Don't change directory in the build window.
 *  +a      Support directory aliases for <i>driveNpath</i>.
 *  -a      Do not support directory aliases for <i>driveNpath</i>.
 * </pre>
 * @return  Returns 0 if successful.  Common error code is PATH_NOT_FOUND_RC.
 *
 * @see cdd
 * @see gui_cd
 * @see alias_cd
 *
 *
 * @categories File_Functions
 */
_command cd,pwd(_str cmdline="",_str quiet="") name_info(FILE_ARG " "MORE_ARG',')
{
   _str ssmessage=get_message();
   int sticky=rc;
   int status=_cd2(cmdline,quiet);
   // Don't change this to ==.  Here we are restoring the original
   // message and NOT displaying a new message
   if (quiet!='') {
      if (ssmessage!='') {
         if (sticky) {
            sticky_message(ssmessage);
         } else {
            message(ssmessage);
         }
      }
   }
   gpending_switchbuf=false;
   return(status);
}
_command int remove_dir(_str path="",_str quiet="") name_info(DIRNEW_ARG " "MORE_ARG',')
{
   status:=rmdir(path);
   if (quiet!='') {
      message(get_message(status));
   }
   return(status);
}
/**
 *  Changes the current working directory to the path
 *  containing the active document.
 *  @see cd
 *  @categories File_Functions
 */
_command int cd_to_buffer,cdb() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL|VSARG2_MARK)
{
    int status=PATH_NOT_FOUND_RC;
    if (p_buf_name != '') {
        directory := _strip_filename(p_buf_name, 'NE');
        if(isdirectory(directory)){
            status=cd(directory);
        }
    }
    return(status);
}
/**
 * Adds the current working directory to the top of the 
 * directory stack and makes the supplied directory (cmdline) 
 * the new working directory.  With no arguments (cmdline==''), 
 * swaps the current working directory with the top of the 
 * directory stack. 
 * 
 * @param cmdline    directory to switch to
 * @param quiet      suppress messages
 * 
 * @return 0 on success, <0 on error 
 *  
 * @see cd 
 * @see popd 
 *  
 * @categories File_Functions
 */
_command int pd,pushd(_str cmdline="",_str quiet="") name_info(FILE_ARG " "MORE_ARG',')
{
   cur_dir := getcwd();
   if (cmdline=='' && gDirectoryStack._length() >= 1) {
      cmdline = _maybe_quote_filename(gDirectoryStack[gDirectoryStack._length()-1]);
      gDirectoryStack._deleteel(gDirectoryStack._length()-1);
   }
   status := cd(cmdline,quiet);
   if (!status) {
      gDirectoryStack[gDirectoryStack._length()]=cur_dir;
   }
   return(status);
}
/**
 * Removes the top directory from the directory stack and makes 
 * it the new working directory.   
 * 
 * @param quiet      suppress messages
 * 
 * @return 0 on success, <0 on error 
 *  
 * @see cd 
 * @see pushd 
 *  
 * @categories File_Functions
 */
_command int popd(_str quiet="") name_info(MORE_ARG',')
{
   n := gDirectoryStack._length();
   if (n<=0 || gDirectoryStack[n-1]=='') {
      if (quiet=='') {
         message(nls("No directories to pop"));
      }
      return(1);
   }
   _str cmdline=gDirectoryStack[n-1];
   gDirectoryStack._deleteel(n-1);
   return cd(cmdline,quiet);
}
/**
 * Changes current drive and directory in the build window (.process).
 *
 * @categories Miscellaneous_Functions
 *
 */
void _process_cd(_str param,_str idname=null,bool allow_cd_in_terminals=true)
{
   if (idname==null && allow_cd_in_terminals && (def_cd & CDFLAG_CHANGE_DIR_IN_TERMINAL_WINDOWS)) {
      _str idnames[];
      _terminal_list_idnames(idnames,true);
      for (i:=0;i<idnames._length();++i) {
         _process_cd(param,idnames[i]);
      }
   }
   if (idname==null) idname='';
   if (!_process_info('',idname)) {
      return;
   }
   if ( _last_char(param)==FILESEP || _last_char(param)==FILESEP2 ) {
      new_param := substr(param,1,length(param)-1);
      if ( ! isdrive(new_param) && ! (new_param=='') ) {
         param=new_param;
      }
   }
   orig_view_id := 0;
   get_window_id(orig_view_id);
   p_window_id=_mdi.p_child;

   param=strip(param,"B","\"");
   if ( isdrive(substr(param,1,2)) ) {
      if (_win32s()) {
         concur_command(substr(param,1,2),false,true,false,true,idname);
         param=_maybe_quote_filename(param);
         if (pos('&',param,1) && substr(param,1,1)!='"') {
             param='"'param'"';
         }
         concur_command('cd 'param,false,true,false,true,idname);
      } else {
         drive := substr(param,1,2);
         param=_maybe_quote_filename(param);
         if (pos('&',param,1) && substr(param,1,1)!='"') {
             param='"'param'"';
         }
         concur_command(drive' & cd 'param,false,true,false,true,idname);
      }
   } else {
      param=_maybe_quote_filename(param);
      if (pos('&',param,1) && substr(param,1,1)!='"') {
         param='"'param'"';
      }
      concur_command('cd 'param,false,true,false,true,idname);
   }
   activate_window(orig_view_id);
}


/**
 * For file system with drive letters, when a command of the syntax "<b>d:</b>" is
 * executed, the editor translates the command into "<b>change-drive d:</b>" which
 * calls this command procedure.  The <b>change_drive</b> command changes the current
 * working directory to the drive and path specified.  A current directory message is displayed.
 *
 * @return  Returns 0 if successful.  Common error code is PATH_NOT_FOUND_RC.
 *
 * @categories File_Functions
 */
_command change_drive(_str drive_path='')
{
   /* if cd is changed. May have to change this. */
   return(cd(drive_path));
}

// List of known file managers, in rough order of how common
// they are.
static _str linux_file_managers[] = {
   "nautilus",
   "nemo",
   "dolphin",
   "konquerer",
   "thunar", 
   "caja",
   "peony",
   "pcmanfm"
};

/**
 * Displays the OS-specific file manager. (eg: Windows Explorer
 * on Windows, Finder on macOS.) Optionally browses to a
 * directory or file.
 *
 * @param directory Optional directory or file to browse to. If
 *                  empty, defaults to current working directory
 *                  or currently active file. Use - to ignore
 *                  current file or current directory and browse
 *                  from the system root.
 */
_command void explore,finder(_str directory = '') name_info(FILE_MAYBE_LIST_BINARIES_ARG'*,'VSARG2_CMDLINE)
{
   cmdline := "";
   selectedFile := "";
   if (directory == '') {
      // No directory supplied.
      // Use the directory for the current document, if any.
      if (_mdi.p_child.p_window_id && _mdi.p_child.p_buf_name != '' && file_exists(_mdi.p_child.p_buf_name)) {
         directory = _strip_filename(_mdi.p_child.p_buf_name, 'NE');
         selectedFile = _mdi.p_child.p_buf_name;
      } else {
         // Default to the current working directory
         directory = getcwd();
      }
   } else if (directory == '-') {
      // "Special" argument
      // Ignore any open document or working directory. Go to system root.
      directory = '';
   } else {
      // User supplied a directory argument
      if (def_unix_expansion) {
         directory = _unix_expansion(directory);
      }
      if (!isdirectory(directory)) {
         // Supplied argument not a valid directory
         // See if the 'directory' argument is actually a file
         if (file_exists(directory)) {
            selectedFile = directory;
            directory = _strip_filename(selectedFile, 'NE');
         } else {
            // Default to the current working directory
            directory = getcwd();
         }
      }
   }

   if (_isWindows()) {
      // Invoking Windows Explorer
      // explorer /e,/select,"Path to file"
      // or
      // explorer /e,"Directory"
      // Note: /e usage will display in "full" explorer view, using the folders sidebar
      // Remove the /e for a "bare" folder view
      // This could be made an option or a def-var
      if (selectedFile != '') {
         cmdline = strip('explorer /e,/select,':+_maybe_quote_filename(selectedFile));
      } else if (directory != '') {
         cmdline = strip('explorer /e,':+_maybe_quote_filename(directory));
      } else {
         cmdline = 'explorer';
      }
   } else {
      if(_isMac()) {
         // Invoking MacOS finder
         cmdline = "osascript -e 'tell application \"Finder\" to activate";
         // If we have a particular file or directory we want to show, reveal them
         if (selectedFile != '') {
            cmdline :+= " reveal posix file \""selectedFile"\"";
         } else if (directory != '') {
            cmdline :+= " reveal posix file \""directory"\"";
         } else if (def_unix_expansion) { //fall through to user's home directory
            cmdline :+= " reveal posix file \""_unix_expansion("~")"\"";
         } else { //fall even further through to the startup disk
            cmdline :+= " make new Finder window to startup disk";
         }
         cmdline :+= "'";
      } else {
         session_name := get_xdesktop_session_name();
         if (session_name=='cinnamon') {
            _str fmpath = path_search('nemo');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else if (session_name == 'gnome' || session_name == 'unity') {
            // GNOME desktop environment.  Nautilus doesn't seem to be able to 
            // select a file.
            _str fmpath = path_search('nautilus');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else if (session_name == 'lxde' || session_name == 'lxde-pi') {
            _str fmpath = path_search('pcmanfm');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else if (session_name == 'xubuntu' || session_name == 'xfce') {
            _str fmpath = path_search('thunar');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else if (session_name == 'kde') {
            // KDE desktop environment
            _str fmpath = path_search('dolphin');

            if (fmpath == '') 
               fmpath = path_search('konqueror');

            if (fmpath != '') {
               cmdline = fmpath;
               if (selectedFile != '') {
                  cmdline :+= ' --select ' :+ _maybe_quote_filename(selectedFile);
               } else if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else if (session_name == 'mate') {
            fmpath := path_search('caja');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' '_maybe_quote_filename(directory);
               }
            }
         } else if (file_exists("/usr/dt/bin/dtfile")) {
            cmdline = "/usr/dt/bin/dtfile -dir " :+ _maybe_quote_filename(directory); 

         } else if (machine() == "SGMIPS") {
            _str fmpath = path_search('fm');
            if (fmpath != '') {
               cmdline = fmpath;
               if (directory != '') {
                  cmdline :+= ' ' :+ _maybe_quote_filename(directory);
               }
            }
         } else {
            // Getting here is entirely possible, because the choice of a window manager 
            // doesn't necessarily tell you what system or file manager being used.  
            // For example: what goes with i3?  Anything does, there isn't a file manager assoicated with 
            // it.  So we go through a list of know managers that's in order of the most common, and
            // use the first one we find.  If we fall through here, we can't select a particular file - not
            // that most of them allow this in the command line anyway.
            foreach (auto fmn in linux_file_managers) {
               fmpath := path_search(fmn);
               if (fmpath != '') {
                  cmdline = fmpath;
                  if (directory != '') {
                     cmdline :+= ' '_maybe_quote_filename(directory);
                  }
                  break;
               }
            }

            if (cmdline == '') {
               message('Unable to determine desktop session for session name 'session_name);
               return;
            }
         }

      }

   }

   if (cmdline != '') {
      if (_isMac()) {
         shell(cmdline); //osascript doesn't like the 'N' option.
      } else {
         shell(cmdline, 'NA');
      }
   }
}
