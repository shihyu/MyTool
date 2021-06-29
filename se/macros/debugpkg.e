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
#import "math.e"
#import "menu.e"
#import "mouse.e"
#import "picture.e"
#import "projutil.e"
#import "refactor.e"
#import "seek.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbview.e"
#import "toolbar.e"
#import "window.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/tags/TaggingGuard.e"
#import "sc/editor/LockSelection.e"
#import "se/ui/toolwindow.e"
#endregion

/**
 * In non-zero, hovering over a number in the source code will 
 * show a popup that shows the number in multiple bases. 
 */
bool def_number_base_popups = true;

///////////////////////////////////////////////////////////////////////////
// Functions for enabling and disabling debugging related commands
//
int _OnUpdate_debug_restart(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
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
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("suspend");
   return(debug_active() && !debug_is_suspended() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_suspend_thread(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("suspend");
   return(debug_active() && !debug_is_suspended() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_go(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, command,
                         "Continues the program",      "&Continue",
                         "Starts program in debugger", "&Start");

   if (!debug_active()) {
      return (_project_DebugCallbackName!="" && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   supported := debug_session_is_implemented("continue");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_run_with_arguments(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   if (!debug_active()) {
      return (_project_DebugCallbackName!="" && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   return MF_GRAYED;
}
int _OnUpdate_debug_continue_thread(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("continue");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_interrupt(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("interrupt");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_monitors(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_monitors");
   return (debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_stop(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   supported := debug_session_is_implemented("terminate");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}

int _OnUpdate_debug_executable(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return MF_ENABLED;
}
int _OnUpdate_debug_executable_lldb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_executable(cmdui,target_wid,command);
}
int _OnUpdate_debug_executable_gdb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_executable(cmdui,target_wid,command);
}
int _OnUpdate_debug_executable_java(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_executable(cmdui,target_wid,command);
}
int _OnUpdate_debug_executable_windbg(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!_isWindows()) {
      return MF_GRAYED;
   }
   return _OnUpdate_debug_executable(cmdui,target_wid,command);
}

int _OnUpdate_debug_corefile(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return MF_ENABLED;
}
int _OnUpdate_debug_corefile_lldb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_corefile(cmdui,target_wid,command);
}
int _OnUpdate_debug_corefile_gdb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_corefile(cmdui,target_wid,command);
}
int _OnUpdate_debug_dumpfile_windbg(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!_isWindows()) {
      return MF_GRAYED;
   }
   return _OnUpdate_debug_corefile(cmdui,target_wid,command);
}

int _OnUpdate_debug_attach(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   //int index=find_index('_debug_'_project_DebugCallbackName'_attach_form',oi2type(OI_FORM));
   //if (!index) {
   //   return MF_GRAYED;
   //}
   return MF_ENABLED;
}
int _OnUpdate_debug_attach_lldb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_attach(cmdui,target_wid,command);
}
int _OnUpdate_debug_attach_gdb(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_attach(cmdui,target_wid,command);
}
int _OnUpdate_debug_attach_jdwp(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_attach(cmdui,target_wid,command);
}
int _OnUpdate_debug_attach_mono(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_attach(cmdui,target_wid,command);
}
int _OnUpdate_debug_attach_windbg(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!_isWindows()) {
      return MF_GRAYED;
   }
   return _OnUpdate_debug_attach(cmdui,target_wid,command);
}

int _OnUpdate_debug_detach(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("detach");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_disconnect(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("disconnect");
   return(debug_active() && debug_is_remote() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_reload(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("reload");
   return(debug_active() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_into(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, "debug-step-into",
                         "Step into the next statement",                   "Step &Into",
                         "Starts program in debugger and steps into code", "Step &Into");

   if (!debug_active()) {
      return (_project_DebugCallbackName!="" && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   supported := debug_session_is_implemented("step_into");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_instr(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   bool supported = (debug_session_is_implemented("step_instr") && 
                        debug_session_is_implemented("update_disassembly"));
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_deep(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   supported := debug_session_is_implemented("step_deep");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_over(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   supported := debug_session_is_implemented("step_over");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_out(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }

   supported := debug_session_is_implemented("step_out");
   return(debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_step_past(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   return (debug_active() && debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_set_instruction_pointer(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:true)) {
      return(MF_GRAYED);
   }
   if (!debug_active()) {
      return(MF_GRAYED);
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   // warn them if they are attempting to move outside of the current file
   thread_id := dbg_get_cur_thread();
   frame_id := dbg_get_cur_frame(thread_id);
   frame_name := unused := frame_file := "";
   frame_line := 0;
   dbg_get_frame_path(thread_id, frame_id, frame_file, frame_line);
   if (!_file_eq(_strip_filename(frame_file, 'P'), _strip_filename(p_buf_name, 'P'))) {
      return MF_GRAYED;
   }
   // make sure we have the callback
   supported := debug_session_is_implemented("set_instruction_pointer");
   return (debug_is_suspended() && !debug_is_corefile() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_run_to_cursor(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   debug_modify_captions(cmdui, "debug-run-to-cursor",
                         "Continue until line cursor is on", "&Run to Cursor",
                         "Starts program in debugger and runs until line cursor is on", "&Run to Cursor");

   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:true)) {
      return(MF_GRAYED);
   }
   if (!debug_active()) {
      return (_project_DebugCallbackName!="" && _project_DebugConfig)? MF_ENABLED:MF_GRAYED;
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   return(/*debug_active() &&*/ debug_is_suspended() && !debug_is_corefile() && !_no_child_windows() && supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_toggle_disassembly(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (!debug_active()) {
      return MF_GRAYED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:true)) {
      return(MF_GRAYED);
   }
   if (isEclipsePlugin()) {
      return(MF_ENABLED);
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   int checked = MF_UNCHECKED;
   if (dbg_have_updated_disassembly(target_wid.p_buf_name) &&
       dbg_toggle_disassembly(target_wid.p_buf_name, -1)) {
      checked = MF_CHECKED;
   }
   supported := debug_session_is_implemented("update_disassembly");
   return (supported)? MF_ENABLED|checked:MF_GRAYED|checked;
}
int _OnUpdate_debug_toggle_hex(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   int checked = (dbg_get_global_format() == VSDEBUG_BASE_HEXADECIMAL)? MF_CHECKED:0;
   return (debug_active())? MF_ENABLED|checked:MF_GRAYED|checked;
}
int _OnUpdate_debug_toggle_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:false)) {
      return(MF_GRAYED);
   }
   if (isEclipsePlugin()) {
      return(MF_ENABLED);
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   if (!supported) return MF_GRAYED;
   if (!cmdui.menu_handle) return MF_ENABLED;

   bp_flags := target_wid.scBPMQFlags();
   _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,auto flags,"p",auto caption);
   parse caption with caption "\t" auto keys;
   if (bp_flags & (VSBPFLAG_BREAKPOINT|VSBPFLAG_BREAKPOINTDISABLED)) {
      caption = "Clear Breakpoint";
   } else {
      caption = "Set Breakpoint";
   }
   _menu_set_state(cmdui.menu_handle,
                   cmdui.menu_pos,
                   MF_ENABLED,
                   "p",
                   caption :+ "\t" :+ keys);
   return MF_ENABLED;
}
int _OnUpdate_debug_toggle_breakpoint3(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:false)) {
      return(MF_GRAYED);
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   if (!supported) return MF_GRAYED;
   if (!cmdui.menu_handle) return MF_ENABLED;

   // Are we on an existing breakpoint?
   address := target_wid.debug_get_disassembly_address();
   enabled := false;
   breakpoint_id := dbg_find_breakpoint(target_wid.p_buf_name,target_wid.p_RLine,enabled,0,address);

   _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,auto flags,"p",auto caption);
   parse caption with caption "\t" auto keys;
   if (breakpoint_id <= 0) {
      caption = "Set Breakpoint";
   } else if (enabled) {
      caption = "Disable Breakpoint";
   } else {
      caption = "Clear Breakpoint";
   }
   _menu_set_state(cmdui.menu_handle,
                   cmdui.menu_pos,
                   MF_ENABLED,
                   "p",
                   caption :+ "\t" :+ keys);
   return MF_ENABLED;
}
int _OnUpdate_debug_toggle_breakpoint_enabled(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:false)) {
      return(MF_GRAYED);
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   if (!supported) return MF_GRAYED;

   // Are we on an existing breakpoint?
   address := target_wid.debug_get_disassembly_address();
   enabled := false;
   breakpoint_id := dbg_find_breakpoint(target_wid.p_buf_name,target_wid.p_RLine,enabled,0,address);
   if (breakpoint_id <= 0) return MF_GRAYED;
   if (!cmdui.menu_handle) return MF_ENABLED;

   _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,auto flags,"p",auto caption);
   parse caption with caption "\t" auto keys;
   if (enabled) {
      caption = "Disable Breakpoint";
   } else {
      caption = "Enable Breakpoint";
   }
   _menu_set_state(cmdui.menu_handle,
                   cmdui.menu_pos,
                   MF_ENABLED,
                   "p",
                   caption :+ "\t" :+ keys);
   return MF_ENABLED;
}
int _OnUpdate_debug_edit_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!target_wid._isdebugging_supported(strict:false)) {
      return(MF_GRAYED);
   }
   if (isEclipsePlugin()) {
      return MF_ENABLED;
   }
   supported := debug_session_is_implemented("enable_breakpoint");
   if (supported) {
       // Are we in disassembly?
      address := target_wid.debug_get_disassembly_address();
      enabled := false;
      breakpoint_id := dbg_find_breakpoint(target_wid.p_buf_name,target_wid.p_RLine,enabled,0,address);
      if (breakpoint_id > 0) {
         return MF_ENABLED;
      }
   }
   return MF_GRAYED;
}
int _OnUpdate_debug_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("enable_breakpoint");
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
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("enable_breakpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_exception(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_exceptions(cmdui,target_wid,command);
}
int _OnUpdate_debug_clear_watches(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   supported := debug_session_is_implemented("update_watches");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_delete_breakpoint(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_clear_all_breakpoints(cmdui,target_wid,command);
}
int _OnUpdate_debug_delete_exception(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_clear_all_exceptions(cmdui,target_wid,command);
}
int _OnUpdate_debug_edit_exception(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_debug_clear_all_exceptions(cmdui,target_wid,command);
}
int _OnUpdate_debug_clear_all_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_breakpoints()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_disable_all_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_breakpoints()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_clear_all_exceptions(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("enable_breakpoint");
   return (supported && dbg_get_num_exceptions()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_disable_all_exceptions(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if(isEclipsePlugin()) {
      return MF_ENABLED;
   }
   //if (_project_DebugCallbackName=="" || !_project_DebugConfig) {
   //   return MF_GRAYED;
   //}
   supported := debug_session_is_implemented("disable_breakpoint");
   return (supported && dbg_get_num_exceptions()>0)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_watch(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_watches");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_watchpoint(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("enable_watchpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_add_watchpoint_on_variable(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("enable_watchpoint");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_watch_variable(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_watches");
   return (supported)? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_props(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return debug_active()? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_send_command(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return debug_active()? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_set_auto_lines(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return debug_active()? MF_ENABLED:MF_GRAYED;
}
int _OnUpdate_debug_show_next_statement(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   //debug_gui_stack_update_buttons();
   supported := debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      thread_id := dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      no_of_frames := dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      frame_id := dbg_get_cur_frame(thread_id);
      if (frame_id <= 0 || frame_id > no_of_frames) {
         return MF_GRAYED;
      }
      file_name := "";
      line_number := 0;
      int status=dbg_get_frame_path(thread_id,frame_id,file_name,line_number);
      if (status || file_name=="" || line_number<0) {
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
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      thread_id := dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      no_of_frames := dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      frame_id := dbg_get_cur_frame(thread_id);
      if (frame_id <= 1) {
         return MF_GRAYED;
      }
      return MF_ENABLED;
   }
   return MF_GRAYED;
}
int _OnUpdate_debug_down(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_stack");
   if (debug_active() && debug_is_suspended() && supported) {
      thread_id := dbg_get_cur_thread();
      if (thread_id < 0) {
         return MF_GRAYED;
      }
      no_of_frames := dbg_get_num_frames(thread_id);
      if (no_of_frames <= 0) {
         return MF_GRAYED;
      }
      frame_id := dbg_get_cur_frame(thread_id);
      if (frame_id<=0 || frame_id+1 > no_of_frames) {
         return MF_GRAYED;
      }
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

int _OnUpdate_debug_show_memory(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   supported := debug_session_is_implemented("update_memory");
   return ( supported ? MF_ENABLED : MF_GRAYED );
}

void _on_popup2_debug(_str menu_name,int menu_handle)
{
   _str callback_name = _project_DebugCallbackName;
   if (callback_name=="" && !_no_child_windows() && _mdi.p_child._LanguageInheritsFrom("e")) {
      callback_name = "jdwp";
   }
   if (callback_name=="" || !_isEditorCtl(false) || !_isdebugging_supported()) {
      // No debug mode, or not editor control, so delete breakpoint items
      found_menu_pos := 0;
      int output_menu_handle,output_menu_pos;
      int status=_menu_find(menu_handle,"debug_toggle_breakpoint",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
         found_menu_pos = output_menu_pos;
      }
      status=_menu_find(menu_handle,"debug_toggle_breakpoint_enabled",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
         found_menu_pos = output_menu_pos;
      }
      status=_menu_find(menu_handle,"debug_add_watch",output_menu_handle,output_menu_pos,'M');
      if (!status) {
         _menu_delete(output_menu_handle,output_menu_pos);
         found_menu_pos = output_menu_pos;
      }

      // check for an extra separator
      if (found_menu_pos && found_menu_pos<_menu_info(menu_handle)) {
         int mf_flags;
         _str caption;
         _menu_get_state(menu_handle,found_menu_pos,mf_flags,'P',caption);
         if (caption=="-") {
            _menu_delete(menu_handle,found_menu_pos);
         }
      }
   }
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
int debug_find_function(_str debug_function, _str debugger_mode="")
{
   index := 0;
   if (debugger_mode != "") {
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
static _str gdebug_last_debugger_path="";
static _str gdebug_last_debugger_args="";

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
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   // clear the debugger path / args
   gdebug_last_debugger_path="";
   gdebug_last_debugger_args="";

   // close Slick-C editor instance, if it was
   // spawned temporarily just to debug Slick-C
   do_exit := slickc_debug_detach();

   // package-specific shutdown
   session_id := dbg_get_current_session();
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
 * @param working_dir      (optional) Directory to run the program in 
 * @param start_command    (optional) "go" or "into" or "restart" 
 *
 * @return 0 on success, <0 on error.
 */
int debug_pkg_initialize(_str host_or_prog, _str port_or_pid, 
                         _str arguments, int timeout, 
                         _str debugger_path, _str debugger_args, 
                         _str working_dir=null, _str start_command=null)
{
   // save the debugger path / args
   gdebug_last_debugger_path = debugger_path;
   gdebug_last_debugger_args = debugger_args;

   // initialize/load the vsdebug DLL
   int status=debug_maybe_initialize(true);
   if (status) {
      return(status);
   }

   // make sure that the JVM is started and wating for connection
   loop_until_on_last_process_buffer_command();

   // delegate to the DLL session management function
   session_id := dbg_get_current_session();
   status = dbg_session_initialize(session_id,
                                   host_or_prog, port_or_pid,
                                   arguments, timeout*1000,
                                   debugger_path, debugger_args, 
                                   working_dir, start_command);

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
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // nothing to update?
   CTL_FORM wid=debug_gui_props_wid();
   if (!wid) {
      return(0);
   }
   // version information required
   description := "";
   major_version := "";
   minor_version := "";
   runtime_version := "";
   debugger_name := "";

   // pass the information to the update method
   session_id := dbg_get_current_session();
   if (debug_active()) {
      int status = dbg_session_version(session_id, description, 
                                       major_version, minor_version, 
                                       runtime_version, debugger_name);
      if (status) {
         return(status);
      }
   }

   // get the last debugger path / args
   debugger_path := gdebug_last_debugger_path;
   debugger_args := gdebug_last_debugger_args;

   // update the properties dialog
   wid.debug_gui_update_version(description,major_version,minor_version,runtime_version,debugger_name,debugger_path,debugger_args);
   return(0);
}
int debug_pkg_enable_breakpoint(int breakpoint_id, bool quiet=false)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_breakpoint_enabled(breakpoint_id,1);
   }

   // call the session specific command to enable the breakpoint
   session_id := dbg_get_current_session();
   int status = dbg_session_enable_breakpoint(session_id, breakpoint_id);

   // special case for Java, class not yet loaded
   if (quiet && status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=="jdwp") {
      status=dbg_set_breakpoint_enabled(breakpoint_id,1);
   }

   // that's all folks
   return(status);
}
int debug_pkg_disable_breakpoint(int breakpoint_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_breakpoint_enabled(breakpoint_id,0);
   }

   // call the session specific command to disable the breakpoint
   session_id := dbg_get_current_session();
   int status = dbg_session_disable_breakpoint(session_id, breakpoint_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=="jdwp") {
      status=dbg_set_breakpoint_enabled(breakpoint_id,0);
   }

   // that's all folks
   return(status);
}
int debug_pkg_enable_exception(int exception_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_exception_enabled(exception_id,1);
   }

   // call the session specific command to enable the exception
   session_id := dbg_get_current_session();
   int status = dbg_session_enable_exception(session_id, exception_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=="jdwp") {
      status=dbg_set_exception_enabled(exception_id,1);
   }

   // that's all folks
   return(status);
}
int debug_pkg_disable_exception(int exception_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // just update the setup data if not currently debugging
   if (!debug_active()) {
      return dbg_set_exception_enabled(exception_id,0);
   }

   // call the session specific command to enable the exception
   session_id := dbg_get_current_session();
   int status = dbg_session_disable_exception(session_id, exception_id);

   // special case for java, class not yet loaded
   if (status==DEBUG_CLASS_NOT_FOUND_RC && dbg_get_callback_name(session_id)=="jdwp") {
      status=dbg_set_exception_enabled(exception_id,0);
   }

   // that's all folks
   return(status);
}
int debug_pkg_step_out()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   thread_id := dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_step_out(session_id, thread_id);
}
int debug_pkg_step_over()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   thread_id := dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_step_over(session_id, thread_id);
}
int debug_pkg_step_into(bool startingDebugger=false,_str main_symbol_name='')
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   thread_id := dbg_get_cur_thread();
   if (!startingDebugger && thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_step_into(session_id, thread_id,main_symbol_name);
}
int debug_pkg_step_instr()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   thread_id := dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_step_instruction(session_id, thread_id);
}
int debug_pkg_step_deep()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   thread_id := dbg_get_cur_thread();
   if (thread_id<=0) {
      return(DEBUG_NO_CURRENT_THREAD_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_step_into_runtimes(session_id, thread_id);
}
int debug_pkg_set_instruction_pointer(int thread_id,int frame_id,
                                      _str class_name, _str function_name,
                                      _str file_name, int line_number, _str address)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_set_instruction_pointer(session_id, thread_id, frame_id, 
                                              class_name, function_name, 
                                              file_name, line_number, address);
}
int debug_pkg_suspend(int thread_id=0)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_suspend(session_id, thread_id);
}
int debug_pkg_continue(int thread_id=0)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_resume(session_id, thread_id);
}
int debug_pkg_interrupt(int thread_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_interrupt(session_id, thread_id);
}
int debug_pkg_terminate(int exit_code=0)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_terminate(session_id, exit_code);
}
int debug_pkg_detach()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_detach(session_id);
}
int debug_pkg_disconnect()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_disconnect(session_id);
}
int debug_pkg_reload(_str file_name, int options)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_reload(session_id, file_name, options);
}
int debug_pkg_restart()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_restart(session_id);
}

int debug_pkg_update_current_thread()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_current_thread(session_id);
}
int debug_pkg_update_threads()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_threads(session_id);
}
int debug_pkg_update_threadgroups()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_thread_groups(session_id);
}
/**
 * @deprecated Use debug_pkg_update_threads() 
 */
int debug_pkg_update_threadnames()
{
   return 0;
}
/**
 * @deprecated Use debug_pkg_update_threads() 
 */
int debug_pkg_update_threadstates()
{
   return 0;
}

int debug_pkg_update_stack_top(int thread_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_stack_top(session_id, thread_id);
}
int debug_pkg_update_stack(int thread_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_stack(session_id, thread_id);
}

int debug_pkg_update_classes()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_classes(session_id);
}
int debug_pkg_expand_class(_str class_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_expand_class(session_id, class_path);
}
int debug_pkg_expand_parents(int class_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_expand_parents(session_id, class_id);
}
int debug_pkg_update_watches(int thread_id, int frame_id,int tab_number)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_watches(session_id, thread_id, frame_id, tab_number);
}
int debug_pkg_eval_condition(int thread_id, int frame_id,_str expr)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_eval_condition(session_id, thread_id, frame_id, expr);
}
int debug_pkg_eval_expression(int thread_id, int frame_id,_str expr,_str &value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_eval_expression(session_id, thread_id, frame_id, expr, value);
}
int debug_pkg_update_registers(int thread_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_registers(session_id, thread_id);
}
int debug_pkg_update_memory(_str address, int size)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_memory(session_id, address, size);
}
int debug_pkg_update_autos(int thread_id, int frame_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   if (!dbg_session_is_name_implemented(session_id, "update_autos")) {
      return(STRING_NOT_FOUND_RC);
   }

   debug_find_autovars(thread_id,frame_id);

   return dbg_session_update_auto_watches(session_id, thread_id, frame_id);
}
int debug_pkg_update_disassembly(_str file_name, int num_lines)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_update_disassembly(session_id, file_name, 1, num_lines);
}
int debug_pkg_update_locals(int thread_id,int frame_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_update_locals(session_id, thread_id, frame_id);
}
int debug_pkg_update_members(int thread_id,int frame_id)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_update_members(session_id, thread_id, frame_id);
}
int debug_pkg_expand_local(int thread_id,int frame_id,_str local_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_expand_local(session_id, thread_id, frame_id, local_path);
}
int debug_pkg_expand_member(int thread_id,int frame_id,_str member_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_expand_member(session_id, thread_id, frame_id, member_path);
}
int debug_pkg_expand_watch(int thread_id,int frame_id,_str watch_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_expand_watch(session_id, thread_id, frame_id, watch_path);
}
int debug_pkg_expand_auto(int thread_id,int frame_id,_str autovar_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_expand_auto_watch(session_id, thread_id, frame_id, autovar_path);
}
int debug_pkg_modify_autovar(int thread_id,int frame_id,_str auto_path,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_modify_auto_watch(session_id, thread_id, frame_id, auto_path, new_value);
}
int debug_pkg_modify_watch(int thread_id,int frame_id,_str watch_path,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_modify_watch(session_id, thread_id, frame_id, watch_path, new_value);
}
int debug_pkg_modify_local(int thread_id,int frame_id,_str local_path,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_modify_local(session_id, thread_id, frame_id, local_path, new_value);
}
int debug_pkg_modify_member(int thread_id,int frame_id,_str member_path,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!thread_id) {
      return(DEBUG_NOT_INITIALIZED_RC);
   }
   if (!frame_id) {
      return(DEBUG_THREAD_NO_FRAMES_RC);
   }

   session_id := dbg_get_current_session();
   return dbg_session_modify_member(session_id, thread_id, frame_id, member_path, new_value);
}
int debug_pkg_modify_field(_str field_path,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_modify_field(session_id, field_path, new_value);
}
int debug_pkg_modify_register(int register_id,_str new_value)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return STRING_NOT_FOUND_RC;
   //return dbg_session_modify_register(session_id, register_id, new_value);
}
int debug_pkg_resolve_path(_str file_name, _str &full_path)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // now try searching using the extension specific function
   session_id := dbg_get_current_session();
   int status = dbg_session_resolve_path(session_id, file_name, full_path);
   if (!status) {
      return(0);
   }

   // this would be a good place to search tag files or the project for this file
   full_path="";
   return(FILE_NOT_FOUND_RC);
}

