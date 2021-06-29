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
#import "error.e"
#import "main.e"
#import "os2cmds.e"
#import "saveload.e"
#import "stdprocs.e"
#import "stdcmds.e"
#endregion

_str compile_rc;

/**
 * Get the name of current xdesktop session.  This is especially
 * useful on UNIX where multiple desktop session types exist.
 * 
 * @return _str session name
 * <ul>
 *    <li>winnt
 *    <li>gnome
 *    <li>kde
 *    <li>unity        (Ubuntu unity)
 * </ul>
 */
_str get_xdesktop_session_name()
{
   _str list_sessions[];
   list_sessions._makeempty();
   list_sessions[0] = 'kde';
   list_sessions[1] = 'gnome';

   temp := get_env('WINDOWMANAGER');
   int i, n = list_sessions._length();
   for (i = 0; i < n; ++i) {
      if (pos(list_sessions[i], temp) > 0) {
         return list_sessions[i];
      }
   }

   session_name := lowcase(get_env('DESKTOP_SESSION'));
   if (session_name == '') {
      session_name = lowcase(get_env('XDG_SESSION_DESKTOP'));
   }

   if (session_name == 'ubuntu'
       || session_name == 'ubuntu-2d') {
      return 'unity';
   } else if (session_name == 'ubuntu-xorg' || session_name == 'ubuntu-wayland') {
      // Ubuntu 17 or above then? Gnome based.
      return 'gnome';
   } else if (session_name != ''
       && session_name != 'default') {                // This is not a helpful session name.
      return session_name;
   } 

   if (get_env('KDE_FULL_SESSION') :== 'true') {
      return 'kde';
   }

   if (get_env('GNOME_DESKTOP_SESSION_ID') != '') {
      return 'gnome';
   }

   // Detection failed.
   return '';
}

/**
 * Launchs the plaform-specific OS Shell.
 *  
 * @categories Miscellaneous_Functions
 */
_command void launch_os_shell() name_info(',')
{
   // Use the directory for the current document, if any.
   selectedFile := "";
   directory := "";
   if (_mdi.p_child.p_window_id && _mdi.p_child.p_buf_name != '' && file_exists(_mdi.p_child.p_buf_name)) {
     directory = _strip_filename(_mdi.p_child.p_buf_name, 'N');
     selectedFile = _mdi.p_child.p_buf_name;
   } else {
     // Default to the current working directory
     directory = getcwd();
   }

   cmd := "";
    if (_isMac()) {
        scriptPath := get_env("VSDIR");
        _maybe_append_filesep(scriptPath);
        scriptPath :+= "terminalPath.applescript";
        scriptArg := _maybe_quote_filename(scriptPath);
        directoryArg := _maybe_quote_filename(directory);
        cmd = "osascript " :+ scriptArg :+ " " :+ directoryArg;
    /*} else {  Same code is built-in for Linux
        session := get_xdesktop_session_name();
        switch (session) {
        case 'unity':
        case 'gnome':
            cmd = path_search('gnome-terminal');
            break;
        case 'kde':
            cmd = path_search('konsole');
            break;
        default:
            break;
        }*/
    }
   
   if (cmd != '') {
      shell(cmd, 'QAB');
   } else {
      dos();
   }
}

