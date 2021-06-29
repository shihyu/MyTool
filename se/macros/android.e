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
#include "pipe.sh"
#include "codetemplate.sh"
#import "cformat.e"
#import "compile.e"
#import "context.e"
#import "clipbd.e"
#import "ctadditem.e"
#import "debuggui.e"
#import "debug.e"
#import "diffprog.e"
#import "dir.e"
#import "doscmds.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "gwt.e"
#import "help.e"
#import "java.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "menu.e"
#import "mprompt.e"
#import "os2cmds.e"
#import "picture.e"
#import "pipe.e"
#import "pmatch.e"
#import "projconv.e"
#import "project.e"
#import "rte.e"
#import "se/ui/toolwindow.e"
#import "seltree.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbcmds.e"
#import "toolbar.e"
#import "treeview.e"
#import "wkspace.e"
#require "sc/net/ClientSocket.e"
#require "sc/lang/String.e"
#require "se/tags/TaggingGuard.e";
#endregion

struct RunningEmulator {
   _str name;
   int pid;
   _str logfile;
};

// Switch for debug logging.
int def_debug_android = 0;

// We keep track of running emulators, we can report a bad status if needed.
#define EMU_CHECK_INTERVAL 1000
static RunningEmulator gEmulators:[];
int gEmulatorTimer = -1;
int gEmuGate = 0;
definit()
{
   def_debug_android = 0;
   gEmulators._makeempty();
   gEmulatorTimer = -1;
   gEmuGate = 0;
}

static _str get_VSANDROIDRUN_EXE() {
   return ("vsandroidrun":+EXTENSION_EXE);
}

struct EMULATOR_INFO {
   _str port;
   _str serial;
   _str name;
   _str state;
   _str target;
   _str api_level;
};

// SDK manager package.
struct SDKRec {
   _str id; // ie: system-images;android-27;default;armeabi-v7a
   _str version;
   _str description;
   bool installed;
   bool updateAvailable;
};

struct AVDRec {
   _str name;
   _str device; // id of hardware platform, plus OEM in parens.  ie: "Nexus S (Google)"
   _str target;
   _str sdcard;
   _str status;  // 'Running', 'Stopped', 'Unknown'.
};

// Used for avdmanager targets (list target) and hw devices (list device).
struct NamedEntry {
   _str id;
   _str name;
};

// Map from API level to user surfaced android verion and name.
static _str AndroidVersions:[] = {
   "1" => "1.0 Base", 
   "2" => "1.1 Base", 
   "3" => "1.5 Cupcake", 
   "4" => "1.6 Donut", 
   "5" => "2.0 Eclair", 
   "6" => "2.0.1 Eclair", 
   "7" => "2.1.x Eclair",
   "8" => "2.2.x Froyo",
   "9" => "2.3.2 Gingerbread",
   "10" => "2.3.4 Gingerbread",
   "11" => "3.0 Honeycomb", 
   "12" => "3.1 Honeycomb",
   "13" => "3.2 Honeycomb", 
   "14" => "4.0.2 Ice Cream Sandwich",
   "15" => "4.0.4 Ice Cream Sandwich", 
   "16" => "4.1.1 Jelly Bean", 
   "17" => "4.2.2 Jelly Bean", 
   "18" => "4.3 Jelly Bean", 
   "19" => "4.4 Kit Kat", 
   "20" => "4.4 Wearable Kit Kat",
   "21" => "5.0 Lollipop", 
   "22" => "5.1 Lollipop", 
   "23" => "6.0 Marshmallow",
   "24" => "7.0 Nougat", 
   "25" => "7.1.1 Nougat", 
   "26" => "8.0 Oreo", 
   "27" => "8.1 Oreo", 
   "28" => "9 Pie"
};


static ExecState gInstallState;

static _str sdkmanager_exe(_str sdk)
{
   return sdk'tools'FILESEP'bin'FILESEP'sdkmanager'EXTENSION_EXE;
}

static bool check_for_license_prompt(int view, int startLine, _str& licText)
{
   ov := p_window_id;
   p_window_id = view;
   p_line = startLine;
   rc := search('License [a-zA-Z0-9\-]+', '@L');
   if (rc != 0) return false;
   
   // License text is bordered by two rows of repeated dashes.
   rc = search('^--------', '@L');
   if (rc != 0) {
      p_window_id = ov;
      return false;
   }
   down();
   p_col = 1;
   start :=_QROffset();
   rc = search('^--------', '@L');
   if (rc != 0) {
      // We haven't gotten the full license text yet, go back for some 
      // more reads.
      p_window_id = ov;
      return false;
   }
   up();
   _end_line();
   endOff := _QROffset();

   _GoToROffset(start);
   licText = get_text((int)(endOff - start));

   // Position the cursor after the end of the license, so we can correctly handle the
   // case where there is more than once license prompt.
   _GoToROffset(endOff);
   down();

   p_window_id = ov;
   return true;
}

const PROMPTING_FOR_LICENSE = 6;

static int user_license_prompt(int tempView, _str license)
{
   return show('-modal _android_license_accept_form', tempView, license);
}

// Watches the output of the SDK/tool install, prompting the user
// to accept licenses if necessary.
static int handle_sdk_install(int tempView)
{
   p_window_id = tempView;
   startLine := p_line;

   licensePrompted := false;
   while (!gInstallState.finished) {
      delay(5);
      exec_handle_pipes(gInstallState);
      if (!licensePrompted) {
         licensePrompted = check_for_license_prompt(tempView, startLine, auto licText);
         if (licensePrompted) {
            // Launch the dialog to prompt the user, and exit immediately. 
            // The dialog handler can finish up the pipe connection.
            user_license_prompt(tempView, licText);
            return PROMPTING_FOR_LICENSE;
         }
      }
   }
   return gInstallState.result;
}

// Each package name in packageNames should be double quoted.
static int install_sdk_package(_str sdk, _str packageNames)
{
   sman := sdkmanager_exe(sdk);
   cmd := sman' 'packageNames;

   origView := _create_temp_view(auto tempView, '', 'SDK Install');
   if (origView < 0) {
      if (def_debug_android > 0) say('  could not create temp view.');
      return origView;
   }

   int progCount = 100;
   progress := progress_show('Installing Package', progCount);
   rv := exec_piped_command(gInstallState, cmd, tempView, output_window_text_control(), progress, progCount, 
                            true);
   if (rv < 0) {
      _message_box('Problem installing 'packageNames', see Output tool window for details.');
      activate_window(origView);
      _delete_temp_view(tempView);
      return rv;
   }

   // Since we called the exec with a temp view, go ahead and replace its record
   // with our real original view, as we don't want to revert back to the temp
   // view after it has been deleted.
   gInstallState.curWin = origView;

   rv = handle_sdk_install(tempView);
   if (rv == PROMPTING_FOR_LICENSE) {
      return 0;
   } else {
      progress_close(progress);
      exec_cleanup_piped_command(gInstallState);
      activate_window(origView);
      _delete_temp_view(tempView);
      return rv;
   }
}

// Runs a command, sending the output to a temp view.  
// Returns status code, and the name of the temp view in ``tempView``.
// If the status code == 0, it's up to the caller to delete ``tempView``
// when done. The cursor is positioned at the top of the temp view when done.
static int command_to_temp_view(_str cmdline, int& tempView, int& origView, CTL_FORM progress = -1, int progressCount = 0)
{
   outWin := output_window_text_control();
   origView = _create_temp_view(tempView, '', cmdline);
   if (origView == 0) {
      return COMMAND_CANCELLED_RC;
   }

   oldmp := p_mouse_pointer;
   p_mouse_pointer = MP_HOUR_GLASS;
   rc := exec_command_to_window(cmdline, tempView, outWin, progress, progressCount);
   if (rc != 0) {
      sticky_message('Bad return code from command, see Output window: 'rc);
      p_window_id = origView;
      _delete_temp_view(tempView);
   }  else {
      top();
   }

   p_mouse_pointer = oldmp;
   return rc;
}

// Convert plain license text to something that renders correctly in a HTML control.
static _str htmlize(_str txt)
{
   return stranslate(txt, "<br>\n", "\n");
}


const NVREGEX = '^ *([\w ]+): *(.*)$';

// Parses name value pairs from avdmanager output into a dict.
// Reads lines in the current buffer until one of them doesn't parse.
// Leaves p_line on the line that didn't parse as a name:value.
static void read_name_value_pairs(_str (&table):[])
{
   table._makeempty();
   
   // Scan down until we find a nvpair to start at.
   _str line;
   found := false;
   do {
      get_line(line);
      if (pos(NVREGEX, line, 1, 'L') > 0) {
         found = true;
         break;
      }
   } while (down() == 0);

   if (!found) return;

   do {
      get_line(line);
      if (pos(NVREGEX, line, 1, 'L') == 0) {
         break;
      }
      key := strip(substr(line, pos('S1'), pos('1')));
      val := strip(substr(line, pos('S2'), pos('2')));
      if (key == 'Target') {
         // Have to special case here, because they put two lines of information for this 
         // key.  We're only interested in the second line.
         down();
         get_line(line);
         table:[key] = strip(line);
      } else {
         table:[key] = val;
      }
   } while (down() == 0);
}

static _str avdmanager_exe(_str sdk)
{
   return sdk'tools'FILESEP'bin'FILESEP'avdmanager'EXTENSION_BAT;
}

// Used to provide more detailed error information for 
// AVD's that are missing the requisite system image.
static _str extract_api_level_from_ini(_str avdPath)
{
   if (avdPath._length() == 0) {
      return '';
   }

  ini := _strip_filename(avdPath, 'E')'.ini';
  if (!file_exists(ini)) {
     return '';
  }

  rc := _open_temp_view(ini, auto tempWid, auto origWid);
  if (rc < 0) return '';

  rc = search('^target=(.*+)$', 'L@');
  if (rc < 0) {
     p_window_id = origWid;
     _delete_temp_view(tempWid);
     return '';
  }

  rv := get_text(match_length('1'), match_length('S1'));
  p_window_id = origWid;
  _delete_temp_view(tempWid);
  return rv;
}

// Returns <0 if there was a problem fetching the records from avdmanager.
static int load_existing_avds(_str sdk, AVDRec (&recs)[], int progress, int progressCount)
{
   recs._makeempty();
   cmd := avdmanager_exe(sdk)' list avd';
   rc := command_to_temp_view(cmd, auto tempView, auto origView, progress, progressCount);
   if (rc < 0) return rc;

   rc = search(' *Name:', 'L@');
   if (rc != 0) {
      activate_window(origView);
      _delete_temp_view(tempView);
      return 0;
   }

   _str table:[];

   do {
      AVDRec rec;
      rec._makeempty();
      read_name_value_pairs(table);
      if (table._length() > 0) {
         rec.name = table:['Name'];
         if (table._indexin('Error')) {
            rec.target = 'ERROR: ('extract_api_level_from_ini(table:['Path'])') 'table:['Error'];
            rec.device = '';
            rec.sdcard = '';
         } else {
            if (table._indexin('Target')) {
               rec.target = table:['Target'];
               if (beginsWith(rec.target, 'Based on: ')) {
                  rec.target = strip(substr(rec.target, 10));
               }
               rec.device = table:['Device'];
               rec.sdcard = table:['Sdcard'];
            } else {
               continue;
            }
         }
         rec.status = 'Stopped';
         recs :+= rec;
      }
   } while (table._length() > 0);

   activate_window(origView);
   _delete_temp_view(tempView);
   return 0;
}

static int load_named_entries(NamedEntry (&ents)[], int tempView, int origView, int progress, int progCount)
{
   rc := search('------', 'L@');
   if (rc != 0) {
      activate_window(origView);
      _delete_temp_view(tempView);
      return 0;
   }

   _str table:[];
   do {
      NamedEntry ent;
      ent._makeempty();
      read_name_value_pairs(table);
      if (table._length() > 0) {
         id := strip(table:['id']);
         if (pos('(\d+) or "([^"]+)', id, 1, 'L') > 0) {
            ent.id = substr(id, pos('S1'), pos('1'));
            named_id := substr(id, pos('S2'), pos('2'));
            ent.name = table:['Name'];
            if (ent.name != named_id) {
               // There are several entries that have the same name, so add the named id to help differentiate.
               ent.name :+= ' ('named_id')';
            }
         } else {
            ent.id = id;
            ent.name = table:['Name'];
         }
         ents :+= ent;
      }
   } while (table._length() > 0);

   activate_window(origView);
   _delete_temp_view(tempView);
   return 0;
}

static int load_available_targets(_str sdk, NamedEntry (&ents)[], int progress, int progressCount)
{
   ents._makeempty();
   cmd := avdmanager_exe(sdk)' list target';
   rc := command_to_temp_view(cmd, auto tempView, auto origView, progress, progressCount);
   if (rc < 0) return rc;

   return load_named_entries(ents,tempView,origView,progress,progressCount);
}

// ie: avdmanager list device - hw devices that can be referenced when creating a new AVD.
static int load_available_devices(_str sdk, NamedEntry (&ents)[], int progress, int progressCount)
{
   ents._makeempty();
   cmd := avdmanager_exe(sdk)' list device';
   rc := command_to_temp_view(cmd, auto tempView, auto origView, progress, progressCount);
   if (rc < 0) return rc;

   return load_named_entries(ents,tempView,origView,progress,progressCount);
}


defeventtab _android_license_accept_form;
static int gInstallTempView;
void _android_license_accept_form.on_create(int tempView, _str licText)
{
   _ctl_license_text.p_text = htmlize(licText);
   gInstallTempView = tempView;
}

void _ctl_accept.lbutton_up()
{
   _PipeWrite(gInstallState.procStdin, "y\r\n");
   p_active_form._delete_window('');
   rv := handle_sdk_install(gInstallTempView);
   if (rv != PROMPTING_FOR_LICENSE) {
      progress_close(gInstallState.progress);
      exec_cleanup_piped_command(gInstallState);
      _delete_temp_view(gInstallTempView);
   }
}

void _ctl_cancel.lbutton_up()
{
   _PipeWrite(gInstallState.procStdin, "n\r\n");
   p_active_form._delete_window('');

   // Go ahead and let the process end normally, so we don't end up with orphaned
   // lock files or anything else unpleasant
   rv := handle_sdk_install(gInstallTempView);
   if (rv != PROMPTING_FOR_LICENSE) {
      progress_close(gInstallState.progress);
      exec_cleanup_piped_command(gInstallState);
      _delete_temp_view(gInstallTempView);
   }
}

void _android_license_accept_form.on_resize()
{
   hmargin := _ctl_license_text.p_x;
   vmargin := _ctl_license_text.p_y;
   _ctl_cancel.p_x = p_width - hmargin - _ctl_cancel.p_width;
   _ctl_cancel.p_y = p_height - vmargin - _ctl_cancel.p_height;
   _ctl_accept.p_x = _ctl_cancel.p_x - hmargin - _ctl_accept.p_width;
   _ctl_accept.p_y = _ctl_cancel.p_y;
   _ctl_license_text.p_width = p_width - hmargin*2;
   _ctl_license_text.p_height = _ctl_accept.p_y - vmargin - _ctl_license_text.p_y;
}

static _str pkg_description(SDKRec& r)
{
   state := ' ';
   if (r.updateAvailable) {
      state = 'Update Available';
   } else if (r.installed) {
      state = 'Installed';
   }

   desc := r.description;
   if (desc == 'Google APIs') {
      desc :+= ' (addon)';
   }
   return desc"\t"r.version"\t"state;
}

