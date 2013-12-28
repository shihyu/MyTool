////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44444 $
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
#include "android.sh"
#import "compile.e"
#import "clipbd.e"
#import "debuggui.e"
#import "dir.e"
#import "doscmds.e"
#import "guicd.e"
#import "guiopen.e"
#import "gwt.e"
#import "main.e"
#import "mprompt.e"
#import "os2cmds.e"
#import "picture.e"
#import "pipe.e"
#import "projconv.e"
#import "project.e"
#import "rte.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "wkspace.e"
#require "sc/net/ClientSocket.e"
#require "sc/lang/String.e"
#endregion

defeventtab _android_device_form;

void ctl_ok.lbutton_up()
{
   int wait_for_debugger = wait_box.p_value;
   boolean emu = false;
   boolean dev = false;
   int index = ctl_emulators._TreeGetNextSelectedIndex(1, auto info);
   if (index <= 0) {
      index = ctl_hardware._TreeGetNextSelectedIndex(1, info);
      if (index <= 0) {
         _message_box("Please select a device.");
         ctl_emulators._set_focus();
         return;
      }
      dev = true;
   } else {
      emu = true;
   }
   _str emulator = '';
   if (emu) {
      emulator = ctl_emulators._TreeGetCaption(index);
   } else {
      emulator = ctl_hardware._TreeGetCaption(index);
   }
   parse emulator with auto serial "\t" auto name "\t" auto target "\t" auto state auto state2;
   serial = strip(serial);
   name = strip(name);
   target = strip(target);
   state = strip(state);
   state2 = strip(state2);
   if (state == 'offline' && pos('emulator',serial) == 1) {
      _message_box("Cannot execute on a running emulator which is offline.");
      ctl_emulators._set_focus();
      return;
   }
   if (state2 != '') {
      state = state' 'state2;
   }
   p_active_form._delete_window("serial="serial",name="name",target="target",state="state",wait="wait_for_debugger);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void _android_device_form.'ESC'()
{
   p_active_form._delete_window("");
}

void _android_device_form.on_create(EMULATOR_INFO emulators[], boolean get_serial = false)
{
   if (get_serial) {
      p_caption = 'Choose a Device to Debug';
      wait_box.p_visible = false;
   }
}

static void _refresh_emulator_list()
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK found.");
      return;
   }
   int status = android_getDeviceInfo(auto emulators, sdk);
   if (status != 0) {
      // ?  error
      return;
   }
// int i = 0;
// for (i = 0; i < emulators._length(); i++) {
//    say(i':');
//    say('...'emulators[i].name' 'emulators[i].port' 'emulators[i].serial' 'emulators[i].state' 'emulators[i].target);
// }
   int index,i,n=emulators._length();
   ctl_emulators._TreeBeginUpdate(TREE_ROOT_INDEX);
   ctl_emulators._TreeDelete(TREE_ROOT_INDEX, 'C');
   ctl_hardware._TreeBeginUpdate(TREE_ROOT_INDEX);
   ctl_hardware._TreeDelete(TREE_ROOT_INDEX, 'C');
   for (i=0; i<n; ++i) {
      int hidden = TREENODE_HIDDEN;
      int more_flags = 0;
      _str caption = emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
      if (emulators[i].state == 'offline') {
         more_flags = TREENODE_DISABLED;
      }
      if (pos('emulator',emulators[i].serial) == 1 || emulators[i].serial == 'N/A') {
         index = ctl_emulators._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD,0,0,-1,more_flags, caption);
      } else if (pos('emulator',emulators[i].serial) <= 0 && emulators[i].name == '') {
         index = ctl_hardware._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD,0,0,-1,more_flags, caption);
      }

   }
   ctl_emulators._TreeTop();
   ctl_emulators._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_emulators._TreeAdjustColumnWidths(-1);
   ctl_hardware._TreeTop();
   ctl_hardware._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_hardware._TreeAdjustColumnWidths(-1);
}

void ctl_emulators.on_create(EMULATOR_INFO emulators[])
{
// int j = 0;
// for (j = 0; j < emulators._length(); j++) {
//    say(j':');
//    say('...'emulators[j].name' 'emulators[j].port' 'emulators[j].serial' 'emulators[j].state' 'emulators[j].target);
// }
   _TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Serial");
   _TreeSetColButtonInfo(1,500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   _TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Target");
   _TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"State");
   _TreeAdjustLastColButtonWidth();

   int index,i,n=emulators._length();
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   for (i=0; i<n; ++i) {
      int hidden = TREENODE_HIDDEN;
      int more_flags = 0;
      _str caption = emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
      if (emulators[i].state == 'offline') {
         more_flags = TREENODE_DISABLED;
      }
      if (pos('emulator',emulators[i].serial) == 1 || emulators[i].serial == 'N/A') {
         index = _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD,0,0,-1,more_flags, caption);
      }
   }
   _TreeTop();
   _TreeEndUpdate(TREE_ROOT_INDEX);

   _TreeAdjustColumnWidths(-1);
}

