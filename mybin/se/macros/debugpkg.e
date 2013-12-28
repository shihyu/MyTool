////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50681 $
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
#include "eclipse.sh"
#import "codehelp.e"
#import "context.e"
#import "debug.e"
#import "debuggui.e"
#import "listproc.e"
#import "markfilt.e"
#import "mouse.e"
#import "projutil.e"
#import "setupext.e"
#import "slickc.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "toolbar.e"
#import "window.e"
#import "se/tags/TaggingGuard.e"
#import "sc/editor/LockSelection.e"
#endregion


///////////////////////////////////////////////////////////////////////////
// Functions for enabling and disabling debugging related commands
//
int _OnUpdate_debug_restart(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, "debug-restart",
                         "Restarts program in debugger", "&Restart",
                         "Starts program in debugger",   "&Restart");


   return (debug_active() && !debug_is_remote())? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_suspend(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("suspend");
   return(debug_active() && !debug_is_suspended() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_suspend_thread(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("suspend");
   return(debug_active() && !debug_is_suspended() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_go(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, command,
                         "Continues the program",      "&Continue",
                         "Starts program in debugger", "&Start");

   if (!debug_active()) {
      return (_project_DebugCallbackName!='' && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   boolean supported = debug_session_is_implemented("continue");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_continue_thread(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("continue");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_interrupt(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("interrupt");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_monitors(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("update_monitors");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_stop(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   boolean supported = debug_session_is_implemented("terminate");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_attach(CMDUI &cmdui,int target_wid,_str command)
{
   //int index=find_index('_debug_'_project_DebugCallbackName'_attach_form',oi2type(OI_FORM));
   //if (!index) {
   //   return MF_GRAYED;
   //}
   return MF_ENABLED;
}
int _OnUpdate_debug_detach(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("detach");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_reload(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("reload");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_into(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, "debug-step-into",
                         "Step into the next statement",                   "Step &Into",
                         "Starts program in debugger and steps into code", "Step &Into");

   if (!debug_active()) {
      return (_project_DebugCallbackName!='' && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   boolean supported = debug_session_is_implemented("step_into");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_instr(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   boolean supported = debug_session_is_implemented("step_instr");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_deep(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   boolean supported = debug_session_is_implemented("step_deep");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_over(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   boolean supported = debug_session_is_implemented("step_over");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_out(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }

   boolean supported = debug_session_is_implemented("step_out");
   return(debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_past(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_set_instruction_pointer(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!debug_active()) {
      return(MF_GRAYED);
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   // warn them if they are attempting to move outside of the current file
   int thread_id = dbg_get_cur_thread();
   int frame_id  = dbg_get_cur_frame(thread_id);
   _str frame_name='', unused='', frame_file='';
   int frame_line=0;
   dbg_get_frame_path(thread_id, frame_id, frame_file, frame_line);
   if (!file_eq(_strip_filename(frame_file, 'P'), _strip_filename(p_buf_name, 'P'))) {
      return MF_GRAYED;
   }
   // make sure we have the callback
   boolean supported = debug_session_is_implemented("set_instruction_pointer");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_run_to_cursor(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, "debug-run-to-cursor",
                         "Continue until line cursor is on", "&Run to Cursor",
                         "Starts program in debugger and runs until line cursor is on", "&Run to Cursor");

   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!debug_active()) {
      return (_project_DebugCallbackName!='' && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return(/*debug_active() &&*/ debug_is_suspended() && !debug_is_corefile() && !_no_child_windows() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_toggle_disassembly(CMDUI &cmdui,int target_wid,_str command)
{
   if (!debug_active()) {
      return MF_GRAYED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (isEclipsePlugin()) {
      return(MF_ENABLED);
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   int checked = MF_UNCHECKED;
   if (dbg_have_updated_disassembly(_mdi.p_child.p_buf_name) &&
       dbg_toggle_disassembly(_mdi.p_child.p_buf_name, -1)) {
      checked = MF_CHECKED;
   }
   boolean supported = debug_session_is_implemented("update_disassembly");
   return (supported)? MF_ENABLED|checked:MF_GRAYED|checked;
}
int _OnUpdate_debug_toggle_hex(CMDUI &cmdui,int target_wid,_str command)
{
   int checked = (dbg_get_global_format() == VSDEBUG_BASE_HEXADECIMAL)? MF_CHECKED:0;
   return (debug_active())? MF_ENABLED|checked:MF_GRAYED|checked;
}
int _OnUpdate_debug_toggle_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!_no_child_windows() && 
       _mdi.p_child._LanguageInheritsFrom('e') && 
       _get_extension(_mdi.p_child.p_buf_name)!='sh') {
      return MF_ENABLED;
   }
   if (isEclipsePlugin()) {
      return(MF_ENABLED);
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_toggle_breakpoint3(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!_no_child_windows() && 
       _mdi.p_child._LanguageInheritsFrom('e') && 
       _get_extension(_mdi.p_child.p_buf_name)!='sh') {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_toggle_breakpoint_enabled(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!_mdi.p_child._isdebugging_supported()) {
      return(MF_GRAYED);
   }
   if (!_no_child_windows() && 
       _mdi.p_child._LanguageInheritsFrom('e') && 
       _get_extension(_mdi.p_child.p_buf_name)!='sh') {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   if (!supported) {
      return MF_GRAYED;
   }

   // Are we in disassembly?
   _str address = _mdi.p_child.debug_get_disassembly_address();
   boolean enabled=false;
   int breakpoint_id=dbg_find_breakpoint(_mdi.p_child.p_buf_name,_mdi.p_child.p_RLine,enabled,0,address);
   return (breakpoint_id > 0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_breakpoints(cmdui, target_wid, command);
}
int _OnUpdate_proctree_set_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_breakpoints(cmdui, target_wid, command);
}
int _OnUpdate_cb_set_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_breakpoints(cmdui, target_wid, command);
}
int _OnUpdate_debug_exceptions(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_exception(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_exceptions(cmdui,target_wid,command);
}
int _OnUpdate_debug_clear_all_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_breakpoints()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_disable_all_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_breakpoints()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_clear_all_exceptions(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_exceptions()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_disable_all_exceptions(CMDUI &cmdui,int target_wid,_str command)
{
   //if (_project_DebugCallbackName=='' || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   boolean supported = debug_session_is_implemented("disable_breakpoint");
   return (supported && dbg_get_num_exceptions()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_watch(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("update_watches");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_watchpoint(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("enable_watchpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_props(CMDUI &cmdui,int target_wid,_str command)
{
   return debug_active()? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_show_next_statement(CMDUI &cmdui,int target_wid,_str command)
{
   //debug_gui_stack_update_buttons();
   boolean supported = debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      int thread_id=dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      int no_of_frames=dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      int frame_id=dbg_get_cur_frame(thread_id);
      if (frame_id <= 0 || frame_id > no_of_frames) {
         return MF_GRAYED;
      }
      _str file_name='';
      int line_number=0;
      int status=dbg_get_frame_path(thread_id,frame_id,file_name,line_number);
      if (status || file_name=='' || line_number<0) {
         return MF_GRAYED;
      }
      return MF_ENABLED;
   }
   return MF_GRAYED;
}
int _OnUpdate_debug_top(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_up(cmdui,target_wid,command);
}
int _OnUpdate_debug_up(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      int thread_id=dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      int no_of_frames=dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      int frame_id=dbg_get_cur_frame(thread_id);
      if (frame_id <= 1) {
         return MF_GRAYED;
      }
      return MF_ENABLED;
   }
   return MF_GRAYED;
}
int _OnUpdate_debug_down(CMDUI &cmdui,int target_wid,_str command)
{
   boolean supported = debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      int thread_id=dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      int no_of_frames=dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      int frame_id=dbg_get_cur_frame(thread_id);
      if (frame_id<=0 || frame_id+1 > no_of_frames) {
         return MF_GRAYED;
      }
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

int _OnUpdate_debug_show_memory(CMDUI& cmdui, int target_wid, _str command)
{
   boolean supported = debug_session_is_implemented("update_memory");
   return ( supported ? MF_ENABLED : MF_GRAYED );
}


///////////////////////////////////////////////////////////////////////////
// debugger utility functions
//

/**
 * Find the package-specific function with the given name.
 * The package-specific functions are named using the following
 * convention:
 * <pre>
 *    _dbg_&lt;package&gt;_&lt;function_name&gt;
 * </pre>
 *
 * @param function_name    name of function to find (method name)
 *
 * @return function index to call using "call_index",
 *         0 if no such function, or not in debugging mode,
 */
int debug_find_function(_str debug_function, _str debugger_mode='')
{
   int index = 0;
   if (debugger_mode != '') {
      index = find_index("dbg_"debugger_mode"_"debug_function,PROC_TYPE);
      if (index && index_callable(index)) {
         return(index);
      }
   }
   index = find_index("dbg_"_project_DebugCallbackName"_"debug_function,PROC_TYPE);
   if (!index || !index_callable(index)) {
      return(0);
   }
   return(index);
}


///////////////////////////////////////////////////////////////////////////
// Surrogate functions that are used to call the package-specific
// functions for implementing a debugger.
//

/**
 * Kill the process and stop the debugger
 * <pre>
 *    dbg_&lt;package&gt;_finalize();
 * </pre>
 *
 * @return 0 on success, <0 on error.
 */
int debug_pkg_finalize()
{
   // close Slick-C editor instance, if it was
   // spawned temporarily just to debug Slick-C
   do_exit := slickc_debug_detach();

   // package-specific shutdown
   int session_id=dbg_get_current_session();
   int status = dbg_session_finalize(session_id);

   // clear out all the debug toolbars
   debug_gui_clear_registers();
   debug_gui_clear_memory();
   debug_gui_clear_classes();
   debug_gui_clear_threads();
   debug_gui_clear_locals();
   debug_gui_clear_members();
   debug_gui_clear_autovars();
   debug_gui_clear_stack();
   debug_gui_clear_registers();
   debug_gui_clear_memory();

   // final cleanup
   dbg_finalize();

   // close Slick-C editor instance, if it was
   // spawned temporarily just to debug Slick-C
   if (do_exit) {
      tbDebugSwitchMode(false,false);
      safe_exit();
   }

   // that's all folks
   return(status);
}

/**
 * Initialize the current debugging package
 * <pre>
 *    dbg_&lt;package&gt;_initialize(host_or_prog, port_or_pid, args, timeout);
 * </pre>
 *
 * @param host_or_prog     Name of host to connect to, "" for localhost
 *                         or path to program to debug
 * @param port_or_pid      Port to connect to if using sockets
 *                         of if program being debugged, PID to attach to
 * @param arguments        Arguments to pass to program
 * @param timeout          Timeout for socket connection and communication
 * @param debugger_path    Path to debugger executable
 * @param debugger_args    Additional arguments needed to invoke debugger 
 * @param working_dir      Directory to run the program in 
 *
 * @return 0 on success, <0 on error.
 */
int debug_pkg_initialize(_str host_or_prog, _str port_or_pid, 
                         _str arguments, int timeout, 
                         _str debugger_path, _str debugger_args, 
                         _str working_dir=null)
{
   // initialize/load the vsdebug DLL
   int status=debug_maybe_initialize(true);
   if (status) {
      return(status);
   }

   // make sure that the JVM is started and wating for connection
   loop_until_on_last_process_buffer_command();

   // delegate to the DLL session management function
   int session_id=dbg_get_current_session();
   status = dbg_session_initialize(session_id,
                                   host_or_prog, port_or_pid,
                                   arguments, timeout*1000,
                                   debugger_path, debugger_args, 
                                   working_dir);

   // return result
   return(status);
}
/**
 * Get the current version of the debugger
 * <pre>
 *    dbg_&lt;package&gt;_version(_str &description,
 *                          _str &major_version, _str &minor_version,
 *                          _str &runtime_version, _str &debugger_name);
 * </pre>
 */
int debug_pkg_update_version()
{
   // nothing to update?
   CTL_FORM wid=debug_gui_props_wid();
   if (!wid) {
      return(0);
   }
   // version information required
   _str description='';
   _str major_version='';
   _str minor_version='';
   _str runtime_version='';
   _str debugger_name='';

   // pass the information to the update method
   int session_id = dbg_get_current_session();
   if (debug_active()) {
      int status = dbg_session_version(session_id, description, 
                                       major_version, minor_version, 
                                       runtime_version, debugger_name);
      if (status) {
         return(status);
      }
   }

   // update the properties dialog
   wid.debug_gui_update_version(description,major_version,minor_version,runtime_version,debugger_name);
   return(0);
}
int debug_pkg_enable_breakpoint(int breakpoint_id, boolean quiet=false)
{
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_breakpoint_enabled(breakpoint_id,1);
   }

   // call the session specific command to enable the breakpoint
   int session_id = dbg_get_current_session();
   int status = dbg_session_enable_breakpoint(session_id, breakpoint_id);

   // special case for Java, class not yet loaded
   if (quiet && status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=='jdwp') {
      status=dbg_set_breakpoint_enabled(breakpoint_id,1);
   }

   // that's all folks
   return(status);
}
int debug_pkg_disable_breakpoint(int breakpoint_id)
{
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_breakpoint_enabled(breakpoint_id,0);
   }

   // call the session specific command to disable the breakpoint
   int session_id = dbg_get_current_session();
   int status = dbg_session_disable_breakpoint(session_id, breakpoint_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=='jdwp') {
      status=dbg_set_breakpoint_enabled(breakpoint_id,0);
   }

   // that's all folks
   return(status);
}
int debug_pkg_enable_exception(int exception_id)
{
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_exception_enabled(exception_id,1);
   }

   // call the session specific command to enable the exception
   int session_id = dbg_get_current_session();
   int status = dbg_session_enable_exception(session_id, exception_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=='jdwp') {
      status=dbg_set_exception_enabled(exception_id,1);
   }

   // that's all folks
   return(status);
}
int debug_pkg_disable_exception(int exception_id)
{
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_exception_enabled(exception_id,0);
   }

   // call the session specific command to enable the exception
   int session_id = dbg_get_current_session();
   int status = dbg_session_disable_exception(session_id, exception_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=='jdwp') {
      status=dbg_set_exception_enabled(exception_id,0);
   }

   // that's all folks
   return(status);
}
int debug_pkg_step_out()
{
   int thread_id=dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_step_out(session_id, thread_id);
}
int debug_pkg_step_over()
{
   int thread_id=dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_step_over(session_id, thread_id);
}
int debug_pkg_step_into(boolean startingDebugger=false)
{
   int thread_id=dbg_get_cur_thread();
   if (!startingDebugger && thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_step_into(session_id, thread_id);
}
int debug_pkg_step_instr()
{
   int thread_id=dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_step_instruction(session_id, thread_id);
}
int debug_pkg_step_deep()
{
   int thread_id=dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_step_into_runtimes(session_id, thread_id);
}
int debug_pkg_set_instruction_pointer(int thread_id,int frame_id,
                                      _str class_name, _str function_name,
                                      _str file_name, int line_number, _str address)
{
   int session_id = dbg_get_current_session();
   return dbg_session_set_instruction_pointer(session_id, thread_id, frame_id, 
                                              class_name, function_name, 
                                              file_name, line_number, address);
}
int debug_pkg_suspend(int thread_id=0)
{
   int session_id = dbg_get_current_session();
   return dbg_session_suspend(session_id, thread_id);
}
int debug_pkg_continue(int thread_id=0)
{
   int session_id = dbg_get_current_session();
   return dbg_session_resume(session_id, thread_id);
}
int debug_pkg_interrupt(int thread_id)
{
   int session_id = dbg_get_current_session();
   return dbg_session_interrupt(session_id, thread_id);
}
int debug_pkg_terminate(int exit_code=0)
{
   int session_id = dbg_get_current_session();
   return dbg_session_terminate(session_id, exit_code);
}
int debug_pkg_detach()
{
   int session_id = dbg_get_current_session();
   return dbg_session_detach(session_id);
}
int debug_pkg_reload(_str file_name, int options)
{
   int session_id = dbg_get_current_session();
   return dbg_session_reload(session_id, file_name, options);
}
int debug_pkg_restart()
{
   int session_id = dbg_get_current_session();
   return dbg_session_restart(session_id);
}
int debug_pkg_update_threads()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_threads(session_id);
}

int debug_pkg_update_threadgroups()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_thread_groups(session_id);
}
int debug_pkg_update_threadnames()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_thread_names(session_id);
}
int debug_pkg_update_threadstates()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_thread_states(session_id);
}
int debug_pkg_update_stack(int thread_id)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   int session_id = dbg_get_current_session();
   return dbg_session_update_stack(session_id, thread_id);
}
int debug_pkg_update_classes()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_classes(session_id);
}
int debug_pkg_expand_class(_str class_path)
{
   int session_id = dbg_get_current_session();
   return dbg_session_expand_class(session_id, class_path);
}
int debug_pkg_expand_parents(int class_id)
{
   int session_id = dbg_get_current_session();
   return dbg_session_expand_parents(session_id, class_id);
}
int debug_pkg_update_watches(int thread_id, int frame_id,int tab_number)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }
   int session_id = dbg_get_current_session();
   return dbg_session_update_watches(session_id, thread_id, frame_id, tab_number);
}
int debug_pkg_eval_condition(int thread_id, int frame_id,_str expr)
{
   int session_id = dbg_get_current_session();
   return dbg_session_eval_condition(session_id, thread_id, frame_id, expr);
}
int debug_pkg_eval_expression(int thread_id, int frame_id,_str expr,_str &value)
{
   int session_id = dbg_get_current_session();
   return dbg_session_eval_expression(session_id, thread_id, frame_id, expr, value);
}
int debug_pkg_update_registers()
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_registers(session_id);
}
int debug_pkg_update_memory(_str address, int size)
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_memory(session_id, address, size);
}
int debug_pkg_update_autos(int thread_id, int frame_id)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   if (!dbg_session_is_name_implemented(session_id, "update_autos")) {
      return(STRING_NOT_FOUND_RC);
   }

   debug_find_autovars(thread_id,frame_id);

   return dbg_session_update_auto_watches(session_id, thread_id, frame_id);
}
int debug_pkg_update_disassembly(_str file_name, int num_lines)
{
   int session_id = dbg_get_current_session();
   return dbg_session_update_disassembly(session_id, file_name, 1, num_lines);
}
int debug_pkg_update_locals(int thread_id,int frame_id)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_update_locals(session_id, thread_id, frame_id);
}
int debug_pkg_update_members(int thread_id,int frame_id)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_update_members(session_id, thread_id, frame_id);
}
int debug_pkg_expand_local(int thread_id,int frame_id,_str local_path)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_expand_local(session_id, thread_id, frame_id, local_path);
}
int debug_pkg_expand_member(int thread_id,int frame_id,_str member_path)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_expand_member(session_id, thread_id, frame_id, member_path);
}
int debug_pkg_expand_watch(int thread_id,int frame_id,_str watch_path)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_expand_watch(session_id, thread_id, frame_id, watch_path);
}
int debug_pkg_expand_auto(int thread_id,int frame_id,_str autovar_path)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_expand_auto_watch(session_id, thread_id, frame_id, autovar_path);
}
int debug_pkg_modify_autovar(int thread_id,int frame_id,_str auto_path,_str new_value)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_modify_auto_watch(session_id, thread_id, frame_id, auto_path, new_value);
}
int debug_pkg_modify_watch(int thread_id,int frame_id,_str watch_path,_str new_value)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_modify_watch(session_id, thread_id, frame_id, watch_path, new_value);
}
int debug_pkg_modify_local(int thread_id,int frame_id,_str local_path,_str new_value)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_modify_local(session_id, thread_id, frame_id, local_path, new_value);
}
int debug_pkg_modify_member(int thread_id,int frame_id,_str member_path,_str new_value)
{
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   int session_id = dbg_get_current_session();
   return dbg_session_modify_member(session_id, thread_id, frame_id, member_path, new_value);
}
int debug_pkg_modify_field(_str field_path,_str new_value)
{
   int session_id = dbg_get_current_session();
   return dbg_session_modify_field(session_id, field_path, new_value);
}
int debug_pkg_modify_register(int register_id,_str new_value)
{
   int session_id = dbg_get_current_session();
   return STRING_NOT_FOUND_RC;
   //return dbg_session_modify_register(session_id, register_id, new_value);
}
int debug_pkg_resolve_path(_str file_name, _str &full_path)
{
   // now try searching using the extension specific function
   int session_id = dbg_get_current_session();
   int status = dbg_session_resolve_path(session_id, file_name, full_path);
   if (!status) {
      return(0);
   }

   // this would be a good place to search tag files or the project for this file
   full_path='';
   return(FILE_NOT_FOUND_RC);
}

/**
 * Get the last message from the debugger system
 */
_str debug_pkg_error_message()
{
   _str errmsg='';
   int session_id = dbg_get_current_session();
   dbg_session_error_message(session_id, errmsg);
   return errmsg;
}

/**
 * Get the user and system paths for this debugger
 */
int debug_pkg_get_paths(_str &cwd, _str &user, _str &sys)
{
   int session_id = dbg_get_current_session();
   int status = dbg_session_get_paths(session_id, cwd, user, sys);
   if (status) {
      cwd=user=sys='';
   }
   return status;
}

/**
 * Disable all the tree views that are not available to a particular package
 */
void debug_pkg_enable_disable_tabs()
{
   CTL_FORM  wid;
   CTL_SSTAB tab_wid;
   CTL_COMBO list_wid;
   int orig_tab;

   // enable watches if we have an "update_watches" callback
   wid=debug_gui_watches_wid();
   if (wid) {
      tab_wid=wid.debug_gui_tab();
      if (tab_wid) {
         boolean supported = debug_session_is_implemented("update_watches");
         orig_tab=tab_wid.p_ActiveTab;
         tab_wid.p_ActiveTab=0;
         tab_wid.p_ActiveEnabled=supported;
         tab_wid.p_ActiveTab=1;
         tab_wid.p_ActiveEnabled=supported;
         tab_wid.p_ActiveTab=2;
         tab_wid.p_ActiveEnabled=supported;
         tab_wid.p_ActiveTab=3;
         tab_wid.p_ActiveEnabled=supported;
         tab_wid.p_ActiveTab=orig_tab;
      }
   }

   // enable threads if we have an "update_threads" callback
   boolean update_threads_supported = debug_session_is_implemented("update_threads");
   wid=debug_gui_threads_wid();
   if (wid) {
      tbWidEnable(wid,update_threads_supported);
   }

   // disable threads combo boxes if we don't have threads support
   list_wid=debug_gui_stack_thread_list();
   if (list_wid) {
      list_wid.p_enabled=update_threads_supported;
   }

   // enable threads if we have an "update_stack" callback
   boolean update_stack_supported = debug_session_is_implemented("update_stack");
   wid=debug_gui_stack_wid();
   if (wid) {
      tbWidEnable(wid,update_stack_supported);
   }

   // enable thread combo boxes if we have an "update_stack" callback
   list_wid=debug_gui_local_stack_list();
   if (list_wid) {
      list_wid.p_enabled=update_stack_supported;
   }
   list_wid=debug_gui_members_stack_list();
   if (list_wid) {
      list_wid.p_enabled=update_stack_supported;
   }
   list_wid=debug_gui_auto_stack_list();
   if (list_wid) {
      list_wid.p_enabled=update_stack_supported;
   }

   // enable the classes tab if we have an "update_classes" callback
   wid=debug_gui_classes_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_classes");
      tbWidEnable(wid,supported);
   }

   // enable the registers tab if we have an "update_registers" callback
   wid=debug_gui_registers_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_registers");
      tbWidEnable(wid,supported);
   }

   // enable the memory tab if we have an "update_memory" callback
   wid=debug_gui_memory_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_memory");
      tbWidEnable(wid,supported);
   }

   // enable the auto-vars tab if we have an "update_autos" callback
   wid=debug_gui_autovars_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_autos");
      tbWidEnable(wid,supported);
   }

   // enable the locals tabs if we have an "update_locals" callback
   wid=debug_gui_locals_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_locals");
      tbWidEnable(wid,supported);
   }

   // enable the members tabs if we have an "update_members" callback
   wid=debug_gui_members_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("update_members");
      tbWidEnable(wid,supported);
   }

   // enable the breakpoints tab if we have an "enable_breakpoint" callback
   wid=debug_gui_breakpoints_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("enable_breakpoint");
      tbWidEnable(wid,supported);
   }
   wid=debug_gui_exceptions_wid();
   if (wid) {
      boolean supported = debug_session_is_implemented("enable_exception");
      tbWidEnable(wid,supported);
   }
}


///////////////////////////////////////////////////////////////////////////
// Functions for checking the availability of callbacks
//

/**
 * Check if the "enable_breakpoint" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_enable_breakpoint(_str msg=null)
{
   debug_maybe_initialize();
   boolean supported = debug_session_is_implemented("enable_breakpoint");
   if (!supported) {
      if (msg==null) msg="Breakpoints are not supported for this project.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "disable_breakpoint" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_disable_breakpoint(_str msg=null)
{
   debug_maybe_initialize();
   boolean supported = debug_session_is_implemented("disable_breakpoint");
   if (!supported) {
      if (msg==null) msg="Breakpoints are not supported for this project.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "enable_exception" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_enable_exception(_str msg=null)
{
   boolean supported = debug_session_is_implemented("enable_exception");
   if (!supported) {
      if (msg==null) msg="Exception breakpoints are not supported for this project.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "disable_exception" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_disable_exception(_str msg=null)
{
   boolean supported = debug_session_is_implemented("disable_exception");
   if (!supported) {
      if (msg==null) msg="Exception breakpoints are not supported for this project.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "update_watches" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_update_watches(_str msg=null)
{
   boolean supported = debug_session_is_implemented("update_watches");
   if (!supported) {
      if (msg==null) msg="Watches are not supported in this environment.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "enable_watchpoints" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_enable_watchpoints(_str msg=null)
{
   boolean supported = debug_session_is_implemented("enable_watchpoint");
   if (!supported) {
      if (msg==null) msg="Watchpoints are not supported in this environment.";
      if (msg!='') debug_message(msg,0,false);
      return(false);
   }
   return(true);
}
/**
 * Check if the "reload" callback is available and post
 * a message if it is not available or not supported in
 * this environment.
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
boolean debug_check_reload(_str msg=null)
{
   // check if reload is supported in this session
   boolean supported = debug_session_is_implemented("reload");

   // call debug_reload with empty arguments to test
   // if it is supported in this environment
   int status=0;
   if (supported) {
      status=dbg_session_reload(dbg_get_current_session(), '', 0);
   }

   // failure?
   if (!supported || status<0) {
      if (msg==null) msg="Edit and continue is not supported in this environment.";
      if (msg!='') debug_message(msg,0,false);
      return(false);  
   }

   // success!
   return(true);
}

struct MouseOverExpression
{
   int windowId;
   int bufferId;
   int lastModified;
   int mouse_x;
   int mouse_y;
   int line;
   int col;
   VS_TAG_IDEXP_INFO idexp_info;
   _str expr;
   _str tag_info;
   _str comment_info;
};

const MOUSEOVER_EXPRESSION_INFO_KEY="MOUSEOVER_EXPRESSION_INFO";

static _str EvaluateMouseExpression(MouseOverExpression &e)
{
   if (e.expr=="") {
      return('');
   }

   // color coding check
   left();
   cfg := _clex_find(0, 'g');
   right();
   switch (cfg) {
   case CFG_COMMENT:
   case CFG_STRING:
      if (p_LangId == 'docbook') break;
      if (p_LangId == ANT_LANG_ID) break;
      return "";
   case CFG_KEYWORD:
      if (e.expr=="this") break;
      if (!_LanguageInheritsFrom('e')) {
         return "";
      }
      if (!pos("p_", e.expr)) {
         return "";
      }
      break;
   }

   _str value='';
   if (debug_active() && debug_is_suspended() && e.expr!="") {
      // try each frame, because they could be mousing over
      // a local in a function higher up the call stack.
      int thread_id = dbg_get_cur_thread();
      int frame_id  = dbg_get_cur_frame(thread_id);
      int orig_frame_id = frame_id;
      int last_frame_id = frame_id;
      int frame_top = dbg_get_num_frames(thread_id);
      for (; frame_id <= frame_top; frame_id++) {
         // do not try this trick if the mouse is not in the file matching this stack frame
         dbg_get_frame_path(thread_id, frame_id, auto frame_file, auto frame_line);
         if (frame_id != orig_frame_id && !file_eq(_strip_filename(frame_file,'P'), _strip_filename(p_buf_name,'P'))) {
            continue;
         }
         // now try to evaluate the expression
         last_frame_id = frame_id;
         _str new_value='';
         status := debug_pkg_eval_expression(thread_id,frame_id,e.expr,new_value);
         if (!status) {
            value=new_value;
            break;
         }
      }
      // this has the (positive) side effect of 
      // restoring the original frame ID for GDB
      // only necessary if we had to try higher level stack frames
      if (last_frame_id != orig_frame_id) {
         _str dummy_value="";
         debug_pkg_eval_expression(thread_id,orig_frame_id,"0",dummy_value);
      }
   }

   _str result="";
   if (value!="") {
      result = e.expr" = "value;
   } else if (e.tag_info != "") {
      result = e.tag_info;
   } else {
      result = e.expr;
   }

   if (e.comment_info!=null && e.comment_info!='') {
      result = result:+"<hr>":+e.comment_info;
   }
   if (result==null) result="";
   return result;
}

_str debug_get_mouse_expr(int &cursor_x, int &width, _str *streamMarkerMessage=null)
{
   // make sure we have an editor control
   if (_no_child_windows() || !_isEditorCtl()) {
      return('');
   }
   // if we are not debugging, make sure this source file deserves mouse-over info
   if (!debug_active() && !(_GetCodehelpFlags() & VSCODEHELPFLAG_MOUSE_OVER_INFO)) {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, null, _mdi);
      return('');
   }
   // if we are debugging, make sure the option is turned on and we can display watches
   if (debug_active() && !(def_debug_options & VSDEBUG_OPTION_MOUSE_OVER_INFO)) {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, null, _mdi);
      return('');
   }
   if (debug_active() && !debug_check_update_watches() && !(_GetCodehelpFlags() & VSCODEHELPFLAG_MOUSE_OVER_INFO) ) {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, null, _mdi);
      return('');
   }

   // this is too slow and unneccesarily restrictive.
   /*
   int status=tag_read_db(_GetWorkspaceTagsFilename());
   if (!status) {
      _str date_tagged='';
      status=tag_get_date(p_buf_name,date_tagged);
      // IF this file is not in the workspace
      if(status) {
         say("debug_get_mouse_expr: r1");
         return('');
      }
      tag_close_db(null,true);
   }
   */
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);

   // probe for whether we can set a watch here or not
   // Make sure the current context is up-to-date
   int OrigLineNum=(int)point('L');
   int OrigCol=p_col;
   save_pos(auto MouseOverPos);

   int mx=mou_last_x('D');
   int my=mou_last_y('D');
   _map_xy(0,p_window_id,mx,my);
   sc.editor.LockSelection markLocked;

   // adjust screen position if we are scrolled
   if (p_scroll_left_edge >= 0) {
      _str line_pos,down_count,SoftWrapLineOffset;
      parse _scroll_page() with line_pos down_count SoftWrapLineOffset;
      goto_point(line_pos);
      down((int)down_count);
      set_scroll_pos(p_scroll_left_edge,0,(int)SoftWrapLineOffset);
      //p_scroll_left_edge= -1;
   }

   //save_pos(p);  DON'T save/restore position.  Caller needs to do this.
   p_cursor_y=my;
   p_cursor_x=mx;

   // check if we can use the last result
   mouse_line := (int)point('L');
   mouse_col  := p_col;
   MouseOverExpression *pLast = _GetDialogInfoHtPtr(MOUSEOVER_EXPRESSION_INFO_KEY, _mdi);
   if (pLast != null) {
      if (pLast->_isempty() || 
          pLast->windowId != p_window_id ||
          pLast->bufferId != p_buf_id ||
          pLast->lastModified != p_LastModified) {
         pLast = null;
      } else if ((pLast->mouse_x == mx && pLast->mouse_y == my) ||
                 (pLast->line == mouse_line && pLast->col == mouse_col)) {
         p_col=pLast->idexp_info.lastidstart_col;
         cursor_x=p_cursor_x;
         p_col+=length(pLast->idexp_info.lastid);
         width=p_cursor_x-cursor_x;
         if (isEclipsePlugin() && _eclipse_debug_active()) {
            temp := _eclipse_evaluate_expression(pLast->expr);
            if (temp != "") {
               return pLast->expr :+ " = " :+ temp;
            }
         } else {
            return EvaluateMouseExpression(*pLast);
         }
      }
   }

   // get the name of the current class and method
   _str expr='';
   _str tag_info='';
   _str comment_info='';
   _str cur_tag_name='';
   _str cur_type_name='';
   _str cur_context='';
   int cur_flags=0;
   int cur_type_id=0;
   _str cur_class='';
   _str cur_package='';
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   _reset_idle();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);

   if (tag_get_num_of_context()==0) {
      return('');
   }
   int status=tag_get_current_context(cur_tag_name,cur_flags,
                                      cur_type_name,cur_type_id,
                                      cur_context,cur_class,cur_package);

   // blow away the proc name if we are not in a proc
   if (status < 0 || !tag_tree_type_is_func(cur_type_name)) {
      cur_tag_name='';
   }

   // IF the mouse is inside a selection, get the selection text
   //say('p_line='p_line' p_col='p_col);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   if (select_active2() && _in_selection() && !(isEclipsePlugin() && _eclipse_debug_active())) {
      _get_selinfo(auto start_col, auto end_col, auto buf_id, '', auto buf_name, auto utf8, auto encoding, auto Noflines);
      if (Noflines != 1) {
         return('');
      }
      idexp_info.lastidstart_col = start_col;

      p_col=start_col;
      cursor_x=p_cursor_x;
      _end_select();
      if (_select_type('','I')) {
         ++p_col;
      }
      width=p_cursor_x-cursor_x;

      //say('start_col='start_col' end_col='end_col);
      expr=_expand_tabsc(start_col,end_col-start_col+_select_type('','I'),'S');
      idexp_info.lastid=expr;

   } else {

      // set a timeout for the amount of time to spend looking up symbols
      _SetTimeout(def_tag_max_list_members_time);

      // get the expression to evaluate
      typeless r1,r2,r3,r4,r5;
      save_search(r1,r2,r3,r4,r5);

      _str ext;
      struct VS_TAG_RETURN_TYPE visited:[];
      status=_Embeddedget_expression_info(false, ext, idexp_info, visited);
      restore_search(r1,r2,r3,r4,r5);
      if (status) {
         _SetTimeout(0);
         return('');
      }
      if (idexp_info.lastidstart_col <= 0) {
         _SetTimeout(0);
         return('');
      }

      // check if we still have the same expression information
      if (pLast != null && tag_idexp_info_equal(pLast->idexp_info, idexp_info)) {
         p_col=idexp_info.lastidstart_col;
         cursor_x=p_cursor_x;
         p_col+=length(idexp_info.lastid);
         width=p_cursor_x-cursor_x;
         if (isEclipsePlugin() && _eclipse_debug_active()) {
            temp := _eclipse_evaluate_expression(pLast->expr);
            if (temp != "") {
               _SetTimeout(0);
               return pLast->expr :+ " = " :+ temp;
            }
         } else {
            _SetTimeout(0);
            return EvaluateMouseExpression(*pLast);
         }
      }

      // check if we should bring up function help
      if (idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
         _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, null, _mdi);
         p_col=idexp_info.lastidstart_col;
         cursor_x=p_cursor_x;
         p_col+=length(idexp_info.lastid);
         width=p_cursor_x-cursor_x;
         status=search('(','>@h');
         if (!status) {
            _str streamMessage = null;
            if (streamMarkerMessage != null) {
               streamMessage = *streamMarkerMessage;
               *streamMarkerMessage = "";
            }
            _do_function_help(false,false,false,false,true,cursor_x,width,OrigLineNum,OrigCol,MouseOverPos,streamMessage);
            _SetTimeout(0);
            return('');
            //status=DEBUG_WATCH_NOT_ALLOWED_RC;
            //debug_message("Can not watch a function",status);
         }
      }

      _UpdateLocals(true);
      p_col=idexp_info.lastidstart_col;
      cursor_x=p_cursor_x;
      status = _Embeddedfind_context_tags(idexp_info.errorArgs,
                                          idexp_info.prefixexp,idexp_info.lastid,
                                          idexp_info.lastidstart_offset,
                                          idexp_info.info_flags,
                                          idexp_info.otherinfo,
                                          false,1,
                                          true,p_LangCaseSensitive);
      if (status >= 0 && tag_get_num_of_matches() > 0) {
         VS_TAG_BROWSE_INFO cm;
         tag_browse_info_init(cm);

         //int i,n=tag_get_num_of_matches();
         //for (i=1; i<=n; i++) {
            tag_get_match_info(1, cm);
            //if (taginfo!='') {
            //   taginfo=taginfo:+"<br>";
            //}
            tag_info=extension_get_decl(p_LangId,cm);
            tag_info="<a href=\"<<pushtag "cm.member_name" "p_line" "p_col"\" lbuttondown><img src=\"vslick://_push_tag.ico\"></a>&nbsp;":+tag_info;
         //}
         //tag_info=stranslate(tag_info,"&nbsp;"," ");


         // Now get the comment for this tag
         if (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS) {
            int comment_flags=0;
            if (cm.file_name!='') {
               _ExtractTagComments2(comment_flags,
                                    comment_info, 100,
                                    cm.member_name, cm.file_name, cm.line_no
                                    );
            }
            if (comment_info!='') {
               if (p_LangId == ANT_LANG_ID) {
                  comment_info = stranslate(comment_info,'','<!--');
                  comment_info = stranslate(comment_info,'','-->');
               }
               _str param_name=(cm.type_name=='param')? cm.member_name:'';
               _make_html_comments(comment_info,comment_flags,cm.return_type,param_name);
            }
         }


         if (_LanguageInheritsFrom('e') && idexp_info.prefixexp=='' && !pos('-',tag_info)) {
            int var_index=find_index(idexp_info.lastid,VAR_TYPE|GVAR_TYPE);
            if (var_index) {
               typeless v=_get_var(var_index);
               if (v._varformat()==VF_EMPTY) v="(null)";
               if (VF_IS_INT(v)) {
                  tag_info=tag_info:+" = <b>"v"</b>";
               } else if (v._varformat()==VF_LSTR) {
                  tag_info=tag_info:+" = <b>\""v"\"</b>";
               }
            }
         }
      }

      // find the tag under the cursor
      expr=idexp_info.prefixexp:+idexp_info.lastid;

      p_col=idexp_info.lastidstart_col;
      cursor_x=p_cursor_x;
      p_col+=length(idexp_info.lastid);
      width=p_cursor_x-cursor_x;
      _SetTimeout(0);
   }

   // save the results, evaluate the expression in the debugger, and return
   MouseOverExpression e;
   e.windowId     = p_window_id;
   e.bufferId     = p_buf_id;
   e.lastModified = p_LastModified;
   e.mouse_x      = mx;
   e.mouse_y      = my;
   e.line         = mouse_line;
   e.col          = mouse_col;
   e.idexp_info   = idexp_info;
   e.expr         = expr;
   e.tag_info     = tag_info;
   e.comment_info = comment_info;
   // this should be a little better...like if it fails, do the normal
   // stuff
   if (isEclipsePlugin() && _eclipse_debug_active()) {
      expr = _eclipse_evaluate_expression(expr);
      if (expr != "") {
         expr = e.expr :+ " = " :+ expr;
      }
   } else {
      expr = EvaluateMouseExpression(e);
   }
   if (expr == idexp_info.prefixexp:+idexp_info.lastid) {
      return '';
   }
   if (expr != "") {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, e, _mdi);
   }
   return expr;
}

int debug_pkg_do_command(_str command, var reply, _str &errmsg, boolean parse_reply)
{
   int session_id = dbg_get_current_session();
   return dbg_session_do_command(session_id, command,reply, errmsg, parse_reply);
}

int debug_pkg_print_output(_str s)
{
   int session_id = dbg_get_current_session();
   int status = dbg_session_print_output(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      _str msg = "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_print_info(_str s)
{
   int session_id = dbg_get_current_session();
   int status = dbg_session_print_info(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      _str msg = "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_print_error(_str s)
{
   int session_id = dbg_get_current_session();
   int status = dbg_session_print_error(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      _str msg = "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_input_direct(_str s)
{
   int session_id = dbg_get_current_session();
   int status = dbg_session_send_direct_input(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      _str msg = "Direct debug io tty input is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

