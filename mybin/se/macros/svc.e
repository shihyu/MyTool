////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50672 $
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
#include "markers.sh"
#include "cvs.sh"
#include "svc.sh"
#include "diff.sh"
#include "perforce.sh"
#import "backtag.e"
#import "dir.e"
#import "filewatch.e"
#import "guiopen.e"
#import "main.e"
#import "projconv.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svcupdate.e"
#import "toolbar.e"
#import "treeview.sh"
#import "util.e"
#import "vc.e"
#import "wkspace.e"
#require "se/vc/IVersionControl.e"
#require "se/vc/IVersionedFile.e"
#require "se/vc/GitVersionedFile.e"
#require "se/vc/HgVersionedFile.e"
#require "se/vc/PerforceVersionedFile.e"
#require "se/vc/SVNVersionedFile.e"
#require "se/vc/CVSClass.e"
#import "se/vc/GitClass.e"
#import "se/vc/Hg.e"
#import "se/vc/Perforce.e"
#import "se/vc/SVN.e"
#endregion

#define VERSION_CONTROL_LOG         'versionControl'

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

static IVersionControl gInterFaceTable:[];

definit()
{
   gInterFaceTable=null;
   if ( def_perforce_info==null ) {
      def_perforce_info.p4_exe_name = P4_EXE_NAME;
   }
}

/**
* @param vcs Name of version control system 
* 
* @return boolean return true if <B>vcs</B> is an 
*         SVCystem
*/
boolean _SVCIsSVCSystem(_str vcs)
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
IVersionControl *svcGetInterface(_str vcs) {
   vcs = lowcase(vcs);
   if ( gInterFaceTable:[vcs]==null ) {
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
   int index=find_index('_'vcs:+functionName,PROC_TYPE);
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
            boolean append_to_output=false,
            /*CVS_LOG_INFO*/typeless (*pFiles)[]=null,
            boolean &updated_new_dir=false,
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
   boolean any_modified=false;

   if (file_array!=null) {
      int index;
      for (index=0;(!any_modified)&&(index<file_array._length());++index) {
         if (file_array[index]!='' && buf_match(maybe_quote_filename(file_array[index]),1,'hx')!='') {
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
static int SVCCheckLocalFileForConflict(_str filename,boolean &conflict)
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
      boolean conflict=false;
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
               if ( file_eq(dirList[i],filelist[j]) ) {
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
               boolean comment_is_filename=false,_str commit_options='',
               boolean append_to_output=false,typeless (*pFiles)[]=null,
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
                                   boolean JumpToBottom=false,boolean clearBuffer=true)
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
      boolean clear=true;
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
                                     boolean JumpToBottom=false)
{
   if ( !last_operation_status ) {
      int p=pos('aborted',error_output);
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
            boolean append_to_output=false,typeless (*pFiles)[]=null,
            boolean &included_dir=false)
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
#if !__UNIX__
   filename=stranslate(filename,FILESEP2,FILESEP);
#endif
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
                           boolean recurse=true,_str run_from_path='',
                           boolean treat_as_wildcard=true,
                           typeless *pfnPreShellCallback=null,
                           typeless *pfnPostShellCallback=null,
                           typeless *pData=null,
                           int (&IndexHTab):[]=null,
                           boolean RunAsynchronous=false,
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
               boolean append_to_output=false,typeless (*pFiles)[]=null,
               boolean &updated_new_dir=false,_str UpdateOptions='',
               int gaugeParent=0)
{
   status := 0;
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      int index=_SVCGetIndex(_GetVCSystemName(),"Update");
      if ( !index ) {
         _message_box("Could not get interface for version control system "def_vc_system".\n\nSet up version control from Tools>Version Control>Setup");
         return status;
      }
      status = call_index(filelist,OutputFilename,append_to_output,pFiles,
                         updated_new_dir,UpdateOptions,gaugeParent,index);
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_UPDATE) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"update"));
      return SVC_COMMAND_NOT_AVAILABLE;
   }
   status = pInterface->updateFiles(filelist);
                           
   return(status);
}

