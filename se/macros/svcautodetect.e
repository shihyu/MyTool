#pragma option(pedantic,on)
#region Imports
#include 'slick.sh'
#include 'filewatch.sh'
#import 'git.e'
#import 'projconv.e'
#import 'ptoolbar.e'
#import 'stdprocs.e'
#import 'subversion.e'
#import 'svc.e'
#import 'vc.e'
#import 'wkspace.e'
#endregion Imports

using se.vc.IVersionControl;

int def_svc_auto_detect = 1;

// Keys are paths, values are names
static AutoVCSystemTypes gVCSystemHash:[];
static _str gVCSPathsPending[];
static int gPathsPendingTimer = -1;

enum VCSystems {
   VCSYSTEM_SVN,
   VCSYSTEM_GIT
};

static _str gNameFromType:[] = {
   WATCHEDPATH_AUTO_VC_UNKOWN => "",
   WATCHEDPATH_AUTO_VC_SVN    => "Subversion",
   WATCHEDPATH_AUTO_VC_GIT    => "Git",
};

static bool gCheckedGit = false;
static bool gCheckedSVN = false;

static bool gHaveGit = true;
static bool gHaveSVN = true;

definit()
{
   gVCSystemHash = null;
   gVCSPathsPending = null;
   if ( arg(1)=='L' && gPathsPendingTimer>=0 ) {
      _kill_timer(gPathsPendingTimer);
   }
   gPathsPendingTimer = -1;
   filewatcherInitType(WATCHEDPATH_SVN_BOOLEAN);
   filewatcherInitType(WATCHEDPATH_GIT_BOOLEAN);
}

_str _getFilenameFromProjectsToolWindow()
{
   if (p_name!=PROJECT_TOOLBAR_NAME) return "";
   index := _TreeCurIndex();
   if ( index<0 ) return "";
   cap := _TreeGetCaption(index);
   parse cap with "\t" auto treePath;
   if (def_project_show_relative_paths) {
      path := _AbsoluteToWorkspace(treePath, _file_path(_workspace_filename));
      return path;
   }
   return treePath;
}

_str svc_get_vc_path(_str path="")
{
   if ( _no_child_windows() ) {
      return absolute(_ProjectGet_WorkingDir(_ProjectHandle()));
   }
   if (p_name==PROJECT_TOOLBAR_NAME) {
      filename := _getFilenameFromProjectsToolWindow();
      path = _file_path(filename);
      _maybe_strip(path,FILESEP);
      return path; 
   }
   if ( path=="" ) {
      path = _file_path(_mdi.p_child.p_buf_name);
   } else {
      path = _file_path(path);
   }
   path = _file_case(path);
   _maybe_strip(path,FILESEP);
   path = _file_case(path);
   return path;
}

/**
 * @param path Path to get system for
 * @param noAutoType Do not use any auto type information, only 
 *                   project, then workspace, then
 *                   _GetVCSystemName() (def_vc_system)
 * 
 * @return _str Name of the version control system
 */
_str svc_get_vc_system(_str path="",bool noAutoType=false)
{
   projectVCS := _ProjectGet_VCSProject(_ProjectHandle());
   if ( substr(projectVCS,1,4)=="SCC:" ) {
      parse projectVCS with "SCC:" auto systemName ":" auto sccProjectInfo;
      return "SCC:":+systemName;
   }
   _maybe_strip(projectVCS,':');
   if ( projectVCS!="" ) return projectVCS;

   if ( gWorkspaceHandle>=0 ) {
      workspaceVCS := _WorkspaceGet_VCSProject(gWorkspaceHandle);
      _maybe_strip(workspaceVCS,':');
      if ( workspaceVCS!="" ) return workspaceVCS;
   }

   defaultSystemName := _GetVCSystemName();

   if (defaultSystemName!="") {
      return defaultSystemName;
   }

   if (!def_svc_auto_detect ) {
      return defaultSystemName;
   }
   path = svc_get_vc_path(path);
   systemType := getSystemFromTable(path);
   if (systemType == null) {
      getVCSystemForPath(path,true);
   }
   if (systemType!=null && gNameFromType._indexin(systemType)) {
      return gNameFromType:[(_str)systemType];
   }
   return _GetVCSystemName();
}

