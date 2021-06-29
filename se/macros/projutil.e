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
#include "xml.sh"
#import "bind.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "debug.e"
#import "dir.e"
#import "doscmds.e"
#import "error.e"
#import "fileman.e"
#import "files.e"
#import "gnucopts.e"
#import "help.e"
#import "ini.e"
#import "javaopts.e"
#import "listbox.e"
#import "main.e"
#import "makefile.e"
#import "mprompt.e"
#import "os2cmds.e"
#import "packs.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "recmacro.e"
#import "rte.e"
#import "seltree.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbcmds.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#import "guiopen.e"
#import "xmlcfg.e"
#import "fileproject.e"
#import "tbview.e"
#import "vchack.e"
#import "menu.e"
#import "listproc.e"
#endregion

static ProjectToolStruct predefToolList[]= {
    {"Compile",  "compile", "project-compile", "",  "&Compile",  "",  1,1,0, 0,PROJ_TOOL_SAVECURRENT,1,0}
   ,{"Link",     "link",    "project-link",    "",  "&Link",     "",  1,1,PROJ_TOOL_HIDEALWAYS, 0,PROJ_TOOL_SAVECURRENT,1,0}
   ,{"Build",    "make",    "project-build",   "",  "&Build",    "",  1,1,0, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"Rebuild",  "rebuild", "project-rebuild", "",  "&Rebuild",  "",  1,1,0, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"Debug",    "debug",   "project-debug",   "",  "&Debug",    "",  0,0,0, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"Execute",  "execute", "project-execute", "",  "E&xecute",  "",  0,0,0, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"Clean",    "clean",   "project-clean",   "",  "Clean",     "",  1,1,0, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"User 1",   "user1",   "project-user1",   "",  "User 1",    "",  0,0,1, 0,PROJ_TOOL_SAVENONE,1,0}
   ,{"User 2",   "user2",   "project-user2",   "",  "User 2",    "",  0,0,1, 0,PROJ_TOOL_SAVENONE,1,0}
};

_str def_process;

int def_antmake_use_classpath = 1; 
bool def_antmake_display_imported_targets = true;
bool def_antmake_filter_matches = false;

const ANT_LANG_ID= "ant";
static const ANT_IMPORTED_TARGET_REGEX= '\[from [A-Za-z0-9]+\.xml\]';
static const XML_ENTITY_REGEX= '<!ENTITY';

// DJB 04-10-2007
// 
// Cache of last result from _ProjectToolGetList()
// This is needed because that function is called from
// _OnUpdateInit() which is called whenever the cursor moves
// therefore, it needs to be really, really fast, and not
// have any hangups if the project is really large and it
// takes a lot of time to read the tool list.
// 
struct ProjectToolListResults {
   // keys
   _str workspaceName;
   _str projectName;
   _str configName;
   bool debugMode;
   _str extension;
   _str absFilename;
   // results
   _str toolNameList[];
   _str toolCaptionList[];
   _str toolMenuCmdList[];
   _str toolCmdList[];
};
static ProjectToolListResults glast_project_tool_list = null;


bool def_project_auto_build = false;
static _str _pending_builds:[];
static bool _in_auto_build = false;
static bool _disable_auto_builds = false; //temporarily disable

static const AUTOBUILD_TIMER_INTERVAL= 500;
static int _gAutoBuildTimerHandle = -2;


// Note: We have to use a hash table for pattern, app command, and file association
//       because the user project file may have the filter names in a different order
//       from what we default here. These hash tables are keyed on the lowcased
//       filter names.
definit()
{
   // Read and parse all the extension projects tools:
   //readAndParseAllExtensionProjects();

   _in_close_all=false;
   _in_project_close=false;
   _in_workspace_close=false;
   rc=0;
   glast_project_tool_list = null;
   //gProjectInfo._makeempty();

   _disable_auto_builds = false;
   _pending_builds._makeempty();
   _in_auto_build = false;
   _gAutoBuildTimerHandle = -2;
}

/**
 * @return Returns currently open project filename.  If no project file is open, the 
 * extension specific project file "project.slk" (UNIX: "uproject.slk")  is 
 * returned. 
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
_str _project_get_filename()
{
   return(_xmlcfg_get_filename(_ProjectHandle()));
}

/**
 * @return Returns <i>default_value</i> specified if a project file is open.  If no 
 * project file is open, the extension of the MDI child edit window with 
 * leading '.' is returned.
 * 
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
_str _project_get_section(_str default_value='')
{
   if (_project_name=='') {
      return('.'_mdi.p_child.p_LangId);
   }
   return(default_value);
}

int _srg_project(_str option='', _str info='')
{
   // If restoring with no files or restoring with files
   if (option=='N' || option=='R') {
      typeless Noffiles;
      _str rest;
      parse info with Noffiles rest;
      arg2 := Noffiles' '_maybe_quote_filename(rest);
      _srg_workspace(option,arg2);
   } else {
   }
   return(0);
}

void _FilterVSEProjectFiles()
{
   top();
   for (;;) {
      int status=search('^?@('_escape_re_chars(TAG_FILE_EXT)'|'\
                    _escape_re_chars(WORKSPACE_FILE_EXT)'|'\
                    _escape_re_chars(WORKSPACE_STATE_FILE_EXT)'|'\
                    _escape_re_chars(PRJ_FILE_EXT)')$','@rh'_fpos_case);
      if (status) break;
      _delete_line();up();
   }
   _lbtop();
}

int _WorkspacePutProjectDate(_str ProjectName=_project_name,_str WorkspaceFilename=_workspace_filename)
{
   glast_project_tool_list=null;
   if (ProjectName=='') {
      return(0);
   }
   ProjectName=GetProjectDisplayName(ProjectName);
   _str date=_file_date(ProjectName,'B');
   int status=_ini_set_value(VSEWorkspaceStateFilename(WorkspaceFilename),
                         "ProjectDates",
                         relative(ProjectName,_strip_filename(WorkspaceFilename,'N'))
                         ,date);
   return(status);
}
////////////////////////////////////////////////////////////////////////////////
//4:43pm 6/22/1999
//Dan made global for workspace stuff
int _mkdir_chdir(_str path,bool doCD=true)
{
   typeless status=cd(path);
   if (status) {
      clear_message();
      if (status==ACCESS_DENIED_RC) {
         _message_box(get_message(ACCESS_DENIED_RC));
         return(status);
      }
      int result=_message_box(nls("Directory %s does not exist\n\nCreate it?",path),"",MB_ICONQUESTION|MB_YESNOCANCEL);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
      status=make_path(path);
      if (status) {
         _message_box(nls("Unable to create directory %s",path));
         return(status);
      }
      if (!doCD) {
         return(0);
      }
      return(cd(path));
   }
   return(0);
}
/**
 * Should probably include Foxpro in here
 *
 * @param filename Filename to check to see if it is a Visual Studio
 *                 project file
 *
 * @return true if it is a Visual Studio project file
 */
bool _IsVisualStudioProjectFilename(_str filename)
{
   _str ext=_get_extension(filename,true);
   return(GetVSStandardAppName(ext):!='' ||
          _file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_TEMPLATE_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_DATABASE_PROJECT_EXT)
          );
}

static bool _IsVisualStudioVCPPCLRProject(_str VCPPProjectFilename,_str config_name='')
{
   status := 0;
   int vcpp_project_handle = _xmlcfg_open(VCPPProjectFilename, status);
   if (  vcpp_project_handle < 0 ) return(false);

   if ( config_name=='' ) {
      _str vse_project_filename=VSEProjectFilename(VCPPProjectFilename);
      xml_handle := -1;
      _ProjectGet_ActiveConfigOrExt(vse_project_filename,xml_handle,config_name);
   }
   path := "/VisualStudioProject/Configurations/Configuration[@ManagedExtensions='TRUE'][@Name='"config_name"']";
   int configindex=_xmlcfg_find_simple(vcpp_project_handle,path);
   _xmlcfg_close(vcpp_project_handle);
   return(configindex>-1);
}

bool _IsVisualStudioCLRProject(_str filename)
{
   _str ext=_get_extension(filename,true);
   return(_file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT) ||
          _IsVisualStudioVCPPCLRProject(filename)
          );
}

bool _IsVCPPProjectFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),VCPP_PROJECT_FILE_EXT));
}

bool _IsWorkspaceAssociated(_str filename, _str &associatedFileName="")
{
   if (filename=='') {
      return false;
   }
   if (!_file_eq('.'_get_extension(filename),WORKSPACE_FILE_EXT)) {
      associatedFileName = filename;
      return(true);
   }

   // check the AssociatedFileName attribute in the workspace
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileName = _WorkspaceGet_AssociatedFile(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      int handle = _xmlcfg_open(filename, status);
      if(handle < 0) return false;

      associatedFileName = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   // if set this is an associated workspace
   if(associatedFileName != "") {
      return true;
   }
   return false;

   //return(!file_eq('.'get_extension(filename),WORKSPACE_FILE_EXT));
}

/**
 * @return Return file extension filter list for all supported 
 *         workspaces on the current platform.
 *  
 * @example (Unix) 
 *           "Workspace Files(*.vpw;*.wsp;*.jpx),
 *            SlickEdit Workspace Files(*.vpw'),
 *            SlickEdit Project Files(*.vpj),
 *            Tornado Workspace Files(*.wsp),
 *            JBuilder Project Files(*.jpx),
 *            All Files(*)"
 */
_str _GetWorkspaceExtensionList()
{
   _str format_list;
   if (_isMac()) {
      format_list='Workspace Files(*'WORKSPACE_FILE_EXT';*'PRJ_FILE_EXT';*'VISUAL_STUDIO_SOLUTION_EXT';Cargo.toml;*'TORNADO_WORKSPACE_EXT';*'JBUILDER_PROJECT_EXT'),SlickEdit Workspace Files(*'WORKSPACE_FILE_EXT'),SlickEdit Project Files(*'PRJ_FILE_EXT'),Tornado Workspace Files(*'TORNADO_WORKSPACE_EXT'),JBuilder Project Files(*'JBUILDER_PROJECT_EXT'),Xcode Project Files(*'XCODE_PROJECT_LONG_BUNDLE_EXT';*'XCODE_PROJECT_SHORT_BUNDLE_EXT'),All Files('ALLFILES_RE')';
   } else if (_isUnix()) {
      format_list='Workspace Files(*'WORKSPACE_FILE_EXT';*'PRJ_FILE_EXT';*'VISUAL_STUDIO_SOLUTION_EXT';Cargo.toml;*'TORNADO_WORKSPACE_EXT';*'JBUILDER_PROJECT_EXT'),SlickEdit Workspace Files(*'WORKSPACE_FILE_EXT'),SlickEdit Project Files(*'PRJ_FILE_EXT'),Tornado Workspace Files(*'TORNADO_WORKSPACE_EXT'),JBuilder Project Files(*'JBUILDER_PROJECT_EXT'),All Files('ALLFILES_RE')';
   } else {
      format_list='Workspace Files(*'WORKSPACE_FILE_EXT';*'PRJ_FILE_EXT';*'VISUAL_STUDIO_SOLUTION_EXT';*'VCPP_PROJECT_WORKSPACE_EXT';*'VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT';Cargo.toml;*'TORNADO_WORKSPACE_EXT';*'JBUILDER_PROJECT_EXT';*'MACROMEDIA_FLASH_PROJECT_EXT'),SlickEdit Workspace Files(*'WORKSPACE_FILE_EXT'),SlickEdit Project Files(*'PRJ_FILE_EXT'),Visual C++ Workspace Files(*'VCPP_PROJECT_WORKSPACE_EXT'),Visual C++ Embedded Workspace Files(*'VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT'),Tornado Workspace Files(*'TORNADO_WORKSPACE_EXT'),JBuilder Project Files(*'JBUILDER_PROJECT_EXT'),Flash Project Files(*'MACROMEDIA_FLASH_PROJECT_EXT'),All Files('ALLFILES_RE')';
   }
   return format_list;
}

bool _IsVCPPWorkspaceFilename(_str filename)
{
   return(_file_eq(_get_extension(filename,true),VCPP_PROJECT_WORKSPACE_EXT));
}

/**
 * Check to see if this workspace supports inserting and removing project files
 */
bool _IsAddDeleteProjectsSupportedWorkspaceFilename(_str filename)
{
   associatedFileType := "";

   // check the AssociatedFileType attribute in the workspace
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      int handle = _xmlcfg_open(filename, status);
      if(handle < 0) return false;

      associatedFileType = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   // associatedFileType will be blank for vse workspaces
   if(associatedFileType == "" || associatedFileType == JBUILDER_VENDOR_NAME) {
      return true;
   }
   return false;
}

/**
 * Check to see if this workspace supports dependencies
 */
bool _IsDependenciesSupportedWorkspaceFilename(_str filename)
{
   if (!_haveBuild()) {
      return false;
   }
   associatedFileType := "";

   // check the AssociatedFileType attribute in the workspace
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      int handle = _xmlcfg_open(filename, status);
      if(handle < 0) return false;

      associatedFileType = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   // associatedFileType will be blank for vse workspaces
   if(associatedFileType == "" || associatedFileType == JBUILDER_VENDOR_NAME) {
      return true;
   }
   return false;
}

bool _IsAddDeleteSupportedWorkspaceFilename(_str filename)
{
   _str ext=_get_extension(filename,true);

   return(_file_eq(ext,VCPP_PROJECT_WORKSPACE_EXT)||
          _file_eq(ext,VISUAL_STUDIO_SOLUTION_EXT) ||
          _file_eq(ext,WORKSPACE_FILE_EXT)
          );
}

/**
 * Add, Delete,Move Up, Move Down supported for project folders
 */
bool _ProjectIs_AddDeleteFolderSupported(int ProjectHandle)
{
   _str makefile=_ProjectGet_AssociatedFile(ProjectHandle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (_file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         return(true);
      } else if (_file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
         return(false);
      } else if (GetVSStandardAppName(ext):!='') {
         return(false);
      } else if (_file_eq(ext,VCPP_PROJECT_FILE_EXT) || _file_eq(ext,VCPP_EMBEDDED_PROJECT_FILE_EXT)) {
         return(false);
      } else if(_file_eq(ext, JBUILDER_PROJECT_EXT)) {
         return true;
      }
      return(false);
   }
   return(true);
}

/*
    Cut/Copy/Paste for project files or folders
*/
bool _ProjectIs_CutPasteSupported(int ProjectHandle)
{
   _str makefile=_ProjectGet_AssociatedFile(ProjectHandle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (_file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
          _file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         // Since this project are like our XML project files,
         // this was easy to support
         return(true);
      } else if(_file_eq(ext, JBUILDER_PROJECT_EXT)) {
         return true;
      }
      return(false);
   }
   return(true);
}


/**
 * Check to see if this workspace is associated to JBuilder
 */
bool _IsJBuilderAssociatedWorkspace(_str filename)
{
   associatedFileType := "";

   // check the AssociatedFileType attribute in the workspace
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      int handle = _xmlcfg_open(filename, status);
      if(handle < 0) return false;

      associatedFileType = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   return (associatedFileType == JBUILDER_VENDOR_NAME);
}

/**
 * Check to see if this workspace is associated to Flash
 */
bool _IsFlashAssociatedWorkspace(_str filename)
{
   associatedFileType := "";

   // check the AssociatedFileType attribute in the workspace
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      int handle = _xmlcfg_open(filename, status);
      if(handle < 0) return false;

      associatedFileType = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   return (associatedFileType == MACROMEDIA_FLASH_VENDOR_NAME);
}

bool _IsDotNetCoreSdkProject(int handle)
{
   result := false;
   if (handle >= 0) {
      node := _xmlcfg_find_simple(handle, "/Project/PropertyGroup/TargetFramework");
      if (node > 0) {
           cdataNode := _xmlcfg_get_first_child(handle, node, VSXMLCFG_NODE_PCDATA);
           if (cdataNode>=0) {
            framework := _xmlcfg_get_value(handle, cdataNode); 
            if (framework:!="" && beginsWith(framework, 'netcoreapp')) {
               result = true; 
            }
         }
      }
   }
   return(result);
}

bool _IsVisualStudioWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),VISUAL_STUDIO_SOLUTION_EXT));
}

bool _IsEmbeddedVCPPWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT));
}

bool _IsTornadoWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),TORNADO_WORKSPACE_EXT));
}

bool _IsXcodeProjectFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),XCODE_PROJECT_LONG_BUNDLE_EXT) || _file_eq('.'_get_extension(filename),XCODE_PROJECT_SHORT_BUNDLE_EXT));
}

bool _IsXcodeWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),XCODE_WKSPACE_BUNDLE_EXT));
}

bool _IsFlashProjectFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),MACROMEDIA_FLASH_PROJECT_EXT));
}

static bool _LastDirMatches(_str cur,_str lastdir)
{
   _maybe_strip_filesep(cur);
   cur=_strip_filename(cur,'P');
   return(_file_eq(cur,lastdir));
}

bool _IsEclipseWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),ECLIPSE_WORKSPACE_FILE_EXT));
}

bool _IsEclipseWorkspacePath(_str filename)
{
   _str metadirpath=filename;
   _maybe_append_filesep(filename);
   metadirpath :+= '.metadata';
   return(isdirectory(filename) && _LastDirMatches(filename,'workspace') &&
          isdirectory(filename:+'.metadata') );
}

/**
 * Determine if this file is a JBuilder project
 *
 * @param filename
 *
 * @return
 */
bool _IsJBuilderProjectFilename(_str filename)
{
   return(_file_eq(_get_extension(filename,true),JBUILDER_PROJECT_EXT));
}

/**
 * Determine if this file is an ant XML build file
 *
 * @param filename
 *
 * @return
 */
bool _IsAntBuildFile(_str filename)
{
   // check that it ends in the proper extension
   if(!_file_eq(_get_extension(filename, true), ANT_BUILD_FILE_EXT) 
      || !def_antmake_identify 
      || _file_size(filename)>def_max_ant_file_size
      ) {
      return false;
   }

   // open the file
   tempstatus := 0;
   int handle = _xmlcfg_open(filename, tempstatus, VSXMLCFG_OPEN_REFCOUNT);
   if(handle <= 0) {
      return false;
   }

   // if an xml file has xpath /project then it is
   // most likely an ant build file
   int node = _xmlcfg_find_simple(handle, "/project");

   // close the file
   _xmlcfg_close(handle);

   return (node >= 0);
}



/**
 * Determine if this file is a makefile
 *
 * @param filename
 *
 * @return
 */
bool _IsMakefile(_str filename)
{
   _str lang=_Filename2LangId(filename);
   return(lang=="mak" || lang=="imakefile");
#if 0
   // open the file in a temp view and check to see if it was
   // opened in makefile mode
   tempViewID := 0;
   origViewID := 0;
   int status = _open_temp_view(filename, tempViewID, origViewID);
   if(status) return false;

   _SetEditorLanguage();

   // if the mode is 'Makefile' then this is recognized as a makefile by the editor
   retval := strieq(p_mode_name, "Makefile");

   // cleanup the temp view
   p_window_id = origViewID;
   _delete_temp_view(tempViewID);
   tempViewID = 0;

   return retval;
#endif
}

bool _IsVSEProjectFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),PRJ_FILE_EXT));
}

bool _IsVSEWorkspaceFilename(_str filename)
{
   return(_file_eq('.'_get_extension(filename),WORKSPACE_FILE_EXT));
}

_str VSEProjectFilename(_str filename)
{
   if (filename=="") return("");
   return(_strip_filename(filename,'E'):+PRJ_FILE_EXT);
}

_str VCPPProjectFilename(_str filename)
{
   if (filename=="") return("");
   return(_strip_filename(filename,'E'):+VCPP_PROJECT_FILE_EXT);
}

_str VSEWorkspaceFilename(_str filename)
{
   if (filename=="") return("");
   if (_IsEclipseWorkspaceFilename(filename)) {
      return(filename);
   }
   return(_strip_filename(filename,'E'):+WORKSPACE_FILE_EXT);
}
_str _VSEProjectTagFileName(_str _workspace_filename,_str abs_project_file,bool doRelative=false) {
   tagFileDir := VSEWorkspaceTagFileDir(_workspace_filename, _strip_filename(abs_project_file,'N'));
   extra := _file_eq(_strip_filename(abs_project_file,'e'), _strip_filename(_workspace_filename,'e'))? "-project":"";
   project_tag_file := tagFileDir:+_strip_filename(abs_project_file,'PE'):+extra:+TAG_FILE_EXT;
   if (doRelative) {
      project_tag_file = _RelativeToWorkspace(project_tag_file);
   }
   return project_tag_file;
}
_str VSEWorkspaceTagFileDir(_str filename=_workspace_filename, _str defaultDir="")
{
   // Get the path to the workspace file
   workspace_dir := _strip_filename(filename,'N');

   // Make the workspace directory the default path
   if (defaultDir == "") defaultDir = workspace_dir;
   _maybe_append_filesep(defaultDir);

   // Not a slickedit workspace (.vpw)?
   if (!_file_eq(_get_extension(filename, true), WORKSPACE_FILE_EXT)) {
      return defaultDir;
   }

   // Is this the current workspace?
   tagFileDir := "";
   if(_workspace_filename != "" && _file_eq(_workspace_filename, filename)) {
      // workspace already cached
      tagFileDir = _WorkspaceGet_TagFileDir(gWorkspaceHandle);
   } else {
      // open the file
      status := 0;
      handle := _xmlcfg_open(filename, status);
      if(handle < 0) return defaultDir;
      tagFileDir = _WorkspaceGet_TagFileDir(handle);
      // close the file
      _xmlcfg_close(handle);
   }

   // Was the "TagFileDir" property set ?
   if(tagFileDir != "") {
      tagFileDir = absolute(tagFileDir, workspace_dir);
      _maybe_append_filesep(tagFileDir);
      if (!isdirectory(tagFileDir)) { 
         make_path(tagFileDir);
      }
      return tagFileDir;
   }

   // Otherwise return the default directory
   _maybe_append_filesep(defaultDir);
   return defaultDir;
}
_str VSEWorkspaceStateFilename(_str filename=_workspace_filename)
{
   if (filename=="") return("");
   tagFileDir := VSEWorkspaceTagFileDir(filename);
   workspace_name := _strip_filename(filename,'pe');
   return(tagFileDir:+workspace_name:+WORKSPACE_STATE_FILE_EXT);
}
_str VSEWorkspaceTagFilename(_str filename=_workspace_filename)
{
   if (filename=="") return("");
   tagFileDir := VSEWorkspaceTagFileDir(filename);
   workspace_name := _strip_filename(filename,'pe');
   return(tagFileDir:+workspace_name:+TAG_FILE_EXT);
}
int _OnUpdate_projecttbCheckin(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_vccheckin(cmdui,target_wid,command));
}
int _OnUpdate_projecttbCheckout(CMDUI &cmdui,int target_wid,_str command)
{
   return(_OnUpdate_vccheckout(cmdui,target_wid,command));
}

