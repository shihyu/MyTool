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
#include "subversion.sh"
#include "mercurial.sh"
#include "cvs.sh"
#include "svc.sh"
#include "diff.sh"
#include "perforce.sh"
#include "treeview.sh"
#require "se/vc/GitVersionedFile.e"
#require "se/vc/HgVersionedFile.e"
#require "se/vc/PerforceVersionedFile.e"
#require "se/vc/SVNVersionedFile.e"
#require "se/vc/CVSClass.e"
#require "se/vc/SVN.e"
#require "se/ui/toolwindow.e"
#import "se/tags/TaggingGuard.e"
#import "diff.e"
#import "context.e"
#import "diffsetup.e"
#import "files.e"
#import "filewatch.e"
#import "historydiff.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "mouse.e"
#import "projconv.e"
#import "sellist.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svcautodetect.e"
#import "svccomment.e"
#import "svcupdate.e"
#import "util.e"
#import "vc.e"
#import "wkspace.e"
#import "cvs.e"
#endregion

const VERSION_CONTROL_LOG=         'versionControl';
static const SVC_CACHE_FILENAME=   'svcPathCache.xml';

definit() {
   _hg_cached_exe_path='';
   _svn_cached_exe_path='';
   _cvs_cached_exe_path='';
   _perforce_cached_exe_path='';
   _git_cached_exe_path='';

   loadCacheInfo();
}

/**
 * This file contains an API of "Specialized Version Control" calls.  For lack
 * of better terminology, a Specialized Version Control system is a system
 * like CVS or Subversion that we provide specialized support
 * for.  To keep things a bit generic these functions will find
 * the approprieate one based on what is returned by
 * _GetVCSystemName().  Some of these functions are support
 * functions that are specific to this functionality, but not to
 * a particular version control system.
 * 
 * I wanted to make these work automatically, by detecting which system the
 * file was checked out from, but since most of these take lists of files we 
 * just cannot do it.
 */

using se.vc.IVersionControl;
using se.vc.CVS;
using se.vc.Git;
using se.vc.Hg;
using se.vc.Perforce;
using se.vc.Subversion;

struct SVC_CACHE_ITEM {
   _str preservedCasePathIn;
   _str preservedCasePathOut;
};

static IVersionControl gInterFaceTable:[];
static SVC_CACHE_ITEM gSVCCache:[];

void _before_write_state_SVC_gInterfaceTable()
{
   typeless i;
   for (i._makeempty();;) {
      gInterFaceTable._nextel(i);
      if ( i._isempty() ) break;
      if (gInterFaceTable:[i]!=null) {
         gInterFaceTable:[i].beforeWriteState();
      }
   }
}

void _after_write_state_SVC_gInterfaceTable()
{
   typeless i;
   for (i._makeempty();;) {
      gInterFaceTable._nextel(i);
      if ( i._isempty() ) break;
      if (gInterFaceTable:[i]!=null) {
         gInterFaceTable:[i].afterWriteState();
      }
   }
}

static const ALT_GIT_LOCATION_1= "/Applications/Xcode.app/Contents/Developer/usr/bin/git";
static const ALT_GIT_LOCATION_2= "/Library/Developer/CommandLineTools/usr/bin/git";

/**
 * Returns the name/path of the git executable that we are 
 * configured to use. If that is not found, we look for one in 
 * the path. 
 *  
 * @return _str - Name of the git executable
 */
_str _GitGetExePath() {
   result:=_GetCachedExePath(def_git_exe_path,_git_cached_exe_path,("git":+EXTENSION_EXE));
   if (_isMac()) {
      if (_file_eq(result,"/usr/bin/git")) {
         if ( !file_exists(ALT_GIT_LOCATION_1)&& 
              !file_exists(ALT_GIT_LOCATION_2)
               ) {
            return '';
         }
      }
   }
   return result;
}


/**
* @param vcs Name of version control system 
* 
* @return bool return true if <B>vcs</B> is an SVCystem
*/
bool _SVCIsSVCSystem(_str vcs)
{
   vcs = lowcase(vcs);
   return vcs=="cvs" || 
          vcs=="subversion" ||
          vcs=='git' || 
          vcs=="mercurial" || 
          vcs=="perforce";
}

/**
* @param vcs name of version control system
* 
* @return IVersionControl* Pointer to interface for version 
*         control systme <B>vcs</B>. null if no system exists.
*/
IVersionControl *svcGetInterface(_str vcs) 
{
   if (!_haveVersionControl()) {
      return null;
   }
   vcs = lowcase(vcs);
   if ( !gInterFaceTable._indexin(vcs) || gInterFaceTable:[vcs]==null ) {
      switch ( vcs ) {
      case 'perforce':
         {
            Perforce temp;
            gInterFaceTable:['perforce'] = temp;
         }
         break;
      case 'subversion':
         {
            Subversion temp;
            gInterFaceTable:['subversion'] = temp;
         }
         break;
      case 'mercurial':
         {
            Hg temp;
            gInterFaceTable:['mercurial'] = temp;
         }
         break;
      case 'git':
         {
            Git temp;
            gInterFaceTable:['git'] = temp;
         }
         break;
      case 'cvs':
         {
            CVS temp;
            gInterFaceTable:['cvs'] = temp;
         }
         break;
      default:
         return null;
      }
   }
   return &gInterFaceTable:[vcs];
}

/**
 * Gets the index to the "vcs specific" version of <b>functionName</b>
 * @param vcs Name of a version control system from _GetVCSystemName()
 * @param functionName
 * 
 * @return int index of function, 0 if not found
 */
static int _SVCGetIndex(_str vcs,_str functionName)
{
   switch (vcs) {
   case 'Subversion':
      vcs='SVN';break;
   }
   index := find_index('_'vcs:+functionName,PROC_TYPE);
   return(index);
}

/**
 * Calls the VC specific function to add files
 * @param filelist list of files to add
 * @param OutputFilename Filename that gets the output of add command.  If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param append_to_output set to true if the output should be appended to rather than overwritten
 * @param pFiles array of System specific file structures.  If this param is non-zero, the 
 *        GetVerboseFileInfo for this system is called to get status on the newly added files
 * @param updated_new_dir set to true if a new directory was added
 * @param add_options Options passed to the *BuildAddCommand callback
 * 
 * @return int 0 if successful
 */
int _SVCAdd(_str filelist[],_str &OutputFilename='',
            bool append_to_output=false,
            /*CVS_LOG_INFO*/typeless (*pFiles)[]=null,
            bool &updated_new_dir=false,
            _str add_options='')
{
   int index=_SVCGetIndex(_GetVCSystemName(),"Add");
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=call_index(filelist,OutputFilename,append_to_output,
                         pFiles,updated_new_dir,add_options,index);
   return(status);
}

/**
 * Show list_modified if any of the files in <b>file_array</b> are modified
 * @param file_array list of files to check for modification
 * 
 * @return int 0 if succesful
 */
int _SVCListModified(_str file_array[])
{
   any_modified := false;

   if (file_array!=null) {
      int index;
      for (index=0;(!any_modified)&&(index<file_array._length());++index) {
         if (file_array[index]!='' && buf_match(_maybe_quote_filename(file_array[index]),1,'hx')!='') {
            int temp_view_id,orig_view_id;
            int status=_open_temp_view(file_array[index],temp_view_id,orig_view_id);
            if (!status) {
               if (p_modify) {
                  any_modified=true;
               }
               _delete_temp_view(temp_view_id);
               activate_window(orig_view_id);
            }
         }
      }
   }

   if (!any_modified) {
      return 0;
   }

   return(list_modified());
}

/**
 * Checks <b>filename</b> for CVS/Subversion style conflict markers
 * @param filename file to check
 * @param conflict set to true if there is a comment
 * 
 * @return int 0 if succesful.  Return value pertains to success of 
 * opening/closing file
 */
static int SVCCheckLocalFileForConflict(_str filename,bool &conflict)
{
   conflict=false;
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();
   status=search('^\<\<\<\<\<\<\< ','@rh');
   conflict=!status;

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(0);
}

/**
 * Checks <b>filelist</b> for CVS/Subversion style conflict markers
 * @param filelist list of files to check
 * 
 * @return int 0 if succesful.  This means either no conflicts, or the user 
 * acknowledged the conflicts and said it was ok to continue
 */
int _SVCCheckLocalFilesForConflicts(_str (&filelist)[])
{
   _str pluralstr= ( filelist._length() > 1 ) ? 's':'';
   int i;
   STRARRAY dirList;
   for ( i=0;i<filelist._length();++i ) {
      conflict := false;
      _str curfile=filelist[i];
      if (isdirectory(curfile)) {
         dirList[dirList._length()] = curfile;
         continue;
      }
      // DJB 08-31-2006
      // if this happens, the file was probably removed using cvs rm -f
      if (!file_exists(curfile)) continue;
      int status=SVCCheckLocalFileForConflict(curfile,conflict);
      if ( status ) {
         int result=_message_box(nls("Could not open file '%s' to check for conflict indicators.\n\nCommit file%s anyway?",curfile,pluralstr),'',MB_YESNO);
         if ( result!=IDYES ) {
            return(1);
         }
      }
      if ( conflict ) {
         int result=_message_box(nls("The file '%s' contains conflict indicators.\n\nCommit file %s anyway?",curfile,pluralstr),'',MB_YESNO);
         if ( result==IDNO ) {
            return(IDNO);
         }
      }
   }
   if ( dirList._length() ) {
      result := _message_box(nls("If you continue you will commit directories.\nThis will automatically commit the files and directories under those directories.\n\nContinue?"),'',MB_YESNO);
      if ( result==IDNO ) {
         for ( i=0;i<dirList._length();++i ) {
            for ( j:=0;j<filelist._length();++j ) {
               if ( _file_eq(dirList[i],filelist[j]) ) {
                  filelist._deleteel(j);--j;
               }
            }
         }
         return(IDNO);
      }
   }
   return(0);
}

/**
 * Commits the files in <b>filelist</b> using <b>comment</b>
 * @param filelist list of files to commit
 * @param comment comment for the files to commit
 * @param OutputFilename file for output. If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param comment_is_filename if true, the <b>comment</b> param is the name of a file that contains the comment
 * @param commit_options options that get passed to SVNBuildCommitCommand
 * @param append_to_output if true <b>OutputFilename</b> is appended to instead of overwritten
 * @param pFiles array of System specific file structures.  If this param is non-zero, the 
 *        GetVerboseFileInfo for this system is called to get status on the newly committed files
 * @param taglist list of tags to apply to files afterwards
 * 
 * @return int 0 if successful
 */
int _SVCCommit(_str filelist[],_str comment,_str &OutputFilename='',
               bool comment_is_filename=false,_str commit_options='',
               bool append_to_output=false,typeless (*pFiles)[]=null,
               _str taglist='')
{

   int index=_SVCGetIndex(_GetVCSystemName(),"Commit");
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=call_index(filelist,comment,OutputFilename,
                         comment_is_filename,commit_options,append_to_output,
                         pFiles,taglist,index);
   return(status);
}

/**
 * Displays error output if <b>last_operation_status</b> is non-zero, or certain
 *          "trigger words" occur in <b>error_filename</b>
 * @param error_filename File with output to check
 * @param last_operation_status status from the operation that we are checking on
 * @param focus_wid window id to set focus to when done
 * @param JumpToBottom if true, jumps to the bottom after 
 *                     inserting text
 * @param clearBuffer if true (default), clear other output 
 *                    FIRST
 * 
 * @return int 0 if successful
 */
