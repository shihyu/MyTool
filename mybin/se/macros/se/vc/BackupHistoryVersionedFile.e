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
#import "IVersionedFile.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class BackupHistoryVersionedFile: IVersionedFile {
   private _str m_localFilename = "";
   private STRHASHTAB m_versionInfo;
   SVCHistoryInfo m_historyInfo:[];

   BackupHistoryVersionedFile(_str localFilename="") {
      m_localFilename = localFilename;
   }

   _str localFilename() {
      return m_localFilename;
   }

   int numVersions() {
      numVersions := DSGetNumVersions(m_localFilename);
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
      if ( m_versionInfo==null ) {
         DSListVersions(m_localFilename,auto versionList=null);

         len := versionList._length();
         for ( i:=0;i<len;++i ) {
            parse versionList[i] with auto curVersion auto date auto time auto comment;
            SVCHistoryInfo temp;

            temp.revision ="";
            temp.author = "";
            temp.date = "";
            temp.comment = "";
            temp.affectedFilesDetails = "";

            temp.date = date' 'time;
            temp.revision = curVersion;
            temp.comment = comment;
            m_historyInfo:[curVersion] = temp;
         }
      }
   }

   void enumerateVersions(STRARRAY &versionList) {
      loadHistory();
      foreach (auto curVersion=>auto curInfo in m_historyInfo) {
         ARRAY_APPEND(versionList,curVersion);
      }
      versionList._sort('N');
   }

   void getVersionInfo(_str version,_str &info) {
   }

   void getHistoryInfo(_str version,SVCHistoryInfo &info) {
      loadHistory();
      info = m_historyInfo:[version];
   }

   _str typeCaption() {
      return "Backup History";
   }

   int getFile(_str version,int &fileWID) {
      fileWID = DSExtractVersion(m_localFilename,(int)version,auto status);
      return status;
   }
};
