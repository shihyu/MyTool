////////////////////////////////////////////////////////////////////////////////////
// $Revision: 39918 $
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
#import "cvs.e"
#import "cvsutil.e"
#import "dir.e"
#import "se/datetime/DateTime.e"
#import "diff.e"
#import "git.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "main.e"
#import "mprompt.e"
#import "project.e"
#import "projconv.e"
#import "ptoolbar.e"
#import "savecfg.e"
#import "saveload.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svc.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#endregion

using namespace se.datetime;

// NOTE: check out http://git.or.cz/course/svn.html for a great comparison of SVN and git

// the flag that allows ending long async functions
static boolean gHgCancel=false;
// flag indicating whether or not push and pull should be interactive
boolean def_hg_pushpull_interactive = true;
// flag indicating whether or not all output should be written to the output window
boolean def_hg_output_all = true;

static int max_debug_shell_output = 25;

#define PULL_REQUIRES_MERGE  2
#define PULL_NO_CHANGES      3
#define COMMIT_MERGE_PENDING 4

// initialization
definit()
{
   if (def_hg_info == null) {
      _HgInit(def_hg_info);
   }
}

/**
 * Initialize all of the global data that we need to keep. 
 *  
 * @param hg_info : Data to initialize
 */
void _HgInit(HG_SETUP_INFO &hg_info)
{
   if (def_hg_info == null || def_hg_info.hg_exe_name == '' || !file_exists(def_hg_info.hg_exe_name)) {
      // Can't find hg executable.
      def_hg_info.hg_exe_name = path_search(HG_EXE_NAME);
   }
}

/**
 * Returns the name/path of the hg executable that we are 
 * configured to use. If that is not found, we look for one in 
 * the path. 
 *  
 * @return _str - Name of the hg executable
 */
_str _HgGetExeName()
{
   if (def_hg_info == null) {
      _HgInit(def_hg_info);
   }
   _str exe_name=def_hg_info.hg_exe_name;
   if (!file_exists(exe_name)) {
      exe_name=path_search(HG_EXE_NAME);
   }
   return exe_name;
}

/**
 * The command entry point for executing a hg push command.
 * 
 * @param filename The file name which originated the push request
 * 
 * @return int - 0 for success
 */
_command int hg_push(_str repositoryName='') name_info(FILE_ARG'*,')
{
   // we don't care if the file exists or not, we just need a path
   int status = _HgPush(repositoryName);
   return status;
}

/**
 * This function executes an hg push command.  The path of the 
 * specified file name is parsed and we determine if the file 
 * belongs to a hg repository.  If so, then we push that whole 
 * repository, since a push cannot be done on a subset of the 
 * repository. 
 *  
 * The command line mode may need to be visible because it may 
 * interactively ask for an ssh passphrase. 
 * 
 * @param filename The file name which originated the push request
 * 
 * @return int - 0 for success
 */
int _HgPush(_str repositoryName)
{
   // run the push command from the repository root
   _str cmd = 'push 'repositoryName;
   _str output[];
   _str shellOption = '';
   if (def_hg_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   int status = _HgShell(cmd, repositoryName, shellOption, output);
   if (status) {

      // get the repository url and show an error message box
      _message_box('Mercurial returned 'status' pushing to repository 'repositoryName'.');
      return status;
   }
   return status;
}

// http://stackoverflow.com/questions/2816369/git-push-error-remote-rejected-master-master-branch-is-currently-checked-ou
/**
 * The command entry point for executing a hg pull command.
 * 
 * @param filename The file name which originated the pull request
 * 
 * @return int - 0 for success
 */
_command int hg_pull(_str repository="") name_info(FILE_ARG'*,')
{
   int status = _HgPull(repository);
   if ( !status ) {
      result := _message_box(nls("Pull was successful, update now?"),"",MB_YESNO);
      if ( result==IDYES ) {
         _HgUpdate();
      }
   } else if ( status == PULL_REQUIRES_MERGE ) {
      result := _message_box(nls("Pull created multiple heads, attempt to merge now?"),"",MB_YESNO);
      if ( result==IDYES ) {
         _HgMerge(repository);
      }
   } else if ( status==PULL_NO_CHANGES ) {
      _message_box(nls("No changes found")); 
   }
   return status;
}

_command int hg_clone(_str repository="") name_info(FILE_ARG'*,')
{
   status := 0;

   if ( repository=="" ) {
      _HgGetRepository(repository);
      if ( repository=="" ) {
         _HgGetUrlForLocalRepository(repository);
      }
   }
   status = hgClonePrompt(repository,auto clonePath="");
   if ( status==COMMAND_CANCELLED_RC ) {
      return COMMAND_CANCELLED_RC;
   }
   clonePathDir := clonePath;
   _maybe_append_filesep(clonePathDir);

   status = _HgClone(repository,clonePath);

   return status;
}

_command int hg_set_repository() name_info(FILE_ARG'*,')
{
   status := 0;

   status = textBoxDialog("Set Mercurial Repository"
                          ,TB_RETRIEVE_INIT
                          ,0
                          ,"Mercurial"
                          ,""
                          ,"mercurial"
                          ,"Repository Name");
   if ( status==COMMAND_CANCELLED_RC ) {
      return COMMAND_CANCELLED_RC;
   }

   repository := _param1;

   _ProjectSet_VCSProject(_ProjectHandle(),def_vc_system':'repository);
   _ProjectSave(_ProjectHandle());

   return status;
}

int _HgGetRepository(_str &repository)
{
   VCSProject := _ProjectGet_VCSProject(_ProjectHandle());
   parse VCSProject with ':' repository;
   return 0;
}

/**
 * This function executes the pull or the repository.  The path 
 * of the specified file name is parsed and we determine if the 
 * file belongs to a hg repository.  If so, then we pull that 
 * whole repository, since a pull cannot be done on a subset of 
 * the repository. 
 *  
 * A pull in hg gets the latest and merges it with the local 
 * version.  This can create a merge situation, which should be 
 * reported. 
 *  
 * The command line mode may need to be visible because it may 
 * interactively ask for an ssh passphrase. 
 * 
 * @param filename The file name which originated the push request
 * 
 * @return int - 0 for success
 */
static int _HgPull(_str path)
{
   // first, find out if this file is addable in hg and get the repository root for this file
   _str repositoryRoot = '';

   // run the push command
   _str cmd = 'pull';
   _str output[];
   _str shellOption = '';
   if (def_hg_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   int status = _HgShell(cmd, repositoryRoot, shellOption, output);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _HgGetUrlForLocalRepository(repositoryRoot);
      _message_box('Mercurial returned 'status' pulling repository at 'repositoryUrl'.');
      return status;
   }
   len := output._length();
   for ( i:=0;i<len;++i ) {
      if ( output[i]=="(run 'hg heads' to see heads, 'hg merge' to merge)" ) {
         status = PULL_REQUIRES_MERGE;
         break;
      } else if ( output[i]=="no changes found" ) {
         status = PULL_NO_CHANGES;
         break;
      }
   }
   // reload any buffers that may be affected
   _actapp_files();

   return status;
}

static int _HgClone(_str repository,_str cloneName)
{
   status := 0;
   // first, find out if this file is addable in hg and get the repository root for this file
   _str repositoryRoot = '';

   // run the push command
   _str cmd = 'clone 'repository' 'cloneName;
   _str output[];
   _str shellOption = '';
   if (def_hg_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   status = _HgShell(cmd, repositoryRoot, shellOption, output,false);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _HgGetUrlForLocalRepository(repositoryRoot);
      _message_box('Mercurial returned 'status' pulling repository at 'repositoryUrl'.');
      return status;
   }
   // reload any buffers that may be affected
   _actapp_files();
   return status;
}

static int _HgMerge(_str repository)
{
   _str shellOption = '';
   if (def_hg_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   _str cmd = 'merge';
   int status = _HgShell(cmd, repository, shellOption, auto output);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _HgGetUrlForLocalRepository(repository);
      _message_box('Mercurial returned 'status' merging');
      return status;
   }
   // reload any buffers that may be affected
   _actapp_files();

   return status;
}

static int _HgUpdate(_str path="")
{
   // first, find out if this file is addable in hg and get the repository root for this file
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(path, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The path 'path' cannot be updated to Mercurial because it is not within a working tree.');
      return -1;
   }

   // run the push command
   _str cmd = 'update';
   _str output[];
   _str shellOption = '';
   if (def_hg_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   int status = _HgShell(cmd, path, shellOption, output);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _HgGetUrlForLocalRepository(repositoryRoot);
      _message_box('Mercurial returned 'status' pulling repository at 'repositoryUrl'.');
      return status;
   }
   // reload any buffers that may be affected
   _actapp_files();

   return status;
}

// http://www.kernel.org/pub/software/scm/git/docs/git-show.html
/**
 * The command entry point for diffing a file with the tip in the repository.
 * 
 * @param filename The file name which originated the diff request
 * 
 * @return int - 0 for success
 */
_command int hg_diff_with_tip(_str cmdline='') name_info(FILE_ARG'*,')
{
   boolean read_only=false;
   _str filename='';
   _str lang='';
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
      lang=p_LangId;
   } else {
      for ( ;; ) {
         _str cur=parse_file(cmdline);
         if ( cur=='' ) break;
         _str ch1=substr(cur,1,1);
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
   _LoadEntireBuffer(filename,lang);
   int status=HgDiffWithVersion(strip(filename,'b','"'),-1,false,'',lang);
   return(status);
}

int _hg_history_diff_button()
{
   // get the file name
   int formWid = p_parent;
   _str filename = formWid.p_user;
   // get the selected version
   _nocheck _control ctltree1;
   int wid = p_window_id;
   p_window_id = ctltree1;
   int version_index = _CVSGetVersionIndex(_TreeCurIndex());
   version := getRevisionNumber(version_index);
   p_window_id = wid;

   // we don't care if the file exists or not, we just need a path
   int status = HgDiffWithVersion(filename, version);
   return status;
}

/**
 * Performs diff_with_tip on the passed file name.
 *  
 * @param filename The file name to compare with the tip in 
 *                 Mercurial.
 *
 * @return int - 0 for success.
 */
static int HgDiffWithVersion(_str filename,_str version=-1,
                             boolean ReadOnly=false,
                             _str TagName='',_str lang='')
{
   _str OutputFilename='',remote_version='';
   _str checkout_tag=version;
   if (TagName!='') {
      checkout_tag=TagName;
      remote_version=-1;
   }else{
      remote_version=version;
   }
   int status = 0;

   _str options='';
   if ( remote_version!='-1' ) {
      options=' -r 'remote_version;
   }

   status=_HgCheckoutFile(filename,options,OutputFilename);
   if ( status ) {
      if ( status!=FILE_NOT_FOUND_RC ) {
         _str msg='';
         if ( version==-1 ) {
            msg=nls("Could not checkout current version of '%s'",filename);
         } else {
            msg=nls("Could not checkout version %s of '%s'",version,filename);
         }
         _message_box(msg);
      }
      return(status);
   }
   int wid=p_window_id;
   int temp_view_id,orig_view_id;
   _str encoding_option=_load_option_encoding(filename);
   status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id,encoding_option);
   if ( status ) {
      if ( status ) {
         _message_box(nls("Could not open locally checked out copy of  '%s'",filename));
      }
      delete_file(OutputFilename);
      return(status);
   }
   if (lang=='') lang=_Filename2LangId(filename);
   _SetEditorLanguage(lang);
   _str undo_steps='';
   parse ' 'def_load_options' ' with ' +U:','i' undo_steps .;
   if (undo_steps!='') {
      p_undo_steps=(int)undo_steps;
   }
   _str local_version = "";
   status = _HgGetCurrentVersionForFile(filename,local_version);
   if ( status ) {
      local_version='Unknown';
   }
   _str ro_opt='';
   if ( ReadOnly ) {
      ro_opt='-r1';
   }

   _str modstr='';
   _str maybe_remote_version='';
   int status_flags=0;
   if ( remote_version==-1 ) {
      remote_version = "TIP";
   }
   filenamenq := strip(filename,'B','"');
   _DiffModal(ro_opt' -r2 -bi2 -nomapping -file1title "':+filenamenq:+' (Version 'local_version' - Local' modstr')" -file2title "'filenamenq' (Version 'remote_version' - Remote)" 'maybe_quote_filename(filename)' 'temp_view_id.p_buf_id,"hg");
   _delete_temp_view(temp_view_id);
   delete_file(OutputFilename);
   p_window_id=wid;
   _set_focus();
   return(status);
}

int _HgCheckoutFile(_str filename,
                     _str checkout_options='',
                     _str &OutputFilename='',
                     boolean quiet=false)
{
   _str caption='';
   status := _HgShell("cat ":+checkout_options' 'maybe_quote_filename(filename),"","q",auto output=null,true,auto outputTempWID=0);
   if ( status && !quiet ) {
      _message_box(nls("Could not checkout file %s.\n\n%s",filename,get_message(status)));
      return status;
   }
   orig_wid := p_window_id;
   p_window_id = outputTempWID;
   if ( OutputFilename=="" ) OutputFilename = mktemp();
   _save_file('+o 'maybe_quote_filename(OutputFilename));
   p_window_id = orig_wid;
   _delete_temp_view(outputTempWID);

   return(status);
}

_command int hg_history_diff_predecessor()
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return(COMMAND_CANCELLED_RC);
   }

   // get the file name
   int formWid = p_parent;
   _str filename = formWid.p_user;
   // get the selected version
   _nocheck _control ctltree1;
   int wid = p_window_id;
   p_window_id = ctltree1;
   int version_index = _CVSGetVersionIndex(_TreeCurIndex());
   version1 := getRevisionNumber(version_index);
   int predecessor_index = _TreeGetNextSiblingIndex(version_index);
   if (predecessor_index < 0) {
      p_window_id = wid;
      _message_box('Version 'version1' has no predecessor.');
      return -1;
   }
   version2 := getRevisionNumber(predecessor_index);
   p_window_id = wid;

   // we don't care if the file exists or not, we just need a path
   int status = _HgDiffTwoVersions(filename, version1, version2);
   return status;
}