int _SVCDisplayErrorOutputFromFile(_str error_filename,int last_operation_status=0,int focus_wid=0,
                                   bool JumpToBottom=false,bool clearBuffer=true)
{
   if ( clearBuffer ) _SccDisplayOutput('',true);
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(error_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   if ( !last_operation_status ) {
      status=search('aborted','@h');
      if ( !status ) {
         last_operation_status=1;
      }
   }
   if ( last_operation_status ) {
      p_window_id=orig_view_id;
      _VCErrorForm(temp_view_id,-1,'',JumpToBottom);
   } else {
      top();up();
      clear := true;
      while ( !down() ) {
         get_line(auto line);
         _SccDisplayOutput(line,clear);
         clear=false;
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
   if ( focus_wid ) {
      focus_wid._set_focus();
   }
   return(0);
}

/**
 * Displays error output if <b>last_operation_status</b> is non-zero, or certain
 *          "trigger words" occur in <b>error_filename</b>
 * 
 * @param error_output String that has the error output
 * @param last_operation_status status from the operation that we are checking on
 * @param focus_wid window id to set focus to when done
 * @param JumpToBottom if true, jumps to the bottom after inserting text
 * 
 * @return int 0 if successful
 */
int _SVCDisplayErrorOutputFromString(_str error_output,int last_operation_status=0,int focus_wid=0,
                                     bool JumpToBottom=false)
{
   if ( !last_operation_status ) {
      p := pos('aborted',error_output);
      if ( p ) {
         last_operation_status=1;
      }
   }
   if ( last_operation_status ) {
      _SccDisplayOutput(error_output,true);
   }
   return(0);
}

/**
 * Tag the items in <b>filelist</b> with <b>tag_options_and_tagname</b>
 * @param filelist files to tag
 * @param OutputFilename Filename that gets the output of tag command.  If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param append_to_output set to true if the output should be appended to rather than overwritten
 * @param tag_options_and_tagname options and tag to usee
 * @param append_to_output set to true if the output should be appended to rather than overwritten
 * @param pFiles array of System specific file structures.  If this param is non-zero, the 
 *        GetVerboseFileInfo for this system is called to get status on the newly tagged files
 * @param updated_new_dir set to true if a new directory was added
 * 
 * @return int
 */
int _SVCTag(_str filelist[],_str &OutputFilename='',_str tag_options_and_tagname='',
            bool append_to_output=false,typeless (*pFiles)[]=null,
            bool &included_dir=false)
{
   int index=_SVCGetIndex(_GetVCSystemName(),"Tag");
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=call_index(filelist,OutputFilename,tag_options_and_tagname,
                         append_to_output,pFiles,included_dir,index);
   return(status);
}

/**
 * Calls relative, but gets the FILESEP chars right for that system 
 * (this is mostly for CVS, but Subversion works either way).
 * @param filename to convert to relative
 * @param dir directory to make <b>filename</b> relative to.  If this is null, 
 *        the current directory is used.
 *
 * @return _str <b>filename</b> relative to <b>dir</b> or the current directory if
 * <b>dir</b> is null
 */
_str _SVCRelative(_str filename,_str dir=null)
{
   filename=relative(filename,dir);
   if (_isWindows()) {
      filename=stranslate(filename,FILESEP2,FILESEP);
   }
   return(filename);
}

/**
 * 
 * @param path
 * @param Files
 * @param module_name
 * @param recurse
 * @param run_from_path
 * @param treat_as_wildcard
 * @param pfnPreShellCallback
 * @param pfnPostShellCallback
 * @param pData
 * @param IndexHTab
 * @param RunAsynchronous
 * @param pid1
 * @param pid2
 * @param StatusOutputFilename
 * @param UpdateOutputFilename
 * 
 * @return int
 */
int _SVCGetVerboseFileInfo(_str path,typeless (&Files)[],_str &module_name,
                           bool recurse=true,_str run_from_path='',
                           bool treat_as_wildcard=true,
                           typeless *pfnPreShellCallback=null,
                           typeless *pfnPostShellCallback=null,
                           typeless *pData=null,
                           int (&IndexHTab):[]=null,
                           bool RunAsynchronous=false,
                           int &pid1=-1,
                           int &pid2=-1,
                           _str &StatusOutputFilename='',
                           _str &UpdateOutputFilename=''
                           )
{
   int index=_SVCGetIndex(_GetVCSystemName(),"GetVerboseFileInfo");
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=call_index(path,Files,module_name,recurse,run_from_path,
                         treat_as_wildcard,pfnPreShellCallback,pfnPostShellCallback,
                         pData,IndexHTab,RunAsynchronous,
                         pid1,pid2,StatusOutputFilename,UpdateOutputFilename,index);
                           
   return(status);
}

/**
* Use interface for current version control system to update the 
* files in <B>filelist</B>.  If there is no interface available, 
* this function will use _SVCGetIndex (deprecated).
* 
* @param filelist files to update
* @param OutputFilename Filename for output if using deprecated 
*                       call_index type function
* @param append_to_output If true, append to existing output do 
*                         not clear (applies only to deprecated
*                         call_index type function)
* @param pFiles File information to update(applies only to deprecated
*                         call_index type function)
* @param updated_new_dir set to true if a new directory was 
*                        updated (applies only to deprecated
*                         call_index type function)
* @param UpdateOptions Options for update command (applies only to deprecated
*                         call_index type function)
* @param gaugeParent Parent WID of a gauge contorl (applies only to deprecated
*                         call_index type function)
* 
* @return int 0 if successful, a SVC_* error code otherwise
*/
int _SVCUpdate(_str filelist[],_str &OutputFilename='',
               bool append_to_output=false,typeless (*pFiles)[]=null,
               bool &updated_new_dir=false,_str UpdateOptions='',
               int gaugeParent=0)
{
   status := 0;
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system(filelist[0]));
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      int index=_SVCGetIndex(_GetVCSystemName(),"Update");
      if ( !index ) {
         _message_box("Could not get interface for version control system "svc_get_vc_system(filelist[0])".\n\nSet up version control from Tools>Version Control>Setup");
         return status;
      }
      status = call_index(filelist,OutputFilename,append_to_output,pFiles,
                         updated_new_dir,UpdateOptions,gaugeParent,index);
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_UPDATE) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"update"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }
   status = pInterface->updateFiles(filelist);
                           
   return(status);
}

_command void svc_gui_mfupdate_project_working_directory() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   workingDirectory := _ProjectGet_WorkingDir(_ProjectHandle());
   if ( workingDirectory=="" ) {
      _message_box(nls("Could not get working directory for current project"));
      return;
   }
   workingDirectory = _AbsoluteToProject(workingDirectory);
   if ( workingDirectory=="" ) {
      _message_box(nls("Could not get working directory for current project"));
      return;
   }
   svc_gui_mfupdate(workingDirectory);
}

_command void svc_gui_mfupdate_workspace_directory() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   workingDirectory := _ProjectGet_WorkingDir(_ProjectHandle());
   if ( workingDirectory=="" ) {
      _message_box(nls("Could not get working directory for current project"));
      return;
   }
   workingDirectory = _AbsoluteToProject(workingDirectory);
   if ( workingDirectory=="" ) {
      _message_box(nls("Could not get working directory for current project"));
      return;
   }
   svc_gui_mfupdate(workingDirectory);
}

/**
* Use interface for current version control system to do 
* GUI update of <B>path</B> 
* 
* @param path path to run GUI update for
*/
_command void svc_gui_mfupdate(_str path='',_str options="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   path = strip(path,'B','"');
   recurse := true;
   flags := 0;
   if ( path=='' ) {
      //hideRecursive := lowcase(autoVCSystem)=="git";
      path = show('-modal _svc_path_form',"Select path to compare","svc_gui_mfupdate"/*,hideRecursive*/);
      if ( path=='' ) return;
   }
   for (;;) {
      cur := parse_file(path);
      maybeOptionPrefix := substr(cur,1,1);
      if (maybeOptionPrefix!='+' && maybeOptionPrefix!='-') {
         path = cur;
         break;
      }
      switch (lowcase(cur)) {
      case '+r':
         recurse = true;
         break;
      case '-r':
         recurse = false;
         break;
      case '--local':
         flags |= SVC_UPDATE_LOCAL_ONLY;
      }
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   SVC_UPDATE_INFO fileStatusList[];

   mou_hour_glass(true);
   status := pInterface->getMultiFileStatus(path,fileStatusList,SVC_UPDATE_PATH,recurse,flags,auto remoteURL="");
   mou_hour_glass(false);
   if ( status ) {
      // Message box was shown in getMultiFileStatus
      return;
   }
   if ( fileStatusList._length()==0 ) {
      _message_box("All files up to date");
      return;
   }
   _SVCGUIUpdateDialog(fileStatusList,path,remoteURL,false,autoVCSystem);
}

_command void svc_gui_mfupdate_local(_str path='',_str options="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   svc_gui_mfupdate(path,"--local");
}

static _str svc_file_case(_str path)
{
   vcs := lowcase(svc_get_vc_system(path));
   switch (vcs) {
   case "git":
      return path;
   case "mercurial":
   case "perforce":  
      return path;
   default:
      return _file_case(path);
   }
}


/**
* Use interface for current version control system to do 
* GUI update of current workspace
* 
*/
_command void svc_gui_mfupdate_workspace(_str options="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   vcSystem := svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(vcSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   SVC_UPDATE_INFO fileStatusList[];

   STRARRAY pathList;
   STRARRAY pathsToUpdate;

   // We get all of the working paths for the projects, and then calculate
   // the minimum number of paths we do the update for
   workspacePath := _file_path(_workspace_filename);
   pathList = null;
   SVCAllFilePathsForWorkspace(_workspace_filename,pathList);
   pInterface->getUpdatePathList(pathList,workspacePath,pathsToUpdate);
//   _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);

   numPathsToUpdate := pathsToUpdate._length();

   badPathList := "";
   if ( numPathsToUpdate ) {
      // We use a pointer to _CVSShowStallForm so that it is only called the first
      // iteration (because we set it to null after that)
      pfnStallForm := _CVSShowStallForm;
      STRHASHTAB pathsTable;
      remoteURL := "";
      status := 0;
      for ( i:=0;i<numPathsToUpdate;++i ) {
         if ( pathsTable:[svc_file_case(pathsToUpdate[i])]==null ) {
            flags := 0;
            if ( pos(' --local ',' 'options' ',1,'i') ) {
               flags |= SVC_UPDATE_LOCAL_ONLY;
            }
            status = pInterface->getMultiFileStatus(pathsToUpdate[i],fileStatusList,SVC_UPDATE_PATH,true,flags,auto curRemoteURL);
            if ( status ) {
               if ( status == FILE_NOT_FOUND_RC ) {
                  badPathList :+= ', 'pathsToUpdate[i];
               } else {
                  return;
               }
            }
            if ( remoteURL=="" ) {
               remoteURL = curRemoteURL;
            }
            pathsTable:[svc_file_case(pathsToUpdate[i])] = "";
         }
         pfnStallForm = null;

         // For git it gives just the one path, we can't do multiple.
         //  
         // If we have a status here from git, it has to be 
         // FILE_NOT_FOUND_RC from a bad path. This means we didn't get a 
         // status for a legitmate path, so go again in that case.
         if ( lowcase(vcSystem)=="git" && !status ) break;
      }
      if ( fileStatusList._length()==0 ) {
         _message_box("All files up to date");
         return;
      }
      
      // First get spaces
      badPathList = strip(badPathList);
      // Now get commas
      badPathList = strip(badPathList,'B',',');

      if ( badPathList!="" && pathsToUpdate._length()==1 ) {
         // There could be a disconnected network path.  Only show error 
         // message if we got an error AND it was the only path
         _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_FOR_PATH_RC,badPathList));
      }
      _maybe_append_filesep(pathsToUpdate[0]);
      origPath := getcwd();
      chdir(pathsToUpdate[0],1);
      rootPath := pInterface->localRootPath();
      if ( rootPath=="" ) {
         rootPath = _file_path(_workspace_filename);
      }
      chdir(origPath,1);
      _SVCGUIUpdateDialog(fileStatusList,rootPath,remoteURL,false,vcSystem,pathsToUpdate,"Workspace");
   }
}

_command void svc_gui_mfupdate_workspace_local() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   svc_gui_mfupdate_workspace('--local');
}


/**
* Use interface for current version control system to do 
* GUI update of current workspace
* 
*/
_command void svc_gui_mfupdate_project(_str projectFilename=_project_name,_str options="") name_info(PROJECT_FILENAME_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   SVC_UPDATE_INFO fileStatusList[];

   STRARRAY pathList;
   STRARRAY pathsToUpdate;

   // We get all of the workking paths for the projects, and then calculate
   // the minimum number of paths we do the update for
   workspacePath := _file_path(_workspace_filename);
   pathList = null;
   SVCGetAllFilePathsForProject(projectFilename,_workspace_filename,pathList);
   pInterface->getUpdatePathList(pathList,workspacePath,pathsToUpdate);

   numPathsToUpdate := pathsToUpdate._length();

   badPathList := "";
   if ( numPathsToUpdate ) {
      // We use a pointer to _CVSShowStallForm so that it is only called the first
      // iteration (because we set it to null after that)
      pfnStallForm := _CVSShowStallForm;
      flags := 0;
      if ( pos(' --local ',' 'options' ',1,'i') ) {
         flags |= SVC_UPDATE_LOCAL_ONLY;
      }
      for ( i:=0;i<numPathsToUpdate;++i ) {
         status := pInterface->getMultiFileStatus(pathsToUpdate[i],fileStatusList,SVC_UPDATE_PATH,true,flags);
         if ( status ) {
            if ( status == FILE_NOT_FOUND_RC ) {
               badPathList :+= ', 'pathsToUpdate[i];
            } else {
               return;
            }
         }
         pfnStallForm = null;
      }
      if ( fileStatusList._length()==0 ) {
         _message_box("All files up to date");
         return;
      }
      
      // First get spaces
      badPathList = strip(badPathList);
      // Now get commas
      badPathList = strip(badPathList,'B',',');

      if ( badPathList!="" ) {
         _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_FOR_PATH_RC,badPathList));
      }
      _maybe_append_filesep(pathsToUpdate[0]);

      parentDirectory := _strip_filename(substr(pathsToUpdate[0],1,length(pathsToUpdate[0])-1),'N');

      _maybe_append_filesep(pathsToUpdate[0]);
      origPath := getcwd();
      chdir(pathsToUpdate[0],1);
      rootPath := pInterface->localRootPath();
      if ( rootPath=="" ) {
         rootPath = parentDirectory;
      }
      chdir(origPath,1);
      _SVCGUIUpdateDialog(fileStatusList,rootPath,"",false,"",null,"Project");
   }
}

_command void svc_gui_mfupdate_project_local(_str projectFilename=_project_name,_str options="") name_info(PROJECT_FILENAME_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   svc_gui_mfupdate_project(projectFilename,"--local");
}


