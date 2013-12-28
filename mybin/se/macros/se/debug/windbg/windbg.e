////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#import "listbox.e"
#import "main.e"
#import "project.e"
#import "projconv.e"
#import "projutil.e"
#import "seltree.e"
#import "stdprocs.e"
#import "wkspace.e"
#endregion

#if __NT__
enum {
   VCPROJ_DEBUG_VISUAL_STUDIO = 1,
   VCPROJ_DEBUG_WINDBG = 2,
};

_str def_windbg_path = "";
typeless def_vcproj_debug_prefs = "";

void dbg_windbg_get_default_configuration(_str &name, _str &path, _str &args)
{
   path = def_windbg_path;
}

/**
 * Create a memory dump file.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Debugger_Commands
 */
_command int windbg_write_dumpfile() name_info(',')
{
   if (!debug_active()) {
      _str msg = "No debugger active.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return DEBUG_NOT_INITIALIZED_RC;
   }
   int session_id = dbg_get_current_session();
   if (session_id > 0 && dbg_get_callback_name(session_id) == "windbg") {
      _str filename = '';
      if (filename == '') {
         _str file_list = '*.dmp';
         _str format_list = 'Minidump (*.dmp), All Files ('ALLFILES_RE')';
         typeless result = _OpenDialog('-new -mdi -modal',
                           'Write Dumpfile',
                            file_list,               // Initial wildcards
                            format_list,
                            OFN_SAVEAS,
                            file_list,               // Default extensions
                            '*.dmp',                 // Initial filename
                            '',                      // Initial directory
                            '',                      // Retrieve name
                            ''                       // Help item
                            );
         if (result == '') {
            return (COMMAND_CANCELLED_RC);
         }
         filename = result;
      }

      int status = dbg_windbg_write_dumpfile(filename);
      if (status) {
         debug_message("Command failed",status);
         return(status);
      }
      return 0;
   }
   return(STRING_NOT_FOUND_RC);
}

/**
 * Display list of loaded modules.
 *
 * @categories Debugger_Commands
 */