/**
 * Performs diff_with_tip on the passed file name.
 *  
 * @param filename The file name to compare with the tip in 
 *                 Mercurial.
 *
 * @return int - 0 for success.
 */
static int _HgDiffTwoVersions(_str filename, _str version1, _str version2)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the Merurial relative file name
   _str remote_filename = filename;
   _str version1ContentsFilename = mktemp();
   // run the cat command to get the version1 contents
   _str cmd = 'cat -r 'version1' -o 'maybe_quote_filename(version1ContentsFilename)' 'maybe_quote_filename(remote_filename);
   int status = _HgShell(cmd, repositoryRoot, 'Q', auto output, true);
   if (status) {
      _message_box('Mercurial returned 'status' retrieving version 'version1' for file 'filename'.');
      return status;
   }
   _str version2ContentsFilename = mktemp();

   // run the show command to get the version2 contents
   cmd = 'cat -r 'version2' -o 'maybe_quote_filename(version2ContentsFilename)' 'maybe_quote_filename(remote_filename);
   status = _HgShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Mercurial returned 'status' retrieving version 'version2' for file 'filename'.');
      return status;
   }

   // show the diff dialog
   status = _DiffModal('-r1 -r2 -nomapping -file1title "Version ('version1')" -file2title "Version ('version2')" 'maybe_quote_filename(version1ContentsFilename)' 'maybe_quote_filename(version2ContentsFilename), 'Mercurial');

   // clean up after ourselves
   delete_file(version1ContentsFilename);
   delete_file(version2ContentsFilename);

   return 0;
}

/**
 * The command entry point for executing a Mercurial commit command.
 * 
 * @param filename The file name to commit 
 * @param comment The comment included with the commit 
 * 
 * @return int - 0 for success
 */
_command int hg_commit(typeless filename='', _str comment=NULL_COMMENT) name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
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
      }
   }
   _str comment_filename=mktemp();
   if ( comment!=NULL_COMMENT ) {
      int temp_wid;
      int orig_wid=_create_temp_view(temp_wid);
      _insert_text(comment);
      status:=_save_config_file(comment_filename);
      p_window_id=orig_wid;
      _delete_temp_view(temp_wid);
   }else{
      status:=_CVSGetComment(comment_filename,auto tag,filename,false,false,false);
      if ( status ) {
         delete_file(comment_filename);
         return(status);
      }
   }
   rootPath := HgGetRootPath(filename);
   if ( rootPath=="" ) {
      _message_box(nls("Could not get root path for '%s'",filename));
   }
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   // run the commit command
   _str temp[];
   temp[0]=filenameNQ;
   int status=_HgCommit(temp,comment_filename,rootPath,auto outputFilename,true);
   if ( status==COMMIT_MERGE_PENDING ) {
      _message_box(nls("Mercurial could not complete this commit, there is a merge pending.\n\nCommit directories from Tools>Version Control>Compare Directory with Mercurial."));
   }
   return status;
}

_command int hg_update(typeless filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result = _ChooseDirDialog("",getcwd(),"");
         if ( result=='' ) return(COMMAND_CANCELLED_RC);
         filename=result;
      }
   }
   _str comment_filename=mktemp();
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   // run the commit command
   _str temp[];
   temp[0]=filenameNQ;
   int status=_HgUpdate(temp[0]);
   return status;
}

int _hg_update_revert_button()
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   refreshFileTree(filelist);

   return( _HgRevert(filelist) );
}

int _HgUpdateAllButton(_str path='')
{
   return _HgUpdate(path);
}

/**
 * Callback for "Diff" button on mercurial update dialog
 *
 * @return int
 */
