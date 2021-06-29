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
#include "scc.sh"
#include "diff.sh"
#require "se/vc/VersionControlSettings.e"
#import "se/ui/toolwindow.e"
#import "adaptiveformatting.e"
#import "complete.e"
#import "compile.e"
#import "cua.e"
#import "cvs.e"
#import "cvsutil.e"
#import "debug.e"
#import "dirlist.e"
#import "drvlist.e"
#import "fileman.e"
#import "files.e"
#import "frmopen.e"
#import "guiopen.e"
#import "help.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "menu.e"
#import "mercurial.e"
#import "mouse.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "put.e"
#import "recmacro.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "svcautodetect.e"
#import "subversion.e"
#import "tagform.e"
#import "tagrefs.e"
#import "tags.e"
#import "treeview.e"
#import "vc.e"
#import "window.e"
#import "wkspace.e"
#endregion

using se.vc.VersionControlSettings;
using namespace se.vc;
using namespace se.ui;

/*
   8/5/1996:  Extension changed on temp files.  Needed for demo.
*/

_str _vcdebug=0;
static _str creating;  // Just a flag for to avoid a couple of on_change events
static _str _last_inwildcards;
static _str _last_outwildcards;

static const MENU_CAPTION_CHECKIN= "Check &In";
static const MENU_CAPTION_COMMIT=  "Comm&it";

static const PERFORCE_NAME= "Perforce SCM";

int def_vcflags;
//Keep the command lists loaded here...
//1:43pm 1/4/2000
//This is global so that OEM users can check these values from
//c code.
int gvcEnableList:[];

static bool IsHarvestSCC(_str system=_GetVCSystemName())
{
   return(system=='SCC:PLATINUM technology, inc. CCC/Harvest');
}

static bool IsPVCSSCC(_str system=_GetVCSystemName())
{
   return(system=='SCC:PVCS Version Manager');
}

// These are copied from scc.h
static const SCC_I_FILEDIFFERS=       6;
static const SCC_I_RELOADFILE=        5;
static const SCC_I_FILENOTAFFECTED=   4;
static const SCC_I_PROJECTCREATED=    3;
static const SCC_I_OPERATIONCANCELED= 2;
static const SCC_I_ADV_SUPPORT=       1;
static const SCC_OK=                  0;


static void _vcquit_error_file()
{
   quit_error_file(_vcerror_file());
}
static _str _vcerror_file()
{
   //2:59pm 9/4/1997
   //Don't want to use Config dir on Source Safe
   tmp := get_env('TMP');
   if (tmp=='') {
      tmp=get_env('TEMP');
   }
   if (tmp=='') tmp=_ConfigPath();
   _maybe_append_filesep(tmp);
   return(tmp:+VC_ERROR_FILENAME);
}
static _str _vcerror_file2()
{
   //2:59pm 9/4/1997
   //Don't want to use Config dir on Source Safe
   tmp := get_env('TMP');
   if (tmp=='') {
      tmp=get_env('TEMP');
   }
   if (tmp=='') tmp=_ConfigPath();
   _maybe_append_filesep(tmp);
   return(tmp:+VC_ERROR_FILENAME2);
}

void _prjclose_vc(bool singleFileProject)
{
   if (singleFileProject) return;
   if (machine()=='WINDOWS' && _SCCProjectIsOpen() && _haveVersionControl()) {
      _SccCloseProject();
      _SccUninit();
   }
}


static void GetVCSAndProjectName(_str vcsproject,_str &vcs,_str &projectname,
                                 bool &isscc)
{
   isscc=false;
   if (upcase(substr(vcsproject,1,4))=='SCC:') {
      isscc=true;
      vcsproject=substr(vcsproject,5);
   }
   p := pos(':',vcsproject);
   vcs=projectname='';
   if (p) {
      vcs=substr(vcsproject,1,p-1);
      projectname=substr(vcsproject,p+1);
   }
}

int _SetVCSItemInWorkspaceState(_str workspaceFilename,_str projectFilename,_str fieldName,_str value)
{
   _str workspace_state_filename = VSEWorkspaceStateFilename(workspaceFilename);
   _str relative_project_name = _RelativeToWorkspace(projectFilename);
   int status=_ini_set_value(workspace_state_filename, "Version Control", fieldName:+".":+relative_project_name,value);
   return status;
}

int _GetVCSItemInWorkspaceState(_str workspaceFilename,_str projectFilename,_str fieldName,_str &value)
{
   _str workspace_state_filename = VSEWorkspaceStateFilename(workspaceFilename);
   _str relative_project_name = _RelativeToWorkspace(projectFilename);
   int status=_ini_get_value(workspace_state_filename, "Version Control", fieldName:+".":+relative_project_name,value);
   return status;
}

static int SetVCSLocalPath(int projectHandle,_str systemName,_str VCSLocalPath)
{
   if ( _isscc(systemName) ) {
      systemName = substr(systemName,SCC_PREFIX_LENGTH+1);
   }
   status := 0;
   if ( systemName==PERFORCE_NAME ) {
      status = _SetVCSItemInWorkspaceState(_workspace_filename,_ProjectGet_Filename(projectHandle),"VCSLocalPath",VCSLocalPath);
   }else{
      _ProjectSet_VCSLocalPath(_ProjectHandle(),VCSLocalPath);
   }
   return status;
}

static int SetVCSAuxPath(int projectHandle,_str systemName,_str VCSAuxPath)
{
   if ( _isscc(systemName) ) {
      systemName = substr(systemName,SCC_PREFIX_LENGTH+1);
   }
   status := 0;
   if ( systemName==PERFORCE_NAME ) {
      status = _SetVCSItemInWorkspaceState(_workspace_filename,_ProjectGet_Filename(projectHandle),"VCSAuxPath",VCSAuxPath);
   }else{
      _ProjectSet_VCSAuxPath(_ProjectHandle(),VCSAuxPath);
   }
   return status;
}

static _str GetVCSLocalPath(int projectHandle,_str systemName)
{
   VCSLocalPath := "";
   if ( systemName==PERFORCE_NAME ) {
      int status=_GetVCSItemInWorkspaceState(_workspace_filename,_ProjectGet_Filename(projectHandle),"VCSLocalPath",VCSLocalPath);
   }else{
      VCSLocalPath=_ProjectGet_VCSLocalPath(_ProjectHandle());
   }
   return VCSLocalPath;
}

static _str GetVCSAuxPath(int projectHandle,_str systemName)
{
   VCSAuxPath := "";
   if ( systemName==PERFORCE_NAME ) {
      _GetVCSItemInWorkspaceState(_workspace_filename,_ProjectGet_Filename(projectHandle),"VCSAuxPath",VCSAuxPath);
   }else{
      VCSAuxPath=_ProjectGet_VCSAuxPath(_ProjectHandle());
   }
   return VCSAuxPath;
}

/**
 * Gets VCSProject info from workspace file.  Returns "" if 
 * there is none 
 * 
 * @author dhenry (4/4/2011)
 * 
 * @param handle 
 * 
 * @return _str VCSProject info from workspace file.  Returns "" 
 * if there is none 
 */
_str _WorkspaceGet_VCSProject(int handle)
{
   if ( handle<0 ) return "";
   return(_xmlcfg_get_path(handle,VPWX_WORKSPACE,"VCSProject"));
}

int _WorkspaceSet_VCSProject(int handle,_str VCS)
{
   if ( VCS=="" ) {
      status := _xmlcfg_set_path(handle,VPWX_WORKSPACE,"VCSProject","");
      return 0;
   }
   status := _xmlcfg_set_path(handle,VPWX_WORKSPACE,"VCSProject",VCS':');
   return status;
}

/**
 * If version control is configured in the workspace fiel, go 
 * ahead and set if up from there 
 * 
 * @param handledInWkspace set to true if version control is 
 *                         setup in the workspace file
 * 
 * @return int 0 if successful
 */
static int maybeGetVCFromWorkspace(bool &handledInWkspace,_str &vcs="" ,bool getAutoDetectedSystem=true)
{
   handledInWkspace = false;

   // 7/15/20
   // Can't do this because we do not want to show an auto detected
   // VCS as the system for a workspace 
   if ( getAutoDetectedSystem ) {
      vcs = svc_get_vc_system();
   }
   vcsproject := "";
   if ( gWorkspaceHandle >=0 ) {
      vcsproject=_WorkspaceGet_VCSProject(gWorkspaceHandle);
      if ( vcsproject=="" ) {
         handledInWkspace = false;
         return 0;
      }
      handledInWkspace = true;
   }
   status := 0;
   projectname := "";
   isscc := false;
   GetVCSAndProjectName(vcsproject,vcs,projectname,isscc);

   if (isscc) {
      vcs='SCC:'vcs;
   } else return(0);

   if (isscc) {
      vcslocalpath := "";
      vcsauxpath := "";
      
      if (machine()=='WINDOWS' && _haveVersionControl() && _SCCProjectIsOpen() &&
          projectname!=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)) {
         vcs=substr(svc_get_vc_system(),5);
         vcslocalpath=GetVCSLocalPath(_ProjectHandle(),vcs);
         vcsauxpath=GetVCSAuxPath(_ProjectHandle(),vcs);
      }
      //Order is important here...
      //vcsproject=substr(vcsproject,SCC_PREFIX_LENGTH+1);
      vcslocalpath=substr(vcslocalpath,SCC_PREFIX_LENGTH+1);

      localpathvcs := "";
      vcslocalpath=MaybeStripLeadingVCSName(vcslocalpath,localpathvcs);
      if (localpathvcs==vcs) {
         status=vcSetupOnOpen(vcs,projectname,vcslocalpath,vcsauxpath);
         if ( status
              && status!=VSSCC_E_PROJECTALREADYOPEN_RC
              && status!=VSSCC_ERROR_MAY_BE_32_BIT_DLL_RC ) {
            if ( status==VSSCC_E_INITIALIZEFAILED_RC ) {
               _message_box(nls("Could not initialize %s",vcs));
               _WorkspacePutProjectDate();
            }else if ( status && status!=VSSCC_E_PROJECTALREADYOPEN_RC ) {
               _message_box(nls("Could not open %s project %s",vcs,/*vcsproject*/projectname));
               _WorkspacePutProjectDate();
               _SccCloseProject();
            }
            _ProjectSet_VCSProject(_ProjectHandle(),'');
            SetVCSLocalPath(_ProjectHandle(),"","");
            _ProjectSave(_ProjectHandle());
            status = 0; // Don't want to stop auto restore
         }
      }
   }

   return status;
}

void _prjopen_vc(bool singleFileProject=false)
{
   if (singleFileProject) return;
   if (!_haveVersionControl()) {
      return;
   }

   handledInWkspace := false;
   status := maybeGetVCFromWorkspace(handledInWkspace);
   if ( handledInWkspace && !status ) {
      // 4/4/2011
      // If version control is set in the workspace, return and use that. Right 
      // now this can only be done manually
      return;
   }

   _str vcs=svc_get_vc_path();
   _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   projectname := "";
   isscc := false;
   GetVCSAndProjectName(vcsproject,vcs,projectname,isscc);

   if ( !isscc ) return;

   vcs='SCC:'vcs;
   _SetVCSystemName(vcs,false);

   status=0;
   vcslocalpath := "";
   vcsauxpath := "";
   
   
   if (machine()=='WINDOWS' && _isscc(vcs) &&
       projectname!=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)) {
      vcs=substr(vcs,5);
      vcslocalpath=GetVCSLocalPath(_ProjectHandle(),vcs);
      vcsauxpath=GetVCSAuxPath(_ProjectHandle(),vcs);
   }
   //Order is important here...
   //vcsproject=substr(vcsproject,SCC_PREFIX_LENGTH+1);
   vcslocalpath=substr(vcslocalpath,SCC_PREFIX_LENGTH+1);

   localpathvcs := "";
   vcslocalpath=MaybeStripLeadingVCSName(vcslocalpath,localpathvcs);
   if (localpathvcs==vcs) {
      status=vcSetupOnOpen(vcs,projectname,vcslocalpath,vcsauxpath);
      if ( status
           && status!=VSSCC_E_PROJECTALREADYOPEN_RC
           && status!=VSSCC_ERROR_MAY_BE_32_BIT_DLL_RC ) {
         if ( status==VSSCC_E_INITIALIZEFAILED_RC ) {
            _message_box(nls("Could not initialize %s",vcs));
            _WorkspacePutProjectDate();
         }else if ( status && status!=VSSCC_E_PROJECTALREADYOPEN_RC ) {
            _message_box(nls("Could not open %s project %s",vcs,/*vcsproject*/projectname));
            _WorkspacePutProjectDate();
            _SccCloseProject();
         }
         _ProjectSet_VCSProject(_ProjectHandle(),'');
         SetVCSLocalPath(_ProjectHandle(),"","");
         _ProjectSave(_ProjectHandle());
         status = 0; // Don't want to stop auto restore
      }
   }
}

static int vcSetupOnOpen(_str vcs,_str projectname,_str vcslocalpath,_str vcsauxpath)
{
   if (!_haveVersionControl()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (machine()=='WINDOWS' &&
       projectname!=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)) {
      //If _srg_project opened this already, skip it
      if (vcs!=_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)) {
         int status=_SccInit(vcs);
         if (status) {
            return(status);
         }
      }
   
      //use project and local_path because they are the stripped versions(no SCC:)
      int status=_SccOpenProject(false,'',projectname,vcslocalpath,vcsauxpath);
      if (status) {
         return status;
      }
   }else{
      detectedSystem :=svc_get_vc_system();
      if (!_isscc(detectedSystem) &&!CommandLineVCSExists(vcs) && detectedSystem!='') {
         _SetVCSystemName('');
         _ProjectSet_VCSProject(_ProjectHandle(),'');
         _ProjectSave(_ProjectHandle());
         _WorkspacePutProjectDate();
         return(1);
      }
      project_option := "";
      info := "";
      parse projectname/*vcsproject*/ with project_option ',' info;
      if (lowcase(project_option)=='command') {
         _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
         if (vcsproject=='') {
            // This case naturally happens when a new project is created.
            return(1);
         }
         styles := "";
         comment := "";
         vcsProjectStyle := VersionControlSettings.getVCSProjectStyle(vcs);
         _str command=_vcparse_command(vcs, info, '', _project_name, vcsproject, comment,'',vcsProjectStyle);
         if (command == "") {
            return(COMMAND_CANCELLED_RC); // user cancelled
         }
         int status=shell(command,'p');
         if (status) {
            _message_box(nls("Failed to set VCS Project by executing the command:\n\n%s",command));
            return(status);
         }
      }
   }
   vcGetList(gvcEnableList);
   return(0);
}

static int CheckForWorkspaceVCInfo(_str WorkspaceFilename,_str &VCSProject,_str &VCSLocalPath,_str &VCSAuxPath)
{
   status := 0;
   _str workspace_state_filename = VSEWorkspaceStateFilename(WorkspaceFilename);
   _str relative_project_name = _RelativeToWorkspace(_project_name);
   do {
      status=_ini_get_value(workspace_state_filename, "Version Control", "VCSLocalPath.":+relative_project_name, VCSLocalPath);
      if ( status ) break;

      status=_ini_get_value(workspace_state_filename, "Version Control", "VCSAuxPath.":+relative_project_name, VCSAuxPath);
      if ( status ) break;
   } while (false);
   return status;
}

/**
 * Check to see if VCSName exists in the system or user
 * vc file
 *
 * @param VCSName VCS to look for
 *
 * @return true if VCSName can be found, false otherwise
 */
static bool CommandLineVCSExists(_str VCSName)
{
   return VersionControlSettings.isValidProviderName(VCSName);
}

static int CommandLineVCSExists2(_str VCSFilename,_str VCSName)
{
   //Open the specified vc file
   temp_view_id := 0;
   orig_view_id := 0;
   int status=_open_temp_view(VCSFilename,temp_view_id,orig_view_id);
   if (status) {
      //If we could not open the file, the system does not exist here
      return(status);
   }
   //File opened ok, now look for the VCS we want to find
   top();
   status=_ini_find_section(VCSName);
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   //If there is no status here, we must have opened the file, and found that
   //VCS
   return(status);
}

static _vccomment_file()
{
   //2:59pm 9/4/1997
   //Don't want to use Config dir on Source Safe
   tmp := get_env('TMP');
   if (tmp=='') {
      tmp=get_env('TEMP');
   }
   if (tmp=='') tmp=_ConfigPath();
   _maybe_append_filesep(tmp);
   return(tmp:+VC_COMMENT_FILENAME);
}

/*
    p_user variables used

    _project_files.p_user       Used to make sure that file list is not filled
                                in more than once.
    _openfn.p_user           Last filespec wildcard(s) used to fill in file
                             list box.

    _ok.p_user               Current directory when dialog box was displayed.

*/
defeventtab _vc_form;

_openfile_types.on_destroy()
{
   // This can happen if destroy the window becuase user wants to edit
   // the dialog
   checking_in := lowcase(p_active_form.p_caption) == 'check in';
   wildcards := "";
   parse _openfile_types.p_text with '('wildcards')' ;
   if (checking_in) {
      _last_inwildcards=wildcards;
   } else {
      _last_outwildcards=wildcards;
   }
}
void _openfile_types.on_drop_down(int reason)
{
   switch (reason) {
   case DROP_UP:
      files := "";
      parse _lbget_seltext() with '('files')' ;
      if (files!='') {
         _vcopen_set_wildcards(files);
         fill_in_sf_listbox();
         _openfn.p_text=files;
         _openfn._set_sel(1);
      }
   }
}
void _vc_form.'F1'()
{
   name := "";
   checking_in := lowcase(p_active_form.p_caption) == 'check in';
   if (checking_in) {
      name='Check In dialog box';
   } else {
      name='Check Out dialog box';
   }
   help(name);
}
_invert.lbutton_up()
{
   _openfile_list._lbinvert();
   _openfile_list.call_event(CHANGE_SELECTED,_openfile_list,ON_CHANGE,'');
}
_prompt_for_each.lbutton_up()
{
   _discard_changes.p_value=0;
}
_discard_changes.lbutton_up()
{
   _new_archive.p_value=0;
   _prompt_for_each.p_value=0;
}
_new_archive.lbutton_up()
{
   _discard_changes.p_value=0;
}

static put_files_in_box(var filelist_id)
{
   orig_view := p_window_id;
   p_window_id = filelist_id;
   top();up();
   for (;;) {
      down();
      if (rc) {
         break;
      }
      get_line(auto line);
      src_filespec := "";
      parse line with 'srcfiles' '=' src_filespec;
      if (src_filespec != '' && iswildcard(src_filespec)) {
         orig_view._openfile_list.insert_file_list('-v +p ':+src_filespec);
      }else if(src_filespec != ''){
         orig_view._openfile_list._lbadd_item(src_filespec);
      }
   }
   _delete_temp_view(filelist_id);
   p_window_id = orig_view;
   _openfile_list._lbsort(_fpos_case' -f');
   _openfile_list._lbremove_duplicates();
   _openfile_list.top();
}
void _checkinout.lbutton_up()
{
   _ok.call_event(1,_ok,LBUTTON_UP,'');
}
void _ok.lbutton_up(typeless open_wildcards="")
{

   checking_in := lowcase(p_active_form.p_caption) == 'check in';
   typeless result=_vcopen_get_result(open_wildcards);
   if (result=='') return;
   options := "";
   if (_edit.p_value) {
      options :+= ' +e';
   } else if(!checking_in){
      options :+= ' -e';
   }
   if (_read_only.p_value) {
      options :+= ' +r';
   }
   if (_prompt_for_each.p_value) {
      options :+= ' +p';
   }
   if (_discard_changes.p_value) {
      options :+= ' +d';
   }
   if (_new_archive.p_value) {
      options :+= ' +new';
   }

   p_active_form._delete_window(options' 'result);
}
static void _vcopen_set_wildcards(_str wildcards)
{
   if (_project_files.p_value) return;
   _openfn.p_user=wildcards;
}
static _str _vcopen_get_wildcards()
{
   if (_project_files.p_value) return('');
   _str wildcards=_openfn.p_user;
   if (wildcards=='') {
      wildcards=ALLFILES_RE;
   }
   return(wildcards);
}

static _str _vcopen_get_result(typeless open_wildcards="")
{
   open_wildcards=open_wildcards!='';
   //parse _openfn.p_user with flags default_ext name_part . ;
   name_part := "";

   checking_in := lowcase(p_active_form.p_caption) == 'check in';
   int flags=OFN_ALLOWMULTISELECT;
   if (checking_in) {
      flags|=OFN_FILEMUSTEXIST;
   }
   default_ext := '.';
   hit_dir := false;
   hit_wildcard := false;
   hit_normal := false;
   rest := _openfn.p_text;
   hit_semi := -1;
   wildcards := "";
   path := "";
   typeless result='';
   typeless bresult='';  // result not in abolute form for retrieval
   _str cwd=_opendir_list._dlpath();
   _str vcs=svc_get_vc_system();
   _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   vcsproject=MaybeStripLeadingVCSName(vcsproject);
   if (vcs=='') {
      return(1);
   }

   typeless file_exists=0;
   typeless status=0;
   bfilename := "";
   filenames := "";
   filename := "";
   text := "";
   new_path := "";

   vcsProjectStyle := VersionControlSettings.getVCSProjectStyle(vcs);
   for (;;) {
      parse rest with filenames ';' rest;
      if (filenames=='') break;
      ++hit_semi;
      for (;;){
         if ((flags & OFN_SAVEAS) || !(flags & OFN_ALLOWMULTISELECT)) {
            bfilename=_maybe_quote_filename(filenames);
            filenames='';
         } else {
            bfilename=parse_file(filenames);
         }
         if (bfilename=='') break;
         filename=_absolute2(bfilename,cwd);
         // Check if this is a directory specification.
         if (isdirectory(filename)) {
            hit_dir=true;
            path=filename;
            name_part='';
         } else {
            if (default_ext!='.' && filename==_strip_filename(filename,'e')) {
               filename=_maybe_quote_filename(strip(filename,'B','"')'.'default_ext);
            }
            result :+= ' 'filename;
            if (bresult=='') {
               bresult=bfilename;
            } else {
               bresult :+= ' 'bfilename;
            }
            filename=strip(filename,'B','"');

            if (vcsProjectStyle == VCS_PROJ_SS_TREE && _ssxlat_dir(filename,vcs,vcsProjectStyle)=='') {
               status=1;
               _message_box(nls('The file %s is not in or below the current project',filename),
                            p_active_form.p_caption
                         );
               text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_set_focus();
               return('');
            }

            new_path=_strip_filename(filename,'N');
            name_part=_strip_filename(filename,'P');
            // Check if path exists
            if (new_path!=''){
               path=new_path;
               if(!isdirectory(new_path)) {
                  _message_box(new_path"\n"nls("Path does not exist.")"\n":+
                               nls("Please verify that the correct path was given."),
                               p_active_form.p_caption
                            );
                  text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_set_focus();
                  return('');
               }
            }
         }
         if (!open_wildcards && iswildcard(name_part)) {
            wildcards :+= ' 'name_part;
            hit_wildcard=true;
         } else if(name_part!=''){
            ++hit_normal;
         }
         if ((hit_normal && (hit_wildcard || hit_dir || hit_semi)) ||
             (hit_normal>1 && !(flags & OFN_ALLOWMULTISELECT))) {
            _message_box(result"\n"nls("The above file name is invalid."),
                         p_active_form.p_caption
                         );

            text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_set_focus();
            return('');
         }
      }
   }

   needVCSProject := VersionControlSettings.getVCSProjectRequired(vcs) && 
      vcsproject=='' && vcsProjectStyle != VCS_PROJ_SS_LOCATE_FILE;

   if (hit_normal) {
      if ((flags & OFN_FILEMUSTEXIST)||
           ((flags & OFN_SAVEAS) && !(flags & OFN_NOOVERWRITEPROMPT)) ) {
         rest=result;
         for (;;) {
            filename=parse_file(rest);
            if (filename=='') break;
            file_exists=file_match('-p 'filename,1)!='';
            if (flags & OFN_FILEMUSTEXIST) {
               if(!file_exists) {
                  _message_box(filename"\n"nls("File not found.")"\n":+
                            nls("Please verify that the correct file name was given."),
                               p_active_form.p_caption
                              );
                  p_window_id=_openfn;
                  text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_set_focus();
                  return('');
               }
            }
            if (flags & OFN_SAVEAS) {
               if (file_exists) {
                  status=_message_box(nls("%s already exists.",filename)"\n\n":+
                            nls("Replace existing file?"),
                            p_active_form.p_caption,
                            MB_YESNO|MB_ICONQUESTION,IDNO
                            );
                  if (status==IDNO) {
                     p_window_id=_openfn;
                     text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_set_focus();
                     return('');
                  }
               }
            }
         }
      }
      result=strip(result);
      if (result=='') {
         return('');
      }

      if (needVCSProject) {
          _message_box("The VCS Project must be set.  Use Version Control Setup Dialog.");
          return('');
      }
      //if (!(flags & OFN_SAVEAS)) {
      //   _append_retrieve(_openfn,bresult,_openfn.p_cb_picture.p_user)
      //}
      return(result);
   }
   wildcards=strip(wildcards);
   if (!hit_wildcard && !hit_dir && (flags & OFN_ALLOWMULTISELECT)){
       if (needVCSProject) {
          _message_box("The VCS Project must be set.  Use Version Control Setup Dialog.");
           return('');
       }
       /* Nothing selected? */
       result=_openfile_list._lbmulti_select_result(1);
       if (result=='') {
          return('');
       }
       return(strip(result));
   }
   if (!hit_normal && !hit_wildcard && !hit_dir) return('');
   if (wildcards=='') {
      wildcards=_vcopen_get_wildcards();
   }
   // Convert *.c *.h to *.c;*.h
   wildcard := "";
   rest=wildcards;
   wildcards='';
   for (;;) {
      wildcard=parse_file(rest);
      if (wildcard=='') break;
      if (wildcards!='') {
         wildcards :+= ';'wildcard;
      } else {
         wildcards=wildcard;
      }
   }
   if (path!='') {
      _vcopen_set_wildcards(wildcards);
      p_window_id=_openfn;
      if (_isWindows()) {
         fill_in_sf_listbox();
         //_openfile_list._flfilename(wildcards,path,1)
         if (substr(path,1,2)=='\\') {
            _opendir_list._dlpath(path);
            server := sharep := "";
            parse path with '\\'  server '\' sharep'\' rest;
            unc_name := '\\'server'\'sharep;
            _opendrives._dvldrive(unc_name);
         } else {
            _opendir_list._dlpath(path);
            _opendrives._dvldrive('');
         }
      } else {
         //chdir path,1
         fill_in_sf_listbox();
         _opendir_list._dlpath('');
         //_opendrives._dvldrive('')
      }
      _set_sel(1,length(p_text)+1);
   } else {
      _vcopen_set_wildcards(wildcards);
      fill_in_sf_listbox();
      //_openfile_list._flfilename(wildcards)
   }
   return('');
}
static init_vc_form_project(typeless use_ini_vcs)
{
   if (_project_name=='') {
      _project_files.p_enabled=false;
      if (_project_files.p_value) {
         ++creating;
         _use_filespec.p_value=1;
         --creating;
      }
   } else {
      _project_files.p_enabled=true;
   }
   _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   vcsproject=MaybeStripLeadingVCSName(vcsproject);
   _str vcs=svc_get_vc_system();
   if (vcs=='') {
      return(1);
   }

   _str filetypes=_openfile_types.p_user;
   _str wildcards=_openfn.p_user;

   _str old_line=_openfile_types._lbget_text();
   if (old_line!='') {
      parse old_line with '(' wildcards ')';
   }

   _openfile_types._lbclear();
   // add to _openfile_types
   orig_wid := p_window_id;
   p_window_id=_openfile_types;
   if (wildcards=='') {
      parse filetypes with '('wildcards')';
      if (wildcards=='') {
         wildcards=ALLFILES_RE;
      }
   }
   for (;;) {
      _str line=_parse_line(filetypes,',');
      if (line=='') break;
      if (pos('(*.e;',line)) {
         line=stranslate(line,'(*'_macro_ext';','(*.e;');
      }
      _lbadd_item(line);
   }

   archive_filespec := VersionControlSettings.getArchiveFileSpec(vcs);
   if (archive_filespec!='' && VersionControlSettings.getUsePVCSWildcards(vcs)) {
      _lbadd_item('Archive Files ('archive_filespec')');
   }
   top();
   status := search(LB_RE:+'?*\(':+_escape_re_chars(wildcards)'\)','rhi@');
   if (status) {
       parse _lbget_text() with '(' wildcards ')';
   }
   _openfile_types.p_text=_lbget_text();

}

_ok.on_destroy()
{

   _str cwd=_ok.p_user;
   if (!_openchange_dir.p_value && cwd!=getcwd()) {
      /* Restore original directory. */
      chdir(cwd,1);
      call_list('_cd_');
   }
}

_ok.on_create()
{
   if (_isUnix()) {
      _opendriveslab.p_visible = false;
      _opendrives.p_visible = false;
   }
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS)) {
      _open_project.p_visible=false;
      _edit_project.p_visible=false;
   }
   _str caption=arg(1);
   _str init_filename=arg(2);
   _str wildcards=arg(3);
   _str filetypes=arg(4);
   if (filetypes=='') filetypes=def_file_types;
   _openfile_types.p_user=filetypes;
   _openfn.p_user=wildcards;

   creating=1;
   _ok.p_user=getcwd();
   if (def_change_dir) _openchange_dir.p_value=1;


   init_vc_form_project(1);


   _opendir_list.p_user = _opendir_list._dlpath(_dvldrive() );
   _opendir_list._dlpath(_dvldrive());

   checking_in := lowcase(caption) == 'check in';
   if (checking_in) {
      _checkinout.p_caption=MENU_CAPTION_CHECKIN;
      _discard_changes.p_visible = true;
      _edit.p_visible = false;
      _edit.p_value=0;
      _new_archive.p_visible = true;
      _prompt_for_each.p_visible = true;
      _read_only.p_visible = false;
   }else{
      _discard_changes.p_visible = false;
      _edit.p_visible = true;
      _new_archive.p_visible = false;
      _prompt_for_each.p_visible = false;
      _read_only.p_visible = true;
   }
   p_active_form.p_caption = caption;
   //vcs=_vc_system.p_text;
   _openfn.p_text=(init_filename=='')?wildcards: init_filename;
   _use_filespec.p_value=1;
   creating=0;
   p_active_form.fill_in_sf_listbox();
}

#if 0
void _vc_system.on_change()
{
   if (creating) return;
   init_vc_form_project(0);
}

#endif
void _use_filespec.lbutton_up()
{
   if (creating) return;
   _openfn.p_text=_vcopen_get_wildcards();
   allow_chdir(1);
   fill_in_sf_listbox();
}

_project_files.lbutton_up()
{
   fill_in_sf_listbox();
   allow_chdir(0);
}

static allow_chdir(typeless value)
{
   _openfile_typeslab.p_enabled=_openfile_types.p_enabled=
           _sddir_listlab.p_enabled=_opendir_list.p_enabled=
            _openfn.p_enabled=_fslabel.p_enabled=value;
   if (_NAME_HAS_DRIVE) {
      _opendriveslab.p_enabled=_opendrives.p_enabled=value;
   }
}

_openfn.on_change(int reason)
{
   if (creating) {
      return('');
   }
   int list=_control _openfile_list;
   if (list.p_Nofselected) {
      list._lbdeselect_all();
      _opennofselected.p_caption=list.p_Nofselected' of 'list.p_Noflines' selected';
   }
}