/**
* Use interface for current version control system to do 
* GUI update of <B>path</B> 
* 
* @param path path to run GUI update for
*/
_command void svc_gui_mfupdate(_str path='') name_info(',')
{
   path = strip(path,'B','"');
   if ( path=='' ) {
      path = show('-modal _cvs_path_form',"Path to Update","svc_gui_mfupdate");
      if ( path=='' ) return;
   }
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   recurse := false;
   SVC_UPDATE_INFO fileStatusList[];
   if ( pos("+r ",path)==1 ) {
      recurse = true;
      path = substr(path,4);
   }

   mou_hour_glass(1);
   status := pInterface->getMultiFileStatus(path,fileStatusList,SVC_UPDATE_PATH,recurse,0,auto remoteURL="");
   mou_hour_glass(0);
   if ( status ) {
      // Message box was shown in getMultiFileStatus
      return;
   }
   if ( fileStatusList._length()==0 ) {
      _message_box("All files up to date");
      return;
   }
   _SVCGUIUpdateDialog(fileStatusList,path,remoteURL);
}

static _str svc_file_case(_str path)
{
   vcs := lowcase(def_vc_system);
   if ( vcs=="mercurial"
        || vcs=="perforce" ) {
      return path;
   }
   return _file_case(path);
}

/**
* Use interface for current version control system to do 
* GUI update of current workspace
* 
*/
_command void svc_gui_mfupdate_workspace() name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
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
   SVCAllFilePathsForWorkspace(_workspace_filename,pathList);
   pInterface->getUpdatePathList(pathList,workspacePath,pathsToUpdate);
