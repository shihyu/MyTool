////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc. 
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
// 
// Language support module for Google Go
// 
#pragma option(pedantic,on)
#region Imports
#include "project.sh"
#include "slick.sh"
#include "tagsdb.sh"
#import "clipbd.e"
#import "compile.e"
#import "env.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "listbox.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "mprompt.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "util.e"
#import "wkspace.e"
#import "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

static const GOOGLE_GO_LANGUAGE_ID= "googlego";

_str def_googlego_exe_path = "";
static _str _googlego_cached_exe_path;

definit() {
   _googlego_cached_exe_path="";
}

defeventtab googlego_keys;
def  ' '= c_space;
def  '('= c_paren;
def  '.'= auto_codehelp_key;
def  ':'= c_colon;
def  '\'= c_backslash;
def  '{'= c_begin;
def  '}'= c_endbrace;
def  'ENTER'= c_enter;
def  'TAB'= smarttab;
def  ';'= c_semicolon;

_command googlego_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(GOOGLE_GO_LANGUAGE_ID);
}

/**
 * Callback called from _project_command to prepare the 
 * environment for running google go command-line interpreter. 
 * The value found in def_googlego_exe_path takes precedence. If 
 * not found, the environment will be checked for existing 
 * values. If all else fails, a path search will be performed. 
 *
 * @param projectHandle  Project handle. Set to -1 to use 
 *                       current project. Defaults to -1.
 * @param config         Project configuration name. Set to "" 
 *                       to use current configuration. Defaults
 *                       to "".
 * @param target         Project target name (e.g. "Execute", 
 *                       "Compile", etc.).
 * @param quiet          Set to true if you do not want to 
 *                       display error messages to user.
 *                       Defaults to false.
 * @param error_hint     (out) Set to a user-friendly message on 
 *                       error suitable for display in a message.
 *
 * @return 0 on success, <0 on error.
 */
int  _googlego_set_environment(int projectHandle, _str config, _str target,
                               bool quiet, _str error_hint)
{
   return set_googlego_environment();
}

int set_googlego_environment(_str command="go"EXTENSION_EXE)
{
   goExePath := guessGoExePath(command);
   // restore the original environment.  this is done so the
   // path for go is not appended over and over
   _restore_origenv(false);
   if (goExePath == "") {
      // Prompt user for interpreter
      int status = _MDICurrent().textBoxDialog("Google Go Executable",
                                      0,
                                      0,
                                      "",
                                      "OK,Cancel:_cancel\tSpecify the path to 'go"EXTENSION_EXE"'.",  // Button List
                                      "",
                                      "-c "FILENOQUOTES_ARG:+_chr(0)"-bf Google Go Executable Path:");
      if( status < 0 ) {
         // Probably COMMAND_CANCELLED_RC
         return status;
      }

      // Save the values entered and mark the configuration as modified
      def_googlego_exe_path = _param1;
      _googlego_cached_exe_path="";
      _config_modify_flags(CFGMODIFY_DEFVAR);

      goExePath = def_googlego_exe_path;
   }

   // Set the environment
   goExeCommand := goExePath;
   if (!_file_eq(_strip_filename(goExePath,'PE'), "go")) {
      _maybe_append(goExePath, FILESEP);
      goExeCommand = goExePath:+command;
   }
   set_env(GO_EXE_ENV_VAR, goExeCommand);

   goDir := _strip_filename(goExePath, 'N');
   _maybe_strip_filesep(goDir);
   if (goDir != "") {

      // restore the original environment.  this is done so the
      // path for go is not appended over and over
      _restore_origenv(false);

      // PATH
      _str path = _replace_envvars("%PATH%");
      _maybe_prepend(path, PATHSEP);
      path = goDir :+ path;
      set("PATH="path);
   }

   // lastest version of 'Go' wants GOROOT set
   goRoot := _strip_filename(goDir, 'N');
   if (goRoot != "") {
      set_env("GOROOT", goRoot);
   }

   // set the extension for the os
   set_env(GO_OUTPUT_FILE_EXT_ENV_VAR, EXTENSION_EXE);

   // if this wasn't set, then we didn't find anything
   return (goExePath != ""?0:1);
}