void ctl_hardware.on_create(EMULATOR_INFO emulators[])
{
// int j = 0;
// for (j = 0; j < emulators._length(); j++) {
//    say(j':');
//    say('...'emulators[j].name' 'emulators[j].port' 'emulators[j].serial' 'emulators[j].state' 'emulators[j].target);
// }
   _TreeSetColButtonInfo(0,1500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Serial");
   _TreeSetColButtonInfo(1,500,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   _TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Target");
   _TreeSetColButtonInfo(3,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"State");
   _TreeAdjustLastColButtonWidth();

   int index,i,n=emulators._length();
   _TreeBeginUpdate(TREE_ROOT_INDEX);
   _TreeDelete(TREE_ROOT_INDEX, 'C');
   for (i=0; i<n; ++i) {
      int hidden = TREENODE_HIDDEN;
      int more_flags = 0;
      _str caption = emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
      if (emulators[i].state == 'offline') {
         more_flags = TREENODE_DISABLED;
      }
      if (pos('emulator',emulators[i].serial) <= 0 && emulators[i].name == '') {
         index = _TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD,0,0,-1,more_flags, caption);
      }
   }
   _TreeTop();
   _TreeEndUpdate(TREE_ROOT_INDEX);

   _TreeAdjustColumnWidths(-1);
}

void ctl_emulators.lbutton_double_click()
{
   call_event(ctl_ok,LBUTTON_UP);
}

void ctl_hardware.lbutton_double_click()
{
   call_event(ctl_ok,LBUTTON_UP);
}

void ctl_emulators.on_got_focus()
{
   ctl_hardware._TreeDeselectAll();
}

void ctl_hardware.on_got_focus()
{
   ctl_emulators._TreeDeselectAll();
}

void ctl_refresh.lbutton_up()
{
   _refresh_emulator_list();
// ctl_emulators._TreeAdjustColumnWidths();
// ctl_hardware._TreeAdjustColumnWidths();
}

void _android_device_form.on_resize()
{
   // adjust the width of the columns for the text and get the width
   int col_widths = ctl_emulators._TreeAdjustColumnWidths(-1);
   int col_widths2 = ctl_hardware._TreeAdjustColumnWidths(-1);

   // padding
   xpadding := emulator_frame.p_x;
   ypadding := emulator_frame.p_y;

   // width/height of buttons (all are the same)
   int button_width  = ctl_ok.p_width;
   int button_height = ctl_ok.p_height;
   
   // minimum width should be whatever is bigger: the width of all buttons or the tree width 
   int min_width = (button_width * 4 + xpadding * 6) > (col_widths + xpadding * 6) ?
      (button_width * 4 + xpadding * 6) : (col_widths + xpadding * 6);

   if (min_width < col_widths2 + xpadding * 6) {
      min_width = col_widths2 + xpadding * 6;
   }

   if (!_minimum_width() || !_minimum_height()) {
      _set_minimum_size(min_width, button_height*19);
   }

   int client_height=p_height;
   int client_width=p_width;

   widthDiff := client_width - (emulator_frame.p_width + 2 * xpadding);
   if (widthDiff) {
      origTreeWidth := ctl_emulators.p_width;
      ctl_emulators.p_width += widthDiff;
      emulator_frame.p_width += widthDiff;
      hardware_frame.p_width += widthDiff;
      ctl_hardware.p_width += widthDiff;
      ctl_emulators._TreeScaleColButtonWidths(origTreeWidth, true);
      ctl_hardware._TreeScaleColButtonWidths(origTreeWidth, true);
   }

   heightDiff := client_height - (ctl_ok.p_y + ctl_ok.p_height + 2 * ypadding);
   if (heightDiff) {
      emulator_frame.p_height += heightDiff/2;
      hardware_frame.p_y += heightDiff/2;
      hardware_frame.p_height += heightDiff/2;
      ctl_emulators.p_height += heightDiff/2;
      ctl_hardware.p_height += heightDiff/2;
      wait_box.p_y += heightDiff;
   }

   // place buttons
   ctl_refresh.p_y = wait_box.p_y + wait_box.p_height + ypadding; 
   ctl_ok.p_y = ctl_refresh.p_y;
   ctl_cancel.p_y = ctl_refresh.p_y;
   ctl_avd.p_y = ctl_refresh.p_y;
}

void ctl_avd.lbutton_up()
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for project.");
      return;
   }
   _maybe_append_filesep(sdk);
   _str cmd = sdk;
   cmd :+= 'tools'FILESEP:+ANDROID_TOOL;
#if !__UNIX__
   cmd :+= '.bat';
#endif
   cmd :+= ' avd';
   shell(cmd, 'AQ');
}

defeventtab _android_update_form;

void _android_update_form.on_create(_str sdk="", _str man_file="", boolean create_ws=true)
{
   _retrieve_prev_form();
   if (sdk != "") {
      android_loc_box.p_text = sdk;
   }
   android_prjname_box.p_text = '';
   _param1 = man_file;
   _param2 = create_ws;
   ctlndk.p_value = 0;
   android_ndk_box.p_enabled = false;
   android_ndk_browse.p_enabled = false;
   android_ndk_label.p_enabled = false;
}

void ctlndk.lbutton_up()
{
   boolean enable = ctlndk.p_value == 1 ? true : false;
   android_ndk_box.p_enabled = enable;
   android_ndk_browse.p_enabled = enable;
   android_ndk_label.p_enabled = enable;
}

void _android_update_form.'ESC'()
{
   p_active_form._delete_window(''); 
}

void a_cancel.lbutton_up()
{
   _str man_file = _param1;
   boolean create_ws = _param2;
   p_active_form._delete_window("");
   typeless *pfnCancelButton=setupExistingAndroidProject;
   int status=(*pfnCancelButton)("", "", "", man_file, false, 0, "", create_ws);
}

void android_sdk_browse.lbutton_up()
{
   int wid=p_window_id;
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if ( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return;
}

void a_ok.lbutton_up()
{
   _str man_file = _param1;
   boolean create_ws = _param2;
   _str name = strip(android_prjname_box.p_text);
   _str sdk = strip(android_loc_box.p_text);
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
   }
   int uses_ndk = ctlndk.p_value;
   _str ndk = android_ndk_box.p_text;
   if (ndk != "" && pos('"',ndk)) {
      ndk = stranslate(ndk,'','"');
   }
   _str target = strip(android_target_box.p_text);
   // input validation...
   if (target == '') {
      _message_box('Please specify an Android build target.');
      return;
   }
   _str apiLevel = _android_getNumberFromTarget(target);
   if (name != '' && !isid_valid(name)) {
      _message_box('Application Name must be a valid Java identifier.');
      return;
   }
// int tagsdk = ctltag.p_value;
// int setupCpath = ctlcpath.p_value;
   // check the android ndk directory for validity
   if (!_android_isValidNdkLoc(ndk)) {
      return;
   }
   // check the android sdk directory for validity and compose the create command
   if (!_android_isValidSdkLoc(sdk)) {
      return;
   }
   _save_form_response();
   p_active_form._delete_window("");
   typeless *pfnOkButton=setupExistingAndroidProject;
   int status=(*pfnOkButton)(name, target, sdk, man_file, true, uses_ndk, ndk, create_ws);
   if (!status) {
      project_build();
      _workspace_opened_rte();
   }
}

defeventtab _android_form;

void android_name_box.on_lost_focus()
{
   _str name = android_name_box.p_text;
   if (name != '') {
      android_activity_box.p_text = name'Activity';
      package_box.p_text = 'com.mycompany.'name;
   }
}

void android_target_box.on_change()
{
   _str target = android_target_box.p_text;
   _str minsdk = _android_getNumberFromTarget(target);
   if (minsdk != '' && isnumber(minsdk)) {
      android_minsdk_box.p_text = minsdk;
   }
}

void _android_form.'ESC'()
{
   p_active_form._delete_window(''); 
}

void ctlndk.lbutton_up()
{
   boolean enable = ctlndk.p_value == 1 ? true : false;
   android_ndk_location.p_enabled = enable;
   android_ndk_browse.p_enabled = enable;
   android_ndk_label.p_enabled = enable;
}

void _android_form.on_create()
{
   _retrieve_prev_form();
   ctltag.p_value=1;
   ctlcpath.p_value=0;
   ctllib.p_value=0;
   ctlndk.p_value=0;
   android_ndk_location.p_enabled = false;
   android_ndk_browse.p_enabled = false;
   android_ndk_label.p_enabled = false;
   android_name_box.p_text='';
   android_activity_box.p_text='';
   package_box.p_text='';
   android_activity_box.p_enabled = true;
}

void ctllib.lbutton_up()
{
   if (ctllib.p_value != 0) {
      android_activity_box.p_enabled = false;
   } else {
      android_activity_box.p_enabled = true;
   }
}