/**
 * Executes the external macro or program specified by-passing an 
 * internal command search for the command.  This command is 
 * intended to be called from the command line.  Use the shell built-in to 
 * achieve the same function from within a macro.
 * 
 * <p>Command line example:<br>
 * 
 * xcom find                    - Runs an external find program or Slick-C&reg; 
 * batch program.</p>
 * 
 * @return Return code of external macro or program specified is returned.
 * 
 * @see dos
 * @see shell
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command xcom(_str cmdline='') name_info(FILE_ARG' 'WORD_ARG'*,'VSARG2_EDITORCTL)
{
   typeless shell_wait='';
   command := "";
   rest := "";
   _str params=cmdline;
   parse params with command rest ;
   if ( lowcase(command)=='dos' ) {
      return(dos(rest));
   }
   // Run asynchronously
   typeless status=shell(params,shell_wait'a');
   if ( (params!='' || status<0) && shell_wait!='' ) {
      if ( status<0 ) {
         message(get_message(status));
      }
   }
   return(status);

}

/**
 * Executes the external program <i>command</i> specified.  No search for 
 * SlickEdit batch programs is performed.  If no <i>command</i> is 
 * specified, the shell specified by the COMSPEC (UNIX: SHELL) environment 
 * variable is executed with no parameters.  
 * <p>
 * Specify the -e parameter if you want the standard output of the command to 
 * be processed as error messages.  The DOS command is intended to be called 
 * from the command line.  Use the <b>shell</b> built-in to achieve the same 
 * function from within a macro.
 * <p>
 * The -w option is used when you want to run a text mode program and wait 
 * for a key press in order to view the output before the DOS (UNIX: xterm) 
 * window is closed.  Under UNIX, this is equivalent to typing 
 *    <b>xterm -T "<i>pgm</i>" -e slkwait $SHELL -c "<i>command</i>"</b>.
 * <P>
 * The -s option specifies to run the command synchronous.  When the -s option 
 * is not specified, the program is run asynchronously.
 * <P>
 * The -t option specifies to run the <i>command</i> specified in an xterm window.   
 * This is equivalent to typing 
 *    <b>xterm -T "<i>pgm</i>" -e $SHELL -c "<i>command</i>"</b> 
 * at a UNIX prompt.  Where <i><b>pgm</b></i> is the first word or quoted string 
 * of <i><b>command</b></i>.  You can set a VSLICKXTERM environment variable to 
 * run a different xterm program.  This option is ignored under non-UNIX platforms.
 * <P>
 * @example
 * <pre>
 *         dos -w dir/w - Execute the DOS dir command and wait for key press.
 *         dos -t man cc   - Run the UNIX man program and wait for a key press
 * </pre>
 * 
 * @param command          parameters of the form: [-e | -w | -s | -t] <i>ProgramName</i> Args
 * 
 * @return  Returns positive return code of program executed which may include 0.  
 * Common negative return codes may be FILE_NOT_FOUND_RC, PATH_NOT_FOUND_RC, and 
 * INSUFFICIENT_MEMORY_RC.  Almost all negative return codes occur before the 
 * program is executed.
 * <p>
 * <b>non-UNIX platforms</b>: When a pipe symbol, '|', or '&lt;' is used, SlickEdit 
 * executes the default shell to handle the redirection.  The default shell may 
 * throw away the return code of the program executed.
 * <p>
 * <b>UNIX platforms</b>:  The default shell is always used to parse the <i>command</i> 
 * string specified.
 * 
 * @see shell
 * @categories Miscellaneous_Functions
 */
