////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50045 $
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
#include "toolbar.sh"
#import "dir.e"
#import "env.e"
#import "files.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "project.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbshell.e"
#import "toolbar.e"
#import "util.e"
#endregion

/* This file contains commands which only work on OS/2 */

/**
 * Passes <i>cmdline</i> to operating system start command.  This 
 * command is not supported by the UNIX version.
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command start(_str cmdline="")
{
   typeless status=shell('start 'cmdline,'p');
   return(status);

}

#if __NT__
   _str def_wshell='wshell';  /* Build window shell under windows. */
   _str def_ntshell;          /* Build window shell for Windows NT. */
#endif

#if __NT__
   boolean def_build_allow_utf8_2=false;
#else
   boolean def_build_allow_utf8_2=true;
#endif


_str _VslickErrorInfo(boolean InsertEcho=true)
{
   _str VslickIncludePath='';
   if (_project_name!='') {
      _ini_get_value(_project_name,"Compiler","includedirs",VslickIncludePath,'');
      VslickIncludePath=_absolute_includedirs(VslickIncludePath,_project_name);
      if (VslickIncludePath!='') {
         VslickIncludePath=PATHSEP:+_xlat_env(VslickIncludePath);
      }
   }
   _str Echo='echo ';
   if (!InsertEcho) {
      Echo='';
   }
   return(Echo:+'VSLICKERRORPATH="'getcwd():+VslickIncludePath'"');
}

#if __UNIX__
   // This list gets looked at for automatically generated commands
   // like project commands
   _str def_no_error_info_commands2='vsbuild java ls echo cp mv rm mkdir rmdir cd diff find more sed set export setenv';
                                   //2:46pm 7/8/1999
                                   //Obviously need more here, these are just what
                                   //I could think of.  DWH.
   // This list gets looked at for automatically generated commands
   // like project commands and when ENTER is pressed in
   // the build window.
   _str def_error_info_commands='cc CC gcc g++ gcc-3 gcc-4 g++-3 g++-4 vst javc sgrep c89 c++ vscomp.rexx';
   // This regular expression gets looked at when you press ENTER in the
   // build window.
   _str def_error_info_commands_re='^?*make?*$';
#else
   // This list gets looked at for automatically generated commands
   // like project commands.
   #define COMMAND_PROCESS_COMMANDS 'ASSOC AT ATTRIB BREAK CACLS CALL CD CHCP CHDIR '\
                                   'CHKDSK CLS CMD COLOR COMP COMPACT CONVERT COPY '\
                                   'DATE DEL DIR DISKCOMP DISKCOPY DOSKEY ECHO '\
                                   'ENDLOCAL ERASE EXIT FC FIND FINDSTR FOR FORMAT '\
                                   'FTYPE GOTO GRAFTABL HELP IF KEYB LABEL MD MKDIR '\
                                   'MODE MORE MOVE PATH PAUSE POPD PRINT PROMPT PUSHD '\
                                   'RD RECOVER REM REN RENAME REPLACE RESTORE RMDIR '\
                                   'SET SETLOCAL SHIFT SORT START SUBST TIME TITLE '\
                                   'TREE TYPE VER VERIFY VOL XCOPY'
   // This list gets looked at for automatically generated commands
   // like project commands and when ENTER is pressed in
   // the build window.
   _str def_no_error_info_commands2='vsbuild java pkzip pkunzip unzip';

   // This list gets looked at when you press ENTER in the build window.
   _str def_error_info_commands='cl javac sj grep sgrep vst msdev';
   // This regular expression gets looked at when you press ENTER in the
   // build window.
   _str def_error_info_commands_re='^?*make?*$';
#endif

/**
 * Determines if extra error search information is needed for error
 * processing.  This function only gets called for automatically generated
 * commands.  This function DOES NOT get called when the ENTER key is
 * pressed in the build window.
 *
 * @param cmd    Command string to be added to the build window.
 * @return Returns true if error search information is needded.
 */