/**
* Use interface for current version control system to do 
* GUI update of current project and all the projects it depends on.
* 
*/
_command void svc_gui_mfupdate_project_dependencies(_str projectFilename=_project_name,_str options="") name_info(PROJECT_FILENAME_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   vcSystem := svc_get_vc_system();
   IVersionControl *pInterface = svcGetInterface(vcSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   SVC_UPDATE_INFO fileStatusList[];

   STRARRAY pathList;
   STRARRAY pathsToUpdate;

   // We get all of the workking paths for the projects, and then calculate
   // the minimum number of paths we do the update for
   workspacePath := _file_path(_workspace_filename);
   pathList = null;
   SVCAllFilePathsForProjectAndDependencies(projectFilename,_workspace_filename,pathList);
   pInterface->getUpdatePathList(pathList,workspacePath,pathsToUpdate);
//   _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);

   numPathsToUpdate := pathsToUpdate._length();

   badPathList := "";
   if ( numPathsToUpdate ) {
      // We use a pointer to _CVSShowStallForm so that it is only called the first
      // iteration (because we set it to null after that)
      pfnStallForm := _CVSShowStallForm;
      STRHASHTAB pathsTable;
      remoteURL := "";
      for ( i:=0;i<numPathsToUpdate;++i ) {
         if ( pathsTable:[svc_file_case(pathsToUpdate[i])]==null ) {
            flags := 0;
            if ( pos(' --local ',' 'options' ',1,'i') ) {
               flags |= SVC_UPDATE_LOCAL_ONLY;
            }
            status := pInterface->getMultiFileStatus(pathsToUpdate[i],fileStatusList,SVC_UPDATE_PATH,true,flags,auto curRemoteURL);
            if ( status ) {
               if ( status == FILE_NOT_FOUND_RC ) {
                  badPathList :+= ', 'pathsToUpdate[i];
               } else {
                  return;
               }
            }
            if ( remoteURL=="" ) {
               remoteURL = curRemoteURL;
            }
            pathsTable:[svc_file_case(pathsToUpdate[i])] = "";
         }
         pfnStallForm = null;

         // For git it gives just the one path, we can't do multiple
         if ( lowcase(vcSystem)=="git" ) break;
      }
      if ( fileStatusList._length()==0 ) {
         _message_box("All files up to date");
         return;
      }
      
      // First get spaces
      badPathList = strip(badPathList);
      // Now get commas
      badPathList = strip(badPathList,'B',',');

      if ( badPathList!="" && pathsToUpdate._length()==1 ) {
         // There could be a disconnected network path.  Only show error 
         // message if we got an error AND it was the only path
         _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_FOR_PATH_RC,badPathList));
      }
      _maybe_append_filesep(pathsToUpdate[0]);
      origPath := getcwd();
      chdir(pathsToUpdate[0],1);
      rootPath := pInterface->localRootPath();
      if ( rootPath=="" ) {
         rootPath = _file_path(_workspace_filename);
      }
      chdir(origPath,1);
      _SVCGUIUpdateDialog(fileStatusList,rootPath,remoteURL,false,vcSystem,pathsToUpdate,"Workspace");
   }
}

_command void svc_gui_mfupdate_project_dependencies_local(_str projectFilename=_project_name,_str options="") name_info(PROJECT_FILENAME_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   svc_gui_mfupdate_project_dependencies(projectFilename,'--local');
}

static int SVCGetAllFilePathsForProject(_str projectFilename,_str workspaceFilename,STRARRAY &pathList)
{
   _str ProjectFiles[];
   _str workpacePath;
   int i;
   // Get all the project files in the workspace
   workpacePath=_file_path(workspaceFilename);
   STRARRAY fileList;
   _str pathHashtab:[];
   // Get all the files in the current project
   absProjectFilename := absolute(projectFilename,workpacePath);
   status := _getProjectFiles(workpacePath, absProjectFilename, fileList, 1);

   // Save all of the paths.   Use them as the key in a hashtable so we will
   // have list of unique paths

   // Be sure to add in the project's working directory in case there were no
   // files in it.
   projectWorkingDir := absolute(_ProjectGet_WorkingDir(_ProjectHandle(absProjectFilename)),_file_path(absProjectFilename));

   // This should have a filesep, but be certain
   _maybe_append_filesep(projectWorkingDir);

   // Add a . because later we will use _file_path
   fileList :+= projectWorkingDir:+'.';

   // Go through and make the hashtable
   fileListLen := fileList._length();
   for ( j:=0;j<fileListLen;++j ) {
      curPath := svc_file_case(_file_path(fileList[j]));
      if (pathHashtab._indexin(curPath)) continue;
      pathHashtab:[curPath] = '';
      pathList :+= curPath;
   }
   return 0;
}

static int SVCAllFilePathsForProjectAndDependencies(_str projectFilename,_str workspaceFilename,STRARRAY &pathList)
{
   // Get all the project files in the workspace
   _str ProjectDependencies[];
   _GetProjectDependencies(workspaceFilename, projectFilename, ProjectDependencies, true);
   if (ProjectDependencies._isempty()) {
      _message_box(nls("Unable find dependencies for '%s'",projectFilename));
      return(1);
   }

   workpace_path := _strip_filename(workspaceFilename,'N');
   STRARRAY fileList;
   _str pathHashtab:[];
   // Loop thru all the projects in the workspace
   for (i:=0;i<ProjectDependencies._length();++i) {
      SVCGetAllFilePathsForProject(ProjectDependencies[i],workspaceFilename,pathList);
   }
#if 0 //12:55pm 4/5/2011
   // Copy the hashtable into pathList
   foreach ( auto key => auto val in pathHashtab ) {
      pathList[pathList._length()] = key;
   }
   // We are not removing anything from the list, we will let Subversion figure 
   // it out
#endif
   return 0;
}

static int SVCAllFilePathsForWorkspace(_str workspaceFilename,STRARRAY &pathList)
{
   // Get all the project files in the workspace
   _str ProjectFiles[];
   status:=_GetWorkspaceFiles(workspaceFilename,ProjectFiles);
   if (status) {
      _message_box(nls("Unable to open workspace '%s'",workspaceFilename));
      return(1);
   }
   workpace_path := _strip_filename(workspaceFilename,'N');
   STRARRAY fileList;
   _str pathHashtab:[];
   // Loop thru all the projects in the workspace
   for (i:=0;i<ProjectFiles._length();++i) {
      SVCGetAllFilePathsForProject(ProjectFiles[i],workspaceFilename,pathList);
   }
#if 0 //12:55pm 4/5/2011
   // Copy the hashtable into pathList
   foreach ( auto key => auto val in pathHashtab ) {
      pathList[pathList._length()] = key;
   }
   // We are not removing anything from the list, we will let Subversion figure 
   // it out
#endif
   return 0;
}


/**
* Use interface for current version control system to do 
* GUI update of a path fixed by the version control system
* 
*/
_command void svc_gui_mfupdate_fixed() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   // In this case no path is needed.  It will be calculated in the implentation
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   path := pInterface->getFixedUpdatePath(true);
   if ( path=="" ) {
      return;
   }
   recurse := false;
   SVC_UPDATE_INFO fileStatusList[];
   if ( pos("+r ",path)==1 ) {
      recurse = true;
      path = substr(path,4);
   }
   status := pInterface->getMultiFileStatus(path,fileStatusList);
   if ( status ) {
      // Message box was shown in getMultiFileStatus
      return;
   }
   if ( fileStatusList._length()==0 ) {
      _message_box("All files up to date");
      return;
   }
   _SVCGUIUpdateDialog(fileStatusList,path,""/*,true*/);
}

static _str getSystemPrefix(_str filename)
{
   system_name := "";
   if ( filename=="" ) {
      system_name=_GetVCSystemName();
      system_name=lowcase(system_name);
      if ( system_name=='subversion' ) system_name='svn';
   }else{
      filePath := _file_path(filename);
      svnDir := filePath:+".svn":+FILESEP:+".";
      cvsDir := filePath:+"CVS":+FILESEP:+".";
      if ( file_exists(svnDir) ) {
         system_name = "svn";
      }else if ( file_exists(cvsDir) ) {
         system_name = "cvs";
      }
   }
   return system_name;
}

/**
 * Finds a function for the specified system.  Uses a lowcased version of 
 * system_name.  Then looks for '_':+system_name:+'_':+function_suffix 
 *  
 * WILL DEPRECATE WHEN OLD SYSTEMS ARE PORTED TO NEW FRAMEWORK
 * 
 * @param system_name if '', use get value from _GetVCSystem() and convert, we
 *                    use "svn" as a prefix instead of subversion
 */
int _SVCGetProcIndex(_str function_suffix,_str system_name='',_str filename="")
{
   if ( system_name=='' ) {
      system_name=getSystemPrefix(filename);
   }
   funcname := '_':+system_name:+'_':+function_suffix;
   index := find_index(funcname,PROC_TYPE);
   return(index);
}

/**
 * Finds a command for the specified system.  Uses a lowcased version of
 * system_name.  Then looks for 
 * system_name:+'_':+function_suffix.  Will be deprecated in 
 * v19.0. 
 * 
 * @param function_suffix
 *               Suffix for funciton, for example to find "svn_history", use "history"
 * @param system_name
 *               if '', use get value from _GetVCSystem() and convert, we
 *               use "svn" as a prefix instead of subversion
 * @param filename 
 *               filename that the command will be run on 
 * 
 * @return Index to command if found, else 0
 */
int _SVCGetCommandIndex(_str function_suffix,_str system_name='',_str filename="")
{
   // If we have a filename that we are working with, check to see what this
   // directory was checked out from
   if ( filename!="" ) {
         system_name =getSystemPrefix(filename);
      }

   if ( system_name=="" ) {
      if ( system_name=='' ) {
         system_name=_GetVCSystemName();
         system_name=lowcase(system_name);
      }
      if ( lowcase(system_name)=='subversion' ) system_name='svn';
   }
   funcname := system_name:+'_':+function_suffix;
   index := find_index(funcname,COMMAND_TYPE);
   return(index);
}

/** 
* Remove files in <B>filelist</B>.  Currently supports 
* deprecated call_index functions. 
* @param filelist list of files to remove
* @param OutputFilename filename to re-direct output to (applies only to deprecated
*                         call_index type function)
* @param append_to_output If true append to output, do not clear
*                         (applies only to deprecated call_index
*                         type function)
* @param pFiles File information to update (applies only to deprecated
*                         call_index type function)
* @param updated_new_dir Set to true if a new directory was 
*                        updated (applies only to deprecated
*                         call_index type function)
* @param remove_options Options for remove command (applies only to deprecated
*                         call_index type function)
* 
* @return int 
*/
int _SVCRemove(_str filelist[],_str &OutputFilename='',
               bool append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               bool &updated_new_dir=false,
               _str remove_options='')
{
   int index=_SVCGetIndex(_GetVCSystemName(),"Remove");
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=call_index(filelist,OutputFilename,append_to_output,pFiles,
                         updated_new_dir,remove_options,index);
                           
   return(status);
}
/**
 * Dialog that prompts the user for the username and the password
 */
defeventtab _svc_auth_form;

static const SVC_AUTH_INFO_INDEX= 0;

void ctlok.on_create(SVC_AUTHENTICATE_INFO *pinfo)
{
   pinfo->password=null;
   pinfo->username=null;
   _SetDialogInfo(SVC_AUTH_INFO_INDEX,pinfo);
}

int ctlok.lbutton_up()
{
   SVC_AUTHENTICATE_INFO *pinfo=_GetDialogInfo(SVC_AUTH_INFO_INDEX);
   _SetDialogInfo(SVC_AUTH_INFO_INDEX,null);
   pinfo->password=ctlpassword.p_text;
   pinfo->username=ctluser_name.p_text;
   p_active_form._delete_window(0);
   return(0);
}

/**
 * 
 * @param pinfo pointer to SVC_AUTHENTICATE_INFO struct that has the user name
 *              and password
 * 
 * @return int returns 0 if successful
 */
int _SVCGetAuthInfo(SVC_AUTHENTICATE_INFO &info)
{
   int status=show('-modal _svc_auth_form',&info);
   return(status);
}

static int _SVCCallCommand(_str command_suffix,_str filename)
{
   index := _SVCGetCommandIndex(command_suffix);
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   status := 0;
   status=call_index(filename,index);
   return(status);
}

/**
 * Runs the history command for a specialized version control system 
 * @deprecated use svc_commit 
 */
int _SVCCommit_command(_str filename='',_str comment=NULL_COMMENT)
{
   index := _SVCGetCommandIndex('commit');
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   status := 0;
   status=call_index(filename,comment,index);
   return(status);
}

/**
 * Runs the update command for a specialized version control system
 * @deprecated use svc_update 
 */
int _SVCUpdate_command(_str filename='')
{
   int status=_SVCCallCommand("update",filename);
   return(status);
}

/**
 * Runs the add command for a specialized version control system
 * @deprecated use svc_add
 */
int _SVCAdd_command(_str filename='')
{
   int status=_SVCCallCommand("add",filename);
   return(status);
}

/**
 * Runs the history command for a specialized version control system
 * @deprecated use svc_history
 */
int _SVCHistory_command(_str filename='')
{
   int status=_SVCCallCommand("history",filename);
   return(status);
}

/**
 * Runs the diff_with_tip command for a specialized version control system
 * @deprecated use svc_diff_with_tip
 */
int _SVCDiffWithTip_command(_str filename='')
{
   int status=_SVCCallCommand("diff_with_tip",filename);
   return(status);
}

/**
 * Runs the diff_with_tip command for a specialized version control system
 * @deprecated use svc_remove
 */
int _SVCRemove_command(_str filename='')
{
   int status=_SVCCallCommand("remove",filename);
   return(status);
}

/**
 * WILL DEPRECATE WHEN OLD SYSTEMS ARE PORTED TO NEW FRAMEWORK
 */
_str _SVCGetEXEName()
{
   exeName := "";
   switch (upcase(svc_get_vc_system())) {
   case "CVS":
      exeName = _CVSGetExePath();
      break;
   case "SUBVERSION":
      exeName = _SVNGetExePath();
      break;
   }
   return exeName;
}


_str _PerforceGetExePath() {
   return _GetCachedExePath(def_perforce_exe_path,_perforce_cached_exe_path,("p4":+EXTENSION_EXE));
}

/**
 * @param dataToWrite Data to write to log file
 * @param writeToScreen If true, also write <B>dataToWrite</B> 
 *                      to the say window
 * @return int 0 if successful
 */
void _SVCLog(_str dataToWrite,bool writeToScreen=true)
{
   dsay(dataToWrite, VERSION_CONTROL_LOG);
   if ( writeToScreen ) {
      say(dataToWrite);
   }
}

/** 
 * @param StdErrData stderr output from a specialized version control system
 * 
 * @return bool true if <B>StdErrData</B> contains a string that indicates that 
 * the user needs to be prompted for login info 
 */
