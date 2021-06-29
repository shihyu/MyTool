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
#include "xml.sh"
#include "diff.sh"
#include "minihtml.sh"
#include "svc.sh"
#import "se/vc/IVersionControl.e"
#import "applet.e"
#import "codehelp.e"
#import "compile.e"
#import "cvsutil.e"
#import "diff.e"
#import "env.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "makefile.e"
#import "menu.e"
#import "mercurial.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "project.e"
#import "ptoolbar.e"
#import "put.e"
#import "savecfg.e"
#import "sellist.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svc.e"
#import "svcautodetect.e"
#import "taggui.e"
#import "tags.e"
#import "tbdeltasave.e"
#import "treeview.e"
#import "vc.e"
#import "wizard.e"
#import "wkspace.e"
#import "xml.e"
#endregion

using se.vc.IVersionControl;

static _str CVS_EXE_NAME() {
   return ('cvs':+EXTENSION_EXE);
}

CVS_OTHER_INFO _cvs_other_info=null;

/** 
 * This struct contains the information describing
 * what expressions to search for in version labels and
 * consider as defect ID's
 */ 
/** 
 * This is an array of regular expressions to apply against
 * version labels of source files, and map to URL's which
 * we can jump to to display more information about the
 * designated defect.
 * 
 * Each item consists of a regular expression (.re) and
 * a URL (.url).  The regular expression must contain one
 * match group isolating the actual contents of the defect ID
 * The URL must contain "\1" to indicate where the defect ID
 * must be substituted.
 */ 
VC_DEFECT_LABEL_REGEX def_vc_defect_label_regexes[] = null; 

definit()
{
   if ( arg(1)!='L' ) {
      _cvs_other_info.check_login=true;
      InitVariables();
      _cvs_other_info.CommandOptionTable=null;
   }
}

_str _CVSGetExePath() {
   return _GetCachedExePath(def_cvs_exe_path,_cvs_cached_exe_path,CVS_EXE_NAME());
}

/**
 * Initialize all of the global data that we need to keep.
 *
 * @param cvs_other_info 
 */
static void CVSInit(CVS_OTHER_INFO &cvs_other_info)
{
   // Blast the "hack dir".  This way it will get reset the first time
   // that we use it.
   cvs_other_info.cvs_hack_dir='';
   cvs_other_info.check_login=true;
}

static _str CVS_INFO_DIRNAME() {
   return  ((_isUnix()?'.':'')'vscvsinfo');
}

#if 0
static int CVSGetHackDir(_str &CVSROOT_directory)
{
   if ( _cvs_other_info!=null && _cvs_other_info.cvs_hack_dir!='' &&
        isdirectory(_cvs_other_info.cvs_hack_dir:+FILESEP:+CVS_CHILD_DIR_NAME) ) {
      _str lastroot;
      _str path=_cvs_other_info.cvs_hack_dir;
      _maybe_append_filesep(path);
      int status=_CVSGetRootForFile(path,lastroot);
      curroot := get_env('CVSROOT');
      if (status||curroot!=lastroot) {
         //_DelTree(_cvs_other_info.cvs_hack_dir,1);
         cvsdir := _cvs_other_info.cvs_hack_dir:+FILESEP:+CVS_CHILD_DIR_NAME;
         status=delete_file(cvsdir:+FILESEP'Entries');
         delete_file(cvsdir:+FILESEP'Entries.Static');
         delete_file(cvsdir:+FILESEP'Repository');
         delete_file(cvsdir:+FILESEP'Root');
         status=rmdir(cvsdir);
         delete_file(_cvs_other_info.cvs_hack_dir:+FILESEP:+'modules');
         status=rmdir(_cvs_other_info.cvs_hack_dir);
         _cvs_other_info.cvs_hack_dir='';
      }
   }
   if ( _cvs_other_info!=null && _cvs_other_info.cvs_hack_dir!='' &&
        isdirectory(_cvs_other_info.cvs_hack_dir:+FILESEP:+CVS_CHILD_DIR_NAME) ) {
      CVSROOT_directory=_cvs_other_info.cvs_hack_dir;
      return(0);
   }
   _str config_path=_ConfigPath();
   CVSROOT_directory=config_path;
   CVSROOT_directory :+= CVS_INFO_DIRNAME();

   _str orig_dir=getcwd();
   chdir(config_path,1);

   // Get a new temp filename to direct our error output into
   _str error_filename=mktemp();

   // Be sure the file is created.  W/o this, subsequent calls to error_filename
   // will return the same filename
   _CVSCreateTempFile(error_filename);

   if ( get_env('CVSROOT')=='' ) {
      cvs_login();
      if ( get_env('CVSROOT')=='' ) {
         chdir(orig_dir,1);
         return(CVS_ERROR_NOT_LOGGED_IN);
      }
   }
   // Now we are in the new temp directory.  Checkout the CVSROOT/modules file.
   // This file should is usually there
   // We are going to run a command that will list the modules, but cvs is not
   // satisified unless a directory checked out from cvs is active.  This is why
   // we checkout this file.
   int status=_CVSShell(_CVSGetExeAndOptions()' 2>'_maybe_quote_filename(error_filename)' -d 'get_env('CVSROOT')' co -d 'CVS_INFO_DIRNAME()' CVSROOT/modules',config_path,def_cvs_shell_options);
   if ( status ) {

      bool cvs_login_error,cvs_checkout_error;
      status=HadCVSLoginError(error_filename,cvs_login_error);
      if ( cvs_login_error ) {
         status=CVS_ERROR_NOT_LOGGED_IN;
      }else{
         status=HadCVSCheckoutError(error_filename,cvs_checkout_error);
         if ( cvs_checkout_error ) status=CVS_ERROR_CHECKOUT_FAILED_RC;
      }

      quiet := !cvs_checkout_error;
      // If we had a checkout error, be quiet about it because the user will be
      // notified and prompted for a module name
      CleanupCVSListModulesError(nls("Could not get modules"),config_path,error_filename,cvs_checkout_error);
      CVSROOT_directory='';
      delete_file(error_filename);
      chdir(orig_dir,1);
      return(status);
   }
   delete_file(error_filename);
   _cvs_other_info.cvs_hack_dir=CVSROOT_directory;

   chdir(orig_dir,1);
   return(0);
}

static void CleanupCVSListModulesError(_str NLSErrorMessage,_str OrigDirectory,_str ErrorFilename,
                                       bool Quiet=false,int LastOperationStatus=0)
{
   chdir(OrigDirectory,1);
   if ( ErrorFilename!='' ) {
      if (!Quiet) {
         _SVCDisplayErrorOutputFromFile(ErrorFilename,LastOperationStatus);
      }
      delete_file(ErrorFilename);
   }
}

static int SwtichToCVSHackDir()
{
   CVSROOT_directory := "";
   int status=CVSGetHackDir(CVSROOT_directory);
   if ( status ) {
      return(status);
   }
   status=chdir(CVSROOT_directory,1);
   if ( status ) {
      if ( status==FILE_NOT_FOUND_RC||
           status==PATH_NOT_FOUND_RC ) {
         _cvs_other_info.cvs_hack_dir='';
         CVSGetHackDir(CVSROOT_directory);
         status=chdir(CVSROOT_directory,1);
      }
      if ( status ) {
         return(status);
      }
   }
   return(0);
}

static int CVSGetModuleList(_str (&ModuleNames)[])
{
   ModuleNames=null;
   // Dennis figured this one out.  It is pretty gross, but it works reliably
   // cross platform

   // Save the current directory, and switch to the temp directory
   _str orig_directory=getcwd();

   // Get a temp directory name and make our own directory
   int status=SwtichToCVSHackDir();
   if ( status ) {
      CleanupCVSListModulesError(nls("Could not switch to temporary directory\n\n%s",get_message(status)),orig_directory,'');
      return(status);
   }

   // Get a new temp filename to direct our output to
   _str output_filename=mktemp();

   status=_CVSShell(_CVSGetExeAndOptions()' 2>'_maybe_quote_filename(output_filename)' -n co .',getcwd(),def_cvs_shell_options);
   if ( status ) {
      CleanupCVSListModulesError(nls("Could not get modules"),orig_directory,output_filename,false,status);
      return(status);
   }

   status=chdir(orig_directory,1);
   if ( status ) {
      _message_box(nls("Could not switch to original directory '%s'\n\n%s",orig_directory,get_message(status)));
   }
   GetModuleNamesFromOutput(output_filename,ModuleNames);
   delete_file(output_filename);
   return(0);
}

/**
 *
 * @param ModuleName
 * @param SubModules
 * @param WorkspaceFiles
 *                   This parameter must be intialized to null before passing it
 *                   in.  This is so this function can add to an existing list.
 * @param pfnPreCall Callback to call before _CVSShell call.
 *
 *                   These are used to show a dialog while the process is running
 * @param pfnPostCall
 *                   Callback to call after _CVSShell call
 *
 * @return
 */
static int CVSGetSubModuleList(_str ModuleName, _str (&SubModules)[],
                               _str (&WorkspaceFiles):[]=null,
                               typeless *pfnPreShellCallback=null,
                               typeless *pfnPostShellCallback=null)
{
   _str orig_directory=getcwd();

   cvsroot_path := "";
   int status=SwtichToCVSHackDir();
   if ( status ) {
      CleanupCVSListModulesError(nls("Could not get modules"),orig_directory,'');
      return(status);
   }
   _str output_filename=mktemp();

   status=_CVSShell(_CVSGetExeAndOptions()' 2>'_maybe_quote_filename(output_filename)' co -r BASE -f '_maybe_quote_filename(ModuleName),cvsroot_path,def_cvs_shell_options'A',false,pfnPreShellCallback,pfnPostShellCallback);
   if ( status ) {
      CleanupCVSListModulesError(nls("Could not get modules"),orig_directory,'');
      return(status);
   }

   status=GetSubmoduleNamesFromOutput(output_filename,ModuleName,SubModules,WorkspaceFiles);
   if ( status ) {
      CleanupCVSListModulesError(nls("Could not get modules"),orig_directory,'');
      return(status);
   }
   chdir(orig_directory,1);
   return(0);
}

static const CVS_CO_UPDATING_DOT_LINE=  'cvs server: Updating .';
static const CVS_CO_UPDATING_LINE=      'cvs server: Updating ';
static const CVS_CO_CHECKOUT_LINE=      'cvs checkout: Updating ';
static const CVS_CO_NOTHING_KNOWN_LINE= 'cvs server: nothing known about ';
static const CVS_CO_LOSTFOUND_LINE=     "cvs server: New directory `lost+found' -- ignored";
static const CVS_CO_LINE_PREFIX_RE=     "cvs (server|checkout)\\: New directory `";
static const CVS_CO_LINE_SUFFIX=        "' -- ignored";