int _googlego_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // maybe we can recycle tag file(s)
   lang := GOOGLE_GO_LANGUAGE_ID;
   if (ext_MaybeRecycleTagFile(tfindex, auto tagfilename, lang) && !forceRebuild) {
      return 0;
   }

   // Try to guess where Go is installed
   goPath := guessGoExePath("gofmt":+EXTENSION_EXE);
   if (goPath != "") {
      goPath = strip(goPath, 'T', FILESEP);
      goPath = _strip_filename(goPath, 'n');
   }

   // no go
   if (goPath == "") return 1;

   _maybe_append_filesep(goPath);
   std_libs := goPath :+ "src" :+ FILESEP :+ "*.go";

   // Build and Save tag file
   return ext_BuildTagFile(tfindex, tagfilename, lang, 
                           "Google Go Compiler Libraries", true, 
                           _maybe_quote_filename(std_libs) :+ " -E *_test.go",
                           ext_builtins_path(lang),
                           withRefs, useThread);
}

static _str GetWindowsGoPath(_str command)
{
   goPath := "";
   if (_isWindows()) {
      _ntRegFindValue(HKEY_LOCAL_MACHINE,
                      "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment",
                      "GOROOT", goPath);
      if (goPath == "") {
         _ntRegFindValue(HKEY_CURRENT_USER,
                         "Software\\GoProgrammingLanguage",
                         "installLocation", goPath);
      }
      if (goPath == "" && file_exists("C:\\Go\\bin\\":+command)) {
         goPath = "C:\\Go\\";
      }
   }
   return goPath;
}

void _googlego_getAutoTagChoices(_str &langCaption, int &langPriority, 
                                 AUTOTAG_BUILD_INFO (&choices)[], _str &defaultChoice)
{
   _str goExePaths[];
   langPriority = 46;
   langCaption = "Google Go libraries";
   defaultChoice = "";

   // check the cached "GO" path
   exePath := _GetCachedExePath(def_googlego_exe_path,_googlego_cached_exe_path,"gofmt"EXTENSION_EXE);
   if ( exePath != "" && file_exists(exePath)) {
      goExePaths :+= exePath;
   }

   // try a plain old path search
   exePath = path_search("gofmt"EXTENSION_EXE, "", 'P');
   if (exePath != "") {
      goExePaths :+= exePath;
   }

   // try the original path
   if (exePath != "") {
      exePath = _orig_path_search("gofmt"EXTENSION_EXE);
      if (exePath != "") {
         _restore_origenv(true);
         goExePaths :+= exePath;
      }
   }

   // maybe check the registry
   if (_isWindows()) {
       exePath = GetWindowsGoPath("go.exe");
       if (exePath != "") {
          _maybe_append_filesep(exePath);
          goExePaths :+= exePath :+ "bin":+FILESEP:+"go.exe";
       }
   }

   // /usr/local/go is the default package installation path on MacOS
   if (_isUnix() && file_exists("/usr/local/go/bin/gofmt")) {
      goExePaths :+= "/usr/local/go/bin/go";
   }

   // Go could also be installed in /opt
   if (_isUnix() && file_exists("/opt/go/bin/gofmt")) {
      goExePaths :+= "/opt/go/bin/go";
   }

   // check for cygwin version
   if (_isWindows()) {
      exePath = _path2cygwin("/bin/gofmt.exe");
      if (exePath != "") {
         exePath = _cygwin2dospath(exePath);
         if (exePath != "") {
            goExePaths :+= exePath;
         }
      }
   }

   // set up tag file build
   foreach (auto p in goExePaths) {
      if (p != "") {
         installPath := _strip_filename(p, 'n');;
         installPath = strip(installPath, 'T', FILESEP);
         installPath = _strip_filename(installPath, 'n');

         AUTOTAG_BUILD_INFO autotagInfo;
         if (pos("cygwin", p,  1, 'i')) {
            autotagInfo.configName = "Cygwin Go";
         } else if (pos("mingw", p, 1, 'i')) {
            autotagInfo.configName = "MinGW Go";
         } else if (pos("google", p, 1, 'i')) {
            autotagInfo.configName = "Google Go";
         } else {
            autotagInfo.configName = installPath;
         }

         autotagInfo.langId = "googlego";
         autotagInfo.tagDatabase = "go":+TAG_FILE_EXT;
         autotagInfo.directoryPath = installPath;
         autotagInfo.wildcardOptions = "";
         choices :+= autotagInfo;
      }
   }
}

