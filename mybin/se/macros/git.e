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
#include "git.sh"
#import "cvs.e"
#import "cvsutil.e"
#import "se/datetime/DateTime.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "main.e"
#import "project.e"
#import "ptoolbar.e"
#import "savecfg.e"
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

// NOTE: check out http://git.or.cz/course/svn.html for a great comparisoin of SVN and git

// the flag that allows ending long async functions
static boolean gGitCancel=false;
// flag indicating whether or not push and pull should be interactive
boolean def_git_pushpull_interactive = true;
// flag indicating whether or not all output should be written to the output window
boolean def_git_output_all = true;

int def_git_debug = 0;
static int max_debug_shell_output = 25;

// initialization
definit()
{
   if (def_git_info == null) {
      _GitInit(def_git_info);
   }
}

/**
 * Logs info to the git debug log (<UserConfig>\logs\git.log)
 *
 * @param info
 */
void _GitDebug(_str info)
{
   dsay(info, 'git');
}

/**
 * Initialize all of the global data that we need to keep. 
 *  
 * @param git_info : Data to initialize
 */
void _GitInit(GIT_SETUP_INFO &git_info)
{
   if (def_git_info == null || def_git_info.git_exe_name == '' || !file_exists(def_git_info.git_exe_name)) {
      // Can't find git executable.
      def_git_info.git_exe_name = path_search(GIT_EXE_NAME);
   }
}

/**
 * Returns the name/path of the git executable that we are 
 * configured to use. If that is not found, we look for one in 
 * the path. 
 *  
 * @return _str - Name of the git executable
 */
_str _GitGetExeName()
{
   if (def_git_info == null) {
      _GitInit(def_git_info);
   }
   _str exe_name=def_git_info.git_exe_name;
   if (!file_exists(exe_name)) {
      exe_name=path_search(GIT_EXE_NAME);
   }
   return exe_name;
}

/**
 * Removes any double quotes from a comment string, which would 
 * break the command line 
 *  
 * @param comment The comment to translate 
 *  
 * @return _str - The translated comment
 */
_str RemoveQuotesFromComment(_str comment)
{
   // replace double quotes with single quoptes
   return stranslate(comment, "'", '"');
}

// http://stackoverflow.com/questions/2816369/git-push-error-remote-rejected-master-master-branch-is-currently-checked-ou
/**
 * The command entry point for executing a git push command.
 * 
 * @param filename The file name which originated the push request
 * 
 * @return int - 0 for success
 */
_command int git_push(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to push',// Dialog Box Title
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
   // we don't care if the file exists or not, we just need a path
   int status = _GitPush(filename);
   return status;
}

/**
 * This function executes a git push command.  The path of the 
 * specified file name is parsed and we determine if the file 
 * belongs to a git repository.  If so, then we push that whole 
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
int _GitPush(_str filename)
{
   _str path = _strip_filename(filename, 'N');
   // first, find out if this file is controlled by git, then get the repository root for this file
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The path 'path' cannot be pushed to git because it is not within a working tree.');
      return -1;
   }

   // run the push command from the repository root
   _str cmd = 'push '_GitGetNameForRemoteRepository(repositoryRoot);
   _str output[];
   _str shellOption = '';
   if (def_git_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   int status = _GitShell(cmd, repositoryRoot, shellOption, output);
   if (status) {

      // get the repository url and show an error message box
      _str repositoryUrl = _GitGetUrlForLocalRepository(repositoryRoot);
      _message_box('Git returned 'status' pushing repository at 'repositoryUrl'.');
      return status;
   }
   return status;
}

// http://stackoverflow.com/questions/2816369/git-push-error-remote-rejected-master-master-branch-is-currently-checked-ou
/**
 * The command entry point for executing a git pull command.
 * 
 * @param filename The file name which originated the pull request
 * 
 * @return int - 0 for success
 */
_command int git_pull(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
         _str result=_OpenDialog('-modal',
                                 'Select file to pull',// Dialog Box Title
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
   // we don't care if the file exists or not, we just need a path
   int status = _GitPull(filename);
   return status;
}

/**
 * This function executes the pull or the repository.  The path 
 * of the specified file name is parsed and we determine if the 
 * file belongs to a git repository.  If so, then we pull that 
 * whole repository, since a pull cannot be done on a subset of 
 * the repository. 
 *  
 * A pull in git gets the latest and merges it with the local 
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
int _GitPull(_str filename)
{
   _str path = _strip_filename(filename, 'N');
   // first, find out if this file is addable in git and get the repository root for this file
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The path 'path' cannot be pulled to git because it is not within a working tree.');
      return -1;
   }

   // run the push command
   rrname := _GitGetNameForRemoteRepository(repositoryRoot);
   rrbranch := _GitGetBranch(repositoryRoot);
   _str cmd = 'pull ' :+ rrname :+ ' ' :+ rrbranch;

   _str output[];
   _str shellOption = '';
   if (def_git_pushpull_interactive == false) {
      shellOption = 'Q';
   }
   int status = _GitShell(cmd, repositoryRoot, shellOption, output);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _GitGetUrlForLocalRepository(repositoryRoot);
      _message_box('Git returned 'status' pulling repository at 'repositoryUrl'.');
      return status;
   }
   // reload any buffers that may be affected
   _actapp_files();

   return status;
}

_str _GitGetBranch(_str repositoryRoot)
{
   branch := '';
   _str cmd = 'symbolic-ref HEAD';
   _str output[];
   int status = _GitShell(cmd, repositoryRoot, 'Q', output);
   if (status == 0) {
      if (output._length() > 0) {
         branch = strip(output[0]);
         // this will give us the full path, which we don't need
         if (pos('refs/heads/', branch)) {
            branch = substr(branch, 12);
         }
      }
   }

   return branch;
}

int _GitGetHeadRevisionID(_str repositoryRoot, _str &headRevision)
{
   headRevision = '';
   // run the push command
   _str cmd = "show --pretty=format:'%h###%ci' --quiet";
   _str output[];
   int status = _GitShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      // get the repository url and show an error message
      _str repositoryUrl = _GitGetUrlForLocalRepository(repositoryRoot);
      _message_box('Git returned 'status' getting the HEAD revision for the repository at 'repositoryUrl'.');
      return status;
   }
   // make sure we got some output back
   if (output._length() > 0) {
      _str revNumber = '';
      _str date = '';
      _str line = strip(output[0]);
      // parse the line info
      parse line with revNumber'###'date;
      headRevision = revNumber;
   }
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
_command int git_diff_with_tip(_str filename='') name_info(FILE_ARG'*,')
{
   // if there's no file name, then use the current buffer name
   if ( filename=='' ) {
      if ( !_no_child_windows() ) {
         filename=_mdi.p_child.p_buf_name;
      } else {
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
      }
   }
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return FILE_NOT_FOUND_RC;
   }
   // we don't care if the file exists or not, we just need a path
   int status = _GITDiffWithLocalFile(filenameNQ, 'HEAD');
   return status;
}

int _git_history_diff_button()
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
   int status = _GITDiffWithLocalFile(filename, version);
   return status;
}

/**
 * Performs diff_with_tip on the passed file name.
 *  
 * @param filename The file name to compare with the tip in git.
 *
 * @return int - 0 for success.
 */
static int _GITDiffWithLocalFile(_str filename, _str version)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   wid := p_window_id;
   // get the git relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');
   // run the show command to get the version contents
   _str output[];
   _str cmd = 'show 'version':'maybe_quote_filename(remote_filename);
   int status = _GitShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Git returned 'status' retrieving version 'version' for file 'filename'.');
      return status;
   }
   _str versionContentsFilename = mktemp() :+ _get_extension(filename, true);
   // write the output to a file
   _GitWriteOutputFile(output, versionContentsFilename);

   // show the diff dialog
   status = _DiffModal('-r2 -b2 -nomapping -file1title "':+filename:+' (Working Tree)" -file2title "'remote_filename' ('version')" 'maybe_quote_filename(filename)' 'maybe_quote_filename(versionContentsFilename), 'git');

   // clean up after ourselves
   delete_file(versionContentsFilename);

   p_window_id = wid;
   _set_focus();

   return 0;
}