_command int show_project_properties_files_tab()
{
   project_edit(PROJECTPROPERTIES_TABINDEX_FILES);

   // must return zero for when this function is used a callback during
   // project creation using the "(none)" template.
   return 0;
}
/*
    FileList is a spaced delimited list of double quoted
    strings.
*/
int project_remove_filelist(_str project_filename,_str FileList,bool CacheProjects_TagFileAlreadyOpen=false,bool &removed_a_file=false)
{
   status := 0;
   removed_a_file=false;
   _str TagFilename = project_tags_filename_only(project_filename);
   if (TagFilename!='') {
      tag_remove_filelist(TagFilename, FileList, CacheProjects_TagFileAlreadyOpen);
   }
   if (_IsVCPPWorkspaceFilename(_workspace_filename) && _CanWriteFileSection( GetProjectDisplayName(project_filename) ) ) {
      _RemoveFileFromVCPPMakefile(FileList,GetProjectDisplayName(project_filename),false,removed_a_file);
   } else if (_IsVisualStudioWorkspaceFilename(_workspace_filename)) {
      _RemoveFileFromVisualStudioProject(FileList,GetProjectDisplayName(project_filename),removed_a_file);
   } else if(_IsJBuilderAssociatedWorkspace(_workspace_filename)) {
      _RemoveFilesFromJBuilderProject(FileList,GetProjectDisplayName(project_filename),removed_a_file);
   } else {
      //11:44am 8/18/1997
      //Dan Changed for makefile support
      int handle=_ProjectHandle(project_filename);
      for (;;) {
         _str filename=parse_file(FileList,false);
         if (filename=='') break;
         int Node=_ProjectGet_FileNode(handle,_RelativeToProject(filename,project_filename));
         if (Node>=0) {
            removed_a_file=true;
            _xmlcfg_delete(handle,Node);
         }
      }
      if (removed_a_file && !CacheProjects_TagFileAlreadyOpen) {
         status=_ProjectSave(handle);
         if (status) {
            return(status);
         }
         _ProjectCache_Update();  // Empty the project cache
      }
   }
   if (removed_a_file && !CacheProjects_TagFileAlreadyOpen) {
      toolbarUpdateFilterList(project_filename);

      // regenerate the makefile
      _maybeGenerateMakefile(project_filename);
   }
   return(status);
}

/**
 * Check to see if this project supports makefile generation.
 * Currently only C/C++ and GNU C/C++ projects are supported.
 *
 * @param projectFilename
 *
 * @return T if supported, F otherwise
 */
bool _project_supports_makefile_generation(_str projectFilename)
{
   int handle=_ProjectHandle(projectFilename);
   int array[];
   _ProjectGet_Configs(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      if (strieq(_xmlcfg_get_attribute(handle,array[i],'Type'),'gnuc')) {
         return(true);
      }
   }
   return(false);
}

bool project_is_associated_file(_str ProjectFilename)
{
   makefilename := "";
   int status=_GetAssociatedProjectInfo(ProjectFilename,makefilename);
   if (!status && makefilename!='') {
      //How else could there even be a file if there is no FILES section?
      return(true);
   }
   return(false);
}
int _OnUpdate_project_load(CMDUI &cmdui,int target_wid,_str command)
{
   if (!_haveSmartOpen()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO_OR_STANDARD;
      }
      return MF_GRAYED|MF_REQUIRES_PRO_OR_STANDARD;
   }
   if (_project_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

static _str _project_load_callback(int reason,var result,typeless key)
{
   _nocheck _control _sellistok,_sellist;
   orig_wid := p_window_id;

   if (reason==SL_ONINIT || reason==SL_ONSELECT) {
      int ok_wid=_sellistok;
      if (_sellist.p_Nofselected) {
         if (!ok_wid.p_enabled) {
            ok_wid.p_enabled=true;
         }
      } else {
         ok_wid.p_enabled=false;
      }
      return('');
   }

   if (reason==SL_ONDEFAULT) {  // Enter key
      if (!_sellistok.p_enabled) {
         return('');
      }
      int sellist_wid=_control _sellist;
      p_window_id=sellist_wid;
      top();up();
      done := 0;
      _macro('m',_macro('s'));
      for (;;) {
         down();
         if (rc) break;
         get_line(auto line);
         while (!_lbisline_selected()) {
            if (_delete_line()) {
               done=1;
               break;
            }
         }
         if (done ) break;
         _str filename,path;
         parse _lbget_text() with filename "\t" path;
         filename=path:+filename;
         int status=edit('+q '_maybe_quote_filename(filename),EDIT_DEFAULT_FLAGS);
         _macro_call('edit',_maybe_quote_filename(filename));
         p_window_id=sellist_wid;
      }
      p_window_id=orig_wid;
      return(1);
   }
   user_button := reason==SL_ONUSERBUTTON;
   if (user_button) {
      return('');
   }
   return('');
}
/**
 * List files in the current project and lets you quickly edit one or more.
 * 
 * @param projectOptions   Specifies which project files to load files
 *                         from.  By default it lets you select from all
 *                         files in your workspace.  If you give it the
 *                         "-p" option, it will restrict the list to
 *                         your current active project.  Finally, you
 *                         can give a specific project file (or list of
 *                         project files).
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
_command void project_load(_str projectOptions='') name_info(MULTI_FILE_ARG ','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   projectFiles := false;
   if ( projectOptions != '' ) {
      while ( projectOptions != '' ) {
         _str option = parse_file(projectOptions, false);
         if ( lowcase(option) == '-p' ) {
            projectFiles = true;
         }
      }
   }
   do {
      if ( projectFiles ) {
         activate_files_project();
         break;
      }
      activate_files_workspace();
   } while ( false );
   return;
   if (_project_name=='') return;
   orig_view_id := 0;
   get_window_id(orig_view_id);
   _str title=nls('Load Files');
   p_window_id=_mdi.p_child;
   _macro_delete_line();
   int _start_buf_id=p_buf_id;
   //11:45am 8/18/1997
   //Dan changed for makefile support
   //status=_ini_get_section(_project_get_filename(),"FILES",temp_view_id);

   workspace_files_view_id := 0;
   get_window_id(orig_view_id);
   _str project_list[];
   status := 0;
   if (projectOptions != '') {
      while (projectOptions != '') {
         _str option = parse_file(projectOptions, false);
         if (option == '-p') {
            project_list[project_list._length()] = _project_get_filename();
         } else if (_first_char(option) == '-') {
            message("Unrecognized option: "option);
            break;
         } else {
            project_list[project_list._length()] = option;
         }
      }
   } else {
      status = _GetWorkspaceFiles(_workspace_filename,project_list);
   }
   if (!status) {
      _create_temp_view(workspace_files_view_id);
      int i;
      WorkspacePath := _strip_filename(_workspace_filename,'N');
      for (i=0;i<project_list._length();++i) {
         CurFilename := absolute(project_list[i],WorkspacePath);
         status=GetProjectFiles(
            CurFilename,workspace_files_view_id,"",null,"",false);
         /*if (status) {
            //_delete_temp_view(workspace_files_view_id);
            break;
         } */
      }
      activate_window(orig_view_id);
   }

   activate_window(workspace_files_view_id);
   // Remove blank lines
   top();
   for (;;) {
      status=search('^ *$','rh@');
      if (status) break;
      _delete_line();
   }
   if (p_Noflines==0) {
      _delete_temp_view(workspace_files_view_id);
      activate_window(orig_view_id);
      _set_focus();_message_box(nls('No files in this project'));
      return;
   }

   line := "";
   top();up();
   while (!down()) {
      get_line(line);
      replace_line(' '_strip_filename(line,'p'):+"\t":+_strip_filename(line,'n'));
   }
   sort_buffer(_fpos_case);
   _remove_duplicates(_fpos_case);
   int isearch_case=(_isUnix()?SL_MATCHCASE:0);
   _str buttons=nls('&Open');
   activate_window(orig_view_id);
   typeless result=show('_sellist_form -mdi -modal',
               title,
               isearch_case|SL_SELECTCLINE|SL_SELECTPREFIXMATCH|SL_COMBO|SL_COLWIDTH|SL_SELECTALL|SL_INVERT|SL_ALLOWMULTISELECT|SL_VIEWID|SL_DEFAULTCALLBACK|SL_SIZABLE,
               workspace_files_view_id,
               buttons,
               'Load Files dialog box',        // help item name
               '',                    // font
               _project_load_callback,   // Call back function
               '',                       // Item separator for list data
               'project_load'            // Retrieve form name
              );
   if (result=='') {
      return;
   }
}

static _str localFindFile(_str filename)
{
   if (file_exists(filename)) {
      return filename;
   }
   qualifiedName := getcwd();
   _maybe_append_filesep(qualifiedName);
   qualifiedName :+= filename;
   if (file_exists(qualifiedName)) {
      return qualifiedName;
   }
   return '';
}

_str _prompt_for_duplicate_files(_str fileList)
{
   fileName := "";
   _str fileArray[];
   bool trueArray[];
   bool hash:[];

   _str filename;
   foreach (fileName in fileList) {
      filename=fileName;
      fileName = strip(fileName, 'B', '"');
      if (!hash._indexin(_file_case(fileName))) {
         fileArray[fileArray._length()] = fileName;
         trueArray[trueArray._length()] = fileArray._length()==1;
         hash:[_file_case(fileName)]=true;
      }
   }
   if (fileArray._length() == 1) {
      return filename;
   }

   fileList = select_tree(fileArray, null, null, null, trueArray, null, null, 
                          "Select Files To Open", SL_ALLOWMULTISELECT|SL_INVERT|SL_SELECTALL|SL_SELECTCLINE, null, null, 
                          true, null, "prompt_for_duplicate_files");

   if (fileList != '' && fileList != COMMAND_CANCELLED_RC) {
      fileArray._makeempty();
      split(fileList, "\n", fileArray);
      fileList = "";
      foreach (fileName in fileArray) {
         if (fileList != '') fileList :+= ' ';
         fileList :+= _maybe_quote_filename(fileName);
      }
   }
   return fileList;
}

/**
 * Command line version of the <b>project_load -p</b> command. 
 * Edits the file(s) specified.  Only the file names need to be supplied, 
 * not their entire paths.
 * <p> 
 * If you need to edit a file whose name contains space characters, 
 * place double quotes around the name.
 * <p> 
 * This command accepts most of the same options as the edit() command.  
 *
 * @appliesTo Edit_Window
 * @return Returns 0 if successful. 
 *
 * @see edit 
 * @see project_load 
 * @categories File_Functions
 */
_command edit_file_in_project,ep(_str filenames='') name_info(PROJECT_FILE_ARG'*,'VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (filenames=='') {
      project_load("-p");
      return '';
   }

   editArgumentList := "";
   foreach (auto f in filenames) {
      // check for simple 'edit' options
      if (_first_char(f)=='-' || _first_char(f)=='+') {
         if (editArgumentList != '') editArgumentList :+= ' ';
         editArgumentList :+= f' ';
         continue;
      }
      // qualify the file name by search for it in the current project
      foundFileList := _projectFindFile(_workspace_filename, _project_name, f, 0, 1);
      if (foundFileList == '') {
         foundFileList = _maybe_quote_filename(localFindFile(f));
         if (foundFileList == '') {
            _message_box("File not found: "f);
            return -1;
         }
      } else {
         foundFileList = _prompt_for_duplicate_files(foundFileList);
         if (foundFileList=='') {
            return COMMAND_CANCELLED_RC;
         }
      }
      if (editArgumentList != '') editArgumentList :+= ' ';
      editArgumentList :+= foundFileList;
   }

   _macro('m',_macro('s'));
   _macro_delete_line();
   _macro_append("edit("_quote(editArgumentList)");");
   return edit(editArgumentList, EDIT_RESTOREPOS);
}

/**
 * Command line version of the <b>project_load</b> command. 
 * Edits the file(s) specified.  Only the file names need to be supplied, 
 * not their entire paths.
 * <p> 
 * If you need to edit a file whose name contains space characters, place double
 * quotes around the name. 
 * <p> 
 * This command accepts most of the same options as the edit() command.  
 *
 * @appliesTo Edit_Window
 * @return Returns 0 if successful. 
 *
 * @see edit 
 * @see project_load 
 * @categories File_Functions
 */
_command edit_file_in_workspace,ew(_str filenames='') name_info(WORKSPACE_FILE_ARG'*,'VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (filenames=='') {
      project_load();
      return '';
   }

   editArgumentList := "";
   foreach (auto f in filenames) {
      // check for simple 'edit' options
      if (_first_char(f)=='-' || _first_char(f)=='+') {
         if (editArgumentList != '') editArgumentList :+= ' ';
         editArgumentList :+= f;
         continue;
      }
      // qualify the file name by search for it in the current project
      foundFileList := _WorkspaceFindFile(f, _workspace_filename, false, false, true);
      if (foundFileList == '') {
         foundFileList = _maybe_quote_filename(localFindFile(f));
         if (foundFileList == '') {
            _message_box("File not found: "f);
            return -1;
         }
      } else {
         foundFileList = _prompt_for_duplicate_files(foundFileList);
         if (foundFileList=='') {
            return COMMAND_CANCELLED_RC;
         }
      }
      if (editArgumentList != '') editArgumentList :+= ' ';
      editArgumentList :+= foundFileList;
   }

   _macro('m',_macro('s'));
   _macro_delete_line();
   _macro_append("edit("_quote(editArgumentList)");");
   return edit(editArgumentList);

}