//   _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);

   numPathsToUpdate := pathsToUpdate._length();

   _str badPathList="";
   if ( numPathsToUpdate ) {
      // We use a pointer to _CVSShowStallForm so that it is only called the first
      // iteration (because we set it to null after that)
      pfnStallForm := _CVSShowStallForm;
      STRHASHTAB pathsTable;
      remoteURL := "";
      for ( i:=0;i<numPathsToUpdate;++i ) {
         if ( pathsTable:[svc_file_case(pathsToUpdate[i])]==null ) {
            status := pInterface->getMultiFileStatus(pathsToUpdate[i],fileStatusList,SVC_UPDATE_PATH,true,0,auto curRemoteURL);
            if ( status ) {
               if ( status == FILE_NOT_FOUND_RC ) {
                  badPathList = badPathList', 'pathsToUpdate[i];
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
         if ( lowcase(def_vc_system)=="git" ) break;
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
      // Have to manuall call _CVSKillStallForm
      _CVSKillStallForm();
      _maybe_append_filesep(pathsToUpdate[0]);
      origPath := getcwd();
      chdir(pathsToUpdate[0],1);
      rootPath := pInterface->localRootPath();
      if ( rootPath=="" ) {
         rootPath = _file_path(_workspace_filename);
      }
      chdir(origPath,1);
      _SVCGUIUpdateDialog(fileStatusList,rootPath,remoteURL);
   }
}

/**
* Use interface for current version control system to do 
* GUI update of current workspace
* 
*/
_command void svc_gui_mfupdate_project(_str projectFilename=_project_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
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

   _str badPathList="";
   if ( numPathsToUpdate ) {
      // We use a pointer to _CVSShowStallForm so that it is only called the first
      // iteration (because we set it to null after that)
      pfnStallForm := _CVSShowStallForm;
      for ( i:=0;i<numPathsToUpdate;++i ) {
         status := pInterface->getMultiFileStatus(pathsToUpdate[i],fileStatusList,SVC_UPDATE_PATH,true);
         if ( status ) {
            if ( status == FILE_NOT_FOUND_RC ) {
               badPathList = badPathList', 'pathsToUpdate[i];
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
      // Have to manuall call _CVSKillStallForm
      _CVSKillStallForm();
      _maybe_append_filesep(pathsToUpdate[0]);

      parentDirectory := _strip_filename(substr(pathsToUpdate[0],1,length(pathsToUpdate[0])-1),'N');


      _SVCGUIUpdateDialog(fileStatusList,parentDirectory,"");
   }
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
   fileList[fileList._length()] = projectWorkingDir:+'.';

   // Go through and make the hashtable
   fileListLen := fileList._length();
   for ( j:=0;j<fileListLen;++j ) {
      curPath := svc_file_case(_file_path(fileList[j]));
      pathHashtab:[curPath] = '';
   }
   // Copy the hashtable into pathList
   foreach ( auto key => auto val in pathHashtab ) {
      pathList[pathList._length()] = key;
   }
   return 0;
}

static int SVCAllFilePathsForWorkspace(_str workspaceFilename,STRARRAY &pathList)
{
   _str ProjectFiles[];
   _str workpace_path;
   int i;
   // Get all the project files in the workspace
   status:=_GetWorkspaceFiles(workspaceFilename,ProjectFiles);
   if (status) {
      _message_box(nls("Unable to open workspace '%s'",workspaceFilename));
      return(1);
   }
   workpace_path=_strip_filename(workspaceFilename,'N');
   STRARRAY fileList;
   _str pathHashtab:[];
   // Loop thru all the projects in the workspace
   for (i=0;i<ProjectFiles._length();++i) {
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
_command void svc_gui_mfupdate_fixed() name_info(',')
{
   // In this case no path is needed.  It will be calculated in the implentation
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
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
   _str system_name="";
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
   _str funcname='_':+system_name:+'_':+function_suffix;
   int index=find_index(funcname,PROC_TYPE);
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
   _str funcname=system_name:+'_':+function_suffix;
   int index=find_index(funcname,COMMAND_TYPE);
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
               boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               boolean &updated_new_dir=false,
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

#define SVC_AUTH_INFO_INDEX 0

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
   int index=_SVCGetCommandIndex(command_suffix);
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=0;
   status=call_index(filename,index);
   return(status);
}

/**
 * Runs the history command for a specialized version control system 
 * @deprecated use svc_commit 
 */
int _SVCCommit_command(_str filename='',_str comment=NULL_COMMENT)
{
   int index=_SVCGetCommandIndex('commit');
   if ( !index ) {
      return(COMMAND_NOT_FOUND_RC);
   }
   int status=0;
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
   switch (upcase(def_vc_system)) {
   case "CVS":
      exeName = def_cvs_info.cvs_exe_name;
      break;
   case "SUBVERSION":
      exeName = def_svn_info.svn_exe_name;
      break;
   }
   return exeName;
}

/**
 * @param dataToWrite Data to write to log file
 * @param writeToScreen If true, also write <B>dataToWrite</B> 
 *                      to the say window
 * @return int 0 if successful
 */
void _SVCLog(_str dataToWrite,boolean writeToScreen=true)
{
   dsay(dataToWrite, VERSION_CONTROL_LOG);
   if ( writeToScreen ) {
      say(dataToWrite);
   }
}

/** 
 * @param StdErrData stderr output from a specialized version control system
 * 
 * @return boolean true if <B>StdErrData</B> contains a string that indicates that 
 * the user needs to be prompted for login info 
 */
boolean _SVCNeedAuthenticationError(_str StdErrData)
{
   int index=_SVCGetIndex(_GetVCSystemName(),"NeedAuthenticationError");
   if ( !index ) {
      return false;
   }
   boolean status=call_index(StdErrData,index);
                           
   return(status);
}

void SVCInitDialogInfo(SVCHistoryFileInfo &dialogInfo)
{
   dialogInfo.URL = "";
   dialogInfo.localFilename = "";
   dialogInfo.revisionCaptionToSelectInTree = "";
   dialogInfo.currentRevision = "";
   dialogInfo.currentLocalRevision = "";
}

/**
 * Add this so that if there are multiple files selected in 
 * project tool window History command is disabled 
 */
int _OnUpdate_svc_history(CMDUI &cmdui,int target_wid,_str command)
{
   if (target_wid.isProjectToolWindow()) {
      if ( target_wid._TreeGetNumSelectedItems()>1 ) {
         return MF_GRAYED;
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
_command void svc_history(_str filename=p_buf_name,SVC_HISTORY_BRANCH_OPTIONS branchOption=SVC_HISTORY_NOT_SPECIFIED,_str curLocalRevision="",boolean isURL=false) name_info(FILE_ARG',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("history",def_vc_system,filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "def_vc_system".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return;
      }
      call_index(filename,index);
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"history"));
      return;
   }
   if ( _no_child_windows() && filename=='' ) {
      cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY,false,false));
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
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   filename = absolute(filename);
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
   mou_hour_glass(1);
   if ( filename=="" ) {
      _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,"","Could not get remote filename"));
      return;
   }
   do {
      SVCInitDialogInfo(dialogInfo);
      status := pInterface->getHistoryInformation(filename,historyInfo,branchOption);
      if ( status ) break;
      status = pInterface->getCurRevision(filename,auto curRevision="");
      if ( status ) break;
      dialogInfo.localFilename = filename;
      dialogInfo.currentRevision = curRevision;
      if ( curLocalRevision=="" ) {
         status = pInterface->getCurLocalRevision(filename,curLocalRevision);
         if ( status ) break;
      }
      dialogInfo.currentLocalRevision = curLocalRevision;
      dialogInfo.revisionCaptionToSelectInTree = curLocalRevision;
      status = pInterface->getLocalFileURL(filename,auto URL="");
      dialogInfo.URL = URL;
      if ( status ) break;
      status = pInterface->getFileStatus(filename,fileStatus);
      if ( status ) break;
   } while (false);
   mou_hour_glass(0);
   dialogInfo.fileStatus = fileStatus;
   if ( historyInfo._length()>0 ) {
      int wid=show('-new -hidden -xy _svc_history_form',historyInfo,dialogInfo);
      wid.p_visible = 1;
      wid._set_focus();
   }
}

/**
* Use interface for current version control system to diff 
* <b>filename</b> with the current version 
*  
* @param filename File to show differences for
*/
_command void svc_diff_with_tip(_str filename=p_buf_name,_str version="") name_info(FILE_ARG',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("diff_with_tip",def_vc_system,filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "def_vc_system".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return;
      }
      call_index(filename,index);
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_DIFF) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"diff"));
      return ;
   }
   STRARRAY fileList;
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
      fileList[0]=result;
   } else if ( filename=='' ) {
      fileList[0]=p_buf_name;
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else {
      fileList[0] = filename;
   }
   origwid := p_window_id;
   len := fileList._length();
   for (i:=0;i<len;++i) {
      pInterface->diffLocalFile(fileList[i],version);
   }
   p_window_id = origwid;
}
/** 
* Use interface for current version control system to commit
* <b>filename</b>
* 
* @param filename File to commit
* @return 0 if successful
*/
_command int svc_commit(_str filename=p_buf_name,_str comment=null) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      // Allow for old callback setup that nobody used
      index := _SVCGetCommandIndex("commit",def_vc_system,filename);
      if ( !index ) {
         _message_box("Could not get interface for version control system "def_vc_system".\n\nSet up version control from Tools>Version Control>Setup");
         vcsetup();
         return SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
      }
      status := call_index(filename,index);
      return status;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_COMMIT) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"commit"));
      return SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( _no_child_windows() && filename=='' ) {
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
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else {
      fileList[0] = filename;
   }
   // The file does not have to exist.  We could be committing a delete
//   if ( !file_exists(filename) ) {
//      _message_box(nls("The file '%s' does not exist",filename));
//      return;
//   }
   status := pInterface->commitFiles(fileList,comment);

   len := fileList._length();
   for (i:=0;i<len;++i) {
      _filewatchRefreshFile(fileList[i]);
   }
   return status;
}

