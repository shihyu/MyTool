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
#pragma option(metadata,"filewatch.e")

enum_flags WatchedPathTypes {
   WATCHEDPATH_NONE = 0x0,
   WATCHEDPATH_SVN = 0x1,
   WATCHEDPATH_FILESYSTEM = 0x2,
   WATCHEDPATH_PERFORCE = 0x4,
   WATCHEDPATH_GIT = 0x8,
   WATCHEDPATH_SVN_BOOLEAN= 0x10,
   WATCHEDPATH_GIT_BOOLEAN= 0x20,
};

struct WATCHED_PATH_REQUEST_INFO {
   _str path;
   WatchedPathTypes changeType;
   typeless *pfnCallback;
   bool recursive;
};

enum AutoVCSystemTypes {
   WATCHEDPATH_AUTO_VC_UNKOWN = -1,
   WATCHEDPATH_AUTO_VC_SVN    =  1,
   WATCHEDPATH_AUTO_VC_GIT    =  2,
};

struct WATCHED_FILE_INFO {
   _str filename;
   _str watchedPath;
   _str VCServerStatus;
   _str VCLocalStatus;
   _str localDate;
   AutoVCSystemTypes autoVCSystem;
   WatchedPathTypes changeType;
};

int def_perforce_show_file_status = 0;
int def_perforce_update_interval = 600;     // Frequency to get file status data from

int def_git_show_file_status = 0;
int def_git_update_interval = 600;     // Frequency to get file status data from

int def_add_opened_files_to_recent = 0;

extern void _GetUpdatedFileInfoList(WATCHED_FILE_INFO (&fileList)[]);
extern int _SetFileInfo(_str filename,WATCHED_FILE_INFO &fileinfo);
extern int _GetFileInfo(_str filename,WATCHED_FILE_INFO &fileinfo);
extern int filewatcherAddPath(_str,WatchedPathTypes,bool,...);
extern int filewatcherRemovePath(_str,WatchedPathTypes);
extern int filewatcherRemoveType(WatchedPathTypes);
extern int filewatcherInitType(WatchedPathTypes);
extern void filewatcherStop(WatchedPathTypes);
extern void _RecentFilesAdd(_str filename);
extern void _RecentFilesProcessPending();
