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
#import "CVSBuildFile.e"
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

class CVS : IVersionControl {
   private boolean m_debug = false;
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
      if ( def_cvs_info.cvs_exe_name=="" || 
           !file_exists(def_cvs_info.cvs_exe_name) ) {
         _str exeName = "";
#if __UNIX__
         exeName='cvs';
#else
         exeName="cvs.exe";
#endif
         def_cvs_info.cvs_exe_name=path_search(exeName);
         if ( def_cvs_info.cvs_exe_name=="" || 
              !file_exists(def_cvs_info.cvs_exe_name) ) {
            return SVC_COULD_NOT_FIND_VC_EXE;
         }
      }
      exeStr = def_cvs_info.cvs_exe_name;
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
      origDir := getcwd();
      chdir(_file_path(localFilename),1);
      cmdLine := maybe_quote_filename(exeStr)" diff "versionSpec' ':+maybe_quote_filename(relative(localFilename));
      maybeOutputStrToLog(cmdLine,"diffLocalFile cmdLine");
      status = cvsRunCommand(cmdLine,auto scriptWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(scriptWID,"diffLocalFile stdout");
      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
      if ( status || (length(stdErrData)>1 && scriptWID.p_Noflines==0) ) {
         status = SVC_COULD_NOT_COMPARE_FILE;
         _message_box(get_message(status,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return status;
      }
      CVSBuildFile bf;
      originalFileWID := bf.buildOriginalFile(localFilename,scriptWID);
      if ( originalFileWID<=0 ) {
         return 1;
      }
      getRemoteFilenameFromDiffScript(scriptWID,auto remoteFilename="");

      _delete_temp_view(scriptWID);

      if ( remoteFilename=="" ) {
         diff('-modal -bi2 -r2 -matchMode2 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      } else {
         diff('-modal -bi2 -r2 -matchMode2 -file2title 'maybe_quote_filename(remoteFilename)' 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      }

      _delete_temp_view(originalFileWID);

      return 0;
   }

   private int cvsRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0) {
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
               return cvsRunCommand(newCommand,stdOutWID,stdErrData,dataToWriteToStdinWID);
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

   #define DASH_LINE "----------------------------"
   #define EQUALS_LINE77 "============================================================================="
   #define EQUALS_LINE67 "==================================================================="

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
      chdir(_file_path(localFilename),1);
      cmdLine := maybe_quote_filename(exeStr)" log ":+maybe_quote_filename(relative(localFilename));
      status = cvsRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformationForCurrentBranch stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      index := 0;
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      int branchParents:[];
      top();
      for (;;) {
         _str revision;
         _str date;
         _str author;
         STRARRAY branches;
         _str comment = "";
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
            comment = comment"\n"curLine;
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
            comment = comment"\n"curLine;
         }

         curItemBranch := substr(revision,1,length(revision)-2);
         parentIndex := branchParents:[curItemBranch];
         if ( parentIndex!=null  ) {
            index = parentIndex;
            addFlags = ADDFLAGS_ASCHILD;
         }
         index = addHistoryItem(index,addFlags,historyInfo,false,_pic_file,revision,author,date,comment);
         addFlags = ADDFLAGS_SIBLINGBEFORE;
         len := branches._length();
         for (i:=0;i<len;++i) {
            curNewBranch := strip(branches[i]);
            branchIndex := addHistoryItem(index,ADDFLAGS_ASCHILD,historyInfo,false,_pic_branch,curNewBranch,"","","");
            branchParents:[curNewBranch] = branchIndex;
         }
      }

      if ( status==STRING_NOT_FOUND_RC ) status = 0;
      return status;
   }

   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0) {
      return 0;
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
      versionStr := "";
      if ( version!="" ) {
         versionStr = "-r "version;
      }
      status = getRemoteFilename(localFilename,auto moduleName="");
      if ( status ) return status;

      origWID := p_window_id;
      origDir := getcwd();
      chdir(_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)"  checkout "versionStr" -p "maybe_quote_filename(moduleName);
      maybeOutputStrToLog(cmdLine,"getFile cmdLine");
      status = cvsRunCommand(cmdLine,fileWID,auto stdErrData);
      chdir(_file_path(origDir));
      maybeOutputWIDToLog(fileWID,"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( status ) return status;
      p_window_id = fileWID;

      // For the moment, this is the easiest way to get the encoding and EOL 
      // chars right
      tempFile := mktemp();
      fileWID._save_file('+o 'maybe_quote_filename(tempFile));
      _delete_temp_view(fileWID);
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

   private int getModule(_str localFilename,_str &module) {
      repositoryFilename := _file_path(localFilename):+FILESEP:+"CVS":+FILESEP:+'Repository';
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

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0) {
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

      parse get_env("CVSROOT") with ':' auto type ':' auto cvsPath ':'.;

      origDir := getcwd();
      chdir(_file_path(localFilename),1);

      cmdLine := maybe_quote_filename(exeStr)"  status "maybe_quote_filename(relative(localFilename));
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
         fileStatus = 0;
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
      cmdLine := maybe_quote_filename(exeStr)" update ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         cmdLine = cmdLine' 'maybe_quote_filename(relative(localFilenames[i]));
      }
      maybeOutputStrToLog(cmdLine,"updateFiles cmdLine");
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
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

      cmdLine := maybe_quote_filename(exeStr)" update -C ";
      len := localFilenames._length();
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      for (i:=0;i<len;++i) {
         cmdLine = cmdLine' 'maybe_quote_filename(relative(localFilenames[i]));
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"revertFiles cmdLine="cmdLine);
      maybeOutputWIDToLog(commitOutputWID,"revertFiles stdout");
      maybeOutputStringToLog(stdErrData,"revertFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
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

         commitOutputWID := 0;
         if ( applyToAll ) {
            rest := "";
            origDir := getcwd();
            chdir(_file_path(localFilenames[0]),1);
            for (j:=i;j<len;++j) {
               rest = rest' 'maybe_quote_filename(relative(localFilenames[j]));
            }
            cmdLine := maybe_quote_filename(exeStr)" commit -F "maybe_quote_filename(commentFilename)' 'rest;
            maybeOutputStrToLog(cmdLine,"commitFiles cmdLine");
            status = cvsRunCommand(cmdLine,commitOutputWID,auto stdErrData);
            chdir(origDir,1);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
            delete_file(commentFilename);
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(SVC_COMMIT_FAILED,"commit",localFilenames[0],stdErrData));
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
            SVCWriteWIDToOutputWindow(commitOutputWID);
            _delete_temp_view(commitOutputWID);
            break;
         } else {
            origDir := getcwd();
            chdir(_file_path(localFilenames[i]),1);
            status = cvsRunCommand(maybe_quote_filename(exeStr)" commit  -F "maybe_quote_filename(commentFilename)' 'relative(localFilenames[i]),commitOutputWID,auto stdErrData);
            chdir(origDir,1);
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
      return "";
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
      return SVC_COMMAND_AVAILABLE_COMMIT\
         |SVC_COMMAND_AVAILABLE_DIFF\
         |SVC_COMMAND_AVAILABLE_HISTORY\
         |SVC_COMMAND_AVAILABLE_MERGE\
         |SVC_COMMAND_AVAILABLE_REVERT\
         |SVC_COMMAND_AVAILABLE_ADD\
         |SVC_COMMAND_AVAILABLE_REMOVE\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE\
         |SVC_COMMAND_AVAILABLE_UPDATE;
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

      result := _message_box(nls("This will remove local files.\n\nContinue?"),"",MB_YESNO);
      if ( result!=IDYES ) {
         return COMMAND_CANCELLED_RC;
      }
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      cmdLine := maybe_quote_filename(exeStr)" add ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         cmdLine = cmdLine' 'maybe_quote_filename(localFilenames[i]);
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"addFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"addFiles stdout");
      maybeOutputStringToLog(stdErrData,"addFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
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
      origDir := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      cmdLine := maybe_quote_filename(exeStr)" remove ";
      len := localFilenames._length();
      for (i:=0;i<len;++i) {
         cmdLine = cmdLine' 'maybe_quote_filename(localFilenames[i]);
      }
      status = cvsRunCommand(cmdLine,auto commitOutputWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputStringToLog(stdErrData,"removeFiles cmdLine="cmdLine);
      popd();
      maybeOutputWIDToLog(commitOutputWID,"removeFiles stdout");
      maybeOutputStringToLog(stdErrData,"removeFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,"add",localFilenames[0],stdErrData));
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
      _maybe_append_filesep(localPath);
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

      parse get_env("CVSROOT") with ':' auto type ':' auto cvsPath ':'.;

      origDir := getcwd();
      chdir(localPath,1);

      cmdLine := maybe_quote_filename(exeStr)"  status -R ";//maybe_quote_filename(relative(localPath));
      maybeOutputStrToLog(cmdLine,"getMultiFileStatus cmdLine");
      status = cvsRunCommand(cmdLine,auto statusWID=0,auto stdErrData);
      chdir(origDir,1);
      maybeOutputWIDToLog(statusWID,"getMultiFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
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
         curFile = localPath:+stranslate(curFile,FILESEP,'/');
         SVC_UPDATE_INFO *pCur = &fileStatusList[fileStatusList._length()];
         fileStatus := 0;
         if ( statusStr=='Locally Modified' ) {
            fileStatus |= SVC_STATUS_MODIFIED;
         }
         if ( statusStr=='Needs Patch' ) {
            fileStatus |= SVC_STATUS_NEWER_REVISION_EXISTS;
         }
         if ( statusStr=='Needs Merge' ) {
            fileStatus |= SVC_STATUS_MODIFIED|SVC_STATUS_NEWER_REVISION_EXISTS;
         }
         if ( fileStatus ) {
            pCur->filename = curFile;
            pCur->status   = fileStatus;
         }
      }
      p_window_id = origWID;
      _delete_temp_view(statusWID);

      if ( status==STRING_NOT_FOUND_RC ) status = 0 ;

      return status;
   }

   private SVCFileStatus getStatusFromOutput(_str line) {
      int status = 0;
      return status;
   }

   _str getSystemNameCaption() {
      return "CVS";
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

      origDir := getcwd();
      chdir(_file_path(localFilename),1);

      status = cvsRunCommand(maybe_quote_filename(exeStr)"  log -t "maybe_quote_filename(relative(localFilename)),auto graphWID=0,auto stdErrData);
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

   int getCurLocalRevision(_str localFilename,_str &curRevision,boolean quiet=false) {
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

   int pushToRepository(_str path="",int options=0) {
      return 0;
   }

   int pullFromRepository(_str path="",int options=0){
      return 0;
   }
   int getNumVersions(_str localFilename) {
      return 0;
   }
   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quiet=false) {
      return 0;
   }
};
