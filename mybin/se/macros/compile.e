////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50675 $
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
#include "debug.sh"
#include "tagsdb.sh"
#include "project.sh"
#include "refactor.sh"
#include "vsockapi.sh"
#include "xml.sh"
#import "debug.e"
#import "debuggui.e"
#import "debugpkg.e"
#import "dir.e"
#import "doscmds.e"
#import "eclipse.e"
#import "env.e"
#import "error.e"
#import "fileman.e"
#import "files.e"
#import "forall.e"
#import "gnucopts.e"
#import "gwt.e"
#import "html.e"
#import "javaopts.e"
#import "listbox.e"
#import "main.e"
#import "menu.e"
#import "makefile.e"
#import "math.e"
#import "last.e"
#import "os2cmds.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "util.e"
#import "window.e"
#import "wkspace.e"
#import "xcode.e"
#import "applet.e"
#import "mprompt.e"
#import "vstudiosln.e"
#endregion

#define COMMAND_FILE '$compile.tmp'
#define PARSE_CHAR '%'

#define OVERRIDE_CLEAR_PBUFFER 0x1
#define OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER 0x2
#define OVERRIDE_DOCAPTUREOUTPUTWITH_REDIRECTION 0x4

static void AddVSBuildToCommandLine(_str &compile_command,_str makecommand, boolean verbose,boolean beep,_str buf_name="");

_str def_process=1;        // Leave process buffer active when exec commands.
_str def_save_on_compile='1 0';//0=no save, 1=save current file, 2=save all files
                               //compile make

/**
 * Clears the contents of the build window (".process").
 *
 * @see start_process
 * @see stop_process
 * @see cursor_error
 * @see exit_process
 * @see set_next_error
 * @see reset_next_error
 * @see next_error
 *
 *
 * @categories Miscellaneous_Functions
 */