static int GetModuleNamesFromOutput(_str output_filename,_str (&ModuleNames)[])
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(output_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();up();
   while ( !down() ) {
      get_line(auto line);
      if ( line==CVS_CO_UPDATING_DOT_LINE ||
           line==CVS_CO_LOSTFOUND_LINE ) {
         continue;
      }
      next_index := ModuleNames._length();
      cur := "";
      parse line with (CVS_CO_LINE_PREFIX_RE),'r'  cur (CVS_CO_LINE_SUFFIX);
      if ( cur!='' ) {
         ModuleNames[next_index]=cur;
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int GetSubmoduleNamesFromOutput(_str Filename,_str ModuleName,
                                       _str (&SubModules)[],_str (&WorkspaceFiles):[])
{
   int orig_view_id,temp_view_id;

   int status=_open_temp_view(Filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();up();
   while ( !down() ) {
      get_line(auto line);
      if ( substr(line,1,length(CVS_CO_UPDATING_LINE))==CVS_CO_UPDATING_LINE ) {
         _str cur;
         parse line with (CVS_CO_UPDATING_LINE) cur;
         if ( cur!=ModuleName ) {
            SubModules[SubModules._length()]=cur;
         }
      } else if ( substr(line,1,length(CVS_CO_CHECKOUT_LINE))==CVS_CO_CHECKOUT_LINE ) {
         _str cur;
         parse line with (CVS_CO_CHECKOUT_LINE) cur;
         if ( cur!=ModuleName ) {
            SubModules[SubModules._length()]=cur;
         }
      } else if ( substr(line,1,length(CVS_CO_NOTHING_KNOWN_LINE))==CVS_CO_NOTHING_KNOWN_LINE ) {
         _str cur;
         parse line with (CVS_CO_NOTHING_KNOWN_LINE) cur;
         if ( _file_eq(_get_extension(cur,true),WORKSPACE_FILE_EXT) ) {
            _str curpath=_file_path(cur);
            index := _file_case(curpath);
            index=substr(index,1,length(index)-1);
            if ( WorkspaceFiles._indexin(index) ) {
               WorkspaceFiles:[index] :+= ' '_maybe_quote_filename(cur);
            } else {
               WorkspaceFiles:[index]=_maybe_quote_filename(cur);
            }
         }
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   delete_file(Filename);

   return(0);
}

void _CVSGetLogInfo(_str filename,CVS_LOG_INFO &info,int HistoryViewId)
{
   orig_view_id := p_window_id;
   p_window_id=HistoryViewId;
   GetSimpleField('RCS file:',info.RCSFile);
   GetSimpleField('Working file:',info.WorkingFile);
   GetSimpleField('head:',info.Head);
   GetSimpleField('branch:',info.BranchFromLog);
   GetSimpleField('keyword substitution:',info.KeywordType);
   //GetBranches(info.BranchesTable);
   GetDescription(info.Description);
   GetVersions(info.VersionList);
   GetSymbolicNames(info.pSymbolicNames,info.VersionList,info.Branches);
   GetStatus(info.Status,info.CurBranch);
   CVSGetEntriesFileInfo(filename,info.LocalVersion);
   p_window_id=orig_view_id;
}

static void GetSimpleField(_str FieldName,_str &FieldValue)
{
   top();up();
   FieldValue='';
   int status=search('^'_escape_re_chars(FieldName),'@r');
   if ( status ) {
      return;
   }
   get_line(auto line);
   parse line with (FieldName) FieldValue;
}

static void GetDescription(_str &Description)
{
   Description='';
   top();
   status := search('^description:','@r');
   if ( !status ) {
      get_line(auto line);
      line=substr(line,13);
      Description=line;
      for ( ;; ) {
         get_line(line);
         if ( line=='----------------------------' ) {
            break;
         }
         Description :+= "\n"line;
      }
   }
}

static void GetVersions(CVS_VERSION_INFO (&VersionList)[])
{
   CVS_VERSION_INFO CurVersion;
   for ( ;; ) {
      status := search('^revision ','@r>');
      if ( status ) {
         break;
      }
      GetVersion(CurVersion);
      InsertVersionIntoList(VersionList,CurVersion);
   }
}

static void GetVersion(CVS_VERSION_INFO &CurVersion)
{
   get_line(auto line);
   parse line with 'revision 'CurVersion.RevisionNumber;
   down();
   get_line(line);
   parse line with 'date: 'CurVersion.Date';' 'author: 'CurVersion.Author';';
   down();
   get_line(line);
   CurVersion.Branches=null;
   if ( substr(line,1,9)=='branches:' ) {
      _str Branches;
      parse line with 'branches:' Branches;
      for ( ;; ) {
         _str cur;
         parse Branches with cur Branches;
         if ( cur=='' ) break;
         CurVersion.Branches[CurVersion.Branches._length()]=cur;
      }
   } else {
      up();
   }
   CurVersion.Comment='';
   for ( ;; ) {
      down();
      get_line(line);
      if ( line=='----------------------------'||
           line=='=============================================================================' ) {
         break;
      }
      CurVersion.Comment=CurVersion.Comment"\n"line;
   }
   CurVersion.Comment=substr(CurVersion.Comment,2);
}

static void InsertVersionIntoList(CVS_VERSION_INFO (&VersionList)[],CVS_VERSION_INFO CurVersion)
{
   array_top := 0;
   int array_bottom=VersionList._length()-1;
   int array_mid=array_bottom intdiv 2;
   ItemIndex := -1;
   int i;

   OldMid := -1;
   for ( ;; ) {
      if ( array_bottom<0 ) {
         ItemIndex=OldMid;
         for ( i=VersionList._length()-1;i>=0;--i ) {
            VersionList[i+1]=VersionList[i];
         }
         VersionList[0]=CurVersion;
         return;
      }
      if ( array_top>array_bottom ) {
         // This case seems a little ambiguous with regards to before or after.
         // Return the last 'status' variable, that will be right.
         //ItemIndex=OldMid;
         ItemIndex=array_mid;
         for ( i=VersionList._length()-1;i>=ItemIndex;--i ) {
            VersionList[i+1]=VersionList[i];
         }
         VersionList[ItemIndex]=CurVersion;
         return;
      }
      int status=VersionNumberCompare(CurVersion.RevisionNumber,VersionList[array_mid].RevisionNumber);
      if ( !status ) {
         break;// found a match
      } else if ( status<0 ) {
         array_bottom=array_mid-1;
      } else if ( status>0 ) {
         array_top=array_mid+1;
      }
      OldMid=array_mid;
      array_mid=((array_bottom-array_top)intdiv 2)+array_top;
   }
   ItemIndex=array_mid;
   for ( i=VersionList._length()-1;i>=ItemIndex;--i ) {
      VersionList[i+1]=VersionList[i];
   }
   VersionList[ItemIndex]=CurVersion;
}

static void GetSymbolicNames(typeless &pSymbolicNames,CVS_VERSION_INFO (&VersionList)[],CVS_VERSION_INFO (&BranchList)[])
{
   top();
   status := search('^symbolic names\:','@r');
   if ( status ) {
      return;
   }
   for ( ;; ) {
      down();
      get_line(auto line);
      if ( substr(line,1,1)!="\t" ) break;
      _str tagname,version;
      parse line with "\t@","r" tagname': 'version;
      found := false;
      int i;
      for ( i=0;i<VersionList._length();++i ) {
         if ( VersionList[i].RevisionNumber:==version ) {
            pSymbolicNames:[tagname]=&VersionList[i];
            found=true;break;
         }
      }
      if ( !found ) {
         if ( pos('.0.',version) ) {
            len := BranchList._length();
            BranchList[len]=null;
            BranchList[len].RevisionNumber=version;
            BranchList[len].Comment=tagname;
         }
      }
   }
}

static void GetStatus(_str &FieldValue,_str &CurBranch)
{
   top();up();
   FieldValue=CurBranch='';
   status := search('^File\: ?@\tStatus\: ?@$','@r');
   if ( status ) {
      return;
   }
   get_line(auto line);
   parse line with '^File\: ?@\tStatus\: ','r' FieldValue;
   status=search('^   Sticky Tag\:?@\(branch\: ?@\)','@r');
   if ( status ) return;
   get_line(line);
   CurBranch='';
   if ( pos('   Sticky Tag\:?@\(branch\: ?@\)',line,1,'r') ) {
      parse line with '(branch: 'CurBranch')';
   }
}

static int CVSGetEntriesFileInfo(_str filename,_str &version,_str &timestamp='',_str &options='',_str &tagname='')
{
   version='';
   entries_filename := _strip_filename(filename,'N'):+CVS_CHILD_DIR_NAME:+FILESEP'Entries';
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(entries_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();up();
   status=search('^/'_escape_re_chars(_strip_filename(filename,'P'))'/','@r'_fpos_case);
   if ( status ) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return(status);
   }
   _str line,name;
   get_line(line);
   parse line with '/' name '/' version '/' timestamp '/' options '/' tagname;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int VersionNumberCompare(_str RevisionNumber1,_str RevisionNumber2)
{
   for ( ;; ) {
      _str cur1,cur2;
      parse RevisionNumber1 with cur1 '.' RevisionNumber1;
      parse RevisionNumber2 with cur2 '.' RevisionNumber2;
      if ( cur1!=cur2 ) {
         if ( cur1=='' ) {
            return(-1);
         } else if ( cur2=='' ) {
            return(1);
         }
         return((int)cur1-(int)cur2);
      }
      if ( cur1==cur2 && cur2=='' ) {
         return(0);
      }
   }
}

static int CVSGetWorkspaceFiles(_str filename,_str (*pProjectFiles)[])
{
   int status=_GetWorkspaceFiles(filename,(*pProjectFiles));
   return(status);
}

static int CVSGetProjectConfigurations(_str filename,ProjectConfig (*pConfigs)[])
{
   associated := 0;
   int status=getProjectConfigs(filename,(*pConfigs),associated);
   return(status);
}

static int CVSGetFileInfo(_str archive_filename,CVS_LOG_INFO &info,
                          _str checkout_tag='',
                          typeless *pfnCallback=null,typeless *pCallbackData=null)
{

   _str ErrorFilename=mktemp();
   _CVSCreateTempFile(ErrorFilename);

   _str temp_sub_path=mktemp();
   temp_path := _strip_filename(temp_sub_path,'N');

   rel_temp_sub_path := _strip_filename(temp_sub_path,'P');

   _str orig_directory=getcwd();
   chdir(temp_path);


   tag_option := "";
   if ( checkout_tag!='' ) {
      tag_option=' -r '_maybe_quote_filename(checkout_tag);
   }
   int status=_CVSShell(_CVSGetExeAndOptions()' co >'_maybe_quote_filename(ErrorFilename)' 2>&1 -d '_maybe_quote_filename(rel_temp_sub_path)' 'tag_option' '_maybe_quote_filename(archive_filename),temp_path,def_cvs_shell_options);
   chdir(orig_directory,1);
   if ( status ) {
      _SVCDisplayErrorOutputFromFile(ErrorFilename,status);
      delete_file(ErrorFilename);
      return(status);
   }
   _str OutputFilename=mktemp();
   status=_CVSShell(_CVSGetExeAndOptions()' log >'_maybe_quote_filename(OutputFilename)' 2>&1 '_maybe_quote_filename(_strip_filename(archive_filename,'P')),temp_sub_path,def_cvs_shell_options);
   if ( status ) {
      _SVCDisplayErrorOutputFromFile(OutputFilename,status);
      delete_file(OutputFilename);
      return(status);
   }
   int temp_view_id,orig_view_id;
   status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
   if ( status ) {
      _message_box(nls("Could not expand file versions"));
      delete_file(OutputFilename);
      return(status);
   }
   p_window_id=orig_view_id;
   _CVSGetLogInfo(OutputFilename,info,temp_view_id);

   _delete_temp_view(temp_view_id);
   if ( pfnCallback ) {
      (*pfnCallback)(temp_sub_path:+FILESEP:+_strip_filename(archive_filename,'P'),pCallbackData);
   }
   delete_file(OutputFilename);
   delete_file(ErrorFilename);
   _DelTree(temp_sub_path,true);
   return(status);
}

static int CVSGetModuleRTags(_str module_name,_str (&Tags)[])
{
   Tags=null;
   _str OutputFilename=mktemp();
   _maybe_strip(module_name, '/');
   int status=_CVSShell(_CVSGetExeAndOptions()' history -T -a -n 'module_name'>'_maybe_quote_filename(OutputFilename),'',def_cvs_shell_options);
   if ( status ) {
      return(status);
   }

   int temp_view_id,orig_view_id;
   status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
   if ( status ) {
      delete_file(OutputFilename);
      return(status);
   }
   p_window_id=temp_view_id;
   int TagIndexes:[]=null;
   top();up();
   i := 0;
   while ( !down() ) {
      get_line(auto line);
      _str code=parse_file(line);
      _str date=parse_file(line);
      _str time=parse_file(line);
      _str time_offset=parse_file(line);
      _str user=parse_file(line);
      _str module_name2=parse_file(line);
      _str tag_info=parse_file(line);
      _str tag,tag_name,suffix;
      parse tag_info with '[' tag ']';
      parse tag with tag_name ':' suffix;

      if ( tag_name=='' ) continue;
      if ( suffix=='D' ) {
         TagIndexes._deleteel(tag_name);
      } else {
         TagIndexes:[tag_name]=1;
      }
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   delete_file(OutputFilename);

   typeless j;
   for ( j=null;; ) {
      TagIndexes._nextel(j);
      if ( j==null ) break;
      Tags[Tags._length()]=j;
   }

   return(status);
}

static const CVS_NOT_LOGGED_IN_ERROR_RE= "(^cvs checkout\\: used empty password; try \"cvs login\" with a real password$)|(^cvs checkout\\: No CVSROOT specified!  Please use the `-d' option)";
static const SVN_NOT_LOGGED_IN_ERROR_RE= "(^svn\\: Can't get password)";
static const CVS_CHECKOUT_ERROR_RE=      '^cvs \[(checkout|server) aborted\]\: ?@$';

/**
 *
 * @param PathMayContainRoot
 *               Must end in trailing filesep
 *
 * @return
 */
static int CVSCheckSetup(_str PathMayContainRoot='')
{

   // Check to see if the exe was not found.
   cvs_filename := _maybe_quote_filename(_CVSGetExePath());
   if ( cvs_filename=='' ) {
      return(CVS_ERROR_EXE_NOT_FOUND);
   }

   status := -1;
   root_value := "";
   if ( PathMayContainRoot!='' ) {
      status=_CVSGetRootForFile(PathMayContainRoot,root_value);
   }

   if ( status || root_value=='' ) {
      _str tempdir=mktemp();

      _str tempdir_parent=tempdir;
      _maybe_strip_filesep(tempdir_parent);
      tempdir_parent=_strip_filename(tempdir_parent,'N');
      _str ErrorFilename=mktemp();
      _str orig_dir=getcwd();
      chdir(tempdir_parent,1);
      reldir := relative(tempdir,tempdir_parent);
      status=_CVSShell(_CVSGetExeAndOptions()' co >'ErrorFilename' 2>&1 -d 'reldir' CVSROOT/modules',tempdir_parent,def_cvs_shell_options);
      chdir(orig_dir,1);
      if ( status ) {
         // What do we do here?  If there is a status, but we appear to be
         // logged in, odds are there are still going to be problems later.

         cvs_login_error := false;
         status=HadCVSLoginError(ErrorFilename,cvs_login_error);
         if ( status ) {
            //Error file probably doesn't exist
            if ( isdirectory(tempdir) ) {
               status=_DelTree(tempdir,true);
            }
            delete_file(ErrorFilename);
            return(1);
         }

         if ( cvs_login_error ) status=CVS_ERROR_NOT_LOGGED_IN;
      }
      delete_file(ErrorFilename);
      if ( isdirectory(tempdir) ) {
         status=_DelTree(tempdir,true);
         if ( status ) return(status);
      }
   }

   status=CVSGetHackDir(_cvs_other_info.cvs_hack_dir);
   return(status);
}

static int HadCVSError(_str output_filename,bool &CVSError,_str SearchStr)
{
   CVSError=false;
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(output_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   status=search(SearchStr,'@r');
   if ( !status ) {
      CVSError=true;
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

/**
 * Searches output for a CVS login error
 *
 * @param filename
 *               File with output from a cvs command
 *
 * @return true if evidence is found that the problem was the user was not logged in
 */
static int HadCVSLoginError(_str output_filename,bool &CVSLoginError,bool &SVNPasswordError=false)
{
   status1 := HadCVSError(output_filename,CVSLoginError,CVS_NOT_LOGGED_IN_ERROR_RE);
   status2 := HadCVSError(output_filename,SVNPasswordError,SVN_NOT_LOGGED_IN_ERROR_RE);
   return( status1|status2 );
}

static int HadCVSCheckoutError(_str output_filename,bool &CVSLoginError)
{
   return( HadCVSError(output_filename,CVSLoginError,CVS_CHECKOUT_ERROR_RE) );
}

int _CVSCheckout(_str module_name,_str directory_name,_str checkout_options='',_str &OutputFilename='',
                 bool quiet=false,bool debug=false,bool NoHourglass=false)
{
   _str parent_directory=_GetParentDirectory(directory_name);
   rel_dir := relative(directory_name,parent_directory);
   _maybe_strip(rel_dir, FILESEP, stripFromFront:true);
   _maybe_strip_filesep(rel_dir);
   typeless *pfnPreShellCallback=null,pfnPostShellCallback=null;
   caption := "";
   if ( !quiet ) {
      pfnPreShellCallback=_CVSShowStallForm;
      pfnPostShellCallback=_CVSKillStallForm;
      caption='Checking out 'module_name;
   }
   append_to_output := true;
   if (OutputFilename=='') {
      OutputFilename=mktemp();
      append_to_output=false;
   }
   int status=_CVSCall('co','','','-d 'rel_dir' 'checkout_options' '_maybe_quote_filename(module_name),parent_directory,OutputFilename,
                      append_to_output,false,pfnPreShellCallback,pfnPostShellCallback,&caption,NoHourglass);
   if (OutputFilename!='' && !status) {
      int temp_view_id,orig_view_id;
      status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
      if (!status) {
         top();up();
         status=(int)!search('aborted','@');
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
   }
   return(status);
}
static _str BuildEditCommand(typeless *pdata,_str output_filename,bool append_to_output)
{
   appendop := '>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str edit_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+_maybe_quote_filename(output_filename)' 2>&1 edit 'edit_options' ');
}

static _str BuildAnnotateCommand(typeless *pdata,_str output_filename,bool append_to_output)
{
   appendop := '>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str edit_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+_maybe_quote_filename(output_filename)' 2>&1 annotate 'edit_options' ');
}

static _str CVSBuildUpdateCommand(typeless *pdata,_str output_filename,bool append_to_output)
{
   appendop := '>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str update_options=*pdata;
   return(_CVSGetExeAndOptions()' 'appendop:+_maybe_quote_filename(output_filename)' 2>&1 update -d 'update_options' ');
}

static int CVSEdit(_str filelist[],_str &OutputFilename='',
                   bool append_to_output=false,
                   CVS_LOG_INFO (*pFiles)[]=null,
                   bool &updated_new_dir=false,_str EditOptions='')
{
   int i,len=filelist._length();
   for (i=0;i<len;++i) {
      if (filelist[i]=='') {
         _message_box(nls("Cannot edit blank filename"));
         return(1);
      }
      _LoadEntireBuffer(filelist[i]);
   }
   int status=_CVSCommand(filelist,BuildEditCommand,&EditOptions,OutputFilename,append_to_output,pFiles,updated_new_dir);
   _reload_vc_buffers(filelist);
   return(status);
}

int _CVSUpdate(_str filelist[],_str &OutputFilename='',
              bool append_to_output=false,
               CVS_LOG_INFO (*pFiles)[]=null,
              bool &updated_new_dir=false,_str UpdateOptions='',
              int gaugeParent=0)
{
   int i,len=filelist._length();
   for (i=0;i<len;++i) {
      if (filelist[i]=='') {
         _message_box(nls("Cannot update blank filename"));
         return(1);
      }
      _LoadEntireBuffer(filelist[i]);

      // Re-cache any updated project files
      _str ext=_get_extension(filelist[i],true);
      if ( _file_eq(ext,PRJ_FILE_EXT) ) {
         _ProjectCache_Update(filelist[i]);
      }
   }
   int status=_CVSCommand(filelist,CVSBuildUpdateCommand,&UpdateOptions,OutputFilename,append_to_output,pFiles,updated_new_dir);
   _reload_vc_buffers(filelist);
   _retag_vc_buffers(filelist);
   if ( gaugeParent ) {
      cancel_form_set_parent(gaugeParent);
   }
   toolbarUpdateFilterList(_project_name);
   return(status);
}

/**
 * Takes a file list and gives a "reduced" hashtable, where
 * the indexes are paths, and values are a space delimeted
 * list of relative filenames.  I call it a reduced list
 * because files are grouped under the lowest directory possible.
 *
 * @param file_list list of files to commit
 * @param file_hashtab
 *                  hash table to store the "reduced" lists
 */
static void GetCommitFileHashTable(_str file_list,_str (&file_hashtab):[])
{
   _str files[]=null;
   for ( ;; ) {
      _str cur=parse_file(file_list);
      if ( cur=='' ) break;
      files[files._length()]=cur;
   }
   files._sort('F');

   _str short_indexes:[]=null;
   int i;
   for ( i=0;i<files._length();++i ) {
      _str cur=files[i];
      if ( cur=='' ) break;
      _str cur_path=_file_path(cur);
      if ( file_hashtab._indexin(cur_path) ) {
         AppendToHashtab(relative(cur,cur_path),cur_path,file_hashtab);
      } else {
         _str index=FindHashtabIndexForPath(cur_path,short_indexes);
         AppendToHashtab(relative(cur,index),index,file_hashtab);
      }
   }
}

static void AppendToHashtab(_str item,_str index,_str (&hash_tab):[])
{
   if ( hash_tab._indexin(index) ) {
      hash_tab:[index]:+=' '_maybe_quote_filename(item);
   } else {
      hash_tab:[index]=_maybe_quote_filename(item);
   }
}

static _str FindHashtabIndexForPath(_str cur_path,_str (&short_indexes):[])
{
   if ( short_indexes._indexin(cur_path) ) {
      return(short_indexes:[cur_path]);
   }
   if ( short_indexes==null ) {
      short_indexes:[cur_path]=cur_path;
   } else {
      // We know it doesn't exist
      typeless i;
      for ( i._makeempty();; ) {
         short_indexes._nextel(i);
         if ( i==null ) break;
         _str cur_hash_entry=short_indexes:[i];

         trunc := substr(cur_path,1,length(cur_hash_entry));

         if ( _file_eq( trunc , cur_hash_entry ) ) {
            short_indexes:[cur_path]=trunc;
            break;
         }
      }
   }
   return(short_indexes:[cur_path]);
}

static int ReduceHashtabPaths(_str (&file_hashtab):[])
{
   typeless i;
   for ( i._makeempty();; ) {
      file_hashtab._nextel(i);
      if ( i._isempty() ) break;

      typeless j;
      for ( j._makeempty();; ) {
         file_hashtab._nextel(j);
         if ( j._isempty() ) break;

         if ( i==j ) continue;

         longer_trunc := substr(j,1,length(i));

         if ( _file_eq(i,longer_trunc) ) {

            file_hashtab:[i] :+= ' ' file_hashtab:[j];
            file_hashtab._deleteel(j);
            return(1);
         }
      }
   }
   return(0);
}

int _CVSCall(_str command,_str global_opts,_str command_opts,
             _str command_args,_str file_or_path,_str &OutputFilename,
             _str append_to_output=false,bool debug=false,
             typeless *pfnPreShellCallback=null,
             typeless *pfnPostShellCallback=null,
             typeless *pData=null,
             bool NoHourglass=false,
             typeless *pfnGetExeAndOptions=_CVSGetExeAndOptions,
             bool checkCVSDashD=true)
{
   if ( !append_to_output ) {
      OutputFilename=mktemp();
   }

   appendop := append_to_output?'>':'';
   _str cmdstr=(*pfnGetExeAndOptions)()' >'appendop:+_maybe_quote_filename(OutputFilename)' 2>':+'&1 'command' 'command_opts' 'command_args;
   int status=_CVSShell(cmdstr,file_or_path,def_cvs_shell_options,debug,pfnPreShellCallback,pfnPostShellCallback,pData,-1,NoHourglass,checkCVSDashD);
   if ( status ) {
      exe_name := _SVCGetEXEName();
      if ( exe_name=='' ) {
         return(CVS_ERROR_EXE_NOT_FOUND);
      } else {
         int log_check_status = HadCVSLoginError(OutputFilename,auto cvs_login_error,auto svn_password_error);
         if ( log_check_status ) {
            return(log_check_status);
         }
         if ( cvs_login_error ) {
            return(CVS_ERROR_NOT_LOGGED_IN);
         }
         if ( svn_password_error ) {
            return SVN_ERROR_CANT_GET_PASSWORD;
         }
         status = file_exists(exe_name) ? 0:CVS_ERROR_EXE_NOT_FOUND;
      }
   }

   return(status);
}

static int CVSCheckLogin(_str PathMayContainRoot='')
{
   int status=CVSCheckSetup(PathMayContainRoot);
   if ( status==CVS_ERROR_NOT_LOGGED_IN ) {
      status=cvs_login();
   } else if ( status==CVS_ERROR_EXE_NOT_FOUND ) {
      _message_box("Please put the cvs executable in your path");
   }
   return(status);
}

_command int cvs_commit(typeless filename='',_str comment=NULL_COMMENT,typeless *pfnCommit=_CVSCommit) name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_commit(filename,comment);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:10am 1/7/2015
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to commit',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   _str file_list[];
   file_list[0]=filename;
   if (_SVCListModified(file_list)==COMMAND_CANCELLED_RC) {
      return COMMAND_CANCELLED_RC;
   }
   _str comment_filename=mktemp();
   tag := "";
   status := 0;
   if ( comment!=NULL_COMMENT ) {
      int temp_wid;
      int orig_wid=_create_temp_view(temp_wid);
      _insert_text(comment);
      status=_save_config_file(comment_filename);
      p_window_id=orig_wid;
      _delete_temp_view(temp_wid);
   }else{
      showTag := pfnCommit==_CVSCommit;
      status=_CVSGetComment(comment_filename,tag,filename,false,false,showTag);
      if ( status ) {
         delete_file(comment_filename);
         return(status);
      }
   }
   filenameNQ := strip(filename,'B','"');
   if ( !file_exists(filenameNQ) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   _str temp[]=null;
   temp[0]=filenameNQ;
   OutputFilename := "";
   status=(*pfnCommit)(temp,comment_filename,OutputFilename,true,'',false,0,tag);
   if ( OutputFilename!="" ) {
      _SVCDisplayErrorOutputFromFile(OutputFilename,status,0,false,false);
   }
   
   if (!status) {
      _str cvs_comment = _param3;
      if (strip(cvs_comment) == '') {
         cvs_comment = "CVS Commit";
      } else {
         cvs_comment = "CVS Commit:\n" :+ cvs_comment;
      }
      //DS_SetMostRecentComment(filename, cvs_comment);
   }
   //return 0;
   
   
   // Need to reload buffers because this may have updated version tags, etc
   // in the file.
   delete_file(OutputFilename);
   delete_file(comment_filename);
   return(status);
#endif
}

_command int cvs_add(_str filename='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_add(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:11am 1/7/2015
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to add',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   if (substr(filename,1,1)=='"') {
      filename=strip(filename,'B','"');
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   _str temp[]=null;
   temp[0]=filename;
   OutputFilename := "";
   int status=_CVSAdd(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

_command int cvs_edit_update(_str filename='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_edit(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:12am 1/7/2015
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to add',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   _str temp[]=null;
   temp[0]=filename;
   OutputFilename := "";
   int status=_CVSUpdate(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   if ( !status ) {
      status=CVSEdit(temp,OutputFilename);
      _SVCDisplayErrorOutputFromFile(OutputFilename,status);
      delete_file(OutputFilename);
   }
   return(status);
#endif
}


_command int cvs_remove(_str filename='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_remove(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:16am 1/7/2015
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to remove',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   int result=_message_box(nls("'%s' must be deleted before it can be removed from CVS.\n\nDelete file now?",filename),'',MB_YESNOCANCEL);
   if ( result!=IDYES ) {
      return(COMMAND_CANCELLED_RC);
   }
   int status=delete_file(filename);
   if ( status ) {
      _message_box(nls("Could not delete file '%s'\n\n%s",filename,get_message(status)));
      return(status);
   }

   _str temp[]=null;
   temp[0]=filename;
   OutputFilename := "";
   status=_CVSRemove(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

_command int cvs_update(_str filename='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_update(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:17am 1/7/2015
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to update',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }

   ismodified := _SVCBufferIsModified(filename);
   if ( ismodified ) {
      _message_box(nls("Cannot update file '%s' because the file is open and modified",filename));
      return 1;
   }
     
   _str temp[]=null;
   temp[0]=filename;
   OutputFilename := "";
   status := _CVSUpdate(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

_command int cvs_update_directory,cvs_gui_mfupdate(_str path='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_gui_mfupdate(path);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:18am 1/7/2015
   if ( path=='' ) {
      path=_CVSGetPath();
      if ( path=='' ) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   _maybe_append_filesep(path);
   _str list=path;
   recurse_option:=false;
   tag_name := "";
   for ( ;; ) {
      _str cur=parse_file(path);
      ch := substr(cur,1,1);
      if ( ch=='+' || ch=='-' ) {
         switch ( lowcase(substr(cur,2)) ) {
         case 'r':
            recurse_option=true;
            break;
         case 't':
            tag_name=parse_file(path);
            break;
         }
      } else {
         path=cur;
         break;
      }
   }
   path=absolute(path);

   could_not_verify_setup:=false;
   int status=CVSCheckLogin(path);
   if ( status==COMMAND_CANCELLED_RC ) {
      return(status);
   }else if ( status ) could_not_verify_setup=true;

   if ( !IsCVSFile(path) ) {
      _message_box(nls("'%s' was not checked out from CVS",path));
      return(1);
   }

   CVS_LOG_INFO Files[]=null;
   module_name := "";
   status=_CVSGetVerboseFileInfo(path,Files,module_name,recurse_option,'',true,_CVSShowStallForm,_CVSKillStallForm,null,null);
   if (status) {
      if (could_not_verify_setup) {
         _message_box(nls("Could not get cvs update information.\n\nSlickEdit's CVS setup check also failed.  You may not have read access to these files, or your cvs setup may be incorrect."));
      }
      return(status);
   }
   if ( Files._length() ) {
      CVSGUIUpdateDialog(Files,path,module_name,recurse_option);
   } else if ( !status ) {
      _message_box(nls("All files up to date"));
   }

   return(0);
#endif
}

/**
 * Displays a directory dialog to the user to let them
 * choose a path.
 *
 * @param caption Caption for the dialog.
 *
 * @return '' if cancelled
 *
 *         [+r] &lt;path&gt;
 *
 *         path will always end in a trailing FILESEP.
 *
 *         +r is prepended to the path if the recursive check box
 *         is on.
 */
_str _CVSGetPath(_str caption='Choose path',_str retrieve_name='')
{
   return(show('-modal _cvs_path_form',caption,retrieve_name));
}

static _str updateGetPathFromTree(int index=-1)
{
   if ( index<0 ) {
      index=_TreeCurIndex();
   }
   path := "";
   curCap := _TreeGetCaption(index);
   if ( _last_char(curCap)==FILESEP ) {
      path = curCap;
   }else{
      parentIndex := _TreeGetParentIndex(index);
      if ( parentIndex>-1 && parentIndex!=TREE_ROOT_INDEX ) {
         curPath := _TreeGetCaption(parentIndex);
         path = curPath:+curCap;
      }
   }
   return(path);
}

/**
 * returns true if <B>filename</B> is a file that was checked
 * out from CVS.  Does this by looking to see if a CVS
 * directory exists under filename's directory.  Not a terribly
 * strong check.
 *
 * @param filename filename to check
 *
 * @return true if file is a cvs file.
 */
static bool IsCVSFile(_str filename)
{
   filename=absolute(filename);
   _str path=filename;
   if ( !isdirectory(path) ) {
      path=_strip_filename(filename,'N');
   }
   _maybe_append_filesep(path);
   cvs_path := path:+'CVS';
   _str cvs_path_exists=isdirectory(_maybe_quote_filename(cvs_path));
   if ( cvs_path_exists ) {
      return(true);
   }
   return(false);
}

defeventtab _cvs_mfupdate_form;
/*static CVS_LOG_INFO TREE_FILE_INFO(...) [] {
   if (arg()) ctltree1.p_user=arg(1);
   return ctltree1.p_user;
} */
static _str IN_TREE_ON_CHANGE(...) {
   if (arg()) ctlclose.p_user=arg(1);
   return ctlclose.p_user;
}

/**
 * Get array of selected items
 * 
 * @param selArray Array of indexes
 */
static void GetSelectedItemsForDelete(int (&selArray)[])
{
   firstSelectedIndex := -1;
   int nofselected;
//   _TreeGetSelInfo(nofselected,firstSelectedIndex);
   int info;
   firstSelectedIndex = _TreeGetNextSelectedIndex(1,info);
   if ( firstSelectedIndex<0 ) {
      // If nothing is selected, use the current item
      selArray[0]=_TreeCurIndex();
   }else{
      for (ff:=1;;ff=0) {
         cur_index := _TreeGetNextSelectedIndex(ff,info);
         if ( cur_index<0 ) break;
         selArray[selArray._length()]=cur_index;
      }
   }
}

int _OnUpdate_cvs_delete_local_file_from_mfg(CMDUI &cmdui,int target_wid,_str command)
{
   if ( target_wid.p_name=="ctltree1") {
      // Everything selected must be an unkonwn file for delete to be allowed.
      // First build an array with the indexes of all the selected items
      int selArray[]=null;
      GetSelectedItemsForDelete(selArray);
      int i;
      selected_item_array_len := selArray._length();
      for (i=0;i<selected_item_array_len;++i) {
         state := bm1 := 0;
         _TreeGetInfo(selArray[i],state,bm1);
         if ( bm1!=_pic_cvs_file_qm) {
            return(MF_GRAYED);
         }
      }

      // Set the caption to "Delete local file" or "Delete local files" based on how many 
      // items are selected
      _str caption=selected_item_array_len==1?"Delete local file":"Delete local files";
      int mf_flags;
      _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,mf_flags);
      _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,mf_flags,'p',caption);
   }
   return(MF_ENABLED);
}

/**
 * Delete a file based on a tree index.  If the file deletes
 * succesfully, delete the tree index.
 * @param index index of filename to delete
 * 
 * @return int 0 if successful
 */
static int DeleteTreeFile(int index)
{
   _str filename=_CVSGetFilenameFromUpdateTree(index);
   if ( filename!="" ) {
       int status=delete_file(filename);
      if ( status ) {
         _message_box(nls("Could not delete '%s'\n\n%s",filename,get_message(status)));
         return(status);
      }
      _TreeDelete(index);
   }
   return(0);
}

/**
 * Call this to delete the current/selected files in the
 * cvs-gui-mfupdate output dialog
 * 
 * @return int 0 if successful
 */
_command int cvs_delete_local_file_from_mfg() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   // Do not want to run this from the command line, etc.
   if ( p_active_form.p_name!='_cvs_mfupdate_form' ) {
      return(1);
   }
   status := 0;
   int selArray[]=null;
   // Get all of the selected items
   GetSelectedItemsForDelete(selArray);
   if ( selArray==null ) {
      return(COMMAND_CANCELLED_RC);
   }

   // Loop through and prompt to delete each file. Loop allows for "Yes to all"
   // and "No to all"
   int i;
   selected_item_array_len := selArray._length();
   yesforall:=false;
   for (i=0;i<selected_item_array_len;++i) {
      _str filename=_CVSGetFilenameFromUpdateTree(selArray[i]);
      if ( yesforall ) {
         DeleteTreeFile(selArray[i]);
      }else{
         _str msg;
         _str answer;
         msg= nls("Permanently delete local file %s",filename);
         answer= show("-modal _yesToAll_form", msg, "Delete Local File");
         if (answer== "CANCEL") {
            break;
         } else if (answer== "YES") {
            DeleteTreeFile(selArray[i]);
         } else if (answer== "YESTOALL") {
            DeleteTreeFile(selArray[i]);
            yesforall=true;
         } else if (answer== "NOTOALL") {
            break;
         }
      }
   }
   return(status);
}

/**
 * Delete key is pressed in the tree control in the
 * cvs-gui-mfupdate output dialog.
 *
 * Calls the _OnUpdate for cvs_delete_local_file_from_mfg, so
 * the user cannot delete anything but unknown files
 */
void ctltree1.del()
{
   CMDUI cmdui;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   cmdui.inMenuBar=0;
   cmdui.button_wid=1;

   _OnUpdateInit(cmdui,p_window_id);

   cmdui.button_wid=0;

   int mfflags=_OnUpdate(cmdui,p_window_id,"cvs_delete_local_file_from_mfg");
   if (!mfflags || (mfflags&MF_ENABLED)) {
      cvs_delete_local_file_from_mfg();
   }else{
      _message_box(nls("Cannot delete selected files.  Only unknown files may be deleted"));
   }
}

static _str gMenuCaptions:[] = {
   "DIFF"=> "Diff %s0 with repository"
   ,"HISTORY"=> "History for %s0"
   ,"COMMIT"=>  "Commit %s0"
   ,"REVERT"=>  "Revert %s0 to the repository version"
};

void ctltree1.rbutton_up()
{
   int MenuIndex=find_index("_cvs_update_rclick_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   if ( menu_handle<0 ) {
      // Error loading menu
      return;
   }

   int Nofselected = _TreeGetNumSelectedItems();
   if ( !Nofselected ) {
      _TreeSelectLine(_TreeCurIndex());
   }

   _nocheck _control ctlclose;
   int firstwid=ctlclose.p_next;
   int wid;
   menu_index := 0;
   for (wid=firstwid;;) {
      if (wid.p_object!=OI_COMMAND_BUTTON) break;
      if ( wid.p_enabled && wid.p_visible ) {
         menucap := upcase(stranslate(wid.p_caption,"","..."));
         menucap=stranslate(menucap,"","&");
         if (!gMenuCaptions._indexin(menucap)) {
            menucap=wid.p_caption;
         }else{
            if (Nofselected>1) {
               menucap=stranslate(gMenuCaptions:[menucap],"selected files","%s0");
            }else{
               menucap=stranslate(gMenuCaptions:[menucap],_TreeGetCaption(_TreeCurIndex()),"%s0");
            }
         }
         if ( menucap!='v' ) {
            _menu_insert(menu_handle,menu_index++,MF_ENABLED,menucap,"cvs_push_command_button ":+wid,'',"");
         }
      }
      wid=wid.p_next;
   }
   _menu_insert(menu_handle,menu_index,MF_ENABLED,"-","",'',"");

   MaybeDisableCommand("commit_set_add",menu_handle);

   int x,y;
   mou_get_xy(x,y);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}
_command void cvs_push_command_button(_str wid='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( wid!="" && p_name!='ctltree1' && p_active_form.p_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   if ( _iswindow_valid((int)wid) ) {
      wid.call_event(wid,LBUTTON_UP);
   }
}

static int MaybeDisableCommand(_str command_name,int menu_handle)
{
   // Check to see if commit_set_add item should be enabled
   CMDUI cmdui;
   cmdui.menu_handle=0;
   cmdui.menu_pos=0;
   cmdui.inMenuBar=false;
   cmdui.button_wid=1;

   _OnUpdateInit(cmdui,p_window_id);
   cmdui.button_wid=0;
   int mfflags=_OnUpdate(cmdui,p_window_id,command_name);

   status := 0;
   if ( mfflags&MF_GRAYED ) {
      int output_handle,output_pos;
      status=_menu_find(menu_handle,"cvs-add-to-current-commit-set-from-mfg",output_handle,output_pos,'M');
      if ( !status ) {
         status=_menu_set_state(output_handle,output_pos,MF_GRAYED,'P');
      }
   }
   return(status);
}

void ctltree1.'c-h'()
{
   cvs_gui_update_hide();
}

/**
 * Find all indexes with given bitmap
 * 
 * @param indexes list of indexes that matche <B>searchBitmap</B> is returned 
 *                here.
 * @param searchBitmap Add any nodes whose bitmap index matches this to 
 *                     <B>indexes</B>
 */
static void getIndexesWithBitmap(int (&indexes)[],int searchBitmap)
{
   index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for ( ;index>0; ) {
      _TreeGetInfo(index,auto ShowChildren,auto BMIndex);
      if ( BMIndex==searchBitmap ) {
         indexes[indexes._length()] = index;
      }
      index = _TreeGetNextIndex(index);
   }
}

/**
 * Select nodes in array <B>indexes</B>
 * 
 * @param indexes list of indexes to select
 */
static void selectFiles(int (&indexes)[])
{
   curIndex := -1;
   foreach ( curIndex in indexes ) {
      _TreeSelectLine(curIndex);
   }
}

/**
 * Try to detect cases where one item is selected becuase we right clicked, and 
 * then deselect it 
 */
static void maybeDeselect()
{
   NofSelected := _TreeGetNumSelectedItems();
   index := _TreeCurIndex();
   _TreeGetInfo(index,auto ShowChildren,auto NonCurrentBMIndex,auto CurrentBMIndex,auto moreFlags);
   curNodeSelected := _TreeIsSelected(index);
   if ( NofSelected==1 && curNodeSelected ) {
      _TreeDeselectAll();
   }
}

static void selectOutOfDateFiles()
{
   maybeDeselect();
   getIndexesWithBitmap(auto indexes,_pic_file_old);
   selectFiles(indexes);
}

static void selectModifiedFiles()
{
   maybeDeselect();
   getIndexesWithBitmap(auto indexes,_pic_file_mod);
   selectFiles(indexes);
}

/** 
 * Can only be called from the context menu on _cvs_mfupdate_form
 * <P> 
 * Open all of the file selected in the _cvs_mfupdate_form in the editor
 */
_command void cvs_gui_update_open_selected() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_name!='ctltree1' && p_active_form.p_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   int indexes[];
   _TreeGetSelectionIndices(indexes);
   _str pathList[];
   foreach ( auto curIndex in indexes ) {
      pathList[pathList._length()] = updateGetPathFromTree(curIndex);
   }
   len := pathList._length();
   for ( i:=0;i<len;++i ) {
      if ( last_char(pathList[i])==FILESEP ) {
         pathList._deleteel(i);
         --i;
         --len;
      }
   }
   foreach ( auto curPath in pathList ) {
      if ( curPath!="" ) {
         _mdi.edit(_maybe_quote_filename(curPath));
      }
   }
}

/**
 * Can only be called from the context menu on _cvs_mfupdate_form
 *  
 * @param selectInfo tells what to select or deselect 
 * <UL> 
 *    <LI> <B>deselect-all</B> - Deselect all files
 *    <LI> <B>out-of-date</B> - Select files that are out of date
 *    <LI> <B>modified</B> - Select files that are modified
 * </UL>
 */
_command void cvs_gui_update_select(_str selectInfo="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_name!='ctltree1' && p_active_form.p_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   switch ( selectInfo ) {
   case "deselect-all":
      _TreeDeselectAll();
      break;
   case "out-of-date":
      selectOutOfDateFiles();
      break;
   case "modified":
      selectModifiedFiles();
      break;
   }
}
_command void cvs_gui_update_hide() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_name!='ctltree1' && p_active_form.p_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   int indices[];
   _TreeGetSelectionIndices(indices);
   currentIndex := _TreeCurIndex();
   nextIndex    := -1;
   int i;
   for (i = 0; i < indices._length(); ++i) {
      int index=indices[i];
      if ( index>-1 ) {
         int state,bm1,bm2,flags;
         if ( index==currentIndex ) {
            nextIndex = _TreeGetNextIndex(currentIndex);
         }
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_HIDDEN);
      }
   }
   if ( nextIndex>=0 ) {
      _TreeSetCurIndex(nextIndex);
   }
}
_command void cvs_gui_update_unhide_all(int index=TREE_ROOT_INDEX) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_name!='ctltree1' && p_active_form.p_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   for ( ;index>-1; ) {
      int state,bm1,bm2,flags;
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if ( flags&TREENODE_HIDDEN ) {
         _TreeSetInfo(index,state,bm1,bm2,flags&~TREENODE_HIDDEN);
      }
      cindex := _TreeGetFirstChildIndex(index);
      if ( cindex>0 ) {
         cvs_gui_update_unhide_all(cindex);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

void _cvs_mfupdate_form.on_resize()
{
   ctltree1.p_visible=ctlclose.p_visible=ctlhistory.p_visible=false;
   ResizeMFUpdate();
   ctltree1.p_visible=ctlclose.p_visible=ctlhistory.p_visible=true;
}

static void ResizeMFUpdate()
{
   int xbuffer=ctltree1.p_x;
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   ctltree1.p_width=/*ctltree2.p_width=*/client_width-(2*xbuffer);
   ctlrep_label.p_x=ctltree1.p_x+(ctltree1.p_width intdiv 2);

   ctltree1.p_height=client_height-(ctltree1.p_y+ctlclose.p_height+(xbuffer*5));

   ctlclose.p_y=ctltree1.p_y_extent+(xbuffer*2);

   SetUpdateDialogButtonYs();

   // Shrink the path for the Repository if necessary
   repositoryList := _GetDialogInfoHt("CaptionRepository");
   if ( repositoryList!=null ) {
      parse ctlrep_label.p_caption with auto label ':' auto rest;
      labelWidth := ctlrep_label._text_width(label);
      wholeLabelWidth := (client_width - ctlrep_label.p_x) - labelWidth;
      wholeCaption := label':'ctlrep_label._ShrinkFilename(strip(repositoryList),wholeLabelWidth);
      ctlrep_label.p_caption = wholeCaption;
   }
}

static void SetUpdateDialogButtonYs()
{
   ctlmerge.p_y=ctlupdate_all.p_y=ctlrevert.p_y=ctlhistory.p_y=ctldiff.p_y=ctlcvs_update.p_y=ctlclose.p_y;
}

static const WAS_RECURSIVE= 1;
static void CVSGUIUpdateDialog(CVS_LOG_INFO Files[],_str path,_str module_name,bool recursive)
{
   int formid=show('-xy -app -new _cvs_mfupdate_form');
   formid.p_active_form.p_caption='CVS 'formid.p_active_form.p_caption;
   formid._SetDialogInfo(WAS_RECURSIVE,recursive);
   formid.ctltree1.CVSSetupTree(Files,path,module_name);
   formid._set_foreground_window();
}

static void CVSSetupTree(CVS_LOG_INFO Files[],_str path,_str module_name)
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
   int PathIndexes1:[]=null;

   int newindex=_TreeAddItem(TREE_ROOT_INDEX,path,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
   // Seed the tree and table with the root index.  Since this is a local
   // directory, we know this exists
   _CVSSeedPathIndexes(path,PathIndexes1,newindex);

   int QMIndexes[]=null;
   int i;
   for ( i=0;i<Files._length();++i ) {
      int parent_bitmap_index=_pic_fldopen;
      _str end_char=_last_char(Files[i].WorkingFile);
      typeless isdir=isdirectory(Files[i].WorkingFile);
      if ( _last_char(Files[i].WorkingFile)==FILESEP &&
           Files[i].Description=='-' ) {
         parent_bitmap_index=_pic_cvs_fld_m;
      }
      int index1=_CVSGetPathIndex(_file_path(Files[i].WorkingFile),path,PathIndexes1,_pic_fldopen,_pic_cvs_fld_m);

      if ( isdir && Files[i].Description=='?' ) {
         // Save this for later
         QMIndexes[QMIndexes._length()]=index1;
      }else if (Files[i].Description=='?' ) {
      }
      if ( parent_bitmap_index==_pic_cvs_fld_m ) {
         // This can't really be open, won't detect subfolders under it
         _TreeSetInfo(index1,-1);
      }
      int bitmap1;
      _CVSGetFileBitmap(Files[i],bitmap1);
      if ( end_char!=FILESEP && !isdir ) {
         int newindex1=_TreeAddItem(index1,_strip_filename(Files[i].WorkingFile,'P'),TREE_ADD_AS_CHILD,bitmap1,bitmap1,-1);
         //_TreeSetUserInfo(newindex1,i);
      }
   }
   for ( i=0;i<QMIndexes._length();++i ) {
      _TreeSetInfo(QMIndexes[i],0,_pic_cvs_fld_qm,_pic_cvs_fld_qm);
   }
   ctltree1._TreeSortTree();
   ctllocal_path_label._CVSSetPathLabel(path);
   //ctllocal_path_label.p_caption=ctllocal_path_label.p_caption:+path;
   ctlrep_label._CVSSetPathLabel(module_name);
   //ctlrep_label.p_caption=ctlrep_label.p_caption:+module_name;
   //TREE_FILE_INFO(Files);
   ctltree1._EnableGUIUpdateButtons("cvs");
}

void _CVSSetPathLabel(_str caption)
{
   label := "";
   parse p_caption with label ':' .;
   p_caption=label':'stranslate(caption,'',' ');
   key := "Caption"label;
   _SetDialogInfoHt(key,caption);
}

_str _CVSGetPathLabel()
{
   _str label,caption='';
   parse p_caption with label ':' caption;
   return(caption);
}

void _CVSGetFileBitmap(CVS_LOG_INFO &File,int &bitmap1,int default_bitmap=_pic_cvs_file,
                      bool DoubleCheckConflict=true)
{
   bitmap1=default_bitmap;
   if ( File.Description=='E' ) {
      if ( isdirectory(File.WorkingFile) ) {
         bitmap1=_pic_cvs_fld_error;
      } else {
         bitmap1=_pic_cvs_file_error;
      }
      return;
   }
   if ( File.Description=='?' ) {
      if ( isdirectory(File.WorkingFile) ) {
         bitmap1=_pic_cvs_fld_qm;
      } else {
         bitmap1=_pic_cvs_file_qm;
      }
      return;
   }
   if ( File.Description=='-' ) {
      bitmap1=_pic_cvs_filem;
      /*if (last_char(File.Description)=='/') {
         bitmap1=_pic_cvs_fld_m;
      }else{
         bitmap1=_pic_cvs_filem;
      }*/
      return;
   }
   if ( File.Description=='O' ) {
      if (_last_char(File.Description)=='/') {
         bitmap1=_pic_cvs_fld_m;
      }else{
         bitmap1=_pic_cvs_file_obsolete;
      }
      return;
   }
   if ( File.Description=='N' ) {
      if (_last_char(File.Description)=='/') {
         bitmap1=_pic_cvs_fld_p;
      }else{
         bitmap1=_pic_cvs_file_new;
      }
      return;
   }
   if ( File.LocalVersion != File.Head ) {
      if ( File.Description=='M' ) {
         bitmap1=_pic_file_old_mod;
      } else if ( File.Description=='C' ) {
         if ( DoubleCheckConflict ) {
            bitmap1=ReturnConflictBitmap(File);
         } else {
            bitmap1=_pic_cvs_file_conflict;
         }
      } else {
         if ( File.Description=='A' ) {
            bitmap1=_pic_cvs_filep;
         }else{
            bitmap1=_pic_file_old;
         }
      }
      return;
   }
   if ( File.Description=='A' ) {
      bitmap1=_pic_cvs_filep;
      return;
   }
   if ( File.Description=='M' ) {
      bitmap1=_pic_file_mod;
      return;
   }

   if ( File.Description=='C' ) {
      if ( DoubleCheckConflict ) {
         bitmap1=ReturnConflictBitmap(File);
      } else {
         bitmap1=_pic_cvs_file_conflict;
      }
      return;
   }

   // This is the case where the file is missing from CVS\Entries
   if ( File.Description=='U' ||
        File.Description=='P'
        ) {
      bitmap1=_pic_file_old;
   }
}

static int ReturnConflictBitmap(CVS_LOG_INFO &File)
{
   version := file_timestamp := conflict_mod_time := "";
   CVSGetEntriesFileInfo(File.WorkingFile,version,file_timestamp);

   parse file_timestamp with . '+' conflict_mod_time;
   _str current_timestamp=GetLocalFileTime(File.WorkingFile);
   if (conflict_mod_time=='') {
      return(_pic_cvs_file_conflict);
   }

   if ( current_timestamp != conflict_mod_time ) {
      return(_pic_cvs_file_conflict_updated);
   } else {
      return(_pic_cvs_file_conflict);
   }
}

void ctltree1.on_change(int reason,int index)
{
   if ( IN_TREE_ON_CHANGE()==1 ) {
      return;
   }
   IN_TREE_ON_CHANGE(1);
   if ( index<0 ) {
      IN_TREE_ON_CHANGE(0);
      return;
   }
   path := _TreeGetCaption(index);
   if ( index>-1 ) {
      int state,bmindex1;
      _TreeGetInfo(index,state,bmindex1);
      Nofselected := _TreeGetNumSelectedItems();

      if (Nofselected>1) {
         ctlhistory.p_enabled=false;
      }
      systemName := "";
      if ( IsCVSUpdateDialog() ) {
         systemName = "cvs";
      }else if ( IsSVNUpdateDialog() ) {
         systemName = "svn";
      }else if ( IsHgUpdateDialog() ) {
         systemName = "hg";
      }
      _EnableGUIUpdateButtons(systemName);
   }
   IN_TREE_ON_CHANGE(0);
}

bool IsCVSUpdateDialog()
{
   return p_active_form.p_caption=="CVS Update Directory";
}

bool IsSVNUpdateDialog()
{
   return p_active_form.p_caption=="Subversion Update Directory";
}

bool IsHgUpdateDialog()
{
   return p_active_form.p_caption=="Mercurial Repository Status";
}

static void FillInDescription(CVS_LOG_INFO FileInfo)
{
   _str lines[]=null;
   if ( FileInfo.Description=='?' ) {
      lines[lines._length()]=FileInfo.WorkingFile' does not exist in repository';
   } else if ( FileInfo.Description=='E' ) {

      file_or_dirname := substr(FileInfo.WorkingFile,length(ctllocal_path_label._CVSGetPathLabel())+1);
      file_or_dirname=stranslate(file_or_dirname,'/',FILESEP);

      lines[lines._length()]='There is a problem with 'FileInfo.WorkingFile'.<BR>The most likely cause is that there is a file/directory in the repository named 'file_or_dirname', but it cannot be written locally because another non-cvs file/directory exists with the same name';
   } else if ( FileInfo.Description=='A' ) {
      lines[lines._length()]='This file has been added to the repository, but has not yet been committed.';
   } else if ( FileInfo.LocalVersion._varformat()==VF_LSTR ) {
      lines[lines._length()]='<B>Working File:</B>'FileInfo.WorkingFile'<BR><B>Archive File:</B>'FileInfo.RCSFile;
      lines[lines._length()]='<B>Repository Version:</B>'FileInfo.Head'<BR><B>Local Version:</B>'FileInfo.LocalVersion;
      switch ( FileInfo.Description ) {
      case 'C':
         lines[lines._length()]='<FONT color=red>cvs will not be able to resolve conflicts if it merges this file.  Use <B>GUI Update</B></FONT>';
         break;
      }
   } else {
      switch ( FileInfo.Description ) {
      case 'C':
         lines[lines._length()]='<FONT color=red>cvs will not be able to resolve conflicts if it merges this file.  Use <B>GUI Update</B></FONT>';
         break;
      case '-':
         lines[lines._length()]='<FONT color=red>This file does not exist locally.</FONT>';
      }
   }
   if ( _CVSDebug&CVS_DEBUG_SHOW_MESSAGES ) {
      lines[lines._length()]='<B>Code:</B>'FileInfo.Description;
   }
}

static bool ValidBitmapCombination(int CurrentBMIndex,int LastSelectedBMIndex)
{
   // If the bitmaps match, or we just selected a folder
   if (CurrentBMIndex==LastSelectedBMIndex ||
       LastSelectedBMIndex==-1 ||
       CurrentBMIndex==_pic_fldopen) {
      return(true);
   }

   // both bitmaps are uncommitted changes?
   bool CurrentNeedsCommit = (
              CurrentBMIndex==_pic_cvs_filep        ||
              CurrentBMIndex==_pic_cvs_filem        ||
              CurrentBMIndex==_pic_file_mod_prop    ||  
              CurrentBMIndex==_pic_file_mod  
           );
   bool LastSelectedNeedsCommit = (
              LastSelectedBMIndex==_pic_cvs_filep     ||
              LastSelectedBMIndex==_pic_cvs_filem     ||
              LastSelectedBMIndex==_pic_file_mod_prop ||
              LastSelectedBMIndex==_pic_file_mod  
           );
   if (CurrentNeedsCommit && LastSelectedNeedsCommit) {
      return true;
   }

   // both bitmaps need update
   bool CurrentNeedsUpdate = (
              CurrentBMIndex==_pic_file_old          ||
              CurrentBMIndex==_pic_file_old_mod      ||
              CurrentBMIndex==_pic_cvs_file_obsolete ||
              CurrentBMIndex==_pic_cvs_file_new      ||
              CurrentBMIndex==_pic_cvs_fld_m         ||
              CurrentBMIndex==_pic_cvs_fld_p
           );
   bool LastSelectedNeedsUpdate = (
              LastSelectedBMIndex==_pic_file_old          ||
              LastSelectedBMIndex==_pic_file_old_mod      ||
              LastSelectedBMIndex==_pic_cvs_file_obsolete ||
              LastSelectedBMIndex==_pic_cvs_file_new      ||
              LastSelectedBMIndex==_pic_cvs_fld_m         ||
              LastSelectedBMIndex==_pic_cvs_fld_p
           );
   return (CurrentNeedsUpdate && LastSelectedNeedsUpdate);
}

static void GetValidBitmaps(int BitmapIndex,_str &ValidBitmaps,_str systemName)
{
   if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_UPDATE' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_UPDATE;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_COMMITABLE' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_COMMITABLE;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_ADD' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_ADD;
   }else if ( pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_CONFLICT' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_CONFLICT;
   }else if ( systemName=="hg" && pos(' 'BitmapIndex' ',' 'SVC_BITMAP_LIST_FOLDER' ') ) {
      ValidBitmaps=SVC_BITMAP_LIST_FOLDER;
   }
}

static void enableRevertButton(bool checkForUpdateDashC)
{
   if ( checkForUpdateDashC ) {
      ctlrevert.p_visible=_CVSUpdateDashCAvailable();
   }else{
      ctlrevert.p_visible=true;
   }
}

/**
 * 
 * @param systemName must be "cvs" or "svn"
 */
void _EnableGUIUpdateButtons(_str systemName)
{
   isCVS := systemName=="cvs";
   isSVN := systemName=="svn";
   isHg  := systemName=="hg";
   checkForUpdateDashC := isCVS;
   wid := p_window_id;
   p_window_id=ctltree1;
   curindex := _TreeCurIndex();
   int state,bmindex1,bmindex2;
   _TreeGetInfo(curindex,state,bmindex1,bmindex2);
   bmindex := -1;
   last_selected := -1;
   valid_bitmaps := "";
   invalid := false;
   bm1 := 0;
   addedFile := false;
   deletedFile := false;
   oldModFile := false;
   no_real_selection := false;
   selinfo := -1;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextSelectedIndex(ff,selinfo);
      if ( index<1 ) {
         if (ff) {
            // If this is the first time through and we got nothing selected,
            // use the current index and break out of the loop this time through
            no_real_selection=true;
            index=_TreeCurIndex();
         }else break;
      }
      _TreeGetInfo(index,state,bm1);
      if ( bm1==_pic_cvs_filep ) {
         // We had an added file bitmap
         addedFile=true;
      }
      if ( bm1==_pic_cvs_filem || bm1==_pic_file_del || bm1==_pic_cvs_filem_mod ) {
         // We had a deleted file bitmap
         deletedFile=true;
      }
      if ( bm1==_pic_file_old_mod ) {
         // We had an modified file that is also out of date
         oldModFile=true;
      }
      if (valid_bitmaps=='') {
         GetValidBitmaps(bm1,valid_bitmaps,systemName);
      }
      if (!pos(' 'bm1' ',' 'valid_bitmaps' '_pic_fldopen' ')) {
         valid_bitmaps='';
      }
      if ( no_real_selection ) break;
   }
   p_window_id=ctlcvs_update;

   if (valid_bitmaps=='') {
      ctlhistory.p_enabled=false;
      ctldiff.p_enabled=false;
      ctlcvs_update.p_enabled=false;
      ctlrevert.p_visible=false;
      ctlmerge.p_visible=false;
   }else if ( valid_bitmaps==SVC_BITMAP_LIST_ADD ) {
      p_caption=SVC_UPDATE_CAPTION_ADD;
      p_enabled=true;
      ctldiff.p_enabled=false;
      ctlmerge.p_visible=false;
      ctlrevert.p_visible=false;
   }else if ( valid_bitmaps==SVC_BITMAP_LIST_CONFLICT ) {
      ctldiff.p_enabled=true;
      p_enabled=true;
      if ( isSVN ) {
         p_caption=SVC_UPDATE_CAPTION_MERGE;
         enableRevertButton(checkForUpdateDashC);

         // the update Button is already the Merge button, so the Merge button 
         // becomes the resolve button
         ctlmerge.p_caption = "Resolve";
         ctlmerge.p_visible=true;
      }else if ( isCVS ) {
         p_caption=SVC_UPDATE_CAPTION_UPDATE;
         ctlrevert.p_visible=_CVSUpdateDashCAvailable();
         if (def_cvs_flags&CVS_SHOW_MERGE_BUTTON) {
            ctlmerge.p_visible=true;
         }
      }
   }else if ( valid_bitmaps==SVC_BITMAP_LIST_COMMITABLE ) {
      p_caption=SVC_UPDATE_CAPTION_COMMIT;
      p_enabled=true;
      ctldiff.p_enabled=true;
      if ( addedFile ) {
         ctlrevert.p_visible=false;
      }else if (deletedFile) {
         ctlrevert.p_visible = false;
         ctldiff.p_enabled   = false;
      }else{
         enableRevertButton(checkForUpdateDashC);
      }
      ctlmerge.p_visible=false;
   }else if ( valid_bitmaps==SVC_BITMAP_LIST_UPDATE ) {
      p_caption=SVC_UPDATE_CAPTION_UPDATE;
      p_enabled=true;
      ctldiff.p_enabled=true;
      ctlrevert.p_visible=false;
      ctlmerge.p_visible=false;
      if ( oldModFile ) {
         enableRevertButton(checkForUpdateDashC);
      }
      if (deletedFile) {
         ctlrevert.p_visible = false;
         ctldiff.p_enabled   = false;
      }
   }else if ( valid_bitmaps==SVC_BITMAP_LIST_FOLDER && isHg ) {
      p_caption=SVC_UPDATE_CAPTION_COMMIT;
      p_enabled=true;
      ctldiff.p_enabled=false;
      ctlrevert.p_visible=true;
      ctlupdate_all.p_enabled=true;
   }
   int button_width=max(p_width,_text_width(p_caption)+400);
   if ( button_width>p_width ) {
      orig_button_width := p_width;
      p_width=button_width;
      int width_difference=(button_width-orig_button_width);
      ctlupdate_all.p_x+=width_difference;
      ctlrevert.p_x+=width_difference;
   }
   bool file_bitmap=(bm1==_pic_file_old||
                     bm1==_pic_file_old_mod ||
                     bm1==_pic_file_mod||
                     bm1==_pic_file_mod_prop||
                     bm1==_pic_cvs_file_conflict||
                     bm1==_pic_cvs_file_conflict_updated);

   int numselected = ctltree1._TreeGetNumSelectedItems();
   ctlhistory.p_enabled=(numselected<=1) && file_bitmap;

   p_window_id=wid;
}

/**
 * The "Revert" button on the CVS GUI Update dialog uses the 
 * "cvs update -C" command.  This is not available on all platforms.
 * @return true if "cvs update -C" is supported.
 */
bool _CVSUpdateDashCAvailable()
{
   return(CVSCommandOptionIsSupported("update","-C"));
}

/**
 * Returns true if an option is supported for a given command.  Uses 
 * def_vc_system to call a callback that will get the info if necessary.
 */
static bool CVSCommandOptionIsSupported(_str command,_str option)
{
   // check if we've tested the command before
   if ( !_cvs_other_info.CommandOptionTable._indexin(command) ) {
      _str func_name='_'lowcase(stranslate(def_vc_system,'_',' '))'_GetOptionInfo';
      index := find_index(func_name,PROC_TYPE);
      if ( index && index_callable(index) ) {
         call_index(command,index);
      }
   }

   // still not there?
   if ( !_cvs_other_info.CommandOptionTable._indexin(command) ) {
      return false;
   }

   // We've tried to load this item into the table, but can't get the information
   typeless optioninfo=_cvs_other_info.CommandOptionTable:[command];
   if ( optioninfo._varformat()!=VF_HASHTAB ) {
      return(false);
   }

   // check if the option is available
   return optioninfo._indexin(option)? true:false;
}

int _cvs_GetOptionInfo(_str command)
{
   _str error_filename=mktemp();
   _str config_path=_ConfigPath();

   _CVSShell(_CVSGetExeAndOptions()' --help 'command' 2>'_maybe_quote_filename(error_filename),config_path,def_cvs_shell_options);
   if ( !file_exists(error_filename) ) {
      // Can't trust the return code here, because it returns 1 on success, so
      // just check to see if the output exists.  If it does not, we assume
      // that the option is supported.
      return(FILE_NOT_FOUND_RC);
   }
   int status;
   int temp_view_id,orig_view_id;
   status=_open_temp_view(error_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   p_window_id=temp_view_id;
   top();up();
   for (;;) {
      // Allow any number of tabs or spaces before an option
      status=search('^(\t| )@\-?@(\t| )','@r>');
      if ( status ) break;
      line := "";
      get_line(line);
      cur_option := info := "";
      parse line with cur_option info;
      _cvs_other_info.CommandOptionTable:[command]:[cur_option]=info;
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   delete_file(error_filename);
   return(0);
}

/**
 * Sets focus to <B>formid</B> if it is a valid window id.
 * I had to do this because sometimes if the output toolbar
 * came up, even though I set focus after the toolbar came
 * up, the dialog lost focus.
 *
 * @param formid    Window id of form to set as foreground window.
 *                  This has to be a form.
 */
static void MySetForeground(int formid)
{
   if ( _iswindow_valid(formid) ) {
      formid._set_foreground_window();
   }
}

int ctlcvs_update.lbutton_up()
{
   orig_form := p_active_form;
   status := 0;
   _str system_name=GetVCSystemNameFromHistoryDialog();

   if ( p_caption==SVC_UPDATE_CAPTION_ADD ) {
      index := _SVCGetProcIndex('update_add_button',system_name);
      if ( index>0 ) {
         status=call_index(index);
      }
   } else if ( p_caption==SVC_UPDATE_CAPTION_UPDATE ) {
      index := _SVCGetProcIndex('update_update_button',system_name);
      if ( index>0 ) {
         status=call_index(index);
      }
   } else if ( p_caption==SVC_UPDATE_CAPTION_COMMIT ) {
      index := _SVCGetProcIndex('update_commit_button',system_name);
      if ( index>0 ) {
         status=call_index(index);
      }
   } else if ( p_caption==SVC_UPDATE_CAPTION_MERGE ) {
      index := _SVCGetProcIndex('update_merge_button',system_name);
      if ( index>0 ) {
         status=call_index(index);
      }
   }
   _post_call(MySetForeground,orig_form);
   orig_form._EnableGUIUpdateButtons("cvs");
   orig_form.ctltree1._set_focus();
   return(status);
}

void ctlmerge.lbutton_up()
{
   MergeSelectedFiles();
}
typedef void (*pfnTraverseCallback_tp)(int NodeIndex);

static void TraverseTree(int RootIndex,pfnTraverseCallback_tp pfnCallback)
{
   int index=RootIndex;
   for ( ;; ) {
      if ( index<0 ) break;
      (*pfnCallback)(index);
      cindex := _TreeGetFirstChildIndex(index);
      if ( cindex>-1 ) {
         TraverseTree(cindex,pfnCallback);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void SelectNodeIfNeedsUpdate(int index)
{
   int state,bm1,bm2,flags;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   if ( bm1==_pic_file_old
        ||bm1==_pic_cvs_fld_m
        ||bm1==_pic_cvs_fld_p
        ||bm1==_pic_cvs_file_new
        ||bm1==_pic_cvs_file_obsolete
        ||bm1==_pic_file_old_mod
      ) {
      _TreeSelectLine(index);
   }
}

/**
 * Same as SelectNodeIfNeedsUpdate but will not do modified files ("NM" stands for
 * not modified).
 *
 * @param index
 */
static void SelectNodeIfNeedsUpdateNM(int index)
{
   int state,bm1,bm2,flags;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   if ( bm1==_pic_file_old
        ||bm1==_pic_cvs_fld_m
        ||bm1==_pic_cvs_fld_p
        ||bm1==_pic_cvs_file_new
        ||bm1==_pic_cvs_file_obsolete
         ) {
      _TreeSelectLine(index);
   }
}

void ctlupdate_all.lbutton_up()
{
   if ( IsHgUpdateDialog() ) {

      wid := p_window_id;
      p_window_id=ctltree1;
      curIndex := _TreeCurIndex();
      path := _TreeGetCaption(curIndex);
      _HgUpdateAllButton(path);
      p_window_id=wid;

      return;
   }
   _str Captions[];
   Captions[0]='Update only new files and files that are not modified';
   Captions[1]='Update all files that are not in conflict';
   int result=RadioButtons("Update all files",Captions,1,'cvs_update_all');
   pfnTraverseCallback_tp pfnCallback=null;
   if ( result==COMMAND_CANCELLED_RC ) {
      return;
   } else if ( result==1 ) {
      pfnCallback=SelectNodeIfNeedsUpdateNM;
   } else if ( result==2 ) {
      pfnCallback=SelectNodeIfNeedsUpdate;
   }
   wid := p_window_id;
   p_window_id=ctltree1;
   _TreeDeselectAll();
   TraverseTree(TREE_ROOT_INDEX,pfnCallback);
   int nofselected = _TreeGetNumSelectedItems();
   if ( nofselected ) {
      _SetDialogInfoHt("userClickedUpdateAll",true);
      _EnableGUIUpdateButtons("cvs");
      ctlcvs_update.call_event(ctlcvs_update,LBUTTON_UP);
   } else {
      _message_box(nls("No files need to be updated"));
   }
   p_window_id=wid;
}

void ctlrevert.lbutton_up()
{
   RevertSelectedFiles();
   _post_call(MySetForeground,p_active_form);
   _EnableGUIUpdateButtons("cvs");
}

static int RevertSelectedFiles()
{
   status := 0;
   if ( IsCVSUpdateDialog() ) {
      status = _cvs_update_update_button('-C');
   }else if ( IsSVNUpdateDialog() ) {
      status = _svn_update_revert_button();
   }else if ( IsHgUpdateDialog() ) {
      status = _hg_update_revert_button();
   }
   return status;
}

int _cvs_update_update_button(_str UpdateOptions='')
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);
   if (filelist==null || filelist._length()==0) {
      return 0;
   }

   // Check to see if there are conflicts in these files
   conflict := false;
   int i;
   for ( i=0;i<indexlist._length();++i ) {
      int state,bm1;
      ctltree1._TreeGetInfo(indexlist[i],state,bm1);
      if ( bm1==_pic_cvs_file_conflict ) {
         conflict=true;
         break;
      }
   }

   if ( conflict && !pos(' -C ',' 'UpdateOptions' ') ) {
      int result=_message_box(nls("This update will cause conflicts that will need to be resolved before a commit.\n\nContinue?"),'',MB_YESNO);
      if ( result==IDNO ) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   OutputFilename := "";
   CVS_LOG_INFO Files[]=null;

   updated_new_dir := false;
   int status=_CVSUpdate(filelist,OutputFilename,false,&Files,updated_new_dir,UpdateOptions,p_active_form);

   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   if (file_exists(OutputFilename)) {
      delete_file(OutputFilename);
   }

   if ( status ) {
      return(status);
   }

   if ( !updated_new_dir ) {
      CVSRefreshTreeBitmaps(indexlist,filelist,Files);
   } else {
      _str local_path;
      parse ctllocal_path_label.p_caption with 'Local Path:','i' local_path;

      Files._makeempty();
      module_name := "";
      typeless recursive=_GetDialogInfo(WAS_RECURSIVE);
      _CVSGetVerboseFileInfo(local_path,Files,module_name,recursive);
      ctltree1.CVSSetupTree(Files,local_path,module_name);
   }

   if ( conflict && !pos(' -C ',' 'UpdateOptions' ') ) {
      len := filelist._length();
      for (i=0;i<len;++i) {
         _mdi.edit(_maybe_quote_filename(filelist[i]));
         _mdi.p_child.search('^<<<<<<< ','@r');
      }
   }

   return(status);
}

static int CVSTouch(_str filename)
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if (status) {
      status=_open_temp_view(filename,temp_view_id,orig_view_id,'+t');
      if (status) {
         return(status);
      }
   }
   status=_save_file('+o');
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

static int MergeSelectedFiles()
{
   // We're using the old Merge button as a Resolve button
   if ( IsSVNUpdateDialog() && p_caption=="Resolve" ) {
      _str system_name=GetVCSystemNameFromHistoryDialog();
      index := _SVCGetProcIndex('update_resolve_button',system_name);
      status := 0;
      if ( index>0 ) {
         status=call_index(index);
      }
      return(status);
   }
   orig_wid := p_window_id;
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   int i,len=filelist._length();
   status := 0;
   _str error_output_filename=mktemp();
   CVSTouch(error_output_filename);
   _str base_temp_directory=mktemp(),rev1_temp_directory='';
   for ( i=0;i<len;++i ) {
      _str remote_version;
      status=CVSGetRemoteVersionForFile(filelist[i],remote_version);
      if ( status ) {
         _message_box(nls("Could not get remote local_version for file '%s'",filelist[i]));
         break;
      }

      _str local_version;
      status=CVSGetEntriesFileInfo(filelist[i],local_version);
      if ( status ) {
         _message_box(nls("Could not get local local_version for file '%s'",filelist[i]));
         break;
      }
      module_name := "";
      status=_CVSGetModuleFromLocalFile(filelist[i],module_name);
      if ( status ) {
         _message_box(nls("Could not get module name for file '%s'",filelist[i]));
         break;
      }
      just_filename := _strip_filename(filelist[i],'P');
      cvs_filename := module_name:+just_filename;
      message(nls("Checking out local_version %s of '%s'",local_version,cvs_filename));

      status=_CVSCheckout(cvs_filename,base_temp_directory,'-r 'local_version,error_output_filename);
      if ( status ) {
         _message_box(nls("Could not checkout local version %s of file '%s'",local_version,filelist[i]));
         _SVCDisplayErrorOutputFromFile(error_output_filename);
         break;
      }
      _maybe_append_filesep(base_temp_directory);

      message(nls("Checking out current local_version of '%s'",cvs_filename));
      rev1_temp_directory=mktemp();
      status=_CVSCheckout(cvs_filename,rev1_temp_directory,'',error_output_filename);
      if ( status ) {
         _message_box(nls("Could not checkout local version %s of file '%s'",local_version,filelist[i]));
         break;
      }
      _maybe_append_filesep(rev1_temp_directory);

      _str match_name=buf_match(filelist[i],1,'E');
      output_is_being_edited := _file_eq(match_name,filelist[i]);
      _str orig_date=_file_date(filelist[i],'B');
      orig_view_id := p_window_id;
      saved_merge_file := false;

      _str backup_filename=CVSMergeGetBackupFilename(filelist[i],local_version);
      status=copy_file(filelist[i],backup_filename);
      if (status) {
         _message_box(nls("Could not backup file '%s'\n\n%s",filelist[i],get_message(status)));
         break;
      }
      _LoadEntireBuffer(filelist[i]);
      status=merge('-smart -showchanges -basefilecaption "'just_filename' (Version 'local_version' - Remote)" -rev2filecaption "'just_filename' (Version 'remote_version' - Remote)" -rev1filecaption "'filelist[i]' (Version 'local_version' - Local)" '_maybe_quote_filename(base_temp_directory:+just_filename)' '_maybe_quote_filename(filelist[i])' '_maybe_quote_filename(rev1_temp_directory:+just_filename)' '_maybe_quote_filename(filelist[i]));
      if ( !MergeNumConflicts() ) {
         int result=_message_box(nls("SlickEdit did not find any conflict in these files.  Save this version of the file?"),'',MB_YESNO);
         if ( result==IDYES ) {
            int junk1_view_id,junk2_view_id;
            status=_open_temp_view(filelist[i],junk1_view_id,junk2_view_id,'+b');
            if (!status) {
               saved_merge_file=true;
               status=_save_file();
               if ( status ) {
                  _delete_temp_view();
                  _message_box(nls("Could not save file '%s'\n\n%s",filelist[i],get_message(status)));
                  break;
               }
            }
            _delete_temp_view();
            p_window_id=orig_view_id;
            saved_merge_file=true;
         }
      } else {
         saved_merge_file=orig_date!=_file_date(filelist[i],'B');
      }

      if ( saved_merge_file ) {
         _message_box(nls("The original version of '%s' was backed up to '%s'",filelist[i],backup_filename));
      }else{
         delete_file(backup_filename);
      }

      if ( saved_merge_file ) {
         // Change the bitmap to reflect that we can do something with this...
         CVS_LOG_INFO Files[]=null;
         status=_CVSGetVerboseFileInfo(filelist[i],Files,module_name);
         bmindex := -1;
         _CVSGetFileBitmap(Files[i],bmindex,_pic_cvs_file/*,true*/);
         int state,bm1,bm2;
         ctltree1._TreeGetInfo(indexlist[i],state,bm1,bm2);
         ctltree1._TreeSetInfo(indexlist[i],state,bmindex,bmindex);
         _EnableGUIUpdateButtons("cvs");
      }
      _DelTree(base_temp_directory,true);
      _DelTree(rev1_temp_directory,true);
      _SVCDisplayErrorOutputFromFile(error_output_filename,status);
      delete_file(error_output_filename);
   }
   if ( status ) {
      _DelTree(base_temp_directory,true);
      _DelTree(rev1_temp_directory,true);
      _SVCDisplayErrorOutputFromFile(error_output_filename,status);

   }
   delete_file(error_output_filename);
   p_window_id=orig_wid;
   return(status);
}

static _str CVSMergeGetBackupFilename(_str filename,_str local_version)
{
   _str path=_file_path(filename);
   name := _strip_filename(filename,'P');
   return(path:+'.##'name'.'local_version);
}

int _cvs_update_add_button()
{
   _str filelist[]=null;
   int indexlist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist,_pic_cvs_fld_qm);

   _str dirs[]=null;
   _str filenames[]=null;
   int i;
   for ( i=0;i<filelist._length();++i ) {
      _str cur=filelist[i];
      if ( _last_char(cur)==FILESEP ) {
         dirs[dirs._length()]=cur;
      } else {
         filenames[filenames._length()]=cur;
      }
   }

   CVS_LOG_INFO Files[]=null;
   status := 0;

   _param1='';
   _str result = show('-modal _textbox_form',
                      'Options for CVS Add ', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'cvs add', //Retrieve Name
                      'Add options:'
                     );

   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str add_options=_param1;

   if ( dirs._length() ) {
      status=CVSAddSelectedFiles(dirs,indexlist,&Files,add_options);
      if ( status ) return(status);
   }

   if ( filenames._length() ) {
      status=CVSAddSelectedFiles(filenames,indexlist,&Files,add_options);
      if ( status ) return(status);
   }

   if ( !dirs._length() ) {
      CVSRefreshTreeBitmaps(indexlist,filenames,Files);
   } else {
      _str local_path;
      parse ctllocal_path_label.p_caption with 'Local Path:','i' local_path;

      Files._makeempty();
      module_name := "";
      typeless recursive=_GetDialogInfo(WAS_RECURSIVE);
      _CVSGetVerboseFileInfo(local_path,Files,module_name,recursive);

      wid := p_window_id;
      p_window_id=ctltree1;
      CVSSetupTree(Files,local_path,module_name);

      // We just deleted and re-filled the tree.  We want to check and see if
      // there is anything that we just added that we can select.
      selected := false;
      for ( i=0;i<filenames._length();++i ) {
         int index=_TreeSearch(TREE_ROOT_INDEX,_strip_filename(filenames[i],'N'),'T'_fpos_case);
         if ( index>-1 ) {
            index=_TreeSearch(index,_strip_filename(filenames[i],'P'),_fpos_case);
            if ( index>-1 ) {
               int state,bm1,bm2,flags;
               _TreeSelectLine(index);
               if (!selected) {
                  _TreeSetCurIndex(index);
               }
               selected=true;
            }
         }
      }
      p_window_id=wid;
   }
   return(status);
}
static int CVSAddSelectedFiles(_str (&filelist)[], int (&indexlist)[],
                               CVS_LOG_INFO (*pFiles)[]=null,
                             _str add_options='')
{
   OutputFilename := "";

   updated_new_dir := false;
   int status=_CVSAdd(filelist,OutputFilename,false,pFiles,updated_new_dir,add_options);

   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   delete_file(OutputFilename);

   return(status);
}

int _cvs_update_commit_button()
{
   wid := p_window_id;
   CVS_LOG_INFO Files[]=null;

   _str filelist[]=null;
   int indexlist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);
   status := 0;
   // Have to keep a copy of this because items can get deleted during the loop
   // and we need all of the filenames to be able to update the tree.
   _str whole_filelist[]=filelist;
   OutputFilename := "";
   if ( filelist!=null ) {
      status=_SVCListModified(filelist);
      if ( status ) {
         return(status);
      }
      reuse_comment := false;
      append_to_output := false;

      len := filelist._length();
      _str temp_filename=mktemp();
      apply_to_all := false;
      tag := "";
      int i;
      for ( i=0;i<len;++i ) {
         if ( !reuse_comment ) {
            status=_CVSGetComment(temp_filename,tag,filelist[i],len>1,apply_to_all);
            if ( status ) {
               return(status);
            }
         }
         if ( apply_to_all ) {
            status=_SVCCheckLocalFilesForConflicts(filelist);
            if ( status==IDCANCEL ) {
               return(COMMAND_CANCELLED_RC);
            } else if ( status ) {
               return(1);
            }
            _CVSCommit(filelist,temp_filename,OutputFilename,true,'',append_to_output,&Files,tag);
            break;
         } else {
            _str cur=filelist[i];

            // because we are using a different array(tempfiles), delete this item
            // from filelist so if the user uses "Apply to all" later, it is not
            // there.  This means that we also have to decrement i and len
            filelist._deleteel(i);
            --i;--len;
            _str tempfiles[]=null;
            tempfiles[0]=cur;
            status=_SVCCheckLocalFilesForConflicts(tempfiles);
            if ( status==IDCANCEL ) {
               return(COMMAND_CANCELLED_RC);
            } else if ( status ) {
               continue;
            }
            status=_CVSCommit(tempfiles,temp_filename,OutputFilename,true,'',append_to_output,&Files,tag);
         }
         append_to_output=true;
      }
      delete_file(temp_filename);
   }
   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   delete_file(OutputFilename);

   CVSRefreshTreeBitmaps(indexlist,whole_filelist,Files);

   ctltree1._set_focus();
   _EnableGUIUpdateButtons("cvs");
   return(0);
}

static void CVSRefreshTreeBitmaps(int (&indexlist)[],_str (&filelist)[],CVS_LOG_INFO (&Files)[])
{
   int i;
   for ( i=0;i<filelist._length();++i ) {
      _str cur_filename_in_tree=_CVSGetFilenameFromUpdateTree( indexlist[i] );
      found := false;
      int j;
      for ( j=0;j<Files._length();++j ) {
         if ( _file_eq(cur_filename_in_tree,Files[j].WorkingFile) ) {
            found=true;break;
         }
      }
      wid := p_window_id;
      p_window_id=ctltree1;
      if ( found ) {
         int state,bm1;
         _CVSGetFileBitmap(Files[j],bm1);
         _TreeGetInfo(indexlist[i],state);
         _TreeSetInfo(indexlist[i],state,bm1,bm1);
      } else {
         _TreeDelete(indexlist[i]);
      }
      p_window_id=wid;
   }
   _EnableGUIUpdateButtons("cvs");
}

void _CVSGetAllFilesFromUpdateTree(int (&indexlist)[],_str (&filelist)[],
                                   int get_all_parents_with_index=-1,bool allowFolders=false)
{
   indexlist=null;
   filelist=null;
   _str parent_path_list:[]=null;
   selinfo := -1;
   for ( ff:=1;;ff=0 ) {
      index := _TreeGetNextSelectedIndex(ff,selinfo);
      if ( index<1 ) {
         if ( ff ) {
            // No items selected - return current node
            indexlist[0]=_TreeCurIndex();
            filelist[0]=_CVSGetFilenameFromUpdateTree(indexlist[0]);
         }
         break;
      }
      int state,bm1=-1;
      _TreeGetInfo(index,state,bm1);
      if ( allowFolders || (bm1!=_pic_fldopen && bm1!=_pic_cvs_fld_error) ) {
         _str cur_file=_CVSGetFilenameFromUpdateTree(index,allowFolders);
         filelist[filelist._length()]=cur_file;
         indexlist[indexlist._length()]=index;
         if ( _last_char(cur_file)==FILESEP ) {
            parent_path_list:[_file_case(cur_file)]=cur_file;
         } else {
            _str cur_parent_path=_file_path(cur_file);
            parent_index := _TreeGetParentIndex(index);
            for ( ;; ) {
               if ( get_all_parents_with_index>-1 &&
                    !parent_path_list._indexin(cur_parent_path) &&
                    parent_index>-1 ) {

                  int parent_bm1;
                  _TreeGetInfo(parent_index,state,parent_bm1);
                  if ( parent_bm1!=get_all_parents_with_index ) {
                     break;
                  }

                  _str curfile=_CVSGetFilenameFromUpdateTree(parent_index);
                  filelist[filelist._length()]=curfile;
                  indexlist[indexlist._length()]=parent_index;

                  parent_path_list:[cur_parent_path]=cur_parent_path;
               } else break;
               cur_parent_path=_GetParentDirectory(cur_parent_path);
               parent_index=_TreeGetParentIndex(parent_index);
            }
         }
      }
   }
}

_str _CVSGetFilenameFromUpdateTree(int index=-1,bool allowFolders=false)
{
   wid := p_window_id;
   p_window_id=ctltree1;
   int curindex=index;
   if ( curindex==-1 ) {
      curindex=_TreeCurIndex();

      if ( _TreeGetNumSelectedItems()==1 ) {
         int info;
         selIndex := _TreeGetNextSelectedIndex(1,info);
         if ( selIndex>=0 && selIndex!=curindex ) curindex=selIndex;
      }
   }
   int state,bmindex1,bmindex2;
   _TreeGetInfo(curindex,state,bmindex1,bmindex2);
   filename := "";
   if ( bmindex1==_pic_cvs_file
        || bmindex1==_pic_cvs_file_qm
        || bmindex1==_pic_file_old
        || bmindex1==_pic_file_old_mod
        || bmindex1==_pic_file_mod
        || bmindex1==_pic_file_mod_prop
        || bmindex1==_pic_cvs_filep
        || bmindex1==_pic_cvs_filem
        || bmindex1==_pic_cvs_file_new
        || bmindex1==_pic_cvs_file_obsolete
        || bmindex1==_pic_cvs_file_conflict
        || bmindex1==_pic_cvs_file_conflict_updated
        || bmindex1==_pic_cvs_file_conflict_local_added
        || bmindex1==_pic_cvs_file_conflict_local_deleted
        || bmindex1==_pic_cvs_file_error
        || bmindex1==_pic_cvs_filem_mod
        || bmindex1==_pic_file_del
      ) {
      filename=_TreeGetCaption(curindex);
      filename=_TreeGetCaption(_TreeGetParentIndex(curindex)):+filename;
      if ( bmindex1==_pic_cvs_fld_qm ) {
         filename :+= FILESEP;
      }
   } else if (    bmindex1==_pic_cvs_fld_m
               || bmindex1==_pic_cvs_fld_p
               || bmindex1==_pic_cvs_fld_qm
               || bmindex1==_pic_cvs_fld_date
               || bmindex1==_pic_cvs_fld_mod
               || bmindex1==_pic_cvs_fld_mod_date
               || (allowFolders && bmindex1==_pic_fldopen)
             ) {
      filename=_TreeGetCaption(curindex);
   }
   p_window_id=wid;
   return(filename);
}

int _cvs_update_history_button()
{
   _str filename=_CVSGetFilenameFromUpdateTree();
   return( cvs_history(filename,true) );
}

int ctlhistory.lbutton_up()
{
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('update_history_button',system_name);
   status := 0;
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}

void ctltree1.lbutton_double_click()
{
   if ( ctldiff.p_enabled ) {
      int numSelected = ctltree1._TreeGetNumSelectedItems();
      if (numSelected==1) {
         // Only want to do this if there is one file selected, otherwise
         // it was likely somebody selecting multiple items and accidentally
         // double clicking
         ctldiff.call_event(ctldiff,LBUTTON_UP);
      }
   }
}
#endif

#if 0
_command int cvs_add_to_current_commit_set_from_mfg() name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   int i,len=indexlist._length();
   int treewid=ctltree1;
   for (i=0;i<len;++i) {
      _str cur_filename_in_tree=_CVSGetFilenameFromUpdateTree( indexlist[i] );
      int status=cvs_add_to_current_commit_set(cur_filename_in_tree);
      if ( status ) {
         return(status);
      }
   }
   return(0);
}

int _cvs_update_diff_button()
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   int i,len=indexlist._length();
   int treewid=ctltree1;
   for (i=0;i<len;++i) {
      int state,bm1,bm2;
      //ctltree1._TreeGetInfo(ctltree1._TreeCurIndex(),state,bm1,bm2);
      ctltree1._TreeGetInfo(indexlist[i],state,bm1,bm2);

      _str filename=_CVSGetFilenameFromUpdateTree(indexlist[i]);
      _str orig_file_date=_file_date(filename,'B');

      both_remote := false;
      _str version_to_compare=-1;
      _str remote_version,local_version;
      get_tip_tag := true;
      if ( bm1==_pic_file_old_mod ||
           bm1==_pic_cvs_file_conflict ) {

         // If the file is on the branch and we are getting the most up to date
         // version, we want to call GetTipTag later to get the branch tag for
         // the version we are checking out.
         // However, in this case we are specifying the original version of the
         // file, which may actually not be on the branch.  So we set
         // get_tip_tag to false so that we don't get the tag name and just
         // perform the checkout with the version number (version_to_compare)
         // set below.
         get_tip_tag=false;
         CVSGetRemoteVersionForFile(filename,remote_version);

         CVSGetEntriesFileInfo(filename,local_version);
         _str Captions[];
         Captions[0]='Compare local version 'local_version' with remote version 'local_version;
         Captions[1]='Compare local version 'local_version' with remote version 'remote_version;
         Captions[2]='Compare remote version 'local_version' with remote version 'remote_version;
         int result=RadioButtons("Newer version exists",Captions,1,'cvs_diff');
         if ( result==COMMAND_CANCELLED_RC ) {
            return(COMMAND_CANCELLED_RC);
         } else if ( result==1 ) {
            version_to_compare=local_version;
         } else if ( result==2 ) {
            version_to_compare=remote_version;
         } else if ( result==3 ) {
            both_remote=true;
            version_to_compare=remote_version;
         }
      }
      status := 0;
      if ( both_remote ) {
         status=CVSDiffPastVersions(filename,local_version,version_to_compare);
      } else {
         tag := date := "";
         if (get_tip_tag) {
            // Don't always want to get this.  See the comment above where
            // get_tip_tag is set.
            GetTipTag(filename,tag,date);
         }
         status=CVSDiffWithVersion(filename,version_to_compare,false,false,tag,date);
      }
      treewid._set_focus();
      p_window_id=treewid;
      if ( status ) return(status);
      wid := p_window_id;
      p_window_id=ctltree1;
      deleted := false;
      if ( _file_date(filename,'B')!=orig_file_date ) {
         // If we are not commiting or updating the file, get the file's status
         // and reset the bitmap
         CVS_LOG_INFO info[];
         module_name := "";
         _CVSGetVerboseFileInfo(filename,info,module_name);
         if ( info!=null ) {
            int bitmap_index;
            _CVSGetFileBitmap(info[0],bitmap_index);
            _TreeSetInfo(indexlist[i],-1,bitmap_index,bitmap_index);
         } else {
            _TreeDelete(indexlist[i]);
            deleted=true;
         }
      }
      if ( def_cvs_flags&CVS_FIND_NEXT_AFTER_DIFF ) {
         search_for_next := true;
         if ( deleted ) {
            int bmindex1;
            _TreeGetInfo(_TreeCurIndex(),state,bmindex1);
            search_for_next=(bmindex1==_pic_cvs_file\
                             || bmindex1==_pic_cvs_file_qm\
                             || bmindex1==_pic_file_old\
                             || bmindex1==_pic_file_old_mod\
                             || bmindex1==_pic_file_mod\
                             || bmindex1==_pic_file_mod_prop\
                             || bmindex1==_pic_cvs_file_conflict);
         }
         int index=_TreeGetNextIndex(_TreeCurIndex());
         for ( ;; ) {
            if ( index<0 ) break;
            int bmindex1,bmindex2;
            _TreeGetInfo(index,state,bmindex1,bmindex2);
            if ( bmindex1==_pic_cvs_file
                 || bmindex1==_pic_cvs_file_qm
                 || bmindex1==_pic_file_old
                 || bmindex1==_pic_file_old_mod
                 || bmindex1==_pic_file_mod
                 || bmindex1==_pic_file_mod_prop
                 || bmindex1==_pic_cvs_file_conflict
               ) {
               _TreeSetCurIndex(index);
               _TreeSelectLine(index,true);
               break;
            }
            index=_TreeGetNextIndex(index);
         }
      }
      p_window_id=wid;
   }
   return(0);
}

static void _DiffMenuButton()
{
   int menu_index=find_index("_":+GetVCSystemNameFromHistoryDialog():+"_history_menu",oi2type(OI_MENU));
   int diff_menu_index=_menu_find_caption(menu_index,"Diff");
   int menu_handle=_mdi._menu_load(diff_menu_index,'P');
   int flags=VPM_LEFTBUTTON;
   int x=_lx2dx(SM_TWIP,ctldiff.p_x);
   int y=_ly2dy(SM_TWIP,ctldiff.p_y_extent);
   _map_xy(p_active_form,0,x,y,SM_PIXEL);
   _menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
}

int ctldiff.lbutton_up(int reason=0)
{
   if( reason == CHANGE_SPLIT_BUTTON ) {
      // Drop-down menu
      _DiffMenuButton();
      return 0;
   }
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('update_diff_button',system_name);
   status := 0;
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);

}

static int CVSGetRemoteVersionForFile(_str filename,_str &version)
{
   version='';

   _str ErrorFilename=mktemp();
   _CVSCreateTempFile(ErrorFilename);
   _str OutputFilename=mktemp();

   //int status=shell('cvs 1>'OutputFilename' 2>'ErrorFilename' status 'filename,'P'def_cvs_shell_options);
   int status=_CVSShell(_CVSGetExeAndOptions()' 1>'_maybe_quote_filename(OutputFilename)' 2>'_maybe_quote_filename(ErrorFilename)' status '_strip_filename(filename,'P'),filename,'P'def_cvs_shell_options);
   if ( status ) {
      return(status);
   }
   int temp_view_id,orig_view_id;
   status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
   if ( status ) {
      delete_file(OutputFilename);
      delete_file(ErrorFilename);
      return(status);
   }
   status=search('^   Repository revision\:\t?@\t?@$','@r');
   if ( !status ) {
      get_line(auto line);
      parse line with "Repository revision:\t" version "\t" .;
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   delete_file(OutputFilename);
   delete_file(ErrorFilename);
   return(status);
}

/**
 *
 * @param filename
 * @param version  Use -1 for most up to date version
 * @param UpdateButton
 *
 * @return
 */
static int CVSDiffWithVersion(_str filename,_str version=-1,bool UpdateButton=false,
                              bool ReadOnly=false,_str TagName='',_str Date='', _str lang='')
{
   remote_filename := OutputFilename := ErrorFilename := remote_version := "";
   _str checkout_tag=version;
   if (TagName!='') {
      checkout_tag=TagName;
      remote_version=-1;
   }else{
      remote_version=version;
   }
   int status=CVSCheckoutVersion(filename,
                                 checkout_tag,
                                 OutputFilename,
                                 ErrorFilename,
                                 remote_version,
                                 remote_filename,
                                 '',
                                 Date);
   if ( status ) {
      if ( status!=FILE_NOT_FOUND_RC ) {
         msg := "";
         if ( version==-1 ) {
            msg=nls("Could not checkout current version of '%s'",filename);
         } else {
            msg=nls("Could not checkout version %s of '%s'",version,filename);
         }
         _message_box(msg);
      }
      return(status);
   }
   wid := p_window_id;
   int temp_view_id,orig_view_id;
   status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
   if ( status ) {
      if ( status ) {
         _message_box(nls("Could not open locally checked out copy of  '%s'",filename));
      }
      delete_file(OutputFilename);
      delete_file(ErrorFilename);
      return(status);
   }
   if (lang=='') lang=_Filename2LangId(filename);
   _SetEditorLanguage(lang);
   undo_steps := "";
   parse ' 'def_load_options' ' with ' +U:','i' undo_steps .;
   if (undo_steps!='') {
      p_undo_steps=(int)undo_steps;
   }
   local_version := "";

   filenameNQ := strip(filename,'B','"');
   status=CVSGetEntriesFileInfo(filenameNQ,local_version);
   if ( status ) {
      local_version='Unknown';
   }
   ro_opt := "";
   if ( ReadOnly ) {
      ro_opt='-r1';
   }
   _str module_name;
   CVS_LOG_INFO Files[];
   status=_CVSGetVerboseFileInfo(filename,Files,module_name);
   modstr := "";
   if ( !status && Files[0]!=null ) {
      if ( Files[0].Description=='M' ) {
         modstr=' - Modified';
      }
   }
   status = _DiffModal(ro_opt' -r2 -b2 -nomapping -file1title "':+filenameNQ:+' (Version 'local_version' - Local' modstr')" -file2title "'remote_filename' (Version 'remote_version' - Remote)" '_maybe_quote_filename(filename)' '_maybe_quote_filename(OutputFilename),
                       "cvs" );
   _delete_temp_view(temp_view_id);
   _DelTree(_strip_filename(OutputFilename,'N'),true);
   delete_file(ErrorFilename);
   p_window_id=wid;
   _set_focus();
   return(status);
}

static int CVSCheckoutVersion(_str filename,_str version,
                              _str &output_filename,
                              _str &error_filename,
                              _str &remote_version='',
                              _str &remote_filename='',
                              _str &module_name='',
                              _str Date='')
{
   filename=strip(filename,'B','"');
   _str local_filename=filename;
   status := 0;
   if (remote_version=='') {
      remote_version=version;
   }else if ( remote_version==-1 ) {
      status=CVSGetRemoteVersionForFile(local_filename,remote_version);
   }
   error_filename=mktemp();
   _CVSCreateTempFile(error_filename);
   _str output_path=mktemp();
   status=_CVSGetModuleFromLocalFile(filename,module_name);
   if ( status ) {
      msg := "";
      if ( status==FILE_NOT_FOUND_RC ) {
         msg=nls("'%s' is not a CVS file",filename);
      } else {
         msg=nls("Could not get module for '%s'",filename);
      }
      _message_box(msg);
      return(status);
   }
   rfilename := _strip_filename(filename,'P');
   rfilename=strip(rfilename,'B','"');
   filename=module_name:+rfilename;
   version_opt := "";
   if ( version!=-1 ) {
      version_opt=' -r 'version;
   }
   date_opt := "";
   if ( Date>-1 ) {
      date_opt=' -D 'Date;
   }
   remote_filename=filename;
   _str parent_dir=_GetParentDirectory(output_path);

   cvsroot := "";
   _CVSGetRootForFile(local_filename,cvsroot);

   status=_CVSShell(_maybe_quote_filename(_CVSGetExePath())' -d 'cvsroot' co >'_maybe_quote_filename(error_filename)' 2>&1 -d '_maybe_quote_filename(relative(output_path,parent_dir))' 'version_opt' 'date_opt' '_maybe_quote_filename(filename),parent_dir,'P'def_cvs_shell_options);
   if ( status ) {
      _str version_message=version;
      if ( version_message==-1 ) {
         version_message='current version';
      } else {
         version_message='version 'version;
      }
      _message_box(nls("Could not checkout %s of '%s'",version_message,filename));
      _SVCDisplayErrorOutputFromFile(error_filename,status);
      delete_file(error_filename);
   }
   _maybe_append_filesep(output_path);
   output_filename=output_path:+_strip_filename(filename,'P');
   return(status);
}
defeventtab _cvs_comment_form;

static int get_prev_visible_control()
{
   wid := p_window_id;
   while (!wid.p_visible) {
      wid=wid.p_prev;
      if ( wid==p_window_id ) break;
   }
   return(wid);
}

void _cvs_comment_form_initial_alignment()
{
   // these labels are auto-sized - make sure they line up nicely
   if ( ctltag_name.p_visible || ctlauthor_name.p_visible ) {
      labelWidth := ctlauthor_name.p_visible ? ctlauthor_name.p_prev.p_width : 0;
      if ( ctltag_name.p_visible && ctltag_name.p_prev.p_width > labelWidth ) {
         labelWidth = ctltag_name.p_prev.p_width;
      }

      ctltag_name.p_x = ctlauthor_name.p_x = ctltag_name.p_prev.p_x + labelWidth + 20;
      ctltag_name.p_width = ctlauthor_name.p_width = (ctledit1.p_x_extent) - ctltag_name.p_x;
   }

   // now space everything out - some things will not be visible
   shift := 0;
   if ( !ctlapply_to_all.p_visible ) {
      shift = ctlapply_to_all.p_height + 90;
   }

   if ( ctltag_name.p_visible ) {
      // shift up
      ctltag_name.p_y -= shift;
      ctltag_name.p_prev.p_y -= shift;
   } else {
      // add to the shift - adds the control height and the padding b/t it and the control before
      shift += ctltag_name.p_height + 180;
   }

   if ( ctlauthor_name.p_visible ) {
      // shift up
      ctlauthor_name.p_y -= shift;
      ctlauthor_name.p_prev.p_y -= shift;
   } else {
      // add to the shift - adds the control height and the padding b/t it and the control before
      shift += ctlauthor_name.p_height + 120;
   }

   // shift buttons up
   ctlok.p_y -= shift;
   ctlcancel.p_y = ctlok.p_y;

   // no need to make the form smaller - this will handled in on_resize
}

void _cvs_comment_form.on_resize()
{
   // get the padding values
   int xbuffer=ctledit1.p_x;
   int ybuffer=ctledit1.p_prev.p_y;

   xDiff := p_width - (ctledit1.p_width + 2 * xbuffer);
   yDiff := p_height - (ctlok.p_y_extent + ybuffer);

   ctledit1.p_width += xDiff;
   ctltag_name.p_width += xDiff;
   ctlauthor_name.p_width += xDiff;

   // we can just move everything down.  some things are invisible, but the shift should be right
   ctledit1.p_height += yDiff;
   ctlcopy_to_clipboard.p_y += yDiff;
   ctlapply_to_all.p_y += yDiff;
   ctltag_name.p_y += yDiff;
   ctltag_name.p_prev.p_y += yDiff;
   ctlauthor_name.p_y += yDiff;
   ctlauthor_name.p_prev.p_y += yDiff;
   ctlok.p_y += yDiff;
   ctlcancel.p_y += yDiff;

}

static const CVS_COMMENT_FILENAME= 'cvs_comment.txt';
static _str CVSGetCommentFilename()
{
   return(_ConfigPath():+CVS_COMMENT_FILENAME);
}


static void cvs_select_comment(int editctl_wid)
{
   editctl_wid.select_all_line();
}

void ctlok.on_create(_str comment_filename='',_str file_being_checked_in='',
                     bool show_apply_to_all=true,bool show_tag=true,bool show_author=false)
{
   ctledit1.p_SoftWrap=true;
   ctledit1.p_SoftWrapOnWord=true;
   SetDialogInfo("comment_filename",comment_filename);
   ctlapply_to_all.p_visible=show_apply_to_all;
   ctledit1.p_prev.p_caption='Comment for 'file_being_checked_in':';
   ctledit1.p_spell_check_while_typing = true;
   _retrieve_prev_form();
   if ( def_cvs_flags&CVS_RESTORE_COMMENT ) {
      wid := p_window_id;
      p_window_id=ctledit1;
      _delete_line();
      _str prev_comment_filename=CVSGetCommentFilename();
      int status=get(_maybe_quote_filename(prev_comment_filename));
      if (p_Noflines) {
         _post_call(cvs_select_comment,p_window_id);
      }
      p_window_id=wid;
   }
   if ( show_tag ) {
      if ( !(def_cvs_flags&CVS_RESTORE_TAGS) ) {
         ctltag_name.p_text='';
      }
   }else{
      ctltag_name.p_visible=ctltag_name.p_prev.p_visible=false;
   }

   if ( !show_author ) {
      ctlauthor_name.p_visible = ctlauthor_label.p_visible = false;
   }

   // aligns everything now that we have made some controls invisible
   _cvs_comment_form_initial_alignment();
}

/**
 * Returns true if <b>string</B> contains non printable characters
 * @param string string to check for non printable characters
 * 
 * @return bool  true if <b>string</B> contains non printable characters 
 *  
 * @categories String_Functions
 */
static bool HasNonPrintChars(_str string)
{
   len := length(string);
   int i;
   for ( i=1;i<=len;++i ) {
      ch := substr(string,i,1);
      if ( !isprint(ch) ) {
         return(true);
      }
   }
   return(false);
}

/**
 * Checks to be sure that a whitespace delimited list of tags are valid
 * @param taglist list of tags
 * @param text_box_wid window id of textbox that has the tags list.  If this is 0
 *        this function searches for a control called "ctltag".  If that is not
 *        found it uses _message_box instead of _text_box_error
 * 
 * @return bool
 */
static bool _CVSTagCheckFails(_str taglist,int text_box_wid=0)
{
   taglist=strip(taglist);
   if ( !text_box_wid ) {
      text_box_wid=_find_control('ctltag');
   }
   for (;;) {
      _str cur_tag=parse_file(taglist);
      if (cur_tag=='') break;
      cur_tag=strip(cur_tag,'B','"');
      while (substr(cur_tag,1,1)=='-') {
         if (cur_tag=='') break;
         _str option=parse_file(cur_tag);
      }

      cur_tag=strip(cur_tag);
      if ( cur_tag=='' ) {
         return(false);
      }
      ch := _first_char(cur_tag);
      if ( !isalpha(ch) ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names must start with a letter",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names must start with a letter",cur_tag));
         }
         return(true);
      }
      if ( pos(' |\t',cur_tag,1,'r') ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names may not contain whitespace",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names may not contain whitespace",cur_tag));
         }
         return(true);
      }
      if ( HasNonPrintChars(cur_tag) ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names may not contain graphics characters",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names may not contain graphics characters",cur_tag));
         }
         return(true);
      }
   }
   return(false);
}

void ctlok.lbutton_up()
{
   if ( _CVSTagCheckFails(ctltag_name.p_text,ctltag_name.p_window_id) ) {
      return;
   }
   
   orig_view_id1 := p_window_id;
   p_window_id = ctledit1.p_window_id;
   comments := "";
   top();
   _str line;
   do {
      get_line_raw(line);
      comments :+= strip(line, 'T') :+ "\n";
   } while (!down());
   _param3 = strip(comments, 'B', "\n\r");
   //say(comments);
   p_window_id = orig_view_id1;

   status := ctledit1._save_file("+o ":+GetDialogInfo("comment_filename"));
   _param1=(ctlapply_to_all.p_value && ctlapply_to_all.p_visible);
   _param2=ctltag_name.p_text;
   _param4=ctlauthor_name.p_text;
   int copy_comment_to_clipboard=ctlcopy_to_clipboard.p_value;

   _save_form_response();
   wid := p_window_id;
   p_window_id=ctledit1;

   int old_markid=_duplicate_selection('');

   int new_markid=_alloc_selection();
   top();_select_line(new_markid);
   bottom();
   status=_select_line(new_markid);
   if (status) clear_message();

   int temp_view_id,orig_view_id;
   status=_open_temp_view(CVSGetCommentFilename(),temp_view_id,orig_view_id);
   if (status) {
      status=_open_temp_view(CVSGetCommentFilename(),temp_view_id,orig_view_id,'+t');
   }
   if (!status) {
      delete_all();
      status=_copy_to_cursor(new_markid);
      status=_save_config_file();
   }

   status=_show_selection(new_markid);
   if (status) clear_message();

   if (copy_comment_to_clipboard) {
      copy_to_clipboard();
   }

   _show_selection(old_markid);
   p_window_id=orig_view_id;
   _free_selection(new_markid);
   _delete_temp_view(temp_view_id);

   p_window_id=wid;
   p_active_form._delete_window(status);
}

defeventtab _cvs_history_form;
void ctltree1.rbutton_up()
{
   int MenuIndex=find_index("_cvs_history_rclick_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   if ( menu_handle<0 ) {
      // Error loading menu
      return;
   }
   int output_handle,output_pos;
   status := _menu_find(menu_handle,"cvs-history-toggle-empty-branches",output_handle,output_pos,'M');
   if ( !status ) {
      hiddenIndexes := _GetDialogInfoHt("hiddenIndexes");
      _menu_get_state(menu_handle,0,auto menuFlags,'p',auto menuCaption);
      if ( hiddenIndexes!=null ) {
         _menu_set_state(menu_handle,0,menuFlags,'p',"Show empty branches");
      }else{
         _menu_set_state(menu_handle,0,menuFlags,'p',"Hide empty branches");
      }
   }
   int x,y;
   mou_get_xy(x,y);
   status = _menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

/** 
 * Get the tree indexes of branches that have no children
 *  
 * @param indexes Tree indexes are returned here
 * @param curIndex Index to start from, used for recursing, caller should not 
 *                 pass this parameter
 */
static void getChildlessBranchIndexes(int (&indexes)[],int curIndex=TREE_ROOT_INDEX)
{
   for ( ;curIndex>-1; ) {
      _TreeGetInfo(curIndex,auto state,auto NonCurrentBMIndex);
      childIndex := _TreeGetFirstChildIndex(curIndex);
      if ( childIndex<0 ) {
         if ( NonCurrentBMIndex==_pic_branch ) {
            indexes[indexes._length()] = curIndex;
         }
      }else{
         getChildlessBranchIndexes(indexes,childIndex);
      }
      curIndex = _TreeGetNextSiblingIndex(curIndex);
   }
}

_command void cvs_history_toggle_empty_branches() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   // Do not want to run this from the command line, etc.
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      return;
   }
   hiddenIndexes := _GetDialogInfoHt("hiddenIndexes");
   if ( hiddenIndexes==null ) {
      int emptyIndexes[];
      getChildlessBranchIndexes(emptyIndexes);
      foreach ( auto curIndex in emptyIndexes ) {
         _TreeGetInfo(curIndex,auto ShowChildren,auto NonCurrentBMIndex,auto CurrentBMIndex,auto moreFlags);
         _TreeSetInfo(curIndex,ShowChildren,NonCurrentBMIndex,CurrentBMIndex,moreFlags|TREENODE_HIDDEN);
      }
      _SetDialogInfoHt("hiddenIndexes",emptyIndexes);
   }else{
      foreach ( auto curIndex in hiddenIndexes ) {
         _TreeGetInfo(curIndex,auto ShowChildren,auto NonCurrentBMIndex,auto CurrentBMIndex,auto moreFlags);
         _TreeSetInfo(curIndex,ShowChildren,NonCurrentBMIndex,CurrentBMIndex,moreFlags&~TREENODE_HIDDEN);
      }
      _SetDialogInfoHt("hiddenIndexes",null);
   }
}

static _str GetVCSystemNameFromHistoryDialog()
{
   DialogPrefix := "";
   parse p_active_form.p_caption with DialogPrefix .;
   switch (lowcase(DialogPrefix)) {
   case 'log':
      return('cvs');
   case 'cvs':
      return('cvs');
   case 'subversion':
      return('svn');
   case 'git':
      return('git');
   case 'mercurial':
      return('hg');
   }
   return('');
}

static _str _CVSGetRevisionString(int index)
{
   version := _TreeGetCaption(index);
   parse version with version " -- " . ;
   return strip(version);
}

void _cvs_history_view_button()
{
   wid := p_window_id;
   p_window_id=ctltree1;
   int version_index=_CVSGetVersionIndex(_TreeCurIndex());
   _str version=_CVSGetRevisionString(version_index);
   p_window_id=wid;
   _str error_output_filename=mktemp();
   _CVSCreateTempFile(error_output_filename);
   _str temp_dir=mktemp();
   cvs_repository := "";

   _str filename=_CVSGetFilenameFromHistoryDialog();
   just_filename := _strip_filename(filename,'P');

   int status=_CVSGetChildItem(filename,cvs_repository,'Repository');
   remote_filename := cvs_repository'/'just_filename;

   if (status) {
      _message_box(nls("Could not get repository for %s",filename));
      return;
   }
   status=_CVSCheckout(remote_filename,temp_dir,'-r 'version,error_output_filename);
   if (status) {
      _SVCDisplayErrorOutputFromFile(error_output_filename,status);
      delete_file(error_output_filename);
      return;
   }
   local_filename := temp_dir:+FILESEP:+just_filename;
   int temp_view_id,orig_view_id;
   status=_open_temp_view(local_filename,temp_view_id,orig_view_id);
   if (status) {
      _message_box(nls("Could not open local version of %s",remote_filename));
      return;
   }
   _SetEditorLanguage();
   // Tweek the buffer name so that if the user click save they get a "save as"
   // dialog
   p_buf_name=just_filename;
   p_window_id=orig_view_id;

   _showbuf(temp_view_id,false,'-new -modal',remote_filename' (Version 'version')','S',true);
   _delete_temp_view(temp_view_id);
   _DelTree(temp_dir,true);
   delete_file(error_output_filename);
}

void ctlview.lbutton_up()
{
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('history_view_button',system_name);
   if ( index>0 ) {
      call_index(index);
   }
}

int ctlrefresh.lbutton_up()
{
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('history_refresh_button',system_name);
   int status=PROCEDURE_NOT_FOUND_RC;
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}

int _cvs_history_refresh_button(_str DialogFilename='')
{
   fid := 0;
   if ( DialogFilename!='' ) {
      int last=_last_window_id();
      int i;
      for ( i=1;i<=last;++i ) {
         if ( !_iswindow_valid(i) ) continue;
         if ( i.p_name=='_cvs_history_form'  && i.p_caption=='Log info for 'DialogFilename ) {
            fid=i;
         }
      }
   } else {
      fid=p_active_form;
   }
   if ( !fid ) {
      return(0);
   }
   _str filename=fid._CVSGetFilenameFromHistoryDialog();
   int temp_view_id;_str ErrorFilename;
   int status=_CVSGetLogInfoForFile(filename,temp_view_id,ErrorFilename);
   if ( status ) {
      return(status);
   }

   SetDialogInfo('DELETING_TREE',1);
   fid.ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   SetDialogInfo('DELETING_TREE',0);
   fid.FillInHistory(filename,temp_view_id);
   fid.ctltree1.call_event(CHANGE_SELECTED,fid.ctltree1._TreeCurIndex(),fid.ctltree1,ON_CHANGE,'W');
   fid.p_caption='Log info for 'filename;

   _delete_temp_view(temp_view_id);
   delete_file(ErrorFilename);
   return(0);
}

_command int cvs_history(_str filename='',bool quiet=false,
                         _str version=null) name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_history(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:26am 1/7/2015
   if ( filename=='' ) {
      bufname := "";
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to view history for',// Dialog Box Title
                                 '',                   // Initial Wild Cards
                                 def_file_types,       // File Type List
                                 OFN_FILEMUSTEXIST,
                                 '',
                                 bufname
                                );
         if ( result=='' ) return(COMMAND_CANCELLED_RC);
         filename=result;
      }
   }
   filename=absolute(filename);
   if ( isdirectory(filename) ) {
      _message_box("This command does not support directories");
      return(1);
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("'%s' does not exist locally",filename));
      return(1);
   }
   if ( !IsCVSFile(filename) ) {
      _message_box(nls("'%s' is was not checked out from CVS",filename));
      return(1);
   }
   int temp_view_id;_str ErrorFilename;
   int status=_CVSGetLogInfoForFile(filename,temp_view_id,ErrorFilename,quiet);
   if ( status ) {
      _message_box(nls("This file may not exist in the repository"));
      return(status);
   }

   int wid=show('-new -xy -hidden _cvs_history_form');
   wid.FillInHistory(filename,temp_view_id);
   wid.cvs_history_add_menu();
   wid.ctltree1.call_event(CHANGE_SELECTED,wid.ctltree1._TreeCurIndex(),wid.ctltree1,ON_CHANGE,'W');
   wid.p_caption='Log info for 'filename;
   wid.p_visible=true;
   if ( version!=null ) {
      int index=wid.ctltree1._CVSGetTreeIndexFromVersion(version);
      if ( index>-1 ) {
         wid.ctltree1._TreeSetCurIndex(index);
      }
   }

   _delete_temp_view(temp_view_id);
   delete_file(ErrorFilename);

   return(0);