boolean _NeedVslickErrorInfo(_str cmd)
{
   _str cur="";
#if !__UNIX__
   if (isalpha(substr(cmd,1,1)) && substr(cmd,2,1)==':') {
      _str rest=strip(substr(cmd,3));
      if (rest=="" || substr(rest,1,1)=='&') {
         return(false);
      }
   }
   parse cmd with cur '[ \\/]','r';
   if (cur!='') {
      if (pos(' 'cur' ',' 'COMMAND_PROCESS_COMMANDS' ',1,_fpos_case)) {
         return(false);
      }
   }
#endif
   _str temp="";
   parse cmd with cur temp;
   if (cur=='') {
      return(false);
   }
   cur=_strip_filename(cur,'P');
   if (pos(' 'cur' ',' 'def_no_error_info_commands2' ',1,_fpos_case)) {
      return(false);
   }
   return(true);
}
/**
 * Determines if extra error search information is needed for error
 * processing.  This function only gets called when the ENTER key
 * is pressed in the build window.  This function DOES NOT
 * get called for automatically generated commands.
 *
 * @param cmd    Command string to be added to the build window.
 * @return Returns true if error search information is needded.
 */
boolean _NeedVslickErrorInfo2(_str cmd)
{
   _str cur="";
   _str temp="";
   parse cmd with cur temp;
   if (cur=='') {
      return(false);
   }
   cur=_strip_filename(cur,'P');
   if (pos(' 'cur' ',' 'def_no_error_info_commands2' ',1,_fpos_case)) {
      return(false);
   }
   if (pos(' 'cur' ',' 'def_error_info_commands' ',1,_fpos_case)) {
      return(true);
   }
   if (pos(def_error_info_commands_re,cur,1,'r'_fpos_case)) {
      return(true);
   }
   return(false);
}

/**
 * Inserts command at end of ".process" buffer.  If last line contains the read
 * point, text after the read point is replaced with command.  
 * The build window is started if necessary.
 * 
 * @param command
 * @param leave_active
 * @param quiet
 * @param uniconize
 * @param addErrorInfo
 * 
 * @return Returns 0 if command queued successfully.  However, this does not
 *         mean that the command will execute successfully.  A non-zero return code
 *         means that the build window was not created.  Common error
 *         codes are: TOO_MANY_FILES_RC, TOO_MANY_SELECTIONS_RC, CANT_FIND_INIT_PROGRAM_RC,
 *         ERROR_CREATING_SEMAPHORE_RC, TOO_MANY_OPEN_FILES_RC, NOT_ENOUGH_MEMORY_RC,
 *         ERROR_CREATING_QUEUE_RC, INSUFFICIENT_MEMORY_RC,  and ERROR_CREATING_THREAD_RC.
 *         On error, message is displayed.
 * @categories File_Functions
 */