int readAndParseProjectToolList(_str projectFileName, _str sectionName,
                                int initDirectoryControls, typeless &ChildHT,
                                int projectPack, _str (&packInfo)[],
                                ProjectToolStruct (&projectToolList)[]=null,
                                ProjectDirStruct &DirInfo=null,
                                ProjectCmdStruct &CmdInfo=null,
                                _str &ClassPath=null,
                                _str &AppType=null,
                                _str &Libs=null,
                                _str &OutputFile=null,
                                //_str &LangType=null,
                                bool expand_copy_from=false)
{
   name := "";
   caption := "";
   dialogName := "";
   otherKey := "";
   appType := "";

   status := 0;
   typeless iline;
   ClassPath='';
   Libs = '';
   OutputFile = '';
   //LangType = '';
   DirInfo.UserIncludeDirs = '';
   DirInfo.SystemIncludeDirs = '';
   DirInfo.ReferencesFile='';
   CmdInfo.PreBuildCmds = '';
   CmdInfo.PostBuildCmds = '';
   CmdInfo.StopOnPreBuildErrors = '0';
   CmdInfo.StopOnPostBuildErrors = '0';

   if (projectPack) {
      iline._makeempty();
   } else {
      // Read the section data from project file:
      int temp_view_id;
      status=_ini_get_section(projectFileName, sectionName, temp_view_id);

      if (status) {
         _initPredefinedToolList(projectToolList);
         updateToolAccelText(projectToolList);
         return(1);
      }
      if (expand_copy_from) {
         _project_expand_copy_from_view(temp_view_id);
      }
   }
   projectToolList._makeempty();

   // Go thru the section and fill the tools' hash table:
   int first;
   first= 1;

   int KeyIndexTable:[];      //This is a table of each items index in the array
                              //indexed by each key.  This is so that when we
                              //find the items that are "apptool_<key>_<Apptype>
                              //we know what to associate them with.

   if (projectPack) {
      _project_expand_copy_from_array(packInfo);
   }

   temp_view_id := 0;
   fname := info := "";
   for (;;) {
      if (projectPack) {
         packInfo._nextel(iline);
         if (iline._isempty()) break;
         parse packInfo[iline] with fname'='info;
      } else {
         // Get the next text line from the temp view:
         // If no more, delete the temp view and its buffer.
         status=_ini_parse_line(temp_view_id, fname, info, first);
         if (status) {
            break;
         }
      }
      _str optionsText=_ProjectGetStr(info,"copts");
      _str key;
      key= lowcase(fname);
      first=0;

      // Make sure tool name key is valid:
      if (!_isToolKeyValid(key)) {
         // This is not a valid name key, check to see if it
         // is a working directory, include dir, or tag files:
         if (initDirectoryControls) {
            /*if (key== "workingdir") {
               //_prjworking_dir.p_text= info;
               ChildHT:["_prjworking_dir"]= info;
               DirInfo.WorkingDir=info;
            } else */if (key== "includedirs") {
               //_prjinclude_dirs.p_text= info;
               ChildHT:["ctlUserIncludesList"]= info;
               DirInfo.UserIncludeDirs=info;
            /*} else if (key== "tagfiles") {
               _prjtag_files.p_text= cb_info;
               ChildHT:["_prjtag_files"]= _prjtag_files.p_text;*/
            } else if(key=="sysincludedirs") {
               ChildHT:["ctlSystemIncludesList"]= info;
               DirInfo.SystemIncludeDirs=info;
            } else if (key== "reffile") {
               //_prjref_files.p_text= info;
               ChildHT:["_prjref_files"]= info;
               DirInfo.ReferencesFile= info;
            }
         }
         if (strieq(key,'classpath')) {
            ClassPath=info;
         } else if (strieq(key,'app_type')) {
            //I didn't really want to put this in this function,
            //but it seemed silly to put it anywhere else since we are going
            //to trip across the data in here anyway.
            info=_GetAppTypeName(info);
            ChildHT:["app_type"]= info;
            AppType=info;
         } else if(strieq(key, 'prebuildcmds')) {
            ChildHT:["ctlPreBuildCmdList"] = info;
            CmdInfo.PreBuildCmds = info;
         } else if(strieq(key, 'postbuildcmds')) {
            ChildHT:["ctlPostBuildCmdList"] = info;
            CmdInfo.PostBuildCmds = info;
         } else if(strieq(key, 'stoponprebuilderrors')) {
            ChildHT:["ctlStopOnPreErrors"] = info;
            CmdInfo.StopOnPreBuildErrors = info;
         } else if(strieq(key, 'stoponpostbuilderrors')) {
            ChildHT:["ctlStopOnPostErrors"] = info;
            CmdInfo.StopOnPostBuildErrors = info;
         } else if(strieq(key, 'libs')) {
            ChildHT:["ctlLibs"] = info;
            Libs = info;
         } else if(strieq(key, 'outputfile')) {
            ChildHT:["ctlOutputFile"] = info;
            OutputFile = info;
         //} else if(strieq(key, 'langtype')) {
         //   ChildHT:["ctlLangType"] = info;
         //   LangType = info;
         }

         // None of the `above...  Must be some other keys
         // in the section.  Ignore them all!
         continue;
      }

      /*

            compile=concur|capture,mycompile
            make=concur|capture,makevnt -!
            rebuild=concur|capture,remakevnt -!

            newtool1=concur|capture|New Tool 1,newtoolcmd -u -B
      */

      // Extract the options text:
      // options text must be before a ':' (which indicates the start of the tool name).
      /*int p1;
      optionsText= cb_info;
      p1= pos(":",cb_info);
      if (p1) optionsText= substr(cb_info,1,p1-1);*/

      ProjectToolStruct toolinfo;
      //9:37am 5/19/2000
      //THIS FORMAT IS NO LONGER CORRECT.  FOR 6.0 THE FORMAT CHANGED!!!!
      //Leaving a copy here just so we have one
      // New tool:
      // For a new tool, we need to parse the tool name for the combo box
      // and the menu caption.  The new tool data from the section has the
      // following format:
      //
      //    newtool1=concur|capture|hide|:New Tool 1:Menu Tool 1,newtoolcmd -u -B
      //             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      //                                 ^^^^^^^^ ^^^^^^^^^^^^^
      //    newtool1=concur|:New Tool 1:Menu Tool 1,newtoolcmd -u -B
      //             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      //                     ^^^^^^^^^^ ^^^^^^^^^^^
      //    newtool1=:New Tool 1:Menu Tool 1,newtoolcmd -u -B
      //             ^^^^^^^^^^^^^^^^^^^^^^^
      //              ^^^^^^^^^^ ^^^^^^^^^^^
      //Here is the 6.0 format:
      // New tool:
      //    newtool1=copts: concur|capture|hide|menu: New Tool 1:Menu Tool 1cmd: newtoolcmd -u -B
      //
      //
      //    newtool1=copts: concur|menu: New Tool 1:Menu Tool 1cmd: newtoolcmd -u -B
      //
      //
      //    newtool1=menu: New Tool 1:Menu Tool 1cmd: newtoolcmd -u -B
      int p1;
      toolinfo.nameKey= key;
      //toolinfo.name= key;
      toolinfo.caption= key;
      _str menu=_ProjectGetStr(info,"menu");
      parse menu with name ':' caption;
      int predefinedToolIndex;
      _isPredefinedTool(key,predefinedToolIndex);
      if (name=='') {
         if (predefinedToolIndex>=0) {
            name=predefToolList[predefinedToolIndex].name;
            caption=predefToolList[predefinedToolIndex].caption;
         } else {
            // This should never happen.
            name=key;
            caption=key;
         }
      }
      toolinfo.name= name;
      toolinfo.caption= caption;
      //Call _ProjectGetStr2 because we don't want the %~other replaced right
      //now.
      _str cmd=_ProjectGetStr2(info,"cmd");
      toolinfo.optionsDialog='';
      toolinfo.cmd= cmd;
      toolinfo.otherOptions= _ProjectGetStr(info,"otheropts");
      toolinfo.appletClass= _ProjectGetStr(info,"appletclass");
      toolinfo.outputExtension= _ProjectGetStr(info,"outputext");
      if (predefinedToolIndex>=0) {
         toolinfo.menuCmd= predefToolList[predefinedToolIndex].menuCmd;
      } else {
         toolinfo.menuCmd= "project-usertool";
      }

      // premacro and postmacro must be parsed first and then removed
      // from the options string because the macro name may contain
      // other options in its name.  for example, if the premacro
      // is 'saveAllFilesForCurrentProject', the 'saveAllFiles' part
      // would be detected as an option
      if (pos('premacro:', optionsText)) {
         beforeOptions := "";
         afterOptions := "";
         macroName := "";
         parse optionsText with beforeOptions 'premacro:' macroName '|' afterOptions;
         toolinfo.preMacro = macroName;

         // rebuild optionsText without premacro
         optionsText = beforeOptions :+ afterOptions;
      } else {
         toolinfo.preMacro = "";
      }

      //if (pos('postmacro:', optionsText)) {
      //   _str beforeOptions = "";
      //   _str afterOptions = "";
      //   _str macroName = "";
      //   parse optionsText with beforeOptions 'postmacro:' macroName '|' afterOptions;
      //   toolinfo.postMacro = macroName;
      //
      //   // rebuild optionsText without premacro
      //   optionsText = beforeOptions :+ afterOptions;
      //} else {
      //   toolinfo.postMacro = "";
      //}

      if (key== "compile" || key== "make" || key== "rebuild") {
         toolinfo.outputConcur= (int)(info=='' || pos('concur', optionsText));
         toolinfo.captureOutput= (int)(info=='' || pos('capture', optionsText));
      } else {
         toolinfo.outputConcur= pos('concur', optionsText)?1:0;
         toolinfo.captureOutput= pos('capture', optionsText)?1:0;
      }
      toolinfo.clearProcessBuf= pos('clear', optionsText)?1:0;
      toolinfo.useVsBuild= pos('vsbuild', optionsText)?1:0;
      toolinfo.buildFirst= pos('buildfirst', optionsText)?1:0;
      toolinfo.saveOptions= PROJ_TOOL_SAVENONE;
      toolinfo.explicitSave= 0;
      toolinfo.noLinkObject= pos('nolink', optionsText)?1:0;
      toolinfo.verbose= pos('verbose', optionsText)?1:0;
      toolinfo.beep= pos('beep', optionsText)?1:0;
      if (_isUnix()) {
         toolinfo.runInXterm= pos('xterm', optionsText)?1:0;
      }
      if (pos('savecurrent', optionsText)) {
         toolinfo.saveOptions= PROJ_TOOL_SAVECURRENT;
         toolinfo.explicitSave= 1;
      } else if (pos('saveall', optionsText)) {
         toolinfo.saveOptions= PROJ_TOOL_SAVEALL;
         toolinfo.explicitSave= 1;
      } else if (pos('savemodified', optionsText)) {
         toolinfo.saveOptions= PROJ_TOOL_SAVEMODIFIED;
         toolinfo.explicitSave= 1;
      } else if (pos('savenone', optionsText)) {
         toolinfo.saveOptions= PROJ_TOOL_SAVENONE;
         toolinfo.explicitSave= 1;
      } else if (pos('saveworkspacefiles', optionsText)) {
         toolinfo.saveOptions= PROJ_TOOL_SAVEWORKSPACEFILES;
         toolinfo.explicitSave= 1;
      } else {
         // Can't find any new "save*" options. Check the def_save_on_compile for
         // tools with command with %f, %p,... specifying a file.
         _str tOption;
         if (pos("(%f)|(%p)|(%n)|(%e)",toolinfo.cmd,1,"RI")) {
            parse def_save_on_compile with tOption .;
            toolinfo.saveOptions= (int)tOption;
         } else if (key== "make" || key== "rebuild") {
            parse def_save_on_compile with . tOption;
            toolinfo.saveOptions= (int)tOption;
         }
      }

      if(pos('hide', optionsText)) {
         toolinfo.hideOptions = PROJ_TOOL_HIDEEMPTY;
      } else if(pos('nevershow', optionsText)) {
         toolinfo.hideOptions = PROJ_TOOL_HIDEALWAYS;
      } else {
         toolinfo.hideOptions = PROJ_TOOL_HIDENEVER;
      }

      if (pos('dialog:', optionsText)) {
         parse optionsText with 'dialog:' dialogName '|' .;
         toolinfo.optionsDialog=dialogName;
      } else {
         toolinfo.optionsDialog = "";
      }

      toolinfo.readOnly=pos('readonly', optionsText)?true:false;
      toolinfo.disableCaptureOutput=pos('disablecapoutput', optionsText)?true:false;
      toolinfo.changeDir= (int)!pos('nochangedir', optionsText);

      // Adjust a few things for correctness. If we are not capturing the output,
      // we should not output to concur buffer or clear buffer. Likewise, if we
      // are capturing output, we must disable "run in xterm".
      if (!toolinfo.captureOutput) {
         toolinfo.outputConcur= 0;
         toolinfo.clearProcessBuf= 0;
      } else {
         if (_isUnix()) {
            //toolinfo.runInXterm = 0;
         }
      }
      NewIndex := projectToolList._length();
      if (substr(key,1,length(PROJ_TOOL_KEY_APPTOOL_PREFIX))==PROJ_TOOL_KEY_APPTOOL_PREFIX) {
         //If this is an apptool line, we store this as part of another
         //entry in projectToolList.
         parse key with (PROJ_TOOL_KEY_APPTOOL_PREFIX)  otherKey '_' appType;
         if (!KeyIndexTable._indexin(otherKey)) {
            _message_box(nls("Error.  Found '%s1' before '%s2' in project file.",key,otherKey));
         }else{
            //Store this item with the "Parent item's" name key, otherwise
            //when we switch the items around we have the wrong key.
            toolinfo.nameKey=otherKey;
            projectToolList[KeyIndexTable:[otherKey]].apptoolHashtab:[appType]=toolinfo;
         }
      }else{
         projectToolList[NewIndex]= toolinfo;
      }

      //Save this index so if we have any apptool "Child" entries for it, we
      //know where to store them.
      KeyIndexTable:[key]=NewIndex;
   }

   updateToolAccelText(projectToolList);
   // Store the entire initial tool table into the hash table so that
   // we can later check changes:
   ChildHT:["projectToolList"]= projectToolList;
   return(0);
}
// Desc:  Build the tool text line for the project file.
//
//        The tool command text has the following formats:
//
//        rebuild=concur|capture,remakevnt -!
//        newtool1=concur|capture|:New Tool 1:Menu Tool 1,newtoolcmd -u -B
//        newtool1=concur|:New Tool 1:Menu Tool 1,newtoolcmd -u -B
//        newtool1=:New Tool 1:Menu Tool 1,newtoolcmd -u -B
//        newtool1=concur|capture|hide|clear|savecurrent|changedir:New Tool 1:Menu Tool 1,newtoolcmd -u -B
//
_str buildToolCommandText(ProjectToolStruct projectTool)
{
   _str text=_chr(1)'copts: ';
   if (projectTool.outputConcur) {
      text :+= "concur";
   }
   if (projectTool.captureOutput) {
      if (text != "") text :+= "|";
      text :+= "capture";
   }
   if (projectTool.clearProcessBuf) {
      if (text != "") text :+= "|";
      text :+= "clear";
   }
   if (projectTool.useVsBuild) {
      if (text != "") text :+= "|";
      text :+= "vsbuild";
   }
   if (projectTool.optionsDialog!='') {
      if (text != "") text :+= "|";
      text :+= "dialog:"projectTool.optionsDialog;
   }
   if (projectTool.preMacro != '') {
      if (text != "") text :+= "|";
      text :+= "premacro:" projectTool.preMacro;
   }
   //if (projectTool.postMacro != '') {
   //   if (text != "") text= text :+ "|";
   //   text= text :+ "postmacro:" projectTool.postMacro;
   //}
   if (projectTool.readOnly) {
      if (text != "") text :+= "|";
      text :+= "readonly";
   }
   if (projectTool.disableCaptureOutput) {
      if (text != "") text :+= "|";
      text :+= "disablecapoutput";
   }
   if (projectTool.buildFirst) {
      if (text != "") text :+= "|";
      text :+= "buildfirst";
   }
   if (_isUnix()) {
      if (projectTool.runInXterm) {
         if (text != "") text :+= "|";
         text :+= "xterm";
      }
   }
   if (projectTool.noLinkObject) {
      if (text != "") text :+= "|";
      text :+= "nolink";
   }
   if (projectTool.verbose) {
      if (text != "") text :+= "|";
      text :+= "verbose";
   }
   if (projectTool.beep) {
      if (text != "") text :+= "|";
      text :+= "beep";
   }
   // explicitSave is set when the save option was loaded directly from
   // the project file or when the user explicitly selects the save option
   // toggle buttons.
   if (projectTool.explicitSave) {
      if (projectTool.saveOptions== PROJ_TOOL_SAVECURRENT) {
         if (text != "") text :+= "|";
         text :+= "savecurrent";
      } else if (projectTool.saveOptions== PROJ_TOOL_SAVEALL) {
         if (text != "") text :+= "|";
         text :+= "saveall";
      } else if (projectTool.saveOptions== PROJ_TOOL_SAVEMODIFIED) {
         if (text != "") text :+= "|";
         text :+= "savemodified";
      } else if (projectTool.saveOptions== PROJ_TOOL_SAVENONE) {
         if (text != "") text :+= "|";
         text :+= "savenone";
      } else if (projectTool.saveOptions== PROJ_TOOL_SAVEWORKSPACEFILES) {
         if (text != "") text :+= "|";
         text :+= "saveworkspacefiles";
      }
   }
   if(projectTool.hideOptions == PROJ_TOOL_HIDEEMPTY) {
      if(text != "") text :+= "|";
      text :+= "hide";
   } else if(projectTool.hideOptions == PROJ_TOOL_HIDEALWAYS) {
      if(text != "") text :+= "|";
      text :+= "nevershow";
   }
   if (!projectTool.changeDir) {
      if (text != "") text :+= "|";
      text :+= "nochangedir";
   }

   // This code appends another '|' at the end of the options string.
   // Not sure if we really need this. Since it does not hurt anything,
   // leave it in for possible backward compatibility.
   if (text != "") text :+= "|";
   text :+= _chr(1);
   text :+= 'menu: ';
   //text= text :+ ":" :+ projectTool.name;
   text :+= projectTool.name;
   _str caption;
   caption= projectTool.caption;
   caption= strip(caption);
#if 0
   if (caption== "") {  // no menu caption?  use the tool name
      caption= "&" :+ projectTool.name;
      projectTool.caption= caption;
   }
#endif
   text :+= ":" :+ caption;
   //text= text :+ ",";
   text :+= _chr(1)'cmd: ';
   text :+= projectTool.cmd;
   text :+= _chr(1)'otheropts: ';
   text :+= projectTool.otherOptions;
   if (projectTool.appletClass!='') {
      text :+= _chr(1)'appletclass: 'projectTool.appletClass;
   }
   if (projectTool.outputExtension!='') {
      text :+= _chr(1)'outputext: 'projectTool.outputExtension;
   }
   return(text);
}
// Desc:  Check the key bindings for each of the tool
//        command and update the accelerator text.
static void updateToolAccelText(ProjectToolStruct (&ToolInfo)[])
{
   int i;
   for (i=0; i<ToolInfo._length(); i++) {
      _str key_binding_list;
      ToolInfo[i].accel= "";

      // Don't show accel for new user defined tools:
      if (ToolInfo[i].menuCmd=='project-usertools') {
         continue;
      }

      // Find all the key bindings for the command:
      int index;
      index= find_index(ToolInfo[i].menuCmd,COMMAND_TYPE);
      if (!index) continue;
      key_binding_list="";
      append_key_bindings(index,key_binding_list,'',
                          _default_keys,
                          _mdi.p_child.p_mode_eventtab);
      key_binding_list= strip(key_binding_list);
      if (key_binding_list== "") continue;

      // If more than one bindings, use the first one:
      int p1;
      p1= pos(",",key_binding_list);
      if (p1) key_binding_list= substr(key_binding_list,1,p1-1);
      ToolInfo[i].accel= key_binding_list;
   }
}
int _convert_to_new_commandstr_format(_str ProjectFilename,
                                             _str SectionName='COMPILER')
{
   int orig_view_id=p_window_id,project_view_id=0;
   int status=_ini_get_section(ProjectFilename,SectionName,project_view_id);
   if (status) {
      return(status);
   }
   version_linenum := -1;
   first := 1;
   p_window_id=project_view_id;
   top();up();
   _str hlist:[];
   _str list[];
   while (!down()) {
      get_line(auto line);
      _str fname,info;
      parse line with fname '=' info;
      first=0;
      key := lowcase(fname);
      if (strieq(fname,'version')) {
         version_linenum=p_line;
      }
      if (_isToolKeyValid(key)) {
         _str cb_info;
         parse info with cb_info ',' info;
         _str optionsText= cb_info;
         p1 := pos(":",cb_info);
         if (p1) optionsText= substr(cb_info,1,p1-1);

         ToolName := ToolCaption := "";
         p1= pos(":", cb_info);
         if (p1) {
            // Extract tool name and menu caption:
            int p2;
            p2= pos(":", cb_info, p1+1);  // locate menu caption
            if (!p2) {
               // No menu caption, use tool name instead:
               ToolName= substr(cb_info, p1+1);
               ToolCaption= key;
            } else {
               // Have both tool name and menu caption:
               ToolName= substr(cb_info, p1+1, p2-p1-1);
               ToolCaption= substr(cb_info, p2+1);
            }
         }
         line=key"=\1copts: "optionsText"\1menu: "ToolName":"ToolCaption"\1cmd: "info;
         if (_isPredefinedTool(key)) {
            hlist:[key]=line;
         } else {
            list[list._length()]=line;
         }
         status=_delete_line();
         if (status) {
            break;
         }
         up();
      }
   }
   // version value has moved to GLOBAL section for project files and
   // extension specific projects.
   // version value has moved to .GLOBAL section for user defined packages
   if (version_linenum>0) {
      p_line=version_linenum;
      _delete_line();
   }
   bottom();
   // We must convert the old non-order command list into an ordered list
   // of commands.
   int i;
   for (i=0;i<predefToolList._length();++i) {
      if (hlist._indexin(predefToolList[i].nameKey)) {
         insert_line(hlist:[predefToolList[i].nameKey]);
      } else if (predefToolList[i].nameKey!='user1' && predefToolList[i].nameKey!='user2') {
         insert_line(predefToolList[i].nameKey'=');
      }
   }
   // Now insert the rest in order
   for (i=0;i<list._length();++i) {
      insert_line(list[i]);
   }
   p_window_id=orig_view_id;
   status=_ini_put_section(ProjectFilename,SectionName,project_view_id);
   return(status);
}

// DJB 04-10-2007
// If they save a project or workspace file, invalidate
// the project tool list cache.
// 
void _cbsave_project_tool_list_cache()
{
   if (_file_eq(_get_extension(p_buf_name,true),PRJ_FILE_EXT) ||
       _file_eq(_get_extension(p_buf_name,true),WORKSPACE_FILE_EXT)) {
      glast_project_tool_list = null;
   }
}
// Also invalidate if the open or close the project.
void _prjopen_project_tool_list_cache()
{
   glast_project_tool_list = null;
}
void _prjclose_project_tool_list_cache()
{
   glast_project_tool_list = null;
}
// Also invalidate if the user changes key bindings
void _eventtab_modify_project_tool_list_cache(typeless keytab_used, _str event="")
{
   glast_project_tool_list = null;
}

void maybeResetLanguageProjectToolList(int isExtProject)
{
   if (isExtProject==1) {
      glast_project_tool_list = null;
   }
}

// Desc:  Get the list of tools for the the current project.
void _projectToolGetList(_str (&toolNameList)[],    // Tool name displayed in combo box
                                                   // "Build" or "API Help"
                        _str (&toolCaptionList)[], // menu caption
                                                   // "&Build" or "Tornado API &Help"
                        _str (&toolMenuCmdList)[], // menu command project-build or
                                                   // project-usertool usertool_api_help
                        _str (&toolCmdList)[],     // command line to parse in parts and execute
                        _str lang,
                         _str absFilename,
                         _str ProjectName=_project_name
                        )
{
   ext := "";
   handle := -1;
   _str config;
   bool newDebugMode;
   if (ProjectName!='') {
      config=GetCurrentConfigName(ProjectName);
      handle=_ProjectHandle(ProjectName);
      newDebugMode=false; // Don't need to know if we are in debug mode.
   } else if(_workspace_filename=='') {
      // Get/set the current single file project
      handle=_fileProjectSetCurrent(lang,absFilename,config);
      // Because the file project code locks the file project when in debug mode,
      // we need to track debug mode for file projects.
      newDebugMode=_tbDebugQMode();
   }

   // DJB 04-10-2007
   // check if cached version is same as what then need now
   if (glast_project_tool_list != null &&
       glast_project_tool_list.workspaceName == _workspace_filename &&
       glast_project_tool_list.projectName == ProjectName &&
       glast_project_tool_list.debugMode == newDebugMode &&
       glast_project_tool_list.configName == config &&
       ((ProjectName!='' && glast_project_tool_list.extension == lang)|| 
        (glast_project_tool_list.extension == lang &&
         _file_eq(glast_project_tool_list.absFilename,absFilename))) &&
       !glast_project_tool_list.toolNameList._isempty()) {
      // copy last values retrieved
      toolNameList    = glast_project_tool_list.toolNameList;
      toolCaptionList = glast_project_tool_list.toolCaptionList;
      toolMenuCmdList = glast_project_tool_list.toolMenuCmdList;
      toolCmdList     = glast_project_tool_list.toolCmdList;
      return;
   }
   //say('l='lang' b='_mdi.p_child.p_buf_name);

   // Find the first build target of active configuration
   TargetNode := -1;
   if (handle>=0) {
      TargetNode=_ProjectGet_FirstTarget(handle,config);
   }

   // Build the arrays tool for the menu system:
   // Only list the tools that are supposed to be shown.
   toolNameList._makeempty();
   toolCaptionList._makeempty();
   toolMenuCmdList._makeempty();
   toolCmdList._makeempty();
   int i,j;
   int count;

   count= 0;
   //say('TargetNode='TargetNode);
   for (;TargetNode>=0;TargetNode=_ProjectGet_NextTarget(handle,TargetNode)) {
      _str text, cmdLine;

      // If tool does not have a command and there is an
      // active buffer, try to use the command from
      // the extension project of the active buffer's extension.
      cmdLine= _ProjectGet_TargetCmdLine(handle,TargetNode);
      TargetName := lowcase(_xmlcfg_get_attribute(handle,TargetNode,'Name'));
      _str ShowOnMenu=_xmlcfg_get_attribute(handle,TargetNode,'ShowOnMenu',VPJ_SHOWONMENU_ALWAYS);
      // If tool still does not have a command...
      if (ShowOnMenu==VPJ_SHOWONMENU_NEVER ||
          (ShowOnMenu==VPJ_SHOWONMENU_HIDEIFNOCMDLINE && cmdLine== "")) {
         continue;
      }

      if (TargetName=='debug' && _project_DebugCallbackName!='' &&
          _project_DebugConfig) {
         continue;
      }
      toolNameList[count]= TargetName;
      text= _xmlcfg_get_attribute(handle,TargetNode,'MenuCaption');

      key_binding_list := "";
      accel := "";
      int index;
      index= find_index(cmdLine,COMMAND_TYPE);
      if (index) {
         key_binding_list="";
         append_key_bindings(index,key_binding_list,'',
                             _default_keys,
                             _mdi.p_child.p_mode_eventtab);
         key_binding_list= strip(key_binding_list);
         if (key_binding_list!= "") {
            // If more than one bindings, use the first one:
            int p1;
            p1= pos(",",key_binding_list);
            if (p1) key_binding_list= substr(key_binding_list,1,p1-1);
            accel= key_binding_list;
         }

      }

      if (accel != "") {
         text :+= "\t" :+ accel;
      }
      toolCaptionList[count]= text;

      // For non-predefined user tools, concat the tool key:
      int ToolIndex;
      if (!(_isPredefinedTool2(TargetName,ToolIndex))) {
         text= "project_usertool ":+TargetName;
      } else {
         text= predefToolList[ToolIndex].menuCmd;
      }
      toolMenuCmdList[count]= text;

      // If the command line requires a file name (or variations of it)
      // or a current word, and there is no edit window, treat the
      // item as if it has no command line:
      if (_workspace_filename=='' && cmdLine=='' && lang!='') {
         switch(TargetName) {
         case 'build':
         case 'compile':
            if (index_callable(find_index('_on_autocreateworkspace_'lang,PROC_TYPE))) {
               cmdLine=_chr(1);
            }
         }
      } else {
         _str tempCmdLine;
         tempCmdLine= stranslate(cmdLine,"","%%");
         if (lang=="" &&
             pos("(%f)|(%p)|(%n)|(%e)|(%c[~p])",tempCmdLine,1,"RI")
            ) {
            cmdLine= "";
         // Can't do this for single file projects!
         //} else if (ProjectName=="" && pos("(%r)|(%rp)|(%rn)",tempCmdLine,1,"RI")) {
         //   cmdLine= "";
         }
      }
      toolCmdList[count]= cmdLine;

      ++count;
   }
   if (toolCaptionList._length()==0) {
      for (i=0; i<predefToolList._length(); ++i) {
         if (strieq(predefToolList[i].name,'User 1') ||
             strieq(predefToolList[i].name,'User 2') ||
             predefToolList[i].hideOptions
             ) {
            continue;
         }
         j=toolCmdList._length();
         toolCmdList[j]='';
         toolMenuCmdList[j]='';
         if (ProjectName=='') {
            if (strieq(predefToolList[i].name,'compile')) {
               toolCmdList[j]='project-compile';
               toolMenuCmdList[j]='project-compile';
            } else if (strieq(predefToolList[i].name,'build')) {
               toolCmdList[j]='project-build';
               toolMenuCmdList[j]='project-build';
            }
         }
         toolCaptionList[j]=predefToolList[i].caption;
         toolNameList[j]=predefToolList[i].name;
      }
   }

   // update the cache
   glast_project_tool_list.workspaceName = _workspace_filename;
   glast_project_tool_list.projectName = ProjectName;
   glast_project_tool_list.configName = config;
   glast_project_tool_list.debugMode = newDebugMode;
   glast_project_tool_list.extension = lang;
   glast_project_tool_list.absFilename = absFilename;
   // update the results
   glast_project_tool_list.toolNameList    = toolNameList;
   glast_project_tool_list.toolCaptionList = toolCaptionList;
   glast_project_tool_list.toolMenuCmdList = toolMenuCmdList;
   glast_project_tool_list.toolCmdList     = toolCmdList;
}
bool _isPredefinedTool(_str nameKey,int &toolIndex=0)
{
   if (_isToolKeyInProjectToolTable(nameKey,toolIndex,predefToolList)) {
      return(true);
   }
   return(false);
}
bool _isPredefinedTool2(_str TargetName,int &toolIndex=0)
{
   if (_isToolKeyInProjectToolTable2(TargetName,toolIndex,predefToolList)) {
      return(true);
   }
   return(false);
}
// Desc:  Check to see if the specified key is a valid key.
// Retn:  1 for yes, 0 for no.
int _isToolKeyValid(_str key)
{
   // Check to see if the key is one of the predefined tools:
   int i;
   for (i=0; i<predefToolList._length(); i++) {
      if (strieq(key, predefToolList[i].nameKey)) {
         return(1);
      }
   }

   // Maybe a new key:
   // Make sure key has a valid tool name key prefix.
   if (pos(PROJ_TOOL_KEY_USERTOOL_PREFIX, key, 1, "I")==1) {
      return(1);
   }
   // Maybe a new key:
   // See if the key has a valid apptool name key prefix.
   if (pos(PROJ_TOOL_KEY_APPTOOL_PREFIX, key, 1, "I")==1) {
      return(1);
   }

   // may be an extension-specific compile command
   // compile(.ext)
   if (pos(PROJ_TOOL_KEY_COMPILE_REGEX, key, 1, "U")==1) {
      return(1);
   }

   return(0);
}