defeventtab _android_sdk_manager_form;
static SDKRec gCurPackages[];
static _str gSdk;
static void update_tool_list(SDKRec (&pkgs)[])
{
   _ctl_pkglist._TreeBeginUpdate(TREE_ROOT_INDEX);
   _ctl_pkglist._TreeDelete(TREE_ROOT_INDEX, "C");

   // Search for maximum api platform.
   sdks := _ctl_showing.p_window_id.p_text == 'SDKs';
   if (sdks) {
       max_api := 25;
       for (i:=0; i < pkgs._length(); i++) {
          if (beginsWith(pkgs[i].id, 'platforms;android-')) {
             s := substr(pkgs[i].id, 19);
             if (isinteger(s)) {
                v := (int)s;
                if (v > max_api) {
                   max_api = v;
                }
             }
          }
       }
   
       for (i = max_api; i > 0; i--) {
          caption := '';
          if (AndroidVersions._indexin(i)) {
             caption = AndroidVersions:[i]' ';
          }
          caption :+= '(API Level 'i')';
          _ctl_pkglist._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, TREENODE_BOLD, -1);
          for (j := 0; j < pkgs._length(); j++) {
             if (j == i) continue;
             if (pos('android-'i'($|;)', pkgs[j].id, 1, 'L') > 0 ||
                 pos('addon-google_apis-google-'i'$', pkgs[j].id, 1, 'L') > 0) {
                _ctl_pkglist._TreeAddListItem('   'pkg_description(pkgs[j]), 0, TREE_ROOT_INDEX, TREE_NODE_LEAF, j);
             }
          }
       }
   } else {
    for (i := 0; i < pkgs._length(); i++) {
       if (pos('android-\d+', pkgs[i].id, 1, 'L') > 0 ||
           pos('addon-google_apis-google-\d+', pkgs[i].id, 1, 'L') > 0) {
          continue;
       }
       _ctl_pkglist._TreeAddItem(TREE_ROOT_INDEX, pkg_description(pkgs[i]), TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF, 0, i);
      }
   }

   _ctl_pkglist._TreeEndUpdate(TREE_ROOT_INDEX);
}

static void resize_tree_columns()
{
   cw := _ctl_pkglist.p_width intdiv 10;
   _ctl_pkglist._TreeSetColButtonInfo(0, cw * 8, -1, -1, 'Name');
   _ctl_pkglist._TreeSetColButtonInfo(1, cw, -1, -1, 'Version');
   _ctl_pkglist._TreeSetColButtonInfo(2, cw, -1, -1, 'Status');
}

void _android_sdk_manager_form.on_resize()
{
   vmargin := _ctl_showing.p_y;
   hmargin := _ctl_pkglist.p_x;
   bmargin := 100;
   buttY := p_height - vmargin - _ctl_close.p_height;
    
   _ctl_close.p_x = p_width - hmargin - _ctl_close.p_width;
   _ctl_close.p_y = buttY;

   _ctl_uninstall.p_x = _ctl_close.p_x - bmargin - _ctl_uninstall.p_width;
   _ctl_uninstall.p_y = buttY;

   _ctl_install.p_x = _ctl_uninstall.p_x - bmargin - _ctl_install.p_width;
   _ctl_install.p_y = buttY;

   _ctl_pkglist.p_width = p_width - hmargin*2;
   _ctl_pkglist.p_height = buttY - vmargin - _ctl_pkglist.p_y;
   resize_tree_columns();
}

void _android_sdk_manager_form.on_create(SDKRec (&pkgs)[], _str sdk)
{
   _ctl_showing.p_window_id._lbadd_item('SDKs');
   _ctl_showing.p_window_id._lbadd_item('Tools');
   _ctl_showing.p_window_id.p_line = 0;
   _ctl_showing.p_window_id._lbselect_line();

   resize_tree_columns();

   _str names[];

   names._makeempty();
   for (i:=0; i < pkgs._length(); i++) {
      names :+= pkgs[i].description'!'i;
   }
   names._sort();
   
   SDKRec tmps[] = pkgs;
   for (i = 0; i < names._length(); i++) {
      parse names[i] with auto nm '!' auto idx;
      pkgs[i] = tmps[(int)idx];
   }

   update_tool_list(pkgs);
   gCurPackages = pkgs;
   gSdk = sdk;
}

void _ctl_showing.on_change2()
{
   update_tool_list(gCurPackages);
}

void _ctl_close.lbutton_up()
{
   p_active_form._delete_window();
}

void _ctl_install.lbutton_up()
{
   int indices[];

   _ctl_pkglist._TreeGetSelectionIndices(indices);
   if (indices._length() == 0) return;

   pkgs := '';
   _str extradeps:[]; extradeps._makeempty();
   for (i := 0; i < indices._length(); i++) {
      int idx = _ctl_pkglist._TreeGetUserInfo(indices[i]);
      if (idx >= 0) {
         pknm := gCurPackages[idx].id;
         if (pos('system-images;android-([0-9]+)', pknm, 1, 'L')) {
            // To save some confusion with emulators, if the user installs a system image
            // for API level N, make sure the platform SDK for N is also 
            // installed.  Otherwise the user will have to solve the mystery of why
            // the image doesn't show up as a choice when they go to create an emulator.
            api := substr(pknm, pos('S1'), pos('1'));
            if (!platform_installed(gSdk, api)) {
               extradeps:['platforms;android-'api] = '';
            }
         }
         pkgs :+= ' "'pknm'"';
         gCurPackages[idx].installed = true;
      }
   }

   foreach (auto key => auto v in extradeps) {
      pkgs :+= ' "'key'"';
   }

   if (pkgs == '') {
      _ctl_pkglist._TreeDeselectAll();
      return;
   }

   install_sdk_package(gSdk, pkgs);

   oldScroll := _ctl_pkglist._TreeScroll();
   update_tool_list(gCurPackages);

   // If we don't process the pending tree events here, they will clobber
   // the scroll position we're setting.
   cancel := false;
   process_events(cancel, 'T');
   _ctl_pkglist._TreeScroll(oldScroll);
}

void _ctl_uninstall.lbutton_up()
{
   int indices[];

   _ctl_pkglist._TreeGetSelectionIndices(indices);
   if (indices._length() == 0) return;
   pkgs := '';
   for (i := 0; i < indices._length(); i++) {
      int idx = _ctl_pkglist._TreeGetUserInfo(indices[i]);
      if (idx >= 0) {
         pkgs :+= ' "'gCurPackages[idx].id'"';
         gCurPackages[idx].installed = false;
      }
   }

   if (pkgs == '') {
      _ctl_pkglist._TreeDeselectAll();
      return;
   }

   int progCount = 100;
   progress := progress_show('Uninstalling Packages', progCount);
   cmd := sdkmanager_exe(gSdk)' --uninstall 'pkgs;
   rv := exec_command_to_window(cmd, output_window_text_control(), -1, progress, progCount);
   if (rv < 0) {
      _message_box('Problem uninstalling package, see Output tool window for details.');
   } else {
      oldScroll := _ctl_pkglist._TreeScroll();
      update_tool_list(gCurPackages);
      // If we don't process the pending tree events here, they will clobber
      // the scroll position we're setting.
      cancel := false;
      process_events(cancel, 'T');
      _ctl_pkglist._TreeScroll(oldScroll);
   }
   progress_close(progress);
}

defeventtab _android_device_form;

void ctl_ok.lbutton_up()
{
   int wait_for_debugger = wait_box.p_value;
   emu := false;
   dev := false;
   index := ctl_emulators._TreeGetNextSelectedIndex(1, auto info);
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
   emulator := "";
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
      state :+= ' 'state2;
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

void _android_device_form.on_create(EMULATOR_INFO emulators[], bool get_serial = false, bool debug_app = false)
{
   if (get_serial) {
      p_caption = 'Choose a Device to Debug';
      wait_box.p_visible = false;
   } else {
      wait_box.p_value = debug_app ? 1 : 0;
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
      more_flags := 0;
      caption :=  emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
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
   ctl_emulators._TreeAdjustColumnWidths(-1, null, 120);
   ctl_hardware._TreeTop();
   ctl_hardware._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_hardware._TreeAdjustColumnWidths(-1, null, 120);
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
      more_flags := 0;
      caption :=  emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
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
      more_flags := 0;
      caption :=  emulators[i].serial"\t"emulators[i].name"\t"emulators[i].target"\t"emulators[i].state;
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

   client_height := p_height;
   client_width := p_width;

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

   heightDiff := client_height - (ctl_ok.p_y_extent + 2 * ypadding);
   if (heightDiff) {
      emulator_frame.p_height += heightDiff intdiv 2;
      hardware_frame.p_y += heightDiff intdiv 2;
      hardware_frame.p_height += heightDiff intdiv 2;
      ctl_emulators.p_height += heightDiff intdiv 2;
      ctl_hardware.p_height += heightDiff intdiv 2;
      wait_box.p_y += heightDiff;
   }

   // place buttons
   ctl_refresh.p_y = wait_box.p_y_extent + ypadding; 
   ctl_ok.p_y = ctl_refresh.p_y;
   ctl_cancel.p_y = ctl_refresh.p_y;
   ctl_avd.p_y = ctl_refresh.p_y;
}

void ctl_avd.lbutton_up()
{
   android_avd_manager();
}

defeventtab _android_update_form;

void _android_update_form.on_create(_str sdk="", _str man_file="", bool create_ws=true)
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
   rightAlign := android_update_frame.p_width - android_update_frame.p_x;
   sizeBrowseButtonToTextBox(android_loc_box.p_window_id, android_sdk_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(android_target_box.p_window_id, android_targetid_choose.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(android_ndk_box.p_window_id, android_ndk_browse.p_window_id, 0, rightAlign);
}

void ctlndk.lbutton_up()
{
   enable := (ctlndk.p_value == 1);
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
   bool create_ws = _param2;
   p_active_form._delete_window("");
   typeless *pfnCancelButton=setupExistingAndroidProject;
   int status=(*pfnCancelButton)("", "", "", man_file, false, 0, "", create_ws);
}

void android_sdk_browse.lbutton_up()
{
   wid := p_window_id;
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
   bool create_ws = _param2;
   name := strip(android_prjname_box.p_text);
   sdk := strip(android_loc_box.p_text);
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
   }
   int uses_ndk = ctlndk.p_value;
   ndk := android_ndk_box.p_text;
   if (ndk != "" && pos('"',ndk)) {
      ndk = stranslate(ndk,'','"');
   }
   target := strip(android_target_box.p_text);
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
   }
}

defeventtab _android_library_form;
void _android_library_form.on_create(_str flags = '')
{
   _retrieve_prev_form();
   if (strip(_ctl_sdk.p_text) == '') {
      if (pos('adding', flags) > 0) {
         pfile := _strip_filename(_workspace_filename, 'N'); _maybe_append_filesep(pfile);
         pfile :+= 'local.properties';
         sdk := _properties_getValueForProperty(_maybe_quote_filename(pfile),'sdk\.dir');
         sdk = stranslate(sdk, '\', '\\');
         sdk = stranslate(sdk, ':', '\:');
         _ctl_sdk.p_text = sdk;
      } else {
         _ctl_sdk.p_text = gSdk;
      }
   }
   dlibname := _strip_filename(_strip_filename(_project_name, 'P'), 'E');
   _ctl_name.p_text = dlibname;
   rightAlign := p_width - _text_width('WW');
   sizeBrowseButtonToTextBox(_ctl_minsdk.p_window_id, android_target_choose.p_window_id, 0, rightAlign);
}

void _ctl_minsdk.on_change()
{
   target := _ctl_minsdk.p_text;
   _str minsdk = _android_getNumberFromTarget(target);
   if (minsdk != '' && isnumber(minsdk)) {
      _ctl_minsdk.p_text = minsdk;
   }
}

_command void android_selectMinSDK(_str target = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) return;
   _nocheck _control _ctl_minsdk;
   _ctl_minsdk.p_text = target;
   p_window_id=_ctl_minsdk;
   _set_focus();
}

void _on_popup2_lib_targets(_str menu_name, int menu_handle)
{
   if (menu_name :!= "_android_lib_menu") {
      return;
   }
   sdk := strip(_ctl_sdk.p_text);
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
      _ctl_sdk.p_text = sdk;
   }
   _maybe_append_filesep(sdk);

   int status = _android_getTargetsFromSDK(sdk, auto targets);
   i := 0;
   for (i = 0; i < targets._length(); i++) {
      _menu_insert(menu_handle, -1, MF_ENABLED, targets[i], "android-selectMinSdK ":+targets[i]);
   }
}