_command dos(_str command='', _str unused='', _str errorFileName='') name_info(FILENEW_ARG' 'WORD_ARG'*,'VSARG2_EDITORCTL)
{
   // Using FILENEW_ARG because of path searching and DOS internal commands like "echo" which are not found on disk.
   async := 'a';
   shell_wait := "";
   memory := "";
   echo_dos_output := "";
   cmdline := strip(command,'L');
   number := "";
   rest := "";
   compname := "";
   winapp_file := "";
   parse cmdline with number rest;
   if ( isinteger(number) ) {
      cmdline=rest;
      memory=number;
   }
   alternate_shell := "";

   typeless redirect_errors=0;
   typeless redirect_args='';
   typeless compiler_is_winapp=0;
   typeless capture_errors=0;
   AccumlateErrors := false;
   NoNextError := false;
   AddVslickErrorInfo := false;
   for (;;) {
      if (substr(cmdline,1,1)!='-') {
         break;
      }
      switch(upcase(substr(cmdline,2,1))){
      case 'A':
         AccumlateErrors=true;
         parse cmdline with . cmdline;
         break;
      case 'N':
         NoNextError=true;
         parse cmdline with . cmdline;
         break;
      case 'W':
         shell_wait='W';
         parse cmdline with . cmdline;
         break;
      case 'J':
         shell_wait='J';  // Wait for key press and display Project "wait for keypress" option message
         parse cmdline with . cmdline;
         break;
      case 'S':
         async='';
         parse cmdline with . cmdline;
         break;
      case 'E':
         capture_errors=1;
         parse cmdline with . cmdline;
         break;
      case 'T':
         alternate_shell=1;
         parse cmdline with . cmdline;
         break;
      case 'V':
         AddVslickErrorInfo=true;
         parse cmdline with . cmdline;
         break;
      default:
         break;
      }
   }
   if (_isUnix() && !_isMac()) {
      if (alternate_shell!='') {
         _str temp=cmdline;
         alternate_shell=_XtermGetCommandPrefix(parse_file(temp));
         if (alternate_shell == "") {
            _message_box(nls("Can't find an X terminal emulator (xterm,dtterm,aixterm,hpterm,cmdtool).\nPlease set VSLICKXTERM to the full path to your X terminal emulator."));
            return(FILE_NOT_FOUND_RC);
         }
      }
   }
   name := "";
   if (capture_errors) {
      async='';
      if ( errorFileName=='' ) {
         //name=COMPILE_ERROR_FILE;
         name=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
      } else {
         name=errorFileName;
      }
      if (AddVslickErrorInfo) {
         status := 0;
         temp_view_id := 0;
         orig_view_id := 0;
         if (file_exists(name)) {
            status=_open_temp_view(name,temp_view_id,orig_view_id);
         }else{
            orig_view_id=_create_temp_view(temp_view_id);
            p_buf_name=name;
            p_UTF8=_load_option_UTF8(p_buf_name);
         }
         if (!status) {
            //Doesn't seem like we should have to return because we had a status here...
            bottom();
            insert_line(_VslickErrorInfo(false));
            _save_file('+o');
            p_window_id=orig_view_id;
            _delete_temp_view(temp_view_id);
         }
      }
      quit_error_file(errorFileName);
      /*
          Might want to reset buffer name like we did in version 2.0.
          However, it does not make sense why this was done only when
          shell_wait!=''.
      */
      //buf_name=p_buf_name;p_buf_name='';
      if(def_auto_reset) reset_next_error('','',0 /* no messages */);
      //p_buf_name=buf_name;

      // Removed check for '@' since it is no longer used.  See slick2.4 code.
      echo_dos_output='E';

      compile_rc=0;
      if ( _error_mark!='' ) {
         _deselect(_error_mark);
      }
      _error_file=absolute(name);
      compiler_is_winapp=find_index('_compiler_redirect',PROC_TYPE);
      if (compiler_is_winapp) {
         parse cmdline with compname .;
         compiler_is_winapp=call_index(compname,winapp_file,compiler_is_winapp);
      }
      if (!compiler_is_winapp) {
         redirect_errors=1;
         ExtraCh := "";
         if (AccumlateErrors) {
            ExtraCh='>';
         }
         if (_isUnix()) {
           /* Unix does not like $ in filenames so use single quote chars. */
            redirect_args=ExtraCh:+">'"name"'";
         } else {
            redirect_args=ExtraCh:+">"name;
         }
         if ( ! pos('2>&1',cmdline) ) {
            redirect_args :+= ' 2>&1';
         }
         if (_isUnix()) {
            alternate_shell=path_search('sh');
         }
      } else {
         redirect_errors=0;
      }
   }
   parse cmdline with number rest;
   if ( memory=='' && isinteger(number) ) {
      cmdline=rest;
      memory=number;
   }
   if ( cmdline=='' || redirect_errors ) {
      shell_wait='';
   }
   filename := "";
   cmdargs := "";
   typeless status=0;
   old_comspec := "";
   if ( cmdline=='' ) {
      if (_isWindows()) {
         old_comspec=get_env('PROMPT');
         if ( old_comspec=='' ) {
            old_comspec='$p$g';
         }
         if (async=='') {
             set_env('PROMPT','(SlickEdit)'old_comspec);
         }
         status=shell(memory,async'B');
         set_env('PROMPT',old_comspec);
      } else {
         if (_isMac()) {
            // Handle case of 'dos' with no arguments on the Mac. 
            // Don't fall through to show xterm. Bring up Terminal.
            if(cmdline=='' && redirect_errors==0 && capture_errors == 0) {
               launch_os_shell();
               return(0);
            }
         }
         status=shell(memory,async'B');
      }
   } else {
      cmdargs=cmdline;
      name=parse_file(cmdargs);
      i := pos('[\<\>\|\&]',name,1,'r');
      if (i) {
         cmdargs=substr(name,i)' 'cmdargs;
         name=substr(name,1,i-1);
      }
      //temp=path_search(name,'PATH','P');
      _str temp=slick_path_search(name,'P');
      if ( pos(' ',temp) ) {
         temp=_maybe_quote_filename(temp);
      }
      filename=memory " "temp " "redirect_args " "cmdargs;
      if (temp=='') {
         message(nls("Program '%s' not found",name));
         return(FILE_NOT_FOUND_RC);
      }
      if (_isMac() && alternate_shell != "") {
         status=external_cmd(name,cmdargs,1,'wa');
      } else if (compiler_is_winapp) {
         status=shell(filename);
      }else{
         //say('options='echo_dos_output:+shell_wait:+async);
         status=shell(filename,((_dos_quiet)?'q':''):+echo_dos_output:+shell_wait:+async'B',alternate_shell);
      }
   }
   if ( (cmdline!='' || status<0) /*&& shell_wait!='' */ && ! redirect_errors ) {
      if ( status<0 ) {
         message(get_message(status));
      }
   }
   if ( ! (status<0) && !(_dos_NextErrorIfNonZero && status==0) &&
        (redirect_errors||compiler_is_winapp) && !NoNextError) {
      if (compiler_is_winapp) {
         status=copy_file(winapp_file, COMPILE_ERROR_FILE);
      }
      compile_rc=status;
      xnext_error2();
   }
   return(status);
}