#endif
}
int _CVSGetLogInfoForFile(_str filename,int &temp_view_id,_str &ErrorFilename,bool quiet=false)
{
   ErrorFilename=mktemp();
   //status=shell('cvs log 'filename' >'ErrorFilename' 2>&1','P'def_cvs_shell_options);
   //int status=_CVSShell(_CVSGetExeAndOptions()' log '_maybe_quote_filename(strip_filename(filename,'P'))' >'_maybe_quote_filename(ErrorFilename)' 2>&1',filename,'P'def_cvs_shell_options);
   int status=_CVSShell(_CVSGetExeAndOptions()' log >'_maybe_quote_filename(ErrorFilename)' '_maybe_quote_filename(_strip_filename(filename,'P'))' >'_maybe_quote_filename(ErrorFilename)' 2>&1',filename,'P'def_cvs_shell_options);
   if ( status ) {
      if ( !quiet ) {
         _message_box(nls("cvs log returned %s",status));
      }
      _SVCDisplayErrorOutputFromFile(ErrorFilename,status);
      return(status);
   }
   //status=shell('cvs status 'filename' >>'ErrorFilename' 2>&1','P'def_cvs_shell_options);
   //status=_CVSShell(_CVSGetExeAndOptions()' status '_maybe_quote_filename(strip_filename(filename,'P'))' >>'ErrorFilename' 2>&1',filename,'P'def_cvs_shell_options);
   status=_CVSShell(_CVSGetExeAndOptions()' status  >>'_maybe_quote_filename(ErrorFilename)' '_maybe_quote_filename(_strip_filename(filename,'P'))' 2>&1',filename,'P'def_cvs_shell_options);
   if ( status ) {
      if ( !quiet ) {
         _message_box(nls("cvs log returned %s",status));
      }
      return(status);
   }
   int orig_view_id;
   status=_open_temp_view(ErrorFilename,temp_view_id,orig_view_id);
   p_window_id=orig_view_id;
   return(status);
}