_command void windbg_list_modules() name_info(',')
{
   if (!debug_active()) {
      _str msg = "No debugger active.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   int session_id = dbg_get_current_session();
   if (session_id > 0 && dbg_get_callback_name(session_id) == "windbg") {
      _str module_list[];
      int status = dbg_windbg_get_modules(module_list);
      if (status) {
         return;
      }
      if (module_list._length() <= 1) {
         return;
      }
      _str columns = module_list[0];
      module_list._deleteel(0);
      select_tree(module_list, null, null, null, null, null,
                  null, "Modules",
                  SL_COLWIDTH|SL_SIZABLE|SL_XY_WIDTH_HEIGHT|SL_CLOSEBUTTON,
                  columns,
                  "", true, null, null);
   }
}


defeventtab _windbg_paths_callback;
void ctl_addpath.lbutton_up()
{
   _str result = _ChooseDirDialog("", "", "", CDN_PATH_MUST_EXIST);
   if (result== '') {
      return;
   }
   index := ctl_tree._TreeAddItem(TREE_ROOT_INDEX, result, TREE_ADD_AS_CHILD, 0, 0, -1, 0, -1);
   if (index > TREE_ROOT_INDEX) {
      ctl_tree._TreeSetUserInfo(index, "");
   }
   if (!ctl_removepath.p_enabled) {
      ctl_removepath.p_enabled = true;
   }
}

void ctl_removepath.lbutton_up()
{
   index := ctl_tree._TreeCurIndex();
   if (index <= TREE_ROOT_INDEX) return;
   ctl_tree._TreeDelete(index);
   if (ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
      p_enabled = false;
   }
}

static _str _windbg_tree_callback(int reason, typeless user_data, typeless info=null)
{
   switch (reason) {
   case SL_ONINITFIRST:
      {
         bottom_wid := _find_control("ctl_bottom_pic");
         default_wid := _find_control("ctl_ok");
         width := default_wid.p_width;
         height := default_wid.p_height;
         add_wid := _create_window(OI_COMMAND_BUTTON, bottom_wid, "Add Path...", 0, 30, width, height, CW_CHILD);
         remove_wid := _create_window(OI_COMMAND_BUTTON, bottom_wid, "Remove Path...", 0, 30, width, height, CW_CHILD);
         add_wid.p_name = 'ctl_addpath';
         remove_wid.p_name = 'ctl_removepath';
         add_wid.p_eventtab = defeventtab _windbg_paths_callback.ctl_addpath;
         remove_wid.p_eventtab = defeventtab _windbg_paths_callback.ctl_removepath;
         add_wid.p_width = add_wid._text_width(add_wid.p_caption) + 240;
         remove_wid.p_width = remove_wid._text_width(remove_wid.p_caption) + 240;
         remove_wid.p_x = add_wid.p_x + add_wid.p_width + 60;
         bottom_wid.p_x = default_wid.p_x;
         bottom_wid.p_height = height + 60;
         bottom_wid.p_visible = bottom_wid.p_enabled = true;
         if (ctl_tree._TreeGetNumChildren(TREE_ROOT_INDEX) == 0) {
            remove_wid.p_enabled = false;
         }
      }
      break;
   }
   return '';
}

/**
 * Display and update symbol path.  Symbol path specifies the
 * directories where symbol files (.pdb files) are located.
 * Modules are reloaded if when symbol path changes.
 *
 * @categories Debugger_Commands
 */
_command void windbg_update_symbols_path() name_info(',')
{
   if (!debug_active()) {
      _str msg = "No debugger active.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   int session_id = dbg_get_current_session();
   if (session_id > 0 && dbg_get_callback_name(session_id) == "windbg") {
      _str symbols;
      int status = dbg_windbg_get_symbols_path(symbols);
      if (status) {
         return;
      }
      _str symbol_paths[];
      split(symbols, ";", symbol_paths);
      results := select_tree(symbol_paths, null, null, null, null, _windbg_tree_callback,
                             null, "Symbol Path",
                             SL_COLWIDTH|SL_SIZABLE|SL_XY_WIDTH_HEIGHT|SL_GET_TREEITEMS,
                             "", "", true, null, null);

      if (results == COMMAND_CANCELLED_RC) {
         return;
      }
      results = stranslate(results,";","\n","r");
      results = stranslate(results,'','"');
      if (results != symbols) {
         dbg_windbg_set_symbols_path(results);
      }
   }
}

/**
 * Display and update image path.  Image path specifies location
 * of loaded executable binary files (.exe or .dll files).
 *
 * @categories Debugger_Commands
 */
_command void windbg_update_image_path() name_info(',')
{
   if (!debug_active()) {
      _str msg = "No debugger active.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   int session_id = dbg_get_current_session();
   if (session_id > 0 && dbg_get_callback_name(session_id) == "windbg") {
      _str image;
      int status = dbg_windbg_get_image_path(image);
      if (status) {
         return;
      }

      _str image_paths[];
      split(image, ";", image_paths);
      results := select_tree(image_paths, null, null, null, null, _windbg_tree_callback,
                             null, "Image Path",
                             SL_COLWIDTH|SL_SIZABLE|SL_XY_WIDTH_HEIGHT|SL_GET_TREEITEMS,
                             "", "", true, null, null);

      if (results == COMMAND_CANCELLED_RC) {
         return;
      }
      results = stranslate(results,";","\n","r");
      results = stranslate(results,'','"');
      if (results != image) {
         dbg_windbg_set_image_path(results);
      }
   }
}

_form _vcproj_debugger_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='Select Debugger';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=1620;
   p_width=5475;
   p_x=7515;
   p_y=10350;
   _label {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Select method for debugging.';
      p_forecolor=0x80000008;
      p_height=240;
      p_tab_index=1;
      p_width=2460;
      p_word_wrap=false;
      p_x=120;
      p_y=120;
   }
   _radio_button _ctlvsdebug {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='Use Visual Studio';
      p_forecolor=0x80000008;
      p_height=300;
      p_tab_index=2;
      p_tab_stop=true;
      p_value=0;
      p_width=3345;
      p_x=300;
      p_y=435;
   }
   _radio_button _ctlwindbgdebug {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='Use integrated WinDbg debugger';
      p_forecolor=0x80000008;
      p_height=300;
      p_tab_index=3;
      p_tab_stop=true;
      p_value=0;
      p_width=3345;
      p_x=300;
      p_y=765;
   }
   _check_box _ctl_no_prompt {
      p_alignment=AL_LEFT;
      p_backcolor=0x80000005;
      p_caption='Do not show these options again.';
      p_forecolor=0x80000008;
      p_height=300;
      p_style=PSCH_AUTO2STATE;
      p_tab_index=4;
      p_tab_stop=true;
      p_value=0;
      p_width=3000;
      p_x=120;
      p_y=1185;
   }
   _command_button _ctl_ok {
      p_cancel=false;
      p_caption='OK';
      p_default=true;
      p_height=300;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=1020;
      p_x=3240;
      p_y=1185;
   }
   _command_button _ctl_cancel {
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=300;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1020;
      p_x=4350;
      p_y=1185;
   }
}

defeventtab _vcproj_debugger_form;
void _ctl_ok.on_create()
{
   _retrieve_prev_form();
}

void _ctl_ok.lbutton_up()
{
   int result;
   if (_ctlvsdebug.p_value) {
      result = VCPROJ_DEBUG_VISUAL_STUDIO;
   } else if (_ctlwindbgdebug.p_value) {
      result = VCPROJ_DEBUG_WINDBG;
   }
   if (_ctl_no_prompt.p_value) {
      def_vcproj_debug_prefs = result;
   }
   _save_form_response();
   p_active_form._delete_window(result);
}

/**
 * Prompt for debugger selection with Visual Studio projects.
 * 
 * @return int 
 */
_command int vcproj_visual_studio_debug()
{
   status := def_vcproj_debug_prefs;
   if (status == "") {
      status = show('-modal _vcproj_debugger_form');
      if (status == '') {
         return COMMAND_CANCELLED_RC;
      }
      return status;
   }
   return status;
}

/**
 * Placeholder command for launching WinDbg debugger for Visual 
 * Studio project debuggging. 
 * 
 * @return int 
 */
_command int vcproj_windbg_debug()
{
   return 0;
}

struct WinDbgOptions {
   _str executableName;
   _str symbolPaths;
};

static void _vcproj_project_get_options_for_config(int projectHandle, _str config, WinDbgOptions& opts)
{
   opts.executableName = "";
   opts.symbolPaths = "";
   configNode := _ProjectGet_ConfigNode(projectHandle, config);
   optionsNode := _xmlcfg_find_simple(projectHandle, "List[@Name='WinDbg Options']", configNode);
   if (optionsNode > 0) {
      node := _xmlcfg_find_simple(projectHandle, "Item[@Name='OutputFile']", optionsNode);
      if (node > 0) {
         opts.executableName = _xmlcfg_get_attribute(projectHandle, node, "Value");
      }

      node = _xmlcfg_find_simple(projectHandle, "Item[@Name='SymbolPaths']", optionsNode);
      if (node > 0) {
         opts.symbolPaths = _xmlcfg_get_attribute(projectHandle, node, "Value");
      }
   }
}

static void _vcproj_project_set_options_for_config(int projectHandle, _str config, WinDbgOptions& opts)
{
   configNode := _ProjectGet_ConfigNode(projectHandle, config);
   optionsNode := _xmlcfg_find_simple(projectHandle, "List[@Name='WinDbg Options']", configNode);
   if (optionsNode < 0) {
      optionsNode = _xmlcfg_add(projectHandle, configNode, VPJTAG_LIST, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle, optionsNode, "Name", "WinDbg Options", 0);
   }

   node := _xmlcfg_find_simple(projectHandle, "Item[@Name='OutputFile']", optionsNode);
   if (node < 0) {
      node = _xmlcfg_add(projectHandle, optionsNode, VPJTAG_ITEM, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle, node, "Name", "OutputFile", 0);
   }
   _xmlcfg_set_attribute(projectHandle, node, "Value", opts.executableName, 0);

   node = _xmlcfg_find_simple(projectHandle,"Item[@Name='SymbolPaths']", optionsNode);
   if (node < 0) {
      node = _xmlcfg_add(projectHandle, optionsNode, VPJTAG_ITEM, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle, node, "Name", "SymbolPaths", 0);
   }
   _xmlcfg_set_attribute(projectHandle, node, "Value", opts.symbolPaths, 0);
}

int _vcproj_project_command_status(int projectHandle, _str config,
                                   int socket_or_status,
                                   _str cmdline,
                                   _str target,
                                   _str buf_name,
                                   _str word,
                                   _str debugStepType,
                                   boolean quiet,
                                   _str& error_hint)
{
   boolean launch_debugger = false;
   if (lowcase(target) == 'debug') {
      if (socket_or_status == COMMAND_CANCELLED_RC) {
         return socket_or_status;
      }
      if (socket_or_status == VCPROJ_DEBUG_VISUAL_STUDIO) {
         node := _ProjectGet_TargetNode(projectHandle, 'debugvisualstudio', config);
         if (node < 0) {
            _message_box("Cannnot find Visual Studio debugging command.", "", MB_OK|MB_ICONEXCLAMATION);
            return COMMAND_CANCELLED_RC;
         }
         project_usertool('debugvisualstudio');
         return 0;
      } else if (socket_or_status == VCPROJ_DEBUG_WINDBG) {
         launch_debugger = true;
      } else {
         _message_box("Unknown operation for Visual Studio debugging.", "", MB_OK|MB_ICONEXCLAMATION);
         return COMMAND_CANCELLED_RC;
      }
   } else if (lowcase(target) == 'debugwindbg') {
      launch_debugger = true;
   } else if (lowcase(target) == 'debugvisualstudio') {
      return 0;
   } else {
      return 0;
   }

   if (launch_debugger) {
      targetNode := _ProjectGet_TargetNode(projectHandle, target, config);
      associatedProject := _ProjectGet_AssociatedFile(projectHandle);
      if (file_eq(_get_extension(associatedProject,true), VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         associatedProject = getICProjAssociatedProjectFile(associatedProject);
      }
      if (associatedProject != '' && _IsVisualStudioProjectFilename(associatedProject)) {
         _str program_name = '';
         _str directory_name = '';
         _str arguments = '';
         _str symbols_path = '';
         _str debugger_path = '';
         _str debugger_args = '-create';
         _str outputFile = '';

         associatedProject = _AbsoluteToProject(associatedProject);
         WinDbgOptions opts;
         _vcproj_project_get_options_for_config(projectHandle, config, opts);
         if (opts.executableName != '') {
            commandLine := _parse_project_command(opts.executableName, buf_name, _project_name, word);
            commandName := parse_file(commandLine, true);
            program_name = '"' :+ absolute(commandName, _file_path(_project_name)) :+ '"';
            if (commandLine != '') {
               program_name = program_name :+ ' ' :+ commandLine;
            }
         } else {
            _GetExeFromVisualStudioFile(associatedProject, config, outputFile);
            program_name = absolute(outputFile, _file_path(_project_name));
         }
         if (program_name :== '') {
            _message_box("WINDBG: Output file not found.", "", MB_OK|MB_ICONEXCLAMATION);
            return 0;
         }

         if (targetNode > 0) {
            directory_name = _ProjectGet_TargetRunFromDir(projectHandle, targetNode);
            if (directory_name != '') {
               directory_name = _parse_project_command(directory_name, buf_name, _project_name, word);
            }
         }
         if (directory_name == '') {
            directory_name = _strip_filename(absolute(program_name, _file_path(_project_name)), 'N');
         }
         debugger_args = debugger_args :+ " -init-dir " :+ maybe_quote_filename(directory_name);

         if (opts.symbolPaths != '') {
            symbols_path = _parse_project_command(opts.symbolPaths, buf_name, _project_name, word);
         } else {
            _GetProgramDatabaseFromVisualStudioFile(associatedProject, config, outputFile);
            symbols_path = _strip_filename(absolute(outputFile, _file_path(_project_name)), 'N');
         }
         if (symbols_path) {
            debugger_args = debugger_args :+ " -symbols " :+ symbols_path;
         }
         int status = debug_begin('windbg', program_name, '', arguments, def_debug_timeout, debugger_path, debugger_args);
         if (!status) {
            if (debugStepType == 'run') {
               debug_go(true);
            } else {
               debug_step_into(true,false);
            }
         }
      }
   }
   return 0;
}

int _vcpp_project_command_status(int projectHandle, _str config,
                                 int socket_or_status,
                                 _str cmdline,
                                 _str target,
                                 _str buf_name,
                                 _str word,
                                 _str debugStepType,
                                 boolean quiet,
                                 _str& error_hint)
{
   return 0;
}

_form _vcproj_debugger_options_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='VCProj Debugger Options';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=3705;
   p_width=7935;
   p_x=4230;
   p_y=5505;
   p_eventtab=_vcproj_debugger_options_form;
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&Settings for:';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=1;
      p_width=900;
      p_word_wrap=false;
      p_x=180;
      p_y=180;
   }
   _combo_box ctl_current_config {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=285;
      p_style=PSCBO_NOEDIT;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=6555;
      p_x=1185;
      p_y=135;
      p_eventtab2=_ul2_combobx;
   }
   _label ctl_windbg_dll_path_label {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&WinDbg path (affects all projects and configurations):';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=4;
      p_width=3870;
      p_word_wrap=false;
      p_x=180;
      p_y=2475;
   }
   _text_box ctl_windbg_path {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=FILENOQUOTES_ARG;
      p_forecolor=0x80000008;
      p_height=255;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=7215;
      p_x=180;
      p_y=2715;
      p_eventtab2=_ul2_textbox;
   }
   _command_button ctl_browse_windbg_path_exe {
      p_cancel=false;
      p_caption='...';
      p_default=false;
      p_height=285;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=270;
      p_x=7485;
      p_y=2670;
   }
   _command_button ctl_ok {
      p_cancel=false;
      p_caption='OK';
      p_default=true;
      p_height=345;
      p_tab_index=7;
      p_tab_stop=true;
      p_width=1125;
      p_x=180;
      p_y=3150;
   }
   _command_button ctl_cancel {
      p_cancel=true;
      p_caption='Cancel';
      p_default=false;
      p_height=345;
      p_tab_index=8;
      p_tab_stop=true;
      p_width=1125;
      p_x=1485;
      p_y=3150;
   }
   _label ctllabel2 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='&Executable name:';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=9;
      p_width=1290;
      p_word_wrap=false;
      p_x=180;
      p_y=675;
   }
   _text_box ctl_output_file {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=255;
      p_tab_index=10;
      p_tab_stop=true;
      p_width=6150;
      p_x=1560;
      p_y=645;
      p_eventtab2=_ul2_textbox;
   }
   _label ctllabel3 {
      p_alignment=AL_LEFT;
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Symbol &path:';
      p_forecolor=0x80000008;
      p_height=195;
      p_tab_index=11;
      p_width=1020;
      p_word_wrap=false;
      p_x=180;
      p_y=1005;
   }
   _text_box ctl_symbols_path {
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_FIXED_SINGLE;
      p_completion=NONE_ARG;
      p_forecolor=0x80000008;
      p_height=255;
      p_tab_index=12;
      p_tab_stop=true;
      p_width=6150;
      p_x=1560;
      p_y=975;
      p_eventtab2=_ul2_textbox;
   }
   _label _ctl_help_panel {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_SUNKEN;
      p_caption='When left blank (the default), the values are determined from the settings from the associated Visual Studio project.  If the settings cannot be determined, or you would like to override the settings specified by the Visual Studio project, you can may set those values here.';
      p_forecolor=0x80000008;
      p_height=825;
      p_tab_index=13;
      p_width=7245;
      p_word_wrap=true;
      p_x=105;
      p_y=1440;
   }
}

