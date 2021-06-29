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
#include "project.sh"
#import "compile.e"
#import "debug.e"
#import "debuggui.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "projconv.e"
#import "projutil.e"
#import "seltree.e"
#import "stdprocs.e"
#import "treeview.e"
#import "wkspace.e"
#endregion

/**
 * Placeholder command for launching GDB debugger
 * 
 * @return int 
 */
_command int debug_gdb_start() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return 0;
}
int _OnUpdate_debug_gdb_start(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   return(MF_ENABLED);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger integration
//

bool _gdb_ConfigNeedsDebugMenu(_str debug_command)
{
   return(pos('vsdebugio',debug_command,1,'i')!=0);
}
bool _gdb_DebugCommandCaptureOutputRequiresConcurrentProcess(_str debug_command)
{
   return(debug_command=='' || pos('vsdebugio',debug_command,1,'i')!=0);
}
bool _gdb_ToolbarSupported(_str FormName)
{
   switch (FormName) {
   case '_tbdebug_classes_form':
   case '_tbdebug_threadgroups_form':
         return(false);
   }
   return(true);
}


///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger attach form
//
defeventtab _debug_gdb_attach_form;
void ctl_ok.lbutton_up()
{
   // verify that the PID is a positive integer
   index := ctl_processes._TreeCurIndex();
   if (index <= 0) {
      debug_message("Please select a process!",0,true);
      ctl_processes._set_focus();
      return;
   }
   process_id := ctl_processes._TreeGetCaption(index);
   parse process_id with . "\t" process_id "\t" . ;
   process_name := ctl_file.p_text;
   if (process_id!='' && (!isinteger(process_id) || (int)process_id < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_processes._set_focus();
      return;
   }
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      int response=_message_box("Warning: If you do not specify a filename,\n there will be no debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_file._set_focus();
         return;
      }
   }

   // get the session name
   session_name := ctl_session_combo.p_text;
   
   _save_form_response();
   p_active_form._delete_window("pid="process_id",app="process_name",session="session_name);
}

void ctl_ok.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_processes.p_width += delta;
      ctl_file.p_width += delta;
      ctl_refresh.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id);

   ctl_processes._TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   ctl_processes._TreeSetColButtonInfo(1,500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_AL_RIGHT,0,"PID");
   ctl_processes._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Title");
   ctl_processes._TreeAdjustLastColButtonWidth(); 

   // need to populate combo box with list of processes, and search
   // within it for a process who's name matches the current project
   // executable name
   ctl_file.p_text="";
   _retrieve_prev_form();
   ctl_processes.debug_refresh_process_list(ctl_file.p_text, ctl_system.p_value != 0);

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }

   // find a process that matches the file we are loading symbols from
   if (ctl_file.p_text != "") {
      executable_name := _strip_filename(ctl_file.p_text, 'pe');
      if (executable_name != '') {
         tree_index := ctl_processes._TreeSearch(TREE_ROOT_INDEX, executable_name,'i',null,0);
         if (tree_index > 0) {
            ctl_processes._TreeSetCurIndex(tree_index);
         }
      }
   }
}

void ctl_processes.lbutton_double_click()
{
   ctl_ok.call_event(ctl_ok,LBUTTON_UP);
}

void ctl_refresh.lbutton_up()
{
   ctl_processes.debug_refresh_process_list(ctl_file.p_text, ctl_system.p_value != 0);
}

void ctl_system.lbutton_up()
{
   int pid = getpid();
   index := ctl_processes._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      int hidden=TREENODE_HIDDEN;
      if (ctl_system.p_value || !ctl_processes._TreeGetUserInfo(index)) {
         caption := ctl_processes._TreeGetCaption(index);
         _str tree_pid;
         parse caption with . "\t" tree_pid "\t" .;
         if (pid != (int)tree_pid) {
            hidden=0;
         }
      }
      ctl_processes._TreeSetInfo(index, -1, 0, 0, hidden);
      index = ctl_processes._TreeGetNextSiblingIndex(index);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _link_order_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id, 0, ctl_processes.p_x_extent);
}