void android_cancel.lbutton_up()
{
   p_active_form._delete_window(''); 
}

void android_loc_browse.lbutton_up()
{
   int wid=p_window_id;
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if ( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return;
}

int _android_getTargetsFromSDK(_str sdk, _str (&targets)[])
{
   if (!_android_isValidSdkLoc(sdk,true)) {
      targets[targets._length()] = 'Please specify valid Android SDK';
      return 1;
   } 
   _str temp_file = mktemp();
   if (temp_file == '') {
      targets[targets._length()] = "Error executing 'android' tool";
      return 1;
   }
   _str list_cmd = sdk;
   _maybe_append_filesep(sdk);
   list_cmd = sdk :+ 'tools' :+ FILESEP :+ ANDROID_TOOL;
#if !__UNIX__
   list_cmd :+= '.bat';
#endif
   list_cmd = maybe_quote_filename(list_cmd) :+ ' list targets > ' :+ maybe_quote_filename(temp_file);
   int status = shell(list_cmd, 'Q');
   if (status) {
      targets[targets._length()] = "Error executing 'android' tool";
      return 1;
   }
   status = _open_temp_view(temp_file, auto temp_view_id, auto orig_view_id);
   if (!status) {
      for (;;) {
         status=search('^id\:[ \t]:d',"@rh");
         if (status) {
            break;
         }
         get_line(auto line);
         targets[targets._length()] = line;
         if (down()) {
            break;
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   delete_file(temp_file);
   return 0;
}

_command void android_selectTarget(_str target = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY)
{
   _nocheck _control android_target_box;
   android_target_box.p_text = target;
   p_window_id=android_target_box;
   _set_focus();
}

void _on_popup2_android_targets(_str menu_name, int menu_handle)
{
   if (menu_name :!= "_android_target_menu") {
      return;
   }
   _str sdk = android_loc_box.p_text;
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
      android_loc_box.p_text = sdk;
   }
   int status = _android_getTargetsFromSDK(sdk, auto targets);
   int i = 0;
   for (i = 0; i < targets._length(); i++) {
      _menu_insert(menu_handle, -1, MF_ENABLED, targets[i], "android-selectTarget ":+targets[i]);
   }
}

void android_ok.lbutton_up()
{
   _str package = strip(package_box.p_text);
   _str sdk = android_loc_box.p_text;
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
   }
   _str ndk = android_ndk_location.p_text;
   if (ndk != "" && pos('"',ndk)) {
      ndk = stranslate(ndk,'','"');
   }
   _str name = strip(android_name_box.p_text);
   _str activity = strip(android_activity_box.p_text);
   _str target = strip(android_target_box.p_text);
   _str apiLevel = '';
   // input validation...
   if (target == '') {
      _message_box('Please specify an Android build target.');
      return;
   }
   apiLevel = _android_getNumberFromTarget(target);
   if (!is_valid_java_package(package)) {
      _message_box('Package Name must be a valid Java package identifier.');
      return;
   }
   if (!isid_valid(name)) {
      _message_box('Application Name must be a valid Java identifier.');
      return;
   }
   int lib = ctllib.p_value;
   if (lib == 0 && !isid_valid(activity)) {
      _message_box('Activity Name must be a valid Java identifier.');
      return;
   }
   int tagsdk = ctltag.p_value;
   int setupCpath = ctlcpath.p_value;
   int uses_ndk = ctlndk.p_value;
   // check the android sdk directory for validity and compose the create command
   if (!_android_isValidSdkLoc(sdk)) {
      return;
   }
   // check the android ndk directory for validity
   if (!_android_isValidNdkLoc(ndk)) {
      return;
   }
   typeless *pfnOkButton=setupAndroidProject;
   int status=(*pfnOkButton)(name, package, activity, target, sdk, tagsdk, setupCpath, lib, apiLevel, uses_ndk, ndk);
   if (!status || status==COMMAND_CANCELLED_RC) {
      _save_form_response();
      p_active_form._delete_window(status);
   }
   if (!status) {
      project_build();
      _str projectDir = _file_path(_project_name);
      _maybe_append_filesep(projectDir);
      _workspace_opened_rte(projectDir'gen');
   }
}

_command int new_android_application()
{
   int status=show('-modal _android_form');
   if (status) {
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      } else {
         return(status);
      }
   }
   // after the dialog closes, if we have been successful, activate and refresh 'Projects' 
   _gwt_updateProjects();
   return(0);
}

/**
 * Check if a directory contains a valid Android SDK 
 * installation. 
 * 
 * @param dir 
 * 
 * @return boolean 
 */
boolean _android_isValidNdkLoc(_str dir, boolean quiet = false)
{
   if (dir == '') {
      return true;
   }
   if (!isdirectory(dir)) {
      if (!quiet) {
         _message_box('Location of Android NDK must be a directory.');
      }
      return false;
   }
   _maybe_append_filesep(dir);

   if (!file_exists(dir:+'ndk-build') || !file_exists(dir:+'ndk-gdb')) {
      if (!quiet) {
         _message_box('Android NDK installation is missing components.');
      }
      return false;
   }
   return true;
}

/**
 * Check if a directory contains a valid Android SDK 
 * installation. 
 * 
 * @param dir 
 * 
 * @return boolean 
 */
boolean _android_isValidSdkLoc(_str dir, boolean quiet = false)
{
   if (dir == '' || !isdirectory(dir)) {
      if (!quiet) {
         _message_box('Location of Android SDK must be a directory.');
      }
      return false;
   }
   _maybe_append_filesep(dir);
   _str android = dir :+ "tools" :+ FILESEP :+ ANDROID_TOOL;
   _str emulator = dir :+ "tools" :+ FILESEP :+ EMU_TOOL;
   _str adb = dir :+ "platform-tools" :+ FILESEP :+ ADB;
   // should also check for android.jar...

#if !__UNIX__
   android :+= ".bat";
   emulator :+= ".exe";
   adb :+= ".exe";
#endif

   if (!file_exists(android) || !file_exists(emulator) || !file_exists(adb)) {
      if (!quiet) {
         _message_box('Android SDK installation is missing components.');
      }
      return false;
   }
   return true;
}

static int setupExistingAndroidProject(_str name='', _str target_id='', _str sdk='', _str man_file='', boolean update=false,
                                       int uses_ndk = 0, _str ndk='', boolean create_ws=true)
{
   if (ndk != '') {
      _maybe_append_filesep(ndk);
   }
   _str xmlFile = strip(man_file, "B", " \t");
   xmlFile = strip(xmlFile, "B", "\"");

   xmlFile = maybe_quote_filename(xmlFile);

   // even if we are inserting into current ws, we need to establish this for what we will name the project
   _str wsname = '';

   // if name wasn't specified, use the name from the manifest file 
   if (name == '') {
      int h = _xmlcfg_open(xmlFile,auto status);
      if (h >= 0) {
         int actNode = _xmlcfg_find_simple(h,'/manifest/application/activity');
         if (actNode >= 0) {
            wsname = _xmlcfg_get_attribute(h,actNode,"android:name","");
         }
         if (wsname != '' && pos('.',wsname) == 1 && length(wsname) > 2) {
            wsname = substr(wsname,2);
         }
         _xmlcfg_close(h);
      }
   } else {
      wsname = name;
   }

   // if there is no activity, we don't really know what to call it...
   if (wsname == '') {
      wsname = 'AndroidManifest';
   }

   _str workspaceName = create_ws ? _strip_filename(xmlFile, 'N') :+ wsname :+ WORKSPACE_FILE_EXT : _workspace_filename;
   _str projectName = _strip_filename(xmlFile, 'N') :+ wsname :+ PRJ_FILE_EXT;

   // create the corresponding workspace/project if necessary
   boolean workspaceCreated = !create_ws;
   if (create_ws && !file_exists(workspaceName)) {
      workspaceCreated = true;

      // not found so create new workspace
      workspace_new(false, _strip_filename(workspaceName, 'P'), _strip_filename(workspaceName, 'N'));

   }

   if (workspaceCreated) {
      // create the project
      workspace_new_project2(projectName, "Java - Ant", _strip_filename(projectName, 'PE'), workspaceName, false, true);
   }

   // open the workspace if necessary
   if (create_ws) {
      workspace_open(workspaceName);
   }

   if (workspaceCreated) {
      int projectHandle = _ProjectHandle();
      // add all appropriate files to the project
      _android_addWildcardsToProject(projectHandle, uses_ndk);
      _ProjectSet_AppType(projectHandle,'Debug',"android");
      _ProjectSet_AppType(projectHandle,'Release',"android");
      if (uses_ndk && ndk != '') {
         _ProjectSet_PreBuildCommandsList(projectHandle,ndk:+'ndk-build NDK_DEBUG=1','Debug');
         _ProjectSet_PreBuildCommandsList(projectHandle,ndk:+'ndk-build','Release');
      }
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Debug'),
         'antmake -emacs -f build.xml debug');
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Debug'),
         'antmake -emacs -f build.xml clean debug');
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Release'),
         'antmake -emacs -f build.xml release');
      _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Release'),
         'antmake -emacs -f build.xml clean release');
      // set up 'execute on device' tool
      int emu_debug_node = _ProjectGet_TargetNode(projectHandle,'execute','Debug');
      int emu_rls_node = _ProjectGet_TargetNode(projectHandle,'execute','Release');
      _ProjectSet_TargetMenuCaption(projectHandle,emu_debug_node,'Execute on Device...');
      _ProjectSet_TargetMenuCaption(projectHandle,emu_rls_node,'Execute on Device...');
      _ProjectSet_TargetCmdLine(projectHandle,emu_debug_node,'android_runAppOnDevice', 'Slick-C');
      _ProjectSet_TargetCmdLine(projectHandle,emu_rls_node,'android_runAppOnDevice', 'Slick-C');
      _ProjectSet_TargetBuildFirst(projectHandle,emu_debug_node,false);
      _ProjectSet_TargetBuildFirst(projectHandle,emu_rls_node,false);
      int temp_debugc_node = _ProjectAddTool(projectHandle,'Clean', 'Debug');
      int temp_rlsc_node = _ProjectAddTool(projectHandle,'Clean', 'Release');
      int clean_debug_node = _xmlcfg_copy(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Debug'),
                                          projectHandle,temp_debugc_node,0);
      int clean_rls_node = _xmlcfg_copy(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Release')
                                        ,projectHandle,temp_rlsc_node,0);
      _xmlcfg_delete(projectHandle,temp_debugc_node);
      _xmlcfg_delete(projectHandle,temp_rlsc_node);
      if (uses_ndk && ndk != '') {
         _ProjectSet_TargetPreMacro(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Debug'),"android_pre_clean");
         _ProjectSet_TargetPreMacro(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Release'),"android_pre_clean");
         _ProjectSet_TargetPreMacro(projectHandle,clean_debug_node,"android_pre_clean");
         _ProjectSet_TargetPreMacro(projectHandle,clean_rls_node,"android_pre_clean");
      }
      _ProjectSet_TargetCmdLine(projectHandle,clean_debug_node,'antmake -emacs -f build.xml clean');
      _ProjectSet_TargetCmdLine(projectHandle,clean_rls_node,'antmake -emacs -f build.xml clean');
      _ProjectSet_TargetBuildFirst(projectHandle,clean_debug_node,false);
      _ProjectSet_TargetBuildFirst(projectHandle,clean_rls_node,false);
      _ProjectSet_TargetCaptureOutputWith(projectHandle,clean_debug_node,'ProcessBuffer');
      _ProjectSet_TargetCaptureOutputWith(projectHandle,clean_rls_node,'ProcessBuffer');
      _ProjectSave(projectHandle);

      if (update && target_id != '' && isinteger(target_id) && sdk != '') {
         _str projectDir = _file_path(_project_name);
         _maybe_append_filesep(projectDir);
         projectDir = maybe_quote_filename(projectDir);
         _maybe_append_filesep(sdk);
         _str uCmd = sdk'tools'FILESEP'android';
#if !__UNIX__
         uCmd :+= '.bat';
#endif
         uCmd = maybe_quote_filename(uCmd) :+ ' update project';
         if (name != '') {
           uCmd :+= ' --name 'name;
         }
         uCmd :+= ' --target 'target_id' --path 'projectDir;
         _str res = _PipeShellResult(uCmd, auto status,'ACH');
      }
   }

   return 0;
}