_command void clear_pbuffer() name_info(','VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   int status;
   int temp_view_id,orig_view_id;
   status=_open_temp_view('.process',temp_view_id,orig_view_id,'+b');
   if (!status) {
      _lbclear();
      set_next_error();
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
}

int _OnUpdate_project_compile(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * <p>Executes a user defined compile command.    The compile command
 * may be specified per project or per file extension.  Parts of the buffer
 * name may be parsed into the compile command before it is executed.
 *
 * Use the <b>new</b> command ("Project", "New...") to create a new
 * workspace or project.  Once a project is open, you can use the Tools
 * Tab ("Project", "Project Properties...", select Tools Tab) to modify
 * project commands, files, and other project setup information.  If the
 * current project has a compile command defined, the extension specific
 * project compile command will be ignored.</p>
 *
 * <p>The compile command is executed in SlickEdit's build window by default.
 *
 * @return Returns 0 if command queued successfully.  However, this does not
 * mean that the command will execute successfully.  A non-zero return
 * code means that the build window was not created.
 * Common error codes are: TOO_MANY_SELECTIONS_RC,
 * TOO_MANY_FILES_RC, CANT_FIND_INIT_PROGRAM_RC,
 * ERROR_CREATING_SEMAPHORE_RC,
 * TOO_MANY_OPEN_FILES_RC, NOT_ENOUGH_MEMORY_RC,
 * ERROR_CREATING_QUEUE_RC,
 * INSUFFICIENT_MEMORY_RC, and
 * ERROR_CREATING_THREAD_RC. On error, message is displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Buffer_Functions, Project_Functions
 *
 */
_command int project_compile(_str buf_name="")
{
   if (isEclipsePlugin()) {
      return 0;
   }
   _str word='';
   if ( buf_name != '') {
      buf_name= absolute(buf_name);
   } else {
      if (_isEditorCtl()) {
         buf_name=p_buf_name;
         int junk;
         word=cur_word(junk);
      } else {
         buf_name='';
      }
   }
   int status=0;
   _str ext=_get_extension(buf_name);
   if ( file_eq('.'ext,_macro_ext) ) {
      if ( _need_to_save2(buf_name,1)) {
         status=_save_non_active(buf_name);
         if ( status ) {
            return(status);
         }
      }
      status=st(buf_name);
      return(status);
   }

   // are we in debug mode and trying to do edit and continue?
   int ActionOverrideFlags=0;
   _str debugReloadCmd='';
   if (debug_active() && debug_is_hotswap_enabled()) {
      debugReloadCmd='reload';
      ActionOverrideFlags=OVERRIDE_DOCAPTUREOUTPUTWITH_REDIRECTION|OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER;
      debug_set_compile_time();
   }

   _str projName = _WorkspaceFindProjectWithFile(buf_name,              // _str filename
                                                 _workspace_filename,   // _str workspaceName = _workspace_filename
                                                 true,                  // boolean isAbsolute = false
                                                 true);                 // boolean quiet = false

   boolean swapping_project=false;
   _str oldProjName=_project_name;
   if ( (projName:!='') && (projName:!=oldProjName)) {
      workspace_set_active(projName,true,false,false);
      swapping_project=true;
   }

   // pass the compile rule to _project_command to be executed
   status=_project_command('compile', buf_name, word,
                           false,true,ActionOverrideFlags,false,debugReloadCmd);

   if (swapping_project) {
      // switch project back
      workspace_set_active(oldProjName,true,false,false);
   }
   return(status);
}

/**
 * Get the run from directory for running the project command
 *
 * @param handle     Handle to the project
 * @param TargetNode Node index for the current target
 * @param filename   Filename of the file that is being compiled (optional)
 */
static _str getRunFromDirectory(int handle,int TargetNode,_str filename = "")
{
   _str runFromDir = _ProjectGet_TargetRunFromDir(handle, TargetNode);
   if (runFromDir == "") return "";

   // parse the dir for %placeholders
   runFromDir = _parse_project_command(runFromDir, filename, _project_name, "");
   if (runFromDir == "") return "";

   return absolute(runFromDir,_strip_filename(_project_name,'N'));
}
/**
 * Change to the proper directory before running the project command
 *
 * @param handle     Handle to the project
 * @param TargetNode Node index for the current target
 * @param filename   Filename of the file that is being compiled (optional)
 */
static void _cdb4compile(int handle,int TargetNode,_str filename = "")
{
   // IF we are running under WINDOWS 3.1 OR running under OS/2
   if (_win32s()==1 /*|| _project_name==""*/) return;

   _str runFromDir = _ProjectGet_TargetRunFromDir(handle, TargetNode);
   if (runFromDir == "") return;

   // parse the dir for %placeholders
   runFromDir = _parse_project_command(runFromDir, filename, _project_name, "");
   if (runFromDir == "") return;

   _str dir=absolute(runFromDir,_strip_filename(_project_name,'N'));
   if (!file_eq(getcwd(),dir)) {
      if (
         strieq(_ProjectGet_TargetCaptureOutputWith(handle,TargetNode),VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER)
         ) {
         cd(maybe_quote_filename(dir),true);
      } else {
         // Don't change directory in process buffer since this command is not going there
         int orig_def_cd=def_cd;
         def_cd &= ~CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW;
         cd(maybe_quote_filename(dir),true);
         def_cd=orig_def_cd;
      }
   }
}
int _OnUpdate_project_make(CMDUI &cmdui,int target_wid,_str command)
{
   _str params='';
   parse command with . params;
   command='project_build 'params;
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
int _OnUpdate_project_build(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}

static _str RecurseTable:[];
static boolean alreadyUsing_vsbuild(_str compile_command)
{
   _str temp=_replace_envvars2(compile_command);
   _str pgmname=_strip_filename(parse_file(temp,false),'PE');
   return(file_eq(pgmname,'vsbuild'));
}

static boolean using_ant(_str command)
{
   _str temp=_replace_envvars2(command);
   _str pgmname=_strip_filename(parse_file(temp,false),'PE');
   if (file_eq(pgmname,'ant') || file_eq(pgmname, "antmake") ||
       file_eq(pgmname,"ant-target-form") || file_eq(pgmname, "ant-execute-target")) {
      return true;
   }
   return false;
}

boolean _DebugMaybeTerminate()
{
   if (_tbDebugQMode()) {
      //_on_slickc_error(0,'');
      int result=_message_box('This command will stop the current debug session.','',MB_OKCANCEL);
      if (result==IDCANCEL) {
         //result=_message_box('Do you want to stop debugging?','',MB_YESNOCANCEL);
         //if (result!=IDYES) {
         return(true);
      }
      debug_stop();
   }
   return(false);
}
///////////////////////////////////////////////////////////////////////////////////////
//AccumulateErrors - if redirecting errors, appends to the file rather than overwriting
//                   if not redirecting errors, no effect
//
//AutoNextError - if redirecting errors, automatically go to first error
//                if not redirecting errors, no effect
static _str BuiltTable:[]=null;
/**
 * <p>All of the compiling from within the editor commands may be
 * accessed from the Project menu.  Be sure to try the
 * <b>Build > Show Build</b> menu item.</p>
 *
 * <p>SlickEdit provides the commands <b>project_compile</b> and
 * <b>project_build</b> for compiling.  The <b>project_compile</b>
 * command (Shift+F10 or <b>Build > Compile</b>) compiles the current
 * buffer based on a compile command you specify.  Alternately, the
 * <b>project_build</b> command (Ctrl+M or <b>Build > Build</b>) executes a
 * build command you specify.  Both of these commands may be specified per 
 * project or per file extension.  Before you can execute the build or 
 * compile commands you must set the current project or define an 
 * extension-based project.  To define an extension-based project command, 
 * use the <b>Extension Options dialog box</b> (<b>Tools > Options > File 
 * Extension Setup</b>, select the Advanced tab) select the extension and 
 * press the Extension Specific Project button.   You will probably want 
 * your build command based on the current project and not the current 
 * extension. Use the <b>workspace_new</b> command (<b>Project > New...</b>) 
 * to create a new workspace or project.  Once a project is open, you can 
 * use the Tools Tab (<b>Project > Project Properties...</b>, select Tools 
 * Tab) to modify project commands, files, and other project setup 
 * information. If the current project has a compile command defined, the 
 * extension-specific project compile command will be ignored.</p> 
 *
 * <p>By default, the compile or build command is executed in SlickEdit's
 * build window.  This allows you to continue editing while your compiler 
 * runs.  You can process the error messages as they appear in the 
 * ".process" build window instead of waiting until the compile(s) finish. 
 * The <b>stop_process</b> command (<b>Build > Stop Build</b>) may be used to
 * send a control break signal to stop your compiler or program 
 * running in the build window.</p>
 *
 * <p>Execute the <b>next_error</b> command (Ctrl+Shift+Down,  or <b>Build >
 * Next Error</b>) to place your cursor on the line of the file containing 
 * the next error.  Click on the Build Tab of the Output toolbar (docked on 
 * the bottom by default) or open the Build tool window (<b>View > 
 * Toolbars > Build</b>) to view all your compilers error messages.  You may 
 * use the <b>cursor_error</b> command (Alt+1, Double-click or <b>Build > Go
 * to Error/Include</b>) to set the next error starting search position and 
 * go to a specific error.</p> 
 *
 * <p>The <b>cursor_error</b>, <b>next_error</b>, and <b>prev_error</b>
 * commands may also be used to process messages from the <b>sgrep</b> 
 * program we provide.  For example, activate the build window (<b>"Build > 
 * Show Build</b>) and type "<b>sgrep main *.c</b>" and press enter.  You 
 * may now press Ctrl+Shift+Down to cursor through the located occurrences. 
 * Press the PgUp key to move the cursor off the build window prompt so you 
 * may use the <b>cursor_error</b> command (Alt+1 or Double-click) on a 
 * specific occurrence.</p> 
 *
 * <p>The <b>reset_next_error</b> command sets the invisible bookmark of the 
 * <b>next_error</b> command to the end of the build window buffer so that 
 * no error messages will be found.</p> 
 *
 * @return Returns 0 if command queued successfully.  However, this does not
 * mean that the command will execute successfully.  A non-zero return
 * code means that the build window was not created.
 * Common error codes are: TOO_MANY_SELECTIONS_RC,
 * TOO_MANY_FILES_RC, CANT_FIND_INIT_PROGRAM_RC,
 * ERROR_CREATING_SEMAPHORE_RC,
 * TOO_MANY_OPEN_FILES_RC, NOT_ENOUGH_MEMORY_RC,
 * ERROR_CREATING_QUEUE_RC,
 * INSUFFICIENT_MEMORY_RC, and
 * ERROR_CREATING_THREAD_RC. On error, message is displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command int project_make,project_build(_str cmdname='build',
                                        boolean AccumulateErrors=false,
                                        boolean AutoNextError=true,
                                        int OverrideFlags=0,
                                        _str buf_name=""
                                       ) name_info(','VSARG2_EDITORCTL)
{
   if(isEclipsePlugin()) {
      _eclipse_project_build();
      return(0);
   }
   // are we in debug mode and trying to do edit and continue?
   // allow it only if they are doing an incremental build.
   _str debugReloadCmd='';
   if (cmdname=='build' && debug_active() && debug_is_hotswap_enabled()) {
      debugReloadCmd='reload';
      OverrideFlags=OVERRIDE_DOCAPTUREOUTPUTWITH_REDIRECTION|OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER;
      debug_set_compile_time();
   }
   if (debugReloadCmd=='' && _DebugMaybeTerminate()) {
      return(1);
   }
   _str FirstName='';
   return(_project_command2(cmdname,AccumulateErrors,AutoNextError,OverrideFlags,false,debugReloadCmd,buf_name));
}
int _OnUpdate_project_rebuild(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * <p>Executes a user defined rebuild command.    The rebuild command
 * may be specified per project or per file extension.  Parts of the buffer
 * name may be parsed into the compile command before it is executed.
 * Use the <b>new</b> command ("Project", "New...") to create a
 * new workspace or project.  Once a project is open, you can
 * use the Tools Tab ("Project", "Project Properties...", select
 * Tools Tab) to modify project commands, files, and other
 * project setup information.  If the current project has a
 * compile command defined, the extension specific
 * project compile command will be ignored.</p>
 *
 * <p>The rebuild command is executed in SlickEdit's build window by default.
 *
 * @return Returns 0 if command queued successfully.  However, this does not
 * mean that the command will execute successfully.  A non-zero return
 * code means that the build window was not created.
 * Common error codes are: TOO_MANY_SELECTIONS_RC,
 * TOO_MANY_FILES_RC, CANT_FIND_INIT_PROGRAM_RC,
 * ERROR_CREATING_SEMAPHORE_RC,
 * TOO_MANY_OPEN_FILES_RC, NOT_ENOUGH_MEMORY_RC,
 * ERROR_CREATING_QUEUE_RC,
 * INSUFFICIENT_MEMORY_RC, and
 * ERROR_CREATING_THREAD_RC. On error, message is displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command project_rebuild() name_info(','VSARG2_EDITORCTL)
{
   return(project_make('rebuild'));
}
int _OnUpdate_project_clean(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
_command project_clean() name_info(','VSARG2_EDITORCTL)
{
   if (isEclipsePlugin()) {
      _eclipse_project_clean();
      return(0);
   }
   // pass the clean rule to _project_command to be executed
   int status = _project_command2("clean");
   return(status);
}
int _OnUpdate_project_user1(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * Executes a user defined command.    The command may be specified
 * per project or per file extension.  Parts of the buffer name may be
 * parsed into the command before it is executed.  Use the
 * <b>new</b> command ("Project", "New...") to create a new
 * workspace or project.  Once a project is open, you can use
 * the Tools Tab ("Project", "Project Properties...", select
 * Tools Tab) to modify project commands, files, and other
 * project setup information.  If the current project has a
 * rebuild command defined, the extension specific project
 * compile command will be ignored.
 *
 * @return Returns 0 if command queued successfully.  On error, message is
 * displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command project_user1() name_info(','VSARG2_EDITORCTL)
{/* was rebuild */
   return(_project_command2("user 1"));
}
int _OnUpdate_project_debug(CMDUI &cmdui,int target_wid,_str command)
{
   if (isEclipsePlugin()) {
      return MF_ENABLED;
   }
   /*if ( !target_wid || !target_wid._isEditorCtl()) {
      enabled=MF_GRAYED;
   } */
   /*if (!p_mdi_child || p_window_state:=='I') {
      enabled=MF_GRAYED;
   } */
   if (debug_active() || (_project_DebugCallbackName!='' && _project_DebugConfig)) {
      return(_OnUpdate_debug_go(cmdui,target_wid,command));
   }
   /*if (cmdui.button_wid && cmdui.button_wid.p_active_form.p_name=='_tbdebugbb_form') {
      return(MF_GRAYED);
   } */
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * <p>Executes a user defined debug command.    The debug command may
 * be specified per project or per file extension.  Parts of the buffer name
 * may be parsed into the debug command before it is executed.
 * Use the <b>new</b> command ("Project", "New...") to create a
 * new workspace or project.  Once a project is open, you can
 * use the Tools Tab ("Project", "Project Properties...", select
 * Tools Tab) to modify project commands, files, and other
 * project setup information.  If the current project has a
 * debug command defined, the extension specific project compile
 * command
 * will be ignored.</p>
 *
 * <p>The debug command is executed asynchronously by default.</p>
 *
 * @return Returns 0 if command queued successfully. On error, message is
 * displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 * @categories Project_Functions
 *
 */
_command int project_debug() name_info(','VSARG2_EDITORCTL)
{
   if (isEclipsePlugin()) {
      return eclipse_debug();
   }
   if (debug_active() || _project_DebugConfig) {
      return(debug_go());
   }
   return(_project_debug2());
}
_command void debug_build_done(_str cmdline='go')
{
   if (!_mdi.p_enabled || (cmdline!='restart' && _tbDebugQMode()) || !_project_DebugConfig) {
      return;
   }
   if (cmdline=='restart') {
      debug_step_into(true,true);
   }
   if (cmdline=='into') {
      debug_step_into(true);
      return;
   }
   if (substr(cmdline,1,8)=='unittest') {
      debug_run_to_cursor_unittest(substr(cmdline, 10));
      return;
   }
   debug_go(true);
   return;
}
int _project_debug2(boolean buildFirstDone=false,_str debugStepType='go')
{
   // look up the session associated with this project/workspace
   int session_id = debug_get_workspace_session_id();
   if (session_id > 0) {
      // make the workspace session the current session
      dbg_set_current_session(session_id);
      debug_gui_update_current_session();
   } else {
      // not using integrated debugger
   }

   // now start the debugger
   return(_project_command2('debug',
                            false,true,0,buildFirstDone,debugStepType));
}
int _OnUpdate_project_execute(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * <p>Executes a user defined execute command.    The execute command
 * may be specified per project or per file extension.  Parts of the buffer
 * name may be parsed into the execute command before it is executed.
 * Use the <b>new</b> command ("Project", "New...") to create a
 * new workspace or project.  Once a project is open, you can
 * use the Tools Tab ("Project", "Project Properties...", select
 * Tools Tab) to modify project commands, files, and other
 * project setup information.  If the current project has a
 * execute command defined, the extension specific project compile
 * command will be ignored.</p>
 *
 * <p>The execute command is executed asynchronously by default.</p>
 *
 * @return Returns 0 if command queued successfully. On error, message is
 * displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command project_execute(_str cmdname='execute',
                         boolean AccumulateErrors=false,
                         boolean AutoNextError=true,
                         int OverrideFlags=0,
                         _str buf_name="") name_info(','VSARG2_EDITORCTL)
{
   if (isEclipsePlugin()) {
      return eclipse_run();
   }
   if (_DebugMaybeTerminate()) {
      return(1);
   }
   return(_project_command2(cmdname,AccumulateErrors,AutoNextError,OverrideFlags,false,'go',buf_name));
}
int _OnUpdate_project_user2(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * Executes a user defined command.    The command may be specified
 * per project or per file extension.  Parts of the buffer name may be
 * parsed into the command before it is executed.  Use the
 * <b>new</b> command ("Project", "New...") to create a new
 * workspace or project.  Once a project is open, you can use
 * the Tools Tab ("Project", "Project Properties...", select
 * Tools Tab) to modify project commands, files, and other
 * project setup information.  If the current project has a
 * resource editor command defined, the extension specific
 * project compile command will be ignored.
 *
 * @return Returns 0 if command queued successfully. On error, message is
 * displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command project_user2() name_info(','VSARG2_EDITORCTL)
{/* was rsrcedit */
   return(_project_command2('user 2'));
}
int _OnUpdate_project_usertool(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
/**
 * <p>Executes a user defined project command.  User tools start with
 * "usertool_."  Check the project file (.vpj) for the exact name of a
 * particular tool.</p>
 *
 * @return Returns 0 if command queued successfully.  On error, message is
 * displayed.
 *
 * @see project_add_file
 * @see project_build
 * @see project_rebuild
 * @see project_debug
 * @see project_execute
 * @see project_user1
 * @see project_user2
 * @see workspace_open
 * @see project_compile
 * @see project_edit
 * @see project_load
 * @see new
 * @see workspace_insert
 * @see workspace_dependencies
 * @see workspace_set_active
 * @see workspace_properties
 * @see workspace_close
 * @see workspace_organize
 *
 * @categories Project_Functions
 *
 */
_command project_usertool(_str TargetName='user 1',boolean AccumulateErrors=false,
                          boolean AutoNextError=true,
                          int OverrideFlags=0,_str buf_name='') name_info(','VSARG2_EDITORCTL)
{
   return(_project_command2(TargetName,AccumulateErrors,AutoNextError,OverrideFlags,false,'go',buf_name));
}
int _OnUpdate_project_help(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdateProjectCommand(cmdui,target_wid,command));
}
_command project_help() name_info(','VSARG2_EDITORCTL)
{
   return(_project_command2('help'));
}
///////////////////////////////////////////////////////////////////////////////////////
//AccumulateErrors - if redirecting errors, appends to the file rather than overwriting
//                   if not redirecting errors, no effect
//
//AutoNextError - if redirecting errors, automatically go to first error
//                if not redirecting errors, no effect
int _project_command2(_str field_name,
                      boolean AccumulateErrors=false,
                      boolean AutoNextError=true,
                      int OverrideFlags=0,
                      boolean buildFirstDone=false,
                      _str debugStepType='go',
                      _str buf_name='')
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS)) {
      _beep();
      return(1);
   }
   _str word='';
   if (buf_name!='') {
      buf_name= absolute(buf_name);
   } else {
      if (_isEditorCtl()) {
         buf_name=p_buf_name;
         int junk;
         word=cur_word(junk);
      }
   }
   int status=_project_command(field_name,buf_name,word,AccumulateErrors,AutoNextError,OverrideFlags,buildFirstDone,debugStepType);
   return(status);
}


static int UsingMacroForMake(_str Dependencies,
                             _str &FirstProjectWithMacro,
                             _str &MacroName,
                             _str command='build')
{
   _str list=Dependencies;
   _str ClassPath=null;
   for (;;) {
      _str cur=parse_file(Dependencies);
      if (cur=='') break;
      cur=_AbsoluteToWorkspace(cur);
      int TargetNode=_ProjectGet_TargetNode(_ProjectHandle(cur),command,GetCurrentConfigName());
      _str makecommand=_ProjectGet_TargetCmdLine(_ProjectHandle(cur),TargetNode);
      if (pos(MACRO_MAKE_RE,makecommand,1,'r')==1) {
         FirstProjectWithMacro=cur;
         parse makecommand with MacroName .;
         return(1);
      }
   }
   return(0);
}


/**
 * Find and execute the specified macro which is defined in the project
 *
 * @param macro  Name of the macro to find and execute
 *
 * @return The return code of the macro
 */
static int callProjectMacro(_str macro)
{
   int status = 0;

   // find the macro
   _str tempMacro = macro;
   _str macroName = parse_file(tempMacro);
   int index = find_index(macroName, PROC_TYPE | COMMAND_TYPE);
   if (index_callable(index)) {
      // call the macro
      status = execute(macro);
      //status = call_index(index);
   } else {
      _message_box("The macro '" macro "' that is associated with this command was not found.");
      status = PROCEDURE_NOT_FOUND_RC;
   }

   return status;
}

void _DisplayErrorMessageBox()
{
   _str msg=get_message();
   _message_box("One or more compilation errors found.\n\n"msg);
}

#define CLR_DEBUGGER_COMMAND "vsclrdebug"

static boolean IsCLRDebuggerCommand(_str command)
{
   int len=length(CLR_DEBUGGER_COMMAND);
   if ( substr(command,1,len)==CLR_DEBUGGER_COMMAND ) {
      return(true);
   }
   return(false);
}

/**
 * Strips .exe or .com form <B>program_name</B> name
 * @param program_name name of program to strip executable extensions from
 * @return <B>program_name</B> with .com or .exe stripped off.
 */
static _str maybe_strip_exe(_str program_name)
{
#if __UNIX__
   return(program_name);
#endif
   _str ext=_get_extension(program_name);
   if ( file_eq(ext,'exe') || file_eq(ext,'com') ) {
      program_name=_strip_filename(program_name,'E');
   }
   return(program_name);
}

/**
 * Returns true if <B>command</B> is a call to <B>program_name</B>.  Strips paths, so this
 * will not tell if paths are equivilant.
 *
 * @param command command-line command from a project tool
 * @param program_name Name of program to check for
 * @return true if <B>command</B> is a call to <B>program_name</B>
 */
static boolean IsCallTo(_str command,_str program_name)
{
   _str first_on_line=parse_file(command,false);
   first_on_line=maybe_strip_exe(first_on_line);
   first_on_line=_strip_filename(first_on_line,'P');

   program_name=maybe_strip_exe(program_name);
   return(file_eq(first_on_line,program_name));
}

/**
 * @return true if <B>command</B> contains a call to vsdebugio
 */
static boolean IsCallToVsdebugio(_str command)
{
   // First check to see if this is an actual call to vsdebugio
   if ( IsCallTo(command,"vsdebugio") ) {
      return(true);
   }
   // Check for the case where the command is being run in an xterm window
   if ( IsCallTo(command,"xterm") && pos("vsdebugio",command) ) {
      return(true);
   }
   return(false);
}

/**
 * Executes project command.
 *
 * <p>
 *
 * Utility function called by project_compile() and _project_command2()
 *
 * @param field_name           Target name (e.g. 'Compile', 
 *                             'Execute', 'Debug').
 * @param buf_name             Parts of this buffer name may be 
 *                             used to fill in the command.
 * @param word                 Parts of this word may be used to
 *                             fill in the command.
 * @param AccumulateErrors     If redirecting errors, appends to
 *                             the file rather than overwriting
 *                             if not redirecting errors, no
 *                             effect
 * @param AutoNextError        If redirecting errors, 
 *                             automatically to to first error
 *                             if not redirecting errors, no
 *                             effect
 * @param ActionOverrideFlags  One or more of bitwise flags 
 *                             OVERRIDE_*.
 * @param buildFirstDone       Set to true when build has 
 *                             already been done (e.g.
 *                             a Build before a Debug).
 * @param debugStepType        Applies to debug commands (e.g. 
 *                             'debug'). Valid values are
 *                             'go'=run to next breakpoint;
 *                             'into'=step into debugee;
 *                             'reload'=restart debugging
 *                             (buf_name becomes significant).
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Project_Functions
 */
int _project_command(_str field_name,
                     _str buf_name,
                     _str word,
                     boolean AccumulateErrors=false,
                     boolean AutoNextError=true,
                     int ActionOverrideFlags=0,
                     boolean buildFirstDone=false,
                     _str debugStepType='go')
{
   // Maybe terminate current debug session?
   if (field_name!='debug' && debugStepType!='reload' && _DebugMaybeTerminate()) {
      return(1);
   }

   int status = 0;
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);

   // 'Compile' tool?
   // Determine which extension-specific compile command applies to this buffer (if any).
   int RuleTargetNode = -1;
   if( strieq(field_name,'compile') && _project_name != "" ) {
      getExtSpecificCompileInfo(buf_name,
                                _ProjectHandle(_project_name),GetCurrentConfigName(),
                                "","",
                                RuleTargetNode,
                                auto linkObject=false,
                                true);
   }
   int TargetNode = RuleTargetNode;

   // If no extension-specific command, then use the one for the field_name specified
   if( TargetNode < 0 ) {
      TargetNode = _ProjectGet_TargetNode(handle,field_name,config);
      //_showxml(handle,0,3);
      //say('TargetNode='TargetNode' n='_xmlcfg_get_filename(handle)' f='field_name' config='config);
   }

   // set the environment variables that are attached to this project/target pair
   setEnvironmentFromProjectTargetNode(handle,TargetNode);

   boolean IsMacro = strieq(_ProjectGet_TargetType(handle,TargetNode),'Slick-C');

   // Auto-add the current file to the project?
   _str configinfo = "";
   _str configobjdir = "";
   _str compile_command = (TargetNode >= 0) ? _ProjectGet_TargetCmdLine(handle,TargetNode,true) : '';
   if (compile_command=='' && _workspace_filename=='' &&
       !_no_child_windows() &&  buf_name!='' &&
       buf_name==_mdi.p_child.p_buf_name &&
       (field_name=='build' || field_name=='compile')
      ) {
      int index=find_index('_on_autocreateworkspace_'_mdi.p_child.p_LangId,PROC_TYPE);
      if (index_callable(index)) {
         status=call_index(buf_name,_strip_filename(buf_name,'PE'),index);
         if (status) {
            return(status);
         }

         int orig_view_id=0;
         get_window_id(orig_view_id);
         project_add_file(buf_name,true);
         activate_window(orig_view_id);

         _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
         TargetNode=_ProjectGet_TargetNode(handle,field_name,config);
         compile_command=(TargetNode>=0)?_ProjectGet_TargetCmdLine(handle,TargetNode):'';
      }
   }

   // check for a pre macro. if buildFirstDone is true, it implies that this is the
   // second time thru this function so we do not want to run the macros again
   _str preMacro = _ProjectGet_TargetPreMacro(handle,TargetNode);
   if (preMacro != "" && !buildFirstDone) {
      status = callProjectMacro(preMacro);
      if (status) return status;
   }

   // check for a post macro. Note that a PostMacro is currently only run if BuildFirst
   // is enabled and the build succeeds.
   _str postMacro = _ProjectGet_TargetPostMacro(handle, TargetNode);

   // if this is a command that contains %bd or %bo make sure the object directory
   // exists since the command references it
   if (pos("(%b[do]|%jbd)", compile_command, 1, "IU") > 0) {
      //say("%b?: " substr(compile_command, pos("S1"), pos("1")));
      _str option=substr(compile_command, pos("S1"), pos("1"));
      _str objectDir = _parse_project_command(option, "", _project_name, "");
      if (strieq(option,'%jbd')) {
         parse objectDir with . objectDir;

      }
      if (objectDir != "") {
         objectDir = absolute(objectDir, _strip_filename(_project_name, "N"));
         if (!file_exists(objectDir ".")) {
            status = make_path(objectDir);
            if (status) return status;
         }
      }
   }

   // If this is an ant-build target, then we need to pull together
   // the CLASSPATH from the ant build file for later.
   _str ClassPath='';
   if (pos('%cp',compile_command,1,'i')) {
      ClassPath=_ProjectGet_ClassPathList(handle,config);
      //if (ClassPath!=null) say(ClassPath);

      // if the build command uses ant, check all targets called as part of that build
      // command for javac commands and add the destdir value to the classpath
      int buildTargetNode = _ProjectGet_TargetNode(handle, "Build", config);
      if (buildTargetNode >= 0) {
         _str antBuildCommand = _ProjectGet_TargetCmdLine(handle, buildTargetNode);
         if (using_ant(antBuildCommand)) {
            // replace %placeholders
            antBuildCommand = _parse_project_command(antBuildCommand, "", _project_name, "");

            // parse the ant command line
            _str antBuildFile = "";
            _str antOptionList[] = null;
            _str antTargetList[] = null;

            _ant_ParseAntCommand(antBuildCommand, antBuildFile, antOptionList, antTargetList);

            // make ant build file absolute
            antBuildFile = _AbsoluteToProject(antBuildFile, _project_name);

            // append classpath from each target that is part of the build command
            int t;
            for (t = 0; t < antTargetList._length(); t++) {
               _str javacDestdir = _ant_GetJavacDestDirFromTarget(antBuildFile, antTargetList[t]);
               _maybe_append(ClassPath, PATHSEP);
               ClassPath = ClassPath javacDestdir;
            }
         }
      }
   }

   // If we do not have a command yet, check for extension-specific one
   _str pname=(_project_name=='')?('.'_mdi.p_child.p_LangId):_project_name;
   boolean isExtensionCommand=false;
   if (((_project_name == '') || (compile_command=='')) && _isEditorCtl()) {
      handle=gProjectExtHandle;
      config='.'_mdi.p_child.p_LangId;
      TargetNode=_ProjectGet_TargetNode(handle,field_name,config);
      compile_command=(TargetNode>=0)?_ProjectGet_TargetCmdLine(handle,TargetNode):'';
      // if there's no luck finding a command to run, then bail
      if( compile_command == "" ) {
         if (!project_in_auto_build()) {
            _message_box(nls("There is no language-specific command for %s.", _mdi.p_child.p_mode_name));
         }
         return -1;
      }
      isExtensionCommand=true;
   }

   // Capture output with process buffer?
   boolean CaptureOutputWith_ProcessBuffer=strieq(_ProjectGet_TargetCaptureOutputWith(handle,TargetNode),VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER);
   if (ActionOverrideFlags & (OVERRIDE_CAPTUREOUTPUTWITH_PROCESSBUFFER|OVERRIDE_DOCAPTUREOUTPUTWITH_REDIRECTION)) {
      CaptureOutputWith_ProcessBuffer=false;
   }

   // No luck finding a command to run, so bail
   if( status != 0 || compile_command == "" ) {
      if (!project_in_auto_build()) {
         _message_box(nls("This project command is not defined for the project %s\n\nFrom the Project menu select \"Project Properties...\" and select the Tools tab", pname));
      }
      return(status);
   }

   _str unconverted_compile_command=compile_command;
   _project_convert_command(compile_command,buf_name,field_name,handle,config);
   //say('h2 compile_command='compile_command);
   _str tempCmdLine = stranslate(compile_command,"","%%");

   // determine if this command will require buildfirst functionality
   boolean buildFirst = (!buildFirstDone && _ProjectGet_TargetBuildFirst(handle,TargetNode) > 0);

   if ( buildFirst && field_name=='debug' && _IsVisualStudioWorkspaceFilename(_workspace_filename) ) {
      buildFirst=false;
   }
   // if buildfirst is enabled, retrieve the flags for the 'make' command so things like
   // its save options can be used to override the options for the current command
   _str makeSaveOption= VPJ_SAVEOPTION_SAVENONE;
   boolean makeVerbose=false;
   boolean makeBeep=false;
   _str buildFirstCommand = "";

   if (buildFirst && debugStepType!='reload') {
      // pull the flags (copts) from the 'make' command
      int BuildTargetNode=_ProjectGet_TargetNode(handle,'build',config);

      // remember the buildfirst command so that it can be checked for environment-setup
      // special cases like ant
      buildFirstCommand = _ProjectGet_TargetCmdLine(handle, BuildTargetNode, true);

      // check for a pre macro for the build command
      _str buildFirstPreMacro= _ProjectGet_TargetPreMacro(handle,BuildTargetNode);
      if (buildFirstPreMacro != "") {
         status = callProjectMacro(buildFirstPreMacro);
         if (status) return status;
      }

      makeSaveOption =_ProjectGet_TargetSaveOption(handle,BuildTargetNode);
      if (makeSaveOption == '') {
         makeSaveOption= VPJ_SAVEOPTION_SAVENONE;
      }
   }

   // if command is 'build', 'rebuild', or buildFirst is true, cleanup the
   // error file
   if (!AccumulateErrors && (strieq(field_name, "build") || strieq(field_name, "rebuild") || buildFirst)) {
      quit_error_file();
      delete_file(COMPILE_ERROR_FILE);
   }

   // Save option is per command in the option flags. If "save*" is missing
   // from the options flag, its absence implies saveNone.  The save options will
   // be used from the current command's flags unless buildFirst is enabled.  If so,
   // the save options will be read from the 'make' command instead.
   _str saveFlags = "";
   if (buildFirst) {
      saveFlags = makeSaveOption;
   } else {
      saveFlags= _ProjectGet_TargetSaveOption(handle,TargetNode);
   }
   _str save_option=0;
   if (strieq(VPJ_SAVEOPTION_SAVECURRENT,saveFlags)) {
      save_option = 1;
   } else if (strieq(VPJ_SAVEOPTION_SAVEMODIFIED,saveFlags)) {
      save_option = 3;
   } else if (strieq(VPJ_SAVEOPTION_SAVEALL,saveFlags)) {
      save_option = 2;
   } else if (strieq(VPJ_SAVEOPTION_SAVEWORKSPACEFILES,saveFlags)) {
      save_option = 4;
   }

   // Honor save options:
   if (save_option) {
      _project_disable_auto_build(true);
      if (save_option==1) {
         if ( buf_name!="" && _need_to_save2(buf_name,1)) {
            status=_save_non_active(buf_name);
         }
      } else if (save_option==2) {
         status=_mdi.p_child.save_all(-1,1 /* skip unnamed files */);
      } else if (save_option==3) {
         _mdi.p_child.list_modified('',true);
      } else if (save_option==4) {
         status=_mdi.p_child.save_all(-1,1 /* skip unnamed files */,true);
      }
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
      _project_disable_auto_build(false);
      if (status) return(status);
   }

   //
   // Package-specific environment set up
   //

   {
      _str temp=compile_command;
      _str filename=parse_file(temp,false);
      _str name=_strip_filename(filename,'PE');
      _str app_type='';

      // what to do when buildFirst == true is tricky here.  if this is an execute call,
      // this function is only called once so it is safe to not check the buildFirst
      // option and go ahead and find the main class that should be executed.  vsbuild
      // will then be given the command to execute after the build.
      //
      // if this is a debug call, this function will actually get called twice if
      // buildFirst is true.  vsbuild will output a string to let the editor know that
      // it should continue.  this would cause the user to be prompted twice for the
      // main class to use.  this is why the buildFirst option is checked if
      // field_name == debug.  the second debug pass of this function will have
      // buildFirst set to false.
      if (_project_name!='' && name=='java' && (field_name=='execute' || (field_name=='debug'  && !buildFirst))) {
         app_type=_ProjectGet_AppType(handle,config);
         if (app_type=='application') {
            _str className=_GetJavaMainFromCommandLine(compile_command);
            if (_helpFindJavaMainClass(className,compile_command)) {
               return(1);
            }
         }
      }
      if (_project_name!='' && name=='jdb' && field_name=='debug' && !buildFirst) {
         app_type=_ProjectGet_AppType(handle,config);

         int ExecuteTargetNode=_ProjectGet_TargetNode(handle,'execute',config);
         if (app_type=='application') {
            _str className=_GetJavaMainFromCommandLine(_ProjectGet_TargetCmdLine(handle,ExecuteTargetNode));
            if (_helpFindJavaMainClass(className,compile_command)) {
               return(1);
            }
         }
      }

      // Call _<type>_set_environment() callback to set up package environment.
      // Example:
      //  int  _php_set_environment(int projectHandle, _str config, _str target,
      //                            boolean quiet, _str error_hint);
      _str type = _ProjectGet_Type(handle,config);
      if( type != "" ) {
         int index = find_index(nls("_%s_set_environment",type),PROC_TYPE);
         if( index > 0 && index_callable(index) ) {
            _str error_hint = "";
            int status2 = call_index(handle,config,field_name,true,error_hint,index);
            if( status2 != 0 ) {
               _str msg = "Warning: Could not set environment for project.";
               if( error_hint != null && error_hint != "" ) {
                  msg = msg"\n\n"error_hint;
               } else {
                  msg = msg"\n\nRun the Options dialog for this project from the Build menu.";
               }
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
               return(status2);
            }
         }
      }

      // Setup the environment for DevStudio and Visual Studio when
      // we open the workspace
      //if ((file_eq(name,'msdev') || file_eq(name,'nmake') || file_eq(name,'cl')) &&
      //    path_search(filename,"","P")==""
      //   ) {
      //   set_vcpp_environment(true);
      //}

      temp=unconverted_compile_command;
      filename=parse_file(temp,false);
      name=_strip_filename(filename,'PE');

      // TODO: Refactor the following functions into _java_set_environment callback:
      // TODO:   set_java_environment
      // TODO:   set_jbuilder_environment
      // TODO:   set_ant_environment
      // setup the environment for java
      if ( file_eq(name,'javac') ||
           file_eq(name,'java') ||
           file_eq(name,'javadoc') ||
           file_eq(name,'appletviewer') ||
           file_eq(name,'jar') ||
           file_eq(name,'java') ||
           file_eq(name,'jdb') ||
           file_eq(name,'javamake') ||
           file_eq(name,'javarebuild') ||
           file_eq(name,'javaviewdoc') ||
           file_eq(name,'javamakedoc') ||
           file_eq(name,'javamakejar') ||
           using_ant(name) ||                           // this is here because ant needs java to be findable
           (buildFirst && using_ant(buildFirstCommand)) // this is here because ant needs java to be findable
         ) {
         boolean useJDWP = (field_name=='debug' && pos("-Xrunjdwp:",compile_command));
         if (set_java_environment(true, handle, config, useJDWP)) {
            _message_box("JDK programs not found\n\nSet the JDK installation directory (\"Build\",\"Java Options\")");
            return(1);
         }
      }

      // TODO: Roll set_jbuilder_environment() into _java_set_environment.
      // setup environment for jbuilder
      if (_IsJBuilderAssociatedWorkspace(_workspace_filename) || (file_eq(name, "jbuilder") || file_eq(name, "bmj"))) {
         if (set_jbuilder_environment(name)) {
            _message_box("JBuilder installation not found.  Please make sure JBuilder SE or Enterprise is installed on this computer.");
            return 1;
         }
      }

      // TODO: Roll set_ant_environment() into _java_set_environment.
      // setup environment for ant
      if (using_ant(name) || (buildFirst && using_ant(buildFirstCommand))) {
         if (set_ant_environment(handle, config)) {
            _message_box("Ant or JDK installation not found.\n\nSet the Ant and JDK installation directories (\"Build\",\"Java Options\")");
            return 1;
         }
      }
   }

   tag_close_bsc();

   // Put together the commandline that will be run
   {
      if( ClassPath == null ) {
         ClassPath = "";
      }
      // Execute project package-specific _parse_project_command() callback.
      // Call _<type>_parse_project_command() callback to get commandline to run.
      // If callback does not exist, fall through to default processing. Look
      // at _php_parse_project_command as an example.
      _str type = _ProjectGet_Type(handle,config);
      if( type != "" ) {
         int index = find_index(nls("_%s_parse_project_command",type),PROC_TYPE);
         if( index > 0 && index_callable(index) ) {
            compile_command = call_index(compile_command,
                                         buf_name,
                                         pname,
                                         word,
                                         '',
                                         field_name,
                                         ClassPath,
                                         handle,config,
                                         index);
            if( compile_command == "" ) {
               return COMMAND_CANCELLED_RC;
            }
            // Success. Fall through.

         } else {
            compile_command = _parse_project_command(compile_command,buf_name,pname,word,'',field_name,ClassPath);
         }
      } else {
         compile_command = _parse_project_command(compile_command,buf_name,pname,word,'',field_name,ClassPath);
      }
   }

   if (alreadyUsing_vsbuild(compile_command)) {
      if (!_vsbuild_signal_init()) {
         if (compile_command != "") compile_command = compile_command " ";
         compile_command = compile_command "-signal "_vsbuild_signal_get_port();
      }
   }
   // check to see if a build should be done first
   boolean doDebugBegin=(field_name=='debug');
   boolean UsePassthru = false;

   if (buildFirst && !alreadyUsing_vsbuild(compile_command)) {
      // if buildFirst is enabled, the original compile command should be saved and passed
      // into vsbuild after the -execute or -execmacro option as applicable
      _str orig_compile_command=compile_command;

      // add the overriding flags from makeFlags to flags for the current command
      // NOTE: should any other flags be checked here?

      if ( _IsVisualStudioWorkspaceFilename(_workspace_filename) ) {
         if (field_name=='execute') {
            AddVSBuildToCommandLine(compile_command,'build',makeVerbose,makeBeep);
         }
      } else {
         AddVSBuildToCommandLine(compile_command,'build',makeVerbose,makeBeep);
      }
      if (field_name=='debug' && pos("-Xrunjdwp:",orig_compile_command) &&
          CaptureOutputWith_ProcessBuffer) {
         compile_command=compile_command' -execmacro debug_build_done 'debugStepType;
         doDebugBegin=false;

      } else if (field_name=='debug' && IsCallToVsdebugio(orig_compile_command) &&
                 _project_DebugCallbackName=='gdb' &&
                 CaptureOutputWith_ProcessBuffer) {
         compile_command=compile_command' -execmacro debug_build_done 'debugStepType;
         doDebugBegin=false;
      } else if (IsMacro && buildFirst) {
         compile_command=compile_command' -execmacro 'orig_compile_command;
      } else if (postMacro != "") {
         // If we've got a PostMacro, append it to the command line
         compile_command=compile_command' -execmacro 'postMacro;
         if (pos('^unittest', field_name, 1, 'RI') > 0) {
            // If this is a unittest command, we need to pass the original cmd
            // line as an argument to the PostMacro
            compile_command=compile_command' 'orig_compile_command;
         }
      } else {
#if 0
         /*
             8.0  -   Allow vsbuild to process buildfirst

         */
         if (alreadyUsing_vsbuild(compile_command)) {
            AddVSBuildParametersToCommandLine(compile_command, makeVerbose, makeBeep);
         } else {
            AddVSBuildToCommandLine(compile_command,field_name,makeVerbose,makeBeep);
         }
#endif
         /*
            Since the editor alrealdy did the work to find the java main class,
            pass the -execute option to vsbuild.
         */
         compile_command=compile_command' -execute 'orig_compile_command;
      }
   } else if (_ProjectGet_TargetVerbose(handle,TargetNode) || _ProjectGet_TargetBeep(handle,TargetNode)) {
      // check to see if vsbuild is already being used.  if so, simply add the parameter(s)
      // if they are not already present
      if (alreadyUsing_vsbuild(compile_command)) {
         AddVSBuildParametersToCommandLine(compile_command,
                                           _ProjectGet_TargetVerbose(handle,TargetNode),
                                           _ProjectGet_TargetBeep(handle,TargetNode));
      } else {
         // if buildFirst is not enabled, vsbuild is being added because the verbose
         // and/or beep options were requested for a build or rebuild.  since verbose
         // and beep are only valid for build and rebuild commands, vsbuild will pull
         // the appropriate command from the project file so there is no need to pass
         // the original command in via -execute or -execmacro
         AddVSBuildToCommandLine(compile_command, field_name,
                                 _ProjectGet_TargetVerbose(handle,TargetNode),
                                 _ProjectGet_TargetBeep(handle,TargetNode));
      }
   } else if (__UNIX__ &&
              _ProjectGet_TargetRunInXterm(handle,TargetNode) &&
              CaptureOutputWith_ProcessBuffer) {
      compile_command=compile_command:+' &';
   } else {
      if (!IsMacro && !alreadyUsing_vsbuild(compile_command) && !buildFirst && !(field_name=='execute' || field_name=='debug')) {
         boolean noPassthru = _ProjectGet_TargetNoPassthru(handle,TargetNode);
         UsePassthru = !noPassthru;
      }
   }

   // If the special command name "vsdebugio" is used for the debug command
   // delegate to launching the command through debug_begin().
   // For GDB, we want to latch on to the vsdebugio handler program.
   _str debug_compile_command=compile_command;
   if (field_name=='debug' && IsCallToVsdebugio(compile_command) && _project_DebugCallbackName=='gdb') {
      // build full path to vsdebugio
      _str vsdebugio_cmd=get_env("VSLICKBIN1");
      _maybe_append_filesep(vsdebugio_cmd);
      vsdebugio_cmd=maybe_quote_filename(vsdebugio_cmd:+"vsdebugio");

      _str vsdebugio_opts = "";
      _str vsdebugio_switches = "";
      parse compile_command with . "vsdebugio" vsdebugio_switches "-prog" vsdebugio_opts;
      _str vsdebugio_port = "";
      if (def_debug_vsdebugio_port!='') {
         vsdebugio_port = " -port " :+ def_debug_vsdebugio_port;
      }
      compile_command=vsdebugio_cmd vsdebugio_port vsdebugio_switches " -prog" vsdebugio_opts ;
#if !__UNIX__
      // vsdebugio unneeded on Windows because it creates an output window of its own
      //_str program_name='', options='';
      //parse vsdebugio_opts with program_name options;
      _str workingDir = getRunFromDirectory(handle, TargetNode, buf_name);
      _str options=vsdebugio_opts;
      _str program_name=parse_file(options);
      options = strip(options);
      return debug_begin('gdb',strip(program_name),'',strip(options),def_debug_timeout,null,null,workingDir);
#endif
   }

#if !__UNIX__
   // If this is a windbg project, then start debugging using windbg.
   // This does not use vsdebugio, so it is pretty straight-forward.
   if (field_name=='debug' && pos("vcproj_windbg_debug",compile_command) > 0 && _project_DebugCallbackName=='windbg') {
      workingDir := getRunFromDirectory(handle, TargetNode, buf_name);
      options := compile_command;
      macro_name   := parse_file(options);
      program_name := parse_file(options);
      debugger_args := "-create -init-dir "maybe_quote_filename(workingDir)" -symbols";
      return debug_begin('windbg',strip(program_name),'',options,def_debug_timeout,null,debugger_args,workingDir);
   }
#endif

   if (CaptureOutputWith_ProcessBuffer &&
       _ProjectGet_TargetClearProcessBuffer(handle,TargetNode)
       && !(ActionOverrideFlags&OVERRIDE_CLEAR_PBUFFER)) {
      _mdi.p_child.clear_pbuffer();
   }
#if __UNIX__
   // IF we are not already using xterm and we need to run xterm
   if (_ProjectGet_TargetRunInXterm(handle,TargetNode)) {
      _str temp=compile_command;
      // If we are running vsdebugio in an xterm, then we do not want the xterm to run
      // vsdebugio through the user's shell (tcsh tries to interpret -prog from vsdebugio!).
      // Besides, the xterm does not need a shell to run vsdebugio, it can just run it
      // directly.
      _str pgmname=compile_command;
      pgmname=_strip_filename(parse_file(pgmname),'P');
      boolean includeShell= !(field_name=='debug' && IsCallToVsdebugio(pgmname));
      _str xterm_prefix=_XtermGetCommandPrefix(parse_file(temp,false),includeShell);
      if (xterm_prefix == "") {
         _message_box(nls("Can't find an X terminal emulator (xterm,dtterm,aixterm,hpterm,cmdtool).\nPlease set VSLICKXTERM to the full path to your X terminal emulator."));
         return(FILE_NOT_FOUND_RC);
      }

      // convert any double quotes in the command to single quotes and double quote
      // always quote the program path/name in the command
      if (includeShell) {
         compile_command = xterm_prefix ' "' stranslate(compile_command,"'",'"') '"';
      } else {
         compile_command = xterm_prefix ' "' stranslate(parse_file(compile_command),"'",'"') '" ' compile_command;
      }
      //say('compile_command='compile_command);
   }
#endif
#if 0
   // It would be nice to prompt whether to buildfirst if the user attempts to debug and they have not
   // yet built the main class. The _FindJavaClass functions is pretty hard to write and if there is
   // no %cp we need to use the CLASSPATH environment variable.  There maybe be more special cases
   // too.
   if (!pos('buildfirst',flags,1,'i') && field_name=='debug' && _project_name!='') {
      _ini_get_value(_project_name,"GLOBAL","DebugCallbackName",DegbugCallbackName);
      if (DegbugCallbackName!='') {
         index=find_index('_'DebugCallbackName'_ConfigNeedsDebugMenu',PROC_TYPE);
         if (index) {
            DebugConfig=call_index(flags,compile_command,index));
         } else {
            DebugConfig=true;
         }
         if (DebugConfig) {
            _str className=_GetJavaMainFromCommandLine(compile_command);
            if (className!='' && _FindJavaClass(className,ClassPath)) {
            }
         }
      }
   }
#endif

   boolean UseVSBuild=false;
   _str Dependencies='';

   if (!IsMacro && !isExtensionCommand && (strieq(field_name,'build') || strieq(field_name,'rebuild'))) {
      Dependencies=workspace_project_dependencies(_project_name);
   }

   // if there are dependencies then vsbuild will be used to make sure they all get built.  the
   // exception to this rule is if this project is built with automatically generated makefiles.
   // if so, they already handle dependencies themselves
   if (Dependencies!='' && !strieq(_ProjectGet_BuildSystem(handle), "automakefile") &&
       //pos('vsbuild',flags,1,'i') &&
       !alreadyUsing_vsbuild(compile_command)) {
      UseVSBuild=true;

   } else {
      // if this is a jbuilder compile, bmj must be run in the proper src dir that contains
      // the java files for the package to align properly.  figure out which src dir applies
      // to the source file and change to that dir before doing the compile
      _str temp = compile_command;
      _str cmdName = parse_file(temp, false);
      cmdName = _strip_filename(cmdName, "PE");
      if (_IsJBuilderAssociatedWorkspace(_workspace_filename) && file_eq(cmdName, "bmj")) {
         // find the src dir that contains the current file
         _str jbuilderSourceDir = _getJBuilderSourceDirForFile(GetProjectDisplayName(), buf_name);
         if (jbuilderSourceDir != "") {
            cd(maybe_quote_filename(jbuilderSourceDir));
         }

      } else {
         // change to the working directory before compile
         _cdb4compile(handle,TargetNode,buf_name);
      }
   }

   // If the command sets any environment variables or uses a "CallTarget", use vsbuild
   _str cmds[];
   _ProjectGet_TargetAdvCmd(handle,TargetNode,cmds);
   if (cmds._length()>0) {
      UseVSBuild=true;
   }

   if (UsePassthru && !UseVSBuild && !IsMacro && !alreadyUsing_vsbuild(compile_command)) {
      compile_command = AddVSBuildProcessCommandLineOnly(compile_command,
                                                         _ProjectGet_TargetVerbose(handle,TargetNode),
                                                         _ProjectGet_TargetBeep(handle,TargetNode));
   }

   //
   // Project command run
   //

   int process_id=0;
   if (!IsMacro && CaptureOutputWith_ProcessBuffer) {
      if ( def_auto_reset ) reset_next_error();
      if (UseVSBuild && _project_name!='') {
         int oemCallbackIndex = find_index("_oem_use_vsbuild_for_command",PROC_TYPE);
         boolean passesOEMCallback = true;
         if ( oemCallbackIndex ) {
            passesOEMCallback = call_index(field_name,oemCallbackIndex);
         }
         if ( passesOEMCallback ) {
            AddVSBuildToCommandLine(compile_command,field_name,
                                    _ProjectGet_TargetVerbose(handle,TargetNode),
                                    _ProjectGet_TargetBeep(handle,TargetNode),
                                    buf_name);
         }
      }

      // make sure there is nothing in the command that could break it
      compile_command = makeCommandCLSafe(compile_command);
      if (compile_command != "") {
         status=concur_command(compile_command,def_process  && !def_process_tab_output);
      }
   } else if ((ActionOverrideFlags & OVERRIDE_DOCAPTUREOUTPUTWITH_REDIRECTION) ||
              strieq(_ProjectGet_TargetCaptureOutputWith(handle,TargetNode),VPJ_CAPTUREOUTPUTWITH_REDIRECTION)
             ) {
      if ( def_auto_reset ) reset_next_error();
      _str AccumulateOption='';
      if (AccumulateErrors) {
         AccumulateOption='-a';
      }
      _str AutoNextErrorOption='';
      if (!AutoNextError) {
         AutoNextErrorOption='-n';
      }
      if (UseVSBuild && _project_name!='') {
         AddVSBuildToCommandLine(compile_command,field_name,
                                 _ProjectGet_TargetVerbose(handle,TargetNode),
                                 _ProjectGet_TargetBeep(handle,TargetNode));
      }

      // make sure there is nothing in the command that could break it
      compile_command = makeCommandCLSafe(compile_command);
      if (compile_command != "") {
         status=dos('-e -v 'AccumulateOption' 'AutoNextErrorOption' 'compile_command);
      }
   } else if ( IsCLRDebuggerCommand(compile_command) ) {
   } else {
      _str temp=compile_command;
      _str pgmname=parse_file(temp);
      int index=find_index(pgmname,COMMAND_TYPE);
      if (index && IsMacro) {
         status=execute(compile_command,'');
      } else if (IsMacro && buildFirst && CaptureOutputWith_ProcessBuffer) {
         status=concur_command(compile_command);
      } else {
         temp=slick_path_search(pgmname,'p');
         if (temp=='') {
            temp=absolute(pgmname);
            if (!file_exists(temp)) {
               _str message2=".\n\nFrom the Project menu, select \"Project Properties...\" and select the Tools tab to change tool command.";
               _message_box(nls("Program %s not found",pgmname)message2);
               return(FILE_NOT_FOUND_RC);
            }
         }
         if (UseVSBuild && _project_name!='') {
            AddVSBuildToCommandLine(compile_command,field_name,
                                    _ProjectGet_TargetVerbose(handle,TargetNode),
                                    _ProjectGet_TargetBeep(handle,TargetNode));
         }
         // IF we are not already using xterm and we need to run xterm
         if (__UNIX__ && _ProjectGet_TargetRunInXterm(handle,TargetNode)) {
            // make sure there is nothing in the command that could break it
            compile_command = makeCommandCLSafe(compile_command);
            if (compile_command != "") {
               _str dosoption='';
               if ( _strip_filename(pgmname,'P')!='xterm' ) {
                  dosoption=dosoption' -t';
               }
               status=dos(dosoption' 'compile_command);
            }
         } else {
            // make sure there is nothing in the command that could break it
            compile_command = makeCommandCLSafe(compile_command);
            if (compile_command != "") {
               status=shell(compile_command,'ap');
            }
         }
      }
   }

   //
   // Project command post-run
   //

   if (!status && debugStepType=='reload') {
      status=debug_reload(buf_name);
   } else if (status && debugStepType=='reload') {
      _DisplayErrorMessageBox();
   }

   // Explanation:
   // If the project command we just ran was a macro, and that
   // macro called _process_events with the (T)imer option, then
   // an _actapp_ callback may have pulled the project handle out
   // from under us (via _ProjectCache_Update). This ugliness first
   // reared its head with the Python debugger on Windows because it
   // spawns a console window by default.
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);

   // Execute project package-specific post-command status callback.
   // Call _<type>_project_command_status() callback to act on status
   // returned from running project command. If callback does not exist,
   // fall through to default processing. Look at _php_project_command_status
   // as an example.
   _str type = _ProjectGet_Type(handle,config);
   if( type != "" ) {
      int index = find_index(nls("_%s_project_command_status",type),PROC_TYPE);
      if( index > 0 && index_callable(index) ) {
         _str error_hint = "";
         status = call_index(handle,config,
                             status,
                             compile_command,
                             field_name,
                             buf_name,
                             word,
                             debugStepType,
                             true,
                             error_hint,
                             index);
         if( status != 0 && status != COMMAND_CANCELLED_RC ) {
            _str msg = "Project command failed to run.";
            if( error_hint != null && error_hint != "" ) {
               msg = msg"\n\n"error_hint;
            }
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return(status);
      }
      // Fall through to legacy processing
   }

   // TODO: Roll this logic into a package-specific _gnuc_project_command_status() callback
   if (!status && field_name=='debug' && IsCallToVsdebugio(compile_command)) {
      if (!doDebugBegin) {
         return(1);
      }
      //_str program_name='', options='';
      //parse debug_compile_command with . "vsdebugio" "-prog" program_name options;
      _str vsdebugio_opts='';
      parse debug_compile_command with . "vsdebugio" "-prog" vsdebugio_opts;
      _str options=vsdebugio_opts;
      _str program_name=parse_file(options);
      options = strip(options);

#if __UNIX__
      // must check to see if options ends with & and strip it off
      if (last_char(options) == '&') {
         options = substr(options, 1, length(options) - 1);
      }
#endif
      _str workingDir = getRunFromDirectory(handle, TargetNode, buf_name);
      status = debug_begin('gdb',strip(program_name),'',strip(options),def_debug_timeout,null,null,workingDir);
   }

   // TODO: Roll this logic into a package-specific _java_project_command_status() callback
   if (!status && field_name=='debug' && 
       (pos("-Xrunjdwp:",compile_command)||_ProjectGet_AppType(handle)==APPTYPE_GWT)){
      if (!doDebugBegin) {
         return(1);
      }
      _str host_name='',host_port='',address='';
      // special case for gwt apps
      if (_ProjectGet_AppType(handle)==APPTYPE_GWT) {
         _str projectDir = _file_path(_project_name);
         _maybe_append_filesep(projectDir);
         // it should be in this directory, but it doesn't have to be 'build.xml'...could be 'anything.xml'
         _str buildFile = projectDir :+ 'build.xml';
         int buildFileHandle = _xmlcfg_open(maybe_quote_filename(buildFile), auto s, VSXMLCFG_OPEN_REFCOUNT);
         if (buildFileHandle >=0) {
            _str jdwpCmd = _gwt_getDebugJDWPCommand(buildFileHandle);
            _xmlcfg_close(buildFileHandle);
            if (jdwpCmd != '') {
               parse jdwpCmd with . "-Xrunjdwp:" . ",address=" address .;
            }
         }
      } else {
         parse compile_command with . "-Xrunjdwp:" . ",address=" address .;
      }
      if (address != '') {
         parse address with address ',' .;
         if (pos(':',address)) {
            parse address with host_name ':' host_port;
         }
         debug_begin('jdwp',strip(host_name),strip(address));
      } else {
         // error...cant start debug
      }
   }

   // TODO: Roll this logic into a package-specific _<type>_project_command_status() callback
   // DJB 03-18-2008
   // Integrated .NET debugging is no longer available as of SlickEdit 2008
   // 
   // Leave the invocation code here, but expect it to ultimately fail and show 
   // a message box informing the user that the feature is no longer available.
   //
   _str display_name=GetProjectDisplayName(_project_name);
   if ( !status && field_name=='debug' && _IsVisualStudioCLRProject(display_name) &&
        IsCLRDebuggerCommand(compile_command) ) {
      _str ExeName='';
      status=_GetExeFromVisualStudioFile(display_name,config,ExeName);
      if ( status ) {
         _message_box(nls("Could not get executable name from project file '%s'",display_name));
         return(status);
      }
      _str args=substr(compile_command,length(CLR_DEBUGGER_COMMAND)+1);
      debug_begin('dotnet',ExeName,'',args);
   }

   // TODO: Roll this logic into a package-specific _<type>_project_command_status() callback
   if ( !status && field_name=='debug' && IsCLRDebuggerCommand(compile_command)) {
      _str ExeName=_ProjectGet_OutputFile(handle,config);
      ExeName=_parse_project_command(ExeName,buf_name,pname,word);
      ExeName=_AbsoluteToProject(ExeName,pname);
      _str args=substr(compile_command,length(CLR_DEBUGGER_COMMAND)+1);
      debug_begin('dotnet',ExeName,'',args);
   }

   return(status);
}