boolean _SVCBufferIsModified(_str filename)
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
_command int svc_update(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return SVC_VC_INTERFACE_NOT_AVAILABLE_RC;

   STRARRAY fileList;
   if ( _no_child_windows() && filename=='' ) {
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
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
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
         return SVC_COULD_NOT_UPDATE_FILE;
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
_command void svc_revert(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REVERT) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"revert"));
      return;
   }
   STRARRAY fileList;
   cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY,false,false));
   if ( _no_child_windows() && filename=='' ) {
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
      curFilename := fileList[i];
      curFilename = strip(curFilename,'B','"');
      if ( !file_exists(curFilename) ) {
         _message_box(nls("The file '%s' does not exist",curFilename));
         return;
      }
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
      if ( fullPath!="" ) {
         ARRAY_APPEND(fileList,fullPath);
      }
   }
}

static boolean isProjectToolWindow()
{
   return p_name=='_proj_tooltab_tree' && p_parent.p_name=='_tbprojects_form';
}

/**
* Use interface for current version control system to edit 
* (open, checkout) <B>filename</B> 
* 
* @param filename File to edit
*/
_command void svc_edit(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   commandCaption := pInterface->getCaptionForCommand(SVC_COMMAND_EDIT,false,false);
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT) ) {
      _message_box(get_message(SVC_COULD_NOT_EDIT_FILE,commandCaption));
      return;
   }
   cap := lowcase(pInterface->getCaptionForCommand(SVC_COMMAND_EDIT,false,false));
   STRARRAY fileList;
   if ( _no_child_windows() && filename=='' ) {
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
   }
}