_command int git_history_diff_predecessor()
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
   int status = _GITDiffTwoVersions(filename, version1, version2);
   return status;
}

/**
 * Performs diff_with_tip on the passed file name.
 *  
 * @param filename The file name to compare with the tip in git.
 *
 * @return int - 0 for success.
 */
static int _GITDiffTwoVersions(_str filename, _str version1, _str version2)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the git relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');
   // run the show command to get the version1 contents
   _str output[];
   _str cmd = 'show 'version1':'maybe_quote_filename(remote_filename);
   int status = _GitShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Git returned 'status' retrieving version 'version1' for file 'filename'.');
      return status;
   }
   _str version1ContentsFilename = mktemp() :+ '1' :+ _get_extension(filename, true);
   // write the output to a file
   _GitWriteOutputFile(output, version1ContentsFilename);
   // run the show command to get the version2 contents
   output._makeempty();
   cmd = 'show 'version2':'maybe_quote_filename(remote_filename);
   status = _GitShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Git returned 'status' retrieving version 'version2' for file 'filename'.');
      return status;
   }
   _str version2ContentsFilename = mktemp() :+ '2' :+ _get_extension(filename, true);
   // write the output to a file
   _GitWriteOutputFile(output, version2ContentsFilename);

   // show the diff dialog
   status = _DiffModal('-r1 -r2 -b2 -nomapping -file1title "Version ('version1')" -file2title "Version ('version2')" 'maybe_quote_filename(version1ContentsFilename)' 'maybe_quote_filename(version2ContentsFilename), 'git');

   // clean up after ourselves
   delete_file(version1ContentsFilename);
   delete_file(version2ContentsFilename);

   return 0;
}

/**
 * The command entry point for executing a git commit command.
 * 
 * @param filename The file name to commit 
 * @param comment The comment included with the commit 
 * 
 * @return int - 0 for success
 */
_command int git_commit(typeless filename='', _str comment='') name_info(FILE_ARG'*,')
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
   // make sure the file exists
   filenameNQ := strip(filename,'B','"');
   if (!file_exists(filenameNQ)) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   // run the commit command
   _str temp[];
   temp[0]=filenameNQ;
   int status=_GitCommit(temp,comment);
   return status;
}

/**
 * This function executes a git commit command.  We confirm that
 * each file in the list to commit is in the git repository 
 * root.  We then make sure that we have a comment to apply to 
 * the operation.  Each file to commit must then be added to the 
 * commit set and then a single commit is executed. 
 * 
 * @param filelist The list of files to be committed
 * @param comment The comment to be applied to the commit
 * 
 * @return int - 0 for success
 */
int _GitCommit(_str filelist[],_str comment)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filelist[0], repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filelist[0]' cannot be committed because it is not within a working tree.');
      return -1;
   }
   // now that we have the repository root, we can do a simple check on all remaining files
   int i = 0;
   _str preparedfiles[];
   for (i = 0; i < filelist._length(); i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot commit file '%s' because the file is open and modified.", _strip_filename(filename, 'P')));
         return -2;
      }
      if (filename != '') {
         // make sure it starts with the repository root
         _str filenamePrefix = substr(filename, 1, repositoryRoot._length());
         if (stricmp(repositoryRoot, filenamePrefix) == 0)
         {
            // yes!  it does start with that prefix!  Now remove that prefix...
            filename = substr(filename, repositoryRoot._length() + 1);
            // translate and \ chars into /
            filename = stranslate(filename, '/', '\');
            // add it to the list of prepared files
            preparedfiles[preparedfiles._length()] = filename;
         }
      }
   }
   // if we don't have a valid comment, then show a dialog to get one
   int status=0;
   _str tag = '';
   tmpFile := '';
   author := '';
   if ((comment==NULL_COMMENT) || (comment=='')) {
      tmpFile = mktemp(1, '.sltmp');
      status=_CVSGetComment(tmpFile,tag,filelist[0],false,false,false,true,author);
      if ( status ) {
         return status;
      } else {
         comment = _param3;
         if (strip(comment) == '') {
            if (preparedfiles._length() == 1) {
               _message_box('Checking in 'preparedfiles[0]);
            } else {
               _message_box('Checking in files.');
            }
         }
      }
   }
   // run the add command first to include all of the files in the commit set
   _str cmd = '';
   _str output[];
   for (i = 0; i < preparedfiles._length(); i++) {
      cmd = 'add 'maybe_quote_filename(preparedfiles[i]);
      status = _GitShell(cmd, repositoryRoot, 'Q', output);
      if (status) {
         _message_box('Git returned 'status' adding file 'filelist[0]'.');
         return status;
      }
   }
   // now commit them in bulk
   cmd = 'commit';
   if (comment != '') {
      if (tmpFile != "" && file_exists(tmpFile)) {
         cmd :+= ' -F 'maybe_quote_filename(tmpFile);
      } else {
         cmd :+= ' -m "'RemoveQuotesFromComment(comment)'"';
      }
   }

   if (author != '') {
      cmd :+= ' --author="'author'"';
   }

   status = _GitShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      if (preparedfiles._length() == 1) {
         _message_box('Git returned 'status' committing file 'filelist[0]'.');
      } else {
         _message_box('Git returned 'status' committing the files.');
      }
   }

   if (tmpFile != "") delete_file(tmpFile);

   return 0;
}

