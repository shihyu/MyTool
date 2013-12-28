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
#include "slick.sh"
#require "IVersionedFile.e"
#import "svc.e"
#import "GitClass.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class GitVersionedFile: IVersionedFile {
   private _str m_localFilename = "";
   private STRHASHTAB m_versionInfo;
   private SVCHistoryInfo m_historyInfo:[];

   GitVersionedFile(_str localFilename="") {
      m_localFilename = localFilename;
   }

   _str localFilename() {
      return m_localFilename;
   }

   int numVersions() {
      IVersionControl *pInterface = svcGetInterface("git");
      numVersions := pInterface->getNumVersions(m_localFilename);
      return numVersions;
   }

   int getVersion(_str version,int &WID) {
      WID = 0;
      return 0;
   }

   void setFilename(_str localFilename) {
      m_localFilename = localFilename;
   }

   private void loadHistory() {
      IVersionControl *pInterface = svcGetInterface("git");
      pInterface->getHistoryInformation(m_localFilename,auto historyInfo);

      len := historyInfo._length();
      for (i:=0;i<len;++i) {
         m_historyInfo:[historyInfo[i].revision] = historyInfo[i];
      }
   }

   void enumerateVersions(STRARRAY &versionList) {
      IVersionControl *pInterface = svcGetInterface("git");
      pInterface->enumerateVersions(m_localFilename,versionList);
   }

   void getVersionInfo(_str version,_str &info) {
      info = m_versionInfo:[version];
      if ( info==null ) {
         info = "";
      }
   }

   void getHistoryInfo(_str version,SVCHistoryInfo &info) {
      loadHistory();
      info = m_historyInfo:[version];
   }

   _str typeCaption() {
      return "Git";
   }

   int getFile(_str version,int &fileWID) {
      IVersionControl *pInterface = svcGetInterface("git");
      status := pInterface->getFile(m_localFilename,version,fileWID);
      return status;
   }
};

