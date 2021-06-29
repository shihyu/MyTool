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
#include "debug.sh"
#import "compile.e"
#import "diff.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "picture.e"
#import "project.e"
#import "projconv.e"
#import "sstab.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "wkspace.e"
#endregion

static const OTHER_OPTIONS_MACRO= "%~other";

static _str gConfigList[];
static int gProjectHandle;
static bool gIsProjectTemplate;

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllMonoOpts()
struct MONO_COMPILER_OPTIONS {
   _str CompilerName;         // mcs, vbc, fsharpc
   _str OutputFile;           // -out:
   //bool ReleaseBuild;         // -release
   bool OptimizeOutput;       // -optimize
   bool GenerateDebug;        // -debug
   bool CheckedMath;          // -checked
   bool CLSChecks;            // -clscheck
   bool UnsafeMode;           // -unsafe
   _str DebugOption;          // -debug:portable or :full or :pdbonly
   _str TargetType;           // -target:
   _str WarningLevel;         // -warn:
   _str LanguageVersion;      // -langversion:
   _str LibPaths[];           // -L:
   _str RefAssemblies[];      // -r:
   _str RefPackages[];        // -pkg:
   _str OtherOptions;
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllInterpreterOpts()
struct MONO_INTERPRETER_OPTIONS {
   _str MonoInterpreterName;  // mono or mono32
   _str ApplicationName;      // application path
   _str RuntimeVersion;       // -runtime=
   _str Arguments;            // application command line args
   _str DebuggerOptions;      // --debugger-agent=
   bool VerboseOutput;        // --verbose
   bool ShowVersion;          // --version
   bool RunAsDesktopApp;      // --desktop
   bool RunAsServerApp;       // --server
   bool UseBoehmGC;           // --gc=boehm
   bool UseSGenGC;            // --gc=sgen
   bool Force32Bit;           // --arch=32
   bool Force64Bit;           // --arch=64
   _str OtherOptions;
};

defeventtab _mono_options_form;

static const MONOOPTS_FORM_HEIGHT=    7000;
static const MONOOPTS_FORM_WIDTH=     6000;


static MONO_COMPILER_OPTIONS MONO_COMPILER_INFO(...):[] {
   if (arg()) ctlsscompile.p_user=arg(1);
   return ctlsscompile.p_user;
}
static MONO_INTERPRETER_OPTIONS MONO_INTERPRETER_INFO(...):[] {
   if (arg()) ctlssint.p_user=arg(1);
   return ctlssint.p_user;
}
static MONO_INTERPRETER_OPTIONS MONO_DEBUGGER_INFO(...):[] {
   if (arg()) ctlint_server.p_user=arg(1);
   return ctlint_server.p_user;
}

static _str MONO_LAST_CONFIG(...) {
   if (arg()) ctlCurConfig.p_user=arg(1);
   return ctlCurConfig.p_user;
}
static int MONO_CHANGING_CONFIGURATION(...) {
   if (arg()) ctllabel6.p_user=arg(1);
   return ctllabel6.p_user;
}
static _str MONO_PROJECT_NAME(...) {
   if (arg()) ctlProjLabel.p_user=arg(1);
   return ctlProjLabel.p_user;
}


void ctlok.on_create(int ProjectHandle,_str TabName='',
                     _str CurConfig='',_str ProjectFilename=_project_name,
                     bool IsProjectTemplate=false
                    )
{
   gProjectHandle=ProjectHandle;
   gIsProjectTemplate=IsProjectTemplate;

   _mono_options_form_initial_alignment();

   MONO_PROJECT_NAME(ProjectFilename);
   ctlProjLabel.p_caption = ctlProjLabel._ShrinkFilename(ProjectFilename, ctlProjLabel.p_width);
   ctlMonoInstallDir.p_text=def_mono_install_dir;
   ctlMonoInstallDir._retrieve_list();
   
   wid := p_window_id;
   p_window_id=ctlCurConfig.p_window_id;
   _ProjectGet_ConfigNames(gProjectHandle,gConfigList);
   for (i:=0;i<gConfigList._length();++i) {
      if (strieq(_ProjectGet_Type(gProjectHandle,gConfigList[i]),'mono')) {
         _lbadd_item(gConfigList[i]);
         continue;
      }
      gConfigList._deleteel(i);--i;
   }
   _lbadd_item(PROJ_ALL_CONFIGS);
   _lbtop();
   if (_lbfind_and_select_item(CurConfig)) {
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, '', true);
   }
   p_window_id=wid;

   MONO_COMPILER_OPTIONS    CompilerOpts:[];
   MONO_INTERPRETER_OPTIONS InterpreterOpts:[];
   MONO_INTERPRETER_OPTIONS DebuggerOpts:[];

   GetMonoOptions("build",   CompilerOpts);
   GetMonoOptions("execute", InterpreterOpts);
   GetMonoOptions("debug",   DebuggerOpts);

   ctlmonocc_target_type._lbadd_file_list(" exe winexe library module");
   ctlmonocc_warning_level._lbadd_file_list("\"\" 0 1 2 3 4");
   ctlmonocc_language_version._lbadd_file_list("\"\" ISO-1 ISO-2");

   MONO_COMPILER_INFO(CompilerOpts);
   MONO_INTERPRETER_INFO(InterpreterOpts);
   MONO_DEBUGGER_INFO(DebuggerOpts);

   ctlCurConfig.call_event(CHANGE_CLINE,ctlCurConfig,ON_CHANGE,'W');

   if (TabName=='') {
      ctlss_main_tab._retrieve_value();
   } else {
      ctlss_main_tab.sstActivateTabByCaption(TabName);
   }

   EnableAssemblyPathButtons();
}

int _check_mono_installdir(_str &install_dir)
{
   install_dir=absolute(install_dir);
   _maybe_strip_filesep(install_dir);
   if (!isdirectory(install_dir)) {
      return PATH_NOT_FOUND_RC;
   }
   if (_strip_filename(install_dir,'p')=='bin') {
      install_dir=_strip_filename(install_dir,'n');
      install_dir=substr(install_dir,1,length(install_dir)-1);
   }
   maybeMonoExePath := install_dir:+FILESEP:+'bin':+FILESEP:+'mono';
   if (file_exists(maybeMonoExePath:+EXTENSION_EXE)) {
      return 0;
   }
   if (file_exists(maybeMonoExePath)) {
      return 0;
   }
   if (_isMac()) {
      if (file_exists(install_dir) && file_exists(install_dir:+FILESEP:+"Contents")) {
         _maybe_append_filesep(install_dir);
         install_dir :+= "Contents";
      }
      if (file_exists(install_dir) && file_exists(install_dir:+FILESEP:+"Home")) {
         _maybe_append_filesep(install_dir);
         install_dir :+= "Home";
      }
      maybeMonoExePath= install_dir:+FILESEP:+'bin':+FILESEP:+'mono';
      if (file_exists(maybeMonoExePath)) {
         return 0;
      }
   }

   _maybe_append_filesep(install_dir);
   return FILE_NOT_FOUND_RC;
}