static void fill_in_sf_listbox()
{
   if (creating) return;
   option := "";
   if (_project_files.p_value) {
      option='p';
   } else {
      option='f';
   }
   typeless status=0;
   filename := "";
   _str path=_opendir_list._dlpath();
   _str wildcards=_vcopen_get_wildcards();
   new_list := option:+path:+wildcards;
   if (new_list:==_project_files.p_user) return;
   _project_files.p_user=new_list;
   wid := p_window_id;
   _openfile_list._lbclear();
   if (!_project_files.p_value) {
      for (;;) {
         parse wildcards with filename ' |;','r' wildcards;
         if (filename=='') break;
         _openfile_list.insert_file_list('-v -p '_maybe_quote_filename(path:+filename));
      }
   }else{
      view_id := 0;
      get_window_id(view_id);
      //11:45am 8/18/1997
      //Dan changed for makefile support
      //status=_ini_get_section(_project_get_filename(), "FILES", temp_view_id);
      int temp_view_id=wid._openfile_list;
      status=GetProjectFiles(_project_get_filename(), temp_view_id, "", null, "", false, true, true);
      if (status) {
         return;
      }
   }
   p_window_id=wid;
   _openfile_list._lbsort('-f');
   _openfile_list._lbtop();
   if (_openfile_list._lbget_text()=='') {
      _openfile_list._lbdelete_item();
      _openfile_list._lbtop();
   }
   _opennofselected.p_caption = '0 of '_openfile_list.p_Noflines' selected';
}

_open_project.lbutton_up()
{
   wid := p_window_id;
   _str old_project_name=_project_name;
   project_open();
   // IF project changed AND project form not editted by dialog editor.
   if (old_project_name!=_project_name && _iswindow_valid(wid)) {
      p_window_id=wid;
      init_vc_form_project(1);
      fill_in_sf_listbox();
   }
}

_edit_project.lbutton_up()
{
   project_edit();
}

void _openfile_list.lbutton_double_click()
{
   _ok.call_event(_ok, LBUTTON_UP);
}

void _openfile_list.on_change(int reason)
{
   if (reason!=CHANGE_SELECTED) return;
   creating=1;
   int Nofselected=_openfile_list.p_Nofselected;
   _opennofselected.p_caption = Nofselected' of '_openfile_list.p_Noflines' selected';
   if (Nofselected==1 && _lbisline_selected()) {
      _openfn.p_text=_maybe_quote_filename(_lbget_text());
   }
   if (Nofselected>1){
      _openfn.p_text='';
   }
   creating=0;
}

static checkout_error(_str filename)
{
   typeless junk=0;process_events(junk);//process_events has a call by reference parameter
   _message_box(nls("An error occured while checking out the file %s.\nThe file may be checked out already, or there may be no archive file for %s",filename, filename));
   return(1);
}

/*
   Get current buffer name.  May be for check in current buffer.
*/
static _str vcinit_filename()
{
   if (_isEditorCtl()) {
      return(_maybe_quote_filename(p_buf_name));
   }
   return('');
}

 /**
 * 
 * Set the file in memory's read only attribute to match the 
 * actual file. 
 *
 * Available options:
 * <DL compact style="margin-left:20pt;">
 *   <DT>+<i>quiet</i>  <DD>Does not prompt or bring up message
 *   boxes on permissions problems.
 * </DL>
 * 
 * @param bool    fast_readonly if true, only check attribute on 
 *                disk, do not actually open the file and test.
 *                This option only affects Windows, the more
 *                stringent test is fast enough on UNIX.
 * 
 * @return int 
 */
_command int maybe_set_readonly(_str opts = '') name_info(','VSARG2_READ_ONLY|VSARG2_ICON)
{
   if (!_isEditorCtl() || (!p_mdi_child && !p_IsTempEditor)) {
      return(0);
   }
   if (_isdiffed(p_buf_id) || debug_is_readonly(p_buf_id)) {
      return(0);
   }
   attrs := "";
   ro := false;
   if (_isUnix()) {
      attrs=file_list_field(p_buf_name,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      if (attrs=='' || _DataSetIsFile(p_buf_name)) return(0);
      switch (_FileQType(p_buf_name)) {
      case VSFILETYPE_DATASET_FILE:
      case VSFILETYPE_JAR_FILE:
      case VSFILETYPE_GZIP_FILE:
      case VSFILETYPE_TAR_FILE:
      case VSFILETYPE_URL_FILE:
      case VSFILETYPE_PLUGIN_FILE:
         return(0);
      }
      ro=!pos('w',attrs,'','i') || _default_option(VSOPTION_FORCERO) || !_WinFileIsWritable(p_window_id);
      if (!p_readonly_set_by_user) {
         if (ro) {
            read_only_mode(opts);
         }else if (!ro) {
            if (p_readonly_mode) {
               read_only_mode_toggle(opts);
            }
         }
         p_readonly_set_by_user=false;
      }
      return(0);
   } else {
      ro= _default_option(VSOPTION_FORCERO);
      if (!ro) {
         if ( def_fast_auto_readonly ) {
            attrs=file_list_field(p_buf_name,DIR_ATTR_COL,DIR_ATTR_WIDTH);
            if (attrs=='' || _FileIsRemote(p_buf_name)) return(0);
            switch (_FileQType(p_buf_name)) {
            case VSFILETYPE_DATASET_FILE:
            case VSFILETYPE_JAR_FILE:
            case VSFILETYPE_GZIP_FILE:
            case VSFILETYPE_TAR_FILE:
            case VSFILETYPE_URL_FILE:
            case VSFILETYPE_PLUGIN_FILE:
               return(0);
            }
            ro=pos('r',attrs,'','i')!=0;
         }else{
            ro=!_WinFileIsWritable(p_window_id);
         }
      }
      if (!p_readonly_set_by_user) {
         if (ro) {
            read_only_mode(opts);
            //should reload here
         }else if (!ro) {
            if (p_readonly_mode) {
               quiet := pos('+quiet', opts) >= 1;

               _set_read_only(!p_readonly_mode,true,false,!quiet && def_rwprompt, quiet);
               //should reload here
            }
         }
         p_readonly_set_by_user=false;
      }
      return(0);
   }
}

_command old_checkin(typeless result="")  name_info(FILE_ARG'*,'VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   /* Command line operation:

      +c [comment]         Comment for all files
      +p                   Promt for each comment
      +d                   Discard changes
      +new                 Create a new archive file for all files
      .                    Check-in current buffer
   */
   orig_view_id := 0;
   if (result == '') {
      get_window_id(orig_view_id);
      _str filename;
      filename = "";
      if (arg() > 1) filename = arg(2);
      if (filename == "") {
         filename = vcinit_filename();
      }
      typeless was_recording=_macro();
      _macro_delete_line();
      result=show('-mdi -modal -reinit _vc_form',
                  'Check In',filename,_last_inwildcards,def_file_types);
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      result=strip(result);
      _macro('m',was_recording);
      _macro_call('old_checkin',result);
      activate_window(orig_view_id);
   }
   get_window_id(orig_view_id);
   typeless status=checkin_cl(result);
   activate_window(orig_view_id);
   if (!status) {
      maybe_set_readonly2();
   }
   return(status);
}

static checkin_cl(_str arglist)
{
   _str vcs=svc_get_vc_system();
   if (vcs=='') {
      _message_box(nls("You must have a version control system set for the current project to use Check-In/Check-Out from the command line."));
      return(1);
   }
   _vcquit_error_file();
   typeless status=delete_file(_vcerror_file());
   file_added := false;
   current_filename := "";
   if (_isEditorCtl()) {
      current_filename=absolute(p_buf_name);
   }
   prompt_for_each_comment := false;
   discard_changes := false;
   new_archive_files := false;
   current_buffer := false;
   grabbed_comment := false;
   typeless comment=NULL_COMMENT;
   filenames := "";
   for (;;) {
      if (grabbed_comment) {
         break;
      }
      _str s=parse_file(arglist);
      if (s=='') {
         break;
      }
      pm := substr(s,1,1);
      if (pm=='+'||pm=='-') {
         switch (lowcase(substr(s,2))) {
         case 'c':
            prompt_for_each_comment=false;
            comment=arglist;// Everything remaining in line should be a comment
            grabbed_comment=true;
            break;
         case 'p':
            prompt_for_each_comment=true;
            break;
         case 'd':
            discard_changes=pm=='+';
            break;
         case 'new':
            new_archive_files=pm=='+';
            break;
         }
      } else {
         /* It's a filename */
         file_added=true;
         if (s=='.') {
            s=current_filename;
         }
         filenames :+= ' '_maybe_quote_filename(s);
      }
   }
   if (!file_added) {
      _message_box(nls("No files were specified."));
      return('');
   }
   errors_view_id := 0;
   int orig_view_id=_create_temp_view(errors_view_id);
   //p_UTF8=0;  // Do this so fixed font is used.  Don't have to but no cmd-line vcs systems support Unicode
   if (orig_view_id=='') return(1);
   activate_window(orig_view_id);
   typeless linenum=0;
   status=_checkin(linenum,errors_view_id,filenames, vcs, new_archive_files, discard_changes,prompt_for_each_comment, comment);
   //show('-modal _vc_error_form',errors_view_id,linenum);
   DisplayOutputFromView(errors_view_id);
   delete_file(_vccomment_file());
   return(status);
}

static void maybe_set_readonly2()
{
   if((def_vcflags&VCF_SET_READ_ONLY)) {
      if (_isEditorCtl() && (p_buf_flags & VSBUFFLAG_HIDDEN)) {
         maybe_set_readonly();
      }
      if(!_no_child_windows()) {
         _mdi.p_child.for_each_buffer('maybe_set_readonly');
      }
   }
}


/* Command Line operation:

   checkout <options> filespec [filespec[..filespec]]

   Valid options are:

   +r Check out read only

   +e Edit newly checked out files

   .  Check out current buffer
*/
_command old_checkout(typeless result="", _str filename="") name_info(FILE_ARG'*,'VSARG2_READ_ONLY|VSARG2_ICON|VSARG2_NOEXIT_SCROLL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   typeless old_def_actapp=def_actapp;
   def_actapp=0;
   orig_view_id := 0;
   if (result == '') {
      get_window_id(orig_view_id);
      if (filename == "") {
         filename = vcinit_filename();
      }
      typeless was_recording=_macro();
      _macro_delete_line();
      result=show('-mdi -modal -reinit _vc_form',
               'Check Out',filename,_last_outwildcards,def_file_types);

      if (result=='') {
         def_actapp=old_def_actapp;
         return(COMMAND_CANCELLED_RC);
      }
      _macro('m',was_recording);
      _macro_call('old_checkout');
      activate_window(orig_view_id);
   }
   get_window_id(orig_view_id);
   typeless status=checkout_cl(result);
   activate_window(orig_view_id);
   def_actapp=old_def_actapp;
   if (!status) {
      maybe_set_readonly2();
   }
   return(status);
}

static checkout_cl(_str arglist)
{
   _param1="";
   _str vcs=svc_get_vc_system();
   if (vcs=='') {
      _message_box(nls("You must have a version control system set for the current project to use Check-In/Check-Out from the command line."));
      return(1);
   }
   _vcquit_error_file();
   typeless status=delete_file(_vcerror_file());
   current_filename := "";
   if (_isEditorCtl()) {
      // SourceSafe needs the path or sstree does not work.
      current_filename=p_buf_name;
   }
   read_only := false;
   edit_files := true;
   files_added := false;
   filename := "";
   filenames := "";
   _str list[];
   for (;;) {
      filename=parse_file(arglist);
      if (filename=='') {
         break;
      }
      pm := substr(filename,1,1);
      if (pm=='+'||pm=='-') {
         switch (lowcase(substr(filename,2))) {
         case 'r':
            read_only=pm=='+';
            break;
         case 'e':
            edit_files=pm=='+';
            break;
         }
      } else {
         files_added=true;
         /* Its a file */
         if (filename=='.') {
            filename=current_filename;
         }
         if (substr(filename,1,1)=='@') {
            temp_view_id := 0;
            orig_view_id := 0;
            status=_open_temp_view(substr(filename,2),temp_view_id,orig_view_id,"+b");
            if (!status) {
               top();up();
               for (;;) {
                  if (down()) break;
                  _str line=_lbget_text();
                  list :+= line;
               }
               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
            }
            filenames :+= ' 'filename;
         } else {
            filenames :+= ' '_maybe_quote_filename(absolute(filename));
         }
      }
   }
   if (!files_added) {
      _message_box(nls("No files were specified."));
      return('');
   }
   errors_view_id := 0;
   int orig_view_id=_create_temp_view(errors_view_id);
   if (orig_view_id=='') return(1);
   activate_window(orig_view_id);
   typeless linenum=0;
   status=_checkout(linenum,errors_view_id,filenames, vcs, edit_files, read_only);
   //show('-modal _vc_error_form',errors_view_id,linenum);
   DisplayOutputFromView(errors_view_id);
   if (edit_files) {
      if (list._length()) {
         _param1="";
         int i;
         for (i=0;i<list._length();++i) {
            if (_param1=="") {
               _param1=_maybe_quote_filename(list[i]);
            } else {
               _param1 :+= " ":+_maybe_quote_filename(list[i]);
            }
         }
      } else {
         _param1=strip(filenames);
      }
   } else {
      _param1="";
   }
   return(status);
}



_opendir_list.on_change()
{
   fill_in_sf_listbox();
#if 0
   _openfile_list._lbclear();
   _openfile_list.insert_file_list('-v +p '_openfn.p_text);
   _openfile_list._lbsort(_fpos_case' -f');
   _openfile_list.top();
#endif
}


void _opendrives.on_change(int reason)
{
   if (_NAME_HAS_DRIVE) {
      switch (reason) {
      case CHANGE_DRIVE:
         _opendir_list._dlpath(_dvldrive());
      }
   }
}


defeventtab _vc_comment_form;

static void save_restore_comment(_str Option)
{
   static _str LastComment;
   if (Option=='S') {
      LastComment='';
      top();up();
      while (!down()) {
         get_line(auto line);
         LastComment :+= "\n"line;
      }
      LastComment=substr(LastComment,2);//Get rid of leading \n
   }else if (Option=='R') {
      _lbclear();
      for (;;) {
         _str CurLine;
         parse LastComment with CurLine "\n" LastComment;
         if (CurLine=='') break;
         insert_line(CurLine);
      }
      if (!p_Noflines) {
         insert_line('');
      }
   }
}

void _ok.on_create(_str filename="", typeless doPrompt="", typeless showUse="")
{
   prompt_for_each_comment := doPrompt!='';
   show_use_for_all_cb := showUse!='';
   if (prompt_for_each_comment) {
      p_active_form.p_caption=p_active_form.p_caption' for 'filename;
   }
   ctlapply_to_all.p_visible=false;
   if (show_use_for_all_cb) {
      ctlapply_to_all.p_visible=true;
      _ok.p_y+=ctlapply_to_all.p_height;
      _ok.p_next.p_y=_ok.p_y;
      p_active_form.p_height+=ctlapply_to_all.p_height;
   }
   list1.save_restore_comment('R');
}
void _ok.lbutton_up()
{
   _param2=0;
   _str vcs=svc_get_vc_system();
   if (vcs=='') {
      p_active_form._delete_window();
      return;
   }
   //_ini_get_value(_vcssystem_file(),vcs, "styles", styles);
   typeless comment_file=0;
   multiline := 0;
   saveop := "";
   if (_isscc(vcs) && machine()=="WINDOWS") {
      comment_file=0;
      multiline=1;
   }else{
      comment_file = VersionControlSettings.getWriteCommentToFile(vcs);
      if (VersionControlSettings.getUNIXCommentFile(vcs)) {
         saveop='+fu';
      }
   }
   if (comment_file) {
      list1.save_restore_comment('S');
      list1.p_buf_name=absolute(_vccomment_file());
      list1.p_AllowSave=true;
      typeless status=list1.save(saveop);
      if (status) {
         return;
      }
      _param1=list1.p_buf_name;
      _param2=ctlapply_to_all.p_value;
      p_active_form._delete_window(0);
      return;
   }
   _param1='';
   if (list1.p_Noflines>1 && !multiline) {
      _message_box(nls("The %s Version Control System is not configured to allow multi-line comments",vcs));
      return;
   }
   if (list1.p_Noflines==1) {
      list1.bottom();
      list1.get_line_raw(_param1);
   }else if (multiline) {
      wid := p_window_id;
      p_window_id=list1;
      top();up();
      while (!down()) {
         _str line;
         get_line_raw(line);
         if (_param1=='') {
            _param1=line;
         }else{
            _param1 :+= p_newline:+line;
         }
      }
      p_window_id=wid;
   }
   if (ctlapply_to_all.p_visible) {
      _param2=ctlapply_to_all.p_value;
   }
   p_active_form._delete_window(0);
}

static _ssxlat_dir(_str filename,_str vcsproject,int vcsProjectStyle)
{
   filename=_ssxlat_dir2(strip(filename,'B','"'),vcsproject,vcsProjectStyle);
   return(_maybe_quote_filename(filename));
}
// Input filename must be absolute
static _ssxlat_dir2(_str filename,_str vcsproject, int vcsProjectStyle)
{
   if (vcsproject=='') {
      return(_strip_filename(filename,'P'));
   }
   ssdir := dir := "";
   parse vcsproject with '[' ssdir ']' dir;
   //messagenwait('ssdir='ssdir' dir='dir);

   //3:00pm 9/4/1997
   //Witout this first a trailing space gets turned into a directory
   ssdir=strip(ssdir);
   _maybe_append(ssdir, '/');

   if (vcsProjectStyle == VCS_PROJ_SS_ONE_DIR || vcsProjectStyle == VCS_PROJ_SS_LOCATE_FILE) {
      return(ssdir:+_strip_filename(filename,'P'));
   }
   dir=absolute(strip(dir));
   _maybe_append_filesep(dir);
   prefix := substr(filename,1,length(dir));
   if (!_file_eq(prefix,dir)) {
      // filename being checked in is not below this directory.
      // Return invalid filename
      return('');
   }
   filename=translate(ssdir:+substr(filename,length(dir)+1),'/',FILESEP);
   //messageNwait('filename='filename);
   return(filename);
}

// Extract a quoted string starting the specified position.
// Retn: string without the quotes
static _str vcExtractQuotedString(_str text, int from, _str quotechar, var toindex)
{
   result := "";
   _str ch, ch2;
   int i = from + 1;
   len := length(text);
   while (i <= len) {
      ch = substr(text, i, 1);
      if (ch == quotechar) {
         i++;
         break;
      } else if (ch == '\\') { // escape \X to just X
         if (i+1 <= len) {
            result :+= substr(text, i+1, 1);
            i++;
            i++;
         } else {
            result :+= '\';
            i++;
         }
      } else {
         result :+= ch;
         i++;
      }
   }
   toindex = i;
   return(result);
}

// Callback check to make sure some text is entered.
int vcCheckPrompt(_str text)
{
   if (text == "") {
      _message_box(nls("Missing argument value. Please try again."));
      return(1);
   }
   return(0);
}

static const VC_PARSE_CHAR= '%';

// Parse VC command and substitute components.
// Retn: command string, "" for user cancelled
static _str _vcparse_command(_str vcs,_str command,_str buf_name,_str project_name,
                             _str vcsproject,var comment,
                             typeless prompt_for_each_comment,int vcsProjectStyle)
{
   typeless dosrc="", rest="";
   parse command with dosrc rest;
   if (_file_eq(dosrc,'dosrc')) {
      // Find dosrc in the VSLICKPATH
      dosrc=get_env('VSLICKBIN1')'dosrc 'rest;
      command=_strip_filename(dosrc,'E')' 'rest;
   }
   s := "";
   ch2 := "";
   ext := "";
   dsname := "";
   member := "";
   before := "";
   typeless result="";
   typeless digit=0;
   typeless count=0;
   len := 0;
   int i=0, j=1;
   for (;;) {
     j=pos(VC_PARSE_CHAR,command,j);
     if ( ! j ) { break; }
     ch := upcase(substr(command,j+1,1));
     len=2;
     if ( ch=='P' ) {
       s=_strip_filename(buf_name,'N');
     } else if ( ch=='Q' ) {
        count=substr(command,j+2,1);
        if (!isinteger(count)) {
           s='';
        } else {
           len=3;
           s=_strip_filename(buf_name,'N');
           if (_NAME_HAS_DRIVE) {
              s=_strip_filename(s,'D');
              --count;
           }
           while (count>0) {
              parse substr(s,2) with (FILESEP) +0 s ;
              --count;
           }
        }
     } else if (ch=='D'){
        ch2=upcase(substr(command,j+2,1));
        len=2;
        s="";
        switch (ch2) {
        case 'Q':
           len=3;
           parse buf_name with "//" dsname"/"member;
           digit=substr(command,j+3,1);
           if (isdigit(digit)) {
              len=4;
              result='';
              while (digit-- >0) {
                 parse dsname with before '.' dsname;
                 if (before=='') {
                    break;
                 }
                 result=before;
              }
              dsname=result;
           }
           s=dsname;
           break;
        case 'M':  // member
           len=3;
           s=_strip_filename(buf_name,'P');
           break;
        case 'S':  // ds.name
           len=3;
           parse buf_name with "//" dsname"/"member;
           digit=substr(command,j+3,1);
           if (isdigit(digit)) {
              len=4;
              while (digit-- >0) {
                 dsname=_strip_filename(dsname,'E');
              }
           }
           s=dsname;
           break;
        case 'F':  // ds.name
           len=3;
           parse buf_name with "//" dsname"/"member;
           if (member!='') {
              s='"'dsname'('member')"';
           } else {
              s='"'dsname'"';
           }
        }
     } else if ( ch=='F' ) {
        if (_DataSetIsFile(buf_name)) {
           ch2=upcase(substr(command,j+2,1));
           ext='';
           if (ch2=='.') {
              i=pos('[ %]|$',command,j+3,'r');
              ext=substr(command,j+2,i-(j+2));
           }
           parse buf_name with "//" dsname"/"member;
           len+=length(ext);
           if (strieq(ext,'.o')) ext='.obj';
           if (strieq(ext,'.s')) ext='.asm';
           if (buf_name=='') {
              s='';
           } else {
              if (ext!='') {
                 dsname :+= ext;
              }
              if (_DataSetIsMember(buf_name)) {
                 s="\"//'"dsname"("member")'\"";
              } else {
                 s="\"//'"dsname"'\"";
              }
           }
        } else {
           suffixStr := upcase(substr(command,j+2,3));
           if ( suffixStr=='R2W' ) {
              len = 5;
              workspaceDir := _file_path(_workspace_filename);
              s=relative(buf_name,workspaceDir);
           } else {
              if (vcsProjectStyle == VCS_PROJ_SS_TREE || 
                  vcsProjectStyle == VCS_PROJ_SS_ONE_DIR ||
                  vcsProjectStyle == VCS_PROJ_SS_LOCATE_FILE) {
                 s=_ssxlat_dir(buf_name,vcsproject,vcsProjectStyle);
              } else {
                 s=relative(buf_name);
              }
           }
        }
     } else if ( ch=='N' ) {
        if (_DataSetIsFile(buf_name)) {
           ch2=upcase(substr(command,j+2,1));
           ext='';
           done := false;
           if (ch2=='.') {
              i=pos('[ %]|$',command,j+3,'r');
              ext=substr(command,j+2,i-(j+2));
           } else if (upcase(substr(command,j+2,2))=='%E') {
              parse buf_name with "//" dsname"/"member;
              len+=2;
              if (_DataSetIsMember(buf_name)) {
                 s="\"//'"dsname"("member")'\"";
              } else {
                 s="\"//'"dsname"'\"";
              }
              done=true;
           }
           if (!done) {
              parse buf_name with "//" dsname"/"member;
              len+=length(ext);
              if (strieq(ext,'.o')) ext='.obj';
              if (strieq(ext,'.s')) ext='.asm';
              if (buf_name=='') {
                 s='';
              } else {
                 dsname=_strip_filename(dsname,'E');
                 if (ext!='') {
                    dsname :+= ext;
                 }
                 if (_DataSetIsMember(buf_name)) {
                    s="\"//'"dsname"("member")'\"";
                 } else {
                    s="\"//'"dsname"'\"";
                 }
              }
           }
        } else {
           s=strip(_strip_filename(buf_name,'P'),'B','"');
           s=strip(_strip_filename(s,'E'),'B','"');
        }
     } else if ( ch=='C' ) {
        if (comment==NULL_COMMENT) {
           result=show('-modal _vc_comment_form',buf_name,prompt_for_each_comment);
           if (result=='') {
              return('');
           }
           // comment will be the filename if COMMENT_FILE style exists
           comment=_param1;
        }
        s=comment;
     } else if ( ch=='E' ) {
       s=strip(_get_extension(buf_name,true),'B','"');
     } else if (ch=='R'){
       ch2=upcase(substr(command,j+2,1));
       if (ch2=='N') {
          len=3;
          temp := _strip_filename(project_name,'P');
          temp=_strip_filename(temp,'E');
          s=temp;
       }else if (ch2=='P') {
          len=3;
          s=_strip_filename(project_name,'N');
       }else{
          s=project_name;
       }
     } else if (ch=='S'){
        if (vcsProjectStyle == VCS_PROJ_SS_TREE || 
            vcsProjectStyle == VCS_PROJ_SS_ONE_DIR ||
            vcsProjectStyle == VCS_PROJ_SS_LOCATE_FILE) {
           parse vcsproject with '[' s ']';
           s=strip(s);
       } else {
          s=vcsproject;
       }
     } else if (ch=='T'){  // Error file
       s=_vcerror_file();
     } else if ( ch=='V' ) {
       s=buf_name;
       if ( substr(s,2,1)==':' ) {
         s=substr(s,1,2);
       } else {
         s='';
       }
     } else if (ch=='L') {
        if (_isrcs(vcs)) {
           s='';
           // Has the user specified a directory?
           if (vcsproject!='') {
              s=vcsproject;
              _maybe_append_filesep(s);
              s :+= _strip_filename(strip(buf_name,'B','"'),'P');
              if (_isUnix()) {
                 s :+= ',v';
              }
           }
        }
     } else if ( ch=='(' ) {
        int k=pos(')',command,j+1);
        s='';
        if (k) {
           len=k-j+1;
           envvar_name := substr(command,j+2,len-3);
           s=get_env(envvar_name);
        }
     } else if (ch == 'A') {
        // Prompt the user for an argument string.
        msg := "";
        s = "";
        len = 2;
        quotechar := substr(command, j+2, 1);
        if (quotechar == '"' || quotechar == "'") {
           // Get the prompt string for the argument.
           int toindex;
           msg = vcExtractQuotedString(command, j+2, quotechar, toindex);
           len = toindex - j;

           // Prompt the user for a string.
           result = show("-modal _textbox_form"
                              ,"Version Control Prompt"
                              ,0 // flags
                              ,'' // default width
                              ,'' // no help item
                              ,'' // Buttons and captions
                              ,''
                              ,"-e vcCheckPrompt "msg);
           if (result == '') {
              return(""); // returning "" indicates user cancellation
           } else if (result == 1) {
              s = _param1;
           }
        }
     } else if ( ch==VC_PARSE_CHAR ) {
       s=VC_PARSE_CHAR;
     } else {
       len=1;
       /* insert pc filename */
       s='';
     }
     command=substr(command,1,j-1):+s:+substr(command,j+len);
     j += length(s);
   }
   return(command);
}

defeventtab _vc_error_form;

void _VCErrorForm(int errors_view_id,int linenum=-1,_str caption='',
                  bool JumpToBottom=false)
{
   show('-modal _vc_error_form',errors_view_id,linenum,caption,JumpToBottom);
}

void list1.on_create(int errors_view_id,int linenum=-1,_str caption='',
                     bool JumpToBottom=false)
{
   if (caption!='') {
      p_active_form.p_caption=caption;
   }

   if (errors_view_id=='') {
      //say('bail 1 errors_view_id=""');
      return;
   }

   int list_buf_flags=p_buf_flags;
   list_view_id := 0;
   get_window_id(list_view_id);
   activate_window(errors_view_id);
   //4:47pm 1/20/1999 CHRIS DEBUG STUFF
   //say('list1.on_create p_Noflines='p_Noflines);
   if (!p_Noflines && !VersionControlSettings.getAlwaysShowOutput(svc_get_vc_system()) ) {
      _delete_temp_view(errors_view_id);
      activate_window(list_view_id);
      p_active_form._delete_window();

      return;
   }
   int errors_buf_id=p_buf_id;
   _delete_temp_view(errors_view_id,false);
   activate_window(list_view_id);
   _delete_buffer();
   p_buf_id=errors_buf_id;
   p_buf_flags=list_buf_flags;
   read_only_mode();
   top();
   if (linenum>-1) {
      p_line=linenum;
   }
   if (JumpToBottom) {
      bottom();
   }
}

void _vc_error_form.on_resize()
{
   if (!_find_formobj('_vc_error_form','N')) {
      //9:01am 6/22/1998
      //This is a workaround for a bug if a form is deleted in on_create.
      //Clark has fixed this, I just don't have the fix yet.
      return;
   }
   list1.p_width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-(list1.p_x*2);
   _yes.p_y=_dy2ly(SM_TWIP,p_active_form.p_client_height)-_yes.p_height-100;
   list1.p_height=_yes.p_y-100-list1.p_y;
}

static dosrc_shell(_str command,int styles,_str ShellOptions='')
{
   _str temp=command;
   _str pgmname=parse_file(temp);
   typeless temp_view_id='';
   read_return_code := false;

   if ((styles & VCS_DOSRC_FOR_ERROR) && _win32s()==0 && machine()=='WINDOWS') {
      if (machine()=='WINDOWS') {
         command='dosrc 'command;
      } else {
         read_return_code=true;
         command='dosrc -f '_vcerror_file2()' 'command;
      }
   }
   alternate_shell := "";
   if (_isUnix()) {
      alternate_shell='/bin/sh';
      if (file_match('-p 'alternate_shell,1)=='') {
         alternate_shell=path_search('sh');
         if (alternate_shell=='') {
            _message_box(nls("Could not find sh shell"));
         }
      }
   }
   if (_vcdebug) {
      _message_box('cwd='getcwd()' command='command);
   }
   typeless status=0;
   found_internal_command := false;

   errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styles);
   if (errorStyle == VCS_ERROR_INTERNAL_LOOKUP) {
      parse command with pgmname .;
      index := find_index(pgmname,COMMAND_TYPE);
      if (index) {
         found_internal_command=true;
         status=execute(command,'');
      } else {
         status=shell(command,'p'ShellOptions,alternate_shell);
      }
   } else {
      status=shell(command,'p'ShellOptions,alternate_shell);
   }
   //_message_box('pgmname='pgmname' status='status);
   // We get UNKNOWN_COMMAND_RC and not FILE_NOT_FOUND_RC
   // when a program is not found.
   if (!found_internal_command &&
       (status==FILE_NOT_FOUND_RC ||
        status==UNKNOWN_COMMAND_RC ||
        status==PATH_NOT_FOUND_RC) &&
       path_search(pgmname,'PATH','P')=="" ) {
      // IF the program name has no path specified.
      if (_strip_filename(pgmname,'N')=="") {
         _message_box(nls('Program %s not found.  Make sure this program can be found on your PATH',pgmname));
      } else {
         _message_box(nls('Program %s not found.',pgmname));
      }
   } else {
      /* Dan added for new sswcl support */
      if (errorStyle == VCS_ERROR_FILE) {
         orig_view_id := 0;
         int tstatus=_open_temp_view(_vcerror_file(), temp_view_id, orig_view_id);
         if (tstatus) {
            if (ShellOptions=='') {
               /* Error file not found, or something */
               _message_box(nls("Could not open error file."));
               status=1;
            }
            /* Force error, since we don't know what happened */
         }else{
            p_window_id=temp_view_id;
            //top();
            //2:52pm 1/27/1999
            //Changing for a scenario where there are multiple "exit code"
            //entries in the output
            bottom();
            tstatus=search('^exit code\:','@rhi-');
            /* Look for error code part */
            if (tstatus) {
               // User may have an incorrect version of the sswcl.exe program.
               _message_box(nls("Could not find error code"));
               /* If the error code is not found, they may have an incorrect version of sswcl */
               /* So, we warn them of this possibility */
               status=1;
               /* Force error, since we don't know what happened */
            }else{
               get_line(auto line);
               trc := "";
               parse line with ':' trc;
               status=strip(trc);
               /* get error code and set status to it */
            }
            _delete_temp_view(temp_view_id);
            p_window_id=orig_view_id;
         }
      }


      if (read_return_code) {
         orig_view_id := 0;
         status=_open_temp_view(strip(_vcerror_file2(),'B','"'),temp_view_id,orig_view_id,'+d +l');
         if (!status) {
            get_line(status);
            if (!isinteger(status)) {
               status=0;
            }
            _delete_temp_view(temp_view_id);
         }
         delete_file(_vcerror_file2());
         activate_window(orig_view_id);
      }
   }

   if (_vcdebug) {
      if (!_win32s()) {
         // Strange bug in Windows NT.  Must flush keyboard before waiting for key
         _mdi.refresh();
         flush_keyboard();
      }
      _message_box('shell status='status);
   }
   return(status);
}
static _vcshell(_str vcs,_str command,int styles,
                _str buf_name,_str &lastss_cd,_str vcsproject,
                _str ssnew_archives='',int ForceError=0,
                _str ShellOptions='')
{
   typeless status=_vcshell2(vcs,command,styles,buf_name,lastss_cd,vcsproject,ssnew_archives,ShellOptions);

   if (!status && !ForceError && (styles & VCS_DELTA_ERROR)) {

      errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styles);
      if (errorStyle == VCS_ERROR_FILE || errorStyle == VCS_ERROR_STDERR_STDOUT || errorStyle == VCS_ERROR_STDOUT) {
         temp_view_id := 0;
         int orig_view_id=_create_temp_view(temp_view_id);
         if (orig_view_id!='') {
            status=get(_vcerror_file(),'','A');
            int noerror=search('^(Error|Warning)\:','rhi@');
            //messageNwait('msg noerror='get_message(noerror));
            status=(noerror)?0:1;
            activate_window(orig_view_id);
            _delete_temp_view(temp_view_id);
         }
      }
   }
   return(status);
}
static _vcshell2(_str vcs,_str command,int styles,_str buf_name,
                 var lastss_cd,_str vcsproject,_str ssnew_archives='',
                 _str ShellOptions='')
{

   errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styles);
   program := arg_list := "";
   if (errorStyle == VCS_ERROR_STDERR_STDOUT) {
      //parse command with program arg_list;
      program = parse_file(command);
      arg_list = command;
      command=program' >'_vcerror_file()' 2>&1 'arg_list;
   } else if (errorStyle == VCS_ERROR_STDOUT) {
      parse command with program arg_list;
      command=program' >'_vcerror_file()' 'arg_list;
   }
   typeless status=0;
   old_cwd := "";
   path := "";

   vcs=svc_get_vc_system();
   vcsProjectStyle := VersionControlSettings.getVCSProjectStyle(vcs);
   if (ssnew_archives!='') {
      old_cwd=getcwd();
      path=_strip_filename(buf_name,'N');
      if (lastss_cd!=path) {
         //messageNwait('vcsproject='vcsproject)

         tvcsproject := VersionControlSettings.getVCSProject(vcs);

         info := "";
         parse tvcsproject with . ',' info;

         buf_name=strip(buf_name,'B','"');
         _str ssdir=_ssxlat_dir(buf_name,vcsproject,vcsProjectStyle);
         i := lastpos('/',ssdir);
         if (i) {
            ssdir=substr(ssdir,1,i);
         }
         vcsproject='['_maybe_quote_filename(ssdir)']';
         comment := "";
         _str newcommand=_vcparse_command(vcs, info, buf_name, _project_name, vcsproject, comment,'',vcsProjectStyle);
         if (newcommand == "") {
            return(COMMAND_CANCELLED_RC); // user cancelled
         }

         status=dosrc_shell(newcommand,styles,ShellOptions);
         if (status) {
            //Was using wrong quote type to use \n 10:25am 4/29/1996
            _message_box(nls("Failed to set Source Current Directory by executing the command:\n\n%s",newcommand));
            return(status);
         }
         lastss_cd=path;
      }
      status=chdir(strip(path,'B','"'),1);
      status=dosrc_shell(command,styles,ShellOptions);
      chdir(old_cwd,1);

   } else if (vcsProjectStyle == VCS_PROJ_SS_TREE || 
              vcsProjectStyle == VCS_PROJ_SS_ONE_DIR ||
              vcsProjectStyle == VCS_PROJ_SS_LOCATE_FILE) {
      old_cwd=getcwd();
      path=_strip_filename(buf_name,'N');
      // When performat ss locate, buf_name is ''
      if (path=='') {
         status=dosrc_shell(command,styles,ShellOptions);
      } else {
         status=chdir(strip(path,'B','"'),1);
         status=dosrc_shell(command,styles,ShellOptions);
         chdir(old_cwd,1);
      }
   } else {
      old_cwd='';
      // strip_filename() and chdir() cannot handle quoted paths
      filedir := _strip_filename(strip(buf_name,'B','"'),'N');

      cdToFileOption := (styles & VCS_CD_TO_FILE) != 0;

      if (cdToFileOption) {
         old_cwd=getcwd();
         int cdstatus=chdir(filedir,1);
         if (cdstatus) {
            _message_box(nls("Could not change to directory '%s'",filedir));
            return(cdstatus);
         }
      }
      status=dosrc_shell(command,styles,ShellOptions);
      if (cdToFileOption) {
         int cdstatus=chdir(old_cwd,1);
         if (cdstatus) {
            _message_box(nls("Could not change to directory '%s'",old_cwd));
            return(cdstatus);
         }
      }
   }
   // Check for warning from RCS and make sure the message gets displayed.
   if (_isrcs(vcs) && errorStyle == VCS_ERROR_STDERR_STDOUT && status==0 && file_list_field(_vcerror_file(),DIR_SIZE_COL,DIR_SIZE_WIDTH)>0) {
      status=1;
   }
   return(status);
}