// Desc:  Initialize the project tool list with the
//        list of predefined tools.
//2:10pm 7/23/1999
//Dan made global to call from wkspace.e
void _initPredefinedToolList(ProjectToolStruct (&ToolInfo)[])
{
   ToolInfo= predefToolList;
}

_str _GetAppTypeName(_str AppType)
{
   _str thisname;
   parse AppType with thisname '-';
   return(lowcase(strip(thisname)));
}

static int _GetAssociatedProjectInfoOld(_str ProjectFilename,_str &VendorProjectFilename,_str &VendorProjectType='')
{
   int status=_ini_get_value(ProjectFilename,"Association","makefile",VendorProjectFilename,'');
   if (status) {
      return(status);//Doesn't have to be an association
   }
   VendorProjectFilename=absolute(VendorProjectFilename,_strip_filename(ProjectFilename,'N'));

   status=_ini_get_value(ProjectFilename,"Association","makefiletype",VendorProjectType,'');

   return(status);
}
static int _convert_to_new_config_type(_str ProjectFilename,_str (&ConfigNames)[],_str WorkspaceFilename)
{
   int i;
   line := "";
   orig_view_id := p_window_id;
   activeconfig := "";
   CompilerSectionViewId := 0;
   int status=_ini_get_section(ProjectFilename,"COMPILER",CompilerSectionViewId);
   if (status) {
      return(0);
   }
   vendorProjectFilename := "";
   //_ini_get_value(ProjectFilename,"ASSOCIATION",'makefile',vendorProjectFilename,'');
   _GetAssociatedProjectInfoOld(ProjectFilename,vendorProjectFilename);
   CompilerSectionExists := !status;
   p_window_id=CompilerSectionViewId;
   if (!status) {
      putSection := false;
      top();up();
      status=search('^activeconfig=','@rhi');
      if (!status) {
         get_line(activeconfig);
         parse activeconfig with '=' activeconfig;
         _delete_line();
         status=_ini_set_value(VSEWorkspaceStateFilename(WorkspaceFilename),"ActiveConfig",_RelativeToWorkspace(ProjectFilename,WorkspaceFilename),activeconfig,_fpos_case);
         putSection=true;
      }
      top();up();
      status=search('^workingdir=','@rhi');
      if (!status) {
         get_line(auto workingdir);
         parse workingdir with '=' workingdir;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'workingdir',workingdir);
         putSection=true;
      }
      top();up();
      status=search('^vcsproject=','@rhi');
      if (!status) {
         get_line(auto vcsproject);
         parse vcsproject with '=' vcsproject;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'vcsproject',vcsproject);
         putSection=true;
      }
      top();up();
      status=search('^vcslocalpath=','@rhi');
      if (!status) {
         get_line(auto vcslocalpath);
         parse vcslocalpath with '=' vcslocalpath;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'vcslocalpath',vcslocalpath);
         putSection=true;
      }
      top();up();
      status=search('^MACRO=','@rhi');
      if (!status) {
         get_line(auto macro);
         parse macro with '=' macro;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'macro',macro);
         putSection=true;
      }
      top();up();
      status=search('^FILTERNAME=','@rhi');
      if (!status) {
         get_line(auto filtername);
         parse filtername with '=' filtername;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'FILTERNAME',filtername);
         putSection=true;
      }

      top();up();
      status=search('^FILTERPATTERN=','@rhi');
      if (!status) {
         get_line(auto filterpattern);
         parse filterpattern with '=' filterpattern;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'FILTERPATTERN',filterpattern);
         putSection=true;
      }

      top();up();
      status=search('^FILTERAPPCOMMAND=','@rhi');
      if (!status) {
         get_line(auto filterappcommand);
         parse filterappcommand with '=' filterappcommand;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'FILTERAPPCOMMAND',filterappcommand);
         putSection=true;
      }

      top();up();
      status=search('^FILTERASSOCIATEFILETYPES=','@rhi');
      if (!status) {
         get_line(auto filterassociatefiletypes);
         parse filterassociatefiletypes with '=' filterassociatefiletypes;
         _delete_line();
         status=_ini_set_value(ProjectFilename,"GLOBAL",'FILTERASSOCIATEFILETYPES',filterassociatefiletypes);
         putSection=true;
      }

      if (putSection) {
         _ini_put_section(ProjectFilename,"COMPILER",CompilerSectionViewId);
      }else{
         p_window_id=orig_view_id;
         _delete_temp_view(CompilerSectionViewId);
      }
   }
   p_window_id=orig_view_id;
   temp_view_id := 0;
   status=_ini_get_section(ProjectFilename,"CONFIGURATIONS",temp_view_id);
   if (CompilerSectionExists) {
      if (status && vendorProjectFilename=='') {
         status=_ini_duplicate_section(ProjectFilename,"COMPILER","COMPILER."PROJ_FIRST_CONFIG_NAME);
         _ini_delete_section(ProjectFilename,"COMPILER");
         status=_ini_set_value(VSEWorkspaceStateFilename(WorkspaceFilename),"ActiveConfig",_RelativeToWorkspace(ProjectFilename,WorkspaceFilename),','PROJ_FIRST_CONFIG_NAME,_fpos_case);
         status=_ini_set_value(ProjectFilename,"CONFIGURATIONS",'config',','PROJ_FIRST_CONFIG_NAME);
      }else if (status && vendorProjectFilename!='') {
         //If this is a VC++ project that had been opened in 5.0x, we
         //may have never written a configurations section.  We have
         //to get the configuration information from the .dsp file.
         ProjectConfig configList[]=null;
         _getAssociatedProjectConfigs(ProjectFilename,configList);

         //create a view for the CONFIGURATIONS section that we have to build.
         //We can't just call _ini_set_value, because we will be listing multiple values
         //for "config=".
         int configSectionViewId ;
         orig_view_id=_create_temp_view(configSectionViewId);
         p_window_id=orig_view_id;

         for (i=0;i<configList._length();++i) {
            ConfigNames[ConfigNames._length()]=configList[i].config;
            status=_ini_duplicate_section(ProjectFilename,"COMPILER","COMPILER."configList[i].config);

            //Put the configuraton in the CONFIGURATIONS section
            p_window_id=configSectionViewId;
            insert_line('config='configList[i].objdir','configList[i].config);
            if (!i) {
               //If this is the first one, set it as the active configuration
               status=_ini_set_value(VSEWorkspaceStateFilename(WorkspaceFilename),"ActiveConfig",_RelativeToWorkspace(ProjectFilename,WorkspaceFilename),configList[i].objdir','configList[i].config,_fpos_case);
               //insert_line('activeconfig='configList[i].objdir','configList[i].config);
            }
            p_window_id=orig_view_id;
         }
         _ini_put_section(ProjectFilename,"CONFIGURATIONS",configSectionViewId);
         _ini_delete_section(ProjectFilename,"COMPILER");
      }else{
         p_window_id=temp_view_id;
         //_str ConfigNames[]=null;
         top();up();
         while (!down()) {
            get_line(line);
            _str CurConfigName;
            parse line with ',' CurConfigName;
            ConfigNames[ConfigNames._length()]=CurConfigName;
         }
         if (!ConfigNames._length()) {
            ConfigNames[0]=PROJ_FIRST_CONFIG_NAME;
         }
         p_window_id=orig_view_id;
         status=0;
         for (i=0;i<ConfigNames._length();++i) {
            status=_ini_duplicate_section(ProjectFilename,"COMPILER","COMPILER."ConfigNames[i]);
            if (status) {
               _message_box(nls("Could not create section %s1.\n\n%s2","COMPILER."ConfigNames[i],get_message(status)));
               p_window_id=orig_view_id;
               return(status);
            }
         }
         if (!status) {
            _ini_delete_section(ProjectFilename,"COMPILER");
         }
      }
   }
   p_window_id=orig_view_id;
   return(status);
}
// Write the configurations to the project file.
static int _writeConfigurations(_str filename,_str (&configList)[],_str activeConfig,_str objdir)
{
   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   if (orig_view_id=='') return(0);
   int i;
   for (i=0;i<configList._length();++i) {
      insert_line('config='objdir','configList[i]);
   }
   //insert_line('activeconfig='activeConfig);
   _ini_set_value(VSEWorkspaceStateFilename(), "ActiveConfig", _RelativeToWorkspace(filename), activeConfig,_fpos_case);
   int status=_ini_put_section(filename,"CONFIGURATIONS",temp_view_id);
   p_window_id=orig_view_id;
   return(0);
}
static _str getActiveProjectConfigOld(_str ProjectFilename=_project_name)
{
   configName := "";
   //int status = _ini_get_value(ProjectFilename,"CONFIGURATIONS","activeconfig",configName);
   int status=_ini_get_value(VSEWorkspaceStateFilename(), "ActiveConfig", _RelativeToWorkspace(ProjectFilename), configName,'',_fpos_case);
   if (status) return("");
   return(configName);
}
/*
   This function is called when reading from a extension specific
   project file or a project file.
   DO NOT call this function for a project file.
*/
static void _ProjectUpgradePackage(_str ProjectFilename)
{
   if (ProjectFilename=='') return;
   _str found_config_name=PROJ_FIRST_CONFIG_NAME;
   info := "";
   old_info := "";
   cmd := "";
   key := "";
   int i,j;
   typeless junk,junk1;
   int status= _ini_get_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,"make",info);
   if (status) {
      status= _ini_get_value(ProjectFilename,"COMPILER.Debug","make",info);
      if (status) return;
      found_config_name="Debug";
   }
   cmdname := "";
   parse _ProjectGetStr2(info,'cmd') with cmdname .;
   if (cmdname=='javamake') {
      javapackver := "";
      _ini_get_value(ProjectFilename,"COMPILER."found_config_name,'packver',javapackver,0);
      if (javapackver<3) {
         _ini_set_value(ProjectFilename,"GLOBAL","packname",'Java');
         _ini_set_value(ProjectFilename,"GLOBAL","macro_switchconfig",'_on_switchconfig_java');
         _ini_set_value(ProjectFilename,"GLOBAL",'app_type_list','application,applet,custom');
         _str filename = _getSysconfigMaybeFixPath("projects":+FILESEP:+VSCFGFILE_PRJPACKS());
         ProjectToolStruct javaToolList[];
         int ii;
         for (ii=1;ii<=2;++ii) {
            _str setConfigName=found_config_name;
            _str getConfigName=found_config_name;
            if (ii==2) {
               setConfigName='Debug';
               getConfigName='Debug';
               status=_ini_get_value(ProjectFilename,"COMPILER."setConfigName,
                              'execute',junk);
               if (status) break;  // Too hard to add debug section.  User can do this easily.
            }
            status=readAndParseProjectToolList(
               filename,'Java - Empty Project;'setConfigName,0,junk1,0,null,
               javaToolList,null,null,null,null,null,null,true);
            if (status) {
               return;
            }
            jdbname := javaname := "";
            debug_index := -1;
            execute_index := -1;
            execute_cmd := "";_str debug_cmd='';
            ExeName := _strip_filename(ProjectFilename,'PE');
            for (i=0;i<javaToolList._length();++i) {

               _str text;
               info= buildToolCommandText(javaToolList[i]);
               key=lowcase(javaToolList[i].nameKey);
               switch (key) {
               case 'debug':
               case 'execute':
               case 'compile':
               case 'usertool_make_jar':
                  _ini_get_value(ProjectFilename,"COMPILER."getConfigName,key,old_info);
                  if (old_info!='') {
                     cmd=_ProjectGetStr2(old_info,'cmd');
                     if (key=='debug' || key=='execute') {
                        _str tempcmd=cmd;
                        _str pgm=parse_file(tempcmd);
                        name := _strip_filename(strip(pgm,'B','"'),'PE');
                        if (_file_eq(name,'jdb') || _file_eq(name,'java')) {
                           // IF a classpath option was not specified
                           if (!pos('-classpath|-cp',tempcmd,1,'ri') &&
                               !pos('%cp',tempcmd,1,'i')) {
                              cmd=pgm' %cp 'tempcmd;
                           }
                        }
                        if (key=='debug') {
                           jdbname=name;
                           debug_index=i;
                           debug_cmd=cmd;
                        } else {
                           javaname=name;
                           execute_index=i;
                           execute_cmd=cmd;
                        }
                     }
                     _ProjectPutStr2(info,'cmd',cmd);
                     if (key=='usertool_make_jar') {
                        // Translate %f or %n%e which may be in double quotes to %{*.*}
                        // This fixes a 5.0 bug where make jar is disabled when no
                        // files are open.  make jar does not really operate on the current file
                        // but the %f makes it look like it does.
                        newParam := "%{*.*}";
                        if (_isUnix()) {
                           newParam = "'%{*}'";
                        }
                        cmd=stranslate(cmd,newParam,'("|)(%f|%n%e)("|)','ri');
                        _ProjectPutStr2(info,'cmd',cmd);
                     }
                     if (key=='compile') {
                        // Only support "%f" now.
                        cmd=stranslate(cmd,'"%f"','("|)%n%e("|)','ri');
                        _ProjectPutStr2(info,'cmd',cmd);
                     }
                  }
                  break;
               case 'usertool_javadoc_all':
                  _ini_get_value(ProjectFilename,"COMPILER."getConfigName,'usertool_javadoc',old_info);
                  if (old_info!='') {
                     cmd=_ProjectGetStr2(old_info,'cmd');
                     if (cmd!='') {
                        cmd='javamakedoc 'cmd;
                        cmd=stranslate(cmd,"%{*.java}",'("|)(%f|%n%e)("|)','ri');
                        _ProjectPutStr2(info,'cmd',cmd);
                     }

                  }
               }
               switch (key) {
               case 'debug':
               case 'execute':
               case 'usertool_make_jar':
                  info=stranslate(info,ExeName,"%<e");
                  break;
               }
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,key,info);
               if (key=='debug' || key=='execute') {
                  status=_ini_get_value(ProjectFilename,"COMPILER."setConfigName,
                                 'apptool_'key'_application',junk);
                  if (status) {
                     int temp_view_id,orig_view_id;
                     status=_open_temp_view(ProjectFilename,temp_view_id,orig_view_id);
                     if (!status) {
                        status=_ini_find_section("COMPILER."setConfigName);
                        if (!status) {
                           _end_line();
                           save_search(auto a,auto b,auto c,auto d);
                           status=search('^'_escape_re_chars(key)'=', 'rhi@');
                           restore_search(a,b,c,d);
                           if (!status) {
                              typeless tkey;
                              for(tkey=null;;){
                                 javaToolList[i].apptoolHashtab._nextel(tkey);
                                 if (tkey==null) break;
                                 info=buildToolCommandText(javaToolList[i].apptoolHashtab:[tkey]);
                                 info=stranslate(info,ExeName,"%<e");
                                 insert_line('apptool_'key'_'tkey:+'=':+info);
                              }
                              status=_save_file("+o");
                           }
                        }
                     }
                     _delete_temp_view(temp_view_id);
                     activate_window(orig_view_id);
                  }
               }
            }
            _str app_type=APPTYPE_APPLICATION;
            if (!_file_eq(jdbname,'jdb') || !_file_eq(javaname,'java')) {
               app_type=APPTYPE_CUSTOM;
            }
            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,'app_type',app_type);
            // This should always be true
            if (execute_index>=0) {
               _str execute_info;
               execute_info=buildToolCommandText(javaToolList[execute_index].apptoolHashtab:[lowcase(app_type)]);
               _ProjectPutStr2(execute_info,'cmd',execute_cmd);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,'execute',execute_info);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,
                              'apptool_execute_'app_type,execute_info);

               execute_info=buildToolCommandText(javaToolList[execute_index].apptoolHashtab:['custom']);
               _ProjectPutStr2(execute_info,'cmd',execute_cmd);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,
                              'apptool_execute_custom',execute_info);
            }

            // This should always be true
            if (debug_index>=0) {
               _str debug_info;
               debug_info=buildToolCommandText(javaToolList[debug_index].apptoolHashtab:[lowcase(app_type)]);
               _ProjectPutStr2(debug_info,'cmd',debug_cmd);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,'debug',debug_info);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,
                              'apptool_debug_'app_type,debug_info);

               debug_info=buildToolCommandText(javaToolList[debug_index].apptoolHashtab:['custom']);
               _ProjectPutStr2(debug_info,'cmd',debug_cmd);
               _ini_set_value(ProjectFilename,"COMPILER."setConfigName,
                              'apptool_debug_custom',debug_info);
            }

            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,'usertool_javadoc',null);
            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,"packver",3);
         }
         _WorkspacePutProjectDate(ProjectFilename);
      }
      if (javapackver<4) {
         _ini_set_value(ProjectFilename,"GLOBAL","packtype","java");
         _ini_set_value(ProjectFilename,"GLOBAL","DebugCallbackName",'jdwp');
         _str filename = _getSysconfigMaybeFixPath("projects":+FILESEP:+VSCFGFILE_PRJPACKS());
         new_application_debug_info := "";
         _ini_get_value_expand_copy_from(filename,'Java - Empty Project;'found_config_name,'apptool_debug_application',new_application_debug_info);
         ProjectToolStruct javaToolList[];
         int ii;
         for (ii=1;ii<=2;++ii) {
            _str setConfigName=found_config_name;
            _str getConfigName=found_config_name;
            if (ii==2) {
               setConfigName='Debug';
               getConfigName='Debug';
               status=_ini_get_value(ProjectFilename,"COMPILER."setConfigName,
                              'execute',junk);
               if (status) break;  // Too hard to add debug section.  User can do this easily.
            }
            app_type := "";
            _ini_get_value(ProjectFilename,"COMPILER."getConfigName,'app_type',app_type,APPTYPE_APPLICATION);
            if (app_type!=APPTYPE_APPLICATION) {
               continue;
            }
            info=new_application_debug_info;
            key='debug';
            _ini_get_value(ProjectFilename,"COMPILER."getConfigName,key,old_info);
            main_class := '.';
            if (old_info!='') {
               old_execute_info := "";
               _ini_get_value(ProjectFilename,"COMPILER."getConfigName,'execute',old_execute_info);
               _str old_execute_cmd=_ProjectGetStr2(old_execute_info,'cmd');
               main_class=_GetJavaMainFromCommandLine(old_execute_cmd);
               if (main_class=='') {
                  main_class='.';
               }
            }
            new_debug_cmd := strip(_ProjectGetStr2(info,'cmd'));
            if (_last_char(new_debug_cmd)=='.') {
               new_debug_cmd=substr(new_debug_cmd,1,length(new_debug_cmd)-1):+main_class;
               _ProjectPutStr2(info,'cmd',new_debug_cmd);
            } else {
               _message_box('Unable to transfer main class for Java project into debug settings');
            }
            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,'apptool_'key'_application',info);
            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,key,info);

            //_ini_set_value(ProjectFilename,"COMPILER."setConfigName,"langtype","java");

            _ini_set_value(ProjectFilename,"COMPILER."setConfigName,"packver",4);
         }
         _WorkspacePutProjectDate(ProjectFilename);
      }
      if (javapackver<5) {
         _ini_set_value(ProjectFilename,"GLOBAL","packtype","java");

         //
         // check all configurations for an empty build directory.  if it was empty,
         // replace it with "classes" which was the default for packver 4.  from this
         // point on, blank will mean do not use -d option.
         //

         // get the configurations for the project and remember the active config

         _str configList[];
         _ini_get_sections_list(ProjectFilename,configList,'COMPILER.');

         //ProjectConfig configList[] = null;
         //getProjectConfigs(ProjectFilename, configList, 0);
         _str activeConfig = getActiveProjectConfigOld(ProjectFilename);

         // save the updated project configuration information
         _writeConfigurations(ProjectFilename, configList, activeConfig,"classes");


         //
         // update specific commands in each configuration
         //
         int l;
         for(l = 0; l < configList._length(); l++) {
            _str command;

            // check the compile command for '-d "%bd"' and replace it with '%jbd'
            _ini_get_value(ProjectFilename, configList[l], "compile", command);
            if(command == "") continue;

            command = stranslate(command, "%jbd", "-d \"%bd\"");
            _ini_set_value(ProjectFilename, configList[l], "compile", command);

            // update the package version
            _ini_set_value(ProjectFilename, configList[l], "packver", 5);
         }

         _WorkspacePutProjectDate(ProjectFilename);
      }
   }

   // detect GNU c++ packages to upgrade
   packtype_info := packname_info := "";
   status= _ini_get_value(ProjectFilename,"GLOBAL","packtype",packtype_info);
   if (status) {
      status= _ini_get_value(ProjectFilename,"GLOBAL","packname",packname_info);
      if (status) return;
      parse packname_info with packname_info .;
   }
   if (strieq(packtype_info,"gnuc") || packname_info=="GNU") {
      _ini_set_value(ProjectFilename,"GLOBAL","DebugCallbackName",'gdb');
      _WorkspacePutProjectDate(ProjectFilename);
   }

}