static void FillInHistory(_str filename,int HistoryViewId)
{
   CVS_LOG_INFO info;
   _CVSGetLogInfo(filename,info,HistoryViewId);
   _str line[]=null;
   line[line._length()]='<B>Filename:</B>'stranslate(info.WorkingFile,FILESEP,FILESEP2);
   line[line._length()]='<B>Archive filename:</B>'info.RCSFile;
   line[line._length()]='<B>Head:</B>'info.Head;
   line[line._length()]='<B>Branch:</B>'info.BranchFromLog;
   line[line._length()]='<B>Keyword type:</B>'info.KeywordType;
   line[line._length()]='<B>Description:</B>'stranslate(info.Description,'<br>',"\n");
   line[line._length()]='<B>Local version:</B>'info.LocalVersion;

   color_attr := "";
   if ( info.Status=='Locally Modified' ) {
      line[line._length()]='<B>Status:</B><FONT color="red">'info.Status'</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=SVC_UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=true;
   } else if ( info.Status!='Up-to-date' ) {
      line[line._length()]='<B>Status:</B><FONT color="red">'info.Status'</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=SVC_UPDATE_CAPTION_UPDATE;
      ctlrevert.p_enabled=true;
   } else {
      line[line._length()]='<B>Status:</B>'info.Status;
      ctlupdate.p_enabled=false;
      ctlrevert.p_enabled=false;
   }
   wid := p_window_id;
   _control ctlminihtml1;
   p_window_id=ctlminihtml1;
   p_backcolor=0x80000022;
   ctlminihtml2.p_backcolor=0x80000022;

   // reverse-map revision names to label names
   CVS_VERSION_INFO *pLabelVersion = null;
   foreach ( auto label => pLabelVersion in info.pSymbolicNames ) {
      if ( pLabelVersion != null ) {
         pLabelVersion->Labels[pLabelVersion->Labels._length()] = label;
      }
   }

   line[line._length()]='<B>Tags:</B>'stranslate(info.Description,'<br>',"\n");
   _str branch_captions[]=null;
   p_window_id=ctltree1;
   InitialIndex := -1;
   _str branches_used:[]=null;
   /*int state=-1;
   if (_diff_istagging_supported(get_extension(filename))) {
      state=0;
   }*/
   i := lastInsertedIndex := 0;
   for ( i=0;i<info.VersionList._length();++i ) {
      if ( info.VersionList[i].Author==null ) {
         continue;
      }
      if ( info.VersionList[i].Author==null ) {
         continue;
      }
      parent_index := QuickFindParent(info.VersionList[i].RevisionNumber,lastInsertedIndex);
      if ( parent_index < 0 ) {
         parent_index = FindParent(info.VersionList[i].RevisionNumber);
      }
      if ( parent_index < 0 ) {
         parent_index = TREE_ROOT_INDEX;
      }
      /*int curstate=state;
      if (info.VersionList[i].RevisionNumber=='1.1') {
         curstate=-1;
      }*/
      curstate := -1;
      int index=_TreeAddItem(parent_index,info.VersionList[i].RevisionNumber,TREE_ADD_AS_CHILD,_pic_file,_pic_file,curstate);
      lastInsertedIndex=index;
      if ( info.VersionList[i].RevisionNumber:==info.LocalVersion ) {
         int state,bm1,bm2,flags;
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
         InitialIndex=index;
      }

      if ( info.VersionList[i].Branches._length() ) {
         lastInsertedIndex = AddBranches(index,info.VersionList[i].Branches,info.Branches,branch_captions,branches_used);
      }

      foreach ( label in info.VersionList[i].Labels ) {
         if ( label=='' ) continue;
         line[line._length()]='<LI><A href="'info.VersionList[i].RevisionNumber'">'label' ('info.VersionList[i].RevisionNumber')</A>';
         if (def_cvs_flags & CVS_SHOW_LABELS_IN_TREE) {
            // Find the node in the tree corresponding to this revision
            labelIndex := _CVSGetTreeIndexFromVersion(info.VersionList[i].RevisionNumber);
            if (labelIndex > 0) {
               // Found it, now add this label to it's caption
               origCaption := _TreeGetCaption(labelIndex);
               if (length(origCaption)<=3 || substr(origCaption, length(origCaption)-3, 4) != "...)") {
                  if (_last_char(origCaption)==')') {
                     origCaption = substr(origCaption, 1, length(origCaption)-1);
                     origCaption :+= ", ";
                  } else {
                     origCaption :+= " -- (";
                  }
                  if (length(origCaption) > 200) {
                     newCaption :=  origCaption :+ "..." :+ ")";
                     _TreeSetCaption(labelIndex, newCaption);
                  } else {
                     newCaption :=  origCaption :+ label :+ ")";
                     _TreeSetCaption(labelIndex, newCaption);
                  }
               }
            }
         }
      }

      SetVersionInfo(index,info.VersionList[i]);
   }
   InsertOtherBranches(info,branches_used,info.CurBranch,branch_captions,InitialIndex);
   if ( InitialIndex>=0 ) {
      _TreeSetCurIndex(InitialIndex);
      //if ( _TreeGetNextSiblingIndex(InitialIndex)<0 ) {
      //ctlupdate.p_enabled=false;
      //}
   }
   p_window_id=ctlminihtml1;
   p_text=line[0];
   for ( i=1;i<line._length();++i ) {
      p_text :+= '<br>'line[i];
   }
   p_text :+= '<br><B>Branches:</B><br>';
   for ( i=0;i<branch_captions._length();++i ) {
      p_text :+= line[line._length()]='<LI><A href="'branch_captions[i]'"> 'branch_captions[i]'</A><br>';
   }
   p_window_id=wid;
}