/**
 * The command entry point for executing a git add command.
 * 
 * @param filename The file name to be added
 * 
 * @return int - 0 for success
 */
_command int git_add(_str filename='') name_info(FILE_ARG'*,')
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
   int status = _GITAdd(temp);
   return status;
}

// http://www.kernel.org/pub/software/scm/git/docs/git-add.html
/**
 * This function executes a git add command.  We confirm that
 * each file in the list to commit is in the git repository 
 * root.  Each file to add must then be processed. 
 * 
 * @param filelist The list of files to be committed
 * 
 * @return int - 0 for success
 */
static int _GITAdd(_str filelist[])
{
   // first, find out if this file is addable in git and get the repository root for this file
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filelist[0], repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filelist[0]' cannot be added to git because it is not within a working tree.');
      return -1;
   }
   // now that we have the repository root, we can do a simple check on all remaining files
   int i = 0;
   _str preparedfiles[];
   for (i = 0; i < filelist._length(); i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot add file '%s' because the file is open and modified.", filename));
         return -2;
      }
      if (filename != '') {
         // make sure it starts with the repository root
         _str filenamePrefix = substr(filename, 1, repositoryRoot._length());
         if (stricmp(repositoryRoot, filenamePrefix) == 0)
         {
            // yes!  it does start with that prefix!  Now remove that prefix...
            filename = substr(filename, repositoryRoot._length() + 1);
            // translate and \ chars into /
            filename = stranslate(filename, '/', '\');
            // add it to the list of prepared files
            preparedfiles[preparedfiles._length()] = filename;
         }
      }
   }
   // add each of the files
   for (i = 0; i < preparedfiles._length(); i++) {
      // run the add command
      _str cmd = 'add 'maybe_quote_filename(preparedfiles[i]);
      _str output[];
      int status = _GitShell(cmd, repositoryRoot, 'Q', output);
      if (status) {
         _message_box('Git returned 'status' adding file 'preparedfiles[i]'.');
         return status;
      }
   }
   return 0;
}

/**
 * The command entry point for executing a git rm command.
 * 
 * @param filename The file name to be removed
 * 
 * @return int - 0 for success
 */
_command int git_remove(_str filename='') name_info(FILE_ARG'*,')
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
   int status = _GitRemove(temp);
   return status;
}

// http://www.kernel.org/pub/software/scm/git/docs/git-rm.html
/**
 * This function executes a git rm command.  We confirm that
 * each file in the list to remove is in the git repository 
 * root.  Each file to remove must then be processed. 
 * 
 * @param filelist The list of files to be committed
 * 
 * @return int - 0 for success
 */
static int _GitRemove(_str filelist[])
{
   // make sure that we have a list of files
   if (filelist._length() == 0) {
      return 0;
   }
   // first, find out if this file is removable in git and get the repository root for this file
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filelist[0], repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filelist[0]' cannot be removed from git because it is not within a working tree.');
      return -1;
   }
   // now that we have the repository root, we can do a simple check on all remaining files
   int i = 0;
   _str preparedfiles[];
   for (i = 0; i < filelist._length(); i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot remove file '%s' because the file is open and modified.", filename));
         return -2;
      }
      if (filename != '') {
         // make sure it starts with the repository root
         _str filenamePrefix = substr(filename, 1, repositoryRoot._length());
         if (stricmp(repositoryRoot, filenamePrefix) == 0)
         {
            // yes!  it does start with that prefix!  Now remove that prefix...
            filename = substr(filename, repositoryRoot._length() + 1);
            // translate and \ chars into /
            filename = stranslate(filename, '/', '\');
            // add it to the list of prepared files
            preparedfiles[preparedfiles._length()] = filename;
         }
      }
   }
   // remove each file
   for (i = 0; i < preparedfiles._length(); i++) {
      // run the add command
      _str cmd = 'rm -f 'maybe_quote_filename(preparedfiles[i]);
      _str output[];
      int status = _GitShell(cmd, repositoryRoot, 'Q', output);
      if (status) {
         _message_box('Git returned 'status' removing file 'preparedfiles[i]'.');
         return status;
      }
   }
   // reload any buffers that may be affected
   _actapp_files();

   return 0;
}

/**
 * The command entry point for executing a git revert command.
 * 
 * @param filename The file name to be added
 * 
 * @return int - 0 for success
 */
_command int git_revert(_str filename='') name_info(FILE_ARG'*,')
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
   int status = _GitRevert(temp);
   return status;
}

// Git uses the checkout command in the same way that SVN uses the revert command
// http://www.kernel.org/pub/software/scm/git/docs/git-checkout.html
/**
 * This function executes a git revert command.  We confirm that
 * each file in the list to commit is in the git repository 
 * root.  Each file to revert must then be processed. 
 * 
 * @param filelist The list of files to be reverted
 * 
 * @return int - 0 for success
 */