void _mono_options_form.on_resize(int move, bool fromReplaceTabControl = false)
{
   // was this a move only?
   if (move) return;

   // enforce a minimum size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(MONOOPTS_FORM_WIDTH, MONOOPTS_FORM_HEIGHT);
   }

   // calculate deltas based on the width and height of the main tab
   // control relative to the width and height of the forms client
   // area.
   deltax := p_width - (2 * ctlss_main_tab.p_x + ctlss_main_tab.p_width);
   deltay := p_height - (ctlok.p_y_extent + 60);

   // project label
   ctlProjLabel.p_width = p_width - ctlProjLabel.p_x - ctlss_main_tab.p_x;
   ctlProjLabel.p_caption = ctlProjLabel._ShrinkFilename(MONO_PROJECT_NAME(), ctlProjLabel.p_width);

   // handle current config
   ctlCurConfig.p_width += deltax;

   // handle the ok and cancel buttons
   ctlok.p_y += deltay;
   ctlcancel.p_y += deltay;

   // handle the Mono install dir boxes and buttons
   ctlMonoInstallDirLabel.p_y += deltay;
   ctlMonoInstallDir.p_y += deltay;
   ctlMonoInstallDir.p_width += deltax;
   ctlBrowseMonoInstallDir.p_x += deltax;
   ctlBrowseMonoInstallDir.p_y += deltay;

   // handle the main tab control
   ctlss_main_tab.p_width += deltax;
   ctlss_main_tab.p_height += deltay;
   
   // handle compiler tab
   ctlmonocc_compiler_name.p_width += deltax;
   ctlFindCompiler.p_x += deltax;
   ctlmonocc_output_file.p_width += deltax;
   ctlmonocc_output_menu.p_x += deltax;
   ctlFindOutputFile.p_x += deltax;
   ctlmonocc_other_options.p_width += deltax;

   // handle classpath tab
   ctlcp_pathlist.p_width += deltax;
   ctlcp_pathlist.p_height += deltay;
   ctlcp_add_path.p_x += deltax;
   ctlcp_add_assembly.p_x += deltax;
   ctlcp_add_package.p_x += deltax;
   ctlcp_edit.p_x += deltax;
   ctlcp_delete.p_x += deltax;
   ctlcp_up.p_x += deltax;
   ctlcp_down.p_x += deltax;

   // handle interpreter tab
   ctlint_path.p_width += deltax;
   ctlFindInterpreter.p_x += deltax;
   ctlint_app_path.p_width += deltax;
   ctlint_path_menu.p_x += deltax;
   ctlFindAppPath.p_x += deltax;
   ctlint_runtime_version.p_width += deltax;
   ctlint_arguments.p_width += deltax;
   ctlint_other.p_width += deltax;
}

void ctlok.lbutton_up()
{
   // Shouldn't do this here before error checking
   install_dir := ctlMonoInstallDir.p_text;
   if (install_dir!="") {
      foundMonoExe := _check_mono_installdir(install_dir);
      if (foundMonoExe == PATH_NOT_FOUND_RC) {
         ctlMonoInstallDir._text_box_error("The Mono installation directory is not valid.  Please correct or clear this field.");
         return;
      }
      if (foundMonoExe < 0) {
         ctlMonoInstallDir._text_box_error("The Mono installation directory specified does not contain the 'mono' program.  Please correct or clear this field.");
         return;
      }
   }
   if (!_file_eq(def_mono_install_dir, install_dir)) {
      def_mono_install_dir = install_dir;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      if (_project_DebugCallbackName!="") {
         dbg_clear_sourcedirs();
      }
   }
   _append_retrieve(ctlMonoInstallDir, def_mono_install_dir);

   ctlCurConfig.call_event(CHANGE_CLINE,ctlCurConfig,ON_CHANGE,'W');

   MONO_COMPILER_OPTIONS    AllCompilerOpts:[]    = MONO_COMPILER_INFO();
   MONO_INTERPRETER_OPTIONS AllInterpreterOpts:[] = MONO_INTERPRETER_INFO();

   // get the configurations for the project and remember the active config
   ProjectConfig configList[] = null;
   foreach (auto configName in gConfigList) {
      if (AllCompilerOpts._varformat()==VF_HASHTAB) {
         SetMonoCompilerCommand(configName,AllCompilerOpts);
      }
      if (AllInterpreterOpts._varformat()==VF_HASHTAB) {
         SetMonoInterpreterCommand(configName,AllInterpreterOpts);
      }
   }

   p_active_form._delete_window(0);
}

static void EnableAssemblyPathButtons()
{
   _nocheck _control ctlcp_pathlist;
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   if (!p_Noflines) {
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=false;
      ctlcp_up.p_enabled=false;
      ctlcp_down.p_enabled=false;
   }else if (p_line==1) {
      ctlcp_up.p_enabled=false;
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_down.p_enabled=(p_Noflines>1);
   }else if (p_line==p_Noflines) {
      ctlcp_down.p_enabled=false;
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_delete.p_enabled=true;
      ctlcp_up.p_enabled=true;
   }else{
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_up.p_enabled=true;
      ctlcp_down.p_enabled=true;
   }
   ctlcp_delete.p_enabled= p_Noflines && (ctlcp_pathlist.p_Nofselected!=0);
   p_window_id=wid;
}

