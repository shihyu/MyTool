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
#import "SVN.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class SVNVersionedFile: IVersionedFile {
   private _str m_localFilename = "";
   private STRHASHTAB m_versionInfo;
   private SVCHistoryInfo m_historyInfo:[];

   SVNVersionedFile(_str localFilename="") {
      m_localFilename = localFilename;
   }

   _str localFilename() {
      return m_localFilename;
   }

   int numVersions() {
      IVersionControl *pInterface = svcGetInterface("subversion");
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

   private void getHistoryInformation(_str localFilename) {
      if ( m_historyInfo==null ) {
         mou_hour_glass(1);
         IVersionControl *pInterface = svcGetInterface("subversion");
         SVCHistoryInfo historyInfo[];
         pInterface->getHistoryInformation(m_localFilename,historyInfo);

         len := historyInfo._length();
         for (i:=0;i<len;++i) {
            if ( historyInfo[i].revision!="rroot" ) {
               m_historyInfo:[substr(historyInfo[i].revision,2)] = historyInfo[i];
            }
         }
      }
      mou_hour_glass(0);
   }

   void enumerateVersions(STRARRAY &versionList) {
      getHistoryInformation(m_localFilename);
      foreach (auto curVersion => auto curInfo in m_historyInfo) {
         if ( !isinteger(curVersion) ) continue;
         ARRAY_APPEND(versionList,curVersion);
      }
      versionList._sort('N');
   }

   void getVersionInfo(_str version,_str &info) {
      info = m_versionInfo:[version];
      if ( info==null ) {
         info = "";
      }
   }

   void getHistoryInfo(_str version,SVCHistoryInfo &info) {
      getHistoryInformation(m_localFilename);
      info = m_historyInfo:[version];
   }

   _str typeCaption() {
      return "Subversion";
   }

   int getFile(_str version,int &fileWID) {
      IVersionControl *pInterface = svcGetInterface("subversion");
      status := pInterface->getFile(m_localFilename,version,fileWID);
      return status;
   }
};