static int setupAndroidProject(_str name='', _str pkg='', _str activity='', _str target='',
                           _str sdk='', int tag=0, int setupCpath=0, int lib=0, _str api='',
                           int uses_ndk=0, _str ndk='')
{
   _str projectDir = _file_path(_project_name);
   int projectHandle = _ProjectHandle();
   _maybe_append_filesep(projectDir);
   // run android tool to generate the project
   _str create_cmd = '';
   _maybe_append_filesep(sdk);
   if (ndk != '') {
      _maybe_append_filesep(ndk);
   }
   _str project_string = lib ? 'lib-project' : 'project';
   _str activity_string = lib ? '' : ' --activity 'activity;
   create_cmd = sdk :+ 'tools' :+ FILESEP :+ ANDROID_TOOL;
#if !__UNIX__
   create_cmd :+= '.bat';
#endif
   create_cmd = maybe_quote_filename(create_cmd) :+ ' create 'project_string' --target 'target' --name 'name' ';
   create_cmd = create_cmd :+ '--path 'maybe_quote_filename(projectDir):+activity_string' '; 
   create_cmd = create_cmd :+ '--package 'pkg; 
   create_cmd = makeCommandCLSafe(create_cmd);
   int status = shell(create_cmd, 'Q');
   if (status) {
      _message_box("Unable to execute android tool: "get_message(status));
      return 1;
   }
   // add all appropriate files to the project
   _android_addWildcardsToProject(projectHandle, uses_ndk);
   if (setupCpath) {
      _str cpath = projectDir :+ 'src' :+ PATHSEP;
      cpath = cpath :+ projectDir :+ 'bin' :+ FILESEP :+ 'classes' :+ PATHSEP;
      if (api != '' && isnumber(api)) {
         cpath = cpath :+ sdk :+ 'platforms' :+ FILESEP :+ 'android-'api :+ FILESEP :+ ANDROID_JAR;
      }
      _ProjectSet_ClassPathList(projectHandle,cpath,'Debug');
      _ProjectSet_ClassPathList(projectHandle,cpath,'Release');
   }
   if (uses_ndk && ndk != '') {
      _ProjectSet_PreBuildCommandsList(projectHandle,ndk:+'ndk-build NDK_DEBUG=1','Debug');
      _ProjectSet_PreBuildCommandsList(projectHandle,ndk:+'ndk-build','Release');
   }
   _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Debug'),
      'antmake -emacs -f build.xml debug');
   _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Debug'),
      'antmake -emacs -f build.xml clean debug');
   _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Release'),
      'antmake -emacs -f build.xml release');
   _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Release'),
      'antmake -emacs -f build.xml clean release');
   // set up 'execute on device' tool
   int emu_debug_node = _ProjectGet_TargetNode(projectHandle,'execute','Debug');
   int emu_rls_node = _ProjectGet_TargetNode(projectHandle,'execute','Release');
   _ProjectSet_TargetMenuCaption(projectHandle,emu_debug_node,'Execute on Device...');
   _ProjectSet_TargetMenuCaption(projectHandle,emu_rls_node,'Execute on Device...');
   _ProjectSet_TargetCmdLine(projectHandle,emu_debug_node,'android_runAppOnDevice', 'Slick-C');
   _ProjectSet_TargetCmdLine(projectHandle,emu_rls_node,'android_runAppOnDevice', 'Slick-C');
   _ProjectSet_TargetBuildFirst(projectHandle,emu_debug_node,false);
   _ProjectSet_TargetBuildFirst(projectHandle,emu_rls_node,false);
   // set up 'execute on device' tools
   int temp_debugc_node = _ProjectAddTool(projectHandle,'Clean', 'Debug');
   int temp_rlsc_node = _ProjectAddTool(projectHandle,'Clean', 'Release');
   int clean_debug_node = _xmlcfg_copy(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Debug'),
                                       projectHandle,temp_debugc_node,0);
   int clean_rls_node = _xmlcfg_copy(projectHandle,_ProjectGet_TargetNode(projectHandle,'build','Release')
                                     ,projectHandle,temp_rlsc_node,0);
   _xmlcfg_delete(projectHandle,temp_debugc_node);
   _xmlcfg_delete(projectHandle,temp_rlsc_node);
   _ProjectSet_TargetCmdLine(projectHandle,clean_debug_node,'antmake -emacs -f build.xml clean');
   _ProjectSet_TargetCmdLine(projectHandle,clean_rls_node,'antmake -emacs -f build.xml clean');
   _ProjectSet_TargetBuildFirst(projectHandle,clean_debug_node,false);
   _ProjectSet_TargetBuildFirst(projectHandle,clean_rls_node,false);
   _ProjectSet_TargetCaptureOutputWith(projectHandle,clean_debug_node,'ProcessBuffer');
   _ProjectSet_TargetCaptureOutputWith(projectHandle,clean_rls_node,'ProcessBuffer');
   if (uses_ndk && ndk != '') {
      _ProjectSet_TargetPreMacro(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Debug'),"android_pre_clean");
      _ProjectSet_TargetPreMacro(projectHandle,_ProjectGet_TargetNode(projectHandle,'rebuild','Release'),"android_pre_clean");
      _ProjectSet_TargetPreMacro(projectHandle,clean_debug_node,"android_pre_clean");
      _ProjectSet_TargetPreMacro(projectHandle,clean_rls_node,"android_pre_clean");
   }
   // generate uses-sdk node for compatibility
   if (api != '' && isnumber(api)) {
      int h = _xmlcfg_open(maybe_quote_filename(projectDir :+ 'AndroidManifest.xml'),status);
      if (h >= 0) {
         int node = _xmlcfg_find_simple(h,"/manifest");
         if (node >= 0) {
            int sdk_node = _xmlcfg_add(h,node,'uses-sdk',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            if (sdk_node >= 0) {
               _xmlcfg_add_attribute(h,sdk_node,'android:minSdkVersion',api);
               status = _xmlcfg_save(h,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
            }
         }
         _xmlcfg_close(h);
      }
   }
   // save the project and we are done
   _ProjectSave(projectHandle);
   // create tag file for android sdk 
   if (tag && api != '' && isnumber(api)) {
      _str android_jar = sdk :+ 'platforms' :+ FILESEP :+ 'android-'api :+ FILESEP :+ ANDROID_JAR;
      if (file_exists(maybe_quote_filename(android_jar))) {
         _str tagfilename=absolute(_tagfiles_path():+'android-'api:+TAG_FILE_EXT);
         if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', 'android-'api)) {
            ext_BuildTagFile(tf, tagfilename, 'java', '', false, maybe_quote_filename(android_jar));
         }
      }
   }
   return 0;
}

/**
 * Add all appropriate wildcards to a GWT project: *.java, *.css, *.xml, *.html, 
 * and *.jar. 
 *  
 * @param handle 
 */
void _android_addWildcardsToProject(int handle=0, int uses_ndk=0)
{
   if (handle > 0) {
      _ProjectAdd_Wildcard(handle, "*.java","",true); 
      _ProjectAdd_Wildcard(handle, "*.xml","",true); 
      _ProjectAdd_Wildcard(handle, "*.cfg","",true); 
      _ProjectAdd_Wildcard(handle, "*.properties","",true); 
      _ProjectAdd_Wildcard(handle, "*.png","",true); 
      _ProjectAdd_Wildcard(handle, "*.apk","",true); 
      _ProjectAdd_Wildcard(handle, "*.dex","",true); 
      _ProjectAdd_Wildcard(handle, "*.prop","",true); 
      if (uses_ndk > 0) {
         _ProjectAdd_Wildcard(handle, "jni":+FILESEP:+"*","",true);
      }
   }
}

_command _str android_runAppOnDevice(boolean get_serial = false)
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for project.");
      return '';
   }
   int status = android_getDeviceInfo(auto emus, sdk);
   int i = 0;
   if (get_serial) {
      int num_online = 0;
      for (i = 0; i < emus._length(); i++) {
         if (emus[i].state == 'online') {
            num_online++;
         }
      }
      if (num_online == 1) {
         // don't need the serial if there is only 1 device online
         return 'serial=';
      }
   }
   _str val = show("-xy -modal _android_device_form", emus, get_serial);
   if (val == "" || get_serial) {
      return val;
   }
   parse val with . "wait=" auto wait_opt;
   parse val with . "state=" auto state auto state2 ',' .;
   if (state2 != '') {
      state = state' 'state2;
   }
   parse val with . "name=" auto name ',' .;
   parse val with . "serial=" auto serial',' .;
   // start a not running emulator
   if (state == 'not running' && name != '') {
      _str start_cmd = sdk :+ 'tools' :+ FILESEP :+ EMU_TOOL;
#if !__UNIX__
      start_cmd :+= '.exe';
#endif
      start_cmd = maybe_quote_filename(start_cmd) :+ ' -logcat verbose -avd ' name;
      status = shell(start_cmd,'AQ');
   }
   // performed again here in case emulator list changed and was refreshed
   status = android_getDeviceInfo(auto emus2, sdk);
   _str serials = '';
   for (i = 0; i < emus2._length(); i++) {
      serials :+= emus2[i].serial',';
   }
   _str vsandroidrun = get_env("VSLICKBIN1"):+VSANDROIDRUN_EXE;
   _str run_args = sdk' 'apk' 'pkg' 'act' 'serial' 'serials' 'wait_opt;
   _str run_cmd = maybe_quote_filename(vsandroidrun)' 'run_args;
   run_cmd = makeCommandCLSafe(run_cmd);
   int test = concur_command(run_cmd);
