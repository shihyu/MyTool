////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#import "WWTSLine.e"
#import "WWTSFile.e"
#import "IWWTSInterface.e"
#import "WWTSModel.e"
#import "WWTSDisplay.e"
#require "sc/lang/Timer.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSDataProcessor : sc.lang.Timer {
   private IWWTSInterface m_wwts;
   private _str m_filename; 
   private _str m_schemeName;
   private WWTSDisplay *m_pDisplay;
   private boolean m_isRunning;
   WWTSDataProcessor(IWWTSInterface wwts=null,WWTSDisplay *pDisplay=0,_str filename="",_str schemeName="") {
      m_wwts       = wwts;
      m_filename   = filename;
      m_schemeName = schemeName;
      m_isRunning  = false;
   }
   ~WWTSDataProcessor() {
   }
   public _str getFilename() {
      return m_filename;
   }
   public int run() {
      stopTimer := 0;
      do {
         status := m_wwts.processData(m_filename);
         //say('WWTSDataProcessor.run: processData status='status);
         if ( status<0 ) {                        
            _message_box("run: PROBLEM");
            stopTimer = 1;
            break;
         }else if (status==1) {
            say('WWTSDataProcessor.run: 'm_filename' thread still processing');
            stopTimer = 0;
            break;
         }else if (!status) {
            say('WWTSDataProcessor.run: processing complete');
            stopTimer = 1;
            WWTSFile fileInfo;
            status = m_wwts.getData(m_filename,fileInfo);
            WWTSModel.setFile(m_filename,fileInfo);
         }
         
      } while (false);
      //say('WWTSDataProcessor.run stopTimer='stopTimer);
      if ( stopTimer ) m_isRunning = false;
      return stopTimer;
   }
   public boolean isRunning() {
      return m_isRunning;
   }
}
