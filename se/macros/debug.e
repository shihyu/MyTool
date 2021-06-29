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
#include "markers.sh"
#include "tagsdb.sh"
#import "annotations.e"
#import "android.e"
#import "autosave.e"
#import "c.e"
#import "cjava.e"
#import "codehelp.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cua.e"
#import "cutil.e"
#import "debugpkg.e"
#import "debuggui.e"
#import "doscmds.e"
#import "eclipse.e"
#import "fileproject.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "junit.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "monoopts.e"
#import "mouse.e"
#import "notifications.e"
#import "optionsxml.e"
#import "os2cmds.e"
#import "projconv.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbcmds.e"
#import "tbview.e"
#import "toast.e"
#import "toolbar.e"
#import "util.e"
#import "varedit.e"
#import "vc.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#import "se/ui/toolwindow.e"
#endregion


///////////////////////////////////////////////////////////////////////////
// globals
//

/**
 * Used to mark class exclude filter as uninitialized
 */
static const VSDEBUG_RUNTIME_IMPOSSIBLE_STR= "########";

/**
 * Types of step commands, NONE means we are not in a step
 */
static const DEBUG_STEP_TYPE_NONE= 0;
static const DEBUG_STEP_TYPE_INTO= 1;
static const DEBUG_STEP_TYPE_INST= 2;
static const DEBUG_STEP_TYPE_OVER= 3;
static const DEBUG_STEP_TYPE_OUT=  4;
static const DEBUG_STEP_TYPE_PAST= 5;
static const DEBUG_STEP_TYPE_DEEP= 6;

// constants for debugging support options
// by default these are ALL on.
_metadata enum_flags VSDebugOptionFlags{
   VSDEBUG_OPTION_SUPPORT_HOTSWAP   = 0x0001,
   VSDEBUG_OPTION_CONFIRM_DIRECTORY = 0x0002,
   VSDEBUG_OPTION_ALLOW_EDITING     = 0x0004,
   VSDEBUG_OPTION_MOUSE_OVER_INFO   = 0x0008,
   VSDEBUG_OPTION_AUTO_CORRECT_BP   = 0x0010,
};

/**
 * Is the current thread in the debugger suspended?
 */
static bool gSuspended=false;
/**
 * Is this a corefile (meaning we can't step or run)
 */
static bool gCoreFileDebug=false;
/**
 * Is the debugger connection remote?
 */
static bool gRemoteDebug=false;
/**
 * Type of step operation
 */
static int gInStepType=DEBUG_STEP_TYPE_NONE;
/**
 * What was the original stack depth before the step
 */
static int gInStepDepth=0;
/**
 * Timer used for delaying updates after step or continue.
 */
static int gDebuggerTimerId=-1;
/**
 * Has the vsdebug DLL been loaded and initialized?
 */
static bool gDebuggerInitialized=false;
/**
 * Class/Method/file lookup cache (for performance)
 */
static _str gFilePathCache:[];
/**
 * List of exceptions that can be caught
 */
static _str gExceptionList[];
/**
 * Time when last compile or build was performed
 */
static _str gStartCompileTime='';
/**
 * The set of files [buffer id's] opened read-only in this debugger session.
 */
static _str gReadOnlyFiles:[];


/**
 * The number of lines in the auto variable table window
 */
int def_debug_auto_lines=3;
/**
 * The default type of watchpoint to set
 */
int def_debug_watchpoint_type=VSDEBUG_WATCHPOINT_WRITE;
/**
 * Amount of time to wait before timing out on commands (in seconds)
 */
int def_debug_timeout=30;
/**
 * Max amount of time to spend in _UpdateDebugger(), handling events. (in milliseconds)
 * This also controls the frequency that _UpdateDebugger() triggers when the
 * application being debugged is suspended.
 */
int def_debug_max_update_time=1000;
/**
 * Minimum amount of time to spend in _UpdateDebugger<true), waiting for events. (in milliseconds)
 * This also controls the frequency that _UpdateDebugger() triggers when the
 * application being debugged is running.
 */
int def_debug_min_update_time=250;
/**
 * Amount of time to wait before updating debug windows (in milliseconds)
 */
int def_debug_timer_delay=100;
/**
 * Amount of time to display "loading classes" message (in seconds)
 */
int def_debug_message_duration=5;
/**
 * Default port to use to connect to vsdebugio application
 */
_str def_debug_vsdebugio_port="8001";
/**
 * Debugging support options flags
 * Bitset of VSDEBUG_OPTION_*
 */
int def_debug_options=0xffffffff;
/**
 * Debugging logging support
 */
int def_debug_logging=0;

/**
 * (Windows only). Set to true to use gdb remote proxy application
 * to mediate connection between gdb and remote target. This setting only
 * applies to attaching to remote target.
 */
bool def_gdb_use_proxy = true;

/**
 * (Windows only). Port to use when gdb connects to a remote target through
 * the gdb remote proxy application. def_gdb_use_proxy must be set to true
 * for this to have any effect. Set to "" to use the default port number of
 * 8002.
 */
_str def_gdb_proxy_port = "";

/**
 * (GDB only) Specifies to enable the integrated pretty printing 
 * using Python scripts supplied with SlickEdit. 
 * <p> 
 * Note:  this will not disable any auto-loaded pretty printing 
 * modules that a user's GDB may have configured. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
bool def_gdb_enable_pretty_printing=true;

/**
 * (GDB only) Specifies to disable auto-loading of pretty printing 
 * modules and other scripting that a user's GDB may have pre-configured. 
 * This is generally necessary when using the integrated pretty printing. 
 *  
 * @default false
 * @categories Configuration_Variables
 */
bool def_gdb_disable_auto_load=true;

/**
 * Debugger number formats.
 * Hash table of integer types mapped to the 
 * numerical base to format them using.
 */
DebugNumberFormat def_debug_number_formats:[];

/**
 * Debugger array or string value maximum length to expand.
 */
int def_debug_max_elements = 1000;

/**
 * Relocatable code markers for breakpoints, indexed by the name of the file 
 * they appear in, then by session id, then by line number.
 */
static RELOC_MARKER bpRELOC_MARKERs:[]:[]:[];

/**
 * Number of milliseconds to attempt to relocate all breakpoints in a file. 
 *  
 * @default 2000 
 * @categories Configuration_Variables 
 */
int def_max_breakpoint_relocate_time=2000;


///////////////////////////////////////////////////////////////////////////
// Ran each time the editor is started
//
definit()
{
   if (arg(1)!='L') {
      gDebuggerInitialized=false;
      gInStepType=DEBUG_STEP_TYPE_NONE;
      gInStepDepth=0;
      gSuspended=false;
      gRemoteDebug=false;
      gCoreFileDebug=false;
      gDebuggerTimerId=-1;
      gStartCompileTime='';
      gFilePathCache._makeempty();
   }
   bpRELOC_MARKERs._makeempty();
   gExceptionList._makeempty();
   gReadOnlyFiles._makeempty();
}


///////////////////////////////////////////////////////////////////////////
// query/set debugging state
//

/**
 * Are we in debugging mode?
 */
bool debug_active()
{
   return(_tbDebugQMode());
}

/**
 * Check if the current session supports the named command
 * 
 * @param capability    name of function to check 
 *                      <ul>
 *                      <li>"initialize"
 *                      <li>"finalize"
 *                      <li>"terminate"
 *                      <li>"detach"
 *                      <li>"restart"
 *                      <li>"do_command"
 *                      <li>"error_message"
 *                      <li>"print_output"
 *                      <li>"print_info"
 *                      <li>"print_error"
 *                      <li>"input_direct"
 *                      <li>"version"
 *                      <li>"test_version"
 *                      <li>"reload"
 *                      <li>"get_paths"
 *                      <li>"resolve_path"
 *                      <li>"suspend"
 *                      <li>"continue"
 *                      <li>"interrupt"
 *                      <li>"step_into"
 *                      <li>"step_over"
 *                      <li>"step_out"
 *                      <li>"step_deep"
 *                      <li>"step_instr"
 *                      <li>"set_instruction_pointer"
 *                      <li>"disable_breakpoint"
 *                      <li>"enable_breakpoint"
 *                      <li>"probe_breakpoint"
 *                      <li>"disable_watchpoint"
 *                      <li>"enable_watchpoint"
 *                      <li>"disable_exception"
 *                      <li>"enable_exception"
 *                      <li>"handle_event"
 *                      <li>"update_threads"
 *                      <li>"update_threadgroups"
 *                      <li>"update_threadnames"
 *                      <li>"update_threadstates"
 *                      <li>"update_stack"
 *                      <li>"update_locals"
 *                      <li>"expand_local"
 *                      <li>"modify_local"
 *                      <li>"update_members"
 *                      <li>"expand_member"
 *                      <li>"modify_member"
 *                      <li>"update_watches"
 *                      <li>"expand_watch"
 *                      <li>"modify_watch"
 *                      <li>"update_autos"
 *                      <li>"expand_autovar"
 *                      <li>"modify_autovar"
 *                      <li>"eval_condition"
 *                      <li>"eval_expression"
 *                      <li>"update_classes"
 *                      <li>"expand_class"
 *                      <li>"expand_methods"
 *                      <li>"expand_fields"
 *                      <li>"expand_nested"
 *                      <li>"expand_parents"
 *                      <li>"modify_field"
 *                      <li>"update_disassembly"
 *                      <li>"update_registers"
 *                      <li>"update_memory"
 *                      <li>"modify_memory"
 *                      </ul>
 */
bool debug_session_is_implemented(_str capability)
{
   if (!_haveDebugging()) return false;
   if (!gDebuggerInitialized) return true;
   session_id := dbg_get_current_session();
   if (session_id <= 0) return true;
   int status = dbg_session_is_name_implemented(session_id, capability);
   return (status > 0);
}

/**
 * Send the given command to the debugger and display the
 * result if there is one.
 *
 * @param command         debugger command
 * @param quiet           If true, does not bring up a message
 *                        box with the reply or errors.  Errors
 *                        will be displayed in the status area
 *                        instead.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_send_command(_str command='', bool quiet = false) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // no command given, then prompt for command
   command=prompt(command,'Command');
   if (command=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // Execute the command
   reply := "";
   errmsg := "";
   int status=debug_pkg_do_command(command"\n",reply,errmsg,false);
   if (status) {
      if (quiet) 
         message('debug_send_command: command failed 'get_message(status));
      else
         debug_message("Command failed",status);
      return(status);
   }

   if (!quiet) {
      // put together the response
      if (errmsg!='') {
         errmsg="\n\n":+errmsg;
      }
      if (reply=="^done") {
         reply="Done.";
      }

      // display the result
      _message_box(reply:+errmsg,command);
   }
   return(0);
}

_command test_gdb_command(_str command="-stack-list-locals 1") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   reply := "";
   errmsg := "";
   int status=debug_pkg_do_command(command"\n",reply,errmsg,true);

   debugvar(reply,command);
}
int _OnUpdate_test_gdb_command(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_send_command(cmdui, target_wid, command);
}

/**
 * Start the debugger in the given debugging mode/system.
 *
 * @param debugger_mode   ("jdwp", "lldb", "gdb", "mono", etc.)
 * @param host_or_prog    remote host name, '' indicates the local host.
 *                        Also can indicate the program to debug under gdb.
 * @param port_or_pid     port number to attach to, or if arg(2) is a program,
 *                        this is the process ID to attach to
 * @param arguments       arguments to pass to program being debugged
 * @param timeout         connection timeout in seconds
 * @param debugger_path   Path to debugger executable
 * @param debugger_args   Additional arguments needed to invoke debugger
 * @param working_dir     Optional working directory to switch to
 * @param start_command   (optional) "go" or "into" or "restart" 
 *
 * @return 0 on success, <0 on error (mode not implemented).
 */
int activate_debug(_str debugger_mode, 
                   _str host_or_prog, _str port_or_pid, 
                   _str arguments, int timeout, 
                   _str debugger_path, _str debugger_args,
                   _str working_dir = null, _str start_command = null)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // DJB 03-18-2008
   // Integrated .NET debugging is no longer available as of SlickEdit 2008
   // Check for "dotnet" and inform the user that the feature is gone.
   if (debugger_mode == "dotnet") {
      _message_box(".NET debugging is no longer available.");
      return DEBUG_FEATURE_REMOVED_RC;
   }

   // check for special case of slick-c with JDWP
   isSlickCJDWPDebugMode := false;
   if (debugger_mode == "slickc_jdwp") {
      debugger_mode = "jdwp";
      isSlickCJDWPDebugMode = true;
   }

   // Once debugging has started, we shouldn't move breakpoints. So relocate them
   // now, right before the debugger is started.
   relocateAllBreakpointsForSession(dbg_get_current_session());

   // active debug toolbar set and enable-disable things as needed
   tbDebugSwitchMode(true, isSlickCJDWPDebugMode);

   // send a message to the output tool window that debugging is being started.
   _SccDisplayOutput("Initializing debugger.", clear_buffer:true, doActivateOutput:false);
   process_events(auto cancel_debug);
   if (cancel_debug) {
      tbDebugSwitchMode(false, isSlickCJDWPDebugMode);
      _SccDisplayOutput("Cancelled.", clear_buffer:false, doActivateOutput:false);
      return COMMAND_CANCELLED_RC;
   }

   // try to get the default debugger path and args
   if (debugger_path==null || debugger_path=='') {
      int get_index = debug_find_function("get_default_configuration", debugger_mode);
      if (get_index > 0) {
         debugger_name := "";
         call_index(debugger_name, debugger_path, debugger_args, get_index);
      }
   }
   if (debugger_args==null) {
      debugger_args='';
   }

   if (pos(' ', host_or_prog) > 0 && file_exists(host_or_prog)) {
      host_or_prog = _maybe_quote_filename(host_or_prog);
   }

   status := debug_pkg_initialize(host_or_prog, port_or_pid, 
                                  arguments, timeout, 
                                  debugger_path, debugger_args, 
                                  working_dir, start_command);
   if (status == DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC) {
      debug_message("Warning", status);
   } else if (status) {
      tbDebugSwitchMode(false);
      return(status);
   }
   init_message := debug_pkg_error_message();
   if (init_message!='') {
      debug_message(init_message,0,false);
   }

   // call the user initialize callback
   debug_gui_update_user_views(VSDEBUG_UPDATE_INITIALIZE);

   // now update everything we need to update right away
   debug_pkg_enable_disable_tabs();
   debug_check_and_set_suspended(true);
   debug_gui_update_suspended();
   _autosave_set_timer_alternate();

   // activate the build tool window
   if (!debug_is_remote() && !debug_is_corefile()) {
      build_wid := tw_find_form("_tbshell_form");
      if (build_wid) {
         _post_call(activateBuildWindow, false);
      }
   }

   return(status);
}

/**
 * Is the debugger in a "suspended" state?
 */
bool debug_is_suspended()
{
   return gSuspended;
}
/**
 * Are we attached doing remote debugging?
 */
bool debug_is_remote()
{
   return gRemoteDebug;
}
/**
 * Are we attached doing remote debugging?
 */
bool debug_is_corefile()
{
   return gCoreFileDebug;
}
/**
 * Is the debugger connection innitialized?
 */
bool debug_is_initialized()
{
   return gDebuggerInitialized;
}
/**
 * Is Edit and Continue (Hot Swap) enabled?
 */
bool debug_is_hotswap_enabled()
{
   return (debug_check_reload('') && 
           !debug_is_remote() && !debug_is_corefile() &&
           (def_debug_options & VSDEBUG_OPTION_SUPPORT_HOTSWAP));
}
/**
 * Mark date and time that last compile or build was invoked.
 * This is used to detect files that have changed in order
 * to detect and hot swap in the new versions.
 */
void debug_set_compile_time()
{
   gStartCompileTime=_time('F');
}

/**
 * Exit debugging mode if there are no more active debugger sessions
 * <p>
 * If not, make the first available debugger session active
 * and update the GUI to reflect that.
 */
int debug_maybe_stop_debugging()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // get all session ids
   int session_ids[];
   int status = debug_pkg_finalize();
   dbg_get_all_sessions(session_ids);

   // find the first remaining active session ID
   first_active_session_id := 0;
   int i,n = session_ids._length();
   for (i=0; i<n; ++i) {
      if (dbg_is_session_active(session_ids[i])) {
         first_active_session_id=session_ids[i];
      }
   }

   // do we have any remaining sessions?
   if (first_active_session_id > 0) {
      // switch sessions
      dbg_set_current_session(first_active_session_id);
      debug_gui_update_session();
      debug_pkg_enable_disable_tabs();
   } else {
      // no more active sessions, exit debugging mode
      _SccDisplayOutput("Debugger stopped.",false,false,false);
      tbDebugSwitchMode(false);
      _autosave_set_timer_alternate();

      // set the files we visited back to read-write mode
      debug_reset_readonly_files(false);
      gReadOnlyFiles._makeempty();
      call_list('_stop_debugging');
   }

   // that's all
   return status;
}

///////////////////////////////////////////////////////////////////////////
// turn on debugging mode
//

/**
 * Start the debugger in the given debugging mode/system.
 *
 * @param pkg             ("jdwp", "lldb", "gdb", "mono", etc.)
 * @param host_or_prog    remote host name, '' indicates the local host.
 *                        Also can be used to indicate the program to be debugged.
 * @param port_pid_number port number to attach to, or if arg(2) is a program
 *                        name, this optional parameter contains the process ID
 *                        to attach to.
 * @param arguments       arguments to pass to program being debugged
 * @param timeout         connection timeout in seconds
 * @param debugger_path   Path to debugger executable
 * @param debugger_args   Additional arguments needed to invoke debugger 
 * @param working_dir     (optional) directory to run program in 
 * @param start_command   (optional) "go" or "into" or "restart" 
 *
 * @return 0 on success, <0 on error (mode not implemented).
 */
int debug_begin(_str pkg, _str host_or_prog, _str port_or_pid, 
                _str arguments="", int timeoutInSeconds=def_debug_timeout, 
                _str debugger_path=null, _str debugger_args=null,
                _str working_dir=null, _str start_command = null)
{
   //say("debug_Begin:, package="pkg" host="host_or_prog" port="port_or_pid" timeout="timeoutInSeconds);
   debug_kill_timer();
   mou_hour_glass(true);
   sticky_message("Starting debugger...");
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gInStepDepth=0;
   gSuspended=false;
   gRemoteDebug=false;
   gCoreFileDebug=false;
   gDebuggerTimerId=-1;
   debug_gui_update_suspended();
   debug_gui_clear_thread_update_flags();
   gStartCompileTime='';
   debug_reset_readonly_files(true);
   debug_auto_correct_breakpoints();

   // activate the debugger
   int status=activate_debug(pkg, host_or_prog, port_or_pid, 
                             arguments, timeoutInSeconds, 
                             debugger_path, debugger_args, 
                             working_dir, start_command);
   if (status == DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC) {
      gInStepType=DEBUG_STEP_TYPE_INTO;
   } else if (status) {
      mou_hour_glass(false);
      debug_message("Error starting debugger",status);
      clear_message();
      debug_stop(true);
      return(status);
   }

   // update the debugger
   _UpdateDebugger(true);
   debug_gui_update_all_buttons();
   mou_hour_glass(false);

   // check that the debugger is up
   if (status==0 && !debug_active()) {
      return DEBUG_DOTNET_PROCESS_NOT_RUNNING_RC;
   }

   if (!gSuspended) {
      message("Starting debugger...");
   } else {
      //message("Execution suspended");
   }
   return(status);
}


///////////////////////////////////////////////////////////////////////////
// main debugger commands (ran from debugging button bar)
//

/**
 * Restart the debugger for this application.
 * If there is an debugger system-specific "restart"
 * callback, we simply do that, otherwise, we revert
 * to the very simple method of stopping the debugger
 * and then restarting debug mode.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_restart() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_restart_debug();
   }
   // if not currently debugging, just start the debugger
   buildFirstDone := false;
   if (debug_active()) {
      // we can't restart a remote session
      if (gRemoteDebug) {
         debug_message("Cannot restart an attached debugger session");
         return(1);
      }
      // first try to do a package-specific restart
      _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
      int status=debug_pkg_restart();
      if (!status) {
         return(0);
      }
      // string-not-found means that we didn't have a
      if (status!=STRING_NOT_FOUND_RC && status!=DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
         debug_message("Error restarting debugger",status);
         return(status);
      }

      // no package specific call
      status=debug_stop(true,true);
      if (status) {
         //debug_message("Error stopping debugger",status);
         //return(status);
      }
      buildFirstDone=true;
   }
   // just call step into at this point
   return debug_step_into(buildFirstDone,true);
}
/**
 * Suspend all threads.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_suspend() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   debug_kill_timer();
   mou_hour_glass(true);
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   int status=debug_pkg_suspend();
   if( status ) {
      mou_hour_glass(false);
      switch( status ) {
      case DEBUG_THREAD_WAITING_FOR_SUSPEND_RC:
         // Just waiting for an asynchronous suspend from the debugger,
         // so do not update any views until we get it and do not blast
         // the user with an error message.
         // DBGp (Python, Perl, PHP, Ruby) debuggers use this.
         return(status);
      default:
         debug_message("Error suspending debugger",status);
         return(status);
      }
   }
   gSuspended=true;
   gInStepType=DEBUG_STEP_TYPE_NONE;
   message(nls("Execution suspended"));
   debug_pkg_update_current_thread();
   thread_id := dbg_get_cur_thread();
   debug_gui_update_all(thread_id,1,false);
   status=debug_show_next_statement(true);
   mou_hour_glass(false);
   return(status);
}
/**
 * Suspend a single thread.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_suspend_thread() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int thread_id=debug_gui_get_selected_thread();
   if (thread_id <= 0) {
      debug_message("No thread selected");
      return(thread_id);
   }
   mou_hour_glass(true);
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   int status=debug_pkg_suspend(thread_id);
   if (status) {
      mou_hour_glass(false);
      debug_message("Error suspending thread",status);
      return(status);
   }
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}
/**
 * Resume all threads.  This command also doubles as the entry
 * point for starting debugging.  If we are not already in debug
 * mode, this command will delegate to "_project_debug2" to start
 * everything, and then immediately issue a 'continue' command.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_go(bool buildFirstDone=false,
                      _str debugArguments="",
                      _str debugWorkingDir="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_resume_execution();
   }
   // if not in debugging, start debugging first
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   int status;
   if (!debug_active()) {
      // start the debugger
      status = _project_debug2(buildFirstDone, "go", debugArguments, debugWorkingDir);
      if (status == DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC) {
         return debug_step_into(true);
      } else if (status) {
         return(status);
      }
      // Did we start _project_debug2, but not use our debugging.
      if (!debug_active()) {
         return(0);
      }
   } else {
      // if not suspended, get out of here
      if (!gSuspended) {
         return(DEBUG_THREAD_NOT_SUSPENDED_RC);
      }
      if (gCoreFileDebug) {
         return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
      }
      message("Continuing...");
   }

   // issue the package-specific continue command
   mou_hour_glass(true);
   debug_kill_timer();
   status=debug_pkg_continue();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error continuing",status);
      return(status);
   }
   // and update everything
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   debug_gui_clear_thread_update_flags();
   gDebuggerTimerId=-1;
   debug_force_update_after_step_or_continue(false);
   mou_hour_glass(false);
   return(0);
}

static void debug_new_default_workspace()
{
   WorkspacePath := _ConfigPath():+'debug';  
   dirExists := (dir_match(_maybe_quote_filename(WorkspacePath), true) != '');
   if (!dirExists) {
      mkdir(WorkspacePath);
   }
   WorkspaceFilename := WorkspacePath:+FILESEP:+'debug':+WORKSPACE_FILE_EXT;  
   _workspace_open_default_workspace(WorkspaceFilename);
}

static bool isScalaProjectOrFile()
{
   return _project_DebugCallbackName == 'scaladbgp';
}

/**
 * Attach the debugger to a process not managed by the editor,
 * such as a Java application being ran remotely, or a running process.
 * <p>
 * The <code>attach_info</code> depends on the target debugger.
 * <ul>
 * <li>GDB -- pid=[process_id],app=[program_path]
 * <li>LLDB -- pid=[process_id],app=[program_path]
 * <li>WinDbg -- windbg:pid=[process_id],image=[program_path]
 * <li>Java -- host=[host_name],port=[port_number]
 * </ul>
 * 
 * @param debug_cb_name    debugger system callback name (gdb, jdwp, or dotnet)
 * @param attach_info      parameters for attaching to the process
 * @param session_name     debugging session to use 
 * 
 * @categories Debugger_Commands
 */
