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
#include "subversion.sh"

#import "cvsutil.e"
#import "diff.e"
#import "main.e"
#import "SubversionBuildFile.e"
#import "setupext.e"
#import "saveload.e"
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
#require "se/vc/QueuedVCCommandManager.e"
#import "wkspace.e"
#require "IVersionControl.e"
#require "sc/lang/String.e"
#endregion Imports

using sc.lang.String;
using se.datetime.DateTime;
using se.vc.vccache.VCBranch;
using se.vc.vccache.VCLabel;
using se.vc.vccache.VCRepositoryCache;
using se.vc.vccache.VCCacheManager;
using se.vc.vccache.VCBaseRevisionItem;
using se.vc.vccache.VCRevision;
using se.vc.vccache.QueuedVCCommand;
using se.vc.vccache.QueuedVCCommandManager;

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class Subversion : IVersionControl {
   private boolean m_debug = false;
   private _str m_captionTable[];
   private _str m_version = "";
   private int m_didDeferredInit = 0;
   private se.vc.vccache.VCCacheManager m_svnCacheManager;
   private QueuedVCCommandManager m_QueuedVCCommandManager;
   private typeless m_branchHistoryInfoHT:[]=null;
   private boolean m_ValidLocalPathTable:[];

   Subversion() {
      m_captionTable[SVC_COMMAND_COMMIT]  = "&Commit";
      m_captionTable[SVC_COMMAND_EDIT]    = "&Lock";
      m_captionTable[SVC_COMMAND_DIFF]    = "&Diff";
      m_captionTable[SVC_COMMAND_HISTORY] = "&History";
      m_captionTable[SVC_COMMAND_MERGE]   = "&Merge";
      m_captionTable[SVC_COMMAND_REVERT]  = "&Revert";
      m_captionTable[SVC_COMMAND_UPDATE]  = "&Update";
      m_captionTable[SVC_COMMAND_ADD]     = "&Add";
      m_captionTable[SVC_COMMAND_REMOVE]  = "Delete";
      m_captionTable[SVC_COMMAND_CHECKOUT]  = "Checkout";
      m_captionTable[SVC_COMMAND_BROWSE_REPOSITORY]  = "Browse repository";
      m_captionTable[SVC_COMMAND_HISTORY_DIFF] = "History Diff";


      VCCacheManager svnCacheManager();
      m_svnCacheManager = svnCacheManager;


      QueuedVCCommandManager newMgr();
      m_QueuedVCCommandManager = newMgr;
   }

   ~Subversion() {
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
      status = subversionRunCommand(maybe_quote_filename(exeStr)" version",auto versionWID=0,auto stdErrData);
      origWID := p_window_id;
      p_window_id = versionWID;
      top();
      get_line(auto curLine);
      parse curLine with "svn, version " m_version " " .;
      m_QueuedVCCommandManager.start();
      p_window_id = origWID;
      _delete_temp_view(versionWID);
   }


   private void getRemoteFilenameFromDiffScript(int scriptWID,_str &remoteFilename) {
      origWID := p_window_id;
      p_window_id = scriptWID;

      top();
      down(2);
      get_line(auto line);

      parse line with "--- " remoteFilename;
      remoteFilename = stranslate(remoteFilename,' ',"\t");

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
      if ( def_svn_info.svn_exe_name=="" || 
           !file_exists(def_svn_info.svn_exe_name) ) {
         _str exeName = "";
#if __UNIX__
         exeName='svn';
#else
         exeName="svn.exe";
#endif
         def_svn_info.svn_exe_name=path_search(exeName);
         if ( def_svn_info.svn_exe_name=="" || 
              !file_exists(def_svn_info.svn_exe_name) ) {
            return SVC_COULD_NOT_FIND_VC_EXE;
         }
      }
      exeStr = def_svn_info.svn_exe_name;
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
      if ( version=="" ) {
         // Be sure we have a version before we call getFile, it will default
         // to getting the same version that we have checked out
         getCurRevision(localFilename,version);
      }
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
#if 0 //8:57am 5/8/2013
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
         headOption = "-r HEAD ";
      }
      cmdLine := maybe_quote_filename(exeStr)" --non-interactive diff "versionSpec' 'headOption:+maybe_quote_filename(localFilename);
      maybeOutputStrToLog(cmdLine,"diffLocalFile cmdLine");
      status = subversionRunCommand(cmdLine,auto scriptWID=0,auto stdErrData);
      maybeOutputWIDToLog(scriptWID,"diffLocalFile stdout");
      maybeOutputStringToLog(stdErrData,"diffLocalFile stderr");
      if ( status || (length(stdErrData)>1 && scriptWID.p_Noflines==0) ) {
         status = SVC_COULD_NOT_COMPARE_FILE;
         _message_box(get_message(status,"compare",localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return status;
      }
      SubversionBuildFile bf;
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
#endif

      return 0;
   }

   private int subversionRunCommand(_str command,int &stdOutWID,String &stdErrData,int dataToWriteToStdinWID=0) {
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
            stdOutWID._insert_text(buf1,true);
            int len=stdOutWID._line_length(true);
            len=stdOutWID._text_colc(len+1,'I');
            stdOutWID.bottom();
            stdOutWID.p_col=len;
         }

         buf2='';
         _PipeRead(process_stderr_pipe,buf2,0,1);
         if ( buf2!='' ) {
            _PipeRead(process_stderr_pipe,buf2,length(buf2),0);
         }
         if ( hasBasicChallengeError(buf2) ) {
            getCommandLineWithUserNameAndPwd(command,auto newCommand="");
            if ( newCommand !="") {
               return subversionRunCommand(newCommand,stdOutWID,stdErrData,dataToWriteToStdinWID);
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

   private int getRevisionInfo(_str localFilename,_str &curRevision,_str &URL,_str &curLocalRevision="",_str &curBranch="",_str &repositoryRoot="") {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      deferedInit();
      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive info "maybe_quote_filename(localFilename),auto historyOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(historyOutputWID,"getRevisionInfo stdout");
      maybeOutputStringToLog(stdErrData,"getRevisionInfo stderr");
      if ( status ) return status;

      if ( stdErrData.getLength()>1 &&
           pos('not a working copy',stdErrData.get()) ) {
         _delete_temp_view(historyOutputWID);
         return SVC_COULD_NOT_GET_INFO;
      }

      origWID := p_window_id;
      p_window_id = historyOutputWID;
      top();up();
      status = search('^Last Changed Rev\: ','@ri');
      if ( !status ) {
         get_line(auto line);
         parse line with 'Last Changed Rev: ' curLocalRevision;
         curLocalRevision = 'r'curLocalRevision;
      }

      top();up();
      status = search('^URL\: ','@ri');
      if ( !status ) {
         get_line(auto line);
         parse line with 'URL: ' URL;
      }

      top();up();
      status = search('^Last Changed Rev\: ','@ri');
      if ( !status ) {
         get_line(auto line);
         parse line with 'Last Changed Rev: ' curRevision;
         if ( first_char(curRevision)!='r' ) {
            curRevision = 'r'curRevision;
         }
      }

      curPath := "";
      top();up();
      status = search('^Path\: ','@ri');
      if ( !status ) {
         get_line(auto line);
         parse line with 'Path: ' curPath;
      }

      repositoryRoot = "";
      top();up();
      status = search('^Repository Root\: ','@ri');
      if ( !status ) {
         get_line(auto line);
         parse line with 'Repository Root: ' repositoryRoot;
      }
      
      curBranch = URL;
      curBranch = substr(curBranch,1,length(URL)-length(curPath));

      p_window_id = origWID;
      return 0;
   }

   private int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",boolean quiet=false) {
      getRemoteFilename(localFilename,auto remoteFilename="");
      status := getRevisionInfo(remoteFilename,curRevision,URL);
      return status;
   }

   private int getCurLocalRevision(_str localFilename,_str &curLocalRevision,boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      status = getRevisionInfo(localFilename,auto curRevision="",auto URL="",curLocalRevision);
      if ( status ) return status;
      //status = getRevisionInfo(URL, curRevision,URL,curLocalRevision);
#if 0 //6:38pm 4/2/2013
      if (status) return status;

      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive log  "maybe_quote_filename(URL),auto historyOutputWID=0,auto stdErrData);
      if (status) return status;
      origWID := p_window_id;
      p_window_id = historyOutputWID;
      top();
      down();
      get_line(auto firstHistoryLine);
      parse firstHistoryLine with curLocalRevision ' |'.;
      p_window_id = origWID;
      _delete_temp_view(historyOutputWID);
#endif

      return status;
   }

   private int _SVNGetBranchForLocalFile(_str filename,_str &branchName,_str &repositoryRoot,_str &subFilename,_str &URL="") {
      repositoryRoot = subFilename = branchName = "";
      status := getRevisionInfo(filename,auto curRevision="",auto remote_filename="");
      //int status=_SVNGetFileURL(filename,remote_filename);
      if ( status ) {
         return(status);
      }
      status = getExeStr(auto exeStr);
      String StdOutData,StdErrData;
      subversionRunCommand(maybe_quote_filename(exeStr):+" info --xml ":+maybe_quote_filename(remote_filename),auto temp_wid=0,auto stdErrData);
      maybeOutputWIDToLog(temp_wid,"_SVNGetBranchForLocalFile stdout");
      maybeOutputStringToLog(stdErrData,"_SVNGetBranchForLocalFile stderr");
//      status=_CVSPipeProcess(maybe_quote_filename(exeStr):+" info --xml ":+maybe_quote_filename(remote_filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
//                             false,null,null,null,-1,false,false);
//      int orig_wid=_create_temp_view(auto temp_wid);
      orig_wid := p_window_id;
      // Took out insert-text of stderr from here, since it could cause the 
      // parse to fail when subversion gives warnings.
      //_insert_text(StdOutData.get());
      p_window_id=orig_wid;

      xmlhandle :=_xmlcfg_open_from_buffer(temp_wid,status,VSXMLCFG_OPEN_ADD_PCDATA);

      //repositoryRoot := "";
      if ( !status ) {
         urlIndex := _xmlcfg_find_simple(xmlhandle,"/info/entry/url");
         if ( urlIndex>-1 ) {
            pcDataIndex := _xmlcfg_get_first_child(xmlhandle,urlIndex,VSXMLCFG_NODE_PCDATA);
            if ( pcDataIndex>-1 ) {
               URL = _xmlcfg_get_value(xmlhandle,pcDataIndex);
            }
         }
         repositoryIndex := _xmlcfg_find_simple(xmlhandle,"/info/entry/repository/root");
         if ( repositoryIndex>-1 ) {
            pcDataIndex := _xmlcfg_get_first_child(xmlhandle,repositoryIndex,VSXMLCFG_NODE_PCDATA);
            if ( pcDataIndex>-1 ) {
               repositoryRoot = _xmlcfg_get_value(xmlhandle,pcDataIndex);
            }
         }
         branchName = URL;
         branchName = _strip_filename(branchName,'N');

         justPath := _file_path(filename);
#if 1
         // Use this code to pare branch name back to just the branch name without
         // the path piece
         _maybe_strip_filesep(justPath);
         _maybe_strip(branchName,'/');
         for ( ;; ) {
            lastdir_justPath   := _GetLastDirName(justPath);
            lastdir_branchName := _GetLastDirName(branchName);
            if ( lastdir_justPath!=lastdir_branchName ) break;

            branchName = _file_path(branchName);
            justPath = _file_path(justPath);

            _maybe_strip(branchName,'/');
            _maybe_strip_filesep(justPath);
         }
         subFilename = substr(remote_filename,length(branchName)+1);
         if ( first_char(subFilename)=='/' ) subFilename=substr(subFilename,2);
#endif 
      } else {
         SVCWriteToOutputWindow(stdErrData.get());
      }
      _xmlcfg_close(xmlhandle);
   //
   //   p_window_id=orig_wid;
   //   _delete_temp_view(temp_wid);
      return status;

   }
   private boolean svnCacheUpdateCommand(_str command,_str filename,_str repositoryRoot,boolean &runOldHistory) {
      runOldHistory = false;
      requiresAsyncUpdate := false;
      VCRepositoryCache cache = m_svnCacheManager.getSvnCache(repositoryRoot);
      if ( m_QueuedVCCommandManager.cacheUpdatePending(repositoryRoot,auto pcurVCCommand=null) ) {
         origMouPointer := p_mouse_pointer;
         mou_set_pointer(MP_DEFAULT);
         result := _message_box(nls("The version cache required for '%s' is currently being built.  The command you requested will be run when the version cache has finished building.\n\nWould you like to launch the non-branch history facility now?",filename,command),"",MB_YESNO);
         mou_set_pointer(origMouPointer);
         runOldHistory = (result==IDYES);
         requiresAsyncUpdate = true;

         if ( pcurVCCommand!=null ) {
            pcurVCCommand->addChild(command,filename);
         }

      }else{
         // check the timestamps to see if an async update is necessary (we don't want
         // the update to take too long and tie down slickedit)
         requiresAsyncUpdate = cache.requiresAsyncUpdate();

         // check to see if SVN is even able to get the history
         if (cache.isSvnCapable() == false) {
            // if not, flag that we need to run the old svn history
            runOldHistory = true;
            return true;
         }

         if ( requiresAsyncUpdate ) {
            origMouPointer := p_mouse_pointer;
            mou_set_pointer(MP_DEFAULT);
            result := _message_box(nls("Before showing history for '%s', a version cache must be built for %s.  The command you requested will be run when the version cache has finished building.\n\nWould you like to launch the non-branch history facility now?",filename,repositoryRoot),"",MB_YESNO);
            mou_set_pointer(origMouPointer);
            runOldHistory = (result==IDYES);
            cache.updateVersionCache(true);
            QueuedVCCommand vcCommand(cache,command,filename,repositoryRoot);
            m_QueuedVCCommandManager.add(vcCommand);
            // show an alert
            _str msg = 'Sync for SVN repository 'cache.get_RepositoryUrl()' has started.';
            _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_SVN_CACHE_SYNC, msg);
         }else{
            cache.updateVersionCache(false);
         }
      }

      return requiresAsyncUpdate;
   }

   private int getHistoryInformationForAllBranches(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0) {
      int status = 0;
      status = getRevisionInfo(localFilename,auto curRevision="",auto URL="",auto curLocalRevision="",auto curBranch="",auto repositoryRoot="");
      if ( URL=="" ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,"Could not get remote filename"));
         return 1;
      }
      svnCacheUpdateCommand("svc_history",localFilename,repositoryRoot,auto runOldHistory=false);
      if ( runOldHistory ) {
         // The dialog will be shown when we return to svc_history, just get the
         // information.
         status = getHistoryInformationForCurrentBranch(localFilename,historyInfo,options);
      } else {
         VCRepositoryCache cache = m_svnCacheManager.getSvnCache(repositoryRoot);
         dbFilename := cache.get_CacheFileName();
         status = vsVCCacheGetHistory(localFilename,dbFilename,historyInfo,def_svn_info.svn_exe_name);
         maybeOutputStrToLog('localFilename='localFilename' dbFilename='dbFilename,"getHistoryInformationForAllBranches");
         maybeOutputStrToLog('historyInfo._length()='historyInfo._length(),"getHistoryInformationForAllBranches");
      }

      return status;
   }

   private int getSVNShowBranches(boolean &showBranches) {
      showBranches = false;
      if ( !(def_svn_flags&SVN_FLAG_DO_NOT_PROMPT_FOR_BRANCHES) ) {
         // If the user has not chosen to not prompt, show the form.
         status := show('-modal _svn_history_choose_form');
         if ( status=="" ) return COMMAND_CANCELLED_RC;
         showBranches = _param1;
      }else{
         // If the user has chosen to not prompt, user def_svn_flags&SVN_FLAG_SHOW_BRANCHES
         if ( def_svn_flags&SVN_FLAG_SHOW_BRANCHES ) {
            showBranches = true;
         }
      }
      return 0;
   }

   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0) {
      //deferedInit();
      status := 0;
      showBranches := false;
      if ( options==SVC_HISTORY_NOT_SPECIFIED ) {
         getSVNShowBranches(showBranches);
      } else if (options==SVC_HISTORY_NO_BRANCHES) {
         showBranches = false;
      } else  if (options==SVC_HISTORY_WITH_BRANCHES) {
         showBranches = true;
      }

      if ( showBranches && options!=SVC_HISTORY_NO_BRANCHES ) {
         status = getHistoryInformationForAllBranches(localFilename,historyInfo,options);
      } else {
         status = getHistoryInformationForCurrentBranch(localFilename,historyInfo,options);
      }

      return status;
   }

   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0) {
      status := getHistoryInformationForCurrentBranch(URL,historyInfo,options,dateBack);
      return status;
   }

   private void addBranchToURLTable(_str branchName,_str repositoryRoot,_str (&branchToURLTable):[]) {
      _maybe_strip(repositoryRoot,'/');
      if ( branchToURLTable:[repositoryRoot:+branchName'/']!=null ) {
         branchToURLTable:[repositoryRoot:+branchName'/'] = branchName'/';
      }
   }

   private void addLabelsToURLTable(VCLabel (&labels)[], _str repositoryRoot,_str (&branchToURLTable):[]) {
      _maybe_strip(repositoryRoot,'/');
      VCLabel curLabel;
      foreach ( curLabel in labels ) {
         labelName := curLabel.get_Name();
         branchToURLTable:[repositoryRoot:+labelName'/'] = labelName'/';
      }
   }

   private _str svnGetFormattedDate(_str unformattedDate) {
      formattedDate := substr(unformattedDate,1,4):+'-':+substr(unformattedDate,5,2):+'-'\
         :+substr(unformattedDate,7,2):+' T':+substr(unformattedDate,9,2):+':'\
         :+substr(unformattedDate,11,2):+':':+substr(unformattedDate,13,2):+'.'\
         :+substr(unformattedDate,15)'Z';
      return formattedDate;
   }

   private void populateFromCache(_str filename,VCRepositoryCache& cache,VCBaseRevisionItem& item,
                                  SVCHistoryInfo (&historyInfo)[],
                                  VCLabel(&labels)[],
                                  int (&revisionList)[],
                                  int (&revisionIndexList):[],
                                  int (&branchTable):[],
                                  _str (&URLToBranchTable):[],
                                  int(&indexTable):[]=null,
                                  int relIndex=TREE_ROOT_INDEX,SVCHistoryAddFlags addFlags=ADDFLAGS_ASCHILD)
   {
      int i = 0;
      
      if (item instanceof VCBranch) {
         // if this is a branch item, then print the details for it and recurse the children   
         VCBranch branch = (VCBranch)item;
         //say(padding"B- "branch.get_HistoryInsertionNumber()", "branch.get_Number()", "branch.get_Name()", "branch.get_Author()", "branch.get_Timestamp()"): "branch.get_Comments());
         int numChildren = branch.getChildItemCount();
         int expandBranch = numChildren>0?1:-1;

         _str branchName = branch.get_Name();
         split(branchName, '/', auto branchParts);
         if ( branchParts._length() >= 4) return;

         repositoryRoot := m_branchHistoryInfoHT:["repositoryRoot"];
         addBranchToURLTable(branchName,repositoryRoot,URLToBranchTable);
//         branchIndex := _TreeAddItem(relIndex,branchName,treeAddFlags,_pic_branch,_pic_branch,expandBranch);
//         say('populateFromCache 10 add 'branchName' relIndex='historyInfo[relIndex].revision);
         branchIndex := addHistoryItem(relIndex,addFlags,historyInfo,true,_pic_branch,
                                       branchName,
                                       branch.get_Author(),
                                       branch.get_Timestamp(),
                                       branch.get_Comments());

         branchTable:[branch.get_BranchID()] = branchIndex;
         for (i = 0; i < numChildren; i++) {
            //printRevisionTreeItem(*branch.getChildItem(i), padding:+"  ");
            populateFromCache(filename,cache,*branch.getChildItem(i),
                              historyInfo,labels,revisionList,
                              revisionIndexList,branchTable,URLToBranchTable,
                              indexTable,branchIndex,addFlags);
         }
      } else if (item instanceof VCRevision) {
         // if this is a revision item, then print the details for it
         VCRevision revision = (VCRevision)item;
         //say(padding"R- "revision.get_HistoryInsertionNumber()", "revision.get_Number()", "revision.get_Author()", "revision.get_Timestamp()"): "revision.get_Comments());
         revisionNumber := revision.get_Number();
//         revisionIndex := _TreeAddItem(relIndex,'r':+revisionNumber,treeAddFlags,_pic_file,_pic_file,-1);
         indexTable:[revisionNumber] = relIndex;
         
         _str lineArray[];
         lineArray[0]='<B>Author:</B>&nbsp;'revision.get_Author()'<br>';
         formattedDate := svnGetFormattedDate(revision.get_Timestamp());
         DateTime revisionDate = DateTime.fromString(formattedDate);
         lineArray[lineArray._length()]='<B>Date:</B>&nbsp;'revisionDate.toStringLocal()'<br>';
         _str rawComments = revision.get_Comments();
         _str commentsBR = stranslate(rawComments, '<br>', '\n', 'l');
         lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentsBR;

         revisionIndex := addHistoryItem(relIndex,addFlags,historyInfo,false,_pic_file,
                                         'r':+revisionNumber,
                                         revision.get_Author(),  //revisionTable:[curRevision].author,
                                         revision.get_Timestamp(),
                                         commentsBR);

         revisionID := revision.get_RevisionID();
         revisionList[revisionList._length()] = revisionID;
         revisionIndexList:[revisionID] = revisionIndex;
//         _TreeSetUserInfo(revisionIndex,lineArray);
      }
   }

   private int getIndexForVersion(VCLabel &curLabel,int posInBranch,int branchIndex,
                                  SVCHistoryInfo (&historyInfo)[]) {
      index := -1;
      childIndex := historyInfo[branchIndex].firstChildIndex;
      if ( childIndex>-1 ) {
         lastIndex := childIndex;
         for ( ;; ) {
            if ( historyInfo[branchIndex].picIndex!=_pic_branch ) {
               curVer := substr(historyInfo[branchIndex].revision,2);
               if ( isinteger(curVer) && (int)curVer > posInBranch ) {
                  break;
               }
               lastIndex = childIndex;
            }
            childIndex = historyInfo[childIndex].rsibIndex;
            if ( childIndex<0 ) break;
         }
         if ( lastIndex>-1 ) {
            //cap := _TreeGetCaption(lastIndex);
            //parse cap with cap ' -- (' auto labels ')';
            //if ( labels!='' ) labels = labels:+', ';
            //labels = labels:+curLabel.get_Name();
            //_TreeSetCaption(lastIndex,cap' -- ('labels')');
            index = lastIndex;
         }
      }
      return index;
   }

   private void addTagsToTree(VCLabel (&labels)[],int(&branchTable):[],_str &labelText,
                              SVCHistoryInfo (&historyInfo)[]) {
      VCLabel curLabel;
      foreach ( curLabel in labels ) {
         parentBranchID := curLabel.get_ParentBranchID();
         posInBranch    := curLabel.get_HistoryInsertionNumber();
         branchIndex := branchTable:[parentBranchID];
         if ( branchIndex!=null ) {
            index := getIndexForVersion(curLabel,(int)posInBranch,(int)branchIndex,historyInfo);
            labelText = labelText:+"<P><A href=\"":+index:+"\">":+curLabel.get_Name():+"<A>";
            if ( def_svn_flags&SVN_FLAG_SHOW_LABELS_IN_HISTORY ) {
               // Have to check this flag here because even if this flag is off we 
               // this is where labelText gets set
               if ( index<0 ) {
                  // If there are no items, put the tag right on the branch
                  index = branchIndex;
               }
               if ( index>-1 ) {
                  curCap := historyInfo[index].revision;
                  tags   := "";
                  if ( last_char(curCap)==')' ) {
                     parse curCap with curCap '(' tags ')';
                     tags = tags:+', ';
                  }
                  //_TreeSetCaption(index,strip(curCap):+' (':+strip(tags):+curLabel.get_Name():+')');
                  historyInfo[index].revision = strip(curCap):+' (':+strip(tags):+curLabel.get_Name():+')';
               }
            }
         }
      }
   }

   private void trackEmptyBranches(int(&branchTable):[],
                                  SVCHistoryInfo (&historyInfo)[] ) {
      int curIndex;
      _str hashIndex = "";
      int hiddenIndexes[];

      foreach ( hashIndex => curIndex in branchTable ) {
         if ( curIndex!=null ) {
            childIndex := historyInfo[curIndex].firstChildIndex;
            if ( childIndex<0 ) {
//               _TreeGetInfo(curIndex,auto ShowChildren,auto NonCurrentBMIndex,auto CurrentBMIndex,auto moreFlags);
//               _TreeSetInfo(curIndex,ShowChildren,NonCurrentBMIndex,CurrentBMIndex,moreFlags|TREENODE_HIDDEN);
               ARRAY_APPEND(hiddenIndexes,curIndex);
            }
         }
      }
      m_branchHistoryInfoHT:["hiddenIndexes"] = hiddenIndexes;
   }

   private int getHistoryInformationForCurrentBranch(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0,se.datetime.DateTime dateBack=null) {
      if ( localFilename=="" ) {
         return 1;
      }
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      SVCHistoryFileInfo dialogInfo=null;
      status = getLocalFileURL(localFilename,auto URL="");
#if 1
      dateBackStr := "";
      if ( dateBack!=null ) {
         dateBackStr = dateBack.year()'-'dateBack.month()'-'dateBack.day();
      }
      status = vsGetSVNHistoryForCurrentBranch(URL,historyInfo,dateBackStr,exeStr);
#else
      versionSpec := "";
      if ( firstRevision!="" ) {
         versionSpec = '-r'firstRevision;
         if ( numVersions!=-1 ) {
            versionSpec = versionSpec':'((int)firstRevision-(int)numVersions);
         }
      } else if ( numVersions>-1 ) {
         versionSpec = '-l'numVersions;
      }
      cmdLine := maybe_quote_filename(exeStr)" --non-interactive log  --stop-on-copy --verbose --xml "versionSpec' 'maybe_quote_filename(URL);
      say('getHistoryInformationForCurrentBranch cmdLine='cmdLine);
      status = subversionRunCommand(cmdLine,auto historyOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(historyOutputWID,"getHistoryInformationForCurrentBranchk stdout");
      maybeOutputStringToLog(stdErrData,"getHistoryInformationForCurrentBranch stderr");
      if ( status || (length(stdErrData)>1 && historyOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_GET_HISTORY_INFO,localFilename,stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
         return SVC_COULD_NOT_GET_HISTORY_INFO;
      }
      xmlhandle := _xmlcfg_open_from_buffer(historyOutputWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
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
         newItemIndex := addHistoryItem(index,addFlags,historyInfo,false,_pic_file,
                                        'r'curRevision,
                                        revisionTable:[curRevision].author,
                                        revisionTable:[curRevision].date,
                                        revisionTable:[curRevision].comment,
                                        revisionTable:[curRevision].affectedFilesDetails);
      }
      _xmlcfg_close(xmlhandle);
      _delete_temp_view(historyOutputWID);
#endif
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

   private int getLocalFileURL(_str localFilename,_str &URL) {
      // Calling deferedInit() in getCurRevision()
      getRevisionInfo(localFilename,auto curRevision="",URL);
      return 0;
   }
   int getLocalFileBranch(_str localFilename,_str &URL) {
      // Calling deferedInit() in getCurRevision()
      getRevisionInfo(localFilename,auto curRevision="","","",URL);
      return 0;
   }

   void getVersionNumberFromVersionCaption(_str revisionCaption,_str &versionNumber) {
      versionNumber = revisionCaption;
      if ( first_char(versionNumber)=='r' ) {
         versionNumber = substr(versionNumber,2);
      }
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
         versionStr = "-r "version;
      }
      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive cat "versionStr' ' maybe_quote_filename(localFilename),fileWID,auto stdErrData);
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

   int getRemoteFilename(_str localFilename,_str &remoteFilename) {
      status := getExeStr(auto exeStr);
      remoteFilename = "";
      getRevisionInfo(localFilename,auto curRevision="",remoteFilename);
      deferedInit();
      return 0;
   }

   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      deferedInit();
      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive status --show-updates "maybe_quote_filename(localFilename),auto statusOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(statusOutputWID,"getFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getFileStatus stderr");
      if ( status ) return status;
      origWID := p_window_id;
      p_window_id = statusOutputWID;


      fileStatus = 0;
      top();
      get_line(auto newLine);
      ch := substr(newLine,1,1);
      switch ( upcase(ch) ) {
      case 'A':
         fileStatus |= SVC_STATUS_SCHEDULED_FOR_ADDITION;
         break;
      case 'C':
         fileStatus |= SVC_STATUS_CONFLICT;
         break;
      case 'D':
         fileStatus |= SVC_STATUS_SCHEDULED_FOR_DELETION;
         break;
      case 'M':
         fileStatus |= SVC_STATUS_MODIFIED;
         break;
      case '!':
         fileStatus |= SVC_STATUS_MISSING;
         break;
      case '?':
         fileStatus |= SVC_STATUS_NOT_CONTROLED;
         break;
      }

      ch = substr(newLine,2,1);
      switch ( upcase(ch) ) {
      case 'C':
         fileStatus |= SVC_STATUS_PROPS_ICONFLICT;
         break;
      case 'M':
         fileStatus |= SVC_STATUS_PROPS_MODIFIED;
         break;
      }

      ch = substr(newLine,3,1);
      switch ( upcase(ch) ) {
      case 'L':
         fileStatus |= SVC_STATUS_LOCKED;
         break;
      }

      ch = substr(newLine,4,1);
      switch ( upcase(ch) ) {
      case 'L':
         fileStatus |= SVC_STATUS_SCHEDULED_WITH_COMMIT;
         break;
      }

      ch = substr(newLine,5,1);
      switch ( upcase(ch) ) {
      case 'S':
         fileStatus |= SVC_STATUS_SWITCHED;
         break;
      case 'X':
         fileStatus |= SVC_STATUS_NEWER_REVISION_EXISTS;
         break;
      }

      ch = substr(newLine,6,1);
      switch ( upcase(ch) ) {
      case 'K':
         fileStatus |= SVC_STATUS_EDITED;
         break;
      }

      ch = substr(newLine,9,1);
      switch ( upcase(ch) ) {
      case '*':
         fileStatus |= SVC_STATUS_NEWER_REVISION_EXISTS;
         break;
      }

      p_window_id = origWID;
      _delete_temp_view(statusOutputWID);
      return 0;
   }

   int updateFiles(_str (&localFilenames)[],int options=0) {
      if ( localFilenames._length()==0 ) {
         // Nothing to do
         return 0;
      }
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      cmdLineBase := maybe_quote_filename(exeStr)" --non-interactive update ";
      buildCommandLineFileList(localFilenames,cmdLineBase,auto cmdLineLists);

      len := cmdLineLists._length();
      status = 0;
      mou_hour_glass(1);
      do {
         for ( i:=0;i<len;++i ) {
            status = subversionRunCommand(cmdLineLists[i],auto updateOutputWID=0,auto stdErrData);
            maybeOutputWIDToLog(updateOutputWID,"updateFiles stdout");
            maybeOutputStringToLog(stdErrData,"updateFiles stderr");
            if ( status || (length(stdErrData)>1 && updateOutputWID.p_Noflines==0) ) {
               exe := parse_file(cmdLineLists[i]);
               parse cmdLineLists[i] with auto updateStr cmdLineLists[i];
               firstFile := parse_file(cmdLineLists[i]);
               _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"update",firstFile,stdErrData));
               status = SVC_COULD_NOT_UPDATE_FILE;
               SVCWriteToOutputWindow(stdErrData.get());
               break;
            }
            SVCWriteWIDToOutputWindow(updateOutputWID);
            _delete_temp_view(updateOutputWID);
         }
         _reload_vc_buffers(localFilenames);
         _retag_vc_buffers(localFilenames);
      } while (false);
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

   private void buildCommandLineFileList(_str (&localFilenames)[],_str cmdLineBase,_str (&commandLineLists)[],boolean disregardFilesAfterParentPath=true) {

      if ( disregardFilesAfterParentPath ) {
         // First figure out how many directories we have and if we can disregard 
         // files from those directories
         localFilenames._sort('f'_fpos_case);
         len := localFilenames._length();

         _str directoryTable:[];
         for ( i:=0;i<len;++i ) {
            cur := localFilenames[i];
            if ( last_char(cur)==FILESEP ) {
               directoryTable:[_file_case(cur)] = "";
            }
         }

         for ( i=0;i<len;++i ) {
            cur := localFilenames[i];
            curPath := _file_path(cur);
            if ( directoryTable:[_file_case(curPath)]!=null ) {
               localFilenames._deleteel(i);
               --i;--len;
            }
         }

         if ( !localFilenames._length() ) {
            i = 0;
            foreach ( auto curKey => auto curValue in directoryTable ) {
               localFilenames[i++] = curKey;
            }
         }
      }

      updateBase := 0;
      // 3/12/2013 - Subversion was introduced Changelists in 1.5 (in June 2008).
      //             Eventually, this should be done in chnagelists, but right now
      //             it is a little early.
      len := localFilenames._length();
//      outerloop:
      for ( currentCommandLine:=0 ;;++currentCommandLine ) {
         cmdLine := cmdLineBase;
         for ( i:=0;i<200;++i ) {
            if ( i+updateBase>=len ) break;
            cmdLine = cmdLine' 'maybe_quote_filename(localFilenames[updateBase+i]);
         }
         commandLineLists[currentCommandLine] = cmdLine;
         if ( i+updateBase>=len ) break;
      }
   }

   int updateFile(_str localFilename,int options=0) {
      // Call deferedInit() in updateFiles()
      STRARRAY tempFilenames;
      tempFilenames[0] = localFilename;
      status := updateFiles(tempFilenames,options);
      return status;
   }

   int revertFiles(_str (&localFilenames)[],int options=0) {
      if ( localFilenames._length()<=0 ) {
         return 1;
      }
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      writeToTargetFile(localFilenames,auto targetFilename);

      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive revert --targets "maybe_quote_filename(targetFilename),auto commitOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(commitOutputWID,"revertFiles stdout");
      maybeOutputStringToLog(stdErrData,"revertFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"revert",localFilenames[0],stdErrData));
         SVCWriteToOutputWindow(stdErrData.get());
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

            cmd := maybe_quote_filename(exeStr)" --non-interactive commit -F "maybe_quote_filename(commentFilename)" --targets "maybe_quote_filename(targetFilename);
            status = subversionRunCommand(cmd,commitOutputWID,auto stdErrData);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"commit",localFilenames[0],stdErrData));
               delete_file(targetFilename);
               SVCWriteToOutputWindow(stdErrData.get());
               return SVC_COULD_NOT_UPDATE_FILE;
            }
            SVCWriteWIDToOutputWindow(commitOutputWID);
            delete_file(commentFilename);
            _delete_temp_view(commitOutputWID);
            delete_file(targetFilename);
            break;
         } else {
            status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive commit -F "maybe_quote_filename(commentFilename)' 'localFilenames[i],commitOutputWID,auto stdErrData);
            maybeOutputWIDToLog(commitOutputWID,"commitFiles stdout");
            maybeOutputStringToLog(stdErrData,"commitFiles stderr");
            if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
               _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"commit",localFilenames[0],stdErrData));
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

   private int writeToTargetFile(_str (&localFilenames)[],_str &targetFilename) {
      origWID := _create_temp_view(auto fileListWID);
      len := localFilenames._length();
      for ( i:=0;i<len;++i ) {
         curFileName := localFilenames[i];
         if ( last_char(curFileName)==FILESEP ) {
            curFileName = substr(curFileName,1,length(curFileName)-1);
         }
         insert_line(curFileName);
      }
      targetFilename = mktemp();
      status := _save_file("+o "targetFilename);
      p_window_id = origWID;
      _delete_temp_view(fileListWID);
      return status;
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
      
      return status;
   }

   int getURLChildDirectories(_str URLPath,STRARRAY &urlChildDirectories) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      mou_hour_glass(1);
      status = 0;
      do {
         status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive --xml ls "URLPath,auto lsOutputWID=0,auto stdErrData);
         maybeOutputWIDToLog(lsOutputWID,"getURLChildDirectories stdout");
         maybeOutputStringToLog(stdErrData,"getURLChildDirectories stderr");
         if ( status || (length(stdErrData)>1 && lsOutputWID.p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_LIST_URL,URLPath));
            status =  SVC_COULD_NOT_LIST_URL;
            SVCWriteToOutputWindow(stdErrData.get());
            break;
         }
         xmlhandle :=_xmlcfg_open_from_buffer(lsOutputWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
         if ( xmlhandle>-1 ) {
            entryIndex := _xmlcfg_find_simple_array(xmlhandle,"/lists/list/entry",auto indexList);
            len := indexList._length();
            for (i:=0;i<len;++i) {
               kind := _xmlcfg_get_attribute(xmlhandle,(int)indexList[i],"kind");
               if ( kind=="dir" ) {
                  nameIndex := _xmlcfg_find_child_with_name(xmlhandle,(int)indexList[i],"name");
                  if ( nameIndex>-1 ) {
                     pcDataIndex := _xmlcfg_get_first_child(xmlhandle,nameIndex,VSXMLCFG_NODE_PCDATA);
                     if ( pcDataIndex>-1 ) {
                        dir := _xmlcfg_get_value(xmlhandle,pcDataIndex);
                        ARRAY_APPEND(urlChildDirectories,dir);
                     }
                  }
               }
            }
            _xmlcfg_close(xmlhandle);
            _delete_temp_view(lsOutputWID);
         }
      } while (false);
      mou_hour_glass(0);
      return status;
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
      do {
         status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive checkout ":+URLPath:+" ":+localPath,checkoutOutputWID,auto stdErrData);
         maybeOutputWIDToLog(checkoutOutputWID,"checkout stdout");
         maybeOutputStringToLog(stdErrData,"checkout stderr");
         if ( status || (length(stdErrData)>1 && checkoutOutputWID.p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_LIST_URL,URLPath));
            SVCWriteToOutputWindow(stdErrData.get());
            status =  SVC_COULD_NOT_LIST_URL;
            break;
         }
      } while(false);
      SVCWriteWIDToOutputWindow(checkoutOutputWID);
      _delete_temp_view(checkoutOutputWID);

      return status;
   }

   SVCCommandsAvailable commandsAvailable() {
      return SVC_COMMAND_AVAILABLE_COMMIT\
         |SVC_COMMAND_AVAILABLE_EDIT\
         |SVC_COMMAND_AVAILABLE_DIFF\
         |SVC_COMMAND_AVAILABLE_HISTORY\
         |SVC_COMMAND_AVAILABLE_MERGE\
         |SVC_COMMAND_AVAILABLE_REVERT\
         |SVC_COMMAND_AVAILABLE_ADD\
         |SVC_COMMAND_AVAILABLE_REMOVE\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT\
         |SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE\
         |SVC_COMMAND_AVAILABLE_UPDATE\
         |SVC_COMMAND_AVAILABLE_GET_URL_CHILDREN\
         |SVC_COMMAND_AVAILABLE_CHECKOUT\
         |SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY\
         |SVC_COMMAND_AVAILABLE_HISTORY_DIFF;
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
      deferedInit();
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }

      writeToTargetFile(localFilenames,auto targetFilename);

      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive lock --targets "maybe_quote_filename(targetFilename),auto commitOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(commitOutputWID,"editFiles stdout");
      maybeOutputStringToLog(stdErrData,"editFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_UPDATE_FILE,"lock",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);
      delete_file(targetFilename);

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

      writeToTargetFile(localFilenames,auto targetFilename);

      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive add --targets "maybe_quote_filename(targetFilename),auto commitOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(commitOutputWID,"addFiles stdout");
      maybeOutputStringToLog(stdErrData,"addFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_ADD_FILE,"add",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);
      delete_file(targetFilename);

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

      writeToTargetFile(localFilenames,auto targetFilename);

      result := _message_box(nls("This will remove local files.\n\nContinue?"),"",MB_YESNO);
      if ( result!=IDYES ) {
         return COMMAND_CANCELLED_RC;
      }
      status = subversionRunCommand(maybe_quote_filename(exeStr)" --non-interactive remove --targets "maybe_quote_filename(targetFilename),auto commitOutputWID=0,auto stdErrData);
      maybeOutputWIDToLog(commitOutputWID,"removeFiles stdout");
      maybeOutputStringToLog(stdErrData,"removeFiles stderr");
      if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
         SVCWriteToOutputWindow(stdErrData.get());
         _message_box(get_message(SVC_COULD_NOT_DELETE_FILE,"remove",localFilenames[0],stdErrData));
         return SVC_COULD_NOT_UPDATE_FILE;
      }
      SVCWriteWIDToOutputWindow(commitOutputWID);
      _delete_temp_view(commitOutputWID);
      delete_file(targetFilename);

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

      writeToTargetFile(localFilenames,auto targetFilename);

      yes := _message_box(nls("Run 'svn resolve --accept working' for all selected files?"),"",MB_YESNO);

      if ( yes ) {
         status = subversionRunCommand(maybe_quote_filename(exeStr)" resolve --accept working --targets "maybe_quote_filename(targetFilename),auto commitOutputWID=0,auto stdErrData);
         maybeOutputWIDToLog(commitOutputWID,"resolveFiles stdout");
         maybeOutputStringToLog(stdErrData,"resolveFiles stderr");
         if ( status || (length(stdErrData)>1 && commitOutputWID.p_Noflines==0) ) {
            _message_box(get_message(SVC_COULD_NOT_RESOLVE_FILE,"resolve",localFilenames[0],stdErrData));
            SVCWriteToOutputWindow(stdErrData.get());
            return SVC_COULD_NOT_RESOLVE_FILE;
         }
         SVCWriteWIDToOutputWindow(commitOutputWID);
         _delete_temp_view(commitOutputWID);
         delete_file(targetFilename);
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

      recurseOption := recursive?"":"--depth=files";


      cmdLine := maybe_quote_filename(exeStr)" --non-interactive status --xml --show-updates ":+recurseOption:+' ':+maybe_quote_filename(localPath);
      maybeOutputStrToLog(cmdLine,"getMultiFileStatus command");
      status = subversionRunCommand(cmdLine,auto statusWID=0,auto stdErrData);
      maybeOutputWIDToLog(statusWID,"getMultiFileStatus stdout");
      maybeOutputStringToLog(stdErrData,"getMultiFileStatus stderr");
      if ( status || (length(stdErrData)>1 && statusWID.p_Noflines==0) ) {
         status = SVC_COULD_NOT_GET_FILE_STATUS;
         _message_box(get_message(status,stdErrData));
         _delete_temp_view(statusWID);
         return status;
      }
      xmlhandle := _xmlcfg_open_from_buffer(statusWID,status);
      if ( xmlhandle<0 ) {
         _message_box(get_message(SVC_COULD_NOT_GET_FILE_STATUS,localPath,stdErrData));
         _delete_temp_view(statusWID);
         return SVC_COULD_NOT_GET_FILE_STATUS;
      }
      STRARRAY fileIndexes;
      boolean pathTable:[];
      _xmlcfg_find_simple_array(xmlhandle,"//entry",fileIndexes);
      len := fileIndexes._length();
      for ( i:=0; i<len; ++i ) {
         curIndex := (int)fileIndexes[i];
         path := _xmlcfg_get_attribute(xmlhandle,curIndex,"path");

         justPath := _file_path(path);
         if ( last_char(justPath)==FILESEP ) {
            justPath = substr(justPath,1,length(justPath)-1);
         }
         pathTable:[_file_case(justPath)] = false;
         if ( pathTable._indexin(_file_case(path)) ) {
            pathTable:[_file_case(path)] = true;
         }

         SVC_UPDATE_INFO cur;
         cur.filename = path;
         cur.status   = 0;
         workingCopyStatusIndex := _xmlcfg_find_child_with_name(xmlhandle,curIndex,"wc-status");
         if ( workingCopyStatusIndex>=0 ) {
            item := _xmlcfg_get_attribute(xmlhandle,workingCopyStatusIndex,"item");
            if ( item=="modified" ) {
               cur.status |= SVC_STATUS_MODIFIED;
            } else if ( item=="unversioned" ) {
               cur.status |= SVC_STATUS_NOT_CONTROLED;
            } else if ( item=="added" ) {
               cur.status |= SVC_STATUS_SCHEDULED_FOR_ADDITION;
            } else if ( item=="conflicted" ) {
               cur.status |= SVC_STATUS_CONFLICT;
            }
            item = _xmlcfg_get_attribute(xmlhandle,workingCopyStatusIndex,"props");
            if ( item=="modified" ) {
               cur.status |= SVC_STATUS_PROPS_MODIFIED;
            }
         }
         repositoryCopyStatusIndex := _xmlcfg_find_child_with_name(xmlhandle,curIndex,"repos-status");
         if ( repositoryCopyStatusIndex>=0 ) {
            item := _xmlcfg_get_attribute(xmlhandle,repositoryCopyStatusIndex,"item");
            if ( item=="modified" ) {
               cur.status |= SVC_STATUS_NEWER_REVISION_EXISTS;
            } else if ( item=="added" ) {
               cur.status |= SVC_STATUS_NEWER_REVISION_EXISTS;
            } else if ( item=="deleted" ) {
               cur.status |= SVC_STATUS_DELETED;
            }
            item = _xmlcfg_get_attribute(xmlhandle,repositoryCopyStatusIndex,"props");
            if ( item=="modified" ) {
               cur.status |= SVC_STATUS_PROPS_NEWER_EXISTS;
            }
         }
         ARRAY_APPEND(fileStatusList,cur);
      }

      // Remove certain items (things that are just paths, we handle these 
      // differently in the code for the dialog itself
#if 0 //11:39am 3/22/2013
      foreach ( auto curKey => auto curValue in pathTable ) {
         if ( curValue ) {
            len = fileStatusList._length();
            for ( i=0;i<len;++i ) {
               if ( file_eq(curKey,_file_case(fileStatusList[i].filename)) ) {
                  fileStatusList._deleteel(i);
                  --i;--len;
               }
            }
         }
      }
#endif

      _xmlcfg_close(xmlhandle);
      _delete_temp_view(statusWID);

      return status;
   }

   private _str getSVNConfigPath() {
      configPath := _ConfigPath();
      _maybe_append_filesep(configPath);
      configPath = configPath:+"svc":+FILESEP:+"svnconfig";
      return configPath;
   }

   _str getSystemNameCaption() {
      return "Subversion";
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

   private boolean svnIsCheckedoutPath(_str localPath,_str URL) {
      urlExists := false;
      if ( m_ValidLocalPathTable:[_file_case(localPath)]==null ) {
         
         _maybe_append_filesep(localPath);
         status := 0;
         if ( !path_exists(localPath:+SUBVERSION_CHILD_DIR_NAME) ) {
            status = 1;
         } else {
   #if 0 //10:56am 4/18/2011
            // For the sake of performance, it is sufficient to check for a .svn/
            // directory.  If we get a false positive, svn will fail when it runs 
            // later.  We are not saving any URL info so there is no need to run 
            // this
            status = _SVNGetFileURL(localPath,auto remote_filename);
   #else
            status = 0;
   #endif
         }
         urlExists = !status;
         m_ValidLocalPathTable:[_file_case(localPath)] = urlExists;
      }else{
         urlExists = m_ValidLocalPathTable:[_file_case(localPath)];
      }
      return urlExists;
   }

   private void getTopSVNPath(_str curPath,_str topPath,_str &topSVNPath) {
      lastCurPath := curPath;
      for ( ;; ) {
         if ( !_pathIsParentDirectory(curPath,topPath) ) {
            topSVNPath = lastCurPath;
            break;
         }
         validSVNPath := svnIsCheckedoutPath(curPath,auto curURL="");
         if ( !validSVNPath ) {
            topSVNPath = lastCurPath;
            break;
         }
         lastCurPath = curPath;
         _maybe_strip_filesep(curPath);
         curPath = _strip_filename(curPath,'N');
      }
      topPathWasCheckedOut := svnIsCheckedoutPath(topSVNPath,auto curURL="");
      if ( !topPathWasCheckedOut ) topSVNPath = "";
   }

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]) {
      _str pathsSoFar:[];

      len := projPaths._length();
   //   say('****************************************************************************************************');
      for ( i:=0;i<len;++i ) {
         curPath := projPaths[i];
         getTopSVNPath(curPath,workspacePath,auto topSVNPath="");
   //      say('_SVNGetUpdatePathList curPath='curPath' topSVNPath='topSVNPath);
         if ( topSVNPath!="" && !pathsSoFar._indexin(topSVNPath) ) {
            pathsToUpdate[pathsToUpdate._length()] = topSVNPath;
            pathsSoFar:[topSVNPath] = "";
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

   SVCSystemSpecificFlags getSystemSpecificFlags() {
      return SVC_UPDATE_PATHS_RECURSIVE;
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
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      getLocalFileURL(localFilename,auto URL="");
      SVCHistoryInfo historyInfo[];
      vsGetSVNHistoryForCurrentBranch(URL,historyInfo,"",exeStr);
      return historyInfo._length();
   }

   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quiet=false) {
      status := getExeStr(auto exeStr);
      if ( status ) {
         _message_box(get_message(status,exeStr));
         return status;
      }
      getLocalFileURL(localFilename,auto URL="");
      SVCHistoryInfo historyInfo[];
      status = vsGetSVNHistoryForCurrentBranch(URL,historyInfo,"",exeStr);
      if ( !status ) {
         foreach ( auto curItem in historyInfo ) {
            if ( curItem.revision != "rroot" ) {
               ARRAY_APPEND(versions,substr(curItem.revision,2));
            }
         }
      }
      versions._sort('N');
      return status;
   }
};