/** 
 * Passes <i>text</i> to the operating system <b>copy</b> (UNIX: <b>cp</b>) 
 * command.  See your operating system manual for argument syntax.
 * <p>
 * In ISPF emulation, this command is not called when invoked from the 
 * command line.  Instead <b>ispf_copy</b> is called.  Use <b>dos_copy </b>to 
 * explicitly invoke the <b>copy </b>command.
 *  
 * @return  Return code depends on operating system.  Use the <b>copy_file</b> built-in for predictable and portable results.
 * 
 * 
 * @categories File_Functions
 */
_command dos_copy,copy(_str cmdline='') name_info(FILE_ARG'*,')
{
   typeless status;
   if (_isUnix()) {
      status=external_cmd('cp',cmdline,last_index('','w'),'wa');
   } else {
      status=external_cmd('copy',cmdline,last_index('','w'),'wa');
   }
   return(status);

}


/** 
 * Passes <i>text</i> to the operating system <b>del</b> (UNIX: <b>rm</b>) 
 * command.  See operating system manual for syntax of arguments.  Use the
 *  <b>delete_file</b> built-in for reliable and portable error codes.
 * <p>
 * In ISPF emulation, this command is not called when invoked from 
 * the command line.  Instead <b>ispf_delete</b> is called.  Use 
 * <b>dos_del</b> to explicitly invoke the <b>del </b>command.
 * @categories File_Functions
 */
_command dos_del,del(_str cmdline='') name_info(FILE_ARG'*,')
{
   typeless status;
   if (_isUnix()) {
      status=external_cmd('rm',cmdline,last_index('','w'),'wa');
   } else {
      status=external_cmd('del',cmdline,last_index('','w'),'wa');
   }
   return(status);

}
_command dos_rmdir,rmdir(_str cmdline='') name_info(FILE_ARG'*,')
{
   typeless status=external_cmd('rmdir',cmdline,last_index('','w'),'wa');
   return(status);

}
/** 
 * Passes <i>text</i> to the operating system <b>rename</b> (UNIX: <b>mv</b>) 
 * command.  See your operating system manual for argument syntax.
 * 
 * <p>In ISPF emulation, this command is not called when invoked from the 
 * command line.  Instead <b>ispf_move</b> is called.  Use <b>dos_move</b> to 
 * explicitly invoke the <b>move </b>command.</p>
 *  
 * @return Return code depends on operating system.
 *  
 * @categories File_Functions
 * 
 */
_command dos_move,move(_str cmdline='') name_info(FILE_ARG'*,')
{
   typeless status;
   if (_isUnix()) {
      status=external_cmd('mv',cmdline,last_index('','w'),'wa');
   } else {
      status=external_cmd('move',cmdline,last_index('','w'),'wa');
   }
   return(status);

}

/** 
 * Utility command for invoking an external macro or program from a menu.  
 * Normally, when an external macro or program is executed from a menu, there is 
 * no message displayed if the macro or program is not found (if it can't be 
 * executed for some strange reason).  Prefix your external macro or program you 
 * want to execute with <b>extern</b> to get better error handling.
 * 
 * @return  Returns 0 or return code of program or macro if successful.  
 * Common negative return codes are FILE_NOT_FOUND_RC, and ACCESS_DENIED_RC.  
 * Return value of external macro can be anything.
 * @categories File_Functions
 */
int external_cmd(_str name, _str params,
                 _str shell_options, _str exact_options)
{
   shell_wait := "";
   if ( shell_options ) {
      shell_wait=exact_options;
   }
   // if the user passed in arguments with an unterminated quote
   // just add in the missing quote in order to satisfy the shell
   if (_first_char(params)=='"' && !pos('"', params, 2)) {
      params :+= '"';
   }
   typeless status=shell(name' 'params,shell_wait);
   if ( shell_wait!='' ) {
     if ( status<0 ) {
        message(get_message(status));
     }
   }
   return(status);
}
int _compiler_redirect(_str prog_name,_str &output_file)
{
   prog_name=_strip_filename(prog_name,'p');
   if(!(_file_eq('cm68k',prog_name)||_file_eq('himake',prog_name))) return(0);
   // Always delete error file since we don't get error code and just
   // in case the compiler does not do this for us.
   if (file_match('edout -p', 1)!=''/* && def_del_error_file*/) {
      delete_file('edout');
   }
   output_file=absolute('edout');
   COMPILE_ERROR_FILE=output_file;
   return(1);
}
#if 1 /*__UNIX__*/
/**
 * Check to see if the specified X terminal emulator is available in the
 * specified directory.
 *
 * @param directory directory to check
 * @param term      X terminal emulator name
 * @param xterm     returning path to the emulator program
 * @param setEnvVar Flag: 1 to also set VSLICKXTERM if the emulator is found
 */