int _hg_update_diff_button()
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

      boolean both_remote=false;
      _str version_to_compare=-1;
      _str remote_version,local_version;
      if ( bm1==_pic_file_old_mod ||
           bm1==_pic_cvs_file_conflict ) {

         status := _SVNGetRemoteInfo(filename,remote_version);
         if ( status ) {
            _message_box(nls("Could not get remote version number for '%s'",filename));
            return status;
         }

         status=_SVNGetAttributeFromCommand(filename,"Last Changed Rev",local_version);
         if ( status ) {
            local_version='Unknown';
         }
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
      int status=0;
      if ( both_remote ) {
         // SVNDiffPastVersions takes a remote filename.  To get this
         // we change to the file's directory, and use the relative
         // filename.  Changing FILESEP to '/' is just a precaution
         origdir := getcwd();
         path := _file_path(filename);
         chdir(path,1);
         remote_filename := relative(filename);
         remote_filename = stranslate(remote_filename,'/',FILESEP);
         status=HgDiffPastVersions(remote_filename,local_version,version_to_compare);
         chdir(origdir,1);
      } else {
         status=HgDiffWithVersion(filename,version_to_compare,false);
      }
      treewid._set_focus();
      p_window_id=treewid;
      if ( status ) return(status);
      int wid=p_window_id;
      p_window_id=ctltree1;
      int index=_TreeCurIndex();
      boolean deleted=false;
      if ( _file_date(filename,'B')!=orig_file_date ) {
         // If we are not commiting or updating the file, get the file's status
         // and reset the bitmap
         HG_STATUS_INFO info[];
         _str module_name='';
         _HgGetVerboseFileInfo(filename,info);
         if ( info!=null ) {
            int bitmap_index;
            _HgGetFileBitmap(info[0],bitmap_index);
            _TreeSetInfo(index,-1,bitmap_index,bitmap_index);
         } else {
            _TreeDelete(index);
            deleted=true;
         }
      }
      if ( def_cvs_flags&CVS_FIND_NEXT_AFTER_DIFF ) {
         boolean search_for_next=true;
         if ( deleted ) {
            int bmindex1;
            _TreeGetInfo(_TreeCurIndex(),state,bmindex1);
            search_for_next=(bmindex1==_pic_cvs_file||
                             bmindex1==_pic_cvs_file_qm||
                             bmindex1==_pic_file_old||
                             bmindex1==_pic_file_old_mod||
                             bmindex1==_pic_file_mod||
                             bmindex1==_pic_cvs_file_conflict);
         }
         index=_TreeGetNextIndex(_TreeCurIndex());
         for ( ;; ) {
            if ( index<0 ) break;
            int bmindex1,bmindex2;
            _TreeGetInfo(index,state,bmindex1,bmindex2);
            if ( bmindex1==_pic_cvs_file
                 || bmindex1==_pic_cvs_file_qm
                 || bmindex1==_pic_file_old
                 || bmindex1==_pic_file_old_mod
                 || bmindex1==_pic_file_mod
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

/**
 * Diffs two past versions of <b>remote_filename</b>
 *
 * @param remote_filename URL for file to compare
 * @param version1
 * @param version2
 *
 * @return int 0 if successful
 */
static int HgDiffPastVersions(_str remote_filename,_str version1,_str version2)
{
   version1=SVNGetVersionFromCaption(version1);
   version2=SVNGetVersionFromCaption(version2);
   _str OutputFilename1;
   int status=_SVNCheckoutFile(remote_filename,"",'-r 'version1,OutputFilename1);
   if ( status ) {
      // _SVNCheckoutFile would have given user an error message
      return(status);
   }
   _str OutputFilename2;
   status=_HgCheckoutFile(remote_filename,'-r 'version2,OutputFilename2);
   if ( status ) {
      // _SVNCheckoutFile would have given user an error message
      return(status);
   }

   int orig_view_id,fileViewID1,fileViewID2,junk_view_id;

   // Open the first remote file, call select edit mode with the file's extension
   lang := _Filename2LangId(remote_filename);
   status = _open_temp_view(OutputFilename1,fileViewID1,orig_view_id);
   if ( status ) return(status);
   _SetEditorLanguage(lang);

   // Open the second remote file, call select edit mode with the file's extension
   p_window_id = orig_view_id;
   status = _open_temp_view(OutputFilename2,fileViewID2,junk_view_id);
   if ( status ) return(status);
   _SetEditorLanguage(lang);

   p_window_id = orig_view_id;

   _str dispname1=remote_filename' (Version 'version1' - Remote)';
   _str dispname2=remote_filename' (Version 'version2' - Remote)';

   status=_DiffModal('-r1 -r2 -viewid1 -viewid2 -nomapping -file1title "'dispname1'" -file2title "'dispname2'" 'fileViewID1' 'fileViewID2);

   // Close the views
    _delete_temp_view(fileViewID1);
    _delete_temp_view(fileViewID2);

   // Delete the temporary files
   delete_file(OutputFilename1);
   delete_file(OutputFilename2);

   return(status);
}

static boolean isRepositoryRootDir(_str path,_str &repositoryRoot)
{
   _str local_path;
   parse ctllocal_path_label.p_caption with 'Local Path: ','i' local_path;

   if ( file_eq(path,local_path) ) {
      return true;
   }

   return false;
}

/**
 * Callback for "History" button on mercurial update dialog
 *
 * @return int
 */
int _hg_update_history_button()
{
   _str filename=_CVSGetFilenameFromUpdateTree();
   return( hg_history(filename,1) );
}

int _hg_update_commit_button()
{
   int wid=p_window_id;
   HG_STATUS_INFO Files[]=null;

   _str filelist[]=null;
   int indexlist[]=null;
   parse ctllocal_path_label.p_caption with 'Local Path: ','i' auto local_path;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist,-1,true);
   isRepositoryRoot := indexlist[0]==ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   int status=0;
   // Have to keep a copy of this because items can get deleted during the loop
   // and we need all of the filenames to be able to update the tree.
   _str whole_filelist[]=filelist;
   _str OutputFilename='';
   if ( filelist!=null) {
      status=_SVCListModified(filelist);
      if ( status ) {
         return(status);
      }
      boolean reuse_comment=false;
      boolean append_to_output=false;

      int len=filelist._length();
      _str temp_filename=mktemp();
      boolean apply_to_all=false;
      _str tag='';
      int i;
      STRARRAY dirList;
      for ( i=0;i<len;++i ) {
         if ( !reuse_comment ) {
            status=_CVSGetComment(temp_filename,tag,filelist[i],len>1,apply_to_all,false);
            if ( status ) {
               return(status);
            }
         }
         if ( last_char(filelist[i])==FILESEP )  {
            dirList[dirList._length()] = filelist[i];
         }
         if ( apply_to_all ) {
            status=_SVCCheckLocalFilesForConflicts(filelist);
            if ( status==IDCANCEL ) {
               return(COMMAND_CANCELLED_RC);
            } else if ( status ) {
               return(1);
            }
            result := IDYES;
            if ( dirList._length() ) {
               result = _message_box(nls("If you continue you will commit directories.\nThis will automatically commit the files and directories under that directory.\n\nContinue?"));
            }
            if ( result==IDYES ) {
               _HgCommit(filelist,temp_filename,local_path,OutputFilename,true,'',append_to_output);
            }
            break;
         } else {
            _str cur=filelist[i];

            _str tempfiles[]=null;
            tempfiles[0]=cur;
            if ( isRepositoryRoot ) {
               result := _message_box(nls("If you continue you will commit the repository root.  This will run \"hg commit\".\n\nContinue?"),'',MB_YESNO);
               if ( result==IDYES ) tempfiles = null;
            } else {
               status=_SVCCheckLocalFilesForConflicts(tempfiles);
            }
            if ( status==IDCANCEL ) {
               return(COMMAND_CANCELLED_RC);
            } else if ( status ) {
               // because we are using a different array(tempfiles), delete this item
               // from filelist so if the user uses "Apply to all" later, it is not
               // there.  This means that we also have to decrement i and len.  In this case,
               // remove indexlist[i] too because we do not want that index removed by
               // SVNRefreshTreeBitmaps below
               filelist._deleteel(i);
               indexlist._deleteel(i);
               --i;--len;
               continue;
            }
            status=_HgCommit(tempfiles,temp_filename,local_path,OutputFilename,true,'',append_to_output);
            if ( status ) return status;
            // because we are using a different array(tempfiles), delete this item
            // from filelist so if the user uses "Apply to all" later, it is not
            // there.  This means that we also have to decrement i and len
            filelist._deleteel(i);
            --i;--len;
         }
         append_to_output=true;
      }
      delete_file(temp_filename);
   }
   if ( OutputFilename!="" ) {
      _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form,false,false);
   }
   delete_file(OutputFilename);

   HgRefreshTreeBitmaps(indexlist,whole_filelist,Files);

   ctltree1._set_focus();
   _SVNEnableButtons();
   return(0);
}

static void HgRefreshTreeBitmaps(int (&indexlist)[],_str (&filelist)[],HG_STATUS_INFO (&Files)[])
{
   int fileIndexesToDelete[]=null;
   int folderIndexesToDelete[]=null;
   int i;
   int wid=p_window_id;
   for ( i=0;i<indexlist._length();++i ) {
      _str cur_filename_in_tree=_CVSGetFilenameFromUpdateTree( indexlist[i] );
      boolean found=false;
      int j;
      for ( j=0;j<Files._length();++j ) {
         if ( file_eq(cur_filename_in_tree,Files[j].local_filename) ) {
            found=true;break;
         }
      }
      p_window_id=wid;
      p_window_id=ctltree1;
      if ( found ) {
         int state,bm1;
         _HgGetFileBitmap(Files[j],bm1);
         _TreeGetInfo(indexlist[i],state);
         _TreeSetInfo(indexlist[i],state,bm1,bm1);
      } else {
         _TreeGetInfo(indexlist[i],auto state,auto bm1);
         // Have to keep track of folder and file nodes separately so we do not
         // delete child nodes twice (by deleting the folder first)
         if ( bm1==_pic_fldopen || bm1==_pic_cvs_fld_p || bm1==_pic_cvs_fld_mod ) {
            folderIndexesToDelete[folderIndexesToDelete._length()]=indexlist[i];
         }else{
            fileIndexesToDelete[fileIndexesToDelete._length()]=indexlist[i];
         }
      }
      p_window_id=wid;
   }
   // First delete file nodes
   for ( i=0;i<fileIndexesToDelete._length();++i ) {
      ctltree1._TreeDelete(fileIndexesToDelete[i]);
   }
   // Now delete folder nodes
   for ( i=0;i<folderIndexesToDelete._length();++i ) {
      ctltree1._TreeDelete(folderIndexesToDelete[i]);
   }
   _SVNEnableButtons();
}

/**
 * This function executes a Mercurial commit command.  We 
 * confirm that each file in the list to commit is in the Mercurial 
 * repository root.  We then make sure that we have a comment to 
 * apply to the operation.  Each file to commit must then be 
 * added to the commit set and then a single commit is executed.
 * 
 * @param filelist The list of files to be committed
 * @param comment The comment to be applied to the commit
 * 
 * @return int - 0 for success
 */
int _HgCommit(_str filelist[],_str comment,_str LocalPath,_str &OutputFilename,
               boolean comment_is_filename=false,_str commit_options='',
               boolean append_to_output=false)
{
//   parse ctllocal_path_label.p_caption with 'Local Path: ','i' auto local_path;
   pushd(LocalPath);

   for (i:=0;i<filelist._length();++i) {
      filelist[i] = relative(filelist[i]);
   }

   origComment := comment;
   OutputFilename = "";
   _str comment_info_str="";
   if ( comment_is_filename ) {
      comment_info_str="-l ":+maybe_quote_filename(comment);
   }else{
      comment_info_str="-m ":+maybe_quote_filename(comment);
   }
   len := filelist._length();
   filelist_filename := mktemp();

   status := 0;
   listfileStr := "";
   if ( filelist!=null ) {
      status = _SVNWriteListFile(filelist,filelist_filename,false);
      if ( status ) {
         _message_box(nls("Could not write list file '%s'",filelist_filename));
         popd();
         return status;
      }
      listfileStr = ' -Ilistfile:'filelist_filename;
   }
   cmd := "commit ":+ comment_info_str:+' ':+listfileStr;
   status = _HgShell(cmd,"",'q',auto output);
   len = output._length();
   for ( i=0;i<len;++i ) {
      if ( output[i]=="abort: cannot partially commit a merge (do not specify files or patterns)" ) {
         status = COMMIT_MERGE_PENDING;
      }
   }
   delete_file(filelist_filename);
   popd();
   return status;
}

static boolean hgCommandLineTooLongError(_str cmd, _str cap)
{
   threshold := 0;
#if __UNIX__
   threshold = 0x20000;
#elif __MACOSX__
   threshold = 0x18000;
#else
   // Windows
   threshold = 0x8000;
#endif 
   if ( length(threshold)>=threshold ) {
      _message_box(nls("This will build a command line that is too long for the operating system.\n\nYou could %s the entire directory",cap));
      return true;
   }
   return false;
}

/**
 * The command entry point for executing a Mercurial add command.
 * 
 * @param filename The file name to be added
 * 
 * @return int - 0 for success
 */
_command int hg_add(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
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
      }
   }
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   // run the add command
   _str temp[]=null;
   temp[0]=filenameNQ;
   int status = _HgAdd(temp);
   return status;
}

