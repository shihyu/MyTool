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
#include "xml.sh"
#import "bhrepobrowser.e"
#import "saveload.e"
#import "stdprocs.e"
#require "IVersionedFile.e"
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
   private bool m_loaded = false;
   SVCHistoryInfo m_historyInfo:[];

   BackupHistoryVersionedFile(_str localFilename="") {
      DSUpgradeArchive(localFilename);
      m_localFilename = localFilename;
   }

   _str localFilename(_str version="") {
      return m_localFilename;
   }

   int numVersions() {
      // Use absolute to resolve symlinks.  We don't want to resolve them
      // ahead of time to keep the display name in tact.
      if (!_haveBackupHistory()) return 0;
      numVersions := DSGetNumVersions(absolute(m_localFilename,"",true));
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
      if (!_haveBackupHistory()) {
         return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
      }
      status := 0;
      if ( m_versionInfo==null ) {
         // Use absolute to resolve symlinks.  We don't want to resolve them
         // ahead of time to keep the display name in tact.
         status = DSListVersions(absolute(m_localFilename,"",true),auto versionList=null);

         len := versionList._length();
         for ( i:=0;i<len;++i ) {
            parse versionList[i] with auto curVersion auto date auto time auto comment;
            SVCHistoryInfo temp;

            temp.revision ="";
            temp.author = "";
            temp.date = "";
            temp.comment = comment;
            temp.affectedFilesDetails = "";

            temp.date = date' 'time;
            temp.revision = curVersion;
            temp.comment = comment;
            m_historyInfo:[curVersion] = temp;
         }
      }
      return status;
   }

   int enumerateVersions(STRARRAY &versionList) {
      status := loadHistory();
      foreach (auto curVersion=>auto curInfo in m_historyInfo) {
         ARRAY_APPEND(versionList,curVersion);
      }
      if ( versionList._length()>1 ) {
         versionList._sort('N');
      }
      return status;
   }

   void getVersionInfo(_str version,_str &info) {
   }

   int getHistoryInfo(_str version,SVCHistoryInfo &info) {
      status := 0;
      if ( !m_loaded ) {
         status = loadHistory();
         m_loaded = true;
      }
      info = m_historyInfo:[version];
      return status;
   }

   _str typeCaption() {
      return "Backup History";
   }

   int getFile(_str version,int &fileWID) {
      if (!_haveBackupHistory()) {
         return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
      }
      // Use absolute to resolve symlinks.  We don't want to resolve them
      // ahead of time to keep the display name in tact.
      fileWID = DSExtractVersion(absolute(m_localFilename,"",true),(int)version,auto status);
      return status;
   }
   int getLocalFile(int &fileWID) {
      _str encoding_option=_load_option_encoding(m_localFilename);
      status := _open_temp_view(m_localFilename,fileWID,auto origWID,'+d 'def_load_options' 'encoding_option" +L");
      p_window_id = origWID;

      // Use +L to be sure we can delete the file while it is open
      if ( status ) return status;
      langId := _Filename2LangId(m_localFilename);
      return status;
   }
   void setComment(_str version, _str comment) {
      // Use absolute to resolve symlinks.  We don't want to resolve them
      // ahead of time to keep the display name in tact.
      if (!_haveBackupHistory()) return;
      DSSetVersionComment(absolute(m_localFilename,"",true), (int)version, comment);

      if ( m_historyInfo:[version]!=null ) {
         m_historyInfo:[version].comment = comment;
      }
   }
   VFCommandsAvailable commandsAvailable() {
      return VFC_SETCOMMENT|VFC_ISGOODARCHIVE|VFC_REPAIRARCHIVE;
   }
   bool isGoodArchive() {
      // Use absolute to resolve symlinks.  We don't want to resolve them
      // ahead of time to keep the display name in tact.
      if (!_haveBackupHistory()) return false;
      archiveFilename := DSGetArchiveFilename(absolute(m_localFilename,"",true));
      if ( archiveFilename!="" ) {
         xmlhandle := _xmlcfg_open(archiveFilename,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
         if (!status) {
            _xmlcfg_close(xmlhandle);
            return true;
         }
      }
      return false;
   }
   int repairArchive() {
      if (!_haveBackupHistory()) {
         return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
      }
      // Use absolute to resolve symlinks.  We don't want to resolve them
      // ahead of time to keep the display name in tact.
      archiveFilename := DSGetArchiveFilename(absolute(m_localFilename,"",true));
      status := 0;
      if ( archiveFilename!="" ) {
         status = _repairBHFile(archiveFilename);
      }
      return status;
   }
};