void SVCDisplayOutput(_str str,
                       boolean clear_buffer=false,
                       boolean strIsViewId=false,
                       boolean doActivateOutput=true)
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
_command int svc_add(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      _message_box(get_message(SVC_VC_INTERFACE_NOT_AVAILABLE_RC,def_vc_system));
      return SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_ADD) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"add"));
      return SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( _no_child_windows() && filename=='' ) {
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
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
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
_command int svc_remove(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      _message_box(get_message(SVC_VC_INTERFACE_NOT_AVAILABLE_RC,def_vc_system));
      return SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REMOVE) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"remove"));
      return SVC_COMMAND_NOT_AVAILABLE;
   }
   STRARRAY fileList;
   if ( _no_child_windows() && filename=='' ) {
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
   } else if ( isProjectToolWindow() ) {
      getListFromProjectTree(fileList);
   } else {
      fileList[0] = filename;
   }
   status := pInterface->removeFiles(fileList);
   _filewatchRefreshFile(filename);
   return status;
}

_command int svc_checkout(_str filename=p_buf_name) name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      _message_box(get_message(SVC_VC_INTERFACE_NOT_AVAILABLE_RC,def_vc_system));
      return SVC_VC_INTERFACE_NOT_AVAILABLE_RC;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GET_URL_CHILDREN) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"checkout"));
      return SVC_COMMAND_NOT_AVAILABLE;
   }
   
   show('-modal _svc_url_explorer_form');
   return 0;
}

#if 0
_command int svc_annotate(_str filename="") name_info(',')
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
   int status=svcAnnotateEnqueueBuffer(filename,def_vc_system);
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
         mou_hour_glass(1);
         svcAnnotateBuffer(newlyCompletedFiles[i]);
         mou_hour_glass(0);
      }
   }
}