static bool containsXterm(_str directory, _str term, _str & xterm, bool setEnvVar=true)
{
   xterm = directory;
   _maybe_append_filesep(xterm);
   xterm :+= term;
   if (file_exists(xterm)) {
      if (setEnvVar) set_env("VSLICKXTERM", xterm);
      return true;
   }
   xterm = "";
   return false;
}

/**
 * Find the path to the X terminal emulation program on this OS.
 * Different OS has different emulators.
 *
 * @return path to the first X terminal emulator found, "" for none found
 */
static _str buildXtermPath()
{
   // If the an explicit X terminal emulator is specified, use it.
   _str xterm;
   xterm = get_env("VSLICKXTERM");
   if (xterm != "" && file_exists(xterm) && !isdirectory(xterm)) return(xterm);

   // Look for the 'xterm' in the user's PATH. If found, VSLICKXTERM
   // is also set to the path so that it can be reused in subsequent
   // calls.
   xterm = path_search("xterm");
   if (xterm != "") {
      set_env("VSLICKXTERM", xterm);
      return(xterm);
   }

   // Look for 'xterm' in the normal places.
   if (containsXterm("/usr/bin/X11/", "xterm", xterm)) return(xterm);
   if (containsXterm("/usr/X11R6/bin/", "xterm", xterm)) return(xterm);
   if (containsXterm("/usr/X11/bin/", "xterm", xterm)) return(xterm);

   // Look for variants of X emulators that are platform dependent.
   _str ostype = machine();
   if (ostype == "SPARCSOLARIS" || ostype == "SPARC" || ostype=="INTELSOLARIS") {
      if (containsXterm("/usr/openwin/bin/", "xterm", xterm)) return(xterm);
      if (containsXterm("/usr/dt/bin/", "xterm", xterm)) return(xterm);
      if (containsXterm("/usr/dt/bin/", "dtterm", xterm)) return(xterm);
      if (containsXterm("/usr/openwin/bin/", "cmdtool", xterm)) return(xterm);
   } else if (ostype == "RS6000") {
      if (containsXterm("/usr/lpp/X11/bin/", "xterm", xterm)) return(xterm);
      if (containsXterm("/usr/dt/bin/", "dtterm", xterm)) return(xterm);
      if (containsXterm("/usr/lpp/X11/bin/", "aixterm", xterm)) return(xterm);
   } else if (ostype == "HP9000") {
      if (containsXterm("/usr/dt/bin/", "xterm", xterm)) return(xterm);
      if (containsXterm("/usr/dt/bin/", "dtterm", xterm)) return(xterm);
      if (containsXterm("/usr/bin/X11/", "hpterm", xterm)) return(xterm);
      if (containsXterm("/usr/X11/bin/", "hpterm", xterm)) return(xterm);
   } else if (ostype == "SCO") {
      if (containsXterm("/usr/bin/X11/", "scoterm", xterm)) return(xterm);
      if (containsXterm("/usr/X11/bin/", "scoterm", xterm)) return(xterm);
   } else if (ostype == "SGMIPS") {
      if (containsXterm("/usr/sbin/", "xterm", xterm)) return(xterm);
      if (containsXterm("/usr/sbin/", "xwsh", xterm)) return(xterm);
      if (containsXterm("/usr/sbin/", "iwsh", xterm)) return(xterm);
   }
   return('');
}
_str _XtermGetCommandPrefix(_str title,bool includeShell=true)
{
   _str xterm=buildXtermPath();
   if (xterm == "") {
      _message_box(nls("Can't find an X terminal emulator (xterm,dtterm,aixterm,hpterm,cmdtool).\nPlease set VSLICKXTERM to the full path to your X terminal emulator."));
      return('');
   }
   _str prefix=xterm' -T "'title'" -e ';
   if( includeShell ) {
      cmdshell := get_env('SHELL');
      if (cmdshell=='') {
         cmdshell=path_search('sh');
      }
      if( cmdshell=='' ) {
         _message_box(nls("Cannot find shell ($SHELL,sh)."));
         return('');
      }
      prefix :+= ' 'cmdshell' -c';
   }
   return(prefix);
}
#endif
