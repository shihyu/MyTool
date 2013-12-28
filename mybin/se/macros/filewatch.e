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
#include "filewatch.sh"
#import "main.e"
#include "subversion.sh"
#import "stdprocs.e"
#import "stdcmds.e"
#import "subversion.e"
#import "subversionutil.e"
#import "svc.e"
#import "sc/lang/Timer.e"
#require "se/files/FileWatcherManager.e"
#require "se/vc/Perforce.e"
#import "projconv.e"
#import "tbsearch.e"
#import "wkspace.e"
#import "vc.e"
#endregion

using namespace se.files;

static FileWatcherManager gPersistentPathWatcher;

definit()
{
   if ( upcase(arg(1))!='L' ) {
      FileWatcherManager temp;
      gPersistentPathWatcher = temp;
      gPersistentPathWatcher.clearWatchedPaths();

      filewatcherInitType(WATCHEDPATH_SVN);
      filewatcherInitType(WATCHEDPATH_PERFORCE);
   }
}

static int svnWatchedPathCallback(WATCHED_FILE_INFO fileInfo,typeless &Info)
{
   if ( !def_svn_show_file_status ) {
      return 1;
   }
   return genericWatchedPathCallback(fileInfo,Info);
}

static int perforceWatchedPathCallback(WATCHED_FILE_INFO fileInfo,typeless &Info)
{
   if ( !def_perforce_show_file_status ) {
      return 1;
   }
   return genericWatchedPathCallback(fileInfo,Info);
}

static int genericWatchedPathCallback(WATCHED_FILE_INFO fileInfo,typeless &Info)
{
   _str refreshedWindowList = Info;

   if ( !pos(' _tbopen_form ',' ':+refreshedWindowList:+' ') ) {
      openFormWID := _find_formobj('_tbopen_form','N');
      if ( openFormWID ) {
         file_treeWID := openFormWID._find_control("_file_tree");
         if ( file_treeWID ) {
            file_treeWID._TreeRefresh();
            refreshedWindowList = refreshedWindowList:+' _tbopen_form ';
         }
      }
   }

   if ( !pos(' _tbfilelist_form ',' ':+refreshedWindowList:+' ') ) {
      fileListFormWID := _find_formobj('_tbfilelist_form','N');
      if ( fileListFormWID ) {
         ctl_file_listWID := fileListFormWID._find_control("ctl_file_list");
         if ( ctl_file_listWID ) {
            ctl_file_listWID._TreeRefresh();
            // We only need to add one of the trees
            refreshedWindowList = refreshedWindowList:+' _tbfilelist_form ';
         }
         ctl_project_listWID := fileListFormWID._find_control("ctl_project_list");
         if ( ctl_project_listWID ) {
            ctl_project_listWID._TreeRefresh();
         }
         ctl_workspace_listWID := fileListFormWID._find_control("ctl_workspace_list");
         if ( ctl_workspace_listWID ) {
            ctl_workspace_listWID._TreeRefresh();
         }
      }
   }

   if ( !pos(' _tbprojects_form ',' ':+refreshedWindowList:+' ') ) {
      projectsFormWID := _find_formobj('_tbprojects_form','N');
      if ( projectsFormWID ) {
         _proj_tooltab_treeWID := projectsFormWID._find_control("_proj_tooltab_tree");
         if ( _proj_tooltab_treeWID ) {
            _proj_tooltab_treeWID._TreeRefresh();
            refreshedWindowList = refreshedWindowList:+' _tbprojects_form ';
         }
      }
   }
   Info = refreshedWindowList;
   return 0;
}

