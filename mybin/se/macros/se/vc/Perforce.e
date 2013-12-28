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
#include "perforce.sh"
#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#require "IVersionControl.e"
#import "se/vc/NormalBuildFile.e"
#import "main.e"
#import "makefile.e"
#import "put.e"
#import "saveload.e"
#import "stdprocs.e"
#import "svc.e"
#import "sellist2.e"
#import "svchistory.e"
#import "stdcmds.e"
#import "subversion.e"
#require "sc/lang/String.e"
#import "vc.e"
#import "wkspace.e"
#endregion Imports

using sc.lang.String;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

#define PERFORCE_UP_TO_DATE " - file(s) up-to-date."

class Perforce : IVersionControl {
   private boolean m_debug = false;
   private _str m_clientPath = "";
   private _str m_localRoot = "";
   private _str m_localMachineInfo = "";
   private boolean m_gotViewInfo = false;
   private int m_didDeferredInit = 0;
   private _str m_captionTable[];
   private boolean m_validLocalPathTable:[];
   private boolean m_statusCommandAvailable = false;

   Perforce() {

      m_captionTable[SVC_COMMAND_COMMIT]  = "&Submit";
      m_captionTable[SVC_COMMAND_EDIT]    = "Check &Out";
      m_captionTable[SVC_COMMAND_DIFF]    = "&Diff";
      m_captionTable[SVC_COMMAND_HISTORY] = "&History";
      m_captionTable[SVC_COMMAND_MERGE]   = "Merge";
      m_captionTable[SVC_COMMAND_REVERT]  = "&Revert";
      m_captionTable[SVC_COMMAND_UPDATE]  = "&Update";
      m_captionTable[SVC_COMMAND_ADD]     = "&Add";
      m_captionTable[SVC_COMMAND_REMOVE]  = "Delete";
      m_captionTable[SVC_COMMAND_HISTORY_DIFF]  = "History Diff";
   }

   ~Perforce() {
   }

   /** 
    * Perform operations here that do anything we can't do in 
    * constructor.  This object could be contructed on a menu drop 
    * down. So we don't want to do a path search or run Perforce. 
    */
   private void deferedInit() {
      if ( m_didDeferredInit!=0 ) return;

      // Avoid recursion
      m_didDeferredInit = -1;

      if ( def_perforce_info.p4_exe_name=="" ) {
         filename := path_search(P4_EXE_NAME);
         if ( filename!="" ) {
            def_perforce_info.p4_exe_name = filename;
         } else {
            // We didn't find anything in the path. Set it to the exe filename
            // in hopes it will wind up in the path.
            def_perforce_info.p4_exe_name = P4_EXE_NAME;
         }
      }
      getPerforceInfo(def_perforce_info);
      m_didDeferredInit = 1;
   }


