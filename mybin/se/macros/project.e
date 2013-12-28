////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50062 $
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
#import "mprompt.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projmake.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "recmacro.e"
#import "refactor.e"
#import "refactorgui.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "tagform.e"
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
#endregion

// Track add, remove, and refresh files instead of just checking modify
static boolean gFileListModified;

static _str gDialog;
static _str gSetActiveConfigTo;

 static _str gProjectName;
 static int gProjectHandle;
 static boolean gdoSaveIfNecessary;
 static boolean gMakeCopyFirst;
 static boolean gIsProjectTemplate;
 static _str gConfigName;
 static _str gConfigList[];
 static boolean gChangingConfiguration;
 static _str gAssociatedFile;
 static _str gAssociatedFileType;
 static _str gInitialTargetName;
 static _str gInitialBuildSystem;
 static _str gInitialBuildMakeFile;
 static boolean gLeaveFileTabEnabled;

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

#define PROJECTTREEADJUSTCOLUMNWIDTH 2600

#define JAVA_OPTS_DLG_DEF "_java_options_form Compiler"
#define GNUC_OPTS_DLG_DEF "_gnuc_options_form Compile"
#define VCPP_OPTS_DLG_DEF "_vcpp_options_form Compile"

static boolean gIsExtensionProject;
static boolean gUpdateTags;
static boolean gProjectFilesNotNeeded;
static boolean ignore_config_change;

// If 1, ignore on_change events to _openfile_list:
static int gProjectIgnoreOnChange= 0;

// default to not showing files in project in open dialog
int def_show_prjfiles_in_open_dlg=0;

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
boolean def_workspace_open_runs_all_macros=false;

static PROJECT_CONFIG_INFO gAllConfigsInfo;

_control _prjref_files;
_control ctlUserIncludesList;
_control ctlToolTree;

#define MIN_SPACE_BEFORE_PATH 200

static int gOrigProjectFileList;

#define MESSAGE_ALLCONFIG_TOOLS_MISMATCH "Select a configuration to view this command"
#define MESSAGE_PRESS_OPTIONS_BUTTON "<- Press Options button to view settings for this command"
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
   "vcppoptions"=>"Displays dialog for setting options for Visual C++ Toolkit 2003",
   "phpoptions"=>"Displays dialog for setting options for PHP tools",
   "pythonoptions"=>"Displays dialog for setting options for Python tools"
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
      _MaybeRetagWorkspace(1,0);
      // Just in case project files were modified
      toolbarUpdateFilterList(_project_name);
   } else if (_workspace_filename!='') {
      toolbarUpdateFilterList(_project_name);
   }
}

static void adjust_filespec(_str &vslickpathfilename)
{
#if !__UNIX__
   _str comspec=get_env("COMSPEC")" /c";
   if (file_eq(substr(vslickpathfilename,1,length(comspec)),comspec)) {
      vslickpathfilename=strip(substr(vslickpathfilename,length(comspec)+1));
      if (file_exists(vslickpathfilename".bat")) {
         vslickpathfilename=vslickpathfilename".bat";
         return;
      }
      if (file_exists(vslickpathfilename".cmd")) {
         vslickpathfilename=vslickpathfilename".cmd";
         return;
      }
   }
#endif
}
int _OnUpdate_project_edit(CMDUI &cmdui,int target_wid,_str command)
{
   if (_project_name=='') {
      if (_no_child_windows()) {
         return(MF_GRAYED);
      }
      return(MF_ENABLED);
   }
   return(MF_ENABLED);
}

static void project_edit2(_str activetab="",_str ProjectFilename=_project_name)
{
   //_macro_delete_line();

   // No global project name==> No project opened!
   if (ProjectFilename=='') {
      int editorctl_wid=p_window_id;
      if (!_isEditorCtl()) {
         if (_no_child_windows()) {
            _message_box(nls("There must be a window to set up extension specific project information."));
            return;
         }
         editorctl_wid=_mdi.p_child;
      }
      show('-mdi -modal -xy _project_form','.'editorctl_wid.p_LangId,gProjectExtHandle);
      return;
   }
   mou_hour_glass(1);
   //_convert_to_relative_project_file(_project_name);
   typeless result=show('-mdi -modal -xy _project_form',ProjectFilename,_ProjectHandle(ProjectFilename),activetab);
   mou_hour_glass(0);
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
boolean projectFilesNotNeeded(int value=-1)
{
   boolean old_value = gProjectFilesNotNeeded;
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
_command void project_edit(_str activetab="") name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   _str ProjectFilename='';
   gProjectFilesNotNeeded=false;
   parse activetab with activetab ProjectFilename;

   // if no project name was specified and this was triggered from
   // the project toolbar, infer the project name from the tree
   if (ProjectFilename == "" && p_name==PROJECT_TOOLBAR_NAME) {
      ProjectFilename=_projecttbTreeGetCurProjectName(-1,true);
      _str olddir=getcwd();
      chdir(_strip_filename(ProjectFilename,'N'),1);
      project_edit2(activetab,ProjectFilename);
      chdir(olddir,1);
      return;
   }
   if (file_exists(ProjectFilename)) {
      project_edit2(activetab,ProjectFilename);
   } else {
      project_edit2(activetab);
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
            if (file_eq(setPath[i], curPath[j])) {
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

static void _project_run_macro2(_str project_name=_project_name, boolean (&been_there_done_that):[]=null)
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
   _str targetName = "";
   int index = ctlToolTree._TreeCurIndex();
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
   int index = ctlToolTree._TreeCurIndex();
   if(index < 0) return -1;

   if(config == "") {
      config = GetConfigText();
   }

   int node = -1;

   // get parent target name and rule input exts
   _str caption = ctlToolTree._TreeGetCaption(index);

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
      return('');
   }
   if (file_eq(ProjectName,_project_name) && gActiveConfigName!='') {
      return(gActiveConfigName);
   }
   _str ConfigName='';
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

   boolean been_there_done_that:[];
   for (i := 0; i < projectFiles._length(); i++) {
      _str ProjectName = _AbsoluteToWorkspace(projectFiles[i]);
      _project_run_macro2(ProjectName, been_there_done_that);
   }
}

void _prjopen_run_macros()
{
   boolean been_there_done_that:[];
   _project_run_macro2(_project_name, been_there_done_that);
}

//void _prjconfig_run_macros()
//{
//   boolean been_there_done_that:[];
//   _project_run_macro2(_project_name, been_there_done_that);
//}

void _ProjectTemplateExpand(int templates_handle,int project_handle,boolean doSetAppType=false,boolean AddDefaultFilters=false)
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
                           boolean ShowPropertiesDialog=true,
                           boolean SetWorkingDir=false,
                           _str AssociatedMakefile='',
                           _str AssociatedMakefileType='',
                           boolean RetagWorkspaceFiles=true,
                           ProjectConfig ConfigList[]=null,
                           boolean RemoveDirectoryIfCancelled=false,
                           boolean RemoveWorkspaceFileIfCancelled=false)
{
   if (WorkspaceName=='') {
      WorkspaceName=_workspace_filename;
   }
   if (WorkspaceName=='') {
      _message_box('WorkspaceName must be specified');
      return(1);
   }
   boolean operatingOnActiveWorkspace=_workspace_filename!='' && file_eq(_workspace_filename,WorkspaceName);
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
   _str new_project_name=absolute(strip(result));

   // Create the project tag file
   _str project_tag_filename=_strip_filename(new_project_name,'E'):+TAG_FILE_EXT;
   //tag_close_db(project_tag_filename);
   //tag_create_db(project_tag_filename);
   //tag_close_db(project_tag_filename);
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   // Init the default project properties and show the properties form:
   //name=slick_path_search(VSCFGFILE_PRJTEMPLATES);

   _str initmacro='';
   int project_handle=_ProjectCreateFromTemplate(new_project_name,CompilerName,initmacro,true,!_IsWorkspaceAssociated(WorkspaceName));

   int ReleaseNode=_ProjectGet_ConfigNode(project_handle,'Release');
   // This is only supported for Visual C++ and Tornado
   int Node=0;
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

   // Set active config
   _str value='';
   _str list[];
   _ProjectGet_ConfigNames(project_handle,list);
   //Make the first configuration active
   _ini_set_value(VSEWorkspaceStateFilename(WorkspaceName), "ActiveConfig",
                 _RelativeToWorkspace(new_project_name,WorkspaceName),','list[0],_fpos_case);

   // Replace %<e with executable name
   {
      typeless array[];
      _xmlcfg_find_simple_array(project_handle,VPJX_MENU"//"VPJTAG_EXEC"/@CmdLine[contains(.,'%<e')]",array);
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
      _str makefilename=relative(AssociatedMakefile,_strip_filename(new_project_name,'N'));

      _ProjectSet_AssociatedFile(project_handle,makefilename);
      if (AssociatedMakefileType!='') {
        _ProjectSet_AssociatedFileType(project_handle,AssociatedMakefileType);
        if (AssociatedMakefileType==XCODE_PROJECT_VENDOR_NAME) {
            // This is actually set to the .xcode or .xcodeproj bundle directory
           _str bundleRelative = _strip_filename(AssociatedMakefile,'P');
           _ProjectSet_AssociatedFile(project_handle,bundleRelative);
        }
      }

      boolean is_standard_vcproj=_IsVisualStudioWorkspaceFilename(WorkspaceName) &&
                                 (GetVSStandardAppName(_get_extension(makefilename,true)):!='');
      if (is_standard_vcproj) {
         Node=_ProjectGet_FilesNode(project_handle,true);
         _str AutoFolders=_xmlcfg_get_attribute(project_handle,Node,'AutoFolders');
         if (AutoFolders==VPJ_AUTOFOLDERS_CUSTOMVIEW) {
            _xmlcfg_set_attribute(project_handle,Node,'AutoFolders',VPJ_AUTOFOLDERS_DIRECTORYVIEW);
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

   _str vPrjFileName=_strip_filename(_xmlcfg_get_filename(project_handle),'N'):+_xmlcfg_get_attribute(project_handle,_xmlcfg_find_simple(project_handle,'Project'),'AssociatedFile');
   _str compilerConfigName=determineCompilerConfigName(compilers,project_handle,vPrjFileName);
   _str nodes[];
   nodes._makeempty();
   _xmlcfg_find_simple_array(project_handle,'/Project/Config',nodes);

   typeless cfgIndex;
   _str configName='';
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
      int orig_view_id=p_window_id;
      status=_ini_get_section(new_project_name,"FILES",files_view_id);
      if (status) {
         orig_view_id=_create_temp_view(files_view_id);
         p_window_id=orig_view_id;
      }
      p_window_id=files_view_id;
      for (;;) {
         parse sourcewildcards with cur (PATHSEP) sourcewildcards;
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
         #if !__UNIX__
            _flash_create_default_build_scripts(AssociatedMakefile);
         #endif
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
      workspace_insert(new_project_name,0,1,RetagWorkspaceFiles);
      //_TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
      //_TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

      //readAndParseProjectToolList_ForAllConfigs(); already did this in workspace_insert
      if (ShowPropertiesDialog) {
         result=show('-modal -mdi -xy _project_form',new_project_name,_ProjectHandle(new_project_name),PROJPROPTAB_FILES);
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
   if (initmacro!='') {
      if (!operatingOnActiveWorkspace) {
         _message_box('The InitMacro may only be invoked on the active workspace');
         return(1);
      }
      int index=find_index(initmacro,PROC_TYPE|COMMAND_TYPE);
      if (index) {
         status=call_index(configName,index);
         if (!status) {
            _menu_add_workspace_hist(WorkspaceName);
         }else{
            CloseAndDeleteNewWorkspace(RemoveDirectoryIfCancelled,RemoveWorkspaceFileIfCancelled);
         }
      }
   } else {
      _menu_add_workspace_hist(WorkspaceName);
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
static int CloseAndDeleteNewWorkspace(boolean RemoveDirectory,boolean RemoveWorkspaceFile)
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
      status=delete_file(_strip_filename(workspaceFilename,'E')TAG_FILE_EXT);
      delete_file(_strip_filename(workspaceFilename,'E')WORKSPACE_STATE_FILE_EXT);
   }

   if (RemoveDirectory) {
      _str curPath=getcwd();
      if (last_char(curPath)!=FILESEP) curPath=curPath:+FILESEP;
      if (file_eq(curPath,_file_path(projectFilename))) {
         //Back up one directory, and then call rmdir.  If there are files in the
         //directory rmdir will fail, and that is fine.
         cd('..');
      }
      status=rmdir(_file_path(projectFilename));
   }
   return(status);
}
defeventtab _project_form;
void ctlBrowseRunFrom.lbutton_up()
{
   int wid=p_window_id;

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

   int wid2=p_prev;
   //ctlinsert(result);
   ctlRunFromDir.p_text = result;
   if (wid2) {
      wid2._set_focus();
   }

   // turn on autoselect on the textbox
   wid.p_prev.p_auto_select = 1;
}
void ctlBrowseCmdLine.lbutton_up()
{
   int wid=p_window_id;

   // turn off autoselect on the textbox
   wid.p_prev.p_auto_select = 0;

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
   wid.p_prev.p_auto_select = 1;
}
void ctlproperties.lbutton_up()
{
   _str RelFilename=_srcfile_list._lbget_text();
   int Node=_ProjectGet_FileNode(gProjectHandle,RelFilename);

   WILDCARD_FILE_ATTRIBUTES f;

   f.Recurse=_xmlcfg_get_attribute(gProjectHandle,Node,'Recurse',0);
   f.Excludes=translate(_xmlcfg_get_attribute(gProjectHandle,Node,'Excludes'), FILESEP, FILESEP2);

   filename := _AbsoluteToProject(RelFilename, gProjectName);
   result :=  modify_wildcard_properties(filename, f);
   if (result) {
      return;
   }

   if (f.Recurse) {
      _xmlcfg_set_attribute(gProjectHandle,Node,'Recurse',f.Recurse);
   } else {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'Recurse');
   }
   if (f.Excludes!='') {
      _xmlcfg_set_attribute(gProjectHandle,Node,'Excludes',_NormalizeFile(f.Excludes));
   } else {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'Excludes');
   }

   gFileListModified=1;
}
void ctlStopOnPreErrors.lbutton_up()
{
   //if (CHANGING_CONFIGURATION==1 || !p_active_form.p_visible) return;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
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

static boolean isItemBold(int index)
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
   int wid = p_window_id;
   p_window_id = wid.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
   if( (index > 0) && (!isItemBold(index)) ) {
      // handle special cases where this is the new entry node or the prev
      // node is the new entry node
      int prevIndex = _TreeGetPrevSiblingIndex(index);
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
   int wid = p_window_id;
   p_window_id = wid.p_prev.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
   if( (index > 0) && (!isItemBold(index)) ) {
      // handle special cases where this is the new entry node or the next node
      // is the new entry node
      int nextIndex = _TreeGetNextSiblingIndex(index);
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

   // can not editor compiler include path directories
   if(reason == CHANGE_EDIT_QUERY && isItemBold(index) &&
      !strieq(arg(4), BLANK_TREE_NODE_MSG)) {
      return -1;
   }

   if(reason == CHANGE_EDIT_OPEN) {
      // if this is the new entry node, clear the message
      if(strieq(arg(4), BLANK_TREE_NODE_MSG)) {
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
      _str caption = _TreeGetCaption(index);
      boolean wasNewEntryNode = strieq(caption, BLANK_TREE_NODE_MSG);

      // HS2-CHG: or if nth. was changed (e.g. by double clicking around
      // if the node changed and is now empty, delete it
      if( (arg(4) == "") || strieq(arg(4), BLANK_TREE_NODE_MSG)) {
         if(wasNewEntryNode) {
            arg(4) = BLANK_TREE_NODE_MSG;
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
         int newIndex = _TreeAddListItem(BLANK_TREE_NODE_MSG);
         _TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);

      }
   }

   if (p_name:=='ctlDefinesTree') {
      // the processing for the defines list is a bit more complicated than the others
      UpdateProjectDefines();
   } else if (p_name == 'ctlUserIncludesList') {
      UpdateProjectIncludes();
   } else if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
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

   return 0;
}
void ctlUserIncludesList.'DEL'()
{
   deleteUserInclude();
}

static void deleteUserInclude()
{
   // with single node selection, if there is a current index, it is selected
   int index = _TreeCurIndex();
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
   _str ch1=substr(define,1,1);
   _str ch2=upcase(substr(define,2,1));

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
      int equ_pos=0;
      int spc_pos=0;
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

static boolean isMacroInList(_str check_define,_str list)
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
   _str name='';
   parse substr(check_define,3) with name '=' . ;

   _str dname='';
   _str orig_list=list;
   list='';

   while (orig_list!='') {
      _str define = parse_next_option(orig_list,false);
      parse substr(define,3) with dname '=' . ;
      if (dname!=name) {
         if (list!='') {
            strappend(list,' ');
         }
         strappend(list,maybe_quote_filename(define));
      }
   }
}

static struct defchange {
   boolean added;
   _str define;
};

static _str fully_quote(_str input)
{
   _str output='';
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

   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      gAllConfigsInfo.Includes = _TreeGetDelimitedItemList(PATHSEP);
      for (i:=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
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

   _str defines='';
   boolean hasDoubleClickLine=false;

   // form a single string for the defines, all properly formatted
   if (_TreeGetNumChildren(TREE_ROOT_INDEX)>0) {
      int index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for (;index>=0;) {
         _str someDefine=_TreeGetCaption(index);
         if (someDefine:==BLANK_TREE_NODE_MSG) {
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

   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      if (defines!=gAllConfigsInfo.Defines) {
         // they changed something, figure out what
         defchange changes[];
         _str orig=gAllConfigsInfo.Defines;
         _str updated=defines;
         _str define='';
         int next_change=0;

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
         int i,j;
         for (i=0;i<gConfigList._length();++i) {
            _str config=gConfigList[i];
            defines=fully_quote(_ProjectGet_Defines(gProjectHandle,config));
            for (j=0;j<changes._length();++j) {
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
                  _str full_define='"'changes[j].define'"';
                  // if it is the first one
                  if (substr(defines,1,length(full_define))==full_define) {
                     // remove it and potentially a trailing space
                     defines=substr(defines,length(full_define)+2);
                  } else {
                     // remove it from the middle with the preceding space
                     _str trailing='';
                     parse defines with defines (' 'full_define) trailing;
                     strappend(defines,trailing);
                  }
               }
            }
            _ProjectSet_Defines(gProjectHandle,defines,config);
         }
      }
   } else {
      _ProjectSet_Defines(gProjectHandle,defines,ctlCurConfig.p_text);
   }

   // if this just replaced the <double click here line, replace it
   if (!hasDoubleClickLine && p_window_id.p_enabled) {
      int newIndex = _TreeAddListItem(BLANK_TREE_NODE_MSG);
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

   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      _str TargetName=GetTargetName();
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
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
   _str macro=strip(_param1);

   _str first_char=substr(macro,1,1);
   if ((first_char!='/')&&(first_char!='-')) {
      macro=prefix:+macro;
   }
   ctlDefinesTree._TreeBottom();
   int lastIndex=ctlDefinesTree._TreeCurIndex(); // get the index of the <double click... line
   ctlDefinesTree._TreeAddItem(lastIndex,macro,TREE_ADD_BEFORE);
   ctlDefinesTree._TreeUp(); // select the newly added item

   ctlDefinesTree.UpdateProjectDefines();
}

void ctlcompiler_config.lbutton_up()
{
   boolean wasLatest=false;
   boolean wasDefault=false;

   int handle = _ProjectHandle();
   _str config = '';
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   _str project_type = _ProjectGet_Type(handle, config );

   _str temp_config=ctlCompilerList.p_text;
   _str result='';
   if (project_type :== "java") {
      if (substr(temp_config,1,length(COMPILER_NAME_LATEST)):==COMPILER_NAME_LATEST) {
         wasLatest=true;
         parse temp_config with . '(' temp_config ')';
      } else if (substr(temp_config,1,length(COMPILER_NAME_DEFAULT)):==COMPILER_NAME_DEFAULT) {
         wasDefault=true;
         parse temp_config with . '(' temp_config ')';
      }
      int orig_wid = p_window_id;
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
      int orig_wid = p_window_id;
      int wid = show("-xy _refactor_c_compiler_properties_form");
      wid._refactor_set_config(temp_config);
      result = _modal_wait(wid);
      p_window_id = orig_wid;
   }

   // repopulate the entire list as anything could have happend
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

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
   int wid=p_window_id;
  _control ctlToolDown;

  int status=0;
   if (wid==ctlToolUp) {
      status = ctlToolTree._TreeMoveUp(ctlToolTree._TreeCurIndex());

   }else if (wid==ctlToolDown) {
      status = ctlToolTree._TreeMoveDown(ctlToolTree._TreeCurIndex());
   }
   p_window_id=wid;

   int i;
   int PrevNode=0;
   int NextNode=0;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
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
   project_tool_wizard(gProjectHandle, gIsExtensionProject ? gConfigName : '', false);
   ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');

// // Prompt the user for a new tool name:
// _str result;
// result= show('-modal _textbox_form',
//               'New Project Tool',             //Captions
//               0,                              //Flags
//               2000,                           //use default textbox width
//               '?Type a name for the new tool and press ENTER to add the tool.',   //Help item
//               '',                             //Buttons and captions
//               '',                //Retrieve Name
//               'New Tool Name:'//Prompt
//              );
// //_param1= '' if someone presses ok on an empty box
// if (result== '' || _param1== '') {
//    return;
// }
// //messageNwait("_param1="_param1);
// _str name;
// name= _param1;
// name= strip(name);  // strip any leading and trailing spaces
//
// // Make sure that there are no colons or commas in tool name:
// if (pos(":",name) || pos(",",name)) {
//    _message_box(nls("Tool name cannot contain ':' (colon) or ',' (comma)."));
//    return;
// }
//
// int status = ctlToolTree._TreeSearch(TREE_ROOT_INDEX, name, "I");
// if(status >= 0) {
//    _message_box(nls("Tool '%s' already exists in project.",name));
//    return;
// }
//
// // create new tool and select it
// int index = ctlToolTree._TreeAddItem(TREE_ROOT_INDEX, name, TREE_ADD_AS_CHILD, 0, 0, -1);
//
// if (ctlCurConfig.p_text==ALL_CONFIGS) {
//    int i;
//    for (i=0;i<gConfigList._length();++i) {
//       _str config=gConfigList[i];
//       _ProjectAddTool(gProjectHandle,name,config);
//    }
//    ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
//
//    // The on_change event is going to delete and re-create the list, so we
//    // can not simply set the old index to current.  Do a search and see if we
//    // can find the name in the list
//    int wid=p_window_id;
//    p_window_id=ctlToolTree;
//    int newindex=_TreeSearch(TREE_ROOT_INDEX,name);
//    if (newindex) {
//       _TreeSetCurIndex(newindex);
//    }
//    p_window_id=wid;
// } else {
//    _ProjectAddTool(gProjectHandle,name,GetConfigText());
//    ctlToolTree._TreeSetCurIndex(index);
//
//    //ctlToolTree.call_event(CHANGE_SELECTED,index,ctlToolTree,ON_CHANGE,'W');
// }
}
void ctlToolVerbose.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];


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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];


         _ProjectSet_TargetBeep(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].Beep=p_value;
      }
      return;
   }
   _ProjectSet_TargetBeep(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
}
void ctlBuildFirst.lbutton_up()
{
#if __UNIX__
   if (ctlBuildFirst.p_value && ctlRunInXterm.p_value) {
      _str TargetName=GetTargetName();
      if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
         ctlRunInXterm.p_value=0;
         ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
      }
   }
#endif
   p_style=PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

         _ProjectSet_TargetClearProcessBuffer(gProjectHandle, GetTargetOrRuleNode(config), p_value!=0);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].ClearProcessBuffer=p_value;
      }
   } else {
      _ProjectSet_TargetClearProcessBuffer(gProjectHandle, GetTargetOrRuleNode(), p_value!=0);
   }
}
#if __UNIX__
void ctlRunInXterm.lbutton_up()
{
   if (ctlBuildFirst.p_value && ctlRunInXterm.p_value) {
      _str TargetName=GetTargetName();
      if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
         ctlBuildFirst.p_value=0;
         ctlBuildFirst.call_event(ctlBuildFirst,LBUTTON_UP,'W');
      }
   }
   p_style=PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

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
static boolean captureOutputRequiresConcurrentProcess(_str TargetName,_str cmd)
{
   if (strieq(TargetName,'debug') && _project_DebugCallbackName!='') {
      int index=find_index('_'_project_DebugCallbackName'_DebugCommandCaptureOutputRequiresConcurrentProcess',PROC_TYPE);
      if (index) {
         boolean requireConcurrent=call_index(cmd,index);
         if (!requireConcurrent) {
            return(false);
         }
      }
      return(true);
   }
   return(false);
}
static _str GetCaptureOutputWith()
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
   _str TargetName=GetTargetName();
   _str CmdLine='';
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
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
#if __UNIX__
      //ctlRunInXterm.p_value=0;
      ctlRunInXterm.p_enabled= true;
      //ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
#endif
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
#if __UNIX__
      //ctlRunInXterm.p_value=0;
      //ctlRunInXterm.p_enabled= false;
      ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
#endif
      //If ctlToolOutputToConcur.p_value is false, this is supposed to be disabled - DWH
   }
   if (p_value!=ctlBuildFirst.p_value && ctlBuildFirst.p_value) {
      ctlBuildFirst.p_value=p_value;
      ctlBuildFirst.call_event(ctlBuildFirst,LBUTTON_UP,'W');
   }

   _str CaptureOutputWith=GetCaptureOutputWith();
   //p_style=PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

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

   _str CaptureOutputWith=GetCaptureOutputWith();
   //p_style=PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

         _ProjectSet_TargetMenuCaption(gProjectHandle, GetTargetOrRuleNode(config), p_text);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].MenuCaption=p_text;
      }
   } else {
      _ProjectSet_TargetMenuCaption(gProjectHandle, GetTargetOrRuleNode(), ctlToolMenuCaption.p_text);
   }
}

