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
#include "markers.sh"
#require "sc/lang/Timer.e"
#import "sc/editor/TempEditor.e"
#require "IWWTSIdentifier.e"
#import "WWTSDisplay.e"
#import "WWTSModel.e"
#import "varedit.e"
#import "diffedit.e"
#import "stdprocs.e"
#import "backtag.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party version control 
 * systems. 
 */
namespace se.vc;

struct WWTS_DISPLAY_QUEUE_ITEM {
   _str filename;
   _str schemeName;
   WWTSDisplay *pDisplay;
};

class WWTSDisplayQueue : sc.lang.Timer {
   private WWTS_DISPLAY_QUEUE_ITEM m_queuedItems[];
   private bool m_inRun = false;
   private typeless m_pfnDisplayCallback = 0;
   WWTSDisplayQueue(typeless *pfnDisplayCallback=null) {
      m_queuedItems = null;
      // This timer never stops. Slow it down a little bit
      Timer(5000);
      m_pfnDisplayCallback = pfnDisplayCallback;
   }
   ~WWTSDisplayQueue() {
   }

   private void callDisplayCallback() {
      if ( m_pfnDisplayCallback ) {
         STRARRAY fileList = null;
         foreach ( auto curItem in m_queuedItems ) {
            fileList[fileList._length()] = curItem.filename;
         }
         (*m_pfnDisplayCallback)(fileList);
      }
   }

   public void setDisplayCallback(typeless *pfnDisplayCallback) {
      m_pfnDisplayCallback = pfnDisplayCallback;
   }

   public void addItem(_str filename,_str schemeName,WWTSDisplay *pDisplay) {
      len := m_queuedItems._length();
      for ( i:=0;i<len;++i ) {
         // Only one queued item for any file
         if ( _file_eq(m_queuedItems[i].filename,filename) ) {
            m_queuedItems._deleteel(i);
         }
      }
      WWTS_DISPLAY_QUEUE_ITEM curItem;
      curItem.filename   = filename;
      curItem.schemeName = schemeName;
      curItem.pDisplay   = pDisplay;

      len = m_queuedItems._length();
      m_queuedItems[len] = curItem;

      callDisplayCallback();
   }
   public int run() {
      if ( m_inRun ) return 0;
      m_inRun = true;
      len := m_queuedItems._length();
      //say('run m_queuedItems._length()='m_queuedItems._length());
      for ( i:=0;i<len;++i ) {
         curItem := m_queuedItems[i];
         status := curItem.pDisplay->displayAllLineInfo(curItem.filename,curItem.schemeName);
         //say('WWTSDisplayQueue.run i='i' len='len' status='status' curItem.filename='curItem.filename' curItem.schemeName='curItem.schemeName);
         // Only display one item per timer for a lesser performance hit
         if ( !status ) {
            // if status is 1, that's not a 'real' error
            m_queuedItems._deleteel(i);
            break;
         }
      }
      callDisplayCallback();
      m_inRun = false;
      // This timer doesn't stop
      return 0;
   }
};