static void AddVSBuildToCommandLine(_str &compile_command,_str makecommand, boolean verbose,boolean beep,_str buf_name="")
{
   // determine which options should be passed to vsbuild
   _str options='';
   if (!_no_child_windows()) {
      if (_isEditorCtl()) {
         /*if (p_DocumentName!='') {
            options='-b 'maybe_quote_filename(p_DocumentName);
         }else */
         if ( buf_name=="" ) buf_name=p_buf_name;
         if ( buf_name!='' ) {
            options='-b 'maybe_quote_filename(buf_name);
         }
      }
   }

   if (verbose) {
      if (options != "") options = options " ";
      options = options "-v";
   }
   if (beep) {
      if (options != "") options = options " ";
      options = options "-beep";
   }

   _str filename=editor_name('p'):+'vsbuild';
   compile_command=maybe_quote_filename(filename)' 'maybe_quote_filename(makecommand)' 'options' 'maybe_quote_filename(_workspace_filename)' 'maybe_quote_filename(_project_name);

   if (!_vsbuild_signal_init()) {
      compile_command = compile_command " -signal "_vsbuild_signal_get_port();
   }
}

static _str AddVSBuildProcessCommandLineOnly(_str compile_command, boolean verbose,boolean beep)
{
   // determine which options should be passed to vsbuild
   _str options='';
   if (verbose) {
      if (options != "") options = options " ";
      options = options "-v";
   }
   if (beep) {
      if (options != "") options = options " ";
      options = options "-beep";
   }

   _str filename=editor_name('p'):+'vsbuild';
   _str orig_command = compile_command;
   compile_command=maybe_quote_filename(filename);
   if (options != '') {
      compile_command = compile_command' 'options;
   }
   if (!_vsbuild_signal_init()) {
      compile_command = compile_command " -signal "_vsbuild_signal_get_port();
   }
   if (orig_command != '') {
      compile_command = compile_command" -command "orig_command;
   }
   return compile_command;
   
}

static void AddVSBuildParametersToCommandLine(_str& compile_command, boolean verbose, boolean beep)
{
   // walk until the first space that is not inside a quote
   boolean inQuotes = false;
   int i;
   for (i = 1; i < length(compile_command); i++) {
      if (substr(compile_command, i, 1) == '"') {
         inQuotes = !inQuotes;
         continue;
      }

      // if this is a space not in quotes then break
      if (substr(compile_command, i, 1) == ' ' && !inQuotes) {
         break;
      }
   }

   int cmdLength = length(compile_command);
   if (i < cmdLength) {
      // add the command (executable) name and then the parameters
      _str newCommand = substr(compile_command, 1, i);
      if (verbose) {
         if (newCommand != "") newCommand = newCommand " ";
         newCommand = newCommand "-v";
      }
      if (beep) {
         if (newCommand != "") newCommand = newCommand " ";
         newCommand = newCommand "-beep";
      }

      // add the rest of the command
      newCommand = newCommand " " substr(compile_command, i+1, cmdLength - i);
      compile_command = newCommand;

   } else {
      // if no space found, just add it to the end
      if (verbose) {
         compile_command = compile_command " -v";
      }
      if (beep) {
         compile_command = compile_command " -beep";
      }
   }
}


/**
 * Check to see if the specified configuration exists.  If so,
 * return its output dir thru the outputDir parameter.
 *
 * @param configText
 * @param configList
 *
 * @return 1 if it exists, 0 otherwise
 */
int configExists(_str configText, ProjectConfig (&configList)[])
{
   int i;
   for (i=0; i<configList._length(); i++) {
      if (configText :== configList[i].config) return(1);
   }
   return(0);
}
_str _vcGetObjDir(_str cfg)
{
   int temp_view_id,orig_view_id;
   _str firstword='',objdir='';
   _str cfgdata=substr(cfg,pos('S0'),pos('0'));
   _str makefilename=_ProjectGet_AssociatedFile(_ProjectHandle());
   if (file_eq(_get_extension(makefilename,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      makefilename = getICProjAssociatedProjectFile(makefilename);
   }

   makefilename=_AbsoluteToProject(makefilename);
   int status=_open_temp_view(makefilename,temp_view_id,orig_view_id);
   if (status) {
      parse cfgdata with '-' firstword objdir;
      if (objdir!='') {
         objdir='.'FILESEP:+objdir;
      }
   } else {
      top();
      status=search('!(if|elseif)[ \t]+"\$\(cfg\)"[ \t]*==[ \t]*"'_escape_re_chars(cfgdata)'"','@ir');
      if (!status) {
         status=search("^INTDIR=",'@r');
         if (!status) {
            get_line(auto line);
            parse line with '=' objdir;
         } else {
            status=search('^\# PROP Output_Dir ','@r');
            if (!status) {
               get_line(auto line);
               parse line with '# PROP Output_Dir "' objdir '"';
            }
         }
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
   if (objdir != "") {
      if (last_char(objdir)!=FILESEP) {
         objdir=objdir:+FILESEP;
      }
   }
   return(objdir);
}

static _str VisualStudioVCPPExpandAllMacros(_str cfg,_str inputStr,_str inputFileName='', _str studio_version= '')
{
   _str vsproj_filename='';
   int status=_GetAssociatedProjectInfo(_project_name,vsproj_filename);
   _str ext=_get_extension(vsproj_filename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      vsproj_filename = absolute(getICProjAssociatedProjectFile(vsproj_filename),_strip_filename(_project_name,'N'));
      ext=_get_extension(vsproj_filename,1);
   }

   _str expandedMacro='';

   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      int vstudio_proj_handle = _xmlcfg_open(vsproj_filename,status);
      if (vstudio_proj_handle>=0) {
         int config_index=GetConfigIndexFromVCProj(vsproj_filename,cfg,vstudio_proj_handle);
         if ( config_index>=0 ) {
            if (studio_version == '') {
               int project_handle=_ProjectHandle();
               studio_version=_ProjectGet_CompilerConfigName(project_handle);
            }
            expandedMacro=_expand_all_vs_macros(studio_version,inputStr,
                                                vstudio_proj_handle,config_index,inputFileName);
         }
         _xmlcfg_close(vstudio_proj_handle);
      }
   } else if (file_eq(ext, VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      int vstudio_proj_handle = _xmlcfg_open(vsproj_filename,status,VSXMLCFG_OPEN_ADD_PCDATA);
      if (vstudio_proj_handle>=0) {
         
         int config_index=GetConfigIndexFromVCXProj(cfg,vstudio_proj_handle);
         if ( config_index>=0 ) {
            if (studio_version == '') {
               studio_version=COMPILER_NAME_VS2010;
            }
            expandedMacro=_expand_all_vs_macros(studio_version,inputStr,
                                                vstudio_proj_handle,config_index,inputFileName);
         }
         _xmlcfg_close(vstudio_proj_handle);
      }

   }
   return(expandedMacro);
}

_str _vcGetOutputDirFromVisualStudioProj(_str cfg)
{
   _str cfgdata=substr(cfg,pos('S0'),pos('0'));
   _str vsproj_filename='';
   int status=_GetAssociatedProjectInfo(_project_name,vsproj_filename);
   _str ext=_get_extension(vsproj_filename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      vsproj_filename = absolute(getICProjAssociatedProjectFile(vsproj_filename),_strip_filename(_project_name,'N'));
      ext=_get_extension(vsproj_filename,1);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      _str OutputDir='';
      GetItemFromVCProj(vsproj_filename,cfg,'OutputDirectory',OutputDir);
      return(OutputDir);
   }

   return GetOutputDirFromVS7StandardProj(vsproj_filename,cfg,ext);
}

_str GetVSStandardAppName(_str ext)
{
   if (file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT)) {
      return 'CSHARP';
   }
   if (file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT)) {
      return 'VisualBasic';
   }
   if (file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
      return 'ECSHARP';
   }
   if (file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT)) {
      return 'EVisualBasic';
   }
   if (file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)) {
      return 'VISUALJSHARP';
   }
   if (file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT)) {
      return 'FSHARP';
   }
   if (def_vs_msbuild_projects_ext != '') {
      _str exts = def_vs_msbuild_projects_ext;
      for (;;) {
         parse exts with auto msext ';' exts;
         if (msext == '') break;
         if (file_eq(ext, msext)) {
            return 'MSBUILD';
         }
      }
   }
   return '';
}

_str GetVSStandardExt(_str ext)
{
   if (file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
      return 'cs';
   }
   if (file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT) ||
       file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT)) {
      return 'vb';
   }
   if (file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT)) {
      return 'fs';
   }
   if (file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)) {
      return 'jsl';
   }

   return '';
}

static _str GetOutputDirFromWhidbeyStandardProj(int handle,_str cfg)
{
   typeless indexes[]=null;
   _xmlcfg_find_simple_array(handle,'/Project/PropertyGroup',indexes);
   if (!indexes._length()) {
      return ('');
   }

   int i;
   for (i=0;i<indexes._length();++i) {
      _str configurationCondition=_xmlcfg_get_attribute(handle,indexes[i],"Condition");

      if (pos("'"cfg"'",configurationCondition)) {
         //_str OutputDirectory=_xmlcfg_get_attribute(handle,configurationNode,"OutputPath");
         //return(OutputDirectory:+FILESEP);
         int outputNode=_xmlcfg_find_simple(handle,'OutputPath',indexes[i]);

         if (outputNode>=0) {
            int cdataNode=_xmlcfg_get_first_child(handle,outputNode,VSXMLCFG_NODE_PCDATA);

            if (cdataNode>=0) {
               return _xmlcfg_get_value(handle,cdataNode);
            }
         }
      }
   }

   return ('');
}

static _str GetOutputDirFromVS7StandardProj(_str vsproj_filename,_str cfg,_str ext)
{
   _str AppName=GetVSStandardAppName(ext);

   if (AppName:=='') {
      return '';
   }
   int i,status=0;
   int handle=_xmlcfg_open(vsproj_filename,status);
   if (handle<0) {
      return('');
   }
   // Get the configurations
   typeless indexes[]=null;
   _xmlcfg_find_simple_array(handle,'/VisualStudioProject/'AppName'/Build/Settings/Config',indexes);
   if (!indexes._length()) {
      _str output_dir=GetOutputDirFromWhidbeyStandardProj(handle,cfg);
      _xmlcfg_close(handle);
      return(output_dir);
   }

   for (i=0;i<indexes._length();++i) {
      _str curname=_xmlcfg_get_attribute(handle,indexes[i],"Name");
      if (curname==cfg) {
         _str OutputDirectory='';
         OutputDirectory=_xmlcfg_get_attribute(handle,indexes[i],"OutputPath");
         _xmlcfg_close(handle);
         return(OutputDirectory:+FILESEP);
      }
   }
   _xmlcfg_close(handle);
   return('');
}

#define DEFAULT_VCPP_OUTPUT_FILENAME '$(OutDir)/$(ProjectName).exe'
#define DEFAULT_VCPP_OUTDIR '$(SolutionDir)$(Configuration)'
#define DEFAULT_VCPP_PCH_FILENAME '$(IntDir)/$(TargetName).pch'
#define DEFAULT_VCPP_PDB_FILENAME '$(TargetDir)$(TargetName).pdb'

static int GetItemFromVCProj(_str vsproj_filename,_str cfg,_str item,_str &Output)
{
   // initialize the output
   Output='';

   int projHandle=-1;
   int status=0;
   if (projHandle<0) {
      projHandle=_xmlcfg_open(vsproj_filename,status);
   }
   if (projHandle<0) {
      return(projHandle);
   }

   status=0;
   int projCfgIndex=GetConfigIndexFromVCProj(vsproj_filename,cfg,projHandle);
   if ( projCfgIndex<0 ) {
      status=projCfgIndex;
      return -1;
   }

   switch (item) {
   case 'OutputFile':
      Output = getProjectCfgToolValue(projHandle,projCfgIndex,'VCLinkerTool','OutputFile',DEFAULT_VCPP_OUTPUT_FILENAME);
      break;

   case 'OutputDirectory':
      Output = getProjectCfgValue(projHandle,projCfgIndex,'OutputDirectory',DEFAULT_VCPP_OUTDIR);
      break;

   case 'PrecompiledHeaderFile':
      Output = getProjectCfgToolValue(projHandle,projCfgIndex,'VCCLCompilerTool','PrecompiledHeaderFile',DEFAULT_VCPP_PCH_FILENAME);
      break;

   case 'ProgramDatabaseFile':
      Output = getProjectCfgToolValue(projHandle,projCfgIndex,'VCLinkerTool','ProgramDatabaseFile',DEFAULT_VCPP_PDB_FILENAME);
      break;
   }
   // translate any output that we got
   if (Output != '') {
      Output = VisualStudioVCPPExpandAllMacros(cfg,Output);
   }
   // close the xml file
   if (projHandle >= 0) {
      _xmlcfg_close(projHandle);
   }
   return 0;
}

#define DEFAULT_VCXPROJ_OUTPUT_FILENAME '$(OutDir)$(TargetName)$(TargetExt)'
#define DEFAULT_VCXPROJ_OUTDIR '$(SolutionDir)$(Configuration)\'
#define DEFAULT_VCXPROJ_PLATFORM_OUTDIR '$(SolutionDir)$(Platform)\$(Configuration)\'
#define DEFAULT_VCXPROJ_PCH_FILENAME '$(IntDir)$(TargetName).pch'
#define DEFAULT_VCXPROJ_PDB_FILENAME '$(TargetDir)$(TargetName).pdb'

static int GetItemFromVCXProj(_str vsproj_filename,_str config,_str item,_str &output)
{
   int status=0;
   int handle=_xmlcfg_open(vsproj_filename,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (handle<0) {
      return(handle);
   }
   output = '';
   status = 0;
   _str value = '';
   int itemIndex = _xmlcfg_find_simple(handle, "/Project/ItemDefinitionGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]");
   int index = -1;
   int data = -1;
   switch (item) {
   case 'OutputFile':
      if (itemIndex < 0) {
         status = index;
         break;
      }
      index = _xmlcfg_find_simple(handle, "Link/OutputFile", itemIndex);
      if (index < 0) {
         value = DEFAULT_VCXPROJ_OUTPUT_FILENAME;
         break;
      }
      data = _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
      if (data < 0) {
         break;
      }
      value = _xmlcfg_get_value(handle, data);
      break;

   case 'OutputDirectory':
      index = _xmlcfg_find_simple(handle, "/Project/PropertyGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]/OutDir");
      if (index < 0) {
         parse config with auto Configuration '|' auto Platform;
         if (Platform == "Win32") {
            value = DEFAULT_VCXPROJ_OUTDIR;
         } else {
            value = DEFAULT_VCXPROJ_PLATFORM_OUTDIR;
         }
         break;
      }
      data = _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
      if (data < 0) {
         break;
      }
      value = _xmlcfg_get_value(handle, data);
      _maybe_append_filesep(value);
      break;

   case 'PrecompiledHeaderFile':
      if (itemIndex < 0) {
         status = index;
         break;
      }
      index = _xmlcfg_find_simple(handle, "ClCompile/PrecompiledHeaderOutputFile", itemIndex);
      if (index < 0) {
         value = DEFAULT_VCXPROJ_PCH_FILENAME;
         break;
      }
      data = _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
      if (data < 0) {
         break;
      }
      value = _xmlcfg_get_value(handle, data);
      break;

   case 'ProgramDatabaseFile':
      if (itemIndex < 0) {
         status = index;
         break;
      }
      index = _xmlcfg_find_simple(handle, "Link/ProgramDatabaseFile", itemIndex);
      if (index < 0) {
         value = DEFAULT_VCXPROJ_PDB_FILENAME;
         break;
      } 
      data = _xmlcfg_get_first_child(handle, index, VSXMLCFG_NODE_PCDATA);
      if (data < 0) {
         break;
      }
      value = _xmlcfg_get_value(handle, data);
      break;
   }

   output = VisualStudioVCPPExpandAllMacros(config, value);
   _xmlcfg_close(handle);
   return(status);
}

static int GetOutputFilenameFromWhidbeyProj(int handle,_str cfg,_str &outputFilename)
{
   _str outputPath=GetOutputDirFromWhidbeyStandardProj(handle,cfg);
   _str outputType='';
   _str assemblyName='';

   typeless indexes[]=null;
   _xmlcfg_find_simple_array(handle,'/Project/PropertyGroup',indexes);
   if (!indexes._length()) {
      return (0);
   }

   int i;
   for (i=0;i<indexes._length();++i) {
      int configurationNode=_xmlcfg_find_simple(handle,'Configuration',indexes[i]);
      if (configurationNode>=0) {
         int cdataNode=_xmlcfg_get_first_child(handle,configurationNode,VSXMLCFG_NODE_PCDATA);
         if (cdataNode>=0) {
            _str short_config=_xmlcfg_get_value(handle,cdataNode);
            if (short_config:!='' && pos(short_config,cfg)) {
               int outputTypeNode=_xmlcfg_find_simple(handle,'OutputType',indexes[i]);
               if (outputTypeNode>=0) {
                  cdataNode=_xmlcfg_get_first_child(handle,outputTypeNode,VSXMLCFG_NODE_PCDATA);
                  if (cdataNode>=0) {
                     outputType=_xmlcfg_get_value(handle,cdataNode);
                  }
               }
               int assemblyNameNode=_xmlcfg_find_simple(handle,'AssemblyName',indexes[i]);
               if (assemblyNameNode>=0) {
                  cdataNode=_xmlcfg_get_first_child(handle,assemblyNameNode,VSXMLCFG_NODE_PCDATA);
                  if (cdataNode>=0) {
                     assemblyName=_xmlcfg_get_value(handle,cdataNode);
                  }
               }
               // stop searching
               i=indexes._length();
            }
         }
      }
   }

   _str outputExt='';
   switch (outputType) {
   case 'WinExe':
   case 'Exe':
      outputExt='.exe';break;
   case 'Library':
      outputExt='.dll';break;
   default:
      break;
   }

   if (outputPath:!='' && assemblyName:!='' && outputExt:!='') {
      outputFilename=_AbsoluteToProject(outputPath:+assemblyName:+outputExt);
   }

   return 0;
}

static int GetOutputFilenameFromStudioStandardProj(_str vsproj_filename,_str cfg,_str &outputFilename,int handle=-1)
{
   boolean close_handle=handle==-1;
   int status=0;
   if ( handle<0 ) {
      handle=_xmlcfg_open(vsproj_filename,status,VSXMLCFG_OPEN_ADD_PCDATA);
   }
   if ( handle<0 ) {
      return(handle);
   }
   _str ext=_get_extension(vsproj_filename,true);
   _str lang_piece=GetVSStandardAppName(ext);
   if (lang_piece:=='') {
      if ( close_handle )_xmlcfg_close(handle);
      return 0;
   }

   _str settings_query="/VisualStudioProject/"lang_piece"/Build/Settings";
   int setting_index=_xmlcfg_find_simple(handle,settings_query);

   if (setting_index<0) {
      int ret_value=GetOutputFilenameFromWhidbeyProj(handle,cfg,outputFilename);
      if ( close_handle )_xmlcfg_close(handle);
      return ret_value;
   }
   _str config_query="/VisualStudioProject/"lang_piece"/Build/Settings/Config[@Name='"cfg"']";
   int config_index=_xmlcfg_find_simple(handle,config_query);

   _str assemblyName=_xmlcfg_get_attribute(handle,setting_index,"AssemblyName");
   _str outputType=_xmlcfg_get_attribute(handle,setting_index,"OutputType");

   _str outputPath=_xmlcfg_get_attribute(handle,config_index,"OutputPath");

   _str outputExt='';
   switch (outputType) {
   case 'WinExe':
   case 'Exe':
      outputExt='.exe';break;
   case 'Library':
      outputExt='.dll';break;
   }

   if ( setting_index<0 ) {
      if ( close_handle )_xmlcfg_close(handle);
      return(setting_index);
   }

   outputFilename=_AbsoluteToProject(outputPath:+assemblyName:+outputExt);
   if ( close_handle )_xmlcfg_close(handle);

   return(0);
}
static int GetConfigIndexFromVCProj(_str vsproj_filename,_str cfg, int handle)
{
   int i,status=0;

   typeless indexes[]=null;
   _xmlcfg_find_simple_array(handle,'/VisualStudioProject/Platforms/Platform',indexes);
   if (!indexes._length()) {
      return(-1);
   }

   // Get the configurations
   _xmlcfg_find_simple_array(handle,'/VisualStudioProject/Configurations/Configuration',indexes);
   for (i=0;i<indexes._length();++i) {
      _str curname=_xmlcfg_get_attribute(handle,indexes[i],"Name");
      if (curname==cfg) {
         return(indexes[i]);
      }
   }

   return(-1);
}

static int GetConfigIndexFromVCXProj(_str cfg, int handle)
{
   return _xmlcfg_find_simple(handle,'/Project/ItemGroup/ProjectConfiguration[@Include="'cfg'"]');
}

_str _generate_objs_list(_str obj_list,_str lib_list,_str pre_object_libs)
{
   obj_list=strip(obj_list);
   obj_list=translate(obj_list,FILESEP,FILESEP2);

   // look for objects duplicated in the lib_list
   _str new_object_list='';
   // this will allow searching for ' 'test_obj' ' without having to worry about
   // the first or last items of the list or 'bb.obj' matching 'aabb.obj'
   lib_list= ' 'lib_list' ';
   lib_list=translate(lib_list,FILESEP,FILESEP2);

   while (obj_list!='') {
      _str test_obj = parse_next_option(obj_list);
      if (!pos(' 'test_obj' ',lib_list)) {
         strappend(new_object_list,' ');
         strappend(new_object_list,test_obj);
      }
   }

   // remove the added spaces
   lib_list=strip(lib_list);

   _str output='';
   while ((pre_object_libs>0)&&(lib_list!='')) {
      strappend(output,' ');
      strappend(output,parse_next_option(lib_list));
      --pre_object_libs;
   }

   strappend(output,' 'new_object_list' 'lib_list);

   return strip(output);
}

#define VCPP_OUTPUT_DIR_PREFIX "# PROP Output_Dir \""

_str _vcGetOutputDirFromDSP(_str cfg)
{
   _str cfgdata=substr(cfg,pos('S0'),pos('0'));
   _str dsp_filename;
   int status=_GetAssociatedProjectInfo(_project_name,dsp_filename);
   if (status || dsp_filename=='') {
      return('');
   }
   int temp_view_id,orig_view_id;
   status=_open_temp_view(dsp_filename,temp_view_id,orig_view_id);
   if (status) {
      return('');
   }
   status=search('^\!(IF|ELSEIF) @"\$\(CFG\)" == "'cfgdata'"','@r');
   if (status) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return('');
   }
   status=search('^'_escape_re_chars(VCPP_OUTPUT_DIR_PREFIX)'?@$','@r');
   if (status) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return('');
   }
   get_line(auto line);
   _str outputdir;
   parse line with (VCPP_OUTPUT_DIR_PREFIX) outputdir;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   outputdir=strip(outputdir,'B','"');
   outputdir=_RelativeToProject(outputdir,dsp_filename);
   if (outputdir!='') {
      if (last_char(outputdir)!=FILESEP) {
         outputdir=outputdir:+FILESEP;
      }
   }
   return(outputdir);
}
/**
 * Substitues VSE Project style embedded environment variables
 * in the format %(ENVVAR) with corresponding value.
 *
 * @param string Input string.
 * @return Return string with %(ENVVAR) specifications replaced
 *         with values.
 * @see _replace_envvars
 */