static int _GitRevert(_str filelist[])
{
   // make sure that we have a list of files
   if (filelist._length() == 0) {
      return 0;
   }
   // first, find out if this file is addable in git and get the repository root for this file
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filelist[0], repositoryRoot);
   if (isGitFile == false) {
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
   _str preparedfiles[];
   for (i = 0; i < filelist._length(); i++) {
      _str filename = filelist[i];
      boolean ismodified = _SVCBufferIsModified(filename);
      if ( ismodified ) {
         _message_box(nls("Cannot revert file '%s' because the file is open and modified.", filename));
         return -2;
      }
      if (filename != '') {
         // make sure it starts with the repository root
         _str filenamePrefix = substr(filename, 1, repositoryRoot._length());
         if (stricmp(repositoryRoot, filenamePrefix) == 0)
         {
            // yes!  it does start with that prefix!  Now remove that prefix...
            filename = substr(filename, repositoryRoot._length() + 1);
            // translate and \ chars into /
            filename = stranslate(filename, '/', '\');
            // add it to the list of prepared files
            preparedfiles[preparedfiles._length()] = filename;
         }
      }
   }
   // process each file
   for (i = 0; i < preparedfiles._length(); i++) {
      // run the add command
      _str cmd = 'checkout 'maybe_quote_filename(preparedfiles[i]);
      _str output[];
      int status = _GitShell(cmd, repositoryRoot, 'Q', output);
      if (status) {
         _message_box('Git returned 'status' reverting file 'preparedfiles[i]'.');
         return status;
      }
   }
   // reload any buffers that may be affected
   _actapp_files();

   return 0;
}

_command int git_history(_str filename='', boolean quiet=false, _str version=null) name_info(FILE_ARG'*,')
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
   _str gitRootPath = '';
   if ( !IsGitPath(filename, gitRootPath) ) {
      _message_box(nls("'%s' is was not checked out from Git",filename));
      return(1);
   }

   int wid = show('-new -xy -hidden _cvs_history_form');
   wid._GitFillInHistory(filename);
   _control ctltree1;
   wid.ctltree1.call_event(CHANGE_SELECTED,wid.ctltree1._TreeCurIndex(),wid.ctltree1,ON_CHANGE,'W');
   wid.p_caption='Git info for 'filename;
   wid.p_user = filename;
   wid.p_visible=true;
   wid.git_history_add_menu();

   return(0);
}

#region _git_mfupdate_form handlers
defeventtab _git_mfupdate_form;

#define GIT_MFUPDATE_ROOT_PATH         ctl_gitremove.p_user

/**
 * Handles the rezigin of the dialog
 */
void _git_mfupdate_form.on_resize()
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
   ctl_gitremove.p_y = ctl_gitcommitall.p_y = ctl_gitcommit.p_y = ctl_gitrevert.p_y = ctl_gitdiff.p_y = ctl_close.p_y;
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

/**
 * Called when the selected index on the tree change so we can 
 * determine which buttons to enable or not. 
 */
void ctltree1.on_change(int reason,int index)
{
   if ( reason==CHANGE_SELECTED ) {
      SetButtonEnabledStates();
   }
}

/**
 * Determines which buttons are enabled or not based on the 
 * current tree selection. 
 */
static void SetButtonEnabledStates()
{
   boolean filesAreSelected = false;
   // see if any items are selected in the tree
   _str selectedFiles[];
   GetSelectedMFTreeFiles(selectedFiles);
   filesAreSelected = (selectedFiles._length() > 0);
   // set the enabled state of the dialog buttons
   ctl_gitrevert.p_enabled = filesAreSelected;
   ctl_gitremove.p_enabled = filesAreSelected;
   ctl_gitcommit.p_enabled = filesAreSelected;
   ctl_gitdiff.p_enabled = filesAreSelected;
}

/**
 * Called when the user selects to revert the selected files in 
 * the tree. 
 */
void ctl_gitrevert.lbutton_up()
{
   _str selectedFiles[];
   int status=0;
   _str comment = '';
   _str tag = '';

   // get the files that are selected to commit
   GetSelectedMFTreeFiles(selectedFiles);
   if (selectedFiles._length() == 0) {
      return;
   }
   // revert the files
   status = _GitRevert(selectedFiles);
   // refresh, to pick up our changes
   _GitRefreshUpdateDialog();
}

/**
 * Called when the user selects to remove the selected files in 
 * the tree. 
 */
void ctl_gitremove.lbutton_up()
{
   _str selectedFiles[];
   int status=0;
   _str comment = '';
   _str tag = '';

   // get the files that are selected to commit
   GetSelectedMFTreeFiles(selectedFiles);
   if (selectedFiles._length() == 0) {
      return;
   }
   // revert the files
   status = _GitRemove(selectedFiles);
   // refresh, to pick up our changes
   _GitRefreshUpdateDialog();
}

/**
 * Called when the user selects to commit all files in 
 * the tree. 
 */
void ctl_gitcommitall.lbutton_up()
{
   _str allFiles[];
   int status=0;
   _str comment = '';
   _str tag = '';

   // get all files in the tree
   GetAllMFTreeFiles(allFiles);
   if (allFiles._length() == 0) {
      return;
   }
   // commit them
   status = _GitCommit(allFiles, comment);
   // refresh, to pick up our changes
   _GitRefreshUpdateDialog();
}

/**
 * Called when the user selects to commit the selected files in 
 * the tree. 
 */
void ctl_gitcommit.lbutton_up()
{
   _str selectedFiles[];
   int status=0;
   _str comment = '';
   _str tag = '';

   // get the files that are selected to commit
   GetSelectedMFTreeFiles(selectedFiles);
   if (selectedFiles._length() == 0) {
      return;
   }
   // commit the files
   status = _GitCommit(selectedFiles, comment);

   // refresh, to pick up our changes
   _GitRefreshUpdateDialog();
}

/**
 * Closes the dialog.
 */
void ctl_close.lbutton_up()
{
   // close the dialog
   p_active_form._delete_window('');
}

int ctl_gitdiff.lbutton_up()
{
   // get the list of selected files
   _str selectedFiles[];
   GetSelectedMFTreeFiles(selectedFiles);
   if (selectedFiles._length() == 0) {
      // just kidding!
      return 0;
   }

   // go through the files and diff them
   for (i := 0; i < selectedFiles._length(); i++) {
      git_diff_with_tip(selectedFiles[i]);
   }

   // refresh, in case we made any changes
   _GitRefreshUpdateDialog();

   return 0;
}