static void cvs_history_add_menu()
{
   int index=find_index("_cvs_history_menu",oi2type(OI_MENU));
   if ( index ) {
      int b4height=p_client_height;
      int menu_handle=p_active_form._menu_load(index);
      p_active_form._menu_set(menu_handle);
   }
}
_command void cvs_history_quit() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   ctlclose.call_event(ctlclose,LBUTTON_UP);
}
_command void cvs_history_diff_local() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   form_name := p_active_form.p_name;
   if ( form_name!='_cvs_history_form' &&
        form_name!='_cvs_mfupdate_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   if ( ctldiff.p_enabled ) {
      ctldiff.call_event(ctldiff,LBUTTON_UP);
   }
}
int _OnUpdate_cvs_history_diff_local(CMDUI &cmdui,int target_wid,_str command)
{
   if ( target_wid.p_name!="_cvs_history_form" &&
        target_wid.p_parent.p_name!="_cvs_history_form" ) {
      return(MF_GRAYED);
   }
   ver1 := ver2 := "";
   int status=_SVNGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   status=_menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version local file with version 'ver1);
   return(MF_ENABLED);
}
int _OnUpdate_cvs_history_diff_past(CMDUI &cmdui,int target_wid,_str command)
{
   if ( target_wid.p_name!="_cvs_history_form" &&
        target_wid.p_parent.p_name!="_cvs_history_form" ) {
      return(MF_GRAYED);
   }
   ver1 := ver2 := "";
   int status=_CVSGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   status=_menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with other version...');
   return(MF_ENABLED);
}
_command void cvs_history_diff_past() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   _str filename=_CVSGetFilenameFromHistoryDialog();
   CVSHistoryDiffPast(filename);
}