void android_dir_browse.lbutton_up()
{
   wid := p_window_id;
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

void _ctl_ok.lbutton_up()
{
   target := strip(_ctl_minsdk.p_text);
   name := strip(_ctl_name.p_text);
   package := strip(_ctl_package.p_text);
   sdk := strip(_ctl_sdk.p_text);
   _maybe_append_filesep(sdk);

   if (target == '') {
      _message_box('Please specify an Android build target.');
      return;
   }
   apiLevel := _android_getNumberFromTarget(target);
   if (apiLevel == '') {
      _message_box('Must provide an api level for the desired platform.');
      return;
   }

   if (!is_valid_java_package(package)) {
      _message_box('Package Name must be a valid Java package identifier.');
      return;
   }
   if (!isid_valid(name)) {
      _message_box('Application Name must be a valid Java identifier.');
      return;
   }

   if (!_android_isValidSdkLoc(sdk, false, true)) {
      return;
   }

   neededPlatforms := '';
   // Fresh Android SDK installs from a zip file won't have the emulator or platform tools
   // that we assume are on hand
   if (!file_exists(emulator_path(sdk))) {
      neededPlatforms :+= '"emulator" ';
   }
   if (!file_exists(adb_path(sdk))) {
      neededPlatforms :+= '"platform-tools" ';
   }

   if (!platform_installed(sdk, apiLevel)) {
      neededPlatforms :+= '"platforms;android-'apiLevel'" ';
   }
   if (!platform_installed(sdk, ANDROID_COMPILE_VERSION)) {
      neededPlatforms :+= '"platforms;android-'ANDROID_COMPILE_VERSION'" ';
   }
   if (neededPlatforms._length() > 0) {
      rc := _message_box('Some additional platform support needs to be downloaded to compile this project.  Download now?', 
                         'New Android Project', MB_YESNO | MB_ICONQUESTION);
      if (rc == IDYES) {
         install_sdk_package(sdk, neededPlatforms);
      }
   }

   if (!have_required_gradle()) {
      return;
   }

   // Expand templates for files not supplied by the SDK templates directory, 
   // but supplied by us.
   ctOptions_t ps;

   setp(ps, 'target_sdk_version', apiLevel);
   setp(ps, 'package', package);
   setp(ps, 'appname_lc', lowcase(name));
   setp(ps, 'min_sdk_version', strip(_ctl_minsdk.p_text));
   setp(ps, 'android_tools_version', '3.2.1');
   // This is destined for a Java properties file, so \ must be escaped.
   setp(ps, 'sdk_dir', stranslate(sdk, '\\', '\'));
   setp(ps, 'package_u', stranslate(package, '_', '.'));
   setp(ps, 'appname', name);
   setp(ps, 'compile_version', ANDROID_COMPILE_VERSION);

   rootDir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(rootDir);
   appDir := rootDir:+name:+FILESEP;
   tmpl := android_template_dir('AndroidLibrary');
   status := add_item(tmpl, 'AndroidLibrary', appDir, '', true, null, ps);
   if (status != 0) {
      _message_box('Problem creating library directory structure: 'get_message(status));
      return;
   }

   // Make libs directory for loose jar files, referenced by build.gradle.
   status = _make_path(appDir'libs');
   if (status != 0) {
      _message_box('Problem creating libs directory: 'get_message(status));
      return;
   }

   // To avoid a limitation in the templates, we move the example test file ourselves.
   pkgDir := stranslate(package :+ '.' :+ lowcase(name), FILESEP, "."); _maybe_append_filesep(pkgDir);
   // Make package directory for main source set.
   status = _make_path(appDir'src'FILESEP'main'FILESEP:+pkgDir);
   if (status != 0) {
      _message_box('Problem creating directory for main source set: 'get_message(status));
      return;
   }
   if (status != 0) return;

   status = move_java_file(appDir, 'AndroidManifest.xml', 
                           appDir'src'FILESEP'main'FILESEP);

   ngp := find_index('add_gradle_subprojects', COMMAND_TYPE);
   if (ngp == 0) {
      _message_box('Could not find gradle import routine.');
      return;
   }
   status = call_index(ngp);
   if (!status || status==COMMAND_CANCELLED_RC) {
      _save_form_response();
      p_active_form._delete_window(status);
   } 
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window(''); 
}

defeventtab _android_form;

void android_name_box.on_lost_focus()
{
   name := android_name_box.p_text;
   if (name != '') {
      android_activity_box.p_text = name;
   }
}

void android_loc_box.on_change()
{
   if (android_ndk_location.p_text == '' || !file_exists(android_ndk_location.p_text)) {
      // Supply default location.
      sdk := android_loc_box.p_text;
      _maybe_append_filesep(sdk);
      android_ndk_location.p_text = sdk'ndk-bundle'FILESEP;
   }
}

void android_loc_box.on_lost_focus()
{
   if (android_loc_box.p_text != '') {
      tpath := android_loc_box.p_text;
      _maybe_append_filesep(tpath);
      tpath :+= 'ndk-bundle'FILESEP;
      if (file_exists(tpath)) {
         android_ndk_location.p_text = tpath;
      }
   }
}

void ctlndk.lbutton_up()
{
   enable := (ctlndk.p_value == 1);
   android_ndk_location.p_enabled = enable;
   android_ndk_browse.p_enabled = enable;
   android_ndk_label.p_enabled = enable;
}

static _str gCreateFlags;
void _android_form.on_create(_str flags = '')
{
   gCreateFlags = flags;
   _retrieve_prev_form();
   ctltag.p_value=1;
   ctlndk.p_value=0;
   android_ndk_location.p_enabled = false;
   android_ndk_browse.p_enabled = false;
   android_ndk_label.p_enabled = false;
   android_name_box.p_text='';
   android_activity_box.p_text='';
   package_box.p_text='';
   android_activity_box.p_enabled = true;
   rightAlign := android_frame.p_width - android_frame.p_x;
   sizeBrowseButtonToTextBox(android_ndk_location.p_window_id, android_ndk_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(android_loc_box.p_window_id, android_loc_browse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(android_target_box.p_window_id, android_target_choose.p_window_id, 0, rightAlign);
   android_minsdk_box.p_x_extent = android_loc_box.p_x_extent;

   if (pos('adding', flags) > 0) {
      // The directory name is already set by new project, so force that as the app name.
      android_name_box.p_text = _strip_filename(_strip_filename(_project_name, 'P'), 'E');
      android_name_box.p_enabled = false;
   }

   // If the target and minsdk haven't been specified before, give reasonable defaults.
   if (android_minsdk_box.p_text == '') {
      android_minsdk_box.p_text = '22';
   }
   if (android_target_box.p_text == '') {
      android_target_box.p_text = '27';
   }
}

void android_cancel.lbutton_up()
{
   p_active_form._delete_window(''); 
}

void android_loc_browse.lbutton_up()
{
   wid := p_window_id;
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
   if (def_debug_android > 0) say('_android_getTargetsFromSDK('sdk')');
   if (!_android_isValidSdkLoc(sdk,true)) {
      targets[targets._length()] = 'Please specify valid Android SDK';
      if (def_debug_android > 0) say('   bad sdk');
      return 1;
   } 
   _str temp_file = mktemp();
   if (temp_file == '') {
      if (def_debug_android > 0) say('   no temp');
      targets[targets._length()] = "Error executing 'android' tool";
      return 1;
   }
   _str list_cmd = sdk;
   _maybe_append_filesep(sdk);
   list_cmd = sdk :+ 'tools' :+ FILESEP :+ ANDROID_TOOL;
   if (_isWindows()) {
      list_cmd :+= '.bat';
   }
   list_cmd = _maybe_quote_filename(list_cmd) :+ ' list target > ' :+ _maybe_quote_filename(temp_file);
   if (def_debug_android > 0) say('   list_cmd='list_cmd);
   int status = shell(list_cmd, 'Q');
   if (status) {
      targets[targets._length()] = "Error executing 'android' tool";
      if (def_debug_android > 0) say('   bad command');
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
   if (def_debug_android > 0) say('   done');
   return 0;
}

_command void android_selectTarget(_str target = '') name_info(','VSARG2_EXECUTE_FROM_MENU_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) return;
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
   sdk := android_loc_box.p_text;
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
      android_loc_box.p_text = sdk;
   }
   int status = _android_getTargetsFromSDK(sdk, auto targets);
   i := 0;
   for (i = 0; i < targets._length(); i++) {
      _menu_insert(menu_handle, -1, MF_ENABLED, targets[i], "android-selectTarget ":+targets[i]);
   }
}

const NDK_NONE = 0;
const NDK_NEW = 1;
const NDK_OLD = 2;

static _str android_template_dir(_str itemName)
{
   return _getSysconfigPath()'templates/ItemTemplates/Android/'itemName'/'itemName'.setemplate';
}

static void setp(ctOptions_t& ps, _str name, _str val)
{
   ctTemplateContent_ParameterValue_t pv;
   pv.Prompt = false;
   pv.PromptString = '';
   pv.Value = val;
   ps.Parameters:[name] = pv;
}

// Copies android platform supplied template files from `tmplRoot` and
// expands any replacements specified in `replace`.  Returns 0 on success.
static int place_template_file(_str tmplRoot, _str src, _str dest, _str (&replace):[] = null)
{
   spath := tmplRoot;
   _maybe_append_filesep(spath);
   spath :+= src;

   rc := _make_path(dest, true);
   if (rc != 0) {
      _message_box('Could not make directory for 'dest'. 'get_message(rc));
      return rc;
   }

   rc = copy_file(spath, dest);
   if (rc != 0) {
      _message_box('Could not copy file to 'dest'. 'get_message(rc));
      return rc;
   }

   if (replace != null && replace._length() > 0) {
      rc = _open_temp_view(dest, auto twid, auto orig_wid);
      if (rc != 0) {
         _message_box('Could not open 'dest'. 'get_message(rc));
         return rc;
      }

      _str k, v;
      foreach (k, v in replace) {
         top();
         search(k, '@W', v);
      }
      save('', SV_OVERWRITE);

      p_window_id = orig_wid;
      _delete_temp_view(twid);
   }

   return 0;
}

// Takes main activity template, and adds some simple code to load the 
// native library, and call a function in it.
static int add_ndk_code(_str javaFile)
{
   rc := _open_temp_view(javaFile, auto tempWid, auto origWid, '', auto bae, false, true);
   if (rc != 0) return rc;

   do {
         rc = search('public void onCreate', '@');
         if (rc != 0) break;

         rc = search('{', '@');
         if (rc != 0) break;

         rc = find_matching_paren(true);
         if (rc != 0) break;

         up();
         insert_line('getActionBar().setSubtitle(stringFromJNI());');
         down();
         insert_line(' static { System.loadLibrary("native-lib"); }');
         insert_line('native String stringFromJNI();');
         beautify(true);
         save('', SV_OVERWRITE);
   } while (false);

   p_window_id = origWid;
   _delete_temp_view(tempWid);

   return rc;
}

static int move_java_file(_str rootDir, _str fileName, _str destDir)
{
   status := _make_path(destDir);
   if (status != 0) {
      _message_box(fileName': Problem createing directories for test files: 'get_message(status));
      return status;
   }

   srcFile := rootDir :+ fileName;
   status = copy_file(srcFile, destDir:+FILESEP:+fileName);
   if (status != 0) {
      _message_box(fileName':Could not copy test file: 'get_message(status));
      return status;
   }
   delete_file(srcFile);

   return 0;
}

// Simplistic check to see if a platform is installed.  Doesn't 
// update the official list from sdkmanager.
static bool platform_installed(_str sdk, _str api)
{
   path := sdk'platforms'FILESEP'android-'api:+FILESEP'android.jar';
   return file_exists(path);
}

// Adds a ndk.dir setting to the root projects local.properties, 
// if it doesn't already exist.
static int add_ndk_dir(_str rootDir, _str ndk)
{
   rc := _open_temp_view(rootDir'local.properties', auto tempWid, auto origWid);
   if (rc < 0) return rc;

   rc = search('^ *ndk.dir=', '@L');
   if (rc == STRING_NOT_FOUND_RC) {
      bottom();
      insert_line('ndk.dir='stranslate(ndk, '\\', '\')); // Properties file, so backslash must be escaped.
   }
   save('', SV_OVERWRITE);
   activate_window(origWid);
   _delete_temp_view(tempWid);
   return 0;
}

static bool have_required_gradle()
{
   // A gradle installation is required when creating a new project.
   gh := call_index(find_index('gradle_install_location', PROC_TYPE));
   if (gh == '') {
      call_index(find_index('prompt_for_gradle_home', PROC_TYPE));
      gh = call_index(find_index('gradle_install_location', PROC_TYPE));
      if (gh == '') {
         _message_box('Gradle is required to create a new android project.');
         return false;
      }
   }
   return true;
}

// What level of the SDK we use to compile apps by default.
const ANDROID_COMPILE_VERSION='28';
const ANDROID_LLDB_VERSION='3.1';

void android_ok.lbutton_up()
{
   addingToExisting := pos('adding', gCreateFlags) > 0;
   uses_ndk := ctlndk.p_value;
   package := strip(package_box.p_text);
   sdk := android_loc_box.p_text;
   if (sdk != "" && pos('"',sdk)) {
      sdk = stranslate(sdk,'','"');
   }
   ndk := android_ndk_location.p_text;
   if (ndk != "" && pos('"',ndk)) {
      ndk = stranslate(ndk,'','"');
      if (ndk._length() > 0) {
         _maybe_append_filesep(ndk);
      }
   }
   name := strip(android_name_box.p_text);
   activity := strip(android_activity_box.p_text);
   target := strip(android_target_box.p_text);
   apiLevel := "";
   // input validation...
   if (target == '') {
      _message_box('Please specify an Android build target.');
      return;
   }
   apiLevel = _android_getNumberFromTarget(target);
   if (apiLevel == '' || !isinteger(apiLevel)) {
      _message_box('Target: "'target'" is not a valid Android API level.');
      return;
   }
   minsdk := android_minsdk_box.p_text;
   if (minsdk == '' || !isinteger(minsdk)) {
      _message_box('Minimum SDK:"'minsdk'" is not a valid Android API level.');
      return;
   }
   if (!is_valid_java_package(package)) {
      _message_box('Package Name must be a valid Java package identifier.');
      return;
   }
   if (!isid_valid(name)) {
      _message_box('Application Name must be a valid Java identifier.');
      return;
   }
   if (!isid_valid(activity)) {
      _message_box('Activity Name must be a valid Java identifier.');
      return;
   }
   int tagsdk = ctltag.p_value;
   // check the android sdk directory for validity and compose the create command
   if (!_android_isValidSdkLoc(sdk, false, true)) {
      return;
   }

   rootDir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(rootDir);

   // If we we're missing any platform images needed to compile, 
   // prompt the user to download them.
   _maybe_append_filesep(sdk);
   neededPlatforms := '';

   // Fresh Android SDK installs from a zip file won't have the emulator or platform tools
   // that we assume are on hand
   if (!file_exists(emulator_path(sdk))) {
      neededPlatforms :+= '"emulator" ';
   }
   if (!file_exists(adb_path(sdk))) {
      neededPlatforms :+= '"platform-tools" ';
   }

   if (!platform_installed(sdk, apiLevel)) {
      neededPlatforms :+= '"platforms;android-'apiLevel'" ';
   }
   if (!platform_installed(sdk, ANDROID_COMPILE_VERSION)) {
      neededPlatforms :+= '"platforms;android-'ANDROID_COMPILE_VERSION'" ';
   }
   if (uses_ndk && !_android_isValidNdkLoc(ndk, true) && beginsWith(ndk, sdk)) {
      // If the user specified the default location, but it's not there, 
      // pick it up as well.  If they have their own copy somewhere else, then they're on their
      // own.
      neededPlatforms :+= '"ndk-bundle" ';
   }

   if (uses_ndk && !file_exists(sdk'lldb'FILESEP:+ANDROID_LLDB_VERSION)) {
      neededPlatforms :+= '"lldb;'ANDROID_LLDB_VERSION'" ';
   }

   if (neededPlatforms._length() > 0) {
      rc := _message_box('Some additional platform support is needed to compile this project.  Download now?', 
                         'New Android Project', MB_YESNO | MB_ICONQUESTION);
      if (rc == IDYES) {
         install_sdk_package(sdk, neededPlatforms);
      }
   }

   if (!have_required_gradle()) {
      return;
   }

   // Fill out SDK supplied template parameters, and have the template generate the directory
   // structure.
   tmpl := sdk'platforms'FILESEP'android-'apiLevel:+FILESEP'templates'FILESEP;
   if (!file_exists(tmpl)) {
      _message_box('Could not find templates directory for android-'apiLevel'. Looked in 'tmpl);
      return;
   }

   _str subst:[]; subst._makeempty();

   subst:['PACKAGE'] = package :+ '.' :+ lowcase(name);
   subst:['ACTIVITY_ENTRY_NAME'] = activity'Activity';
   subst:['ACTIVITY_CLASS_NAME'] = activity'Activity';
   subst:['ACTIVITY_FQ_NAME'] = package'.'activity'Activity';
   subst:['ACTIVITY_TESTED_CLASS_NAME'] = activity'Activity';
   subst:['ICON'] = 'android:icon="@mipmap/ic_launcher"';

   appDirName := name; // Just an alias to keep usage clear.
   if (!addingToExisting && file_exists(rootDir:+appDirName)) {
      _message_box('A directory named 'appDirName' already exists in 'rootDir);
      return;
   }

   appMainDir := rootDir:+appDirName:+FILESEP'src'FILESEP'main'FILESEP;
   //appTestDir := rootDir'app'FILESEP'src'FILESEP'test'FILESEP;
   pkgDir := stranslate(subst:['PACKAGE'], FILESEP, "."); _maybe_append_filesep(pkgDir);
   resDir := appMainDir'res'FILESEP;

   status := place_template_file(tmpl, 'AndroidManifest.template', appMainDir'AndroidManifest.xml', subst);
   if (status != 0) return;
   javaActivity := appMainDir'java'FILESEP:+pkgDir:+activity'Activity.java';
   status = place_template_file(tmpl, 'java_file.template', javaActivity, subst);
   if (status != 0) return;
   status = place_template_file(tmpl, 'layout.template', resDir'layout'FILESEP'main.xml', subst);
   if (status != 0) return;
   status = place_template_file(tmpl, 'ic_launcher_hdpi.png', resDir'mipmap-hdpi'FILESEP'ic_launcher.png');
   if (status != 0) return;
   status = place_template_file(tmpl, 'ic_launcher_mdpi.png', resDir'mipmap-mdpi'FILESEP'ic_launcher.png');
   if (status != 0) return;
   status = place_template_file(tmpl, 'ic_launcher_xhdpi.png', resDir'mipmap-xhdpi'FILESEP'ic_launcher.png');
   if (status != 0) return;

   // For some reason, the use ACTIVITY_ENTRY_NAME seems odd in the strings template, so we set the app name to the 
   // actual app name.
   subst:['ACTIVITY_ENTRY_NAME'] = name;
   status = place_template_file(tmpl, 'strings.template', resDir'values'FILESEP'strings.xml', subst);
   if (status != 0) return;

   // TODO: RTE needs to see the jars in libs. Can we just add this directory, and it will pick up the jars
   //        automatically?  OR do we need an entry for each jar.  If the latter, make sure that Project Refresh
   //        refreshes the RTE classpath.
   // TODO: Same deal for tagging.  If we add a *.jar wildcard in the project for the libs directory, that should
   //     ensure the jars in the libs directory get tagged on a project refresh.  (still need to manually trigger retag?).

   // Expand templates for files not supplied by the SDK templates directory, 
   // but supplied by us.
   ctOptions_t ps;

   setp(ps, 'target_sdk_version', apiLevel);
   setp(ps, 'package', package);
   setp(ps, 'appname_lc', lowcase(name));
   setp(ps, 'min_sdk_version', minsdk);
   setp(ps, 'android_tools_version', '3.2.1');
   setp(ps, 'ndk_dir', ndk);
   // This is destined for a Java properties file, so \ must be escaped.
   setp(ps, 'sdk_dir', stranslate(sdk, '\\', '\'));
   setp(ps, 'package_u', stranslate(package, '_', '.'));
   setp(ps, 'main_activity', activity);
   setp(ps, 'appname', name);
   setp(ps, 'compile_version', ANDROID_COMPILE_VERSION);

   if (!addingToExisting) {
      tmpl = android_template_dir('AndroidBase');
      status = add_item(tmpl, 'AndroidBase', rootDir, '', true, null, ps);
      if (status != 0) {
         _message_box('Problem creating directory structure: 'get_message(status));
         return;
      }
   }

   appDir := rootDir:+appDirName:+FILESEP;
   tmpl = android_template_dir('AndroidApp');
   status = add_item(tmpl, 'AndroidApp', appDir, '', true, null, ps);
   if (status != 0) {
      _message_box('Problem creating app directory structure: 'get_message(status));
      return;
   }

   // Make libs directory for loose jar files, referenced by build.gradle.
   status = _make_path(appDir'libs');
   if (status != 0) {
      _message_box('Problem creating libs directory: 'get_message(status));
      return;
   }


   // To avoid a limitation in the templates, we move the example test file ourselves.
   status = move_java_file(appDir, 'ExampleInstrumentedTest.java', 
                  appDir'src'FILESEP'androidTest'FILESEP'java'FILESEP:+pkgDir);
   if (status != 0) return;
   status = move_java_file(appDir, 'ExampleUnitTest.java', 
                           appDir'src'FILESEP'test'FILESEP'java'FILESEP:+pkgDir);
   if (status != 0) return;

   if (uses_ndk) {
      tmpl = android_template_dir('NewNDK');
      delete_file(appDir'build.gradle');  // Will be overwritten, we do not want a prompt.
      status = add_item(tmpl, 'NewNDK', appDir, '', true, null, ps);
      if (status != 0) {
         _message_box('Problem NDK directory structure: 'get_message(status));
         return;
      }
      status = add_ndk_code(javaActivity);
      if (status != 0) {
         _message_box('Problem adding ndk code to 'javaActivity);
         return;
      }
      status = add_ndk_dir(rootDir, ndk);
      if (status != 0) {
         _message_box('Problem adding ndk.dir to local.properties.');
         return;
      }
   }

   ngp := 0;
   if (addingToExisting) {
      ngp = find_index('add_gradle_subprojects', COMMAND_TYPE);
   } else {
      ngp = find_index('new_gradle_proj', COMMAND_TYPE);
   }

   if (ngp == 0) {
      _message_box('Could not find gradle import routine.');
      return;
   }
   status = call_index(ngp);
   if (!status || status==COMMAND_CANCELLED_RC) {
      _save_form_response();
      p_active_form._delete_window(status);
   } 

   if (!status) {
      // live error support.
      _str projectDir = _file_path(_project_name);
      _maybe_append_filesep(projectDir);

      if (tagsdk && apiLevel != '' && isnumber(apiLevel)) {
         android_jar :=  sdk :+ 'platforms' :+ FILESEP :+ 'android-'apiLevel :+ FILESEP :+ ANDROID_JAR;
         if (file_exists(_maybe_quote_filename(android_jar))) {
            tagfilename := absolute(_tagfiles_path():+'android-'apiLevel:+TAG_FILE_EXT);
            if (!ext_MaybeRecycleTagFile(auto tf, auto tagfn, 'java', 'android-'apiLevel)) {
               useThread := _is_background_tagging_enabled(AUTOTAG_LANGUAGE_NO_THREADS);
               ext_BuildTagFile(tf, tagfilename, 'java', '', false, _maybe_quote_filename(android_jar), "", false, useThread);
            }
         }
      }

   }
}

// Brings up the dialog to configure Java live errors.
_command void configure_live_errors() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   show('-modal -xy -wh _java_options_form',_ProjectHandle(),"Live Errors",GetCurrentConfigName(),_project_name,0);
}

static int collect_project_information(_str extraArgs='')
{
   form := '-modal _android_form';
   if (pos('library', extraArgs) > 0) {
      form = '-modal _android_library_form';
   }

   int status=show(form, extraArgs);
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

// Returns true if the active project isn't in the build.settings
bool gradle_project_not_added(_str wkRoot, _str projName)
{
   rv := false;
   rc := _open_temp_view(wkRoot'settings.gradle', auto tempWid, auto origWid);
   if (rc == 0) {
      term := "include +'\\:?"projName"'";
      if (def_debug_android > 0) say('cur_project_not_added term='term);
      rv = search(term, 'L@') != 0;
      activate_window(origWid);
      _delete_temp_view(tempWid);
   }

   return rv;
}

static bool cur_project_not_added(_str wkRoot)
{
   pname := _strip_filename(_strip_filename(_project_name, 'P'), 'E');
   return gradle_project_not_added(wkRoot, pname);
}

static bool cur_project_is_library()
{
   ph := _ProjectHandle();
   return _ProjectGet_TemplateName(ph) == 'Android - Library';
}

_command int new_android_application() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Android SDK support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // Decide if this is an import of an existing project, or a brand new project.
   flags := '';
   if (cur_project_is_library()) {
      flags :+= ' library';
   }

   root := _file_path(_workspace_filename);
   _maybe_append_filesep(root);
   if (file_exists(root'build.gradle')) {
      if (_WorkspaceGet_EnvironmentVariable(gWorkspaceHandle, 'SE_IMPORTING_WORKSPACE') == '1') {
         // Importing an existing workspace.
         if (def_debug_android > 0) say('new_android_application: import existing 'root);
         ngp := find_index('new_gradle_proj', COMMAND_TYPE);
         if (ngp > 0) {
            call_index(ngp);
         }
         _WorkspaceSet_EnvironmentVariable(gWorkspaceHandle, 'SE_IMPORTING_WORKSPACE', '0');
      } else {
         // Maybe adding an android project to an existing workspace.
         if (cur_project_not_added(root)) {
            if (def_debug_android > 0) say('new_android_application: adding new project to workspace '_project_name);
            prjDir := _strip_filename(_project_name, 'N');
            if (!beginsWith(prjDir, root)) {
               _message_box('Bad directory: the Android sub-project must be in a sub-directory under the existing workspace.');
               return ERROR_CREATING_DIRECTORY_RC;
            }
            return collect_project_information(flags :+ ' adding');
         } else {
            // This is a subproject being created by gradle. See new_gradle_project().
            return rc;
         }
      }
   } else {
      if (def_debug_android > 0) say('new_android_application(): new workspace + project');
      return collect_project_information(flags);
   }
   return(0);
}

/**
 * Check if a directory contains a valid Android SDK 
 * installation. 
 * 
 * @param dir 
 * 
 * @return bool 
 */
bool _android_isValidNdkLoc(_str dir, bool quiet = false)
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

   if (!file_exists(dir:+'ndk-build'EXTENSION_BATCH) || !file_exists(dir:+'ndk-gdb'EXTENSION_BATCH)) {
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
 * @return bool 
 */
bool _android_isValidSdkLoc(_str dir, bool quiet = false, 
                            bool ignoreTools = false)
{
   if (dir == '' || !isdirectory(dir)) {
      if (!quiet) {
         _message_box('Location of Android SDK must be a directory.');
      }
      return false;
   }
   _maybe_append_filesep(dir);
   android :=  dir :+ "tools" :+ FILESEP :+ ANDROID_TOOL;
   emulator :=  emulator_path(dir);
   adb :=  adb_path(dir);
   // should also check for android.jar...

   if (_isWindows()) {
      android :+= ".bat";
   }

   if (!file_exists(android)) {
      if (!quiet) {
         _message_box('Android SDK installation is missing components.');
      }
      return false;
   }

   if (!ignoreTools && (!file_exists(emulator) || !file_exists(adb))) {
      if (!quiet) {
         _message_box('Android SDK installation is missing tools directories.');
      }
      return false;
   }
   return true;
}

static _str gradle_cmd(_str cmd)
{
   ext := _isWindows() ? ".bat":"";
   return '"%wpgradlew%(SE_GRADLE_WRAPPER_EXT)" 'cmd;
}

// Takes a generically setup gradle vpj and updates it to have
// the correct tool menus and options appropriate to the corresponding
// android setup. Returns 0 on success.
int _android_project_setup(bool isRootProject)
{
   if (def_debug_android > 0) say('android_project_setup '_project_name);
   pname := isRootProject ? '' : _strip_filename(_strip_filename(_project_name, 'P'), 'E')':';
   if (def_debug_android > 0) say('  projname='pname);
   int handle = _ProjectHandle(_project_name);
   if (!handle) {
      if (def_debug_android > 0) say('  no open project?');
      return VSRC_NO_CURRENT_PROJECT;
   }
   if (def_debug_android > 0) say(  'handle='handle);

   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto activity, auto ndk, auto target);
   uses_ndk := (ndk != '') ? 1 : 0;
   
   if (!isRootProject) {
      // Include generated resource java files so they're available for completion.
      _str nf[];
      pkgRPath := translate(pkg, FILESEP, '.');
      nf :+= 'build'FILESEP'generated'FILESEP'not_namespaced_r_class_sources'FILESEP'debug'FILESEP'processDebugResources'FILESEP'r'FILESEP:+pkgRPath:+FILESEP:+'R.java';
      _ProjectAdd_Files(handle, nf, null, -1, "PackageView");

      nf[0] = 'build'FILESEP'generated'FILESEP'not_namespaced_r_class_sources'FILESEP'release'FILESEP'processReleaseResources'FILESEP'r'FILESEP:+pkgRPath:+FILESEP:+'R.java';
      _ProjectAdd_Files(handle, nf, null, -1, "PackageView");
   } else {
      // Execute isn't well defined for all possible root projects like `build` is, so
      // remove that option from the menu.
      bh := _ProjectGet_TargetNode(handle, 'execute', 'Debug');
      if (bh >= 0) {
         _xmlcfg_delete(handle, bh);
      }
      bh = _ProjectGet_TargetNode(handle, 'execute', 'Release');
      if (bh >= 0) {
         _xmlcfg_delete(handle, bh);
      }
   }

   _ProjectSet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'build','Debug'),
                             gradle_cmd(pname'assembleDebug'));
   _ProjectSet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'rebuild','Debug'),
                             gradle_cmd(pname'clean 'pname'assembleDebug'));
   _ProjectSet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'build','Release'),
                             gradle_cmd(pname'assembleRelease'));
   _ProjectSet_TargetCmdLine(handle,_ProjectGet_TargetNode(handle,'rebuild','Release'),
                             gradle_cmd(pname'clean 'pname'assembleRelease'));

   if (!isRootProject) {
      int emu_debug_node = _ProjectGet_TargetNode(handle,'execute','Debug');
      int emu_rls_node = _ProjectGet_TargetNode(handle,'execute','Release');
      _ProjectSet_TargetMenuCaption(handle,emu_debug_node,'Execute/Debug on Device...');
      _ProjectSet_TargetMenuCaption(handle,emu_rls_node,'Execute/Debug on Device...');
      _ProjectSet_TargetCmdLine(handle,emu_debug_node,'android_runAppOnDevice', 'Slick-C');
      _ProjectSet_TargetCmdLine(handle,emu_rls_node,'android_runAppOnDevice', 'Slick-C');
      _ProjectSet_TargetBuildFirst(handle,emu_debug_node,false);
      _ProjectSet_TargetBuildFirst(handle,emu_rls_node,false);
   }

   int temp_debugc_node = _ProjectGet_TargetNode(handle, 'Clean', 'Debug');
   int temp_rlsc_node = _ProjectGet_TargetNode(handle, 'Clean', 'Release');
   _ProjectSet_TargetCmdLine(handle,temp_debugc_node,
                             gradle_cmd(pname'clean'));
   _ProjectSet_TargetCmdLine(handle,temp_rlsc_node,
                             gradle_cmd(pname'clean'));



   _ProjectSave(handle);
   return 0;
}

//TODO go once the new android project code is in.
static int setupExistingAndroidProject(_str name='', _str target_id='', _str sdk='', _str man_file='', bool update=false,
                                       int uses_ndk = 0, _str ndk='', bool create_ws=true)
{
   if (ndk != '') {
      _maybe_append_filesep(ndk);
   }
   xmlFile := strip(man_file, "B", " \t");
   xmlFile = strip(xmlFile, "B", "\"");

   xmlFile = _maybe_quote_filename(xmlFile);

   // even if we are inserting into current ws, we need to establish this for what we will name the project
   wsname := "";

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
   projectName := _strip_filename(xmlFile, 'N') :+ wsname :+ PRJ_FILE_EXT;

   // create the corresponding workspace/project if necessary
   workspaceCreated := !create_ws;
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
         projectDir = _maybe_quote_filename(projectDir);
         _maybe_append_filesep(sdk);
         uCmd :=  sdk'tools'FILESEP'android';
        if (_isWindows()) {
           uCmd :+= '.bat';
        }
         uCmd = _maybe_quote_filename(uCmd) :+ ' update project';
         if (name != '') {
           uCmd :+= ' --name 'name;
         }
         uCmd :+= ' --target 'target_id' --path 'projectDir;
         _str res = _PipeShellResult(uCmd, auto status,'ACH');
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

static void emu_check_and_report(_str name, _str log)
{
   rc := _open_temp_view(log, auto temp, auto orig);
   if (rc == 0) {
      out := output_window_text_control();
      out.bottom_of_buffer();
      out.insert_line('===LOG FROM FINISHED EMULATOR===');
      out._copy_from_view(temp, auto doNotCare);
      out.p_line = out.p_Noflines;
      out.insert_line('===END LOG FROM FINISHED EMULATOR===');

      save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
      top();
      rc = search('PANIC|ERROR', '<@L');
      if (rc == 0) {
         get_line(auto panic);
         show('_android_emulator_error_form', name': 'panic);
      }
      restore_search(s1, s2, s3, s4, s5);

      p_window_id = orig;
      _delete_temp_view(temp);
   }
}

void emulator_cleaner()
{
   if (gEmuGate == 0) {
      int deadlist[]; deadlist._makeempty();

      gEmuGate = 1;
      // Save logs for stopped emulators, and clean up temp file.
      foreach (auto pid => auto em in gEmulators) {
         if (!_IsProcessRunning(pid)) {
            deadlist :+= pid;
            emu_check_and_report(em.name, em.logfile);
            delete_file(em.logfile);
         }
      }

      foreach (pid in deadlist) {
         gEmulators._deleteel(pid);
      }

      // Turn the timer back off if there are no outstanding emulators running.
      if (gEmulators._length() == 0) {
         _kill_timer(gEmulatorTimer);
         gEmulatorTimer = -1;
      }
      gEmuGate = 0;
   }
}

static int start_emulator(_str sdk, _str name)
{
   RunningEmulator em; 

   lc := 1;
   em.logfile = "";
   em.name = name;
   while (em.logfile == "") {
      em.logfile = mktemp(lc, "emu");
      lc += 100;
   }

   cmd :=  emulator_path(sdk)' -avd ' name;
   if (_isWindows()) {
      cmd :+= ' 1> ';
   } else {
      cmd :+= ' 2>&1 >';
   }
   cmd :+= _maybe_quote_filename(em.logfile);
   if (_isWindows()) {
      cmd :+= ' 2>&1';
   }

   status := shell(cmd,'AQ', '', em.pid);
   if (status == 0) {
      gEmulators:[em.pid] = em;
      if (gEmulatorTimer < 0) {
         gEmulatorTimer = _set_timer(EMU_CHECK_INTERVAL, emulator_cleaner);
      }
   }

   return status;
}

_command _str android_runAppOnDevice(bool get_serial = false, bool debug_app = false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Android SDK support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for project.");
      return '';
   }
   cfgName := lowcase(GetCurrentConfigName());
   if (cfgName == 'release' && extract_signing_information(auto d1, auto d2, auto d3, auto d4, auto d5) < 0) {
      answ := _message_box('This is a release build that has no signing configuration in the build.gradle.  Select a key to use for signing now?',
                           'No signing key', MB_YESNO);
      if (answ == IDYES) {
         android_configure_signing();
      } else {
         message('Run on device cancelled.');
      }
      return '';
   }

   if (apk == '') {
      _message_box('Error: No apk file found. Has the project been built for the 'cfgName' configuration?');
      return '';
   }


   int status = android_getDeviceInfo(auto emus, sdk);
   i := 0;
   if (get_serial) {
      num_online := 0;
      for (i = 0; i < emus._length(); i++) {
         if (emus[i].state == 'online') {
            num_online++;
         }
      }
      if (num_online == 1) {
         // Easy choice if there is only 1 device online
         return 'serial='emus[0].serial;
      }
   }
   _str val = show("-xy -modal _android_device_form", emus, get_serial, debug_app);
   if (val == "" || get_serial) {
      return val;
   }
   parse val with . "wait=" auto wait_opt;
   parse val with . "state=" auto state auto state2 ',' .;
   if (state2 != '') {
      state :+= ' 'state2;
   }
   parse val with . "name=" auto name ',' .;
   parse val with . "serial=" auto serial',' .;
   // start a not running emulator
   if (state == 'not running' && name != '') {
      status = start_emulator(sdk, name);
   }
   // performed again here in case emulator list changed and was refreshed
   status = android_getDeviceInfo(auto emus2, sdk);
   serials := "";
   for (i = 0; i < emus2._length(); i++) {
      serials :+= emus2[i].serial',';
   }

   vsandroidrun := get_env("VSLICKBIN1"):+get_VSANDROIDRUN_EXE();
   _str run_args = sdk' 'apk' 'pkg' 'act' 'serial' 'serials' 'wait_opt;
   run_cmd := _maybe_quote_filename(vsandroidrun)' 'run_args;
   run_cmd = makeCommandCLSafe(run_cmd);
   concur_command(run_cmd);
   return '';
}

_command _str android_debugAppOnDevice(bool get_serial = false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   return android_runAppOnDevice(get_serial, true);
}

_command void android_debug_attach() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   debug_attach('jdwp', 'host=localhost,port=8000,session=WORKSPACE: '_workspace_filename);
}