_command concur_command(_str command="",boolean leave_active=false,boolean quiet=false,boolean uniconize=true,boolean addErrorInfo=true)
{
   //command=arg(1);
   //quiet=arg(3);
   //leave_active=arg(2)!='' && arg(2);
   typeless found_tile=0;
   typeless orig_buf_id=0;
   int orig_wid=0;
   if ( _process_info('b') || p_window_id==VSWID_HIDDEN || !p_HasBuffer) {
      orig_buf_id='';
   } else {
      orig_wid=p_window_id;
      orig_buf_id=p_buf_id;
      found_tile=_find_tile('.process');
   }
   typeless status=0;
   int temp_view_id=0;
   int orig_view_id=0;
   boolean doDeleteTempView=false;
   if ((!uniconize && leave_active==false) && _process_info() && buf_match('.process',1,'hx')) {
      _open_temp_view('.process',temp_view_id,orig_view_id,'+b');
      doDeleteTempView=true;
   } else {
      if (def_process_tab_output) {
         if( _tbMaybeAutoShow("_tbshell_form") > 0 ) {
            // The Build tool window will be auto shown. In order to prevent
            // it from auto hiding before the user has a chance to see the
            // output, we give it focus. All the user has to do is hit ESC
            // to hide it again.
            status=start_process_tab(false,true,quiet,uniconize);
         } else {
            int focus_wid=_get_focus();
            status=start_process_tab(false,false /* No focus changes. */,quiet,uniconize);
            // Need this code so that Unix focus is set properly.
            // Do this for Windows too in order to hopefully potentially uncover a bug 
            // that would also occur on Unix.
            if (focus_wid) {
               focus_wid._set_focus();
            }
         }
      } else {
         status=start_process(false,false /* No focus changes. */,quiet,uniconize);
      }
      if ( status ) {
         if ( status!=PROCESS_ALREADY_RUNNING_RC ) {
            if (_iswindow_valid(orig_wid) && orig_buf_id!='') {
               p_window_id=orig_wid;
               p_buf_id=orig_buf_id;
            }
            return(status);
         }
         clear_message();
      }
   }

   if ( p_Noflines!=p_line ) {
      bottom();
   }

   _str line='';
   int col=0;
   if ( _process_info('c') ) {
      col=_process_info('c');
   } else {
      line='';
      col=1;
   }
   p_col=col;
   _delete_text(-1);
   _str memory="";
   _str rest="";
   parse command with memory rest;
   if ( isinteger(memory) ) {
      command=rest;
   }
#if !__UNIX__
   if (machine()=='WINDOWS' && length(command)>ntGetMaxCommandLength()) {
      int orig_view_id2=0;
      int temp_view_id2=0;
      orig_view_id2=_create_temp_view(temp_view_id2);
      p_UTF8=0;  // vsexecfromfile does not support Unicode yet
      _str temp_name=mktemp();
      p_buf_name=temp_name;
      insert_line(command);
      status=_save_file('+o');
      _delete_temp_view(temp_view_id2);
      if (status) {
         _message_box(nls("Unable to write to '%s'",temp_name));
      }
      activate_window(orig_view_id2);
      command=maybe_quote_filename(get_env('VSLICKBIN1'):+'vsexecfromfile')' -d ' maybe_quote_filename(temp_name);
   }
#endif
   if (addErrorInfo && _NeedVslickErrorInfo(command)) {
      _insert_text(_VslickErrorInfo()"\n"command"\n");
   }else{
      _insert_text(command"\n");
   }
   //replace_line(line:+command);
   if ( (!leave_active || found_tile)&& orig_buf_id!='') {
      p_window_id=orig_wid;
      p_buf_id=orig_buf_id;
   } else {
      if (def_process_tab_output && p_active_form.p_name=='_tbshell_form') {
         if (!p_DockingArea) {
            _TOOLBAR *ptoolbar;
            ptoolbar=_tbFind(p_active_form.p_name);
            if (!ptoolbar || !(ptoolbar->tbflags & TBFLAG_ALWAYS_ON_TOP)) {
               p_active_form._set_foreground_window(VSWID_TOP);
               /*focus_wid=_get_focus();
               _set_focus();
               if (focus_wid) {
                  focus_wid._set_focus();
               } */
            }
         }
      } else {
         _set_focus();
      }
   }
   if (!quiet) {
      message(nls("Command %s queued",command));
   }
   if (doDeleteTempView) {
      _delete_temp_view(temp_view_id,false);
      activate_window(orig_view_id);
   }
   return(0);
}
int _OnUpdate_stop_process(CMDUI &cmdui,int target_wid,_str command)
{
   if (_process_info()) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
/**
 * Sends a Ctrl+Break signal to the build window created by 
 * the <b>start_process</b> command.
 * 
 * @see start_process
 * @see next_error
 * @see cursor_error
 * @see exit_process
 * @see set_next_error
 * @see reset_next_error
 * @see clear_pbuffer
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void stop_build,stop_process() name_info(','VSARG2_EDITORCTL)
{
   if(isEclipsePlugin()) {
      return;
   }
   _stop_process();
   call_list("_cbstop_process_");
}
_str no_concur_proc;

static int doStartProcess(boolean OpenInCurrentWindow, boolean doSetFocus,
                          boolean quiet, boolean uniconize, _str outputTo)
{
   int orig_focus=_get_focus();
   p_window_id=_edit_window();
   if ( pos(machine(),' 'no_concur_proc' ') ) {
      message(nls('Sorry.  No build window available for this operating system'));
      return(1);
   }
   _str old_buffer_name="";
   typeless swold_pos=0;
   typeless swold_buf_id=0;
   int buf_id=0;
   typeless status=0;
   boolean old_def_switchbuf_cd = def_switchbuf_cd;
   def_switchbuf_cd = 0;
   if (p_window_id==VSWID_HIDDEN) {
      status=start_process2(OpenInCurrentWindow,quiet,uniconize,outputTo);
   } else {
      set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
      buf_id=p_buf_id;
      status=start_process2(OpenInCurrentWindow,quiet,uniconize,outputTo);
      if ( p_buf_name!=old_buffer_name ) {
         switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);
      }
   }
   def_switchbuf_cd = old_def_switchbuf_cd;
   //messageNwait('doSetFocus='doSetFocus);
   if (doSetFocus) {
      //messageNwait('h1');
      _set_focus();
   } else {
      if (orig_focus != _get_focus() && orig_focus) {
         // (clark) if this ends up being a problem, we can pass
         // doSetFocus through to start_process2 and outputTabToolShowShell
         // and have outputTabToolShowShell() handle save/restore
         orig_focus._set_focus();
      }
   }
   return(status);
}
/*
_OnUpdate_start_process(..) does not work because it does not allow the start_process
command to activate the build window.

int _OnUpdate_start_process(CMDUI &cmdui,int target_wid,_str command)
{
   if (_process_info()) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
} */


/**
 * Starts or activates the build window.  The build window
 * is a command shell running inside an editor buffer.  The default 
 * command shell  is defined by the COMSPEC (UNIX: SHELL) 
 * environment variable.
 * 
 * @return Returns 0 if successful.  however, this does not mean that the 
 * command shell will execute successfully.  A non-zero return code 
 * means that the build window was not created.  Common 
 * error codes are:  TOO_MANY_FILES_RC, 
 * TOO_MANY_SELECTIONS_RC, 
 * CANT_FIND_INIT_PROGRAM_RC, 
 * ERROR_CREATING_SEMAPHORE_RC, 
 * TOO_MANY_FILES_RC, NOT_ENOUGH_MEMORY_RC, 
 * ERROR_CREATING_QUEUE_RC, 
 * INSUFFICIENT_MEMORY_RC, and 
 * ERROR_CREATING_THREAD_RC.  On error, message is 
 * displayed.
 * 
 * @see stop_process
 * @see next_error
 * @see exit_process
 * @see set_next_error
 * @see reset_next_error
 * @see cursor_error
 * @see clear_pbuffer
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command start_process(boolean OpenInCurrentWindow=false,
                       boolean doSetFocus=true,
                       boolean quiet=false,
                       boolean uniconize=true
                       ) name_info(','VSARG2_EDITORCTL)
{
   if(isEclipsePlugin()) {
      return -1;
   }
   if (!p_mdi_child) {
      if (p_HasBuffer && p_buf_name!='.process') {
         if (p_active_form.p_modal || !def_process_tab_output) {
            return('');
         }
      }
   }
   //OpenInCurrentWindow=arg(1)!="";
   //doSetFocus=arg(2)=="";
   //quiet=arg(3)!="";
   //uniconize=arg(4)=="";

   outputTo := 'T';
   if (!def_process_tab_output) outputTo = 'B';

   typeless status=doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,outputTo);
   if (doSetFocus && outputTo=='T') {
      //formwid = _find_object("_tbshell_form","N");
      int formwid = _tbIsVisible("_tbshell_form");
      if (formwid && !formwid.p_DockingArea) {
         formwid._set_foreground_window();
      }
   }
   return(status);
}
_command start_process_window(boolean OpenInCurrentWindow=false,
                       boolean doSetFocus=true,
                       boolean quiet=false,
                       boolean uniconize=true)
{
   return(doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,'B'));
}
_command start_process_tab(boolean OpenInCurrentWindow=false,
                       boolean doSetFocus=true,
                       boolean quiet=false,
                       boolean uniconize=true)
{
   return(doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,'T'));
}
_command restore_build_window()
{
   outputTo := (def_process_tab_output)? "T":"B";
   status := doStartProcess(false,false,true,false,outputTo);
   return status;
}

int _OnUpdate_toggle_process_tab_output(CMDUI &cmdui,int target_wid,_str command)
{
   return (!def_process_tab_output)? MF_CHECKED|MF_ENABLED:MF_ENABLED;
}
/**
 * Toggles whether or not the build window should be displayed
 * in an editor window or just in the Build tool window.
 * When this option is toggled from off to on, 
 * the build window is activated.
 * 
 * @see stop_process
 * @see start_process
 * 
 * @categories Miscellaneous_Functions
 */ 
_command void toggle_process_tab_output() name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   def_process_tab_output = !def_process_tab_output;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if (!def_process_tab_output) {
      start_process_window();
      if (p_LangId=='process') {
         bottom();_end_line();
      }
   }
}

