////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50629 $
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
#include "tagsdb.sh"
#include "project.sh"
#include "scc.sh"
#include "xml.sh"
#import "actionscript.e"
#import "android.e"
#import "applet.e"
#import "compile.e"
#import "complete.e"
#import "context.e"
#import "cutil.e"
#import "cvs.e"
#import "debug.e"
#import "diff.e"
#import "dir.e"
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "gwt.e"
#import "help.e"
#import "ini.e"
#import "last.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "menu.e"
#import "moveedge.e"
#import "mprompt.e"
#import "packs.e"
#import "picture.e"
#import "project.e"
#import "projconv.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "recmacro.e"
#import "restore.e"
#import "saveload.e"
#import "sellist.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tbprojectcb.e"
#import "toast.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "vchack.e"
#import "vstudiosln.e"
#import "wman.e"
#import "xcode.e"
#import "xmlcfg.e"
#import "maven.e"
#endregion

#define WKSPCHIST_HELP ''
#define WKSPCHIST_MESSAGE 'Opens workspace '

static _str VendorNameTable:[]={
   VISUAL_STUDIO_SOLUTION_EXT                => VISUAL_STUDIO_VENDOR_NAME,
   // These entries are indented because they are Visual studio project types
   VISUAL_STUDIO_VB_PROJECT_EXT              => VISUAL_STUDIO_VB_VENDOR_NAME,
   VISUAL_STUDIO_VCPP_PROJECT_EXT            => VISUAL_STUDIO_VCPP_VENDOR_NAME,
   VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT       => VISUAL_STUDIO_VCPP_VENDOR_NAME,
   VISUAL_STUDIO_VCX_PROJECT_EXT             => VISUAL_STUDIO_VCPP_VENDOR_NAME,
   VISUAL_STUDIO_CSHARP_PROJECT_EXT          => VISUAL_STUDIO_CSHARP_VENDOR_NAME,
   VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT   => VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME,
   VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT       => VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME,
   VISUAL_STUDIO_JSHARP_PROJECT_EXT          => VISUAL_STUDIO_JSHARP_VENDOR_NAME,
   VISUAL_STUDIO_FSHARP_PROJECT_EXT          => VISUAL_STUDIO_FSHARP_VENDOR_NAME,
   VISUAL_STUDIO_TEMPLATE_PROJECT_EXT        => VISUAL_STUDIO_TEMPLATE_NAME,
   VISUAL_STUDIO_DATABASE_PROJECT_EXT        => VISUAL_STUDIO_DATABASE_NAME,
   VCPP_PROJECT_WORKSPACE_EXT          => VCPP_VENDOR_NAME,
   VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT => VCPP_EMBEDDED_VENDOR_NAME,
   TORNADO_WORKSPACE_EXT               => TORNADO_VENDOR_NAME,
   XCODE_PROJECT_EXT                   => XCODE_PROJECT_VENDOR_NAME,
   XCODE_PROJECT_SHORT_BUNDLE_EXT      => XCODE_PROJECT_VENDOR_NAME,
   XCODE_PROJECT_LONG_BUNDLE_EXT       => XCODE_PROJECT_VENDOR_NAME,
   XCODE_WKSPACE_BUNDLE_EXT            => XCODE_WKSPACE_VENDOR_NAME,
   ECLIPSE_WORKSPACE_FILE_EXT          => ECLIPSE_VENDOR_NAME,
   MACROMEDIA_FLASH_PROJECT_EXT        => MACROMEDIA_FLASH_VENDOR_NAME,
};

int def_workspace_options=WORKSPACE_OPT_COPYSAMPLES;

// do we automatically launch the new project wizard when they go to Project > New?
boolean def_launch_new_project_wizard = false;

// number of MRU document modes and project types to display on New File/Project dialog.
int def_max_doc_mode_mru = 5;
int def_max_proj_type_mru = 5;

static _str MRUProjectTypes[];
static _str MRUDocModes[];

boolean def_warn_mismatched_ext = true;
boolean def_warn_unknown_ext = true;

static _str LBDIVIDER = "------------------------------------------------------";

#define TORNADO_LATEST_VERSION 3

int workspace_close_project(boolean save_project_state_during_auto_restore=false)
{
   if (_project_name=='') {
      return(0);
   }
   _in_project_close=true;

   tag_close_bsc();
   call_list('_project_close_', _project_name);
   // IF we are NOT saving state because we are exiting the editor
   if (!save_project_state_during_auto_restore) {
      _project_name='';
      call_list('_prjclose_');
   }
   //9:19am 8/14/1997
   //Dan added for browser support
   _in_project_close=false;
   return(0);
}
static _str gProjectDisplayNames:[];

/**
 * Because Visual Studio solutions can mix .csproj, .vcproj, and .vbproj
 * files, we need to remember what the project filenames are
 * so we don't have to fetch them.
 *
 * @param ProjectNames
 *               Our workspace project files
 * @param VendorProjectNames
 *               Associated workspace project files with vendor extensions.
 * @param WorkspacePath
 *               Absolute path to workspace
 */
static void SetProjectDisplayNames(_str ProjectNames[],_str VendorProjectNames[],
                                   _str WorkspacePath)
{
   int i;
   for (i=0;i<ProjectNames._length();++i) {
      // Strip the path and only keep the names in the table.  There cannot be
      // collisions anyway.
      gProjectDisplayNames:[_RelativeToWorkspace(ProjectNames[i])]=absolute(VendorProjectNames[i],WorkspacePath);
   }
}

_str GetProjectDisplayName(_str ProjectFilename=_project_name)
{
   _str WorkspaceExt=_get_extension(_workspace_filename,1);
   if (!_IsWorkspaceAssociated(_workspace_filename)) {
      return(ProjectFilename);
   }

   // this function is dependent on the global gProjectDisplayNames variable 
   // being populated.  Calling this function ensures that it is.
   _str projectNames[];
   if (gProjectDisplayNames._length() == 0) {
      _GetWorkspaceFiles(_workspace_filename, projectNames);
   }

   // Table only has names, not paths since there cannot be two projects with
   // the same name.
   ProjectFilename=_strip_filename(ProjectFilename,'E'):+PRJ_FILE_EXT;
   if (gProjectDisplayNames._indexin(_RelativeToWorkspace(ProjectFilename))) {
      if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
         _str cur=gProjectDisplayNames:[_RelativeToWorkspace(ProjectFilename)];
         return(cur/*:+lastdirname*/);
      } else {
         return(gProjectDisplayNames:[_RelativeToWorkspace(ProjectFilename)]);
      }
   }
   return('');
}

void _before_write_state_ClearDisplayNames()
{
   // Don't want to save these in the state file
   gProjectDisplayNames=null;
}

/**
 * Remove workspace from recent menu list and organize
 * all workspace menu.  Make sure you don't call this
 * on the active workspace.
 *
 * @param filename
 */
void _menu_remove_workspace_hist(_str filename,boolean removeFromAllWorkspacesMenu=true)
{
   if (!_mdi.p_menu_handle) return;
   _menu_remove_hist(filename,_mdi.p_menu_handle,'&Project',WKSPHIST_CATEGORY,'workspace-open','ncw|wkspcopen',WKSPCHIST_HELP,WKSPCHIST_MESSAGE:+filename);
   if (removeFromAllWorkspacesMenu) {
      _RemoveFileFromWorkspaceManager(filename);
   }
}
/**
 * Remarks  Adds project file history to end of Project menu on the SlickEdit MDI 
 * menu bar.  The filename argument MUST be specified in absolute.  Use the absolute function to do this.
 * 
 * @see on_init_menu
 * @see _menu_add_hist
 * @see _menu_add_filehist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 * 
 * @categories Menu_Functions
 */
void _menu_add_workspace_hist(_str filename)
{
   if (file_eq(_get_extension(filename,1),ECLIPSE_WORKSPACE_FILE_EXT)) {
      filename=_strip_filename(filename,'N');
   } else {
      filename=_xcode_strip_pbxproj(filename);
   }
   call_list("_MenuAddWorkspaceHist_",filename);
   if (!def_max_workspacehist || !_mdi.p_menu_handle) return;
   _menu_add_hist(filename,_mdi.p_menu_handle,'&Project',WKSPHIST_CATEGORY,'workspace-open','ncw|wkspcopen',WKSPCHIST_HELP,WKSPCHIST_MESSAGE:+filename);
   _AddFilesToWorkspaceManager(filename);
}

/** 
   Strips of any "/project.pbxproj" suffixes from old-style
   Xcode project history
*/
_str _xcode_strip_pbxproj(_str origFilename) {
    if(!(origFilename._isempty())) {
        int pbxExt = pos(FILESEP:+'project.pbxproj', origFilename);
        if(pbxExt > 0) {
            _str trimmedFilename = substr(origFilename,1,pbxExt-1);
            return trimmedFilename;
        }
    }
    return origFilename;
}

int _OnUpdate_workspace_open(CMDUI &cmdui,int target_wid,_str command)
{
   _str cmdname='';
   _str filename='';
   parse command with cmdname filename;
   if (filename=="") {
      return(MF_ENABLED);
   }
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      if (file_eq(strip(filename,'B','"'),_strip_filename(_workspace_filename,'N'))) {
         return(MF_ENABLED|MF_CHECKED);
      }
   } else {
      if (file_eq(strip(filename,'B','"'),_workspace_filename)) {
         return(MF_ENABLED|MF_CHECKED);
      }
   }
   return(MF_ENABLED|MF_UNCHECKED);
}

_str _AbsoluteToWorkspace(_str ProjectName, _str WorkspaceFilename = _workspace_filename)
{
   if (WorkspaceFilename=='') {
      return('');
   }
   return(absolute(ProjectName,_GetWorkspaceDir(WorkspaceFilename)));
}

_str _AbsoluteToProject(_str filename,_str ProjectName=_project_name)
{
   if (ProjectName=='') {
      return('');
   }
   return( absolute( filename, _strip_filename(ProjectName,'N')) );
}

_str _RelativeToWorkspace(_str Filename,_str WorkspaceFilename=_workspace_filename)
{
   if (WorkspaceFilename=='') {
      return('');
   }
   return(relative(Filename,_GetWorkspaceDir(WorkspaceFilename)));
}

_str _RelativeToProject(_str Filename,_str ProjectName=_project_name)
{
   if (ProjectName=='') {
      return('');
   }
   return(relative(Filename,_strip_filename(ProjectName,'N')));
}

static _str VSEProjectFilenameList(_str filename_list)
{
   _str list='';
   for (;;) {
      _str cur=parse_file(filename_list);
      if (cur=='') break;
      list=list' 'VSEProjectFilename(cur);
   }
   return(strip(list));
}

_str workspace_project_dependencies(_str ProjectName,boolean OnlyVSEDependencies=true)
{
   if (_workspace_filename=='') {
      return('');
   }
   if (_IsVCPPWorkspaceFilename(_workspace_filename) && !OnlyVSEDependencies) {
      _str Dependencies:[];
      Dependencies._makeempty();
      _str Files[];
      Files[0]=ProjectName;
      GetDependenciesFromVCPPWorkspaceFile(_workspace_filename,Files,Dependencies);
      //Lots of name conversion stuff here.  See comment on GetDependenciesFromVCPPWorkspaceFile
      //for how this stuff is returned.
      _str relativeProjectName=_file_case(_RelativeToWorkspace(GetProjectDisplayName(ProjectName)));
      if (Dependencies._indexin(relativeProjectName)) {
         return(VSEProjectFilenameList(Dependencies:[relativeProjectName]));
      }
      return('');
   }
   if (ProjectName=='') {
      return('');
   }
   return(_ProjectGet_DependencyProjectsList(_ProjectHandle(ProjectName)));
}

_str _WorkspaceGet_AssociatedFileType(int handle)
{
   return(_xmlcfg_get_path(handle,VPWX_WORKSPACE,"AssociatedFileType"));
}
_str _WorkspaceGet_AssociatedFile(int handle)
{
   return(_xmlcfg_get_path(handle,VPWX_WORKSPACE,"AssociatedFile"));
}
void _WorkspaceSet_AssociatedFileType(int handle,_str AssociatedFileType)
{
   _xmlcfg_set_path(handle,VPWX_WORKSPACE,"AssociatedFileType",AssociatedFileType);
}
void _WorkspaceSet_AssociatedFile(int handle,_str AssociatedFile)
{
   _xmlcfg_set_path(handle,VPWX_WORKSPACE,"AssociatedFile",AssociatedFile);
}
void _WorkspaceGet_ProjectFiles(int handle,_str (&ProjectFiles)[])
{
   _xmlcfg_find_simple_array(handle,VPWX_PROJECT'/@File',ProjectFiles,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<ProjectFiles._length();++i) {
      ProjectFiles[i]=translate(_parse_project_command(ProjectFiles[i],"","",""),FILESEP,FILESEP2);
   }
}
void _WorkspaceGet_ProjectNodes(int handle,_str (&ProjectNodes)[])
{
   _xmlcfg_find_simple_array(handle,VPWX_PROJECT,ProjectNodes);
}

/**
 * Add ore replace the specified tag file in the list
 */
int _WorkspaceSet_TagFile(int handle, _str tagfile, _str autoUpdatePath="")
{
   // make sure tagfile is relative to workspace
   _str relativeTagfile = _NormalizeFile(_RelativeToWorkspace(tagfile, _xmlcfg_get_filename(handle)));
   if (autoUpdatePath != "") {
      autoUpdatePath = _NormalizeFile(_RelativeToWorkspace(autoUpdatePath, _xmlcfg_get_filename(handle)));
   }
   int tagfilesNode = _xmlcfg_set_path(handle, VPWX_TAGFILES);
   if (tagfilesNode < 0) {
      return tagfilesNode;
   }

   // make sure the node doesnt already exist
   int node = _xmlcfg_find_simple(handle, VPWTAG_TAGFILE :+ XPATH_FILEEQ("File", relativeTagfile));
   if (node >= 0) {
      // found so replace the other attributes
      if (autoUpdatePath != "") {
         _xmlcfg_set_attribute(handle, node, "AutoUpdateFrom", autoUpdatePath);
      } else {
         _xmlcfg_set_attribute(handle, node, "AutoUpdateFrom", "");
      }
   } else {
      // not found so add it
      int newNode = _xmlcfg_add(handle, tagfilesNode, VPWTAG_TAGFILE, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(handle, newNode, "File", relativeTagfile);
      if (autoUpdatePath != "") {
         _xmlcfg_add_attribute(handle, newNode, "AutoUpdateFrom", autoUpdatePath);
      }
   }

   return 0;
}

/**
 * Remove the TagFiles container from the workspace
 */
int _WorkspaceRemove_TagFiles(int handle)
{
   int node = _xmlcfg_find_simple(handle, VPWX_TAGFILES);
   if (node >= 0) {
      return _xmlcfg_delete(handle, node);
   }

   return 0;
}

/**
 * Remove the specified tag file from the workspace
 */
int _WorkspaceRemove_TagFile(int handle, _str tagfile)
{
   // make sure tagfile is relative to workspace
   _str relativeTagfile = _NormalizeFile(_RelativeToWorkspace(tagfile, _xmlcfg_get_filename(handle)));

   // search for this tag file
   int node = _xmlcfg_find_simple(handle, VPWX_TAGFILE :+ XPATH_FILEEQ("File", relativeTagfile));
   if (node) {
      _xmlcfg_delete(handle, node);
   }

   return 0;
}

/**
 * Get an array of the tag files in the workspace
 */
void _WorkspaceGet_TagFileNames(int handle,_str (&array)[])
{
   _xmlcfg_find_simple_array(handle, VPWX_TAGFILE "/@File", array, TREE_ROOT_INDEX, VSXMLCFG_FIND_VALUES);
}

/**
 * Get an array of the tag file nodes in the workspace
 */
void _WorkspaceGet_TagFileNodes(int handle, typeless (&array)[])
{
   _xmlcfg_find_simple_array(handle, VPWX_TAGFILE, array);
}

/**
 * Find the node for the specified tag file
 */
int _WorkspaceGet_TagFileNode(int handle, _str tagfile)
{
   // make sure tagfile is relative to workspace
   _str relativeTagfile = _NormalizeFile(_RelativeToWorkspace(tagfile, _xmlcfg_get_filename(handle)));

   // search for this tag file
   return _xmlcfg_find_simple(handle, VPWX_TAGFILE :+ XPATH_FILEEQ("File", relativeTagfile));
}

//9:40am 7/19/1999
//RelFilename comes in with quotes on it.  This gives us a little more
//flexibility when we are searching.
static void RemoveDependenciesToFile(_str RelFilename)
{
   _str ProjectFiles[]; ProjectFiles._makeempty();
   _WorkspaceGet_ProjectFiles(gWorkspaceHandle,ProjectFiles);

   int i;
   for (i=0;i<ProjectFiles._length();++i) {
      _str ProjectName=_AbsoluteToWorkspace(ProjectFiles[i]);
      int handle = _ProjectHandle(ProjectName);
      _str configNames[] = null;
      int icfg;
      _ProjectGet_ConfigNames(handle, configNames);
      for (icfg = 0; icfg < configNames._length(); ++icfg) {
         _ProjectRemove_Dependency(handle, RelFilename, "", "", configNames[icfg], true);
      }
      _ProjectSave(handle);
      _maybeGenerateMakefile(ProjectName);
   }
}
int _WorkspaceRemove_ProjectFile(int handle,_str RelProjectFile)
{
   /*
       Note:  We could remove RelProjectFile from the gProjectHashTab but we may add
       try again save code later so we might as well leave the extra file.
   */
   RelProjectFile=translate(RelProjectFile,'/','\');
   typeless array[]; array._makeempty();
   _WorkspaceGet_ProjectNodes(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      _str File=_xmlcfg_get_attribute(handle,array[i],'File');
      File=translate(File,'/','\');
      if (file_eq(File,RelProjectFile)) {
         _xmlcfg_delete(handle,array[i]);
         RemoveDependenciesToFile(RelProjectFile);
         return(0);
      }
   }
   RemoveDependenciesToFile(RelProjectFile);
   return(1);
}
void _WorkspaceGet_ProjectFilesView(int handle,int &files_view_id)
{
   int orig_view_id=_create_temp_view(files_view_id);
   _xmlcfg_find_simple_insert(handle,VPWX_PROJECT'/@File');
   top();
   search(FILESEP2,'@h',FILESEP);
   activate_window(orig_view_id);
}
void _WorkspacePut_ProjectFilesView(int handle,int files_view_id)
{
   int Node=_xmlcfg_find_simple(handle,VPWX_PROJECTS);
   if (Node>=0) {
      _xmlcfg_delete(handle,Node);
   }
   int orig_view_id;
   get_window_id(orig_view_id);
   activate_window(files_view_id);
   top();up();
   for (;;) {
      if (down()) {
         break;
      }
      get_line(auto File);
      _xmlcfg_set_path2(handle,VPWX_PROJECTS,VPWTAG_PROJECT,'File',_NormalizeFile(File));
   }
   _delete_temp_view(files_view_id);
   activate_window(orig_view_id);
}
int _WorkspaceGet_ProjectsNode(int handle)
{
   return(_xmlcfg_find_simple(handle,VPWX_PROJECTS));
}
int _WorkspaceGet_ProjectNode(int handle,_str RelProjectName)
{
   return(_xmlcfg_find_simple(handle,VPWX_PROJECT:+XPATH_STRIEQ('File',_NormalizeFile(RelProjectName))));
}
int _WorkspaceAdd_Project(int handle,_str RelProjectName,boolean AllowFilesThatDontExist=false)
{
   int orig_view_id=0;
   get_window_id(orig_view_id);
   int files_view_id=0;
   _WorkspaceGet_ProjectFilesView(handle,files_view_id);
   if (AllowFilesThatDontExist || file_exists(_AbsoluteToWorkspace(RelProjectName))) {
      p_window_id=files_view_id;
      top();
      int status=search('^'_escape_re_chars(RelProjectName)'$','@rh'_fpos_case);
      if (!status) {
         _delete_temp_view(files_view_id);
         activate_window(orig_view_id);
         return(1);
      } else {
         insert_line(_NormalizeFile(RelProjectName));
         p_window_id=orig_view_id;
      }
   }
   p_window_id=files_view_id;
   sort_buffer('-F '_fpos_case);
   //_remove_duplicates();  Shouldn't have to do this
   p_window_id=orig_view_id;
   _WorkspacePut_ProjectFilesView(handle,files_view_id);
   activate_window(orig_view_id);
   //_xmlcfg_set_path(handle,VPWX_PROJECT,'File',translate(RelProjectName,'/','\'));
   return(0);
}
int _WorkspaceSave(int handle)
{
   vc_make_file_writable(_xmlcfg_get_filename(handle));
   int status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   if (status) {
      _message_box(nls("Could not save workspace file '%s'\n\n%s",_xmlcfg_get_filename(handle),get_message(status)));
      return(status);
   }
   return(0);
}
int _ConvertProjectToWorkspace(_str WorkspaceFilename)
{
   _str ProjectName=WorkspaceFilename;
   WorkspaceFilename=_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_FILE_EXT;
   int handle=_WorkspaceCreate(WorkspaceFilename);

   // The workspace is not open at this point.  Several of the funtions called
   // in here and in _WorkspaceAdd_Project rely on that, so we set one 
   // temporarily
   _str orlg_workspace_filename=_workspace_filename;
   _workspace_filename=WorkspaceFilename;

   _str WorkspacePath=_strip_filename(WorkspaceFilename,'N');
   _WorkspaceAdd_Project(handle,_RelativeToWorkspace(ProjectName));

   int ProjectsNode=_WorkspaceGet_ProjectsNode(handle);
   if (ProjectsNode>=0) {
      _xmlcfg_sort_on_attribute(handle,ProjectsNode,'File','2');
   }

   int status=_WorkspaceSave(handle);
   _xmlcfg_close(handle);
   _workspace_filename=orlg_workspace_filename;
   if (status) {
      return(status);
   }
   _WorkspacePutProjectDate(ProjectName,WorkspaceFilename);
   return(0);
}
int def_verify_external_workspaces=0;
static int VerifyWorkspace(_str Filename)
{
/*
Document file - DO NOT EDIT
Microsoft Developer Studio Workspace File, Format Version 6.00
*/
   int status=0;
   int temp_view_id=0;
   int orig_view_id=0;
   status=_open_temp_view(Filename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   top();up();
   if (file_eq(_get_extension(Filename,1),VCPP_PROJECT_WORKSPACE_EXT)) {
      status=search('Microsoft Developer Studio Workspace File','@h');
   } else if (file_eq(_get_extension(Filename,1),TORNADO_WORKSPACE_EXT)) {
      status=search('Document file - DO NOT EDIT','@h');
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Copy the sample projects to the user's configuration
 * directory, if needed.
 *
 * @return 0 OK, !0 error code
 */
static int maybeCopySampleProjects()
{
   if ( !(def_workspace_options&WORKSPACE_OPT_COPYSAMPLES) ) {
      return(0);
   }

   // If the sample projects have been copied, do nothing more.
   _str local_dir = _localSampleProjectsPath();
   if (isdirectory(local_dir)) return(0);

   // Create the local sample projects directory.
   int status=make_path(local_dir,'0');  /* Give no shell messages options. */
   if (status) {
      popup_message(nls('Unable to create local sample projects directory "%s".\n\nReason: %s',local_dir,get_message(status)));
      return(status);
   }

   // Copy the global sample projects.
   _str globalDir = _globalSampleProjectsPath();
   _str copiedProjectFiles[]=null;
   status = copyFileTree(globalDir, local_dir, 'w', false, copiedProjectFiles);
   if (status) {
      _DelTree(local_dir, true);
      popup_message(nls("Unable to copy the sample projects from '%s' to '%s'.\n\nReason: %s",globalDir,local_dir,get_message(status)));
      return(status);
   }

   // Update the restore section in the sample CPP project.
   /*_str localCPP = local_dir :+ VSSAMPLEWORKSPACECPP :+ "cpp.vpw";
   status = updateRestoreSection(localCPP, local_dir:+VSSAMPLEWORKSPACECPP:+"cpp.cpp");
   if (status) {
      if( !ignore_errors ) popup_message(nls("Unable to save the modified sample project '%s'.\n\nReason: %s",localCPP,get_message(status)));
      return ignore_errors ? 0 : status;
   } */

   // Update the restore section in the sample JAVA project.
   /*_str localJava = local_dir :+ VSSAMPLEWORKSPACEJAVA :+ "java.vpw";
   status = updateRestoreSection(localJava, local_dir:+VSSAMPLEWORKSPACEJAVA:+"file1.java");
   if (status) {
      if( !ignore_errors ) popup_message(nls("Unable to save the modified sample project '%s'.\n\nReason: %s",localJava,get_message(status)));
      return ignore_errors ? 0 : status;
   } */
   int i;
   for (i=0;i<copiedProjectFiles._length();++i) {
      _str cur=copiedProjectFiles[i];
      if (file_eq(WORKSPACE_FILE_EXT,_get_extension(cur,1))) {
         _AddFilesToWorkspaceManager(cur,'Sample Workspaces');
      }
   }
   return(0);
}
static _str WorkspaceSupportedEnvironmentEscapes(_str string)
{
   _str result='';
   int i,j;
   for (i=1;;) {
      j=pos('%',string,i);
      if (!j) {
         result=result:+substr(string,i);
         return(result);
      }
      result=result:+substr(string,i,j-i+1);
      _str ch=substr(string,j+1,1);
      switch (upcase(ch)) {
      case '-':
      case 'W':
      case '(':
      case '[':
         break;
      default:
         result=result:+'%';
      }
      //messageNwait('result='result);
      i=j+1;
   }
}
static void setEnvironmentFromXMLFile()
{
   //setNodeArray = _xmlcfg_find_simple(gWorkspaceHandle, VPWX_SET);
   typeless setNodeArray[] = null;
   int status = _xmlcfg_find_simple_array(gWorkspaceHandle, VPWX_SET, setNodeArray);
   if (status < 0) return;

   // walk the list of environment variables
   int i = 0;
   for (i = 0; i < setNodeArray._length(); i++) {
      // get the name and value attributes
      _str name = _xmlcfg_get_attribute(gWorkspaceHandle, setNodeArray[i], "Name");
      _str value = _xmlcfg_get_attribute(gWorkspaceHandle, setNodeArray[i], "Value");

      // check to see if this var should be parsed on the way in
      if (strieq(substr(value, 1, 3), "%XE")) {
         value = _parse_project_command(WorkspaceSupportedEnvironmentEscapes(substr(value,4)),'', '', '');
      }

      // set the value
      set_env(name, value);
   }
}

void setEnvironmentFromProjectTargetNode(int projectHandle, int targetNode)
{
   // make sure that these values are ok to use
   if ((projectHandle < 0) || (targetNode < 0)) {
      return;
   }

   typeless setNodeArray[] = null;
   int status = _xmlcfg_find_simple_array(projectHandle, "Set", setNodeArray, targetNode);
   if (status < 0) return;

   // walk the list of environment variables
   int i = 0;
   for (i = 0; i < setNodeArray._length(); i++) {
      // get the name and value attributes
      _str name = _xmlcfg_get_attribute(projectHandle, setNodeArray[i], "Name");
      _str value = _xmlcfg_get_attribute(projectHandle, setNodeArray[i], "Value");
      // check to see if this var should be parsed on the way in
      if (strieq(substr(value, 1, 3), "%XE")) {
         value = _parse_project_command(WorkspaceSupportedEnvironmentEscapes(substr(value,4)),'', '', '');
      }
      // set the value
      set_env(name, value);
   }
}

void _ModifyWorkspaceEnvVars()
{
   typeless setNodeArray[] = null;
   int status = _xmlcfg_find_simple_array(gWorkspaceHandle, VPWX_SET, setNodeArray);
   if (status < 0) return;

   _str cmds[];

   // walk the list of environment variables
   int i = 0;
   for (i = 0; i < setNodeArray._length(); i++) {
      // get the name and value attributes
      _str name = _xmlcfg_get_attribute(gWorkspaceHandle, setNodeArray[i], "Name");
      _str value = _xmlcfg_get_attribute(gWorkspaceHandle, setNodeArray[i], "Value");

      if (value:!='') {
         cmds[cmds._length()]='Set ':+name:+'=':+value;
      } else {
         cmds[cmds._length()]='Set ':+name;
      }
   }

   _str result=show('-modal _adv_project_command_form',
                    cmds,
                    null,
                    null,
                    true,
                    "Workspace Environment Options");

   if (result:=='') {
      return;
   }

   cmds=_param1;

   int envNode=_xmlcfg_find_simple(gWorkspaceHandle,VPWX_ENVIRONMENT);

   if (envNode<0) {
      int wkspaceNode=_xmlcfg_find_simple(gWorkspaceHandle,VPWX_WORKSPACE);
      if (wkspaceNode<0) {
         _message_box('There was an error updating the enviroment for the workspace file.');
         return;
      }
      envNode=_xmlcfg_add(gWorkspaceHandle,wkspaceNode,VPWTAG_ENVIRONMENT,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      if (envNode<0) {
         _message_box('There was an error updating the enviroment for the workspace file.');
         return;
      }
   }

   _xmlcfg_delete(gWorkspaceHandle,envNode,true);

   int cmd_index;
   for (cmd_index=0;cmd_index<cmds._length();++cmd_index) {
      _str name='';
      _str value='';

      parse cmds[cmd_index] with 'set ','i' name '=' value;

      int node=_xmlcfg_add(gWorkspaceHandle,envNode,VPWTAG_SET,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      if (node<0) {
         _message_box('There was an error updating the enviroment for the workspace file.');
         return;
      }
      _xmlcfg_set_attribute(gWorkspaceHandle,node,'Name',strip(name));
      _xmlcfg_set_attribute(gWorkspaceHandle,node,'Value',strip(value));
   }

   _WorkspaceSave(gWorkspaceHandle);

   _message_box('Workspace environment variables will not have an effect until the next time the workspace is opened.');
}

void _WorkspaceSet_EnvironmentVariable(int handle, _str name, _str value)
{
   int env_node = _xmlcfg_find_simple(handle, VPWX_ENVIRONMENT);
   if (env_node < 0) {
      int workspaceNode = _xmlcfg_find_simple(handle, VPWX_WORKSPACE);
      env_node = _xmlcfg_add(handle, workspaceNode, VPWTAG_ENVIRONMENT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      if (env_node < 0) {
         return;
      }
   }

   typeless setNodeArray[] = null;
   int status = _xmlcfg_find_simple_array(handle, VPWX_SET, setNodeArray, env_node);
   if (status == 0) {
      // check for dupe
      int i = 0;
      for (i = 0; i < setNodeArray._length(); i++) {
         // get the name and value attributes
         _str w_name = _xmlcfg_get_attribute(handle, setNodeArray[i], "Name");
         if (w_name :== name) {
            // found a match, set value
            _xmlcfg_set_attribute(handle, setNodeArray[i], "Value", strip(value));
            return;
         }
      }
   }

   int node = _xmlcfg_add(handle, env_node, VPWTAG_SET, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (node < 0) {
      return;
   }
   _xmlcfg_set_attribute(handle, node, 'Name', strip(name));
   _xmlcfg_set_attribute(handle, node, 'Value', strip(value));
   set_env(name, value);
   return;
}

/**
 * Displays the Workspace Open dialog box which allows you to open a 
 * workspace.  If a workspace is already open it is closed.  The optional 
 * <i>filename</i> specifies the workspace to open.
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
 * 
 */ 
_command int workspace_open,project_open(_str WorkspaceFilename='',_str notused="",_str restoring_from_invocation="",boolean closeFilesFirst=true,boolean restoreFiles=true)   name_info(FILE_ARG'*,'VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   //result=arg(1);
   //compiler_name=arg(2);
   //restoring_from_invocation=arg(3);
   _macro_delete_line();
   int was_recording=0;
   if (WorkspaceFilename=='') {
      was_recording=_macro();
      _str format_list=_GetWorkspaceExtensionList();
      WorkspaceFilename=_OpenDialog('-new -mdi -modal',
                                    'Open Workspace',
                                    '',     // Initial wildcards
                                    format_list,  // file types
                                    OFN_FILEMUSTEXIST,
                                    WORKSPACE_FILE_EXT,      // Default extensions
                                    '',      // Initial filename
                                    '',      // Initial directory
                                    '',      // Reserved
                                    "Standard Open dialog box"
                                   );
      if (WorkspaceFilename=='') {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',was_recording);
   }
   boolean isEclipse=_IsEclipseWorkspacePath(WorkspaceFilename)||_IsEclipseWorkspaceFilename(WorkspaceFilename);
   // Create the local sample projects, if needed.
   int status=0;
   if(!isVisualStudioPlugin()) {
      // Don't do this if this is the visual studio plugin since we won't ship
      // the sample projects
      status = maybeCopySampleProjects();
      if (status) return(status);
   }
   if(_DebugMaybeTerminate()) {
      return(1);
   }
   WorkspaceFilename=absolute(strip(WorkspaceFilename,'B','"'));

   name := "";
   ConvertedOldProject := false;
   warn_project_file_opened := false;
  
   _str workspace_file_ext = '.':+_get_extension(WorkspaceFilename);
   if (file_eq(workspace_file_ext, PRJ_FILE_EXT)) {
      //Trying to open a project file...
      //First look for a workpace file by the same name
      name=_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_FILE_EXT;
      if (file_exists(name)) {
         _str ProjectName=WorkspaceFilename;
         WorkspaceFilename=name;
         // just warn them that the corresponding workspace was opened
         // delay the toast message until after the workspace is opened
         // otherwise it will get hidden.
         warn_project_file_opened = true;
         //A corresponding workspace '%s' has been found and will be opened instead
         //of the specified project '%s'.
         //
         //Note: If you wish to create a workspace containing only the specified
         //project, you can do so by creating a blank workspace with the Workspaces
         //tab on the New dialog and then adding the project to that workspace
         //using Insert Projects into Workspace.
      } else {
         //We just go ahead and create a new workspace, put this file
         //in it, and open it...
         status = _ConvertProjectToWorkspace(WorkspaceFilename);
         ConvertedOldProject=true;
         WorkspaceFilename=VSEWorkspaceFilename(WorkspaceFilename);
      }
   } else if (file_eq(workspace_file_ext, WORKSPACE_FILE_EXT) ) {
      _str associatedFileName = '';
      if (_IsWorkspaceAssociated(WorkspaceFilename, associatedFileName)) {
         WorkspaceFilename = _strip_filename(WorkspaceFilename,'N'):+associatedFileName;
         status = _WorkspaceAssociate(associatedFileName);
      }
   } else if (file_eq(workspace_file_ext, VCPP_PROJECT_WORKSPACE_EXT) ||
              file_eq(workspace_file_ext, TORNADO_WORKSPACE_EXT) ||
              file_eq(workspace_file_ext, VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT) ||
              file_eq(workspace_file_ext, XCODE_PROJECT_EXT) ||
              file_eq(workspace_file_ext, XCODE_PROJECT_LONG_BUNDLE_EXT) ||
              file_eq(workspace_file_ext, XCODE_PROJECT_SHORT_BUNDLE_EXT) ||
              file_eq(workspace_file_ext, XCODE_WKSPACE_BUNDLE_EXT) ||
              file_eq(workspace_file_ext, VISUAL_STUDIO_SOLUTION_EXT) ||
              file_eq(workspace_file_ext, JBUILDER_PROJECT_EXT) ||
              file_eq(workspace_file_ext, MACROMEDIA_FLASH_PROJECT_EXT)) {
      status = _WorkspaceAssociate(WorkspaceFilename);
   } else if(file_eq(workspace_file_ext, ".xcode") ||
              file_eq(workspace_file_ext, ".xcodeproj")) {
      //WorkspaceFilename :+= "/project.pbxproj";
      status = _WorkspaceAssociate(WorkspaceFilename);
   
   } else if (isEclipse) {
      if (file_eq(workspace_file_ext, ECLIPSE_WORKSPACE_FILE_EXT)) {
         WorkspaceFilename = _strip_filename(WorkspaceFilename,'N');
      }
      WorkspaceFilename=GetVSEWorkspaceNameFromEclipsePath(WorkspaceFilename, ECLIPSE_WORKSPACE_FILE_EXT);
      status = _WorkspaceAssociate(WorkspaceFilename);
   } else if (!file_eq(workspace_file_ext, WORKSPACE_FILE_EXT)) {
      _message_box(nls("Unsupported extension for workspace filename.  Can't open %s",WorkspaceFilename));
      status = COMMAND_CANCELLED_RC;
   }

   if (status) {
      return(status);
   }
   if (closeFilesFirst) {
      if (_workspace_filename!='') {
         // Close workspace and project
         status=workspace_close();
         if (status) {
            return(status);
         }
      } else if (def_restore_flags & RF_PROJECTFILES) {
         status=_close_all2();
         if (status) {
            return(status);
         }
      }
   }

   // DJB 03-14-2007 -- do not jump out of fullscreen mode
   //fullscreen(0);

   if (ConvertedOldProject) {
      //If we converted an old project, the extension is wrong
      if (file_exists(_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_FILE_EXT)) {
         WorkspaceFilename=_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_FILE_EXT;
      } else {
         _message_box(nls("Workspace '%s' not found",WorkspaceFilename));
         return(FILE_NOT_FOUND_RC);
      }
   }
   status=_WorkspaceOpenAndUpdate(WorkspaceFilename);
   if (status) {
      return(status);
   }
   {
      int view_id;
      get_window_id(view_id);
      int ini_view_id;
      status=_ini_get_section(VSEWorkspaceStateFilename(WorkspaceFilename),"State", ini_view_id);
      activate_window(view_id);
      if (!status) {
         int old_restore_flags=def_restore_flags;
         //if (ProjectWorkingDirectory!='') {
         //}
         def_restore_flags&=~RF_CWD;
         was_recording=_macro();
         boolean doRestoreFiles = (def_restore_flags & RF_PROJECTFILES)!=0;
         if (!restoreFiles) {
            doRestoreFiles = false;
         }
         restore(restoring_from_invocation,ini_view_id,_strip_filename(WorkspaceFilename,'N'),doRestoreFiles,true);
         _macro('m',was_recording);
         def_restore_flags=old_restore_flags;
         _delete_temp_view(ini_view_id);
      }
   }

   _macro_call('workspace_open',_workspace_filename);
   // set any environment variables from the workspace file
   setEnvironmentFromXMLFile();

   _str ProjectName='';
   _str cur_project_name='';
   _str ProjectFiles[];
   _GetWorkspaceFiles(WorkspaceFilename, ProjectFiles);
   status=_ini_get_value(VSEWorkspaceStateFilename(WorkspaceFilename), "Global", "CurrentProject", cur_project_name);
   if (cur_project_name != '') {
      boolean projectFound = false;
      int i;
      for (i = 0; i < ProjectFiles._length(); ++i) {
         if (file_eq(cur_project_name, ProjectFiles[i])) {
            projectFound = true;
            break;
         }
      }
      if (!projectFound) {
         cur_project_name = '';
      } else {
         ProjectName = absolute(cur_project_name, _strip_filename(WorkspaceFilename,'N'));
      }
   }
   if (cur_project_name == '' && ProjectFiles._length()) {
      ProjectName = absolute(ProjectFiles[0], _strip_filename(WorkspaceFilename,'N'));
   }

   workspace_set_active(ProjectName,true,true,false);
   _menu_add_workspace_hist(_workspace_filename);
   call_list('_workspace_opened_');

   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   if (!(def_autotag_flags2 & AUTOTAG_WORKSPACE_NO_OPEN)) {
      _MaybeRetagWorkspace('',true,true,true);//Update tagfiles etc if any projects changed in another workspace
   }

   toolbarUpdateWorkspaceList();
   toolbarRestoreState(_workspace_filename);
#if !__UNIX__
   _init_vcpp();
#endif

   // check any auto-updated tag files
   check_autoupdated_tagfiles();

   if (warn_project_file_opened) {
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_PROJECT_ERROR,
                     nls("A corresponding workspace '%s' has been found and will be opened instead of the specified project '%s'.<p>Note: If you wish to create a workspace containing only the specified project, you can do so by creating a blank workspace with the Workspaces tab on the New dialog and then adding the project to that workspace using Insert Projects into Workspace.",WorkspaceFilename,ProjectName),
                     "Open workspace", 1);
   }

   return(0);
}

/**
 * Open workspace from another vendor
 *
 * @param WorkspaceFilename
 *
 * @return
 */
static int workspace_open_other(_str workspaceFilename, _str caption, _str extList, _str initialWildcards = '')
{
   if (workspaceFilename == "") {
      int was_recording=_macro();
      workspaceFilename = _OpenDialog('-new -mdi -modal',
                                      caption,
                                      initialWildcards, // Initial wildcards
                                      extList,  // file types
                                      OFN_FILEMUSTEXIST,
                                      '',      // Default extensions
                                      '',      // Initial filename
                                      '',      // Initial directory
                                      '',      // Reserved
                                      "Standard Open dialog box"
                                     );
      if (workspaceFilename == "") {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',was_recording);
   }

   // pass the call
   return workspace_open(workspaceFilename);
}

_command int workspace_open_xcode(_str workspaceFilename = "") name_info(FILE_ARG'*,')
{
   _macro_delete_line();
   #if __MACOSX__
   _str initialWildcards = "*"XCODE_PROJECT_LONG_BUNDLE_EXT";*"XCODE_PROJECT_SHORT_BUNDLE_EXT;
   #else
   _str initialWildcards = '';
   #endif
   // pass the call
   return workspace_open_other(workspaceFilename, "Open Xcode Project",
                               "Xcode Project Files(*"XCODE_PROJECT_LONG_BUNDLE_EXT";*"XCODE_PROJECT_SHORT_BUNDLE_EXT"),All Files("ALLFILES_RE")" ,
                               initialWildcards);

}

_command int workspace_open_visualstudio(_str workspaceFilename = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(workspaceFilename, "Open Visual Studio .NET Solution",
                               "Visual Studio Solution Files(*"VISUAL_STUDIO_SOLUTION_EXT"),All Files("ALLFILES_RE")");
}

_command int workspace_open_visualcpp(_str workspaceFilename = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(workspaceFilename, "Open Visual C++ Workspace",
                               "Visual C++ Workspace Files(*"VCPP_PROJECT_WORKSPACE_EXT"),All Files("ALLFILES_RE")");
}

_command int workspace_open_visualcppembedded(_str workspaceFilename = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(workspaceFilename, "Open Visual C++ Embedded Workspace",
                               "Visual C++ Embedded Workspace Files(*"VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT"),All Files("ALLFILES_RE")");
}

_command int workspace_open_tornado(_str workspaceFilename = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(workspaceFilename, "Open Tornado Workspace",
                               "Tornado Workspace Files(*"TORNADO_WORKSPACE_EXT"),All Files("ALLFILES_RE")");
}

_command int workspace_open_eclipse(_str workspaceFilename = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   if (workspaceFilename=='') {
      _str result = _ChooseDirDialog();
      if ( result=='' ) {
         return(COMMAND_CANCELLED_RC);
      }
      workspaceFilename=result;
   }
   boolean isEclipse=_IsEclipseWorkspacePath(workspaceFilename)||_IsEclipseWorkspaceFilename(workspaceFilename);
   if (!isEclipse) {
      _message_box(nls("'%s' is not a valid Eclipse workspace path.\n\nYou must pick path that ends in 'workspace'",workspaceFilename));
      return(INVALID_ARGUMENT_RC);
   }
   // Doesn't make any sense to call workpace_open_other, because it cannot
   // prompt the user for an eclipse workspace.
   return workspace_open(workspaceFilename);
}

_command int workspace_open_maven(_str pomXmlPath = "") name_info(FILE_ARG'*,')
{
    _macro_delete_line();

    if (pomXmlPath == "") {
        int was_recording=_macro();
#if __MACOSX__
        _str initialWildcards = "*"MAVEN_BUILD_FILE_EXT;
#else
        _str initialWildcards = '';
#endif
        pomXmlPath = _OpenDialog('-new -mdi -modal',
                                 "Open Maven pom.xml File",
                                 initialWildcards,     // Initial wildcards
                                 "Maven pom.xml File(*"MAVEN_BUILD_FILE_EXT"),All Files("ALLFILES_RE")",  // file types
                                 OFN_FILEMUSTEXIST,
                                 '',      // Default extensions
                                 '',      // Initial filename
                                 '',      // Initial directory
                                 '',      // Reserved
                                 "Standard Open dialog box"
                                );
        if (pomXmlPath == "") {
            return(COMMAND_CANCELLED_RC);
        }
        _macro('m',was_recording);
    }

    // Strip quotes and lead/trail spaces
    pomXmlPath = strip(pomXmlPath, "B", " \t");
    pomXmlPath = strip(pomXmlPath, "B", "\"");

    // Make sure this file is named pom.xml
    _str pomXmlFilename = _strip_filename(pomXmlPath,'P');
    if (!file_eq(pomXmlFilename,MAVEN_BUILD_FILE_NAME)) {
        _message_box("Maven project files must be named pom.xml");
        return(MISSING_FILENAME_RC);
    }

    // Get the project/name node from the pom.xml file. Fall back
    // to using artifactId if no name node.
    _str mvnProjName = maven_get_project_name(pomXmlPath);
    if (mvnProjName == "") {
        mvnProjName = maven_get_artifact_name(pomXmlPath);
    }
    if (mvnProjName == "") {
        message("Could not read project name from pom.xml");
        return(ERROR_READING_FILE_RC);
    }

    _str projectDirectory = _strip_filename(pomXmlPath, 'NE');

    _str workspaceName =  projectDirectory :+ mvnProjName :+ WORKSPACE_FILE_EXT;
    _str projectName = projectDirectory :+ mvnProjName :+ PRJ_FILE_EXT;

    boolean workspaceCreated = false;

    if (!file_exists(workspaceName)) {
        workspaceCreated = true;

        // not found so create new workspace
        workspace_new(false, _strip_filename(workspaceName, 'P'), _strip_filename(workspaceName, 'N'));

        // create the project
        workspace_new_project2(projectName, "Maven", _strip_filename(projectName, 'PE'), workspaceName, false, true);
    }

    // open the workspace
    workspace_open(workspaceName);

    if (workspaceCreated) {

        _str packType = maven_get_artifact_packaging(pomXmlPath);
        if(packType == 'jar') {
            // TODO: Create/Modify the "Execute" target to provide the correct
            // parameters to Java with the correct path & name of the 
            // .jar file 
        }

        // retag the workspace
        // NOTE:  it is *very* important that the workspace be retagged before
        //        toolbarUpdateFilderList() gets called.  when in package view,
        //        updating the filter list uses tagging to figure out the package
        //        that each file belongs in
        useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
        _workspace_update_files_retag(false, false, false, true, false, false, useThread);

        // update the toolbar
        toolbarUpdateFilterList(projectName);
    }

    return 0;
}

_command int workspace_open_ant(_str xmlBuildFile = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   if (xmlBuildFile == "") {
      int was_recording=_macro();
      #if __MACOSX__
      _str initialWildcards = "*"ANT_BUILD_FILE_EXT;
      #else
      _str initialWildcards = '';
      #endif
      xmlBuildFile = _OpenDialog('-new -mdi -modal',
                                 "Open Ant XML Build File",
                                 initialWildcards,     // Initial wildcards
                                 "Ant XML Build Files(*"ANT_BUILD_FILE_EXT"),All Files("ALLFILES_RE")",  // file types
                                 OFN_FILEMUSTEXIST,
                                 '',      // Default extensions
                                 '',      // Initial filename
                                 '',      // Initial directory
                                 '',      // Reserved
                                 "Standard Open dialog box"
                                );
      if (xmlBuildFile == "") {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',was_recording);
   }

   // make sure there are no quotes on xmlBuildFile
   xmlBuildFile = strip(xmlBuildFile, "B", " \t");
   xmlBuildFile = strip(xmlBuildFile, "B", "\"");

   // figure out the name of the corresponding workspace/project.  this will be the
   // name of the build file with the vpw/vpj extension
   _str workspaceName = _strip_filename(xmlBuildFile, 'E') :+ WORKSPACE_FILE_EXT;
   _str projectName = _strip_filename(xmlBuildFile, 'E') :+ PRJ_FILE_EXT;

   // create the corresponding workspace/project if necessary
   boolean workspaceCreated = false;
   if (!file_exists(workspaceName)) {
      workspaceCreated = true;

      // not found so create new workspace
      workspace_new(false, _strip_filename(workspaceName, 'P'), _strip_filename(workspaceName, 'N'));

      // create the project
      workspace_new_project2(projectName, "Java - Ant", _strip_filename(projectName, 'PE'), workspaceName, false, true);
   }

   // open the workspace
   workspace_open(workspaceName);

   if (workspaceCreated) {
      // let the user know what is being done
      message("Scanning XML build file '" _strip_filename(xmlBuildFile, 'P') "'");

      // add the ant build file to the project
      _AddFileToProject(xmlBuildFile, projectName);

      // get dependencies recursively
      _str depList[];
      _ant_GetDependencyList(xmlBuildFile, depList, true);

      // add all dependent ant build files to the project
      int i;
      for (i = 0; i < depList._length(); i++) {
         _AddFileToProject(depList[i], projectName);
      }

      // determine which dirs should be added with *.java wildcard
      // NOTE: cannot just add the dir that the ant build file is in because
      //       there is a possibility that the wildcards will overlap
      _str wildcardList[];
      for (i = 0; i < depList._length(); i++) {
         boolean addNewPath = true;

         // get path part of current file
         _str newPath = _strip_filename(depList[i], 'N');
         _maybe_append_filesep(newPath);
         int newPathLength = length(newPath);

         int k;
         for (k = 0; k < wildcardList._length(); k++) {
            _str oldPath = wildcardList[k];
            if (oldPath == "") continue;

            oldPath = _strip_filename(oldPath, 'N');
            _maybe_append_filesep(oldPath);
            int oldPathLength = length(oldPath);

            if (oldPathLength <= newPathLength) {
               // check to see if oldPath contains newPath
               if (file_eq(oldPath, substr(newPath, 1, oldPathLength))) {
                  // oldPath contains newPath so disregard newPath
                  addNewPath = false;
                  break;
               } else {
                  // oldPath does not contain newPath
               }
            } else {
               // check to see if newPath contains oldPath
               if (file_eq(newPath, substr(oldPath, 1, newPathLength))) {
                  // newPath contains oldPath so remove oldPath and continue
                  wildcardList[k] = "";
               } else {
                  // newPath does not contain oldPath
               }
            }
         }

         // add newPath if necessary
         if (addNewPath) {
            wildcardList[wildcardList._length()] = newPath;
         }
      }

      // add each path in wildcardList with *.java
      int projectHandle = _ProjectHandle(projectName);
      int m;
      for (m = 0; m < wildcardList._length(); m++) {
         _ProjectAdd_Wildcard(projectHandle, _RelativeToProject(wildcardList[m], projectName) "*.java", "", true, false);
      }

      // parse the xml file to check for a gwt build file
      int status = _gwt_parseBuildFile(xmlBuildFile, projectHandle, auto sdkNode, auto hasDevMode, 
                           auto gwtAppName, auto gwtFullName);
      if (status) {
         return 1;
      }

      // load the configuration list from the project file
      _str configList[] = null;
      _ProjectGet_ConfigNames(projectHandle, configList);

      // check for ant targets for 'clean' and 'rebuild'
      int handle = _xmlcfg_open(xmlBuildFile, status, VSXMLCFG_OPEN_REFCOUNT);
      if(handle < 0 || status < 0) {
         return 1;
      }
      int antCleanNode = _xmlcfg_find_simple(handle, "/project/target[@name='clean']");
      int antRebuildNode = _xmlcfg_find_simple(handle, "/project/target[@name='rebuild']");
      if (gwtAppName != '' && gwtFullName != '') {
         _str googleClass = 'com.google.gwt.dev.';
         if (hasDevMode) {
            googleClass :+= 'DevMode';
         } else {
            googleClass :+= 'HostedMode';
         }
         _gwt_generateDebugTarget(handle,googleClass,gwtAppName,gwtFullName);
         def_antmake_use_classpath = 0;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }

      _xmlcfg_close(handle);

      // update the project file to reflect the selections
      int n = 0;
      for (n = 0; n < configList._length(); n++) {
         // find the config node
         int configNode = _ProjectGet_ConfigNode(projectHandle, configList[n]);
         if (configNode < 0) continue;

         // find the relevant target nodes
         int buildTargetNode = _ProjectGet_TargetNode(projectHandle, "build", configList[n]);
         int rebuildTargetNode = _ProjectGet_TargetNode(projectHandle, "rebuild", configList[n]);
         int cleanTargetNode = _ProjectGet_TargetNode(projectHandle, "clean", configList[n]);
         int executeTargetNode = _ProjectGet_TargetNode(projectHandle, "execute", configList[n]);
         int debugTargetNode = _ProjectGet_TargetNode(projectHandle, "debug", configList[n]);
   
         // remove the dialogs for these nodes since they will be using ant
         _ProjectSet_TargetDialog(projectHandle, buildTargetNode, "");
         _ProjectSet_TargetDialog(projectHandle, rebuildTargetNode, "");
         _ProjectSet_TargetDialog(projectHandle, cleanTargetNode, "");

         // build is a special case that does not get the target form.  it will call the
         // default build target in the ant build file
         _ProjectSet_TargetRunFromDir(projectHandle, buildTargetNode, ".");
         _ProjectSet_TargetCmdLine(projectHandle, buildTargetNode, "antmake -emacs -f " maybe_quote_filename(_strip_filename(xmlBuildFile, "P")), "");

         // set the command to launch the target form with the xml build file
         _str targetFormCmd = "ant-target-form " maybe_quote_filename(projectName) " " maybe_quote_filename(xmlBuildFile);
         _ProjectSet_TargetRunFromDir(projectHandle, cleanTargetNode, "");
         _ProjectSet_TargetRunFromDir(projectHandle, rebuildTargetNode, "");
         // if we found a 'clean' target we can set the 'clean' and 'rebuild' commands accordingly
         if (antCleanNode >= 0) {
            _ProjectSet_TargetCmdLine(projectHandle,cleanTargetNode,
               'antmake -emacs -f build.xml clean');
            _ProjectSet_TargetCmdLine(projectHandle,rebuildTargetNode,
               'antmake -emacs -f build.xml clean build');
         } else {
            _ProjectSet_TargetCmdLine(projectHandle, cleanTargetNode, targetFormCmd, "Slick-C");
         }
         if (antRebuildNode >= 0) {
            _ProjectSet_TargetCmdLine(projectHandle,rebuildTargetNode,
               'antmake -emacs -f build.xml rebuild');
         } else {
            _ProjectSet_TargetCmdLine(projectHandle, rebuildTargetNode, targetFormCmd, "Slick-C");
         }
         // if this appears to be a gwt application, set the execute and debug commands appropriately
         if (gwtAppName != '' && gwtFullName != '') {
            // 1.7.1 and earlier uses 'HostedMode' to launch, 2.0.0 and later should use 'DevMode'
            _str launchClass = 'HostedMode';
            _str executeTarget = 'hosted';
            if (hasDevMode) {
               launchClass = 'DevMode';
               executeTarget = 'devmode';
            }
            _ProjectSet_TargetCmdLine(projectHandle,executeTargetNode,'antmake -emacs -f build.xml 'executeTarget);
            _ProjectSet_TargetBuildFirst(projectHandle,executeTargetNode,false);
            _ProjectSet_TargetCmdLine(projectHandle,_ProjectGet_TargetNode(projectHandle,'debug',configList[n]),
               'antmake -emacs -f build.xml debug');
            _ProjectSet_TargetBuildFirst(projectHandle,_ProjectGet_TargetNode(projectHandle,'debug',configList[n]),false);
            _ProjectSet_AppType(projectHandle,configList[n],APPTYPE_GWT);
            // can't fill in the command to deploy the application because the location of the appengine
            // does not reside anywhere we can see. this must be provided by the user.
            _ProjectAdd_Target(projectHandle,'DeployCmd','','',configList[n],"Never","");
            _ProjectAdd_Target(projectHandle,'DeployProject','gwt-deploy-app','&Deploy Project...',configList[n],
               "Always","Slick-C");
         }
      }

      // save the project file
      _ProjectSave(projectHandle);

      // clear the message
      clear_message();

      // retag the workspace
      // NOTE:  it is *very* important that the workspace be retagged before
      //        toolbarUpdateFilderList() gets called.  when in package view,
      //        updating the filter list uses tagging to figure out the package
      //        that each file belongs in
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, true, false, false, useThread);

      // update the toolbar
      toolbarUpdateFilterList(projectName);
   }

   return 0;
}

_command int workspace_open_nant(_str xmlBuildFile = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   if (xmlBuildFile == "") {
      int was_recording=_macro();
      xmlBuildFile = _OpenDialog('-new -mdi -modal',
                                 "Open NAnt Build File",
                                 '',     // Initial wildcards
                                 "NAnt Build Files(*"NANT_BUILD_FILE_EXT"),All Files("ALLFILES_RE")",  // file types
                                 OFN_FILEMUSTEXIST,
                                 '',      // Default extensions
                                 '',      // Initial filename
                                 '',      // Initial directory
                                 '',      // Reserved
                                 "Standard Open dialog box"
                                );
      if (xmlBuildFile == "") {
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',was_recording);
   }

   // make sure there are no quotes on xmlBuildFile
   xmlBuildFile = strip(xmlBuildFile, "B", " \t");
   xmlBuildFile = strip(xmlBuildFile, "B", "\"");

   // figure out the name of the corresponding workspace/project.  this will be the
   // name of the build file with the vpw/vpj extension
   _str workspaceName = _strip_filename(xmlBuildFile, 'E') :+ WORKSPACE_FILE_EXT;
   _str projectName = _strip_filename(xmlBuildFile, 'E') :+ PRJ_FILE_EXT;

   // create the corresponding workspace/project if necessary
   boolean workspaceCreated = false;
   if (!file_exists(workspaceName)) {
      workspaceCreated = true;

      // not found so create new workspace
      workspace_new(false, _strip_filename(workspaceName, 'P'), _strip_filename(workspaceName, 'N'));

      // create the project
      workspace_new_project2(projectName, 'NAnt', '', workspaceName, false, true);
   }

   // open the workspace
   workspace_open(workspaceName);

   if (workspaceCreated) {
      // let the user know what is being done
      message("Scanning XML build file '" _strip_filename(xmlBuildFile, 'P') "'");

      // add the NAnt build file to the project
      _AddFileToProject(xmlBuildFile, projectName);

      // get dependencies recursively
      _str depList[];
      _nant_GetDependencyList(xmlBuildFile, depList, true);

      // add all dependent ant build files to the project
      int i;
      for (i = 0; i < depList._length(); i++) {
         _AddFileToProject(depList[i], projectName);
      }

      // clear the message
      clear_message();

      // retag the workspace
      // NOTE:  it is *very* important that the workspace be retagged before
      //        toolbarUpdateFilderList() gets called.  when in package view,
      //        updating the filter list uses tagging to figure out the package
      //        that each file belongs in
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, true, false, false, useThread);

      // update the toolbar
      toolbarUpdateFilterList(projectName);
   }

   return 0;
}

_command int workspace_open_qtmakefile(boolean isQT = true, _str makefile = "")   name_info(FILE_ARG'*,')
{
   return workspace_open_makefile(true, makefile);
}
/**
 * 
 * Calculate the name of the corresponding workspace/project for a workspace created
 * from an imported makefile. For makefiles, the base name is the directory name if 
 * in valid directory. If not, base name is the name of the actual makefile. The 
 * workspace and project files will be the base name plus the vpw/vpj extensions. 
 * 
 * @param makefileNamename Name of makefile from which to calculate project and 
 *                         workspace file names.
 * @param workspace        (output) Calculated workspace file name.
 * @param projectName      (output) Calculated project file name.
 * 
 */
static void createWkProjNamesFromMakefile(_str makefileName, _str& workspaceName, _str& projectName) {
   _str workspacePath = _strip_filename(makefileName, 'N');
   if (last_char(workspacePath) == FILESEP) {
      workspacePath = substr(workspacePath, 1, workspacePath._length() - 1);
   }
   if (isdrive(workspacePath) || !isdirectory(workspacePath) || last_char(workspacePath) :== FILESEP) {
      workspaceName = _strip_filename(makefileName, 'E') :+ WORKSPACE_FILE_EXT;
      projectName = _strip_filename(makefileName, 'E') :+ PRJ_FILE_EXT;
   } else {
      int lastp = lastpos(FILESEP, workspacePath);
      if (lastp) {
         workspaceName = workspacePath :+ FILESEP :+ substr(workspacePath, lastp + 1) :+ WORKSPACE_FILE_EXT;
         projectName   = workspacePath :+ FILESEP :+ substr(workspacePath, lastp + 1) :+ PRJ_FILE_EXT;
      }
   }
}

#define MAKE_NEW_MAKEFILE_PROJECT -1
/** 
 * 
 * 
 * @param workspaceName
 * @param makefileName
 * @param wildcards
 * @param excludes
 * @param findRecursiveCalls
 * @param addRecursiveCallsAsProjects
 * @param isQT
 * @param showProjPropDialog
 * @param destProjectHandle
 * 
 * @return typeless
 */
static addMakefileProjectToWorkspace(_str workspaceName, _str makefileName, _str wildcards, _str excludes, boolean findRecursiveCalls, boolean addRecursiveCallsAsProjects, boolean isQT, boolean showProjPropDialog = true, int destProjectHandle = MAKE_NEW_MAKEFILE_PROJECT) {

   _str projectName = "";
   createWkProjNamesFromMakefile(makefileName, auto workspaceNameDummy, projectName);

   //Scan the makefile for files to add to the project
   _str fileslist[], recursiveMakefilesList[];
   fileslist._makeempty();
   recursiveMakefilesList._makeempty();
   _str runTargetName = '';
   MI_projectTargets targetlist;
   int status = MI_getFilesInMakefile(makefileName, '', fileslist, targetlist, runTargetName, recursiveMakefilesList, true, true, wildcards, excludes, findRecursiveCalls, isQT);
   if (status) {
      return status;
   }

   //if makefile did not provide an executable name, assume the project name.
   if (runTargetName == '') {
      runTargetName = _strip_filename(projectName, 'PDE');
   }

   int projectHandle = destProjectHandle;
   // create the project if a project handle were not passed in
   if (destProjectHandle == MAKE_NEW_MAKEFILE_PROJECT) {
      workspace_new_project2(projectName, isQT?"QTMakefile":"Makefile",
                             _strip_filename(projectName, 'PE'), workspaceName,
                             false, true, '', '', false);
      projectHandle = _ProjectHandle(projectName);
   }

   fileslist[fileslist._length()] = makefileName;
   _AddFileToProject(fileslist, projectName, projectHandle);

   //Set targets if creating a new project
   if (destProjectHandle == MAKE_NEW_MAKEFILE_PROJECT) {
      _ProjectSet_BuildSystem(projectHandle, "");
      _ProjectSet_BuildMakeFile(projectHandle, _strip_filename(makefileName, 'P'));
      _ProjectSet_OutputFile(projectHandle, runTargetName, "Release");
      int buildTargetNode = _ProjectGet_TargetNode(projectHandle, "Build", "Release");
      if (buildTargetNode >= 0) {
         _ProjectSet_TargetCmdLine(projectHandle, buildTargetNode, 'make -f ' :+ _strip_filename(makefileName, 'P') :+ ' all');
         //_ProjectSet_TargetPreMacro(projectHandle, buildTargetNode, 'checkQTMakefileDate');
         //_ProjectSet_TargetPostMacro(projectHandle, buildTargetNode, 'checkedQTMakefileDate');
      }
      int rebuildTargetNode = _ProjectGet_TargetNode(projectHandle, "Rebuild", "Release");
      if (rebuildTargetNode >= 0) {
         _ProjectSet_TargetCmdLine(projectHandle, rebuildTargetNode, 'make -f ' :+ _strip_filename(makefileName, 'P') :+ ' clean all');
         //_ProjectSet_TargetPreMacro(projectHandle, rebuildTargetNode, 'checkQTMakefileDate');
         //_ProjectSet_TargetPostMacro(projectHandle, rebuildTargetNode, 'checkedQTMakefileDate');
      }
   }

   _str value;
   foreach (value in recursiveMakefilesList) {
      addMakefileProjectToWorkspace(workspaceName, value, wildcards, excludes, findRecursiveCalls, addRecursiveCallsAsProjects, isQT, false, addRecursiveCallsAsProjects ? MAKE_NEW_MAKEFILE_PROJECT : projectHandle);
   }

   if (showProjPropDialog) show_project_properties_files_tab();

   // save the project file if a new one were created
   if (destProjectHandle == MAKE_NEW_MAKEFILE_PROJECT) {
      _ProjectSave(projectHandle);
   }
}
_command int workspace_open_makefile(boolean isQT = false, _str makefile = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();
   //Set defaults
   boolean findRecursiveCalls          = false;
   boolean addRecursiveCallsAsProjects = false;
   _str    wildcards                   = '';
   _str    excludes                    = '';

   //Show the dialog box.
   if (makefile == "") {
      int was_recording=_macro();
      int result = show('-modal _import_makefile_form', isQT);
      if (result != IDOK) {
         return 0;
      }
      makefile                    = _param1;
      findRecursiveCalls          = _param2;
      addRecursiveCallsAsProjects = _param3;
      wildcards                   = _param4;
      excludes                    = _param5;
      _macro('m',was_recording);
   }

   // make sure there are no quotes on xmlBuildFile
   makefile = strip(makefile, "B", " \t");
   makefile = strip(makefile, "B", "\"");

   message("Scanning makefile '" _strip_filename(makefile, 'P') "'");

   _str workspaceName = "";
   _str projectName = "";
   createWkProjNamesFromMakefile(makefile, workspaceName, projectName);

   // create the corresponding workspace/project if necessary
   boolean workspaceCreated = false;
   if (!file_exists(workspaceName)) {
      workspaceCreated = true;

      // not found so create new workspace
      workspace_new(false, _strip_filename(workspaceName, 'P'), _strip_filename(workspaceName, 'N'));
   }

   // open the workspace
   workspace_open(workspaceName);

   if (workspaceCreated) {
      // let the user know what is being done
      message("Adding files to project '" projectName "'");

      //Add the makefile as a project into the workspace.
      addMakefileProjectToWorkspace(workspaceName, makefile, wildcards, excludes, findRecursiveCalls, addRecursiveCallsAsProjects, isQT);

      // clear the message
      clear_message();

      // retag the workspace
      // NOTE:  it is *very* important that the workspace be retagged before
      //        toolbarUpdateFilderList() gets called.  when in package view,
      //        updating the filter list uses tagging to figure out the package
      //        that each file belongs in
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, true, false, false, useThread);

      // update the toolbar
      toolbarUpdateFilterList(projectName);
   }

   return 0;
}

_command int workspace_open_jbuilder(_str projectName = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(projectName, "Open JBuilder Project File",
                               "JBuilder Project Files(*"JBUILDER_PROJECT_EXT"),All Files("ALLFILES_RE")");
}


_command int workspace_open_flash(_str projectFile = "")   name_info(FILE_ARG'*,')
{
   _macro_delete_line();

   // pass the call
   return workspace_open_other(projectFile, "Open Flash Project File",
                               "Flash Project Files(*"MACROMEDIA_FLASH_PROJECT_EXT"),All Files("ALLFILES_RE")");
}

int _OnUpdate_workspace_insert(CMDUI &cmdui,int target_wid,_str command)
{
////   if (_workspace_filename=='' || _IsWorkspaceAssociated(_workspace_filename)) {
   if (_workspace_filename=='' || !_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

static void _RecursiveAddDependencies(_str filename)
{
   _str DependencyProjects[];
   _ProjectGet_DependencyProjects(_ProjectHandle(filename),DependencyProjects);
   int i;
   for (i=0;i<DependencyProjects._length();++i) {
      filename=_AbsoluteToWorkspace(DependencyProjects[i]);

      _str ConfigList[];
      _ProjectGet_ConfigNames(_ProjectHandle(filename),ConfigList);
      // make the first configuration in the inserted project active
      if (!ConfigList._length()) {
         _message_box(nls("Project file %s has no configurations.", _strip_filename(filename, "P")));
         continue;
      }

      if (_WorkspaceAdd_Project(gWorkspaceHandle,DependencyProjects[i]) ) {
         continue;
      }
      _WorkspacePutProjectDate(filename);
      _str firstConfig=ConfigList[0];
      _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename), "ActiveConfig",
                     _RelativeToWorkspace(filename, _workspace_filename), firstConfig, _fpos_case);
      _RecursiveAddDependencies(filename);

   }
}

/**
 * Allows you to add an existing project to the currently open workspace.  
 * The optional <i>filename</i> specifies the project to add.
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
_command int workspace_insert(_str filename='',/*_str Dependency='',*/boolean quiet=false,
                              boolean AllowEmptyFiles=false,
                              boolean RetagWorkspaceFiles=true) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{

   if (_IsWorkspaceAssociated(_workspace_filename)) {
      // pass the call
      return workspace_insert_associated(filename, quiet, AllowEmptyFiles, RetagWorkspaceFiles);
   }

   if (!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
      _message_box('This feature is not supported for the current workspace');
      return(1);
   }

   int was_recording=_macro();
   _macro_delete_line();
   if (_workspace_filename=='') {
      _message_box(nls('No workspace open'));
      return(1);
   }

   if (filename=='') {
      _str format_list='Project Files(*'PRJ_FILE_EXT'),Android Manifest File(AndroidManifest.xml),All Files('ALLFILES_RE')';

      filename=_OpenDialog('-new -mdi -modal',
                           'Add Project to Workspace',
                           '',     // Initial wildcards
                           format_list,  // file types
                           OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT,
                           '*.vpj',      // Default extensions
                           '',      // Initial filename
                           '',      // Initial directory
                           '',      // Reserved
                           ''
                          );
      if (filename=='') {
         return(COMMAND_CANCELLED_RC);
      }
   } else {
      // if a single filename was passed in, make sure the filename is quoted
      // so parse_file performs properly
      filename = maybe_quote_filename(filename);
   }
   int status=0;
   _str filenameList = filename;
   _str firstFilename='';
   for (;;) {
      // parse the list of filenames
      filename = parse_file(filenameList, false);
      if (firstFilename=='') {
         firstFilename=filename;
      }
      if (filename == "") break;

      if (get_extension(filename,true) != PRJ_FILE_EXT) {
         if (_strip_filename(filename,'P') == 'AndroidManifest.xml') {
            workspace_open_android(filename, false);
            continue;
         }
      }

      // validate the project file
      int handle=_ProjectHandle(_AbsoluteToWorkspace(filename),status);
      if (status) {
         // error so remove it from cache
         _ProjectCache_Update(_AbsoluteToWorkspace(filename));
         if (!quiet) {
            _message_box(nls("The project '%s' is not a valid SlickEdit project.", _strip_filename(filename, "P")));
         }
         return INVALID_ARGUMENT_RC;
      }

      // We already know that our workspace is not associated - we don't want to allow adding 
      // associated projects to it because of compatibility issues
      if (project_is_associated_file(filename)) {
         if (!quiet) {
            _message_box(nls("Cannot add non-SlickEdit project '%s' to a SlickEdit workspace.", _strip_filename(filename, "P")));
         }
         continue;
      }

      if (_WorkspaceAdd_Project(gWorkspaceHandle,_RelativeToWorkspace(filename),AllowEmptyFiles) ) {
         if (!quiet) {
            _message_box(nls("There is already a file named '%s' is already in this workspace.",_strip_filename(filename,'P')));
         }
         continue;
      }

      _str ConfigList[];
      _ProjectGet_ConfigNames(_ProjectHandle(filename),ConfigList);
      // make the first configuration in the inserted project active
      if (!ConfigList._length()) {
         _message_box(nls("Project file %s has no configurations.", _strip_filename(filename, "P")));
         continue;
      }
      _WorkspacePutProjectDate(filename);
      _str firstConfig=ConfigList[0];
      _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename), "ActiveConfig",
                     _RelativeToWorkspace(filename, _workspace_filename), firstConfig, _fpos_case);

      // Don't really need this if because associated projects are never inserted into our workspace

      //_tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
      /*say('_GetWorkspaceTagsFilename()='_GetWorkspaceTagsFilename());
      _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,_GetWorkspaceTagsFilename());
      _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);*/
      _macro('M',was_recording);
      _macro_call('workspace_insert',filename);

      _RecursiveAddDependencies(filename);
   }
   status=_WorkspaceSave(gWorkspaceHandle);
   if (status) {
      return(status);
   }

   if (RetagWorkspaceFiles) {
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, false, false, false, useThread);
   }
   int ProjectsNode=_WorkspaceGet_ProjectsNode(gWorkspaceHandle);
   if (ProjectsNode>=0) {
      _xmlcfg_sort_on_attribute(gWorkspaceHandle,ProjectsNode,'File','2');
   }
   _WorkspaceSave(gWorkspaceHandle);

   if (get_extension(firstFilename,true) == PRJ_FILE_EXT) {
      workspace_set_active(firstFilename);
   }
   toolbarUpdateWorkspaceList();
   call_list('_prjupdate_');
   return(0);
}


_command int workspace_insert_associated(_str filename='',/*_str Dependency='',*/boolean quiet=false,
                                         boolean AllowEmptyFiles=false,
                                         boolean RetagWorkspaceFiles=true)
{
   if (!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
      _message_box('This feature is not supported for the current workspace');
      return(1);
   }

   int was_recording=_macro();
   _macro_delete_line();
   if (_workspace_filename=='') {
      _message_box(nls('No workspace open'));
      return(1);
   }

   // remember the associated type of this workspace.  empty implies no association
   _str associationType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);

   if (filename=='') {
      _str format_list='Project Files(*'PRJ_FILE_EXT')';
      _str defaultExt = '*' PRJ_FILE_EXT;

      // if this is a jbuilder associated workspace, only allow jbuilder projects
      if (associationType == JBUILDER_VENDOR_NAME) {
         format_list='JBuilder Project Files(*'JBUILDER_PROJECT_EXT')';
         defaultExt = '*' JBUILDER_PROJECT_EXT;
      }

      filename=_OpenDialog('-new -mdi -modal',
                           'Add Project to Associated Workspace',
                           '',     // Initial wildcards
                           format_list,  // file types
                           OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT,
                           defaultExt,      // Default extensions
                           '',      // Initial filename
                           '',      // Initial directory
                           '',      // Reserved
                           ''
                          );
      if (filename=='') {
         return(COMMAND_CANCELLED_RC);
      }
   } else {
      // if a single filename was passed in, make sure the filename is quoted
      // so parse_file performs properly
      filename = maybe_quote_filename(filename);
   }
   _str filenameList = filename;
   _str firstFilename='';
   for (;;) {
      // parse the list of filenames
      filename = parse_file(filenameList, false);
      if (firstFilename=='') {
         firstFilename=filename;
      }
      if (filename == "") break;

      // validate the project file
      if (associationType == JBUILDER_VENDOR_NAME) {
         // only allow jpx projects
         if (!file_eq(_get_extension(filename, true), JBUILDER_PROJECT_EXT)) {
            if (!quiet) {
               _message_box(nls("The project '%s' is not a valid JBuilder project.", _strip_filename(filename, "P")));
            }
            return INVALID_ARGUMENT_RC;
         }

         // call workspace associate to force the associated vpj to get created
         vendorWorkspaceName := _AbsoluteToWorkspace(filename);
         _WorkspaceAssociate(vendorWorkspaceName, true);

         // make sure the new vpj gets into the vpw
         _str vseProjectName = VSEProjectFilename(filename);
         if (!file_exists(vseProjectName)) {
            if (!quiet) {
               _message_box(nls("The attempt to associate the project '%s' failed.", _strip_filename(filename, "P")));
            }
            return ERROR_OPENING_FILE_RC;
         }

         int wksProjectsNode = _WorkspaceGet_ProjectsNode(gWorkspaceHandle);
         if (wksProjectsNode < 0) {
            // add it
            wksProjectsNode = _xmlcfg_set_path(gWorkspaceHandle, VPWX_PROJECTS);
         }

         int projectNode = _xmlcfg_find_simple(gWorkspaceHandle, VPWX_PROJECT XPATH_FILEEQ("File", _NormalizeFile(_RelativeToWorkspace(vseProjectName))));
         if (projectNode < 0 && wksProjectsNode >= 0) {
            // add it
            projectNode = _xmlcfg_add(gWorkspaceHandle, wksProjectsNode, VPWTAG_PROJECT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(gWorkspaceHandle, projectNode, "File", _NormalizeFile(_RelativeToWorkspace(vseProjectName)));
         }

         _macro('M',was_recording);
         _macro_call('workspace_insert',filename);

      } else {
         // unsupported type
         if (!quiet) {
            _message_box(nls("The project '%s' is not a supported project type.", _strip_filename(filename, "P")));
         }
         return INVALID_ARGUMENT_RC;
      }
   }

   int status=_WorkspaceSave(gWorkspaceHandle);
   if (status) {
      return(status);
   }
   if (RetagWorkspaceFiles) {
      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, false, false, false, useThread);
   }
   int ProjectsNode=_WorkspaceGet_ProjectsNode(gWorkspaceHandle);
   if (ProjectsNode>=0) {
      _xmlcfg_sort_on_attribute(gWorkspaceHandle,ProjectsNode,'File','2');
   }
   _WorkspaceSave(gWorkspaceHandle);

   workspace_set_active(firstFilename);
   toolbarUpdateWorkspaceList();
   return(0);
}

//9:40am 7/19/1999
//RelFilename comes in with quotes on it.  This gives us a little more
//flexibility when we are searching.
static void RemoveDependenciesFromHashTab(_str RelFilename,_str (&Dependencies):[])
{
   _str DelList[];
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._varformat()==VF_EMPTY) {
         break;
      }
      if (file_eq(RelFilename,i)) {
         DelList[DelList._length()]=i;
      }
   }
   for (i=0;i<DelList._length();++i) {
      Dependencies._deleteel(DelList[i]);
   }

   DelList._makeempty();
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._varformat()==VF_EMPTY) {
         break;
      }
      if (Dependencies._indexin(i)) {
         _str line=Dependencies:[i];
         int p=pos(always_quote_filename(RelFilename),line);
         if (p) {
            _str oldline=line;
            line=substr(oldline,1,p-1);
            line=line:+substr(oldline,p+length(always_quote_filename(RelFilename)));
            line=strip(line);
            if (strip(last_char(line))=='') {
               DelList[DelList._length()]=i;
            } else {
               Dependencies:[i]=line;
            }
         }
      }
   }
   for (i=0;i<DelList._length();++i) {
      Dependencies._deleteel(DelList[i]);
   }
}

/**
 * Removes Filename from the workspace.  If NewActiveProject
 * is specified, it is set active.
 *
 * @param Filename Filename to remove from the workspace
 *
 * @param NewActiveProject
 *                 Project to activate
 *
 * @return Returns 0 if successful
 */
_command int workspace_remove(_str Filename='',_str NewActiveProject='',boolean doUpdateToolbarWorkspaceList=true) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
      _message_box('This feature is not supported for this workspace');
      return(1);
   }

   int was_recording=_macro();
   _macro_delete_line();
   if (_workspace_filename=='') {
      _message_box(nls('No workspace open'));
      return(1);
   }
   if (Filename=='') {
      _message_box(nls('You must specify a file to remove'));
      return(FILE_NOT_FOUND_RC);
   }

   // if this is an associated workspace, make sure that the project filename that
   // was passed in is a vpj
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      if (!_IsVSEProjectFilename(Filename)) {
         Filename = VSEProjectFilename(Filename);
      }
   }

   int status=_WorkspaceRemove_ProjectFile(gWorkspaceHandle,_RelativeToWorkspace(Filename));
   if (status) {
      _message_box(nls("The file '%s' is not in this workspace.",Filename));
      return(1);
   }
   _WorkspaceSave(gWorkspaceHandle);

   _str ProjectFileList[]=null;
   _GetWorkspaceFiles(_workspace_filename,ProjectFileList);


   if (file_eq(_AbsoluteToWorkspace(Filename),_project_name)) {
      if (NewActiveProject!='') {
         workspace_set_active(NewActiveProject,true);
      } else if (!ProjectFileList._length()) {
         workspace_set_active("",true,true);
      } else {
         workspace_set_active(ProjectFileList[0],true);
      }
   }

   _str TagFilename=_GetWorkspaceTagsFilename();
   if (doUpdateToolbarWorkspaceList) {
      toolbarUpdateWorkspaceList();
   }
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   _workspace_update_files_retag(false,true,true,useThread,false,false,useThread);

   _TagCallList(TAGFILE_MODIFIED_CALLBACK_PREFIX,TagFilename);
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   call_list('_prjupdate_');
   _macro('M',was_recording);
   _macro_call('workspace_remove',Filename);
   return(0);
}

//4:35pm 7/6/1999
//Moved this from project.e

/**
 * Closes all editor windows.
 * 
 * @param closeCurrent  whether to close the current window - 
 *                      can use this to close all windows but
 *                      current window.
 * 
 * @return              0 if successful, error otherwise
 */
int _close_all2(boolean closeCurrent = true)
{
   /* If leaves '.process' buffer up if def_auto_restore&RF_PROCESS */
   _project_disable_auto_build(true);
   int status=list_modified(nls("Save Changes Before Closing"),true, !closeCurrent);
   _project_disable_auto_build(false);
   if (status) {
      return(status);
   }
   if (!p_mdi_child || (p_window_flags &HIDE_WINDOW_OVERLAP)) {
      p_window_id=_mdi.p_child;
   }

   // if we are closing only all the other buffers - leave this one open.
   current := -1;  // 0 is a valid buffer id
   if (!closeCurrent) {
      current = p_buf_id;
      // start by calling _prev_buffer - otherwise when we close a buffer, we'll keep going 
      // back to the "current" one
      _prev_buffer();
   }

   int old_def_actapp = def_actapp;
   def_actapp &= ~ACTAPP_AUTORELOADON;
   for (;;) {
      if (p_buf_id == current) {
         _next_buffer();
         // if the next buffer is also the current buffer, then we know we're down to one, so let's stop
         if (p_buf_id == current) status = 1;
         else continue;
      } else if (p_modify) {
         p_modify=0;
      }
      _project_disable_auto_build(true);
      if (!status) status=close_buffer(true);
      _project_disable_auto_build(false);
      if (status) break;
   }
   def_actapp = old_def_actapp;

   // make sure and activate the remaining file
   if (current>=0) {
      edit('+Q +BI 'current, EDIT_DEFAULT_FLAGS|EDIT_NOEXITSCROLL);
   }
   
   return (0);
}

int _OnUpdate_workspace_properties(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
/**
 * Allows you to add projects to a workspace, change project 
 * dependencies, and set the active project.  Displays Workspace 
 * Properties dialog box
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
_command void workspace_properties() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   _macro_delete_line();
   show('-modal _workspace_properties_form');
}
int _OnUpdate_workspace_close(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

int _workspace_save_state()
{
   if (_workspace_filename=='') {
      return(0);
   }

   toolbarSaveExpansion();
   int state_view_id=0;
   int orig_view_id=_create_temp_view(state_view_id);
   p_window_id=orig_view_id;
   save_window_config(true,state_view_id,false,_strip_filename(_workspace_filename,'N'));
   p_window_id=orig_view_id;
   int status=_ini_put_section(VSEWorkspaceStateFilename(_workspace_filename),"State",state_view_id);
   if (status) {
      clear_message();
   }
   return(status);
}
/**
 * Prompts to save modified files, save workspace auto-restore 
 * information, and closes all files.
 * 
 * @return Returns 0 if command not cancelled because user selected to cancel 
 * when prompted with modified file list.  Otherwise a non-zero value is 
 * returned.
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
 * @see workspace_organize
 * 
 * @categories Project_Functions
 * 
 */ 
_command int workspace_close() name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (_workspace_filename=='') {
      if (!isVisualStudioPlugin()) {
         _message_box(nls('No workspace open'));
      }
      return(FILE_NOT_FOUND_RC);
   }
   if (_DebugMaybeTerminate()) {
      return(1);
   }
   _in_workspace_close=true;
   int status=_workspace_save_state();
   int result=0;

   if (status) {
      result=_message_box(nls("Could not save workspace state information to file %s1.\n\n%s2\n\nClose anyway?",VSEWorkspaceStateFilename(_workspace_filename),get_message(status)),'',MB_YESNOCANCEL);
      if (result==IDYES) {
         status=0;
      } else {
         _in_workspace_close=false;
         return(status);
      }
   }
   if (def_restore_flags & RF_PROJECTFILES) {
      status=_close_all2();
      if (status) {
         _in_workspace_close=false;
         return(1);
      }
   }
   tag_close_db(_strip_filename(_workspace_filename,'E'):+TAG_FILE_EXT);

   workspace_close_project();
   if (gWorkspaceHandle>=0) {
      _xmlcfg_close(gWorkspaceHandle);
      _ProjectCache_Update();
   }
   _workspace_filename='';
   if (gWorkspaceHandle>=0) {
      _xmlcfg_close(gWorkspaceHandle);
      gWorkspaceHandle= -1;
   }
   _project_name='';
   gActiveConfigName='';
   gActiveTargetDestination='';
   _project_extTagFiles = '';
   _project_extExtensions = '';
   if (_project_DebugCallbackName!='') {
      _project_DebugCallbackName='';
      _DebugUpdateMenu();
   } else {
      _project_DebugCallbackName='';
   }
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);

   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);
   toolbarUpdateWorkspaceList();
   _toolbar_update_project_list();
   call_list('_wkspace_close_');
   call_list('_prjconfig_');  // Active config changed
   _in_workspace_close=false;
   return(0);
}

#if 0
/**
 * This function does a full recursion on the tree and stores 
 * the expanded state for each node.  This is necessary because 
 * we may have nested folder that we need to store the state of.
 */
static void _GetProjTreeStates2(_str (&array)[],int index,_str indent)
{
   int state=0;
   _str lineText = '';
   index=_TreeGetFirstChildIndex(index);
   _str WorkspacePath = strip_filename(_workspace_filename,'N');
   for (;index>=0;) {
      _TreeGetInfo(index,state);
      if (state>-1) {
         _str WholeName='';
         _str caption = _TreeGetCaption(index);
         parse caption with "\t" WholeName;
         // sometimes, the line will contain a non-file name, you can tell because there's no
         // \t delimiter seperating the file name from the relative path.  If this is
         // the case, then just use the caption of the indexed tree node
         if (WholeName != '') {
            lineText = (indent:+((state)?'-':'+'):+'@':+' ':+relative(WholeName, WorkspacePath));
         } else {
            lineText = (indent:+((state)?'-':'+'):+' ':+caption);
         } 
         array[array._length()]=lineText;
         _GetProjTreeStates2(array,index,indent'  ');
      }
      index=_TreeGetNextSiblingIndex(index);
   }
} 
#endif  

/**  
 * Non-recursive traversal of tree
 */
static void _GetProjTreeStates2(_str (&array)[], int parentIndex)
{
   int index = _TreeGetFirstChildIndex(parentIndex);
   _str WorkspacePath = _strip_filename(_workspace_filename, 'N');
   int curIndex[];
   int depth = 0;
   int state = 0;
   _str indent = '';
   _str lineText = '';

   while (index >= 0) {
      _TreeGetInfo(index, state);
      if (state > -1) {
         _str WholeName='';
         _str caption = _TreeGetCaption(index);
         parse caption with "\t" WholeName;
         // sometimes, the line will contain a non-file name, you can tell because there's no
         // \t delimiter seperating the file name from the relative path.  If this is
         // the case, then just use the caption of the indexed tree node
         if (WholeName != '') {
            lineText = (indent:+((state)?'-':'+'):+'@':+' ':+relative(WholeName, WorkspacePath));
         } else {
            lineText = (indent:+((state)?'-':'+'):+' ':+caption);
         } 
         array[array._length()] = lineText;
      }

      int child = _TreeGetFirstChildIndex(index);
      if (child >= 0) {
         curIndex[depth] = index;
         ++depth;
         index = child;
         indent = substr('', 1, depth*2, ' ');
         continue;
      }
      index = _TreeGetNextSiblingIndex(index);
      while (index < 0 && depth > 0) {
         --depth;
         index = _TreeGetNextSiblingIndex(curIndex[depth]);
         indent = substr('', 1, depth*2, ' ');
      }
   }
}

/**
 * Call this to get the workspace index in the tree. Since we
 * used to safely use TREE_ROOT_INDEX, this will insert the item
 * if necessary.
 *
 * @return int Index of workspace item in projects toolwindow
 */
static int getWorkspaceTreeIndex(_str WorkspaceName="")
{
   childIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if ( childIndex<0 ) {
      // Be sure to set TREE_NODE_EXPANDED flag so that the workspace filename
      // does not get clipped
      childIndex = _TreeAddItem(TREE_ROOT_INDEX,WorkspaceName,TREE_ADD_AS_CHILD,0,0,TREE_NODE_EXPANDED,TREENODE_FIRSTCOLUMNSPANS);
   }
   return childIndex;
}

void _GetProjTreeStates(_str (&array)[])
{
   // cll the recursive version of this function to traverse the project tree
   array._makeempty();
   //_GetProjTreeStates2(array, getWorkspaceIndex(), '');
   _GetProjTreeStates2(array, getWorkspaceTreeIndex());
   // store the scroll location
   array[array._length()]='scroll:'_TreeScroll();
}

#define TREE_WORKSPACE_DEPTH 1
#define TREE_PROJECT_DEPTH   2

/**
 * An item is a workspace item if it is not parented up the 
 * branch by a project,in other words, the file does not belong 
 * to a project. 
 * 
 * @return true if it is a workspace item, false if not
 */
boolean _projecttbIsWorkspaceItemNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   // walk up the parent line checking to see if each is a project.
   // if a project is found, then the item is not a workspace item
   while ((index >= 0) && (_TreeGetDepth(index) > TREE_WORKSPACE_DEPTH)) {
      if (_projecttbIsProjectNode(index) == true) {
         return false;
      }
      index=_TreeGetParentIndex(index);
   }
   // if we got here, then it has no project parent and it is a workspace item
   return true;
}

boolean _projecttbIsProjectFolderNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   // is the current node a folder node?
   boolean isFolderNode = _projecttbIsFolderNode(index);
   if (isFolderNode == true) {
      // walk up the parent line checking to see if each is a project.
      // if a project is found, then the item is not a project folder
      while ((index >= 0) && (_TreeGetDepth(index) > TREE_WORKSPACE_DEPTH)) {
         if (_projecttbIsProjectNode(index) == true) {
            return true;
         }
         index=_TreeGetParentIndex(index);
      }
   }

   // if we got here, then it has no project parent and it is not a 
   // project folder node
   return false;
}

boolean _projecttbIsWorkspaceFileNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   if (!_projecttbIsWorkspaceItemNode(index)) {
      return false;
   }
   int showchildren;
   int bm1;
   int bm2NOLONGERUSED;
   int more;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);

   return(bm1!=_pic_tfldclos&&bm1!=_pic_tfldclosdisabled&&bm1!=_pic_tpkgclos&&showchildren<0);
}
boolean _projecttbIsWorkspaceFolderNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   if (!_projecttbIsWorkspaceItemNode(index)) {
      return false;
   }
   int showchildren;
   int bm1;
   int bm2NOLONGERUSED;
   int more;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);

   return((bm1==_pic_tfldclos || bm1==_pic_tfldclosdisabled || bm1==_pic_tpkgclos) && showchildren>=0);
}
boolean _projecttbIsProjectFileNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   int showchildren=0,bm1=0,bm2NOLONGERUSED=0,more=0;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);
   return(bm1!=_pic_project && // Don't want dependencies
          showchildren<0 &&
          _TreeGetDepth(index)>TREE_WORKSPACE_DEPTH);
}
boolean _projecttbIsAntBuildFileNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   _str name, fullpath;
   parse _TreeGetCaption(index) with name "\t" fullpath;
   if (_IsAntBuildFile(fullpath)) {
      return true;
   }

   return false;
}
boolean _projecttbIsNAntBuildFileNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   _str name, fullpath;
   parse _TreeGetCaption(index) with name "\t" fullpath;
   if (_IsNAntBuildFile(fullpath)) {
      return true;
   }

   return false;
}
boolean _projecttbIsMakefileNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   _str name, fullpath;
   parse _TreeGetCaption(index) with name "\t" fullpath;
   if (_IsMakefile(fullpath)) {
      return true;
   }

   return false;
}
boolean _projecttbIsProjectNode(int index=-1,boolean allowDependentProjects=true)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   if (allowDependentProjects) {
      /*parse _TreeGetCaption(index) with name "\t" path;

      if (!file_eq(get_extension(name,true),PRJ_FILE_EXT)) {
         return(false);
      } */
      int showchildren=0,bm1=0,bm2NOLONGERUSED=0,more=0;
      _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);
      return(bm1==_pic_project /*&& showchildren>=0 */);
   }
   return(_TreeGetDepth(index)==TREE_PROJECT_DEPTH);
}
boolean _projecttbIsDependencyNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   int showchildren=0,bm1=0,bm2NOLONGERUSED=0,more=0;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);
   return(bm1==_pic_project /*&& showchildren>=0 */ && _TreeGetDepth(index)>TREE_PROJECT_DEPTH);
}
boolean _projecttbIsWorkspaceNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   int Depth=_TreeGetDepth(index);
   return(Depth==TREE_WORKSPACE_DEPTH);
}
boolean _projecttbIsFolderNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   int showchildren=0,bm1=0,bm2NOLONGERUSED=0,more=0;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);

   return((bm1==_pic_tfldclos || bm1==_pic_tfldclosdisabled || bm1==_pic_tpkgclos) && showchildren>=0);
}
boolean _projecttbIsPackageNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }
   int showchildren=0,bm1=0,bm2NOLONGERUSED=0,more=0;
   _TreeGetInfo(index,showchildren,bm1,bm2NOLONGERUSED,more);

   return((bm1==_pic_tpkgclos) && showchildren>=0);   
}
boolean _projecttbIsWildcardFolderNode(int index=-1)
{
   if (index<0) {
      index=_TreeCurIndex();
   }

   _str projectName = _projecttbTreeGetCurProjectName(index);
   int handle=_ProjectHandle(projectName);
   if (_ProjectIs_SupportedXMLVariation(handle)) {
      handle=_ProjectGet_AssociatedHandle(handle);
   }

   // wildcard folders only currently used for jbuilder support
   if (file_eq(_get_extension(_xmlcfg_get_filename(handle), true), JBUILDER_PROJECT_EXT)) {
      // check the type attribute of the folder
      _str folderName = _TreeGetCaption(index);
      int folderNode = _ProjectGet_FolderNode(handle, folderName);
      if (folderNode >= 0) {
         _str folderType = _xmlcfg_get_attribute(handle, folderNode, "type");
         if (strieq(folderType, "NavigationDirectory")) {
            return true;
         }
      }
   }

   return false;
}

#if 0
// DJB 05/26/2011
// AllDependencies is used to cache project dependencies workspace-wide
// so that we do not have to reparse the solution file with Visual Studio
// projects for every single project.
//
static void _RestoreProjTreeStatesVS(_str (&array)[], _str (*AllDependencies):[]=null)
{
   // this is a hash table, where the hash key is the number of spaces
   // that the items for that level are indented
   int curParentIndexByIndent:[];
   curParentIndexByIndent:[0] = getWorkspaceIndex();

   int curLineIndex = 0;
   // traverse the array
   for (curLineIndex = 0; curLineIndex < (array._length() - 1); curLineIndex++) {
      // get the indent on the current line
      int curIndent = pos('[~ ]',array[curLineIndex],1,'r');
      int nextIndent = pos('[~ ]',array[curLineIndex + 1],1,'r');
      // check to see if we've indented in a level
      if (nextIndent <= curIndent) {
         continue;
      } 
      // get the parent node index in the tree for this nesting level
      int treeParentIndex = getWorkspaceIndex();
      if (curParentIndexByIndent._indexin(curIndent)) {
         treeParentIndex = curParentIndexByIndent:[curIndent];
      } else {
         curParentIndexByIndent:[curIndent] = getWorkspaceIndex();
      }
      // parse the current state line
      _str stateLine = strip(array[curLineIndex]);
      _str ch = '';
      _str stateItem = '';
      parse stateLine with ch' 'stateItem;
      _str captionToFind = stateItem;
      // first, try to find it normally
      int treeIndex = _TreeSearch(treeParentIndex, captionToFind, _fpos_case);
      // if we couldn't find it, then it's probably a file name, so construct the proper
      // caption to look for in the project tree
      if (treeIndex < 0) {
         _str fileName = _AbsoluteToWorkspace(stateItem);
         _str nameOnly = strip_filename(fileName,'P');
         // remove any trailing file seperater character
         if (last_char(fileName) == FILESEP) {
            fileName = strip_filename(substr(fileName,1,length(fileName)-1),'P');
         }
         // build the caption to find
         captionToFind = nameOnly"\t"fileName;
         // find the project in the tree
         treeIndex = _TreeSearch(treeParentIndex, captionToFind, _fpos_case);
         // see if we have a project node here, we may need to build it dynamically
         if ((treeIndex >= 0) && (_TreeGetFirstChildIndex(treeIndex) < 0)) {
            toolbarBuildFilterList(_projecttbTreeGetCurProjectName(treeIndex), treeIndex, AllDependencies);
         }
      }
      // set the expansion level
      if (treeIndex >= 0) {
         // set the next tree indent parent index
         curParentIndexByIndent:[nextIndent] = treeIndex;
         // set the expanded state
         if (ch == '-') {
            _TreeSetInfo(treeIndex, 1);
         } else {
            _TreeSetInfo(treeIndex, 0);
         }
      }
   }
}

static void _RestoreProjTreeStates2(int ParentIndex,_str (&array)[],int &i,int indent)
{
   int index=_TreeGetFirstChildIndex(ParentIndex);
   for (++i;;++i) {
      if (i>=array._length()) {
         return;
      }
      int p=pos('[~ ]',array[i],1,'r');
      if (p<indent) {
         --i;
         return;
      }
      _str ch='',FolderName='';
      parse strip(array[i]) with ch' 'FolderName;
      if (index<0 || !strieq(_TreeGetCaption(index),FolderName)) {
         index=_TreeSearch(ParentIndex,FolderName,'i');
      }
      if (index>=0) {
         if (ch=='-' && _projecttbIsFolderNode(index)) {
            _TreeSetInfo(index,1);
         }
         _RestoreProjTreeStates2(index,array,i,indent+2);
         index=_TreeGetNextSiblingIndex(index);
      } else {
         for (++i;i<array._length();++i) {
            p=pos('[~ ]',array[i],1,'r');
            if (p<=indent) {
               --i;
               break;
            }
         }
      }
   }
}
#endif

// LB 2011-06-17 
// One code path for restoring project tree state, handles projects nested in workspace folders
// Replaced recursive version with this one.
// adds more complexity but profiled to be much much faster
static void _RestoreProjTreeStates2(_str (&array)[], _str (*AllDependencies):[]=null)
{
   int index = _TreeGetFirstChildIndex(getWorkspaceTreeIndex());
   int parentIndex = getWorkspaceTreeIndex();
   int prevIndex[];
   int prevParent[];
   int depth = 0;
   int indent = 1;
   int i;

   for (i = 0; i < array._length(); ++i) {
      int p = pos('[~ ]', array[i], 1, 'r');
      if (p > indent) {
         continue;
      }

      _str ch='', name='';
      parse strip(array[i]) with ch' 'name;
      if (substr(ch,2,1) == '@') {
         ch = substr(ch,1,1);

         name = _AbsoluteToWorkspace(name);
         _str projectName = _strip_filename(name,'P');
         if (last_char(name) == FILESEP) {
            projectName = _strip_filename(substr(name,1,length(name)-1),'P');
         }
         if (index < 0 || !file_eq(_TreeGetCaption(index), projectName"\t"name)) {
            index = _TreeSearch(parentIndex, projectName"\t"name, _fpos_case);
         }

         if (index >= 0) {
            if (ch == '-' && _projecttbIsProjectNode(index)) {
               _TreeSetInfo(index, 1);
               // Always call toolbarBuildFilterList
               toolbarBuildFilterList(_projecttbTreeGetCurProjectName(index), index, AllDependencies);
            }
         }

      } else {
         if (index < 0 || !strieq(_TreeGetCaption(index), name)) {
            index = _TreeSearch(parentIndex, name, 'i');
         }

         if (index >= 0) {
            if (ch=='-' && _projecttbIsFolderNode(index)) {
               _TreeSetInfo(index, 1);
            }
         }
      }

      boolean skipChild = false;
      if (index < 0) { // not found
         for (; i < array._length(); ++i) {
            p = pos('[~ ]', array[i], 1, 'r');
            if (p <= indent) {
               --i;
               break;
            }
         }

         if (depth > 0) {
            --depth; indent -= 2;
            index = prevIndex[depth];
            parentIndex = prevParent[depth];
         }
         skipChild = true;
      }

      if (!skipChild && index >= 0) {
         int child = _TreeGetFirstChildIndex(index);
         if (child >= 0) {
            prevIndex[depth] = index;
            prevParent[depth] = parentIndex;
            ++depth; indent += 2;
            parentIndex = index;
            index = child;
            continue;
         }
      }

      if (index >= 0) {
         index = _TreeGetNextSiblingIndex(index);
         while (index < 0 && depth > 0) {
            --depth; indent -= 2;
            parentIndex = prevParent[depth];
            index = _TreeGetNextSiblingIndex(prevIndex[depth]);
         }
      }

      if (index < 0 || indent < 1) {
         break;
      }
   }
   _TreeSizeColumnToContents(0);
}

// DJB 05/26/2011
// AllDependencies is used to cache project dependencies workspace-wide
// so that we do not have to reparse the solution file with Visual Studio
// projects for every single project.
//
void _RestoreProjTreeStates(_str (&array)[], _str (*AllDependencies):[]=null)
{
   // The last element in the array is the scroll position. Get that out of the
   // array, and then delete it.
   _str scroll_pos='';
   int scroll_pos_index=array._length()-1;
   parse array[scroll_pos_index] with 'scroll:' scroll_pos .;
   array._deleteel(scroll_pos_index);
   _RestoreProjTreeStates2(array, AllDependencies);
   if (scroll_pos!='') {
      typeless newsp=_TreeScroll((int)scroll_pos);
      _TreeRefresh();
   }
}


void AddTreeSolutionItems(_str filters[], _str options, _str exclude[])
{
   // Find all files in tree:
   mou_hour_glass(1);
   message('SlickEdit is finding all files in tree');

   int formwid=p_active_form;

   int filelist_view_id;
   int orig_view_id=_create_temp_view(filelist_view_id);

   if (orig_view_id:=='') {
      mou_hour_glass(0);
      clear_message();
      return;
   }

   _str all_files='';
   _str filename;
   int file_index;
   for (file_index=0;file_index<filters._length();++file_index) {
      filename=maybe_quote_filename(strip(absolute(filters[file_index]),'B','"'));
      strappend(all_files,' 'filename);
   }
   if (exclude._length() > 0) {
      all_files=all_files' -exclude';
      for (file_index = 0; file_index < exclude._length(); ++file_index) {
         _str file = maybe_quote_filename(strip(exclude[file_index], 'B', '"'));
         strappend(all_files,' 'filename);
      }
   }
   // +W option supports multiple file specs but must specify switches
   // before files when you use this option.
   insert_file_list(options' +W +L -v +p -d 'all_files);

   _str new_file_list[];
   all_files='';

   // get all the files from the temp view and into both a single string and
   // an array
   top();up();
   while (!down()) {
      get_line(filename);
      filename=strip(filename);
      if (filename=='') break;
      if (_DataSetIsFile(filename)) {
         filename=upcase(filename);
      }
      strappend(all_files,' ':+maybe_quote_filename(filename));
      new_file_list[new_file_list._length()]=filename;
   }

   _delete_temp_view(filelist_view_id);
   activate_window(orig_view_id);

   AddSolutionItems(all_files);
   _AddAndRemoveFilesFromVC(new_file_list,null);

   mou_hour_glass(0);
   clear_message();
}



static void InsertCurrentWorkspaceNames(_str WorkspaceName=_workspace_filename,
                                        boolean CallUpdateFilter=true,int formid=-1,
                                        int initialNodeState=0,int workspaceIndex=TREE_ROOT_INDEX)
{
   // DJB 05/26/2011
   // AllDependencies is used to cache project dependencies workspace-wide
   // so that we do not have to reparse the solution file with Visual Studio
   // projects for every single project.
   _str AllDependencies:[];
   AllDependencies._makeempty();

   _str Files[];
   Files._makeempty();
   _GetWorkspaceFiles(_workspace_filename,Files);
   _str ProjectName=GetProjectDisplayName(_project_name);
   int i;
   workspaceDir:=_GetWorkspaceDir();
   for (i=0;i<Files._length();++i) {
      _str curfile=GetProjectDisplayName(absolute(Files[i],workspaceDir));
      //cap=strip_filename(curfile,'P')"\t"relative(curfile,_GetWorkspaceDir());
      _str justfile=_strip_filename(curfile,'P');
      if (justfile=='') {
         justfile=_GetLastDirName(curfile);
      }
      _str cap=justfile"\t"curfile;
      boolean IsCurProject=file_eq(_AbsoluteToWorkspace(curfile),ProjectName);
      int NodeFlags=0;
      if (IsCurProject) {
         NodeFlags|=TREENODE_BOLD;
      }
      int sortflag=0;
      if (lowcase(_fpos_case)=='i') {
         sortflag=TREE_ADD_SORTED_CI;
      } else {
         sortflag=TREE_ADD_SORTED_CS;
      }
      int curindex=_TreeAddItem(workspaceIndex,
                                cap,
                                TREE_ADD_AS_CHILD|sortflag,
                                _pic_project,
                                _pic_project,
                                initialNodeState,
                                NodeFlags);
      if (CallUpdateFilter) {
         toolbarUpdateFilterList(_AbsoluteToWorkspace(Files[i]),curindex,formid,&AllDependencies);
      }
   }
}

int toolbarUpdateWorkspaceList(int formid=-1,
                               _str FormName='_tbprojects_form',
                               _str ControlName='_proj_tooltab_tree')
{
   _toolbar_update_project_list();

   _str States[];
   int oriWindowId = p_window_id;

   if (formid<0) {
      formid = _find_object(FormName,"N");
      if (!formid) {
         p_window_id = oriWindowId;
         return(0);
      }
   }

   int controlid=_find_object(FormName'.'ControlName);
   if (!controlid) {
      p_window_id=oriWindowId;
      return(0);
   }

   p_window_id=controlid.p_window_id;

   workspaceIndex := getWorkspaceTreeIndex(_workspace_filename);
   typeless p;
   _TreeSavePos(p);
   _GetProjTreeStates(States);
   if (_workspace_filename=='') {
      _TreeSetCaption(workspaceIndex,"No workspace open");
      _TreeDelete(workspaceIndex,'C');
      p_window_id=oriWindowId;
      return(1);
   }
   _TreeSetCaption(workspaceIndex,_workspace_filename);
   _TreeSetInfo(workspaceIndex,1,_pic_workspace,_pic_workspace);
   _TreeBeginUpdate(workspaceIndex);

   InsertCurrentWorkspaceNames(_workspace_filename,false,formid,0,workspaceIndex);
   InsertOtherWorkspaceFiles(_workspace_filename);
   _TreeEndUpdate(workspaceIndex);

   // DJB 05/26/2011
   // AllDependencies is used to cache project dependencies workspace-wide
   // so that we do not have to reparse the solution file with Visual Studio
   // projects for every single project.
   _str AllDependencies:[];
   AllDependencies._makeempty();
   // This fills in the project files (eventually)
   _RestoreProjTreeStates(States, &AllDependencies);
   _TreeRestorePos(p);
   p_window_id=oriWindowId;
   return(0);
}
int toolbarUpdateActiveProject()
{
   int States:[];
   int oriWindowId = p_window_id;

   _toolbar_update_project_list();
   int formid = _find_object('_tbprojects_form',"N");
   if (!formid) {
      p_window_id = oriWindowId;
      return(0);
   }
   _nocheck _control _proj_tooltab_tree;
   //p_window_id = formid._proj_tooltab_tree.p_window_id;
   p_window_id=formid._proj_tooltab_tree.p_window_id;

   // Build a name to search with, start with display name
   _str dispName=GetProjectDisplayName(_project_name);

   // Add tabs to match the tree format
   _str searchName='';
   searchName=_strip_filename(dispName,'P')"\t"dispName;
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      searchName=_GetLastDirName(dispName)"\t"dispName;
   }

   // search recursively
   workspaceIndex  := getWorkspaceTreeIndex(_workspace_filename);
   newProjectIndex := _TreeSearch(getWorkspaceTreeIndex(),searchName,_fpos_case'T');
   MakeActiveProjectBold(newProjectIndex, workspaceIndex);

   p_window_id=oriWindowId;
   return(0);
}

static void MakeActiveProjectBold(int activeProjectTreeIndex, int index)
{
   int state=0,bm1=0,bm2NOLONGERUSED=0,flags=0;

   // if this is the node we're looking for, make it bold
   _TreeGetInfo(index,state,bm1,bm2NOLONGERUSED,flags);
   if (index == activeProjectTreeIndex) {
      _TreeSetInfo(index,state,bm1,bm2NOLONGERUSED,flags|TREENODE_BOLD);
   } else if (flags&TREENODE_BOLD){
      _TreeSetInfo(index,state,bm1,bm2NOLONGERUSED,flags&~TREENODE_BOLD);
   }
   // keep searching, we have to UNbold everything else
   index = _TreeGetFirstChildIndex(index);
   while (index > 0) {
      MakeActiveProjectBold(activeProjectTreeIndex, index);
      index = _TreeGetNextSiblingIndex(index);
   }
}

int toolbarRestoreState(_str WorkspaceFilename=_workspace_filename)
{
   int oriWindowId = p_window_id;
   int formid = _find_object('_tbprojects_form',"N");
   if (!formid) {
      p_window_id = oriWindowId;
      return(0);
   }
   _nocheck _control _proj_tooltab_tree;

   int orig_view_id=p_window_id;
   int temp_view_id=0;
   _str workspaceStateFileName = VSEWorkspaceStateFilename(_workspace_filename);
   int status=_ini_get_section(workspaceStateFileName,"TreeExpansion2",temp_view_id);
   if (!status) {
      p_window_id=temp_view_id;
      _str array[];
      top();up();
      while (!down()) {
         get_line(auto line);
         if (line!='') {
            array[array._length()]=line;
         }
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);

      // DJB 05/26/2011
      // AllDependencies is used to cache project dependencies workspace-wide
      // so that we do not have to reparse the solution file with Visual Studio
      // projects for every single project.
      _str AllDependencies:[];
      AllDependencies._makeempty();
      p_window_id=formid._proj_tooltab_tree;
      _RestoreProjTreeStates(array, &AllDependencies);

      p_window_id=orig_view_id;
   }
   return(0);
}

int restoreWorkspaceSettings(_str section, _str WorkspaceFilename=_workspace_filename)
{
   // open up the file to find the goodies
   int orig_view_id=p_window_id;
   int temp_view_id=0;
   int status=_ini_get_section(VSEWorkspaceStateFilename(WorkspaceFilename),"State",temp_view_id);
   if (!status) {
      // search for the debug section
      p_window_id=temp_view_id;
      top();up();
      boolean have_section = (search("^"section"\\:", '@rhe') == 0);
      if (have_section) {

         // find the callback to process this section
         name := '_sr_':+lowcase(section);
         index := find_index(name,PROC_TYPE);
         // IF there is a callable function
         if ( index_callable(index)) {
            get_line(auto line);
            parse line with section":" line;
            call_index('N', line, '', _strip_filename(WorkspaceFilename,'N'), index);
         }
      }

      // clean up the temp view
      _delete_temp_view(temp_view_id);
      p_window_id=orig_view_id;
   }
   // that's all
   return(0);
}

#define SET_ACTIVE_CAPTION '&Set Active Project'
#define SET_ACTIVE_CONFIGURATION 'Set Active Configuration'

static void GetBuildRules(_str ProjectName,_str (&Files)[])
{
   ProjectName=GetProjectDisplayName(ProjectName);
   int temp_view_id=0,orig_view_id=0;
   int status=_open_temp_view(ProjectName,temp_view_id,orig_view_id);
   if (!status) {
      for (;;) {
         status=search('^\<BEGIN\> BUILD_RULE_?@$','@rh>');
         if (status) break;
         get_line(auto line);
         _str name;
         parse line with '<BEGIN> BUILD_RULE_'name;
         Files[Files._length()]=strip(name);
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
   //if (!Files._length()) {
   //   Files[0]='archive';
   //   Files[1]='linkedObjs.o';
   //   Files[2]='objects';
   //}
}

void _init_menu_workspace(int menu_handle,int no_child_windows)
{
   int status;
   int project_menu_handle, itempos;
   int active_project_menu_handle=0;
   int mf_flags=0;
   _str caption='';
   _str command='';
   int total=0;
   _str cap1='',cap2='';
   if (_menu_find(menu_handle, "set active project", active_project_menu_handle,
                  itempos, "C")) {
      status=_menu_find(menu_handle, "project-edit", project_menu_handle,
                        itempos, "M");
      if (status) {
         return;
      }
      _menu_get_state(project_menu_handle,itempos-1,mf_flags,"P",caption,command);
      total=_menu_info(project_menu_handle);
      cap1=lowcase(stranslate(caption,'','&'));
      cap2=lowcase(SET_ACTIVE_CAPTION);
      if (cap1!=cap2) {
         // Insert the active project menu item and get its submenu handle.
         status=_menu_insert(project_menu_handle,
                             itempos,
                             MF_SUBMENU,       // flags
                             SET_ACTIVE_CAPTION,  // tool name
                             '',   // command
                             "set active project",    // category
                             "",  // help command
                             'Sets the active project'       // help message
                            );
         if (status<0) {
            return;
         }
         if (_menu_find(menu_handle, "set active project", active_project_menu_handle,
                        itempos, "C")) {
            return;
         }
      }
   }

   // Set the state for active project and active configuration.
   typeless submenu_handle;
   _str categories='';
   _str help_command='';
   _str help_message='';
   _menu_get_state(active_project_menu_handle,itempos,mf_flags,'p',caption,submenu_handle,
                   categories,help_command,help_message);
   if (_workspace_filename=="") {
      _menu_set_state(active_project_menu_handle,itempos,(mf_flags&~MF_ENABLED)|MF_GRAYED,'p',caption,submenu_handle,
                      categories,help_command,help_message);
      initMenuSetActiveConfig(menu_handle,no_child_windows);
      _AddWorkspaceTreeToMenu();
      return;
   } else {
      _menu_set_state(active_project_menu_handle,itempos,(mf_flags&~MF_GRAYED)|MF_ENABLED,'p',caption,submenu_handle,
                      categories,help_command,help_message);
   }
   for (;;) {
      status=_menu_get_state(submenu_handle,0,mf_flags,'p',caption,command,
                             categories,help_command,help_message);
      if (status) {
         break;
      }
      _menu_delete(submenu_handle,0);
   }

   int i;
   int build_menu_handle=0;
   if (_IsTornadoWorkspaceFilename(_workspace_filename) && _project_name!='') {
      _str Rules[];
      Rules._makeempty();
      GetBuildRules(_project_name,Rules);
      status=_menu_find(menu_handle, "project-build", build_menu_handle,
                        itempos, "M");
      if (!status) {
         for (i=0;i<Rules._length();++i) {
            status=_menu_insert(build_menu_handle,
                                itempos+1,
                                MF_ENABLED,       // flags
                                "Build (DEFAULT_RULE="Rules[i]")",  // tool name
                                'tornadomake -f ..\MAKEFILE %b DEFAULT_RULE='Rules[i]' 'Rules[i],   // command
                                "",    // category
                                "",  // help command
                                ''       // help message
                               );
         }
      }
   }
   //status=_ini_get_section(_workspace_filename,"ProjectFiles",project_files_view);
   _str Projects[]=null;
   status=_GetWorkspaceFiles(_workspace_filename,Projects);
   if (status) {
      initMenuSetActiveConfig(menu_handle,no_child_windows);
      _AddWorkspaceTreeToMenu();
      return;
   }
   int menupos=0;
   _str filename='';
   int flags=0;
   if (!Projects._length()) {
      status=_menu_insert(submenu_handle,
                          menupos++,
                          MF_GRAYED,      // flags
                          "No Projects",  // tool name
                          'nothing',      // command
                          "file",         // category
                          "",             // help command
                          ''              // help message
                         );
   } else {
      boolean iseclipse=_IsEclipseWorkspaceFilename(_workspace_filename);

      _str dispNames[];
      _str dispNameToFilename:[];
      for (i = 0; i < Projects._length(); i++) {
         filename = GetProjectDisplayName(Projects[i]);

         // get the name we'll use for display purposes
         dispName := '';
         if (iseclipse) {
            filename=filename:+_GetLastDirName(filename);
            dispName=_GetLastDirName(strip(filename,'B','"'));
         } else {
            dispName = strip(_strip_filename(filename,'P'),'B','"');
         }

         dispNames[i] = dispName;
         dispNameToFilename:[dispName] = filename;
      }

      // sort!
      dispNames._sort('F');

      for (i = 0; i < dispNames._length(); i++) {
         dispName := dispNames[i];
         filename = dispNameToFilename:[dispName];

         // maybe check this menu item if this is the current project
         flags=0;
         if (file_eq(_project_name,VSEProjectFilename(_AbsoluteToWorkspace(filename)))) {
            flags|=MF_CHECKED;
         }

         // we don't add this before, because it screws up the sort
         dispName :+= "\t" :+ strip(filename,'B','"');

         if (iseclipse) {
            filename=filename:+PRJ_FILE_EXT;
         }


         _str CommandFilename=filename;
         status=_menu_insert(submenu_handle,
                             menupos++,
                             flags,                               // flags
                             dispName,                         // tool name
                             'workspace_set_active 'filename,     // command
                             "file",                              // category
                             "",                                  // help command
                             'Sets the named project as active'   // help message
                            );
      }
   }

   // Insert configurations into the active configuration submenu.
   // Turn on the checkbox for the active configuration.
   initMenuSetActiveConfig(menu_handle,no_child_windows);
   _AddWorkspaceTreeToMenu();
}

// Insert the Active Configuration menu item and submenu, if it is
// not already inserted.
void initMenuSetActiveConfig(int menu_handle,int no_child_windows, _str ProjectFilename=_project_name)
{
   // Locate the item handle and submenu handle for active configuration.
   int status;
   int build_menu_handle;
   int active_config_menu_handle, acitempos;
   int itempos=0;
   int nitems=0;
   int mf_flags=0;
   _str caption='';
   _str command='';
   _str cap1='',cap2='';

   initMenuTargetDestinations(menu_handle, ProjectFilename);
   initMenuXcodeWorkspaceSchemes(menu_handle);

   if (_menu_find(menu_handle, "set active configuration", active_config_menu_handle,
                  acitempos, "C")) {
      // Find the Activate Build item.
      status=_menu_find(menu_handle, "start-process", build_menu_handle,
                        itempos, "M");
      if (status) {
         status=_menu_find(menu_handle, "projecttbSetCurProject", build_menu_handle,
                           itempos, "M");
      }
      if (status) {
         return;
      }
      int needInsert = 1;
      nitems=_menu_info(build_menu_handle);
      if (nitems > itempos) {
         needInsert = 0;
         _menu_get_state(build_menu_handle,itempos+1,mf_flags,"P",caption,command);
         cap1=lowcase(stranslate(caption,'','&'));
         cap2=lowcase(SET_ACTIVE_CONFIGURATION);
         if (cap1!=cap2) needInsert = 1;
      }
      if (needInsert) {
         // Insert the active configuration menu item and get its submenu handle.
         status=_menu_insert(build_menu_handle,
                             itempos+1,
                             MF_SUBMENU,       // flags
                             SET_ACTIVE_CONFIGURATION,  // tool name
                             '',   // command
                             "set active configuration",    // category
                             "",  // help command
                             'Sets the active configuration'       // help message
                            );
         if (status<0) return;
         if (_menu_find(menu_handle, "set active configuration", active_config_menu_handle,
                        acitempos, "C")) {
            return;
         }

         // Insert the Configurations... item to bring up Project Properties and
         // activate the Configurations tab.
         status=_menu_insert(build_menu_handle,
                             itempos+2,
                             0,       // flags
                             "Configurations...",  // tool name
                             'project-config',   // bring up Project Configurations dialog
                             "edit project configuration",    // category
                             "help project menu",  // help command
                             'Edit the project configurations'       // help message
                            );
         if (status<0) return;
      }
   }

   // Set the state for active project and active configuration.
   typeless acsubmenu_handle;
   int acmf_flags;
   _str accaption, accommand, accategories, achelp_command, achelp_message;
   _menu_get_state(active_config_menu_handle,acitempos,acmf_flags,'p',accaption,acsubmenu_handle,
                   accategories,achelp_command,achelp_message);
   if (_workspace_filename=="" || _project_name == "") {
      _menu_set_state(active_config_menu_handle,acitempos,(acmf_flags&~MF_ENABLED)|MF_GRAYED,'p',accaption,acsubmenu_handle,
                      accategories,achelp_command,achelp_message);
      return;
   } else {
      _menu_set_state(active_config_menu_handle,acitempos,(acmf_flags&~MF_GRAYED)|MF_ENABLED,'p',accaption,acsubmenu_handle,
                      accategories,achelp_command,achelp_message);
   }

   // Delete all items in the active configuration submenu.
   for (;;) {
      status=_menu_get_state(acsubmenu_handle,0,acmf_flags,'p',accaption,accommand,
                             accategories,achelp_command,achelp_message);
      if (status) {
         break;
      }
      _menu_delete(acsubmenu_handle,0);
   }

   // Get the configurations for the active project.
   ProjectConfig configList[];
   int associated;
   status=getProjectConfigs(ProjectFilename, configList, associated);
   if (status) return;
   if (!configList._length()) {
      status=_menu_insert(acsubmenu_handle,
                          0, // first item
                          MF_GRAYED, // flags
                          "no configuration",  // tool name
                          'project_config_set_active ', // command to do nothing
                          "file",    // category
                          "",  // help command
                          ''       // help message
                         );
      return;
   }

   // Insert configurations into the active configuration submenu.
   // Turn on the checkbox for the active configuration.
   _str activeConfig= GetCurrentConfigName(ProjectFilename);
   int i;
   for (i=0;i<configList._length();++i) {
      _str configName = configList[i].config;
      int flags=0;
      // Put a check on the active configuration menu item. If there
      // is no active conguration, default to the first.
      if ((activeConfig == "" && i == 0) || strieq(configList[i].config,activeConfig)) {
         flags|=MF_CHECKED;
      }
      status=_menu_insert(acsubmenu_handle,
                          i,
                          flags,       // flags
                          configName,  // tool name
                          'project_config_set_active -p 'maybe_quote_filename(ProjectFilename)' 'maybe_quote_filename(configName),   // command
                          "file",    // category
                          "",  // help command
                          ''       // help message
                         );
   }
}

// Get a list of configurations from an associated project file.
// Code courtesy of Shawn M.
// Retn: 0 OK, !0 error status
int _getAssociatedProjectConfigs(_str project_name,ProjectConfig (&configList)[])
{
   // Get the associated makefile, if there is one.
   int status = 0;
   _str associateMakefile = "";
   _str makefiletype = "";
   _str ext;
   if (_IsVSEProjectFilename(project_name)) {
      /*status = _ini_get_value(project_name,"ASSOCIATION","MAKEFILE",associateMakefile);
      if (status) return(status);
      //makefiletype=wind river tornado
      status = _ini_get_value(project_name,"ASSOCIATION","makefiletype",makefiletype);
      if (status) return(status);*/
      status=_GetAssociatedProjectInfo(project_name,associateMakefile,makefiletype);
      if (status && associateMakefile!='') return(status);
      ext=_get_extension(associateMakefile,true);
      if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         associateMakefile = absolute(getICProjAssociatedProjectFile(associateMakefile),_strip_filename(project_name,'N'));
      }
   } else {
      associateMakefile=project_name;
      ext=_get_extension(associateMakefile,true);
      if (file_eq(ext,VCPP_PROJECT_FILE_EXT)) {
         makefiletype=VCPP_VENDOR_NAME;
      } else if (file_eq(ext,TORNADO_PROJECT_EXT)) {
         makefiletype=TORNADO_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_VCPP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         associateMakefile = absolute(getICProjAssociatedProjectFile(associateMakefile),_strip_filename(project_name,'N'));
         makefiletype=VISUAL_STUDIO_VCPP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_VCPP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_CSHARP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_VB_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_JSHARP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_FSHARP_VENDOR_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_TEMPLATE_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_TEMPLATE_NAME;
      } else if (file_eq(ext,VISUAL_STUDIO_DATABASE_PROJECT_EXT)) {
         makefiletype=VISUAL_STUDIO_DATABASE_NAME;
      } else if (file_eq(ext,JBUILDER_PROJECT_EXT)) {
         makefiletype = JBUILDER_VENDOR_NAME;
      } else if (file_eq(ext,XCODE_PROJECT_LONG_BUNDLE_EXT) || file_eq(ext,XCODE_PROJECT_SHORT_BUNDLE_EXT)) {
         makefiletype = XCODE_PROJECT_VENDOR_NAME;
      } else if (file_eq(ext,MACROMEDIA_FLASH_PROJECT_EXT)) {
         makefiletype = MACROMEDIA_FLASH_VENDOR_NAME;
      }
   }

   // Look for these up here because there is no reason to open the makefile
   if (makefiletype==VISUAL_STUDIO_VCPP_VENDOR_NAME) {
      if(file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
         return(GetVisualStudioVCXConfigs(associateMakefile,configList));
      } else {
         return(GetVisualStudioVCPPConfigs(associateMakefile,configList));
      }
   } else if ( (makefiletype==VISUAL_STUDIO_CSHARP_VENDOR_NAME) ||
               (makefiletype==VISUAL_STUDIO_VB_VENDOR_NAME) ||
               (makefiletype==VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME) ||
               (makefiletype==VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME) ||
               (makefiletype==VISUAL_STUDIO_FSHARP_VENDOR_NAME) ||
               (makefiletype==VISUAL_STUDIO_JSHARP_VENDOR_NAME) ) {
      return(GetVisualStudioStandardConfigs(associateMakefile,configList,ext));
   } else if ( (makefiletype==VISUAL_STUDIO_TEMPLATE_NAME) ||
               (makefiletype==VISUAL_STUDIO_DATABASE_NAME) ) {
      // These don't really have configurations, so just create a dummy 'Debug'
      // so that things don't explode later
      configList[0].config='Debug';
      configList[0].objdir='';
      return 0;
   } else if (makefiletype==JBUILDER_VENDOR_NAME) {
      return getJBuilderConfigs(associateMakefile, configList);
   } else if (makefiletype==XCODE_PROJECT_VENDOR_NAME) {
      return _xcode_get_configs(associateMakefile,configList);
   } else if (makefiletype==MACROMEDIA_FLASH_VENDOR_NAME) {
      return _flash_get_configs(associateMakefile,configList);
   }

   // Look up the associated project file and extract the configurations.
   _str line='';
   int temp_view_id, orig_view_id;
   status = _open_temp_view(associateMakefile, temp_view_id, orig_view_id);
   if (status) return(status);
   switch (makefiletype) {
   case TORNADO_VENDOR_NAME:
      {
         top(); up();
         int count = configList._length();
         status=search('^\<BEGIN\> BUILD__LIST$','@rh');
         if (!status) {
            while (!down()) {
               get_line(line);
               if (line=='<END>') break;
               for (;;) {
                  _str cur=parse_file(line);
                  if (cur=='') break;
                  configList[count].config="BUILD_SPEC="cur;
                  configList[count].objdir = "";
                  ++count;
               }
            }
         }
         //12:25:11 PM 11/24/2000
         //The code that was here was to be sure that there is an active configuration.
         //We do not want to do this here.  There is code elsewhere to be sure that
         //this happens.  Doing this here causes a problem because if these files
         //are created already, some stuff get skipped, most notably setting the
         //working directory
         //
         //status=_ini_get_value(VSEProjectFilename(project_name),"CONFIGURATIONS",'activeconfig',activeconfig,'');
         //if (status || activeconfig=='') {
         //   top();up();
         //   status=search('^\<BEGIN\> BUILD__CURRENT$','@r');
         //   if (!status) {
         //      down();get_line(line);
         //      status=_ini_set_value(VSEProjectFilename(project_name),"CONFIGURATIONS",'activeconfig',',BUILD_SPEC='line);
         //   }
         //}
      }
      break;
   case VCPP_VENDOR_NAME:
      {
         top();up();
         int count = configList._length();
         while (!search('# Name "','>@h')) {
            get_line(line);
            parse line with '# Name "'line'"';
            configList[count].config='CFG=':+line;
            configList[count].objdir='';
            ++count;
         }
      }
      break;
   }
   /*
     10/6/1999
     This removes duplicates from the configList.  This happened where a user
     had a configuration setting for each of the file's in his project.
   */
   int i,j;
   for (i=0; i<configList._length(); i++) {
      _str configstring=configList[i].config;
      for (j=i+1; j<configList._length(); j++) {
         if (configList[j].config:==configstring) {
            configList._deleteel(j);
            j--;
         }
      }
   }

   // Clean up.
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   return(0);
}

// Return list of the configurations defined in a Visual C++ .vcxproj (VS2010)
static int GetVisualStudioVCXConfigs(_str assoicatedProjectFile, ProjectConfig (&configList)[])
{
   // Open the file
   int status=0;
   int handle=_xmlcfg_open(assoicatedProjectFile,status);
   if (handle<0) return(status);
   if (status && status!=VSXMLCFG_STATUS_OPEN_ALREADY) {
      _xmlcfg_close(handle);
      return(status);
   }

   // Get the <ItemGroup Label="ProjectConfigurations"> node
   int allConfigsNode = _xmlcfg_find_simple(handle, "//Project/ItemGroup[@Label='ProjectConfigurations']");
   if(allConfigsNode > 0) {
      // Get all the child <ProjectConfiguration> nodes
      typeless ConfigIndexes[]=null;
      status = _xmlcfg_find_simple_array(handle, "ProjectConfiguration", ConfigIndexes, allConfigsNode);
      if((status == 0)  && (ConfigIndexes._length() > 0)) {

         // Walk each ProjectConfiguration node
         // Return the value of the Include attribute, and parse
         // out the first part.
         // 
         // TODO: Correctly determine the objDir, instead of just assuming the 
         // name of the configuration.
         int idx;
         for (idx=0;idx<ConfigIndexes._length();++idx) {
            _str cfgString = _xmlcfg_get_attribute(handle, ConfigIndexes[idx], "Include");
            _str cfgName, cfgPlatform;
            parse cfgString with cfgName "|" cfgPlatform;
            configList[idx].config = cfgString;
            configList[idx].objdir = cfgName;
         }
         _xmlcfg_close(handle);
         return 0;
      }
   }
   _xmlcfg_close(handle);
   return -1;
}

static int GetVisualStudioVCPPConfigs(_str associateMakefile,ProjectConfig (&configList)[])
{
   // If we have a new Visual Studio VC++ project file, get the configs here
   //
   // Open the file
   int status=0;
   int handle=_xmlcfg_open(associateMakefile,status);
   if (handle<0) return(status);
   if (status && status!=VSXMLCFG_STATUS_OPEN_ALREADY) {
      return(status);
   }

   
   // Get the index of the Platform tag
   typeless PlatformIndexes[]=null;
   status=_xmlcfg_find_simple_array(handle,"/VisualStudioProject/Build/Settings/Platform",PlatformIndexes);
   //for (i=0;i<PlatformIndexes._length();++i) {
   //cap=_xmlcfg_get_name(handle,PlatformIndexes[i]);
   //}
   if (PlatformIndexes._length()) {
      return(GetVisualStudioVCPPConfigsBeta1(handle,PlatformIndexes,associateMakefile,configList));
   }
   status=_xmlcfg_find_simple_array(handle,"/VisualStudioProject/Platforms/Platform",PlatformIndexes);
   if (status || !PlatformIndexes._length()) {
      _xmlcfg_close(handle);
      return(status);
   }
   _str PlatformName;
   PlatformName=_xmlcfg_get_attribute(handle,PlatformIndexes[0],"Name");
   if (PlatformName=='') {
      _xmlcfg_close(handle);
      return(status);
   }
   // Get the indexes to the Configuration tags
   typeless ConfigurationIndexes[]=null;
   status=_xmlcfg_find_simple_array(handle,"/VisualStudioProject/Configurations/Configuration",ConfigurationIndexes);
   if (status) {
      _xmlcfg_close(handle);
      return(status);
   }
   GetConfigNamesFromIndexes(handle,PlatformName,ConfigurationIndexes,configList);

   _xmlcfg_close(handle);
   return(0);
}

static int GetVisualStudioVCPPConfigsBeta1(int handle,int PlatformIndexes[],
                                           _str VCPPProjectFile,ProjectConfig (&configList)[])
{
   // Get the Name attribute from the Platform tag
   _str PlatformName='';
   PlatformName=_xmlcfg_get_attribute(handle,PlatformIndexes[0],"Name");
   if (PlatformName=='') {
      _xmlcfg_close(handle);
      // VSRC_XMLCFG_ATTRIBUTE_NOT_FOUND might be better
      return(STRING_NOT_FOUND_RC);
   }

   // Get the indexes to the Configuration tags
   typeless ConfigurationIndexes[]=null;
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/Build/Settings/Configuration",ConfigurationIndexes);
   GetConfigNamesFromIndexes(handle,PlatformName,ConfigurationIndexes,configList);
   _xmlcfg_close(handle);
   return(0);
}

static void GetConfigNamesFromIndexes(int handle,_str PlatformName,int ConfigurationIndexes[], ProjectConfig (&configList)[])
{
   // Loop through the indexes
   int i;
   for (i=0;i<ConfigurationIndexes._length();++i) {
      // Get the Name attribute from each config tag
      configList[i].config=_xmlcfg_get_attribute(handle,ConfigurationIndexes[i],"Name");

      // Get the OutputDirectory attribute from the Config tag
      _str OutputDir=_xmlcfg_get_attribute(handle,ConfigurationIndexes[i],"OutputDirectory");

      // We probably need to append a trailing FILESEP
      if (last_char(OutputDir)!=FILESEP) {
         OutputDir=OutputDir:+FILESEP;
      }
      // We might also want to put on a leading "."FILESEP
      if (substr(OutputDir,1,1)!=FILESEP && substr(OutputDir,1,1)!='.' &&
          substr(OutputDir,2,1)!=':') {
         // If we don't start with a filesep or a ".",
         // we don't have a relative filename, if we don't
         // have a ":" for the second char, we don't have an absolute path.
         OutputDir='.':+FILESEP:+OutputDir;
      }
      // Keep the objdir
      configList[i].objdir=OutputDir;
   }
}

static int GetWhidbeyConfigs(int handle,ProjectConfig (&configList)[],_str ext)
{
   typeless propertyGroupNodes[]=null;
   _xmlcfg_find_simple_array(handle,'/Project/PropertyGroup',propertyGroupNodes);

   int curPropertyGroup;
   for (curPropertyGroup=0;curPropertyGroup<propertyGroupNodes._length();++curPropertyGroup) {
      _str condition=_xmlcfg_get_attribute(handle,propertyGroupNodes[curPropertyGroup],'Condition');

      if (condition:!='') {
         _str configName;
         parse condition with . " == '" configName "'" .;
         int configIndex=configList._length();

         configList[configIndex].config=configName;
         configList[configIndex].objdir='';

         int outputPathNode=_xmlcfg_find_simple(handle,'OutputPath',propertyGroupNodes[curPropertyGroup]);
         if (outputPathNode>=0) {
            int cdataNode=_xmlcfg_get_first_child(handle,outputPathNode,VSXMLCFG_NODE_PCDATA);
            if (cdataNode>=0) {
               configList[configIndex].objdir=_xmlcfg_get_value(handle,cdataNode);
            }
         }
      }
   }

   return 0;
}

static int GetVisualStudioStandardConfigs(_str associateMakefile,ProjectConfig (&configList)[],_str ext)
{
   _str AppName=GetVSStandardAppName(ext);
   // If we have a new Visual Studio VC++ project file, get the configs here
   //
   // Open the file
   int status=0;
   int handle=_xmlcfg_open(associateMakefile,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if (handle<0) return(status);

   // Get the indexes to the Configuration tags

   typeless ConfigurationIndexes[]=null;
   status=_xmlcfg_find_simple_array(handle,"/VisualStudioProject/"AppName"/Build/Settings/Config",ConfigurationIndexes);

   if (status || (ConfigurationIndexes._length() == 0)) {
      status=GetWhidbeyConfigs(handle,configList,ext);
      _xmlcfg_close(handle);
      return(status);
   }
   // Loop through the indexes
   int i;
   for (i=0;i<ConfigurationIndexes._length();++i) {
      // Get the Name attribute from each config tag
      configList[i].config=_xmlcfg_get_attribute(handle,ConfigurationIndexes[i],"Name");

      // Get the OutputDirectory attribute from the Config tag
      _str OutputDir=_xmlcfg_get_attribute(handle,ConfigurationIndexes[i],"OutputPath");

      // We might also want to put on a leading "."FILESEP
      if (substr(OutputDir,1,1)!=FILESEP && substr(OutputDir,1,1)!='.' &&
          substr(OutputDir,2,1)!=':') {
         // If we don't start with a filesep or a ".",
         // we don't have a relative filename, if we don't
         // have a ":" for the second char, we don't have an absolute path.
         OutputDir='.':+FILESEP:+OutputDir;
      }
      // Keep the objdir
      configList[i].objdir=OutputDir;
   }
   _xmlcfg_close(handle);
   return(0);
}

// Get the project configurations from a VSE project file.
// Retn: 0 OK, !0 error status
int getVSEProjectConfigs(int handle,ProjectConfig (&configList)[])
{
   // get list of config names
   _str configNames[] = null;
   _ProjectGet_ConfigNames(handle, configNames);
   int j;
   for (j = 0; j < configNames._length(); j++) {
      // get output dir
      _str outdir = _ProjectGet_ObjectDir(handle, configNames[j]);

      // add it to the list
      configList[j].config = configNames[j];
      configList[j].objdir = outdir;
   }
   return 0;
}

/**
 * Get list of configs from the specified JBuilder project
 */
static int getJBuilderConfigs(_str filename, ProjectConfig (&configList)[])
{
   int status = 0;

   // open the file
   int handle = _xmlcfg_open(filename, status);
   if (handle < 0) return status;

   // jbuilder projects have a single output dir
   _str outputDir = "";
   int outputDirNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "OutPath"));
   if (outputDirNode >= 0) {
      outputDir = _xmlcfg_get_attribute(handle, outputDirNode, "value");
      outputDir = _RelativeToProject(outputDir, _xmlcfg_get_filename(handle));
   }
//
// JBUILDER USES CONFIGS AS 'RUNTIME' CONFIGURATIONS WHICH DOES NOT MAP CLEANLY TO
// HOW VSE CONFIGS WORK.  ADD A SINGLE DEFAULT CONFIG AND LET JBUILDER DO THE REST
//
//   // get the list of configurations
//   int configNodeList[] = null;
//   status = _xmlcfg_find_simple_array(handle, "/project/property" XPATH_STRIEQ("name", "ConfigurationName"), configNodeList);
//   if(status) {
//      _xmlcfg_close(handle);
//      return status;
//   }
//
//   int i;
//   for(i = 0; i < configNodeList._length(); i++) {
//      // get the name of the configuration which is in the value attribute
//      _str configName = _xmlcfg_get_attribute(handle, configNodeList[i], "value");
//      if(configName == "") continue;
//
//      // save the config name and output dir
//      configList[i].config = configName;
//      configList[i].objdir = outputDir;
//   }

   // it is possible that a jbuilder project may have no configs.  if this is
   // the case, return "Default Configuration" so that there is at least
   // one config
   if (configList._length() <= 0) {
      configList[0].config = "Default Configuration";
      configList[0].objdir = outputDir;
   }

   // close the file
   _xmlcfg_close(handle);
   return 0;
}

/**
 * Get the JBuilder source dir that applies to the specified file
 */
_str _getJBuilderSourceDirForFile(_str project, _str filename, int handle = -1)
{
   int status = 0;

   // absolute the filename
   filename = _AbsoluteToProject(filename, project);

   // open the file
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(project, status);
      openedFile = true;
   }
   if (handle < 0) return "";

   _str sourceDir = "";

   // find the list of source dirs
   int sourceDirNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "SourcePath"));
   if (sourceDirNode >= 0) {
      _str sourceDirList = _xmlcfg_get_attribute(handle, sourceDirNode, "value");
      for (;;) {
         _str dir = "";
         parse sourceDirList with dir PATHSEP sourceDirList;
         if (dir == "") break;

         // absolute it to the project to see if it contains the file
         dir = _AbsoluteToProject(dir, project);

         // see if the file is in this dir by comparing the paths
         if (file_eq(dir, substr(filename, 1, length(dir)))) {
            sourceDir = dir;
            break;
         }
      }
   }

   // close the file
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   return sourceDir;
}

#if 0
/**
 * Get default config for JBuilder project file
 */
static _str getJBuilderDefaultConfig(_str filename, int handle = -1)
{
   int status = 0;

   // open the file
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(filename, status);
      openedFile = true;
   }
   if (handle < 0) return "";

   // find the default configuration
   _str defConfig = "";
   _str defConfigID = "";
   int defConfigNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "DefaultConfiguration"));
   if (defConfigNode < 0) {
      // node not found means use id 0
      defConfigID = "0";
   } else {
      defConfigID = _xmlcfg_get_attribute(handle, defConfigNode, "value");
   }

   // if id is -1 then no configs exist so use default
   if (defConfigID == "-1") {
      defConfig = "Default Configuration";
   } else {
      // find the name associated with that config id
      int configNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("category", "runtime." defConfigID));
      if (configNode >= 0) {
         defConfig = _xmlcfg_get_attribute(handle, configNode, "value");
      }
   }

   // close the file
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   // if nothing found, use default
   if (defConfig == "") {
      defConfig = "Default Configuration";
   }

   return defConfig;
}

/**
 * Set default config for JBuilder project file
 */
static int setJBuilderDefaultConfig(_str filename, _str config, int handle = -1)
{
   int status = 0;

   // open the file
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(filename, status);
      openedFile = true;
   }
   if (handle < 0) return status;

   // get the list of configurations
   int configNodeList[] = null;
   status = _xmlcfg_find_simple_array(handle, "/project/property" XPATH_STRIEQ("name", "ConfigurationName"), configNodeList);
   if (status) {
      _xmlcfg_close(handle);
      return status;
   }

   // find the config that was given
   _str configID = "";
   if (configNodeList._length()) {
      // there are configs so default to first one in case specified config not found
      configID = "0";

      int i;
      for (i = 0; i < configNodeList._length(); i++) {
         // get the name of the configuration which is in the value attribute
         _str configName = _xmlcfg_get_attribute(handle, configNodeList[i], "value");

         if (strieq(configName, config)) {
            // get the id of this config
            _str category = _xmlcfg_get_attribute(handle, configNodeList[i], "category");
            parse category with "runtime." configID;
            break;
         }
      }
   } else {
      // there are no configs so use default
      configID = "-1";
   }

   // find the default configuration node
   int defConfigNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "DefaultConfiguration"));
   if (defConfigNode < 0) {
      defConfigNode = _xmlcfg_add(handle, _xmlcfg_find_simple(handle, "/property"), "property", VSXMLCFG_NODE_ATTRIBUTE, 0);
      _xmlcfg_set_attribute(handle, defConfigNode, "category", "runtime");
      _xmlcfg_set_attribute(handle, defConfigNode, "name", "DefaultConfiguration");
   }

   _xmlcfg_set_attribute(handle, defConfigNode, "value", configID);

   // close the file
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}
#endif

/**
 * Get the output dir from the JBuilder project file
 */
_str getJBuilderOutputDir(_str filename)
{
   int status = 0;

   // open the file
   int handle = _xmlcfg_open(filename, status);
   if (handle < 0) return "";

   // jbuilder projects have a single output dir
   _str outputDir = "";
   int outputDirNode = _xmlcfg_find_simple(handle, "/project/property" XPATH_STRIEQ("name", "OutPath"));
   if (outputDirNode >= 0) {
      outputDir = _xmlcfg_get_attribute(handle, outputDirNode, "value");
      outputDir = _RelativeToProject(outputDir, _xmlcfg_get_filename(handle));
   }

   // close the file
   _xmlcfg_close(handle);

   return outputDir;
}


/**
 * Get list of configs from the specified flash project
 */
static int _flash_get_configs(_str filename, ProjectConfig (&configList)[])
{
   // flash projects don't have configurations
   configList[0].config = "Release";
   configList[0].objdir = '';
   return 0;
}

// Get the configurations from the active project. If the project
// is associated project file, the associated makefile is scanned for
// build configurations. If the project is a VSE project, its
// configurations are read.
// Retn: 0 OK, !0 error status
// WARNING:  DONT CHANGE THIS FUNCTION unless you change the C code that calls it in
// vsapi.dll
int getProjectConfigs(_str project_name, ProjectConfig (&configList)[], int & associated)
{
   // Get the list of configurations from an associated project file,
   // if this is an associated project file.
   configList._makeempty();
   associated = 1;
   int status = _getAssociatedProjectConfigs(project_name,configList);
   if (!status) return(0);

   // Get the list of configurations from the SlickEdit project file.
   associated = 0;
   status = getVSEProjectConfigs(_ProjectHandle(project_name),configList);
   return(status);
}

// Get the active configuration of the active project. If there is
// no active configuration, default to the first configuration in
// the list. If there is no configuration for the current project,
// return "".
// WARNING: DON'T CHANGE THIS FUNCTION unless you change the C code that calls
// in vsapi.dll
_str getActiveProjectConfig(_str ProjectFilename=_project_name)
{
   _str configName = "";
   _str array[]; array._makeempty();
   _str info;
   //int status = _ini_get_value(ProjectFilename,"CONFIGURATIONS","activeconfig",configName);
   _ProjectGet_ConfigNames(_ProjectHandle(ProjectFilename),array);
   _ini_get_value(VSEWorkspaceStateFilename(), "ActiveConfig", _RelativeToWorkspace(ProjectFilename), info,'',_fpos_case);
   parse info with ',' configName;
   if (configName!='') {
      int i;
      for (i=0;i<array._length();++i) {
         if (strieq(configName,array[i])) {
            return(configName);
         }
      }
   }
   if (array._length()) {
      configName=array[0];
   }
   return(configName);
}

/**
 * Returns the active configuration object directory for the given project.
 *
 * @param ProjectFilename   Absolute path to project file. Object directories
 *                          returned are relative to the location of this file.
 * @param WorkspaceFilename Absolute path to workspace file. It is very
 *                          important that this be correct because relative
 *                          project directory paths will be returned relative
 *                          to the location of this file.
 *
 * <p>
 * <b>Note:</b><br>
 * This will also return the default object directory for the case of no
 * active configuration.
 * </p>
 */
_str getActiveProjectConfigObjDir(_str ProjectFilename=_project_name,_str WorkspaceFilename=_workspace_filename)
{
   ProjectConfig configList[];
   int associated;

   getProjectConfigs(ProjectFilename,configList,associated);
   _str ActiveConfig;
   ActiveConfig=getActiveProjectConfig(ProjectFilename);
   _str objdir=_ProjectGet_ObjectDir(_ProjectHandle(ProjectFilename),ActiveConfig);

   if ( objdir=="" ) {
      if ( pos('CFG={?*}($|")',ActiveConfig,1,'ri') ) {
         objdir=_vcGetObjDir(ActiveConfig);
      } else {
         // Java is a special case that we default to a 'classes' subdir instead
         // of a subdir named the same as the configuration
         _str packtype="";
         _str packname="";
         packtype=_ProjectGet_Type(_ProjectHandle(ProjectFilename),ActiveConfig);
         if (strieq(packtype, "java")) {
            objdir="classes";
         } else {
            objdir=ActiveConfig;
         }
      }
   }
   if ( objdir!="" ) {
      _maybe_append_filesep(objdir);
      objdir=_AbsoluteToProject(objdir,ProjectFilename);
   }

   return(objdir);
}

int _OnUpdate_project_config_set_active(CMDUI &cmdui,int target_wid,_str command)
{
   int flags=_OnUpdateDefault(cmdui,target_wid,command);
   if (flags==MF_ENABLED) {
      // Need to keep the MF_CHECKED flag
      return(0);
   }
   return(flags);
}
/**
 * Sets the current project's configuration, and all
 * dependant projects configurations to configText.
 *
 * @param configText String in the format &lt;objdir&gt;,&lt;Configname&gt;
 */
_command void project_config_set_active(_str ConfigName='', _str ProjectFilename=_project_name,
                                        boolean quiet=false) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{

   if (ConfigName == "") return;
   if (_DebugMaybeTerminate()) {
      return;
   }

   // look for project specified on command line?
   _str cmd_line=ConfigName;
   _str cmd_arg = '';
   for (;;) {
      cmd_arg = parse_file(cmd_line,false);
      if (cmd_arg=='') break;
      if (cmd_arg=='-p') {
         ProjectFilename = parse_file(cmd_line,false);
      } else {
         ConfigName = cmd_arg;
         break;
      }
   }
   ProjectFilename=strip(ProjectFilename,'B','"');

   // change the mouse pointer to reflect the configuration is changing
   if (!quiet) {
      mou_hour_glass(1);
   }

   int orig_view_id;
   get_window_id(orig_view_id);

   // keep a hash table of which projects have already been switched.  this is to resolve a
   // performance issue where a project was having its configuration switched multiple times
   // due to several projects being dependent on it
   _str depProjectsCompleted:[];

   // call the recursive version of the function to do the work
   project_config_set_active_recursive(ConfigName, 0, ProjectFilename, depProjectsCompleted, quiet);

   if (file_eq(_project_name,ProjectFilename)) {
      gActiveConfigName=ConfigName;
      _DebugUpdateMenu();
      call_list('_prjconfig_');  // Active config changed
   }
   activate_window(orig_view_id);

   // update the tag file list
   _TagCallList(TAGFILE_ADD_REMOVE_CALLBACK_PREFIX,'','');
   _TagCallList(TAGFILE_REFRESH_CALLBACK_PREFIX);

   // clear message and restore mouse pointer
   if (!quiet) {
      mou_hour_glass(0);
      _toolbar_update_project_config();
   }
}

static void project_config_set_active_recursive(_str configName, int recurse, _str ProjectFilename,
                                                _str (&depProjectsCompleted):[], boolean quiet)
{
   // make sure this project has not already had its active config changed
   ProjectFilenameCased := _file_case(ProjectFilename);
   if (depProjectsCompleted._indexin(ProjectFilenameCased)) {
      if (depProjectsCompleted:[ProjectFilenameCased] == "1") return;
   }

   // flag that this project had its active config changed
   depProjectsCompleted:[ProjectFilenameCased] = "1";

   // change the message to reflect the configuration is changing
   if (!quiet) {
      message("Changing configuration to \"" configName "\" in project \"" ProjectFilename "\"");
   }

   int orig_view_id;
   get_window_id(orig_view_id);
   //_ini_set_value(_project_get_filename(),"COMPILER","activeconfig",configText);
   _str old_configName=GetCurrentConfigName(ProjectFilename);
   int status = _ini_set_value(VSEWorkspaceStateFilename(),"ActiveConfig",_RelativeToWorkspace(ProjectFilename),','configName,_fpos_case);

   int was_recording=_macro();
   if (!recurse) {
      _macro_delete_line();
   }
   _macro('m',was_recording);
   _macro_append(nls("_ini_set_value(\"%s1\",\"ActiveConfig\",\"%s2\",\"%s3\",_fpos_case);",
                     VSEWorkspaceStateFilename(),_RelativeToWorkspace(ProjectFilename),','configName));
   //_str WorkspaceFilename=VSEWorkspaceFilename(_workspace_filename);
   if (_workspace_filename!='') {
      _WorkspacePutProjectDate(ProjectFilename);
      _macro('m',was_recording);
      _macro_call('_workspace_filename',_workspace_filename,_project_name);
   }
   //parse configText with configDir ',' configName;
   _str Files[]=null,Dependencies:[]=null;
   Files[0]=_RelativeToWorkspace(ProjectFilename);
   _GetDependencies(Files,Dependencies);
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._isempty()) break;
      _str CurDeps=Dependencies:[i];
      if ( file_eq(i,_RelativeToWorkspace(GetProjectDisplayName(ProjectFilename))) ) {
         for (;;) {
            _str CurFile=parse_file(CurDeps);
            if (CurFile=='') break;
            //Env expansion MUST be done in _GetDependencies!
            //CurFile=_parse_project_command(CurFile,"","","");
            CurFile=_AbsoluteToWorkspace(CurFile);
            int Node=_ProjectGet_ConfigNode(_ProjectHandle(CurFile),configName);
            if (Node>=0) {
               project_config_set_active_recursive(configName, 1, CurFile, depProjectsCompleted, quiet);
            } else if (_IsVCPPWorkspaceFilename(_workspace_filename)) {
               // If this is a VCPP workspace, just set the config name
               // First parse out the config name
               _str curConfigName=configName;
               parse curConfigName with 'CFG=' curConfigName;
               int lp=lastpos(' - ',curConfigName);
               if (!lp) {
                  curConfigName='';
               } else {
                  // Now add the CFG=projname to the config name
                  curConfigName=substr(curConfigName,lp+3);
                  curConfigName='"CFG='_strip_filename(ProjectFilename,'PE')' - 'curConfigName;
               }
               project_config_set_active_recursive(curConfigName, 1, CurFile, depProjectsCompleted, quiet);
            }
         }
      }
   }
   activate_window(orig_view_id);

   if (!quiet) {
      clear_message();
   }
}
/**
 * Sets the specified project active in the current workspace.
 *
 * @param filename project file that is in the workspace
 *
 * @param quiet
 *
 * @param allowBlankFilename
 *
 * @param doUpdateWorkspaceList
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
_command void workspace_set_active(_str filename='',boolean quiet=false,boolean allowBlankFilename=false,boolean doUpdateWorkspaceList=true) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   if (_workspace_filename=='') {
      return;
   }
   if (!allowBlankFilename && filename=='') {
      if (!quiet) {
         _message_box(nls("You must specify a filename to set current"));
      }
      return;
   }
   _str afilename;
   if (filename=='') {
      afilename=filename;
   } else {
      afilename=_AbsoluteToWorkspace(filename);
   }
   if (file_eq(_project_name,afilename)) {
      return;
   }

   if (!file_exists(afilename) && afilename!='') {
      _message_box(nls("Project file '%s' does not exist",afilename));
      return;
   }
   boolean projectWasOpen=_project_name!='';
   if (projectWasOpen) {
      workspace_close_project();
      //call_list('_prjclose_');
      //tag_close_bsc();
      //toolbarSaveExpansion(_project_name);
   }
   _str ProjectFilename=VSEProjectFilename(afilename);

   if (ProjectFilename=='') {
      gActiveConfigName='';
      gActiveTargetDestination='';
      _project_name='';
      call_list('_prjconfig_');  // Active config changed
   } else {
      if (_ProjectOpen(ProjectFilename)<0) {
         // Error message box already displayed
         return;
      }
   }

   _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename),"Global","CurrentProject",_RelativeToWorkspace(_project_name));

   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   if (_project_name!='') {
      // Cache the project file
      _str new_DebugCallbackName=_ProjectGet_DebugCallbackName(_ProjectHandle(_project_name));
      // DJB 03-18-2008
      // Integrated .NET debugging is no longer available as of SlickEdit 2008
      if (new_DebugCallbackName=="dotnet") new_DebugCallbackName="";
      if (new_DebugCallbackName!=_project_DebugCallbackName) {
         _project_DebugCallbackName=new_DebugCallbackName;
         _DebugUpdateMenu();
      }
      _str cwd=_ProjectGet_WorkingDir(_ProjectHandle(_project_name));
      if (cwd!='') {
         //cwd=_parse_project_command(cwd, '', _project_get_filename(),'');
         cwd=absolute(cwd,_strip_filename(_project_name,'n'));
         cd(cwd);
      }

      // create project-specific tagfiles
      // (this will set _project_extTagFiles and _project_extExtensions)
      maybeCreateProjectSpecificTagFiles(_project_name);

      call_list('_prjopen_');
   } else {
      if (_project_DebugCallbackName!='') {
         _project_DebugCallbackName='';
         _DebugUpdateMenu();
      }
   }
   if (doUpdateWorkspaceList) {
      toolbarUpdateActiveProject();
   }
}

static void maybeCreateProjectSpecificTagFiles(_str projectFilename)
{
   // check for and save project-specific tag file extension support
   _project_extExtensions=_ProjectGet_TagFileExt(_ProjectHandle(projectFilename));

   // call the package-specific on-set-active callback to create any custom tag files
   _str onSetActiveCallback;
   onSetActiveCallback=_ProjectGet_OnSetActiveMacro(_ProjectHandle(projectFilename));

   if (onSetActiveCallback != '') {
      int index = find_index(onSetActiveCallback, PROC_TYPE);
      if (index) {
         _project_extTagFiles = call_index(index);
      }
   } else {
      _project_extTagFiles = '';
   }

   // set the taglist cache flag so that the taglist will be regenerated.  this is done
   // because project type specific tag files are stored on a project level
   gtag_filelist_cache_updated = false;
}

_str always_quote_filename(_str filename)
{
   if (filename=='') {
      return('');
   }
   if (substr(filename,1,1)!='"') {
      filename='"'filename;
   }
   if (last_char(filename)!='"') {
      filename=filename'"';
   }
   return(filename);
}

int _OnUpdate_workspace_dependencies(CMDUI &cmdui,int target_wid,_str command)
{
   if (_project_name=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

static int GetDependenciesEclipseWorkspaceFile(_str WorkspaceFilename,
                                               _str (&Files)[],
                                               _str (&Dependencies):[])
{
   _str PathList[]=null;
   int i,j,k;
   for (i=0;i<Files._length();++i) {
      _str TempPathList[]=null;
      _GetEclipsePathList(_strip_filename(Files[i],'N'),TempPathList,true);
      for (j=0;j<Files._length();++j) {
         for (k=0;k<TempPathList._length();++k) {
            if (file_eq(_strip_filename(Files[j],'PE'),substr(TempPathList[k],2))) {
               if (Dependencies._indexin(Files[i])) {
                  Dependencies:[Files[i]] :+= ' 'TempPathList[k];
               } else {
                  Dependencies:[Files[i]] = TempPathList[k];
               }
            }
         }
      }
   }
   return(0);
}

/**
 * Returns a hashtable of dependencies in Dependencies, and a
 * list of relative project filenames in Files.
 *
 * @param WorkspaceFilename
 *               Workspace to get dependencies from
 *
 * @param Files  Array to return files in
 *
 * @param Dependencies
 *               Hashtable to return dependencies in.  Filenames returned
 *               are display names.  Indexes are "file cased".
 *  
 * @param AllDependencies 
 *               Hashtable containing all project dependencies in
 *               the workspace tag file.  If this is empty, it will be
 *               built on the first invocation so that it can be used
 *               to build Dependencies lists later without reparsing
 *               the solution file.
 *
 * @return returns 0 if successful
 */
static int GetDependenciesFromVisualStudioWorkspaceFile(_str SolutionFilename,
                                                        _str (&Files)[],
                                                        _str (&Dependencies):[],
                                                        _str (*AllDependencies):[]=null)
{
   // clear out the output list of dependencies
   Dependencies._makeempty();

   // set flag if we need to build all dependency information for caching later
   buildAllDependencies := false;
   if (AllDependencies != null && AllDependencies->_length() == 0) {
      buildAllDependencies = true;
   }

   // hash the set of project file names into a table
   boolean InFilesHashTab:[];
   for (j:=0; j<Files._length(); ++j) {
      InFilesHashTab:[_file_case(_strip_filename(Files[j],'PE'))]=true;
   }

   // open the solution in a temp view
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(SolutionFilename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }

   // now search for dependency information
   _str FileTable:[];
   _str Codes:[]=null;
   int StartLines:[]=null;
   _str line='';
   _str curfile='';
   _str curcode='';
   _str curproj='';
   _str curproj_dependson='';
   top();up();
   for (;;) {
      status=search('^Project\("?@") = "?@", "?@", "?@"$','@rhi>');
      if (status) {
         break;
      }
      get_line(line);
      parse line with 'Project\(\"?@\"\) = "?*", "','r' curfile '", "{'curcode'}"';
      curfile=_AbsoluteToWorkspace(curfile);
      Codes:[curcode]=curfile;
      StartLines:[curcode]=p_line;
   }
   // look for global dependencies section
   top();up();
   status=search('\tGlobalSection\(ProjectDependencies\) = postSolution$','@r');
   if (!status) {
      while (!down()) {
         get_line(line);
         if (line=='EndGlobalSection') {
            break;
         }
         parse line with '[\{\(]','r' curproj '[\}\)]\.:i = [\{\(]','r' curproj_dependson '[\}\)]','r';
         if (Codes._indexin(curproj)) {
            _str curprojName=_file_case(Codes:[curproj]);
            _str name=_strip_filename(curprojName,'PE'); // already file cased
            if (buildAllDependencies) {
               if (AllDependencies->_indexin(curprojName)) {
                  (*AllDependencies):[curprojName] :+= ' 'maybe_quote_filename(Codes:[curproj_dependson]);
               } else {
                  (*AllDependencies):[curprojName] = maybe_quote_filename(Codes:[curproj_dependson]);
               }
            }
            if (!InFilesHashTab._indexin(name)) {
               continue;
            }
            if (Dependencies._indexin(curprojName)) {
               Dependencies:[curprojName] :+= ' 'maybe_quote_filename(Codes:[curproj_dependson]);
            } else {
               Dependencies:[curprojName] = maybe_quote_filename(Codes:[curproj_dependson]);
            }
         }
      }
   }
   // look for dependencies listed per project
   int curprojline=0;
   typeless curprojindex;
   top();up();
   status=search('\tProjectSection\(ProjectDependencies\) = postProject$','@rh');
   while (!status) {
      // determine which project this is in
      curproj='';
      curprojline=-1;

      curprojindex._makeempty();
      for (StartLines._nextel(curprojindex);!curprojindex._isempty();StartLines._nextel(curprojindex)) {
         int testLine=StartLines:[curprojindex];
         if ((testLine<=p_line)&&(testLine>curprojline)) {
            curproj=curprojindex;
            curprojline=testLine;
         }
      }

      _str name='';
      if (Codes._indexin(curproj)) {
         name=_strip_filename(Codes:[curproj],'PE');
      }

      buildTheseDependencies := InFilesHashTab._indexin(_file_case(name));
      if ((curprojline>=0) && (buildTheseDependencies || buildAllDependencies)) {
         while (!down()) {
            get_line(line);
            line=strip(line);
            if (line=='EndProjectSection') {
               break;
            }
            parse line with '{'curproj_dependson'}' .;
            _str curprojName=_file_case(Codes:[curproj]);
            if (buildAllDependencies) {
               if (AllDependencies->_indexin(curprojName)) {
                  (*AllDependencies):[curprojName] :+= ' 'maybe_quote_filename(Codes:[curproj_dependson]);
               } else {
                  (*AllDependencies):[curprojName] = maybe_quote_filename(Codes:[curproj_dependson]);
               }
            }
            if (buildTheseDependencies) {
               if (Dependencies._indexin(curprojName)) {
                  Dependencies:[curprojName] :+= ' 'maybe_quote_filename(Codes:[curproj_dependson]);
               } else {
                  Dependencies:[curprojName] = maybe_quote_filename(Codes:[curproj_dependson]);
               }
            }
         }
      } else {
         down();
      }
      status=search('\tProjectSection\(ProjectDependencies\) = postProject$','@rh');
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

/**
 * Returns a hashtable of dependencies in Dependencies, and a
 * list of relative project filenames in Files.  All names are
 * DISPLAY NAMES (.dsp).
 *
 * @param WorkspaceFilename
 *               Workspace to get dependencies from
 *
 * @param Files  Array to return files in
 *
 * @param Dependencies
 *               Hashtable to return dependencies in.  Filenames returned
 *               are display names.  Indexes are "file cased".
 *  
 * @param AllDependencies 
 *               Hashtable containing all project dependencies in
 *               the workspace.  If this is empty, it will be
 *               built on the first invocation so that it can be used
 *               to build Dependencies lists later without reparsing
 *               the solution file.
 *
 * @return returns 0 if successful
 */
static int GetDependenciesFromVCPPWorkspaceFile(_str WorkspaceFilename,
                                                _str (&Files)[],
                                                _str (&Dependencies):[],
                                                _str (*AllDependencies):[]=null)
{
   // clear out the output list of dependencies
   Dependencies._makeempty();

   // set flag if we need to build all dependency information for caching later
   buildAllDependencies := false;
   if (AllDependencies != null && AllDependencies->_length() == 0) {
      buildAllDependencies = true;
   }

   // hash the set of project file names into a table
   boolean InFilesHashTab:[];
   for (j:=0; j<Files._length(); ++j) {
      InFilesHashTab:[_file_case(_strip_filename(Files[j],'PE'))]=true;
   }

   int temp_view_id,orig_view_id;
   int status=_open_temp_view(WorkspaceFilename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   _str FileTable:[];
   _str line='';
   _str FileTitle='';
   _str Filename='';
   _str PackageNumber='';
   _str projname='';
   top();up();
   for (;;) {
      status=search('^Project\: "?@"?@ - Package Owner=\<?@\>$','@rhi>');
      if (status) {
         break;
      }
      get_line(line);
      parse line with 'Project: "' FileTitle '"=' Filename ' - Package Owner=<'PackageNumber'>';
      //////////////////////////////////////////////////////////////////////////
      //This looks really weird, but its so that we get the file in a format
      //that is consistent with the way we get the rest of our file
      _str WorkspacePath=_strip_filename(WorkspaceFilename,'N');
      Filename=absolute(Filename,WorkspacePath);
      Filename=relative(Filename,WorkspacePath);
      FileTable:[FileTitle]=Filename;
      buildTheseDependencies := InFilesHashTab._indexin(_file_case(FileTitle));
      if (!buildTheseDependencies && !buildAllDependencies) {
         continue;
      }
      status=search('^Package=\<'PackageNumber'\>$','@rhi');
      if (!status) {
         down();
         get_line(line);
         if (line=='{{{') {
            for (;;) {
               status=search('(^ @Project_Dep_Name )|(^\}\}\}$)','@rhi>');
               if (!status) {
                  get_line(line);
                  if (line!='}}}') {
                     parse line with 'Project_Dep_Name 'projname;
                     FilenameCased := _file_case(Filename);
                     if (buildTheseDependencies) {
                        if (Dependencies._indexin(FilenameCased)) {
                           Dependencies:[FilenameCased] :+= ' 'always_quote_filename(projname);
                        } else {
                           Dependencies:[FilenameCased] = always_quote_filename(projname);
                        }
                     }
                     if (buildAllDependencies) {
                        if (AllDependencies->_indexin(FilenameCased)) {
                           (*AllDependencies):[FilenameCased] :+= ' 'always_quote_filename(projname);
                        } else {
                           (*AllDependencies):[FilenameCased] = always_quote_filename(projname);
                        }
                     }
                  } else {
                     break;
                  }
               } else {
                  break;
               }
            }
         }
      }
   }

   // clean up dependency list to only include projects that exist
   typeless t;
   for (t._makeempty();;) {
      Dependencies._nextel(t);
      if (t._varformat()==VF_EMPTY) {
         break;
      }
      _str deps=Dependencies:[t];
      _str newstr='';
      for (;;) {
         _str cur=strip(parse_file(deps),'B','"');
         if (cur=='') {
            break;
         }
         if (FileTable._indexin(cur)) {
            //newstr=newstr' 'FileTable:[strip(cur,'B','"')];
            newstr=newstr' 'maybe_quote_filename(FileTable:[strip(cur,'B','"')]);
         }
      }
      Dependencies:[t]=newstr;
   }

   // clean up dependency list to only include projects that exist
   if (buildAllDependencies) {
      for (t._makeempty();;) {
         AllDependencies->_nextel(t);
         if (t._varformat()==VF_EMPTY) {
            break;
         }
         _str deps=(*AllDependencies):[t];
         _str newstr='';
         for (;;) {
            _str cur=strip(parse_file(deps),'B','"');
            if (cur=='') {
               break;
            }
            if (FileTable._indexin(cur)) {
               //newstr=newstr' 'FileTable:[strip(cur,'B','"')];
               newstr=newstr' 'maybe_quote_filename(FileTable:[strip(cur,'B','"')]);
            }
         }
         (*AllDependencies):[t]=newstr;
      }
   }

   //debugvar(Dependencies);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

/**
 * Takes a list of project files <B>that must be relative to the
 * workspace file</B> and fills in a hashtable with a space
 * delimited list of files that each file depends on.  Only project
 * level dependencies are returned by this function.  This is useful
 * for updating the project toolbar which only displays project
 * level dependencies.
 * <P>
 * <B>This function is mainly used for GUI updates and backwards
 * compatibility.  The VSE project system now allows dependencies
 * to be set at a project and configuration level.  To exploit
 * this improved capability, see the _ProjectGet_Dependency*
 * functions.</B>
 * <P>
 * 
 * @param Files  List of project files that must be relative to
 *               the workspace file.
 * @param Dependencies
 *               Returns a list of files for each entry(which
 *               is a project file) a space delimited list of files
 *               that it depends on.
 * 
 * @param AllDependencies (optional) 
 *               Hashtable containing all project dependencies in
 *               the workspace.  If this is empty, it will be
 *               built on the first invocation so that it can be used
 *               to build Dependencies lists later without reparsing
 *               the solution file.
 *
 * @see _ProjectGet_DependencyProjects
 * @see _ProjectGet_DependencyProjectNodes
 * @see _ProjectGet_DependencyProjectNodesForRef
 */
void _GetDependencies(_str (&Files)[],_str (&Dependencies):[], _str (*AllDependencies):[]=null)
{
   // clear out the output list of dependencies
   Dependencies._makeempty();

   // if we have already gathered all the dependency information from
   // this workspace, then just use the dependency information instead
   // of re-opening the workspace file
   if (AllDependencies != null && (AllDependencies->_length() > 0)) {
      for (j:=0; j<Files._length(); ++j) {
         filename := _file_case(_strip_filename(Files[j],'PE'));
         if (AllDependencies->_indexin(filename)) {
            Dependencies:[filename] = (*AllDependencies):[filename];
         }
      }
      return;
   }

   if (_IsVCPPWorkspaceFilename(_workspace_filename)) {
      GetDependenciesFromVCPPWorkspaceFile(_workspace_filename,Files,Dependencies,AllDependencies);
      return;
   }
   if (_IsVisualStudioWorkspaceFilename(_workspace_filename)) {
      GetDependenciesFromVisualStudioWorkspaceFile(_workspace_filename,Files,Dependencies,AllDependencies);
      return;
   }
   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      GetDependenciesEclipseWorkspaceFile(_workspace_filename,Files,Dependencies);
      return;
   }
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      return;
   }
   int i;
   for (i=0;i<Files._length();++i) {
      // although VSE project dependencies can now be defined at a project and
      // configuration level, it is safe to just list the projects for this function
      _str DependencyProjects[];
      _str deplist=_ProjectGet_DependencyProjectsList(_ProjectHandle(_AbsoluteToWorkspace(Files[i])));

      Dependencies:[_file_case(Files[i])]=deplist;
   }
}

/**
 * Lists dependencies for the current project and allows you to modify 
 * the dependencies.
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
 * 
 */ 
_command int workspace_dependencies(_str Project=_project_name) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT)
{
   _macro_delete_line();
   if (_workspace_filename=='') {
      _message_box(nls('No workspace open'));
      return(FILE_NOT_FOUND_RC);
   }
   boolean DisableTree=false;
   _str Files[]=null,Dependencies:[]=null;
   int status=_GetWorkspaceFiles(_workspace_filename,Files);
   if (status) {
      return(status);
   }
   // dependencies for associated workspaces are assumed to be project level
   // dependencies.  they will be presented read-only using the old dependencies
   // dialog that VSE originally used.
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      _GetDependencies(Files,Dependencies);
      DisableTree=true;
      status=show('-modal _workspace_dependencies_form',Files,Dependencies,Project,false,DisableTree);
      if (status!='') {
         //toolbarUpdateWorkspaceList();
         toolbarUpdateDependencies();
      }
   } else {
      // dependencies in VSE can now be set at both project and configuration
      // level.  open the project properties dialog to the dependencies tab
      // to edit them.
      project_edit(PROJECTPROPERTIES_TABINDEX_DEPENDENCIES " " Project);
      toolbarUpdateDependencies();
   }
   return(0);
}

//9:59am 7/29/1999
//For now, let's force users to open workspace files directly and see how that
//works.
/*_command int workspace_associate()
{
   //_message_box(nls("Associating VC++ Workspaces not supported in Beta 1"));
   //return(1);
   if (_workspace_filename=='') {
      return(STRING_NOT_FOUND_RC);
   }
   _str VendorWorkspace='';
   _str VendorWorkspaceType='';
   _ini_get_value(_workspace_filename,"ASSOCIATION","workspacefile",VendorWorkspace,'');
   _ini_get_value(_workspace_filename,"ASSOCIATION","workspacetype",VendorWorkspaceType,'');
   _param1=0;
   _str DirectionsCaption="To dynamically associate a VC++ workspace to a VSE workspace, click \"Associate...\"\n\nClick \"Disassociate\" to disassociate a workspace from a VC++ workspace.";
   result=show('-modal _makefile_form',_workspace_filename,VendorWorkspace"\t"VendorWorkspaceType,"Workspace");
   if (result=='') {
      if (_param1==1) {//Broke association
         _ini_set_value(_workspace_filename,"ASSOCIATION","workspacefile",'');
         _ini_set_value(_workspace_filename,"ASSOCIATION","workspacetype",'');
         toolbarUpdateWorkspaceList();
         return(0);
      }
      //Shouldn't get here...
      return(COMMAND_CANCELLED_RC);
   }
   parse result with NewVendorWorkspace "\t" NewVendorWorkspaceType;

   if (NewVendorWorkspace!=VendorWorkspace ||
       NewVendorWorkspaceType!=VendorWorkspaceType) {
      _ini_set_value(_workspace_filename,"ASSOCIATION","workspacefile",VendorWorkspace);
      _ini_set_value(_workspace_filename,"ASSOCIATION","workspacetype",VendorWorkspaceType);
      toolbarUpdateWorkspaceList();
   }

   return(0);
}*/

#define PROJECTNEWDIR_MODIFY  ctlProjectNewDir.p_user
defeventtab _workspace_dependencies_form;

#define gFiles                         ctlok.p_user
#define gDependencies                  ctltree1.p_user
#define gNoOnChange                    ctlProjectList.p_user
#define gLastProject                   ctllabel1.p_user
#define gStrippedNames                 p_active_form.p_user
#define gOrigDependencies              ctlhelp.p_user
#define RETURN_DEPENDENCIES_IN_HASHTAB ctllabel2.p_user

static boolean FileDependsOn(_str File1,_str File2,_str Dependencies:[])
{
   File2Cased := _file_case(File2);
   if (!Dependencies._indexin(File2Cased)) return(0);
   _str Deps = Dependencies:[File2Cased];
   for (;;) {
      _str cur=parse_file(Deps,false);
      if (cur._varformat()==VF_EMPTY ||cur=='') {
         break;
      }
      if (file_eq(File1,cur)) {
         return(1);
      }
      if (FileDependsOn(File1,cur,Dependencies)) {
         return(1);
      }
   }
   return(0);
}

static boolean FileImmediatelyDependsOn(_str File1,_str File2,
                                        _str Dependencies:[])
{
   File2Cased := _file_case(File2);
   if (!Dependencies._indexin(File2Cased)) return(0);
   _str Deps=Dependencies:[File2Cased];
   for (;;) {
      _str cur=parse_file(Deps,false);
      if (cur._varformat()==VF_EMPTY || cur=='') {
         break;
      }
      if (file_eq(File1,cur)) {
         return(1);
      }
   }
   return(0);
}


void ctlProjectList.on_change(int reason)
{
   if (gNoOnChange==1) {
      return;
   }
   int wid=p_window_id;
   _nocheck _control ctltree1;
   p_window_id=ctltree1;
   _str Files[],Dependencies:[];
   Files=gFiles;
   Dependencies=gDependencies;
   int state=0,bm1=0,bm2NOLONGERUSED=0;
   _str Filename='';

   if (gLastProject!='') {
      //Set the deps for the last one
      _str OldDeps='';
      int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for (;;) {
         if (index<0) {
            break;
         }
         if (_TreeGetCheckState(index)) {
            _str cap=_TreeGetCaption(index);
            parse cap with "\t" Filename;
            OldDeps=OldDeps' 'always_quote_filename(Filename);
         }
         index=_TreeGetNextSiblingIndex(index);
      }
      OldDeps=strip(OldDeps);
      Dependencies:[_file_case(gLastProject)]=OldDeps;
   }
   gDependencies=Dependencies;

   _TreeDelete(TREE_ROOT_INDEX,'C');
   //Fill in new deps
   _str StrippedNames:[];
   StrippedNames=gStrippedNames;
   int cbindex=0;
   int i;
   for (i=0;i<Files._length();++i) {
      if (!file_eq(Files[i],StrippedNames:[ctlProjectList.p_text]) &&
          !FileDependsOn(StrippedNames:[ctlProjectList.p_text],Files[i],Dependencies)) {
         treeIndex := _TreeAddItem(TREE_ROOT_INDEX,
                                   _strip_filename(GetProjectDisplayName(Files[i]),'P')"\t"GetProjectDisplayName(Files[i]),
                                   TREE_ADD_AS_CHILD,
                                   -1,
                                   -1,
                                   -1);
         _TreeSetCheckable(treeIndex,1,0);
         if (FileImmediatelyDependsOn(GetProjectDisplayName( Files[i]),GetProjectDisplayName( StrippedNames:[ctlProjectList.p_text]),Dependencies)) {
            _TreeSetCheckState(treeIndex,TCB_CHECKED);
         } else {
            _TreeSetCheckState(treeIndex,TCB_UNCHECKED);
         }
      }
   }
   if (Files._length()) {
      _TreeSortCaption(TREE_ROOT_INDEX,'F');
      _TreeTop();
   }
   _TreeRefresh();
   p_window_id=wid;
   gLastProject=StrippedNames:[p_text];
}

void projectListTreeCheckToggle(int index)
{
   int state=0,bm1=0,bm2NOLONGERUSED=0;
   if ( !ctlok.p_enabled ) {
      _str ErrorMessage=nls("You cannot change these settings because this is an asssociated workspace.");
      _str workspacetype=_WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
      if (workspacetype == JBUILDER_VENDOR_NAME) {
         // no op
      } else if (workspacetype!='') {
         _str line2='You must change these settings in';
         for (;;) {
            _str cur;
            parse workspacetype with cur workspacetype;
            if (cur=='') {
               break;
            }
            line2=line2' '_Capitalize(cur);
         }
         line2=line2'.';
         ErrorMessage=ErrorMessage"\n"line2;
      }
      _message_box(ErrorMessage);
   }
}

int ctltree1.on_change(int reason,int index)
{
   switch ( reason ) {
   case CHANGE_CHECK_TOGGLED:
      projectListTreeCheckToggle(index);
      break;
   }
   return 0;
}

/**
 * Capitalizes the first letter of <B>word</B>
 *
 * @param word   Word to capitalize
 *
 * @return "Capitalized" version of <B>word</B>
 */
_str _Capitalize(_str word)
{
   return(upcase(substr(word,1,1)):+substr(word,2));
}

void ctltree1.ENTER()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}


void ctlok.on_create(_str Files[],_str Dependencies:[],_str Project,
                     boolean ReturnHashTab=false,boolean DisableTree=false)
{
   if (ReturnHashTab) {
      RETURN_DEPENDENCIES_IN_HASHTAB=1;
   }
   int wid=p_window_id;
   gNoOnChange=1;
   p_window_id=ctlProjectList;
   _str StrippedNames:[];
   int i;
   for (i=0;i<Files._length();++i) {
      _str CurStrippedName=_strip_filename(GetProjectDisplayName(Files[i]),'P');
      StrippedNames:[CurStrippedName]=Files[i];
      _lbadd_item(CurStrippedName);
   }
   gStrippedNames=StrippedNames;

   _lbsort();
   _lbtop();
   status := _lbfind_and_select_item(GetProjectDisplayName(_strip_filename(Project,'P')),_fpos_case);
   p_window_id=wid;
   gNoOnChange=0;
   gFiles=Files;
   gDependencies=Dependencies;
   gOrigDependencies=Dependencies;

   int longestName=0;
   int longestPath=0;
   for (i=0;i<Files._length();++i) {
      int curwidth=_text_width(_strip_filename(GetProjectDisplayName(Files[i]),'P'));
      if (curwidth>longestName) {
         longestName=curwidth;
      }
      curwidth=_text_width(Files[i]);
      if (curwidth>longestPath) {
         longestPath=curwidth;
      }
   }

   int oldwidth=0;
   ctltree1._TreeColWidth(0,longestName+100);
   if (longestName+longestPath+750>ctltree1.p_width) {

      oldwidth=ctltree1.p_width;

      ctltree1.p_width=longestName+longestPath+750;

      int diff=ctltree1.p_width-oldwidth;

      ctlhelp.p_x=ctlok.p_x=ctlok.p_next.p_x=ctlok.p_x+diff;
      ctlProjectList.p_width=ctltree1.p_width;
      p_active_form.p_width+=diff;
   }
   ctlProjectList.call_event(CHANGE_SELECTED,-1,ctlProjectList,ON_CHANGE,'W');
   if (DisableTree) {
      ctlok.p_enabled=0;
   }
}

//11:56am 8/18/1999
//Made global for macro recording
int _WriteDependencies(_str Dependencies:[],_str OrigDependencies:[]=null)
{
   _str ProjectName='';
   typeless i;
   for (i._makeempty();;) {
      Dependencies._nextel(i);
      if (i._isempty()) {
         break;
      }
      //Don't have to do always_quote_filename on the right here because the list
      //is built that way in ctlProjectList.on_change
      i=translate(_file_case(i),FILESEP,FILESEP2);
      _str deplist=strip(Dependencies:[i]);
      if (OrigDependencies._indexin(i) && file_eq(strip(OrigDependencies:[i]),deplist)) {
         continue;
      }
      ProjectName=_AbsoluteToWorkspace(i);
      _ProjectSet_DependencyProjectsList(_ProjectHandle(ProjectName),deplist);
      _ProjectSave(_ProjectHandle(ProjectName));
   }
   _maybeGenerateMakefile(ProjectName);
   return(0);
}

int ctlok.lbutton_up()
{
   ctlProjectList.call_event(CHANGE_SELECTED,ctlProjectList,ON_CHANGE,'W');
   _str Dependencies:[];
   Dependencies=gDependencies;
   if (RETURN_DEPENDENCIES_IN_HASHTAB==1) {
      _param1=Dependencies;
      p_active_form._delete_window(0);
      return(0);
   }

   int was_recording=_macro();
   _macro('M',_macro('S'));
   AddMacroRecordingForHashtab(Dependencies,'Dependencies');
   int status=_WriteDependencies(Dependencies,gOrigDependencies);
   _macro_append('_WriteDependencies(Dependencies);');
   _macro('M',was_recording);
   if (status) {
      _message_box(nls('Could not write to workspace file %s.\n\n%s',_workspace_filename,get_message(status)));
   }
   p_active_form._delete_window(0);
   return(0);
}

boolean _project_save_restore_done;
int _srg_workspace(_str option='',_str info='')
{
   // If restoring with no files or restoring with files
   typeless Noffiles,rest;
   _str WorkspaceName='';
   _str ProjectName='';
   _str filename='';
   int i,status=0;

   if (option=='N' || option=='R') {
      // Only restore project if user has selected to restore current directory
      parse info with Noffiles rest;
      _str tempWkspaceName=parse_file(rest,false);
      WorkspaceName=_xcode_strip_pbxproj(tempWkspaceName);
      ProjectName=parse_file(rest,false);
      if (ProjectName=='' && file_eq(_get_extension(WorkspaceName,1),PRJ_FILE_EXT)) {
         // We must be opening a VPJ file.
         ProjectName=WorkspaceName;
         _ConvertProjectToWorkspace(ProjectName);
      }
      if (!def_max_workspacehist || !_mdi.p_menu_handle || !Noffiles) {
         down(Noffiles);
      } else {
         for (i=1;i<=Noffiles;++i) {
            down();
            if (i<=def_max_workspacehist) {
               get_line(filename);
               _menu_add_workspace_hist(filename);
            }
         }
      }
      // Project could have been openned because the user specified
      // a project file name as an invocation argument
      // IF a project is not already openned
      if (_workspace_filename=="") {
         if (WorkspaceName!='') {
            status=_WorkspaceOpenAndUpdate(WorkspaceName);
            if (!status) {
               if (!file_exists(ProjectName)) {
                  ProjectName='';
               }
               if (ProjectName!='') {
                  _ProjectOpen(ProjectName);
               }

               //_tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
               // set any environment variables from the workspace file
               setEnvironmentFromXMLFile();
               _menu_add_workspace_hist(_workspace_filename);
               _project_refresh();
               InitProjectVC();
               toolbarRestoreState(_workspace_filename);
               restoreWorkspaceSettings('DEBUG', _workspace_filename);
               restoreWorkspaceSettings('BUFFTABS', _workspace_filename);

               // check any auto-updated tag files
               check_autoupdated_tagfiles();

               if (_project_name!='') {
                  _str new_DebugCallbackName=_ProjectGet_DebugCallbackName(_ProjectHandle(),gActiveConfigName);
                  // DJB 03-18-2008
                  // Integrated .NET debugging is no longer available as of SlickEdit 2008
                  if (new_DebugCallbackName=="dotnet") new_DebugCallbackName="";
                  if (new_DebugCallbackName!=_project_DebugCallbackName) {
                     _project_DebugCallbackName=new_DebugCallbackName;
                     _DebugUpdateMenu();
                  }
               }
#if !__UNIX__
               _init_vcpp();
#endif
            }
         }
      }

   } else {
      if (_project_save_restore_done) {
         return(0);
      }
      //2:30pm 10/29/1998
      //arg(1) is not used
      //The 'X' as the second argument means that we are just saving project
      //information. '' as the 3rd argument means do not refresh tag files
      int orig_view_id;
      get_window_id(orig_view_id);
      status=_workspace_save_state();
      activate_window(orig_view_id);
      int dash_mh=0;
      int dash_pos=0;
      int flags=0;
      _str caption='';
      _str command='';
      int count=0;
      if (def_max_workspacehist && _mdi.p_menu_handle) {
         // Look for the menu files separator
         status=_menu_find(_mdi.p_menu_handle,WKSPHIST_CATEGORY,dash_mh,dash_pos,'c');
         count=0;
         if (! status) {
            int Nofitems=_menu_info(dash_mh,'c');
            for (i=Nofitems-1; i>=dash_pos+1 ;++count,--i) {
               _menu_get_state(dash_mh,i,flags,'p',caption,command);
               parse command with . filename;
               // if on all workspaces line
               if (filename=='') {
                  --count;
               } else {
                  _str strippedFilename=strip(filename,'B',"\"");
                  _str correctedFilename=_xcode_strip_pbxproj(strippedFilename);
                  insert_line(correctedFilename);
               }
            }
            up(count);
         }
      }
      insert_line("WORKSPACE: "count" "maybe_quote_filename(_workspace_filename)' 'maybe_quote_filename(_project_name));
      down(count);
   }
   return(0);
}

static int getUse32BitSCCDLLMessage(_str workspaceFilename,_str projectFilename,int &value)
{
   value = 0;
   _str valueStr;
   int status = _GetVCSItemInWorkspaceState(workspaceFilename,projectFilename,projectFilename'_SCC32Warning',valueStr);
   if ( isinteger(valueStr) ) value = (int)valueStr;
   return status;
}

static int setUse32BitSCCDLLMessage(_str workspaceFilename,_str projectFilename,int newValue)
{
   return _SetVCSItemInWorkspaceState(workspaceFilename,projectFilename,projectFilename'_SCC32Warning',newValue);
}

static int InitProjectVC()
{
   if (_isscc(def_vc_system) && machine()=='WINDOWS') {
      _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
      _str vcs=substr(def_vc_system,5);
      int status=0;
      if (vcs!=_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)) {
         status=_SccInit(vcs);
         if (status) {
            if ( status==VSSCC_ERROR_MAY_BE_32_BIT_DLL_RC && machine_bits()==64 ) {
               status = getUse32BitSCCDLLMessage(_workspace_filename,_project_name,auto value=0);
               if ( status || !value ) {
                  // If we could not retrieve the value (probably because it has
                  // not been written yet) or the value is 0

                  _str caption1 = nls("Could not initialize %s",vcs);
                  _str caption2 = get_message(VSSCC_ERROR_MAY_BE_32_BIT_DLL_RC);
                  int result = textBoxDialog("Unable to initialize SCC provider",
                                             0,
                                             0,
                                             "",
                                             nls("OK,Cancel:_cancel\t-html %s\n-html %s",caption1,caption2),
                                             "",
                                             '-checkbox Do not ask me again:0');
                  doNotPrompt := 0;
                  if ( result==1 && _param1==1 ) {
                     // User pressed OK and "Do not ask me again" was checked
                     doNotPrompt = 1;
                  }
                  setUse32BitSCCDLLMessage(_workspace_filename,_project_name,doNotPrompt);
               }
            } else {
               _message_box(nls("Could not initialize %s",vcs));
            }
            return(status);
         }
      }
      _str vcslocalpath=_ProjectGet_VCSLocalPath(_ProjectHandle());
      _str vcsauxpath=_ProjectGet_VCSAuxPath(_ProjectHandle());

      //Order is important here...
      vcsproject=substr(vcsproject,SCC_PREFIX_LENGTH+1);
      vcslocalpath=substr(vcslocalpath,SCC_PREFIX_LENGTH+1);

      _str prjvcs='';
      if (substr(vcsproject,1,length(vcs':'))==vcs:+':') {
         prjvcs=substr(vcsproject,1,length(vcs));
         vcsproject=substr(vcsproject,length(vcs':')+1);
      }

      _str localpathvcs='';
      if (substr(vcslocalpath,1,length(vcs':'))==vcs:+':') {
         localpathvcs=substr(vcslocalpath,1,length(vcs));
         vcslocalpath=substr(vcslocalpath,length(vcs':')+1);
      }

      //vcsproject=MaybeStripLeadingVCSName(vcsproject,prjvcs);
      //vcslocalpath=MaybeStripLeadingVCSName(vcslocalpath,localpathvcs);

      if (prjvcs==vcs && localpathvcs==vcs && vcsproject!='') {
         //use project and local_path because they are the stripped versions(no SCC:)
         status=_SccOpenProject(0,'',vcsproject,vcslocalpath,vcsauxpath);
         if (status) {
            //10:46am 11/30/1999
            //If there is a SCC project open already, we just want to close
            //it and then try to open the project again.
            if (status==VSSCC_E_PROJECTALREADYOPEN_RC) {
               _SccCloseProject();
               status=_SccOpenProject(0,'',vcsproject,vcslocalpath,vcsauxpath);
            }
            if (status) {
               _message_box(nls("Could not open %s project %s",vcs,vcsproject));
               _SccCloseProject();
            }
            //return(status);
            //don't want to stop restore...
         }
      }
   }
   return(0);
}
static boolean vstudioIsExpressEdition(_str target_version,_str productName) {

#if !__UNIX__
      _str DEVENVDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\VisualStudio\\":+target_version:+"\\Setup\\VS","","EnvironmentDirectory");
      if (DEVENVDIR=='') {
         DEVENVDIR=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\":+productName:+"\\":+target_version,"","InstallDir");
         if (DEVENVDIR!='') {
            return true;
         }
      }
#endif
   return false;
}

static _str GetCompilerPackage(_str WorkspaceType,_str Version='-1',_str ProjectName='')
{
   switch (lowcase(WorkspaceType)) {
   case ECLIPSE_VENDOR_NAME:
      return('Java - Eclipse');
   case VISUAL_STUDIO_VENDOR_NAME:
      _str ext=_get_extension(ProjectName,true);
      if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
          file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT) ||
          file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
         // >=2008
         if (Version>=9 && vstudioIsExpressEdition(Version,"VCExpress")) {
            return('Microsoft Visual Studio Express  >= 2008 VC++');
         }
         return('Microsoft Visual Studio  >= 7.0 VC++');
      } else if (file_eq(ext,VISUAL_STUDIO_VB_PROJECT_EXT)) {
         if (Version>=9 && vstudioIsExpressEdition(Version,"VBExpress")) {
            return('Microsoft Visual Studio Express  >= 2008 Visual Basic');
         }
         return('Microsoft Visual Studio  >= 7.0 Visual Basic');
      } else if (file_eq(ext,VISUAL_STUDIO_CSHARP_PROJECT_EXT)) {
         if (Version>=9 && vstudioIsExpressEdition(Version,"VCSExpress")) {
            return('Microsoft Visual Studio Express  >= 2008 C#');
         }
         return('Microsoft Visual Studio  >= 7.0 C#');
      } else if (file_eq(ext,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT)) {
         /*if (Version>=9 && vstudioIsExpressEdition(Version)) {
            return('Microsoft Visual Studio Express  >= 2008 C# Device');
         } */
         return('Microsoft Visual Studio  >= 7.0 C# Device');
      } else if (file_eq(ext,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT)) {
         /*if (Version>=9 && vstudioIsExpressEdition(Version)) {
            return('Microsoft Visual Studio Express  >= 2008 Visual Basic Device');
         } */
         return('Microsoft Visual Studio  >= 7.0 Visual Basic Device');
      } else if (file_eq(ext,VISUAL_STUDIO_JSHARP_PROJECT_EXT)) {
         return('Microsoft Visual Studio  >= 7.0 J#');
      } else if (file_eq(ext,VISUAL_STUDIO_FSHARP_PROJECT_EXT)) {
         return('Microsoft Visual Studio  >= 7.0 F#');
      } else if (file_eq(ext,VISUAL_STUDIO_TEMPLATE_PROJECT_EXT)) {
         return('Microsoft Visual Studio  >= 7.0 Enterprise Template');
      } else if (file_eq(ext,VISUAL_STUDIO_DATABASE_PROJECT_EXT)) {
         return('Microsoft Visual Studio  >= 7.0 Database');
      } else {
         // This should never happen.
         // Returning the VC++ pkg may not be right, but it will
         // keep us from getting Slick-C stacks.
         if (Version>=9 && vstudioIsExpressEdition(Version,"VCExpress")) {
            return('Microsoft Visual Studio Express >= 7.0 VC++');
         }
         return('Microsoft Visual Studio  >= 7.0 VC++');
      }
   case VCPP_EMBEDDED_VENDOR_NAME:
      return('Microsoft Embedded Tools for 32 bit Windows >= 6.0');
   case VCPP_VENDOR_NAME:
      if (Version!=5) {
         return('Microsoft Visual C++ for 32 bit Windows >= 6.0');
      }
      return('Microsoft Visual C++ for 32 bit Windows');
   case TORNADO_VENDOR_NAME:
#if __UNIX__
      return('Tornado for UNIX');
#else
      if (Version>=3) {
         return('Tornado for Windows >= 3.0');
      } else {
         return('Tornado for Windows');
      }
#endif
   case JBUILDER_VENDOR_NAME:
      return "Java - Borland JBuilder";
   case XCODE_WKSPACE_VENDOR_NAME:
   case XCODE_PROJECT_VENDOR_NAME:
      return "Apple Xcode";
   case MACROMEDIA_FLASH_VENDOR_NAME:
      return "Macromedia Flash";
   }
   return('');
}

static int GetWorkspaceVersion(_str WorkspaceFilename,_str WorkspaceType,int &Version)
{
   int status=0;
   int temp_view_id=0;
   int orig_view_id=0;
   _str line='';

   switch (lowcase(WorkspaceType)) {
   case VCPP_VENDOR_NAME:
      {
         Version=-1;
         status=_open_temp_view(WorkspaceFilename,temp_view_id,orig_view_id);
         if (status) return(status);
         top();
         get_line(line);
         //Microsoft Developer Studio Workspace File, Format Version 6.00
         _str VersionStr='';
         parse line with "Microsoft Developer Studio Workspace File, Format Version " VersionStr;
         Version=(int)substr(VersionStr,1,1);
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
         return(0);
      }
   case TORNADO_VENDOR_NAME:
      {
         status=_open_temp_view(WorkspaceFilename,temp_view_id,orig_view_id);
         if (status) return(status);
         top();
         status=search('^\<BEGIN\> CORE_INFO_VERSION$','@rh');
         if (status) {
            //Assume the latest version
            Version=TORNADO_LATEST_VERSION;
         } else {
            down();
            get_line(line);
            _str MajorVersion,MinorVersion;
            parse line with MajorVersion '.' MinorVersion;
            Version=(int)MajorVersion;
         }
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
         return(0);
      }
   default:
      Version=-1;
      return(-1);
   }
   return(0);
}

static void MaybeStripTrailing(_str &string,_str item)
{
   if (substr(string,(length(string)+1)-length(item),length(item)) == item) {
      string=substr(string,1,length(string)-length(item));
   }
}

static _str GetVSEWorkspaceNameFromEclipsePath(_str VendorWorkspacePath,_str FileExt=WORKSPACE_FILE_EXT)
{
   if (isdirectory(VendorWorkspacePath)) {
      _maybe_append_filesep(VendorWorkspacePath);
   }
   _str path=VendorWorkspacePath;
   MaybeStripTrailing(path,FILESEP);
   path=_strip_filename(path,'N');

   MaybeStripTrailing(path,FILESEP);
   path=_strip_filename(path,'p');
   if (path=='') {
      path='workspace';
   }

   return(_file_path(VendorWorkspacePath):+path:+FileExt);
}

static _str getVSEWorkspaceAssociationType(_str filename)
{
   _str associatedFileType = "";

   // check the AssociatedFileType attribute in the workspace
   if (_workspace_filename != "" && file_eq(_workspace_filename, filename)) {
      // workspace already cached
      associatedFileType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);
   } else {
      // open the file
      int status = 0;
      int handle = _xmlcfg_open(filename, status);
      if (handle < 0) return false;

      associatedFileType = _WorkspaceGet_AssociatedFile(handle);

      // close the file
      _xmlcfg_close(handle);
   }

   // associatedFileType will be blank for vse workspaces
   return associatedFileType;
}

/**
 * Associate the specified workspace with a SlickEdit workspace.
 *
 * If the vendor application has both workspaces and projects, there will
 * be a VSE workspace created for the vendor workspace and a VSE project
 * created for each vendor project in the vendor workspace.  The VSE
 * workspace will not physically contain any VSE projects.
 *
 * If the file is a project from a system that does not have workspaces,
 * a VSE workspace will be created and VendorWorkspaceName will be changed
 * to be that new workspace.  In this case, there is no way to track the
 * vendor projects so the associated VSE project must be physically
 * inserted into the VSE workspace.
 *
 * insertIntoCurrentWorkspace is only valid for projects from systems
 * that do not have workspaces.  It is ignored otherwise.
 */
int _WorkspaceAssociate(_str& VendorWorkspaceName, boolean insertIntoCurrentWorkspace = false)
{

 
   boolean IsEclipse=_IsEclipseWorkspaceFilename(VendorWorkspaceName);
   _str vendorProjectNameHasNoWorkspace = "";

   // if this is a VSE workspace, then it is being used to support
   // association with a system that does not have workspaces.  figure
   // out which system that is and the original project file that was
   // opened by checking the association type and then replacing the
   // .vpw with the appropriate project extension for that system.  the
   // first reaction would be to just return but we have most likely
   // gotten here due to _MaybeRetagWorkspace() which means the date
   // changed on the vendor project file.  therefore, the project has
   // to be rescanned.
   if (_IsVSEWorkspaceFilename(VendorWorkspaceName)) {
      _str vsewAssocType = getVSEWorkspaceAssociationType(VendorWorkspaceName);
      switch (vsewAssocType) {
      case JBUILDER_VENDOR_NAME:
         VendorWorkspaceName = _strip_filename(VendorWorkspaceName, "E") :+ JBUILDER_PROJECT_EXT;
         break;

      default:
         return -1;
      }
   }

   _ProjectCache_Update();
   _str WorkspaceType;
   boolean lookForDebugConfig=false;
   if (_IsVCPPWorkspaceFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[VCPP_PROJECT_WORKSPACE_EXT];
      lookForDebugConfig=true;
   } else if (_IsVisualStudioWorkspaceFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[VISUAL_STUDIO_SOLUTION_EXT];
      lookForDebugConfig=true;
   } else if (_IsTornadoWorkspaceFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[TORNADO_WORKSPACE_EXT];
   } else if (_IsEmbeddedVCPPWorkspaceFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT];
      lookForDebugConfig=true;
   } else if (_IsXcodeProjectFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[XCODE_PROJECT_LONG_BUNDLE_EXT];
   } else if (_IsXcodeWorkspaceFilename(VendorWorkspaceName)) {
      WorkspaceType=VendorNameTable:[XCODE_WKSPACE_BUNDLE_EXT];
   } else if (IsEclipse) {
      WorkspaceType=VendorNameTable:[ECLIPSE_WORKSPACE_FILE_EXT];
   } else if (_IsJBuilderProjectFilename(VendorWorkspaceName)) {
      // jbuilder has no workspace so the variable passed in
      // is actually a project.  remember that project name for
      // use later and change it to a vse workspace
      WorkspaceType = JBUILDER_VENDOR_NAME;
      vendorProjectNameHasNoWorkspace = VendorWorkspaceName;
      if (insertIntoCurrentWorkspace && _workspace_filename != "") {
         VendorWorkspaceName = _workspace_filename;
      } else {
         VendorWorkspaceName = VSEWorkspaceFilename(vendorProjectNameHasNoWorkspace);
      }
   } else if (_IsFlashProjectFilename(VendorWorkspaceName)) {
      // flash has no workspace so the variable passed in
      // is actually a project.  remember that project name for
      // use later and change it to a vse workspace
      WorkspaceType = MACROMEDIA_FLASH_VENDOR_NAME;
      vendorProjectNameHasNoWorkspace = VendorWorkspaceName;
      if (insertIntoCurrentWorkspace && _workspace_filename != "") {
         VendorWorkspaceName = _workspace_filename;
      } else {
         VendorWorkspaceName = VSEWorkspaceFilename(vendorProjectNameHasNoWorkspace);
      }
   }
   boolean workspace_create = false;
   int status=0;
   
   _str VSEWorkspaceName='';
   int workspace_handle;
   VSEWorkspaceName=VSEWorkspaceFilename(VendorWorkspaceName);

   if (!file_exists(VSEWorkspaceName)) {
      workspace_create = true;
   } else {
      workspace_handle=_xmlcfg_open(VSEWorkspaceName,status);
      if (workspace_handle<0) {
         status=_WorkspaceConvert70ToXML(VSEWorkspaceName);
         if (status) {
            return(status);
         }
         workspace_handle=_xmlcfg_open(VSEWorkspaceName,status);
         if (workspace_handle<0) {
            return(workspace_handle);
         }
      }
      // check for unexpected problems
      if (_xmlcfg_get_path(workspace_handle,VPWX_WORKSPACE,"AssociatedFile") != _NormalizeFile(relative(VendorWorkspaceName,_strip_filename(VSEWorkspaceName,'N'))) ||
          _xmlcfg_get_path(workspace_handle,VPWX_WORKSPACE,"AssociatedFileType") != WorkspaceType) {
         
         _str msg = nls('This workspace already exists, but is not associated with "%s".  Do you wish to overwrite workspace with associated workspace name?',
                        _NormalizeFile(relative(VendorWorkspaceName,_strip_filename(VSEWorkspaceName,'N'))));
         int result = _message_box(msg, '', MB_OKCANCEL|MB_ICONQUESTION);
         if (result == IDOK) {
            _xmlcfg_close(workspace_handle);
            workspace_create = true;
         } else {
            message('Workspace not opened. Command cancelled.');
            _xmlcfg_close(workspace_handle);
            return (COMMAND_CANCELLED_RC);
         }
      }
   }

   if (workspace_create) {
      workspace_handle=_WorkspaceCreate(VSEWorkspaceName);
      _xmlcfg_set_path(workspace_handle,VPWX_WORKSPACE,'AssociatedFile',_NormalizeFile(relative(VendorWorkspaceName,_strip_filename(VSEWorkspaceName,'N'))));
      _xmlcfg_set_path(workspace_handle,VPWX_WORKSPACE,'AssociatedFileType',WorkspaceType);
      if (status) {
         _xmlcfg_close(workspace_handle);
         return(status);
      }

      if (WorkspaceType == MACROMEDIA_FLASH_VENDOR_NAME) {
#if !__UNIX__
         _WorkspaceSet_EnvironmentVariable(workspace_handle, 'FLASHIDE', _flash_get_ide_path());
#endif
      }
   }

   _str ProjectNames[]=null;
   _str VendorProjectNames[]=null;
   status=_GetWorkspaceFilesH(workspace_handle,ProjectNames,VendorProjectNames);
   if (_xmlcfg_get_modify(workspace_handle)) {
      _WorkspaceSave(workspace_handle);
   }

   // if this is a system without workspaces, the vpj and vendor project
   // must be inserted into the list
   if (vendorProjectNameHasNoWorkspace != "") {
      ProjectNames[ProjectNames._length()] = _strip_filename(vendorProjectNameHasNoWorkspace, "E") :+ PRJ_FILE_EXT;
      VendorProjectNames[VendorProjectNames._length()] = vendorProjectNameHasNoWorkspace;
   }

   boolean reset_active_project = true;
   _str cur_project_name = '';
   _ini_get_value(VSEWorkspaceStateFilename(VendorWorkspaceName), "Global", "CurrentProject", cur_project_name);

   _str WorkspacePath=_strip_filename(VSEWorkspaceName, 'N');
   int i;
   _str vstudioWorkspaceVersion='';
   int WorkspaceVersion=-1;
   if (WorkspaceType==VISUAL_STUDIO_VENDOR_NAME) {
      _str version='';
      version = vstudio_application_version(VendorWorkspaceName);
      if (version!='' && isnumber(version)) {
         vstudioWorkspaceVersion=version;
      }
   }

   int prjpacks_handle=_ProjectOpenTemplates();
   for (i=0;i<ProjectNames._length();++i) {
      _str Compiler='';
      //int WorkspaceVersion=-1;
      if (WorkspaceType==VCPP_VENDOR_NAME) {
         GetWorkspaceVersion(VendorWorkspaceName,WorkspaceType,WorkspaceVersion);
         Compiler=GetCompilerPackage(WorkspaceType,WorkspaceVersion);
      } else if (WorkspaceType==VISUAL_STUDIO_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType,vstudioWorkspaceVersion,VendorProjectNames[i]);
#if !__UNIX__
         // this is where we want to associate dotnet.vtg with C++
         AddDotNetTagFile();
#endif 
      } else if (WorkspaceType==TORNADO_VENDOR_NAME) {
         GetWorkspaceVersion(VendorWorkspaceName,WorkspaceType,WorkspaceVersion);
         Compiler=GetCompilerPackage(WorkspaceType,WorkspaceVersion,VendorProjectNames[i]);
      } else if (WorkspaceType==ECLIPSE_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType,WorkspaceVersion,VendorProjectNames[i]);
      } else if (WorkspaceType == JBUILDER_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType);
      } else if (WorkspaceType == XCODE_PROJECT_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType);
      } else if (WorkspaceType == XCODE_WKSPACE_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType);
      } else if (WorkspaceType==VCPP_EMBEDDED_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType);
      } else if (WorkspaceType==MACROMEDIA_FLASH_VENDOR_NAME) {
         Compiler=GetCompilerPackage(WorkspaceType);
      }

      //_str CurFilename=absolute(GetVendorProjectFilename(ProjectNames[i],WorkspaceType),WorkspacePath);
      _str CurFilename=absolute(VendorProjectNames[i],WorkspacePath);
      _str CurVSEFilename=absolute(ProjectNames[i],WorkspacePath);

      boolean cur_config_hashtab:[];
      _str cur_config_list[];

      int project_handle= -1;
      if (file_exists(CurVSEFilename)) {
         project_handle=_xmlcfg_open(CurVSEFilename,status);
         if (project_handle<0) {
            if (!_ini_is_valid(CurVSEFilename)) {
               delete_file(CurVSEFilename);
            } else {
               _ProjectConvert70ToXML(CurVSEFilename);
               project_handle=_xmlcfg_open(CurVSEFilename,status);
            }
         }
      }
      if (project_handle>=0) {
         _xmlcfg_find_simple_array(project_handle,VPJX_CONFIG'/@Name',cur_config_list,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
      }
      int j;
      for (j=0;j<cur_config_list._length();++j) {
         cur_config_hashtab:[lowcase(cur_config_list[j])]=true;
      }

      if (file_eq(cur_project_name, ProjectNames[i])) {
         reset_active_project = false;
      }

      if (_IsVisualStudioProjectFilename(CurFilename) ||
          file_eq('.'_get_extension(CurFilename),VCPP_PROJECT_FILE_EXT) ||
          file_eq('.'_get_extension(CurFilename),VCPP_EMBEDDED_PROJECT_FILE_EXT) ||
          file_eq('.'_get_extension(CurFilename),TORNADO_PROJECT_EXT) ||
          file_eq('.'_get_extension(CurFilename),JBUILDER_PROJECT_EXT) ||
          file_eq('.'_get_extension(CurFilename),XCODE_PROJECT_EXT)||
          file_eq('.'_get_extension(CurFilename),XCODE_PROJECT_LONG_BUNDLE_EXT)||
          file_eq('.'_get_extension(CurFilename),XCODE_PROJECT_SHORT_BUNDLE_EXT)||
          file_eq('.'_get_extension(CurFilename),MACROMEDIA_FLASH_PROJECT_EXT)) {

         _str cur_config_name='';
         _str ProjectType=WorkspaceType;
         _str CurProjectExt=_file_case(_get_extension(CurFilename,1));
         if (VendorNameTable._indexin(CurProjectExt)) {
            ProjectType=VendorNameTable:[CurProjectExt];
         }
         _str exename=_strip_filename(CurVSEFilename,'PE');


         ProjectConfig configList[]=null;
         // There is some funny manipulation of file names for Xcode to get around the
         // fact that Xcode has no analog to a project file, but only a workspace file
         // more specifically, every entry in the VendorProjectNames contains the name
         // of the workspace.  While the ProjectNames array contains the real names of
         // the projects with the vpj extenstion tacked on.  Look at these five lines.
         if (file_eq('.'_get_extension(CurFilename),XCODE_PROJECT_LONG_BUNDLE_EXT)||
             file_eq('.'_get_extension(CurFilename),XCODE_PROJECT_SHORT_BUNDLE_EXT)) {
            _xcode_get_configs(CurFilename,configList);
         } else {
            _getAssociatedProjectConfigs(absolute(VendorProjectNames[i],WorkspacePath),configList);
         }

         if (project_handle<0) {
            workspace_new_project2(CurVSEFilename,
                                   Compiler,
                                   exename,
                                   VendorWorkspaceName,
                                   false,
                                   true,
                                   CurFilename,
                                   ProjectType,
                                   true,
                                   configList);

            // if this is a system without workspaces, the vpj must be forced into
            // the vpw because there is no other way to track it
            if (vendorProjectNameHasNoWorkspace != "") {
               // see if the project is already in the workspace
               int wksProjectsNode = _WorkspaceGet_ProjectsNode(workspace_handle);
               if (wksProjectsNode < 0) {
                  // add it
                  wksProjectsNode = _xmlcfg_set_path(workspace_handle, VPWX_PROJECTS);
               }

               int projectNode = _xmlcfg_find_simple(workspace_handle, VPWX_PROJECT XPATH_FILEEQ("File", _NormalizeFile(_RelativeToWorkspace(CurVSEFilename, VSEWorkspaceName))));
               if (projectNode < 0) {
                  // add it
                  projectNode = _xmlcfg_add(workspace_handle, wksProjectsNode, VPWTAG_PROJECT, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
                  _xmlcfg_set_attribute(workspace_handle, projectNode, "File", _NormalizeFile(_RelativeToWorkspace(CurVSEFilename, VSEWorkspaceName)));
               }

               _WorkspaceSave(workspace_handle);
            }
         } else {
            //_ini_get_value(CurVSEFilename,"Configurations","activeconfig",cur_config_name);
            _ini_get_value(VSEWorkspaceStateFilename(VendorWorkspaceName), "ActiveConfig", _RelativeToWorkspace(CurVSEFilename,VendorWorkspaceName), cur_config_name,'',_fpos_case);
            parse cur_config_name with ',' cur_config_name;
            if (substr(cur_config_name,1,1)=='"') {
               _ini_set_value(VSEWorkspaceStateFilename(VendorWorkspaceName),
                              "ActiveConfig",
                              _RelativeToWorkspace(CurVSEFilename,VendorWorkspaceName),
                              ','strip(cur_config_name,'B','"'),
                              _fpos_case);
            }
            cur_config_name=strip(cur_config_name,'B','"');
            // IF this open fails we're screwed
            int Node=0;
            if (prjpacks_handle >= 0) {
               for (j=0;j<configList._length();++j) {
                  _str key=configList[j].config;
                  if (cur_config_hashtab._indexin(lowcase(key))) {
                     cur_config_hashtab._deleteel(lowcase(key));
   
                  } else if (project_handle>=0) {
                     if (cur_config_list._length()) {
                        Node=_ProjectGet_ConfigNode(project_handle,cur_config_list[0]);
                        int DestNode=_ProjectGet_ConfigNode(project_handle,cur_config_list[cur_config_list._length()-1]);
                        Node=_xmlcfg_copy(project_handle,DestNode,project_handle,Node,0);
                        //Node=_xmlcfg_get_next_sibling(project_handle,Node);
                     } else {
                        int TemplateNode=_ProjectTemplatesGet_TemplateNode(prjpacks_handle,Compiler);
                        Node=_ProjectTemplatesGet_TemplateConfigNode(prjpacks_handle,TemplateNode,'Release');
                        //_message_box('Node='Node);
                        if (Node<0) {
                           _message_box(nls("%s file missing template %s or configuration %s",VSCFGFILE_PRJTEMPLATES,Compiler,'Release'));
                        }
                        Node=_ProjectCopy_Config(project_handle,prjpacks_handle,Node);
                     }
                     _xmlcfg_set_attribute(project_handle,Node,'Name',key);
                     _xmlcfg_set_attribute(project_handle,Node,"ObjectDir",configList[j].objdir);
                     Node=_ProjectGet_TargetNode(project_handle,'execute',key);
                     _str value=_ProjectGet_TargetCmdLine(project_handle,Node);
                     value=stranslate(value,exename,"%<e");
                     _ProjectSet_TargetCmdLine(project_handle,Node,value);
   
                     Node=_ProjectGet_TargetNode(project_handle,'debug',key);
                     value=_ProjectGet_TargetCmdLine(project_handle,Node);
                     value=stranslate(value,exename,"%<e");
                     _ProjectSet_TargetCmdLine(project_handle,Node,value);
   
                  }
               }
            }
            _str key=null;
            for (;;) {
               cur_config_hashtab._nextel(key);
               if (key==null) break;
               if (strieq(cur_config_name,key)) {
                  cur_config_name='';
               }
               Node=_ProjectGet_ConfigNode(project_handle,key);
               if (Node>=0) {
                  _xmlcfg_delete(project_handle,Node);
               }
            }

            _str asf = relative(CurFilename,_strip_filename(CurVSEFilename,'N'));
            if (asf != _ProjectGet_AssociatedFile(project_handle)) {
               _ProjectSet_AssociatedFile(project_handle, asf);
            }

            if (ProjectType != _ProjectGet_AssociatedFileType(project_handle)) {
               _ProjectSet_AssociatedFileType(project_handle,ProjectType);
            }

            boolean is_standard_vcproj=_IsVisualStudioWorkspaceFilename(VendorWorkspaceName) &&
                                       (GetVSStandardAppName(_get_extension(CurFilename,true)):!='');

            Node=_ProjectGet_FilesNode(project_handle,(is_standard_vcproj)?true:false);
            if (Node>=0) {
               // Since we support the AutoFolders attribute for associated workspaces
               // we need the Files tag and the Folders
               _xmlcfg_delete_children_with_name(project_handle,Node,VPJTAG_F);
               //_xmlcfg_delete(project_handle,Node);
               if (is_standard_vcproj) {
                  _str AutoFolders=_xmlcfg_get_attribute(project_handle,Node,'AutoFolders');
                  if (AutoFolders==VPJ_AUTOFOLDERS_CUSTOMVIEW) {
                     _xmlcfg_set_attribute(project_handle,Node,'AutoFolders',VPJ_AUTOFOLDERS_DIRECTORYVIEW);
                  }
               }
            }

            if (_xmlcfg_get_modify(project_handle)) {
               _ProjectSave(project_handle);
            }
         }

         if (cur_config_name=='') {
            if (configList._length()) {
               cur_config_name=configList[0].config;
               if (lookForDebugConfig) {
                  for (j=0;j<configList._length();++j) {
                     if (pos(' Debug("|)$',configList[j].config,1,'ri')) {
                        cur_config_name=configList[j].config;
                     }
                  }
               }
            }
            if (cur_config_name!='') {
               cur_config_name=','cur_config_name;
            }
            _ini_set_value(VSEWorkspaceStateFilename(VendorWorkspaceName),
                           "ActiveConfig",
                           _RelativeToWorkspace(CurVSEFilename,VendorWorkspaceName),
                           cur_config_name,
                           _fpos_case);
         }
         // This was already done in workspace_new_project
         //status=_ini_set_value(CurVSEFilename,"GLOBAL","workingdir",".");
      } else {
         if (IsEclipse && project_handle<0) {
            workspace_new_project2(CurVSEFilename,
                                   Compiler,
                                   _strip_filename(CurVSEFilename,'PE'),
                                   VendorWorkspaceName,
                                   false,
                                   true,
                                   _strip_filename(CurVSEFilename,'N'),
                                   WorkspaceType,
                                   true,
                                   null);
         }
      }
      if (project_handle > -1) {
         _xmlcfg_close(project_handle);
      }
   }
   _xmlcfg_close(prjpacks_handle);

   if (reset_active_project) {
      if (ProjectNames._length()) {
         cur_project_name = ProjectNames[0];
      }
      _ini_set_value(VSEWorkspaceStateFilename(VendorWorkspaceName), "Global", "CurrentProject", cur_project_name);
   }

   // close the workspace
   _xmlcfg_close(workspace_handle);

   //toolbarUpdateWorkspaceList();
   return(0);
}

static _str _GetTornadoBasePath()
{
   _str value='';

#if __UNIX__
   value=get_env('WIND_BASE');
#else
   value=_ntRegQueryValue(HKEY_CURRENT_USER,"SOFTWARE\\Wind River Systems","","WIND_BASE");
   if (value=='') {
      value=get_env('WIND_BASE');
   }
#endif

   if (last_char(value)!=FILESEP) {
      value=value:+FILESEP;
   }

   return(value);
}

static _str _GetTornadoPrjBasePath()
{
   _str value='';

#if __UNIX__
   value=get_env('WIND_PROJ_BASE');
#else
   value=_ntRegQueryValue(HKEY_CURRENT_USER,"SOFTWARE\\Wind River Systems","","WIND_PROJ_BASE");
   if (value=='') {
      value=get_env('WIND_PROJ_BASE');
   }
#endif

   if (last_char(value)!=FILESEP) {
      value=value:+FILESEP;
   }

   return(value);
}

static _str _GetTornadoPrjPath(_str VendorWorkspaceFilename)
{
   _str Path=_strip_filename(VendorWorkspaceFilename,'N');
   return(Path);
}

static _str TornadoGetVar(_str varname)
{
   _str value='';

#if __UNIX__
   value=get_env(varname);
#else
   value=_ntRegQueryValue(HKEY_CURRENT_USER,"SOFTWARE\\Wind River Systems","",varname);
   if (value=='') {
      value=get_env(varname);
   }
#endif

   return(value);
}

_str _TranslateTornadoFile(_str Filename,_str VendorWorkspaceFilename)
{
   int p=1;
   Filename=stranslate(Filename,_GetTornadoPrjPath(VendorWorkspaceFilename),'$(PRJ_DIR)/');
   for (;;) {
      p=pos('{\$\(?*\)}',Filename,1,'r');
      if (!p) break;
      _str varname=substr(Filename,pos('S0'),pos('0'));
      int len=length(varname);
      // Strip off the "$(" prefix and ")" suffix
      _str just_varname=substr(varname,3,len-3);
      Filename=substr(Filename,1,p-1):+TornadoGetVar(just_varname):+substr(Filename,p+len);
   }
   return(Filename);
}

#if !__UNIX__
#define LOCALHOST_PREFIX 'http://localhost/'

/**
 * Visual Studio solutions (.sln) can have projects that are web-hosted
 * through IIS. This function resolves them to their local path (if hosted
 * on localhost). For example: <br>
 * http://localhost/WebApplication1/WebApplication1.csproj <br>
 * might resolve to: <br>
 * c:\inetpub\wwwroot\WebApplication1\WebApplication1.csproj
 * <p>
 * IIS MUST be running for this function to succeed.
 * <p>
 * Note: <br>
 * This function only supports locally (localhost) hosted filenames.
 * 
 * @param relname Relative web-hosted name
 */
static void ResolveWebHostedRelname(_str& relname)
{
   int lp_len=length(LOCALHOST_PREFIX);
   if (lowcase(substr(relname,1,lp_len))==LOCALHOST_PREFIX) {
      _str vdir = substr(relname,lp_len+1);
      _str path;
      parse substr(relname,lp_len+1) with vdir '/' path;
      path=vdir'/'path;
      _str vpath;
      int status = ntIISGetVirtualDirectoryPath("/W3SVC/1/ROOT/"vdir,vpath);
      if ( status==0 ) {
         // Support: IIS is probably not running when you get this error
         if ( path!="" ) {
            _maybe_append_filesep(vpath);
            vpath=vpath:+translate(path,FILESEP,FILESEP2);
         }
         relname=vpath;
      }
   }
}
#endif

#define ECLIPSE_LOCATION_FILE_FILENAME_OFFSET 18
#define ECLIPSE_LOCATION_FILE_NUM_BYTES_AFTER 16
// This is used for Eclipse
static int GetPathFromDotLocationFile(_str locationFilePath,_str &newLocation)
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(locationFilePath,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   bottom();_end_line();
   long fileSize=_QROffset();
   goto_point(ECLIPSE_LOCATION_FILE_FILENAME_OFFSET);
   newLocation=get_text((int)(fileSize-ECLIPSE_LOCATION_FILE_FILENAME_OFFSET)-ECLIPSE_LOCATION_FILE_NUM_BYTES_AFTER);
   _maybe_append_filesep(newLocation);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

_str _GetLastDirName(_str Path)
{
   if (last_char(Path)==FILESEP) {
      Path=substr(Path,1,length(Path)-1);
   }
   Path=_strip_filename(Path,'P');
   return(Path);
}

static int GetFilenamesFromVendorWorkspaceFile(_str VendorWorkspaceFilename,
                                               _str VendorWorkspaceType,
                                               _str (&ProjectNames)[],
                                               _str (&VendorProjectNames)[]=null)
{
   int temp_view_id=0;
   int orig_view_id=0;
   int status=0;
   int ret_value=0;

   boolean IsEclipse=(VendorWorkspaceType==ECLIPSE_VENDOR_NAME);
   boolean IsXcode= ((VendorWorkspaceType==XCODE_PROJECT_VENDOR_NAME) || (VendorWorkspaceType==XCODE_WKSPACE_VENDOR_NAME));
   if (!IsEclipse && !IsXcode) {
      status=_open_temp_view(VendorWorkspaceFilename,temp_view_id,orig_view_id);
      if (status) {
         return(status);
      }
   }
   _str old_workspace_filename=_workspace_filename;
   _workspace_filename=VendorWorkspaceFilename;
   if (!IsEclipse && !IsXcode) {
      top();up();
   }
   _str VendorWorkspacePath=_strip_filename(VendorWorkspaceFilename,'N');
   _str TempProjectNames[]=null;
   _str line='';
   _str cur='';

   switch (lowcase(VendorWorkspaceType)) {
   case ECLIPSE_VENDOR_NAME:
      _str path=VendorWorkspacePath:+'.metadata':+FILESEP:+'.plugins':+FILESEP:+'org.eclipse.core.resources':+FILESEP:+'.projects':+FILESEP;
      _str tempPaths[]=null;
      int ff;
      for (ff=1;;ff=0) {
         cur=file_match(path:+ALLFILES_RE' +d',ff);
         if (cur=='') {
            break;
         }
         _str lastName=_GetLastDirName(cur);
         if (lastName=='.' || lastName=='..') continue;
         tempPaths[tempPaths._length()]=cur;
      }
      int i;
      for (i=0;i<tempPaths._length();++i) {
         cur=tempPaths[i];
         if (file_exists(cur:+'.location')) {
            status=GetPathFromDotLocationFile(cur:+'.location',tempPaths[i]);
            if (status) {
               // Not sure what the best thing to do is, I guess we skip this one.
               tempPaths._deleteel(i);
               --i;
            }
         } else {
            _str lastName=_GetLastDirName(cur);
            tempPaths[i]=VendorWorkspacePath:+lastName:+FILESEP;
         }
      }
      VendorProjectNames=tempPaths;
      for (i=0;i<VendorProjectNames._length();++i) {
         _str JustName=_GetLastDirName(VendorProjectNames[i]);
         ProjectNames[ProjectNames._length()]=VendorProjectNames[i]:+_GetLastDirName(VendorProjectNames[i]):+PRJ_FILE_EXT;
      }
      break;
   case VISUAL_STUDIO_VENDOR_NAME:
      for (;;) {
         status=search('^Project\("\{?@\}"\) = "{?@}", "{?@}", ?@$','@rh>');
         get_line(line);
         if (status) break;
         _str justname=get_match_text(0);
         _str relname=get_match_text(1);
#if !__UNIX__
         ResolveWebHostedRelname(relname);
#endif
         _str relnameExpanded = _replace_envvars(relname);
         if ( _IsVisualStudioProjectFilename(relnameExpanded) ) {
            // Throw out projects we do not recognize.  They will not be
            // removed from the workspace, and this will save the user some 
            // error messages about missing .vpj files.
            ProjectNames[ProjectNames._length()]=VSEProjectFilename(_RelativeToWorkspace(_AbsoluteToWorkspace(relnameExpanded)));
            VendorProjectNames[VendorProjectNames._length()]=_RelativeToWorkspace(_AbsoluteToWorkspace(relnameExpanded));
         }
      }
      break;
   case TORNADO_VENDOR_NAME:
      _str BasePath=_GetTornadoBasePath();
      _str PrjPath=_GetTornadoPrjPath(VendorWorkspaceFilename);
      status=search('^\<BEGIN\> projectList$','@rh');
      if (!status) {
         for (;;) {
            if (down()) break;
            get_line(line);
            if (line=='<END>') {
               break;
            }
            line=strip(line);
            for (;;) {
               cur=parse_file(line);
               cur=strip(cur,'T','\');
               cur=strip(cur);
               if (cur=='') break;
               VendorProjectNames[VendorProjectNames._length()]=_RelativeToWorkspace(_AbsoluteToWorkspace(_TranslateTornadoFile(cur,VendorWorkspaceFilename)));
               ProjectNames[ProjectNames._length()]=VSEProjectFilename(_RelativeToWorkspace(_AbsoluteToWorkspace(_TranslateTornadoFile(cur,VendorWorkspaceFilename))));
            }
         }
      }
      break;
   case VCPP_VENDOR_NAME:
   case VCPP_EMBEDDED_VENDOR_NAME:
      for (;;) {
         status=search('^Project\:','@rh>');
         if (status) {
            break;
         }
         get_line(line);
         //Strip off beginning "Project :"
         line=substr(line,length('Project: ')+1);
         //Strip off ending " - Package Owner=<xx>"
         int lp=lastpos(' - ',line);
         if (lp>1) {
            line=substr(line,1,lp-1);
         }
         //Strip off beginning "title"=<filename>
         int p=pos('=',line);//= is invalid for VCPP project file
         if (p) {
            line=substr(line,p+1);
         }
         //relative(absolute()) looks funny, but it is to be sure that the
         //format matches our format
         VendorProjectNames[VendorProjectNames._length()]=_RelativeToWorkspace(_AbsoluteToWorkspace(line));
         ProjectNames[ProjectNames._length()]=VSEProjectFilename(_RelativeToWorkspace(_AbsoluteToWorkspace(line)));
      }
      break;

   case JBUILDER_VENDOR_NAME:
      // add a .jpx file to the VendorProjectNames array for each .vpj file
      // in the ProjectNames array
      int k;
      for (k = 0; k < ProjectNames._length(); k++) {
         VendorProjectNames[k] = _strip_filename(ProjectNames[k], "E") JBUILDER_PROJECT_EXT;
      }
      break;
   case XCODE_PROJECT_VENDOR_NAME:
      ret_value=_xcode_project_get_vpj_names(VendorWorkspaceFilename,ProjectNames,VendorProjectNames);
      break;
   case XCODE_WKSPACE_VENDOR_NAME:
      ret_value=_xcode_workspace_get_vpj_names(VendorWorkspaceFilename,ProjectNames,VendorProjectNames);
      break;
   case MACROMEDIA_FLASH_VENDOR_NAME:
      // add a .flp file to the VendorProjectNames array for each .vpj file
      // in the ProjectNames array
      for (k = 0; k < ProjectNames._length(); k++) {
         VendorProjectNames[k] = _strip_filename(ProjectNames[k], "E") MACROMEDIA_FLASH_PROJECT_EXT;
      }
      break;
   }
   _workspace_filename=old_workspace_filename;
   if (!IsEclipse && !IsXcode) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
   return(ret_value);
}

static int GetAssociatedWorkspaceInfo(int WorkspaceHandle,
                                      _str &VendorWorkspaceFilename,
                                      _str &VendorWorkspaceType='')
{
   VendorWorkspaceFilename=_WorkspaceGet_AssociatedFile(WorkspaceHandle);
   if (VendorWorkspaceFilename=='') {
      return(1);//Doesn't have to be an association
   }
   VendorWorkspaceFilename=absolute(VendorWorkspaceFilename,_strip_filename(_xmlcfg_get_filename(WorkspaceHandle),'N'));

   VendorWorkspaceType=_WorkspaceGet_AssociatedFileType(WorkspaceHandle);
   if (VendorWorkspaceType=='') {
      return(1);
   }
   return(0);
}

/**
 * Fills all the files in WorkspaceFilename into project_names.
 *
 * THE NAMES FILLED IN ARE RELATIVE TO WorkspaceFilename
 *
 * @param WorkspaceFilename
 *               Filename to get files from
 * @param project_names
 *               Array to put filenames into
 * @return returns 0 if succesful
 */
int _GetWorkspaceFilesH(int WorkspaceHandle,_str (&project_names)[],
                        _str (&VendorProjectNames)[]=null)
{
   project_names._makeempty();
   if (WorkspaceHandle<0) {
      return(WorkspaceHandle);
   }
   _WorkspaceGet_ProjectFiles(WorkspaceHandle,project_names);
   ////////////////////////////////////////////////////////////////////////////
   //End of old func.  Above here works
   _str VendorWorkspacefilename='';
   _str VendorWorkspaceType='';
   int status=GetAssociatedWorkspaceInfo(WorkspaceHandle,VendorWorkspacefilename,VendorWorkspaceType);
   if (status) {
      return(0);//Doesn't have to be an association
   }

   status=GetFilenamesFromVendorWorkspaceFile(VendorWorkspacefilename,
                                              VendorWorkspaceType,
                                              project_names,
                                              VendorProjectNames);
   SetProjectDisplayNames(project_names,VendorProjectNames,_strip_filename(VendorWorkspacefilename,'N'));
   return(status);
}
int _GetWorkspaceFiles(_str WorkspaceFilename,_str (&project_names)[],
                       _str (&VendorProjectNames)[]=null)
{
   int status=0;
   if (!file_eq(WorkspaceFilename,_workspace_filename)) {
      int handle;
      handle=_xmlcfg_open(VSEWorkspaceFilename(WorkspaceFilename),status);
      status=_GetWorkspaceFilesH(handle,project_names,VendorProjectNames);
      if (handle>=0) _xmlcfg_close(handle);
      return(status);
   }
   status=_GetWorkspaceFilesH(gWorkspaceHandle,project_names,VendorProjectNames);
   return(status);
}

static int  gUserTemplatesHandle;
static int  gSysTemplatesHandle;
#define DEPLIST_STRIPPED_NAMES  ctldeplist.p_user
#define PROJECT_STRIPPED_NAMES  ctladd_to_project_name.p_user
#define WORKSPACE_NEW_OPTION    p_active_form.p_user
#define NEW_PROJ_WIZARD_TIMER   'NewProjectWizardTimer'
#define PROJECT_TYPES_EXECUTABLE ctlcustomize.p_user

defeventtab _workspace_new_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _workspace_new_form_initial_alignment()
{
   // file tab
   sizeBrowseButtonToTextBox(ctldirectory.p_window_id, ctlBrowsedir.p_window_id, 0,
                             ctlfilename.p_x + ctlfilename.p_width);

   // project tab
   sizeBrowseButtonToTextBox(ctlProjectNewDir.p_window_id, ctlBrowseCD.p_window_id, 0,
                             _new_prjname.p_x + _new_prjname.p_width);

   // workspace tab
   sizeBrowseButtonToTextBox(ctlnew_workspace_dir.p_window_id, ctlcommand1.p_window_id, 0,
                             ctlnew_workspace_name.p_x + ctlnew_workspace_name.p_width);

}

ctlProjTree.on_change(int reason)
{
   if (reason == CHANGE_SELECTED) {
      _str packageName=ctlProjTree._TreeGetCurCaption();
      if (CheckMSProjectType(packageName)){
         // see about possibly disabling the executable name
         hasExecutableName := false;
         if (PROJECT_TYPES_EXECUTABLE != null && PROJECT_TYPES_EXECUTABLE._indexin(packageName)) {
            hasExecutableName = PROJECT_TYPES_EXECUTABLE:[packageName];
         }

         ctlExecutableName.p_enabled = ctlExecutableLabel.p_enabled = hasExecutableName;
         if (hasExecutableName && ctlExecutableName.p_text == '') {
            ctlExecutableName.p_text = _strip_filename(_new_prjname.p_text, 'pe');
         }
      } else ctlExecutableName.p_enabled = ctlExecutableLabel.p_enabled = false;
   }
}

void ctl_new_proj_wizard.lbutton_up(boolean manual = false)
{
   // show the wizard
   result := p_active_form.show('-modal -xy _new_project_wizard_form');

   if (result == IDOK) {
      // select things based on what user said
      // if there is a second param, then we try and find it
      searchItem := _param1;
      index := ctlProjTree._TreeSearch(TREE_ROOT_INDEX, searchItem, 'T');
      if (index > 0) {
         ctlProjTree._TreeSetCurIndex(index);
         ctlProjTree._set_focus();
      } else {
         index = ctlProjTree._TreeSearch(TREE_ROOT_INDEX, '(Other)', 'T');
         ctlProjTree._TreeSetCurIndex(index);
         ctlProjTree._set_focus();
      }

   } else if (result == IDIGNORE || manual) {
      // close this form, too
      p_active_form._delete_window();
   }
}


/**
 * Checks to see if the package name is a type that SlickEdit 
 * can create on its own.  Some Microsoft project types cannot 
 * be created using SlickEdit.  If the project type is one of 
 * these MS types, then the function displays a message to the 
 * user. 
 * 
 * @param packageName
 *               the project type to check
 * 
 * @return whether the project type is one SlickEdit can create
 */
boolean CheckMSProjectType(_str packageName)
{
   _str msg = "";
   if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows") ) {
      msg="If you are using Visual C++ version 5.0 or newer, create your workspace in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   } else if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows >= 6.0") ) {
      msg="If you are using Visual C++ version 6.0 or newer, create your workspace/solution in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   } else if ( strieq(substr(packageName,1,length("Microsoft Visual Studio")),"Microsoft Visual Studio") ) {
         // Being very lazy here by just checking the first part of the package string, but it keeps us from
         // having to check the 6 or more possibilities explicitly.
      msg="If you are using Visual Studio, create your workspace/solution in Visual Studio. Then open your Visual Studio workspace/solution from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
   }
   if ( msg != "" ) {
          // This is not a package we can create on our own, so advise the user
       _message_box(msg, "", MB_OK | MB_ICONINFORMATION);
       return false;
   }
   return true;
}

void ctlcustomize.lbutton_up()
{
   // remember which package was selected before customization
   _str selectedItem = ctlProjTree._TreeGetCurCaption();

   if (gUserTemplatesHandle>=0) {
      _xmlcfg_close(gUserTemplatesHandle);
   }
   show('-modal _packs_form');

   if(_find_formobj('_workspace_new_form','n')){
      gUserTemplatesHandle=_ProjectOpenUserTemplates();
      _FillInProjectTreeControl(gUserTemplatesHandle,gSysTemplatesHandle,false);
   
      // change the selection back to the package that was selected before customization
      int status = ctlProjTree._TreeSearch(TREE_ROOT_INDEX, selectedItem, "T");//ctlPkgList._lbsearch(selectedItem);
      if (status >= 0) {
         ctlProjTree._TreeSetCurIndex(status);
      }
   }
}
void ctlcustomize.on_destroy()
{
   if (gUserTemplatesHandle>=0) {
      _xmlcfg_close(gUserTemplatesHandle);
   }
   if (gSysTemplatesHandle>=0) {
      _xmlcfg_close(gSysTemplatesHandle);
   }
}

void ctlnew_workspace_name.on_change()
{
   _str wroot=GetWorkspaceRoot();
   if (wroot!='') {
      if (ctlnew_workspace_dir.p_text=="" || file_eq(_strip_filename(ctlnew_workspace_dir.p_text,'N'),wroot)) {
         ctlnew_workspace_dir.p_text=wroot:+ctlnew_workspace_name.p_text;
      }
   }
}
void ctlBrowseCD.lbutton_up()
{
   _str olddir=getcwd();
   _str path = _ChooseDirDialog("",p_prev.p_text,"",CDN_ALLOW_CREATE_DIR|CDN_PATH_MUST_EXIST);
   chdir(olddir,1);
   if ( path=='' ) {
      return;
   }
   p_prev.p_text=path;
}

ctlProjectNewDir.on_change()
{
   PROJECTNEWDIR_MODIFY=1;

   UpdateReadOnlyLocation();
}

_str CreateReadOnlyLocation()
{
   _str text = ctlProjectNewDir.p_text;

   if (ctlCreateProjDir.p_value) {
      _maybe_append_filesep(text);
      text = text :+ _new_prjname.p_text;
   }
   _maybe_append_filesep(text);

   return text;
}

void UpdateReadOnlyLocation()
{
   // _chr(13) = newline in label
   ctlROLocation.p_caption = 'Files will be located at:':+ _chr(13) :+ 
      _ShrinkFilename(CreateReadOnlyLocation(), ctlROLocation.p_width);
}

void ctlDocModes.lbutton_double_click()
{
   _param1 =_param2 = _param3 = _param4 ='';
   _param5=0;
   _param6 = ctlDocModes._lbget_seltext();

   ctlok.call_event(ctlok,LBUTTON_UP);
}

#define NEW_FILE_TAB      0
#define NEW_PROJECT_TAB   1
#define NEW_WORKSPACE_TAB 2

_command void project_new_maybe_wizard() name_info(',')
{
   // see if we want to launch the project wizard
   if (!new_project_wizard(false)) {
      // if not, just use the old command
      workspace_new();
   }
}

_command boolean new_project_wizard(boolean force = true) name_info(',')
{
   if (force || def_launch_new_project_wizard) {

      // show the New Project form
      newProjForm := show('-modal -mdi _workspace_new_form', 'PW');

      return true;
   }

   return false;
}

/**
 * Displays the New dialog box.  Allows you to create files, projects, and 
 * workspaces. The Project tab is initially active.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories Buffer_Functions
 * 
 */ 
_command void workspace_new(boolean inDialog=true,_str workspaceName=null,_str workspaceDir=null)
{
   if (workspaceName!=null) {
      if (_DebugMaybeTerminate()) {
         return;
      }
      _str msg='';
      if (workspaceName=="") {
         msg='Must specify a workspace name';
         if (inDialog) {
            ctlnew_workspace_name._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return;
      }
#if !__UNIX__
      // pretty much all the characters are allowed on UNIX
      if (iswildcard(workspaceName)) {
         msg="Invalid filename";
         if (inDialog) {
            ctlnew_workspace_name._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return;
      }
#endif
      if (_strip_filename(workspaceName,'n')!='') {
         msg='Workspace name must not contain a path';
         if (inDialog) {
            ctlnew_workspace_name._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return;
      }
      if (workspaceName=='') {
         msg='You must specify a workspace filename';
         if (inDialog) {
            ctlnew_workspace_dir._text_box_error(msg);
         } else {
            _message_box(msg);
         }
         return;
      }

      // handle special unix paths like "~/"
      if (def_unix_expansion) {
         workspaceDir = _unix_expansion(workspaceDir);
      }

      workspaceDir=absolute(workspaceDir);
      if (last_char(workspaceDir)!=FILESEP) {
         workspaceDir=workspaceDir:+FILESEP;
      }

      if (workspaceDir!='' && _mkdir_chdir(workspaceDir)) return;

      _str WorkspaceFilename;
      WorkspaceFilename=workspaceDir:+workspaceName;
      if (!file_eq(_get_extension(WorkspaceFilename,1),WORKSPACE_FILE_EXT)) {
         WorkspaceFilename=_strip_filename(WorkspaceFilename,'E'):+WORKSPACE_FILE_EXT;
      }
      if (file_exists(WorkspaceFilename)) {
         _message_box(nls("The workspace file %s already exists.",WorkspaceFilename));
         return;
      }
      if (inDialog) {
         p_active_form._delete_window(0);
      }
      int status=workspace_new_workspace2(WorkspaceFilename);
      if (status) {
         return;
      }
      toolbarUpdateWorkspaceList();
      return;
   }
   _macro_delete_line();
   show('-modal -mdi _workspace_new_form','P');
}

int workspace_new_workspace2(_str WorkspaceFilename,boolean closeFilesFirst=true)
{
   int status=0;
   if (closeFilesFirst) {
      status=0;
      if (_workspace_filename!='') {
         status=workspace_close();
      } else if (def_restore_flags & RF_PROJECTFILES) {
         status=_close_all2();
      }
      if (status) {
         return(status);
      }
   }
   int handle=_WorkspaceCreate(WorkspaceFilename);
   status=_WorkspaceSave(handle);
   _xmlcfg_close(handle);
   if (!status) {
      _WorkspaceOpenAndUpdate(WorkspaceFilename);
      _menu_add_workspace_hist(_workspace_filename);
   }
   _tbSetRefreshBy(VSTBREFRESHBY_PROJECT);
   if (status) {
      _message_box(nls("Could not create workspace file '%s1'\n\n%s2",WorkspaceFilename,get_message(status)));
   }
   return(status);
}

struct PROJECT_INFO {
   _str ProjectFilename;
   _str CompilerName;
   _str ExecutableName;
   _str DependencyOf;
};

int workspace_new_project(boolean inDialog,
                          _str packageName,
                          _str Filename,
                          _str Path,
                          boolean add_to_workspace,
                          _str ExecutableName,
                          _str Dependency
                         )
{
   if (_DebugMaybeTerminate()) {
      return(1);
   }
   _str msg='';
   if (Filename=='') {
      msg="You must specify a project name";
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
#if !__UNIX__
      // pretty much all the characters are allowed on UNIX
   if (iswildcard(Filename)) {
      msg="Invalid filename";
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
#endif
   if (Path=='') {
      msg="You must specify a project directory";
      if (inDialog) {
         ctlProjectNewDir._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (_strip_filename(Filename,'n')!='') {
      msg='Project name must not contain a path';
      if (inDialog) {
         _new_prjname._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }

   Path=strip(Path,'B','"');
   if (last_char(Path)!=FILESEP) {
      Path=Path:+FILESEP;
   }

   // handle special unix paths like "~/"
   if (def_unix_expansion) {
      Path = _unix_expansion(Path);
   }

   Path=absolute(Path);    // VC++ uses current directory
   boolean ShowProperties=false;

   _str ProjectFilename=Path:+Filename;
   if (_get_extension(ProjectFilename)!=PRJ_FILE_EXT) {
      ProjectFilename=ProjectFilename:+PRJ_FILE_EXT;
   }
   // Moving this fixes bug where existing project file is
   // trashed when adding existing project to workspace.
   boolean addExistingProject = false;
   if (file_exists(ProjectFilename)) {
      int result = _message_box(nls("The file %s already exists.  Would you like to add it to the current workspace?", ProjectFilename), 
                   "", MB_YESNO | MB_ICONQUESTION);
      if (result == IDNO) {
         return(1);
      } 
      add_to_workspace = true;
      addExistingProject = true;
   }

   boolean createdDirectory=false;
   // Only show project properties if directory does not exist.
   // Moving thing code fixes bug when adding project to workspace.
   int status=0;
   if (!isdirectory(Path)) {
      createdDirectory=true;
      status=_mkdir_chdir(Path);
      if (status) {
         return(status);
      }
   } else {
      cd(Path);
      ShowProperties=true;
   }
   if (add_to_workspace) {
      // Code changed to close dialog before
      // workspace_new_project displays project properties dialog.
         _str newProjectName=ProjectFilename;
         _str newPackageName=packageName;
         _str newExecutableName=ExecutableName;
      if (inDialog) {
         p_active_form._delete_window(0);
      }

      if (addExistingProject) {
         // we are adding an existing project to the current workspace
         status = workspace_insert(ProjectFilename);
      } else {
         status=workspace_new_project2(newProjectName,
                                       newPackageName,
                                       newExecutableName,
                                       _workspace_filename,
                                       ShowProperties,
                                       true,
                                       '',
                                       '',
                                       false,
                                       null,
                                       createdDirectory);
      }
      if (!status && Dependency!='') {
         _str DepProj = _AbsoluteToWorkspace(Dependency);
         int handle = _ProjectHandle(DepProj);
         _str configNames[] = null;
         int icfg;
         _ProjectGet_ConfigNames(handle, configNames);
         for (icfg = 0; icfg < configNames._length(); ++icfg) {
            _ProjectAdd_Dependency(handle, newProjectName, "", "", configNames[icfg]);
         }
         _ProjectSave(handle);
         _maybeGenerateMakefile(DepProj);
      }
      toolbarUpdateWorkspaceList();
      return(status);
   }
   // create new workspace

   _str WorkspaceFilename=_strip_filename(ProjectFilename,'E'):+WORKSPACE_FILE_EXT;
   if (file_exists(WorkspaceFilename)) {
      _message_box(nls("The workspace file %s already exists.",WorkspaceFilename));
      return(1);
   }

   if (inDialog) {
      p_active_form._delete_window(0);
   }
   status=workspace_new_workspace2(WorkspaceFilename);
   if (status) {
      return(status);
   }

   status=workspace_new_project2(ProjectFilename,
                                 packageName,
                                 ExecutableName,
                                 WorkspaceFilename,
                                 ShowProperties,
                                 true,
                                 '',//AssociatedMakefile
                                 '',//AssociatedMakefileType
                                 false,
                                 null,
                                 createdDirectory,
                                 true);
   toolbarUpdateWorkspaceList();
   return(status);
}
int workspace_new_file(
                      boolean inDialog,
                      _str Filename,
                      _str Path,
                      _str modeName='',
                      _str ProjectName='',
                      _str encoding=''
                      )
{
   _str msg='';
   if (_strip_filename(Filename,'n')!='') {
      msg='Filename must not contain a path';
      if (inDialog) {
         ctlfilename._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   if (ProjectName!='' && Filename=="") {
      msg='Filename must be specified when adding to the project';
      if (inDialog) {
         ctlfilename._text_box_error(msg);
      } else {
         _message_box(msg);
      }
      return(1);
   }
   _maybe_append_filesep(Path);

   // handle special unix paths like "~/"
   int status=0;
   if (def_unix_expansion) {
      Path = _unix_expansion(Path);
   }
   if (Path!='' ) {
      if (!isdirectory(Path)) {
         status=_mkdir_chdir(Path,false);
         if (status) {
            return(status);
         }
      }
   }

   if (Filename!='') {
      Filename=Path:+Filename;
   }
   if (Filename!='' && file_or_buffer_exists(Filename)) {
      msg = nls('A file named %s already exists. Open Existing File?',Filename);
      int result = _message_box(msg, "New File" ,MB_YESNOCANCEL|MB_ICONQUESTION);
      if (inDialog) {
         ctlfilename._set_focus();
         ctlfilename._set_sel(1,length(ctlfilename.p_text)+1);
      }
      if (result == IDYES) {
         if (inDialog) {
            p_active_form._delete_window(status);
         }
         status = _mdi.p_child.edit(maybe_quote_filename(Filename));
         return(status);
      } else if (result == IDCANCEL) {
         if (inDialog) {
            p_active_form._delete_window(status);
         }
      }
      return(1);
   }
   //10:49am 11/3/1999
   //The reason for reordering this code is because the buffer has to be
   //created before project_add_file is called so that the file gets in the
   //tags database
   int fid=p_active_form;
   int had_no_child_windows=_no_child_windows();
   if (encoding=='') {
      _str lang='';
      if (modeName!='') {
         check_and_load_mode_support(modeName);
         lang=_Modename2LangId(modeName);
      }
      if (lang!='') {
         encoding=_load_option_encoding('.'lang);
      } else {
         encoding=_load_option_encoding(Filename);
      }
   }
   status=_mdi.p_child.edit(encoding' +t 'maybe_quote_filename(Filename));

   if (ProjectName!='' && Filename!='') {
      _str old_project_name=_project_name;
      _project_name=ProjectName;
      status=project_add_file(Filename);
      _project_name=old_project_name;
      if (status) {
         return(status);
      }
   }
   if (inDialog) {
      fid._delete_window(status);
   }
   if (modeName!='') {
      check_and_load_mode_support(modeName);
      _str lang=_Modename2LangId(modeName);
      _mdi.p_child._SetEditorLanguage(lang);
   }
   _mdi.p_child._set_focus();
   call_list('_workspace_file_add', _project_name, Filename);
   return(0);
}
void ctlok.lbutton_up()
{
   _macro('m',_macro('s'));
   int wid=0;
   if (ctl_gn_tab.p_ActiveTab==NEW_FILE_TAB) {
      _str Filename=ctlfilename.p_text;
      _str ProjectName='';
      _str Path=ctldirectory.p_text;
      _str modeName='';


      _maybe_append_filesep(Path);
      if (def_unix_expansion) {
         Path = _unix_expansion(Path);
      }

      if (ctlDocModes.p_text != '') {
         modeName=ctlDocModes._lbget_text();
         if (modeName == "Automatic") {
            modeName = HandleAutomaticDocumentMode(Filename);
         }
         if (modeName == "") {
            return;
         }
      } else if ( Filename=='' ) {
         // Here we try to guess that the user wants the same file type
         // as the current buffer.  Since nothing is selected this is a reasonable
         // guess.
         wid=_mdi.p_child;
         if (wid && wid._isEditorCtl(false)) {
            modeName=ctlDocModes._lbget_text();
         }
      }

      // verify extension and doc mode match.
      if (modeName != "Fundamental" && modeName != "Plain Text" && modeName != "Automatic") {
         _str ext = _get_extension(Filename);
         if (ext != "") {
            _str lang = _Ext2LangId(ext);
            if (lang == '') {
               lang = _Ext2LangId(lowcase(ext));
            }
            if (!strieq(_LangId2Modename(lang), modeName)) {
               // warn user about mismatched extensions (provided they have the warning turned on).
               if (def_warn_mismatched_ext) {
                  _str msg = "Filename extension, "ext", does not match selected Document Mode, "modeName".  Continue?";
                  int result = textBoxDialog("Mismatched Extensions",
                       0,                                         // Flags
                       0,                                         // width
                      "",                                         // help item
                      "Yes,No\t-html "msg,                        // buttons and captions
                      "",                                         // Retrieve Name
                      "-CHECKBOX Warn about mismatched extensions.:1" );
                  // check for warning checkbox (0=unchecked, 1=checked)
                  def_warn_mismatched_ext = (_param1 == 1);
                  if (result != 1/*Yes*/) {   /*button 1, aka Yes*/
                     return;
                  }
               }
            }
         }
      }

      _param1=Path:+Filename;

      if (ctladd_to_project.p_value) {
         _str StrippedNames:[];
         StrippedNames=PROJECT_STRIPPED_NAMES;
         ProjectName=_AbsoluteToWorkspace(StrippedNames:[ctladd_to_project_name.p_text]);
      }
      // save the value of the add to project checkbox
      _append_retrieve(ctladd_to_project, ctladd_to_project.p_value, '_workspace_new_form.ctladd_to_project');

      if (WORKSPACE_NEW_OPTION=='f2') {
         // Call will add this file to a specific folder

         // Note: when Filename is blank, workspace_new_file displays an error
         // because we are adding this file to a project
         if (Filename!='') {
            ProjectName='';
         }
      }

      // for macro recording
      _macro_call('workspace_new_file',
                  0,
                  Filename,
                  Path,
                  modeName,
                  ProjectName,
                  _EncodingGetComboSetting()
                 );
      int result = workspace_new_file(true,
                         Filename,
                         Path,
                         modeName,
                         ProjectName,
                         _EncodingGetComboSetting()
                        );
      // update most recently used document mode list
      if (!result) {
         UseDocumentMode(modeName);
      }
      // Check and save any modified project packs.
   } else if (ctl_gn_tab.p_ActiveTab==NEW_PROJECT_TAB) {
      // any parent items in trees are not valid project types but groups of project types
      if (ctlProjTree._TreeDoesItemHaveChildren(ctlProjTree._TreeCurIndex())) {
         _message_box("You must specify a project type.", "", MB_OK);
         return;
      }
      _str packageName=ctlProjTree._TreeGetCurCaption();
      if (strieq(packageName, "Root")) {
         _message_box("You must specify a project type.", "", MB_OK);
         return;
      }
      if (!CheckMSProjectType(packageName)) {
         return;
      }

       _str msg = "";
      if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows") ) {
         msg="If you are using Visual C++ version 5.0 or newer, create your workspace in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
      } else if ( strieq(packageName,"Microsoft Visual C++ for 32 bit Windows >= 6.0") ) {
         msg="If you are using Visual C++ version 6.0 or newer, create your workspace/solution in Visual C++. Then open your Visual C++ workspace from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
      } else if ( strieq(substr(packageName,1,length("Microsoft Visual Studio")),"Microsoft Visual Studio") ) {
         // Being very lazy here by just checking the first part of the package string, but it keeps us from
         // having to check the 6 or more possibilities explicitly.
         msg="If you are using Visual Studio, create your workspace/solution in Visual Studio. Then open your Visual Studio workspace/solution from the \n\"Project\" > \"Open Workspace\" menu item in ":+_getDialogApplicationName():+".";
      }
       if ( msg != "" ) {
          // This is not a package we can create on our own, so advise the user
          _message_box(msg, "", MB_OK | MB_ICONINFORMATION);
          return;
       }

      _str Dependency='';
      if (ctldependency.p_value && ctldependency.p_enabled) {
         _str StrippedNames:[];
         StrippedNames=DEPLIST_STRIPPED_NAMES;
         if (StrippedNames._varformat()==VF_HASHTAB) {
            Dependency=StrippedNames:[ctldeplist.p_text];
         }
      }
      _macro('m',_macro('s'));
      _macro_call('workspace_new_project',
                  0,
                  packageName,
                  _new_prjname.p_text,
                  CreateReadOnlyLocation(),
                  ctladd_to_workspace.p_value!=0,
                  ctlExecutableName.p_text,
                  Dependency
                 );
      int result = workspace_new_project(true,
                            packageName,
                            _new_prjname.p_text,
                            CreateReadOnlyLocation(),
                            ctladd_to_workspace.p_value!=0,
                            ctlExecutableName.p_text,
                            Dependency
                           );
      // update most recently used document mode list
      if (!result) {
         UseProjectType(packageName);
      }
   } else if (ctl_gn_tab.p_ActiveTab==NEW_WORKSPACE_TAB) {
      _macro_call('workspace_new',
                  0,
                  ctlnew_workspace_name.p_text,
                  ctlnew_workspace_dir.p_text);
      workspace_new(true,ctlnew_workspace_name.p_text,ctlnew_workspace_dir.p_text);
   }
}


/**
 * Updates the most recently used document mode list after a user has created a new file.
 * 
 * @param modeName
 */
void UseDocumentMode(_str modeName)
{
   if (strieq(modeName, "Automatic")) return;

   int i = 0;
   for (; i < MRUDocModes._length(); i++ ) {
      if (strieq(MRUDocModes[i], modeName)) {
         break;
      }
   }

   // mode name was found - reorganize
   if (i < MRUDocModes._length()) {
      ShiftArrayUp(MRUDocModes, 0, i);
   } else {   // mode name not found, add new one and remove last one
      ShiftArrayUp(MRUDocModes, 0);
   }

   MRUDocModes[0] = modeName;

   // clear any items past maximum
   for (i = def_max_doc_mode_mru; i < MRUDocModes._length(); ++i) {
      MRUDocModes._deleteel(i);
   }

}

/**
 * Updates the most recently used project type list when a new project is created.
 * 
 * @param type   the project type that was used
 */
void UseProjectType(_str type)
{
   int i = 0;
   for (; i < MRUProjectTypes._length(); i++ ) {
      if (strieq(MRUProjectTypes[i], type)) {
         break;
      }
   }

   // mode name was found - reorganize
   if (i < MRUProjectTypes._length()) {
      ShiftArrayUp(MRUProjectTypes, 0, i);
   } else {   // mode name not found, add new one and remove last one
      ShiftArrayUp(MRUProjectTypes, 0);
   }

   MRUProjectTypes[0] = type;

   // clear any items past maximum
   for (i = def_max_proj_type_mru; i < MRUProjectTypes._length(); ++i) {
      MRUDocModes._deleteel(i);
   }

}

/**
 * Shifts the elements of an array up (so that a[n] contains what was in a[n-1]).
 * 
 * @param a          Array to be shifted
 * @param StartIndex Index where shifting should begin (default 
 *                   is beginning of array)
 * @param endIndex   Final index to be moved (default is last 
 *                   index of array)
 */
void ShiftArrayUp(typeless (&a)[], int StartIndex = 0, int endIndex = -1)
{
   if (endIndex == -1) {
      endIndex = a._length();
   } 

   int i;
   for (i = endIndex; i > StartIndex; --i) {
      a[i]=a[i - 1];
   }
}

/**
 * Handles the logic when the user selects the 
 * Automatic document mode from the new file dialog.
 * 
 * @param filename file to be created
 * 
 * @return the new document mode
 */
_str HandleAutomaticDocumentMode(_str filename)
{
   // if no extension, then create as Plain Text (Fundamental)
   // if extension, look up document mode
   modeName := "Plain Text";
   lang := _Filename2LangId(filename);
   if (lang != "") {
      modeName = _LangId2Modename(lang);
   }

   // if no extension, then ask if user wants plain text
   if (modeName == "") {
      // warn user about lack of document mode for specified extension
      if (def_warn_unknown_ext) {
         _str msg = nls("No Document Mode for this specified file: %s.  Create document as Plain Text?", filename);
         int result = textBoxDialog("Unknown Extension",
                                    0,                                          // Flags
                                    0,                                          // width
                                    "",                                         // help item
                                    "Yes,No\t-html "msg,                        // buttons and captions
                                    "",                                         // Retrieve Name
                                    "-CHECKBOX Warn about unknown extensions.:1");
         // check for warning checkbox (0=unchecked, 1=checked)
         def_warn_unknown_ext = (_param1 == 1);
         if (result == 1/*Yes*/) {   /*button 1, aka Yes*/
            modeName = "Plain Text";
         }
      } else {
         modeName = "Plain Text";
      }
   }

   return modeName;
}

static void FillInPrjName(boolean HadButtonChange=false)
{
   if (ctladd_to_workspace.p_enabled) {
      if (ctladd_to_workspace.p_value) {
         _str BaseName=_workspace_filename;
         ctlProjectNewDir.p_text=_strip_filename(BaseName,'N');
         PROJECTNEWDIR_MODIFY=0;
      } else {
         _str wroot=GetWorkspaceRoot();
         if (wroot!='') {
            ctlProjectNewDir.p_text=wroot;
            PROJECTNEWDIR_MODIFY=0;
         }
      }
   } else {
      _str currentDir = getcwd();
      _maybe_append_filesep(currentDir);
      ctlProjectNewDir.p_text = currentDir;
      PROJECTNEWDIR_MODIFY=0;
   }
}

void ctlcreate_new_workspace.lbutton_up()
{
   if (!PROJECTNEWDIR_MODIFY) {
      FillInPrjName(1);
   }
   int NewWorkspace=(int)(ctladd_to_workspace.p_value==0);
   if (ctldeplist.p_Noflines) {
      ctldependency.p_enabled=!NewWorkspace;
      ctldeplist.p_enabled= ctldependency.p_enabled && (ctldependency.p_value != 0);
   }
}

void ctldependency.lbutton_up()
{
   ctldeplist.p_enabled = ctldependency.p_enabled && (ctldependency.p_value != 0);
}

static void initialize_workspace_tab()
{
   ctlworkspace_type_list._lbadd_item("Blank Workspace");
   _str wroot=GetWorkspaceRoot();
   ctlnew_workspace_dir.p_text=wroot;
   if (wroot=="") {
      ctlnew_workspace_dir.p_text=getcwd();
   }
}

void ctlok.on_create(_str option='',_str (&Files)[]=null)
{
   _workspace_new_form_initial_alignment();

   PROJECTNEWDIR_MODIFY=0;
   initialize_file_tab();
   initialize_project_tab(Files);
   initialize_workspace_tab();
   option=lowcase(option);
   WORKSPACE_NEW_OPTION=option;
   if (option=='p') {
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;
   } else if (option == 'pw') {
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;

      _SetDialogInfoHt(NEW_PROJ_WIZARD_TIMER, -1, ctl_new_proj_wizard);

      int * timer = _GetDialogInfoHtPtr(NEW_PROJ_WIZARD_TIMER, ctl_new_proj_wizard);
      if (_timer_is_valid(*timer)) {
         _kill_timer(*timer);
         *timer = -1;
      }

      *timer = _set_timer(200, launchNewProjectWizard);
   } else if (option=='d') {
      //9:34am 7/20/1999
      //This means that we are going to return all of the new project
      //information to the caller.  We limit the user to a new project in the
      //current workspace.
      ctl_gn_tab.p_ActiveTab=NEW_PROJECT_TAB;
      ctl_gn_tab._setEnabled(NEW_FILE_TAB,0);
      ctl_gn_tab._setEnabled(NEW_PROJECT_TAB,1);
      ctl_gn_tab._setEnabled(NEW_WORKSPACE_TAB,0);
      ctlcreate_new_workspace.p_enabled=0;
      ctladd_to_workspace.p_enabled=1;
      ctladd_to_workspace.p_value=1;
   } else if (option=='f2') {
      /*
         Limit to adding new file to current project.
         Return information to caller.
      */
      ctl_gn_tab.p_ActiveTab=NEW_FILE_TAB;
      ctl_gn_tab._setEnabled(NEW_FILE_TAB,1);
      ctl_gn_tab._setEnabled(NEW_PROJECT_TAB,0);
      ctl_gn_tab._setEnabled(NEW_WORKSPACE_TAB,0);
      ctladd_to_project.p_enabled=0;
      ctladd_to_project.p_value=1;
      ctladd_to_project_name.p_enabled=0;
   }
}

static void launchNewProjectWizard()
{
   button := _find_object('_workspace_new_form.ctl_new_proj_wizard');
   if (button < 0) return;

   int * timer = _GetDialogInfoHtPtr(NEW_PROJ_WIZARD_TIMER, button);
   if (_timer_is_valid(*timer)) {
      _kill_timer(*timer);
      *timer = -1;
   }

   // find button and click it!
   button.call_event(button, LBUTTON_UP, 'W');
}

void ctladd_to_project_name.on_change(int reason)
{
   if (!p_visible) {
      return;
   }
   _str StrippedNames:[];
   StrippedNames=PROJECT_STRIPPED_NAMES;
   if (StrippedNames._varformat()!=VF_HASHTAB) return;
   if (!StrippedNames._indexin(p_text)) return;
   _str dir=_strip_filename(_AbsoluteToWorkspace(StrippedNames:[p_text]),'N');
   ctldirectory.p_text=dir;
}

void ctlDocModes.on_change(int reason)
{
   if (reason == CHANGE_CLINE) {
      // see if this item is the list divider
      if (strieq(ctlDocModes._lbget_text(), LBDIVIDER)) {
         ctlDocModes._lbdown();
         ctlDocModes._lbselect_line();
         ctlDocModes.p_text = ctlDocModes._lbget_text();
      }
   } else if (reason == CHANGE_OTHER) {  // if user types in name, select it.
      _str mode = ctlDocModes.p_text;
      _str text = ctlDocModes._lbget_text();
      if (lowcase(mode)!=lowcase(text)) {
         return;
      }
      _lbselect_line();
   }
}


static void initialize_file_tab()
{
   typeless status=0;
   _str info='';
   _str project_dir =_ProjectGet_WorkingDir(_ProjectHandle());
   project_dir=absolute(project_dir,_file_path(_project_name));
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   int projwid=_find_object('_tbprojects_form._proj_tooltab_tree');
   if (_project_name=='') {
      ctldirectory.p_text=getcwd();
   } else if (_ProjectGet_Type(handle, config) :== 'java' &&
              strieq(_ProjectGet_AutoFolders(handle),VPJ_AUTOFOLDERS_PACKAGEVIEW) && _get_focus() == projwid) {
      // special case here for Java package view
      _str caption=projwid._TreeGetCaption(projwid._TreeCurIndex());
      int node=_xmlcfg_find_simple(handle, "/Project/Files/Folder[@Name='"caption"']":+
                                   "[@Type='Package']");
      // try to populate the directory text with the directory from the current package
      if (node >= 0) {
         int child=_xmlcfg_get_first_child(handle, node);
         if (child >= 0) {
            _str projpath=_strip_filename(_xmlcfg_get_filename(handle),'N');
            _str relfile=_xmlcfg_get_attribute(handle, child, 'N');
            _str absfile=absolute(relfile, projpath);
            ctldirectory.p_text=_strip_filename(absfile, 'N');
         }
      } else {
         status=_ini_get_value(_project_get_filename(),_project_get_section("GLOBAL"),"WORKINGDIR",info);
         if (!status) {
            info=absolute(info,_strip_filename(_project_name,'N'));
            ctldirectory.p_text=info;
         } else {
            ctldirectory.p_text=getcwd();
         }
      }
   } else {
      status=_ini_get_value(_project_get_filename(),_project_get_section("GLOBAL"),"WORKINGDIR",info);
      if (!status) {
         info=absolute(info,_strip_filename(_project_name,'N'));
         ctldirectory.p_text=info;
      } else {
         ctldirectory.p_text=getcwd();
      }
   }
   if (_UTF8()) {
      _EncodingFillComboList('','Automatic',OEFLAG_REMOVE_FROM_NEW);
   } else {
      ctlencoding.p_visible=ctlencodinglabel.p_visible=0;
   }

   FillInDocumentModeList();

   _str ProjectNames[];
   _str StrippedNames:[];
   int wid;
   if (_workspace_filename!='') {
      _GetWorkspaceFiles(_workspace_filename,ProjectNames);
      wid=p_window_id;
      p_window_id=ctladd_to_project_name;
      int i;
      for (i=0;i<ProjectNames._length();++i) {
         _str StrippedCurName=_strip_filename(ProjectNames[i],'PE');
         StrippedNames:[StrippedCurName]=ProjectNames[i];
         _lbadd_item(StrippedCurName);
      }
      _lbfind_and_select_item(_strip_filename(_project_name,'PE'));
      p_window_id=wid;
   }
   PROJECT_STRIPPED_NAMES=StrippedNames;
   ctladd_to_project.p_enabled=(_project_name!="");
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      if (!_IsAddDeleteSupportedWorkspaceFilename(_workspace_filename)) {
         ctladd_to_project.p_enabled=0;
      }
   }

   if (ctladd_to_project.p_enabled) {
      // restore the last value of add to project
      retrieveValue := ctladd_to_project._retrieve_value();
      if (retrieveValue != null && isinteger(retrieveValue)) ctladd_to_project.p_value = retrieveValue;
      else ctladd_to_project.p_value = 1;
   } else ctladd_to_project.p_value = 0;

   ctladd_to_project_name.p_enabled = (ctladd_to_project.p_enabled && ctladd_to_project.p_value != 0);

   ctlfilename.call_event(CHANGE_OTHER,ctlfilename,ON_CHANGE,"W");
}

/*
 * Fills in the Document Mode list on the New File tab.  Moved
 * this to its own function since list has to be refreshed when
 * user changes number of recently used modes to display.
 * 
 **/
void FillInDocumentModeList()
{
   int wid=_mdi.p_child;

   // save currently selected item - Automatic mode is default
   _str current = ctlDocModes.p_text;
   if (current == '') {
      current = "Automatic";
   }

   // clear list
   ctlDocModes._lbclear();

   // we need to use the lower of the two values:  the maximum
   // allowed number of MRUs versus the current length of the
   // array.
   int max = def_max_doc_mode_mru;
   if (def_max_doc_mode_mru > MRUDocModes._length()) {
      max = MRUDocModes._length();
   }

   // Put in placeholders for most recently used types
   // there is no listbox insert method and the _list_modes method
   // sorts its value, so if we want the MRU list at top, we need
   // to add placeholders now.
   int j = 0;
   if (max) {
      for (; j < max; j++) {
         ctlDocModes._lbadd_item(j);
      }

      // add extra placeholder for line separator
      ctlDocModes._lbadd_item(j);
   }

   // 6.4.07
   // change the _list_modes calls to include Automatic mode
   if (wid && wid._isEditorCtl(false)) {
      ctlDocModes._list_modes(wid.p_LangId, wid.p_mode_name, true);
   } else {
      ctlDocModes._list_modes('', '', true);
   }

   // insert N most recently used document modes at placeholders
   if (max) {
      ctlDocModes._lbtop();
      ctlDocModes._lbselect_line();
      for (j = 0; j < max; j++) {
         ctlDocModes._lbset_item(MRUDocModes[j]);
         ctlDocModes.down();
      }

      // add line separator
      ctlDocModes._lbset_item(LBDIVIDER);
   }

   // restore previous selection
   boolean found = false;
   ctlDocModes._lbtop();
   while (!ctlDocModes.down()) {
      if (strieq(ctlDocModes._lbget_text(), current)) {
         ctlDocModes.p_text = current;
         ctlDocModes._lbselect_line();
         found = true;
         break;
      }
   }

   // not found, just select what's at the top
   if (!found) {
      ctlDocModes._lbtop();
      ctlDocModes._lbselect_line();
   }

}

static _str GetWorkspaceRoot()
{
   if (_workspace_filename=='') {
      return('');
   }
   _str NewWorkspaceDir=_GetWorkspaceDir();
   //Get rid of the trailing filesep
   NewWorkspaceDir=substr(NewWorkspaceDir,1,length(NewWorkspaceDir)-1);
   //Trim back one path...
   // NOTE: this is done because most projects live in a subdirectory with the same
   //       name.  for example, a project Test1 most likely lives in a folder named
   //       Test1 so the last piece of the path is trimmed based on that assumption
   NewWorkspaceDir=_strip_filename(NewWorkspaceDir,'N');
   return(NewWorkspaceDir);
}

_str _GetWorkspaceDir(_str WorkspaceFilename=_workspace_filename)
{
   return(_strip_filename(WorkspaceFilename,'N'));
}

_str _compiler_default;

static void initialize_project_tab(_str Files[]=null)
{
   PROJECT_TYPES_EXECUTABLE = null;

   _str currentDir;
   currentDir = getcwd();
   if (last_char(currentDir) != FILESEP) {  // append a FILESEP if there is not one
      currentDir = currentDir :+ FILESEP;
   }

   boolean createdUserTemplates=false;
   gUserTemplatesHandle=_ProjectOpenUserTemplates(createdUserTemplates);
   gSysTemplatesHandle=_ProjectOpenTemplates();
   if (gSysTemplatesHandle<0 && (gUserTemplatesHandle<0 || createdUserTemplates) ) {
      // No templates are available, so we will remove project and workspace
      // tabs from the dialog
      int wid=p_window_id;
      p_window_id=ctl_gn_tab;
      _setEnabled(2,0);
      _setEnabled(1,0);
      p_window_id=wid;
      return;
   }

   _FillInProjectTreeControl(gUserTemplatesHandle,gSysTemplatesHandle,false);

   boolean table:[];
   _FillProjectTypeExecutableTable(gSysTemplatesHandle, table);
   PROJECT_TYPES_EXECUTABLE = table;

   // If a default compiler package is specified, use it.
   // Otherwise select the last compiler package selected.
   _str _compiler_restore;
   if (_compiler_default == "") {
      _compiler_restore = _retrieve_value("_project_new_form.packageSelected");
   } else {
      _compiler_restore = _compiler_default;
   }
   if (_compiler_restore == "") {
      _compiler_restore = "(None)";
   }
   int wid = p_window_id;
   p_window_id = ctlProjTree;
   _compiler_restore = lowcase(_compiler_restore);
   int found = 0;
   typeless status = 0;

   // search for compiler package - if not found exactly, do a prefix search
   int index = _TreeSearch(TREE_ROOT_INDEX, _compiler_restore, "IT");
   if (index < 0) {
      index = _TreeSearch(TREE_ROOT_INDEX, _compiler_restore, "IPT");
   }

   // If no compiler package can be matched, use the first package
   if (index < 0) {
      _TreeSetCurIndex(TREE_ROOT_INDEX);
   }

   p_window_id=wid;
   ctlcreate_new_workspace.p_value=1;

   if (ctlcreate_new_workspace.p_value) {
      ctlProjectNewDir.p_text=GetWorkspaceRoot();
   }
   _str ProjectNames[];
   _str StrippedNames:[];
   if (_workspace_filename=='') {
      ctladd_to_workspace.p_enabled=false;
      ctldeplist.p_enabled=ctldependency.p_enabled=false;
   }
   if (_workspace_filename!='') {
      if (Files==null) {
         _GetWorkspaceFiles(_workspace_filename,ProjectNames);
      } else {
         ProjectNames=Files;
      }
      if (ProjectNames._length()) {
         wid=p_window_id;
         p_window_id=ctldeplist;
         int i;
         for (i=0;i<ProjectNames._length();++i) {
            _str StrippedCurName=_strip_filename(ProjectNames[i],'PE');
            StrippedNames:[StrippedCurName]=ProjectNames[i];
            _lbadd_item(StrippedCurName);
         }
         _lbfind_and_select_item(_strip_filename(_project_name,'PE'));
         p_window_id=wid;
         DEPLIST_STRIPPED_NAMES=StrippedNames;
         ctldependency.p_value=0;
      } else {
         ctldeplist.p_enabled=0;
         ctldependency.p_enabled=0;
         ctldependency.p_value=0;
      }
   }
   ctlcreate_new_workspace.call_event(ctlcreate_new_workspace,LBUTTON_UP);
   _str VendorWorkspace='';
   if (gWorkspaceHandle>=0) {
      GetAssociatedWorkspaceInfo(gWorkspaceHandle,VendorWorkspace);
   }
   if (ctlProjectNewDir.p_text=="") {
      ctlProjectNewDir.p_text=currentDir;
   }
   PROJECTNEWDIR_MODIFY=0;

   if (_IsWorkspaceAssociated(_workspace_filename)) {
      //Cannot let the user add projects to a VCPP workspace
      ctladd_to_workspace.p_enabled=0;
      ctladd_to_workspace.call_event(ctladd_to_workspace,LBUTTON_UP);
   }
}

// Search thru the specified file for a list of section names and
// append section names into the list. Duplicate copies are removed.
// Retn: 0 OK, !0 can't read file
static int _getProjectTypeNames(int handle, _str (&p)[], int user, boolean showAll)
{
   // Loop thru the entire ini file and get all sections.
   // Append new sections to the end of the list.
   _str line, sectionName;
   int i,array[];
   _ProjectTemplatesGet_TemplateNodes(handle,array);
   for (i=0;i<array._length();++i) {
      // Find the start of a section. [sectionName]
      sectionName=_xmlcfg_get_attribute(handle,array[i],'Name');

      // see if this template should be shown
      if (!_ignoreProjectPackage(handle, array[i],showAll)) continue;

      // Ignore a global project pack if a version with the same name
      // already exists in the list.
      if (!user) {
         int found = 0;
         typeless ii;
         for (ii._makeempty();;) {
            p._nextel(ii);
            if (ii._isempty()) break;
            if (lowcase(ii) == lowcase(sectionName)) {
               found = 1;
               break;
            }
         }
         if (found) continue;
      }

      p[p._length()]=sectionName;
   }
   return(0);
}


/**
 * Retrieves the list of available project types and populates the tree view at Project > New.
 * 
 * @param usertemplates_handle
 * @param systemplates_handle
 * @param showAll whether all project types should be listed
 */
void _FillInProjectTreeControl(int usertemplates_handle,
                               int systemplates_handle,
                               boolean showAll)
{
   int wid=p_window_id;
   _control ctlProjTree;
   p_window_id = ctlProjTree;

   // Get the list of user-defined project packs first.
   // If a project pack exists as user-defined and globally defined,
   // the user-defined version in the user's project pack file
   // superceeds the global version.
   PROJECTPACKS p:[];
   p._makeempty();

   GetAllProjectPacks(p, usertemplates_handle, systemplates_handle, showAll);

   // Fill the project type tree view.
   fillProjectTree(p);
   _TreeTop();
   p_window_id=wid;
}

/**
 * Determines which project types require executable names.  Fills up a table 
 * with this information. 
 * 
 * @param usertemplates_handle      handle to system project templates file
 * @param table                     table to be filled:  if a project type 
 *                                  requires an executable name, true will be
 *                                  mapped to the project name.  otherwise, the
 *                                  project type may be missing or mapped to
 *                                  false.
 */
static void _FillProjectTypeExecutableTable(int systemplates_handle, 
                                            boolean (&table):[])
{
   table._makeempty();

   GetProjectTypeExecutables(systemplates_handle, table);
}

/**
 * Loads a hashtable with information regarding whether the project types 
 * contained in the file specified by the handle require executable names. 
 * 
 * @param handle                    handle to template file
 * @param table                     table to be filled
 */
static void GetProjectTypeExecutables(int handle, boolean (&table):[])
{
   // search for the OutputFile attribute
   ss := "Templates/Template/Config/@OutputFile";
        
   int attrNode;
   _str foundNodes[];
   _xmlcfg_find_simple_array(handle, ss, foundNodes);
   foreach (attrNode in foundNodes) {
      outputFile := _xmlcfg_get_value(handle, attrNode);
      if (outputFile != '') {
         parent := _xmlcfg_get_parent(handle, attrNode);      // get the Config node
         parent = _xmlcfg_get_parent(handle, parent);    // get the Template node

         projType := _xmlcfg_get_attribute(handle, parent, 'Name');
         table:[projType] = true;
      }
   }

}

/**
 * Fills in the Project Types tree on Project > New.
 * 
 * @param p         List of project types with which to populate 
 *                  the tree view.
 */
static void fillProjectTree(PROJECTPACKS (&p):[])
{
   int index;

   _TreeDelete(TREE_ROOT_INDEX, "C");
   _TreeBeginUpdate(TREE_ROOT_INDEX);

   // add most recently used project types to tree
   index = AddMRUProjTypesToTree();

   PopulateProjectPacksTree(p);

   // update title of most recently used node
   if (index > 0)   {
      _TreeSetCaption(index, "Recently Used");
   }

   _TreeEndUpdate(TREE_ROOT_INDEX);
}

/**
 * Adds the Most Recently Used project types list to the project types tree as a node titled "Recently Used".
 * 
 * @return the index of the new "Recently Used" node.  -1 if it 
 *         was not added because of a lack of recently used
 *         types
 */
int AddMRUProjTypesToTree()
{
   if (!MRUProjectTypes._isempty()) {

      int lower = MRUProjectTypes._length();
      if (lower > def_max_proj_type_mru) {
         lower = def_max_proj_type_mru;
      }

      if (lower > 0) {
         int index = _TreeAddItem(TREE_ROOT_INDEX, "!Recently Used", TREE_ADD_AS_CHILD);
   
         int i;
         for (i = 0; i < lower; i++) {
            _TreeAddItem(index, MRUProjectTypes[i], TREE_ADD_AS_CHILD, 0, 0, -1);
         }
      
         return index;
      }
   }
   return -1;
}

void ctlBrowsedir.lbutton_up()
{
   int wid=p_window_id;
   typeless result=_ChooseDirDialog("",p_prev.p_text,"",CDN_PATH_MUST_EXIST|CDN_ALLOW_CREATE_DIR);
   if ( result=='' ) {
      return;
   }

   // we don't need quotes for this
   result = strip(result, 'B', '"');

   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
   return;
}
#if 0 //11:03am 6/17/1999
void _gn_filename.on_change()
{
   if (p_text == '') {
      ctladd_to_project.p_enabled = 0;
   } else if (_workspace_filename !='' ) {
      ctladd_to_project.p_enabled = 1;
   }
}
#endif

void ctladd_to_project.lbutton_up()
{
   ctladd_to_project_name.p_enabled=p_value!=0;
}

void _new_prjname.on_change()
{
   if (ctlExecutableName.p_enabled) {
      _str exename=_strip_filename(p_text,'pe');
      ctlExecutableName.p_text=exename;
   }

   if (ctlCreateProjDir.p_value) {
      UpdateReadOnlyLocation();
   }
}

void ctlCreateProjDir.lbutton_up()
{
   UpdateReadOnlyLocation();
}

defeventtab _workspace_properties_form;

#define WORKSPACE_MODIFIED ctlremove.p_user

_workspace_properties_form.on_resize()
{
   int xbuff=ctltree1.p_x;
   int ybuff=ctltree1.p_y;
   int form_width=_dx2lx(SM_TWIP,p_client_width);
   int form_height=_dy2ly(SM_TWIP,p_client_height);
   ctltree1.p_width=form_width-(xbuff+xbuff+ctlclose.p_width+xbuff);
   ctltree1.p_height=(form_height-(ctllabel1.p_y+ctllabel1.p_height))-(xbuff*2);
   ctlclose.p_x=ctltree1.p_x+ctltree1.p_width+xbuff;
   ctlnew.p_x=ctlproperties.p_x=ctldependencies.p_x=ctladd.p_x=ctlremove.p_x=ctlclose.p_x;
   ctlset_active.p_x=ctlnew.p_x;
   ctlenv.p_x=ctlnew.p_x;
   ctllabel1.p_caption=ctllabel1._ShrinkFilename(ctllabel1.p_user,form_width-(ctllabel1.p_x*2));
}

static void InitWorkspaceTree()
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
   InsertCurrentWorkspaceNames(_workspace_filename,false,-1,-1,TREE_ROOT_INDEX);
   _SetProjTreeColWidth();
   int index=_TreeSearch(TREE_ROOT_INDEX,_strip_filename(_project_name,'P')"\t",relative(_project_name,_GetWorkspaceDir()));
   if (index>-1) {
      _TreeSetCurIndex(index);
   }
   _str Files[];
   GetProjectFileArrayFromTree(Files);

   call_event(CHANGE_SELECTED,ctltree1,ON_CHANGE,'W');
}

ctlclose.on_create()
{
   ctllabel1.p_caption=_workspace_filename;
   ctllabel1.p_user=ctllabel1.p_caption;
   ctllabel1.p_width=ctllabel1._text_width(ctllabel1.p_caption);
   if (ctllabel1.p_width+ctllabel1.p_x>ctlclose.p_x) {
      p_active_form.p_width+=ctllabel1.p_x+ctllabel1.p_width-ctlclose.p_x;
   }
   int wid=p_window_id;
   ctltree1.InitWorkspaceTree();
}


void ctltree1.on_change(int reason)
{
   _str cur=_TreeCurIndex();
   if (cur==TREE_ROOT_INDEX||
       cur<0) {
      ctlproperties.p_enabled=ctlremove.p_enabled=ctldependencies.p_enabled=ctlset_active.p_enabled=0;
      return;
   }
   switch ( reason ) {
   case CHANGE_LEAF_ENTER:
      ctlproperties.call_event(ctlproperties,LBUTTON_UP);
      break;
   default:
      ctlset_active.p_enabled=ctldependencies.p_enabled=ctlproperties.p_enabled=1;
      if (!_IsAddDeleteProjectsSupportedWorkspaceFilename(_workspace_filename)) {
         ctlremove.p_enabled=ctladd.p_enabled=ctlnew.p_enabled=0;
      } else {
         ctlremove.p_enabled=ctladd.p_enabled=ctlnew.p_enabled=1;
      }
   }
}

ctltree1.enter()
{
   ctlclose.call_event(ctlclose,LBUTTON_UP);
}

void ctltree1.del()
{
   ctlremove.call_event(ctlremove,LBUTTON_UP);
}

int ctlremove.lbutton_up()
{
   if (!p_enabled) {
      return(COMMAND_CANCELLED_RC);
   }
   int wid=p_window_id;
   p_window_id=ctltree1;
   int curIndex=_TreeCurIndex();
   if (curIndex<0) {
      p_enabled=0;
      return(1);
   }
   _str curCap=_TreeGetCaption(curIndex);
   _str absName='';
   parse curCap with "\t" absName;
   int result=_message_box(nls("Do you wish to remove the file '%s' from this workspace?",absName),'',MB_OKCANCEL);
   if (result!= IDOK) {
      return(COMMAND_CANCELLED_RC);
   }
   int twid=p_window_id;
   int state=0,bm1=0,bm2NOLONGERUSED=0,flags=0;
   _TreeGetInfo(curIndex,state,bm1,bm2NOLONGERUSED,flags);
   _str NewActiveProject='';
   if (flags&TREENODE_BOLD) {//we are deleting the current project
      int newindex=_TreeGetPrevIndex(curIndex);
      if (newindex<0) {
         newindex=_TreeGetNextIndex(curIndex);
      }
      if (newindex>=0) {
         _str cap=_TreeGetCaption(newindex);
         _str name;
         parse cap with name "\t" NewActiveProject;
      }
   }
   int status=workspace_remove(absName,NewActiveProject);
   if (status) {
      _message_box(nls("Could not remove project '%s1'\n\n%s2",absName,get_message(status)));
      return(status);
   }
   p_window_id=twid;
   _TreeDelete(curIndex);
   if (NewActiveProject!='') {
      int index=_TreeSearch(TREE_ROOT_INDEX,_strip_filename(_project_name,'P')"\t"_project_name,_fpos_case);
      if (index>-1) {
         _TreeGetInfo(index,state,bm1,bm2NOLONGERUSED,flags);
         _TreeSetInfo(index,state,bm1,bm2NOLONGERUSED,flags|TREENODE_BOLD);
      }
   }

   _TreeRefresh();
   p_window_id=wid;
   return(0);
}

void ctltree1.ins()
{
   ctladd.call_event(ctladd,LBUTTON_UP);
}

static void SortAndFixBold(int newIndex,boolean doSort=true)
{
   if (doSort) {
      _TreeSortCaption(TREE_ROOT_INDEX,_fpos_case);
   }
   int state=0,bm1=0,bm2NOLONGERUSED=0,flags=0;
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;index>-1;) {
      _TreeGetInfo(index,state,bm1,bm2NOLONGERUSED,flags);
      if (index!=newIndex && flags&TREENODE_BOLD) {
         _TreeSetInfo(index,state,bm1,bm2NOLONGERUSED,flags&~TREENODE_BOLD);
         break;
      }
      index=_TreeGetNextIndex(index);
   }
   _TreeSetCurIndex(newIndex);
}

int ctladd.lbutton_up()
{
   // remember the associated type of this workspace.  empty implies no association
   _str associationType = _WorkspaceGet_AssociatedFileType(gWorkspaceHandle);

   _str format_list='Project Files(*'PRJ_FILE_EXT')';
   _str defaultExt = '*' PRJ_FILE_EXT;

   // if this is a jbuilder associated workspace, only allow jbuilder projects
   if (associationType == JBUILDER_VENDOR_NAME) {
      format_list='JBuilder Project Files(*'JBUILDER_PROJECT_EXT')';
      defaultExt = '*' JBUILDER_PROJECT_EXT;
   }

   _str FileName=_OpenDialog('-new -modal',
                             'Add Project to Workspace',
                             '',     // Initial wildcards
                             format_list,  // file types
                             OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT,
                             defaultExt,      // Default extensions
                             '',      // Initial filename
                             '',      // Initial directory
                             '',      // Reserved
                             ''
                            );
   if (FileName=='') {
      return(COMMAND_CANCELLED_RC);
   }

   _str filenameList = FileName;
   for (;;) {
      // parse the list of filenames
      FileName = parse_file(filenameList, false);
      if (FileName == "") break;

      int oldwid=p_window_id;
      int status=workspace_insert(FileName,false,false,false);
      p_window_id=oldwid;
      if (status) {
         _message_box(nls("Could not add project '%s1'\n\n%s2",FileName,get_message(status)));
         return(status);
      }

      useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
      _workspace_update_files_retag(false, false, false, false, false, false, useThread);
      int wid=p_window_id;
   }

   ctltree1.InitWorkspaceTree();
   return(0);
}

void ctlnew.lbutton_up()
{
   _param1=null;

   _str Files[];
   _str Dependencies:[];
   ctltree1.GetProjectFileArrayFromTree(Files);

   _str oldproject_name=_project_name;
   show('-modal -mdi _workspace_new_form','D');
   if (!file_eq(oldproject_name,_project_name)) {
      ctltree1.InitWorkspaceTree();
   }
}

static void AddMacroRecordingForHashtab(_str HashTab:[],_str varname)
{
   _macro_append('_str 'varname':[];');
   _macro_append(varname'._makeempty();');
   typeless i;
   for (i._makeempty();;) {
      HashTab._nextel(i);
      if (i._isempty()) break;
      if (HashTab._indexin(i)) {
         _macro_append(varname':['_quote(i)']='_quote(HashTab:[i])';');
      } else {
         _macro_append(varname':['_quote(i)"]='';");
      }
   }
}

void ctlclose.lbutton_up()
{
   p_active_form._delete_window();
}

static boolean IsNewFile(_str relname,_str (&OrigProjectNames)[])
{
   int i;
   for (i=0;i<OrigProjectNames._length();++i) {
      if (file_eq(relname,OrigProjectNames[i])) {
         OrigProjectNames._deleteel(i);
         return(false);
      }
   }
   return(true);
}

void ctlproperties.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   //_str ProjectName=_TreeGetCaption(index);
   //parse ProjectName with "\t" relName;
   //ProjectName=_AbsoluteToWorkspace(relName);
   _str ProjectName=CurProjFromTree();
   _str old_prjname=_project_name;
   _project_name=VSEProjectFilename(ProjectName);
   project_edit();
   _project_name=old_prjname;
   p_window_id=wid;
}

// 7/26/2011 - Currently tree control doesn't get lbutton_double_click
//void ctltree1.lbutton_double_click()
//{
//   ctlproperties.call_event(ctlproperties,LBUTTON_UP);
//}

void ctlset_active.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   _str OrigProjectName=_project_name;
   int state=0,bm1=0,bm2NOLONGERUSED=0,flags=0;
   if (index>-1) {
      _TreeGetInfo(index,state,bm1,bm2NOLONGERUSED,flags);
      _TreeSetInfo(index,state,bm1,bm2NOLONGERUSED,flags|TREENODE_BOLD);
      _str cap=_TreeGetCaption(index);
      _str name='',absName='';
      parse cap with name "\t" absName;
      _str ProjectName=VSEProjectFilename(absName);
      workspace_set_active(ProjectName,true,true);
   }
   if (OrigProjectName!=_project_name) {
      SortAndFixBold(index,false);
   }
   p_window_id=wid;
}

void ctlenv.lbutton_up()
{
   _ModifyWorkspaceEnvVars();
}

static void GetProjectFileArrayFromTree(_str (&Files)[])
{
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for (;index>-1;) {
      _str cap=_TreeGetCaption(index);
      _str name='',WholeName='';
      parse cap with name "\t" WholeName;
      _str relName=_RelativeToWorkspace(WholeName);
      Files[Files._length()]=relName;
      index=_TreeGetNextIndex(index);
   }
}

static _str CurProjFromTree()
{
   _str cap='';
   int index=ctltree1._TreeCurIndex();
   if (index>-1) {
      cap=ctltree1._TreeGetCaption(index);
   }
   _str relName='';
   parse cap with "\t" relName;
   _str Filename=_AbsoluteToWorkspace(relName);
   return(Filename);
}

void ctldependencies.lbutton_up()
{
   _str Files[];
   _str Dependencies:[];
   ctltree1.GetProjectFileArrayFromTree(Files);
   _param1=null;
   _str Project=CurProjFromTree();
   workspace_dependencies(Project);
}
static _str GetDateFromView(_str Filename,int DateViewId)
{
   int orig_view_id=p_window_id;
   p_window_id=DateViewId;
   top();up();
   int status=search('^'_escape_re_chars(Filename)'=','@rh'_fpos_case);
   if (status) {
      p_window_id=orig_view_id;
      return('');
   }
   get_line(auto line);
   _str date='';
   parse line with '=' date;
   _delete_line();  // Delete the line so we know this project has been processed
   p_window_id=orig_view_id;
   return(date);
}

static void SyncDates(int DateViewId,_str ProjectFiles[])
{
   int orig_view_id=p_window_id;
   p_window_id=DateViewId;
   _lbclear();
   _IsWorkspaceAssociated=_IsWorkspaceAssociated(_workspace_filename);
   workspaceDir:=_GetWorkspaceDir();
   if (ProjectFiles!=null) {
      int i;
      for (i=0;i<ProjectFiles._length();++i) {
         _str CurFilename=absolute(ProjectFiles[i],workspaceDir);
         if (_IsWorkspaceAssociated) {
            CurFilename=GetProjectDisplayName(CurFilename);
         }
         insert_line(_RelativeToWorkspace(GetProjectDisplayName(_AbsoluteToWorkspace(ProjectFiles[i])))'='_file_date(CurFilename,'B'));
      }
   }
   p_window_id=orig_view_id;
}

static int GetAllFilesInTagfile(_str TagFilename,int &FilesViewId)
{
   int orig_view_id=_create_temp_view(FilesViewId);
   int status = tag_read_db(TagFilename);
   if (status < 0) {
      return status;
   }
   _str filename='';
   status=tag_find_file(filename);
   while (!status) {
      insert_line(filename);
      status=tag_next_file(filename);
   }
   tag_reset_find_file();
   tag_close_db(TagFilename,true);
   p_window_id=orig_view_id;
   return(0);
}

static int GetAllFilesInWorkspace(int &FilesViewId)
{
   _str ProjectNames[]=null;
   int status=_GetWorkspaceFiles(_workspace_filename,ProjectNames);
   if (status) return(status)
      int orig_view_id=_create_temp_view(FilesViewId);
   int i,len=ProjectNames._length();
   for (i=0;i<len;++i) {
      _str afilename=absolute(ProjectNames[i],_strip_filename(_workspace_filename,'N'));
      GetProjectFiles(afilename,FilesViewId,'',null,'',false);
   }
   p_window_id=orig_view_id;
   return(0);
}
int def_eclipse_retag_files=1;
static _str gEclipseProjectFiles[]=null;
static boolean NeedToRetagEclipseWorkspace(_str (&ProjectFiles)[])
{
   if (ProjectFiles._length() != gEclipseProjectFiles._length()) {
      gEclipseProjectFiles=ProjectFiles;
      gEclipseProjectFiles._sort('f');
      return(true);
   }
   _str temp[]=null;
   temp=ProjectFiles;
   temp._sort('f');

   boolean mismatch=false;
   int i;
   for (i=0;i<ProjectFiles._length();++i) {
      if (!file_eq(temp[i],gEclipseProjectFiles[i])) {
         mismatch=true;
         break;
      }
   }
   if (mismatch) {
      gEclipseProjectFiles=temp;
      return(true);
   }
   if (def_eclipse_retag_files) {
      static int NumFilesTagged;
      int OldNumFilesTagged=NumFilesTagged;

      CurNumFiles := 0;
      _str fileList[];
      for (i=0;i<ProjectFiles._length();++i) {
         fileList._makeempty();
         _getProjectFiles(_workspace_filename, ProjectFiles[i], fileList, 1);
         CurNumFiles += fileList._length();
      }

      NumFilesTagged=CurNumFiles;
      if (OldNumFilesTagged!=CurNumFiles) {
         return(true);
      }
   }
   return(false);
}

/** 
 * Rebuild the workspace tag file if it is or may be out of date. 
 * Will check the date of all the project files in the workspace to 
 * verify that they have not changed. 
 *  
 * @param GettingFocus 
 *        'true' if we were called form the application activation callback
 *  
 * @param AssociationOverride 
 *        Override associated workspace
 *  
 * @param alreadyCalled_AssiciatedWorkspace 
 *        'true' if already done for associated workspace
 *  
 * @param alreadyUpdaedWorkspaceList 
 *        'true' if we already updated the project tool window (or plan to)
 *        Helps us avoid redundant work.
 *  
 * @categories Tagging_Functions
 */
void _MaybeRetagWorkspace(typeless GettingFocus,
                          boolean AssociationOverride=false,
                          boolean alreadyCalled_AssociateWorkspace=false,
                          boolean alreadyUpdatedWorkspaceList=false)
{
   //the plugin manages its own tag files.
   if (isEclipsePlugin()) {
      return;
   }
   if (_workspace_filename==''/* || !_IsWorkspaceAssociated(_workspace_filename) */) {
      //If we got called from _actapp_makefile, we only want to do this if we
      //are in an associated makefile.  Sometimes we want to be able to override
      //this to call this directly to check dates on a normal workspace when
      //we open it.
      if (!AssociationOverride) {
         return;
      }
   }
   _str ProjectFiles[];
   _GetWorkspaceFiles(_workspace_filename,ProjectFiles);
   boolean SetDates=false;
   boolean doRetagFiles=false;

   int orig_view_id=0;
   get_window_id(orig_view_id);
   int temp_view_id=0;
   int status=_ini_get_section(VSEWorkspaceStateFilename(_workspace_filename),"ProjectDates",temp_view_id);
   if (status) {
      doRetagFiles=true;
      orig_view_id=_create_temp_view(temp_view_id);
      SyncDates(temp_view_id,ProjectFiles);
      _ini_put_section(VSEWorkspaceStateFilename(_workspace_filename),"ProjectDates",temp_view_id);
      status=_ini_get_section(VSEWorkspaceStateFilename(_workspace_filename),"ProjectDates",temp_view_id);
      if (status) {
         return;
      }
   }

   if (_IsEclipseWorkspaceFilename(_workspace_filename)) {
      if (NeedToRetagEclipseWorkspace(ProjectFiles)) {
         doRetagFiles=true;
      }
   } else {
      int i;
      for (i=0;i<ProjectFiles._length();++i) {

         _str DisplayName=GetProjectDisplayName(_AbsoluteToWorkspace(ProjectFiles[i]));
         _str VSEDate=GetDateFromView(_RelativeToWorkspace(DisplayName),temp_view_id);

         if (VSEDate!=_file_date(DisplayName,'B')) {
            message(nls('The project file %s changed.  SlickEdit is updating tag files',GetProjectDisplayName(ProjectFiles[i])));
            doRetagFiles=true;
         }
      }
      if (_IsWorkspaceAssociated(_workspace_filename)) {
         activate_window(temp_view_id);
         // We any projects removed from the workspace
         if (p_Noflines) {
            doRetagFiles=true;
         }
         activate_window(orig_view_id);
      }
   }

   _str TagFilename=project_tags_filename();
   if (!file_eq(tag_current_db(), TagFilename)) {
      if (!file_exists(TagFilename)) {
         message(nls('The workspace tag file %s is missing.  SlickEdit is rebuilding it',TagFilename));
         doRetagFiles=true;
      } else {
         status = tag_read_db(TagFilename);
         if (status == ACCESS_DENIED_RC) {
            message(nls('The workspace tag file %s is unreadable or being used by another process.',TagFilename));
            doRetagFiles=false;
         } else if (status >= 0) {
            status = tag_open_db(TagFilename);
            if (status == ACCESS_DENIED_RC) {
               message(nls('The workspace tag file %s is read only or being used by another process.',TagFilename));
               doRetagFiles=false;
            }
            status = tag_read_db(TagFilename);
         } else {
            message(nls('The workspace tag file %s is unreadable or corrupt.  SlickEdit is rebuilding it',TagFilename));
            doRetagFiles=true;
         }
      }
   }

   // If the tag file doesn't really need to be updated, but the user has
   // things configured to updated the workspace on a thread, then we can
   // safely trigger the workspace file to be updated now anyway, even if
   // no project files have changed, there could be source files that changed. 
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   if (useThread && !doRetagFiles) {
      _workspace_update_files_retag(false,true,true,true,true,true,true);
   }

   if (!doRetagFiles) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return;
   }
 
   if (_IsWorkspaceAssociated(_workspace_filename)) {
      if (!alreadyCalled_AssociateWorkspace) {
         //Look for this with Eclipse
         cur_project_name := "";
         _WorkspaceAssociate(_workspace_filename);
         _ini_get_value(VSEWorkspaceStateFilename(_workspace_filename),"Global","CurrentProject",cur_project_name);
         if (cur_project_name!=_project_name) {
            workspace_set_active(cur_project_name);
         }
      }
      _workspace_update_files_retag(false,true,true,true,true,true,useThread);

      // only call this if we haven't already updated the project toolbar
      if (!alreadyUpdatedWorkspaceList) {
         toolbarUpdateWorkspaceList();
         SyncDates(temp_view_id,ProjectFiles);
      }

   } else {

      if (useThread) {
         _workspace_update_files_retag(false,true,true,true,true,true,useThread);

      } else {

         //_workspace_update_files_retag(false,true,true,true);
         int NewFilesViewId,OrigFilesViewId;

         _ProjectCache_Update();
         status=GetAllFilesInWorkspace(NewFilesViewId);
         if (status) {
            // If this fails, NewFilesViewId is likely invalid
            p_window_id=orig_view_id;
            _delete_temp_view(temp_view_id);
            return;
         }
         GetAllFilesInTagfile(TagFilename,OrigFilesViewId);
         // After calling GetAllFilesInTagfile, we don't have to check the
         // status.  The view for OrigFilesViewId is already created, so if
         // we could not open the tagfile and end up with a blank view, that
         // will be ok.

         orig_view_id=p_window_id;
         p_window_id=NewFilesViewId;
         sort_buffer('-fc');
         _remove_duplicates(_fpos_case);
         p_window_id=OrigFilesViewId;
         sort_buffer('-fc');
         _remove_duplicates(_fpos_case);
         p_window_id=orig_view_id;

         int database_flags=(def_references_options & VSREF_NO_WORKSPACE_REFS)? 0:VS_DBFLAG_occurrences;
         _TagUpdateFromViews(TagFilename,NewFilesViewId,OrigFilesViewId,
                             true,_project_name,null,null,
                             database_flags,useThread);
      }
   }

   // only call this if we haven't already updated the project toolbar
   if (!alreadyUpdatedWorkspaceList) {
      toolbarUpdateWorkspaceList();
      SyncDates(temp_view_id,ProjectFiles);
      status=_ini_put_section(VSEWorkspaceStateFilename(_workspace_filename),"ProjectDates",temp_view_id);
      call_list('_prjupdate_');
   }
   /*
     Only need to update the dependencies when doRetagFiles is true.
     toolbarUpdateWorkspaceList(), _RestoreProjTreeStates(), and
     _proj_tooltab_tree.on_change(int reason) has been changed to update
     the dependencies on a per project base.
   */
   //toolbarUpdateDependencies();
}
static void _ProjectUpdateConfig(int handle)
{
   _str array[];
   _ProjectGet_ConfigNames(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      _str type=_ProjectGet_Type(handle,array[i]);
      if (type=='java') {
         int ConfigNode=_ProjectGet_ConfigNode(handle,array[i]);
         _str ver=_xmlcfg_get_attribute(handle,ConfigNode,'Version');
         if (ver<6) {
#if 0
            int Node=_xmlcfg_find_simple(handle,VPJTAG_MENU'/'VPJTAG_TARGET:+XPATH_STRIEQ('Name','Javadoc All'),ConfigNode);
            if (Node>=0) {
               Node=_xmlcfg_add(handle,Node,VPJTAG_TARGET,VSXMLCFG_NODE_ELEMENT_START_END,0);
               _xmlcfg_set_attribute(handle,Node,'Name','Activate GUI Builder');
               _xmlcfg_set_attribute(handle,Node,'MenuCaption','Activat&e GUI Builder');
               _xmlcfg_set_attribute(handle,Node,'Deletable','0');
               Node=_xmlcfg_add(handle,Node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_set_attribute(handle,Node,'CmdLine','jguiLaunch');
               _xmlcfg_set_attribute(handle,Node,'Type','Slick-C');
            }
#endif
            _xmlcfg_set_attribute(handle,ConfigNode,'Version',6);
            _ProjectSave(handle);
         }
         if (ver<7) {
            int Node=_xmlcfg_find_simple(handle,VPJTAG_MENU'/'VPJTAG_TARGET:+XPATH_STRIEQ('Name','GUI Builder'),ConfigNode);
            if (Node<0) {
               Node=_xmlcfg_find_simple(handle,VPJTAG_MENU'/'VPJTAG_TARGET:+XPATH_STRIEQ('Name','Activate GUI Builder'),ConfigNode);
            }
            if (Node>=0) {
               _xmlcfg_delete(handle,Node);
            }
         }
         if (ver<8) {
            if (_xmlcfg_get_attribute(handle, ConfigNode, 'CompilerConfigName','') == '') {
               _xmlcfg_set_attribute(handle, ConfigNode, 'CompilerConfigName', COMPILER_NAME_LATEST);
            }
            _xmlcfg_set_attribute(handle, ConfigNode, 'Version', 8);
            _ProjectSave(handle);
         }
      }else if (type=='') {
         _str associatedProjectType=_ProjectGet_AssociatedFileType(handle);
         if ( substr(associatedProjectType,1,length(VISUAL_STUDIO_VENDOR_NAME)) == VISUAL_STUDIO_VENDOR_NAME ) {
            // Check the version and see if we need to add the debugger callback
            int ConfigNode=_ProjectGet_ConfigNode(handle,array[i]);
            _str callback_name=_xmlcfg_get_attribute(handle,ConfigNode,'DebugCallbackName');
            // Just look @ type and command
            _str vcpp_project_filename=absolute(_ProjectGet_AssociatedFile(handle),_file_path(_ProjectGet_Filename(handle)) );
#if 0
            if ( callback_name=='' && _IsVisualStudioCLRProject( vcpp_project_filename ) ) {
               // No initial version, add clr debugger

               // Find the Debug target
               int origDebugIndex=_xmlcfg_find_simple(handle,"Menu/Target[@Name='OrigDebug']",ConfigNode);
               int debugIndex=_xmlcfg_find_simple(handle,"Menu/Target[@Name='Debug']",ConfigNode);
               if ( (debugIndex>=0) && (origDebugIndex < 0) ) {
                  _xmlcfg_set_attribute(handle,debugIndex,'EnableBuildFirst',"0");
                  // Make a copy of Debug to OrigDebug
                  int newDebugIndex=_xmlcfg_copy(handle,debugIndex,handle,debugIndex,0);
                  if ( newDebugIndex>=0 ) {
                     _xmlcfg_set_attribute(handle,newDebugIndex,"Name","OrigDebug");
                     _xmlcfg_set_attribute(handle,newDebugIndex,"MenuCaption","Old Debug Command");
                  }
                  // DJB 03-18-2008
                  // Integrated .NET debugging is no longer available as of SlickEdit 2008
                  // 
                  // Find the Exec command, and change it to vsclrdebug
                  //int execIndex=_xmlcfg_find_simple(handle,"Exec",debugIndex);
                  //if ( execIndex>=0 ) {
                  //   _xmlcfg_set_attribute(handle,execIndex,"CmdLine","vsclrdebug");
                  //}
                  // Set the version so we don't do this again
                  //_xmlcfg_set_attribute(handle,ConfigNode,'DebugCallbackName',"dotnet");
                  _xmlcfg_set_attribute(handle,ConfigNode,'DebugCallbackName',"");
                  _ProjectSave(handle);
               }
            }
#endif
            _str ext = _get_extension(vcpp_project_filename,1);
            if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
                file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) ||
                file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
               // add support for windbg debugging
               _str type_name = _xmlcfg_get_attribute(handle,ConfigNode,'Type');
               if (type_name == '') {
                  _xmlcfg_set_attribute(handle,ConfigNode,'Type',"vcproj");
                  _xmlcfg_set_attribute(handle,ConfigNode,'DebugCallbackName','windbg');
                  int debugIndex = _xmlcfg_find_simple(handle,"Menu/Target[@Name='Debug']", ConfigNode);
                  if (debugIndex > 0) {
                      int newOldDebugIndex = _xmlcfg_copy(handle, debugIndex, handle, debugIndex, 0);
                     _xmlcfg_set_attribute(handle, newOldDebugIndex, "Name", "DebugVisualStudio");
                     _xmlcfg_set_attribute(handle, newOldDebugIndex, "MenuCaption", "Debug - Visual Studio");

                     int newDebugIndex = _xmlcfg_copy(handle, newOldDebugIndex, handle, debugIndex, 0);
                     _xmlcfg_set_attribute(handle, newDebugIndex, "Name", "DebugWinDbg");
                     _xmlcfg_set_attribute(handle, newDebugIndex, "MenuCaption", "Debug - WinDbg");
                     int execNode = _xmlcfg_find_simple(handle, VPJTAG_EXEC, newDebugIndex);
                     if (execNode < 0) {
                        execNode = _xmlcfg_add(handle, newDebugIndex, VPJTAG_EXEC, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
                     }
                     if (execNode > 0) {
                        _xmlcfg_set_attribute(handle, execNode, 'CmdLine', 'vcproj_windbg_debug');
                        _xmlcfg_set_attribute(handle, execNode, 'Type', 'Slick-C');
                     }

                     execNode = _xmlcfg_find_simple(handle, VPJTAG_EXEC, debugIndex);
                     if (execNode > 0) {
                        _xmlcfg_set_attribute(handle, execNode, 'CmdLine', 'vcproj_visual_studio_debug');
                        _xmlcfg_set_attribute(handle, execNode, 'Type', 'Slick-C');
                     }
                  }
                  _ProjectSave(handle);
               }
            }
         }
      }
   }
}
int _ProjectHandle(_str ProjectName=_project_name,int &status=0)
{
   if (ProjectName=='') {
      return(gProjectExtHandle);
   }
   ProjectNameCased := _file_case(ProjectName);
   int *phandle=gProjectHashTab._indexin(ProjectNameCased);
   if (phandle) {
      return(*phandle);
   }
   int handle=0;
   if (!file_eq(_get_extension(ProjectName,true),PRJ_FILE_EXT)) {
      // Check for extension specific project file
      extfilename := _ConfigPath():+VSCFGFILE_USER_EXTPROJECTS;
      if (file_eq(ProjectName, extfilename)) {
         return(gProjectExtHandle);
      }
      _message_box(nls("Project '%s' should have %s2 extension",ProjectName,PRJ_FILE_EXT));
      handle=_ProjectCreate('');
      status=1;
      //_UpdateSlickCStack(0);
      //_message_box(nls("Slick-C error: Call to _ProjectHandle with bad file name.  Project '%s' should have %s2 extension",ProjectName,PRJ_FILE_EXT));
      //stop();
   }
   if (!file_eq(absolute(ProjectName),ProjectName)) {
      _message_box(nls("Project '%s' should be absolute",ProjectName));
      handle=_ProjectCreate('');
      status=1;
      //_UpdateSlickCStack(0);
      //_message_box(nls("Slick-C error: Call to _ProjectHandle with relative or bad FILESEP project filename.  Project '%s' should be absolute",ProjectName));
      //stop();
   }
   if (!status) {
      handle=_xmlcfg_open(ProjectName,status);
      if (handle<0) {
         if (status==FILE_NOT_FOUND_RC || status==PATH_NOT_FOUND_RC) {
            _message_box(nls("Project file '%s' not found",ProjectName));
            /*
               We could create the project here but what configurations do we add?
               Here we create an invalid filename so this project will never get saved.
               _ProjectSave() looks for a blank filename and does nothing.
            */
            handle=_ProjectCreate('');
            status=1;
         } else if (status && status>VSRC_XMLCFG_EXPECTING_ROOT_ELEMENT_NAME /* First XMLCFG error.  I/O error */) {
            _message_box(nls("Error opening project file '%s'\n\n",ProjectName):+get_message(status));
            /*
               We could create the project here but what configurations do we add?
               Here we create an invalid filename so this project will never get saved.
               _ProjectSave() looks for a blank filename and does nothing.
            */
            handle=_ProjectCreate('');
            status=1;

         } else {
            if (!_ini_is_valid(ProjectName)) {
               //_UpdateSlickCStack(0);
               _message_box(nls("Project '%s' is not recognized as valid",ProjectName));
               handle=_xmlcfg_create('',VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);
               gProjectHashTab:[ProjectNameCased]=handle;
               status=1;
               return(handle);
            }
            typeless projectVersion;
            _ini_get_value(ProjectName,"GLOBAL","version",projectVersion,0);
            if (projectVersion>PROJECT_FILE_VERSION) {
               _message_box(nls("Unable to convert project file %s\n\nVersion %s not supported",ProjectName,projectVersion));
               handle=_xmlcfg_create('',VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);
               gProjectHashTab:[ProjectNameCased]=handle;
               status=1;
               return(handle);
            }
            status=_ProjectConvert70ToXML(ProjectName);
            if (status) {
               return(status);
            }
            p_window_id._WorkspacePutProjectDate(ProjectName);

            handle=_xmlcfg_open(ProjectName,status);
            if (handle<0) {
               _message_box(nls("Project '%s' is not recognized as valid.  There must have been a problem converting the workspace to the new format",ProjectName));
               handle=_xmlcfg_create('',VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);
               gProjectHashTab:[ProjectNameCased]=handle;
               status=1;
               return(handle);
            }
         }
      }
   }

   // verify project vendor
   if (!strieq(_xmlcfg_get_path(handle,VPJX_PROJECT,"VendorName"),'SlickEdit')) {
      _message_box(nls("Project '%s' is not recognized as valid.  VendorName attribute not set to SlickEdit",ProjectName));
      status=1;
      return(-1);
   }

   // verify project version
   double xmlProjectVersion;
   if (!ProjectIsCompatible(handle,xmlProjectVersion)) {
      // make backup before changes are saved
      copy_file(ProjectName, _strip_filename(ProjectName, 'E') PRJ_FILE_BACKUP_EXT);

      // see if it is a version that is upgradable
      status=0;

      if (xmlProjectVersion == 8.0 || xmlProjectVersion == 8.01) {
         status=_ProjectConvert80To81(ProjectName, handle);
         xmlProjectVersion = (typeless)_xmlcfg_get_path(handle,VPJX_PROJECT,"Version");
      }

      if ((!status)&&(xmlProjectVersion == VPJ_FILE_VERSION81)) {
         status=_ProjectConvert81To90(ProjectName, handle);
         xmlProjectVersion = (typeless)_xmlcfg_get_path(handle,VPJX_PROJECT,"Version");
      }

      if ((!status)&&(xmlProjectVersion == VPJ_FILE_VERSION90)) {
         status=_ProjectConvert90To91(ProjectName, handle);
         xmlProjectVersion = (typeless)_xmlcfg_get_path(handle,VPJX_PROJECT,"Version");
      }

      if ((!status)&&(xmlProjectVersion == VPJ_FILE_VERSION91)) {
         status=_ProjectConvert91To100(ProjectName, handle);
         xmlProjectVersion = (typeless)_xmlcfg_get_path(handle,VPJX_PROJECT,"Version");
      }

      // see if the file is still not the proper version
      if ((status)||(xmlProjectVersion != VPJ_FILE_VERSION)) {
         _message_box(nls("Project '%s' is not recognized as valid.  Incorrect version",ProjectName));
         status=1;
         return(-1);
      }
   }
   gProjectHashTab:[ProjectNameCased]=handle;
   _ProjectUpdateConfig(handle);
   return(handle);
}

int _ProjectGet_AssociatedHandle(int handle,int &status=0)
{
   return(_ProjectAssociatedHandle(_AbsoluteToProject(_ProjectGet_AssociatedFile(handle),_xmlcfg_get_filename(handle)),status));
}
int _ProjectAssociatedHandle(_str ProjectName,int &status=0)
{
   status=0;
   ProjectNameCased := _file_case(ProjectName);
   int *phandle=gProjectHashTab._indexin(ProjectNameCased);
   if (phandle) {
      return(*phandle);
   }
   ProjectExtension := _get_extension(ProjectName,true);
   if (!file_eq(ProjectExtension,VISUAL_STUDIO_VB_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_VCPP_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_VCX_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_CSHARP_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_FSHARP_PROJECT_EXT) &&
       !file_eq(ProjectExtension,VISUAL_STUDIO_JSHARP_PROJECT_EXT) &&
       !file_eq(ProjectExtension,JBUILDER_PROJECT_EXT) && 
       !file_eq(ProjectExtension,MACROMEDIA_FLASH_PROJECT_EXT)) {
      _UpdateSlickCStack(0);
      _message_box(nls("Slick-C"VSREGISTEREDTM" error: Call to _ProjectAssociatedHandle with unsupported file name '%s'.",ProjectName));
      stop();
   }
   if (!file_eq(absolute(ProjectName),ProjectName)) {
      _UpdateSlickCStack(0);
      _message_box(nls("Slick-C"VSREGISTEREDTM" error: Call to _ProjectAssociatedHandle with relative or bad FILESEP project filename.  Project '%s' should be absolute",ProjectName));
      stop();
   }

   // NB: There was code here to open vcproj files with VSCP_ACTIVE_CODEPAGE, and
   // all others with the default (VSENCODING_AUTOXML). But vcproj files can also be
   // utf-8 or unicode, so we should use VSENCODING_AUTOXML in all cases.
   int handle=_xmlcfg_open(ProjectName,status);
   if (handle<0) {
      if (status==FILE_NOT_FOUND_RC || status==PATH_NOT_FOUND_RC) {
         _message_box(nls("Project file '%s' not found",ProjectName));
         /*
            We could create the project here but what configurations do we add?
            Here we create an invalid filename so this project will never get saved.
            _ProjectSave() looks for a blank filename and does nothing.
         */
         handle=_ProjectCreate('');
         status=1;
      } else {
         //_UpdateSlickCStack(0);
         _message_box(nls("Project '%s' is not recognized as valid",ProjectName));
         handle=_xmlcfg_create('',VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);
         gProjectHashTab:[ProjectNameCased]=handle;
         status=1;
         return(handle);
      }
   }

   if (handle >= 0 && file_eq(ProjectExtension,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      node := _xmlcfg_find_simple(handle,'/VisualStudioProject');
      if (node > 0) {
         nestedProjectName := _xmlcfg_get_attribute(handle, node, 'VCNestedProjectFileName');
         if (nestedProjectName != '') {
            nestedHandle := _xmlcfg_open(nestedProjectName, status);
            if (nestedHandle > 0) {
               _xmlcfg_close(handle);
               handle = nestedHandle;
            }
         }
      }
   }

   gProjectHashTab:[ProjectNameCased]=handle;

   // if this is a jbuilder project, massage the xml syntax so that the
   // files and folders look like a vse project.  during _ProjectSave(),
   // the syntax will be changed back to normal jbuilder syntax
   if (handle >= 0 && file_eq(ProjectExtension,JBUILDER_PROJECT_EXT)) {
      _convertJBuilderXML(handle, true);

      // IMPORTANT: wildcards are intentionally not expanded here.  wildcards should
      //            only be expanded when filling in the project toolbar
   }

   return(handle);
}

void _ProjectCache_Update(_str ProjectName='')
{
   if (_workspace_filename=='') {
      return;
   }
   if (ProjectName=='') {
      typeless i;
      for (i._makeempty();;) {
         int handle=gProjectHashTab._nextel(i);
         if (i._isempty()) break;
         _xmlcfg_close(handle);
      }
      gProjectHashTab._makeempty();
   } else {
      ProjectNameCased := _file_case(ProjectName);
      int *phandle=gProjectHashTab._indexin(ProjectNameCased);
      if (phandle) {
         _xmlcfg_close(*phandle);
         gProjectHashTab._deleteel(ProjectNameCased);
      }
   }
}
static _str sectionsToMove[]={
   'State','TreeExpansion','ProjectDates'
};

int _WorkspaceCreate(_str WorkspaceFilename)
{
   int handle=_xmlcfg_create(WorkspaceFilename,VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CREATE);

   // add the doctype
   int doctypeNode = _xmlcfg_add(handle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", VPWTAG_WORKSPACE);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPW_DTD_PATH);

   _xmlcfg_set_path(handle,VPWX_WORKSPACE,'Version',VPW_FILE_VERSION);
   _xmlcfg_set_path(handle,VPWX_WORKSPACE,'VendorName','SlickEdit');
   return(handle);
}
void _WorkspaceCache_Update()
{
   if (_workspace_filename=='') {
      return;
   }
   int status=_WorkspaceOpenAndUpdate(_workspace_filename);
   if (!status) {
      _str WorkspaceFilename=_workspace_filename;
      _str ProjectName='';
      _str cur_project_name='';

      _str ProjectFiles[];
      _GetWorkspaceFiles(WorkspaceFilename, ProjectFiles);
      status=_ini_get_value(VSEWorkspaceStateFilename(WorkspaceFilename), "Global", "CurrentProject", cur_project_name);
      if (cur_project_name != '') {
         boolean projectFound = false;
         int i;
         for (i = 0; i < ProjectFiles._length(); ++i) {
            if (file_eq(cur_project_name, ProjectFiles[i])) {
               projectFound = true;
               break;
            }
         }
         if (!projectFound) {
            cur_project_name = '';
         } else {
            ProjectName = absolute(cur_project_name, _strip_filename(WorkspaceFilename,'N'));
         }
      }
      if (cur_project_name == '' && ProjectFiles._length()) {
         ProjectName = absolute(ProjectFiles[0], _strip_filename(WorkspaceFilename,'N'));
      }
      //_macro_call('workspace_open',_workspace_filename);

      workspace_set_active(ProjectName,true,true,false);
   }
}

static boolean WorkspaceIsCompatible(int handle, double& xmlWorkspaceVersion)
{
   xmlWorkspaceVersion = (typeless)_xmlcfg_get_path(handle,VPWX_WORKSPACE,"Version");
   if (xmlWorkspaceVersion == VPW_FILE_VERSION) {
      return true;
   }

   int index=_xmlcfg_find_simple(handle,VPWX_COMPATIBLEVERSIONS'/'VPWTAG_PREVVERSION"[@VersionNumber='"VPW_FILE_VERSION"']");
   return(index>=0);
}

static boolean ProjectIsCompatible(int handle, double& xmlProjectVersion)
{
   xmlProjectVersion = (typeless)_xmlcfg_get_path(handle,VPJX_PROJECT,"Version");
   if (xmlProjectVersion == VPJ_FILE_VERSION) {
      return true;
   }

   int index=_xmlcfg_find_simple(handle,VPJX_COMPATIBLEVERSIONS'/'VPJTAG_PREVVERSION"[@VersionNumber='"VPJ_FILE_VERSION"']");
   return(index>=0);
}

static int _WorkspaceOpenAndUpdate(_str WorkspaceFilename)
{
   if (!file_exists(WorkspaceFilename)) {
      _message_box(nls("Workspace '%s' not found",WorkspaceFilename));
      return(FILE_NOT_FOUND_RC);
   }

   _str VSEWorkspace=VSEWorkspaceFilename(WorkspaceFilename);
   typeless WorkspaceVersion;

   _str line='';
   int status=0;
   int handle=_xmlcfg_open(VSEWorkspace,status);
   if (handle<0) {
      if (!_ini_is_valid(VSEWorkspace)) {
         _message_box(nls("Workspace '%s' is not recognized as valid and can't be converted",VSEWorkspace));
         return(1);
      }

      _ini_get_value(VSEWorkspace,'Global','Version',WorkspaceVersion);
      if (WorkspaceVersion!='' && WorkspaceVersion<8) {
         // Translate all the project files
         int temp_view_id;
         status=_ini_get_section(VSEWorkspace,"ProjectFiles",temp_view_id);
         if (!status) {
            int orig_view_id=p_window_id;
            p_window_id=temp_view_id;
            top();up();
            while (!down()) {
               get_line(line);
               if (line!='') {
                  _UpdateProjectFileActiveConfig(VSEWorkspace,_AbsoluteToWorkspace(line,VSEWorkspace));
               }
            }
            p_window_id=orig_view_id;
            _delete_temp_view(temp_view_id);
         }

      }
      if (WorkspaceVersion=='' || WorkspaceVersion<7) {
         int i;
         for (i=0;i<sectionsToMove._length();++i) {
            _str section_name=sectionsToMove[i];
            int temp_view_id=0;
            status=_ini_get_section(VSEWorkspace,section_name,temp_view_id);
            if (!status) {
               status=_ini_put_section(VSEWorkspaceStateFilename(VSEWorkspace),
                                       section_name,temp_view_id);
               if (status) {
                  return(status);
               }
               _ini_delete_section(VSEWorkspace,section_name);
            }
         }
         _str CurrentProject;
         _ini_get_value(VSEWorkspace,'CurrentProject','curproj',CurrentProject);
         _ini_delete_section(VSEWorkspace,'CurrentProject');
         // Change before release was finialized
         if (CurrentProject=='') {
            _ini_get_value(VSEWorkspaceStateFilename(VSEWorkspace),'CurrentProject','curproj',CurrentProject);
            _ini_delete_section(VSEWorkspaceStateFilename(VSEWorkspace),'CurrentProject');
         }
         _ini_set_value(VSEWorkspaceStateFilename(VSEWorkspace),'Global','CurrentProject',CurrentProject);
         _ini_set_value(VSEWorkspace,'Global','Version',WORKSPACE_FILE_VERSION);
      }

      status=_WorkspaceConvert70ToXML(VSEWorkspace);
      if (status) {
         return(status);
      }
      handle=_xmlcfg_open(VSEWorkspace,status);
      if (handle<0) {
         _message_box(nls("Workspace '%s' is not recognized as valid.  There must have been a problem converting the workspace to the new format",VSEWorkspace));
         return(status);
      }
   }

   // verify workspace vendor
   if (!strieq(_xmlcfg_get_path(handle,VPWX_WORKSPACE,"VendorName"),'SlickEdit')) {
      _message_box(nls("Workspace '%s' is not recognized as valid.  VendorName attribute not set to SlickEdit",VSEWorkspace));
      return(1);
   }

   // verify workspace version
   double xmlWorkspaceVersion;
   if (!WorkspaceIsCompatible(handle,xmlWorkspaceVersion)) {
      // make backup before changes are saved
      copy_file(WorkspaceFilename, _strip_filename(WorkspaceFilename, 'E') WORKSPACE_FILE_BACKUP_EXT);

      status=0;
      // see if it is a version that is upgradeable
      if (xmlWorkspaceVersion == 8.0) {
         status=_WorkspaceConvert80To81(WorkspaceFilename, handle);
         xmlWorkspaceVersion = (typeless)_xmlcfg_get_path(handle,VPWX_WORKSPACE,"Version");
      }

      if ((!status)&&(xmlWorkspaceVersion == VPW_FILE_VERSION81)) {
         status=_WorkspaceConvert81To90(WorkspaceFilename, handle);
         xmlWorkspaceVersion = (typeless)_xmlcfg_get_path(handle,VPWX_WORKSPACE,"Version");
      }

      if ((!status)&&(xmlWorkspaceVersion == VPW_FILE_VERSION90)) {
         status=_WorkspaceConvert90To91(WorkspaceFilename, handle);
         xmlWorkspaceVersion = (typeless)_xmlcfg_get_path(handle,VPWX_WORKSPACE,"Version");
      }

      if ((!status)&&(xmlWorkspaceVersion == VPW_FILE_VERSION91)) {
         status=_WorkspaceConvert91To100(WorkspaceFilename, handle);
         xmlWorkspaceVersion = (typeless)_xmlcfg_get_path(handle,VPWX_WORKSPACE,"Version");
      }

      // see if file is still not the proper version
      if ((status)||(xmlWorkspaceVersion != VPW_FILE_VERSION)) {
         _message_box(nls("Workspace '%s' is not recognized as valid.  Incorrect version",VSEWorkspace));
         return(1);
      }
   }

   if (gWorkspaceHandle>=0) {
      _xmlcfg_close(gWorkspaceHandle);
   }
   _ProjectCache_Update();
   _workspace_filename= WorkspaceFilename;
   gWorkspaceHandle=handle;
   _projectSetDependencyExtensions(def_add_to_prj_dep_ext);
   return(0);
}

/**
 * Build/Retag the tagfile for each workspace that is specified
 */
_command int build_workspace_tagfiles(_str arglist='') name_info(FILE_ARG'*,'VSARG2_EDITORCTL)
{
   // save original configuration settings
   orig_background_tagging_timeout                := def_background_tagging_timeout;
   orig_background_tagging_idle                   := def_background_tagging_idle;
   orig_background_tagging_threads                := def_background_tagging_threads;
   orig_background_reader_threads                 := def_background_reader_threads;
   orig_background_database_threads               := def_background_database_threads;
   orig_background_tagging_maximum_jobs           := def_background_tagging_maximum_jobs;
   orig_background_tagging_minimize_write_locking := def_background_tagging_minimize_write_locking;
   orig_autotag_flags2                            := def_autotag_flags2;
   orig_actapp                                    := def_actapp;

   // fine-tune settings for top performance
   def_background_tagging_timeout = 600000;     // 10 minutes
   def_background_tagging_idle = 25;            // 10 microsections
   def_background_tagging_threads = 8;          // pedal to the metal
   def_background_reader_threads = 2;           // two parallel readers
   def_background_database_threads = 1;         // dedicated database thread
   def_background_tagging_maximum_jobs = 5000;
   def_background_tagging_minimize_write_locking=false;

   // make sure that we don't automatically rebuild any workspaces
   def_actapp = 0;
   def_autotag_flags2 = 0;
   def_autotag_flags2 |= AUTOTAG_BUFFERS_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_FILES_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_LANGUAGE_NO_THREADS;
   def_autotag_flags2 |= AUTOTAG_SILENT_THREADS;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_OPEN;
   def_autotag_flags2 |= AUTOTAG_WORKSPACE_NO_ACTIVATE;

   // default tagging settings
   int status = 0;
   _str origWorkspaceList[] = null;
   boolean retagAll = false;
   boolean useThread = true;
   int refsAll = -1;

   // parse the options
   for (;;) {
      _str nextarg = parse_file(arglist);
      if (nextarg == "") break;

      if (first_char(nextarg) == '-') {
         // -retag - full retag
         if (strieq(nextarg, "-retag")) {
            retagAll = true;

         // -refs=[on/off] - tag with refereces
         } else if (strieq(nextarg, "-refs=on")) {
            refsAll = 1;
         } else if (strieq(nextarg, "-refs=off")) {
            refsAll = 0;

         // -thread=[on/off] - tag with threads
         } else if (strieq(nextarg, "-thread=on")) {
            useThread = true;
         } else if (strieq(nextarg, "-thread=off")) {
            useThread = false;

         // unsupported argument
         } else {
            _message_box("The argument '" nextarg "' is not supported.");
            return -1;
         }
      } else {

         // must be a workspace name
         switch (lowcase(_get_extension(nextarg, true))) {
         case WORKSPACE_FILE_EXT:
         case PRJ_FILE_EXT:
            break;
         case TAG_FILE_EXT:
            break;
         case VCPP_PROJECT_WORKSPACE_EXT:
         case TORNADO_WORKSPACE_EXT:
         case VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT:
         case XCODE_PROJECT_EXT:
         case XCODE_PROJECT_LONG_BUNDLE_EXT:
         case XCODE_PROJECT_SHORT_BUNDLE_EXT:
         case VISUAL_STUDIO_SOLUTION_EXT:
         case JBUILDER_PROJECT_EXT:
         case MACROMEDIA_FLASH_PROJECT_EXT:
         case XCODE_PROJECT_EXT:
            break;
         default:
            // unsupported filename
            _message_box("The file '" nextarg "' does not appear to be a SlickEdit workspace or tag file.");
            return -1;
         }

         // add it to the list of tag files to rebuild
         origWorkspaceList[origWorkspaceList._length()] = absolute(nextarg);
      }
   }

   // expand the workspace list (in case there are wildcards)
   // NOTE: there is nothing done here to prevent duplicates
   _str workspaceList[] = null;
   int i;
   for (i = 0; i < origWorkspaceList._length(); i++) {
      if (!iswildcard(origWorkspaceList[i]) || file_exists(origWorkspaceList[i])) {
         // not a wildcard so just add it
         workspaceList[workspaceList._length()] = origWorkspaceList[i];
         continue;
      }

      // is wildcard so expand it
      _str workspace = file_match(maybe_quote_filename(origWorkspaceList[i]), 1);
      for (;;) {
         if (workspace == "") break;

         switch (lowcase(_get_extension(workspace, true))) {
         case WORKSPACE_FILE_EXT:
         case PRJ_FILE_EXT:
            // add to list
            workspaceList[workspaceList._length()] = workspace;
            break;
         case TAG_FILE_EXT:
            // add to list
            workspaceList[workspaceList._length()] = workspace;
            break;
         case VCPP_PROJECT_WORKSPACE_EXT:
         case TORNADO_WORKSPACE_EXT:
         case VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT:
         case XCODE_PROJECT_EXT:
         case VISUAL_STUDIO_SOLUTION_EXT:
         case JBUILDER_PROJECT_EXT:
         case MACROMEDIA_FLASH_PROJECT_EXT:
         case XCODE_PROJECT_EXT:
            // add to list
            workspaceList[workspaceList._length()] = workspace;
            break;
         default:
            break;
         }

         // move next
         workspace = file_match(maybe_quote_filename(origWorkspaceList[i]), 0);
      }
   }

   // show the form
   _nocheck _control ctlLogTree;
   _nocheck _control ctlProgress;
   int wid = show("-xy -hidden _tag_progress_form");
   wid.p_caption = "Build Workspace Tag Files";
   wid.ctlLogTree.p_height = wid.ctlLogTree.p_height + 360;
   wid.ctlProgress.p_visible = false;
   wid.p_visible = true;


   // put the list of workspaces into the form
   for (i = 0; i < workspaceList._length(); i++) {
      nodeIndex := wid.ctlLogTree._TreeAddItem(TREE_ROOT_INDEX, workspaceList[i], TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      wid.ctlLogTree._TreeSetCheckable(nodeIndex, 1, 1);
      wid.ctlLogTree._TreeSetCheckState(nodeIndex, TCB_UNCHECKED);
   }
   //wid.ctlLogTree._TreeRefresh();
   wid.refresh("W");
   int node = wid.ctlLogTree._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   // tag each workspace
   for (i = 0; i < workspaceList._length(); i++) {
      wid.ctlLogTree._TreeSetCurIndex(node);
      wid.ctlLogTree._TreeSetCheckState(node, TCB_PARTIALLYCHECKED);
      wid.ctlLogTree._TreeRefresh();
      wid.ctlProgress.p_value = 0;

      // check if they just gave us a plain tag file
      workspace := workspaceList[i];
      isTagFile := (file_eq(_get_extension(workspace, true), TAG_FILE_EXT));
      tagfilename := _strip_filename(workspace, "E") :+ PRJ_TAG_FILE_EXT;
      boolean retag = retagAll;
      boolean refs = false;
      int flags = 0;

      // open the workspace (this will cause _MaybeRetagWorkspace to be run)
      if (!isTagFile) {
         status = workspace_open(workspace, "", "", true, false);
         if (status) break;
      }

      // see if the tag file flags match
      status = tag_read_db(tagfilename);
      if (status < 0 || tag_current_version() < VS_TAG_LATEST_VERSION) {
         // error or out of date so must retag
         retag = true;

         // set refs flag
         switch (refsAll) {
         case 0:
            // noop
            break;
         case 1:
            flags = flags | VS_DBFLAG_occurrences;
            break;
         }
      } else {
         // get the flags
         flags = tag_get_db_flags();
         refs = (flags & VS_DBFLAG_occurrences) != 0;

         // check for references if necessary
         if (refsAll != -1) {
            // if refs were not there but were requested to be on, rebuild is required
            if (!refs && refsAll == 1) {
               retag = true;
               refs = true;

               tag_open_db(tagfilename);
               flags = flags | VS_DBFLAG_occurrences;
               tag_set_db_flags(flags);

               // if refs were there but were requested to be off, disable them
            } else if (refs && refsAll == 0) {
               // TODO: this can be done quicker than rebuild
               retag = true;
               refs = false;

               tag_open_db(tagfilename);
               flags = flags & ~VS_DBFLAG_occurrences;
               tag_set_db_flags(flags);
            }
         }
      }

      // if we are building using threads, release the write lock
      if (useThread) {
         tag_close_db(tagfilename, true);
      }

      // retag the workspace if necessary
      wid.ctlProgress.p_value = 0;
      if (isTagFile) {
         status = RetagFilesInTagFile(tagfilename,
                                      retag,                   // rebuild from scratch
                                      (refsAll==1),            // tag occurrences
                                      true,                    // remove missing files
                                      true,                    // remove without prompting
                                      useThread,               // use threads
                                      true,                    // quiet
                                      true,                    // check all file dates
                                      !useThread,              // allow cancellation
                                      true                     // keep without prompting
                                      );
         if (status < 0) {
            _message_box("Error rebuilding tag file: "get_message(status, tagfilename));
         }
      } else {
         status = _workspace_update_files_retag(retag,         // rebuild from scratch
                                                true,          // remove obsolete files
                                                true,          // remove without prompting
                                                true,          // quiet
                                                (refsAll==1),  // tag occurrences
                                                true,          // check all file dates
                                                useThread,     // use threads
                                                !useThread,    // allow cancellation
                                                true           // keep without prompting
                                                );
         if (status < 0) {
            _message_box("Error retagging workspace: "get_message(status, tagfilename));
         }
      }

      cancelFormCaption := "Building ":+_strip_filename(tagfilename,"P");
      progressWid := show_cancel_form(cancelFormCaption, null, true, true);

      if (useThread) {
         // loop while we wait for the threaded tag file build to finish
         isJobRunning := false;
         progress := 0;
         do {
            delay(100);
            tag_check_async_tag_file_build(tagfilename, isJobRunning, progress);
            if (progressWid && _iswindow_valid(progressWid)) {
               cancel_form_progress(progressWid, 1, 100);
            }
         } while (isJobRunning);

         // finish building the tag file on a thread.
         _MaybeRetryTaggingWhenFinished(false, cancelFormCaption);
      }

      // close the tag file
      tag_close_db(tagfilename, false);

      // close the workspace
      if (!isTagFile) {
         status = workspace_close();
         if (status) break;
      }

      // check to see if cancel was pressed
      if(getCancelTagProgressFormGlobal()) {
         break;
      }

      // workspace complete so show the checkmark
      wid.ctlLogTree._TreeSetCheckState(node, TCB_CHECKED);
      wid.ctlLogTree._TreeRefresh();
      node = wid.ctlLogTree._TreeGetNextSiblingIndex(node);
   }

   //_message_box("finished");
   if (_iswindow_valid(wid)) {
      wid._delete_window();
   }

   // restore settings
   def_background_tagging_timeout                = orig_background_tagging_timeout;
   def_background_tagging_idle                   = orig_background_tagging_idle;
   def_background_tagging_threads                = orig_background_tagging_threads;
   def_background_reader_threads                 = orig_background_reader_threads;
   def_background_database_threads               = orig_background_database_threads;
   def_background_tagging_maximum_jobs           = orig_background_tagging_maximum_jobs;
   def_background_tagging_minimize_write_locking = orig_background_tagging_minimize_write_locking;
   def_autotag_flags2                            = orig_autotag_flags2;
   def_actapp                                    = orig_actapp;

   // that's all folks
   return status;
}

int _WorkspaceConvert80To81(_str WorkspaceFilename, int handle = -1)
{
   // changes from workspace version 8.0 to 8.1
   //    added doctype

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(WorkspaceFilename, status);
      if (handle < 0) {
         _message_box(nls("Unable to convert 8.0 workspace '%s1' to 8.1", WorkspaceFilename));
         return handle;
      }
   }

   // add the doctype
   int firstChildNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX);
   int doctypeNode = _xmlcfg_add(handle, firstChildNode, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", VPWTAG_WORKSPACE);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPW_DTD_PATH81);

   // put the new version
   _xmlcfg_set_path(handle, VPWX_WORKSPACE, "Version", 8.1);

   // save the converted file
   status = _WorkspaceSave(handle);

   // close the file if we opened it
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

int _WorkspaceConvert81To90(_str WorkspaceFilename, int handle = -1)
{
   // changes from workspace version 8.1 to 9.0
   //   version number only - changed to be consistent with project file

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(WorkspaceFilename, status);
      openedFile = true;
      if (handle < 0) {
         _message_box(nls("Unable to convert 8.1 workspace '%s1' to 9.0", WorkspaceFilename));
         return handle;
      }
   }

   // update the doctype
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPW_DTD_PATH90);

   // put the new version
   _xmlcfg_set_path(handle, VPWX_WORKSPACE, "Version", VPW_FILE_VERSION90);

   // save the converted file
   status = _WorkspaceSave(handle);

   // close the file if we opened it
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

int _WorkspaceConvert90To91(_str WorkspaceFilename, int handle = -1)
{
   // changes from workspace version 9.0 to 9.1
   //   update DTD
   //   insert forward compatiblity node

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(WorkspaceFilename, status);
      openedFile = true;
      if (handle < 0) {
         _message_box(nls("Unable to convert 9.0 workspace '%s1' to 9.1", WorkspaceFilename));
         return handle;
      }
   }

   // update the doctype
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPW_DTD_PATH91);

   // find the workspace node
   int workspaceNode = _xmlcfg_find_simple(handle, VPWX_WORKSPACE);

   if (workspaceNode >= 0) {
      // set the new version
      _xmlcfg_set_attribute(handle, workspaceNode, "Version", VPW_FILE_VERSION91);

      // insert forward compatibility node
      int versionsNode=_xmlcfg_add(handle, workspaceNode, "CompatibleVersions",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

      if (versionsNode >= 0) {
         int newNode=_xmlcfg_add(handle,versionsNode,"PrevVersion",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         if (newNode >= 0) {
            status=_xmlcfg_set_attribute(handle,newNode,"VersionNumber",VPW_FILE_VERSION90);
            if (status>=0) {
               // save the converted file
               status = _WorkspaceSave(handle);
            } else {
               _message_box(nls("Unable to convert 9.0 workspace '%s1' to 9.1", WorkspaceFilename));
            }
         } else {
            _message_box(nls("Unable to convert 9.0 workspace '%s1' to 9.1", WorkspaceFilename));
         }
      } else {
         _message_box(nls("Unable to convert 9.0 workspace '%s1' to 9.1", WorkspaceFilename));
      }
   } else {
      _message_box(nls("Unable to convert 9.0 workspace '%s1' to 9.1", WorkspaceFilename));
   }


   // close the file if we opened it
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

int _WorkspaceConvert91To100(_str WorkspaceFilename, int handle = -1)
{
   // changes from workspace version 9.1 to 10.0
   //   version number only - changed to be consistent with project file

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if (handle < 0) {
      handle = _xmlcfg_open(WorkspaceFilename, status);
      openedFile = true;
      if (handle < 0) {
         _message_box(nls("Unable to convert 9.1 workspace '%s1' to 10.0", WorkspaceFilename));
         return handle;
      }
   }

   // update the doctype
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPW_DTD_PATH100);

   // put the new version
   _xmlcfg_set_path(handle, VPWX_WORKSPACE, "Version", VPW_FILE_VERSION100);

   // insert forward compatibility node
   _xmlcfg_set_path2(handle, VPWX_COMPATIBLEVERSIONS, VPWTAG_PREVVERSION, "VersionNumber", VPW_FILE_VERSION91);

   // save the converted file
   status = _WorkspaceSave(handle);

   // close the file if we opened it
   if (openedFile) {
      _xmlcfg_close(handle);
   }

   // make sure all project files get converted
   //
   // NOTE: if all projects are not handled here, they will be handled
   //       as they are opened.  by doing them all here, this makes
   //       it easier for users who use version control to have everything
   //       get converted and checked in at the same time.
   _str projectFiles[] = null;
   _WorkspaceGet_ProjectFiles(handle, projectFiles);
   int i;
   for (i = 0; i < projectFiles._length(); i++) {
      // open each project
      _str projectName = projectFiles[i];
      if (projectName == "") continue;
      projectName = _AbsoluteToWorkspace(projectName, WorkspaceFilename);

      // open the project which will trigger conversion if necessary
      //
      // ignoring status here because if any of the projects fail
      // during the upgrade, the project converter will throw an error
      _ProjectHandle(projectName);

      // remove the project from the cache
      _ProjectCache_Update(projectName);
   }

   return status;
}

/**
 * Set current working directory to workspace directory.
 * 
 * @categories Project_Functions
 */
_command void workspace_cd() name_info(',')
{
   if (_workspace_filename != '') {
      _str cwd = _GetWorkspaceDir(_workspace_filename);
      if (cwd != '') {
         cd(cwd);
      }
   }
}

/**
 * Set current working directory to current project
 * working directory.
 * 
 * @categories Project_Functions
 */
_command void project_cd() name_info(',')
{
   if (_project_name != '') {
      _str cwd = _ProjectGet_WorkingDir(_ProjectHandle(_project_name));
      if (cwd != '') {
         cwd = absolute(cwd, _strip_filename(_project_name, 'n'));
         cd(cwd);
      }
   }
}

void _workspace_open_deprecated()
{
   call_list('_project_opened');
}

/**
 * Refresh workspace and projects files, workspace tag 
 * files, and tool windows.
 * 
 * @categories Project_Functions
 */
_command void workspace_refresh() name_info(',')
{
   _clearWorkspaceFileListCache();
   _WorkspaceCache_Update();
   _MaybeRetagWorkspace(false, false, false, true);
   toolbarUpdateWorkspaceList();
   call_list('_workspace_refresh_');
}

int _OnUpdate_workspace_refresh(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

_command int workspace_retag(boolean quiet = false) name_info(',')
{
   status := 0;
   rebuildAll := true;

   // check if the workspace tag file was built with references
   tagOccurrences := true;
   tagDatabase := _GetWorkspaceTagsFilename();
   if (tagDatabase != '') {
      dbHandle := tag_read_db(tagDatabase);
      if (dbHandle >= 0) {
         if (!(tag_get_db_flags() & VS_DBFLAG_occurrences)) {
            tagOccurrences = false;
         }
      }
   }

   // check if background tagging is enabled for the workspace tag file
   useThread := !quiet && _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);

   // prompt the user if they want to retag everything or only modified files
   if (!quiet) {
      status = _mdi.show('-modal _rebuild_tag_file_form', rebuildAll, tagOccurrences, false, true, true, useThread);
      if (status == '') return COMMAND_CANCELLED_RC;

      rebuildAll = (_param1 == 0);
      tagOccurrences = (_param3 != 0);
      useThread = useThread && (_param5 != 0);
   }

   // if the tag file rebuild fails, tell them why
   status = _workspace_update_files_retag(rebuildAll,              // rebuild tag file from scratch
                                          true,                    // remove missing files
                                          useThread||rebuildAll,   // remove files without prompting
                                          false,                   // quiet
                                          tagOccurrences,          // tag references
                                          !rebuildAll,             // check all file dates
                                          useThread,               // use threaded background tagging
                                          false,                   // allow cancellation
                                          useThread||quiet);       // keep deleted files without prompting
   if (status < 0) {
      _message_box("Error retagging workspace: "get_message(status, tagDatabase));
   }

   return 0;
}

int _OnUpdate_workspace_retag(CMDUI &cmdui,int target_wid,_str command)
{
   if (_workspace_filename=='') {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}