_str _properties_getValueForProperty(_str filename, _str property)
{
   if (def_debug_android > 0) say('getValueForProperty 'filename', 'property);
   val := "";
   if (!file_exists(filename)) {
      if (def_debug_android > 0) say('   file not found');
      return val;
   }
   int status = _open_temp_view(filename, auto temp_view_id, auto orig_view_id);
   if (!status) {
      query := '^'property'=(.*)$';
      if (def_debug_android > 0) say('   query='query);
      top();
      status=search(query,'+L@XSC');
      if (!status) {
         val = get_match_text(1);
         if (def_debug_android > 0) say('   found 'val);
      } else {
         if (def_debug_android > 0) say('   prop not found 'get_message(status));
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   } else {
      if (def_debug_android > 0) say('   no view 'get_message(status));
   }
   return val;
}

static _str extract_target_from_gradle(_str prjdir)
{
   if (def_debug_android > 0) say('extract_target_from_gradle('prjdir')');
   gfile := prjdir'build.gradle';
   if (!file_exists(gfile)) {
      if (def_debug_android > 0) say('  not found 'gfile);
      return ANDROID_COMPILE_VERSION;
   }

   rc := _open_temp_view(gfile, auto wid, auto oldWid, '', auto nocare, false, true);
   if (rc < 0) {
      if (def_debug_android > 0) say('  no view 'gfile);
      return ANDROID_COMPILE_VERSION;
   }

   rv := ANDROID_COMPILE_VERSION;
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   do {
      top();
      rc = search('targetSdkVersion +(\d+)', '+L@XSC');
      if (rc != 0) {
         if (def_debug_android > 0) say('  no sdk ver');
         break;
      }

      rv = get_text(match_length('1'),match_length('S1'));
      if (def_debug_android > 0) say('  rv='rv);
      if (!isinteger(rv)) {
         if (def_debug_android > 0) say('  not a number');
         rv = ANDROID_COMPILE_VERSION;
      }
   } while (false);

   restore_search(s1, s2, s3, s4, s5);
   p_window_id = oldWid;
   _delete_temp_view(wid);
   if (def_debug_android > 0) say('  returns 'rv);
   return rv;
}

// Extracts information for the currently opened android project.
//   sdk - Directory for the installed Andoid SDK
//   apk - full path to apk file.  (app/build/outputs/apk?)
//   pkg - package defined in app/src/main/AndroidManifest.xml
//   act  - Activity name from AndroidManifest, with leading '.' stripped off.
//   ndk - NDK path. (local.properties?)
//   target - target api version. A number.  (some places expect 'something:something:15).
// TODO: most callers seem to only use one or two values, so it may be better to split this into 
//  multiple functions.
int _android_getRunArgs(_str &sdk, _str &apk, _str &pkg, _str &act, _str &ndk,
                        _str &target, bool maybe_quote_sdk = true)
{
   if (def_debug_android > 0) say('android_getRunArgs '_project_name);
   sdk = '';
   apk = '';
   pkg = '';
   act = '';
   ndk = '';
   target = '';

   pdir := _file_path(_project_name);
   _maybe_append_filesep(pdir);
   wdir := _file_path(_workspace_filename);
   _maybe_append_filesep(wdir);

   lpropfile := _maybe_quote_filename(wdir'local.properties');
   if (def_debug_android > 0) say('   propfile='lpropfile);
   // locate sdk from local.propeties
   sdk = _properties_getValueForProperty(lpropfile,'sdk\.dir');
   sdk = stranslate(sdk, '\', '\\');
   sdk = stranslate(sdk, ':', '\:');
   _maybe_append_filesep(sdk);
   if (maybe_quote_sdk) {
      sdk = _maybe_quote_filename(sdk);
   }
   
   ndk = _properties_getValueForProperty(lpropfile,'ndk\.dir');
   ndk = stranslate(ndk, '\', '\\');
   ndk = stranslate(ndk, ':', '\:');
   _maybe_append_filesep(ndk);

   config := 'debug';
   int handle = _ProjectHandle();
   if (handle) {
      _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
      config = lowcase(config);
   }
   if (def_debug_android > 0) say('\tconfig='config);

   outdir := pdir'build'FILESEP'outputs'FILESEP'apk'FILESEP:+config;
   if (file_exists(outdir)) {
      if (def_debug_android > 0) say('looking for apk in 'outdir);
      cwd := getcwd();
      cd(outdir);
      res := file_match('*-'config'.apk -P',1);
      if (res != '') {
         apk = outdir :+ FILESEP :+ res;
         // TODO: probably not needed anymore for newer sdk.
//       if (config == 'debug' && endsWith(res,"-unaligned.apk")) {
//          aligned := stranslate(res,'','-unaligned');
//          aligned_full :=  projectDir :+ 'bin' :+ FILESEP :+ aligned;
//          if (file_exists(_maybe_quote_filename(aligned_full))) {
//             apk = aligned_full;
//          }
//       }
      }
      cd(cwd);
   }

   mandir := pdir :+ 'src' :+ FILESEP :+ 'main' :+ FILESEP;
   int h = _xmlcfg_open(mandir :+ 'AndroidManifest.xml',auto status);
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
   } else {
      if (def_debug_android > 0) say('no manifest in 'mandir);
   }

   target = extract_target_from_gradle(pdir);
   if (def_debug_android > 0) say('sdk='sdk', apk='apk', pkg='pkg', act='act', ndk='ndk', target='target);
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
_command int workspace_open_android(_str xmlFile = "", bool create_ws=true) name_info(FILE_ARG'*,')
{
   return workspace_open_gradle(xmlFile, create_ws);
}

_str _android_getNumberFromTarget(_str &target)
{
   if (target == '' || isnumber(target)) {
      return target;
   }
   apiLevel := "";
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

const CMD_TIMEOUT = 500;

// Reads data off of a socket connected to an emulator until it gets an 
// OK, or just times out.  Returns 0 when OK is found.
static int read_till_OK(sc.net.ClientSocket& s, _str &all)
{
   buf := '';
   numRet := 10;
   ending := 'OK':+_chr(0xd):+_chr(0xa);

   all = '';
   while ( pos(ending, all) <= 0 && numRet > 0) {
      rc := s.receive_if_pending(buf);
      if (rc == SOCK_NO_MORE_DATA_RC) {
         numRet--;
         delay(1);
      } else if (rc < 0) {
         return rc;
      }
      all :+= buf;
      buf = '';
   }
   return 0;
}

// Sends a command to the emulator, and collects the response.
// Command should not include trailing newline.
static int emulator_command(sc.net.ClientSocket& s, _str cmd, _str &response)
{

   cc := cmd :+ _chr(0xD) :+ _chr(0xA);
   if (def_debug_android > 0) say('emulator_command 'cc);
   _str buf;

   rc := s.send(cc);
   if (rc != 0) {
      if (def_debug_android > 0) say('  send failed:'rc);
      return SOCK_NO_RECOVERY_RC;
   }

   rv := read_till_OK(s, response);
   if (def_debug_android > 0) say('  final response: 'rv'/'response);
   return rv;
}

// Connects the socket to the emulator and authenticates
// so the emulator is ready for connections.  This is new, the emulator
// did not previously require authentication.
// Returns 0 on success, <0 on failure.
static int connect_to_emulator(sc.net.ClientSocket& s, _str host, int port)
{
   if (def_debug_android > 0) say('connect_to_emulator 'host':'port);

   hd := '';
   if (_isWindows()) {
      hd = get_env('USERPROFILE');
   } else {
      hd = get_env('HOME');
   }
   _maybe_append_filesep(hd);
   hd :+= '.emulator_console_auth_token';
   if (!file_exists(hd)) {
      if (def_debug_android > 0) say('  COULD not find auth file at 'hd);
      return FILE_NOT_FOUND_RC;
   }

   rc := _open_temp_view(hd, auto nwid, auto oldWid);
   if (rc != 0) {
      if (def_debug_android > 0) say('  COULD not open temp view: 'rc);
      return rc;
   }
   top();
   get_line(auto authtok);
   authtok = strip(authtok);
   activate_window(oldWid);
   _delete_temp_view(nwid);

   rc = s.connect(host, port);
   if (rc < 0) {
      if (def_debug_android > 0) say('  connect fail 'rc);
      return rc;
   }

   buf := '';
   rc = read_till_OK(s, buf);
   if (rc < 0) {
      if (def_debug_android > 0) say('  no prompt ('buf')');
      s.close();
      return rc;
   }

   rc = emulator_command(s, 'auth 'authtok, buf);
   if (rc < 0) {
      if (def_debug_android > 0) say('  auth failed: 'rc'/'buf);
      s.close();
      return rc;
   }

   if (def_debug_android > 0) say('  connection succeeded');
   return 0;
}

static _str emulator_path(_str sdk)
{
   emu :=  sdk :+ "emulator" :+ FILESEP :+ EMU_TOOL;
   if (_isWindows()) {
      emu :+= ".exe";
   }
   return _maybe_quote_filename(emu);
}

static _str adb_path(_str sdk)
{
   adb := sdk :+ "platform-tools" :+ FILESEP :+ ADB;
   if (_isWindows()) {
      adb :+= ".exe";
   }
   return _maybe_quote_filename(adb);
}

static int android_getDeviceInfo(EMULATOR_INFO (&emus)[], _str sdk)
{
   if (def_debug_android > 0) say('android_getDeviceInfo sdk='sdk);
   mou_hour_glass(true);
   _str ports[];
   _str serials[];
   _str names[];
   _str states[];
   _str targets[];
   _str api_levels[];
   // first run 'adb devices' to get any running emulators...
   //TODO: format changes, not seeing available emulators that are not running.  Probably same for running emulators.
   adb := adb_path(sdk);
   cmd := _maybe_quote_filename(adb) :+ ' devices';
   status := command_to_temp_view(cmd, auto temp_view_id, auto orig_view_id);
   if (status) {
      mou_hour_glass(false);
      _message_box("Unable to retrieve Android device info: Error executing 'adb devices'");
      return 1;
   }
   if (!status) {
      // it's ok to skip the first line because it's not an actual result
      down(); // Skip title row.
      while (rc == 0) {
         get_line(auto line);
         parse line with auto name auto stat; 
         if (def_debug_android > 0) say('  adb name='name', stat='stat);
         cur := pos('emulator-{#1:n}',name,1,'R');
         if ((cur == 0 || pos('S1') == 1) && name != '') {
            serials :+= name;
            ports :+= 'N/A';
         } else if (name != '') {
            port := substr(name, pos('S1'),pos('1'));
            ports :+= port;
            serials :+= 'emulator-'port;
         } else {
            break;
         }
         if (pos('device',stat) == 1) {
            states :+= 'online';
         } else {
            states :+= 'offline';
         }
         if (def_debug_android > 0) say('  adb line serials='serials[serials._length()-1]', ports='ports[ports._length()-1]', states='states[states._length() - 1]);
         rc = down();
      }
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   }
   // now get the names for each running emulator via tcp/ip
   i := 0;
   for (i = 0; i < ports._length(); i++) {
      // can't connect if offline (not going to connect if not an emulator)
      // but it would be nice if we could determine the target for devices...
      if (states[i] == 'offline' || ports[i] == 'N/A') {
         names[i] = '';
         targets[i] = '';
         continue;
      }
      sc.net.ClientSocket client;
      status = connect_to_emulator(client, "localhost",(int)ports[i]);
      if (status == 0 && client.isConnected()) {
         status = emulator_command(client, 'avd name', auto reply);
         if (def_debug_android > 0) say('    name reply: 'reply);
         if (!status && reply != '') {
            emu_name := pos('^[ \t]*{#1[a-zA-Z0-9_\-\.]#}',reply,1,'R');
            if (emu_name > 0) {
               name := substr(reply, pos('S1'),pos('1'));
               names[names._length()] = name;
            } else {
               names[names._length()] = '';
            }
         } else {
            names[names._length()] = '';
         }
         client.close();
      } else {
         if (def_debug_android > 0) say('  COULD not connect to 'serials[i]);
         names[names._length()] = '';
      }
   }
   // now get the emulators which are not running, from 'android list avd'
   android :=  sdk :+ "tools" :+ FILESEP :+ ANDROID_TOOL;
   if (_isWindows()) {
      android :+= ".bat";
   }
   android = _maybe_quote_filename(android);

   // _PipeShellResult isn't behaving well with this command, for some reason
   status = command_to_temp_view(android :+ ' list avd', auto temp_view_id2, auto orig_view_id2);
   if (status) {
      // ? couldn't execute android tool
      if (def_debug_android > 0) say('   command status? 'status);
      mou_hour_glass(false);
      return 1;
   }
   // check the results of 'list avd' with what we found the API level to be from the .properties file
   if (!status) {
      for (;;) {
         status=search('Name\:[ \t]{#1?*}$',"@rh");
         if (status) {
            break;
         }
         name := strip(get_match_text(1));
         if (def_debug_android > 0) say('  avd name 'name);
         // determine if we already have this name yet 
         found := -1;
         for (i = 0; i < names._length(); i++) {
            if (name == names[i]) {
               found = i;
               if (def_debug_android > 0) say('  found in names');
               break;
            }
         }
         status=search('Target\:[ \t]{#2?*}$',"@rh");
         t := "";
         if (!status) {
            t = get_match_text(2);
            if (def_debug_android > 0) say('  target match 't);
            if (pos('API level {#3}', t) > 0) {
               // set api level...TBD, unused for now
            }
         } else {
            down();
         }
         if (found == -1) {
            num_emu := names._length();
            if (def_debug_android > 0) say('  not found adding as 'num_emu);
            names[num_emu] = name;
            serials[num_emu] = 'N/A';
            targets[num_emu] = t;
            states[num_emu] = 'not running';
            ports[num_emu] = 'N/A';
         } else {
            targets[found] = t;
         }
      }
      activate_window(orig_view_id2);
      _delete_temp_view(temp_view_id2);
   }
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

void _prjopen_android(bool singleFileProject)
{
   if (singleFileProject) return;
   if (!_haveBuild()) {
      return;
   }
   int h = _ProjectHandle();
   if (h) {
      _str apptype = _ProjectGet_AppType(h);
      if (apptype == "android") {
         //int wid = _tbIsVisible("_tbandroid_form");
         wid := _tbGetWid('_tbandroid_form');
         if (wid <= 0) {
            toggle_android();
         }
      }
   }
}

void _prjclose_android(bool singleFileProject)
{
   if (singleFileProject) return;
   if (!_haveBuild()) {
      return;
   }
   int h = _ProjectHandle();
   if (h) {
      _str apptype = _ProjectGet_AppType(h);
      if (apptype == "android") {
         //int wid = _tbIsVisible("_tbandroid_form");
         wid := _tbGetWid('_tbandroid_form');
         if (wid > 0) {
            toggle_android();
         }
      }
   }
}

// AVD manager data.
static AVDRec gAvds[];
static NamedEntry gTargets[];
static NamedEntry gDevices[];

defeventtab _android_create_avd_form;

void _android_create_avd_form.on_resize()
{
   hmargin := ctllabel1.p_x;
   vmargin := 75;

   maxLabW := ctllabel1.p_width;
   vspacing := _ctl_name.p_height + 50;
    
   // Align labels and text/combo boxes.
   ctllabel2.p_x = hmargin;
   ctllabel2.p_y = ctllabel1.p_y + vspacing;
   _ctl_system_image.p_y = ctllabel2.p_y;
   maxLabW = max(maxLabW, ctllabel2.p_width);

   ctllabel4.p_x = hmargin;
   ctllabel4.p_y = ctllabel2.p_y + vspacing;
   _ctl_arch.p_y = ctllabel4.p_y;
   maxLabW = max(maxLabW, ctllabel4.p_width);

   ctllabel3.p_x = hmargin;
   ctllabel3.p_y = ctllabel4.p_y + vspacing;
   _ctl_device.p_y = ctllabel3.p_y;
   maxLabW = max(maxLabW, ctllabel3.p_width);

   ctllabel5.p_x = hmargin;
   ctllabel5.p_y = ctllabel3.p_y + vspacing;
   _ctl_sdcard.p_y = ctllabel5.p_y;
   maxLabW = max(maxLabW, ctllabel5.p_width);

   boxX := hmargin + maxLabW + 100;
   _ctl_name.p_x = boxX;
   _ctl_name.p_width = p_width - _ctl_name.p_x - hmargin;
   _ctl_system_image.p_x = boxX;
   _ctl_system_image.p_width = p_width - _ctl_system_image.p_x - hmargin;
   _ctl_arch.p_x = boxX;
   _ctl_arch.p_width = p_width - _ctl_arch.p_x - hmargin;
   _ctl_device.p_x = boxX;
   _ctl_device.p_width = p_width - _ctl_device.p_x - hmargin;
   _ctl_sdcard.p_x = boxX;
   _ctl_sdcard.p_width = p_width - _ctl_sdcard.p_x - hmargin;

   // Align buttons to bottom right.
   butSpace := vmargin;
   butY := p_height - vmargin - _ctl_cancel.p_height;
   _ctl_cancel.p_x = p_width - hmargin - _ctl_cancel.p_width;
   _ctl_cancel.p_y = butY;
   _ctl_create.p_x = _ctl_cancel.p_x - butSpace - _ctl_create.p_width;
   _ctl_create.p_y = butY;

   // Stretch frame between combo boxes and the buttons.
   ctlframe1.p_x = hmargin;
   ctlframe1.p_y = _ctl_sdcard.p_y + vspacing;
   ctlframe1.p_width = p_width - 2*hmargin;
   ctlframe1.p_height = _ctl_create.p_y - vmargin - ctlframe1.p_y;

   // Fill frame with status text.
   _ctl_status.p_x = hmargin*2;
   _ctl_status.p_y = vmargin*2;
   _ctl_status.p_width = ctlframe1.p_width - 4*hmargin;
   _ctl_status.p_height = ctlframe1.p_height - 4*vmargin;
}

static void update_available_architectures()
{
   //add error text to dialog that can be updated with information when a field is invalid, or there are no architectures downloaded for a API level.
   _ctl_arch._lbclear();
   platform := _ctl_system_image.p_text;
   if (platform == '') return;

   if (pos('^Android API (\d+)', platform, 1, 'L') <= 0) return;
   api := substr(platform, pos('S1'), pos('1'));
   prefix := 'system-images;android-'api';';
   
   for (i := 0; i < gCurPackages._length(); i++) {
      if (gCurPackages[i].installed && beginsWith(gCurPackages[i].id, prefix)) {
         _ctl_arch._lbadd_item(substr(gCurPackages[i].id, 1 + prefix._length()));
      }
   }
   _ctl_arch.p_window_id.p_line = 1;
   _ctl_arch.p_window_id._lbselect_line();
}

void _ctl_system_image.on_change(int reason, int index = 0)
{
   if (reason == CHANGE_CLINE) {
      update_available_architectures();
      _ctl_create.p_enabled = validate_create_fields();
   }
}

// Assumes gAvds, gTarget and gDevices are already populated.
void _android_create_avd_form.on_create()
{
   for (i := 0; i < gTargets._length(); i++) {
      _ctl_system_image.p_window_id._lbadd_item(gTargets[i].name);
   }
   _ctl_system_image.p_window_id._lbselect_line();

   update_available_architectures();

   for (i = 0; i < gDevices._length(); i++) {
      _ctl_device.p_window_id._lbadd_item(gDevices[i].name);
   }
   _ctl_device.p_window_id.p_line = 1;
   _ctl_device.p_window_id._lbselect_line();
   _ctl_create.p_enabled = validate_create_fields();
}

void _ctl_cancel.lbutton_up()
{
   p_active_form._delete_window('cancelled');
}

static bool validate_create_fields()
{
   rc := pos('^[a-zA-Z0-9._-]+$', _ctl_name.p_text, 1, 'L');
   if (rc <= 0) {
      _ctl_status.p_caption = "Name contains invalid characters. Allowed characters are: a-z A-Z 0-9 . _ -";
      _ctl_status.p_visible = true;
      return false;
   }

   if (_ctl_arch.p_text == '') {
      _ctl_status.p_caption = "No system images found for platform '"_ctl_system_image.p_text"'. Use the SDK manager to download images for this API level.";
      _ctl_status.p_visible = true;
      return false;
   }

   rc = pos('^[0-9]+[kmKM]', strip(_ctl_sdcard.p_text), 1, 'L');
   if (rc <= 0) {
      _ctl_status.p_caption = "SD card size should be a number, followed by M|K.";
      _ctl_status.p_visible = true;
      return false;
   }

   _ctl_status.p_visible = true;
   _ctl_status.p_caption = "Ok.";
   return true;
}

void _ctl_name.on_change()
{
   _ctl_create.p_enabled = validate_create_fields();
}

void _ctl_arch.on_change(int reason = 0, int index = 0)
{
   _ctl_create.p_enabled = validate_create_fields();
}

void _ctl_device.on_change(int reason = 0, int index = 0)
{
   _ctl_create.p_enabled = validate_create_fields();
}

void _ctl_sdcard.on_change(int reason = 0, int index = 0)
{
   _ctl_create.p_enabled = validate_create_fields();
}

void _ctl_create.lbutton_up()
{

   rc := pos('android-(\d+)', _ctl_system_image.p_text, 1, 'L');
   if (rc <= 0) {
      return;
   }

   apiLev := substr(_ctl_system_image.p_text, pos('S1'), pos('1'));
   image := 'system-images;android-'apiLev';'_ctl_arch.p_text;
   dev := '0';
   for (i := 0; i < gDevices._length(); i++) {
      if (gDevices[i].name == _ctl_device.p_text) {
         dev = gDevices[i].id;
      }
   }
   cmd := avdmanager_exe(gSdk)' create avd -n "'strip(_ctl_name.p_text)'" -k "'image'" -d 'dev' -c 'strip(_ctl_sdcard.p_text);
   pr := progress_show('Creating...', 10);
   rc = command_to_temp_view(cmd, auto tempView, auto origView, pr, 10);
   progress_close(pr);
   if (rc < 0) {
      _message_box('Problem executing AVD manager: 'rc);
      p_active_form._delete_window('cancelled');
      return;
   }

   rc = search('Error:(.*)$', 'L@');
   if (rc == 0) {
      emsg := get_text(match_length('1'), match_length('S1'));
      _message_box('Problem creating AVD: 'emsg);
      p_window_id = origView;
      _delete_temp_view(tempView);
      p_active_form._delete_window('cancelled');
      return;
   }

   p_window_id = origView;
   _delete_temp_view(tempView);
   p_active_form._delete_window('done');
}

defeventtab _android_avd_manager_form;

void _android_avd_manager_form.on_resize()
{
   hmargin := 150;
   vmargin := 100;

   // Pin buttons to lower right corner.
   bY := p_height - vmargin - _ctl_close.p_height;
   bSpace := 75;
   
   curX := p_width - hmargin - _ctl_close.p_width;
   _ctl_close.p_x = curX;
   _ctl_close.p_y = bY;
   curX -= _ctl_close.p_width + bSpace;

   _ctl_new.p_x = curX;
   _ctl_new.p_y = bY;
   curX -= _ctl_new.p_width + bSpace;

   _ctl_delete.p_x = curX;
   _ctl_delete.p_y = bY;
   curX -= _ctl_delete.p_width + bSpace;

   _ctl_launch.p_x = curX;
   _ctl_launch.p_y = bY;
   curX -= _ctl_launch.p_width + bSpace;

   _ctl_refresh.p_x = curX;
   _ctl_refresh.p_y = bY;

   // Stretch tree control between top and buttons.
   _ctl_avd_list.p_x = hmargin;
   _ctl_avd_list.p_y = vmargin;
   _ctl_avd_list.p_width = p_width - 2*hmargin;
   _ctl_avd_list.p_height = bY - 2*vmargin;
   resize_avdmanager_columns();
}

static void update_avd_buttons()
{
   ns := _ctl_avd_list._TreeGetNumSelectedItems();
   if (ns == 0) {
      _ctl_launch.p_enabled = false;
      _ctl_delete.p_enabled = false;
   } else {
      int indices[];
      _ctl_avd_list._TreeGetSelectionIndices(indices);
      avdIndex := _ctl_avd_list._TreeGetUserInfo(indices[0]);
      if (gAvds[avdIndex].status == 'Stopped') {
         _ctl_launch.p_enabled = true;
         _ctl_delete.p_enabled = true;
      } else {
         _ctl_launch.p_enabled = false;
         _ctl_delete.p_enabled = false;
      }
   }
}

static _str avd_emulator_exe(_str sdk)
{
   return sdk'tools'FILESEP'emulator'EXTENSION_EXE;
}

static void reload_avd_list()
{
   load_avd_data(gSdk);
   update_avd_list();
   update_avd_buttons();
}

void _ctl_launch.lbutton_up()
{
   int indices[];
   _ctl_avd_list._TreeGetSelectionIndices(indices);
   if (indices._length() > 0) {
      myForm := p_parent;
      avdIndex := _ctl_avd_list._TreeGetUserInfo(indices[0]);
      start_emulator(gSdk, gAvds[avdIndex].name);
      oldMp := p_mouse_pointer;
      p_mouse_pointer = MP_BUSY;
      for (i := 0; i < 10; i++) {
         delay(40);
         process_events(auto cancel);
      }
      p_mouse_pointer = oldMp;
      // Make sure we haven't switched to another active window due to
      // losing and regaining focus due to emulator windows popping up.
      p_window_id = myForm; 
      reload_avd_list();
   }
}

void _ctl_refresh.lbutton_up()
{
   reload_avd_list();
}

void _ctl_avd_list.on_change(int reason, int index = 0)
{
   if (reason == CHANGE_SELECTED) {
      update_avd_buttons();
   }
}

void _ctl_new.lbutton_up()
{
   rv := show('-modal _android_create_avd_form');
   if (rv != 'cancelled') {
      reload_avd_list();
   }
}

void _ctl_delete.lbutton_up()
{
   int indices[];
   _ctl_avd_list._TreeGetSelectionIndices(indices);

   if (indices._length() == 0) return;

   ai := _ctl_avd_list._TreeGetUserInfo(indices[0]);
   if (gAvds[ai].status != 'Stopped') {
      message('Can only delete stopped AVDs');
      return;
   }

   cmd := avdmanager_exe(gSdk)' delete avd -n "'gAvds[ai].name'"';
   pr := progress_show('Deleting 'gAvds[ai].name, 20);
   rc := exec_command_to_window(cmd, output_window_text_control(), -1, pr, 20);
   progress_close(pr);
   if (rc < 0) {
      _message_box('Problem deleting AVD.  See Output window for details.');
      return;
   }

   _ctl_avd_list._TreeDelete(indices[0]);
}

static void resize_avdmanager_columns()
{
   cw := _ctl_avd_list.p_width intdiv 10;
   _ctl_avd_list._TreeSetColButtonInfo(0, cw * 2, TREE_BUTTON_SORT, -1, 'Name');
   _ctl_avd_list._TreeSetColButtonInfo(1, cw * 2, -1, -1, 'Device'); 
   _ctl_avd_list._TreeSetColButtonInfo(2, cw * 5, -1, -1, 'Target'); 
   _ctl_avd_list._TreeSetColButtonInfo(3, cw * 2, -1, -1, 'Status');
}

static void update_avd_list()
{
   _ctl_avd_list._TreeBeginUpdate(TREE_ROOT_INDEX);
   _ctl_avd_list._TreeDelete(TREE_ROOT_INDEX, "C");

   for (i := 0; i < gAvds._length(); i++) {
      _ctl_avd_list._TreeAddListItem(gAvds[i].name"\t"gAvds[i].device"\t"gAvds[i].target"\t"gAvds[i].status, 0, TREE_ROOT_INDEX, TREE_NODE_LEAF, i);
   }
   _ctl_avd_list._TreeEndUpdate(TREE_ROOT_INDEX);
}

void _android_avd_manager_form.on_create()
{
   resize_avdmanager_columns();
   update_avd_list();
   update_avd_buttons();
}

void _ctl_close.lbutton_up()
{
   p_active_form._delete_window();
}

static int load_avd_data(_str sdk)
{
   // Populates the avd globals with the current AVDs, targets and hw devices.
   pr := progress_show('Loading AVD info...', 100);
   rc := load_existing_avds(sdk, gAvds, pr, 33);
   if (rc != 0) {
      _message_box('Problem loading AVD list.  See output window for details. ('rc')');
      progress_close(pr);
      return rc;
   }
   progress_set(pr, 33);

   EMULATOR_INFO emulators[];
   emulators._makeempty(); 
   rc = android_getDeviceInfo(emulators, sdk);
   if (rc < 0) {
      // Don't fail, but mark the status of everything as unknown.
      for (i := 0; i < gAvds._length(); i++) {
         gAvds[i].status = 'Unknown';
      }
   } else {
      for (i := 0; i < emulators._length(); i++) {
         for (j := 0; i < gAvds[j]._length(); j++) {
            if (emulators[i].name == gAvds[j].name) {
               if (emulators[i].state == 'online') {
                  gAvds[j].status = 'Running';
               }
               break;
            }
         }
      }
   }

   rc = load_available_targets(sdk, gTargets, pr, 33);
   if (rc != 0) {
      _message_box('Problem loading AVD targets.  See output window for details. ('rc')');
      progress_close(pr);
      return rc;
   }
   progress_set(pr, 66);

   rc = load_available_devices(sdk, gDevices, pr, 33);
   if (rc != 0) {
      _message_box('Problem loading AVD devices.  See output window for details. ('rc')');
      progress_close(pr);
      return rc;
   }
   progress_close(pr);

// _dump_var(gAvds, 'AVDS');
// _dump_var(gDevices, 'DEVICES');
// _dump_var(gTargets, 'TARGETS');
   return rc;
}

_command void android_avd_manager() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Android SDK support");
      return;
   }
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box("Error: No Android SDK specified in local.properties for active project.");
      return;
   }

   gSdk = sdk;
   rc := load_avd_data(sdk);
   if (rc != 0) {
      return;
   }

   gCurPackages._makeempty();
   rc = gather_sdks(sdk, gCurPackages);


   show('_android_avd_manager_form');
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
_command int android_pre_clean() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Android SDK support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (ndk != '' && isdirectory(ndk)) {
      _maybe_append_filesep(ndk);
      ndk_build :=  ndk :+ 'ndk-build';
      _str projectDir = _file_path(_project_name);
      cd(projectDir);
      // this has to be executed synchronously because of rebuild
      shell(ndk_build' clean','Q');
   }
   return(0);
}

// Looks up the directory the manifest file is in, assuming the current project
// is an android application.  This is also the directory NDK-BUILD obj directory is placed in.
static _str lookup_manifest_directory()
{
   pf := _projectFindFile(_workspace_filename, _project_name, 'AndroidManifest.xml', 0);
   if (pf == '') {
      return '';
   }

   return _strip_filename(pf, 'N');
}
//NOTES even with gradle support, may still need to run ndk-build NDK_DEBUG=1 directly to get
// debug files in place, otherwise you won't be able to find symbols when we run ndk-gdb
//
// Don't need to mess with gdb.setup, or pass it in as a script to run.  the new ndk-gdb generates a 
// correct setup itself.

const LOCAL_GDB_PORT = 5039;

static _str gdb_script_path()
{
   return _temp_path()'ndkgdbscript'; 
}

// Runs ps command on connected devices, and returns the output in a temp view.
static int device_ps(_str adb, _str serial, int& tempView, int& origView)
{
   cmdline := adb' -s 'serial' shell ps';
   return command_to_temp_view(cmdline,tempView,origView);
}

// Returns <0 on error.  Returns 0 if ps is successful and pid is/isn't found.
static int device_pidfor(_str adb, _str serial, _str pkg, _str& pid)
{
   rc := device_ps(adb,serial, auto tempView, auto origView);
   if (rc < 0) return rc;
   rc = search(' 'pkg'$', '@L');
   if (rc < 0) {
      if (def_debug_android > 0) say('device_pidfor: did not find 'pkg);
      pid = '';
      return 0;
   }
   p_col = 1;
   rc = search('[ ]+([0-9]+)', '@L');
   if (rc < 0) {
      pid = '';
      return STRING_NOT_FOUND_RC;
   }
   pid=get_text(match_length('1'),match_length('S1'));
   return 0;
}

// Returns a property from the device.
static int device_getprop(_str adb, _str serial, _str property, _str& value)
{
   cmdline := adb' -s 'serial' shell getprop 'property;
   rc := command_to_temp_view(cmdline,auto tempView, auto origView);
   if (rc < 0) return rc;
   get_line(auto line);
   value = strip(line);
   activate_window(origView);
   _delete_temp_view(tempView);
   if (value == '') {
      return VSRC_INVALID_ARGUMENT;
   }
   return 0;
}

static _str local_lldb_server_dir(_str sdk)
{
   return sdk'lldb/'ANDROID_LLDB_VERSION'/android/';
}

// Uploads a file to the device.
static int device_push(_str adb, _str serial, _str local, _str remote)
{
   // We assume the remote dir never has spaces.
   push_cmd := adb' -s 'serial' push --sync '_maybe_quote_filename(local)' 'remote;
   return exec_command_to_window(push_cmd, output_window_text_control());
}

static int device_mkdir(_str adb, _str serial, _str pkg, _str dir)
{
   cmd := adb' -s 'serial' shell run-as 'pkg' mkdir -p 'dir;
   return exec_command_to_window(cmd, output_window_text_control());
}

static int device_shellcmd(_str adb, _str serial, _str cmd)
{
   shell_cmd := adb' -s 'serial' shell 'cmd;
   return exec_command_to_window(shell_cmd, output_window_text_control());
}

static _str debugger_socket_name(_str pkg)
{
   return pkg;
}
const DEBUGGER_SOCKET_DIR = '/debugger';

// Waits for a lldbserver to come up by waiting for its abstract socket
// to be created.
int device_wait_for_lldbserver(_str adb, _str serial, _str socket)
{
   if (def_debug_android > 0) say('device_wait_for_lldbserver: 'serial': 'socket);
   num_tries := 30;
   cmd := adb' -s 'serial' shell cat /proc/net/unix';
   needle := ' @'socket;
   rc := 0;

   while (num_tries > 0) {
      num_tries -= 1;
      rc = command_to_temp_view(cmd, auto tempView, auto origView);
      if (rc < 0) break;
      rc = search(needle, '@L');
      activate_window(origView);
      _delete_temp_view(tempView);
      if (rc == 0) break;
      delay(100);
   }

   if (def_debug_android > 0) say('   wait result: 'rc);
   return rc;
}

int ensure_lldbserver_running(_str sdk, _str ndk, _str pkg, _str serial)
{
   adb := adb_path(sdk);
   rc := device_ps(adb, serial, auto tempView, auto origView);
   if (rc < 0)  return rc;

   // Look only for the lldbserver that could be running for this particular app.
   remote_lldb_dir := '/data/data/'pkg'/lldb';
   remote_lldb_exe := remote_lldb_dir'/bin/lldb-server';
   rc = search(remote_lldb_exe, 'L@');
   _delete_temp_view(tempView);
   if (rc == 0) {
      if (def_debug_android > 0) say('ensure_lldbserver_running: already running on 'remote_lldb_exe);
      activate_window(origView);
      return 0;
   }

   rc = device_getprop(adb,serial,'ro.product.cpu.abi2', auto arch);
   if (rc < 0) return rc;
   if (def_debug_android > 0) say('ensure_lldbserver_running: installing to 'pkg' 'arch);
   upload_dir := '/data/local/tmp'; // Dir that has permissions allowing uploads on all supported devices.
   local_lldb := local_lldb_server_dir(sdk);
   local_lldb_server := local_lldb :+ arch'/lldb-server';
   local_lldb_script := local_lldb :+ 'start_lldb_server.sh';
   if (!file_exists(local_lldb_server) || !file_exists(local_lldb_script)) {
      output_window_text_control()._insert_text('Could not find 'local_lldb_server' or 'local_lldb_script);
      return FILE_NOT_FOUND_RC;
   }

   // First just push to tmp directory.  We'll to run-as to get the 
   // pieces into the correct directory with the right permissions.
   rc = device_push(adb, serial, local_lldb_server, upload_dir);
   if (rc < 0) return rc;
   rc = device_push(adb, serial, local_lldb_script, upload_dir);
   if (rc < 0) return rc;

   // Build up directory structure.
   rc = device_mkdir(adb,serial,pkg, remote_lldb_dir'/bin');
   if (rc < 0) return rc;
   rc = device_mkdir(adb,serial,pkg, remote_lldb_dir'/log');
   if (rc < 0) return rc;
   rc = device_mkdir(adb,serial,pkg,remote_lldb_dir'/tmp');
   if (rc < 0) return rc;

   // Copy to app directory so it can be run under the app user, and 
   // fix up the permissions.
   rc = device_shellcmd(adb,serial,'run-as 'pkg' cp 'upload_dir'/lldb-server /data/data/'pkg'/lldb/bin');
   if (rc < 0) return rc;
   rc = device_shellcmd(adb,serial,'run-as 'pkg' chmod 700 /data/data/'pkg'/lldb/bin/lldb-server');
   if (rc < 0) return rc;

   rc = device_shellcmd(adb,serial,'run-as 'pkg' cp 'upload_dir'/start_lldb_server.sh /data/data/'pkg'/lldb/bin');
   if (rc < 0) return rc;
   rc = device_shellcmd(adb,serial,'run-as 'pkg' chmod 700 /data/data/'pkg'/lldb/bin/start_lldb_server.sh');
   if (rc < 0) return rc;

   server_cmd := adb' -s 'serial' shell run-as 'pkg' 'remote_lldb_dir'/bin/start_lldb_server.sh 'remote_lldb_dir' unix-abstract 'DEBUGGER_SOCKET_DIR' 'debugger_socket_name(pkg)' "lldb process:gdb-remote packets"';
   if (def_debug_android > 0) say('ensure_lldb_server_running: server start 'server_cmd);
   rc = shell(server_cmd, 'A');
   if (rc < 0) return rc;

   return device_wait_for_lldbserver(adb, serial, DEBUGGER_SOCKET_DIR:+'/':+debugger_socket_name(pkg));
}

// Creates an attach string for the newer NDK support based on 
// clang/cmake/lldb.
_str _new_ndk_attach_info(_str& debug_cb_name)
{

   debug_cb_name = 'lldb';
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (ndk == '') {
      _message_box('Unable to locate Android NDK directory. Please check that your project is set up to use the NDK.');
      mou_hour_glass(false);
      return '';
   }
   _maybe_append_filesep(ndk);
   _maybe_append_filesep(sdk);

   // retrieve the serial for the device if we have more than 1 online device
   _str device_info = android_runAppOnDevice(true);
   if (device_info == '') {
      return '';
   }
   mou_hour_glass(true);
   parse device_info with 'serial=' auto serial ',' .;
   if (serial == '') {
      _message_box('Problem getting serial number for device.');
      mou_hour_glass(false);
      return '';
   }
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   cd(projectDir);

   if (ensure_lldbserver_running(sdk, ndk, pkg, serial) < 0) {
      _message_box('Problem starting lldb server on device 'device_info'. See output window for details.');
      mou_hour_glass(false);
      return '';
   }

   adb := adb_path(sdk);
   rc := device_getprop(adb, serial, 'ro.product.cpu.abi', auto abi);
   if (rc < 0) {
      _message_box('Could not get ABI for target device 'serial);
      mou_hour_glass(false);
      return '';
   }

   ndk_out := projectDir'build'FILESEP'intermediates'FILESEP'cmake'FILESEP'debug'FILESEP'obj'FILESEP:+abi:+FILESEP;
   if (def_debug_android > 0) say('new_ndk_attach_info: ndk out is 'ndk_out);
   if (!file_exists(ndk_out)) {
      _message_box('Could not find ndk output directory at 'ndk_out);
      mou_hour_glass(false);
      return '';
   }

   rc = device_pidfor(adb, serial, pkg, auto app_pid);
   if (rc < 0 || app_pid == '') {
      _message_box('Could not find PID for application 'pkg' on 'serial'.');
      mou_hour_glass(false);
      return '';
   }
   if (def_debug_android > 0) say('     pid for 'pkg'='app_pid);

   sofile := '';
   fn := '';
   for (fn = file_match(ndk_out, 1); fn != ''; fn = file_match(ndk_out, 0)) {
      if (endsWith(fn, '.so')) {
         sofile = ndk_out:+fn;
         break;
      }
   }

   if (sofile == '') {
      _message_box('Could not find library file in 'ndk_out);
      mou_hour_glass(false);
      return '';
   }
   if (def_debug_android > 0) say('new_ndk_attach_info: sofile='sofile);
   sock := DEBUGGER_SOCKET_DIR :+ '/' :+ debugger_socket_name(pkg);
   attach := 'file='sofile',android-remote='serial',port='sock',pid='app_pid',search='ndk_out',dir=/tmp,args=,session=WORKSPACE: '_workspace_filename;
   if (def_debug_android > 0) say('   attach='attach);
   mou_hour_glass(false);
   return attach;
}

/**
 * Retrieve a string which contains the attach info for vsdebug 
 * to use to attach to a running Android process with GDB.  This 
 * is only used for Android applications which use the NDK. 
 * 
 * @return _str debug attach info 
 */
_str _android_get_attach_info(_str& debug_cb_name)
{
   if (def_debug_android > 0) say('android_get_attach_info');
   if (!_haveBuild() || !_haveDebugging()) {
      return "";
   }

   // Need this to pass a good project directory to ndk-gdb
   andmk_dir := lookup_manifest_directory();
   oldmk := andmk_dir:+FILESEP:+'jni':+FILESEP:+'Android.mk';
   if (!file_exists(oldmk)) {
      return _new_ndk_attach_info(debug_cb_name);
   }


   debug_cb_name = 'gdb';
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (ndk == '') {
      _message_box('Unable to locate Android NDK directory. Please check that your project is set up to use the NDK.');
      mou_hour_glass(false);
      return '';
   }
   _maybe_append_filesep(ndk);
   _maybe_append_filesep(sdk);

   // retrieve the serial for the device if we have more than 1 online device
   _str device_info = android_runAppOnDevice(true);
   if (device_info == '') {
      return '';
   }
   mou_hour_glass(true);
   parse device_info with 'serial=' auto serial ',' .;
   _str projectDir = _file_path(_project_name);
   _maybe_append_filesep(projectDir);
   cd(projectDir);

   // Setup needs platform tools on the path.
   oldpath := get_env('PATH');
   ptpath := sdk'platform-tools';
   set_env('PATH', ptpath':'oldpath);

   // We have to set a different path from the command line default because 
   // the gradle task does this implicitly.  Without this, ndk-gdb will
   // look for the output underneath the directory that has the Android manifest
   // file.
   old_ndk := get_env('NDK_OUT');
   ndk_out := projectDir'build'FILESEP'intermediates'FILESEP'ndkBuild'FILESEP'debug'FILESEP'obj';
   set_env('NDK_OUT', ndk_out);
   if (def_debug_android > 0) say('  NDK_OUT='ndk_out);

   // We also need to extend python's search path to include the libraries and scripts
   // provided by the SDK.
   UNAME un;
   _uname(un);
   archname := lowcase(un.sysname)'-'lowcase(un.cpumachine);
   prebuilt_bin := ndk'prebuilt'FILESEP:+archname:+FILESEP'bin';
   python_search := ndk'python-packages:'prebuilt_bin;
   old_pythonpath := get_env('PYTHONPATH');
   set_env('PYTHONPATH', python_search);
   if (def_debug_android > 0) say('  PYTHONPATH='python_search);

   // locate our ndk-gdb and run the script
   ndk_gdb := _maybe_quote_filename(_getSlickEditInstallPath():+'resource'FILESEP'tools'FILESEP'ndk-gdb'FILESEP'rungdbsetup.py');
   pyexe := prebuilt_bin:+FILESEP'python';
   if (_isWindows()) {
      pyexe :+= '.exe';
   }
   pyexe = _maybe_quote_filename(pyexe);

   _str ndk_gdb_cmd = pyexe' 'ndk_gdb' --verbose --force --port 'LOCAL_GDB_PORT' -p 'andmk_dir;
   ndk_gdb_cmd = serial == '' ? ndk_gdb_cmd : ndk_gdb_cmd :+ ' -s ' :+ serial;
   if (def_debug_android > 0) say('  setup command: 'ndk_gdb_cmd);
   int status = shell(ndk_gdb_cmd,'A');
   set_env('NDK_OUT', old_ndk);
   set_env('PYTHONPATH', old_pythonpath);
   set_env('PATH', oldpath);
   if (status < 0) {
      _message_box('Error running ndk-gdb: 'get_message(status));
      mou_hour_glass(false);
      return '';
   }

   script := gdb_script_path();
   for (i := 0; i < 50 ; i++) {
      if (file_exists(script)) break;
      delay(10);
   }
   if (!file_exists(script)) {
      _message_box('Timed out waiting for gdbserver to start on the device');
      mou_hour_glass(false);
      return '';
   }

   gdb_path := prebuilt_bin:+FILESEP'gdb';
   if (_isWindows()) {
      gdb_path :+= '.exe';
   }


   attach_info := 'file=,host=localhost,port='LOCAL_GDB_PORT',timeout=15,address=32,cache=0,break=0,path='gdb_path',args=-x '_maybe_quote_filename(script)',session=WORKSPACE: '_workspace_filename;
   mou_hour_glass(false);
   if (def_debug_android > 0) say('attach_info='attach_info);
   return attach_info;
}

void _stop_debugging_ndk()
{
   if (def_debug_android > 0) say('debugger stop, cleaning up gdb script file.');
   delete_file(gdb_script_path());
}

static int gather_sdks(_str sdk, SDKRec (&sdks)[])
{
   sdks._makeempty();
   sman := sdkmanager_exe(sdk);
   progress := progress_show('Finding packages...', 100);
   rc := command_to_temp_view(sman' --list --include_obsolete', auto tempView, auto origView, progress, 100);
   if (rc < 0) {
      progress_close(progress);
      return rc;
   }

   rc = search('Installed packages:', '@L');
   if (rc == STRING_NOT_FOUND_RC) {
      rc = search('Available packages:', '@L');
      if (rc == STRING_NOT_FOUND_RC) {
         activate_window(origView);
         _delete_temp_view(tempView);
         progress_close(progress);
         _message_box('SDK manager: could not find available packages.');
         return rc;
      }
   }
   down(3);


   int seen:[];
   installed := true;
   line := '';
   path := '';
   version := '';
   desc := '';

   do {
     get_line(line);
     if (beginsWith(line, 'Available Packages')) {
        installed = false;
        down(2);
        continue;
     } else if (beginsWith(line, 'Available Updates:')) {
        break;
     }

     if (installed) {
        parse line with path '|' version '|' desc '|' auto rest;
     } else {
        parse line with path '|' version '|' desc;
     }
     spath := strip(path);
     if (spath == '') continue;
     desc = strip(desc);
     if (desc == '' || beginsWith(desc, '-')) continue;

     if (seen._indexin(spath)) {
        // Already seen it, don't need to add another.
        continue;
     }

     SDKRec r;
     r.id = spath;
     r.version = strip(version);
     r.description = strip(desc);
     r.installed = installed;
     r.updateAvailable = false;
     seen:[spath] = sdks._length();
     sdks :+= r;
   } while (down() != BOTTOM_OF_FILE_RC);

   //TODO: fix up updateAvailable fields for anything listed in 'Available updates' section.

   activate_window(origView);
   _delete_temp_view(tempView);
   progress_close(progress);
   return 0;
}

_command void android_sdk_manager() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Android SDK support");
      return;
   }
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg);
   if (sdk == '') {
      _message_box('Could not determine SDK location from project.');
      return;
   }

   SDKRec pkgs[];
   if (gather_sdks(sdk, pkgs) == 0) {
      show('_android_sdk_manager_form', pkgs, sdk);
   }
}