static void GetMonoOptions(_str CommandNameKey,
                           typeless (&AllConfigInfo):[])
{
   foreach (auto configName in gConfigList) {
      TargetNode := _ProjectGet_TargetNode(gProjectHandle,CommandNameKey,configName);
      cmd := _ProjectGet_TargetCmdLine(gProjectHandle, TargetNode);
      otherOptions := _ProjectGet_TargetOtherOptions(gProjectHandle,TargetNode);
      switch (lowcase(CommandNameKey)) {
      case 'build':
         GetMonoCompilerOptionsFromString(cmd,otherOptions,AllConfigInfo:[configName],configName);
         break;
      case 'execute':
         GetMonoInterpreterOptionsFromString(cmd,otherOptions,AllConfigInfo:[configName]);
         break;
      }
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _mono_options_form_initial_alignment()
{
   // form
   rightAlign := ctlss_main_tab.p_x_extent;
   sizeBrowseButtonToTextBox(ctlMonoInstallDir.p_window_id, ctlBrowseMonoInstallDir.p_window_id, 0, rightAlign);

   // compiler tab
   rightAlign = ctlss_main_tab.p_width - ctlmonocc_debug.p_x;
   sizeBrowseButtonToTextBox(ctlmonocc_compiler_name.p_window_id, ctlFindCompiler.p_window_id,   0, rightAlign);
   sizeBrowseButtonToTextBox(ctlmonocc_output_file.p_window_id,  ctlmonocc_output_menu.p_window_id, ctlFindOutputFile.p_window_id, rightAlign);

   // iterpreter tab
   sizeBrowseButtonToTextBox(ctlint_path.p_window_id, ctlFindInterpreter.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlint_app_path.p_window_id, ctlint_path_menu.p_window_id, ctlFindAppPath.p_window_id, rightAlign);
}



_str _GetMonoMainFromCommandLine(_str cmd)
{
   MONO_INTERPRETER_OPTIONS Options;
   GetMonoInterpreterOptionsFromString(cmd,'',Options);
   return(Options.ApplicationName);
}

_str _GetMonoArgumentsFromCommandLine(_str cmd)
{
   MONO_INTERPRETER_OPTIONS Options;
   GetMonoInterpreterOptionsFromString(cmd,'',Options);
   return(Options.Arguments);
}

static void GetMonoInterpreterOptionsFromString(_str cmd,_str OtherOptions,MONO_INTERPRETER_OPTIONS &Options)
{
   //say("GetMonoInterpreterOptionsFromString H"__LINE__": cmd="cmd);
   Options.MonoInterpreterName = "";
   Options.ApplicationName     = "";
   Options.RuntimeVersion      = "";
   Options.Arguments           = "";
   Options.OtherOptions        = "";
   Options.VerboseOutput       = false;
   Options.ShowVersion         = false;
   Options.RunAsDesktopApp     = false;
   Options.RunAsServerApp      = false;
   Options.UseBoehmGC          = false;
   Options.UseSGenGC           = false;
   Options.Force32Bit          = false;
   Options.Force64Bit          = false;

   cur := parse_file(cmd,false);
   if (cur!=OTHER_OPTIONS_MACRO && cur!="%cp") {
      //This can happen if everything but the other field or classpath is blank
      Options.MonoInterpreterName = cur;
   }

   Options.OtherOptions=OtherOptions;
   for (;;) {
      cur=parse_file(cmd, false);
      if (cur=="") break;
      //%cp is always there, so we just skip it, and put it back in.
      if (cur=="%cp" || cur==OTHER_OPTIONS_MACRO) continue;
      ch := substr(cur,1,1);
      if (ch!="-") break;
      //say("GetMonoInterpreterOptionsFromString H"__LINE__": cur="cur);

      if (cur=="--verbose" || cur=="-v") {
         Options.VerboseOutput=true;
      } else if (cur=="--version" || cur=="-V") {
         Options.ShowVersion=true;
      } else if (cur=="--desktop") {
         Options.RunAsDesktopApp=true;
      } else if (cur=="--server") {
         Options.RunAsServerApp=true;
      } else if (cur=="--gc=boehm") {
         Options.UseBoehmGC=true;
         Options.UseSGenGC=false;
      } else if (cur=="--gc=sgen") {
         Options.UseSGenGC=true;
         Options.UseBoehmGC=false;
      } else if (cur=="--arch=32") {
         Options.Force32Bit=true;
         Options.Force64Bit=false;
      } else if (cur=="--arch=64") {
         Options.Force64Bit=true;
         Options.Force32Bit=false;
      } else if (beginsWith(cur, "--runtime=")) {
         Options.RuntimeVersion=substr(cur,11);
      } else if (beginsWith(cur, "--debugger-agent=")) {
         Options.DebuggerOptions=substr(cur,18);
      } else {
         _maybe_append(Options.OtherOptions, ' ');
         Options.OtherOptions :+= cur;
      }
   }

   //First thing after the options has to be the application name
   if (cur!=OTHER_OPTIONS_MACRO && cur!=".") {
      Options.ApplicationName = cur;
   }
   //Whatever is left is arguments
   if (cmd!=OTHER_OPTIONS_MACRO) {
      Options.Arguments = cmd;
   }
}

static void GetMonoCompilerOptionsFromString(_str cmd, _str OtherOptions, MONO_COMPILER_OPTIONS &Options, _str configName ="")
{
   //say("GetMonoCompilerOptionsFromString H"__LINE__": cmd="cmd);
   Options.CompilerName    = "";
   Options.OutputFile      = "";
   //Options.ReleaseBuild    = false;
   Options.OptimizeOutput  = false;
   Options.GenerateDebug   = false;
   Options.DebugOption     = "";
   Options.CheckedMath     = false;
   Options.CLSChecks       = false;
   Options.UnsafeMode      = false;
   Options.TargetType      = "";
   Options.WarningLevel    = "";
   Options.LanguageVersion = "";
   Options.LibPaths        = null;
   Options.RefAssemblies   = null;
   Options.RefPackages     = null;
   Options.OtherOptions    = "";

   Options.CompilerName = parse_file(cmd,false);

   Options.OtherOptions=OtherOptions;
   for (;;) {
      cur := parse_file(cmd, false);
      if (cur=="") break;
      //%cp is always there, so we just skip it, and put it back in.
      if (cur=="%cp" || cur==OTHER_OPTIONS_MACRO) continue;
      ch := substr(cur,1,1);
      if (ch!="-") break;
      //say("GetMonoCompilerOptionsFromString H"__LINE__": cur="cur);

      if (cur=="-optimize" || cur=="-optimize+") {
         Options.OptimizeOutput=true;
      } else if (cur=="-optimize-") {
         Options.OptimizeOutput=false;
      //} else if (cur=="-release" || cur=="-release+") {
      //   Options.ReleaseBuild=true;
      //} else if (cur=="-release-") {
      //   Options.ReleaseBuild=false;
      } else if (cur=="-debug" || cur=="-debug+") {
         Options.GenerateDebug=true;
      } else if (beginsWith(cur, "-debug:")) {
         Options.GenerateDebug=true;
         Options.DebugOption=strip(substr(cur, 8));
      } else if (cur=="-debug-") {
         Options.GenerateDebug=false;
      } else if (cur=="-checked" || cur=="-checked+") {
         Options.CheckedMath=true;
      } else if (cur=="-checked-") {
         Options.CheckedMath=false;
      } else if (cur=="-clscheck" || cur=="-clscheck+") {
         Options.CLSChecks=true;
      } else if (cur=="-clscheck-") {
         Options.CLSChecks=false;
      } else if (cur=="-unsafe" || cur=="-unsafe+") {
         Options.UnsafeMode=true;
      } else if (cur=="-unsafe-") {
         Options.UnsafeMode=false;
      } else if (beginsWith(cur, "-target:")) {
         Options.TargetType=strip(substr(cur, 9));
      } else if (beginsWith(cur, "-t:")) {
         Options.TargetType=strip(substr(cur, 4));
      } else if (beginsWith(cur, "-warn:")) {
         Options.WarningLevel=strip(substr(cur, 7));
      } else if (beginsWith(cur, "-langversion:")) {
         Options.LanguageVersion=strip(substr(cur,14));
      } else if (beginsWith(cur, "-out:")) {
         Options.OutputFile = strip(substr(cur,6));
         Options.OutputFile = _maybe_unquote_filename(Options.OutputFile);
      } else if (cur=="-o") {
         Options.OutputFile = parse_file(cmd, false);
         Options.OutputFile = _maybe_unquote_filename(Options.OutputFile);
      } else if (beginsWith(cur, "-o:")) {
         Options.OutputFile = strip(substr(cur,4));
         Options.OutputFile = _maybe_unquote_filename(Options.OutputFile);
      } else if (beginsWith(cur, "-lib:")) {
         libraryPath := strip(substr(cur,6));
         split(libraryPath, ',', auto a);
         foreach (libraryPath in a) {
            Options.LibPaths :+= libraryPath;
         }
      } else if (cur=="-L") {
         libraryPath := parse_file(cmd, false);
         Options.LibPaths :+= libraryPath;
      } else if (beginsWith(cur, "-L")) {
         libraryPath := strip(substr(cur,3));
         if (libraryPath == "") {
            libraryPath = parse_file(cmd, false);
         }
         Options.LibPaths :+= libraryPath;
      } else if (beginsWith(cur, "-r:")) {
         assembly := strip(substr(cur,4));
         split(assembly, ',', auto a);
         foreach (assembly in a) {
            Options.RefAssemblies :+= assembly;
         }
      } else if (cur=="-reference") {
         assembly := parse_file(cmd, false);
         split(assembly, ',', auto a);
         foreach (assembly in a) {
            Options.RefAssemblies :+= assembly;
         }
      } else if (beginsWith(cur, "-reference:")) {
         Options.RefAssemblies :+= strip(substr(cur, 12));
      } else if (beginsWith(cur, "-pkg:")) {
         libraryPath := strip(substr(cur,6));
         split(libraryPath, ',', auto a);
         foreach (libraryPath in a) {
            Options.RefPackages :+= libraryPath;
         }
      } else {
         _maybe_append(Options.OtherOptions, ' ');
         Options.OtherOptions :+= cur;
      }
   }

}


_str get_mono_from_settings_or_mono_home()
{
   mono_name := "mono":+EXTENSION_EXE;
   mono_path := def_mono_install_dir;
   if (mono_path != "") {
      _maybe_append_filesep(mono_path);
      mono_path :+= "bin" :+ FILESEP :+ mono_name;
      if (file_exists(mono_path)) {
         return _maybe_quote_filename(mono_path);
      }
   }
   mono_path = get_env("MONO_HOME");
   if (mono_path != "") {
      _maybe_append_filesep(mono_path);
      mono_path :+= "bin" :+ FILESEP :+ mono_name;
      if (file_exists(mono_path)) {
         return _maybe_quote_filename(mono_path);
      }
   }
   if (_isWindows()) {
      // look in registry on Windows
      key := 'Software\Mono';
      mono_path = _ntRegQueryValue(HKEY_LOCAL_MACHINE, key, "", "SdkInstallRoot");
      if (mono_path=="") {
         key = 'Software\WOW6432Node\Mono';
         mono_path = _ntRegGetLatestVersionValue(HKEY_LOCAL_MACHINE, key, 'Mono', "SdkInstallRoot");
      }
      if (mono_path != "") {
         _maybe_append_filesep(mono_path);
         mono_path :+= "bin" :+ FILESEP :+ mono_name;
         if (file_exists(mono_path)) {
            return _maybe_quote_filename(mono_path);
         }
      }

      //HKL\sorware\classes\com.unity3d.kharma\shell\open\command\
      //  "C:\Program Files (x86)\Unity\Editor\Unity.exe" -openurl "%1"
      key = 'SOFTWARE\classes\com.unity3d.kharma\shell\open\command';
      mono_path = _ntRegQueryValue(HKEY_LOCAL_MACHINE, key, "", null);
      if (mono_path._varformat()==VF_LSTR && mono_path != "") {
         unity_exe := parse_file(mono_path, false);
         mono_path = _strip_filename(unity_exe,'n'):+'Data\mono\bin\';
         if (file_exists(mono_path)) {
            return _maybe_quote_filename(mono_path);
         }
      }

   }
   return mono_name;
}

_command void mono_options(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }

   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   if (configName == "") configName = GetCurrentConfigName();
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   result := ctlbutton_wid.call_event('_mono_options_form',configName,ctlbutton_wid,LBUTTON_UP,'W');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   status := ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'BUILD', 'I');
   }
   if( status < 0 ) {
      _message_box('COMPILE or BUILD command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}

static void SetMonoCompilerCommand(_str CurConfig, MONO_COMPILER_OPTIONS CompilerOpts:[])
{
   curCompilerOpts := CompilerOpts:[CurConfig]; 

   // first, the compiler name
   Cmd := _maybe_quote_filename(curCompilerOpts.CompilerName);

   // boolean options
   if (curCompilerOpts.OptimizeOutput) {
      Cmd :+= " -optimize";
   }
   //if (curCompilerOpts.ReleaseBuild) {
   //   Cmd :+= " -release";
   //}
   if (curCompilerOpts.GenerateDebug) {
      Cmd :+= " -debug";
      if ( curCompilerOpts.DebugOption != "" ) {
         Cmd :+= ":";
         Cmd :+= curCompilerOpts.DebugOption;
      } else {
         compilerName := _strip_filename(curCompilerOpts.CompilerName, 'PE');
         switch (compilerName) {
         case "csc":
         case "vbc":
         case "fsharpc":
            Cmd :+= ":portable";
            break;
         }
      }
   }
   if (curCompilerOpts.CheckedMath) {
      Cmd :+= " -checked";
   }
   if (curCompilerOpts.CLSChecks) {
      Cmd :+= " -clscheck";
   }
   if (curCompilerOpts.UnsafeMode) {
      Cmd :+= " -unsafe";
   }

   // combo box options
   if (curCompilerOpts.WarningLevel != "") {
      Cmd :+= " -warn:";
      Cmd :+= curCompilerOpts.WarningLevel;
   }
   if (curCompilerOpts.LanguageVersion != "") {
      Cmd :+= " -langversion:";
      Cmd :+= curCompilerOpts.LanguageVersion;
   }

   // target type (library makes single file compile possible)
   targetArg := "";
   if (curCompilerOpts.TargetType != "") {
      targetArg = " -target:":+curCompilerOpts.TargetType;
   }

   // output file
   outArg := "";
   if (curCompilerOpts.OutputFile != "") {
      outArg = "-out:\"":+curCompilerOpts.OutputFile:+"\"";
   }

   // library paths
   foreach (auto libPath in curCompilerOpts.LibPaths) {
      Cmd :+= " -lib:";
      Cmd :+= _maybe_quote_filename(libPath);
   }

   // Packages
   foreach (auto pkgName in curCompilerOpts.RefPackages) {
      Cmd :+= " -pkg:";
      Cmd :+= pkgName;
   }

   // Reference assemblies
   foreach (auto assemblyName in curCompilerOpts.RefAssemblies) {
      Cmd :+= " ":+_maybe_quote_filename("-r:":+assemblyName);
   }

   // other options
   OtherOpts := curCompilerOpts.OtherOptions;
   if (OtherOpts != "") {
      Cmd :+= " "OTHER_OPTIONS_MACRO;
   }

   // set the compile command
   if ( _project_name != "" ) {
      _ProjectSet_TargetCmdLine(gProjectHandle,
                                _ProjectGet_TargetNode(gProjectHandle,"compile",CurConfig),
                                Cmd:+" -target:module -out:%bd%n.obj %f",null,OtherOpts);
   }

   // infer the extension from the compiler name
   ext := "%{*.cs}";
   switch (_strip_filename(curCompilerOpts.CompilerName, 'PE')) {
   case "mcs":
   case "gmcs":
   case "smcs":
   case "dmcs":
   case "csc":
      ext = "%{*.cs}";
      break;
   case "fsharpc":
      ext = "%{*.fs}";
      break;
   case "vbc":
   case "vbnc":
      ext = "%{*.vb} %{*.bas}";
      break;
   case "cl":
   case "cscc":
      ext = "%{*.cpp}";
      break;
   case "javac":
      ext = "%{*.java}";
      break;
   case "vjc":
      ext = "%{*.jsl}";
      break;
   case "booc":
      ext = "%{*.boo}";
      break;
   case "ipy":
      ext = "%{*.py}";
      break;
   // MORE OPTIONS TO HANDLE HERE
   }

   // single file project?
   if (_project_name == "") {
      ext = '%f';
   }

   // and set up the build command
   _ProjectSet_TargetCmdLine(gProjectHandle,
                             _ProjectGet_TargetNode(gProjectHandle,"build",CurConfig),
                             Cmd:+" ":+targetArg:+" ":+outArg:+" ":+ext,null,OtherOpts);

}


static void SetMonoInterpreterCommand(_str CurConfig, MONO_INTERPRETER_OPTIONS InterpreterOpts:[])
{
   curInterpreterOpts := InterpreterOpts:[CurConfig]; 

   // first, the compiler name
   Cmd := _maybe_quote_filename(curInterpreterOpts.MonoInterpreterName);

   // boolean options
   if (curInterpreterOpts.VerboseOutput) {
      Cmd :+= " --verbose";
   }
   if (curInterpreterOpts.ShowVersion) {
      Cmd :+= " --version";
   }
   if (curInterpreterOpts.RunAsDesktopApp) {
      Cmd :+= " --desktop";
   }
   if (curInterpreterOpts.RunAsServerApp) {
      Cmd :+= " --server";
   }
   if (curInterpreterOpts.UseBoehmGC) {
      Cmd :+= " --gc=boehm";
   } else if (curInterpreterOpts.UseSGenGC) {
      Cmd :+= " --gc=sgen";
   }
   if (curInterpreterOpts.Force32Bit) {
      Cmd :+= " --arch=32";
   } else if (curInterpreterOpts.Force64Bit) {
      Cmd :+= " --arch=64";
   }

   // runtime version
   if (curInterpreterOpts.RuntimeVersion != "") {
      Cmd :+= " --runtime=";
      Cmd :+= curInterpreterOpts.RuntimeVersion;
   }

   // other options
   OtherOpts := curInterpreterOpts.OtherOptions;
   if (OtherOpts != "") {
      Cmd :+= " "OTHER_OPTIONS_MACRO;
   }


   // Application Path
   RunArgs := "\"":+curInterpreterOpts.ApplicationName:+"\"";
   
   // Application Arguments
   if (curInterpreterOpts.Arguments != "") {
      RunArgs :+= " ";
      RunArgs :+= curInterpreterOpts.Arguments;
   }

   // set the execute command
   _ProjectSet_TargetCmdLine(gProjectHandle,
                             _ProjectGet_TargetNode(gProjectHandle,"execute",CurConfig),
                             Cmd:+" ":+RunArgs,null,OtherOpts);

   // add in the debugger arguments
   if (curInterpreterOpts.DebuggerOptions == null || curInterpreterOpts.DebuggerOptions == "") {
      curInterpreterOpts.DebuggerOptions = "transport=dt_socket,server=y,suspend=y,address=localhost:8000";
   }
   Cmd :+= " --debugger-agent=\"" :+ curInterpreterOpts.DebuggerOptions :+ "\"";

   // set the debug command
   _ProjectSet_TargetCmdLine(gProjectHandle,
                             _ProjectGet_TargetNode(gProjectHandle,"debug",CurConfig),
                             Cmd:+" ":+RunArgs,null,OtherOpts);
}

void ctlCurConfig.on_change(int reason)
{
   if (!p_active_form.p_visible && reason==CHANGE_OTHER) {
      // We get 2 on_change events when before the dialog is visible.  One
      // happens when the textbox gets filled in(reason==CHANGE_OTHER), and the
      // other one we call ourselves.
      //
      // Since the one we call is later on(CHANGE_CLINE). Skip the first one
      return;
   }
   MONO_CHANGING_CONFIGURATION(1);

   SaveMonoCheckBoxOptionsAll(MONO_LAST_CONFIG());

   style := PSCH_AUTO2STATE;
   curConfigName := ctlCurConfig.p_text; 
   if (curConfigName == PROJ_ALL_CONFIGS) {
      style = PSCH_AUTO3STATEB;
   }
   p_active_form._set_all_check_box_styles(style);

   MONO_COMPILER_OPTIONS allCompilerOptions:[] = MONO_COMPILER_INFO();
   MONO_INTERPRETER_OPTIONS allInterpreterOptions:[] = MONO_INTERPRETER_INFO();
   if (allCompilerOptions._varformat()!=VF_HASHTAB) {
      return;
   }

   MONO_COMPILER_OPTIONS    curCompilerOptions=null;
   MONO_INTERPRETER_OPTIONS curInterpreterOptions=null;

   if (curConfigName == PROJ_ALL_CONFIGS) {
      allCompilerOptions._deleteel(PROJ_ALL_CONFIGS);
      allInterpreterOptions._deleteel(PROJ_ALL_CONFIGS);
      curCompilerOptions    = _get_matching_struct_values(allCompilerOptions);
      curInterpreterOptions = _get_matching_struct_values(allInterpreterOptions);
   }else{
      curCompilerOptions = allCompilerOptions:[curConfigName];
      curInterpreterOptions = allInterpreterOptions:[curConfigName];
   }

   SetMonoCompilerValues(curCompilerOptions);
   SetMonoAssemblyValues(curCompilerOptions);
   SetMonoInterpreterValues(curInterpreterOptions);

   MONO_LAST_CONFIG(curConfigName);
   MONO_CHANGING_CONFIGURATION(0);
}

static void SetMonoCompilerValues(MONO_COMPILER_OPTIONS compilerOptions)
{
   ctlmonocc_compiler_name.p_text = compilerOptions.CompilerName;
   ctlmonocc_output_file.p_text   = compilerOptions.OutputFile;
   ctlmonocc_optimize.p_value     = (int)compilerOptions.OptimizeOutput;
   //ctlmonocc_release.p_value      = (int)compilerOptions.ReleaseBuild;
   ctlmonocc_debug.p_value        = (int)compilerOptions.GenerateDebug;
   ctlmonocc_checked.p_value      = (int)compilerOptions.CheckedMath;
   ctlmonocc_clscheck.p_value     = (int)compilerOptions.CLSChecks;
   ctlmonocc_unsafe.p_value       = (int)compilerOptions.UnsafeMode;
   ctlmonocc_target_type._cbset_text(compilerOptions.TargetType);
   ctlmonocc_warning_level._cbset_text(compilerOptions.WarningLevel);
   ctlmonocc_language_version._cbset_text(compilerOptions.LanguageVersion);
   ctlmonocc_other_options.p_text = compilerOptions.OtherOptions;
}

static void SetMonoAssemblyValues(MONO_COMPILER_OPTIONS compilerOptions)
{
   path := "";
   foreach (path in compilerOptions.LibPaths) {
      ctlcp_pathlist._lbadd_item("-lib:":+path);
   }
   foreach (path in compilerOptions.RefPackages) {
      ctlcp_pathlist._lbadd_item("-pkg:":+path);
   }
   foreach (path in compilerOptions.RefAssemblies) {
      ctlcp_pathlist._lbadd_item(path);
   }
   _lbtop();
}

static void SetMonoInterpreterValues(MONO_INTERPRETER_OPTIONS interpreterOptions)
{
   ctlint_path.p_text            = interpreterOptions.MonoInterpreterName;
   ctlint_app_path.p_text        = interpreterOptions.ApplicationName;
   ctlint_runtime_version.p_text = interpreterOptions.RuntimeVersion;
   ctlint_arguments.p_text       = interpreterOptions.Arguments;
   ctlint_verbose.p_value        = (int)interpreterOptions.VerboseOutput;
   ctlint_version.p_value        = (int)interpreterOptions.ShowVersion;
   ctlint_desktop.p_value        = (int)interpreterOptions.RunAsDesktopApp;
   ctlint_server.p_value         = (int)interpreterOptions.RunAsServerApp;
   ctlint_gcboehm.p_value        = (int)interpreterOptions.UseBoehmGC;
   ctlint_gcsgen.p_value         = (int)interpreterOptions.UseSGenGC;
   ctlint_arch32.p_value         = (int)interpreterOptions.Force32Bit;
   ctlint_arch64.p_value         = (int)interpreterOptions.Force64Bit;
   ctlint_other.p_text           = interpreterOptions.OtherOptions;
}

// boehm and sgen GC are mutually exclusive
void ctlint_gcboehm.lbutton_up()
{
   if (ctlint_gcboehm.p_value==1 && ctlint_gcsgen.p_value==1) {
      ctlint_gcsgen.p_value=0;
   }
}
void ctlint_gcsgen.lbutton_up()
{
   if (ctlint_gcboehm.p_value==1 && ctlint_gcsgen.p_value==1) {
      ctlint_gcboehm.p_value=0;
   }
}

// 32-bit and 64-bit are mutually exclusive
void ctlint_arch32.lbutton_up()
{
   if (ctlint_arch32.p_value==1 && ctlint_arch64.p_value==1) {
      ctlint_arch64.p_value=0;
   }
}
void ctlint_arch64.lbutton_up()
{
   if (ctlint_arch32.p_value==1 && ctlint_arch64.p_value==1) {
      ctlint_arch32.p_value=0;
   }
}

static void SaveMonoCheckBoxOptionsAll(_str configName)
{
   if (configName=="") return;

   MONO_COMPILER_OPTIONS    allCompilerOptions:[]    = MONO_COMPILER_INFO();
   MONO_INTERPRETER_OPTIONS allInterpreterOptions:[] = MONO_INTERPRETER_INFO();

   SaveMonoCheckBoxOptionsCompiler(configName, allCompilerOptions);

   SaveMonoCheckBoxOptionsInterpreter(configName, allInterpreterOptions);

   MONO_COMPILER_INFO(allCompilerOptions);
   MONO_INTERPRETER_INFO(allInterpreterOptions);
}

static void SaveMonoCheckBoxOptionsCompiler(_str configName, MONO_COMPILER_OPTIONS (&allOptions):[])
{
   if (configName==PROJ_ALL_CONFIGS) {
      foreach (configName => auto interpreterOpts in allOptions) {
         if (configName==PROJ_ALL_CONFIGS) continue;

         if (ctlmonocc_optimize.p_value != 2) {
            allOptions:[configName].OptimizeOutput = (ctlmonocc_optimize.p_value != 0);
         }
         /*if (ctlmonocc_release.p_value != 2) {
            allOptions:[configName].ReleaseBuild = (ctlmonocc_release.p_value != 0);
         } */
         if (ctlmonocc_debug.p_value != 2) {
            allOptions:[configName].GenerateDebug = (ctlmonocc_debug.p_value != 0);
         }
         if (ctlmonocc_checked.p_value != 2) {
            allOptions:[configName].CheckedMath = (ctlmonocc_checked.p_value != 0);
         }
         if (ctlmonocc_clscheck.p_value != 2) {
            allOptions:[configName].CLSChecks = (ctlmonocc_clscheck.p_value != 0);
         }
         if (ctlmonocc_unsafe.p_value != 2) {
            allOptions:[configName].UnsafeMode = (ctlmonocc_unsafe.p_value != 0);
         }
      }
   } else {
      allOptions:[configName].OptimizeOutput = (ctlmonocc_optimize.p_value != 0);
      //allOptions:[configName].ReleaseBuild = (ctlmonocc_release.p_value != 0);
      allOptions:[configName].GenerateDebug = (ctlmonocc_debug.p_value != 0);
      allOptions:[configName].CheckedMath = (ctlmonocc_checked.p_value != 0);
      allOptions:[configName].CLSChecks = (ctlmonocc_clscheck.p_value != 0);
      allOptions:[configName].UnsafeMode = (ctlmonocc_unsafe.p_value != 0);
   }
}

static void SaveMonoCheckBoxOptionsInterpreter(_str configName, MONO_INTERPRETER_OPTIONS (&allOptions):[])
{
   if (configName==PROJ_ALL_CONFIGS) {
      foreach (configName => auto interpreterOpts in allOptions) {
         if (configName==PROJ_ALL_CONFIGS) continue;

         if (ctlint_verbose.p_value != 2) {
            allOptions:[configName].VerboseOutput = (ctlint_verbose.p_value != 0);
         }
         if (ctlint_version.p_value != 2) {
            allOptions:[configName].ShowVersion = (ctlint_version.p_value != 0);
         }
         if (ctlint_desktop.p_value != 2) {
            allOptions:[configName].RunAsDesktopApp = (ctlint_desktop.p_value != 0);
         }
         if (ctlint_server.p_value != 2) {
            allOptions:[configName].RunAsServerApp = (ctlint_server.p_value != 0);
         }
         if (ctlint_gcboehm.p_value != 2) {
            allOptions:[configName].UseBoehmGC = (ctlint_gcboehm.p_value != 0);
         }
         if (ctlint_gcsgen.p_value != 2) {
            allOptions:[configName].UseSGenGC = (ctlint_gcsgen.p_value != 0);
         }
         if (ctlint_arch32.p_value != 2) {
            allOptions:[configName].Force32Bit = (ctlint_arch32.p_value != 0);
         }
         if (ctlint_arch64.p_value != 2) {
            allOptions:[configName].Force64Bit = (ctlint_arch64.p_value != 0);
         }
      }
   } else {
      allOptions:[configName].VerboseOutput = (ctlint_verbose.p_value != 0);
      allOptions:[configName].ShowVersion = (ctlint_version.p_value != 0);
      allOptions:[configName].RunAsDesktopApp = (ctlint_desktop.p_value != 0);
      allOptions:[configName].RunAsServerApp = (ctlint_server.p_value != 0);
      allOptions:[configName].UseBoehmGC = (ctlint_gcboehm.p_value != 0);
      allOptions:[configName].UseSGenGC = (ctlint_gcsgen.p_value != 0);
      allOptions:[configName].Force32Bit = (ctlint_arch32.p_value != 0);
      allOptions:[configName].Force64Bit = (ctlint_arch64.p_value != 0);
   }
}

void ctlmonocc_compiler_name.on_change()
{
   if (MONO_CHANGING_CONFIGURATION()==1) return;
   MONO_COMPILER_OPTIONS allCompilerOpts:[] = MONO_COMPILER_INFO();

   text := p_text;
   if (p_name == "ctlmonocc_compiler_name") {
      if (text=="") text="mcs";
   }

   curConfig := ctlCurConfig.p_text;
   foreach (auto k => auto v in allCompilerOpts) {
      if (curConfig == PROJ_ALL_CONFIGS) {
         if (k==PROJ_ALL_CONFIGS) continue;
      } else {
         if (k!=curConfig) continue;
      }
      switch (p_name) {
      case "ctlmonocc_compiler_name":
         allCompilerOpts:[k].CompilerName = text;
         break;
      case "ctlmonocc_output_file":
         allCompilerOpts:[k].OutputFile = text;
         break;
      case "ctlmonocc_other_options":
         allCompilerOpts:[k].OtherOptions = text;
         break;
      case "ctlmonocc_language_version":
         allCompilerOpts:[k].LanguageVersion = text;
         break;
      case "ctlmonocc_target_type":
         allCompilerOpts:[k].TargetType = text;
         break;
      case "ctlmonocc_warning_level":
         allCompilerOpts:[k].WarningLevel = text;
         break;
      }
   }

   MONO_COMPILER_INFO(allCompilerOpts);
}

void ctlint_path.on_change()
{
   if (MONO_CHANGING_CONFIGURATION()==1) return;
   MONO_INTERPRETER_OPTIONS allInterpreterOpts:[] = MONO_INTERPRETER_INFO();

   text := p_text;
   if (p_name == "ctlint_path") {
      if (text=="") text="mono";
   }
   if (p_name == "ctlint_app_path") {
      if (text=="") text="%o":+EXTENSION_EXE;
   }

   curConfig := ctlCurConfig.p_text;
   foreach (auto k => auto v in allInterpreterOpts) {
      if (curConfig == PROJ_ALL_CONFIGS) {
         if (k==PROJ_ALL_CONFIGS) continue;
      } else {
         if (k!=curConfig) continue;
      }
      switch (p_name) {
      case "ctlint_path":
         allInterpreterOpts:[k].MonoInterpreterName = text;
         break;
      case "ctlint_app_path":
         allInterpreterOpts:[k].ApplicationName = text;
         break;
      case "ctlint_other":
         allInterpreterOpts:[k].OtherOptions = text;
         break;
      case "ctlint_runtime_version":
         allInterpreterOpts:[k].RuntimeVersion = text;
         break;
      case "ctlint_arguments":
         allInterpreterOpts:[k].Arguments = text;
         break;
      }
   }

   MONO_INTERPRETER_INFO(allInterpreterOpts);
}

void ctlBrowseMonoInstallDir.lbutton_up(){
   wid := p_window_id;
   init_dir := wid.p_prev.p_text;
   if (init_dir != "" && !isdirectory(init_dir)) {
      init_dir = "";
   }
   if (init_dir == "") {
      if (_isWindows()) {
         init_dir = 'C:\Program Files (x86)\Mono\';
         if (!isdirectory(init_dir)) init_dir = 'C:\Program Files\Mono\';
         if (!isdirectory(init_dir)) init_dir = 'C:\Program Files\Unity\';
      }
      if (_isMac()) {
         init_dir = "/Library/Frameworks/Mono.framework/";
      }
      if (_isUnix()) {
         if (!isdirectory(init_dir)) init_dir = "/usr/local/mono/";
         if (!isdirectory(init_dir)) init_dir = "/usr/mono/";
         if (!isdirectory(init_dir)) init_dir = "/opt/mono/";
         if (!isdirectory(init_dir)) init_dir = "/usr/local/unity/";
         if (!isdirectory(init_dir)) init_dir = "/usr/unity/";
         if (!isdirectory(init_dir)) init_dir = "/opt/unity/";
         if (!isdirectory(init_dir)) init_dir = "/usr/local/";
      }
   }
   if (init_dir!= "" && !isdirectory(init_dir)) {
      init_dir= "";
   }
   result := _ChooseDirDialog("", init_dir);
   if( result=='' ) {
      return;
   }
   wid.p_prev.p_text=result;
   wid.p_prev.end_line();
   wid.p_prev._set_focus();
   return;
}

void ctlcp_pathlist.on_change(int reason)
{
   EnableAssemblyPathButtons();
}

static void add_path(_str path,bool SelectNewLine=true)
{
   save_pos(auto p);
   _lbtop();
   typeless status=_lbsearch(path,_fpos_case);
   if (!status) {
      _lbselect_line();
      return;
   }
   restore_pos(p);
   _lbadd_item(path);
   if (SelectNewLine) {
      _lbselect_line();
   }
}
void ctlcp_add_path.lbutton_up()
{
   result := _ChooseDirDialog('','','',CDN_PATH_MUST_EXIST); 
   if( result == "" ) {
      return;
   }
   options := "";
   path := strip_options(result,options,true);
   path = strip(path,'B','"');
   _maybe_append_filesep(path);
   ctlcp_pathlist._lbdeselect_all();
   ctlcp_pathlist.add_path("-lib:":+path);
   UpdateAssemblyPathsFromListBox();
   EnableAssemblyPathButtons();
}

void ctlcp_add_assembly.lbutton_up()
{
   initial_dir := def_mono_install_dir;
   if (initial_dir == "") {
      initial_dir = get_mono_from_settings_or_mono_home();
      if ( initial_dir != "" ) {
         initial_dir = _strip_filename(initial_dir, 'N');
         _maybe_strip_filesep(initial_dir);
         initial_dir = _strip_filename(initial_dir, 'N');
      }
   }
   if (initial_dir != "") {
      _maybe_append_filesep(initial_dir);
      if (!isdirectory(initial_dir)) {
         initial_dir = "";
      } else {
         if (isdirectory(initial_dir:+"lib":+FILESEP)) {
            initial_dir :+= "lib":+FILESEP;
         }
         if (isdirectory(initial_dir:+"mono":+FILESEP)) {
            initial_dir :+= "mono":+FILESEP;
         }
      }
   }
   abs_initial_dir := "";
   if (initial_dir != "") {
      abs_initial_dir = absolute(initial_dir, null, true);
   }

   typeless result=_OpenDialog('-new -modal',
        'Add .NET Assembly',
        '',             // Initial wildcards
        '.NET Assembly files(*.dll),'def_file_types,
        OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
        '*.dll',        // Default extension
        '',             // Initial filename
        initial_dir     // Initial directory
        );
   if (result=='') {
      return;
   }

   ctlcp_pathlist._lbdeselect_all();
   for (;;) {
      cur := parse_file(result,false);
      if (cur=='') break;
      // anything added under the installation 
      abs_cur := absolute(cur, null, true);
      cur = relative(abs_cur, abs_initial_dir, false);
      if (cur != abs_cur) cur = _strip_filename(cur, 'P');
      ctlcp_pathlist.add_path(cur,false);
   }

   ctlcp_pathlist._lbselect_line();
   EnableAssemblyPathButtons();
   UpdateAssemblyPathsFromListBox();
}

void ctlcp_add_package.lbutton_up()
{
   status := textBoxDialog("Enter .NET Package Name",    // form caption
                           0,                            // flags
                           0,                            // text box width
                           "",                           // help item
                           "",                           // button/caption list
                           "",                           // retrieve name
                           "Package name(s):");             // prompt
   if (status < 0) {
      return;
   }
   foreach (auto packageName in _param1) {
      ctlcp_pathlist.add_path("-pkg:":+packageName);
   }

   ctlcp_pathlist._lbdeselect_all();
   EnableAssemblyPathButtons();
   UpdateAssemblyPathsFromListBox();
}

void ctlcp_pathlist.'C-A'()
{
   _lbselect_all();
}

void ctlcp_pathlist.del()
{
   ctlcp_delete.call_event(ctlcp_delete,LBUTTON_UP);
}

void ctlcp_delete.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   save_pos(auto p);
   top();up();
   bool ff;
   for (ff=true;;ff=false) {
      typeless status=_lbfind_selected(ff);
      if (status) break;
      _lbdelete_item();_lbup();
   }
   restore_pos(p);
   _lbselect_line();
   p_window_id=wid;
   UpdateAssemblyPathsFromListBox();
   EnableAssemblyPathButtons();
}

void ctlcp_edit.lbutton_up()
{
   _str CurText=ctlcp_pathlist._lbget_text();
   typeless result=show('-modal _textbox_form',
               'Edit Path',
               0,
               '',           //tb width
               '',           //Help item
               '',           //Buttons and captions
               'editpath',      //retrieve
               'Edit Path:'CurText);//prompts
   if (result=='') {
      return;
   }
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   if (_last_char(_param1)!=FILESEP &&
       !_file_eq(_get_extension(_param1),'jar') &&
       !_file_eq(_get_extension(_param1),'zip') &&
       substr(_param1,1,2)!='%('
      ) {
      _param1 :+= FILESEP;
   }
   if (_param1=='') {
      _lbdelete_item();
   }else{
      _lbset_item(_param1);
   }
   //_lbselect_line();
   p_window_id=wid;
   UpdateAssemblyPathsFromListBox();
}

void ctlcp_up.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _str Text=_lbget_text();

   orig_linenum := p_line;
   _lbdelete_item();

   if (p_line==orig_linenum) {
      _lbup();
   }
   _lbup();//Be careful of order since the above compares line number then does an up

   _lbadd_item(Text);
   _lbselect_line();
   p_window_id=wid;
   UpdateAssemblyPathsFromListBox();
   EnableAssemblyPathButtons();
}