/**
 * Searches for a window with the same tile id as the current window which is 
 * displaying the buffer, <i>buffer_name.</i>
 * 
 * @return  Returns the window id, if successful.  Otherwise, 0 is returned.  
 * If the current window is displaying <i>buffer_name</i>, the current window id 
 * is returned.
 * 
 * @appliesTo  Edit_Window
 * @categories Search_Functions, Window_Functions
 */
int _find_tile(_str buf_name)
{
   if (buf_name==_mdi.p_child.p_buf_name && (_mdi.p_child.p_window_id!=VSWID_HIDDEN )) {
      return(_mdi.p_child.p_window_id);
   }
   if (p_window_state=='N' ||
       (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS)
       ) {
      if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_TABGROUPS) ) {
         int wid=window_match(buf_name,1,'xn',-1,"vg,vm,va");
         return wid;
      }


      // Look for a tiled window already running process buffer.
      int tile_id=p_tile_id;
      int wid=window_match(buf_name,1,'xn');
      for (;;) {
         if (!wid) break;
         if (wid.p_mdi_child && wid.p_tile_id==tile_id && buf_name==wid.p_buf_name) {
            return(wid);
         }
         wid=window_match(buf_name,0,'xn');
      }
   }
   return(0);
}
void _create_process_retrieve_view() 
{
   if (process_retrieve_id=='' ) {  /* Start .process-command file. ? */
      int temp_wid=0;
      int orig_view_id=_create_temp_view(temp_wid,'+ftext +t','.process_command',false,VSBUFFLAG_THROW_AWAY_CHANGES);
      process_retrieve_id=temp_wid;
      activate_window(orig_view_id);
   }
}
static _str start_process2(boolean OpenInCurrentWindow ,boolean quiet,boolean uniconize,
                           _str location)
{
   if(isEclipsePlugin()) {
      return -1;
   }
   int formwid = 0;
   boolean display_toolbar=true;
   typeless status=0;
   if (!uniconize) {
      formwid = _tbIsActive("_tbshell_form");
      if( formwid==0 ) {
         display_toolbar=buf_match('.process',1,'hx')=='';
      }
   }
   typeless insert_window='';
   typeless wid=0;
   int oriBufId=0;
   if (location == 'T' && display_toolbar) {
      // Show the shell output tab:
      wid = toolShowShell();

      // If existing .process exists, reuse it:
      p_window_id=wid;
      oriBufId = p_buf_id;
      for (;p_buf_name != ".process";) {
         if (p_buf_name == ".process") {
            //say( "Found existing .process" );
            //bottom();
            break;
         }
         _next_buffer( "HR" );
         if (p_buf_id == oriBufId) break;
      }
   } else {
      wid=_find_tile('.process');
   }
   typeless mark='';
   if (wid) {
      p_window_id=wid;
   } else {
      insert_window='';
      if (location!='T') {
         if (!OpenInCurrentWindow && _no_child_windows()) {
            insert_window=' +i ';
         }
      }
      if (!p_window_id.p_mdi_child) {
         p_window_id=_mdi.p_child;
      }
      if ( pos('+bp',def_load_options,1,'i') ) {
         status=load_files(insert_window:+def_one_file' +q +bp +b .process');
      } else {
         status=load_files(insert_window:+def_one_file' +q +b .process');
      }
   }
   if ( ! status ) {
      if ( ! _process_info() ) {   /* have an exited .process buffer? */
         /* empty the file. */
         mark=_alloc_selection();
         if ( mark<0 ) {
            bottom();
         } else {
            top();_select_line(mark);bottom();_select_line(mark);
            _delete_selection(mark);
            _free_selection(mark);
            insert_line('');   /* Need at least one blank line for */
                               /* CONCUR_COMMAND procedure. */
         }
         p_modify=0;
      } else {
         //bottom();
         if (!quiet) {
            message(get_message(PROCESS_ALREADY_RUNNING_RC));
         }
         if (uniconize) {
            if (p_window_state=='I') {
               p_window_state="N";
            }
         }
         // IF mdi child
         if (location == 'B') {
            // Remove VSBUFFLAG_HIDDEN flag
            p_buf_flags = VSBUFFLAG_THROW_AWAY_CHANGES;
         }
         return(PROCESS_ALREADY_RUNNING_RC);
      }
   } else {
      clear_message();
      // Open build window in current window?
      if (OpenInCurrentWindow) {
         status=load_files('-u +t');
         if (!status) {
            _SetEditorLanguage();
         }
      }  else {
         status=edit('-u +t');
      }
      if ( status ) {
         return(1);
      }
   }
   name('.process',0); //p_buf_name='.process';
   docname('Build (.process)');
   toolShellConnectProcess();
   _SetEditorLanguage();
   set_env('SLKRUNS',1);

   _str line='';
   _str exepath='';
   if (!status) {
      exepath=editor_name('p');
      // This check is reasonably close enough
      if (!pos(substr(exepath,1,length(exepath)-1),get_env('PATH'))) {
         set_env('PATH',get_env('PATH') :+ PATHSEP :+ exepath);
      }
   }
#if __MACOSX__
   /* when a Mac application is NOT launched from a terminal window,
      the LANG environment variable is not set. Set it here since
      the secsh (or other shell) probably needs it.
   */
   if (get_env('LANG')=='') {
      set_env('LANG','en_US.UTF-8');
   }
#endif
   if (__WINDOWS__ || pos('.utf-8|.utf8',get_env('LANG'),1,'RI')) {
      if (def_build_allow_utf8_2) {
         p_UTF8=1;
         p_encoding=VSENCODING_UTF8;
         set_env('VSLICKBUILDALLOWUTF8',1);
      } else {
         p_UTF8=0;
         p_encoding=VSCP_ACTIVE_CODEPAGE;
         set_env('VSLICKBUILDALLOWUTF8',0);
      }
      int temp_wid,orig_wid;
      int status_pc=_open_temp_view('.process_command',temp_wid,orig_wid,'+b');
      if (!status_pc) {
         if (def_build_allow_utf8_2) {
            p_UTF8=1;
            p_encoding=VSENCODING_UTF8;
            set_env('VSLICKBUILDALLOWUTF8',1);
         } else {
            p_UTF8=0;
            p_encoding=VSCP_ACTIVE_CODEPAGE;
            set_env('VSLICKBUILDALLOWUTF8',0);
         }
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
      }
   }
#if __UNIX__
   replace_line('You can ignore shell warning messages.');
   insert_line('');
   insert_line('');
   status=concur_shell(_get_process_shell());
#else
   //p_UTF8=1;
   int temp_wid,pc_orig_wid;
   int status_pc=_open_temp_view('.process_command',temp_wid,pc_orig_wid,'+b');
   if (!status_pc) {
      //p_UTF8=1;
      _delete_temp_view(temp_wid);
      activate_window(pc_orig_wid);
   }
   if (_win32s()==2) { // IF running under windows 95?
      status=concur_shell('');
      for (;;) {
         if ( ! _process_info('R') ) {
            break;
         }
         get_line(line);
         if (line!='' || p_Noflines>1) {
            break;
         }
      }
      _mdi._set_foreground_window();
      //_post_call(find_index('_process_focus',PROC_TYPE));
   } else if (_win32s()==1) {
   } else if (machine()=='WINDOWS') {
      if (def_ntshell=='') {
         _str command=get_env('COMSPEC');
         if (!pos('cmd.exe',command,1,'i')) {
            command=path_search('cmd.exe','','P');
         }
         status=concur_shell(command' /q');
      } else {
         status=concur_shell(def_ntshell);
      }
   } else {
      status=concur_shell('');
   }
#endif
   set_env('SLKRUNS');
   // Remove VSBUFFLAG_HIDDEN flag
   p_buf_flags=VSBUFFLAG_THROW_AWAY_CHANGES;
   p_LCBufFlags&=~VSLCBUFFLAG_READWRITE;
   boolean SoftWrap=false;
   boolean SoftWrapOnWord=false;
   _SoftWrapGetSettings('process',SoftWrap,SoftWrapOnWord);
   p_SoftWrap=SoftWrap;
   p_SoftWrapOnWord=SoftWrapOnWord;
   if (location == 'T') {
      p_buf_flags= VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN;
   }
   if ( status ) {
      quit(false);
      return(status);
   }
   _create_process_retrieve_view();
   return(0);
}