_command int debug_attach(_str debug_cb_name="", _str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // are they already in a debug session?
   //if (_DebugMaybeTerminate()) {
   //   return(1);
   //}
   
   // if there is no callback name specified, 
   // try the project default, otherwise try to use GDB.
   if (debug_cb_name == "") {
      debug_cb_name = _project_DebugCallbackName;
   }
   if (debug_cb_name == "") {
      debug_cb_name = "gdb";
   }

   // no attach form for this package then it must not be supported
   if (attach_info=='') {
      int index=find_index('_debug_'debug_cb_name'_attach_form',oi2type(OI_FORM));
      if (!index) {
         debug_message("Attaching to a running process is not supported.");
         return(-1);
      }
   }

   // Scala is odd man out as it does attach with JDWP, but we use the DBGp protocol
   // to talk to the scala debugger.  It also requires a launch of an external
   // JVM, even in the attach case because we're using a Scala debugger library.
   if (isScalaProjectOrFile()) {
      int index = find_index('scala-attach', COMMAND_TYPE);

      if (!index) {
         debug_message("scala-attach command not found.");
         return -1;
      }
      return call_index('', index);
   }

   // display the appropriate form
   if (attach_info=='') {
      attach_info=show("-xy -modal _debug_"debug_cb_name"_attach_form", session_name);
      if (attach_info=='') {
         return(-1);
      }
   }

   if (_workspace_filename == '') {
      _fileProjectClose();
      debug_new_default_workspace();
   } 

   // load vsdebug.dll if it is not already loaded
   debug_maybe_initialize();

   // construct a session name using the program name
   if (substr(attach_info,1,1)=='p') {
      process_id := program_name := "";
      parse attach_info with 'pid=' process_id ',app=' program_name",session="session_name;
      if (session_name == VSDEBUG_NEW_SESSION) session_name = "";
      if (program_name != '' && session_name == '') {
         session_name = "ATTACH: " :+ program_name;
      }
   } else if (substr(attach_info,1,1)=='h') {
      host_name := port_number := "";
      parse attach_info with 'host=' host_name ',port=' port_number",session="session_name;
      if (session_name == VSDEBUG_NEW_SESSION) session_name = "";
      if (session_name == "") {
         session_name = "ATTACH: " :+ host_name":"port_number;
      }
   } else if (pos('windbg: ', attach_info, 1) == 1) { 
      process_id := program_name := symbols := "";
      parse attach_info with 'windbg: pid=' process_id ',image=' program_name ',symbols=' symbols",session="session_name;
      if (session_name == VSDEBUG_NEW_SESSION) session_name = "";
      if (program_name != '' && session_name == '') {
         session_name = "ATTACH: " :+ program_name;
      }
   }

   // no luck, prompt for a session name
   if (session_name == "") {
      session_name = show("-xy -modal _debug_select_session_form", debug_cb_name, session_name);
      if (session_name == '') {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // try to find a session with this name
   orig_session := dbg_get_current_session();
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // if they changed callback name, restart the session
   cb_name := (debug_cb_name=="slickc_jdwp")? "jdwp":debug_cb_name;
   if (session_id > 0 && dbg_get_callback_name(session_id) != cb_name) {
      session_id = dbg_create_new_session(cb_name, session_name, true);
   }

   // create a new debugging session
   created_new_session := false;
   if (session_id <= 0) {
      session_id = dbg_create_new_session(cb_name, session_name, true);
      if (session_id < 0) {
         debug_message("Error creating debugger session", session_id);
         return session_id;
      }
      debug_initialize_runtime_filters(session_id,true);
      debug_gui_update_current_session();
      created_new_session = true;
   }

   // attach to running PID?
   mou_hour_glass(true);
   status := -1;
   host_name := port_number := "";
   process_id := program_name := symbols := "";
   if (substr(attach_info,1,1)=='p') {
      parse attach_info with 'pid=' process_id ',app=' program_name",session="session_name;
      program_name = relative(strip(program_name));
      status = debug_begin(debug_cb_name,program_name,strip(process_id));
   } else if (substr(attach_info,1,1)=='h') {
      parse attach_info with 'host=' host_name ',port=' port_number",session="session_name;
      status = debug_begin(debug_cb_name,strip(host_name),strip(port_number));
   } else if (pos('windbg: ', attach_info, 1) == 1) {
      parse attach_info with 'windbg: pid=' process_id ',image=' program_name ',symbols=' symbols",session="session_name;
      debugger_args :=  "-attach -symbols " :+ symbols;
      status = debug_begin(debug_cb_name,program_name,process_id,'',def_debug_timeout,"",debugger_args);
   }

   // if we attach successfully, update the critical items
   if (!status) {
      if (created_new_session && dbg_get_num_sessions() > 1 && (debug_cb_name!="slickc_jdwp")) {
         activate_sessions();
      }
      gRemoteDebug = (port_number != "");
      debug_check_and_set_suspended();
      debug_gui_update_current_session();
      debug_gui_update_suspended();
      debug_gui_update_all_buttons();
      if (gSuspended) {
         debug_gui_update_all();
      } else {
         debug_gui_update_threads();
         debug_gui_update_classes();
      }
      debug_pkg_enable_disable_tabs();
      debug_gui_update_all_buttons();
      debug_gui_update_breakpoints(true);
      debug_gui_update_exceptions(true);
   } else if (status < 0) {
      debug_message("Error initializing debugger",status);
   } else {
      debug_message("Unsupported debugger attach protocol");
   }

   // If we failed to create a session, then clean up session
   if (status) {
      dbg_session_finalize(session_id);
      if (created_new_session) {
         dbg_destroy_session(session_id);
         if (orig_session > 0) {
            dbg_set_current_session(orig_session);
         }
      }
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}
/**
 * Attach the debugger to a running process using the WinDBG debugger. 
 * 
 * @param attach_info      parameters for attaching to the process 
 * @param session_name     debugging session to use 
 *  
 * @see debug_attach 
 * @categories Debugger_Commands
 */
_command int debug_attach_windbg(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_attach("windbg",attach_info,session_name);
}
/**
 * Attach the debugger to a running JVM using the Java debugger.
 * 
 * @param attach_info      parameters for attaching to the process 
 * @param session_name     debugging session to use 
 *  
 * @see debug_attach 
 * @categories Debugger_Commands
 */
_command int debug_attach_jdwp(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_attach("jdwp",attach_info,session_name);
}
/**
 * Attach the debugger to a running process using the GDB debugger. 
 * 
 * @param attach_info      parameters for attaching to the process 
 * @param session_name     debugging session to use 
 *  
 * @see debug_attach 
 * @categories Debugger_Commands
 */
_command int debug_attach_gdb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_attach("gdb",attach_info,session_name);
}
/**
 * Attach the debugger to a running process using the LLDB debugger. 
 * 
 * @param attach_info      parameters for attaching to the process 
 * @param session_name     debugging session to use 
 *  
 * @see debug_attach 
 * @categories Debugger_Commands
 */
_command int debug_attach_lldb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_attach("lldb",attach_info,session_name);
}
/**
 * Attach the debugger to a running process using the Mono debugger. 
 * 
 * @param attach_info      parameters for attaching to the process 
 * @param session_name     debugging session to use 
 *  
 * @see debug_attach 
 * @categories Debugger_Commands
 */
_command int debug_attach_mono(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_attach("mono",attach_info,session_name);
}

/**
 * Attach the debugger to a core file left after a process crashed.
 * 
 * @param debug_cb_name    debugger system callback name (gdb, windbg, lldb)
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 * 
 * @categories Debugger_Commands
 */
_command int debug_corefile(_str debug_cb_name="", _str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // are they already in a debug session?
   //if (_DebugMaybeTerminate()) {
   //   return(1);
   //}

   // if there is no callback name specified, 
   // try the project default, otherwise try to use GDB.
   if (debug_cb_name == "") {
      debug_cb_name = _project_DebugCallbackName;
   }
   if (debug_cb_name == "") {
      debug_cb_name = "gdb";
   }

   // no attach form for this package then it must not be supported
   int index=find_index("_debug_"debug_cb_name"_corefile_form",oi2type(OI_FORM));
   if (!index) {
      debug_message("Analyzing a core file is not supported.");
      return(-1);
   }

   // display the appropriate form
   if (attach_info == "") {
      attach_info=show("-xy -modal _debug_"debug_cb_name"_corefile_form", session_name);
      if (attach_info=='') {
         return(-1);
      }
   }

   if (_workspace_filename == '') {
      _fileProjectClose();
      debug_new_default_workspace();
   } 

   // attach to running PID?
   corefile := program_name := "";
   debugger_path := "";
   debugger_args := "";
   windbg_dumpfile := (pos('windbg: ', attach_info, 1) == 1);
   if (windbg_dumpfile) {
      _str symbols;
      parse attach_info with 'windbg: dumpfile=' corefile ',image=' program_name ',symbols=' symbols",session="session_name;
      debugger_args = "-dumpfile -symbols " :+ symbols;
   } else {
      parse attach_info with 'core=' corefile ',app=' program_name ',path=' debugger_path ',args=' debugger_args",session="session_name;
   }


   // see if we can use the workspace session?
   debug_maybe_initialize();

   // generate a name for the new configuration they are using
   if (session_name == VSDEBUG_NEW_SESSION) {
      session_name = "";
   }
   if (_isUnix()) {
      if (session_name == "") {
         session_name = "COREFILE: " :+ program_name;
         if (program_name == '') {
            session_name = "COREFILE: " :+ corefile;
         }
      }
   }

   if (_isWindows()) {
      if (session_name == "") {
         session_name = "DUMPFILE: " :+ corefile;
      }
   }

   // now prompt for a session name
   if (session_name == "") {
      session_name = show("-xy -modal _debug_select_session_form", debug_cb_name, session_name);
      if (session_name == '') {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // try to find a session with this name
   orig_session := dbg_get_current_session();
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // if they changed callback name, restart the session
   if (session_id > 0 && dbg_get_callback_name(session_id) != debug_cb_name) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
   }

   // create a new debugging session
   created_new_session := false;
   if (session_id <= 0) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
      if (session_id < 0) {
         debug_message("Error creating debugger session", session_id);
         return session_id;
      }
      debug_initialize_runtime_filters(session_id,true);
      debug_gui_update_current_session();
      created_new_session = true;
   }

   // now start the debugging session
   mou_hour_glass(true);
   if (windbg_dumpfile) {
      //
      
   } else {
      program_name = relative(strip(program_name));
      corefile = relative(strip(corefile));
   }
   int status = debug_begin(debug_cb_name,program_name,corefile,'',def_debug_timeout,debugger_path,debugger_args);

   // if we attach successfully, update the critical items
   if (!status) {      
      if (created_new_session && dbg_get_num_sessions() > 1) {
         activate_sessions();
      }
      gRemoteDebug=true;
      gCoreFileDebug=true;
      debug_suspend();
      debug_gui_update_current_session();
      debug_gui_update_all_buttons();
      debug_gui_update_all();
      debug_pkg_enable_disable_tabs();
      debug_gui_update_all_buttons();
      debug_gui_update_breakpoints(true);
      debug_gui_update_exceptions(true);
   } else if (status < 0) {
      debug_message("Error initializing debugger",status);
   } else {
      debug_message("Unsupported core file type");
   }

   // If we failed to create a session, then clean up session
   if (status) {
      dbg_session_finalize(session_id);
      if (created_new_session) {
         dbg_destroy_session(session_id);
         if (orig_session > 0) {
            dbg_set_current_session(orig_session);
         }
      }
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}
/**
 * Attach the LLDB debugger to a core file left after a process crashed.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_corefile 
 * @categories Debugger_Commands
 */
_command int debug_corefile_lldb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_corefile("lldb",attach_info,session_name);
}
/**
 * Attach the GDB debugger to a core file left after a process crashed.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 * 
 * @see debug_corefile 
 * @categories Debugger_Commands
 */
_command int debug_corefile_gdb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_corefile("gdb",attach_info,session_name);
}
/**
 * Attach the WinDbg debugger to a dump file left after a process crashed.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 * 
 * @see debug_corefile 
 * @categories Debugger_Commands
 */
_command int debug_dumpfile_windbg(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_corefile("lldb",attach_info,session_name);
}

/**
 * Create a debugging session to debug an executable not
 * associated with the current project.
 * 
 * @param debug_cb_name    debugger system callback name (gdb, windbg, lldb)
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 * 
 * @categories Debugger_Commands
 */
_command int debug_executable(_str debug_cb_name="", _str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // are they already in a debug session?
   //if (_DebugMaybeTerminate()) {
   //   return(1);
   //}

   // if there is no callback name specified, 
   // try the project default, otherwise try to use GDB.
   if (debug_cb_name == "") {
      debug_cb_name = _project_DebugCallbackName;
   }
   if (debug_cb_name == "") {
      debug_cb_name = "gdb";
   }

   // no attach form for this package then it must not be supported
   int index=find_index("_debug_"debug_cb_name"_executable_form",oi2type(OI_FORM));
   if (!index) {
      debug_message("Debugging an executable is not supported.");
      return(-1);
   }

   // display the appropriate form
   if (attach_info == "") {
      attach_info=show("-xy -modal _debug_"debug_cb_name"_executable_form", session_name);
      if (attach_info=='') {
         return(-1);
      }
   }

   if (_workspace_filename == '') {
      _fileProjectClose();
      debug_new_default_workspace();
   } 

   // attach to other executable
   command := "";
   program_name := "";
   directory_name := "";
   arguments := "";
   debugger_port := "";
   debugger_path := "";
   debugger_args := "";
   class_path := "";
   use_relative_name := true;

   if (pos('windbg: ', attach_info, 1) == 1) {
      parse attach_info with 'windbg: app=' program_name ',args='arguments ',dir='directory_name ',symbols=' auto symbols_name",session="session_name;
      if (directory_name == '') {
         directory_name = getcwd();
         _maybe_append_filesep(directory_name);
      }
      debugger_args = "-create -init-dir " :+ _maybe_quote_filename(directory_name) :+ " -symbols "symbols_name;
      use_relative_name = false;
   } else if (debug_cb_name == "jdwp") {
      parse attach_info with 'command=' command ',app=' program_name ',dir=' directory_name ',args='arguments",session="session_name",cp="class_path;
      use_relative_name = false;
   } else if (debug_cb_name == "mono") {
      parse attach_info with 'command=' command ',app=' program_name ',dir=' directory_name ',args='arguments",session="session_name;
      use_relative_name = false;
   } else if (debug_cb_name == "lldb") {
      parse attach_info with 'command=' command ',app=' program_name ',dir=' directory_name ',args='arguments",session="session_name;
      use_relative_name = false;
   } else {
      parse attach_info with 'command=' command ',app=' program_name ',dir=' directory_name ',args='arguments",session="session_name;
   }

   // patch in the program name if they select that for the configuration
   if (session_name == VSDEBUG_NEW_SESSION) {
      session_name = "PROGRAM: ":+program_name;
   }

   // switch to the specified working directory
   if (directory_name != '') {
      // Adjust program path to be relative to working directory
      directory_name = strip(directory_name);
      if (file_exists(program_name)) {
         program_name = absolute(program_name);
      }
      if (use_relative_name) {
         program_name = relative(program_name, directory_name);
      }
      int status = chdir(directory_name, 1);
      if (status < 0) {
         debug_message("Error switching to working directory", status);
         return status;
      }
   }

   // see if we can use the workspace session?
   debug_maybe_initialize();

   // now prompt for a session name
   if (session_name == "") {
      session_name = "PROGRAM: " :+ program_name;
      session_name = show("-xy -modal _debug_select_session_form", debug_cb_name, session_name);
      if (session_name == '') {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // try to find a session with this name
   orig_session := dbg_get_current_session();
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // if they changed callback name, restart the session
   if (session_id > 0 && dbg_get_callback_name(session_id) != debug_cb_name) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
   }

   // create a new debugging session
   created_new_session := false;
   if (session_id <= 0) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
      if (session_id < 0) {
         debug_message("Error creating debugger session", session_id);
         return session_id;
      }
      debug_initialize_runtime_filters(session_id,true);
      debug_gui_update_current_session();
      created_new_session = true;
   }

   // for GDB, we need to start vsdebugio on UNIX
   if (_isUnix() && (debug_cb_name == "gdb" || debug_cb_name == "lldb")) {
      vsdebugio_command := get_env("VSLICKBIN1");
      _maybe_append_filesep(vsdebugio_command);
      vsdebugio_command :+= "vsdebugio";
      if (file_exists(vsdebugio_command)) {
         _str vsdebugio_port = def_debug_vsdebugio_port;
         if (vsdebugio_port == '') vsdebugio_port = 8000 + session_id;
         vsdebugio_command = _maybe_quote_filename(vsdebugio_command);
         vsdebugio_command :+= " -port " vsdebugio_port " -prog " _maybe_quote_filename(program_name) " " arguments;
         vsdebugio_status := 0;
         if ( !debug_active() ) {
            vsdebugio_status = concur_command(vsdebugio_command);
         } else {
            vsdebugio_status = dos("-t "vsdebugio_command);
         }
         if (vsdebugio_status < 0) {
            debug_message("Error starting vsdebugio", vsdebugio_status);
            return vsdebugio_status;
         }
      }
   }

   // we need to start java interpreter
   if (debug_cb_name == "jdwp") {
      debugger_port = 8000 + session_id;
      java_command := get_java_from_settings_or_java_home();
      java_command :+= " -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=" :+ debugger_port;
      program_path := _strip_filename(program_name, 'N');
      program_name  = _strip_filename(program_name, 'P');
      if (_get_extension(program_name) == "class") {
         program_name = _strip_filename(program_name, 'E');
      }
      if (program_path != "") {
         class_path = program_path :+ ";" :+ class_path;
      }
      if (class_path != "") {
         _str a[];
         split(class_path, ';', a);
         java_command :+= " -classpath \"" :+ join(a, ':') :+ "\"";
      }
      java_command :+= " " :+ _maybe_quote_filename(program_name);
      if (arguments != "") {
         java_command :+= " " :+ arguments;
      }
      java_status := 0;
      if ( !debug_active() ) {
         java_status = concur_command(java_command);
      } else {
         java_status = dos("-t "java_command);
      }
      if (java_status < 0) {
         debug_message("Error starting java", java_status);
         return java_status;
      }
      program_name = "localhost";
   }

   // we need to start mono interpreter
   if (debug_cb_name == "mono") {
      debugger_port = 8000 + session_id;
      mono_command := get_mono_from_settings_or_mono_home();
      mono_command :+= " --debugger-agent=\"transport=dt_socket,server=y,suspend=y,address=localhost:" :+ debugger_port :+ "\"";
      mono_command :+= " " :+ _maybe_quote_filename(program_name);
      if (arguments != "") {
         mono_command :+= " " :+ arguments;
      }
      mono_status := 0;
      if ( !debug_active() ) {
         mono_status = concur_command(mono_command);
      } else {
         mono_status = dos("-t "mono_command);
      }
      if (mono_status < 0) {
         debug_message("Error starting Mono", mono_status);
         return mono_status;
      }
      program_name = "localhost";
   }

   // now start the debugging session
   mou_hour_glass(true);
   if (use_relative_name) {
      program_name = relative(strip(program_name));
   }
   int status = debug_begin(debug_cb_name,
                            program_name,debugger_port,arguments,def_debug_timeout,
                            debugger_path,debugger_args,directory_name,command);

   // missing breakpoints, then do a step into
   if (status == DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC) {
      status=0;
      command = "into";
   }

   // if we attach successfully, update the critical items
   if (!status) {      
      if (created_new_session && dbg_get_num_sessions() > 1) {
         activate_sessions();
      }
      if (command == 'run') {
         status = debug_go(true);
      } else {
         status = debug_step_into(true,false);
      }
      if (status < 0) {
         debug_message("Error starting debugger",status);
      }
   } else if (status < 0) {
      debug_message("Error initializing debugger",status);
   } else {
      debug_message("Unsupported executable type");
   }

   // If we failed to create a session, then clean up session
   if (status) {
      dbg_session_finalize(session_id);
      if (created_new_session) {
         dbg_destroy_session(session_id);
         if (orig_session > 0) {
            dbg_set_current_session(orig_session);
         }
      }
      tbDebugSwitchMode(false);
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}
/**
 * Create a debugging session to debug an executable not
 * associated with the current project using the GDB debugger.
 * 
 * @param debug_cb_name    debugger system callback name (gdb, windbg, lldb)
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_executable
 * @categories Debugger_Commands
 */
_command int debug_executable_gdb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_executable("gdb",attach_info,session_name);
}
/**
 * Create a debugging session to debug an executable not
 * associated with the current project using the WinDBG debugger.
 * 
 * @param debug_cb_name    debugger system callback name (gdb, windbg, lldb)
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_executable
 * @categories Debugger_Commands
 */
_command int debug_executable_windbg(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_executable("windbg",attach_info,session_name);
}
/**
 * Create a debugging session to debug an executable not
 * associated with the current project using the LLDB debugger.
 * 
 * @param debug_cb_name    debugger system callback name (gdb, windbg, lldb)
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_executable
 * @categories Debugger_Commands
 */
_command int debug_executable_lldb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_executable("lldb",attach_info,session_name);
}
/**
 * Create a debugging session to debug an Java program not
 * associated with the current project using the Java/JVM debugger.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_executable
 * @categories Debugger_Commands
 */
_command int debug_executable_java(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_executable("jdwp",attach_info,session_name);
}
/**
 * Create a debugging session to debug an Mono program not
 * associated with the current project using the Mono debugger.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_executable
 * @categories Debugger_Commands
 */
_command int debug_executable_mono(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_executable("mono",attach_info,session_name);
}

/**
 * Create a debugging session to debug an executable not
 * associated with the current project.
 * 
 * @categories Debugger_Commands
 */
_command int debug_run_with_arguments(_str debug_cb_name="", _str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // are they already in a debug session?
   if (_DebugMaybeTerminate()) {
      return(1);
   }

   // if there is no callback name specified, 
   // try the project default, otherwise try to use GDB.
   if (debug_cb_name == "") {
      debug_cb_name = _project_DebugCallbackName;
   }
   if (debug_cb_name == "") {
      debug_cb_name = "gdb";
   }

   // no attach form for this package then it must not be supported
   index := find_index("_debug_arguments_form",oi2type(OI_FORM));
   if (!index) {
      debug_message("Debugging with custom arguments is not supported.");
      return(-1);
   }

   // try to ascertain the default directory to run from
   directory_name := getcwd();
   if (_workspace_filename != "" && _project_name != "") {
      absCurProject := absolute(_project_name, _strip_filename(_workspace_filename, 'N'));
      targetNode := _ProjectGet_TargetNode(_ProjectHandle(),"debug");
      directory_name = _ProjectGet_TargetRunFromDir(_ProjectHandle(), targetNode);
      if (directory_name == "") {
         directory_name = _ProjectGet_WorkingDir(_ProjectHandle());
      }
      buf_name := (_isEditorCtl()? p_buf_name : "");
      directory_name = _parse_project_command(directory_name, buf_name, _project_name, "");
      directory_name = absolute(directory_name, _strip_filename(absCurProject,'N'));
   }

   // display the appropriate form
   if (attach_info == "") {
      attach_info=show("-xy -modal _debug_arguments_form", directory_name);
      if (attach_info=='') {
         return(-1);
      }
   }

   // attach to other executable
   command := "";
   arguments := "";
   parse attach_info with 'command=' command ',dir=' directory_name ',args='arguments;

   // switch to the specified working directory
   if (directory_name != "") {
      // Adjust program path to be relative to working directory
      directory_name = strip(directory_name);
      status := chdir(directory_name);
      if (status < 0) {
         debug_message("Error switching to working directory", status);
         return status;
      }
   }

   // see if we can use the workspace session?
   debug_maybe_initialize();

   // try to find a session with this name
   if (session_name == "") {
      session_name = debug_get_workspace_session_name();
   }
   orig_session := dbg_get_current_session();
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // if they changed callback name, restart the session
   if (session_id > 0 && dbg_get_callback_name(session_id) != debug_cb_name) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
   }

   // create a new debugging session
   if (session_id <= 0) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
      if (session_id < 0) {
         debug_message("Error creating debugger session", session_id);
         return session_id;
      }
      debug_initialize_runtime_filters(session_id,true);
      debug_gui_update_current_session();
   }

   // now start the debugging session
   mou_hour_glass(true);

   // start the debugger
   status := _project_debug2(false, command, arguments, directory_name);
   if (status == DEBUG_BREAKPOINTS_NOT_ENABLED_ON_STARTUP_RC) {
      mou_hour_glass(false);
      return debug_step_into(true);
   } else if (status) {
      mou_hour_glass(false);
      return(status);
   }
   // Did we start _project_debug2, but not use our debugging.
   if (!debug_active()) {
      mou_hour_glass(false);
      return(0);
   }

   // issue the package-specific continue command
   debug_kill_timer();
   if (command == "run") {
      status=debug_pkg_continue();
   } else {
      status=debug_step_into();
   }
   if (status) {
      mou_hour_glass(false);
      debug_message("Error continuing",status);
      return(status);
   }
   // and update everything
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   debug_gui_clear_thread_update_flags();
   gDebuggerTimerId=-1;
   debug_force_update_after_step_or_continue(true);
   mou_hour_glass(false);
   return(status);
}
/**
 * Attach the GDB debugger to a remote target
 * 
 * @categories Debugger_Commands
 */
_command int debug_remote(_str debug_cb_name="", _str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // are they already in a debug session?
   //if (_DebugMaybeTerminate()) {
   //   return(1);
   //}
   
   // if there is no callback name specified, 
   // try the project default, otherwise try to use GDB.
   if (debug_cb_name == "") {
      debug_cb_name = _project_DebugCallbackName;
   }
   if (debug_cb_name == "") {
      debug_cb_name = "gdb";
   }

   // no attach form for this package then it must not be supported, unless it's android
   int index=find_index("_debug_"debug_cb_name"_remote_form",oi2type(OI_FORM));
   if (!index && debug_cb_name != 'android') {
      debug_message("Remote debugging is not supported.");
      return(-1);
   }

   if (debug_cb_name == 'android') {
      attach_info = _android_get_attach_info(debug_cb_name);
      if (attach_info == '') {
         return 0;
      }
   }

   // display the appropriate form
   if (attach_info == '') {
      attach_info=show("-xy -modal _debug_"debug_cb_name"_remote_form", session_name);
      if (attach_info=='') {
         return(-1);
      }
   }

   if (_workspace_filename == '') {
      _fileProjectClose();
      debug_new_default_workspace();
   } 

   // attach to running PID?
   info := "";
   program_name := "";
   program_args := "";
   working_dir  := "";
   debugger_path := "";
   debugger_args := "";
   if (debug_cb_name == "lldb") {
      parse attach_info with 'file=' program_name ',' info ',dir=' working_dir ',args=' program_args ",session=" session_name;
   } else {
      parse attach_info with 'file=' program_name ',' info ',path=' debugger_path ',args=' debugger_args ",session=" session_name;
   }
   //say('file='program_name', info='info', path='debugger_path', args='debugger_args',session='session_name);

   // construct a session name using the program name
   if (session_name == VSDEBUG_NEW_SESSION) session_name = "";
   if (program_name != '' && session_name == '') {
      session_name = "REMOTE: " :+ program_name;
   }

   // no luck, prompt for a session name
   if (session_name == "") {
      session_name = show("-xy -modal _debug_select_session_form", debug_cb_name, session_name);
      if (session_name == '') {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // try to find a session with this name
   orig_session := dbg_get_current_session();
   session_id := dbg_find_session(session_name);
   if (session_id > 0) {
      dbg_set_current_session(session_id);
   }

   // if they changed callback name, restart the session
   if (session_id > 0 && dbg_get_callback_name(session_id) != debug_cb_name) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
   }

   // create a new debugging session
   created_new_session := false;
   if (session_id <= 0) {
      session_id = dbg_create_new_session(debug_cb_name, session_name, true);
      if (session_id < 0) {
         debug_message("Error creating debugger session", session_id);
         return session_id;
      }
      debug_initialize_runtime_filters(session_id,true);
      debug_gui_update_current_session();
      created_new_session = true;
   }

   // now start debugging
   mou_hour_glass(true);
   int status = debug_begin(debug_cb_name,
                            strip(program_name),
                            ':':+strip(info),
                            program_args,
                            def_debug_timeout,
                            debugger_path, debugger_args,
                            working_dir);

   // if we attach successfully, update the critical items
   if (!status) {
      if (created_new_session && dbg_get_num_sessions() > 1) {
         activate_sessions();
      }
      gRemoteDebug=true;
      debug_check_and_set_suspended();
      debug_gui_update_current_session();
      debug_gui_update_suspended();
      debug_gui_update_all_buttons();
      if (gSuspended) {
         debug_gui_update_all();
      } else {
         debug_gui_update_threads();
         debug_gui_update_classes();
      }
      debug_pkg_enable_disable_tabs();
      debug_gui_update_all_buttons();
      debug_gui_update_breakpoints(true);
      debug_gui_update_exceptions(true);
   } else if (status < 0) {
      // This is already reported by debug_begin.
      //debug_message("Error initializing debugger",status);
   } else {
      debug_message("Unsupported debugger attach protocol");
   }

   // If we failed to create a session, then clean up session
   if (status) {
      dbg_session_finalize(session_id);
      if (created_new_session) {
         dbg_destroy_session(session_id);
         if (orig_session > 0) {
            dbg_set_current_session(orig_session);
         }
      }
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}

/**
 * Attach the LLDB debugger to a remote process.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_remote 
 * @categories Debugger_Commands
 */
_command int debug_remote_lldb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_remote("lldb",attach_info,session_name);
}
/**
 * Attach the GDB debugger to a remote process.
 * 
 * @param attach_info      parameters for launching the process
 * @param session_name     debugging session to use 
 *  
 * @see debug_remote 
 * @categories Debugger_Commands
 */
_command int debug_remote_gdb(_str attach_info="", _str session_name="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   return debug_remote("gdb",attach_info,session_name);
}

/**
 * Detach from the current debugging session (if supported),
 * leaving the client application running, and exiting debug mode.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_detach() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // already terminated?
   if (!debug_active()) {
      debug_message("Debugger is not active");
      return(0);
   }
   debug_kill_timer();
   mou_hour_glass(true);
   debug_gui_clear_disassembly();
   int status=debug_pkg_detach();
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   gRemoteDebug=false;
   debug_gui_clear_thread_update_flags();
   gDebuggerTimerId=-1;
   gFilePathCache._makeempty();
   debug_gui_update_suspended();
   debug_gui_update_all_buttons();
   dbg_clear_editor();
   debug_remove_temporary_breakpoints();
   dbg_update_editor_breakpoints();
   debug_maybe_stop_debugging();
   if (status) {
      debug_message("Error detaching debugger",status);
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}

/**
 * Detach from the current remote debugging session (if
 * supported), leaving the client application suspended, and
 * exiting debug mode.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_disconnect() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // already terminated?
   if (!debug_active()) {
      debug_message("Debugger is not active");
      return(0);
   }
   debug_kill_timer();
   mou_hour_glass(true);
   debug_gui_clear_disassembly();
   int status=debug_pkg_disconnect();
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   gRemoteDebug=false;
   debug_gui_clear_thread_update_flags();
   gDebuggerTimerId=-1;
   gFilePathCache._makeempty();
   debug_gui_update_suspended();
   debug_gui_update_all_buttons();
   dbg_clear_editor();
   debug_remove_temporary_breakpoints();
   dbg_update_editor_breakpoints();
   debug_maybe_stop_debugging();
   if (status) {
      debug_message("Error disconnecting debugger",status);
   }

   // that's all folks
   mou_hour_glass(false);
   return(status);
}

/**
 * Reload the file passed in.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_reload(_str file_name=null) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   // already terminated?
   if (!debug_active()) {
      debug_message("Debugger is not active");
      return(0);
   }
   // remote debugging session?
   if (gRemoteDebug) {
      debug_message("Reload and continue is not supported for remote debugging.");
      return(0);
   }
   // edit and continue supported?
   if (!debug_check_reload()) {
      return STRING_NOT_FOUND_RC;
   }
   // start compile time not set up first?
   if (gStartCompileTime=='') {
      debug_message("Not prepared to reload.  Call debug_set_compile_time() first.");
      return COMMAND_CANCELLED_RC;
   }
   debug_kill_timer();
   mou_hour_glass(true);

   if (file_name==null && !_no_child_windows() && _isEditorCtl()) {
      file_name=_mdi.p_child.p_buf_name;
   }

   session_id := dbg_get_current_session();
   status := 0;
   options := 0;
   if (dbg_get_callback_name(session_id) == 'jdwp') {

      // get the class path
      file_list := "";
      _str cwd,user,sys;
      debug_pkg_get_paths(cwd,user,sys);

      // for each item in the user class path, look for new items
      while (user != '') {
         class_path := "";
         parse user with class_path "\n" user;
         _maybe_append_filesep(class_path);

         ff := 1;
         for (;;ff=0) {
            // find class files along this path
            file_name = file_match(_maybe_quote_filename(class_path:+"*.class")" +T -P",ff);
            if (file_name=="") {
               break;
            }
            // check file dates against build time
            //say("debug_reload: file="file_name);
            if (_file_date(file_name,'B') < gStartCompileTime) {
               continue;
            }
            // add to the file list
            if (file_list=='') {
               file_list=file_name;
            } else {
               file_list :+= "\n"file_name;
            }
            message(nls("Reloading class:  %s",file_name));
            _SccDisplayOutput(nls("Reloading class:  %s",file_name),false,false,false);
         }
      }

      // reload this set of class files
      status=debug_pkg_reload(file_list,options);
      if (status) {
         debug_message("Error reloading classes: ",status);
      }
      // update the GUI
      debug_gui_update_all();
      debug_show_next_statement(true);
   }

   mou_hour_glass(false);
   return(status);
}
/**
 * Resume a single thread.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_continue_thread() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int thread_id=debug_gui_get_selected_thread();
   if (thread_id <= 0) {
      debug_message("No thread selected");
      return(thread_id);
   }
   mou_hour_glass(true);
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   int status=debug_pkg_continue(thread_id);
   if (status) {
      mou_hour_glass(false);
      debug_message("Error resuming thread",status);
      return(status);
   }
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}
/**
 * Send an interrupt to a single thread.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_interrupt() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   int thread_id=debug_gui_get_selected_thread();
   if (thread_id <= 0) {
      debug_message("No thread selected");
      return(thread_id);
   }
   mou_hour_glass(true);
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   int status=debug_pkg_interrupt(thread_id);
   if (status) {
      mou_hour_glass(false);
      debug_message("Error interrupting thread",status);
      return(status);
   }
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}
/**
 * Display the monitor information for the selected thread.
 * <P>
 * NOT IMPLEMENTED
 *
 * @return 0 on success, <0 on error.
 */
_command int debug_monitors() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   debug_message("Viewing thread monitors is not implemented yet.");
   return(0);

   int thread_id=debug_gui_get_selected_thread();
   if (thread_id <= 0) {
      debug_message("No thread selected");
      return(thread_id);
   }
   // show the monitors and current contended monitor for this thread
   //show("-xy _debug_monitors_form",thread_id);
   return(0);
}
/**
 * Is the given file flagged as read-only within the debugger?
 */
bool debug_is_readonly(int buf_id)
{
   return (debug_active() && gReadOnlyFiles._indexin(buf_id));
}
/**
 * Maybe add this file to the list of readonly files.
 * The current object should be an editor control.
 */