defeventtab _vcproj_debugger_options_form;

static void loadCurrentOptions(WinDbgOptions& opts)
{
   ctl_output_file.p_text = opts.executableName;
   ctl_symbols_path.p_text = opts.symbolPaths;
}

static void storeCurrentOptions(WinDbgOptions& opts)
{
   opts.executableName = ctl_output_file.p_text;
   opts.symbolPaths = ctl_symbols_path.p_text;
}

static void loadAllConfigurations(WinDbgOptions (&allOpts):[])
{
   WinDbgOptions opt;
   _str configList[] = _GetDialogInfoHt("configList");
   _str lastConfig = '';
   foreach (auto config in configList) {
      if (lastConfig != "") {
         if (opt.executableName != '') {
            if (allOpts:[lastConfig].executableName != allOpts:[config].executableName) {
               opt.executableName = '';
            }
         }
         if (opt.symbolPaths != '') {
            if (allOpts:[lastConfig].symbolPaths != allOpts:[config].symbolPaths) {
               opt.symbolPaths = '';
            }
         }
      } else {
         opt = allOpts:[config];
      }
      lastConfig = config;
   }

   ctl_output_file.p_text = opt.executableName;
   ctl_symbols_path.p_text = opt.symbolPaths;
}

static void storeAllConfigurations(WinDbgOptions (&allOpts):[])
{
   WinDbgOptions opt;
   opt.executableName = ctl_output_file.p_text;
   opt.symbolPaths = ctl_symbols_path.p_text;

   _str configList[] = _GetDialogInfoHt("configList");
   foreach (auto config in configList) {
      if (opt.executableName != '') {
         allOpts:[config].executableName = opt.executableName;
      }
      if (opt.symbolPaths != '') {
         allOpts:[config].symbolPaths = opt.symbolPaths;
      }
   }
}