defeventtab _android_emulator_error_form;

void ctl_ok.on_create(_str msg)
{
   ctl_err_msg.p_caption = msg;
}


void ctl_ok.lbutton_up()
{
   p_active_form._delete_window();
}

void _android_emulator_error_form.on_resize()
{
   hmargin := ctl_err_msg.p_x;
   vmargin := 100;
   
   ctl_ok.p_x = p_width - hmargin - ctl_ok.p_width;
   ctl_ok.p_y = p_height - vmargin - ctl_ok.p_height;

   ctl_err_msg.p_width = p_width - hmargin*2;
   ctl_err_msg.p_height = p_height - ctl_ok.p_height - vmargin*2 - ctl_err_msg.p_y;
}

// Assumes tagging context is already locked and updated.
static int find_gradle_section(_str sname, long startLimit, long endLimit, long& startPos, long& endPos)
{
   // Sections are essentially function calls taking closures.  
   ns := tag_get_num_of_statements();
   rc := PROCEDURE_NOT_FOUND_RC;
   ckname := sname' ';
   for (i := 1; i < ns; i++) {
      if (tag_get_statement_browse_info(i, auto cm) < 0) continue;
      if (cm.seekpos < startLimit || cm.seekpos > endLimit) continue;

      if (cm.type_id == SE_TAG_TYPE_CALL && beginsWith(cm.member_name, ckname)) {
         startPos = cm.seekpos;
         endPos = cm.end_seekpos-1;  // -1, because we're right after the }
         rc = 0;
         break;
      }
   }

   return rc;
}

