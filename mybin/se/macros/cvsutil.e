////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50523 $
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
#include "cvs.sh"
#include "svc.sh"
#include "pipe.sh"
#import "cvs.e"
#import "guicd.e"
#import "listbox.e"
#import "main.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#require "sc/lang/String.e"
#import "svc.e"
#import "vc.e"
#endregion

using sc.lang.String;

/**
 * CD's to the directory specified, and runs the necessary
 * command.
 *
 * On UNIX, cvs will not accept an absolute path, so you have
 * to cd to a relative directory to run a command.
 *
 * Also, turns on mou_hour_glass while running.
 *
 * @param command    command to shell
 * @param FileOrPath Directory to cd to, or absolute filename to cd to directory of
 * @param shell_options
 *                   Options for shell builtin
 * @param debug      if 1, a debug line will be output with the actual line
 *                   shelled out, and current directory
 *
 * @return status from shell builtin
 */
int _CVSShell(_str command,_str FileOrPath,_str shell_options,boolean debug=false,
              typeless *pfnPreShellCallback=null,typeless *pfnPostShellCallback=null,
              typeless *pData=null,int &pid=-1,boolean NoHourglass=false,
              boolean checkCVSDashD=true)
{
   _str cwd=getcwd();
   if ( FileOrPath!='' ) {
      _str path='';
      if ( isdirectory(FileOrPath) ) {
         path=FileOrPath;
      } else {
         path=_file_path(FileOrPath);
      }
      if ( path!='' ) {
         int status=chdir(path,1);
         if ( status ) {
            return(status);
         }
      }
   }
   if ( !NoHourglass ) mou_hour_glass(1);
   if ( checkCVSDashD ) {
      if ( _CVSMaybeAddDashDToCommand(command) ) return(CVS_ERROR_NOT_LOGGED_IN);
   }
   if ( debug || _CVSDebug&CVS_DEBUG_SHOW_MESSAGES ) {
      _SVCLog('CVSShell:FileOrPath='FileOrPath);
      _SVCLog('CVSShell:cwd='getcwd()' command='command);
   }
   int focus_wid=_get_focus();
   int current_wid=p_window_id;
   if ( pfnPreShellCallback ) {
      shell_options='A'shell_options;
      (*pfnPreShellCallback)(pData);
   }
   _str alternate_shell='';
   #if __UNIX__
   alternate_shell='/bin/sh';
   if (file_match('-p 'alternate_shell,1)=='') {
      alternate_shell=path_search('sh');
      if (alternate_shell=='') {
         _message_box(nls("Could not find sh shell"));
      }
   }
   #endif
   int status=0;
   if ( !(_CVSDebug&CVS_DEBUG_DO_NOT_RUN_COMMANDS) ) {
      status=shell(command,shell_options'P',alternate_shell,pid);
   }
   if (_CVSDebug&CVS_DEBUG_SHOW_MESSAGES) {
      _SVCLog('CVSShell:pid='pid' status='status);
   }
   _CVSSetCVSCancel(false);
   if ( pos('a',shell_options,1,'i') &&
        (pfnPreShellCallback || pfnPostShellCallback) ) {
      for ( ;; ) {
         if ( !_IsProcessRunning(pid) ) break;
         delay(1);
         boolean cancel;
         process_events(cancel,'T');
         if ( _CVSGetCVSCancel() ) {
            status=COMMAND_CANCELLED_RC;
            if (_IsProcessRunning(pid)) {
               int exit_code;
               _kill_process_tree(pid,exit_code);
            }
            break;
         }
      }
   }
   if ( pfnPostShellCallback ) {
      (*pfnPostShellCallback)(pData);
   }

   if ( focus_wid && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
   p_window_id=current_wid;

   if ( !NoHourglass ) mou_hour_glass(0);
   if ( FileOrPath!='' ) {
      chdir(cwd,1);
   }
   return(status);
}

int _CVSPipeProcess(_str command,_str FileOrPath,_str shell_options,
                    sc.lang.String &StdOutData,sc.lang.String &StdErrData,
                    boolean debug=false,
                    typeless *pfnPreShellCallback=null,typeless *pfnPostShellCallback=null,
                    typeless *pData=null,int &pid=-1,boolean NoHourglass=false,
                    boolean checkCVSDashD=true)
{
   _str copy_of_command=command;
   _str vcexename=strip(parse_file(copy_of_command),'B','"');
   if ( !file_exists(vcexename) ) {
      _message_box(nls("Could not find executable '%s'",vcexename));
      return(FILE_NOT_FOUND_RC);
   }
   _str cwd=getcwd();
   if ( FileOrPath!='' ) {
      _str path='';
      if ( isdirectory(FileOrPath) ) {
         path=FileOrPath;
      } else {
         path=_file_path(FileOrPath);
      }
      if ( path!='' && substr(path,1,6)!="svn://" && substr(path,1,7)!="http://"  ) {
         int status=chdir(path,1);
         if ( status ) {
            return(status);
         }
      }
   }
   if ( !NoHourglass ) mou_hour_glass(1);
   if ( checkCVSDashD ) {
      if ( _CVSMaybeAddDashDToCommand(command) ) return(CVS_ERROR_NOT_LOGGED_IN);
   }
   if ( debug || _CVSDebug&CVS_DEBUG_SHOW_MESSAGES ) {
      _SVCLog('_CVSPipeProcess:FileOrPath='FileOrPath);
      _SVCLog('_CVSPipeProcess:cwd='getcwd()' command='command);
   }
   int focus_wid=_get_focus();
   int current_wid=p_window_id;
   if ( pfnPreShellCallback ) {
      shell_options='A'shell_options;
      (*pfnPreShellCallback)(pData);
   }
   _str alternate_shell='';
   #if __UNIX__
   alternate_shell='/bin/sh';
   if (file_match('-p 'alternate_shell,1)=='') {
      alternate_shell=path_search('sh');
      if (alternate_shell=='') {
         _message_box(nls("Could not find sh shell"));
      }
   }
   #endif
   int status=0;

   maxLen := origLen := _default_option(VSOPTION_WARNING_STRING_LENGTH);
   _str orig_command=command;
   outerloop:
   for (;;) {
      status=0;
      if ( !(_CVSDebug&CVS_DEBUG_DO_NOT_RUN_COMMANDS) ) {
         //status=shell(command,shell_options'P',alternate_shell,pid);
         int process_stdout_pipe,process_stdin_pipe,process_stderr_pipe;
         if (_CVSDebug&CVS_DEBUG_SHOW_MESSAGES) {
            _SVCLog('_CVSPipeProcess:command='command);
         }
         int process_handle=_PipeProcess(command,process_stdout_pipe,process_stdin_pipe,process_stderr_pipe,'');
         if ( process_handle<0 ) {
            return(process_handle);
         }
         _CVSSetCVSCancel(false);
         _str buf1='';
         _str buf2='';
         for (;;) {

            delay(1);
            boolean cancel=false;
            if (pfnPreShellCallback) process_events(cancel,'T');
            if ( _CVSGetCVSCancel() ) {
               status=COMMAND_CANCELLED_RC;
               break;
            }
            buf1='';
            _PipeRead(process_stdout_pipe,buf1,0,1);
            if ( buf1!='' ) {
               _PipeRead(process_stdout_pipe,buf1,length(buf1),0);
            }
            newLen := StdOutData.getLength()+length(buf1);
            if ( newLen>StdOutData.getCapacity() ) {
               StdOutData.setCapacity(newLen);
            }
            StdOutData.append(buf1);

            buf2='';
            _PipeRead(process_stderr_pipe,buf2,0,1);
            if ( buf2!='' ) {
               _PipeRead(process_stderr_pipe,buf2,length(buf2),0);
            }
            newLen = StdErrData.getLength()+length(buf2);
            if ( newLen>StdErrData.getCapacity() ) {
               StdErrData.setCapacity(StdErrData.getLength()+length(buf2));
            }
            StdErrData.append(buf2);

            int ppe=_PipeIsProcessExited(process_handle);
            if ( (ppe && buf1=='' && buf2=='' && _PipeIsReadable(process_handle)<=0
                  ) || 
                 pos("Password for '?@'\\:",StdErrData,1,'r') ) {
               break;
            }
         }
         int p2=pos("authorization failed",StdErrData,1,'i');
         int p3=pos("missing argument:",StdErrData,1,'i');
         int p4=pos("Password for '?@'\\:",StdErrData,1,'ri');
         int p5=pos("Can't get password",StdErrData,1,'r');
         int p6=pos("Can't get username or password",StdErrData,1,'r');
         if ( debug || _CVSDebug&CVS_DEBUG_SHOW_MESSAGES ) {
            _SVCLog('_CVSPipeProcess p2='p2' p3='p3' p4='p4' p5='p5' p6='p6);
            _SVCLog('_CVSPipeProcess loop StdOutData='StdOutData);
            _SVCLog('_CVSPipeProcess loop StdErrData='StdErrData);
         }
         if ( p2 || p3 || p4 || p5 || p6 ) {
            SVC_AUTHENTICATE_INFO authinfo=null;
            if ( !NoHourglass ) mou_hour_glass(0);
            status=_SVCGetAuthInfo(authinfo);
            if ( !NoHourglass ) mou_hour_glass(1);
            if ( status ) {
               _PipeCloseProcess(process_handle);
               _default_option(VSOPTION_WARNING_STRING_LENGTH,origLen);
               return(COMMAND_CANCELLED_RC);
            }
            _str exename,rest;
            //parse orig_command with exename rest;
            rest = orig_command;
            exename = parse_file(rest);
            command=exename' --username "'authinfo.username'"';
            if ( authinfo.password!='' ) {
               command=command' --password "'authinfo.password'"';
            }
            authinfo=null;
            command=command' 'rest;
            StdErrData.set("");
            StdOutData.set("");
            continue outerloop;
         }else {
            int exit_code = _PipeCloseProcess(process_handle);
            if ( exit_code >  0 && !status ) {
               status = exit_code;
            }
            break outerloop;
         }
      }
   }
   _default_option(VSOPTION_WARNING_STRING_LENGTH,origLen);
   if ( debug || _CVSDebug&CVS_DEBUG_SHOW_MESSAGES ) {
      _SVCLog('_CVSPipeProcess out StdOutData='StdOutData);
      _SVCLog('_CVSPipeProcess out StdErrData='StdErrData);
   }
   if (_CVSDebug&CVS_DEBUG_SHOW_MESSAGES) {
      _SVCLog('_CVSPipeProcess:pid='pid' status='status);
   }
   if ( pfnPostShellCallback ) {
      (*pfnPostShellCallback)(pData);
   }

   if ( focus_wid && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
   p_window_id=current_wid;

   if ( !NoHourglass ) mou_hour_glass(0);
   if ( FileOrPath!='' ) {
      chdir(cwd,1);
   }
   if ( !status && pos("Authentication error from server",StdErrData) ) {
      status = 1;
   }
   return(status);
}

static boolean gCVSCancel=false;
void _CVSSetCVSCancel(boolean newval)
{
   gCVSCancel=newval;
}

boolean _CVSGetCVSCancel()
{
   return(gCVSCancel);
}

int _CVSMaybeAddDashDToCommand(_str &command)
{
   if ( def_cvs_flags&CVS_ALWAYS_USE_DASH_D && _GetVCSystemName()=="CVS" ) {
      if ( get_env('CVSROOT')=='' ) {
         cvs_login();
         if ( get_env('CVSROOT')=='' ) {
            return(1);
         }
      }
      _str exename=parse_file(command);
      command=exename' -d 'maybe_quote_filename(get_env('CVSROOT'))' 'command;
   }
   return(0);
}

void _CVSSeedPathIndexes(_str Path,int (&PathTable):[],int SeedIndex)
{
   PathTable:[_file_case(Path)]=SeedIndex;
}

int _CVSGetPathIndex(_str Path,_str BasePath,int (&PathTable):[],
                     int ExistFolderIndex=_pic_fldopen,
                     int NoExistFolderIndex=_pic_cvs_fld_m,
                     _str OurFilesep=FILESEP,
                     int state=1)
{
   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   int Othercount=0;
   Path=strip(Path,'B','"');
   BasePath=strip(BasePath,'B','"');
   if (PathTable._indexin(_file_case(Path))) {
      return(PathTable:[_file_case(Path)]);
   }
   int Parent=TREE_ROOT_INDEX;
   for (;;) {
      if (Path=='') {
         break;
      }
      PathsToAdd[count++]=Path;
      Path=substr(Path,1,length(Path)-1);
      _str tPath=_strip_filename(Path,'N');
      if (file_eq(Path:+OurFilesep,BasePath) || file_eq(tPath,Path)) break;
      if (isunc_root(Path)) break;
      Path=tPath;
      if (PathTable._indexin(_file_case(Path))) {
         Parent=PathTable:[_file_case(Path)];
         break;
      }
   }
   PathsToAdd._sort('F');
   int i;
   for (i=0;i<PathsToAdd._length();++i) {
      int bmindex;
      if (isdirectory(PathsToAdd[i])) {
         bmindex=ExistFolderIndex;
      }else{
         bmindex=NoExistFolderIndex;
      }
      Parent=_TreeAddItem(Parent,
                          PathsToAdd[i],
                          TREE_ADD_AS_CHILD/*|TREE_ADD_SORTED_FILENAME*/,
                          bmindex,
                          bmindex,
                          state);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

_str _CVSGetExeAndOptions()
{
   return(maybe_quote_filename(def_cvs_info.cvs_exe_name)' 'def_cvs_global_options);
}

//#define BASE_COMMIT_COMMAND maybe_quote_filename(def_cvs_info.cvs_exe_name)' >'appendop:+maybe_quote_filename(OutputFilename)' 2>'appendop'&1 commit 'comment_opt
_str _CVSBuildCommitCommand(CVS_COMMIT_CALLBACK_INFO *pinfo,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str comment_opt='';
   if ( pinfo->comment_is_filename ) {
      comment_opt='-F 'maybe_quote_filename(pinfo->comment);
   } else {
      // This is a comment, but we still want to quote it(maybe, could have quotes?)
      comment_opt='-m 'maybe_quote_filename(pinfo->comment);
   }
   return(_CVSGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 commit 'comment_opt' 'pinfo->commit_options' ');
}

int _CVSCommit(_str filelist[],_str comment,_str &OutputFilename='',
               boolean comment_is_filename=false,_str commit_options='',
               boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               _str taglist='')
{
   CVS_COMMIT_CALLBACK_INFO info;
   info.comment=comment;
   info.comment_is_filename=comment_is_filename;
   info.commit_options=commit_options;

   // This is a "just in case" sort of thing.  If we ever had a bug
   // that caused this filename to be blank, we would commit entire
   // directory trees when the user only wanted to commit a file
   int i,len=filelist._length();
   for (i=0;i<len;++i) {
      if (filelist[i]=='') {
         _message_box(nls("Cannot commit blank filename"));
         return(1);
      }
      _LoadEntireBuffer(filelist[i]);
   }
   int status=_CVSCommand(filelist,_CVSBuildCommitCommand,&info,OutputFilename,append_to_output,pFiles);
   if ( !status && taglist!='' ) {
      _CVSTag(filelist,OutputFilename,taglist,true);
   }
   _reload_vc_buffers(filelist);
   return(status);
}
static _str CVSBuildAddCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str add_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 add 'add_options' ');
}

int _CVSAdd(_str filelist[],_str &OutputFilename='',
            boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
            boolean &updated_new_dir=false,
            _str add_options='')
{
   int status=_CVSCommand(filelist,CVSBuildAddCommand,&add_options,OutputFilename,append_to_output,pFiles,updated_new_dir);
   return(status);
}

int _CVSGetComment(_str comment_filename,_str &tag,_str file_being_checked_in,boolean show_apply_to_all=true,
                   boolean &apply_to_all=false,boolean show_tag=true,boolean show_author=false,_str &author='')
{
   tag='';
   int result=show('-modal -xy _cvs_comment_form',comment_filename,file_being_checked_in,show_apply_to_all,show_tag,show_author);
   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }

   // the comment is _param3
   apply_to_all=_param1;
   tag=_param2;
   author=_param4;
   return(0);
}
_str _GetParentDirectory(_str directory_name)
{
   if ( last_char(directory_name)==FILESEP ) {
      directory_name=substr(directory_name,1,length(directory_name)-1);
   }
   directory_name=_strip_filename(directory_name,'N');
   return(directory_name);
}

int _CVSGetVerboseFileInfo(_str path,CVS_LOG_INFO (&Files)[],_str &module_name,
                           boolean recurse=true,_str run_from_path='',
                           boolean treat_as_wildcard=true,
                           typeless *pfnPreShellCallback=0,
                           typeless *pfnPostShellCallback=0,
                           typeless *pData=0,
                           int (&IndexHTab):[]=null,
                           int &pid1=-1,
                           int &pid2=-1,
                           _str &StatusOutputFilename='',
                           _str &UpdateOutputFilename=''
                           );

/**
 * This is designed to run a cvs command where multiple filenames
 * can be appended to the end of the list.  It shells as
 * few times as possible, switching directory to run relative files.
 *
 * You have to pass a callback function to build the
 * "base comamnd line", and this function will call to get
 * it, and then append filenames to the end.
 *
 * @param filelist list of files to use
 * @param pfnCommandLineBuilder
 *                 Pointer to function to call to build the base command line
 * @param pCommandLineData
 *                 Pointer to data to pass to the callback
 * @param OutputFilename
 *                 Filename that output is directed to.
 *
 *                 If append_to_output is on, the caller needs to initialize
 *                 this to '' so that it gets filled in with a name the first time.
 * @param append_to_output
 *                 set to true to append to same output file
 * @param pFiles   If not zero, runs _CVSGetVerboseFileInfo to get information
 *                 about all files.  If you are using a VCS other than CVS, do
 *                 not pass this parameter.
 * @param included_dir
 *                 We ran this operation on a path(an item that ended in '/')
 *
 * @return 0 if successful
 */
int _CVSCommand(_str (&filelist)[],
                typeless *pfnCommandLineBuilder,typeless *pCommandLineData,
                _str &OutputFilename='',
                boolean append_to_output=false,typeless pFiles=0,
                boolean &included_dir=false,typeless pfnGetVerboseFileInfo=_CVSGetVerboseFileInfo)
{
   // For now we are going to do this really cheap and do each file.
   int status=0;

   _str orig_dir=getcwd();

   filelist._sort('F');

   if ( !append_to_output ||
        (append_to_output && OutputFilename=='') ) {
      OutputFilename=mktemp();
   }

   _str last_dir='';
   _str cmdline=(*pfnCommandLineBuilder)(pCommandLineData,OutputFilename,append_to_output);
   int cmdline_length=length(cmdline);

   // no files to process?
   if (filelist == null || filelist._length()==0) {
      return 0;
   }

   _str cur_dir=_file_path(filelist[0]);
   if ( last_char(filelist[0])==FILESEP ) {
      // Good chance isdirectory will fail on this because if we are doing an
      // update this will fail
      cur_dir=_GetParentDirectory(cur_dir);
   }
   _str cur_files='';

   checkCVSDashD := lowcase(_GetVCSystemName())=='cvs';
   int i,len=filelist._length();
   _str module_name='';
   for ( i=0;i<len;++i ) {
      int dir_len=length(last_dir);
      _str cur_file_dir=_file_path(filelist[i]);
      if ( i &&
           (last_dir=='' || !file_eq( substr(cur_file_dir,1,dir_len), last_dir)) ) {
         cur_dir=cur_file_dir;
         _CVSShell(cmdline,last_dir,def_cvs_shell_options,false,null,null,null,-1,false,checkCVSDashD);

         //if ( pFiles ) _CVSGetVerboseFileInfo(cur_files,*pFiles,module_name,false,last_dir,false);
         if ( pFiles ) (*pfnGetVerboseFileInfo)(cur_files,*pFiles,module_name,false,last_dir,false);

         chdir(cur_dir);
         //cmdline=maybe_quote_filename(def_cvs_info.cvs_exe_name)' >'appendop:+maybe_quote_filename(OutputFilename)' 2>'appendop'&1 commit 'comment_opt;
         cmdline=(*pfnCommandLineBuilder)(pCommandLineData,OutputFilename,append_to_output);
         cmdline_length=length(cmdline);
         cur_files='';
      }
      _str new_file=_SVCRelative(filelist[i],cur_dir);
      if ( cmdline_length + length(new_file) + 1 > MAX_COMMAND_LINE_LENGTH ) {
         _CVSShell(cmdline,cur_dir,def_cvs_shell_options,false,null,null,null,-1,false,checkCVSDashD);

         //if ( pFiles ) _CVSGetVerboseFileInfo(cur_files,*pFiles,module_name,false,cur_dir,false);
         if ( pFiles ) (*pfnGetVerboseFileInfo)(cur_files,*pFiles,module_name,false,cur_dir,false);

         --i;
         //cmdline=maybe_quote_filename(def_cvs_info.cvs_exe_name)' >'appendop:+maybe_quote_filename(OutputFilename)' 2>'appendop'&1 commit 'comment_opt;
         cmdline=(*pfnCommandLineBuilder)(pCommandLineData,OutputFilename,append_to_output);
         cmdline_length=length(cmdline);
         cur_files='';
         append_to_output=true;
         continue;
      }
      if ( last_char(new_file)=='/' ) {
         // Cannot perform these checks on quoted filename
         included_dir=true;
         pFiles=0; // We no longer need to run _CVSGetVerboseFileInfo for individual
                   // files, because the whole tree will be refreshed
         new_file=substr(new_file,1,length(new_file)-1);
      }
      new_file=maybe_quote_filename(new_file);
      cmdline=cmdline' 'new_file;
      cur_files=cur_files' 'new_file;

      cmdline_length += length(filelist[i]) + 1;

      last_dir=cur_dir;
      append_to_output=true;
   }
   _str base_command=(*pfnCommandLineBuilder)(pCommandLineData,OutputFilename,append_to_output);
   if ( cmdline!=base_command ) {
      status = _CVSShell(cmdline,last_dir,def_cvs_shell_options,false,null,null,null,-1,false,checkCVSDashD);

      if ( pFiles ) {
         //_CVSGetVerboseFileInfo(cur_files,*pFiles,module_name,false,last_dir,false);
         (*pfnGetVerboseFileInfo)(cur_files,*pFiles,module_name,false,last_dir,false);
      }
   }
   chdir(orig_dir);

   return(status);
}

static _str BuildTagCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str tag_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 tag 'tag_options' ');
}

/**
 * Tags all of the files in filelist with the tagname
 * given in tag_options_and_tagname
 *
 * @param filelist list of files to tag
 * @param OutputFilename
 *                 File to write output to
 * @param tag_options_and_tagname
 *                 tag name and options to tag command
 * @param append_to_output
 *                 If true, output data is appended to OutputFilename.
 *                 OutputFilename will be set to a filename the first time
 *                 if it is initialized to ''
 * @param pFiles   If not null, will call _CVSGetVerboseFileInfo on the files
 *                 after tagging them and return the results here.
 * @param included_dir
 *                 set to true if a directory was one of the items tagged
 *
 * @return 0 if successful
 */
int _CVSTag(_str filelist[],_str &OutputFilename='',_str tag_options_and_tagname='',
            boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
            boolean &included_dir=false
            )
{
   int status=0;
   for (;;) {
      _str tag_command='';
      _str cur_option_or_tag=parse_file(tag_options_and_tagname);
      if ( cur_option_or_tag=='' ) {
         break;
      }
      for (;;) {
         // We will definitely want to add this to the command, but if it is not
         // an option, we want to break after this iteration and do the tag.  If
         // this is not an option, it is the tag name, and you can only have one
         tag_command=tag_command' 'cur_option_or_tag;
         if ( substr(cur_option_or_tag,1,1)!='-' ) {
            break;
         }
         cur_option_or_tag=parse_file(tag_options_and_tagname);
      }
      boolean updated_new_dir;
      status=_CVSCommand(filelist,BuildTagCommand,&tag_command,OutputFilename,append_to_output,pFiles,updated_new_dir);
      if (status) break;
   }
   return(status);
}

static _str BuildEditCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str edit_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 edit 'edit_options' ');
}

int _CVSEdit(_str filelist[],_str &OutputFilename='',_str edit_options='',
             boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
             boolean &included_dir=false
             )
{
   int status=_CVSCommand(filelist,BuildEditCommand,&edit_options,OutputFilename,append_to_output,pFiles);
   _reload_vc_buffers(filelist);
   return(status);
}

/**
 * If there is a buffer up for <B>filename</B>, loads the entire file and closes
 * the handle.  This way we will not have errors if CVS replaces large files that
 * are open.
 *
 * @param filename
 *
 * @return 0 if succesful
 */
int _LoadEntireBuffer(_str filename, _str &lang='')
{
   if (filename=='' || buf_match(maybe_quote_filename(filename),1,'hx')=='') return(FILE_NOT_FOUND_RC);
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   _ReadEntireFile();
   lang=p_LangId;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(0);
}

/**
 *
 * @param path    Path to get information for
 * @param Files   Caller should initialize this variable so that multiple
 *                calls to this function can append to the end of the
 *                array
 * @param recurse Recurse subdirectories.  Defaults to true.
 *
 * @return 0 if succesful
 */
int _CVSGetVerboseFileInfo(_str path,CVS_LOG_INFO (&Files)[],_str &module_name,
                           boolean recurse=true,_str run_from_path='',
                           boolean treat_as_wildcard=true,
                           typeless *pfnPreShellCallback=null,
                           typeless *pfnPostShellCallback=null,
                           typeless *pData=null,
                           int (&IndexHTab):[]=null,
                           int &pid1=-1,
                           int &pid2=-1,
                           _str &StatusOutputFilename='',
                           _str &UpdateOutputFilename=''
                           )
{
   _str orig_path=getcwd();
   _str shell_path=path;
   if ( run_from_path!='' ) {
      int status=chdir(run_from_path,1);
      if ( status ) {
         return(status);
      }
      shell_path=run_from_path;
   }
   StatusOutputFilename=mktemp();
   _str local_option='';
   if ( !recurse ) {
      local_option=' -l ';
   }
   path=strip(path);
   _str wildcard='';
   if ( treat_as_wildcard ) {
      wildcard=_strip_filename(path,'P');
   } else {
      wildcard=path;
   }
   _CVSCreateTempFile(StatusOutputFilename);
   _str async_option='';
   // The -v option makes the CVS status command take about 17 X longer
   // and from I (Clark) can tell, no code path currently using this
   // function needs it.
   _str verbose_option=''; //' -v ';
   shell_path=strip(shell_path,'B','"');
   int status=_CVSShell(_CVSGetExeAndOptions()' >'maybe_quote_filename(StatusOutputFilename)' 2>&1 status 'verbose_option' ' local_option' 'wildcard,shell_path,'P'def_cvs_shell_options:+async_option,false,pfnPreShellCallback,null,pData,pid1);
   if ( status ) {
      if (status!=COMMAND_CANCELLED_RC) {
         _message_box(nls("cvs status %s returned %s",path,status));
      }
      delete_file(StatusOutputFilename);
      return(status);
   }

   UpdateOutputFilename=mktemp();
   _CVSCreateTempFile(UpdateOutputFilename);
   _str tag_option='';
   /*if (tag_name!='') {
      tag_option='-r 'tag_name;
   }*/
   status=_CVSShell(_CVSGetExeAndOptions()' >'maybe_quote_filename(UpdateOutputFilename)' 2>&1 -n -q update -d 'tag_option' 'local_option' 'wildcard,shell_path,'P'def_cvs_shell_options:+async_option,false,null,pfnPostShellCallback,pData,pid2);
   // Do not check status here - it is unreliable. We will look through the
   // output instead
   if (status==COMMAND_CANCELLED_RC) {
      // It is ok to check for this status, it came from the user pressing the
      // ok button
      delete_file(StatusOutputFilename);
      delete_file(UpdateOutputFilename);
      return(status);
   }

   module_name='';
   _str temp=path;
   _str first=parse_file(temp);
   status=_CVSGetModuleFromLocalFile(first,module_name);
   if ( run_from_path=='' ) {
      status=CVSGetAllFileInfoFromOutput(StatusOutputFilename,UpdateOutputFilename,Files,path,module_name,recurse,IndexHTab);
   } else {
      status=CVSGetAllFileInfoFromOutput(StatusOutputFilename,UpdateOutputFilename,Files,run_from_path,module_name,recurse,IndexHTab);
   }
   if ( status ) {
      _SVCDisplayErrorOutputFromFile(StatusOutputFilename,status,0,true);
   }

   delete_file(StatusOutputFilename);
   delete_file(UpdateOutputFilename);
   if ( run_from_path!='' ) {
      chdir(orig_path);
   }
   return(status);
}

int _create_temp_view_of_data(int &temp_wid,_str data,_str load_options='',_str buf_name='',boolean doSelectEditMode=false,int more_buf_flags=0)
{
   int orig_wid=_create_temp_view(temp_wid,load_options,buf_name,doSelectEditMode,more_buf_flags);
   if ( !orig_wid ) {
      return(orig_wid);
   }
   _insert_text(data);
   return(orig_wid);
}

int _CVSCreateTempFile(_str filename)
{
   if ( file_exists(filename) ) {
      return(0);
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   int status=_save_file('+o');
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

int _CVSGetChildItem(_str file_or_path,_str &root_value,_str child_filename)
{
   root_value='';
   _str root_filename=_strip_filename(file_or_path,'N'):+CVS_CHILD_DIR_NAME:+FILESEP:+child_filename;
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(root_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();
   get_line(auto line);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   if (_isMac()) {
      // 3:24:12 PM 1/30/2007
      // Some very old CVS clients for the mac accidentally put this in 
      // CVS/Repository
      if( file_eq(_strip_filename(file_or_path,'P'),"Repository") 
          && pos('/cvs/', line, 1, 'I')==1 ) {
         line=substr(line, 6);
      }
   }
   root_value=line;
   return(0);
}

int _CVSGetRootForFile(_str file_or_path,_str &root_value)
{
   return(_CVSGetChildItem(file_or_path,root_value,CVS_ROOT_FILENAME));
}

/**
 * Parses the CVSRoot string for its various components.
 *
 * <p>
 * This function replaces the one in cvsutil.e. That one presumes that local
 * repository designators are always preceded by :local:. If they are not,
 * then it returns an empty string for the repository name and several
 * functions within the CVS subsystem fail. This version allows for a local
 * repository designator that is not preceded by :local: as in
 * /usr/local/cvsroot.
 * </p>
 *
 * @param CVSRoot
 * @param auth_type
 * @param host_name
 * @param repository_name
 */
void _CVSParseCVSRoot(_str CVSRoot,_str &auth_type,_str &host_name,_str &repository_name)
{
   auth_type='';
   host_name='';
   repository_name=CVSRoot;
   if (CVSRoot=='') {
      CVSRoot=get_env('CVSROOT');
   }
   if (substr(CVSRoot,1,7)==':local:') {
      parse CVSRoot with ':' auth_type ':' repository_name;
   }else if (first_char(CVSRoot) == ':') {
      parse CVSRoot with ':' auth_type ':' host_name ':' repository_name;
   }
}

/**
 * Gets the module name for a give path or file.
 *
 * Always puts a trailing forward slash on.
 *
 * @param filename
 * @param module_name
 *
 * @return
 */
int _CVSGetModuleFromLocalFile(_str file_or_path,_str &module_name)
{
   module_name='';
   int status=_CVSGetChildItem(file_or_path,module_name,CVS_REPOSITORY_FILENAME);
   if ( !status ) {
      _CVSMaybeAppendFilesep(module_name);
   }
   // Sometimes, the Repository filename may have the CVSROOT prepended to it.
   // This is documenented in
   // "Version Management with CVS for cvs 1.11.1p1 Per Cederqvist et al"
   _str auth_type,host_name,repository_name;
   if (first_char(module_name)=='/') {
      _str cvsroot='';
      status=_CVSGetChildItem(file_or_path,cvsroot,CVS_ROOT_FILENAME);
      _CVSParseCVSRoot(cvsroot,auth_type,host_name,repository_name);

      int repository_name_len=length(repository_name);
      if ( substr(module_name,1,repository_name_len)==repository_name ) {
         // This module name begins with the repository part of CVSROOT.  This
         // will not work.
         // We user repository_name_len+2 because we have to add one to get the
         // value of the repository, and one to get past the FILESEP
         module_name=substr(module_name,repository_name_len+2);
      }
   }

   return(status);
}

void _CVSMaybeAppendFilesep(_str &path)
{
   _maybe_append(path,
#if __UNIX__
                 FILESEP
#else
                 FILESEP2
#endif
                );
}

#define CVS_SERVER_OR_UPDATE_RE "(server|update)"

/**
 *
 * @param StatusOutputFilename
 * @param UpdateOutputFilename
 * @param Files
 * @param path
 * @param module_name
 * @param recurse
 * @param IndexHTab
 * @param FirstProcessing
 * @param status_view_id
 * @param update_view_id
 * @param MaxTimeAllowed
 *                  In milliseconds.  -1 means always finish.
 * @param descriptions_only
 *
 * @return 0 if successful
 */
static int CVSGetAllFileInfoFromOutput(_str StatusOutputFilename,_str UpdateOutputFilename,CVS_LOG_INFO (&Files)[],
                                    _str path,_str module_name,boolean recurse,
                                    int (&IndexHTab):[]=null,
                                    boolean FirstProcessing=true,
                                    int &status_view_id=0,int &update_view_id=0,
                                    int MaxTimeAllowed=-1,
                                    boolean descriptions_only=false)
{
   int orig_view_id=p_window_id;
   int status=0;
   if ( !status_view_id ) {
      status=_open_temp_view(StatusOutputFilename,status_view_id,orig_view_id);
   }
   _str extra_message='';
   _str bad_path_name='';
   if ( StatusLockError(status_view_id,module_name,path,bad_path_name) ) {
      if ( bad_path_name!='' ) {
         _message_box(nls("There is a problem with the local directory '%s'.\n\nThis is causing the 'cvs status' command to stop.\n\nPlease correct the problem and try again",bad_path_name));
      }
      return(1);
   }
   if ( !update_view_id ) {
      int junk;
      status=_open_temp_view(UpdateOutputFilename,update_view_id,junk);
   }
   p_window_id=update_view_id;
   if ( FirstProcessing ) {
      top();up();
   }
   boolean done_processing=false;

   // Keep a hash table of all the indexes that we put in the tree.
   // This way we can check for duplicates and change the description
   // to represent an error.
   // This normally happens in this circumstance, the user updates with
   // the -d option.  CVS cannot write a new directory 'xxx', because the
   // user already has a non-cvs directory 'xxx'.
   int PathIndexes:[]=null;
   _str Roots:[]=null;
   if ( !isdirectory(path) ) {
      path=_file_path(path);
   }
   _str t1=_time('b');
   int orig_len=Files._length();
   return_status := 0;
   for ( ;; ) {
      if ( down() ) {
         done_processing=true;break;
      }
      get_line(auto line);
      int len=Files._length();

      // return error status and give up if we get a fatal error
      if (line == "Fatal error, aborting.") {
         return_status = 1;
         break;
      }
      // also check for other error messages
      if ( pos("^cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: warning\\: failed to ",line,1,'r') ||
           pos("^cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: authorization failed\\: ",line,1,'r') ||
           pos("^cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: used empty password; try \\\"cvs login\\\" with a real password",line,1,'r') ) {
         return_status = 1;
         break;
      }

      _str cur='';
      if ( pos('^cvs ':+CVS_SERVER_OR_UPDATE_RE:+'\: ?@ is no longer in the repository',line,1,'r') ) {
         parse line with ('cvs ':+CVS_SERVER_OR_UPDATE_RE:+'\: '),'r' cur' is no longer in the repository' .;
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         if ( index<1 ) {
            Files[len].WorkingFile=path:+cur;
            Files[len].RCSFile=module_name:+cur;
            Files[len].Description='O';
         } else {
            Files[index].Description='E';
         }
      } else if ( pos("^cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: New directory `?@' -- ignored",line,1,'r') ) {
         parse line with ("cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: New directory `"),'r' cur"' -- ignored";
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         if ( index<1 ) {
            if ( !(def_cvs_flags&CVS_HIDE_EMPTY_DIRECTORIES ) ) {
               Files[len].WorkingFile=path:+cur'/';
               Files[len].RCSFile=module_name:+cur'/';
               Files[len].Description='N';
            }
         } else {
            Files[index].Description='E';
         }
      } else if ( pos("^cvs ":+CVS_SERVER_OR_UPDATE_RE:+"\\: use `cvs add' to create an entry for ?@",line,1,'r') ) {
         parse line with ("cvs ":+CVS_SERVER_OR_UPDATE_RE:+": use `cvs add' to create an entry for "),'r' cur;
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         Files[len].Description='?';
         Files[len].WorkingFile=path:+cur;
         Files[len].RCSFile=module_name:+cur;
      } else if ( substr(line,2,1)!=' ' ) {
         continue;
      } else {
         _str cur_path=path:+substr(line,3);
         int index=_CVSPathExistsInTable(cur_path,PathIndexes);
         if ( index<0 ) {
            Files[len].Description=substr(line,1,1);
            Files[len].WorkingFile=cur_path;
            Files[len].RCSFile=module_name:+substr(line,3);
            if ( Files[len].Description=='?' &&
                 isdirectory(Files[len].WorkingFile) ) {
               _maybe_append(Files[len].WorkingFile,'/');
               _maybe_append(Files[len].RCSFile,'/');
               if ( !descriptions_only ) GetSubFiles(cur_path,Files,path,module_name,recurse);
            }
         } else {
            Files[index].Description='E';
         }
      }
      if ( Files._length()!=len ) {
         // If we have added something to the array
#if !__UNIX__
         Files[len].WorkingFile=stranslate(Files[len].WorkingFile,FILESEP,FILESEP2);
#endif
         IndexHTab:[_file_case(Files[len].WorkingFile)]=len;
         // Store the index in our table
         StorePathInTable(Files[len].WorkingFile,PathIndexes,len);
         _str ArchiveFilename='';
         _str cur_path=_file_path(Files[len].WorkingFile);
         if ( !Roots._indexin(cur_path) ) {
            _CVSGetRootForFile(cur_path,Roots:[cur_path]);
         }
         _str curroot=Roots:[cur_path];
         // If we set an old index to an error state, we don't have to do this
         // because it was done when the entry was put in the first MaxTimeAllowed.
         int p=lastpos(':',curroot);
         curroot=substr(curroot,p+1);
         _CVSMaybeAppendFilesep(curroot);
         ArchiveFilename=curroot:+Files[len].RCSFile',v';
         if ( Files[len].Description!='-' ) {
            if ( !file_exists(Files[len].WorkingFile) ) {
               if (Files[len].Description=='U') {
                  Files[len].Description='N';
               } else {
                  Files[len].Description='-';
               }
            }
         }
         if ( Files[len].Description!='-' ) {
            //say('1 'Files[len].WorkingFile);
            p_window_id=status_view_id;
            if ( FirstProcessing ) {
               top();up();
               FirstProcessing=false;
            }
            if ( Files[len].Description!='?' ) {
               //say('2 'Files[len].WorkingFile);
               status=search('\t'_escape_re_chars(ArchiveFilename)'$','@r'_fpos_case);
               if ( status ) {
                  top();up();
                  status=search('\t'_escape_re_chars(ArchiveFilename)'$','@r'_fpos_case);
                  if (status) {
                     _str AtticArchiveFilename=curroot:+_strip_filename(Files[len].RCSFile,'N'):+'Attic/'_strip_filename(Files[len].WorkingFile,'P')',v';
                     status=search('\t'_escape_re_chars(AtticArchiveFilename)'$','@r'_fpos_case);
                     if (!status) {
                        // This file was in the attic.  We want to update the rcs file entry to reflect that
                        Files[len].RCSFile=_strip_filename(Files[len].RCSFile,'N')'Attic/'_strip_filename(Files[len].WorkingFile,'P')',v';
                     }
                  }
               }
               if ( !status ) {
                  up();
                  get_line(line);
                  _str local_version;
                  parse line with 'Working revision:' "\t" local_version "\t";
                  down();
                  get_line(line);
                  _str remote_version;
                  parse line with . 'Repository revision:' "\t" remote_version "\t" .;
                  Files[len].LocalVersion=local_version;
                  Files[len].Head=remote_version;

                  if ( !descriptions_only ) {
                     status=search('Existing Tags:','@');
                     if ( !status ) {
                        // Should never get status
                        for ( ;; ) {
                           down();
                           get_line(line);
                           if ( line=='' ) break;
                           _str tagname;
                           parse line with tagname '(revision: ' version ')';
                           int vlen=Files[len].VersionList._length();
                           Files[len].VersionList[vlen].Comment=tagname;
                           Files[len].VersionList[vlen].RevisionNumber=version;
                        }
                     }
                  }
               }
            }
            p_window_id=update_view_id;
         }
      }
      if ( MaxTimeAllowed>-1 ) {
         _str t2=_time('b');
         int time_diff=(int)t2-(int)t1;
         if ( time_diff>MaxTimeAllowed ) {
            break;
         }
      }
   }
   p_window_id=orig_view_id;
   if ( done_processing ) {
      _delete_temp_view(status_view_id);
      status_view_id=0;
      _delete_temp_view(update_view_id);
      update_view_id=0;
   }
   return(return_status);
}
/**
 *
 * @param StatusOutputFilename
 * @param UpdateOutputFilename
 * @param Files
 * @param path
 * @param module_name
 * @param recurse
 * @param IndexHTab
 * @param FirstProcessing
 * @param status_view_id
 * @param update_view_id
 * @param MaxTimeAllowed
 *                  In milliseconds.  -1 means always finish.
 * @param descriptions_only
 *
 * @return 0 if successful
 */
static int CVSGetAllFileInfoFromOutputString(_str StatusOutput,_str UpdateOutput,CVS_LOG_INFO (&Files)[],
                                             _str path,_str module_name,boolean recurse,
                                             int (&IndexHTab):[]=null,
                                             boolean FirstProcessing=true,
                                             int MaxTimeAllowed=-1,
                                             boolean descriptions_only=false)
{
   int orig_view_id=p_window_id;
   int status_view_id;
   _create_temp_view_of_data(status_view_id,StatusOutput);
   int status=0;
   _str extra_message='';
   _str bad_path_name='';
   if ( StatusLockError(status_view_id,module_name,path,bad_path_name) ) {
      if ( bad_path_name!='' ) {
         _message_box(nls("There is a problem with the local directory '%s'.\n\nThis is causing the 'cvs status' command to stop.\n\nPlease correct the problem and try again",bad_path_name));
      }
      return(1);
   }
   int update_view_id;
   _create_temp_view_of_data(update_view_id,UpdateOutput);
   p_window_id=update_view_id;
   if ( FirstProcessing ) {
      top();up();
   }
   boolean done_processing=false;

   // Keep a hash table of all the indexes that we put in the tree.
   // This way we can check for duplicates and change the description
   // to represent an error.
   // This normally happens in this circumstance, the user updates with
   // the -d option.  CVS cannot write a new directory 'xxx', because the
   // user already has a non-cvs directory 'xxx'.
   int PathIndexes:[]=null;
   _str Roots:[]=null;
   if ( !isdirectory(path) ) {
      path=_file_path(path);
   }
   _str t1=_time('b');
   int orig_len=Files._length();
   for ( ;; ) {
      if ( down() ) {
         done_processing=true;break;
      }
      get_line(auto line);
      int len=Files._length();

      _str cur;
      if ( pos('^cvs server\: ?@ is no longer in the repository',line,1,'r') ) {
         parse line with 'cvs server: 'cur' is no longer in the repository' .;
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         if ( index<1 ) {
            Files[len].WorkingFile=path:+cur;
            Files[len].RCSFile=module_name:+cur;
            Files[len].Description='O';
         } else {
            Files[index].Description='E';
         }
      } else if ( pos("^cvs server\\: New directory `?@' -- ignored",line,1,'r') ) {
         parse line with "cvs server: New directory `"cur"' -- ignored";
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         if ( index<1 ) {
            Files[len].WorkingFile=path:+cur'/';
            Files[len].RCSFile=module_name:+cur'/';
            Files[len].Description='N';
         } else {
            Files[index].Description='E';
         }
      } else if ( pos("^cvs server\\: use `cvs add' to create an entry for ?@",line,1,'r') ) {
         parse line with "cvs server: use `cvs add' to create an entry for "cur;
         int index=_CVSPathExistsInTable(path:+cur,PathIndexes);
         Files[len].Description='?';
         Files[len].WorkingFile=path:+cur;
         Files[len].RCSFile=module_name:+cur;
      } else if ( substr(line,2,1)!=' ' ) {
         continue;
      } else {
         _str cur_path=path:+substr(line,3);
         int index=_CVSPathExistsInTable(cur_path,PathIndexes);
         if ( index<0 ) {
            Files[len].Description=substr(line,1,1);
            Files[len].WorkingFile=cur_path;
            Files[len].RCSFile=module_name:+substr(line,3);
            if ( Files[len].Description=='?' &&
                 isdirectory(Files[len].WorkingFile) ) {
               _maybe_append(Files[len].WorkingFile,'/');
               _maybe_append(Files[len].RCSFile,'/');
               if ( !descriptions_only ) GetSubFiles(cur_path,Files,path,module_name,recurse);
            }
         } else {
            Files[index].Description='E';
         }
      }
      if ( Files._length()!=len ) {
         // If we have added something to the array
#if !__UNIX__
         Files[len].WorkingFile=stranslate(Files[len].WorkingFile,FILESEP,FILESEP2);
#endif
         IndexHTab:[_file_case(Files[len].WorkingFile)]=len;
         // Store the index in our table
         StorePathInTable(Files[len].WorkingFile,PathIndexes,len);
         _str ArchiveFilename='';
         _str cur_path=_file_path(Files[len].WorkingFile);
         if ( !Roots._indexin(cur_path) ) {
            _CVSGetRootForFile(cur_path,Roots:[cur_path]);
         }
         _str curroot=Roots:[cur_path];
         // If we set an old index to an error state, we don't have to do this
         // because it was done when the entry was put in the first MaxTimeAllowed.
         int p=lastpos(':',curroot);
         curroot=substr(curroot,p+1);
         _CVSMaybeAppendFilesep(curroot);
         ArchiveFilename=curroot:+Files[len].RCSFile',v';
         if ( Files[len].Description!='-' ) {
            if ( !file_exists(Files[len].WorkingFile) ) {
               if (Files[len].Description=='U') {
                  Files[len].Description='N';
               } else {
                  Files[len].Description='-';
               }
            }
         }
         if ( Files[len].Description!='-' ) {
            //say('1 'Files[len].WorkingFile);
            p_window_id=status_view_id;
            if ( FirstProcessing ) {
               top();up();
            }
            if ( Files[len].Description!='?' ) {
               //say('2 'Files[len].WorkingFile);
               status=search('\t'_escape_re_chars(ArchiveFilename)'$','@r'_fpos_case);
               if ( status ) {
                  top();
                  status=search('\t'_escape_re_chars(ArchiveFilename)'$','@r'_fpos_case);
                  if (status) {
                     _str AtticArchiveFilename=curroot:+_strip_filename(Files[len].RCSFile,'N'):+'Attic/'_strip_filename(Files[len].WorkingFile,'P')',v';
                     status=search('\t'_escape_re_chars(AtticArchiveFilename)'$','@r'_fpos_case);
                     if (!status) {
                        // This file was in the attic.  We want to update the rcs file entry to reflect that
                        Files[len].RCSFile=_strip_filename(Files[len].RCSFile,'N')'Attic/'_strip_filename(Files[len].WorkingFile,'P')',v';
                     }
                  }
               }
               if ( !status ) {
                  up();
                  get_line(line);
                  _str local_version;
                  parse line with 'Working revision:' "\t" local_version "\t";
                  down();
                  get_line(line);
                  _str remote_version;
                  parse line with . 'Repository revision:' "\t" remote_version "\t" .;
                  Files[len].LocalVersion=local_version;
                  Files[len].Head=remote_version;

                  if ( !descriptions_only ) {
                     status=search('Existing Tags:','@');
                     if ( !status ) {
                        // Should never get status
                        for ( ;; ) {
                           down();
                           get_line(line);
                           if ( line=='' ) break;
                           _str tagname;
                           parse line with tagname '(revision: ' version ')';
                           int vlen=Files[len].VersionList._length();
                           Files[len].VersionList[vlen].Comment=tagname;
                           Files[len].VersionList[vlen].RevisionNumber=version;
                        }
                     }
                  }
               }
            }
            p_window_id=update_view_id;
         }
      }
      if ( MaxTimeAllowed>-1 ) {
         _str t2=_time('b');
         int time_diff=(int)t2-(int)t1;
         if ( time_diff>MaxTimeAllowed ) {
            break;
         }
      }
   }
   p_window_id=orig_view_id;
   if ( done_processing ) {
      _delete_temp_view(status_view_id);
      status_view_id=0;
      _delete_temp_view(update_view_id);
      update_view_id=0;
   }
   return(0);
}

static boolean StatusLockError(int status_view_id,_str module_name,_str path='',_str &bad_path_name='')
{
   // cvs server: failed to create lock directory for `/cvs/vslick80/rt/slick/one' (/cvs/vslick80/rt/slick/one/#cvs.lock): No such file or directory
   // cvs server: failed to obtain dir lock in repository `/cvs/vslick80/rt/slick/one'
   // cvs [server aborted]: read lock failed - giving up
   bad_path_name='';
   int orig_view_id=p_window_id;
   p_window_id=status_view_id;
   top();
   int status=search('^cvs \[?@ aborted\]\:','@r');
   p_window_id=orig_view_id;

   _str search_line='cvs server: failed to obtain dir lock in repository ';
   top();
   int status2=search('^'_escape_re_chars(search_line),'@r');
   if ( !status2 ) {
      _str line,path_name;
      get_line(line);
      parse line with (search_line) path_name;
      parse path_name with '`' path_name "'";
      int p=pos(module_name,path_name);
      path_name=substr(path_name,p+length(module_name));
      bad_path_name=path:+stranslate(path_name,FILESEP,'/');
   }
   return(!status);
}

int _CVSPathExistsInTable(_str path,int (&PathTable):[])
{
#if !__UNIX__
   path=stranslate(path,FILESEP,FILESEP2);
#endif
   // Want to lookup paths in the table w/o FILESEP chars on the end
   _maybe_strip_filesep(path);

   int val=PathTable:[_file_case(path)];
   return(val==null?-1:val);
}

static void StorePathInTable(_str path,int (&PathIndexes):[],int index)
{
   // Want to store paths in the table w/o FILESEP chars on the end
   _maybe_strip_filesep(path);
   PathIndexes:[_file_case(path)]=index;
}

static _str CVSBuildRemoveCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str add_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 remove 'add_options' ');
}

int _CVSRemove(_str filelist[],_str &OutputFilename='',
               boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               boolean &updated_new_dir=false,
               _str add_options='')
{
   int status=_CVSCommand(filelist,CVSBuildRemoveCommand,&add_options,OutputFilename,append_to_output,pFiles,updated_new_dir);
   return(status);
}

static void GetSubFiles(_str path,CVS_LOG_INFO (&Files)[],
                        _str local_path,_str module_name,boolean recursive)
{
   int orig_view_id,temp_view_id;
   orig_view_id=_create_temp_view(temp_view_id);

   _str tree_opt='';
   if ( recursive ) {
      tree_opt='+t ';
   }
   insert_file_list(tree_opt' +h +d -v +p 'maybe_quote_filename(path:+FILESEP:+ALLFILES_RE));
   int new_max=Files._length()+p_Noflines+1000;
   if(_default_option(VSOPTION_WARNING_ARRAY_SIZE)<new_max) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,new_max);
   }

   top();up();
   int path_len=length(local_path);
   while ( !down() ) {
      get_line(auto line);
      line=substr(line,2);
      if ( last_char(line)==FILESEP ) {
         _str just_name=substr(line,1,length(line)-1);
         just_name=_strip_filename(just_name,'P');
         if ( just_name=='.' || just_name=='..' ) {
            continue;
         }
      }
      _str rcs_file=stranslate(substr(line,path_len+1),'/',FILESEP);
      int len=Files._length();
      Files[len].WorkingFile=line;
      Files[len].Description='?';
      Files[len].RCSFile=module_name:+rcs_file;
   }
   p_window_id=orig_view_id;

   _delete_temp_view(temp_view_id);
}

defeventtab _cvsopen_browsedir;

void _cvsopen_browsedir.lbutton_up()
{
   int wid=p_window_id;
   // TODO: save and restore def_cd variable here
   _str result=_ChooseDirDialog('', p_prev.p_text, '', CDN_ALLOW_CREATE_DIR|CDN_CHANGE_DIRECTORY);
   if ( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   if (p_object==OI_TREE_VIEW) {
      _TreeBottom();
      int lastIndex=_TreeCurIndex(); // get the index of the <double click... line
      _TreeAddItem(lastIndex,result,TREE_ADD_BEFORE);
      _TreeUp(); // select the newly added item
   } else if( p_object==OI_LIST_BOX ) {
      _lbbottom();
      _lbadd_item(result);
      _lbselect_line();
   } else {
      p_text=result;
      end_line();
   }
   _set_focus();
   return;
}