void debug_maybe_add_readonly_file(_str file_name)
{
   // already in readonly mode?
   if (p_readonly_mode || p_readonly_set_by_user) {
      return;
   }

   // debug not active?
   if (!debug_active()) {
      return;
   }

   // add the file if guardrails are turned on
   if (!(def_debug_options & VSDEBUG_OPTION_ALLOW_EDITING)) {
      gReadOnlyFiles:[p_buf_id]=true;
      p_readonly_mode=true;
   }

   // add the file if disassembly is enabled
   if (dbg_have_updated_disassembly(file_name)) {
      gReadOnlyFiles:[p_buf_id]=true;
      p_readonly_mode=true;
   }
}
static bool debug_breakpoint_message(_str event_kind, int breakpoint_id, int exception_id, _str method_name)
{
   if (!_haveDebugging()) return false;
   if (breakpoint_id > 0) {
      condition := "";
      dbg_get_breakpoint_condition(breakpoint_id,condition);
      breakpoint_flags := 0;
      int breakpoint_type = dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags);
      if (breakpoint_type==VSDEBUG_BREAKPOINT_LINE ||
          breakpoint_type==VSDEBUG_BREAKPOINT_ADDRESS ||
          breakpoint_type==VSDEBUG_BREAKPOINT_METHOD ||
          event_kind=='breakpoint') {

         if (condition!='') {
            message(nls("Stopped at breakpoint in \"%s()\" on condition (%s)",method_name,condition));
         } else {
            message(nls("Stopped at breakpoint in \"%s()\"",method_name));
         }
      } else if (breakpoint_type==VSDEBUG_WATCHPOINT_READ || event_kind=='watchpoint-read') {
         message(nls("Stopped at watchpoint in \"%s()\" because (%s) was read",method_name,condition));
      } else if (breakpoint_type==VSDEBUG_WATCHPOINT_WRITE || event_kind=='watchpoint-write') {
         message(nls("Stopped at watchpoint in \"%s()\" because (%s) changed",method_name,condition));
      } else if (breakpoint_type==VSDEBUG_WATCHPOINT_ANY || event_kind=='watchpoint') {
         if (condition!='') {
            message(nls("Stopped at watchpoint in \"%s()\" on expression (%s)",method_name,condition));
         } else {
            // special case for GDB which does not correlate watchpoint
            // event to the triggering watchpoint
            message(nls("Stopped at watchpoint in \"%s()\"",method_name));
         }
      }
      _mdi._set_foreground_window();
      _set_focus();
      return true;
   }
   if (exception_id) {
      _beep();
      if (exception_id > 0) {
         message(nls("Caught exception in \"%s()\"",method_name));
      } else {
         message(nls("Uncaught exception in \"%s()\"",method_name));
      }
      _mdi._set_foreground_window();
      _set_focus();
      return true;
   }
   return false;
}
/**
 * Display the next statement to be executed for the current
 * stack frame.
 *
 * @param quiet            Do not complain about errors (default false)
 * @param breakpoint_id    breakpoint ID from debugger event
 * @param execption_id     exception ID from debugger event
 * @param event_kind       type of debugger event causing this update
 * @param event_text       description of debugger event
 * @param thread_id        thread ID to make active,
 *                         if == 0, use the current thread ID
 * @param frame_id         frame ID to make active,
 *                         if == 0, use the current frame ID
 *                         if == 1, use the topmost frame ID
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_show_next_statement(bool quiet=false,
                                       int breakpoint_id=0,int exception_id=0,
                                       _str event_kind='',_str event_text='',
                                       int thread_id=0,int frame_id=1) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   //say("debug_show_next_statement: HERE, id="breakpoint_id" except="exception_id" thread="thread_id);
   session_id := dbg_get_current_session();
   // what is the current stack frame
   if (thread_id==0) {
      thread_id = dbg_get_cur_thread();
   }
   if (thread_id <= 0) {
      if (!quiet) {
         debug_message("No current thread");
      }
      return(thread_id);
   }
   status := 0;
   if (frame_id == 1) {
      status = debug_pkg_update_stack_top(thread_id);
   } else {
      status = debug_pkg_update_stack(thread_id);
   }
   if (status < 0) {
      if (!quiet) {
         debug_message("Error getting stack trace",status);
      }
      return(status);
   }
   if (frame_id <= 0) {
      frame_id=dbg_get_cur_frame(thread_id);
   }
   if (frame_id <= 0) {
      if (!quiet) {
         debug_message("No current frame");
      }
      return(frame_id);
   }
   // get the details about the current method
   method_name := signature := return_type := class_name := file_name := address := "";
   line_number := 0;
   status=dbg_get_frame(thread_id, frame_id, method_name, signature, return_type, class_name, file_name, line_number, address);
   debug_log("debug_show_next_statement: file="file_name" class="class_name" method="method_name" frame_id="frame_id);
   if (status) {
      if (!quiet) {
         debug_message("Error looking up current frame",status);
      }
      return(status);
   }
   // no source code or debug information
   if (file_name=='' || line_number<0) {
      if (dbg_get_callback_name(session_id)=='gdb') {
         method_name=(class_name==''? method_name:class_name'::'method_name);
      } else {
         method_name=(class_name==''? method_name:class_name'.'method_name);
      }
      if (!quiet) {
         debug_message(nls("No debug information for \"%s()\"",method_name));
      }
      debug_breakpoint_message(event_kind,breakpoint_id,exception_id,method_name);
      debug_log("debug_show_next_statement: NO DEBUG INFORMATION");
      return(-1);
   }
   // Attempt to resolve the path to 'file_name'
   if (file_name != absolute(file_name)) {
      full_path := debug_resolve_or_prompt_for_path(file_name,class_name,method_name,!quiet);
      if (full_path == '') {
         // no message here, they have already been prompted for a path
         return(-1);
      }
      dbg_set_frame_path(thread_id,frame_id,full_path);
      file_name=full_path;
      debug_gui_update_cur_frame(thread_id,frame_id);
   }

   // try to open the file
   status=edit(_maybe_quote_filename(file_name),EDIT_DEFAULT_FLAGS);
   if (status) {
      // no message here, edit() will complain if it has a problem
      return status;
   }

   // maybe add this file to list of read only files
   debug_maybe_add_readonly_file(file_name);

   // kill current selection if there is one
   maybe_deselect(true);

   // if the buffer has not been modified, set the old line numbers
   //if (!p_modify) {
   //   _SetAllOldLineNumbers();
   //}

   // go to the specified line number
   //_GoToOldLineNumber(line_number);
   goto_line(line_number);

   p_col=1;
   p_DebugMode=true;

   // tell user what happened
   if (dbg_get_callback_name(session_id)=='gdb') {
      method_name=(class_name==''? method_name:class_name'::'method_name);
   } else {
      method_name=(class_name==''? method_name:class_name'.'method_name);
   }
   debug_breakpoint_message(event_kind,breakpoint_id,exception_id,method_name);

   // make sure the editor stack is up to date
   dbg_update_editor_stack(thread_id,frame_id);

   // that's all folks
   return(0);
}
/**
 * Move up one frame in the stack.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_up() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_wid._TreeUp();
   } else {
      // no debug stack window, have to do things the hard way
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      // already on the top frame?
      if (frame_id == 1) {
         return(0);
      }
      // try to move up
      int status=debug_gui_switch_frame(thread_id,frame_id-1);
      if (status) {
         debug_message("Error",status);
      }
   }
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   _tbOnUpdate(true);
   return(debug_show_next_statement(true,0,0,'','',0,0));
}
/**
 * Move down one frame in the stack.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_down() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_wid._TreeDown();
   } else {
      // no debug stack window, have to do things the hard way
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      // already on the bottom frame?
      if (frame_id >= dbg_get_num_frames(thread_id)) {
         return(0);
      }
      // try to move up
      int status=debug_gui_switch_frame(thread_id,frame_id+1);
      if (status) {
         debug_message("Error",status);
      }
   }
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   _tbOnUpdate(true);
   return(debug_show_next_statement(true,0,0,'','',0,0));
}
/**
 * Move to the top of the execution stack.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_top() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   CTL_TREE tree_wid=debug_gui_stack_tree();
   if (tree_wid) {
      tree_wid._TreeTop();
   } else {
      // no debug stack window, have to do things the hard way
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      // already on the top frame?
      if (frame_id == 1) {
         return(0);
      }
      // try to move up
      int status=debug_gui_switch_frame(thread_id,1);
      if (status) {
         debug_message("Error",status);
      }
   }
   debug_kill_timer();
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   _tbOnUpdate(true);
   return(debug_show_next_statement(true));
}
/**
 * Reset the files set to read-only mode back to normal editing mode.
 */
static void debug_reset_readonly_files(bool read_only_flag)
{
   if (!_no_child_windows()) {
      // save the window ID and switch to first editor window
      orig_wid := p_window_id;
      p_window_id=_mdi.p_child;
      // Find first buffer, just return buffer name
      _str buf_id = buf_match('',1,'i');
      for (;;) {
         if (rc) break;
         if (gReadOnlyFiles._indexin(buf_id)) {

            // is the file still readonly and not set that way by user?
            if (p_readonly_mode!=read_only_flag && !p_readonly_set_by_user) {
               int temp_view_id,orig_view_id;
               int status = _open_temp_view('',temp_view_id,orig_view_id,'+bi ':+buf_id);
               if (status) {
                  continue;
               }
               // Use new function and fix bug where p_readonly_set_by_user was getting set.
               _set_read_only(false,false);

               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
            }
         }
         // next please
         buf_id = buf_match('',0,'i');
      }
      // restore window id
      p_window_id=orig_wid;
   }
}
/**
 * @return Returns 'true' if the given breakpoint ID for a watchpoint.
 * 
 * @param breakpoint_id    breakpoint ID
 */
bool debug_is_watchpoint(int breakpoint_id)
{
   if (!_haveDebugging()) return false;
   breakpoint_flags := 0;
   int breakpoint_type = dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags);
   if (breakpoint_type < 0) {
      return false;
   }
   switch (breakpoint_type) {
   case VSDEBUG_BREAKPOINT_ADDRESS:
   case VSDEBUG_BREAKPOINT_LINE:
   case VSDEBUG_BREAKPOINT_METHOD:
      return false;
   case VSDEBUG_WATCHPOINT_ANY:
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
      return true;
   default:
      return false;
   }
}
/**
 * @return Returns 'true' if the given breakpoint ID for a watchpoint.
 * 
 * @param breakpoint_id    breakpoint ID
 */
bool debug_is_breakpoint(int breakpoint_id)
{
   if (!_haveDebugging()) return false;
   breakpoint_flags := 0;
   int breakpoint_type = dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags);
   if (breakpoint_type < 0) {
      return false;
   }
   switch (breakpoint_type) {
   case VSDEBUG_BREAKPOINT_ADDRESS:
   case VSDEBUG_BREAKPOINT_LINE:
   case VSDEBUG_BREAKPOINT_METHOD:
      return true;
   case VSDEBUG_WATCHPOINT_ANY:
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
      return false;
   default:
      return false;
   }
}

/**
 * Reset the class names and method names indicating the
 * context that breakpoints are set in.
 */
static int debug_auto_correct_breakpoints()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // is auto-correct breakpoints enabled?
   if (!(def_debug_options & VSDEBUG_OPTION_AUTO_CORRECT_BP)) {
      return 0;
   }

   // has table for files we have already done
   bool been_there_done_that:[];
   been_there_done_that._makeempty();

   // the number of breakpoints modified
   num_modified := 0;
   num_invalid := 0;

   // list of all breakponts to modify and changes to make
   struct {
      int breakpoint_id;
      _str class_name;
      _str method_name;
      _str orig_class;
      _str orig_method;
   } modifications[];
   modifications._makeempty();

   // for each breakpoint
   int i,j,n = dbg_get_num_breakpoints();
   for (i=1; i<=n; ++i) {

      // breakpoints only, please
      if (!debug_is_breakpoint(i)) {
         continue;
      }

      // get the breakpoint file name
      file_name := "";
      line_number := 0;
      dbg_get_breakpoint_location(i, file_name, line_number);

      // already did this file, then continue
      if (been_there_done_that._indexin(file_name)) {
         continue;
      }

      // file doesn't exist, then continue
      been_there_done_that:[file_name] = true;
      if (!file_exists(file_name)) {
         continue;
      }

      // create a temp view and update context
      buffer_already_exists := false;
      temp_view_id := 0;
      orig_view_id := 0;
      int status = _open_temp_view(file_name, temp_view_id, orig_view_id, '', buffer_already_exists, false, true);
      if (status < 0) {
         continue;
      }

      // save the current context (see below for restore)
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_push_context();

      // now cycle through all remaining breakpoints
      for (j=i; j<=n; ++j) {

         // breakpoints only, please
         if (!debug_is_breakpoint(j)) {
            continue;
         }

         // get this breakpoints file and line number information
         bp_file_name := "";
         bp_line_number := 0;
         dbg_get_breakpoint_location(j, bp_file_name, bp_line_number);

         // make sure this is the right file
         if (!_file_eq(bp_file_name, file_name)) {
            continue;
         }

         // jump to the line number for this breakpoint
         if (bp_line_number <= 0) {
            continue;
         }
         p_RLine = bp_line_number;

         // get the class and method name for this breakpoint
         class_name := "";
         method_name := "";
         dbg_get_breakpoint_scope(j, class_name, method_name);

         // compute the class and method name as seen by tagging
         cur_tag_name := "";
         cur_type_name := "";
         cur_context := "";
         int context_id = debug_get_current_context(cur_context, cur_tag_name, cur_type_name);
         if (context_id <= 0 || cur_tag_name == '') {
            continue;
         }
         debug_translate_class_name(cur_context);

         // reset the breakpoint scope
         if (cur_tag_name != method_name || cur_context != class_name) {
            modifications[num_modified].breakpoint_id = j;
            modifications[num_modified].class_name  = cur_context;
            modifications[num_modified].method_name = cur_tag_name;
            modifications[num_modified].orig_class  = class_name;
            modifications[num_modified].orig_method = method_name;
            num_modified++;
         }
      }

      // close the temp view, we are finished here
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      //DJB 01-03-2007 -- push/pop context is obsolete
      //tag_pop_context();
   }

   msg := "";
   if (num_invalid > 0) {
      _str plural = (num_invalid > 1)? "s":"";
      msg = "Detected "num_invalid" breakpoint"plural" not in function scope.";
      _message_box(msg);
   }

   if (num_modified > 0) {
      _str plural = (num_modified>1)? "s":"";
      msg = "Detected "num_modified" breakpoint"plural" whose scope changed.\n\n";
      for (i=0; i<modifications._length(); i++) {
         if (modifications[i].orig_class != modifications[i].class_name) {
            transform :=  modifications[i].orig_class" -> "modifications[i].class_name"\n";
            if (!been_there_done_that._indexin(transform)) {
               if (length(msg) < 800) {
                  msg :+= transform;
                  been_there_done_that:[transform]=true;
               } else {
                  msg :+= "...\n";
                  break;
               }
            }
         }
         if (modifications[i].orig_method != modifications[i].method_name) {
            transform :=  modifications[i].orig_method"() -> "modifications[i].method_name"()\n";
            if (!been_there_done_that._indexin(transform)) {
               if (length(msg) < 800) {
                  msg :+= transform;
                  been_there_done_that:[transform]=true;
               } else {
                  msg :+= "...\n";
                  break;
               }
            }
         }
      }
      msg :+= "\nAutomatically correct breakpoints now?";

      int answer = _message_box(msg, "SlickEdit Debugger", MB_YESNO);
      if (answer == IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      }
      if (answer == IDYES) {
         for (i=0; i<modifications._length(); i++) {
            dbg_set_breakpoint_scope(modifications[i].breakpoint_id,
                                     modifications[i].class_name,
                                     modifications[i].method_name);
         }
         debug_gui_update_breakpoints();
      }
   }

   // that's all folks
   return 0;
}

/**
 * Save the breakpoints in the current file, optionally restricting 
 * to a range of lines, and saving relocation information.
 * <p> 
 * This function is used to save breakpoint information before we do 
 * something that heavily  modifies a buffer, such as refactoring, 
 * beautification, or auto-reload.  It uses the relocatable marker 
 * information to attempt to restore the breakpoints back to their 
 * original line, even if the actual line number has changed because 
 * lines were inserted or deleted. 
 * 
 * @param bpSaves       Saved breakpoints           
 * @param startRLine    First line in region to save
 * @param endRLine      Last line in region to save
 * @param relocatable   Save relocation marker information? 
 *  
 * @see _RestoreBreakpointsInFile 
 *  
 * @categories Debugger_Functions 
 */
void _SaveBreakpointsInFile(BreakpointSaveInfo (&bpSaves)[],
                            int startRLine=0, int endRLine=0,
                            bool relocatable=true)
{
   // For each breakpoint, save the ones that are in the current
   // file and within the specified region
   if (!_haveDebugging()) return;
   bpSaves._makeempty();
   int indices[];
   for ( i:=1; i <= dbg_get_num_breakpoints(); ++i ) {

      // Get the the data about the breakpoints
      buf_id := 0;
      BreakpointSaveInfo bpInfo;
      dbg_get_breakpoint(i, 
                         bpInfo.count, bpInfo.condition,
                         bpInfo.threadName, bpInfo.className,
                         bpInfo.methodName, bpInfo.fileName,
                         bpInfo.lineNumber, bpInfo.enabled,
                         bpInfo.address);
      bpInfo.bp_type = dbg_get_breakpoint_type(i, bpInfo.bp_flags);


      // If the specified file does not match
      if (!_file_eq(bpInfo.fileName, p_buf_name)) {
         continue;
      }

      // If the breakpoint is before the start of the line region
      if (startRLine > 0 && bpInfo.lineNumber < startRLine) {
         continue;
      }

      // If the breakpoint is after the end of the line region
      if (endRLine > 0 && bpInfo.lineNumber > endRLine) {
         continue;
      }

      // Get the relocatable marker info
      if (relocatable) {
         save_pos(auto p);
         p_RLine = bpInfo.lineNumber;
         _BuildRelocatableMarker(bpInfo.relocationInfo);
         restore_pos(p);
      } else {
         bpInfo.relocationInfo = null;
      }

      // Save all the information about the breakpoint.
      indices :+= i;
      bpSaves :+= bpInfo;
   }

   // Now delete all the breakpoints that were saved away
   for (i = indices._length() - 1; i >= 0; --i) {
      dbg_remove_breakpoint(indices[i]);
   }
}

/**
 * Restore saved breakpoints from the current file and relocate them
 * if the breakpoint information includes relocation information. 
 * 
 * @param bmSaves          Saved breakpoints           
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see _SaveBreakpointsInFile 
 *  
 * @categories Debugger_Functions 
 */
void _RestoreBreakpointsInFile(BreakpointSaveInfo (&bpSaves)[], int adjustLinesBy=0)
{
   if (!_haveDebugging()) return;
   resetTokens := true;
   save_pos(auto p);
   for (i := 0; i < bpSaves._length(); ++i) {

      // adjust line number if requested
      if (adjustLinesBy && bpSaves[i].lineNumber + adjustLinesBy > 0) {
         bpSaves[i].lineNumber += adjustLinesBy;
         if (bpSaves[i].relocationInfo != null) {
            bpSaves[i].relocationInfo.origLineNumber += adjustLinesBy;
         }
      }

      // relocate the marker, presuming the file has changed
      int origRLine = bpSaves[i].lineNumber;
      if (bpSaves[i].relocationInfo != null) {
         origRLine = _RelocateMarker(bpSaves[i].relocationInfo, resetTokens);
         resetTokens = false;
         if (origRLine < 0) {
            origRLine = bpSaves[i].lineNumber;
         }
      }

      // now add the breakpoint
      bp := dbg_add_breakpoint(bpSaves[i].count, 
                               bpSaves[i].condition,
                               bpSaves[i].threadName,
                               bpSaves[i].className, 
                               bpSaves[i].methodName,
                               bpSaves[i].fileName, origRLine,
                               bpSaves[i].address, 
                               bpSaves[i].bp_type, 
                               bpSaves[i].bp_flags);
      if (bpSaves[i].enabled) {
         debug_pkg_enable_breakpoint(bp,true);
      }
   }

   debug_gui_update_breakpoints(true);
   restore_pos(p);
}


/**
 * Terminate the debugger.
 *
 * @param quiet              Do not issue error messages, just stop debugging.
 * @param stay_in_debug_mode Do not switch out of debug mode.  This is used to
 *                           avoid toolbar switching when restarting the debugger.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_stop(bool quiet=true, bool stay_in_debug_mode=false) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if(isEclipsePlugin()) {
      return eclipse_stop_debug();
   }
   // already terminated?
   if (!debug_active()) {
      if (!quiet) {
         debug_message("Debugger is not active");
      }
      return(0);
   }
   debug_kill_timer();
   mou_hour_glass(true);
   debug_gui_clear_disassembly();
   int result=debug_pkg_terminate();
   int status=debug_pkg_finalize();
   gInStepType=DEBUG_STEP_TYPE_NONE;
   gSuspended=false;
   gRemoteDebug=false;
   debug_gui_clear_thread_update_flags();
   gDebuggerTimerId=-1;
   gFilePathCache._makeempty();
   gStartCompileTime='';
   //debug_active()=false;
   debug_gui_update_suspended();
   debug_gui_update_all_buttons();
   dbg_clear_editor();
   debug_remove_temporary_breakpoints();
   dbg_update_editor_breakpoints();
   debug_gui_update_user_views(VSDEBUG_UPDATE_FINALIZE);
   if (result || status || !stay_in_debug_mode) {
      debug_maybe_stop_debugging();
   }
   mou_hour_glass(false);
   if (result) {
      if (!quiet) {
         debug_message("Error terminating debugger",result,false);
      }
      return(result);
   }
   if (status) {
      if (!quiet) {
         debug_message("Error",status);
      }
      return(status);
   }

   // that's all folks
   clear_message();
   return(0);
}

/**
 * Step into the next statement (or step into the first statement).
 * <P>
 * This command also doubles as the entry point for starting debugging.
 * If we are not already in debug mode, this command will delegate to
 * "_project_debug2" to start everything, and then immediately issue a
 * 'step into' command.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_into(bool buildFirstDone=false, 
                             bool doRestart=false,
                             _str debugArguments="",
                             _str debugWorkingDir="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_step_into();
   }
   // if not in debugging, start debugging first
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   status := 0;
   startingDebugger := false;
   main_symbol_name:='';
   if (!debug_active() || doRestart) {
      // start the debugger
      status = _project_debug2(buildFirstDone,
                               (doRestart)?'restart':'into',
                               debugArguments,
                               debugWorkingDir);
      if (status) {
         return(status);
      }
      // Did we start _project_debug2, but not use our debugging.
      if (!debug_active()) {
         return(0);
      }
      startingDebugger=true;
      app_type := "";
      if (_project_name!='') {
         app_type=_ProjectGet_Type(_ProjectHandle(),gActiveConfigName);
      } else {
         handle := _fileProjectHandle();
         if (handle >=0) {
            app_type=_ProjectGet_Type(handle,_fileProjectConfig());
         }
      }
      if (app_type:=='rustc') {
         main_file_name := (_isEditorCtl()? _strip_filename(p_buf_name,'pe') : "main");
         main_symbol_name = main_file_name'::main';
      } else if (app_type:=='cargo') {
         path := _strip_filename(_workspace_filename,'n');
         if (_last_char(path):==FILESEP) {
            path=substr(path,1,length(path)-1);
            path=_strip_filename(path,'p');
            main_symbol_name=path'::main';
         }
      }
   } else {
      // if not suspended, get out of here
      if (!gSuspended) {
         return(DEBUG_THREAD_NOT_SUSPENDED_RC);
      }
      if (gCoreFileDebug) {
         return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
      }
      message("Stepping...");
   }

   // issue the package-specific step command
   debug_kill_timer();
   mou_hour_glass(true);
   gInStepType=DEBUG_STEP_TYPE_INTO;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());

   status=debug_pkg_step_into(startingDebugger,main_symbol_name);
   if (status && status!=DEBUG_NO_CURRENT_THREAD_RC) {
      mou_hour_glass(false);
      debug_message("Error stepping",status);
      return(status);
   }
   gSuspended=false;

   // and update everything
   debug_gui_clear_thread_update_flags();
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(status);
}
/**
 * Step into the next instruction (or step into the first instruction).
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_instr() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   if (gCoreFileDebug) {
      return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
   }

   // issue the package-specific step command
   debug_kill_timer();
   mou_hour_glass(true);
   message("Stepping...");
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   gInStepType=DEBUG_STEP_TYPE_INST;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   int status=debug_pkg_step_instr();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error stepping",status);
      return(status);
   }
   // and update everything
   gSuspended=false;
   debug_gui_clear_thread_update_flags();
   _UpdateDebugger(true);

   // check if this session supports disassembly
   if (debug_session_is_implemented("update_disassembly")) {
      if (dbg_get_num_suspended() == dbg_get_num_threads()) {
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         file_name := "";
         line_number := 0;
         if (!dbg_get_frame_path(thread_id, frame_id, file_name, line_number)) {
            if (dbg_toggle_disassembly(file_name, -1) <= 0) {
               if (_isEditorCtl() && _file_eq(file_name, p_buf_name)) {
                  debug_toggle_disassembly();
               }
            }
         }
      }
   }

   debug_gui_update_suspended();
   debug_gui_update_all_buttons();
   mou_hour_glass(false);
   return(0);
}
/**
 * Step into the next instruction even if it is a system call.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_deep() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   if (gCoreFileDebug) {
      return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
   }

   // issue the package-specific step command
   debug_kill_timer();
   mou_hour_glass(true);
   message("Stepping...");
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   gInStepType=DEBUG_STEP_TYPE_DEEP;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   int status=debug_pkg_step_deep();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error stepping",status);
      return(status);
   }
   // and update everything
   gSuspended=false;
   debug_gui_clear_thread_update_flags();
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}
/**
 * Step over the next statement.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_over() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_step_over();
   }
   if (p_scroll_left_edge>=0) {
      _scroll_page('r');
   }
   if (!debug_active()) {
      return(debug_step_into());
   } else {
      // if not suspended, get out of here
      if (!gSuspended) {
         return(DEBUG_THREAD_NOT_SUSPENDED_RC);
      }
      if (gCoreFileDebug) {
         return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
      }
      message("Stepping...");
   }
   debug_kill_timer();
   mou_hour_glass(true);
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   gInStepType=DEBUG_STEP_TYPE_OVER;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   int status=debug_pkg_step_over();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error stepping",status);
      return(status);
   }
   gSuspended=false;
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}
/**
 * Step out of the current function.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_out() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_step_return();
   }
   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   if (gCoreFileDebug) {
      return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
   }

   debug_kill_timer();
   mou_hour_glass(true);
   message("Stepping out...");
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   gInStepType=DEBUG_STEP_TYPE_OUT;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   int status=debug_pkg_step_out();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error stepping",status);
      return(status);
   }
   gSuspended=false;
   debug_force_update_after_step_or_continue();
   mou_hour_glass(false);
   return(0);
}

// For some debuggers, like the Python PTVSD, 
// receipt of the set instruction pointer response doesn't mean the
// deed is done, but that it is underway, and there
// will be a stop event with the updated information 
// when the operation completes.
static bool debug_set_ip_generates_stop_event()
{
   rv := false;
   sid := dbg_get_current_session();
   if (sid > 0) {
      cb := dbg_get_callback_name(sid);
      rv = cb == 'dap';
   }

   return rv;
}

/**
 * Set the instruction pointer for the top frame in the
 * current thread to the current file/line/address.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_set_instruction_pointer() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   if (gCoreFileDebug) {
      return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
   }
   if(isEclipsePlugin()) {
      return(DEBUG_FUNCTION_NOT_FOUND_RC);
   }
   if (_no_child_windows()) {
      debug_message("No files open");
      return(FILE_NOT_FOUND_RC);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // issue the package-specific step command
   debug_kill_timer();
   mou_hour_glass(true);

   // update the instruction pointer
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);

   // warn them if they are attempting to move outside of the current file
   frame_name := unused := frame_file := "";
   frame_line := 0;
   dbg_get_frame(thread_id, frame_id,
                 frame_name, unused, unused, unused, 
                 frame_file, frame_line, unused);
   if (!_file_eq(_strip_filename(frame_file, 'P'), _strip_filename(p_buf_name, 'P'))) {
      mou_hour_glass(false);
      debug_message("Can not move instruction pointer outside of file.");
      return COMMAND_CANCELLED_RC;
   }

   // do nothing if they aren't really changing the instruction pointer
   if (frame_line == p_RLine) {
      mou_hour_glass(false);
      return 0;
   }

   // probe for whether we can set a watch here or not
   // Make sure the current context is up-to-date
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
  
   
   // get the name of the current class and method
   _str address=debug_get_disassembly_address();
   status := tag_get_current_context(auto cur_tag_name,auto cur_flags,
                                     auto cur_type_name,auto cur_type_id,
                                     auto cur_context,auto cur_class,auto cur_package);

   // blow away the proc name if we are not in a proc
   if (status < 0 || !tag_tree_type_is_func(cur_type_name)) {
      cur_tag_name='';
   }

   // strip the function name reported by the debugger down to bare essentials.
   parse frame_name with frame_name "(" .;
   lastsep := lastpos(':',frame_name);
   if (lastsep <= 0) lastsep = lastpos('.',frame_name);
   if (lastsep <= 0) lastsep = lastpos('/',frame_name);
   if (lastsep > 0) frame_name = substr(frame_name,lastsep+1);

   // complain if they are trying to move the pointer outside
   // of the current function
   if (cur_tag_name != frame_name &&
      _message_box("Warning: attempting to move instruction pointer outside of current function.","SlickEdit",MB_OKCANCEL) != IDOK) {
      mou_hour_glass(false);
      return COMMAND_CANCELLED_RC;
   }

   // everything checks out, so move the pointer
   status=debug_pkg_set_instruction_pointer(thread_id, frame_id,
                                            cur_context, cur_tag_name,
                                            p_buf_name, p_RLine, address);
   if (status) {
      mou_hour_glass(false);
      debug_message("Error setting instruction pointer",status);
      return(status);
   }

   // and update everything
   if (debug_set_ip_generates_stop_event()) {
      // A stop event is coming or is already queued that will
      // update the location, etc...
      debug_force_update_after_step_or_continue(true);
   } else {
      debug_gui_update_cur_frame(thread_id, frame_id);
   }
   mou_hour_glass(false);
   return(0);
}
/**
 * Toggle disassembly view
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_toggle_disassembly() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // the current object must be an editor control
   if (!_isEditorCtl()) {
      if (!_no_child_windows()) {
         return _mdi.p_child.debug_toggle_disassembly();
      }
      return 0;
   }

   // do we have assembly for this file already?
   mou_hour_glass(true);
   if (!dbg_have_updated_disassembly(p_buf_name)) {

      // do not allow disassembly while a file is being diffed
      if (_isdiffed(p_buf_id)) {
         _message_box(nls("You cannot display disassembly for the file '%s' because it is being diffed.",p_buf_name));
         return 1;
      }

      // no disassembly, so update
      int status = debug_pkg_update_disassembly(p_buf_name, p_RNoflines);
      if (status < 0) {
         debug_message("Could not get disassembly for \"":+p_buf_name:+"\"", status);
         mou_hour_glass(false);
         return status;
      }
   }

   // is the disassembly displayed or not?
   int show_disassembly = dbg_toggle_disassembly(p_buf_name, -1);
   if (show_disassembly < 0) {
      mou_hour_glass(false);
      return show_disassembly;
   }

   // toggle whether to show disassembly for this file or not
   dbg_toggle_disassembly(p_buf_name, (int) !show_disassembly);

   // update the display
   debug_gui_update_disassembly();
   debug_maybe_add_readonly_file(p_buf_name);
   mou_hour_glass(false);
   return(0);
}
/**
 * Step past the current line.  This behaves like run-to-cursor,
 * pretending the cursor is on the next line.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_step_past() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // if not suspended, get out of here
   if (!gSuspended) {
      return(DEBUG_THREAD_NOT_SUSPENDED_RC);
   }
   if (gCoreFileDebug) {
      return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
   }

   if (!debug_check_enable_breakpoint("Step past is not supported in this environment.")) {
      return(STRING_NOT_FOUND_RC);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);

   /*
   // get the thread name
   _str thread_name,thread_group;
   thread_flags := 0;
   int status=dbg_get_thread(thread_id,thread_name,thread_group,thread_flags);
   if (status) {
      debug_message("Error",status);
      return(status);
   }
   */

   // get the class, method, etc.
   _str method_name,signature,return_type,class_name;
   _str file_name, address;
   line_number := 0;
   int status=dbg_get_frame(thread_id,frame_id,
                            method_name,signature,return_type,class_name,
                            file_name,line_number,address);
   if (status) {
      debug_message("Error",status);
      return(status);
   }

   // add a temporary breakpoint
   int breakpoint_id=dbg_add_breakpoint(-1,null,null /*thread_group'.'thread_name*/,
                                        class_name,method_name,
                                        file_name,line_number+1,null,
                                        VSDEBUG_BREAKPOINT_LINE, 0);
   if (breakpoint_id > 0) {
      // enable it
      status=debug_pkg_enable_breakpoint(breakpoint_id,false);
      if (status) {
         breakpoint_id=status;
         debug_remove_temporary_breakpoints();
      }
   }
   if (breakpoint_id < 0) {
      return debug_step_over();
   }

   // and then go
   debug_kill_timer();
   mou_hour_glass(true);
   message("Stepping...");
   gInStepType=DEBUG_STEP_TYPE_PAST;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   status=debug_pkg_continue();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error continuing",status);
      return(status);
   }
   gSuspended=false;
   debug_force_update_after_step_or_continue();
   status=dbg_update_editor_breakpoints();
   mou_hour_glass(false);
   return(status);
}
/**
 * Run until we hit the line where the cursor currently is.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_run_to_cursor(bool buildFirstDone=false, _str debugStepType='go') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_run_to_line();
   }
   if (_no_child_windows()) {
      debug_message("No files open");
      return(FILE_NOT_FOUND_RC);
   }
   if (!debug_check_enable_breakpoint("Run to cursor is not supported in this environment.")) {
      return(STRING_NOT_FOUND_RC);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // make sure that we are allowed to set breakpoints here
   enabled := false;
   line_number := 0;
   address := "";
   int breakpoint_id=debug_find_and_probe_breakpoint(enabled,line_number,address);
   if (breakpoint_id < 0 && breakpoint_id!=DEBUG_BREAKPOINT_NOT_FOUND_RC) {
      return(breakpoint_id);
   }

   // add a temporary breakpoint
   breakpoint_id=debug_add_breakpoint_at(true, 0, address);
   if (breakpoint_id < 0) {
      debug_message("Error adding breakpoint",breakpoint_id);
      return(breakpoint_id);
   }

   // enable the breakpoint
   int status=debug_pkg_enable_breakpoint(breakpoint_id,true);
   if (status) {
      debug_message("Error setting breakpoint",status);
      debug_remove_temporary_breakpoints();
      return(status);
   }

   // if not in debugging, start debugging first
   if (!debug_active()) {
      // start the debugger
      status = _project_debug2(buildFirstDone, debugStepType);
      if (status) {
         return(status);
      }
      // Did we start _project_debug2, but not use our debugging.
      if (!debug_active()) {
         return(0);
      }
   } else {
      // if not suspended, get out of here
      if (!gSuspended) {
         return(DEBUG_THREAD_NOT_SUSPENDED_RC);
      }
      if (gCoreFileDebug) {
         return(DEBUG_CAN_NOT_RESUME_CORE_FILE_RC);
      }
      message("Running to cursor...");
   }

   // and then go
   debug_kill_timer();
   mou_hour_glass(true);
   gInStepType=DEBUG_STEP_TYPE_PAST;
   gInStepDepth=dbg_get_num_frames(dbg_get_cur_thread());
   status=debug_pkg_continue();
   if (status) {
      mou_hour_glass(false);
      debug_message("Error continuing",status);
      return(status);
   }
   gSuspended=false;
   debug_force_update_after_step_or_continue();
   status=dbg_update_editor_breakpoints();
   mou_hour_glass(false);
   return(status);
}

/**
 * This runs to the cursor, but it modifies the command line first
 */