/** 
 * Exits the build window by entering the "exit" command and 
 * waiting until the command processor finishes.
 * @categories Miscellaneous_Functions
 */
_command void exit_process(_str force='')
{
   if ( _process_info() ) {
      if (force!=1 && _isEditorCtl() && !_no_child_windows() && 
          _mdi.p_child.p_buf_name == ".process" &&
          _DialogViewingBuffer(_mdi.p_child.p_buf_id, _mdi.p_child)) {
         return;
      }
#if __UNIX__
      if ( _rsprocessbug() ) {
         return;
      }
#endif

      int orig_wid=p_window_id;
      int temp_view_id=0;
      int orig_view_id=0;
      int status=_open_temp_view('.process',temp_view_id,orig_view_id,'+b');
      if (!status) {

         _str command='exit';
         bottom();
         _str line="";
         get_line_raw(line);
         if ( _process_info('c') ) {
            line=expand_tabs(line,1,_process_info('c')-1,'S');
         } else {
            line='';
         }
         replace_line_raw(line:+command);
         insert_line("");

         int Noflines=p_Noflines;
         message(nls('Attempting to exit process. Hold down Ctrl+Shift+Alt+F2 to abort'));
         refresh();
         int NofTries=0;
         status=0;
         for (;;) {
            if ( ! _process_info('R') ) {
               break;
            }
            if (p_Noflines>Noflines || (p_Noflines==Noflines && p_col>1)) {
               if (NofTries<5) {
                  ++NofTries;
                  bottom();
                  line="";
                  get_line_raw(line);
                  if ( _process_info('c') ) {
                     line=expand_tabs(line,1,_process_info('c')-1,'S');
                  } else {
                     line='';
                  }
                  replace_line_raw(line:+command);
                  insert_line("");
                  Noflines=p_Noflines;
               } else {
                  _message_box('A program is still running in the build window.  You need to manually exit the program.');
                  status=1;
                  break;
               }
            }
         }
         _delete_temp_view(temp_view_id,0);
         p_window_id=orig_wid;
         clear_message();
         if (status) {
            stop();
         }
      }
   }

}