static int sslocate_project(_str command,_str buf_name,int styles, var vcsproject,
                            typeless ssnew_archives)
{
   typeless result="";
   if ((styles & VCS_PROJ_SS_LOCATE_FILE) == 0) return(0);

   if (ssnew_archives!='') {
      //messageNwait('vcsproject='vcsproject)
      result = show('-modal _textbox_form',
                    'Checkin New file 'buf_name, // Form caption
                    0,  //flags
                    '', //use default textbox width
                    '', //Help item.
                    '', //Buttons and captions
                    'sslocate', //Retrieve Name
                    'Source Safe Project:'
                    );

      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      vcsproject='['_param1 ']';
      //messageNwait('vcsproject='vcsproject);
      return(0);
   }
   // Locate which Source Safe project this file is in
   ssexe := "";
   parse command with ssexe .;
   locatecmd := ssexe' locate '_strip_filename(buf_name,'P');
   locatecmd :+= " -o@"_vcerror_file()" -exitcode";
   typeless junk="";
   typeless status=_vcshell2('',locatecmd,styles,'',junk,vcsproject);
   if (status) {
      _message_box(nls("Failed to locate Source Safe project for %s.  Shell error",buf_name));
      return(status);
   }
   line := "";
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id!='') {
      status=get(_vcerror_file(),'','A');
      top();
      status=1;
      for (;;) {
         if(_on_line0()) break;
         get_line(line);
         _delete_line();
         if (pos("Searching",line)) {
            status=0;
            break;
         }
      }
      if (status) {
         _delete_temp_view(temp_view_id);
         _message_box(nls("Failed to locate Source Safe project for %s.  Keyword 'Searching' not found.",buf_name));
         return(NOT_ENOUGH_MEMORY_RC);
      }
      base_project := "";
      parse lowcase(vcsproject) with '[' base_project ']';
      found_file_in_base := false;
      top();up();
      for (;;) {
         if(down()) break;
         get_line(line);
         i := lastpos('/',line);
         if (pos('(Removed)',line)) {
            if(_delete_line()) break;
            up();
            continue;
         }
         if (i) {
            line=substr(line,1,i-1);
         }
         if (line=='$') line='$/';
         if (line=='') {
            _delete_line();
            break;
         }
         if (base_project==lowcase(substr(line,1,length(base_project)))) {
            found_file_in_base=true;
         }
         _lbset_item(line);
      }
      top();get_line(line);
      if (_on_line0() || line=="No matches found.") {
         _delete_temp_view(temp_view_id);
         _message_box(nls("Failed to locate Source Safe project for %s.  Use the New Archive File(s) option to check in a new file.",buf_name));
         return(NOT_ENOUGH_MEMORY_RC);
      }
      if (base_project!='') {
         if (found_file_in_base) {
            top();up();
            for (;;) {
               if(down()) break;
               line=_lbget_text();
               if (base_project!=lowcase(substr(line,1,length(base_project)))) {
                  if(_lbdelete_item()) break;
                  up();
               }
            }
         }
      }
      result=_lbget_text();
      if (p_Noflines>1) {
         activate_window(orig_view_id);
         result=show('-modal _sellist_form',
              nls('Select Project for %s',buf_name),
              SL_VIEWID|SL_SELECTPREFIXMATCH|SL_COMBO|SL_MUSTEXIST, // flags
              temp_view_id,     // input_data
              "",       // buttons
              nls('?Choose the Source Safe project for which the file %s belongs',buf_name),    // help item
              '',   // font

              '',   // Call back function
              '',   // Item separator for list_data
              '',   // Retrieve form name
              '',   // Combo box. Completion property value.
              7000,   // minimum list width
              result    // Combo Box initial value
             );
      }
      activate_window(orig_view_id);
      result=strip(result);
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      vcsproject='['result']';
   }
   return(0);
}


static _str MaybeStripLeadingVCSName(_str VCSName,_str &VCS='')
{
   p1 := pos(':',VCSName);
   if (p1) {
      VCS=substr(VCSName,1,p1-1);
      prjname := substr(VCSName,p1+1);
      return(prjname);
   }
   return(VCSName);
}

/*
   CommandName is the name of the command to be executed as it appears in the
   vc file(vcsystem.slk or uservc.slk).

   If ForceOutput is non-zero we make sure that we get output even if there is
   no error condition.
*/
int _misc_cl_vc_command(_str CommandName,
                               int ErrorsViewId,
                               _str Filename,
                               _str vcs,
                               int ForceOutput,
                               _str ShellOptions='')
{
   info := VersionControlSettings.getCommandByName(vcs, CommandName);

   //if (Filename=='') return(1);
   //2:43pm 7/2/1998
   //For manager we don't need a filename
   _str vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   vcsproject=MaybeStripLeadingVCSName(vcsproject);
   vcsProjectStyle := VersionControlSettings.getVCSProjectStyle(vcs);
   comment := "";
   _str command=_vcparse_command(vcs, info, Filename,
                            _project_name, vcsproject, comment,
                            0,//prompt for each comment
                            vcsProjectStyle);
   if (command=='') {
      return(COMMAND_CANCELLED_RC);
   }
   if (command==COMMAND_CANCELLED_RC) {
      return(COMMAND_CANCELLED_RC);
   }
   if (file_match(_vcerror_file()' -p',1)!='') {
      delete_file(_vcerror_file());
   }
   typeless lastss_cd="";
   typeless linenum=0;

   styles := VersionControlSettings.getStyleFlags(vcs);
   status := _vcshell(vcs,command,styles,Filename,lastss_cd,vcsproject,'',ForceOutput,ShellOptions);

   if (status || (styles & VCS_ALWAYS_SHOW_OUTPUT) || ForceOutput) {
      errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styles);
      _vcappend_errors(linenum,ErrorsViewId,errorStyle);
   }
   if (status==FILE_NOT_FOUND_RC) {
      rest := "";
      parse command with Filename rest;
      clear_message();
      _message_box(nls("Program '%s' not found",Filename));
      return(status);
   }
   return(status);
}


/*
   filespec is a filespec to check in, or a view_id of a list of filespecs to check
      in.

   vcs is the name of the current version control system

   new_archives is one if the user wants new archive files to be made for all files
      to be checked in.

   discard_changes is 1 if the user wants a "Unlock and Discard" action for each of
      the files to be checked in

   prompt_for_each_comment  is non-zero if the user wants to specify a comment for each file.

   comment is a comment (just for better command line support)
*/
static _checkin(var linenum,int errors_view_id,_str filespec, _str vcs, 
                typeless new_archives, typeless discard_changes,
                typeless prompt_for_each_comment, _str comment)
{
   typeless status=0;
   typeless result=0;

   if (machine()=='WINDOWS' && _haveVersionControl() && _isscc(vcs)) {
      vcs=substr(vcs,5);
      if (_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)!=vcs) {
         status=_SccInit(vcs);
         if (status) {
            _message_box(nls("Could not initialize support for '%s'",vcs));
            return(status);
         }
      }
      //Hey, no project name for Object Cycle.
      //So much for foolproof
      if (_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)=='') {
         _message_box(nls("You must first open a project(Tools...Version Control...Setup)"));
         return(1);
      }
      _str Files[];
      Files._makeempty();
      ExpandFilespecForSCC(filespec,Files);
      if (!Files._length()) {
         return(1);
      }
      status=0;
      if (new_archives) {
         int FileStatus[];
         status=_SccQueryInfo(Files,FileStatus);
         if (status) {
            _message_box(nls(vcget_message(status)));
            return(status);
         }
         if ( (FileStatus[0]&(VSSCC_STATUS_CONTROLLED|VSSCC_STATUS_DELETED))==(VSSCC_STATUS_CONTROLLED|VSSCC_STATUS_DELETED) ) {
            _message_box(nls("This file is already in version control, but is deleted.  You must either undelete or purge this file first."));
            return(1);
         }else if (FileStatus[0]&VSSCC_STATUS_CONTROLLED) {
            _message_box(nls("This file is already in version control."));
            return(1);
         }
         status=_SccAdd(Files,comment);
         //Check it in, but we gotta prompt for a comment.
         if (status) {
            //_message_box(nls("An error occured while checking in files"));
            _message_box(nls("%s",vcget_message(status)));
         }
      }else{
         _str OrigFiles:[];
         CopyArrayToHashTab(OrigFiles,Files);
         int Command;
         if (discard_changes) {
            Command=VSSCC_COMMAND_UNCHECKOUT;
         }else{
            Command=VSSCC_COMMAND_CHECKIN;
         }
         status=_SccPopulateList(Command,Files,1);
         if (Files._length()) {
            int FileStatus[];
            status=_SccQueryInfo(Files,FileStatus);
            if (status) {
               _message_box(nls(vcget_message(status)));
               return(status);
            }
            int i;
            for (i=0;i<FileStatus._length();++i) {
               if (FileStatus[i]==VSSCC_STATUS_NOTCONTROLLED) {
                  //This returns flags,but is 0, so we have to check for exact
                  FileStatus._deleteel(i);
                  Files._deleteel(i);
                  --i;
               }
            }
         }

         _str ExistingFiles:[];
         CopyArrayToHashTab(ExistingFiles,Files);

         RemovedFileList := "";
         _str ActionName;
         if (discard_changes) {
            ActionName='unlock';
         }else{
            ActionName='checkin';
         }
         GetRemovedFileList(OrigFiles,ExistingFiles,RemovedFileList);
         if (!Files._length()) {
            //All files were removed
            _message_box(nls("Cannot %s the following files:\n%s\n\nThese files may not be checked out, or archives may not exist for these files",ActionName,RemovedFileList));
            return(1);
            //Display message 'The following files could not be checked out'
            //No continue message, return immediatley
         }
         if (RemovedFileList!='') {
            result=_message_box(nls("Cannot %s the following files:\n%s\nContinue?",ActionName,RemovedFileList));
            if (result!=IDYES) {
               return(COMMAND_CANCELLED_RC);
            }
         }

         if (discard_changes) {
            status=_SccUncheckout(Files);
            if (status) {
               _message_box(nls("An error occured while unlocking files"));
            }
         }else{
            status=_SccCheckin(Files,comment);
            //Check it in, but we gotta prompt for a comment.
            if (status<0) {
               _message_box(nls("An error occured while checking in files"));
            }else if (status>0) {
               //Need to reload the file...
               temp_view_id := 0;
               int orig_view_id=_create_temp_view(temp_view_id);
               int i;
               for (i=0;i<Files._length();++i) {
                  insert_line(' 'Files[i]);
               }
               p_window_id=orig_view_id;
               edit_and_close_files(temp_view_id);
            }
         }
      }
      return(status);
   }
   linenum='';
   typeless info="";
   if (new_archives) {
      info = VersionControlSettings.getCommand(vcs, VCADD);
   } else if (!discard_changes) {
      info = VersionControlSettings.getCommand(vcs, VCCHECKIN);
   } else {// Discard Changes
      info = VersionControlSettings.getCommand(vcs, VCUNLOCK);
   }
   if (info=='') {
      return(status);
   }

   vcsproject := VersionControlSettings.getVCSProject(vcs);
   styleFlags := VersionControlSettings.getStyleFlags(vcs);
   vcsProjectStyle := VersionControlSettings.getVCSProjectStyleFromFlags(styleFlags);
   errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styleFlags);

   project_option := "";
   parse lowcase(vcsproject) with project_option ',';
   vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   vcsproject=MaybeStripLeadingVCSName(vcsproject);
   ssnew_archives := "";
   lastss_cd := "";
   
   if (new_archives && 
       (vcsProjectStyle == VCS_PROJ_SS_TREE || vcsProjectStyle == VCS_PROJ_SS_ONE_DIR || vcsProjectStyle == VCS_PROJ_SS_LOCATE_FILE)) {
      ssnew_archives=1;
      // Don't want _ssxlat_dir to be called
   }
   orig_cd := "";
   if (project_option=='dir') {
      orig_cd=getcwd();
      if (vcsproject!='') {
         status=chdir(vcsproject,1);
         if (status) {
            _message_box(nls("VCS Project is invalid directory"));
            return(1);
         }
      }
   }

   needVCSProject := VersionControlSettings.getVCSProjectRequired(vcs) && 
      vcsproject=='' && vcsProjectStyle != VCS_PROJ_SS_LOCATE_FILE;

   if (needVCSProject) {
      _message_box("The VCS Project must be set.  Use Check In dialog box to set VCS Project.");
      return(1);
   }
   filename := "";
   command := "";
   line := "";
   filespec=strip(filespec);
   if (substr(filespec,1,1)!='@') {
      for (;;) {
         filename=parse_file(filespec);
         if (filename=='') break;
         status=sslocate_project(info,filename,vcsProjectStyle,vcsproject,ssnew_archives);
         if (status) break;
         command=_vcparse_command(vcs, info, filename, _project_name, vcsproject, comment,prompt_for_each_comment,vcsProjectStyle);
         if (prompt_for_each_comment) {
            comment=NULL_COMMENT;
         }
         if (command == "") {
            status=COMMAND_CANCELLED_RC; // user cancelled
            break;
         }
         if (command==COMMAND_CANCELLED_RC) {
            status=command;
            break;
         }
         if (vcsProjectStyle == VCS_PROJ_SS_TREE && _ssxlat_dir(filename,vcsproject,vcsProjectStyle)=='') {
            status=1;
            line=nls('The file %s is not in or below the current project',filename);
            _vcappend_error_message(linenum,errors_view_id,errorStyle,line);
         } else {
            status=_vcshell(vcs,command,styleFlags,filename,lastss_cd,vcsproject,ssnew_archives);
            if (iswildcard(filename) || status || styleFlags & VCS_ALWAYS_SHOW_OUTPUT) {
               _vcappend_errors(linenum,errors_view_id,errorStyle);
               //handle_error(vcs, status, filename, 1/* checking in */, new_archives);
            }
            if (status==FILE_NOT_FOUND_RC) {
               rest := "";
               parse command with filename rest;
               clear_message();
               _message_box(nls("Program '%s' not found",filename));
               break;
            }
         }
      }
   }else{
      temp_view_id := 0;
      orig_view_id := 0;
      status=_open_temp_view(strip(substr(filespec,2),'B','"'),temp_view_id,orig_view_id);
      if (status) {
         if (orig_cd!='') chdir(orig_cd,1);
         return(status);
      }
      top();up();
      for (;;) {
         /* In this section, I shell out for each file individually.  Therefore,
            If the user has specified one commment to be used for all files, I
            just put it into each command line, depending on the VCS's syntax*/
         activate_window(temp_view_id);
         if (down()) {
            break;
         }
         get_line(filename);
         filename=strip(filename/*,'L'*/);
         if (filename=='') continue;
         filename=_maybe_quote_filename(filename);
         status=sslocate_project(info,filename,vcsProjectStyle,vcsproject,ssnew_archives);
         if (status) break;
         command=_vcparse_command(vcs, info, filename, _project_name, vcsproject, comment,prompt_for_each_comment,vcsProjectStyle);
         if (prompt_for_each_comment) {
            comment=NULL_COMMENT;
         }
         if (command == "") {
            status=COMMAND_CANCELLED_RC; // user cancelled
            break;
         }
         if (command==COMMAND_CANCELLED_RC) {
            status=command;
            break;
         }
         if (vcsProjectStyle == VCS_PROJ_SS_TREE && _ssxlat_dir(filename,vcsproject,vcsProjectStyle)=='') {
            status=1;
            line=nls('The file %s is not in or below the current project',filename);
            _vcappend_error_message(linenum,errors_view_id,errorStyle,line);
         } else {
            status=_vcshell(vcs,command,styleFlags,filename,lastss_cd,vcsproject,ssnew_archives);
            if (status || styleFlags & VCS_ALWAYS_SHOW_OUTPUT) {
               _vcappend_errors(linenum,errors_view_id,errorStyle);
               //handle_error(vcs, status, filename, 1/* checking in */, new_archives);
            }
            if (status==FILE_NOT_FOUND_RC) {
               rest := "";
               parse command with filename rest;
               clear_message();
               _message_box(nls("Program '%s' not found",filename));
               break;
            }
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   if (orig_cd!='') chdir(orig_cd,1);
   return(status);
}

static void _vcpvcs_append_checkout(int errors_view_id,int styles,int filelist_view_id)
{
   if ((styles & VCS_PVCS_WILDCARDS) == 0) return;

   errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styles);
   
   if (errorStyle == VCS_ERROR_FILE || errorStyle == VCS_ERROR_STDERR_STDOUT || 
       errorStyle == VCS_ERROR_STDOUT) return;

   orig_view_id := 0;
   get_window_id(orig_view_id);
   activate_window(VSWID_HIDDEN);
   _safe_hidden_window();
   typeless status=load_files(_vcerror_file());
   if (!status) {
      top();
      status=search('^{:p}( <- ){:p}','rh@');
      for (;;) {
         if (status) break;
         word := get_match_text(0);
         activate_window(filelist_view_id);
         _lbadd_item(absolute(word));
         activate_window(VSWID_HIDDEN);
         status=repeat_search();
      }
      _delete_buffer();
   }
   activate_window(orig_view_id);
}
static _vcappend_errors(var linenum,int errors_view_id,int errorStyle)
{
   if (errorStyle == VCS_ERROR_FILE || errorStyle == VCS_ERROR_STDERR_STDOUT || errorStyle == VCS_ERROR_STDOUT) {
      orig_view_id := 0;
      get_window_id(orig_view_id);
      activate_window(errors_view_id);
      typeless status=get(_vcerror_file(),'','A');
      if (!status) {
         if (linenum=='') {
            linenum=p_line+1;
         }
         bottom();
      }
      activate_window(orig_view_id);
   }
}
static _vcappend_error_message(var linenum,int errors_view_id,int errorStyle,_str msg)
{
   if (errorStyle == VCS_ERROR_FILE || errorStyle == VCS_ERROR_STDERR_STDOUT || errorStyle == VCS_ERROR_STDOUT) {
      orig_view_id := 0;
      get_window_id(orig_view_id);
      activate_window(errors_view_id);
      insert_line(msg);
      if (linenum=='') {
         linenum=p_line+1;
      }
      bottom();
      activate_window(orig_view_id);
   }
}

static void ExpandFilespecForSCC(_str filespec,_str (&Files)[])
{
   if (!iswildcard(filespec)) {
      int i;
      for (i=0;;++i) {
         cur := strip(parse_file(filespec),'B','"');
         if (cur=='') break;
         Files[i]=cur;
      }
      return;
   }
   ff := 1;
   for (;;) {
      filename := file_match(_maybe_quote_filename(filespec)' -p',ff);ff=0;
      if (filename=='') break;
      Files[Files._length()]=strip(filename);
   }
}

static void CopyArrayToHashTab(_str (&FilesTab):[],_str FilesArray[])
{
   int i,len=FilesArray._length();
   for (i=0;i<len;++i) {
      FilesTab:[FilesArray[i]]=FilesArray[i];
   }
}

static void GetRemovedFileList(_str OrigFiles:[],
                               _str ExistingFiles:[],
                               _str &RemovedFileList)
{
   typeless i;
   for (i._makeempty();;) {
      OrigFiles._nextel(i);
      if (i._varformat()==VF_EMPTY) break;
      if (!ExistingFiles._indexin(i)) {
         if (RemovedFileList=='') {
            RemovedFileList=i;
         }else{
            RemovedFileList :+= "\n"i;
         }
      }
   }
}

/*
   vcs is the name of the current version control system

   read_only is 1 if the user wishes to check out all files specified in "browse"
      mode.
*/
static _checkout(int &linenum,int errors_view_id,_str filespec,_str vcs,bool edit_files,bool read_only)
{
   typeless status=0;
   typeless result=0;

   if (machine()=='WINDOWS' && _haveVersionControl() && _isscc(vcs)) {
      vcs=substr(vcs,5);
      if (_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)!=vcs) {
         status=_SccInit(vcs);
         if (status) {
            _message_box(nls("Could not initialize support for '%s'",vcs));
            return(status);
         }
      }
      if (_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)=='') {
         _message_box(nls("You must first open a project(Tools...Version Control...Setup)"));
         return(1);
      }
      _str Files[];
      Files._makeempty();
      filespec=strip(filespec);
      ExpandFilespecForSCC(filespec,Files);
      if (!Files._length()) {
         return(1);
      }

      _str OrigFiles:[];
      CopyArrayToHashTab(OrigFiles,Files);
      //status=_SccPopulateList(VSSCC_COMMAND_CHECKOUT,Files,1);

      int FileStatus[];
      status=_SccQueryInfo(Files,FileStatus);
      if (status) {
         _message_box(nls(vcget_message(status)));
         return(status);
      }
      int i;
      for (i=0;i<Files._length();++i) {
         if (/*!FileStatus[i] ||*/ FileStatus[i]==VSSCC_STATUS_INVALID) {
            FileStatus._deleteel(i);
            Files._deleteel(i);
            --i;
         }
      }

      _str ExistingFiles:[];
      CopyArrayToHashTab(ExistingFiles,Files);

      RemovedFileList := "";
      _str ActionName;
      if (read_only) {
         ActionName='get';
      }else{
         ActionName='checkout';
      }
      GetRemovedFileList(OrigFiles,ExistingFiles,RemovedFileList);
      if (!Files._length()) {
         //All files were removed
         _message_box(nls("Cannot %s the following files:\n%s\n\nThese files may be checked out, or archives may not exist for these files",ActionName,RemovedFileList));
         return(1);
         //Display message 'The following files could not be checked out'
         //No continue message, return immediatley
      }
      if (RemovedFileList!='') {
         result=_message_box(nls("Cannot %s the following files:\n%s\nContinue?",ActionName,RemovedFileList),'',MB_YESNOCANCEL);
         if (result!=IDYES) {
            return(COMMAND_CANCELLED_RC);
         }
      }
      if (read_only) {
         status=_SccGet(Files);
         if (status && !IsHarvestSCC()) {
            _message_box(nls("Could not get files status=%s",status));
         }
      }else{
         status=_SccCheckout(Files,'');
         if (status && !IsHarvestSCC()) {
            _message_box(nls("Could not checkout files\n%s",vcget_message(status)));
         }
      }
      if (!status) {
         //Need to call edit_and_close_files
         temp_view_id := 0;
         int orig_view_id=_create_temp_view(temp_view_id);
         for (i=0;i<Files._length();++i) {
            insert_line(' 'Files[i]);
         }
         p_window_id=orig_view_id;
         if (edit_files) {
            edit_and_close_files(temp_view_id);
         }
         _delete_temp_view(temp_view_id);
      }
      return(status);
   }
   linenum=-1;
   typeless info="";
   if (!read_only) {
      info = VersionControlSettings.getCommand(vcs, VCCHECKOUT);
   }else{
      info = VersionControlSettings.getCommand(vcs, VCGET);
   }
   if (status||info=='') {
      return(status);
   }
   vcsproject := VersionControlSettings.getVCSProject(vcs);
   styleFlags := VersionControlSettings.getStyleFlags(vcs);
   vcsProjectStyle := VersionControlSettings.getVCSProjectStyleFromFlags(styleFlags);
   errorStyle := VersionControlSettings.getErrorCaptureStyleFromFlags(styleFlags);

   project_option := "";
   parse lowcase(vcsproject) with project_option ',';
   vcsproject=_ProjectGet_VCSProject(_ProjectHandle());
   vcsproject=MaybeStripLeadingVCSName(vcsproject);
   orig_cd := "";
   if (project_option=='dir') {
      orig_cd=getcwd();
      if (vcsproject!='') {
         status=chdir(vcsproject,1);
         if (status) {
            _message_box(nls("VCS Project is invalid directory"));
            return(1);
         }
      }
   }

   needVCSProject := VersionControlSettings.getVCSProjectRequired(vcs) && 
      vcsproject=='' && vcsProjectStyle != VCS_PROJ_SS_LOCATE_FILE;

   if (needVCSProject) {
      _message_box("The VCS Project must be set.  Use Check Out dialog box to set VCS Project.");
      return(1);
   }
   filespec=strip(filespec);
   filename := "";
   comment := "";
   command := "";
   line := "";
   typeless junk=0;
   filelist_view_id := 0;
   int orig_view_id = _create_temp_view(filelist_view_id);
   if (orig_view_id=='') return(1);
   if (substr(filespec,1,1)!='@') {
      for (;;) {
         filename=parse_file(filespec);
         if (filename=='') break;
         status=sslocate_project(info,filename,vcsProjectStyle,vcsproject,'');
         if (status) break;
         comment=_chr(0);
         command=_vcparse_command(vcs, info, filename, _project_name, vcsproject, comment,'',vcsProjectStyle);
         if (command == "") {
            status = COMMAND_CANCELLED_RC;
            break;
         }
         if (vcsProjectStyle == VCS_PROJ_SS_TREE && _ssxlat_dir(filename,vcsproject,vcsProjectStyle)=='') {
            status=1;
            line=nls('The file %s is not in or below the current project',filename);
            _vcappend_error_message(linenum,errors_view_id,errorStyle,line);
         } else {
            status=_vcshell(vcs,command,styleFlags,filename,junk,vcsproject);
            if (iswildcard(filename) || status ||
                styleFlags & VCS_ALWAYS_SHOW_OUTPUT) {
               _vcappend_errors(linenum,errors_view_id,errorStyle);
            }
            if (status!=FILE_NOT_FOUND_RC) {
               _vcpvcs_append_checkout(errors_view_id,styleFlags,filelist_view_id);
            }
            if (((styleFlags & VCS_PVCS_WILDCARDS) == 0) &&
                (iswildcard(filename) || !status)) {
               activate_window(filelist_view_id);
               _lbadd_item(absolute(filename));
            }
            if (status==FILE_NOT_FOUND_RC) {
               rest := "";
               parse command with filename rest;
               clear_message();
               _message_box(nls("Program '%s' not found",filename));
               break;
            }
         }
      }
   }else{
      temp_view_id := 0;
      junk_view_id := 0;
      status=_open_temp_view(strip(substr(filespec,2),'B','"'),temp_view_id,junk_view_id);
      if (status) {
         if (orig_cd!='') chdir(orig_cd,1);
         _delete_temp_view(filelist_view_id);
         return(status);
      }
      top();up();
      for (;;) {
         if (down()) break;
         get_line(filename);
         filename=strip(filename/*,'L'*/);
         if (filename=='') continue;
         filename=_maybe_quote_filename(absolute(filename));
         //if (!read_only) add_to_list(filename);
         status=sslocate_project(info,filename,vcsProjectStyle,vcsproject,'');
         if (status) break;
         comment='';
         command=_vcparse_command(vcs, info, filename, _project_name, vcsproject, comment,'',vcsProjectStyle);
         if (command == "") {
            status = COMMAND_CANCELLED_RC;
            break;
         }
         if (vcsProjectStyle == VCS_PROJ_SS_TREE && _ssxlat_dir(filename,vcsproject,vcsProjectStyle)=='') {
            status=1;
            line=nls('The file %s is not in or below the current project',filename);
            _vcappend_error_message(linenum,errors_view_id,errorStyle,line);
         } else {
            status=_vcshell(vcs,command,styleFlags,filename,junk,vcsproject);
            if (status || styleFlags & VCS_ALWAYS_SHOW_OUTPUT) {
               _vcappend_errors(linenum,errors_view_id,errorStyle);
            }
            if (status!=FILE_NOT_FOUND_RC) {
               _vcpvcs_append_checkout(errors_view_id,styleFlags,filelist_view_id);
            }
            if (status==FILE_NOT_FOUND_RC) {
               rest := "";
               parse command with filename rest;
               clear_message();
               _message_box(nls("Program '%s' not found",filename));
               break;
            }
         }
         
         if (!status && (styleFlags & VCS_PVCS_WILDCARDS) == 0) {
            activate_window(filelist_view_id);
            _lbadd_item(absolute(filename));
            activate_window(temp_view_id);
         }
      }
      _delete_temp_view(temp_view_id);
   }
   if (orig_cd!='') chdir(orig_cd,1);
   activate_window(orig_view_id);
   if (edit_files && status!=FILE_NOT_FOUND_RC) {
      edit_and_close_files(filelist_view_id);
      _delete_temp_view(filelist_view_id);
   }else{
      _delete_temp_view(filelist_view_id);
   }
   return(status);
}