void debug_run_to_cursor_unittest(_str testName)
{
   _utModifyDebugCmdLineForJUnit(testName);
   debug_go(true);
   _utRestoreDebugCmdLineForJUnit();
}

/**
 * Toggles breakpoint between two states, enabled and removed
 * 
 * @categories Debugger_Commands
 */
_command int debug_toggle_breakpoint() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_PRO_EDITION|VSARG2_MULTI_CURSOR)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // If were started as part of the eclipse plug-in then
   // we need to toggle breakpoint via Eclipse
   //
   if (isEclipsePlugin()) {
      eclipse_togglebreakpoint();
      return (0);
   }
   if (_no_child_windows()) {
      debug_message("Can not set breakpoint: no files open",0,false);
      return(FILE_NOT_FOUND_RC);
   }
   if (!debug_check_enable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }
   orig_wid := p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=_mdi.p_child;
   }

   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   status := 0;
   line_number := p_RLine;
   address := "";
   enabled := false;
   int breakpoint_id=debug_find_and_probe_breakpoint(enabled,line_number,address);
   if (breakpoint_id > 0) {
      // already have a breakpoint, remove it
      if (enabled) {
         /*status=*/debug_pkg_disable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error disabling breakpoint",status);
         }
      }
      if (!status) {
         status=dbg_remove_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error removing breakpoint",status);
         }
      }
   } else if (breakpoint_id==DEBUG_BREAKPOINT_NOT_FOUND_RC) {
      // need to create a new breakpoint and insert it
      breakpoint_id = debug_add_breakpoint_at(false,line_number,address);
      if (breakpoint_id < 0) {
         debug_message("Error adding breakpoint",breakpoint_id);
         status=breakpoint_id;
      }
      //say("debug_toggle_breakpoint: breakpoint="breakpoint_id" line="line_number);

      // enable the breakpoint
      if (breakpoint_id > 0) {
         status = debug_pkg_enable_breakpoint(breakpoint_id);
         //say("debug_toggle_breakpoint: status="status);
         if (status) {
            debug_message("Error enabling breakpoint",status);
         }
      }
   }

   // update the views
   p_window_id=orig_wid;
   int result=debug_gui_update_breakpoints(true);
   if (status) {
      return(status);
   }

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return(result);
}
/**
 * Toggles breakpoint between three states, enabled, disabled, and removed
 * 
 * @categories Debugger_Commands
 */
_command int debug_toggle_breakpoint3() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_PRO_EDITION|VSARG2_MULTI_CURSOR)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (_no_child_windows()) {
      debug_message("No files open");
      return(FILE_NOT_FOUND_RC);
   }
   if (!debug_check_enable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }
   orig_wid := p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=_mdi.p_child;
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   status := 0;
   line_number := p_RLine;
   address := "";
   enabled := false;
   int breakpoint_id=debug_find_and_probe_breakpoint(enabled,line_number,address);
   if (breakpoint_id > 0) {
      // already have a breakpoint, remove it
      if (enabled) {
         status=debug_pkg_disable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error disabling breakpoint",status);
         }
      } else {
         status=dbg_remove_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error removing breakpoint",status);
         }
      }
   } else if (breakpoint_id==DEBUG_BREAKPOINT_NOT_FOUND_RC) {
      // need to create a new breakpoint and insert it
      breakpoint_id = debug_add_breakpoint_at(false,line_number,address);
      if (breakpoint_id < 0) {
         debug_message("Error adding breakpoint",breakpoint_id);
         status=breakpoint_id;
      }

      // enable the breakpoint
      if (breakpoint_id > 0) {
         status = debug_pkg_enable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error enabling breakpoint",status);
         }
      }
   }

   // update the views
   p_window_id=orig_wid;
   int result=debug_gui_update_breakpoints(true);
   if (status) {
      return(status);
   }

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return(result);
}
/**
 * Toggles breakpoint between two states, enabled and disabled
 * 
 * @categories Debugger_Commands
 */
_command int debug_toggle_breakpoint_enabled() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_PRO_EDITION|VSARG2_MULTI_CURSOR)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (isEclipsePlugin()) {
      return eclipse_togglebreakpointenabled();
   }
   if (_no_child_windows()) {
      debug_message("No files open");
      return(FILE_NOT_FOUND_RC);
   }
   if (!debug_check_enable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }
   orig_wid := p_window_id;
   if (!_isEditorCtl()) {
      p_window_id=_mdi.p_child;
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   status := 0;
   line_number := p_RLine;
   address := "";
   enabled := false;
   int breakpoint_id=debug_find_and_probe_breakpoint(enabled,line_number,address);
   if (breakpoint_id > 0) {
      // already have a breakpoint, disable it
      if (enabled) {
         status=debug_pkg_disable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error disabling breakpoint",status);
         }
      } else {
         status=debug_pkg_enable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error enabling breakpoint",status);
         }
      }
   } else if (breakpoint_id==DEBUG_BREAKPOINT_NOT_FOUND_RC) {
      // need to create a new breakpoint and insert it
      breakpoint_id = debug_add_breakpoint_at(false,line_number,address);
      if (breakpoint_id < 0) {
         debug_message("Error adding breakpoint",status);
         status=breakpoint_id;
      }

      // enable the breakpoint
      if (breakpoint_id > 0) {
         status = debug_pkg_enable_breakpoint(breakpoint_id);
         if (status) {
            debug_message("Error enabling breakpoint",status);
         }
      }
   }

   // update the views
   p_window_id=orig_wid;
   int result=debug_gui_update_breakpoints(true);
   if (status) {
      return(status);
   }

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return(result);
}

int debug_mouse_click_breakpoint()
{
   // do notthing if this session does not support it
   if (!debug_check_enable_breakpoint()) {
      return(0);
   }

   orig_line := p_line;
   mou_mode(1);
   mou_capture();
   mou_set_pointer(MP_ALLOWDROP);

   enabled := false;
   line_number := p_RLine;
   address := "";
   int breakpoint_id=debug_find_and_probe_breakpoint(enabled,line_number,address);
   if (breakpoint_id <= 0) {
      return breakpoint_id;
   }

   pic_file := "_ed_breakpoint.svg";
   breakpoint_flags := 0;
   int breakpoint_type = dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags);
   switch (breakpoint_type) {
   case VSDEBUG_BREAKPOINT_ADDRESS:
   case VSDEBUG_BREAKPOINT_LINE:
   case VSDEBUG_BREAKPOINT_METHOD:
      pic_file = (enabled? "_ed_breakpoint.svg" : "_ed_breakpoint_disabled.svg");
      break;
   case VSDEBUG_WATCHPOINT_ANY:
   case VSDEBUG_WATCHPOINT_READ:
   case VSDEBUG_WATCHPOINT_WRITE:
      pic_file = (enabled? "_ed_watchpoint.svg" : "_ed_watchpoint_disabled.svg");
      break;
   default:
      pic_file = (enabled? "_ed_watchpoint.svg" : "_ed_watchpoint_disabled.svg");
      break;
   }

   int status = mouse_drag(null, pic_file);
   if (status < 0) {
      return status;
   }

   if (p_line == orig_line) {
      debug_toggle_breakpoint_enabled();
   } else {
      // get the name of the current class and method
      // probe for whether we can set a breakpoint here or not
      _str cur_tag_name;
      _str cur_context;
      _str cur_type_name;
      status=debug_get_current_context(cur_context,cur_tag_name,cur_type_name);
      if (status < 0) {
         return(status);
      }

      // is the current line on a function or procedure
      if (!tag_tree_type_is_func(cur_type_name) || cur_tag_name=='') {
         if( _LanguageInheritsFrom("html") ) {
            // Let-it-slide cases: 
            //   phpscript embedded in PHP
            //   java embedded in JSP
            _str embeddedLang = _GetEmbeddedLangId();
            if( embeddedLang != "java" && embeddedLang != "phpscript" ) {
               return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
            }
         } else {
            // Pure PHP script (i.e. not embedded in HTML)?
            // Python?
            // Perl
            if( !_LanguageInheritsFrom("phpscript") &&
                !_LanguageInheritsFrom("py") &&
                !_LanguageInheritsFrom("pl") &&
                !_LanguageInheritsFrom("ruby") ) {
               return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
            }
         }
      }

      // add the breakpoint to the list of breakpoints (disabled)
      debug_translate_class_name(cur_context);
      dbg_set_breakpoint_scope(breakpoint_id, cur_context, cur_tag_name);
      dbg_set_breakpoint_location(breakpoint_id, p_buf_name, p_RLine, address);

      if (enabled) {
         debug_pkg_disable_breakpoint(breakpoint_id);
         status = debug_pkg_enable_breakpoint(breakpoint_id);
         if (status < 0) {
            return(status);
         }
      }
   }
   debug_gui_update_breakpoints(true);

   // update the debugger, in case if we hit the breakpoint right away
   if (debug_active()) {
      mou_hour_glass(true);
      debug_force_update_after_step_or_continue();
      mou_hour_glass(false);
   }

   return 0;
}

/**
 * Display the breakpoints toolbar
 * 
 * @categories Debugger_Commands
 */
_command int debug_breakpoints() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      eclipse_show_breakpoints();
   }
   if (!debug_check_enable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }
   activate_breakpoints();
   return(0);
}
/**
 * Display the exception breakpoints toolbar
 * 
 * @categories Debugger_Commands
 */
_command int debug_exceptions() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!debug_check_enable_exception()) {
      return(STRING_NOT_FOUND_RC);
   }
   activate_exceptions();
   return(0);
}
/**
 * Disable all the breakpoints currently stored.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_disable_all_breakpoints() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!debug_check_disable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   mou_hour_glass(true);
   status := result := 0;
   int i,n=dbg_get_num_breakpoints();

   // first, check if all the breakpoint are already disabled
   all_disabled := true;
   enable_all := false;
   for (i=1; i<=n; ++i) {
      int enabled=dbg_get_breakpoint_enabled(i);
      if (enabled) {
         all_disabled=false;
      }
   }
   if (n>0 && all_disabled) {
      result=_message_box("All breakpoints are already disabled.\n\nWould you like to enable all breakpoint?",'',MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
      if (result==IDYES) {
         enable_all=true;
      } else
      if (result==IDCANCEL) {
         mou_hour_glass(false);
         return(1);
      }
   }

   // disable the breakpoints
   result=0;
   for (i=1; i<=n; ++i) {
      if (enable_all) {
         status = debug_pkg_enable_breakpoint(i,true);
      } else {
         status = debug_pkg_disable_breakpoint(i);
      }
      if (status) {
         result=status;
      }
   }
   mou_hour_glass(false);

   // warn them about breakpoints not disabled
   if (result) {
      if (enable_all) {
         debug_message("Error enabling breakpoints",result);
      } else {
         debug_message("Error disabling breakpoints",result);
      }
   }

   // update the views
   return debug_gui_update_breakpoints(true);
}
/**
 * Clear all the breakpoints currently set.
 *
 * @return 0 on success, <0 on error
 * 
 * @categories Debugger_Commands
 */
_command int debug_clear_all_breakpoints() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if(isEclipsePlugin()) {
      return eclipse_clear_breakpoints();
   }
   if (!debug_check_disable_breakpoint()) {
      return(STRING_NOT_FOUND_RC);
   }

   // first ask them
   if (dbg_get_num_breakpoints() > 0) {
      int result=_message_box('Are you sure you want to clear all breakpoints?','',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // first disable all the breakpoints we can
   mou_hour_glass(true);
   status := result := 0;
   int i,n=dbg_get_num_breakpoints();
   for (i=1; i<=n; ++i) {
      /*status=*/debug_pkg_disable_breakpoint(i);
      if (status) {
         result=status;
      }
   }
   // now remove everyone
   for (i=n; i>=1; --i) {
      status = dbg_remove_breakpoint(i);
      if (status) {
         result=status;
      }
   }
   mou_hour_glass(false);

   // warn them about breakpoints not disabled
   if (result) {
      debug_message("Error removing breakpoints",result);
   }

   // update the views
   return debug_gui_update_breakpoints(true);
}

/**
 * Disable all the exceptions currently stored.
 *
 * @return 0 on success, <0 on error.
 * 
 * @categories Debugger_Commands
 */
_command int debug_disable_all_exceptions() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!debug_check_disable_exception()) {
      return(STRING_NOT_FOUND_RC);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   mou_hour_glass(true);
   status := result := 0;
   int i,n=dbg_get_num_exceptions();

   // first, check if all the breakpoint are already disabled
   all_disabled := true;
   enable_all := false;
   for (i=1; i<=n; ++i) {
      int enabled=dbg_get_exception_enabled(i);
      if (enabled) {
         all_disabled=false;
      }
   }
   if (n>0 && all_disabled) {
      result=_message_box("All exceptions are already disabled.\n\nWould you like to enable all exceptions?",'',MB_YESNOCANCEL|MB_ICONQUESTION,IDNO);
      if (result==IDYES) {
         enable_all=true;
      } else
      if (result==IDCANCEL) {
         mou_hour_glass(false);
         return(1);
      }
   }

   // disable the exceptions
   for (i=1; i<=n; ++i) {
      if (enable_all) {
         status = debug_pkg_enable_exception(i);
      } else {
         status = debug_pkg_disable_exception(i);
      }
      if (status) {
         result=status;
      }
   }
   mou_hour_glass(false);

   // warn them about exceptions not disabled
   if (result) {
      debug_message("Error disabling exceptions",status);
   }

   // update the views
   return debug_gui_update_exceptions(true);
}
/**
 * Clear all the exceptions currently set.
 *
 * @return 0 on success, <0 on error
 * 
 * @categories Debugger_Commands
 */
_command int debug_clear_all_exceptions() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!debug_check_disable_exception()) {
      return(STRING_NOT_FOUND_RC);
   }

   // first ask them
   if (dbg_get_num_exceptions() > 0) {
      int result=_message_box('Are you sure you want to clear all exceptions?','',MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // first disable all the exceptions we can
   mou_hour_glass(true);
   status := result := 0;
   int i,n=dbg_get_num_exceptions();
   for (i=1; i<=n; ++i) {
      /*status=*/debug_pkg_disable_exception(i);
      if (status) {
         result=status;
      }
   }
   // now remove everyone
   for (i=n; i>=1; --i) {
      status = dbg_remove_exception(i);
      if (status) {
         result=status;
      }
   }
   mou_hour_glass(false);

   // warn them about exceptions not disabled
   if (result) {
      debug_message("Error removing exceptions",result);
   }

   // update the views
   return debug_gui_update_exceptions(true);
}

/**
 * Is the given exception in the cached exception list?
 */
bool debug_find_exception_in_list(_str exception)
{
   return _inarray(exception,gExceptionList);
}

/**
 * Update the list of exceptions
 */
int debug_update_exception_list()
{
   // look up and call the list-exceptions callback
   int i,n;
   if (gExceptionList._isempty()) {
      gExceptionList._makeempty();
      int index = debug_find_function("list_exceptions");
      if (index > 0) {
         call_index(gExceptionList,index);
      }
      // insert each class that derives from 'Exception'
      n=gExceptionList._length();
      for (i=0; i<n; ++i) {
         class_name := gExceptionList[i];
         p := lastpos('.',class_name);
         if (p) {
            gExceptionList[i] = substr(class_name,p+1):+"\t":+substr(class_name,1,p-1);
         }
      }
   }
   // check that we found some exception classes
   if (gExceptionList._length()==0) {
      _message_box("No exception classes found.");
      return(COMMAND_CANCELLED_RC);
   }
   // success!
   return(0);
}
/**
 * Add an exception breakpoint for the symbol under the cursor,
 * or if this is not an editor control display dialog to select
 * an exception class to add a breakpoint on.
 * 
 * @categories Debugger_Commands
 */
_command int debug_add_exception(_str expr="") name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (!debug_check_enable_exception()) {
      return(FILE_NOT_FOUND_RC);
   }

   status := 0;
   orig_wid := p_window_id;
   list_exceptions := false;
   session_id := dbg_get_current_session();

   if (expr=="" && !_no_child_windows() && _isEditorCtl() &&
       _istagging_supported() && p_LangId!='e') {

      // get the expression to evaluate
      _str ext;

      typeless r1,r2,r3,r4,r5;
      save_search(r1,r2,r3,r4,r5);

      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(true);
      sentry.lockMatches(true);
      _UpdateContextAndTokens(true);

      VS_TAG_IDEXP_INFO idexp_info;
      tag_idexp_info_init(idexp_info);
      struct VS_TAG_RETURN_TYPE visited:[];
      status=_Embeddedget_expression_info(false, ext, idexp_info, visited);

      restore_search(r1,r2,r3,r4,r5);

      // find the tag under the cursor
      if (!status && idexp_info.lastid != "" && pos("Exception", idexp_info.lastid) > 0) {

         status=_Embeddedfind_context_tags(idexp_info.errorArgs,idexp_info.prefixexp,
                                           idexp_info.lastid,idexp_info.lastidstart_offset,
                                           idexp_info.info_flags,idexp_info.otherinfo,false,100);
         if (status >= 0) {
            int i,n=tag_get_num_of_matches();
            for (i=1; i<=n; ++i) {
               int tag_type;
               tag_get_detail2(VS_TAGDETAIL_match_type,i,tag_type);
               if (tag_type!='class') {
                  continue;
               }
               _str tag_name;
               _str class_name;
               tag_get_detail2(VS_TAGDETAIL_match_name,i,tag_name);
               tag_get_detail2(VS_TAGDETAIL_match_class,i,class_name);
               if (class_name != '') {
                  if (dbg_get_callback_name(session_id)=='gdb') {
                     class_name :+= '::';
                  } else {
                     class_name :+= '.';
                  }
               }
               expr = class_name:+tag_name;
               debug_translate_class_name(expr);
               break;
            }
            if (n > 0 && expr=='') {
               debug_message("Error adding exception breakpoint, "(idexp_info.prefixexp:+idexp_info.lastid)" is not an exception class");
               return VSCODEHELPRC_NO_SYMBOLS_FOUND;
            }
         } else {
            list_exceptions=true;
         }
      } else {
         list_exceptions=true;
      }

   } else if (expr!='') {
      // use the expression they passed us as the exception class name
   } else {
      list_exceptions=true;
   }

   if (list_exceptions) {
      // look up and call the list-exceptions callback
      debug_update_exception_list();

      // create bitmap list (they are all classes)
      pic_class := tag_get_bitmap_for_type(SE_TAG_TYPE_CLASS);
      int bitmap_list[];
      n := gExceptionList._length();
      for (i:=0; i<n; ++i) {
         bitmap_list[i] = pic_class;
      }
      // let the user select a group of exceptions to add
      gExceptionList._sort();
      _str result=select_tree(gExceptionList,null,bitmap_list,null,
                              null,
                              null,null,
                              "Select exceptions to catch",
                              SL_ALLOWMULTISELECT|SL_MUSTEXIST|SL_COMBO|SL_COLWIDTH,
                              "Exception,Package/Class",
                              (TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT)','(TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT),
                              true,null,"exceptions");
      // now handle the result
      if (result==null || result==COMMAND_CANCELLED_RC) {
         return(COMMAND_CANCELLED_RC);
      }
      // for each exception handled
      status=0;
      while (result!='') {
         parse result with auto exception "\n" result;
         exception = _maybe_unquote_filename(exception);
         parse exception with auto class_name "\t" auto package_name;

         if( package_name == "" ) {
            // Xdebug (PHP) uses string literal exceptions (e.g. "Fatal error")
            exception = class_name;
         } else {
            exception = package_name :+ "." :+ class_name;
         }

         // check if the exception already exists
         enabled := 0;
         int exception_id=dbg_find_exception(exception,enabled,0);
         if (exception_id <= 0) {
            // add the exception breakpoint and update the views
            exception_id=dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT|VSDEBUG_EXCEPTION_STOP_WHEN_UNCAUGHT,0,'',exception,'');
            if (exception_id < 0) {
               status=exception_id;
               continue;
            }
         }

         exception_id=debug_pkg_enable_exception(exception_id);
         if (exception_id < 0) {
            status=exception_id;
         }
      }
      debug_gui_update_exceptions();
      if (status < 0) {
         debug_message("Error enabling exception",status);
      }
      return(status);
   }

   // add the exception breakpoint and update the views
   status=dbg_add_exception(VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT|VSDEBUG_EXCEPTION_STOP_WHEN_UNCAUGHT,0,'',expr,'');
   if (status < 0) {
      debug_message("Error adding exception",status);
      return(status);
   }
   status=debug_pkg_enable_exception(status);
   if (status < 0) {
      debug_message("Error enabling exception",status);
      return(status);
   }

   // restore the window ID and return status
   status=debug_gui_update_exceptions();
   return(status);
}

/**
 * Add a watch on the symbol under the cursor
 * 
 * @categories Debugger_Commands
 */
_command int debug_add_watch(_str expr="") name_info(','VSARG2_MARK|VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_check_update_watches()) {
      return(FILE_NOT_FOUND_RC);
   }

   // set the window ID to the editor control
   cur_context := "";
   cur_tag_name := "";
   cur_type_name := "";
   status := 0;
   orig_wid := p_window_id;
   if (expr == "") {
      if (_no_child_windows()) {
         return(FILE_NOT_FOUND_RC);
      }
      if (!_isEditorCtl()) {
         p_window_id=_mdi.p_child;
      }

      // probe for whether we can set a watch here or not
      // Make sure the current context is up-to-date
      // make sure that the context doesn't get modified by a background thread.
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateContext(true);

      // get the name of the current class and method
      cur_flags:=SE_TAG_FLAG_NULL;
      cur_type_id:=SE_TAG_TYPE_NULL;
      cur_class := "";
      cur_package := "";
      status=tag_get_current_context(cur_tag_name,cur_flags,
                                     cur_type_name,cur_type_id,
                                     cur_context,cur_class,cur_package);
      if (status > 0) status=0;

      // blow away the proc name if we are not in a proc
      if (status < 0 || !tag_tree_type_is_func(cur_type_name)) {
         cur_tag_name='';
      }
   }

   // if there is a selection active, then get it
   if (expr=="") {
      expr = debug_get_expression_under_cursor();
   }

   if (!status && expr!="") {
      // make sure the watches toolbar is up
      _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
      if (debug_active() && !debug_gui_watches_wid()) {
         activate_watch();
      }
      // add watches to all the matches
      session_id := dbg_get_current_session();
      tab_number := debug_gui_active_watches_tab();
      if (cur_context!='') {
         if (dbg_get_callback_name(session_id)=='gdb') {
            cur_tag_name=cur_context'::'cur_tag_name;
         } else {
            cur_tag_name=cur_context'.'cur_tag_name;
         }
      }
      debug_translate_class_name(cur_tag_name);
      status=dbg_add_watch(tab_number,expr,cur_tag_name,VSDEBUG_BASE_DEFAULT);
      if (status >= 0) {
         // update the views
         if (debug_active() && gSuspended) {
            thread_id := dbg_get_cur_thread();
            frame_id := dbg_get_cur_frame(thread_id);
            status=debug_gui_update_watches(thread_id,frame_id,tab_number);
         }
      } else {
         debug_message("Error adding watch",status);
      }
   } else {
      if (expr=="") {
         status=NOTHING_SELECTED_RC;
      }
      if (status) {
         _str errorArgs[]; errorArgs._makeempty();
         _message_box("Error setting watch: "_CodeHelpRC(status,errorArgs));
      }
   }

   // restore the window ID and return status
   p_window_id=orig_wid;
   return(status);
}

// Find and return the expression under the cursor, if any.
_str debug_get_expression_under_cursor()
{
   // if there is a selection active, then get it
   if (select_active()) {
      expr := "";
      tmp := "";
      filter_init();
      while (!filter_get_string(tmp)) {
         expr :+= tmp;
      }
      filter_restore_pos();
      return expr;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);

   // get the expression to evaluate
   _str ext;

   typeless r1,r2,r3,r4,r5;
   save_search(r1,r2,r3,r4,r5);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   struct VS_TAG_RETURN_TYPE visited:[];
   int status=_Embeddedget_expression_info(false, ext, idexp_info, visited);

   restore_search(r1,r2,r3,r4,r5);
   if (status) {
      return "";
   }

   // find the tag under the cursor
   return idexp_info.prefixexp:+idexp_info.lastid;
}

/**
 * Add a watchpoint on the symbol under the cursor
 * 
 * @param expr          expression to watch
 * @param class_name    class that expression's field is in
 * @param field_name    field that expression is in
 * 
 * @categories Debugger_Commands
 */