// Finds a section, or creates an empty section.  Returns true if it created a new section.
static bool find_or_create_gradle_section(_str sname, long startLimit, long endLimit, long& startPos, long& endPos)
{
   dc := find_gradle_section(sname, startLimit, endLimit, startPos, endPos);
   rv := false;
   if (dc < 0) {
      // If it doesn't exist, add it.
      _GoToROffset(endLimit);
      ind := p_col - 1 + p_SyntaxIndent;
      startPos = _QROffset();
      _insert_text(indent_string(ind):+sname:+" {\n");
      _insert_text(indent_string(ind)"}");
      endPos = _QROffset()-1;
      java_enter();
      _UpdateStatements(true, true); // Fix the tagging offsets we changed.
      rv = true;
   }

   return rv;
}

// Opens the current project's build.gradle into a temp buffer.
// Returns <0 on error.  
static int open_project_build_gradle(int &orig_wid, int& temp_wid, _str& errmsg)
{
   errmsg = '';
   if (_project_name == '') {
      errmsg = 'No project open.';
      return FILE_NOT_FOUND_RC;
   }

   projDir := _strip_filename(_project_name, 'N');
   _maybe_append_filesep(projDir);
   bf := projDir'build.gradle';

   if (!file_exists(bf)) {
      // While you can have gradle projects without a build file, that shouldn't 
      // be the case for android projects.
      errmsg = 'Could not find 'bf;
      return FILE_NOT_FOUND_RC;
   }

   rc := _open_temp_view(bf, temp_wid, orig_wid, doSelectEditorLanguage: true);
   if (rc < 0) {
      errmsg = 'Could not open 'bf;
      return rc;
   }

   return 0;
}