bool _SVCNeedAuthenticationError(_str StdErrData)
{
   int index=_SVCGetIndex(_GetVCSystemName(),"NeedAuthenticationError");
   if ( !index ) {
      return false;
   }
   status := call_index(StdErrData,index);
                           
   return(status);
}

void SVCInitDialogInfo(SVCHistoryFileInfo &dialogInfo)
{
   dialogInfo.URL = "";
   dialogInfo.localFilename = "";
   dialogInfo.revisionCaptionToSelectInTree = "";
   dialogInfo.currentRevision = "";
   dialogInfo.currentLocalRevision = "";
   dialogInfo.branchOption = SVC_HISTORY_NONE;
   dialogInfo.branchName= "";
}

/**
 * Add this so that if there are multiple files selected in 
 * project tool window History command is disabled 
 */
int _OnUpdate_svc_history(CMDUI &cmdui,int target_wid,_str command)
{
   if (cmdui.menu_handle) {
      if (!_haveVersionControl()) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      if ( target_wid ) {
         if (target_wid.isProjectToolWindow()) {
            if ( target_wid._TreeGetNumSelectedItems()>1 ) {
               return MF_GRAYED;
            }
         }
      }
   }
   if (!_haveVersionControl()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   if ( target_wid ) {
      if (target_wid.isProjectToolWindow()) {
         if ( target_wid._TreeGetNumSelectedItems()>1 ) {
            return MF_GRAYED;
         }
      }
   }
   return MF_ENABLED;
}

/**
* Use interface for current version control system to diff 
* <b>filename</b> with the current version 
* 
* @param filename File to show history for
*/
_command void svc_history(_str filename="",SVC_HISTORY_BRANCH_OPTIONS branchOption=SVC_HISTORY_NOT_SPECIFIED,_str curLocalRevision="",bool isURL=false,_str branchName="",
                          bool searchUserInfoForVersion=false) name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("history",svc_get_vc_system(),filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "autoVCSystem".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return;
      }
      call_index(filename,index);
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"history"));
      return;
   }
   if ( isProjectToolWindow() ) {
      STRARRAY fileList;
      getListFromProjectTree(fileList);
      if (fileList!=null) {
         filename=fileList[0];
      }
   } else if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to view 'cap' for',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return;
      filename=result;
   } else  if ( filename=='' ) {
      filename=p_buf_name;
   }
   if ( !isURL ) {
      filename = absolute(filename);
   }
   option := parse_file(filename);
   if ( lowcase(option)=='--no-branches' ) {
      branchOption = SVC_HISTORY_NO_BRANCHES;
   }else if ( lowcase(option)=='--with-branches' ) {
      branchOption = SVC_HISTORY_WITH_BRANCHES;
   } else {
      // Put the filename back together
      filename = option' 'filename;
      // filename may have been '', so strip any trailing space
      filename = strip(filename);
   }
   filename = strip(filename,'B','"');
   if ( !file_exists(filename) && !isURL ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return;
   }
   SVCHistoryInfo historyInfo[];
   SVCHistoryFileInfo dialogInfo;
   SVCFileStatus fileStatus;
   mou_hour_glass(true);
   if ( filename=="" ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,"","Could not get remote filename"));
      return;
   }
   do {
      SVCInitDialogInfo(dialogInfo);
      status := pInterface->getHistoryInformation(filename,historyInfo,branchOption,branchName);
      if ( status ) break;
      if ( !isURL ) {
         status = pInterface->getCurRevision(filename,auto curRevision="");
         if ( status ) break;
         dialogInfo.currentRevision = curRevision;
      }
      dialogInfo.localFilename = filename;
      if ( curLocalRevision=="" ) {
         status = pInterface->getCurLocalRevision(filename,curLocalRevision);
         if ( status ) break;
      }
      dialogInfo.currentLocalRevision = curLocalRevision;
      dialogInfo.revisionCaptionToSelectInTree = curLocalRevision;
      status = pInterface->getLocalFileURL(filename,auto URL="");
      dialogInfo.URL = URL;
      if ( status ) break;
      dialogInfo.branchOption=branchOption;
      dialogInfo.branchName = branchName;
      if ( branchName=="" ) {
         status = pInterface->getLocalFileBranch(filename,branchName);
         if ( status ) break;
         dialogInfo.branchName = branchName;
      }
      if ( !isURL ) {
         status = pInterface->getFileStatus(filename,fileStatus);
      }
      if ( status ) break;
   } while (false);
   mou_hour_glass(false);
   dialogInfo.fileStatus = fileStatus;
   if ( historyInfo._length()>0 ) {
      int wid=show('-new -hidden -xy _svc_history_form',historyInfo,dialogInfo,searchUserInfoForVersion);
      wid.p_visible = true;
      wid._set_focus();
   }
}


/**
* Use interface for current version control system to diff 
* <b>filename</b> with the current version 
*  
* @param filename File to show differences for
*/
_command int svc_diff_with_tip(_str filename="",_str version="",_str VCSystemName="",bool modal=false) name_info(FILE_ARG','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }
   if ( VCSystemName=="" ) VCSystemName = svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("diff_with_tip",VCSystemName,filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "VCSystemName".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return VSRC_SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC;
      }
      call_index(filename,index);
      return rc;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_DIFF) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"diff"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_DIFF,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return COMMAND_CANCELLED_RC;
      fileList[0]=result;
   } else if ( filename=='' ) {
      fileList[0]=p_buf_name;
   } else {
      fileList[0] = filename;
   }
   origwid := p_window_id;
   len := fileList._length();
   for (i:=0;i<len;++i) {
      pInterface->diffLocalFile(strip(fileList[i],'B','"'),version,0,modal);
   }
   p_window_id = origwid;
   return 0;
}


/**
 * Diff the current file, or file specified in <b>cmdline</b> 
 * with the current BASE revision in the local working copy 
 *  
 * This is equivelent to {@link svc_diff_with_tip} for systems that do not 
 * support BASE revisions. 
 *  
 * @param cmdline a filename to be diffed
 *
 * @return int 0 if successful
 */
_command int svc_diff_with_base(_str cmdline='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }

   VCSystemName := svc_get_vc_system(cmdline);
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   base_rev := "";
   if ( pInterface != null ) {
      base_rev = pInterface->getBaseRevisionSpecialName();
   }
   return svc_diff_with_tip(cmdline,base_rev,VCSystemName);
}


/** 
* Use interface for current version control system to reviews changes 
* and commit <b>filename</b>
* 
* @param filename File to commit
* @return 0 if successful
*/
_command int svc_review_and_commit(_str cmdline='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status = svc_diff_with_tip(cmdline, modal:true);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }
   return svc_commit(cmdline);
}


/** 
* Use interface for current version control system to commit
* <b>filename</b>
* 
* @param filename File to commit
* @return 0 if successful
*/
_command int svc_commit(_str filename="",_str comment=null) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   VCSystemName := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(VCSystemName);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("commit",VCSystemName,filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "VCSystemName".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
      }
      status := call_index(filename,index);
      return status;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_COMMIT) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"commit"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return COMMAND_CANCELLED_RC;
      fileList[0]=result;
   } else if ( filename=='' ) {
      fileList[0]=p_buf_name;
   } else {
      fileList[0] = filename;
   }
   // The file does not have to exist.  We could be committing a delete
//   if ( !file_exists(filename) ) {
//      _message_box(nls("The file '%s' does not exist",filename));
//      return;
//   }
   status := 0;
   if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GET_COMMENT_AND_COMMIT) ) {
      status = _SVCGetCommentAndCommit(fileList,null,null,pInterface);
   } else {
      status = pInterface->commitFiles(fileList,comment);
   }

   len := fileList._length();
   for (i:=0;i<len;++i) {
      _filewatchRefreshFile(fileList[i]);
   }
   return status;
}

bool _SVCBufferIsModified(_str filename)
{
   buf_info := buf_match(filename,1,'vx');
   if ( !rc ) {
      parse buf_info with auto buf_id auto ModifyFlags auto buf_flags auto buf_name;
      int modFlags = (int)ModifyFlags;
      return ((modFlags & 0x1) != 0);
   }
   return false;
}


/**
* 
* Use interface for current version control system to update
* <b>filename</b>
*  
* @param filename File to update 
* @return 0 if successful
*/
_command int svc_update(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   autoVCSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;

   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to update',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return COMMAND_CANCELLED_RC;
      fileList[0] = result;
   } else if ( filename=='' ) {
      fileList[0] = p_buf_name;
   } else {
      fileList[0] = filename;
   }
   len := fileList._length();
   for (i:=0;i<len;++i) {
      curFilename := strip(fileList[i],'B','"');
      if ( !file_exists(curFilename) ) {
         _message_box(nls("The file '%s' does not exist",filename));
         return FILE_NOT_FOUND_RC;
      }
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE,false,false));
      ismodified := _SVCBufferIsModified(curFilename);
      if ( ismodified ) {
         _message_box(nls("Cannot %s file '%s' because the file is open and modified",cap,curFilename));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
      }
   }

   status := pInterface->updateFiles(fileList);
   for (i=0;i<len;++i) {
      _filewatchRefreshFile(filename);
   }
   return status;
}


/**
* 
* Use interface for current version control system to 
* revert <b>filename</b>
* 
* @param filename File to revert
*/
_command void svc_revert(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REVERT) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"revert"));
      return;
   }
   STRARRAY fileList;
   cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_REVERT,false,false));
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return;
      fileList[0] = result;
   } else if ( filename=='' ) {
      fileList[0] = p_buf_name;
   } else {
      fileList[0] = filename;
   }
   len := fileList._length();
   for (i:=0;i<len;++i) {
      curFilename := fileList[i];
      curFilename = strip(curFilename,'B','"');
      if ( !file_exists(curFilename) ) {
         _message_box(nls("The file '%s' does not exist",curFilename));
         return;
      }
   }
   if ( !svc_user_confirms_revert(fileList) ) {
      return;
   }
   pInterface->revertFiles(fileList);
   for (i=0;i<len;++i) {
      _filewatchRefreshFile(fileList[i]);
   }
}

static void getListFromProjectTree(STRARRAY &fileList)
{
   int info;
   for (ff:=1;;ff=0) {
      index := _TreeGetNextSelectedIndex(ff,info);
      if ( index<0 ) break;
      cap := _TreeGetCaption(index);
      parse cap with "\t" auto fullPath;
      fullPath = _AbsoluteToWorkspace(fullPath, _file_path(_workspace_filename));
      if ( fullPath!="" ) {
         fileList :+= fullPath;
      }
   }
}

static bool isProjectToolWindow()
{
   return p_name=='_proj_tooltab_tree' && p_parent.p_name=='_tbprojects_form';
}


/**
* Use interface for current version control system to edit 
* (open, checkout) <B>filename</B> 
* 
* @param filename File to edit
*/
_command void svc_edit(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system(filename));
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   commandCaption := pInterface->getCaptionForCommand(SVC_COMMAND_EDIT,false,false);
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,commandCaption,filename,""));
      return;
   }
   cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_EDIT,false,false));
   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return;
      fileList[0] = result;
   } else if ( filename=='' ) {
      fileList[0] = p_buf_name;
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else {
      fileList[0] = filename;
   }
   len := fileList._length();
   for (i:=0;i<len;++i) {
      status := pInterface->getCurRevision(fileList[i],auto curRevision);
      if ( !status ) {
         status = pInterface->getCurLocalRevision(fileList[i],auto curLocalRevision);
         if ( !status ) {
            if ( curRevision!=curLocalRevision ) {
               status = _message_box(nls("The current revision of %s is %s, you have %s locally.\n\nWould you like to update this file before attempting %s?",filename,curRevision,curLocalRevision,commandCaption),"",MB_YESNOCANCEL);
               if ( status==IDCANCEL ) return;
               if ( status==IDYES ) {
                  status = pInterface->updateFile(fileList[i]);
                  if (status) return;
               }
            }
         }
      }
   }
   pInterface->editFiles(fileList);
   for (i=0;i<len;++i) {
      _filewatchRefreshFile(fileList[i]);
      _UpdateBufferReadOnlyStatus(fileList[i]);
   }
}

void SVCDisplayOutput(_str str,
                       bool clear_buffer=false,
                       bool strIsViewId=false,
                       bool doActivateOutput=true)
{
   _SccDisplayOutput(str,clear_buffer,strIsViewId,doActivateOutput);
}

/**
* 
* Use interface for current version control system to add 
* <b>filename</b> to version control
* 
* @param filename File to add 
*  
* @return 0 if successful
*/
_command int svc_add(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   vcSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(vcSystem);
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC,vcSystem));
      return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_ADD) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"add"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_ADD,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return COMMAND_CANCELLED_RC;
      fileList[0] = result;
   } else if ( filename=='' ) {
      fileList[0] = p_buf_name;
   } else {
      fileList[0] = filename;
   }
   status := pInterface->addFiles(fileList);
   len := fileList._length();
   for (i:=0;i<len;++i) {
      _filewatchRefreshFile(fileList[i]);
   }
   return status;
}


/** 
*  
* Use interface for current version control system to remove
* <b>filename</b> from version control
* 
* @param filename File to remove
*/
_command int svc_remove(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   autoVCSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC,autoVCSystem));
      return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REMOVE) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"remove"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_REMOVE,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return COMMAND_CANCELLED_RC;
      fileList[0 ] =result;
   } else if ( filename=='' ) {
      fileList[0] = p_buf_name;
   } else {
      fileList[0] = filename;
   }
   status := pInterface->removeFiles(fileList);
   _filewatchRefreshFile(filename);
   return status;
}

_command int svc_checkout(_str path="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system(path));
   if ( pInterface==null ) {
      _message_box(get_message(VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC,svc_get_vc_system()));
      return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   formName := svc_get_form_name(pInterface,SVC_COMMAND_CHECKOUT);
   if ( formName=="" ) {
      if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GET_URL_CHILDREN) ) {
         _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"checkout"));
         return VSRC_SVC_COMMAND_NOT_AVAILABLE;
      }
   }
   show('-modal 'formName);
   return 0;
}