// _str minsdk = '';
// // extract target min api level from AndroidManifest.xml
// int h = _xmlcfg_open(maybe_quote_filename(projectDir :+ 'AndroidManifest.xml'),auto status);
// if (h >= 0) {
//    int node = _xmlcfg_find_simple(h,"/manifest/uses-sdk");
//    if (node >= 0) {
//       minsdk = _xmlcfg_get_attribute(h,node,'android:minSdkVersion');
//    }
//    _xmlcfg_close(h);
// }
// android_chooseEmulatorOrAutoLaunch(sdk, apk, pkg, act, minsdk);
   return '';
}

_str _properties_getValueForProperty(_str filename, _str property)
{
   _str val = '';
   if (!file_exists(filename)) {
      return val;
   }
   int status = _open_temp_view(filename, auto temp_view_id, auto orig_view_id);
   if (!status) {
      status=search('^'property'={#1?*}$',"@rh");
      if (!status) {
         val = get_match_text(1);
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   return val;
}

int _android_getRunArgs(_str &sdk, _str &apk, _str &pkg, _str &act, _str &ndk,
                        _str &target, boolean maybe_quote_sdk = true)
{
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   // locate sdk from local.propeties
   sdk = _properties_getValueForProperty(maybe_quote_filename(projectDir :+ "local.properties"),'sdk\.dir');
   _maybe_append_filesep(sdk);
   if (maybe_quote_sdk) {
      sdk = maybe_quote_filename(sdk);
   }
   // locate target from project.properties
   target = _properties_getValueForProperty(maybe_quote_filename(projectDir :+ "project.properties"),'target');

   int handle = _ProjectHandle();
   if (handle) {
      _ProjectGet_ActiveConfigOrExt(_project_name, handle, auto config);
      ndk = _ProjectGet_PreBuildCommandsList(handle, config);
      if (ndk != '') {
         ndk = _strip_filename(ndk,'N');
         ndk = isdirectory(ndk) ? ndk : '';
      }
      _str cwd = getcwd();
      cd(projectDir:+'bin');
      _str res = file_match('*-'lowcase(config)'*.apk -P',1);
      if (res != '') {
         apk = projectDir :+ 'bin' :+ FILESEP :+ res;
         if (lowcase(config) == 'debug' && endsWith(res,"-unaligned.apk")) {
            _str aligned = stranslate(res,'','-unaligned');
            _str aligned_full = projectDir :+ 'bin' :+ FILESEP :+ aligned;
            if (file_exists(maybe_quote_filename(aligned_full))) {
               apk = aligned_full;
            }
         }
      }
      cd(cwd);
   }

   int h = _xmlcfg_open(projectDir :+ 'AndroidManifest.xml',auto status);
   if (h >= 0) {
      int node = _xmlcfg_find_simple(h,"/manifest");
      if (node >= 0) {
         pkg = _xmlcfg_get_attribute(h,node,"package","");
      }
      int actNode = _xmlcfg_find_simple(h,'/manifest/application/activity');
      if (actNode >= 0) {
         act = _xmlcfg_get_attribute(h,actNode,"android:name","");
         if (act != '' && pos('.',act) == 1 && length(act) > 2) {
            act = substr(act,2);
         }
      }
      _xmlcfg_close(h);
   }

   return 0; 
}

int validTarget(_str target)
{
   if (target != '') {
      target = strip(target);
      if (!isinteger(target) || (int)target <= 0) {
         _message_box("Android Build Target must be positive integer value.");
         return 1;
      }
   } else {
      _message_box("Android Build Target must not be empty.");
      return 1;
   }
      
   return 0;
}

//TODO: need to update this to be in line with setupAndroidProject
_command int workspace_open_android(_str xmlFile = "", boolean create_ws=true) name_info(FILE_ARG'*,')
{
   if (xmlFile == "") {
      xmlFile = _OpenDialog('-new -mdi -modal',
                                 "Open Android Manifest XML File",
                                 '*.xml',     // Initial wildcards
                                 "Android Manifest File(AndroidManifest.xml),All Files("ALLFILES_RE")",  // file types
                                 OFN_FILEMUSTEXIST,
                                 '',      // Default extensions
                                 '',      // Initial filename
                                 '',      // Initial directory
                                 '',      // Reserved
                                 "Standard Open dialog box"
                                );
      if (xmlFile == "") {
         return(COMMAND_CANCELLED_RC);
      }
   }

   // make sure there are no quotes on xmlBuildFile
   xmlFile = strip(xmlFile, "B", " \t");
   xmlFile = strip(xmlFile, "B", "\"");

   // attempt to find the sdk location from local.properties
   _str dir = _file_path(xmlFile);
   _maybe_append_filesep(dir);
   _str sdk = _properties_getValueForProperty(maybe_quote_filename(dir :+ "local.properties"),'sdk\.dir');

   int status=show('-modal _android_update_form',sdk, xmlFile, create_ws);
   if (status) {
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      } else {
         return(status);
      }
   }

   _gwt_updateProjects();
   return 0;
}

_str _android_getNumberFromTarget(_str &target)
{
   if (target == '' || isnumber(target)) {
      return target;
   }
   _str apiLevel = '';
   if (!isnumber(target) && pos('id:',target) > 0 && length(target) > 5) {
      parse target with 'id:' auto n ' ' auto rest;
      if (strip(n) == '') {
         parse target with 'id: ' n ' ' rest;
      }
      target = strip(n);
      if (rest != '') {
         if (pos('android-{#1:n}',rest,1,'R') > 0) {
            apiLevel = substr(rest, pos('S1'));
         } else if (pos('?*\:{#2:n\"}',rest,1,'R') > 0) {
            apiLevel = substr(rest, pos('S2'));
         }
         if (apiLevel != '') {
            apiLevel = strip(apiLevel,'T','"');
         }
      }
   }
   return apiLevel;
}

static int android_getDeviceInfo(EMULATOR_INFO (&emus)[], _str sdk)
{
   mou_hour_glass(true);
   _str ports[];
   _str serials[];
   _str names[];
   _str states[];
   _str targets[];
   _str api_levels[];
   // first run 'adb devices' to get any running emulators...
   _str adb = sdk :+ "platform-tools" :+ FILESEP :+ ADB;
#if !__UNIX__
   adb :+= ".exe";
#endif
   adb = maybe_quote_filename(adb);
   _str temp_file = mktemp();
   if (temp_file == '') {
      mou_hour_glass(false);
      _message_box('Unable to retrieve Android device info: Error creating temp file');
      return 1;
   }
   _str cmd = maybe_quote_filename(adb) :+ ' devices > ' :+ maybe_quote_filename(temp_file);
   int status = shell(cmd, 'Q');
   if (status) {
      mou_hour_glass(false);
      _message_box("Unable to retrieve Android device info: Error executing 'adb devices'");
      return 1;
   }
   status = _open_temp_view(temp_file, auto temp_view_id, auto orig_view_id);
   if (!status) {
      // it's ok to skip the first line because it's not an actual result
      while (!down()) {
         get_line(auto line);
         parse line with auto name auto stat; 
         int cur = pos('emulator-{#1:n}',name,1,'R');
         if ((cur == 0 || pos('S1') == 1) && name != '') {
            serials[serials._length()] = name;
            ports[ports._length()] = 'N/A';
         } else if (name != '') {
            _str port = substr(name, pos('S1'),pos('1'));
            ports[ports._length()] = port;
            serials[serials._length()] = 'emulator-'port;
         } else {
            break;
         }
         if (pos('device',stat) == 1) {
            states[states._length()] = 'online';
         } else {
            states[states._length()] = 'offline';
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   delete_file(temp_file);
   // now get the names for each running emulator via tcp/ip
   int i = 0;
   for (i = 0; i < ports._length(); i++) {
      // can't connect if offline (not going to connect if not an emulator)
      // but it would be nice if we could determine the target for devices...
      if (states[i] == 'offline' || ports[i] == 'N/A') {
         names[i] = '';
         targets[i] = '';
         continue;
      }
      sc.net.ClientSocket client;
      status = client.connect("localhost",(int)ports[i]);
      if (client.isConnected()) {
         status = client.receive(auto reply,false,1000);
         status = client.receive(reply,false,1000);
         status = client.send("avd name\n");
         status = client.receive(reply,false,1000);
         if (!status && reply != '') {
            int emu_name = pos('^[ \t]*{#1[a-zA-Z0-9_\-\.]#}',reply,1,'R');
            if (emu_name > 0) {
               _str name = substr(reply, pos('S1'),pos('1'));
               names[names._length()] = name;
            } else {
               names[names._length()] = '';
            }
         } else {
            names[names._length()] = '';
         }
         client.close();
      } else {
         names[names._length()] = '';
      }
   }
   // now get the emulators which are not running, from 'android list avd'
   _str android = sdk :+ "tools" :+ FILESEP :+ ANDROID_TOOL;
#if !__UNIX__
   android :+= ".bat";
#endif
   android = maybe_quote_filename(android);
   temp_file = mktemp();
   if (temp_file == '') {
      // ? couldn't create temp file to hold results
      mou_hour_glass(false);
      return 1;
   }
   temp_file = maybe_quote_filename(temp_file);
   // _PipeShellResult isn't behaving well with this command, for some reason
   status = shell(android :+ ' list avd > ' :+ temp_file, 'Q');
   if (status) {
      // ? couldn't execute android tool
      mou_hour_glass(false);
      return 1;
   }
   // check the results of 'list avd' with what we found the API level to be from the .properties file
   status = _open_temp_view(temp_file, auto temp_view_id2, auto orig_view_id2);
   if (!status) {
      for (;;) {
         status=search('Name\:[ \t]{#1?*}$',"@rh");
         if (status) {
            break;
         }
         _str name = strip(get_match_text(1));
         // determine if we already have this name yet 
         int found = -1;
         for (i = 0; i < names._length(); i++) {
            if (name == names[i]) {
               found = i;
               break;
            }
         }
         status=search('Target\:[ \t]{#2?*}$',"@rh");
         _str t = '';
         if (!status) {
            t = get_match_text(2);
            if (pos('API level {#3}', t) > 0) {
               // set api level...TBD, unused for now
            }
         } else {
            down();
         }
         if (found == -1) {
            int num_emu = names._length();
            names[num_emu] = name;
            serials[num_emu] = 'N/A';
            targets[num_emu] = t;
            states[num_emu] = 'not running';
            ports[num_emu] = 'N/A';
         } else {
            targets[found] = t;
         }
      }
      _delete_temp_view(temp_view_id2);
      activate_window(orig_view_id2);
   }
   delete_file(temp_file);
   for (i = 0; i < names._length(); i++) {
      emus[i].api_level = "";
      emus[i].name = names[i]; 
      emus[i].port = ports[i]; 
      emus[i].serial = serials[i]; 
      emus[i].state = states[i]; 
      emus[i].target = targets[i]; 
   }
   mou_hour_glass(false);
   return 0;
}

_command void android_avd_manager() name_info(',')
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for active project.");
      return;
   }
   _maybe_append_filesep(sdk);
   _str cmd_string = '';
#if !__UNIX__
   cmd_string = sdk :+ 'AVD Manager.exe';
   shell(maybe_quote_filename(cmd_string), 'AQ');
#else
   cmd_string = sdk :+ 'tools' :+ FILESEP :+ 'android';
   shell(maybe_quote_filename(cmd_string)' avd', 'AQ');
#endif
}

_command void android_sdk_manager() name_info(',')
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for active project.");
      return;
   }
   _maybe_append_filesep(sdk);
   _str cmd_string = '';
#if !__UNIX__
   cmd_string = sdk :+ 'SDK Manager.exe';
#else
   cmd_string = sdk :+ 'tools' :+ FILESEP :+ 'android';
#endif
   shell(maybe_quote_filename(cmd_string), 'AQ');
}