/**
 * Get the last message from the debugger system
 */
_str debug_pkg_error_message()
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   errmsg := "";
   session_id := dbg_get_current_session();
   dbg_session_error_message(session_id, errmsg);
   return errmsg;
}

/**
 * Get the user and system paths for this debugger
 */
int debug_pkg_get_paths(_str &cwd, _str &user, _str &sys)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   int status = dbg_session_get_paths(session_id, cwd, user, sys);
   if (status) {
      cwd=user=sys="";
   }
   return status;
}

/**
 * Disable all the tree views that are not available to a particular package
 */
void debug_pkg_enable_disable_tabs()
{
   if (!_haveDebugging()) {
      return;
   }

   // enable watches if we have an "update_watches" callback
   orig_tab := 0;
   CTL_SSTAB tab_wid = 0;
   wid := debug_gui_watches_wid();
   if (wid) {
      tab_wid=wid.debug_gui_watches_tab();
      if (tab_wid) {
         _SetDialogInfoHt("IGNORE_ON_CHANGE", 1, tab_wid);
         supported := debug_session_is_implemented("update_watches");
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
         _SetDialogInfoHt("IGNORE_ON_CHANGE", 0, tab_wid);
      }
   }

   // enable threads if we have an "update_threads" callback
   update_threads_supported := debug_session_is_implemented("update_threads");
   wid=debug_gui_threads_wid();
   if (wid) {
      tw_enable(wid, update_threads_supported);
   }

   // disable threads combo boxes if we don't have threads support
   list_wid := debug_gui_stack_thread_list();
   if (list_wid) {
      list_wid.p_enabled=update_threads_supported;
   }

   // enable threads if we have an "update_stack" callback
   update_stack_supported := debug_session_is_implemented("update_stack");
   wid=debug_gui_stack_wid();
   if (wid) {
      tw_enable(wid, update_stack_supported);
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
      supported := debug_session_is_implemented("update_classes");
      tw_enable(wid, supported);
   }

   // enable the registers tab if we have an "update_registers" callback
   wid=debug_gui_registers_wid();
   if (wid) {
      supported := debug_session_is_implemented("update_registers");
      tw_enable(wid, supported);
   }

   // enable the memory tab if we have an "update_memory" callback
   wid=debug_gui_memory_wid();
   if (wid) {
      supported := debug_session_is_implemented("update_memory");
      tw_enable(wid, supported);
   }

   // enable the auto-vars tab if we have an "update_autos" callback
   wid=debug_gui_autovars_wid();
   if (wid) {
      supported := debug_session_is_implemented("update_autos");
      tw_enable(wid, supported);
   }

   // enable the locals tabs if we have an "update_locals" callback
   wid=debug_gui_locals_wid();
   if (wid) {
      supported := debug_session_is_implemented("update_locals");
      tw_enable(wid, supported);
   }

   // enable the members tabs if we have an "update_members" callback
   wid=debug_gui_members_wid();
   if (wid) {
      supported := debug_session_is_implemented("update_members");
      tw_enable(wid, supported);
   }

   // enable the breakpoints tab if we have an "enable_breakpoint" callback
   wid=debug_gui_breakpoints_wid();
   if (wid) {
      supported := debug_session_is_implemented("enable_breakpoint");
      tw_enable(wid, supported);
   }
   wid=debug_gui_exceptions_wid();
   if (wid) {
      supported := debug_session_is_implemented("enable_exception");
      tw_enable(wid, supported);
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
bool debug_check_debugging_support(_str msg=null)
{
   if (!_haveDebugging()) {
      if (msg==null) msg=get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      if (msg!="") debug_message(msg,0,true);
      return(false);
   }
   return(true);
}

/**
 * Check if the "enable_breakpoint" callback is available and post
 * a message if it is not available
 *
 * @param msg        Message to display, quiet if msg==''
 *
 * @return 0 on success.
 */
bool debug_check_enable_breakpoint(_str msg=null)
{
   debug_maybe_initialize();
   supported := debug_session_is_implemented("enable_breakpoint");
   if (!supported) {
      if (msg==null) msg="Breakpoints are not supported for this project.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_disable_breakpoint(_str msg=null)
{
   debug_maybe_initialize();
   supported := debug_session_is_implemented("disable_breakpoint");
   if (!supported) {
      if (msg==null) msg="Breakpoints are not supported for this project.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_enable_exception(_str msg=null)
{
   supported := debug_session_is_implemented("enable_exception");
   if (!supported) {
      if (msg==null) msg="Exception breakpoints are not supported for this project.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_disable_exception(_str msg=null)
{
   supported := debug_session_is_implemented("disable_exception");
   if (!supported) {
      if (msg==null) msg="Exception breakpoints are not supported for this project.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_update_watches(_str msg=null)
{
   supported := debug_session_is_implemented("update_watches");
   if (!supported) {
      if (msg==null) msg="Watches are not supported in this environment.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_enable_watchpoints(_str msg=null)
{
   supported := debug_session_is_implemented("enable_watchpoint");
   if (!supported) {
      if (msg==null) msg="Watchpoints are not supported in this environment.";
      if (msg!="") debug_message(msg,0,false);
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
bool debug_check_reload(_str msg=null)
{
   if (!_haveDebugging()) {
      return false;
   }
   // check if reload is supported in this session
   supported := debug_session_is_implemented("reload");

   // call debug_reload with empty arguments to test
   // if it is supported in this environment
   status := 0;
   if (supported) {
      status=dbg_session_reload(dbg_get_current_session(), "", 0);
   }

   // failure?
   if (!supported || status<0) {
      if (msg==null) msg="Edit and continue is not supported in this environment.";
      if (msg!="") debug_message(msg,0,false);
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
   VS_TAG_BROWSE_INFO tagList[];
};

static const MOUSEOVER_EXPRESSION_INFO_KEY="MOUSEOVER_EXPRESSION_INFO";

static _str EvaluateMouseExpression(MouseOverExpression &e, _str &number_msg)
{
   // no expression, or number popups are disabled?
   if (e.expr=="") {
      if (_chdebug) {
         say("EvaluateMouseExpression: H"__LINE__": EARLY RETURN e.expr="e.expr" def_number_base_popups="def_number_base_popups);
      }
      return("");
   }

   // color coding check
   is_number := false;
   skip_evaluation := false;
   cfg := CFG_WINDOW_TEXT;
   cfgDetail := CFG_WINDOW_TEXT;
   if (p_lexer_name != "") {
      cfg = (CFGColorConstants)_clex_find(0, 'g');
      cfgDetail = (CFGColorConstants)_clex_find(0, 'd');
      if (p_col > 1) {
         left();
         cfg = (CFGColorConstants)_clex_find(0, 'g');
         cfgDetail = (CFGColorConstants)_clex_find(0, 'd');
         right();
      }
   }
   if (cfg==CFG_WINDOW_TEXT) {
      // check for CFG_XML_CHARACTER_REF color. Support for &#xff in XML.
      if (p_lexer_name != "") {
         orig_cfg := cfg;
         cfg = (CFGColorConstants)_clex_find(0, 'd');
         if (p_col > 1) {
            left();
            cfg = (CFGColorConstants)_clex_find(0, 'd');
            right();
         }
         switch (cfg) {
         case CFG_XML_CHARACTER_REF:
         case CFG_DOC_ATTR_VALUE:
         case CFG_DOC_ATTRIBUTE:
         case CFG_DOC_KEYWORD:
         case CFG_IDENTIFIER:
         case CFG_IDENTIFIER2:
         case CFG_INACTIVE_KEYWORD:
            break;
         default:
            cfg=orig_cfg;
            break;
         }
      }
   }

   prefix_len_added := 0;

   switch (cfg) {
   case CFG_WINDOW_TEXT:
      /* So we don't confuse variables in source files like "x509","o777", and "b111" as numbers.
         We could also consider checking if we are in debug mode here instead.
      */
      if (p_lexer_name=="") {
         is_number = (eval_exp(auto tmp1, e.expr, 10) == 0);
         if (is_number) skip_evaluation = true;
      }
      break;
   case CFG_XML_CHARACTER_REF:
   case CFG_NUMBER:
   case CFG_COMMENT:
   case CFG_STRING:
   case CFG_DOC_ATTR_VALUE:
   case CFG_INACTIVE_COMMENT:
      skip_evaluation = true;
      if (cfgDetail == CFG_HEX_NUMBER) {
         // With tokens color coded as HEX_NUMBER, we can forgo
         // the prefix, though we need to add a prefix here so 
         // later code will recognize it as a hexadecimal number.  
         if (pos('0x', e.expr) < 1) {
            e.expr = '0x'e.expr;
            prefix_len_added = 2;
         }
         is_number = (eval_exp(auto tmp2, e.expr, 10) == 0);
      } else {
         is_number = (eval_exp(auto tmp2, e.expr, 10) == 0);
      }
      if (is_number) break;
      // drop through
   case CFG_LINENUM:
      skip_evaluation = true;
      if (p_LangId == "docbook") break;
      if (p_LangId == ANT_LANG_ID) break;
      return "";
   case CFG_KEYWORD:
   case CFG_PPKEYWORD:
   case CFG_DOC_KEYWORD:
   case CFG_INACTIVE_KEYWORD:
      if (e.expr=="this") break;
      if (!_LanguageInheritsFrom("e")) {
         return "";
      }
      if (!pos("p_", e.expr)) {
         return "";
      }
      break;
   case CFG_DOC_ATTRIBUTE:
   case CFG_IDENTIFIER:
   case CFG_IDENTIFIER2:
      is_number=false;
      break;
   }

   // look out for negative numbers (-44), or numbers after identifiers (xyz22)
   // use a primitive test on the character before '-' to screen out cases
   // where we are looking at a binary subtraction operator (x-333)
   if (is_number && prefix_len_added == 0) {
      prev_ch := "";
      if (p_col >= length(e.expr)+1) {
         prev_ch = get_text(1, _nrseek()-length(e.expr)-1);
      }
      if (prev_ch == '-') {
         if (p_col > length(e.expr)+2) {
            save_pos(auto before_pos);
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            _nrseek(_nrseek() - length(e.expr)-2);
            search("^|[^ \t]", '-r');
            prev_ch = get_text(1);
            restore_search(s1,s2,s3,s4,s5);
            restore_pos(before_pos);
            if (!pos('[a-z_)\]\}\''\"0-9\-]', prev_ch, 1, 'ir')) {
               e.expr = '-':+e.expr;
            }
         } else {
            e.expr = '-':+e.expr;
         }
      } else if (pos("[a-z_]", prev_ch, 1, 'ir')) {
         return "";
      }
   }

   // 0 and 1 are just too simple, showing number popups would be pointless
   if (e.expr :== "0" || e.expr :== "1") {
      if (_chdebug) {
         say("EvaluateMouseExpression: H"__LINE__": 0 or 1");
      }
      return("");
   }

   // Be sure vsdebug.dll is there before calling this function which
   // will attempt to load it
   have_debugging := (_haveDebugging() && !DllIsMissing('vsdebug.dll'));

   // if we are debugging, make sure the option is turned on and we can display watches
   if (have_debugging && !(def_debug_options & VSDEBUG_OPTION_MOUSE_OVER_INFO)) {
      have_debugging = false;
   }
   if (have_debugging && (!debug_active() || !debug_check_update_watches())) {
      have_debugging = false;
   }

   value := "";
   if (have_debugging && debug_active() && debug_is_suspended() && e.expr!="") {

      if (_chdebug) {
         say("EvaluateMouseExpression: H"__LINE__": DEBUGGING: expr="e.expr);
      }
      // make sure they haven't mouse'd over preprocessing or comments
      if (e.idexp_info != null) {
         if (e.idexp_info.info_flags & (VSAUTOCODEINFO_IN_IMPORT_STATEMENT|
                                        VSAUTOCODEINFO_IN_PREPROCESSING|
                                        VSAUTOCODEINFO_IN_PREPROCESSING_ARGS|
                                        VSAUTOCODEINFO_IN_STRING_OR_NUMBER|
                                        VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST|
                                        VSAUTOCODEINFO_IN_JAVADOC_COMMENT)) {
            skip_evaluation = true;
         }
      }
      // make sure we aren't mousing over a class name or other symbol
      // the debugger will not be able to evaluate
      if (e.tagList._length() > 0) {
         type_name := e.tagList[0].type_name;
         if (tag_tree_type_is_class(type_name) || 
             tag_tree_type_is_package(type_name) || 
             type_name == "typedef" || type_name=="enum" ||
             type_name == "import"  || type_name=="include") {
            skip_evaluation = true;
         }
      }

      if (!skip_evaluation) {
         // try each frame, because they could be mousing over
         // a local in a function higher up the call stack.
         thread_id := dbg_get_cur_thread();
         frame_id := dbg_get_cur_frame(thread_id);
         orig_frame_id := frame_id;
         last_frame_id := frame_id;
         frame_top := dbg_get_num_frames(thread_id);
         for (; frame_id <= frame_top; frame_id++) {
            // do not try this trick if the mouse is not in the file matching this stack frame
            dbg_get_frame_path(thread_id, frame_id, auto frame_file, auto frame_line);
            if (frame_id != orig_frame_id && !_file_eq(_strip_filename(frame_file,'P'), _strip_filename(p_buf_name,'P'))) {
               continue;
            }
            // now try to evaluate the expression
            last_frame_id = frame_id;
            new_value := "";
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
            dummy_value := "";
            debug_pkg_eval_expression(thread_id,orig_frame_id,"0",dummy_value);
         }
      }
   }

   evalue := e.expr;
   result := "";
   if (value!="") {
      is_number = (eval_exp(auto tmp2, value, 10) == 0);
      if (is_number) evalue=value;
      _escape_html_chars(value);
      result = e.expr" = "value;
   } else if (e.tag_info != "") {
      //result = e.tag_info;
   } else {
      result = e.expr;
   }

   if (is_number && def_number_base_popups) {
      _xlat_default_font(CFG_FUNCTION_HELP, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
      imageSize := getImageSizeForFontHeight(fontHeight);

      href_push_clipboard_bgn := "&nbsp;&nbsp;&nbsp;<a href=\"<<push_clipboard ";
      href_push_clipboard_end := "\" lbuttondown><img src=\"vslick://bbpaste.svg@"imageSize"\"></a>";
      typeless decimal_value;
      is_hex_number := false;
      is_binary_number :=false;
      if (strieq(substr(evalue,1,2),"0x") && pos('[^0-9A-F]|$',substr(evalue,3),1,'ir')==length(evalue)-1) {
         is_hex_number=true;
      } 
      if (strieq(substr(evalue,1,2),"0b") && pos('[^01]|$',substr(evalue,3),1,'ir')==length(evalue)-1) {
         is_binary_number=true;
      } 
      eval_exp(decimal_value, evalue, 10);
      if (// I got a Slick-C stack. Couldn't figure out what decimal_value was
          // set to but give the stack, it must not have been an integer.
          // This excludes more than just a check for floating point
          isinteger(decimal_value)
          ) {
         /* 
           0x80000001
           0x80800000 0x7f800000
           0b10000000100000000000000000000000
           0x8080000000000000
           0x8000000000000000
           0xFFFFFFFF80000000
           0xFF   (maybe add signed/unsigned byte support)
           0xFFFF (maybe add signed/unsigned short support)
           123456789
           0xFFFFFFFF
           18446744071562067968
           0b1111111111111111111111111111111110000000000000000000000000000000
           -2
           3+5
           (2 << 29) + 9
         */
         show_other_number := false;
         typeless decimal_value_positive = decimal_value;
         if ((is_binary_number || is_hex_number) && decimal_value<0 /*&& decimal_value!= -1*((long)(0x7FFFFFFFFFFFFFFF+1)*/) {
            eval_exp(decimal_value_positive, evalue"U", 10);
            show_other_number=true;
         /*} else if ((0xFFFFFFFF80000000&(typeless)decimal_value)==0xFFFFFFFF80000000
              || (0x8000000000000000&(typeless)decimal_value)==0x8000000000000000
             ) {
            if (decimal_value<0) {
               show_other_number=true;
               hexdigits:=substr(dec2hex(decimal_value,16),3);
               decimal_value_positive=hex2dec('0x0'hexdigits,10);
            }*/
         }
         hex_value    := dec2hex(decimal_value_positive,16);
         octal_value  := dec2hex(decimal_value_positive,8);
         binary_value := dec2hex(decimal_value_positive,2);

         // calculate the exact size of column 1 (pretty close at least)
         // allow 6 pixels space for padding
         tw := 6;
         longest_label := "unsigned ";
         if (decimal_value > 32 && decimal_value < 65536) {
            longest_label = "unicode (@X) ";
         }
         orig_wid := _create_temp_view(auto temp_wid);
         if (temp_wid) {
            temp_wid.p_font_name        = fontName;
            temp_wid.p_font_size        = pointSizex10 intdiv 10;
            temp_wid.p_font_bold        = (fontFlags & F_BOLD)!=0;
            temp_wid.p_font_italic      = (fontFlags & F_ITALIC)!=0;
            temp_wid.p_font_underline   = (fontFlags & F_UNDERLINE)!=0;
            temp_wid.p_font_strike_thru = (fontFlags & F_STRIKE_THRU)!=0;
            tw += temp_wid._text_width(longest_label);
            _delete_temp_view(temp_wid);
            activate_window(orig_wid);
         } else {
            tw += VSWID_STATUS._text_width(longest_label);
         }

         column_separator := "</dt><dd style=\"margin-left:":+tw:+"px\">";
         _maybe_append(number_msg, "<hr>");
         number_msg :+= "<dl compact>";
         number_msg :+= "<dt>decimal" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(decimal_value) :+ href_push_clipboard_bgn :+ decimal_value :+ href_push_clipboard_end;
         if (show_other_number) {
            number_msg :+= "</dd><dt>unsigned" :+ column_separator;
            number_msg :+= "= " :+ _pretty_number(decimal_value_positive) :+ href_push_clipboard_bgn :+ decimal_value_positive :+ href_push_clipboard_end;
         }
         number_msg :+= "</dd><dt>hex" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(hex_value,16," ",4)     :+ href_push_clipboard_bgn :+ hex_value     :+ href_push_clipboard_end;
         number_msg :+= "</dd><dt>octal" :+ column_separator;
         number_msg :+= "= " :+ octal_value   :+ href_push_clipboard_bgn :+ octal_value   :+ href_push_clipboard_end;
         number_msg :+= "</dd><dt>binary" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(binary_value,2," ",8)  :+ href_push_clipboard_bgn :+ binary_value  :+ href_push_clipboard_end;
         if (decimal_value > 32 && decimal_value < 65536) {
            hex_value = "\\u" :+ substr("0000",1,6-length(hex_value)) :+ substr(hex_value,3);
            number_msg :+= "</dd><dt>unicode (&#"decimal_value";)" :+ column_separator;
            number_msg :+= "= " :+ hex_value :+ href_push_clipboard_bgn :+ hex_value :+ href_push_clipboard_end;
         } else if (decimal_value > 32 && decimal_value < 0x7FFFFFFF) {
            hex_value = "\\U" :+ substr("00000000",1,10-length(hex_value)) :+ substr(hex_value,3);
            number_msg :+= "</dd><dt>unicode" :+ column_separator;
            number_msg :+= "= " :+ hex_value :+ href_push_clipboard_bgn :+ hex_value :+ href_push_clipboard_end;
         }
         number_msg :+= "</dd>";
         number_msg :+= "</dl>";
      } else if (isnumber(decimal_value) && !isinteger(decimal_value)) {
         // this has to be a floating point number
         //
         //  1.0e+10
         //  1234.4568
         //
         scientific_value := _double2asc(decimal_value, 'g');
         hex_value        := _double2asc(decimal_value, 'x');
         floating_value   := _double2asc(decimal_value, 'f');
         math_value       := "";
         if (pos('e', scientific_value)) {
            parse scientific_value with auto mantissa_value 'e' auto exponent_value;
            mantissa_value = stranslate(mantissa_value, "0", "0+$", 'r');
            math_value = _pretty_number(mantissa_value) :+ " * (10 ^ " :+ exponent_value :+ ")"; 
         }

         tw := 6;
         longest_label := "scientific ";
         if (math_value != "") {
            longest_label = "mathematically ";
         }
         orig_wid := _create_temp_view(auto temp_wid);
         if (temp_wid) {
            temp_wid.p_font_name        = fontName;
            temp_wid.p_font_size        = pointSizex10 intdiv 10;
            temp_wid.p_font_bold        = (fontFlags & F_BOLD)!=0;
            temp_wid.p_font_italic      = (fontFlags & F_ITALIC)!=0;
            temp_wid.p_font_underline   = (fontFlags & F_UNDERLINE)!=0;
            temp_wid.p_font_strike_thru = (fontFlags & F_STRIKE_THRU)!=0;
            tw += temp_wid._text_width(longest_label);
            _delete_temp_view(temp_wid);
            activate_window(orig_wid);
         } else {
            tw += VSWID_STATUS._text_width(longest_label);
         }

         column_separator := "</dt><dd style=\"margin-left:":+tw:+"px\">";
         _maybe_append(number_msg, "<hr>");
         number_msg :+= "<dl compact>";
         number_msg :+= "<dt>decimal" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(decimal_value) :+ href_push_clipboard_bgn :+ decimal_value :+ href_push_clipboard_end;
         number_msg :+= "</dd><dt>hex" :+ column_separator;
         number_msg :+= "= " :+ hex_value :+ href_push_clipboard_bgn :+ hex_value     :+ href_push_clipboard_end;
         number_msg :+= "</dd><dt>scientific" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(scientific_value) :+ href_push_clipboard_bgn :+ scientific_value   :+ href_push_clipboard_end;
         number_msg :+= "<dt>floating" :+ column_separator;
         number_msg :+= "= " :+ _pretty_number(floating_value) :+ href_push_clipboard_bgn :+ floating_value :+ href_push_clipboard_end;
         if (math_value != "") {
            number_msg :+= "<dt>mathematically" :+ column_separator;
            number_msg :+= "= " :+ math_value  :+ href_push_clipboard_bgn :+ math_value :+ href_push_clipboard_end;
         }
         number_msg :+= "</dd>";
         number_msg :+= "</dl>";

      } else if (decimal_value :!= e.expr) {
         _maybe_append(number_msg, "<hr>");
         number_msg :+= "decimal\t= " :+ decimal_value :+ href_push_clipboard_bgn :+ decimal_value :+ href_push_clipboard_end;
      }
      number_msg = number_msg :+ " ";
   }

   if (result==null) result="";
   return result;
}
static _str cur_integer(int &start_col,int &complete_match_len=0) {
    save_pos(auto p);
    word:=_cur_integer(auto input_base,false,complete_match_len);
    start_col=p_col;
    restore_pos(p);
    if (word:!="") {
       // complete_word is set to entire word in it's original syntax with
       // prefix and/or suffix.
       //complete_word:=get_text(complete_match_len);
       if(input_base==16) {
          word="0x"word;
       }
    }
    return word;
}

/** 
 * @return 
 * Return message for expression under mouse (or whatever given x,y is)
 * 
 * @param cursor_x               cursor x position 
 * @param width                  width
 * @param streamMarkerMessage    stream marker message for current item
 * @param msg                    (output) set to message to display 
 * @param expr                   (output) set to expression under cursor
 * @param tagList                (output) set to list of matching symbols
 * @param useCursorXY            use cursor x/y position instead of mouse position
 */
_str debug_get_mouse_expr(int &cursor_x, 
                          int &width, 
                          _str *streamMarkerMessage=null, 
                          _str &msg="",
                          _str &expr="",
                          VS_TAG_BROWSE_INFO (&tagList)[]=null,
                          bool useCursorXY=false)
{
   // Be sure vsdebug.dll is there before calling this function which
   // will attempt to load it
   have_debugging := (_haveDebugging() && !DllIsMissing('vsdebug.dll'));

   // make sure we have an editor control
   if (_no_child_windows() || !_isEditorCtl()) {
      if (_chdebug) {
         say("debug_get_mouse_expr H"__LINE__": NO EDITOR");
      }
      return("");
   }
   // if we are not debugging, make sure this source file deserves mouse-over info
   mo_info := _haveContextTagging() && (_GetCodehelpFlags() & VSCODEHELPFLAG_MOUSE_OVER_INFO) != 0;
   if (!debug_active() && !mo_info && !def_number_base_popups) {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, null, _mdi);
      if (_chdebug) {
         say("debug_get_mouse_expr H"__LINE__": MOUSE OVER DISABLED");
      }
      return("");
   }

   // should we evaluate the expression under the mouse
   // if number popups are enabed, or we are debugging, we should do this
   evaluate_expr := def_number_base_popups;
   if (!evaluate_expr && 
       have_debugging &&
       (def_debug_options & VSDEBUG_OPTION_MOUSE_OVER_INFO) && 
       debug_active() &&
       debug_check_update_watches() &&
       debug_is_suspended()) {
      evaluate_expr = true;
   }

   // probe for whether we can set a watch here or not
   // Make sure the current context is up-to-date
   _tbSetRefreshBy(VSTBREFRESHBY_DEBUGGING);
   OrigLineNum := (int)point('L');
   OrigCol := p_col;
   save_pos(auto MouseOverPos);

   // get mouse x/y position
   mx := my := 0;
   if (_isEditorCtl() && useCursorXY) {
      mx = p_cursor_x;
      my = p_cursor_y;
   } else {
      mx = mou_last_x('D');
      my = mou_last_y('D');
      _map_xy(0,p_window_id,mx,my);
   }
   if (_chdebug) {
      say("debug_get_mouse_expr H"__LINE__": mx="mx" my="my);
   }

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
   if (_chdebug) {
      say("debug_get_mouse_expr H"__LINE__": mouse_line="mouse_line);
   }
   mouse_col  := p_col;
   MouseOverExpression *pLast = _GetDialogInfoHtPtr(MOUSEOVER_EXPRESSION_INFO_KEY, _mdi);
   if (mo_info && pLast != null) {
      if (pLast->_isempty() || 
          pLast->windowId != p_window_id ||
          pLast->bufferId != p_buf_id ||
          pLast->lastModified != p_LastModified) {
         pLast = null;
      } else if (mo_info && 
                 ((pLast->mouse_x == mx && pLast->mouse_y == my) ||
                  (pLast->line == mouse_line && pLast->col == mouse_col))) {
         if (_chdebug) {
            say("debug_get_mouse_expr H"__LINE__": REUSING TAG LIST");
         }
         tagList = pLast->tagList;
         p_col=pLast->idexp_info.lastidstart_col;
         cursor_x=p_cursor_x;
         p_col+=length(pLast->idexp_info.lastid);
         width=p_cursor_x-cursor_x;
         if (isEclipsePlugin() && _eclipse_debug_active()) {
            temp := _eclipse_evaluate_expression(pLast->expr);
            if (temp != "") {
               //say("debug_get_mouse_expr H"__LINE__": JUST DOING EXPRESSION");
               return pLast->expr :+ " = " :+ temp;
            }
         } else if (evaluate_expr) {
            if (_chdebug) {
               say("debug_get_mouse_expr H"__LINE__": REBUILDING MOUSE INFO");
            }
            msg = pLast->comment_info;
            expr = EvaluateMouseExpression(*pLast, msg);
            return pLast->expr;
         }
      }
   }

   // get the name of the current class and method
   status := 0;
   expr = "";
   tag_info := "";
   comment_info := "";
   struct VS_TAG_RETURN_TYPE visited:[];

   // make sure that the context doesn't get modified by a background thread.
   _reset_idle();
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContextAndTokens(true);

   if (mo_info &&_istagging_supported() && mo_info && tag_get_num_of_context() > 0) {
      status = tag_get_current_context(auto cur_tag_name,auto cur_flags,
                                       auto cur_type_name,auto cur_type_id,
                                       auto cur_context,auto cur_class,auto cur_package,
                                       visited, 1);
      // blow away the proc name if we are not in a proc
      if (status < 0 || !tag_tree_type_is_func(cur_type_name)) {
         cur_tag_name="";
      }
   }

   // IF the mouse is inside a selection, get the selection text
   //say('p_line='p_line' p_col='p_col);
   VS_TAG_IDEXP_INFO idexp_info;
   tag_idexp_info_init(idexp_info);
   tag_init_tag_browse_info(auto cm);
   if (select_active2() && _in_selection() && !(isEclipsePlugin() && _eclipse_debug_active())) {
      _get_selinfo(auto start_col, auto end_col, auto buf_id, "", auto buf_name, auto utf8, auto encoding, auto Noflines);
      if (Noflines != 1) {
         if (_chdebug) {
            say("debug_get_mouse_expr H"__LINE__": SELECTION SPANS LINES");
         }
         return("");
      }
      typeless force_wrap_line_len=_default_option(VSOPTION_FORCE_WRAP_LINE_LEN);
      idexp_info.lastidstart_col = start_col;
      if (end_col-start_col>force_wrap_line_len) {
         end_col=start_col+force_wrap_line_len;
      }

      p_col=start_col;
      cursor_x=p_cursor_x;
      _end_select();
      if (_select_type("",'I')) {
         ++p_col;
      }
      width=p_cursor_x-cursor_x;

      //say('start_col='start_col' end_col='end_col);
      expr=_expand_tabsc(start_col,end_col-start_col+_select_type("",'I'),'S');
      idexp_info.lastid=expr;

   } else {

      // set a timeout for the amount of time to spend looking up symbols
      sc.lang.ScopedTimeoutGuard timeout(def_tag_max_list_members_time);

      // get the expression to evaluate
      typeless r1,r2,r3,r4,r5;
      save_search(r1,r2,r3,r4,r5);

      _str ext='';

      cfg := _clex_find(0, 'g');
      if (cfg==CFG_WINDOW_TEXT) {
         cfg=_clex_find(0, 'D');
      }
      bool is_numeric_literal=false;
      status=1;
      // If the color coding says this is a number, parse that specially
      if (cfg == CFG_NUMBER) {
         idexp_info.lastid = findLiteralAtCursor(idexp_info.lastidstart_offset, auto endSeekPos);
         //say('idexp_info.lastid='idexp_info.lastid);
         if (idexp_info.lastid!='') {
            // Set the idexp_info.lastidstart_col member
            save_pos(auto p);
            goto_point(idexp_info.lastidstart_offset);
            idexp_info.lastidstart_col=p_col;
            restore_pos(p);
            status=0;is_numeric_literal=true;
            lastid := cur_integer(auto lastidstart_col,auto complete_match_len);
            //say('lastid='lastid);
            if (lastidstart_col==idexp_info.lastidstart_col && complete_match_len==length(idexp_info.lastid)) {
               if (length(lastid)>complete_match_len) {
                  lastidstart_col-=length(lastid)-complete_match_len;
               }
               idexp_info.lastid=lastid;
               idexp_info.lastidstart_col=lastidstart_col;
            }
         }
      } else if ( cfg==CFG_XML_CHARACTER_REF) {
         idexp_info.lastid = cur_integer(idexp_info.lastidstart_col);
         if (idexp_info.lastid!='') {
            status=0;is_numeric_literal=true;
         }
      } else if (p_lexer_name=='') {
         idexp_info.lastid=cur_integer(idexp_info.lastidstart_col,auto complete_match_len);
         if (length(idexp_info.lastid)) {
            if (length(idexp_info.lastid)>complete_match_len) {
               idexp_info.lastidstart_col-=length(idexp_info.lastid)-complete_match_len;
            }
         }
      }
      // IF we didn't find a number literal
      if (status) {
         //say("debug_get_mouse_expr H"__LINE__": p_line="p_line" p_col="p_col);
         status=_Embeddedget_expression_info(false, ext, idexp_info, visited);
         //say('status='status' idexp_info.lastid='idexp_info.lastid' ln='p_line' col='p_col);
      }
      restore_search(r1,r2,r3,r4,r5);
      if (status) {
         if (cfg < 0 || cfg == CFG_STRING || cfg == CFG_COMMENT) {
            idexp_info.lastid = cur_integer(idexp_info.lastidstart_col);
            if (idexp_info.lastid != "") {
               status = 0;
               is_numeric_literal=true;
            }
         }
      }
      if (status) {
         //say("debug_get_mouse_expr H"__LINE__": IDEXP status="status);
         return("");
      }
      if (idexp_info.lastidstart_col <= 0) {
         //say("debug_get_mouse_expr H"__LINE__": INVALID IDEXPINFO, startcol="idexp_info.lastidstart_col);
         return("");
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
               //say("debug_get_mouse_expr H"__LINE__": ECLIPSE FAIL");
               return pLast->expr :+ " = " :+ temp;
            }
         } else if (mo_info && evaluate_expr) {
            if (_chdebug) {
               say("debug_get_mouse_expr H"__LINE__": REBUILDING MOUSE INFO");
            }
            tagList = pLast->tagList;
            msg = pLast->comment_info;
            expr = EvaluateMouseExpression(*pLast, msg);
            return pLast->expr;
         }
      }

      // check if we should bring up function help
      if (mo_info && idexp_info.info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
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
            _do_function_help(OperatorTyped:false,
                              DisplayImmediate:false,
                              cursorInsideArgumentList:false,
                              tryReturnTypeMatching:false,
                              doMouseOverFunctionName: !useCursorXY,
                              cursor_x, width,
                              OrigLineNum, OrigCol,
                              MouseOverPos,
                              streamMessage);
            if (_chdebug) {
               say("debug_get_mouse_expr H"__LINE__": FUNCTION HELP");
            }
            return("");
            //status=DEBUG_WATCH_NOT_ALLOWED_RC;
            //debug_message("Can not watch a function",status);
         }
      }

      // don't look for matches to keywords
      lookForSymbolMatches := mo_info && (_haveContextTagging() != 0) && !is_numeric_literal;
      cfg = _clex_find(0, 'g');
      switch (cfg) {
      case CFG_NUMBER:
      case CFG_LINENUM:
         lookForSymbolMatches = false;
         break;
      case CFG_KEYWORD:
      case CFG_PPKEYWORD:
         if (_LanguageInheritsFrom("e") && pos("p_", idexp_info.lastid)==1) break;
         lookForSymbolMatches = false;
         break;
      }
      if (idexp_info.lastid == "") {
         lookForSymbolMatches = false;
      }

      if (lookForSymbolMatches) {
         _UpdateLocals(true);
         p_col=idexp_info.lastidstart_col;
         cursor_x=p_cursor_x;
         status = _Embeddedfind_context_tags(idexp_info.errorArgs,
                                             idexp_info.prefixexp,idexp_info.lastid,
                                             idexp_info.lastidstart_offset,
                                             idexp_info.info_flags,
                                             idexp_info.otherinfo,
                                             false,def_tag_max_function_help_protos,
                                             true,p_LangCaseSensitive,
                                             SE_TAG_FILTER_ANYTHING,
                                             SE_TAG_CONTEXT_ALLOW_LOCALS, 
                                             visited, 1);
         // no matches found, try just looking for symbol in workspace tag files.
         tag_files := tags_filenamea(p_LangId);
         if (tag_get_num_of_matches() <= 0 && idexp_info.prefixexp=="" && idexp_info.otherinfo=="") {
            status=tag_list_duplicate_matches(idexp_info.lastid, tag_files, def_tag_max_function_help_protos);
         }
         if (status >= 0 && tag_get_num_of_matches() > 0) {

            case_sensitive_proc_name := "";
            if (_GetCodehelpFlags() & VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE) {
               case_sensitive_proc_name = idexp_info.lastid;
            }
            tag_remove_duplicate_symbol_matches(filterDuplicatePrototypes:false,
                                                filterDuplicateGlobalVars:false,
                                                filterDuplicateClasses:false,
                                                filterAllImports:false,
                                                filterDuplicateDefinitions:false,
                                                filterAllTagMatchesInContext:false,
                                                case_sensitive_proc_name,
                                                filterFunctionSignatures:false,
                                                visited, 1);

            _xlat_default_font(CFG_FUNCTION_HELP, auto fontName, auto pointSizex10, auto fontFlags, auto fontHeight);
            imageSize := getImageSizeForFontHeight(fontHeight);

            bool been_there_done_that:[];
            n := tag_get_num_of_matches();
            for (i:=1; i<=n; i++) {
               // first get the symbol declaration
               tag_get_match_info(i, cm);

               // skip duplicates (use a bit of fuzz on the line number, plus or minus 1)
               if (length(cm.member_name)+length(cm.class_name)+length(cm.file_name) <= 0) continue;
               key := cm.member_name";"cm.class_name";"cm.type_name";"_file_case(cm.file_name)";"((cm.line_no+2) intdiv 3)";"cm.arguments;
               //say("debug_get_mouse_expr H"__LINE__": i="i" key="key);
               if (been_there_done_that._indexin(key)) continue;
               been_there_done_that:[key] = true;

               add_tag_info := extension_get_decl(p_LangId, cm, VSCODEHELPDCLFLAG_VERBOSE|VSCODEHELPDCLFLAG_SHOW_CLASS|VSCODEHELPDCLFLAG_SHOW_STATIC);
               _escape_html_chars(add_tag_info);
               add_member_name := cm.member_name;
               _escape_html_chars(add_member_name);
               add_tag_info="<a href=\"<<pushtag -context "p_line" "p_col" -line "cm.line_no" "add_member_name"\" lbuttondown><img src=\"vslick://_f_arrow_into.svg@"imageSize"\"></a>&nbsp;":+add_tag_info;

               // Now get the comment for this tag
               if (_CheckTimeout()) break;
               comment_flags    := (VSCodeHelpCommentFlags)0;
               add_comment_info := "";
               if (_GetCodehelpFlags() & VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS) {
                  if (GetCommentInfoForSymbol(cm, comment_flags, add_comment_info, visited)) {
                     // we can use the comments attached to the symbol by tagging
                  } else if (cm.file_name!="") {
                     _ExtractTagComments2(comment_flags,
                                          add_comment_info, 100,
                                          cm.member_name, cm.file_name, cm.line_no
                                          );
                  }
                  if (add_comment_info!="") {
                     if (p_LangId == ANT_LANG_ID) {
                        add_comment_info = stranslate(add_comment_info,"","<!--");
                        add_comment_info = stranslate(add_comment_info,"","-->");
                     }
                     param_name := (cm.type_name=="param")? cm.member_name:"";
                     _make_html_comments(add_comment_info,comment_flags,cm.return_type,param_name,true,cm.language);
                  }
               }

               // now try to get the return type for this tag
               if (_CheckTimeout()) break;
               tag_get_match_info(i, cm);
               if (_GetCodehelpFlags(cm.language) & VSCODEHELPFLAG_DISPLAY_RETURN_TYPE) {
                  if (cm.return_type!="" && !been_there_done_that._indexin(cm.return_type)) {
                     been_there_done_that:[cm.return_type] = true;
                     add_return_info := _Embeddedget_inferred_return_type_string(auto errorArgs, tag_files, cm, visited, 2);
                     if (add_return_info != "" && add_return_info != cm.return_type) {
                        _escape_html_chars(add_return_info);
                        if (add_comment_info != "") {
                           add_comment_info = "Evaluated type:&nbsp;&nbsp;" :+ add_return_info :+ "<hr>" :+ add_comment_info;
                        } else {
                           add_comment_info = "Evaluated type:&nbsp;&nbsp;" :+ add_return_info;
                        }
                     }
                  }
               }

               // put things together
               if (tag_info != "") tag_info :+= "<hr>";
               tag_info :+= add_tag_info; 
               if (add_comment_info != "") {
                  //tag_info :+= "<hr>";
                  //tag_info :+= add_comment_info;
                  cm.doc_comments = add_comment_info;
               }

               // keep track of this symbol
               //say("debug_get_mouse_expr H"__LINE__": adding a symbol, name="cm.member_name" line="cm.line_no);
               tagList :+= cm;

               // out of time, out of mind
               
               if (_CheckTimeout()) break;
            }

            // Special case for Slick-C where we can actually display the values for variables
            if (_LanguageInheritsFrom("e") && idexp_info.prefixexp=="" && !pos("-",tag_info)) {
               var_index := find_index(idexp_info.lastid,VAR_TYPE|GVAR_TYPE);
               if (var_index) {
                  typeless v=_get_var(var_index);
                  if (v._varformat()==VF_EMPTY) v="(null)";
                  if (VF_IS_INT(v)) {
                     tag_info :+= " = <b>"v"</b>";
                  } else if (v._varformat()==VF_LSTR) {
                     tag_info :+= " = <b>\""v"\"</b>";
                  }
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
   e.tagList      = tagList;

   // this should be a little better...like if it fails, do the normal stuff
   if (isEclipsePlugin() && _eclipse_debug_active()) {
      expr = _eclipse_evaluate_expression(expr);
      if (expr != "") {
         expr = e.expr :+ " = " :+ expr;
      }
   } else  if (evaluate_expr) {
      if (_chdebug) {
         say("debug_get_mouse_expr H"__LINE__": REBUILDING MOUSE INFO");
      }
      number_msg := comment_info;
      expr = EvaluateMouseExpression(e, number_msg);
      comment_info = number_msg;
   }
   if (expr == idexp_info.prefixexp:+idexp_info.lastid && length(comment_info) == 0) {
      if (_chdebug) {
         say("debug_get_mouse_expr H"__LINE__": expression MATCHES prefix/id");
      }
      expr = "";
      return "";
   }
   if (expr != "") {
      _SetDialogInfoHt(MOUSEOVER_EXPRESSION_INFO_KEY, e, _mdi);
   }
   //say("debug_get_mouse_expr H"__LINE__": DONE");
   msg = comment_info;
   return expr;
}

int debug_pkg_do_command(_str command, var reply, _str &errmsg, bool parse_reply)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   return dbg_session_do_command(session_id, command,reply, errmsg, parse_reply);
}

int debug_pkg_print_output(_str s)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   int status = dbg_session_print_output(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      msg := "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_print_info(_str s)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   int status = dbg_session_print_info(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      msg := "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_print_error(_str s)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   int status = dbg_session_print_error(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      msg := "Printing directly to debug io is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

int debug_pkg_input_direct(_str s)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   session_id := dbg_get_current_session();
   int status = dbg_session_send_direct_input(session_id, s);
   if (status == DEBUG_FEATURE_NOT_IMPLEMENTED_RC) {
      msg := "Direct debug io tty input is not supported in this environment.";
      debug_message(msg,0,false);
      return STRING_NOT_FOUND_RC;
   }
   return status;
}