void _debug_gdb_attach_form.on_resize()
{
   // we always need a little padding
   padding := ctl_label.p_x;

   // width/height of OK, Cancel, Help buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;

   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      _set_minimum_size(button_width*3, button_height*8);
   }

   client_height := p_height;
   client_width := p_width;

   // figure out how much the width changed
   widthDiff := client_width - (ctl_processes.p_width + 2 * padding);
   if (widthDiff) {
      origTreeWidth := ctl_processes.p_width;
      ctl_processes.p_width += widthDiff;
      ctl_processes._TreeScaleColButtonWidths(origTreeWidth, true);
      ctl_refresh.p_x += widthDiff;
      ctl_file.p_width += widthDiff;
      ctl_find_app.p_x += widthDiff;
      ctl_session_combo.p_width+=widthDiff;
   }

   heightDiff := client_height - (ctl_ok.p_y_extent + padding);
   if (heightDiff) {
      ctl_processes.p_height += heightDiff;
      ctl_refresh.p_y += heightDiff;
      ctl_ok.p_y += heightDiff;
      ctl_cancel.p_y += heightDiff;
      ctl_file_label.p_y += heightDiff;
      ctl_file.p_y += heightDiff;
      ctl_find_app.p_y += heightDiff;
      ctl_system.p_y += heightDiff;
      ctl_session_label.p_y+=heightDiff;
      ctl_session_combo.p_y+=heightDiff;
   }

}