int CVSHistoryDiffPast(_str filename,typeless *pfnDiffPastVersions=CVSDiffPastVersions)
{
   _nocheck _control ctltree1;
   ver1 := "";
   int status=_CVSGetVersionsFromHistoryTree(ver1);

   _control ctltree1;
   int tree1=p_active_form.ctltree1;

   int wid=show('_cvs_get_past_version_form',"Choose other version",'"'ver1'"',_pic_branch' '_pic_symbol' '_pic_symbold' '_pic_symbold2' '_pic_symbolm' '_pic_symbolp);
   _TreeCopy(TREE_ROOT_INDEX,TREE_ROOT_INDEX,tree1,wid.ctltree1);
   _str result=_modal_wait(wid);
   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str ver2=result;

   (*pfnDiffPastVersions)(filename,ver1,ver2);
   tree1._set_focus();
   return(0);
}

int _OnUpdate_cvs_history_diff_predecessor(CMDUI &cmdui,int target_wid,_str command)
{
   if ( target_wid.p_name!="_cvs_history_form" &&
        target_wid.p_parent.p_name!="_cvs_history_form" ) {
      return(MF_GRAYED);
   }
   ver1 := ver2 := "";
   int status=_CVSGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with version 'ver2);
   return(MF_ENABLED);
}