// http://www.kernel.org/pub/software/scm/git/docs/git-add.html
/**
 * This function executes a Mercurial add command.  We confirm that
 * each file in the list to commit is in the Mercurial repository 
 * root.  Each file to add must then be processed. 
 * 
 * @param filelist The list of files to be committed
 * 
 * @return int - 0 for success
 */
static int _HgAdd(_str filelist[])
{
   LocalPath := HgGetRootPath(filelist[0]);
   pushd(LocalPath);
   status := _SVNWriteListFile(filelist,auto fileListFilename);
   if ( status ) {
      _message_box("Could not write list file");
      popd();
      return status;
   }
   // run the add command
   _str cmd = 'add -Ilistfile:'fileListFilename;
   status = _HgShell(cmd, "", 'Q', auto output);
   popd();
   if (status) {
      _message_box('Mercurial returned 'status' adding filelist');
      return status;
   }
   return 0;
}

/**
 * The command entry point for executing a Mercurial rm command.
 * 
 * @param filename The file name to be removed
 * 
 * @return int - 0 for success
 */
_command int hg_remove(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
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
      }
   }
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filenameNQ));
      return(FILE_NOT_FOUND_RC);
   }
   // run the remove command
   _str temp[]=null;
   temp[0]=filenameNQ;
   int status = _HgRemove(temp);
   return status;
}

// http://www.kernel.org/pub/software/scm/git/docs/git-rm.html
/**
 * This function executes a Mercurial rm command.  We confirm that
 * each file in the list to remove is in the Mercurial repository 
 * root.  Each file to remove must then be processed. 
 * 
 * @param filelist The list of files to be committed
 * 
 * @return int - 0 for success
 */
static int _HgRemove(_str filelist[])
{
   // make sure that we have a list of files
   if (filelist._length() == 0) {
      return 0;
   }
   // first, find out if this file is addable in Mercurial and get the repository root for this file
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filelist[0], repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filelist[0]' cannot be reverted because it is not within a working tree.');
      return -1;
   }
   // warn the user about what they're about to do
   _str msg = 'Are you sure you want to remove ';
   if (filelist._length() == 1) {
      msg :+= "'"filelist[0]"'?";
   } else {
      msg :+= 'these 'filelist._length()' files?';
   }
   int result=_message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
   if (result != IDYES) {
      return 0;
   }
   // now that we have the repository root, we can do a simple check on all remaining files
   int i = 0;
   len := filelist._length();
   for (i = 0; i < len; i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot revert file '%s' because the file is open and modified.", filename));
         return -2;
      }
   }

   cmd := "remove ";
   for ( i=0;i<len;++i ) {
      if ( length(cmd)>320000 ) {
         _message_box("Too many files selected");
         return 0;
      }
      cmd:+=maybe_quote_filename(filelist[i])' ';
   }

   status := _HgShell(cmd,"",'q',auto output);

   // reload any buffers that may be affected
   _reload_vc_buffers(filelist);

   return 0;
}

/**
 * The command entry point for executing a Mercurial revert command.
 * 
 * @param filename The file name to be added
 * 
 * @return int - 0 for success
 */
_command int hg_revert(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to revert',// Dialog Box Title
                                 '',                   // Initial Wild Cards
                                 def_file_types,       // File Type List
                                 OFN_FILEMUSTEXIST,
                                 '',
                                 ''
                                 );
         if ( result=='' ) return(COMMAND_CANCELLED_RC);
         filename=result;
      }
   }
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   // run the revert command
   _str temp[]=null;
   temp[0]=filenameNQ;
   int status = _HgRevert(temp);
   return status;
}

// Mercurial uses the checkout command in the same way that SVN uses the revert command
// http://www.kernel.org/pub/software/scm/git/docs/git-checkout.html
/**
 * This function executes a Mercurial revert command.  We confirm that
 * each file in the list to commit is in the Mercurial repository 
 * root.  Each file to revert must then be processed. 
 * 
 * @param filelist The list of files to be reverted
 * 
 * @return int - 0 for success
 */
static int _HgRevert(_str filelist[])
{
   // make sure that we have a list of files
   if (filelist._length() == 0) {
      return 0;
   }
   // first, find out if this file is addable in Mercurial and get the repository root for this file
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filelist[0], repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filelist[0]' cannot be reverted because it is not within a working tree.');
      return -1;
   }
   // warn the user about what they're about to do
   _str msg = 'Are you sure you want to revert ';
   if (filelist._length() == 1) {
      msg :+= "'"filelist[0]"'?";
   } else {
      msg :+= 'these 'filelist._length()' files?';
   }
   int result=_message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
   if (result != IDYES) {
      return 0;
   }
   // now that we have the repository root, we can do a simple check on all remaining files
   int i = 0;
   len := filelist._length();
   for (i = 0; i < len; i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot revert file '%s' because the file is open and modified.", filename));
         return -2;
      }
   }

   cmd := "revert ";
   for ( i=0;i<len;++i ) {
      if ( length(cmd)>320000 ) {
         _message_box("Too many files selected");
         return 0;
      }
      cmd:+=maybe_quote_filename(filelist[i])' ';
   }

   status := _HgShell(cmd,"",'q',auto output);

   // reload any buffers that may be affected
   _reload_vc_buffers(filelist);

   return 0;
}