/** 
 * Changes the current working directory to the drive and path if given.  A current 
 * directory message is displayed.  This command will also change directory in the 
 * build window if a path is given.
 * 
 * @return  Returns 0 if successful.  Common error code is PATH_NOT_FOUND_RC.  This function 
 * can not detect an error which occurs while changing directory in the build window.
 * 
 * @see  cd
 * @see gui_cd
 * @see alias_cd
 * 
 * @categories File_Functions
 */
_command cdd(_str param="") name_info(FILE_ARG',')
{
   /* Change directory in build window. */
   _process_cd(param);
   typeless status=chdir(param,1);
   if (!status) {
      call_list('_cd_',param);
   }
   return(status);
}
#if __UNIX__

_str def_build_shell='%VSLICKBIN1%secsh -i';

/**
 * Default shell to use in the build window.
 * This setting is used on Solaris, AIX, and HPUX only.
 * 
 * @default "/bin/sh -i"
 * @category Configuration_Variables
 */
_str def_process_shell='/bin/sh -i';
/**
 * Default shell to use in the build window on Linux.
 * 
 * @default "/bin/tcsh -i"
 * @category Configuration_Variables
 */
_str def_linux1_shell='/bin/tcsh -i';
/**
 * Alternate shell to use in the build window on Linux.
 * This is only used if the def_linux1_shell does not exist.
 * 
 * @default "/bin/ksh -i"
 * @category Configuration_Variables
 */