static void extract_quoted(long st, long en, _str& val)
{
   tmp := get_text((int)(1 + en-st), st);
   if (pos("'([^']+)'", tmp, 1, 'L') > 0) {
      val = substr(tmp, pos('S1'), pos('1'));
   } else {
      val = '';
   }
}

static void get_gradle_value(_str valName, long startOff, long endOff, _str& val, _str defVal='')
{
   dc := find_gradle_section(valName, startOff, endOff, auto kv_start, auto kv_end);
   val = defVal;
   if (dc == 0) {
      extract_quoted(kv_start, kv_end, val);
   } 
}

// Reads the current release signing configuration and stores it into the 
// given parameters.  Returns <0 on error.
static int extract_signing_information(_str &storeFile, _str &storePasswd, _str &keyAlias, _str &keyPassword, _str &errmsg)
{
   storeFile = '';
   storePasswd = '';
   keyAlias = '';
   keyPassword = '';
   errmsg = '';

   rc := open_project_build_gradle(auto orig_wid, auto temp_wid, errmsg);
   if (rc < 0) {
      return rc;
   }

   do {
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateStatements(true, true);
      
      // We assume our signing config is always named 'release'.
      rc = find_gradle_section('android', 0, p_buf_size, auto as_begin, auto as_end);
      if (rc < 0) {
         errmsg = 'Could not find "android" section in build.gradle';
         break;
      }
      rc = find_gradle_section('signingConfigs', as_begin, as_end, auto sc_begin, auto sc_end);
      if (rc < 0) {
         errmsg = 'Could not find "signingConfigs" section in build.gradle';
         break;
      }
      rc = find_gradle_section('release', sc_begin, sc_end, auto rel_begin, auto rel_end);
      if (rc < 0) {
         errmsg = 'Could not find "signingConfigs.release" section in build.gradle';
         break;
      }

      get_gradle_value('storeFile', rel_begin, rel_end, storeFile);
      get_gradle_value('storePassword', rel_begin, rel_end, storePasswd);
      get_gradle_value('keyAlias', rel_begin, rel_end, keyAlias);
      get_gradle_value('keyPassword', rel_begin, rel_end, keyPassword);
   } while (false);
   return rc;
}