_str _replace_envvars2(_str string)
{
   int j=1;
   int len=0;
   for (;;) {
      j=pos('%',string,j);
      if ( ! j ) {
         break;
      }
      _str s='';
      _str ch=substr(string,j+1,1);
      if ( ch=='(' ) {
         int k=pos(')',string,j+1);
         len=2;
         s='%(';
         if (k) {
            len=k-j+1;
            _str envvar_name=substr(string,j+2,len-3);
            s=get_env(envvar_name);
         }
      } else {
         len=1;
         s='%';
      }
      string=substr(string,1,j-1):+s:+substr(string,j+len);
      j=j+length(s);
   }
   return(string);
}
static _str _ppc_getObjectDir(_str &configName,_str project_name,_str config,int handle) {
   if (project_name=='') {
      configName='';
      return '';
   }

   ProjectConfig configList[];
   int associated;
   getProjectConfigs(project_name,configList, associated);

   // make copy of config because it may have to be changed
   configName = config;

   // get output dir from project
   _str outputDir = _ProjectGet_ObjectDir(handle, configName);

   if (!configExists(configName,configList)) {
      // The active configuration is not set in the project.
      // Get the configuration list and default to the first one.
      configName = "";
      if (configList._length()) {
         configName = configList[0].config;
         outputDir = _ProjectGet_ObjectDir(handle, configName);
      }
   }

   // convert objdir fileseps to appropriate platform in case they were created on a different one
   outputDir = stranslate(outputDir, FILESEP, FILESEP2);
   return outputDir;
}
/**
 * Used to generate a compile command which needs parts of the buffer
 * name (<i>buf_name</i>), the project name (<i>project_name</i>), or
 * the current word (<i>cword</i>) inserted.  The rules for substituting
 * these parts into the command are:
 *
 * <dl> 
 * <dt>%AP</dt><dd>The 3rd party project file name, for 
 * associated projects</dd> 
 * <dt>%AW</dt><dd>The 3rd party workspace file name, for 
 * associated workspaces</dd>  
 * <dt>%B</dt><dd>Configuration</dd>
 * <dt>%BD</dt><dd>Configuration build directory</dd>
 * <dt>%BN</dt><dd>Configuration name.  Same as %B option except
 * for Visual C++ configuration names where
 * configuration names are of the form
 * CFG="[ConfigName]" or [ConfigName]|[Platform].</dd>
 * <dt>%BP</dt><dd>Platform name from Visual C++ configuration
 * [ConfigName]|[Platform].</dd>
 * <dt>%C</dt><dd>Current word</dd>
 * <dt>%CP</dt><dd>Java class path including <b>-classpath</b>.</dd>
 * <dt>%DEFD</dt><dd>Configuration defines with dashes.  Example: %DEFD, 
 * project def = 'test' produces '"-Dtest"</dd>
 * <dt>%DEFS</dt><dd>Configuration defines with slashes.  Example: %DEFS, 
 * project def = 'test' produces '"/Dtest"</dd>
 * <dt>%DM</dt><dd>The file name only of the current buffer.</dd>
 * <dt>%E</dt><dd>File extension with dot</dd>
 * <dt>%F</dt><dd>Absolute filename</dd>
 * <dt>%H</dt><dd>(Java only) Builds a temp HTML file to run the compiled applet, 
 * %H is replaced by the temp HTML file name.</dd>
 * <dt>%I</dt><dd>Absolute include directories (individually listed) including 
 * '-i'.  Example: '-ic:\folder1 -ic:\folder2'</dd> 
 * <dt>%IR</dt><dd>Relative include directories (to the project) including '-I', 
 * seperated by semicolons.  Example: '-Ic:\folder1;c:\folder2'</dd> 
 * <dt>%IN</dt><dd>Absolute include directories (individually listed) including 
 * '-i '.  Example: '-i c:\folder1 -i c:\folder2'</dd> 
 * <dt>%JBD</dt><dd>Java build directory including -d.</dd>
 * <dt>%LF</dt><dd>Current buffer name.</dd>
 * <dt>%LIBS</dt><dd>Libraries space delimited.</dd>
 * <dt>%M</dt><dd>Calls a macro function.  Any return value is included in the 
 * build command. Must be terminated by a matching %.   Example: %Mmy_function%, 
 * where my_function() is a macro function.</dd> 
 * <dt>%N</dt><dd>Filename without extension or path</dd>
 * <dt>%O</dt><dd>Output filename.  Currently only GNU projects
 * have an output filename on the Link Tab.</dd>
 * <dt>%OBJS</dt><dd>Project objects (including libraries).</dd>
 * <dt>%OE</dt><dd>Output extension with dot</dd>
 * <dt>%ON</dt><dd>Output filename with no extension or path</dd>
 * <dt>%OP</dt><dd>Output path</dd>
 * <dt>%P</dt><dd>Path of current file</dd>
 * <dt>%Q#</dt><dd>The current file's path (no file name) starting with the folder item
 * indicated by #.  Example: %Q2, current file = 'c:\a\b\c\d\test.txt' produces 
 * '\b\c\d\'</dd> 
 * <dt>%R</dt><dd>Absolute project name</dd>
 * <dt>%RE</dt><dd>Project extension</dd>
 * <dt>%RM</dt><dd>Project display name (for associated workspaces).</dd>
 * <dt>%RN</dt><dd>Project filename without extension or path</dd>
 * <dt>%RP</dt><dd>Project path</dd>
 * <dt>%RV</dt><dd>(Windows only) Project drive with :</dd>
 * <dt>%RW</dt><dd>Project working directory</dd>
 * <dt>%T</dt><dd>Project configuration target</dd>
 * <dt>%V</dt><dd>(Windows Only) Drive of current file with :</dd>
 * <dt>%W</dt><dd>Absolute workspace filename</dd>
 * <dt>%WE</dt><dd>Workspace extension with dot</dd>
 * <dt>%WN</dt><dd>Workspace filename with no extension or path</dd>
 * <dt>%WP</dt><dd>Workspace path</dd>
 * <dt>%WV or %WD</dt><dd>Workspace drive with :</dd>
 * <dt>%WX</dt><dd>The workspace folder name only.  Example: %WX, 
 * workspace = 'c:\a\b\c\workspace.vpw' produces 'c'.</dd>
 * <dt>%XUP </dt><dd>Translate all back slashes that follow to forward
 * slashes (UNIX file separator)</dd>
 * <dt>%XWP</dt><dd>Translate all forward slashes to back slashes
 * (Windows file separator)</dd>
 * <dt>%-#</dt><dd>Removes the previous # characters.</dd>
 * <dt>%(envvar)</dt><dd>Value of environment variable envvar</dd>
 * <dt>%#</dt><dd>The # item in argline (items are seperated by spaces).</dd>
 * <dt>%{*.*}</dt><dd>A list of project files matching the pattern in braces.</dd>
 * <dt>%[regkey]</dt><dd>Value of Windows registry entry. 
 *              example:
 *              %[HKLM:\Software\Microsoft\Communicator@InstallationDirectory]</dd>
 * <dt>%?</dt><dd>Prompts the user for a value.  The 
 * user input is then included in the build command. Must be 
 * terminated by a matching %. Example: %?Prompt text%, 
 * would prompt the user with the text 'Prompt text'.</dd> 
 * <dt>%%</dt><dd>Percent character</dd>
 * </dl>
 *
 * @return The resulting command is returned.
 *
 * @example
 * <pre>
 *           defmain()
 *           {
 *                // The message displayed is the same as 'cc -c':+p_buf_name
 *                message(_parse_project_command('%f',_project_current(p_buf_name),'');
 *           }
 * </pre>
 *
 * @categories Miscellaneous_Functions
 *
 */
_str _parse_project_command(_str command,_str buf_name,
                            _str project_name,_str cword,_str argline='',
                            _str ToolName='',_str ClassPath='', int* recursionStatus = null,
                            _str (*recursionMonitorHash):[] = null,
                            int handle=0,_str config='',
                            _str outputFile='')
{
   int recLocalStatus = 0;
   _str recLocalHash:[];
   if (recursionMonitorHash == null) {
      recursionMonitorHash= &recLocalHash;
   }
   if (recursionStatus==null) {
      recursionStatus= &recLocalStatus;
   }

/*
 * 12:37pm 7/16/1999
 * Important!!!!
 * From now on when we change this function, we must consider whether to
 * duplicate the functionality in _parse_project_command in vsbuild.cpp
 * <P>
 * Note - this function is also used to parse print commands.
 */
   if (project_name!='' && _workspace_filename!='' && (handle==0 || config=='')) {
      _ProjectGet_ActiveConfigOrExt(project_name,handle,config);
   }

   _str s = "";
   _str lastOption = "";
   _str ext="";
   _str member,dsname;
   _str info,dirname;
   boolean recurseRepString = false;
   boolean forceUnixFileSeps = false;
   int i,j=1,k;

   for (;;) {
      // reset the recursion information
      recurseRepString = false;
      lastOption = "";

      j=pos(PARSE_CHAR,command,j);
      if ( ! j ) {
         break;
      }
      _str ch=upcase(substr(command,j+1,1));
      _str ch2='';
      int len=2;
      if ( ch=='P' ) {
         s=_strip_filename(buf_name,'N');
      } else if ( ch=='Q' ) {
         _str count=substr(command,j+2,1);
         if (!isinteger(count)) {
            s='';
         } else {
            len=3;
            s=_strip_filename(buf_name,'N');
#if _NAME_HAS_DRIVE
            s=_strip_filename(s,'D');
            --count;
#endif
            while (count>0) {
               parse substr(s,2) with (FILESEP) +0 s ;
               --count;
            }
         }
      } else if (ch=='D') {
         if (upcase(substr(command,j+2,2))=='EF') {
            if (project_name != "") {
               _str ch4=upcase(substr(command,j+4,1));
               if (ch4 == 'S' || ch4 == 'D') {
                  s='';
                  len=5;
                  _str rep_char='/';
                  if (ch4=='D') {
                     rep_char='-';
                  }

                  lastOption = "%def";
                  // attempt to prevent infinite loops by checking to see if this variable has
                  // already been replaced during recursion
                  if (recursionMonitorHash != null && (*recursionMonitorHash):[lastOption] == 1) {
                     _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", lastOption));
                     if (recursionStatus != null) {
                        *recursionStatus = -1;
                     }
                     return "";
                  }

                  _str temp_s=_ProjectGet_Defines(handle,config);
                  while (temp_s!='') {
                     _str define=parse_next_option(temp_s,false);
                     define=stranslate(define, '\\\"', '\"');  // add escapes for quotes
                     if (s!='') {
                        strappend(s,' ');
                     }
                     _str lead_char=substr(define,1,1);
                     if (lead_char=='/' || lead_char=='-') {
                        strappend(s,'"':+rep_char:+substr(define,2):+'"');
                     } else {
                        strappend(s,'"':+define:+'"');
                     }
                  }
                  recurseRepString = true;
               }
            }
         } else {
            ch2=upcase(substr(command,j+2,1));
            len=2;
            s="";
            switch (ch2) {
            case 'Q':
               len=3;
               member=_DataSetMemberOnly(buf_name);
               dsname=_DataSetNameOnly(buf_name);
               _str digit=substr(command,j+3,1);
               if (isdigit(digit)) {
                  len=4;
                  _str result='';
                  while (digit-- >0) {
                     _str before;
                     parse dsname with before '.' dsname;
                     if (before=='') {
                        break;
                     }
                     result=before;
                  }
                  dsname=result;
               }
               s=dsname;
               break;
            case 'M':  // member
               len=3;
               s=_strip_filename(buf_name,'P');
               break;
            case 'S':  // ds.name
               len=3;
               member=_DataSetMemberOnly(buf_name);
               dsname=_DataSetNameOnly(buf_name);
               digit=substr(command,j+3,1);
               if (isdigit(digit)) {
                  len=4;
                  while (digit-- >0) {
                     dsname=_strip_filename(dsname,'E');
                  }
               }
               s=dsname;
               break;
            case 'F':  // ds.name
               len=3;
               member=_DataSetMemberOnly(buf_name);
               dsname=_DataSetNameOnly(buf_name);
               if (member!='') {
                  s='"'dsname'('member')"';
               } else {
                  s='"'dsname'"';
               }
            }
         }
      } else if ( ch=='F' ) {
         if (_DataSetIsFile(buf_name)) {
            ch2=upcase(substr(command,j+2,1));
            ext='';
            if (ch2=='.') {
               i=pos('[ %]|$',command,j+3,'r');
               ext=substr(command,j+2,i-(j+2));
            }
            member=_DataSetMemberOnly(buf_name);
            dsname=_DataSetNameOnly(buf_name);
            len+=length(ext);
            if (strieq(ext,'.o')) ext='.obj';
            if (strieq(ext,'.s')) ext='.asm';
            if (buf_name=='') {
               s='';
            } else {
               if (ext!='') {
                  dsname=dsname:+ext;
               }
               if (_DataSetIsMember(buf_name)) {
                  s="\"//'"dsname"("member")'\"";
               } else {
                  s="\"//'"dsname"'\"";
               }
            }
         } else {
            s=buf_name;
         }
      } else if ( ch=='N' ) {
         if (_DataSetIsFile(buf_name)) {
            ch2=upcase(substr(command,j+2,1));
            ext='';
            boolean done=false;
            if (ch2=='.') {
               i=pos('[ %]|$',command,j+3,'r');
               ext=substr(command,j+2,i-(j+2));
            } else if (upcase(substr(command,j+2,2))=='%E') {
               member=_DataSetMemberOnly(buf_name);
               dsname=_DataSetNameOnly(buf_name);
               len+=2;
               if (_DataSetIsMember(buf_name)) {
                  s="\"//'"dsname"("member")'\"";
               } else {
                  s="\"//'"dsname"'\"";
               }
               done=1;
            }
            if (!done) {
               member=_DataSetMemberOnly(buf_name);
               dsname=_DataSetNameOnly(buf_name);
               len+=length(ext);
               if (strieq(ext,'.o')) ext='.obj';
               if (strieq(ext,'.s')) ext='.asm';
               if (buf_name=='') {
                  s='';
               } else {
                  dsname=_strip_filename(dsname,'E');
                  if (ext!='') {
                     dsname=dsname:+ext;
                  }
                  if (_DataSetIsMember(buf_name)) {
                     s="\"//'"dsname"("member")'\"";
                  } else {
                     s="\"//'"dsname"'\"";
                  }
               }
            }
         } else {
            //say('h2 buf_name='buf_name);
            s=_strip_filename(buf_name,'PE');
         }
      } else if ( ch=='M') {
         k= pos('[A-Za-z0-9_]',command,j+2,'r');
         if (!k) {
            return(command);
         }
         int l= pos('%',command,k);
         if (!l) {
            return(command);
         }
         int w= l-k;
         _str macCommand= substr(command,k,w);
         //messageNwait("macName "macName);
         _str fctname,cmdline;
         parse macCommand with fctname cmdline;
         int index=find_index(fctname,PROC_TYPE|COMMAND_TYPE);
         if (!index) {
            // if we can't find the index, then try to run execute on it
            // unfortunately, the parameters have to be thrown out and we 
            // can't check return values
            execute(fctname);
         } else {
            s=call_index(cmdline,index);
         }
         len= l-j+1;
      } else if ( ch=='?' ) {
         k= pos('[A-Za-z0-9_]',command,j+2,'r');
         if (!k) {
            return(command);
         }
         int l= pos('%',command,k);
         if (!l) {
            return(command);
         }
         int w = l-k;
         _str prompt= substr(command,k,w);
         int promptResult = textBoxDialog("SlickEdit", 0, 0, "", "Ok,Cancel:_cancel", "", prompt" :");
         if (promptResult != COMMAND_CANCELLED_RC) {
            s = maybe_quote_filename(_param1);
         }
         len= l-j+1;
      } else if ( ch=='E' ) {
         s=_get_extension(buf_name,1);
      } else if (ch=='R') {
         ch2=upcase(substr(command,j+2,1));
         switch (ch2) {
         case 'D':
         case 'V':
            len=3;
            s=project_name;
            if ( substr(s,2,1)==':' ) {
               s=substr(s,1,2);
            } else {
               s='';
            }
            break;
         case 'E':
            len=3;
            s=_get_extension(project_name,1);
            break;
         case 'N':
            len=3;
            s=_strip_filename(project_name,'PE');
            break;
         case 'P':
            len=3;
            s=_strip_filename(project_name,'N');
            break;
         case 'M':
            len=3;
            s=GetProjectDisplayName(project_name);
            break;
         case 'W': {
               s='';

               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%rw"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%rw"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               // retrieve the project working directory
               _str projectWorkingDir = "";
               projectWorkingDir=_ProjectGet_WorkingDir(handle);
               if (projectWorkingDir != "") {
                  // absolute the directory (relative to project dir)
                  projectWorkingDir = absolute(projectWorkingDir, _strip_filename(project_name, 'N'));
               }
               // Project work dir %rw is inconsistant. If user puts trailing slash,
               // then it gets a trailing slash. If not, then it doesn't. 
               // IMO This should be changed and the working dir should be stored normalized or
               // anything that fetches this should normalize it.

               len=3;
               s = projectWorkingDir;

               // set recursion info
               recurseRepString = true;
               lastOption = "%rw";

               break;
            }
         default:
            s=project_name;
         }
      } else if (ch=='A') {
         // Associated projects and workspace names
         ch2=upcase(substr(command,j+2,1));
         switch(ch2) {
         case 'P':
            {
               len=3;
               s = _ProjectGet_AssociatedFile(handle);
            }
            break;
         case 'W':
            {
               len=3;
               _str workspace_filename='';
               if (_IsWorkspaceAssociated(_workspace_filename, workspace_filename)) {
                  s = workspace_filename;
               } else {
                  s = '';
               }
            }
            break;
         default:
            break;
         }

      } else if (ch=='-') {
         //ch2=upcase(substr(command,j+2,1));
         s='';
         int count=0;
         while (isdigit(substr(command,j+2+count,1))) {
            ++count;
         }
         ch2=substr(command,j+2,count);
         if (count) {
            if (j<=ch2) {
               ch2=j-1;
            }
            command=substr(command,1,j-1-(int)ch2):+substr(command,j);
            j-=(int)ch2;
            len=2+count;
         } else {
            len=2;
         }
      } else if (ch=='W') {
         _str workspace_filename='';
         if (!_IsWorkspaceAssociated(_workspace_filename, workspace_filename)) {
            workspace_filename=_workspace_filename;
         }
         ch2=upcase(substr(command,j+2,1));
         switch (ch2) {
         case 'D':
         case 'V':
            len=3;
            s=workspace_filename;
            if ( substr(s,2,1)==':' ) {
               s=substr(s,1,2);
            } else {
               s='';
            }
            break;
         case 'E':
            len=3;
            s=_get_extension(workspace_filename,1);
            break;
         case 'N':
            len=3;
            s=_strip_filename(workspace_filename,'PE');
            break;
         case 'P':
            len=3;
            s=_strip_filename(workspace_filename,'N');
            break;
         case 'X':
            len=3;
            s=_strip_filename(workspace_filename,'N');
            if (last_char(s):==FILESEP) {
               s=substr(s,1,length(s)-1);
            }
            s=_strip_filename(s,'P');
            break;
         default:
            s=workspace_filename;
            break;
         }
      } else if (ch=='C') {
         ch2=upcase(substr(command,j+2,1));
         if (ch2=='P') {
            s='';

            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%cp"] == 1) {
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%cp"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            _str cp = ClassPath;
            if (cp == null) cp = "";
            /*
               Only add the source path if we are doing a build.  If we add the build output directory,
               then there are problems when a class is moved and the only .class file still exists.
            */
            if (strieq(ToolName,'compile') || // Java compile hits this code path
                strieq(ToolName,'View Javadoc') || //Never get here
                strieq(ToolName,'Javadoc All') || //Never get here
                strieq(ToolName,'build') || //Never get here
                strieq(ToolName,'rebuild')  //Never get here
               ) {
               // Only add project directory.  This assumes it is the correct root of the source
               // which it might not be.
               _str projectdir = _strip_filename(project_name,'N');
               if (projectdir!='') {
                  if (cp != "") _maybe_append(cp, PATHSEP);
                  cp = cp :+ projectdir;
               }
            } else {
               // Append the build output directory and the project directory.

               // get the build directory by recursively processing %bd
               (*recursionMonitorHash):["%cp"] = 1;
               _str builddir = _parse_project_command("%bd", buf_name, project_name, cword, argline,
                                                      ToolName, ClassPath, recursionStatus, recursionMonitorHash);
               (*recursionMonitorHash):["%cp"] = 0;

               // append %bd to the classpath to ensure it searches wherever the class files were built
               if (builddir != "") {
                  if (cp != "") _maybe_append(cp, PATHSEP);
                  cp = cp :+ builddir;
               }

               // append %rp to the classpath to ensure that images and other things that are
               // not located in the classes dir can be found.  if the build dir is the
               // same as the project dir, there is no need to do this
               _str projectdir = _strip_filename(project_name,'N');
               if (!file_eq(absolute(builddir, projectdir), projectdir)) {
                  if (cp != "") _maybe_append(cp, PATHSEP);
                  cp = cp :+ projectdir;
               }
            }

            // if the classpath is not empty, build the full option
            if (cp != "") {
               cp = "-classpath " maybe_quote_filename(cp);
            }

            len=3;
            s = cp;

            // set recursion info
            recurseRepString = true;
            lastOption = "%cp";

         } else {
            s=cword;
         }
      } else if (ch=='I') {
         s='';
         ch2 = upcase(substr(command, j+2, 1));
         if (ch2 == 'R') {
            len = 3;
            // replace with includes that have been made relative to project dir

            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%i"] == 1) {
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%i"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            if (project_name!='') {
               info = _ProjectGet_IncludesList(handle, config);
               info=_relative_includedirs(info,project_name);
               for (;;) {
                  if (info=='') break;
                  parse info with dirname PATHSEP info;
                  dirname=strip(dirname,'T',FILESEP);
                  dirname=strip(dirname,'T',FILESEP2);
                  s=s:+'-I' maybe_quote_filename(dirname) ' ';
               }
            }

            // set recursion info
            recurseRepString = true;
            lastOption = "%i";
         } else if (ch2=='N') {
            // replace with includes that have been made absolute
            len = 3;
            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%in"] == 1) {
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%in"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            if (project_name!='') {
               info = _ProjectGet_IncludesList(handle, config);
               info=_absolute_includedirs(info,project_name, recursionStatus, recursionMonitorHash);
               for (;;) {
                  if (info=='') break;
                  parse info with dirname PATHSEP info ;
                  dirname=strip(dirname,'T',FILESEP);
                  dirname=strip(dirname,'T',FILESEP2);
                  s=s:+'-i ' maybe_quote_filename(dirname) ' ';
               }
            }

            // set recursion info
            recurseRepString = true;
            lastOption = "%in";
         } else {
            // replace with includes that have been made absolute

            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%i"] == 1) {
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%i"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            if (project_name!='') {
               info = _ProjectGet_IncludesList(handle, config);
               info=_absolute_includedirs(info,project_name, recursionStatus, recursionMonitorHash);
               for (;;) {
                  if (info=='') break;
                  parse info with dirname PATHSEP info ;
                  dirname=strip(dirname,'T',FILESEP);
                  dirname=strip(dirname,'T',FILESEP2);
                  s=s:+'-I' maybe_quote_filename(dirname) ' ';
               }
            }

            // set recursion info
            recurseRepString = true;
            lastOption = "%i";
         }
      } else if (ch=='O') {
         _str absOutputFile=(outputFile != '') ? outputFile : '';
         s = '';
         if (project_name != '') {
            ch2 = upcase(substr(command, j+2, 1));
            if (absOutputFile == '') {
               _str associatedProject=_ProjectGet_AssociatedFile(_ProjectHandle(project_name));
               if (file_eq(_get_extension(associatedProject,true),VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
                  associatedProject = getICProjAssociatedProjectFile(associatedProject);
               }
               if ( associatedProject!='' && _IsVisualStudioProjectFilename(associatedProject) ) {
                  _str outputDir='';
                  _GetExeFromVisualStudioFile(associatedProject,config,outputDir);
                  info=absOutputFile=absolute(outputDir,_file_path(project_name));
               } else {
                  if (_isMac()) {
                     //Xcode projects are associated to the .xcode/.xcodeproj bundle directory
                     if ( associatedProject!='' && _IsXcodeProjectFilename(associatedProject)) {
                        _str absOutputPath;
                        info=_xcode_get_output_file(project_name,associatedProject,config,absOutputPath);
                     } else {
                        info=_ProjectGet_OutputFile(handle,config);
                     }
                  } else {
                     info=_ProjectGet_OutputFile(handle,config);
                  }
                  // parse the output dir for %placeholders.  necessary for %on and %op
                  int x=pos(ch2,'npeb',1,'i');
                  if (x>0) {
                     lastOption='%o':+substr('npeb',x,1);
                  } else {
                     lastOption='%o';
                  }
                  if (recursionMonitorHash != null && (*recursionMonitorHash):[lastOption] == 1) {
                     _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", lastOption));
                     if (recursionStatus != null) {
                        *recursionStatus = -1;
                     }
                     return "";
                  }
                  (*recursionMonitorHash):[lastOption] = 1;
                  absOutputFile=_parse_project_command(info, buf_name, project_name, cword, argline,
                                                      ToolName, ClassPath, recursionStatus, recursionMonitorHash);
                  /* 
                     For consistency, %o always returns a path. Make it absolute to the build directory.
                  */ 
                  _str outputPath=_parse_project_command("%bd",buf_name,project_name,cword,argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash);
                  (*recursionMonitorHash):[lastOption] = 0;
                  absOutputFile=absolute(absOutputFile,outputPath);
               }
            }
            switch (ch2) {
            case 'N':
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%on"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%on"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               len = 3;
               s = _strip_filename(absOutputFile, 'PE');

               // set recursion info
               recurseRepString = true;
               lastOption = "%on";

               break;

            case 'P':
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%op"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%op"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               len = 3;
               s = _strip_filename(absOutputFile, 'N');

               // set recursion info
               recurseRepString = true;
               lastOption = "%op";

               break;

            case 'E':
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%oe"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%oe"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

#if 0
               If we still need this, make up a new % option for rules
               // look for a compile command that applies to the current buffer
               _str outputExtension = "";
               getExtSpecificCompileInfo(buf_name, _ProjectHandle(project_name), GetCurrentConfigName(),
                                         "", outputExtension, auto compileRuleTargetNode=0, auto linkObject=false, true);


               // remove the wildcard
               if (first_char(outputExtension) == '*') {
                  outputExtension = substr(outputExtension, 2);
               }
               s = outputExtension;
#endif
               // This is consistent with the new vsbuild changes after v17.0.2.
               // Return the extension of the output file. This should never
               // get called for rules. It only gets called for rules in vsbuild.
               s = get_extension(absOutputFile,true);

               // set recursion info
               recurseRepString = true;
               lastOption = "%oe";
               len = 3;
               break;

            case 'B':
               if (upcase(substr(command,j+3,2))=='JS') {

                  if (recursionMonitorHash != null && (*recursionMonitorHash):["%objx"] == 1) {
                     _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%objs"));
                     if (recursionStatus != null) {
                        *recursionStatus = -1;
                     }
                     return "";
                  }

                  // objs
                  len=5;

                  // assume a list of objects is in buf_name (true when generating linker
                  // commands)
                  _str obj_list=buf_name;
                  _str lib_list=_ProjectGet_LibsList(handle,config);

                  _str preObjectLibs=_ProjectGet_PreObjectLibs(handle,config);

                  s=_generate_objs_list(obj_list,lib_list,preObjectLibs);

                  // set recursion info
                  recurseRepString = true;
                  lastOption = "%objs";

               }
               break;

            default:
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%o"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%o"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               // %bd%o is no longer valid. OuputFile is often set to "%bdname" for Gnu C++.
               // Fix confusion by always returning an absolute file.
               s = absOutputFile;  

               // set recursion info
               recurseRepString = true;
               lastOption = "%o";

               break;
            }
         }
      } else if (ch=='L') {
         s = '';
         ch2=upcase(substr(command,j+2,1));
         if (ch2=='F') {
            // list file
            len=3;
            s=buf_name;
         } else if (ch2=='I') {
            _str ch3=upcase(substr(command,j+3,1));
            if (ch3=='B') {
               _str ch4=upcase(substr(command,j+4,1));
               if (ch4=='S') {
                  // attempt to prevent infinite loops by checking to see if this variable has
                  // already been replaced during recursion
                  if (recursionMonitorHash != null && (*recursionMonitorHash):["%libs"] == 1) {
                     _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%libs"));
                     if (recursionStatus != null) {
                        *recursionStatus = -1;
                     }
                     return "";
                  }

                  // libs
                  len=5;

                  info=_ProjectGet_LibsList(handle,config);

                  s = s:+info ' ';

                  // set recursion info
                  recurseRepString = true;
                  lastOption = "%libs";

               } else {
                  s=argline;
               }
            } else {
               s=argline;
            }
         } else {
            s=argline;
         }
      } else if (ch=='H') {
         s=BuildTempAppletFile(handle,config);
      } else if (ch=='T') {
         s=ToolName;
      } else if (isdigit(ch)) {
         k=verify(command,'0123456789','',j+1);
         if ( k==0 ) k=length(command)+1;
         if ( k-j-1>3 ) k=j+4;
         len=k-j;
         typeless num=substr(command,j+1,k-j-1);
         s=word(arg(5),num);
      } else if ( ch=='V' || ch=='D') {
         s=buf_name;
         if ( substr(s,2,1)==':' ) {
            s=substr(s,1,2);
         } else {
            s='';
         }
      } else if ( ch=='(' ) {
         k=pos(')',command,j+1);
         s='';
         if (k) {
            len=k-j+1;
            _str envvar_name=substr(command,j+2,len-3);

            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%("envvar_name")"] == 1) {
               //say("infinite loop detected: " envvar_name);
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%(" envvar_name ")"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            // get the value
            s = get_env(envvar_name);

            // set recursion info
            recurseRepString = true;
            lastOption = "%(" envvar_name ")";
         }
      } else if ( ch=='[' ) {
         k=pos(']',command,j+1);
         s='';
         if (k) {
            len=k-j+1;
            _str registry_path = substr(command,j+2,len-3);

            // attempt to prevent infinite loops by checking to see if this variable has
            // already been replaced during recursion
            if (recursionMonitorHash != null && (*recursionMonitorHash):["%["registry_path"]"] == 1) {
               //say("infinite loop detected: " envvar_name);
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%[" registry_path "]"));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }

            // check if the registry name is qualified with an HKEY
            int constantHKey=HKEY_LOCAL_MACHINE;
            if (first_char(registry_path)=='H') {
               parse registry_path with auto hkey '\' registry_path;
               switch (hkey) {
               case 'HKEY_CLASSES_ROOT':
               case 'HKCR:':
               case 'HKCR':
                  constantHKey=HKEY_CLASSES_ROOT;   
                  break;
               case 'HKEY_CURRENT_USER':   
               case 'HKCU:':   
               case 'HKCU':   
                  constantHKey=HKEY_CURRENT_USER;   
                  break; 
               case 'HKEY_LOCAL_MACHINE':  
               case 'HKLM:':  
               case 'HKLM':  
                  constantHKey=HKEY_LOCAL_MACHINE;  
                  break;
               case 'HKEY_USERS':          
               case 'HKU:':          
               case 'HKU':          
                  constantHKey=HKEY_USERS;          
                  break;
               case 'HKEY_CURRENT_CONFIG': 
               case 'HKCC:': 
               case 'HKCC': 
                  constantHKey=HKEY_CURRENT_CONFIG; 
                  break;
               default:
                  registry_path = hkey '\' registry_path;
                  break;
               }
            }

            // check for a field name to query
            _str field_name=null;
            if (pos('@',registry_path)) {
               parse registry_path with registry_path '@' field_name;
            }

            // get the value
#if __UNIX__
            s = "";
#else
            if (field_name != null && field_name != '') {
               s = _ntRegQueryValue(constantHKey, registry_path, "", field_name);
            } else {
               s = _ntRegQueryValue(constantHKey, registry_path, "");
            }
#endif

            // set recursion info
            recurseRepString = true;
            lastOption = "%[" registry_path "]";
         }
      } else if ( ch=='B') {
         s='';
         /* 
            For backward compatibility, if see %bd%o return nothing.
         */          
         boolean return_nothing=false;
         {
            ch2=upcase(substr(command,j+2,1));
            _str ch3=upcase(substr(command,j+3,1));
            _str ch4=upcase(substr(command,j+4,1));
            _str ch5=upcase(substr(command,j+5,1));
            if (ch2=='D' && ch3=='%' && ch4=='O' && !pos(ch5,'NPEB')) {
               return_nothing=true;
            }
         }
         if (return_nothing) {
            len=3;
         } else if (project_name == "") {
            // no project so this is the fall thru case...check for %b, %bn, %bt, %bd, %bo, %bp
            // and remove them
            ch2 = upcase(substr(command, j+2, 1));
            switch (ch2) {
            case 'N':
            case 'T':
            case 'D':
            case 'O':
            case 'P':
               len = 3;
               break;

            default:
               break;
            }

         } else {
            _str configName;
            _str outputDir=_ppc_getObjectDir(configName,project_name,config,handle);
            int x=pos(ch2,'ntdop',1,'i');
            if (x>0) {
               lastOption='%b':+substr('ntdop',x,1);
            } else {
               lastOption='%b';
            }
            if (recursionMonitorHash != null && (*recursionMonitorHash):[lastOption] == 1) {
               _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", lastOption));
               if (recursionStatus != null) {
                  *recursionStatus = -1;
               }
               return "";
            }
            (*recursionMonitorHash):[lastOption] = 1;
            outputDir= _parse_project_command(outputDir, buf_name, project_name, cword, argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash,handle,config);
            (*recursionMonitorHash):[lastOption] = 0;

            _str cfg = configName;
            //cfg='"CFG=mdisamp - Win32 Debug"';
            //cfg='"CFG=mdisamp - Win32" "OBJDIR=.\debug"';
            ch2=upcase(substr(command,j+2,1));
            switch (ch2) {
            case 'N'://CFG=<Name>
               len=3;
#define CFG_EQUAL_STR 'CFG='
               int p=pos(CFG_EQUAL_STR,cfg);
               if (p) {
                  int start=0;
                  if (substr(cfg,1,1)=='"') ++start;//Should start with "
                  _str beginning='';
                  if (start) beginning=substr(cfg,start,1);
                  if (substr(cfg,p+1,1,'*')==' ') {//Pad with star in case we are at end of string
                     ++p;//Should probably have a space.
                  }
                  _str ending=substr(cfg,p+length(CFG_EQUAL_STR));
                  s=beginning:+ending;
               } else {
                  // might be a .NET config (config|Platform)
                  parse cfg with s '|' .;
               }
               break;
            case 'T':
               if (_IsTornadoWorkspaceFilename(_workspace_filename)) {
                  len=3;
                  int temp_view_id,orig_view_id;
                  int status=_open_temp_view(_strip_filename(project_name,'N'):+'Makefile',temp_view_id,orig_view_id);
                  if (!status) {
                     top(); // Just incase user is editing the file
                     _str cfgval;
                     parse cfg with '=' cfgval;
                     status=search('^ifeq \(\$\(BUILD_SPEC\),'cfgval'\)$','@r');
                     if (!status) {
                        status=search('^DEFAULT_RULE?@\= ','@r');
                        if (!status) {
                           get_line(auto line);
                           _str DefaultRule;
                           parse line with '=' DefaultRule;
                           DefaultRule=strip(DefaultRule);
                           s='DEFAULT_RULE='DefaultRule' 'DefaultRule;
                        }
                     }
                     p_window_id=orig_view_id;
                     _delete_temp_view(temp_view_id);
                  }
               }
               break;

            case 'D':
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%bd"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%bd"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               // If there is a user-defined OBJDIR, use it as is.
               if (outputDir == "") {
                  if (pos('CFG={?*}($|")',cfg,1,'ri') ) {
                     outputDir=_vcGetObjDir(cfg);
                  } else {
                     // java is a special case that we do not default
                     _str configType = _ProjectGet_Type(handle,config);
                     if (!strieq(configType, "java")) {
                        outputDir=cfg;
                     }
                  }
               }
               _maybe_append_filesep(outputDir);
               // Since all "path" and "dir" options return absolute paths,
               // need to be consistent here too. Always return an absolute path
               // for %bd instead of just sometimes like the previous implementation.
               outputDir=absolute(outputDir,_strip_filename(_project_name,'n'));

               s=outputDir;
               len=3;

               // set recursion info
               recurseRepString = true;
               lastOption = "%bd";

               break;

            case 'O':
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%bo"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%bo"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               // If there is a user-defined OBJDIR, use it as is.
               if (outputDir == "") {
                  if (pos('CFG={?*}($|")',cfg,1,'ri') ) {
                     outputDir=_vcGetOutputDirFromDSP(cfg);
                  } else {
                     outputDir=_vcGetOutputDirFromVisualStudioProj(cfg);
                     outputDir=_AbsoluteToWorkspace(outputDir);
                  }
               }
               s=outputDir;
               len=3;

               // set recursion info
               recurseRepString = true;
               lastOption = "%bo";
               break;

            case 'P': // .NET config (Configuration|Platform)
               len=3;
               if (pos('|',cfg)) {
                  parse cfg with . '|' s;
               } else {
                  s = "";
               }
               break;

            case 'X':
               {
                  // Specials for Xcode projects with "ConfigName | Target"
                  // TODO: May at some point need "ConfigName|Target|SDKName"
                  //  %bxt = Target
                  //  %bxc = Configuration
                  //  %bxk = SDK
                  _str ch3 = upcase(substr(command,j+3,1));
                  if (ch3 == 'C') {
                     // attempt to prevent infinite loops by checking to see if this variable has
                     // already been replaced during recursion
                     if (recursionMonitorHash != null && (*recursionMonitorHash):["%bxc"] == 1) {
                        _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%bxc"));
                        if (recursionStatus != null) {
                           *recursionStatus = -1;
                        }
                        return "";
                     }
                     parse cfg with s '|' .;
                     len=4;
                     // set recursion info
                     recurseRepString = true;
                     lastOption = "%bxc";
                  } else if (ch3 == 'T') {
                     // attempt to prevent infinite loops by checking to see if this variable has
                     // already been replaced during recursion
                     if (recursionMonitorHash != null && (*recursionMonitorHash):["%bxt"] == 1) {
                        _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%bxt"));
                        if (recursionStatus != null) {
                           *recursionStatus = -1;
                        }
                        return "";
                     }
                     parse cfg with . '|' s;
                     len=4;
                     // set recursion info
                     recurseRepString = true;
                     lastOption = "%bxt";
                  } else if (ch3 == 'K') {
                     // attempt to prevent infinite loops by checking to see if this variable has
                     // already been replaced during recursion
                     if (recursionMonitorHash != null && (*recursionMonitorHash):["%bxk"] == 1) {
                        _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%bxk"));
                        if (recursionStatus != null) {
                           *recursionStatus = -1;
                        }
                        return "";
                     }
                     parse GetCurrentTargetSDK(project_name) with auto targetSDK "-" auto targetDevice;
                     if (targetSDK == '') {
                        s = "";
                     } else { 
                        s = "-sdk "targetSDK;
                     }
                     len=4;
                     // set recursion info
                     recurseRepString = true;
                     lastOption = "%bxk";
                  }
               }
               break;
            default:
               s=cfg;
            }
         }
      } else if (ch=='J') {
         s = '';
         ch2=upcase(substr(command,j+2,1));
         if (ch2=='B') {
            _str ch3=upcase(substr(command,j+3,1));
            if (ch3=='D') {
               // attempt to prevent infinite loops by checking to see if this variable has
               // already been replaced during recursion
               if (recursionMonitorHash != null && (*recursionMonitorHash):["%jbd"] == 1) {
                  _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%jbd"));
                  if (recursionStatus != null) {
                     *recursionStatus = -1;
                  }
                  return "";
               }

               // jbd
               len=4;

               // Since %bd returns an absoulte path now, lets have this return ''
               // when the outputDir is blank to keep this code this same for Java.
               // (clark) I don't know if this is nicessary.
               _str configName;
               _str outputDir=_ppc_getObjectDir(configName,project_name,config,handle);
               if (outputDir!='') {
                  // get the build directory by recursively processing %bd
                  (*recursionMonitorHash):["%jbd"] = 1;
                  _str builddir = _parse_project_command("%bd", buf_name, project_name, cword, argline,
                                                         ToolName, ClassPath, recursionStatus, recursionMonitorHash);
                  (*recursionMonitorHash):["%jbd"] = 0;
                  //Check for blank but it won't be blank if there is a project open.
                  if (builddir != "") {
                     s = "-d \"" builddir "\"";
                  }
               }

               // set recursion info
               recurseRepString = true;
               lastOption = "%jbd";
            } else {
               s=argline;
            }
         } else {
            s=argline;
         }
      } else if ( ch=='{') {
         // TBD, insert list of files matching filter
         k=pos('}',command,j+1);
         s='';
         if (k && project_name!='') {
            len=k-j+1;
            _str file_filter=substr(command,j+2,len-3);
            //11:45am 8/18/1997
            message("Getting source files in current project");
            mou_hour_glass(1);
            _str fileList[];
            int status = _getProjectFiles(_workspace_filename, project_name, fileList, 1);
            if (!status) {
               for (n := 0; n < fileList._length(); n++) {
                  if (_IsFileMatchedExtension(strip(fileList[n]),file_filter)) {
                     if (s!='') {
                        strappend(s,' ');
                     }
                     strappend(s,maybe_quote_filename(fileList[n]));
                  }
               }
            }
            mou_hour_glass(0);
         }
      } else if (ch == 'X') {
         s = "";
         ch2=upcase(substr(command,j+2,1));
         switch (ch2) {
         case 'U': {
               _str ch3=upcase(substr(command,j+3,1));
               switch (ch3) {
               case 'P':
                  // enable unix fileseps
                  forceUnixFileSeps = true;
                  len = 4;
                  break;

               default:
                  break;
               }
               break;
            }

         case 'W': {
               _str ch3=upcase(substr(command,j+3,1));
               switch (ch3) {
               case 'P':
                  // disable unix fileseps
                  forceUnixFileSeps = false;
                  len = 4;
                  break;

               default:
                  break;
               }
               break;
            }

         default:
            break;
         }
      } else if ( ch==PARSE_CHAR ) {
         s=PARSE_CHAR;
      } else {
         len=1;
         /* insert pc filename */
         s='';
      }

      // recursively process the replacement value before inserting it.  this is done recursively
      // so a hash table can be maintained and infinite loops can be prevented
      if (recurseRepString && lastOption != "") {
         //say("Checking option: " lastOption " with value: " s);
            // flag that this var has been replaced within this recursion
        (*recursionMonitorHash):[lastOption] = 1;
        s = _parse_project_command(s, buf_name, project_name, cword, argline,
                                   ToolName, ClassPath, &recLocalStatus, recursionMonitorHash);
            // clear the flag now that the recursion concerning this var is over
        (*recursionMonitorHash):[lastOption] = 0;
         // check status code for failure
         if (recLocalStatus) {
            // pass the code along if status is valid pointer
            *recursionStatus = recLocalStatus;
            return "";
         }
      }

      // convert fileseps if necessary
#if !__UNIX__
      if (forceUnixFileSeps) {
         s = stranslate(s, FILESEP2, FILESEP);
      }
#endif

      // replace the placeholder with the result
      command=substr(command,1,j-1):+s:+substr(command,j+len);

      // recurse thru the replacement string unless told not to
      if (!recurseRepString) {
         j=j+length(s);
      }
   }
   return(command);
}