int _googlego_buildAutoTagFile(AUTOTAG_BUILD_INFO &autotagInfo, bool backgroundThread = true)
{
   config_name := autotagInfo.configName;
   goPath := autotagInfo.directoryPath;
   _maybe_append_filesep(goPath);
   std_libs := goPath :+ "src" :+ FILESEP :+ "*.go";

   // Build and Save tag file
   tfindex := 0;
   return ext_BuildTagFile(tfindex, 
                           _tagfiles_path():+autotagInfo.tagDatabase,
                           autotagInfo.langId,
                           "Google Go Compiler Libraries", true, 
                           _maybe_quote_filename(std_libs) :+ " -E *_test.go",
                           ext_builtins_path(autotagInfo.langId),
                           false, backgroundThread);
}

// handle of project file
static int GG_PROJECT_HANDLE(...) {
   if (arg()) ctl_ok.p_user=arg(1);
   return ctl_ok.p_user;
}
// whether we are currently changing the config
static int GG_CHANGING_CONFIG(...) {
   if (arg()) ctl_cancel.p_user=arg(1);
   return ctl_cancel.p_user;
}
// the last selected config
static _str GG_LAST_CONFIG(...) {
   if (arg()) ctllabel1.p_user=arg(1);
   return ctllabel1.p_user;
}
// list of configs for this project
static _str GG_CONFIG_LIST(...)[] {
   if (arg()) ctllabel10.p_user=arg(1);
   return ctllabel10.p_user;
}
// table of options for each config
static const GG_OPTS="GG_OPTS";

static const DEFAULT_FILE=       '"%f"';
static const GO_EXE_ENV_VAR=     "SLICKEDIT_GOOGLEGO_EXE";
static const GO_OUTPUT_FILE_EXT_ENV_VAR= "SLICKEDIT_GOOGLEGO_OUTPUT_EXT";

struct GoogleGoOptions {
   // arguments for go build
   _str buildArgs;
   // Packages to build. If blank then current file is run.
   _str packages;
   // output file
   _str outputFile;
   // Arguments to the executable
   _str exeArgs;
};

_command void googlegooptions(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return;
   }

   mou_hour_glass(true);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   if (configName == "") configName = GetCurrentConfigName();

   ctlbutton_wid := project_prop_wid._find_control("ctlcommand_options");
   typeless result = ctlbutton_wid.call_event("_googlego_options_form",configName,ctlbutton_wid,LBUTTON_UP,'w');
   ctltooltree_wid := project_prop_wid._find_control("ctlToolTree");
   int status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX,"Execute",'i');
   if( status < 0 ) {
      _message_box("EXECUTE command not found");
   } else {
      if( result == "" ) {
         opencancel_wid := project_prop_wid._find_control("_opencancel");
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'w');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'w');
      }
   }
   projectFilesNotNeeded(0);
}

defeventtab _googlego_options_form;

void ctl_ok.on_create(int projectHandle, _str currentConfig=""/*,
                     _str projectFilename=_project_name, bool isProjectTemplate=false*/)
{
   GG_PROJECT_HANDLE(projectHandle);

   _googlego_options_form_initial_alignment();

   GG_CHANGING_CONFIG(1);
   orig_wid := p_window_id;

   p_window_id = ctl_current_config.p_window_id;
   _str configList[];
   _ProjectGet_ConfigNames(projectHandle, configList);
   for (i := 0; i < configList._length(); ++i) {
      _lbadd_item(configList[i]);
   }

   // "All Configurations" config
   _lbadd_item(PROJ_ALL_CONFIGS);
   if (_lbfind_and_select_item(currentConfig)) {
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, "", true);
   }
   GG_LAST_CONFIG(ctl_current_config.p_text);

   p_window_id = orig_wid;
   GG_CHANGING_CONFIG(0);

   GoogleGoOptions ggOpts:[] = null;
   getGoogleGoProjectOptions(projectHandle, configList, ggOpts);

   GG_CONFIG_LIST(configList);
   _SetDialogInfoHt(GG_OPTS,ggOpts);

   ctl_go_exe_path.p_text = def_googlego_exe_path;

   // Initialize form with options.
   // Note: Cannot simply call ctl_current_config.ON_CHANGE because
   // we do not want initial values validated (they might not be valid).
   // Note: It is not possible (through the GUI) to bring up the
   // options dialog without at least 1 configuration.
   setFormOptionsFromConfig(GG_LAST_CONFIG(), ggOpts);

}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _googlego_options_form_initial_alignment()
{
   rightAlign := ctl_current_config.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_go_exe_path.p_window_id, ctl_browse_go_exe.p_window_id, 0, rightAlign);

   rightAlign = ctl_exe_args.p_x_extent;
   sizeBrowseButtonToTextBox(ctl_packages.p_window_id, ctl_browse_packages.p_window_id, 0, rightAlign);
}