static int _CVSGetVersionsFromHistoryTree(_str &ver1,_str &ver2='')
{
   wid := p_window_id;
   p_window_id=ctltree1;
   index := _TreeCurIndex();
   int state,bm1;
   _TreeGetInfo(index,state,bm1);

   if ( bm1==_pic_branch ) {
      index=_TreeGetParentIndex(index);
      if ( index<0 ) {
         return(1);
      }
      _TreeGetInfo(index,state,bm1);
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   ver1=_CVSGetRevisionString(index);
   int v1index=index;

   index=_TreeGetPrevSiblingIndex(index);
   if ( index<0 ) {
      index=_TreeGetParentIndex(v1index);
      if ( index<0 ) {
         return(1);
      }
   }
   _TreeGetInfo(index,state,bm1);
   if ( bm1==_pic_branch ) {
      index=_TreeGetParentIndex(index);
      if ( index<0 ) {
         return(1);
      }
      _TreeGetInfo(index,state,bm1);
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   ver2=_CVSGetRevisionString(index);

   p_window_id=wid;
   return(0);
}
_command void cvs_history_diff_predecessor() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return;
   }
   int wid=ctltree1;
   ver1 := ver2 := "";
   int status=_CVSGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return;
   }
   _str filename=_CVSGetFilenameFromHistoryDialog();
   CVSDiffPastVersions(filename,ver1,ver2);
   wid._set_focus();
}

void _cvs_history_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   int xbuffer=ctlminihtml1.p_x;
   ctlminihtml1.p_width=(/*2**/(client_width intdiv 2))-(xbuffer*2);
   ctltree1.p_x=ctlminihtml1.p_x_extent+xbuffer;
   ctltree1.p_width=(client_width intdiv 2)-(xbuffer);
   ctltree1.p_height=ctlminihtml1.p_height;

   int ybuffer=ctlminihtml1.p_y;

   client_height-=ctlclose.p_height;
   ctlminihtml1.p_height=(2*(client_height intdiv 3))-(ybuffer*3);

   ctltree1.p_height=ctlminihtml1.p_height;

   ctlminihtml2.p_width=client_width-(xbuffer*2);
   ctlminihtml2.p_height=(client_height intdiv 3)-(ybuffer);
   ctlminihtml2.p_y=ctltree1.p_y_extent+ybuffer;
   ctlclose.p_y=ctlminihtml2.p_y_extent+ybuffer;
   ctlclose.p_next.p_y=ctlclose.p_y;
   ctlclose.p_next.p_next.p_y=ctlclose.p_y;
   ctlview.p_y=ctlrevert.p_y=ctlrefresh.p_y=ctlupdate.p_y=ctlclose.p_y;
}

void _cvs_history_form.on_load()
{
   ctltree1._set_focus();
}

static int _CVSGetTreeIndexFromVersion(_str revisionNumber)
{
   // look for exact match
   int index = _TreeSearch(TREE_ROOT_INDEX, revisionNumber, 't');
   if (index > 0) {
      return index;
   }

   // Look for a line with a label on it.
   index = _TreeSearch(TREE_ROOT_INDEX, revisionNumber" -- (", 'tp');
   return index;
}

static int _SVNGetTreeIndexFromVersion(_str revisionNumber)
{
   // look for exact match
   int index = _TreeSearch(TREE_ROOT_INDEX, 'r'revisionNumber, 't');
   if (index > 0) {
      return index;
   }

   // Look for a line with a label on it.
   index = _TreeSearch(TREE_ROOT_INDEX, 'r'revisionNumber" -- (", 'tp');
   return index;
}

static void handleCVSInfoLink(_str hrefText)
{
   // launch web browser if we find an http link in the checkin comments
   if (substr(hrefText,1,5)=='http:' && !_no_child_windows()) {
      p_window_id = _mdi.p_child;
      tag_goto_url(_maybe_quote_filename(hrefText));
      return;
   }

   wid := p_window_id;
   p_window_id=ctltree1;
   int index=_CVSGetTreeIndexFromVersion(hrefText);
   if ( index>=0 ) {
      _TreeSetCurIndex(index);
   }
   p_window_id=wid;
}

static void handleSVNInfoLink(_str hrefText)
{
   // launch web browser if we find an http link in the checkin comments
   if (substr(hrefText,1,5)=='http:' && !_no_child_windows()) {
      p_window_id = _mdi.p_child;
      tag_goto_url(_maybe_quote_filename(hrefText));
      return;
   }

   wid := p_window_id;
   p_window_id=ctltree1;
   if ( isinteger(hrefText) ) {
      int index=(int)hrefText;
      if ( index>=0 ) {
         _TreeSetCurIndex(index);
      }
   }
   p_window_id=wid;
}

void ctlminihtml1.on_change(int reason,_str hrefText)
{
   if ( reason==CHANGE_CLICKED_ON_HTML_LINK ) {
      vcname := GetVCSystemNameFromHistoryDialog();
      switch ( vcname ) {
      case "cvs":
         handleCVSInfoLink(hrefText);
         break;
      case "svn":
         handleSVNInfoLink(hrefText);
         break;
      }
   }

}

static void handleSubversionCommentLink(_str hrefText)
{
   if (substr(hrefText,1,5)=='http:' && !_no_child_windows()) {
      p_window_id = _mdi.p_child;
      tag_goto_url(_maybe_quote_filename(hrefText));
      return;
   }
   caption := ctltree1._TreeGetCaption(ctltree1._TreeCurIndex());
   _mdi.svn_history(hrefText,false,caption);
}

void ctlminihtml2.on_change(int reason,_str hrefText)
{
   if (reason==CHANGE_CLICKED_ON_HTML_LINK) {
      vcname := GetVCSystemNameFromHistoryDialog();
      switch ( vcname ) {
      case "svn":
         switch ( hrefText ) {
         case "fillInAffectedFiles":
            _SVNFillInAffectedFiles();
            break;
         default:
            {
               caption := ctltree1._TreeGetCaption(ctltree1._TreeCurIndex());
               _mdi.svn_history(hrefText,false,caption);
               break;
            }
         }
         break;
      }
   }
}

void ctltree1.on_change(int reason,int changingindex)
{
   if ( GetDialogInfo('DELETING_TREE')==1 ) {
      return;
   }
   //int index=_TreeCurIndex();
   if ( changingindex<0 ) {
      return;
   }
   switch ( reason ) {
   case CHANGE_EXPANDED:
      {
         int state,bm1;
         _TreeGetInfo(changingindex,state,bm1);
         if ( bm1!=_pic_file ) {
            break;
         }
      }
   case CHANGE_SELECTED:
      {
         index := _CVSGetVersionIndex(changingindex);
         if ( index<0 ) {
            ctldiff.p_enabled=false;
            ctlview.p_enabled=false;
         } else {
            ctldiff.p_enabled=true;
            ctlview.p_enabled=true;
         }
         wid := p_window_id;
         p_window_id=ctlminihtml2;
         if ( index>-1 ) {
            info := ctltree1._TreeGetUserInfo(index);
            if ( info._varformat()==VF_LSTR ) {
               p_text=stranslate(ctltree1._TreeGetUserInfo(index),'<br>',"\n");
            }else if ( info._varformat()==VF_ARRAY ) {
               p_text = "";
               len := info._length();
               infoStr := "";
               for ( i:=0;i<len;++i ) {
                  infoStr :+= "\n":+info[i];
               }
               p_text = infoStr;
            }
            /*_str filename=_CVSGetFilenameFromHistoryDialog();
            ext := get_extension(filename);
            p_text :+= '<br><A href="expandtags">See function differences</A>';*/
         } else {
            p_text='';
         }
         p_window_id=wid;
         break;
      }
   }
}

_str _CVSGetFilenameFromHistoryDialog(_str DialogPrefix='Log ')
{
   filename := "";
   parse p_active_form.p_caption with (DialogPrefix) 'info for 'filename;
   return(filename);
}

int _cvs_history_diff_button()
{
   _str version=ctltree1._CVSGetRevisionString(ctltree1._CVSGetVersionIndex());
   _str filename=_CVSGetFilenameFromHistoryDialog();
   _str orig_date=_file_date(filename,'B');
   int status=CVSDiffWithVersion(filename,version);
   if ( _file_date(filename,'B')!=orig_date ) {
      _cvs_history_refresh_button();
   }
   return(status);
}

int ctldiff.lbutton_up(int reason=0)
{
   if( reason == CHANGE_SPLIT_BUTTON ) {
      // Drop-down menu
      _DiffMenuButton();
      return 0;
   }
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('history_diff_button',system_name);
   status := 0;
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}
#endif

#if 0 //10:29am 1/7/2015
_command int cvs_review_and_commit(_str cmdline='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   int status = cvs_diff_with_tip(cmdline);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }
   return cvs_commit(cmdline);
}


_command int cvs_diff_with_tip(_str cmdline='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "CVS";
   svc_diff_with_tip(cmdline);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:29am 1/7/2015
   read_only:=false;
   filename := "";
   ext := "";
   if ( _no_child_windows() && cmdline=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to diff',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( cmdline=='' ) {
      filename=p_buf_name;
      ext=p_LangId;
   } else {
      for ( ;; ) {
         _str cur=parse_file(cmdline);
         if ( cur=='' ) break;
         ch1 := substr(cur,1,1);
         if ( ch1=='-' ) {
            switch ( upcase(substr(cur,2)) ) {
            case 'READONLY':
               read_only=true;
               break;
            }
         } else {
            filename=cur;
         }
      }
   }
   _LoadEntireBuffer(filename,ext);
   tag := date := "";
   GetTipTag(filename,tag,date);
   int status=CVSDiffWithVersion(filename,-1,false,read_only,tag,date,ext);
   return(status);
#endif
}

static int GetTipTag(_str filename,_str &tag,_str &date)
{
   version := timestamp := options := tagname := "";
   int status=CVSGetEntriesFileInfo(filename,version,timestamp,options,tagname);
   if (status) {
      return(status);
   }

   tag='';date='';
   _str ch=_first_char(tagname);
   switch (ch) {
   case 'T':
      // If there was a tag specified, use that as the version.
      tag=substr(tagname,2);break;
   case 'D':
      date=substr(tagname,2);break;
   }
   return(0);
}

static int CVSDiffPastVersions(_str filename,_str version1,_str version2)
{
   _str OutputFilename1,ErrorFilename1,module_name;
   int status=CVSCheckoutVersion(filename,version1,OutputFilename1,ErrorFilename1,'','',module_name);
   if ( status ) {
      // CVSCheckoutVersion would have given user an error message
      return(status);
   }
   _str OutputFilename2,ErrorFilename2;
   status=CVSCheckoutVersion(filename,version2,OutputFilename2,ErrorFilename2);
   if ( status ) {
      // CVSCheckoutVersion would have given user an error message
      return(status);
   }

   just_name := _strip_filename(filename,'p');
   dispname1 := module_name:+just_name' (Version 'version1' - Remote)';
   dispname2 := module_name:+just_name' (Version 'version2' - Remote)';

   status=_DiffModal('-r1 -r2 -nomapping -file1title "'dispname1'" -file2title "'dispname2'" '_maybe_quote_filename(OutputFilename1)' '_maybe_quote_filename(OutputFilename2));

   _DelTree(_strip_filename(OutputFilename1,'N'),true);
   _DelTree(_strip_filename(OutputFilename2,'N'),true);
   delete_file(ErrorFilename1);
   delete_file(ErrorFilename2);

   return(status);
}

int _cvs_history_update_button()
{
   _str filename=_CVSGetFilenameFromHistoryDialog();
   wid := p_window_id;

   status := 0;
   if ( p_caption==SVC_UPDATE_CAPTION_UPDATE ) {
      status=cvs_update(filename);
   } else if ( p_caption==SVC_UPDATE_CAPTION_COMMIT ) {
      status=cvs_commit(filename);
   }

   p_window_id=wid;
   _set_focus();
   if ( !status ) {
      // Sometimes after an update the log command would fail, apparently
      // because the server was still doing some processing on the update.
      // This short delay seems to keep that from happening.
      delay(10);
      _cvs_history_refresh_button();
   }
   return(status);
}

int ctlupdate.lbutton_up()
{
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('history_update_button',system_name);
   status := 0;
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}

void _cvs_history_revert_button()
{
   _str filename=_CVSGetFilenameFromHistoryDialog();
   _str filelist[]=null;
   filelist[0]=filename;
   _str OutputFilename=mktemp();

   updated_new_dir := false;
   int status=_CVSUpdate(filelist,OutputFilename,false,null,false,'-C');
   if (status) {
      _SVCDisplayErrorOutputFromFile(OutputFilename);
   }else{
      _cvs_history_refresh_button();
   }
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
}

void ctlrevert.lbutton_up()
{
   _str system_name=GetVCSystemNameFromHistoryDialog();
   index := _SVCGetProcIndex('history_revert_button',system_name);
   if ( index>0 ) {
      call_index(index);
   }
}

static int QuickFindParent(_str VersionNumber, int index)
{
   if ( index <= 0 ) return 0;

   p := lastpos('.',VersionNumber);
   if ( p<=1 ) {
      return(-1);
   }
   BranchNumber := substr(VersionNumber,1,p-1);

   if ( !pos('.', BranchNumber) ) {
      return TREE_ROOT_INDEX;
   }

   loop {
      caption := _CVSGetRevisionString(index);
      if ( pos('(',caption) ) {
         parse caption with '(' version ')' ;
      } else {
         version=caption;
      }
      if ( version:==BranchNumber ) {
         return(index);
      }

      index = _TreeGetParentIndex(index);
      if ( index <= 0 ) break;
   }

   return(-1);
}