_command int svc_switch(_str path="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system(path));
   if ( pInterface==null ) {
      if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_SWITCH) ) {
         _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"checkout"));
         return VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
      }
   }
   formName := svc_get_form_name(pInterface,SVC_COMMAND_SWITCH);
   if ( formName=="" ) {
      if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_SWITCH) ) {
         _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"checkout"));
         return VSRC_SVC_COMMAND_NOT_AVAILABLE;
      }
   }
   svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   createNewBranch := false;
   status := show('-modal 'formName, path, &branchName, &pullRepositoryName, &createNewBranch);

   if ( status=="" ) return COMMAND_CANCELLED_RC;

   mou_hour_glass(true);
   SVCSwitchBranch flags = createNewBranch?SVC_SWITCH_NEW_BRANCH:0;
   status = pInterface->switchBranches(branchName,path,flags);
   mou_hour_glass(false);
   if (!status) {
      _ReloadFiles();
   }

   return status;
}

#if 0
_command int svc_annotate(_str filename="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( filename=="" ) {
      if (_no_child_windows()) {
         _str result=_OpenDialog('-modal',
                                 'Select file to annotate',// Dialog Box Title
                                 '',                   // Initial Wild Cards
                                 def_file_types,       // File Type List
                                 OFN_FILEMUSTEXIST,
                                 '',
                                 ''
                                );
         if ( result=='' ) return(COMMAND_CANCELLED_RC);
         filename=result;
      } else {
         filename=p_buf_name;
      }
   }
   int status=svcAnnotateEnqueueBuffer(filename,svc_get_vc_system());
   return status;
}

static int gAnnotateTimerHandle=-1;
static SVC_FILE_INFO gFileInfo:[];
static SVC_QUEUE_ITEM gAnnotationQueue[];

definit()
{
   gFileInfo=null;
}

static void svcAnnotateCallback()
{
   _kill_timer(gAnnotateTimerHandle);
   gAnnotateTimerHandle=-1;

   SVC_QUEUE_ITEM newlyCompletedFiles[];

   int i,len=gAnnotationQueue._length();
   for (i=0;i<len;++i) {
      _str fileIndex=svc_file_case(gAnnotationQueue[i].filename);
      SVC_ANNOTATION annotationInfo[];
      int status=_SVCGetFileAnnotations(gAnnotationQueue[i].VCSystem,gAnnotationQueue[i].filename,annotationInfo);
      if (!status) {
         gFileInfo:[fileIndex].annotations=annotationInfo;
         newlyCompletedFiles[newlyCompletedFiles._length()]=gAnnotationQueue[i];
         gAnnotationQueue._deleteel(i);
         --i;--len;
      }
   }

   if ( gAnnotationQueue._length() ) {
      gAnnotateTimerHandle=_set_timer(1000,svcAnnotateCallback);
   }else{
      len=newlyCompletedFiles._length();
      for (i=0;i<len;++i) {
         mou_hour_glass(true);
         svcAnnotateBuffer(newlyCompletedFiles[i]);
         mou_hour_glass(false);
      }
   }
}

int _CVS_unmark_buffer(int annotated_wid)
{
   int markid=_alloc_selection();
   if ( markid  >= 0 ) {
      orig_wid := p_window_id;
      p_window_id=annotated_wid;

      top();p_col=1;
      _select_block(markid);

      bottom();p_col=35;
      _select_block(markid);

      _delete_selection(markid);

      _free_selection(markid);

      p_window_id=orig_wid;
   }
   return markid  >= 0 ? 0:markid;
}

#define USE_STREAM_MARKER 1

static int svcAnnotateBuffer(SVC_QUEUE_ITEM file)
{
   status := 0;
   _str fileIndex=svc_file_case(file.filename);
   annotatedPicIndex := find_index('_f_arrow_gt.svg');
   modifiedPicIndex := find_index('_ed_breakpoint.svg');

   do {
      _str bufname=buf_match(file.filename,1);
      if ( bufname=="" ) {
         status=FILE_NOT_FOUND_RC;break;
      }

      orig_wid := annotated_wid := p_window_id;
      _SVCGetAnnotatedBuffer(file.VCSystem,file.filename,annotated_wid);
   
      index := _SVCGetIndex(file.VCSystem,"_unmark_buffer");
      if ( !index ) {
         status=PROCEDURE_NOT_FOUND_RC;break;
      }
      status=call_index(annotated_wid,index);
      if ( status ) break;

      long seekPositions[];
      int localfile_wid;
      status=_open_temp_view(bufname,localfile_wid,orig_wid,"+b");
      p_view_id=orig_wid;
      if ( status ) break;

      _GetLineSeekPositions(localfile_wid,seekPositions);
      Diff(annotated_wid,localfile_wid,
           DIFF_NO_BUFFER_SETUP|DIFF_DONT_COMPARE_EOL_CHARS|DIFF_DONT_MATCH_NONMATCHING_LINES,
           0,0,0,
           def_load_options,0,0,def_max_fast_diff_size,"","",def_smart_diff_limit,"");

      int vector[];
      _DiffGetMatchVector(vector);
      len := vector._length();
      int i;

      p_view_id=localfile_wid;

      int markerType=_MarkerTypeAlloc();
      _MarkerTypeSetFlags(markerType,VSMARKERTYPEFLAG_AUTO_REMOVE);
      gFileInfo:[fileIndex].annotationMarkerType=markerType;

      int annotated:[];
      for (i=0;i<len;++i) {
         if ( vector[i] ) {
            _str msg=gFileInfo:[fileIndex].annotations[i].date;
            msg :+= ",":+gFileInfo:[fileIndex].annotations[i].userid;
            msg :+= ",":+gFileInfo:[fileIndex].annotations[i].version;
            _StreamMarkerAdd(localfile_wid,seekPositions[vector[i]],1,1,annotatedPicIndex,markerType,msg);
            annotated:[vector[i]]=1;
         }
      }

      userName := "";
      if (_vsUnix()) {
         userName=get_env("USER");
      } else { 
         userName=get_env("USERNAME");
      }
      for (i=1;i<=p_Noflines;++i) {
         if ( annotated:[i]==null ) {
            _StreamMarkerAdd(localfile_wid,seekPositions[i],1,1,modifiedPicIndex,markerType,"Local modification");
         }
      }

      _delete_temp_view(localfile_wid);
      _delete_temp_view(annotated_wid);
      p_view_id=orig_wid;


   } while ( false );

   _SVCFreeAnnotationInfo(file.VCSystem,file.filename);
   refresh('A');
   return status;
}

static int svcAnnotateEnqueueBuffer(_str filename,_str VCSystemName=svc_get_vc_system())
{
   status := 0;
   do {
      status=_SVCCreateVCI(VCSystemName,'c:\cygwin\bin\cvs.exe');
      if ( status ) {
         return status;
      }
      _str fileIndex=svc_file_case(filename);
      _SVCFreeAnnotationInfo(VCSystemName,fileIndex);
      if ( gFileInfo:[fileIndex]!=null ) {
         _StreamMarkerRemoveAllType(gFileInfo:[fileIndex].annotationMarkerType);
      }
      fileid := 0;
      if ( gFileInfo:[fileIndex]!=null ) {
         gFileInfo:[fileIndex].annotationMarkerType=0;
         gFileInfo:[fileIndex].annotations=null;
      }
      status=_SVCGetFile(VCSystemName,filename,fileid);
      if ( status==VSRC_SVC_FILE_NOT_FOUND_RC ) {
         status=_SVCGetNewFile(VCSystemName,filename,fileid);
         if (status) break;
      }

      _SVCNewAnnotationInfo(VCSystemName,filename);
      SVC_ANNOTATION fileAnnotations[];
      status=_SVCGetFileAnnotations(VCSystemName,filename,fileAnnotations);
      if (!status) {
         gFileInfo:[fileIndex].annotations=fileAnnotations;
         gFileInfo:[fileIndex].annotationMarkerType=-1;
      }else{
         _SVCAnnotationQueueAppend(filename,VCSystemName);
         if ( gAnnotateTimerHandle<0 ) {
            gAnnotateTimerHandle=_set_timer(1000,svcAnnotateCallback);
         }
      }
   
   } while ( false );
   return status;
}
static void _SVCAnnotationQueueAppend(_str filename,_str VCSystemName)
{
   SVC_QUEUE_ITEM item;
   item.filename=filename;
   item.VCSystem=VCSystemName;

   gAnnotationQueue[gAnnotationQueue._length()]=item;
}

static _str svc_get_message(int status)
{
   switch (status) {
   case VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC:
      return "VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC";
   case VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC:
      return "VSRC_SVC_VC_INTERFACE_NOT_AVAILABLE_RC";
   case SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC:
      return "SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC";
   case VSRC_SVC_FILE_INTERFACE_NOT_AVAILABLE_RC:
      return "VSRC_SVC_FILE_INTERFACE_NOT_AVAILABLE_RC";
   case VSRC_SVC_FILE_NOT_FOUND_RC:
      return "VSRC_SVC_FILE_NOT_FOUND_RC";
   default:
      return get_message(status);
   }
}
#endif

static _str svc_get_status_name(SVCFileStatus status)
{
   strStatus := "";
   if ( status& SVC_STATUS_SCHEDULED_FOR_ADDITION ) {
      strStatus :+= "|SVC_STATUS_SCHEDULED_FOR_ADDITION";
   }
   if ( status& SVC_STATUS_SCHEDULED_FOR_DELETION ) {
      strStatus :+= "|SVC_STATUS_SCHEDULED_FOR_DELETION";
   }
   if ( status& SVC_STATUS_MODIFIED ) {
      strStatus :+= "|SVC_STATUS_MODIFIED";
   }
   if ( status& SVC_STATUS_CONFLICT ) {
      strStatus :+= "|SVC_STATUS_CONFLICT";
   }
   if ( status& SVC_STATUS_EXTERNALS_DEFINITION ) {
      strStatus :+= "|SVC_STATUS_EXTERNALS_DEFINITION";
   }
   if ( status& SVC_STATUS_IGNORED ) {
      strStatus :+= "|SVC_STATUS_IGNORED";
   }
   if ( status& SVC_STATUS_NOT_CONTROLED ) {
      strStatus :+= "|SVC_STATUS_NOT_CONTROLED";
   }
   if ( status& SVC_STATUS_MISSING ) {
      strStatus :+= "|SVC_STATUS_MISSING";
   }
   if ( status& SVC_STATUS_NODE_TYPE_CHANGED ) {
      strStatus :+= "|SVC_STATUS_NODE_TYPE_CHANGED";
   }
   if ( status& SVC_STATUS_PROPS_MODIFIED ) {
      strStatus :+= "|SVC_STATUS_PROPS_MODIFIED";
   }
   if ( status& SVC_STATUS_PROPS_ICONFLICT ) {
      strStatus :+= "|SVC_STATUS_PROPS_ICONFLICT";
   }
   if ( status& SVC_STATUS_LOCKED ) {
      strStatus :+= "|SVC_STATUS_LOCKED";
   }
   if ( status& SVC_STATUS_SCHEDULED_WITH_COMMIT ) {
      strStatus :+= "|SVC_STATUS_SCHEDULED_WITH_COMMIT";
   }
   if ( status& SVC_STATUS_SWITCHED ) {
      strStatus :+= "|SVC_STATUS_SWITCHED";
   }
   if ( status& SVC_STATUS_NEWER_REVISION_EXISTS ) {
      strStatus :+= "|SVC_STATUS_NEWER_REVISION_EXISTS";
   }
   if ( status& SVC_STATUS_TREE_ADD_CONFLICT ) {
      strStatus :+= "|SVC_STATUS_TREE_ADD_CONFLICT";
   }
   if ( status& SVC_STATUS_TREE_DEL_CONFLICT ) {
      strStatus :+= "|SVC_STATUS_TREE_DEL_CONFLICT";
   }
   if ( status& SVC_STATUS_EDITED ) {
      strStatus :+= "|SVC_STATUS_EDITED";
   }
   strStatus = substr(strStatus,2);
   return strStatus;
}

/**
 * Writes a single string to the output window
 */
void SVCWriteToOutputWindow(_str output)
{
   _str temp[];
   temp[0] = output;
   SVCWriteArrayToOutputWindow(temp);
}

void SVCWriteWIDToOutputWindow(int WID)
{
   origWID := p_window_id;
   p_window_id = WID;
   _str temp[];
   top();up();
   while ( !down() ) {
      get_line(auto curLine);
      ARRAY_APPEND(temp,curLine);
   }
   p_window_id = origWID;

   SVCWriteArrayToOutputWindow(temp);
}

/**
 * Writes an array of strings to the output window
 */
void SVCWriteArrayToOutputWindow(_str output[])
{
   // check to make sure the Output toolbar is visible

   origWID := p_window_id;
   int outputTB=activate_tool_window("_tboutputwin_form");
   if (!outputTB) {
      p_window_id = origWID;
      return;
   }
   outputWid := outputTB._find_control("ctloutput");
   if (!outputWid) {
      p_window_id = origWID;
      return;
   }
   // parse for the output and append new output at the bottom.
   outputWid.bottom();
   i := 0;
   newLine := outputWid.p_newline;
   for (i = 0; i < output._length(); i++) {
      _maybe_append(output[i],newLine);
      outputWid._insert_text(output[i]);
      outputWid.bottom();
   }
   outputWid.center_line();
   // make the Output tab active.
   sstabWid := outputTB._find_control("_output_sstab");
   if (sstabWid) {
      sstabWid.p_ActiveTab = OUTPUTTOOLTAB_OUTPUT;
   }
   p_window_id = origWID;

   orig_def_switchbuf_cd := def_switchbuf_cd;
   def_switchbuf_cd = false;
   origWID._set_focus();
   def_switchbuf_cd = orig_def_switchbuf_cd;
}