_command int debug_add_watchpoint(_str expr="", _str class_name="", _str field_name="") name_info(','VSARG2_MARK|VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_check_enable_watchpoints()) {
      return(FILE_NOT_FOUND_RC);
   }
   if (expr=='' && _no_child_windows()) {
      return(FILE_NOT_FOUND_RC);
   }

   // set the window ID to the editor control
   orig_wid := p_window_id;
   if (expr=='' && !_isEditorCtl()) {
      p_window_id=_mdi.p_child;
   }
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // get the selection or current ID expression
   file_name := "";
   line_number := 0;
   status := 0;
   if (expr=="") {
      // get the expression under the cursor and it's location
      expr = debug_get_expression_under_cursor();
      file_name = p_buf_name;
      line_number = p_RLine;

      // resolve the class/id information for this variable
      _UpdateContext(true,true);
      status = tag_get_browse_info("", auto cm);
      if(status >= 0) {
         tag_complete_browse_info(cm);
         class_name = cm.class_name;
         field_name = cm.member_name;
      }

      // DJB 05/20/2005 -- don't let them set breakpoints on
      //                -- locals or other non-class members
      session_id := dbg_get_current_session();
      if (dbg_get_callback_name(session_id) == 'jdwp') {
         if (cm.type_name != 'var' || cm.class_name == '') {
            debug_message("Error enabling watchpoint", DEBUG_JDWP_LOCAL_WATCHPOINT_NOT_SUPPORTED_RC);
            return DEBUG_JDWP_LOCAL_WATCHPOINT_NOT_SUPPORTED_RC;
         }
      }
   }

   if (!status && expr!="") {
      // make sure the watches toolbar is up
      if (!debug_gui_breakpoints_wid()) {
         activate_breakpoints();
      }
      debug_translate_class_name(class_name);
      status=dbg_add_breakpoint(0, expr, '', class_name, field_name, file_name, line_number, '', def_debug_watchpoint_type, 0);
      if (status >= 0) {
         status=debug_pkg_enable_breakpoint(status);
         if (status) {
            debug_message("Error enabling watchpoint",status);
         }
         // update the views
         status=debug_gui_update_breakpoints(true);

         // update the debugger, in case if we hit the watchpoint right away
         if (debug_active()) {
            mou_hour_glass(true);
            debug_force_update_after_step_or_continue();
            mou_hour_glass(false);
         }
      } else {
         debug_message("Error adding watchpoint",status);
      }
   } else {
      if (expr=="") {
         status=NOTHING_SELECTED_RC;
      }
      if (status) {
         _str errorArgs[]; errorArgs._makeempty();
         _message_box("Error setting watchpoint: "_CodeHelpRC(status,errorArgs));
      }
   }

   // restore the window ID and return status
   p_window_id=orig_wid;
   return(status);
}

/**
 * Display the debugger options dialog. 
 * The debugger must be active for this command to work properly. 
 * 
 * @categories Debugger_Commands
 */
_command int debug_props(_str default_tab='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   show("-xy -modal _debug_props_form",default_tab);
   return(0);
}

/**
 * Display the debugger properties dialog.
 * 
 * @categories Debugger_Commands
 */
_command int debug_options(_str default_tab='') name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   optionsWid := config('Debugging', '+N', '', true);
   if (!debug_active()) return 0;
   _modal_wait(optionsWid);
   return debug_pkg_update_version();
}

/**
 * Display the GDB configuration management dialog in order
 * to manage different GDB executable configurations.
 * <p>
 * Format of debugger configuration file
 * <pre>
 * &lt;Debugger&gt;
 *    &lt;Package Name="GDB"&gt;
 *       &lt;Configuration
 *          Name="PalmOS"
 *          Path='C:\palmsdk\bin\gdb_palm.exe'
 *          Platform="VSWINDOWS"
 *          Arguments=""
 *       /&gt;
 *    &lt;/Package&gt;
 * &lt;/Debugger&gt;
 * </pre>
 * 
 * @categories Debugger_Commands
 */
_command int debug_configurations() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!debug_check_debugging_support()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   optionsWid := config('_debug_props_configurations_form', '+D', '', true);
   if (!debug_active()) return 0;
   _modal_wait(optionsWid);
   return debug_pkg_update_version();
}


///////////////////////////////////////////////////////////////////////////
// debugger utility functions
//

/**
 * Search the project tag file for a class/method in
 * the specified file name, and return its directory path.
 *
 * @param file_name   file name (stripped, only file name) to search for
 * @parma class_name  name of class to search in
 * @param method_name name of method to search for
 * @parma in_project  was the file found in the project tag file?
 *
 * @return path!='' on success, '' on failure
 */
static _str debug_search_tagfiles_for_class_or_proc(_str file_name,
                                                    _str class_name,
                                                    _str method_name,
                                                    bool &in_project)
{
   // get the list of project tag files
   _str tag_files[];
   _str lang=_Filename2LangId(file_name);
   if (lang != '') {
      tag_files = tags_filenamea(lang);
   } else {
      tag_files = project_tags_filenamea();
   }

   // create a hash table containing all the workspace tag files
   bool is_workspace_tag_file:[];
   foreach (auto project_tag_file in project_tags_filenamea()) {
      is_workspace_tag_file:[_file_case(project_tag_file)] = true;
   }

   // for each tag file
   in_project=false;
   i := 0;
   for (;;) {
      // get next tag file in list
      _str tag_filename=next_tag_filea(tag_files,i,false,true);
      if (tag_filename=='') {
         break;
      }

      // If this is a package name, leave it alone
      _str search_class=class_name;
      if (tag_find_tag(class_name,"package",'')==0) {
         // do nothing
      } else {
         // resolve the class name to a database package/class name
         first_part := "";
         end_part := "";
         int p = pos("([.]|[:][:])",class_name,1,'r');
         while (p > 0) {
            tmp := substr(class_name,1,p-1);
            p += pos('');
            if (tag_find_tag(tmp,"package",'')==0) {
               // this is a package name, leave it alone
               first_part=tmp;
               end_part=substr(class_name,p);
            }
            p = pos("([.]|[:][:])",class_name,p,'r');
         }
         if (first_part!='') {
            end_part = stranslate(end_part,VS_TAGSEPARATOR_class,"([.]|[:][:]|[$])",'r');
            search_class = first_part:+VS_TAGSEPARATOR_package:+end_part;
         } else {
            search_class = stranslate(class_name,VS_TAGSEPARATOR_class,"([.]|[:][:]|[$])",'r');
         }
      }
      tag_reset_find_tag();

      // search for the given method in the given class
      //say("debug_search_tagfiles_for_class_or_proc: method="method_name" class="search_class);
      type_id := 0;
      found_file := "";
      int status=tag_find_equal(method_name,true,search_class);
      while (!status) {
         tag_get_detail(VS_TAGDETAIL_type_id,type_id);
         if (type_id==SE_TAG_TYPE_FRIEND || type_id==SE_TAG_TYPE_IMPORT || type_id==SE_TAG_TYPE_INCLUDE) {
            status = tag_next_equal(true,search_class);
            continue;
         }
         tag_get_detail(VS_TAGDETAIL_file_name,found_file);
         if (file_name=='' || _file_eq(_strip_filename(found_file,'P'),file_name)) {
            if (is_workspace_tag_file:[_file_case(tag_filename)]) {
               in_project=true;
            }
            tag_reset_find_tag();
            return(found_file);
         }
         status = tag_next_equal(true,search_class);
      }
      tag_reset_find_tag();

      // still didn't find it, look for just the class name
      if (search_class!='') {
         p := lastpos(VS_TAGSEPARATOR_class,search_class);
         if (!p) {
            p = lastpos(VS_TAGSEPARATOR_package,search_class);
         }
         just_class := "";
         if (p > 0) {
            just_class=substr(search_class,p+1);
            search_class=substr(search_class,1,p-1);
         } else {
            just_class=search_class;
            search_class='';
         }
         status=tag_find_equal(just_class,true,search_class);
         while (!status) {
            type_id=0;
            tag_get_detail(VS_TAGDETAIL_type_id,type_id);
            if (type_id==SE_TAG_TYPE_FRIEND || type_id==SE_TAG_TYPE_IMPORT || type_id==SE_TAG_TYPE_INCLUDE) {
               status = tag_next_equal(true,search_class);
               continue;
            }
            tag_get_detail(VS_TAGDETAIL_file_name,found_file);
            if (file_name=='' || _file_eq(_strip_filename(found_file,'P'),file_name)) {
               if (is_workspace_tag_file:[_file_case(tag_filename)]) {
                  in_project=true;
               }
               tag_reset_find_tag();
               return(found_file);
            }
            status = tag_next_equal(true,search_class);
         }
      }
      tag_reset_find_tag();
   }

   // no matches found
   return('');
}

/**
 * Search tag files for a source file matching the
 * specified file name, and return its complete path with dir.
 *
 * @param file_name   file name (stripped, only file name) to search for
 * @parma in_project  was the file found in the project tag file?
 *
 * @return path!='' on success, '' on failure
 */
static _str debug_search_tagfiles_for_path(_str file_name,bool &in_project)
{
   // create a hash table containing all the workspace tag files
   bool is_workspace_tag_file:[];
   foreach (auto project_tag_file in project_tags_filenamea()) {
      is_workspace_tag_file:[_file_case(project_tag_file)] = true;
   }

   in_project=false;
   found_count := 0;
   found_file := "";
   _str lang=_Filename2LangId(file_name);
   if (lang!='') {
      typeless tag_files=tags_filenamea(lang);
      i := 0;
      status := 0;
      search_file_name := _strip_filename(file_name,'p');
      ffile_name := "";
      _str tag_filename=next_tag_filea(tag_files,i,false,true);
      while (tag_filename!='') {
         status=tag_find_file(ffile_name, search_file_name);
         while (!status) {
            if (_file_eq(_strip_filename(ffile_name,'p'),search_file_name)) {
               if (found_file=='') {
                  in_project=is_workspace_tag_file:[_file_case(tag_filename)];
                  found_file=ffile_name;
               } else if (!_file_eq(ffile_name,found_file)) {
                  found_count++;
               }
            }
            status=tag_next_file(ffile_name);
         }
         tag_reset_find_file();
         tag_filename=next_tag_filea(tag_files,i,false,true);
      }
   }
   if (found_count!=1) {
      in_project=false;
   }
   return(found_file);
}
/** 
 * Check if we have a built-in Slick-C pseudo-class
 * @param class_name set to "" if it was actually just a pseudo-class.
 */
void debug_resolve_slickc_class(_str &class_name)
{
   switch (class_name) {
   case "sc.lang.vars.Globals":
   case "sc.lang.vars.Statics":
   case "sc.lang.vars.Defs":
   case "sc.lang.procs.Globals":
   case "sc.lang.procs.Statics":
   case "sc.lang.procs.Commands":
   case "sc.lang.procs.Events":
   case "sc.lang.types.Structs":
   case "sc.lang.types.EventTables":
      class_name="";
      break;
   default:
      if (pos("sc.lang.modules/",class_name)==1) {
         class_name="";
      }
      break;
   }
}
/**
 * Resolve the path name for the given file.
 *
 * @param file_name
 */
_str debug_resolve_or_prompt_for_path(_str file_name,
                                      _str class_name='',_str func_name='',
                                      bool no_prompting=false)
{
   if (!_haveDebugging()) {
      return "";
   }
   session_id := dbg_get_current_session();
   if (session_id>0) {
      session_name := dbg_get_session_name(session_id);
      if (beginsWith(session_name,'FILEPROJECT:') && _mdi.p_child._isEditorCtl(false) &&
          _file_eq(file_name,_strip_filename(_mdi.p_child.p_buf_name,'P'))) {
         return _mdi.p_child.p_buf_name;
      }
   }

   if (_get_extension(file_name)=='e') {
      debug_resolve_slickc_class(class_name);
   }
   //say("debug_resolve_or_prompt_for_path: file="file_name" class="class_name" func="func_name" prompt="no_prompting);
   _str hash_key=file_name;
   if (class_name!='') {
      // if we have a class, the function name doesn't matter
      hash_key=file_name"\t"class_name;
   } else if (func_name!='') {
      // no class name, add function if we have one (we better have one!)
      hash_key=file_name"\t\t"func_name;
   }
   if (gFilePathCache._indexin(hash_key)) {
      if (gFilePathCache:[hash_key]!='') {
         return gFilePathCache:[hash_key];
      } else if (no_prompting) {
         return '';
      }
   }

   // info about where the path was found
   in_project := false;
   found_using_tagging := true;
   found_dir := found_path := "";

   // very first, for gdb, check for absolute path to executable
   callback_name := dbg_get_callback_name(session_id);
   if (callback_name == "gdb" || callback_name == "lldb") {
      found_path = absolute(file_name);
      if (found_path!='' && file_exists(found_path)) {
         gFilePathCache:[hash_key]=found_path;
         return(found_path);
      }
      found_path='';
   }

   if (callback_name == "jdwp" || callback_name == 'scala') {
      p := pos('[.:]:i',class_name,1,'r');
      _str lang=_Filename2LangId(file_name);

      if (p > 0) {
         class_name=substr(class_name,1,p-1);
      }

      if (lang == 'groovy') {
         // Strip off closure garbage if it exists in the name.
         p = pos('\._\o:a*_closure\o:d+$', class_name, 1, 'L');
         if (p > 0) {
            class_name = substr(class_name, 1, p-1);
         }
      } else if (lang == 'scala') {
         // Scala does a lot of name munging for anonymous functions.
         // All loops bodies are anonymous functions, and they are
         // heavily used in the libraries, so we get to see this a lot.
         // Try to extract the real outer function and class name, as we
         // don't tag the anonymous functions for scala in a way they can be 
         // resolved. Some of this needs to be  done by the scala debug layer,
         //  but I'm doing it here temporarily for a hotfix.
         p = pos('/', func_name, 1, 'L');
         if (p > 0) {
            if (class_name == '') {
               class_name = substr(func_name, 1, p-1);
            }
            func_name = substr(func_name, p+1);
         }
         p = pos("\\$", class_name, 1, 'L');
         if (p > 0) {
            class_name = substr(class_name, 1, p-1);
         }

         _str name_pcs[];
         split(func_name, '$', name_pcs);
         for (i:=name_pcs._length()-1; i >= 0; i--) {
            if (name_pcs[i] == '' || isinteger(name_pcs[i])) {
               continue;
            }
            func_name = name_pcs[i];
            break;
         }
         if (beginsWith(func_name, 'def ')) {
            func_name = substr(func_name, 5);
         }
      }

      // strip the file name down to class.java,
      // this is just in case if some miscreant compiler
      // decided to put the package path in there
      p = pos('.',file_name);
      if (p > 0) {
         for (;;) {
            q := pos('.', file_name, p+1);
            if (q <= 0) break;
            file_name = substr(file_name,p+1);
            p = pos('.',file_name);
         }
      }
   }

   // first, search the project tag file for this class/func
   file_name=_strip_filename(file_name,'P');
   if (func_name!='') {
      found_path=debug_search_tagfiles_for_class_or_proc(file_name,class_name,func_name,in_project);
   }

   // see if we can find the file in the tag files
   if (found_path=='') {
      found_using_tagging=false;
      found_path=debug_search_tagfiles_for_path(file_name,in_project);
   }

   // if not found in tag file, try system specific path lookup
   if (found_path=='') {
      debug_pkg_resolve_path(file_name,found_path);
   }

   // check previously visited source directories
   if (found_path=='') {
      dbg_resolve_path(file_name,found_path);
   }

   // try finding the path among breakpoints
   if (found_path=='') {
      int i,n=dbg_get_num_breakpoints();
      for (i=1; i<=n; ++i) {
         _str break_file=1;
         break_line := 0;
         dbg_get_breakpoint_location(i,break_file,break_line);
         if (file_exists(break_file)) {
            break_file_name := _strip_filename(break_file,'P');
            if (_file_eq(break_file_name,file_name) || _file_eq(break_file,file_name)) {
               found_path=break_file;
               break;
            }
         }
      }
   }

   // check if path matches source dirs or is from project tag file
   if (found_path!='' && file_exists(found_path)) {
      // don't prompt if the file is in their project
      if (in_project) {
         gFilePathCache:[hash_key]=found_path;
         return(found_path);
      }
      // Is the no-prompting option on?
      if (!(def_debug_options & VSDEBUG_OPTION_CONFIRM_DIRECTORY)) {
         gFilePathCache:[hash_key]=found_path;
         return(found_path);
      }
      // check if patch matches a path in the source dirs
      if (found_using_tagging) {
         found_dir=_strip_filename(found_path,'N');
         source_dir := "";
         int i,n=dbg_get_num_dirs();
         for (i=1; i<=n; ++i) {
            dbg_get_source_dir(i,source_dir);
            if (_file_eq(source_dir,found_dir)) {
               gFilePathCache:[hash_key]=found_path;
               return(found_path);
            }
         }
      }
   }

   // check for src.jar in java installation
   if (dbg_get_callback_name(session_id) == 'jdwp') {
      // first step is to find the java installation, 
      // prefer the one they have configured.
      JDKPath := "";
      _str javaList[];
      _str javaNamesList[];
      get_javac_from_defvar(javaList,JDKPath,javaNamesList);
      if (JDKPath == "") {
         getJavaIncludePath(javaList,JDKPath);
      }
      // now check for src.jar, src.zip, or src directory
      SRCPath := "";
      if (JDKPath != "") {
         _maybe_append_filesep(JDKPath);
         if (file_exists(JDKPath:+"src.jar")) {
            SRCPath = JDKPath:+"src.jar";
         } else if (file_exists(JDKPath:+"lib":+FILESEP:+"src.zip")) {
            SRCPath = JDKPath:+"lib":+FILESEP:+"src.zip";
         } else if (file_exists(JDKPath:+"src.zip")) {
            SRCPath = JDKPath:+"src.zip";
         } else if (file_exists(JDKPath:+"src")) {
            SRCPath = JDKPath:+"src";
         }
      }
      if (SRCPath != "") {
         // base path on class name, first remove template arguments
         java_class_name := class_name;
         parse java_class_name with '<' .;
         java_file_name := SRCPath;
         _maybe_append_filesep(java_file_name);
         while (class_name != "") {
            // get first part of class name and check if it exists
            java_dir_name := "";
            parse class_name with java_dir_name '.' class_name;
            java_file_name :+= java_dir_name;
            if (file_exists(java_file_name)) {
               _maybe_append_filesep(java_file_name);
               continue;
            }
            // we found the file name, the rest is nested classes
            if (_file_eq(java_dir_name:+".java", file_name)) {
               break;
            }
         }
         // Now just add .java and see if the file exists
         SRCPath = java_file_name :+ ".java";
         if (file_exists(SRCPath)) {
            gFilePathCache:[hash_key]=SRCPath;
            return(SRCPath);
         }
      }
   }

   // do not prompt for Slick-C
   if (_get_extension(file_name)=='e') { 
      if (found_path != '' && file_exists(found_path)) {
         gFilePathCache:[hash_key]=found_path;
         return(found_path);
      }
   }

   // last resort, prompt the user for the real path name
   if (no_prompting==false) {
      found_dir=_strip_filename(found_path,'N');
      for_what := "";
      if (class_name!='') {
         for_what=' for ':+class_name;
      } else if (func_name!='') {
         for_what=' for ':+func_name'()';
      }
      _str full_path=show('-modal _cd_form','Find Source':+for_what,true,true,true,false,file_name,found_dir);
      if (full_path=='') {
         return('');
      }
      full_path=strip(full_path, 'B', '"');
      // check if file exists
      _maybe_append_filesep(full_path);
      full_path :+= file_name;
      if (file_exists(full_path)) {
         // success!
         gFilePathCache:[hash_key]=full_path;
         return(full_path);
      }
   } else {
      // didn't find it, hold that thought
      gFilePathCache:[hash_key]='';
   }

   // we could not find the file
   return('');
}

/**
 * Clear out the file path cache.
 */
void debug_clear_file_path_cache()
{
   gFilePathCache._makeempty();
}

/**
 * Turn debugging mode off for all buffers.
 */
/*
static void debug_turn_DebugMode_off()
{
   // for each window, check for debugging mode and turn it off.
   if (_no_child_windows()) {
      return;
   }
   orig_window_id := p_window_id;
   p_window_id=_mdi.p_child;
   first_window_id := p_window_id;
   for (;;) {
      if (p_DebugMode) {
         p_DebugMode=false;
      }
      _next_window('hr');
      if ( p_window_id:==first_window_id ) {
         return;
      }
   }
   p_window_id=orig_window_id;
}
*/

#if 0
/**
 * Create a list of field paths that are expanded.
 * This is used to save and restore the tree between
 * refreshes.
 *
 * @param tree_index      tree node index to start at
 * @param base_path       base path, initially the empty string
 * @param path_list       (reference) list of paths to construct
 */
static void debug_list_expanded_fields(int tree_index, _str base_path, _str (&path_list)[])
{
   index := _TreeGetFirstChildIndex(tree_index);
   while (index > 0) {
      _TreeGetInfo(index,show_children);
      if (show_children) {
         caption := _TreeGetCaption(index);
         parse caption with caption "\t";
         caption=base_path"\t"caption;
         path_list[path_list._length()] = caption;
         debug_list_expanded_fields(index,caption,path_list);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}
/**
 * Given a list of tree paths, expand the items as they
 * were before the tree was refreshed.
 *
 * @param path_list       list of paths to expand
 */
static void debug_expand_path_list(_str (&path_list)[])
{
   int i;
   for (i=0; i<path_list._length(); ++i) {
      debug_expand_fields(TREE_ROOT_INDEX,path_list[i]);
   }
}

/**
 * Expand the fields under the given tree path.
 *
 * @param tree_index      index of tree node to start at
 * @param path            path to expand
 */
static void debug_expand_fields(int tree_index,_str path)
{
   first_part := "";
   parse path with first_part "\t" path;

   index := _TreeGetFirstChildIndex(tree_index);
   while (index > 0) {
      _TreeGetInfo(index,show_children);
      if (show_children>=0) {
         caption := _TreeGetCaption(index);
         parse caption with caption "\t";
         if (caption==first_part) {
            if (show_children>0 && path!='') {
               debug_expand_fields(index,path);
            } else if (path=='') {
               call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'w')
               _TreeSetInfo(index, 1);
            }
            return;
         }
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}
#endif

/**
 * Test if individually suspending or resuming a thread has
 * vaulted us into a truly suspended mode, and set gSuspend
 * appropriately.
 */
int debug_check_and_set_suspended(bool quiet=false, bool check_all_threads=true)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (gCoreFileDebug) {
      gSuspended=true;
      return 0;
   }
   int status=debug_pkg_update_current_thread();
   if (check_all_threads) {
      status=debug_pkg_update_threads();
   }
   if (status) {
      return(status);
   }
   int num_threads=dbg_get_num_threads();
   int num_suspended=dbg_get_num_suspended();
   suspended := (num_threads == num_suspended);
   if (suspended != gSuspended) {
      gSuspended=suspended;
      if (gSuspended && !quiet) {
         message(nls("Execution suspended"));
      }
      // update the user views
      debug_gui_update_user_views(VSDEBUG_UPDATE_SUSPENDED);
   }
   return(0);
}

/**
 * Delete all the temporary breakpoints (those set by step-past or
 * run-to-cursor commands.
 */
static int debug_remove_temporary_breakpoints()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := result := 0;
   int i=1,n=dbg_get_num_breakpoints();
   while (i<=n) {
      int count=dbg_get_breakpoint_count(i);
      if (count == -1) {
         debug_pkg_disable_breakpoint(i);
         status=dbg_remove_breakpoint(i);
         if (status) {
            result=status;
         }
         --n;
      } else {
         ++i;
      }
   }
   return(result);
}

static _str jdwp_translate_class_name(_str class_name)
{
   // Example of what we get from debug_get_context for
   // a breakpoint inside of two nested anonymous classes:
   // "ClassName:@2:@1:1:@1".  The JWDP name would be 
   // ClassName.2.1
   suffixPos := pos('(?:@[0-9]+:)+', class_name, 1, 'U');
   if (suffixPos > 0 && pos('') > 0) {
      suffix := substr(class_name, suffixPos, pos('')-1);
      suffix = stranslate(suffix, '', '@');
      suffix = stranslate(suffix, '.', ':');
      prefix := substr(class_name, 1, suffixPos-1);
      class_name = stranslate(prefix, '.', ':') :+ suffix;
   } else {
      class_name = stranslate(class_name, '.', ':');
   }

   return class_name;
}

/**
 * Translate SlickEdit-style class names to
 * Java-style anonymous class names
 */
void debug_translate_class_name(_str &class_name)
{
   if (!_haveDebugging()) {
      return;
   }

   session_id := dbg_get_current_session();
   callback_name := dbg_get_callback_name(session_id);
   switch (callback_name) {
   case "jdwp":
      // translate single ':' (inner class seperator) with '.'
      class_name = jdwp_translate_class_name(class_name);
      break;
   case "mono":
      class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_class);
      class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_package);
      break;
   case "gdb":
   case "lldb":
   case "windbg":
      // translate single ':' (inner class seperator) with '::'
      class_name=stranslate(class_name,'!!','::');
      class_name=stranslate(class_name,'!!',VS_TAGSEPARATOR_class);
      class_name=stranslate(class_name,'::','!!');
      class_name=stranslate(class_name,'::',VS_TAGSEPARATOR_package);
      break;
   default:
      class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_package);
      class_name=stranslate(class_name,'.',VS_TAGSEPARATOR_class);
      break;
   }
}

/**
 * Get current function name and class name using Context Tagging&reg;
 * for use by debugger.  Does a slightly fuzzy match, checking if
 * we are in a function on the current line either at the beginning
 * or end of the line, not just the current cursor positoin
 */
int debug_get_current_context(_str &cur_context,
                              _str &cur_tag_name,
                              _str &cur_type_name)
{
   // probe for whether we can set a breakpoint here or not
   // Make sure the current context is up-to-date
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   save_pos(auto p);
   _UpdateContext(true);
   _UpdateLocals(true);

   // get the name of the current class and method
   struct VS_TAG_RETURN_TYPE visited:[];
   cur_flags:=SE_TAG_FLAG_NULL;
   cur_type_id:=SE_TAG_TYPE_NULL;
   _str cur_class;
   _str cur_package;
   int status=tag_get_current_context(cur_tag_name,cur_flags,
                                      cur_type_name,cur_type_id,
                                      cur_context,cur_class,cur_package,
                                      visited, 1);
   if (status < 0) {
      return(status);
   }

   // try beginning of line
   if (!tag_tree_type_is_func(cur_type_name) || cur_tag_name=='') {
      _begin_line();
      status=tag_get_current_context(cur_tag_name,cur_flags,
                                     cur_type_name,cur_type_id,
                                     cur_context,cur_class,cur_package,
                                     visited, 1);
   }

   // try end of line
   if (!tag_tree_type_is_func(cur_type_name) || cur_tag_name=='') {
      _end_line();
      status=tag_get_current_context(cur_tag_name,cur_flags,
                                     cur_type_name,cur_type_id,
                                     cur_context,cur_class,cur_package,
                                     visited, 1);
   }
   if (status < 0) {
      restore_pos(p);
      return(status);
   }

   // if this looks like a Slick-C event function, 
   // attempt to determine what event table we are in
   if (p_LangId == 'e' && pos('.', cur_tag_name)) {
      save_pos(auto p0);
      save_search(auto p1,auto p2,auto p3,auto p4);
      if (!search('^ *defeventtab +{:v}','@-rh')) {
         eventtab_name := get_match_text(0);
         if (eventtab_name != "") {
            cur_tag_name = eventtab_name"."cur_tag_name;
         }
      }
      restore_search(p1,p2,p3,p4);
      restore_pos(p0);
   }

   // get the name of the current class and method
   int local_id=tag_current_local();
   if (local_id > 0) {
      bool locals_visited:[];
      local_tag_name := "";
      local_type_name := "";
      local_class_name := "";
      while (local_id > 0) {
         locals_visited:[local_id] = true;
         tag_get_detail2(VS_TAGDETAIL_local_name,local_id,local_tag_name);
         tag_get_detail2(VS_TAGDETAIL_local_type,local_id,local_type_name);
         tag_get_detail2(VS_TAGDETAIL_local_class,local_id,local_class_name);
         if (tag_tree_type_is_func(local_type_name)) {
            break;
         }
         orig_local_id := local_id;
         tag_get_detail2(VS_TAGDETAIL_local_outer,orig_local_id,local_id);
         if (local_id == orig_local_id) break;
         if (locals_visited._indexin(local_id)) break;
      }

      // try beginning of line
      if (tag_tree_type_is_func(local_type_name)) {
         cur_tag_name=local_tag_name;
         cur_type_name=local_type_name;
         tag_get_detail2(VS_TAGDETAIL_context_class,status,cur_context);
         cur_context :+= ":1:":+local_class_name;
      }
   }

   // that's all folks
   restore_pos(p);
   return(status);
}

/**
 * @return Return the instruction address for the line under
 * the cursor if we are sitting on a disassembly line.
 * <p>
 * The current object is expected to be an editor control.
 */
_str debug_get_disassembly_address()
{
   // Are we in disassembly?
   if (_isEditorCtl() && (_lineflags() & NOSAVE_LF)) {
      address := "";
      line := "";
      get_line(line);
      parse line with address .;
      if (pos('0x',address) == 1) {
         return address;
      }
   }
   return null;
}

/**
 * Attempt to find a breakpoint at the current line
 * Check if there is a breakpoint at the current line in the
 * current file, compensating for the possibility that a breakpoint
 * may move when it is set.
 *
 * return breakpoint ID if match is found, 0 if error probing, <0 if not found
 */