static int FindParent(_str VersionNumber,int index=TREE_ROOT_INDEX)
{
   p := lastpos('.',VersionNumber);
   if ( p<=1 ) {
      return(-1);
   }
   BranchNumber := substr(VersionNumber,1,p-1);

   for ( ;index>-1; ) {
      cindex := _TreeGetFirstChildIndex(index);
      if ( cindex>=0 ) {
         int tindex=FindParent(VersionNumber,cindex);
         if ( tindex>-1 ) {
            return(tindex);
         }
      }
      _str cap=_CVSGetRevisionString(index);
      if ( pos('(',cap) ) {
         parse cap with '(' version ')' ;
      } else {
         version=cap;
      }
      if ( version:==BranchNumber ) {
         return(index);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
   return(-1);
}

static void SetVersionInfo(int index,CVS_VERSION_INFO CurVersionInfo)
{
   line :=  '<B>Author:</B>'CurVersionInfo.Author'<br>';
   line :+= '<B>Date:</B>'AdjustDateForLocalTime(CurVersionInfo.Date)'<br>';

   // search the comment text for substrings matching the defect ID
   // regular expressions, and convert them to URL's.
   _str comment = CurVersionInfo.Comment;
   VC_DEFECT_LABEL_REGEX defectItem;
   p := 1;
   loop {
      orig_p := p;
      foreach ( defectItem in def_vc_defect_label_regexes ) {
         p = pos(defectItem.re, comment, p, "r");
         if ( p > 0 ) break;
         p = orig_p;
      }
      if ( defectItem==null ) break;
      defectTxt := get_match_substr(comment);
      defectId  := get_match_substr(comment,0);
      defectUrl := stranslate(defectItem.url, defectId, "\\1");
      defectHtm := "<A href=\"":+defectUrl:+"\">":+defectTxt:+"</a>";
      comment = substr(comment, 1, p-1) :+ defectHtm :+ substr(comment, p+length(defectTxt));
      p += length(defectHtm);
   }
   line :+= '<B>Comment:</B>' :+ comment;

   // Add in the list of labels if we had any, map them to defects if possible
   if ( CurVersionInfo.Labels._length() > 0 ) {
      line :+= '<BR><B>Labels:</B>';
      foreach ( auto label in CurVersionInfo.Labels ) {
         line :+= '<li>';
         foreach ( defectItem in def_vc_defect_label_regexes ) {
            if ( pos(defectItem.re, label, 1, "r") ) {
               defectId  := get_match_substr(label,0);
               defectUrl := stranslate(defectItem.url, defectId, "\\1");
               line :+= "<A href=\"":+defectUrl:+"\">":+label:+"</a>";
               break;
            }
         }
         // this means we did not find a match for this label
         if ( defectItem==null ) {
            line :+= label;
         }
      }
   }

   _TreeSetUserInfo(index,line);
}

static _str AdjustDateForLocalTime(_str date)
{
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

static _str pad(int number)
{
   numberstr := "";
   if ( number < 10 ) {
      numberstr = "0";
   }
   numberstr :+= number;
   return numberstr;
}

static void InsertOtherBranches(CVS_LOG_INFO info,_str branches_used:[],_str CurBranch,
                                _str (&branch_captions)[],int &InitialIndex)
{
   Data := "";
   int j;
   for ( j=0;j<info.Branches._length();++j ) {
      _str cur_branch_version=_CVSConvertedBranchNumber(info.Branches[j].RevisionNumber);
      if ( !branches_used._indexin(cur_branch_version) ) {
         branch_name := GetBranchName(info,cur_branch_version);
         _str parent_name=TrimLastVersion(cur_branch_version);
         int parent_index=ctltree1._TreeSearch(TREE_ROOT_INDEX,parent_name,'T');
         if ( parent_index <= 0 ) {
            parent_index=ctltree1._TreeSearch(TREE_ROOT_INDEX,parent_name' -- ','TP');
         }
         if ( parent_index>-1 ) {
            cap := branch_name' ('cur_branch_version')';
            wid := p_window_id;
            p_window_id=ctltree1;
            _TreeSetInfo(parent_index,1);
            int flags=((CurBranch==cur_branch_version)?TREENODE_BOLD:0);
            int newindex=_TreeAddItem(parent_index,cap,TREE_ADD_AS_CHILD,_pic_branch,_pic_branch,1,flags);
            if ( flags&TREENODE_BOLD ) {
               InitialIndex=newindex;
            }
            branch_captions[branch_captions._length()]=cap;
            p_window_id=wid;
         }
      }
   }
}

static int AddBranches(int parent_index,
                       _str (&Branches)[],
                       CVS_VERSION_INFO (&SymbolicNames)[],
                       _str (&branch_captions)[],
                       _str (&branches_used):[])
{
   i := index := 0;
   for ( i=0;i<Branches._length();++i ) {
      found := false;
      cur := substr(Branches[i],1,length(Branches[i])-1);
      int j,len=SymbolicNames._length();
      for ( j=0;j<len;++j ) {
         if ( cur==_CVSConvertedBranchNumber(SymbolicNames[j].RevisionNumber) ) {
            found=true;break;
         }
      }
      _str cap=cur;
      if ( found ) {
         cap=SymbolicNames[j].Comment' ('cur')';
         branches_used:[cur]='';
      } else {

      }
      index=_TreeAddItem(parent_index,cap,TREE_ADD_AS_CHILD,_pic_branch,_pic_branch,1);
      branch_captions[branch_captions._length()]=cap;
   }
   _TreeSetInfo(parent_index,1);
   return index;
}

static _str GetBranchName(CVS_LOG_INFO &info,_str version)
{
   int i;
   for ( i=0;i<info.Branches._length();++i ) {
      if ( version==_CVSConvertedBranchNumber(info.Branches[i].RevisionNumber) ) {
         return(info.Branches[i].Comment);
      }
   }
   return('');
}

static _str TrimLastVersion(_str BranchName)
{
   lp := lastpos('.',BranchName);
   if ( lp<=1 ) {
      return(BranchName);
   }
   return(substr(BranchName,1,lp-1));
}

defeventtab _cvs_get_past_version_form;

static _str gDisableList(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}

void ctlok.on_create(_str caption='',_str DisableCapList='',_str DisableBMList='')
{
   if ( caption!='' ) {
      p_active_form.p_caption=caption;
   }
   gDisableList(DisableCapList'|'DisableBMList);
}

ctlok.lbutton_up()
{
   _str version=ctltree1._CVSGetRevisionString(ctltree1._TreeCurIndex());
   p_active_form._delete_window(version);
}

void ctltree1.ENTER()
{
   ctlok.call_event(ctlok,LBUTTON_UP);
}

void ctltree1.on_change(int reason,int index)
{
   if ( index>-1 ) {
      _str cap=_CVSGetRevisionString(index);
      _str DisableCapList,DisableBMList;
      parse gDisableList() with DisableCapList'|'DisableBMList;
      int state,bm1;
      _TreeGetInfo(index,state,bm1);
      if ( pos('"'cap'"',DisableCapList) ||
           pos(' 'bm1' ',' 'DisableBMList' ') ) {
         ctlok.p_enabled=false;
      } else {
         ctlok.p_enabled=true;
      }
   }
}

_cvs_get_past_version_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);
   int xbuffer=ctltree1.p_x;
   int ybuffer=ctltree1.p_y;

   ctltree1.p_width=client_width-(xbuffer*2);

   ctltree1.p_height=client_height-ctlok.p_height-(xbuffer*3);

   ctlok.p_y=ctlok.p_next.p_y=ctltree1.p_x+ctltree1.p_height+ybuffer;
}

defeventtab _cvs_login_form;

static _str GetLabelValueFromDialog()
{
   new_value := "";
   if (ctllocal.p_value) {
      new_value='CVSROOT=:'GetAuthenticationTypeFromDialog()':'ctlcvs_repository.p_text;
   }else{
      new_value='CVSROOT=:'GetAuthenticationTypeFromDialog()':'ctlcvs_userid.p_text'@'ctlcvs_host.p_text':'ctlcvs_repository.p_text;
   }
   return(new_value);
}

void ctlcvs_host.on_change(int reason)
{
   SetCVSRootLabel(GetLabelValueFromDialog());
}

static const CVS_AUTH_PSERVER= 'pserver';
static const CVS_AUTH_GSERVER= 'gserver';
static const CVS_AUTH_KSERVER= 'kserver';
static const CVS_AUTH_FORK=    'fork';
static const CVS_AUTH_EXT=     'ext';
static const CVS_AUTH_LOCAL=   'local';

void ctlok.on_create()
{
   SetCVSRootLabel('CVSROOT=');
   _retrieve_prev_form();
   ctlcvs_userid._retrieve_list();
   ctlcvs_host._retrieve_list();
   ctlcvs_repository._retrieve_list();

   // Now that the retrieval information is there, change the dialog to reflect
   // the users existing CVSROOT
   cvsroot := get_env('CVSROOT');
   if (cvsroot!='') {
      SetLoginDialogToMatchCVSROOT(cvsroot);
   }
}

static void SetLoginDialogToMatchCVSROOT(_str CVSRoot)
{
   _str auth_type,userid_at_host,reposoitory;

   //parse CVSRoot with ':' auth_type ':' userid_at_host ':' reposoitory;
   _CVSParseCVSRoot(CVSRoot,auth_type,userid_at_host,reposoitory);

   switch (auth_type) {
   case CVS_AUTH_PSERVER:
      ctlpserver.p_value=1;break;
   case CVS_AUTH_GSERVER:
      ctlgserver.p_value=1;break;
   case CVS_AUTH_KSERVER:
      ctlkserver.p_value=1;break;
   case CVS_AUTH_FORK:
      ctlfork.p_value=1;break;
   case CVS_AUTH_EXT:
      ctlrsh.p_value=1;break;
   case CVS_AUTH_LOCAL:
      ctllocal.p_value=1;break;
   }

   if (!ctllocal.p_value) {
      _str userid,hostid;
      parse userid_at_host with userid '@' hostid;
      ctlcvs_userid.p_text=userid;
      ctlcvs_host.p_text=hostid;
   }

   ctlcvs_repository.p_text=reposoitory;
}

int ctlok.lbutton_up()
{
   if ( ctlcvs_userid.CheckName('Invalid user id') ) {
      return(1);
   }
   userid := "";
   if (ctlcvs_userid.p_enabled) {
      userid=ctlcvs_userid.p_text;
   }else{
      if ( ctlcvs_host.CheckName('Invalid host name') ) {
         return(1);
      }
   }
   host := ctlcvs_host.p_text;
   // Can't really check as much about the repository...
   repository_name := ctlcvs_repository.p_text;
   int result=_message_box(nls("Do you wish to set CVSROOT in user.cfg.xml so that SlickEdit will restore it?",'',MB_YESNO),'',MB_YESNO);
   cvsroot_val := "";
   if (ctlcvs_userid.p_enabled) {
      cvsroot_val=':'GetAuthenticationTypeFromDialog()':'userid'@'host':'repository_name;
   }else{
      cvsroot_val=':'GetAuthenticationTypeFromDialog()':'repository_name;
   }
   if (result==IDYES) {
      _ConfigEnvVar('CVSROOT',cvsroot_val);
   }else{
      set('CVSROOT='cvsroot_val);
   }

   status := 0;
   if (ctlcvs_userid.p_enabled && GetAuthenticationTypeFromDialog()=='pserver') {
      // Have to wait here because if there is an error we want the user to see it
      options := stranslate(def_cvs_shell_options,'','q','i');
      status=shell(_CVSGetExeAndOptions()' -d 'get_env('CVSROOT')' login','PW'options);
      if ( status ) {
         _message_box(nls("cvs login failed\n\ncvs returned %s",status));
         return(status);
      }
   }
   _save_form_response();
   p_active_form._delete_window(status);

   return(status);
}

static int CheckName(_str ErrorMesssage,_str InvalidChars='')
{
   userid := strip(ctlcvs_userid.p_text);

   if ( pos(' ':+InvalidChars,userid) ||
        (userid=='' && !ctllocal.p_value)
        ) {
      _text_box_error(ErrorMesssage);
      return(1);
   }
   return(0);
}

static _str GetAuthenticationTypeFromDialog()
{
   if ( ctlpserver.p_value ) {
      return(CVS_AUTH_PSERVER);
   } else if ( ctlgserver.p_value ) {
      return(CVS_AUTH_GSERVER);
   } else if ( ctlkserver.p_value ) {
      return(CVS_AUTH_KSERVER);
   } else if ( ctlfork.p_value ) {
      return(CVS_AUTH_FORK);
   } else if ( ctlrsh.p_value ) {
      return(CVS_AUTH_EXT);
   } else if ( ctllocal.p_value ) {
      return(CVS_AUTH_LOCAL);
   }
   return('');
}

void ctlpserver.lbutton_up()
{
   SetCVSRootLabel(GetLabelValueFromDialog());
}

static void SetCVSRootLabel(_str NewValue)
{
   root_filename := CVS_CHILD_DIR_NAME:+FILESEP:+CVS_ROOT_FILENAME;
   match := file_match(root_filename' -p',1);
   /*if ( file_eq(match,root_filename) ) {
      ctlcvs_root_label.p_caption='<CVSROOT will be ignored because you have a local 'CVS_CHILD_DIR_NAME'\Root file>';
      ctlcvs_root_label.p_forecolor=0x000000FF;
      return;
   }*/
   ctlcvs_root_label.p_caption=NewValue;
   ctlcvs_root_label.p_forecolor=0x80000008;
   ctlcvs_userid.p_enabled=ctlcvs_userid.p_prev.p_enabled=
      ctlcvs_host.p_enabled=ctlcvs_host.p_prev.p_enabled=!ctllocal.p_value;
}
#endif

/**
 * Displays login dialog for CVS.  After the user fills it
 * out and presses OK it will set CVSROOT and call
 * <B>cvs login<B>.  This is done with a call to <B>shell</B>
 * without the 'Q' option and with the 'W' option so that the
 * user can still type in their password and see if there
 * are errors.
 *
 * @return 0 if succesfull, error code from cvs otherwise
 */
_command int cvs_login() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str result=show('-modal _cvs_login_form');
   int status;
   if ( result=='' ) {
      status=COMMAND_CANCELLED_RC;
   } else {
      status=(int)result;
   }
   return(status);
}


#if 0 //10:31am 1/7/2015
_command int cvs_open_workspace() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   int status=CVSOpenWizard();
   return(status);
}
#endif

#if 0 //10:31am 1/7/2015
_command int cvs_checkout_module() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   int status=CVSOpenWizard(true);
   return(status);
}
#endif


static void SetDialogInfo(_str name,typeless data)
{
   typeless AllData=p_active_form.p_user;
   AllData:[name]=data;
   p_active_form.p_user=AllData;
}

static typeless GetDialogInfo(_str name)
{
   typeless AllData=p_active_form.p_user;
   return(AllData:[name]);
}

_command cvs_setup() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   config('CVS', 'V');
}

struct CVS_BITMAP_INFO2 {
   _str RootHashTab:[];
   int SocketHashTab:[];

   _str LastWorkspaceFilename;
   int Bitmaps:[];         // Hashtable of bitmap indexes, indexed by filename
   int OutputViewId;       // View id that collects output from the socket
   int EntryViewHashTab:[];// Hashtable of viewids of CVS/Entries files(indexed by file path(w/o CVS))
   //_str QueuedFiles[];
   int QueuedFilesViewId;     // These are files that we are waiting to get info on
   _str LocalFilesHashTab:[]; // Local filenames and versions, indexed by archive filenames.
                              // stored as filename"\t"version
   bool ProcessNext;
   _str Passwords:[];
};

static CVS_BITMAP_INFO2 gBitmapInfo2;

static int BMFileQueueGetNumFiles()
{
   orig_view_id := p_window_id;
   p_window_id=gBitmapInfo2.QueuedFilesViewId;
   num_files_queued := p_Noflines;
   p_window_id=orig_view_id;
   return(num_files_queued);
}

static _str BMFileQueueGetNext()
{
   orig_view_id := p_window_id;
   p_window_id=gBitmapInfo2.QueuedFilesViewId;
   top();
   get_line(auto line);
   p_window_id=orig_view_id;
   return(line);
}

static void BMFileQueueRemoveFirst()
{
   orig_view_id := p_window_id;
   p_window_id=gBitmapInfo2.QueuedFilesViewId;
   top();
   _delete_line();
   p_window_id=orig_view_id;
}

static void BMFileQueueMaybeInit()
{
   if ( !gBitmapInfo2.QueuedFilesViewId ) {
      int orig_view_id=_create_temp_view(gBitmapInfo2.QueuedFilesViewId);
      p_buf_name='.CVS Queued Files';
      p_window_id=orig_view_id;
   }
}

static void BMFileQueuePut(_str filename)
{
   BMFileQueueMaybeInit();
   orig_view_id := p_window_id;
   p_window_id=gBitmapInfo2.QueuedFilesViewId;
   bottom();
   insert_line(filename);
   p_window_id=orig_view_id;
}

static _str GetLocalFileTime(_str filename)
{
   info := file_match(_maybe_quote_filename(filename)' -p +v',1);
   if ( info=='' ) {
      return(info);
   }
   return(strip(substr(info,DIR_DATE_COL,DIR_DATE_WIDTH))' 'strip(substr(info,DIR_TIME_COL,DIR_TIME_WIDTH)));
}

static void InitVariables()
{
   gBitmapInfo2.RootHashTab=null;
   gBitmapInfo2.SocketHashTab=null;
   gBitmapInfo2.LastWorkspaceFilename='';
   gBitmapInfo2.Bitmaps=null;
   gBitmapInfo2.OutputViewId=0;
   gBitmapInfo2.EntryViewHashTab=null;
   gBitmapInfo2.QueuedFilesViewId=0;
   gBitmapInfo2.LocalFilesHashTab=null;
   gBitmapInfo2.ProcessNext=false;
   gBitmapInfo2.Passwords=null;
}

static int CVSGetCVSRepository(_str filename,_str &cvs_repository)
{
   cvs_repository='';
   if ( !isdirectory(filename) ) {
      filename=_file_path(filename);
   }
   if ( gBitmapInfo2.RootHashTab._indexin(_file_case(filename)) != null ) {
      cvs_repository = gBitmapInfo2.RootHashTab:[_file_case(filename)];
      return(0);
   }
   //int status=_CVSGetRootForFile(filename,cvs_repository);
   int status=_CVSGetChildItem(filename,cvs_repository,'Repository');
   gBitmapInfo2.RootHashTab:[_file_case(filename)] = cvs_repository;
   return(status);
}

static _str gMonthHashTab:[]= {
   "JAN" => 1,"FEB" => 2,"MAR" => 3,"APR" => 4,"MAY" => 5,"JUN" => 6,
   "JUL" => 7,"AUG" => 8,"SEP" => 9,"OCT" => 10,"NOV" => 11,"DEC" => 12,
};

static _str SlickeditStyleDate(_str CVSDate)
{
   typeless day,month,date,time,year,hour,minute,second;
   // Check about international dates...
   parse CVSDate with day month date time year;

   month=gMonthHashTab:[upcase(month)];
   parse time with hour':'minute':'second;
   if ( !isinteger(year)
        ||!isinteger(month)
        ||!isinteger(date)
        ||!isinteger(hour)
        ||!isinteger(minute)
        ||!isinteger(second)
      ) {
      // Occasionally CVS sets this date to something other than a date.  If this
      // is the case, just return the original date.
      return(CVSDate);
   }
   _localize_time(year, month, date, hour, minute, second);

   ampm := 'a';
   if ( hour-12>=0 ) {
      ampm='p';
      hour-=12;
   }
   date_prefix := "";
   if ( length(date)==1 ) {
      date_prefix='0';
   }
   minute_prefix := "";
   if ( length(minute)==1 ) {
      minute_prefix='0';
   }
   return(month'-'date_prefix:+date'-'year' 'hour':'minute_prefix:+minute:+ampm);
}

static int GetEntryViewId(_str Path,int (&EntryViewHashTab):[],int &EntryViewId)
{
   EntryViewId=0;
   cased_path := _file_case(Path);
   if ( EntryViewHashTab._indexin(cased_path) ) {
      EntryViewId = EntryViewHashTab:[cased_path];
      return(0);
   }
   entries_filename := Path:+CVS_CHILD_DIR_NAME:+FILESEP:+CVS_ENTRIES_FILENAME;

   // Be sure to load the whole file.  If this gets locked, we can goof up cvs
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(entries_filename,temp_view_id,orig_view_id,'+l');
   if ( status ) {
      return(status);
   }
   p_window_id=orig_view_id;
   EntryViewHashTab:[cased_path]=temp_view_id;
   EntryViewId=temp_view_id;
   return(0);
}

static int CVSGetAllWorkspaceFiles(_str (&Files)[])
{
   Files=null;
   if ( _workspace_filename=='' ) {
      // Nothing to do
      return(0);
   }

   return _getWorkspaceFiles(_workspace_filename, Files);
}

static int GetPassword(_str CVSRoot,_str &password)
{
   if ( gBitmapInfo2.Passwords._indexin(CVSRoot) ) {
      password = gBitmapInfo2.Passwords:[CVSRoot];
      return(0); 
   }
   // Reset this so if we fail, it isn't set to null and causes other problems
   password='';
   _str password_filename;
   password_filename=GetPasswordFilename();
   if ( password_filename=='' ) {
      return(1);
   }
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(password_filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   top();
   _str servertype,user_at_host,remote_path;
   //parse CVSRoot with ':' servertype ':' user_at_host ':' remote_path;
   _CVSParseCVSRoot(CVSRoot,servertype,user_at_host,remote_path);
   status=search('^(|/1 )'_escape_re_chars(CVSRoot)' ','@r');
   if ( status ) {
      new_root := '\:'servertype'\:'_escape_re_chars(user_at_host)'\::i'remote_path;
      status=search('^(|/1 )'new_root' ','@r');
   }
   if ( !status ) {
      get_line(auto line);
      parse line with (remote_path) ' ' password;
      gBitmapInfo2.Passwords:[CVSRoot]=password;
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

static _str GetPasswordFilename()
{
   // 10:10:42 AM 11/8/2002
   // This mimics the way that cvs 1.11.1p1 does this
   password_filename := "";

   home_env := get_env('HOME');
   if ( home_env!='' ) {
      _maybe_append_filesep(home_env);
      password_filename=home_env:+CVS_PASS_FILENAME;
   } else {
      home_drive := get_env('HOMEDRIVE');
      home_path := get_env('HOMEPATH');
      password_filename=home_drive:+home_path;
      _maybe_append_filesep(password_filename);
      password_filename :+= CVS_PASS_FILENAME;
   }
   return(password_filename);
}

static int CVSMaybeInitSockets()
{
   int already_init=vssIsInit();
   if ( already_init ) {
      return(0);
   }
   int status=vssInit();
   return(status);
}

void _exit_cvs()
{
   typeless i;
   for ( i._makeempty();; ) {
      gBitmapInfo2.SocketHashTab._nextel(i);
      if ( i==null ) break;
      if ( gBitmapInfo2.SocketHashTab:[i]>-1 ) {
         vssSocketClose(gBitmapInfo2.SocketHashTab:[i]);
      }
   }
   gBitmapInfo2._makeempty();
}

#if 0 //10:41am 4/15/2019
_command int cvs_get_annotated_buffer(_str filename='') name_info(FILE_ARG'*,'VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   lang := "";
   restore_linenum := false;
   if ( filename=='' ) {
      bufname := "";
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
         lang=_mdi.p_child.p_LangId;
         restore_linenum = true;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to view history for',// Dialog Box Title
                                 '',                   // Initial Wild Cards
                                 def_file_types,       // File Type List
                                 OFN_FILEMUSTEXIST,
                                 '',
                                 bufname
                                );
         if ( result=='' ) return(COMMAND_CANCELLED_RC);
         filename=result;
      }
   }
   filename=absolute(filename);
   if ( isdirectory(filename) ) {
      _message_box("This command does not support directories");
      return(1);
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("'%s' does not exist locally",filename));
      return(1);
   }
   if ( !IsCVSFile(filename) ) {
      _message_box(nls("'%s' is was not checked out from CVS",filename));
      return(1);
   }
   relative_filename := relative(filename);
   if (_isWindows()) {
      relative_filename = stranslate(relative_filename,FILESEP2,FILESEP);
   }
   if ( lang == '' ) {
      lang = _Filename2LangId(filename);
   }
   ln := p_line; col := p_col;
   mou_hour_glass(true);
   cvs_tag := "";
   int status=_CVSGetChildItem(filename,cvs_tag,'Tag');
   if ( status ) cvs_tag='';

   cvs_tag_option := "";
   if ( substr(cvs_tag,1,1)=='T' ) {
      cvs_tag = substr(cvs_tag,2);
      if ( cvs_tag!="" ) {
         cvs_tag_option = "-r ":+cvs_tag;
      }
   }

   status = _CVSPipeProcess(_CVSGetExeAndOptions():+" annotate ":+cvs_tag_option:+" ":+_maybe_quote_filename(relative_filename),'','P'def_cvs_shell_options,auto StdOutData,auto StdErrData);
   mou_hour_glass(false);
   if ( status ) {
      _message_box(nls("cvs annoated failed for file '%s'\n\ncvs returned %s",relative_filename,status));
      return status;
   }
   edit('+t');
   _delete_line();

   p_DocumentName="Annotations for ":+filename;
   _SetEditorLanguage(lang);
   _insert_text_raw(StdOutData.get());
   p_modify=false;
   p_ReadOnly = true;

   top();
   if ( restore_linenum ) {
      p_line = ln; p_col = col;
   }
   return status;
}
_str _CVSConvertedBranchNumber(_str a) {
   return stranslate(a,'.','.0.');
}
#endif

