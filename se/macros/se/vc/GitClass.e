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
#include "ftp.sh"
#require "sc/lang/String.e"
#require "se/datetime/DateTime.e"
#require "se/vc/IVersionControl.e"
#require "se/vc/QueuedVCCommand.e"
#require "se/vc/QueuedVCCommandManager.e"
#require "se/vc/SubversionBuildFile.e"
#require "se/vc/VCBaseRevisionItem.e"
#require "se/vc/VCBranch.e"
#require "se/vc/VCCacheManager.e"
#require "se/vc/VCLabel.e"
#require "se/vc/VCRepositoryCache.e"
#require "se/vc/VCRevision.e"
#require "se/vc/GitBuildFile.e"
#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#import "main.e"
#import "saveload.e"
#import "sellist.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "svchistory.e"
#import "toast.e"
#import "vc.e"
#import "wkspace.e"
#import "git.e"
#endregion Imports

using sc.lang.String;
using se.datetime.DateTime;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

#if 0 //12:04pm 10/17/2018
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
#endif

class Git : IVersionControl {

   private int gitRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0);
   void maybeOutputStrToLog(_str stdErrData,_str label);
   void maybeOutputWIDToLog(int WID,_str label);
   void maybeOutputStringToLog(String stdErrData,_str label);
   private SVCFileStatus getStatusFromOutput(_str line);
   int addFilesToCommit(STRARRAY &localFilenames,int startIndex=0);
   private bool isChildDirectory(_str curPath, STRHASHTAB &foundDiretoriesTable);

   private bool m_debug = false;
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
      m_captionTable[SVC_COMMAND_SYMBOL_QUERY]  = "Find symbol changes";
      m_captionTable[SVC_COMMAND_STASH]  = "&Stash";
      m_captionTable[SVC_COMMAND_STASH_POP]  = "Stash &Pop";
      m_captionTable[SVC_COMMAND_SWITCH]  = "Checkou&t";
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
      deferedInit();
      exeStr = _GitGetExePath();
      return 0;
   }

   int diffLocalFile(_str localFilename,_str version="",int options=0, bool modal=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      versionSpec := "";
      if ( version!="" ) {
         versionSpec = version' ';
      }
      origPath := getcwd();

      status = getFile(localFilename,version,auto originalFileWID=0);
      if (status) return status;
      getRemoteFilename(localFilename,auto remoteFilename="");

      modalOption := modal?" -modal ":"";

      if ( remoteFilename=="" ) {
         diff(modalOption' -viewid2 -r2 -internalCloseBuffer2 '_maybe_quote_filename(localFilename)' 'originalFileWID);
      } else {
         diff(modalOption' -viewid2 -r2 -internalCloseBuffer2 -file2title '_maybe_quote_filename(remoteFilename)' '_maybe_quote_filename(localFilename)' 'originalFileWID);
      }

      // Don't have to delete originalFileWID because we use the 
      // internalCloseBuffer2 option.  This will close the buffer when the diff
      // dialog closes

      return 0;
   }

   private bool hasBasicChallengeError(_str buf) {
      p := pos("authorization failed: Could not authenticate to server: rejected Basic challenge",buf,1,'i');
      if ( p ) {
         return true;
      }
      return false;
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

   private int gitRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0) {
      deferedInit();
      origWID := _create_temp_view(stdOutWID);
      p_window_id = origWID;
      status := 0;
      int process_stdout_pipe,process_stdin_pipe,process_stderr_pipe;
      origShell := get_env("SHELL");
      set_env("SHELL","/bin/sh");
      int process_handle=_PipeProcess(command,process_stdout_pipe,process_stdin_pipe,process_stderr_pipe,'H');
      set_env("SHELL",origShell);

      oldDisplay := get_env("DISPLAY");
      if ( oldDisplay=="" ) {
         set_env("DISPLAY",":0.0");
      }

      _str askpass_path=editor_name('P'):+"vs-ssh-askpass":+EXTENSION_EXE;
      old_ssh_askpass := get_env("SSH_ASKPASS");
      set_env("SSH_ASKPASS",askpass_path);   

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
            if (_isWindows()) {
               _PipeWrite(process_stdin_pipe,"\x1a");
            }
            p_window_id = origWID;
         }
      }
      for (i:=0;;++i) {
         buf1 := "";
         buf2 := "";
         _PipeRead(process_stdout_pipe,buf1,0,1);
         if ( length(buf1) ) {
            _PipeRead(process_stdout_pipe,buf1,length(buf1),0);
            stdOutWID._insert_text(buf1,true);
            len := stdOutWID._line_length(true);
            len=stdOutWID._text_colc(len+1,'I');
            stdOutWID.bottom();
            stdOutWID.p_col=len;
         }
         buf2='';
         _PipeRead(process_stderr_pipe,buf2,0,1);
         if ( length(buf2) ) {
            _PipeRead(process_stderr_pipe,buf2,length(buf2),0);
            if ( hasBasicChallengeError(buf2) ) {
               getCommandLineWithUserNameAndPwd(command,auto newCommand="");
               if ( newCommand !="") {
                  _PipeCloseProcess(process_handle);
                  //say("subversionRunCommand: retrying with username and pass");
                  return gitRunCommand(newCommand,stdOutWID,stdErrData,dataToWriteToStdinWID);
               }
            }
            newLen := stdErrData.getLength()+length(buf2);
            if ( newLen>stdErrData.getCapacity() ) {
               stdErrData.setCapacity(stdErrData.getLength()+length(buf2));
            }
            stdErrData.append(buf2);
         }
         int ppe=_PipeIsProcessExited(process_handle);
         if ( ppe && length(buf1)==0 && length(buf2)==0 && _PipeIsReadable(process_stdout_pipe)<=0 ) {
            break;
         }
         // no data yet, don't spin and hog CPU
         if (!ppe && length(buf1)==0 && length(buf2)==0) {
            delay(1);
         }
      }

      set_env("DISPLAY",oldDisplay);
      set_env("SSH_ASKPASS",old_ssh_askpass);

      _PipeCloseProcess(process_handle);
      //say("subversionRunCommand: DONE, time="_time());
      return status;
   }

   private _str getPullOptionsString(int flags) {
      strOptions := "";
      if ( flags&SVC_PULL_REBASE ) {
         strOptions :+= " --rebase ";
      }
      if ( flags&SVC_PULL_NOCOMMIT ) {
         strOptions :+= " --no-commit ";
      }
      if ( flags&SVC_PULL_AUTOSTASH ) {
         strOptions :+= " --auto-stash ";
      }
      return strOptions;
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

   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0,_str branchName="") {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      status = _GitGetHistoryInfo(localFilename,exeStr,historyInfo,branchName,(options&SVC_HISTORY_LAST_ENTRY_ONLY),(def_git_flags&GIT_FLAG_FOLLOW_HISTORY),(options&SVC_HISTORY_INCLUDE_WORKING_FILE));

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
      _maybe_strip(URL, '/');
      origPath := getcwd();
      status = chdir(URL,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",URL));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" log -p --name-only --since "dateBack.year()'-'dateBack.month()'-'dateBack.day();
      maybeOutputStrToLog(cmdLine,"getRepositoryInformation cmdLine");
      logOutputWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,logOutputWID,stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(logOutputWID,"getRepositoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getRepositoryInformation stderr");
      if ( status || (length(stdErrData)>1 && logOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,URL,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      origWID := p_window_id;
      p_window_id = logOutputWID;
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
               comment :+= "\n"curLine;
            }
            if ( down() ) break;
         }
         affectedFiles := "";
         if ( getFiles ) {
            down();
            for (;;) {
               get_line(curLine);
               if ( curLine=="" ) break;
               affectedFiles :+= "<br>"curLine;
               if ( down() ) break;
            }
         }
         curIndex = addHistoryItem(curIndex,addFlags,historyInfo,false,_pic_file,revision,author,date,comment,affectedFiles,revisionCaption);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
         if ( down() ) break;
      }
      p_window_id = origWID;

      _delete_temp_view(logOutputWID);

      return status;
   }

   /**
    * @param localPath Directory or filename to get branchName for. 
    *                   If this is a directory, it must have a
    *                   trailing FILESEP
    * @param branchName name of branch currently checked out by 
    *                   <B>localPath</B>
    * 
    * @return int 0 and branchName if successful, 
    */
   int getLocalFileBranch(_str localPath,_str &branchName) {
      branchName = "";
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origPath := getcwd();
      curPath := _file_path(localPath);
      status = chdir(curPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",curPath));
         return status;
      }
      // 3/2/2020 - Don't use --show-current because some older versions of
      // git don't support it
#if 0 //8:31pm 3/2/2020
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager branch --show-current";
#else
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager branch";
#endif
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      maybeOutputStrToLog(getcwd(),"getFile getcwd()=");
      maybeOutputStrToLog(localPath,"getFile localFilename=");
      tempFileWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,tempFileWID,stdErrData);
      if ( status ) {
         _delete_temp_view(tempFileWID);
         chdir(origPath,1);
         return status;
      }
      tempFileWID.top();

      //  3/2/2020 - Don't use --show-current because some older versions of
      // git don't support it.  Have to find branch with the '*' and remove the
      // beginning