static int debug_find_and_probe_breakpoint(bool &enabled, int &line_number, _str &address)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   status := 0;
   enabled=false;
   line_number=p_RLine;
   address = debug_get_disassembly_address();

   // we can't set a breakpoint in an unnamed file
   if (p_buf_name=='') {
      debug_message("Breakpoints are not allowed in an unnamed file.");
      return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
   }

   // check that tagging is supported in this file (should be a source file)
   if (!_isdebugging_supported(strict:false)) {
      debug_message("Breakpoints are not allowed in files that are not source files.");
      return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
   }

   // attempt to find a matching breakpoint
   int breakpoint_id=dbg_find_breakpoint(p_buf_name,p_RLine,enabled,0,address);
   if (breakpoint_id < 0) {

      // probe for whether we can set a breakpoint here or not
      _str cur_tag_name;
      _str cur_context;
      _str cur_type_name;
      status=debug_get_current_context(cur_context,cur_tag_name,cur_type_name);
      if (status < 0) {
         debug_message("Could not get current context",status);
         return(status);
      }

      //// is the current line on a function or procedure
      //if (!tag_tree_type_is_func(cur_type_name) || cur_tag_name=='') {
      //   if( _LanguageInheritsFrom("html") ) {
      //      // Let-it-slide cases: 
      //      //   phpscript embedded in PHP
      //      //   java embedded in JSP
      //      _str embeddedLang = _GetEmbeddedLangId();
      //      if( embeddedLang != "java" && embeddedLang != "phpscript" ) {
      //         debug_message("Not in a function",DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
      //         return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
      //      }
      //   } else {
      //      // Pure PHP script (i.e. not embedded in HTML)?
      //      // Python?
      //      if( !_LanguageInheritsFrom("phpscript") &&
      //          !_LanguageInheritsFrom("py") &&
      //          !_LanguageInheritsFrom("pl") &&
      //          !_LanguageInheritsFrom("ruby") ) {
      //         debug_message("Not in a function",DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
      //         return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
      //      }
      //   }
      //}

      // no probing going on if we debug isn't active
      line_number=p_RLine;
      if (debug_active()) {
         // is there a probe callback?
         session_id := dbg_get_current_session();
         if (dbg_session_is_name_implemented(session_id, "probe_breakpoint")) {
            line_number = dbg_session_probe_breakpoint(session_id,
                                                       cur_context, cur_tag_name, 
                                                       p_buf_name, p_RLine);
            //say("debug_find_and_probe_breakpoint: probe result="line_number);
            if (line_number==DEBUG_CLASS_NOT_FOUND_RC) {
               if (dbg_get_callback_name(session_id) == 'gdb') {
                  cur_context=stranslate(cur_context,'::',VS_TAGSEPARATOR_package);
               } else {
                  cur_context=stranslate(cur_context,'.',VS_TAGSEPARATOR_package);
               }
               message(nls("Class \"%s\" is not loaded.  Setting deferred breakpoint",cur_context));
               line_number=p_RLine;
            }
         }
      }
      if (line_number < 0) {
         debug_message("Unable to set breakpoint at this location",line_number);
         return(DEBUG_BREAKPOINT_LINE_NOT_FOUND_RC);
      }

      // try to find the breakpoint on the new line
      if (line_number != p_RLine) {
         breakpoint_id=dbg_find_breakpoint(p_buf_name,line_number,enabled,0,null);
      }
   }
   //say("debug_find_and_probe_breakpoint: breakpoint="breakpoint_id);
   return breakpoint_id;
}

/**
 * Add a breakpoint at the location that the cursor is at in the
 * current editor control.  The current object must be an editor control.
 *
 * @param temporary  Is this a temporary breakpoint?
 *
 * @return breakpoint ID >0 on success, <0 on error.
 */
static int debug_add_breakpoint_at(bool temporary, int line_number=0, _str address='')
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!line_number) line_number=p_RLine;

   if (debug_active() && gSuspended && false) {
      // get the current thread id and frame ID
      // only if suspended
      // (we don't need to do this at all, actually)
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);

      // get the thread name
      _str thread_name,thread_group;
      thread_flags := 0;
      int status=dbg_get_thread(thread_id,thread_name,thread_group,thread_flags);
      if (status) {
         return(status);
      }

      // get the class, method, etc.
      _str method_name,signature,return_type,class_name;
      _str file_name;
      line_number=0;
      status=dbg_get_frame(thread_id,frame_id,
                           method_name,signature,return_type,class_name,
                           file_name,line_number,address);
      if (status) {
         return(status);
      }
   }

   // get the name of the current class and method

   // probe for whether we can set a breakpoint here or not
   _str cur_tag_name;
   _str cur_context;
   _str cur_type_name;
   int status=debug_get_current_context(cur_context,cur_tag_name,cur_type_name);
   if (status < 0) {
      return(status);
   }

   //// is the current line on a function or procedure
   //if (!tag_tree_type_is_func(cur_type_name) || cur_tag_name=='') {
   //   if( _LanguageInheritsFrom("html") ) {
   //      // Let-it-slide cases: 
   //      //   phpscript embedded in PHP
   //      //   java embedded in JSP
   //      _str embeddedLang = _GetEmbeddedLangId();
   //      if( embeddedLang != "java" && embeddedLang != "phpscript" ) {
   //         return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
   //      }
   //   } else {
   //      // Pure PHP script (i.e. not embedded in HTML)?
   //      // Python?
   //      if( !_LanguageInheritsFrom("phpscript") &&
   //          !_LanguageInheritsFrom("py") &&
   //          !_LanguageInheritsFrom("pl") &&
   //          !_LanguageInheritsFrom("ruby") ) {
   //         return(DEBUG_BREAKPOINT_NOT_ALLOWED_RC);
   //      }
   //   }
   //}

   // add the breakpoint to the list of breakpoints (disabled)
   int count=(temporary? -1:0);
   debug_translate_class_name(cur_context);
   int breakpoint_id=dbg_add_breakpoint(count, null, null/*thread_group'.'thread_name*/,
                                        cur_context,cur_tag_name,
                                        p_buf_name, line_number, address,
                                        VSDEBUG_BREAKPOINT_LINE, 0);
   if (breakpoint_id < 0) {
      return(breakpoint_id);
   }

   // that's all folks
   return(breakpoint_id);
}

/**
 * Attempt to enable breakpoints set from the previous debugging session.
 */
static int debug_enable_all_breakpoints(_str class_name,bool quiet=false,_str suspend_msg='')
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("debug_enable_all_breakpoints: CLASS_NAME="class_name);
   got_one := false;
   bp_class := bp_method := "";
   debug_translate_class_name(class_name);
   _str error_class=class_name;
   p := pos("[.][0-9]",class_name,1,'r');
   if (p > 0) class_name = substr(class_name,1,p);
   result := 0;
   int i,n=dbg_get_num_breakpoints();
   for (i=1; i<=n; ++i) {
      int enabled=dbg_get_breakpoint_enabled(i);
      if (enabled <= 0 || enabled==2) {
         continue;
      }
      int status=dbg_get_breakpoint_scope(i,bp_class,bp_method);
      simplified_bp_class := stranslate(bp_class, "/",  ".");
      simplified_bp_class = stranslate(simplified_bp_class, "/",  "::");
      simplified_bp_class = stranslate(simplified_bp_class, "/",  ":");
      simplified_class_name := stranslate(class_name, "/",  ".");
      simplified_class_name = stranslate(simplified_class_name, "/",  "::");
      simplified_class_name = stranslate(simplified_class_name, "/",  ":");
      if (status < 0 || (class_name!="" && pos(simplified_class_name, simplified_bp_class) != 1)) {
         continue;
      }
      status=dbg_set_breakpoint_enabled(i,0);
      if (status < 0) {
         result=status;
         continue;
      }
      status=debug_pkg_enable_breakpoint(i,true);
      if (status) {
         error_class=bp_class;
         result=status;
      } else {
         got_one=true;
      }
   }
   if (got_one) {
      debug_gui_update_breakpoints(true);

      // update the debugger, in case if we hit the breakpoint right away
      if (debug_active()) {
         mou_hour_glass(true);
         debug_force_update_after_step_or_continue();
         mou_hour_glass(false);
      }
   }
   if (result) {
      if (quiet) return(result);
      debug_message(nls("One or more breakpoints set in class \"%s\" are no longer valid.%s",
                        error_class,suspend_msg));
      debug_gui_update_breakpoints(true);
      return(result);
   }
   return(0);
}

/**
 * Attempt to enable exceptions set from the previous debugging session.
 */
static int debug_enable_all_exceptions(_str class_name,bool quiet=false,_str suspend_msg='')
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //say("debug_enable_all_exceptions: CLASS_NAME="class_name);
   got_one := false;
   bp_class := bp_method := "";
   debug_translate_class_name(class_name);
   _str error_class=class_name;
   p := pos("[.][0-9]",class_name,1,'r');
   if (p > 0) class_name = substr(class_name,1,p);
   result := 0;
   int i,n=dbg_get_num_exceptions();
   for (i=1; i<=n; ++i) {
      int enabled=dbg_get_exception_enabled(i);
      if (enabled <= 0 || enabled==2) {
         continue;
      }
      int status=dbg_get_exception_class(i,bp_class);
      if (status < 0 || (class_name!='' && pos(class_name, bp_class) != 1)) {
         continue;
      }
      status=dbg_set_exception_enabled(i,0);
      if (status < 0) {
         result=status;
         continue;
      }
      status=debug_pkg_enable_exception(i);
      if (status) {
         error_class=bp_class;
         result=status;
      } else {
         got_one=true;
      }
   }
   if (got_one) {
      debug_gui_update_exceptions(true);
   }
   if (result) {
      if (quiet) return(result);
      debug_message(nls("Exception class \"%s\" is no longer valid.%s",
                        error_class,suspend_msg));
      debug_gui_update_exceptions(true);
      return(result);
   }
   return(0);
}

/**
 * Return 'this' if we are in a class method and should include that in Autos. 
 */
static _str debug_maybe_add_this()
{
   // figure out what the 'this' variable is named
   this_name := "this";
   if (_LanguageInheritsFrom("m"))   this_name = "self";
   if (_LanguageInheritsFrom("bas")) this_name = "This";
   if (_LanguageInheritsFrom("py"))  this_name = "self";

   // check that this is a supported language
   if (!_LanguageInheritsFrom("c") &&
       !_LanguageInheritsFrom("m") &&
       !_LanguageInheritsFrom("ansic") &&
       !_LanguageInheritsFrom("d") &&
       !_LanguageInheritsFrom("googlego") &&
       !_LanguageInheritsFrom("java") &&
       !_LanguageInheritsFrom("js") &&
       !_LanguageInheritsFrom("bas") &&
       !_LanguageInheritsFrom("py") &&
       !_LanguageInheritsFrom("cs")) {
      return "";
   }

   // get the current class and current package from the context
   struct VS_TAG_RETURN_TYPE visited:[];
   context_id := tag_get_current_context(auto cur_tag_name, auto cur_tag_flags,
                                         auto cur_type_name, auto cur_type_id,
                                         auto cur_class_name, auto cur_class_only,
                                         auto cur_package_name,
                                         visited, 1);
   if (context_id <= 0) return "";

   // make sure we have are in a class context
   if (cur_class_name == '') return "";

   // make sure we are not in a static function
   if (cur_tag_flags & SE_TAG_FLAG_STATIC) return "";

   // not a function or proc, not a static method, in a class method
   if (!tag_tree_type_is_func(cur_type_name) || cur_type_name :== 'proto') {
      return "";
   }

   // not really a class method, just a member of a package
   lang := _isEditorCtl()? p_LangId : "";
   tag_files := tags_filenamea(lang);
   inner_name := outer_name := "";
   tag_split_class_name(cur_class_name, inner_name, outer_name);
   if (tag_check_for_package(inner_name, tag_files, true, p_LangCaseSensitive, null, visited, 1)) {
      return "";
   }

   // add the item to the tree
   return this_name;
}

/**
 * Find the auto variables for the current line context
 */
int debug_find_autovars(int thread_id, int frame_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // already have them computed, don't do it again!
   if (dbg_have_autovars(thread_id,frame_id)) {
      return(0);
   }

   // clear the existing autovars list
   int status=dbg_clear_autos(thread_id,frame_id);
   if (status) {
      return(status);
   }

   // get the information about the current frame
   file_name := "";
   line_number := 0;
   status=dbg_get_frame_path(thread_id,frame_id,file_name,line_number);
   if (status) {
      return(status);
   }

   // they don't want any autos
   if (def_debug_auto_lines <= 0) {
      return(0);
   }

   // set the start and end points
   int start_linenum=line_number-def_debug_auto_lines+1;
   int end_linenum=line_number;

   // open a temp view
   int temp_view_id,orig_view_id;
   status=_open_temp_view(file_name,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }

   // save the last search options
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

   // move to beginning of identified function
   p_RLine=line_number;
   _begin_line();
   _first_non_blank();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(true);

   // get the current context, and verify start/end line numbers
   _UpdateContextAndTokens(true);
   context_id := tag_current_context();
   if (context_id > 0) {
      int context_start_linenum,context_end_linenum;
      tag_get_detail2(VS_TAGDETAIL_context_start_linenum,context_id,context_start_linenum);
      tag_get_detail2(VS_TAGDETAIL_context_end_linenum,context_id,context_end_linenum);
      if (start_linenum < context_start_linenum && context_start_linenum <= end_linenum) {
         start_linenum=context_start_linenum;
      }
      if (start_linenum <= context_end_linenum && context_end_linenum < end_linenum) {
         end_linenum=context_end_linenum;
      }
   }

   // hash table to keep track of what we've seen already
   int already_found:[]; already_found._makeempty();

   // now search, with options:
   // and add in 'this' if so.
   this_name := debug_maybe_add_this();
   if (this_name != "") {
      already_found:[this_name]=1;
      dbg_add_autovar(thread_id,frame_id,this_name);
   }

   // move to starting point for search
   if (start_linenum != line_number) {
      p_RLine=start_linenum;
      _begin_line();
      _first_non_blank();
   }

   // now search, with options:
   //    @       quiet
   //    >       position cursor after match
   //    i       case insensitive
   //    r       regular expression search
   //    X       EXCLUDE COLOR CODING
   //       c    // comments
   //       n    // numbers
   //       k    // keywords
   //       a    // HTML attributes
   //       p    // preprocessing
   //       l    // line numbers
   //       s    // strings
   //    w=      Word match, with specified word chars
   //
   struct VS_TAG_RETURN_TYPE visited:[];
   _str k=(_LanguageInheritsFrom('e')? '':'k');
   o2 := "";
   if( _LanguageInheritsFrom("phpscript") || 
       (_LanguageInheritsFrom("html") && _GetEmbeddedLangId() == "phpscript") ) {

      // Some PHP library functions can be called without parentheses (echo, exit),
      // so we must skip those too.
      o2 = '2';  // Note: '2'=lib symbols
   }
   word_chars := _clex_identifier_chars();
   srch_opts  := '@>irhXcn'k'apls'o2'w=['word_chars']';
   status=search('['word_chars']#',srch_opts);

   // now search
   result := 0;
   while (status==0) {

      // check if we have went past last line
      if (p_RLine > end_linenum) {
         break;
      }

      // get the word match
      word_len := match_length('');
      word_pos := match_length('S');
      word := get_text(word_len,word_pos);

      // check if it is a property name, skip any other keyword
      left();
      if (_clex_find(0,'g')==CFG_KEYWORD && substr(word,1,2)!="p_") {
         word = "";
      }
      right();

      // now handle it
      if (word != '' ) {
         ext := "";

         typeless r1,r2,r3,r4,r5;
         save_search(r1,r2,r3,r4,r5);

         VS_TAG_IDEXP_INFO idexp_info;
         tag_idexp_info_init(idexp_info);
         status=_Embeddedget_expression_info(false, ext, idexp_info, visited);
  
         restore_search(r1,r2,r3,r4,r5);

         // peel 'new ' off of the prefix expression
         // and since this is a constructor, ignore followed by paren.
         if (!status && substr(idexp_info.prefixexp,1,4)=='new ') {
            idexp_info.prefixexp=substr(idexp_info.prefixexp,5);
            idexp_info.info_flags &= ~VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN;
         }
         // skip function calls, operators
         if (!status && 
             (!(idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) || (idexp_info.info_flags & VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST)) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_THROW_STATEMENT) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_JAVADOC_COMMENT) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_STRING_OR_NUMBER) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_IMPORT_STATEMENT) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_HAS_CLASS_SPECIFIER) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_CPP_OPERATOR) &&
             !(idexp_info.info_flags & VSAUTOCODEINFO_IN_PREPROCESSING_ARGS)
             ) {
            if ((idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET) &&
                !(idexp_info.info_flags & VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL) &&  
                (idexp_info.otherinfo!="")) {
               idexp_info.lastid=idexp_info.lastid:+'[':+idexp_info.otherinfo']';
            }

            // For struct access with array expressions on the lhs of the '.', 
            // _c_get_expression_info does not return the indexes in
            // in the prefixexp. Extract real expression text from buffer in that case.
            if (_LanguageInheritsFrom("c") && pos("[]", idexp_info.prefixexp)) {
               idexp_info.prefixexp = get_text_safe(idexp_info.lastidstart_offset - idexp_info.prefixexpstart_offset, idexp_info.prefixexpstart_offset);
            }

            skip_symbol := false;
            _UpdateLocals(true);
            status = _Embeddedfind_context_tags(idexp_info.errorArgs,
                                                idexp_info.prefixexp,idexp_info.lastid,
                                                idexp_info.lastidstart_offset,
                                                idexp_info.info_flags,
                                                idexp_info.otherinfo,
                                                false,10,
                                                true,p_LangCaseSensitive);
            if (status >= 0 && tag_get_num_of_matches() > 0) {
               skip_symbol = true;
               for (i:=1; i<=tag_get_num_of_matches(); i++) {
                  tag_get_match_browse_info(i, auto cm);
                  // make sure we aren't mousing over a class name or other symbol
                  // the debugger will not be able to evaluate
                  if (!(tag_tree_type_is_class(cm.type_name) || 
                        tag_tree_type_is_package(cm.type_name) || 
                        tag_tree_type_is_func(cm.type_name) ||
                        cm.type_name == 'typedef' || cm.type_name=='enum' ||
                        cm.type_name == 'import'  || cm.type_name=='include')) {
                     skip_symbol = false;
                     break;
                  }
               }
            }

            // do not add things like "int" or "char"
            if (do_default_is_builtin_type(idexp_info.lastid)) {
               skip_symbol = true;
            }

            if (!skip_symbol) {
               autovar_expression :=  idexp_info.prefixexp:+idexp_info.lastid;
               autovar_expression = stranslate(autovar_expression, "", "++");
               autovar_expression = stranslate(autovar_expression, "", "--");
               if (!already_found._indexin(autovar_expression)) {
                  already_found:[autovar_expression]=1;
                  dbg_add_autovar(thread_id,frame_id,autovar_expression);
               }
            }
         }

         if (status) {
            result = status;
         }
      }

      // next please...
      status = repeat_search(srch_opts);
   }

   // restore position and search options
   restore_search(s1,s2,s3,s4,s5);

   // close the temporary view
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   // that's all folks
   return(result);
}

/**
 * Modify the menu captions or button help messages depending
 * on whether we are in debug mode or not.
 *
 * @param cmdui         Command UI controls
 * @param command       command to execute when in debug mode
 * @param debug_caption Caption / help message to use when in debug mode
 * @param debug_label   Menu label when in debug mode
 * @param other_caption Caption / message to use when not debugging
 * @param other_label   Menu label when not debugging
 */
void debug_modify_captions(
      CMDUI &cmdui, _str command,
      _str debug_caption, _str debug_label,
      _str other_caption, _str other_label)
{
   // if this is a button, update the caption
   int button_wid=cmdui.button_wid;
   if (button_wid) {
      if (debug_active()) {
         button_wid.p_message=debug_caption;
         button_wid.p_command=command;
      } else {
         button_wid.p_message=other_caption;
         button_wid.p_command=command;
      }
   }
   // if for a menu item, update the caption and shortcut key name
   int menu_handle=cmdui.menu_handle;
   if (cmdui.menu_handle) {
      int flags;
      new_text := key_name := orig_help_string := "";
      typeless junk;

      _menu_get_state(menu_handle,cmdui.menu_pos,flags,'P',new_text,junk,junk,junk,orig_help_string);
      parse new_text with \t key_name;
      if(debug_active()) {
         _menu_set_state(menu_handle,
                         cmdui.menu_pos,flags,'p',
                         debug_label:+"\t":+key_name,
                         command,'','',debug_caption);
      } else {
         _menu_set_state(menu_handle,
                         cmdui.menu_pos,flags,'p',
                         other_label:+"\t":+key_name,
                         command,'','',other_caption);
      }
   }
}

/**
 * Display a status message from the debugger.
 */
void debug_message(_str header, int status=0, bool modal=true)
{
   orig_wid := _get_focus();
   _str msg = nls(header);
   if (status) {
      msg :+= ":  "get_message(status);
   }
   if (status < 0) {
      _str system_msg=debug_pkg_error_message();
      if (system_msg!='') {
         msg :+= (modal)? "\n\n" : "<p>";
         msg :+= "\"" system_msg "\"";
         if (upcase(machine():+machine_bits())=="WINDOWS64" && 
             pos("not in executable format", system_msg) > 0 &&
             pos("File format not recognized", system_msg) > 0) {
            msg :+= (modal)? "\n\n" : "<p>";
            msg :+= "The supplied gdb is built for debugging 64-bit programs only. ":+
                    "You may need to configure a different version of GDB to debug 32-bit ":+
                    "programs by going to Debug > Debugger Options... > Configurations";
         }
      }
   }
   if (modal) {
      clear_message();
      _message_box(msg);
      if (orig_wid) {
         orig_wid._set_focus();
      }
   } else {
      notifyUserOfWarning(ALERT_DEBUGGER_ERROR, msg, "");
   }
}

/**
 * If we are logging debug info, logs info in the debugger log,
 * found in configDir\logs\debug.log.  Can force the log, even
 * if def_debug_logging is turned off.
 *
 * @param text             text to add to log
 * @param force            true to force this message to be
 *                         written to the log, regardless of
 *                         def_debug_logging value
 */
void debug_log(_str text, bool force = false)
{
   if (force || def_debug_logging) {
      dsay(text, VSDEBUG_LOG);
   }
}

/**
 * Polls until the last process buffer command is processed.
 */
void loop_until_on_last_process_buffer_command(_str idname='')
{
   if ( !_process_info() ) {
      return;
   }
   orig_wid := p_window_id;
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(_process_buffer_name(idname),temp_view_id,orig_view_id,'+b');
   if (!status) {
      int timeout=def_debug_timeout;
      if (timeout>60) timeout=59;
      _str start_mm,start_ss;
      parse _time("M") with . ":" start_mm ":" start_ss;
      for (;;) {
         if ( ! _process_info('R',idname) ) {
            break;
         }
         bottom();
         int col=_process_info('c');
         if (col) {
            break;
         }
         _str mm,ss;
         parse _time("M") with . ":" mm ":" ss;
         if (ss<start_ss || start_mm!=mm) ss=((int)ss)+60;
         if (((int)ss)-((int)start_ss)>timeout) {
            // This may not be reallistically possible to happen.
            break;
         }
      }
      _delete_temp_view(temp_view_id,false);
      p_window_id=orig_wid;
   }
}

/**
 * @return Returns true if debugging is supported for 
 * source files of this language.
 *
 * @param lang       (optional) language id to check 
 * @param strict     (optional) if false, let a breakpoint be set in 
 *                   any file that supports tagging 
 */
bool _isdebugging_supported(_str lang=null, bool strict=true)
{
   if (!_haveDebugging() || DllIsMissing("vsdebug.dll")) {
      return false;
   }
   if (lang==null) {
      if (!_isEditorCtl()) {
         return false;
      }
      lang = _GetEmbeddedLangId();
   }
   if (isEclipsePlugin()) {
      return(_LanguageInheritsFrom('c', lang) || _LanguageInheritsFrom('java'));
   }
   if (lang == 'e') { // Slick-C
      return true;
   }

   // if debugging is not active, relax the requirement to the bare minimum.
   if (!debug_active() && !strict) {
      return _istagging_supported(lang);
   }

   // these really should be callbacks, but for now...
   session_id := dbg_get_current_session();
   switch (dbg_get_callback_name(session_id)) {
   case 'dap':
      return (_LanguageInheritsFrom('py', lang));

   case 'gdb':
   case 'lldb':
      // GDB works with other languages, and we only support C and C++
      // but we can let them try to set breakpoints in those languages anyway
      return(_LanguageInheritsFrom('c', lang) || 
             _LanguageInheritsFrom('d', lang) || 
             _LanguageInheritsFrom('googlego', lang) || 
             _LanguageInheritsFrom('f', lang) || 
             _LanguageInheritsFrom('for', lang) || 
             _LanguageInheritsFrom('s', lang) || 
             _LanguageInheritsFrom('swift', lang) || 
             _LanguageInheritsFrom('ch', lang) || 
             _LanguageInheritsFrom('java', lang) || 
             _LanguageInheritsFrom('asm', lang) || 
             _LanguageInheritsFrom('unixasm', lang) || 
             _LanguageInheritsFrom('mod', lang) || 
             _LanguageInheritsFrom('ada', lang) || 
             _LanguageInheritsFrom('rs', lang) || 
             _LanguageInheritsFrom('pas'));
   case 'windbg':
      return(_LanguageInheritsFrom('c', lang) ||
             _LanguageInheritsFrom('cs', lang) ||
             _LanguageInheritsFrom('jsl', lang) ||
             _LanguageInheritsFrom('bas', lang) ||
             _LanguageInheritsFrom('for', lang) ||
             _LanguageInheritsFrom('pas', lang) ||
             _LanguageInheritsFrom('ada', lang) ||
             _LanguageInheritsFrom('rs', lang) ||
             _LanguageInheritsFrom('asm', lang) || 
             _LanguageInheritsFrom('vb', lang));
   case 'jdwp':
      // this should work also for java embedded in HTML
      return(_LanguageInheritsFrom("java",lang) ||
             _LanguageInheritsFrom("groovy", lang) ||
             _LanguageInheritsFrom("clojure", lang) ||
             _LanguageInheritsFrom("js", lang) ||
             _LanguageInheritsFrom("e", lang) ||
             _LanguageInheritsFrom("kotlin", lang) ||
             _LanguageInheritsFrom("py", lang) ||
             _LanguageInheritsFrom("ruby", lang) ||
             _LanguageInheritsFrom('c', lang));
   case 'mono':
      return(_LanguageInheritsFrom("cs",lang) ||
             _LanguageInheritsFrom("vb", lang) ||
             _LanguageInheritsFrom("bas", lang) ||
             _LanguageInheritsFrom("jsl", lang) ||
             _LanguageInheritsFrom("fsharp", lang));
   case 'xdebug':
      return ( lang == 'phpscript' );
   case 'pydbgp':
      return ( lang == 'py' );
   case 'perl5db':
      return ( lang == 'pl' );
   case 'rdbgp':
      return ( lang == 'ruby' );
   case 'scaladbgp':
      return (lang == 'scala');
   default:
      // not a system we know about, revert to if taggable
      return _istagging_supported(lang);
   }
}


///////////////////////////////////////////////////////////////////////////
// Functions for managing the debugger timer
//

/**
 * Function called from timer to update the debugger state.
 */
static void debug_timer_callback()
{
   // kill the timer
   if (gDebuggerTimerId != -1) {
      _kill_timer(gDebuggerTimerId);
      gDebuggerTimerId=-1;
   }

   // update the debugger views
   if (!_haveDebugging()) return;
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   debug_gui_update_all(thread_id,frame_id);
}
/**
 * Kill the existing symbol browser update timer
 */
static void debug_kill_timer()
{
   if (gDebuggerTimerId != -1) {
      _kill_timer(gDebuggerTimerId);
      gDebuggerTimerId=-1;
   }
}
/**
 * Initiate a new debugger timer callback.
 */
static void debug_start_timer()
{
   // kill any pending update
   if (gDebuggerTimerId != -1) {
      _kill_timer(gDebuggerTimerId);
      gDebuggerTimerId=-1;
   }

   // if timer callback is zero, just call the function
   if (def_debug_timer_delay <= 0) {
      debug_timer_callback();
      return;
   }

   // otherwise, create a timer event
   gDebuggerTimerId=_set_timer(def_debug_timer_delay, debug_timer_callback);
}


///////////////////////////////////////////////////////////////////////////
// auto-save timer hook
//

/**
 * Update the debugger session when we catch incoming events.
 *
 * @param session_id       ID of session to make current
 * @param AlwaysUpdate     do it right now, or wait a tenth second?
 * @param switchSession    breakpoint or step done, switch to this session
 * 
 * @return 0 on success, <0 on error
 */