int _CVS_unmark_buffer(int annotated_wid)
{
   int markid=_alloc_selection();
   if ( markid  >= 0 ) {
      int orig_wid=p_window_id;
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
   int status=0;
   _str fileIndex=svc_file_case(file.filename);
   int annotatedPicIndex=find_index('_arrowgt.ico');
   int modifiedPicIndex=find_index('_breakpt.ico');

   do {
      _str bufname=buf_match(file.filename,1);
      if ( bufname=="" ) {
         status=FILE_NOT_FOUND_RC;break;
      }

      int orig_wid=p_window_id,annotated_wid;
      _SVCGetAnnotatedBuffer(file.VCSystem,file.filename,annotated_wid);
   
      int index=_SVCGetIndex(file.VCSystem,"_unmark_buffer");
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
      int len=vector._length();
      int i;

      p_view_id=localfile_wid;

      int markerType=_MarkerTypeAlloc();
      _MarkerTypeSetFlags(markerType,VSMARKERTYPEFLAG_AUTO_REMOVE);
      gFileInfo:[fileIndex].annotationMarkerType=markerType;

      int annotated:[];
      for (i=0;i<len;++i) {
         if ( vector[i] ) {
            _str msg=gFileInfo:[fileIndex].annotations[i].date;
            msg=msg:+",":+gFileInfo:[fileIndex].annotations[i].userid;
            msg=msg:+",":+gFileInfo:[fileIndex].annotations[i].version;
            _StreamMarkerAdd(localfile_wid,seekPositions[vector[i]],1,1,annotatedPicIndex,markerType,msg);
            annotated:[vector[i]]=1;
         }
      }

      _str userName="";
      #if __UNIX__
      userName=get_env("USER");
      #else 
      userName=get_env("USERNAME");
      #endif 
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

static int svcAnnotateEnqueueBuffer(_str filename,_str VCSystemName=def_vc_system)
{
   int status=0;
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
      int fileid=0;
      if ( gFileInfo:[fileIndex]!=null ) {
         gFileInfo:[fileIndex].annotationMarkerType=0;
         gFileInfo:[fileIndex].annotations=null;
      }
      status=_SVCGetFile(VCSystemName,filename,fileid);
      if ( status==SVC_FILE_NOT_FOUND_RC ) {
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
   case SVC_COULD_NOT_GET_VC_INTERFACE_RC:
      return "SVC_COULD_NOT_GET_VC_INTERFACE_RC";
   case SVC_VC_INTERFACE_NOT_AVAILABLE_RC:
      return "SVC_VC_INTERFACE_NOT_AVAILABLE_RC";
   case SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC:
      return "SVC_COULD_NOT_GET_VC_FILE_INTERFACE_RC";
   case SVC_FILE_INTERFACE_NOT_AVAILABLE_RC:
      return "SVC_FILE_INTERFACE_NOT_AVAILABLE_RC";
   case SVC_FILE_NOT_FOUND_RC:
      return "SVC_FILE_NOT_FOUND_RC";
   default:
      return get_message(status);
   }
}
#endif

static _str svc_get_status_name(SVCFileStatus status)
{
   strStatus := "";
   if ( status& SVC_STATUS_SCHEDULED_FOR_ADDITION ) {
      strStatus = strStatus"|SVC_STATUS_SCHEDULED_FOR_ADDITION";
   }
   if ( status& SVC_STATUS_SCHEDULED_FOR_DELETION ) {
      strStatus = strStatus"|SVC_STATUS_SCHEDULED_FOR_DELETION";
   }
   if ( status& SVC_STATUS_MODIFIED ) {
      strStatus = strStatus"|SVC_STATUS_MODIFIED";
   }
   if ( status& SVC_STATUS_CONFLICT ) {
      strStatus = strStatus"|SVC_STATUS_CONFLICT";
   }
   if ( status& SVC_STATUS_EXTERNALS_DEFINITION ) {
      strStatus = strStatus"|SVC_STATUS_EXTERNALS_DEFINITION";
   }
   if ( status& SVC_STATUS_IGNORED ) {
      strStatus = strStatus"|SVC_STATUS_IGNORED";
   }
   if ( status& SVC_STATUS_NOT_CONTROLED ) {
      strStatus = strStatus"|SVC_STATUS_NOT_CONTROLED";
   }
   if ( status& SVC_STATUS_MISSING ) {
      strStatus = strStatus"|SVC_STATUS_MISSING";
   }
   if ( status& SVC_STATUS_NODE_TYPE_CHANGED ) {
      strStatus = strStatus"|SVC_STATUS_NODE_TYPE_CHANGED";
   }
   if ( status& SVC_STATUS_PROPS_MODIFIED ) {
      strStatus = strStatus"|SVC_STATUS_PROPS_MODIFIED";
   }
   if ( status& SVC_STATUS_PROPS_ICONFLICT ) {
      strStatus = strStatus"|SVC_STATUS_PROPS_ICONFLICT";
   }
   if ( status& SVC_STATUS_LOCKED ) {
      strStatus = strStatus"|SVC_STATUS_LOCKED";
   }
   if ( status& SVC_STATUS_SCHEDULED_WITH_COMMIT ) {
      strStatus = strStatus"|SVC_STATUS_SCHEDULED_WITH_COMMIT";
   }
   if ( status& SVC_STATUS_SWITCHED ) {
      strStatus = strStatus"|SVC_STATUS_SWITCHED";
   }
   if ( status& SVC_STATUS_NEWER_REVISION_EXISTS ) {
      strStatus = strStatus"|SVC_STATUS_NEWER_REVISION_EXISTS";
   }
   if ( status& SVC_STATUS_TREE_ADD_CONFLICT ) {
      strStatus = strStatus"|SVC_STATUS_TREE_ADD_CONFLICT";
   }
   if ( status& SVC_STATUS_TREE_DEL_CONFLICT ) {
      strStatus = strStatus"|SVC_STATUS_TREE_DEL_CONFLICT";
   }
   if ( status& SVC_STATUS_EDITED ) {
      strStatus = strStatus"|SVC_STATUS_EDITED";
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
   int outputTB=activate_toolbar("_tboutputwin_form","");
   if (!outputTB) {
      p_window_id = origWID;
      return;
   }
   int outputWid = outputTB._find_control("ctloutput");
   if (!outputWid) {
      p_window_id = origWID;
      return;
   }
   // parse for the output and append new output at the bottom.
   outputWid.bottom();
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      outputWid.insert_line(output[i]);
      outputWid.bottom();
   }
   outputWid.center_line();
   // make the Output tab active.
   int sstabWid = outputTB._find_control("_output_sstab");
   if (sstabWid) {
      sstabWid.p_ActiveTab = OUTPUTTOOLTAB_OUTPUT;
   }
   p_window_id = origWID;
}

_command void svc_gui_browse_repository(_str path='') name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"browse repository"));
      return;
   }
   if ( !_no_child_windows() ) {
      path = _file_path(p_buf_name);
   } else if ( path=="" ) path = getcwd();

   URL := pInterface->localRootPath();
   if ( URL=="" ) {
      pInterface->getLocalFileURL(_file_path(_workspace_filename),URL);
      if ( URL=="" ) {
         pInterface->getLocalFileURL(_file_path(_project_name),URL);
         if ( URL=="" ) {
            if ( !_no_child_windows() ) {
               pInterface->getLocalFileURL(_file_path(p_buf_name),URL);
            }
            if ( URL=="" ) {
               curDir := getcwd();
               pInterface->getLocalFileURL(curDir,URL);
            }
         }
      }
   }
   if ( URL=="" ) {
      // Still show the dialog in case user wants to try to type in manually
      _message_box("Could not get remote path information");
   }
   show('_svc_repository_browser',URL);
}

