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
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "main.e"
#import "project.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbshell.e"
#import "tbterminal.e"
#import "toolbar.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twautohide.e"
#import "util.e"
#import "menu.e"
#import "cfg.e"
#import "setupext.e"
#import "seek.e"
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

#if 1 /* __NT__ */
   _str def_wshell='wshell';  /* Build window shell under windows. */
   _str def_ntshell;          /* Build window shell for Windows NT. */
#endif

bool def_build_allow_utf8_2;

_str _VslickErrorInfo(bool InsertEcho=true)
{
   VslickIncludePath := "";
   if (_project_name!='') {
      _ini_get_value(_project_name,"Compiler","includedirs",VslickIncludePath,'');
      VslickIncludePath=_absolute_includedirs(VslickIncludePath,_project_name);
      if (VslickIncludePath!='') {
         VslickIncludePath=PATHSEP:+_xlat_env(VslickIncludePath);
      }
   }
   Echo := "echo ";
   if (!InsertEcho) {
      Echo='';
   }
   return(Echo:+'VSLICKERRORPATH="'getcwd():+VslickIncludePath'"');
}

// This list gets looked at for automatically generated commands
// like project commands.
static const COMMAND_PROCESS_COMMANDS= 'ASSOC AT ATTRIB BREAK CACLS CALL CD CHCP CHDIR '\
                                   'CHKDSK CLS CMD COLOR COMP COMPACT CONVERT COPY '\
                                   'DATE DEL DIR DISKCOMP DISKCOPY DOSKEY ECHO '\
                                   'ENDLOCAL ERASE EXIT FC FIND FINDSTR FOR FORMAT '\
                                   'FTYPE GOTO GRAFTABL HELP IF KEYB LABEL MD MKDIR '\
                                   'MODE MORE MOVE PATH PAUSE POPD PRINT PROMPT PUSHD '\
                                   'RD RECOVER REM REN RENAME REPLACE RESTORE RMDIR '\
                                   'SET SETLOCAL SHIFT SORT START SUBST TIME TITLE '\
                                   'TREE TYPE VER VERIFY VOL XCOPY';


// This regular expression gets looked at when you press ENTER in the
// build window.
_str def_error_info_commands_re='^?*make?*$';

definit() {
   if (arg(1)=='L') {
      // This is not a good way to do this because this def var gets
      // reset every time this module is loaded. Since this is 
      // not an important option, thats' ok. Otherwise, this needs
      // to go in main.e and only get initialized once.
      if (_isWindows()) {
         def_build_allow_utf8_2=false;
      } else {
         def_build_allow_utf8_2=true;
      }
   }
}

/**
 * Determines if extra error search information is needed for error
 * processing.  This function only gets called for automatically generated
 * commands.  This function DOES NOT get called when the ENTER key is
 * pressed in the build window.
 *
 * @param cmd    Command string to be added to the build window.
 * @return Returns true if error search information is needded.
 */