void ctl_current_config.on_change(int reason)
{
   WinDbgOptions (*pOpts):[] = _GetDialogInfoHtPtr("optionsList");
   if (pOpts == null) {
      return;
   }
   _str lastConfig = _GetDialogInfoHt("lastConfig");
   if (lastConfig == ALL_CONFIGS) {
      storeAllConfigurations(*pOpts);
   } else if (lastConfig != '') {
      storeCurrentOptions((*pOpts):[lastConfig]);
   }

   lastConfig = p_text;
   _SetDialogInfoHt("lastConfig", lastConfig);

   if (lastConfig == ALL_CONFIGS) {
      loadAllConfigurations(*pOpts);
   } else {
      loadCurrentOptions((*pOpts):[lastConfig]);
   }
}

void ctl_ok.on_create(int projectHandle, _str options="", _str currentConfig="",
                     _str projectFilename=_project_name, boolean isProjectTemplate=false)
{
   // add configurations list
   orig_wid := p_window_id;
   p_window_id = ctl_current_config;
   _ProjectGet_ConfigNames(projectHandle, auto configList);
   int i;
   for (i = 0; i < configList._length(); ++i) {
      _lbadd_item(configList[i]);
   }
   _lbadd_item(ALL_CONFIGS);
   _lbtop();
   if (_lbfind_and_select_item(currentConfig)) {
      _lbfind_and_select_item(ALL_CONFIGS, '', true);
   }
   _str lastConfig = _lbget_text();
   ctl_current_config.p_text = lastConfig;
   p_window_id = orig_wid;

   // get options from project file
   WinDbgOptions optionsList:[];
   foreach (auto config in configList) {
      WinDbgOptions opts;
      _vcproj_project_get_options_for_config(projectHandle, config, opts);
      optionsList:[config] = opts;
   }

   // initialize windbg path
   ctl_windbg_path.p_text = def_windbg_path;

   _SetDialogInfoHt("projectHandle", projectHandle);
   _SetDialogInfoHt("isProjectTemplate", isProjectTemplate);
   _SetDialogInfoHt("configList", configList);
   _SetDialogInfoHt("lastConfig", '');
   _SetDialogInfoHt("optionsList", optionsList);
   ctl_current_config.call_event(CHANGE_SELECTED, ctl_current_config, ON_CHANGE, 'w');
}