#if 0 //8:52pm 2/28/2017
_command void test_svc_get_vc_system() name_info(',')
{
   if ( !_haveVersionControl() ) return;
   vc_system := svc_get_vc_system();
   say('test_svc_get_vc_system vc_system='vc_system);
}

_command void test_filewatcher_svn() name_info(',')
{
   if ( !_haveVersionControl() ) return;
   filewatcherInitType(WATCHEDPATH_SVN_BOOLEAN);
   path := getcwd();
   status := filewatcherAddPath(path,WATCHEDPATH_SVN_BOOLEAN,false,"",1);
   say('test_filewatcher_svn filewatcherAddPath status='status' path='path);
}

_command void test_filewatcher_get_bool_status() name_info(',')
{
   if ( !_haveVersionControl() ) return;
   path := svc_get_vc_path(p_buf_name);
   say('test_filewatcher_get_bool_status path='path);
   status := _GetFileInfo(path,auto fileinfo);
   if ( !status ) {
      say('test_filewatcher_get_bool_status fileinfo.passedBooleanTest='fileinfo.autoVCSystem' path='path);
   } else {
      say('test_filewatcher_get_bool_status status='status);
   }
}

_command void test_svc_dump_table() name_info(',')
{
   _dump_var(gVCSystemHash);
}
#endif

static void setUpToLocalRoot(_str casedPath,WATCHED_FILE_INFO &fileInfo)
{
   //WATCHEDPATH_AUTO_VC_SVN    =  1,
   //WATCHEDPATH_AUTO_VC_GIT    =  2,
   IVersionControl *pInterface = null;
   switch ( fileInfo.autoVCSystem ) {
   case WATCHEDPATH_AUTO_VC_SVN:
      {
         pInterface = svcGetInterface("subversion");
         break;
      }
   case WATCHEDPATH_AUTO_VC_GIT:
      {
         pInterface = svcGetInterface("git");
         break;
      }
   }
   if (pInterface==null) return;

   localRoot := pInterface->localRootPath(casedPath);
   _maybe_strip_filesep(localRoot);

   curCasedPath := casedPath;
   _maybe_strip_filesep(curCasedPath);

   if ( localRoot!="" ) {
      for (i:=0;i<10;++i) {
         if ( _file_eq(localRoot, curCasedPath) ) {
            break;
         }
         _maybe_strip_filesep(curCasedPath);
         curCasedPath = _strip_filename(curCasedPath, 'N');
         _maybe_strip_filesep(curCasedPath);
         setSystemInTable(curCasedPath, fileInfo.autoVCSystem);
      }
   }
}

static void pathsPendingCallback()
{
   static int inCallback;
   if ( inCallback==1 ) {
      return;
   }

   inCallback = 1;
   INTARRAY itemsToDelete;
   len := gVCSPathsPending._length();
   for (i := 0; i<len ; ++i) {
      parse gVCSPathsPending[i] with auto path (PATHSEP) auto SVCSystemBoolean;
      status := _GetFileInfo(path,auto fileInfo);
      if ( !status ) {
         ARRAY_APPEND(itemsToDelete,i);
         casedPath := _file_case(fileInfo.filename);
         if ( getSystemFromTable(casedPath)==null ) {
            if (fileInfo.autoVCSystem==WATCHEDPATH_AUTO_VC_GIT) {
               setUpToLocalRoot(casedPath,fileInfo);
            } else {
               setSystemInTable(casedPath,fileInfo.autoVCSystem);
            }
         } else if ( (getSystemFromTable(casedPath)==WATCHEDPATH_AUTO_VC_UNKOWN || fileInfo.autoVCSystem!=WATCHEDPATH_AUTO_VC_UNKOWN) 
              && fileInfo.autoVCSystem != null ) {
            if (fileInfo.autoVCSystem==WATCHEDPATH_AUTO_VC_GIT) {
               setUpToLocalRoot(casedPath,fileInfo);
            }else {
               setSystemInTable(casedPath,fileInfo.autoVCSystem);
            }
         }
      }
   }
   len = itemsToDelete._length();
   for (i = len-1; i>=0 ; --i) {
      gVCSPathsPending._deleteel(itemsToDelete[i]);
   }

   if ( gVCSPathsPending._length()==0 ) {
      _kill_timer(gPathsPendingTimer);
      gPathsPendingTimer = -1;
   }

   inCallback = 0;
}