#if 0 //8:59am 1/19/2010
_command void test_filewatch() name_info(',')
{
   FileWatcherManager temp;
   gFileWatcher = temp;

   //gFileWatcher.addWatchedPath('C:\src\15.0\slickedit\',WATCHEDPATH_SVN,svnWatchedPathCallback);
   gFileWatcher.addWatchedPath('C:\src\svn_tests\slickedit-winbuild01\',WATCHEDPATH_SVN,svnWatchedPathCallback,false);
   if ( !gFileWatcher.isRunning() ) {
      gFileWatcher.start();
   }
}

_command void test_filewatch_file() name_info(',')
{
   FileWatcherManager temp;
   gFileWatcher = temp;

   //gFileWatcher.addWatchedPath('C:\src\15.0\slickedit\',WATCHEDPATH_SVN,svnWatchedPathCallback);
   gFileWatcher.addWatchedPath('C:\src\15.0\slickedit\clib\alist.cpp',WATCHEDPATH_SVN,svnWatchedPathCallback,false);
   if ( !gFileWatcher.isRunning() ) {
      gFileWatcher.start();
   }
}

_command void test_filewatch2() name_info(',')
{
   FileWatcherManager temp;
   gFileWatcher = temp;

   //gFileWatcher.addWatchedPath('C:\src\15.0\slickedit\',WATCHEDPATH_SVN,svnWatchedPathCallback);
   gFileWatcher.addWatchedPath('C:\src\svn_tests\slickedit-winbuild01\clib\',WATCHEDPATH_SVN,svnWatchedPathCallback,false);
   gFileWatcher.addWatchedPath('C:\src\svn_tests\slickedit-winbuild01\rt\slick\',WATCHEDPATH_SVN,svnWatchedPathCallback,false);
   if ( !gFileWatcher.isRunning() ) {
      gFileWatcher.start();
   }
}
_command void test_filewatch3() name_info(',')
{
   FileWatcherManager temp;
   gFileWatcher = temp;
   say('test_filewatch3 ****************************************************************************************************');
   FileWatcherManager.clearWatchedPaths();

   FileWatcherManager.addWatchedPath('C:\src\svn_tests\slickedit-winbuild01\clib\',WATCHEDPATH_SVN,svnWatchedPathCallback,false);
   FileWatcherManager.addWatchedPath('C:\src\svn_tests\slickedit-winbuild01\rt\slick\',WATCHEDPATH_SVN,svnWatchedPathCallback,false);

   WATCHED_PATH_REQUEST_INFO watchedPaths[];
   FileWatcherManager.getWatchedPaths(WATCHEDPATH_SVN,watchedPaths);

   len := watchedPaths._length();
   for ( i:=0;i<len;++i ) {
      say('test_filewatch3 10 watchedPaths['i'].path='watchedPaths[i].path);
   }

//   FileWatcherManager.removeWatchedPathType(WATCHEDPATH_SVN);

   say('test_filewatch3 ****************************************************************************************************');
   FileWatcherManager.getWatchedPaths(WATCHEDPATH_SVN,watchedPaths);

   len = watchedPaths._length();
   for ( i=0;i<len;++i ) {
      say('test_filewatch3 20 watchedPaths['i'].path='watchedPaths[i].path);
   }
   if ( !gFileWatcher.isRunning() ) {
      gFileWatcher.start();
   }
}

_command void test_filewatch_ind_path() name_info(',')
{
   FileWatcherManager temp;
   gFileWatcher = temp;

   _str ProjectFiles[];
   _GetWorkspaceFiles(_workspace_filename, ProjectFiles);

   _str pathTable:[];
   len := ProjectFiles._length();
   for ( i:=0;i<len;++i ) {
      absCurProject := absolute(ProjectFiles[i],_file_path(_workspace_filename));

      projPath := _ProjectGet_WorkingDir(_ProjectHandle(absCurProject));
      absProjPath := _file_path(absCurProject);
      projPath = relative(projPath,absProjPath);
      projPath = absolute(projPath,absProjPath);

      pathTable:[_file_case(projPath)] = projPath;
   }
   _str pathList[];
   pathList[0] = 'c:\temp\';
   foreach ( auto pathName in pathTable ) {
      pathList[pathList._length()] = pathName;
   }
   pathList[pathList._length()] = 'c:\src\';

   _str workspacePath = _file_path(_workspace_filename);
   _str pathsToUpdate[];
   getUpdatePathList(pathList,workspacePath,pathsToUpdate);

   len = pathsToUpdate._length();
   for ( i=0;i<len;++i ) {
      say('test_filewatch_ind_path pathsToUpdate['i']='pathsToUpdate[i]);
   }
}
#endif

#if 1 //9:00am 1/19/2010
void _wkspace_close_filewatch_vc()
{
   WATCHED_PATH_REQUEST_INFO watchedPaths[];
   gPersistentPathWatcher.getWatchedPaths(WATCHEDPATH_SVN,watchedPaths);
   len := watchedPaths._length();
//   say('_wkspace_close_filewatch_vc before removing paths len='len);
   for ( i:=0;i<len;++i ) {
//      say('                            watchedPaths['i']='watchedPaths[i].path);
   }
   // Any time we close the project, remove the SVN elements
   gPersistentPathWatcher.removeWatchedPathType(WATCHEDPATH_SVN);

   gPersistentPathWatcher.getWatchedPaths(WATCHEDPATH_SVN,watchedPaths);
//   say('_wkspace_close_filewatch_vc after removing paths');
   len = watchedPaths._length();
   for ( i=0;i<len;++i ) {
//      say('                            watchedPaths['i']='watchedPaths[i].path);
   }
}

void _workspace_opened_filewatch_vc()
{
   startWatchingSVN();
   startWatchingPerforce();
}

_command void test_stop_svn() name_info(',')
{
   filewatcherStop(WATCHEDPATH_SVN);
}

void _exit_filewatch()
{
   if ( gPersistentPathWatcher!=null ) {
      gPersistentPathWatcher.kill();
      gPersistentPathWatcher = null;
   }
   filewatcherStop(WATCHEDPATH_SVN);
}
#endif

/**
 * @return boolean true if we are watching subversion
 */
static boolean watchingSVN()
{
   systemName := lowcase(_GetVCSystemName());
   return systemName=="subversion" && def_svn_show_file_status;
}

/**
 * @return boolean true if we are watching subversion
 */
static boolean watchingPerforce()
{
   systemName := lowcase(_GetVCSystemName());
   return systemName=="perforce" && def_perforce_show_file_status;
}

/** 
 * Turn on the remote path watching for Subversion 
 */
static void startWatchingSVN()
{
//   say('startWatchingSVN in');
   systemName := lowcase(_GetVCSystemName());
   if ( systemName=="subversion" && def_svn_show_file_status ) {
//      say('startWatchingSVN in if');
      STRARRAY pathList;
      _GetAllProjectWorkingDirs(_workspace_filename,pathList);
      workspacePath := _file_path(_workspace_filename);

      STRARRAY pathsToUpdate;
      _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);
      len := pathsToUpdate._length();
      for ( i:=0;i<len;++i ) {
         gPersistentPathWatcher.addWatchedPath(pathsToUpdate[i],WATCHEDPATH_SVN,true,svnWatchedPathCallback);
      }

      if ( !gPersistentPathWatcher.isRunning() ) {
//         say('startWatchingSVN calling start');
         gPersistentPathWatcher.start();
      }
      gPersistentPathWatcher.setThreadInterval(def_svn_update_interval*1000);
   }
}

/** 
 * Turn off the remote path watching for Subversion 
 */
static void stopWatchingSVN()
{
   filewatcherStop(WATCHEDPATH_SVN);
   gPersistentPathWatcher.removeWatchedPathType(WATCHEDPATH_SVN);
}

/** 
 * Turn on the remote path watching for Subversion 
 */
static void startWatchingPerforce()
{
   systemName := lowcase(_GetVCSystemName());
   if ( systemName=="perforce" && def_perforce_show_file_status ) {
//      say('startWatchingPerforce in if');
      STRARRAY pathList;
      _GetAllProjectWorkingDirs(_workspace_filename,pathList);
      workspacePath := _file_path(_workspace_filename);

      STRARRAY pathsToUpdate;
      //_SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);
      //say('startWatchingPerforce pathsToUpdate._length()='pathsToUpdate._length());
      se.vc.IVersionControl *pInterface = svcGetInterface(def_vc_system);
      if ( pInterface!=null ) {
         localRoot := pInterface->getSystemSpecificInfo("localroot");
         pathsToUpdate[0] = localRoot;
         _maybe_append_filesep(pathsToUpdate[0]);
         pathsToUpdate[0] = pathsToUpdate[0]"...";
      }

      len := pathsToUpdate._length();
      for ( i:=0;i<len;++i ) {
         gPersistentPathWatcher.addWatchedPath(pathsToUpdate[i],WATCHEDPATH_PERFORCE,true,svnWatchedPathCallback);
      }

      if ( !gPersistentPathWatcher.isRunning() ) {
//         say('startWatchingPerforce calling start');
         gPersistentPathWatcher.start();
      }
      gPersistentPathWatcher.setThreadInterval(def_perforce_update_interval*1000);
   }
}

/** 
 * Turn off the remote path watching for Subversion 
 */
static void stopWatchingPerforce()
{
   filewatcherStop(WATCHEDPATH_PERFORCE);
   gPersistentPathWatcher.removeWatchedPathType(WATCHEDPATH_PERFORCE);
}

/**
 * Get all the working directories of all projects in the 
 * current workspace 
 *  
 * @param workspace_filename 
 * @param pathList list of all the working directories is 
 *                 returned here
 */
void _GetAllProjectWorkingDirs(_str workspace_filename,STRARRAY &pathList)
{
   // Merge the paths together into the smallest number of paths we will need
   _str workspacePath = _file_path(_workspace_filename);
   _str pathsToUpdate[];
   _str ProjectFiles[];
   _str pathTable:[];
   _GetWorkspaceFiles(_workspace_filename, ProjectFiles);
   len := ProjectFiles._length();
   for ( i:=0;i<len;++i ) {
      absCurProject := absolute(ProjectFiles[i],_file_path(_workspace_filename));

      projPath := _ProjectGet_WorkingDir(_ProjectHandle(absCurProject));
      absProjPath := _file_path(absCurProject);
      projPath = relative(projPath,absProjPath);
      projPath = absolute(projPath,absProjPath);

      pathTable:[_file_case(projPath)] = projPath;
   }
   foreach ( auto pathName in pathTable ) {
      pathList[pathList._length()] = pathName;
   }
}

void _before_write_state_filewatch()
{
   if ( gPersistentPathWatcher!=null ) {
      gPersistentPathWatcher.prepareForWriteState();
   }
}

void _after_write_state_filewatch()
{
   if ( gPersistentPathWatcher!=null ) {
      gPersistentPathWatcher.recoverFromWriteState();
   }
}

/** 
 * If we are watching a version contol system, run 
 * filewatcherAddPath with recursion off for that path so that 
 * file's status is updated in version control 
 * 
 * @return int 0 if successful
 */
int _cbsave_filewatch()
{
   status := _filewatchRefreshFile(p_buf_name);
   return status;
}

int _filewatchRefreshFile(_str filename)
{
   curPath := _file_path(filename);
   if ( curPath!="" ) {
      isSVN := watchingSVN();
      isPerforce := watchingPerforce();
      if ( !isSVN && !isPerforce  ) {
         // Nothing to do
         return 0;
      }

      if ( isSVN||isPerforce ) {
         workspacePath := _file_path(_workspace_filename);
         watchedPathType := 0;
         STRARRAY curPathList;
         curPathList[0] = curPath;
         _str pathsToUpdate[];
         if ( isSVN ) {
            _SVNGetUpdatePathList(curPathList,workspacePath,pathsToUpdate);
            watchedPathType = WATCHEDPATH_SVN;
         } else if ( isPerforce ) {
            pathsToUpdate[0] = curPath;
            watchedPathType = WATCHEDPATH_PERFORCE;
         }
         _str altWatchedPath = "";
         if ( pathsToUpdate[0]!=null ) {
            altWatchedPath = pathsToUpdate[0];
         }
         filewatcherAddPath(filename,watchedPathType,false,altWatchedPath);
      }
   }
   return 0;
}

void _filewatchRefreshFiles(STRARRAY &filenameList)
{
   len := filenameList._length();
   for ( i:=0;i<len;++i ) {
      _filewatchRefreshFile(filenameList[i]);
   }
}

/** 
 * Callback for config dialog 
 *  
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _filewatch_subversion_interval(_str vcsystem,int value = null)
{
//   say('_filewatch_subversion_interval in');
   if ( value!=null ) {
      def_svn_update_interval = value * 60;
      stopWatchingSVN();
      startWatchingSVN();
   }
   return def_svn_update_interval intdiv 60;
}

/**
 * Callback for config dialog 
 * 
 * @param vcsystem Name of version control system
 * @param value new value
 * 
 * @return boolean true if filewatching for this system is on
 */
boolean _filewatch_subversion_onoff(_str vcsystem,boolean value = null)
{
//   say('_filewatch_subversion_onoff in');
   if ( value!=null ) {
      if ( value ) {
         def_svn_show_file_status = 1;
         startWatchingSVN();
      }else{
         def_svn_show_file_status = 0;
         stopWatchingSVN();
      }
   }else{
      value = def_svn_show_file_status!=0;
   }
   return value;
}
/** 
 * Callback for config dialog 
 *  
 * @param int value           the new value to set - use null 
 *                            to get the current value
 * 
 * @return int                the current value
 */
int _filewatch_perforce_interval(_str vcsystem,int value = null)
{
//   say('_filewatch_perforce_interval in');
   if ( value!=null ) {
      def_perforce_update_interval = value * 60;
      stopWatchingPerforce();
      startWatchingPerforce();
   }
   return def_perforce_update_interval intdiv 60;
}

/**
 * Callback for config dialog 
 * 
 * @param vcsystem Name of version control system
 * @param value new value
 * 
 * @return boolean true if filewatching for this system is on
 */
boolean _filewatch_perforce_onoff(_str vcsystem,boolean value = null)
{
//   say('_filewatch_perforce_onoff in');
   if ( value!=null ) {
      if ( value ) {
         def_perforce_show_file_status = 1;
         startWatchingPerforce();
      }else{
         def_perforce_show_file_status = 0;
         stopWatchingPerforce();
      }
   }else{
      value = def_perforce_show_file_status!=0;
   }
   return value;
}
