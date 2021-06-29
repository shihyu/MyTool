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
#import "stdprocs.e"
#require "QueuedVCCommand.e"
#require "sc/lang/Timer.e"
#endregion Imports

using se.vc.vccache.VCRepositoryCache;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc.vccache;

class QueuedVCCommandManager : sc.lang.Timer {
   QueuedVCCommand m_list[];
   bool m_inRun = false;
   QueuedVCCommandManager() {
      Timer(1000);
      m_list = null;
   }
   public void add(QueuedVCCommand command) {
      listLen := m_list._length();
      m_list[listLen] = command;
   }

   public bool cacheUpdatePending(_str repositoryRoot,QueuedVCCommand *(&pcommand)) {
      pcommand = null;
      len := m_list._length();
      if ( def_vccache_debug ) {
         if ( !len ) say('cacheUpdatePending: no files queued');
         say('cacheUpdatePending 'len' items queued');
      }
      for ( i:=0;i<m_list._length();++i ) {
         if ( m_list[i]==null || !m_list[i].isRunning() ) {
            m_list._deleteel(i);
            --i;
            continue;
         }

         if ( _file_eq(m_list[i].getRepository(),repositoryRoot) ) {
            pcommand = &(m_list[i]);
            return true;
         }
      }
      return false;
   }
   public void clear() {
      m_list = null;
   }

   public int run() {
      if ( m_inRun ) {
         return 0;
      }
      m_inRun = true;
      len := m_list._length();
      for ( i:=0;i<len;++i ) {
         if ( m_list[i].run() ) {
            // QueuedVCCommand.run returns non-zero we have to remove this item
            m_list._deleteel(i);
            --i;
            --len;
         }
      }
      m_inRun = false;
      return 0;
   }
}