void _UpdateProjectFileActiveConfig(_str WorkspaceFilename,_str absoluteProjectFilename)
{
   // get the absolute project filename
   ActiveConfig := "";
   _ini_get_value(absoluteProjectFilename,'CONFIGURATIONS','activeconfig',ActiveConfig);

   if (ActiveConfig!='') {
      _ini_set_value(absoluteProjectFilename,'CONFIGURATIONS','activeconfig',null);
      _ini_set_value(VSEWorkspaceStateFilename(WorkspaceFilename),"ActiveConfig",_RelativeToWorkspace(absoluteProjectFilename,WorkspaceFilename),ActiveConfig,_fpos_case);
      _ini_set_value(absoluteProjectFilename,"GLOBAL","version",PROJECT_FILE_VERSION);
      _WorkspacePutProjectDate(absoluteProjectFilename,WorkspaceFilename);
   }
}
static void ConvertViewToRelative(int ViewId,_str WorkingDir)
{
   orig_view_id := p_window_id;
   p_window_id=ViewId;

   filename := "";
   top();up();
   for (;;) {
      if (down()) break;
      get_line(filename);
      replace_line(relative(filename,WorkingDir));
   }
   p_window_id=orig_view_id;
}
static int _convert_to_relative_project_file(_str ProjectFilename)
{
   int status;
   // If they had a references database (.vtr), blow it away
   // Beyond 5.0, VTR files are not supported, however, if the
   // references file is a .bsc file, leave it alone
   _str referencesFile;
   status = _ini_get_value(ProjectFilename,"COMPILER."GetCurrentConfigName(),"reffile",referencesFile);
   if (!status) {
      if (_file_eq(_get_extension(referencesFile),REF_FILE_EXT)) {
         _ini_set_value(ProjectFilename,"COMPILER."GetCurrentConfigName(),"reffile","");
      }
   }

   // Check to see if this project is an old project and that it needs
   // to have its project files converted from absolute to relative.
   _str versionText;
   status = _ini_get_value(ProjectFilename,"COMPILER."GetCurrentConfigName(),"version",versionText);
   if (!status) {
      // Can also check for version being >= 50. Since version string
      // is introduced in 5.0, don't need the check.
      return(0);
   }

   // Convert project files to relative.
   workingdir := _strip_filename(ProjectFilename,'N');
   orig_view_id := p_window_id;
   temp_view_id := 0;
   status=_ini_get_section(ProjectFilename,"Files",temp_view_id);
   if (status) {
      return(status);
   }
   ConvertViewToRelative(temp_view_id,workingdir);
   p_window_id=orig_view_id;
   status=_ini_put_section(ProjectFilename,"Files",temp_view_id);

   // Add the version into the converted project.
   _WorkspacePutProjectDate(ProjectFilename);

   return(status);
}
/**
 * Updates a project file to format of the current
 * version.
 *
 * @param ProjectFilename
 *               Name of project file to update.
 */
void _UpdateProjectFile(_str ProjectFilename,_str WorkspaceFilename=_workspace_filename)
{
   ChangedFile := false;

   // Check to see if this project is an old project and that it needs
   // to have its project files converted from absolute to relative.
   versionText := "";

   _ini_get_value(ProjectFilename,'GLOBAL',"version",versionText,0);
   //If we get a status, version has to be before 5.0
   if (isalpha(_last_char(versionText))) {
      versionText=substr(versionText,1,length(versionText)-1);
   }
   if (versionText<7) {
      _UpdateProjectFileActiveConfig(WorkspaceFilename,ProjectFilename);
   }

   if (versionText<6) {
      //Files from before version 6.0 have to have their command strings
      //converted to the new format.
      _convert_to_new_commandstr_format(ProjectFilename);//Have to do this one first...

      _str ConfigNames[]=null;
      _convert_to_new_config_type(ProjectFilename,ConfigNames,WorkspaceFilename);
      ChangedFile=true;
   }
   if (versionText<5) {
      //Files from before version 5.0 have to be converted to relative
      _convert_to_relative_project_file(ProjectFilename);
      ChangedFile=true;
   }
   // Add the version into the converted project.
   status := 0;
   if (ChangedFile) {
      status=_ini_set_value(ProjectFilename,"GLOBAL","version",PROJECT_FILE_VERSION);
      filtername := filterpattern := filterappcommand := filterassociatefiletypes := "";
      _ini_get_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERNAME',filtername);
      _ini_set_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERNAME',null);
      _ini_get_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERPATTERN',filterpattern);
      _ini_set_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERPATTERN',null);
      _ini_get_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERAPPCOMMAND',filterappcommand);
      _ini_set_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERAPPCOMMAND',null);
      _ini_get_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERASSOCIATEFILETYPES',filterassociatefiletypes);
      _ini_set_value(ProjectFilename,"COMPILER."PROJ_FIRST_CONFIG_NAME,'FILTERASSOCIATEFILETYPES',null);

      if (filtername!='') {
         _ini_set_value(ProjectFilename,'GLOBAL','FILTERNAME',filtername);
      }
      if (filterpattern!='') {
         _ini_set_value(ProjectFilename,'GLOBAL','FILTERPATTERN',filterpattern);
      }
      if (filterappcommand!='') {
         _ini_set_value(ProjectFilename,'GLOBAL','FILTERAPPCOMMAND',filterappcommand);
      }
      if (filterassociatefiletypes!='') {
         _ini_set_value(ProjectFilename,'GLOBAL','FILTERASSOCIATEFILETYPES',filterassociatefiletypes);
      }
      _WorkspacePutProjectDate(ProjectFilename,WorkspaceFilename);
   }
   _ProjectUpgradePackage(ProjectFilename);
}


// Desc:  Check to see if the specified tool key is already
//        in tool table.  Tool key is the key used to identify
//        which tool in the project file.
//        If in table, the index to the tool is returned in toolIndex.
// Retn:  1 for in table, 0 for not
int _isToolKeyInProjectToolTable(_str key, int & toolIndex,ProjectToolStruct projectToolList[])
{
   toolIndex= -1;
   int i;
   for (i=0; i<projectToolList._length(); i++) {
      if (strieq(key, projectToolList[i].nameKey)) {
         toolIndex= i;
         return(1);
      }
   }
   return(0);
}
// Desc:  Check to see if the specified tool key is already
//        in tool table.  Tool key is the key used to identify
//        which tool in the project file.
//        If in table, the index to the tool is returned in toolIndex.
// Retn:  1 for in table, 0 for not
int _isToolKeyInProjectToolTable2(_str TargetName, int & toolIndex,ProjectToolStruct projectToolList[])
{
   toolIndex= -1;
   int i;
   for (i=0; i<projectToolList._length(); i++) {
      if (strieq(TargetName, projectToolList[i].name)) {
         toolIndex= i;
         return(1);
      }
   }
   return(0);
}

// Desc:  Check to see if the specified tool name is already
//        in tool table.  Tool name is the text used in the
//        tool name combo box.  It is also the name that the user
//        assigns to a new key.
//        If in table, the index to the tool is returned in toolIndex.
// Retn:  1 for in table, 0 for not
int _isToolNameInProjectToolTable(ProjectToolStruct atoolList[],
                                        _str name, int & toolIndex)
{
   toolIndex= 0;
   int i;
   for (i=0; i<atoolList._length(); ++i) {
      ProjectToolStruct toolInfo;
      toolInfo= atoolList[i];

      if (strieq(name, toolInfo.name)) {
         toolIndex= i;
         return(1);
      }
   }
   return(0);
}


#if 0
// Desc:  Read and parse all known extension projects.
// Retn:  0 for OK, 1 for error.
int readAndParseAllExtensionProjects()
{
   if (gProjectExtHandle>=0) {
      _xmlcfg_close(gProjectExtHandle);
   }
   filename := usercfg_path_search(VSCFGFILE_USER_EXTPROJECTS);
   if (filename=='') {

      _str oldfilename=_isUnix()?'uproject.slk':'project.slk';    // Move old 7.0 file
      oldfilename=usercfg_path_search(oldfilename);

      filename=_ConfigPath():+VSCFGFILE_USER_EXTPROJECTS;
      if (editor_name('s')!='' && // if state file exists (not building state file)
          oldfilename!='' && _ini_is_valid(oldfilename)) {
         // RGH - 5/30/06
         // Putting in call to make_path here to make sure _config_path exists before we copy the file
         status := 0;
         if (!isdirectory(_ConfigPath())) { 
            status = make_path(_ConfigPath());
         }
         if (!status) {
            copy_file(oldfilename,filename);
            _ProjectConvert70ToXML(filename,true);
         } else {
            return(1);
         }
      } else {
         gProjectExtHandle=_ProjectCreateUserLangSpecificConfigFile(filename);
         return(0);
      }
   }
   if (gProjectExtHandle>=0) _xmlcfg_close(gProjectExtHandle);
   status := 0;
   gProjectExtHandle=_xmlcfg_open(filename,status);
   if (gProjectExtHandle<0) {
      if (status != FILE_NOT_FOUND_RC) {
         _message_box(nls("Extension project file '%s' is not recognized as valid",filename));
      }
      gProjectExtHandle=_ProjectCreateUserLangSpecificConfigFile(filename);
      return(0);
   }
   _ProjectMaybeUpdateLangSpecificConfigs(gProjectExtHandle);
   return(0);
}
#endif
_str _ProjectGetStr2(_str info,_str FieldName)
{
   FieldName="\1"FieldName":";
   FieldInfo := "";
   parse info with (FieldName) FieldInfo "\1" .;
   return(strip(FieldInfo));
}
void _ProjectPutStr2(_str &info,_str FieldName,_str FieldInfo)
{
   before := after := "";
   parse info with before ("\1"FieldName":") . "\1" +0 after;
   info=before:+"\1"FieldName": "strip(FieldInfo):+after;
}

_str _ProjectGetStr(_str Info,_str FieldName)
{
   if (FieldName=='cmd') {
      _str cmd=_ProjectGetStr2(Info,FieldName);
      _str other=_ProjectGetStr2(Info,"otheropts");
      int p=pos('(^|[~%])\%\~other',cmd,1,'r');
      cmd2 := "";
      if (p) {
         if (p>1) {
            cmd2=substr(cmd,1,p);
            ++p;
         }
         cmd2 :+= other:+substr(cmd,p+7);
      }else cmd2=cmd;
      return(cmd2);
   }else{
      return(_ProjectGetStr2(Info,FieldName));
   }
}

/**
 * Show the target form with targets from the specified ant build file
 */
_command int ant_target_form(_str projectAndBuildFile = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Ant Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str projectFile = parse_file(projectAndBuildFile, false);
   _str xmlBuildFile = parse_file(projectAndBuildFile, false);

   if(projectFile == "") {
      message("You must specify a project file.");
      return -1;
   }
   if(xmlBuildFile == "") {
      message("You must specify an XML build file.");
      return -1;
   }

   _str status = show('-mdi -modal -xy _target_form', projectFile, xmlBuildFile);
   return (int)!strieq(status, 0);
}

/**
 * Get the list of targets and their descriptions from the
 * specified ant XML build file
 *
 * @param filename   Ant XML build file
 * @param targetList Will contain the list of targets
 * @param descriptionList
 *                   Will contain the list of descriptions
 * @param includeHyphenedTargets
 *                   Include targets that start with hyphen.  Ant does not allow
 *                   these targets to be called from the command line.
 * @param includeTargetsWithNoDesc
 *                   Include targets that have an empty description.  Most targets
 *                   intended for external use have a description set, but it is
 *                   *not* a requirement
 */
void _ant_GetTargetList(_str filename, _str (&targetList)[], _str (&descriptionList)[],
                        bool includeHyphenedTargets = false,
                        bool includeTargetsWithNoDesc = true,
                        bool findingImportedTargets = false)
{
   status := 0;

   // open the xml build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return;
   }

   typeless indexes[] = null;
   status = _xmlcfg_find_simple_array(handle, "/project/target", indexes, TREE_ROOT_INDEX);
   if(status) {
      if (status) {
         _xmlcfg_close(handle);
         return;
      }
   }

   // if we might be looking for an xml snippet, just check for target nodes
   if (indexes._length() == 0 && findingImportedTargets) {
      status = _xmlcfg_find_simple_array(handle, "//target", indexes, TREE_ROOT_INDEX);
      if (status) {
         _xmlcfg_close(handle);
         return;
      }
   }

   // build target list
   int i;
   for(i = 0; i < indexes._length(); i++) {
      // get the target name
      _str targetName = _xmlcfg_get_attribute(handle, indexes[i], "name");
      _str targetDesc = _xmlcfg_get_attribute(handle, indexes[i], "description", "");

      // check for target names starting with hyphen
      if(!includeHyphenedTargets && _first_char(targetName) == '-') {
         continue;
      }

      // check for target desc that is empty
      if(!includeTargetsWithNoDesc && targetDesc == "") {
         continue;
      }

      // add target to array
      if (findingImportedTargets) {
          targetName :+= " [from " :+ _strip_filename(filename,'P') :+ "]";
      }
      targetList[targetList._length()] = targetName;

      // add description to desc array
      descriptionList[descriptionList._length()] = targetDesc;
   }

   if (def_antmake_display_imported_targets) {
       typeless imports[] = null;
       // check for ant imports
       status = _xmlcfg_find_simple_array(handle, "//import", imports, TREE_ROOT_INDEX);
       if(status) {
          _xmlcfg_close(handle);
          return;
       }
    
       for(i = 0; i < imports._length(); i++) {
          // get the file name
          _str importFile = _xmlcfg_get_attribute(handle, imports[i], "file");
          if (importFile == "") {
              continue;
          }
          // try to resolve the absolute filename
          absName := absolute(importFile,_strip_filename(filename,'N'));
          if (absName == "") {
              continue;
          }
          _ant_GetTargetList(absName,targetList,descriptionList,
                              includeHyphenedTargets,includeTargetsWithNoDesc,true);
       }

       // check for external xml entities
       int dtnode = _xmlcfg_get_first_child(handle,TREE_ROOT_INDEX,VSXMLCFG_NODE_DOCTYPE);
       if(dtnode > 0) {
          _str ht:[];
          status = _xmlcfg_get_attribute_ht(handle,dtnode,ht);
          if(status == 0) {
             _str attr, val;
             _str entities[],ids[];
             foreach( attr => val in ht ) {
                parseFilesFromEntity(val,entities,ids);
             }
             for (i = 0; i < entities._length(); i++) {
                absName := absolute(entities[i],_strip_filename(filename,'N'));
                int temp_wid, orig_wid;
                found_ref := false;
                // open the file and search to see if there is a reference to the entity
                int res = _open_temp_view(filename,temp_wid,orig_wid);
                if (!res) {
                   top();up();
                   found_ref = search('&'ids[i]';','xcs') ? false : true;
                   _delete_temp_view(temp_wid);
                   p_window_id = orig_wid;
                }
                // if there's no reference, don't bother importing the targets
                if (found_ref) {
                   _ant_GetTargetList(absName,targetList,descriptionList,
                                       includeHyphenedTargets,includeTargetsWithNoDesc,true);
                } 
             }
          }
       }
   }

   // close the file
   status = _xmlcfg_close(handle);
   if(status) {
      return;
   }
}

/**
 * Parses the files referenced in XML entities from the entity 
 * statements (if any exist). 
 * 
 * @param entities String containing any xml entity statements 
 *                 in the DOCTYPE, concatenated together
 * @param results (output) Array of files parsed from entity 
 *                statements
 * @param ids (output) Array of ids of entities...parallel with 
 *            results
 *
 */
void parseFilesFromEntity(_str entities,_str (&results)[],_str (&ids)[]) {
   // is there an xml entity?
   isEntity := pos(XML_ENTITY_REGEX,entities,1,'u');
   if (isEntity > 0) {
      // does the entity reference an external xml file?
      parse entities with auto prefix (XML_ENTITY_REGEX) auto id 'SYSTEM' auto file '>' auto suffix;
      if (file != "" && id != "") {
        relname := stranslate(strip(file),"","\"");
        // remove 'file:' prefix if necessary
        if (relname != "" && pos("file:",relname) > 0 && length(relname) >= 6) {
           relname = substr(relname,6);
        }
        results[results._length()] = relname;
        ids[ids._length()] = strip(id);
      }
      parseFilesFromEntity(suffix, results, ids);
   }
}

/**
 * Get the list of other XML build files called from the specified
 * ant XML build file
 *
 * @param filename Ant XML build file
 * @param dependencyList
 * @param basedirList
 */
void _ant_GetDependencyList(_str filename, _str (&dependencyList)[], bool recurse = false)
{
   int masterDepHash:[];
   _str depList[];

   // get dependencies for filename
   _ant_GetDependencyListForFile(filename, depList);
   masterDepHash:[filename] = 1;

   // if not recursing
   if(!recurse) {
      dependencyList = depList;
      return;
   }

   int i;
   for(i = 0; i < depList._length(); i++) {
      // check to see if this dep has already been parsed
      if(!masterDepHash._indexin(depList[i])) {
         // mark as processed
         masterDepHash:[depList[i]] = 1;

         // process this dep
         _ant_GetDependencyListForFile(depList[i], depList);
      }
   }

   typeless j;
   for(j._makeempty();;) {
      masterDepHash._nextel(j);
      if (j._isempty()) break;

      dependencyList[dependencyList._length()] = j;
   }

   // sort the array
   dependencyList._sort("F"_fpos_case);
}

/**
 * Get the list of other XML build files called from the specified
 * ant XML build file
 *
 * @param filename Ant XML build file
 * @param dependencyList
 * @param basedirList
 */
void _ant_GetDependencyListForFile(_str filename, _str (&dependencyList)[])
{
   status := 0;

   // open the xml build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return;
   }

   // each ant build file has a <project> container
   int projectNode = _xmlcfg_find_simple(handle, "/project");
   if(projectNode < 0) {
      _xmlcfg_close(handle);
      return;
   }

   // figure out the basedir that all paths in this build file are relative to
   _str basedir = _ant_GetPropertyValue(filename, "basedir");

   // find all calls to other ant build files
   typeless indexes[] = null;
   status = _xmlcfg_find_simple_array(handle, "/project//ant", indexes, TREE_ROOT_INDEX);
   if(status) {
      _xmlcfg_close(handle);
      return;
   }

   // build dependency list
   int i;
   for(i = 0; i < indexes._length(); i++) {
      // get name of the ant build file.  if not specified, 'build.xml' is implied
      _str antfile = _xmlcfg_get_attribute(handle, indexes[i], "antfile", "build.xml");

      // get the dir where the ant build file is located.  this is relative to the
      // basedir of the current ant build file.  if inheritAll is true, then the
      // basedir is inherited from the parent build file.  if inheritAll is false,
      // basedir is not defined
      inheritAll := strieq(_xmlcfg_get_attribute(handle, indexes[i], "inheritAll", ""), "true");
      _str dir = _xmlcfg_get_attribute(handle, indexes[i], "dir", inheritAll ? basedir : "");

      // parse antfile and dir for ${property} values
      dir = _ant_ParseProperties(filename, dir, false);
      antfile = _ant_ParseProperties(filename, antfile, false);

      // absolute the ant file against the specified dir
      dir = absolute(dir, basedir);
      antfile = absolute(antfile, dir);

      // add dependency to array
      dependencyList[dependencyList._length()] = antfile;
   }

   // close the file
   status = _xmlcfg_close(handle);
   if(status) {
      return;
   }
}

/**
 * Utility function used to find if the cursor is on a 
 * references to a Ant property. ie. ${property}. 
 * 
 * @param w current word 
 * @param sc start column of current word 
 * 
 * @return bool
 */
bool _ant_CursorOnProperty(_str w, int sc){
   // Bail if we aren't in an Ant file
   if (!_isEditorCtl() || p_LangId != ANT_LANG_ID) {
      return false;
   }
   save_pos(auto p);
   p_col = sc;
   _str l = get_text_left();
   found := false;
   if (l == "{") {
      left();
      l = get_text_left();
      if (l == "$") {
         p_col = sc + length(w);
         if (get_text() == "}") {
            found = true;
         }
      }
   }
   restore_pos(p);
   return found;
}

// assuming this is only for being on a property reference
//void _ant_FindContainingTargetOrProject(long &begin_seekpos, long &end_seekpos){
//   begin_seekpos = -1;
//   end_seekpos = -1;
//   // Bail if we aren't in an Ant file
//   if (!_isEditorCtl() || !_ModenameEQ(p_mode_name,ANT_LANG_ID)) {
//      return;
//   }
//   save_pos(auto p);
//   long seek_pos = _nrseek();
//   int status = search('<target','-ixcs');
//   if (status == 0) {
//      begin_seekpos = _nrseek();
//      status = find_matching_paren();
//      if (status == 0) {
//         end_seekpos = _nrseek();
//         if (begin_seekpos < seek_pos && seek_pos < end_seekpos) {
//            restore_pos(p);
//            return;
//         }
//      }
//   }
//   // try project
//   restore_pos(p);
//   status = search('<project','-ixcs');
//   if (status == 0) {
//      begin_seekpos = _nrseek();
//      status = find_matching_paren();
//      if (status == 0) {
//         end_seekpos = _nrseek();
//         if (begin_seekpos < seek_pos && seek_pos < end_seekpos) {
//            restore_pos(p);
//            return;
//         }
//      }
//   }
//   restore_pos(p);
//   begin_seekpos = -1;
//   end_seekpos = -1;
//   return;
//}

