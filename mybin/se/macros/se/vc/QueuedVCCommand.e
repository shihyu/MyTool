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
#import "main.e"
#import "toast.e"
#require "VCRepositoryCache.e"
//#import "subversion.e"
#endregion Imports

using se.vc.vccache.VCRepositoryCache;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc.vccache;

class QueuedVCCommand {
   private VCRepositoryCache m_cache;
   private _str m_command;
   private _str m_filename;
   private _str m_repository;
   private int  m_processID;  // Used when piggy-backing another item
   QueuedVCCommand m_childList[];
   QueuedVCCommand(VCRepositoryCache cache=null,_str command="",_str filename="",_str repository="",int processID=-1) {
      m_cache = cache;
      m_command = command;
      m_filename = filename;
      m_repository = repository;
      m_processID = processID;
   }

   ~QueuedVCCommand() {
   }

   public _str getCommand() {
      return m_command;
   }

   public void addChild(_str command,_str filename) {
      len := m_childList._length();

      QueuedVCCommand temp(null,command,filename);

      m_childList[len] = temp;
   }

   public int run() {
      if ( def_vccache_debug ) {
         say('run QueuedVCCommand.m_filename='m_filename);
         say('run m_processID='m_processID);
      }
      if ( !m_cache.vcProcessRunning() ) {
         // show an alert
         _str msg = 'Sync for SVN repository 'm_cache.get_RepositoryUrl()' is done.';
         _DeactivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_SVN_CACHE_SYNC, msg);
         // parse the result
         int status = SVN_CACHE_SUCCESS;
         msg = '';
         m_cache.parseStatusFile(status, msg);
         if (status != SVN_CACHE_SUCCESS) {
            _message_box(msg, "SlickEdit SVN History");
            // don't show the new style svn-history anymore
            def_svn_use_new_history = 0;
            _config_modify_flags(CFGMODIFY_DEFDATA);
            // HACK HACK HACK, switch the command to 'svn_history'
            m_command = 'svc_history';
         }
         // run the proper command
         commandIndex := find_index(m_command,COMMAND_TYPE);
         numChildren := m_childList._length();
         if ( def_vccache_debug ) {
            say('run 10 commandIndex='commandIndex' m_command='m_command);
         }
         if ( commandIndex ) {
            dialogStr := "dialog";
            numDialogs := 1+numChildren;
            if ( numDialogs>1 ) dialogStr = "dialogs";
            // Remove this message box, we feel maybe there is too many modal distractions
            #if 0
            _message_box(nls("A version control cache has finished building and %s history %s will now be launched.",numDialogs,dialogStr));
            #endif
            // These command must support an argument 
            call_index(m_filename,SVC_HISTORY_WITH_BRANCHES,null,false,true,commandIndex);
         }
         for ( i:=0;i<numChildren;++i ) {
            commandIndex = find_index(m_childList[i].m_command,COMMAND_TYPE);
            if ( def_vccache_debug ) {
               say('run 20 commandIndex='commandIndex' m_childList[i].m_command='m_childList[i].m_command);
            }
            if ( commandIndex ) {
               // These command must support an argument 
               call_index(m_childList[i].m_filename,SVC_HISTORY_WITH_BRANCHES,null,false,true,commandIndex);
            }
         }
         return 1;
      }
      return 0;
   }

   public _str getRepository() {
      return m_repository;
   }

   public int getCachePID() {
      if ( m_cache==null ) {
         return -1;
      }
      return m_cache.getProcessPID();
   }

   public _str getFilename() {
      return m_filename;
   }

   public STRARRAY getChildFilenames() {
      STRARRAY temp;
      len := m_childList._length();
      for ( i:=0;i<len;++i ) {
         temp[i] = m_childList[i].m_filename;
      }
      return temp;
   }

   public boolean isRunning() {
      if ( m_processID!=-1 ) {
         return _IsProcessRunning(m_processID)!=0;
      }else{
         return m_cache.vcProcessRunning();
      }
   }
}