int _GetExeFromVisualStudioFile(_str associatedProject,_str config,_str &outputDir)
{
   _str ext=_get_extension(associatedProject,true);
   int status=0;
   if ( file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ) {
      status = GetItemFromVCProj(associatedProject, config, 'OutputFile', outputDir);
   } else if ( file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT) ) {
      status = GetItemFromVCXProj(associatedProject, config, 'OutputFile', outputDir);
   } else {
      status = GetOutputFilenameFromStudioStandardProj(associatedProject,config,outputDir);
   }
   return(status);
}

int _GetProgramDatabaseFromVisualStudioFile(_str associatedProject,_str config,_str &pdbDir)
{
   _str ext=_get_extension(associatedProject,true);
   int status=0;
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      status = GetItemFromVCProj(associatedProject, config, 'ProgramDatabaseFile', pdbDir);
   } else if (file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      status = GetItemFromVCXProj(associatedProject, config, 'ProgramDatabaseFile', pdbDir);
   } 
   return(status);
}

/**
 *
 * @param command
 * @param recursionStatus
 * @param recursionMonitorHash
 *
 * @return
 */
_str _parse_env_vars(_str command, int* recursionStatus = null, _str (*recursionMonitorHash):[] = null)
{
   _str s = "";
   _str lastOption = "";
   boolean recurseRepString = false;
   int j=1;

   for (;;) {
      // reset the recursion information
      recurseRepString = false;
      lastOption = "";

      j=pos("%(",command,j);
      if ( ! j ) {
         break;
      }
      int len=2;
      int k=pos(')',command,j+1);
      s='';
      if (k) {
         len=k-j+1;
         _str envvar_name=substr(command,j+2,len-3);

         // attempt to prevent infinite loops by checking to see if this variable has
         // already been replaced during recursion
         if (recursionMonitorHash != null && (*recursionMonitorHash):["%("envvar_name")"] == 1) {
            //say("infinite loop detected: " envvar_name);
            _message_box(get_message(VSBUILDRC_INFINITE_LOOP_DETECTED_IN_COMMAND_2ARG, "", "%(" envvar_name ")"));
            if (recursionStatus != null) {
               *recursionStatus = -1;
            }
            return "";
         }

         // get the value
         s = get_env(envvar_name);

         // set recursion info
         recurseRepString = true;
         lastOption = "%(" envvar_name ")";
      }

      // recursively process the replacement value before inserting it.  this is done recursively
      // so a hash table can be maintained and infinite loops can be prevented
      if (recurseRepString && lastOption != "") {
         //say("Checking option: " lastOption " with value: " s);
         int recLocalStatus = 0;
         if (recursionMonitorHash != null) {
            // flag that this var has been replaced within this recursion
            (*recursionMonitorHash):[lastOption] = 1;
            s = _parse_env_vars(s, &recLocalStatus, recursionMonitorHash);
            // clear the flag now that the recursion concerning this var is over
            (*recursionMonitorHash):[lastOption] = 0;

         } else {
            // flag that this var has been replaced within this recursion
            _str recLocalHash:[];
            recLocalHash:[lastOption] = 1;
            s = _parse_env_vars(s, &recLocalStatus, &recLocalHash);
            // clear the flag now that the recursion concerning this var is over
            recLocalHash:[lastOption] = 0;
         }

         // check status code for failure
         if (recLocalStatus) {
            // pass the code along if status is valid pointer
            if (recursionStatus != null) {
               *recursionStatus = recLocalStatus;
            }

            return "";
         }
      }

      // replace the placeholder with the result
      if (len > 0) {
         command=substr(command,1,j-1):+s:+substr(command,j+len);
      }

      // recurse thru the replacement string unless told not to
      if (!recurseRepString) {
         j=j+length(s);
      }
   }
   return(command);
}

int CreateRCOptionsLine(_str SourceFilename, _str ProjectFilename, _str ConfigName, _str &CommandLine)
{
   _str VCPPProjectFilename;
   int status=_GetAssociatedProjectInfo(ProjectFilename, VCPPProjectFilename);
   if (status) {
      return(status);
   }
   _str ext=_get_extension(VCPPProjectFilename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      VCPPProjectFilename = absolute(getICProjAssociatedProjectFile(VCPPProjectFilename),_strip_filename(ProjectFilename,'N'));
      ext=_get_extension(VCPPProjectFilename,1);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      // set to current in the project
      int handle=_xmlcfg_open(VCPPProjectFilename,status);
      if (handle<0) {
         return(status);
      }
      int i;
      int index=_xmlcfg_find_child_with_name(handle,TREE_ROOT_INDEX,"VisualStudioProject");
      if (index<0) {
         _xmlcfg_close(handle);
         return(1);
      }

      int CurConfigIndex = _xmlcfg_find_simple(handle, "/VisualStudioProject/Configurations/Configuration[@Name='"ConfigName"']");
      if (CurConfigIndex<0) {
         _xmlcfg_close(handle);
         return(1);
      }

      _str OptionValues:[]=null;
      GetVCPPToolInfo(handle,CurConfigIndex,"VCResourceCompilerTool",OptionValues);

      typeless FileIndexes[]=null;
      _xmlcfg_find_simple_array(handle,"//File",FileIndexes);
      _str ProjectPath=_strip_filename(ProjectFilename,'N');
      _str RelSourceFilename=relative(SourceFilename,ProjectPath);
      RelSourceFilename=ConvertToVCPPRelFilename(RelSourceFilename,ProjectPath);
      for (i=0;i<FileIndexes._length();++i) {
         _str CurRelPath='';
         CurRelPath=_xmlcfg_get_attribute(handle,FileIndexes[i],"RelativePath");
   
         if (file_eq(CurRelPath,RelSourceFilename)) {
            int ChildIndex=_xmlcfg_get_first_child(handle,FileIndexes[i]);
            for (;ChildIndex>=0;) {
               _str CurConfigName='';
   
               //tagname=_xmlcfg_get_name(handle,ChildIndex);
               CurConfigName=_xmlcfg_get_attribute(handle,ChildIndex,"Name");
               if (CurConfigName==ConfigName) {
                  GetVCPPToolInfo(handle,ChildIndex,"VCResourceCompilerTool",OptionValues);
               }
               ChildIndex=_xmlcfg_get_next_sibling(handle,ChildIndex);
            }
            break;
         }
      }
   
      _str options = '';
      _str VCPPMacros:[]=null;
      GetVCPPMacros(handle,CurConfigIndex,ProjectFilename,SourceFilename,VCPPMacros);
      status=GenerateRCOptionsLine(SourceFilename,ProjectFilename,ConfigName,OptionValues,VCPPMacros,options);
      CommandLine = 'rc ' :+ options :+ ' ' :+ maybe_quote_filename(SourceFilename);
      if (status) {
         _xmlcfg_close(handle);
         return(status);
      }
      _xmlcfg_close(handle);

   } else if (file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      // msbuild proj.vcxproj /nologo /verbosity:m /target:ResourceCompile /p:Platform:"Win32" /p:Configuration="Debug" /p:SelectedFiles="filename.rc"
      _str TempFilename = GenerateMSBuildResponseFile(SourceFilename, VCPPProjectFilename, ConfigName, 'ResourceCompile');
      CommandLine = 'msbuild @' :+ TempFilename;
   }
   return(0);
}

static int GenerateRCOptionsLine(_str SourceFilename,_str ProjectFilename,_str ConfigName,_str OptionValues:[],
                                 _str VCPPMacros:[],_str &CommandLine)
{
   CommandLine='';
   if (OptionValues._indexin('PreprocessorDefinitions') ) {
      _str Defines=OptionValues:['PreprocessorDefinitions'];
      for (;;) {
         _str cur;
         parse Defines with cur ';' Defines;
         if (cur=='') break;
         CommandLine=CommandLine' /d "'cur'"';
      }
   }
   if (OptionValues._indexin('Culture') ) {
      CommandLine=CommandLine' /l 'dec2hex((long)OptionValues:['Culture']);
   }
   if (OptionValues._indexin('PrintProgress') ) {
      if (OptionValues:['PrintProgress']=='TRUE') {
         CommandLine=CommandLine' /v ';
      }
   }
   if (OptionValues._indexin('IgnoreStandardIncludePath') ) {
      if (OptionValues:['IgnoreStandardIncludePath']=='TRUE') {
         CommandLine=CommandLine' /x ';
      }
   }
   if (OptionValues._indexin('IncludePaths') ) {
      CommandLine=CommandLine' 'GetVStudioIncludeCommandLine(ExpandVCPPMacros(VCPPMacros,OptionValues:['IncludePaths']));//' /I 'cmdline_quote_filename(ExpandVCPPMacros(VCPPMacros,OptionValues:['IncludePaths']));
   }
   if (OptionValues._indexin('AdditionalIncludePaths') ) {
      CommandLine=CommandLine' 'GetVStudioIncludeCommandLine(ExpandVCPPMacros(VCPPMacros,OptionValues:['AdditionalIncludePaths']));' /I 'cmdline_quote_filename(ExpandVCPPMacros(VCPPMacros,OptionValues:['AdditionalIncludePaths']));
   }
   if (OptionValues._indexin('AdditionalIncludeDirectories') ) {
      CommandLine=CommandLine' 'GetVStudioIncludeCommandLine(ExpandVCPPMacros(VCPPMacros,OptionValues:['AdditionalIncludePaths']));' /I 'cmdline_quote_filename(ExpandVCPPMacros(VCPPMacros,OptionValues:['AdditionalIncludePaths']));
   }

   _str ResName = '$(IntDir)/$(InputName).res';
   if (OptionValues._indexin('ResourceOutputFileName') ) {
      ResName = OptionValues:['ResourceOutputFileName'];
   }
   CommandLine=CommandLine' /fo 'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName, ResName));
   return(0);
}

static _str GetVStudioIncludeCommandLine(_str ProjectFileIncludeString)
{
   _str command_line='';
   for (;;) {
      _str cur='';
      parse ProjectFileIncludeString with cur (PATHSEP) ProjectFileIncludeString;
      if ( cur=='' ) {
         break;
      }
      command_line=command_line:+'/I 'cmdline_quote_filename(cur)' ';
   }
   return(command_line);
}

static _str GenerateMSBuildResponseFile(_str SourceFilename, _str VCPPProjectFilename, _str ConfigName, _str TargetName)
{
   if (_vcpp_compiler_option_tempfile == '') {
      _vcpp_compiler_option_tempfile = mktemp();
   }
   TempFilename := _vcpp_compiler_option_tempfile;
   parse ConfigName with auto Configuration '|' auto Platform;

   orig_view_id := _create_temp_view(auto temp_view_id);
   TempLine := maybe_quote_filename(VCPPProjectFilename);
   TempLine :+= ' /nologo /verbosity:m /target:':+ TargetName;
   TempLine :+= ' /p:Platform=':+ maybe_quote_filename(Platform);
   TempLine :+= ' /p:Configuration=':+ maybe_quote_filename(Configuration);
   TempLine :+= ' /p:SelectedFiles=' :+ maybe_quote_filename(relative(SourceFilename, _strip_filename(VCPPProjectFilename, 'N'), false));
   insert_line(TempLine);
   _save_file('+o 'maybe_quote_filename(TempFilename));
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);
   return TempFilename;
}

/**
 *
 * @param SourceFilename
 *
 * @param ProjectFilename
 *
 * @return 0 if successful
 */