/**
 * Get the list of targets from an ant command
 */
void _ant_ParseAntCommand(_str command, _str& filename, _str (&optionList)[], _str (&targetList)[])
{
   // remove executable name
   _str program = parse_file(command);

   // default filename is build.xml in the project directory
   filename = "build.xml";

   // if this is running the macro form or executing a target, it must be parsed differently
   if(program == "ant-target-form" || program == "ant-execute-command") {
      // project will be first argument
      parse_file(command);

      // build file should be second argument
      filename = parse_file(command);

   // handle ant.bat
   } else {
      // figure out which targets are called in the build command
      for(;;) {
         _str option = parse_file(command, false);
         if(option == "") break;

         // determine if this is an option or a target
         if(substr(option, 1, 1) == '-') {
            optionPredicate := "";
            switch(option) {
               case "-buildfile":
               case "-file":
               case "-f":
                  optionPredicate = parse_file(command);
                  optionList[optionList._length()] = option " " optionPredicate;

                  // this overrides the default filename
                  filename = optionPredicate;
                  break;

               case "-logfile":
               case "-l":
               case "-logger":
               case "-listener":
               case "-propertyfile":
               case "-inputhandler":
               case "-find":
                  optionPredicate = parse_file(command);
                  optionList[optionList._length()] = option " " optionPredicate;
                  break;

               default:
                  optionList[optionList._length()] = option;
                  break;
            }
         } else {
            // must be a target
            targetList[targetList._length()] = option;
         }
      }
   }

   // strip any quotes from around the filename
   filename = strip(filename, "B", "\"");

   // make sure at least one target is returned
   if(targetList._length() <= 0) {
      // no targets are specified on this command line so get the default from the build file
      targetList[targetList._length()] = _ant_GetDefaultTarget(filename);
   }
}

/**
 * Get the destdir property of any javac tasks in the specified target
 */
_str _ant_GetJavacDestDirFromTarget(_str filename, _str target)
{
   status := 0;

   // open the xml build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return "";
   }

   int targetNode = _xmlcfg_find_simple(handle, "/project/target" XPATH_STRIEQ("name", target));
   if(targetNode < 0) {
      _xmlcfg_close(handle);
      return "";
   }

   typeless javacNodeList[] = null;
   status = _xmlcfg_find_simple_array(handle, "//javac", javacNodeList, targetNode);
   if(status) {
      _xmlcfg_close(handle);
      return "";
   }

   destdirList := "";
   int i;
   for(i = 0; i < javacNodeList._length(); i++) {
      _str destdir = _xmlcfg_get_attribute(handle, javacNodeList[i], "destdir");

      // parse any ${property} values
      destdir = _ant_ParseProperties(filename, destdir, true);

      if(destdir != "") {
         if(destdirList != "") {
            destdirList :+= FILESEP:+destdir;
         } else {
            destdirList = destdir;
         }
      }
   }

   // close the file
   status = _xmlcfg_close(handle);

   return destdirList;
}

/**
 * Parse the line, replacing all ${property} entries with the appropriate
 * values.  Any properties that cannot be determined can either be left
 * in the line or removed (replaced with "").
 */
_str _ant_ParseProperties(_str filename, _str line, bool removeIfNotFound = true)
{
   start := 1;
   for(;;) {
      int offset = pos("\\$\\{(.*?)\\}", line, start, "U");
      if(!offset) break;

      // get the name and value of the property
      propertyStatus := 0;
      propertyName := substr(line, pos("S1"), pos("1"));
      _str propertyValue = _ant_GetPropertyValue(filename, propertyName, propertyStatus);
      if(propertyStatus == 0 || removeIfNotFound) {
         // replace the placeholder
         line = substr(line, 1, offset - 1) :+ propertyValue :+ substr(line, offset + 3 + length(propertyName));
      } else {
         // not found and removeIfNotFound == false so step past the
         // offset so it will not be detected again
         start = offset + 1;
      }
   }

   return line;
}

/**
 * Get the value of the specified ant property in the specified XML build file
 *
 * All builtin and system properties that can be determined by this function
 * are supported.  If a value cannot be determined, status is returned as -1.
 *
 * NOTE: Currently does not support properties files and environment variables
 */
_str _ant_GetPropertyValue(_str filename, _str property, int& status = 0)
{
   value := "";
   status = 0;
   found := true;

   // open the xml build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return "";
   }

   // check for supported builtin or system properties
   // NOTE: safe to use == because property names are case-sensitive

   // basedir is specified as the basedir attribute of the project tag
   if(property == "basedir") {
      // figure out the basedir that all paths in this build file are relative to.  the
      // basedir may be declared using a <property> task or as an attribute to the
      // <project> tag.  the documentation states that if it is defined as a property,
      // it must be omitted from the project.  therefore, the project overrides and
      // should be searched for first.  if a basedir is not specified, the dir where
      // the build file resides will be used
      int projectNode = _xmlcfg_find_simple(handle, "/project");
      if(projectNode > 0) {
         _str basedir = _xmlcfg_get_attribute(handle, projectNode, "basedir");
         if(basedir == "") {
            // check for a <property> tag that specifies it
            int basedirPropertyNode = _xmlcfg_find_simple(handle, "//property" XPATH_STRIEQ("name", "basedir"));
            if(basedirPropertyNode >= 0) {
               // use this property
               basedir = _xmlcfg_get_attribute(handle, basedirPropertyNode, "location", "");
            }

            // if basedir is still not defined, use the path of the ant build file
            if(basedir == "") {
               basedir = _strip_filename(filename, 'N');
            }
         }
         value = absolute(basedir, _strip_filename(filename, 'N'));

         // ant does not put the trailing FILESEP on the basedir
         value = strip(value, "T", FILESEP);
      } else {
         // flag that it was not found
         found = false;
      }

   // ant.file is the absolute path to the build file
   } else if(property == "ant.file") {
      value = filename;

   // ant.project.name is specified as the name attribute of the project tag
   } else if(property == "ant.project.name") {
      int projectNode = _xmlcfg_find_simple(handle, "/project");
      if(projectNode > 0) {
         // check the basedir attribute
         value = _xmlcfg_get_attribute(handle, projectNode, "name");
         if(value != "") {
            // this value may be relative to the build.xml file so absolute it
            value = absolute(value, _strip_filename(filename, "N"));
         }
      } else {
         // flag that it was not found
         found = false;
      }

   // java.home is the value of the jdk install dir that is being used
   } else if(property == "java.home") {
      value = def_jdk_install_dir;

   // file.separator is FILESEP
   } else if(property == "file.separator") {
      value = FILESEP;

   // path.separator is PATHSEP
   } else if(property == "path.separator") {
      value = PATHSEP;

   // line.separator is \r\n on win32 and \n on unix
   } else if(property == "line.separator") {
      if(_isUnix()) {
         value = "\n";
      } else {
         value = "\r\n";
      }

   // not a builtin so search for it
   } else {
      int propertyNode = _xmlcfg_find_simple(handle, "/project//property" XPATH_STRIEQ("name", property));
      if(propertyNode >= 0) {
         // check for a value attribute
         value = _xmlcfg_get_attribute(handle, propertyNode, "value");
         if(value == "") {
            // if value is empty, check for a location attribute
            value = _xmlcfg_get_attribute(handle, propertyNode, "location");
         }
      } else {
         // flag that it was not found
         found = false;
      }
   }

   // close the file
   status = _xmlcfg_close(handle);

   if(!status && !found) {
      status = -1;
   }

   return value;
}

/**
 * Get the value of the specified ant property in the specified XML build file
 *
 * NOTE: This currently only supports locally declared properties.  Support
 *       for properties files and environment variables needs to be added.
 */
_str _ant_GetDefaultTarget(_str filename)
{
   status := 0;

   // open the xml build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return "";
   }

   int projectNode = _xmlcfg_find_simple(handle, "/project");
   if(projectNode < 0) {
      _xmlcfg_close(handle);
      return "";
   }

   // check for a value attribute
   _str target = _xmlcfg_get_attribute(handle, projectNode, "default");

   // close the file
   status = _xmlcfg_close(handle);

   return target;
}

/**
 * Execute the specified target in the specified XML build file
 *
 * @param filenameArgsTargets
 *               Project, Filename, arguments, and target list to be passed to ant
 */
_command void ant_execute_target(_str filenameArgsTargets = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Ant Build support");
      return;
   }
   // are we in debug mode and trying to do edit and continue?
   debugReload := false;
   if(debug_active() && debug_is_hotswap_enabled()) {
      debugReload = true;
      debug_set_compile_time();
   } else if(_DebugMaybeTerminate()) {
      return;
   }

   // save workspace files
   _mdi.p_child.save_all(-1, true, true);

   // project is first argument
   _str projectName = parse_file(filenameArgsTargets);
   if(projectName == "") {
      message("You must specify the project that contains this build file.");
   }
   projectName = _AbsoluteToWorkspace(projectName);

   // ant should be run in the directory that the build file lives in so
   // parse the filename
   _str antBuildFile = parse_file(filenameArgsTargets);
   if(antBuildFile != "") {
      // change to the directory where the build file lives
      buildFileDir := _strip_filename(antBuildFile, "N");
      if(buildFileDir != "") {
         cd(buildFileDir);
      }

      // now that the dir has been changed, remove the path from the file
      antBuildFile = _strip_filename(antBuildFile, "P");
   }

   // build ant command line
   _str command = "\"%(VSLICKBIN1)vsbuild\" \"%w\" \"%r\" ";
   if (def_antmake_use_classpath == 0) {
      command :+= '-noclasspath';
   }
   // if we appended any imported target information, strip it off before we go to project_command
   newargs := stranslate(filenameArgsTargets,'',ANT_IMPORTED_TARGET_REGEX,'ui');
   command :+= " -execastarget antmake -emacs -f " _maybe_quote_filename(antBuildFile) " " newargs;
   command = _parse_project_command(command, "", projectName, "");

   // setup the environment
   if(set_ant_environment()) {
      _message_box("Ant or JDK installation not found.\n\nYou must set the Ant and JDK installation directories.");
      return;
   }

   // execute the target
   if(debugReload) {
      int status=dos("-e -v " command);
      if (status) {
         _DisplayErrorMessageBox();
         return;
      }
      debug_reload();
   } else {
      //dos("-e -v -s " command);
      concur_command(command, def_process  && !def_process_tab_output);
      loop_until_on_last_process_buffer_command();
   }
}

/**
 * Get the list of targets and their descriptions from the specified 
 * makefile.  Will search included makefiles for their targets and will 
 * find target names dependent on macros and will find multiple targets 
 * defined on the same line. 
 *  
 * @param filename   makefile
 * @param targetList Will contain the list of targets
 * @param descriptionList
 *                   Will contain the list of descriptions
 */
void _makefile_GetTargetList(_str filename, _str startDirectory, _str (&targetList)[], _str (&descriptionList)[])
{
   MI_makefile_GetTargetList(filename, startDirectory, targetList, descriptionList, false);
   return;
}

/**
 * Default make program that is used when a makefile target is executed.
 */
_str def_default_make_program = 'make';

/**
 * Builds the command when a makefile target is executed.  Normally, this 
 * command is to a version of make. 
 * 
 * @param makefile_name        Full path and name of makefile
 * @param filenameArgsTargets  Filename, arguments, and target list to be passed 
 *                             to make command
 * @param projectName          Name of the current project 
 * 
 * @return Command to execute
 */
static _str build_make_command(_str makefile_name, _str filenameArgsTargets, _str projectName)
{
   _str command = def_default_make_program" -f " makefile_name " " filenameArgsTargets " CFG=%b";
   command = _parse_project_command(command, "", projectName, "");
   return command;
}

/**
 * Execute the specified target in the specified makefile
 *
 * @param filenameArgsTargets
 *               Filename, arguments, and target list to be passed to make
 */
_command void makefile_execute_target(_str filenameArgsTargets = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Makefile support");
      return;
   }
   // are we in debug mode and trying to do edit and continue?
   debugReload := false;
   if(debug_active() && debug_is_hotswap_enabled()) {
      debugReload = true;
      debug_set_compile_time();
   } else if(_DebugMaybeTerminate()) {
      return;
   }

   // save workspace files
   _mdi.p_child.save_all(-1, true, true);

   // project is first argument
   _str projectName = parse_file(filenameArgsTargets);
   if(projectName == "") {
      message("You must specify the project that contains this build file.");
   }
   projectName = _AbsoluteToWorkspace(projectName);
   
   // makefiles should be run in the directory where they live so parse the command line
   _str makefile = parse_file(filenameArgsTargets);
   if(makefile != "") {
      // change to the directory where the makefile lives
      makefileDir := _strip_filename(makefile, "N");
      if(makefileDir != "") {
         cd(makefileDir);
      }

      // now that the dir has been changed, remove the path from the file
      makefile = _strip_filename(makefile, "P");
   }

   // build command line
   _str command = build_make_command(_maybe_quote_filename(makefile), filenameArgsTargets, projectName);

   // execute the target
   if(debugReload) {
      int status=dos("-e -v " command);
      if (status) {
         _DisplayErrorMessageBox();
         return;
      }
      debug_reload();
   } else {
      concur_command(command, def_process  && !def_process_tab_output);
   }
}

/**
 * Show the target form with targets from the specified makefile
 */
_command int makefile_target_form(_str projectAndMakefile = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Makefile support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str projectFile = parse_file(projectAndMakefile, false);
   _str makefile = parse_file(projectAndMakefile, false);

   if(projectFile == "") {
      message("You must specify a project file.");
      return -1;
   }
   if(makefile == "") {
      message("You must specify a makefile.");
      return -1;
   }

   _str status = show('-mdi -modal -xy _target_form', projectFile, makefile);
   return (int)!strieq(status, 0);
}


/**
 * Execute the specified target in the specified XML build file
 *
 * @param filenameArgsTargets
 *               Project, Filename, arguments, and target list to be passed to ant
 */
_command void nant_execute_target(_str filenameArgsTargets = "") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Nant Build support");
      return;
   }
   // are we in debug mode and trying to do edit and continue?
   debugReload := false;
   if(debug_active() && debug_is_hotswap_enabled()) {
      debugReload = true;
      debug_set_compile_time();
   } else if(_DebugMaybeTerminate()) {
      return;
   }

   // save workspace files
   _mdi.p_child.save_all(-1, true, true);

   // project is first argument
   _str projectName = parse_file(filenameArgsTargets);
   if(projectName == "") {
      message("You must specify the project that contains this build file.");
   }
   projectName = _AbsoluteToWorkspace(projectName);

   // ant should be run in the directory that the build file lives in so
   // parse the filename
   _str antBuildFile = parse_file(filenameArgsTargets);
   if(antBuildFile != "") {
      // change to the directory where the build file lives
      buildFileDir := _strip_filename(antBuildFile, "N");
      if(buildFileDir != "") {
         cd(buildFileDir);
      }

      // now that the dir has been changed, remove the path from the file
      antBuildFile = _strip_filename(antBuildFile, "P");
   }

   // build NAnt command line
   _str command = "\"%(VSLICKBIN1)vsbuild\" \"%w\" \"%r\" ";
   if (def_antmake_use_classpath == 0) {
      command :+= '-noclasspath';
   }
   command :+= " -execastarget nant /f:" _maybe_quote_filename(antBuildFile) " " filenameArgsTargets;
   command = _parse_project_command(command, "", projectName, "");

   // setup the environment
   if(set_nant_environment()) {
      _message_box("NAnt installation not found.\n\nYou must set the NAnt installation directory.");
      return;
   }

   // execute the target
   if(debugReload) {
      int status=dos("-e -v " command);
      if (status) {
         _DisplayErrorMessageBox();
         return;
      }
      debug_reload();
   } else {
      //dos("-e -v -s " command);
      concur_command(command, def_process  && !def_process_tab_output);
      loop_until_on_last_process_buffer_command();
   }
}

/**
 * Determine if this file is a NAnt XML build file
 *
 * @param filename
 *
 * @return
 */
bool _IsNAntBuildFile(_str filename)
{
   // check that it ends in the proper extension
   if(!_file_eq(_get_extension(filename, true), NANT_BUILD_FILE_EXT)) {
      return false;
   }

   // open the file
   tempstatus := 0;
   int handle = _xmlcfg_open(filename, tempstatus, VSXMLCFG_OPEN_REFCOUNT);
   if(handle <= 0) {
      return false;
   }

   // if a .build file has xpath /project/target then it is
   // most likely a NAnt build file
   int node = _xmlcfg_find_simple(handle, "/project/target");

   // close the file
   _xmlcfg_close(handle);

   return (node >= 0);
}

/**
 * Get the list of targets and their descriptions from the
 * specified NAnt XML build file
 *
 * @param filename   NAnt XML build file
 * @param targetList Will contain the list of targets
 * @param descriptionList
 *                   Will contain the list of descriptions
 * @param includeHyphenedTargets
 *                   Include targets that start with hyphen.
 *                   NAnt does not allow these targets to be
 *                   called from the command line.
 * @param includeTargetsWithNoDesc
 *                   Include targets that have an empty description.  Most targets
 *                   intended for external use have a description set, but it is
 *                   *not* a requirement
 */
void _nant_GetTargetList(_str filename, _str (&targetList)[], _str (&descriptionList)[],
                        bool includeHyphenedTargets = false,
                        bool includeTargetsWithNoDesc = true){
   _ant_GetTargetList(filename,targetList,descriptionList,includeHyphenedTargets,includeTargetsWithNoDesc);
}

/**
 * Get the list of other XML build files called from the specified
 * ant XML build file
 *
 * @param filename Ant XML build file
 * @param dependencyList
 * @param basedirList
 */
void _nant_GetDependencyList(_str filename, _str (&dependencyList)[], bool recurse = false)
{
   int masterDepHash:[];
   _str depList[];

   // get dependencies for filename
   _nant_GetDependencyListForFile(filename, depList);
   masterDepHash:[filename] = 1;

   // if not recursing
   if(!recurse) {
      dependencyList = depList;
      return;
   }

   int i;
   for(i = 0; i < depList._length(); i++) {
      // check to see if this dep has already been parsed
      if(!masterDepHash._indexin(depList[i])) {
         // mark as processed
         masterDepHash:[depList[i]] = 1;

         // process this dep
         _ant_GetDependencyListForFile(depList[i], depList);
      }
   }

   typeless j;
   for(j._makeempty();;) {
      masterDepHash._nextel(j);
      if (j._isempty()) break;

      dependencyList[dependencyList._length()] = j;
   }

   // sort the array
   dependencyList._sort("F"_fpos_case);
}

/**
 * Get the list of other XML build files called from the specified
 * ant XML build file
 *
 * @param filename Ant XML build file
 * @param dependencyList
 * @param basedirList
 */
void _nant_GetDependencyListForFile(_str filename, _str (&dependencyList)[])
{
   status := 0;

   // open the .build file
   int handle = _xmlcfg_open(filename, status, VSXMLCFG_OPEN_REFCOUNT);
   if(handle < 0 || status < 0) {
      return;
   }

   // each NAnt .build file has a <project> container
   int projectNode = _xmlcfg_find_simple(handle, "/project");
   if(projectNode < 0) {
      _xmlcfg_close(handle);
      return;
   }

   // figure out the basedir that all paths in this build file are relative to
   basedir := _strip_filename(filename, 'NE');

   // build dependency list from list of <include buildfile='file.build'/> tags

   // First, find the <include> tags that are immediate children of the root
   // <project> document node
   typeless indexes[] = null;
   status = _xmlcfg_find_simple_array(handle, "/project/include", indexes, TREE_ROOT_INDEX);
   if(status) {
      _xmlcfg_close(handle);
      return;
   }

   // Build list of included files (buildfile= attribute)
   int i;
   for(i = 0; i < indexes._length(); i++) {
      // get name of the ant build file.  if not specified, 'build.xml' is implied
      _str includedFile = _xmlcfg_get_attribute(handle, indexes[i], "buildfile", '');

      if(includedFile._length() > 1) {
         // absolute the included file against the specified dir
         includedFileAbs := absolute(includedFile, basedir);
   
         // add dependency to array
         dependencyList[dependencyList._length()] = includedFileAbs;
      }
   }

   // close the file
   status = _xmlcfg_close(handle);
   if(status) {
      return;
   }
}


defeventtab _target_form;

static _str TARGETFORM_PROJECTNAME(...) {
   if (arg()) ctlOk.p_user=arg(1);
   return ctlOk.p_user;
}
static _str TARGETFORM_FILENAME(...) {
   if (arg()) ctlCancel.p_user=arg(1);
   return ctlCancel.p_user;
}