static void getGoogleGoProjectOptions(int projectHandle, _str (&configList)[], GoogleGoOptions (&optsList):[])
{
   foreach (auto config in configList) {
      GoogleGoOptions opts;
      buildArgs := packages := outputFile := exeArgs := "";

      // go through each config
      node := _ProjectGet_ConfigNode(projectHandle, config);
      if (node >= 0) {

         // pull the packages off the clean node - it's easier that way because clean 
         // doesn't have other arguments which may confuse the issue
         target_node := _ProjectGet_TargetNode(projectHandle, "Clean", config);
         cmdline := _ProjectGet_TargetCmdLine(projectHandle, target_node, false);
         parse cmdline with . ('"%('GO_EXE_ENV_VAR')" clean') cmdline;
         packages = strip(cmdline);

         // get the execute node for the build options and output file
         target_node = _ProjectGet_TargetNode(projectHandle, "Build", config);
         cmdline = _ProjectGet_TargetCmdLine(projectHandle, target_node, false);
         parse cmdline with . ('"%('GO_EXE_ENV_VAR')" build') cmdline;
         cmdline = strip(cmdline);
         // go build [-o output] [build flags] [packages]

         // check for an output file argument
         if (beginsWith(cmdline, '-o')) {
            parse cmdline with '-o' cmdline;
            outputFile = parse_file(cmdline);
         }

         // now we pull the packages off the backend and VOILA! are left with the build args
         if (length(cmdline) > length(packages)) {
            buildArgs = substr(cmdline, 1, length(cmdline) - length(packages));
         }

         // this is the default, so it doesn't need to be shown
         if (packages == DEFAULT_FILE) packages = "";

         target_node = _ProjectGet_TargetNode(projectHandle, "Execute", config);
         exeArgs = _ProjectGet_TargetOtherOptions(projectHandle, target_node);
      }

      opts.buildArgs = buildArgs;
      opts.packages = packages;
      opts.outputFile = outputFile;
      opts.exeArgs = exeArgs;
      optsList:[config] = opts;
   }
}


static void setFormOptionsFromConfig(_str config,
                                     GoogleGoOptions (&ggOpts):[])
{
   GoogleGoOptions opts;
   if( config == PROJ_ALL_CONFIGS ) {
      // If options do not match across all configs, then use default options instead
      _str last_cfg, cfg;

      last_cfg = "";
      foreach (cfg => . in ggOpts) {
         if (last_cfg != "") {
            if (ggOpts:[last_cfg] != ggOpts:[cfg] ) {
               // No match, so use default options
               opts.buildArgs = opts.exeArgs = opts.packages = opts.outputFile = "";
               break;
            }
         } 
         // Match (or first config)
         opts = ggOpts:[cfg];
         last_cfg = cfg;
      }
   } else {
      opts = ggOpts:[config];
   }

   ctl_build_args.p_text = opts.buildArgs;
   ctl_packages.p_text = opts.packages;
   ctl_output_file.p_text = opts.outputFile;
   ctl_exe_args.p_text = opts.exeArgs;

}

void ctl_browse_packages.lbutton_up()
{
   wildcards := "Google Go Files (*.go)";
   format_list := "";
   parse def_file_types with "Google Go Files" +0 format_list',';
   if( format_list == "" ) {
      // Fall back
      format_list = wildcards;
   }

   // Try to be smart about the initial directory
   dir := _ProjectGet_WorkingDir(GG_PROJECT_HANDLE());
   dir = absolute(dir, _strip_filename(_project_name, 'N'));

   _str result = _OpenDialog("-modal",
                             "Packages",
                             wildcards,
                             format_list,
                             OFN_ALLOWMULTISELECT|OFN_FILEMUSTEXIST,              // OFN_* flags
                             "",             // Default extensions
                             "",             // Initial filename
                             dir,            // Initial directory
                             "",             // Retrieve name
                             ""              // Help topic
                            );

   if (result != "") {
      text := strip(p_prev.p_text);
      files := "";
      while (result != "") {
         file := parse_file(result, false);
         file = relative(file, dir);

         // make sure it's not already in there
         if (!pos(" "file" ", " "text" ") && pos('"'file'"', '"'text'"')) {
            files :+= " "_maybe_quote_filename(file);
         }
      }
      files = strip(files);

      if (files != "") {
         p_prev.p_text = text" "files;
      }
      p_prev._set_focus();
   }
}