static int debug_session_update_debugger(int session_id,
                                         _str &event_kind,
                                         int &event_flags,
                                         int &event_thread,
                                         _str &event_class,
                                         int &breakpoint_id,
                                         bool alwaysUpdate,
                                         bool &switchSession,
                                         bool &doRefresh,
                                         bool &updateDebugGUI,
                                         bool &updateThreads,
                                         bool &updateClasses,
                                         bool &updateExceptions,
                                         bool &showingLoadingMessage,
                                         bool &showNextStatement)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // make the requested session active
   int orig_session = dbg_set_current_session(session_id);
   if (orig_session < 0) {
      return orig_session;
   }
   if (session_id != orig_session) {
      debug_log("selecting session: "session_id" name="dbg_get_session_name(session_id));
   }

   // handle events until we run out of them
   long orig_time=(long)_time('B');
   orig_suspended := gSuspended;
   doContinue := false;
   doNotContinue := false;
   showLoading := false;
   while (1) {

      //if (_IsKeyPending(true)) {
      //   say("debug_session_update_debugger: KEY PENDING!!");
      //   break;
      //}

      event_kind='';
      event_class='';
      event_flags=0;
      event_thread=0;
      breakpoint_id=0;

      int status = dbg_session_handle_event(session_id,
                                            event_kind, event_flags,
                                            event_thread, event_class,
                                            breakpoint_id);
      if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
         dbg_set_current_session(orig_session);
         return status;
      }
      if (event_kind != "") {
         debug_log("_UpdateDebugger: status="status" event="event_kind" flags="event_flags" thread="event_thread" time="_time('B')" mtime="_time('M')" ELAPSED TIME="(long)_time('b')-orig_time);
      }
      if (status < 0 && event_flags==VSDEBUG_EVENT_STOP) {
         debug_message("Debugger stopped",status,false);
         showingLoadingMessage=false;
         debug_stop(true);
         refresh();
         return 0;
      }
      if (status) {
         if (!doContinue && !alwaysUpdate) {
            break;
         }
         long now_time=(long)_time('B');
         if (now_time-orig_time > def_debug_min_update_time) {
            break;
         }
         delay(5);
         debug_log("_UpdateDebugger: GET ANOTHER EVENT");
         continue;
      }
      //say("_UpdateDebugger: status="status" event="event_kind" flags="event_flags" thread="event_thread" time="_time('B')" mtime="_time('M')" ELAPSED TIME="(long)_time('b')-orig_time);
      if ((event_flags & VSDEBUG_EVENT_STOP) && event_kind=="signal") {
         debug_message("Exited on signal: ":+event_class);
         debug_stop(true);
         showingLoadingMessage=false;
         refresh();
         return 0;
      }
      //say("_UpdateDebugger: status="status" event="event_kind" flags="event_flags" thread="event_thread" time="_time('B')" mtime="_time('M')" ELAPSED TIME="(long)_time('b')-orig_time);
      if( (event_flags & VSDEBUG_EVENT_STOP) ||
          event_kind == "exit" ||
          event_kind == "exit_quiet" ) {
         debug_message("Debugger stopped",status,false);
         debug_stop(true);
         showingLoadingMessage=false;
         refresh();
         return 0;
      } else if (event_kind == 'vm_stop' || event_kind == 'vm_disconnect') {
         debug_message("Debugger stopped",status,true);
         debug_stop(true);
         showingLoadingMessage=false;
         refresh();
         return 0;
      } else if (event_kind == 'crash') {
         debug_message("Debuggee crashed",status,true);
         debug_stop(true);
         showingLoadingMessage=false;
         refresh();
         return 0;
      }
      // relay errors back to the status bar, but don't do anything else fancy with them
      if (event_kind=="error") {
         debug_message("Error: ":+event_class);
      }
      // relay message if we caught a signal or exception
      if (event_kind=="signal") {
         debug_message("Signal caught: ":+event_class, 0, false);
      }
      if (event_kind=="exception" && event_class!='') {
         event_extra := "";
         if (pos("ClassNotFoundException", event_class) ||
             pos("NoClassDefFoundError", event_class)) {
            event_extra="\n\n":+
                        "Verify that your project is built and up-to-date.\n":+
                        "Also check if you have your CLASSPATH set correctly.";
         }
         clear_message();
         event_class_name := "";
         parse event_class with event_class_name ":" .;
         enabled := 0;
         int exception_id=dbg_find_exception(event_class_name,enabled,0);
         if (exception_id > 0) {
            stop_when := 0;
            typeless d1,d2,d3,d4,d5;
            dbg_get_exception(exception_id,stop_when,d1,d2,d3,d4,d5);
            if (stop_when & VSDEBUG_EXCEPTION_STOP_WHEN_CAUGHT) {
               int choice=debug_exception_message("Exception caught: ":+event_class:+event_extra);
               if (choice > 0) {
                  if (choice==2) {
                     debug_pkg_disable_exception(exception_id);
                     updateExceptions=true;
                  }
                  doContinue=true;
               }
            }
         } else {
            debug_message("Exception caught: ":+event_class:+event_extra);
         }
      }
      // Did we exit the main function?
      if (event_kind=='exit_main') {
         debug_message("Program exited main function...finishing",0,false);
         continue;
      }
      if (event_kind=='class_prepare' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         //say("_UpdateDebugger: event_class="event_class);
         status=debug_enable_all_breakpoints(event_class,false,nls("\n\nThe breakpoint has been disabled and execution will be suspended immediately."));
         if (!status) {
            status=debug_enable_all_exceptions(event_class,false,nls("\n\nThe exception has been disabled and execution will be suspended immediately."));
         }
         if (status) {
            debug_check_and_set_suspended(false,false);
            event_flags |= VSDEBUG_EVENT_GOTOPC;
         } else {
            debug_pkg_continue();
            gSuspended=false;
            event_flags &= ~VSDEBUG_EVENT_SUSPEND_ALL;
         }
      }
      if (event_kind=='step_system' &&
          (event_flags & VSDEBUG_EVENT_SUSPEND_ALL) &&
          gInStepType==DEBUG_STEP_TYPE_INTO &&
          event_class!='' && dbg_is_runtime_expr(event_class)) {
         debug_pkg_step_out();
         event_flags &= ~VSDEBUG_EVENT_SUSPEND_ALL;
         gSuspended=false;
      }
      if (event_kind=='breakpoint' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
         // look up its breakpoint condition
         breakpoint_flags := 0;
         condition := "";
         status=dbg_get_breakpoint_condition(breakpoint_id,condition);
         switch (dbg_get_breakpoint_type(breakpoint_id, breakpoint_flags)) {
         case VSDEBUG_WATCHPOINT_ANY:
         case VSDEBUG_WATCHPOINT_READ:
         case VSDEBUG_WATCHPOINT_WRITE:
            condition='';
            break;
         }
         if (!status && condition!='') {
            // update the threads and stack frame
            status=debug_pkg_update_current_thread();
            if (!status) {
               status=debug_pkg_update_stack(event_thread);
               if (!status) {
                  frame_id := dbg_get_cur_frame(event_thread);
                  new_depth := dbg_get_num_frames(event_thread);
                  // evaluate the expression in the current thread and stack frame
                  status=debug_pkg_eval_condition(event_thread,frame_id,condition);
                  if (status < 0) {
                     debug_message(nls("Error evaluating conditional breakpoint expression (%s)",condition),status);
                     showingLoadingMessage=false;
                  } else if (status > 0) {
                     doNotContinue=true;
                  } else if (status==0) {
                     // condition failed, resume execution
                     // handle differently, depending on the step type
                     switch (gInStepType) {
                     case DEBUG_STEP_TYPE_INTO:
                     case DEBUG_STEP_TYPE_DEEP:
                     case DEBUG_STEP_TYPE_INST:
                        doNotContinue=true;
                        break;
                     case DEBUG_STEP_TYPE_OVER:
                        if (new_depth > gInStepDepth) {
                           doContinue=true;
                        } else {
                           doNotContinue=true;
                        }
                        break;
                     case DEBUG_STEP_TYPE_OUT:
                        if (new_depth >= gInStepDepth) {
                           doContinue=true;
                        } else {
                           doNotContinue=true;
                        }
                        break;
                     case DEBUG_STEP_TYPE_PAST:
                        if (new_depth >= gInStepDepth) {
                           doContinue=true;
                        } else {
                           doNotContinue=true;
                        }
                        if (new_depth==gInStepDepth) {
                           int j,m=dbg_get_num_breakpoints();
                           for (j=1; j<=m; ++j) {
                              if (dbg_get_breakpoint_count(j)==-1) {
                                 _str bp_file_name,ev_file_name;
                                 int  bp_line_number,ev_line_number;
                                 dbg_get_breakpoint_location(j,bp_file_name,bp_line_number);
                                 dbg_get_breakpoint_location(breakpoint_id,ev_file_name,ev_line_number);
                                 if (bp_line_number==ev_line_number) {
                                    doNotContinue=true;
                                 }
                              }
                           }
                        }
                        break;
                     case DEBUG_STEP_TYPE_NONE:
                     default:
                        doContinue=true;
                        break;
                     }
                  }
               }
            }
         }
      }
      if (event_kind=='signal' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
      }
      if (event_kind=='watchpoint' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
      }
      if (event_kind=='watchpoint-read' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
      }
      if (event_kind=='watchpoint-write' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
      }
      if (event_kind=='watchpoint-disabled') {
         // thread states need updating
         updateThreads=true;
         status = dbg_set_breakpoint_enabled(breakpoint_id, 0);
         if (!status) {
            _str watchpoint_expr;
            dbg_get_breakpoint_condition(breakpoint_id,watchpoint_expr);
            debug_message(nls("Watchpoint '%s' went out of scope and has been disabled",watchpoint_expr));
         }
      }
      if (event_kind=='exception' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         // thread states need updating
         updateThreads=true;
         // look up its exception condition
         condition := "";
         status=dbg_get_exception_condition(breakpoint_id,condition);
         if (!status && condition!='') {
            // update the threads and stack frame
            status=debug_pkg_update_current_thread();
            if (!status) {
               status=debug_pkg_update_stack(event_thread);
               if (!status) {
                  frame_id := dbg_get_cur_frame(event_thread);
                  new_depth := dbg_get_num_frames(event_thread);
                  // evaluate the expression in the current thread and stack frame
                  status=debug_pkg_eval_condition(event_thread,frame_id,condition);
                  if (status < 0) {
                     debug_message(nls("Error evaluating conditional expression (%s)",condition),status);
                     showingLoadingMessage=false;
                  } else if (status > 0) {
                     doNotContinue=true;
                  } else if (status==0) {
                     // condition failed, resume execution
                     // handle differently, depending on the step type
                     switch (gInStepType) {
                     case DEBUG_STEP_TYPE_INTO:
                     case DEBUG_STEP_TYPE_DEEP:
                     case DEBUG_STEP_TYPE_INST:
                        doNotContinue=true;
                        break;
                     case DEBUG_STEP_TYPE_OVER:
                        if (new_depth > gInStepDepth) {
                           doContinue=true;
                        } else {
                           doNotContinue=true;
                        }
                        break;
                     case DEBUG_STEP_TYPE_OUT:
                        if (new_depth >= gInStepDepth) {
                           doContinue=true;
                        } else {
                           doNotContinue=true;
                        }
                        break;
                     case DEBUG_STEP_TYPE_NONE:
                     default:
                        doContinue=true;
                        break;
                     }
                  }
               }
            }
         }
      }
      if (substr(event_kind,1,5)=='class') {
         updateClasses=true;
         if (event_kind=='class_prepare') {
            showLoading=true;
         }
      }
      if ((event_flags & VSDEBUG_EVENT_SUSPEND_ALL) && !(doContinue && !doNotContinue)) {
         if (!orig_suspended) {
            clear_message();
         }
         showingLoadingMessage=false;
         gInStepType=DEBUG_STEP_TYPE_NONE;
         gSuspended=true;
         if (event_kind!='vm_start') {
            debug_remove_temporary_breakpoints();
            dbg_update_editor_breakpoints();
         }
         if (event_kind=='breakpoint' || event_kind=='exception' || event_kind=='watchpoint' || event_kind=='watchpoint-read' || event_kind=='watchpoint-write') {
            if (dbg_get_callback_name(session_id) == 'jdwp') {
               debug_kill_suspended_events();
            }
         }
         updateDebugGUI=true;
         if (event_flags & VSDEBUG_EVENT_GOTOPC) {
            showNextStatement=true;
         }
         if (event_flags & VSDEBUG_EVENT_UPDATE_CLASSES) {
            updateClasses=true;
         }
         doRefresh=true;
         switchSession=true;
         debug_log("_UpdateDebugger: suspended:");
         break;
      }
      if (substr(event_kind,1,6)=='thread') {
         updateThreads=true;
      }

      if( event_kind == 'update_gui_breakpoints' ) {
         debug_gui_update_breakpoints(true);
      }

      // been working here too long (over a second)
      // let other people back into the game
      long now_time=(long)_time('B');
      if (now_time-orig_time > def_debug_max_update_time) {
         debug_log("_UpdateDebugger: time out, status="status" time="_time('B')" mtime="_time('M'));
         break;
      }
   }

   // if the condition for a breakpoint or exception fails, resume execution
   if (!gSuspended && doContinue && !doNotContinue) {
      debug_log("_UpdateDebugger: continuing");
      debug_pkg_continue();
      gSuspended=false;
      dbg_set_current_session(orig_session);
      return 0;
   }

   // that's all folks
   dbg_set_current_session(orig_session);
   return 0;
}

/**
 * Common code block used to update the debugger after we
 * have stepped, continued, or reset a breakpoint.  This
 * should be called after any action that could be quickly
 * followed by an asynchronous event, such as hitting a
 * breakpoint.
 */
void debug_force_update_after_step_or_continue(bool checkSuspendedFirst=true)
{
   _UpdateDebugger(true);
   if (checkSuspendedFirst) {
      debug_check_and_set_suspended(true,false);
   }
   debug_gui_update_threads();
   debug_gui_update_all_buttons();
   debug_gui_update_suspended();
}

/**
 * Timer hook, for updating the debugger when we catch incoming events.
 *
 * @param AlwaysUpdate     do it right now, or wait a tenth second?
 */
void _UpdateDebugger(bool AlwaysUpdate=false)
{
   // Do nothing if debugging is not support
   if (!_haveDebugging()) {
      return;
   }

   // not in debugging mode, then we are out of here
   if (!debug_active()) {
      return;
   }

   // make sure timer has waited long enough (a quarter second)
   // poll less often (every full second) if we are suspended
   int poll_interval=(gSuspended? def_debug_max_update_time:def_debug_min_update_time);
   if (!AlwaysUpdate && _idle_time_elapsed()<poll_interval) {
      return;
   }
   //debug_log("_UpdateDebugger: polling, time="_time('b'));

   // check if the "loading classes" message has been displayed long enough
   static bool showingLoadingMessage;
   if (showingLoadingMessage && _idle_time_elapsed() > def_debug_message_duration*1000) {
      clear_message();
      showingLoadingMessage=false;
   }

   // get the list of active sessions
   int session_ids[];
   int status = dbg_get_all_sessions(session_ids);
   if (status < 0) {
      return;
   }

   // save the original session ID
   session_id := dbg_get_current_session();
   switchSession := false;
   doRefresh := false;
   updateDebugGUI := false;
   updateClasses := false;
   updateThreads := false;
   updateExceptions := false;
   showLoadingMessage := false;
   showNextStatement := false;

   // event information from handle_event,
   // needed to show next statement
   event_kind := "";
   event_flags := 0;
   event_thread := 0;
   event_class := "";
   breakpoint_id := 0;

   // update each session
   result := 0;
   int i,n = session_ids._length();
   for (i=0; i<n; ++i) {
      // verify that this is an active debugger session
      if (!dbg_is_session_active(session_ids[i])) {
         continue;
      }

      switchSession = false;
      event_kind = '';
      event_flags = 0;
      event_thread = 0;
      event_class = '';
      breakpoint_id = 0;

      status = debug_session_update_debugger(session_ids[i],
                                             event_kind,
                                             event_flags,
                                             event_thread,
                                             event_class,
                                             breakpoint_id,
                                             AlwaysUpdate,
                                             switchSession,
                                             doRefresh,
                                             updateDebugGUI,
                                             updateThreads,
                                             updateClasses,
                                             updateExceptions,
                                             showLoadingMessage,
                                             showNextStatement);
      if (status < 0) {
         debug_log("_UpdateDebugger H"__LINE__": status="status);
         result = status;

      } else if (switchSession) {
         debug_log("_UpdateDebugger H"__LINE__": SWITCH SESSION");
         if (session_ids[i] != session_id) {

            int choice = _message_box("Break: switch to session: \"":+dbg_get_session_name(session_ids[i])"\"",'',MB_YESNO|MB_ICONQUESTION);
            if (choice == IDYES) {
               session_id = session_ids[i];
               break;
            } else {
               showNextStatement = false;
               updateThreads = false;
               updateClasses = false;
               updateExceptions = false;
               doRefresh = false;
               switchSession = false;
            }
         } else {
            switchSession = false;
         }
      }
   }

   // restore the session ID
   if (dbg_is_session_active(session_id) && session_id != dbg_get_current_session()) {

      debug_log("_UpdateDebugger H"__LINE__": SWITCH SESSION (2)");
      // switch sessions
      status = dbg_set_current_session(session_id);
      if (status < 0) {
         result = status;
      }

      // update enable/disable
      if (switchSession) {
         debug_gui_update_current_session();
         debug_pkg_enable_disable_tabs();
      }
   }

   // did we just switch sessions?
   if (switchSession) {
      debug_log("_UpdateDebugger H"__LINE__": SWITCH SESSION (3)");
      debug_gui_update_session();
      updateDebugGUI=false;
   }

   // do we need to update the symbol browser?
   if (updateClasses) {
      debug_log("_UpdateDebugger H"__LINE__": UPDATE CLASSES");
      if (showLoadingMessage && !gSuspended) {
         message("Loading classes...");
         showingLoadingMessage=true;
      }
      debug_gui_update_classes(true);
      doRefresh=true;
   }

   // do we need to update the list of exceptions
   if (updateExceptions) {
      debug_log("_UpdateDebugger H"__LINE__": UPDATE EXCEPTIONS");
      debug_gui_update_exceptions();
   }

   // update the execution stack (so that arrows point down)
   if (AlwaysUpdate) {
      debug_log("_UpdateDebugger H"__LINE__": ALWAYS UPDATE");
      thread_id := dbg_get_cur_thread();
      frame_id := dbg_get_cur_frame(thread_id);
      dbg_update_editor_stack(thread_id, frame_id);
   }

   // do we need to update the thread view?
   check_all_threads := !(event_flags & event_flags & VSDEBUG_EVENT_SUSPEND_ALL);
   if (updateThreads) {
      debug_log("_UpdateDebugger H"__LINE__": UPDATE THREADS");
      debug_check_and_set_suspended(true, check_all_threads);
      debug_gui_update_threads();
      debug_gui_update_all_buttons();
      debug_gui_update_suspended();
      doRefresh=true;
   }

   // update the gui?
   if (updateDebugGUI) {
      debug_log("_UpdateDebugger H"__LINE__": UPDATE GUI");
      if (AlwaysUpdate && def_debug_timer_delay > 0) {
         debug_log("_UpdateDebugger H"__LINE__": UPDATE GUI cur_thread="dbg_get_cur_thread()", jdwp_thread="event_thread);
         if (event_thread > 0) {
            dbg_set_cur_thread(event_thread);
         }
         debug_start_timer();
      } else {
         debug_log("_UpdateDebugger H"__LINE__": UPDATE GUI CUR THREAD");
         orig_thread_id := dbg_get_cur_thread();
         debug_gui_update_all(event_thread,1,!updateThreads && check_all_threads);
         if (event_thread == orig_thread_id) {
            event_thread = dbg_get_cur_thread();
         }
      }
   }

   // do we need to show the next statement?
   if (showNextStatement) {
      debug_log("_UpdateDebugger H"__LINE__": SHOW NEXT STATEMENT");
      debug_log("_UpdateDebugger H"__LINE__": breakpoint_id="breakpoint_id" event_kind="event_kind);
      exception_id  := (breakpoint_id > 0)? breakpoint_id:-1;
      is_breakpoint := (event_kind=='breakpoint' || event_kind=='watchpoint' || event_kind=='watchpoint-read' || event_kind=='watchpoint-write');
      is_exception  := (event_kind=='exception' || event_kind=='signal');
      debug_show_next_statement(true,
                                (is_breakpoint)? breakpoint_id:0,
                                (is_exception)?  exception_id:0,
                                event_kind, event_class, event_thread, 1
                                );
      if (breakpoint_id > 0) {
         debug_gui_update_current_breakpoint(breakpoint_id);
      }
   }

   // force a refresh?
   if (doRefresh) {
      refresh();
   }

   // nothing to do with the result
   return;
}

void _UpdateSlickCDebugHandler(bool AlwaysUpdate=false)
{
   if (_haveDebugging()) {
      _SlickCDebugHandler(0);
   }
}

/**
 * Function to eat up extraneous breakpoint or exception events that
 * occur after all threads have been suspended.  This done merely to
 * work around a problem in the JDWP implementation.  Technically,
 * we should get only breakpoint event, and no other events once
 * the virtual machine is suspended.
 */
static void debug_kill_suspended_events()
{
   return;

   // not in debugging mode or not suspended, then we are out of here
   if (!debug_active() || !gSuspended) {
      return;
   }

   // handle events until we run out of them
   session_id := dbg_get_current_session();
   long orig_time=(long)_time('B');
   now_time := 0L;
   while (1) {

      // poll for the next event off the queue
      event_kind := "";
      event_class := "";
      event_flags := 0;
      event_thread := 0;
      breakpoint_id := 0;
      int status = dbg_session_handle_event(session_id, 
                                            event_kind, event_flags, 
                                            event_thread, event_class, 
                                            breakpoint_id);
      if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
         return;
      }
      if (status) {
         now_time=(long)_time('B');
         if (now_time-orig_time > def_debug_min_update_time) {
            break;
         }
         delay(5);
         continue;
      }

      //say("debug_kill_suspended_events: status="status" event="event_kind" flags="event_flags" thread="event_thread" time="_time('B')" mtime="_time('M')" ELAPSED TIME="(long)_time('b')-orig_time);

      // stop the virtual machine
      if( (event_flags & VSDEBUG_EVENT_STOP) ||
          event_kind == 'vm_stop' || event_kind == 'vm_disconnect' ||
          event_kind == "exit" ||
          event_kind == "exit_quiet" ) {

         if (event_class=='') event_class="application exited";
         debug_message("Debugger stopped: ":+event_class,status,false);
         debug_stop(true);
         refresh();
         return;
      }

      // handle class prepare events here, in case if we get one out-of-sequence
      if (event_kind=='class_prepare' && (event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         status=debug_enable_all_breakpoints(event_class,false,nls("\n\nThe breakpoint has been disabled and execution will be suspended immediately."));
         if (!status) {
            status=debug_enable_all_exceptions(event_class,false,nls("\n\nThe exception has been disabled and execution will be suspended immediately."));
         }
         if (status) {
            //debug_step_into();
            gSuspended=true;
            break;
         } else {
            debug_pkg_continue();
            gSuspended=false;
         }
         event_flags &= ~VSDEBUG_EVENT_SUSPEND_ALL;
         break;
      }

      // not a recognized message, uh-oh
      if (event_kind!='breakpoint' && 
          event_kind!='exception' &&
          event_kind!='watchpoint' && 
          event_kind!='watchpoint-read' &&
          event_kind!='watchpoint-write' &&
          event_kind!='step' && 
          event_kind!='signal') {
         break;
      }

      // not a suspend-all?
      if (!(event_flags & VSDEBUG_EVENT_SUSPEND_ALL)) {
         break;
      }

      // spending too much time here
      now_time=(long)_time('B');
      if (now_time-orig_time > def_debug_max_update_time) {
         break;
      }
   }
}

///////////////////////////////////////////////////////////////////////////
// project management hooks
//

/**
 * Initialize the runtime filters if they have not yet been initialized.
 */
void debug_initialize_runtime_filters(int session_id, bool force=false)
{
   if (!_haveDebugging()) return;
   // If they have marker item, clear and initilize the runtimes
   orig_session := dbg_set_current_session(session_id);
   debug_cb_name := dbg_get_callback_name(session_id);
   if (dbg_get_num_runtimes() <= 1 || force) {
      _str first_one;
      dbg_get_runtime_expr(1,first_one);
      if (first_one==VSDEBUG_RUNTIME_IMPOSSIBLE_STR || force) {
         dbg_clear_runtimes();
         if (debug_cb_name=='jdwp') {
            dbg_add_runtime_expr("java.*");
            dbg_add_runtime_expr("javax.*");
            dbg_add_runtime_expr("com.sun.*");
            dbg_add_runtime_expr("com.ibm.*");
            dbg_add_runtime_expr("sun.*");
            dbg_add_runtime_expr("org.codehaus.*");
            dbg_add_runtime_expr("groovy.lang.*");
            dbg_add_runtime_expr("scala.*");
            dbg_add_runtime_expr("jdk.internal.*");
         } else if (debug_cb_name=='mono') {
            dbg_add_runtime_expr("System.*");
            dbg_add_runtime_expr("Microsoft.*");
            dbg_add_runtime_expr("Mono.*");
         } else if (debug_cb_name=='gdb' || debug_cb_name=='lldb' || debug_cb_name=="windbg") {
            dbg_add_runtime_expr("printf");
            dbg_add_runtime_expr("strcpy");
            dbg_add_runtime_expr("strcmp");
            dbg_add_runtime_expr("std::*");
            dbg_add_runtime_expr("boost::*");
         }
      }
   }
   dbg_set_current_session(orig_session);
}

/**
 * Maybe initialize the debugger library (vsdebug.dll)
 * and debugger code
 */
int debug_maybe_initialize(bool force_initialization=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( DllIsMissing("vsdebug.dll") ) {
      return(FILE_NOT_FOUND_RC);
   }
   status := 0;
   if (!gDebuggerInitialized || force_initialization) {
      status=dbg_initialize();
      if (!gDebuggerInitialized) {
         debug_gui_remove_update_callbacks();
      }
      gDebuggerInitialized=true;
   }
   return(status);
}

/**
 * Return the name of the debugging session for the current workspace
 */
_str debug_get_workspace_session_name()
{
   if (!_haveDebugging()) return "";
   if (_workspace_filename == '') {
      if (_fileProjectHandle()>=0) {
         return "FILEPROJECT: " :+ gfp_curAbsFilename;
      }
      return "";
   }
   return "WORKSPACE: " :+ _workspace_filename;
}

/**
 * Return the session ID of the debugging session for the current workspace.
 */
int debug_get_workspace_session_id(_str cb_name="")
{
   if (!_haveDebugging()) return 0;
   session_name := debug_get_workspace_session_name();
   if (session_name == '') return 0;
   session_id := dbg_find_session(session_name);

   // if they changed callback name, restart the session
   if (cb_name == "") cb_name = _project_DebugCallbackName;
   cb_name = (cb_name=="slickc_jdwp")? "jdwp":cb_name;
   if (session_id > 0 && dbg_get_callback_name(session_id) != cb_name) {
      session_id = dbg_create_new_session(cb_name, session_name, true);
   }

   // that's all folks
   return session_id;
}

/**
 * Save the setup information for the current debugging session
 */
void debug_save_session(int session_id, _str relativeToDir, bool skipIfEmpty=true)
{
   if (!_haveDebugging()) {
      return;
   }
   // make this the active session
   dbg_set_current_session(session_id);
   CallBackName := dbg_get_callback_name(session_id);

   // get the number of each item
   int NofWatches=dbg_get_num_watches();
   int NofDirs=dbg_get_num_dirs();
   int NofBreakpoints=dbg_get_num_breakpoints();
   int NofExceptions=dbg_get_num_exceptions();
   int NofRuntimes=dbg_get_num_runtimes();
   int NofFormattedVars=dbg_get_num_formatted_vars();
   int i;

   // check if the uninitialized marker is still set
   if (NofRuntimes >= 1) {
      _str first_one;
      dbg_get_runtime_expr(1,first_one);
      if (first_one==VSDEBUG_RUNTIME_IMPOSSIBLE_STR) {
         NofRuntimes=0;
      }
   }

   // nothing set, so don't write anything
   if (skipIfEmpty && !NofWatches && !NofDirs && !NofBreakpoints && !NofExceptions && !NofRuntimes) {
      return;
   }

   // header line has number of lines to follow for each type of item
   insert_line('DEBUG: 'NofWatches' 'NofDirs' 'NofBreakpoints' 'NofExceptions' 'NofRuntimes' 'NofFormattedVars' 'CallBackName);

   // save the watch expressions
   _str expr,context_name,value,raw_value='',typename='';
   int tab_number,expandable,base_str;
   for (i=1;i<=NofWatches;++i) {
      dbg_get_watch(0,0,i,tab_number,expr,context_name,value,expandable,base_str,raw_value,typename);
      insert_line(tab_number"\1"context_name"\1"expr"\1"base_str);
   }

   // save the source directories
   _str source_dir;
   for (i=1;i<=NofDirs;++i) {
      dbg_get_source_dir(i,source_dir);
      _maybe_append_filesep(source_dir);
      if (relativeToDir!=null) {
         source_dir=relative(source_dir,relativeToDir);
      }
      if (source_dir=='') {
         source_dir='.';
      }
      insert_line(source_dir);
   }

   // save the breakpoints
   bool enabled;
   count := line_number := type := flags := 0;
   _str condition,thread_name,class_name,method_name,file_name,address;
   for (i=1;i<=NofBreakpoints;++i) {
      dbg_get_breakpoint(i,count,condition,thread_name,class_name,method_name,file_name,line_number,enabled,address);
      type=dbg_get_breakpoint_type(i,flags);
      if (relativeToDir!=null) {
         file_name=relative(file_name,relativeToDir);
      }
      insert_line(count"\1"type"\1"thread_name"\1"class_name"\1"method_name"\1"file_name"\1"line_number"\1"enabled"\1"condition"\1"address"\1"flags);
   }

   // save the exceptions
   int stop_when;
   for (i=1;i<=NofExceptions;++i) {
      dbg_get_exception(i,stop_when,count,condition,class_name,thread_name,enabled);
      insert_line(stop_when"\1"count"\1"class_name"\1"thread_name"\1"enabled"\1"condition);
   }

   // save the runtime dirs
   for (i=1;i<=NofRuntimes;++i) {
      dbg_get_runtime_expr(i,expr);
      insert_line(expr);
   }

   // save the formatting specs
   for (i=1;i<=NofFormattedVars;++i) {
      cur_var := "";
      int status=dbg_get_formatted_var(i,cur_var);
      if (!status) {
         int base=dbg_get_var_format(cur_var);
         insert_line(cur_var"\1"base);
      }
   }
}

/**
 * 
 * 
 * @param session_id 
 * @param relativeToDir 
 * @param skipIfEmpty 
 */