void _retag_vc_buffers(_str filearray[])
{
   if (_workspace_filename=='') {
      return;
   }
   orig_use_timers := _use_timers;
   _use_timers=0;
   orig_wid := p_window_id;
   _MaybeRetagWorkspace(false);
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   more_than_50_files := (filearray._length() > 50);
   foreach (auto cur in filearray) {
      if (_WorkspaceFindFile(cur, _workspace_filename) == "") {
         continue;
      }
      if (cur=='') continue;
      insert_line(cur);
   }
   retag_occurrences := (def_references_options & VSREF_NO_WORKSPACE_REFS)==0;
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);

   tag_files := project_tags_filenamea();
   foreach (auto project_tagfile in tag_files) {
      RetagFilesInTagFile2(project_tagfile,
                           orig_view_id, temp_view_id,
                           force_create:false, 
                           rebuild_all:false, 
                           retag_occurrences,
                           doRemove:false, 
                           RemoveWithoutPrompting:false, 
                           useThread,
                           quiet: !more_than_50_files,
                           checkAllDates:true, 
                           doDeleteListView:false, 
                           allowCancel: !more_than_50_files,
                           skipFilesNotInTagFile:true,
                           KeepWithoutPrompting:true);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   p_window_id=orig_wid;
   _use_timers=orig_use_timers;
   _reset_idle();
}
void _reload_vc_buffers(_str filearray[])
{
   orig_use_timers := _use_timers;
   _use_timers=0;
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   foreach (auto cur in filearray) {
      if (cur=='') continue;
      insert_line(cur);
   }
   p_window_id=orig_view_id;
   edit_and_close_files(temp_view_id,true);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   _use_timers=orig_use_timers;
   _reset_idle();
}
bool _reload_buffer(_str filename, bool do_maybe_set_readonly=false) {
   file_already_loaded := buf_match(filename,1,'E')!='';
   if (file_already_loaded) {
      status := _open_temp_view(filename,auto tempWID,auto origWID,"+b",auto buffer_already_exists);
      if (status) {
         return true;
      }
      if (buffer_already_exists) {
         fileDate := (long)_file_date(filename,'B');
         _ReloadCurFile(p_window_id,fileDate,false);
         if (do_maybe_set_readonly && !p_readonly_set_by_user) {
            //will set buffer to what it is on disk, should be r/w
            maybe_set_readonly();
         }
      }
      _delete_temp_view(tempWID);
      p_window_id=origWID;
   }
   return file_already_loaded;
}

static void edit_and_close_filelist(_str filelist)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   for (;;) {
      _str cur=parse_file(filelist);
      if (cur=='') break;
      insert_line(' 'cur);
   }
   p_window_id=orig_view_id;
   edit_and_close_files(temp_view_id);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
}

static void edit_and_close_files(int filelist_view_id,bool reload_only=false)
{
   orig_view_id := p_window_id;
   p_window_id=filelist_view_id;
   top();up();
   new_view_id := 0;
   filename := "";
   qfilename := "";
   for (;;) {
      if (down()) {
         break;
      }
      get_line(filename);
      filename=strip(filename/*,'L'*/);
      if (filename=='') continue;
      filename=absolute(filename);
      p_window_id=orig_view_id;
      filename=strip(filename);
      qfilename=_maybe_quote_filename(filename);
      if (file_match('-p 'qfilename,1)!='') {
         file_already_loaded:=_reload_buffer(filename,true);
         if (file_already_loaded) {
         } else if ( !reload_only ){
            if (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW) {
               edit(qfilename);
               if (def_one_file!='') new_view_id=p_window_id;
            }
         }
#if 0 //11:42am 4/3/2014
         // This code used to try to close the buffer from memory if the file 
         // was deleted from disk.  It didn't do it right, calling 
         // _delete_buffer is not the right way to do this, so the code was 
         // never good.  Nothing deletes the file on disk on checkins anymore
         // so just let this go.
      } else {
         parse buf_match(filename,1,'VE') with buf_id .;
         status := _open_temp_view(qfilename,auto tempWID,auto origWID,"+bi "buf_id);
         if ( !status ) {
            if ( !p_modify ) {
               _delete_buffer();
            }
            _delete_temp_view(tempWID);
         }
         p_window_id = orig_view_id;
#endif
      }
      p_window_id=filelist_view_id;
   }
   if (new_view_id) {
      p_window_id=new_view_id;
   }else{
      p_window_id=orig_view_id;
   }
}

static handle_error(_str vcs, typeless error_code, _str filename, typeless checking_in, typeless create_new_archives)
{
   filename=strip(filename,'B','"');
   switch (lowcase(vcs)) {
   case 'tlib for dos':
   case 'tlib for os/2':
      if (checking_in) {
         switch (error_code) {
         case 1:
            if (!create_new_archives) {
               _message_box(nls("%s could not be checked in.\n\nYou may need to create an archive file for it first.",filename));
            }else{
               _message_box(nls("%s could not be created.\n\nAn archive file may already exist for this file."),filename);
            }
            break;
         }
      }else{
         switch (error_code) {
         case 1:
            _message_box(nls("%s could not be checked out.\n\nYou may wish to be sure that an archive exists for %s.",filename, filename));
            break;
         }
      }
      break;
   case 'source safe for dos':
   case 'source safe for os/2':
      if (checking_in) {
         switch (error_code) {
         case 1:
         case 100:
            if (!create_new_archives) {
               _message_box(nls("%s could not be checked in.\n\nYou may need to create an archive file for it first.",filename));
            }else{
               /* Actually Source safe returns 0 if you try to create a checked
                  in module, but I put this in for completeness in case they change
                  it. */
               _message_box(nls("%s could not be created.\n\nAn archive file may already exist for this file.",filename));
            }
            break;
         }
      }else{
         switch (error_code) {
         case 1:
         case 100:
            _message_box(nls("%s could not be checked out.\n\nYou may wish to be sure that an archive exists for %s.",filename, filename));
            break;
         }
      }
      break;
   }
}

static build_view_of_selected(var temp_view_id)
{
   if (p_Nofselected<1) {
      return(1);
   }
   int orig_view_id=_create_temp_view(temp_view_id);
   activate_window(orig_view_id);
   ff := true;
   for (;;) {
      typeless status=_lbfind_selected(ff);
      if (status) {
         break;
      }
      _str text=_lbget_text();
      activate_window(temp_view_id);
      insert_line(text);
      activate_window(orig_view_id);
      ff=false;
   }
}

defeventtab _vc_auto_inout_form;

_yes.on_create(_str msg="", typeless read_only_caption="", bool showCancelButton=true)
{
   // resize the form height based on the new message
   int oldheight=_message.p_height;
   _message.p_caption=msg;
   int diff=_message.p_height-oldheight;

   // move all the controls as necessary
   _read_only.p_y+=diff;
   _yes.p_y+=diff;
   _no.p_y+=diff;
   command3.p_y+=diff;

   // set the checkbox caption, hide if blank
   _read_only.p_auto_size = true;
   _read_only.p_caption=read_only_caption;
   if ( _read_only.p_caption=="" ) {
      _read_only.p_visible = false;
   } 

   // make sure we are wide enough
   int label_width=max(_message.p_width, _read_only.p_width);
   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   if (label_width+(2 * _message.p_x) > client_width) {
      p_active_form.p_width+=(label_width+(2 * _message.p_x))-client_width;
   }
   p_active_form.p_height+=diff;
   // _read_only.p_caption="Discard Changes";
   // msg=nls("Do you wish to save and check in the file %s?",str, arg(1));

   if (!showCancelButton) {
      command3.p_visible = false;
      diff = command3.p_x - _no.p_x;
      _no.p_x += diff;
      _yes.p_x += diff;
   }
}

void _vc_auto_inout_form.on_resize()
{
   // keep the buttons in the corner
   padding := _message.p_x;
   xDiff := p_width - (command3.p_x_extent + padding);
   command3.p_x += xDiff;
   _no.p_x += xDiff;
   _yes.p_x += xDiff;
}

_yes.lbutton_up()
{
   _param1=_read_only.p_value;
   _param2=1;   // Save the file
   p_active_form._delete_window(IDYES);
}

_no.lbutton_up()
{
   _param1=_read_only.p_value;
   p_active_form._delete_window(IDNO);
}

static const CHECKOUT=      1;
static const GET=           2;
static const SET_WRITEABLE= 3;
static const SAVE_AS=       4;

static const ENABLE_CHECKOUT=      0x1;
static const ENABLE_GET=           0x2;
static const ENABLE_SET_WRITEABLE= 0x4;
static const ENABLE_SAVE_AS=       0x8;

static int window_edit2(_str filename)
{
   typeless status=edit_file('+BL 'filename);
   if (! status) {
      int was_hidden=p_buf_flags&VSBUFFLAG_HIDDEN;
      p_buf_flags &= ~(VSBUFFLAG_HIDDEN|VSBUFFLAG_DELETE_BUFFER_ON_CLOSE);
      if (was_hidden) {
         call_list('_cbmdibuffer_unhidden_');
      }
   }
   return(status);
}
/**
 * This function is intended to be used by the developers of Visual
 * SlickEdit only.  Opens <i>filename</i> for editing.  Checks out
 * <i>filename</i> from the version control system if Auto Check Out is
 * on and the file does not exist or is read only.
 *
 * Don't use edit or window_edit to create a hidden buffer or
 * it might get added to the project tab buffer list.
 *
 * @return Returns 0 if successful.  Common return codes are NEW_FILE_RC
 * (empty buffer created with filename specified because file did not
 * exist), PATH_NOT_FOUND_RC, TOO_MANY_WINDOWS_RC,
 * TOO_MANY_FILES_RC, TOO_MANY_SELECTIONS_RC,
 * NOT_ENOUGH_MEMORY_RC.  On error, message is displayed.
 *
 * @appliesTo Edit_Window
 *
 * @categories Window_Functions
 *
 */
_str window_edit(_str filename, int a2_flags)
{
   // NOTE:  This code doesn't actually do anything.
   //
   // The automatic checkout code now happens in _readonly_error()
   // The idea is that the editor should not checkout files until
   // it is attempting to modify the file, never when they just edit
   // the file.
   //
   do_auto_check := (def_vcflags&VCF_AUTO_CHECKOUT) && (isinteger(a2_flags) && (a2_flags & VCF_AUTO_CHECKOUT));
   jname := just_name(filename);
  /* tiled edit is the default of load_files so nothing need be done. */
   if (do_auto_check && _FileQType(jname)==VSFILETYPE_NORMAL_FILE) {
      //file_already_loaded=buf_match(absolute(just_name(filename)),1,'E')!='';
      block_was_read(0);
      attrs := "";
      if (jname=='') {
         attrs='x';
      } else {
         attrs=file_list_field(jname,DIR_ATTR_COL,DIR_ATTR_WIDTH);
      }
      isreadonly := false;
      if (_isUnix()) {
         // Could limit check to user write access.
         // A better check would check write access by attempting to open the file read/write
         // and in case we are root, check for no write access.
         isreadonly=!pos('w',attrs);
      } else {
         isreadonly=pos('R',attrs)!=0;
      }
      int LoadingBuffer=pos('\+b( |i)',filename,1,'ir');
      //Don't want to get the +bp option by accident!!!!
      if((_ispvcs_library(filename) || attrs==''/* || isreadonly*/) &&
         !LoadingBuffer) {
         typeless status=0;
         b1 := b2 := b3 := "";//Captions for radio buttons
         msg := "";
         if (_ispvcs_library(filename)) {
            msg=nls("'%s' is a PVCS archive file.",jname);
            b3='&Open as is';
         } else if(attrs=='') {
            msg=nls("'%s' does not exist.",jname);
            b3='&Create the file';
         } else {
            msg=nls("'%s' is read only.",jname);
         }
         typeless result=show('-modal _vc_checkout_form',msg,b1,b2,b3);
         if (result=='') {
            return(COMMAND_CANCELLED_RC);
         }else if (result==CHECKOUT) {
            vccheckout(jname);
         }else if (result==GET) {
            vcget(jname);
         }else if (result==SET_WRITEABLE) {
            if (b3=='&Create the file') {
               status=window_edit2(filename);
            }else if (b3=='&Open as is') {
               status=edit_file(filename);
            }else{
               if (_isUnix()) {
                  chmod('u+w '_maybe_quote_filename(jname));
               } else {
                  chmod('-r '_maybe_quote_filename(jname));
               }
            }
         }
         return(status);
      }
   }
   typeless status=window_edit2(filename);
   return(status);
}
bool _ispvcs_library(_str filename)
{
   filename=strip(filename,'B','"');
   _str ext=_get_extension(filename);
   if (_file_eq(substr(ext,3,1),'v') &&
       !_file_eq(ext,'java')) {

      // Check for PVCS file
      vcs := svc_get_vc_system();
      return VersionControlSettings.getUsePVCSWildcards(vcs);
   }
   return(false);
}

static just_name(_str filename)
{
   for (;;) {
      _str name=parse_file(filename);

      if (filename=='') {
         return('');
      }
      first_ch := substr(filename,1,1);
      //This is Shawn's fix for a version control problem if you have
      //def_winpos_override set.
      if (first_ch!='-' && first_ch!='+') return(filename);
      if (lowcase(substr(filename,2,2)=='i:')) {
         int i;
         for (i=0;i<6;++i) parse_file(filename);
      }
   }
}
_vcs_project_get_section(typeless projectName="")
{
   if (_project_name=='') {
      return("VCS");
   }
   return(projectName);
}
static int _isrcs(_str SectionName)
{
   return (pos(' RCS ',' 'SectionName' '));
}


#region Options Dialog Helper Functions

defeventtab _vc_select_form;

static const VC_SELECTED_NONE_STRING = '[NONE]';

static const VC_SCOPE_DEFAULT_STRING = 'Default';
static const VC_SCOPE_WORKSPACE_STRING='Workspace';
static const VC_SCOPE_PROJECT_STRING  ='Project';

void ctlscope_combo.on_change(int reason)
{
   if ( _GetDialogInfoHt("inSetCurrentItemInScopeCombo")==1 ) return;
   systemsForAllScopes := _GetDialogInfoHt("systemsForAllScopes");
   lastScope := _GetDialogInfoHt("lastScope");
   cl_systems_text := ctlcl_systems._lbget_text();
   if ( cl_systems_text==VC_SELECTED_NONE_STRING ) {
      cl_systems_text = "";
   }
   systemsForAllScopes:[lastScope] = cl_systems_text;

   systemForCurrentScope := systemsForAllScopes:[p_text];

   if ( systemForCurrentScope!=null ) {
      setCLSystem(systemForCurrentScope);
   }

   _SetDialogInfoHt("systemsForAllScopes",systemsForAllScopes);
   _SetDialogInfoHt("lastScope",p_text);
}

void _vc_select_form_init_for_options(_str arguments = '')
{
   _str type='',
        system='',
        localpath='',
        project='';
   for (;;) {
      cur := lowcase(substr(parse_file(arguments),2));
      if (cur=='') {
         break;
      }
      if (cur=='type') {
         type=parse_file(arguments);
      } else if (cur=='system') {
         system=parse_file(arguments);
      } else if (cur=='localpath') {
         localpath=parse_file(arguments);
      } else if (cur=='project') {
         project=arguments;
         break;
      }
   }

   ctlok.p_visible = false;
   ctlcancel.p_visible = false;
   ctlhelp.p_visible = false;

   // do this so the right checkboxes are displayed
   if (ctl_cl_frame.p_value) {
      ctlcl_systems.call_event(1, ctlcl_systems, ON_CHANGE, 'W');
   } else {
      ctlscc_systems.call_event(1, ctlscc_systems, ON_CHANGE, 'W');
   }
}

static _str getCheckedFrame()
{
   checkedFrame := "";
   if ( ctl_cl_frame.p_value ) {
      checkedFrame = "ctl_cl_frame";
   } else if ( ctlscc_frame.p_value ) {
      checkedFrame = "ctlscc_frame.p_value";
   }
   return checkedFrame;
}

void _vc_select_form_save_settings()
{
   ctlscope_combo.call_event(CHANGE_SELECTED,ctlscope_combo,ON_CHANGE,'W');
   systemsForAllScopes := _GetDialogInfoHt("systemsForAllScopes");
   _SetDialogInfoHt("origSystemsForAllScopes",systemsForAllScopes);
   _SetDialogInfoHt("_auto_checkout.p_value",_auto_checkout.p_value);
   _SetDialogInfoHt("_set_read_only_checkin.p_value",_set_read_only_checkin.p_value);
   _SetDialogInfoHt("ctlprompt.p_value",ctlprompt.p_value);
   _SetDialogInfoHt("ctlauto_detect.p_value",ctlauto_detect.p_value);
   _SetDialogInfoHt("ctlprompt_to_add.p_value",ctlprompt_to_add.p_value);
   _SetDialogInfoHt("ctlprompt_to_remove.p_value",ctlprompt_to_remove.p_value);

   _SetDialogInfoHt("checkedFrame",getCheckedFrame());
}

bool _vc_select_form_is_modified()
{
   if ( getCheckedFrame()!=_GetDialogInfoHt("checkedFrame") ) return true;

   ctlscope_combo.call_event(CHANGE_SELECTED,ctlscope_combo,ON_CHANGE,'W');
   systemsForAllScopes := _GetDialogInfoHt("systemsForAllScopes");
   origSystemsForAllScopes := _GetDialogInfoHt("origSystemsForAllScopes");
   systemsMatch := systemsForAllScopes == origSystemsForAllScopes;
   if ( !systemsMatch ) {
      //say('_vc_select_form_is_modified !systemsMatch');
      //_dump_var(systemsForAllScopes,'systemsForAllScopes');
      //_dump_var(origSystemsForAllScopes,'origSystemsForAllScopes');
      return true;
   }

   orig_auto_checkout_p_value := _GetDialogInfoHt("_auto_checkout.p_value");
   if ( orig_auto_checkout_p_value!=_auto_checkout.p_value  ) {
      return true;
   }

   orig_set_read_only_checkin_p_value := _GetDialogInfoHt("_set_read_only_checkin.p_value");
   if ( orig_set_read_only_checkin_p_value!=_set_read_only_checkin.p_value ) {
      return true;
   }

   orig_ctlprompt_p_value := _GetDialogInfoHt("ctlprompt.p_value");
   if ( orig_ctlprompt_p_value!=ctlprompt.p_value ) {
      return true;
   }

   orig_ctlauto_delect_p_value := _GetDialogInfoHt("ctlauto_detect.p_value");
   if ( orig_ctlauto_delect_p_value!=ctlauto_detect.p_value ) {
      return true;
   }
   orig_ctlprompt_to_add_p_value := _GetDialogInfoHt("ctlprompt_to_add.p_value");
   if ( orig_ctlprompt_to_add_p_value!=ctlprompt_to_add.p_value ) {
      return true;
   }
   orig_ctlprompt_to_remove_p_value := _GetDialogInfoHt("ctlprompt_to_remove.p_value");
   if ( orig_ctlprompt_to_remove_p_value!=ctlprompt_to_remove.p_value ) {
      return true;
   }
   return false;
}

void _vc_select_form_apply()
{
   if (!_haveVersionControl()) {
      return;
   }
   typeless status=0;
   _str olddef_vc_system=svc_get_vc_system();
   was_scc := _SCCProjectIsOpen() || _isscc();
   if (ctl_cl_frame.p_value) {
      if ( was_scc ) {
         _SccCloseProject();
      }
      // Have to do this to save ctlscope_combo's setting in systemsForAllScopes
      ctlscope_combo.call_event(CHANGE_SELECTED,ctlscope_combo,ON_CHANGE,'W');

      systemsForAllScopes := _GetDialogInfoHt("systemsForAllScopes");
      origSystemsForAllScopes := _GetDialogInfoHt("origSystemsForAllScopes");

      // get the systemsForAllScopes (current from dialog) and 
      // origSystemsForAllScopes which is what it was when we loaded the dialog
      // 
      // if default scope vcs changed, set def_vc_system, and set CFGMODIFY_DEFVAR
      if ( systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING]!=origSystemsForAllScopes:[VC_SCOPE_DEFAULT_STRING] ) {
         def_vc_system = systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING];
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }

      // If the vcs for the workspace changed, set that in .vpw file.  Don't 
      // have to worry  about _config_modify_flags
      if ( _workspace_filename!="" &&
           systemsForAllScopes:[VC_SCOPE_WORKSPACE_STRING]!=origSystemsForAllScopes:[VC_SCOPE_WORKSPACE_STRING] ) {
         status = _WorkspaceSet_VCSProject(gWorkspaceHandle,systemsForAllScopes:[VC_SCOPE_WORKSPACE_STRING]);
         if ( status>=0 ) {
            _WorkspaceSave(gWorkspaceHandle);
         }
      }
      // If the vcs for the workspace changed, set that in .vpj file.  Don't 
      // have to worry  about _config_modify_flags
      if ( _project_name!="" &&
           (systemsForAllScopes:[VC_SCOPE_PROJECT_STRING]!=origSystemsForAllScopes:[VC_SCOPE_PROJECT_STRING] || was_scc) ) {
         _ProjectSet_VCSProject(_ProjectHandle(),systemsForAllScopes:[VC_SCOPE_PROJECT_STRING]':');
         _ProjectSave(_ProjectHandle());
      }
   }else if (ctlscc_frame.p_value){
      _SetVCSystemName(SCC_PREFIX:+ctlscc_systems._lbget_text());
   }else{
      if (machine()=='WINDOWS' && _haveVersionControl() && _SccGetCurProjectInfo(VSSCC_PROJECT_NAME)!='' ) {
         _SccCloseProject();
      }
      _SetVCSystemName('');
      if (_project_name!="") {
         _ProjectSet_VCSProject(_ProjectHandle(),'');
         SetVCSLocalPath(_ProjectHandle(),"","");
         status=_ProjectSave(_ProjectHandle());
         if (status) {
            _message_box(nls("Could not write version control information to project file %s1.\n\n%s2\n\nThis version control project will probably not be properly linked with the current SlickEdit project.",_project_name,get_message(status)));
         }
         _WorkspacePutProjectDate();
      }
   }
   vcGetList(gvcEnableList);
   if (machine()=='WINDOWS' && _haveVersionControl() && was_scc &&
       _SccGetCurProjectInfo(VSSCC_PROJECT_NAME)!=ctlok.p_user) {
      toolbarUpdateFilterList(_project_name);
   }
   detectedSystem := svc_get_vc_system();
   if ( (!_isscc(detectedSystem)  || machine()!='WINDOWS') &&
        detectedSystem!='') {
      VerifyVCSExecutables();
   }
   int oldflags=def_vcflags;
   if (_auto_checkout.p_value) {
      def_vcflags|=VCF_AUTO_CHECKOUT;
   }else{
      def_vcflags&=~VCF_AUTO_CHECKOUT;
   }
   if (_auto_checkin.p_value) {
      def_vcflags|=VCF_EXIT_CHECKIN;
   }else{
      def_vcflags&=~VCF_EXIT_CHECKIN;
   }
   if (_set_read_only_checkin.p_enabled && _set_read_only_checkin.p_value) {
      def_vcflags|=VCF_SET_READ_ONLY;
   }else{
      def_vcflags&=~VCF_SET_READ_ONLY;
   }
   if (ctlprompt_to_add.p_enabled && ctlprompt_to_add.p_value) {
      def_vcflags|=VCF_PROMPT_TO_ADD_NEW_FILES;
   }else{
      def_vcflags&=~VCF_PROMPT_TO_ADD_NEW_FILES;
   }
   if (ctlprompt_to_remove.p_enabled && ctlprompt_to_remove.p_value) {
      def_vcflags|=VCF_PROMPT_TO_REMOVE_DELETED_FILES;
   }else{
      def_vcflags&=~VCF_PROMPT_TO_REMOVE_DELETED_FILES;
   }
   if (oldflags!=def_vcflags) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }                             
   if ( ctlprompt.p_value ) {
      def_vc_advanced_options&=~VC_ADVANCED_NO_PROMPT;
   }else{
      def_vc_advanced_options|=VC_ADVANCED_NO_PROMPT;
   }
   if ( ctlauto_detect.p_value ) {
      def_svc_auto_detect = 1;
   }else{
      def_svc_auto_detect = 0;
   }
}

#endregion Options Dialog Helper Functions


void ctlcl_systems.on_change(int reason)
{
   provName := _lbget_text();
   uline := upcase(provName);
   if ( _VCIsSpecializedSystem(uline) ) {
      ctlprompt.p_visible=false;
   }else{
      ctlprompt.p_visible=true;
   }

   // enable and disable the delete button depending on 
   // what we're looking at
   provID := VersionControlSettings.getProviderID(provName);
   if (provID == '') {
      ctlsetup.p_enabled = ctlcopy.p_enabled = ctldelete.p_enabled = ctlrename.p_enabled = false;
   } else {
      ctlsetup.p_enabled = ctlcopy.p_enabled = true;
      ctldelete.p_enabled = ctlrename.p_enabled = !VersionControlSettings.isSystemProvider(provID);
   }
}

void ctl_cl_frame.lbutton_up()
{
   ctlscc_frame.p_value=0;
   cur_frame_val := p_value!=0;
   other_frame_val := ctlscc_frame.p_value!=0;

   if (!ctlcl_systems.p_Nofselected) {
      ctlcl_systems._lbselect_line();
   }
   ctlscope_combo.p_enabled = true;
   if (machine()=='WINDOWS') {
      ctlscc_systems.call_event(CHANGE_SELECTED,ctlscc_systems,ON_CHANGE,'W') ;
   }
   ctlcl_systems.call_event(CHANGE_SELECTED,ctlcl_systems,ON_CHANGE,'W');
}

void ctlscc_frame.lbutton_up()
{
   ctl_cl_frame.p_value=0;
   cur_frame_val := p_value!=0;
   other_frame_val := ctl_cl_frame.p_value!=0;
   if (!ctlscc_systems.p_Nofselected) {
      ctlscc_systems._lbselect_line();
   }
   ctlscope_combo.p_text = VC_SCOPE_PROJECT_STRING;
   ctlscope_combo.p_enabled = false;
   if (machine()=='WINDOWS') {
      ctlscc_systems.call_event(CHANGE_SELECTED,ctlscc_systems,ON_CHANGE,'W') ;
   }
   ctlprompt.p_visible=true;
}

static _str MaybeNone(_str Caption)
{
   return( (Caption==''?'NONE':Caption) );
}

static int GetNumLinesInLabel(_str string)
{
   count := 1;
   p := 0;
   for (;;) {
      p=pos("\n",string,p+1);
      if (!p) return(count);
      ++count;
   }
}

static const SIMULATE_NON_NT= 0;

void _vc_select_form.on_load()
{
   if (ctl_cl_frame.p_value) {
      ctl_cl_frame._set_focus();
   }else if (ctlscc_frame.p_value) {
      ctlscc_frame._set_focus();
   }
}

void ctlok.on_create(_str type='',_str system='',_str localpath='',_str project='')
{
   initVCSetup(type,system,localpath,project);
}

void _vc_select_form.on_resize()
{
   pad := ctlscope_combo.p_y;
   ctl_cl_frame.p_y = ctlscope_combo.p_y_extent+pad;
   heightDiff := p_height - (ctlprompt_to_remove.p_y_extent + pad);

   _auto_checkout.p_y += heightDiff;
   _set_read_only_checkin.p_y = ctlprompt.p_y = _auto_checkout.p_y;
   ctlprompt_to_add.p_y = ctlauto_detect.p_y = _auto_checkout.p_y_extent + pad;
   ctlprompt_to_remove.p_y = ctlprompt_to_add.p_y_extent + pad;

   if (ctlscc_frame.p_visible) {
      heightDiff = heightDiff intdiv 2;
      ctlscc_frame.p_y += heightDiff;
      ctlscc_frame.p_height += heightDiff;
      ctlscc_systems.p_height += heightDiff;
      label6.p_y += heightDiff;
      ctlscc_projname.p_y += heightDiff;
   }

   ctl_cl_frame.p_height += heightDiff;
   ctlcl_systems.p_height += heightDiff;
}

static _str getSpelledNumber(int num32BitSystems)
{
   switch ( num32BitSystems ) {
   case 1:
      return "One";
   case 2:
      return "Two";
   case 3:
      return "Three";
   case 4:
      return "Four";
   default:
      return num32BitSystems;
   }
}

static void display64BitMessage(int num32BitSystems)
{
   ctlscc_frame.p_enabled = false;
   ctlscc_systems.p_visible = false;
   ctlscc_systems.p_prev.p_visible = false;
   ctlscc_init.p_visible = false;
   ctlscc_advanced.p_visible = false;
   ctlscc_open_project.p_visible = false;
   ctlscc_projname.p_prev.p_visible = false;

   num32BitSystemsStr := getSpelledNumber(num32BitSystems);
   msg := get_message(VSSCC_WARN_ABOUT_32_BIT_SCC_SYSTEMS_RC,num32BitSystemsStr);
   ctlscc_projname.p_word_wrap = true;
   ctlscc_projname.p_caption = msg;
   ctlscc_projname.p_x = ctlscc_systems.p_prev.p_x;
   ctlscc_projname.p_y = p_y =ctlscc_systems.p_prev.p_y;
   ctlscc_projname.p_x_extent = ctlscc_projname.p_parent.p_width ;
}

static void fillInScopeCombo()
{
   _lbadd_item(VC_SCOPE_DEFAULT_STRING);
   if ( _workspace_filename!="" ) {
      _lbadd_item(VC_SCOPE_WORKSPACE_STRING);
      if ( _project_name!="" ) {
         _lbadd_item(VC_SCOPE_PROJECT_STRING);
      }
   }
}

static bool setCurrentScopeAndCLSystem(_str scope,_str vcsproject)
{
   _SetDialogInfoHt("inSetCurrentItemInScopeCombo",1);
   setSystem := false;
   status := ctlscope_combo._lbsearch(scope);
   if (!status) {
      p_text = _lbget_text();
      _SetDialogInfoHt("lastScope",p_text);
      status = ctlcl_systems._lbsearch(vcsproject);
      if ( !status ) {
         setSystem = true;
         ctlcl_systems._lbselect_line();
      }
   }

   _SetDialogInfoHt("inSetCurrentItemInScopeCombo",0);
   return setSystem;
}