void ctlcp_down.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _str Text=_lbget_text();

   _lbdelete_item();

   _lbadd_item(Text);
   _lbselect_line();
   p_window_id=wid;
   UpdateAssemblyPathsFromListBox();
   EnableAssemblyPathButtons();
}

static void UpdateAssemblyPathsFromListBox()
{
   _str newLibPaths[];
   _str newPackages[];
   _str newAssemblies[];

   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   save_pos(auto p);
   _lbtop();
   _lbup();
   while (!_lbdown()) {
      item := _lbget_text();
      if (beginsWith(item, "-lib:")) {
         newLibPaths :+= strip(substr(item, 6));
      } else if (beginsWith(item,  "-pkg:")) {
         newPackages :+= strip(substr(item, 6));
      } else {
         newAssemblies :+= item;
      }
   }
   restore_pos(p);

   MONO_COMPILER_OPTIONS allCompilerOpts:[] = MONO_COMPILER_INFO();
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      foreach (auto k => . in allCompilerOpts) {
         if (k == PROJ_ALL_CONFIGS) continue;
         allCompilerOpts:[k].LibPaths = newLibPaths;
         allCompilerOpts:[k].RefPackages = newPackages;
         allCompilerOpts:[k].RefAssemblies = newAssemblies;
      }
   }else{
      k := ctlCurConfig.p_text;
      allCompilerOpts:[k].LibPaths = newLibPaths;
      allCompilerOpts:[k].RefPackages = newPackages;
      allCompilerOpts:[k].RefAssemblies = newAssemblies;
   }

   MONO_COMPILER_INFO(allCompilerOpts);
   p_window_id=wid;
}


