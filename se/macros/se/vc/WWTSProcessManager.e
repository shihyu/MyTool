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
#import "varedit.e"
#require "sc/lang/Timer.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSProcessManager : sc.lang.Timer {
   private int m_runMessage = 0;
   private static IWWTSInterface s_wwtsList:[];
   WWTSProcessManager() {
      // This timer never stops. Slow it down a little bit
      Timer(5000);
   }
   ~WWTSProcessManager() {
      s_wwtsList = null;
   }
   static public void addProcess(IWWTSInterface wwts,_str filename) {
      s_wwtsList:[filename] = wwts;
      s_wwtsList:[filename].retrieveData(filename);
   }
   public int run() {
      if ( !m_runMessage ) {
         //message('WWTSProcessManager started');
         ++m_runMessage;
      }
      foreach ( auto curFilename => auto curWwts in s_wwtsList ) {
         status := curWwts.processData(curFilename);
         if ( status == 1 ) {
            // Process is running
         }else{
            WWTSFile fileInfo;
            status = curWwts.getData(curFilename,fileInfo);
            WWTSModel.setFile(curFilename,fileInfo);

            // Remove this from the hash table
            s_wwtsList._deleteel(curFilename);

            // Return right away, only process one file at a time
            return 0;
         }
      }
      // This timer doesn't stop
      return 0;
   }
   public void getProcessList(STRARRAY &filenameList) {
      foreach ( auto curFilename => auto curWwts in s_wwtsList ) {
         filenameList[filenameList._length()] = curFilename;
      }
   }
}