void ctl_current_config.on_change(int reason)
{
   if (GG_CHANGING_CONFIG()) return;
   if (reason != CHANGE_CLINE) return;

   GG_CHANGING_CONFIG(1);
   changeCurrentConfig(p_text);
   GG_CHANGING_CONFIG(0);
}

static void changeCurrentConfig(_str config)
{
   GoogleGoOptions opts;
   opts.buildArgs = ctl_build_args.p_text;
   opts.packages = ctl_packages.p_text;
   opts.outputFile = ctl_output_file.p_text;
   opts.exeArgs = ctl_exe_args.p_text;

   // All good, save these settings
   if (config == PROJ_ALL_CONFIGS) {
      _str list[]=GG_CONFIG_LIST();
      for (i := 0; i < list._length(); i++) {
         _GetDialogInfoHtPtr(GG_OPTS)->:[list[i]] = opts;
      }
   } else {
      _GetDialogInfoHtPtr(GG_OPTS)->:[config] = opts;
   }

   // Set form options for new config.
   // "All Configurations" case:
   // If switching to "All Configurations" and configs do not match, then use
   // last options for the default. This is better than blasting the user's
   // settings completely with generic default options.
   GG_LAST_CONFIG(config);
   setFormOptionsFromConfig(GG_LAST_CONFIG(), *_GetDialogInfoHtPtr(GG_OPTS));
}

void ctl_browse_go_exe.lbutton_up()
{
   _str wildcards = _isUnix()?"":"Executable Files (*.exe;*.com;*.bat;*.cmd)";
   _str format_list = wildcards;

   // Try to be smart about the initial filename and directory
   init_dir := "";
   init_filename := ctl_go_exe_path.p_text;
   if( init_filename == "" ) {
      init_filename = guessGoExePath();
   }
   if( init_filename != "" ) {
      // Strip off the 'go' exe to leave the directory
      init_dir = _strip_filename(init_filename,'N');
      _maybe_strip_filesep(init_dir);

      // Strip directory off 'go' exe to leave filename-only
      init_filename = _strip_filename(init_filename,'P');
   }

   _str result = _OpenDialog("-modal",
                             "Google Go",
                             wildcards,
                             format_list,
                             0,             // OFN_* flags
                             "",            // Default extensions
                             init_filename, // Initial filename
                             init_dir,      // Initial directory
                             "",            // Retrieve name
                             ""             // Help topic
                            );
   if( result != "" ) {
      result = strip(result,'B','"');
      p_prev.p_text = result;
      p_prev._set_focus();
   }
}