void ctlToolAdvanced.lbutton_up()
{
   _str config_to_use=ctlCurConfig.p_text;
   if (config_to_use:==ALL_CONFIGS) {
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

   if (ctlCurConfig.p_text:==ALL_CONFIGS) {
      int config_index;
      for (config_index=0;config_index<gConfigList._length();++config_index) {
         _ProjectSet_TargetAdvCmd(gProjectHandle,GetTargetOrRuleNode(gConfigList[config_index]),cmds);
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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

         _ProjectSet_TargetCmdLine(gProjectHandle, GetTargetOrRuleNode(config), p_text);
         gAllConfigsInfo.TargetInfo:[GetTargetName()].Exec_CmdLine=p_text;
      }
      _str TargetName=GetTargetName();
      gAllConfigsInfo.TargetInfo:[lowcase(TargetName)].Exec_CmdLine=p_text;
   } else {
      _ProjectSet_TargetCmdLine(gProjectHandle, GetTargetOrRuleNode(), p_text);
   }
   //updateShowOnMenuOptions(gProjectInfo2.ProjectSettings:[GetConfigText()].ToolInfo[toolIndex].hideOptions);
}

void ctlRunFromDir.on_change()
{
   if (gChangingConfiguration==1) return;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      // So not save "Run From Dir" setting for all configs if it is not set.
      if (p_text != "" || gAllConfigsInfo.TargetInfo:[GetTargetName()].RunFromDir != null) {
         int i;
         for (i=0;i<gConfigList._length();++i) {
            _str config=gConfigList[i];

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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

         _ProjectSet_DisplayLibsList(gProjectHandle, config, p_text);
      }
      gAllConfigsInfo.Libs=p_text;
   } else {
      _ProjectSet_DisplayLibsList(gProjectHandle, ctlCurConfig.p_text, p_text);
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
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];
         node := GetTargetOrRuleNode(config);

         _ProjectSet_TargetType(gProjectHandle, node, (p_value)?'Slick-C':'');
         if (p_value) {
            _ProjectSet_TargetCaptureOutputWith(gProjectHandle, node, '');
            gAllConfigsInfo.TargetInfo:[target].CaptureOutputWith='';
            _ProjectSet_TargetClearProcessBuffer(gProjectHandle, node, 0);
            gAllConfigsInfo.TargetInfo:[target].ClearProcessBuffer=0;
            _ProjectSet_TargetBuildFirst(gProjectHandle, node, 0);
            gAllConfigsInfo.TargetInfo:[target].BuildFirst=0;
            _ProjectSet_TargetVerbose(gProjectHandle, node, 0);
            gAllConfigsInfo.TargetInfo:[target].Verbose=0;
            _ProjectSet_TargetBeep(gProjectHandle, node, 0);
            gAllConfigsInfo.TargetInfo:[target].Beep=0;

            // if the target is 'build', then we must also loop thru all targets in
            // this config, disabling buildfirst because buildfirst is not allowed when
            // the build target is a slickc macro
            if(strieq(target, "build")) {
               _str targetNodeList[] = null;
               _ProjectGet_Targets(gProjectHandle, targetNodeList, config);
               int k;
               for(k = 0; k < targetNodeList._length(); k++) {
                  _ProjectSet_TargetBuildFirst(gProjectHandle, (int)targetNodeList[k], 0);
               }
            }
         }
      }

   } else {
      node := GetTargetOrRuleNode();
      _ProjectSet_TargetType(gProjectHandle, node, (p_value)?'Slick-C':'');
      if (p_value) {
         _ProjectSet_TargetCaptureOutputWith(gProjectHandle, node, '');
         _ProjectSet_TargetClearProcessBuffer(gProjectHandle, node, 0);
         _ProjectSet_TargetBuildFirst(gProjectHandle, node, 0);
         _ProjectSet_TargetVerbose(gProjectHandle, node, 0);
         _ProjectSet_TargetBeep(gProjectHandle, node, 0);

         // if the target is 'build', then we must also loop thru all targets in
         // this config, disabling buildfirst because buildfirst is not allowed when
         // the build target is a slickc macro
         if(strieq(target, "build")) {
            _str config=GetConfigText();
            _str targetNodeList[] = null;
            _ProjectGet_Targets(gProjectHandle, targetNodeList, config);
            int k;
            for(k = 0; k < targetNodeList._length(); k++) {
               _ProjectSet_TargetBuildFirst(gProjectHandle, (int)targetNodeList[k], 0);
            }
         }
      }
   }

   if (p_value) {
      ctlToolCaptureOutput.p_enabled=0;
      ctlToolOutputToConcur.p_enabled=0;
      ctlToolClearProcessBuf.p_enabled=0;
      ctlBuildFirst.p_enabled=0;
      ctlToolVerbose.p_enabled=0;
      ctlToolBeep.p_enabled=0;

      ctlToolCaptureOutput.p_value = 0;
      ctlToolOutputToConcur.p_value = 0;
      ctlToolClearProcessBuf.p_value = 0;
      ctlBuildFirst.p_value=0;
      ctlToolVerbose.p_value=0;
      ctlToolBeep.p_value=0;
   }else{
      ctlToolCaptureOutput.p_enabled=1;

      if (strieq(target,'build') || strieq(target,'rebuild') ) {
         ctlToolVerbose.p_enabled=1;
         ctlToolBeep.p_enabled=1;
      } else {
         ctlToolVerbose.p_value=0;
         ctlToolVerbose.p_enabled=0;
         ctlToolBeep.p_value=0;
         ctlToolBeep.p_enabled=0;
      }

      switch (lowcase(target)) {
         case "build":
         case "rebuild":
         case "compile":
         case "link":
            ctlBuildFirst.p_enabled = 0;
            ctlBuildFirst.p_value = 0;
            break;
         default:
            ctlBuildFirst.p_enabled = 1;
      }
   }

}
void ctlCompilerList.on_change(int reason)
{
   if (gChangingConfiguration==1) return;

   // update the system include directories
   if (ctlUserIncludesList.p_EditInPlace) {
      if (ctlCurConfig.p_text==ALL_CONFIGS) {
         if (gAllConfigsInfo.IncludesMatchForAllConfigs) {
            ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                          _ProjectGet_AssociatedIncludes(gProjectHandle, false));

         } else {
            ctlUserIncludesList._TreeSetDelimitedItemList(gAllConfigsInfo.Includes, PATHSEP, false,
                                                          "Select a configuration to edit includes");
         }
      } else {
         ctlUserIncludesList._TreeSetDelimitedItemList(_ProjectGet_IncludesList(gProjectHandle, GetConfigText()),
                                                       PATHSEP, false,
                                                       _ProjectGet_AssociatedIncludes(gProjectHandle, false, GetConfigText()));
      }
   }

   if (reason == CHANGE_CLINE) {
      _str compiler_name = ctlCompilerList.p_text;
      // strip off actual compiler name if set to 'Latest Version(name)'
      if (substr(compiler_name,1,length(COMPILER_NAME_LATEST)):==COMPILER_NAME_LATEST) {
         compiler_name=COMPILER_NAME_LATEST;
      } else if (substr(compiler_name,1,length(COMPILER_NAME_DEFAULT)):==COMPILER_NAME_DEFAULT) {
         compiler_name=COMPILER_NAME_DEFAULT;
      }

      if (ctlCurConfig.p_text==ALL_CONFIGS) {
         int i;
         for (i=0;i<gConfigList._length();++i) {
            _str config=gConfigList[i];
            _ProjectSet_CompilerConfigName(gProjectHandle, compiler_name,config);
            gAllConfigsInfo.CompilerConfigName=compiler_name;
         }
      } else {
         _ProjectSet_CompilerConfigName(gProjectHandle, compiler_name,GetConfigText());
      }
      gUpdateTags=true;
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
      if (ctlCurConfig.p_text==ALL_CONFIGS) {
         int i;
         for (i=0;i<gConfigList._length();++i) {
            _str config=gConfigList[i];

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
      if (ctlCurConfig.p_text==ALL_CONFIGS) {
         int i;
         for (i=0;i<gConfigList._length();++i) {
            _str config=gConfigList[i];

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
   if (gIsExtensionProject) {
      return(gConfigName);
   }
   return(ctlCurConfig.p_text);
}

/**
 */
static boolean shouldEnableBuildFirst(int handle, _str configName)
{
   if(configName == ALL_CONFIGS) {
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

static int SaveOptionToLine(_str SaveOption)
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
   int i;
   for (i=0;i<gSaveComboList._length();++i) {
      if (strieq(gShowComboList[i],SaveOption)) {
         return(i+1);
      }
   }
   return(1);
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
      ctlToolSaveCombo.p_line=SaveOptionToLine(saveOptions);
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
   typeless result=show('-modal _project_config_form',gProjectHandle,gIsProjectTemplate);
   if (result=='') return('');

   gSetActiveConfigTo=maybe_quote_filename(_param1);
   if (result==0) return(result);

   // save what was selected before
   _str origconfig=GetConfigText();

   // add all the configs back into the list
   _ProjectGet_ConfigNames(gProjectHandle,gConfigList);
   ctlCurConfig._lbclear();
   int i;
   for (i=0;i<gConfigList._length();++i) {
      ctlCurConfig._lbadd_item(gConfigList[i]);
   }

   if (ctlCurConfig.p_Noflines) {
      ctlCurConfig._lbbottom();
      ctlCurConfig._lbadd_item(ALL_CONFIGS);
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
      _str name='';
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
   _str thisname=_GetAppTypeName(AppType);
   _str list=AppTypeList;
   for (;;) {
      _str description='';
      parse list with description','list;
      if (description=='') {
         return(thisname);
      }
      _str name=_GetAppTypeName(description);
      if (strieq(name,thisname)) {
         return(description);
      }
   }
}
void ctlAppType.on_change(int reason)
{
   if (!ctlAppType.p_visible) return;
   if (gChangingConfiguration==1) return;

   _str AppType=_GetAppTypeName(p_text);
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
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

#define isPredefinedUserTool(a)  (a=='user1' || a=='user2')

void ctlToolTree.on_change(int reason,int index)
{
   // if this is not a CHANGE_SELECTED event, ignore it
   if(reason != CHANGE_SELECTED) return;

   // if the index is 0, it is the root node and the tree is empty
   if(index <= 0) return;

   // From the tool name, find out the tool index and
   // init the text boxes:
   _str TargetName=GetTargetName();

   // check to see if this is a target or a rule based on depth
   boolean isRule = false;
   _str parentTargetName = "";
   if(ctlToolTree._TreeGetDepth(index) == 2) {
      isRule = true;
      parentTargetName = lowcase(ctlToolTree._TreeGetCaption(ctlToolTree._TreeGetParentIndex(index)));
   }

   int Verbose=0;
   int Beep=0;
   _str CaptureOutputWith=0;
   int ClearProcessBuffer=0;
   _str MenuCaption="";
   int RunInXterm=0;
   _str ClassPath="";
   _str SaveOption="";
   _str ShowOnMenu="";
   _str RunFromDir="";
   typeless Deletable=false;
   _str Exec_Type="";
   int EnableBuildFirst=0;
   typeless BuildFirst=0;
   _str Dialog="";

   _str cmdLine;
   _str otherOptions;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      if(isRule) {
         cmdLine= gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Exec_CmdLine;
         otherOptions= gAllConfigsInfo.TargetInfo:[parentTargetName].Rules:[TargetName].Exec_OtherOptions;
         Verbose=0;
         Beep=0;
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
      int targetNode = -1;
      if(isRule) {
         targetNode = _ProjectGet_RuleNode(gProjectHandle, parentTargetName, TargetName, GetConfigText());

         cmdLine=_ProjectGet_TargetCmdLine(gProjectHandle, targetNode);
         otherOptions=_ProjectGet_TargetOtherOptions(gProjectHandle, targetNode);
         Verbose=0;
         Beep=0;
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
      ctlToolNew.p_enabled = 0;

      // cannot reorder rules
      ctlToolUp.p_enabled = ctlToolDown.p_enabled = 0;

      // cannot apply advanced items to rules
      ctlToolAdvanced.p_enabled = 0;

      // disable menu caption
      ctlToolMenuCaption.p_enabled = ctlMenuCaptionLabel.p_enabled = 0;

      // disable run from dir
      ctlRunFromDirLabel.p_enabled = 0;
      ctlRunFromDir.p_enabled = 0;
      ctlBrowseRunFrom.p_enabled = 0;
      ctlRunFromButton.p_enabled = 0;

      // disable save and show on menu combobox
      ctlToolSaveCombo.p_enabled = 0;
      ctlToolHideCombo.p_enabled = 0;

      // disable capture output
      ctlToolCaptureOutput.p_enabled = 0;

   } else {
      ctlToolNew.p_enabled = 1;

      // this if mimics the behavior of ctlCurConfig.on_change() for the up/down buttons
      if(ctlCurConfig.p_text != ALL_CONFIGS || gAllConfigsInfo.TargetList != null) {
         ctlToolUp.p_enabled = ctlToolDown.p_enabled = ctlToolAdvanced.p_enabled = 1;
      }

      // enable menu caption
      ctlToolMenuCaption.p_enabled = ctlMenuCaptionLabel.p_enabled = 1;

      // enable run from dir
      ctlRunFromDirLabel.p_enabled = 1;
      ctlRunFromDir.p_enabled = 1;
      ctlBrowseRunFrom.p_enabled = 1;
      ctlRunFromButton.p_enabled = 1;

      // enable save and show on menu combobox
      ctlToolSaveCombo.p_enabled = 1;
      ctlToolHideCombo.p_enabled = 1;

      // enable capture output
      ctlToolCaptureOutput.p_enabled = 1;
   }

   if (strieq(TargetName,'build') || strieq(TargetName,'rebuild') ) {
      ctlToolVerbose.p_enabled=(Exec_Type=='');
      //ctlToolVerbose.p_enabled=1;
      if (Verbose==2) {
         ctlToolVerbose.p_style=PSCH_AUTO3STATEB;
      }
      ctlToolVerbose.p_value= Verbose;

      ctlToolBeep.p_enabled=(Exec_Type=='');
      //ctlToolBeep.p_enabled=1;
      if (Beep==2) {
         ctlToolBeep.p_style=PSCH_AUTO3STATEB;
      }
      ctlToolBeep.p_value= Beep;
   }else{
      ctlToolVerbose.p_value=0;
      ctlToolVerbose.p_enabled=0;
      ctlToolBeep.p_value=0;
      ctlToolBeep.p_enabled=0;
   }
   // If tool does not have a command line, we default a few things.
   // Otherwise just fill in.
   boolean oldcc=false;
   if (cmdLine== "" || cmdLine==null) {
      oldcc=gChangingConfiguration;
      gChangingConfiguration=1;
      ctlToolCmdLine.p_text= "";
      gChangingConfiguration=oldcc;
   } else {
      oldcc=gChangingConfiguration;
      gChangingConfiguration=1;
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

#if __UNIX__
   if (RunInXterm==2) {
      ctlRunInXterm.p_style=PSCH_AUTO3STATEB;
   }
   ctlRunInXterm.p_value= RunInXterm;
#endif

   if (ClearProcessBuffer==2) {
      ctlToolClearProcessBuf.p_style=PSCH_AUTO3STATEB;
   }
   ctlToolClearProcessBuf.p_value= ClearProcessBuffer;

   updateSaveOptions(SaveOption);
   updateShowOnMenuOptions(ShowOnMenu);

   // Disable a few things for predefined tools:
   ctlToolDelete.p_enabled= (Deletable && ctlToolTree._TreeGetNumChildren(TREE_ROOT_INDEX)>1)?1:0;

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
#if __UNIX__
      //This two commented out lines cause p_value to be set to zero when ctlToolCaptureOutput.p_value==2
      //ctlRunInXterm.p_value= 0;
      //ctlRunInXterm.call_event(ctlRunInXterm,LBUTTON_UP,'W');
      //ctlRunInXterm.p_enabled= false;
#endif
   } else {
      ctlToolOutputToConcur.p_enabled= false;
      ctlToolClearProcessBuf.p_enabled= false;
#if __UNIX__
      ctlRunInXterm.p_enabled= true;
#endif
   }
   if (ctlToolOutputToConcur.p_value /*&& ctlToolOutputToConcur.p_enabled*/) {
      ctlToolClearProcessBuf.p_enabled= true;
   } else {
      ctlToolClearProcessBuf.p_enabled= false;
      ctlToolClearProcessBuf.p_value= 0;
   }

   if(Exec_Type == "" && !isRule) {
      ctlToolCaptureOutput.p_enabled = 1;
   } else {
      ctlToolCaptureOutput.p_enabled = 0;
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
         ctlBuildFirst.p_enabled=(EnableBuildFirst)?1:0;

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
      ctlToolSaveCombo.p_enabled = 0;
   } else if(ctlBuildFirst.p_enabled) {
      ctlToolSaveCombo.p_enabled = !ctlBuildFirst.p_value;
   } else {
      ctlToolSaveCombo.p_enabled = 1;
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

   ctlRunFromDir.p_text = RunFromDir == null ? "" : RunFromDir;

   if (Dialog==null || cmdLine==null) {
      ctlToolCmdLine.p_visible=false;
      ctlToolCmdLineButton.p_visible=false;
      ctlBrowseCmdLine.p_visible=false;
      ctlcommand_line_label.p_visible=false;
      ctlcmdmessage.p_caption=MESSAGE_ALLCONFIG_TOOLS_MISMATCH;
      ctlcmdmessage.p_visible=true;
      ctlcommand_options.p_visible=0;
   } else if (Dialog!='') {
      ctlcommand_options.p_visible=1;
      gDialog=Dialog;
      ctlcommand_line_label.p_visible=0;

      ctlToolCmdLine.p_visible=false;
      ctlToolCmdLineButton.p_visible=false;
      ctlBrowseCmdLine.p_visible=false;
      ctlcommand_line_label.p_visible=false;
      ctlcmdmessage.p_caption=MESSAGE_PRESS_OPTIONS_BUTTON;
      ctlcmdmessage.p_visible=true;
   }else{
      ctlcommand_options.p_visible=0;
      _str firstword='';
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
         ctlcommand_line_label.p_visible=1;

         // cannot select IsSlickCMacro if a dialog is specified
         ctlCommandIsSlickCMacro.p_enabled=true;
      }
   }
   /*if (ctlToolCmdLine.p_ReadOnly) {
      ctlToolCmdLine.p_backcolor=0x80000022;
   } */
}

_str ctlcommand_options.lbutton_up(_str DialogName='')
{
   if (DialogName=='') {
      DialogName=gDialog;
   }
   _str Options='';
   parse DialogName with DialogName Options;
   int form_wid=p_active_form;
   PROJECT_CONFIG_INFO ProjectInfo:[];


   int wid=show('-hidden -wh 'DialogName,gProjectHandle,Options,GetConfigText(),gProjectName,gIsProjectTemplate);
   //int wid=show('-hidden -wh 'DialogName,Options,&gAllConfigsInfo,gConfigList,GetConfigText(),gProjectName);
   _str result='';
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
   int fid= p_active_form;
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
   p_word_wrap_style=p_word_wrap_style&(~WORD_WRAP_WWS);
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
   p_word_wrap_style=p_word_wrap_style&(~WORD_WRAP_WWS);
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
   p_word_wrap_style=p_word_wrap_style&(~WORD_WRAP_WWS);
#endif
}

static int oncreateMacro()
{
   _str MacroCmdLines[];
   _ProjectGet_Macro(gProjectHandle,MacroCmdLines);
   list1._setMacroTextList(MacroCmdLines,0);
   return( 0 );
}
static void okMacro(boolean &macrosChanged)
{
   _str text='';

   list1._getMacroText(text,0);

   _str orig_text=_ProjectGet_MacroList(gProjectHandle);
   if (text!=orig_text) {
      _ProjectSet_MacroList(gProjectHandle,text);
      if (_project_name!='' && file_eq(gProjectName,_project_name)) {
         macrosChanged=1;
      }
   }
}

void ctlfolders.lbutton_up()
{
   _str filters_list='';

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
void _ok.on_create(_str PropertiesForName='',int project_handle=-1,_str activetab='',boolean MakeCopyFirst=true,boolean doSaveIfNecessary=true,
                   boolean IsProjectPackage=false)
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
   gFileListModified=0;  // List is not modified.
   gAllConfigsInfo._makeempty();
   gProjectHandle=project_handle;
   gMakeCopyFirst=MakeCopyFirst;
   gdoSaveIfNecessary=doSaveIfNecessary;
   gIsProjectTemplate=IsProjectPackage;
   gConfigName=PropertiesForName; // Only used when editing settings for extension project

   gIsExtensionProject=(project_handle==gProjectExtHandle);

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

#if __UNIX__
   ctlRunInXterm.p_visible= true;
#endif

   // Fill in the options for the modified files save combo box
   FillInToolSaveCombo();

   // fill in the options for the hide combo box
   FillInToolShowCombo();

   // If a real project is opened, _project_name is not "" and arg(1)== ""
   // If an extension project is opened, _project_name is "" and arg(1) is ".e" or ".c" or ...
   int fid=p_active_form;
   _str SectionsList[];

   if (gIsProjectTemplate) {
      p_active_form.p_caption='Project Package for "'PropertiesForName'"';
   } else if(gIsExtensionProject) {
      p_active_form.p_caption='Project Properties For '_LangId2Modename(substr(PropertiesForName,2));
   } else {
      p_active_form.p_caption="Project Properties For ":+GetProjectDisplayName(PropertiesForName);
   }
   // Disable unused tabs (for extension project):
   //
   //_proj_prop_sstab._setEnabled(PROJPROPTAB_CONFIGURATIONS,0); // Configurations
   if (gIsExtensionProject) {  // extension project or project pack
      ctlRunFromDir.p_enabled=false;
      _proj_prop_sstab._setEnabled(PROJPROPTAB_FILES,0); // Files tab
      _proj_prop_sstab._setEnabled(PROJPROPTAB_DIRECTORIES,1);
      _proj_prop_sstab._setEnabled(PROJPROPTAB_BUILDOPTS,0); // Build Options tab
      _proj_prop_sstab._setEnabled(PROJPROPTAB_OPENCOMMAND,0); // Command

      // Make sure the active tab is one of the enabled ones:
      if (activetab=='') {
         activetab= _retrieve_value("_project_form._proj_prop_sstab");
      }
      if (activetab== PROJPROPTAB_FILES
          || activetab== PROJPROPTAB_BUILDOPTS
          || activetab== PROJPROPTAB_OPENCOMMAND
          /*|| activetab== PROJPROPTAB_CONFIGURATIONS*/) {
         _proj_prop_sstab.p_ActiveTab= PROJPROPTAB_DIRECTORIES;
      } else if (activetab!=''){
         _proj_prop_sstab.p_ActiveTab= (int)activetab;
      }

      // For a project pack, get the pack information from arg(2).
      ctlPreBuildCmdList.DisableAll();
      ctlCurConfig.p_enabled=false;
      ctlCurConfig.p_prev.p_enabled=false;
      ctlconfigurations.p_enabled=false;
   } else if (gIsProjectTemplate) {
      _proj_prop_sstab._setEnabled(PROJPROPTAB_FILES,0); // Files tab

      // Make sure the active tab is one of the enabled ones:
      if (activetab=='') {
         activetab= _retrieve_value("_project_form._proj_prop_sstab");
      }
      if (activetab== PROJPROPTAB_FILES) {
         _proj_prop_sstab.p_ActiveTab= PROJPROPTAB_DIRECTORIES;
      } else if (activetab!=''){
         _proj_prop_sstab.p_ActiveTab= (int)activetab;
      }

      ctlfolders.p_visible=true;
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
         boolean LeaveFileTabEnabled=_CanWriteFileSection(GetProjectDisplayName(gProjectName));
         gLeaveFileTabEnabled=LeaveFileTabEnabled;
         DisableProjectControlsForWorkspace(LeaveFileTabEnabled, false);
         if (!gProjectFilesNotNeeded && !_IsEclipseWorkspaceFilename(_workspace_filename) &&
             !_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
            int modify=_xmlcfg_get_modify(gProjectHandle);
            int Node=_ProjectGet_FilesNode(gProjectHandle,true);

            _str fileList[];
            int status = _getProjectFiles(_workspace_filename, gProjectName, fileList, 0);
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
            _str path = _strip_filename(gProjectName, "N");

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
   if (!gIsExtensionProject) {  // a real project opened
      oncreateMacro();
   }
   // Initialize the Directories and Tools tabs.
   // project ==> ".e" for extension project, "" for real project
   oncreateDirectories();
   oncreateBuildOptions();

   // load dependencies tab with all projects in workspace except this one
   if (!gIsExtensionProject && !gIsProjectTemplate) {  // a real project opened
      oncreateDependencies();
   }

   if (gIsExtensionProject) {
      // just add the extension and select it - user will not be able to change it
      ctlCurConfig._lbadd_item(gConfigName);
      ctlCurConfig.call_event(CHANGE_SELECTED,ctlCurConfig,ON_CHANGE,'W');
   } else {
      //_ProjectGet_Configs(gProjectName,gConfigList);
      ctlCurConfig._lbclear();
      int i;
      for (i=0;i<gConfigList._length();++i) {
         ctlCurConfig._lbadd_item(gConfigList[i]);
      }
      //_showbuf(ctlCurConfig.p_cb_list_box.p_buf_id);
      if (ctlCurConfig.p_Noflines) {
         ctlCurConfig._lbbottom();
         ctlCurConfig._lbadd_item(ALL_CONFIGS);
      } else {
         _message_box('ERROR: project file has no configurations');
      }
      //_showbuf(ctlCurConfig.p_cb_list_box.p_window_id);
      ctlCurConfig._lbbottom();
      if (gIsExtensionProject || gIsProjectTemplate || !def_project_prop_show_curconfig) {
         ctlCurConfig.p_text=ctlCurConfig._lbget_text();
      } else {
         ctlCurConfig.p_text=GetCurrentConfigName(gProjectName);
      }
      //ctlCurConfig.p_text=ctlCurConfig.p_cb_list_box._lbget_text();
   }
   ctlimport.p_enabled=ImportTypesAvailable();
   ctlimport.p_visible=ctlimport.p_enabled;

   // call any _prjedit_* functions
   call_list("_prjedit_", gProjectHandle);

   // force an activate event
   // does not get called during restore since the files tab
   // is tab zero
   if (_proj_prop_sstab.p_ActiveTab==PROJPROPTAB_FILES) {
      call_event(CHANGE_TABACTIVATED,_proj_prop_sstab,ON_CHANGE,'W');
   }
}

static void FillInToolSaveCombo()
{
   for (i := 0; i < gSaveComboTextList._length(); i++) {
      ctlToolSaveCombo._lbadd_item(gSaveComboTextList[i]);            // SAVENONE=0
   }
}

static _str getToolSaveComboValue()
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

static boolean ImportTypesAvailable()
{
   return(!_IsWorkspaceAssociated(_workspace_filename) && def_import_file_types!='');
}

//  int _[ext]_import_files(_str from_filename, _str (&file_list)[]);
int ctlimport.lbutton_up()
{
   // _import_list_form returns a wid to a temporary window
   int orig_wid=p_window_id;
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
   int wid=p_window_id;
   p_window_id=_srcfile_list;

   int len=Files._length();
   int i;
   int list_wid=_srcfile_list;
   _str projectPath=_strip_filename(gProjectName,'N');
   _str config=ctlCurConfig.p_text;

   // get ready to add some files to this configuration
   int FileToNode:[];
   int FilesNode=0;
   _str AutoFolders='';
   int ExtToNodeHashTab:[];
   _str LastExt='';
   int LastNode=0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);

   // and add them
   list_wid._lbbegin_update();
   for (i=0;i<len;++i) {
      AddFileToConfig(list_wid,relative(Files[i],projectPath),config,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   list_wid._lbend_update(list_wid.p_Noflines);

   if ( len ) {
      gFileListModified=1;
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
      _str cur='';
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
   _str cmd2='';
   if (p) {
      if (p>1) {
         cmd2=substr(cmd,1,p);
         ++p;
      }
      //7 is the length of %~other
      cmd2=cmd2:+other:+substr(cmd,p+7);
   }else cmd2=cmd;
   return(cmd2);
}
#endif

static void populate_config_list(_str type = '')
{
   gChangingConfiguration=1;
   ctlCompilerList._lbclear();
   gChangingConfiguration=0;

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

   _str compiler_name='';
   // sometimes have to open compilers.xml again here because _GetLatestXXX will close it
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;
   if (!refactor_config_is_open(filename)){
      refactor_config_open(filename);
   }
   int i,n = refactor_config_count();
   for (i=0; i<n; ++i) {
      refactor_config_get_name(i, compiler_name);
      _str comp_type = '';
      refactor_config_get_type(i, comp_type);
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

static void oncreateDirectories()
{
   _prjworking_dir.p_text=_ProjectGet_WorkingDir(gProjectHandle);

   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   refactor_config_open( filename );

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   int handle = _ProjectHandle();
   _str config = '';
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   _str project_type = _ProjectGet_Type(handle, config );

   populate_config_list(project_type);

   if (project_type == 'java') {
      ctlHelpLabelCompileLink.p_caption = "The compiler configuration selects the JDK package to use for building and tagging for the Java project.";
   }
}

static void okDirectories()
{
   if (_prjworking_dir.p_text!=_ProjectGet_WorkingDir(gProjectHandle)) {
      _str workingDir = _prjworking_dir.p_text;

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
   // setup pre/post commands
   //ctlPreBuildCmdList._TreeSetDelimitedItemList(GetCmdInfo(GetConfigText(), 'PRE'), "\1", true);
   //ctlStopOnPreErrors.p_value = GetCmdInfo(GetConfigText(), 'SPRE') == '1' ? 1 : 0;
// ctlMovePreCmdUp.p_y = ctlMovePreCmdUp.p_y - 300;
// ctlMovePreCmdDown.p_y = ctlMovePreCmdDown.p_y - 300;

   //ctlPostBuildCmdList._TreeSetDelimitedItemList(GetCmdInfo(GetConfigText(), 'POST'), "\1", true);
   //ctlStopOnPostErrors.p_value = GetCmdInfo(GetConfigText(), 'SPOST') == '1' ? 1 : 0;
// ctlMovePostCmdUp.p_y = ctlMovePostCmdUp.p_y - 300;
// ctlMovePostCmdDown.p_y = ctlMovePostCmdDown.p_y - 300;

   // setup build system
   switch(_ProjectGet_BuildSystem(gProjectHandle)) {
      case "vsbuild":
         ctlBuild_vsbuild.p_value = 1;
         ctlBuild_AutoMakefile.p_value = 0;
         ctlBuild_Custom.p_value = 0;

         ctlAutoMakefile.p_text = "";
         ctlAutoMakefile.p_enabled = false;
         ctlAutoMakefileButton.p_enabled = false;
         break;

      case "automakefile":
         ctlBuild_vsbuild.p_value = 0;
         ctlBuild_AutoMakefile.p_value = 1;
         ctlBuild_Custom.p_value = 0;

         ctlAutoMakefile.p_text = _ProjectGet_BuildMakeFile(gProjectHandle);
         ctlAutoMakefile.p_enabled = true;
         ctlAutoMakefileButton.p_enabled = true;
         break;

      default:
         ctlBuild_vsbuild.p_value = 0;
         ctlBuild_AutoMakefile.p_value = 0;
         ctlBuild_Custom.p_value = 1;
         ctlBuild_Custom.p_user = _ProjectGet_BuildMakeFile(gProjectHandle);

         ctlAutoMakefile.p_text = "";
         ctlAutoMakefile.p_enabled = false;
         ctlAutoMakefileButton.p_enabled = false;
   }
}

static void GetBuildOptions(_str &BuildSystem,_str &BuildMakeFile)
{
   BuildSystem='';
   BuildMakeFile='';
   if (ctlBuild_vsbuild.p_value) {
      BuildSystem='vsbuild';
   } else if (ctlBuild_Custom.p_value) {
      BuildSystem='';
      BuildMakeFile=ctlBuild_Custom.p_user;
   } else {
      BuildSystem='automakefile';
      BuildMakeFile=ctlAutoMakefile.p_text;
   }
}

static void okBuildOptions()
{
   _str BuildSystem = "";
   _str BuildMakeFile = "";
   GetBuildOptions(BuildSystem,BuildMakeFile);

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
                      ALL_CONFIGS);

   } else if(strieq(gInitialBuildSystem,"automakefile")) {
      // if this was using automakefile support but is no longer, remove the
      // makefile from the project
      // NOTE: it is safe to just remove it from the file list view because the
      //       entire list will be parsed later and the tag file will be updated
      _str oldBuildMakeFile = _parse_project_command(gInitialBuildMakeFile, "", gProjectName, "");
      int FileToNode:[] = null;
      _ProjectGet_FileToNodeHashTab(gProjectHandle, FileToNode);
      RemoveFileFromViews(relative(oldBuildMakeFile, _strip_filename(gProjectName, 'N')), ALL_CONFIGS, FileToNode);
   }

   if (!strieq(_ProjectGet_BuildSystem(gProjectHandle),BuildSystem) ||
       !strieq(_ProjectGet_BuildMakeFile(gProjectHandle),BuildMakeFile)) {

      _ProjectSet_BuildSystem(gProjectHandle,BuildSystem);
      _ProjectSet_BuildMakeFile(gProjectHandle,BuildMakeFile);
   }
}

static void oncreateDependencies()
{
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
      if(file_eq(depProjectFile, thisProject) || depProjectFile == "") {
         continue;
      }

      int wid=p_window_id;
      _control ctlDepsTree;
      p_window_id=ctlDepsTree;
      // add the project node
      int depProjectNode = _TreeAddItem(TREE_ROOT_INDEX, depProjectFile, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_EXPANDED);
      if(depProjectNode < 0) continue;
      int depProjectActiveConfigNode = _TreeAddItem(depProjectNode, "Active Configuration", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      _TreeSetCheckState(depProjectActiveConfigNode,TCB_UNCHECKED);

      int depProjectOtherConfigsNode = _TreeAddItem(depProjectNode, "Configurations", TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_COLLAPSED);

      // open that project
      int depProjectHandle = _ProjectHandle(_AbsoluteToWorkspace(depProjectFile));
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
                                       int projectIndex = -1, boolean activeConfigChecked = false,
                                       int configIndex = -1, boolean configChecked = false)
{
   int wid=p_window_id;
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
         boolean uncheckProject = true;
         int siblingConfigState = 0;
         int siblingConfigIndex = _TreeGetFirstChildIndex(projectIndex);
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
         checkAllChildren(otherConfigFolderIndex,0);
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
                                          boolean checked, boolean wasGraychecked)
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
static void updateDependsRefs(_str config, boolean enable)
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
   int wid=p_window_id;
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
   int wid=p_window_id;
   _nocheck _control ctlDepsTree;
   p_window_id=ctlDepsTree;
   // determine whether tree search will be case-sensitive or not
   _str searchOptions = "";
   #if __UNIX__
   #else
      searchOptions = "I";
   #endif

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
   int state = 0;

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
   int state = 0;

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
   _str searchOptions = "";
   #if __UNIX__
   #else
      searchOptions = "I";
   #endif

   // run thru the dependencies and make sure that all project level
   // dependencies have configs that match the implied config names
   //
   // NOTE: this is done by running thru the xml file instead of the
   //       tree because the tree only displays the representation
   //       of a single configuration (or the 'all configs' combined
   //       case).  the tree is only used to determine what configs
   //       a project has in order to avoid having to open all of
   //       the workspace projects again.
   int c;
   for(c = 0; c < gConfigList._length(); c++) {
      _str config = gConfigList[c];

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

   _str cur_def='';
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
      newIndex = ctlDefinesTree._TreeAddListItem(BLANK_TREE_NODE_MSG);
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
      if (!strieq(info2.OutputFile,info.OutputFile)) info.OutputFile='';
      if (!strieq(info2.DebugCallbackName,info.DebugCallbackName)) info.DebugCallbackName='';
      if (!strieq(info2.ObjectDir,info.ObjectDir)) info.ObjectDir='';
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

void ctlCurConfig.on_change(int reason)
{
   if (ignore_config_change) {
      return;
   }
   gChangingConfiguration=1;
   /*if (!p_active_form.p_visible && p_text!=ALL_CONFIGS) {
      CHANGING_CONFIGURATION=0;
      return;
   } */

   _str ConfigName=GetConfigText();

   ctlToolUp.p_enabled=ctlToolDown.p_enabled=ctlToolAdvanced.p_enabled=1;

   _str ToolName=GetTargetName();
   if (ToolName=='') {
      ToolName=lowcase(gInitialTargetName);
   }
   //ctlAppType.p_text must be set before we call the on_change event for ctlToolTree
   isJavaConfigType:=true;
   _str AppType;
   _str AppTypeList;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
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
                                                       "Select a configuration to edit includes");
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

      // update the compiler config name to match what appears in the compilers list
      if (gAllConfigsInfo.CompilerConfigName:==COMPILER_NAME_LATEST) {
         // Latest is always listed first in the list
         ctlCompilerList._lbtop();
         gAllConfigsInfo.CompilerConfigName=ctlCompilerList._lbget_text();
      } else if (gAllConfigsInfo.CompilerConfigName:==COMPILER_NAME_DEFAULT) {
         // Default is always listed second
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         gAllConfigsInfo.CompilerConfigName=ctlCompilerList._lbget_text();
      }
      if (gAllConfigsInfo.CompilerConfigName!='') {
         ctlCompilerList._lbfind_and_select_item(gAllConfigsInfo.CompilerConfigName);
      }

      fillInDefines(gAllConfigsInfo.Defines,gAllConfigsInfo.AssociatedDefines);

      ctlLibraries.p_text=gAllConfigsInfo.Libs;

      ctlToolTree._TreeDelete(TREE_ROOT_INDEX, "C");

      if (gAllConfigsInfo.TargetList!=null) {
         _str list=gAllConfigsInfo.TargetList;
         for (;;) {
            _str item='';
            parse list with item "\1" list;
            if (item=="") {
               break;
            }
            _str lowcasedItem = lowcase(item);

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
         ctlToolUp.p_enabled=ctlToolDown.p_enabled=0;
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

   }else{
      if (gIsExtensionProject && _ProjectGet_ConfigNode(gProjectHandle,ConfigName)<0) {
         _ProjectCreateLangSpecificConfig(gProjectHandle, ConfigName);
      }
      _str compiler_name=_ProjectGet_CompilerConfigName(gProjectHandle,ConfigName);

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

      // change the compiler name to match what is in the compiler list
      if (compiler_name:==COMPILER_NAME_LATEST) {
         // latest is always at the top of the list
         ctlCompilerList._lbtop();
         compiler_name=ctlCompilerList._lbget_text();
      } else if (compiler_name:==COMPILER_NAME_DEFAULT) {
         // default is always second in the list
         ctlCompilerList._lbtop();
         ctlCompilerList._lbdown();
         compiler_name=ctlCompilerList._lbget_text();
      }
      ctlCompilerList._lbfind_and_select_item(compiler_name);

      _str assoc_file = _ProjectGet_AssociatedFile(gProjectHandle);
      if (assoc_file!='') {
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
   }

   ctlToolTree._TreeRefresh();
   if (isJavaConfigType) {
      ctlIncDirLabel.p_enabled=0;
      ctlDefinesLabel.p_enabled=0;
      ctlDefinesTree.p_EditInPlace=0;
      ctlDefinesTree.p_enabled=0;
      ctlAddDefine.p_enabled=0;
      ctlAddUndef.p_enabled=0;
      ctlUserIncludesList.p_enabled=0;
      ctlUserIncludesList.p_next.p_enabled=0; // browse button
      ctlMoveUserIncludesUp.p_enabled=0; // up button
      ctlMoveUserIncludesDown.p_enabled=0; // down button
      ctlRemoveUserIncludes.p_enabled=0; // delete button
      //ctlCompilerList.p_enabled=0;
      ctlBuild_vsbuild.p_visible=0;
      ctlBuild_AutoMakefile.p_visible=0;
      ctlBuild_Custom.p_visible=0;
      ctlBuildDescription.p_visible=0;
      ctlMakefileLabel.p_visible=0;
      ctlAutoMakefile.p_visible=0;
      ctlAutoMakefileButton.p_visible=0;
      ctlBuildSystem.p_visible=0;
      ctlLibrariesLabel.p_enabled=0;
      ctlLibraries.p_enabled=0;
      ctlLinkOrder.p_enabled=0;
      ctlLibrariesButton.p_enabled=0;
   } else {
      ctlBuild_vsbuild.p_visible=1;
      ctlBuild_AutoMakefile.p_visible=1;
      ctlBuild_Custom.p_visible=1;
      ctlBuildDescription.p_visible=1;
      ctlMakefileLabel.p_visible=1;
      ctlAutoMakefile.p_visible=1;
      ctlAutoMakefileButton.p_visible=1;
      ctlBuildSystem.p_visible=1;
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
      ctlAppType.p_visible=ctlAppTypeLabel.p_visible=true;
   } else {
      ctlHelpLabelTools.p_visible=true;
      ctlAppType.p_visible=ctlAppTypeLabel.p_visible=false;
   }
   _srcfile_list.FillInSrcFileList(ctlCurConfig.p_text);

   ctlToolTree.call_event(CHANGE_SELECTED, ctlToolTree._TreeCurIndex(), ctlToolTree, ON_CHANGE, 'W');
   ctlToolTree.refresh();

   gChangingConfiguration=0;
}

void _prjref_files.on_change(int reason)
{
   if (gChangingConfiguration==1) return;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str config=gConfigList[i];

         _ProjectSet_RefFile(gProjectHandle,p_text,config);
         gAllConfigsInfo.RefFile=p_text;
      }
   } else {
      _ProjectSet_RefFile(gProjectHandle,p_text,GetConfigText());
   }
}

void ctlBuild_vsbuild.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = false;
   ctlAutoMakefileButton.p_enabled = false;
   _str BuildSystem = "";
   _str BuildMakeFile = "";
   GetBuildOptions(BuildSystem,BuildMakeFile);
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str config=gConfigList[i];
      switchBuildSystem(config,BuildSystem,BuildMakeFile);
   }
}

void ctlBuild_Custom.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = false;
   ctlAutoMakefileButton.p_enabled = false;
   _str BuildSystem = "";
   _str BuildMakeFile = "";
   GetBuildOptions(BuildSystem,BuildMakeFile);
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str config=gConfigList[i];
      switchBuildSystem(config,BuildSystem,BuildMakeFile);
   }
}

void ctlBuild_AutoMakefile.lbutton_up()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   ctlAutoMakefile.p_enabled = true;
   ctlAutoMakefileButton.p_enabled = true;
   _str BuildSystem = "";
   _str BuildMakeFile = "";
   GetBuildOptions(BuildSystem,BuildMakeFile);
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str config=gConfigList[i];
      switchBuildSystem(config,BuildSystem,BuildMakeFile);
   }
}

void ctlAutoMakefile.on_change()
{
   if (gChangingConfiguration || !p_active_form.p_visible) return;
   _str BuildSystem = "";
   _str BuildMakeFile = "";
   GetBuildOptions(BuildSystem,BuildMakeFile);

   // change buildmakefile to whatever is in ctlAutoMakefile
   BuildMakeFile = ctlAutoMakefile.p_text;

   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str config=gConfigList[i];
      switchBuildSystem(config,BuildSystem,BuildMakeFile);
   }
}

static int storeDependencyInfo(int index)
{
   _TreeGetInfo(index, auto state, auto pic);
   arrayIndex := _TreeGetUserInfo(index);

   // note whether this is a config or a project.  if it is a config,
   // it will be a leaf node (state == -1).  otherwise, it is a project.
   depth := _TreeGetDepth(index);
   boolean isProject = (depth == 2);  // This is actually the "Active Config" checkbox
   boolean isConfig = (depth == 3);

   // toggle the picture, remembering if it was enabled or not so the
   // value can be set in the project
   boolean checked = _TreeGetCheckState(index);

   if(isProject) {
      // update the project and potentially graycheck the implied config
      updateDependenciesTreeInfo(GetConfigText(), index, checked);
   } else if(isConfig) {
      // update the config and potentially graycheck the parent project
      updateDependenciesTreeInfo(GetConfigText(), -1, false, index, checked);
   }

   // get the names of the project (and config if applicable)
   _str depProject = "", depConfig = "";
   if(isProject) {
      depProject = _TreeGetCaption(getProjectIndexFromActiveConfig(index));
   } else {
      depProject = _TreeGetCaption(getProjectIndexFromIndividualConfig(index));
      depConfig = _TreeGetCaption(index);
   }

   // now store the information in the project
   if(ctlCurConfig.p_text == ALL_CONFIGS) {
      if ( checked ) {
         // First, get rid of any checked individual configs, or checked active
         // config, depending on what was clicked on
         // 
         if ( isProject ) {
            getConfigListFromTree(index,auto configList);
            foreach ( auto configName in configList ) {
               updateDependenciesProjectInfoForAllConfigs(depProject, configName, 0, 0);
            }
         }
      }
      updateDependenciesProjectInfoForAllConfigs(depProject, depConfig, checked, 0);
   } else {
      if ( checked ) {
         if ( isProject ) {
            getConfigListFromTree(index,auto configList);
            foreach ( auto configName in configList ) {
               updateDependenciesProjectInfoForAllConfigs(depProject, configName, 0, 0);
            }
         }
      }
      // set the value in the current config in the project
      updateDependenciesProjectInfo(GetConfigText(), depProject, depConfig, checked, 0);
   }

   return 0;
}
static void updateDependenciesProjectInfoForAllConfigs(_str depProject, _str depConfig,boolean checked, boolean wasGraychecked)
{
   int i;
   for(i = 0; i < gConfigList._length(); i++) {
      _str config = gConfigList[i];

      // set the value in each config in the project
      updateDependenciesProjectInfo(config, depProject, depConfig, checked, 0);

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

static void DisableProjectControlsForWorkspace(boolean LeaveFileTabEnabled=false,
                                               boolean LeaveDepsTabEnabled=true)
{
   _add.DisableAll();
   _srcfile_list.p_enabled=1;//Want users to be able to scroll through files

   if (LeaveFileTabEnabled) {
      _add.p_enabled=1;
      _addtree.p_enabled=1;
      _invert.p_enabled=1;
      ctlrefresh.p_enabled=1;
      _remove.p_enabled=1;
      _remove_all.p_enabled=1;
      ctlproperties.p_enabled=1;

      ctlUserIncludesList.p_enabled=true;
      _project_nofselected.p_enabled=true;
      _project_nofselected.p_prev.p_enabled=true;
      ctlCompilerList.p_enabled=true;
   }

   _prjworklab.p_enabled=false;
   _prjworking_dir.p_enabled=false;
   _prjworking_dir.p_next.p_enabled=false; // browse button
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
      ctlDepsTree.p_enabled = 0;
   }
}

static void DisableAll()
{
   int origwid=p_window_id;
   int wid=origwid;
   for (;;) {
      wid=wid.p_next;
      wid.p_enabled=0;
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
   _append_retrieve(0, ctlToolTree._TreeGetCaption(ctlToolTree._TreeCurIndex()), "_project_form.toolNameSelected");
}

static void _InitAddFileToConfig(int (&FileToNode):[],int &FilesNode,_str &AutoFolders,int (&ExtToNodeHashTab):[],_str &LastExt,int &LastNode)
{
   LastExt=null;
   LastNode= -1;
   _ProjectGet_FileToNodeHashTab(gProjectHandle,FileToNode);
   FilesNode=_ProjectGet_FilesNode(gProjectHandle,true);
   AutoFolders=_ProjectGet_AutoFolders(gProjectHandle);

   _ProjectGet_ExtToNode(gProjectHandle,ExtToNodeHashTab);
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
                            WILDCARD_FILE_ATTRIBUTES attrs=null
                            )
{
   list_wid._lbadd_item(Filename);

   gFileListModified=1;
   _str cfilename=_file_case(Filename);

   if (FileToNode==null) {
      _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }

   int *pnode=FileToNode._indexin(cfilename);

   int Node=0;
   if (pnode) {
      Node=*pnode;
   } else {
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         _ProjectAdd_FilteredFiles(gProjectHandle,Filename,FileToNode,ExtToNodeHashTab,LastExt,LastNode);
      } else {
         _str list[];
         list[0]=Filename;
         _ProjectAdd_Files(gProjectHandle,list,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,false);
      }
      Node=FileToNode:[cfilename];
   }
   if (ConfigName==ALL_CONFIGS) {
      _xmlcfg_delete_attribute(gProjectHandle,Node,'C');
   } else {
      _str configs=_xmlcfg_get_attribute(gProjectHandle,Node,'C');

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
            _xmlcfg_delete_attribute(gProjectHandle,Node,'C');
         } else {
            _xmlcfg_set_attribute(gProjectHandle,Node,'C',configs);
         }
      }
   }

   if (attrs!=null) {
      _xmlcfg_set_attribute(gProjectHandle,Node,'Recurse',attrs.Recurse);
      _xmlcfg_set_attribute(gProjectHandle,Node,'Excludes',_NormalizeFile(attrs.Excludes));
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
static void addFilesToHashFromTree(int treeID, int index, boolean (&hashTable):[])
{
   if(index < 0) {
      return;
   }

   // make sure it is a file (ignore projects, folders, dependent projects, etc)
   if(treeID._projecttbIsProjectFileNode(index)) {
      // extract the absolute filename from the tree caption
      _str caption = treeID._TreeGetCaption(index);
      _str filename = "";
      _str absoluteFilename = "";
      parse caption with filename "\t" absoluteFilename;

      // add to the hash table
      hashTable:[_file_case(absoluteFilename)] = true;
   }

   int childIndex = treeID._TreeGetFirstChildIndex(index);
   while(childIndex >= 0) {
      addFilesToHashFromTree(treeID, childIndex, hashTable);

      // move next
      childIndex = treeID._TreeGetNextSiblingIndex(childIndex);
   }
}

static boolean projectPropertiesAddFileHash:[] = null;

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
int projectPropertiesAddFilesCallback(_str filename = "")
{
   // if def_show_prjfiles_in_open_dlg is 1 then this callback has
   // been globally disabled by the user
   if(def_show_prjfiles_in_open_dlg == 1) return 1;

   // if filename is empty, clean the cached information
   if(filename == "") {
      projectPropertiesAddFileHash._makeempty();
      return 0;
   }

   // default to including it
   int includeItem = 1;

   // if the file hash is empty, this is the first time the callback has
   // been called for this open dialog.  populate it with all the files
   // in the current config of the project
   if(projectPropertiesAddFileHash._isempty()) {
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
      boolean fromProjectProperties = false;
      boolean fromProjectToolbar = false;

      // search the ancestry all the way to the top
      int origid = p_window_id;
      int wid = p_window_id;
      for(;;) {
         if(strieq(wid.p_name, "_project_form")) {
            fromProjectProperties = true;
            break;
         } else if(strieq(wid.p_name, "_tbprojects_form")) {
            fromProjectToolbar = true;
            break;
         }

         // move up another level
         if(!wid.p_parent) break;
         wid = wid.p_parent;
      }

      p_window_id = wid;

      if(fromProjectProperties) {
         // the file list has already been processed, so just iterate thru
         // the source list box to save time
         _srcfile_list._lbtop();
         _srcfile_list._lbup();
         while(!_srcfile_list._lbdown()) {
            // make the file absolute so later lookups do not have to be done relatively
            _str absoluteFilename = _AbsoluteToProject(_srcfile_list._lbget_text(), gProjectName);
            projectPropertiesAddFileHash:[_file_case(absoluteFilename)] = true;
         }

      // check to see if the open dialog was launched from the project toolbar
      } else if(fromProjectToolbar) {
         _nocheck _control _proj_tooltab_tree;
         // the file list has already been processed and wildcards have
         // been expanded in the project toolbar, so iterate thru the
         // tree to save time

         // find project that is the parent of the selected node
         int projectNode = _proj_tooltab_tree._TreeCurIndex();
         while(_proj_tooltab_tree._TreeGetDepth(projectNode) > 1) {
            projectNode = _proj_tooltab_tree._TreeGetParentIndex(projectNode);
         }

         // recursively walk the tree
         addFilesToHashFromTree(_proj_tooltab_tree, projectNode, projectPropertiesAddFileHash);
      }

      // restore window id
      p_window_id = origid;
   }

   // check to see if the file is in the hash table of known files
   if(projectPropertiesAddFileHash._indexin(_file_case(filename))) {
      includeItem = 0;
   }

   // if still being included, check to see if it is one of the ignored extensions
   if(includeItem == 1) {
      _str ext = _get_extension(filename, true);
      if(projectPropertiesAddFileHash._indexin(_file_case(ext))) {
         includeItem = 0;
      }
   }

   return includeItem;
}

void _add.lbutton_up()
{
   gFileListModified=1;
   int form_wid=p_active_form;
   _str config=ctlCurConfig.p_text;
   int list_wid=_srcfile_list;

   // init the callback so it clears its cache
   projectPropertiesAddFilesCallback("");

   _str working_dir = absolute(_ProjectGet_WorkingDir(gProjectHandle), _strip_filename(gProjectName, 'N'));
   typeless result=_OpenDialog("-modal",
                      'Add Source Files',// title
                      _last_wildcards,// Initial wildcards
                      def_file_types','EXTRA_FILE_FILTERS,
                      OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                      "", // Default extension
                      ""/*wildcards*/, // Initial filename
                      working_dir, // Initial directory
                      "",
                      "",
                      projectPropertiesAddFilesCallback); // include item callback

   // cleanup after the callback so it clears its cache
   projectPropertiesAddFilesCallback("");

   //chdir(olddir,1);
   if (result=='') return;
   int filelist_view_id=0;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   _str file_spec_list = result;
   while (file_spec_list != '') {
      _str file_spec = parse_file(file_spec_list);
      insert_file_list(file_spec' -v +p -d');
   }
   p_line=0;
   _str path=_strip_filename(gProjectName,'N');
   int FileToNode:[];
   int FilesNode=0;
   _str AutoFolders='';
   int ExtToNodeHashTab:[];
   _str LastExt='';
   int LastNode=0;
   _InitAddFileToConfig(FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);

   list_wid._lbbegin_update();
   for (;;) {
      if (down()) {
         break;
      }
      _str filename='';
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
}

static void updateControlsNofSelected()
{
   _project_nofselected.p_caption=_srcfile_list.p_Nofselected' of '_srcfile_list.p_noflines' Files Selected';

   if (!gLeaveFileTabEnabled) {
      return;
   }
   // If there is nothing in _srcfile_list, disable Remove All button and
   // if there is nothing selected in _srcfile_list, disable Remove button
   ctlproperties.p_enabled=iswildcard(_srcfile_list._lbget_text());
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
/*
   if (_openfn.p_enabled) {
      //If this is disabled, the workspace is associated and the user cannot
      //do this!!!
      updateControlsAssociatedWithSrcFileList();
   }
*/
}

static _str calculateFileSpec(int projectHandle, _str projectName) {
   _str returnVal = '*.*';
   _str configType = '';
   _str configType2 = '';

   if (!_GetAssociatedProjectInfo(projectName, auto associatedFile, auto associatedFileType)) {
      return associatedFileType;
   }

   int i;
   int PrevNode=0;
   int NextNode=0;
   if (ctlCurConfig.p_text==ALL_CONFIGS) {
      for (i=0;i<gConfigList._length();++i) {
         configType2 = _ProjectGet_Type(projectHandle, gConfigList[i]);
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
      configType = _ProjectGet_Type(projectHandle, ctlCurConfig.p_text);
   }

//messageNwait(status' |'AssociatedFileType'|');
   return returnVal;
}

void _addtree.lbutton_up()
{
   int status;
   olddir := getcwd();
   _str working_dir = absolute(_ProjectGet_WorkingDir(gProjectHandle), _strip_filename(gProjectName, 'N'));
   chdir(working_dir,1);

   _str fileSpec = calculateFileSpec(gProjectHandle, gProjectName);


   typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
               'Add Tree',
               fileSpec,
               true,
               true,
               gProjectName,
               !_IsWorkspaceAssociated(_workspace_filename));
   chdir(olddir,1);

   if (result== "") {
      return;
   }
// _param1 - trees to add (array of paths)
// _param2 - recursive?
// _param3 - follow symlinks?
// _param4 - exclude filespecs (array of filespecs)
// _param5 - add as wildcard

   // _param5 specifies whether this tree was added as a wildcard or not
   if (_param5) {
      // add as wildcards!
      addWildcardsToProject(_param1, _param4, _param2, _param3);
   } else {
      addTreeToProject(_param1, _param4, _param2, _param3);
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
   gFileListModified=1;

   // Indicate that the project source file list has been modified:
   mou_hour_glass(0);
   clear_message();
}

static void addWildcardsToProject(_str (&filesList)[], _str (&excludesList)[], boolean recursive, boolean followSymlinks)
{
   WILDCARD_FILE_ATTRIBUTES wfa;
   wfa.Recurse = recursive;

   wfa.Excludes = '';
   for (i := 0; i < excludesList._length(); ++i) {
      wfa.Excludes :+= excludesList[i]';';
   }
   wfa.Excludes = strip(wfa.Excludes, 't', ';');

   for (i = 0; i < filesList._length(); ++i) {
      RelFilename := _RelativeToProject(filesList[i], gProjectName);
      AddFileToConfig(_control _srcfile_list, RelFilename, ctlCurConfig.p_text, null, -1, null, null, null, -1, wfa);
   }
}

static void addTreeToProject(_str (&filesList)[], _str (&excludesList)[], boolean recursive, boolean followSymlinks)
{
   _str ConfigName=ctlCurConfig.p_text;

   // Find all files in tree:
   mou_hour_glass(1);
   message('SlickEdit is finding all files in tree');

   recursiveString := recursive ? '+t' : '-t';
   optimizeString := followSymlinks ? '' : '+o';
   int list_wid=_srcfile_list;

   int formwid=p_active_form;
   int filelist_view_id=0;
   int orig_view_id=_create_temp_view(filelist_view_id);
   p_window_id=filelist_view_id;
   _str orig_cwd=getcwd();
   _str ProjectName=gProjectName;
   _str all_files='';
   int i;
   for (i=0;i<filesList._length();++i) {
      _str file=maybe_quote_filename(strip(absolute(filesList[i]),'B','"'));
      all_files=all_files' 'file;
   }
   if (excludesList._length() > 0) {
      all_files = all_files' -exclude';
      for (i = 0; i < excludesList._length(); ++i) {
         _str file = maybe_quote_filename(strip(excludesList[i], 'B', '"'));
         all_files = all_files' 'file;
      }
   }

   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   status:=insert_file_list(recursiveString' 'optimizeString' +W +L -v +p -d 'all_files);
   if (status==VSRC_OPERATION_CANCELLED) {
      p_window_id=orig_view_id;
      _delete_temp_view(filelist_view_id);
      mou_hour_glass(0);
      clear_message();
      _message_box(get_message(VSRC_OPERATION_CANCELLED));
      return;
   }
   p_line=0;

   int FileToNode:[];
   int FilesNode=0;
   _str AutoFolders='';
   int ExtToNodeHashTab:[];
   _str LastExt='';
   int LastNode=0;
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
      AddFileToConfig(list_wid,relative(filename,_strip_filename(ProjectName,'N')),ConfigName,FileToNode,FilesNode,AutoFolders,ExtToNodeHashTab,LastExt,LastNode);
   }
   list_wid._lbend_update(list_wid.p_Noflines);
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
   gFileListModified=1;
   //Simple case, we are in the "ALL CONFIGS" config, and we just remove the file
   if (ConfigName==ALL_CONFIGS) {
      _xmlcfg_delete(gProjectHandle,Node);
      FileToNode._deleteel(RelativeFilenameCased);
      return;
   }
   _str configs=_xmlcfg_get_attribute(gProjectHandle,Node,'C');
   // IF this file was in all configs
   if (configs=='') {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         strappend(configs,' 'always_quote_filename(gConfigList[i]));
      }
      configs=strip(configs);
   }
   int i=pos(always_quote_filename(ConfigName),configs);
   if (i) {
      _str before='';
      _str after='';
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
   boolean addFile = false;
   boolean findfirst=true;
   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(gProjectHandle,FileToNode);
   while (!_srcfile_list._lbfind_selected(findfirst)) {
      _str AbsoluteFilename=absolute(_srcfile_list._lbget_text(),_strip_filename(gProjectName,'N'));
      _str RelativeFilename=_srcfile_list._lbget_text();
      RemoveFileFromViews(RelativeFilename,ctlCurConfig.p_text,FileToNode);
      _srcfile_list._lbdelete_item();
      _srcfile_list.up();
      findfirst=0;
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
   gFileListModified=1;
   RemoveFiles();
}

_remove_all.lbutton_up()
{
   // Add all files back to openfile_list:
   gFileListModified=1;
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
   boolean yesforall;
   boolean noforall=false;
   removed= 0;
   result=_message_box('Remove deleted files from project without prompt?',"",MB_YESNOCANCEL,IDNO);
   if (result==IDCANCEL) {
      return;
   }
   yesforall= result==IDYES;
   mou_hour_glass(1);
   _srcfile_list._lbtop();
   _srcfile_list._lbup();
   int Noflines=_srcfile_list.p_Noflines;
   _str project_path=_strip_filename(gProjectName,'N');
   int FileToNode:[];
   _ProjectGet_FileToNodeHashTab(gProjectHandle,FileToNode);
   while (!_srcfile_list._lbdown()) {
      _str line;
      line= _srcfile_list._lbget_text();

      int linenum=_srcfile_list.p_line;
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
            RemoveFileFromViews(line,ctlCurConfig.p_text,FileToNode);
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
               RemoveFileFromViews(line,ctlCurConfig.p_text,FileToNode);
            } else if (answer== "YESTOALL") {
               _srcfile_list._lbdelete_item();
               _srcfile_list._lbup();
               modified= 1;
               removed++;
               RemoveFileFromViews(line,ctlCurConfig.p_text,FileToNode);
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
   mou_hour_glass(0);
   if (modified) {
      gFileListModified=1;
   }
}

_invert.lbutton_up()
{
   _srcfile_list._lbinvert();
   _srcfile_list.call_event(CHANGE_SELECTED,_srcfile_list,ON_CHANGE,'');
}

static int okFiles(boolean &doUpdateProjectToolbar)
{
   doUpdateProjectToolbar=false;
   int wid=p_active_form;

   // Update project:
   int status= 0;
   if (gFileListModified || !file_exists(_GetWorkspaceTagsFilename())) {
      doUpdateProjectToolbar=1;  // Could have modified wildcard properties
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
#if __UNIX__
   if (i1.runInXterm != i2.runInXterm) {
      return(1);
   }
#endif
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
   if (last_char(path)!=FILESEP) {
      path=path:+FILESEP;
   }
   _str toDir=_strip_filename(project_name,'n');
   // Just incase path is already relative, convert it to absolute
   path=absolute(path,toDir);
   path=relative(path,toDir);
   if (path=='') {
      return('.');
   }
   return(path);
}
_str _relative_includedirs(_str includedirs,_str project_name=_project_name)
{
   if (project_name=='' || substr(project_name,1,1)=='.') {
      return(includedirs);
   }
   _str resultdirs='';
   for (;;) {
      if (includedirs=='') {
         break;
      }
      _str path='';
      parse includedirs with path (PATHSEP) includedirs;
      if (path=='') path='.';
      path=_relative_workingdir(path,project_name);
      if (resultdirs=='') {
         resultdirs=path;
      } else {
         resultdirs=resultdirs:+PATHSEP:+path;
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
   if (project_name=='' || substr(project_name,1,1)=='.') {
      includedirs=_parse_project_command(includedirs, '', project_name,'');
      return(includedirs);
   }
   _str resultdirs='';
   _str toDir=_strip_filename(project_name,'N');
   for (;;) {
      if (includedirs=='') {
         break;
      }
      _str path='';
      parse includedirs with path (PATHSEP) includedirs;
      path=strip(path);
      if (path=='') path='.';

      if (pos('%',path)) {
         path=_parse_project_command(path, '', project_name,'','','','',recursionStatus,recursionMonitorHash);
         if (path=='') continue;
      } else {
         if (last_char(path)!=FILESEP) {
            path=path:+FILESEP;
         }
         path=absolute(path,toDir);
      }
      if (resultdirs=='') {
         resultdirs=path;
      } else {
         resultdirs=resultdirs:+PATHSEP:+path;
      }
   }
   return(resultdirs);
}

/**
 * Update the build and rebuild commands for the selected build system
 *
 * @return
 */
static void switchBuildSystem(_str configName,_str BuildSystem,_str BuildMakefile)
{
   _str packType = "";
   packType= _ProjectGet_Type(gProjectHandle,configName);
   boolean isJavaProject = strieq(packType, "java");
   boolean isGNUCProject = strieq(packType, "gnuc");
   boolean isVCPPProject = strieq(packType, "vcpp");

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
         _ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,"\"%(VSLICKBIN1)vsbuild\" build \"%w\" \"%r\"",'','');
         _ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,"\"%(VSLICKBIN1)vsbuild\" rebuild \"%w\" \"%r\"",'','');
         break;

      case "automakefile":
         // look for 'gmake' first.  default to 'make' if not found
         _str makeProgram = _findGNUMake();

         // set the makefile name if it wasnt provided
         if(BuildMakefile == "") {
            BuildMakefile = "%rp%rn.mak";
         }

         // build
         _ProjectSet_TargetDialog(gProjectHandle,BuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,BuildNode,makeProgram " -f \"" BuildMakefile "\" CFG=%b",'','');

         // rebuild
         _ProjectSet_TargetDialog(gProjectHandle,RebuildNode,'');
         _ProjectSet_TargetCmdLine(gProjectHandle,RebuildNode,makeProgram " -f \"" BuildMakefile "\" rebuild CFG=%b",'','');

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
   int p= pos("\n",text);
   if (!p) return( "\n" );  // Can't find one so does not matter
   if (p < 2) return( "\n" );
   _str lc= substr(text,p-1,1);
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
   mou_hour_glass(1);
   doOK();
   mou_hour_glass(0);
}

static void doOK()
{
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   _str SectionsList[]=null;
   boolean modified;

   int fid=p_active_form;
   fid.p_enabled=false;
   boolean macrosChanged=false;
   if (!gIsExtensionProject) {
      okMacro(macrosChanged);
      okDirectories();

      // IMPORTANT: it is imperative that okBuildOptions() be called *before*
      //            okFiles().  the reason is an auto-generated makefile may
      //            be added/removed from the file list during okBuildOptions()
      //            and will need to be added/removed from the tag file
      okBuildOptions();

      if (!gIsProjectTemplate) {
         // make sure dependencies are valid
         if(okDependencies() < 0) {
            // do not close the form if an invalid dependency is detected
            fid.p_enabled=true;
            return;
         }
      }
   }
   int status=0;
   if (gIsExtensionProject || gIsProjectTemplate) {  // extension project or project pack
      modified=_xmlcfg_get_modify(gProjectHandle);
      if (gdoSaveIfNecessary && _xmlcfg_get_modify(gProjectHandle)) {
         if (gIsProjectTemplate) {
            status=_ProjectTemplatesSave(gProjectHandle);
         } else {
            status=_ProjectSave(gProjectHandle,'',_ConfigPath():+VSCFGFILE_USER_EXTPROJECTS);
         }
         if (status && p_active_form.p_visible) {
            fid.p_enabled=true;
            return;
         }
      }
      if (gIsExtensionProject) {
         readAndParseAllExtensionProjects();
      }
      // IF this is an extension specific project
      //_project_refresh();
   } else {
      modified=_xmlcfg_get_modify(gProjectHandle);
      boolean doUpdateProjectToolbar=false;
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
         if (file_eq(gProjectName,_project_name)) {
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
      previousConfig=ctlCurConfig.p_text;
   }

   if (previousConfig=='') {
      return;
   }

   typeless status=0;
   if (_proj_prop_sstab.p_ActiveTab == PROJPROPTAB_FILES) {
      if (_IsWorkspaceAssociated(_workspace_filename)) {
         if (reason==CHANGE_TABACTIVATED) {

            // force configuration to "All Configurations"
            ctlCurConfig._lbtop();
            if (ctlCurConfig._lbfind_and_select_item(ALL_CONFIGS)) {
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
   if (ConfigName!=ALL_CONFIGS) {
      _xmlcfg_find_simple_insert(gProjectHandle,VPJX_FILES"//"VPJTAG_F:+XPATH_CONTAINS('C',always_quote_filename(ConfigName),'i')'/@N');
   }
   top();search(FILESEP2,'@',FILESEP);
   //top();search('^','@R',' ');

   _lbsort('-f');
   _lbtop();
   // Update all controls associated with the _srcfile_list
   updateControlsNofSelected();
}

int _MaybeAddFilesToVC(_str NewFiles[])
{
   int status=0;
   int result=0;
   if ( NewFiles._length() &&
        ( ( machine()=='WINDOWS' && _isscc(_GetVCSystemName()) && _SCCProjectIsOpen() ) ||
          _VCSCommandIsValid(VCS_CHECKIN_NEW)) ) {
      result=_message_box(nls("Do you want to add the new files to version control?"),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDYES) {

         if (def_vc_system=='CVS') {
            status=_CVSAdd(NewFiles);
            if (status) return(status);
            result=_message_box(nls("Files added, commit these files now?"),'',MB_YESNO);
            if (result==IDYES) {
               _str comment_filename=mktemp(),tag='',filelist='';
               int i,len=NewFiles._length();
               for (i=0;i<len;++i) {
                  filelist=filelist' 'NewFiles[i];
               }
               filelist=strip(filelist);
               status=_SVCListModified(NewFiles);
               if (status) return(status);
               status=_CVSGetComment(comment_filename,tag,filelist,false);
               if (!status) {
                  _str OutputFilename='';
                  status=_CVSCommit(NewFiles,comment_filename,OutputFilename,true,'',false,null,tag);
                  _SVCDisplayErrorOutputFromFile(OutputFilename,status);
               }
               delete_file(comment_filename);
            }
            return(status);
         }

         result=show('-modal _vc_comment_form',NewFiles[0],1,1);
         if (result=='') {
            return(COMMAND_CANCELLED_RC);
         }
         _str comment=_param1;
         boolean prompt_for_each_comment=!_param2;
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
               int SkipNext=0;
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
   int status=0;
   int result=0;
   int i=0;
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
          _VCSCommandIsValid(VCS_REMOVE)) ) {
      _str msg=nls("Would you like to remove these files from version control?");
      if ( def_vc_system=='CVS' ) {
         msg=nls("Would you like to remove these files from version control?\n\nWARNING:This will also delete the local files");
      }
      result=_message_box(msg,'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDYES) {
         if (_isscc(_GetVCSystemName()) && machine()=='WINDOWS') {
            _SccRemove(DeletedFiles,'');
         } if ( _VCIsSpecializedSystem(def_vc_system) ) {
            _str OutputFilename='';
            status=_SVCRemove(DeletedFiles,OutputFilename,false,null,false,'-f');
            _SVCDisplayErrorOutputFromFile(OutputFilename,status);
            if (status) return(status);
            result=_message_box(nls("Files removed, commit these files now?"),'',MB_YESNO);
            if (result==IDYES) {
               _str comment_filename=mktemp(),tag='',filelist='';
               int len=DeletedFiles._length();
               for (i=0;i<len;++i) {
                  filelist=filelist' 'DeletedFiles[i];
               }
               filelist=strip(filelist);
               status=_CVSGetComment(comment_filename,tag,filelist,false);
               if (!status) {
                  status=_SVCCommit(DeletedFiles,comment_filename,OutputFilename,true,'',false,null,tag);
                  _SVCDisplayErrorOutputFromFile(OutputFilename,status);
               }
               delete_file(comment_filename);
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


#define DEBUG_TAGGING_MESSAGES 0

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
void _CreateProjectFilterTree(int TreeWid,int TreeParentIndex,int ProjectHandle,int Node,int (&ExtToNodeHashTab):[],boolean SetOtherFilesNode=true)
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
         _str ext='';
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
   int OtherFilesNode=-1;
   typeless array;
   _ProjectGet_Folders(handle,array);
   boolean moreThanOne=false;
   int i;
   for (i=0;i<array._length();++i) {
      if (strieq(SkipFolderName,_xmlcfg_get_attribute(handle,array[i],'Name'))) {
         continue;
      }
      _str filters=_xmlcfg_get_attribute(handle,array[i],xmlv.vpjattr_filters);
      if (filters=='') {
         if (OtherFilesNode>=0) {
            moreThanOne=true;
         }
         OtherFilesNode=array[i];
         continue;
      }
      for (;;) {
         _str ext='';
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
   int FilesNode=_ProjectGet_FilesNode(handle,true);
   if (OtherFilesNode<0 || moreThanOne) {
      ExtToNodeHashTab:['']=FilesNode;
   } else {
      ExtToNodeHashTab:['']=OtherFilesNode;
   }
}
int _TagUpdateFromViews(_str TagFilename,
                        int NewFilesViewId,
                        int OrigFilesViewId,
                        boolean InputIsAbsolute,
                        _str project_name=_project_name,
                        _str (&NewFilesList)[]=null,
                        _str (&DeletedFilesList)[]=null,
                        int database_flags=0,
                        boolean useThread=false
                        )
{
   boolean tagFileModified=false;
   int dbstatus=tag_open_db(TagFilename);
   p_window_id=NewFilesViewId;
   int num_files=p_Noflines;
   static _str last_lang;
   _str project_path=_strip_filename(project_name,'N');
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
               #if DEBUG_TAGGING_MESSAGES
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
      int NofLines1=p_Noflines;
      activate_window(OrigFilesViewId);top();up();
      int NofLines2=p_Noflines;

      if (NofLines1+NofLines2+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE) ) {
         _default_option(VSOPTION_WARNING_ARRAY_SIZE,NofLines1+NofLines2+10);
      }
      NewFilesList._makeempty();
      DeletedFilesList._makeempty();
      //_showbuf(OrigFilesViewId);
      top();up();
      boolean done1=false;
      boolean done2=false;
      activate_window(NewFilesViewId);
      _str line1='';
      if (down()) {
         done1=1;
         line1='';
      } else {
         get_line(line1);
         line1=strip(line1);
      }
      activate_window(OrigFilesViewId);
      _str line2='';
      if (down()) {
         done2=1;
         line2='';
      } else {
         get_line(line2);
      }
      line2=strip(line2);
      int buildform_wid=0;
      boolean allowCancel=false;
      if (allowCancel) {
         buildform_wid=_mdi.show_cancel_form(_GetBuildingTagFileMessage(useThread),null,true,true);
      } else {
         buildform_wid=_mdi.show_cancel_form(_GetBuildingTagFileMessage(useThread),'',false,true);
      }
      int max_label2_width=cancel_form_max_label2_width(buildform_wid);
      for (;;) {
         if (cancel_form_cancelled()) {
            break;
         }
         if (done1 && done2) {
            break;
         }
         if (!done1 && !done2 && file_eq(line1,line2)) {
            activate_window(NewFilesViewId);
            if (down()) {
               done1=1;
               line1='';
            } else {
               get_line(line1);
            }
            line1=strip(line1);
            activate_window(OrigFilesViewId);
            if (down()) {
               done2=1;
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
               NewFilesList[NewFilesList._length()]=line1;
               _str filename='';
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
                  #if DEBUG_TAGGING_MESSAGES
                  DebugTaggingMessage('Tagging 'p_line'/'num_files': 'filename);
                  #endif
                  RetagFile(filename,useThread,0,lang);
               }
               activate_window(NewFilesViewId);
               if (down()) {
                  done1=1;
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
            DeletedFilesList[DeletedFilesList._length()]=line2;
            _str filename='';
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
               #if DEBUG_TAGGING_MESSAGES
               DebugTaggingMessage('Removing 'filename' from 'TagFilename);
               #endif
               tag_remove_from_file(filename);
            }
            activate_window(OrigFilesViewId);
            if (down()) {
               done2=1;
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
      tag_close_db(TagFilename,1);

      //_showbuf(addfiles_view_id);_delete_temp_view(addfiles_view_id);
   }
   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   clear_message();
   return(0);
}

//12:08:14 PM 9/13/2000
//Wrote this because I kind of wanted to have these messages in there for quite
//a while so I could see what was going on, but I didn't want to have calls
//to say(made it harder to take out the "short term" calls to say).
static void DebugTaggingMessage(_str Msg)
{
   say(Msg);
}

void _DiffFileListsFromViews(int newFileListViewId, 
                             int origFileListViewId,
                             _str (&newFilesList)[], 
                             _str (&deletedFilesList)[])
{
   _str fileName, fileNameKey;
   _str fileHashTable:[];

   newFileListViewId.save_pos(auto p);
   newFileListViewId.top();
   newFileListViewId._begin_line();
   loop {
      newFileListViewId.get_line(fileName);
      fileNameKey = _file_case(strip(fileName));
      fileHashTable:[fileNameKey] = fileName;
      if (newFileListViewId.down()) break;
   }
   newFileListViewId.restore_pos(p);


   origFileListViewId.save_pos(p);
   origFileListViewId.top();
   origFileListViewId._begin_line();
   loop {
      origFileListViewId.get_line(fileName);
      fileNameKey = _file_case(strip(fileName));

      if (fileHashTable._indexin(fileNameKey)) {
         // if the file is in both views, then it is rather boring.
         fileHashTable._deleteel(fileNameKey);
      } else {
         // if a file was there before and isn't anymore, it is a deleted file.
         deletedFilesList[deletedFilesList._length()] = fileName;
      }

      if (origFileListViewId.down()) break;
   }
   origFileListViewId.restore_pos(p);

   // the files remaining in the hash table are the new files
   foreach (fileName in fileHashTable) {
      newFilesList[newFilesList._length()] = fileName;
   }
}

static int save_source_filenames(int form_wid)
{
   if (gIsExtensionProject || gIsProjectTemplate) return( 0 );
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      return(0);
   }
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id);
      _xmlcfg_find_simple_insert(gProjectHandle,VPJX_FILES"//"VPJTAG_F'/@N');
      top();search(FILESEP2,'@',FILESEP);
      cancel_form_set_parent(form_wid);
      int status=SaveAssociatedProjectFiles(temp_view_id,gProjectName);
      cancel_form_set_parent(0);
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
      return(status);
   }

   int orig_view_id=p_window_id;

   activate_window(gOrigProjectFileList);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);

   int new_all_files_view_id=0;
   GetProjectFiles(gProjectName, new_all_files_view_id,'',null,'',true,true,false,gProjectHandle);

   //_showbuf(new_all_files_view_id);
   activate_window(new_all_files_view_id);
   sort_buffer('-fc');
   _remove_duplicates(_fpos_case);


   cancel_form_set_parent(form_wid);
   _str NewFilesList[];
   _str DeletedFilesList[];
   int database_flags=(def_references_options & VSREF_NO_WORKSPACE_REFS)? 0:VS_DBFLAG_occurrences;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   if (useThread) {

      _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_TAGGING_WORKSPACE, 'Updating workspace tag file', '', 1);
      call_list("_LoadBackgroundTaggingSettings");
      rebuildFlags := VS_TAG_REBUILD_CHECK_DATES;
      if (database_flags == VS_DBFLAG_occurrences) {
         rebuildFlags |= VS_TAG_REBUILD_DO_REFS;
      }

      _DiffFileListsFromViews(new_all_files_view_id, gOrigProjectFileList, NewFilesList, DeletedFilesList);
      _ConvertViewToAbsolute(new_all_files_view_id, _strip_filename(gProjectName, 'n'));
      tag_build_tag_file_from_view(project_tags_filename(), 
                                   rebuildFlags,
                                   new_all_files_view_id);
      if (def_tagging_logging) {
         loggingMessage := nls("Starting background tag file update for '%s1' because file list has been edited", project_tags_filename());
         dsay("BACKGROUND TAGGING(":+_time('M'):+"): ":+loggingMessage, TAGGING_LOG);
      }

   } else {
      _TagUpdateFromViews(project_tags_filename(),new_all_files_view_id,
                          gOrigProjectFileList,false,gProjectName,
                          NewFilesList,DeletedFilesList,database_flags,useThread);
   }

   cancel_form_set_parent(0);
   _delete_temp_view(new_all_files_view_id);
   //_delete_temp_view(old_all_files_view_id);

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


   _AddAndRemoveFilesFromVC(NewFilesList,DeletedFilesList);

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
   _str old_text='';
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
   int wid=p_window_id;
   // TODO: save and restore def_cd variable here
   _str prev_text = "";
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
      int lastIndex=_TreeCurIndex(); // get the index of the <double click... line
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
   int wid=p_window_id;
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return('');
   }
   p_window_id=wid.p_prev;
   if (p_text=="") {
      p_text= result;
   } else {
      p_text= p_text :+ PATHSEP :+ result;
   }
   end_line();
   _set_focus();
   return('');
}
_browsefileconcat.lbutton_up()
{
   int wid=p_window_id;
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
      p_text= p_text :+ PATHSEP :+ result;
   }
   end_line();
   _set_focus();
   return('');
}
_browserefs.lbutton_up()
{
   int wid=p_window_id;
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
         _str item_text=stranslate(child.p_caption,'','&');
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
#if __UNIX__
   return(pos(';'ALLFILES_RE';',';'pattern';',1,_fpos_case));
   /*return(pos(';*.*;',';'pattern';',1,_fpos_case) ||
          pos(';*;',';'pattern';',1,_fpos_case));*/
#else
   return(pos(';'ALLFILES_RE';',';'pattern';',1,_fpos_case));
#endif
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

static boolean IsReadOnly(_str filename)
{
#if __UNIX__
   _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   if (attrs=='') return(0);
   int w=pos('w',attrs,'','i');
   return(w != 0);
#else
   _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   if (attrs=='') return(0);
   int ro=pos('r',attrs,1,'i');
   return(ro != 0);
#endif
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
   int longestWW=0;
   int index=_TreeGetFirstChildIndex(getWorkspaceTreeRootIndex());
   for (;;) {
      if (index<0) {
         break;
      }
      _str nameOnly='';
      _str path='';
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

   _str name='';
   int status=0;
   int doneCount = 0;
   int i = 0;
   typeless t;
   _str FolderName='';
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
   mou_hour_glass(1);

   _str DisplayName=GetProjectDisplayName(projectName);
   _str capname=strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(TREE_ROOT_INDEX,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   int orig_wid=p_window_id;
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
   int check_SCC_Status=0;
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
      boolean BackedUpXMLFilesSection=false;
      int backup_project_handle=-1;
      typeless array;
      _xmlcfg_find_simple_array(_ProjectHandle(projectName),
                                VPJX_FILES"//"VPJTAG_F:+
                                //XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                array,TREE_ROOT_INDEX);
      boolean projectHasWildcards=array._length()!=0;
      _str FoldersToSort:[];
      boolean done=false;
      _str AutoFolders=_ProjectGet_AutoFolders(project_handle);
      boolean CustomView=strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW);
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
            int PrevParentNode= -1;
            for (i=0;i<array._length();++i) {
               boolean Refilter=_xmlcfg_get_attribute(project_handle,array[i],'Refilter',0);
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
         boolean NeedToSort=false;
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
               int orig_view_id=p_window_id;
               int temp_view_id=0;
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
               boolean NodeDoneHashTab:[];
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

   mou_hour_glass(0);
   return(status);
}

#else 

int toolbarBuildPackageFilter(_str projectName, _str (&array)[], int ProjectIndex=-1, _str (*AllDependencies):[]=null)
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

   _SetProjTreeColWidth();

   _str name='';
   int status=0;
   int doneCount = 0;
   int i = 0;
   typeless t;
   _str FolderName='';
   //This code was dead.
   _proj_tooltab_tree._TreeSetInfo(workspace_index, TREE_NODE_EXPANDED);
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
   mou_hour_glass(1);

   _str DisplayName=GetProjectDisplayName(projectName);
   _str capname=_strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(workspace_index,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   int orig_wid=p_window_id;
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
   int check_SCC_Status=0;
#endif
   /*
      - Don't insert Refilter=1 wildcard files
      - Expand wildcards other wildcards
   */
   int project_handle=_ProjectHandle(projectName);
   int ExtToNodeHashTab:[];
   boolean BackedUpXMLFilesSection=false;
   int backup_project_handle=-1;
   _str FoldersToSort:[];
   boolean done=false;
   _str AutoFolders=_ProjectGet_AutoFolders(project_handle);
   boolean CustomView=strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW);
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
            status=_GetEclipsePathList(_strip_filename(projectName,'N'),pathList);
         }else{
            pathList[0]=_strip_filename(projectName,'N');
         }
         int folderNodeHash:[];
         int PrevParentNode= -1;
         for (i=0;i<array._length();++i) {
            if (!def_refilter_wildcards || !CustomView) {
               if (!BackedUpXMLFilesSection) {
                  BackedUpXMLFilesSection=true;
                  backup_project_handle=_xmlcfg_create('',VSENCODING_UTF8);
                  _xmlcfg_copy(backup_project_handle,TREE_ROOT_INDEX,project_handle,_ProjectGet_FilesNode(project_handle),VSXMLCFG_COPY_CHILDREN);
               }
               //_message_box('got here F='_xmlcfg_get_attribute(project_handle,array[i],'N'));
               int ParentNode=_xmlcfg_get_parent(project_handle,(int)array[i]);
               if (PrevParentNode!=ParentNode) {
                  PrevParentNode=ParentNode;
                  name=_xmlcfg_get_attribute(project_handle,ParentNode,"Name");
                  folderNodeHash=null;
               }
               _ExpandFileView2(project_handle,(int)array[i],_xmlcfg_get_attribute(project_handle,(int)array[i],'N'),pathList,true,false,false,folderNodeHash);
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
      boolean NeedToSort=false;
      if (BackedUpXMLFilesSection) {
         int FilesNode=_ProjectGet_FilesNode(project_handle);
         _xmlcfg_delete(project_handle,FilesNode,true);
         _xmlcfg_copy(project_handle,FilesNode,backup_project_handle,TREE_ROOT_INDEX,VSXMLCFG_COPY_CHILDREN);
      }
      if (CustomView) {
         /*
            - Expand wildcards
         */
         typeless refiltered;
         if (def_refilter_wildcards) {
            _xmlcfg_find_simple_array(project_handle,
                                      VPJX_FILES"//"VPJTAG_F:+
                                      //XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                      XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                      refiltered,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
         }
         if (refiltered._length()) {
            int orig_view_id=p_window_id;
            int temp_view_id=0;
            _create_temp_view(temp_view_id);
            activate_window(temp_view_id);
            for (i=0;i<refiltered._length();++i) {
               insert_line(translate(refiltered[i],FILESEP,FILESEP2));
            }

            _str pathList[];
            if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
               status=_GetEclipsePathList(_strip_filename(projectName,'N'),pathList);
            }else{
               pathList[0]=_strip_filename(projectName,'N');
            }
            _ExpandFileView(project_handle,temp_view_id,pathList,0);

            _ConvertViewToAbsolute(temp_view_id,_strip_filename(projectName,'N'),0,0);
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
            boolean NodeDoneHashTab:[];
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

      tree_wid._TreeRemoveDuplicatesSpecial(ProjectIndex);
   }
   return(status);
}

static void _SortFolders(int parentIndex, boolean CustomView, boolean PackageView)
{
   if (CustomView) {
      // sort top level files, folders first (no sort folders)
      _TreeSortCaption(parentIndex, 'F=');

      // sort all subfolders
      int index = _TreeGetFirstChildIndex(parentIndex);
      while (index >= 0) {
         if (_projecttbIsFolderNode(index)) {
            // TBF:  The limit should be customizable
            if (!CustomView || _TreeGetNumChildren(index) < 1000) {
               _TreeSortCaption(index,'FPT');
            }
         }
         index = _TreeGetNextSiblingIndex(index);
      }
   } else if (PackageView) {
      _TreeSortCaption(parentIndex);
   } else {
      // sort all recursively
      _TreeSortCaption(parentIndex, 'FPT');
   }
}

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

   _str name='';
   int status=0;
   int doneCount = 0;
   int i = 0;
   typeless t;
   _str FolderName='';
   //This code was dead.
   _proj_tooltab_tree._TreeSetInfo(workspace_index, TREE_NODE_EXPANDED);
   mou_hour_glass(1);

   _str DisplayName=GetProjectDisplayName(projectName);
   _str capname=_strip_filename(DisplayName,'p')"\t"_RelativeToWorkspace(DisplayName);

   if (ProjectIndex<0) {
      ProjectIndex=_proj_tooltab_tree._TreeSearch(workspace_index,capname,_fpos_case);
      if (ProjectIndex<0) {
         return(0);
      }
   }

   int orig_wid=p_window_id;
   p_window_id=_proj_tooltab_tree;
   int tree_wid=_proj_tooltab_tree;
   tree_wid._TreeBeginUpdate(ProjectIndex,'','T');

   projectName=VSEProjectFilename(projectName);
//1:45pm 3/1/2000
//Using a 0 for this parameter defeats querying an SCC version control system
//for the icon to use for each file.  This will increase performance when using
//slower version control systems.  There may be an option for this in the future.
#if 1
   int check_SCC_Status=_isscc();
#else
   int check_SCC_Status=0;
#endif
   needSort := false;
   int project_handle=-1;
   _str AutoFolders="";
   boolean CustomView=false;
   boolean PackageView=false;

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
      boolean buildPackages=false;
      typeless array;
      if (PackageView) {
         _xmlcfg_find_simple_array(_ProjectHandle(projectName),
                                   VPJX_FILES"//"VPJTAG_F:+
                                   //XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                   XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                   array,TREE_ROOT_INDEX);
         buildPackages = (array._length()!=0);
      }

      if (buildPackages) {
         status = toolbarBuildPackageFilter(projectName, array, ProjectIndex, AllDependencies);

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
         _xmlcfg_find_simple_array(project_handle,
                                   VPJX_FILES"//"VPJTAG_F:+
                                   XPATH_CONTAINS('N','['_escape_re_chars(WILDCARD_CHARS)']','r'),
                                   array, TREE_ROOT_INDEX);
      }
   }
   _TreeEndUpdate(ProjectIndex);
   if ( needSort ) _SortFolders(ProjectIndex, CustomView, PackageView);

   tree_wid._toolbarUpdateDependencies2(ProjectIndex, AllDependencies);
   p_window_id=orig_wid;

   mou_hour_glass(0);
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
   _str projectPath=_strip_filename(_projecttbTreeGetCurProjectName(index,false),'N');
   _str caption,fullPath;
   _str fullPath2='';

   caption= _TreeGetCaption(index);
   _str name='';
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
      if (file_eq(fullPath,fullPath2)) {
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
   int state=0;
   int bm1=0, bm2=0;
   for (;;) {
      if (index<0) {
         break;
      }
      _TreeGetInfo(index,state,bm1,bm2);
      if (bm1==_pic_project) {
         DeleteIndexes[DeleteIndexes._length()]=index;
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   int i;
   for (i=0;i<DeleteIndexes._length();++i) {
      _TreeDelete(DeleteIndexes[i]);
   }
}

static int InsertAtBottom(int ParentIndex,_str NewCap,int BmIndex1,int BmIndex2,
                          int State=TREE_NODE_LEAF)
{
   int BottomIndex=_TreeGetFirstChildIndex(ParentIndex);
   if (BottomIndex<0) {
      int NewIndex=_TreeAddItem(ParentIndex,NewCap,TREE_ADD_AS_CHILD,BmIndex1,BmIndex2,State);
      return(NewIndex);
   }
   int LastIndex=-1;
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
         list=maybe_quote_filename(array[i]);
      } else {
         strappend(list,' 'maybe_quote_filename(array[i]));
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
   _str ProjectName=_projecttbTreeGetCurProjectName(index);
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

   boolean isEclipse=_IsEclipseWorkspaceFilename(_workspace_filename);
   _str Filename=i;
   _str Cap='';
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
      _str NewCap=_strip_filename(strip(cur,'B','"'),'P')"\t"strip(cur,'B','"');
      InsertAtBottom(index,NewCap,_pic_project,_pic_project);
   }
}
void toolbarUpdateDependencies()
{
   int oriWindowId= p_window_id;
   int formid= _find_object("_tbprojects_form","N");
   if (!formid) {
      p_window_id= oriWindowId;
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

   boolean isEclipse=_IsEclipseWorkspaceFilename(_workspace_filename);
   // Add dependencies that are needed
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._isempty()) {
         break;
      }
      _str Filename=i;
      _str Cap='';
      if (isEclipse) {
         Cap=_strip_filename(Filename,'PE')"\t"_strip_filename(_AbsoluteToWorkspace(Filename),'N');
      }else{
         Cap=_strip_filename(Filename,'P')"\t"_AbsoluteToWorkspace(Filename);
      }
      workspace_index := formid._proj_tooltab_tree.getWorkspaceTreeRootIndex();
      int index=formid._proj_tooltab_tree._TreeSearch(workspace_index,Cap,_fpos_case);
      int ShowChildren=0;
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
               _str NewCap=_strip_filename(strip(cur,'B','"'),'P')"\t"strip(cur,'B','"');
               formid._proj_tooltab_tree.InsertAtBottom(index,NewCap,_pic_project,_pic_project);
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
      _str cap=_TreeGetCaption(index);
      if (!HandledProjects._indexin(_file_case(cap))) {
         DeleteChildWithBMIndex(index,_pic_project);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   p_window_id=oriWindowId;
}

static void DeleteChildWithBMIndex(int TreeIndex,int BMIndex)
{
   int cindex=_TreeGetFirstChildIndex(TreeIndex);
   int state=0;
   int bm1=0, bm2=0;
   for (;;) {
      if (cindex<0) return;
      _TreeGetInfo(cindex,state,bm1,bm2);
      int nextindex=_TreeGetNextSiblingIndex(cindex);
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
 * @param projectIndex     Index of project node in project tool window
 * @param formid           Window ID of project tool window form 
 * @param AllDependencies  (optional) Used to cache workspace-wide 
 *                         project dependencies 
 *
 * @return 0 on success, <0 otherwise
 */
int toolbarUpdateFilterList(_str projectName,
                            int projectIndex=-1,int formid=-1,
                            _str (*AllDependencies):[]=null)
{
   int oriWindowId= p_window_id;

   //int formid;
   if (formid<0) {
      formid= _find_object("_tbprojects_form","N");
      if (!formid) {
         p_window_id= oriWindowId;
         return(0);
      }
   }
   _nocheck _control _proj_tooltab_tree;
   p_window_id= formid._proj_tooltab_tree.p_window_id;

   // Delete all level 1 nodes in tree view and remember the expansion list:
   int expansionModeList[];
   _str expansionNameList[];
   workspace_index := formid._proj_tooltab_tree.getWorkspaceTreeRootIndex();
   childL1 := formid._proj_tooltab_tree._TreeGetFirstChildIndex(workspace_index);
   caption := "";
   if (childL1>=0) {
      caption = formid._proj_tooltab_tree._TreeGetCaption(childL1);
   }
   // Since we don't use the "real" root anymore, now we have to check for
   // "no workspace open".  We actually do need both cases here.
   if ( caption=="" || caption=="No workspace open" ) {
      toolbarUpdateWorkspaceList();
      p_window_id= oriWindowId;
      return(0);
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
      longestWW= formid._proj_tooltab_tree._text_width(text);
      //formid._proj_tooltab_tree._TreeSetCaption(workspace_index, text);
      formid._proj_tooltab_tree._TreeColWidth(0, longestWW + PROJECTTREEADJUSTCOLUMNWIDTH);
      p_window_id= oriWindowId;
      return(0);
   }

   // Reset expansion state:
   _RestoreProjTreeStates(States, AllDependencies);
   _TreeRestorePos(p);
   _TreeSizeColumnToContents(0);
   p_window_id= oriWindowId;
   //toolbarUpdateDependencies();
   return(0);
}

//Start DANS STUFF
void _actapp_makefile(_str gettingFocus='')
{
   if (!gettingFocus) return;
   if (!def_actapp) {
      return;
   }
   if (!(def_autotag_flags2 & AUTOTAG_WORKSPACE_NO_ACTIVATE)) {
      _MaybeRetagWorkspace(arg(1));
   }
}
int _OnUpdate_project_add_file(CMDUI &cmdui,int target_wid, _str command)
{
   _str cmdname='';
   _str filename='';
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

boolean _FileExistsInCurrentProject(_str filename,_str ProjectName=_project_name)
{
   int orig_view_id=p_window_id;
   int FileViewId=0;
   GetProjectFiles(ProjectName,FileViewId);
   p_window_id=FileViewId;
   top();up();
   int status=search('^'_escape_re_chars(filename)'$','@r'_fpos_case);
   p_window_id=orig_view_id;
   _delete_temp_view(FileViewId);
   return(!status);
}

boolean _FileExistsInCurrentWorkspace(_str filename,_str WorkspaceName=_workspace_filename)
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

_command int project_add_files_prompt_project(_str files = "", _str project = '') name_info(',')
{
   // If no filename, then get the current buffer name
   if (files == '') {
      files = p_buf_name;

      // no buffer name?
      if (files == '') {
         _message_box("Buffer has no name","Error",MB_OK|MB_ICONEXCLAMATION);
         return 1;
      }
   }

   // we might have multiple files here, let's split them up
   _str fileList[];
   split(files, PATHSEP, fileList);

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

      curProject := _strip_filename(_project_name, 'P');
      result := _mdi.comboBoxDialog('Add file to project', 'Select a project to add the file', projects, 0, curProject, 'strip_filename');
      if (result == IDOK) {
         if (justNamesToRelNames._indexin(_param1)) {
            project = justNamesToRelNames:[_param1];
         } 
      }
   }

   if (project != '') {
      // make it absolute to the workspace
      workspaceDir := _strip_filename(_workspace_filename, 'N');
      project = absolute(project, workspaceDir);

      for (i := 0; i < fileList._length(); i++) {
         // strip off the quotes, if they are there
         filename := strip(fileList[i], 'B', '"');
         if (filename != '') {
            project_add_file(filename, false, project);
         }
      }
   } else {
      return COMMAND_CANCELLED_RC;
   }

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
_command int project_add_file(_str newfilename="",boolean quiet=false,_str ProjectName=_project_name, _str& msg=null)
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
   boolean FileExists=true;
   if (!file_exists(newfilename)) {
      if(buf_match(newfilename,1,'hx')=='') {
         msg=nls("File %s does not exist or has not been saved",newfilename);
         if (!quiet) {
            _message_box(msg,"Error",MB_OK|MB_ICONEXCLAMATION);
         }
         return 1;
      }
      FileExists=false;
   }
   if (_FileExistsInCurrentProject(newfilename,ProjectName)) {
      msg=nls("The file %s already exists in project %s",newfilename,_project_name);
      if (!quiet) {
         _message_box(msg,0,MB_OK|MB_ICONEXCLAMATION);
      }
      return 2;
   }
   int status = 0;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _str tag_filename=_GetWorkspaceTagsFilename();
   if (FileExists) {
      status=tag_add_filelist(tag_filename,maybe_quote_filename(newfilename),ProjectName,useThread);
   }else{
      status=tag_add_new_file(tag_filename,newfilename,ProjectName,true,useThread);
   }
   call_list("_project_file_add", ProjectName, newfilename);
   //p_window_id.call_list("_prjupdate_");
   //toolbarUpdateFilterList(_project_name);
   //_TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
   //_TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   return 0;
}

int _OnUpdate_project_add_item(CMDUI &cmdui, int target_wid, _str command)
{
   // Might make this an option at some point
   boolean requireProject = true;
   if( requireProject && _project_name!="" && _CanWriteFileSection(_project_name) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command int project_add_item(_str templatePath="", _str itemName="", _str itemLocation="", boolean quiet=false, _str projectName=_project_name)
{
   int was_recording = _macro();
   // Delete recorded call to project_add_item()
   _macro_delete_line();

   // Note:
   // No need to error-check templatePath, itemName since add_item()
   // will do that for us.

   // Might make this an option at some point
   boolean requireProject = true;
   if( requireProject && projectName=="" ) {
      if( !quiet ) {
         _str msg = "Missing project.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return(INVALID_ARGUMENT_RC);
   }

   boolean addToProject = false;
   if( projectName!="" ) {
      projectName=absolute(projectName);
      if( projectName != absolute(_project_name) ) {
         // Only support adding items to the current project for now
         if( !quiet ) {
            _str msg = "Only the current project can add items.";
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return(INVALID_ARGUMENT_RC);
      }
      if( itemLocation=="" ) {
         itemLocation=_ProjectGet_WorkingDir(_ProjectHandle());
      }
      itemLocation=_AbsoluteToProject(itemLocation);
      // Inform the Add New Item dialog that we will be adding to the project.
      // Note that this can be overridden by the user.
      addToProject=true;
   } else {
      addToProject=false;
   }
   int status = add_item(templatePath,itemName,itemLocation,addToProject,quiet);
   if( status == 0 ) {
      // Turn macro recording back on and insert custom recorded call
      _macro('m',was_recording);
      if( addToProject ) {
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
                     quiet);
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
                     addToProject,
                     quiet,
                     0);
      }
   }
   return status;
}

_command void project_config(_str ProjectFilename=_project_name)  name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (_DebugMaybeTerminate()) return;
   mou_hour_glass(1);
   //_convert_to_relative_project_file(ProjectFilename);
   ProjectFilename=strip(ProjectFilename,'B','"');
   gProjectFilesNotNeeded=true;
   int project_prop_wid=show('-hidden -app -xy _project_form',ProjectFilename,_ProjectHandle(ProjectFilename));
   mou_hour_glass(0);
   int ctlbutton_wid=project_prop_wid._find_control('ctlconfigurations');
   typeless result=ctlbutton_wid.call_event('',ctlbutton_wid,LBUTTON_UP,'W');
   if (result=='') {
      project_prop_wid._opencancel.call_event(project_prop_wid._opencancel,LBUTTON_UP,'W');
   } else {
      project_prop_wid._ok.call_event(project_prop_wid._ok,LBUTTON_UP,'W');
   }
   gProjectFilesNotNeeded=false;
}

/**
 * Search for a file in any project in the specified workspace
 *
 * @param filename File to search for
 * @param workspaceName
 *                 Workspace path
 * @param matchPathSuffix  When true, path suffix specified in
 *                         filename must match path of workspace
 *                         file.
 *
 * @return Filename if found
 */
_str _WorkspaceFindFile(_str filename, _str workspaceName = _workspace_filename,
                        boolean checkPath=true, boolean excludeCurrentProject=false,
                        boolean returnAll=false,boolean matchPathSuffix=false)
{
   _str projectList[] = null;
   _GetWorkspaceFiles(workspaceName, projectList);

   int i = 0;
   _str foundFileHash:[] = null;
   for(i = 0; i < projectList._length(); i++) {
      // check if this project should be skipped
      projectName := _AbsoluteToWorkspace(projectList[i], workspaceName);
      if (excludeCurrentProject && workspaceName==_workspace_filename && file_eq(projectName, _project_name)) {
         continue;
      }
      // search this project for the file
      _str foundFileList = _projectFindFile(workspaceName, projectName, filename, (int)checkPath, 1, 1);
      foreach (auto quotedFile in foundFileList) {
         quotedFile = strip(quotedFile, "B", "\"");
         foundFileHash:[quotedFile] = quotedFile;
      }
   }

   // build array of files to send to _sellist_form
   _str foundFileList[] = null;
   typeless j;
   for(j._makeempty();;) {
      foundFileHash._nextel(j);
      if(j._isempty()) break;

      foundFileList[foundFileList._length()] = j;
   }

   if (returnAll) {
      _str result = "";
      foreach (j in foundFileList) {
         if (result != '') result :+= ' ';
         result :+= maybe_quote_filename(j);
      }
      return result;
   }

   // sort the array
   foundFileList._sort("F");

   // if found more than one, prompt the user for which one
   if(foundFileList._length() > 1) {
      // prompt the user for the file
      return show("-modal _sellist_form", "Select filename", SL_SELECTCLINE, foundFileList);

   // if only found one
   } else if(foundFileList._length() == 1) {
      return foundFileList[0];
   }

   // nothing found
   return "";
}

/**
 * First searches the current project for <i>filename</i>,
 * then the current workspace.  If that fails, it reduces
 * <i>filename</i> to it's basename and searches again.
 * If that fails, it searches include paths as defined by
 * the current project.
 *
 * @param filename         path of file to search for
 * @param searchIncludes   search the project include paths
 * @param strict           search only for exact matches,
 *                         do not strip path from filename
 *
 * @return '' if not found, otherwise, the absolute path
 *         to <i>filename</i>.
 *
 * @categories Project_Functions
 */
_str _ProjectWorkspaceFindFile(_str filename,
                               boolean searchIncludes=true,
                               boolean strict=false)
{
   if (isEclipsePlugin()) {
      _str found_filename='';
      _eclipse_ProjectWorkspaceFindFile(_strip_filename(filename,'P'),found_filename);
      return found_filename;
   }
   // if not found, search for file in the current project
   _str found_filename=_projectFindFile(_workspace_filename, _project_name, filename);
   if (found_filename!='') {
      return found_filename;
   }

   // if not found, search for file in the current workspace
   // exclude the current project, we have already searched it.
   found_filename=_WorkspaceFindFile(filename, _workspace_filename, true, true);
   if (found_filename!='') {
      return found_filename;
   }

   // if not found, search for file (by name only) in the current project
   _str filename_only = _strip_filename(filename,'P');
   if (!strict) {
      found_filename=_projectFindFile(_workspace_filename, _project_name, filename_only, 0);
      if (found_filename!='') {
         return found_filename;
      }

      // if not found, search for file (by name only) in the current workspace
      found_filename=_WorkspaceFindFile(filename_only, _workspace_filename, false, true);
      if (found_filename!='') {
         return found_filename;
      }
   }

   // if not found, search include paths
   _str info=_ProjectGet_IncludesList(_ProjectHandle(),_project_get_section(gActiveConfigName));
   info=_absolute_includedirs(info, _project_get_filename());
   found_filename=include_search(filename,info);
   if(found_filename!='') {
      return found_filename;
   }

   // no match
   return '';
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
_command int show_file_in_projects_tb(boolean quiet = def_show_all_proj_with_file) name_info(',')
{
   // look in the workspace for files with this name
   filename := p_buf_name;
   _str projArray[] = _WorkspaceFindAllProjectsWithFile(filename, _workspace_filename, true);
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
   tree := _find_object('_tbprojects_form._proj_tooltab_tree');
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
         projCaption := _strip_filename(projName, 'P') :+ "\t" :+ projName;

         // now search!
         index := tree._TreeSearch(workspace_index, projCaption, 'T');
         if (index != -1) {
            if (tree._projecttbIsProjectNode(index)
                && tree._TreeGetFirstChildIndex(index) < 0) {
               tree.toolbarBuildFilterList(tree._projecttbTreeGetCurProjectName(index), index, &AllDependencies);
               // Rebuilding the filter list for the project just expanded
               // will re-set the current index. Refocus the project node
               tree._TreeSetCurIndex(index);
            }
         } else {
            message('No project containing the file ' :+ filename);
            return 1;
         }

         // we are searching for a caption of this form
         caption := _strip_filename(filename, 'P') :+ "\t" :+ filename;
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
 * Search for a file in all projects in the specified workspace.
 *
 * @param filename   File to search for
 * @param workspaceName
 *                   Workspace path
 * @param isAbsolute T if the specified filename is an absolute path
 *
 * @return array of projects containing the given file
 *
 * @categories Project_Functions
 */
STRARRAY _WorkspaceFindAllProjectsWithFile(_str filename, _str workspaceName = _workspace_filename,
                                           boolean isAbsolute = false)
{
   _str projectList[] = null;
   _GetWorkspaceFiles(workspaceName, projectList);
   int i = 0;
   _str foundFileHash:[] = null;
   for(i = 0; i < projectList._length(); i++) {
      _str projectName = _AbsoluteToWorkspace(projectList[i], workspaceName);

      // if the filename was absolute, make it relative to the project first
      _str relativeFilename = filename;
      if(isAbsolute) {
         relativeFilename = _RelativeToProject(relativeFilename, projectName);
      }

      // search this project for the file
      if(_projectFindFile(workspaceName, projectName, relativeFilename) != "") {
         foundFileHash:[projectName] = projectName;
      }
   }

   // build array of files to send to _sellist_form
   _str foundFileList[] = null;
   typeless j;
   for(j._makeempty();;) {
      foundFileHash._nextel(j);
      if(j._isempty()) break;

      foundFileList[foundFileList._length()] = j;
   }

   // sort the array
   foundFileList._sort("F");
   return foundFileList;
}

/**
 * Search for a file in any project in the specified workspace
 *
 * @param filename   File to search for
 * @param workspaceName
 *                   Workspace path
 * @param isAbsolute T if the specified filename is an absolute path
 * @param quiet      T if we should just take the first match
 *
 * @return Project containing the file if found
 *
 * @categories Project_Functions
 */
_str _WorkspaceFindProjectWithFile(_str filename, _str workspaceName = _workspace_filename,
                                   boolean isAbsolute = false, boolean quiet = false)
{
   _str foundFileList[] = _WorkspaceFindAllProjectsWithFile(filename, workspaceName, isAbsolute);

   // if found more than one, prompt the user for which one
   if(foundFileList._length() >= 1) {
      if (foundFileList._length() == 1) {
         return foundFileList[0];
      }

      // we know we have several projects, so we default to the current one
      if (quiet) {            // ssssh, we're hunting wabbits...
         if (_inarray(_project_name, foundFileList)) {
            return _project_name;
         } else return foundFileList[0];     // didn't find it, so pick the first thing we found
      }

      // prompt the user for the file
      return show("-modal _sellist_form", "Select project", SL_SELECTCLINE, foundFileList);
   }

   // nothing found
   return "";
}

/**
 * Returns list built from the tree delimited by the specified
 * delimiter.
 *
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param delimiter
 *
 * @return
 */
_str _TreeGetDelimitedItemList(_str delimiter)
{
   _str list = '';
   if(p_window_id._TreeGetNumChildren(TREE_ROOT_INDEX) > 0) {
      int index = p_window_id._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for(; index >= 0; ) {
         // get the caption and skip the node reserved for new entry
         //if(!strieq(caption, BLANK_TREE_NODE_MSG)) {
         if (!isItemBold(index)) {
            _str caption = p_window_id._TreeGetCaption(index);
            if(list != '') {
               list = list :+ delimiter :+ caption;
            } else {
               list = caption;
            }
         }

         // move to next node
         index = p_window_id._TreeGetNextSiblingIndex(index);
      }
   }

   return list;
}


/*void _TreeAddNodeList(int handle,int (&NodeArray)[], _str AttrName, boolean allowDuplicates = false)
{
   // remove previous list items
   p_window_id._TreeDelete(TREE_ROOT_INDEX, 'C');

   for(i=0;i<NodeArray._length();++i) {
      // make sure the node isnt already in the tree if duplicates are not allowed
      value=_xmlcfg_get_attribute(handle,AttrName);
      if (value!='') {
         if(!allowDuplicates && p_window_id._TreeSearch(TREE_ROOT_INDEX, value) >= 0) {
            continue;
         }

         p_window_id._TreeAddListItem(value);
      }
   }

   // add the node for new data
   int newIndex = p_window_id._TreeAddListItem(BLANK_TREE_NODE_MSG);
   p_window_id._TreeSetInfo(newIndex, 0, -1, -1, TREENODE_BOLD);
} */
/**
 * Builds the tree from the list delimited by the specified
 * delimiter.
 *
 * IMPORTANT: p_window_id *must* be a tree control
 *
 * @param list      List of items to be entered into the tree
 * @param delimiter Delimiter separating each item in the list
 * @param allowDuplicates
 *                  Allow duplicate nodes in the tree
 */
void _TreeSetDelimitedItemList(_str list, _str delimiter, boolean allowDuplicates = false, _str lockedItems = '')
{
   // turn off edit in place so that callbacks do nothing
   orig_EditInPlace := p_EditInPlace;
   p_EditInPlace = false;

   // remove previous list items
   p_window_id._TreeDelete(TREE_ROOT_INDEX, 'C');

   _str node;
   int newIndex;

   for(;;) {
      if(lockedItems == '') {
         break;
      }
      parse lockedItems with node (delimiter) lockedItems;
      if(node != '') {
         // make sure the node isnt already in the tree if duplicates are not allowed
         if(!allowDuplicates && p_window_id._TreeSearch(TREE_ROOT_INDEX, node) >= 0) {
            continue;
         }

         newIndex = p_window_id._TreeAddListItem(node);
         p_window_id._TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
      }
   }

   for(;;) {
      if(list == '') {
         break;
      }
      parse list with node (delimiter) list;
      if(node != '') {
         // make sure the node isnt already in the tree if duplicates are not allowed
         if(!allowDuplicates && p_window_id._TreeSearch(TREE_ROOT_INDEX, node) >= 0) {
            continue;
         }

         p_window_id._TreeAddListItem(node);
      }
   }

   if (orig_EditInPlace && p_window_id.p_enabled) {
      // add the node for new data
      newIndex = p_window_id._TreeAddListItem(BLANK_TREE_NODE_MSG);
      p_window_id._TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
   }

   // restore the edit option
   p_EditInPlace = orig_EditInPlace;
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
/**
 * Converts a space delimited list of files to semicolons.  If the input list already
 * has semicolons, the list is return unchanged.
 *
 * @param result
 *
 * @return
 */
_str _SpaceDelimitedFileList(_str FileList)
{
   if (!pos(';',FileList)) {
      return(FileList);
   }
   _str result='';
   for (;;) {
      if (FileList=='') {
         break;
      }
      _str file='';
      parse FileList with file';' FileList;
      if (file!='') {
         if (result=='') {
            result=maybe_quote_filename(file);
         } else {
            result=result:+' ':+maybe_quote_filename(file);
         }
      }
   }
   return(result);


}
/**
 * Converts a space delimited list of files to semicolons.  If the input list already
 * has semicolons, the list is return unchanged.
 *
 * @param result
 *
 * @return
 */
_str _SemicolonDelimitedFileList(_str FileList)
{
   if (pos(';',FileList)){
      return(FileList);
   }
   _str semicolons_result='';
   for (;;) {
      if (FileList=='') {
         break;
      }
      _str file=parse_file(FileList,false);
      if (file!='') {
         if (semicolons_result=='') {
            semicolons_result=file;
         } else {
            semicolons_result=semicolons_result:+';':+file;
         }
      }
   }
   return(semicolons_result);
}

static void resizeProjectProperties(int &widthDiff, int &heightDiff)
{
   // get form width and height in twips
   form_width  := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   form_height := _dy2ly(SM_TWIP,p_active_form.p_client_height);
   border_width  := p_active_form.p_width - form_width;
   border_height := p_active_form.p_height - form_height;

   // border/padding constants for spacing controls
   pad_x := _ok.p_x;
   pad_y := ctlconfigurations.p_y;

   widthDiff = form_width - _proj_prop_sstab.p_x - _proj_prop_sstab.p_width;
   heightDiff = form_height - _ok.p_height - pad_y - _ok.p_y;

   // resizing configurations combo box and button
   ctlCurConfig.p_width += widthDiff;
   ctlconfigurations.p_x += widthDiff;

   // resize main tab control
   _proj_prop_sstab.p_width += widthDiff;
   _proj_prop_sstab.p_height += heightDiff;

   // position buttons
   _ok.p_y += heightDiff;
   _opencancel.p_y = _ok.p_y;
   ctlhelp.p_y = _ok.p_y;
   ctlfolders.p_y = _ok.p_y;
}
static void resizeFilesTab(int widthDiff, int heightDiff)
{
   _srcfile_list.p_width += widthDiff;
   _project_nofselected.p_x = _srcfile_list.p_x + _srcfile_list.p_width - _project_nofselected.p_width;

   _srcfile_list.p_height += heightDiff;
   ctlimport.p_y += heightDiff;

   _add.p_x += widthDiff;
   _addtree.p_x = _add.p_x;
   _invert.p_x = _add.p_x;
   _remove.p_x = _add.p_x;
   _remove_all.p_x = _add.p_x;
   ctlrefresh.p_x = _add.p_x;
   ctlproperties.p_x = _add.p_x;
   ctlimport.p_x = _add.p_x;
}
static void resizeDirectoriesTab(int widthDiff, int heightDiff)
{
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
   ctlBrowseUserIncludes.p_x += widthDiff;
   ctlMoveUserIncludesUp.p_x =ctlBrowseUserIncludes.p_x;
   ctlMoveUserIncludesDown.p_x = ctlBrowseUserIncludes.p_x;
   ctlRemoveUserIncludes.p_x = ctlBrowseUserIncludes.p_x;

}
static void resizeToolsTab(int widthDiff, int heightDiff)
{
   ctlHelpLabelTools.p_y += heightDiff;
   ctlHelpLabelTools.p_width += widthDiff;

   ctlAppTypeLabel.p_y += heightDiff;
   ctlAppType.p_y += heightDiff;
   ctlAppType.p_width += widthDiff;

   ctlToolHideCombo.p_y += heightDiff;
   ctlToolSaveCombo.p_y += heightDiff;
   ctlCaptureOutputFrame.p_y += heightDiff;

   ctlRunInXterm.p_y += heightDiff;
   ctlToolBeep.p_y += heightDiff;
   ctlToolVerbose.p_y += heightDiff;
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

   ctlToolUp.p_x += widthDiff;
   ctlToolDown.p_x += widthDiff;
   ctlToolDelete.p_x += widthDiff;
   ctlToolNew.p_x += widthDiff;
   ctlToolAdvanced.p_x += widthDiff;
}
static void resizeBuildTab(int widthDiff, int heightDiff)
{
   ctlBuildSystem.p_y += heightDiff;
   ctlBuildSystem.p_width += widthDiff;
   ctlAutoMakefile.p_width += widthDiff;
   ctlAutoMakefileButton.p_x += widthDiff;

   ctlStopOnPreErrors.p_x += widthDiff;
   ctlPreBuildCmdButton.p_x += widthDiff;
   ctlMovePreCmdUp.p_x += widthDiff;
   ctlMovePreCmdDown.p_x += widthDiff;
   ctlPreBuildCmdList.p_width += widthDiff;

   ctlStopOnPostErrors.p_x += widthDiff;
   ctlPostBuildCmdBtn.p_x += widthDiff;
   ctlMovePostCmdUp.p_x += widthDiff;
   ctlMovePostCmdDown.p_x += widthDiff;
   ctlPostBuildCmdList.p_width += widthDiff;

   half_y := heightDiff intdiv 2;
   ctlStopOnPostErrors.p_y += half_y;
   ctlPostBuildCmdBtn.p_y += half_y;
   ctlMovePostCmdUp.p_y += half_y;
   ctlMovePostCmdDown.p_y += half_y;
   ctlPostBuildCmdList.p_y += half_y;
   ctlPostBuildLabel.p_y += half_y;
   ctlPostBuildCmdList.p_height += half_y;
   ctlPreBuildCmdList.p_height += half_y;
}
static void resizeCompileTab(int widthDiff, int heightDiff)
{
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
static void resizeDependenciesTab(int widthDiff, int heightDiff)
{
   ctlDepsTree.p_width += widthDiff;
   ctlDepsTree.p_height += heightDiff;
}
static void resizeOpenTab(int widthDiff, int heightDiff)
{
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
   resizeToolsTab(widthDiff, heightDiff);
   resizeBuildTab(widthDiff, heightDiff);
   resizeCompileTab(widthDiff, heightDiff);
   resizeDependenciesTab(widthDiff, heightDiff);
   resizeOpenTab(widthDiff, heightDiff);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _project_form_initial_alignment()
{
   tabWidth := _proj_prop_sstab.p_child.p_width;

   pad_x := ctllabel3.p_x;
   pad_y := ctlconfigurations.p_y;

   // directories tab
   rightAlign := tabWidth - pad_x;
   alignUpDownListButtons(ctlUserIncludesList, rightAlign, ctlBrowseUserIncludes, ctlMoveUserIncludesUp, ctlMoveUserIncludesDown, ctlRemoveUserIncludes);

   rightAlign = ctlBrowseUserIncludes.p_x + ctlBrowseUserIncludes.p_width;
   sizeBrowseButtonToTextBox(_prjworking_dir.p_window_id, _browsedir1.p_window_id, _projworking_button.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(_prjref_files.p_window_id, _browserefs.p_window_id, _projref_button.p_window_id, rightAlign);

   ctlHelpLabelDir.p_width = rightAlign - ctlHelpLabelDir.p_x;

   // tools tab
   ctlToolNew.p_width = ctlToolAdvanced.p_width;
   alignUpDownListButtons(ctlToolTree, 0, ctlToolUp, ctlToolDown, ctlToolDelete);

   rightAlign = ctlToolAdvanced.p_x + ctlToolAdvanced.p_width;
   sizeBrowseButtonToTextBox(ctlToolCmdLine.p_window_id, ctlBrowseCmdLine.p_window_id, ctlToolCmdLineButton.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlRunFromDir.p_window_id, ctlBrowseRunFrom.p_window_id, ctlRunFromButton.p_window_id, rightAlign);
   ctlToolMenuCaption.p_width = (ctlRunFromDir.p_x + ctlRunFromDir.p_width) - ctlToolMenuCaption.p_x;

   ctlHelpLabelTools.p_width = rightAlign - ctlHelpLabelDir.p_x;

   // build tab
   sizeBrowseButtonToTextBox(ctlAutoMakefile.p_window_id, ctlAutoMakefileButton.p_window_id);

   rightAlign = tabWidth - pad_x;
   alignUpDownListButtons(ctlPreBuildCmdList, rightAlign, ctlMovePreCmdUp, ctlMovePreCmdDown);
   alignUpDownListButtons(ctlPostBuildCmdList, rightAlign, ctlMovePostCmdUp, ctlMovePostCmdDown);

   ctlBuildSystem.p_width = rightAlign - ctlBuildSystem.p_x;

   // compile/link tab
   sizeBrowseButtonToTextBox(ctlCompilerList.p_window_id, ctlcompiler_config.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlLibraries.p_window_id, ctlLinkOrder.p_window_id, ctlLibrariesButton.p_window_id, rightAlign);

   alignUpDownListButtons(ctlDefinesTree, rightAlign, ctlAddDefine, ctlAddUndef);
   if (ctlAddDefine.p_width > ctlAddUndef.p_width) {
      ctlAddUndef.p_width = ctlAddDefine.p_width;
   } else {
      ctlAddDefine.p_width = ctlAddUndef.p_width;
   }

   ctlHelpLabelCompileLink.p_width = rightAlign - ctlHelpLabelCompileLink.p_x;

   // make sure the form is big enough
   minWidth := ctlfolders.p_x + ctlfolders.p_width + _ok.p_width;
   minHeight := ctlBuildSystem.p_height*3;
   p_active_form._set_minimum_size(minWidth, minHeight);
}

defeventtab _import_list_form;

/**
 * Adds the list of file types found in def_file_types to a list
 * box.
 */
void _init_filters()
{
   _lbclear();
   _retrieve_list();
   _lbbottom();

   _str name='';
   _str list='';
   _str wildcards=def_file_types;
   for (;;) {
      parse wildcards with name '('list')' ',' wildcards;
      if (name=='') break;
      _lbadd_item(list);
   }
}

ctlok.on_create()
{
   _retrieve_prev_form();
   ctlFileFilter._init_filters();

   ctlFileFilter.p_enabled=ctlFileFilterEnable.p_value!=0;
   _import_list_form_initial_alignment();
}

ctlFileFilterEnable.lbutton_up()
{
   ctlFileFilter.p_enabled=ctlFileFilterEnable.p_value!=0;
}

ctlListFileBrowse.lbutton_up()
{
   _str working_dir = absolute(_ProjectGet_WorkingDir(gProjectHandle), _strip_filename(gProjectName, 'N'));
   _str result=_OpenDialog("-modal",
                           'Import Files',// title
                           '',// Initial wildcards
                           "Text Files (*.txt),All Files (*.*)",
                           OFN_NOCHANGEDIR|OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT|OFN_SET_LAST_WILDCARDS,
                           "", // Default extension
                           ""/*wildcards*/, // Initial filename
                           working_dir,// Initial directory
                           "",
                           ""
                           );
   if ( result!='' ) {
      ctlListFile.p_text=result;
   }
}

/**
 * Reads the specified import file, grabbing each line and 
 * putting it into an array 
 * 
 * @param file_array 
 * @param recursive 
 * 
 * @return int 
 */
static int get_file_array(_str (&file_array)[],boolean &recursive)
{
   file_array._makeempty();

   // collapse the list file into a bgm_gen_file_list friendly string
   // open the file specified into a temp view
   int temp_wid;
   int orig_wid;
   int status=_open_temp_view(ctlListFile.p_text,temp_wid,orig_wid);
   if (status) {
      _message_box('Could not open list file');
      return status;
   }

   // make sure we don't get any array size warnings
   if (p_Noflines+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE)) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,p_Noflines+10);
   }

   // grab each line in the file
   top();
   up();
   _str cur_line;
   while (!down()) {
      get_line(cur_line);
      cur_line=strip(cur_line);
      if (cur_line:!='') {
         file_array[file_array._length()]=cur_line;
      }
   }

   // clean up after ourselves
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   // do what the checkbox says
   recursive=ctlRecurse.p_value!=0;

   return 0;
}

static int generate_file_list()
{
   // get the files specified in the import list
   _str file_array[];
   boolean recursive;
   int status=get_file_array(file_array,recursive);

   // we failed, very sad
   if (status) return 0;

   // figure out which files to keep based on file type
   _str wildcards=ALLFILES_RE;
   if (ctlFileFilterEnable.p_value) {
      wildcards=ctlFileFilter.p_text;
   }

   int temp_wid;
   status=bgm_gen_file_list(temp_wid,'',wildcards,'',true,false,false,true,recursive,file_array);
   if (status) {
      if (status<0) {
         _message_box(get_message(status));
      }
      return(0);
   }

   activate_window(temp_wid);

   bgm_filter_project_files(wildcards);

   return temp_wid;
}

ctlok.lbutton_up()
{
   _save_form_response();
   if (ctlFileFilter.p_text!='') {
      _append_retrieve(ctlFileFilter,ctlFileFilter.p_text);
   }
   temp_wid:=p_window_id.generate_file_list();
   p_active_form._delete_window(temp_wid);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _import_list_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctlListFile.p_window_id, ctlListFileBrowse.p_window_id, 0,
                             ctlFileFilter.p_x + ctlFileFilter.p_width);
}

boolean def_project_auto_build = false;
static _str _pending_builds:[];
static boolean _in_auto_build = false;
static boolean _disable_auto_builds = false; //temporarily disable

#define AUTOBUILD_TIMER_INTERVAL 500
static int _gAutoBuildTimerHandle = -2;

_command void project_toggle_auto_build()
{
   def_project_auto_build = !def_project_auto_build;
   if (!def_project_auto_build) {
      _pending_builds._makeempty();
   }
}

int _OnUpdate_project_toggle_auto_build(CMDUI &cmdui,int target_wid,_str command)
{
   return(def_project_auto_build ? MF_ENABLED|MF_CHECKED : MF_ENABLED|MF_UNCHECKED);
}

boolean project_in_auto_build()
{
   return def_project_auto_build && _in_auto_build;
}

void _cb_auto_build_timer()
{
   if (_in_auto_build) {
      return;
   }
   _next_pending_build();
   if (!_in_auto_build && _pending_builds._isempty()) {
      _kill_timer(_gAutoBuildTimerHandle);
      _gAutoBuildTimerHandle = -2;
   }
}

// on save callback
void _cbsave_project_auto_build()
{
   if (_workspace_filename != '' && def_project_auto_build && !_disable_auto_builds && !debug_active()) {
      _str projName = _WorkspaceFindProjectWithFile(p_buf_name, _workspace_filename, true, true);
      if (projName != "") {
         _str buildName = projName:+"\t"p_buf_name;
         if (!_pending_builds._indexin(buildName)) {
            _pending_builds:[buildName] = 1;
            if (_gAutoBuildTimerHandle < 0) {
               _gAutoBuildTimerHandle = _set_timer(AUTOBUILD_TIMER_INTERVAL, _cb_auto_build_timer);
            }
         }
      }
   }
}

// on stop process callback
void _cbstop_process_cancel_pending_builds()
{
   _clear_pending_builds();
}

// on workspace closed callback
void _wkspace_close_cancel_pending_builds()
{
   _clear_pending_builds();
}

// prebuild callback
void _prebuild_check_start()
{
   _in_auto_build = true; // start timer
}

// postbuild callback
void _postbuild_build_done()
{
   _in_auto_build = false;
}

static void _clear_pending_builds()
{
   _pending_builds._makeempty();
   _in_auto_build = false;
   if (_gAutoBuildTimerHandle > 0) {
      _kill_timer(_gAutoBuildTimerHandle);
      _gAutoBuildTimerHandle = -2;
   }
}

static void _next_pending_build()
{
   _str projName;
   projName._makeempty();
   _pending_builds._nextel(projName);
   if (!projName._isempty()) {
      _execute_pending_auto_build(projName);
   } else {
      _clear_pending_builds();
   }
}

static void _execute_pending_auto_build(_str buildName)
{
   parse buildName with auto projName "\t" auto bufName;
   if (_workspace_filename != '') {
      _in_auto_build = true;
      _str old_project_name = _project_name;
      boolean old_process_output = def_process_tab_output;
      def_process_tab_output = true; // auto builds work quietly
      workspace_set_active(projName, false, false, false);
      project_build('build', false, true, 0, bufName);
      workspace_set_active(old_project_name, false, false, false);
      def_process_tab_output = old_process_output;
      _in_auto_build = false;
   }
   if (_pending_builds._indexin(buildName)) {
      _pending_builds._deleteel(buildName);
   }
}

void _project_disable_auto_build(boolean enable)
{
   _disable_auto_builds = enable;
}


defeventtab _selproj_form;

void _ctl_ok.on_create(_str (&data)[])
{
   int i;
   for (i = 0; i < data._length(); i++) {
      _ctl_list._lbadd_item(data[i]);
   }
}

void _ctl_ok.lbutton_up()
{
   // is the checkbox checked?  save the value
   def_show_all_proj_with_file = (_ctl_no_prompt.p_value != 0);

   // figure out our selections and save them
   _str projArray[];
   while (!_ctl_list._lbfind_selected(true)) {
      projArray[projArray._length()] = _ctl_list._lbget_text();

      _ctl_list._lbdelete_item();
      _ctl_list.up();
   }

   if (!projArray._length()) {
      _message_box("Please select at least one project to expand in the Project tool window.");
      return;
   }

   _param1 = projArray;

   p_parent._delete_window(IDOK);
}

void _ctl_list.lbutton_double_click()
{
   call_event(_ctl_ok, LBUTTON_UP);
}

void _ctl_select_all.lbutton_up()
{
   _ctl_list._lbselect_all();
   _ctl_list.call_event(CHANGE_SELECTED, _ctl_list, ON_CHANGE, '');
}

definit()
{
   _disable_auto_builds = false;
   _pending_builds._makeempty();
   _in_auto_build = false;
   _gAutoBuildTimerHandle = -2;
}

defeventtab _project_tool_wizard_form;

#define     TEMPLATE_TYPE        slide3_add_to_template.p_user

#define     LANG_ID_KEY          'langid'
#define     PROJECT_HANDLE_KEY   'projectHandle'

int _OnUpdate_project_tool_wizard(CMDUI &cmdui,int target_wid,_str command)
{
   // make sure a project is open
   if (_project_name != '') {
      return MF_ENABLED;
   } else if (!_no_child_windows()) {
      // or an extension-specific project will work, too
      return MF_ENABLED;
   }

   return MF_GRAYED;
}

_command void project_tool_wizard(int projectHandle = _ProjectHandle(), _str langId = '', boolean doMakeCopy = true) name_info(',')
{
   // if this is a language-specific project, then we do not
   // bother with configurations
   if (projectHandle == gProjectExtHandle) {
      if (langId == '') {
         if (_no_child_windows()) return;
         langId = '.'_mdi.p_child.p_LangId;
      }
   }

   if (doMakeCopy) {
      origProjHandle := projectHandle;
      projectHandle = _xmlcfg_create(_xmlcfg_get_filename(origProjHandle), VSENCODING_UTF8);
      _xmlcfg_copy(projectHandle, TREE_ROOT_INDEX, origProjHandle, TREE_ROOT_INDEX, VSXMLCFG_COPY_CHILDREN);
   }

   typeless callback_table:[];
   setupProjectToolWizardTable(callback_table, projectHandle, langId);

   WIZARD_INFO info;
   info.dialogCaption = 'Add new project tool';
   info.parentFormName = '_project_tool_wizard_form';
   info.callbackTable = callback_table;

   _Wizard(&info);

   if (doMakeCopy) {
      // now save the project file
      _ProjectSave(projectHandle);
      projName := _xmlcfg_get_filename(projectHandle);

      // IF we are modifying the active project
      if (projName == _project_name) {
         _ProjectCache_Update(projName);
         p_window_id._WorkspacePutProjectDate(projName);

         p_window_id.call_list("_prjupdatedirs_");

         // regenerate the makefile
         p_window_id._maybeGenerateMakefile(projName);
         p_window_id.call_list("_prjupdate_");
      } else if (langId != '') {
         readAndParseAllExtensionProjects();
         maybeResetLanguageProjectToolList(langId);
      }

      _xmlcfg_close(projectHandle);
   }
}

static void setupProjectToolWizardTable(typeless (&callback_table):[], int projectHandle, _str langId)
{
// callback_table:['destroy'] = ptw_destroy;
   callback_table:['finish'] = ptw_finish;

   // slide 0 - basic info
   callback_table:['ctlslide0.create'] = ptw_basic_create;
   callback_table:['ctlslide0.next'] = ptw_basic_next;
   callback_table:['ctlslide0.skip'] = 0;

   // slide 1 - configurations
   callback_table:['ctlslide1.next'] = ptw_configurations_next;
   callback_table:['ctlslide1.finishon'] = 0;
   callback_table:['ctlslide1.skip'] = langId != '';

   // slide 2 - advanced options
   callback_table:['ctlslide2.create'] = ptw_advanced_create;
   callback_table:['ctlslide2.finishon'] = 0;
   callback_table:['ctlslide2.skip'] = 0;

   // slide 3 - finish up
   callback_table:['ctlslide3.finishon'] = 1;
   callback_table:['ctlslide3.skip'] = 0;

   // some info we just want to send to the wizard
   callback_table:[LANG_ID_KEY] = langId;
   callback_table:[PROJECT_HANDLE_KEY] = projectHandle;

}

static _str ptw_get_langId()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   return pWizardInfo->callbackTable:[LANG_ID_KEY];
}

static int ptw_get_project_handle()
{
   WIZARD_INFO *pWizardInfo=_WizardGetPointerToInfo();
   return pWizardInfo->callbackTable:[PROJECT_HANDLE_KEY];
}

static int ptw_basic_create()
{
   projectHandle := ptw_get_project_handle();

   // handles all the little gui tweaks for the whole wizard
   panelWidth := ctlslide0.p_width;

   pad_x := slide0_caption.p_x;

   // which of these labels is longest?  align them!
   slide0_name.p_x = ctllabel15.p_x + ctllabel15.p_width + (pad_x / 2);
   slide0_name.p_width = panelWidth - pad_x - slide0_name.p_x;
   slide0_exe.p_x = slide0_args.p_x = slide0_name.p_x;

   // fill in the combo box full of the existing tools
   slide0_copy_combo.ptw_fill_in_existing_tool_names(projectHandle);
   slide0_copy_combo.p_enabled = false;

   rightAlign := panelWidth - pad_x;
   sizeBrowseButtonToTextBox(slide0_exe, ctlimage1.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(slide0_args, ctlToolCmdLineButton.p_window_id, 0, rightAlign);

   ctlRunFromDir.p_x = ctllabel10.p_x + ctllabel10.p_width + (pad_x / 2);
   sizeBrowseButtonToTextBox(ctlRunFromDir, ctl_browse_dir.p_window_id, ctlRunFromButton.p_window_id, rightAlign);

   ctlToolSaveCombo.p_x = ctlRunFromDir.p_x;

   // call the creation functions of other slide,
   // so their controls will be ready
   ptw_configurations_init();
   ptw_advanced_init();
   ptw_end_init();

   return 0;
}

static void ptw_fill_in_existing_tool_names(int handle)
{
   _str tools[];
   _str added:[];
   _ProjectGet_Targets(handle, tools, '');
   for (i := 0; i < tools._length(); i++) {
      // this is the index into the project file
      index := (int)tools[i];

      // get the menu caption - we need to make sure this is not a dash (separator)
      caption := _ProjectGet_TargetMenuCaption(handle, index);
      if (caption != '-') {
         // get the name
         name := _ProjectGet_TargetName(handle, index);

         lowcaseItem := lowcase(name);
         if (!added._indexin(lowcaseItem)) {
            _lbadd_item(name);
            added:[lowcaseItem] = 1;
         }
      }
   }

   _lbsort();
   _lbtop();
   _lbselect_line();
}

static int ptw_basic_next()
{
   // make sure the necessary fields are filled in
   if (slide0_name.p_text == '') {
      _message_box("Please enter a menu caption for your new project tool.");
      return 1;
   }

   // make sure we don't already have a tool by this name
   if (_ProjectDoes_TargetExist(ptw_get_project_handle(), slide0_name.p_text, ptw_get_langId())) {
      _message_box('A project tool with the name "'slide0_name.p_text'" already exists.');
      return 1;
   }

   return 0;
}

static void ptw_configurations_init()
{
   // load the configurations in the project into the tree
   _str configs[];
   _ProjectGet_ConfigNames(ptw_get_project_handle(), configs);
   configs._sort();

   index := 0;
   for (i := 0; i < configs._length(); i++) {
      index = slide1_tree._TreeAddItem(TREE_ROOT_INDEX, configs[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

      // go ahead and just select them all
      slide1_tree._TreeSetCheckState(index, TCB_CHECKED);
   }

   slide1_tree.p_CheckListBox = true;
}

static int ptw_configurations_next()
{
   // they need to pick at least one
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      if (slide1_tree._TreeGetCheckState(index) == TCB_CHECKED) {
         return 0;
      }
      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }

   // we got to the end, with nothing picked
   _message_box("Please select at least one configuration.");
   return 1;
}

static void ptw_advanced_init()
{
   FillInToolSaveCombo();
}

static int ptw_advanced_create()
{
   // if we are not copying from an existing tool,
   // set a default value for the save option
   if (!slide0_copy_check.p_value) {
      ptw_set_default_save_option();
   }

   return 0;
}

static void ptw_set_default_save_option()
{
   // if the current file option (%f) is specified in the arguments, then
   // we default to save the current file
   defaultOption := VPJ_SAVEOPTION_SAVENONE;
   if (pos('%f', slide0_args.p_text)) {
      defaultOption = VPJ_SAVEOPTION_SAVECURRENT;
   }
}

static void ptw_set_save_option(_str option)
{
   ctlToolSaveCombo._lbdeselect_all();
   ctlToolSaveCombo.p_line=SaveOptionToLine(option);
   ctlToolSaveCombo._lbselect_line();
   ctlToolSaveCombo.p_text=ctlToolSaveCombo._lbget_text();
}

static void ptw_end_init()
{
   // determine if this was made from a template
   projectHandle := ptw_get_project_handle();
   if (_ProjectGet_AssociatedFileType(projectHandle) == '') {
      type := _ProjectGet_ActiveType();

      if (type == '') {
         type = _ProjectGet_TemplateName(projectHandle);
      }

      // if we have a type, then save it
      if (type != '') {
         TEMPLATE_TYPE = type;
         slide3_add_to_template.p_visible = true;
      } else {
         slide3_add_to_template.p_visible = false;
      }
   }
}

static int ptw_finish()
{
   // get the list of checked configs
   _str configs[];
   projectHandle := ptw_get_project_handle();
   langId := ptw_get_langId();
   if (langId != '') {
      configName := langId;
      configs[0] = configName;

      // make sure there is a section for this lang in the extension projects file

      if (_ProjectGet_ConfigNode(projectHandle, configName)<0) {
         _ProjectCreateLangSpecificConfig(projectHandle, configName);
      }
   } else {
      index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while (index > 0) {
         if (slide1_tree._TreeGetCheckState(index) == TCB_CHECKED) {
            configs[configs._length()] = slide1_tree._TreeGetCaption(index);
         }
         index = slide1_tree._TreeGetNextSiblingIndex(index);
      }
   }

   saveToolToFile(projectHandle, configs);

   // do we save this to the project template as well?
   if (slide3_add_to_template.p_visible && slide3_add_to_template.p_value) {
      saveToolToTemplate(TEMPLATE_TYPE, configs);
   }

   return 0;
}

static void saveToolToFile(int handle, _str (&configs)[])
{
   for (i := 0; i < configs._length(); i++) {
      // add the tool
      index := _ProjectAddTool(handle, slide0_name.p_text, configs[i]);

      // set the command line
      cmdLine := strip(strip(slide0_exe.p_text)' 'strip(slide0_args.p_text));
      _ProjectSet_TargetCmdLine(handle, index, cmdLine);

      // run from dir?
      _ProjectSet_TargetRunFromDir(handle, index, ctlRunFromDir.p_text);

      // set some sensible defaults for other advanced options
      // capture output = true, output to build window = true
      _ProjectSet_TargetCaptureOutputWith(handle, index, GetCaptureOutputWith());

      // save option
      _ProjectSet_TargetSaveOption(handle, index, getToolSaveComboValue());
   }
}

static void saveToolToTemplate(_str templateName, _str (&configs)[])
{
   // first, look for the template in the existing user and system templates
   foundInHandle := 0;
   foundAtNode := 0;

   // first check the user templates
   userTemplates :=  _ProjectOpenUserTemplates();
   sysTemplates := _ProjectOpenTemplates();
   foundAtNode = _ProjectTemplatesGet_TemplateNode(userTemplates, templateName, false);
   if (foundAtNode < 0) {
      // not in the user templates, so see if it is in the system templates
      foundAtNode = _ProjectTemplatesGet_TemplateNode(sysTemplates, templateName, false);
      if (foundAtNode > 0) {
         foundInHandle = sysTemplates;
      }
   } else {
      foundInHandle = userTemplates;
   }

   if (foundAtNode <= 0) {
      // we didn't find it, oh well
      _xmlcfg_close(userTemplates);
      _xmlcfg_close(sysTemplates);
      return;
   }

   // create a new file to store this as we work with it
   tempHandle := _xmlcfg_create('',VSENCODING_UTF8);
   node := _xmlcfg_copy(tempHandle, TREE_ROOT_INDEX, foundInHandle, foundAtNode, VSXMLCFG_COPY_AS_CHILD);
   _xmlcfg_set_name(tempHandle, node, VPJTAG_PROJECT);
   _ProjectTemplateExpand(sysTemplates, tempHandle, true);

   // this does the work
   saveToolToFile(tempHandle, configs);

   oldNode := _ProjectTemplatesGet_TemplateNode(userTemplates, templateName, true);
   ProjectNode := _xmlcfg_set_path(tempHandle, "/"VPJTAG_PROJECT);

   int NewNode=_xmlcfg_copy(userTemplates, oldNode, tempHandle, ProjectNode,0);
   _xmlcfg_set_name(userTemplates, NewNode, VPTTAG_TEMPLATE);

   _xmlcfg_delete(userTemplates, oldNode);
   _ProjectTemplatesSave(userTemplates);

   _xmlcfg_close(tempHandle);
   _xmlcfg_close(userTemplates);
   _xmlcfg_close(sysTemplates);
}

void slide0_copy_check.lbutton_up()
{
   slide0_copy_combo.p_enabled = (slide0_copy_check.p_value != 0);
   call_event(slide0_copy_combo, ON_CHANGE);
}

void slide0_copy_combo.on_change()
{
   // make sure this is turned on
   if (slide0_copy_check.p_value) {
      handle := ptw_get_project_handle();

      // now update all the other controls to reflect the values for this tool
      tool := slide0_copy_combo.p_text;
      toolNode := _ProjectGet_TargetNode(handle, tool, '');
      if (toolNode > 0) {
         // executable and arguments
         cmdLine := _ProjectGet_TargetCmdLine(handle, toolNode);
         parse cmdLine with auto exec auto args;
         slide0_exe.p_text = exec;
         slide0_args.p_text = args;

         // run from dir
         ctlRunFromDir.p_text = _ProjectGet_TargetRunFromDir(handle, toolNode);

         // save option
         saveOption := _ProjectGet_TargetSaveOption(handle, toolNode);
         ptw_set_save_option(saveOption);

         // capture output, output to build window
         output := _ProjectGet_TargetCaptureOutputWith(handle, toolNode);
         if (output == VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER) {
            ctlToolCaptureOutput.p_value = 1;
            ctlToolOutputToConcur.p_value = 1;
         } else if (output == VPJ_CAPTUREOUTPUTWITH_REDIRECTION) {
            ctlToolCaptureOutput.p_value = 1;
               ctlToolOutputToConcur.p_value = 0;
         } else {
            ctlToolCaptureOutput.p_value = ctlToolOutputToConcur.p_value = 0;
         }
      }
   }
}

void slide1_select_all.lbutton_up()
{
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      slide1_tree._TreeSetCheckState(index, TCB_CHECKED);

      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }
}

void slide1_clear_all.lbutton_up()
{
   index := slide1_tree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index > 0) {
      slide1_tree._TreeSetCheckState(index, TCB_UNCHECKED);

      index = slide1_tree._TreeGetNextSiblingIndex(index);
   }
}