static bool pathIsPending(_str path)
{
   gitPathMatch := path:+PATHSEP:+WATCHEDPATH_GIT_BOOLEAN;
   svnPathMatch := path:+PATHSEP:+WATCHEDPATH_SVN_BOOLEAN;
   len := gVCSPathsPending._length();
   for (i := 0; i<len ; ++i) {
      if ( _file_eq(gitPathMatch,gVCSPathsPending[i])
           || _file_eq(svnPathMatch,gVCSPathsPending[i]) ) {
         return true;
      }
   }
   return false;
}

static void setHaveVariable(_str exePath,bool &haveSystem)
{
   if ( _isRelative(exePath) ) {
      exePath = absolute(exePath); ;
      exists := file_exists(exePath);
      if ( exists ) {
         haveSystem = true;
         return;
      } else {
         haveSystem = false;
         return;
      }
   } else if ( !pos(FILESEP,exePath) ) {
      exePath = path_search(exePath);
      if ( exePath=="" ) {
         haveSystem = false;
         return;
      }
   }
   exists := file_exists(exePath);
   if ( exists ) {
      haveSystem = true;
   }
}

static void setSystemInTable(_str path,AutoVCSystemTypes value)
{
   gVCSystemHash:[_file_case(path)] = value;
}

static _str getSystemFromTable(_str path)
{
   casedPath := _file_case(path);

   if ( !gVCSystemHash._indexin(casedPath) ) return null;
   return gVCSystemHash:[_file_case(casedPath)];
}

static void getVCSystemForPath(_str pathOrFile,bool isVCPath=false)
{
   if ( !_haveVersionControl() ) return;
   path := pathOrFile;
   if ( !isVCPath ) {
      path = svc_get_vc_path(pathOrFile);
   }

   // If it is int he hashtable, or it is pending, just return
   if ( getSystemFromTable(path)!=null ) {
      return;
   }
   if ( pathIsPending(path) ) {
      return;
   }

   status := _GetFileInfo(path, auto fileInfo);
   if ( !status ) {
      setSystemInTable(path,fileInfo.autoVCSystem);
      return;
   }

   if ( !gCheckedGit ) {
      gitPath := _GitGetExePath();
      setHaveVariable(gitPath,gHaveGit);
      gCheckedGit = true;
   }

   if ( !gCheckedSVN ) {
      SVNPath := _SVNGetExePath();
      gHaveSVN = false;
      setHaveVariable(SVNPath,gHaveSVN);
      gCheckedSVN = true;
   }

   if ( !gHaveGit && !gHaveSVN ) {
      return;
   }

   addedPath := false;

   // Have to figure out who wins
   if ( gHaveGit ) {
      ARRAY_APPEND(gVCSPathsPending,path:+PATHSEP:+WATCHEDPATH_GIT_BOOLEAN);
      status = filewatcherAddPath(path,WATCHEDPATH_GIT_BOOLEAN,false,"",1);
      addedPath = true;
   }
   if ( gHaveSVN ) {
      ARRAY_APPEND(gVCSPathsPending,path:+PATHSEP:+WATCHEDPATH_SVN_BOOLEAN);
      status = filewatcherAddPath(path,WATCHEDPATH_SVN_BOOLEAN,false,"",1);
      addedPath = true;
   }

   if ( gPathsPendingTimer<0 && addedPath ) {
      gPathsPendingTimer = _set_timer(500,pathsPendingCallback);
   }
}

void _switchbuf_auto_detect_vc_system(_str oldbuffname, _str flag)
{
   getVCSystemForPath(_mdi.p_child.p_buf_name);
}
