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
#include "git.sh"

#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#import "main.e"
#import "GitBuildFile.e"
#import "SubversionBuildFile.e"
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

class GitTempWID {
   private _str m_filename = "";
   private int m_WID = -1;

   GitTempWID(_str filename="",int viewID=-1) {
      set(filename,viewID);
   }
   void close() {
      if ( m_WID>=0  ) {
         _delete_temp_view(m_WID);
      }
      status := delete_file(m_filename);
      if ( status ) {
//         say('~GitTempView could not delete m_filename='m_filename' status='status);
      }
   }
   int wid() {
      return m_WID;
   }
   void set(_str filename="",int viewID=-1) {
      m_filename = filename;
      m_WID = viewID;
   }
};

class Git : IVersionControl {
   private boolean m_debug = false;
   private _str m_captionTable[];
   private _str m_version = "";
   private int m_didDeferredInit = 0;

   Git() {
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

   ~Git() {
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
      originalWID := p_window_id;
      p_window_id = scriptWID;

      top();
      get_line(auto topLine);
      parse topLine with 'diff --git a/' remoteFilename .;

      p_window_id = originalWID;
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
      if ( def_git_info.git_exe_name=="" || 
           !file_exists(def_git_info.git_exe_name) ) {
         _str exeName = "";
#if __UNIX__
         exeName='git';
#else
         exeName="git.exe";
#endif
         def_git_info.git_exe_name=path_search(exeName);
         if ( def_git_info.git_exe_name=="" || 
              !file_exists(def_git_info.git_exe_name) ) {
            return SVC_COULD_NOT_FIND_VC_EXE;
         }
      }
      exeStr = def_git_info.git_exe_name;
      return 0;
   }

   int diffLocalFile(_str localFilename,_str version="",int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
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
         versionSpec = version' ';
      }
      origPath := getcwd();
//      chdir(_file_path(localFilename),1);
//      cmdLine := maybe_quote_filename(exeStr)" --no-pager diff "versionSpec:+maybe_quote_filename(localFilename);
//      maybeOutputStrToLog(cmdLine,"diffLocalFile cmdLine");
//      status = gitRunCommand(cmdLine,auto scriptWID,auto stdErrData);
//      chdir(origPath,1);
//      maybeOutputWIDToLog(scriptWID.wid(),"diffLocalFile stdout");
//      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
//      if ( status || (length(stdErrData)>1 && scriptWID.wid().p_Noflines==0) ) {
//         status = SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
//         _message_box(get_message(status,localFilename,stdErrData));
//         SVCWriteToOutputWindow(stdErrData.get());
//         return status;
//      }
//      GitBuildFile bf;
//      originalFileWID := bf.buildOriginalFile(localFilename,scriptWID.wid());
//      if ( originalFileWID<=0 ) {
//         return 1;
//      }
//      getRemoteFilenameFromDiffScript(scriptWID.wid(),auto remoteFilename="");
//
//      scriptWID.close();

      status = getFile(localFilename,version,auto originalFileWID=0);
      if (status) return status;
      getRemoteFilename(localFilename,auto remoteFilename="");

      if ( remoteFilename=="" ) {
         diff('-modal -bi2 -r2 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      } else {
         diff('-modal -bi2 -r2 -file2title 'maybe_quote_filename(remoteFilename)' 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      }

      _delete_temp_view(originalFileWID);

      return 0;
   }

   private int gitRunCommand(_str command,GitTempWID &stdOut,String &stdErrData,_str shellOptions="Q") {
      deferedInit();
      int status = 0;
      stdOutFile := mktemp(1,'1');
      stdErrFile := mktemp(1,'2');
      command = command' 1>'maybe_quote_filename(stdOutFile)' 2>'maybe_quote_filename(stdErrFile);
      shell(command,shellOptions);
      status = _open_temp_view(stdOutFile,auto stdOutWID,auto origWID);
      if ( status ) return status;
      p_window_id = origWID;
      status = _open_temp_view(stdErrFile,auto stdErrWID,origWID);
      if ( status ) return status;
      p_window_id = stdErrWID;
      top();up();
      while (!down()) {
         get_line(auto curLine);
         stdErrData.append(curLine);
         if (p_line!=1) {
            stdErrData.append("\n");
         }
      }
      p_window_id = origWID;
      _delete_temp_view(stdErrWID);
      stdOut.set(stdOutFile,stdOutWID);
      status = delete_file(stdErrFile);
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

      origPath := getcwd();
      chdir(_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" --no-pager log ":+maybe_quote_filename(_strip_filename(localFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getHistoryInformationForCurrentBranch cmdLine");
#if 1
      status = gitRunCommand(cmdLine,auto historyOutputWID,auto stdErrData);
#else
      filename := 'c:\temp\gittest3.txt';
      _open_temp_view(filename,auto tempWID,auto tempOrigWID);
      GitTempWID historyOutputWID;
      String stdErrData;
      historyOutputWID.set(filename,tempWID);
#endif
      chdir(origPath,1);
      maybeOutputStrToLog(getcwd(),"getHistoryInformationForCurrentBranch getcwd()");
      maybeOutputWIDToLog(historyOutputWID.wid(),"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.wid().p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID.wid();
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      revisionCaption := "";
      for (;;) {
         get_line(auto curLine);
         parse curLine with "commit " auto revision;
         if ( down() ) break;
         get_line(curLine);

         // If a merge was inserted, skip over it.  Doesn't help for our history
         // info
         if ( pos("Merge:",curLine)==1 ) {
            if ( down() ) break;
            get_line(curLine);
         }
         parse curLine with "Author: " auto author;
         if ( down() ) break;
         get_line(curLine);
         parse curLine with "Date:   " auto date;
         if ( down() ) break;
         if ( down() ) break;
         comment := "";
         for (;;) {
            get_line(curLine);
            if ( substr(curLine,1,4)!="    " ) break;
            curLine = substr(curLine,5);// Remove space from the beginning of the comment
            if ( pos("    Conflicts:",curLine)==1 ) {
               while ( !down() ) {
                  get_line(curLine);
                  if ( curLine=="" ) break;
               }
            }
            if ( comment==null || comment == "" ) {
               comment = curLine;
               revisionCaption = comment;
            } else {
               comment = comment"\n"curLine;
            }
            if ( down() ) break;
         }
         curIndex = addHistoryItem(curIndex,addFlags,historyInfo,false,_pic_file,revision,author,date,comment,"",revisionCaption);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
#if 0 //12:06pm 6/27/2013
         if ( down() ) break;
         get_line(curLine);
         if ( pos("    Conflicts:",curLine)==1 ) {
            for (;;) {
               get_line(curLine);
               if ( curLine=="" ) break;
               if ( down() ) break;
            }
            if ( down() ) break;
         }
#endif 
      }
      p_window_id = origWID;

      historyOutputWID.close();

      return status;
   }

   private int getPCDataItem(int xmlhandle,int index,_str fieldName,_str &item) {
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
      if ( !file_exists(URL) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,URL));
         return FILE_NOT_FOUND_RC;
      }

      se.datetime.DateTime dateCur;
      cmdLine := maybe_quote_filename(exeStr)" log -p --name-only --since "dateBack.year()'-'dateBack.month()'-'dateBack.day();
      maybeOutputStrToLog(cmdLine,"getRepositoryInformation cmdLine");
      status = gitRunCommand(cmdLine,auto logOutputWID,auto stdErrData);
      maybeOutputWIDToLog(logOutputWID.wid(),"getRepositoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getRepositoryInformation stderr");
      if ( status || (length(stdErrData)>1 && logOutputWID.wid().p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,URL,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      origWID := p_window_id;
      p_window_id = logOutputWID.wid();
      top();
      curIndex := 0;
      revisionCaption := "";
      addFlags := ADDFLAGS_ASCHILD;
      for (;;) {
         get_line(auto curLine);
         parse curLine with "commit " auto revision;
         if ( down() ) break;
         get_line(curLine);

         // If a merge was inserted, skip over it.  Doesn't help for our history
         // info
         getFiles := true;
         if (pos("Merge:",curLine)==1) {
            getFiles = false;
            if ( down() ) break;
            get_line(curLine);
         }

         parse curLine with "Author: " auto author;
         if ( down() ) break;
         get_line(curLine);
         parse curLine with "Date:   " auto date;
         if ( down() ) break;
         if ( down() ) break;
         comment := "";
         for (;;) {
            get_line(curLine);
            if ( curLine=="" ) break;
            if ( comment==null || comment == "" ) {
               comment = curLine;
               revisionCaption = comment;
            } else {
               comment = comment"\n"curLine;
            }
            if ( down() ) break;
         }
         affectedFiles := "";
         if ( getFiles ) {
            down();
            for (;;) {
               get_line(curLine);
               if ( curLine=="" ) break;
               affectedFiles = affectedFiles"<br>"curLine;
               if ( down() ) break;
            }
         }
         curIndex = addHistoryItem(curIndex,addFlags,historyInfo,false,_pic_file,revision,author,date,comment,affectedFiles,revisionCaption);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
         if ( down() ) break;
      }
      p_window_id = origWID;

      logOutputWID.close();

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
         versionStr = version;
      } else {
         versionStr = 'HEAD';
      }
      gitFilename := "";
      if (pos(localRootPath(),localFilename)==1) {
         gitFilename = stranslate(substr(localFilename,length(localRootPath())+1),'/',FILESEP);
      } else {
         gitFilename = localFilename;
      }
      origDir := getcwd();
      path := _file_path(localFilename);
      status = chdir(path);
      cmdLine := maybe_quote_filename(exeStr)" --no-pager show "versionStr':'maybe_quote_filename('./'_strip_filename(gitFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      maybeOutputStrToLog(getcwd(),"getFile getcwd()=");
      maybeOutputStrToLog(localFilename,"getFile localFilename=");
      status = gitRunCommand(cmdLine,auto tempFileWID,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(tempFileWID.wid(),"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( status || (length(stdErrData)>1 && tempFileWID.wid().p_Noflines==0) ) {
         status = SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
         _message_box(get_message(status,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return status;
      }

      tempFile := mktemp();

      status = tempFileWID.wid()._save_file('+o 'maybe_quote_filename(tempFile));

      //_delete_temp_view(fileWID);
      tempFileWID.close();
      p_window_id = origWID;

      // Use +L to be sure we can delete the file while it is open
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
      deferedInit();
      remoteFilename = stranslate(substr(localFilename,length(localRootPath())+1),'/',FILESEP);
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
      cmdLine := maybe_quote_filename(exeStr)" status --porcelain "maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getFileStatus cmdLine");
      status = gitRunCommand(cmdLine,auto hgOutputWID,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"getFileStatus cmdLine="cmdLine);
      popd();
      SVCWriteWIDToOutputWindow(hgOutputWID.wid());
      hgOutputWID.wid().top();
      hgOutputWID.wid().get_line(auto curLine);
      hgOutputWID.close();
      fileStatus = getStatusFromOutput(curLine);

      return 0;
   }

   int updateFiles(_str (&localFilenames)[],int options=0) {
#if 0 //3:07pm 4/24/2013
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
      cmdLine := maybe_quote_filename(exeStr)" update ";
      maybeOutputStrToLog(cmdLine,"updateFiles cmdLine");
      status = gitRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
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
#endif

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
      origWID := p_window_id;

      origPath := getcwd();
      foreach (auto curFilename in localFilenames) {
         curPath := _file_path(curFilename);
         chdir(curPath);
         status = getCurRevision(curFilename,auto curRevision="");
         if ( status ) return status;
         cmdLine := maybe_quote_filename(exeStr)" checkout  "curRevision' 'maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"revertFiles cmdLine");
         status = gitRunCommand(cmdLine,auto revertOutputWID,auto stdErrData);
         maybeOutputWIDToLog(revertOutputWID.wid(),"revertFiles stdout");
         maybeOutputStringToLog(stdErrData,"revertFiles stderr");
         revertOutputWID.close();
      }
      p_window_id = origWID;
      chdir(origPath,1);

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

      showApplyToAll := true;
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {

         status = getComment(auto commentFilename="","",localFilenames[i],showApplyToAll,auto applyToAll=false,false);
         if ( status ) {
            return status;
         }

         GitTempWID commitOutputWID;
         if ( applyToAll ) {
            origDir := getcwd();
            chdir(_file_path(localFilenames[i]),1);
            status = addFilesToCommit(localFilenames,i);
            if ( status ) {
               chdir(origDir,1);
               return status;
            }

            cmdLine := maybe_quote_filename(exeStr)" commit -F "maybe_quote_filename(commentFilename);
            maybeOutputStrToLog(cmdLine,"commitFiles 10 cmdLine");
            status = gitRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            chdir(origDir,1);
            maybeOutputStrToLog(cmdLine,"commitFiles cmdLine");
            maybeOutputStrToLog(getcwd(),"commitFiles getcwd");
            maybeOutputWIDToLog(commitOutputWID.wid(),"commitFiles 10 stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles 10 stderr");
            delete_file(commentFilename);
            if ( status || (length(stdErrData)>1 && commitOutputWID.wid().p_Noflines==0) ) {
               _message_box(get_message(SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
            SVCWriteWIDToOutputWindow(commitOutputWID.wid());
            commitOutputWID.close();
            break;
         } else {
            STRARRAY temp;
            temp[0] = localFilenames[i];
            origDir := getcwd();
            chdir(_file_path(temp[0]),1);
            addFilesToCommit(temp);
            cmdLine := maybe_quote_filename(exeStr)" commit -F "maybe_quote_filename(commentFilename);
            maybeOutputStrToLog(cmdLine,"commitFiles 20 cmdLine="cmdLine);
            status = gitRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            chdir(origDir,1);
            maybeOutputWIDToLog(commitOutputWID.wid(),"commitFiles 20 stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles 20 stderr");
            if ( status || (length(stdErrData)>1 && commitOutputWID.wid().p_Noflines==0) ) {
               _message_box(get_message(SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
         }
         SVCWriteWIDToOutputWindow(commitOutputWID.wid());
         delete_file(commentFilename);
         commitOutputWID.close();
      }
      _reload_vc_buffers(localFilenames);
      _retag_vc_buffers(localFilenames);

      return 0;
   }

   int addFilesToCommit(STRARRAY &localFilenames,int startIndex=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      len := localFilenames._length();
      for (i:=startIndex;i<len;++i) {
         curFilename := localFilenames[i];
         if ( !file_exists(curFilename) ) {
            _message_box(get_message(FILE_NOT_FOUND_RC,curFilename));
            return FILE_NOT_FOUND_RC;
         }
         cmdLine := maybe_quote_filename(exeStr)" add ":+maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"addFilesToCommit cmdLine");
         status = gitRunCommand(cmdLine,auto addOutputWID,auto stdErrData);
         maybeOutputWIDToLog(addOutputWID.wid(),"addFilesToCommit stdout");
         maybeOutputStringToLog(stdErrData,"addFilesToCommit stderr");
         if ( status || (length(stdErrData)>1 && addOutputWID.wid().p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_ADD_FILE,"add",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            return SVC_COULD_NOT_ADD_FILE;
         }
         addOutputWID.close();
      }
      return 0;
   }

   int commitFile(_str localFilename,_str comment=null,int options=0) {
      _str localFilenames[];
      localFilenames[0] = localFilename;
      status := commitFiles(localFilenames,comment,options);
      return status;
   }

   private _str tempFilename() {
      path := localRootPath();
      temp := _strip_filename(mktemp(),'P');
      filename := stranslate(path:+FILESEP:+temp,'/',FILESEP);
      return filename;
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
         SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY|
         SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY|
         SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY|
         SVC_COMMAND_AVAILABLE_UPDATE|
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

      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         curFilename := localFilenames[i];
         if ( !file_exists(curFilename) ) {
            _message_box(get_message(FILE_NOT_FOUND_RC,curFilename));
            return FILE_NOT_FOUND_RC;
         }
         origDir := getcwd();
         chdir(_file_path(localFilenames[i]),1);
         cmdLine := maybe_quote_filename(exeStr)" add ":+maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"addFiles cmdLine");
         status = gitRunCommand(cmdLine,auto addOutputWID,auto stdErrData);
         chdir(origDir,1);
         maybeOutputWIDToLog(addOutputWID.wid(),"addFiles stdout");
         maybeOutputStringToLog(stdErrData,"addFiles stderr");
         if ( status || (length(stdErrData)>1 && addOutputWID.wid().p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_ADD_FILE,"add",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            return SVC_COULD_NOT_ADD_FILE;
         }
         addOutputWID.close();
      }
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

      origPath := getcwd();
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         curFilename := localFilenames[i];
         if ( !file_exists(curFilename) ) {
            _message_box(get_message(FILE_NOT_FOUND_RC,curFilename));
            return FILE_NOT_FOUND_RC;
         }
         curPath := _file_path(curFilename);
         chdir(curPath,1);
         maybeOutputStrToLog(getcwd(),"removeFiles getcwd()");
         cmdLine := maybe_quote_filename(exeStr)" rm ":+maybe_quote_filename(_strip_filename(curFilename,'P'));
         maybeOutputStrToLog(cmdLine,"removeFiles cmdLine");
         status = gitRunCommand(cmdLine,auto removeOutputWID,auto stdErrData);
         maybeOutputWIDToLog(removeOutputWID.wid(),"removeFiles stdout");
         maybeOutputStringToLog(stdErrData,"removeFiles stderr");
         if ( status || (length(stdErrData)>1 && removeOutputWID.wid().p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_ADD_FILE,"rm",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            chdir(origPath,1);
            return SVC_COULD_NOT_ADD_FILE;
         }
         removeOutputWID.close();
      }
      chdir(origPath,1);
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
      if ( !file_exists(localPath) ) {
//         _message_box(get_message(FILE_NOT_FOUND_RC,localPath));
         return FILE_NOT_FOUND_RC;
      }
      status = gitRunCommand(maybe_quote_filename(exeStr)' remote  -v',auto remoteWID,auto stdErrData);
      remoteWID.wid().top();
      remoteWID.wid().get_line(remoteURL);
      remoteWID.close();

      parse remoteURL with auto branch remoteURL ' (fetch)';

      recurseOption := recursive?"":"--subrepos";

      origPath := getcwd();
      chdir(localPath,1);
      localRootPath := localRootPath();
      cmdLine := maybe_quote_filename(exeStr)' status --porcelain ';
      maybeOutputStrToLog(cmdLine,"getMultiFileStatus cmdLine");
      status = gitRunCommand(cmdLine,auto statusWID,stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(statusWID.wid(),"getMultiFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
      if ( status || (length(stdErrData)>1 && statusWID.wid().p_Noflines==0) ) {
         status = SVC_COULD_NOT_GET_FILE_STATUS;
         _message_box(get_message(status,stdErrData));
         statusWID.close();
         return status;
      }
      origWID := p_window_id;
      p_window_id = statusWID.wid();

      _maybe_append(localRootPath,FILESEP);
      top();up();
      while ( !down() ) {
         get_line(auto line);
         if ( line=='' ) break;
         SVC_UPDATE_INFO * pCurFileInfo = &fileStatusList[fileStatusList._length()];
         curName := localRootPath:+substr(line,4);
         pCurFileInfo->filename = stranslate(curName,FILESEP,'/');

         pCurFileInfo->status = getStatusFromOutput(line);
      }
      p_window_id = origWID;

      statusWID.close();

      return status;
   }

   private SVCFileStatus getStatusFromOutput(_str line) {
      int status = 0;
      switch ( substr(line,1,1) ) {
      case 'A':
         status|=SVC_STATUS_SCHEDULED_FOR_ADDITION;break;
      case 'D':
         status|=SVC_STATUS_SCHEDULED_FOR_DELETION;break;
      }
      switch ( substr(line,2,1) ) {
      case 'M':
         status|=SVC_STATUS_MODIFIED;break;
      case '!':
         status|=SVC_STATUS_IGNORED;break;
      case '?':
         status|=SVC_STATUS_NOT_CONTROLED;break;
      case 'C':
         // Copied in index, don't think we need to support this
         status|=SVC_STATUS_COPIED_IN_INDEX;break;
      case 'U':
         // Copied in index, don't think we need to support this
         status|=SVC_STATUS_UNMERGED;break;
      }
      return status;
   }

   _str getSystemNameCaption() {
      return "git";
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

      origPath := getcwd();
      do {
         len := projPaths._length();
         for ( i:=0;i<len;++i ) {
            curPath := projPaths[i];
            chdir(curPath,1);
            topGitPath := localRootPath();
            if ( topGitPath=="" || (isinteger(topGitPath) && topGitPath<0) ) {
               projPaths._deleteel(i);
               --i;--len;
            } else if ( topGitPath!="" && !pathsSoFar._indexin(topGitPath) ) {
               pathsToUpdate[pathsToUpdate._length()] = topGitPath;
               pathsSoFar:[topGitPath] = "";
            }
         }
      } while (false);
      chdir(origPath,1);

      // First copy to the output, then sort as filenames
      pathsToUpdate = projPaths;
      pathsToUpdate._sort('f'_fpos_case);

      len := pathsToUpdate._length();
      for ( i:=0;i+1<len;++i ) {
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
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      origPath := getcwd();
      chdir(_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" --no-pager log -1 ":+maybe_quote_filename(_strip_filename(localFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getCurRevision cmdLine");
      GitTempWID historyOutputWID;
      status = gitRunCommand(cmdLine,historyOutputWID,auto stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(historyOutputWID.wid(),"getCurRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurRevision stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.wid().p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID.wid();
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      get_line(auto curLine);
      parse curLine with "commit " curRevision;
      p_window_id = origWID;
      historyOutputWID.close();
      return 0;
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

      status = gitRunCommand(maybe_quote_filename(exeStr)" paths default",auto graphWID,auto stdErrData);
      maybeOutputWIDToLog(graphWID.wid(),"getLocalFileURL stdout");
      maybeOutputStringToLog(stdErrData,"getLocalFileURL stderr");
      if ( status ) return status;

      p_window_id = graphWID.wid();
      top();
      get_line(URL);
      p_window_id = origWID;
      graphWID.close();
      return status;
   }

   int getCurLocalRevision(_str localFilename,_str &curRevision,boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      origPath := getcwd();
      chdir(_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" --no-pager log -1 ":+maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getCurLocalRevision cmdLine");
      GitTempWID historyOutputWID;
      status = gitRunCommand(cmdLine,historyOutputWID,auto stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(historyOutputWID.wid(),"getCurLocalRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurLocalRevision stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.wid().p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID.wid();
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      get_line(auto curLine);
      parse curLine with "commit " curRevision;
      p_window_id = origWID;
      historyOutputWID.close();
      return 0;
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

      cmdLine := maybe_quote_filename(exeStr)" push ";
      maybeOutputStrToLog(cmdLine,"pushToRepository cmdLine");

      // In this one case we pass "" to shell options because this command can
      // prompt so we want the console to be visible

      status = gitRunCommand(cmdLine,auto commitOutputWID,auto stdErrData,"");
      maybeOutputStringToLog(stdErrData,"pushToRepository cmdLine="cmdLine);
      maybeOutputWIDToLog(commitOutputWID.wid(),"pushToRepository stdout");
      maybeOutputStringToLog(stdErrData,"pushToRepository stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.wid().p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_PUSH_TO_REPOSITORY,stdErrData));
         return SVC_COULD_NOT_PUSH_TO_REPOSITORY;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID.wid());
      commitOutputWID.close();

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
      cmdLine := maybe_quote_filename(exeStr)" pull ";
      maybeOutputStrToLog(cmdLine,"pullFromRepository cmdLine");
      status = gitRunCommand(cmdLine,auto commitOutputWID,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"pullFromRepository cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID.wid(),"pullFromRepository stdout");
      maybeOutputStringToLog(stdErrData,"pullFromRepository stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.wid().p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_PULL_FROM_REPOSITORY,stdErrData));
         return SVC_COULD_NOT_PULL_FROM_REPOSITORY;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID.wid());
      commitOutputWID.close();

      return 0;
   }

   _str localRootPath() {
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      cmdLine := maybe_quote_filename(exeStr)" rev-parse --show-toplevel ";
      maybeOutputStrToLog(cmdLine,"localRootPath cmdLine");
      status = gitRunCommand(cmdLine,auto commitOutputWID,auto stdErrData);
      maybeOutputWIDToLog(commitOutputWID.wid(),"localRootPath stdout");
      maybeOutputStringToLog(stdErrData,"localRootPath stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.wid().p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
//         _message_box(get_message(SVC_COULD_NOT_PULL_FROM_REPOSITORY,stdErrData));
         return SVC_COULD_NOT_PULL_FROM_REPOSITORY;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID.wid());
      commitOutputWID.wid().top();
      commitOutputWID.wid().get_line(auto localRootPath);
      commitOutputWID.close();

      localRootPath = stranslate(localRootPath,FILESEP,'/');
      _maybe_append_filesep(localRootPath);
      return localRootPath;
   }
   int getNumVersions(_str localFilename) {
      enumerateVersions(localFilename,auto versions);
      return versions._length();
   }
   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      origPath := getcwd();
      chdir(_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" --no-pager log ":+maybe_quote_filename(_strip_filename(localFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getHistoryInformationForCurrentBranch cmdLine");
      status = gitRunCommand(cmdLine,auto historyOutputWID,auto stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(historyOutputWID.wid(),"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.wid().p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID.wid();
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      revisionCaption := "";
      for (;;) {
         get_line(auto curLine);
         parse curLine with "commit " auto revision;
         if ( down() ) break;
         get_line(curLine);

         // If a merge was inserted, skip over it.  Doesn't help for our history
         // info
         if (pos("Merge:",curLine)==1) {
            if ( down() ) break;
            get_line(curLine);
         }
         parse curLine with "Author: " auto author;
         if ( down() ) break;
         get_line(curLine);
         parse curLine with "Date:   " auto date;
         if ( down() ) break;
         if ( down() ) break;
         comment := "";
         for (;;) {
            get_line(curLine);
            if ( curLine=="" ) break;
            if ( comment==null || comment == "" ) {
               comment = curLine;
               revisionCaption = comment;
            } else {
               comment = comment"\n"curLine;
            }
            if ( down() ) break;
         }
//         curIndex = addHistoryItem(curIndex,addFlags,historyInfo,false,_pic_file,revision,author,date,comment,"",revisionCaption);
//         ARRAY_APPEND(versions,revision);
         versions._insertel(revision,0);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
         if ( down() ) break;
      }
      p_window_id = origWID;

      historyOutputWID.close();

      return 0;
   }
};