#endregion

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
_command int git_update_directory,git_gui_mfupdate(_str path='') name_info(FILE_ARG'*,')
{
   path = strip(path,'B','"');
   if ( path=='' ) {
      path=_GitGetPath();
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
   // let's make sure that path is an actual git path
   _str repositoryRoot = '';
   boolean isGitPath = IsGitPath(path, repositoryRoot);
   if (isGitPath == false) {
      _message_box(path' is not a path that is managed by git.');
      return 0;
   }

   // get the url for the given path
   // get the list of modified, added or removed files in Git
   GIT_FILE_STATUS fileList[];
   int status = _GitGetPendingChanges(repositoryRoot, fileList);
   if (status) {
      _str url = _GitGetUrlForLocalRepository(repositoryRoot);
      _message_box(nls("An error occurred getting difference information about repository '%s'.", url));
      return status;
   }
   if (fileList._length() == 0) {
      _str url = _GitGetUrlForLocalRepository(repositoryRoot);
      _message_box(nls("No pending changes to repository '%s' found.", url));
      return 0;
   }
   // populate and show the mfupdate dialog for git differences
   _GITGUIUpdateDialog(repositoryRoot, fileList);
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
static _str _GitGetPath(_str caption='Choose path')
{
   return(_CVSGetPath(caption,'_git_path_form'));
}

/**
 * Debug function for outputting git file difference info to the 
 * console window. 
 * 
 * @param fileList The list of file difference info.
 * @param rootPath The path to the git repository root.
 */
static void _DebugSayPendingChanges(GIT_FILE_STATUS fileList[], _str rootPath)
{
   say('Modified files in 'rootPath);
   int i = 0;
   for (i = 0; i < fileList._length(); i++) {
      _str outputLine = '   'fileList[i].filename' : ';
      if (fileList[i].state == GIT_UNCHANGED) {
         outputLine :+= "Unchanged";
      } else if (fileList[i].state == GIT_NEW) {
         outputLine :+= "New";
      } else if (fileList[i].state == GIT_MODIFIED) {
         outputLine :+= "Modified";
      } else if (fileList[i].state == GIT_DELETED) {
         outputLine :+= "Deleted";
      }
      say(outputLine);
   }
}
/**
 * Refreshes the file statuses on the Git Update dialog.
 */
static void _GitRefreshUpdateDialog()
{
   // get the url for the given path
   // get the list of modified, added or removed files in Git
   GIT_FILE_STATUS fileList[];
   int status = _GitGetPendingChanges(GIT_MFUPDATE_ROOT_PATH, fileList);
   if (status) {
      _str url = _GitGetUrlForLocalRepository(GIT_MFUPDATE_ROOT_PATH);
      _message_box(nls("An error occurred getting difference information about repository '%s'.", url));
      return;
   }

   ctltree1._PopulateFileStatusTree(GIT_MFUPDATE_ROOT_PATH, fileList);
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
static void _GITGUIUpdateDialog(_str rootPath, GIT_FILE_STATUS fileList[])
{
   _nocheck _control ctltree1;

   int wid = show('-xy -app -new _git_mfupdate_form');

   p_window_id = wid;
   p_active_form.p_caption='Git Repository Status';
   GIT_MFUPDATE_ROOT_PATH = rootPath;
   ctltree1._PopulateFileStatusTree(rootPath, fileList);
   _set_foreground_window();
}

/**
 * Populates the mfupdate tree with file statuses.
 * 
 * @param rootPath The local root where a repository is checked 
 *                 out.
 * @param fileList The array of file statuses for files that 
 *                 have a difference with the repository.
 */
static void _PopulateFileStatusTree(_str rootPath, GIT_FILE_STATUS fileList[])
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
   int PathIndexes1:[]=null;

   rootPath = stranslate(rootPath, FILESEP, '/');
   int newindex=_TreeAddItem(TREE_ROOT_INDEX,rootPath,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
   int i;
   for ( i=0;i<fileList._length();++i ) {
      _str curFilename = stranslate(fileList[i].filename, FILESEP, '/');
      int parent_bitmap_index=_pic_fldopen;
      _str end_char=last_char(curFilename);
      typeless isdir=isdirectory(curFilename);
      int index1=_GitTreeGetPathIndex(newindex, _file_path(curFilename), rootPath, PathIndexes1, _pic_fldopen, _pic_cvs_fld_m);
      int fileBitmap = _pic_file;
      if (fileList[i].state == GIT_NEW) {
         fileBitmap = _pic_cvs_file_new;
      } else if (fileList[i].state == GIT_MODIFIED) {
         fileBitmap = _pic_file_mod;
      } else if (fileList[i].state == GIT_DELETED) {
         fileBitmap = _pic_file_del;
      }
      if ( end_char!=FILESEP && !isdir ) {
         int newindex1=_TreeAddItem(index1,_strip_filename(curFilename,'P'),TREE_ADD_AS_CHILD,fileBitmap,fileBitmap,-1);
         _str fullPath = rootPath :+ curFilename;
         _TreeSetUserInfo(newindex1, fullPath);
      }
   }
   ctltree1._TreeSortTree();
   ctllocal_path_label.p_caption='Local: 'rootPath;
   ctlrep_label.p_caption='URL: '_GitGetUrlForLocalRepository(rootPath, true);
   SetButtonEnabledStates();
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
static int _GitTreeGetPathIndex(int rootIndex,_str Path,_str BasePath,int (&PathTable):[], int ExistFolderIndex=_pic_fldopen, int NoExistFolderIndex=_pic_cvs_fld_m, _str OurFilesep=FILESEP, int state=1)
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
      Parent=_TreeAddItem(Parent, PathsToAdd[i], TREE_ADD_AS_CHILD, bmindex, bmindex, state);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

/**
 * Determines if a path, or a file's path, belongs to a git 
 * repository.  It does this by looking to see if a .git 
 * directory exists under filename's directory, and if not, then
 * it looks up the folder's parents to the root. 
 *
 * @param path The path or filename to check 
 * @param gitRootPath The root path where the git repository is 
 *                    checked out to.
 *
 * @return true if file is a git path or file.
 */
static boolean IsGitPath(_str path, _str& gitRootPath)
{
   if (def_git_debug) _GitDebug('_IsGitPath - 'path);

   gitRootPath = '';
   // get the path from the file name passed in
   path=absolute(path);
   if ( !isdirectory(path) ) {
      path=_strip_filename(path,'N');
   }
   _maybe_append_filesep(path);

   // determine if a "[x]/.git" folder exists.  If it does, then this is a git file.
   boolean isRootFolder = (isdirectory(path) != 0);
   _str gitPath = '';
   boolean gitPathExists = false;
   do {
      gitPath = path:+'.git';
      gitPathExists = (isdirectory(gitPath) != 0);
      if (!gitPathExists) {
         // see if we have reached the top
         if (!isdrive(path)) {
            path = _parent_path(path);
            isRootFolder = (path == '' || isdirectory(path) == 0);
         } else {
            // base case, we need to stop
            isRootFolder = 1;
         }
      } else {
         gitRootPath = path;
      }
      // if the git path exists, then great.  If not, walk up to the parent folder 
      // and try again until we find a match, or we hit a root folder
   } while ((!gitPathExists) && (!isRootFolder));

   if (def_git_debug) _GitDebug('   returning 'gitPathExists);
   return gitPathExists;
}

// returns the URL for the remote repository managed by this local workspace
// NOTE: The current working directory MUST be in the git repository path
/**
 * Returns the URL for the remote repository managed by this local workspace.
 * 
 * @param repositoryRoot The local root folder where the repository is checked out.
 * 
 * @return _str The url for the remote repository.
 */
static _str _GitGetUrlForLocalRepository(_str repositoryRoot, boolean quiet = false)
{
   // first try getting it from the config file
   repositoryUrl := _GitGetUrlForLocalRepositoryFromConfigFile(repositoryRoot);
   if (repositoryUrl == '') {

      // it did not work, so try querying - this may not work 
      // if they used a different name other than "remote"
      // run the config command
      _str cmd = 'config --get remote.origin.url';
      _str output[];
      int status = _GitShell(cmd, repositoryRoot, 'Q', output);
      if (status == 0) {
         if (output._length() > 0) {
            repositoryUrl = strip(output[0]);
            repositoryUrl = _ConvertCygwinPrefix(repositoryUrl);
         }
      } else {
         if (!quiet) {
            _message_box("An error occurred getting the URL for this repository.");
         }
         repositoryUrl = '';
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
static _str _GitGetNameForRemoteRepository(_str repositoryRoot)
{
   _str repositoryName = '';
   int tempWid, origWid;

   // get the config file
   configFile := _GitGetConfigFile(repositoryRoot);

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
 * Returns the path to the git config file for this repository.
 * 
 * @param repositoryRoot 
 * 
 * @return _str 
 */
static _str _GitGetConfigFile(_str repositoryRoot)
{
   _maybe_append_filesep(repositoryRoot);
   repositoryRoot :+= '.git'FILESEP'config';

   return repositoryRoot;
}

/**
 * Gets the URL for the remote repository by looking into the git config file 
 * for the repository. 
 * 
 * @param repositoryRoot 
 * 
 * @return _str 
 */
static _str _GitGetUrlForLocalRepositoryFromConfigFile(_str repositoryRoot)
{
   _str repositoryUrl = '';
   int tempWid, origWid;

   // get the config file
   configFile := _GitGetConfigFile(repositoryRoot);

   if (file_exists(configFile)) {
      // open it up and take a peek
      _open_temp_view(configFile, tempWid, origWid);
      if (tempWid > 0) {
         top();
         
         // look for the section that deals with remote stuff
         if (!search('[remote ')) {

            // look for the line that contains the url
            while (true) {
               if (down()) break;

               get_line(auto line);

               // check that we are still in the same section
               if (pos('[', line) == 1) {
                  break;
               } else {
                  parse line with auto name '=' auto value;
                  if (name == 'url') {
                     // we got it
                     repositoryUrl = value;
                     break;
                  }
               }
            }
         } 
      }

   }

   if (tempWid) {
      _delete_temp_view(tempWid);
      p_window_id = origWid;
   }

   return repositoryUrl;
}

/**
 * Converts the '/cygdrive/' prefix on cygwin paths to an actual 
 * volume label. This is required if the git repository in on a 
 * local drive. 
 * 
 * @param url A repository URL to convert
 * 
 * @return _str - Returns the converted URL 
 */
static _str _ConvertCygwinPrefix(_str url) {
   _str retVal = url;
   _str prefixMatch = substr(url, 1, length(GIT_CYGWIN_PREFIX));
   if (strieq(prefixMatch, GIT_CYGWIN_PREFIX) == true) {
      // we've got to tweak the url to a Windows friendly name
      // first, remove the /cygwin/ part
      url = substr(url, length(GIT_CYGWIN_PREFIX) + 1);
      // split this into an array
      _str pathParts[] = split2array(url, '/');
      pathParts[0] = pathParts[0]':';
      retVal = join(pathParts, '\');
   }
   return retVal;
}

/**
 * Runs the log command for a file and determines that file's 
 * git status. 
 * 
 * @param filename The name of the file to get info for
 * @param logInfo The structure to populate with log info
 * 
 * @return int - 0 for success
 */
static int _GitGetLogInfoForFile(_str filename, GIT_LOG_INFO &logInfo)
{
   // make sure the file is git controlled
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' is not within a working tree.');
      return -1;
   }
   // now remove that prefix...
   filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   filename = stranslate(filename, '/', '\');

   // create a temp file to write the log to
   _str cmd = "log --pretty=format:'%p###%H###%cd###%cn###%s###%b###%an' "maybe_quote_filename(filename);
   _str output[];
   int status=_GitShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      _message_box(nls("Git log returned %s for file '%s'", status, filename));
      return status;
   }
   // parse the output
   InitGitLogInfo(logInfo);
   GetGitLogInfo(output, logInfo);

   return status;
}

/**
 * Initializes a GIT_LOG_INFO struct.
 * 
 * @param info The struct to initialize.
 */
static void InitGitLogInfo(GIT_LOG_INFO &info)
{
   info.WorkingFile = '';
   info.Head = '';
   info.CurBranch = '';
   info.LocalVersion = '';
   info.State = GIT_UNCHANGED;
   info.VersionList._makeempty();
}

/**
 * Parses the log info in the specified output file in 
 * [filename]. 
 * 
 * @param filename The output file from running 'git log'
 * @param info The structure to populate with git log info.
 */
static void GetGitLogInfo(_str output[], GIT_LOG_INFO &info)
{
   GIT_VERSION_INFO flatVersionList[];
   GIT_VERSION_INFO curVersion;
   _str line = '';
   int rc = 0;
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      _str infoRevNumber = '';
      _str infoParentRevNumber = '';
      _str infoDate = '';
      _str infoCommitter = '';
      _str infoSubject = '';
      _str infoBody = '';
      _str infoAuthor = '';

      line = strip(output[i]);
      if (line == '') {
         continue;
      }
      // parse the line info
      parse line with infoParentRevNumber'###'infoRevNumber'###'infoDate'###'infoCommitter'###'infoSubject'###'infoBody'###'infoAuthor;
      curVersion.ParentRevisionNumber = infoParentRevNumber;
      curVersion.RevisionNumber = infoRevNumber;
      curVersion.Date = infoDate;
      curVersion.Committer = infoCommitter;
      curVersion.Subject = infoSubject;
      curVersion.Body = infoBody;
      curVersion.Author = infoAuthor;
      // insert it into the temp flat list
      flatVersionList[i] = curVersion;
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
static _str _GitGetCurrentBranch(_str rootPath)
{
   _str curBranch = 'master';

   // run the branch command
   _str cmd = 'branch';
   _str output[];
   int status=_GitShell(cmd, rootPath, 'Q', output);
   _str line = '';
   int retVal = 0;
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      line = strip(output[i]);
      if (substr(line, 1, 1) == '*') {
         curBranch = strip(substr(line, 2));
         break;
      }
   }

   return curBranch;
}

/**
 * CD's to the directory specified, and runs the necessary
 * command, then restores the previous directory.
 *
 * On UNIX, git will not accept an absolute path, so you have
 * to cd to a relative directory to run a command.
 *
 * Also, turns on mou_hour_glass while running.
 *
 * @param command    command to shell (do not include Git in the 
 *                   command, just what comes after)
 * @param FileOrPath Directory to cd to, or absolute filename to cd to directory of
 * @param shell_options
 *                   Options for shell builtin
 * @param debug      if 1, a debug line will be output with the actual line
 *                   shelled out, and current directory
 *
 * @return status from shell builtin
 */
static int _GitShell(_str command,_str path,_str shell_options,_str (&output)[], boolean suppressOutput=false)
{
   if (def_git_debug) _GitDebug('_GitShell');

   int pid = 0;
   int status = 0;
   output._makeempty();

   // change to the repository directory
   _str cwd = getcwd();
   chdir(path,1);

   if (def_git_debug) _GitDebug('   changing to 'path);

   // create a temp file to capture the output
   _str outputFilename = mktemp(1, '.sltmp');
   // set up the command to output the result
   _str commandWithoutOutput = maybe_quote_filename(_GitGetExeName())' 'command;
   _str commandWithOutput = commandWithoutOutput' > 'maybe_quote_filename(outputFilename)' 2>&1'; 
   if (def_git_debug) _GitDebug('   'commandWithOutput);
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
   if (def_git_debug) _GitDebug('   status from shell = 'status);
   // read the output
   _GitReadOutputFile(outputFilename, output);
   // maybe write the command that was run
   if ((status != 0) || (def_git_output_all == true)) {
      // output the command
      _str t1 = _time('b');
      se.datetime.DateTime dateTime = se.datetime.DateTime.fromTimeB(t1);
      SVCWriteToOutputWindow('------------- 'dateTime.toStringParts(DT_LOCALTIME, DT_DATE)' 'dateTime.toStringParts(DT_LOCALTIME, DT_TIME));
      SVCWriteToOutputWindow('Command: 'commandWithoutOutput);
      // maybe write the output results
      if (suppressOutput == false) {
         SVCWriteArrayToOutputWindow(output);
      }
      SVCWriteToOutputWindow('');
   }

   if (def_git_debug) {
      _GitDebug('   -------------------Output from shell-------------------');
      for (i := 0; i < output._length() && i < max_debug_shell_output; i++) {
         _GitDebug('      'i': 'output[i]);
      }
      if (output._length() > max_debug_shell_output) _GitDebug('   ...'output._length() - max_debug_shell_output' more lines');
      _GitDebug('   -------------------------------------------------------');
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
static void _GitReadOutputFile(_str outputFilename, _str (&output)[])
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
      output[output._length()] = line;
      retVal = down();
   }
   // clean up after ourselves
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
static void _GitWriteOutputFile(_str output[], _str &outputFilename)
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
static void SetGitCancel(boolean newval)
{
   gGitCancel=newval;
}

/**
 * Gets the flag that can cancel an async function.
 */
static boolean GetGitCancel()
{
   return(gGitCancel);
}

/**
 * Returns an array of GIT_FILE_STATUS objects which represent 
 * the differences between the local workspace and the local 
 * repository. 
 * 
 * @param fileList The array of diff info objects to populate
 * 
 * @return int - 0 for success
 */
static int _GitGetFileStatus(_str filename, GIT_FILE_STATUS &fileStatus)
{
   // initialize the status struct
   InitGitFileStatus(fileStatus);
   fileStatus.filename = filename;
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the git relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');

   // run the status command
   _str cmd = 'status 'maybe_quote_filename(remote_filename);
   _str output[];
   int status=_GitShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      return status;
   }
   int i = 0;
   for (i = 0; i < output._length(); i++) {
      // if we found an action to be taken with this line, then break
      boolean actionFound = GitParseFileStatus(output[i], fileStatus);
      if (actionFound == true) {
         break;
      }
   }
   return 0;
}

/**
 * Returns an array of GIT_FILE_STATUS objects which represent 
 * the differences between the local workspace and the local 
 * repository. 
 * 
 * @param fileList The array of diff info objects to populate
 * 
 * @return int - 0 for success
 */
static int _GitGetPendingChanges(_str repositoryRoot, GIT_FILE_STATUS (&fileList)[])
{
   fileList._makeempty();

   // run the status command
   _str cmd = 'status';
   _str output[];
   int status=_GitShell(cmd, repositoryRoot, 'Q', output);
   if (status) {
      return status;
   }
   // parse the output
   _str line = '';
   _str temp = '';
   int retVal = 0;
   int i = 0;
   GIT_FILE_STATUS fileStatus;
   boolean actionFound = false;
   for (i = 0; i < output._length(); i++) {
      // if we found an action to be taken with this line, then add it to the files
      actionFound = GitParseFileStatus(output[i], fileStatus);
      if (actionFound == true) {
         fileList[fileList._length()] = fileStatus;
      }
   }
   return 0;
}

static boolean GitParseFileStatus(_str line, GIT_FILE_STATUS &fileStatus)
{
   boolean actionFound = false;
   _str temp = '';
   // does it contain an indicator that this line is a new file being added?
   int tokenPos = pos('new file:', line, 1, 'I');
   if (tokenPos != 0) {
      // we have a new file here
      temp = substr(line, tokenPos + 9);
      fileStatus.filename = strip(temp);
      fileStatus.state = GIT_NEW;
      // flag that we've done something with this line
      actionFound = true;
   }
   if (actionFound == false) {
      // does it contain an indicator that this line is a deleted file?
      tokenPos = pos('deleted:', line, 1, 'I');
      if (tokenPos != 0) {
         // we have a modified file here
         InitGitFileStatus(fileStatus);
         temp = substr(line, tokenPos + 9);
         fileStatus.filename = strip(temp);
         fileStatus.state = GIT_DELETED;
         // flag that we've done something with this line
         actionFound = true;
      }
   }
   if (actionFound == false) {
      // does it contain an indicator that this line is a modified file?
      tokenPos = pos('modified:', line, 1, 'I');
      if (tokenPos != 0) {
         // we have a modified file here
         InitGitFileStatus(fileStatus);
         temp = substr(line, tokenPos + 9);
         fileStatus.filename = strip(temp);
         fileStatus.state = GIT_MODIFIED;
         // flag that we've done something with this line
         actionFound = true;
      }
   }
   return actionFound;
}

/**
 * Initializes a GIT_FILE_STATUS struct.
 * 
 * @param fileStatus The struct to initialize
 */
void InitGitFileStatus(GIT_FILE_STATUS &fileStatus)
{
   fileStatus.filename = '';
   fileStatus.state = GIT_UNCHANGED;
}

static _str GitFileStateToString(GIT_STATE state)
{
   _str retVal = 'Unknown';
   switch (state) {
   case GIT_UNCHANGED:
      retVal = 'Unchanged';
      break;
   case GIT_NEW:
      retVal = 'New';
      break;
   case GIT_MODIFIED:
      retVal = 'Modified';
      break;
   case GIT_DELETED:
      retVal = 'Deleted';
      break;
   }
   return retVal;
}

defeventtab _cvs_history_form;

/**
 * Callback for "View" button on subversion history dialog
 * @return 0 if successful
 */
int _git_history_view_button()
{
   int formWid = p_parent;
   _str filename = formWid.p_user;

   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' cannot be viewed because it is not within a working tree.');
      return -1;
   }
   // get the git relative file name
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
   int status = _GitShell(cmd, repositoryRoot, 'Q', output, true);
   if (status) {
      _message_box('Git returned 'status' retrieving the tip for file 'filename'.');
      return status;
   }
   _str outputFilename = mktemp() :+ _get_extension(remote_filename, true);
   // write the output to a file
   _GitWriteOutputFile(output, outputFilename);

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

// STUBS
/*
int _git_update_add_button()
{
   say('_git_update_add_button');
   return 0;
}
int _git_update_update_button()
{
   say('_git_update_update_button');
   return 0;
}
int _git_update_commit_button()
{
   say('_git_update_commit_button');
   return 0;
}
int _git_update_merge_button()
{
   say('_git_update_merge_button');
   return 0;
}
int _git_update_history_button()
{
   say('_git_update_history_button');
   return 0;
}
int _git_update_diff_button()
{
   say('_git_update_diff_button');
   return 0;
}
int _git_history_refresh_button()
{
   say('_git_history_refresh_button');
   return 0;
}
int _git_history_revert_button()
{
   say('_git_history_revert_button');
   return 0;
}
int _git_history_menu()
{
   say('_git_history_menu');
   return 0;
}
*/

/**
 * Adds the menu to the history dialog
 */
static void git_history_add_menu()
{
   int index=find_index("_git_history_menu",oi2type(OI_MENU));
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
static int _GitFillInHistory(_str filename)
{
   // find out if this file is actually in the repository root 
   _str repositoryRoot = '';
   boolean isGitFile = IsGitPath(filename, repositoryRoot);
   if (isGitFile == false) {
      _message_box('The file 'filename' cannot be diffed because it is not within a working tree.');
      return -1;
   }
   // get the git relative file name
   _str remote_filename = substr(filename, repositoryRoot._length() + 1);
   // translate and \ chars into /
   remote_filename = stranslate(remote_filename, '/', '\');

   GIT_LOG_INFO logInfo;
   int status=_GitGetLogInfoForFile(filename, logInfo);
   if ( status ) {
      _message_box(nls("This file may not exist in the repository"));
      return -2;
   }
   GIT_FILE_STATUS fileStatus;
   _GitGetFileStatus(filename, fileStatus);
   logInfo.WorkingFile = fileStatus.filename;
   logInfo.Head = '';
   logInfo.CurBranch = _GitGetCurrentBranch(repositoryRoot);
   logInfo.State = fileStatus.state;
   _str remoteRepository = _GitGetUrlForLocalRepository(repositoryRoot, true);
   _str line[]=null;
   line[line._length()]='<B>Filename:</B> 'logInfo.WorkingFile;
   line[line._length()]='<B>Branch:</B> 'logInfo.CurBranch;
   line[line._length()]='<B>Repository:</B> 'remoteRepository;
   if (fileStatus.state != GIT_UNCHANGED) {
      line[line._length()]='<B>Status:</B> <FONT color="red">'GitFileStateToString(fileStatus.state)'</FONT>';
   } else {
      line[line._length()]='<B>Status:</B> 'GitFileStateToString(fileStatus.state);
   } 
   ctlrefresh.p_visible=false;
   ctlupdate.p_visible=false;
   ctlrevert.p_visible=false;
   ctlview.p_x=ctlrefresh.p_x;
    
   int wid=p_window_id;
   p_active_form.p_caption = 'Git history for 'fileStatus.filename;
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
      int index=_TreeAddItem(TREE_ROOT_INDEX,logInfo.VersionList[i].Subject,TREE_ADD_AS_CHILD,_pic_file,_pic_file,TREE_NODE_LEAF);
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

static void SetVersionInfo(int index, GIT_VERSION_INFO versionInfo)
{
   _str line = '';
   line = '<B>Author:</B> 'versionInfo.Author'<br>';
   if (versionInfo.Committer != '' && versionInfo.Author != versionInfo.Committer) {
      line :+= '<B>Committer:</B> 'versionInfo.Committer'<br>';
   }
   line :+= '<B>Date:</B> 'versionInfo.Date'<br>';
   line :+= '<B>Revision:</B> ' :+ versionInfo.RevisionNumber'<br>';
   line :+= '<B>Comment:</B> ' :+ versionInfo.Subject'<br>'versionInfo.Body;
   // assign this to the tree node
   _TreeSetUserInfo(index, line);
}