static void setCLSystem(_str vcsproject)
{
   setSystem := false;
   _SetDialogInfoHt("lastScope",p_text);

   origWID := p_window_id;
   p_window_id = ctlcl_systems;
   status := _lbsearch(vcsproject);
   if ( !status ) {
      setSystem = true;
      _lbselect_line();
   }
   p_window_id = origWID;
}

static void initAllSystemScopes(STRHASHTAB &systemsForAllScopes)
{
   systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING] = "";
   systemsForAllScopes:[VC_SCOPE_WORKSPACE_STRING] = "";
   systemsForAllScopes:[VC_SCOPE_PROJECT_STRING] = "";
}

static _str getCurrentVCForAllScopes(_str &scope)
{
   STRHASHTAB systemsForAllScopes;
   initAllSystemScopes(systemsForAllScopes);
   vcs := _GetVCSystemName();
   scope = VC_SCOPE_DEFAULT_STRING;
   systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING] = vcs;
   maybeGetVCFromWorkspace(auto handledInWkspace=false,auto vcswkspace="",false);
   if ( vcswkspace !="" ) {
      // 4/19/2017 11:52:52 AM
      // The colons on here are a throwback to when there was version control 
      // project information that would be after the colon.  Not SlickEdit 
      // project information, stuff that was  specific to the version control 
      // system (source safe was the only  command line system taht used this, 
      // most if not all SCC system had  something, but it was proprietary and 
      // you couldn't tell what it was,  you justpassed it in.  
      // Long story short: strip the colon.
      _maybe_strip(vcswkspace,':');
      vcs = vcswkspace;
      scope = VC_SCOPE_WORKSPACE_STRING;
      systemsForAllScopes:[VC_SCOPE_WORKSPACE_STRING] = vcswkspace;
   }
   vcsproject := _ProjectGet_VCSProject(_ProjectHandle());
   if ( vcsproject !="" ) {
      // See comment above
      _maybe_strip(vcsproject,':');
      vcs = vcsproject;
      scope = VC_SCOPE_PROJECT_STRING;
      systemsForAllScopes:[VC_SCOPE_PROJECT_STRING] = vcsproject;
   }
   if ( _isscc(systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING]) && (vcsproject!="" || vcswkspace!="") ) {
      // Can't have SCC AND something set in project or workspace
      systemsForAllScopes:[VC_SCOPE_DEFAULT_STRING] = "";
      _SetVCSystemName("",false);
   }
   _SetDialogInfoHt("systemsForAllScopes",systemsForAllScopes);
   return vcs;
}

static void initVCSetup(_str type='',_str system='',_str localpath='',_str project='')
{
   if (!_haveVersionControl()) {
      return;
   }
   refreshCLSystemList();
   typeless status=0;
   wid := 0;
   line := "";

   if (machine()=='WINDOWS' && _haveVersionControl()) {
      wid=p_window_id;
      p_window_id=ctlscc_systems;
      _SccListProviders();
      if ( ctlscc_systems.p_Noflines ) {
         _lbsort();
         _lbtop();
      } else {
         if ( machine_bits()==64 ) {
            // If no SCC systems were listed AND this is a 64-bit version of 
            // SlickEdit, check to see if there are 32-bit systems installed.  
            // If there are, display a message explaining the user might want 
            // to use the 32-bit version of SlickEdit so they can use their 
            // SCC provider.
            num32BitSystems := _SccGetNumberOf32BitSystems();
            if ( num32BitSystems>0 ) {
               _SetDialogInfoHt("64BitMessage",1);
               display64BitMessage(num32BitSystems);
               p_window_id = wid;

               // If we are in this odd error state, and the current system was
               // an SCCsystem, just bail here.
               if ( _isscc() ) return;
            }
         }
      }
      p_window_id=wid;
   }

   // 4/17/2017 12:34:27 PM
   // Now need "NONE" on Windows
   ctlcl_systems._lbtop();
   ctlcl_systems._lbup();
   ctlcl_systems._lbadd_item(VC_SELECTED_NONE_STRING);

   ctlscope_combo.fillInScopeCombo();
   vcs := getCurrentVCForAllScopes(auto scope="");
   setCLSystem := ctlscope_combo.setCurrentScopeAndCLSystem(scope,vcs);
   systemsForAllScopes := _GetDialogInfoHt("systemsForAllScopes");

   //_str vcs=_ProjectGet_VCSProject(_ProjectHandle());
   /*if (machine()=='WINDOWS' && _haveVersionControl() && vcs=='' &&!SIMULATE_NON_NT) {
      if (ctlscc_systems.p_Noflines) {
         ctlscc_systems._lbtop();
         ctlscc_systems._lbselect_line();
         ctlscc_projname.p_caption=MaybeNone(_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
      }
   }else */
   if (machine()=='WINDOWS' && _haveVersionControl() && _isscc(vcs)  &&!SIMULATE_NON_NT) {
      // 4/19/2017 12:27:58 PM
      // Strip the "scc:" off of the beginning
      vcs=substr(vcs,5);
      ctlscc_frame.p_value=1;
      ctlscc_frame.call_event(ctlscc_frame,LBUTTON_UP);
      ctlscc_systems._lbsearch(vcs);
      ctlscc_systems._lbselect_line();
      _str projname=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME);
      ctlscc_projname.p_caption=MaybeNone(projname);
      if (projname!='') {
         ctlscc_open_project.p_caption='Close Project';
      }
   }else{
      if ( vcs!="" && _isscc(vcs) ) {
         ctlscc_frame.p_value=1;
         ctlscc_frame.call_event(ctlscc_frame,LBUTTON_UP);
      }else if ( vcs!="" ) {
         ctl_cl_frame.p_value=1;
         ctl_cl_frame.call_event(ctl_cl_frame,LBUTTON_UP);
         ctlcl_systems._lbtop();
         status=ctlcl_systems._lbsearch(vcs);
         if (!status) {
            ctlcl_systems._lbselect_line();
         }
      }
   }
   if (!ctlscc_systems.p_Noflines || SIMULATE_NON_NT) {
      //ctlcl_enabled.call_event(ctlcl_enabled,LBUTTON_UP);
      if (!ctlcl_systems.p_Noflines) {
         ctlcl_systems._lbtop();
         ctlcl_systems._lbselect_line();
      }
      ctlscc_frame.p_enabled=false;
      ctl_cl_frame.p_value=1;
   }
   _auto_checkout.p_value=def_vcflags&VCF_AUTO_CHECKOUT;
   _auto_checkin.p_value=def_vcflags&VCF_EXIT_CHECKIN;
   _set_read_only_checkin.p_value=def_vcflags&VCF_SET_READ_ONLY;
   if (machine()=='WINDOWS') {
      ctlscc_systems.call_event(CHANGE_SELECTED,ctlscc_systems,ON_CHANGE,'W') ;
   }
   //SetLabel();
   if (machine()!='WINDOWS'||SIMULATE_NON_NT) {
      //If we can't use the scc stuff, hide it
      ctlscc_frame.p_visible=false;
      int diff=_auto_checkout.p_y - ctlscc_frame.p_y;//_auto_checkout.p_y-frame1.p_y;

      _auto_checkout.p_y=_set_read_only_checkin.p_y=ctlscc_frame.p_y;
      ctlok.p_y-=diff;
      ctlcancel.p_y-=diff;
      ctlhelp.p_y-=diff;
      ctlprompt.p_y-=diff;

      p_active_form.p_height-=diff;

      // it's the only thing left, so get rid of the checkbox
      ctl_cl_frame.p_checkable=false;
      if (vcs!='') {
         ctl_cl_frame.call_event(ctl_cl_frame,LBUTTON_UP);
      }
//    ctl_cl_frame.p_y=-500;
      ctl_cl_frame.p_value = 1;
   }
   if (machine()=='WINDOWS' && _haveVersionControl()) {
      ctlok.p_user=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME);
   }
   if (vcs=='' && ctlscc_frame.p_visible) {
      //If there is not a version control system, make sure this stuff
      //gets disabled
      ctl_cl_frame.call_event(ctl_cl_frame,LBUTTON_UP);
      ctlscc_frame.call_event(ctlscc_frame,LBUTTON_UP);
   }
   ctlprompt.p_value=(int)!(def_vc_advanced_options&VC_ADVANCED_NO_PROMPT);
   ctlauto_detect.p_value=(int)def_svc_auto_detect;

   ctlauto_detect.p_value=(int)def_svc_auto_detect;

   ctlprompt_to_add.p_value=def_vcflags&VCF_PROMPT_TO_ADD_NEW_FILES;
   ctlprompt_to_remove.p_value=def_vcflags&VCF_PROMPT_TO_REMOVE_DELETED_FILES;
}

/**
 * Refreshes the list of command line systems on the 
 * _vc_select_form.  Optionally selects one of the values. 
 * 
 * @param selection        the list item to select
 */
static void refreshCLSystemList(_str selection = '')
{
   ctlcl_systems._lbclear();

   bool clList:[];
   VersionControlSettings.getCommandLineProviderList(clList);
   foreach (auto provName => auto systemProv in clList) {
      if (systemProv) ctlcl_systems._lbadd_item(provName, 60, _pic_lbvs);
      else ctlcl_systems._lbadd_item(provName, 60);
   }

   ctlcl_systems.p_picture = _pic_lbvs;
   ctlcl_systems.p_pic_space_y = 60;
   ctlcl_systems.p_pic_point_scale = 8;

   ctlcl_systems._lbsort();

   ctlcl_systems._lbtop();

   if (selection != '') {
      ctlcl_systems._lbsearch(selection);
   }
   ctlcl_systems._lbselect_line();
}

_exit_vc()
{
   if (_haveVersionControl() &&
       machine()=='WINDOWS' &&
       _isscc(svc_get_vc_system()) &&
       _SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)!='') {
      _SccUninit();
   }
}

void ctlok.lbutton_up()
{
   _vc_select_form_apply();
   p_active_form._delete_window();

}

void ctlsetup.lbutton_up()
{
   // get the provider id of this system
   system := ctlcl_systems._lbget_text();
   system = VersionControlSettings.getProviderID(system);

   // now tell the options what we want to do
   config(system, 'V');
}

static bool nonblank(_str str)
{
   if (str!='') {
      return(false);
   }
   return(true);
}

static bool nonblankpath(_str str)
{
   if (str=='') {
      return(true);
   }
   return(! (isdirectory(str)));//Has to return 0...
}

int _vcGenericGetProjectPath()
{
   workingdir := "";
   _ini_get_value(_project_name,"GLOBAL",'workingdir',workingdir);
   workingdir=_AbsoluteToProject(workingdir);
   typeless status=show('-modal _textbox_form',
               'Open SCC Project',
               TB_RETRIEVE_INIT,
               '',//tb width
               '',//help item
               '',//Buttons and captions
               'scc',//retrieve name
               '-e 'nonblank' SCC Project Name:'_strip_filename(_project_name,'PE'),
               '-e 'nonblankpath' Local Path:'workingdir);
   if (status=='') {
      return(1);
   }
   return(0);
}

void ctlscc_open_project.lbutton_up()
{
   typeless status=0;
   if (machine()=='WINDOWS' && _haveVersionControl()) {
      //This is strictly a precaution.  We should never get here unless we
      //are running Intel Windows
      _str curvcs=ctlscc_systems._lbget_text();
      if (p_caption=='&Open Project') {
         promptForPath := true;

         int providerCapabilityFlags = _SccGetProviderCapabilities();
         promptForPath = ! (providerCapabilityFlags&SCC_CAP_GETPROJPATH);
         
         if (promptForPath && lowcase(curvcs)==lowcase(PERFORCE_NAME) ) {
            // DWH - 11:18:41 AM 5/2/2008
            // Check to see if this version of Perforce provides _SccGetProjPath
            status=show('-modal _textbox_form',
                        'Open Perforce Project',
                        TB_RETRIEVE_INIT,
                        '',//tb width
                        '',//help item
                        '',//Buttons and captions
                        'perforceproject',//retrieve name
                        '-e 'nonblank' Client Name',
                        '-e 'nonblankpath' Local Path');
            if (status=='') return;

            mou_hour_glass(true);
            origwid := p_window_id;
            status=_SccOpenProject(false,"",_param1,_param2,0);
            p_window_id = origwid;
            if (status) {
               _message_box(nls("Could not open project.\n\n%s1",vcget_message(status)));
               return;
            }
            mou_hour_glass(false);
         }else if (lowcase(curvcs)=='clearcase') {
            status=show('-modal _textbox_form',
                        'Open ClearCase Project',
                        TB_RETRIEVE_INIT,
                        '',//tb width
                        '',//help item
                        '',//Buttons and captions
                        'clearcaseproject',//retrieve name
                        '-e 'nonblank' VOB Name',
                        '-e 'nonblankpath' Local View Path');
            if (status=='') return;
            mou_hour_glass(true);
            origwid := p_window_id;
            status=_SccOpenProject(true,"",_param1,_param2);
            p_window_id = origwid;
            mou_hour_glass(false);
            if (status) {
               _message_box(nls("Could not open project.\n\n%s1",vcget_message(status)));
               return;
            }
         }else if ((lowcase(curvcs)=='mks source integrity scc extension') ||
                   (lowcase(curvcs)=='mks scc integration')) {
            status=show('-modal _textbox_form',
                        'Open Source Integrity Project',
                        TB_RETRIEVE_INIT,
                        '',//tb width
                        '',//help item
                        '',//Buttons and captions
                        'clearcaseproject',//retrieve name
                        '-e 'nonblank' SI Project Filename',
                        '-e 'nonblankpath' Sandbox Path');
            if (status=='') return;
            mou_hour_glass(true);
            origwid := p_window_id;
            status=_SccOpenProject(true,"",_param1,_param2);
            p_window_id = origwid;
            mou_hour_glass(false);
         }else if (lowcase(curvcs)=='starbase starteam') {
            status=show('-modal _textbox_form',
                        'Open StarTeam Project',
                        TB_RETRIEVE_INIT,
                        '',//tb width
                        '',//help item
                        '',//Buttons and captions
                        'starteamproject',//retrieve name
                        '-e 'nonblank' StarTeam Project Name',
                        '-e 'nonblankpath' Local Path');
            if (status=='') return;
            mou_hour_glass(true);
            origwid := p_window_id;
            status=_SccOpenProject(true,"",_param1,_param2);
            p_window_id = origwid;
            mou_hour_glass(false);
         }else if (lowcase(curvcs)=='reliable software code co-op') {
               status=show('-modal _textbox_form',
                           'Open Code Co-Op Project',
                           TB_RETRIEVE_INIT,
                           '',//tb width
                           '',//help item
                           '',//Buttons and captions
                           'codecoopproject',//retrieve name
                           '-e 'nonblank' Version Control Project Name',
                           '-e 'nonblankpath' Local Path');
               mou_hour_glass(true);
               origwid := p_window_id;
               status=_SccOpenProject(true,"",_param1,_param2);
               p_window_id = origwid;
               mou_hour_glass(false);
         }else{
            newproject := false;
            if (IsHarvestSCC('SCC:'curvcs) || IsPVCSSCC('SCC:'curvcs) ) {
               typeless val=show('-modal _vc_create_prompt_form');
               if (val=='N') {
                  newproject=true;
               }else if (val=='E') {
                  newproject=false;
               }
            }
            ProjName := "";
            LocalPath := "";
            AllowChangePath := 1;
            if (newproject && IsHarvestSCC('SCC:'curvcs)) {
               AllowChangePath=0;
               if (_project_name=='') {
                  LocalPath=getcwd();
               }else{
                  LocalPath=_strip_filename(_project_name,'N');
               }
            }
            mou_hour_glass(true);
            origwid := p_window_id;
            status=_SccOpenProject(newproject,"",ProjName,LocalPath);
            p_window_id = origwid;
            mou_hour_glass(false);
         }
         if (!status) {
            _ProjectSet_VCSProject(_ProjectHandle(),SCC_PREFIX:+curvcs':'_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
            SetVCSLocalPath(_ProjectHandle(),curvcs,SCC_PREFIX:+curvcs':'_SccGetCurProjectInfo(VSSCC_LOCAL_PATH));
            SetVCSAuxPath(_ProjectHandle(),curvcs,_SccGetCurProjectInfo(VSSCC_AUX_PATH_INFO));
            status=_ProjectSave(_ProjectHandle());
            if (status) {
               _message_box(nls("Could not write version control information to project file %s1.\n\n%s2\n\nThis version control project will probably not be properly linked with the current SlickEdit project.",_project_name,get_message(status)));
            }
            _WorkspacePutProjectDate();
         }
         if (_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)!='') {
            p_caption='Close Project';
         }
      }else if (p_caption=='Close Project') {
         // OK to use _GetVCSystemName here because it's SCC and def_vc_system
         // is still used.
         mou_hour_glass(true);
         status=_SccCloseProject();
         mou_hour_glass(false);
         if (!status) {
            _ProjectSet_VCSProject(_ProjectHandle(),_GetVCSystemName()':'_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
            SetVCSLocalPath(_ProjectHandle(),_GetVCSystemName(),_GetVCSystemName()':'_SccGetCurProjectInfo(VSSCC_LOCAL_PATH));
            status=_ProjectSave(_ProjectHandle());
            if (status) {
               _message_box(nls("Could not write version control information to project file %s1.\n\n%s2\n\nThis version control project will probably not be properly linked with the current SlickEdit project.",_project_name,get_message(status)));
            }
            _WorkspacePutProjectDate();
         }
         if (_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)=='') {
            p_caption='&Open Project';
         }
      }
      ctlscc_projname.p_caption=MaybeNone(_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
      orig_view_id := 0;
      get_window_id(orig_view_id);
      oldvcname := _GetVCSystemName();
      _SetVCSystemName(SCC_PREFIX:+curvcs,false);
      toolbarUpdateFilterList(_project_name);
      _SetVCSystemName(oldvcname,false);
      activate_window(orig_view_id);
      ctlok.p_user=_SccGetCurProjectInfo(VSSCC_PROJECT_NAME);
   }
}

static const VSSCC_MAJOR_VERSION= 1;
static const VSSCC_MINOR_VERSION= 1;

int ctlscc_init.lbutton_up()
{
   typeless status=0;
   if (machine()=='WINDOWS' && _haveVersionControl()) {
      //This is strictly a precaution.  We should never get here unless we
      //are running Intel Windows
      if (_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)!=ctlscc_systems._lbget_text()) {
         mou_hour_glass(true);
         status=_SccInit(ctlscc_systems._lbget_text());
         mou_hour_glass(false);
      }
      if (status) {
         _message_box(nls("Could not initialize provider %s",ctlscc_systems._lbget_text()));
         return(1);
      }
      typeless Major="", Minor="";
      _SccGetVersion(Major,Minor);
#if 0 //9:23am 2/8/1999
      if (Major<VSSCC_MAJOR_VERSION ||
          Minor<VSSCC_MINOR_VERSION) {
         _message_box(nls("SlickEdit cannot use the provider support dll %s because it is too old.",_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)));
         mou_hour_glass(true);
         status=_SccInit(ctlscc_systems._lbget_text());
         mou_hour_glass(false);
         return(1);
      }
#endif
      ctlscc_open_project.p_caption='&Open Project';
      ctlscc_projname.p_caption=MaybeNone(_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
      ctlscc_systems.call_event(CHANGE_SELECTED,ctlscc_systems,ON_CHANGE,'W') ;
   }
   return(0);
}

void ctlscc_systems.on_change(int reason)
{
   //say('_SccGetCurProjectInfo(SCC_PROVIDER_NAME)='_SccGetCurProjectInfo(SCC_PROVIDER_NAME));
   //say('_SccGetCurProjectInfo(SCC_PROJECT_NAME)='_SccGetCurProjectInfo(SCC_PROJECT_NAME));
   if (machine()=='WINDOWS' && _haveVersionControl()) {
      //This is strictly a precaution.  We should never get here unless we
      //are running Intel Windows
      if (_lbget_text()!=_SccGetCurProjectInfo(VSSCC_PROVIDER_NAME)) {
         ctlscc_init.p_enabled=ctlscc_systems.p_enabled;
         ctlscc_open_project.p_enabled=false;
         ctlscc_advanced.p_enabled=false;
         ctlscc_projname.p_caption='NONE';
      }else{
         if ( _GetDialogInfoHt("64BitMessage")!=1 ) {
            // If we have displayed the 64-bit error message, we do not want to
            // change it by setting ctlscc_projname.p_caption
            ctlscc_init.p_enabled=false;
            ctlscc_open_project.p_enabled=ctlscc_systems.p_enabled;
            ctlscc_advanced.p_enabled=ctlscc_systems.p_enabled;
            ctlscc_projname.p_caption=MaybeNone(_SccGetCurProjectInfo(VSSCC_PROJECT_NAME));
         }
      }
   }
}

void ctlscc_advanced.lbutton_up()
{
   if (machine()=='WINDOWS' && _haveVersionControl()) {
      //This is strictly a precaution.  We should never get here unless we
      //are running Intel Windows
      typeless status=_SccGetCommandOptions(VSSCC_COMMAND_OPTION);
      if (status && status!=COMMAND_CANCELLED_RC) {
         _message_box(nls("Advanced options not supported"));
      }
   }
}

static int IsUniqueSystemName(_str SystemName)
{
   if (pos(':',SystemName)) {
      _message_box(nls("'%s' is not a valid system name.  Please limit name to alphnumeric characters."));
      return(1);
   }

   if (VersionControlSettings.getProviderID(SystemName) != '') {
      //New system name is not unique
      _message_box(nls("A system named '%s' already exists",SystemName));
      return(1);
   }

   return(0);
}

void ctladd.lbutton_up()
{
   typeless result=show('-modal _textbox_form',
               'New System Name',
               0,//Flags
               '',//Use default width
               '',//Help Item
               '',//Buttons and captions
               '',//Retrieve Name
               '-e 'IsUniqueSystemName':New System Name');
   if (result=='') {
      return;
   }

   newvcs := _param1;
   VersionControlSettings.addProvider(newvcs);
   refreshCLSystemList(newvcs);

   // make sure this is added to the options
   addNewVersionControlProviderToOptionsXML(newvcs);
}

void ctldelete.lbutton_up()
{
   // get the provider id
   system := ctlcl_systems._lbget_text();
   systemID := VersionControlSettings.getProviderID(system);

   VersionControlSettings.deleteProvider(systemID);
   refreshCLSystemList();

   // update the options
   removeVersionControlProviderFromOptionsXML(system);
}

void ctlrename.lbutton_up()
{
   typeless result=show('-modal _textbox_form',
               'New System Name',
               0,//Flags
               '',//Use default width
               '',//Help Item
               '',//Buttons and captions
               '',//Retrieve Name
               '-e 'IsUniqueSystemName':New System Name');
   if (result=='') {
      return;
   }
   _str newvcs=_param1;
   vcs := ctlcl_systems._lbget_text();
   provID := VersionControlSettings.getProviderID(vcs);

   VersionControlSettings.renameProvider(provID, newvcs);
   refreshCLSystemList(newvcs);
 
   // update the options
   renameVersionControlProvider(vcs, newvcs);
}

void ctlcopy.lbutton_up()
{
   source := ctlcl_systems._lbget_text();
   typeless result=show('-modal _textbox_form',
               'Copy 'source' to New System',
               0,//Flags
               '',//Use default width
               '',//Help Item
               '',//Buttons and captions
               '',//Retrieve Name
               '-e 'IsUniqueSystemName':New System Name');

   if (result == '') return;

   newVCS := _param1;
   source = VersionControlSettings.getProviderID(source);

   VersionControlSettings.addProvider(newVCS, source);

   refreshCLSystemList(newVCS);
}

static _str vcget_message(int status)
{
   return(get_message(status));
#if 0 //12:53pm 3/30/2011
   if (!_isscc() || machine()!='WINDOWS') {
      return(get_message(status));
   }
   switch (status) {
   case VSSCC_E_INITIALIZEFAILED:
      return("Initialize failed");
   case VSSCC_E_UNKNOWNPROJECT:
      return("Unknown project");
   case VSSCC_E_COULDNOTCREATEPROJECT:
      return("Could not create project");
   case VSSCC_E_NOTCHECKEDOUT:
      return("Not checked out");
   case VSSCC_E_ALREADYCHECKEDOUT:
      return("Already checked out");
   case VSSCC_E_FILEISLOCKED:
      return("File is locked");
   case VSSCC_E_FILEOUTEXCLUSIVE:
      return("File checked out exclusive");
   case VSSCC_E_ACCESSFAILURE:
      return("Access failure");
   case VSSCC_E_CHECKINCONFLICT:
      return("Checkin conflict");
   case VSSCC_E_FILEALREADYEXISTS:
      return("File already exists");
   case VSSCC_E_FILENOTCONTROLLED:
      return("File not controlled");
   case VSSCC_E_FILEISCHECKEDOUT:
      return("File is checked out");
   case VSSCC_E_NOSPECIFIEDVERSION:
      return("No specified version");
   case VSSCC_E_OPNOTSUPPORTED:
      return("Opereation not supported");
   case VSSCC_E_NONSPECIFICERROR:
      return("The version control system returned a non specific error code");
   case VSSCC_E_OPNOTPERFORMED:
      return("Operation not performed");
   case VSSCC_E_TYPENOTSUPPORTED:
      return("Type not supported");
   case VSSCC_E_VERIFYMERGE:
      return("Verify Merge");
   case VSSCC_E_FIXMERGE:
      return("Fix Merge");
   case VSSCC_E_SHELLFAILURE:
      return("Shell failure");
   case VSSCC_E_INVALIDUSER:
      return("Invalid user");
   case VSSCC_E_PROJECTALREADYOPEN:
      return("Project already open");
   case VSSCC_E_PROJSYNTAXERR:
      return("Project syntax error");
   case VSSCC_E_INVALIDFILEPATH:
      return("Invalid file path");
   case VSSCC_E_PROJNOTOPEN:
      return("Project not open");
   case VSSCC_E_NOTAUTHORIZED:
      return("Not authorized");
   case VSSCC_E_FILESYNTAXERR:
      return("File syntax error");
   case VSSCC_E_FILENOTEXIST:
      return("File does not exist");
   }
   return(get_message(status));
#endif
}

bool _isscc(_str vcs=svc_get_vc_system())
{
   return(substr(vcs,1,SCC_PREFIX_LENGTH) == SCC_PREFIX);
}

bool _SCCProjectIsOpen()
{

   if (machine()=='WINDOWS' && _haveVersionControl()) {
      //This is strictly a precaution.  We should never get here unless we
      //are running Intel Windows
      return(_SccGetCurProjectInfo(VSSCC_PROJECT_NAME)!='');
   }
   return(false);
}

bool _VCSCommandIsValid(_str FieldName)
{
   vcsystem := svc_get_vc_system();
   if ( vcsystem == '') return(false);

   if ( _SVCIsSVCSystem(vcsystem) ) {
      IVersionControl *pInterface = svcGetInterface(vcsystem);
      switch ( FieldName ) {
      case VCS_CHECKOUT:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_CHECKOUT ) {
            return true;
         }
         return false;
      case VCS_CHECKIN_NEW:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_ADD ) {
            return true;
         }
         return false;
      case VCS_CHECKIN:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_COMMIT ) {
            return true;
         }
         return false;
      case VCS_CHECKOUT_READ_ONLY:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_UPDATE ) {
            return true;
         }
         return false;
      case VCS_CHECKIN_DISCARD:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REVERT ) {
            return true;
         }
         return false;
      case VCS_PROPERTIES:
         return false;
      case VCS_DIFFERENCE:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_DIFF ) {
            return true;
         }
         return false;
      case VCS_HISTORY:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY ) {
            return true;
         }
         return false;
      case VCS_REMOVE:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REMOVE ) {
            return true;
         }
         return false;
      case VCS_LOCK:
         if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT ) {
            return true;
         }
         return false;
      case VCS_MANAGER:
         return false;
      }
      return false;
   }

   info := VersionControlSettings.getCommandByName(svc_get_vc_system(), FieldName);
   return(info!='');
}

static const PROJECT_TREE_NAME=     '_proj_tooltab_tree';
static const PROJECT_OPENLIST_NAME= '_openfile_list';

_command refresh_project_toolbar() name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2)
{
   toolbarUpdateFilterList(_project_name);
}

static void UpdateProjectTree(_str filename)
{
   if (!machine()=='WINDOWS' || !_isscc()) {
      return;
   }

   TBPROJECTS_FORM_INFO v;
   int i;
   foreach (i => v in gtbProjectsFormList) {
      _nocheck _control _proj_tooltab_tree;
      int treewid=i._proj_tooltab_tree;
      treewid.UpdateProjectBitmap(filename);
   }

}

int _UpdateBufferReadOnlyStatus(_str filename,bool &haveBuffer=false)
{
   if (filename=='' || filename==_chr(1)'empty') {
      return(0);
   }
   //Now reload the file to get the read-only stuff right
   orig_view_id := p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   typeless status=load_files('+q +b 'strip(filename,'b','"'));
   if (!status) {
      haveBuffer = true;
      maybe_set_readonly();
   }
   p_window_id=orig_view_id;
   return(status);
}

static const VC_BUFFER_COL= 2;

static void vc_build_buf_list(int &width,_str (&Files)[],int start_buf_id=-1)
{
   orig_view_id := p_window_id;
   p_window_id=VSWID_HIDDEN;
   int orig_buf_id=p_buf_id;
   _safe_hidden_window();
   width=0;
   if (start_buf_id<0) {
      start_buf_id=_mdi.p_child.p_buf_id;
   }
   match_name := "";
   line := "";
   load_files('+bi 'start_buf_id);
   for (;;) {
      // Skip over Delphi buffers:
      if (1/* || p_buf_id!=orig_buf_id */) {
         if (p_DocumentName!='') {
            match_name=p_DocumentName;
         } else {
            match_name=p_buf_name;
         }
         if (match_name!='') {
            //match_name=NO_NAME:+p_buf_id'>';
            line=match_name;
            int is_hidden=(p_buf_flags&VSBUFFLAG_HIDDEN);
            if ( ! is_hidden) {
               //insert_line substr(modify,1,BUFFER_COL-1):+ strip(line,'L');
               if (!beginsWith(match_name,'.process')) {
                  Files[Files._length()]=line;
               }
               if ( length(line)>width ) { width=length(line); }
            }
         }
      }
      _next_buffer('NRH');
      if ( p_buf_id==start_buf_id ) {
         break;
      }
   }
   p_buf_id=orig_buf_id;
#if 0 //11:20am 2/25/1999
   next=1;
   for (i=0; i<Files._length() ; ++i) {
      //p_line=next;
      //get_line(line);
      //modify=substr(line,1,BUFFER_COL-1)
      //new_modify=substr(stranslate(modify,'','H'),1,BUFFER_COL-1)
      if ( pos('H',modify) || (substr(line,VC_BUFFER_COL,1)=='.' && 1/*(def_buflist&SORT_BUFLIST_FLAG)*/ ) ) {
         //_delete_line
         //bottom;
         //insert_line new_modify:+ substr(line,BUFFER_COL)
         Files[Files._length()]=' 'substr(line,VC_BUFFER_COL);
      } else {
         //replace_line new_modify:+ substr(line,BUFFER_COL)
         //next=next+1
      }
   }
#endif
   p_window_id=orig_view_id;
}


static _str getVCFilename()
{
   filename := "";
   if ( _isEditorCtl() ) {
      filename=GetFilenameFromBuffer();
   }else if (p_object==OI_TREE_VIEW) {
      index := _TreeCurIndex();
      cap := _TreeGetCaption(index);
      if (_projecttbIsWorkspaceNode(index)) {
         filename=cap;
      }else{
         parse cap with . "\t" filename;
         filename = _AbsoluteToWorkspace(filename);
      }
   }

   return filename;
}

int _OnUpdate_vcget(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==""||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCGET));
}

//10:49am 2/25/1999
//Sort of gross, but there is some global data for the advanced data for
//each SCC command.  Since I use a sellist for the the dialog for that, I
//have to have a global variable to know what VC command I am in.
static int gCurrentCommand;