static int CreateVCPPOptionsFile(_str SourceFilename, _str ProjectFilename, _str ConfigName, _str& CommandLine)
{
   _str VCPPProjectFilename;
   CommandLine = '';
   int status=_GetAssociatedProjectInfo(ProjectFilename,VCPPProjectFilename);
   if (status) {
      return(status);
   }
   _str ext=_get_extension(VCPPProjectFilename,1);
   if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      CommandLine = "echo Command not supported by SlickEdit.";
      return(1);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      // set to current in the project
      int handle=_xmlcfg_open(VCPPProjectFilename,status);
      if (handle<0) {
         return(status);
      }

      _str TempFilename = '';
      _str OtherOptions = '';

      int index=_xmlcfg_find_child_with_name(handle,TREE_ROOT_INDEX,"VisualStudioProject");
      if (index<0) {
         _xmlcfg_close(handle);
         return(1);
      }
      int VSPindex=index;
   
     int CurConfigIndex = _xmlcfg_find_simple(handle, "/VisualStudioProject/Configurations/Configuration[@Name='"ConfigName"']");
      if (CurConfigIndex<0) {
         _xmlcfg_close(handle);
         return(1);
      }

      _str OptionValues:[]=null;
      GetVCPPToolInfo(handle,CurConfigIndex,"VCCLCompilerTool",OptionValues);
      GetVCPPConfigInfo(handle,CurConfigIndex,OptionValues);
   
      int i;
      typeless FileIndexes[]=null;
      _xmlcfg_find_simple_array(handle,"//File",FileIndexes);
      _str ProjectPath=_strip_filename(ProjectFilename,'N');
      _str RelSourceFilename=relative(SourceFilename,ProjectPath);
      RelSourceFilename=ConvertToVCPPRelFilename(RelSourceFilename,ProjectPath);
      for (i=0;i<FileIndexes._length();++i) {
         _str CurRelPath='';
         CurRelPath=_xmlcfg_get_attribute(handle,FileIndexes[i],"RelativePath");
   
         if (file_eq(CurRelPath,RelSourceFilename)) {
            int ChildIndex=_xmlcfg_get_first_child(handle,FileIndexes[i]);
            for (;ChildIndex>=0;) {
               _str CurConfigName='';
   
               //tagname=_xmlcfg_get_name(handle,ChildIndex);
               CurConfigName=_xmlcfg_get_attribute(handle,ChildIndex,"Name");
               if (CurConfigName==ConfigName) {
                  GetVCPPToolInfo(handle,ChildIndex,"VCCLCompilerTool",OptionValues);
               }
               ChildIndex=_xmlcfg_get_next_sibling(handle,ChildIndex);
            }
            break;
         }
      }
   
      _str VCPPMacros:[]=null;
      GetVCPPMacros(handle,CurConfigIndex,ProjectFilename,SourceFilename,VCPPMacros);
      status=GenerateVCPPTempOptionsFile(SourceFilename,ProjectFilename,OptionValues,handle,VCPPMacros,TempFilename,OtherOptions,ConfigName);
      _maybe_append(OtherOptions, ' ');
      CommandLine = "cl @" :+ TempFilename :+ " " :+ strip(OtherOptions, 'L', ' ') :+ maybe_quote_filename(SourceFilename);
      if (status) {
         _xmlcfg_close(handle);
         return(status);
      }
      _xmlcfg_close(handle);
   } else if (file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      // msbuild proj.vcxproj /nologo /verbosity:m /target:CLCompile /p:Platform:Win32 /p:Configuration=Debug /p:SelectedFiles=filename.cpp
      _str TempFilename = GenerateMSBuildResponseFile(SourceFilename, VCPPProjectFilename, ConfigName, 'CLCompile');
      CommandLine = 'msbuild @' :+ TempFilename;
   }
   return(0);
}

static _str GetVCPPStudioVersion(_str vs_version)
{
   _str configName = '';
   if (vs_version=='7.10') {
      configName=COMPILER_NAME_VS2003;
   } else if (vs_version=='8.00') {
      configName=COMPILER_NAME_VS2005;
   } else if (vs_version=='9.00') {
      configName=COMPILER_NAME_VS2008;
   } else if (vs_version=='10.00') {
      configName=COMPILER_NAME_VS2010;
   } else if (vs_version=='11.00') {
      configName=COMPILER_NAME_VS2012;
   }
   return configName;
}
 
static int GenerateVCPPTempOptionsFile(_str SourceFilename,_str ProjectFilename,_str OptionValues:[], int handle,
                                       _str (&VCPPMacros):[],_str &TempFilename,_str &OtherOptions,_str ConfigName)
{
   _str vs_version=_xmlcfg_get_path(handle,'VisualStudioProject','Version');

   _str PropSheetValues:[];
   if (OptionValues._indexin("InheritedPropertySheets")) {
      _str studioVersion = GetVCPPStudioVersion(vs_version);
      _str filename = VisualStudioVCPPExpandAllMacros(ConfigName, OptionValues:["InheritedPropertySheets"], '', studioVersion);
      GetVCPPPropertySheetsOptions(filename, PropSheetValues);
      typeless key;
      for (key._makeempty();;) {
         PropSheetValues._nextel(key);
         if (key._isempty()) {
            break;
         }
         if (key == "Name") {
            continue;
         }
         if (!OptionValues._indexin(key)) {
            OptionValues:[key] = PropSheetValues:[key];
         }
      }
   }

   OtherOptions='';
   // _vcpp_compiler_option_tempfile is set in stdcmds.e.definit
   if (_vcpp_compiler_option_tempfile=='') {
      _vcpp_compiler_option_tempfile=mktemp();
   }
   TempFilename=_vcpp_compiler_option_tempfile;
   _str TempLine='';
   if (OptionValues._indexin("Optimization")) {
      switch (OptionValues:["Optimization"]) {
      case 0:
         TempLine=TempLine' /Od';
         break;
      case 1:
         TempLine=TempLine' /O1';
         break;
      case 2:
         TempLine=TempLine' /O2';
         break;
      case 3:
         TempLine=TempLine' /Ox';
         break;
      }
   }
   if (OptionValues._indexin("OmitFramePointers")) {
      if (upcase(OptionValues:["OmitFramePointers"])=="TRUE") {
         TempLine=TempLine' /Oy';
      }
   }

   if (OptionValues._indexin("InlineFunctionExpansion")) {
      if (OptionValues:["InlineFunctionExpansion"]==1) {
         TempLine=TempLine' /Ob1';
      } else if (OptionValues:["InlineFunctionExpansion"]==2) {
         TempLine=TempLine' /Ob2';
      }
   }
   if (OptionValues._indexin("GlobalOptimizations")) {
      if (upcase(OptionValues:["GlobalOptimizations"])=="TRUE") {
         TempLine=TempLine' /Og';
      }
   }
   if (OptionValues._indexin("WholeProgramOptimizations")) {
      if (upcase(OptionValues:["WholeProgramOptimizations"])=="TRUE") {
         TempLine=TempLine' /GL';
      }
   }
   if (OptionValues._indexin("ImproveFloatingPointConsistency")) {
      if (upcase(OptionValues:["ImproveFloatingPointConsistency"])=="TRUE") {
         TempLine=TempLine' /Op';
      }
   }
   if (OptionValues._indexin("FavorSizeOrSpeed")) {
      if (OptionValues:["FavorSizeOrSpeed"]==1) {
         TempLine=TempLine' /Ot';
      } else if (OptionValues:["FavorCodeGeneration"]==2) {
         TempLine=TempLine' /Os';
      }
   }
   if (OptionValues._indexin("EnableIntrinsicFunctions")) {
      if (upcase(OptionValues:["EnableIntrinsicFunctions"])=='TRUE') {
         TempLine=TempLine' /Oi';
      }
   }
   if (OptionValues._indexin("EnableFiberSafeOptimizations")) {
      if (upcase(OptionValues:["EnableFiberSafeOptimizations"])=='TRUE') {
         TempLine=TempLine' /GT';
      }
   }
   if (OptionValues._indexin("SuppressStartupMessage")) {
      if (upcase(OptionValues:["SuppressStartupMessage"])=='TRUE') {
         OtherOptions=OtherOptions' /nologo';
      }
   } else if (OptionValues._indexin("SuppressStartupBanner")) {
      if (upcase(OptionValues:["SuppressStartupBanner"])=='TRUE') {
         OtherOptions=OtherOptions' /nologo';
      }
   }
   if (OptionValues._indexin("WarningLevel")) {
      if (OptionValues:["WarningLevel"]==0) {
         TempLine=TempLine' /W0';
      } else if (OptionValues:["WarningLevel"]==1) {
         TempLine=TempLine' /W1';
      } else if (OptionValues:["WarningLevel"]==2) {
         TempLine=TempLine' /W2';
      } else if (OptionValues:["WarningLevel"]==3) {
         TempLine=TempLine' /W3';
      } else if (OptionValues:["WarningLevel"]==4) {
         TempLine=TempLine' /W4';
      }
   }
   if (OptionValues._indexin("WarnAsError")) {
      if (upcase(OptionValues:["WarnAsError"])=='TRUE') {
         TempLine=TempLine' /WX';
      }
   }
   if (OptionValues._indexin("Detect64BitPortabilityProblems")) {
      if (upcase(OptionValues:["Detect64BitPortabilityProblems"])=='TRUE') {
         TempLine=TempLine' /Wp64';
      }
   }
   if (OptionValues._indexin("DebugInformationFormat")) {
      if (OptionValues:["DebugInformationFormat"]==1) {
         TempLine=TempLine' /Z7';
      } else if (OptionValues:["DebugInformationFormat"]==2) {
         TempLine=TempLine' /Zd';
      } else if (OptionValues:["DebugInformationFormat"]==3) {
         TempLine=TempLine' /Zi';
      } else if (OptionValues:["DebugInformationFormat"]==4) {
         TempLine=TempLine' /ZI';
      }
   }

   boolean isCLR=false;
   if (OptionValues._indexin("UseManagedExtensions")) {
      if (OptionValues:["UseManagedExtensions"]==1) {
         isCLR=true;
         TempLine=TempLine' /CLR:noAssembly';
      } else if (OptionValues:["UseManagedExtensions"]==2) {
         isCLR=true;
         TempLine=TempLine' /CLR';
      }
   } else if (OptionValues._indexin("ManagedExtensions")) {
      if ( (upcase(OptionValues:["ManagedExtensions"]):=='TRUE') ||
           (OptionValues:["ManagedExtensions"]:=='1') )  {
         isCLR=true;
         TempLine=TempLine' /clr';
      }
   }
   _str defines=_ProjectGet_AssociatedDefines(SourceFilename,handle,ConfigName,_xmlcfg_get_filename(handle),true);
   if (defines:!='') {
      TempLine=TempLine' 'defines;
   }

   if (OptionValues._indexin("IgnoreStandardIncludePath")) {
      if (upcase(OptionValues:["IgnoreStandardIncludePath"])=='TRUE') {
         TempLine=TempLine' /X';
      }
   }
   if (OptionValues._indexin("KeepComments")) {
      if (upcase(OptionValues:["KeepComments"])=='TRUE') {
         TempLine=TempLine' /C';
      }
   }
   if (OptionValues._indexin("GeneratePreprocessedFile")) {
      if (OptionValues:["GeneratePreprocessedFile"]==1) {
         TempLine=TempLine' /P';
      } else if (OptionValues:["GeneratePreprocessedFile"]==2) {
         TempLine=TempLine' /EP /P';
      }
   }
   if (OptionValues._indexin("OptimizeForProcessor")) {
      if (OptionValues:["OptimizeForProcessor"]=='1') {
         TempLine=TempLine' /G5';
      } else if (OptionValues:["OptimizeForProcessor"]=='2') {
         TempLine=TempLine' /G6';
      } else if (OptionValues:["OptimizeForProcessor"]=='3') {
         TempLine=TempLine' /G7';
      }
   }
   if (OptionValues._indexin("OptimizeForWindowsApplication")) {
      if (OptionValues:["OptimizeForWindowsApplication"]=='1') {
         TempLine=TempLine' /GA';
      }
   }
   if (OptionValues._indexin("BufferSecurityCheck")) {
      if (upcase(OptionValues:["BufferSecurityCheck"])=='TRUE') {
         TempLine=TempLine' /GS';
      }
      else if ((upcase(OptionValues:["BufferSecurityCheck"])=='FALSE')
               && (vs_version >= 8.0)){
         // /GS is the default in VS2005, so we only we have an entry
         // for BufferSecurityCheck if it is false
         TempLine=TempLine' /GS-';
      }

   } else if (isCLR) {
      TempLine=TempLine' /GS';
   }

   if (OptionValues._indexin("UninitializedVariableCheck")) {
      if (upcase(OptionValues:["UninitializedVariableCheck"])=='TRUE') {
         TempLine=TempLine' /RTCu';
      }
   }
   if (OptionValues._indexin("StackFrameCheck")) {
      if (upcase(OptionValues:["StackFrameCheck"])=='TRUE') {
         TempLine=TempLine' /RTCs';
      }
   }
   // ExceptionHandling is either false or not there.  If it is not there this
   // is the default
   if (!isCLR) {
      if ( !OptionValues._indexin("ExceptionHandling") ) {
         TempLine=TempLine' /EHsc';
      } else {
         if (upcase(OptionValues:["ExceptionHandling"])=='TRUE' || OptionValues:["ExceptionHandling"]=='1') {
            TempLine=TempLine' /EHsc';
         }
         else if (OptionValues:["ExceptionHandling"]=='2') {
            TempLine=TempLine' /EHa';
         }
      }
   }
   if (OptionValues._indexin("EnableFunctionLevelLinking")) {
      if (upcase(OptionValues:["EnableFunctionLevelLinking"])=='TRUE') {
         TempLine=TempLine' /Gy';
      }
   }
   if (OptionValues._indexin("MinimalRebuild")) {
      if (upcase(OptionValues:["MinimalRebuild"])=='TRUE') {
         TempLine=TempLine' /Gm';
      }
   } else {
      // This option is described in the Visual Studio .NET documentation
      // as being only for the use of Visual Studio.  However, we are in
      // using a VS project and setting this here should maintain the users
      // experience if they open the project in VS again.
      TempLine=TempLine' /FD';
   }
   if (OptionValues._indexin("StringPooling")) {
      if (upcase(OptionValues:["StringPooling"])=='TRUE') {
         TempLine=TempLine' /GF';
      }
   }
   if (OptionValues._indexin("BasicRuntimeChecks")) {
      if (OptionValues:["BasicRuntimeChecks"]=='1') {
         TempLine=TempLine' /RTCs';
      } else if (OptionValues:["BasicRuntimeChecks"]=='2') {
         TempLine=TempLine' /RTCu';
      } else if (OptionValues:["BasicRuntimeChecks"]=='3') {
         TempLine=TempLine' /RTC1';
      }
   }
   if (OptionValues._indexin("RuntimeLibrary")) {
      if (OptionValues:["RuntimeLibrary"]==0) {
         TempLine=TempLine' /MT';
      } else if (OptionValues:["RuntimeLibrary"]==1) {
         TempLine=TempLine' /MTd';
      } else if (OptionValues:["RuntimeLibrary"]==2) {
         TempLine=TempLine' /MD';
      } else if (OptionValues:["RuntimeLibrary"]==3) {
         TempLine=TempLine' /MDd';
      } else if (OptionValues:["RuntimeLibrary"]==4) {
         TempLine=TempLine' /ML';
      } else if (OptionValues:["RuntimeLibrary"]==5) {
         TempLine=TempLine' /MLd';
      }
   }
   if (OptionValues._indexin("UseOfMFC")) {
      if (OptionValues:["UseOfMFC"]==2) {
         TempLine=TempLine' /D "_AFXDLL"';
      }
   }
   if (OptionValues._indexin("SmallerTypeCheck")) {
      if (upcase(OptionValues:["SmallerTypeCheck"])=='TRUE') {
         TempLine=TempLine' /RTCc';
      }
   }
   if (OptionValues._indexin("StructMemberAlignment")) {
      if (OptionValues:["StructMemberAlignment"]==1) {
         TempLine=TempLine' /Zp1';
      } else if (OptionValues:["StructMemberAlignment"]==2) {
         TempLine=TempLine' /Zp2';
      } else if (OptionValues:["StructMemberAlignment"]==3) {
         TempLine=TempLine' /Zp4';
      } else if (OptionValues:["StructMemberAlignment"]==4) {
         TempLine=TempLine' /Zp8';
      } else if (OptionValues:["StructMemberAlignment"]==5) {
         TempLine=TempLine' /Zp16';
      }
   }
   if (OptionValues._indexin("TreatWChar_tAsBuiltInType")) {
      if (upcase(OptionValues:["TreatWChar_tAsBuiltInType"])=='TRUE') {
         TempLine=TempLine' /Zc:wchar_t';
      } else if (upcase(OptionValues:["TreatWChar_tAsBuiltInType"])=='FALSE') {
         TempLine=TempLine' /Zc:wchar_t-';
      }
   }
   if (OptionValues._indexin("DisableLanguageExtensions")) {
      if (upcase(OptionValues:["DisableLanguageExtensions"])=='TRUE') {
         TempLine=TempLine' /Za';
      }
   }
   if (OptionValues._indexin("NoHRESULT")) {
      if (upcase(OptionValues:["NoHRESULT"])=='TRUE') {
         TempLine=TempLine' /noHRESULT';
      }
   }
   if (OptionValues._indexin("RuntimeTypeInfo")) {
      if (upcase(OptionValues:["RuntimeTypeInfo"])=='TRUE') {
         TempLine=TempLine' /GR';
      }
   }
   if (OptionValues._indexin("DefaultCharIsUnsigned")) {
      if (upcase(OptionValues:["DefaultCharIsUnsigned"])=='TRUE') {
         TempLine=TempLine' /J';
      }
   }
   if (OptionValues._indexin("UsePrecompiledHeader")) {
      if (OptionValues:["UsePrecompiledHeader"]==1) {
         TempLine=TempLine' /Yc';
      } else if (OptionValues:["UsePrecompiledHeader"]==2) {
         if (vs_version >= 8.0) {
            // /YX is not supported in the 2005 version of cl, instead
            // Visual Studio makes the distinction between /Yu and /Yc
            // when the project is set to "Automatic."  Blindly using
            // /Yu will work in most cases and when it doesn't, the
            // user will have to perform a full build first.
            TempLine=TempLine' /Yu';
         } else {
            TempLine=TempLine' /YX';
         }

      } else if (OptionValues:["UsePrecompiledHeader"]==3) {
         TempLine=TempLine' /Yu';
      }

      if (OptionValues:["UsePrecompiledHeader"]!=0) {

         if (OptionValues._indexin("PrecompiledHeaderThrough")) {
            _str through_filename=OptionValues:["PrecompiledHeaderThrough"];
            through_filename=VisualStudioVCPPExpandAllMacros(ConfigName,through_filename);
            TempLine=TempLine:+cmdline_quote_filename(through_filename);
         } else {
            TempLine=TempLine'"stdafx.h"';
         }

         _str vcppProjectFilename=GetProjectDisplayName(ProjectFilename);

         _str pchFile;
         int status=GetItemFromVCProj(vcppProjectFilename,ConfigName,'PrecompiledHeaderFile',pchFile);
         if ((status==0)&&(pchFile:!='')) {
            TempLine=TempLine:+' /Fp'cmdline_quote_filename(pchFile);
         }
      }
   }

   // if nothing is specified, use the default
   _str pdbfilename='$(IntDir)/vc'first_char(vs_version)'0.pdb';
   if (OptionValues._indexin("ProgramDataBaseFileName")) {
      pdbfilename=OptionValues:["ProgramDataBaseFileName"];
   }
   // if '' is specified, don't use anything
   if (pdbfilename:!='') {
      pdbfilename=VisualStudioVCPPExpandAllMacros(ConfigName,pdbfilename);
      TempLine=TempLine' /Fd'cmdline_quote_filename(pdbfilename);
   }

   if (OptionValues._indexin("ForcedUsingFiles")) {
      _str val=OptionValues:["ForcedUsingFiles"];
      TempLine=TempLine' /FU'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,val));
   }

   typeless referencesNodes[];
   _xmlcfg_find_simple_array(handle,'VisualStudioProject/References/AssemblyReference',referencesNodes);

   if (referencesNodes._length()) {
      int refIndex=0;
      _str frameworkLocation=VisualStudioVCPPExpandAllMacros(ConfigName,'$(FRAMEWORKDIR)$(FRAMEWORKVERSION)':+FILESEP);

      for (;refIndex<referencesNodes._length();++refIndex) {
         _str assemblyRelName=_xmlcfg_get_attribute(handle,referencesNodes[refIndex],'RelativePath');
         _str assemblyFile=frameworkLocation:+assemblyRelName;
         TempLine=TempLine' /FU'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,assemblyFile));
      }
   }

   if (OptionValues._indexin("AssemblerOutput")) {
      boolean checkFa=true;
      if (OptionValues:["AssemblerOutput"]==1) {
         TempLine=TempLine' /FA';
      } else if (OptionValues:["AssemblerOutput"]==2) {
         TempLine=TempLine' /FAcs';
      } else if (OptionValues:["AssemblerOutput"]==3) {
         TempLine=TempLine' /FAc';
      } else if (OptionValues:["AssemblerOutput"]==4) {
         TempLine=TempLine' /FAs';
      } else {
         checkFa=false;
      }

      if (checkFa) {
         if (OptionValues._indexin("AssemblerListingLocation")) {
            _str val=OptionValues:["AssemblerListingLocation"];
            TempLine=TempLine' /Fa'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,val));
         }
      }
   }

   if (OptionValues._indexin("ObjectFile")) {
      _str val = VisualStudioVCPPExpandAllMacros(ConfigName, OptionValues:["ObjectFile"]);
      TempLine=TempLine' /Fo'cmdline_quote_filename(val);
   } else {
      TempLine=TempLine' /Fo'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,'$(INTDIR)/'));
   }

   if (OptionValues._indexin("ExpandAttributedSource")) {
      if (upcase(OptionValues:["ExpandAttributedSource"])=='TRUE') {
         TempLine=TempLine' /Fx';
      }
   }

   if (OptionValues._indexin("BrowseInformation")) {
      boolean setBrowseFile=false;
      if (OptionValues:["BrowseInformation"]==1) {
         TempLine=TempLine' /FR';
         setBrowseFile=true;
      } else if (OptionValues:["BrowseInformation"]==2) {
         TempLine=TempLine' /Fr';
         setBrowseFile=true;
      }
      if (setBrowseFile) {
         if (OptionValues._indexin("BrowseInformationFile")) {
            TempLine=TempLine:+cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,OptionValues:["BrowseInformationFile"]));
         } else {
            _str newfname = VisualStudioVCPPExpandAllMacros(ConfigName,"$(IntDir)/");
            _str ProjectPath=_strip_filename(ProjectFilename,'N');
            TempLine = TempLine:+cmdline_quote_filename(ConvertToVCPPRelFilename(_RelativeToProject(newfname,ProjectFilename),ProjectPath));
         }
      }

   }
   if (OptionValues._indexin("UndefineAllPreprocessorDefinitions")) {
      if (upcase(OptionValues:["UndefineAllPreprocessorDefinitions"])=='TRUE') {
         TempLine=TempLine' /u';
      }
   }
   if (OptionValues._indexin("UndefinePreprocessorDefinitions")) {
      _str val=OptionValues:["UndefinePreprocessorDefinitions"];
      TempLine=TempLine' /U'cmdline_quote_filename(VisualStudioVCPPExpandAllMacros(ConfigName,val));
   }
   if (OptionValues._indexin("CompileAs")) {
      if (OptionValues:["CompileAs"]==1) {
         TempLine=TempLine' /TC';
      } else if (OptionValues:["CompileAs"]==2) {
         TempLine=TempLine' /TP';
      }
   }
   if (OptionValues._indexin("ShowIncludes")) {
      if (upcase(OptionValues:["ShowIncludes"])=='TRUE') {
         TempLine=TempLine' /showIncludes';
      }
   }
   if (OptionValues._indexin("DisableSpecificWarnings")) {
      _str DisabledWarnings=OptionValues:["DisableSpecificWarnings"];

      for (;;) {
         _str cur;
         parse DisabledWarnings with cur ';' DisabledWarnings;
         if (cur=='') break;
         TempLine=TempLine' /wd'cur;
      }
   }
   if (OptionValues._indexin("ForcedIncludeFiles")) {
      _str ForcedIncludeFiles=OptionValues:["ForcedIncludeFiles"];

      for (;;) {
         _str cur;
         parse ForcedIncludeFiles with cur ';' ForcedIncludeFiles;
         if (cur=='') break;
         _str translatedCur = VisualStudioVCPPExpandAllMacros(ConfigName,cur);
         TempLine=TempLine' /FI 'cmdline_quote_filename(translatedCur);
      }
   }
   if (OptionValues._indexin("CallingConvention")) {
      if (OptionValues:["CallingConvention"]==0) {
         TempLine=TempLine' /Gd';
      } else if (OptionValues:["CallingConvention"]==1) {
         TempLine=TempLine' /Gr';
      } else if (OptionValues:["CallingConvention"]==2) {
         TempLine=TempLine' /Gz';
      }
   }
   if (OptionValues._indexin("ForceConformanceInForLoopScope")) {
      if (upcase(OptionValues:["ForceConformanceInForLoopScope"])=='TRUE') {
         TempLine=TempLine' /Zc:forScope';
      }
   }

   if (OptionValues._indexin("AdditionalOptions")) {
      _str additional_options = VisualStudioVCPPExpandAllMacros(ConfigName,OptionValues:["AdditionalOptions"],SourceFilename);
      TempLine = TempLine" "additional_options;
   }

   _str all_includes=_ProjectGet_IncludesForFile(_ProjectHandle(),SourceFilename,true,ConfigName);
   _str cur_include;
   while (all_includes:!='') {
      parse all_includes with cur_include PATHSEP all_includes;
      cur_include=strip(cur_include,'B','"');
      if ((cur_include:!='%(INCLUDE)')&&(cur_include:!='')) {
         TempLine=TempLine' /I 'cmdline_quote_filename(cur_include);
      }
   }

   if (OptionValues._indexin("AdditionalUsingDirectories")) {
      all_includes = OptionValues:["AdditionalUsingDirectories"];
      while (all_includes:!='') {
         parse all_includes with cur_include PATHSEP all_includes;
         cur_include=strip(cur_include,'B','"');
         if ((cur_include:!='%(INCLUDE)')&&(cur_include:!='')) {
            TempLine=TempLine' /AI 'cmdline_quote_filename(cur_include);
         }
      }
   }

   TempLine=TempLine' /c ';   // Compile only, do not link
   //TempLine=makeCommandCLSafe(TempLine);  // don't need this here
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   insert_line(TempLine);
   int status=_save_file('+o 'maybe_quote_filename(TempFilename));
   TempFilename=_vcpp_compiler_option_tempfile;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

static void GetVCPPMacros(int handle,int CurConfigIndex,_str ProjectFilename,_str SourceFilename,
                          _str (&VCPPMacros):[])
{
   _str ConfigDir='';
   ConfigDir=_xmlcfg_get_attribute(handle,CurConfigIndex,"OutputDirectory");
   if (ConfigDir=='') return;

   ConfigDir=absolute(ConfigDir,_strip_filename(ProjectFilename,'NE'));

   VCPPMacros:['$(IntDir)']=ConfigDir;
   VCPPMacros:['$(TargetName)']=_strip_filename(SourceFilename,'PE');
}

static _str ExpandVCPPMacros(_str (&VCPPMacros):[],_str Path)
{
   if (VCPPMacros._indexin('$(IntDir)')) {
      Path=stranslate(Path,VCPPMacros:['$(IntDir)'],'$(IntDir)');
   }
   if (VCPPMacros._indexin('$(TargetName)')) {
      Path=stranslate(Path,VCPPMacros:['$(TargetName)'],'$(TargetName)');
   }
   Path=stranslate(Path,FILESEP,FILESEP2);
   return(Path);
}

static void GetVCPPConfigInfo(int handle,int CurConfigIndex,_str (&OptionValues):[])
{
   typeless attrNode=_xmlcfg_get_next_attribute(handle,CurConfigIndex);
   while (attrNode>=0) {
      OptionValues:[_xmlcfg_get_name(handle,attrNode)]=_xmlcfg_get_value(handle,attrNode);
      attrNode=_xmlcfg_get_next_attribute(handle,attrNode);
   }
}

int _exit_delete_html_tempfiles()
{
   if (_html_tempfile!='') {
      delete_file(_html_tempfile);
      _html_tempfile='';
   }
   if (_vcpp_compiler_option_tempfile!='') {
      delete_file(_vcpp_compiler_option_tempfile);
      _vcpp_compiler_option_tempfile='';
   }
   return(0);
}
void _before_write_state_delete_html_tempfiles()  {
   _exit_delete_html_tempfiles();
}