_command void svc_push_to_repository() name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"browse repository"));
      return;
   }
   mou_hour_glass(1);
   pInterface->pushToRepository();
   mou_hour_glass(0);
}

_command void svc_pull_from_repository(_str path='') name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"browse repository"));
      return;
   }
   mou_hour_glass(1);
   pInterface->pullFromRepository();
   mou_hour_glass(0);
}

_command void svc_history_diff(_str filename="") name_info(',')
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) {
      //_message_box(get_message(SVC_COULD_NOT_GET_VC_INTERFACE_RC,def_vc_system));
      vcsetup();
      return;
   }
   if ( !(pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY_DIFF) ) {
      _message_box(get_message(SVC_COMMAND_NOT_AVAILABLE,"History Diff"));
      return;
   }
   if ( _no_child_windows() ) {
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
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }

   // If this came from a menu it might be quoted
   filename = strip(filename,'B','"');

   vcSystemName := lowcase(def_vc_system);
   if (  vcSystemName=="subversion" ) {
      se.vc.SVNVersionedFile svnHistoryFile(filename);
      show('-modal -xy  _history_diff_form',&svnHistoryFile);
   } else if ( vcSystemName=="perforce" ) {
      se.vc.PerforceVersionedFile perforceHistoryFile(filename);
      show('-modal -xy  _history_diff_form',&perforceHistoryFile);
   } else if ( vcSystemName=="git" ) {
      se.vc.GitVersionedFile gitHistoryFile(filename);
      show('-modal -xy  _history_diff_form',&gitHistoryFile);
   } else if ( vcSystemName=="mercurial" ) {
      se.vc.HgVersionedFile hgHistoryFile(filename);
      show('-modal -xy  _history_diff_form',&hgHistoryFile);
   }
}

boolean _perforce_changelist(_str vcSystemName, boolean value = null) 
{
   if (value == null) {
      value = def_perforce_info.userSpecifiesChangeNumber;
      if ( value==null ) value = false;
   } else {
      def_perforce_info.userSpecifiesChangeNumber = value;
   }
   return value;
}