   private void getPerforceInfo(PERFORCE_SETUP_INFO &perforceInfo) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return;
      }
      status = perforceRunCommand(maybe_quote_filename(exeStr)" info ",auto infoWID=0,auto stdErrData);
      if ( status ) {
         return;
      }
      origWID := p_window_id;
      p_window_id = infoWID;
      top();up();
      while ( !down() ) {
         get_line(auto curLine);
         parse curLine with auto curLabel ': ' auto curValue;
         switch ( lowcase(curLabel) ) {
         case "user name":
            perforceInfo.userName = curValue;break;
         case "client name":
            perforceInfo.clientName = curValue;break;
         case "client host":
            perforceInfo.clientHost = curValue;break;
         case "client root":
            perforceInfo.clientRoot = curValue;break;
         case "current directory":
            perforceInfo.currentDirectory = curValue;break;
         case "peer address":
            perforceInfo.peerAddress = curValue;break;
         case "client address":
            perforceInfo.clientAddress = curValue;break;
         case "server address":
            perforceInfo.serverAddress = curValue;break;
         case "server root":
            perforceInfo.serverRoot = curValue;break;
         case "server date":
            perforceInfo.serverDate = curValue;break;
         case "server uptime":
            perforceInfo.serverUptTime = curValue;break;
         case "server version":
            parse curValue with ."/" auto serverPlatform '/' perforceInfo.serverVersion'/' auto serverBuildNumber '('auto serverBuildDate')';
            break;
         case "server license":
            perforceInfo.serverLicense = curValue;break;
         case "case handling":
            perforceInfo.caseHandling = curValue;break;
         }
      }
      p_window_id = origWID;
      _delete_temp_view(infoWID);
      infoWID = 0;
      stdErrData.set("");
      status = perforceRunCommand(maybe_quote_filename(exeStr)" -V ",infoWID,stdErrData);
      if ( status ) {
         return;
      }
      p_window_id = infoWID;
      top();
      status = search('^Rev\. P','@ri');
      if ( !status ) {
         // Rev. P4/NTX64/2012.2/536738 (2012/10/16).
         get_line(auto curLine);
         parse curLine with "Rev\\. P?/",'r' auto platform '/' perforceInfo.clientVersion'/' auto buildNumber '('auto buildDate')';
         parse perforceInfo.clientVersion with auto clientMajorVersion '.' auto clientMinorVersion;
         parse perforceInfo.serverVersion with auto serverMajorVersion '.' auto serverMinorVersion;

         allInts := isinteger(clientMajorVersion) && isinteger(clientMinorVersion)\
          && isinteger(serverMajorVersion) && isinteger(serverMinorVersion);

         all2012Dot1OrHigher := false;
         if ( allInts ) {
            all2012Dot1OrHigher = clientMajorVersion>=2012 && clientMinorVersion>=1 \
               && serverMajorVersion>=2012 && serverMinorVersion>=1;
         }
         m_statusCommandAvailable = allInts && all2012Dot1OrHigher;
      }
      p_window_id = origWID;
      _delete_temp_view(infoWID);

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
      if ( def_perforce_info.p4_exe_name==null 
           || def_perforce_info.p4_exe_name==""
           || !file_exists(def_perforce_info.p4_exe_name) ) {
         return SVC_COULD_NOT_FIND_VC_EXE;
      }
      exeStr = def_perforce_info.p4_exe_name;
      return 0;
   }

   int diffLocalFile(_str localFilename,_str version="",int options=0) {
      //deferedInit();
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
         // Version string already has 'r'
         if ( first_char(version)=='r' ) {
            versionSpec:+=' -'version;
         } else {
            versionSpec:+=' -r'version;
         }
      }
      if ( versionSpec=="" ) {
         versionSpec = "-r HEAD ";
      }
      mou_hour_glass(1);
      getFile(localFilename,version,auto originalFileWID=0);
      mou_hour_glass(0);
      getRemoteFilename(localFilename,auto remoteFilename="");
      fileTitle := remoteFilename;
      if ( version!="" ) {
         fileTitle = fileTitle'('version')';
      } else {
         fileTitle = fileTitle'(HEAD)';
      }
      diff('-modal -bi2 -r2 -file2title 'maybe_quote_filename(fileTitle)' 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);
      _delete_temp_view(originalFileWID);
#if 0 //12:21pm 5/8/2013
      filenameSpec := localFilename;
      if ( version!="" ) {
         filenameSpec:+='#'version;
      }
      status = perforceRunCommand(maybe_quote_filename(exeStr)" diff -f "maybe_quote_filename(filenameSpec),auto scriptWID=0,auto stdErrData);
      maybeOutputWIDToLog(scriptWID,"diffLocalFile stdout");
      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
      if ( status || (length(stdErrData)>1 && scriptWID.p_Noflines==0) ) {
         status = SVC_COULD_NOT_COMPARE_FILE;
         _message_box(get_message(status,localFilename,stdErrData));
         return status;
      }
      NormalBuildFile bf;
      originalFileWID := bf.buildOriginalFile(localFilename,scriptWID);
      if ( originalFileWID<=0 ) {
         return 1;
      }
      p_window_id = originalFileWID;
      getRemoteFilenameFromDiffScript(scriptWID,auto remoteFilename="");

      // Don't have to do this, the version will already be in what we get back
      // from getRemoteFilenameFromDiffScript
//      if ( version!="" ) {
//         remoteFilename = remoteFilename'#'version;
//      }
      _delete_temp_view(scriptWID);

      diff('-modal -bi2 -r2 -matchMode2 -file2title 'maybe_quote_filename(remoteFilename)' 'maybe_quote_filename(localFilename)' 'originalFileWID.p_buf_id);

      _delete_temp_view(originalFileWID);
#endif

      return 0;
   }

   private int getFilesCommand(_str localFilename,int &outputViewID,String &stdErrData,
                               _str command="files") {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;
      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      status = perforceRunCommand(maybe_quote_filename(exeStr)' 'command' 'maybe_quote_filename(localFilename),outputViewID,stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(outputViewID,"getFilesCommand stdout");
      maybeOutputStringToLog(stdErrData,"getFilesCommand stderr");
      if ( length(stdErrData)>1 || status ) {
         _message_box(get_message(SVC_COULD_NOT_GET_CURRENT_VERSION_FILE,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
      }

      p_window_id = origWID;
      return 0;
   }

   #define BRANCH_PREFIX "... ... branch "
   #define COPY_PREFIX   "... ... copy "
   #define MERGE_PREFIX   "... ... merge "
   #define IGNORE_PREFIX   "... ... ignored "
   #define EDIT_PREFIX   "... ... edit "

   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;
      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" filelog -t -l "maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getHistoryInformation cmdLine");
#if 1
      status = perforceRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData,0,localFilename);
#else
      status = _open_temp_view('c:\temp\p4test.txt',auto historyOutputWID,auto junkWID);
      String stdErrData;
#endif 
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformation stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      p_window_id = historyOutputWID;
      top();
      get_line(auto curBranch);
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      index := 0;

      bottom();
      // Buffer created from pipes somehow gets an extra line at the bottom, 
      // just skip any blank lines
      for ( ;; ) {
         if ( up() ) break;
         get_line(auto curLine);
         if ( curLine!="" ) break;
      }
      // Now move back down to our "false bottom"
      down();

      if ( curBranch!="" ) {
         lp := lastpos('/',curBranch);
         if ( lp ) curBranch = substr(curBranch,1,lp);
         index = addHistoryItem(index,addFlags,historyInfo,true,_pic_branch,curBranch);
      }

      hadParentBranch   := false;
      parentBranchIndex := -1;

      outerloop:
      for ( ;; ) {
         if ( up() ) break;
         get_line(auto curLine);
         comment := "";
         for ( ;; ) {
            if ( substr(curLine,1,1)!="\t" ) {
               if ( p_line==1 ) {
                  break outerloop;
               }
               break;
            }
            if ( comment=="" ) {
               comment = substr(curLine,2);
            } else {
               comment = substr(curLine,2)'<br>'comment;
            }
            if ( up() ) {
               break;
            }
            get_line(curLine);
         }
         parse curLine with "... " auto revision " change :i",'r' auto versionType " on " auto date_and_time " by " auto author '(' .;
         hadParentBranch = false;
         parentBranchIndex = -1;
         picIndex := _pic_file;
         skip := false;
         if ( substr(curLine,1,length(BRANCH_PREFIX)) == BRANCH_PREFIX ) {
            parse curLine with "... ... " versionType auto toOrFrom auto branchName "#" revision "," auto rev2;
            if ( branchName!="" ) {
               picIndex = _pic_branch;
               lp := lastpos('/',branchName);
               if ( lp ) revision = substr(branchName,1,lp);
               comment = "Branch "toOrFrom' 'branchName;
               if ( toOrFrom=="from" ) hadParentBranch = true;
            }
         } else if ( substr(curLine,1,length(COPY_PREFIX)) == COPY_PREFIX 
                     || substr(curLine,1,length(MERGE_PREFIX)) == MERGE_PREFIX 
                     || substr(curLine,1,length(IGNORE_PREFIX)) == IGNORE_PREFIX 
                     || substr(curLine,1,length(EDIT_PREFIX)) == EDIT_PREFIX ) {
            skip = true;
         }
         if ( revision!="" && !skip ) {
            index = addHistoryItem(index,addFlags,historyInfo,false,picIndex,revision,author,date_and_time,comment);
            if ( versionType=="branch" && parentBranchIndex!=-1 ) {
               historyInfo[parentBranchIndex].date = date_and_time;
               historyInfo[parentBranchIndex].author = author;
            }
         }
         if ( hadParentBranch ) {
            addFlags = ADDFLAGS_ASCHILD;
            parentBranchIndex = index;
         } else {
            addFlags = ADDFLAGS_SIBLINGAFTER;
         }
      }

      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;
      return 0;
   }

   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0) {
      return 0;
   }

   int getLocalFileBranch(_str localFilename,_str &URL) {
      return 0;
   }

   int getLocalFileURL(_str localFilename,_str &URL) {
      // Calling deferedInit() in getCurRevision()
      getCurRevision(localFilename,auto curRevision="",URL);
      return 0;
   }

   private int getRevisionInfo(_str localFilename,_str &curRevision,_str &URL,_str &curLocalRevision="",boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      deferedInit();

      curRevision = "";
      URL         = "";
      curLocalRevision = "";

      origWID := p_window_id;
      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)' -ztag fstat 'maybe_quote_filename(_strip_filename(localFilename,'P'));
      maybeOutputStrToLog(cmdLine,"getRevisionInfo cmdLine");
      maybeOutputStrToLog(getcwd(),"getRevisionInfo getcwd()");
      status = perforceRunCommand(cmdLine,auto outputViewID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(outputViewID,"getRevisionInfo stdout");
      maybeOutputStringToLog(stdErrData,"getRevisionInfo stderr");
      if ( length(stdErrData)>1 || status ) {
         if ( !quiet ) _message_box(get_message(SVC_COULD_NOT_GET_CURRENT_VERSION_FILE,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
      }

      p_window_id = outputViewID;
      top();up();

      status = search("^... depotFile ",'@ri');
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with "... depotFile " URL;
         top();up();
      }

      status = search("^... clientFile ",'@ri');
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with "... clientFile " auto clientFile;
      }

      status = search("^... headRev ",'@ri>');
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with "... headRev " curRevision;
         curRevision = '#'curRevision;
         top();up();
      }

      status = search("^... haveRev ",'@ri>');
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with "... haveRev " curLocalRevision;
         curLocalRevision = '#'curLocalRevision;
         top();up();
      }

      _delete_temp_view(outputViewID);
      p_window_id = origWID;
      return 0;
   }

   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",boolean quiet=false) {
      status := getRevisionInfo(localFilename,curRevision,URL,"",quiet);
      return status;
   }

   int getCurLocalRevision(_str localFilename,_str &curLocalRevision,boolean quiet=false) {
      status := getRevisionInfo(localFilename,auto curRevision="",auto URL="",curLocalRevision,quiet);
      return status;
   }

   private void getRemoteFilenameFromDiffScript(int scriptWID,_str &remoteFilename) {
      origWID := p_window_id;
      p_window_id = scriptWID;

      top();
      get_line(auto line);

      parse line with "==== " remoteFilename " - " . " ====";

      p_window_id = origWID;
   }

   private int perforceRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0,_str pathToRunIn="") {
      deferedInit();
      origWID := _create_temp_view(stdOutWID);
      p_window_id = origWID;
      int status = 0;
      int process_stdout_pipe,process_stdin_pipe,process_stderr_pipe;
      pathToRunIn = _file_path(pathToRunIn);
      origPath := getcwd();
      if ( pathToRunIn!="" ) {
         chdir(pathToRunIn,1);
         set_env("PWD",_file_path(pathToRunIn));
      }
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
      }
      chdir(origPath,1);
      set_env("PWD",origPath);
      return status;
   }
    
   private void perforceLog(_str dataToWrite,boolean writeToScreen=true) {
      dsay(dataToWrite, VERSION_CONTROL_LOG);
      if ( writeToScreen ) {
         say(dataToWrite);
      }
   }

   void getVersionNumberFromVersionCaption(_str revisionCaption,_str &versionNumber) {
      if ( substr(revisionCaption,1,1)=='#' ) {
         versionNumber = substr(revisionCaption,2);
      }
   }

   int getFile(_str localFilename,_str version,int &fileWID) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;
      filenameSpec := localFilename;
      if ( version!="" ) {
         if ( first_char(version)=='#' ) {
            version = substr(version,2);
         }
         filenameSpec:+='#'version;
      }
      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      status = perforceRunCommand(maybe_quote_filename(exeStr)" print "maybe_quote_filename(filenameSpec),fileWID,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(fileWID,"getFile stdout");
      maybeOutputStringToLog(stdErrData,"getFile stderr");
      if ( length(stdErrData)>1 || status ) {
         _message_box(get_message(SVC_COULD_NOT_GET_CURRENT_LOCAL_VERSION_FILE,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_CURRENT_LOCAL_VERSION_FILE;
      }

      // For the moment, this is the easiest way to get the encoding and EOL 
      // chars right
      tempFile := mktemp();
      fileWID.top();
      fileWID._delete_line();
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

   int getRemoteFilename(_str localFilename,_str &remoteFilename) {
      deferedInit();
      origWID := p_window_id;
      status := getFilesCommand(localFilename,auto historyOutputWID=0,auto stdErrData);
      if ( length(stdErrData)>1 || status ) {
         // If we had an error, first check to see if this file has just been 
         // added.
         if ( historyOutputWID ) _delete_temp_view(historyOutputWID);
         stdErrData.set("");
         status = getFilesCommand(localFilename,historyOutputWID,stdErrData,"opened");

         if ( length(stdErrData)>1 || status ) {
            if ( historyOutputWID ) _delete_temp_view(historyOutputWID);
            _message_box(get_message(SVC_COULD_NOT_GET_CURRENT_VERSION_FILE,localFilename,stdErrData));
            return SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
         }
      }
      p_window_id = historyOutputWID;
      up();
      get_line(auto line);
      parse line with remoteFilename "\\#:i",'r' auto curRevision " - " .;
      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;
      return 0;
   }

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      fileStatus = 0;
      curRevision := "";
      origWID := p_window_id;

      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      status = perforceRunCommand(maybe_quote_filename(exeStr)" opened "maybe_quote_filename(localFilename),auto openedInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(openedInfoWID,"getFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getFileStatus stderr");
      if ( status ) {
//         _message_box(get_message(SVC_COULD_NOT_GET_CURRENT_VERSION_FILE,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_CURRENT_VERSION_FILE;
      }

      p_window_id = openedInfoWID;
      up();
      get_line(auto line);
      if ( length(stdErrData)>0 ) {
         line = stdErrData.get();
      }
      parse line with auto filePart " - " auto statusInfo;
      if ( pos("file(s) not opened on this client.",statusInfo) ) {
         getCurRevision(localFilename,curRevision,"",true);
         getCurLocalRevision(localFilename,auto curLocalRevision="",true);
         if ( curRevision=="" ) {
            fileStatus |= SVC_STATUS_NOT_CONTROLED;
         } else if ( curRevision!=curLocalRevision ) {
            fileStatus |= SVC_STATUS_NEWER_REVISION_EXISTS;
         }
      } else if ( pos(" edit ",' 'statusInfo' ') ) {
         fileStatus |= SVC_STATUS_EDITED;
         status = perforceRunCommand(maybe_quote_filename(exeStr)" diff "maybe_quote_filename(localFilename),auto diffInfoWID=0,stdErrData);
         maybeOutputWIDToLog(diffInfoWID,"getFileStatus diff stdout");
         maybeOutputStringToLog(stdErrData,"getFileStatus diff stderr");
         if ( !status ) {
            if ( diffInfoWID.p_Noflines>2 ) {
               fileStatus |= SVC_STATUS_MODIFIED;
            }
            _delete_temp_view(diffInfoWID);
         }
      } else if ( pos(" add ",' 'statusInfo' ') ) {
         fileStatus |= SVC_STATUS_SCHEDULED_FOR_ADDITION;
      } else if ( pos(" delete ",' 'statusInfo' ') ) {
         fileStatus |= SVC_STATUS_SCHEDULED_FOR_DELETION;
      }
      _delete_temp_view(openedInfoWID);
      p_window_id = origWID;
      return 0;
   }

   int updateFiles(_str (&localFilenames)[],int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      commandStr := maybe_quote_filename(exeStr)" sync ";
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         commandStr = commandStr' 'maybe_quote_filename(localFilenames[i]);
      }
      errFilename := localFilenames[0];
      if ( len>1 ) errFilename = errFilename" ...";

      commandCaption := getCaptionForCommand(SVC_COMMAND_UPDATE,false,false);
      origPath := getcwd();
      // These files will have to be under the same client
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      status = perforceRunCommand(commandStr,auto updateInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(updateInfoWID,"updateFiles stdout");
      maybeOutputStringToLog(stdErrData,"updateFiles stderr");
      if ( status ) {
         if ( length(stdErrData)>1 ) {
            _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,commandCaption,errFilename,stdErrData));
         } else {
            _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,commandCaption,errFilename,get_message(status)));
         }
         return SVC_COULD_NOT_UPDATE_FILE;
      }

      if ( length(stdErrData)>1 && !pos(PERFORCE_UP_TO_DATE,stdErrData) ) {
         _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,commandCaption,errFilename,stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCDisplayOutput(updateInfoWID,true,true);
      _delete_temp_view(updateInfoWID);
      p_window_id = origWID;
      _reload_vc_buffers(localFilenames);

      return 0;
   }

   int updateFile(_str localFilename,int options=0) {
      // Call deferedInit() in updateFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := updateFiles(tempFilenames,options);
      return status;
   }

   int revertFiles(_str (&localFilenames)[],int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      commandStr := maybe_quote_filename(exeStr)" revert ";
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         commandStr = commandStr' 'maybe_quote_filename(localFilenames[i]);
      }
      errFilename := localFilenames[0];
      if ( len>1 ) errFilename = errFilename" ...";

      commandCaption := getCaptionForCommand(SVC_COMMAND_REVERT,false,false);

      // These files will have to be under the same client
      origPath := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      status = perforceRunCommand(commandStr,auto revertInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(revertInfoWID,"revertFiles stdout");
      maybeOutputStringToLog(stdErrData,"revertFiles stderr");
      if ( status ) {
         if ( length(stdErrData)>2 ) {
            _message_box(get_message(SVC_COULD_NOT_REVERT_FILE,commandCaption,errFilename,stdErrData));
         } else {
            _message_box(get_message(SVC_COULD_NOT_REVERT_FILE,commandCaption,errFilename,get_message(status)));
         }
         return SVC_COULD_NOT_UPDATE_FILE;
      }

      if ( length(stdErrData)>1) {
         _message_box(get_message(SVC_COULD_NOT_REVERT_FILE,commandCaption,errFilename,stdErrData));
         return SVC_COULD_NOT_REVERT_FILE;
      }
      _reload_vc_buffers(localFilenames);
      SVCDisplayOutput(revertInfoWID,true,true);
      _delete_temp_view(revertInfoWID);
      p_window_id = origWID;

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

   private int appendComment(_str commentInfo,boolean commentIsFilename) {
      if ( !commentIsFilename ) {
         insert_line(commentInfo);
         return 0;
      }
      commentStr := "";
      commentFilename := commentInfo;
      status := _open_temp_view(commentFilename,auto commentWID,auto origWID);
      if ( status ) return status;

      top();up();
      while ( !down() ) {
         get_line(auto curLine);
//         tabCh := (p_line==1)?"\t":"";
         tabCh := "\t";
         p_window_id = origWID;
         insert_line(tabCh:+curLine);
         p_window_id = commentWID;
      }
      _delete_temp_view(commentWID);
      p_window_id = origWID;
      return status;
   }

   private int createChangelist(_str (&localFilenames)[],
//                                _str &changeListFilename,
                                int &changeListWID,
                                _str commentInfo,
                                _str &version,
                                int startIndex,
                                boolean commentIsFilename,
                                int changeListNumber = 0
                                ) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;

      changeListNumSpec := "";
      if ( changeListNumber!=0 ) {
         changeListNumSpec = changeListNumber;
      }
      status = perforceRunCommand(maybe_quote_filename(exeStr)" change -o "changeListNumSpec,changeListWID,auto stdErrData);
      maybeOutputWIDToLog(changeListWID,"createChangelist stdout");
      maybeOutputStringToLog(stdErrData,"createChangelist stderr");
      if ( status ) {
         return status;
      }

      p_window_id = changeListWID;
      
      markid := _alloc_selection();
      outerloop:
      do {
         // First remove the filenames that are there
         bottom();
         len := 0;

         p_window_id = changeListWID;
         top();
         // Now remove the comment string and replace it with what was passed in
         status = search('^\t\<enter description here\>$','@r');
//         if ( status  ) {
//            break outerloop;
//         }
         if ( !status ) {
            _delete_line();
            up();
            status = appendComment(commentInfo,commentIsFilename);
         }

         top();
         status = search('^Files\:$','@r');
         if ( !status  ) {
            if ( !down() ) {
               _select_line(markid);
               bottom();
               _select_line(markid);
               _delete_selection(markid);
            }
         } else {
            bottom();
            insert_line("Files:");
         }
         len = localFilenames._length();
         for ( i:=startIndex;i<len;++i ) {
            status = getRemoteFilename(localFilenames[i],auto remoteFilename="");
            if ( status ) {
               break outerloop;
            }
            insert_line("\t":+remoteFilename);
         }
      } while ( false );
      _free_selection(markid);
      p_window_id = origWID;

      if ( status ) {
         _delete_temp_view(changeListWID);
      }

      return status;
   }

   int commitFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      len := localFilenames._length();
      commentFilename := "";
      changeFilename := "";
      version := "";

      origPath := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      STRARRAY changeLists;
      STRARRAY changeVersions;
      filenameForErrorMsg := "";
      showApplyToAll := len>1;
      for ( i:=0;i<len;++i ) {
         applyToAll := false;
         if ( comment==null ) {
            status = getComment(commentFilename,"",localFilenames[i],showApplyToAll,applyToAll,false);
         } else {
            applyToAll = true;
            commentFilename = mktemp();
            tempOrigWID := _create_temp_view(auto tempWID);
            if ( !status || status==NEW_FILE_RC ) {
               p_window_id = tempWID;
               _insert_text(comment);
               _save_file('+o 'maybe_quote_filename(commentFilename));
               p_window_id = tempOrigWID;
               _delete_temp_view(tempWID);
            }
         }
         if ( status ) {
            chdir(origPath,1);
            set_env("PWD",origPath);
            return status;
         }
         changeFilename = "";
         changeListWID := 0;
         // First create and submit a change list
         do {
            changeListNum := 0;
            if ( def_perforce_info.userSpecifiesChangeNumber ) {
               changeListNum = promptForChangeListNumber();
               if ( changeListNum<0 ) return COMMAND_CANCELLED_RC;
            }
            if ( applyToAll ) {
               status = createChangelist(localFilenames,changeListWID,commentFilename,version,i,true,changeListNum);
               if ( status ) break;
               filenameForErrorMsg = localFilenames[i];
               if ( localFilenames._length()>i+1 ) {
                  filenameForErrorMsg = filenameForErrorMsg" ...";
               }
            } else {
               _str tempLocalFilenames[];
               tempLocalFilenames[0] = localFilenames[i];
               filenameForErrorMsg = tempLocalFilenames[0];
               status = createChangelist(tempLocalFilenames,changeListWID,commentFilename,version,0,true,changeListNum);
               if ( status ) break;
            }
         } while ( false );

         // Be sure to delete the file the comment was written in, this is in the
         // change list now
         delete_file(commentFilename);

         if ( status ) {
            chdir(origPath,1);
            set_env("PWD",origPath);
            return status;
         }
//         say('commitFiles i='i' changeListWID='changeListWID);

         // use the -i option to read from stdin.  the lines in changeListWID will be piped in
         status = perforceRunCommand(maybe_quote_filename(exeStr)" change -i ",auto changeInfoWID=0,auto stdErrData,changeListWID);
         maybeOutputWIDToLog(changeInfoWID,"commitFiles stdout");
         maybeOutputStringToLog(stdErrData,"commitFiles stderr");
         if ( length(stdErrData)>0 ) {
            _message_box(get_message(SVC_CHANGELIST_FAILED,filenameForErrorMsg,stdErrData));
            status = SVC_CHANGELIST_FAILED;
            break;
         }
         if ( status ) {
            chdir(origPath,1);
            set_env("PWD",origPath);
            return status;
         }

         // Go into the output from the change command and find the number of
         // the change
         SVCDisplayOutput(changeInfoWID,i==0,true);
         p_window_id = changeInfoWID;
         top();
         get_line(auto curLine);
         parse curLine with "Change " auto changeNum " created" .;
         p_window_id = origWID;
//         say('commitFiles changeNum='changeNum);

         ARRAY_APPEND(changeLists,changeNum);

         _delete_temp_view(changeListWID);
         _delete_temp_view(changeInfoWID);

         commandCaption := getCaptionForCommand(SVC_COMMAND_COMMIT,false,false);

         // Submit the change
         status = perforceRunCommand(maybe_quote_filename(exeStr)" submit -c "changeNum,auto submitInfoWID=0,stdErrData);
         maybeOutputWIDToLog(submitInfoWID,"commitFiles stdout");
         maybeOutputStringToLog(stdErrData,"commitFiles stderr");
         if ( status ) {
            if ( length(stdErrData)>2 ) {
               _message_box(get_message(SVC_COMMIT_FAILED,commandCaption,"change list "changeNum,stdErrData));
            } else {
               _message_box(get_message(SVC_COMMIT_FAILED,commandCaption,"change list "changeNum,""));
            }
            if ( submitInfoWID!=0 ) _delete_temp_view(submitInfoWID);
            chdir(origPath,1);
            set_env("PWD",origPath);
            return SVC_COMMIT_FAILED;
         }
         // Show the output
         SVCDisplayOutput(submitInfoWID,false,true);

         // Reload the buffers, if there are any "$VERSION$" type things in here
         // we'll need to have these reloaded
         _reload_vc_buffers(localFilenames);
         _delete_temp_view(submitInfoWID);
         if ( applyToAll ) break;
      }
      chdir(origPath,1);
      set_env("PWD",origPath);
      p_window_id = origWID;
      return 0;
   }

   int commitFile(_str localFilename,_str comment=null,int options=0) {
      // call deferedInit() in commitFiles()
      _str localFilenames[];
      localFilenames[0] = localFilename;
      status := commitFiles(localFilenames,comment,options);
      return status;
   }

   int mergeFile(_str localFilename,int options=0) {
      status := 0;
      
      status = getCurLocalRevision(localFilename,auto localRevision="");
      if ( status ) return status;

      status = getCurRevision(localFilename,auto curRevision="",auto URL="");
      if ( status ) return status;

      status = getFile(localFilename,localRevision,auto localRevisionWID=0);
      if ( status ) return status;

      status = getFile(localFilename,curRevision,auto curRevisionWID=0);
      if ( status ) return status;

      status = merge('-quiet -bbi -b1i -smart -showchanges -basefilecaption 'maybe_quote_filename(URL'#'localRevision)' -rev1filecaption 'maybe_quote_filename(URL'#'curRevision)' 'localRevisionWID.p_buf_id' 'curRevisionWID.p_buf_id' 'maybe_quote_filename(localFilename)' 'maybe_quote_filename(localFilename));

      return status;
   }


   SVCCommandsAvailable commandsAvailable() {
      return SVC_COMMAND_AVAILABLE_COMMIT|
         SVC_COMMAND_AVAILABLE_EDIT|
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

   private int promptForChangeListNumber() {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";

      cmdLine := maybe_quote_filename(exeStr)" user -o";

      origPath := getcwd();
      // Files have to be under same client
      maybeOutputStrToLog(cmdLine,"getHistoryInformation cmdLine");
      status = perforceRunCommand(cmdLine,auto userInfoWID=0,auto stdErrData);
      maybeOutputWIDToLog(userInfoWID,"promptForChangeList stdout");
      maybeOutputStringToLog(stdErrData,"promptForChangeList stderr");
      origWID := p_window_id;
      p_window_id = userInfoWID;
      top();up();
      status = search("User\\:\t?@$",'@r');
      userName := "";
      if ( !status ) {
         get_line(auto curLine);
         parse curLine with "User:\t" userName;
      }
      p_window_id = origWID;


      cmdLine = maybe_quote_filename(exeStr)" changes -s pending -u "userName;

      origPath = getcwd();
      // Files have to be under same client
      maybeOutputStrToLog(cmdLine,"getHistoryInformation cmdLine");
      status = perforceRunCommand(cmdLine,auto changesInfoWID=0,stdErrData);
      maybeOutputWIDToLog(changesInfoWID,"promptForChangeList stdout");
      maybeOutputStringToLog(stdErrData,"promptForChangeList stderr");

      if ( status ) {
         return 0;
      }

      int changeTable:[];
      origWID = p_window_id;
      p_window_id = changesInfoWID;
      top();up();
      insert_line(DEFAULT_CHANGELIST);
      changeTable:[DEFAULT_CHANGELIST] = 0;
      while ( !down() ) {
         get_line(auto curLine);
         parse curLine with "Change " auto changeNumber " on " .;
         if ( isinteger(changeNumber) ) {
            changeTable:[curLine] = (int)changeNumber;
         }
      }
      #define DEFAULT_CHANGELIST "[default changelist]"
      p_window_id = origWID;
      result := show('-modal _sellist_form',"Choose changelist",SL_VIEWID|SL_SELECTCLINE,changesInfoWID);
      if (result=="") return -1;
      changeNumber := changeTable:[result];

      return changeNumber;
   }

   int editFiles(_str (&localFilenames)[],int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      changeListSpec := "";
      if ( def_perforce_info.userSpecifiesChangeNumber ) {
         changeListNum := promptForChangeListNumber();
         if ( changeListNum<0 ) return COMMAND_CANCELLED_RC;
         if ( changeListNum!=0 ) {
            changeListSpec = '-c 'changeListNum;
         }
      }

      commandStr := maybe_quote_filename(exeStr)" edit "changeListSpec;
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         commandStr = commandStr' 'maybe_quote_filename(localFilenames[i]);
      }

      commandCaption := getCaptionForCommand(SVC_COMMAND_EDIT,false,false);
      origPath := getcwd();
      // Files have to be under same client
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      maybeOutputStrToLog(commandStr,"getHistoryInformation commandStr");
      status = perforceRunCommand(commandStr,auto revertInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(revertInfoWID,"editFiles stdout");
      maybeOutputStringToLog(stdErrData,"editFiles stderr");
      errFilename := localFilenames[0];
      if ( len>1 ) errFilename = errFilename" ...";
      if ( status ) {
         if ( length(stdErrData)>2 ) {
            _message_box(get_message(SVC_COULD_NOT_EDIT_FILE,commandCaption,errFilename,stdErrData));
         } else {
            _message_box(get_message(SVC_COULD_NOT_EDIT_FILE,commandCaption,errFilename,get_message(status)));
         }
         return SVC_COULD_NOT_EDIT_FILE;
      }

      if ( length(stdErrData)>1) {
         _message_box(get_message(SVC_COULD_NOT_EDIT_FILE,commandCaption,errFilename,stdErrData));
         return SVC_COULD_NOT_EDIT_FILE;
      }
      // This will insure that buffers get r/w set properly
      _reload_vc_buffers(localFilenames);
      SVCDisplayOutput(revertInfoWID,true,true);
      _delete_temp_view(revertInfoWID);
      p_window_id = origWID;

      return 0;
   }

   int editFile(_str localFilename,int options=0) {
      // Call deferedInit() in editFiles
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := editFiles(tempFilenames,options);
      return status;
   }

   void maybeOutputStrToLog(_str stdErrData,_str label) {
      if ( !def_svc_logging ) return;
      dsay(label,"svc");
      dsay(label':'stdErrData,"svc",1);
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


   int addFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      commandStr := maybe_quote_filename(exeStr)" add ";
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         commandStr = commandStr' 'maybe_quote_filename(localFilenames[i]);
      }

      commandCaption := getCaptionForCommand(SVC_COMMAND_ADD,false,false);
      origPath := getcwd();
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      status = perforceRunCommand(commandStr,auto addInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(addInfoWID,"addFiles stdout");
      maybeOutputStringToLog(stdErrData,"addFiles stderr");
      errFilename := localFilenames[0];
      if ( len>1 ) errFilename = errFilename" ...";
      if ( status ) {

         if ( length(stdErrData)>1 ) {
            _message_box(get_message(SVC_COULD_NOT_ADD_FILE,commandCaption,errFilename,stdErrData));
         } else {
            _message_box(get_message(SVC_COULD_NOT_ADD_FILE,commandCaption,errFilename,get_message(status)));
         }
         return SVC_COULD_NOT_ADD_FILE;
      }

      if ( length(stdErrData)>1) {
         _message_box(get_message(SVC_COULD_NOT_ADD_FILE,commandCaption,errFilename,stdErrData));
         return SVC_COULD_NOT_ADD_FILE;
      }
      // Could have change r/w permissions on a buffer
      _reload_vc_buffers(localFilenames);
      SVCDisplayOutput(addInfoWID,true,true);
      _delete_temp_view(addInfoWID);
      p_window_id = origWID;

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
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      commandStr := maybe_quote_filename(exeStr)" delete ";
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         commandStr = commandStr' 'maybe_quote_filename(localFilenames[i]);
      }

      origPath := getcwd();
      // Files have to be under same client
      chdir(_file_path(localFilenames[0]),1);
      set_env("PWD",_file_path(localFilenames[0]));
      status = perforceRunCommand(commandStr,auto removeInfoWID=0,auto stdErrData);
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(removeInfoWID,"removeFiles stdout");
      maybeOutputStringToLog(stdErrData,"removeFiles stderr");
      errFilename := localFilenames[0];
      if ( len>1 ) errFilename = errFilename" ...";
      if ( status ) {

         if ( length(stdErrData)>2 ) {
            _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,getCaptionForCommand(SVC_COMMAND_REMOVE,false,false),errFilename,stdErrData));
         } else {
            _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,getCaptionForCommand(SVC_COMMAND_REMOVE,false,false),errFilename,get_message(status)));
         }
         return SVC_COULD_NOT_ADD_FILE;
      }

      if ( length(stdErrData)>1) {
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,getCaptionForCommand(SVC_COMMAND_REMOVE,false,false),errFilename,stdErrData));
         return SVC_COULD_NOT_ADD_FILE;
      }
      _reload_vc_buffers(localFilenames);
      SVCDisplayOutput(removeInfoWID,true,true);
      _delete_temp_view(removeInfoWID);
      p_window_id = origWID;

      return status;
   }

   int removeFile(_str localFilename,_str comment=null,int options=0) {
      status := 0;
      // Call deferedInit() in removeFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status = removeFiles(tempFilenames,options);
      return status;
   }

   private int getViewInfo() {
      m_gotViewInfo = true;
      m_clientPath = "";
      m_localRoot = "";
      m_localMachineInfo = "";
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      status = perforceRunCommand(maybe_quote_filename(exeStr)" where",auto clientInfoWID=0,auto stdErrData);
      origWID := p_window_id;
      p_window_id = clientInfoWID;
      top();
      curLine := "";
      get_line(curLine);
      m_clientPath = parse_file(curLine);
      m_localMachineInfo = parse_file(curLine);
      m_localRoot = parse_file(curLine);
      p_window_id = origWID;
      _delete_temp_view(clientInfoWID);

      status = perforceRunCommand(maybe_quote_filename(exeStr)" info",clientInfoWID,stdErrData);
      p_window_id = clientInfoWID;
      top();
      status = search('^Case Handling\: ','@r>');
      if ( !status ) {
         get_line(curLine);
         parse curLine with "Case Handling: " auto caseHandling;
      }
      p_window_id = origWID;
      _delete_temp_view(clientInfoWID);
      return status;
   }

   int getMultiFileStatus(_str localPath,SVC_UPDATE_INFO (&fileStatusList)[],
                          SVC_UPDATE_TYPE updateType=SVC_UPDATE_PATH,
                          boolean recursive=true,int options=0,_str &remoteURL="") {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      if ( !file_exists(localPath) ) {
         _message_box(get_message(FILE_NOT_FOUND_RC,localPath));
         return FILE_NOT_FOUND_RC;
      }

      origWID := p_window_id;
      int differentFilesWID = 0;
      int outOfDateFilesWID = 0;
      int findInfoWID       = 0;
      int openedFilesWID    = 0;
      status = pushd(localPath,1);

      localPathFilespec := localPath;
      findOption := '';
      _maybe_append_filesep(localPathFilespec);
      if ( recursive ) {
         localPathFilespec = localPathFilespec'...';
      } else {
         localPathFilespec = localPathFilespec'*';
         findOption = ' -maxdepth 1 ';
      }
      getFileTable(localPath,recursive,auto fileTable);

      // Always quote - this keeps UNIX from expanding the '*' to everything
      localPathFilespec = always_quote_filename(localPathFilespec);
      do {
         SVC_UPDATE_INFO *filenameTab:[];
         origPath := getcwd();
         chdir(_file_path(localPath),1);
         set_env("PWD",_file_path(localPath));
         getViewInfo();
         remoteURL = m_clientPath;
         cmdLine := maybe_quote_filename(exeStr)' fstat -T "clientFile,haveRev,headRev,path,action,headAction" 'localPathFilespec;
         maybeOutputStrToLog(cmdLine,"getMultiFileStatus cmdLine");
         status = perforceRunCommand(cmdLine,differentFilesWID,auto stdErrData);
         chdir(origPath,1);
         set_env("PWD",origPath);
         maybeOutputWIDToLog(differentFilesWID,"getMultiFileStatus stdout");
         maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
         if ( length(stdErrData)>1 ) {
            stdErrData.stripChars("\n",'t');
            stdErrData.stripChars("\r",'t');
         }
         origWID = p_window_id;
         p_window_id = differentFilesWID;
         top();up();
         for (;;) {
            status = search('^(\.\.\. clientFile)','@r>');
            if (status) break;
            get_line(auto curLine);
            if ( curLine=="" ) {
               continue;
            }
            SVC_UPDATE_INFO temp;
            temp.status = 0;
            parse curLine with "... clientFile " temp.filename;

            down();
            get_line(curLine);
            parse curLine with "... headAction " auto headAction;
            if ( headAction=="" ) {
               up();
            } else {
               if ( headAction=="delete" || headAction=="move/delete" ) {
                  continue;
               }
            }

            down();
            get_line(curLine);
            parse curLine with "... headRev " auto headRev;
            if ( headRev=="" ) {
               if ( curLine=="... action add" ) {
                  temp.status |= SVC_STATUS_SCHEDULED_FOR_ADDITION;
               }
            }

            down();
            get_line(curLine);
            parse curLine with "... haveRev " auto haveRev;
            
            if ( headRev!=haveRev ) {
               temp.status |= SVC_STATUS_NEWER_REVISION_EXISTS;
            }

            down();
            get_line(auto maybeActionEdit);
            if ( maybeActionEdit=="... action edit" ) {
               temp.status |= SVC_STATUS_MODIFIED;
            } else if ( maybeActionEdit=="... action delete" ) {
               temp.status |= SVC_STATUS_SCHEDULED_FOR_DELETION;
            }
            if ( temp.status!=0 ) {
               ARRAY_APPEND(fileStatusList,temp);
            }
            fileTable._deleteel(_file_case(temp.filename));
         }
         p_window_id = origWID;
         if ( status==STRING_NOT_FOUND_RC ) status = 0;
      } while ( false );

      foreach (auto curFile => auto curValue in fileTable) {
         SVC_UPDATE_INFO temp;
         temp.filename = curFile;
         temp.status   = SVC_STATUS_NOT_CONTROLED;
         ARRAY_APPEND(fileStatusList,temp);
      }
      popd(1);
      p_window_id = origWID;
      if ( differentFilesWID ) _delete_temp_view(differentFilesWID);
      if ( outOfDateFilesWID ) _delete_temp_view(outOfDateFilesWID);
      if ( findInfoWID ) _delete_temp_view(findInfoWID);
      if ( openedFilesWID ) _delete_temp_view(openedFilesWID);

      return status;
   }

   private void getFileTable(_str localPath,boolean recursive,STRHASHTAB &fileTable) {
      _maybe_append_filesep(localPath);
      cmdLine := '-v +p 'localPath:+ALLFILES_RE;
      if ( recursive ) {
         cmdLine = '+t 'cmdLine;
      }
      origWID := _create_temp_view(auto tempWID);
      insert_file_list(cmdLine);
      top();up();
      while ( !down() ) {
         get_line(auto curLine);
         fileTable:[_file_case(strip(curLine))] = "";
      }
      p_window_id = origWID;
      _delete_temp_view(tempWID);
   }


   private _str getWholeRemotePath(_str &remotePath) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      curRevision := "";
      origWID := p_window_id;

      remotePathSpec := m_clientPath;
      remotePathSpec = stranslate(remotePathSpec,'*','...');

      cmdLine := maybe_quote_filename(exeStr)" dirs "remotePathSpec;

      maybeOutputStrToLog(cmdLine,"getWholeRemotePath cmdLine");
      status = perforceRunCommand(cmdLine,auto dirsWID=0,auto stdErrData);
      maybeOutputWIDToLog(dirsWID,"getWholeRemotePath stdout");
      maybeOutputStringToLog(stdErrData,"getWholeRemotePath stderr");
      p_window_id = dirsWID;
      top();
      get_line(remotePath);
      SVCDisplayOutput(dirsWID,true,true);
      _delete_temp_view(dirsWID);
      p_window_id = origWID;

      return 0;
   }

   private int getUnversionedFiles(SVC_UPDATE_INFO (&fileStatusList)[],SVC_UPDATE_INFO *filenameTab:[],String &stdErrData) {
      if ( m_statusCommandAvailable ) {
         return getUnversionedFilesFromStatus(fileStatusList,filenameTab,stdErrData);
      }
      status := getExeStr(auto exeStr);
      if ( status && false ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      missingFilesWID := 0;
      origWID := p_window_id;
      stdErrData.set("");
      _create_temp_view(auto findInfoWID);
      insert_file_list('+t +p -v 'ALLFILES_RE);
      markid := _alloc_selection();
      top();
      _select_line(markid);
      bottom();
      _select_line(markid);
      _shift_selection_left(markid);
      _free_selection(markid);
      stdErrData.set("");
      status = perforceRunCommand(maybe_quote_filename(exeStr)" -x- have",missingFilesWID,stdErrData,findInfoWID);
      maybeOutputWIDToLog(missingFilesWID,"getUnversionedFiles stdout");
      maybeOutputStringToLog(stdErrData,"getUnversionedFiles stderr");
      //say('getMultiFileStatus c='maybe_quote_filename(exeStr)" -x- have");
      if ( findInfoWID!=0 ) _delete_temp_view(findInfoWID);
      if ( length(stdErrData)>1 ) {
         errMessages := stdErrData.splitToArray("\n");
         len := errMessages._length();
         for ( i:=0;i<len;++i ) {
            p := pos(' - file(s) not on client.',errMessages[i]);
            if ( p>1 ) {
               localFilename := substr(errMessages[i],1,p-1);
//             say('getUnversionedFiles 10 localFilename='localFilename);
               SVC_UPDATE_INFO *pInfo = filenameTab:[_file_case(localFilename)];
               if ( pInfo==null ) {
                  SVC_UPDATE_INFO temp;
                  temp.filename = localFilename;
                  temp.status   = 0 ;
                  ARRAY_APPEND(fileStatusList,temp);
                  filenameTab:[_file_case(localFilename)] = &fileStatusList[fileStatusList._length()-1];
                  pInfo = &fileStatusList[fileStatusList._length()-1];
               }
               pInfo->filename = localFilename;
               pInfo->status |= SVC_STATUS_NOT_CONTROLED;
            }
         }
      }
      if ( missingFilesWID!=0 ) _delete_temp_view(missingFilesWID);
      return status;
   }

   private int getUnversionedFilesFromStatus(SVC_UPDATE_INFO (&fileStatusList)[],SVC_UPDATE_INFO *filenameTab:[],String &stdErrData) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      status = perforceRunCommand(maybe_quote_filename(exeStr)" status",auto missingFilesWID=0,stdErrData);
      maybeOutputWIDToLog(missingFilesWID,"getUnversionedFilesFromStatus stdout");
      maybeOutputStringToLog(stdErrData,"getUnversionedFilesFromStatus stderr");
      if ( status ) return status;

      origWID := p_window_id;

      p_window_id = missingFilesWID;

      top();up();
      while ( !down() ) {
         get_line(auto curLine);
         p := pos('^?@ \- reconcile to add ?@$',curLine,1,'r');
         if ( p ) {
            parse curLine with auto relFilename ' \- reconcile to add //?@$','r';
            localFilename := absolute(relFilename);
            SVC_UPDATE_INFO *pInfo = filenameTab:[_file_case(localFilename)];
            if ( pInfo==null ) {
               SVC_UPDATE_INFO temp;
               temp.filename = localFilename;
               temp.status   = 0 ;
               ARRAY_APPEND(fileStatusList,temp);
               filenameTab:[_file_case(localFilename)] = &fileStatusList[fileStatusList._length()-1];
               pInfo = &fileStatusList[fileStatusList._length()-1];
            }
            pInfo->filename = localFilename;
            pInfo->status |= SVC_STATUS_NOT_CONTROLED;
         }
      }

      p_window_id = origWID;
      _delete_temp_view(missingFilesWID);

      return status;
   }

   _str getSystemNameCaption() {
      return "Perforce";
   }

   _str getSystemSpecificInfo(_str fieldName) {
      switch (lowcase(fieldName)) {
      case "clientpath":
         if ( !m_gotViewInfo ) {
            getViewInfo();
         }
         return m_clientPath;
      case "localroot":
         if ( !m_gotViewInfo ) {
            getViewInfo();
         }
         return m_localRoot;
      case "localmachineinfo":
         if ( !m_gotViewInfo ) {
            getViewInfo();
         }
         return m_localMachineInfo;
      }
      return "";
   }

   int resolveFiles(_str (&localFilenames)[],_str comment=null,int options=0) {
      return 0;
   }

   int resolveFile(_str localFilename,_str comment=null,int options=0) {
      return 0;
   }

   _str getFixedUpdatePath(boolean forceCalculation=false) {
      if ( m_localRoot=="" && forceCalculation ) {
         getViewInfo();
      }
      fixedUpdatePath := m_localRoot;
      return fixedUpdatePath;
   }

   boolean hotkeyUsed(_str hotkeyLetter,boolean onMenu=true) {
      foreach ( auto curCap in m_captionTable ) {
         if ( pos('&'hotkeyLetter,curCap,1,'i') ) {
            return true;
         }
      }
      return false;
   }

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]) {
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

   SVCSystemSpecificFlags getSystemSpecificFlags() {
      return SVC_REQUIRES_EDIT;
   }
   int getURLChildDirectories(_str URLPath,STRARRAY &urlChildDirectories){
      return 0;
   }

   int checkout(_str URLPath,_str localPath,int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      return status;
   }
   int pushToRepository(_str path="",int options=0) {
      return 0;
   }
   int pullFromRepository(_str path="",int options=0){
      return 0;
   }
   _str localRootPath() {
      return "";
   }
   int getNumVersions(_str localFilename) {
      enumerateVersions(localFilename,auto versions);
      return versions._length();
   }
   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quiet=false) {
      //deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      origWID := p_window_id;
      origPath := getcwd();
      chdir(_file_path(localFilename),1);
      set_env("PWD",_file_path(localFilename));
      cmdLine := maybe_quote_filename(exeStr)" filelog -t -l "maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"getHistoryInformation cmdLine");