void ctl_ok.lbutton_up()
{
   // save current values
   changeCurrentConfig(ctl_current_config.p_text);

   // Save all configs for project
   _str list[]=GG_CONFIG_LIST();
   foreach (auto config in list) {
      setProjectOptionsForConfig(GG_PROJECT_HANDLE(), config, _GetDialogInfoHtPtr(GG_OPTS)->:[config]);
   }

   // Go 
   goExePath := ctl_go_exe_path.p_text;
   if(goExePath != def_googlego_exe_path) {
      def_googlego_exe_path = goExePath;
      _googlego_cached_exe_path="";
      // Flag state file modified
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // Success
   p_active_form._delete_window(0);
}

static void setProjectOptionsForConfig(int projectHandle, _str config, GoogleGoOptions& opts)
{
   cmdline := "";
   packages := "";
   if (opts.packages != "") {
      temp := opts.packages;
      while (temp != "") {
         packages :+= " "_maybe_quote_filename(parse_file(temp));
      }
      packages = strip(packages);
   }
   // default to current file
   if (packages == "") packages = DEFAULT_FILE;

   // build commands used by build and execute
   buildCmdLine := "";
   exeCmdLine := "";
   if (opts.outputFile != "") {
      buildCmdLine = " -o "opts.outputFile" ";
   }

   if (opts.buildArgs != "") {
      buildCmdLine :+= opts.buildArgs" ";
      exeCmdLine :+= opts.buildArgs" ";
   }

   buildCmdLine :+= packages;
   exeCmdLine :+= packages;

   if (opts.exeArgs != "") {
      exeCmdLine :+= " %~other";
   }

   // build
   int target_node = _ProjectGet_TargetNode(projectHandle, "Build", config);
   if (target_node > 0) {
      cmdline = '"%('GO_EXE_ENV_VAR')" build 'buildCmdLine;
      _ProjectSet_TargetCmdLine(projectHandle, target_node, cmdline);
   }

   // clean
   target_node = _ProjectGet_TargetNode(projectHandle, "Clean", config);
   if (target_node > 0) {
      cmdline = '"%('GO_EXE_ENV_VAR')" clean 'packages;
      _ProjectSet_TargetCmdLine(projectHandle, target_node, cmdline);
   }

   // execute
   target_node = _ProjectGet_TargetNode(projectHandle, "Execute", config);
   if (target_node > 0) {
      cmdline = '"%('GO_EXE_ENV_VAR')" run 'exeCmdLine;
      _ProjectSet_TargetCmdLine(projectHandle, target_node, cmdline, "", opts.exeArgs);
   }

   // debug
   target_node = _ProjectGet_TargetNode(projectHandle, "Debug", config);
   if (target_node > 0) {

      // figure out the output file
      outFile := "";
      if (opts.outputFile != "") {
         outFile = opts.outputFile;
      } else if (opts.packages != "") {
         // use the first package
         outFile = parse_file(opts.packages);
         outFile = _strip_filename(outFile, 'E') :+ '%('GO_OUTPUT_FILE_EXT_ENV_VAR')';
      } else {
         // the current file with .exe extension
         outFile = '%n' :+ '%('GO_OUTPUT_FILE_EXT_ENV_VAR')';

      }

      cmdline = 'vsdebugio -prog "'outFile'"';
      if (opts.exeArgs != "") {
         cmdline :+= " "opts.exeArgs;
      }

      _ProjectSet_TargetCmdLine(projectHandle, target_node, cmdline);
   }
}

static _str guessGoExePath(_str command = "go"EXTENSION_EXE)
{
   goPath:=_GetCachedExePath(def_googlego_exe_path,_googlego_cached_exe_path,"go"EXTENSION_EXE);
   if( file_exists(goPath)) {
      // No guessing necessary
      goPath = _strip_filename(goPath, 'N');
      return goPath;
   }

   do {
      command = _replace_envvars2(command);

      // first check their GOROOT environment variable
      goPath = get_env("GOROOT");
      if (goPath != "") {
         _maybe_append_filesep(goPath);
         goPath :+= "bin" :+ FILESEP :+ "go" :+ command;
         if (!file_exists(goPath)) {
            goPath = "";
         }
      }

      // try a plain old path search
      goPath = path_search(command, "", 'P');
      if (goPath != "") {
         goPath = _strip_filename(goPath, 'N');
         break;
      }

      goPath = _orig_path_search(command);
      if (goPath != "") {
         _restore_origenv(true);
         goPath = _strip_filename(goPath, 'N');
         break;
      }

      // maybe check the registry
      if (_isWindows()) {
          goPath = GetWindowsGoPath(command);
          if (goPath != "") {
             _maybe_append_filesep(goPath);
             goPath :+= "bin";
             break;
          }
      }

      // look for gofmt, since there may be other things named go
      goPath = path_search("gofmt", "", "P");
      if (goPath != "") {
         goPath = _strip_filename(goPath, 'N');
         break;
      }

      // /usr/local/go is the default package installation path on MacOS
      if (goPath=="" && _isUnix() && file_exists("/usr/local/go/bin/gofmt")) {
         goPath = "/usr/local/go/bin";
         break;
      }

      // /opt/go is also a reasonable place on Unix
      if (goPath=="" && _isUnix() && file_exists("/opt/go/bin/gofmt")) {
         goPath = "/opt/go/bin";
         break;
      }

      // check for cygwin version
      if (_isWindows()) {
         goPath = _path2cygwin("/bin/gofmt.exe");
         if (goPath != "") {
            goPath = _cygwin2dospath(goPath);
            if (goPath != "") {
               goPath = _strip_filename(goPath, 'N');
               break;
            }
         }
      }

   } while (false);

   if (goPath != "") {
      _maybe_append_filesep(goPath);
      _googlego_cached_exe_path = goPath :+ "go" :+ EXTENSION_EXE;
   } else {
      // clear it out, it's no good
      _googlego_cached_exe_path = "";
   }

   return _googlego_cached_exe_path;
}

