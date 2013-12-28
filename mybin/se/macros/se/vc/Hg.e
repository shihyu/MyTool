///////////////////////////////////////////////////////////////////////////////////
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
#include "mercurial.sh"

#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#import "main.e"
#import "HgBuildFile.e"
#import "projconv.e"
#import "saveload.e"
#import "setupext.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "svchistory.e"
#import "toast.e"
#import "vc.e"
#import "se/datetime/DateTime.e"
#import "se/vc/VCBranch.e"
#import "se/vc/VCLabel.e"
#require "se/vc/VCRepositoryCache.e"
#import "se/vc/VCCacheManager.e"
#import "se/vc/VCRevision.e"
#import "se/vc/VCBaseRevisionItem.e"
#import "se/vc/QueuedVCCommand.e"
#import "se/vc/QueuedVCCommandManager.e"
#import "wkspace.e"
#require "IVersionControl.e"
#require "sc/lang/String.e"
#endregion Imports

using sc.lang.String;
using se.datetime.DateTime;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class Hg : IVersionControl {
   private boolean m_debug = false;
   private _str m_captionTable[];
   private _str m_version = "";
   private int m_didDeferredInit = 0;

   Hg() {
      m_captionTable[SVC_COMMAND_COMMIT]  = "&Commit";
      m_captionTable[SVC_COMMAND_EDIT]    = "&Lock";
      m_captionTable[SVC_COMMAND_DIFF]    = "&Diff";
      m_captionTable[SVC_COMMAND_HISTORY] = "&History";
      m_captionTable[SVC_COMMAND_MERGE]   = "&Merge";
      m_captionTable[SVC_COMMAND_REVERT]  = "&Revert";
      m_captionTable[SVC_COMMAND_UPDATE]  = "&Update";
      m_captionTable[SVC_COMMAND_ADD]     = "&Add";
      m_captionTable[SVC_COMMAND_REMOVE]  = "Remove";
      m_captionTable[SVC_COMMAND_CHECKOUT]  = "Clone";
      m_captionTable[SVC_COMMAND_BROWSE_REPOSITORY]  = "Browse repository";
      m_captionTable[SVC_COMMAND_PUSH_TO_REPOSITORY]  = "Push to repository";
      m_captionTable[SVC_COMMAND_PULL_FROM_REPOSITORY]  = "Pull from repository";
      m_captionTable[SVC_COMMAND_HISTORY_DIFF]  = "History diff";
   }

   ~Hg() {
   }

   /** 
    * Perform operations here that do anything we can't do in 
    * constructor.  This object could be contructed on a menu drop 
    * down. So we don't want to do a path search or run Perforce. 
    */
   private void deferedInit() {
      if ( m_didDeferredInit ) return;
      m_didDeferredInit = 1;
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return ;
      }
   }


   private void getRemoteFilenameFromDiffScript(int scriptWID,_str &remoteFilename) {
      origWID := p_window_id;
      p_window_id = scriptWID;
      top();
      get_line(auto line);
      parse line with auto wordDiff auto wordDashR auto hash remoteFilename;
      p_window_id = origWID;
   }

   /**
    * This could be part of the interface, but instead we're 
    * leaving it up to each system. This will allow us to support a 
    * system that has multiple executables for different commands. 
    * 
    * @param exeStr exe name filled in here.
    * 
    * @return int 0 if successful
    */
   private int getExeStr(_str &exeStr) {
      exeStr = "";
      deferedInit();
      if ( def_hg_info.hg_exe_name=="" || 
           !file_exists(def_hg_info.hg_exe_name) ) {
         _str exeName = "";
#if __UNIX__
         exeName='hg';
#else
         exeName="hg.exe";
#endif
         def_hg_info.hg_exe_name=path_search(exeName);
         if ( def_hg_info.hg_exe_name=="" || 
              !file_exists(def_hg_info.hg_exe_name) ) {
            return SVC_COULD_NOT_FIND_VC_EXE;
         }
      }
      exeStr = def_hg_info.hg_exe_name;
      return 0;
   }

   int diffLocalFile(_str localFilename,_str version="",int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      localFilename = strip(localFilename,'B','"');
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }
      matchInfo := buf_match(localFilename,1,'EV');
      localFileExists := matchInfo!='';
      if ( localFileExists ) {
         for (;;) { 
            parse matchInfo with auto bufID auto modifyFlags auto bufFlags auto bufName;

            if ( (int)modifyFlags&0x1 ) {          
               result := _message_box(nls("To diff this file, the buffer must be saved.\n\nSave now?"),"",MB_YESNO);
               if ( result==IDNO ) {
                  return COMMAND_CANCELLED_RC;
               } else {
                  list_modified();  
                  matchInfo = buf_match(localFilename,1,'EV');
                  continue;
               }
            }
            break;
         }
      }

      versionSpec := "";
      if ( version!="" ) {
         // Version string already has 'r'
         if ( first_char(version)=='r' ) {
            versionSpec:+=' -'version;
         } else {
            versionSpec:+=' -r'version;
         }
      }
      headOption := "";
      if ( versionSpec=="" ) {
//         headOption = "-r HEAD ";
      }
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive diff "headOption:+maybe_quote_filename(localFilename)' 'versionSpec;
//      status = hgRunCommand(cmdLine,auto scriptWID=0,auto stdErrData);
//      maybeOutputWIDToLog(scriptWID,"diffLocalFile stdout");
//      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
//      if ( status || (length(stdErrData)>1 && scriptWID.p_Noflines==0) ) {
//         status = SVC_COULD_NOT_COMPARE_FILE;
//         _message_box(get_message(status,localFilename,stdErrData));
//         SVCWriteToOutputWindow(stdErrData.get());
//         return status;
//      }
//      HgBuildFile bf;
//      originalFileWID := bf.buildOriginalFile(localFilename,scriptWID);
//      if ( originalFileWID<=0 ) {
//         return 1;
//      }
//      getRemoteFilenameFromDiffScript(scriptWID,auto remoteFilename="");
//
//      _delete_temp_view(scriptWID);

      status = getFile(localFilename,version,auto originalFileWID=0);
      if (status) return status;
      getRemoteFilename(localFilename,auto remoteFilename="");

      if ( remoteFilename=="" ) {
         diff('-modal -bi2 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      } else {
         if ( version=="" ) version="HEAD";
         diff('-modal -bi2 -file2title "'remoteFilename'(Version 'version')"':+maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      }

      _delete_temp_view(originalFileWID);

      return 0;
   }

   private int hgRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0) {
      deferedInit();
      origWID := _create_temp_view(stdOutWID);
      p_window_id = origWID;
      int status = 0;
      int process_stdout_pipe,process_stdin_pipe,process_stderr_pipe;
      int process_handle=_PipeProcess(command,process_stdout_pipe,process_stdin_pipe,process_stderr_pipe,'');
      if ( process_handle>=0 ) {
         if ( dataToWriteToStdinWID && dataToWriteToStdinWID.p_Noflines ) {
            p_window_id = dataToWriteToStdinWID;
            top();up();
            while ( !down() ) {
               get_line(auto curLine);
               if (curLine!="") {
                  _PipeWrite(process_stdin_pipe,curLine"\n");
               }
            }
#if __WINDOWS__
            _PipeWrite(process_stdin_pipe,"\x1a");
#endif 
            p_window_id = origWID;
         }
      }
      for (i:=0;;++i) {
         _str buf1 = "";
         _str buf2 = "";
         _PipeRead(process_stdout_pipe,buf1,0,1);
         if ( buf1!='' ) {
            _PipeRead(process_stdout_pipe,buf1,length(buf1),0);
            stdOutWID._insert_text(buf1);
            int len=length(stdOutWID._expand_tabsc());
            stdOutWID.bottom();
            stdOutWID.p_col=len+1;
         }

         buf2='';
         _PipeRead(process_stderr_pipe,buf2,0,1);
         if ( buf2!='' ) {
            _PipeRead(process_stderr_pipe,buf2,length(buf2),0);
         }
         if ( hasBasicChallengeError(buf2) ) {
            getCommandLineWithUserNameAndPwd(command,auto newCommand="");
            if ( newCommand !="") {
               return hgRunCommand(newCommand,stdOutWID,stdErrData,dataToWriteToStdinWID);
            }
         }
         newLen := stdErrData.getLength()+length(buf2);
         if ( newLen>stdErrData.getCapacity() ) {
            stdErrData.setCapacity(stdErrData.getLength()+length(buf2));
         }
         stdErrData.append(buf2);
         int ppe=_PipeIsProcessExited(process_handle);
         if ( ppe && buf1=='' && buf2=='' && _PipeIsReadable(process_stdout_pipe)<=0 ) {
            break;
         }
      }
      _PipeCloseProcess(process_handle);
      return status;
   }

   private _str getCommandLineWithUserNameAndPwd(_str command,_str &newCommand) {
      SVC_AUTHENTICATE_INFO info;
      status := _SVCGetAuthInfo(info);
      if (status!=0) {
         return "";
      }
      exeName := parse_file(command);
      newCommand = exeName' --username 'info.username' --password 'info.password' 'command;
      return newCommand;
   }

   private boolean hasBasicChallengeError(_str buf) {
      p := pos("authorization failed: Could not authenticate to server: rejected Basic challenge",buf,1,'i');
      if ( p ) {
         return true;
      }
      return false;
   }

   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      origDir := getcwd();
      chdir(localRootPath(),1);
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive log --verbose --style=xml ":+maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getHistoryInformationForCurrentBranch cmdLine");
      status = hgRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      chdir(origDir,1);

      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      xmlhandle := _xmlcfg_open_from_buffer(historyOutputWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformation stderr");
      if ( status ) return status;
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      if ( xmlhandle<0 ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      _xmlcfg_find_simple_array(xmlhandle,"//logentry",auto indexArray);
      len := indexArray._length();
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      index := 0;

      int revisionList[];
      SVCHistoryInfo revisionTable:[];

      for ( i:=0;i<len;++i ) {
         curIndex := (int)indexArray[i];
         revision := _xmlcfg_get_attribute(xmlhandle,curIndex,"revision");

         authorIndex := getPCDataItem(xmlhandle,curIndex,"author",auto author="");
         dateAndTimeIndex := getPCDataItem(xmlhandle,curIndex,"date",auto dateAndTime="");
         commentIndex := getPCDataItem(xmlhandle,curIndex,"msg",auto comment="");
         // Put the revision in a list, and store the rest of the information in
         // a table with the revision as the key
         ARRAY_APPEND(revisionList,revision);
         revisionTable:[revision].author = author;
         revisionTable:[revision].date = dateAndTime;
         revisionTable:[revision].comment = comment;

         _xmlcfg_find_simple_array(xmlhandle,"paths/path",auto pathIndexArray,curIndex);
         pathIndexArrayLen := pathIndexArray._length();
         _str affectedFilesDetails = "";
         for ( j:=0;j<pathIndexArrayLen;++j ) {
            curPathIndex := _xmlcfg_get_first_child(xmlhandle,(int)pathIndexArray[j],VSXMLCFG_NODE_PCDATA);
            if ( curPathIndex>=0 ) {
               curPath := _xmlcfg_get_value(xmlhandle,curPathIndex);
               affectedFilesDetails = affectedFilesDetails:+"<br>"curPath;
            }
         }
         revisionTable:[revision].affectedFilesDetails = affectedFilesDetails;
      }

      // Sort the revision list by the revisions
      revisionList._sort('N');

      for ( i=0;i<len;++i ) {
         // Get the revision from the sorted array, and then add the rest of the
         // information from the table
         curRevision := revisionList[i];
         // Use the 'r' for the caption of the revision
         index = addHistoryItem(index,addFlags,historyInfo,false,_pic_file,
                                 curRevision,
                                 revisionTable:[curRevision].author,
                                 revisionTable:[curRevision].date,
                                 revisionTable:[curRevision].comment,
                                 revisionTable:[curRevision].affectedFilesDetails);
         addFlags = ADDFLAGS_SIBLINGAFTER;
      }
      _xmlcfg_close(xmlhandle);
      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;

      return status;
   }

   private int getPCDataItem(int xmlhandle,int index,_str fieldName,_str &item)
   {
      pcDataIndex := -1;
      item = "";
      childIndex := _xmlcfg_find_child_with_name(xmlhandle,index,fieldName);
      if ( childIndex>-1 ) {
         pcDataIndex = _xmlcfg_get_first_child(xmlhandle,childIndex,VSXMLCFG_NODE_PCDATA);
         if ( pcDataIndex>-1 ) {
            item = _xmlcfg_get_value(xmlhandle,pcDataIndex);
         }
      }
      return pcDataIndex;
   }

   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      se.datetime.DateTime dateCur;
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive log --style=xml --date \""dateBack.year()'-'dateBack.month()'-'dateBack.day()' to 'dateCur.year()'-'dateCur.month()'-'dateCur.day()'" ':+maybe_quote_filename(localRootPath());
      maybeOutputStrToLog(cmdLine,"getRepositoryInformation cmdLine");
      status = hgRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(historyOutputWID,"getRepositoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getRepositoryInformation stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,URL,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      xmlhandle := _xmlcfg_open_from_buffer(historyOutputWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformation stderr");
      if ( status ) return status;
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      if ( xmlhandle<0 ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,URL,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      _xmlcfg_find_simple_array(xmlhandle,"//logentry",auto indexArray);
      len := indexArray._length();
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      index := 0;

      int revisionList[];
      SVCHistoryInfo revisionTable:[];

      for ( i:=0;i<len;++i ) {
         curIndex := (int)indexArray[i];
         revision := _xmlcfg_get_attribute(xmlhandle,curIndex,"revision");

         authorIndex := getPCDataItem(xmlhandle,curIndex,"author",auto author="");
         dateAndTimeIndex := getPCDataItem(xmlhandle,curIndex,"date",auto dateAndTime="");
         commentIndex := getPCDataItem(xmlhandle,curIndex,"msg",auto comment="");
         // Put the revision in a list, and store the rest of the information in
         // a table with the revision as the key
         ARRAY_APPEND(revisionList,revision);
         revisionTable:[revision].author = author;
         revisionTable:[revision].date = dateAndTime;
         revisionTable:[revision].comment = comment;

         _xmlcfg_find_simple_array(xmlhandle,"paths/path",auto pathIndexArray,curIndex);
         pathIndexArrayLen := pathIndexArray._length();
         _str affectedFilesDetails = "";
         for ( j:=0;j<pathIndexArrayLen;++j ) {
            curPathIndex := _xmlcfg_get_first_child(xmlhandle,(int)pathIndexArray[j],VSXMLCFG_NODE_PCDATA);
            if ( curPathIndex>=0 ) {
               curPath := _xmlcfg_get_value(xmlhandle,curPathIndex);
               affectedFilesDetails = affectedFilesDetails:+"<br>"curPath;
            }
         }
         revisionTable:[revision].affectedFilesDetails = affectedFilesDetails;
      }

      // Sort the revision list by the revisions
      revisionList._sort('N');

      for ( i=0;i<len;++i ) {
         // Get the revision from the sorted array, and then add the rest of the
         // information from the table
         curRevision := revisionList[i];
         // Use the 'r' for the caption of the revision
         index = addHistoryItem(index,addFlags,historyInfo,false,_pic_file,
                                 curRevision,
                                 revisionTable:[curRevision].author,
                                 revisionTable:[curRevision].date,
                                 revisionTable:[curRevision].comment,
                                 revisionTable:[curRevision].affectedFilesDetails);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
      }
      _xmlcfg_close(xmlhandle);
      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;

      return status;
   }

   int getLocalFileBranch(_str localFilename,_str &URL) {
      return 0;
   }

   void getVersionNumberFromVersionCaption(_str revisionCaption,_str &versionNumber) {
      versionNumber = revisionCaption;
   }

   int getFile(_str localFilename,_str version,int &fileWID) {
      fileWID = 0;
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      versionStr := "";
      if ( version!="" ) {
         versionStr = "--rev "version;
      }
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive cat "versionStr' ' maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      status = hgRunCommand(cmdLine,fileWID,auto stdErrData);
      maybeOutputWIDToLog(fileWID,"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( status ) return status;

      tempFile := mktemp();

      status = fileWID._save_file('+o 'maybe_quote_filename(tempFile));
      _delete_temp_view(fileWID);

      _str encoding_option=_load_option_encoding(localFilename);
      status = _open_temp_view(tempFile,fileWID,origWID,'+d 'def_load_options' 'encoding_option" +L");
      if ( status ) return status;
      status = delete_file(tempFile);
      ext := get_extension(localFilename);
      langId := _Ext2LangId(ext);

      _SetEditorLanguage(langId);

      p_window_id = origWID;
      return status;
   }

   int getRemoteFilename(_str localFilename,_str &remoteFilename) {
      status := getExeStr(auto exeStr);
      remoteFilename = "";
      deferedInit();
      return 0;
   }

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive status "maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getFileStatus cmdLine");
      status = hgRunCommand(cmdLine,auto hgOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"getFileStatus cmdLine="cmdLine);
      popd();
      SVCWriteWIDToOutputWindow(hgOutputWID);
      hgOutputWID.top();
      hgOutputWID.get_line(auto curLine);
      _delete_temp_view(hgOutputWID);
      fileStatus = getStatusFromOutput(curLine);

      return 0;
   }

   int updateFiles(_str (&localFilenames)[],int options=0) {
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive update ";
      maybeOutputStrToLog(cmdLine,"updateFiles cmdLine");
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"updateFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"updateFiles stdout");
      maybeOutputStringToLog(stdErrData,"updateFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"update",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
   }

   int updateFile(_str localFilename,int options=0) {
      // Call deferedInit() in updateFiles()
      // localFilename doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := updateFiles(tempFilenames,options);
      return status;
   }

   void maybeOutputWIDToLog(int WID,_str label) {
      if ( !def_svc_logging ) return;
      dsay(label,"svc");
      origWID := p_window_id;
      p_window_id = WID;
      top();up();
      while ( !down() ) {
         get_line(auto curLine);
         dsay(label':'curLine,"svc",1);
      }
      p_window_id = origWID;
   }

   void maybeOutputStringToLog(String stdErrData,_str label) {
      if ( !def_svc_logging ) return;
      dsay(label,"svc");
      dsay(label':'stdErrData,"svc",1);
   }

   void maybeOutputStrToLog(_str stdErrData,_str label) {
      if ( !def_svc_logging ) return;
      dsay(label,"svc");
      dsay(label':'stdErrData,"svc",1);
   }

   int revertFiles(_str (&localFilenames)[],int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      writeToTargetFile(localFilenames,auto targetFilename);
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive revert \"set:'listfile:"targetFilename"'\"";
      maybeOutputStrToLog(cmdLine,"revertFiles cmdLine=");
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"revertFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"revertFiles stdout");
      maybeOutputStringToLog(stdErrData,"revertFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"revert",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      _reload_vc_buffers(localFilenames);
      _retag_vc_buffers(localFilenames);
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);
      delete_file(targetFilename);

      return 0;
   }

   int revertFile(_str localFilename,int options=0) {
      // Call deferedInit() in revertFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := revertFiles(tempFilenames,options);
      return status;
   }

   int getComment(_str &commentFilename,_str &tag,_str fileBeingCheckedIn,boolean showApplyToAll=true,
                  boolean &applyToAll=false,boolean showTag=true,boolean showAuthor=false,_str &author='') {
      if ( commentFilename=="" ) commentFilename = mktemp();
      return _CVSGetComment(commentFilename,tag,fileBeingCheckedIn,showApplyToAll,applyToAll,showTag,showAuthor,author);
   }

   int commitFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      origPath := getcwd();
      showApplyToAll := true;
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {

         status = getComment(auto commentFilename="","",localFilenames[i],showApplyToAll,auto applyToAll=false,false);
         if ( status ) {
            return status;
         }

         commitOutputWID := 0;
         targetFilename  := "";
         if ( applyToAll ) {
            writeToTargetFile(localFilenames,targetFilename);

            chdir(localRootPath(),1);
            cmdLine := maybe_quote_filename(exeStr)" --noninteractive commit --logfile "maybe_quote_filename(commentFilename)" set:'listfile:"maybe_quote_filename(targetFilename)"'";
            maybeOutputStrToLog(cmdLine,"commitFiles cmdLine");
            status = hgRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            chdir(origPath,1);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
            delete_file(targetFilename);
            delete_file(commentFilename);
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               delete_file(targetFilename);
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
            SVCWriteWIDToOutputWindow(commitOutputWID);
            _delete_temp_view(commitOutputWID);
            break;
         } else {
            pushd(_file_path(localFilenames[i]));
            cmdLine := maybe_quote_filename(exeStr)" --noninteractive commit  --logfile "maybe_quote_filename(commentFilename)' 'maybe_quote_filename(_strip_filename(localFilenames[i],'p'));
            status = hgRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            popd();
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
         }
         SVCWriteWIDToOutputWindow(commitOutputWID);
         delete_file(commentFilename);
         _delete_temp_view(commitOutputWID);
      }
      _reload_vc_buffers(localFilenames);
      _retag_vc_buffers(localFilenames);

      return 0;
   }

   int commitFile(_str localFilename,_str comment=null,int options=0) {
      // call deferedInit() in commitFiles()
      _str localFilenames[];
      localFilenames[0] = localFilename;
      status := commitFiles(localFilenames,comment,options);
      return status;
   }

   private int writeToTargetFile(_str (&localFilenames)[],_str &targetFilename) {
      origWID := _create_temp_view(auto fileListWID);
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         curFileName := strip(localFilenames[i],'B','"');
         if ( last_char(curFileName)==FILESEP ) {
            curFileName = substr(curFileName,1,length(curFileName)-1);
         }
         insert_line(curFileName);
      }
      targetFilename = tempFilename();
      status := _save_file("+o "maybe_quote_filename(targetFilename));
      p_window_id = origWID;
      _delete_temp_view(fileListWID);
      return status;
   }

   private _str tempFilename() {
      path := localRootPath();
      temp := _strip_filename(mktemp(),'P');
      filename := stranslate(path:+FILESEP:+temp,'/',FILESEP);
      return filename;
   }

   _str localRootPath() {
      fileWID := 0;
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;
      status = hgRunCommand(maybe_quote_filename(exeStr)" --noninteractive root",fileWID,auto stdErrData);
      maybeOutputWIDToLog(fileWID,"tempFilename stdout");
      maybeOutputStringToLog(stdErrData,"tempFilename stderr");
      if ( status ) return status;

      p_window_id = fileWID;
      top();
      get_line(auto path="");
      p_window_id = origWID;
      _delete_temp_view(fileWID);

      if ( path=="" ) {
         origPath := getcwd();

         workingDir := _ProjectGet_WorkingDir(_ProjectHandle());
         workingDir = absolute(workingDir,_file_path(_project_name));

         chdir(workingDir,1);
         origWID = p_window_id;
         status = hgRunCommand(maybe_quote_filename(exeStr)" --noninteractive root",fileWID,stdErrData);
         maybeOutputWIDToLog(fileWID,"tempFilename stdout");
         maybeOutputStringToLog(stdErrData,"tempFilename stderr");
         chdir(origPath,1);
         if ( status ) return status;

         p_window_id = fileWID;
         top();
         get_line(path);

         p_window_id = origWID;
         _delete_temp_view(fileWID);
      }

      return path;
   }

   int mergeFile(_str localFilename,int options=0) {
      status := 0;
      
      return status;
   }

   int getURLChildDirectories(_str URLPath,STRARRAY &urlChildDirectories) {
      return 0;
   }

   int checkout(_str URLPath,_str localPath,int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      mou_hour_glass(1);
      status = 0;
      int checkoutOutputWID = 0;

      return status;
   }

   SVCCommandsAvailable commandsAvailable() {
      return SVC_COMMAND_AVAILABLE_COMMIT|
         SVC_COMMAND_AVAILABLE_DIFF|
         SVC_COMMAND_AVAILABLE_HISTORY|
         SVC_COMMAND_AVAILABLE_MERGE|
         SVC_COMMAND_AVAILABLE_REVERT|
         SVC_COMMAND_AVAILABLE_ADD|
         SVC_COMMAND_AVAILABLE_REMOVE|
         SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH|
         SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT|
         SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE|
         SVC_COMMAND_AVAILABLE_UPDATE|
         SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY|
         SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY|
         SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY|
         SVC_COMMAND_AVAILABLE_HISTORY_DIFF;
   }

   _str getCaptionForCommand(SVCCommands command,boolean withHotkey=true,boolean mixedCaseCaption=true) {
      caption := m_captionTable[command];
      if ( caption==null ) {
         caption = "";
      }
      if ( !withHotkey  ) {
         caption = stranslate(caption,'','&');
      }
      if ( !mixedCaseCaption ) {
         caption = lowcase(caption);
      }
      return caption;
   }

   int editFiles(_str (&localFilenames)[],int options=0) {
      return 0;
   }

   int editFile(_str localFilename,int options=0) {
      // Call deferedInit() in editFiles
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := editFiles(tempFilenames,options);
      return status;
   }

   int addFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      writeToTargetFile(localFilenames,auto targetFilename);
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive add \"set:'listfile:"targetFilename"'\"";
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"addFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"addFiles stdout");
      maybeOutputStringToLog(stdErrData,"addFiles stderr");
      delete_file(targetFilename);
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_ADD_FILE,"add",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
   }

   int addFile(_str localFilename,_str comment=null,int options=0) {
      // Call deferedInit() in addFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := addFiles(tempFilenames,options);
      return status;
   }

   int removeFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      result := _message_box(nls("This will remove local files.\n\nContinue?"),"",MB_YESNO);
      if ( result!=IDYES ) {
         return COMMAND_CANCELLED_RC;
      }
      pushd(localRootPath());
      writeToTargetFile(localFilenames,auto targetFilename);
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive remove --force \"set:'listfile:"targetFilename"'\"";
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"removeFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"removeFiles stdout");
      maybeOutputStringToLog(stdErrData,"removeFiles stderr");
      delete_file(targetFilename);
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,"remove",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
   }

   int removeFile(_str localFilename,_str comment=null,int options=0) {
      status := 0;
      // Call deferedInit() in removeFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status = removeFiles(tempFilenames,options);
      return status;
   }

   int resolveFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      return status;
   }

   int resolveFile(_str localFilename,_str comment=null,int options=0) {
      status := 0;
      // Call deferedInit() in removeFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status = resolveFiles(tempFilenames,options);
      return status;
   }

   int getMultiFileStatus(_str localPath,SVC_UPDATE_INFO (&fileStatusList)[],
                          SVC_UPDATE_TYPE updateType=SVC_UPDATE_PATH,
                          boolean recursive=true,int options=0,_str &remoteURL="") {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      localPath = strip(localPath,'B','"');
      if ( !file_exists(localPath) ) {
//         _message_box(get_message(FILE_NOT_FOUND_RC,localPath));
         return FILE_NOT_FOUND_RC;
      }

      recurseOption := recursive?"":"--subrepos";

      origPath := getcwd();
      if ( last_char(localPath)==FILESEP ) {
         // Hg doens't like the trailing FILESEP
         localPath = substr(localPath,1,length(localPath)-1);
      }
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive status ":+recurseOption:+' ':+maybe_quote_filename(localPath);
      maybeOutputStrToLog(cmdLine,"getMultiFileStatus command");
      root := localRootPath();
      chdir(root,1);
      status = hgRunCommand(cmdLine,auto statusWID=0,auto stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(statusWID,"getMultiFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
      if ( status || (length(stdErrData)>1 && statusWID.p_Noflines==0) ) {
         status = SVC_COULD_NOT_GET_FILE_STATUS;
         _message_box(get_message(status,stdErrData));
         _delete_temp_view(statusWID);
         return status;
      }
      origWID := p_window_id;
      p_window_id = statusWID;

      _maybe_append(root,FILESEP);
      top();up();
      while ( !down() ) {
         get_line(auto line);
         if ( line=='' ) break;
         SVC_UPDATE_INFO * pCurFileInfo = &fileStatusList[fileStatusList._length()];
         pCurFileInfo->filename := root:+substr(line,3);

         pCurFileInfo->status = getStatusFromOutput(substr(line,1,1));
      }
      p_window_id = origWID;
      getRemoteURLName(remoteURL);

      _delete_temp_view(statusWID);

      return status;
   }

   private SVCFileStatus getStatusFromOutput(_str line) {
      int status = 0;
      switch ( substr(line,1,1) ) {
      case 'M':
         status=SVC_STATUS_MODIFIED;break;
      case 'A':
         status=SVC_STATUS_SCHEDULED_FOR_ADDITION;break;
      case 'R':
         status=SVC_STATUS_SCHEDULED_FOR_DELETION;break;
      case 'C':
         status=0;break;
      case '!':
         status=SVC_STATUS_MISSING;break;
      case '?':
         status=SVC_STATUS_NOT_CONTROLED;break;
      case 'I':
         status=SVC_STATUS_IGNORED;break;
      }
      return status;
   }

   _str getSystemNameCaption() {
      return "Mercurial";
   }

   _str getSystemSpecificInfo(_str fieldName) {
      return "";
   }

   _str getFixedUpdatePath(boolean forceCalculation=false) {
      return "";
   }

   boolean hotkeyUsed(_str hotkeyLetter,boolean onMenu=true) {
      foreach ( auto curCap in m_captionTable ) {
         if ( pos('&'hotkeyLetter,curCap,1,'i') ) {
            return true;
         }
      }
      return false;
   }

   private boolean _pathIsParentDirectory(_str path,_str parentPath) {
      lenPath := length(path);
      lenParentPath := length(parentPath);
      if ( lenPath < lenParentPath )  {
         return false;
      }
      pieceOfPath := substr(path,1,lenParentPath);
      match := file_eq(pieceOfPath,parentPath);
      return match;
   }

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]) {
      _str pathsSoFar:[];

      len := projPaths._length();
      for ( i:=0;i<len;++i ) {
         curPath := projPaths[i];
         topHgPath := localRootPath();
         if ( topHgPath!="" && !pathsSoFar._indexin(topHgPath) ) {
            pathsToUpdate[pathsToUpdate._length()] = topHgPath;
            pathsSoFar:[topHgPath] = "";
         }
      }
      // First copy to the output, then sort as filenames
      pathsToUpdate = projPaths;
      pathsToUpdate._sort('f'_fpos_case);

      len = pathsToUpdate._length();
      for ( i=0;i+1<len;++i ) {
         // If the length of the next path is longer than the current, and 
         // the beginning matches, remove the later one.
         if ( length(pathsToUpdate[i+1])>length(pathsToUpdate[i]) &&
              file_eq(substr(pathsToUpdate[i+1],1,length(pathsToUpdate[i])),pathsToUpdate[i])
                      ) {
            pathsToUpdate._deleteel(i+1);
            --len;
            --i;
         }
      }
   }

   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      status = hgRunCommand(maybe_quote_filename(exeStr)" --noninteractive log --limit 1 "maybe_quote_filename(localFilename),auto graphWID=0,auto stdErrData);
      maybeOutputWIDToLog(graphWID,"getCurRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurRevision stderr");
      if ( status ) return status;

      p_window_id = graphWID;
      top();
      status = search('^changeset\:','@r');
      if ( !status ) {
         get_line(auto line);
         parse line with 'changeset:   '  curRevision ':' .;
      }
      p_window_id = origWID;
      _delete_temp_view(graphWID);
      return status;
   }

   SVCSystemSpecificFlags getSystemSpecificFlags() {
      return SVC_UPDATE_PATHS_RECURSIVE;
   }

   int getLocalFileURL(_str localFilename,_str &URL) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      status = hgRunCommand(maybe_quote_filename(exeStr)" --noninteractive paths default",auto graphWID=0,auto stdErrData);
      maybeOutputWIDToLog(graphWID,"getLocalFileURL stdout");
      maybeOutputStringToLog(stdErrData,"getLocalFileURL stderr");
      if ( status ) return status;

      p_window_id = graphWID;
      top();
      get_line(URL);
      p_window_id = origWID;
      _delete_temp_view(graphWID);
      return status;
   }

   int getCurLocalRevision(_str localFilename,_str &curRevision,boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      cmdLine := maybe_quote_filename(exeStr)" --noninteractive log -l 1 --template {rev} "maybe_quote_filename(localFilename);maybe_quote_filename(exeStr)" --noninteractive log -l 1 --template '{rev}\n' "maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getCurLocalRevision cmdLine");
      status = hgRunCommand(cmdLine,auto graphWID=0,auto stdErrData);
      maybeOutputWIDToLog(graphWID,"getCurLocalRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurLocalRevision stderr");
      if ( status ) return status;

      p_window_id = graphWID;
      top();
      get_line(curRevision);
      p_window_id = origWID;
      _delete_temp_view(graphWID);
      return status;
   }

   int pushToRepository(_str path="",int options=0) {
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive push ";
      maybeOutputStrToLog(cmdLine,"pushToRepository cmdLine");
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"pushToRepository cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"pushToRepository stdout");
      maybeOutputStringToLog(stdErrData,"pushToRepository stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_PUSH_TO_REPOSITORY,stdErrData));
         return SVC_COULD_NOT_PUSH_TO_REPOSITORY;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
   }

   int pullFromRepository(_str path="",int options=0){
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive pull ";
      maybeOutputStrToLog(cmdLine,"pullFromRepository cmdLine");
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"pullFromRepository cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"pullFromRepository stdout");
      maybeOutputStringToLog(stdErrData,"pullFromRepository stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_PULL_FROM_REPOSITORY,stdErrData));
         return SVC_COULD_NOT_PULL_FROM_REPOSITORY;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
   }
   int getNumVersions(_str localFilename) {
      enumerateVersions(localFilename,auto versions);
      return versions._length();
   }

   private int getRemoteURLName(_str &URL) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      pushd(localRootPath());
      cmdLine := maybe_quote_filename(exeStr)" --noninteractive paths ";
      maybeOutputStrToLog(cmdLine,"getRemoteURLName cmdLine");
      status = hgRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"getRemoteURLName cmdLine="cmdLine);
      popd();
      commitOutputWID.top();
      commitOutputWID.get_line(URL);
      parse URL with "default = " URL;
      return status;
   }

   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quite=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      cmdLine := maybe_quote_filename(exeStr)" --noninteractive log --verbose --style=xml ":+maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getHistoryInformationForCurrentBranch cmdLine");
      status = hgRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      xmlhandle := _xmlcfg_open_from_buffer(historyOutputWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformation stderr");
      if ( status ) return status;
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      if ( xmlhandle<0 ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      _xmlcfg_find_simple_array(xmlhandle,"//logentry",auto indexArray);
      len := indexArray._length();
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      index := 0;

      int revisionList[];
      SVCHistoryInfo revisionTable:[];

      for ( i:=0;i<len;++i ) {
         curIndex := (int)indexArray[i];
         revision := _xmlcfg_get_attribute(xmlhandle,curIndex,"revision");

         authorIndex := getPCDataItem(xmlhandle,curIndex,"author",auto author="");
         dateAndTimeIndex := getPCDataItem(xmlhandle,curIndex,"date",auto dateAndTime="");
         commentIndex := getPCDataItem(xmlhandle,curIndex,"msg",auto comment="");
         // Put the revision in a list, and store the rest of the information in
         // a table with the revision as the key
         ARRAY_APPEND(versions,revision);
      }
      _xmlcfg_close(xmlhandle);
      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;

      return status;
   }
};