void ctlOk.on_create(_str projectFile, _str makefile)
{
   // remember filenames
   TARGETFORM_PROJECTNAME(projectFile);
   TARGETFORM_FILENAME(makefile);

   // determine what type of file this is
   type := "";
   if(_IsAntBuildFile(makefile)) {
      type = "Ant";
      p_active_form.p_help="Invoking Ant Targets";
   } else if(_IsNAntBuildFile(makefile)) {
      type = "NAnt";
      p_active_form.p_help="Invoking Ant Targets";
   } else if(_IsMakefile(makefile)) {
      type = "Makefile";
      p_active_form.p_help="";
   //   p_active_form.p_help="Invoking Makefile Targets";
   } else {
      p_active_form.p_help="";
   }

   // add filename to caption
   switch(lowcase(type)) {
      case "ant":
         p_active_form.p_caption = "Choose Ant Target(s) - " _strip_filename(makefile, "P");
         break;
      case "nant":
         p_active_form.p_caption = "Choose NAnt Target(s) - " _strip_filename(makefile, "P");
         break;
      case "makefile":
         p_active_form.p_caption = "Choose Makefile Target(s) - " _strip_filename(makefile, "P");
         break;
   }

   // populate tree with list of targets
   _str targetList[];
   _str descriptionList[];
   switch(lowcase(type)) {
      case "ant":
         _ant_GetTargetList(makefile, targetList, descriptionList);
         break;
      case "nant":
         _nant_GetTargetList(makefile, targetList, descriptionList);
         break;
      case "makefile":
         _makefile_GetTargetList(makefile, '', targetList, descriptionList);
         //makefile descriptions are blank, so might as well sort the target list
         targetList._sort();
         break;
   }

   _nocheck _control ctlTargetTree;
   wid := p_window_id;
   p_window_id=ctlTargetTree;
   // setup tree columns
   _TreeSetColButtonInfo(0, 2000, TREE_BUTTON_PUSHBUTTON, 0, "Target");
   _TreeSetColButtonInfo(1, 550, TREE_BUTTON_PUSHBUTTON, 0, "Order");
   _TreeSetColButtonInfo(2, ctlTargetTree.p_width - 2650, TREE_BUTTON_WRAP, 0, "Description");

   int i;
   for(i = 0; i < targetList._length(); i++) {
      target :=  targetList[i] "\t\t" descriptionList[i];
      newIndex := _TreeAddItem(TREE_ROOT_INDEX, target, TREE_ADD_AS_CHILD, 0, 0, -1, 0);
      if ( newIndex>0 ) {
         _TreeSetCheckState(newIndex, TCB_UNCHECKED);
      }
   }
   p_window_id=ctlTargetTree;

   // populate builtin command combobox.  only targets that were part of the
   // template are supported (no user added targets)
   ctlBuiltinCmd._lbadd_item("Build");
   ctlBuiltinCmd._lbadd_item("Rebuild");
   //ctlBuiltinCmd.p_cb_list_box._lbadd_item("Clean");
   ctlBuiltinCmd._lbtop();
   ctlBuiltinCmd.p_text = ctlBuiltinCmd._lbget_text();

   // disable the combobox
   ctlBuiltinCmd.p_enabled = ctlUseAs.p_value == 1;
}

static int ctlTargetTreeCheckToggle(int index)
{
   // get the caption of this tree item and split it into its parts
   caption := _TreeGetCaption(index);
   _str target, orderStr, description;
   parse caption with target "\t" orderStr "\t" description;

   // get the bitmap information in the tree
   int arrayIndex;
   arrayIndex = _TreeGetUserInfo(index);

   // renumber based on selection
   if(_TreeGetCheckState(index) == 0) {
      // all targets with an order greater than this one must be decremented
      int order = (int)orderStr;

      node := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while(node >= 0) {
         // do not process the current node
         if(node == index) {
            // update caption
            _TreeSetCaption(node, target "\t\t" description);
         } else {
            // update order in caption if found
            nodeCaption := _TreeGetCaption(node);
            _str nodeTarget, nodeOrderStr, nodeDescription;
            parse nodeCaption with nodeTarget "\t" nodeOrderStr "\t" nodeDescription;
            if(nodeOrderStr != "") {
               int nodeOrder = (int)nodeOrderStr;

               // only decrement those that were later than the one that was just deselected
               if(nodeOrder >= order) {
                  nodeOrder--;
                  nodeOrderStr = nodeOrder;

                  // update caption
                  _TreeSetCaption(node, nodeTarget "\t" nodeOrder "\t" nodeDescription);
               }
            }
         }

         // find next node
         node = _TreeGetNextIndex(node);
      }

   // should contain no order information is this caption
   } else {
      // figure out how many targets have already been queued
      nextOrder := 1;

      node := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      while(node >= 0) {
         // do not process the current node
         if(node != index) {
            // check the order of this node to see if it is greater than the current max
            // update order in caption if found
            nodeCaption := _TreeGetCaption(node);
            _str nodeTarget, nodeOrderStr, nodeDescription;
            parse nodeCaption with nodeTarget "\t" nodeOrderStr "\t" nodeDescription;
            if(nodeOrderStr != "") {
               int nodeOrder = (int)nodeOrderStr;
               if(nodeOrder >= nextOrder) {
                  nextOrder = nodeOrder + 1;
               }
            }
         }

         // move to next node
         node = _TreeGetNextIndex(node);
      }

      // update the caption with the order information
      _TreeSetCaption(index, target "\t" nextOrder "\t" description);
   }

   return 0;
}

void ctlTargetTree.on_change(int reason,int index)
{
   if ( reason==CHANGE_CHECK_TOGGLED ) {
      ctlTargetTreeCheckToggle(index);
   }
}

void ctlUseAs.lbutton_up()
{
   // en/disable the combobox as appropriate
   ctlBuiltinCmd.p_enabled = ctlUseAs.p_value == 1;
}

void ctlOk.lbutton_up()
{
   _str projectFile = TARGETFORM_PROJECTNAME();
   _str makefile = TARGETFORM_FILENAME();

   // determine what type of file this is
   type := "";
   if(_IsAntBuildFile(makefile)) {
      type = "ant";
   } else if(_IsNAntBuildFile(makefile)) {
      type = "nant";
   } else if(_IsMakefile(makefile)) {
      type = "makefile";
   }

   // determine which targets are checked and in which order
   _str targetList[];
   node := ctlTargetTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while(node >= 0) {
      // check the order position of this node and add it to the array.  if the
      // order is empty, ignore that target
      caption := ctlTargetTree._TreeGetCaption(node);
      _str target, orderStr, description;
      parse caption with target "\t" orderStr "\t" description;
      if(orderStr != "") {
         int order = (int)orderStr;
         targetList[order - 1] = target;
      }

      // move to next node
      node = ctlTargetTree._TreeGetNextIndex(node);
   }

   // if there are arguments add them
   options := "";
   if(ctlArguments.p_text != "") {
      options = " " ctlArguments.p_text;
   }

   // add each target to the command.  this is all done in a single command
   // since ant and make can accept multiple targets on the command line
   int i;
   for(i = 0; i < targetList._length(); i++) {
      options :+= " " targetList[i];
   }

   // save the information if requested
   if(ctlUseAs.p_value) {
      int handle = _ProjectHandle(projectFile);
      if(handle >= 0) {
         // make sure the requested target exists in the config
         int targetNode = _ProjectGet_TargetNode(handle, ctlBuiltinCmd.p_text, GetCurrentConfigName(projectFile));
         if(targetNode >= 0) {
            _str absoluteFilename = _AbsoluteToProject(makefile, projectFile);

            // strip filename
            filename := _strip_filename(absoluteFilename, "P");

            // convert path to be relative to project
            runFromDir := _strip_filename(absoluteFilename, "N");
            runFromDir = _RelativeToProject(runFromDir, projectFile);
            if(runFromDir == "") {
               runFromDir = ".";
            }

            // the file should be run in the directory where it lives so set the
            // runfromdir, relative to the project

            _ProjectSet_TargetRunFromDir(handle, targetNode, _NormalizeFile(runFromDir));

            // set the build command with just the filename since the dir has been set
            switch(lowcase(type)) {
               case "ant":
                  _ProjectSet_TargetCmdLine(handle, targetNode, "antmake -emacs -f " _maybe_quote_filename(filename) :+ options);
                  break;
               case "nant":
                 _ProjectSet_TargetCmdLine(handle, targetNode, "nant /f:" _maybe_quote_filename(filename) :+ options);
                  break;
               case "makefile":
                  _ProjectSet_TargetCmdLine(handle, targetNode, "make -f " _maybe_quote_filename(filename) :+ options);
                  break;
            }

            // if there is a dialog associated with this command, remove it since
            // the dialogs do not support ant or make related options
            if(_ProjectGet_TargetDialog(handle, targetNode) != "") {
               _ProjectSet_TargetDialog(handle, targetNode, "");
            }

            // save the project
            _ProjectSave(handle);
         }
      }
   }

   // close the targets dialog
   p_active_form._delete_window(0);

   // execute the targets
   switch(lowcase(type)) {
      case "ant":
         ant_execute_target(_maybe_quote_filename(projectFile) " " _maybe_quote_filename(makefile) " " options);
         break;
      case "nant":
         nant_execute_target(_maybe_quote_filename(projectFile) " " _maybe_quote_filename(makefile) " " options);
         break;
      case "makefile":
         makefile_execute_target(_maybe_quote_filename(projectFile) " " _maybe_quote_filename(makefile) " " options);
         break;
   }
}

/**
 * Get the list of libraries used by a project in the manner it should
 * be displayed in the project properties, or other similar dialogs.<br>
 * <br>
 * This includes inserting the &lt;ProjectObjects&gt; marker to indicate the
 * PreObjectLibs property.
 */
_str _ProjectGet_DisplayLibsList(int projectHandle, _str config)
{
   _str output = _ProjectGet_LibsList(projectHandle, config);
   _str preObjectLibs = _ProjectGet_PreObjectLibs(projectHandle, config);
   if (preObjectLibs > 0) {
      _str oldLibs = output;
      output = '';

      while ((preObjectLibs > 0) && (oldLibs != '')) {
         if (output != '') {
            strappend(output, ' ');
         }
         strappend(output, _maybe_quote_filename(parse_next_option(oldLibs,false)));
         --preObjectLibs;
      }

      if (!preObjectLibs) {
         // if preObjectLibs is greater than zero, something went wrong
         strappend(output, ' ':+PROJECT_OBJECTS);
      }

      if (oldLibs != '') {
         strappend(output, ' ':+oldLibs);
      }
   }

   return output;
}

/**
 * Set the list of libraries used by a project by parsing the text
 * displayed in the project properties, or other similar dialogs.<br>
 * <br>
 * This includes finding the &lt;ProjectObjects&gt; marker and setting the
 * PreObjectLibs property.
 */
void _ProjectSet_DisplayLibsList(int projectHandle, _str config, _str libsList)
{
   if (pos(PROJECT_OBJECTS,libsList)) {
      _str leadingLibs;
      _str trailingLibs;
      parse libsList with leadingLibs (PROJECT_OBJECTS) trailingLibs;
      _ProjectSet_LibsList(projectHandle, strip(leadingLibs' 'trailingLibs), config);
      preObjectLibs := 0;
      while (leadingLibs != '') {
         ++preObjectLibs;
         parse_next_option(leadingLibs);

         // temp to break infinite loop
         if (preObjectLibs > 5) {
            leadingLibs = '';
         }
      }
      _ProjectSet_PreObjectLibs(projectHandle, preObjectLibs, config);
   } else {
      _ProjectSet_LibsList(projectHandle, libsList, config);
      _ProjectSet_PreObjectLibs(projectHandle, 0, config);
   }
}

defeventtab _link_order_form;

ctlok.on_create(_str libList)
{
   if (0==pos(PROJECT_OBJECTS,libList)) {
      ctlLibList._lbadd_item(PROJECT_OBJECTS);
   }

   while (libList:!='') {
      ctlLibList._lbadd_item(parse_next_option(libList, false));
   }

   ctlLibList._lbtop();
   ctlLibList._lbselect_line();
}

ctlok.lbutton_up()
{
   libList := "";
   firstItem := true;

   // since the PROJECT_OBJECTS item can't be deleted, the list will always have
   // at least one item.
   ctlLibList._lbtop();

   do {
      _str lib = ctlLibList._lbget_text();

      if ( (!firstItem) || (lib!=PROJECT_OBJECTS) ) {
         if (libList:!='') {
            strappend(libList,' ');
         }
         strappend(libList, _maybe_quote_filename(lib));
      }
      firstItem = false;
   } while ( !ctlLibList._lbdown() );

   // so that the main dialog can tell the difference between hitting
   // OK with no libraries and hitting cancel, never return empty string

   if (libList:=='') {
      libList=PROJECT_OBJECTS;
   }

   p_active_form._delete_window(libList);
}

ctlLibBrowse.lbutton_up()
{
   _str result = show('-modal _textbox_form',
                      'Enter library',
                      0, // Flags
                      '', // Tb width
                      '', // help item
                      '', // Buttons and captions
                      '', // retrieve name
                      'Library:');

   if (result!='') {
      ctlLibList._lbbottom();
      ctlLibList._lbadd_item(_param1);
      ctlLibList._lbselect_line();
   }
}

ctlLibAddObj.lbutton_up()
{
   _str result = show('-modal _textbox_form',
                      'Enter Object',
                      0, // Flags
                      '', // Tb width
                      '', // help item
                      '', // Buttons and captions
                      '', // retrieve name
                      'Object:$(OUTDIR)/');

   if (result!='') {
      ctlLibList._lbtop();
      _str item = ctlLibList._lbget_text();
      ctlLibList._lbadd_item(_param1);
      ctlLibList._lbtop();
      ctlLibList._lbdelete_item();
      ctlLibList._lbadd_item(item);
      ctlLibList._lbtop();
      ctlLibList._lbselect_line();
   }
}

static void move_lib_up()
{
   curIndex := ctlLibList.p_line;

   if (curIndex > 1) {
      ctlLibList._lbup();
      _str item = ctlLibList._lbget_text();
      ctlLibList._lbdelete_item();
      ctlLibList._lbadd_item(item);
      ctlLibList._lbup();
      ctlLibList._lbselect_line();
   }
}

static void move_lib_down()
{
   curIndex := ctlLibList.p_line;

   if (curIndex < ctlLibList.p_Noflines) {
      _str item = ctlLibList._lbget_text();
      ctlLibList._lbdelete_item();
      ctlLibList._lbadd_item(item);
      ctlLibList._lbselect_line();
   }
}

ctlLibUp.lbutton_up()
{
   move_lib_up();
}

ctlLibDown.lbutton_up()
{
   move_lib_down();
}

static void remove_lib()
{
   _str item = ctlLibList._lbget_text();

   if (item != PROJECT_OBJECTS) {
      ctlLibList._lbdelete_item();
      ctlLibList._lbselect_line();
   }
}

ctlLibRemove.lbutton_up()
{
   remove_lib();
}

_link_order_form.up()
{
   curIndex := ctlLibList.p_line;

   if (curIndex > 1) {
      ctlLibList._lbup();
      ctlLibList._lbselect_line();
   }
}

_link_order_form.down()
{
   curIndex := ctlLibList.p_line;

   if (curIndex < ctlLibList.p_Noflines) {
      ctlLibList._lbdown();
      ctlLibList._lbselect_line();
   }
}

_link_order_form.'C-UP'()
{
   move_lib_up();
}

_link_order_form.'C-DOWN'()
{
   move_lib_down();
}

_link_order_form.'DEL'()
{
   remove_lib();
}

_link_order_form.on_resize()
{
   margin_y := ctlLibBrowse.p_y;
   controls_height := 4*margin_y + ctlLibBrowse.p_height + ctlok.p_height;
   if (!_minimum_width()) {
      _set_minimum_size(ctlok.p_width*3,  controls_height*2);
   }
   ctlLibList.p_height = p_active_form.p_height - controls_height;

   alignUpDownListButtons(ctlLibList.p_window_id, 
                          p_active_form.p_width - ctlLibList.p_x,
                          ctlAddLib.p_window_id,
                          ctlLibUp.p_window_id, 
                          ctlLibDown.p_window_id, 
                          ctlLibRemove.p_window_id);

   alignControlsVertical(ctlLibBrowse.p_x, 
                         ctlLibBrowse.p_y, 
                         ctlLibBrowse.p_y, 
                         ctlLibBrowse.p_window_id, 
                         ctlLibList.p_window_id, 
                         ctlok.p_window_id);

   alignControlsHorizontal(ctlok.p_x,        ctlok.p_y,        ctlLibBrowse.p_x, ctlok.p_window_id,        ctlcancel.p_window_id);
   alignControlsHorizontal(ctlLibBrowse.p_x, ctlLibBrowse.p_y, ctlLibBrowse.p_x, ctlLibBrowse.p_window_id, ctlLibAddObj.p_window_id);
}

ctlAddLib.lbutton_up()
{
   typeless result=_OpenDialog("-modal",
                      'Add Library',// title
                      '*.*',
                      'All Files (*.*)',
                      OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                      "", // Default extension
                      ""/*wildcards*/, // Initial filename
                      "",// Initial directory
                      "",
                      ""); // include item callback

   if (result!='') {
      ctlLibList._lbbottom();
      for (;;) {
         _str filename = parse_file(result);
         if (filename == '') break;
         filename = strip(filename, 'B', '"');
         ctlLibList._lbadd_item(_RelativeToProject(filename, _project_name));
      }
   }
}


defeventtab _adv_project_command_form;
static const ADV_CMD_TOOLS=      (0);
static const ADV_CMD_CONFIGS=    (1);
static const ADV_CMD_ENV_ONLY=   (2);
static const ADV_CMD_EDIT_OPEN=  (3);

static const ADV_CMD_CUR_CONFIG=    "Current Configuration";

ctlok.on_create(_str cmds[],_str tool_names[],_str configs[],bool env_only,_str caption="")
{
   // set caption for dialog, this is used when setting workspace
   // environment variables
   if (caption != '') {
      p_active_form.p_caption=caption;
   }

   int cmd_index;
   for (cmd_index=0;cmd_index<cmds._length();++cmd_index) {
      ctlCmdTree._TreeAddItem(TREE_ROOT_INDEX,cmds[cmd_index],TREE_ADD_AS_CHILD,0,0,-1);
   }

   int newIndex=ctlCmdTree._TreeAddItem(TREE_ROOT_INDEX,PROJ_BLANK_TREE_NODE_MSG,TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
   ctlCmdTree._TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);

   // add the "Current Configuration" node
   config_index := configs._length();
   while (config_index>0) {
      configs[config_index]=configs[config_index-1];
      --config_index;
   }
   configs[0]=ADV_CMD_CUR_CONFIG;

   _SetDialogInfo(ADV_CMD_TOOLS,tool_names);
   _SetDialogInfo(ADV_CMD_CONFIGS,configs);
   _SetDialogInfo(ADV_CMD_ENV_ONLY,env_only);
   _SetDialogInfo(ADV_CMD_EDIT_OPEN,false);

   if (env_only) {
      ctlAddCallTarget.p_visible = false;
      ctlAddSetVar.p_visible = false;

      dy := ctlAddSetVar.p_y;
      ty := ctlCmdTree.p_y_extent;
      ctlCmdTree.p_y = dy;
      ctlCmdTree.p_height = ty - dy;
      
      ty = ctlCmdUp.p_y - ctlCmdNew.p_y;
      ctlCmdNew.p_y  = dy; dy += ty;
      ctlCmdUp.p_y = dy; dy += ty;
      ctlCmdDown.p_y = dy; dy += ty;
      ctlCmdRemove.p_y = dy;
   }
}

void _adv_project_command_form.on_resize()
{
   // set mininum size for this form
   if (!_minimum_width()) {
      _set_minimum_size(ctlok.p_width*5, ctlok.p_height*5);
   }

   // adjust widths
   dw := p_active_form.p_width;
   dh := p_active_form.p_height;

   // align buttons in correct positions
   alignControlsHorizontal(ctlAddSetVar.p_x, ctlAddSetVar.p_y, ctlAddSetVar.p_x, ctlAddSetVar.p_window_id, ctlAddCallTarget.p_window_id);
   alignControlsHorizontal(ctlok.p_x, dh-60-ctlok.p_height, ctlok.p_x, ctlok.p_window_id, ctlcancel.p_window_id);

   // align list with top add button and adjust list height
   if (ctlAddSetVar.p_visible || ctlAddCallTarget.p_visible) {
      alignControlsVertical(ctlAddSetVar.p_x, ctlAddSetVar.p_y, ctlAddSetVar.p_y, ctlAddSetVar.p_window_id, ctlCmdTree.p_window_id);
   } else {
      ctlCmdTree.p_x = ctlAddSetVar.p_x;
      ctlCmdTree.p_y = ctlAddSetVar.p_y;
   }

   // finally, align the buttons to the list
   ctlCmdTree.p_height = ctlok.p_y - 60 - ctlCmdTree.p_y; 
   alignUpDownListButtons(ctlCmdTree.p_window_id, 
                          dw - ctlCmdTree.p_x,
                          ctlCmdNew.p_window_id,
                          ctlCmdUp.p_window_id,
                          ctlCmdDown.p_window_id,
                          ctlCmdRemove.p_window_id);
}

void ctlok.lbutton_up()
{
   _str cmds[];
   _str cmd;

   node := ctlCmdTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   while (node>=0) {
      cmd=ctlCmdTree._TreeGetCaption(node);

      if (cmd:!=PROJ_BLANK_TREE_NODE_MSG) {
         cmds[cmds._length()]=cmd;
      }

      node=ctlCmdTree._TreeGetNextSiblingIndex(node);
   }

   _param1=cmds;

   p_active_form._delete_window(1);
}

static int check_command(_str &text,bool env_only)
{
   _str cmd=text;
   _str cmd_type;
   _str options;

   parse cmd with cmd_type ' ' options;

   if (strieq(cmd_type,'run_tool') && !env_only) {
      _str config;
      _str tool;

      parse options with 'Config=','I' config ' ' .;
      parse options with 'Tool=','I' tool ' ' .;

      if (tool:=='') {
         _message_box('You must specifiy a tool.');
         return -1;
      }

      _str tools[]=_GetDialogInfo(ADV_CMD_TOOLS);

      is_valid_tool := false;
      int tool_index;

      for (tool_index=0;tool_index<tools._length();++tool_index) {
         if (strieq(tool,tools[tool_index])) {
            is_valid_tool=true;
         }
      }

      if (!is_valid_tool) {
         _message_box('"'tool'" is not a valid tool name.');
         return -1;
      }

      if (config:=='') {
         return 0;
      }

      _str configs[]=_GetDialogInfo(ADV_CMD_CONFIGS);

      is_valid_config := false;
      int config_index;

      for (config_index=0;config_index<configs._length();++config_index) {
         if (strieq(config,configs[config_index])) {
            is_valid_config=true;
         }
      }

      if (!is_valid_config) {
         _message_box('"'config'" is not a valid configuration.');
         return -1;
      }
      return 0;
   } else if (strieq(cmd_type,'set')) {
      _str name;
      _str value;

      parse options with name'='value;

      name=strip(name);
      value=strip(value);

      if (value:=='') {
         parse name with name ' ' value;

         name=strip(name);
         value=strip(value);

         if (value:=='') {
            _message_box('You must specifiy a value.');
            return -1;
         }

         // insert an equals sign into the command
         text=cmd_type' 'name'='value;
      }
      return 0;
   } else {
      _message_box('The command "'cmd_type'" is not recognized.');
   }

   return -1;
}