#if 0
      tempFileWID.get_line(branchName);
#else
      status = tempFileWID.search('^\* ','@ri');
      if ( !status ) {
         tempFileWID.get_line(branchName);
         branchName = substr(branchName,3);
      }
#endif
      _delete_temp_view(tempFileWID);
      chdir(origPath,1);
      return 0;
   }

   void getVersionNumberFromVersionCaption(_str revisionCaption,_str &versionNumber) {
      versionNumber = revisionCaption;
   }

   _str getBaseRevisionSpecialName() {
      return "";
   }
   _str getHeadRevisionSpecialName() {
      return "HEAD";
   }
   _str getPrevRevisionSpecialName() {
      return "";
   }

   int getFile(_str localFilename,_str version,int &fileWID,bool getIndexVersion=false) {
      fileWID = 0;
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      versionStr := "";
      if ( getIndexVersion ) {
         versionStr = ':';
      } else {
         if ( version!="" ) {
            versionStr = version':';
         } else {
            versionStr = 'HEAD:';
         }
      }
      gitFilename := "";
      if (pos(localRootPath(),localFilename)==1) {
         gitFilename = stranslate(substr(localFilename,length(localRootPath())+1),'/',FILESEP);
      } else {
         gitFilename = localFilename;
      }
      origDir := getcwd();
      curPath := _file_path(localFilename);
      status = chdir(curPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",curPath));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager show "_maybe_quote_filename(versionStr'./'_strip_filename(gitFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      maybeOutputStrToLog(getcwd(),"getFile getcwd()=");
      maybeOutputStrToLog(localFilename,"getFile localFilename=");
      tempFileWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,tempFileWID,stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(tempFileWID,"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( status || (length(stdErrData)>1 && tempFileWID.p_Noflines==0) ) {
         status = VSRC_SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
//         _message_box(get_message(status,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return status;
      }

      tempFile := mktemp();

      status = tempFileWID._save_file('+o '_maybe_quote_filename(tempFile));

      //_delete_temp_view(fileWID);
      _delete_temp_view(tempFileWID);
      p_window_id = origWID;

      // Use +L to be sure we can delete the file while it is open
      _str encoding_option=_load_option_encoding(localFilename);
      status = _open_temp_view(tempFile,fileWID,origWID,'+d 'def_load_options' 'encoding_option" +L");
      if ( status ) return status;
      status = delete_file(tempFile);
      langId := _Filename2LangId(localFilename);

      _SetEditorLanguage(langId);

      p_window_id = origWID;
      return status;
   }

   int getRemoteFilename(_str localFilename,_str &remoteFilename) {
      status := getExeStr(auto exeStr);
      deferedInit();

      // Have to be sure we're in the right path
      origDir := getcwd();
      path := _file_path(localFilename);
      status = chdir(path,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      remoteFilename = stranslate(substr(localFilename,length(localRootPath())+1),'/',FILESEP);
      chdir(origDir,1);
      return 0;
   }

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0,bool checkForUpdates=true) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      origPath := getcwd();
      rootPath := localRootPath();
      if (rootPath=="") {
         _message_box(nls("Could not get local root path"));
         return VSRC_SVC_COULD_NOT_GET_INFO;
      }
      status = chdir(rootPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",rootPath));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" status --porcelain "_maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getFileStatus cmdLine");
      hgOutputWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,hgOutputWID,stdErrData);
      maybeOutputStringToLog(stdErrData,"getFileStatus cmdLine="cmdLine);
      chdir(origPath,1);
      SVCWriteWIDToOutputWindow(hgOutputWID);
      hgOutputWID.top();
      hgOutputWID.get_line(auto curLine);
      _delete_temp_view(hgOutputWID);
      fileStatus = getStatusFromOutput(curLine);

      return 0;
   }

   int getBranchNames(STRARRAY &branches,_str &currentBranch,_str path,bool forPushPullCombo=false,_str pullRepositoryName="",SVCBranchFlags options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      origWID := p_window_id;
      path = localRootPath(path);
      origPath := getcwd();
      if ( path!="" ) {
         status = chdir(path,1);
         if (status) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
            return status;
         }
      }
      cmdLine := _maybe_quote_filename(exeStr)" branch ";
      if ( options&SVC_BRANCH_ALL ) {
         cmdLine :+= "-a ";
      }
      maybeOutputStrToLog(cmdLine,"getFileStatus cmdLine");
      gitOutputWID := 0;
      String stdErrData("");
      maybeOutputStringToLog(stdErrData,"getFileStatus cmdLine="cmdLine);
      status = gitRunCommand(cmdLine,gitOutputWID,stdErrData);
      if ( status || (length(stdErrData)>1 && gitOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION,path,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      if ( path!="" ) chdir(origPath,1);
      //SVCWriteWIDToOutputWindow(gitOutputWID);
      p_window_id = gitOutputWID;
      top();up();
      STRHASHTAB addedBranches;
      while (!down()) {
         get_line(auto line);
         if (substr(line,1,1)=='*') {
            currentBranch = strip(substr(line,3));
         }
         branch := substr(line,2);
         if ( forPushPullCombo ) {
            parse branch with branch " -> " .;
            if ( endsWith(branch,"/HEAD") ) continue;
            if ( pos('/', branch) && !endsWith(branch,"/HEAD") ) {
               parse branch with "/" (pullRepositoryName) "/" branch;
               if ( branch == "" ) {
                  continue;
               }
            }
         }
         branch = strip(branch);
         if ( addedBranches:[branch]==null && branch!="" ) {
            branches :+= branch;
            addedBranches:[branch] = "";
         }
      }

      _delete_temp_view(gitOutputWID);
      p_window_id = origWID;
      status = 0;
      if (branches._length()==0) {
         status = VSRC_SVC_COULD_NOT_GET_INFO;
      }
      return status;
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
      cmdLine := _maybe_quote_filename(exeStr)" update ";
      maybeOutputStrToLog(cmdLine,"updateFiles cmdLine");
      status = gitRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      maybeOutputStringToLog(stdErrData,"updateFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"updateFiles stdout");
      maybeOutputStringToLog(stdErrData,"updateFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(VSRC_SVC_COULD_NOT_UPDATE_FILE,"update",localFilenames[0],stdErrData));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
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
         status = chdir(curPath,1);
         if (status) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",curPath));
            return status;
         }
         status = getCurRevision(curFilename,auto curRevision="");
         if ( status ) {
            chdir(origPath,1);
            return status;
         }
         cmdLine := _maybe_quote_filename(exeStr)" checkout  "curRevision' '_maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"revertFiles cmdLine");
         revertOutputWID := 0;
         String stdErrData("");
         status = gitRunCommand(cmdLine,revertOutputWID,stdErrData);
         maybeOutputWIDToLog(revertOutputWID,"revertFiles stdout");
         maybeOutputStringToLog(stdErrData,"revertFiles stderr");
         _delete_temp_view(revertOutputWID);
      }
      p_window_id = origWID;
      chdir(origPath,1);

      _reload_vc_buffers(localFilenames);
      _retag_vc_buffers(localFilenames);

      return 0;
   }

   int revertFile(_str localFilename,int options=0) {
      // Call deferedInit() in revertFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := revertFiles(tempFilenames,options);
      return status;
   }

   int getComment(_str &commentFilename,_str &tag,_str fileBeingCheckedIn,bool showApplyToAll=true,
                  bool &applyToAll=false,bool showTag=true,bool showAuthor=false,_str &author='') {
      if ( commentFilename=="" ) commentFilename = mktemp();
      return _SVCGetComment(commentFilename,tag,fileBeingCheckedIn,showApplyToAll,applyToAll,showTag,showAuthor,author);
   }

   int commitFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      len := localFilenames._length();
      showApplyToAll := len>1;
      for ( i:=0;i<len;++i ) {

         status = getComment(auto commentFilename="","",localFilenames[i],showApplyToAll,auto applyToAll=false,false);
         if ( status ) {
            return status;
         }

         commitOutputWID := 0;
         haveRootPath := false;
         if ( applyToAll ) {
            origDir := getcwd();
            numFiles := localFilenames._length();
            curPath := _file_path(localFilenames[i]);
            status = chdir(curPath,1);
            if (status) {
               _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",curPath));
               return status;
            }
            if ( numFiles>1 ) {
               status = addFilesToCommit(localFilenames, i);
               if ( status ) {
                  chdir(origDir,1);
                  return status;
               }
            }
            cmdLine := _maybe_quote_filename(exeStr)" commit ";
            if ( numFiles==1 ) {
               cmdLine :+= _maybe_quote_filename(localFilenames[0]);
            } else if ( haveRootPath ) {
               cmdLine :+= " . ";
            }
            cmdLine :+= " -F "_maybe_quote_filename(commentFilename);
            maybeOutputStrToLog(cmdLine,"commitFiles 10 cmdLine");
            String stdErrData("");
            status = gitRunCommand(cmdLine,commitOutputWID,stdErrData);
            chdir(origDir,1);
            maybeOutputStrToLog(cmdLine,"commitFiles cmdLine");
            maybeOutputStrToLog(getcwd(),"commitFiles getcwd");
            maybeOutputWIDToLog(commitOutputWID,"commitFiles 10 stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles 10 stderr");
            delete_file(commentFilename);
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(VSRC_SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return VSRC_SVC_COULD_NOT_UPDATE_FILE;
            }
            SVCWriteWIDToOutputWindow(commitOutputWID);
            _delete_temp_view(commitOutputWID);
            break;
         } else {
            STRARRAY temp;
            temp[0] = localFilenames[i];
            origDir := getcwd();
            status = chdir(_file_path(temp[0]),1);
            if (status) {
               _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",temp[0]));
               return status;
            }
            addFilesToCommit(temp);
            cmdLine := _maybe_quote_filename(exeStr)" commit ";
            if ( haveRootPath ) {
               cmdLine :+= " . ";
            }
            cmdLine :+= " -F "_maybe_quote_filename(commentFilename);
            maybeOutputStrToLog(cmdLine,"commitFiles 20 cmdLine="cmdLine);
            String stdErrData("");
            status = gitRunCommand(cmdLine,commitOutputWID,stdErrData);
            chdir(origDir,1);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles 20 stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles 20 stderr");
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(VSRC_SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return VSRC_SVC_COULD_NOT_UPDATE_FILE;
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
            // Skip adding this file
            continue;

            //_message_box(get_message(FILE_NOT_FOUND_RC,curFilename));
            //return FILE_NOT_FOUND_RC;
         }
         cmdLine := _maybe_quote_filename(exeStr)" add ":+_maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"addFilesToCommit cmdLine");
         addOutputWID := 0;
         String stdErrData("");
         status = gitRunCommand(cmdLine,addOutputWID,stdErrData);
         maybeOutputWIDToLog(addOutputWID,"addFilesToCommit stdout");
         maybeOutputStringToLog(stdErrData,"addFilesToCommit stderr");
         if ( status || (length(stdErrData)>1 && addOutputWID.p_Noflines==0) ) {
            _message_box(get_message(VSRC_SVC_COULD_NOT_ADD_FILE,"add",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            return VSRC_SVC_COULD_NOT_ADD_FILE;
         }
         _delete_temp_view(addOutputWID);
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

   int checkout(_str URLPath,_str localPath,int options=0,_str revision="") {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      mou_hour_glass(true);
      status = 0;
      checkoutOutputWID := 0;

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
         SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY|
         SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY|
         SVC_COMMAND_AVAILABLE_UPDATE|
         SVC_COMMAND_AVAILABLE_HISTORY_DIFF|
         SVC_COMMAND_AVAILABLE_SYMBOL_QUERY|
         SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY|
         SVC_COMMAND_AVAILABLE_STASH|
         SVC_COMMAND_AVAILABLE_STASH_POP|
         SVC_COMMAND_AVAILABLE_SWITCH;
   }

   _str getCaptionForCommand(SVCCommands command,bool withHotkey=true,bool mixedCaseCaption=true) {
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
         path := _file_path(localFilenames[i]);
         status = chdir(path,1);
         if (status) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
            return status;
         }
         cmdLine := _maybe_quote_filename(exeStr)" add ":+_maybe_quote_filename(curFilename);
         maybeOutputStrToLog(cmdLine,"addFiles cmdLine");
         addOutputWID := 0;
         String stdErrData("");
         status = gitRunCommand(cmdLine,addOutputWID,stdErrData);
         chdir(origDir,1);
         maybeOutputWIDToLog(addOutputWID,"addFiles stdout");
         maybeOutputStringToLog(stdErrData,"addFiles stderr");
         if ( status || (length(stdErrData)>1 && addOutputWID.p_Noflines==0) ) {
            _message_box(get_message(VSRC_SVC_COULD_NOT_ADD_FILE,"add",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            return VSRC_SVC_COULD_NOT_ADD_FILE;
         }
         _delete_temp_view(addOutputWID);
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
         status = chdir(curPath,1);
         if (status) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",curPath));
            return status;
         }
         maybeOutputStrToLog(getcwd(),"removeFiles getcwd()");
         cmdLine := _maybe_quote_filename(exeStr)" rm ":+_maybe_quote_filename(_strip_filename(curFilename,'P'));
         maybeOutputStrToLog(cmdLine,"removeFiles cmdLine");
         removeOutputWID := 0;
         String stdErrData("");
         status = gitRunCommand(cmdLine,removeOutputWID,stdErrData);
         maybeOutputWIDToLog(removeOutputWID,"removeFiles stdout");
         maybeOutputStringToLog(stdErrData,"removeFiles stderr");
         if ( status || (length(stdErrData)>1 && removeOutputWID.p_Noflines==0) ) {
            _message_box(get_message(VSRC_SVC_COULD_NOT_ADD_FILE,"rm",curFilename,stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            chdir(origPath,1);
            return VSRC_SVC_COULD_NOT_ADD_FILE;
         }
         SVCWriteWIDToOutputWindow(removeOutputWID);
         _delete_temp_view(removeOutputWID);
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
                          bool recursive=true,int options=0,_str &remoteURL="") {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localPath) && !isdirectory(localPath) ) {
//         _message_box(get_message(FILE_NOT_FOUND_RC,localPath));
         return FILE_NOT_FOUND_RC;
      }
      remoteWID := 0;
      String stdErrData("");
      origPath := getcwd();
      status = chdir(localPath,1);
      if (status) return status;
      status = gitRunCommand(_maybe_quote_filename(exeStr)' remote  -v',remoteWID,stdErrData);
      remoteWID.top();
      remoteWID.get_line(remoteURL);
      _delete_temp_view(remoteWID);
      if ( status || stdErrData.strPos("Not a git repository",1)) {
         chdir(origPath,1);
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_INFO,localPath));
         return VSRC_SVC_COULD_NOT_LIST_URL;
      }

      parse remoteURL with auto branch remoteURL ' (fetch)';

      recurseOption := recursive?"":"--subrepos";

      local_root_path := localRootPath();
      cmdLine := _maybe_quote_filename(exeStr)' status --porcelain .';
      maybeOutputStrToLog(cmdLine,"getMultiFileStatus cmdLine");
      statusWID := 0;
      status = gitRunCommand(cmdLine,statusWID,stdErrData);
      chdir(origPath,1);
      if (status) return status;
      maybeOutputWIDToLog(statusWID,"getMultiFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
      if ( status || (length(stdErrData)>1 && statusWID.p_Noflines==0) ) {
         status = VSRC_SVC_COULD_NOT_GET_FILE_STATUS;
         _message_box(get_message(status,stdErrData));
         _delete_temp_view(statusWID);
         return status;
      }
      origWID := p_window_id;
      p_window_id = statusWID;

      _maybe_append(local_root_path,FILESEP);
      top();up();
      while ( !down() ) {
         get_line(auto line);
         if ( line=='' ) break;
         SVC_UPDATE_INFO * pCurFileInfo = &fileStatusList[fileStatusList._length()];
         endPath := strip(substr(line,4),'B','"');
         curName := local_root_path:+endPath;
         pCurFileInfo->filename = stranslate(curName,FILESEP,'/');
         if ( pos(' -> ',pCurFileInfo->filename) ) {
            if ( substr(line,1,1)=='R' ) {
               parse pCurFileInfo->filename with pCurFileInfo->filename " -> " auto addedFilename;
               pCurFileInfo->status = getStatusFromOutput('R'substr(line,2,1)' 'pCurFileInfo->filename);

               SVC_UPDATE_INFO * pAddedFileInfo = &fileStatusList[fileStatusList._length()];
               addedFilename = local_root_path:+addedFilename;
               pAddedFileInfo->filename = stranslate(addedFilename,FILESEP,'/');
               pAddedFileInfo->status = SVC_STATUS_SCHEDULED_FOR_ADDITION;
            }
         } else {
            pCurFileInfo->status = getStatusFromOutput(line);
         }
      }
      p_window_id = origWID;

      _delete_temp_view(statusWID);

      return status;
   }

   private SVCFileStatus getStatusFromOutput(_str line) {
      status := SVC_STATUS_NONE;
      switch ( substr(line,1,1) ) {
      case 'A':
         status|=SVC_STATUS_SCHEDULED_FOR_ADDITION;break;
      case 'D':
         status|=SVC_STATUS_SCHEDULED_FOR_DELETION;break;
      case 'R':
         status|=SVC_STATUS_SCHEDULED_FOR_DELETION;break;
      case 'M':
         status|=SVC_STATUS_UPDATED_IN_INDEX;break;
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

   bool listsFilesInUncontrolledDirectories() {
      return false;
   }

   _str getSystemNameCaption() {
      return "git";
   }

   _str getSystemSpecificInfo(_str fieldName) {
      return "";
   }

   _str getFixedUpdatePath(bool forceCalculation=false) {
      return "";
   }

   bool hotkeyUsed(_str hotkeyLetter,bool onMenu=true) {
      foreach ( auto curCap in m_captionTable ) {
         if ( pos('&'hotkeyLetter,curCap,1,'i') ) {
            return true;
         }
      }
      return false;
   }

   private bool isChildDirectory(_str curPath, STRHASHTAB &foundDiretoriesTable) {
      foreach (auto curParentPath => . in foundDiretoriesTable) {
         if ( _file_eq(curParentPath,substr(curPath,1,length(curParentPath))) ) {
            return true;
         }
      }
      return false;
   }

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]) {
      _str pathsSoFar:[];

      origPath := getcwd();
      do {
         len := projPaths._length();
         for ( i:=0;i<len;++i ) {
            curPath := projPaths[i];
            status := chdir(curPath,1);
            if (status) continue;

            if ( isChildDirectory(curPath,pathsSoFar) ){
               continue;
            }

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
   }

   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",bool quiet=false) {
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
      path := _file_path(localFilename);
      status = chdir(path,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager log -1 ":+_maybe_quote_filename(_strip_filename(localFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getCurRevision cmdLine");
      historyOutputWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,historyOutputWID,stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(historyOutputWID,"getCurRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurRevision stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      get_line(auto curLine);
      parse curLine with "commit " curRevision;
      p_window_id = origWID;
      _delete_temp_view(historyOutputWID);
      return 0;
   }

   SVCSystemSpecificFlags getSystemSpecificFlags() {
      return SVC_UPDATE_PATHS_RECURSIVE|SVC_HISTORY_DIALOG_ALLOWS_COLUMNS;
   }

   int getLocalFileURL(_str localFilename,_str &URL) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      graphWID := 0;
      String stdErrData("");
      status = gitRunCommand(_maybe_quote_filename(exeStr)" paths default",graphWID,stdErrData);
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

   int getCurLocalRevision(_str localFilename,_str &curRevision,bool quiet=false) {
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
      path := _file_path(localFilename);
      status = chdir(path,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager log -1 ":+_maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getCurLocalRevision cmdLine");
      historyOutputWID := 0;
      String stdErrData("");
      status = gitRunCommand(cmdLine,historyOutputWID,stdErrData);
      chdir(origPath,1);
      maybeOutputWIDToLog(historyOutputWID,"getCurLocalRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurLocalRevision stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      top();
      curIndex := 0;
      addFlags := ADDFLAGS_ASCHILD;
      get_line(auto curLine);
      parse curLine with "commit " curRevision;
      p_window_id = origWID;
      _delete_temp_view(historyOutputWID);
      return 0;
   }

   int pushToRepository(_str path="",_str branch="",_str remote="",int flags=0) {
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      cmdLine := _maybe_quote_filename(exeStr)" push";
      maybeOutputStrToLog(cmdLine,"pushToRepository cmdLine");

      // In this one case we pass "" to shell options because this command can
      // prompt so we want the console to be visible

      commitOutputWID := 0;
      String stdErrData("");
      origPath := getcwd();
      if ( path!="" ) {
         status = chdir(path,1);
         if (status) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
            return status;
         }
      }

      oldDisplay := get_env("DISPLAY");
      if ( oldDisplay=="" ) {
         set_env("DISPLAY",":0.0");
      }

      askpass_pass := editor_name('P'):+VS_SSH_ASKPASS_COMMAND;
      old_ssh_askpass := get_env("SSH_ASKPASS");
      set_env("SSH_ASKPASS",askpass_pass);

      optionsString := "";
      if ( flags&SVC_PUSH_ALL ) {
         optionsString :+= " --all ";
      }
      if ( flags&SVC_PUSH_TAGS ) {
         optionsString :+= " --tags ";
      }
      if ( flags&SVC_PUSH_FOLLOW_TAGS ) {
         optionsString :+= " --follow-tags ";
      }
      if ( flags&SVC_PUSH_SET_UPSTREAM ) {
         optionsString :+= " --set-upstream ";
      }
      if ( flags&SVC_PUSH_VERBOSE ) {
         optionsString :+= " --verbose ";
      }
      if ( flags&SVC_PUSH_SPECIFY_BRANCH ) {
         optionsString :+= " ";
         optionsString :+= remote;
         if (last_char(remote) != '/')
            optionsString :+= " ";
         optionsString :+= branch;
      }
      cmdLine :+= optionsString;
      //say('pushToRepository cmdLine='cmdLine);
      status = gitRunCommand(cmdLine,commitOutputWID,stdErrData);

      if ( oldDisplay=="" ) {
         // Windows, so DISPLAY env var is usually not set
         set_env("DISPLAY",":0.0");
      }
      if (old_ssh_askpass != "") {
         set_env("SSH_ASKPASS",old_ssh_askpass);   
      }

      status = chdir(origPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      p := stdErrData.strPos(VS_SSH_ASKPASS_PROMPT,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_PROMPT),'');
      }
      p = stdErrData.strPos(VS_SSH_ASKPASS_DONE,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_DONE),'');
      }
      p = stdErrData.strPos(VS_SSH_ASKPASS_CANCELLED,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_CANCELLED),'');
      }

      // For push always show output
      SVCWriteToOutputWindow(stdErrData.get());
      if ( stdErrData.strPos("Error",1,'i') ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_PUSH_TO_REPOSITORY,"Git:":+stdErrData));
      }
      if ( commitOutputWID ) {
         SVCWriteWIDToOutputWindow(commitOutputWID);
         _delete_temp_view(commitOutputWID);
      }

      return 0;
   }

   int getPushPullInfo(_str &branchName, _str &pushRepositoryName, _str &pullRepositoryName, _str &path="") {
      origPath := getcwd();
      if ( path!="" ) chdir(path,1);
      dontShowAgain := _param1;
      localRoot := localRootPath(path);
      path = localRoot;
      chdir(localRoot,1);
      deferedInit();
      status := getExeStr(auto exeStr);
      cmdLine := _maybe_quote_filename(exeStr)" --no-pager branch";
      maybeOutputStrToLog(cmdLine,"getPushPullInfo cmdLine");
      String stdErrData("");

      pushPullBranch := "";
      status = gitRunCommand(cmdLine,auto branchOutputWID=0,stdErrData);
      if ( status ) {
         chdir(origPath,1);
         return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
      }
      origWID := p_window_id;
      p_window_id = branchOutputWID;

      top();up();
      status = search('^\* ','@r');
      if ( status ) {
         p_window_id = origWID;
         chdir(origPath,1);
         return status;
      }
      get_line(auto line);
      branchName = substr(line,3);

      p_window_id = origWID;
      _delete_temp_view(branchOutputWID);

      cmdLine = _maybe_quote_filename(exeStr)" remote -v";
      maybeOutputStrToLog(cmdLine,"getPushPullInfo cmdLine");
      stdErrData.set("");

      pushPullBranch = "";
      status = gitRunCommand(cmdLine,auto remoteWID=0,stdErrData);
      if ( status ) {
         p_window_id = origWID;
         chdir(origPath,1);
         return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
      }
      origWID = p_window_id;
      p_window_id = remoteWID;
      top();up();

      status = search('^?@\t?@ \(fetch\)','@r');
      if ( status ) {
         p_window_id = origWID;
         chdir(origPath,1);
         return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
      }
      get_line(line);
      parse line with pullRepositoryName "\t" . ;
      top();up();

      status = search('^?@\t?@ \(push\)','@r');
      if ( status ) {
         p_window_id = origWID;
         chdir(origPath,1);
         return VSRC_SVC_COULD_NOT_GET_REMOTE_REPOSITORY_INFORMATION;
      }
      get_line(line);
      parse line with pushRepositoryName "\t" . ;

      p_window_id = origWID;
      _delete_temp_view(remoteWID);

      chdir(origPath,1);
      return status;
   }

   int pullFromRepository(_str path="",_str branch="",_str remote="",int flags=0) {
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      origPath := getcwd();
      if ( path!="" ) {
         status = chdir(path,1);
         if ( status ) {
            _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
            if (status) return status;
         }
      }

      optionsString := "";
      if ( flags&SVC_PULL_REBASE ) {
         optionsString = "--rebase";
      }
      if ( flags&SVC_PULL_NOCOMMIT ) {
         optionsString :+= " --no-commit";
      }
      if ( flags&SVC_PULL_AUTOSTASH ) {
         optionsString :+= " --autostash";
      }
      if ( flags&SVC_PULL_VERBOSE ) {
         optionsString :+= " --verbose";
      }
      if ( flags&SVC_PULL_SPECIFY_BRANCH ) {
         optionsString :+= " ";
         optionsString :+= remote;
         if (last_char(remote) != '/')
            optionsString :+= " ";
         optionsString :+= branch;
      }

      rootPath := localRootPath();
      status  = chdir(rootPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",rootPath));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" pull ";
      cmdLine :+= optionsString;
      maybeOutputStrToLog(cmdLine,"pullFromRepository cmdLine");
      commitOutputWID := 0;
      String stdErrData("");

      oldDisplay := get_env("DISPLAY");
      if ( oldDisplay=="" ) {
         set_env("DISPLAY",":0.0");
      }

      askpass_path := editor_name('P'):+VS_SSH_ASKPASS_COMMAND;
      old_ssh_askpass := get_env("SSH_ASKPASS");
      set_env("SSH_ASKPASS",askpass_path);

      //say('pullFromRepository cmdLine='cmdLine);
      status = gitRunCommand(cmdLine,commitOutputWID,stdErrData);

      if ( oldDisplay=="" ) {
         // Windows, so DISPLAY env var is usually not set
         set_env("DISPLAY");
      }
      if (old_ssh_askpass != "") {
         set_env("SSH_ASKPASS",old_ssh_askpass);   
      }

      maybeOutputStringToLog(stdErrData,"pullFromRepository cmdLine="cmdLine);
      if ( path!="" ) chdir(origPath,1);
      maybeOutputWIDToLog(commitOutputWID,"pullFromRepository stdout");
      maybeOutputStringToLog(stdErrData,"pullFromRepository stderr");


      p := stdErrData.strPos(VS_SSH_ASKPASS_PROMPT,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_PROMPT),'');
      }
      p = stdErrData.strPos(VS_SSH_ASKPASS_DONE,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_DONE),'');
      }
      p = stdErrData.strPos(VS_SSH_ASKPASS_CANCELLED,1);
      if ( p ) {
         stdErrData.replace(p, length(VS_SSH_ASKPASS_CANCELLED),'');
      }

      // For pull always show output
      SVCWriteToOutputWindow(stdErrData.get());
      if ( stdErrData.strPos("Error",1,'i') ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_PULL_FROM_REPOSITORY,"Git:":+stdErrData));
      }
      if ( commitOutputWID ) {
         SVCWriteWIDToOutputWindow(commitOutputWID);
         _delete_temp_view(commitOutputWID);
      }

      return 0;
   }

   _str localRootPath(_str path="") {
      // localFilenames doesn't matter.  Hg's update command does not take a 
      // path, filename, etc. It just updates everything to what was last 
      // pulled.
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      cmdLine := _maybe_quote_filename(exeStr)" rev-parse --show-toplevel "path;
      maybeOutputStrToLog(cmdLine,"localRootPath cmdLine");
      commitOutputWID := 0;
      String stdErrData("");
      origPath := getcwd();
      if ( path!="" ) chdir(path,1);
      status = gitRunCommand(cmdLine,commitOutputWID,stdErrData);
      if ( path!="" ) chdir(origPath,1);
      maybeOutputWIDToLog(commitOutputWID,"localRootPath stdout");
      maybeOutputStringToLog(stdErrData,"localRootPath stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         //SVCWriteToOutputWindow(stdErrData.get());
         return "";
      }
      commitOutputWID.top();
      commitOutputWID.get_line(auto local_root_path);
      _delete_temp_view(commitOutputWID);

      local_root_path = stranslate(local_root_path,FILESEP,'/');
      _maybe_append_filesep(local_root_path);
      return local_root_path;
   }

   int getNumVersions(_str localFilename) {
      enumerateVersions(localFilename,auto versions);
      return versions._length();
   }
   int enumerateVersions(_str localFilename,STRARRAY &versions,bool quiet=false,_str branchName="") {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localFilename));
         return FILE_NOT_FOUND_RC;
      }

      SVCHistoryInfo historyInfo[];
      status = _GitGetHistoryInfo(localFilename,exeStr,historyInfo,branchName,0,(def_git_flags&GIT_FLAG_FOLLOW_HISTORY),0);
      len := historyInfo._length();
      for (i:=0;i<len;++i) {
         ARRAY_APPEND(versions,historyInfo[i].revision);
      }

      return 0;
   }

   void beforeWriteState() {
   }

   void afterWriteState() {
   }
   _str getFilenameRelativeToBranch(_str localFilename) {
      return "";
   }
   int getRepositoryRoot(_str URL,_str &URLRoot="") {
      return 0;
   }

   int stash(_str path="",SVCStashFlags flags=0,STRARRAY &listOfStashes=null) {
      logOutputWID := 0;
      String stdErrData("");
      origPath := getcwd();
      status := chdir(path,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      status = getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
     pop := flags&SVC_STASH_POP;
     listStashes := flags&SVC_STASH_LIST;
      cmdLine := _maybe_quote_filename(exeStr)" stash ";
      if ( pop ) {
         cmdLine :+= "pop ";
      } else if ( flags&SVC_STASH_LIST ) {
         cmdLine :+= "list ";
      }
      status = gitRunCommand(cmdLine,logOutputWID,stdErrData);
      chdir(origPath,1);
      origWID := p_window_id;
      p_window_id = logOutputWID;
      if ( status || (length(stdErrData)>1 && logOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,path,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         _delete_temp_view(logOutputWID);
         p_window_id = origWID;
         return VSRC_SVC_FILE_NOT_FOUND_RC;
      }
      fileList := "";
      if ( listStashes ) {
         top();up();
         while ( !down() ) {
            get_line(auto line);
            if ( line!="" ) {
               listOfStashes :+= line;
            }
         }
      } else if ( p_Noflines>0 ) {
         top();up();
         for (;;) {
            status = search('^CONFLICT \(content\)\: ','@ri>');
            if ( status ) break;
            get_line(auto line);
            parse line with 'CONFLICT (content): Merge conflict in ' auto curFilename;
            if (curFilename!="") {
               fileList :+= _maybe_quote_filename(localRootPath():+curFilename)"\n";
            }
         }
      }
      p_window_id = origWID;
      if ( fileList!="" ) {
         _message_box(nls("Git stash pop caused the following conflicts:\n\n%s",fileList));
      }
      _delete_temp_view(logOutputWID);
      return 0;
   }

   int getStashList(STRARRAY &listOfStashes,_str path="",SVCStashFlags flags=0) {
      status := stash(path,SVC_STASH_LIST,listOfStashes);
      return status;
   }

   int switchBranches(_str branchName,_str localPath,SVCSwitchBranch options=0) {
      logOutputWID := 0;
      String stdErrData("");
      origPath := getcwd();
      status := chdir(localPath,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",localPath));
         return status;
      }
      status = getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" checkout ";
      if ( options&SVC_SWITCH_NEW_BRANCH ) {
         cmdLine :+= "-b ";
      }
      cmdLine :+= _maybe_quote_filename(branchName);
      status = gitRunCommand(cmdLine,logOutputWID,stdErrData);
      chdir(origPath,1);
      origWID := p_window_id;
      p_window_id = logOutputWID;
      if ( status || (length(stdErrData)>1 && logOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,localPath,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         _delete_temp_view(logOutputWID);
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      p_window_id = origWID;
      _delete_temp_view(logOutputWID);
      return 0;
   }

   int getBranchForCommit(_str commitVersion,_str &branchforCommit, _str path) {
      logOutputWID := 0;
      String stdErrData("");
      origPath := getcwd();
      status := chdir(path,1);
      if (status) {
         _message_box(get_message(VSBUILDRC_COULD_NOT_CHANGE_DIRECTORY_2ARG,"",path));
         return status;
      }
      status = getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      cmdLine := _maybe_quote_filename(exeStr)" branch -a --contains " commitVersion;
      status = gitRunCommand(cmdLine,logOutputWID,stdErrData);
      chdir(origPath,1);
      origWID := p_window_id;
      p_window_id = logOutputWID;
      if ( status || (length(stdErrData)>1 && logOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,path,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         _delete_temp_view(logOutputWID);
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      top();up();
      status = search('^(\+|\*)','@r');
      if ( !status ) {
         get_line(auto line);
         branchforCommit = substr(line,3);
      }
      p_window_id = origWID;
      _delete_temp_view(logOutputWID);
      return 0;
   }
};