_command void android_ddms() name_info(',')
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for active project.");
      return;
   }
   _maybe_append_filesep(sdk);
   _str cmd_string = '';
   cmd_string = sdk :+ 'tools' :+ FILESEP :+ 'ddms';
#if !__UNIX__
   cmd_string :+= '.bat';
#endif
   shell(maybe_quote_filename(cmd_string), 'AQ');
}

void _prjopen_android()
{
   int h = _ProjectHandle();
   if (h) {
      _str apptype = _ProjectGet_AppType(h);
      if (apptype == "android") {
         int wid = _tbIsVisible("_tbandroid_form");
         if (wid <= 0) {
            toggle_android();
         }
      }
   }
}

void _project_close_android()
{
   int h = _ProjectHandle();
   if (h) {
      _str apptype = _ProjectGet_AppType(h);
      if (apptype == "android") {
         int wid = _tbIsVisible("_tbandroid_form");
         if (wid > 0) {
            toggle_android();
         }
      }
   }
}

/**
 * The pre-clean macro for use with Android NDK projects.  It 
 * will run 'ndk-build clean' before running the normal Android 
 * clean operation in order to clean the native libs as well as 
 * the other stuff. 
 *
 * This command is only intended to be run from the 'rebuild' or 
 * 'clean' build tool. 
 */