static void _vc_callback(int Event,_str &result,_str info)
{
   _nocheck _control _selnofselected;
   _nocheck _control _sellist;
   _nocheck _control _sellistcombo;
   switch (Event) {
   case SL_ONINIT:
      _str filename=_mdi.p_child.p_buf_name;
      wid := p_window_id;
      p_window_id=_sellist;
      _lbsort('-F');
      top();
      up();
#if 0 //5:36pm 3/2/1999
      status=search('^?'_escape_re_chars(filename)'$',_fpos_case'@rh');
      if (!status) {
         _lbselect_line();
      }
#else
      _sellistcombo.p_text=filename;
#endif
      _selnofselected.p_caption=p_Nofselected' of 'p_Noflines' selected';
      p_window_id=wid;
      if (machine()=='WINDOWS' && _isscc() && _haveVersionControl() && _SccGetCommandOptions(gCurrentCommand,'T')) {
         //Disable the advanced button
         _sellist.p_next.p_next.p_next.p_enabled=false;
      }else if (machine()!='WINDOWS' || !_isscc()) {
         //Disable the advanced button
         _sellist.p_next.p_next.p_next.p_enabled=false;
      }
      /*if (machine()!='WINDOWS' || !_isscc() ||
          _SccGetCommandOptions(gCurrentCommand,'T')) {
         //Disable the advanced button
         _sellist.p_next.p_next.p_next.p_enabled=false;
      }*/
      break;
   case SL_ONUSERBUTTON:
      switch (info) {
      case 3://Advanced button
         if (machine()=='WINDOWS' && _haveVersionControl()) {
            //Should be disabled if !_isscc() or not on WINDOWS
            _SccGetCommandOptions(gCurrentCommand);
         }
         break;
      case 4://Advanced button
         int buttonwid=_sellist.p_next.p_next.p_next.p_next;
         if (buttonwid.p_caption=='Buffers') {
            buttonwid.p_caption='Project Files';
         }else if (buttonwid.p_caption=='Project Files') {
            buttonwid.p_caption='Buffers';
         }
         break;
      }
   }
}

static void GetVCDialogCaptions(int command,_str &DialogCaption,_str &OKCaption)
{
   switch (command) {
   case VSSCC_COMMAND_GET:
      DialogCaption="Get Files";
      OKCaption="Get";
      break;
   case VSSCC_COMMAND_CHECKIN:
      DialogCaption="Checkin Files";
      OKCaption="Checkin";
      break;
   case VSSCC_COMMAND_CHECKOUT:
      DialogCaption="Checkout Files";
      OKCaption="Checkout";
      break;
   case VSSCC_COMMAND_UNCHECKOUT:
      DialogCaption="Unlock Files";
      OKCaption="Unlock";
      break;
   case VSSCC_COMMAND_ADD:
      DialogCaption="Add Files";
      OKCaption="Add";
      break;
   case VSSCC_COMMAND_REMOVE:
      DialogCaption="Remove Files";
      OKCaption="Remove";
      break;
   }
}

static int vc_prompt_for_filenames(_str (&Files)[],int command,bool &SaveFiles=false)
{
   if ( def_vc_advanced_options&VC_ADVANCED_NO_PROMPT ) {
      Files[0]=p_buf_name;
   }else{
      if (!_isEditorCtl()) {
         return(FILE_NOT_FOUND_RC);
      }
      _str DialogCaption,OKCaption;
      GetVCDialogCaptions(command,DialogCaption,OKCaption);
      typeless result=show('-modal _vc_advanced_form',DialogCaption,OKCaption,command);
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      Files=_param1;
      SaveFiles=_param2;
   }
   return(0);
}

/*
   Get the current file
*/
_command int vcget(_str filename='') name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_GET;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   PassedFilename := filename!='';
   _str Files[]=null;
   if (p_name==PROJECT_TREE_NAME) {
      treewid := p_window_id;
      GetFileListFromTree(Files,"get");
   }else if (filename=='') {
      int status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_GET);
      if (status) return(status);
   }else{
      Files[0]=filename;
   }
   vcs := svc_get_vc_system(filename);
   if ( vcs=='' ) {
      _message_box(nls("No vcs configured"));
      return(1);
   }
   OutputDisplayClear();
   rechached_projects := false;
   typeless junk=0;
   int i;
   for (i=0;i<Files._length();++i) {
      filename=Files[i];
      filename=_maybe_quote_filename(filename);
      status := 0;
      if (_isscc(vcs) && machine()=='WINDOWS') {
         status=_checkout(junk,junk,filename,vcs,
                          true,true);//edit_files,read_only
      }else if ( _VCIsSpecializedSystem(vcs) ) {
         status=svc_update(filename);
      }else{
         if (file_match(_vcerror_file()' -p',1)!='') {
            delete_file(_vcerror_file());
         }
         errors_view_id := 0;
         int orig_view_id=_create_temp_view(errors_view_id);
         if (orig_view_id=='') return(1);
         activate_window(orig_view_id);
         typeless linenum=0;
         status=_checkout(linenum,errors_view_id,filename,vcs,
                          true,true);//edit_files,read_only
         //show('-modal _vc_error_form',errors_view_id,linenum);
         DisplayOutputFromView(errors_view_id);
      }
      if ( !status ) {
         // Re-cache any updated project files
         if (RecacheIfProject(filename)) rechached_projects=true;
      }
      _UpdateBufferReadOnlyStatus(filename);
   }
   if ( rechached_projects ) {
      projecttbRefresh();
   }
   return(0);
}

/**
 * @param filename filename to check
 * 
 * @return true if filename this was project (vpj) file and was re-cached by the project system
 */
static bool RecacheIfProject(_str filename)
{
   recached := false;
   _str ext=_get_extension(filename,true);
   if ( _file_eq(ext,PRJ_FILE_EXT) ) {
      _ProjectCache_Update(filename);
      recached=true;
   }
   return(recached);
}

static int IsValidLevel(_str command='')
{
   index := _TreeCurIndex();
   int depth=_TreeGetDepth(index);
   if (command=='vchistory' || command=='vcdiff') {
      int state,bm1,bm2;
      _TreeGetInfo(index,state,bm1,bm2);

      // Before this checked the depth of the file. 
      // That isn't good enough anymore because of 
      // the folder structures.
      if ( bm1!=_pic_vc_co_user_w &&
           bm1!=_pic_vc_co_user_r &&
           bm1!=_pic_vc_co_other_m_w &&
           bm1!=_pic_vc_co_other_m_r &&
           bm1!=_pic_vc_co_other_x_w &&
           bm1!=_pic_vc_co_other_x_r &&
           bm1!=_pic_vc_available_w &&
           bm1!=_pic_vc_available_r &&
           bm1!=_pic_file &&
           bm1!=_pic_cvs_file &&
           bm1!=_pic_cvs_filem &&
           bm1!=_pic_file_mod &&
           bm1!=_pic_file_mod_prop &&
           bm1!=_pic_file_old ) {
         return(0);
      }
   }
   return(1);
}
int _OnUpdate_vccheckout(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCCHECKOUT));
}

/**
 * Returns a list of all filenames under index.  Only
 * returns filenames.  Folder and project nodes are
 * traversed, but not added to the list.
 *
 * @param index  index to add all children from.
 * @param Files  Array to add all filenames to.
 */
static void GetAllChildFiles(int index,_str (&Files)[])
{
   for (;;) {
      CIndex := _TreeGetFirstChildIndex(index);
      if (CIndex>=0) {
         GetAllChildFiles(CIndex,Files);
      }
      if (_projecttbIsProjectFileNode(index) == true) {
         Caption := _TreeGetCaption(index);
         name := filename := "";
         parse Caption with name "\t" filename;
         Files[Files._length()]=_AbsoluteToWorkspace(filename);
      }
      RIndex := _TreeGetNextSiblingIndex(index);
      if (RIndex<0) break;
      index=RIndex;
   }
}


/**
 * Prompts the user, and then returns a list of all
 * files under the current index in the project
 * tree on the project toolbar.
 *
 * @param Files      Array that the file list is returned in
 * @param CommandStr Command string used to prompt the user:
 *                   Do you wish to &lt;CommandStr&gt; all of the files...
 * @return Returns 0 if succesful.
 */
static int GetFileListFromTree(_str (&Files)[],_str CommandStr)
{
   name := "";
   path := "";

   _str FileTab:[];
   ff := 1;
   int info;
   selindex := _TreeGetNextSelectedIndex(ff,info);
   if (selindex<0) {
      _TreeSelectLine(_TreeCurIndex());
   }

   for (;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index<0) break;
      CommandStr=_Capitalize(CommandStr);
      int depth=_TreeGetDepth(index);
      Caption := _TreeGetCaption(index);
      if (_projecttbIsProjectFileNode(index)) {
         parse Caption with name "\t" path;
         filename := _AbsoluteToWorkspace(path);
         if (filename=='') {
            return(1);
         }
         FileTab:[_file_case(filename)]=filename;
      }else if (_projecttbIsFolderNode(index)) {
         _str Msg=nls("%s all files in the folder '%s'",CommandStr,Caption);
         int status=_message_box(nls(Msg),'',MB_YESNOCANCEL);
         if (status==IDYES) {
            GetAllChildFiles(_TreeGetFirstChildIndex(index),Files);
         }else{
            return(COMMAND_CANCELLED_RC);
         }
      }else{
         _str captions[]=null;

         captions[0]=nls("%s all files in ",CommandStr);
         suffix := "";
         isworkspace := false;
         if (_projecttbIsProjectNode(index)) {
            parse Caption with name "\t" path;
            suffix=path;
            captions[1]=nls("%s %s",CommandStr,suffix);
         }else if (_projecttbIsWorkspaceNode(index)) {
            suffix=Caption;
            captions[1]=nls("%s %s",CommandStr,suffix);
            isworkspace=true;
         }
         captions[0] :+= ' 'nls(suffix);
         int result=RadioButtons(CommandStr,captions,1,'projtbcheckout');
         if (result==COMMAND_CANCELLED_RC) {
            return(result);
         }else if (result==1) {
            GetAllChildFiles(_TreeGetFirstChildIndex(index),Files);
         }else{
            if (isworkspace) {
               FileTab:[_file_case(Caption)]=Caption;
            }else{
               parse Caption with name "\t" path;
               FileTab:[_file_case(path)]=path;
            }
         }
      }
   }
   typeless j;
   count := 0;
   for (j=null;;) {
      FileTab._nextel(j);
      if (j==null) break;
      Files[count++]=FileTab:[j];
   }

   return(0);
}
/*
   Checkout the current file
*/
_command int vccheckout(_str filename='', _str skipProjectUpdate='',bool editCheckedoutFiles=true) name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_CHECKOUT;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   PassedFilename := filename!='';

   vcs := svc_get_vc_system(filename);
   if (vcs=='') {
      _message_box(nls("No vcs configured"));
      return(1);
   }
   typeless junk=0;
   status := 0;
   treewid := 0;
   FileList := "";
   _str Files[]=null;
   if (p_name==PROJECT_TREE_NAME) {
      //If someone has used the 'rclickmenu' on the project tree
      treewid=p_window_id;
      GetFileListFromTree(Files,"check out");
   }else if (p_name==PROJECT_OPENLIST_NAME) {
      _nocheck _control _opendir_list;
      Files[0]=_opendir_list._dlpath():+_lbget_text();
   }else if (filename=='') {
      status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_CHECKOUT);
      if (status) return(status);
   }else{
      Files[0]=filename;
   }
   OutputDisplayClear();
   recached_projects := false;
   int i;
   for (i=0;i<Files._length();++i) {
      filename=Files[i];
      filename=_maybe_quote_filename(filename);//Shouldn't need this now
      _str ext=_get_extension(filename,true);
      edit_file := editCheckedoutFiles && !_file_eq(ext,PRJ_FILE_EXT) && !_file_eq(ext,WORKSPACE_FILE_EXT);
      if (_isscc(vcs) && machine()=='WINDOWS') {
         status=_checkout(junk,junk,filename,vcs,edit_file,false);
      }else if ( _VCIsSpecializedSystem(vcs) ) {
         svc_edit(filename);
      }else{
         if (file_match(_vcerror_file()' -p',1)!='') {
            delete_file(_vcerror_file());
         }

         errors_view_id := 0;
         int orig_view_id=_create_temp_view(errors_view_id);
         if (orig_view_id=='') return(1);
         activate_window(orig_view_id);
         typeless linenum=0;
         status=_checkout(linenum,errors_view_id,filename,vcs,
                          editCheckedoutFiles,false);//edit_files,read_only
         //_checkout will not edit the files if there is no _mdi
         //if (status) show('-modal _vc_error_form',errors_view_id,linenum);
         if (status || VersionControlSettings.getAlwaysShowOutput(vcs)) {
            DisplayOutputFromView(errors_view_id);
         }else{
            _delete_temp_view(errors_view_id);
         }
      }
      if (skipProjectUpdate!=true) {
         if ( !status ) {
            // Re-cache any updated project files
            if (RecacheIfProject(filename)) recached_projects=true;
         }
         UpdateProjectTree(filename);
         status=_UpdateBufferReadOnlyStatus(filename);
         //3:57:30 PM 11/8/2002
         // Shouldn't need this, _checkout edits the files if that option is on.
         /*if (status && _default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW &&
             filename!=_chr(1):+'empty') {
            edit(filename);
         }*/
      }
   }
   if ( recached_projects && treewid ) {
      projecttbRefresh();
   }
   return(status);
}


// Need this so version 3.0 tool bars sort of work.
// Old message in toolbar will be wrong.

/**
 * The <b>checkin</b> command checks in the files specified into the version control
 * system specified by the current project.  If <i>cmdline</i> is not given or '',
 * the Check In dialog box is displayed.
 *
 * @paraam options is a string of one or more of the following switches:
 * <pre>
 * + or -c  Comment for all files.
 * + or -p  Prompt for each comment
 * + or -d  Discard changes
 * + or -new   Create a new archive file
 *
 * You may specify '.' to check in the current buffer ("checkin .").
 *
 * </pre>
 * @return Returns 0 if successful.
 *

 * @example  <i>cmdline</i> is a  string in the format: [<i>options</i>] <i>file1 file2 file3 ...</i>
 *
 *
 * @see checkout
 * @categories File_Functions
 */
_command int checkin(_str filename="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   options := "";
   filename=strip_options(filename,options,true);
   return(vccheckin(filename));
}
// Need this so version 3.0 tool bars sort of work.
// Old message in toolbar will be wrong.


/**
 * The <b>checkout</b> command checks out the files specified from the version
 * control system specified by the current project.  If <i>cmdline</i> is not given or '',
 * the Check Out dialog box is displayed.
 *
 *  @param  <i>options</i> is a string of one or more of the following switches:
 * <pre>
 *    + or -r  Checkout the file read only.  Ignored by Delta.
 *    + or -e  Edit the file after checking it out.
 *
 *    You may specify '.' to check out the current buffer ("checkout .").
 * </pre>
 *
 * @return  Returns 0 if successful.
 *
 * @exmple <i>cmdline</i> is a  string in the format: [<i>options</i>] <i>file1 file2 file3 ...</i>
 *
 * @see checkin
 *
 * @categories File_Functions
 */
_command int checkout(_str filename="") name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   options := "";
   filename=strip_options(filename,options,true);
   return(vccheckout(filename));
}

int _OnUpdate_vccheckin(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCCHECKIN));
}
/*
   Checkin the current file
*/
_command int vccheckin(_str filename='',_str comment=NULL_COMMENT) name_info(','EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_CHECKIN;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   PassedFilename := filename!='';

   vcs := svc_get_vc_system(filename);
   if (vcs=='') {
      _message_box(nls("No vcs configured"));
      return(1);
   }
   treewid := 0;
   _str Files[];
   SaveFiles := false;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"check in");
   }else if (p_name==PROJECT_OPENLIST_NAME) {
      _nocheck _control _opendir_list;
      Files[0]=_opendir_list._dlpath():+_lbget_text();
   }else if (filename=='') {
      int status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_CHECKIN,SaveFiles);
      if (status) return(status);
   }else{
      Files[0]=filename;
   }
#if 0 //4:32pm 3/2/1999
   int status=list_modified('',true);
   if (status) {
      return(status);
   }
#endif
   OutputDisplayClear();
   typeless junk=0;
   typeless result=0;
   HaveComment := false;

   command := VersionControlSettings.getCommand(vcs, VCCHECKIN);
   typeless status;
   int i;
   callAutoReload := false;
   for (i=0;i<Files._length();++i) {
      filename=Files[i];
      if (SaveFiles) {
         status=_save_non_active(filename);
      }
      if ( (_isscc(vcs) && machine()=='WINDOWS') ||
             (Files._length()>0 && pos('%c',command)) ) {
         if (filename=='') {
            break;
         }
         if (!HaveComment) {
            result=show('-modal _vc_comment_form',filename,0,1);
            if (VersionControlSettings.getWriteCommentToFile(vcs)) {
               comment=absolute(_vccomment_file());
            }else{
               comment=_param1;
            }
            HaveComment=_param2;
         }
      }
      filename=_maybe_quote_filename(filename);
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      if (_isscc(vcs) && machine()=='WINDOWS') {
         _checkin(junk,junk,filename,vcs,0,0,0,comment);
      }else if (_VCIsSpecializedSystem(vcs)) {
         status=svc_commit(filename,comment);
      }else{
         if (file_match(_vcerror_file()' -p',1)!='') {
            delete_file(_vcerror_file());
         }
         errors_view_id := 0;
         int orig_view_id=_create_temp_view(errors_view_id);
         if (orig_view_id=='') return(1);
         activate_window(orig_view_id);
         typeless linenum=0;
         _checkin(linenum,errors_view_id,filename,vcs,0,0,0,comment);
         //show('-modal _vc_error_form',errors_view_id,linenum);
         DisplayOutputFromView(errors_view_id);
      }

      //Now update the bitmap in the project toolbar
      UpdateProjectTree(filename);
      _UpdateBufferReadOnlyStatus(filename,auto haveBuffer);
      if ( haveBuffer ) {
         haveFile := file_exists(filename);

         if ( haveBuffer && !haveFile ) {
            // The local source file was deleted on the checkin.  Set flag to 
            // call auto-reload when we are done so it only happens once
            callAutoReload = true;
         }
      }
   }
   if ( callAutoReload ) {
      _ReloadFiles();
   }
   return(0);
}

int _OnUpdate_vcunlock(CMDUI &cmdui,int target_wid,_str command)
{
   vcs := svc_get_vc_system();
   if (vcs==''||command==''||
       (_isscc(vcs) && machine()=='WINDOWS') ) {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCUNLOCK));
}
/*
   Unlock the current file
*/
_command int vcunlock(_str filename='') name_info(','EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_UNCHECKOUT;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   PassedFilename := filename!='';
   if (svc_get_vc_system()=='') {
      _message_box(nls("No vcs configured"));
      return(1);
   }
   treewid := 0;
   _str Files[];
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"unlock");
   }else if (filename=='') {
      int status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_UNCHECKOUT);
      if (status) return(status);
   }else{
      Files[0]=filename;
   }
   typeless junk=0;
   OutputDisplayClear();
   int i;
   for (i=0;i<Files._length();++i) {
      filename=Files[i];
      if (filename=='') {
         break;
      }
      filename=_maybe_quote_filename(filename);
      comment := "";
      needReload := false;
      // 5/25/2017 12:49:55 PM
      // Do this in loop because, in theory, it could be different for 
      // different files
      vcs := svc_get_vc_system(filename);
      if (_isscc(vcs) && machine()=='WINDOWS') {
         _checkin(junk,junk,filename,vcs,0,1,0,'');
         needReload=true;
      }else if ( _VCIsSpecializedSystem(vcs) ) {
         // Nothing to do in this case
      }else{
         if (file_match(_vcerror_file()' -p',1)!='') {
            delete_file(_vcerror_file());
         }
         errors_view_id := 0;
         int orig_view_id=_create_temp_view(errors_view_id);
         if (orig_view_id=='') return(1);
         activate_window(orig_view_id);
         typeless linenum=0;
         _checkin(linenum,errors_view_id,filename,vcs,0,1,0,'');
         //show('-modal _vc_error_form',errors_view_id,linenum);
         DisplayOutputFromView(errors_view_id);
         needReload=true;
      }
      //Now reload the file to get the read-only stuff right
      UpdateProjectTree(filename);
      _UpdateBufferReadOnlyStatus(filename);
      if ( needReload ) {
         edit_and_close_filelist(filename);
      }
   }
   return(0);
}

int _OnUpdate_vcadd(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCADD));
}
/*
   Checkin the current file for the first time
*/
_command int vcadd(_str filename='',_str comment=NULL_COMMENT) name_info(','EDITORCTL_ARG2|READ_ONLY_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_ADD;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   PassedFilename := filename!='';

   vcs := svc_get_vc_system();
   if (vcs == '') {
      _message_box(nls("No vcs configured"));
      return(1);
   }
   treewid := 0;
   _str Files[];
   SaveFiles := false;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"add");
      if ( Files._length()==0 ) {
         Files[0]=filename;
      }
   }else if (filename=='') {
      int status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_ADD,SaveFiles);
      if (status) return(status);
   }else{
      Files[0]=filename;
   }
   typeless junk=0;
   typeless status=0;
   typeless result=0;
   OutputDisplayClear();
   int i;
   for (i=0;i<Files._length();++i) {
      if (SaveFiles) {
         _save_non_active(Files[i]);
      }
      filename=_maybe_quote_filename(Files[i]);

      if (_isscc(vcs) && machine()=='WINDOWS') {

         if (comment==NULL_COMMENT) {
            result=show('-modal _vc_comment_form',filename,0);

            comment_file := VersionControlSettings.getWriteCommentToFile(vcs);
            if (comment_file) {
               comment=absolute(_vccomment_file());
            }else{
               comment=_param1;
            }
            if (result=='') {
               return(COMMAND_CANCELLED_RC);
            }
         }
         status=_checkin(junk,junk,filename, vcs,1,0,0,comment);
      }else if ( _VCIsSpecializedSystem(vcs) ) {
         status=svc_add(filename);
      }else{
         if (file_match(_vcerror_file()' -p',1)!='') {
            delete_file(_vcerror_file());
         }
         errors_view_id := 0;
         int orig_view_id=_create_temp_view(errors_view_id);
         if (orig_view_id=='') return(1);
         activate_window(orig_view_id);
         typeless linenum=0;
         _checkin(linenum,errors_view_id,filename,vcs,1,0,0,comment);
         DisplayOutputFromView(errors_view_id);
      }
      UpdateProjectTree(filename);
      _UpdateBufferReadOnlyStatus(filename);
   }
   return(0);
}

int _OnUpdate_vcmanager(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCMANAGER));
}
_command int vcmanager() name_info(','NCW_ARG2|ICON_ARG2|READ_ONLY_ARG2|CMDLINE_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   status := 0;
   OutputDisplayClear();
   vcs := svc_get_vc_system();
   if (machine()!='WINDOWS' || !_isscc()) {
      filename := "";
      if (!_no_child_windows()) {
         filename=_maybe_quote_filename(_mdi.p_child.p_buf_name);
      }
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=orig_view_id;

      status=_misc_cl_vc_command(VCS_MANAGER,temp_view_id,filename,vcs,0,'A');

      if (status || VersionControlSettings.getAlwaysShowOutput(vcs)) {
         DisplayOutputFromView(temp_view_id);
      }else{
         _delete_temp_view(temp_view_id);
      }
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      // Nothing to do in this case
   }else{
      _str junk[];
      //This is supposed to take an array of files to highlight when the VCS
      //comes up, but the SCC call doesn't seem to work right.
      status=_SccRunScc(junk);
      if (status) {
         _message_box(nls(vcget_message(status)));
      }
   }
   return(status);
}

int _OnUpdate_vcproperties(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCPROPERTIES));
}
_command int vcproperties(_str filename='') name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_PROPERTIES;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   status := 0;
   treewid := 0;
   _str Files[]=null;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"view properties");
   }else if (filename=='') {
      if (!_isEditorCtl()) {
         return(FILE_NOT_FOUND_RC);
      }
      Files[0]=p_buf_name;
   }
   OutputDisplayClear();
   filename=Files[0];
   vcs := svc_get_vc_system();
   if (machine()=='WINDOWS' && _isscc(vcs)) {
      if (!Files._length()) return(1);
      filename=Files[0];
      status=_SccProperties(filename);
      if (status) {
         _message_box(nls(vcget_message(status)));
      }
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      // Nothing to do in this case
   }else{
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      status=_misc_cl_vc_command(VCS_PROPERTIES,temp_view_id,_maybe_quote_filename(filename),vcs,1);
      //show('-modal _vc_error_form',temp_view_id,'','Properties for 'filename);
      DisplayOutputFromView(temp_view_id);
   }
   return(status);
}

int _OnUpdate_vcdiff(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCDIFF));
}
_command int vcdiff(_str filename='') name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_DIFF;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   status := 0;
   treewid := 0;
   _str Files[]=null;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"diff");
      filename=Files[0];
   }else if (filename=='') {
      filename=p_buf_name;
   }
   OutputDisplayClear();
   vcs := svc_get_vc_system();
   if (machine()=='WINDOWS' && _isscc(vcs)) {
      status=_SccDiff(filename);
      if (status==SCC_I_FILEDIFFERS) {
         _message_box(nls("Files do not match"));
      }else if (status) {
         _message_box(nls(vcget_message(status)));
      }
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      svc_diff_with_tip(filename);
   }else{
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      status=_misc_cl_vc_command(VCS_DIFFERENCE,temp_view_id,_maybe_quote_filename(filename),vcs,1);
      //show('-modal _vc_error_form',temp_view_id,'','Differences for 'filename);
      DisplayOutputFromView(temp_view_id);
   }
   return(status);
}

int _OnUpdate_vcsetup(CMDUI &cmdui,int target_wid,_str command)
{
   if (command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCREMOVE));
}

//10:38am 4/12/1999
//Adding arguments to this so you can do this automatically from a project
//usage:
//vcsetup [-type <scc|cl> -system <sysname> -localpath <localpath> -project <projname>]
//
//For the time being, all three arguments must be specified, and -project
//must be last.
_command int vcsetup(typeless arg1="") name_info(','NCW_ARG2|ICON_ARG2|READ_ONLY_ARG2|CMDLINE_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return config('_vc_select_form', 'D', arg1, true);
}

int _OnUpdate_vcremove(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCREMOVE));
}
_command int vcremove(_str filename='', bool RemoveFromProjectDone=false) name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_REMOVE;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   _str Files[];
   PassedFilename := filename!='';
   RemoveFromProject := 0;
   treewid := 0;
   typeless status=0;
   typeless result=0;
   if (!PassedFilename && p_name!=PROJECT_TREE_NAME) {
      status=vc_prompt_for_filenames(Files,VSSCC_COMMAND_REMOVE);
      if (status) return(status);
   }else if (!PassedFilename && p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"remove");
   }else{
      Files[0]=filename;
   }
   if (!RemoveFromProjectDone) {
      result=_message_box(nls("Remove these files from the project %s also?",_project_name),'',MB_YESNOCANCEL);
      if (result==IDYES) {
         RemoveFromProject=1;
      }else if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   if (!Files._length() && filename=='') {
      if (!_isEditorCtl()) {
         return(FILE_NOT_FOUND_RC);
      }
      filename=p_buf_name;
   }else if (!Files._length() && filename!=''){
      Files[0]=filename;
   }
   OutputDisplayClear();

   vcs := _GetVCSystemName();
   i := 0;
   if (machine()=='WINDOWS' && _isscc(vcs)) {
      status=_SccRemove(Files,'');
      if (status) {
         _message_box(nls(vcget_message(status)));
      }
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      status=svc_remove(filename);
   }else{
      for (i=0;i<Files._length();++i) {
         filename=Files[i];
         temp_view_id := 0;
         int orig_view_id=_create_temp_view(temp_view_id);
         p_window_id=orig_view_id;
         status=_misc_cl_vc_command(VCS_REMOVE,temp_view_id,_maybe_quote_filename(filename),vcs,0);

         if (status || VersionControlSettings.getAlwaysShowOutput(vcs)) {
            DisplayOutputFromView(temp_view_id);
         }else{
            _delete_temp_view(temp_view_id);
         }
      }
   }
   UpdateOptions := "";
   if (_project_name!='') {
      for (i=0;i<Files._length();++i) {
         filename=Files[i];
         if (RemoveFromProject) {
            project_remove_filelist(_project_name,_maybe_quote_filename(filename));
         }
      }
   }
   for (i=0;i<Files._length();++i) {
      filename=Files[i];
      UpdateProjectTree(filename);
      _UpdateBufferReadOnlyStatus(filename);
   }
   if ( p_active_form.p_name!="_tbprojects_form" &&
        p_name!="_proj_tooltab_tree" ) {
      // If we are in the tree, there is no reason to relist the tree.
      // Also, we don't want to because we would lose the selection
      toolbarUpdateWorkspaceList();
   }
   return(status);
}

int _OnUpdate_vchistory(CMDUI &cmdui,int target_wid,_str command)
{
   if (svc_get_vc_system()==''||command=='') {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCHISTORY));
}
_command int vchistory(_str filename='') name_info(','READ_ONLY_ARG2|EDITORCTL_ARG2|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return(VSRC_FEATURE_REQUIRES_PRO_EDITION);
   }
   gCurrentCommand=VSSCC_COMMAND_HISTORY;
   if (machine()=='WINDOWS' && _isscc()) _SccGetCommandOptions(-1);
   status := 0;
   treewid := 0;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      //GetFileListFromTree(Files,"view history");
      _str cap=_TreeGetCaption(_TreeCurIndex());
      parse cap with auto name "\t" filename;
      filename=_AbsoluteToWorkspace(filename);
   }else if (filename=='') {
      if (!_isEditorCtl()) {
         return(FILE_NOT_FOUND_RC);
      }
      filename=p_buf_name;
   }
   OutputDisplayClear();
   vcs := svc_get_vc_system(filename);
   if (machine()=='WINDOWS' && _isscc(vcs)) {
      status=_SccHistory(filename);
      if (status==SCC_I_RELOADFILE) {
         edit_and_close_filelist(_maybe_quote_filename(filename));
      }else if (status) {
         _message_box(nls(vcget_message(status)));
      }
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      svc_history(filename);
   }else{
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      status=_misc_cl_vc_command(VCS_HISTORY,temp_view_id,_maybe_quote_filename(filename),vcs,1);
      //show('-modal _vc_error_form',temp_view_id,'','History for 'filename);
      DisplayOutputFromView(temp_view_id);
   }
   return(status);
}

int _OnUpdate_vclock(CMDUI &cmdui,int target_wid,_str command)
{
   filename := getVCFilename();
   //There is no SccLock command, so if we are using an SCC system
   vcs := svc_get_vc_system();
   if (vcs==''||command==''||
       (_isscc(vcs) && machine()=='WINDOWS') ) {
      return(MF_GRAYED);
   }
   return(_OnUpdateVCCommand(cmdui,target_wid,command,VCLOCK));
}
_command int vclock(_str filename='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   treewid := 0;
   status := 0;
   _str Files[]=null;
   if (p_name==PROJECT_TREE_NAME) {
      treewid=p_window_id;
      GetFileListFromTree(Files,"lock");
      filename=Files[0];
   }else if (filename=='') {
      if (!_isEditorCtl()) {
         return(FILE_NOT_FOUND_RC);
      }
      filename=p_buf_name;
   }
   OutputDisplayClear();
   vcs := svc_get_vc_system();
   if (_isscc(vcs) && machine()=='WINDOWS') {
      //Should not get here
      //There is no SccLock for me to call, and I gray the menu item
      _message_box(nls("This option is not supported for %s",substr(vcs,SCC_PREFIX_LENGTH+1)));
      return(0);
   }else if ( _VCIsSpecializedSystem(vcs) ) {
      // Nothing to do
   }else{
      temp_view_id := 0;
      int orig_view_id=_create_temp_view(temp_view_id);
      p_window_id=orig_view_id;
      status=_misc_cl_vc_command(VCS_LOCK,temp_view_id,filename,vcs,0);

      if (status || VersionControlSettings.getAlwaysShowOutput(vcs)) {
         DisplayOutputFromView(temp_view_id);
      }else{
         _delete_temp_view(temp_view_id);
      }
      return(status);
   }
   UpdateProjectTree(filename);
   _UpdateBufferReadOnlyStatus(filename);
   return(status);
}