static _str BuildTempAppletFile(int handle,_str config)
{
   if (_html_tempfile=='') {
      _html_tempfile=mktemp(1,'.html');
   }
   _str Filename=_html_tempfile;
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=0;
   insert_line('<html>');
   insert_line('<head>');
   insert_line('<title>SlickEdit</title>');
   insert_line('</head>');
   insert_line('<body>');

   int TargetNode=_ProjectGet_TargetNode(handle,'execute',config);
   _str appletClass=_ProjectGet_TargetAppletClass(handle,TargetNode);
   if (appletClass=='') {
      appletClass=_strip_filename(_project_name,'PE')'.class';
   }
   if (!file_eq(_get_extension(appletClass),'.class')) {
      appletClass=_strip_filename(appletClass,'E')'.class';
   }
   //APPLETVIEWER DOES NOT LIKE BACK SLASHES
   appletClass=stranslate(appletClass,'/',FILESEP);

   _str codeBase=stranslate(getActiveProjectConfigObjDir(),'/',FILESEP);
   if ( last_char(codeBase)!='/' ) codeBase=codeBase'/';

   insert_line('<applet code="'appletClass'" codebase="file:///'codeBase'" width="400" height="300"></applet>');
   insert_line('</body>');
   insert_line('</html>');
   _save_file('+o 'maybe_quote_filename(Filename));
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   _str URLStyleFilename='file:///'stranslate(Filename,'/',FILESEP);
   return(URLStyleFilename);
}

/**
 * Finds the next error.  Cursor is placed on the line and column of the
 * file with error.
 *
 * @see next_error
 *
 * @categories Miscellaneous_Functions
 *
 */
xnext_error2()
{
   /* remove error file if one already present. */
   if ( _error_file=='' ) {
      _error_file=absolute(COMPILE_ERROR_FILE);
      //_error_file=GetErrorFilename();//GetErrorFilename sets COMPILE_ERROR_FILE
   }
   _str filename=buf_match(absolute(_error_file),1,'X');
   // IF error buffer already exists?
   _str options;
   if ( filename!='') {
      options='+l +d +r ';
   } else {
      options='+l +d ';
   }
   int view_id,status=0;;
   get_window_id(view_id);
   if (iswildcard(_error_file) && !file_exists(_error_file)) {
      status=FILE_NOT_FOUND_RC;
   } else if (file_match('-p 'maybe_quote_filename(_error_file),1)!='') {
      status=edit(' +bp 'options maybe_quote_filename(_error_file));
   } else {
      status=FILE_NOT_FOUND_RC;
   }
   if ( status ) {
      if (status==FILE_NOT_FOUND_RC) {
         message(nls("File '%s' not found",maybe_quote_filename(_error_file)));
      } else {
         message(get_message(status));
      }
      return(status);
   }
   return(next_error());
}
/**
 * Quits SlickEdit's temporary compiler error message output file.
 * This procedure is called before compiler error messages are redirected.
 *
 * @categories Buffer_Functions
 *
 */
void quit_error_file(...)
{
   _str filename;
   if ( arg(1)!='' ) {
      filename=absolute(arg(1));
   } else {
      filename=absolute(COMPILE_ERROR_FILE);
   }
   if ( buf_match(filename,1)=='' ) {
      return;
   }
   int status=edit('+q +b 'maybe_quote_filename(filename));
   if (!status) {
      p_modify=0;
      quit(false);
   }
}
_str getPackageName()
{
   _str packageName='';
   save_pos(auto p);
   top();
   int status = search('^[ \t]*package','@erhwxcs');
   if (status) {
      restore_pos(p);
      return('');
   } else {
      get_line(auto line);
      parse line with . packageName';';
      restore_pos(p);
      return(packageName);
   }

}

static void MaybeSetTornadoEnvironmemt()
{
#if !__UNIX__
   if (get_env('WIND_BASE')=='') {
      _str value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoWorkspaceType\\shell\\open\\command","");
      if (value=='' || def_tornado_version==2) {
         value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\TornadoSourceType\\shell\\open\\command","");
      }
      value=parse_file(value);
      _str path=_strip_filename(value,'N');
      int temp_view_id,orig_view_id;
      int status=_open_temp_view(path:+'torVars.bat',temp_view_id,orig_view_id);
      if (!status) {
         top();up();
         while (!down()) {
            get_line(auto line);
            if (substr(line,1,3)=='set') {
               _str SetExpr;
               parse line with 'set ' SetExpr;
               p_window_id=orig_view_id;
               set(SetExpr);//If we do it this way, it gets set in the process buffer too.
                            //We have to be sure to set orig_view_id to be active though.

               p_window_id=temp_view_id;
            }
         }
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
   }
#endif
}

_command void tornadorebuild() name_info(','VSARG2_EDITORCTL)
{
   _str info;
   int TargetNode=_ProjectGet_TargetNode(_ProjectHandle(_project_name),'build',GetCurrentConfigName());
   _str cmd=_ProjectGet_TargetCmdLine(_ProjectHandle(_project_name),TargetNode);

   _str cmdline;
   parse cmd with . cmdline;
   tornadomake(cmdline,'clean');
#if 0
   _str bufname='',word='';
   if (!_no_child_windows()) {
      bufname=_mdi.p_child.p_buf_name;
      word=_mdi.p_child.cur_word(junk);
   }
   cmdline=_parse_project_command(cmdline,bufname,_project_name,word);
   concur_command('make 'cmdline,1);
   //tornadomake(cmdline);
#endif
}
_command int tornadomake(_str cmdline="",_str target='') name_info(','VSARG2_EDITORCTL)
{
   if (_project_name=='') {
      return(FILE_NOT_FOUND_RC);
   }
   tornadomake2(cmdline,target);
   if (pos(' rclean',cmdline)) {
      // If this is a clean command, go ahead and rebuild.
      // This makes it like Tornado's Rebuild command
      int TargetNode=_ProjectGet_TargetNode(_ProjectHandle(_project_name),'build',GetCurrentConfigName());
      _str nextcmdline=_ProjectGet_TargetCmdLine(_ProjectHandle(_project_name),TargetNode);
      if (nextcmdline!='' && !pos('rclean',nextcmdline) ) {
         // check to be sure that rclean isn't in the nextcmdline, so we
         // don't wind up in an infinite loop
         if (substr(nextcmdline,1,12)=='tornadomake ') {
            nextcmdline=substr(nextcmdline,13);
         }
         tornadomake2(nextcmdline);
      }
   }
   return(0);
}

static void tornadomake2(_str cmdline,_str target='')
{
   _str bufname='',word='';
   if (!_no_child_windows()) {
      int junk;
      bufname=_mdi.p_child.p_buf_name;
      word=_mdi.p_child.cur_word(junk);
   }
   //Still have to do this just in case.  The "Extra" items
   //(Build (DEFAULT_RULE=xxx)) have don't get parsed first
   cmdline=_parse_project_command(cmdline,bufname,_project_name,word);
   MaybeSetTornadoEnvironmemt();
   _str Config,rest;
   parse cmdline with 'BUILD_SPEC=' Config rest;
   if (!_process_info('r')) {
      start_process();
   }
   mkdir(_strip_filename(_project_name,'N'):+Config);
   _process_cd(_strip_filename(_project_name,'N'):+Config);
   reset_next_error();
   if (target!='') {
      // make sure there is nothing in the command that could break it
      cmdline = makeCommandCLSafe(cmdline);
      concur_command('make 'cmdline' 'target'&':+'make 'cmdline,1);
   } else {
      // make sure there is nothing in the command that could break it
      cmdline = makeCommandCLSafe(cmdline);
      concur_command('make 'cmdline' 'target,1);
   }
}

static void _project_convert_command(_str &command,_str buf_name='',_str field_name='',int handle=-1,_str config='')
{
   _str cmdname;
   parse command with cmdname .;
   switch (cmdname) {
   case 'javamake':
   case 'javamakedoc':
   case 'javarebuild':
   case 'cppmake':
   case 'cpprebuild':
   case 'cppclean':
      // 7.0  command=maybe_quote_filename(get_env('VSLICKBIN1')'vsbuild')' "%t" "%w" "%r" -'stranslate(command,'%%','%');
      command=maybe_quote_filename(get_env('VSLICKBIN1')'vsbuild')' -t "%t" "%w" "%r"';
      break;
   case 'antmake':
      command=maybe_quote_filename(get_env('VSLICKBIN1')'vsbuild')' -t "%t" "%w" "%r"';
      if (def_antmake_use_classpath == 0) {
         command = command :+ ' -noclasspath'; 
      }
      break;
   case 'javamakejar':
      command=maybe_quote_filename(get_env('VSLICKBIN1')'vsbuild')' -t "%t" "%w" "%r" -execmacro make_jad %r';
      break;
   case 'vstudiocompile':
      if (buf_name!='') {
         // This is ok because if buf_name is not passed in, we are doing a
         // build instead of a compile and this shouldn't happen anyway.
         _str ext=_get_extension(lowcase(buf_name));
         _str lang=_Ext2LangId(ext);
         _str CommandLine='';
         if (lang == 'c' || lang == 'ansic') {
            CreateVCPPOptionsFile(buf_name, _project_name, config, CommandLine);
            command = CommandLine;

         } else if (lang == 'rc' || ext=='rc') {
            CreateRCOptionsLine(buf_name, _project_name, config, CommandLine);
            command = CommandLine;
         }
      }
      break;
   case 'xcodecompile':
      command=_xcode_make_compile_command(buf_name);
      break;
   default:
      // 9/12/2005 - RB
      // Auto makefile case already calls pre- and post-build commands. Using
      // vsbuild to run a build/rebuild would end up calling them twice. Worse,
      // the dependent projects would get built twice (once by vsbuild, once by
      // the auto makefile.
      if (!alreadyUsing_vsbuild(command) && !strieq(_ProjectGet_BuildSystem(handle), "automakefile")) {
         if ((field_name=='build' || field_name=='rebuild')) {
            _str PreBuildCommandsNode=_ProjectGet_PreBuildCommandsNode(handle,config);
            _str PostBuildCommandsNode=_ProjectGet_PostBuildCommandsNode(handle,config);
            if (PreBuildCommandsNode>=0 || PostBuildCommandsNode>=0) {
               command=maybe_quote_filename(get_env('VSLICKBIN1')'vsbuild')' "%t" "%w" "%r"';
               /*  This case will never happen because our make and rebuild commands
                   for GNU projects already have vsbuild in the ocmmand line.
               _ini_get_value(_project_name, _project_get_section(section_name), 'compile', compile_info);
               compile_flags=_ProjectGetStr(compile_info,"copts");
               if (pos(compile_flags,'_gnuc_options_form')) {
                  command=command' -cpp'field_name;
               }*/
            }
         }
      }
   }
}

/*int _OnUpdate_javaviewdoc(CMDUI &cmdui,int target_wid,_str command)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   return((target_wid.p_LangId=='java' || target_wid.p_LangId=='html')?MF_ENABLED:MF_GRAYED);
}
*/
_command void javaviewdoc()  name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_EDITORCTL)
{
   // Check if the source file is newer than the HTML file

   boolean doCurrentFile=true;
   doCurrentFile=_isEditorCtl() && p_LangId=='java' && p_buf_name!='';
   if (!doCurrentFile && _project_name=='') {
      html_preview();
      return;
   }
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   int TargetNode=_ProjectGet_TargetNode(handle,'Javadoc All',config);
   _str cmd=_ProjectGet_TargetCmdLine(handle,TargetNode);

   if (cmd=='') {
      if (!doCurrentFile) {
         html_preview();
         return;
      }
      _message_box("This project does not have a Javadoc All command");
      return;
   }
   boolean doRebuild=false;
   _str output_path='',rest='';
   parse cmd with ' -d 'rest;
   _cdb4compile(handle,(int)TargetNode);
   if (rest!='') {
      output_path=parse_file(rest,false);
      if ( last_char(output_path)!=FILESEP) {
         output_path=output_path:+FILESEP;
      }
      output_path=absolute(output_path);
      if (output_path!='') {
         make_path(output_path);
      }
   }
   _str filename;
   if (!doCurrentFile) {
      filename=output_path'index.html';
   } else {
      if ( p_modify ) {
         if ( save() ) return;
      }
      _str package=getPackageName();
      package=translate(package,FILESEP,'.');
      if (output_path!='') {
         filename=output_path;
      } else {
         filename=_strip_filename(p_buf_name,'N');
      }
      if (package!='' && last_char(package)!=FILESEP) {
         package=package:+FILESEP;
      }
      filename=filename:+package:+_strip_filename(p_buf_name,'PE')'.html';
   }

   if ( !file_exists(filename) ) {
      _str dlg_message = "", title = "";

      // Check to see if the file exists.
      if ( doCurrentFile ) {
         dlg_message = "Javadoc file for this class does not exist.  Do you want to rerun javadoc now?" :+
            "  If you choose yes, please run this command again after javadoc is successfully built.";
         title = "Javadoc File Not Found";
      } else {
         dlg_message = "Javadoc was never created for this project.  Do you want to run javadoc now?" :+
            "  If you choose yes, please run this command again after javadoc is successfully built.";
         title = "Javadoc Not Run";
      }

      if ( dlg_message != "" ) {
         if ( _message_box( dlg_message, title, MB_YESNO ) == IDNO )
            return;
         doRebuild = true;
      }

   } else if ( p_file_date > _file_date(filename,'B') ) {
      // Is the source file modified since the late time javadoc was run?
      int _ret = _message_box(
         "The source file is modified since the last time the javadoc was created.":+
         "  Do you want to rebuild javadoc now?":+
         "  If you choose yes, please run this command again after javadoc is successfully built.",
         "Javadoc File May Be Old", MB_YESNO );
      if ( _ret == IDYES )
         doRebuild = true;
      else
         doRebuild = false;
   }

   if ( doRebuild ) {
      //say('info='info);
      if ( def_auto_reset ) reset_next_error();
      // Don't clear next error because this does clears our message
      def_auto_reset=false;
      _dos_NextErrorIfNonZero=true;
      _dos_quiet=true;
      message('Running javadoc compiler...');
      // So we don't destroy the index, we need to do a javadoc all
      int status=project_usertool("Javadoc All",false,true);
      if (!status) {
         clear_message();
      }
      def_auto_reset=true;
      _dos_NextErrorIfNonZero=false;
      _dos_quiet=false;
   } else {
#if __UNIX__
      // If a file name is given as a regular full path i.e. /path/to/file,
      // the mozilla-family browser launches only when it is the first instance.
      // So, the filename must be in the form "file:///path/to/file".
      filename = "file://" :+ filename;
#endif
      goto_url(filename);
   }
}
defeventtab _java_rebuild_now_form;
void ctlyes.on_create(int rebuildJar=0)
{
   if (rebuildJar<0) {
      ctlrebuildjar.p_visible=false;
   } else {
      ctlrebuildjar.p_value=rebuildJar;
   }
}
void ctlyes.lbutton_up()
{
   _param1=ctlrebuildjar.p_value;
   p_active_form._delete_window(1);
}
void ctlno.lbutton_up()
{
   p_active_form._delete_window('');
}
static int _set_java_environment2(_str java_root, boolean quiet=false)
{
   _str path;
   _str javac_filename=_orig_path_search('javac');
   if (javac_filename!="") {
      javac_filename=absolute(javac_filename);
      if (java_root=='') {
         if (!quiet) {
            _message_box('Java is already setup.  javac is already in your PATH.');
         }
         _restore_origenv(true);
         return(0);
      }
      path=_strip_filename(javac_filename,'n');
#if __UNIX__
      if (file_eq(path,'/usr/bin/') && _isJavaInstallDirKaffe(def_jdk_install_dir)) {
         if (!quiet) {
            _message_box('Java is already setup.  javac is already in your PATH.');
         }
         _restore_origenv(true);
         return(0);
      }
#endif
      // IF the javac found is in the correct jdk_install_dir
      if (file_eq(path,java_root:+'bin':+FILESEP)) {
         // Use the original environment
         if (!quiet) {
            _message_box('Java is already setup.  javac is already in your PATH.');
         }
         _restore_origenv(true);
         return(0);
      }
   }
   if (java_root!='') {
      if (!file_exists(java_root'bin':+FILESEP:+'javac':+EXTENSION_EXE)) {
         return(1);
      }
      _restore_origenv(false);
      set('PATH='java_root'bin':+PATHSEP:+get_env('PATH'));
      return(0);
   }
#if __UNIX__
   return(1);
   // Some more work here...
#else
   _str key='Software\JavaSoft\Java Development Kit';
   javahome := _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, key, '', "JavaHome");
   if (javahome=="") {
      if (!quiet) {
         _message_box('JavaHome value not found at HKEY_LOCAL_MACHINE\':+key);
      }
      return(1);
   }
   _maybe_append_filesep(javahome);
   // JDK version 1.4 does not set JavaHome correctly.  It incorrectly points to the JRE stuff.
   //say('h1 javahome='javahome);
   if (!file_exists(javahome'bin':+FILESEP:+'javac.exe')) {
      // This is not great.  Using the path on java.exe gets the last JDK installation.
      // It could even get you a directory for some other products JDK installation.
      //say('h2');
      _str javaexe=_ntRegQueryValue(
         HKEY_LOCAL_MACHINE,
         'Software\Microsoft\Windows\CurrentVersion\App Paths\java.exe',
         ""  // DefaultValue
         );
      if (javaexe=="") {
         return(1);
      }
      javahome=_strip_filename(javaexe,'N');
      if (!file_exists(javahome'javac.exe')) {
         return(1);
      }
      // Strip the 'bin' directory
      javahome=substr(javahome,1,length(javahome)-1);
      javahome=_strip_filename(javahome,'N');
   }
   _restore_origenv(false);
   set('PATH='javahome'bin;'get_env('PATH'));
   return(0);
#endif
}

_command int set_java_environment(boolean quiet=false, int handle=-1, _str config='', boolean useJDWP = false)
{
   boolean JDWPSupported = true;
#if __UNIX__
   // For the Linux kaffe case, def_jdk_install_dir is either '' or /usr/share
   // Kaffe does not support the JDWP debugging API.
   if (_isJavaInstallDirKaffe(def_jdk_install_dir)) {
      if (useJDWP) {
         JDWPSupported=false;
      }
   }
#endif

   _str path = def_jdk_install_dir;
   if (handle != -1 && config != '') {
      _str compiler_name = _ProjectGet_ActualCompilerConfigName(handle, config);
      if (compiler_name != '') {
         _str compiler_root = '';
         int status = refactor_config_get_java_source(compiler_name, compiler_root);
         if (!status && compiler_root != '') {
            // Be sure there is a compiler here, in case refactor_config_get_java_source
            // returns something that was tagged, but does not actually have a compiler
            javaPath := compiler_root;
            _maybe_append_filesep(javaPath);
            javaPath = javaPath:+"bin":+FILESEP;
#if __UNIX__
            _str java_name = "java";
#else
            _str java_name = "java.exe";
#endif
            if ( file_exists(javaPath:+java_name) ) {
               path = compiler_root;
            }
         }
      }
   }
   if (JDWPSupported) {
      if (!_set_java_environment2(path, quiet) || _project_name=='') return(0);
   }
   if (handle<0) {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   }
   _str packname=_ProjectGet_Type(handle,config);
   if (strieq(packname,'java')) {
      if (!JDWPSupported) {
         _message_box("The Java debugger does not support KAFFE. Install a SUN Java JDK to use the Java debugger\n\nSet the JDK installation directory so the JDK programs can be found");
      } else {
         _message_box("Set the JDK installation directory so the JDK programs can be found");
      }
      javaoptions();
      if (!JDWPSupported) {
         if (_isJavaInstallDirKaffe(def_jdk_install_dir)) {
            // Can't use KAFFE with Java debugger
            return(1);
         }
      }
      // Try again
      return(_set_java_environment2(path, quiet));
   }
   return(0);
}

/**
 * Prepares the environment for running Ant.  Both ANT_HOME
 * and JAVA_HOME are guaranteed to be set if this function
 * succeeds.  Values found in def_jdk_install_dir and
 * def_ant_install_dir take precedence.  If they are not
 * found, the environment will be checked for existing
 * values.  If all else fails, a path search will be performed.
 *
 * @return 0 on success, <0 otherwise
 */