// Adds release signing information to an existing build.gradle file.  If it already exists, 
// the information is replaced.  Returns <0 on failure, and an optional error message in `errmsg`
static int add_signing_to_build(_str storeFile, _str storePasswd, _str keyAlias, _str keyPassword, _str &errmsg)
{
   if (!file_exists(storeFile)) {
      errmsg = 'Could not find key store file at 'storeFile;
      return FILE_NOT_FOUND_RC;
   }

   rc := open_project_build_gradle(auto orig_wid, auto temp_wid, errmsg);
   if (rc < 0) {
      return rc;
   }

   rc = 0;
   do {
      se.tags.TaggingGuard sentry;
      sentry.lockContext(false);
      _UpdateStatements(true, true);

      rc = find_gradle_section('android', 0L, p_buf_size, auto as_begin, auto as_end);
      if (rc < 0) {
         errmsg = 'Could not find "android" section in build.gradle';
         break;
      }

      if (find_or_create_gradle_section('signingConfigs', as_begin, as_end, auto sc_begin, auto sc_end)) {
         // Created a new section, so fix up android section extents.
         rc = find_gradle_section('android', 0L, p_buf_size, as_begin, as_end);
         if (rc < 0) {
            errmsg = 'No android section found after edit.';
            break;
         }
      }

      dc := find_gradle_section('release', sc_begin, sc_end, auto rel_start, auto rel_end);
      if (dc == 0) {
         // We are replacing it, so go ahead and delete this.
         sel := _alloc_selection();
         _GoToROffset(rel_start);
         _select_char(sel);
         _GoToROffset(rel_end);
         right();
         _select_char(sel);
         _delete_selection(sel);
         _free_selection(sel);
         get_line(auto ln);
         if (ln == '') {
            delete_line();
         }
         _UpdateStatements(true, true); // Fix the tagging offsets we changed.
         rc = find_gradle_section('signingConfigs', as_begin, as_end, sc_begin, sc_end);
         if (rc < 0) {
            errmsg = "No signingConfigs section after edit.";
            break;
         }
      }

      // Now we can add the signingConfigs.release section at the end of the signingConfigs.
      _GoToROffset(sc_end);
      ind := p_col - 1 + p_SyntaxIndent;
      _insert_text(indent_string(ind)"release {\n");
      _insert_text(indent_string(ind+p_SyntaxIndent)"keyAlias '"keyAlias"'\n");
      _insert_text(indent_string(ind+p_SyntaxIndent)"keyPassword '"keyPassword"'\n");
      _insert_text(indent_string(ind+p_SyntaxIndent)"storeFile file('"storeFile"')\n");
      _insert_text(indent_string(ind+p_SyntaxIndent)"storePassword '"storePasswd"'\n");
      _insert_text(indent_string(ind)"}");
      java_enter();
      _UpdateStatements(true, true); // Fix the tagging offsets we changed.

      // Android section extents invalidated now, so get them again.
      rc = find_gradle_section('android', 0L, p_buf_size, as_begin, as_end);
      if (rc < 0) {
         errmsg = 'Could not find "android" section in build.gradle after edits.';
         break;
      }

      find_or_create_gradle_section('buildTypes', as_begin, as_end, auto bt_begin, auto bt_end);
      find_or_create_gradle_section('release', bt_begin, bt_end, auto btrel_begin, auto btrel_end);

      dc = find_gradle_section('signingConfig', btrel_begin, btrel_end, auto btsc_begin, auto btsc_end);
      if (dc == 0) {
         // Delete it so we can re-add it.
         sel := _alloc_selection();
         _GoToROffset(btsc_begin);
         _select_char(sel);
         _GoToROffset(btsc_end);
         right();
         _select_char(sel);
         _delete_selection(sel);
         _free_selection(sel);
         get_line(auto ln);
         if (ln == '') {
            delete_line();
         }
         _UpdateStatements(true, true); // Fix the tagging offsets we changed.
         rc = find_gradle_section('release', bt_begin, bt_end, btrel_begin, btrel_end);
         if (rc < 0) {
            errmsg = "No buildTypes.release section after edit.";
            break;
         }
      }

      // Add the reference to the signing config in the buildTypes.release section.
      _GoToROffset(btrel_end);
      ind = p_col - 1 + p_SyntaxIndent;
      _insert_text(indent_string(ind):+"signingConfig signingConfigs.release");
      java_enter();

      // Lastly, the signing configs must be before the buildTypes under the android section, 
      // otherwise the build file won't compile. 
      if (sc_begin > bt_begin) {
         // Regenerate offsets one more time.
         _UpdateStatements(true, true); 
         rc = find_gradle_section('android', 0L, p_buf_size, as_begin, as_end);
         if (rc < 0) {
            errmsg = 'Could not find "android" section in build.gradle for reordering';
            break;
         }
         rc = find_gradle_section('signingConfigs', as_begin, as_end, sc_begin, sc_end);
         if (rc < 0) {
            errmsg = 'Could not find "signingConfigs" section in build.gradle for reordering';
            break;
         }
         rc = find_gradle_section('buildTypes', as_begin, as_end, bt_begin, bt_end);
         if (rc < 0) {
            errmsg = 'Could not find "buildTypes" section in build.gradle for reordering';
            break;
         }

         // Cut the signing configs section and move it up.
         sel := _alloc_selection();
         _GoToROffset(sc_begin);
         sect := get_text((int)(1 + sc_end-sc_begin));
         _select_char(sel);
         _GoToROffset(sc_end);
         right();
         _select_char(sel);
         _delete_selection(sel);
         _free_selection(sel);
         get_line(auto ln);
         if (ln == '') {
            delete_line();
         }

         _GoToROffset(bt_begin);
         java_enter();
         _GoToROffset(bt_begin);
         _insert_text(sect);
         java_enter();
      }
   } while (false);

   if (rc == 0) {
      save();
   }
   p_window_id = orig_wid;
   _delete_temp_view(temp_wid);

   return rc;
}

defeventtab _android_signing_form;

static void update_feedback()
{
   msg := '';
   ks := strip(ctl_keystore.p_text);
   if (ks == '') {
      msg = 'No keystore file selected.';
   } else if (!file_exists(ks)) {
      msg = 'File not found: 'ks;
   } else if (ctl_key_alias.p_text == '') {
      msg = 'Must suppy the key alias name.';
   }

   if (msg == '') {
      ctl_feedback.p_caption = '';
      ctl_ok.p_enabled = true;
   } else {
      ctl_feedback.p_caption = msg;
      ctl_ok.p_enabled = false;
   }
}

void ctl_ok.on_create()
{
   saved := p_active_form;
   extract_signing_information(auto sf, auto sp, auto ka, auto kp, auto errmsg);
   p_window_id = saved;
   ctl_keystore.p_text = sf;
   ctl_ks_password.p_text = sp;
   ctl_key_alias.p_text = ka;
   ctl_key_password.p_text = kp;
   sizeBrowseButtonToTextBox(ctl_keystore.p_window_id, _browsefile.p_window_id, 
                             0, ctl_keystore.p_active_form.p_width - ctl_keystore.p_x);
   update_feedback();
}

void ctl_keystore.on_change()
{
   update_feedback();
}

void ctl_key_alias.on_change()
{
   update_feedback();
}

void _android_signing_form.on_resize()
{
   hmargin := ctllabel1.p_x;
   vmargin := 100;
   
   // Buttons to bottom right.
   ctl_cancel.p_x = p_width - hmargin - ctl_cancel.p_width;
   ctl_cancel.p_y = p_height - vmargin - ctl_cancel.p_height;
   ctl_ok.p_x = ctl_cancel.p_x - hmargin - ctl_ok.p_width;
   ctl_ok.p_y = ctl_cancel.p_y;

   // Center error feedback and stretch to take up vertical space
   // down to buttons.
   ctl_feedback.p_width = p_width - 2*ctl_feedback.p_x;
   ctl_feedback.p_height = ctl_ok.p_y - vmargin - ctl_feedback.p_y;

   // Right edges of text boxes aligned. 
   _browsefile.p_x = p_width - hmargin - _browsefile.p_width;
   rend := _browsefile.p_x + _browsefile.p_width - 20;
   ctl_keystore.p_width = rend - ctl_keystore.p_x;
   ctl_ks_password.p_width = rend - ctl_ks_password.p_x;
   ctl_key_alias.p_width = rend - ctl_key_alias.p_x;
   ctl_key_password.p_width = rend - ctl_key_password.p_x;
   ctl_instructions.p_width = rend - ctl_instructions.p_x;
}

void ctl_ok.lbutton_up()
{
   saved := p_active_form;
   rc := add_signing_to_build(ctl_keystore.p_text, ctl_ks_password.p_text, ctl_key_alias.p_text, ctl_key_password.p_text, auto err);
   p_window_id = saved;

   if (rc < 0) {
      _message_box('Error saving signing information to build.gradle ('rc'): 'err, 'Error saving signing setup');
   } else {
      _message_box('You will need to rebuild the application for it to be signed with the updated key.', 'Release signing updated');
   }
   p_active_form._delete_window();
}

void _browsefile.lbutton_up()
{
   fdir := ctl_keystore.p_text;
   filters := "Java Key Store (*.jks)";
   wcs := '*.jks';
   rv := _OpenDialog('-modal', "Select `mvn` executable", wcs, filters, OFN_FILEMUSTEXIST, "", '', fdir);
   if (rv != '') {
      ctl_keystore.p_text = _maybe_unquote_filename(rv);
   }
   update_feedback();
}

// Prompts user for release signing key information.
_command int android_configure_signing() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   show('_android_signing_form');
   return 0;
}