_command void svc_gui_browse_repository(_str path='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"browse repository"));
      return;
   }
   if ( !_no_child_windows() ) {
      if (p_name==PROJECT_TOOLBAR_NAME) {
         filename := _getFilenameFromProjectsToolWindow();
         if ( filename!="" ) path = _file_path(filename);
      } else {
         path = _file_path(p_buf_name);
      }
   } else if ( path=="" ) path = getcwd();

   URL := pInterface->localRootPath();
   if ( URL=="" ) {
      pInterface->getLocalFileURL(_file_path(_workspace_filename),URL);
      if ( URL=="" ) {
         pInterface->getLocalFileURL(_file_path(_project_name),URL);
         if ( URL=="" ) {
            if ( !_no_child_windows() ) {
               filename := "";
               if (p_name==PROJECT_TOOLBAR_NAME) {
                  filename = _getFilenameFromProjectsToolWindow();
               } else filename = p_buf_name;
               path = _file_path(filename);
               pInterface->getLocalFileURL(path,URL);
            }
            if ( URL=="" ) {
               curDir := getcwd();
               pInterface->getLocalFileURL(curDir,URL);
            }
         }
      }
   }
   if ( lowcase(svc_get_vc_system())=="git" ) {
      wid := show("-xy -app _git_repository_browser_form",path);
      return;
   }
   show('_svc_repository_browser',URL,autoVCSystem);
}


_command void svc_push_to_repository(_str path='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }

   autoVCSystem := svc_get_vc_system();

   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"push to repository"));
      return;
   }

   if ( path=="" ) {
      path = getcwd();
      _maybe_append_filesep(path);
   }
   pathIn := path;
   status := svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   if (status) {
      if ( status!=COMMAND_CANCELLED_RC ) {
         _message_box(nls(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION, path)));
      }
      return;
   }
   formName := svc_get_form_name(pInterface,SVC_COMMAND_PUSH_TO_REPOSITORY);
   if ( formName=="" ) {
      return;
   }

   pushFlags := 0;
   status = show('-modal 'formName,path,&branchName,&pushRepositoryName,&pushFlags);
   if (status=="" ) {
      return;
   }

   mou_hour_glass(true);
   status = pInterface->pushToRepository(path, branchName, pushRepositoryName, pushFlags);
   if ( status ) {
      _message_box(nls(get_message(status)));
      return;
   }
   pathOut := path;

   SVC_CACHE_ITEM curItem;
   curItem.preservedCasePathIn  = pathIn;
   curItem.preservedCasePathOut = pathOut;
   setCacheInfo(pathIn, curItem);

   saveCacheInfo();
   mou_hour_glass(false);
}

_command void svc_stash(_str path='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_STASH) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"stash"));
      return;
   }

   if ( path=="" ) {
      path = getcwd();
      _maybe_append_filesep(path);
   }
   pathIn := path;

   status := svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   if (status) {
      if ( status!=COMMAND_CANCELLED_RC ) {
         pathList := "\n\n";
         foreach (auto curPath in failedPaths) {
            pathList :+= curPath:+"\n";
         }
         _message_box(nls(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION, pathList)));
      }
      return;
   }
   if ( path=="" ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,"","Could not get remote filename"));
      return;
   }

   formName := svc_get_form_name(pInterface,SVC_COMMAND_STASH);
   if ( formName=="" ) {
      return;
   }

   result := _message_box(nls("Stash files in '%s' now?",path),"",MB_YESNO);
   if ( result !=IDYES ) return;

   if (status=="" ) {
      return;
   }

   mou_hour_glass(true);
   pathOut := path;
   SVCStashFlags stashFlags = 0;

   status = pInterface->stash(path,stashFlags);
   if ( status ) {
      // message handled in interface
      return;
   }

   _ReloadFiles();

   SVC_CACHE_ITEM curItem;
   curItem.preservedCasePathIn  = pathIn;
   curItem.preservedCasePathOut = pathOut;
   setCacheInfo(pathIn, curItem);

   saveCacheInfo();
   mou_hour_glass(false);
}

_command void svc_stash_pop(_str path='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_STASH) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"stash"));
      return;
   }

   if ( path=="" ) {
      path = getcwd();
      _maybe_append_filesep(path);
   }
   pathIn := path;

   status := svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   if ( status==COMMAND_CANCELLED_RC ) {
      return;
   }
   if ( path=="" ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,"","Could not get remote filename"));
      return;
   }

   status = pInterface->getStashList(auto listOfStashes,path,SVC_STASH_LIST);
   if (status) {
      return;
   }
   if ( listOfStashes._length()==0 ) {
      _message_box(nls("Nothing to stash"));
      return;
   }

   result := _message_box(nls("Pop stashed files in '%s' now?",path),"",MB_YESNO);
   if ( result !=IDYES ) return;

   if (status=="" ) {
      return;
   }

   mou_hour_glass(true);
   pathOut := path;
   SVCStashFlags stashFlags = 0;

   status = pInterface->stash(path,SVC_STASH_POP);
   if ( status ) {
      // message handled in interface
      return;
   }

   _ReloadFiles();

   SVC_CACHE_ITEM curItem;
   curItem.preservedCasePathIn  = pathIn;
   curItem.preservedCasePathOut = pathOut;
   setCacheInfo(pathIn, curItem);

   saveCacheInfo();
   mou_hour_glass(false);
}

int svc_stash_get_list(STRARRAY &list,_str path='')
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG;
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      vcsetup();
      return 0;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_STASH) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"stash"));
      return VSRC_SVC_COMMAND_NOT_AVAILABLE;
   }

   if ( path=="" ) {
      path = getcwd();
      _maybe_append_filesep(path);
   }
   pathIn := path;

   status := svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   if ( status ) {
      return status;
   }
   if ( path=="" ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,"","Could not get remote filename"));
      return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
   }

   status = pInterface->getStashList(auto listOfStashes,path,SVC_STASH_LIST);
   if (status) {
      return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
   }

   mou_hour_glass(true);
   pathOut := path;
   _ReloadFiles();

   SVC_CACHE_ITEM curItem;
   curItem.preservedCasePathIn  = pathIn;
   curItem.preservedCasePathOut = pathOut;
   setCacheInfo(pathIn, curItem);

   saveCacheInfo();
   mou_hour_glass(false);
   return 0;
}

/**
 * Get information fore repository from current path. 
 * <B>path</B> is one of the parameters we may be getting as 
 * well if the path passed in does not work with remote commands
 * 
 * @param pInterface instance of IVersionControl interface.
 * @param path input/output.  Path we are starting from.  If 
 *             that path was passed in does not have a cloned
 *             repository, find another local path
 *  
 * Look in the following order: 
 *    * Cache result for <B>path</B> that is passed in
 *    * <B>path</B> that is passed in
 *    * Path of the current file
 *    * Working directory of the current project
 *    * Prompt user with the path that the current workspace is
 *      in
 *    * If no workspace is open, prompt user with the current
 *      path
 *  
 *  
 * @param branchName current branch name
 * @param pushRepositoryName repository to push into
 * @param pullRepositoryName repository to pull from
 * @param failedPaths list of paths we tried to find a cloned 
 *                    repository in
 * 
 * @return int 0 if successful
 */
int svc_get_push_pull_info(IVersionControl *pInterface,_str &path, _str &branchName, _str &pushRepositoryName, 
                           _str &pullRepositoryName, STRARRAY &failedPaths, bool promptForPath=true)
{
   STRHASHTAB pathTable;
   status := 0;
   do {
      if ( path!="" ) {
         getCacheInfo(path, auto cacheItem);
         if ( cacheItem != null ) {
            pathIn := cacheItem.preservedCasePathOut;
            status = pInterface->getPushPullInfo(branchName, pushRepositoryName, pullRepositoryName, pathIn);
            if ( !status ) {
               break;
            }
            ARRAY_APPEND(failedPaths, path);
            pathTable:[_file_case(path)] = path;
         }
      }
      if (!_no_child_windows()) {
         path = _file_path(_mdi.p_child.p_buf_name);
         if ( path!="" && pathTable:[_file_case(path)] == null ) {
            origPath := path;
            status = pInterface->getPushPullInfo(branchName, pushRepositoryName, pullRepositoryName, path);
            if ( !status ) break;
            ARRAY_APPEND(failedPaths, origPath);
            pathTable:[_file_case(path)] = path;
         }
      }
      if ( path!="" && pathTable:[_file_case(path)] == null ) {
         origPath := path;
         status = pInterface->getPushPullInfo(branchName, pushRepositoryName, pullRepositoryName, path);
         if ( !status ) {
            break;
         }
         ARRAY_APPEND(failedPaths, origPath);
         pathTable:[_file_case(path)] = path;
      }
      path = _AbsoluteToProject(_ProjectGet_WorkingDir(_ProjectHandle()));
      if ( path!="" && pathTable:[_file_case(path)] == null ) {
         origPath := path;
         status = pInterface->getPushPullInfo(branchName, pushRepositoryName, pullRepositoryName, path);
         if ( !status ) break;
         ARRAY_APPEND(failedPaths, origPath);
         pathTable:[_file_case(path)] = path;
      }
      if ( _workspace_filename!="" ) {
         path = _file_path(_workspace_filename);
      } else {
         path = getcwd();
         _maybe_append_filesep(path);
      }
      origPath := path;
      status = pInterface->getPushPullInfo(branchName, pushRepositoryName, pullRepositoryName, path);
      if ( path!="" && pathTable:[_file_case(path)] == null ) {
         if ( !status ) break;
         ARRAY_APPEND(failedPaths, origPath);
      }
      if ( promptForPath ) {
         path = _ChooseDirDialog("Directory to pull into", path);
         if ( path=="" ) return(COMMAND_CANCELLED_RC);
      } else path = getcwd();
   } while (false);
   return status;
}

_str svc_get_form_name(IVersionControl *pInterface, SVCCommands command)
{
   systemName := pInterface->getSystemNameCaption();
   formName := "";
   switch ( systemName ) {
   case "git":
      {
         switch ( command ) {
         case SVC_COMMAND_PULL_FROM_REPOSITORY:
            formName = "_git_pull_form";
            break;
         case SVC_COMMAND_PUSH_TO_REPOSITORY:
            formName = "_git_push_form";
            break;
         case SVC_COMMAND_STASH:
            formName = "_git_stash_form";
            break;
         case SVC_COMMAND_CHECKOUT:
            formName = "_git_checkout_form";
            break;
         case SVC_COMMAND_SWITCH:
            formName = "_git_switch_form";
            break;
         }
      }
      break;
   case "subversion":
      {
         switch ( command ) {
         case SVC_COMMAND_CHECKOUT:
            formName = "_svn_checkout_form";
            break;
         }
      }
   }
   return formName;
}

_command void svc_pull_from_repository(_str path='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"pull from repository"));
      return;
   }

   if ( path=="" ) {
      path = getcwd();
      _maybe_append_filesep(path);
   }
   pathIn := path;
   status := svc_get_push_pull_info(pInterface, path,auto branchName="",auto pushRepositoryName="",auto pullRepositoryName="", auto failedPaths);
   if (status) {
      if ( status!=COMMAND_CANCELLED_RC ) {
         pathList := "\n\n";
         foreach (auto curPath in failedPaths) {
            pathList :+= curPath:+"\n";
         }
         _message_box(nls(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION, pathList)));
      }
      return;
   }

   pullFlags := 0;
   formName := svc_get_form_name(pInterface,SVC_COMMAND_PULL_FROM_REPOSITORY);
   if ( formName=="" ) {
      return;
   }

   status = show('-modal 'formName,path,&branchName,&pullRepositoryName,&pullFlags);
   if (status!=0 ) {
      return;
   }

   mou_hour_glass(true);
   status = pInterface->pullFromRepository(path, branchName, pullRepositoryName, pullFlags);
   if ( status ) {
      _message_box(nls(get_message(status)));
      return;
   }
   pathOut := path;

   SVC_CACHE_ITEM curItem;
   curItem.preservedCasePathIn  = pathIn;
   curItem.preservedCasePathOut = pathOut;
   setCacheInfo(pathIn, curItem);

   saveCacheInfo();
   mou_hour_glass(false);
}

static void setCacheInfo(_str path, SVC_CACHE_ITEM &curItem)
{
   gSVCCache:[_file_case(path)] = curItem;
}

static void getCacheInfo(_str path, SVC_CACHE_ITEM &cacheItem)
{
   cacheItem = gSVCCache:[_file_case(path)];
}

static int loadCacheInfo()
{
   gSVCCache = null;
   filename := _ConfigPath():+SVC_CACHE_FILENAME;
   xmlhandle := _xmlcfg_open(filename,VSENCODING_UTF8_WITH_SIGNATURE);
   if ( xmlhandle<0 ) return xmlhandle;

   status := _xmlcfg_find_simple_array(xmlhandle,"/Matches/PathMatch",auto pathMatchIndexes);
   foreach (auto curIndex in pathMatchIndexes) {
      pathIn := _xmlcfg_get_attribute(xmlhandle,(int)curIndex,"PI");
      pathOut := _xmlcfg_get_attribute(xmlhandle,(int)curIndex,"PO");
      SVC_CACHE_ITEM temp;
      temp.preservedCasePathIn = pathIn;
      temp.preservedCasePathOut = pathOut;
      gSVCCache:[_file_case(pathIn)] = temp;
   }
   _xmlcfg_close(xmlhandle);
   return status;
}