_command int set_ant_environment(int handle = -1, _str config = "")
{
   if (_project_name == "") return 0;

   if (handle<0) {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   }

   // see if this is a java project
   _str packname=_ProjectGet_Type(handle,config);
   boolean isJavaProject = strieq(packname, "java");

   // restore the original environment.  this is done so the
   // path for ant is not appended over and over
   _restore_origenv(true);

   _str origAntHome = _replace_envvars("%ANT_HOME%");
   if (origAntHome != "") {
      _maybe_append_filesep(origAntHome);
   }

   _str origJavaHome = _replace_envvars("%JAVA_HOME%");
   if (origJavaHome != "") {
      _maybe_append_filesep(origJavaHome);
   }

   // figure out what ANT_HOME should be
   //    ANT_HOME empty && def_ant_install_dir empty   SHOW JAVAOPTS
   //    ANT_HOME empty && def_ant_install_dir set     USE def_ant_install_dir
   //    ANT_HOME set   && def_ant_install_dir empty   USE EXISTING ENVVAR
   //    ANT_HOME set   && def_ant_install_dir set     ALWAYS USE def_ant_install_dir
   _str antHome = "";
   if (def_ant_install_dir != "") {
      // use def_ant_install_dir
      antHome = def_ant_install_dir;
   } else {
      if (origAntHome == "") {
         // if this is a java project, show the java options dialog so the directories can be set
         if (isJavaProject) {
            _message_box("Set the JDK and Ant installation directories so the programs can be found");
            javaoptions();
         } else {
            // not a java project so prompt user for installation dirs
            int status = _mdi.show("-modal _textbox_form", "JDK and Ant Installation Directories",
                                   TB_RETRIEVE, '', '',
                                   "OK,Cancel:_cancel\tSet the JDK and Ant installation directories so the programs can be found",//Button List
                                   "set_ant_environment",
                                   "-bd JDK installation directory:" def_jdk_install_dir,
                                   "-bd Ant installation directory:" def_ant_install_dir);
            if (status=='') return -1;

            // save the values entered and mark the configuration as modified
            def_jdk_install_dir = _param1;
            def_ant_install_dir = _param2;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         antHome = def_ant_install_dir;
      } else {
         antHome = origAntHome;
      }
   }

   // figure out what JAVA_HOME should be
   // (similar to ANT_HOME except do not show javaopts again)
   _str javaHome = "";
   if (def_jdk_install_dir != "") {
      // use def_jdk_install_dir
      javaHome = def_jdk_install_dir;
   } else if (origJavaHome != "") {
      javaHome = origJavaHome;
   } else {
      // not specified in def_jdk_install_dir and no previous JAVA_HOME set, so
      // do a path search for javac and try to infer the path from there.  if still
      // not found, just fall thru and an error will be returned
      _str javac = path_search("javac", "", "P");
      if (javac != "") {
         javaHome = _strip_filename(javac, "N");
         javaHome = strip(javaHome, "T", FILESEP);

         // remove 'bin' dir from the path
         javaHome = _strip_filename(javaHome, "N");
      }
   }

   // make sure both antHome and javaHome are paths now
   if (antHome == "" || javaHome == "") {
      return -1;
   }

   // set the environment (if necessary)
   if (!file_eq(antHome, origAntHome)) {
      // note that this must not end with a filesep or it will screw ant.bat up
      antHome = strip(antHome, "T", FILESEP);

      // set the environment and process buffer
      set_env("ANT_HOME", antHome);
      set("ANT_HOME=" antHome);
   }

   if (!file_eq(javaHome, origJavaHome)) {
      // note that this must not end with a filesep or it will screw ant.bat up
      javaHome = strip(javaHome, "T", FILESEP);

      // set the environment and process buffer
      set_env("JAVA_HOME", javaHome);
      set("JAVA_HOME=" javaHome);
   }

   // add ANT_HOME/bin and JAVA_HOME/bin to path
   _str path = _replace_envvars("%PATH%");
   _maybe_append(path, PATHSEP);
   path = path :+ javaHome;
   _maybe_append_filesep(path);
   path = path :+ "bin";
   _maybe_append(path, PATHSEP);
   path = path :+ antHome;
   _maybe_append_filesep(path);
   path = path :+ "bin";
   set_env("PATH", path);
   set("PATH=" path);

   // set classpath so that it matches what is in the editor
   _str classpath = _ProjectGet_ClassPathList(handle, config);
   if (classpath != "") {
      // parse the classpath for placeholders
      classpath = _parse_project_command(classpath, "", _project_name, "");

      // set the environment and process buffer
      set_env("CLASSPATH", classpath);
      set("CLASSPATH=" classpath);
   }

   return 0;
}

/**
 * Prepares the environment for running NAnt.  NANT_HOME is
 * guaranteed to be set if this function succeeds. The value 
 * found in def_ant_install_dir takes precedence. If not found, 
 * the environment will be checked for existing values. If all 
 * else fails, a path search will be performed. 
 *
 * @return 0 on success, <0 otherwise
 */
_command int set_nant_environment(int handle = -1, _str config = "")
{
   if (_project_name == "") return 0;

   if (handle<0) {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   }

   // restore the original environment.  this is done so the
   // path for NAnt is not appended over and over
   _restore_origenv(true);

   _str origNAntHome = _replace_envvars("%NANT_HOME%");
   if (origNAntHome != "") {
      _maybe_append_filesep(origNAntHome);
   }

   // figure out what NANT_HOME should be
   //    NANT_HOME empty && def_nant_install_dir empty   Prompt for value
   //    NANT_HOME empty && def_nant_install_dir set     USE def_ant_install_dir
   //    NANT_HOME set   && def_nant_install_dir empty   USE EXISTING ENVVAR
   //    NANT_HOME set   && def_nant_install_dir set     ALWAYS USE def_ant_install_dir
   _str nantHome = "";
   if (def_nant_install_dir != "") {
      // use def_ant_install_dir
      nantHome = def_nant_install_dir;
   } else {
      if (origNAntHome == "") {
         // Prompt user for installation directory
         int status = _mdi.show("-modal _textbox_form", "NAnt Installation Directory",
                                TB_RETRIEVE, '', '',
                                "OK,Cancel:_cancel\tSet the NAnt installation directory so the program can be found. \nSpecify the root directory, not the /bin subdirectory.",//Button List
                                "set_nant_environment",
                                "-bd NAnt installation directory:" def_nant_install_dir);
         if (status=='') return -1;

         // save the values entered and mark the configuration as modified
         def_nant_install_dir = _param1;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         nantHome = def_nant_install_dir;
      } else {
         nantHome = origNAntHome;
      }
   }

   // make sure both nantHome is a path
   if (nantHome == "") {
      return -1;
   }

   // set the environment (if necessary)
   if (!file_eq(nantHome, origNAntHome)) {
      // note that this must not end with a filesep or it will screw ant.bat up
      nantHome = strip(nantHome, "T", FILESEP);

      // set the environment and process buffer
      set_env("NANT_HOME", nantHome);
      set("NANT_HOME=" nantHome);
   }

   // add NANT_HOME/bin to path
   _str path = _replace_envvars("%PATH%");
   _maybe_append(path, PATHSEP);
   path = path :+ nantHome;
   _maybe_append_filesep(path);
   path = path :+ "bin";
   set_env("PATH", path);
   set("PATH=" path);

   return 0;
}

/**
 * Prepares the environment for running java programs that
 * require JAVA_HOME to be set.  JAVA_HOME is guaranteed
 * to be set if this function succeeds.  The value found in
 * def_jdk_install_dir takes precedence.  If it is not found,
 * the environment will be checked for an existing value.
 * If all else fails, a path search will be performed.
 *
 * @return 0 on success, <0 otherwise
 */
_command int set_java_home_environment(int handle = -1, _str config = "")
{
   if (_project_name == "") return 0;

   if (handle<0) {
      _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   }

   // see if this is a java project
   _str packname=_ProjectGet_Type(handle,config);
   boolean isJavaProject = strieq(packname, "java");

   // restore the original environment.  this is done so the
   // path for ant is not appended over and over
   _restore_origenv(true);

   _str origJavaHome = _replace_envvars("%JAVA_HOME%");
   if (origJavaHome != "") {
      _maybe_append_filesep(origJavaHome);
   }

   // figure out what ANT_HOME should be
   //    ANT_HOME empty && def_ant_install_dir empty   SHOW JAVAOPTS
   //    ANT_HOME empty && def_ant_install_dir set     USE def_ant_install_dir
   //    ANT_HOME set   && def_ant_install_dir empty   USE EXISTING ENVVAR
   //    ANT_HOME set   && def_ant_install_dir set     ALWAYS USE def_ant_install_dir
   _str javaHome = "";
   if (def_jdk_install_dir != "") {
      // use def_jdk_install_dir
      javaHome = def_jdk_install_dir;
   } else {
      if (origJavaHome == "") {
         // if this is a java project, show the java options dialog so the directories can be set
         if (isJavaProject) {
            _message_box("Set the JDK installation directory so the programs can be found");
            javaoptions();
         } else {
            // not a java project so prompt user for installation dirs
            int status = _mdi.show("-modal _textbox_form", "JDK Installation Directory",
                                   TB_RETRIEVE, '', '',
                                   "OK,Cancel:_cancel\tSet the JDK installation directory so the programs can be found",//Button List
                                   "set_java_home_environment",
                                   "-bd JDK installation directory:" def_jdk_install_dir);
            if (status=='') return -1;

            // save the values entered and mark the configuration as modified
            def_jdk_install_dir = _param1;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         javaHome = def_jdk_install_dir;
      } else {
         javaHome = origJavaHome;
      }
   }

   // make sure javaHome is a path now
   if (javaHome == "") {
      return -1;
   }

   // set the environment (if necessary)
   if (!file_eq(javaHome, origJavaHome)) {
      // note that this must not end with a filesep or it will screw ant.bat up
      javaHome = strip(javaHome, "T", FILESEP);

      // set the environment and process buffer
      set_env("JAVA_HOME", javaHome);
      set("JAVA_HOME=" javaHome);
   }

   // add JAVA_HOME/bin to path
   _str path = _replace_envvars("%PATH%");
   _maybe_append(path, PATHSEP);
   path = path :+ javaHome;
   _maybe_append_filesep(path);
   path = path :+ "bin";
   set_env("PATH", path);
   set("PATH=" path);

   // set classpath so that it matches what is in the editor
   _str classpath = _ProjectGet_ClassPathList(handle, config);
   if (classpath != "") {
      // parse the classpath for placeholders
      classpath = _parse_project_command(classpath, "", _project_name, "");

      // set the environment and process buffer
      set_env("CLASSPATH", classpath);
      set("CLASSPATH=" classpath);
   }

   return 0;
}

static _str select_main_callback(int sl_event,_str &result,_str info)
{
   if (sl_event==SL_ONINIT) {
      _nocheck _control _sellist;
      if (!_sellist._lbsearch(_strip_filename(_project_name,'pe'))) {
         _sellist._lbselect_line();
      }
   }
   return('');
}
static int _helpFindJavaMainClass(_str className,_str &compile_command)
{
   int status;
   className=strip(className,'B','"');
   if (className=='') {
      status=tag_read_db(_strip_filename(_workspace_filename,'E'):+TAG_FILE_EXT);
      _str filename;
      //_str package;
      _str tag_class;
      _str class_list[];
      if (status >= 0) {
         status=tag_find_equal('main',true);
         for (;;) {
            if (status) {
               break;
            }
            _str signature,type_name,package;
            int tag_flags;
            tag_get_detail(VS_TAGDETAIL_file_name,filename);
            tag_get_detail(VS_TAGDETAIL_arguments,signature);
            tag_get_detail(VS_TAGDETAIL_type,type_name);
            tag_get_detail(VS_TAGDETAIL_flags,tag_flags);
            //tag_get_detail(VS_TAGDETAIL_package,package);
            tag_get_detail(VS_TAGDETAIL_class_name,tag_class);
            if (_FileExistsInCurrentProject(filename) &&
                (
                (tag_flags & VS_TAGFLAG_static) && tag_tree_type_is_func(type_name) ||
                (!tag_tree_compare_args(
                   signature,
                   VS_TAGSEPARATOR_args:+"String args[]",true)
                )
                )
               ) {
               parse tag_class with package VS_TAGSEPARATOR_package className;
               if (className=='') {
                  className=package;
                  package='';
               }
               //say('className='className);
               //say('package='package);
               if (package!='') {
                  className=package'.'className;
               }
               class_list[class_list._length()]=className;
            }
            status=tag_next_equal(true);
         }
         tag_reset_find_tag();
      }
      if (!class_list._length()) {
         _message_box(nls("No 'static void main(String args[])' defined in project '%s'\n\nSet the main class (\"Build\",\"Java Options...\",select JRE tab)",_project_name));
         return(1);
      }
      if (class_list._length()!=1) {
         className=show('_sellist_form -mdi -modal -reinit',
                        'Select Main Class',
                        SL_SELECTCLINE,
                        class_list,
                        '',
                        '',                     // help item name
                        '',                     // font
                        select_main_callback,   // Call back function
                        '',                     // Item list separator
                        'select_main_class'     // retrieve form name
                       );
         if (className=='') {
            return(1);
         }

      }

      // if there is a main within an inner class, the subclass:innerclass syntax will
      // not be accepted by java.  change all ':' to '$'
      className = stranslate(className, "$", ":");

      if (pos(' . ',compile_command' ')) {
         //If there is a "." by itself, this is not a valid argument for java
         //this means that it was a placeholder so that we could put the
         //class name here
         compile_command=stranslate(compile_command' ',' 'className' ',' . ');
      } else {
         compile_command=compile_command' 'className;
      }
      //say(compile_command);
   }
#if 0
   _str orig_classPath=classPath;
   className=stranslate(className,FILESEP,'.');
   className=className:+'.class';
   for (;;) {
      parse classPath with filename (PATHSEP) classPath;
      if (filename=='' && classPath=='') {
         break;
      }
      if (filename=='') continue;
      if (last_char(filename)!=FILESEP) {
         strappend(filename,FILESEP);
      }
      if (file_exists(absolute(filename:+className,toDir))) {
         return(0);
      }
   }
   classpath=orig_classPath;
#endif
   return(0);

}

#if !__UNIX__
static int _copy_xlat(_str srcFilename,_str name,_str ext,_str destPath)
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(srcFilename,
                              temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   top();
   search(_chr(1):+'file':+_chr(1),'@E',name);
   top();
   search(_chr(1):+'ext':+_chr(1),'@E',ext);
   status=_save_file('+o 'maybe_quote_filename(destPath:+name:+_get_extension(srcFilename,true)));
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(status);
}
#endif
static int FixExecuteCommand(_str ProjectName,_str ConfigName)
{
   int handle=_ProjectHandle(ProjectName:+PRJ_FILE_EXT);
   int TargetNode=_ProjectGet_TargetNode(handle,'Execute',ConfigName);
   _ProjectSet_TargetCaptureOutputWith(handle,TargetNode,VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER);
   int status=_ProjectSave(handle);
   return(status);
}


int _on_autocreateworkspace_c(_str srcBufName,_str name)
{
   int status,result;
   _str path;
   _str DestWorkspaceFilename='';
   _str filename;
#if !__UNIX__
   _str value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\7.0","","InstallDir");
   if (value!='') {
      // User needs VC++ 7.0 or higher for this code to
      // work.
      path=_strip_filename(srcBufName,'N');
      DestWorkspaceFilename=path:+name:+'.sln';
      if (file_exists(DestWorkspaceFilename)) {
         return(workspace_open(DestWorkspaceFilename,'','',false));
      }
      DestWorkspaceFilename=path:+name:+'.vpw';
      if (file_exists(DestWorkspaceFilename)) {
         return(workspace_open(DestWorkspaceFilename,'','',false));
      }
      if (file_exists(path:+name:+'.vcproj') ||
          file_exists(path:+name:+'.vpj') ||
          file_exists(path:+name:+'.mak')
         ) {
         return(1);
      }
      result=_message_box('This build command requires an active project workspace. Would you like to create a default project workspace?','',MB_YESNOCANCEL|MB_ICONEXCLAMATION);
      if (result==IDCANCEL || result==IDNO) {
         return(1);
      }
      _str ext=_get_extension(srcBufName);
      status=_copy_xlat(get_env('VSROOT'):+'wizards\cpp\vcpp7\file.sln',
                        name,ext,path);
      if (status) {
         return(status);
      }
      status=_copy_xlat(get_env('VSROOT'):+'wizards\cpp\vcpp7\file.vcproj',
                        name,ext,path);
      if (status) {
         return(status);
      }
      status=workspace_open(path:+name:+'.sln','','',false);
      return(status);
   } else {
      // User needs VC++ 6.0 or higher for this code to
      // work.
      path=_strip_filename(srcBufName,'N');
      DestWorkspaceFilename=path:+name:+'.dsw';
      if (file_exists(DestWorkspaceFilename)) {
         return(workspace_open(DestWorkspaceFilename,'','',false));
      }
      DestWorkspaceFilename=path:+name:+'.vpw';
      if (file_exists(DestWorkspaceFilename)) {
         return(workspace_open(DestWorkspaceFilename,'','',false));
      }
      if (file_exists(path:+name:+'.dsp') ||
          file_exists(path:+name:+'.vpj') ||
          file_exists(path:+name:+'.mak')
         ) {
         return(1);
      }
      result=_message_box('This build command requires an active project workspace. Would you like to create a default project workspace?','',MB_YESNOCANCEL|MB_ICONEXCLAMATION);
      if (result==IDCANCEL || result==IDNO) {
         return(1);
      }
      _str ext=_get_extension(srcBufName);
      status=_copy_xlat(get_env('VSROOT'):+'wizards\cpp\vcpp\file.dsw',
                        name,ext,path);
      if (status) {
         return(status);
      }
      status=_copy_xlat(get_env('VSROOT'):+'wizards\cpp\vcpp\file.dsp',
                        name,ext,path);
      if (status) {
         return(status);
      }
      status=_copy_xlat(get_env('VSROOT'):+'wizards\cpp\vcpp\file.mak',
                        name,ext,path);
      if (status) {
         return(status);
      }

      status=workspace_open(path:+name:+'.dsw','','',false);
      if (status) {
         return(status);
      }
      status=FixExecuteCommand(path:+name,'COMPILER."CFG='name' - Win32 Release"');
      if (status) {
         return(status);
      }
      status=FixExecuteCommand(path:+name,'COMPILER."CFG='name' - Win32 Debug"');
      return(status);
   }
#else
   boolean workspaceAlreadyExists;
   status=_autocreateworkspace(srcBufName,name,'GNU C/C++',workspaceAlreadyExists);
   if (status==0 && !workspaceAlreadyExists) {
      // add the file to the newly created project
      _AddFileToProject(srcBufName);
   }
   return(status);
#endif
}

int _on_autocreateworkspace_java(_str srcBufName,_str name)
{
   return(_autocreateworkspace(srcBufName,name,'Java - Empty Project'));
}
int _autocreateworkspace(_str srcBufName,_str name,_str packageName,boolean &workspaceAlreadyExists=false)
{
   workspaceAlreadyExists=false;
   _str path=_strip_filename(srcBufName,'N');
   _str WorkspaceFilename=path:+name:+WORKSPACE_FILE_EXT;
   if (file_exists(WorkspaceFilename)) {
      workspaceAlreadyExists=true;
      return(workspace_open(WorkspaceFilename));
   }
   _str ProjectFilename=path:+name:+PRJ_FILE_EXT;
   if (file_exists(ProjectFilename)) {
      return(1);
   }
   int result=_message_box('This build command requires an active project workspace. Would you like to create a default project workspace?','',MB_YESNOCANCEL|MB_ICONEXCLAMATION);
   if (result==IDCANCEL || result==IDNO) {
      return(1);
   }
   int status=workspace_new_workspace2(WorkspaceFilename,false);
   if (status) {
      return(status);
   }
   status=workspace_new_project2(ProjectFilename,
                                 packageName,
                                 name,
                                 WorkspaceFilename,
                                 false,true,'','',
                                 false,null,true,true);
   toolbarUpdateWorkspaceList();
   return(status);
}
/*
static boolean find_javac_and_adjust_path(int handle, _str config, _str name, boolean useJDWP, boolean &JDWPSupported)
{
   JDWPSupported=true;
   _str javac_filename=path_search('javac',"","P");
   if (javac_filename=="") {
      return(true);
   }
   _str path=strip_filename(javac_filename,'n');
#if __UNIX__
   // For the Linux kaffe case, def_jdk_install_dir is either '' or /usr/share
   // Kaffe does not support the JDWP debugging API.
   if (_isJavaInstallDirKaffe(def_jdk_install_dir)) {
      if (useJDWP) {
         JDWPSupported=false;
         return(true);
      }
      return(false);
   }
#endif
   _str compiler_name = _ProjectGet_CompilerConfigName(handle, config);
   if (compiler_name != '') {
      _str compiler_root = '';
      int status = refactor_config_get_java_source(compiler_name, compiler_root);
      if (!status && compiler_root != '') {
         path = compiler_root;
      }
   }
   if (def_jdk_install_dir!='' && !file_eq(path,def_jdk_install_dir:+'bin':+FILESEP)) {
      return(true);
   }
#if __UNIX__
   return(false);
#endif
   if (!file_eq(name,'java')) {
      return(false);
   }
   // Make sure the correct java interpreter is found
   _str java_filename=path_search('java','','P');
   // IF we find the "java.exe" in the windows directory
   if (java_filename=='' || file_eq(_get_windows_directory(),
               substr(strip_filename(java_filename,'N'),1,length(_get_windows_directory()))
               )) {

      // java.exe should exists in the same directory as javac.exe
      java_filename=strip_filename(javac_filename,'n'):+'java.exe';
      if (file_exists(java_filename)) {
         set('PATH='strip_filename(javac_filename,'n')';'get_env('PATH'));
         return(false);
      }
      return(true);
   }
   if (file_exists(java_filename)) {
      return(false);
   }
   return(true);
}
*/
/*
This is pretty hard to write
boolean _FindJavaClass(_str className,_str classPath)
{
   className=stranslate(className,FILESEP,'.');
   className=className:+'.class';
   for (;;) {
      parse classPath with filename (PATHSEP) classPath;
      if (filename=='' && classPath=='') {
         break;
      }
      if (filename=='') continue;
      if(last_char(filename)!=FILESEP) {
         strappend(filename,FILESEP);
      }
      if (file_exists(absolute(filename:+className,toDir))) {
         return(0);
      }
   }
}
*/

/**
 * Find latest JBuilder install path
 */
static _str findLatestJBuilderInstall(boolean ignorePersonalEdition)
{
   _str jbuilderDir = "";
#if __UNIX__
#else
   // check for jbuilder 2006 developer
   jbuilderDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "Software\\Borland\\JBuilder\\2006\\Developer", "", "PathName");

   if (jbuilderDir == "") {
      // check for 8.0 install
      jbuilderDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "Software\\Borland\\JBuilder\\8.0", "", "PathName");

      // if no 8.0, check for 7.0 install
      if (jbuilderDir == "") {
         jbuilderDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, "Software\\Borland\\JBuilder\\7.0", "", "PathName");
      }
   }


#endif

   // make sure it ends in a filesep if it was found (_maybe_append_filesep
   // checks for empty string)
   _maybe_append_filesep(jbuilderDir);

   // if personal edition should be ignored, make sure the bin directory
   // contains bmj.exe on windows and bmj on unix
   if (jbuilderDir != "" && ignorePersonalEdition) {
      _str bmjFilename = jbuilderDir "bin" FILESEP;
#if __UNIX__
      bmjFilename = bmjFilename "bmj";
#else
      bmjFilename = bmjFilename "bmj.exe";
#endif
      // see if bmj exists
      if (!file_exists(bmjFilename)) {
         // not found so this must be personal edition
         jbuilderDir = "";
      }
   }

   return jbuilderDir;
}

/**
 * Setup path for JBuilder
 */
static int set_jbuilder_environment(_str name)
{
#if __UNIX__

#else
   // restore the original environment.  this is done so the
   // path for jbuilder is not appended over and over
   _restore_origenv(true);

   // get PATH envvar
   _str path = _replace_envvars("%PATH%");
   _maybe_append(path, PATHSEP);

   // find the jbuilder path
   _str jbuilderDir = findLatestJBuilderInstall(true);

   // return error if it was not found
   if (jbuilderDir == "") {
      return -1;
   }

   // add the bin subdir
   jbuilderDir = jbuilderDir "bin";

   // set the environment
   set_env("PATH", path :+ jbuilderDir);

   // set in process buffer
   set("PATH=" get_env("PATH"));
#endif

   return 0;
}

/**
 * Make the specified command safe for use on a command line.  This
 * is generally used to check for quoted parameters that end in a
 * backslash on Windows, which will escape the trailing quote.
 *
 * @param command
 *
 * @return Command line safe command
 */
_str makeCommandCLSafe(_str& command)
{
   // working copy
   _str safeCommand = command;

#if !__UNIX__
   safeCommand = stranslate(safeCommand, FILESEP FILESEP "\"", FILESEP "\"");
   //outputDebugString("mkcmdlnsf: " safeCommand);
#endif

   return safeCommand;
}

_str cmdline_quote_filename(_str filename)
{
   if (filename=='') {
      return('');
   }
   if (substr(filename,1,1)!='"') {
      filename='"'filename;
   }
   if (last_char(filename)!='"') {
      if (last_char(filename)=='\') {
         filename=filename'\';
      }
      filename=filename'"';
   }
   return(filename);
}


/**
 * Return the compile command that should be used for the
 * specified file (checked by extension)
 *
 * @param filename  File to find compile command for
 * @param projectHandle
 *                  Handle to project to retrieve commands from
 * @param config    Config to retrieve commands from
 * @param command_o Compile command that should be used
 * @param outputExtension_o
 *                  The extension that objects compiled with this command will have
 * @param compileRule_o
 *                  The name of the compile rule (ex: compile(.c .cpp))
 * @param copts_o   The copts associated with this compile command
 * @param allowDefault
 *                  T to return the default compile command if no match is found
 *
 * @return 0 on success, <0 otherwise
 */
int getExtSpecificCompileInfo(_str filename, int projectHandle, _str config, _str &command_o = "",
                              _str  &outputExtension_o= "", int &CompileRuleTargetNode_o=0,
                              boolean &LinkObject_o = true, boolean allowDefault = true)
{
   int status = 0;

   _str curCommand = "";
   _str defaultCompileCmd = "";
   _str defaultOutputExt = "";
   boolean defaultLinkObject= true;
   _str compileCmd = "";
   _str outputExt = "";
   boolean LinkObject =1;
   int ruleNode= -1;

   CompileRuleTargetNode_o= -1;
   outputExtension_o='';
   LinkObject_o=1;
   command_o='';

   // extract the extension of the file
   _str extension = _get_extension(filename, true);
   parse extension with '.' extension;

   //if (projectName=='') {
   if (projectHandle < 0) {
      if (allowDefault) {
         CompileRuleTargetNode_o= -1;
         return 0;
      }

      message("There is no default compile command for this project");
      return STRING_NOT_FOUND_RC;

   }

   int TargetNode=_ProjectGet_TargetNode(projectHandle,'compile',config);
   int defaultTargetNode=TargetNode;

   // get the default compile command
   if (TargetNode<0) {
      if (allowDefault) {
         CompileRuleTargetNode_o= -1;
         return 0;
      }

      message("There is no default compile command for this project");
      return STRING_NOT_FOUND_RC;
   }

   defaultCompileCmd = _ProjectGet_TargetCmdLine(projectHandle,TargetNode);
   defaultOutputExt = _ProjectGet_TargetOutputExts(projectHandle,TargetNode);
   defaultLinkObject = _ProjectGet_TargetLinkObject(projectHandle,TargetNode) != 0;
   curCommand = "";

   // store original view and switch to temp view
   int i,array[];
   _ProjectGet_Rules(projectHandle,array,'compile',config);
outerloop:
   for (i=0;i<array._length();++i) {
      TargetNode=array[i];
      _str InputExts=_ProjectGet_TargetInputExts(projectHandle,TargetNode);

      // check each extension to see if it applies to this file
      for (;;) {
         _str curExtension = "";
         parse InputExts with curExtension ";" InputExts;
         if (curExtension == "") {
            break;
         }
         parse curExtension with '.' curExtension;
         // does this command apply to this file
         if (file_eq(curExtension,extension)) {
            // save the rule
            ruleNode= TargetNode;
            compileCmd = _ProjectGet_TargetCmdLine(projectHandle,TargetNode);
            outputExt = _ProjectGet_TargetOutputExts(projectHandle,TargetNode);
            LinkObject = _ProjectGet_TargetLinkObject(projectHandle,TargetNode) != 0;

            //say("found cmd: " compileCmd "  outputext: " outputExt " copts: " copts);
            break outerloop;
         }
      }
   }

   // cleanup temp view
   if (compileCmd == "" && allowDefault) {
      command_o= defaultCompileCmd;
   } else {
      command_o= compileCmd;
   }

   if (compileCmd == "" && allowDefault) {
      outputExtension_o = defaultOutputExt;
   } else {
      outputExtension_o = outputExt;
   }

   // default the output extension if not specified
   if (outputExtension_o == "") {
#if __UNIX__
      outputExtension_o = ".o";
#else
      outputExtension_o = ".obj";
#endif
   }

   if (LinkObject_o != "") {
      if (compileCmd == "" && allowDefault) {
         LinkObject_o = defaultLinkObject;
      } else {
         LinkObject_o = LinkObject;
      }
   }

   if (ruleNode<0 && allowDefault) {
      CompileRuleTargetNode_o = defaultTargetNode;
   } else {
      CompileRuleTargetNode_o = ruleNode;
   }

   // if nothing was found and defaults were not allowed, return string not found
   if (ruleNode<0 && !allowDefault) {
      return STRING_NOT_FOUND_RC;
   }

   return 0;
}

/**
 * Post-build callback to call parse errors and display error markers
 *
 */
void _postbuild_build_set_error_markers()
{
   if (def_disable_postbuild_error_markers && def_disable_postbuild_error_scroll_markers) {
      return;
   }
   onlyErrorMarkers := def_disable_postbuild_error_markers && !def_disable_postbuild_error_markers;
   _str proj_name = arg(1);
   if (onlyErrorMarkers && proj_name != "") {
      int handle;
      _str config;
      _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
      _str packtype = _ProjectGet_Type(handle, config);
      if (strieq(packtype, "java") && def_java_live_errors_enabled) {
         return;  // live errors already does this to some extent
      }
   }
   _str cmdLine = "";
   if ( !onlyErrorMarkers ) {
      if ( !def_disable_postbuild_error_markers ) {
         cmdLine = "-m";
      }
      if ( !def_disable_postbuild_error_scroll_markers ) {
         cmdLine :+= " -s";
      }
   }
   set_error_markers(cmdLine);
   refresh('A');
}

#define VSBUILD_SIGNAL_TIMER_INTERVAL  200
#define VSBUILD_SIGNAL_LOCALHOST       "127.0.0.1"
#define VSBUILD_SIGNAL_CLOSE_TIMEOUT   VSBUILD_SIGNAL_TIMER_INTERVAL * 5

#define VSBUILD_SIGNAL_STATE_NONE      0
#define VSBUILD_SIGNAL_STATE_LISTENING 1
#define VSBUILD_SIGNAL_STATE_RECV      2
#define VSBUILD_SIGNAL_STATE_CLOSING   3

static int _vsbuild_timer_handle;
static int _vsbuild_socket_listen_handle;
static int _vsbuild_socket_handle;
static int _vsbuild_signal_state;
static int _vsbuild_signal_wait;
static int _vsbuild_signal_port;

static int _vsbuild_init_vss()
{
   int is_initialized = vssIsInit();
   if (is_initialized) {
      return (0);
   }
   int status = vssInit();
   return (status);
}

static void _vsbuild_socket_listen()
{
   int pending = 0;
   int status = 0;
   if (!vssIsConnectionAlive(_vsbuild_socket_listen_handle)) {
      _vsbuild_signal_exit();
   }
   if (vssIsSocketListening(_vsbuild_socket_listen_handle, pending)) {
      if (!pending) return;
      _vsbuild_socket_handle = vssSocketAcceptConn2(_vsbuild_socket_listen_handle);
      if (_vsbuild_socket_handle > 0) {
         _str host = "";
         int port = 0;
         status = vssGetRemoteSocketInfo(_vsbuild_socket_handle, host, port);
         if (!status && (host == VSBUILD_SIGNAL_LOCALHOST)) {
            _vsbuild_signal_state = VSBUILD_SIGNAL_STATE_RECV;
         }
      }
      if (status || (_vsbuild_socket_handle <= 0)) {
         _vsbuild_signal_exit();
      }
   }
}

static void _vsbuild_socket_recv()
{
   _str buf = '';
   int status = 0;
   status = vssSocketRecvToZStr(_vsbuild_socket_handle, buf, 1, 0);
   if (status == SOCK_TIMED_OUT_RC) {
      return;
   }
   if ((status && (status != SOCK_TIMED_OUT_RC)) || (!status && (buf :== ''))) {
      _vsbuild_signal_exit();
      return;
   }
   _str extra, args = "";
   parse buf with "@STX" args "@ETX" extra;
   call_list("_postbuild_", args);
   
   status = vssSocketSendZ(_vsbuild_socket_handle, "@ACK");
   if (status) {
      _vsbuild_signal_exit();
   }
   _vsbuild_signal_state = VSBUILD_SIGNAL_STATE_CLOSING;
   _vsbuild_signal_wait = VSBUILD_SIGNAL_CLOSE_TIMEOUT;
}

static void _vsbuild_signal_exit()
{
   if (_vsbuild_socket_handle > 0) {
      vssSocketClose(_vsbuild_socket_handle);
   }
   if (_vsbuild_timer_handle > 0) {
      _kill_timer(_vsbuild_timer_handle);
   }
   _vsbuild_timer_handle = -1;
   _vsbuild_socket_handle = 0;
   _vsbuild_signal_state = 0;
}

_str _vsbuild_signal_get_port()
{
   return (_vsbuild_signal_port);
}

void _vsbuild_signal_timer_cb()
{
   switch (_vsbuild_signal_state) {
   case VSBUILD_SIGNAL_STATE_LISTENING:
      _vsbuild_socket_listen();
      break;

   case VSBUILD_SIGNAL_STATE_RECV:
      _vsbuild_socket_recv();
      break;

   case VSBUILD_SIGNAL_STATE_CLOSING:
      _vsbuild_signal_wait -= VSBUILD_SIGNAL_TIMER_INTERVAL;
      if (_vsbuild_signal_wait < 0) {
         _vsbuild_signal_exit();
         _vsbuild_signal_state = VSBUILD_SIGNAL_STATE_LISTENING;
      }
      break;
   }
}

// returns port number for signal socket
int _vsbuild_signal_init()
{
   if (_vsbuild_init_vss() != 0) {
      return (-1);
   }

   _vsbuild_signal_exit();
   int status = _vsbuild_init_listen();
   if (status) {
      return (status);
   }

   // Sanity by checking that we have a local endpoint on the listening socket
   status = vssGetLocalSocketInfo(_vsbuild_socket_listen_handle, auto hostname, _vsbuild_signal_port);
   if (status) {
      _vsbuild_signal_exit();
      return (status);
   }
   _vsbuild_timer_handle = _set_timer(VSBUILD_SIGNAL_TIMER_INTERVAL, _vsbuild_signal_timer_cb);
   _vsbuild_signal_state = VSBUILD_SIGNAL_STATE_LISTENING;

   call_list("_prebuild_", arg(1));
   return (0);
}

static int _vsbuild_init_listen()
{
   if (_vsbuild_socket_listen_handle) {
      int pending = 0;
      if (vssIsSocketListening(_vsbuild_socket_listen_handle, pending)) {
         while (pending) {
            int handle = vssSocketAcceptConn2(_vsbuild_socket_listen_handle);
            if (handle) {
               vssSocketClose(handle);
            }
            vssIsSocketListening(_vsbuild_socket_listen_handle, pending);
         }
      }
      return (0);
   }

   int status = vssSocketOpen(_UTF8ToMultiByte(VSBUILD_SIGNAL_LOCALHOST), "0", _vsbuild_socket_listen_handle, 1, 30000);
   if (!status) {
      return (status);
   }
   return (0);
}

// on stop process callback
void _cbstop_process_cancel_vsbuild_signal()
{
   _vsbuild_signal_exit();
}

// on workspace closed callback
void _wkspace_close_cancel_vsbuild_signal()
{
   _vsbuild_signal_exit();
}

// on exit callback
int _exit_close_vsbuild_signal()
{
   _vsbuild_signal_exit();
   if (vssIsInit()) {
      if (_vsbuild_socket_listen_handle != 0) {
         vssSocketClose(_vsbuild_socket_listen_handle);
      }
      vssExit();
   }
   return (0);
}

_command void force_vsbuild_timer_exit() name_info(',')
{
   _vsbuild_signal_exit();
}

definit()
{
   if (arg(1) != 'L') {
      _vsbuild_timer_handle   = -1;
      _vsbuild_socket_handle  = 0;
      _vsbuild_signal_state   = 0;
      _vsbuild_socket_listen_handle = 0;
      _vsbuild_signal_port    = -1;
   }
}