_str def_linux2_shell='/bin/ksh -i';
/**
 * Default shell to use in the build window on the Mac OS X platform.
 * The default is tcsh which is needed for the Ctrl A character
 * to work with echo command.
 * 
 * @default "/bin/tcsh -i"
 * @category Configuration_Variables
 */
_str def_mac_shell='/bin/tcsh -i';

// these are obsolete (since BSD is no longer supported)
_str def_bsd1_shell='/bin/tcsh -i';  /* This BSD shell works in process buffer.*/
_str def_bsd2_shell='/bin/csh -i';   /* This BSD shell works in process buffer.*/


#endif
_str _get_process_shell(boolean returnDefaultSHELL=false)
{
#if __UNIX__
   _str filename="";
   if (def_build_shell!='') {
      return(_replace_envvars(def_build_shell));
   }
   if ( machine()=='HP9000' || machine()=='SPARCSOLARIS' || machine()=='INTELSOLARIS' ) {
      /* Unfortunately the C shell under SUN does not work in the build window */
      /* So the user is forced to define the def_process_shell variable. */
      return(def_process_shell);
   } else if (_isMac()) {
      return(def_mac_shell);
   } else if (machine()=='RS6000') {
      // Hard-code the shell used for AIX in case user has SHELL=bash, which
      // does not work well in process buffer.
      return(def_process_shell);
   } else if (machine()=='LINUX' ) {
      parse  def_linux1_shell with filename .;
      if (file_match('-p 'filename,1)!='') {
         return(def_linux1_shell);
      }
      parse def_linux2_shell with filename .;
      if (file_match('-p 'filename,1)!='') {
         return(def_linux2_shell);
      }
      // After trying def_linux1_shell and def_linux2_shell, fall through to /bin/sh.  
      // Need this for Ubuntu
      return('/bin/sh -i');
   } else if (machine()=='FREEBSD' ) {
      parse  def_bsd1_shell with filename .;
      if (file_match('-p 'filename,1)!='') {
         return(def_bsd1_shell);
      }
      parse def_bsd2_shell with filename .;
      if (file_match('-p 'filename,1)!='') {
         return(def_bsd2_shell);
      }
   }
   if (returnDefaultSHELL) {
      filename=get_env('SHELL');
      if (filename=='') {
         filename='/bin/sh';
      }
      return(filename);
   }
   return('');
#else
   if (_win32s()==1) {
      return def_wshell;
   } else if (machine()=='WINDOWS') {
      if (def_ntshell=='') {
         _str command=get_env('COMSPEC');
         if (!pos('cmd.exe',command,1,'i')) {
            command=path_search('cmd.exe','','P');
         }
         return command' /q';
      } else {
         return def_ntshell;
      }
   } 

   return '';
#endif
}
_str _srg_process_commands(_str option='',_str info='')
{
   int window_file_id=0;
   get_window_id(window_file_id);/* should be $window.slk */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   typeless Noflines=0;
   typeless line_number=0;
   typeless sprocess_first_retrieve=0;
   if ( (option=='R' || option=='N') ) {
      parse info with Noflines line_number sprocess_first_retrieve .;
      process_first_retrieve=sprocess_first_retrieve;
      down();_select_line(mark);
      down(Noflines-1);
      _select_line(mark);
      _create_process_retrieve_view();
      activate_window((int)process_retrieve_id);
      _lbclear();
      _copy_to_cursor(mark);
      //p_line=line_number;
      process_first_retrieve=true;
      bottom();
   } else if(process_retrieve_id!='') {
      int view_id=0;
      get_window_id(view_id);
      activate_window((int)process_retrieve_id);
      Noflines=p_Noflines;
      line_number=p_line;
      bottom();_end_line();
      activate_window((int)process_retrieve_id);
      top();
      //if (!_embedded_crlf()) {
         _select_line(mark);
         bottom();_select_line(mark);
         activate_window(window_file_id);
         insert_line('PROCESS_COMMANDS: 'Noflines " "line_number" "process_first_retrieve);
         /* **** */
         _copy_to_cursor(mark);
         _end_select(mark);
      //}
      activate_window((int)process_retrieve_id);
      p_line=line_number;
   }
   _free_selection(mark);
   activate_window(window_file_id);
   return(0);

}