void ctlFindCompiler.lbutton_up()
{
   // set up the initial directory to be the Mono bin directory
   wid := p_window_id;
   initial_directory := "";
   program := wid.p_prev.p_text;
   if (program == "") program = "mcs";
   filename := path_search(program,"",'P');
   if (filename == "") {
      status := set_mono_environment(true);
      if (!status) {
         filename = path_search(program,"",'P');
      }
   }
   if (filename == "") {
      filename = path_search("mono","",'P');
   }
   if (filename != "") {
      filename = absolute(filename, null, true);
      initial_directory = _strip_filename(filename,'N');
      _maybe_append_filesep(initial_directory);
   }

   // propmt for the location of the compiler
   result := _OpenDialog("-modal",
                         "Choose Application",
                         "",
                         def_debug_exe_extensions, // File Type List
                         OFN_FILEMUSTEXIST,     // Flags
                         "",
                         "",
                         initial_directory
                         );

   // remove quotes
   result = _maybe_unquote_filename(result);
   if (result == "") {
      return;
   }

   // make the result relative to the bin directory
   if (initial_directory != "") {
      result = absolute(result, "", true);
      result = relative(result, initial_directory, false);
   }

   // that's all
   p_window_id=wid.p_prev;
   p_text= result;
   end_line();
   _set_focus();
   return;
}