void ctl_ok.lbutton_up()
{
   int projectHandle = _GetDialogInfoHt("projectHandle");
   _str configList[] = _GetDialogInfoHt("configList");
   WinDbgOptions (*pOpts):[] = _GetDialogInfoHtPtr("optionsList");
   if (pOpts != null) {
      _str lastConfig = _GetDialogInfoHt("lastConfig");
      if (lastConfig == ALL_CONFIGS) {
         storeAllConfigurations(*pOpts);
      } else if (lastConfig != '') {
         storeCurrentOptions((*pOpts):[lastConfig]);
      }
      foreach (auto config in configList) {
         _vcproj_project_set_options_for_config(projectHandle, config, (*pOpts):[config]);
      }
      _ProjectSave(projectHandle);
   }

   _str dbgPath = ctl_windbg_path.p_text;
   if (dbgPath != def_windbg_path) {
      def_windbg_path = dbgPath;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

_command void vcproj_debug_options() name_info(',')
{
   if (_project_name == "") {
      // What are we doing here?
      _str msg = "No project. Cannot set options.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   int handle = _ProjectHandle(_project_name);
   _str makefile = _ProjectGet_AssociatedFile(handle);
   if (makefile == '') {
      _str msg = "Not a Visual Studio project file.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   _str ext = _get_extension(makefile, true);
   if (file_eq(ext, VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      makefile = getICProjAssociatedProjectFile(makefile);
      ext = _get_extension(makefile, true);
   }
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) || file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
      show('-xy -modal _vcproj_debugger_options_form', _ProjectHandle(_project_name), "", GetCurrentConfigName(), _project_name);
   } else {
      _str msg = "Not a Visual Studio project file.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
}

boolean _windbg_ConfigNeedsDebugMenu(_str debug_command)
{
   return(pos('vcproj_windbg_debug',debug_command,1,'i')!=0);
}
boolean _windbg_DebugCommandCaptureOutputRequiresConcurrentProcess(_str debug_command)
{
   return false;
}
boolean _windbg_ToolbarSupported(_str FormName)
{
   switch (FormName) {
   case '_tbdebug_classes_form':
   case '_tbdebug_exceptions_form':
      return(false);
   }
   return(true);
}

#endif