bool _NeedVslickErrorInfo(_str cmd)
{
   cur := "";
   if (_isWindows()) {
      if (isalpha(substr(cmd,1,1)) && substr(cmd,2,1)==':') {
         rest := strip(substr(cmd,3));
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
   }
   temp := "";
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
bool _NeedVslickErrorInfo2(_str cmd)
{
   cur := "";
   temp := "";
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
_command concur_command(_str command="",bool leave_active=false,bool quiet=false,bool uniconize=true,bool addErrorInfo=true,_str idname='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (_process_is_interactive_idname(idname)) {
      quiet=true;
   }
   if (!_haveBuild()) {
      //popup_message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //command=arg(1);
   //quiet=arg(3);
   //leave_active=arg(2)!='' && arg(2);
   typeless found_tile=0;
   typeless orig_buf_id=0;
   orig_wid := 0;
   process_buffer_name:=_process_buffer_name(idname);
   if ( _process_info('b') || p_window_id==VSWID_HIDDEN || !p_HasBuffer) {
      orig_buf_id='';
   } else {
      orig_wid=p_window_id;
      orig_buf_id=p_buf_id;
      found_tile=_find_tile(process_buffer_name);
   }
   bool tab_output;
   _str form_name;
   if (idname=='') {
      tab_output=def_process_tab_output;
      form_name='_tbshell_form';
   } else if(_process_is_terminal_idname(idname)) {
      tab_output=def_terminal_tab_output;
      form_name='_tbterminal_form';
   } else if(_process_is_interactive_idname(idname)) {
      tab_output=def_interactive_tab_output;
      form_name='_tbinteractive_form';
   }
   typeless status=0;
   temp_view_id := 0;
   orig_view_id := 0;
   doDeleteTempView := false;
   if ((!uniconize && leave_active==false) && _process_info('',idname) && buf_match(process_buffer_name,1,'hx'):!='' && !_process_is_interactive_idname(idname)) {
      _open_temp_view(process_buffer_name,temp_view_id,orig_view_id,'+b');
      doDeleteTempView=true;
   } else {
      if (tab_output) {
         if( tw_maybe_auto_raise(form_name) > 0 ) {
            // The Build tool window will be auto shown. In order to prevent
            // it from auto hiding before the user has a chance to see the
            // output, we give it focus. All the user has to do is hit ESC
            // to hide it again.
            status = start_process_tab(false, true, quiet, uniconize,idname);
         } else {
            focus_wid := _get_focus();
            status=start_process_tab(false,false /* No focus changes. */,quiet,uniconize,idname);
            // Need this code so that Unix focus is set properly.
            // Do this for Windows too in order to hopefully potentially uncover a bug 
            // that would also occur on Unix.
            if (focus_wid) {
               focus_wid._set_focus();
            }
         }
      } else {
         status=start_process(false,false /* No focus changes. */,quiet,uniconize,idname);
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
   if (_process_is_interactive_idname(idname)) {
      if (last_char(command):!="\n") {
         strappend(command,"\n");
      }
      command=stranslate(command,"","\r");
      bottom();
      _insert_text(command);
      _process_info('R',idname);
   } else {
      if ( p_Noflines!=p_line ) {
         bottom();
      }

      line := "";
      col := 0;
      if ( _process_info('c') ) {
         col=_process_info('c');
      } else {
         line='';
         col=1;
      }
      p_col=col;
      _delete_text(-1);
      if (_isWindows()) {
         if (length(command)>ntGetMaxCommandLength()) {
            orig_view_id2 := 0;
            temp_view_id2 := 0;
            orig_view_id2=_create_temp_view(temp_view_id2);
            p_UTF8=false;  // vsexecfromfile does not support Unicode yet
            _str temp_name=mktemp();
            p_buf_name=temp_name;
            insert_line(command);
            status=_save_file('+o');
            _delete_temp_view(temp_view_id2);
            if (status) {
               _message_box(nls("Unable to write to '%s'",temp_name));
            }
            activate_window(orig_view_id2);
            command=_maybe_quote_filename(get_env('VSLICKBIN1'):+'vsexecfromfile')' -d ' _maybe_quote_filename(temp_name);
         }
      }
      if (addErrorInfo && _NeedVslickErrorInfo(command)) {
         _insert_text(_VslickErrorInfo()"\n"command"\n");
      }else{
         _insert_text(command"\n");
      }
   }
   //replace_line(line:+command);
   if ( (!leave_active || found_tile)&& orig_buf_id!='') {
      p_window_id=orig_wid;
      p_buf_id=orig_buf_id;
   } else {
      if (tab_output && p_active_form.p_name==form_name) {
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
   if (!_haveBuild()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(!target_wid || !target_wid._isEditorCtl(false)) {
      if (_process_info()) {
         return(MF_ENABLED);
      }
   } else {
      name=target_wid._ConcurProcessName();
      if (_process_info('',name)) {
         return(MF_ENABLED);
      }
   }
   return(MF_GRAYED);
}
int _OnUpdate_stop_build(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_stop_process(cmdui, target_wid, command);
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
_command void stop_build,stop_process() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      return;
   }
   if(isEclipsePlugin()) {
      return;
   }
   idname:=_ConcurProcessName();
   if (idname==null) {
      idname='';
   }
   _stop_process(idname);
   if (idname=='') {
      call_list("_cbstop_process_");
   }
}
_str no_concur_proc;

int _doStartProcess(bool OpenInCurrentWindow, bool doSetFocus, bool quiet, bool uniconize, _str outputTo, _str idname='')
{
   if (!_haveBuild()) {
      //popup_message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_focus := _get_focus();
   p_window_id=_edit_window();
   if ( pos(machine(),' 'no_concur_proc' ') ) {
      message(nls('Sorry.  No build window available for this operating system'));
      return(1);
   }
   old_buffer_name := "";
   typeless swold_pos=0;
   typeless swold_buf_id=0;
   buf_id := 0;
   typeless status=0;
   old_def_switchbuf_cd := def_switchbuf_cd;
   def_switchbuf_cd = false;
   if (p_window_id==VSWID_HIDDEN) {
      status=start_process2(OpenInCurrentWindow,quiet,uniconize,outputTo,idname);
   } else {
      set_switch_buffer_args(old_buffer_name,swold_pos,swold_buf_id);
      buf_id=p_buf_id;
      status=start_process2(OpenInCurrentWindow,quiet,uniconize,outputTo,idname);
      if ( p_buf_name!=old_buffer_name ) {
         switch_buffer(old_buffer_name,'',swold_pos,swold_buf_id);
      }
   }
   if (status==PROCESS_ALREADY_RUNNING_RC) {
      status=0;
   }
   if (!status) {
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
   }
   def_switchbuf_cd = old_def_switchbuf_cd;
   return(status);
}


int _OnUpdate_start_process(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_ENABLED);
   }
   idname:=target_wid._ConcurProcessName();
   if (idname==null || idname=='' || target_wid.p_mdi_child) {
      return(MF_ENABLED);
   }
   // Only want to remove this not so useful menu item for the Terminal
   // and and Interactive edit windows but not when they are MDI children.
   if (cmdui.menu_handle) {
      _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
      _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
      return MF_DELETED;
   }
   return(MF_ENABLED);
}
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
_command start_process(bool OpenInCurrentWindow=false,
                       bool doSetFocus=true,
                       bool quiet=false,
                       bool uniconize=true,
                       _str idname=''
                       ) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Build window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if(isEclipsePlugin()) {
      return -1;
   }
   bool tab_output;
   _str form_name;
   if (idname=='') {
      tab_output=def_process_tab_output;
      form_name='_tbshell_form';
   } else if(_process_is_terminal_idname(idname)) {
      tab_output=def_terminal_tab_output;
      form_name='_tbterminal_form';
   } else if(_process_is_interactive_idname(idname)) {
      tab_output=def_interactive_tab_output;
      form_name='_tbinteractive_form';
   }
   if (!p_mdi_child) {
      if (p_HasBuffer && !beginsWith(p_buf_name,'.process')) {
         if (p_active_form.p_modal || !tab_output) {
            return('');
         }
      }
   }
   //OpenInCurrentWindow=arg(1)!="";
   //doSetFocus=arg(2)=="";
   //quiet=arg(3)!="";
   //uniconize=arg(4)=="";

   outputTo := 'T';
   if (!tab_output) outputTo = 'B';

   int status=_doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,outputTo,idname);
   if (!status) {
      if (doSetFocus && outputTo=='T') {
         int formwid = tw_is_visible(form_name);
         if (formwid && !formwid.p_DockingArea) {
            formwid._set_foreground_window();
         }
      }
   }
   return(status);
}
_command int start_terminal_key() name_info(','VSARG2_LASTKEY|VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION|VSARG2_READ_ONLY)
{
   return start_process(false,true,false,true,_terminal_get_idname_from_key(last_event()));
}
_command start_process_window(bool OpenInCurrentWindow=false,
                       bool doSetFocus=true,
                       bool quiet=false,
                       bool uniconize=true,
                       _str idname='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   return(_doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,'B',idname));
}
_command start_process_tab(bool OpenInCurrentWindow=false,
                       bool doSetFocus=true,
                       bool quiet=false,
                       bool uniconize=true,
                       _str idname='')
{
   return(_doStartProcess(OpenInCurrentWindow,doSetFocus,quiet,uniconize,'T',idname));
}
_command restore_build_window() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_window_id := 0;
   orig_buf_id := 0;
   orig_buf_name := "";
   if (p_mdi_child) {
      if (p_HasBuffer && p_buf_name!=".process") {
         orig_window_id = p_window_id;
         orig_buf_id = p_buf_id;
         orig_buf_name = p_buf_name;
      }
   }
   outputTo := (def_process_tab_output)? "T":"B";
   status := _doStartProcess(false,false,true,false,outputTo);
   if (orig_buf_id != 0 && orig_window_id != 0 && orig_buf_name != "") {
      activate_window(orig_window_id);
      //edit("+bi "orig_buf_id);
      orig_window_id.edit("+Q +B "orig_buf_name);
   }
   return status;
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
_command void toggle_process_tab_output() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (p_buf_name=='.process') {
      if (!p_mdi_child) {
         start_process_window();
         if (p_LangId=='process') {
            bottom();_end_line();
         }
         def_process_tab_output=false;
      } else {
         start_process_tab();
         def_process_tab_output=true;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else {
      idname:=_ConcurProcessName();
      if (_process_is_terminal_idname(idname)) {
         if (!p_mdi_child) {
            start_process_window(false,true,false,true,idname);
            if (p_LangId=='process') {
               bottom();_end_line();
            }
            def_terminal_tab_output = false;
         } else {
            start_process_tab(false,true,false,true,idname);
            def_terminal_tab_output = true;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
      } else if (_process_is_interactive_idname(idname)) {
         def_interactive_tab_output = !def_interactive_tab_output;
         if (!p_mdi_child) {
            start_process_window(false,true,false,true,idname);
            if (p_LangId=='process') {
               bottom();_end_line();
            }
            def_interactive_tab_output= false;
         } else {
            start_process_tab(false,true,false,true,idname);
            def_interactive_tab_output= true;
         }
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
   }
}
int _OnUpdate_toggle_process_tab_output(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveBuild()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!target_wid || !target_wid._isEditorCtl(false) || target_wid.p_buf_name=='.process') {
      return (!def_process_tab_output)? MF_CHECKED|MF_ENABLED:MF_ENABLED;
   } 
   if(_process_is_terminal_idname(target_wid._ConcurProcessName())) {
      return (!def_terminal_tab_output)? MF_CHECKED|MF_ENABLED:MF_ENABLED;
   }
   return (!def_interactive_tab_output)? MF_CHECKED|MF_ENABLED:MF_ENABLED;
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
         wid := window_match(buf_name,1,'xn',-1,"vg,vm,va");
         return wid;
      }


      // Look for a tiled window already running process buffer.
      int tile_id=p_tile_id;
      wid := window_match(buf_name,1,'xn');
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
static bool _use_utf8_for_process_buffer() {
   return _isMac() || ((_isWindows() || pos('.utf-8|.utf8',get_env('LANG'),1,'RI')) && def_build_allow_utf8_2);
}
_str _process_retrieve_name(_str idname='') {
   if (idname=='' || idname==null) {
      return '.process_command';
   }
   return '.process_command-'idname;
}
int _process_retrieve_id(_str idname='') 
{
   int orig_wid = _find_or_create_temp_view(auto temp_wid,
                                            _use_utf8_for_process_buffer()?
                                            '+futf8 +t':
                                            '+ftext +t',
                                             _process_retrieve_name(idname), false, VSBUFFLAG_THROW_AWAY_CHANGES);
   activate_window(orig_wid);
   return temp_wid;
}
_str _process_buffer_name(_str idname) {
   if (idname!=null && idname!='') {
      return ".process-"idname;
   }
   return ".process";
}
bool _process_is_terminal_idname(_str idname) {
   return idname!=null && beginsWith(idname,'terminal_',false,_fpos_case);
}
bool _process_is_interactive_idname(_str idname) {
   return idname!=null && beginsWith(idname,'interactive_',false,_fpos_case);
}

#if 0 
bool _process_retrieve_on_enter(_str idname) {
   if (!_process_is_interactive_idname(idname)) {
      return false;
   }
   return true; def_interactive_send_input_on_enter;
}
#endif
/*bool _process_is_interactive(_str buf_name) {
   return beginsWith(buf_name,'.processs-interactive_',false,_fpos_case);
}
bool _process_is_terminal(_str buf_name) {
   return beginsWith(buf_name,'.processs-terminal_',false,_fpos_case);
} */
_str _terminal_get_idname_from_key(_str key) {
   //return 'terminal_'translate(event2name(key,'L'),'_','-');
   return 'terminal_'event2name(key,'L');
}
_str _interactive_get_idname(_str langid, _str profileName) {
   //return 'terminal_'translate(event2name(key,'L'),'_','-');
   return 'interactive_'langid'__'profileName;
}
_str _interactive_get_lang_from_idname(_str idname) {
   parse idname with 'interactive_' auto langid '__';
   return langid;
}
_str _interactive_get_profile_from_idname(_str idname) {
   parse idname with '__' auto profile;
   return profile;
}
_str _process_get_idname(_str buf_name) {
   if (buf_name=='.process') {
      return '';
   }
   parse buf_name with '.process-' auto idname;
   return idname;
}
void _terminal_list_idnames(_str (&array_idnames)[],bool list_running_only=false) {
   array_idnames._makeempty();
   buf_name:=buf_match('.process-terminal_',1,'h');
   while (buf_name!='') {
      idname:=_process_get_idname(buf_name);
      if (!list_running_only || _process_info('',idname)) {
         array_idnames[array_idnames._length()]=idname;
      }

      buf_name=buf_match('.process-terminal_',0,'h');
   }
}
void _interactive_list_idnames(_str (&array_idnames)[],bool list_running_only=false) {
   array_idnames._makeempty();
   buf_name:=buf_match('.process-interactive_',1,'h');
   while (buf_name!='') {
      idname:=_process_get_idname(buf_name);
      if (!list_running_only || _process_info('',idname)) {
         array_idnames[array_idnames._length()]=idname;
      }

      buf_name=buf_match('.process-interactive_',0,'h');
   }
}
void _terminal_list_bufids(int (&array_bufids)[]) {
   array_bufids._makeempty();
   parse buf_match('.process-terminal_',1,'hv') with auto buf_id .;
   while (buf_id!='') {
      array_bufids[array_bufids._length()]=(int)buf_id;
      parse buf_match('.process-terminal_',0,'hv') with buf_id .;
   }
}

_str _terminal_new_idname() {
   for (i:=0;i<1000;++i) {
      if (buf_match('.process-terminal_'i,1,'hx')=='') {
         break;
      }
   }
   return 'terminal_'i;
}
_str _terminal_idname_to_tab_name(_str idname) {
   parse idname with 'terminal_' idname;
   return 'Terminal (':+idname:+')';
}
_str _interactive_idname_to_tab_name(_str idname) {
   langid:=_interactive_get_lang_from_idname(idname);
   modeName:=_LangGetModeName(langid);
   profileName:=_interactive_get_profile_from_idname(idname);
   tab_name:=modeName;
   if (!strieq(modeName,profileName)) {
      tab_name=modeName' - 'profileName;
   }
   return tab_name;
}
static _str start_process2(bool OpenInCurrentWindow ,bool quiet,bool uniconize,
                           _str location,_str idname)
{
   if(isEclipsePlugin()) {
      return -1;
   }
   formwid := 0;
   display_toolbar := true;
   typeless status=0;
   process_buffer_name:=_process_buffer_name(idname);
   if (!uniconize) {
      if (_process_is_interactive_idname(idname)) {
         formwid = tw_is_current_form("_tbinteractive_form");
      } else if (_process_is_terminal_idname(idname)) {
         formwid = tw_is_current_form("_tbterminal_form");
      } else {
         formwid = tw_is_current_form("_tbshell_form");
      }
      if( formwid==0 ) {
         display_toolbar=buf_match(process_buffer_name,1,'hx')=='';
      }
   }
   typeless insert_window='';
   typeless wid=0;
   oriBufId := 0;
   if (location == 'T' && display_toolbar) {
      // Show the shell output tab:
      if (idname!='') {
         if (_process_is_terminal_idname(idname)) {
            wid=_toolShowTerminal(idname);
         } else {
            wid=_toolShowInteractive(idname);
         }
      } else { 
         wid = toolShowShell();
      }

      // If existing .process exists, reuse it:
      p_window_id=wid;
      oriBufId = p_buf_id;
      for (;p_buf_name!=process_buffer_name;) {
         if (p_buf_name == process_buffer_name) {
            //say( "Found existing .process" );
            //bottom();
            break;
         }
         _next_buffer( "HR" );
         if (p_buf_id == oriBufId) break;
      }
   } else {
      wid=_find_tile(process_buffer_name);
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
         status=load_files(insert_window:+def_one_file' +q +bp +b 'process_buffer_name);
      } else {
         status=load_files(insert_window:+def_one_file' +q +b 'process_buffer_name);
      }
   }
   if ( ! status ) {
      if ( ! _process_info('',idname) ) {   /* have an exited .process buffer? */
         /* empty the file. */
         mark=_alloc_selection();
         if ( mark<0 ) {
            bottom();
         } else {
            top();
            if (p_line!=0) {
               _select_line(mark);bottom();_select_line(mark);
               _delete_selection(mark);
            }
            _free_selection(mark);
            insert_line('');   /* Need at least one blank line for */
                               /* CONCUR_COMMAND procedure. */
         }
         p_modify=false;
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
            call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
            call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
         }
         return(PROCESS_ALREADY_RUNNING_RC);
      }
   } else {
      clear_message();
      // Open build window in current window?
      if (OpenInCurrentWindow) {
         status=load_files('+t');
         if (!status) {
            _SetEditorLanguage('process');
         }
      }  else {
         status=edit('+t');
      }
      if ( status ) {
         return(1);
      }
   }
   name(process_buffer_name,false);
   if (idname=='') {
      docname('Build (.process)');
      toolShellConnectProcess();
   } else if (_process_is_interactive_idname(idname)) {
      docname(_interactive_idname_to_tab_name(idname));
   } else {
      docname(_terminal_idname_to_tab_name(idname));
   }
   if (_process_is_interactive_idname(idname)) {
      langid:=_interactive_get_lang_from_idname(idname);
      _str szEventTableName=_LangGetProperty('process',VSLANGPROPNAME_EVENTTAB_NAME);
      int index=0;
      if (szEventTableName!="") index=_eventtab_get_mode_keys(szEventTableName);
      _SetEditorLanguage(langid);
      p_mode_eventtab=index;
      //p_LangId='process';
   } else {
      _SetEditorLanguage("process");
   }
   set_env('SLKRUNS',1);

   line := "";
   exepath := "";
   if (!status) {
      exepath=editor_name('p');
      // This check is reasonably close enough
      if (!pos(substr(exepath,1,length(exepath)-1),get_env('PATH'))) {
         set_env('PATH',get_env('PATH') :+ PATHSEP :+ exepath);
      }
   }
   if (_isMac()) {
      /* when a Mac application is NOT launched from a terminal window,
         the LANG environment variable is not set. Set it here since
         the secsh (or other shell) probably needs it.
      */
      if (get_env('LANG')=='') {
         set_env('LANG','en_US.UTF-8');
      }
   }
   if (_isWindows() || pos('.utf-8|.utf8',get_env('LANG'),1,'RI')) {
      if (def_build_allow_utf8_2) {
         p_UTF8=true;
         p_encoding=VSENCODING_UTF8;
         set_env('VSLICKBUILDALLOWUTF8',1);
      } else {
         p_UTF8=false;
         p_encoding=VSCP_ACTIVE_CODEPAGE;
         set_env('VSLICKBUILDALLOWUTF8',0);
      }
   }
   if (_process_is_interactive_idname(idname)) {
      langid:=_interactive_get_lang_from_idname(idname);
      profileName:=_interactive_get_profile_from_idname(idname);
      command:=_plugin_get_property(vsCfgPackage_for_LangInteractiveProfiles(langid),profileName,'command');
      command=_replace_envvars(command);
      typeless supty;
      supty=_plugin_get_property(vsCfgPackage_for_LangInteractiveProfiles(langid),profileName,'use_pty',-1);
      if (!isinteger(supty)) supty=-1;
      temp:=command;
      pgm_name:=parse_file(temp,false);
      if(path_search(pgm_name,'PATH','P')=='') {
         orig_wid:=p_window_id;
         _message_box(nls("External program '%s' not found in PATH. Install the program or configure the path",pgm_name));
         setupext('-interactiveprofiles 'langid);
         p_window_id=orig_wid;
         status=FILE_NOT_FOUND_RC;
         message(get_message(status));
      } else {
         field_width:=21;
         ctrl_enter:='';
         if (name_on_key(name2event('C-ENTER'))=='nosplit-insert-line') {
            ctrl_enter='  Ctrl+Enter';
            ctrl_enter=substr(ctrl_enter,1,field_width)"No split insert line\n";
         }
         shift_enter:='';
         if (name_on_key(name2event('S-ENTER'))=='keyin-enter'  || name_on_key(name2event('S-ENTER'))=='split-insert-line') {
            shift_enter='  Shift+Enter';
            shift_enter=substr(shift_enter,1,field_width)"Split insert line\n";
         }
         ctrl_a:='';
         if (name_on_key(ENTER)=='select-all') {
            ctrl_a='  Ctrl+A';
            ctrl_a=substr(ctrl_a,1,field_width)"If no selection and within current submission, select submission\n":+
            substr('',1,field_width):+"Otherwise, select entire file.\n";
         }
         etab_index:=eventtab_index(_default_keys,p_mode_eventtab,event2index(name2event('C-;')));
         ctrl_semi_f:='';
         ctrl_semi_c:='';
         ctrl_semi_r:='';
         if (etab_index>0 && name_type(etab_index)==EVENTTAB_TYPE) {
            if(name_name(eventtab_index(etab_index,etab_index,event2index(name2event('f')))):=='interactive-load-file') {
               ctrl_semi_f="  Ctrl+; f";
               ctrl_semi_f=substr(ctrl_semi_f,1,field_width)"Load a file you choose\n";
            }
            if(name_name(eventtab_index(etab_index,etab_index,event2index(name2event('c')))):=='clear-pbuffer') {
               ctrl_semi_c="  Ctrl+; c";
               ctrl_semi_c=substr(ctrl_semi_c,1,field_width)"Clear window\n";
            }
            if(name_name(eventtab_index(etab_index,etab_index,event2index(name2event('r')))):=='restart-process') {
               ctrl_semi_r="  Ctrl+; r";
               ctrl_semi_r=substr(ctrl_semi_r,1,field_width)"Restart\n";
            }
         }
         ctrl_alt_enter:='';
         if (_isMac()) {
            if (name_on_key(name2event('C-M-ENTER'))=='interactive-load-selection') {
               ctrl_alt_enter="  Ctrl+Comand+Enter";
               ctrl_alt_enter=substr(ctrl_alt_enter,1,field_width)"Load selected code or current line in interactive window\n";
            }
         } else {
            if (name_on_key(name2event('C-A-ENTER'))=='interactive-load-selection') {
               ctrl_alt_enter="  Ctrl+Alt+Enter";
               ctrl_alt_enter=substr(ctrl_alt_enter,1,field_width)"Load selected code or current line in interactive window\n";
            }
         }
         ctrl_semi_f_global:='';
         etab_index=eventtab_index(_default_keys,_default_keys,event2index(name2event('C-;')));
         if (name_on_key(name2event('S-ENTER'))=='keyin-enter'  || name_on_key(name2event('S-ENTER'))=='split-insert-line') {
            if(etab_index && name_type(etab_index)==EVENTTAB_TYPE &&
               name_name(eventtab_index(etab_index,etab_index,event2index(name2event('f')))):=='interactive-load-file') {
               ctrl_semi_f_global="  Ctrl+; f";
               ctrl_semi_f_global=substr(ctrl_semi_f_global,1,field_width)"Load current file in interactive window\n";
            }
         }
         ctrl_c:='';
         if (name_on_key(C_C)=='stop-process') {
            ctrl_c='  Ctrl+C';
            ctrl_c=substr(ctrl_c,1,field_width)"Terminate shell (send Ctrl+C signal). Supported by some interactive shells.\n";
         }

         _insert_text("":+
         "Interactive editor window\n":+
         substr("  Enter",1,field_width)"Within current submission, send submission.\n":+
         substr("",1,field_width)"Otherwise, invoke default Enter key definition (split-insert-line).\n":+
         ctrl_enter:+
         shift_enter:+
         substr("  UpArrow",1,field_width)"Within current submission, retrieves previous submission\n":+
         substr("  DownArrow",1,field_width)"Within current submission, retrieves next submission\n":+
         ctrl_a:+
         ctrl_semi_f:+
         ctrl_semi_c:+
         ctrl_semi_r:+
         ctrl_c:+
         "Any editor window\n":+
         ctrl_alt_enter:+
         ctrl_semi_f_global:+
         "\n");
         _StreamMarkerAdd(0,0,_nrseek(),false,0,_InteractiveOutputMarkerType(),'');
         if (_isWindows()) {
            status=concur_shell(command,idname,supty);
         } else {
            // Need to run secsh to allow Ctrl+C signal to exit some interactive shells
            status=concur_shell(_maybe_quote_filename(get_env("VSLICKBIN1"):+'secsh')' -c 'command,idname,supty);
         }
      }
   } else if (_isUnix()) {
      status=concur_shell(_get_process_shell(),idname);
   } else {
      //p_UTF8=1;
      int temp_wid,pc_orig_wid;
      int status_pc=_open_temp_view(_process_retrieve_name(idname),temp_wid,pc_orig_wid,'+b');
      if (!status_pc) {
         //p_UTF8=1;
         _delete_temp_view(temp_wid);
         activate_window(pc_orig_wid);
      }
      if (_win32s()==2) { // IF running under windows 95?
         status=concur_shell('',idname);
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
         orig_prompt:=get_env('PROMPT');
         if (pos('$E',orig_prompt)) {
            set_env('PROMPT',"$P$G");
         }
         if (def_ntshell=='') {
            command := get_env('COMSPEC');
            if (!pos('cmd.exe',command,1,'i')) {
               command=path_search('cmd.exe','','P');
            }
            status=concur_shell(command' /q',idname);
         } else {
            status=concur_shell(def_ntshell,idname);
         }
         if (orig_prompt!='') {
            set_env('PROMPT',orig_prompt);
         }
      } else {
         status=concur_shell('',idname);
      }
   }
   if (_process_is_interactive_idname(idname)) {
      langid:=_interactive_get_lang_from_idname(idname);
      if (langid!='') {
         lexer_name:=_LangGetProperty(langid,VSLANGPROPNAME_LEXER_NAME);
         if (lexer_name!='') {
            p_lexer_name=lexer_name;
            if (p_lexer_name!="") {
               p_color_flags|=LANGUAGE_COLOR_FLAG;
            }
         }
      }
      p_interactive_wid=1;
      _process_info('E',idname,true /*def_interactive_send_input_on_enter*/);
   }
   set_env('SLKRUNS');
   // Remove VSBUFFLAG_HIDDEN flag
   p_buf_flags=VSBUFFLAG_THROW_AWAY_CHANGES;
   p_LCBufFlags&=~VSLCBUFFLAG_READWRITE;
   SoftWrap := false;
   SoftWrapOnWord := false;
   _SoftWrapGetSettings('process',SoftWrap,SoftWrapOnWord);
   p_SoftWrap=SoftWrap;
   p_SoftWrapOnWord=SoftWrapOnWord;
   if (location == 'T') {
      p_buf_flags= VSBUFFLAG_THROW_AWAY_CHANGES|VSBUFFLAG_HIDDEN;
   } else if (location == 'B') {
      call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
   }
   if ( status ) {
      quit(false);
      return(status);
   }
   return(0);
}


/** 
 * Exits the build window by entering the "exit" command and 
 * waiting until the command processor finishes.
 * @categories Miscellaneous_Functions
 */
_command void exit_process(_str force='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      return;
   }
   if ( _process_info() ) {
      if (force!=1 && _isEditorCtl() && !_no_child_windows() && 
          beginsWith(_mdi.p_child.p_buf_name,".process") 
          // When invoking commands like close_others and close_all, its best
          // to just hide the .process buffer.
          /*&& _DialogViewingBuffer(_mdi.p_child.p_buf_id, _mdi.p_child)*/) {
         return;
      }
      if (_isUnix()) {
         if ( _rsprocessbug() ) {
            return;
         }
      }

      orig_wid := p_window_id;
      temp_view_id := 0;
      orig_view_id := 0;
      int status=_open_temp_view('.process',temp_view_id,orig_view_id,'+b');
      if (!status) {

         command := "exit";
         bottom();
         line := "";
         get_line_raw(line);
         if ( _process_info('c') ) {
            line=expand_tabs(line,1,_process_info('c')-1,'S');
         } else {
            line='';
         }
         replace_line_raw(line:+command);
         insert_line("");

         Noflines := p_Noflines;
         typeless start_time=_time('b');
         //message(nls('Attempting to exit process. Hold down Ctrl+Shift+Alt+F2 to abort'));
         refresh();
         NofTries := 0;
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
               /*} else {
                  result:=_message_box("A program is still running in the build window\n\nForce terminate?",'',MB_YESNO);
                  if (result==IDYES) {
                     _process_info('Q');
                  } else {
                     status=1;
                     break;
                  }*/
               }
            }
            if ((typeless)_time('b')-start_time>5000) {
               start_time=_time('b');
               result:=_message_box("A program is still running in the build window\n\nForce terminate?",'',MB_YESNO);
               if (result==IDYES) {
                  _process_info('Q');
               } else {
                  status=1;
                  break;
               }
            }
         }
         _delete_temp_view(temp_view_id,false);
         p_window_id=orig_wid;
         clear_message();
         if (status) {
            stop();
         }
      }
   }

}
int _OnUpdate_exit_process(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_stop_process(cmdui, target_wid, command);
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
#if 1 /*__UNIX__ */

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
 * Default shell to use in the build window on the macOS 
 * platform. The default is tcsh which is needed for the Ctrl A 
 * character to work with echo command. 
 * 
 * @default "/bin/tcsh -i"
 * @category Configuration_Variables
 */
_str def_mac_shell='/bin/tcsh -i';

// these are obsolete (since BSD is no longer supported)
_str def_bsd1_shell='/bin/tcsh -i';  /* This BSD shell works in process buffer.*/
_str def_bsd2_shell='/bin/csh -i';   /* This BSD shell works in process buffer.*/
#endif

_str _get_process_shell(bool returnDefaultSHELL=false)
{
   if (_isUnix()) {
      filename := "";
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
      } else if (_isLinux()) {
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
   }
   if (_win32s()==1) {
      return def_wshell;
   } else if (machine()=='WINDOWS') {
      if (def_ntshell=='') {
         command := get_env('COMSPEC');
         if (!pos('cmd.exe',command,1,'i')) {
            command=path_search('cmd.exe','','P');
         }
         return command' /q';
      } else {
         return def_ntshell;
      }
   } 

   return '';
}
_str _srg_process_commands(_str option='',_str info='')
{
   window_file_id := 0;
   get_window_id(window_file_id);/* should be $window.slk */
   typeless mark=_alloc_selection();
   if ( mark<0 ) {
      return(mark);
   }
   typeless Noflines=0;
   typeless line_number=0;
   if ( (option=='R' || option=='N') ) {
      parse info with Noflines line_number . auto idname;
      down();_select_line(mark);
      down(Noflines-1);
      _select_line(mark);
      activate_window((int)_process_retrieve_id(idname));
      _lbclear();
      _copy_to_cursor(mark);
      //p_line=line_number;
      bottom();
   } else if(buf_match('.process_command',1,'h')!='') {
      buf_name:=buf_match('.process_command',1,'h');
      while (buf_name!='') {
         parse buf_name with '.process_command-' auto idname;
         process_retrieve_id:=_process_retrieve_id(idname);
         activate_window((int)process_retrieve_id);
         Noflines=p_Noflines;
         line_number=p_line;
         bottom();_end_line();
         activate_window((int)process_retrieve_id);
         top();
         
         _deselect(mark);
         _select_line(mark);
         bottom();_select_line(mark);
         activate_window(window_file_id);
         insert_line('PROCESS_COMMANDS: 'Noflines " "line_number" 0 "idname);
         /* **** */
         _copy_to_cursor(mark);
         _end_select(mark);
         
         activate_window((int)process_retrieve_id);
         p_line=line_number;
         buf_name=buf_match('.process_command',0,'h');
      }
   }
   activate_window(window_file_id);
   _free_selection(mark);
   return(0);

}