static int saveCacheInfo()
{
   filename := _ConfigPath():+SVC_CACHE_FILENAME;
   xmlhandle := _xmlcfg_create(filename,VSENCODING_UTF8_WITH_SIGNATURE,VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if ( xmlhandle<0 ) return xmlhandle;

   pathMatchIndex := _xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX);
   if ( pathMatchIndex<0 ) {
      pathMatchIndex = _xmlcfg_add(xmlhandle, TREE_ROOT_INDEX,"Matches",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   }

   foreach (auto curPath => auto curItem in gSVCCache) {
      curMatchIndex := _xmlcfg_add(xmlhandle, pathMatchIndex,"PathMatch",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(xmlhandle, curMatchIndex, "PI", curItem.preservedCasePathIn);
      _xmlcfg_add_attribute(xmlhandle, curMatchIndex, "PO", curItem.preservedCasePathOut);
   }
   status := _xmlcfg_save(xmlhandle,-1,0);
   _xmlcfg_close(xmlhandle);
   return status;
}

_command void svc_history_diff(_str filename="",_str branchName="",_str version="",bool forceShowHistory=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   autoVCSystem := svc_get_vc_system(filename);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      //_message_box(get_message(VSRC_SVC_COULD_NOT_GET_VC_INTERFACE_RC,svc_get_vc_system()));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY_DIFF) ) {
      _message_box(get_message(VSRC_SVC_COMMAND_NOT_AVAILABLE,"History Diff"));
      return;
   }
   if ( _no_child_windows() && filename=="") {
      _message_box("A file must be open to use this command");
      return;
   }
   if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_DIFF,false,false));
      _str result=_OpenDialog('-modal',
                              'Select file to 'cap,// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return;
      filename=result;
   } else if ( isProjectToolWindow() ) {
      STRARRAY fileList;
      getListFromProjectTree(fileList);
      if (fileList!=null) {
         filename = fileList[0];
      }
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }

   // If this came from a menu it might be quoted
   filename = strip(filename,'B','"');


   // Figure out whether to intially show the newest vesrion or the local file
   // as the file on the left
   localDiff := _historyDiffUseLocalFile("_history_diff_form.ctltype_combo",false) && !forceShowHistory;

   vcSystemName := lowcase(autoVCSystem);
   if (  vcSystemName=="subversion" ) {
      se.vc.SVNVersionedFile svnHistoryFile(filename,branchName);
      // substr(version,2) strips the 'r' from the beginning of the version number
      show('-modal -xy  _history_diff_form',&svnHistoryFile,substr(version,2),localDiff);
   } else if ( vcSystemName=="perforce" ) {
      se.vc.PerforceVersionedFile perforceHistoryFile(filename,branchName);
      show('-modal -xy  _history_diff_form',&perforceHistoryFile,version,localDiff);
   } else if ( vcSystemName=="git" ) {
      se.vc.GitVersionedFile gitHistoryFile(filename,branchName);
      show('-modal -xy  _history_diff_form',&gitHistoryFile,version,localDiff);
   } else if ( vcSystemName=="mercurial" ) {
      se.vc.HgVersionedFile hgHistoryFile(filename,branchName);
      show('-modal -xy  _history_diff_form',&hgHistoryFile,version,localDiff);
   }
}

bool _perforce_changelist(_str vcSystemName, bool value = null) 
{
   if (value == null) {
      value = _perforce_info.userSpecifiesChangeNumber;
      if ( value==null ) {
         // Don't let the value get left null
         _perforce_info.userSpecifiesChangeNumber = value = false;
      }
   } else {
      _perforce_info.userSpecifiesChangeNumber = value;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   return value;
}

int _SVCGetLineNumbers(int &startLineNumber,int &endLineNumber,_str &symbolName="",_str &tagInfo="")
{
   if ( p_object!=OI_EDITOR ) return INVALID_OBJECT_HANDLE_RC;
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);
   _UpdateLocals(true);

   if ( symbolName=="" ) {
      // Update the context message, if current context is local variable
      local_id := tag_current_local();
      if (local_id > 0 && 
          (def_context_toolbar_flags & CONTEXT_TOOLBAR_ADD_LOCALS) &&
          (def_context_toolbar_flags & CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
         //say("_UpdateContextWindow(): local_id="local_id);
         symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
         p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
         return -1;
      }

      // Update the context message
      context_id := tag_current_context();
      if (context_id <= 0) {
         // check if we are in a comment directly before or after a symbol
         //context_id = tag_current_context_or_comment();
      }
      if (context_id <= 0) {
         return VSCODEHELPRC_NO_SYMBOLS_FOUND;
      }
      symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,false,true,false);
   }

   status := _GetLineRangeWithFunctionInfo(p_buf_name,symbolName,tagInfo,startLineNumber,endLineNumber,true);
   return status;
}

_command void svc_diff_current_symbol_with_tip() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   status := _SVCGetLineNumbers(auto startLineNumber1=0,auto endLineNumber1=0,auto symbolName="",auto tagInfo="");
   if ( status || startLineNumber1==0 ||endLineNumber1==0 ) {
      _message_box(nls("Could not get line numbers for current symbol in local file"));
      return;
   }

   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      vcsetup();
      return;
   }

   pInterface->getCurRevision(p_buf_name,auto version="");
   status = pInterface->getFile(p_buf_name,version,auto originalFileWID=0);
   mou_hour_glass(false);
   if ( status ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_FILE,p_buf_name));
      return;
   }
   status = originalFileWID._SVCGetLineNumbers(auto startLineNumber2=0,auto endLineNumber2=0,symbolName,tagInfo);
   if ( status || startLineNumber2==0 || endLineNumber2==0 ) {
      _message_box(nls("Could not get line numbers for remote file.\n\nThe symbol '%s' may not exist in the remote version.",symbolName));
      _delete_temp_view(originalFileWID);
      return;
   }

   pInterface->getRemoteFilename(p_buf_name,auto remoteFilename="");
   fileTitle2 := remoteFilename':'symbolName;
   if ( version!="" ) {
      fileTitle2 :+= '('version')';
   } else {
      fileTitle2 :+= '(HEAD)';
   }
   fileTitle1 := p_buf_name':'symbolName;
   diff('-modal -bi2 -r2 -range1:'startLineNumber1','endLineNumber1'  -range2:'startLineNumber2','endLineNumber2' -file1title '_maybe_quote_filename(fileTitle1)' -file2title '_maybe_quote_filename(fileTitle2)' '_maybe_quote_filename(p_buf_name)' 'originalFileWID.p_buf_id);
   _delete_temp_view(originalFileWID);
}

_command void svc_diff_symbols_with_tip() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   IVersionControl *pInterface = svcGetInterface(svc_get_vc_system());
   if ( pInterface==null ) {
      vcsetup();
      return;
   }

   pInterface->getCurRevision(p_buf_name,auto version="");
   status := pInterface->getFile(p_buf_name,version,auto originalFileWID=0);
   mou_hour_glass(false);
   if ( status ) {
      _message_box(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_FILE,p_buf_name));
      return;
   }
   path2 := originalFileWID.p_buf_name;
   _maybe_append_filesep(path2);
   path2 :+= _strip_filename(p_buf_name, 'P');
   originalFileWID.p_buf_name = path2;

   pInterface->getRemoteFilename(p_buf_name,auto remoteFilename="");
   fileTitle2 := remoteFilename;
   if ( version!="" ) {
      fileTitle2 :+= '('version')';
   } else {
      fileTitle2 :+= '(HEAD)';
   }
   fileTitle1 := p_buf_name;
   diff('-modal -tags -bi2 -r2 -file1title '_maybe_quote_filename(fileTitle1)' -file2title '_maybe_quote_filename(fileTitle2)' '_maybe_quote_filename(p_buf_name)' 'originalFileWID.p_buf_id);
   _delete_temp_view(originalFileWID);
}

static _str SVCGetCurrentSymbolName()
{
   _mdi.p_child._UpdateContext(true);
   local_id := _mdi.p_child.tag_current_local();

   type_name := "";
   symbolName := "";
   if (local_id > 0 && (def_context_toolbar_flags&CONTEXT_TOOLBAR_DISPLAY_LOCALS) ) {
      //say("_UpdateContextWindow(): local_id="local_id);
      tag_get_detail2(VS_TAGDETAIL_local_type,local_id,type_name);
      tag_get_detail2(VS_TAGDETAIL_local_flags,local_id,auto tag_flags);
      symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_local,local_id,true,true,false);
      pic_index := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
      //ContextMessage(caption, pic_index);
      _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
   }else{
      int context_id = _mdi.p_child.tag_current_context();
      if (context_id > 0) {
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
         tag_get_detail2(VS_TAGDETAIL_context_flags,context_id,auto tag_flags);
         symbolName = tag_tree_make_caption_fast(VS_TAGMATCH_context,context_id,true,true,false);
         pic_index := tag_get_bitmap_for_type(tag_get_type_id(type_name), tag_flags);
         _mdi.p_child.p_ModifyFlags |= MODIFYFLAG_CONTEXTWIN_UPDATED;
      }
   }
   parse symbolName with symbolName '(' .;
   return symbolName;
}

void SVCMenuSetup(_str cur_bufname,int vc_menu_handle,int &count,_str system_name)
{
   if ( _no_child_windows() ) cur_bufname=="";

   autoVCSystem := svc_get_vc_system(cur_bufname);

   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      return;
   }
   isProjectToolWindowPopup := p_name=="_proj_tooltab_tree";
   isCheckedOut := -1;
   if ( isProjectToolWindowPopup ) {
      index := _TreeCurIndex();
      if ( index>=0 ) {
         _TreeGetOverlayBitmaps(index,auto bitmapArrayIndex=null);
         _TreeGetCaption(index);
         isCheckedOut = 0;
         len := bitmapArrayIndex._length();
         for ( i:=0;i<len;++i ) {
            if ( bitmapArrayIndex[i]==_pic_file_checkout_overlay ) {
               isCheckedOut = 1;
            }
         }
      }
   }

   vcSystemCaption := pInterface->getSystemNameCaption();
   count = 0;
   just_name := _strip_filename(cur_bufname,'P');

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_DIFF ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_DIFF);
      menuCap := curCap' 'just_name' with most up to date version';
      if ( cur_bufname=="" ) {
         menuCap = curCap' file with 'vcSystemCaption'...';
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_diff_with_tip\t"_maybe_quote_filename(cur_bufname),"","help version control");
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
      // curCap for Diff should have an accelerator already, pull it out 
      // and use O.
      advancedDiffSubHandle := _menu_insert(vc_menu_handle,-1,MF_ENABLED|MF_SUBMENU,"Advanced Diff &Operations","","","help version control");
      if ( !isProjectToolWindowPopup ) {
         menuCap = stranslate(curCap,'','&')' current symb&ol with most up to date version';


         curSymbolName := SVCGetCurrentSymbolName();
         if (curSymbolName!="") {
            menuCap = "Diff "curSymbolName" with most up to date version...";
         } else {
            menuCap = "Diff current symbol with most up to date...";
         }
         _menu_insert(advancedDiffSubHandle,-1,MF_ENABLED,menuCap,"svc_diff_current_symbol_with_tip","","help version control");
//         _menu_insert(advancedDiffSubHandle,-1,MF_ENABLED,"Diff remote verison with predecessor","","","help version control");
//         _menu_insert(advancedDiffSubHandle,-1,MF_ENABLED,"Diff local file with predecessor","","","help version control");
         //++count;
      }
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY);
      menuCap := curCap" for "just_name;
      if ( cur_bufname=="" ) {
         menuCap = "History for file from "vcSystemCaption"...";
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_history\t" _maybe_quote_filename(cur_bufname),'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }
   countAtLastDivider := 0;
   if ( count>0 ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }
   if (just_name!='' && !beginsWith(just_name,'.process')) {
      if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT) &&
           (isCheckedOut==0||isCheckedOut==-1) ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_EDIT);
         menuCap := curCap" "just_name"...";
         if ( cur_bufname=="" ) {
            menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_EDIT)' file in 'vcSystemCaption'...';
         }
         menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_edit\t"_maybe_quote_filename(cur_bufname),'','help version control');
         _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      }
      if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_COMMIT) &&
           (((pInterface->getSystemSpecificFlags()&SVC_REQUIRES_EDIT)==0) || 
           ((pInterface->getSystemSpecificFlags()&SVC_REQUIRES_EDIT)&& 
            (isCheckedOut==1||isCheckedOut==-1) ) )
           ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
         menuCap := curCap" "just_name"...";
         if ( cur_bufname=="" ) {
            menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT)' file to 'vcSystemCaption'...';
         }
         menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_commit\t"_maybe_quote_filename(cur_bufname),'','help version control');
         _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
         ++count;
      }
      if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_UPDATE ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE);
         menuCap := curCap" "just_name"...";
         if ( cur_bufname=="" ) {
            menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE)' file from 'vcSystemCaption'...';
         }
         menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_update\t"_maybe_quote_filename(cur_bufname),'','help version control');
         _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
         ++count;
      }
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_ADD ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_ADD);
      menuCap := curCap" "just_name;
      if ( cur_bufname=="" ) {
         menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_ADD)' file to 'vcSystemCaption'...';
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_add\t"_maybe_quote_filename(cur_bufname),'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REMOVE ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_REMOVE);
      menuCap := curCap" "just_name;
      if ( cur_bufname=="" ) {
         menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_REMOVE)' file from 'vcSystemCaption'...';
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_remove\t"_maybe_quote_filename(cur_bufname),'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REVERT ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_REVERT);
      menuCap := curCap" "just_name;
      if ( cur_bufname=="" ) {
         menuCap = pInterface->getCaptionForCommand(SVC_COMMAND_REVERT)' file from 'vcSystemCaption'...';
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,menuCap,"svc_revert\t"_maybe_quote_filename(cur_bufname),'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY_DIFF ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY_DIFF);
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' on 'just_name,"svc_history_diff\t"_maybe_quote_filename(cur_bufname),'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_SYMBOL_QUERY && !isProjectToolWindowPopup ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_SYMBOL_QUERY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' in 'just_name'...','svc_query','','help version control');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_STASH && !isProjectToolWindowPopup ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_STASH);
      haveStash := true;
      haveMod := true;
      status := 0;
      path := cur_bufname!=""?_file_path(cur_bufname):getcwd();
      path = pInterface->localRootPath(path);
      if ( path!="" ) {
         _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);

         _menu_insert(vc_menu_handle,-1,haveMod?MF_ENABLED:MF_GRAYED,curCap' items in 'path,'svc_stash '_maybe_quote_filename(path),'','help version control');
         ++count;
         if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_STASH_POP) && !isProjectToolWindowPopup ) {
            curCap = pInterface->getCaptionForCommand(SVC_COMMAND_STASH_POP);
            _menu_insert(vc_menu_handle,-1,haveStash?MF_ENABLED:MF_GRAYED,curCap' from '_file_path(path),'svc_stash_pop '_maybe_quote_filename(path),'','help version control');
            ++count;
         }
      }
   }
   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }

   prjVCSystem := svc_get_vc_system(cur_bufname,true);

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH ) {
      // Update is a little different, but be sure to keep things generic
      caption := "Compare Directory with "vcSystemCaption;
      if ( !pInterface->hotkeyUsed('c') ) {
         caption = '&'caption;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate','','help version control');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_FIXED_PATH ) {
      // Update is a little different, but be sure to keep things generic
      caption := "";
      fixedPath := pInterface->getFixedUpdatePath();
      if ( fixedPath=="" ) {
         caption = "Compare with "vcSystemCaption;
      } else {
         caption = "Compare "fixedPath" with "vcSystemCaption;
      }
      if ( !pInterface->hotkeyUsed('c') ) {
         caption = '&'caption;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate_fixed','','help version control');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT
        && _project_name!=""
        && autoVCSystem==prjVCSystem
        ) {
      // Update is a little different, but be sure to keep things generic
      projectName := _strip_filename(_project_name, 'P');
      caption := "";
      if ( !pInterface->hotkeyUsed('p') ) {
         caption = "Compare &Project (" projectName ") with "vcSystemCaption;
      } else {
         caption = "Compare Project (" projectName ") with "vcSystemCaption;
      }
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,"svc_gui_mfupdate_project\t"_project_name,'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT
        && _project_name!=""
        && autoVCSystem==prjVCSystem
        ) {
      // Update is a little different, but be sure to keep things generic
      projectName := _strip_filename(_project_name, 'P');
      caption := "Compare Project and Dependencies with "vcSystemCaption;
      menuPos := _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,"svc_gui_mfupdate_project_dependencies\t"_project_name,'','help version control');
      _mdi.p_child._menu_set_binding(vc_menu_handle, menuPos);
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE 
        && _workspace_filename!="" 
        && autoVCSystem==prjVCSystem
        ) {
      // Update is a little different, but be sure to keep things generic
      caption := "";
      if ( !pInterface->hotkeyUsed('w') ) {
         caption = "Compare &Workspace with "vcSystemCaption;
      } else {
         caption = "Compare Workspace with "vcSystemCaption;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate_workspace','','help version control');
      ++count;
   }

   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }


   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_SWITCH ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_SWITCH);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_switch",'','help version control');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_BROWSE_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_gui_browse_repository",'','help version control');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_PUSH_TO_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_push_to_repository",'','help version control');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_PULL_FROM_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_pull_from_repository",'','help version control');
      ++count;
   }
   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }
#if 0 //4:43pm 8/19/2019
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'&List shelves...',"svc_list_shelves",'','help version control');
   ++count;

   _menu_insert(vc_menu_handle,-1,MF_ENABLED,'Open shelf...',"svc_open_shelf",'','help version control');
   ++count;

   if ( cur_bufname!="" ) {
      len := def_svc_all_shelves._length();
      if ( len>0 ) {
         testHandle := _menu_insert(vc_menu_handle,-1,MF_SUBMENU,"Add to shelf");
         if ( testHandle ) {
            for ( i:=0;i<len;++i ) {
               _menu_insert(testHandle,i,MF_ENABLED,def_svc_all_shelves[i],'svc-add-to-shelf '_maybe_quote_filename(def_svc_all_shelves[i])' '_maybe_quote_filename(cur_bufname));
            }
         }
      }
      ++count;
   }
#endif

   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }

   // Add setup item.  This isn't in the interface, just call vcsetup.  We do
   // use the interface to see what hotkeys are used.
   setupCaption := "&Setup...";
   if ( pInterface->hotkeyUsed('S') ) {
      setupCaption = "S&etup...";
      if ( pInterface->hotkeyUsed('E') ) {
         setupCaption = "Setup...";
      }
   }
   _menu_insert(vc_menu_handle,-1,MF_ENABLED,setupCaption,'vcsetup','','help subversion','Allows you to choose and configure a Version Control System interface');
}
int _SVCGetComment(_str comment_filename,_str &tag,_str file_being_checked_in,bool show_apply_to_all=true,
                   bool &apply_to_all=false,bool show_tag=true,bool show_author=false,_str &author='')
{
   tag='';
   int result=show('-modal -xy _svc_comment_form',comment_filename,file_being_checked_in,show_apply_to_all,show_tag,show_author);
   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }

   // the comment is _param3
   apply_to_all=_param1;
   tag=_param2;
   author=_param4;
   return(0);
}
defeventtab _svc_path_form;
static _str IN_PATH_ON_CHANGE(...) {
   if (arg()) ctlpath.p_user=arg(1);
   return ctlpath.p_user;
}

void _svc_path_form.on_resize()
{
   ctlrecursive.p_visible=ctlok.p_visible=ctlok.p_next.p_visible=ctlok.p_next.p_next.p_visible=false;

   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   int xbuffer=ctltree1.p_x;
   int ybuffer=ctlpath.p_y;

   ctltree1.p_width=client_width-(2*xbuffer);
   ctlpath.p_width=ctltree1.p_width-(ctlpath.p_prev.p_x+ctlpath.p_prev.p_width+100);

   int tree_height=client_height-ctltree1.p_y;
   tree_height-=ctlrecursive.p_height;
   tree_height-=ctlok.p_height;
   tree_height-=4*ybuffer;

   ctltree1.p_height=tree_height;
   ctlrecursive.p_y=ctltree1.p_y_extent+ybuffer;

   ctlrecursive.p_y_extent+ybuffer;

   ctlok.p_y=ctlrecursive.p_y_extent+ybuffer;
   ctlok.p_next.p_y=ctlok.p_next.p_next.p_y=ctlok.p_y;

   ctlrecursive.p_visible=ctlok.p_visible=ctlok.p_next.p_visible=ctlok.p_next.p_next.p_visible=true;
}

static void GetDriveList(_str (&DriveList)[])
{
   if (_isUnix()) {
      DriveList[0]='/';
   } else {
      int temp_view_id;
      int orig_view_id=_create_temp_view(temp_view_id);
      _insert_drive_list();
      top();up();
      while ( !down() ) {
         get_line(auto line);
         DriveList[DriveList._length()]=strip(line);
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
   }
}

static void AddDriveList(_str (DriveList)[])
{
   _TreeBeginUpdate(TREE_ROOT_INDEX,'T');
   int i;
   for ( i=0;i<DriveList._length();++i ) {
      picture := 0;
      if ( _drive_type(DriveList[i])==DRIVE_FIXED ) {
         picture=_pic_drfixed;
      } else {
         picture=_pic_drremov;
      }
      _TreeAddItem(TREE_ROOT_INDEX,DriveList[i],TREE_ADD_AS_CHILD,picture,picture,0);
   }
   _TreeEndUpdate(TREE_ROOT_INDEX);
}

void ctlok.on_create(_str caption='Choose path',_str retrieve_name='',bool disableRecursive=false,int recursiveValue=-1)
{
   _str DriveList[]=null;
   GetDriveList(DriveList);
   ctltree1.AddDriveList(DriveList);
   if ( retrieve_name!='' ) {
      p_active_form.p_name=retrieve_name;
   }
   _retrieve_prev_form();
   ctlpath._retrieve_list();
   autoVCSystem := svc_get_vc_system();
   prjVCSystem := svc_get_vc_system("",true);
   if ( autoVCSystem!=prjVCSystem) {
      path := "";
      if ( !_no_child_windows() ) {
         path = _file_path(_mdi.p_child.p_buf_name);
      }
      IVersionControl *pInterface = svcGetInterface(autoVCSystem);
      if ( pInterface!=null && path!="" ) {
         origPath := getcwd();
         chdir(path,1);
         rootPath := pInterface->localRootPath();
         chdir(origPath,1);
         if ( !isinteger(rootPath) && rootPath!="" ) path = rootPath;
      }
      ctlpath.p_text=path;
   } else {
      if ( ctlpath.p_text=='' ) {
         ctlpath.p_text=getcwd();
      }
   }
   if ( caption!='' ) {
      p_active_form.p_caption=caption;
   }
   if ( disableRecursive ) {
      ctlrecursive.p_enabled = false;
   }
   if ( recursiveValue>=0 ) {
      ctlrecursive.p_value = recursiveValue;
   }
}

_str ctlok.lbutton_up()
{
   return_string := "";
   if ( ctlrecursive.p_value ) {
      return_string='+r ';
   }
   /*if ( ctltagname.p_text!='' ) {
      return_string :+= ' +t 'ctltagname.p_text;
   }*/
   path := ctlpath.p_text;
   _maybe_append_filesep(path);
   path=_maybe_quote_filename(path);
   return_string :+= path;
   _save_form_response();
   p_active_form._delete_window(return_string);
   return(return_string);
}

void ctltree1.on_change(int reason,int index)
{
   if ( reason==CHANGE_SCROLL ) {
      return;
   }
   if ( reason==CHANGE_EXPANDED ) {
      cindex := _TreeGetFirstChildIndex(index);
      if ( cindex<0 ) {
         ExpandPath(index);
      }
   }
   if ( IN_PATH_ON_CHANGE()!=1 && index > 0) {
      ctlpath.p_text=GetPathFromTree(index);
   }
}

static _str GetPathFromTree(int index=-1)
{
   if ( index<0 ) {
      index=_TreeCurIndex();
   }
   _str Path=FILESEP;
   for ( ;; ) {
      if ( index<0 || index==TREE_ROOT_INDEX ) break;
      Cap := _TreeGetCaption(index);
      if ( Cap==FILESEP ) break;
      Path=FILESEP:+Cap:+Path;
      index=_TreeGetParentIndex(index);
   }
   if (_isWindows()) {
      Path=substr(Path,2);
   }
   return(Path);
}

static void ExpandPath(int index)
{
   bool ends_with_pathsep:[];
   _str Path=GetPathFromTree(index);
   _str Paths[]=null;
   cur := "";
   for ( ff:=1;;ff=0 ) {
      //////////////////////////////////////////////////////////////////////////
      // Sometimes if events fall right, a: can get matched before the dialog 
      // comes up.  We will not do the matching for it, and if anybody actually 
      // uses a: for controlled items we will force them to type it in after the 
      // dialog comes up.
      lowcasedPath := lowcase(Path);
      doMatch := p_active_form.p_visible|| (lowcasedPath!="a:\\" && lowcasedPath!="b:\\");
      if ( doMatch ) {
         cur=file_match(_maybe_quote_filename(Path:+ALLFILES_RE),ff);
      }
      if ( cur=='' ) break;
      /*
         Leaving a trailing FILESEP on some of the entries
         messes up the sorting. Temporarily take them off.
      */
      if (_last_char(cur):==_FILESEP) {
         cur=substr(cur,1,length(cur)-1);
         ends_with_pathsep:[cur]=true;
      }
      Paths[Paths._length()]=cur;
   }
   Paths._sort('f'_fpos_case);
   AddedPath := false;
   int i;
   for ( i=0;i<Paths._length();++i ) {
      cur=Paths[i];
      if (ends_with_pathsep._indexin(cur)) {
         strappend(cur,_FILESEP);
      }
      if ( isdirectory(cur) ) {
         cur=substr(cur,1,length(cur)-1);
         cur=_strip_filename(cur,'P');
         if ( cur=='.' || cur=='..' ) continue;
         _TreeAddItem(index,cur,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,0);
         AddedPath=true;
      }
   }
   if ( !AddedPath ) {
      _TreeSetInfo(index,-1);
   }
}

void ctlpath.on_change(int reason)
{
   IN_PATH_ON_CHANGE(1);
   path := p_text;
   if ( iswildcard(_strip_filename(path,'P')) ) {
      path=_strip_filename(path,'N');
   }
   int index=ctltree1.FindPath(path);
   if ( index>0 ) {
      ctltree1._TreeSetCurIndex(index);
   } else {
      ctltree1._TreeTop();
      ctltree1._TreeRefresh();
   }
   IN_PATH_ON_CHANGE(0);
}

static int FindPath(_str Path)
{
   int tree_index=TREE_ROOT_INDEX;
   if (_first_char(Path) == '"') {
      Path = strip(Path,'B','"');
   }
   if ( _isUnix() && _first_char(Path)==FILESEP ) {
      Path=substr(Path,2);
      tree_index=_TreeSearch(TREE_ROOT_INDEX,'/',_fpos_case);
      if ( tree_index<0 ) {
         return(STRING_NOT_FOUND_RC);
      }
      if ( _TreeGetFirstChildIndex(tree_index)<0 ) {
         ExpandPath(tree_index);
      }
   }
   for ( ;; ) {
      _str cur;
      parse Path with cur (FILESEP) Path;
      if ( cur=='' ) break;
      int index=_TreeSearch(tree_index,cur,_fpos_case);
      if ( index<0 ) {
         return(STRING_NOT_FOUND_RC);
      }
      tree_index=index;
      if ( _TreeGetFirstChildIndex(tree_index)<0 ) {
         ExpandPath(tree_index);
      }
   }
   return(tree_index);
}