///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger core file attach form
//
defeventtab _debug_gdb_corefile_form;
void ctl_ok.lbutton_up()
{
   // verify that the core file was specified
   core_file := ctl_core.p_text;
   process_name := ctl_file.p_text;
   if (core_file=='') {
      debug_message("Expecting a core file!",0,true);
      ctl_core._set_focus();
      return;
   } else if (!file_exists(core_file)) {
      debug_message(core_file,FILE_NOT_FOUND_RC,true);
      return;
   }
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      int response=_message_box("Warning: If you do not specify a filename,\n there may be no symbolic debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_file._set_focus();
         return;
      }
   }

   // finally, get the selected GDB path and supplemental arguments
   gdb_name := "";
   gdb_path := "";
   gdb_args := "";
   line_no := ctl_gdb.p_line;
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
   }

   // get the session name
   session_name := ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("core="core_file",app="process_name",path="gdb_path",args="gdb_args",session="session_name);
}
void ctl_ok.on_create(_str session_name="")
{
   // load the list of GDB configurations
   ctl_gdb.debug_gui_load_configurations_list();

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_core.p_width += delta;
      ctl_file.p_width += delta;
      ctl_gdb.p_width += delta;
      ctl_gdb_config.p_x += delta;
      ctl_session_combo.p_width = max_width;
   }

   // adjust alighment of browse buttons
   _debug_gdb_corefile_form_initial_alignment();

   // restore the last response they entered
   ctl_file.p_text="";
   _retrieve_prev_form();
   if (ctl_core.p_text=="") {
      ctl_core.p_text="core";
   }

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }

}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_corefile_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_core, ctl_find_core.p_window_id);
   sizeBrowseButtonToTextBox(ctl_file, ctl_find_exec.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debug other executable attach form
//
defeventtab _debug_gdb_executable_form;
static void debug_gui_executable_ok(_str command)
{
   // verify that the core file was specified
   program_name := ctl_file.p_text;
   program_args := ctl_args.p_text;
   if (program_name=='') {
      debug_message("Expecting an executable file!",0,true);
      ctl_file._set_focus();
      return;
   } else if (!file_exists(_maybe_unquote_filename(program_name))) {
      debug_message(program_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the working directory specified
   dir_name := ctl_dir.p_text;
   if (dir_name != '' && !file_exists(_maybe_unquote_filename(dir_name))) {
      debug_message(dir_name,FILE_NOT_FOUND_RC,true);
      return;
   }

   // get the session name
   session_name := ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("command="command",app="program_name",dir="dir_name",args="program_args",session="session_name);
}
void ctl_step.lbutton_up()
{
   debug_gui_executable_ok("step");
}
void ctl_run.lbutton_up()
{
   debug_gui_executable_ok("run");
}
void ctl_step.on_create(_str session_name="")
{
   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   max_width += 500;
   if (max_width > ctl_session_combo.p_width) {
      p_active_form.p_width += (max_width - ctl_session_combo.p_width);
      ctl_dir.p_width = max_width;
      ctl_file.p_width = max_width;
      ctl_args.p_width = max_width;
      ctl_session_combo.p_width = max_width;
   }

   // align the browse buttons to the text boxes
   _debug_gdb_executable_form_initial_alignment();

   // restore the last response they entered
   ctl_file.p_text="";
   ctl_dir.p_text="";
   ctl_args.p_text="";
   _retrieve_prev_form();

   // make sure the session they passed in is selected
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_executable_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(ctl_file, ctl_find_exec.p_window_id);
   sizeBrowseButtonToTextBox(ctl_dir, ctl_find_dir.p_window_id);
}

///////////////////////////////////////////////////////////////////////////
// Callbacks for GDB debugger remote attach form
//
defeventtab _debug_gdb_remote_form;
static void debug_gdb_remote_enable_disable_form(bool en)
{
   ctl_host_label.p_enabled = en;
   ctl_host.p_enabled = en;
   ctl_port_label.p_enabled = en;
   ctl_port.p_enabled= en;

   en=!en;
   ctl_device_label.p_enabled = en;
   ctl_device.p_enabled = en;
   ctl_baud_label.p_enabled = en;
   ctl_baud.p_enabled = en;
}
void ctl_device_radio.lbutton_up()
{
   en := (p_value==0);
   debug_gdb_remote_enable_disable_form(en);
}
void ctl_socket_radio.lbutton_up()
{
   en := (p_value==0);
   debug_gdb_remote_enable_disable_form(en);
}
void ctl_ok.lbutton_up()
{
   // verify connection properties
   port_string := "";
   if (ctl_socket_radio.p_value) {
      // verify that the port is a positive integer
      if (ctl_port.p_text!='' && (!isinteger(ctl_port.p_text) || (int)ctl_port.p_text < 0)) {
         debug_message("Expecting a positive integer value!",0,true);
         ctl_tab.p_ActiveTab=0;
         ctl_port._set_focus();
         return;
      }
      port_string="host="ctl_host.p_text",port="ctl_port.p_text;
   }

   if (ctl_device_radio.p_value) {
      // verify that the port is a positive integer
      if (ctl_baud.p_text!='' && (!isinteger(ctl_baud.p_text) || (int)ctl_baud.p_text < 0)) {
         debug_message("Expecting a positive integer value!",0,true);
         ctl_tab.p_ActiveTab=0;
         ctl_baud._set_focus();
         return;
      }
      port_string="device="ctl_device.p_text",baud="ctl_baud.p_text;
   }


   // check that the timeout is a valid integer
   if (ctl_timeout.p_text!='' && (!isinteger(ctl_timeout.p_text) || (int)ctl_timeout.p_text < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_tab.p_ActiveTab=1;
      ctl_timeout._set_focus();
      return;
   } else {
      port_string :+= ",timeout="ctl_timeout.p_text;
   }

   // check that the address is a valid integer
   if (ctl_address_size.p_text!="" && ctl_address_size.p_text!="Default" &&
       (!isinteger(ctl_address_size.p_text) || (int)ctl_address_size.p_text < 0)) {
      debug_message("Expecting a positive integer value!",0,true);
      ctl_tab.p_ActiveTab=1;
      ctl_timeout._set_focus();
      return;
   } else {
      numBits := ctl_address_size.p_text;
      if (numBits == "Default") numBits = "";
      port_string :+= ",address="numBits;
   }

   // save the check box settings
   port_string :+= ",cache="ctl_cache.p_value;
   port_string :+= ",break="ctl_break.p_value;

   // save the extended remote settings
   if (_find_control("ctl_extended_remote") > 0 && ctl_extended_remote.p_value) {
      port_string :+= ",extended="ctl_extended_remote.p_value;
   }

   // save the extended remote settings
   if (_find_control("ctl_remote_pid") > 0 && ctl_remote_pid.p_text != "") {
      port_string :+= ",remotepid="ctl_remote_pid.p_text;
      if (!isnumber(ctl_remote_pid.p_text)) {
         debug_message("Expecting a numeric process ID on the remote host",0,true);
         ctl_tab.p_ActiveTab=0;
         ctl_remote_pid._set_focus();
         return;
      }
   }

   // finally, check the file name (for symbols)
   process_name := ctl_file.p_text;
   if (process_name!='' && !file_exists(process_name)) {
      debug_message(process_name,FILE_NOT_FOUND_RC,true);
      ctl_tab.p_ActiveTab=0;
      ctl_file._set_focus();
      return;
   } else if (process_name=='') {
      response := _message_box("Warning: If you do not specify a filename,\n there may be no symbolic debugging information.","SlickEdit",MB_OKCANCEL|MB_ICONEXCLAMATION);
      if (response==IDCANCEL) {
         ctl_tab.p_ActiveTab=0;
         ctl_file._set_focus();
         return;
      }
   }

   // finally, get the selected GDB path and supplemental arguments
   gdb_name := "";
   gdb_path := "";
   gdb_args := "";
   line_no := ctl_gdb.p_line;
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
   }

   // get the session name
   session_name := ctl_session_combo.p_text;
   
   // that's all folks
   _save_form_response();
   p_active_form._delete_window("file="ctl_file.p_text","port_string",path="gdb_path",args="gdb_args",session="session_name);
}

void ctl_ok.on_create(_str session_name="")
{
   // make sure all the controls are aligned nicely
   _debug_gdb_remote_form_initial_alignment();

   // get all the available debugger sessions
   max_width := ctl_session_combo.debug_load_session_names("gdb", session_name);
   if (max_width > ctl_session_combo.p_width) {
      delta := max_width - ctl_session_combo.p_width;
      p_active_form.p_width += delta;
      ctl_find_app.p_x += delta;
      ctl_file.p_width += delta;
      ctl_tab.p_width += delta;
      ctl_gdb.p_width += delta;
      ctlframe1.p_width += delta;
      ctl_host.p_width += delta;
      ctl_device.p_width += delta;
      ctl_gdb_config.p_x += delta;
      ctl_remote_pid.p_width += delta;
      ctl_args.p_width += delta;
      ctl_session_combo.p_width = max_width;
   }

   // handy default values for baud settings
   ctl_baud._lbadd_item("300");
   ctl_baud._lbadd_item("600");
   ctl_baud._lbadd_item("1200");
   ctl_baud._lbadd_item("2400");
   ctl_baud._lbadd_item("4800");
   ctl_baud._lbadd_item("9600");
   ctl_baud._lbadd_item("14400");
   ctl_baud._lbadd_item("19200");
   ctl_baud._lbadd_item("28800");
   ctl_baud._lbadd_item("38400");
   ctl_baud._lbadd_item("57600");

   // default value for address sizes
   ctl_address_size._lbadd_item("Default");
   ctl_address_size._lbadd_item("8");
   ctl_address_size._lbadd_item("16");
   ctl_address_size._lbadd_item("32");
   ctl_address_size._lbadd_item("64");
   ctl_address_size._cbset_text("Default");

   // handy default values for communication ports
   if (_isUnix()) {
      ff := 1;
      for (;;ff=0) {
         file_name := file_match("/dev/tty*",ff);
         if (file_name=="") break;
         ctl_device._lbadd_item(file_name);
      }
      if (_isSolaris()) {
         ctl_device._lbadd_item("/dev/sr0");
         ctl_device._lbadd_item("/dev/cua/a");
         ctl_device._lbadd_item("/dev/cua/b");
         ctl_device._lbadd_item("/dev/term/a");
         ctl_device._lbadd_item("/dev/term/b");
      }
   } else {
      ctl_device._lbadd_item("COM1");
      ctl_device._lbadd_item("COM2");
      ctl_device._lbadd_item("COM3");
      ctl_device._lbadd_item("COM4");
   }

   // load the list of GDB configurations
   ctl_gdb.debug_gui_load_configurations_list();
   ctl_gdb.call_event(CHANGE_CLINE,ctl_gdb.p_line,ctl_gdb.p_window_id,ON_CHANGE,'W');

   // get the previous form values
   _retrieve_prev_form();
   if (ctl_address_size.p_text == "") {
      ctl_address_size.p_text = "Default";
   }

   // select the default session name
   if (session_name != "") {
      ctl_session_combo._cbset_text(session_name);
   } else if (ctl_session_combo.p_text == "") {
      ctl_session_combo._cbset_text(VSDEBUG_NEW_SESSION);
   }

   // enable/disable the appropriate items
   ctl_tab.p_ActiveTab=0;
   en := (ctl_socket_radio.p_value != 0);
   debug_gdb_remote_enable_disable_form(en);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _debug_gdb_remote_form_initial_alignment()
{
   rightAlign := ctl_session_combo.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_file.p_window_id, ctl_find_app.p_window_id, 0, rightAlign);
}

void ctl_gdb_config.lbutton_up()
{
   int combo_wid=ctl_gdb;
   debug_configurations();
   combo_wid.debug_gui_load_configurations_list();
}
void ctl_gdb.on_change(int reason, int line_no=0)
{
   if (reason != CHANGE_CLINE && reason != CHANGE_SELECTED) {
      return;
   }
   _str gdb_info[] = ctl_gdb.p_user;
   if (line_no > 0 && line_no <= gdb_info._length()) {
      gdb_name := "";
      gdb_path := "";
      gdb_args := "";
      parse gdb_info[line_no-1] with gdb_name "\t" gdb_path "\t" gdb_args;
      ctl_args.p_caption=gdb_path' 'gdb_args;
   }
}