/*
returns 1 if the current file is controlled by version control for the
current vc project

Filname MUST BE FULLY QUALIFIED

Only works properly for SCC, for all others, returns 1
*/
int _FileUnderVC(_str Filename)
{
   vcs := svc_get_vc_system();
   if (vcs=='') {
      return(0);
   }
   if (!_isscc(vcs) || machine()!='WINDOWS') {
      return(1);
   }
   if (!machine()=='WINDOWS') {
      return(0);
   }
   _str Files[];
   Files[0]=p_buf_name;
   Checkin := 0;
   Checkout := 0;
   Get := 0;
   typeless status=_SccPopulateList(VSSCC_COMMAND_GET,Files,1);
   if (Files._length()) {
      //We are only depopulating the list, so if there is anything left, it
      //has to be under version control
      return(1);
   }
   return(0);
}

#region Options Dialog Helper Functions

defeventtab _vc_setup2_form;

// Take a value but return a pointer to the value
static typeless *PTR_ORIG_COMMAND_TABLE(...) {
   if (arg()) ctlcommand_line.p_user=arg(1);
   return &ctlcommand_line.p_user;
}
// Take a value but return a pointer to the value
static typeless *PTR_CURRENT_COMMAND_TABLE(...) {
   if (arg()) list1.p_user=arg(1);
   return &list1.p_user;
}
static _str CURRENT_COMMAND(...) {
   if (arg()) label2.p_user=arg(1);
   return label2.p_user;
}

void _vc_setup2_form_init_for_options(_str provID)
{
   _set_language_form_vc_provider_id(provID);

   _str CommandTable:[];
   VersionControlSettings.getCommandTable(provID, CommandTable);
   PTR_CURRENT_COMMAND_TABLE(CommandTable);

   list1._lbtop();
   list1._lbselect_line();
   list1.call_event(CHANGE_SELECTED, list1, ON_CHANGE, 'W');

   ctlok.p_visible = ctlcancel.p_visible = ctlhelp.p_visible = false;
}

void _vc_setup2_form_save_settings()
{
   PTR_ORIG_COMMAND_TABLE(*PTR_CURRENT_COMMAND_TABLE());
}

bool _vc_setup2_form_is_modified()
{
   updateCommandTable();

   // compare the tables, see if anything has changed
   _str commandKey, commandText;
   foreach (commandKey => commandText in *PTR_CURRENT_COMMAND_TABLE()) {
      if (PTR_ORIG_COMMAND_TABLE()->:[commandKey] != commandText) return true;
   }

   return false;
}

bool _vc_setup2_form_apply()
{
   provID := _get_language_form_vc_provider_id();
   VersionControlSettings.setCommandTable(provID, *PTR_CURRENT_COMMAND_TABLE());

   vcGetList(gvcEnableList);

   return true;
}

_str _vc_setup2_form_build_export_summary(PropertySheetItem (&table)[], _str provID)
{
   // get a hashtable of commands
   _str CommandTable:[];
   VersionControlSettings.getCommandTable(provID, CommandTable);

   // sort the command titles
   _str commands[];
   foreach (auto commandKey => . in CommandTable) {
      commands[commands._length()] = commandKey;
   }
   commands._sort();

   for (i := 0; i < commands._length(); i++) {
      PropertySheetItem psi;
      psi.Caption = commands[i];
      psi.Value = CommandTable:[psi.Caption];

      table[table._length()] = psi;
   }

   return '';
}

_str _vc_setup2_form_import_summary(PropertySheetItem (&table)[], _str provID)
{
   error := '';

   // make sure this version control provider exists
   if (!VersionControlSettings.isValidProviderID(provID)) {
      VersionControlSettings.addProvider(provID);
   }

   _str CommandTable:[];
   provName := VersionControlSettings.getProviderName(provID);
   VersionControlSettings.getCommandTable(provID, CommandTable);

   PropertySheetItem psi;
   foreach (psi in table) {
      propert_name := lowcase(psi.Caption);
      // we do not import commands that we don't have
      if (CommandTable._indexin(propert_name)) {
         CommandTable:[propert_name] = psi.Value;
      } else {
         error :+= 'Error importing command 'psi.Caption' for version control provider 'provName'.';
      }
   }
   VersionControlSettings.setCommandTable(provID, CommandTable);

   return '';
}

#endregion Options Dialog Helper Functions

void list1.on_create()
{
   _vc_setup2_form_initial_alignment();

   foreach (auto command=>auto value in _vc_commands) {
      list1._lbadd_item(_Capitalize(command));
   }

   list1._lbsort();
   list1._lbtop();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _vc_setup2_form_initial_alignment()
{
   rightAlign := p_active_form.p_width - label2.p_x;
   sizeBrowseButtonToTextBox(ctlcommand_line.p_window_id, ctlremenu.p_window_id, 0, rightAlign);
}

void _set_language_form_vc_provider_id(_str provID, int wid = 0)
{
   _SetDialogInfoHt('vcProviderID', provID, wid);
}

int _get_language_form_vc_provider_id(int wid = 0)
{
   return _GetDialogInfoHt('vcProviderID', wid);
}

void vcGetList(int (&vcEnableList):[]) {
   vcEnableList._makeempty();
   vcs := _GetVCSystemName();
   {
      foreach (auto key=>auto value in _vc_commands) {
         vcEnableList:[key]=MF_ENABLED;
      }
   }
   if (_isscc(vcs) && machine()=='WINDOWS') {
      vcEnableList:[VCLOCK]=MF_GRAYED;
   }else{
      if ( _SVCIsSVCSystem(vcs) ) {
         vcEnableList:["get"]=MF_ENABLED;
         vcEnableList:["checkout"]=MF_ENABLED;
         vcEnableList:["checkin"]=MF_ENABLED;
         vcEnableList:["unlock"]=MF_GRAYED;
         vcEnableList:["add"]=MF_ENABLED;
         vcEnableList:["lock"]=MF_GRAYED;
         vcEnableList:["remove"]=MF_ENABLED;
         vcEnableList:["history"]=MF_ENABLED;
         vcEnableList:["difference"]=MF_ENABLED;
         vcEnableList:["properties"]=MF_GRAYED;
         vcEnableList:["manager"]=MF_GRAYED;
      } else {
         _str commandTable:[];
         VersionControlSettings.getCommandTable(vcs, commandTable);
         foreach (auto key=>auto value in commandTable) {
            if (strip(value) != '') {
               vcEnableList:[key]=MF_ENABLED;
            } else {
               vcEnableList:[key]=MF_GRAYED;
            }
         }
      }
   }
}

static int gDidSpecializedSystemSetup=0;
definit()
{
   if ( arg(1)!='L' ) {
      gDidSpecializedSystemSetup=0;
   }
   vcGetList(gvcEnableList);
   rc=0;
}

static const DONT_NEED_WID_LIST= 'vccheckin vccheckout vcget vclock vcunlock vcadd';

/*
    WARNING: This function is called from code which assumes that the
    cmdui and command arguments are not used.
*/
int _OnUpdateVCCommand(CMDUI &cmdui,int target_wid,_str command,_str property_name)
{
   if (!_haveVersionControl()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if (_no_child_windows() && command=='vclock') {
      return(MF_GRAYED);
   }
   if ( command=='vcsetup' ) return MF_ENABLED;
   if (!target_wid) {
      if ( !pos(' 'command' ',' 'DONT_NEED_WID_LIST' ') ) {
         return(MF_GRAYED);
      }
      if (!gvcEnableList._indexin(property_name)) {
         return(MF_GRAYED);
      }
      return(gvcEnableList:[property_name]);
   }
   if (target_wid.p_name=='_proj_tooltab_tree') {
      if (!target_wid.IsValidLevel(command)) {
         return(MF_GRAYED);
      }
      if (_workspace_filename=='') {
         return(MF_GRAYED);
      }
      if (!gvcEnableList._indexin(property_name)) {
         return(MF_GRAYED);
      }
      return(gvcEnableList:[property_name]);
   }
   if (target_wid.p_name!=PROJECT_OPENLIST_NAME && !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (!gvcEnableList._indexin(property_name)) {
      return(MF_GRAYED);
   }
   return(gvcEnableList:[property_name]);
}

void ctlok.lbutton_up()
{
   if (_vc_setup2_form_apply() ) {
      p_active_form._delete_window();
   }
}

void list1.on_change(int reason)
{
   // update the table with any changes we made to the text box
   updateCommandTable();

   // puts the correct command in the text box based on our new selection
   CURRENT_COMMAND(lowcase(list1._lbget_text()));
   _str CommandTable:[] = *PTR_CURRENT_COMMAND_TABLE();
   _str temp=CommandTable:[CURRENT_COMMAND()];
   ctlcommand_line.p_text = temp;
}

static void updateCommandTable()
{
   // has the command changed from what we saved?
   _str CommandTable:[] = *PTR_CURRENT_COMMAND_TABLE();

   if (CURRENT_COMMAND() != '' && CommandTable:[CURRENT_COMMAND()] != ctlcommand_line.p_text) {
      CommandTable:[CURRENT_COMMAND()] = ctlcommand_line.p_text;
      PTR_CURRENT_COMMAND_TABLE(CommandTable);
   }
}

bool def_readonly_message;
/**
 * Handle an error where they try to modify or save a read-only
 * buffer.  This hook function will attempt to check out the
 * file or offer other options for the user to complete the operation.
 * 
 * @param KeyPressed
 * @param doAuto        pretend (def_vcflags & VCF_AUTO_CHECKOUT) is set
 * @param enableSaveAs  enable the save as option on the checkout dialog
 * 
 * @return <0 on error, COMMAND_CANCELLED_RC on cancellation, 0 on success
 */
int _readonly_error(_str KeyPressed, 
                    bool doAutoCheckout=false, 
                    bool enableSaveAs=false)
{
   if (isEclipsePlugin()) {
      if (_eclipse_validate_edit(p_buf_name) == 1) {
         // eclipse has already updated the rw attributes on disk
         // all we need to do is set the appropriate property
         p_readonly_mode=false;
         if (KeyPressed == "1") {
            _str lastevent=last_event();
            if (select_active()) {
               _on_select();
            }else{
               call_event(p_window_id,lastevent);
            }
         }
         return(0);
      } 
      // if eclipse did not automatically change the file to writable, this could
      // have been for a number or reasons, so although it results in a double prompt
      // we need to let slickedit do it's thing here...
   }

   status := 0;
   origAuto := doAutoCheckout;
   _str lastevent=last_event();
   int key_index=event2index(lastevent);
   name_index := eventtab_index(_default_keys,p_mode_eventtab,key_index);
   command_name := name_name(name_index);

   vcs := _GetVCSystemName();
   isscc := _isscc(vcs);
   if (def_vcflags & VCF_AUTO_CHECKOUT) {
      if (machine()=='WINDOWS' && isscc) {
         //If the current VCS is an SCC system, we can check to see if the
         //file is in version control
         _str Files[];
         Files._makeempty();
         Files[0]=p_buf_name;
         status=_SccPopulateList(VSSCC_COMMAND_CHECKOUT,Files,1);
         if (Files._length()) {
            //There was only one file in the list, and "depopulate only"
            //was on, so if there are any left, we definitely have a file
            //in version control
            doAutoCheckout=true;
         }
      }else{
         //If the current VCS is not an SCC system, we're flying blind.
         //Have to show them the VCS prompt box and hope for the best
         doAutoCheckout=true;
      }
   }

   if (!doAutoCheckout || !_HaveValidOuputFileName(p_buf_name)) {
      if (def_readonly_message) {
         message(READ_ONLY_ERROR_MESSAGE);_beep();
         return COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC;
      } 

      if (_HaveValidOuputFileName(p_buf_name)) {
         typeless id = show("-modal _read_only_warning_form");
         if (id == '') return COMMAND_CANCELLED_RC;
         if (id == IDYES) doAutoCheckout=true;
         if (id == IDOK) {
            return COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC;
         }
      } else {
         int id = _message_box(READ_ONLY_ERROR_MESSAGE);
         if (id == IDCANCEL) {
            return COMMAND_CANCELLED_RC;
         }
         return COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC;
      }
   }

   status = 0;
   checkout_msg := "";
   enable_flags := -1;
   if (vcs=='CVS') {
      checkout_msg='cvs edit this file';
      enable_flags=ENABLE_SET_WRITEABLE|ENABLE_CHECKOUT;
   }
   if (!enableSaveAs) {
      enable_flags &= ~ENABLE_SAVE_AS;
   }

   do {
      if ( _isdiffed(p_buf_id) ) {
         _message_box(nls("Cannot modify '%s' because it is being diffed",p_buf_name));
         status = 1;break;
      }
      typeless result;
      if ( isscc && (def_vc_advanced_options&VC_ADVANCED_NO_PROMPT) ) {
         result = CHECKOUT;
      }else{
         result=show('-modal _vc_checkout_form',p_buf_name' is read only',checkout_msg,'','',enable_flags);
         if (result=='') {
            return COMMAND_CANCELLED_RC;
         }
      }
   
      if (_haveVersionControl() && result==CHECKOUT) {
            // Check for modern interface, then call edit if we have it
            IVersionControl *pInterface = svcGetInterface(def_vc_system);
            if ( pInterface!=null && pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT ) {
               svc_edit(p_buf_name);
            } else {
               status=vccheckout(p_buf_name,origAuto,false);
               if (!status) {
                  if (p_file_date ==_file_date(p_buf_name,'B') &&
                      p_buf_size==_filesize(p_buf_name)
                      ) {
                     last_event(lastevent);
                     if (select_active()) {
                        _on_select();
                     }else{
                        call_event(p_window_id,lastevent);
                     }
                  }else{
                     edit_and_close_filelist(p_buf_name);
                     p_file_date = (long)_file_date(p_buf_name,'B');
                  }
               }
#if 0
            // 1:28:29 PM 6/1/2004
            // Going to leave this if0'd for a little while in case anybody 
            // wants to put it back in.  There are a few issues with this, 
            // certain keys it will be difficult to get right, and also 
            // the file could have changed
            if ( !status && command_name!='') {
               command_index=find_index(command_name,COMMAND_TYPE);
               if (index_callable(command_index)) {
                  call_index(command_index);
               }
            }else{
               call_event(p_window_id,lastevent);
            }
   #endif
         }
   
      }else if (_haveVersionControl() && result==GET) {
         status = vcget(p_buf_name);
         if (!status) {
            p_file_date = (long)_file_date(p_buf_name,'B');
         }

      }else if (result==SET_WRITEABLE) {
         if (_isUnix()) {
            status=_chmod('u+w '_maybe_quote_filename(p_buf_name));
            if (status) {
               _message_box('Unable to update user write permissions for: '_strip_filename(p_buf_name, 'P'));
            }
         } else {
            status=_chmod('-r '_maybe_quote_filename(p_buf_name));
            if (status) {
               _message_box('Unable to update read only attribute for: '_strip_filename(p_buf_name, 'P'));
            }
         }

         // if we were successful, then update the mode
         if (!status) p_readonly_mode=false;

      }else if (result==SAVE_AS) {
         status = gui_save_as();
      }
   } while ( false );

   // looks like we were successful
   return status;
}

/**
 * This is a callback called from C-code. DO NOT CALL THIS 
 * FUNCITON DIRECTLY.  Call _readonly_error() instead.
 */
int _on_readonly_error(_str KeyPressed)
{
   if (isEclipsePlugin()) {
      if (_eclipse_validate_edit(p_buf_name) == 1) {
         // eclipse has already updated the rw attributes on disk
         // all we need to do is set the appropriate property
         p_readonly_mode=false;
         if (KeyPressed == "1") {
            _str lastevent=last_event();
            if (select_active()) {
               _on_select();
            }else{
               call_event(p_window_id,lastevent);
            }
         }
         return(0);
      } 
      // if eclipse did not automatically change the file to writable, this could
      // have been for a number or reasons, so although it results in a double prompt
      // we need to let slickedit do it's thing here...
   }

   // Call maybe_set_readonly - it could be that file was set to read only because
   // it was locked, and it no longer is.
   maybe_set_readonly();
   if ( !_QReadOnly() ) {
      // maybe_set_readonly shut off read only mode.  Get the 
      // key the user pressed back
      _str lastevent=last_event();
      if (select_active()) {
         _on_select();
      }else{
         call_event(p_window_id,lastevent);
      }
      return 0;
   }

   index := find_index('_on_readonly_error2',PROC_TYPE);
   if (index_callable(index)) {
      status := call_index(KeyPressed,index);
      if (!status) {
         return COMMAND_NOT_ALLOWED_IN_READ_ONLY_MODE_RC;
      }
   }
   return _readonly_error(KeyPressed,false,false);
}

int vc_make_file_writable(_str filename)
{
   inmem := false;
   temp_view_id := 0;
   orig_view_id := 0;
   int status = _open_temp_view(filename, temp_view_id, orig_view_id, '+l', inmem);
   if (status < 0) {
      return status;
   }

   if (_QReadOnly()) {
      int orig_actapp=def_actapp;
      def_actapp=0;
      status = _readonly_error(0,true);
      def_actapp=orig_actapp;
   }

//   if (!inmem) quit(false,true);
   _delete_temp_view(temp_view_id);
   p_window_id = orig_view_id;
   return status;
}

defeventtab _vc_checkout_form;

void ctlok.on_create(_str label_caption='',
                     _str checkout_caption='',
                     _str get_caption='',
                     _str set_writable_caption='',
                     int enable_flags=-1)
{
   label1.p_caption=label_caption"\n\nDo you wish to:";
   if (label1.p_x_extent>ctlok.p_x) {
      int clientwidth=_dx2lx(SM_TWIP,p_active_form.p_client_width);
      int buff=clientwidth-(ctlok.p_x_extent);
      ctlok.p_x=command2.p_x=label1.p_x_extent+buff;
      ctlsetup.p_x=ctlok.p_x_extent-ctlsetup.p_width;
      p_active_form.p_width=ctlok.p_x_extent+buff+(p_active_form.p_width-clientwidth);
   }
   p_active_form.p_caption='SlickEdit';
   if (checkout_caption!='') {
      ctlcheckout.p_caption=checkout_caption;
   }
   if (get_caption!='') {
      ctlget.p_caption=get_caption;
   }
   if (set_writable_caption!='') {
      ctlset_writable.p_caption=set_writable_caption;
   }
   if ( !_haveVersionControl() ) {
      ctlget.p_enabled = false;
      ctlcheckout.p_enabled = false;
      ctlsetup.p_enabled = false;
      
   } else if ( svc_get_vc_system() == '') {
      ctlget.p_enabled = false;
      ctlcheckout.p_enabled = false;
   }
   if (!(enable_flags&ENABLE_CHECKOUT)) {
      ctlcheckout.p_enabled=false;
   }
   if (!(enable_flags&ENABLE_GET)) {
      ctlget.p_enabled=false;
   }
   if (!(enable_flags&ENABLE_SET_WRITEABLE)) {
      ctlset_writable.p_enabled=false;
   }
   if (!(enable_flags&ENABLE_SAVE_AS)) {
      ctlsave_as.p_enabled=false;
   }
}

void ctlok.lbutton_up()
{
   if (ctlcheckout.p_value) {
      p_active_form._delete_window(CHECKOUT);
   }else if (ctlget.p_value) {
      p_active_form._delete_window(GET);
   }else if (ctlset_writable.p_value) {
      p_active_form._delete_window(SET_WRITEABLE);
   }else if (ctlsave_as.p_value) {
      p_active_form._delete_window(SAVE_AS);
   }
}

void ctlsetup.lbutton_up()
{
   optionsWid := vcsetup();
   _modal_wait(optionsWid);
   vcs := svc_get_vc_system();
   ctlget.p_enabled      = (vcs != '');
   ctlcheckout.p_enabled = (vcs != '');
   if (vcs=='CVS') {
      ctlcheckout.p_caption='cvs edit this file';
      ctlget.p_enabled=false;
   }
}

static int VerifyCommand(_str (&InvalidExeNames):[],_str CommandString, bool internalCommandLookup)
{
   if (CommandString==null) {
      return 0;
   }
   _str str=CommandString;
   _str exename=parse_file(str);
   if (exename=='') {
      return(0);
   }

   if (internalCommandLookup) {
      index := find_index(exename,COMMAND_TYPE);
      if (index) {
         return(0);
      }
   }
   _str filename=path_search(exename,'','P');
   if (filename=='') {
      InvalidExeNames:[exename]=exename;
      return(1);
   }
   return(0);
}

static void VerifyVCSExecutables()
{
   vcs := _GetVCSystemName();
   if ( _SVCIsSVCSystem(vcs) ) {
      // Don't check all of these, the cvs setup dialog will chack
      return;
   }
   _str InvalidExeNames:[];

   internalCommandLookup := (VersionControlSettings.getErrorCaptureStyle(vcs) == VCS_ERROR_INTERNAL_LOOKUP);
   _str commands:[];
   VersionControlSettings.getCommandTable(vcs, commands);

   status1 := VerifyCommand(InvalidExeNames, commands:[VCCHECKIN], internalCommandLookup);
   status2 := VerifyCommand(InvalidExeNames, commands:[VCCHECKOUT], internalCommandLookup);
   status3 := VerifyCommand(InvalidExeNames, commands:[VCUNLOCK], internalCommandLookup);
   status4 := VerifyCommand(InvalidExeNames, commands:[VCGET], internalCommandLookup);
   status5 := VerifyCommand(InvalidExeNames, commands:[VCADD], internalCommandLookup);

   if (status1||status2||status3||status4||status5) {
      _str msg=nls("The following executables were not found:\n");
      typeless i;
      for (i._makeempty();;) {
         InvalidExeNames._nextel(i);
         if (i._isempty()) break;
         if (i!='') {
            msg :+= i"\n";
         }
      }
      //Took the blank entries out of here
      if (i!='') {
         msg :+= nls("Version control may not work properly because these executables could not be found.  You may need to add them to your PATH.");
         _message_box(nls(msg));
      }
   }
}
/*
#define VSSCC_STATUS_INVALID          -1L,    // Status could not be obtained, don't rely on it
#define VSSCC_STATUS_NOTCONTROLLED    0x0000L,// File is not under source control
#define VSSCC_STATUS_CONTROLLED       0x0001L,// File is under source code control
#define VSSCC_STATUS_CHECKEDOUT       0x0002L,// Checked out to current user at local path
#define VSSCC_STATUS_OUTOTHER         0x0004L,// File is checked out to another user
#define VSSCC_STATUS_OUTEXCLUSIVE     0x0008L,// File is exclusively check out
#define VSSCC_STATUS_OUTMULTIPLE      0x0010L,// File is checked out to multiple people
#define VSSCC_STATUS_OUTOFDATE        0x0020L,// The file is not the most recent
#define VSSCC_STATUS_DELETED          0x0040L,// File has been deleted from the project
#define VSSCC_STATUS_LOCKED           0x0080L,// No more versions allowed
#define VSSCC_STATUS_MERGED           0x0100L,// File has been merged but not yet fixed/verified
#define VSSCC_STATUS_SHARED           0x0200L,// File is shared between projects
#define VSSCC_STATUS_PINNED           0x0400L,// File is shared to an explicit version
#define VSSCC_STATUS_MODIFIED         0x0800L,// File has been modified/broken/violated
#define VSSCC_STATUS_OUTBYUSER        0x1000L // File is checked out by current user someplace
*/
static int GetBitmapIndex(_str filename,int FileStatus)
{
   //bool ro=IsReadOnly(filename);
   typeless ro=0;
   if (!FileStatus || (FileStatus&VSSCC_STATUS_DELETED)) {
      if (ro) {
         return(_pic_doc_r);
      }else{
         return(_pic_doc_w);
      }
   }
   if (FileStatus & VSSCC_STATUS_CHECKEDOUT) {
      if (ro) {
         return(_pic_vc_co_user_r);
      }else{
         return(_pic_vc_co_user_w);
      }
   }
   if (FileStatus&VSSCC_STATUS_OUTOTHER) {
      if (FileStatus&VSSCC_STATUS_OUTEXCLUSIVE) {
         if (ro) {
            return(_pic_vc_co_other_x_r);
         }else{
            return(_pic_vc_co_other_x_w);
         }
      }else/* if (FileStatus&VSSCC_STATUS_OUTMULTIPLE) */{
         if (ro) {
            return(_pic_vc_co_other_m_r);
         }else{
            return(_pic_vc_co_other_m_w);
         }
      }
   }
   if (FileStatus&VSSCC_STATUS_CONTROLLED &&
       !(FileStatus&VSSCC_STATUS_LOCKED)) {
      if (ro) {
         return(_pic_vc_available_r);
      }else{
         return(_pic_vc_available_w);
      }
   }
   return(-1);
}


static int TreeSearchProject(int ParentIndex,_str filename,_str options)
{
   filename=strip(filename,'B','"');
   if (def_project_show_relative_paths) {
      filename = _RelativeToWorkspace(filename);
   }
   SetBM := false;
   for (;;) {
      if (ParentIndex<0) break;
      int fileIndex=_TreeSearch(ParentIndex,_strip_filename(filename,'p')"\t"filename,_fpos_case'T');
      if (fileIndex>0) {
         //Found one
         if (options=='R') {
            _TreeDelete(fileIndex);
         }else{
            int FileStatus[];
            typeless status=_SccQueryInfo(filename,FileStatus);
            if (!status) {
               bmindex := GetBitmapIndex(filename,FileStatus[0]);
               state := 0;
               _TreeGetInfo(fileIndex,state);
               _TreeSetInfo(fileIndex,state,bmindex,bmindex);
               SetBM=true;
            }
         }
         break;
      }
      ParentIndex=_TreeGetNextSiblingIndex(ParentIndex);
   }
   return((int)(!SetBM));
}

//This function sets a file's bitmap in the project window to the appropriate
//picture according to whether the file is checked out etc.
//The project tree conrol must be active
static void UpdateProjectBitmap(_str filename,_str options='')
{
   pname := GetProjectDisplayName(_project_name);
   if (def_project_show_relative_paths) {
      pname = _RelativeToWorkspace(pname);
   }
   int ParentIndex=_TreeSearch(TREE_ROOT_INDEX,_strip_filename(pname,'P')"\t"pname,_fpos_case't');
   if (ParentIndex<0) {
      return;
   }
   int ProjectParentIndex=ParentIndex;
   int status=TreeSearchProject(ParentIndex,filename,options);
   if (status) {
      //We never set it, look through the whole tree...
      ParentIndex=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if (ParentIndex<0) {
         return;
      }
      for (;;) {
         if (ParentIndex<0) {
            break;
         }
         if (ParentIndex==ProjectParentIndex) {
            ParentIndex=_TreeGetNextSiblingIndex(ParentIndex);
            continue;
         }
         status=TreeSearchProject(ParentIndex,filename,options);
         if (!status) {
            break;
         }
         ParentIndex=_TreeGetNextSiblingIndex(ParentIndex);
      }
   }
}
int getOutputWindowWid(bool forceCreate)
{
   curret_wid := 0;
   current_wid := p_window_id;
   index := find_index('_outputWindow_QFormWID',PROC_TYPE);
   if (index_callable(index)) {
      ret := call_index(forceCreate, index);
      p_window_id = current_wid;
     return ret;
   }
   int retWID = tw_is_visible('_tboutputwin_form');
   _nocheck _control ctloutput;
   if(!forceCreate) {
      p_window_id = current_wid;
      return retWID;
   }
   if(!retWID) {
      int formwid = activate_tool_window('_tboutputwin_form');
      if (!formwid) {
         p_window_id = current_wid;
         return formwid;
      }
      p_window_id = current_wid;
      return formwid;
   }
   p_window_id = current_wid;
   return retWID;
}
int activateOutputWindow(bool DoSetFocus=true)
{
   index := find_index('_outputWindow_activate',PROC_TYPE);
   if (index_callable(index)) {
      ret := call_index(index);
      return ret;
   }
   int formwid = activate_tool_window('_tboutputwin_form', DoSetFocus);
   if ( !formwid || !_iswindow_valid(formwid) ) {
      return 0;
   }
   _nocheck _control ctloutput;
   return formwid.ctloutput;

}
int activateSymbolWindow(bool DoSetFocus=true)
{
   index := find_index('_symbolWindow_activate',PROC_TYPE);
   if (index_callable(index)) {
      ret := call_index(index);
      return ret;
   }
   int formwid = activate_tool_window('_tbtagwin_form', DoSetFocus, 'ctltaglist');
   if ( !formwid ) {
      return 0;
   }
   _nocheck _control edit1;
   return formwid.edit1;

}
int activatePreviewWindow(bool DoSetFocus=true)
{
   index := find_index('_previewWindow_activate',PROC_TYPE);
   if (index_callable(index)) {
      ret := call_index(index);
      return ret;
   }
   return activateSymbolWindow(DoSetFocus);
}
int activateBuildWindow(bool DoSetFocus=true)
{
   index := find_index('_buildWindow_activate',PROC_TYPE);
   if (index_callable(index)) {
      ret := call_index(index);
      return ret;
   }
   int formwid = activate_tool_window('_tbshell_form', DoSetFocus, '_shellEditor');
   if ( !formwid ) {
      return 0;
   }
   _nocheck _control _shellEditor;
   return formwid._shellEditor;
}
/**
 * Append a line of information to the Output tool window.
 * 
 * @param str              message to append 
 * @param clear_buffer     (default false) clear window before adding this message?
 * @param strIsViewId      (default false) 'str' is actually the view ID 
 *                         of a buffer to switch to
 * @param doActivateOutput (default true) activate the Output tool window 
 *                         if it is not already up.
 * 
 * @categories Miscellaneous_Functions
 */
void _SccDisplayOutput(_str str,
                       bool clear_buffer=false,
                       bool strIsViewId=false,
                       bool doActivateOutput=true)
{
   if( isVisualStudioPlugin() ) {
      _maybe_append(str, p_newline);
      vsRefactorOutput(str);
      return;
   }
   /* Due to a crash bug in the new tool window code. Can't display the Output tool window 
      during Auto Restore. The gin_restore variable indicates whether the the code is in auto
      restore.
   */ 
   form_wid := getOutputWindowWid(doActivateOutput && _autoRestoreFinished());
   temp_wid := 0;
   if (!form_wid) {
      if (doActivateOutput) {
         if (_autoRestoreFinished()) {
            // Go ahead and create the .output buffer and output the data to it. 
            // Then activate the Output tool window later.
            orig_wid:=_create_temp_view(temp_wid);
            _str sbuf_id;
            parse buf_match('.output',1,'vhx') with sbuf_id .;
            if ( isinteger(sbuf_id) && sbuf_id != p_buf_id ) {
               _delete_buffer();
               // Since we don't know what buffer is active here,
               // don't save previous buffer currsor location.
               load_files('+m +bi 'sbuf_id);
            } else {
               p_buf_name = ".output";
               p_UTF8 = true;
            }
            p_window_id=orig_wid;

         } else {
            form_wid = activateOutputWindow(false);
            if (form_wid && form_wid.p_object != OI_FORM) form_wid = form_wid.p_active_form;
         }
      }
      if (!form_wid && !temp_wid) return;
      if (temp_wid) {
         temp_wid._delete_line();
      } else {
         output_wid := form_wid._find_control("ctloutput");
         if (!output_wid) return;
         output_wid._delete_line();
      }
   } else {
      activateOutputWindow(false);
   }
   
   // make sure we have output editor control 
   output_wid := temp_wid;
   if (!output_wid) {
      output_wid = form_wid._find_control("ctloutput");
      if (!output_wid || !output_wid._isEditorCtl()) return;
   }

   wid := p_window_id;
   p_window_id =output_wid;
   if (clear_buffer) {
      _lbclear();
   }
   bottom();
   if (strIsViewId) {
      orig_view_id := p_window_id;
      int error_view_id=(int)str;
      p_window_id=error_view_id;
      int markid=_alloc_selection();
      needtocopy := false;
      if (p_Noflines) {
         needtocopy=true;
         top();_select_line(markid);
         bottom();_select_line(markid);
         if (rc) clear_message();
      }
      p_window_id=orig_view_id;
      if (needtocopy) {
         _copy_to_cursor(markid);
      }
      _free_selection(markid);
   /*}else if ((pos("\n",str) || !pos("\r",str)) && p_newline!="\n") {
      // If there is a newline, or no carraige return, AND p_newline is not a
      // newline.  The check for \r is to catch cases where there are no
      for (;;) {
         cur := "";
         parse str with cur "\n" str;
         if (cur=='') break;
         insert_line(cur);
      }*/
   }else{
      // make sure the line has a newline.  do this instead of calling
      // insert_line() so that text containing newlines still works properly
      _maybe_append(str, "\n");
      _insert_text(str);
   }
   refresh();
   p_window_id=wid;
   if (!_no_child_windows() && !temp_wid) {
      _mdi.p_child._set_focus();
   }
   if (temp_wid) {
      _delete_temp_view(temp_wid,false);
      gdelayed_activateOutputWindow=true;
   }
}

void OutputDisplayClear()
{
   int formwid=_find_formobj('_tboutputwin_form','N');
   _nocheck _control ctloutput;
   if (!formwid) {
      return;
   }
   wid := p_window_id;
   p_window_id=formwid.ctloutput;
   _lbclear();
   p_window_id=wid;
}

/**
 * If there are any lines in the view supplied,
 * those lines are displayed in the Output tab on
 * the Output toolbar.  This way, errors from
 * command line version control systems is consistent
 * with SCC systems.
 *
 * @param ViewId View id with output to be displayed
 */
void DisplayOutputFromView(int ViewId)
{
   _SccDisplayOutput(ViewId,true,true);
   _delete_temp_view(ViewId);
}

defeventtab _vc_create_prompt_form;

_str ctlok.lbutton_up()
{
   if (ctlnew.p_value) {
      p_active_form._delete_window('N');
      return('N');
   }
   if (ctlexisting.p_value) {
      p_active_form._delete_window('E');
      return('E');
   }
   return('');
}


defeventtab _vc_advanced_form;

void ctlok.on_create()
{
   ctlok.p_enabled=false;
   _str DialogCaption=arg(1);
   _str OKCaption=arg(2);
   int CurCommand=arg(3);
   if (CurCommand!=VSSCC_COMMAND_ADD) {
      ctlremove.p_visible=false;
      ctlbrowse.p_visible=false;
   }
   switch (CurCommand) {
   case VSSCC_COMMAND_GET:
      ctlhelp.p_help='Get Dialog Box';
      ctlsave.p_visible=false;
      break;
   case VSSCC_COMMAND_CHECKOUT:
      ctlhelp.p_help='Check Out Dialog Box';
      ctlsave.p_visible=false;
      break;
   case VSSCC_COMMAND_CHECKIN:
      ctlhelp.p_help='Check In Dialog Box';
      break;
   case VSSCC_COMMAND_UNCHECKOUT:
      ctlhelp.p_help='Unlock Dialog Box';
      ctlsave.p_visible=false;
      break;
   case VSSCC_COMMAND_ADD:
      ctlhelp.p_help='Add Dialog Box';
      break;
   case VSSCC_COMMAND_REMOVE:
      ctlhelp.p_help='Remove Dialog Box';
      ctlsave.p_visible=false;
      break;
   }
   ctladvanced.p_user=CurCommand;
   p_active_form.p_caption=DialogCaption;
   ctlok.p_caption=OKCaption;

   /*if (machine()!='WINDOWS' || !_isscc() || _SccGetCommandOptions(CurCommand,'T')) {
      ctladvanced.p_enabled=false;
   }*/
   if (machine()=='WINDOWS' && _haveVersionControl() && _isscc() && _SccGetCommandOptions(gCurrentCommand,'T')) {
      //Disable the advanced button
      ctladvanced.p_enabled=false;
   }else if (machine()!='WINDOWS' || !_isscc()) {
      //Disable the advanced button
      ctladvanced.p_enabled=false;
   }
   changed := false;
   if (def_vc_advanced_options& VC_ADVANCED_PROJECT) {
      ctlproject.p_value=1;
      changed=true;
   }
   if (def_vc_advanced_options& VC_ADVANCED_BUFFERS) {
      ctlbuffers.p_value=1;
      changed=true;
   }
   if (machine()!='WINDOWS' || !_isscc() || ctladvanced.p_user==VSSCC_COMMAND_ADD) {
      ctlavailable.p_enabled=false;
      ctlavailable.p_value=0;
   }else{
      if (def_vc_advanced_options& VC_ADVANCED_AVAILABLE) {
         ctlavailable.p_value=1;
         changed=true;
      }
   }
   if (changed) {
      ctlproject.call_event(ctlproject,LBUTTON_UP);
   }
   if (ctlsave.p_visible && !(def_vc_advanced_options&VC_ADVANCED_NO_SAVE_FILES)) {
      ctlsave.p_value=1;
   }
   if (!_no_child_windows()) {
      _str bufname=_mdi.p_child.p_buf_name;
      bufname=_strip_filename(bufname,'P')"\t"_strip_filename(bufname,'N');
      wid := p_window_id;
      _nocheck _control ctlfiletree;
      p_window_id=ctlfiletree;
      int index=_TreeSearch(TREE_ROOT_INDEX,bufname,_fpos_case);
      if (index>=0) {
         _TreeSetCurIndex(index);
         _TreeSelectLine(index);
         call_event(index,ctlfiletree,ON_CHANGE,'W');
      }
      p_window_id=wid;
   }
}

static void InsertFileListIntoTree(int file_list_view_id)
{
   nameWidth := 0;
   pathWidth := 0;
   _str fileName;
   file_list_view_id.top();
   file_list_view_id.up();
   while (!file_list_view_id.down()) {
      file_list_view_id.get_line(fileName);
      name := _strip_filename(fileName,'P');
      path := _strip_filename(fileName,'N');

      int newindex=_TreeAddItem(TREE_ROOT_INDEX,name"\t"path,TREE_ADD_AS_CHILD,0,0,-1,0,fileName);
      int curNameWidth=_text_width(name);
      if (curNameWidth>nameWidth) {
         nameWidth=curNameWidth;
      }
      int curPathWidth=_text_width(path);
      if (curPathWidth>pathWidth) {
         pathWidth=curPathWidth;
      }
   }

   ResizeTree(nameWidth, pathWidth);
}
static void InsertArrayIntoTree(_str Files[])
{
   nameWidth := 0;
   pathWidth := 0;
   int i;
   for (i=0;i<Files._length();++i) {
      _str cur=Files[i];
      name := _strip_filename(cur,'P');
      path := _strip_filename(cur,'N');

      int newindex=_TreeAddItem(TREE_ROOT_INDEX,name"\t"path,TREE_ADD_AS_CHILD,0,0,-1,0,cur);
      int curNameWidth=_text_width(name);
      if (curNameWidth>nameWidth) {
         nameWidth=curNameWidth;
      }
      int curPathWidth=_text_width(path);
      if (curPathWidth>pathWidth) {
         pathWidth=curPathWidth;
      }
   }

   ResizeTree(nameWidth, pathWidth);
}

static void ResizeTree(int nameWidth, int pathWidth)
{
   int curColWidth=_col_width(0);
   if (curColWidth<nameWidth+100) {
      _col_width(0,nameWidth+100);
      curColWidth=_col_width(0);
   }

   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   screen_x := screen_y := screen_width := screen_height := 0;
   p_active_form._GetVisibleScreen(screen_x,screen_y,screen_width,screen_height);
   int maxtreewidth=_dx2lx(SM_TWIP,screen_width)-(client_width-(ctlfiletree.p_x_extent) );
   int minTreeWidth=min(curColWidth+pathWidth+150,maxtreewidth);


   if (minTreeWidth<pathWidth) {
      // Go through the tree and shrink paths as necessary
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      int actual_path_width=minTreeWidth-_col_width(0);
      for (;;) {
         if (index<0) break;
         cap := _TreeGetCaption(index);
         curpath := "";
         curname := "";
         parse cap with curname "\t" curpath;
         if (_text_width(curpath) > actual_path_width) {
            _TreeSetCaption(index,curname"\t":+_ShrinkFilename(curpath,actual_path_width) );
         }
         index=_TreeGetNextIndex(index);
      }
   }

   if (client_width<minTreeWidth) {
      int xbuffer=ctlworkspace.p_x-(ctlfiletree.p_x_extent);

      int diff=ctlfiletree.p_width-_dx2lx(SM_TWIP,ctlfiletree.p_client_width);
      ctlfiletree.p_width=minTreeWidth+diff;

      int newXPos=ctlfiletree.p_x_extent+xbuffer;
      diff=newXPos-ctlworkspace.p_x;
      ctlworkspace.p_x=newXPos;
      ctlproject.p_x=newXPos;
      ctlbuffers.p_x=newXPos;
      ctlavailable.p_x=newXPos;
      ctlsave.p_x=newXPos;
      ctlok.p_x=newXPos;
      ctlok.p_next.p_x=newXPos;
      ctladvanced.p_x=newXPos;
      ctlhelp.p_x=newXPos;
      ctlbrowse.p_x=newXPos;
      ctlremove.p_x=newXPos;
      p_active_form.p_width+=diff;
   }
}

static void InsertProjectList()
{
   if (_project_name=='') {
      return;
   }

   list_view_id := 0;
   orig_view_id := p_window_id;
   int status=GetProjectFiles(_project_name,list_view_id);
   if (status) {
      return;
   }

   p_window_id=orig_view_id;
   InsertFileListIntoTree(list_view_id);
   _delete_temp_view(list_view_id);
   activate_window(orig_view_id);
}

static void InsertWorkspaceList()
{
   if (_workspace_filename=='') {
      return;
   }

   _str ProjectNames[];
   typeless status=_GetWorkspaceFiles(_workspace_filename,ProjectNames);
   if (status) {
      return;
   }

   CreateView := true;
   orig_view_id := p_window_id;
   typeless list_view_id='';
   for (i:=0;i<ProjectNames._length();++i) {
      status=GetProjectFiles(_AbsoluteToWorkspace(ProjectNames[i]),list_view_id,"",null,"",CreateView);
      if (status) continue;
      p_window_id=orig_view_id;
      CreateView=false;
   }

   InsertFileListIntoTree(list_view_id);
   _delete_temp_view(list_view_id);
   activate_window(orig_view_id);
}

static void InsertBufferList()
{
   _str Files[];
   width := 0;
   vc_build_buf_list(width,Files);
   InsertArrayIntoTree(Files);
}

static void GetAllDirectories(_str Path,_str (&Files)[])
{
   _str NewDirs[];
   ff := 1;
   for (ff=1;;ff=0) {
      name := file_match(_maybe_quote_filename(Path)' +d',ff);
      if (name=='') {
         break;
      }
      if (_last_char(name)==FILESEP) {
         tname := substr(name,1,length(name)-1);
         tname=_strip_filename(tname,'P');
         if (tname=='.' || tname=='..') {
            continue;
         }
         Files[Files._length()]=name;
         NewDirs[NewDirs._length()]=name;
      }
   }
   int i;
   for (i=0;i<NewDirs._length();++i) {
      GetAllDirectories(NewDirs[i],Files);
   }
}

static void InsertAvailableList(int Command)
{
   if (!_haveVersionControl()) {
      return;
   }

   _str Files[];

   GetAllDirectories(_SccGetCurProjectInfo(VSSCC_LOCAL_PATH),Files);
   typeless status=_SccPopulateList(Command,Files,2);
   if (status) {
      return;
   }
   int i;
   for (i=0;i<Files._length();++i) {
      if (_last_char(Files[i])==FILESEP) {
         Files._deleteel(i);
         --i;
      }
   }
   InsertArrayIntoTree(Files);
}

void ctlproject.lbutton_up()
{
   wid := p_window_id;
   _control ctlfiletree;
   p_window_id=ctlfiletree;
   _TreeDelete(TREE_ROOT_INDEX,'C');
   if (ctlproject.p_value) {
      mou_hour_glass(true);
      InsertProjectList();
      mou_hour_glass(false);
   }
   if (ctlworkspace.p_value) {
      mou_hour_glass(true);
      InsertWorkspaceList();
      mou_hour_glass(false);
   }
   if (ctlbuffers.p_value) {
      mou_hour_glass(true);
      InsertBufferList();
      mou_hour_glass(false);
   }
   if (ctladvanced.p_user!=VSSCC_COMMAND_ADD &&
       ctlavailable.p_value && ctlavailable.p_enabled) {
      mou_hour_glass(true);
      InsertAvailableList(ctladvanced.p_user);
      mou_hour_glass(false);
   }
   typeless Files=ctlbrowse.p_user;
   if (Files._varformat()==VF_ARRAY) {
      InsertArrayIntoTree(Files);
   }
   _TreeSortCaption(TREE_ROOT_INDEX,'UF'_fpos_case);
   FirstChildIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   if (FirstChildIndex>=0) {
      _TreeSetCurIndex(FirstChildIndex);
   }
   p_window_id=wid;
}

void ctlok.lbutton_up()
{
   wid := p_window_id;
   p_window_id=_control ctlfiletree;
   _str Files[];
   int ff;
   int info;
   for (ff=1;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index<0) {
         break;
      }
      /*caption=_TreeGetCaption(index);
      parse caption with name "\t" path;
      Files[Files._length()]=path:+name;*/
      Files[Files._length()]=_TreeGetUserInfo(index);
   }
   flags := 0;
   if (ctlproject.p_value) {
      flags|=VC_ADVANCED_PROJECT;
   }
   if (ctlbuffers.p_value) {
      flags|=VC_ADVANCED_BUFFERS;
   }
   if (ctlavailable.p_value) {
      flags|=VC_ADVANCED_AVAILABLE;
   }
   if (ctlsave.p_visible && !ctlsave.p_value) {
      flags|=VC_ADVANCED_NO_SAVE_FILES;
   }
   def_vc_advanced_options=flags;
   _param1=Files;
   _param2=(bool)(ctlsave.p_value==1);
   p_window_id=wid;
   p_active_form._delete_window(0);
}

void ctladvanced.lbutton_up()
{
   if (isinteger(ctladvanced.p_user) && machine()=='WINDOWS' && _haveVersionControl()) {
      _SccGetCommandOptions(ctladvanced.p_user);
   }
}

void ctlfiletree.on_change(int index)
{
   if (_TreeGetNumSelectedItems()) {
      ctlok.p_enabled=true;
   }else{
      ctlok.p_enabled=false;
   }
}


void ctlfiletree.ENTER()
{
   ctlok.call_event(ctlok,ENTER);
}

void ctlbrowse.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                      'Add Files',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      'All Files ('ALLFILES_RE')',       // File Type List
                      OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                      ''
                      );
   if (result=='') {
      return;
   }
   _str Files[];
   Files=ctlbrowse.p_user;
   if (Files._varformat()!=VF_ARRAY) {
      Files._makeempty();
   }
   for (;;) {
      _str cur=parse_file(result);
      if (cur=='') {
         break;
      }
      Files[Files._length()]=cur;
   }
   ctlbrowse.p_user=Files;
   wid := p_window_id;
   p_window_id=ctlfiletree;
   InsertArrayIntoTree(Files);
   _TreeSortCaption(TREE_ROOT_INDEX,'UF'_fpos_case);
#if 0 //11:50am 3/4/1999
   for (i=0;i<Files._length();++i) {
      curfilename=Files[i];
      curfilename=strip_filename(curfilename,'P')"\t"strip_filename(curfilename,'N');
      index=_TreeSearch(TREE_ROOT_INDEX,curfilename,_fpos_case);
      if (index>=0) {
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_SELECTED);
      }
   }