void debug_save_session_RELOC_MARKERs(int session_id, _str relativeToDir,
                                      bool skipIfEmpty=true)
{
   if (!_haveDebugging()) {
      return;
   }
   // Make this the active session
   dbg_set_current_session(session_id);

   insert_line("");
   orig_line := p_line;
   NofBreakpoints := 0;

   bool enabled;
   count := line_number := type := flags := 0;
   _str condition, thread_name, class_name, method_name, file_name, address;
   _str possibly_relative_file_name;
   int i;
   for (i = 1; i <= dbg_get_num_breakpoints(); ++i) {
      dbg_get_breakpoint(i, count, condition, thread_name, class_name,
                         method_name, file_name, line_number, enabled, address);
      type = dbg_get_breakpoint_type(i, flags);

      possibly_relative_file_name = file_name;
      if (relativeToDir != null) {
         possibly_relative_file_name = relative(file_name, relativeToDir);
      }

      if (!bpRELOC_MARKERs._indexin(file_name) ||
          !bpRELOC_MARKERs:[file_name]._indexin(session_id)) {
         build_bpRELOC_MARKERs(session_id, file_name);
      }

      // make sure we have relevant item
      if (!bpRELOC_MARKERs._indexin(file_name) ||
          !bpRELOC_MARKERs:[file_name]._indexin(session_id) ||
          !bpRELOC_MARKERs:[file_name]:[session_id]._indexin(line_number)) {
         continue;
      }
      RELOC_MARKER lm = bpRELOC_MARKERs:[file_name]:[session_id]:[line_number];

      ++NofBreakpoints;
      insert_line(count"\1"type"\1"thread_name"\1"class_name"\1":+
                  method_name"\1"possibly_relative_file_name"\1":+
                  line_number"\1"enabled"\1"condition"\1"address"\1"flags"\1":+
                  lm.textAbove._length()"\1"lm.textBelow._length());
      int j;
      int k;
      _str RMLine;
      for (j = 0; j < lm.textAbove._length(); ++j) {
         RMLine = "\1";
         for (k = 0; k < lm.textAbove[j]._length(); ++k) {
            RMLine :+= "\1"lm.textAbove[j][k];
         }
         RMLine = strip(RMLine);
         insert_line(RMLine);
      }
      RMLine = "\1";
      for (k = 0; k < lm.origText._length(); ++k) {
         RMLine :+= "\1"lm.origText[k];
      }
      RMLine = strip(RMLine);
      insert_line(RMLine);
      for (j = 0; j < lm.textBelow._length(); ++j) {
         RMLine = "\1";
         for (k = 0; k < lm.textBelow[j]._length(); ++k) {
            RMLine :+= "\1"lm.textBelow[j][k];
         }
         RMLine = strip(RMLine);
         insert_line(RMLine);
      }
   }
   orig_line2 := p_line;
   p_line=orig_line;
   replace_line('DEBUG2: 'NofBreakpoints);
   p_line=orig_line2;
}

/**
 * Restore the setup information for the current debugging session
 */
int debug_restore_session(_str session_name, _str callback_name, _str info, _str relativeToDir)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // now parse the restore information
   int i;
   _str line;
   typeless NofWatches,NofDirs,NofBreakpoints,NofExceptions,NofRuntimes,NofFormattedVars,CallBackName;
   parse info with NofWatches NofDirs NofBreakpoints NofExceptions NofRuntimes NofFormattedVars CallBackName;
   if (CallBackName=="") CallBackName = callback_name; 

   // create a default session ID for this workspace and make it active
   session_id := 0;
   if (session_name != '') {
      dbg_create_new_session(CallBackName, session_name, false);
      if (session_id < 0) {
         return session_id;
      }
   }

   // restore watches
   dbg_clear_watches();
   if (isinteger(NofWatches) && NofWatches>0) {
      _str tab_number,context_name,expr,base_str;
      for (i=1;i<=NofWatches;++i) {
         down();
         get_line(line);
         parse line with tab_number"\1"context_name"\1"expr"\1"base_str .;
         int base=VSDEBUG_BASE_DEFAULT;
         // Check to be sure that base_str is actually an integer.  There will
         // be old restore files that will not have this setting, and this
         // was we default to VSDEBUG_BASE_DEFAULT
         if (isinteger(base_str)) {
            base=(int)base_str;
         }
         int watch_id=dbg_add_watch((int)tab_number,expr,context_name,base);
      }
   }

   // restore source directories
   dbg_clear_sourcedirs();
   if (isinteger(NofDirs) && NofDirs>0) {
      for (i=1;i<=NofDirs;++i) {
         down();
         get_line(line);
         line=absolute(line,relativeToDir);
         dbg_add_source_dir(absolute(strip(line),relativeToDir));
      }
   }

   // restore breakpoints
   dbg_clear_breakpoints();
   if (isinteger(NofBreakpoints) && NofBreakpoints>0) {
      _str count,reserved,thread_name,class_name,method_name,file_name,line_number,enabled,condition,address,type,flags;
      for (i=1;i<=NofBreakpoints;++i) {
         down();
         get_line(line);
         parse line with count"\1"type"\1"thread_name"\1"class_name"\1"method_name"\1"file_name"\1"line_number"\1"enabled"\1"condition"\1"address"\1"flags;
         file_name=absolute(file_name,relativeToDir);
         int itype = isnumber(type)? (int)type : VSDEBUG_BREAKPOINT_LINE;
         int iflag = isnumber(flags)? (int)flags : 0;
         int breakpoint_id=dbg_add_breakpoint((int)count,condition,thread_name,class_name,method_name,file_name,(int)line_number,address,itype,(int)iflag);
         if (breakpoint_id>0 && enabled>0) {
            dbg_set_breakpoint_enabled(breakpoint_id,1);
         }
      }
   }

   // restore exceptions
   dbg_clear_exceptions();
   if (isinteger(NofExceptions) && NofExceptions>0) {
      _str stop_when,count,class_name,thread_name,enabled,condition;
      for (i=1;i<=NofExceptions;++i) {
         down();
         get_line(line);
         parse line with stop_when"\1"count"\1"class_name"\1"thread_name"\1"enabled"\1"condition;
         int exception_id=dbg_add_exception((int)stop_when,(int)count,condition,class_name,thread_name);
         if (exception_id>0 && enabled>0) {
            dbg_set_exception_enabled(exception_id,1);
         }
      }
   }

   // restore runtimes
   dbg_clear_runtimes();
   if (isinteger(NofRuntimes) && NofRuntimes>0) {
      for (i=1;i<=NofRuntimes;++i) {
         down();
         get_line(line);
         dbg_add_runtime_expr(strip(line));
      }
   } else if (!isinteger(NofRuntimes)) {
      // set a marker to indicate that we need to initialize this later.
      dbg_add_runtime_expr(VSDEBUG_RUNTIME_IMPOSSIBLE_STR);
   }

   // restore format specifications
   if (isinteger(NofFormattedVars) && NofFormattedVars>0) {
      _str varname,base_str;
      for (i=1;i<=NofFormattedVars;++i) {
         down();
         get_line(line);
         parse line with varname"\1"base_str;
         int base=VSDEBUG_BASE_DEFAULT;
         if (isinteger(base_str)) {
            base=(int)base_str;
         }
         dbg_set_var_format(varname,base);
      }
   }

   // return the new session ID
   debug_initialize_runtime_filters(session_id);
   return session_id;
}

void debug_restore_session_RELOC_MARKERs(_str session_name, _str callback_name,
                                         _str bpCount, _str relativeToDir,
                                         bool fullDump)
{
   if (!_haveDebugging()) {
      return;
   }

   orig_session_id := dbg_get_current_session();

   // Make session_name the active session
   tmp_session_id := dbg_find_session(session_name);
   dbg_set_current_session(tmp_session_id);
   
   // restore breakpoints
   if (bpCount > 0) {
      count := "";
      reserved := "";
      thread_name := "";
      class_name := "";
      method_name := "";
      file_name := "";
      line_number := "";
      enabled := "";
      condition := "";
      address := "";
      type := "";
      flags := "";
      aboveCount := "";
      belowCount := "";
      int i;
      line := "";
      for (i=1; i <= bpCount; ++i) {
         if(down()) break;
         get_line(line);
         parse line with count"\1"type"\1"thread_name"\1"class_name"\1"method_name"\1"file_name"\1"line_number"\1"enabled"\1"condition"\1"address"\1"flags"\1"aboveCount"\1"belowCount;

         status := -1;
         int temp_view_id;
         int orig_view_id;
         if ((aboveCount > 0) || (belowCount > 0)) {
            // Build the relocatable marker
            RELOC_MARKER lm;

            lm.aboveCount = (int)aboveCount;
            lm.belowCount = (int)belowCount;
            int j;
            for (j = 0; j < lm.aboveCount; ++j) {
               down();
               lineAbove := "";
               get_line(lineAbove);
               lineAbove = strip(stranslate(lineAbove, ' ', "\1"));
               tokenizeLine(lineAbove, lm.textAbove[j]);
            }
            down();
            get_line(line);
            line = strip(stranslate(line, ' ', "\1"));
            tokenizeLine(line, lm.origText);
            for (j = 0; j < lm.belowCount; ++j) {
               down();
               lineBelow := "";
               get_line(lineBelow);
               lineBelow = strip(stranslate(lineBelow, ' ', "\1"));
               tokenizeLine(lineBelow, lm.textBelow[j]);
            }
            lm.origLineNumber = (int)line_number;
            lm.totalCount = lm.aboveCount + lm.belowCount;
            lm.n = RELOC_MARKER_WINDOW_SIZE;
            lm.sourceFile = file_name;
            bpRELOC_MARKERs:[file_name]:[tmp_session_id]:[line_number] = lm;
         }
      }
   }

   dbg_set_current_session(orig_session_id);
}

/**
 * Used to save-restore debugger options when the workspace is closed.
 * NOTE: some might argue that these settings should be done per-project
 * rather than per-workspace.
 */
int _sr_debug(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null,bool doFileProjects=false)
{
   // If the debugger DLL (vsdebug.dll) is not already loaded,
   // call it's initialize function and cause it to become loaded.
   if (option=='R' || option=='N') {
      debug_maybe_initialize();
   }
   if (!gDebuggerInitialized) {
      return 0;
   }
   if (!_haveDebugging() || DllIsMissing("vsdebug.dll")) {
      return 0;
   }

   // session information needed later
   session_id := 0;
   session_name := "";
   callback_name := "";

   //say("_sr_debug: HERE, options="option" info="info" project="_project_name);
   typeless NofWatches,NofDirs,NofBreakpoints,NofExceptions,NofRuntimes,NofFormattedVars;
   if (option=='R' || option=='N') {
      line := "";

      // restore the default session ID for this workspace and make it active
      session_name = debug_get_workspace_session_name();
      session_id = debug_restore_session(session_name, "", info, relativeToDir);

      // restore the other debugging sessions
      for (;;) {

         // check for a SESSION: line
         if (down()) break;;
         get_line(line);
         if (pos("SESSION: ", line) != 1) {
            up();
            break;
         }

         // get the callback name and session name
         parse line with "SESSION:" callback_name session_name;
         callback_name = strip(callback_name);
         session_name = strip(session_name);

         // now get the DEBUG line and restore
         if (down()) break;
         get_line(line);
         if (pos("DEBUG: ", line) == 1) {
            parse line with "DEBUG:" info;
            debug_restore_session(session_name, callback_name, info, relativeToDir);
         }
      }

      if (down() == 0) {
         // restore the default session ID for this workspace and make it active
         session_name = debug_get_workspace_session_name();

         get_line(line);
         bpCount := "";
         if (pos("DEBUG2: ", line) == 1) {
            parse line with "DEBUG2:" bpCount;
            debug_restore_session_RELOC_MARKERs(session_name, '', (int)bpCount,
                                                relativeToDir, true);
         }

         // restore the other debugging sessions
         for (;;) {
            // check for a SESSION2: line
            if (down()) break;
            get_line(line);
            if (pos("SESSION2: ", line) != 1) {
               up();
               break;
            }

            // get the callback name and session name
            parse line with "SESSION2:" callback_name session_name;
            callback_name = strip(callback_name);
            session_name = strip(session_name);

            // now get the DEBUG2 line and restore
            if (down()) break;
            get_line(line);
            if (pos("DEBUG2: ", line) == 1) {
               parse line with "DEBUG2:" bpCount;
               debug_restore_session_RELOC_MARKERs(session_name, callback_name,
                                                   (int)bpCount, relativeToDir,
                                                   false);
            }
         }

         dbg_set_current_session(session_id);
      }
   } else {

      if (doFileProjects || _workspace_filename!='') {
         // finally, save the default session for this workspace
         session_id = debug_get_workspace_session_id();
         if (session_id > 0) {
            debug_save_session(session_id, relativeToDir);
         }
      }

      int session_ids[];
      dbg_get_all_sessions(session_ids);
      int i,n = session_ids._length();
      if (!doFileProjects) {
         // get all the session ids
         for (i=0; i<n; ++i) {
            int other_id = session_ids[i];
            if (other_id == session_id) continue;

            session_name = dbg_get_session_name(other_id);
            if (beginsWith(session_name,'FILEPROJECT:')) {
               if (!doFileProjects) {
                  continue;
               }
            }
            callback_name = dbg_get_callback_name(other_id);
            insert_line("SESSION: "callback_name" "session_name);
            debug_save_session(other_id, relativeToDir, false);
         }
      }

      if (doFileProjects || _workspace_filename!='') {
         // Save the breakpoints again, with relocatable marker information:
         session_id = debug_get_workspace_session_id();
         if (session_id > 0) {
            debug_save_session_RELOC_MARKERs(session_id, relativeToDir);
         }
      }
      if (!doFileProjects) {
         for (i=0; i<n; ++i) {
            int other_id = session_ids[i];
            if (other_id == session_id) {
               continue;
            }

            session_name = dbg_get_session_name(other_id);
            if (beginsWith(session_name,'FILEPROJECT:')) {
               if (!doFileProjects) {
                  continue;
               }
            }
            callback_name = dbg_get_callback_name(other_id);
            insert_line("SESSION2: "callback_name" "session_name);
            debug_save_session_RELOC_MARKERs(other_id, relativeToDir, false);
         }
      }
   }

   // make the workspace session ID the active session
   if (session_id > 0) {
      dbg_set_current_session(session_id);
      debug_gui_update_current_session();
   }

   // that's all folks
   return(0);
}

/**
 * If they open a different project, stop debugging
 */
void _prjopen_debug()
{
   if ( !_haveDebugging() || DllIsMissing('vsdebug.dll') ) {
      // Be sure vsdebug.dll is there before calling any debug_* functions
      // will attempt to load it
      return;
   }
   // If the debugger DLL (vsdebug.dll) is not already loaded,
   // call it's initialize function and cause it to become loaded.
   if (_project_DebugCallbackName!='') {
      debug_maybe_initialize();
   } else {
      return;
   }

   // create a session ID for this project and make it active
   session_name := debug_get_workspace_session_name();
   if (session_name == '') return;
   int session_id = dbg_create_new_session(_project_DebugCallbackName, session_name, true);

   // initialize the debugger
   debug_stop(true);
   debug_pkg_enable_disable_tabs();
   debug_gui_update_all_buttons();
   debug_gui_update_breakpoints(true);
   debug_gui_update_exceptions(true);
   debug_gui_update_current_session();
   debug_initialize_runtime_filters(session_id);
}
/**
 * If they close the current project, stop debugging
 */
void _prjclose_debug()
{
   if (!_haveDebugging()) {
      return;
   }
   if (!gDebuggerInitialized) {
      return;
   }
   debug_stop(true);
   dbg_clear_variables();
   debug_pkg_enable_disable_tabs();

   // These caused trouble when switching projects
   // see _wkspace_close_debug() below
   //
   //dbg_clear_breakpoints();
   //dbg_clear_exceptions();
   //dbg_clear_sourcedirs();
   //dbg_clear_watches();
   //dbg_clear_runtimes();
   //dbg_clear_editor();
   //dbg_add_runtime_expr(VSDEBUG_RUNTIME_IMPOSSIBLE_STR);
   //debug_gui_clear_breakpoints();
   //debug_gui_clear_exceptions();
   //gExceptionList._makeempty();

}

/**
 * If they close the current workspace, stop debugging
 * This is part of a call-list, called when a workspace is closed
 */
void _wkspace_close_debug()
{
   if (!_haveDebugging() || DllIsMissing("vsdebug.dll")) {
      return;
   }
   if (!gDebuggerInitialized) {
      return;
   }

   // destroy the default workspace debugger session
   int session_id = debug_get_workspace_session_id();
   if (session_id > 0) {
      if (dbg_is_session_active(session_id)) {
         dbg_set_current_session(session_id);
         debug_stop(true);
      }
      dbg_destroy_session(session_id);
   }

   // also stop and destroy all the other sessions
   int session_ids[];
   dbg_get_all_sessions(session_ids);
   int i,n = session_ids._length();
   for (i=0; i<n; ++i) {
      session_id = session_ids[i];
      if (dbg_is_session_active(session_id)) {
         dbg_set_current_session(session_id);
         debug_stop(true);
      }
      dbg_destroy_session(session_id);
   }

   // clean up
   dbg_clear_breakpoints();
   dbg_clear_exceptions();
   dbg_clear_sourcedirs();
   dbg_clear_watches();
   dbg_clear_variables();
   dbg_clear_editor();
   debug_gui_clear_disassembly();
   dbg_clear_runtimes();
   dbg_add_runtime_expr(VSDEBUG_RUNTIME_IMPOSSIBLE_STR);
   debug_gui_clear_breakpoints();
   debug_gui_clear_exceptions();
   debug_pkg_enable_disable_tabs();
   gExceptionList._makeempty();
   gReadOnlyFiles._makeempty();
   debug_gui_update_current_session();

}

/**
 * Gets called when a buffer is closed. 
 * This function is used to generate relocatable code markers 
 * for breakpoints, from all debug sessions, when their file is 
 * closed by a user. 
 *
 * @param buffid  p_buf_id of the buffer that was closed
 * @param name    p_buf_name of the buffer that was closed
 * @param docname p_DocumentName of the buffer that was closed
 * @param flags   assumed to be 0
 */
void _cbquit_breakpoints(int buffid, _str name, _str docname='', int flags=0)
{
   if (!_haveDebugging() || DllIsMissing("vsdebug.dll")) {
      return;
   }

   // Save the current session.
   currentSessionID := dbg_get_current_session();

   // Build bpRELOC_MARKERs for all sessions, not just the current one.
   workspaceSessionID := debug_get_workspace_session_id();
   if (workspaceSessionID > 0) {
      dbg_set_current_session(workspaceSessionID);
      build_bpRELOC_MARKERs(workspaceSessionID, name);
   }
   int sessionIDs[];
   dbg_get_all_sessions(sessionIDs);
   n := sessionIDs._length();
   for (i:=0; i<n; ++i) {
      int otherSessionID = sessionIDs[i];
      if (otherSessionID == workspaceSessionID) {
         continue;
      }
      dbg_set_current_session(otherSessionID);
      build_bpRELOC_MARKERs(otherSessionID, name);
   }

   // Restore the current session.
   if (currentSessionID > 0) {
      dbg_set_current_session(currentSessionID);
   }
}



static void build_bpRELOC_MARKERs (int session_id, _str name)
{
   if (!_haveDebugging()) return;
   bpRELOC_MARKERs:[name]:[session_id]._makeempty();

   int temp_view_id;
   int orig_view_id;
   int status;
   status = _open_temp_view(name, temp_view_id, orig_view_id);
   if (!status) {
      int i;
      // Check each breakpoint to see if it's in the buffer being quit.
      for (i = 1; i <= dbg_get_num_breakpoints(); ++i) {
         // breakpoint attributes
         count := 0;
         condition := "";
         thread_name := "";
         class_name := "";
         method_name := "";
         file_name := "";
         line_number := 0;
         enabled := false;
         address := "";
         dbg_get_breakpoint(i, count, condition, thread_name, class_name,
                            method_name, file_name, line_number, enabled,
                            address);

         if (!_file_eq(file_name, p_buf_name)) {
            continue;
         }

         RELOC_MARKER lm;
         p_RLine = line_number;
         // There may be more than one breakpoint on a line. No need to build
         // more than one relocatable marker.
         if (!bpRELOC_MARKERs:[name]:[session_id]._indexin(line_number)) {
            _BuildRelocatableMarker(lm);
            bpRELOC_MARKERs:[name]:[session_id]:[line_number] = lm;
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }

   // If there aren't any breakpoints in this buffer and session anymore, remove
   // it from the list.
   if (bpRELOC_MARKERs._indexin(name) &&
       bpRELOC_MARKERs:[name]._indexin(session_id) &&
       (bpRELOC_MARKERs:[name]:[session_id]._length() == 0)) {
      bpRELOC_MARKERs._deleteel(name);
   }

   // If there aren't any breakpoints in this buffer anymore, remove it from the
   // list.
   if (bpRELOC_MARKERs._indexin(name) &&
       (bpRELOC_MARKERs:[name]._length() == 0)) {
      bpRELOC_MARKERs._deleteel(name);
   }
}



void _switchbuf_breakpoints ()
{
   if (!_haveDebugging()) return;
   if (!_isEditorCtl(false)) return;
   maybeRelocateAllBreakpointsInBuffer(p_buf_name);
   debug_gui_update_breakpoints(true);
}


void relocateAllBreakpointsForSession (int session)
{
   // Find every buffer that has breakpoints for this session ...
   double origTime = (double)_time('F');
   typeless bufName;
   for (bufName._makeempty(); ; ) {
      bpRELOC_MARKERs._nextel(bufName);
      if (bufName._isempty()) {
         break;
      }
      typeless sessionID;
      for (sessionID._makeempty(); ; ) {
         bpRELOC_MARKERs:[bufName]._nextel(sessionID);
         if (sessionID._isempty()) {
            break;
         }
         // ... but go ahead and relocate breakpoints for all sessions that have
         // breakpoints in that buffer.
         maybeRelocateAllBreakpointsInBuffer(bufName);

         double nowTime = (double)_time('F');
         if ((nowTime - origTime) > def_max_breakpoint_relocate_time) {
            break;
         }
      }
   }
   debug_gui_update_breakpoints(true);
}


void maybeRelocateAllBreakpointsInBuffer (_str bufName)
{
   // If the debugger is running, don't relocate breakpoints, it's too late.
   if (debug_active()) {
      return;
   }

   if (!bpRELOC_MARKERs._indexin(bufName)) {
      return;
   }

   int temp_view_id;
   int orig_view_id;
   int status;
   status = _open_temp_view(bufName, temp_view_id, orig_view_id);
   if (status) {
      return;
   }

   // Save the current session.
   currentSessionID := dbg_get_current_session();
   resetTokens := true;
   workspaceSessionID   := 0;
   workspaceSessionName := debug_get_workspace_session_name();
   if (workspaceSessionName != "") {
      workspaceSessionID = dbg_find_session(workspaceSessionName);
      if (workspaceSessionID > 0) {
         dbg_set_current_session(workspaceSessionID);
         maybeRelocateSessionBreakpointsInBuffer(workspaceSessionID, bufName, resetTokens);
      }
   }
   int sessionIDs[];
   dbg_get_all_sessions(sessionIDs);
   int i;
   n := sessionIDs._length();
   for (i = 0; i < n; ++i) {
      int otherSessionID = sessionIDs[i];
      if (otherSessionID == workspaceSessionID) {
         continue;
      }
      dbg_set_current_session(otherSessionID);
      maybeRelocateSessionBreakpointsInBuffer(otherSessionID, bufName,
                                              resetTokens);
      resetTokens = false;
   }

   // Restore the current session.
   if (currentSessionID > 0) {
      dbg_set_current_session(currentSessionID);
   }

   bpRELOC_MARKERs._deleteel(bufName);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
}


void maybeRelocateSessionBreakpointsInBuffer (int sessionID, _str bufName,
                                              bool resetTokens=false)
{
   if ((!bpRELOC_MARKERs._indexin(bufName) ||
        !bpRELOC_MARKERs:[bufName]._indexin(sessionID))) {
      return;
   }

   if (!_haveDebugging()) return;
   typeless p;
   save_pos(p);

   BreakpointSaveInfo bpInfos[];
   int deletionList[];
   int linesRelocated:[];
   int rLine;
   
   bool enabled;
   _str possibly_relative_file_name;
   int i;
   int NofBreakpoints = dbg_get_num_breakpoints();
   
   // Find breakpoints that need to be relocated.
   double origTime = (double)_time('F');
   for (i = 1; i <= NofBreakpoints; ++i) {
      BreakpointSaveInfo bpInfo;
      dbg_get_breakpoint(i, bpInfo.count, bpInfo.condition, bpInfo.threadName,
                         bpInfo.className, bpInfo.methodName, bpInfo.fileName,
                         bpInfo.lineNumber, bpInfo.enabled, bpInfo.address);
      bpInfo.bp_type = dbg_get_breakpoint_type(i, bpInfo.bp_flags);

      if (_file_eq(bpInfo.fileName, bufName) &&
          bpRELOC_MARKERs:[bufName]:[sessionID]._indexin(bpInfo.lineNumber)) {
         rLine = -1;
         // If more than one breakpoint is on a line, only relocate it once.
         if (!linesRelocated._indexin(bpInfo.lineNumber)) {
            rLine = _RelocateMarker(bpRELOC_MARKERs:[bufName]:[sessionID]:[bpInfo.lineNumber],
                                    resetTokens);
            resetTokens = false;
            linesRelocated:[bpInfo.lineNumber] = rLine;
         } else {
            rLine = linesRelocated:[bpInfo.lineNumber];
         }

         if ((rLine != -1) && (rLine != bpInfo.lineNumber)) {
            bpInfo.lineNumber = rLine;
            bpInfos[bpInfos._length()] = bpInfo;
            deletionList[deletionList._length()] = i;
         }
      }

      double nowTime = (double)_time('F');
      if ((nowTime - origTime) > def_max_breakpoint_relocate_time) {
         break;
      }
   }

   // Remove the old breakpoints that need to be relocated.
   i = (deletionList._length()-1);
   for (; i >= 0; --i) {
      debug_pkg_disable_breakpoint(deletionList[i]);
      int result = dbg_remove_breakpoint(deletionList[i]);
   }

   // Re-add the breakpoints that moved.
   int bpHandle;
   for (i = 0; i < bpInfos._length(); ++i) {
      bpHandle = dbg_add_breakpoint(bpInfos[i].count, bpInfos[i].condition,
                                    bpInfos[i].threadName, bpInfos[i].className,
                                    bpInfos[i].methodName, bpInfos[i].fileName,
                                    bpInfos[i].lineNumber, bpInfos[i].address,
                                    bpInfos[i].bp_type, bpInfos[i].bp_flags);
      if (bpInfos[i].enabled) {
         debug_pkg_enable_breakpoint(bpHandle, true);
      }
   }

   restore_pos(p);

   bpRELOC_MARKERs:[bufName]._deleteel(sessionID);
}

static void menu_hide_debug_command(int menu_handle, _str cmd)
{
   int mh,mpos;
   int status=_menu_find(menu_handle,cmd,mh,mpos,'M');
   if (!status) {
     _menu_delete(mh,mpos);
   }
}

void _init_menu_attach_debugger(int menu_handle,int no_child_windows) {
   int found_menu_handle,found_menu_pos;
   status:=_menu_find(menu_handle,'debug_detach',found_menu_handle,found_menu_pos,'M');
   if (status || found_menu_pos<=0) {
      return;
   }
   --found_menu_pos;
   _menu_get_state(found_menu_handle,found_menu_pos,auto mf_flags,'P',auto caption,auto command,auto categories,auto help_command,auto help_message);
   _str first_word,rest;
   parse caption with first_word rest;
   if (strieq(first_word,'Windows')) {
      // this code is technically obsolete
      if (_isUnix()) {
         _menu_delete(found_menu_handle,found_menu_pos);
         //parse caption with auto first_word .;
      } else {
         _menu_set_state(found_menu_handle,found_menu_pos,mf_flags,'P',rest,command, categories,help_command,help_message);
         --found_menu_pos;
      }
   }
   _menu_get_state(found_menu_handle,found_menu_pos,mf_flags,'P',caption,command,categories,help_command,help_message);
   parse caption with first_word rest;
   if (strieq(first_word,'Unix')) {
      // this code is technically obsolete
      if (_isWindows()) {
         _menu_delete(found_menu_handle,found_menu_pos);
         //parse caption with auto first_word .;
      } else {
         _menu_set_state(found_menu_handle,found_menu_pos,mf_flags,'P',rest,command, categories,help_command,help_message);
         //--found_menu_pos;
      }
   }
   _menu_get_state(found_menu_handle,found_menu_pos,mf_flags,'P',caption,command,categories,help_command,help_message);
   parse caption with first_word rest;
   if (strieq(first_word,'&Attach')) {
      if (!_is_lldb_debugger_supported()) {
         // LLDB is only supported on MacOS
         menu_hide_debug_command(found_menu_handle, "debug_executable lldb");
         menu_hide_debug_command(found_menu_handle, "debug_corefile lldb");
         menu_hide_debug_command(found_menu_handle, "debug_attach lldb");
         menu_hide_debug_command(found_menu_handle, "debug_remote lldb");
      }
      if (!_isWindows()) {
         // WinDbg is only on Windows
         menu_hide_debug_command(found_menu_handle, "debug_executable windbg");
         menu_hide_debug_command(found_menu_handle, "debug_corefile windbg");
         menu_hide_debug_command(found_menu_handle, "debug_attach windbg");
         menu_hide_debug_command(found_menu_handle, "debug_remote windbg");
      } else {
         // core file commands are only on Unix
         menu_hide_debug_command(found_menu_handle, "debug_corefile lldb");
         menu_hide_debug_command(found_menu_handle, "debug_corefile gdb");
      }
   }
}

/**
 * @return 
 * Return 'true' if LLDB debuggin is supported on this platform. 
 * Currently, it is only available on macOS and Linux 64-bit.
 * 
 */
bool _is_lldb_debugger_supported()
{
   // no debugging support at all?
   if (!_haveDebugging()) return false;

   // macOS
   if (_isMac()) {
      return true;
   }

   // Unix platforms
   if (_isUnix()) {
      // Linux, 64-bit
      if (_isLinux() && machine_bits() == "64") {
         return true;
      }
   }

   // Windows platforms
   if (_isWindows()) {
      // Windows, 32-bit (placeholder)
      if (machine_bits() == "32") {
         return false;
      }
   }

   // gloom, dispair, and agony on me
   return false;
}

// For JDWP projects, should the debugger use the location cache
// to resolve breakpoints lazily?
bool debug_should_use_location_cache()
{
   ph := _ProjectHandle();

   if (ph < 0) {
      return false;
   }

   ind := find_index('GetCurrentConfigName', PROC_TYPE);
   if (ind > 0) {
      // Required for setting breakpoints in Kotlin.
      return _ProjectGet_Type(ph, call_index(ind)) == 'kotlin';
   }
   return false;
}

