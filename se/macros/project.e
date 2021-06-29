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
#include 'slick.sh'
#include 'tagsdb.sh'
#include 'project.sh'
#include "codetemplate.sh"
#include "scc.sh"
#include "xml.sh"
#include "treeview.sh"
#import "actionscript.e"
#import "backtag.e"
#import "bgsearch.e"
#import "cjava.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "controls.e"
#import "ctadditem.e"
#import "cvsutil.e"
#import "debug.e"
#import "dir.e"
#import "error.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "gnucopts.e"
#import "ini.e"
#import "javacompilergui.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "monoopts.e"
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "projmake.e"
#import "projutil.e"
#import "projgui.e"
#import "ptoolbar.e"
#import "recmacro.e"
#import "refactor.e"
#import "refactorgui.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "svcautodetect.e"
#import "tagform.e"
#import "taggui.e"
#import "tagrefs.e"
#import "tags.e"
#import "tbcmds.e"
#import "toast.e"
#import "treeview.e"
#import "vc.e"
#import "xmlcfg.e"
#import "xmldoc.e"
#import "wizard.e"
#import "wkspace.e"
#import "util.e"
#import "xcode.e"
#import "se/vc/IVersionControl.e"
#import "fileproject.e"
#import "help.e"
#import "menu.e"
#endregion

_str VSCFGFILE_PRJPACKS() {
   return (_isUnix()? "uprjpack.slk" : "prjpacks.slk");
}

// Track add, remove, and refresh files instead of just checking modify
static bool gFileListModified;

static _str gDialog;
static _str gSetActiveConfigTo;

 static _str gProjectName;
 static int gProjectHandle;
 static bool gdoSaveIfNecessary;
 static bool gMakeCopyFirst;
 static bool gIsProjectTemplate;
 static _str gConfigName;
 static _str gConfigList[];
 static bool gChangingConfiguration;
 static _str gAssociatedFile;
 static _str gAssociatedFileType;
 static _str gInitialTargetName;
 static _str gInitialBuildSystem;
 static _str gInitialBuildMakeFile;
 static bool gLeaveFileTabEnabled;
 static _str gInitialTagFileOption;

 static _str gTagsComboList[]={
   VPJ_TAGGINGOPTION_WORKSPACE,
   VPJ_TAGGINGOPTION_PROJECT,
    VPJ_TAGGINGOPTION_PROJECT_NOREFS,
   VPJ_TAGGINGOPTION_NONE,
 };

 static _str gTagsComboTextList[]={
    "Tag files using workspace tag file",
    "Tag files with project-specific tag file",
    "Tag files with project-specific tag file, without references",
    "Do not tag files",
 };

 static _str gSaveComboList[]={
   VPJ_SAVEOPTION_SAVENONE,
   VPJ_SAVEOPTION_SAVECURRENT,
   VPJ_SAVEOPTION_SAVEALL,
   VPJ_SAVEOPTION_SAVEMODIFIED,
   VPJ_SAVEOPTION_SAVEWORKSPACEFILES,
 };

 static _str gSaveComboTextList[]={
    "Save none",
    "Save current file",
    "Save all files",
    "List modified files",
    "Save workspace files",
 };

 static _str gShowComboList[]={
    VPJ_SHOWONMENU_ALWAYS,
    VPJ_SHOWONMENU_HIDEIFNOCMDLINE,
    VPJ_SHOWONMENU_NEVER,
 };

 static _str gShowComboTextList[]={
    "Always show on menu",
    "Hide if no command line",
    "Never show on menu",
 };

static const PROJECTTREEADJUSTCOLUMNWIDTH= 2600;

static const JAVA_OPTS_DLG_DEF= "_java_options_form Compiler";
static const GNUC_OPTS_DLG_DEF= "_gnuc_options_form Compile";
static const VCPP_OPTS_DLG_DEF= "_vcpp_options_form Compile";
static const JAVA_OPTS_DLG_DBG= "_java_options_form Debugger";
static const GNUC_OPTS_DLG_DBG= "_gnuc_options_form Debugger";
static const VCPP_OPTS_DLG_DBG= "_vcpp_options_form Debugger";

static int gIsExtensionProject;
static bool gUpdateTags;
static bool gProjectFilesNotNeeded;
static bool ignore_config_change;

// If 1, ignore on_change events to _openfile_list:
static int gProjectIgnoreOnChange= 0;

// default to not showing files in project in open dialog
ShowProjectFilesInOpenDialog def_show_prjfiles_in_open_dlg=PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG;

int def_refilter_wildcards=0;

/**
 * This setting controls the way project open commands are ran 
 * when a workspace is opened. 
 * <p> 
 * The default value of "false" specifies that only the active 
 * project and the projects that it depends have their open 
 * commands ran. 
 * <p>When set to 'true', the open commands are ran for all the 
 * projects in the workspace. 
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_workspace_open_runs_all_macros=false;

static PROJECT_CONFIG_INFO gAllConfigsInfo;

_control _prjref_files;
_control ctlUserIncludesList;
_control ctlToolTree;

static int gOrigProjectFileList;

static const MESSAGE_ALLCONFIG_SETTING_MISMATCH=   "Select a configuration to view this option";
static const MESSAGE_ALLCONFIG_TOOLS_MISMATCH=     "Select a configuration to view this command";
static const MESSAGE_ALLCONFIG_INCLUDES_MISMATCH=  "Select a configuration to edit includes";
static const MESSAGE_PRESS_OPTIONS_BUTTON= "<- Press Options button to view settings for this command";
static _str gSpecialToolMessage:[]=
{
#if 0
   "javamake"=>"Compiles all out-of-date files using 'Compile' settings",
   "javarebuild"=>"Recompiles all files using 'Compile' settings",
   "javaviewdoc"=>"Updates javadoc and views javadoc for current file",
   "javamakedoc"=>"Updates javadoc for all files using 'Javadoc' settings",
   "javamakejar"=>"Updates Jar file using Jar program with all class files",
#endif
   "javaoptions"=>"Displays dialog for setting options for Java tools",
   "gnucoptions"=>"Displays dialog for setting options for GNU C/C++ tools",
   "clangoptions"=>"Displays dialog for setting options for Clang C/C++ tools",
   "vcppoptions"=>"Displays dialog for setting options for Visual C++ Toolkit",
   "phpoptions"=>"Displays dialog for setting options for PHP tools",
   "pythonoptions"=>"Displays dialog for setting options for Python tools",
   "rubyoptions"=>"Displays dialog for setting options for Ruby tools",
   "googlegooptions"=>"Displays dialog for setting options for Google Go tools"
};
void _project_refresh()
{
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   //readAndParseAllExtensionProjects();

   // Initialize the project tool table:
   // We need this tool table initialized and consistent at all
   // times to update the menubar's project menu.
   if (_project_name!="") {
      //readAndParseProjectToolList_ForAllConfigs();

      //readAndParseProjectToolList(_project_name,"COMPILER."GetCurrentConfigName(),0,junk,0,junk2,gProjectInfo.ProjectSettings:[GetCurrentConfigName()].ToolInfo,gProjectInfo.ProjectSettings:[GetCurrentConfigName()].DirInfo);

      //Just in case tag files for project were modified
      _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      // Just in case there is an associated makefile
      _MaybeRetagWorkspace(1,false);
      // Just in case project files were modified
      toolbarUpdateFilterList(_project_name);
   } else if (_workspace_filename!='') {
      toolbarUpdateFilterList(_project_name);
   }
}

int _OnUpdate_project_edit(CMDUI &cmdui,int target_wid,_str command)
{
   if (_project_name=='') {
      if (_no_child_windows() || !target_wid || !target_wid._isEditorCtl()) {
         return(MF_GRAYED);
      }
      if (_fileProjectHandle() < 0) {
         return(MF_GRAYED);
      }
      //return(MF_ENABLED);
   }

   // if the workspace has multiple projects, show the current project on the menu
   isProjectTBForm := (target_wid && target_wid.p_active_form && target_wid.p_active_form.p_name != "");
   if (!isProjectTBForm && cmdui.menu_handle) {
      num_projects := 1;
      if (_workspace_filename != "") {
         _GetWorkspaceFiles(_workspace_filename, auto project_names);
         num_projects = project_names._length();
      }
      _menu_get_state(cmdui.menu_handle,command,auto flags,"m",auto caption);
      parse caption with caption "\t" auto keys;
      parse caption with caption "(" .;
      if (_project_name != "" && num_projects > 1) {
         caption = strip(caption) :+ " (" :+ _strip_filename(_project_name, 'P') :+ ")";
      }
      _menu_set_state(cmdui.menu_handle,
                      cmdui.menu_pos,
                      MF_ENABLED,
                      "p",
                      caption :+ "\t" :+ keys);
   }

   return(MF_ENABLED);
}
int _OnUpdate_project_edit_config(CMDUI &cmdui,int target_wid,_str command)
{
   configName := GetCurrentConfigName();
   if (configName == "") {
      return(MF_GRAYED);
   }
   return _OnUpdate_project_edit(cmdui,target_wid,command);
}
int _OnUpdate_project_edit_project_with_file(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_project_edit(cmdui,target_wid,command);
}

static void project_edit2(_str activetab="",
                          _str ProjectFilename=_project_name,
                          bool showCurrentConfig=false)
{
   //_macro_delete_line();

   // No global project name==> No project opened!
   if (ProjectFilename=='') {
      handle:=_fileProjectSetCurrentOrCreate(auto editorctl_wid,auto config);
      if (handle<0) {
         return;
      }
      displayName := _strip_filename(editorctl_wid.p_buf_name,'P')' - 'editorctl_wid.p_buf_name;
      show('-mdi -modal -xy _project_form',displayName,handle);
      return;
   }
   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   typeless result=show('-mdi -modal -xy _project_form',
                        ProjectFilename,
                        _ProjectHandle(ProjectFilename),
                        activetab,
                        true,       // MakeCopyFirst
                        true,       // doSaveIfNecessary
                        false,      // IsProjectPackage
                        showCurrentConfig
                        );
   mou_hour_glass(false);
}

/**
 * Set whether to ignore file processing for project properties.
 * Call this function before invoking the Project Properties
 * dialog. This function allows functions that invoke Build tool
 * options dialogs (e.g. javaoptions, gnucoptions) to be defined
 * in separate modules.
 *
 * @param value  Set to 1 (true) to skip project files
 *               processing. Set to 0 (false) to process project
 *               files. Set to -1 to retreive current value.
 *               Defaults to -1.
 *
 * @return Previous setting.
 */
bool projectFilesNotNeeded(int value=-1)
{
   old_value := gProjectFilesNotNeeded;
   if( value != -1 ) {
      gProjectFilesNotNeeded = ( value != 0 );
   }
   return old_value;
}

/**
 * Allows you to add files to project, change project commands, working
 * directory and other project properties.  Displays <b>Project Properties
 * dialog box</b>.
 *
 * @param activetab Index of tab to show on the Project Properties dialog.  May also
 *                  contain the absolute path to the project to open.
 * @param showCurrentConfig  Initialize project properties for
 *                           the current build configuration.
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
 * @see project_edit_config
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
 */
_command void project_edit(_str activetab="", bool showCurrentConfig=false) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   ProjectFilename := "";
   gProjectFilesNotNeeded=false;
   parse activetab with activetab ProjectFilename;

   // if no project name was specified and this was triggered from
   // the project toolbar, infer the project name from the tree
   if (ProjectFilename == "" && p_name==PROJECT_TOOLBAR_NAME) {
      ProjectFilename=_projecttbTreeGetCurProjectName(-1,true);
      olddir := getcwd();
      chdir(_strip_filename(ProjectFilename,'N'),1);
      project_edit2(activetab,ProjectFilename,showCurrentConfig);
      chdir(olddir,1);
      return;
   }
   if (file_exists(ProjectFilename)) {
      project_edit2(activetab,ProjectFilename,showCurrentConfig);
   } else {
      project_edit2(activetab,_project_name,showCurrentConfig);
   }
}

/**
 * Allows you to add files to project, change project commands, working
 * directory and other project properties.  Displays <b>Project Properties
 * dialog box</b> with the current active configuration pre-selected.
 *
 * @param activetab Index of tab to show on the Project Properties dialog.  May also
 *                  contain the absolute path to the project to open.
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
 */
_command void project_edit_config(_str activetab="") name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   project_edit(activetab,true);
}
/**
 * Allows you to add files to project, change project commands, working
 * directory and other project properties.  Displays <b>Project Properties
 * dialog box</b> with for the selected project which contains the current file. 
 * This command will prompt if multiple projects contain the current file.
 * It will pop up a warning if the current file is not in the workspace.
 *
 * @param activetab Index of tab to show on the Project Properties dialog.  May also
 *                  contain the absolute path to the project to open.
 * @param showCurrentConfig  Initialize project properties for
 *                           the current build configuration.
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
 */
_command void project_edit_project_with_file(_str activetab="", bool showCurrentConfig=false) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_EDITORCTL)
{
   buffer_name := _mdi.p_child.p_buf_name;
   project_list := _WorkspaceFindAllProjectsWithFile(buffer_name);
   if ( project_list._length() < 1 ) {
      _message_box("No project with file " :+ buffer_name);
      return;
   }
   if ( project_list._length() == 1 ) {
      olddir := getcwd();
      chdir(_strip_filename( project_list[0],'N'),1);
      project_edit2(activetab, project_list[0], false);
      chdir(olddir,1);
      return;
   }
   chosen_project := select_tree(project_list, caption:nls("Select a project with %s", _strip_filename(buffer_name,'P')), SL_FILENAME);
   if (chosen_project != COMMAND_CANCELLED_RC && chosen_project != "") {
      _maybe_unquote_filename(chosen_project);
      olddir := getcwd();
      chdir(_strip_filename( chosen_project,'N'),1);
      project_edit2(activetab, chosen_project, false);
      chdir(olddir,1);
      return;
   }
}

static _str checkForRedundantPath(_str cmd)
{
   // we are only interested in things that add things to the existing PATH
   if (pos('{^set path *=}?*path?*$', cmd, 1, 'IR') == 1) {
      
      // split up the parts
      firstPart := substr(cmd, pos('S0'), pos('0'));
      tempCmd := substr(cmd, pos('0') + pos('S0'), -1);

      // get the envvar value
      value := get_env('PATH');

      // split up the current PATH and the new stuff into the path parts
      _str setPath[], curPath[];
      split(tempCmd, PATHSEP, setPath);
      split(value, PATHSEP, curPath);

      // now see if any of these items are already in the path
      for (i := 0; i < setPath._length(); i++) {
         // look for this in the current path
         found := false;
         for (j := 0; j < curPath._length(); j++) {
            if (_file_eq(setPath[i], curPath[j])) {
               found = true;
               break;
            }
         }
         // if we found this is already in the PATH, take it out of our 
         // list so we don't set it again
         if (found) setPath[i] = '';
      }

      // go through and reassemble our command
      cmd = firstPart;
      first := true;
      for (i = 0; i < setPath._length(); i++) {
         if (setPath[i] != '') {
            if (!first) cmd :+= PATHSEP;
            else first = false;

            cmd :+= setPath[i];
         }
      }
      // we got rid of everything?
      if (cmd == firstPart) cmd = '';
   }

   return cmd;
}

static void _project_run_macro2(_str project_name=_project_name, bool (&been_there_done_that):[]=null)
{
   // make sure we do not recurse infinitely
   if (been_there_done_that._indexin(project_name)) return;
   been_there_done_that:[project_name] = true;

   // get the list of dependent projects, run their project open commands first
   _str p,array[];
   int handle=_ProjectHandle(project_name);
   _ProjectGet_DependencyProjects(handle,array);
   foreach (p in array) {
      _project_run_macro2(project_name,been_there_done_that);
   }

   // now get the project open commands for this project
   array._makeempty();
   _ProjectGet_Macro(handle,array);

   // and run them
   foreach (p in array) {
      // see if we are setting the path - maybe these things are already included?
      p = checkForRedundantPath(p);
      if (p != '') {
         execute(_parse_project_command(p, "", project_name, ""));
      }
   }
}

/**
 * Get lowcased name of currently selected tool (target or rule)
 */
_str GetTargetName()
{
   targetName := "";
   index := ctlToolTree._TreeCurIndex();
   if(index >= 0) {
      targetName = lowcase(ctlToolTree._TreeGetCaption(ctlToolTree._TreeCurIndex()));
   }

   return targetName;
}

/**
 * Get node for currently selected tool (target or rule)
 */
int GetTargetOrRuleNode(_str config = "")
{
   index := ctlToolTree._TreeCurIndex();
   if(index < 0) return -1;

   if(config == "") {
      config = GetConfigText();
   }

   node := -1;

   // get parent target name and rule input exts
   caption := ctlToolTree._TreeGetCaption(index);

   // determine if this is a target or a rule
   if(ctlToolTree._TreeGetDepth(index) == 2) {
      // this is a rule
      _str ruleSet = ctlToolTree._TreeGetCaption(ctlToolTree._TreeGetParentIndex(index));
      node = _ProjectGet_RuleNode(gProjectHandle, ruleSet, caption, config);
   } else {
      // this is a target
      node = _ProjectGet_TargetNode(gProjectHandle, caption, config);
   }

   return node;
}

_str GetCurrentConfigName(_str ProjectName=_project_name)
{
   if (ProjectName=='') {
      if (_fileProjectHandle()<0) {
         return '';
      }
      return _fileProjectConfig();
   }
   if (_file_eq(ProjectName,_project_name) && gActiveConfigName!='') {
      return(gActiveConfigName);
   }
   ConfigName := "";
   _ini_get_value(VSEWorkspaceStateFilename(), "ActiveConfig", _RelativeToWorkspace(ProjectName), ConfigName,'',_fpos_case);
   parse ConfigName with ',' ConfigName;
   if (ConfigName=='') {
      //We have to just pick one...
      _str List[];
      _ProjectGet_ConfigNames(_ProjectHandle(ProjectName),List);
      if (List._length()) {
         ConfigName=List[0];
      }
   }
   return(ConfigName);
}

void _workspace_opened_run_macros()
{
   if (gWorkspaceHandle <= 0) {
      return;
   }
   _str projectFiles[] = null;
   _GetWorkspaceFilesH(gWorkspaceHandle, projectFiles);

   if (_project_name != "" && !def_workspace_open_runs_all_macros) {
      return;
   }

   bool been_there_done_that:[];
   for (i := 0; i < projectFiles._length(); i++) {
      _str ProjectName = _AbsoluteToWorkspace(projectFiles[i]);
      _project_run_macro2(ProjectName, been_there_done_that);
   }
}

void _prjopen_run_macros(bool singleFileProject)
{
   if (singleFileProject) return;
   if (_project_name=='') return;
   bool been_there_done_that:[];
   _project_run_macro2(_project_name, been_there_done_that);
}

//void _prjconfig_run_macros()
//{
//   bool been_there_done_that:[];
//   _project_run_macro2(_project_name, been_there_done_that);
//}

void _ProjectTemplateExpand(int templates_handle,int project_handle,bool doSetAppType=false,bool AddDefaultFilters=false)
{
   int i;
   typeless array[];
   for (;;) {
      // Look for CopyChildren
      array._makeempty();
      _xmlcfg_find_simple_array(project_handle,"//CopyChildren",array);
      if (!array._length()) {
         break;
      }
      for (i=0;i<array._length();++i) {
         _str xpath=_xmlcfg_get_attribute(project_handle,array[i],"From");
         int SrcNode=_xmlcfg_find_simple(templates_handle,xpath);
         if (SrcNode<0) {
            _message_box(nls("CopyChildren from '%s' not found",xpath));
            break;
         } else {
            _xmlcfg_copy_children_as_siblings(project_handle,array[i],templates_handle,SrcNode);
            _xmlcfg_delete(project_handle,array[i]);
         }
      }
   }
   if (doSetAppType) {
      // Do SetAppType if command exists
      int SetAppTypeNode=_xmlcfg_find_simple(project_handle,'//SetAppType');
      if (SetAppTypeNode>=0) {
         _str AppType=_xmlcfg_get_attribute(project_handle,SetAppTypeNode,'AppType');
         _xmlcfg_delete(project_handle,SetAppTypeNode);
         _ProjectSetAppType(project_handle,AppType);
      }
   }
   if (AddDefaultFilters) {
      // Add file filters if necessary
      int FilesNode=_ProjectGet_FilesNode(project_handle);
      if (FilesNode<0) {
         _ProjectAdd_DefaultFolders(project_handle);
      }
   }
}

static void _ProjectInitializeFolderGuids(int handle)
{
   typeless array[];
   _xmlcfg_find_simple_array(handle, VPJX_FILES"//":+VPJTAG_FOLDER, array);

   count := array._length();
   int i;
   for (i = 0;i < count; ++i) {
      _ProjectAdd_FolderGuid(handle, array[i]);
   }
}


/**
 * 11:03am 6/22/1999
 * Adding some defaults so I can use this for the workspace stuff. 
 *  
 * @param ProjectName 
 * @param CompilerName 
 * @param ExeName 
 * @param WorkspaceName 
 * @param ShowPropertiesDialog 
 * @param SetWorkingDir 
 * @param AssociatedMakefile 
 * @param AssociatedMakefileType 
 * @param RetagWorkspaceFiles 
 * @param ConfigList 
 * @param RemoveDirectoryIfCancelled 
 * @param RemoveWorkspaceFileIfCancelled 
 * 
 * @return int 
 */
int workspace_new_project2(_str ProjectName='',
                           _str CompilerName='',
                           _str ExeName='',
                           _str WorkspaceName=_workspace_filename,
                           bool ShowPropertiesDialog=true,
                           bool SetWorkingDir=false,
                           _str AssociatedMakefile='',
                           _str AssociatedMakefileType='',
                           bool RetagWorkspaceFiles=true,
                           ProjectConfig ConfigList[]=null,
                           bool RemoveDirectoryIfCancelled=false,
                           bool RemoveWorkspaceFileIfCancelled=false,
                           bool runInitMacros=true)
{
   if (WorkspaceName=='') {
      WorkspaceName=_workspace_filename;
   }
   if (WorkspaceName=='') {
      _message_box('WorkspaceName must be specified');
      return(1);
   }
   operatingOnActiveWorkspace := _workspace_filename!='' && _file_eq(_workspace_filename,WorkspaceName);
   if (!_IsWorkspaceAssociated(WorkspaceName)) {
      if (!operatingOnActiveWorkspace) {
         _message_box('Invalid call to workspace_new_project().  Workspace must be active');
         return(1);
      }
   }
   _str result;
   //compiler_name="";
   if (ProjectName=='') {
      result= show('-modal _project_new_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      if (_param2!='') {
         CompilerName=_param2;
      }
      if (_param1!='') {
         ExeName=_param1;
      }
   }else{
      result=ProjectName;
   }
   //messageNwait("projectname="result" compiler_name="compiler_name);
   // If there is an open project, close it:
   new_project_name := absolute(strip(result));

   // Create the project tag file
   project_tag_filename := _strip_filename(new_project_name,'E'):+TAG_FILE_EXT;
   //tag_close_db(project_tag_filename);
   //tag_create_db(project_tag_filename);
   //tag_close_db(project_tag_filename);
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   // Init the default project properties and show the properties form:
   //name=slick_path_search(VSCFGFILE_PRJTEMPLATES);

   initmacro := "";
   int project_handle=_ProjectCreateFromTemplate(new_project_name,CompilerName,initmacro,true,!_IsWorkspaceAssociated(WorkspaceName));

   int ReleaseNode=_ProjectGet_ConfigNode(project_handle,'Release');
   // This is only supported for Visual C++ and Tornado
   Node := 0;
   int j;
   for (j=0;j<ConfigList._length();++j) {
      //_message_box('Node='Node);
      if (ReleaseNode<0) {
         _message_box(nls("%s file missing template %s or configuration %s",VSCFGFILE_PRJTEMPLATES,CompilerName,'Release'));
         break;
      }
      if (j==0) {
         Node=ReleaseNode;
      } else {
         Node=_xmlcfg_copy(project_handle,_xmlcfg_set_path(project_handle,"/"VPJTAG_PROJECT),
                           project_handle,ReleaseNode,VSXMLCFG_COPY_AS_CHILD);
      }
      _xmlcfg_set_attribute(project_handle,Node,'Name',ConfigList[j].config);
   }


   // add folder guids
   _ProjectInitializeFolderGuids(project_handle);

   // Set active config
   value := "";
   _str list[];
   _ProjectGet_ConfigNames(project_handle,list);
   //Make the first configuration active
   _ini_set_value(VSEWorkspaceStateFilename(WorkspaceName), "ActiveConfig",
                 _RelativeToWorkspace(new_project_name,WorkspaceName),','list[0],_fpos_case);

   // Replace %<e with executable name
   {
      typeless array[];
      _xmlcfg_find_simple_array(project_handle,VPJX_MENU"//"VPJTAG_EXEC"/@CmdLine[contains(.,'%<e')]",array);
      _xmlcfg_find_simple_array(project_handle,VPJX_POSTBUILDCOMMANDS"//"VPJTAG_EXEC"/@CmdLine[contains(.,'%<e')]",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_APPEND);
      _xmlcfg_find_simple_array(project_handle,VPJX_PREBUILDCOMMANDS"//"VPJTAG_EXEC"/@CmdLine[contains(.,'%<e')]",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_APPEND);
      _xmlcfg_find_simple_array(project_handle,VPJX_MENU"//"VPJTAG_TARGET"/@AppletClass[contains(.,'%<e')]",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_APPEND);
      _xmlcfg_find_simple_array(project_handle,VPJX_APPTYPETARGETS"//"VPJTAG_APPTYPETARGET"/@AppletClass[contains(.,'%<e')]",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_APPEND);
      int i;
      for (i=0;i<array._length();++i) {
         value=_xmlcfg_get_value(project_handle,array[i]);
         value=stranslate(value,ExeName,"%<e");
         _xmlcfg_set_value(project_handle,array[i],value);
      }
      // check all <Config> tag OutputFile attributes
      _xmlcfg_find_simple_array(project_handle, VPJX_CONFIG, array);
      for(i = 0; i < array._length(); i++) {
         _str outputFile = _xmlcfg_get_attribute(project_handle, array[i], "OutputFile");
         outputFile = stranslate(outputFile, ExeName, "%<e");
         _xmlcfg_set_attribute(project_handle, array[i], "OutputFile", outputFile);
      }
   }


   if (SetWorkingDir) {
      // This could be a user project template which has a working directory set.
      // This does not support a user wanting the working directory to be blank!
      _str WorkingDir=_ProjectGet_WorkingDir(project_handle);
      if (WorkingDir=='') {
         // Xcode projects need to have their working dir be the
         // parent of where the .pbxproj (and the .vpj) are located
         if (0 /*AssociatedMakefileType==XCODE_PROJECT_VENDOR_NAME*/) {
            _ProjectSet_WorkingDir(project_handle,"..");
         } else {
            _ProjectSet_WorkingDir(project_handle,".");
         }
      }
   }
   if (AssociatedMakefile!='') {
      makefilename := relative(AssociatedMakefile,_strip_filename(new_project_name,'N'));

      _ProjectSet_AssociatedFile(project_handle,makefilename);
      if (AssociatedMakefileType!='') {
        _ProjectSet_AssociatedFileType(project_handle,AssociatedMakefileType);
        if (AssociatedMakefileType==XCODE_PROJECT_VENDOR_NAME) {
            // This is actually set to the .xcode or .xcodeproj bundle directory
           bundleRelative := _strip_filename(AssociatedMakefile,'P');
           _ProjectSet_AssociatedFile(project_handle,bundleRelative);
        }
      }
   }
   if (initmacro!='') {
      ShowPropertiesDialog=false;
   }

   // With different versions of GCC and .NET, there is only one template in
   // prjtempletes.vpt that could have the CompilerConfigName element set
   // (VC6) and for all others it would have to be done dynamically.  So
   // all of them will be done here unless the user sets CompilerConfigName
   // in which case, their value will be used

   available_compilers compilers;
   _find_compilers(compilers);

   vPrjFileName := _strip_filename(_xmlcfg_get_filename(project_handle),'N'):+_xmlcfg_get_attribute(project_handle,_xmlcfg_find_simple(project_handle,'Project'),'AssociatedFile');
   compilerConfigName := determineCompilerConfigName(compilers,project_handle,vPrjFileName);
   _str nodes[];
   nodes._makeempty();
   _xmlcfg_find_simple_array(project_handle,'/Project/Config',nodes);

   typeless cfgIndex;
   configName := "";
   for (cfgIndex._makeempty();;) {
      nodes._nextel(cfgIndex);
      if (cfgIndex._isempty()) break;

      // set the CompilerConfigName attribute of the project configuration if it is not already set
      configName=_xmlcfg_get_attribute(project_handle,(int)nodes[cfgIndex],'Name');
      if (''==_ProjectGet_CompilerConfigName(project_handle,configName)) {
         if (compilerConfigName!='') {
            _ProjectSet_CompilerConfigName(project_handle,compilerConfigName,configName);
         } else {
            _ProjectSet_CompilerConfigName(project_handle,determineCompilerConfigName(compilers,project_handle,vPrjFileName,(int)nodes[cfgIndex]),configName);
         }
      }
   }
   //status=_ini_get_value(new_project_name,"GLOBAL",'sourcewildcards',sourcewildcards,'');
#if 0
   if (!status) {
      orig_view_id := p_window_id;
      status=_ini_get_section(new_project_name,"FILES",files_view_id);
      if (status) {
         orig_view_id=_create_temp_view(files_view_id);
         p_window_id=orig_view_id;
      }
      p_window_id=files_view_id;
      for (;;) {
         parse sourcewildcards with cur (PARSE_PATHSEP_RE),'r' sourcewildcards;
         if (cur=='') break;
         top();up();
         status=search('^'_escape_re_chars(cur)'$','@r'_fpos_case);
         if (status) {
            insert_line(cur);
         }
      }
      p_window_id=orig_view_id;
      _ini_put_section(new_project_name,"FILES",files_view_id);
      _ini_delete_value(new_project_name,"GLOBAL",'sourcewildcards');
   }
#endif

   if (_IsWorkspaceAssociated(WorkspaceName)) {
      if (AssociatedMakefileType == MACROMEDIA_FLASH_VENDOR_NAME) {
         if (_isWindows()) {
            _flash_create_default_build_scripts(AssociatedMakefile);
         }
      }

      if (AssociatedMakefileType == XCODE_PROJECT_VENDOR_NAME) {
         xcode_project_add_simulator_targets(AssociatedMakefile, project_handle);
      }
   }

   int status=_ProjectSave(project_handle);
   if (status) {
      _xmlcfg_close(project_handle);
      return(status);
   }
   if (!_IsWorkspaceAssociated(WorkspaceName) && AssociatedMakefileType=='') {
      // !!! Workspace must be active to call this function.
      workspace_insert(new_project_name,false,true,RetagWorkspaceFiles);
      //_TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      //_TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

      //readAndParseProjectToolList_ForAllConfigs(); already did this in workspace_insert
      if (ShowPropertiesDialog) {
         result=show('-modal -mdi -xy _project_form',new_project_name,_ProjectHandle(new_project_name),PROJECTPROPERTIES_TABINDEX_FILES);
         //toolbarUpdateFilterList(new_project_name);
      }
   } else {
      // This function special cases associated workspaces and
      // should not update the current project.

      //_ini_set_value(WorkspaceName,"Global","CurrentProject",new_project_name);
      //if (operatingOnActiveWorkspace) {
      //   workspace_set_active(_project_name);
      //}
   }
   _xmlcfg_close(project_handle);
   if ( initmacro!='' && runInitMacros ) {
      if (!operatingOnActiveWorkspace) {
         _message_box('The InitMacro may only be invoked on the active workspace');
         return(1);
      }
      index := find_index(initmacro,PROC_TYPE|COMMAND_TYPE);
      if (index) {
         status=call_index(configName,index);
         if (!status) {
            if (!_IsWorkspaceAssociated(WorkspaceName)) {
               _menu_add_workspace_hist(WorkspaceName,ProjectName);
            }
         }else{
            CloseAndDeleteNewWorkspace(RemoveDirectoryIfCancelled,RemoveWorkspaceFileIfCancelled);
         }
      }
   } else if (!_IsWorkspaceAssociated(WorkspaceName)) {
      _menu_add_workspace_hist(WorkspaceName,ProjectName);
   }
   return(0);
}

/**
 * Closes the current workspace, deletes the workspace
 * and project files, backs up one directory and removes
 * that directory if there are no files left.
 *
 * @return returns 0 if files can be deleted.  Removing directory
 *         does not affect the return value.
 */
static int CloseAndDeleteNewWorkspace(bool RemoveDirectory,bool RemoveWorkspaceFile)
{
   _str projectFilename=_project_name;
   _str workspaceFilename=_workspace_filename;
   //Wizard was cancelled, clean up project stuff.

   //Remove the file from the workspace.
   workspace_remove(projectFilename);
   if (RemoveWorkspaceFile) {
      int status=workspace_close();
      if (status) return(status);
   }

   _str workspaceFilenames[]=null;
   _GetWorkspaceFiles(workspaceFilename,workspaceFilenames);
   int status=delete_file(projectFilename);
   if (RemoveWorkspaceFile && workspaceFilenames._length()<2) {
      //If there are 1 or less files in this workspace
      if (status) return(status);
      status=delete_file(workspaceFilename);

      _menu_remove_workspace_hist(workspaceFilename);
      tag_file := VSEWorkspaceTagFilename(workspaceFilename);
      if (file_exists(tag_file)) delete_file(tag_file);
      history_file := VSEWorkspaceStateFilename(workspaceFilename);
      if (file_exists(history_file)) delete_file(history_file);
   }

   if (RemoveDirectory) {
      curPath := getcwd();
      _maybe_append_filesep(curPath);
      if (_file_eq(curPath,_file_path(projectFilename))) {
         //Back up one directory, and then call rmdir.  If there are files in the
         //directory rmdir will fail, and that is fine.
         cd('..');
      }
      status=rmdir(_file_path(projectFilename));
   }
   return(status);
}
defeventtab _project_form;

static _str getCurrentConfig()
{
   if (ctlCurConfig.p_visible) {
      return ctlCurConfig.p_text;
   } else {
      return PROJ_ALL_CONFIGS;
   }
}

void _ctl_new_override.lbutton_up()
{
   _control _ctl_profile_ovrs;
   pfNewErrorsProfileOverride(_ctl_profile_ovrs);
}

void _ctl_edit_ovr.lbutton_up()
{
   _control _ctl_profile_ovrs;
   pfEditLButtonUp(_ctl_profile_ovrs);
}

void _ctl_del_override.lbutton_up()
{
   _control _ctl_profile_ovrs;
   pfDeleteLButtonUp(_ctl_profile_ovrs);
}

void ctlBrowseRunFrom.lbutton_up()
{
   wid := p_window_id;

   // turn off autoselect on the textbox
   // (05/29/07 dobrien, leave p_auto_select at 1 so that text of control will
   // be overwritten.  CR#1-9I0RA
   //wid.p_prev.p_auto_select = 0;

   _str orig_dir = _parse_project_command(p_prev.p_text,"",_project_name,"");
   orig_dir = absolute(orig_dir, _strip_filename(_project_name,'N'));
   _str result = _ChooseDirDialog("", orig_dir, "", CDN_PATH_MUST_EXIST);
   if ( result=='' ) {
      return;
   }

   wid2 := p_prev;
   //ctlinsert(result);
   ctlRunFromDir.p_text = strip(result,'B','"');
   if (wid2) {
      wid2._set_focus();
   }

   // turn on autoselect on the textbox
   wid.p_prev.p_auto_select = true;
}
void ctlBrowseCmdLine.lbutton_up()
{
   wid := p_window_id;

   // turn off autoselect on the textbox
   wid.p_prev.p_auto_select = false;

   typeless result=_OpenDialog('-modal',
                        'Choose File',        // Dialog Box Title
                        '',                   // Initial Wild Cards
                        "All Files (" ALLFILES_RE ")", // File Type List
                        OFN_FILEMUSTEXIST|OFN_NOCHANGEDIR     // Flags
                       );
   result=strip(result,'B','"');
   if ( result=='' ) {
      return;
   }

   ctlinsert(result);

   // turn on autoselect on the textbox
   wid.p_prev.p_auto_select = true;
}

void ctlproperties.lbutton_up()
{
   _str RelFilename=_srcfile_list._lbget_text();
   int Node=_ProjectGet_FileNode(gProjectHandle,RelFilename);

   WILDCARD_FILE_ATTRIBUTES f;

   f.Recurse=_xmlcfg_get_attribute(gProjectHandle,Node,'Recurse',0);
   f.Excludes=translate(_xmlcfg_get_attribute(gProjectHandle,Node,'Excludes'), FILESEP, FILESEP2);
   f.ListMode=_xmlcfg_get_attribute(gProjectHandle,Node,'L',0);
   f.DirectoryFolder=_xmlcfg_get_attribute(gProjectHandle,Node,'D',0);

   filename := RelFilename;
   result :=  modify_wildcard_properties(gProjectName, filename, f);
   if (result) {
      return;
   }

   // check filename
   if (filename != RelFilename) {
      _xmlcfg_set_attribute(gProjectHandle,Node,'N',_NormalizeFile(filename));
      _srcfile_list._lbset_item(filename);
   }
   _xmlcfg_set_attribute(gProjectHandle,Node,'Recurse',f.Recurse);
   if (f.Excludes!='') {
      _xmlcfg_set_attribute(gProjectHandle,Node,'Excludes',_NormalizeFile(f.Excludes));
   } else {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'Excludes');
   }
   if (f.ListMode) {
      _xmlcfg_set_attribute(gProjectHandle,Node,'L',f.ListMode);
   } else {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'L');
   }
   if (f.DirectoryFolder) {
      _xmlcfg_set_attribute(gProjectHandle,Node,'D',f.DirectoryFolder);
   } else {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'D');
   }

   gFileListModified=true;
}
void ctlStopOnPreErrors.lbutton_up()
{
   //if (CHANGING_CONFIGURATION==1 || !p_active_form.p_visible) return;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         switch(p_name) {
         case 'ctlStopOnPreErrors':
            _ProjectSet_StopOnPreBuildError(gProjectHandle,ctlStopOnPreErrors.p_value,config);
            break;

         case 'ctlStopOnPostErrors':
            _ProjectSet_StopOnPostBuildError(gProjectHandle,ctlStopOnPostErrors.p_value,config);
            break;
         }
      }
      return;
   }
   switch(p_name) {
   case 'ctlStopOnPreErrors':
      _ProjectSet_StopOnPreBuildError(gProjectHandle,ctlStopOnPreErrors.p_value,GetConfigText());
      break;

   case 'ctlStopOnPostErrors':
      _ProjectSet_StopOnPostBuildError(gProjectHandle,ctlStopOnPostErrors.p_value,GetConfigText());
      break;
   }
}

static bool isItemBold(int index)
{
   int showChildren;
   int nonCurrentBMIndex;
   int currentBMIndex;
   int moreFlags;

   _TreeGetInfo(index, showChildren, nonCurrentBMIndex, currentBMIndex, moreFlags);

   return (0 != (moreFlags & TREENODE_BOLD));
}

void ctlMoveUserIncludesUp.lbutton_up()
{
   // find the tree control relative to the edit control
   wid := p_window_id;
   p_window_id = wid.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if( (index > 0) && (!isItemBold(index)) ) {
      // handle special cases where this is the new entry node or the prev
      // node is the new entry node
      prevIndex := _TreeGetPrevSiblingIndex(index);
      if(prevIndex == -1) return;
      if (isItemBold(prevIndex)) return;
      // checking for bold should handle this
//      if(strieq(_TreeGetCaption(index), BLANK_TREE_NODE_MSG)) return;
//      if(strieq(_TreeGetCaption(prevIndex), BLANK_TREE_NODE_MSG)) return;

      _TreeMoveUp(index);

      // trigger the on_change event so that the data will be saved
      switch(p_name) {
         case 'ctlUserIncludesList':
            ctlUserIncludesList.call_event(CHANGE_SELECTED,index,ctlUserIncludesList,ON_CHANGE, 'W');
            break;

         case 'ctlPreBuildCmdList':
            ctlPreBuildCmdList.call_event(CHANGE_SELECTED,index,ctlPreBuildCmdList,ON_CHANGE, 'W');
            break;

         case 'ctlPostBuildCmdList':
            ctlPostBuildCmdList.call_event(CHANGE_SELECTED,index,ctlPostBuildCmdList,ON_CHANGE, 'W');
            break;
      }
   }

   p_window_id = wid;
}

void ctlMoveUserIncludesDown.lbutton_up()
{
   // find the tree control relative to the edit control
   wid := p_window_id;
   p_window_id = wid.p_prev.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if( (index > 0) && (!isItemBold(index)) ) {
      // handle special cases where this is the new entry node or the next node
      // is the new entry node
      nextIndex := _TreeGetNextSiblingIndex(index);
      if(nextIndex == -1) return;
      if (isItemBold(nextIndex)) return;
      // checking for bold should handle this
//      if(strieq(_TreeGetCaption(index), BLANK_TREE_NODE_MSG)) return;
//      if(strieq(_TreeGetCaption(nextIndex), BLANK_TREE_NODE_MSG)) return;

      _TreeMoveDown(index);

      // trigger the on_change event so that the data will be saved
      switch(p_name) {
         case 'ctlUserIncludesList':
            ctlUserIncludesList.call_event(CHANGE_SELECTED,index,ctlUserIncludesList,ON_CHANGE, 'W');
            break;

         case 'ctlPreBuildCmdList':
            ctlPreBuildCmdList.call_event(CHANGE_SELECTED,index,ctlPreBuildCmdList,ON_CHANGE, 'W');
            break;

         case 'ctlPostBuildCmdList':
            ctlPostBuildCmdList.call_event(CHANGE_SELECTED,index,ctlPostBuildCmdList,ON_CHANGE, 'W');
            break;
      }
   }

   p_window_id = wid;
}

typeless ctlUserIncludesList.on_change(int reason,int index,int col=-1,_str value="",int wid=0)
{
   // if we let this one through, it will reset all
   // our pre/post build commands to nothing
   if (reason == CHANGE_BUTTON_SIZE) return 0;

   if (gChangingConfiguration==1) {
      // Force trees to update
      ctlUserIncludesList._TreeRefresh();
      ctlPreBuildCmdList._TreeRefresh();
      ctlPostBuildCmdList._TreeRefresh();
      ctlDefinesTree._TreeRefresh();
      return 0;
   }

   // can not edit compiler include path directories
   if(reason == CHANGE_EDIT_QUERY && isItemBold(index) &&
      !strieq(arg(4), PROJ_BLANK_TREE_NODE_MSG)) {
      return -1;
   }

   if(reason == CHANGE_EDIT_OPEN) {
      // if this is the new entry node, clear the message
      if(strieq(arg(4), PROJ_BLANK_TREE_NODE_MSG)) {
         arg(4) = '';
      } else if (isItemBold(index)) {
         return -1;
      }
   }

   if (reason == CHANGE_EDIT_OPEN_COMPLETE) {
      typeless completion = (p_window_id == _control ctlUserIncludesList) ? DIR_ARG : NONE_ARG;
      if (wid != 0) wid.p_completion = completion;
   }

   if(reason == CHANGE_EDIT_CLOSE) {
      // check the old caption to see if it is the new entry node
      caption := _TreeGetCaption(index);
      wasNewEntryNode := strieq(caption, PROJ_BLANK_TREE_NODE_MSG);

      // HS2-CHG: or if nth. was changed (e.g. by double clicking around
      // if the node changed and is now empty, delete it
      if( (arg(4) == "") || strieq(arg(4), PROJ_BLANK_TREE_NODE_MSG)) {
         if(wasNewEntryNode) {
            arg(4) = PROJ_BLANK_TREE_NODE_MSG;
            return 0;
         } else {
            _TreeDelete(index);
            return DELETED_ELEMENT_RC;
         }
      }

      // make sure the last node in the tree is the new entry node
      if(wasNewEntryNode) {
         // unbold the existing node
         _TreeSetInfo(index, TREE_NODE_LEAF, -1, -1, 0);

         // bold the new entry node
         int newIndex = _TreeAddListItem(PROJ_BLANK_TREE_NODE_MSG);
         _TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);

      }
   }

   if (p_name:=='ctlDefinesTree') {
      // the processing for the defines list is a bit more complicated than the others
      UpdateProjectDefines();
   } else if (p_name == 'ctlUserIncludesList') {
      UpdateProjectIncludes();
   } else if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         switch(p_name) {
         case 'ctlPreBuildCmdList':
            _ProjectSet_PreBuildCommandsList(gProjectHandle,ctlPreBuildCmdList._TreeGetDelimitedItemList("\1"),config);
            break;
         case 'ctlPostBuildCmdList':
            _ProjectSet_PostBuildCommandsList(gProjectHandle,ctlPostBuildCmdList._TreeGetDelimitedItemList("\1"),config);
            break;
         }
      }
   } else {
      switch(p_name) {
      case 'ctlPreBuildCmdList':
         _ProjectSet_PreBuildCommandsList(gProjectHandle,ctlPreBuildCmdList._TreeGetDelimitedItemList("\1"),GetConfigText());
         break;
      case 'ctlPostBuildCmdList':
         _ProjectSet_PostBuildCommandsList(gProjectHandle,ctlPostBuildCmdList._TreeGetDelimitedItemList("\1"),GetConfigText());
         break;
      }
   }

   // disable up, down, and delete for bold nodes
   updateUpDownButtons();

   return 0;
}

/**
 * Updates enabled status of up & down buttons associated with
 * the current tree object.
 */
static void updateUpDownButtons()
{
   index := _TreeCurIndex();

   prevIndex := _TreeGetPrevSiblingIndex(index);
   nextIndex := _TreeGetNextSiblingIndex(index);

   bold := isItemBold(index);

   switch (p_name) {
   case 'ctlUserIncludesList':
      ctlMoveUserIncludesUp.p_enabled = (prevIndex != -1) && !bold;
      ctlMoveUserIncludesDown.p_enabled = (nextIndex != -1) && !bold && (_TreeGetCaption(nextIndex) != PROJ_BLANK_TREE_NODE_MSG);
      ctlRemoveUserIncludes.p_enabled = !bold;
      break;
   case 'ctlPreBuildCmdList':
      ctlMovePreCmdUp.p_enabled = (prevIndex != -1) && !bold;
      ctlMovePreCmdDown.p_enabled = (nextIndex != -1) && !bold && (_TreeGetCaption(nextIndex) != PROJ_BLANK_TREE_NODE_MSG);;
      break;
   case 'ctlPostBuildCmdList':
      ctlMovePostCmdUp.p_enabled = (prevIndex != -1) && !bold;
      ctlMovePostCmdDown.p_enabled = (nextIndex != -1) && !bold && (_TreeGetCaption(nextIndex) != PROJ_BLANK_TREE_NODE_MSG);
      break;
   }
}

void ctlUserIncludesList.'DEL'()
{
   deleteUserInclude();
}

static void deleteUserInclude()
{
   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if(index > 0) {
      // cannot delete new entry node
      //if(strieq(_TreeGetCaption(index), BLANK_TREE_NODE_MSG)) {
      if (isItemBold(index)) {
         return;
      }
      _TreeDelete(index);

      // HS2-ADD: trigger the on_change event so that the data will be saved
      call_event(CHANGE_SELECTED,index,ctlUserIncludesList,ON_CHANGE, 'W');
   }
}

void ctlRemoveUserIncludes.lbutton_up()
{
   ctlUserIncludesList.deleteUserInclude();
}

void _checkDefine(_str &define)
{
   ch1 := substr(define,1,1);
   ch2 := upcase(substr(define,2,1));

   // if no prefix
   if ( ((ch1!='/')&&(ch1!='-')) ||
        ((ch2!='D')&&(ch2!='U')) ) {
      // assume define
      define='/D'define;
      ch2='D';
   }

   // no reason to keep blank lines
   if (length(strip(define))==2) {
      define='';
   } else {
      // remove any space that might be between /D or /U and the macro
      define=substr(define,1,2):+strip(substr(define,3));

      // fix any problems with an equals sign, either missing, or unexpected
      equ_pos := 0;
      spc_pos := 0;
      if (ch2=='D') {
         equ_pos=pos('=',define);
         spc_pos=pos(' ',define);

         // if there are spaces AND
         if ( (spc_pos!=0) &&
            // no equals sign OR the first equals sign is after the first space
            ((equ_pos==0)||(equ_pos>spc_pos))) {

            // replace the first space with an equals sign
            define=substr(define,1,spc_pos-1):+'=':+substr(define,spc_pos+1);
         }
      } else { // ch2=='U'
         // if there is a space or an equals sign, ignore everything after it
         spc_pos=pos(' ',define);
         if (spc_pos!=0) {
            define=substr(define,1,spc_pos-1);
         }
         equ_pos=pos(' ',define);
         if (equ_pos!=0) {
            define=substr(define,1,equ_pos-1);
         }
      }
   }
}

static bool isMacroInList(_str check_define,_str list)
{
   if (0==pos(check_define,list)) {
      return false;
   }

   // the string appears in the list, now verify that is actually
   // defined exactly the same way (pseudo match whole word)
   while (list!='') {
      _str define = parse_next_option(list,false);
      if (define==check_define) {
         return true;
      }
   }
   return false;
}

static void maybeRemoveDefine(_str check_define,_str &list)
{
   // get the name without the /D or /U
   name := "";
   parse substr(check_define,3) with name '=' . ;

   dname := "";
   _str orig_list=list;
   list='';

   while (orig_list!='') {
      _str define = parse_next_option(orig_list,false);
      parse substr(define,3) with dname '=' . ;
      if (dname!=name) {
         if (list!='') {
            strappend(list,' ');
         }
         strappend(list,_maybe_quote_filename(define));
      }
   }
}

struct defchange {
   bool added;
   _str define;
};

static _str fully_quote(_str input)
{
   output := "";
   input=strip(input);

   while (input!='') {
      _str item=parse_next_option(input,false);
      if (output:=='') {
         output='"'item'"';
      } else {
         strappend(output,' "'item'"');
      }
   }

   return output;
}

static void UpdateProjectIncludes()
{
   if (!p_EditInPlace) {
      return;
   }

   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      gAllConfigsInfo.Includes = _TreeGetDelimitedItemList(PATHSEP);
      foreach (auto config in gConfigList) {
         _ProjectSet_IncludesList(gProjectHandle,gAllConfigsInfo.Includes,config);
      }
   } else {
      _ProjectSet_IncludesList(gProjectHandle,_TreeGetDelimitedItemList(PATHSEP),GetConfigText());
   }
}
static void UpdateProjectDefines()
{
   if (!p_EditInPlace) {
      return;
   }

   defines := "";
   hasDoubleClickLine := false;

   // form a single string for the defines, all properly formatted
   if (_TreeGetNumChildren(TREE_ROOT_INDEX)>0) {
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for (;index>=0;) {
         someDefine := _TreeGetCaption(index);
         if (someDefine:==PROJ_BLANK_TREE_NODE_MSG) {
            hasDoubleClickLine=true;
         } else if (!isItemBold(index)) {
            _checkDefine(someDefine);
            if (someDefine!='') {
               if (defines!='') {
                  strappend(defines,' ');
               }
               strappend(defines,'"'someDefine'"');
            }
         }
         index=_TreeGetNextSiblingIndex(index);
      }
   }

   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      if (defines!=gAllConfigsInfo.Defines) {
         // they changed something, figure out what
         defchange changes[];
         _str orig=gAllConfigsInfo.Defines;
         _str updated=defines;
         define := "";
         next_change := 0;

         // look for new defines
         while (updated!='') {
            define=parse_next_option(updated,false);
            if (!isMacroInList(define,gAllConfigsInfo.Defines)) {
               next_change=changes._length();
               changes[next_change].added=true;
               changes[next_change].define=define;
            }
         }

         // now look for removed defines
         while (orig!='') {
            define=parse_next_option(orig,false);
            if (!isMacroInList(define,defines)) {
               next_change=changes._length();
               changes[next_change].added=false;
               changes[next_change].define=define;
            }
         }

         // then apply the changes to all configs
         foreach (auto config in gConfigList) {
            defines=fully_quote(_ProjectGet_Defines(gProjectHandle,config));
            for (j:=0;j<changes._length();++j) {
               if (changes[j].added) {
                  // don't add it if it is already there
                  if (!isMacroInList(changes[j].define,defines)) {
                     // if there is already a define matching the beginning
                     // of the new one, remove it
                     // (e.g.
                     //       config has /Dblah=old
                     //       user adds  /Dblah=new to "All configurartions"
                     //       remove /Dblah=old so "/Dblah" is not duplicated)
                     maybeRemoveDefine(changes[j].define,defines);
                     if (defines!='') {
                        strappend(defines,' ');
                     }
                     strappend(defines,'"'changes[j].define'"');
                  }
               } else {
                  // removed
                  full_define := '"'changes[j].define'"';
                  // if it is the first one
                  if (substr(defines,1,length(full_define))==full_define) {
                     // remove it and potentially a trailing space
                     defines=substr(defines,length(full_define)+2);
                  } else {
                     // remove it from the middle with the preceding space
                     trailing := "";
                     parse defines with defines (' 'full_define) trailing;
                     strappend(defines,trailing);
                  }
               }
            }
            _ProjectSet_Defines(gProjectHandle,defines,config);
         }
      }
   } else {
      _ProjectSet_Defines(gProjectHandle,defines,getCurrentConfig());
   }

   // if this just replaced the <double click here line, replace it
   if (!hasDoubleClickLine && p_window_id.p_enabled) {
      int newIndex = _TreeAddListItem(PROJ_BLANK_TREE_NODE_MSG);
      _TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
   }
}

void _srcfile_list.'DEL'()
{
   if (_remove.p_enabled) {
      _remove.call_event(_remove,LBUTTON_UP,'W');
   }
}

void ctlToolDelete.lbutton_up()
{
   if (ctlToolTree._TreeCurIndex() <= 0) {
      return;
   }

   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      TargetName := GetTargetName();
      foreach (auto config in gConfigList) {
         int Node = GetTargetOrRuleNode(config);
         if (Node>=0) {
            _xmlcfg_delete(gProjectHandle,Node);
         }
      }
      gAllConfigsInfo.TargetInfo._deleteel(lowcase(TargetName));
   } else {
      int Node = GetTargetOrRuleNode();
      if (Node>=0) {
         _xmlcfg_delete(gProjectHandle,Node);
      }
   }


   // Delete the entry from the list box:
   ctlToolTree._TreeDelete(ctlToolTree._TreeCurIndex());
   ctlToolTree.call_event(CHANGE_SELECTED, ctlToolTree._TreeCurIndex(), ctlToolTree, ON_CHANGE, 'W');
   ctlToolTree.refresh();

   // Set ctlToolDelete.p_enabled and rebuild TargetList (could call SetTargetList() instead for this)
   ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
}

void ctlAddDefine.lbutton_up()
{
   _str prompt_title;
   _str prompt_value;
   _str prefix;

   if (p_name=='ctlAddDefine') {
      prompt_title='Enter the macro you wish to define';
      prompt_value='name=value';
      prefix='/D';
   } else {
      prompt_title='Enter the macro you wish to un-define';
      prompt_value='name';
      prefix='/U';
   }

   typeless result=show('-modal _textbox_form',
               prompt_title,
               0,//Flags,
               '',//Tb width
               '',//help item
               '',//Buttons and captions
               '',//retrieve name
               'Macro:'prompt_value);

   if (result=='') return;
   macro := strip(_param1);

   first_char := substr(macro,1,1);
   if ((first_char!='/')&&(first_char!='-')) {
      macro=prefix:+macro;
   }
   ctlDefinesTree._TreeBottom();
   lastIndex := ctlDefinesTree._TreeCurIndex(); // get the index of the <double click... line
   ctlDefinesTree._TreeAddItem(lastIndex,macro,TREE_ADD_BEFORE);
   ctlDefinesTree._TreeUp(); // select the newly added item

   ctlDefinesTree.UpdateProjectDefines();
}
static _str getCompilerListProjectType() {
   project_type := "";
   enabled:=true;
   if(gConfigList._length()>0) {
      if (gConfigList._length()<=2) {
         project_type=_ProjectGet_Type(gProjectHandle, gConfigList[0]);
      } else if(getCurrentConfig()!=PROJ_ALL_CONFIGS) {
         project_type=_ProjectGet_Type(gProjectHandle, getCurrentConfig());
      } else {
         // ALL_CONFIGS case
         project_type=_ProjectGet_Type(gProjectHandle, gConfigList[0]);
         if (project_type!='') {
            for (i:=1;i<gConfigList._length()-1;++i) {
               project_type2:=_ProjectGet_Type(gProjectHandle, gConfigList[i]);
               if (project_type2!=project_type) {
                  //enabled=false;
                  project_type='';
                  break;
               }
            }
         }
      }
   }
   //ctlCompilerLabel.p_enabled=ctlCompilerList.p_enabled=ctlcompiler_config.p_enabled=enabled;
   return project_type;

   /*int handle = _ProjectHandle();
   config := "";
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   _str project_type=_ProjectGet_Type(handle, config );
   return project_type; */
}

void ctlcompiler_config.lbutton_up()
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build");
      return;
   }

   wasLatest := false;
   wasDefault := false;

   project_type := getCompilerListProjectType();

   temp_config := ctlCompilerList.p_text;
   result := "";
   if (project_type :== "java") {
      if (substr(temp_config,1,length(COMPILER_NAME_LATEST)):==COMPILER_NAME_LATEST) {
         wasLatest=true;
         parse temp_config with . '(' temp_config ')';
      } else if (substr(temp_config,1,length(COMPILER_NAME_DEFAULT)):==COMPILER_NAME_DEFAULT) {
         wasDefault=true;
         parse temp_config with . '(' temp_config ')';
      }
      orig_wid := p_window_id;
      int wid = show("-xy _java_compiler_properties_form");
      wid._java_compiler_set_config(temp_config);
      result = _modal_wait(wid);
      p_window_id = orig_wid;
   } else {
      if (substr(temp_config,1,length(COMPILER_NAME_LATEST)):==COMPILER_NAME_LATEST) {
         wasLatest=true;
         parse temp_config with . '(' temp_config ')';
      } else if (substr(temp_config,1,length(COMPILER_NAME_DEFAULT)):==COMPILER_NAME_DEFAULT) {
         wasDefault=true;
         parse temp_config with . '(' temp_config ')';
      }
      orig_wid := p_window_id;
      int wid = show("-xy _refactor_c_compiler_properties_form");
      wid._refactor_set_config(temp_config);
      result = _modal_wait(wid);
      p_window_id = orig_wid;
   }

   // repopulate the entire list as anything could have happend
   filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;

   refactor_config_open( filename );

   populate_config_list(project_type);

   if (wasLatest) {
      // latest is always at the top of the list
      ctlCompilerList._lbtop();
   } else if (wasDefault) {
      // default is always second in the list
      ctlCompilerList._lbtop();
      ctlCompilerList._lbdown();
   } else {
      ctlCompilerList._lbfind_and_select_item(temp_config);
   }

   ctlCompilerList._lbselect_line();
   ctlCompilerList.p_text=ctlCompilerList._lbget_seltext();
   ctlCompilerList.call_event(CHANGE_SELECTED,ctlCompilerList,ON_CHANGE,'W');
}

static void SetTargetList()
{
   // IF the targets are not the same for all configurations
   if (gAllConfigsInfo.TargetList==null) {
      return;
   }

   gAllConfigsInfo.TargetList = ctlToolTree._TreeGetDelimitedItemList("\1");
}
void ctlToolUp.lbutton_up()
{
   wid := p_window_id;
  _control ctlToolDown;

  status := 0;
   if (wid==ctlToolUp) {
      status = ctlToolTree._TreeMoveUp(ctlToolTree._TreeCurIndex());

   }else if (wid==ctlToolDown) {
      status = ctlToolTree._TreeMoveDown(ctlToolTree._TreeCurIndex());
   }
   p_window_id=wid;

   int i;
   PrevNode := 0;
   NextNode := 0;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         int Node = GetTargetOrRuleNode(config);
         if (Node>=0) {
            if (wid==ctlToolUp) {
               PrevNode=_xmlcfg_get_prev_sibling(gProjectHandle,Node);
               if (PrevNode!=-1) {
                  _xmlcfg_copy(gProjectHandle,Node,gProjectHandle,PrevNode,0);
                  _xmlcfg_delete(gProjectHandle,PrevNode);
               }
            } else {
               NextNode=_xmlcfg_get_next_sibling(gProjectHandle,Node);
               if (NextNode!=-1) {
                  _xmlcfg_copy(gProjectHandle,NextNode,gProjectHandle,Node,0);
                  _xmlcfg_delete(gProjectHandle,Node);
               }
            }
         }
      }
      SetTargetList();
   } else {
      int Node = GetTargetOrRuleNode();
      if (Node>=0) {
         if (wid==ctlToolUp) {
            PrevNode=_xmlcfg_get_prev_sibling(gProjectHandle,Node);
            if (PrevNode!=-1) {
               _xmlcfg_copy(gProjectHandle,Node,gProjectHandle,PrevNode,0);
               _xmlcfg_delete(gProjectHandle,PrevNode);
            }
         } else {
            NextNode=_xmlcfg_get_next_sibling(gProjectHandle,Node);
            if (NextNode!=-1) {
               _xmlcfg_copy(gProjectHandle,NextNode,gProjectHandle,Node,0);
               _xmlcfg_delete(gProjectHandle,Node);
            }
         }
      }

   }
}

void ctlToolNew.lbutton_up()
{
   project_tool_wizard(gProjectHandle, gIsExtensionProject?1:0, false);
   ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
}

void ctlToolVerbose.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetVerbose(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].Verbose=p_value;
      }
      return;
   }
   _ProjectSet_TargetVerbose(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlToolBeep.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetBeep(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].Beep=p_value;
      }
      return;
   }
   _ProjectSet_TargetBeep(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlThreadDeps.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetThreadDeps(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].ThreadDeps=p_value;
      }
      return;
   }
   _ProjectSet_TargetThreadDeps(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlThreadCompiles.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetThreadCompiles(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].ThreadCompiles=p_value;
      }
      return;
   }
   _ProjectSet_TargetThreadCompiles(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlTimeBuild.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetTimeBuild(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].TimeBuild=p_value;
      }
      return;
   }
   _ProjectSet_TargetTimeBuild(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlBuildFirst.lbutton_up()
{
   if (_isUnix()) {
      if (ctlBuildFirst.p_value && ctlRunInXterm.p_value) {
         TargetName := GetTargetName();
         if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
            ctlRunInXterm.p_value=0;
            ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
         }
      }
   }
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetBuildFirst(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].BuildFirst=p_value;
      }
   } else {
      _ProjectSet_TargetBuildFirst(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
   }
   if (ctlBuildFirst.p_value) {
      if (!ctlToolCaptureOutput.p_value) {
         ctlToolCaptureOutput.p_value=1;
         call_event(ctlToolCaptureOutput,LBUTTON_UP,'W');
      }
      if (!ctlToolOutputToConcur.p_value) {
         ctlToolOutputToConcur.p_value=1;
         call_event(ctlToolOutputToConcur,LBUTTON_UP,'W');
      }
   }

   // enable the save options combo based on the buildfirst enabled and value settings
   ctlToolSaveCombo.p_enabled = ctlBuildFirst.p_enabled ? !ctlBuildFirst.p_value : true;
}
void ctlToolClearProcessBuf.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetClearProcessBuffer(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].ClearProcessBuffer=p_value;
      }
   } else {
      _ProjectSet_TargetClearProcessBuffer(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
   }
}
#if 1 /*__UNIX__ */
void ctlRunInXterm.lbutton_up()
{
   if (!_isUnix()) return;
   if (ctlBuildFirst.p_value && ctlRunInXterm.p_value) {
      TargetName := GetTargetName();
      if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
         ctlBuildFirst.p_value=0;
         ctlBuildFirst.call_event(ctlBuildFirst,LBUTTON_UP,'W');
      }
   }
   p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetRunInXterm(gProjectHandle, GetTargetOrRuleNode(config), (p_value!=0));
         gAllConfigsInfo.TargetInfo:[GetTargetName()].RunInXterm=p_value;
      }
   } else {
      _ProjectSet_TargetRunInXterm(gProjectHandle, GetTargetOrRuleNode(), (p_value!=0));
   }
}
#endif
/**
 * Determine if the "output to current process" check box should be enabled.
 * <P>
 * This code always returns false if the cmdline is blank and there is a
 * debugger callback for simplicity.
 *
 * @param projectToolList
 * @param toolIndex
 *
 * @return
 */
bool captureOutputRequiresConcurrentProcess(_str TargetName,_str cmd)
{
   if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
      index := find_index('_'_project_DebugCallbackName'_DebugCommandCaptureOutputRequiresConcurrentProcess',PROC_TYPE);
      if (index) {
         requireConcurrent := call_index(cmd,index);
         if (!requireConcurrent) {
            return(false);
         }
      }
      return(true);
   }
   return(false);
}
_str ProjectFormGetCaptureOutputWith()
{
   _str CaptureOutputWith;
   if (!ctlToolCaptureOutput.p_value) {
      CaptureOutputWith='';
   } else if (ctlToolOutputToConcur.p_value) {
      CaptureOutputWith=VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER;
   } else {
      CaptureOutputWith=VPJ_CAPTUREOUTPUTWITH_REDIRECTION;
   }
   return(CaptureOutputWith);
}
void ctlToolCaptureOutput.lbutton_up()
{
   TargetName := GetTargetName();
   CmdLine := "";
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      CmdLine=gAllConfigsInfo.TargetInfo:[lowcase(TargetName)].Exec_CmdLine;
   }else{
      CmdLine=ctlToolCmdLine.p_text;
   }
   if (CmdLine==null) {
      CmdLine='';
   }

   ctlToolCaptureOutput.p_style=PSCH_AUTO2STATE;
   // IF capture output is off
   if (!p_value) {
      ctlToolOutputToConcur.p_value=0;
      ctlToolOutputToConcur.p_enabled= false;
      ctlToolClearProcessBuf.p_value=0;
      ctlToolClearProcessBuf.p_enabled= false;
      if (_isUnix()) {
         //ctlRunInXterm.p_value=0;
         ctlRunInXterm.p_enabled= true;
         //ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
      }
   } else {
      if (captureOutputRequiresConcurrentProcess(TargetName,CmdLine)) {
         ctlToolOutputToConcur.p_value=1;
         call_event(ctlToolOutputToConcur,LBUTTON_UP,'W');
         ctlToolOutputToConcur.p_enabled= false; //supportConcurrentProcessBuffer(projectToolList,toolIndex);
      } else {
         ctlToolOutputToConcur.p_value=0;
         call_event(ctlToolOutputToConcur,LBUTTON_UP,'W');
         ctlToolOutputToConcur.p_enabled= true; //supportConcurrentProcessBuffer(projectToolList,toolIndex);
      }
      ctlToolClearProcessBuf.p_value=0;
      //ctlToolClearProcessBuf.p_enabled= false;
      if (_isUnix()) {
         //ctlRunInXterm.p_value=0;
         //ctlRunInXterm.p_enabled= false;
         ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
      }
      //If ctlToolOutputToConcur.p_value is false, this is supposed to be disabled - DWH
   }
   if (p_value!=ctlBuildFirst.p_value && ctlBuildFirst.p_value) {
      ctlBuildFirst.p_value=p_value;
      ctlBuildFirst.call_event(ctlBuildFirst,LBUTTON_UP,'W');
   }

   CaptureOutputWith := ProjectFormGetCaptureOutputWith();
   //p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetCaptureOutputWith(gProjectHandle, GetTargetOrRuleNode(config), CaptureOutputWith);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].CaptureOutputWith=CaptureOutputWith;
      }
   } else {
      _ProjectSet_TargetCaptureOutputWith(gProjectHandle, GetTargetOrRuleNode(), CaptureOutputWith);
   }

}
void ctlToolOutputToConcur.lbutton_up()
{
   ctlToolOutputToConcur.p_style=PSCH_AUTO2STATE;
   if (p_value) {
      ctlToolClearProcessBuf.p_enabled= true;
   } else {
      ctlToolClearProcessBuf.p_enabled= false;
      ctlToolClearProcessBuf.p_value= 0;
   }

   // if buildfirst is on and this gets disabled, buildfirst must also be disabled
   if (p_value!=ctlBuildFirst.p_value && ctlBuildFirst.p_value) {
      ctlBuildFirst.p_value = 0;
      ctlBuildFirst.call_event(ctlBuildFirst,LBUTTON_UP,'W');
   }

   CaptureOutputWith := ProjectFormGetCaptureOutputWith();
   //p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetCaptureOutputWith(gProjectHandle, GetTargetOrRuleNode(config), CaptureOutputWith);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].CaptureOutputWith=CaptureOutputWith;
      }
   } else {
      _ProjectSet_TargetCaptureOutputWith(gProjectHandle, GetTargetOrRuleNode(), CaptureOutputWith);
   }
}
void ctlToolMenuCaption.on_change()
{
   if (gChangingConfiguration==1) return;
   //p_style=PSCH_AUTO2STATE;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetMenuCaption(gProjectHandle, GetTargetOrRuleNode(config), p_text);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].MenuCaption=p_text;
      }
   } else {
      _ProjectSet_TargetMenuCaption(gProjectHandle, GetTargetOrRuleNode(), ctlToolMenuCaption.p_text);
   }
}

void ctlToolAdvanced.lbutton_up()
{
   _str config_to_use=getCurrentConfig();
   if (config_to_use:==PROJ_ALL_CONFIGS) {
      // pick the first config at random (rather than trying to do some sort of OR of the commands
      config_to_use=gConfigList[0];
   }

   int Node=GetTargetOrRuleNode(config_to_use);

   // build the list of commands
   _str cmds[];
   _ProjectGet_TargetAdvCmd(gProjectHandle,Node,cmds);

   // build the list of tools
   typeless tools[];
   _ProjectGet_Targets(gProjectHandle,tools,config_to_use);    // set node id's

   // get the names
   int tool_index;
   for (tool_index=0;tool_index<tools._length();++tool_index) {
      tools[tool_index]=_xmlcfg_get_attribute(gProjectHandle,tools[tool_index],'Name');
   }

   _str result=show('-modal _adv_project_command_form',
                    cmds,
                    tools,
                    gConfigList,
                    false);

   if (result:=='') {
      return;
   }

   cmds=_param1;

   if (getCurrentConfig():==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetAdvCmd(gProjectHandle,GetTargetOrRuleNode(config),cmds);
      }
   } else {
      _ProjectSet_TargetAdvCmd(gProjectHandle,Node,cmds);
   }
}

void ctlToolCmdLine.on_change()
{
   if (gChangingConfiguration==1) return;
   // Don't allow the command to be -
   //projectToolList[toolIndex].cmd=(ctlToolCmdLine.p_text=="-")?"":ctlToolCmdLine.p_text;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_TargetCmdLine(gProjectHandle, GetTargetOrRuleNode(config), p_text);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].Exec_CmdLine=p_text;
      }
      TargetName := GetTargetName();
      gAllConfigsInfo.TargetInfo:[lowcase(TargetName)].Exec_CmdLine=p_text;
   } else {
      _ProjectSet_TargetCmdLine(gProjectHandle, GetTargetOrRuleNode(), p_text);
   }
   //updateShowOnMenuOptions(gProjectInfo2.ProjectSettings:[GetConfigText()].ToolInfo[toolIndex].hideOptions);
}

void ctlRunFromDir.on_change()
{
   if (gChangingConfiguration==1) return;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      // Do not save "Run From Dir" setting for all configs if it is not set.
      if (p_text != "" || gAllConfigsInfo.TargetInfo:[GetTargetName()].RunFromDir != null) {
         foreach (auto config in gConfigList) {
            _ProjectSet_TargetRunFromDir(gProjectHandle, GetTargetOrRuleNode(config), p_text);
            gAllConfigsInfo.TargetInfo:[GetTargetName()].RunFromDir=p_text;
         }
      }
   } else {
      _ProjectSet_TargetRunFromDir(gProjectHandle, GetTargetOrRuleNode(), p_text);
   }
}

void ctlLibraries.on_change()
{
   if (gChangingConfiguration==1) return;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_DisplayLibsList(gProjectHandle, config, p_text);
      }
      gAllConfigsInfo.Libs=p_text;
   } else {
      _ProjectSet_DisplayLibsList(gProjectHandle, getCurrentConfig(), p_text);
   }
}

static void GetTargetNodeMaybeAddForAllConfigs(int handle, _str target, _str command="",_str caption="")
{
   target = _Capitalize(target);
   if (gAllConfigsInfo.TargetInfo._indexin(target)) {
      return;
   }
   foreach (auto config in gConfigList) {
      targetIndex := _ProjectGet_TargetNode(handle, target, config);
      if (targetIndex > 0) return;
   }
   foreach (config in gConfigList) {
      GetTargetNodeMaybeAdd(handle, target, config, command, caption);
   }
   PROJECT_TARGET_INFO targetInfo;
   targetInfo.Exec_CmdLine=command;
   targetInfo.MenuCaption=(caption=="")? target:caption;
   targetInfo.Name=target;
   gAllConfigsInfo.TargetInfo:[target] = targetInfo;
   ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
}

static int GetTargetNodeMaybeAdd(int handle,_str target,_str config,_str command="",_str caption="")
{
   targetIndex := _ProjectGet_TargetNode(handle,target,config);
   if (targetIndex < 0) {
      target = _Capitalize(target);
      if (caption=="") caption = _Capitalize(target);
      _ProjectAdd_Target(handle,target,command,caption,config,"","");
      targetIndex = _ProjectGet_TargetNode(handle,target,config);
   }
   return targetIndex;
}

void ctlProgramDir.on_change()
{
   if (gChangingConfiguration==1) return;
   foreach (auto targetName in "debug execute") {
      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         // Do not save "Run From Dir" setting for all configs if it is not set.
         GetTargetNodeMaybeAddForAllConfigs(gProjectHandle,targetName);
         if (gAllConfigsInfo.TargetInfo._indexin(targetName)) {
            if (p_text != "" || gAllConfigsInfo.TargetInfo:[targetName].RunFromDir != null) {
               foreach (auto config in gConfigList) {
                  targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, config);
                  _ProjectSet_TargetRunFromDir(gProjectHandle, targetIndex, p_text);
                  gAllConfigsInfo.TargetInfo:[targetName].RunFromDir=p_text;
               }
            }
         }
      } else {
         targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, GetConfigText());
         _ProjectSet_TargetRunFromDir(gProjectHandle, targetIndex, p_text);
      }
   }
}

void ctlProgramName.on_change()
{
   if (gChangingConfiguration==1) return;
   programName := ctlProgramName.p_text;
   programArgs := ctlProgramArgs.p_text;
   executeName := programName;
   if (programArgs != "") {
      programName :+= " " :+ programArgs;
   }

   targetName := "execute";
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      // Do not save the execute command setting for all configs if it is not set.
      GetTargetNodeMaybeAddForAllConfigs(gProjectHandle,targetName);
      if (gAllConfigsInfo.TargetInfo._indexin(targetName)) {
         if (programName != "" || gAllConfigsInfo.TargetInfo:[targetName].RunFromDir != null) {
            foreach (auto config in gConfigList) {
               targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, config);
               _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, programName);
               gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine=programName;
            }
         }
      }
   } else {
      targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, "execute", GetConfigText());
      _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, programName);
   }

   targetName = "debug";
   programName = ctlProgramName.p_text;
   programArgs = ctlProgramArgs.p_text;
   programType := "";

   vsdebugio_port := def_debug_vsdebugio_port;
   if (vsdebugio_port == '') vsdebugio_port = 8000;

   if (!ctlUseOther.p_value) {
      commandLine := programName;
      if (ctlUseLLDB.p_value || ctlUseGDB.p_value) {

         // add vsdebugio to the debugger command line
         vsdebugio_command := "\"%(VSLICKBIN1)vsdebugio\"";
         commandLine = vsdebugio_command " -port " vsdebugio_port " -prog " programName;

      } else if (ctlUseJDWP.p_value) {

         // set up command line to invoke java or appletviewer in debug mode
         java_command := executeName;
         if (java_command == "") {
            java_command =  get_java_from_settings_or_java_home();
         }
         java_command :+= " -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=" :+ vsdebugio_port;
         program_path := _strip_filename(programName, 'N');
         program_name := _strip_filename(programName, 'P');
         if (_get_extension(program_name) == "class") {
            program_name = _strip_filename(program_name, 'E');
         }
         class_path := "%cp";
         if (program_path != "") {
            class_path = program_path :+ ":" :+ class_path;
         }
         if (class_path != "") {
            java_command :+= " -classpath \"" :+ class_path :+ "\"";
         }
         java_command :+= " " :+ program_name;
         commandLine = java_command;

      } else if (ctlUseMono.p_value) {

         // set up command line to invoke java or appletviewer in debug mode
         mono_command := executeName;
         if (mono_command == "") {
            mono_command =  get_mono_from_settings_or_mono_home();
         }
         mono_command :+= " --debugger-agent=\"transport=dt_socket,server=y,suspend=y,address=" :+ vsdebugio_port :+ "\"";
         program_path := _strip_filename(programName, 'N');
         program_name := _strip_filename(programName, 'P');
         //class_path := "%cp";
         //if (program_path != "") {
         //   class_path = program_path :+ ":" :+ class_path;
         //}
         //if (class_path != "") {
         //   mono_command :+= " -classpath \"" :+ class_path :+ "\"";
         //}
         mono_command :+= " " :+ program_name;
         commandLine = mono_command;

      } else if (ctlUseWinDBG.p_value) {

         // set up command line for WinDBG debugger
         programType = "Slick-C";
         commandLine = "vcproj_windbg_debug " programName;

      } else if (ctlUsePerl.p_value) {

         // set up command line for Perl debugger
         programType = "Slick-C";
         commandLine = "perl_debug " :+ programName;

      } else if (ctlUsePython.p_value) {

         // set up command line for Python debugger
         programType = "Slick-C";
         commandLine = "python_debug " :+ programName;

      } else if (ctlUseRuby.p_value) {

         // set up command line for Ruby debugger
         programType = "Slick-C";
         commandLine = "ruby_debug " :+ programName;

      } else if (ctlUsePHP.p_value) {

         // set up command line for PHP/Xdebug debugger
         programType = "Slick-C";
         commandLine = "php_debug " :+ programName;
      }

      // tack on arguments if we have them
      if (programArgs != "") {
         commandLine :+= " " :+ programArgs;
      }

      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         // Do not save the execute command setting for all configs if it is not set.
         GetTargetNodeMaybeAddForAllConfigs(gProjectHandle,targetName);
         if (gAllConfigsInfo.TargetInfo._indexin(targetName)) {
            if (programName != "" || gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine != null) {
               foreach (auto config in gConfigList) {
                  targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, config);
                  _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, commandLine, programType);
                  gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine=commandLine;
                  gAllConfigsInfo.TargetInfo:[targetName].Exec_Type=programType;
               }
            }
         }
      } else {
         // save command line settings for the current config
         targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, GetConfigText());
         _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, commandLine, programType);
         gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine=commandLine;
         gAllConfigsInfo.TargetInfo:[targetName].Exec_Type=programType;
      }
   }
}

void ctldbgDebugger.on_change()
{
   if (gChangingConfiguration==1) return;
   targetName := "debug";
   command_line := _maybe_quote_filename(ctldbgDebugger.p_text);
   if (command_line != "" && ctldbgOtherDebuggerOptions.p_text != "") {
      command_line :+= " " :+ ctldbgOtherDebuggerOptions.p_text;
   }
   if (gChangingConfiguration==1) return;
   if (ctlUseOther.p_value == 0) return;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      // Do not save "Run From Dir" setting for all configs if it is not set.
      GetTargetNodeMaybeAddForAllConfigs(gProjectHandle,targetName);
      if (gAllConfigsInfo.TargetInfo._indexin(targetName)) {
         if (command_line != "" || gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine != null) {
            foreach (auto config in gConfigList) {
               targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, config);
               _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, command_line);
               gAllConfigsInfo.TargetInfo:[targetName].Exec_CmdLine = command_line;
            }
         }
      }
   } else {
      targetIndex := GetTargetNodeMaybeAdd(gProjectHandle, targetName, GetConfigText());
      _ProjectSet_TargetCmdLine(gProjectHandle, targetIndex, command_line);
   }
}

void ctlLinkOrder.lbutton_up()
{
   _str libList = show('-modal _link_order_form',ctlLibraries.p_text);

   if (libList :!= '') {
      // pressing OK with no libraries will return
      // PROJECT_OBJECTS instead of ''
      //
      // This should invoke an on_change event which will copy
      // the new value into the options structure.
      if (libList :== PROJECT_OBJECTS) {
         ctlLibraries.p_text = '';
      } else {
         ctlLibraries.p_text = libList;
      }
   }
}

void ctlCommandIsSlickCMacro.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   target := GetTargetName();
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         node := GetTargetOrRuleNode(config);

         _ProjectSet_TargetType(gProjectHandle, node, (p_value)?'Slick-C':'');
         if (p_value) {
            _ProjectSet_TargetCaptureOutputWith(gProjectHandle, node, '');
            gAllConfigsInfo.TargetInfo:[target].CaptureOutputWith='';
            _ProjectSet_TargetClearProcessBuffer(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].ClearProcessBuffer=0;
            _ProjectSet_TargetBuildFirst(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].BuildFirst=0;
            _ProjectSet_TargetVerbose(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].Verbose=0;
            _ProjectSet_TargetBeep(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].Beep=0;
            _ProjectSet_TargetThreadDeps(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].ThreadDeps=0;
            _ProjectSet_TargetThreadCompiles(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].ThreadCompiles=0;
            _ProjectSet_TargetTimeBuild(gProjectHandle, node, false);
            gAllConfigsInfo.TargetInfo:[target].TimeBuild=0;

            // if the target is 'build', then we must also loop thru all targets in
            // this config, disabling buildfirst because buildfirst is not allowed when
            // the build target is a slickc macro
            if(strieq(target, "build")) {
               _str targetNodeList[] = null;
               _ProjectGet_Targets(gProjectHandle, targetNodeList, config);
               int k;
               for(k = 0; k < targetNodeList._length(); k++) {
                  _ProjectSet_TargetBuildFirst(gProjectHandle, (int)targetNodeList[k], false);
               }
            }
         }
      }

   } else {
      node := GetTargetOrRuleNode();
      _ProjectSet_TargetType(gProjectHandle, node, (p_value)?'Slick-C':'');
      if (p_value) {
         _ProjectSet_TargetCaptureOutputWith(gProjectHandle, node, '');
         _ProjectSet_TargetClearProcessBuffer(gProjectHandle, node, false);
         _ProjectSet_TargetBuildFirst(gProjectHandle, node, false);
         _ProjectSet_TargetVerbose(gProjectHandle, node, false);
         _ProjectSet_TargetBeep(gProjectHandle, node, false);

         // if the target is 'build', then we must also loop thru all targets in
         // this config, disabling buildfirst because buildfirst is not allowed when
         // the build target is a slickc macro
         if(strieq(target, "build")) {
            _str config=GetConfigText();
            _str targetNodeList[] = null;
            _ProjectGet_Targets(gProjectHandle, targetNodeList, config);
            int k;
            for(k = 0; k < targetNodeList._length(); k++) {
               _ProjectSet_TargetBuildFirst(gProjectHandle, (int)targetNodeList[k], false);
            }
         }
      }
   }

   if (p_value) {
      ctlToolCaptureOutput.p_enabled=false;
      ctlToolOutputToConcur.p_enabled=false;
      ctlToolClearProcessBuf.p_enabled=false;
      ctlBuildFirst.p_enabled=false;
      ctlToolVerbose.p_enabled=false;
      ctlToolBeep.p_enabled=false;
      ctlThreadDeps.p_enabled=false;
      ctlThreadCompiles.p_enabled=false;
      ctlTimeBuild.p_enabled=false;

      ctlToolCaptureOutput.p_value = 0;
      ctlToolOutputToConcur.p_value = 0;
      ctlToolClearProcessBuf.p_value = 0;
      ctlBuildFirst.p_value=0;
      ctlToolVerbose.p_value=0;
      ctlToolBeep.p_value=0;
      ctlThreadDeps.p_value=0;
      ctlThreadCompiles.p_value=0;
      ctlTimeBuild.p_value=0;
   }else{
      ctlToolCaptureOutput.p_enabled=true;

      if (strieq(target,'build') || strieq(target,'rebuild') ) {
         ctlToolVerbose.p_enabled=true;
         ctlToolBeep.p_enabled=true;
         ctlThreadDeps.p_enabled=true;
         ctlThreadCompiles.p_enabled=true;
         ctlTimeBuild.p_enabled=true;
      } else {
         ctlToolVerbose.p_value=0;
         ctlToolVerbose.p_enabled=false;
         ctlToolBeep.p_value=0;
         ctlToolBeep.p_enabled=false;
         ctlThreadDeps.p_enabled=false;
         ctlThreadCompiles.p_enabled=false;
         ctlTimeBuild.p_enabled=false;
         ctlThreadDeps.p_value=0;
         ctlThreadCompiles.p_value=0;
         ctlTimeBuild.p_value=0;
      }

      switch (lowcase(target)) {
         case "build":
         case "rebuild":
         case "compile":
         case "link":
            ctlBuildFirst.p_enabled = false;
            ctlBuildFirst.p_value = 0;
            break;
         default:
            ctlBuildFirst.p_enabled = true;
      }
   }

}
void ctlCompilerList.on_change(int reason)
{
   if (gChangingConfiguration==1) return;

   // update the system include directories
   if (ctlUserIncludesList.p_EditInPlace) {
      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         if (gAllConfigsInfo.IncludesMatchForAllConfigs) {
            ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                          _ProjectGet_AssociatedIncludes(gProjectHandle, false));

         } else {
            ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                          MESSAGE_ALLCONFIG_INCLUDES_MISMATCH);
         }
      } else {
         ctlUserIncludesList._TreeSetDelimitedItemList(_ProjectGet_IncludesList(gProjectHandle, GetConfigText()),
                                                       PATHSEP, false,
                                                       _ProjectGet_AssociatedIncludes(gProjectHandle, false, GetConfigText()));
      }
   }

   if (reason == CHANGE_CLINE && ctlCompilerList.p_enabled) {
      compiler_name := ctlCompilerList.p_text;
      // strip off actual compiler name if set to 'Latest Version(name)'
      if (substr(compiler_name,1,length(COMPILER_NAME_LATEST)):==COMPILER_NAME_LATEST) {
         compiler_name=COMPILER_NAME_LATEST;
      } else if (substr(compiler_name,1,length(COMPILER_NAME_DEFAULT)):==COMPILER_NAME_DEFAULT) {
         compiler_name=COMPILER_NAME_DEFAULT;
      } else if (compiler_name == MESSAGE_ALLCONFIG_SETTING_MISMATCH) {
         compiler_name="";
      }

      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         if (ctlCompilerList.p_text != "" && ctlCompilerList.p_text != MESSAGE_ALLCONFIG_SETTING_MISMATCH) {
            foreach (auto config in gConfigList) {
               _ProjectSet_CompilerConfigName(gProjectHandle, compiler_name,config);
               gAllConfigsInfo.CompilerConfigName=compiler_name;
            }
         }
      } else {
         _ProjectSet_CompilerConfigName(gProjectHandle, compiler_name,GetConfigText());
      }
      gUpdateTags=true;
   }
}

void ctltagscombo.on_change(int reason, int index = 0)
{
   if (gChangingConfiguration==1) return;
   if (reason == CHANGE_CLINE) {
      option := index-1;
      if (option<0 || option>=gTagsComboList._length()) {
         return;
      }
      taggingOption := gTagsComboList[option];
      _ProjectSet_TaggingOption(gProjectHandle, taggingOption);
   }
}

void ctlToolSaveCombo.on_change(int reason, int index = 0)
{
   if (gChangingConfiguration==1) return;
   if (reason == CHANGE_CLINE) {
      int option= index-1;
      if (option<0 || option>=gSaveComboList._length()) {
         return;
      }
      _str SaveOption=gSaveComboList[option];
      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         foreach (auto config in gConfigList) {
            _ProjectSet_TargetSaveOption(gProjectHandle, GetTargetOrRuleNode(config), SaveOption);
            gAllConfigsInfo.TargetInfo:[GetTargetName()].SaveOption=SaveOption;
         }
      } else {
         _ProjectSet_TargetSaveOption(gProjectHandle, GetTargetOrRuleNode(), SaveOption);
      }
   }
}

void ctlToolHideCombo.on_change(int reason, int index = 0)
{
   if (gChangingConfiguration==1) return;
   if (reason == CHANGE_CLINE) {
      int option=index-1;
      if (option<0 || option>gShowComboList._length()) {
         return;
      }
      _str ShowOnMenu=gShowComboList[option];
      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         foreach (auto config in gConfigList) {
            _ProjectSet_TargetShowOnMenu(gProjectHandle, GetTargetOrRuleNode(config), ShowOnMenu);
            gAllConfigsInfo.TargetInfo:[GetTargetName()].ShowOnMenu=ShowOnMenu;
         }
      } else {
         _ProjectSet_TargetShowOnMenu(gProjectHandle, GetTargetOrRuleNode(), ShowOnMenu);
      }
   }
}

//Returns the text in the ctlCurConfig.p_text, unless this is an extension
//project.  Then the proper extension(from gProjectName) is returned.
static _str GetConfigText()
{
   return(ctlCurConfig.p_text);
}

/**
 */
static bool shouldEnableBuildFirst(int handle, _str configName)
{
   if(configName == PROJ_ALL_CONFIGS) {
      // get list of configs
      _str configList[] = null;
      _ProjectGet_ConfigNames(handle, configList);

      // recursively call this function for each config
      int i;
      for(i = 0; i < configList._length(); i++) {
         if(!shouldEnableBuildFirst(handle, configList[i])) {
            // found a case where it is false so buildfirst *must* be
            // disabled in the all configs case
            return false;
         }
      }
   } else {
      // find target node for config
      int targetNode = _ProjectGet_TargetNode(handle, "Build", configName);
      if(targetNode < 0) {
         // 'build' target not found so buildfirst is not valid
         return false;
      }

      // check to see if build target is a slickc macro
      if(_ProjectGet_TargetType(handle, targetNode) == "Slick-C") {
         return false;
      }
   }

   // no reason not to enable it
   return true;
}

static int TagsOptionToLine(_str TagsOption)
{
   for (i:=0; i<gTagsComboList._length(); ++i) {
      if (strieq(gTagsComboList[i],TagsOption)) {
         return(i+1);
      }
   }
   return(1);
}
int ProjectFormSaveOptionToLine(_str SaveOption)
{
   int i;
   for (i=0;i<gSaveComboList._length();++i) {
      if (strieq(gSaveComboList[i],SaveOption)) {
         return(i+1);
      }
   }
   return(1);
}
static int ShowOptionToLine(_str SaveOption)
{
   for (i:=0;i<gSaveComboList._length();++i) {
      if (strieq(gShowComboList[i],SaveOption)) {
         return(i+1);
      }
   }
   return(1);
}
// Desc: Make sure tagging options are consistent with each other.
static void updateTaggingOption(_str taggingOption)
{
   // Change the radio buttons values.
   if(taggingOption == "") {
      ctltagscombo._lbdeselect_all();
      ctltagscombo.p_line=1;
      ctltagscombo._lbselect_line();
      ctltagscombo.p_text="";
   } else {
      ctltagscombo._lbdeselect_all();
      ctltagscombo.p_line=TagsOptionToLine(taggingOption);
      ctltagscombo._lbselect_line();
      ctltagscombo.p_text=ctltagscombo._lbget_text();
   }
}

// Desc: Make sure save options are consistent with each other.
static void updateSaveOptions(_str saveOptions)
{
   // Change the radio buttons values.
   if(saveOptions == '') {
      ctlToolSaveCombo._lbdeselect_all();
      ctlToolSaveCombo.p_line=1;
      ctlToolSaveCombo._lbselect_line();
      ctlToolSaveCombo.p_text="";
   } else {
      ctlToolSaveCombo._lbdeselect_all();
      ctlToolSaveCombo.p_line=ProjectFormSaveOptionToLine(saveOptions);
      ctlToolSaveCombo._lbselect_line();
      ctlToolSaveCombo.p_text=ctlToolSaveCombo._lbget_text();
   }
}

static void updateShowOnMenuOptions(_str ShowOnMenu)
{
   // Change the radio buttons values.
   if(ShowOnMenu == '') {
      ctlToolHideCombo._lbdeselect_all();
      ctlToolHideCombo.p_line=1;
      ctlToolHideCombo._lbselect_line();
      ctlToolHideCombo.p_text="";
   } else {
      ctlToolHideCombo._lbdeselect_all();
      ctlToolHideCombo.p_line=ShowOptionToLine(ShowOnMenu);
      ctlToolHideCombo._lbselect_line();
      ctlToolHideCombo.p_text=ctlToolHideCombo._lbget_text();
   }
}


_str ctlconfigurations.lbutton_up()
{
   // we want to manage our configurations
   typeless result=show('-modal _project_config_form',gProjectHandle,gIsProjectTemplate,gIsExtensionProject);
   if (result=='') return('');

   gSetActiveConfigTo=_maybe_quote_filename(_param1);
   if (result==0) return(result);

   // save what was selected before
   _str origconfig=GetConfigText();

   // add all the configs back into the list
   _ProjectGet_ConfigNames(gProjectHandle,gConfigList);
   ctlCurConfig._lbclear();
   foreach (auto config in gConfigList) {
      ctlCurConfig._lbadd_item(config);
   }

   if (ctlCurConfig.p_Noflines) {
      ctlCurConfig._lbbottom();
      ctlCurConfig._lbadd_item(PROJ_ALL_CONFIGS);
   } else {
      _message_box('ERROR: project file has no configurations');
   }

   ctlCurConfig._lbtop();
   if (ctlCurConfig._lbfind_and_select_item(origconfig)) {
      ctlCurConfig._lbbottom();
      ctlCurConfig.p_text=ctlCurConfig._lbget_text();
   }

   return(result);
}

_str _AppTypeList_hashtab:[] = {
   APPTYPE_APPLICATION=>'Application - requires java.exe to run',
   APPTYPE_APPLET=>'Applet - runs in a web browser',
   APPTYPE_CUSTOM=>'Custom - command lines for execute and debug',
};
static _str _GetAppTypeListDescriptions(_str AppTypeList)
{
   _str list=AppTypeList;
   AppTypeList='';
   for (;;) {
      name := "";
      parse list with name','list;
      if (name=='') {
         return(AppTypeList);
      }
      name=_GetAppTypeName(name);
      if (_AppTypeList_hashtab._indexin(name)) {
         name=_AppTypeList_hashtab:[name];
      }
      if (AppTypeList=='') {
         AppTypeList=name;
      } else {
         strappend(AppTypeList,','name);
      }
   }
}
static _str _GetAppTypeDescription(_str AppTypeList,_str AppType)
{
   thisname := _GetAppTypeName(AppType);
   _str list=AppTypeList;
   for (;;) {
      description := "";
      parse list with description','list;
      if (description=='') {
         return(thisname);
      }
      name := _GetAppTypeName(description);
      if (strieq(name,thisname)) {
         return(description);
      }
   }
}
void ctlAppType.on_change(int reason)
{
   if (!ctlAppType.p_visible) return;
   if (gChangingConfiguration==1) return;

   AppType := _GetAppTypeName(p_text);
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      /*for (i=0;i<gConfigList._length();++i) {
         config=gConfigList[i];
         _ProjectSetAppType(gProjectHandle,AppType,config);
      } */
      _ProjectSetAppType(gProjectHandle,AppType);
   }else{
      _ProjectSetAppType(gProjectHandle,AppType,GetConfigText());
   }

   ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
}

static void setTriStateVSBuildOption(bool enable, int v)
{
   p_enabled=enable;
   if (v==2) {
      p_style=PSCH_AUTO3STATEB;
   }
   p_value= v;
}

void ctlToolTree.on_change(int reason,int index)
{
   // if this is not a CHANGE_SELECTED event, ignore it
   if(reason != CHANGE_SELECTED) return;

   // if the index is 0, it is the root node and the tree is empty
   if(index <= 0) return;

   // From the tool name, find out the tool index and
   // init the text boxes:
   TargetName := GetTargetName();

   // check to see if this is a target or a rule based on depth
   isRule := false;
   parentTargetName := "";
   if(ctlToolTree._TreeGetDepth(index) == 2) {
      isRule = true;
      parentTargetName = lowcase(ctlToolTree._TreeGetCaption(ctlToolTree._TreeGetParentIndex(index)));
   }

   Verbose := 0;
   Beep := 0;
   ThreadDeps := 0;
   ThreadCompiles := 0;
   TimeBuild := 0;
   _str CaptureOutputWith=0;
   ClearProcessBuffer := 0;
   MenuCaption := "";
   RunInXterm := 0;
   ClassPath := "";
   SaveOption := "";
   ShowOnMenu := "";
   RunFromDir := "";
   typeless Deletable=false;
   Exec_Type := "";
   EnableBuildFirst := 0;
   typeless BuildFirst=0;
   Dialog := "";

   _str cmdLine;
   _str otherOptions;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      if(isRule) {
         cmdLine= gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Exec_CmdLine;
         otherOptions= gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Exec_OtherOptions;
         Verbose=0;
         Beep=0;
         ThreadDeps=0;
         ThreadCompiles=0;
         TimeBuild=0;
         CaptureOutputWith=0;
         ClearProcessBuffer=0;
         MenuCaption="";
         RunInXterm=0;
         ClassPath=gAllConfigsInfo.ClassPath;
         SaveOption=VPJ_SAVEOPTION_SAVENONE;
         ShowOnMenu=VPJ_SHOWONMENU_NEVER;
         RunFromDir=gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].RunFromDir;
         Deletable=gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Deletable;
         Exec_Type=gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Exec_Type;
         EnableBuildFirst=0;
         BuildFirst=0;
         Dialog=gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Dialog;
      } else {
         cmdLine= gAllConfigsInfo.TargetInfo:[TargetName].Exec_CmdLine;
         otherOptions= gAllConfigsInfo.TargetInfo:[TargetName].Exec_OtherOptions;
         Verbose=gAllConfigsInfo.TargetInfo:[TargetName].Verbose;
         Beep=gAllConfigsInfo.TargetInfo:[TargetName].Beep;
         ThreadDeps=gAllConfigsInfo.TargetInfo:[TargetName].ThreadDeps;
         ThreadCompiles=gAllConfigsInfo.TargetInfo:[TargetName].ThreadCompiles;
         TimeBuild=gAllConfigsInfo.TargetInfo:[TargetName].TimeBuild;
         CaptureOutputWith=gAllConfigsInfo.TargetInfo:[TargetName].CaptureOutputWith;
         ClearProcessBuffer=gAllConfigsInfo.TargetInfo:[TargetName].ClearProcessBuffer;
         MenuCaption=gAllConfigsInfo.TargetInfo:[TargetName].MenuCaption;
         RunInXterm=gAllConfigsInfo.TargetInfo:[TargetName].RunInXterm;
         ClassPath=gAllConfigsInfo.ClassPath;
         SaveOption=gAllConfigsInfo.TargetInfo:[TargetName].SaveOption;
         ShowOnMenu=gAllConfigsInfo.TargetInfo:[TargetName].ShowOnMenu;
         RunFromDir=gAllConfigsInfo.TargetInfo:[TargetName].RunFromDir;
         Deletable=gAllConfigsInfo.TargetInfo:[TargetName].Deletable;
         Exec_Type=gAllConfigsInfo.TargetInfo:[TargetName].Exec_Type;
         EnableBuildFirst=gAllConfigsInfo.TargetInfo:[TargetName].EnableBuildFirst;
         BuildFirst=gAllConfigsInfo.TargetInfo:[TargetName].BuildFirst;
         Dialog=gAllConfigsInfo.TargetInfo:[TargetName].Dialog;
      }
   } else {
      // find the target node, taking care to check if it is a target or a rule
      targetNode := -1;
      if(isRule) {
         targetNode = _ProjectGet_RuleNode(gProjectHandle, parentTargetName, TargetName, GetConfigText());

         cmdLine=_ProjectGet_TargetCmdLine(gProjectHandle, targetNode);
         otherOptions=_ProjectGet_TargetOtherOptions(gProjectHandle, targetNode);
         Verbose=0;
         Beep=0;
         ThreadDeps=0;
         ThreadCompiles=0;
         TimeBuild=0;
         CaptureOutputWith=0;
         ClearProcessBuffer=0;
         MenuCaption="";
         RunInXterm=0;
         ClassPath=_ProjectGet_ClassPathList(gProjectHandle, GetConfigText());
         SaveOption=VPJ_SAVEOPTION_SAVENONE;
         ShowOnMenu=VPJ_SHOWONMENU_NEVER;
         RunFromDir=_ProjectGet_TargetRunFromDir(gProjectHandle, targetNode);
         Deletable=_ProjectGet_TargetDeletable(gProjectHandle, targetNode);
         Exec_Type=_ProjectGet_TargetType(gProjectHandle, targetNode);
         EnableBuildFirst=0;
         BuildFirst=0;
         Dialog=_ProjectGet_TargetDialog(gProjectHandle, targetNode);
      } else {
         targetNode = _ProjectGet_TargetNode(gProjectHandle,TargetName,GetConfigText());

         cmdLine=_ProjectGet_TargetCmdLine(gProjectHandle, targetNode);
         otherOptions=_ProjectGet_TargetOtherOptions(gProjectHandle, targetNode);
         Verbose=(int)_ProjectGet_TargetVerbose(gProjectHandle, targetNode);
         Beep=(int)_ProjectGet_TargetBeep(gProjectHandle, targetNode);
         ThreadDeps=(int)_ProjectGet_TargetThreadDeps(gProjectHandle, targetNode);
         ThreadCompiles=(int)_ProjectGet_TargetThreadCompiles(gProjectHandle, targetNode);
         TimeBuild=(int)_ProjectGet_TargetTimeBuild(gProjectHandle, targetNode);
         CaptureOutputWith=_ProjectGet_TargetCaptureOutputWith(gProjectHandle, targetNode);
         ClearProcessBuffer=(int)_ProjectGet_TargetClearProcessBuffer(gProjectHandle, targetNode);
         MenuCaption=_ProjectGet_TargetMenuCaption(gProjectHandle, targetNode);
         RunInXterm=(int)_ProjectGet_TargetRunInXterm(gProjectHandle, targetNode);
         ClassPath=_ProjectGet_ClassPathList(gProjectHandle, GetConfigText());
         SaveOption=_ProjectGet_TargetSaveOption(gProjectHandle, targetNode);
         ShowOnMenu=_ProjectGet_TargetShowOnMenu(gProjectHandle, targetNode);
         RunFromDir=_ProjectGet_TargetRunFromDir(gProjectHandle, targetNode);
         Deletable=_ProjectGet_TargetDeletable(gProjectHandle, targetNode);
         Exec_Type=_ProjectGet_TargetType(gProjectHandle, targetNode);
         EnableBuildFirst=(int)_ProjectGet_TargetEnableBuildFirst(gProjectHandle, targetNode);
         BuildFirst=_ProjectGet_TargetBuildFirst(gProjectHandle, targetNode);
         Dialog=_ProjectGet_TargetDialog(gProjectHandle, targetNode);
      }
   }
   ctlToolMenuCaption.p_ReadOnly= false;  // temporarily turn off read-only so that we can update caption

   // rules are special case so disable controls as needed
   if(isRule) {
      // rules are not currently deletable
      Deletable=false;

      // cannot currently create new rules thru gui
      ctlToolNew.p_enabled = false;

      // cannot reorder rules
      ctlToolUp.p_enabled = ctlToolDown.p_enabled = false;

      // cannot apply advanced items to rules
      ctlToolAdvanced.p_enabled = false;

      // disable menu caption
      ctlToolMenuCaption.p_enabled = ctlMenuCaptionLabel.p_enabled = false;

      // disable run from dir
      ctlRunFromDirLabel.p_enabled = false;
      ctlRunFromDir.p_enabled = false;
      ctlBrowseRunFrom.p_enabled = false;
      ctlRunFromButton.p_enabled = false;

      // disable save and show on menu combobox
      ctlToolSaveCombo.p_enabled = false;
      ctlToolHideCombo.p_enabled = false;

      // disable capture output
      ctlToolCaptureOutput.p_enabled = false;

   } else {
      ctlToolNew.p_enabled = true;

      // this if mimics the behavior of ctlCurConfig.on_change() for the up/down buttons
      if(getCurrentConfig() != PROJ_ALL_CONFIGS || gAllConfigsInfo.TargetList != null) {
         ctlToolUp.p_enabled = ctlToolDown.p_enabled = ctlToolAdvanced.p_enabled = true;
      }

      // enable menu caption
      ctlToolMenuCaption.p_enabled = ctlMenuCaptionLabel.p_enabled = true;

      // enable run from dir
      ctlRunFromDirLabel.p_enabled = true;
      ctlRunFromDir.p_enabled = true;
      ctlBrowseRunFrom.p_enabled = true;
      ctlRunFromButton.p_enabled = true;

      // enable save and show on menu combobox
      ctlToolSaveCombo.p_enabled = true;
      ctlToolHideCombo.p_enabled = true;

      // enable capture output
      ctlToolCaptureOutput.p_enabled = true;
   }

   if (strieq(TargetName,'build') || strieq(TargetName,'rebuild') ) {
      doEnable := (Exec_Type=='');
      ctlToolVerbose.setTriStateVSBuildOption(doEnable, Verbose);
      ctlToolBeep.setTriStateVSBuildOption(doEnable, Beep);
      ctlThreadDeps.setTriStateVSBuildOption(doEnable, ThreadDeps);
      ctlThreadCompiles.setTriStateVSBuildOption(doEnable, ThreadCompiles);
      ctlTimeBuild.setTriStateVSBuildOption(doEnable, TimeBuild);

   }else{
      ctlToolVerbose.p_value=0;
      ctlToolVerbose.p_enabled=false;
      ctlToolBeep.p_value=0;
      ctlToolBeep.p_enabled=false;
      ctlThreadDeps.p_value=0;
      ctlThreadDeps.p_enabled=false;
      ctlThreadCompiles.p_value=0;
      ctlThreadCompiles.p_enabled=false;
      ctlTimeBuild.p_value=0;
      ctlTimeBuild.p_enabled=false;
   }
   // If tool does not have a command line, we default a few things.
   // Otherwise just fill in.
   oldcc := false;
   if (cmdLine== "" || cmdLine==null) {
      oldcc=gChangingConfiguration;
      gChangingConfiguration=true;
      ctlToolCmdLine.p_text= "";
      gChangingConfiguration=oldcc;
   } else {
      oldcc=gChangingConfiguration;
      gChangingConfiguration=true;
      _str Text= cmdLine; //_ProjectReplaceOther(cmdLine,otherOptions);

      ctlToolCmdLine.p_text=Text;
      gChangingConfiguration=oldcc;

   }
   ctlToolMenuCaption.p_text= MenuCaption == null ? "" : MenuCaption;
   if (CaptureOutputWith==null) {
      ctlToolOutputToConcur.p_style=PSCH_AUTO3STATEB;
   }
   ctlToolOutputToConcur.p_value= (CaptureOutputWith!=null && strieq(CaptureOutputWith,'ProcessBuffer'))?1:0;

   if (CaptureOutputWith==null) {
      ctlToolCaptureOutput.p_style=PSCH_AUTO3STATEB;
      ctlToolCaptureOutput.p_value= 2;
   } else {
      ctlToolCaptureOutput.p_value= (CaptureOutputWith!='') ?1:0;
   }
   ctlToolOutputToConcur.p_enabled=(ctlToolCaptureOutput.p_value!=2);
   ctlToolClearProcessBuf.p_enabled=(ctlToolCaptureOutput.p_value==1);

   if (_isUnix()) {
      if (RunInXterm==2) {
         ctlRunInXterm.p_style=PSCH_AUTO3STATEB;
      }
      ctlRunInXterm.p_value= RunInXterm;
   }

   if (ClearProcessBuffer==2) {
      ctlToolClearProcessBuf.p_style=PSCH_AUTO3STATEB;
   }
   ctlToolClearProcessBuf.p_value= ClearProcessBuffer;

   updateSaveOptions(SaveOption);
   updateShowOnMenuOptions(ShowOnMenu);

   // Disable a few things for predefined tools:
   ctlToolDelete.p_enabled= (Deletable && ctlToolTree._TreeGetNumChildren(TREE_ROOT_INDEX)>1);

   // If not capturing output, disable output to process buffer and clear process
   // buffer toggle buttons.
   if (ctlToolCaptureOutput.p_value && ctlToolCaptureOutput.p_enabled) {
      if (captureOutputRequiresConcurrentProcess(TargetName,(cmdLine==null)?'':cmdLine)) {
         ctlToolOutputToConcur.p_enabled= false; //supportConcurrentProcessBuffer(projectToolList,toolIndex);
         ctlToolOutputToConcur.p_value=1;
         ctlToolOutputToConcur.call_event(ctlToolOutputToConcur,LBUTTON_UP,'W');
      } else {
         ctlToolOutputToConcur.p_enabled= true; //supportConcurrentProcessBuffer(projectToolList,toolIndex);
      }
      ctlToolClearProcessBuf.p_enabled= true;
      if (_isUnix()) {
         //This two commented out lines cause p_value to be set to zero when ctlToolCaptureOutput.p_value==2
         //ctlRunInXterm.p_value= 0;
         //ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
         //ctlRunInXterm.p_enabled= false;
      }
   } else {
      ctlToolOutputToConcur.p_enabled= false;
      ctlToolClearProcessBuf.p_enabled= false;
      if (_isUnix()) {
         ctlRunInXterm.p_enabled= true;
      }
   }
   if (ctlToolOutputToConcur.p_value /*&& ctlToolOutputToConcur.p_enabled*/) {
      ctlToolClearProcessBuf.p_enabled= true;
   } else {
      ctlToolClearProcessBuf.p_enabled= false;
      ctlToolClearProcessBuf.p_value= 0;
   }

   if(Exec_Type == "" && !isRule) {
      ctlToolCaptureOutput.p_enabled = true;
   } else {
      ctlToolCaptureOutput.p_enabled = false;
   }

   if (!ctlToolCaptureOutput.p_enabled && !ctlToolOutputToConcur.p_value) {
      ctlBuildFirst.p_enabled=false;
   } else {
      switch (lowcase(TargetName)) {
      case 'build':
      case 'rebuild':
      case 'compile':
      case 'link':
         ctlBuildFirst.p_enabled=false;
         break;
      default:
         ctlBuildFirst.p_enabled=(EnableBuildFirst!=0);

         // if 'Build' tool is a slickc macro, buildfirst cannot be enabled anywhere
         if(!shouldEnableBuildFirst(gProjectHandle, GetConfigText())) {
            ctlBuildFirst.p_enabled = false;
         }
         break;
      }
   }
   if (BuildFirst==2) {
      ctlBuildFirst.p_style=PSCH_AUTO3STATEB;
   }
   ctlBuildFirst.p_value= ctlBuildFirst.p_enabled ? BuildFirst : false;

   // enable the save options combo based on the buildfirst enabled and value settings
   if(isRule) {
      ctlToolSaveCombo.p_enabled = false;
   } else if(ctlBuildFirst.p_enabled) {
      ctlToolSaveCombo.p_enabled = !ctlBuildFirst.p_value;
   } else {
      ctlToolSaveCombo.p_enabled = true;
   }

   gDialog='';
   ctlcmdmessage.p_visible=false;
   ctlToolCmdLine.p_ReadOnly=false;
   ctlToolCmdLine.p_backcolor=0x80000005;
   ctlCommandIsSlickCMacro.p_enabled=false;
   if (Exec_Type==null) {
      ctlCommandIsSlickCMacro.p_style=PSCH_AUTO3STATEB;
      ctlCommandIsSlickCMacro.p_value=2;
   } else {
      ctlCommandIsSlickCMacro.p_style=PSCH_AUTO2STATE;
      ctlCommandIsSlickCMacro.p_value=(Exec_Type!=null && strieq(Exec_Type,'Slick-C'))?1:0;
   }

   ctlRunFromDir.p_text = RunFromDir == null ? "" : strip(RunFromDir,'B','"');

   // these dialogs no longer exist, so ignore them
   if (Dialog == GNUC_OPTS_DLG_DBG || Dialog == VCPP_OPTS_DLG_DBG) {
      Dialog = "";
   }

   if (Dialog==null || cmdLine==null) {
      ctlToolCmdLine.p_visible=false;
      ctlToolCmdLineButton.p_visible=false;
      ctlBrowseCmdLine.p_visible=false;
      ctlcommand_line_label.p_visible=false;
      ctlcmdmessage.p_caption=MESSAGE_ALLCONFIG_TOOLS_MISMATCH;
      ctlcmdmessage.p_visible=true;
      ctlcommand_options.p_visible=false;
   } else if (Dialog!='') {
      ctlcommand_options.p_visible=true;
      gDialog=Dialog;
      ctlcommand_line_label.p_visible=false;

      ctlToolCmdLine.p_visible=false;
      ctlToolCmdLineButton.p_visible=false;
      ctlBrowseCmdLine.p_visible=false;
      ctlcommand_line_label.p_visible=false;
      ctlcmdmessage.p_caption=MESSAGE_PRESS_OPTIONS_BUTTON;
      ctlcmdmessage.p_visible=true;
   }else{
      ctlcommand_options.p_visible=false;
      firstword := "";
      parse ctlToolCmdLine.p_text with firstword .;
      _str *p;
      p=gSpecialToolMessage._indexin(firstword);
      if (p) {
         ctlToolCmdLine.p_visible=false;
         ctlToolCmdLineButton.p_visible=false;
         ctlBrowseCmdLine.p_visible=false;
         ctlcommand_line_label.p_visible=false;
         ctlcmdmessage.p_caption=*p;
         ctlcmdmessage.p_visible=true;
      } else {
         ctlToolCmdLine.p_visible=true;
         ctlToolCmdLineButton.p_visible=true;
         ctlBrowseCmdLine.p_visible=true;
         ctlcommand_line_label.p_visible=true;

         // cannot select IsSlickCMacro if a dialog is specified
         ctlCommandIsSlickCMacro.p_enabled=true;
      }
   }
   /*if (ctlToolCmdLine.p_ReadOnly) {
      ctlToolCmdLine.p_backcolor=0x80000022;
   } */
}

_str ctlcommand_options.lbutton_up(_str DialogName='',_str ConfigName='')
{
   if (DialogName=='') {
      DialogName=gDialog;
   }
   Options := "";
   parse DialogName with DialogName Options;
   form_wid := p_active_form;
   PROJECT_CONFIG_INFO ProjectInfo:[];
   if (ConfigName=="") {
      ConfigName=GetConfigText();
   }

   int wid=show('-hidden -wh 'DialogName,gProjectHandle,Options,ConfigName,gProjectName,gIsProjectTemplate);
   //int wid=show('-hidden -wh 'DialogName,Options,&gAllConfigsInfo,gConfigList,GetConfigText(),gProjectName);
   result := "";
   if (wid) {
      //We do a modal wait on this dialog so that we can move the dialog over
      //slightly
      if (form_wid.p_visible) {
         //If the form is not visible, this came up from the javaoptions command
         //and we don't have to indent.
         //wid.p_x+=500;
         wid._show_entire_form();
      }
      wid.p_visible=true;
      result=_modal_wait(wid);
      if (result!='') {
         form_wid.ctlCurConfig.call_event(CHANGE_SELECTED,form_wid.ctlCurConfig,ON_CHANGE,'W');
         //SetIndirectCommands();
         //ctlCurConfig.call_event(CHANGE_CLINE,ctlToolTree,ON_CHANGE,'W');

         // trigger the on_change event so that the directory data that could have been
         // changed in some options forms will be updated.  the CHANGING_CONFIGURATION
         // variable must be set here because the tree will attempt to save any changes
         // that are made to its contents except during a configuration change.
         //CHANGING_CONFIGURATION = 1;
         //populateIncludesTrees();
         //CHANGING_CONFIGURATION = 0;
      }
   }
   return(result);
}


//-----------------------------------------------------------------------------------
void _opencancel.lbutton_up()
{
   fid := p_active_form;
   //_save_form_response();
   int value= _proj_prop_sstab.p_ActiveTab;
   _append_retrieve( _proj_prop_sstab, value );

   fid._delete_window('');
}

void _setMacroTextList(_str (&MacroCmdLines)[],int flags=EDC_INPUTINI)
{
   _lbclear();
   int i;
   for (i=0;i<MacroCmdLines._length();++i) {
      if (flags & EDC_INPUTINI) {
         insert_line(_ini_xlat_multiline(MacroCmdLines[i]));
      } else {
         insert_line(MacroCmdLines[i]);
      }
   }
   if (!p_Noflines) {
      insert_line('');
   }
   top();
   p_word_wrap_style &= (~WORD_WRAP_WWS);
}
void _setMacroText(_str input,int flags=EDC_INPUTINI)
{
   //if (flags=='') {
   //   flags=EDC_OUTPUTINI|EDC_INPUTINI;
   //}
   if (flags & EDC_INPUTINI) {
      input=_ini_xlat_multiline(input);
   }

   /*
   if (!sstIsControlExists("list1")) {
      sstSetProp("list1","p_text",input);
      return;
   }
   */
   _lbclear();
   input=input;
   for (;;) {
      if (input=='') break;
      _str line=_parse_line(input);
      insert_line(line);
   }
   if (!p_Noflines) {
      insert_line('');
   }
   top();
   p_word_wrap_style &= (~WORD_WRAP_WWS);
#if 0
   _lbclear();
   for (i=0;i<MacroCmdLines._length();++i) {
      if (flags & EDC_INPUTINI) {
         insert_line(_ini_xlat_multiline(MacroCmdLines[i]));
      } else {
         insert_line(MacroCmdLines[i]);
      }
   }
   if (!p_Noflines) {
      insert_line('');
   }
   top();
   p_word_wrap_style &= (~WORD_WRAP_WWS);
#endif
}

static int oncreateMacro()
{
   _str MacroCmdLines[];
   _ProjectGet_Macro(gProjectHandle,MacroCmdLines);
   list1._setMacroTextList(MacroCmdLines,0);
   return( 0 );
}
static void okMacro(bool &macrosChanged)
{
   text := "";

   list1._getMacroText(text,0);

   _str orig_text=_ProjectGet_MacroList(gProjectHandle);
   if (text!=orig_text) {
      _ProjectSet_MacroList(gProjectHandle,text);
      if (_project_name!='' && _file_eq(gProjectName,_project_name)) {
         macrosChanged=true;
      }
   }
}

void ctlfolders.lbutton_up()
{
   filters_list := "";

   int files_node=_ProjectGet_FilesNode(gProjectHandle);

   if (files_node>=0) {
      typeless folder_nodes[];
      _xmlcfg_find_simple_array(gProjectHandle,VPJTAG_FOLDER,folder_nodes,files_node);

      _str folder_name;
      _str folder_filter;

      int folder_index;
      for (folder_index=0;folder_index<folder_nodes._length();++folder_index) {
         folder_name=_xmlcfg_get_attribute(gProjectHandle,folder_nodes[folder_index],'Name');
         folder_filter=_xmlcfg_get_attribute(gProjectHandle,folder_nodes[folder_index],'Filters');
         if (filters_list:!='') {
            strappend(filters_list,',');
         }
         strappend(filters_list,folder_name:+'(':+folder_filter:+')');
      }
   }

   _str result=_edit_folder_filters(filters_list);

   if (result:!='') {
      if (files_node>=0) {
         _xmlcfg_delete(gProjectHandle,files_node,true);
      } else {
         files_node=_ProjectGet_FilesNode(gProjectHandle,true);
      }

      if (filters_list:!='') {
         // for easy parsing
         _maybe_append(filters_list,',');

         _str folder_name;
         _str folder_filter;
         int folder_node;

         while (filters_list:!='') {
            parse filters_list with folder_name '(' folder_filter '),' filters_list;

            folder_node=_xmlcfg_add(gProjectHandle,
                                    files_node,
                                    'Folder',
                                    VSXMLCFG_NODE_ELEMENT_START_END,
                                    VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_add_attribute(gProjectHandle,
                                  folder_node,
                                  'Name',
                                  folder_name);
            _xmlcfg_add_attribute(gProjectHandle,
                                  folder_node,
                                  'Filters',
                                  folder_filter);
         }
      }
   }
}

/**
 * Displays the <b>Project Properties dialog box</b>.  The project's
 * values are updated before the dialog box is closed unless the user
 * cancels the dialog box.
 *
 * @return Returns '' if the dialog box is cancelled.  Otherwise, 1 is returned.
 *
 * @categories Forms
 *
 */
void _ok.on_create(_str PropertiesForName='',
                   int project_handle=-1,
                   _str activetab='',
                   bool MakeCopyFirst=true,
                   bool doSaveIfNecessary=true,
                   bool IsProjectPackage=false,
                   bool showCurrentConfig=false)
{

   if (project_handle<0) {
      return;
   }

   _project_form_initial_alignment();

   gUpdateTags=false;
   gLeaveFileTabEnabled=true;
   gOrigProjectFileList= 0;
   //gWildCardFileAttributesHashTab._makeempty();
   gSetActiveConfigTo='';
   gInitialTargetName= _retrieve_value("_project_form.toolNameSelected");
   gInitialTagFileOption = _ProjectGet_TaggingOption(project_handle);
   gFileListModified=false;  // List is not modified.
   gAllConfigsInfo._makeempty();
   gProjectHandle=project_handle;
   gMakeCopyFirst=MakeCopyFirst;
   gdoSaveIfNecessary=doSaveIfNecessary;
   gIsProjectTemplate=IsProjectPackage;
   gConfigName=PropertiesForName; // Only used when editing settings for extension project

   if (project_handle==_fileProjectHandle()) {
      gIsExtensionProject=1;
   } else if (project_handle==_fileProjectEditProfileHandle()) {
      gIsExtensionProject=2;
   } else {
      gIsExtensionProject=0;
   }

   if (activetab != "" && !isnumber(activetab)) {
      for (tabi := 0; tabi < _proj_prop_sstab.p_NofTabs; tabi++) {
         _proj_prop_sstab.p_ActiveTab = tabi;
         if (_proj_prop_sstab.p_ActiveCaption == activetab) {
            activetab = tabi;
         }
      }
   }

   ignore_config_change=false;

   if (gMakeCopyFirst) {
      gProjectHandle=_xmlcfg_create(_xmlcfg_get_filename(project_handle),VSENCODING_UTF8);
      _xmlcfg_copy(gProjectHandle,TREE_ROOT_INDEX,project_handle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);
   }
   gProjectName=PropertiesForName;
   if (!gIsProjectTemplate) {
      gProjectName=_xmlcfg_get_filename(project_handle);
   }
   _xmlcfg_set_modify(gProjectHandle,0);
   _ProjectGet_ConfigNames(gProjectHandle,gConfigList);

   gInitialBuildSystem = _ProjectGet_BuildSystem(gProjectHandle);
   gInitialBuildMakeFile = _ProjectGet_BuildMakeFile(gProjectHandle);

   if (!gIsExtensionProject && !gIsProjectTemplate) {
      //_ini_get_value(_project_name,"ASSOCIATION",'makefile',makefile,'');
      //_ini_get_value(_project_name,"ASSOCIATION",'makefiletype',makefiletype,'');
      _GetAssociatedProjectInfo(gProjectName,gAssociatedFile,gAssociatedFileType);
   }

   if (gIsProjectTemplate) {
      p_active_form.p_caption='Project Package for "'PropertiesForName'"';
   } else if(gIsExtensionProject) {
      p_active_form.p_caption='Project Properties For 'PropertiesForName;
   } else {
      p_active_form.p_caption="Project Properties For ":+GetProjectDisplayName(PropertiesForName);
   }

   if (!_haveBuild()) {
      removeBuildItems();
   } else {
      if (_isUnix()) {
         ctlRunInXterm.p_visible= true;
      }

      // Fill in the options for the tagging options combo box
      FillInTagsCombo();

      // Fill in the options for the modified files save combo box
      ProjectFormFillInToolSaveCombo();

      // fill in the options for the hide combo box
      FillInToolShowCombo();

      // If a real project is opened, _project_name is not "" and arg(1)== ""
      // If an extension project is opened, _project_name is "" and arg(1) is ".e" or ".c" or ...
      fid := p_active_form;
      _str SectionsList[];

   }


   // Disable unused tabs (for extension project):
   //
   //_proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_CONFIGURATIONS,0); // Configurations
   if (gIsExtensionProject) {  // extension project or project pack
      if (_haveBuild()) {
         ctlRunFromDir.p_enabled=false;
         _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_BUILDOPTIONS,0); // Build Options tab
         _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_OPENCOMMAND,0); // Command
      }
      _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_FILES,0); // Files tab
      _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_DEPENDENCIES,0); // Dependencies tab
      _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_DIRECTORIES,1);
      _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_RUNDEBUG,1);

      DisableProjectControlsForWorkspace(false, false);

      // Make sure the active tab is one of the enabled ones:
      if (activetab=='') {
         activetab= _retrieve_value("_project_form._proj_prop_sstab");
      }

      // remove two trailing disabled tabs
      // removing other tabs before Compile/Link would mess with numbering
      if (haveProjectOpenTab()) {
         _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_OPENCOMMAND;
         _proj_prop_sstab._deleteActive();
      }
      if (haveProjectDependenciesTab()) {
         _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_DEPENDENCIES;
         _proj_prop_sstab._deleteActive();
      }

      if (!_haveBuild()) {
         _proj_prop_sstab.p_ActiveTab= PROJECTPROPERTIES_TABINDEX_DIRECTORIES;
      } else {
         if (activetab== PROJECTPROPERTIES_TABINDEX_FILES
             || activetab== PROJECTPROPERTIES_TABINDEX_BUILDOPTIONS
             || activetab== PROJECTPROPERTIES_TABINDEX_OPENCOMMAND
             || activetab== PROJECTPROPERTIES_TABINDEX_DEPENDENCIES
             || activetab== PROJECTPROPERTIES_TABINDEX_RUNDEBUG
             /*|| activetab== PROJECTPROPERTIES_TABINDEX_CONFIGURATIONS*/) {
            _proj_prop_sstab.p_ActiveTab= PROJECTPROPERTIES_TABINDEX_DIRECTORIES;
         } else if (activetab!=''){
            _proj_prop_sstab.p_ActiveTab= (int)activetab;
         }

         // For a project pack, get the pack information from arg(2).
         ctlPreBuildCmdList.DisableAll();
         //ctlCurConfig.p_enabled=false;
         //ctlCurConfig.p_prev.p_enabled=false;
         //ctlconfigurations.p_enabled=false;
      }

   } else if (gIsProjectTemplate) {
      _proj_prop_sstab._setEnabled(PROJECTPROPERTIES_TABINDEX_FILES,0); // Files tab

      // Make sure the active tab is one of the enabled ones:
      if (activetab=='') {
         activetab= _retrieve_value("_project_form._proj_prop_sstab");
      }
      if (activetab== PROJECTPROPERTIES_TABINDEX_FILES) {
         _proj_prop_sstab.p_ActiveTab= PROJECTPROPERTIES_TABINDEX_DIRECTORIES;
      } else if (activetab!=''){
         _proj_prop_sstab.p_ActiveTab= (int)activetab;
      }

      if (_haveBuild()) ctlfolders.p_visible=true;
   } else {              // real project
      // Restore active tab:
      if (activetab=='') {
         activetab= _retrieve_value("_project_form._proj_prop_sstab");
      }
      if (activetab!=''){
         _proj_prop_sstab.p_ActiveTab= (int)activetab;
      }
   }
   //if (file_eq(get_extension(_workspace_filename,1),VCPP_PROJECT_WORKSPACE_EXT)) {
   if (!gIsExtensionProject && !gIsProjectTemplate) {  // a real project opened
      if (_IsWorkspaceAssociated(_workspace_filename)) {
         // if the association does not support modifying the file list, disable
         // the files tab
         LeaveFileTabEnabled := _CanWriteFileSection(GetProjectDisplayName(gProjectName));
         gLeaveFileTabEnabled=LeaveFileTabEnabled;
         DisableProjectControlsForWorkspace(LeaveFileTabEnabled, false);
         if (!gProjectFilesNotNeeded && !_IsEclipseWorkspaceFilename(_workspace_filename) &&
             !_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
            int modify=_xmlcfg_get_modify(gProjectHandle);
            int Node=_ProjectGet_FilesNode(gProjectHandle,true);

            _str fileList[];
            int status = _getProjectFiles(_workspace_filename, gProjectName, fileList, 0,-1,false);
            if (!status) {
               int flags=VSXMLCFG_ADD_AS_CHILD;
               for (i := 0; i < fileList._length(); i++) {
                  Node=_xmlcfg_add(gProjectHandle,Node,VPJTAG_F,VSXMLCFG_NODE_ELEMENT_START_END,flags);
                  _xmlcfg_set_attribute(gProjectHandle,Node,'N',_NormalizeFile(fileList[i]));
                  flags=0;
               }
            }

            _xmlcfg_set_modify(gProjectHandle,modify);
         } else if(_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
            int associatedHandle = _ProjectGet_AssociatedHandle(gProjectHandle);
            int FilesNode=_ProjectGet_FilesNode(gProjectHandle,true);
            path := _strip_filename(gProjectName, "N");

            typeless nodeArray[] = null;
            _xmlcfg_find_simple_array(associatedHandle, "/project//" VPJTAG_F, nodeArray);
            int i;
            for(i = 0; i < nodeArray._length(); i++) {
               _str filename = _xmlcfg_get_attribute(associatedHandle, nodeArray[i], "N");

               // only wildcards in jbuilder are for directory views which cannot be deleted
               if(iswildcard(filename) && !file_exists(filename)) continue;

               int Node=_xmlcfg_add(gProjectHandle,FilesNode,VPJTAG_F,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_set_attribute(gProjectHandle,Node,'N',_NormalizeFile(relative(filename,path)));
            }
         }
      } else {
         _prjref_files.p_prev.p_enabled=false; // references label
         _prjref_files.p_enabled=false;
         _prjref_files.p_next.p_enabled=false; // browse button
         _prjref_files.p_next.p_next.p_enabled=false; // menu button
      }
   }

   // Initialize the various tabs:
   // If an extension project is being opened, only the Directories, Tools, and
   // Compile Options tabs need to be initialized.
   if (_haveBuild() && !gIsExtensionProject) {  // a real project opened
      oncreateMacro();
   }
   // Initialize the Directories and Tools tabs.
   // project ==> ".e" for extension project, "" for real project
   oncreateDirectories();
   if (_haveBuild()) {
      oncreateBuildOptions();
   }

   // load dependencies tab with all projects in workspace except this one
   if (_haveBuild() && !gIsExtensionProject && !gIsProjectTemplate) {  // a real project opened
      oncreateDependencies();
   }
   if (_haveRealTimeErrors()) {
      _control _ctl_profile_ovrs;
      onCreateLiveErrorsTab(gProjectHandle, _ctl_profile_ovrs);
   }

   if (_haveBuild()) {
      /*if (gIsExtensionProject) {
         // just add the extension and select it - user will not be able to change it
         ctlCurConfig._lbadd_item(gConfigName);
         ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
      } else */{
         //_ProjectGet_Configs(gProjectName,gConfigList);
         ctlCurConfig._lbclear();
         foreach (auto config in gConfigList) {
            ctlCurConfig._lbadd_item(config);
         }
         //_showbuf(ctlCurConfig.p_cb_list_box.p_buf_id);
         if (ctlCurConfig.p_Noflines) {
            ctlCurConfig._lbbottom();
            ctlCurConfig._lbadd_item(PROJ_ALL_CONFIGS);
         } else {
            _message_box('ERROR: project file has no configurations');
         }
         //_showbuf(ctlCurConfig.p_cb_list_box.p_window_id);
         ctlCurConfig._lbbottom();
         if (gIsExtensionProject==1) {
            // Since you can't add files to a single file project, always show the current config.
            ctlCurConfig.p_text=_fileProjectConfig();
         }  else if (gIsExtensionProject || gIsProjectTemplate || !showCurrentConfig) {
            ctlCurConfig.p_text=ctlCurConfig._lbget_text();
         } else {
            ctlCurConfig.p_text=GetCurrentConfigName(gProjectName);
         }
         //ctlCurConfig.p_text=ctlCurConfig.p_cb_list_box._lbget_text();
      }
   } else {
      // Make sure we create a configuration for this language
      if (gIsExtensionProject && _ProjectGet_ConfigNode(gProjectHandle,gConfigName)<0) {
         _ProjectCreateLangSpecificConfig(gProjectHandle, gConfigName);
      }
      // in the pro edition, a lot of things are keyed off the changing of the config
      // this takes care of the case where the config is not visible
      initNonBuildTabs();
   }


   ctlimport.p_enabled=ImportTypesAvailable();
   ctlimport.p_visible=ctlimport.p_enabled;

   // call any _prjedit_* functions
   call_list("_prjedit_", gProjectHandle);

   // force an activate event
   // does not get called during restore since the files tab
   // is tab zero
   if (_proj_prop_sstab.p_ActiveTab==PROJECTPROPERTIES_TABINDEX_FILES) {
      call_event(CHANGE_TABACTIVATED,_proj_prop_sstab,ON_CHANGE,'W');
   }
}

static void removeBuildItems()
{
   // files tab
   ctltagscombo.p_visible = ctltagslabel.p_visible = false;
   _srcfile_list.p_height = (ctltagscombo.p_y_extent) - _srcfile_list.p_y;
   ctlimport.p_y = (_srcfile_list.p_y_extent) - ctlimport.p_height;

   // directories tab
   label5.p_visible = _prjref_files.p_visible = _browserefs.p_visible = _projref_button.p_visible = false;
   diff := ctlIncDirLabel.p_y - label5.p_y;
   if (gIsExtensionProject) {
      _prjworking_dir.p_visible = _prjworklab.p_visible = _browsedir1.p_visible = _projworking_button.p_visible = false;
      diff = (ctlIncDirLabel.p_y - _prjworklab.p_y);
   }
   ctlIncDirLabel.p_y -= diff;
   ctlUserIncludesList.p_y -= diff;
   ctlBrowseUserIncludes.p_y -= diff;
   ctlMoveUserIncludesUp.p_y -= diff;
   ctlMoveUserIncludesDown.p_y -= diff;
   ctlRemoveUserIncludes.p_y -= diff;
   ctlUserIncludesList.p_height += diff;

   // remove the text about the reference directory
   _str helpStrs[];
   split(ctlHelpLabelDir.p_caption, "\n\n", helpStrs);
   ctlHelpLabelDir.p_caption = helpStrs[0] :+ "\n\n" :+ helpStrs[1];

   _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_LIVE_ERRORS;
   _proj_prop_sstab._deleteActive();

   // remove the rest of the tabs
   if (haveProjectOpenTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_OPENCOMMAND;
      _proj_prop_sstab._deleteActive();
   }
   if (haveProjectDependenciesTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_DEPENDENCIES;
      _proj_prop_sstab._deleteActive();
   }
   if (haveProjectCompileTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_COMPILELINK;
      _proj_prop_sstab._deleteActive();
   }
   if (haveProjectBuildTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_BUILDOPTIONS;
      _proj_prop_sstab._deleteActive();
   }
   if (haveProjectToolsTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_TOOLS;
      _proj_prop_sstab._deleteActive();
   }
   if (haveProjectRunDebugTab()) {
      _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_RUNDEBUG;
      _proj_prop_sstab._deleteActive();
   }

   // main form
   ctllabel3.p_visible = ctlCurConfig.p_visible = ctlconfigurations.p_visible = false;
   diff = (_proj_prop_sstab.p_y - ctlconfigurations.p_y);
   _proj_prop_sstab.p_y -= diff;
   _proj_prop_sstab.p_height += diff;
   resizeFilesTab(0, diff);
   resizeDirectoriesTab(0, diff);
}

static void initNonBuildTabs()
{
   isJavaConfigType := true;
   _ProjectGet_AllConfigsInfo(gProjectHandle,gAllConfigsInfo,gConfigList);

   // do not allow them to edit includes for all configurations unless they match
   includesMatchForAllConfigs := (/*gIsExtensionProject || */gAllConfigsInfo.IncludesMatchForAllConfigs);
   ctlIncDirLabel.p_enabled          = includesMatchForAllConfigs;
   ctlBrowseUserIncludes.p_enabled   = includesMatchForAllConfigs; // browse button
   ctlMoveUserIncludesUp.p_enabled   = includesMatchForAllConfigs; // up button
   ctlMoveUserIncludesDown.p_enabled = includesMatchForAllConfigs; // down button
   ctlRemoveUserIncludes.p_enabled   = includesMatchForAllConfigs; // delete button
   ctlUserIncludesList.p_enabled     = includesMatchForAllConfigs;
   ctlUserIncludesList.p_EditInPlace = includesMatchForAllConfigs;
   if (!includesMatchForAllConfigs) {
      ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false);
   }

   /*if (gIsExtensionProject) {
      isJavaConfigType=false;
      ctlUserIncludesList._TreeSetDelimitedItemList(_ProjectGet_IncludesList(gProjectHandle, gConfigName), PATHSEP, false);

   } else */if(!strieq(gAllConfigsInfo.Type,'java')) {
      isJavaConfigType=false;
      if(ctlUserIncludesList.p_EditInPlace) {
         ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                       _ProjectGet_AssociatedIncludes(gProjectHandle, false));
      }
   }

   if (isJavaConfigType) {
      ctlIncDirLabel.p_enabled=false;
      ctlUserIncludesList.p_enabled=false;
      ctlUserIncludesList.p_next.p_enabled=false; // browse button
      ctlMoveUserIncludesUp.p_enabled=false; // up button
      ctlMoveUserIncludesDown.p_enabled=false; // down button
      ctlRemoveUserIncludes.p_enabled=false; // delete button
   }

   _srcfile_list.FillInSrcFileList(getCurrentConfig());

   gChangingConfiguration=false;
}

static void FillInTagsCombo()
{
   for (i:=0; i < gTagsComboTextList._length(); i++) {
      ctltagscombo._lbadd_item(gTagsComboTextList[i]);
   }
}

static _str getTagsComboValue()
{
   // find which item in the list matches this text
   text := ctltagscombo.p_text;
   for (i:=0; i < gTagsComboTextList._length(); i++) {
      if (gTagsComboTextList[i] == text) {
         // then use the index to return the text we save in the file
         return gTagsComboList[i];
      }
   }
   return gTagsComboList[0];
}

void ProjectFormFillInToolSaveCombo()
{
   for (i := 0; i < gSaveComboTextList._length(); i++) {
      ctlToolSaveCombo._lbadd_item(gSaveComboTextList[i]);            // SAVENONE=0
   }
}

_str ProjectFormGetToolSaveComboValue()
{
   // find which item in the list matches this text
   text := ctlToolSaveCombo.p_text;
   for (i := 0; i < gSaveComboTextList._length(); i++) {
      if (gSaveComboTextList[i] == text) {
         // then use the index to return the text we save in the file
         return gSaveComboList[i];
      }
   }

   return gSaveComboList[0];
}

static void FillInToolShowCombo()
{
   for (i := 0; i < gShowComboTextList._length(); i++) {
      ctlToolHideCombo._lbadd_item(gShowComboTextList[i]);
   }
}

static _str getToolHideComboValue()
{
   // find which item in the list matches this text
   text := ctlToolHideCombo.p_text;
   for (i := 0; i < gShowComboTextList._length(); i++) {
      if (gShowComboTextList[i] == text) {
         // then use the index to return the text we save in the file
         return gShowComboList[i];
      }
   }

   return gShowComboList[0];
}

static bool ImportTypesAvailable()
{
   return(!_IsWorkspaceAssociated(_workspace_filename) && def_import_file_types!='');
}

//  int _[ext]_import_files(_str from_filename, _str (&file_list)[]);
int ctlimport.lbutton_up()
{
   // _import_list_form returns a wid to a temporary window
   orig_wid := p_window_id;
   int temp_wid=show('-modal _import_list_form');

   if (temp_wid==0 || temp_wid:=='') {
      // nothing to see here
      return COMMAND_CANCELLED_RC;
   }

   _str Files[];
   _str line;

   // let's take a look at what's in this temp file
   activate_window(temp_wid);

   // make sure we don't get any warnings about giant arrays
   if (_default_option(VSOPTION_WARNING_ARRAY_SIZE)<p_Noflines+10) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,p_Noflines+10);
   }

   // start at the top, work our way down
   top();
   up();
   while (!down()) {
      // grab the line
      get_line(line);
      line = strip(line);

      // as long as it's not blank, add this file to our list (relative to our project)
      if (line:!='') {
         Files[Files._length()]=_RelativeToProject(line,gProjectName);
      }
   }

   // all done with the temp view, delete it
   activate_window(orig_wid);
   _delete_temp_view(temp_wid);

   // we're going to add these to the project file list
   wid := p_window_id;
   p_window_id=_srcfile_list;

   len := Files._length();
   int i;
   int list_wid=_srcfile_list;
   projectPath := _strip_filename(gProjectName,'N');
   _str config=getCurrentConfig();

   // get ready to add some files to this configuration
   int FileToNode:[];
   FilesNode := 0;
   AutoFolders := "";
   int ExtToNodeHashTab:[];
   LastExt := "";
   LastNode := 0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);

   // and add them
   list_wid._lbbegin_update();
   for (i=0;i<len;++i) {
      AddFileToConfig(list_wid,relative(Files[i],projectPath),config,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   list_wid._lbend_update(list_wid.p_Noflines);

   if ( len ) {
      gFileListModified=true;
      _lbsort('-f');
      _lbremove_duplicates(_fpos_case);
      _lbtop();
   }
   p_window_id=wid;
   return(0);
}

/**
 * Fills in a combo box with the Application types
 *
 * @param AppTypeList
 *               Comma delimited list of applications
 */
static void FillInAppTypes(_str AppTypeList)
{
   for (;;) {
      cur := "";
      parse AppTypeList with cur ',' AppTypeList;
      if (cur=='') break;
      _lbadd_item(cur);
   }
   _lbtop();
   p_text=_lbget_text();
}


#if 0
/**
 *
 * Replaces the %~other in command strings with the actual
 * value
 *
 * @param cmd    The "cmd" portion of a command string from a project file
 *
 * @param other  The "other" portion of a command string from a project file.
 *
 * @return returns the string from the <B>cmd</B> parameter
 */
static _str _ProjectReplaceOther(_str cmd,_str other)
{
   int p=pos('(^|[~%])\%\~other',cmd,1,'r');
   cmd2 := "";
   if (p) {
      if (p>1) {
         cmd2=substr(cmd,1,p);
         ++p;
      }
      //7 is the length of %~other
      cmd2 :+= other:+substr(cmd,p+7);
   }else cmd2=cmd;
   return(cmd2);
}
#endif

static void populate_config_list(_str type = "")
{
   gChangingConfiguration=true;
   ctlCompilerList._lbclear();
   ctlCompilerList._lbadd_item(COMPILER_NAME_NONE);

   if (type :!= "java") {
      ctlCompilerList._lbadd_item(COMPILER_NAME_LATEST' ('_GetLatestCompiler()')');
      if (def_refactor_active_config != '') {
         ctlCompilerList._lbadd_item(COMPILER_NAME_DEFAULT' ('def_refactor_active_config')');
      } else {
         ctlCompilerList._lbadd_item(COMPILER_NAME_DEFAULT' (none selected)');
      }
   } else {
      ctlCompilerList._lbadd_item(COMPILER_NAME_LATEST' ('_GetLatestJDK()')');
      if (def_active_java_config!= '') {
         ctlCompilerList._lbadd_item(COMPILER_NAME_DEFAULT' ('def_active_java_config')');
      } else {
         ctlCompilerList._lbadd_item(COMPILER_NAME_DEFAULT' (none selected)');
      }
   }

   // sometimes have to open compilers.xml again here because _GetLatestXXX will close it
   if (_haveBuild()) {
      filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
      if (!refactor_config_is_open(filename)){
         refactor_config_open(filename);
      }
      n := refactor_config_count();
      for (i:=0; i<n; ++i) {
         refactor_config_get_name(i, auto compiler_name);
         refactor_config_get_type(i, auto comp_type);
         if (type :== "java") {
            if (comp_type :== "java") {
               ctlCompilerList._lbadd_item(compiler_name);
            }
         } else {
            if (comp_type :!= "java") {
               ctlCompilerList._lbadd_item(compiler_name);
            }
         }
      }
   }

   // done filling in list
   gChangingConfiguration=false;
}

static void oncreateDirectories()
{
   if (!haveProjectDirectoriesTab()) {
      return;
   }

   // use this later to restore original caption for this frame
   if (haveProjectRunDebugTab()) {
      ctlDebuggerFrame.p_user = ctlDebuggerFrame.p_caption;
   }

   _prjworking_dir.p_text=_ProjectGet_WorkingDir(gProjectHandle);
   updateTaggingOption(_ProjectGet_TaggingOption(gProjectHandle));

   if (_haveBuild()) {
      filename := _ConfigPath():+COMPILER_CONFIG_FILENAME;
      refactor_config_open( filename );
      if (refactor_config_count() <= 0) {
         generate_default_configs();
      }
   }
}

static void resetRunDebugInfo(PROJECT_CONFIG_INFO configInfo=null)
{
   if (!haveProjectRunDebugTab()) {
      return;
   }

   // if they did not pass in the configInfo, 
   // only do this if the current target is debug or execute
   if (configInfo == null) {
      if (!stricmp(GetTargetName(), "debug") && !stricmp(GetTargetName(), "execute")) {
         return;
      }
      if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
         configInfo = gAllConfigsInfo;
      } else {
         _ProjectGet_OneConfigsInfo(gProjectHandle,configInfo,getCurrentConfig());
      }
   }

   // update run/debug tab items
   callback_name := configInfo.DebugCallbackName;
   if (!_haveDebugging()) {
      // no debugging support
      ctlDebuggerFrame.p_enabled = false;
   } else if (callback_name == null) {
      // all-configs mismatch case
      ctlDebuggerFrame.p_enabled = false;
      ctlDebuggerFrame.p_caption = ctlDebuggerFrame.p_user;
      ctlDebuggerFrame.p_caption :+= " (" :+ MESSAGE_ALLCONFIG_SETTING_MISMATCH :+ ")";
   } else {
      // set appropriate radio button for debugger
      ctlDebuggerFrame.p_enabled = true;
      ctlDebuggerFrame.p_caption = ctlDebuggerFrame.p_user;
      switch (lowcase(callback_name)) {
      case "lldb":      ctlUseLLDB.p_value = 1;   break;
      case "gdb":       ctlUseGDB.p_value = 1;    break;
      case "windbg":    ctlUseWinDBG.p_value = 1; break;
      case "jdwp":      ctlUseJDWP.p_value = 1;   break;
      case "mono":      ctlUseMono.p_value = 1;   break;
      case "pydbgp":    ctlUsePython.p_value = 1; break;  // We recognize this older debugger type as python, even though newer backend will be used in newer SE versions.
      case "dap":    ctlUsePython.p_value = 1; break;
      case "perl5db":   ctlUsePerl.p_value = 1;   break;
      case "rdbgp":     ctlUseRuby.p_value = 1;   break;
      case "xdebug":    ctlUsePHP.p_value = 1;    break;
      case "":          ctlUseOther.p_value = 1;  break;
      default:          ctlUseOther.p_value = 1;  break;
      }
   }

   ctlUseWinDBG.p_enabled = _isWindows();
   ctlUseLLDB.p_enabled = _is_lldb_debugger_supported();
   ctldbgDebugger.p_enabled = (ctlUseOther.p_value == 1);
   ctldbgFindApp.p_enabled = (ctlUseOther.p_value == 1);
   ctldbgOtherDebuggerOptions.p_enabled = (ctlUseOther.p_value == 1);
   ctldbgOtherDebuggerButton.p_enabled = (ctlUseOther.p_value == 1);
   ctlProgramName.p_text = "";
   ctlProgramArgs.p_text = "";
   ctlProgramDir.p_text = "";
   ctldbgDebugger.p_text = "";
   ctldbgOtherDebuggerOptions.p_text = "";
   if (configInfo.TargetInfo._indexin("debug")) {
      PROJECT_TARGET_INFO debugInfo = configInfo.TargetInfo:["debug"];
      if (debugInfo != null) {
         // get "run from dir"
         ctlProgramDir.p_text = (debugInfo.RunFromDir == null)?  MESSAGE_ALLCONFIG_SETTING_MISMATCH : debugInfo.RunFromDir;
         ctlProgramDir.p_enabled = (debugInfo.RunFromDir != null);
         ctlProgramDirBrowse.p_enabled = (debugInfo.RunFromDir != null);
         ctlProgramDirMenu.p_enabled = (debugInfo.RunFromDir != null);
         // now get command line
         command_line := debugInfo.Exec_CmdLine;
         ctlProgramName.p_enabled = (command_line != null);
         ctlProgramNameBrowse.p_enabled = (command_line != null);
         ctlProgramNameMenu.p_enabled = (command_line != null);
         ctlProgramArgs.p_enabled = (command_line != null);
         ctlProgramArgsBrowse.p_enabled = (command_line != null);
         ctlProgramArgsMenu.p_enabled = (command_line != null);
         ctlDebuggerFrame.p_enabled = (ctlDebuggerFrame.p_enabled && command_line != null);
         if (command_line == null) {
            ctlProgramName.p_text = MESSAGE_ALLCONFIG_TOOLS_MISMATCH;
            ctlProgramArgs.p_text = MESSAGE_ALLCONFIG_SETTING_MISMATCH;
            ctldbgDebugger.p_text = MESSAGE_ALLCONFIG_TOOLS_MISMATCH;
            ctldbgOtherDebuggerOptions.p_text = MESSAGE_ALLCONFIG_SETTING_MISMATCH;
         } else if (ctlUseOther.p_value) {
            // debugger comamnd line is actual debugger to launch
            ctldbgDebugger.p_text = parse_file(command_line);
            ctldbgOtherDebuggerOptions.p_text = command_line;
         } else {
            // try to get executable and args from debug command.
            // this only matters if there is no "execute" comamnd
            if (pos("vsdebugio ", command_line) > 0) {
               parse command_line with . "vsdebugio" . "-prog" command_line;
            } else if (pos("vcproj_windbg_debug ", command_line) > 0) {
               parse command_line with "vcproj_windbg_debug " command_line;
            } else if (pos("-Xrunjdwp", command_line) > 0) {
               address := "";
               args := "";
               parse command_line with command_line "-Xrunjdwp:" . ",address="address args;
               parse command_line with command_line "-Xdebug" .;
               parse command_line with command_line "-Xnoagent" .;
               address = parse_file(command_line);
               command_line = _maybe_quote_filename(address) " " args;
            } else if (pos("--debugger-agent=", command_line) > 0) {
               address := "";
               args := "";
               parse command_line with command_line "--debugger-agent=" . ",address="address args;
               address = strip(address,'B',"\"\' \t");
               address = parse_file(command_line);
               command_line = _maybe_quote_filename(address) " " args;
            } else if (pos("(vcproj_windbg_debug|perl_debug|python_debug|ruby_debug|php_debug) ", command_line, 1, 'r') == 1) {
               parse command_line with . command_line;
            }
            ctlProgramName.p_text = parse_file(command_line);
            ctlProgramArgs.p_text = command_line;
            if (ctlProgramArgs.p_text == "%~other") {
               ctlProgramArgs.p_text = "";
            }
         }
      }
   }

   if (configInfo.TargetInfo._indexin("execute")) {
      PROJECT_TARGET_INFO executeInfo = configInfo.TargetInfo:["execute"];
      if (executeInfo != null) {
         // get "run from dir"
         ctlProgramDir.p_text = (executeInfo.RunFromDir == null)? MESSAGE_ALLCONFIG_SETTING_MISMATCH : executeInfo.RunFromDir;
         ctlProgramDir.p_enabled = (executeInfo.RunFromDir != null);
         ctlProgramDirBrowse.p_enabled = (executeInfo.RunFromDir != null);
         ctlProgramDirMenu.p_enabled = (executeInfo.RunFromDir != null);
         // now get command line
         command_line := executeInfo.Exec_CmdLine;
         ctlProgramName.p_enabled = (command_line != null);
         ctlProgramNameBrowse.p_enabled = (command_line != null);
         ctlProgramNameMenu.p_enabled = (command_line != null);
         ctlProgramArgs.p_enabled = (command_line != null);
         ctlProgramArgsBrowse.p_enabled = (command_line != null);
         ctlProgramArgsMenu.p_enabled = (command_line != null);
         ctlDebuggerFrame.p_enabled = (ctlDebuggerFrame.p_enabled && command_line != null);
         if (command_line == null) {
            ctlProgramName.p_text = MESSAGE_ALLCONFIG_TOOLS_MISMATCH;
            ctlProgramArgs.p_text = MESSAGE_ALLCONFIG_SETTING_MISMATCH;
         } else {
            ctlProgramName.p_text = parse_file(command_line);
            ctlProgramArgs.p_text = command_line;
            if (ctlProgramArgs.p_text == "%~other") {
               ctlProgramArgs.p_text = "";
            }
         }
      }
   }

   // make sure radio buttons are disabled if frame is disabled
   ctlUseLLDB.p_enabled   = ctlDebuggerFrame.p_enabled;
   ctlUseGDB.p_enabled    = ctlDebuggerFrame.p_enabled;
   ctlUseWinDBG.p_enabled = ctlDebuggerFrame.p_enabled;
   ctlUseJDWP.p_enabled   = ctlDebuggerFrame.p_enabled;
   ctlUsePython.p_enabled = ctlDebuggerFrame.p_enabled;
   ctlUsePerl.p_enabled   = ctlDebuggerFrame.p_enabled;
   ctlUseRuby.p_enabled   = ctlDebuggerFrame.p_enabled;
   ctlUsePHP.p_enabled    = ctlDebuggerFrame.p_enabled;
   ctlUseMono.p_enabled   = ctlDebuggerFrame.p_enabled;
   ctlUseOther.p_enabled  = ctlDebuggerFrame.p_enabled;
}

static void okDirectories()
{
   _prjworking_dir.p_text=strip(_prjworking_dir.p_text,'B','"');
   if (_prjworking_dir.p_text!=_ProjectGet_WorkingDir(gProjectHandle)) {
      workingDir := _prjworking_dir.p_text;

      // store working dir relative to project unless this is a project template
      if(!gIsProjectTemplate) {
         workingDir = relative(workingDir, _strip_filename(gProjectName, "N"));

         // if the project dir is specified, this will return blank.  check for
         // that case and insert a '.'
         if(workingDir == "") {
            workingDir = ".";
         }
      }

      _ProjectSet_WorkingDir(gProjectHandle, workingDir);
   }
}

static void oncreateBuildOptions()
{
   if (!haveProjectBuildTab()) {
      return;
   }

   // setup build system
   switch(_ProjectGet_BuildSystem(gProjectHandle)) {
      case "vsbuild":
         ctlBuild_vsbuild.p_value = 1;
         ctlBuild_AutoMakefile.p_value = 0;
         ctlBuild_Custom.p_value = 0;

         ctlAutoMakefile.p_text = "";
         ctlAutoMakefile.p_enabled = false;
         ctlAutoMakefileButton.p_enabled = false;
         ctlThreadMake.p_enabled = false;
         ctlMakeJobs.p_enabled = false;
         ctlMakeJobsSpinner.p_enabled = false;
         break;

      case "automakefile":
         ctlBuild_vsbuild.p_value = 0;
         ctlBuild_AutoMakefile.p_value = 1;
         ctlBuild_Custom.p_value = 0;

         // if we have a VCPP config, then we can't use gmake's parallel build options
         haveVCPPConfig := false;
         _ProjectGet_ConfigNames(gProjectHandle, auto configList);
         foreach (auto config in configList) {
            configType := _ProjectGet_Type(gProjectHandle, config);
            if (strieq(configType, "vcpp")) {
               haveVCPPConfig = true;
               break;
            }
         }
         ctlAutoMakefile.p_text = _ProjectGet_BuildMakeFile(gProjectHandle);
         ctlMakeJobs.p_text = _ProjectGet_BuildMakeJobs(gProjectHandle);
         if (haveVCPPConfig || !isuinteger(ctlMakeJobs.p_text)) {
            ctlMakeJobs.p_text = 1;
         }
         ctlThreadMake.p_value = (ctlMakeJobs.p_text > 1)? 1:0;
         ctlAutoMakefile.p_enabled = true;
         ctlAutoMakefileButton.p_enabled = true;
         ctlThreadMake.p_enabled = !haveVCPPConfig;
         ctlMakeJobs.p_enabled = true;
         ctlMakeJobsSpinner.p_enabled = true;
         if (!ctlThreadMake.p_value) {
            ctlMakeJobs.p_enabled = false;
            ctlMakeJobsSpinner.p_enabled = false;
         }
         break;

      default:
         ctlBuild_vsbuild.p_value = 0;
         ctlBuild_AutoMakefile.p_value = 0;
         ctlBuild_Custom.p_value = 1;
         ctlBuild_Custom.p_user = _ProjectGet_BuildMakeFile(gProjectHandle);

         ctlAutoMakefile.p_text = "";
         ctlAutoMakefile.p_enabled = false;
         ctlAutoMakefileButton.p_enabled = false;
         ctlThreadMake.p_enabled = false;
         ctlMakeJobs.p_enabled = false;
         ctlMakeJobsSpinner.p_enabled = false;
   }
}

static void GetBuildOptions(_str &ObjectDir, _str &OutputFile, _str &BuildSystem,_str &BuildMakeFile,_str &BuildOptions)
{
   ObjectDir=strip(ctlConfigObjectDir.p_text,'B','"');
   OutputFile=strip(ctlConfigOutputFile.p_text,'B','"');
   if (ObjectDir==MESSAGE_ALLCONFIG_SETTING_MISMATCH) ObjectDir="";
   if (OutputFile==MESSAGE_ALLCONFIG_SETTING_MISMATCH) OutputFile="";
   BuildMakeFile="";
   BuildOptions="";
   if (ctlBuild_vsbuild.p_value) {
      BuildSystem='vsbuild';
      if (ctlThreadDeps.p_value) {
         BuildOptions :+= "-threaddeps";
      }
      if (ctlThreadCompiles.p_value) {
         _maybe_append(BuildOptions, ' ');
         BuildOptions :+= " -threadcompiles";
      }
      if (ctlTimeBuild.p_value) {
         _maybe_append(BuildOptions, ' ');
         BuildOptions :+= " -time";
      }
   } else if (ctlBuild_Custom.p_value) {
      BuildSystem='';
      BuildMakeFile=ctlBuild_Custom.p_user;
   } else {
      BuildSystem='automakefile';
      BuildMakeFile=strip(ctlAutoMakefile.p_text,'B','"');
      if (ctlThreadMake.p_enabled && ctlThreadMake.p_value && isuinteger(ctlMakeJobs.p_text) && ctlMakeJobs.p_text > 1) {
         BuildOptions = "-j ":+ctlMakeJobs.p_text;
      }
   }
}

static void okBuildOptions()
{
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   BuildMakeJobs := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   // if changing to automakefile, set the makefile name if it wasnt provided and
   // add it to the project
   if(strieq(BuildSystem, "automakefile")) {
      if(BuildMakeFile == "") {
         BuildMakeFile = "%rp%rn.mak";
      }

      // add makefile to the project
      // NOTE: it is safe to just put it in the file list view because the
      //       entire list will be parsed later and the tag file will be updated
      _str parsedBuildMakeFile = _parse_project_command(BuildMakeFile, "", gProjectName, "");
      AddFileToConfig(_control _srcfile_list, relative(parsedBuildMakeFile, _strip_filename(gProjectName, 'N')),
                      PROJ_ALL_CONFIGS);

      parse BuildOptions with . BuildMakeJobs;
      if (!isuinteger(BuildMakeJobs) || BuildMakeJobs <= 1) BuildMakeJobs="";

   } else if(strieq(gInitialBuildSystem,"automakefile")) {
      // if this was using automakefile support but is no longer, remove the
      // makefile from the project
      // NOTE: it is safe to just remove it from the file list view because the
      //       entire list will be parsed later and the tag file will be updated
      _str oldBuildMakeFile = _parse_project_command(gInitialBuildMakeFile, "", gProjectName, "");
      int FileToNode:[] = null;
      _ProjectGet_FileToNodeHashTab(gProjectHandle, FileToNode);
      RemoveFileFromViews(relative(oldBuildMakeFile, _strip_filename(gProjectName, 'N')), PROJ_ALL_CONFIGS, FileToNode);
   }

   if (!strieq(_ProjectGet_BuildSystem(gProjectHandle),BuildSystem) ||
       !strieq(_ProjectGet_BuildMakeFile(gProjectHandle),BuildMakeFile) ||
       !strieq(_ProjectGet_BuildMakeJobs(gProjectHandle),BuildMakeJobs)) {
      _ProjectSet_BuildSystem(gProjectHandle,BuildSystem);
      _ProjectSet_BuildMakeFile(gProjectHandle,BuildMakeFile);
      _ProjectSet_BuildMakeJobs(gProjectHandle,BuildMakeJobs);
   }
}

static void reinitCompileLink()
{
   if (!haveProjectCompileTab()) {
      return;
   }
   if (!_haveBuild()) {
      return;
   }
   _str project_type = getCompilerListProjectType();

   populate_config_list(project_type);

   if (project_type == 'java') {
      ctlHelpLabelCompileLink.p_caption = "The compiler configuration selects the JDK package to use for building and tagging for the Java project.";
   }
}

static void oncreateDependencies()
{
   if (!haveProjectDependenciesTab()) {
      return;
   }
   // insert all projects from workspace except this project
   _str depProjectFiles[] = null;
   _WorkspaceGet_ProjectFiles(gWorkspaceHandle, depProjectFiles);
   int i, n = depProjectFiles._length();

   // sort the projects by filename
   depProjectFiles._sort("F");

   // get this projects filename relative to the workspace so it
   // can be removed from the list
   _str thisProject = _RelativeToWorkspace(gProjectName);

   for(i = 0; i < n; i++) {
      _str depProjectFile = depProjectFiles[i];

      // if this is the current project, remove it from the list
      if(_file_eq(depProjectFile, thisProject) || depProjectFile == "") {
         continue;
      }

      wid := p_window_id;
      _control ctlDepsTree;
      p_window_id=ctlDepsTree;
      // add the project node
      int depProjectNode = _TreeAddItem(TREE_ROOT_INDEX, depProjectFile, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);
      if(depProjectNode < 0) continue;
      int depProjectActiveConfigNode = _TreeAddItem(depProjectNode, "Active Configuration", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      _TreeSetCheckState(depProjectActiveConfigNode,TCB_UNCHECKED);

      int depProjectOtherConfigsNode = _TreeAddItem(depProjectNode, "Configurations", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_COLLAPSED);

      // open that project
      absDepProjectFile := _AbsoluteToWorkspace(depProjectFile);
      int depProjectHandle = _ProjectHandle(absDepProjectFile);
      if(depProjectHandle < 0) continue;

      // add all configurations from the project
      _str depProjectConfigs[] = null;
      _ProjectGet_ConfigNames(depProjectHandle, depProjectConfigs);
      int k, o = depProjectConfigs._length();
      for(k = 0; k < o; k++) {
         treeIndex := _TreeAddItem(depProjectOtherConfigsNode, depProjectConfigs[k], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
         _TreeSetCheckState(treeIndex,TCB_UNCHECKED);
      }
      p_window_id=wid;
   }
}

/**
 * Update the specified project and its configurations in the
 * dependencies tree.  If only the projectIndex is provided,
 * this update is done at the project level and the config will be
 * implied by the current config.  If the configIndex is provided,
 * this update is done at the config level and the project will be
 * derived if not provided.
 *
 * @param curConfig Current config name
 * @param projectIndex
 *                  Index of the dependent project tree node
 * @param projectChecked
 *                  True if the project should be checked
 * @param configIndex
 *                  Index of the dependent config tree node
 * @param configChecked
 *                  True if the config should be checked
 */
static void updateDependenciesTreeInfo(_str curConfig,
                                       int projectIndex = -1, bool activeConfigChecked = false,
                                       int configIndex = -1, bool configChecked = false)
{
   wid := p_window_id;
   _control ctlDepsTree;
   p_window_id=ctlDepsTree;
   // if config information specified, give it priority
   if(configIndex >= 0) {
      // if the project index was not specified, infer it from the config node
      if(projectIndex < 0) {
         // Start with the config index, then move up the tree
         projectIndex = configIndex;
         for ( ;; ) {
            if ( _TreeGetDepth(projectIndex)==1 ) break;
            projectIndex = _TreeGetParentIndex(projectIndex);
         }
      }

      if(configChecked) {
         _TreeSetCheckState(configIndex,TCB_CHECKED);
         activeConfigCheckBox := getActiveConfigCheckboxFromConfigIndex(configIndex);
         _TreeSetCheckState(activeConfigCheckBox,TCB_UNCHECKED);

         // 1/10/2012 - We need to be sure that this is visible
         parentIndex := _TreeGetParentIndex(configIndex);
         _TreeSetInfo(parentIndex,TREE_NODE_EXPANDED);
      } else {
         // uncheck the config
         _TreeSetCheckState(configIndex, TCB_UNCHECKED);

         // ungraycheck the project if no other configs are checked
         uncheckProject := true;
         siblingConfigState := 0;
         siblingConfigIndex := _TreeGetFirstChildIndex(projectIndex);
         int siblingConfigPic;
         while(siblingConfigIndex >= 0) {
            // get the config information in the tree
            if ( _TreeGetCheckState(siblingConfigIndex) ) {
               uncheckProject = false;
               break;
            }

            // next config
            siblingConfigIndex = _TreeGetNextSiblingIndex(siblingConfigIndex);
         }
      }
   } else if(projectIndex >= 0) {
      int activeConfigIndex;
      if ( _TreeGetDepth(projectIndex)==1 ) {
         activeConfigIndex = getActiveConfigCheckboxFromProjectIndex(projectIndex);
      } else {
         activeConfigIndex = projectIndex;
      }
      otherConfigFolderIndex := _TreeGetNextSiblingIndex(activeConfigIndex);
      if(activeConfigChecked) {
         // check the project
         _TreeSetCheckState(activeConfigIndex, TCB_CHECKED);

         // disable the individual configurations
         checkAllChildren(otherConfigFolderIndex, TCB_UNCHECKED);
      } else {
         // uncheck the project
         _TreeSetCheckState(activeConfigIndex,TCB_UNCHECKED);

      }
   }
   p_window_id=wid;
}

static void checkAllChildren(int index,TreeCheckVal state)
{
   childIndex := _TreeGetFirstChildIndex(index);
   for ( ;; ) {
      if ( childIndex<0 ) break;
      _TreeSetCheckState(childIndex,state);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
}

static void updateDependenciesProjectInfo(_str curConfig, _str depProject, _str depConfig,
                                          bool checked, bool wasGraychecked)
{
   // if a config was clicked, depConfig will not be empty
   if(depConfig != "") {
      if(checked) {
         // make sure there is no longer a project level dependency
         _ProjectRemove_Dependency(gProjectHandle, depProject, "", "", curConfig, false);

         // add the config level dependency
         _ProjectAdd_Dependency(gProjectHandle, depProject, depConfig, "", curConfig);

         // update the DependsRef attribute for build, rebuild, clean targets
         updateDependsRefs(curConfig, true);

      } else if(wasGraychecked) {
         // this is the implied config level dependency and therefore
         // the project level dependency should be removed instead
         _ProjectRemove_Dependency(gProjectHandle, depProject, "", "", curConfig, false);

         // update the DependsRef attribute for build, rebuild, clean targets
         updateDependsRefs(curConfig, false);

      } else {
         // remove the dependency
         _ProjectRemove_Dependency(gProjectHandle, depProject, depConfig, "", curConfig, depConfig == "");

         // update the DependsRef attribute for build, rebuild, clean targets
         updateDependsRefs(curConfig, false);
      }
   } else if(checked) {
      // add the project level dependency
      _ProjectAdd_Dependency(gProjectHandle, depProject, depConfig, "", curConfig);

      // update the DependsRef attribute for build, rebuild, clean targets
      updateDependsRefs(curConfig, true);

   } else {
      // remove the project or config level dependency
      _ProjectRemove_Dependency(gProjectHandle, depProject, depConfig, "", curConfig, depConfig == "");

      // update the DependsRef attribute for build, rebuild, clean targets
      updateDependsRefs(curConfig, false);
   }
}

/**
 * Update the DependsRef attributes of the Build, Rebuild, and Clean
 * targets in the specified config.
 */
static void updateDependsRefs(_str config, bool enable)
{
   // look for a dependencies node for the specified configuration.  this
   // will be checked when enable is false because the DependsRef attribute
   // should only be removed if there are no dependencies.
   int dependenciesNode = _ProjectGet_DependenciesNode(gProjectHandle, config);

   // look for build target
   int buildTargetNode = _ProjectGet_TargetNode(gProjectHandle, "Build", config);
   if(buildTargetNode >= 0) {
      if(enable) {
         _ProjectSet_TargetDependsRef(gProjectHandle, buildTargetNode, config);
      } else if(dependenciesNode < 0) {
         // enable is false and there is no dependencies set, so clear the DependsRef
         _ProjectSet_TargetDependsRef(gProjectHandle, buildTargetNode, "");
      }
   }

   // look for rebuild target
   int rebuildTargetNode = _ProjectGet_TargetNode(gProjectHandle, "Rebuild", config);
   if(rebuildTargetNode >= 0) {
      if(enable) {
         _ProjectSet_TargetDependsRef(gProjectHandle, rebuildTargetNode, config);
      } else if(dependenciesNode < 0) {
         // enable is false and there is no dependencies set, so clear the DependsRef
         _ProjectSet_TargetDependsRef(gProjectHandle, rebuildTargetNode, "");
      }
   }

   // look for clean target
   int cleanTargetNode = _ProjectGet_TargetNode(gProjectHandle, "Clean", config);
   if(cleanTargetNode >= 0) {
      if(enable) {
         _ProjectSet_TargetDependsRef(gProjectHandle, cleanTargetNode, config);
      } else if(dependenciesNode < 0) {
         // enable is false and there is no dependencies set, so clear the DependsRef
         _ProjectSet_TargetDependsRef(gProjectHandle, cleanTargetNode, "");
      }
   }
}

static void clearDependenciesTree()
{
   wid := p_window_id;
   _control ctlDepsTree;
   p_window_id=ctlDepsTree;
   // iterate over projects unchecking everything
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;;) {
      if ( index<0 ) break;

      // process all configs
      defaultConfigIndex := _TreeGetFirstChildIndex(index);
      _TreeSetCheckState(defaultConfigIndex, TCB_UNCHECKED);
      otherConfigsIndex := _TreeGetNextSiblingIndex(defaultConfigIndex);
      if ( otherConfigsIndex>0 ) {
         childIndex := _TreeGetFirstChildIndex(otherConfigsIndex);
         for ( ;; ) {
            if ( childIndex<0 ) break;
            _TreeSetCheckState(childIndex, TCB_UNCHECKED);

            _TreeGetInfo(childIndex, auto state, auto bm1, auto bm2, auto flags);
            _TreeSetInfo(childIndex, state, bm1, bm2, flags&~TREENODE_DISABLED);
            _TreeSetCheckState(childIndex, TCB_UNCHECKED);

            // next config
            childIndex = _TreeGetNextSiblingIndex(childIndex);
         }
      }

      // next project
      index = _TreeGetNextSiblingIndex(index);
   }
   p_window_id=wid;
}

static void findAndCheckDependency(_str depProject, _str depConfig)
{
   wid := p_window_id;
   _nocheck _control ctlDepsTree;
   p_window_id=ctlDepsTree;
   // determine whether tree search will be case-sensitive or not
   searchOptions := "";
   if (_isWindows()) {
      searchOptions = "I";
   }

   // find it in the tree
   int depIndex = _TreeSearch(TREE_ROOT_INDEX, depProject, searchOptions);
   if(depIndex >= 0) {
      // now check to see if specific config was specified
      if(depConfig != "") {
         // find it in the tree
         int depConfigIndex = _TreeSearch(getOtherConfigFolderFromProjectIndex(depIndex), depConfig, "I");
         if(depConfigIndex >= 0) {
            // graycheck the project and check the config
            updateDependenciesTreeInfo(GetConfigText(), depIndex, false, depConfigIndex, true);
         } else {
            // check the project
            updateDependenciesTreeInfo(GetConfigText(), depIndex, true);
         }
      } else {
         // check the project
         updateDependenciesTreeInfo(GetConfigText(), depIndex, true);
      }
   }
   p_window_id=wid;
}

static int getActiveConfigCheckboxFromProjectIndex(int projectIndex)
{
   return _TreeGetFirstChildIndex(projectIndex);
}

static int getActiveConfigCheckboxFromConfigIndex(int configIndex)
{
   projectIndex := _TreeGetParentIndex(_TreeGetParentIndex(configIndex));
   return getActiveConfigCheckboxFromProjectIndex(projectIndex);
}

static int getOtherConfigFolderFromProjectIndex(int projectIndex)
{
   childIndex :=  _TreeGetFirstChildIndex(projectIndex);
   return _TreeGetNextSiblingIndex(childIndex);
}

static int getOtherConfigFolderFromAcitveConfig(int activeConfigIndex)
{
   return _TreeGetNextSiblingIndex(activeConfigIndex);
}

static int getProjectIndexFromActiveConfig(int activeConfigIndex)
{
   return _TreeGetParentIndex(activeConfigIndex);
}

static int getProjectIndexFromIndividualConfig(int individualConfigIndex)
{
   return _TreeGetParentIndex(_TreeGetParentIndex(individualConfigIndex));
}

static void resetDependenciesTreeFromNodeList(int (&dependencyNodes)[] = null)
{
   if (!haveProjectDependenciesTab()) {
      return;
   }

   state := 0;

   // uncheck everything in the dependencies tree
   clearDependenciesTree();

   // check the dependent project/configs
   int i, n = dependencyNodes._length();
   for(i = 0; i < n; i++) {
      int depNode = dependencyNodes[i];
      if(depNode < 0) continue;

      _str depProject = _xmlcfg_get_attribute(gProjectHandle, depNode, "Project");
      _str depConfig = _xmlcfg_get_attribute(gProjectHandle, depNode, "Config");

      if(depProject == "") {
         continue;
      }

      // make depProject relative to the workspace instead of this project
      depProject = _AbsoluteToProject(depProject, gProjectName);
      depProject = _RelativeToWorkspace(depProject);

      // check this dependency
      findAndCheckDependency(depProject, depConfig);
   }
}

static void resetDependenciesTreeFromAllConfigs(PROJECT_DEPENDENCY_INFO (&dependencyValues):[] = null)
{
   if (!haveProjectDependenciesTab()) {
      return;
   }

   state := 0;

   // uncheck everything in the dependencies tree
   clearDependenciesTree();

   // check the dependent project/configs
   typeless d;
   for(d._makeempty();;) {
      dependencyValues._nextel(d);
      if(d._isempty()) break;

      _str depProject = dependencyValues:[d].Project;
      _str depConfig = dependencyValues:[d].Config;

      if(depProject == "") {
         continue;
      }
      // make depProject relative to the workspace instead of this project
      depProject = _AbsoluteToProject(depProject, gProjectName);
      depProject = _RelativeToWorkspace(depProject);

      // check this dependency
      findAndCheckDependency(depProject, depConfig);
   }
}

static int okDependencies()
{
   // determine whether tree search will be case-sensitive or not
   searchOptions := "";
   if (_isWindows()) {
      searchOptions = "I";
   }

   // run thru the dependencies and make sure that all project level
   // dependencies have configs that match the implied config names
   //
   // NOTE: this is done by running thru the xml file instead of the
   //       tree because the tree only displays the representation
   //       of a single configuration (or the 'all configs' combined
   //       case).  the tree is only used to determine what configs
   //       a project has in order to avoid having to open all of
   //       the workspace projects again.
   foreach (auto config in gConfigList) {

      // get all dependencies for this config
      int dependencyNodes[] = null;
      _ProjectGet_DependencyProjectNodes(gProjectHandle, dependencyNodes, config);

      // only need to check project level dependencies
      int i;
      for(i = 0; i < dependencyNodes._length(); i++) {
         int depNode = dependencyNodes[i];
         if(depNode < 0) continue;

         _str depProject = _xmlcfg_get_attribute(gProjectHandle, depNode, "Project");
         depProject = stranslate(depProject,FILESEP,FILESEP2);
         _str depConfig = _xmlcfg_get_attribute(gProjectHandle, depNode, "Config");

         // if depConfig is not empty, this is a config level dependency
         // and does not need to be checked
         if(depConfig != "") continue;

         // find depProject in the dependencies tree
         int depProjectIndex = ctlDepsTree._TreeSearch(TREE_ROOT_INDEX, depProject, searchOptions);
         if(depProjectIndex >= 0) {
            // now check to see if this project has the current config
            int depConfigIndex = ctlDepsTree._TreeSearch(depProjectIndex, config, "IT");
            if(depConfigIndex < 0) {
               // config not found so switch to the dependencies tab
               _proj_prop_sstab.p_ActiveTab = PROJECTPROPERTIES_TABINDEX_DEPENDENCIES;

               // highlight the project in question and expand it
               ctlDepsTree._TreeSetCurIndex(depProjectIndex);

               int state, pic;
               ctlDepsTree._TreeGetInfo(depProjectIndex, state, pic);
               ctlDepsTree._TreeSetInfo(depProjectIndex, TREE_NODE_EXPANDED, pic, pic);

               // notify the user that there is a problem
               _message_box("The project '" depProject "' does not have a '" config "' configuration.  In order to specify a dependency\ron a project, one of the following criteria must be satisfied:\r\r     - There must be a matching configuration.\r\r     - A specific configuration must be selected.");

               // return an error so the project properties dialog will not close
               return -1;
            }
         }
      }
   }

   return 0;
}

static void fillInDefines(_str defines, _str lockedDefines)
{
   int newIndex;
   ctlDefinesTree._TreeDelete(TREE_ROOT_INDEX,'C');

   cur_def := "";
   while (lockedDefines!='') {
      cur_def=parse_next_option(lockedDefines,false);
      newIndex=ctlDefinesTree._TreeAddItem(TREE_ROOT_INDEX,cur_def,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
      ctlDefinesTree._TreeSetInfo(newIndex,TREE_NODE_COLLAPSED,-1,-1,TREENODE_BOLD);
   }
   while (defines!='') {
      cur_def=parse_next_option(defines,false);
      ctlDefinesTree._TreeAddItem(TREE_ROOT_INDEX,cur_def,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
   }
   if (ctlDefinesTree.p_EditInPlace && ctlDefinesTree.p_enabled) {
      // add the node for new data
      newIndex = ctlDefinesTree._TreeAddListItem(PROJ_BLANK_TREE_NODE_MSG);
      ctlDefinesTree._TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
   }
}

static _str allConfigsDefines(_str all_defines,_str cur_defines)
{
   _str init_defines=all_defines;
   all_defines='';

   while ((init_defines!='')&&(cur_defines!='')) {
      _str test_define=parse_next_option(init_defines,false);
      if (pos(test_define,cur_defines)) {
         if (all_defines!='') {
            strappend(all_defines,' ');
         }
         strappend(all_defines, '"'test_define'"');
      }
   }
   return all_defines;
}

void _ProjectGet_AllConfigsInfo(int handle,PROJECT_CONFIG_INFO &info,_str (&ConfigList)[]=null)
{
   info=null;
   ConfigList._makeempty();
   int array[] = null;
   _ProjectGet_Configs(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      ConfigList[ConfigList._length()]=_xmlcfg_get_attribute(handle,array[i],'Name');
      if (info==null) {
         _ProjectGet_ConfigInfo(handle,info,array[i]);
         info.IncludesMatchForAllConfigs=true;
         continue;
      }

      PROJECT_CONFIG_INFO info2;
      _ProjectGet_ConfigInfo(handle,info2,array[i]);

      if (!strieq(info2.Type,info.Type)) info.Type='';
      if (!strieq(info2.Type,info.Type)) info.Type='';
      if (!strieq(info2.AppType,info.AppType)) info.AppType='';
      if (!strieq(info2.AppTypeList,info.AppTypeList)) info.AppTypeList='';
      if (!strieq(info2.RefFile,info.RefFile)) info.RefFile='';
      if (info.OutputFile!=null && !strieq(info2.OutputFile,info.OutputFile)) info.OutputFile=null;
      if (info.ObjectDir!=null && !strieq(info2.ObjectDir,info.ObjectDir)) info.ObjectDir=null;
      if (info.DebugCallbackName!=null && !strieq(info2.DebugCallbackName,info.DebugCallbackName)) info.DebugCallbackName=null;
      if (!strieq(info2.Libs,info.Libs)) info.Libs='';
      if (!strieq(info2.Includes,info.Includes)) {
         info.Includes='';
         info.IncludesMatchForAllConfigs=false;
      }
      if (!strieq(info2.AssociatedIncludes,info.AssociatedIncludes)) info.AssociatedIncludes='';
      if (!strieq(info2.StopOnPreBuildError,info.StopOnPreBuildError)) info.StopOnPreBuildError=2;
      if (!strieq(info2.PreBuildCommands,info.PreBuildCommands)) info.PreBuildCommands='';
      if (!strieq(info2.StopOnPostBuildError,info.StopOnPostBuildError)) info.StopOnPostBuildError=2;
      if (!strieq(info2.PostBuildCommands,info.PostBuildCommands)) info.PostBuildCommands='';
      if (!strieq(info2.ClassPath,info.ClassPath)) info.ClassPath='';
      if (!strieq(info2.CompilerConfigName,info.CompilerConfigName)) info.CompilerConfigName='';
      info.Defines=allConfigsDefines(info.Defines,info2.Defines);
      info.AssociatedDefines=allConfigsDefines(info.AssociatedDefines,info2.AssociatedDefines);

      if (info.TargetList!=null && !strieq(info2.TargetList,info.TargetList)) info.TargetList=null;
      typeless j;
      for (j._makeempty();;) {
         PROJECT_TARGET_INFO *pt2=&info2.TargetInfo._nextel(j);
         if (j._isempty()) break;
         PROJECT_TARGET_INFO *pt=info.TargetInfo._indexin(j);
         if (!pt) {
            info.TargetInfo:[j]=*pt2;
            pt=&info.TargetInfo:[j];
         }
         if (!strieq(pt2->MenuCaption,pt->MenuCaption)) pt->MenuCaption='';
         if (!strieq(pt2->OutputExts,pt->OutputExts)) pt->OutputExts='';
         if (!strieq(pt2->LinkObject,pt->LinkObject)) pt->LinkObject=2;
         if (!strieq(pt2->BuildFirst,pt->BuildFirst)) pt->BuildFirst=2;
         if (!strieq(pt2->Verbose,pt->Verbose)) pt->Verbose=2;
         if (!strieq(pt2->Beep,pt->Beep)) pt->Beep=2;
         if (!strieq(pt2->ThreadDeps,pt->ThreadDeps)) pt->ThreadDeps=2;
         if (!strieq(pt2->ThreadCompiles,pt->ThreadCompiles)) pt->ThreadCompiles=2;
         if (!strieq(pt2->TimeBuild,pt->TimeBuild)) pt->TimeBuild=2;
         if (!strieq(pt2->Dialog,pt->Dialog)) pt->Dialog='';
         if (!strieq(pt2->Deletable,pt->Deletable)) pt->Deletable=2;
         if (!strieq(pt2->ShowOnMenu,pt->ShowOnMenu)) pt->ShowOnMenu='';
         if (!strieq(pt2->EnableBuildFirst,pt->EnableBuildFirst)) pt->EnableBuildFirst=2;
         if (pt->CaptureOutputWith!=null && !strieq(pt2->CaptureOutputWith,pt->CaptureOutputWith)) pt->CaptureOutputWith=null;
         if (!strieq(pt2->ClearProcessBuffer,pt->ClearProcessBuffer)) pt->ClearProcessBuffer=2;
         if (!strieq(pt2->RunInXterm,pt->RunInXterm)) pt->RunInXterm=2;
         if (!strieq(pt2->PreMacro,pt->PreMacro)) pt->PreMacro=2;
         if (pt->RunFromDir!=null && !strieq(pt2->RunFromDir,pt->RunFromDir)) pt->RunFromDir=null;
         if (!strieq(pt2->AppletClass,pt->AppletClass)) pt->AppletClass='';
         if (pt->Exec_CmdLine!=null && !strieq(pt2->Exec_CmdLine,pt->Exec_CmdLine)) pt->Exec_CmdLine=null;
         if (pt->Exec_Type!=null && !strieq(pt2->Exec_Type,pt->Exec_Type)) pt->Exec_Type=null;
         if (!strieq(pt2->Exec_OtherOptions,pt->Exec_OtherOptions)) pt->Exec_OtherOptions='';

         // check rules for each target
         typeless k;
         for(k._makeempty();;) {
            PROJECT_RULE_INFO* pr2 = &pt2->Rules._nextel(k);
            if(k._isempty()) break;
            PROJECT_RULE_INFO* pr = pt->Rules._indexin(k);
            if(!pr) {
               // not in pr, so add it
               pt->Rules:[k] = *pr2;
               pr = &pt->Rules:[k];
            }

            if(!strieq(pr2->InputExts,pr->InputExts)) pr->InputExts='';
            if(!strieq(pr2->OutputExts,pr->OutputExts)) pr->OutputExts='';
            if(!strieq(pr2->LinkObject,pr->LinkObject)) pr->LinkObject=2;
            if(!strieq(pr2->Dialog,pr->Dialog)) pr->Dialog='';
            if(!strieq(pr2->Deletable,pr->Deletable)) pr->Deletable=2;
            if(!strieq(pr2->RunFromDir,pr->RunFromDir)) pr->RunFromDir="";
            if(pr->Exec_CmdLine!=null && !strieq(pr2->Exec_CmdLine,pr->Exec_CmdLine)) pr->Exec_CmdLine=null;
            if(pr->Exec_Type!=null && !strieq(pr2->Exec_Type,pr->Exec_Type)) pr->Exec_Type=null;
            if(!strieq(pr2->Exec_OtherOptions,pr->Exec_OtherOptions)) pr->Exec_OtherOptions='';
         }
      }

      // look for dependencies that do not match
      typeless d;
      for(d._makeempty();;) {
         // get each dependency from info
         PROJECT_DEPENDENCY_INFO* pd = &info.DependencyInfo._nextel(d);
         if(d._isempty()) break;

         // check to see if that dependency is also in info2
         PROJECT_DEPENDENCY_INFO* pd2 = info2.DependencyInfo._indexin(d);
         if(!pd2) {
            // not in info2 so remove it from the all configs case
            info.DependencyInfo._deleteel(d);
            continue;
         }

         // no need to validate the dependency attributes because the
         // key (variable d above) is project/config/target which covers
         // all of the values already
      }
   }
}

void _ProjectGet_OneConfigsInfo(int handle,PROJECT_CONFIG_INFO &info,_str configName)
{
   info=null;
   int array[] = null;
   _ProjectGet_Configs(handle,array);
   for (i:=0; i<array._length(); ++i) {
      name := _xmlcfg_get_attribute(handle,array[i],'Name');
      if (!strieq(name, configName)) continue;
      _ProjectGet_ConfigInfo(handle,info,array[i]);
      info.IncludesMatchForAllConfigs=false;
      return;
   }
}

void ctlCurConfig.on_change(int reason)
{
   if (ignore_config_change) {
      return;
   }
   // call reinitCompileLink() before setting gChangingConfiguration.
   // If move this call after the assignment, you'll need to set it to 1 again.
   reinitCompileLink();
   gChangingConfiguration=true;
   /*if (!p_active_form.p_visible && p_text!=ALL_CONFIGS) {
      CHANGING_CONFIGURATION=0;
      return;
   } */

   _str ConfigName=GetConfigText();
   if (ConfigName=='') {
      return;
   }

   ctlToolUp.p_enabled=ctlToolDown.p_enabled=ctlToolAdvanced.p_enabled=true;
   ctlCompilerList.p_enabled=true;

   ToolName := GetTargetName();
   if (ToolName=='') {
      ToolName=lowcase(gInitialTargetName);
   }
   //ctlAppType.p_text must be set before we call the on_change event for ctlToolTree
   isJavaConfigType:=true;
   _str AppType;
   _str AppTypeList;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      _ProjectGet_AllConfigsInfo(gProjectHandle,gAllConfigsInfo,gConfigList);

      // do not allow them to edit includes for all configurations unless they match
      ctlIncDirLabel.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs;
      ctlBrowseUserIncludes.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs; // browse button
      ctlMoveUserIncludesUp.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs; // up button
      ctlMoveUserIncludesDown.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs; // down button
      ctlRemoveUserIncludes.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs; // delete button
      ctlUserIncludesList.p_enabled=gAllConfigsInfo.IncludesMatchForAllConfigs;
      ctlUserIncludesList.p_EditInPlace=gAllConfigsInfo.IncludesMatchForAllConfigs;
      if (!gAllConfigsInfo.IncludesMatchForAllConfigs) {
         ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                       MESSAGE_ALLCONFIG_INCLUDES_MISMATCH);
      }

      //_prjworking_dir.p_text= AllDirInfo.WorkingDir;
      if(!strieq(gAllConfigsInfo.Type,'java')) {
         isJavaConfigType=false;
         if(ctlUserIncludesList.p_EditInPlace) {
            ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                          _ProjectGet_AssociatedIncludes(gProjectHandle, false));
         }
      }

      //
      _prjref_files.p_text= gAllConfigsInfo.RefFile;
      ctlPreBuildCmdList._TreeSetDelimitedItemList(gAllConfigsInfo.PreBuildCommands, "\1", true);
      ctlPostBuildCmdList._TreeSetDelimitedItemList(gAllConfigsInfo.PostBuildCommands, "\1", true);

      ctlStopOnPreErrors.p_style=(gAllConfigsInfo.StopOnPreBuildError==2)?PSCH_AUTO3STATEB:PSCH_AUTO2STATE;
      ctlStopOnPreErrors.p_value = gAllConfigsInfo.StopOnPreBuildError;

      ctlStopOnPostErrors.p_style=(gAllConfigsInfo.StopOnPostBuildError==2)?PSCH_AUTO3STATEB:PSCH_AUTO2STATE;
      ctlStopOnPostErrors.p_value = gAllConfigsInfo.StopOnPostBuildError;
      AppTypeList=gAllConfigsInfo.AppTypeList;
      AppType=gAllConfigsInfo.AppType;

      // update build tab object directory and executable name
      ctlConfigObjectDir.p_text = (gAllConfigsInfo.ObjectDir == null)?  MESSAGE_ALLCONFIG_SETTING_MISMATCH : gAllConfigsInfo.ObjectDir;
      ctlConfigObjectDir.p_enabled = (gAllConfigsInfo.ObjectDir != null);
      ctlConfigObjectDirBrowse.p_enabled = (gAllConfigsInfo.ObjectDir != null);
      ctlConfigObjectDirButton.p_enabled = (gAllConfigsInfo.ObjectDir != null);
      ctlConfigOutputFile.p_text = (gAllConfigsInfo.OutputFile == null)?  MESSAGE_ALLCONFIG_SETTING_MISMATCH : gAllConfigsInfo.OutputFile;
      ctlConfigOutputFile.p_enabled = (gAllConfigsInfo.OutputFile != null);
      ctlConfigOutputFileBrowse.p_enabled = (gAllConfigsInfo.OutputFile != null);
      ctlConfigOutputFileButton.p_enabled = (gAllConfigsInfo.OutputFile != null);

      // update the compiler config name to match what appears in the compilers list
      if (gAllConfigsInfo.CompilerConfigName:==COMPILER_NAME_NONE) {
         // None is always the first item
         ctlCompilerList._lbtop();
      } else if (gAllConfigsInfo.CompilerConfigName=="") {
         // "" is at the end of the list
         ctlCompilerList._cbset_text(MESSAGE_ALLCONFIG_SETTING_MISMATCH);
         ctlCompilerList._lbbottom();
         ctlCompilerList.p_enabled=false;
      } else if (gAllConfigsInfo.CompilerConfigName:==COMPILER_NAME_LATEST) {
         // Latest is always listed second
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         gAllConfigsInfo.CompilerConfigName=ctlCompilerList._lbget_text();
      } else if (gAllConfigsInfo.CompilerConfigName:==COMPILER_NAME_DEFAULT) {
         // Default is always listed third
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         ctlCompilerList._lbdown();
         gAllConfigsInfo.CompilerConfigName=ctlCompilerList._lbget_text();
      }
      if (gAllConfigsInfo.CompilerConfigName!="") {
         ctlCompilerList._cbset_text(gAllConfigsInfo.CompilerConfigName);
         ctlCompilerList._lbfind_and_select_item(gAllConfigsInfo.CompilerConfigName);
      }

      fillInDefines(gAllConfigsInfo.Defines,gAllConfigsInfo.AssociatedDefines);

      ctlLibraries.p_text=gAllConfigsInfo.Libs;

      ctlToolTree._TreeDelete(TREE_ROOT_INDEX, "C");

      if (gAllConfigsInfo.TargetList!=null) {
         _str list=gAllConfigsInfo.TargetList;
         for (;;) {
            item := "";
            parse list with item "\1" list;
            if (item=="") {
               break;
            }
            lowcasedItem := lowcase(item);

            // only add + if there are rules for this target
            if(!gAllConfigsInfo.TargetInfo:[lowcasedItem].Rules._isempty()) {
               // add the target
               int targetIndex = ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);

               // add rules as children
               typeless r;
               for(r._makeempty();;) {
                  gAllConfigsInfo.TargetInfo:[lowcasedItem].Rules._nextel(r);
                  if(r._isempty()) break;

                  ctlToolTree._TreeAddItem(targetIndex, gAllConfigsInfo.TargetInfo:[lowcasedItem].Rules:[r].InputExts, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
               }
            } else {
               // add the target
               ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            }
         }
      } else {
         // Since all the tools are not the same, we can't change the menu order.  User must
         // pick a specific configuration.
         ctlToolUp.p_enabled=ctlToolDown.p_enabled=false;
         typeless i;
         for (i._makeempty();;) {
            gAllConfigsInfo.TargetInfo._nextel(i);
            if (i._isempty()) break;

            // only add + if there are rules for this target
            if(!gAllConfigsInfo.TargetInfo:[i].Rules._isempty()) {
               // add the target
               int targetIndex = ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, gAllConfigsInfo.TargetInfo:[i].Name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);

               // add rules as children
               typeless r;
               for(r._makeempty();;) {
                  gAllConfigsInfo.TargetInfo:[i].Rules._nextel(r);
                  if(r._isempty()) break;

                  ctlToolTree._TreeAddItem(targetIndex, gAllConfigsInfo.TargetInfo:[i].Rules:[r].InputExts, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
               }

               // sort the rules
               ctlToolTree._TreeSortCaption(targetIndex);

            } else {
               // add the target
               ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, gAllConfigsInfo.TargetInfo:[i].Name, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

            }
         }
         ctlToolTree._TreeSortCaption(TREE_ROOT_INDEX);
      }

      // update dependencies
      resetDependenciesTreeFromAllConfigs(gAllConfigsInfo.DependencyInfo);

      // update run/debug tab items
      resetRunDebugInfo(gAllConfigsInfo);

   } else {
      // get the configuration information for this specific item
      PROJECT_CONFIG_INFO thisConfigInfo = null;
      _ProjectGet_OneConfigsInfo(gProjectHandle,thisConfigInfo,ConfigName);

      if (gIsExtensionProject && _ProjectGet_ConfigNode(gProjectHandle,ConfigName)<0) {
         _ProjectCreateLangSpecificConfig(gProjectHandle, ConfigName);
      }
      compiler_name := _ProjectGet_CompilerConfigName(gProjectHandle,ConfigName);

      if(!strieq(_ProjectGet_Type(gProjectHandle,ConfigName),'java')) {
         isJavaConfigType=false;
         ctlIncDirLabel.p_enabled=true;
         ctlBrowseUserIncludes.p_enabled=true; // browse button
         ctlMoveUserIncludesUp.p_enabled=true; // up button
         ctlMoveUserIncludesDown.p_enabled=true; // down button
         ctlRemoveUserIncludes.p_enabled=true; // delete button
         ctlUserIncludesList.p_enabled=true;
         ctlUserIncludesList.p_EditInPlace=true;

         ctlUserIncludesList._TreeSetDelimitedItemList(_ProjectGet_IncludesList(gProjectHandle, ConfigName),
                                                       PATHSEP, false,
                                                       _ProjectGet_AssociatedIncludes(gProjectHandle, false, ConfigName));
      }
      _prjref_files.p_text= _ProjectGet_RefFile(gProjectHandle,ConfigName);
      ctlPreBuildCmdList._TreeSetDelimitedItemList(_ProjectGet_PreBuildCommandsList(gProjectHandle,ConfigName), "\1", true);
      ctlPostBuildCmdList._TreeSetDelimitedItemList(_ProjectGet_PostBuildCommandsList(gProjectHandle,ConfigName), "\1", true);
      ctlStopOnPreErrors.p_style=PSCH_AUTO2STATE;
      ctlStopOnPreErrors.p_value = (int)_ProjectGet_StopOnPreBuildError(gProjectHandle,ConfigName);
      ctlStopOnPostErrors.p_style=PSCH_AUTO2STATE;
      ctlStopOnPostErrors.p_value = (int) _ProjectGet_StopOnPostBuildError(gProjectHandle,ConfigName);
      AppType= _ProjectGet_AppType(gProjectHandle,ConfigName);
      AppTypeList= _ProjectGet_AppTypeList(gProjectHandle,ConfigName);

      // update build tab object directory and executable name
      ctlConfigObjectDir.p_text = _ProjectGet_ObjectDir(gProjectHandle,ConfigName);
      ctlConfigObjectDir.p_enabled = true;
      ctlConfigObjectDirBrowse.p_enabled = true;
      ctlConfigObjectDirBrowse.p_enabled = true;
      if (ctlConfigObjectDir.p_text=="") ctlConfigObjectDir.p_text=ConfigName;
      ctlConfigOutputFile.p_text = _ProjectGet_OutputFile(gProjectHandle,ConfigName);
      ctlConfigOutputFile.p_enabled = true;
      ctlConfigOutputFileBrowse.p_enabled = true;
      ctlConfigOutputFileBrowse.p_enabled = true;

      // change the compiler name to match what is in the compiler list
      if (compiler_name:==COMPILER_NAME_NONE) {
         // None is always at the top of the list
         ctlCompilerList._lbtop();
         compiler_name=COMPILER_NAME_NONE;
      } else if (compiler_name:==COMPILER_NAME_LATEST) {
         // latest is always second in the list
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         compiler_name=ctlCompilerList._lbget_text();
      } else if (compiler_name:==COMPILER_NAME_DEFAULT || compiler_name=="") {
         // latest is always third in the list
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         ctlCompilerList._lbdown();
         compiler_name=ctlCompilerList._lbget_text();
      }
      ctlCompilerList._cbset_text(compiler_name);
      ctlCompilerList._lbfind_and_select_item(compiler_name);

      assoc_file := _ProjectGet_AssociatedFile(gProjectHandle);
      if (assoc_file != "") {
         fillInDefines(_ProjectGet_Defines(gProjectHandle,ConfigName),_ProjectGet_AssociatedDefines('',gProjectHandle,ConfigName,assoc_file,false));
      } else {
         fillInDefines(_ProjectGet_Defines(gProjectHandle,ConfigName),'');
      }

      ctlLibraries.p_text=_ProjectGet_DisplayLibsList(gProjectHandle,ConfigName);

      typeless array[];
      _ProjectGet_Targets(gProjectHandle,array,ConfigName);
      ctlToolTree._TreeDelete(TREE_ROOT_INDEX, "C");
      int i;
      for (i=0;i<array._length();++i) {
         _str item = _xmlcfg_get_attribute(gProjectHandle,array[i],'Name');

         // only add + if there are rules for this target
         int rulesArray[] = null;
         _ProjectGet_Rules(gProjectHandle, rulesArray, item, ConfigName);
         if(rulesArray._length() > 0) {
            // add the target
            int targetIndex = ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);

            // add rules as children
            int ruleIndex;
            for(ruleIndex = 0; ruleIndex < rulesArray._length(); ruleIndex++) {
               ctlToolTree._TreeAddItem(targetIndex, _ProjectGet_TargetInputExts(gProjectHandle, rulesArray[ruleIndex]), TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
            }
         } else {
            // add the target
            ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, item, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
         }
      }

      // update dependencies
      int dependencyNodes[] = null;
      _ProjectGet_DependencyProjectNodesForRef(gProjectHandle, ConfigName, ConfigName, dependencyNodes);
      resetDependenciesTreeFromNodeList(dependencyNodes);

      // update run/debug tab items
      resetRunDebugInfo(thisConfigInfo);
   }

   ctlToolTree._TreeRefresh();
   if (isJavaConfigType) {
      ctlIncDirLabel.p_enabled=false;
      ctlDefinesLabel.p_enabled=false;
      ctlDefinesTree.p_EditInPlace=false;
      ctlDefinesTree.p_enabled=false;
      ctlAddDefine.p_enabled=false;
      ctlAddUndef.p_enabled=false;
      ctlUserIncludesList.p_enabled=false;
      ctlUserIncludesList.p_next.p_enabled=false; // browse button
      ctlMoveUserIncludesUp.p_enabled=false; // up button
      ctlMoveUserIncludesDown.p_enabled=false; // down button
      ctlRemoveUserIncludes.p_enabled=false; // delete button
      //ctlCompilerList.p_enabled=false;
      ctlBuild_vsbuild.p_visible=false;
      ctlBuild_AutoMakefile.p_visible=false;
      ctlBuild_Custom.p_visible=false;
      ctlBuildDescription.p_visible=false;
      ctlMakefileLabel.p_visible=false;
      ctlAutoMakefile.p_visible=false;
      ctlAutoMakefileButton.p_visible=false;
      ctlBuildSystem.p_visible=false;
      ctlLibrariesLabel.p_enabled=false;
      ctlLibraries.p_enabled=false;
      ctlLinkOrder.p_enabled=false;
      ctlLibrariesButton.p_enabled=false;
      ctlThreadMake.p_visible = false;
      ctlMakeJobs.p_visible = false;
      ctlMakeJobsSpinner.p_visible = false;
      ctlThreadMake.p_enabled = false;
      ctlMakeJobs.p_enabled = false;
      ctlMakeJobsSpinner.p_enabled = false;
   } else {
      ctlBuild_vsbuild.p_visible=true;
      ctlBuild_AutoMakefile.p_visible=true;
      ctlBuild_Custom.p_visible=true;
      ctlBuildDescription.p_visible=true;
      ctlMakefileLabel.p_visible=true;
      ctlAutoMakefile.p_visible=true;
      ctlAutoMakefileButton.p_visible=true;
      ctlBuildSystem.p_visible=true;
      ctlThreadMake.p_visible = true;
      ctlMakeJobs.p_visible = true;
      ctlMakeJobsSpinner.p_visible = true;
   }

   int status = ctlToolTree._TreeSearch(TREE_ROOT_INDEX, ToolName, "I");
   if(status >= 0) {
      ctlToolTree._TreeSetCurIndex(status);
   } else if (ctlToolTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX) >= 0) {
      // not found so default to first in list
      ctlToolTree._TreeTop();
   } else {
      ctlToolTree._TreeSetCurIndex(0);
   }
   ctlToolTree._TreeSelectLine(ctlToolTree._TreeCurIndex());

   if (AppTypeList!='') {
      //If this is not a hash table, this project just does not have any
      //application type info
      //
      //Now set the ctlAppType combo box to the appropriate value
      //Try to get the combo box's list box on the right line
      ctlAppType._lbclear();
      ctlAppType.FillInAppTypes(AppTypeList);
      ctlAppType._lbtop();
      ctlAppType._lbfind_and_select_item(AppType);
      ctlAppType.p_text=_GetAppTypeDescription(AppTypeList,AppType);
      //if (!ctlAppTypeLabel.p_visible) {
         ctlAppType.p_visible=ctlAppTypeLabel.p_visible=true;
         resizeToolsTab(0, 0, toggleAppTypeVisible:true);
      //}
   } else {
      ctlHelpLabelTools.p_visible=true;
      //if (ctlAppTypeLabel.p_visible) {
         ctlAppType.p_visible=ctlAppTypeLabel.p_visible=false;
         resizeToolsTab(0, 0, toggleAppTypeVisible:true);
      //}
   }
   _srcfile_list.FillInSrcFileList(getCurrentConfig());

   ctlToolTree.call_event(CHANGE_SELECTED, ctlToolTree._TreeCurIndex(), ctlToolTree, ON_CHANGE, 'W');
   ctlToolTree.refresh();

   gChangingConfiguration=false;
}

void _prjref_files.on_change()
{
   if (gChangingConfiguration==1) return;
   text := strip(p_text,'B','"');
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      gAllConfigsInfo.RefFile=text;
      foreach (auto config in gConfigList) {
         _ProjectSet_RefFile(gProjectHandle,text,config);
      }
   } else {
      _ProjectSet_RefFile(gProjectHandle,text,GetConfigText());
   }
}

void ctlConfigObjectDir.on_change()
{
   if (gChangingConfiguration==1) return;
   text := strip(p_text,'B','"');
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      gAllConfigsInfo.ObjectDir=text;
      foreach (auto config in gConfigList) {
         _ProjectSet_ObjectDir(gProjectHandle,text,config);
      }
   } else {
      if (text == GetConfigText()) text="";
      _ProjectSet_ObjectDir(gProjectHandle,text,GetConfigText());
   }
}

void ctlConfigOutputFile.on_change()
{
   if (gChangingConfiguration==1) return;
   text := strip(p_text,'B','"');
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      gAllConfigsInfo.OutputFile=text;
      foreach (auto config in gConfigList) {
         _ProjectSet_OutputFile(gProjectHandle,text,config);
      }
   } else {
      _ProjectSet_OutputFile(gProjectHandle,text,GetConfigText());
   }
}

void ctlBuild_vsbuild.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = false;
   ctlAutoMakefileButton.p_enabled = false;
   ctlThreadMake.p_enabled = false;
   ctlMakeJobs.p_enabled = false;
   ctlMakeJobsSpinner.p_enabled = false;
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   foreach (auto config in gConfigList) {
      switchBuildSystem(config,BuildSystem,BuildMakeFile,BuildOptions);
   }
}

void ctlBuild_Custom.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = false;
   ctlAutoMakefileButton.p_enabled = false;
   ctlThreadMake.p_enabled = false;
   ctlMakeJobs.p_enabled = false;
   ctlMakeJobsSpinner.p_enabled = false;
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   foreach (auto config in gConfigList) {
      switchBuildSystem(config,BuildSystem,BuildMakeFile,BuildOptions);
   }
}

void ctlBuild_AutoMakefile.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = true;
   ctlAutoMakefileButton.p_enabled = true;
   ctlThreadMake.p_enabled = true;
   ctlMakeJobs.p_enabled = (ctlMakeJobs.p_text != 0);
   ctlMakeJobsSpinner.p_enabled = (ctlMakeJobs.p_text != 0);;
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   foreach (auto config in gConfigList) {
      switchBuildSystem(config,BuildSystem,BuildMakeFile,BuildOptions);
   }
}

void ctlAutoMakefile.on_change()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   // change buildmakefile to whatever is in ctlAutoMakefile
   BuildMakeFile = strip(ctlAutoMakefile.p_text,'B','"');

   foreach (auto config in gConfigList) {
      switchBuildSystem(config,BuildSystem,BuildMakeFile,BuildOptions);
   }
}

void ctlThreadMake.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   checked := (p_value != 0);
   ctlMakeJobs.p_enabled = checked;
   ctlMakeJobsSpinner.p_enabled = checked;
   ObjectDir := "";
   OutputFile := "";
   BuildSystem := "";
   BuildMakeFile := "";
   BuildOptions := "";
   GetBuildOptions(ObjectDir,OutputFile,BuildSystem,BuildMakeFile,BuildOptions);

   foreach (auto config in gConfigList) {
      switchBuildSystem(config,BuildSystem,BuildMakeFile,BuildOptions);
   }
}

static int storeDependencyInfo(int index)
{
   _TreeGetInfo(index, auto state, auto pic);
   arrayIndex := _TreeGetUserInfo(index);

   // note whether this is a config or a project.  if it is a config,
   // it will be a leaf node (state == -1).  otherwise, it is a project.
   depth := _TreeGetDepth(index);
   isProject := (depth == 2);  // This is actually the "Active Config" checkbox
   isConfig := (depth == 3);

   // toggle the picture, remembering if it was enabled or not so the
   // value can be set in the project
   checked := _TreeGetCheckState(index) != 0;

   if(isProject) {
      // update the project and potentially graycheck the implied config
      updateDependenciesTreeInfo(GetConfigText(), index, checked);
   } else if(isConfig) {
      // update the config and potentially graycheck the parent project
      updateDependenciesTreeInfo(GetConfigText(), -1, false, index, checked);
   }

   // get the names of the project (and config if applicable)
   depProject := depConfig := "";
   if(isProject) {
      depProject = _TreeGetCaption(getProjectIndexFromActiveConfig(index));
   } else {
      depProject = _TreeGetCaption(getProjectIndexFromIndividualConfig(index));
      depConfig = _TreeGetCaption(index);
   }

   // now store the information in the project
   if(getCurrentConfig() == PROJ_ALL_CONFIGS) {
      if ( checked ) {
         // First, get rid of any checked individual configs, or checked active
         // config, depending on what was clicked on
         // 
         if ( isProject ) {
            getConfigListFromTree(index,auto configList);
            foreach ( auto configName in configList ) {
               updateDependenciesProjectInfoForAllConfigs(depProject, configName, false, false);
            }
         }
      }
      updateDependenciesProjectInfoForAllConfigs(depProject, depConfig, checked, false);
   } else {
      if ( checked ) {
         if ( isProject ) {
            getConfigListFromTree(index,auto configList);
            foreach ( auto configName in configList ) {
               updateDependenciesProjectInfoForAllConfigs(depProject, configName, false, false);
            }
         }
      }
      // set the value in the current config in the project
      updateDependenciesProjectInfo(GetConfigText(), depProject, depConfig, checked, false);
   }

   return 0;
}
static void updateDependenciesProjectInfoForAllConfigs(_str depProject, _str depConfig,bool checked, bool wasGraychecked)
{
   foreach (auto config in gConfigList) {

      // set the value in each config in the project
      updateDependenciesProjectInfo(config, depProject, depConfig, checked, false);

      // update the values in the all configs hash table
      if(checked) {
         PROJECT_DEPENDENCY_INFO* pd = &gAllConfigsInfo.DependencyInfo:[lowcase(depProject "/" depConfig "/" /*depTarget*/)];
         pd->Project = depProject;
         pd->Config  = depConfig;
      } else {
         gAllConfigsInfo.DependencyInfo._deleteel(lowcase(depProject "/" depConfig "/" /*depTarget*/));
      }
   }
}
static void getConfigListFromTree(int index,STRARRAY &configList)
{
   configList = null;
   otherConfigIndex := getOtherConfigFolderFromAcitveConfig(index);
   childIndex := _TreeGetFirstChildIndex(otherConfigIndex);
   for ( ;; ) {
      if ( childIndex<0 ) break;
      configList[configList._length()] = _TreeGetCaption(childIndex);
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
}

int ctlDepsTree.on_change(int reason,int index)
{
   if ( _GetDialogInfoHt("inDepsOnChange")==1 ) return 0;
   _SetDialogInfoHt("inDepsOnChange",1);
   if ( index>0 ) {
      // >0 because this will not happen on root
      switch ( reason ) {
      case CHANGE_CHECK_TOGGLED:
         storeDependencyInfo(index);
         break;
      }
   }
   _SetDialogInfoHt("inDepsOnChange",0);
   return 0;
}

static void DisableProjectControlsForWorkspace(bool LeaveFileTabEnabled=false,
                                               bool LeaveDepsTabEnabled=true)
{
   _add.DisableAll();
   _srcfile_list.p_enabled=true;//Want users to be able to scroll through files

   if (LeaveFileTabEnabled) {
      _add.p_enabled=true;
      _addtree.p_enabled=true;
      _invert.p_enabled=true;
      ctlrefresh.p_enabled=true;
      _remove.p_enabled=true;
      _remove_all.p_enabled=true;
      ctlproperties.p_enabled=true;

      ctlUserIncludesList.p_enabled=true;
      _project_nofselected.p_enabled=true;
      _project_nofselected.p_prev.p_enabled=true;
      if (_haveBuild()) ctlCompilerList.p_enabled=true;
   }

   _prjworklab.p_enabled=false;
   _prjworking_dir.p_enabled=false;
   _prjworking_dir.p_next.p_enabled=false; // browse button
   _prjworking_dir.p_next.p_next.p_enabled=false; // menu button
   //_prjref_files.p_prev.p_enabled=false; // references label
   //_prjref_files.p_enabled=false;
   //_prjref_files.p_next.p_enabled=false; // browse button
   //_prjref_files.p_next.p_next.p_enabled=false; // menu button

   ctlIncDirLabel.p_enabled=true;
   ctlBrowseUserIncludes.p_enabled=true; // browse button
   ctlMoveUserIncludesUp.p_enabled=true; // up button
   ctlMoveUserIncludesDown.p_enabled=true; // down button
   ctlRemoveUserIncludes.p_enabled=true; // delete button
   ctlUserIncludesList.p_EditInPlace=true;

   if (_haveBuild()) {
      ctlDefinesLabel.p_enabled=true;
      ctlDefinesTree.p_EditInPlace=true;
      ctlAddDefine.p_enabled=true;
      ctlAddUndef.p_enabled=true;
      ctlCaptureOutputFrame.p_enabled=true;
      ctlToolCaptureOutput.p_enabled=true;
      ctlToolOutputToConcur.p_enabled=true;
      ctlToolClearProcessBuf.p_enabled=true;
      ctlRunFromDir.p_enabled=true;
      ctlHelpLabelDir.p_enabled=true;

      // Disable all the Build tab controls (this requires removing the
      // <double click here to add another entry> nodes from the trees)
      ctlPreBuildCmdList._TreeDelete(TREE_ROOT_INDEX, 'C');
      ctlPostBuildCmdList._TreeDelete(TREE_ROOT_INDEX, 'C');
      ctlPreBuildCmdList.DisableAll();

      if(!LeaveDepsTabEnabled) {
         ctlDepsTree.p_enabled = false;
      }
   }
}

static void DisableAll()
{
   origwid := p_window_id;
   int wid=origwid;
   for (;;) {
      wid=wid.p_next;
      wid.p_enabled=false;
      if (wid.p_object==OI_FRAME) {
         int child=wid.p_child;
         if (child) {
            child.DisableAll();
         }
      }
      if (wid==origwid) {
         break;
      }
   }
}

_ok.on_destroy()
{
   //if (!sstIsControlExists("_openchange_dir")) return( "" );
   if (gOrigProjectFileList) {
      _delete_temp_view(gOrigProjectFileList);
   }
   if (gMakeCopyFirst) {
      _xmlcfg_close(gProjectHandle);
   }

   if (_haveBuild()) _append_retrieve(0, ctlToolTree._TreeGetCaption(ctlToolTree._TreeCurIndex()), "_project_form.toolNameSelected");
}

static void _InitAddFileToConfig(int (&FileToNode):[],int &FilesNode,_str &AutoFolders,int (&ExtToNodeHashTab):[],_str &LastExt,int &LastNode,int projectHandle=gProjectHandle)
{
   LastExt=null;
   LastNode= -1;
   _ProjectGet_FileToNodeHashTab(projectHandle,FileToNode);
   FilesNode=_ProjectGet_FilesNode(projectHandle,true);
   AutoFolders=_ProjectGet_AutoFolders(projectHandle);

   _ProjectGet_ExtToNode(projectHandle,ExtToNodeHashTab);
}
/**
 * Adds file to the file view for the specified
 * configuration.  If the file will now be in all
 * configurations, it is added to the
 * "All Configurations" view and removed from the others.
 *
 * @param Filename   Filename to add
 *
 * @param ConfigName Name of configuration to add the file to
 *
 * @param SortBuffer If true(default), the buffer is sorted when done.
 */
static void AddFileToConfig(int list_wid,_str Filename,_str ConfigName,
                            int (&FileToNode):[]=null,
                            int FilesNode=-1,_str AutoFolders=null,int (&ExtToNodeHashTab):[]=null,
                            _str &LastExt=null,
                            int &LastNode= -1,
                            WILDCARD_FILE_ATTRIBUTES attrs=null,
                            int projectHandle = gProjectHandle,
                            )
{
   if ( list_wid ) {
      list_wid._lbadd_item(Filename);
   }

   gFileListModified=true;
   cfilename := _file_case(Filename);

   if (FileToNode==null) {
      _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode,projectHandle);
   }

   directoryFolder := (attrs != null) ? attrs.DirectoryFolder : false;

   int *pnode=FileToNode._indexin(cfilename);
   Node := 0;
   if (pnode) {
      Node=*pnode;
   } else {
      if (directoryFolder) {
         if (FilesNode<0) {
            FilesNode=_ProjectGet_FilesNode(projectHandle,true);
         }
         Node = _xmlcfg_add(projectHandle, FilesNode, 'F', VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(projectHandle, Node, 'N', _NormalizeFile(stranslate(Filename,'%%','%')));
         FileToNode:[cfilename] = Node;

      } else {
         if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
            _ProjectAdd_FilteredFiles(projectHandle,Filename,FileToNode,ExtToNodeHashTab,LastExt,LastNode);
         } else {
            _str list[];
            list[0]=Filename;
            _ProjectAdd_Files(projectHandle,list,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,false);
         }
      }
      Node=FileToNode:[cfilename];
   }
   if (ConfigName==PROJ_ALL_CONFIGS) {
      _xmlcfg_delete_attribute(projectHandle,Node,'C');
   } else {
      _str configs=_xmlcfg_get_attribute(projectHandle,Node,'C');

      int i;
      i=pos(always_quote_filename(ConfigName),configs);
      if (!i) {
         configs=strip(configs' 'always_quote_filename(ConfigName));

         _str temp=configs;
         // Check if this file contains all configs
         int count;
         for (count=0;temp!='';++count) {
            parse temp with '"' . '"' temp;
         }
         if (count>=gConfigList._length()) {
            _xmlcfg_delete_attribute(projectHandle,Node,'C');
         } else {
            _xmlcfg_set_attribute(projectHandle,Node,'C',configs);
         }
      }
   }

   if (attrs!=null) {
      _xmlcfg_set_attribute(projectHandle,Node,'Recurse',attrs.Recurse);
      _xmlcfg_set_attribute(projectHandle,Node,'Excludes',_NormalizeFile(attrs.Excludes));
      if (attrs.ListMode) {
         _xmlcfg_set_attribute(projectHandle,Node,'L',attrs.ListMode);
      }
      if (directoryFolder) {
         _xmlcfg_set_attribute(projectHandle,Node,'D',directoryFolder);
      }
   }
}


/**
 * Add all files under the specified tree node to the provided
 * hash table.  This function is called by the open file dialog
 * callback that is used with the Project Properties dialog
 * and the Files tab of the Project Toolbar.
 *
 * @param treeID    ID of the tree control that contains the node
 * @param index     The index of the node to add
 * @param hashTable Hash table to add files to
 */
static void addFilesToHashFromTree(int treeID, int index, bool (&hashTable):[])
{
   if (index < 0) {
      return;
   }

   // make sure it is a file (ignore projects, folders, dependent projects, etc)
   if (treeID._projecttbIsProjectFileNode(index)) {
      // extract the absolute filename from the tree caption
      caption := treeID._TreeGetCaption(index);
      filename := "";
      absoluteFilename := "";
      parse caption with filename "\t" absoluteFilename;
      absoluteFilename = _AbsoluteToWorkspace(absoluteFilename);

      // add to the hash table
      absoluteFilename = stranslate(absoluteFilename, FILESEP, FILESEP2);
      hashTable:[_file_case(absoluteFilename)] = true;
   }

   // if this is a leaf node, do nothing
   // if this node hasn't been expanded yet, expand it now 
   treeID._TreeGetInfo(index, auto show_children);
   if (show_children == TREE_NODE_LEAF) return;
   if (show_children == TREE_NODE_COLLAPSED && treeID._TreeGetFirstChildIndex(index) < 0) {
      treeID.call_event(CHANGE_EXPANDED,index,treeID,ON_CHANGE,'w');
   }

   childIndex := treeID._TreeGetFirstChildIndex(index);
   while (childIndex >= 0) {
      addFilesToHashFromTree(treeID, childIndex, hashTable);

      // move next
      childIndex = treeID._TreeGetNextSiblingIndex(childIndex);
   }
}

/**
 * This is the callback that is called for each item before it
 * is included on the Open dialog that is shown when the user
 * clicks Add Files on the Files tab of the Project Properties
 * dialog.
 *
 * IMPORTANT: This function must *only* be called while the
 *            Project Properties dialog is open, unless this
 *            is the init case (filename == "")
 *
 * @param filename
 *
 * @return
 */
bool projectPropertiesAddFilesCallback(_str filename = "", _str projectName="")
{
   //say("projectPropertiesAddFilesCallback: HERE, filename="filename" project="projectName);
   static bool projectPropertiesAddFileHash:[];
   static bool projectPropertiesAddWildcardHash:[];

   //say("projectPropertiesAddFilesCallback: filename="filename);
   // if def_show_prjfiles_in_open_dlg is 1 then this callback has
   // been globally disabled by the user
   if (def_show_prjfiles_in_open_dlg == PROJECT_ADD_SHOWS_FILES_ALREADY_IN_PROJECT) {
      return true;
   }

   // if filename is empty, clean the cached information
   if (filename == "") {
      projectPropertiesAddFileHash._makeempty();
      projectPropertiesAddWildcardHash._makeempty();
      if (projectName == "") {
         return false;
      }

      // if the file hash is empty, this is the first time the callback has
      // been called for this open dialog.  populate it with all the files
      // in the current config of the project
      if (projectPropertiesAddFileHash._isempty()) {
         //say("projectPropertiesAddFilesCallback:  ADDING FILES");
         // add known extensions that should be ignored
         //    (workspace, project, history, tag files)
         //
         // NOTE: this serves two purposes
         //          1. make hash lookups on ignored extensions possible
         //          2. make sure the hash table is not empty even if the project is empty
         projectPropertiesAddFileHash:[_file_case(WORKSPACE_FILE_EXT)] = true;
         projectPropertiesAddFileHash:[_file_case(WORKSPACE_STATE_FILE_EXT)] = true;
         projectPropertiesAddFileHash:[_file_case(PRJ_FILE_EXT)] = true;
         projectPropertiesAddFileHash:[_file_case(TAG_FILE_EXT)] = true;

         // figure out which dialog the open dialog was launched from
         fromProjectProperties := false;
         fromProjectToolbar := false;

         // search the ancestry all the way to the top
         origid := p_window_id;
         wid := p_window_id;
         for (;;) {
            if (strieq(wid.p_name, "_project_form")) {
               fromProjectProperties = true;
               break;
            } else if (strieq(wid.p_name, "_tbprojects_form")) {
               fromProjectToolbar = true;
               break;
            }

            // move up another level
            if (!wid.p_parent) break;
            wid = wid.p_parent;
         }
         p_window_id = wid;

         if (fromProjectProperties) {
            //say("projectPropertiesAddFilesCallback:  PROPERTIES");
            // the file list has already been processed, so just iterate thru
            // the source list box to save time
            projectPropertiesAddFileHash:[_file_case(gProjectName)] = true;
            numFiles := _srcfile_list.p_Noflines;
            for (i := 1; i <= numFiles; i++) {
               _srcfile_list._lbget_item_index(i, auto fname, auto pi);
               absoluteFilename := _AbsoluteToProject(fname, gProjectName);
               absoluteFilename = stranslate(absoluteFilename, FILESEP, FILESEP2);
               projectPropertiesAddFileHash:[_file_case(absoluteFilename)] = true;
               if (iswildcard(fname)) {
                  projectPropertiesAddWildcardHash:[fname] = true;
               }
            }
            // check to see if the open dialog was launched from the project toolbar
         } else if (fromProjectToolbar) {
            //say("projectPropertiesAddFilesCallback:  TOOLBAR");
            _nocheck _control _proj_tooltab_tree;
            // the file list has already been processed and wildcards have
            // been expanded in the project toolbar, so iterate thru the
            // tree to save time

            // find project that is the parent of the selected node
            projectNode := _proj_tooltab_tree._TreeCurIndex();
            while (_proj_tooltab_tree._TreeGetDepth(projectNode) > PROJECT_TOOLWIN_TREE_PROJECT_DEPTH) {
               projectNode = _proj_tooltab_tree._TreeGetParentIndex(projectNode);
            }
    
            // make sure node is expanded
            if (_proj_tooltab_tree._TreeGetFirstChildIndex(projectNode) < 0) {
               _proj_tooltab_tree.call_event(CHANGE_EXPANDED,projectNode,_proj_tooltab_tree.p_window_id,ON_CHANGE,'w');
            }

            // recursively walk the tree
            addFilesToHashFromTree(_proj_tooltab_tree, projectNode, projectPropertiesAddFileHash);
         } else {

            //say("projectPropertiesAddFilesCallback:  OTHER");
            // not coming from a form, use generic method to get project file list
            _getProjectFiles(_workspace_filename, projectName, auto fileList, 1);
            foreach (auto fname in fileList) {
               projectPropertiesAddFileHash:[_file_case(fname)] = true;
            }
         }

         // restore window id
         p_window_id = origid;
      }

      // just adding the files to the list, nothing else happening here
      return false;
   }

   // default to including it
   includeItem := true;

   // check to see if the file is in the hash table of known files
   //say("projectPropertiesAddFilesCallback:  TRYING FILE: "filename);
   filename = stranslate(filename, FILESEP, FILESEP2);
   if (projectPropertiesAddFileHash._indexin(_file_case(filename))) {
      //say("projectPropertiesAddFilesCallback:  IN HASH TAB");
      includeItem = false;
   }

   // check for a wildcard file match
   if (includeItem && !projectPropertiesAddWildcardHash._isempty()) {
      foreach (auto wc => . in projectPropertiesAddWildcardHash) {
         wildcardFilename := _AbsoluteToProject(wc, gProjectName);
         if (length(filename) < length(wildcardFilename)) continue;
         if (pos(_file_case(wildcardFilename), _file_case(filename), 1, '&') == 1 && pos('')==length(filename)) {
            includeItem = false;
            //say("projectPropertiesAddFilesCallback:  WILD CARD");
            break;
         }
      }
   }

   // if still being included, check to see if it is one of the ignored extensions
   if (includeItem) {
      ext := _get_extension(filename, true);
      if (projectPropertiesAddFileHash._indexin(_file_case(ext))) {
         //say("projectPropertiesAddFilesCallback: PROJECT OR WORKSPACE EXT");
         includeItem = false;
      }
   }

   return includeItem;
}

typeless getProjectPropertiesAddFilesCallback()
{
   if (def_show_prjfiles_in_open_dlg==PROJECT_ADD_SHOWS_FILES_ALREADY_IN_PROJECT) {
      return null;
   }
   if (def_show_prjfiles_in_open_dlg==PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG && !_NativeOpenDialogSupportsCallback()) {
      return null;
   }
   return projectPropertiesAddFilesCallback;
}

static int project_form_add_directory_folder(typeless dirs=''){
   // In case, the current directory changes, convert all input directories
   // to absolute.
   _str abs_dirs[];
   int i;
   for (i=0;;++i) {
      _str path;
      if (dirs._varformat()==VF_LSTR) {
         path=parse_file(dirs,false);
         if (path=='') break;
      } else { 
         if (i>=dirs._length()) break;
         path=dirs[i];
         if (path=='') continue;
      }
      path=absolute(path);
      _maybe_append_filesep(path);
      abs_dirs:+=path;
   }

   _str excludes=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES);
   excludes=_project_xlat_special_excludes(excludes);
   excludes=strip(excludes,'B',';');  // Strip leading and trailing semicolons
   _str excludeList[];
   split(excludes, ";", excludeList);

   _str includeList[];
   _str includes=_default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES);
   includes=strip(includes,'B',';');  // Strip leading and trailing semicolons
   split(includes, ";", includeList);

   i=0;
   int project_handle=gProjectHandle;
   for (;;++i) {
      _str path;
      if (i>=abs_dirs._length()) break;
      path=abs_dirs[i];
      if (path=='') continue;
      path=absolute(path);
      _maybe_append_filesep(path);

      //newfilename:= path:+includes;
      //_str RelFilename=_RelativeToProject(newfilename);
      bool is_custom_view=add_custom_folders();
      DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
      bool dont_prompt= (flags&DIRPROJFLAG_DONT_PROMPT)!=0;
      if (!dont_prompt) {
         if (add_tree_prompt(path,is_custom_view,true)) {
            break;
         }
      }
   }
   return 0;
}
void _project_form.on_drop_files() {

   _str directory_list[];
   _str file_list[];

   for ( ;; ) {
      _str filename = _next_drop_file();
      if ( filename == '' ) {
         break;
      }
      if (isdirectory(filename)) {
         _maybe_append_filesep(filename);
         directory_list:+=filename;
         continue;
      }
      file_list:+=filename;
   }
   //say('name='p_name);
   //say('files='file_list._length());
   if (file_list._length()) {
      doAddFiles2(file_list);
   }
   if (directory_list._length()) {
      project_form_add_directory_folder(directory_list);
   }
   //say('dir='directory_list._length());
}

static doAddFiles2(typeless result) {
   _str config=getCurrentConfig();
   int list_wid=_srcfile_list;
   filelist_view_id := 0;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   if (result._varformat()==VF_ARRAY) {
      for (i:=0;i<result._length();++i) {
         insert_line(' 'result[i]);
      }
   } else {
      _str file_spec_list = result;
      while (file_spec_list != '') {
         _str file_spec = parse_file(file_spec_list);
         insert_file_list(file_spec' -v +p -d');
      }
   }
   p_line=0;
   path := _strip_filename(gProjectName,'N');
   int FileToNode:[];
   FilesNode := 0;
   AutoFolders := "";
   int ExtToNodeHashTab:[];
   LastExt := "";
   LastNode := 0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);

   list_wid._lbbegin_update();
   for (;;) {
      if (down()) {
         break;
      }
      filename := "";
      get_line(filename);
      filename=substr(filename,2);
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      AddFileToConfig(list_wid,relative(filename,path),config,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   list_wid._lbend_update(list_wid.p_Noflines);
   _delete_temp_view(filelist_view_id);
   activate_window(orig_view_id);
   _srcfile_list._lbsort('-f');
   _srcfile_list._lbremove_duplicates(_fpos_case);
   _srcfile_list._lbtop();

   // Update the buttons associated with the lists:
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');
}
void _add.lbutton_up()
{
   gFileListModified=true;
   form_wid := p_active_form;

   // init the callback so it clears its cache
   projectPropertiesAddFilesCallback("", gProjectName);

   working_dir := absolute(_ProjectGet_WorkingDir(gProjectHandle), _strip_filename(gProjectName, 'N'));
   result := p_window_id._OpenDialog("-modal",
                         'Add Source Files',// title
                         _last_wildcards,// Initial wildcards
                         def_file_types:+',':+EXTRA_FILE_FILTERS,
                         OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                         "", // Default extension
                         ""/*wildcards*/, // Initial filename
                         working_dir, // Initial directory
                         "",
                         "",
                         getProjectPropertiesAddFilesCallback()); // include item callback

   // cleanup after the callback so it clears its cache
   projectPropertiesAddFilesCallback("");

   //chdir(olddir,1);
   if (result=='') return;


   doAddFiles2(result);
}

static void updateControlsNofSelected()
{
   _project_nofselected.p_caption=_srcfile_list.p_Nofselected' of '_srcfile_list.p_noflines' Files Selected';

   if (!gLeaveFileTabEnabled) {
      return;
   }
   // If there is nothing in _srcfile_list, disable Remove All button and
   // if there is nothing selected in _srcfile_list, disable Remove button
   ctlproperties.p_enabled=iswildcard(_srcfile_list._lbget_text()) && !_IsWorkspaceAssociated(_workspace_filename);
   if (_srcfile_list.p_noflines== 0) {
      _remove_all.p_enabled= false;
      _remove.p_enabled= false;
      _invert.p_enabled= false;
   } else {
      _remove_all.p_enabled= true;
      _invert.p_enabled= true;
      if (_srcfile_list.p_Nofselected > 0) {
         _remove.p_enabled= true;
      } else {
         _remove.p_enabled= false;
      }
   }
}
_srcfile_list.on_change()
{
   updateControlsNofSelected();
}

static _str calculateFileSpec(int projectHandle, _str projectName) {
   returnVal := '';
   configType := "";
   configType2 := "";

   if (!_GetAssociatedProjectInfo(projectName, auto associatedFile, auto associatedFileType)) {
      return associatedFileType;
   }

   int i;
   PrevNode := 0;
   NextNode := 0;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         configType2 = _ProjectGet_Type(projectHandle, config);
         //Consider 'gnuc', 'vcpp' and 'cpp' all to be 'cpp'
         if (configType2 == 'gnuc' || configType2 == 'vcpp') {
            configType2 = 'cpp';
         }
         if (configType == '') {
            configType = configType2;
         } else if (configType2 != configType) {
            //different configs have different types so just return default
            return returnVal;
         }
      }
   } else {
      configType = _ProjectGet_Type(projectHandle, getCurrentConfig());
   }

//messageNwait(status' |'AssociatedFileType'|');
   return returnVal;
}

static bool add_custom_folders()
{
   // well, we have to have a workspace, and it needs to be one of ours
   if (_workspace_filename=='' || _IsWorkspaceAssociated(_workspace_filename)) {
      return false;
   }

   // we only allow this in custom view
   AutoFolders := _ProjectGet_AutoFolders(gProjectHandle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      return true;
   }

   // just forget it
   return false;
}

void _addtree.lbutton_up()
{
   int status;
   olddir := getcwd();
   working_dir := absolute(_ProjectGet_WorkingDir(gProjectHandle), _strip_filename(gProjectName, 'N'));
   chdir(working_dir,1);

   _str fileSpec = calculateFileSpec(gProjectHandle, gProjectName);
   allowCustomFolders := add_custom_folders();

   typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
                        'Add Tree',
                        fileSpec,
                        true,
                        true,
                        gProjectName,
                        !_IsWorkspaceAssociated(_workspace_filename),
                        true,
                        allowCustomFolders);
   chdir(olddir,1);

   if (result== "") {
      return;
   }
// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard

// _param7 - list folders
// _param8 - directory folder
   // _param5 specifies whether this tree was added as a wildcard or not
   if (_param5) {
      // add as wildcards!
      _addWildcardsToProject(_param1, _param6, _param4, _param2, _param3, gProjectName, gProjectHandle,_param7,_param8);
   } else {
      addTreeToProject(_param1, _param6, _param4, _param2, _param3, _param7);
   }

   _param1._makeempty();
   _param4._makeempty();

   // Sort and remove duplicate items in the project source file list:
   _srcfile_list._lbdeselect_all();
   _srcfile_list._lbsort('-f');
   _srcfile_list._lbremove_duplicates(_fpos_case);
   _srcfile_list._lbtop();

   // Update the buttons associated with the lists:
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');

   // Remove all matching files in the directory file list:
   gFileListModified=true;

   // Indicate that the project source file list has been modified:
   mou_hour_glass(false);
   clear_message();
}

void _addWildcardsToProject(_str basePath, _str (&includeList)[], _str (&excludesList)[], bool recursive, bool followSymlinks, _str projectName=_project_name, int projectHandle=gProjectHandle, bool showFolders=true, bool directoryFolder=false)
{
   wid := _find_control("_srcfile_list");
   currentConfig := PROJ_ALL_CONFIGS;
   if ( wid ) {
      currentConfig = getCurrentConfig();
   }

   WILDCARD_FILE_ATTRIBUTES wfa;
   wfa.Recurse = recursive;
   wfa.ListMode = !showFolders;
   wfa.DirectoryFolder = directoryFolder;
   wfa.Excludes = join(excludesList, ';');
   for (i := 0; i < includeList._length(); ++i) {
      RelFilename := _RelativeToProject(basePath:+includeList[i], projectName);
      if (pos("**/", _NormalizeFile(RelFilename, true))) {
         wfa.Recurse = false;
      }
      AddFileToConfig(wid, RelFilename, currentConfig, null, -1, null, null, null, -1, wfa, projectHandle);
      wfa.Recurse = recursive;
   }
}

static void addTreeToProject(_str basePath,_str (&includeList)[], _str (&excludeList)[], bool recursive, bool followSymlinks, bool customFolders)
{
   _str ConfigName=getCurrentConfig();

   // Find all files in tree:
   mou_hour_glass(true);
   message('SlickEdit is finding all files in tree');

   recursiveString := recursive ? '+t' : '-t';
   optimizeString := followSymlinks ? '' : '+o';
   int list_wid=_srcfile_list;

   formwid := p_active_form;
   filelist_view_id := 0;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   _str orig_cwd=getcwd();
   _str ProjectName=gProjectName;
   all_files := _maybe_quote_filename(basePath);
   for (i := 0; i < includeList._length(); ++i) {
      strappend(all_files,' -wc '_maybe_quote_filename(includeList[i]));
   }

   for (i = 0; i < excludeList._length(); ++i) {
      strappend(all_files,' -exclude '_maybe_quote_filename(excludeList[i]));
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   status:=insert_file_list(recursiveString' 'optimizeString' +W +L -v +p -d 'all_files);
   if (status==CMRC_OPERATION_CANCELLED) {
      p_window_id=orig_view_id;
      _delete_temp_view(filelist_view_id);
      mou_hour_glass(false);
      clear_message();
      _message_box(get_message(CMRC_OPERATION_CANCELLED));
      return;
   }

   _str root = _NormalizeFile(relative(basePath,_strip_filename(ProjectName,'N')));
   list_wid._lbbegin_update();
   _VPJAddTree(ProjectName, root, gProjectHandle, p_window_id, list_wid, -1, (int)customFolders, null);
   list_wid._lbend_update(list_wid.p_Noflines);

   /*
   p_line=0;
   int FileToNode:[];
   FilesNode := 0;
   AutoFolders := "";
   int ExtToNodeHashTab:[];
   LastExt := "";
   LastNode := 0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   // Insert tree file list into project source file list:
   top();up();
   list_wid._lbbegin_update();

   while (!down()) {
      get_line(auto filename);
      filename=strip(filename);
      if (filename=='') break;
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      //4:15pm 7/11/2000
      //Changing for multiple configs...
      //fid._srcfile_list._lbadd_item(filename);
      //_srcfile_list._lbadd_item(relative(filename,strip_filename(gProjectName,'N')));
      relFilename := relative(filename,_strip_filename(ProjectName,'N'));
      AddFileToConfig(list_wid,relFilename,ConfigName,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   list_wid._lbend_update(list_wid.p_Noflines);
   */
   //Now sort the buffer...
   p_window_id=orig_view_id;
   _delete_temp_view(filelist_view_id);

}

static void RemoveFileFromViews(_str RelativeFilename,_str ConfigName,int (&FileToNode):[])
{
   RelativeFilenameCased := _file_case(RelativeFilename);
   int *pnode=FileToNode._indexin(RelativeFilenameCased);
   if (!pnode) {
      return;
   }
   int Node=*pnode;
   gFileListModified=true;
   //Simple case, we are in the "ALL CONFIGS" config, and we just remove the file
   if (ConfigName==PROJ_ALL_CONFIGS) {
      _xmlcfg_delete(gProjectHandle,Node);
      FileToNode._deleteel(RelativeFilenameCased);
      return;
   }
   _str configs=_xmlcfg_get_attribute(gProjectHandle,Node,'C');
   // IF this file was in all configs
   if (configs=='') {
      foreach (auto config in gConfigList) {
         strappend(configs,' 'always_quote_filename(config));
      }
      configs=strip(configs);
   }
   int i=pos(always_quote_filename(ConfigName),configs);
   if (i) {
      before := "";
      after := "";
      parse configs with before (always_quote_filename(ConfigName)) after;
      configs=strip(before' 'after);
   }
   if (configs=='') {
      _xmlcfg_delete(gProjectHandle,Node);
      FileToNode._deleteel(RelativeFilenameCased);
   } else {
      _xmlcfg_set_attribute(gProjectHandle,Node,'C',configs);
   }
}

// Desc:  Add the selected entries in the _srcfile_list to the
//        _openfile_list if they are supposed to be in the
//        current directory.
static void RemoveFiles()
{
   // Remember the current line in the _openfile_list so that
   // we can restore it after the update:
   // Indicate that the _srcfile_list is modified:
   //PROJECT_FILE_LIST_MODIFIED=1;

   // Build the path to the current directory:

   // Loop thru all the selected entries in the _srcfile_list:
   // Entries that are added back to the _openfile_list are removed
   // from _srcfile_list.
   addFile := false;
   findfirst := true;
   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(gProjectHandle,FileToNode);
   while (!_srcfile_list._lbfind_selected(findfirst)) {
      AbsoluteFilename := absolute(_srcfile_list._lbget_text(),_strip_filename(gProjectName,'N'));
      _str RelativeFilename=_srcfile_list._lbget_text();
      RemoveFileFromViews(RelativeFilename,getCurrentConfig(),FileToNode);
      _srcfile_list._lbdelete_item();
      _srcfile_list.up();
      findfirst=false;
   }
   if (_srcfile_list.p_line<=0) {
      _srcfile_list._lbtop();
   }

   // Update all the controls associated with the lists:
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');
}

// Desc:  Add the selected entries in the _srcfile_list to the
//        _openfile_list if they are supposed to be in the
//        current directory.
_remove.lbutton_up()
{
   gFileListModified=true;
   RemoveFiles();
}

_remove_all.lbutton_up()
{
   // Add all files back to openfile_list:
   gFileListModified=true;
   _srcfile_list._lbselect_all();
   _remove.call_event(_remove,LBUTTON_UP,'W');

   // Remove all files in srcfile_list:
   _srcfile_list._lbclear();
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');
}

// Desc: Go thru the project file list and remove all files that do not exist.
void ctlrefresh.lbutton_up()
{
   int modified;
   modified= 0;
   _str result;
   int removed;
   bool yesforall;
   noforall := false;
   removed= 0;
   result=_message_box('Remove deleted files from project without prompt?',"",MB_YESNOCANCEL,IDNO);
   if (result==IDCANCEL) {
      return;
   }
   yesforall= result==IDYES;
   mou_hour_glass(true);
   _srcfile_list._lbtop();
   _srcfile_list._lbup();
   Noflines := _srcfile_list.p_Noflines;
   project_path := _strip_filename(gProjectName,'N');
   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(gProjectHandle,FileToNode);
   while (!_srcfile_list._lbdown()) {
      _str line;
      line= _srcfile_list._lbget_text();

      linenum := _srcfile_list.p_line;
      //if (!(linenum % 5) || linenum==1) {
         message("Checking "linenum"/"Noflines': 'line);
      //}
      if (iswildcard(line) && !file_exists(absolute(line,project_path))) {
         continue;
      }
      // If file does not exits, remove the file from the project
      // file list.
      if (!file_exists(absolute(line,project_path))) {
         // If already selected "Yes for all", just remove the file
         // without asking. Otherwise, ask the user.
         clear_message();
         if (yesforall) {
            _srcfile_list._lbdelete_item();
            _srcfile_list._lbup();
            modified= 1;
            removed++;
            RemoveFileFromViews(line,getCurrentConfig(),FileToNode);
         } else if (!noforall) {
            _str msg;
            _str answer;
            msg= line :+ "\nno longer exists.\n\nRemove file from project?";
            answer= show("-modal _yesToAll_form", msg, "Remove File From Project");
            if (answer== "CANCEL") {
               break;
            } else if (answer== "YES") {
               _srcfile_list._lbdelete_item();
               _srcfile_list._lbup();
               modified= 1;
               removed++;
               RemoveFileFromViews(line,getCurrentConfig(),FileToNode);
            } else if (answer== "YESTOALL") {
               _srcfile_list._lbdelete_item();
               _srcfile_list._lbup();
               modified= 1;
               removed++;
               RemoveFileFromViews(line,getCurrentConfig(),FileToNode);
               yesforall= true;
            } else if (answer== "NOTOALL") {
               noforall= true;
            }
         }
      }
   }
   clear_message();
   if (removed) {
      _str fileMsg;
      fileMsg= "file";
      if (removed > 1) fileMsg= "files";
      _message_box("Project file list refreshed.\n\nRemoved "removed" "fileMsg".");
   }
   mou_hour_glass(false);
   if (modified) {
      gFileListModified=true;
   }
}

_invert.lbutton_up()
{
   _srcfile_list._lbinvert();
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');
}

static int okFiles(bool &doUpdateProjectToolbar)
{
   doUpdateProjectToolbar=false;
   wid := p_active_form;

   // Update project:
   status := 0;
   if (gFileListModified || !file_exists(_GetWorkspaceTagsFilename())) {
      doUpdateProjectToolbar=true;  // Could have modified wildcard properties
      status=save_source_filenames(wid);
      clear_message();
      if (status) {
         _message_box(nls("Error writing filenames"));
         return(status);
      }
   }
   return( status );
}
// Desc:  Check to see if the text field has been modified.
// Retn:  1 for modified, 0 for not.
//        2 for not in original hash
static int isTextFieldModified(_str ctlName,typeless &ht)
{
   _str value;
   int cid;
   cid= _find_control(ctlName);
   value= "";
   if (cid) value= cid.p_text;
   if (!ht._indexin(ctlName)) return(2);
   if (ht._indexin(ctlName) && value != ht:[ctlName]) return(1);
   return(0);
}

// Desc:  Check to see if the specified project tool in the new project
//        tool table has been modified.
// Retn:  1 for table modified, 0 for not.
//        2 for tool not in original tool table
static int isProjectToolModified(ProjectToolStruct projectToolList[],
                                 ProjectToolStruct oldprojectToolList[],
                                 int toolIndex /* tool index in new table */)
{
   // If the tool is not in the old tool table...
   int otoolIndex;
   _str name;
   name= projectToolList[toolIndex].name;
   if (!_isToolNameInProjectToolTable(oldprojectToolList,name,otoolIndex)) {
      return(2);
   }
   if (otoolIndex!=toolIndex) {
      return(1);
   }

   // Check individual fields...
   ProjectToolStruct i1, i2;
   i1= projectToolList[toolIndex];
   i2= oldprojectToolList[otoolIndex];
   if (i1.name != i2.name) {
      //messageNwait("isProjectToolModified name");
      return(1);
   }
   if (i1.nameKey != i2.nameKey) {
      //messageNwait("isProjectToolModified nameKey");
      return(1);
   }
   if (i1.cmd != i2.cmd) {
      //messageNwait("isProjectToolModified cmd");
      return(1);
   }
   if (i1.caption != i2.caption) {
      //messageNwait("isProjectToolModified caption");
      return(1);
   }
   if (i1.outputConcur != i2.outputConcur) {
      //messageNwait("isProjectToolModified outputConcur");
      return(1);
   }
   if (i1.captureOutput != i2.captureOutput) {
      //messageNwait("isProjectToolModified captureOutput");
      return(1);
   }
   if (i1.hideOptions != i2.hideOptions) {
      //messageNwait("isProjectToolModified hideOptions");
      return(1);
   }
   if (i1.clearProcessBuf != i2.clearProcessBuf) {
      //messageNwait("isProjectToolModified clearProcessBuf");
      return(1);
   }
   if (i1.saveOptions != i2.saveOptions) {
      //messageNwait("isProjectToolModified saveOptions");
      return(1);
   }
   if (i1.changeDir != i2.changeDir) {
      //messageNwait("isProjectToolModified changeDir");
      return(1);
   }
   if (i1.useVsBuild != i2.useVsBuild) {
      //messageNwait("isProjectToolModified useVsBuild");
      return(1);
   }
   if (i1.buildFirst != i2.buildFirst) {
      //messageNwait("isProjectToolModified useVsBuild");
      return(1);
   }
   if (i1.apptoolHashtab != i2.apptoolHashtab) {
      return(1);
   }
   if (i1.appletClass != i2.appletClass) {
      return(1);
   }
   if (_isUnix()) {
      if (i1.runInXterm != i2.runInXterm) {
         return(1);
      }
   }
   if (i1.outputExtension != i2.outputExtension) {
      return(1);
   }
   if (i1.noLinkObject != i2.noLinkObject) {
      return(1);
   }
   if (i1.verbose != i2.verbose) {
      return(1);
   }
   if (i1.beep != i2.beep) {
      return(1);
   }
   if (i1.preMacro != i2.preMacro) {
      return(1);
   }
   //if (i1.postMacro != i2.postMacro) {
   //   return(1);
   //}
   if (i1.otherOptions != i2.otherOptions) {
      return(1);
   }

   //messageNwait("isProjectToolModified NO MODIFICATION");
   return(0);
}

// Desc:  Check to see if the project tool table has been modified.
// Retn:  1 for table modified, 0 for not.
static int isProjectToolListModified(ProjectToolStruct projectToolList[],ProjectToolStruct oldprojectToolList[])
{
   // If the table are of different lengths, they are different:
   if (projectToolList._length() != oldprojectToolList._length()) {
      return(1);
   }

   // Check to see if the tool table has been changed:
   int i;
   for (i=0; i<projectToolList._length(); i++) {
      if (isProjectToolModified(projectToolList,oldprojectToolList, i)) {
         return(1);
      }
   }
   return(0);
}

_str _relative_workingdir(_str path,_str project_name=_project_name)
{
   if (project_name=='' || substr(project_name,1,1)=='.') {
      return(path);
   }
   if (path=='' || pos('%',path)) {
      return(path);
   }
   // strip space and quotes
   path = strip(path);
   path = strip(path, 'B', '"');

   // translate any FILESEP2 that are part of the path into FILESEP to
   // make sure the path is proper (this happens when a project
   // created on VSWINDOWS is modified on UNIX or vice versa)
   path = translate(path, FILESEP, FILESEP2);
   _maybe_append_filesep(path);
   toDir := _strip_filename(project_name,'n');
   // Just incase path is already relative, convert it to absolute
   path=absolute(path,toDir);
   path=relative(path,toDir);
   if (path=='') {
      return('.');
   }
   return(path);
}
_str _relative_includedirs(_str includedirs,_str project_name=_project_name,
                           int* recursionStatus = null, _str (*recursionMonitorHash):[] = null)
{
   includedirs=_parse_project_command(includedirs, '', project_name,'','','','',recursionStatus,recursionMonitorHash);
   if (project_name=='' || substr(project_name,1,1)=='.') {
      return(includedirs);
   }
   resultdirs := "";
   for (;;) {
      if (includedirs=='') {
         break;
      }
      path := "";
      parse includedirs with path (PARSE_PATHSEP_RE),'r' includedirs;
      if (path=='') continue;
      // Parse this like vsbuild, user must add '.' or "./" to includes
      //if (path=='') path='.';
      path=_relative_workingdir(path,project_name);
      if (resultdirs=='') {
         resultdirs=path;
      } else {
         resultdirs :+= PATHSEP:+path;
      }
   }
   return(resultdirs);
}
/**
 * Make each include directory in the list an absolute path
 *
 * @param includedirs
 *               List of include dirs
 * @param project_name
 * @param recursionStatus
 *               Do not use this parameter directly.  This is used only when
 *               called from _parse_project_command to prevent infinite
 *               recursion while parsing the includes
 * @param recursionMonitorHash
 *               Do not use this parameter directly.  This is used only when
 *               called from _parse_project_command to prevent infinite
 *               recursion while parsing the includes
 *
 * @return List of absolute includes
 */
_str _absolute_includedirs(_str includedirs,_str project_name=_project_name,
                           int* recursionStatus = null, _str (*recursionMonitorHash):[] = null)
{
   includedirs=_parse_project_command(includedirs, '', project_name,'','','','',recursionStatus,recursionMonitorHash);
   if (project_name=='' || substr(project_name,1,1)=='.') {
      return(includedirs);
   }
   resultdirs := "";
   toDir := _strip_filename(project_name,'N');
   for (;;) {
      if (includedirs=='') {
         break;
      }
      path := "";
      parse includedirs with path (PARSE_PATHSEP_RE),'r' includedirs;
      path=strip(path);
      // Parse this like vsbuild, user must add '.' or "./" to includes
      //if (path=='') path='.';
      if (path=='') continue;

      /*if (pos('%',path)) {
         path=_parse_project_command(path, '', project_name,'','','','',recursionStatus,recursionMonitorHash);
         if (path=='') continue;
      } else {
         if (last_char(path)!=FILESEP) {
            path :+= FILESEP;
         }
         path=absolute(path,toDir);
      }*/
      _maybe_append_filesep(path);
      path=absolute(path,toDir);
      if (resultdirs=='') {
         resultdirs=path;
      } else {
         resultdirs :+= PATHSEP:+path;
      }
   }
   return(resultdirs);
}

/**
 * Update the build and rebuild commands for the selected build system
 *
 * @return
 */
static void switchBuildSystem(_str configName,_str BuildSystem,_str BuildMakefile,_str BuildOptions)
{
   packType := "";
   packType= _ProjectGet_Type(gProjectHandle,configName);
   isJavaProject := strieq(packType, "java");
   isGNUCProject := strieq(packType, "gnuc");
   isVCPPProject := strieq(packType, "vcpp");

   // things should be setup in the following way for each build system
   //
   //    vsbuild
   //       if packname contains 'java'
   //          dialogs  -> javaopts
   //          build    -> javamake
   //          rebuild  -> javarebuild
   //
   //       if packtype equals 'gnuc'
   //          dialogs  -> gnucopts
   //          build    -> cppmake
   //          rebuild  -> cpprebuild
   //
   //       if packtype equals 'vcpp'
   //          dialogs  -> vcppopts
   //          build    -> ???
   //          rebuild  -> ???
   //
   //       default
   //          dialogs  -> none
   //          build    -> "%(VSLICKBIN1)vsbuild" make "%w" "%r"
   //          rebuild  -> "%(VSLICKBIN1)vsbuild" rebuild "%w" "%r"
   //
   //    automakefile
   //          dialogs  -> none
   //          build    -> (g)make -f "makefilename" CFG=%b
   //          rebuild  -> (g)make -f "makefilename" rebuild CFG=%b
   //
   //    custom
   //          dialogs  -> none
   //          build    -> none (user should fill these in)
   //          rebuild  -> none (user should fill these in)
   //
   int BuildNode=_ProjectGet_TargetNode(gProjectHandle,'build',configName);
   int RebuildNode=_ProjectGet_TargetNode(gProjectHandle,'rebuild',configName);
   switch(BuildSystem) {
      case "vsbuild":
         if(isJavaProject) {
            // build
            _ProjectSet_TargetDialog(gProjectHandle,BuildNode,JAVA_OPTS_DLG_DEF);
            //_ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,"javamake",'');

            _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,JAVA_OPTS_DLG_DEF);
            //_ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,"javarebuild",'');

         } else if(isGNUCProject) {
            _ProjectSet_TargetDialog(gProjectHandle,BuildNode,GNUC_OPTS_DLG_DEF);
            //_ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,"cppmake",'');

            _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,GNUC_OPTS_DLG_DEF);
            //_ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,"cpprebuild",'');
         } else if (isVCPPProject) {
            _ProjectSet_TargetDialog(gProjectHandle,BuildNode,VCPP_OPTS_DLG_DEF);

            _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,VCPP_OPTS_DLG_DEF);
         } else {
            // build
            _ProjectSet_TargetDialog(gProjectHandle,BuildNode,'');

            // rebuild
            _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,'');
         }
         _maybe_prepend(BuildOptions, ' ');
         _ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,"\"%(VSLICKBIN1)vsbuild\" build \"%w\" \"%r\"":+BuildOptions,'','');
         _ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,"\"%(VSLICKBIN1)vsbuild\" rebuild \"%w\" \"%r\"":+BuildOptions,'','');
         break;

      case "automakefile":
         // look for 'gmake' first.  default to 'make' if not found
         makeProgram := _findGNUMake();

         // set the makefile name if it wasnt provided
         if(BuildMakefile == "") {
            BuildMakefile = "%rp%rn.mak";
         }

         // build
         _maybe_prepend(BuildOptions, ' ');
         _ProjectSet_TargetDialog(gProjectHandle,BuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,makeProgram:+BuildOptions:+" -f \"" BuildMakefile "\" CFG=%b",'','');

         // rebuild
         _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,makeProgram:+BuildOptions:+" -f \"" BuildMakefile "\" rebuild CFG=%b",'','');

         break;

      default:
         // build
         _ProjectSet_TargetDialog(gProjectHandle,BuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,'','','');

         // rebuild
         _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,'','','');

         break;
   }
}

static ProjectDirStruct GetBlankDirInfo()
{
   ProjectDirStruct rv;
   rv.UserIncludeDirs='';
   rv.SystemIncludeDirs='';
   rv.ReferencesFile='';
   //rv.WorkingDir='';
   return(rv);
}

static ProjectCmdStruct GetBlankCmdInfo()
{
   ProjectCmdStruct rv;
   rv.PreBuildCmds = '';
   rv.PostBuildCmds = '';
   rv.StopOnPreBuildErrors = '0';
   rv.StopOnPostBuildErrors = '0';
   return(rv);
}


static _str getNewLineChars(_str text)
{
   p := pos("\n",text);
   if (!p) return( "\n" );  // Can't find one so does not matter
   if (p < 2) return( "\n" );
   lc := substr(text,p-1,1);
   if (lc== "\r") return( "\r\n" );
   return( "\n" );
}
void _getMacroText(_str &text,int flags=EDC_OUTPUTINI)
{
   typeless p;
   if (flags & EDC_OUTPUTINI) {
      save_pos(p);
      top();
      text=get_text(p_buf_size);
      text=stranslate(text,'\\','\');
      text=stranslate(text,'\n',p_newline);
      restore_pos(p);
   } else {
      save_pos(p);
      top();up();
      text='';
      for (;;) {
         if (down()) {
            break;
         }
         get_line(auto line);
         if (text!='') {
            strappend(text,"\1");
         }
         strappend(text,line);
      }
      restore_pos(p);
   }
}
_ok.lbutton_up()
{
   mou_hour_glass(true);
   doOK();
   mou_hour_glass(false);
}

static void doOK()
{
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   _str SectionsList[]=null;
   int modified;

   fid := p_active_form;
   fid.p_enabled=false;
   macrosChanged := false;
   if (!gIsExtensionProject) {
      if (_haveBuild()) okMacro(macrosChanged);
      okDirectories();
      if (_haveRealTimeErrors()) {
         _control _ctl_profile_ovrs;
         pfSaveProfileSettings(gProjectHandle, _ctl_profile_ovrs);
      }

      // IMPORTANT: it is imperative that okBuildOptions() be called *before*
      //            okFiles().  the reason is an auto-generated makefile may
      //            be added/removed from the file list during okBuildOptions()
      //            and will need to be added/removed from the tag file
      if (_haveBuild()) okBuildOptions();

      if (_haveBuild() && !gIsProjectTemplate) {
         // make sure dependencies are valid
         if(okDependencies() < 0) {
            // do not close the form if an invalid dependency is detected
            fid.p_enabled=true;
            return;
         }
      }
   }
   newTagOption := _ProjectGet_TaggingOption(gProjectHandle);
   if ((newTagOption == VPJ_TAGGINGOPTION_PROJECT && gInitialTagFileOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS) ||
       (newTagOption == VPJ_TAGGINGOPTION_PROJECT_NOREFS && gInitialTagFileOption == VPJ_TAGGINGOPTION_PROJECT)) {
      // Force the tag file to rebuild to capture the new references setting.
      _project_update_files_retag(gProjectName, true, true, true, true, newTagOption == VPJ_TAGGINGOPTION_PROJECT, false, true);
   }

   status := 0;
   if (gIsExtensionProject || gIsProjectTemplate) {  // extension project or project pack
      modified=_xmlcfg_get_modify(gProjectHandle);
      if (gdoSaveIfNecessary && _xmlcfg_get_modify(gProjectHandle)) {
         if (gIsProjectTemplate) {
            status=_ProjectTemplatesSave(gProjectHandle);
         } else {
            if (gIsExtensionProject==1) {
               status=_fileProjectSaveCurrent(gProjectHandle);
            } else {
               status=_fileProjectSaveProfile(gProjectHandle);
            }
            //status=_ProjectSave(gProjectHandle,'',_ConfigPath():+VSCFGFILE_USER_EXTPROJECTS);
         }
         if (status && p_active_form.p_visible) {
            fid.p_enabled=true;
            return;
         }
      }
      if (gIsExtensionProject==1) {
         if (gSetActiveConfigTo!='') {
            _fileProjectSetActiveConfig(gSetActiveConfigTo);
         }
      }
      /*if (gIsExtensionProject) {
         readAndParseAllExtensionProjects();
      } */
      // IF this is an extension specific project
      //_project_refresh();
   } else {
      modified=_xmlcfg_get_modify(gProjectHandle);
      doUpdateProjectToolbar := false;
      if (!gProjectFilesNotNeeded) {
         status= fid.okFiles(doUpdateProjectToolbar);
         if (status) {
            fid.p_enabled=true;
            return;
         }
         if (_IsWorkspaceAssociated(_workspace_filename)) {
            int Node=_ProjectGet_FilesNode(gProjectHandle);

            _xmlcfg_delete_children_with_name(gProjectHandle,Node,VPJTAG_F);
         }
      }
      if (modified) {
         status=_ProjectSave(gProjectHandle);
         if (status && p_active_form.p_visible) {
            fid.p_enabled=true;
            return;
         }
         // IF we are modifying the active project
         _ProjectCache_Update(gProjectName);
         p_window_id._WorkspacePutProjectDate(gProjectName);

         if (doUpdateProjectToolbar) {
            toolbarUpdateFilterList(gProjectName);
         }

         // IF we are modifying the active project
         if (_file_eq(gProjectName,_project_name)) {
            // Update debug project callback name if it changed
            new_DebugCallbackName := _ProjectGet_DebugCallbackName(_ProjectHandle(gProjectName));
            if (new_DebugCallbackName=="dotnet") new_DebugCallbackName="";
            if (new_DebugCallbackName!=_project_DebugCallbackName) {
               _project_DebugCallbackName=new_DebugCallbackName;
            }
            _DebugUpdateMenu();
         }
         p_window_id.call_list("_prjupdatedirs_");

         // regenerate the makefile
         p_window_id._maybeGenerateMakefile(gProjectName);
         if (macrosChanged) {
            _project_run_macro2();
         }
      }
      if (gSetActiveConfigTo!='') {
         project_config_set_active(gSetActiveConfigTo,gProjectName);
      }
   }
   if (modified) {
      p_window_id.call_list("_prjupdate_");
      if (gUpdateTags) {
         _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
         _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
      }
   }
   //5:24pm 7/30/1999
   //The window id changes to the toolbar in here somewhere.
   fid.p_enabled=true;
   p_window_id=fid;
   int value= _proj_prop_sstab.p_ActiveTab;
   _append_retrieve( _proj_prop_sstab, value );
   fid._delete_window(modified);
#if 0
   if (CurConfig!='') {
      // This may display a rebuild dialog box for Java.
      project_config_set_active(CurConfig);
   }
#endif
}

void _proj_prop_sstab.on_change(int reason)
{
   static _str previousConfig;

   if (ctlCurConfig.p_enabled) {
      // save the current configuration
      previousConfig=getCurrentConfig();
   }

   if (previousConfig=='') {
      return;
   }

   typeless status=0;
   if (_proj_prop_sstab.p_ActiveTab == PROJECTPROPERTIES_TABINDEX_FILES) {
      if (_IsWorkspaceAssociated(_workspace_filename)) {
         if (reason==CHANGE_TABACTIVATED) {

            // force configuration to "All Configurations"
            ctlCurConfig._lbtop();
            if (ctlCurConfig._lbfind_and_select_item(PROJ_ALL_CONFIGS)) {
               ctlCurConfig._lbbottom();
               ctlCurConfig.p_text=ctlCurConfig._lbget_text();
            } 

            // disable the config dropdown
            ctlCurConfig.p_enabled=false;

         } else if (reason==CHANGE_TABDEACTIVATED) {
            // restore the configuration to whatever it was
            ctlCurConfig._lbtop();
            if (ctlCurConfig._lbfind_and_select_item(previousConfig)) {
               ctlCurConfig._lbbottom();
               ctlCurConfig.p_text=ctlCurConfig._lbget_text();
            } 

            // re-enable the config dropdown
            ctlCurConfig.p_enabled=true;
         }
      }
   } else if (_proj_prop_sstab.p_ActiveTab == PROJECTPROPERTIES_TABINDEX_TOOLS) {
      gChangingConfiguration=true;
      ctlToolTree.call_event(CHANGE_SELECTED, ctlToolTree._TreeCurIndex(), ctlToolTree, ON_CHANGE, 'W');
      ctlToolTree.refresh();
      gChangingConfiguration=false;
   } else if (_proj_prop_sstab.p_ActiveTab == PROJECTPROPERTIES_TABINDEX_RUNDEBUG) {
      gChangingConfiguration=true;
      orig_completion := ctlProgramName.p_completion;
      ctlProgramName.p_completion = "";
      resetRunDebugInfo();
      ctlProgramName.p_completion = orig_completion;
      gChangingConfiguration=false;
   }
   if (reason==CHANGE_TABACTIVATED && _proj_prop_sstab.p_ActiveTab == PROJECTPROPERTIES_TABINDEX_FILES && !(gIsExtensionProject || gIsProjectTemplate) && _addtree.p_enabled) {
      // It would be better to set the property on the Files tree control but
      // Qt seems to have a bug. Only way I could get this to work is to set this
      // property on the form.
      p_active_form.p_AllowDropFiles=true;
   } else {
      p_active_form.p_AllowDropFiles=false;
   }
}


_prjcompile_concur.lbutton_up()
{
   if (p_value) {
      p_next.p_value=1;
   }
}

_prjcompile_capture.lbutton_up()
{
   if (!p_value) {
      p_prev.p_value=0;
   }
}

void ctlUseGDB.lbutton_up()
{
   if (ignore_config_change) {
      return;
   }
   debugging_other := (ctlUseOther.p_value != 0);
   ctldbgDebugger.p_enabled=debugging_other;
   ctldbgDebuggerLabel.p_enabled=debugging_other;
   ctldbgOtherDebuggerOptions.p_enabled=debugging_other;
   ctldbgOtherDebuggerButton.p_enabled=debugging_other;
   ctldbgDebuggerOtherLabel.p_enabled=debugging_other;
   ctldbgFindApp.p_enabled=debugging_other;

   debug_callback := "";
   if (ctlUseGDB.p_value && ctlUseGDB.p_enabled) {
      debug_callback = "gdb";
   } else if (ctlUseLLDB.p_value && ctlUseLLDB.p_enabled) {
      debug_callback = "lldb";
   } else if (ctlUseWinDBG.p_value && ctlUseWinDBG.p_enabled) {
      debug_callback = "windbg";
   } else if (ctlUseJDWP.p_value && ctlUseJDWP.p_enabled) {
      debug_callback = "jdwp";
   } else if (ctlUseMono.p_value && ctlUseMono.p_enabled) {
      debug_callback = "mono";
   } else if (ctlUsePython.p_value && ctlUsePython.p_enabled) {
      debug_callback = "dap";
   } else if (ctlUsePerl.p_value && ctlUsePerl.p_enabled) {
      debug_callback = "perl5db";
   } else if (ctlUseRuby.p_value && ctlUseRuby.p_enabled) {
      debug_callback = "rdbgp";
   } else if (ctlUsePHP.p_value && ctlUsePHP.p_enabled) {
      debug_callback = "xdebug";
   }

   if (gChangingConfiguration==1) return;
   if (getCurrentConfig()==PROJ_ALL_CONFIGS) {
      foreach (auto config in gConfigList) {
         _ProjectSet_DebugCallbackName(gProjectHandle, debug_callback, config);
         gAllConfigsInfo.DebugCallbackName = debug_callback;
      }
   } else {
      config := GetConfigText();
      _ProjectSet_DebugCallbackName(gProjectHandle, debug_callback, config);
   }
}


static void FillInSrcFileList(_str ConfigName)
{
   if (gIsExtensionProject || gIsProjectTemplate) {
      return;
   }
   if (!gOrigProjectFileList) {
      GetProjectFiles(gProjectName, gOrigProjectFileList,'',null,'',true,true,false,gProjectHandle);
   }
   //_showbuf(gProjectInfo2:[ALL_CONFIGS].FilesViewId);
   _lbclear();
   _lbbegin_update();
   _xmlcfg_find_simple_insert(gProjectHandle,VPJX_FILES"//"VPJTAG_F:+'[not(@C)]/@N');
   _lbend_update(p_Noflines);
   //_showbuf(p_window_id);
   if (ConfigName!=PROJ_ALL_CONFIGS) {
      _xmlcfg_find_simple_insert(gProjectHandle,VPJX_FILES"//"VPJTAG_F:+XPATH_CONTAINS('C',always_quote_filename(ConfigName),'i')'/@N');
   }
   top();search(FILESEP2,'@',FILESEP);
   //top();search('^','@R',' ');

   _lbsort('-f');
   _lbtop();
   // Update all controls associated with the _srcfile_list
   updateControlsNofSelected();
}

int _MaybeAddFilesToVC(_str (&NewFiles)[])
{
   status := 0;
   result := 0;
   if ( !_haveVersionControl() ) return 0;
   if ( NewFiles._length() &&
        ( ( machine()=='WINDOWS' && _isscc(_GetVCSystemName()) && _SCCProjectIsOpen() ) ||
          _VCSCommandIsValid(VCS_CHECKIN_NEW) && (def_vcflags&VCF_PROMPT_TO_ADD_NEW_FILES) ) ) {
      result=_message_box(nls("Do you want to add the new files to version control?"),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDYES) {

         vcSystem := svc_get_vc_system(NewFiles[0]);
         if ( _VCIsSpecializedSystem(vcSystem) ) {
            se.vc.IVersionControl *pInterface = svcGetInterface(vcSystem);
            if ( pInterface==null ) {
               return(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC);
            }
            status = pInterface->addFiles(NewFiles);
            if (status) return(status);
            result = _message_box(nls("Files added, commit these files now?"),'',MB_YESNO);
            if ( result == IDYES ) {
               _str comment_filename=mktemp(),tag='',filelist='';
               int i,len=NewFiles._length();
               for (i=0;i<len;++i) {
                  filelist :+= ' 'NewFiles[i];
               }
               filelist=strip(filelist);
               status=_SVCListModified(NewFiles);
               if (status) return(status);
               OutputFilename := "";
               status = pInterface->commitFiles(NewFiles);
               _SVCDisplayErrorOutputFromFile(OutputFilename,status);
               delete_file(comment_filename);
            }
            return(status);
         }

         result=show('-modal _vc_comment_form',NewFiles[0],1,1);
         if (result=='') {
            return(COMMAND_CANCELLED_RC);
         }
         _str comment=_param1;
         prompt_for_each_comment := !_param2;
         if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
            if (prompt_for_each_comment) {
               int FileStatus[];
               FileStatus._makeempty();
               int i;
               for (i=0;i<NewFiles._length();++i) {
                  _str CurFiles[];
                  CurFiles[0]=NewFiles[i];
                  status=_SccAdd(CurFiles,comment);
                  if (i+1>=NewFiles._length()) {
                     break;
                  }
                  result=show('-modal _vc_comment_form',NewFiles[i+1],1,1);
                  if (result=='') {
                     return(COMMAND_CANCELLED_RC);
                  }
                  comment=_param1;
                  prompt_for_each_comment=!_param2;
                  if (!prompt_for_each_comment) break;
               }
               if (i<NewFiles._length()-1) {
                  //There are some left, but use same comment for all
                  _str CurFiles[];
                  int j;
                  for (j=i+1;j<NewFiles._length();++j) {
                     CurFiles[j-(i+1)]=NewFiles[j];
                  }
                  status=_SccAdd(CurFiles,comment);
               }
            } else {
               status=_SccAdd(NewFiles,comment);
            }
         } else {
            if (prompt_for_each_comment) {
               SkipNext := 0;
               int i;
               for (i=0;i<NewFiles._length();++i) {
                  if (!SkipNext) {
                     vcadd(NewFiles[i],comment);
                  }
                  SkipNext=0;
                  if (i+1>=NewFiles._length()) {
                     break;
                  }
                  result=show('-modal _vc_comment_form',NewFiles[i+1],1,1);
                  if (result=='') {
                     SkipNext=1;
                     continue;
                  }
                  comment=_param1;
                  prompt_for_each_comment=!_param2;
                  if (!prompt_for_each_comment) break;
               }
               int j;
               for (j=i+1;j<NewFiles._length();++j) {
                  vcadd(NewFiles[j],comment);
               }
            } else {
               int i;
               for (i=0;i<NewFiles._length();++i) {
                  vcadd(NewFiles[i],comment);
               }
            }
         }
      }
   }
   return(status);
}

int _AddAndRemoveFilesFromVC(_str (&NewFiles)[],_str (&DeletedFiles)[], _str ProjectName='')
{
   if ( !_haveVersionControl() ) return 0;
#if 0
   ProjectPath=strip_filename(ProjectName,'N');
   int i;
   count=NewFiles._length();
   for (i=0;i<count;++i) {
      NewFiles[i]=absolute(NewFiles[i],ProjectPath);
   }
   count=DeletedFiles._length();
   for (i=0;i<count;++i) {
      DeletedFiles[i]=absolute(DeletedFiles[i],ProjectPath);
   }
#endif
   // Update project file:
   typeless FileStatus=0;
   status := 0;
   result := 0;
   i := 0;
   if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
      status=_SccQueryInfo(NewFiles,FileStatus);
      if (!status) {
         for (i=0;i<FileStatus._length();++i) {
            if (FileStatus[i]) {
               //File is already in Version control...
               NewFiles._deleteel(i);
               FileStatus._deleteel(i);
               --i;
            }
         }
      }
   }
   _MaybeAddFilesToVC(NewFiles);
   if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
      status=_SccQueryInfo(DeletedFiles,FileStatus);
      if (!status) {
         for (i=0;i<FileStatus._length();++i) {
            if (!FileStatus[i]) {
               //File is not in Version control...
               DeletedFiles._deleteel(i);
               FileStatus._deleteel(i);
               --i;
            }
         }
      }
   }
   if ( DeletedFiles._length() &&
        ( (machine()=='WINDOWS' && _isscc() && _SCCProjectIsOpen() ) ||
          _VCSCommandIsValid(VCS_REMOVE)) && (def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES) ) {
      vcSystem := svc_get_vc_system(DeletedFiles[0]);
      _str msg=nls("Would you like to remove these files from version control?");
      if ( upcase(vcSystem)=='CVS' ) {
         msg=nls("Would you like to remove these files from version control?\n\nWARNING:This will also delete the local files");
      }
      result=_message_box(msg,'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDYES) {
         if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
            _SccRemove(DeletedFiles,'');
         } if ( _VCIsSpecializedSystem(vcSystem) ) {
            OutputFilename := "";
            se.vc.IVersionControl *pInterface = svcGetInterface(vcSystem);
            if ( pInterface==null ) {
               return(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC);
            }
            pInterface->removeFiles(DeletedFiles);
            if (status) return(status);
            result=_message_box(nls("Files removed, commit these files now?"),'',MB_YESNO);
            if (result==IDYES) {
               status = pInterface->commitFiles(DeletedFiles);
            }
            return(status);
         } else {
            for (i=0;i<DeletedFiles._length();++i) {
               vcremove(DeletedFiles[i],true);
            }
         }
      }
   }
   return(0);
}


#define PROJECT_DEBUG_TAGGING_MESSAGES 0

/**
 * Add the filter nodes to the tree specified based on the
 * xml file given.
 *
 * @param TreeWid
 * @param TreeParentIndex
 * @param ProjectHandle
 * @param Node
 * @param ExtToNodeHashTab
 * @param SetOtherFilesNode
 */
void _CreateProjectFilterTree(int TreeWid,int TreeParentIndex,int ProjectHandle,int Node,int (&ExtToNodeHashTab):[],bool SetOtherFilesNode=true)
{
   if (SetOtherFilesNode) {
      ExtToNodeHashTab._makeempty();
   }
   Node=_xmlcfg_get_first_child(ProjectHandle,Node);
   for (;Node>=0;Node=_xmlcfg_get_next_sibling(ProjectHandle,Node)) {
      if (_xmlcfg_get_name(ProjectHandle,Node)!=VPJTAG_FOLDER) {
         continue;
      }
      int index=TreeWid._TreeAddItem(TreeParentIndex,
                                     _xmlcfg_get_attribute(ProjectHandle,Node,'Name'),
                                     TREE_ADD_AS_CHILD,
                                     _pic_tfldclos,
                                     _pic_tfldopen,
                                     TREE_NODE_COLLAPSED,0);
      _str filters=_xmlcfg_get_attribute(ProjectHandle,Node,'Filters');
      if (filters=='') {
         ExtToNodeHashTab:['']=index;
         continue;
      }
      for (;;) {
         ext := "";
         parse filters with ext ';' filters;
         parse ext with "*." ext;
         if (ext=='' && filters=='') {
            break;
         }
         if (ext!='') {
            ExtToNodeHashTab:[lowcase(ext)]=index;
         }
      }
      _CreateProjectFilterTree(TreeWid,index,ProjectHandle,Node,ExtToNodeHashTab,false);
   }
   if (SetOtherFilesNode && !ExtToNodeHashTab._indexin('')) {
      ExtToNodeHashTab:['']=TreeParentIndex;
   }
}
void _ProjectGet_ExtToNode(int handle,int (&ExtToNodeHashTab):[],_str SkipFolderName='')
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   ExtToNodeHashTab._makeempty();
   int FilesNode=_ProjectGet_FilesNode(handle,true);
   OtherFilesNode := -1;
   _str PrjExt=_get_extension(_xmlcfg_get_filename(handle),true);
   bool CheckCustomFolders = _file_eq(_get_extension(PrjExt,true),PRJ_FILE_EXT);
   typeless array;
   _ProjectGet_Folders(handle,array);

   int i;
   for (i=0;i<array._length();++i) {
      if (strieq(SkipFolderName,_xmlcfg_get_attribute(handle,array[i],'Name'))) {
         continue;
      }
      _str filters=_xmlcfg_get_attribute(handle,array[i],xmlv.vpjattr_filters);
      if (filters=='') {
         if (OtherFilesNode < 0) {
            if (CheckCustomFolders) {
               if (_xmlcfg_get_attribute(handle,array[i],"AutoCustom") :== "1") {
                  continue;
               }
            }

            parent := _xmlcfg_get_parent(handle, array[i]);
            if (parent == FilesNode) {
               OtherFilesNode=array[i];
            }
         }
         continue;
      }
      for (;;) {
         ext := "";
         parse filters with ext ';' filters;
         if (substr(ext,1,2)=='*.') {
            parse ext with "*." ext;
         }
         if (ext=='' && filters=='') {
            break;
         }
         if (ext!='') {
            if (!ExtToNodeHashTab._indexin(lowcase(ext))) {
               ExtToNodeHashTab:[lowcase(ext)]=array[i];
            }
         }
      }
   }
   
   if (OtherFilesNode<0) {
      ExtToNodeHashTab:['']=FilesNode;
   } else {
      ExtToNodeHashTab:['']=OtherFilesNode;
   }
}
int _TagUpdateFromViews(_str TagFilename,
                        int NewFilesViewId,
                        int OrigFilesViewId,
                        bool InputIsAbsolute,
                        _str project_name=_project_name,
                        _str (&NewFilesList)[]=null,
                        _str (&DeletedFilesList)[]=null,
                        int database_flags=0,
                        bool useThread=false
                        )
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   tagFileModified := false;
   int dbstatus=tag_open_db(TagFilename);
   p_window_id=NewFilesViewId;
   num_files := p_Noflines;
   static _str last_lang;
   project_path := _strip_filename(project_name,'N');
   //_showbuf(NewFilesViewId);GetProjectFiles(project_name,CurProjectList_view_id,'','' /*Don't want associated project makefile */,"",true,false);_showbuf(CurProjectList_view_id);_delete_temp_view(CurProjectList_view_id);
   if (dbstatus) {
      int status= _OpenOrCreateTagFile(TagFilename,true,VS_DBTYPE_tags,database_flags);
#if 0
      if (!status) {
         activate_window(NewFilesViewId);
         top();up();
         for (;;) {
            if (down()) {
               break;
            }
            get_line(filename);
            filename=strip(filename);
            if (!InputIsAbsolute) {
               filename=absolute(filename,project_path);
            }
            lang := _Filename2LangId(filename);
            if (last_lang==lang || _istagging_supported(lang) || _QBinaryLoadTagsSupported(filename)) {
               last_lang=lang;
               message('Tagging 'p_line'/'num_files': 'filename);
               #if PROJECT_DEBUG_TAGGING_MESSAGES
               DebugTaggingMessage('Tagging 'p_line'/'num_files': 'filename);
               #endif
               RetagFile(filename);
            }
         }
      }
#endif
   }

   {
      //GetProjectFiles(project_name,CurProjectList_view_id,'','' /*Don't want associated project makefile */,"",true,false);

      activate_window(NewFilesViewId);top();up();
      NofLines1 := p_Noflines;
      activate_window(OrigFilesViewId);top();up();
      NofLines2 := p_Noflines;

      if (NofLines1+NofLines2+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE) ) {
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,NofLines1+NofLines2+10);
      }
      NewFilesList._makeempty();
      DeletedFilesList._makeempty();
      //_showbuf(OrigFilesViewId);
      top();up();
      done1 := false;
      done2 := false;
      activate_window(NewFilesViewId);
      line1 := "";
      if (down()) {
         done1=true;
         line1='';
      } else {
         get_line(line1);
         line1=strip(line1);
      }
      activate_window(OrigFilesViewId);
      line2 := "";
      if (down()) {
         done2=true;
         line2='';
      } else {
         get_line(line2);
      }
      line2=strip(line2);
      buildform_wid := 0;
      allowCancel := false;
      if (allowCancel) {
         buildform_wid=_mdi.show_cancel_form(_GetBuildingTagFileMessage(useThread,TagFilename),null,true,true);
      } else {
         buildform_wid=_mdi.show_cancel_form(_GetBuildingTagFileMessage(useThread,TagFilename),'',false,true);
      }
      int max_label2_width=cancel_form_max_label2_width(buildform_wid);
      for (;;) {
         if (cancel_form_cancelled()) {
            break;
         }
         if (done1 && done2) {
            break;
         }
         if (!done1 && !done2 && _file_eq(line1,line2)) {
            activate_window(NewFilesViewId);
            if (down()) {
               done1=true;
               line1='';
            } else {
               get_line(line1);
            }
            line1=strip(line1);
            activate_window(OrigFilesViewId);
            if (down()) {
               done2=true;
               line2='';
            } else {
               get_line(line2);
            }
            line2=strip(line2);
            continue;
         }
         // If we are add a file to the project
         if (!done1 && (done2 || _file_case(line1)<_file_case(line2))) {
            for (;;) {
               if (cancel_form_cancelled()) {
                  break;
               }
               // call tag progress callback
               int cancelPressed = tagProgressCallback(p_line * 100 intdiv num_files, true);
               if(cancelPressed) break;

               activate_window(NewFilesViewId);
               if ( line1 != "" ) {
                  NewFilesList :+= line1;
                  filename := "";
                  if (!InputIsAbsolute) {
                     filename=absolute(line1,project_path);
                  }else{
                     filename=line1;
                  }
                  //say('***add 'absolute(line1,project_path));
                  lang := _Filename2LangId(filename);
                  if (last_lang==lang || _istagging_supported(lang) || _QBinaryLoadTagsSupported(filename)) {

                     if (cancel_form_progress(buildform_wid,p_line-1,num_files)) {
                        _str sfilename=buildform_wid._ShrinkFilename(filename,max_label2_width);
                        cancel_form_set_labels(buildform_wid,'Tagging 'p_line'/'num_files':',sfilename);
                     }
                     //message('Tagging 'p_line'/'num_files': 'filename);
                     #if PROJECT_DEBUG_TAGGING_MESSAGES
                     say('Tagging 'p_line'/'num_files': 'filename);
                     #endif
                     RetagFile(filename,useThread,0,lang,TagFilename);
                  }
                  activate_window(NewFilesViewId);
               }
               if (down()) {
                  done1=true;
                  line1='';
                  break;
               } else {
                  get_line(line1);
               }
               line1=strip(line1);
               if (!done2 && _file_case(line1)>=_file_case(line2)) {
                  break;
               }
            }
            continue;
         }
         // We are deleting files from the project
         for (;;) {
            if (cancel_form_cancelled()) {
               break;
            }
            //say('***remove 'absolute(line2,project_path));
            if ( line2 != "" ) {
               DeletedFilesList :+= line2;
               filename := "";
               if (!InputIsAbsolute) {
                  filename=absolute(line2,project_path);
               }else{
                  filename=line2;
               }
               lang := _Filename2LangId(filename);
               if (last_lang==lang || _istagging_supported(lang) || _QBinaryLoadTagsSupported(filename)) {
                  _str sfilename=buildform_wid._ShrinkFilename(filename,max_label2_width);
                  cancel_form_set_labels(buildform_wid,'Removing:',sfilename);
                  //message('Removing 'filename' from 'TagFilename);
                  #if PROJECT_DEBUG_TAGGING_MESSAGES
                  say('Removing 'filename' from 'TagFilename);
                  #endif
                  tag_remove_from_file(filename);
               }
            }
            activate_window(OrigFilesViewId);
            if (down()) {
               done2=true;
               line2='';
               break;
            } else {
               get_line(line2);
            }
            line2=strip(line2);
            if (!done1 && _file_case(line1)<=_file_case(line2)) {
               break;
            }
         }
      }
      if (buildform_wid) {
         close_cancel_form(buildform_wid);
      }
      tag_close_db(TagFilename,true);

      //_showbuf(addfiles_view_id);_delete_temp_view(addfiles_view_id);
   }
   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   clear_message();
   return(0);
}

void _DiffFileListsFromViews(int newFileListViewId, 
                             int origFileListViewId,
                             _str (&newFilesList)[], 
                             _str (&deletedFilesList)[])
{
   int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
   _str fileName, fileNameKey;
   _str fileHashTable:[];

   newFileListViewId.save_pos(auto p);
   newFileListViewId.top();
   newFileListViewId._begin_line();
   loop {
      newFileListViewId.get_line(fileName);
      if ( fileName != "" ) {
         fileNameKey = _file_case(strip(fileName));
         fileHashTable:[fileNameKey] = fileName;
      }
      if (newFileListViewId.down()) break;
   }
   newFileListViewId.restore_pos(p);


   origFileListViewId.save_pos(p);
   origFileListViewId.top();
   origFileListViewId._begin_line();
   loop {
      origFileListViewId.get_line(fileName);
      if ( fileName != "" ) {
         fileNameKey = _file_case(strip(fileName));

         if (fileHashTable._indexin(fileNameKey)) {
            // if the file is in both views, then it is rather boring.
            fileHashTable._deleteel(fileNameKey);
         } else {
            // if a file was there before and isn't anymore, it is a deleted file.
            deletedFilesList :+= fileName;
         }
      }

      if (origFileListViewId.down()) break;
   }
   origFileListViewId.restore_pos(p);

   // the files remaining in the hash table are the new files
   foreach (fileName in fileHashTable) {
      newFilesList :+= fileName;
   }
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);
}

static int save_source_filenames(int form_wid)
{
   if (gIsExtensionProject || gIsProjectTemplate) return( 0 );
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      return(0);
   }
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      line := "";
      _xmlcfg_find_simple_insert(gProjectHandle,VPJX_FILES"//"VPJTAG_F'/@N');
      top();up();
      while (!down()) {
         get_line(line);
         replace_line(stranslate(line,'%','%%'));
      }
      top();search(FILESEP2,'@',FILESEP);
      cancel_form_set_parent(form_wid);
      int status=SaveAssociatedProjectFiles(temp_view_id,gProjectName);
      cancel_form_set_parent(0);
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
      return(status);
   }

   orig_view_id := p_window_id;

   cancel_form_set_parent(form_wid);
   _project_after_modify_files(gProjectName,gProjectHandle,gOrigProjectFileList,true);

   /*
      Need to do this after tagging so we can query the package names from the
      tag data base.
   */
   _str AutoFolders=_ProjectGet_AutoFolders(gProjectHandle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      int ExtToNodeHashTab:[];
      _ProjectGet_ExtToNode(gProjectHandle,ExtToNodeHashTab);

      _ProjectSortFolderNodesInHashTable(gProjectHandle,ExtToNodeHashTab);
   } else {
      _ProjectAutoFolders(gProjectHandle);
   }

   _ProjectUpdate_AutoTreeFolders(gProjectHandle);

   cancel_form_set_parent(0);
   p_window_id=form_wid;
   return(0);
}


// Desc:  Check to specified tool command for modifications.
// Retn:  1 for modified, 0 for nothing modified.
static int isProjectShellCommandModified(_str ctlName, typeless & ht)
{
   int wid;
   /*
   wid= sstIsControlExists(ctlName);
   if (!wid) {
      _str widptext;
      int concur, capture;
      widptext= _proj_prop_sstab.sstGetProp2(ctlName,"p_text");

      if (!ht._indexin(ctlName)) {
         old_text='';
      } else {
         old_text=ht:[ctlName];
      }
      if (widptext != old_text) return(1);
      concur= _proj_prop_sstab.sstGetProp2(ctlName:+"_concur","p_value");
      if (ht._indexin(ctlName:+"_concur") && concur != ht:[ctlName:+"_concur"]) return(1);
      capture= _proj_prop_sstab.sstGetProp2(ctlName:+"_capture","p_value");
      if (ht._indexin(ctlName:+"_capture") && capture != ht:[ctlName:+"_capture"]) return(1);
      return(0);
   }
   */
   wid= _find_control(ctlName);
   if (!wid) {
      return(0);
   }

   int concurwid, capturewid;
   concurwid= wid.p_next.p_next;
   capturewid= concurwid.p_next;
   old_text := "";
   if (!ht._indexin(ctlName)) {
      old_text='';
   } else {
      old_text=ht:[ctlName];
   }
   if (wid.p_text != old_text) return(1);
   if (ht._indexin(ctlName:+"_concur") && concurwid.p_value != ht:[ctlName:+"_concur"]) return(1);
   if (ht._indexin(ctlName:+"_capture") && capturewid.p_value != ht:[ctlName:+"_capture"]) return(1);
   return(0);
}

_browsedir.lbutton_up()
{
   wid := p_window_id;
   // TODO: save and restore def_cd variable here
   prev_text := "";
   if (p_prev.p_object == OI_TEXT_BOX) {
      prev_text = p_prev.p_text;
      prev_text = _parse_project_command(prev_text,"",_project_name,"");
      prev_text = absolute(prev_text, _strip_filename(_project_name,'N'));
   }
   _str result = _ChooseDirDialog("",prev_text,"",CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR);
   if ( result=='' ) {
      return('');
   }
   p_window_id=wid.p_prev;
   if (p_object==OI_TREE_VIEW) {
      _TreeBottom();
      lastIndex := _TreeCurIndex(); // get the index of the <double click... line
      _TreeAddItem(lastIndex,result,TREE_ADD_BEFORE,0,0,TREE_NODE_LEAF);
      _TreeUp(); // select the newly added item
   } else if( p_object==OI_LIST_BOX ) {
      _lbbottom();
      _lbadd_item(result);
      _lbselect_line();
   } else {
      p_text=result;
      end_line();
   }
   _set_focus();
   return('');
}
_browsedirconcat.lbutton_up()
{
   wid := p_window_id;
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return('');
   }
   p_window_id=wid.p_prev;
   if (p_text=="") {
      p_text= result;
   } else {
      p_text :+= PATHSEP :+ result;
   }
   end_line();
   _set_focus();
   return('');
}
_browsefileconcat.lbutton_up()
{
   wid := p_window_id;
   typeless result=_OpenDialog('-modal',
                               'Choose File',        // Dialog Box Title
                               '',                   // Initial Wild Cards
                               "Tag Files (*.slk;*.vtg)", // File Type List
                               OFN_FILEMUSTEXIST|OFN_NOCHANGEDIR     // Flags
                              );
   if (result=='') {
      return('');
   }
   p_window_id=wid.p_prev;
   if (p_text=="") {
      p_text= result;
   } else {
      p_text :+= PATHSEP :+ result;
   }
   end_line();
   _set_focus();
   return('');
}
_browserefs.lbutton_up()
{
   wid := p_window_id;
   typeless result=_OpenDialog('-modal',
                               'Choose File',        // Dialog Box Title
                               '',                   // Initial Wild Cards
                               "References Files (*.bsc)", // File Type List
                               OFN_FILEMUSTEXIST|OFN_NOCHANGEDIR     // Flags
                              );
   result=strip(result,'B','"');
   if (result=='') {
      return('');
   }
   p_window_id=wid.p_prev;
   p_text= result;
   end_line();
   _set_focus();
   return('');
}

static int _myisdirectory(_str path)
{
   if (isdirectory(path) && path!='') {
      return(0);
   }
   _message_box(nls("'%s' is not a valid path",path));
   return(1);
}

static int find_caption(int menu_index,_str menu_text)
{
   int child=menu_index.p_child;
   if (child) {
      int firstchild=child;
      for (;;) {
         item_text := stranslate(child.p_caption,'','&');
         if (strieq(item_text,menu_text)) {
            return(child);
         }
         child=child.p_next;
         if (child==firstchild) {
            break;
         }
      }
   }
   return(0);
}

int _OnUpdate_projecttbSetCurProject(CMDUI &cmdui,int target_wid,_str command)
{
   if (p_name!='_proj_tooltab_tree') {
      return(MF_GRAYED);
   }
   // just determine if the current node is a project node 
   if (_projecttbIsProjectNode() == true) {
      return(MF_ENABLED);
   } else {
      return(MF_GRAYED);
   }
}

static int isPatternAllFilesRE(_str pattern)
{
   if (_isUnix()) {
      return(pos(';'ALLFILES_RE';',';'pattern';',1,_fpos_case));
      /*return(pos(';*.*;',';'pattern';',1,_fpos_case) ||
             pos(';*;',';'pattern';',1,_fpos_case));*/
   }
   return(pos(';'ALLFILES_RE';',';'pattern';',1,_fpos_case));
}
// Desc:  Check to see if the specified file has one of the extensions
//     listed in semicolon-separated pattern.
static int isFileMatchedExtension(_str name, _str pattern)
{
   _str ext= _get_extension(name);
   if (ext=='') {
      return(isPatternAllFilesRE(pattern));
   }
   int status=pos(';*.'ext';',';'pattern';',1,_fpos_case);
   if (status) {
      return(status);
   }
   return(isPatternAllFilesRE(pattern));
}

static bool IsReadOnly(_str filename)
{
   if (_isUnix()) {
      _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      if (attrs=='') return(false);
      w := pos('w',attrs,'','i');
      return(w != 0);
   }
   _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   if (attrs=='') return(false);
   ro := pos('r',attrs,1,'i');
   return(ro != 0);
}

/*
int _pic_vc_co_user_r;           // File under version control checked out by user, read-only
int _pic_vc_co_other_m_r;        // File under version control checked out by other user multiple, read-only
int _pic_vc_co_other_x_r;        // File under version control checked out by other user exclusive, read-only
int _pic_vc_available_r;         // File under version control not checked read-only
int _pic_doc_r;                  // File NOT under version control read-only

int _pic_vc_co_user_w;           // File under version control checked out by user, writable
int _pic_vc_co_other_m_w;        // File under version control checked out by other user multiple, writable
int _pic_vc_co_other_x_w;        // File under version control checked out by other user exclusive, writable
int _pic_vc_available_w;         // File under version control not checked writable
int _pic_doc_w;                  // File NOT under version control writable
*/

static int getWorkspaceTreeRootIndex()
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (index < 0) return TREE_ROOT_INDEX;
   return index;
}

void _SetProjTreeColWidth()
{
   // Initialize tree column width to at least fit the project name.
   // This width may be changed by _InsertProjectFileList().
   longestWW := 0;
   int index=_TreeGetFirstChildIndex(getWorkspaceTreeRootIndex());
   for (;;) {
      if (index<0) {
         break;
      }
      nameOnly := "";
      path := "";
      parse _TreeGetCaption(index) with nameOnly "\t" path;
      int cur=/*_proj_tooltab_tree.*/_text_width(nameOnly);
      if (cur>longestWW+400) {
         longestWW=cur;
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   //curwidth=_TreeColWidth(0);
   /*_proj_tooltab_tree.*/_TreeColWidth(0, longestWW + PROJECTTREEADJUSTCOLUMNWIDTH);
}

static void _projecttbSortFolder(int Node)
{
   // Sort this node but keep sort order of folders
   //int FolderOrder:[];
   _str FolderNames[];
   int i,child=_TreeGetFirstChildIndex(Node);
   for (i=0;child>=0;child=_TreeGetNextSiblingIndex(child),++i) {
      if (_projecttbIsFolderNode(child)) {
         //FolderOrder:[_TreeGetCaption(child)]=i;
         FolderNames[i]=_TreeGetCaption(child);
      }
   }
   _TreeSortCaption(Node,'2P');

   int CurFolderOrder:[];
   child=_TreeGetFirstChildIndex(Node);
   for (i=0;child>=0;child=_TreeGetNextSiblingIndex(child),++i) {
      if (!_projecttbIsFolderNode(child)) {
         break;
      }
      CurFolderOrder:[_TreeGetCaption(child)]=i;
   }

   // Now fix the order of the folders
   child=_TreeGetFirstChildIndex(Node);
   for (i=0;i<FolderNames._length();++i) {
      int index=_TreeSearch(Node,FolderNames[i]);
      int count=CurFolderOrder:[FolderNames[i]]-i;
      if (count>0) {
         while(count--) _TreeMoveUp(index);
      }
   }
}

#if 0
//4:28pm 5/3/1999
// Dan made this global to call it from wkspace.e
//
// This function cynamically populates the project tree at a current
// node, since the tree is not completely populated when a project or
// workspace is opened.
//
// AllDependencies is used to cache project dependencies workspace-wide
// so that we do not have to reparse the solution file with Visual Studio
// projects for every single project.
//
int toolbarBuildFilterList(_str projectName,int ProjectIndex=-1,_str (*AllDependencies):[]=null)
{

   if (projectName== "") return(0);
   /*
        If there are more than 1000 files in the project,
        don't fill in the extensions
        return(0);
   */

   // Show project name in root node:
   _nocheck _control _proj_tooltab_tree;
   _proj_tooltab_tree._TreeSetInfo(TREE_ROOT_INDEX,0,_pic_workspace,_pic_workspace);

   _SetProjTreeColWidth();

   name := "";
   status := 0;
   doneCount := 0;
   i := 0;
   typeless t;
   FolderName := "";
   //This code was dead.
   _proj_tooltab_tree._TreeSetInfo(TREE_ROOT_INDEX, 1);
   int BitmapIndexList[];
   BitmapIndexList[0]=_pic_doc_w;
   BitmapIndexList[1]=_pic_doc_r;
   BitmapIndexList[2]=_pic_vc_co_user_w;
   BitmapIndexList[3]=_pic_vc_co_user_r;
   BitmapIndexList[4]=_pic_vc_co_other_x_w;
   BitmapIndexList[5]=_pic_vc_co_other_x_r;
   BitmapIndexList[6]=_pic_vc_co_other_m_w;
   BitmapIndexList[7]=_pic_vc_co_other_m_r;
   BitmapIndexList[8]=_pic_vc_available_w;
   BitmapIndexList[9]=_pic_vc_available_r;
   BitmapIndexList[10]=_pic_doc_ant;
   mou_hour_glass(true);

   DisplayName := GetProjectDisplayName(projectName);
   _str capname=strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(TREE_ROOT_INDEX,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   orig_wid := p_window_id;
   p_window_id=_proj_tooltab_tree;
   int tree_wid=_proj_tooltab_tree;
   tree_wid._TreeDelete(ProjectIndex,'C');

   projectName=VSEProjectFilename(projectName);
//1:45pm 3/1/2000
//Using a 0 for this parameter defeats querying an SCC version control system
//for the icon to use for each file.  This will increase performance when using
//slower version control systems.  There may be an option for this in the future.
#if 1
   int check_SCC_Status=_isscc();
#else
   check_SCC_Status := 0;
#endif
   if(_IsWorkspaceAssociated(_workspace_filename)) {
      _InsertAssociatedProjectFileList(projectName,
                                       BitmapIndexList,
                                       def_optimize_sccprjfiles,
                                       _pic_tfldclos,
                                       _pic_tfldopen,
                                       check_SCC_Status,
                                       ProjectIndex);

   } else {
      /*
         - Don't insert Refilter=1 wildcard files
         - Expand wildcards other wildcards
      */
      int project_handle=_ProjectHandle(projectName);
      int ExtToNodeHashTab:[];
      BackedUpXMLFilesSection := false;
      backup_project_handle := -1;
      typeless array;
      _xmlcfg_find_simple_array(_ProjectHandle(projectName),
                                VPJX_FILES"//"VPJTAG_F:+
                                //XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                array,TREE_ROOT_INDEX);
      projectHasWildcards := (array._length()!=0);
      _str FoldersToSort:[];
      done := false;
      _str AutoFolders=_ProjectGet_AutoFolders(project_handle);
      CustomView := strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW);
      if (array._length()) {
         if (!CustomView) {
            if (!BackedUpXMLFilesSection) {
               BackedUpXMLFilesSection=true;
               backup_project_handle=_xmlcfg_create('',VSENCODING_UTF8);
               _xmlcfg_copy(backup_project_handle,TREE_ROOT_INDEX,project_handle,_ProjectGet_FilesNode(project_handle),VSXMLCFG_COPY_CHILDREN);
            }
         }
            /*_InsertAssociatedProjectFileList(projectName,
                                             BitmapIndexList,
                                             def_optimize_sccprjfiles,
                                             _pic_tfldclos,
                                             _pic_tfldopen,
                                             check_SCC_Status,
                                             ProjectIndex);
            */


         if (!done) {
            _str pathList[]=null;

            if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
               status=_GetEclipsePathList(strip_filename(projectName,'N'),pathList);
            }else{
               pathList[0]=strip_filename(projectName,'N');
            }
            int folderNodeHash:[];
            PrevParentNode := -1;
            for (i=0;i<array._length();++i) {
               Refilter := _xmlcfg_get_attribute(project_handle,array[i],'Refilter',0);
               if (!Refilter || !CustomView) {
                  if (!BackedUpXMLFilesSection) {
                     BackedUpXMLFilesSection=true;
                     backup_project_handle=_xmlcfg_create('',VSENCODING_UTF8);
                     _xmlcfg_copy(backup_project_handle,TREE_ROOT_INDEX,project_handle,_ProjectGet_FilesNode(project_handle),VSXMLCFG_COPY_CHILDREN);
                  }
                  //_message_box('got here F='_xmlcfg_get_attribute(project_handle,array[i],'N'));
                  int ParentNode=_xmlcfg_get_parent(project_handle,array[i]);
                  if (PrevParentNode!=ParentNode) {
                     PrevParentNode=ParentNode;
                     name=_xmlcfg_get_attribute(project_handle,ParentNode,"Name");
                     folderNodeHash=null;
                  }
                  _ExpandFileView2(project_handle,array[i],_xmlcfg_get_attribute(project_handle,array[i],'N'),pathList,true,false,false,folderNodeHash);
                  FolderName=_xmlcfg_get_attribute(project_handle,ParentNode,'Name');
                  FoldersToSort:[ParentNode]=FolderName;
               }
            }
            if (!CustomView) {
               _ProjectAutoFolders(project_handle);
               //_showxml(project_handle);
            }

         }
      }
      if (!done) {
         status= _InsertProjectFileListXML(project_handle,
                                           BitmapIndexList,
                                           def_optimize_sccprjfiles,
                                           _pic_tfldclos,
                                           _pic_tfldopen,
                                           check_SCC_Status,
                                           ProjectIndex,
                                           ExtToNodeHashTab,
                                           !strieq(_ProjectGet_AutoFolders(project_handle),VPJ_AUTOFOLDERS_CUSTOMVIEW)
                                           );
         NeedToSort := false;
         if (BackedUpXMLFilesSection) {
            int FilesNode=_ProjectGet_FilesNode(project_handle);
            _xmlcfg_delete(project_handle,FilesNode,true);
            _xmlcfg_copy(project_handle,FilesNode,backup_project_handle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);
         }
         if (CustomView) {
            /*
               - Now look for files with Refilter=1
               - Expand wildcards
            */
            _xmlcfg_find_simple_array(project_handle,
                                      VPJX_FILES"//"VPJTAG_F:+'[@Refilter="1"]/@N',array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
            if (array._length()) {
               orig_view_id := p_window_id;
               temp_view_id := 0;
               _create_temp_view(temp_view_id);
               activate_window(temp_view_id);
               for (i=0;i<array._length();++i) {
                  insert_line(translate(array[i],FILESEP,FILESEP2));
               }

               _str pathList[];
               if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
                  status=_GetEclipsePathList(strip_filename(projectName,'N'),pathList);
               }else{
                  pathList[0]=strip_filename(projectName,'N');
               }
               _ExpandFileView(project_handle,temp_view_id,pathList,0);

               _ConvertViewToAbsolute(temp_view_id,strip_filename(projectName,'N'),0,0);
               _str fileList[];
               if (p_Noflines+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE)) {
                  _default_option(VSOPTION_WARNING_ARRAY_SIZE,p_Noflines+10);
               }

               _str line;
               top();up();
               i= 0;
               while (!down()) {
                  get_line(line);
                  fileList[i]=line;
                  ++i;
               }

               activate_window(orig_view_id);
               _InsertProjectFileList(fileList,
                                      ExtToNodeHashTab,//assocTypeList,
                                      //patternList,
                                      BitmapIndexList,
                                      MAXINT,
                                      def_optimize_sccprjfiles,
                                      check_SCC_Status);
               bool NodeDoneHashTab:[];
               // Now sort all the files
               for (t._makeempty();;) {
                  int Node=ExtToNodeHashTab._nextel(t);
                  if (t._isempty()) {
                     break;
                  }
                  if (NodeDoneHashTab._indexin(Node)) {
                     continue;
                  }
                  NodeDoneHashTab:[Node]=true;
                  //_projectbSortFolder(Node);
                  tree_wid._TreeSortCaption(Node,'2=');
               }
            } else {
               for (t._makeempty();;) {
                  FolderName=FoldersToSort._nextel(t);
                  if (t._isempty()) {
                     break;
                  }
                  index := tree_wid._TreeSearch(ProjectIndex,FolderName,'T');
                  if (FolderName=='' || index<0) {
                     index=ProjectIndex;
                  }
                  tree_wid._TreeSortCaption(index,'2=');
                  //_projecttbSortFolder(index);
               }
            }
         }
         // IF there are wildcards in this project
         if (projectHasWildcards) {
            // Remove the duplicates
            tree_wid._TreeRemoveDuplicatesSpecial(ProjectIndex);
         }
      }
   }

   tree_wid._toolbarUpdateDependencies2(ProjectIndex, AllDependencies);
   p_window_id=orig_wid;

   mou_hour_glass(false);
   return(status);
}

#else 

int toolbarBuildPackageFilter(_str projectName, int ProjectIndex=-1, _str (*AllDependencies):[]=null)
{
   if (projectName== "") return(0);
   // Show project name in root node:
   _nocheck _control _proj_tooltab_tree;
   workspace_index := _proj_tooltab_tree.getWorkspaceTreeRootIndex();
   _proj_tooltab_tree._TreeSetInfo(workspace_index,TREE_NODE_COLLAPSED,_pic_workspace,_pic_workspace);
   _SetProjTreeColWidth();

   status := 0;
   //This code was dead.
   _proj_tooltab_tree._TreeSetInfo(workspace_index, TREE_NODE_EXPANDED);
   mou_hour_glass(true);
   DisplayName := GetProjectDisplayName(projectName);
   capname := _strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(workspace_index,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   orig_wid := p_window_id;
   p_window_id=_proj_tooltab_tree;
   int tree_wid=_proj_tooltab_tree;
   tree_wid._TreeDelete(ProjectIndex,'C');

   projectName=VSEProjectFilename(projectName);
//1:45pm 3/1/2000
//Using a 0 for this parameter defeats querying an SCC version control system
//for the icon to use for each file.  This will increase performance when using
//slower version control systems.  There may be an option for this in the future.
#if 1
   int check_SCC_Status=_isscc()?1:0;
#else
   check_SCC_Status := 0;
#endif
   int project_handle=_ProjectHandle(projectName);
   BackedUpXMLFilesSection := false;
   backup_project_handle := -1;
   done := false;
   if (!BackedUpXMLFilesSection) {
      BackedUpXMLFilesSection=true;
      backup_project_handle=_xmlcfg_create('',VSENCODING_UTF8);
      _xmlcfg_copy(backup_project_handle,TREE_ROOT_INDEX,project_handle,_ProjectGet_FilesNode(project_handle),VSXMLCFG_COPY_CHILDREN);
   }
   _VPJExpandWildcards(project_handle, _workspace_filename, projectName);
   _ProjectAutoFolders(project_handle);
   if (!done) {
      status = _ProjectBuildTree(_workspace_filename,
                                 projectName, 
                                 project_handle,
                                 def_optimize_sccprjfiles,
                                 check_SCC_Status,
                                 ProjectIndex,
                                 true,
                                 def_refilter_wildcards);
      NeedToSort := false;
      if (BackedUpXMLFilesSection) {
         int FilesNode=_ProjectGet_FilesNode(project_handle);
         _xmlcfg_delete(project_handle,FilesNode,true);
         _xmlcfg_copy(project_handle,FilesNode,backup_project_handle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);
      }
      tree_wid._TreeRemoveDuplicatesSpecial(ProjectIndex);
   }
   return(status);
}

static void _SortFolders(int parentIndex, bool CustomView, bool PackageView)
{
   if (CustomView) {
      // sort top level files, folders first (no sort folders)
      _TreeSortCaption(parentIndex, 'FTM=');
   } else if (PackageView) {
      _TreeSortCaption(parentIndex);
   } else {
      // sort all recursively
      _TreeSortCaption(parentIndex, 'FPTM');
   }
}

extern void _projectFileCacheCheck(_str workspace_file, _str project_file);

// use builtin to handle wildcard expansion using project cache
int toolbarBuildFilterList(_str projectName,int ProjectIndex=-1,_str (*AllDependencies):[]=null)
{
   if (projectName== "") return(0);
   /*
        If there are more than 1000 files in the project,
        don't fill in the extensions
        return(0);
   */

   // Show project name in root node:
   _nocheck _control _proj_tooltab_tree;
   workspace_index := _proj_tooltab_tree.getWorkspaceTreeRootIndex();
   _proj_tooltab_tree._TreeSetInfo(workspace_index,TREE_NODE_COLLAPSED,_pic_workspace,_pic_workspace);

   name := "";
   status := 0;
   //This code was dead.
   _proj_tooltab_tree._TreeSetInfo(workspace_index, TREE_NODE_EXPANDED);
   mou_hour_glass(true);

   DisplayName := GetProjectDisplayName(projectName);
   capname := _strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(workspace_index,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   projectName=VSEProjectFilename(projectName);
   if (!_ProjectFileExists(projectName)) {
      return(0);
   }

   orig_wid := p_window_id;
   p_window_id=_proj_tooltab_tree;
   int tree_wid=_proj_tooltab_tree;
   tree_wid._TreeBeginUpdate(ProjectIndex,'','T');

//1:45pm 3/1/2000
//Using a 0 for this parameter defeats querying an SCC version control system
//for the icon to use for each file.  This will increase performance when using
//slower version control systems.  There may be an option for this in the future.
#if 1
   int check_SCC_Status=_isscc()?1:0;
#else
   check_SCC_Status := 0;
#endif
   needSort := false;
   project_handle := -1;
   AutoFolders := "";
   CustomView := false;
   PackageView := false;

   if (project_is_associated_file(projectName)) {
      int BitmapIndexList[];
      BitmapIndexList[0]=_pic_doc_w;
      BitmapIndexList[1]=_pic_doc_r;
      BitmapIndexList[2]=_pic_vc_co_user_w;
      BitmapIndexList[3]=_pic_vc_co_user_r;
      BitmapIndexList[4]=_pic_vc_co_other_x_w;
      BitmapIndexList[5]=_pic_vc_co_other_x_r;
      BitmapIndexList[6]=_pic_vc_co_other_m_w;
      BitmapIndexList[7]=_pic_vc_co_other_m_r;
      BitmapIndexList[8]=_pic_vc_available_w;
      BitmapIndexList[9]=_pic_vc_available_r;
      BitmapIndexList[10]=_pic_doc_ant;
      _InsertAssociatedProjectFileList(projectName,
                                       BitmapIndexList,
                                       def_optimize_sccprjfiles,
                                       _pic_tfldclos,
                                       _pic_tfldopen,
                                       check_SCC_Status,
                                       ProjectIndex);

   } else {
      project_handle=_ProjectHandle(projectName);
      AutoFolders=_ProjectGet_AutoFolders(project_handle);
      CustomView=strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW);
      PackageView=strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW);
      buildPackages := false;
      hasWildcards := (_VPJHasWildcards(project_handle) != 0);
      typeless array;
      if (PackageView) {
         buildPackages = hasWildcards;
      }

      if (hasWildcards && !_isProjectInfoCached(_workspace_filename, projectName)) {
         _projectFileCacheCheck(_workspace_filename, projectName);
      }

      if (buildPackages) {
         status = toolbarBuildPackageFilter(projectName, ProjectIndex, AllDependencies);

      } else {
         status = _ProjectBuildTree(_workspace_filename,
                                    projectName, 
                                    project_handle,
                                    def_optimize_sccprjfiles,
                                    check_SCC_Status,
                                    ProjectIndex,
                                    !CustomView,
                                    def_refilter_wildcards);
         needSort = true;
      }
   }
   _TreeEndUpdate(ProjectIndex);
   if ( needSort ) _SortFolders(ProjectIndex, CustomView, PackageView);
   tree_wid._toolbarUpdateDependencies2(ProjectIndex, AllDependencies);
   projecttbTreeReset();
   p_window_id=orig_wid;
   
   mou_hour_glass(false);
   return(status);
}
#endif

static void _TreeRemoveDuplicatesSpecial(int index)
{
   index=_TreeGetFirstChildIndex(index);
   if (!index) return;
   for (;;) {
      if (index<0) {
         return;
      }
      if(_projecttbIsFolderNode(index)) {
         _TreeRemoveDuplicatesSpecial(index);
      } else if(_projecttbIsProjectFileNode(index)) {
         break;
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   projectPath := _strip_filename(_projecttbTreeGetCurProjectName(index,false),'N');
   _str caption,fullPath;
   fullPath2 := "";

   caption= _TreeGetCaption(index);
   name := "";
   parse caption with name "\t" fullPath;
   fullPath=absolute(fullPath,projectPath);
   index=_TreeGetNextSiblingIndex(index);
   for (;;) {
      if (index<0) {
         break;
      }
      caption= _TreeGetCaption(index);
      parse caption with name "\t" fullPath2;
      fullPath2=absolute(fullPath2,projectPath);
      if (_file_eq(fullPath,fullPath2)) {
         _TreeDelete(_TreeGetPrevSiblingIndex(index));
      }
      fullPath=fullPath2;
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void DeleteDepenciesFromTree(int index)
{
   index=_TreeGetFirstChildIndex(index);
   int DeleteIndexes[];
   state := 0;
   bm1 := bm2 := 0;
   for (;;) {
      if (index<0) {
         break;
      }
      _TreeGetInfo(index,state,bm1,bm2);
      if (bm1==_pic_project_dependency) {
         DeleteIndexes :+= index;
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   for (i:=0;i<DeleteIndexes._length();++i) {
      _TreeDelete(DeleteIndexes[i]);
   }
}

static int InsertAtBottom(int ParentIndex,_str NewCap,int BmIndex1,int BmIndex2,
                          int State=TREE_NODE_LEAF)
{
   BottomIndex := _TreeGetFirstChildIndex(ParentIndex);
   if (BottomIndex<0) {
      int NewIndex=_TreeAddItem(ParentIndex,NewCap,TREE_ADD_AS_CHILD,BmIndex1,BmIndex2,State);
      return(NewIndex);
   }
   LastIndex := -1;
   while (BottomIndex>-1) {
      LastIndex=BottomIndex;
      BottomIndex=_TreeGetNextSiblingIndex(BottomIndex);
   }
   if (LastIndex>-1) {
      int NewIndex=_TreeAddItem(LastIndex,NewCap,0,BmIndex1,BmIndex2,State);
   }
   return(-1);
}

static _str _RemoveDuplicatesFromList(_str list)
{
   _str array[];
   for (;;) {
      _str cur=parse_file(list,false);
      if (cur=='') {
         break;
      }
      array[array._length()]=cur;
   }
   array._sort('2');
   _aremove_duplicates(array,upcase(_fpos_case)=='i');
   list='';
   int i;
   for (i=0;i<array._length();++i) {
      if (list:=='') {
         list=_maybe_quote_filename(array[i]);
      } else {
         strappend(list,' '_maybe_quote_filename(array[i]));
      }
   }
   return(list);
}
// DJB 05/26/2011
// AllDependencies is used to cache project dependencies workspace-wide
// so that we do not have to reparse the solution file with Visual Studio
// projects for every single project.
//
static void _toolbarUpdateDependencies2(int index, _str (*AllDependencies):[]=null)
{
   ProjectName := _projecttbTreeGetCurProjectName(index);
   _str ProjectFiles[];
   ProjectFiles[0]=_RelativeToWorkspace(ProjectName);
   _str Dependencies:[];
   _GetDependencies(ProjectFiles,Dependencies,AllDependencies);
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._isempty()) {
         return;
      }
      break;
   }

   isVisualStudio :=_IsVisualStudioWorkspaceFilename(_workspace_filename);
   if (isVisualStudio) {
      return;
   }

   isEclipse := _IsEclipseWorkspaceFilename(_workspace_filename);
   _str Filename=i;
   Cap := "";
   if (isEclipse) {
      Cap=_strip_filename(Filename,'PE')"\t"_strip_filename(_AbsoluteToWorkspace(Filename),'N');
   }else{
      Cap=_strip_filename(Filename,'P')"\t"_AbsoluteToWorkspace(Filename);
   }
   _str deplist=_RemoveDuplicatesFromList(Dependencies:[i]);
   DeleteDepenciesFromTree(index);
   for (;;) {
      _str cur=parse_file(deplist);
      if (cur=='') {
         break;
      }
      NewCap := _strip_filename(strip(cur,'B','"'),'P')"\t"strip(cur,'B','"');
      InsertAtBottom(index,NewCap,_pic_project_dependency,_pic_project_dependency);
   }
}
void toolbarUpdateDependencies()
{
   oriWindowId := p_window_id;
   formid := _tbGetActiveProjectsForm();
   if (!formid) {
      p_window_id= oriWindowId;
      return;
   }

   isVisualStudio :=_IsVisualStudioWorkspaceFilename(_workspace_filename);
   if (isVisualStudio) {
      return;
   }

   _nocheck _control _proj_tooltab_tree;
   p_window_id= formid._proj_tooltab_tree.p_window_id;
   _str Files[];
   Files._makeempty();
   _GetWorkspaceFiles(_workspace_filename,Files);
   _str Dependencies:[]=null;
   _GetDependencies(Files,Dependencies);
   _str HandledProjects:[]=null;

   isEclipse := _IsEclipseWorkspaceFilename(_workspace_filename);
   // Add dependencies that are needed
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._isempty()) {
         break;
      }
      _str Filename=i;
      Cap := "";
      if (isEclipse) {
         Cap=_strip_filename(Filename,'PE')"\t"_strip_filename(_AbsoluteToWorkspace(Filename),'N');
      }else{
         Cap=_strip_filename(Filename,'P')"\t"_AbsoluteToWorkspace(Filename);
      }
      workspace_index := formid._proj_tooltab_tree.getWorkspaceTreeRootIndex();
      int index=formid._proj_tooltab_tree._TreeSearch(workspace_index,Cap,_fpos_case);
      ShowChildren := 0;
      if (index>=0) {
         _TreeGetInfo(index,ShowChildren);
         if (ShowChildren==1) {  // Only update the projects that are expanded.
            formid._proj_tooltab_tree.DeleteDepenciesFromTree(index);
            _str list=_RemoveDuplicatesFromList(Dependencies:[i]);
            for (;;) {
               _str cur=parse_file(list);
               if (cur=='') {
                  break;
               }
               HandledProjects:[_file_case(Cap)]=Cap;
               NewCap := _strip_filename(strip(cur,'B','"'),'P')"\t"strip(cur,'B','"');
               formid._proj_tooltab_tree.InsertAtBottom(index,NewCap,_pic_project_dependency,_pic_project_dependency);
            }
         }
      }
   }

   for (i._makeempty();;) {
      HandledProjects._nextel(i);
      if (i._isempty()) break;
   }
   // Delete old dependencies
   int index=_TreeGetFirstChildIndex(getWorkspaceTreeRootIndex());
   for (;;) {
      if (index<0) break;
      cap := _TreeGetCaption(index);
      if (!HandledProjects._indexin(_file_case(cap))) {
         DeleteChildWithBMIndex(index,_pic_project_dependency);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   p_window_id=oriWindowId;
}

static void DeleteChildWithBMIndex(int TreeIndex,int BMIndex)
{
   cindex := _TreeGetFirstChildIndex(TreeIndex);
   state := 0;
   bm1 := bm2 := 0;
   for (;;) {
      if (cindex<0) return;
      _TreeGetInfo(cindex,state,bm1,bm2);
      nextindex := _TreeGetNextSiblingIndex(cindex);
      if (bm1==BMIndex || bm2==BMIndex) {
         _TreeDelete(cindex);
      }
      cindex=nextindex;
   }
}

/**
 * 4:31pm 8/22/1997
 * This was static, but Dan made it global so that the project toolbar
 * could be updated if someone added/removed a project file from the
 * make tags dialog
 *
 * @param projectName      Absolute project name.
 * @param AllDependencies  (optional) Used to cache workspace-wide 
 *                         project dependencies 
 *
 * @return 0 on success, <0 otherwise
 */
void toolbarUpdateFilterListForForm(int form_wid,_str projectName,
                            _str (*AllDependencies):[]=null) {
   projectIndex := -1;
   oriWindowId := p_window_id;

   _nocheck _control _proj_tooltab_tree;
   p_window_id= form_wid._proj_tooltab_tree.p_window_id;

   // Delete all level 1 nodes in tree view and remember the expansion list:
   int expansionModeList[];
   _str expansionNameList[];
   workspace_index := form_wid._proj_tooltab_tree.getWorkspaceTreeRootIndex();
   childL1 := form_wid._proj_tooltab_tree._TreeGetFirstChildIndex(workspace_index);
   caption := "";
   if (childL1>=0) {
      caption = form_wid._proj_tooltab_tree._TreeGetCaption(childL1);
   }
   // Since we don't use the "real" root anymore, now we have to check for
   // "no workspace open".  We actually do need both cases here.
   if ( caption=="" || caption=="No workspace open" ) {
      toolbarUpdateWorkspaceList();
      p_window_id= oriWindowId;
      return;
   }
   typeless p;
   _TreeSavePos(p);
   _str States[];
   _GetProjTreeStates(States);

   // If no current project
   if (projectName== "") {
      _str text;
      text= "  No Project  ";
      int longestWW;
      longestWW= form_wid._proj_tooltab_tree._text_width(text);
      //form_wid._proj_tooltab_tree._TreeSetCaption(workspace_index, text);
      form_wid._proj_tooltab_tree._TreeColWidth(0, longestWW + PROJECTTREEADJUSTCOLUMNWIDTH);
      p_window_id= oriWindowId;
      return;
   }

   // Reset expansion state:
   _RestoreProjTreeStates(States, AllDependencies);
   _TreeRestorePos(p);
   _TreeSizeColumnToContents(0);
   p_window_id= oriWindowId;
   //toolbarUpdateDependencies();
   return;
}
/**
 * 4:31pm 8/22/1997
 * This was static, but Dan made it global so that the project toolbar
 * could be updated if someone added/removed a project file from the
 * make tags dialog
 *
 * @param projectName      Absolute project name.
 * @param AllDependencies  (optional) Used to cache workspace-wide 
 *                         project dependencies 
 *
 * @return 0 on success, <0 otherwise
 */
void toolbarUpdateFilterList(_str projectName,
                            _str (*AllDependencies):[]=null)
{
   TBPROJECTS_FORM_INFO v;
   int i;
   foreach (i => v in gtbProjectsFormList) {
      toolbarUpdateFilterListForForm(i,projectName,AllDependencies);
   }
}

//Start DANS STUFF
void _actapp_makefile(_str gettingFocus='')
{
   if (!gettingFocus) return;
   if (!def_actapp) {
      return;
   }
   if (!(def_autotag_flags2 & AUTOTAG_WORKSPACE_NO_ACTIVATE) &&
       !(def_autotag_flags2 & AUTOTAG_DISABLE_ALL_BG) &&
       !(def_autotag_flags2 & AUTOTAG_DISABLE_ALL_THREADS)) {
      _MaybeRetagWorkspace(arg(1));
   }
}
int _OnUpdate_project_add_file(CMDUI &cmdui,int target_wid, _str command)
{
   cmdname := "";
   filename := "";
   parse command with cmdname filename;
   if (_workspace_filename=='' || _project_name=='') {
      return(MF_GRAYED);
   }
   if (filename=="") {
      if ( !target_wid || !target_wid._isEditorCtl()) {
         return(MF_GRAYED);
      }
      filename=target_wid.p_buf_name;
   }
   // For now, its too slow to check whether the file is
   // already in the project.  If we every cache the project
   // files or keep the project file loaded, we can do better.
#if 0
   // Code below only works for taggable project files
   filename=absolute(strip(filename,'B','"'));
   tag_files=project_tags_filename();
   for (;;) {
      parse tag_files with tag_filename tag_files;
      if (tag_filename=="") {
         break;
      }
      int status= tag_read_db(tag_filename);
      if (!status) {
         // get the files from the database
         int status=tag_get_date(filename,tagged_date);
         if (!status) {
            return(MF_GRAYED);
         }
      }
   }
#endif
   return(MF_ENABLED);
}

bool _FileExistsInCurrentProject(_str filename,_str ProjectName=_project_name)
{
   return _isFileInProject(_workspace_filename, ProjectName, filename) != 0;
}

bool _FileExistsInCurrentWorkspace(_str filename,_str WorkspaceName=_workspace_filename)
{
   _str project_names[];
   _GetWorkspaceFiles(WorkspaceName,project_names);

   len := project_names._length();

   for (i:=0;i<len;++i) {
      curProjectFilename := absolute(project_names[i],_file_path(WorkspaceName));
      existsInCur := _FileExistsInCurrentProject(filename,curProjectFilename);
      if (existsInCur) {
         return true;
      }
   }

   return false;
}


int _OnUpdate_project_add_files_prompt_project(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename == '') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

_command int project_add_files_prompt_project(typeless files = "", _str project = '') name_info(',')
{
   // If no filename, then get the current buffer name
   if (files == '') {
      files = _maybe_quote_filename(p_buf_name);

      // no buffer name?
      if (files == '') {
         _message_box("Buffer has no name","Error",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
   }

   // we might have multiple files here, let's split them up

   // now get the project files in this workspace
   _str projects[], vendorProjects[];
   _GetWorkspaceFiles(_workspace_filename, projects, vendorProjects);

   // is there more than one project in this workspace?
   if (projects._length() == 1) {
      // just one project, this is easy
      project = projects[0];
   } else {

      // go through and get just the project name, stripping the relative path
      _str justNamesToRelNames:[];
      for (i := 0; i < projects._length(); i++) {
         projName := projects[i];
         projects[i] = _strip_filename(projName, 'P');

         justNamesToRelNames:[projects[i]] = projName;
      }

      // sort them alphabetically
      projects._sort('F');
      if (projects._length() == 0) {
         _message_box("Current workspace has no projects.");
      } else {
         curProject := _strip_filename(_project_name, 'P');
         result := _mdi.comboBoxDialog('Add file to project', 
                                       'Select a project to add the file', 
                                       projects, 0, curProject, 
                                       'strip_filename');
         if (result == IDOK) {
            if (justNamesToRelNames._indexin(_param1)) {
               project = justNamesToRelNames:[_param1];
            } 
         }
      }
   }

   if (project != '') {
      // make it absolute to the workspace
      workspaceDir := _strip_filename(_workspace_filename, 'N');
      project = absolute(project, workspaceDir);

      _str already_in_project_list[];
      _str filename;
      for (i:=0;;++i) {
         if (files._varformat()==VF_LSTR) {
            if (files=='') break;
            filename=parse_file(files,false);
         } else {
            if (i>=files._length()) break;
            filename=files[i];
         }
         if (filename != '') {
            if (_FileExistsInCurrentProject(filename)) {
               already_in_project_list:+=filename;
            } else {
               project_add_file(filename, false, project);
            }
         }
      }
      if (already_in_project_list._length()) {
         if (already_in_project_list._length()==1) {
            msg:=nls("'%s' already exists in project %s",already_in_project_list[0],project);
            _message_box(msg);
         } else {
            _str buttons = 'OK,Cancel:_cancel';
            form_wid:=show('_sellist_form -mdi',
                 nls("Already in project %s",project),
                 SL_NOISEARCH|SL_SIZABLE,
                 already_in_project_list,
                 buttons,    // buttons
                 '',    // help item name
                 ''     // font
                 );
            _nocheck _control _cancel,_sellistok;
            form_wid._cancel.p_cancel=false;
            form_wid._sellistok.p_cancel=true;
            form_wid._cancel.p_visible=false;
            _modal_wait(form_wid);
         }
      }
   } else {
      return COMMAND_CANCELLED_RC;
   }

   return 0;
}

static int _workspace_open_directory(typeless dirs,bool &dialog_displayed,bool &workspace_created)  {
   workspace_created=false;
   dialog_displayed=false;
   if (_workspace_filename!='') {
      return INVALID_ARGUMENT_RC;
   }

   _str path;
   if (dirs._varformat()==VF_LSTR) {
      path=parse_file(dirs,false);
      if (path=='') return INVALID_ARGUMENT_RC;
   } else { 
      path=dirs[0];
      if (path=='') return INVALID_ARGUMENT_RC;
   }
   path=absolute(path);
   _maybe_append_filesep(path);
   _str projectPath=path;
   _str projectName;
   projectName=_getDirTitledWorkspaceName(path);
   int status;
   // Check if this workspace already exists
   _str vpw_file=projectPath:+projectName:+WORKSPACE_FILE_EXT;
   if (file_exists(vpw_file)) {
      status=workspace_open(_maybe_quote_filename(vpw_file));
      return status;
   }
   _str cwd=getcwd();
   // See if the vpw file is in a writable locations
   int handle2=_file_open(vpw_file,1 /* create */);
   if (handle2>=0) {
      _file_close(handle2);
      delete_file(vpw_file);
   } else {
      // There's already an auto-project for this directory or 
      // a directory which looks like this directory. Figure out
      // if it is the right one.
      _str auto_projects_path=get_env(_SLICKEDITCONFIG):+"auto-projects":+FILESEP;
      int i;
      _str name;
      int handle;
      for (i=1;;++i) {
         name=projectName;
         if (i>1) {
            name:+=i;
         }
         // See if there is a Directory foloder
         _str vtg_file=auto_projects_path:+name:+TAG_FILE_EXT;
         if (file_exists(vtg_file)) {
            // See if we can get read/write access to this file.
            handle=_file_open(vtg_file,3 /* append */);
            if (handle<0) {
               // This file is probably open by another process
               continue;
            }
            _file_close(handle);
            /*status:=delete_file(vtg_file);
            if (status) {
               // Odd can't delete tag file
               continue;
            } */
         }
         vpw_file=auto_projects_path:+name:+WORKSPACE_FILE_EXT;
         vpj_file:=auto_projects_path:+name:+PRJ_FILE_EXT;
         handle=_xmlcfg_open(vpj_file,status);
         if (handle>=0) {
            RelativePath:=relative(path,auto_projects_path);
            int node;
#if 0     /* This really only works if all thes projects are using wildcards and directory folders */
            node:=_ProjectGet_DirectoryFolderNode(handle,RelativePath);
            if (node>=0) {
               _xmlcfg_close(handle);
               break;
            }
#endif
            // Look for a file node that is a starts with this RelativePath
            re:='^'_escape_re_chars(translate(RelativePath,'/','\'));
            node=_ProjectGet_FileNodeRE(handle,re);
            if (node>=0) {
               _xmlcfg_close(handle);
               break;
            }
            _xmlcfg_close(handle);
            // Let's use a different temp name.
            continue;
         }
         break;
      }
      if (file_exists(vpw_file)) {
         status=workspace_open(vpw_file);
         cd(cwd);
         return status;
      }
      _make_path(auto_projects_path);
      projectName=name;
      projectPath=auto_projects_path;
   }

   DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);

   if (flags & DIRPROJFLAG_DONT_PROMPT) {
      status=workspace_new_project(false,
                            _default_option(VSOPTIONZ_DIR_PROJECT_TYPE),
                            projectName,
                            projectPath,
                            false,
                            projectName,
                            '',
                            false,
                            false
                            );
   } else { 
      dialog_displayed=true;
      show('-modal -mdi _workspace_new_form','P',null,vpw_file);
      status=0;
      if (_workspace_filename=='') {
         status=COMMAND_CANCELLED_RC;
      }
   }
   workspace_created=true;

   if (handle2<0) {
      if (_workspace_filename!='') {
         project_handle:=_ProjectHandle(_project_name);
         _ProjectSet_WorkingDir(project_handle,projectPath);
      }
      cd(cwd);
   }

   // remove filter folders
   if (_workspace_filename!='') {
      project_handle:=_ProjectHandle(_project_name);
      _xmlcfg_find_simple_array(project_handle, VPJX_FILES"//":+VPJTAG_FOLDER, auto array);
      foreach (auto folderNode in array) {
         _xmlcfg_delete(project_handle, (int)folderNode);
      }
   }
   return status;
}                     
/*int _OnUpdate_project_add_directory_folder(CMDUI &cmdui,int target_wid,_str command) {
   // do we have a workspace open here?
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }

} */
_str _project_xlat_special_excludes(_str excludes) {
   int i;
   i = pos('(^|;)<Project Excludes>($|;)',excludes,1,'ri');
   if (i>0) {
       _str project_excludes=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES);
       excludes=stranslate(excludes,project_excludes,'(#<=(^|;))<Project Excludes>(#=($|;))',"ri");
   }

   i = pos('(^|;)<Binary Files>($|;)',excludes,1,'ri');
   if (i>0) {
      ext_list := _LangGetExtensions("binary");
      ext_list=stranslate(ext_list,';*.',' ');
      if (length(ext_list)) {
         ext_list='*.'ext_list;
      }
      excludes=stranslate(excludes,ext_list,'(#<=(^|;))<Binary Files>(#=($|;))',"ri");
   }
   return excludes;
}

static bool add_tree_prompt(_str path,bool addCustomFolders,bool run_from_project_properties=false) {
   // see if we selected a folder in directory structure
   origPath := getcwd();
   chdir(path,1);    /* change drive and directory. */

   int fid;
   fid= p_active_form;
   form_wid:=(int)_MDICurrent().show('-center _project_add_tree_or_wildcard_form',
               'Add Tree',
               _default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES),    // filespec
               true,        // attempt retrieval
               true,         // show exclude filespec
               (run_from_project_properties)?gProjectName:_project_name,  // project file name
               (run_from_project_properties)?!_IsWorkspaceAssociated(_workspace_filename):true, //showWildcard, // show wildcard option
               true,         // allow ant paths
               addCustomFolders);
   DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
   bool dont_prompt= (flags&DIRPROJFLAG_DONT_PROMPT)!=0;
   orig_wid:=p_window_id;
   p_window_id=form_wid;
   _nocheck _control ctlrecursive,ctlwildcard,ctldirectoryfolder,ctlsymlinks,ctlcustomfolders,ctlexclude_filespecs,ctlpath_textbox,ctldir_tree;
   ctlrecursive.p_value=(flags&DIRPROJFLAG_RECURSIVE)?1:0;
   ctlwildcard.p_value=(flags&DIRPROJFLAG_ADD_AS_WILDCARD)?1:0;
   wildcard_flag:=!ctlwildcard.p_visible && (flags&DIRPROJFLAG_ADD_AS_WILDCARD);
   ctldirectoryfolder.p_value=(flags&DIRPROJFLAG_DIRECTORY_FOLDER)?1:0;
   create_parent_folder_flag:=!ctldirectoryfolder.p_visible && (flags&DIRPROJFLAG_DIRECTORY_FOLDER);
   ctlsymlinks.p_value=(flags&DIRPROJFLAG_FOLLOW_SYMLINKS)?1:0;
   if (addCustomFolders) {
      ctlcustomfolders.p_value=(flags&DIRPROJFLAG_CREATE_SUBFOLDERS)?1:0;
   }
   create_subfolders_flag:=!ctlcustomfolders.p_visible && (flags&DIRPROJFLAG_CREATE_SUBFOLDERS);
   ctlexclude_filespecs.p_text=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES);
   ctlpath_textbox.p_text=path;
   ctlpath_textbox.p_enabled=false;
   ctldir_tree.p_enabled=false;
   typeless result=_modal_wait(form_wid);
   if (result== "") {
      return true;
   }

   chdir(origPath,1);
// _param1 - base path
   if (run_from_project_properties) {
      // _param1 - trees to add (array of paths)
      // _param2 - recursive?
      // _param3 - follow symlinks?
      // _param4 - exclude filespecs (array of filespecs)
      // _param5 - add as wildcard

      // _param7 - list folders
      // _param8 - directory folder
         // _param5 specifies whether this tree was added as a wildcard or not
         if (_param5) {
            // add as wildcards!
            _addWildcardsToProject(_param1, _param6, _param4, _param2, _param3, gProjectName, gProjectHandle,_param7,_param8);
         } else {
            addTreeToProject(_param1, _param6, _param4, _param2, _param3, _param7);
         }
   }

   flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS)&~(DIRPROJFLAG_RECURSIVE|DIRPROJFLAG_ADD_AS_WILDCARD|DIRPROJFLAG_DIRECTORY_FOLDER|DIRPROJFLAG_FOLLOW_SYMLINKS|DIRPROJFLAG_DONT_PROMPT|DIRPROJFLAG_CREATE_SUBFOLDERS);
   if (_param2) flags|=DIRPROJFLAG_RECURSIVE;
   if (_param5 || wildcard_flag) flags|=DIRPROJFLAG_ADD_AS_WILDCARD;
   if (_param8 || create_parent_folder_flag) flags|=DIRPROJFLAG_DIRECTORY_FOLDER;
   if (_param3) flags|=DIRPROJFLAG_FOLLOW_SYMLINKS;
   if (dont_prompt) flags|=DIRPROJFLAG_DONT_PROMPT;
   if (_param7 || create_subfolders_flag) flags|=DIRPROJFLAG_CREATE_SUBFOLDERS;
   if (flags!=_default_option(VSOPTION_DIR_PROJECT_FLAGS)) {
      _default_option(VSOPTION_DIR_PROJECT_FLAGS,flags);
   }
   _param4=join(_param4, ';');
   _param6= join(_param6, ';');
   if (_param6!=_default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES)) {
      _default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES,_param6);
   }
   if (_param4!=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES)) {
      _default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES,_param4);
   }

   _param1._makeempty();
   _param4._makeempty();
   return false;
}
_command int project_add_directory_folder(typeless dirs='') name_info(DIR_ARG',')
{
   if (_project_name!='') {
      int handle=_ProjectHandle(_project_name);
#if 0
      // do we even support adding folders to this project?
      if (!_ProjectIs_AddDeleteFolderSupported(handle)) {
         _message_box('Only supported with native SlickEdit Workspaces');
         return INVALID_ARGUMENT_RC;
      }
#endif
      if (_workspace_filename!='' && _IsWorkspaceAssociated(_workspace_filename)) {
         _message_box('Currently only supported with native SlickEdit Workspaces');
         return INVALID_ARGUMENT_RC;
      }
   }
   bool workspace_already_open=true;
   bool workspace_created=false;
   bool dialog_displayed=false;
   // In case, the current directory changes, convert all input directories
   // to absolute.
   _str abs_dirs[];
   int i;
   for (i=0;;++i) {
      _str path;
      if (dirs._varformat()==VF_LSTR) {
         path=parse_file(dirs,false);
         if (path=='') break;
      } else { 
         if (i>=dirs._length()) break;
         path=dirs[i];
         if (path=='') continue;
      }
      path=absolute(path);
      _maybe_append_filesep(path);
      abs_dirs:+=path;
   }

   /* convert */ 
   if (_workspace_filename=='') {
      workspace_already_open=false;
      // Create an untitled workspace
      _workspace_open_directory(abs_dirs,dialog_displayed,workspace_created);
      if (_workspace_filename=='') {
         return COMMAND_CANCELLED_RC;
      }
      if (_workspace_filename!='' && _IsWorkspaceAssociated(_workspace_filename)) {
         _message_box('Currently only supported with native SlickEdit Workspaces');
         return INVALID_ARGUMENT_RC;
      }
   }
   project_handle:=_ProjectHandle(_project_name);
   if (_ProjectIs_SupportedXMLVariation(project_handle)) {
      project_handle=_ProjectGet_AssociatedHandle(project_handle);
   }
   bool added_one=false;
   i=0;
   int OrigProjectFileList;
   _project_before_modify_files(_project_name,project_handle,OrigProjectFileList);
   for (;;++i) {
      _str path;
      if (i>=abs_dirs._length()) break;
      path=abs_dirs[i];
      if (path=='') continue;
      path=absolute(path);
      _maybe_append_filesep(path);

      //newfilename:= path:+includes;
      //_str RelFilename=_RelativeToProject(newfilename);
      if (!workspace_already_open && !workspace_created) {
         if (i==0) {
            //assume first directory already in here
            continue;
         }
         // Allow users to add the same thing more than once
#if 0
         _str RelPath=_RelativeToProject(path);
         re:='^'_escape_re_chars(translate(RelPath,'/','\'));
         // Look for complete list first
         //if (_ProjectGet_FileNode(project_handle,RelFilename)>=0) {
         if (_ProjectGet_FileNodeRE(project_handle,re)>=0) {
            if (workspace_already_open) {
               msg:=nls("The directory '%s' is already in project %s",path,_project_name);
               _message_box(msg,0,MB_OK|MB_ICONEXCLAMATION);
            }
            continue;
         }
#endif
      }
      bool is_custom_view=strieq(_ProjectGet_AutoFolders(project_handle),VPJ_AUTOFOLDERS_CUSTOMVIEW);
      DIRPROJFLAGS flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
      bool dont_prompt= (flags&DIRPROJFLAG_DONT_PROMPT)!=0;
      if (!workspace_created) {
         if (!dont_prompt) {
            if (add_tree_prompt(path,is_custom_view)) {
               break;
            }
         }
      }
      flags=_default_option(VSOPTION_DIR_PROJECT_FLAGS);
      bool recursive=(flags&DIRPROJFLAG_RECURSIVE)!=0;
      bool add_as_wildcard=(flags&DIRPROJFLAG_ADD_AS_WILDCARD)!=0;
      bool directory_folder=(flags&DIRPROJFLAG_DIRECTORY_FOLDER)!=0;
      bool follow_symlinks= (flags&DIRPROJFLAG_FOLLOW_SYMLINKS)!=0;
      bool create_subfolders= (flags&DIRPROJFLAG_CREATE_SUBFOLDERS)!=0;

      _str excludes=_default_option(VSOPTIONZ_DIR_PROJECT_EXCLUDES);
      excludes=_project_xlat_special_excludes(excludes);
      excludes=strip(excludes,'B',';');  // Strip leading and trailing semicolons
      _str excludeList[];
      split(excludes, ";", excludeList);

      _str includeList[];
      _str includes=_default_option(VSOPTIONZ_DIR_PROJECT_INCLUDES);
      includes=strip(includes,'B',';');  // Strip leading and trailing semicolons
      split(includes, ";", includeList);

      _str folderName;
      if (length(path)>1 && !(_isWindows() && length(path)==3 && substr(path,2,1)==':')) {
         folderName= _strip_filename(substr(path,1,length(path)-1),'P');
      } else {
         folderName=path;
      }
      added_one=true;
      mou_hour_glass(true);
      message('SlickEdit is listing files');
      if (add_as_wildcard) {
         if (directory_folder) {
            _projecttbAddDirectoryToProject(true,_project_name, project_handle, -1, path, includeList, excludeList, recursive, follow_symlinks, create_subfolders);
         } else {
            _projecttbAddWildcardsToProject(true,_project_name, project_handle, -1, path, includeList, excludeList, recursive, follow_symlinks, create_subfolders);
         }
      } else {
         _projecttbAddTreeToProject(true,-1,_project_name, project_handle, path, includeList, excludeList, recursive, follow_symlinks, (is_custom_view)?create_subfolders:false);
      }
   }

   if (added_one) {
      _project_after_modify_files(_project_name,project_handle,OrigProjectFileList);
      _ProjectSave(project_handle);
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();

      mou_hour_glass(false);
      clear_message();
   }
   _project_directory_post_options();
  
   return 0;
}

/**
 * Adds a file or buffer to the current project.
 *
 * @return Returns 0 if successful.
 *
 * @param newfilename   Name of file or buffer to add to the project.
 * If "" is given, the current buffer is added to the project.
 *
 * @param newfilename
 * @param quiet       When false, messages are displayed.
 * @param ProjectName
 * @param msg         Set to status message on error. Useful when quiet=true.
 *
 * @return 0 on success, 1 if unable to add file to project (message is set to description of error),
 * 2 if file already exists in project.
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
_command int project_add_file(_str newfilename="",bool quiet=false,_str ProjectName=_project_name, _str& msg=null)
{
   msg="";

   // Check to see if project is active
   if (_project_name== '') {
      msg="No project is open";
      if (!quiet) {
         _message_box(msg,"Error",0);
      }
      return 1;
   }
   newfilename= strip(newfilename,'B','"');
   // If no filename, then get the current buffer name
   if (newfilename== '') {
      newfilename= p_buf_name;
      if (newfilename== '') {
         msg="Buffer has no name";
         if (!quiet) {
            _message_box(msg,"Error",MB_OK|MB_ICONEXCLAMATION);
         }
         return 1;
      }
   }
   newfilename=absolute(newfilename);
   FileExists := true;
   if (!file_exists(newfilename)) {
      if(buf_match(newfilename,1,'hx')=='') {
         msg=nls("File %s does not exist or has not been saved",newfilename);
         if (!quiet) {
            _message_box(msg,"Error",MB_OK|MB_ICONEXCLAMATION);
         }
         return 1;
      }
      if (_isEditorCtl(false) && _file_eq(newfilename,p_buf_name)) {
         msg = nls("File '%s' is not saved.  Save file now?", p_buf_name);
         result := _message_box(msg,"Warning",MB_YESNOCANCEL|MB_ICONEXCLAMATION);
         if ( result == IDCANCEL ) {
            return 1;
         } 
         if ( result == IDYES ) {
            save();
         } else {
            FileExists=false;
         }
      } else {
         FileExists=false;
      }
   }
   if (_FileExistsInCurrentProject(newfilename,ProjectName)) {
      msg=nls("The file %s already exists in project %s",newfilename,_project_name);
      if (!quiet) {
         _message_box(msg,0,MB_OK|MB_ICONEXCLAMATION);
      }
      return 2;
   }
   status := 0;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _str tag_filename=project_tags_filename_only(ProjectName);
   if (FileExists) {
      status=tag_add_filelist(tag_filename,_maybe_quote_filename(newfilename),ProjectName,useThread);
   }else{
      status=tag_add_new_file(tag_filename,newfilename,ProjectName,true,useThread);
   }
   if (!status) {
      // See if we need to add this file to version control
      STRARRAY fileList;
      fileList :+= newfilename;
      origParam1 := _param1;
      _MaybeAddFilesToVC(fileList);
      _param1 = origParam1;
   }
   call_list("_workspace_file_add", ProjectName, newfilename);
   //p_window_id.call_list("_prjupdate_");
   //toolbarUpdateFilterList(_project_name);
   //_TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
   //_TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   return 0;
}

int _OnUpdate_project_add_item(CMDUI &cmdui, int target_wid, _str command)
{
   if (!_haveCodeTemplates()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO_OR_STANDARD;
      }
      return MF_GRAYED|MF_REQUIRES_PRO_OR_STANDARD;
   }
   // Might make this an option at some point
   requireProject := true;
   if( requireProject && _project_name!="" && _CanWriteFileSection(_project_name,false) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command int project_add_item(_str templatePath="", _str itemName="", _str itemLocation="", bool quiet=false, _str projectName=_project_name) name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveCodeTemplates()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Merge");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int was_recording = _macro();
   // Delete recorded call to project_add_item()
   _macro_delete_line();

   // Note:
   // No need to error-check templatePath, itemName since add_item()
   // will do that for us.

   // Might make this an option at some point
   requireProject := true;
   if( requireProject && projectName=="" ) {
      if( !quiet ) {
         msg := "Missing project.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return(INVALID_ARGUMENT_RC);
   }

   if( projectName!="" ) {
      /*projectName=absolute(projectName);
      if( projectName != absolute(_project_name) ) {
         // Only support adding items to the current project for now
         if( !quiet ) {
            msg := "Only the current project can add items.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return(INVALID_ARGUMENT_RC);
      } */
      if( itemLocation=="" ) {
         itemLocation=_ProjectGet_WorkingDir(_ProjectHandle(projectName));
      }
      itemLocation=_AbsoluteToProject(itemLocation,projectName);
      // Inform the Add New Item dialog that we will be adding to the project.
      // Note that this can be overridden by the user.
   }
   int status = add_item(templatePath,itemName,itemLocation,projectName,quiet,null,null);
   if( status == 0 ) {
      // Turn macro recording back on and insert custom recorded call
      _macro('m',was_recording);
      if( projectName!='' ) {
         // Use _RelativeToProject() for item location in recorded macro, since
         // a user recording a macro to add project items would almost always
         // want it recorded so that files are added to the CURRENT project's
         // working directory. If for some reason this is not the case, then
         // they can always edit the recorded macro and change the location.
         // IMPORTANT:
         // Very important that itemLocation have a trailing FILESEP before
         // calling _RelativeToProject(). Otherwise the last name part of the
         // path is picked up as a filename, not a directory.
         _maybe_append_filesep(itemLocation);
         _macro_call("project_add_item",
                     _encode_vslickconfig(_encode_vsroot(templatePath,true,false),true,false),
                     itemName,
                     _RelativeToProject(itemLocation),
                     quiet,
                     projectName);
      } else {
         // Use relative() for item location in recorded macro, since a
         // user recording a macro to add relative to the current working directory
         // would almost always want it recorded so that files are added to
         // the current working directory. If for some reason this is not the
         // case, then they can always edit the recorded macro and change the
         // location.
         // IMPORTANT:
         // Very important that itemLocation have a trailing FILESEP before
         // calling relative(). Otherwise the last name part of the  path is
         // picked up as a filename, not a directory.
         _maybe_append_filesep(itemLocation);
         _macro_call("add_item",
                     _encode_vslickconfig(_encode_vsroot(templatePath,true,false),true,false),
                     itemName,
                     relative(itemLocation,getcwd(),false),
                     '',
                     quiet,
                     0);
      }
   }
   return status;
}

_command void project_config(_str ProjectFilename=_project_name)  name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (_DebugMaybeTerminate()) return;
   mou_hour_glass(true);
   //_convert_to_relative_project_file(ProjectFilename);
   ProjectFilename=strip(ProjectFilename,'B','"');
   gProjectFilesNotNeeded=true;
   int project_prop_wid=show('-hidden -app -xy _project_form',ProjectFilename,_ProjectHandle(ProjectFilename));
   mou_hour_glass(false);
   ctlbutton_wid := project_prop_wid._find_control('ctlconfigurations');
   typeless result=ctlbutton_wid.call_event('',ctlbutton_wid,LBUTTON_UP,'W');
   if (result=='') {
      project_prop_wid._opencancel.call_event(project_prop_wid._opencancel,LBUTTON_UP,'W');
   } else {
      project_prop_wid._ok.call_event(project_prop_wid._ok,LBUTTON_UP,'W');
   }
   gProjectFilesNotNeeded=false;
}

/**
 * Command used to show the current buffer file's position in
 * the Projects tool window.  First searches for any projects
 * that might contain the given file and asks the user to select
 * one if more than one such project exists.  Then expands the
 * project tree to show the file's position in the relevant
 * project.
 *
 * If the project tool window is not currently opened, it will
 * be opened and activated.
 *
 * @return     0 if file was successfully located in project
 *             tool window, non-zero if there was an error
 */
_command int show_file_in_projects_tb(bool quiet = def_show_all_proj_with_file) name_info(',')
{
   // get the current file name, just active the project tool window if
   // there are no files open
   filename := "";
   if (_isEditorCtl()) {
      filename = p_buf_name;
   } else if (!_no_child_windows()) {
      filename = _mdi.p_child.p_buf_name;
   }
   if (filename == "") {
      activate_project_files();
      return 1;
   }

   // look in the workspace for files with this name
   projArray := _WorkspaceFindAllProjectsWithFile(filename, _workspace_filename, true);
   if (!projArray._length()) {
      // there isn't one - return
      message('No project containing the file ' :+ filename);
      return 1;
   }

   // we ask the user what they want
   if (!quiet && projArray._length() > 1) {
      if (show('-modal _selproj_form', projArray)) {
         projArray = _param1;
      } else return 0;           // we must have cancelled the dialog...
   }

   // bring up the projects toolbar
   activate_projects();

   // find our projects tree
   tree := _tbGetActiveProjectsTreeWid();
   if (tree > 0) {

      // used to cache project dependency information
      _str AllDependencies:[];
      AllDependencies._makeempty();
      workspace_index := tree.getWorkspaceTreeRootIndex();
      tree._TreeDeselectAll();
      int i;
      for (i = 0; i < projArray._length(); i++) {
         // get the tree caption that we are looking for
         projName := projArray[i];
         projName = GetProjectDisplayName(projName);
         if (def_project_show_relative_paths) {
            projName = _RelativeToWorkspace(projName);
         }
         projCaption := _strip_filename(projName,'P') :+ "\t" :+ projName;

         // now search!
         index := tree._TreeSearch(workspace_index, projCaption, '');
         if (index < 0) {
            index = tree._TreeSearch(workspace_index, projCaption, 'T');
         }
         if (index > 0) {
            if (tree._projecttbIsProjectNode(index)
                && tree._TreeGetFirstChildIndex(index) < 0) {
               tree.toolbarBuildFilterList(tree._projecttbTreeGetCurProjectName(index), index, &AllDependencies);
               // Rebuilding the filter list for the project just expanded
               // will re-set the current index. Refocus the project node
               tree._TreeSetCurIndex(index);
            } else {
               tree._TreeSetCurIndex(index);
               tree._TreeExpandChildren(index,2);
            }
         } else {
            message('No project containing the file ' :+ filename);
            return 1;
         }

         // we are searching for a caption of this form
         caption := _strip_filename(filename, 'P') :+ "\t" :+ filename;
         if (def_project_show_relative_paths) {
            caption = _strip_filename(filename, 'P') :+ "\t" :+ _RelativeToWorkspace(filename);
         }
         index = tree._TreeSearch(index, caption, 'T');
         if (index > 0) {
            tree._TreeSetCurIndex(index);
            tree._TreeSelectLine(index);
         } else {
            message('File not found : ' :+ filename);
            return 1;
         }
      }

   } else {
      message("Could not find the project tree.");
      return 1;
   }

   // success!
   return 0;
}

/**
 * Maybe generate a makefile for the specified project.  The
 * name of the makefile will be read from the project file.  If
 * there is no name defined, it will not be generated.
 *
 * @param projectName
 *               Name of the project to generate a makefile for
 */
void _maybeGenerateMakefile(_str projectName = _project_name)
{
   int projectHandle = _ProjectHandle(projectName);

   // if there is a makefile defined in the project, update it if anything changed
   _str buildSystem = _ProjectGet_BuildSystem(projectHandle);
   _str makefile = _ProjectGet_BuildMakeFile(projectHandle);

   if(strieq(buildSystem, "automakefile") && makefile != "") {
      generate_makefile(projectName, makefile, false, false);
   }
}
static bool haveProjectFilesTab()
{
   return (_find_control("_srcfile_list") > 0);
}
static bool haveProjectDirectoriesTab()
{
   return (_find_control("ctlUserIncludesList") > 0);
}
static bool haveProjectToolsTab()
{
   return (_find_control("ctlToolTree") > 0);
}
static bool haveProjectBuildTab()
{
   return (_find_control("ctlBuildSystem") > 0);
}
static bool haveProjectCompileTab()
{
   return (_find_control("ctlCompilerList") > 0);
}
static bool haveProjectRunDebugTab()
{
   return (_find_control("ctlProgramArgs") > 0);
}
static bool haveProjectDependenciesTab()
{
   return (_find_control("ctlDepsTree") > 0);
}
static bool haveProjectOpenTab()
{
   return (_find_control("list1") > 0);
}

static void resizeProjectProperties(int &widthDiff, int &heightDiff)
{
   // border/padding constants for spacing controls
   pad := ctlconfigurations.p_y;

   widthDiff = p_width - (_proj_prop_sstab.p_x_extent);
   heightDiff = p_height - (_ok.p_y_extent + pad);

   // resizing configurations combo box and button
   ctlCurConfig.p_width += widthDiff;
   ctlconfigurations.p_x += widthDiff;

   // resize main tab control
   _proj_prop_sstab.p_width += widthDiff;
   _proj_prop_sstab.p_height += heightDiff;

   // position buttons
   _ok.p_y += heightDiff;
   _opencancel.p_y = ctlhelp.p_y = ctlfolders.p_y = _ok.p_y;
}

static void resizeFilesTab(int widthDiff, int heightDiff)
{
   if (!haveProjectFilesTab()) {
      return;
   }
   _srcfile_list.p_width += widthDiff;
   _project_nofselected.p_x += widthDiff;

   ctltagscombo.p_width += widthDiff;
   ctltagslabel.p_x += widthDiff;

   _srcfile_list.p_height += heightDiff;
   ctlimport.p_y += heightDiff;
   ctltagslabel.p_y += heightDiff;
   ctltagscombo.p_y += heightDiff;

   _add.p_x += widthDiff;
   _addtree.p_x = _invert.p_x = _remove.p_x = _remove_all.p_x = ctlrefresh.p_x =
      ctlproperties.p_x = ctlimport.p_x = _add.p_x;
}

static void resizeDirectoriesTab(int widthDiff, int heightDiff)
{
   if (!haveProjectDirectoriesTab()) {
      return;
   }
   _prjworking_dir.p_width += widthDiff;
   _browsedir1.p_x += widthDiff;
   _projworking_button.p_x += widthDiff;

   _prjref_files.p_width = _prjworking_dir.p_width;
   _browserefs.p_x = _browsedir1.p_x;
   _projref_button.p_x = _projworking_button.p_x;

   ctlHelpLabelDir.p_y += heightDiff;
   ctlHelpLabelDir.p_width += widthDiff;

   ctlUserIncludesList.p_width += widthDiff;
   ctlUserIncludesList.p_height += heightDiff;

   alignUpDownListButtons(ctlUserIncludesList.p_window_id, 
                          _proj_prop_sstab.p_child.p_width - ctlIncDirLabel.p_x,
                          ctlBrowseUserIncludes.p_window_id, 
                          ctlMoveUserIncludesUp.p_window_id, 
                          ctlMoveUserIncludesDown.p_window_id, 
                          ctlRemoveUserIncludes.p_window_id);
}
static void resizeToolsTab(int widthDiff, int heightDiff, bool toggleAppTypeVisible=false)
{
   if (!haveProjectToolsTab()) {
      return;
   }

   ctlAppTypeLabel.p_y += heightDiff;
   ctlAppType.p_y += heightDiff;
   ctlAppType.p_width += widthDiff;

   ctlHelpLabelTools.p_y += heightDiff;
   ctlHelpLabelTools.p_width += widthDiff;

   if (toggleAppTypeVisible) {
      if (ctlAppType.p_visible && ctlAppType.p_y == ctlHelpLabelTools.p_y) {
         heightDiff = -(ctlAppType.p_height + 120);
      } else if (!ctlAppType.p_visible && ctlAppType.p_y != ctlHelpLabelTools.p_y) {
         heightDiff = ctlHelpLabelTools.p_y - ctlAppType.p_y;
         ctlAppType.p_y = ctlHelpLabelTools.p_y;
      }
   }

   ctlToolHideCombo.p_y += heightDiff;
   ctlToolSaveCombo.p_y += heightDiff;
   ctlCaptureOutputFrame.p_y += heightDiff;

   ctlRunInXterm.p_y += heightDiff;
   ctlThreadDeps.p_y += heightDiff;
   ctlThreadCompiles.p_y += heightDiff;
   ctlCommandIsSlickCMacro.p_y += heightDiff;
   ctlBuildFirst.p_y += heightDiff;
   ctlMenuCaptionLabel.p_y += heightDiff;
   ctlToolMenuCaption.p_y  += heightDiff;
   ctlToolMenuCaption.p_width  += widthDiff;

   ctlRunFromDirLabel.p_y += heightDiff;
   ctlRunFromDir.p_y += heightDiff;
   ctlBrowseRunFrom.p_y += heightDiff;
   ctlRunFromButton.p_y += heightDiff;
   ctlRunFromDir.p_width  += widthDiff;
   ctlBrowseRunFrom.p_x += widthDiff;
   ctlRunFromButton.p_x += widthDiff;

   ctlcmdmessage.p_y += heightDiff;
   ctlcommand_line_label.p_y += heightDiff;
   ctlcommand_options.p_y += heightDiff;
   ctlToolCmdLine.p_y += heightDiff;
   ctlBrowseCmdLine.p_y += heightDiff;
   ctlToolCmdLineButton.p_y += heightDiff;
   ctlToolCmdLine.p_width += widthDiff;
   ctlBrowseCmdLine.p_x   += widthDiff;
   ctlToolCmdLineButton.p_x += widthDiff;

   ctlToolTree.p_width  += widthDiff;
   ctlToolTree.p_height += heightDiff;

   ctlToolNew.p_x += widthDiff;
   ctlToolAdvanced.p_x += widthDiff;

   ctlToolNew.p_width = ctlToolAdvanced.p_width = max(ctlToolNew.p_width, ctlToolAdvanced.p_width);

   ctlToolHideCombo.p_x_extent   = ctlRunFromDir.p_x_extent;
   ctlToolMenuCaption.p_x_extent = ctlRunFromDir.p_x_extent;

   tabWidth := _proj_prop_sstab.p_child.p_width;
   alignUpDownListButtons(ctlToolTree.p_window_id,
                          tabWidth - ctlToolNew.p_width - 3*label1.p_x,  
                          ctlToolUp.p_window_id, 
                          ctlToolDown.p_window_id, 
                          ctlToolDelete.p_window_id);
}
static void resizeBuildTab(int widthDiff, int heightDiff)
{
   if (!haveProjectBuildTab()) {
      return;
   }

   ctlBuildOutput.p_y += heightDiff;
   ctlBuildOutput.p_width += widthDiff;
   ctlConfigObjectDir.p_width += widthDiff;
   ctlConfigObjectDirBrowse.p_x += widthDiff;
   ctlConfigObjectDirButton.p_x += widthDiff;
   ctlConfigOutputFile.p_width += widthDiff;
   ctlConfigOutputFileBrowse.p_x += widthDiff;
   ctlConfigOutputFileButton.p_x += widthDiff;

   ctlBuildSystem.p_y += heightDiff;
   ctlBuildSystem.p_width += widthDiff;
   ctlAutoMakefile.p_width += widthDiff;
   ctlAutoMakefileButton.p_x += widthDiff;

   ctlStopOnPreErrors.p_x += widthDiff;
   ctlPreBuildCmdButton.p_x += widthDiff;
   ctlPreBuildCmdList.p_width += widthDiff;

   ctlStopOnPostErrors.p_x += widthDiff;
   ctlPostBuildCmdBtn.p_x += widthDiff;
   ctlPostBuildCmdList.p_width += widthDiff;

   half_y := heightDiff intdiv 2;
   ctlStopOnPostErrors.p_y += half_y;
   ctlPostBuildCmdBtn.p_y += half_y;
   ctlPostBuildCmdList.p_y += half_y;
   ctlPostBuildLabel.p_y += half_y;
   ctlPostBuildCmdList.p_height += half_y;
   ctlPreBuildCmdList.p_height += half_y;

   rightAlign := _proj_prop_sstab.p_child.p_width - ctlPreBuildCmdList.p_x;
   alignUpDownListButtons(ctlPreBuildCmdList.p_window_id, 
                          rightAlign, 
                          ctlMovePreCmdUp.p_window_id, 
                          ctlMovePreCmdDown.p_window_id);
   alignUpDownListButtons(ctlPostBuildCmdList.p_window_id, 
                          rightAlign, 
                          ctlMovePostCmdUp.p_window_id, 
                          ctlMovePostCmdDown.p_window_id);


}
static void resizeCompileTab(int widthDiff, int heightDiff)
{
   if (!haveProjectCompileTab()) {
      return;
   }
   ctlCompilerList.p_width += widthDiff;
   ctlcompiler_config.p_x += widthDiff;

   ctlDefinesTree.p_width += widthDiff;
   ctlDefinesTree.p_height += heightDiff;
   ctlAddDefine.p_x += widthDiff;
   ctlAddUndef.p_x += widthDiff;

   ctlLibraries.p_width += widthDiff;
   ctlLinkOrder.p_x += widthDiff;
   ctlLibrariesButton.p_x += widthDiff;

   ctlLibrariesLabel.p_y += heightDiff;
   ctlLibraries.p_y += heightDiff;
   ctlLinkOrder.p_y += heightDiff;
   ctlLibrariesButton.p_y += heightDiff;
   ctlHelpLabelCompileLink.p_y += heightDiff;

   ctlHelpLabelCompileLink.p_width += widthDiff;
}

static void resizeRunDebugTab(int widthDiff, int heightDiff)
{
   if (!haveProjectRunDebugTab()) {
      return;
   }

   ctlProgramName.p_width += widthDiff;
   ctlProgramNameBrowse.p_x += widthDiff;
   ctlProgramNameMenu.p_x += widthDiff;

   ctlProgramArgs.p_width += widthDiff;
   ctlProgramArgsBrowse.p_x += widthDiff;
   ctlProgramArgsMenu.p_x += widthDiff;

   ctlProgramDir.p_width += widthDiff;
   ctlProgramDirBrowse.p_x += widthDiff;
   ctlProgramDirMenu.p_x += widthDiff;

   ctlDebuggerFrame.p_width += widthDiff;
   ctldbgDebugger.p_width += widthDiff;
   ctldbgFindApp.p_x += widthDiff;
   ctldbgOtherDebuggerOptions.p_width += widthDiff;
   ctldbgOtherDebuggerButton.p_x += widthDiff;

   //ctlDebuggerFrame.p_height += heightDiff;
   ctlDebuggerHelpLabel.p_width += widthDiff;
   ctlDebuggerHelpLabel.p_height += heightDiff;
}

static void resizeDependenciesTab(int widthDiff, int heightDiff)
{
   if (!haveProjectDependenciesTab()) {
      return;
   }
   ctlDepsTree.p_width += widthDiff;
   ctlDepsTree.p_height += heightDiff;
}
static void resizeOpenTab(int widthDiff, int heightDiff)
{
   if (!haveProjectOpenTab()) {
      return;
   }
   list1.p_width += widthDiff;
   list1.p_height += heightDiff;

   ctlHelpLabelOpenCmd.p_width += widthDiff;
   ctlHelpLabelOpenCmd.p_y += heightDiff;
}
void _project_form.on_resize()
{
   resizeProjectProperties(auto widthDiff, auto heightDiff);
   resizeFilesTab(widthDiff, heightDiff);
   resizeDirectoriesTab(widthDiff, heightDiff);
   resizeRunDebugTab(widthDiff, heightDiff);

   if (_haveBuild()) {
      resizeToolsTab(widthDiff, heightDiff);
      resizeBuildTab(widthDiff, heightDiff);
      resizeCompileTab(widthDiff, heightDiff);
      resizeDependenciesTab(widthDiff, heightDiff);
      resizeOpenTab(widthDiff, heightDiff);
   }
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _project_form_initial_alignment()
{
   tabWidth := _proj_prop_sstab.p_child.p_width;

   pad_x := ctlIncDirLabel.p_x;
   pad_y := ctlconfigurations.p_y;

   // directories tab
   rightAlign := tabWidth - pad_x;
   sizeBrowseButtonToTextBox(_prjworking_dir.p_window_id, _browsedir1.p_window_id, _projworking_button.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(_prjref_files.p_window_id, _browserefs.p_window_id, _projref_button.p_window_id, rightAlign);
   ctlHelpLabelDir.p_x_extent = rightAlign ;

   // tools tab
   rightAlign = ctlToolAdvanced.p_x_extent;
   sizeBrowseButtonToTextBox(ctlToolCmdLine.p_window_id, ctlBrowseCmdLine.p_window_id, ctlToolCmdLineButton.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlRunFromDir.p_window_id, ctlBrowseRunFrom.p_window_id, ctlRunFromButton.p_window_id, rightAlign);
   ctlToolMenuCaption.p_width = (ctlRunFromDir.p_x_extent) - ctlToolMenuCaption.p_x;
   ctlHelpLabelTools.p_width = rightAlign - ctlHelpLabelDir.p_x;

   // build tab
   sizeBrowseButtonToTextBox(ctlConfigObjectDir.p_window_id, ctlConfigObjectDirBrowse.p_window_id, ctlConfigObjectDirButton.p_window_id);
   sizeBrowseButtonToTextBox(ctlConfigOutputFile.p_window_id, ctlConfigOutputFileBrowse.p_window_id, ctlConfigOutputFileButton.p_window_id);
   sizeBrowseButtonToTextBox(ctlAutoMakefile.p_window_id, ctlAutoMakefileButton.p_window_id);
   rightAlign = tabWidth - pad_x;
   ctlBuildSystem.p_x_extent = rightAlign ;
   //ctlBuildSystem.p_x_extent = rightAlign;
   ctlMakeJobs.p_x = ctlThreadMake.p_x_extent + 150;
   ctlMakeJobsSpinner.p_y = ctlMakeJobs.p_y;
   ctlMakeJobsSpinner.p_height = ctlMakeJobs.p_height;
   ctlMakeJobsSpinner.p_x = ctlMakeJobs.p_x_extent;

   // compile/link tab
   sizeBrowseButtonToTextBox(ctlCompilerList.p_window_id, ctlcompiler_config.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlLibraries.p_window_id, ctlLinkOrder.p_window_id, ctlLibrariesButton.p_window_id, rightAlign);

   alignUpDownListButtons(ctlDefinesTree.p_window_id, 
                          rightAlign, 
                          ctlAddDefine.p_window_id, 
                          ctlAddUndef.p_window_id);
   if (ctlAddDefine.p_width > ctlAddUndef.p_width) {
      ctlAddUndef.p_width = ctlAddDefine.p_width;
   } else {
      ctlAddDefine.p_width = ctlAddUndef.p_width;
   }

   ctlHelpLabelCompileLink.p_x_extent = rightAlign ;

   // run/debug tab
   sizeBrowseButtonToTextBox(ctlProgramName.p_window_id,  ctlProgramNameBrowse.p_window_id, ctlProgramNameMenu.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlProgramArgs.p_window_id, ctlProgramArgsBrowse.p_window_id,  ctlProgramArgsMenu.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlProgramDir.p_window_id,  ctlProgramDirBrowse.p_window_id, ctlProgramDirMenu.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctldbgDebugger.p_window_id, ctldbgFindApp.p_window_id, 0, rightAlign-300);
   sizeBrowseButtonToTextBox(ctldbgOtherDebuggerOptions.p_window_id, ctldbgOtherDebuggerButton.p_window_id, 0, rightAlign-300);

   // make sure the form is big enough
   minWidth := ctlfolders.p_x_extent + _ok.p_width + 450;
   minHeight := ctlBuildSystem.p_height*3;
   p_active_form._set_minimum_size(minWidth, minHeight);
}

int ProjectFormProjectHandle()
{
   return gProjectHandle;
}
_str ProjectFormProjectName()
{
   return gProjectName;
}