#if 1
      status = perforceRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData,0,localFilename);
#else
      status = _open_temp_view('c:\temp\p4test.txt',auto historyOutputWID,auto junkWID);
      String stdErrData;
#endif 
      chdir(origPath,1);
      set_env("PWD",origPath);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformation stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformation stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         if ( !quiet ) _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }

      p_window_id = historyOutputWID;
      top();
      get_line(auto curBranch);
      SVCHistoryAddFlags addFlags = ADDFLAGS_ASCHILD;
      index := 0;

      bottom();
      // Buffer created from pipes somehow gets an extra line at the bottom, 
      // just skip any blank lines
      for ( ;; ) {
         if ( up() ) break;
         get_line(auto curLine);
         if ( curLine!="" ) break;
      }
      // Now move back down to our "false bottom"
      down();

      if ( curBranch!="" ) {
         lp := lastpos('/',curBranch);
         if ( lp ) curBranch = substr(curBranch,1,lp);
//         index = addHistoryItem(index,addFlags,historyInfo,true,_pic_branch,curBranch);
      }

      hadParentBranch   := false;
      parentBranchIndex := -1;

      outerloop:
      for ( ;; ) {
         if ( up() ) break;
         get_line(auto curLine);
         comment := "";
         for ( ;; ) {
            if ( substr(curLine,1,1)!="\t" ) {
               if ( p_line==1 ) {
                  break outerloop;
               }
               break;
            }
            if ( comment=="" ) {
               comment = substr(curLine,2);
            } else {
               comment = substr(curLine,2)'<br>'comment;
            }
            if ( up() ) {
               break;
            }
            get_line(curLine);
         }
         parse curLine with "... " auto revision " change :i",'r' auto versionType " on " auto date_and_time " by " auto author '(' .;
         hadParentBranch = false;
         parentBranchIndex = -1;
         picIndex := _pic_file;
         skip := false;
         if ( substr(curLine,1,length(BRANCH_PREFIX)) == BRANCH_PREFIX 
              || substr(curLine,1,length(COPY_PREFIX)) == COPY_PREFIX 
              || substr(curLine,1,length(MERGE_PREFIX)) == MERGE_PREFIX
              || substr(curLine,1,length(IGNORE_PREFIX)) == IGNORE_PREFIX
              || substr(curLine,1,length(EDIT_PREFIX)) == EDIT_PREFIX ) {
            skip = true;
         }
         if ( revision!="" && !skip ) {
//            index = addHistoryItem(index,addFlags,historyInfo,false,picIndex,revision,author,date_and_time,comment);
            ARRAY_APPEND(versions,revision);
         }
         if ( hadParentBranch ) {
            addFlags = ADDFLAGS_ASCHILD;
            parentBranchIndex = index;
         } else {
            addFlags = ADDFLAGS_SIBLINGAFTER;
         }
      }

      _delete_temp_view(historyOutputWID);
      p_window_id = origWID;
      return 0;
   }
};