static void refreshFileTree(STRARRAY &filelist)
{
   _str local_path;
   parse ctllocal_path_label.p_caption with 'Local Path: ','i' local_path;
   HG_STATUS_INFO Files[];
   status := _HgGetVerboseFileInfo(local_path,Files);

   int wid=p_window_id;
   p_window_id=ctltree1;
   HgSetupTree(local_path,Files);

   // We just deleted and re-filled the tree.  We want to check and see if
   // there is anything that we just added that we can select.
   boolean selected=false;
   for ( i:=0;i<filelist._length();++i ) {
      int index=_TreeSearch(TREE_ROOT_INDEX,_strip_filename(filelist[i],'N'),'T'_fpos_case);
      if ( index>-1 ) {
         index=_TreeSearch(index,_strip_filename(filelist[i],'P'),_fpos_case);
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
}

_command int hg_history(_str filename='', boolean quiet=false, _str version=null) name_info(FILE_ARG'*,')
{
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to view history for',// Dialog Box Title
                                 '',                   // Initial Wild Cards
                                 def_file_types,       // File Type List
                                 OFN_FILEMUSTEXIST,
                                 '',
                                 ''
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
   _str hgRootPath = '';
   if ( !IsHgPath(filename, hgRootPath) ) {
      _message_box(nls("'%s' is was not checked out from Mercurial",filename));
      return(1);
   }

   int wid = show('-new -xy -hidden _cvs_history_form');
   wid._HgFillInHistory(filename);
   _control ctltree1;
   wid.ctltree1.call_event(CHANGE_SELECTED,wid.ctltree1._TreeCurIndex(),wid.ctltree1,ON_CHANGE,'W');
   wid.p_caption='Mercurial info for 'filename;
   wid.p_user = filename;
   wid.p_visible=true;
   wid.hg_history_add_menu();

   return(0);
}

#if 0 //9:53am 7/30/2012
#region _hg_mfupdate_form handlers
defeventtab _hg_mfupdate_form;

/**
 * Handles the rezigin of the dialog
 */
void _hg_mfupdate_form.on_resize()
{
   // hide the tree
   ctltree1.p_visible=ctl_close.p_visible=0;

   int xbuffer=ctltree1.p_x;
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);
   ctltree1.p_width=client_width-(2*xbuffer);
   ctlrep_label.p_x=ctltree1.p_x+(ctltree1.p_width intdiv 2);
   ctltree1.p_height=client_height-(ctltree1.p_y+ctl_close.p_height+(xbuffer*5));
   ctl_close.p_y=ctltree1.p_y+ctltree1.p_height+(xbuffer*2);
   ctl_hgremove.p_y = ctl_hgcommitall.p_y = ctl_hgcommit.p_y = ctl_hgrevert.p_y = ctl_close.p_y;
   // Shrink the path for the Repository if necessary
   repositoryList := _GetDialogInfoHt("CaptionRepository");
   if ( repositoryList!=null ) {
      parse ctlrep_label.p_caption with auto label ':' auto rest;
      labelWidth := ctlrep_label._text_width(label);
      wholeLabelWidth := (client_width - ctlrep_label.p_x) - labelWidth;
      wholeCaption := label':'ctlrep_label._ShrinkFilename(strip(repositoryList),wholeLabelWidth);
      ctlrep_label.p_caption = wholeCaption;
   }
   // now show the tree
   ctltree1.p_visible=ctl_close.p_visible=1;
}
#endif

/**
 * Get array of selected files in the tree.
 * 
 * @param selArray Array of files which will be populated by the 
 *                 function
 */
static void GetSelectedMFTreeFiles(_str (&selectedFiles)[])
{
   int selIndexes[];
   int firstSelectedIndex=-1;
   int nofselected;

   // get the selected indexes from the tree
   ctltree1._TreeGetSelectionIndices(selIndexes);

   if (!selIndexes._length()) {
      // If nothing is selected, use the current item
      selIndexes[0]=ctltree1._TreeCurIndex();
   }


   // clear out the array
   selectedFiles._makeempty();
   // now get the user info for those selected indexes (that's the relative file name)
   _str filename = '';
   int i;
   for (i = 0; i < selIndexes._length(); i++) {
      // only file names will have user info, which is their relative path to the root
      filename = ctltree1._TreeGetUserInfo(selIndexes[i]);
      if (filename != '') {
         selectedFiles[selectedFiles._length()] = filename;
      }
   }
}

/**
 * Get array of all files in the tree.
 * 
 * @param selArray Array of files which will be populated by the 
 *                 function.
 */
static void GetAllMFTreeFiles(_str (&allFiles)[])
{
   _str filename = '';

   // clear out the array
   allFiles._makeempty();
   // iterate through the tree indexes
   int index = ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   while (index >= 0) {
      // only file names will have user info, which is their relative path to the root
      filename = ctltree1._TreeGetUserInfo(index);
      if (filename != '') {
         allFiles[allFiles._length()] = filename;
      }
      index=ctltree1._TreeGetNextIndex(index);
   }
}

#if 0 //9:54am 7/30/2012
/**
 * Called when the selected index on the tree change so we can 
 * determine which buttons to enable or not. 
 */
void ctltree1.on_change(int reason,int index)
{
   if ( reason==CHANGE_SELECTED ) {
      _HGEnableButtons();
   }
}
#endif

/**
 * Determines which buttons are enabled or not based on the 
 * current tree selection. 
 */

void _HGEnableButtons()
{
   _EnableGUIUpdateButtons("hg");
}


/**
 * The command to show a dialog representing differences between 
 * the users local workspace and their local repository.  From 
 * that dialog, they can commit, revert or whatever they want to 
 * do. 
 * 
 * @param path The path to use when determining which repository 
 *             to show differences for in the dialog.
 * 
 * @return int - 0 for success
 */
_command int hg_update_directory,hg_gui_mfupdate(_str path='') name_info(FILE_ARG'*,')
{
   path = strip(path,'B','"');
   if ( path=='' ) {
      path=_HgGetPath();
      if ( path=='' ) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   _maybe_append_filesep(path);

   // handle the first argument (-r or -t)
   boolean recurse_option=false;
   _str tag_name='';
   for ( ;; ) {
      _str cur=parse_file(path);
      _str ch=substr(cur,1,1);
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
   // let's make sure that path is an actual Mercurial path
   _str repositoryRoot = '';
   boolean isHgPath = IsHgPath(path, repositoryRoot);
   if (isHgPath == false) {
      _message_box(path' is not a path that is managed by Mercurial.');
      return 0;
   }

   // get the url for the given path
   // get the list of modified, added or removed files in Mercurial
   HG_STATUS_INFO fileList[];
   int status = _HgGetVerboseFileInfo(repositoryRoot, fileList);
   if (status) {
      _str url = _HgGetUrlForLocalRepository(repositoryRoot);
      _message_box(nls("An error occurred getting difference information about repository '%s'.", url));
      return status;
   }
   if (fileList._length() == 0) {
      _str url = _HgGetUrlForLocalRepository(repositoryRoot);
      _message_box(nls("No pending changes to repository '%s' found.", url));
      return 0;
   }
   // populate and show the mfupdate dialog for Mercurial differences
   _HgGUIUpdateDialog(repositoryRoot, fileList);
   return 0;
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
static _str _HgGetPath(_str caption='Choose path')
{
   return(_CVSGetPath(caption,'_hg_path_form'));
}

/**
 * Shows the dialog that reports the status for the files in the
 * repository rooted at [rootPath]. 
 * 
 * @param rootPath The local root where a repository is checked 
 *                 out.
 * @param fileList The array of file statuses for files that 
 *                 have a difference with the repository.
 */
static void _HgGUIUpdateDialog(_str rootPath, HG_STATUS_INFO fileList[])
{
   _nocheck _control ctltree1;

   int wid = show('-xy -app -new _cvs_mfupdate_form');
   wid.p_active_form.p_caption='Mercurial Repository Status';
   wid.ctltree1.HgSetupTree(rootPath, fileList);
   wid._set_foreground_window();
}


static void prepopulateDirs(int rootIndex,_str wholePath,int (&pathsToAdd):[])
{
   for (i:=0;;++i) {
      if (i>100) {
         // Leave this safeguard in, if a directory format etc changes, this will save us from
         // having an infinite loop
         break;
      }
      parse wholePath with auto curPath (FILESEP) wholePath;
      if ( curPath=="" ) break;
      cap := _TreeGetCaption(rootIndex):+curPath:+FILESEP;
      curPath = cap;
      if ( pathsToAdd:[_file_case(cap)]==null ) {
         
         rootIndex = _TreeAddItem(rootIndex,  cap,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
         pathsToAdd:[_file_case(cap)] = rootIndex;
      } else {
         rootIndex = pathsToAdd:[_file_case(cap)];
      }
   }
}

/**
 * Populates the mfupdate tree with file statuses.
 * 
 * @param rootPath The local root where a repository is checked 
 *                 out.
 * @param fileList The array of file statuses for files that 
 *                 have a difference with the repository.
 */
static void HgSetupTree(_str rootPath, HG_STATUS_INFO fileList[])
{
   ctllocal_path_label.p_caption='Local Path: 'rootPath;
   ctlrep_label.p_caption='URL: '_HgGetUrlForLocalRepository(rootPath, true);
   _TreeDelete(TREE_ROOT_INDEX,'C');
   int PathIndexes1:[]=null;

   rootPath = stranslate(rootPath, FILESEP, '/');
   int newindex=_TreeAddItem(TREE_ROOT_INDEX,rootPath,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
   PathIndexes1:[_file_case(rootPath)] = newindex;

   // First pre-populate the tree with the paths we know we need
   int i;
   for ( i=0;i<fileList._length();++i ) {
      curPath := _file_path(fileList[i].local_filename);
      prepopulateDirs(newindex,curPath,PathIndexes1);
   }
   for ( i=0;i<fileList._length();++i ) {
      _str curFilename = stranslate(fileList[i].local_filename, FILESEP, '/');
      int parent_bitmap_index=_pic_fldopen;
      _str end_char=last_char(curFilename);
      typeless isdir=isdirectory(curFilename);

      curPath := rootPath:+_file_path(curFilename);
      int index1=_HgTreeGetPathIndex(newindex, curPath, rootPath, PathIndexes1, _pic_fldopen, _pic_cvs_fld_m);
      _HgGetFileBitmap(fileList[i],auto fileBitmap);
      if ( end_char!=FILESEP && !isdir ) {
         int newindex1=_TreeAddItem(index1,_strip_filename(curFilename,'P'),TREE_ADD_AS_CHILD,fileBitmap,fileBitmap,-1);
         _str fullPath = rootPath :+ curFilename;
         _TreeSetUserInfo(newindex1, fullPath);
      }
   }
   ctltree1._TreeSortTree();
   _HGEnableButtons();
}

int _hg_update_add_button()
{
   _str filelist[]=null;
   int indexlist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist,_pic_cvs_fld_qm);

   _str dirs[]=null;
   _str filenames[]=null;
   int i;
   for ( i=0;i<filelist._length();++i ) {
      _str cur=filelist[i];
      if ( last_char(cur)==FILESEP ) {
         dirs[dirs._length()]=cur;
      } else {
         filenames[filenames._length()]=cur;
      }
   }

   HG_STATUS_INFO Files[]=null;
   int status=0;

   _param1='';
   _str result = show('-modal _textbox_form',
                      'Options for ':+VCSYSTEM_TITLE_SUBVERSION:+' Add ', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'svn add', //Retrieve Name
                      'Add options:'
                     );

   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str add_options=_param1;

   if ( dirs._length() ) {
      status=HGAddSelectedFiles(dirs,&Files,add_options);
      if ( status ) return(status);
   }

   if ( filenames._length() ) {
      status=HGAddSelectedFiles(filenames,&Files,add_options);
      if ( status ) return(status);
   }

   _str local_path;
   parse ctllocal_path_label.p_caption with 'Local Path: ','i' local_path;

   refreshFileTree(filelist);
   return(status);
}
/**
 * Get the bitmap to show in the GUI update dialog for <b>File</b>
 * @param File File to get bitmap for
 * @param bitmap1 bitmap index is returned here
 * @param default_bitmap bitmap to use if we somehow get through all of the
 *        conditions in this funciton and never set one.
 * @param DoubleCheckConflict_NOTUSED Just here to match params in _CVS version
 *        of this function
 */
static void _HgGetFileBitmap(HG_STATUS_INFO &File,int &bitmap1,int default_bitmap=_pic_cvs_file)
{
   bitmap1=default_bitmap;
   if ( File.file_state==HG_STATUS_NOT_CONTROLED ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_qm;
      } else {
         bitmap1=_pic_cvs_file_qm;
      }
      return;
   }
   if ( File.file_state==HG_STATUS_MODIFIED ) {
      bitmap1=_pic_file_mod;
      return;
   }
   if ( File.file_state==HG_STATUS_MISSING ) {
      bitmap1=_pic_file_del;
      return;
   }
   if ( File.file_state==HG_STATUS_DELETED ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_m;
      }else{
         bitmap1=_pic_cvs_filem_mod;
      }
      return;
   }
   if ( File.file_state==HG_STATUS_NEW ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_p;
      }else{
         bitmap1=_pic_cvs_filep;
      }
      return;
   }
}


/**
 * Adds the selected files to Subvesrion
 * @param filelist List of files to add
 * @param pFiles Resulting file info from Mercurial (status 
 *               command run after add command if this param is
 *               not 0)
 * @param add_options options to pass to SVNBuildAddCommand
 *
 * @return int 0 if successful
 */
static int HGAddSelectedFiles(_str (&filelist)[],
                               HG_STATUS_INFO (*pFiles)[]=null,
                               _str add_options='')
{
   _str OutputFilename='';

   boolean updated_new_dir=false;
   int status=_HgAdd(filelist);

   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   delete_file(OutputFilename);

   return(status);
}

/**
 * Returns an index to a tree node based on the passed file name 
 * in [Path]. 
 * 
 * @param rootIndex The index of the root node in the tree.
 * @param Path The path to get the tree node index for
 * 
 * @return int - The index of the node for [Path].
 */
static int _HgTreeGetPathIndex(int rootIndex,_str Path,_str BasePath,int (&PathTable):[], int ExistFolderIndex=_pic_fldopen, int NoExistFolderIndex=_pic_cvs_fld_m, _str OurFilesep=FILESEP, int state=1)
{
   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   int Othercount=0;

   Path=strip(Path,'B','"');
   BasePath=strip(BasePath,'B','"');
   if (PathTable._indexin(_file_case(Path))) {
      return(PathTable:[_file_case(Path)]);
   }
   int Parent=rootIndex;
   for (;;) {
      if (Path=='') {
         break;
      }
      PathsToAdd[count++]=Path;
      Path=substr(Path,1,length(Path)-1);
      _str tPath=_strip_filename(Path,'N');
      if (file_eq(Path:+OurFilesep,BasePath) || file_eq(tPath,Path)) 
         break;
      if (isunc_root(Path)) 
         break;
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
      _str fullPath = BasePath :+ PathsToAdd[i];
      if (isdirectory(fullPath)) {
         bmindex=ExistFolderIndex;
      }else{
         bmindex=NoExistFolderIndex;
      }
      Parent=_TreeAddItem(Parent, _TreeGetCaption(Parent):+PathsToAdd[i], TREE_ADD_AS_CHILD, bmindex, bmindex, state);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

/**
 * Determines if a path, or a file's path, belongs to a Mercurial 
 * repository.  It does this by looking to see if a .git 
 * directory exists under filename's directory, and if not, then
 * it looks up the folder's parents to the root. 
 *
 * @param path The path or filename to check 
 * @param hgRootPath The root path where the Mercurial repository is 
 *                    checked out to.
 *
 * @return true if file is a Mercurial path or file.
 */
static boolean IsHgPath(_str path, _str& hgRootPath)
{
   hgRootPath = '';
   // get the path from the file name passed in
   path=absolute(path);
   if ( !isdirectory(path) ) {
      path=_strip_filename(path,'N');
   }
   _maybe_append_filesep(path);

   // determine if a "[x]/.git" folder exists.  If it does, then this is a Mercurial file.
   boolean isRootFolder = (isdirectory(path) != 0);
   _str HgPath = '';
   boolean HgPathExists = false;
   _HgShell('root',path,'Q',auto output,true);
   len := output._length();
   for ( i:=0;i<len;++i ) {
      if ( output[i]!="" ) {
         hgRootPath = output[i];
         break;
      }
   }
   _maybe_append_filesep(hgRootPath);
   HgPath = hgRootPath:+'.hg';
   HgPathExists = (isdirectory(HgPath) != 0);

   return HgPathExists;
}

static _str HgGetRootPath(_str path)
{
   hgRootPath := '';
   // get the path from the file name passed in
   path=absolute(path);
   if ( !isdirectory(path) ) {
      path=_strip_filename(path,'N');
   }
   _maybe_append_filesep(path);

   // determine if a "[x]/.git" folder exists.  If it does, then this is a Mercurial file.
   boolean isRootFolder = (isdirectory(path) != 0);
   _str HgPath = '';
   _HgShell('root',path,'Q',auto output,true);
   len := output._length();
   for ( i:=0;i<len;++i ) {
      if ( output[i]!="" ) {
         hgRootPath = output[i];
         break;
      }
   }
   _maybe_append_filesep(hgRootPath);
   return hgRootPath;
}

// returns the URL for the remote repository managed by this local workspace
// NOTE: The current working directory MUST be in the Mercurial repository path
/**
 * Returns the URL for the remote repository managed by this local workspace.
 * 
 * @param repositoryRoot The local root folder where the repository is checked out.
 * 
 * @return _str The url for the remote repository.
 */
_str _HgGetUrlForLocalRepository(_str repositoryRoot, boolean quiet = false)
{
   repositoryUrl := "";
   status := _HgShell("paths",repositoryRoot,'q',auto output,true);
   len := output._length();
   for ( i:=0;i<len;++i ) {
      if ( substr(output[i],1,10)=="default = " ) {
         repositoryUrl = substr(output[i],10);break;
      }
   }

   return repositoryUrl;
}

/**
 * Retrieves the name of the remote repository from the config file.
 * 
 * @param repositoryRoot 
 * 
 * @return _str 
 */
static _str _HgGetNameForRemoteRepository(_str repositoryRoot)
{
   _str repositoryName = '';
   int tempWid, origWid;

   // get the config file
   configFile := _HgGetConfigFile(repositoryRoot);

   if (file_exists(configFile)) {
      // open it up and take a peek
      _open_temp_view(configFile, tempWid, origWid);
      if (tempWid > 0) {
         top();
         
         // look for the section that deals with remote stuff
         if (!search('[remote ')) {

            // the rest of that line should contain the name
            get_line(auto line);
            parse line with . '"' repositoryName '"' .;
         } 
      }

   }

   if (tempWid) {
      _delete_temp_view(tempWid);
      p_window_id = origWid;
   }

   return repositoryName;
}

/**
 * Returns the path to the Mercurial config file for this repository.
 * 
 * @param repositoryRoot 
 * 
 * @return _str 
 */
static _str _HgGetConfigFile(_str repositoryRoot)
{
   status := _HgShell('root',repositoryRoot,'Q',auto output);
   root := "";
   if ( !status ) {
      len := output._length();
      for ( i:=0;i<len;++i ) {
         if ( output[i]!="" ) {
            root = output[i];
            _maybe_append_filesep(root);
            root :+= '.hg':+FILESEP:+'hgrc';
            break;
         }
      }
   }
   return root;
}

/**
 * Converts the '/cygdrive/' prefix on cygwin paths to an actual 
 * volume label. This is required if the Mercurial repository in on a 
 * local drive. 
 * 
 * @param url A repository URL to convert
 * 
 * @return _str - Returns the converted URL 
 */
static _str _ConvertCygwinPrefix(_str url) {
   _str retVal = url;
   _str prefixMatch = substr(url, 1, length(HG_CYGWIN_PREFIX));
   if (strieq(prefixMatch, HG_CYGWIN_PREFIX) == true) {
      // we've got to tweak the url to a Windows friendly name
      // first, remove the /cygwin/ part
      url = substr(url, length(HG_CYGWIN_PREFIX) + 1);
      // split this into an array
      _str pathParts[] = split2array(url, '/');
      pathParts[0] = pathParts[0]':';
      retVal = join(pathParts, '\');
   }
   return retVal;
}

/**
 * Runs the log command for a file and determines that file's 
 * Mercurial status. 
 * 
 * @param filename The name of the file to get info for
 * @param logInfo The structure to populate with log info
 * 
 * @return int - 0 for success
 */
static int _HgGetLogInfoForFile(_str filename, HG_LOG_INFO &logInfo)
{
   // make sure the file is Mercurial controlled
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filename' is not within a working tree.');
      return -1;
   }
   // now remove that prefix...
   filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   filename = stranslate(filename, '/', '\');

   // create a temp file to write the log to
   _str cmd = "log --style=xml "maybe_quote_filename(filename);
   _str output[];
   logOutputTempWID := -1;
   int status=_HgShell(cmd, repositoryRoot, 'Q', output, false, logOutputTempWID);
   if (status) {
      _message_box(nls("Mercurial log returned %s for file '%s'", status, filename));
      return status;
   }

   InitHgLogInfo(logInfo);
   // parse the output
   GetHgLogInfo(logOutputTempWID, logInfo);
   _delete_temp_view(logOutputTempWID);

   return status;
}

static int _HgGetCurrentVersionForFile(_str filename, _str &version)
{
   version = 0;
   // make sure the file is Mercurial controlled
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
#if 0 //11:29am 8/7/2012
   if (isHgFile == false) {
      _message_box('The file 'filename' is not within a working tree.');
      return -1;
   }
   // now remove that prefix...
   filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   filename = stranslate(filename, '/', '\');
#endif

   // create a temp file to write the log to
   _str cmd = "log --style=xml "maybe_quote_filename(filename);
   _str output[];
   logOutputTempWID := -1;
   int status=_HgShell(cmd, repositoryRoot, 'Q', output, true, logOutputTempWID);
   if (status) {
      _message_box(nls("Mercurial log returned %s for file '%s'", status, filename));
      return status;
   }

   // parse the output
   xmlHandle := _xmlcfg_open_from_buffer(logOutputTempWID,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( status!=0 || xmlHandle<0 ) {
      _message_box("Could not open xml output");
      return status;
   }

   status = _xmlcfg_find_simple_array(xmlHandle,"/log/logentry",auto handleArray);
   if ( status ) {
      _message_box("Could not parse xml output");
      return status;
   }
   len := handleArray._length();
   if ( len ) {
      HG_VERSION_INFO curInfo;
      InitVersionInfo(curInfo);
      version = _xmlcfg_get_attribute(xmlHandle,(int)handleArray[0],"revision");
   }

   _xmlcfg_close(xmlHandle);
   _delete_temp_view(logOutputTempWID);

   return status;
}

/**
 * Initializes a HG_LOG_INFO struct.
 * 
 * @param info The struct to initialize.
 */
static void InitHgLogInfo(HG_LOG_INFO &info)
{
   info.WorkingFile = '';
   info.Head = '';
   info.CurBranch = '';
   info.LocalVersion = '';
   info.State = HG_STATUS_UNCHANGED;
   info.VersionList._makeempty();
}

static void getChildItemList(int xmlHandle,int xmlIndex,_str xpath,STRARRAY &value,_str attribute="")
{
   _xmlcfg_find_simple_array(xmlHandle,xpath,auto handleArray,xmlIndex);

   len := handleArray._length();
   for ( i:=0;i<len;++i ) {
      if ( attribute!="" ) {
         value[value._length()] = _xmlcfg_get_attribute(xmlHandle,(int)handleArray[i],attribute);
      } else {
         PCDataIndex := _xmlcfg_get_first_child(xmlHandle,(int)handleArray[i]);
         if ( PCDataIndex>=0 ) {
            value[value._length()] = _xmlcfg_get_value(xmlHandle,PCDataIndex);
         }
      }
   }
}

static void getChildItem(int xmlHandle,int xmlIndex,_str name,_str &value)
{
   value = "";
   parentIndex := _xmlcfg_find_child_with_name(xmlHandle,xmlIndex,name);
   if ( parentIndex>=0 ) {
      PCDataIndex := _xmlcfg_get_first_child(xmlHandle,parentIndex);
      if ( PCDataIndex>=0 ) {
         value = _xmlcfg_get_value(xmlHandle,PCDataIndex);
      }
   }
}

/**
 * Parses the log info in the specified output file in 
 * [filename]. 
 * 
 * @param filename The output file from running 'git log'
 * @param info The structure to populate with Mercurial log info.
 */
static void GetHgLogInfo(int logInfoWID, HG_LOG_INFO &info)
{
   xmlHandle := _xmlcfg_open_from_buffer(logInfoWID,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( status!=0 || xmlHandle<0 ) {
      _message_box("Could not open xml output");
      return;
   }
   status = _xmlcfg_find_simple_array(xmlHandle,"/log/logentry",auto handleArray);
   if ( status ) {
      _message_box("Could not parse xml output");
      return;
   }
   len := handleArray._length();
   HG_VERSION_INFO flatVersionList[];
   for ( i:=0;i<len;++i ) {
      HG_VERSION_INFO curInfo;
      InitVersionInfo(curInfo);
      curInfo.RevisionNumber = _xmlcfg_get_attribute(xmlHandle,(int)handleArray[i],"revision");
      curInfo.Node = _xmlcfg_get_attribute(xmlHandle,(int)handleArray[i],"node");

      getChildItem(xmlHandle,(int)handleArray[i],"author",curInfo.Author);
      getChildItem(xmlHandle,(int)handleArray[i],"date",curInfo.Date);
      getChildItem(xmlHandle,(int)handleArray[i],"msg",curInfo.Subject);
      getChildItem(xmlHandle,(int)handleArray[i],"tag",curInfo.Tag);
      getChildItemList(xmlHandle,(int)handleArray[i],"parent",curInfo.ParentRevisions,"revision");

      flatVersionList[flatVersionList._length()] = curInfo;
   }
   info.VersionList = flatVersionList;
}

/**
 * Determines the current branch the local repository is on.
 * 
 * @param rootPath The root path where the repository is checked 
 *                 out to
 * 
 * @return _str The name of the branch.
 */
static _str _HgGetCurrentBranch(_str rootPath)
{
   _str curBranch = "";

   _HgShell("branch",rootPath,'q',auto output);
   len := output._length();
   for ( i:=0;i<len;++i ) {
      if ( output[i]!="" ) {
         curBranch = output[i];
         break;
      }
   }

   return curBranch;
}

/**
 * CD's to the directory specified, and runs the necessary
 * command, then restores the previous directory.
 *
 * On UNIX, Mercurial will not accept an absolute path, so you have
 * to cd to a relative directory to run a command.
 *
 * Also, turns on mou_hour_glass while running.
 *
 * @param command    command to shell (do not include Mercurial in the 
 *                   command, just what comes after)
 * @param FileOrPath Directory to cd to, or absolute filename to cd to directory of
 * @param shell_options
 *                   Options for shell builtin
 * @param debug      if 1, a debug line will be output with the actual line
 *                   shelled out, and current directory
 *
 * @return status from shell builtin
 */
static int _HgShell(_str command,_str path,_str shell_options,_str (&output)[], boolean suppressOutput=false,int &outputTempWID=0,
                    boolean debug=false)
{
   int pid = 0;
   int status = 0;
   output._makeempty();

   // change to the repository directory
   _str cwd = getcwd();
   chdir(path,1);

   // create a temp file to capture the output
   _str outputFilename = mktemp(1, '.sltmp');
   // set up the command to output the result
   _str commandWithoutOutput = maybe_quote_filename(_HgGetExeName())' 'command;
   _str commandWithOutput = commandWithoutOutput' > 'maybe_quote_filename(outputFilename)' 2>&1'; 
   int focus_wid=_get_focus();
   int current_wid=p_window_id;
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
   // shell the command
   status=shell(commandWithOutput,shell_options'P',alternate_shell,pid);
   if ( debug ) {
      say('::_HgShell status='status' commandWithOutput='commandWithOutput);
   }
   // read the output
   _HgReadOutputFile(outputFilename, output, &outputTempWID);
   // maybe write the command that was run
   if ((status != 0) || (def_hg_output_all == true)) {
      // output the command
      // maybe write the output results
      if (suppressOutput == false) {
         SVCWriteArrayToOutputWindow(output);
      }
      SVCWriteToOutputWindow('');
   }
   if ( !suppressOutput ) {
      activateOutputWindow();
   }

   // restore the focus
   if ( focus_wid && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
   p_window_id=current_wid;

   // change back to the previous current directory
   if ( path!='' ) {
      chdir(cwd,1);
   }

   return status;
}

/**
 * Reads the specified output file into an array of strings and 
 * then deletes the output file. 
 */
static void _HgReadOutputFile(_str outputFilename, _str (&output)[],int *pOutputTempWID=null)
{
   int origWid = 0;
   int tempWid = 0;
   _str line = '';
   // initialize output
   output._makeempty();
   // make sure the file exists
   if (file_exists(outputFilename) == false) {
      return;
   }
   // open the output file in a temp buffer
   _open_temp_view(outputFilename, tempWid, origWid);
   p_window_id = tempWid;
   top();
   int retVal = 0;
   while (retVal != BOTTOM_OF_FILE_RC) {
      get_line(line);
      if (_UTF8()) line = _UTF8ToMultiByte(line);
      output[output._length()] = line;
      retVal = down();
   }
   // clean up after ourselves
   if ( pOutputTempWID ) {
      if ( *pOutputTempWID<=0 ) {
         _create_temp_view(*pOutputTempWID);
      }

      p_window_id = tempWid;
      markid := _alloc_selection();
      top();
      _select_line(markid);
      bottom();
      _select_line(markid);
      if ( rc!=TEXT_NOT_SELECTED_RC ) {
         p_window_id=*pOutputTempWID;
         _copy_to_cursor(markid);
         _free_selection(markid);
      }
      p_window_id = tempWid;
   }
   _delete_temp_view(tempWid);
   p_window_id = origWid;
   delete_file(outputFilename);
}

/**
 * Writes the passed array of strings to a file.  If the file is 
 * blank, then a temp file name is created. 
 * 
 * @param output The strings to be written to the file
 * @param outputFilename The file name to write to.  A temp file 
 *                       name is created if it's blank.
 */
static void _HgWriteOutputFile(_str output[], _str &outputFilename)
{
   // create a temp buffer
   int tempWid = 0;
   int origWid = _create_temp_view(tempWid);
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      tempWid.insert_line(output[i]);
      tempWid.bottom();
   }
   // initialize output file name
   if (outputFilename == '') {
      outputFilename = mktemp();
   }
   // save the buffer
   tempWid._save_file(maybe_quote_filename(outputFilename));
   // clean up after ourselves
   _delete_temp_view(tempWid);
   p_window_id = origWid; 
}

/**
 * Sets the flag to cancel an async function
 */
static void SetHgCancel(boolean newval)
{
   gHgCancel=newval;
}

/**
 * Gets the flag that can cancel an async function.
 */
static boolean GetHgCancel()
{
   return(gHgCancel);
}

/**
 * Returns an array of HG_FILE_STATUS objects which represent 
 * the differences between the local workspace and the local 
 * repository. 
 * 
 * @param fileList The array of diff info objects to populate
 * 
 * @return int - 0 for success
 */
static int _HgGetFileStatus(_str filename, HG_FILE_STATE &fileStatus)
{
   // initialize the status struct
   InitHgFileStatus(fileStatus);
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the Mercurial relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');

   // run the status command
   _str cmd = 'status 'maybe_quote_filename(remote_filename);
   _str output[];
   int status=_HgShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      return status;
   }
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      // if we found an action to be taken with this line, then break
      if ( output[i]!="" ) {
         fileStatus = _HgGetStatusFlagsFromLine(output[i]);
      }
   }
   return 0;
}

static int _HgGetStatusFlagsFromLine(_str line,_str &filename="")
{
   HG_FILE_STATE state = HG_STATUS_UNCHANGED;
   switch ( substr(line,1,1) ) {
   case 'M':
      state=HG_STATUS_MODIFIED;break;
   case 'A':
      state=HG_STATUS_NEW;break;
   case 'R':
      state=HG_STATUS_DELETED;break;
   case 'C':
      state=HG_STATUS_CLEAN;break;
   case '!':
      state=HG_STATUS_MISSING;break;
   case '?':
      state=HG_STATUS_NOT_CONTROLED;break;
   case 'I':
      state=HG_STATUS_IGNORED;break;
   }
   filename = substr(line,3);
   return(state);
}

/**
 * Returns an array of HG_FILE_STATUS objects which represent 
 * the differences between the local workspace and the local 
 * repository. 
 * 
 * @param fileList The array of diff info objects to populate
 * 
 * @return int - 0 for success
 */
static int _HgGetVerboseFileInfo(_str repositoryRoot, HG_STATUS_INFO (&fileList)[])
{
   fileList._makeempty();

   // run the status command
   _str cmd = 'status 'maybe_quote_filename(repositoryRoot);
   _str output[];
   int status=_HgShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      return status;
   }
   // parse the output
   _str line = '';
   _str temp = '';
   int retVal = 0;
   int i = 0;
   boolean actionFound = false;
   for (i = 0; i < output._length(); i++) {
      // if we found an action to be taken with this line, then add it to the files
      HG_FILE_STATE fileStatus= _HgGetStatusFlagsFromLine(output[i],auto filename);
      if ( fileStatus!=0 ) {
         len := fileList._length();
         fileList[len].local_filename = filename;
         fileList[len].file_state = fileStatus;
      }
   }
   return 0;
}

static boolean HgParseFileStatus(_str line, HG_FILE_STATUS &fileStatus)
{
   boolean actionFound = false;
   _str temp = '';
   // does it contain an indicator that this line is a new file being added?
   int tokenPos = pos('new file:', line, 1, 'I');
   if (tokenPos != 0) {
      // we have a new file here
      temp = substr(line, tokenPos + 9);
      fileStatus.filename = strip(temp);
      fileStatus.state = HG_STATUS_NEW;
      // flag that we've done something with this line
      actionFound = true;
   }
   if (actionFound == false) {
      // does it contain an indicator that this line is a deleted file?
      tokenPos = pos('deleted:', line, 1, 'I');
      if (tokenPos != 0) {
         // we have a modified file here
         InitHgFileStatus(fileStatus.state);
         temp = substr(line, tokenPos + 9);
         fileStatus.filename = strip(temp);
         fileStatus.state = HG_STATUS_DELETED;
         // flag that we've done something with this line
         actionFound = true;
      }
   }
   if (actionFound == false) {
      // does it contain an indicator that this line is a modified file?
      tokenPos = pos('modified:', line, 1, 'I');
      if (tokenPos != 0) {
         // we have a modified file here
         InitHgFileStatus(fileStatus.state);
         temp = substr(line, tokenPos + 9);
         fileStatus.filename = strip(temp);
         fileStatus.state = HG_STATUS_MODIFIED;
         // flag that we've done something with this line
         actionFound = true;
      }
   }
   return actionFound;
}

/**
 * Initializes a HG_FILE_STATUS struct.
 * 
 * @param fileStatus The struct to initialize
 */
void InitHgFileStatus(HG_FILE_STATE &fileStatus)
{
   fileStatus = HG_STATUS_UNCHANGED;
}

static _str HgFileStateToString(HG_FILE_STATE state)
{
   _str retVal = 'Unknown';
   switch (state) {
   case HG_STATUS_UNCHANGED:
      retVal = 'Unchanged';
      break;
   case HG_STATUS_NEW:
      retVal = 'New';
      break;
   case HG_STATUS_MODIFIED:
      retVal = 'Modified';
      break;
   case HG_STATUS_DELETED:
      retVal = 'Deleted';
      break;
   }
   return retVal;
}

defeventtab _cvs_history_form;

/**
 * Callback for "View" button on Mercurial history dialog
 * @return 0 if successful
 */
int _hg_history_view_button()
{
   int formWid = p_parent;
   _str filename = formWid.p_user;

   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filename' cannot be viewed because it is not within a working tree.');
      return -1;
   }
   // get the Mercurial relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');

   _nocheck _control ctltree1;
   int wid = p_window_id;
   p_window_id = ctltree1;
   int version_index = _CVSGetVersionIndex(_TreeCurIndex());
   version := getRevisionNumber(version_index);
   p_window_id = wid;

   // run the add command first to include all of the files in the commit set
   _str output[];
   _str cmd = 'show 'version':'maybe_quote_filename(remote_filename);
   int status = _HgShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Mercurial returned 'status' retrieving the tip for file 'filename'.');
      return status;
   }
   _str outputFilename = mktemp() :+ _get_extension(remote_filename, true);
   // write the output to a file
   _HgWriteOutputFile(output, outputFilename);

   int temp_view_id, orig_view_id;
   status=_open_temp_view(outputFilename, temp_view_id, orig_view_id);
   if (status) {
      _message_box(nls("Could not open local version of %s", remote_filename));
      return status;
   }
   _str ext = _get_extension(remote_filename);
   langid := _Ext2LangId(ext);
   if (langid == '') {
      langid = _Ext2LangId(lowcase(ext));
   }
   _SetEditorLanguage(langid);
   // Tweek the buffer name so that if the user click save they get a "save as" dialog
   p_buf_name = _strip_filename(remote_filename, 'P');
   p_window_id = orig_view_id;

   // This is what shows the file, it is not debug, do not comment it out
   _showbuf(temp_view_id.p_buf_id,true,'-new -modal',remote_filename' (Version 'version')','S',true);
   _delete_temp_view(temp_view_id);
   delete_file(outputFilename);
   return status; 
}

/**
 * Adds the menu to the history dialog
 */
static void hg_history_add_menu()
{
   int index=find_index("_hg_history_menu",oi2type(OI_MENU));
   if ( index ) {
      int b4height=p_client_height;
      int menu_handle=p_active_form._menu_load(index);
      p_active_form._menu_set(menu_handle);
   }
}

/**
 * Populates the version history tree with info about the 
 * specified file name. 
 * 
 * @param filename The file to show history for.
 */
static int _HgFillInHistory(_str filename)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isHgFile = IsHgPath(filename, repositoryRoot);
   if (isHgFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the mercurial relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');

   HG_LOG_INFO logInfo;
   int status=_HgGetLogInfoForFile(filename, logInfo);
   if ( status ) {
      _message_box(nls("This file may not exist in the repository"));
      return -2;
   }
   HG_FILE_STATE fileState;
   _HgGetFileStatus(filename, fileState);
   logInfo.WorkingFile = filename;
   logInfo.Head = '';
   logInfo.CurBranch = _HgGetCurrentBranch(repositoryRoot);
   logInfo.State = fileState;
   _str remoteRepository = _HgGetUrlForLocalRepository(repositoryRoot, true);
   _str line[]=null;
   line[line._length()]='<B>Filename:</B> 'logInfo.WorkingFile;
   line[line._length()]='<B>Branch:</B> 'logInfo.CurBranch;
   line[line._length()]='<B>Repository:</B> 'remoteRepository;
   if (fileState != HG_STATUS_UNCHANGED) {
      line[line._length()]='<B>Status:</B> <FONT color="red">'HgFileStateToString(fileState)'</FONT>';
   } else {
      line[line._length()]='<B>Status:</B> 'HgFileStateToString(fileState);
   } 
   ctlrefresh.p_visible=false;
   ctlupdate.p_visible=false;
   ctlrevert.p_visible=false;
   ctlview.p_x=ctlrefresh.p_x;
    
   int wid=p_window_id;
   p_active_form.p_caption = 'Mercurial history for 'filename;
   _control ctlminihtml1;
   p_window_id=ctlminihtml1;
   p_backcolor=0x80000022;
   ctlminihtml2.p_backcolor=0x80000022;

   _control ctltree1;
   p_window_id=ctltree1;
   _str branch_captions[]=null;
   int InitialIndex=-1;
   _str branches_used:[]=null;
   int i, lastInsertedIndex=0;
   for ( i = 0; i < logInfo.VersionList._length(); ++i ) {
      if ( logInfo.VersionList[i].Author==null || logInfo.VersionList[i].Author == "") {
         continue;
      }
      caption := "";
      if ( logInfo.VersionList[i].Tag=="" ) {
         caption = logInfo.VersionList[i].RevisionNumber;
      } else {
         caption = logInfo.VersionList[i].RevisionNumber' - 'logInfo.VersionList[i].Tag;
      }
      int index=_TreeAddItem(TREE_ROOT_INDEX,caption,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
      lastInsertedIndex=index;
      if (logInfo.VersionList[i].RevisionNumber :== logInfo.LocalVersion) {
         int state,bm1,bm2,flags;
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
         InitialIndex=index;
      }
      SetVersionInfo(index,logInfo.VersionList[i]);
   }
   p_window_id=ctlminihtml1;
   p_text=line[0];
   for ( i=1;i<line._length();++i ) {
      p_text=p_text'<br>'line[i];
   }
   p_window_id=wid;

   return 0;
}

static _str getRevisionNumber(int index)
{
   info := _TreeGetUserInfo(index);
   parse info with "Revision:</B>" auto rev '<br>';

   return strip(rev);
}

static void SetVersionInfo(int index, HG_VERSION_INFO versionInfo)
{
   _str line = '';
   line = '<B>Author:</B> 'versionInfo.Author'<br>';
   if (versionInfo.Committer != '' && versionInfo.Author != versionInfo.Committer) {
      line :+= '<B>Committer:</B> 'versionInfo.Committer'<br>';
   }
   line :+= '<B>Date:</B> 'versionInfo.Date'<br>';
   line :+= '<B>Revision:</B> ' :+ versionInfo.RevisionNumber'<br>';
   line :+= '<B>Node:</B> ' :+ versionInfo.Node'<br>';

   numParents := versionInfo.ParentRevisions._length();
   if ( numParents==1 ) {
      line :+= '<B>Parent:</B> ' :+ versionInfo.ParentRevisions[0]'<br>';
   } else if ( numParents>0 ) {
      line :+= '<B>Parents:</B> ';
      len := versionInfo.ParentRevisions._length();
      for ( i:=0;i<len;++i ) {
         line :+= versionInfo.ParentRevisions[i];
         line :+= ', ';
      }
      line = substr(line,1,length(line)-2)'<br>';
   }
   line :+= '<B>Comment:</B> ' :+ versionInfo.Subject'<br>'versionInfo.Body;
   // assign this to the tree node
   _TreeSetUserInfo(index, line);
}

static void InitVersionInfo(HG_VERSION_INFO &versionInfo)
{
   versionInfo.ParentRevisionNumber = "";
   versionInfo.RevisionNumber = "";
   versionInfo.Subject = "";
   versionInfo.Body = "";
   versionInfo.Date = "";
   versionInfo.Author = "";
   versionInfo.Committer = "";
   versionInfo.Tag = "";
   versionInfo.Node = "";
}

defeventtab _hg_clone_form;

static _str hgCloneBrowse(ChooseDirectoryFlags chooseDirFlags=CDN_NO_SYS_DIR_CHOOSER)
{
   _str result = _ChooseDirDialog("",p_prev.p_text,"",chooseDirFlags);
   return result;
}

void ctlok.on_create(_str repository="",_str clonePath="")
{
   ctlrepository.p_text = repository;
   ctlclonePath.p_text = clonePath;
}

void ctlbrowsedir1.lbutton_up()
{
   flags := CDN_NO_SYS_DIR_CHOOSER;
   if ( p_window_id==ctlbrowsedir1 ) {
      flags |= CDN_PATH_MUST_EXIST;
   }
   result := hgCloneBrowse(flags);
   if ( result!="" ) {
      p_prev.p_text = result;
   }
}

void ctlok.lbutton_up()
{
   if ( ctlrepository.p_text=="" ) {
      ctlrepository._text_box_error("You must specify a repository to clone");
      return;
   }
   if ( ctlclonePath.p_text=="" ) {
      ctlclonePath._text_box_error("You must specify a local path for the clone");
      return;
   }
   _param1 = ctlrepository.p_text;
   _param2 = ctlclonePath.p_text;
   p_active_form._delete_window();
}

static int hgClonePrompt(_str &repository,_str &clonePath)
{
   status := 0;
   _param1 = _param2 = "";
   show('-modal _hg_clone_form',repository,clonePath);
   if ( _param1=="" || _param2=="" ) return COMMAND_CANCELLED_RC;

   repository = _param1;
   clonePath = _param2;

   return 0;
}