_command int android_pre_clean()
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (ndk != '' && isdirectory(ndk)) {
      _maybe_append_filesep(ndk);
      _str ndk_build = ndk :+ 'ndk-build';
      _str projectDir = _file_path(_project_name);
      cd(projectDir);
      // this has to be executed synchronously because of rebuild
      shell(ndk_build' clean','Q');
   }
   return(0);
}

/**
 * Retrieve a string which contains the attach info for vsdebug 
 * to use to attach to a running Android process with GDB.  This 
 * is only used for Android applications which use the NDK. 
 * 
 * @return _str debug attach info 
 */
_str _android_get_attach_info()
{
   // retrieve the serial for the device if we have more than 1 online device
   _str device_info = android_runAppOnDevice(true);
   if (device_info == '') {
      return '';
   }
   mou_hour_glass(1);
   parse device_info with 'serial=' auto serial ',' .;
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   cd(projectDir);
   // locate our ndk-gdb and run the script
   _str ndk_gdb = maybe_quote_filename(get_env('VSROOT'):+'resource'FILESEP'tools'FILESEP'ndk-gdb'FILESEP'ndk-gdb');
   _str ndk_gdb_cmd = 'bash 'ndk_gdb' --force';
   ndk_gdb_cmd = serial == '' ? ndk_gdb_cmd : ndk_gdb_cmd :+ ' -s ' :+ serial;
   int status = shell(ndk_gdb_cmd,'Q');
//    _str res = _PipeShellResult('bash 'ndk_gdb' --force', auto status, 'C');
   if (status < 0) {
      _message_box('Error running ndk-gdb: 'get_message(status));
      mou_hour_glass(0);
      return '';
   }
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (ndk == '') {
      _message_box('Unable to locate Android NDK directory. Please check that your project is set up to use the NDK.');
      mou_hour_glass(0);
      return '';
   }
   _maybe_append_filesep(ndk);
   // fileseps must be / for the make command, no matter the platform 
   ndk = stranslate(ndk,'/',"\\");
   ndk = stranslate(ndk,'/','\');
   // check NDK_OUT env var, which will override the default output location
   _str ndkout = get_env('NDK_OUT');
   if (ndkout == '') {
      ndkout = projectDir'obj'FILESEP'local'FILESEP;
   } else {
      _maybe_append_filesep(ndkout);
      ndkout = ndkout'local'FILESEP;
   }
   _str path_make = path_search('make','PATH','P');
   if (path_make == '') {
      path_make = 'make';
   }
   // use makefile to determine the target ABI(s) of the application
   _str res = _PipeShellResult(path_make' --no-print-dir -f 'ndk'build/core/build-local.mk -C 'projectDir' DUMP_APP_ABI', status);
   _str app_abi = stranslate(res,'',"[\r\n]",'r');
   split(app_abi, ' ', auto platforms);
   boolean found_compat_abi = false;
   if (platforms._length() == 1) {
      // if there is only 1 ABI we just go with that
      app_abi = strip(platforms[0]);
      found_compat_abi = true;
   } else if (platforms._length() > 1) {
      // if there is more than one target ABI for the application, check the ABI(s) 
      // supported on the device and as soon as we find a compatible one, use that
      // this algorithm comes from the ndk-gdb script
      _str adb = sdk :+ "platform-tools" :+ FILESEP :+ ADB;
#if !__UNIX__
      adb :+= ".exe";
#endif
      adb = maybe_quote_filename(adb);
      if (serial != '') {
         adb = adb :+ ' -s 'serial;
      }
      _str cpu_abi = _PipeShellResult(adb:+' shell getprop ro.product.cpu.abi', status, 'H'); 
      cpu_abi = stranslate(cpu_abi,'',"[\r\n]",'r');
      int i = 0;
      for (i; i < platforms._length(); i++) {
         if (strip(platforms[i] == cpu_abi)) {
            app_abi = cpu_abi;
            found_compat_abi = true;
            break;
         }
      }
      if (!found_compat_abi) {
         _str cpu_abi2 = _PipeShellResult(adb:+' shell getprop ro.product.cpu.abi2', status, 'H'); 
         cpu_abi2 = stranslate(cpu_abi2,'',"[\r\n]",'r');
         for (i = 0; i < platforms._length(); i++) {
            if (strip(platforms[i] == cpu_abi2)) {
               app_abi = cpu_abi2;
               found_compat_abi = true;
               break;
            }
         }
      }
   }
   if (!found_compat_abi) {
      _message_box("The device does not support the application's targetted ABI(s).");
      mou_hour_glass(0);
      return '';
   }
   ndkout = ndkout:+app_abi:+FILESEP;
   // format the gdb.setup that ndk-gdb creates, we don't want any leading spaces on the lines with cmds 
   if (file_exists(ndkout:+'gdb.setup')) {
      status = _open_temp_view(ndkout:+'gdb.setup', auto temp_view_id, auto orig_view_id);
      if (!status) {
         // the first line seems to always be fine...
         while (!down()) {
            strip_leading_spaces();
         }
         // must save gdb command file with unix style line endings (line feed only)
         status = _save_file("+O +FU "ndkout:+"gdb.setup");
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
      } else {
         _message_box('Error opening gdb.setup script: 'get_message(status));
         mou_hour_glass(0);
         return '';
      }
   } else {
      _message_box('Unable to locate gdb.setup script at 'ndkout'.');
      mou_hour_glass(0);
      return '';
   }
   _str file_name = 'file='ndkout :+ 'app_process'; 
   _str host = 'host=localhost'; 
   _str port = 'port=5039'; 
   _str timeout = 'timeout=15';
   _str address = 'address=32'; 
   _str cache = 'cache=0'; 
   _str break_opt = 'break=0'; 
   dbg_gdb_get_default_configuration(auto gdb_name, auto gdb_path, auto gdb_args);
   _str path = 'path='gdb_path;
   _str args = 'args=-x 'ndkout'gdb.setup'; 
   if (gdb_args != '') {
      args :+= gdb_args;
   }
   // path to gdb setup script must have / separators on all platforms
   args = stranslate(args,'/',"\\");
   args = stranslate(args,'/','\');
   _str attach_info = file_name','host','port','timeout','address','cache','break_opt','path','args; 
   mou_hour_glass(0);
   return attach_info;
}
