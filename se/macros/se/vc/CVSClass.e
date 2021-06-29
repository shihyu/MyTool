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
#require "sc/lang/String.e"
#require "se/datetime/DateTime.e"
//#require "se/vc/CVSBuildFile.e"
#require "se/vc/IVersionControl.e"
#require "se/vc/QueuedVCCommand.e"
#require "se/vc/VCBaseRevisionItem.e"
#require "se/vc/VCBranch.e"
#require "se/vc/VCCacheManager.e"
#require "se/vc/VCLabel.e"
#require "se/vc/VCRepositoryCache.e"
#require "se/vc/VCRevision.e"
#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#import "main.e"
#import "saveload.e"
#import "setupext.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "svchistory.e"
#import "toast.e"
#import "vc.e"
#import "wkspace.e"
#import "cvs.e"
#endregion Imports

using sc.lang.String;
using se.datetime.DateTime;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class CVS : IVersionControl {
   private bool m_debug = false;
   private _str m_captionTable[];
   private _str m_version = "";
   private int m_didDeferredInit = 0;

   CVS() {
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
      m_captionTable[SVC_COMMAND_SYMBOL_QUERY]  = "Find symbol changes";
   }

   ~CVS() {
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
      exeStr=_CVSGetExePath();
      return 0;
   }

   int diffLocalFile(_str localFilename,_str version="",int options=0,bool modal=false) {
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
         if ( _first_char(version)=='r' ) {
            versionSpec:+=' -'version;
         } else {
            versionSpec:+=' -r'version;
         }
      }
      origDir := getcwd();
      chdir(_file_path(localFilename),1);
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" diff "versionSpec' ':+_maybe_quote_filename(relative(localFilename));
      maybeOutputStrToLog(cmdLine,"diffLocalFile cmdLine");
      status = cvsRunCommand(cmdLine,auto scriptWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(scriptWID,"diffLocalFile stdout");
      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
      if ( status || (length(stdErrData)>1 && scriptWID.p_Noflines==0) ) {
         status = VSRC_SVC_COULD_NOT_COMPARE_FILE;
         _message_box(get_message(status,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return status;
      }
#if 0 //3:23pm 10/9/2014
      CVSBuildFile bf;
      originalFileWID := bf.buildOriginalFile(localFilename,scriptWID);
      if ( originalFileWID<=0 ) {
         return 1;
      }
      getRemoteFilenameFromDiffScript(scriptWID,auto remoteFilename="");

      _delete_temp_view(scriptWID);
#else
      status = getFile(localFilename,version,auto originalFileWID=0);
      originalFileWID.p_buf_name = "";
      if ( status ) return status;
#endif

      status = getRemoteFilename(localFilename,auto remoteFilename="");
      fileTitle := remoteFilename;
      if ( version!="" ) {
         fileTitle :+= '('version')';
      } else {
         fileTitle :+= '(HEAD)';
      }
      modalOption := modal?" -modal ":"";
      diff(modalOption' -bi2 -r2 -matchMode2 -file2title 'fileTitle' '_maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);

      _delete_temp_view(originalFileWID);

      return 0;
   }

   private int cvsRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0) {
      deferedInit();
      origWID := _create_temp_view(stdOutWID);
      p_window_id = origWID;
      status := 0;
      int process_stdout_pipe,process_stdin_pipe,process_stderr_pipe;
      origShell := get_env("SHELL");
      if ( _isUnix() ) {
         set_env("SHELL","/bin/sh");
      }
      int process_handle=_PipeProcess(command,process_stdout_pipe,process_stdin_pipe,process_stderr_pipe,'');
      set_env("SHELL",origShell);
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
            if ( hasBasicChallengeError(buf2) ) {
               getCommandLineWithUserNameAndPwd(command,auto newCommand="");
               if ( newCommand !="") {
                  return cvsRunCommand(newCommand,stdOutWID,stdErrData,dataToWriteToStdinWID);
               }
            }
            newLen := stdErrData.getLength()+length(buf2);
            if ( newLen>stdErrData.getCapacity() ) {
               stdErrData.setCapacity(stdErrData.getLength()+length(buf2));
            }
            stdErrData.append(buf2);
         }
         int ppe=_PipeIsProcessExited(process_handle);
         if ( ppe && buf1=='' && buf2=='' && _PipeIsReadable(process_stdout_pipe)<=0 ) {
            break;
         }
         // no data yet, don't spin and hog CPU
         if (!ppe && length(buf1)==0 && length(buf2)==0) {
            delay(1);
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

   private bool hasBasicChallengeError(_str buf) {
      p := pos("authorization failed: Could not authenticate to server: rejected Basic challenge",buf,1,'i');
      if ( p ) {
         return true;
      }
      return false;
   }

   const DASH_LINE= "----------------------------";
   const EQUALS_LINE77= "=============================================================================";
   const EQUALS_LINE67= "===================================================================";

   private void getSymbolicNames(STRHASHTAB &symbolicNames) {
      save_pos(auto p);
      top();up();
      status := search('^symbolic names\:','@ri');
      if ( status ) {
         return;
      }
      for (;;) {
         if ( down() ) break;
         get_line(auto line);
         if (substr(line,1,1)!="\t") break;
         parse line with "\t" auto name ':' auto version;
         symbolicNames:[strip(version)] = strip(name);
      }
      restore_pos(p);
   }

   // Add a 0 in the middle like the symbolic names have
   private _str getBranchNumber(_str branchNumber) {
      lp := lastpos('.',branchNumber);
      leftSide := "";
      rightSide := "";
      if (lp>1) {
         leftSide = substr(branchNumber,1,lp-1);
         rightSide = substr(branchNumber,lp+1);
         branchNumber = leftSide'.0.'rightSide;
      }
      return branchNumber;
   }

   private _str getBranchName(_str branchNumber,STRHASHTAB &symbolicNames) {
      branchNumber = getBranchNumber(branchNumber);
      if ( symbolicNames:[branchNumber]!=null ) {
         return symbolicNames:[branchNumber];
      }
      return '';
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

      origDir := getcwd();
      chdir(_file_path(localFilename),1);
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" log ";
      cmdLine :+= _maybe_quote_filename(relative(localFilename));
      status = cvsRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(VSRC_SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return VSRC_SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      index := 0;
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      int branchParents:[];
      top();
      STRHASHTAB symbolicNames;
      getSymbolicNames(symbolicNames);
      for (;;) {
         _str revision;
         _str date;
         _str author;
         STRARRAY branches;
         comment := "";
         status = search(DASH_LINE,'@>');
         if ( status ) {
            break;
         }
         down();
         get_line(auto curLine);
         if ( pos("revision ",curLine)==1 ) {
            parse curLine with "revision " revision;
         }
         down();
         get_line(curLine);
         if ( pos("date:",curLine)==1 ) {
            parse curLine with "date: " date";  author: "author ";".;
            date = adjustDateForLocalTime(date);
         }
         down();
         get_line(curLine);
         if ( pos("branches:",curLine)==1 ) {
            parse curLine with "branches: " auto branchList;
            for (;;) {
               parse branchList with auto curBranch';' branchList;
               if (curBranch=="") break;
               ARRAY_APPEND(branches,curBranch);
            }
         } else {
            if (curLine==EQUALS_LINE77) break;
            comment :+= "\n"curLine;
         }
         for (;;) {
            if (down()) {
               break;
            }
            get_line(curLine);
            if (curLine==EQUALS_LINE77) break;
            if ( curLine==DASH_LINE ) {
               up();
               break;
            }
            comment :+= "\n"curLine;
         }

         curItemBranch := substr(revision,1,length(revision)-2);
         parentIndex := branchParents:[curItemBranch];
         if ( parentIndex!=null  ) {
            index = parentIndex;
            addFlags = ADDFLAGS_ASTOPCHILD;
         }
         index = addHistoryItem(index,addFlags,historyInfo,false,_pic_file,revision,author,date,comment);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
         len := branches._length();
         for (i:=0;i<len;++i) {
            branchNumber := strip(branches[i]);
            curNewBranch := branchNumber;
            branchName = getBranchName(curNewBranch,symbolicNames);
            if ( branchName!="" ) {
               curNewBranch = branchName' ('curNewBranch')';
            }
            branchIndex := addHistoryItem(index,ADDFLAGS_ASCHILD,historyInfo,false,_pic_branch,curNewBranch,"","","");
            branchParents:[branchNumber] = branchIndex;
         }
      }
      if ( options & SVC_HISTORY_INCLUDE_WORKING_FILE ) {
         index = addHistoryItem(index,addFlags,historyInfo,false,0,"Working file","","","","","","");
      }

      if ( status==STRING_NOT_FOUND_RC ) status = 0;
      p_window_id = origWID;
      return status;
   }

   private _str pad(int number) {
      numberstr := "";
      if ( number < 10 ) {
         numberstr = "0";
      }
      numberstr :+= number;
      return numberstr;
   }

   private _str adjustDateForLocalTime(_str date) {
      // cvs dates are all in UTC
      typeless year, month, day, hour, minute, second,offset;
      datesep := '/';

      // Some CVS clients/servers seem to use '-' instead of '/'.  Use a simple 
      // check for this
      if ( !pos(datesep,date) ) {
         if ( pos('-',date) ) {
            datesep='-';
         }
      }
      parse date with year (datesep) month (datesep) day " " hour ":" minute ":" second;
      if ( pos('\+|\-',second,1,'r') ) {
         // Some newer CVS servers are appending "+####" for the time zone
         parse second with second offset;
      }
      if ( _localize_time(year, month, day, hour, minute, second) ) {
         return(year:+datesep:+pad(month):+datesep:+pad(day) " " pad(hour) ":" pad(minute) ":" pad(second) " (" date " UTC)");
      }

      // localize failed so flag the date that was passed in as UTC and send it back out
      return(date " UTC");
   }

   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0) {
      return 0;
   }

   int getLocalFileBranch(_str localFilename,_str &branchName) {
      branchName = "";
      return 0;
   }

   void getVersionNumberFromVersionCaption(_str revisionCaption,_str &versionNumber) {
      versionNumber = revisionCaption;
   }

   _str getBaseRevisionSpecialName() {
      return "BASE";
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
      versionStr := "";
      if ( version!="" ) {
         versionStr = "-r "version;
      }
      status = getRemoteFilename(localFilename,auto moduleName="");
      if ( status ) return status;

      origWID := p_window_id;
      origDir := getcwd();
      status = chdir(_file_path(localFilename));
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options"  checkout "versionStr" -p "_maybe_quote_filename(moduleName);
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      status = cvsRunCommand(cmdLine,fileWID,auto stdErrData);
      chdir(origDir);
      maybeOutputWIDToLog(fileWID,"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( status ) return status;
      p_window_id = fileWID;

      // For the moment, this is the easiest way to get the encoding and EOL 
      // chars right
      tempFile := mktemp();
      fileWID._save_file('+o '_maybe_quote_filename(tempFile));
      _delete_temp_view(fileWID);
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

   private int getModule(_str localFilename,_str &module) {
      repositoryFilename := _file_path(localFilename):+FILESEP:+"CVS":+FILESEP:+'Repository';

      if (substr(localFilename,2,1)!=':' && substr(localFilename,1,1)!=FILESEP) {
         repositoryFilename = "CVS":+FILESEP:+'Repository';
      }
      status := _open_temp_view(repositoryFilename,auto tempWID,auto origWID);
      if ( status ) return status;
      top();
      get_line(module);
      p_window_id = origWID;
      _delete_temp_view(tempWID);
      return status;
   }

   int getRemoteFilename(_str localFilename,_str &remoteFilename) {
      status := getExeStr(auto exeStr);
      deferedInit();
      getModule(localFilename,auto module="");
      remoteFilename = module:+'/':+_strip_filename(localFilename,'P');
      return 0;
   }

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0,bool checkForUpdates=true) {
      localPath := _file_path(localFilename);
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localFilename) ) {
//         _message_box(get_message(FILE_NOT_FOUND_RC,localPath));
         return FILE_NOT_FOUND_RC;
      }

      getCVSPath(localPath,auto cvsPath="");

      origDir := getcwd();
      chdir(_file_path(localFilename),1);

      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options"  status "_maybe_quote_filename(relative(localFilename));
      maybeOutputStrToLog(cmdLine,"getFileStatus cmdLine");
      status = cvsRunCommand(cmdLine,auto statusWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(statusWID,"getFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getFileStatus stderr");
      if ( status ) return status;
      origWID := p_window_id;
      p_window_id = statusWID;
      top();
      SVC_UPDATE_INFO fileInfo:[];
      for (;;) {
         status = search(EQUALS_LINE67,'@>');
         if (status) break;
         down();
         get_line(auto curLine);
         parse curLine with 'File: 'auto justName 'Status: 'auto statusStr;
         justName = strip(justName);
         down(3);
         get_line(curLine);
         parse curLine with "   Repository revision:\t" auto curRevision"\t" auto repositoryFile;
         parse repositoryFile with (cvsPath) auto curFile ',v';
         curFile = substr(curFile,2);
         p := pos('/',curFile);
         if ( p>1 ) {
            curFile = substr(curFile,p+1);
         }
         fileStatus = SVC_STATUS_NONE;
         curFile = localPath:+stranslate(curFile,FILESEP,'/');
         if ( statusStr=='Locally Modified' ) {
            fileStatus |= SVC_STATUS_MODIFIED;
         }
         if ( statusStr=='Needs Patch' ) {
            fileStatus |= SVC_STATUS_NEWER_REVISION_EXISTS;
         }
         if ( statusStr=='Needs Merge' ) {
            fileStatus |= SVC_STATUS_MODIFIED|SVC_STATUS_NEWER_REVISION_EXISTS;
         }
      }
      p_window_id = origWID;
      _delete_temp_view(statusWID);

      if ( status==STRING_NOT_FOUND_RC ) status = 0 ;

      return status;
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
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" update -d ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         curFilename := localFilenames[i];
         _maybe_strip_filesep(curFilename);
         curFilename = relative(curFilename);
         curFilename = stranslate(curFilename,'/',FILESEP);
         cmdLine :+= ' '_maybe_quote_filename(curFilename);
      }
      maybeOutputStrToLog(cmdLine,"updateFiles cmdLine");
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
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

      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" update -C ";
      len := localFilenames._length();
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      for (i:=0;i<len;++i) {
         cmdLine :+= ' '_maybe_quote_filename(relative(localFilenames[i]));
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"revertFiles cmdLine="cmdLine);
      maybeOutputWIDToLog(commitOutputWID,"revertFiles stdout");
      maybeOutputStringToLog(stdErrData,"revertFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(VSRC_SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
      }
      _reload_vc_buffers(localFilenames);
      _retag_vc_buffers(localFilenames);
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

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

      showApplyToAll := true;
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {

         status = getComment(auto commentFilename="","",localFilenames[i],showApplyToAll,auto applyToAll=false,false);
         if ( status ) {
            return status;
         }

         commitOutputWID := 0;
         if ( applyToAll ) {
            rest := "";
            origDir := getcwd();
            chdir(_file_path(localFilenames[0]),1);
            for (j:=i;j<len;++j) {
               rest :+= ' '_maybe_quote_filename(relative(localFilenames[j]));
            }
            cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" commit -F "_maybe_quote_filename(commentFilename)' 'rest;
            maybeOutputStrToLog(cmdLine,"commitFiles cmdLine");
            status = cvsRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            chdir(origDir,1);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
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
            origDir := getcwd();
            chdir(_file_path(localFilenames[i]),1);
            status = cvsRunCommand(_maybe_quote_filename(exeStr)" commit  -F "_maybe_quote_filename(commentFilename)' 'relative(localFilenames[i]),commitOutputWID,auto stdErrData);
            chdir(origDir,1);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
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
         _maybe_strip_filesep(curFileName);
         insert_line(curFileName);
      }
      targetFilename = tempFilename();
      status := _save_file("+o "_maybe_quote_filename(targetFilename));
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

   _str localRootPath(_str path="") {
      return path;
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
   int switchBranches(_str branchName,_str localPath,SVCSwitchBranch options=0) {
      return 0;
   }

   SVCCommandsAvailable commandsAvailable() {
      return SVC_COMMAND_AVAILABLE_COMMIT|SVC_COMMAND_AVAILABLE_DIFF|SVC_COMMAND_AVAILABLE_HISTORY|SVC_COMMAND_AVAILABLE_MERGE|SVC_COMMAND_AVAILABLE_REVERT|SVC_COMMAND_AVAILABLE_ADD|SVC_COMMAND_AVAILABLE_REMOVE|SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH|SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT|SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE|SVC_COMMAND_AVAILABLE_UPDATE|SVC_COMMAND_AVAILABLE_SYMBOL_QUERY|SVC_COMMAND_AVAILABLE_EDIT;
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
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" edit ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         curFilename := localFilenames[i];
         _maybe_strip_filesep(curFilename);
         curFilename = relative(curFilename);
         curFilename = stranslate(curFilename,'/',FILESEP);
         cmdLine :+= ' '_maybe_quote_filename(curFilename);
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"editFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"editFiles stdout");
      maybeOutputStringToLog(stdErrData,"editFiles stderr");
      if ( status || ( (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) &&
             substr(stdErrData,1,24) != "cvs edit: editing file"
             ) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(VSRC_SVC_COULD_NOT_EDIT_FILE,"edit",localFilenames[0],stdErrData));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);

      return 0;
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
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" add ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         curFilename := localFilenames[i];
         _maybe_strip_filesep(curFilename);
         curFilename = relative(curFilename);
         curFilename = stranslate(curFilename,'/',FILESEP);
         cmdLine :+= ' '_maybe_quote_filename(curFilename);
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"addFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"addFiles stdout");
      maybeOutputStringToLog(stdErrData,"addFiles stderr");
      if ( status || ( (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) &&
             substr(stdErrData,1,24) != "cvs add: scheduling file"
             ) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(VSRC_SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
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
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      cmdLine := _maybe_quote_filename(exeStr)" "def_cvs_global_options" remove ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         cmdLine :+= ' '_maybe_quote_filename(localFilenames[i]);
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"removeFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"removeFiles stdout");
      maybeOutputStringToLog(stdErrData,"removeFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(VSRC_SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
         return VSRC_SVC_COULD_NOT_UPDATE_FILE;
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

   static void getCVSPath(_str localPath,_str &cvsPath) {
      cvsPath = "";
      CVSRootPath := localPath:+"CVS":+FILESEP:+"Root";
      status := _open_temp_view(CVSRootPath,auto tempWID,auto origWID);
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with ':' auto type ':' . ':' cvsPath;
         if ( type=="local" ) {
            parse curLine with ':' type ':' cvsPath;
         }
         if ( !pos(':',curLine) ) {
            cvsPath = curLine;
         }
      }
      p := pos('/',cvsPath);
      if (p>1) {
         first := substr(cvsPath,1,p-1);
         if (isnumber(first)) {
            cvsPath = substr(cvsPath,p);
         }
      }
      p_window_id = origWID;
      _delete_temp_view(tempWID);
   }

   int getMultiFileStatus(_str localPath,SVC_UPDATE_INFO (&fileStatusList)[],
                          SVC_UPDATE_TYPE updateType=SVC_UPDATE_PATH,
                          bool recursive=true,int options=0,_str &remoteURL="") {
      CVS_LOG_INFO Files[]=null;
      status := _CVSGetVerboseFileInfo(localPath,Files,auto moduleName="",true);
      len := Files._length();
      offset := fileStatusList._length();
      for (i:=0;i<len;++i) {
         fileStatusList[i + offset].filename = Files[i].WorkingFile;
         switch ( Files[i].Description ) {
         case 'M':
            fileStatusList[i + offset].status = SVC_STATUS_MODIFIED;
            if ( Files[i].LocalVersion != Files[i].Head ) {
               fileStatusList[i + offset].status = SVC_STATUS_MODIFIED|SVC_STATUS_NEWER_REVISION_EXISTS;
            }
            break;
         case 'U':
            fileStatusList[i + offset].status = SVC_STATUS_NEWER_REVISION_EXISTS;
            break;
         case '?':
            fileStatusList[i + offset].status = SVC_STATUS_NOT_CONTROLED;
            break;
         case '-':                
            fileStatusList[i + offset].status = SVC_STATUS_MISSING;
            break;
         case 'N':                
            fileStatusList[i + offset].status = SVC_STATUS_NEWER_REVISION_EXISTS;
            break;
         case 'A':                
            fileStatusList[i + offset].status = SVC_STATUS_SCHEDULED_FOR_ADDITION;
            break;
         default:
            fileStatusList[i + offset].status = SVC_STATUS_NOT_CONTROLED;
         }
      }
      return status;
   }

   private SVCFileStatus getStatusFromOutput(_str line) {
      status := SVC_STATUS_NONE;
      return status;
   }

   _str getSystemNameCaption() {
      return "CVS";
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

   private bool _pathIsParentDirectory(_str path,_str parentPath) {
      lenPath := length(path);
      lenParentPath := length(parentPath);
      if ( lenPath < lenParentPath )  {
         return false;
      }
      pieceOfPath := substr(path,1,lenParentPath);
      match := _file_eq(pieceOfPath,parentPath);
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
              _file_eq(substr(pathsToUpdate[i+1],1,length(pathsToUpdate[i])),pathsToUpdate[i])
                      ) {
            pathsToUpdate._deleteel(i+1);
            --len;
            --i;
         }
      }
   }

   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",bool quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      origDir := getcwd();
      chdir(_file_path(localFilename),1);

      status = cvsRunCommand(_maybe_quote_filename(exeStr)" "def_cvs_global_options"  log -t "_maybe_quote_filename(relative(localFilename)),auto graphWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(graphWID,"getCurRevision stdout");
      maybeOutputStringToLog(stdErrData,"getCurRevision stderr");
      if ( status ) return status;

      p_window_id = graphWID;
      top();
      status = search('^head\: ','@r');
      if ( !status ) {
         get_line(auto line);
         parse line with 'head: '  curRevision ':' .;
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
      p_window_id = origWID;
      return status;
   }

   int getCurLocalRevision(_str localFilename,_str &curRevision,bool quiet=false) {
      curRevision = "";
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      entriesFilename := _file_path(localFilename):+FILESEP:+"CVS":+FILESEP:+'Entries';
      status = _open_temp_view(entriesFilename,auto tempWID,auto origWID);
      if ( status ) return status;
      status = search('/'_strip_filename(localFilename,'P')'/');
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with '/' .  '/' curRevision '/' .;
      }
      p_window_id = origWID;
      _delete_temp_view(tempWID);
      return status;
   }

   int pushToRepository(_str path="",_str branch="",_str remote="",int flags=0) {
      return 0;
   }

   int pullFromRepository(_str path="",_str branch="",_str remote="",int options=0){
      return 0;
   }

   int getNumVersions(_str localFilename) {
      return 0;
   }

   int enumerateVersions(_str localFilename,STRARRAY &versions,bool quiet=false,_str branchName="") {
      SVCHistoryInfo historyInfo[];
      getHistoryInformation(localFilename,historyInfo);

      len := historyInfo._length();
      for (i:=0;i<len;++i) {
         versions[i] = historyInfo[i].revision;
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
   int getPushPullInfo(_str &branchName, _str &pushRepositoryName, _str &pullRepositoryName, _str &path="") {
      return 0;
   }
   int getBranchNames(STRARRAY &branches,_str &currentBranch,_str path,bool forPushPullCombo=false,_str pullRepositoryName="",SVCBranchFlags options=0) {
      return 0;
   }
   int getBranchForCommit(_str commitVersion,_str &branchforCommit, _str path) {
      return 0;
   }

   int stash(_str path="",SVCStashFlags flags=0,STRARRAY &listOfStashes=null) {
      return 0;
   }

   int getStashList(STRARRAY &listOfStashes, _str path="", SVCStashFlags options=0) {
      return 0;
   }

   bool listsFilesInUncontrolledDirectories() {
      return true;
   }
};