void SVCMenuSetup(_str cur_bufname,int vc_menu_handle,int &count,_str system_name)
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
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

   vcSystemName := pInterface->getSystemNameCaption();
   count = 0;
   _str just_name=_strip_filename(cur_bufname,'P');

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_DIFF ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_DIFF);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' 'just_name' with most up to date version',"svc_diff_with_tip "maybe_quote_filename(cur_bufname),"","help perforce");
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap" for "just_name,"svc_history " maybe_quote_filename(cur_bufname),'','help perforce');
      ++count;
   }
   countAtLastDivider := 0;
   if ( count>0 ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }
   if (just_name!='' && just_name!='.process') {
      if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_EDIT) &&
           (isCheckedOut==0||isCheckedOut==-1) ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_EDIT);
         _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap" "just_name"...","svc_edit "maybe_quote_filename(cur_bufname),'','help perforce');
      }
      if ( (pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_COMMIT) &&
           (((pInterface->getSystemSpecificFlags()&SVC_REQUIRES_EDIT)==0) || 
           ((pInterface->getSystemSpecificFlags()&SVC_REQUIRES_EDIT)&& 
            (isCheckedOut==1||isCheckedOut==-1) ) )
           ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_COMMIT);
         _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap" "just_name"...","svc_commit "maybe_quote_filename(cur_bufname),'','help perforce');
         ++count;
      }
      if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_UPDATE ) {
         curCap := pInterface->getCaptionForCommand(SVC_COMMAND_UPDATE);
         _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap" "just_name,"svc_update "maybe_quote_filename(cur_bufname),'','help perforce');
         ++count;
      }
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_ADD ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_ADD);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap" "just_name,"svc_add  "maybe_quote_filename(cur_bufname),'','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REMOVE ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_REMOVE);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' 'just_name,"svc_remove "maybe_quote_filename(cur_bufname),'','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_REVERT ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_REVERT);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' 'just_name,'svc_revert 'maybe_quote_filename(cur_bufname),'','help perforce');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_HISTORY_DIFF ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_HISTORY_DIFF);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap' on 'just_name,'svc_history_diff 'maybe_quote_filename(cur_bufname),'','help perforce');
      ++count;
   }
   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH ) {
      fixedPath := pInterface->getFixedUpdatePath();
      // Update is a little different, but be sure to keep things generic
      caption := "Compare Directory with "vcSystemName;
      if ( !pInterface->hotkeyUsed('c') ) {
         caption = '&'caption;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate','','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_FIXED_PATH ) {
      fixedPath := pInterface->getFixedUpdatePath();
      // Update is a little different, but be sure to keep things generic
      caption := "";
      if ( fixedPath=="" ) {
         caption = "Compare with "vcSystemName;
      } else {
         caption = "Compare "fixedPath" with "vcSystemName;
      }
      if ( !pInterface->hotkeyUsed('c') ) {
         caption = '&'caption;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate_fixed','','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE ) {
      fixedPath := pInterface->getFixedUpdatePath();
      // Update is a little different, but be sure to keep things generic
      caption := "";
      if ( !pInterface->hotkeyUsed('w') ) {
         caption = "Compare &Workspace with "vcSystemName;
      } else {
         caption = "Compare Workspace with "vcSystemName;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate_workspace','','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT ) {
      fixedPath := pInterface->getFixedUpdatePath();
      // Update is a little different, but be sure to keep things generic
      caption := "";
      if ( !pInterface->hotkeyUsed('p') ) {
         caption = "Compare &Project with "vcSystemName;
      } else {
         caption = "Compare Project with "vcSystemName;
      }
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,caption,'svc_gui_mfupdate_project '_project_name,'','help perforce');
      ++count;
   }

   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_CHECKOUT ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_CHECKOUT);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_checkout",'','help perforce');
      ++count;
   }

   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_BROWSE_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_gui_browse_repository",'','help perforce');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_PUSH_TO_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_push_to_repository",'','help perforce');
      ++count;
   }
   if ( pInterface->commandsAvailable()&SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY ) {
      curCap := pInterface->getCaptionForCommand(SVC_COMMAND_PULL_FROM_REPOSITORY);
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,curCap'...',"svc_pull_from_repository",'','help perforce');
      ++count;
   }
   if ( count>countAtLastDivider ) {
      _menu_insert(vc_menu_handle,-1,MF_ENABLED,'-',0);
      ++count;
      countAtLastDivider = count;
   }


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