int ctlCmdTree.on_change(int reason=CHANGE_CLINE,int index=TREE_ROOT_INDEX,typeless dummy=null, _str &text=null)
{
   if ((reason!=CHANGE_EDIT_OPEN)&&(reason!=CHANGE_EDIT_CLOSE)) {
      return 0;
   }

   // check the old caption to see if it is the new entry node
   wasNewEntryNode := strieq(_TreeGetCaption(index), PROJ_BLANK_TREE_NODE_MSG);

   ret_value := 0;

   if (reason==CHANGE_EDIT_OPEN) {
      _SetDialogInfo(ADV_CMD_EDIT_OPEN,true);
      if (wasNewEntryNode) {
         text='';
      }
   } else if (reason==CHANGE_EDIT_CLOSE) {
      _SetDialogInfo(ADV_CMD_EDIT_OPEN,false);
      if (text:=='') {
         if (wasNewEntryNode) {
            text=PROJ_BLANK_TREE_NODE_MSG;
         } else {
            _TreeDelete(index);
            ret_value=DELETED_ELEMENT_RC;
         }
      } else {
         ret_value=check_command(text,_GetDialogInfo(ADV_CMD_ENV_ONLY));

         if (ret_value) {
            _SetDialogInfo(ADV_CMD_EDIT_OPEN,true);
         } else {
            if (wasNewEntryNode) {
               // unbold the existing node
               _TreeSetInfo(index, TREE_NODE_LEAF, -1, -1, 0);

               // add and bold the new entry node
               int newIndex = _TreeAddListItem(PROJ_BLANK_TREE_NODE_MSG);
               _TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
            }
         }
      }
   }

   return ret_value;
}

static void add_new_adv_cmd(_str cmd)
{
   node := ctlCmdTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   while ((node>=0)&&(ctlCmdTree._TreeGetCaption(node):!=PROJ_BLANK_TREE_NODE_MSG)) {
      node=ctlCmdTree._TreeGetNextSiblingIndex(node);
   }

   if (node>=0) {
      ctlCmdTree._TreeAddItem(node,cmd,TREE_ADD_BEFORE,0,0,TREE_NODE_LEAF);
   }
}

void ctlAddSetVar.lbutton_up()
{
   _str promptResult = show("-modal _textbox_form",
                            "Enter the new environment variable",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Name:" "",
                            "Value:" "" );

   if (promptResult:=="") {
      return;
   }

   add_new_adv_cmd('Set '_param1'='_param2);
}

void ctlAddCallTarget.lbutton_up()
{
   _str tools[]=_GetDialogInfo(ADV_CMD_TOOLS);
   _str configs[]=_GetDialogInfo(ADV_CMD_CONFIGS);

   _str tool=show('-modal _sellist_form',
                  'Select a Tool',
                  SL_MUSTEXIST|SL_SELECTCLINE,
                  tools);

   if (tool:=='') {
      return;
   }

   _str config=show('-modal _sellist_form',
                    'Select a Tool',
                    SL_MUSTEXIST|SL_SELECTCLINE,
                    configs);

   if (config:=='') {
      return;
   }

   if (config:==ADV_CMD_CUR_CONFIG) {
      add_new_adv_cmd('run_tool Tool='tool);
   } else {
      add_new_adv_cmd('run_tool Config='config' Tool='tool);
   }
}

static void move_cmd_up()
{
   cur_node := ctlCmdTree._TreeCurIndex();

   if (ctlCmdTree._TreeGetCaption(cur_node):!=PROJ_BLANK_TREE_NODE_MSG) {
      ctlCmdTree._TreeMoveUp(cur_node);
   }
}

static void move_cmd_down()
{
   cur_node := ctlCmdTree._TreeCurIndex();
   next_node := ctlCmdTree._TreeGetNextSiblingIndex(cur_node);

   if ((next_node>=0) && (ctlCmdTree._TreeGetCaption(next_node):!=PROJ_BLANK_TREE_NODE_MSG)) {
      ctlCmdTree._TreeMoveDown(cur_node);
   }
}

static void remove_cmd()
{
   cur_node := ctlCmdTree._TreeCurIndex();

   if (ctlCmdTree._TreeGetCaption(cur_node):!=PROJ_BLANK_TREE_NODE_MSG) {
      ctlCmdTree._TreeDelete(cur_node);
   }
}

static void cancel_edit()
{
   _StopEditInPlace();
   _SetDialogInfo(ADV_CMD_EDIT_OPEN,false);
}

void ctlCmdNew.lbutton_up()
{
   env_only := _GetDialogInfo(ADV_CMD_ENV_ONLY);
   if (env_only) {
      ctlAddSetVar.call_event(_control ctlAddSetVar, LBUTTON_UP, "W");
      return;
   }

   result := textBoxDialog(p_active_form.p_caption,      // form caption
                 0,                                      // flags
                 0,                                      // text box width
                 '',                                     // help item
                 '',                                     // buttons and captions
                 '',                                     // retrieve name
                 '-e _check_new_command New item:');                           // prompt

   // nothing to see here
   if (result == COMMAND_CANCELLED_RC || _param1 == '') return;

   // add the new value to the tree
   add_new_adv_cmd(_param1);

   // scroll to the bottom so the user can see what we did
   ctlCmdTree._TreeBottom();
}

int _check_new_command(_str cmd)
{
   if (check_command(cmd, _GetDialogInfo(ADV_CMD_ENV_ONLY))) {
      return INVALID_ARGUMENT_RC;
   }

   return 0;
}

void ctlCmdUp.lbutton_up()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      move_cmd_up();
   }
}

void ctlCmdDown.lbutton_up()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      move_cmd_down();
   }
}

void ctlCmdRemove.lbutton_up()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      remove_cmd();
   }
}

void _adv_project_command_form.'C-UP'()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      move_cmd_up();
   }
}

void _adv_project_command_form.'C-DOWN'()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      move_cmd_down();
   }
}

void ctlCmdTree.'DEL'()
{
   if (_GetDialogInfo(ADV_CMD_EDIT_OPEN)) {
      cancel_edit();
   } else {
      remove_cmd();
   }
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
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if (def_show_all_proj_with_file) {
      _ctl_list._lbselect_all();
   }

   // figure out our selections and save them
   _str projArray[];
   while (!_ctl_list._lbfind_selected(true)) {
      projArray :+= _ctl_list._lbget_text();
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

////////////////////////////////////////////////////////////////////////////////

_command void project_toggle_auto_build()
{
   def_project_auto_build = !def_project_auto_build;
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if (!def_project_auto_build) {
      _pending_builds._makeempty();
   }
}

int _OnUpdate_project_toggle_auto_build(CMDUI &cmdui,int target_wid,_str command)
{
   return(def_project_auto_build ? MF_ENABLED|MF_CHECKED : MF_ENABLED|MF_UNCHECKED);
}

bool project_in_auto_build()
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
         buildName :=  projName:+"\t"p_buf_name;
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
   if (!_haveBuild()) return;
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
      old_process_output := def_process_tab_output;
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

void _project_disable_auto_build(bool enable)
{
   _disable_auto_builds = enable;
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
   result := "";
   for (;;) {
      if (FileList=='') {
         break;
      }
      file := "";
      parse FileList with file';' FileList;
      if (file!='') {
         if (result=='') {
            result=_maybe_quote_filename(file);
         } else {
            result :+= ' ':+_maybe_quote_filename(file);
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
   semicolons_result := "";
   for (;;) {
      if (FileList=='') {
         break;
      }
      _str file=parse_file(FileList,false);
      if (file!='') {
         if (semicolons_result=='') {
            semicolons_result=file;
         } else {
            semicolons_result :+= ';':+file;
         }
      }
   }
   return(semicolons_result);
}


/**
 * Search for a file in any project in the specified workspace
 *
 * @param filename               File to search for
 * @param workspaceName          Workspace path
 * @param checkPath              true to check the whole path, 
 *                               false for just the file name
 * @param excludeCurrentProject  exclude the current project 
 *                               (asssuming it has already been searched).
 * @param returnAll              Return all matches as aspace-delimited list. 
 *                               This also prevents this function from
 *                               prompting to resolve duplicates.
 * @param matchPathSuffix        (unused), see checkPath, above.
 *
 * @return Filename if found. 
 *         Will return COMMAND_CANCELLED_RC if the user was 
 *         prompted and then cancelled instead of picking a choice. 
 */
_str _WorkspaceFindFile(_str filename, 
                        _str workspaceName = _workspace_filename,
                        bool checkPath=true, 
                        bool excludeCurrentProject=false,
                        bool returnAll=false, 
                        bool matchPathSuffix=false)
{
   _str projectList[];
   _GetWorkspaceFiles(workspaceName, projectList);

   _str foundFileHash:[];
   for (i := 0; i < projectList._length(); i++) {
      // check if this project should be skipped
      projectName := _AbsoluteToWorkspace(projectList[i], workspaceName);
      if (excludeCurrentProject && workspaceName==_workspace_filename && _file_eq(projectName, _project_name)) {
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
   _str foundFileList[];
   typeless j;
   for(j._makeempty();;) {
      foundFileHash._nextel(j);
      if(j._isempty()) break;

      foundFileList :+= j;
   }

   if (returnAll) {
      result := "";
      foreach (j in foundFileList) {
         if (result != '') result :+= ' ';
         result :+= _maybe_quote_filename(j);
      }
      return result;
   }

   // sort the array
   foundFileList._sort("F");

   // if found more than one, prompt the user for which one
   if(foundFileList._length() > 1) {
      // prompt the user for the file
      result := show("-modal _sellist_form", "Select filename", SL_SELECTCLINE, foundFileList);
      if (result == "") return COMMAND_CANCELLED_RC;
      return result;

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
 * @param returnAll        Return all matches as aspace-delimited list. 
 *                         This also prevents this function from
 *                         prompting to resolve duplicates.
 *
 * @return "" if not found, otherwise, 
 *         the absolute path to <i>filename</i>.
 *         Will return COMMAND_CANCELLED_RC if the user was 
 *         prompted and then cancelled instead of picking a choice. 
 *
 * @categories Project_Functions
 */
_str _ProjectWorkspaceFindFile(_str filename,
                               bool searchIncludes=true,
                               bool strict=false,
                               bool returnAll=false)
{
   // try finding file in Eclipse workspace
   found_filename := "";
   if (isEclipsePlugin()) {
      _eclipse_ProjectWorkspaceFindFile(_strip_filename(filename,'P'),found_filename);
      return found_filename;
   }

   // if not found, search for file in the current project
   found_filename = _projectFindFile(_workspace_filename, _project_name, filename, 1, (int)returnAll);
   if (found_filename!="") {
      return found_filename;
   }

   // if not found, search for file in the current workspace
   // exclude the current project, we have already searched it.
   found_filename = _WorkspaceFindFile(filename, _workspace_filename, true, true, returnAll);
   if (found_filename != "") {
      return found_filename;
   }

   // if not found, search for file (by name only) in the current project
   filename_only := _strip_filename(filename,'P');
   if (!strict) {
      if (_isRelative(filename)) {
         temp_filename:=filename;
         // Remove leading ../ stuff since that will mess up using
         // the path part to find a better mach
         while (file_eq(substr(temp_filename,1,3),'..'FILESEP)) {
            temp_filename=substr(temp_filename,4);
         }
         if (_strip_filename(temp_filename,'p')!='') {
            found_filename = _projectFindFile(_workspace_filename, _project_name, temp_filename, 0, (int)returnAll,1);
            if (found_filename != "") {
               return found_filename;
            }

            // if not found, search for file (by name only) in the current workspace
            found_filename = _WorkspaceFindFile(temp_filename, _workspace_filename, false, true, returnAll,true);
            if (found_filename != "") {
               return found_filename;
            }
         }
      }


      found_filename = _projectFindFile(_workspace_filename, _project_name, filename_only, 0, (int)returnAll);
      if (found_filename != "") {
         return found_filename;
      }

      // if not found, search for file (by name only) in the current workspace
      found_filename = _WorkspaceFindFile(filename_only, _workspace_filename, false, true, returnAll);
      if (found_filename != "") {
         return found_filename;
      }
   }

   // if not found, search include paths
   if (searchIncludes) {
      info := _ProjectGet_IncludesList(_ProjectHandle(),_project_get_section(gActiveConfigName));
      info  = _absolute_includedirs(info, _project_get_filename());
      found_filename = include_search(filename,info);
      if (found_filename != "") {
         return found_filename;
      }
   }

   // no match
   return "";
}

/**
 * Search for a file in all projects in the specified workspace.
 *
 * @param filename   File to search for
 * @param workspaceName
 *                   Workspace path
 * @param isAbsolute T if the specified filename is an absolute path
 * @param skipProjectsNotYetCached   Skip searching any project
 *                                   files that are not yet cached.
 *
 * @return array of projects containing the given file
 *
 * @categories Project_Functions
 */
STRARRAY _WorkspaceFindAllProjectsWithFile(_str filename, _str workspaceName = _workspace_filename,
                                           bool isAbsolute = false,
                                           bool skipProjectsNotYetCached=false)
{
   _str projectList[] = null;
   _GetWorkspaceFiles(workspaceName, projectList);
   i := 0;
   _str foundFileHash:[] = null;
   for(i = 0; i < projectList._length(); i++) {
      _str projectName = _AbsoluteToWorkspace(projectList[i], workspaceName);

      // if the filename was absolute, make it relative to the project first
      _str relativeFilename = filename;
      if(isAbsolute) {
         relativeFilename = _RelativeToProject(relativeFilename, projectName);
      }

      // file list is not ready yet, so skip this project
      if (skipProjectsNotYetCached && !_isProjectInfoCached(workspaceName, projectName)) {
         continue;
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
 * @param skipProjectsNotYetCached   Skip searching any project
 *                                   files that are not yet cached.
 *
 * @return Project containing the file if found
 *
 * @categories Project_Functions
 */
_str _WorkspaceFindProjectWithFile(_str filename, _str workspaceName = _workspace_filename,
                                   bool isAbsolute = false, bool quiet = false, 
                                   bool skipProjectsNotYetCached=false)
{
   _str foundFileList[] = _WorkspaceFindAllProjectsWithFile(filename, workspaceName, isAbsolute, skipProjectsNotYetCached);

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

static bool isItemBold(int index)
{
   int showChildren;
   int nonCurrentBMIndex;
   int currentBMIndex;
   int moreFlags;

   _TreeGetInfo(index, showChildren, nonCurrentBMIndex, currentBMIndex, moreFlags);

   return (0 != (moreFlags & TREENODE_BOLD));
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
   list := "";
   if(p_window_id._TreeGetNumChildren(TREE_ROOT_INDEX) > 0) {
      index := p_window_id._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for(; index >= 0; ) {
         // get the caption and skip the node reserved for new entry
         //if(!strieq(caption, BLANK_TREE_NODE_MSG)) {
         if (!isItemBold(index)) {
            caption := p_window_id._TreeGetCaption(index);
            if(list != '') {
               list :+= delimiter :+ caption;
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


/*void _TreeAddNodeList(int handle,int (&NodeArray)[], _str AttrName, bool allowDuplicates = false)
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
void _TreeSetDelimitedItemList(_str list, _str delimiter, bool allowDuplicates = false, _str lockedItems = '')
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
      newIndex = p_window_id._TreeAddListItem(PROJ_BLANK_TREE_NODE_MSG);
      p_window_id._TreeSetInfo(newIndex, TREE_NODE_LEAF, -1, -1, TREENODE_BOLD);
   }

   // restore the edit option
   p_EditInPlace = orig_EditInPlace;
}

// Helper for project form to initialize the Live Errors tag
void onCreateLiveErrorsTab(int projectHandle, int treeForm)
{
   _str rteLangs[];  rteLangs._makeempty();
   rv := _ProjectGet_AllRteProfileLangs(projectHandle, rteLangs);

   treeForm._TreeDelete(TREE_ROOT_INDEX,'C');
   treeForm._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Language");
   treeForm._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Profile");
   treeForm._TreeAdjustLastColButtonWidth();

   if (rv == 0) {
      foreach (auto lang in rteLangs) {
         prof := _ProjectGet_RteProfile(projectHandle, lang);
         treeForm._TreeAddItem(TREE_ROOT_INDEX,_LangId2Modename(lang)"\t"prof,
                               TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
      }
   } else {
      treeForm._TreeAddItem(TREE_ROOT_INDEX, " \t***Error, could not load profiles: "rv"***",
                            TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);

   }

}
// Helper for project form to implement the Live Errors New button.
void pfNewErrorsProfileOverride(int treeCtl)
{
   show('-modal _project_rte_profile', 
         treeCtl, '', '');
}

void pfDeleteLButtonUp(int treeCtl)
{
   index:=treeCtl._TreeCurIndex();
   if (index > 0 && treeCtl._TreeIndexIsValid(index)) {
      treeCtl._TreeDelete(index);
   }
}

void pfEditLButtonUp(int treeCtl)
{
   index:=treeCtl._TreeCurIndex();
   if (index > 0 && treeCtl._TreeIndexIsValid(index)) {
      modename := treeCtl._TreeGetTextForCol(index, 0);
      prof := treeCtl._TreeGetTextForCol(index, 1);
      rv := show('-modal _project_rte_profile', 
                 treeCtl, modename, prof);
      if (rv != '') {
         treeCtl._TreeSetTextForCol(index, 1, rv);
      }
   }
}

// Helper for live errors tab on project properties
// form.  Commits the settings in the tree control to 
// the project.
void pfSaveProfileSettings(int handle, int treeCtl)
{
   _str langids[];  langids._makeempty();
   _str profiles[];  profiles._makeempty();

   for (i := treeCtl._TreeGetFirstChildIndex(0); 
         i >= 0; 
         i = treeCtl._TreeGetNextSiblingIndex(i)) {
      langids :+= _Modename2LangId(treeCtl._TreeGetTextForCol(i, 0));
      profiles :+= treeCtl._TreeGetTextForCol(i, 1);
   }
   _ProjectSet_AllRteProfiles(handle, langids, profiles);
}

defeventtab _project_rte_profile;
static _str gavailableLangs[];
static int gprofileTreeCtl;
static bool gEditingProfile;

static void handle_lang_change()
{
   modename := _ctl_lang.p_text;

   if (modename != '') {
      _str profiles[];
      lang := _Modename2LangId(modename);
      rte_get_profiles_for_language(lang, profiles);
      _ctl_profile.p_cb_list_box._lbclear();
      foreach (auto prof in profiles) {
         _ctl_profile.p_cb_list_box._lbadd_item(prof);
      }
   }
}

void _ctl_ok.on_create()
{
   bool inTreeLangs:[]; 
   gprofileTreeCtl = (int)arg(1);
   modename := (_str)arg(2);
   prof := (_str)arg(3);
   gEditingProfile = modename != '';
   _ctl_lang.p_cb_list_box._lbclear();

   if (gEditingProfile) {
      _ctl_lang.p_cb_list_box._lbadd_item(modename);
      _ctl_lang.p_text = modename;
      _ctl_lang.p_enabled = false;
      handle_lang_change();
      _ctl_profile.p_text = prof;
   } else {
      gavailableLangs._makeempty();
      inTreeLangs._makeempty();

      // Don't offer languages already in the tree as a choice.
      i := 0;
      for (i = gprofileTreeCtl._TreeGetFirstChildIndex(0); 
            i >= 0; 
            i = gprofileTreeCtl._TreeGetNextSiblingIndex(i)) {
         ent := gprofileTreeCtl._TreeGetCaption(i, 0);
         inTreeLangs:[_Modename2LangId(ent)] = true;
      }

      _str allLangs[]; allLangs._makeempty();

      se.lang.api.LanguageSettings.getAllLanguageIds(allLangs);
      foreach (auto lang in allLangs) {
         if (lang != 'java' &&   // No java profile to be overridden, it still uses original RTE impl.
             !inTreeLangs._indexin(lang) &&
             has_rte_profiles(lang)) {
            _ctl_lang.p_cb_list_box._lbadd_item(_LangId2Modename(lang));
         }
      }
      handle_lang_change();
   }

}

void _ctl_lang.on_change()
{
   handle_lang_change();
}

void _ctl_ok.lbutton_up()
{
   modename := _ctl_lang.p_text;
   lang := _Modename2LangId(modename);
   prof := _ctl_profile.p_text;

   if (lang != '' && prof != '') {
      if (gEditingProfile) {
         p_active_form._delete_window(prof);
      } else {
         gprofileTreeCtl._TreeAddItem(TREE_ROOT_INDEX,_LangId2Modename(lang)"\t"prof,
                               TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
         p_active_form._delete_window(IDOK);
      }
   }
}

/**
 * 
 * 
 * @author cmaurer (12/6/20)
 * 
 * @param filelist All files must be saved on disk and be in 
 *                 absolute form.
 * @param quiet 
 * @param ProjectName 
 * @param msg 
 * 
 * @return int 
 */
int _project_add_filelist(_str filelist[],bool quiet=false,_str ProjectName=_project_name, _str& msg=null)
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
   int i;
   for (i=0;i<filelist._length();++i) {
      newfilename:=filelist[i];
      if (_FileExistsInCurrentProject(newfilename,ProjectName)) {
         filelist._deleteel(i);
         --i;
      }
   }
   status := 0;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _str tag_filename=project_tags_filename_only(ProjectName);
   status=tag_add_filelist(tag_filename,filelist,ProjectName,useThread);
   if (!status) {
      // See if we need to add this file to version control
      origParam1 := _param1;
      _MaybeAddFilesToVC(filelist);
      _param1 = origParam1;
   }
   for (i=0;i<filelist._length();++i) {
      newfilename:=filelist[i];
      call_list("_workspace_file_add", ProjectName, newfilename);
   }          
   //p_window_id.call_list("_prjupdate_");
   //toolbarUpdateFilterList(_project_name);
   //_TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,tag_filename);
   //_TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   return 0;
}

