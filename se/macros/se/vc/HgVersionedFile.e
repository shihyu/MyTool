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
#require "Hg.e"
#import "svc.e"
#import "saveload.e"
#import "stdprocs.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class HgVersionedFile: IVersionedFile {
   private _str m_localFilename = "";
   private STRHASHTAB m_versionInfo;
   private SVCHistoryInfo m_historyInfo:[];

   HgVersionedFile(_str localFilename="",_str branchName="") {
      m_localFilename = localFilename;
   }

   _str localFilename(_str verison="") {
      return m_localFilename;
   }

   int numVersions() {
      IVersionControl *pInterface = svcGetInterface("mercurial");
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

   private int loadHistory() {
      IVersionControl *pInterface = svcGetInterface("mercurial");
      status := pInterface->getHistoryInformation(m_localFilename,auto historyInfo);

      len := historyInfo._length();
      for (i:=0;i<len;++i) {
         m_historyInfo:[historyInfo[i].revision] = historyInfo[i];
      }
      return status;
   }

   int enumerateVersions(STRARRAY &versionList) {
      status := loadHistory();
      foreach (auto curRevision => auto curInfo in m_historyInfo) {
         if ( curRevision!="root" ) {
            ARRAY_APPEND(versionList,curRevision);
         }
      }
      versionList._sort('N');
      return status;
   }

   void getVersionInfo(_str version,_str &info) {
      info = m_versionInfo:[version];
      if ( info==null ) {
         info = "";
      }
   }

   int getHistoryInfo(_str version,SVCHistoryInfo &info) {
      status := loadHistory();
      info = m_historyInfo:[version];
      return status;
   }

   _str typeCaption() {
      return "Mercurial";
   }

   int getFile(_str version,int &fileWID) {
      IVersionControl *pInterface = svcGetInterface("mercurial");
      status := pInterface->getFile(m_localFilename,version,fileWID);
      return status;
   }
   int getLocalFile(int &fileWID) {
      IVersionControl *pInterface = svcGetInterface("mercurial");
      _str encoding_option=_load_option_encoding(m_localFilename);
      status := _open_temp_view(m_localFilename,fileWID,auto origWID,'+d 'def_load_options' 'encoding_option" +L");
      p_window_id = origWID;

      // Use +L to be sure we can delete the file while it is open
      if ( status ) return status;
      langId := _Filename2LangId(m_localFilename);
      return status;
   }
   void setComment(_str version, _str comment) {
   }
   int repairArchive() {
      return 0;
   }
   bool isGoodArchive() {
      return false;
   }
   VFCommandsAvailable commandsAvailable() {
      return VFC_NONE;
   }
};

