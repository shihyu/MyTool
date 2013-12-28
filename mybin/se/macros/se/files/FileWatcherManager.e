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
#include "subversion.sh"
#import "stdprocs.e"
#import "varedit.e"
#require "sc/lang/Timer.e"
#endregion

/**
 * The "se.files" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace se.files;

using sc.lang.Timer;

class FileWatcherManager : Timer {
   static WATCHED_PATH_REQUEST_INFO s_watchedPaths:[][];
   static int s_constantInterval=10000;
   static int s_threadFrequencyInterval = 0;
   static int s_threadTimeElapsed = 0;
   boolean m_inRun = false;

   FileWatcherManager() {
      if ( !isinteger(def_svn_update_interval) ) def_svn_update_interval=5*60*1000;

      s_threadFrequencyInterval = def_svn_update_interval*1000;
      s_threadTimeElapsed = 0;
      Timer( s_constantInterval );
   }

   void addWatchedPath(_str path,WatchedPathTypes type,boolean recursive,typeless *pfnCallback) {
      WATCHED_PATH_REQUEST_INFO (*pWatchedPaths):[][];
      WATCHED_PATH_REQUEST_INFO temp;
      temp.path = path;
      temp.changeType = type;
      temp.pfnCallback = pfnCallback;
      temp.recursive = recursive;
      casedPath := _file_case(path);
      if ( s_watchedPaths:[casedPath]==null ) {
         s_watchedPaths:[casedPath][0] = temp;
      }else{
         len := s_watchedPaths:[casedPath]._length();
         found := false;
         for ( i:=0;i<len;++i ) {
            // We already have this one
            if ( s_watchedPaths:[casedPath][i].changeType & type ) {
               //found = true;
               s_watchedPaths:[casedPath]._deleteel(i);
               break;
            }
         }
         s_watchedPaths:[casedPath][s_watchedPaths:[casedPath]._length()] = temp;
      }
      filewatcherAddPath(casedPath,type,recursive);
   }

   void removeWatchedPath(_str path,WatchedPathTypes type) {
      casedPath := _file_case(path);

      if ( s_watchedPaths:[casedPath]!=null ) {
         len := s_watchedPaths:[casedPath]._length();
         for ( i:=0;i<len;++i ) {
            if ( s_watchedPaths:[casedPath][i].changeType==type ) {
               filewatcherRemovePath(casedPath,type);
               --i;
            }
         }
      }
   }

   void setThreadInterval(int mSecInterval) {
      s_threadFrequencyInterval = mSecInterval;
   }

   void removeWatchedPathType(WatchedPathTypes type) {
      typeless pathIndex;

      for (pathIndex._makeempty();;) {
          s_watchedPaths._nextel(pathIndex);
          if (pathIndex._isempty()) break;
          len := s_watchedPaths:[pathIndex]._length();

          for ( i:=0;i<len;++i ) {
             if ( s_watchedPaths:[pathIndex][i].changeType==type ) {
                s_watchedPaths:[pathIndex]._deleteel(i);
                --i;
                --len;
             }
          }
          filewatcherRemoveType(type);
      }
   }

   void getWatchedPaths(WatchedPathTypes type,WATCHED_PATH_REQUEST_INFO (&watchedPaths)[]) {
      watchedPaths = null;

      foreach ( auto casedPath => auto curWatchedPathArray in s_watchedPaths ) {
         foreach ( auto curWatchedPath in curWatchedPathArray ) {
            if ( curWatchedPath.changeType==type ) {
               watchedPaths[watchedPaths._length()] = curWatchedPath;
            }
         }
      }
   }

   void clearWatchedPaths() {
      s_watchedPaths = null;
   }

   void refreshPaths(WatchedPathTypes type) {
//      say('refreshPaths refresh in');
      WATCHED_PATH_REQUEST_INFO watchedPaths[];
      getWatchedPaths(type,watchedPaths);
      len := watchedPaths._length();
//      say('refreshPaths num paths='len);
      for ( i:=0;i<len;++i ) {
//         say('refreshPaths filewatcherAddPath watchedPaths['i'].path='watchedPaths[i].path);
         filewatcherAddPath(watchedPaths[i].path,watchedPaths[i].changeType,watchedPaths[i].recursive);
      }
   }

   int run() {
      if ( m_inRun ) return 0;
      m_inRun = true; 
      s_threadTimeElapsed += s_constantInterval;

//      say('run s_threadTimeElapsed='s_threadTimeElapsed' s_threadFrequencyInterval='s_threadFrequencyInterval);
      if ( s_threadTimeElapsed >= s_threadFrequencyInterval ) {
         refreshPaths(WATCHEDPATH_SVN);
         refreshPaths(WATCHEDPATH_PERFORCE);
         s_threadTimeElapsed = 0;
      }

      WATCHED_FILE_INFO fileInfoList[];
      _GetUpdatedFileInfoList(fileInfoList);
      len := fileInfoList._length();
      typeless info;

      WATCHED_PATH_REQUEST_INFO (*pWatchedPaths):[][];

      for ( i:=0;i<len;++i ) {
         curWatchedFile := fileInfoList[i] ;

         casedCurWatchPath := _file_case(curWatchedFile.watchedPath);
         WATCHED_PATH_REQUEST_INFO curWatchedRequest[] = s_watchedPaths:[casedCurWatchPath];
         numCurWatchRequests := curWatchedRequest._length();
         for ( j:=0;j<numCurWatchRequests;++j ) {
            if ( curWatchedRequest[j].changeType & curWatchedFile.changeType ) {
               status := (*curWatchedRequest[j].pfnCallback)(curWatchedFile,info);
               if ( status ) {
                  removeWatchedPath(curWatchedRequest[j].path,curWatchedRequest[j].changeType);
               }
            }
         }
      }
      m_inRun = false; 
      return 0;
   }
}