#endif
   p_window_id=wid;
}

void ctlremove.lbutton_up()
{
   _str Files[];
   Files=ctlbrowse.p_user;
   if (Files._varformat()!=VF_ARRAY) {
      Files._makeempty();
   }
   wid := p_window_id;
   p_window_id=ctlfiletree;
   int IndexesToDelete[];
   i := 0;
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if (index<0) {
         break;
      }
      cur := _TreeGetCaption(index);
      filename := path := "";
      parse cur with filename path;
      filename=path:+filename;
      for (i=0;i<Files._length();++i) {
         if (_file_eq(Files[i],filename)) {
            Files._deleteel(i);
            IndexesToDelete[IndexesToDelete._length()]=index;
            --i;
            break;
         }
      }
   }
   ctlbrowse.p_user=Files;
   for (i=0;i<IndexesToDelete._length();++i) {
      _TreeDelete(IndexesToDelete[i]);
   }
   p_window_id=wid;
}

void _SetVCSystemName(_str SystemName, bool setConfigModify=true)
{
   if (def_vc_system!=SystemName && setConfigModify) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   def_vc_system=SystemName;
}

_str _GetVCSystemName()
{
   return(def_vc_system);
}

#if 0 //2:41pm 4/12/2017
static int SwapMenuCaptions(_str CurCap,_str NewCap)
{
   SwapMDIMenuCaptions(CurCap,NewCap);
   index := find_index('_ext_menu_default',OBJECT_TYPE);
   if (index) {
      SwapResourceMenuCaptions(CurCap,NewCap,index.p_child);
   }
   index=find_index('_projecttb_menu',OBJECT_TYPE);
   if (index) {
      SwapResourceMenuCaptions(CurCap,NewCap,index.p_child);
   }
   return(0);
}
#endif

static int SwapMDIMenuCaptions(_str CurCap,_str NewCap)
{
   vc_menu_handle := 0;
   itempos := 0;
   typeless status=_menu_find(_mdi.p_menu_handle, "vccheckin", vc_menu_handle,itempos, "M");
   if (status) {
      return(status);
   }
   flags := 0;
   caption := "";
   _menu_get_state(_mdi.p_menu_handle,itempos,flags,'p',caption);
   if (caption==CurCap) {
      _menu_set_state(_mdi.p_menu_handle,itempos,flags,'p',NewCap);
   }
   return(0);
}

static int SwapResourceMenuCaptions(_str CurCap,_str NewCap,int index)
{
   if (!index) {
      return(-1);
   }
   int firstindex=index;
   for (;;) {
      int childindex=index.p_child;
      if (childindex) {
         SwapResourceMenuCaptions(CurCap,NewCap,childindex);
      }
      if (index.p_caption==CurCap) {
         index.p_caption=NewCap;
      }
      index=index.p_next;
      if (index==firstindex) {
         break;
      }
   }
   return(0);
}

static void GetAbsoluteFilenameFromWorkspace(_str &filename,int index)
{
   int wkspace_index=index;
   for (;;) {
      if (_projecttbIsWorkspaceNode(wkspace_index)) break;
      wkspace_index=_TreeGetParentIndex(wkspace_index);
   }
   wkspace_filename := _TreeGetCaption(wkspace_index);
   filename=_AbsoluteToWorkspace(filename,wkspace_filename);
}

static _str GetFilenameFromBuffer()
{
   if (_no_child_windows()) {
      return('');
   }else{
      return(p_buf_name);
   }
   return('');
}

static int DeleteVCMenuItem(_str menu_caption,int vc_menu_handle,int vc_item_pos)
{
   new_output_handle := 0;
   new_item_pos := 0;
   typeless status=_menu_find(vc_menu_handle,menu_caption,new_output_handle,new_item_pos,'M');
   if (!status) {
      _menu_delete(new_output_handle,new_item_pos);
   }
   return(status);
}

static int ChangeVCMenuItem(_str command_name,int vc_menu_handle,int vc_item_pos,
                             _str new_caption,_str new_command,int flags=MF_ENABLED)
{
   new_output_handle := 0;
   new_item_pos := 0;
   typeless status=_menu_find(vc_menu_handle,command_name,new_output_handle,new_item_pos,'M');
   if (!status) {
      status=_menu_set_state(new_output_handle,new_item_pos,flags,'P',new_caption,new_command);
      _menu_info(new_output_handle,'R');   // Redraw menu bar
   }
   return(status);
}

/**
 * Gets a prefix for command names for a given system.  Currently this function 
 * only supports CVS and Subversion
 * @param system_name name of version control system to get prefix for.
 * @return command prefix for version control specified by <i>system_name</i>
 */
static _str GetVCCommandPrefix(_str system_name)
{
   switch (lowcase(system_name)) {
   case 'cvs':
      return('cvs_');
   case 'subversion':
      return('svn_');
   case 'git':
      return('git_');
   case 'mercurial':
      return('hg_');
   }
   return('');
}

/**
 * Gets a command name for <i>vccommand</i> that is specific to <i>system_name</i>
 * @param vccommand command to find
 * @param system_name name of version control system to find this for.  Has to
 *        be supported by GetVCCommandPrefix
 * @return name of the command for the system specified
 */
static _str GetVCSpecificName(_str vccommand,_str system_name)
{
   _str command_name=GetVCCommandPrefix(system_name):+vccommand;
   return(command_name);
}

/**
 * Translate the CVS_HELP_MESSAGE_* constants to other systems. CURRENTLY ONLY 
 * SUPPORTS SUBVERSION
 * @param msg Message to translate
 * @param system_name name of the version control system to translate the message to
 * @return Translated message, or '' if an unsupported <i>system_name</i> is passed in
 */
static _str GetVCSpecificMessage(_str msg,_str system_name)
{
   switch (lowcase(system_name)) {
   case 'subversion':
      return(stranslate(msg,'Subversion','CVS','i'));
   }
   return('');
}

void _on_popup_vc(_str menu_name,int menu_handle)
{
   int oldsetup=gDidSpecializedSystemSetup;
   gDidSpecializedSystemSetup=0;
   _init_menu_vc(menu_handle,_no_child_windows(),true);
   gDidSpecializedSystemSetup=oldsetup;
}

/**
 * Returns true if this is a system that we specialize the menus for (currently CVS and Subversion)
 * @param system_name Name of version control system to check
 * @return Returns true if this is a system that we specialize the menus for
 */
bool _VCIsSpecializedSystem(_str system_name)
{
   switch (lowcase(system_name)) {
   case 'subversion':
   case 'perforce':
   case 'cvs':
   case 'git':
   case 'mercurial':
      return(true);
   default:
      return(false);
   }
}

void _init_menu_vc(int menu_handle,int no_child_windows,bool is_popup_menu=false)
{
   filename := "";
   if ( _isEditorCtl() ) {
      filename=GetFilenameFromBuffer();
   }else if (p_object==OI_TREE_VIEW) {
      index := _TreeCurIndex();
      cap := _TreeGetCaption(index);
      if (_projecttbIsWorkspaceNode(index)) {
         filename=cap;
      }else{
         parse cap with . "\t" filename;
         filename = _AbsoluteToWorkspace(filename);
      }
#if 0 //5:27pm 5/4/2017
      if ( def_project_show_relative_paths || _projecttbIsProjectNode(index,true)) {
         GetAbsoluteFilenameFromWorkspace(filename,index);
      }
#endif
   }

   vcs := lowcase(svc_get_vc_system(filename));
   vcSubmenuPos := 0;
   subhandle := 0;
   toolsSubhandle := 0;

   if ( is_popup_menu ) {
      toolsSubhandle=menu_handle;
   }else{
      // if this is not a pop-up, then Version Control is found under Tools
      _menu_find_loaded_menu_caption(menu_handle,"Tools",toolsSubhandle);
   }


   if ( toolsSubhandle>=0 ) {
      int in_subhandle=toolsSubhandle;
      vcSubmenuPos=_menu_find_loaded_menu_caption_prefix(toolsSubhandle,"Version Control",subhandle);
      if (vcSubmenuPos>=0 && !_haveVersionControl()) {
         _menu_delete(in_subhandle,vcSubmenuPos);
         _menuRemoveExtraSeparators(in_subhandle,vcSubmenuPos);
         vcSubmenuPos=_menu_find_loaded_menu_caption_prefix(toolsSubhandle,"Shelves",subhandle);
         if (vcSubmenuPos>=0 && !_haveVersionControl()) {
            _menu_delete(in_subhandle,vcSubmenuPos);
         }
         return;
      }
   }

   if ( vcSubmenuPos<0 ) {
      return;
   }

   menuCap := "&Version Control";
   if ( vcs!="" ) {
      vcs = svc_get_vc_system(filename);
      isscc := _isscc(vcs);
      if ( substr(vcs,1,4)=="SCC:" ) {
         vcs=substr(vcs,5);
      }
      if ( isscc ) {
         menuCap :+=  " ("vcs "(SCC))";
      } else{
         menuCap :+=  " ("vcs")";
      }
   }
   status := _menu_set_state(toolsSubhandle,vcSubmenuPos,0,'p',menuCap);

   // delete all the submenu items so we can add them back in an 
   // exciting and dynamic sort of way
   for (;;) {
      status=_menu_delete(subhandle, 0);
      if ( status ) break;
   }
   numberOfItemsOnMenu := 0;
   if ( _VCIsSpecializedSystem(vcs) ) {
      SetupMenuForSpecializedSystem(subhandle,vcs,filename,numberOfItemsOnMenu);
   }else{
      SetupMenuForNonSpecializedSystem(subhandle,numberOfItemsOnMenu);
   }
   index := find_index("_oem_vc_menu_callback",PROC_TYPE);
   if ( index ) {
      call_index(subhandle,numberOfItemsOnMenu,index);
   }
   // Call for eaach comand/caption change
   //_menu_set_binding(menu_handle);
}

#define CVS_HELP_MESSAGE_COMMIT nls('Commit a file in CVS')
#define CVS_HELP_MESSAGE_CHECKOUT nls('Check out a CVS module')
#define CVS_HELP_MESSAGE_ADD nls('Add a file to CVS')
#define CVS_HELP_MESSAGE_REMOVE nls('Remove a file from CVS')
#define CVS_HELP_MESSAGE_REVERT nls('Revert a file to the repository version')
#define CVS_HELP_MESSAGE_HISTORY nls('View the CVS history for a file')
#define CVS_HELP_MESSAGE_QUERY nls('Query CVS about a file')
#define CVS_HELP_MESSAGE_DIFF nls('Diff a file with the most up to date version in CVS')
#define CVS_HELP_MESSAGE_COMMIT_SET nls('Show the commit sets dialog')
#define CVS_HELP_MESSAGE_ADD_TO_CURRENT_COMMIT_SET nls('Add this file to the current commit set')
#define CVS_HELP_MESSAGE_LOGIN nls('Show the CVS Login dialog')

void _CVSAddTreeMenu(int vc_menu_handle)
{
   vcs := lowcase(svc_get_vc_system());
   index := _TreeCurIndex();
   filename := "";
   cap := _TreeGetCaption(index);
   if (_projecttbIsWorkspaceNode(index)) {
      filename=cap;
   }else{
      parse cap with . "\t" filename;
   }
   if (_projecttbIsProjectNode(index,true)) {
      GetAbsoluteFilenameFromWorkspace(filename,index);
   }
   just_name := _strip_filename(filename,'P');
   typeless status=_menu_insert(vc_menu_handle,-1,MF_ENABLED,"Comm&it "just_name"...",GetVCSpecificName("commit",vcs)' '_maybe_quote_filename(filename),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_COMMIT,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,"Check &Out Module...",GetVCSpecificName("checkout_module",vcs),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_CHECKOUT,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);

   MaybeAddUpdate(vc_menu_handle,index);

   is_project_file := _projecttbIsProjectNode(index,true);
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,"&Add "just_name,GetVCSpecificName("add",vcs)" "_maybe_quote_filename(filename),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_ADD,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'&Remove 'just_name,GetVCSpecificName("remove",vcs)' '_maybe_quote_filename(filename),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_REMOVE,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,"&History for "just_name,GetVCSpecificName("history",vcs)' '_maybe_quote_filename(filename),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_HISTORY,vcs));
   //_menu_insert(vc_menu_handle,-1,MF_ENABLED,"&Query CVS about "filename,'cvs_query '_maybe_quote_filename(filename),'','help subversion',CVS_HELP_MESSAGE_QUERY);
   ro_opt := "";
   if (is_project_file) {
      ro_opt='-readonly';
   }
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'&Diff 'just_name' with most up to date version',GetVCSpecificName("diff_with_tip",vcs)' 'ro_opt' '_maybe_quote_filename(filename),'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_DIFF,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'Commi&t sets...',"commit_sets",'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_COMMIT_SET,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'Add 'just_name' to current commit set...','cvs_add_to_current_commit_set 'filename,'','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_ADD_TO_CURRENT_COMMIT_SET,vcs));
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
   if ( vcs=='cvs' ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'CVS &Login...','cvs_login','','help subversion',GetVCSpecificMessage(CVS_HELP_MESSAGE_LOGIN,vcs));
   }
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'&Setup...','vcsetup','','help subversion','Allows you to choose and configure a Version Control System interface');
}

static void MaybeAddUpdate(int vc_menu_handle,int tree_cur_index)
{
   vcs := lowcase(svc_get_vc_system());
   // Figure out what the project directory is
   int pindex=tree_cur_index;
   project_path := "";
   project_name := "";
   int file_index=tree_cur_index;
   if (_projecttbIsProjectFileNode(file_index)) {
      file_name := "";
      parse _TreeGetCaption(pindex) with "\t" file_name;
     file_name=_strip_filename(file_name,'P');
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,"Update "file_name,GetVCSpecificName("update",vcs)' 'file_name,'','help cvs','Update a file');
   }
   if (_projecttbIsWorkspaceNode(pindex)) {
      // We'll use this.
      project_name=_TreeGetCaption(pindex);
      project_path=_file_path(project_name);
   }else{
      for (;pindex>0;) {
         if (_projecttbIsProjectNode(pindex,true)) break;
         pindex=_TreeGetParentIndex(pindex);
      }
      // Double check to be sure we found something
      if (_projecttbIsProjectNode(pindex,true)) {
         parse _TreeGetCaption(pindex) with "\t" project_name;

         GetAbsoluteFilenameFromWorkspace(project_path,pindex);

         project_path=_ProjectGet_WorkingDir(_ProjectHandle());
         project_path=absolute(project_path,_file_path(project_name));
         _maybe_append_filesep(project_path);
      }
   }
   if (project_path!='') {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,"Update "project_name,GetVCSpecificName("update",vcs)' 'project_name,'','help cvs','Update this file');
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,"Update "project_path" ...",GetVCSpecificName("gui_mfupdate",vcs)' -r 'project_path,'','help cvs','Update a directory tree');
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
   }
}

static void SetupMenuForSpecializedSystem(int vc_menu_handle,_str system_name,_str cur_bufname,
                                          int &numberOfItemsOnMenu)
{

   SVCMenuSetup(cur_bufname,vc_menu_handle,auto count,system_name);
   numberOfItemsOnMenu=count;
}

/**
 * Gets the original VC menu resource and copies it into the Version Control submenu
 * @param int vc_menu_handle Handle of Version Control submenu
 */
static void SetupMenuForNonSpecializedSystem(int vc_menu_handle,int &numberOfItemsOnMenu)
{
   int menu_handle=find_index("_mdi_menu",oi2type(OI_MENU));
   int tools_index=_menu_find_caption(menu_handle,"Tools");
   if (tools_index) {
      int vc_index=_menu_find_caption(tools_index,"Version Control");
      if (vc_index) {
         int child_index;
         int first_child_index=child_index=vc_index.p_child;
         count := 0;
         for (;;) {
            _menu_insert(vc_menu_handle,
                         -1,
                         MF_ENABLED,
                         child_index.p_caption,
                         child_index.p_command,
                         '',
                         child_index.p_help,
                         child_index.p_message);
            ++count;
            child_index=child_index.p_next;
            if ( child_index==first_child_index ) break;
         }
         numberOfItemsOnMenu=count;
         _menu_destroy(menu_handle);
      }
   }
}

defeventtab _read_only_warning_form;
void ctl_ok.lbutton_up()
{
   p_active_form._delete_window(IDOK);
}
void ctl_checkout.lbutton_up()
{
   p_active_form._delete_window(IDYES);
}
