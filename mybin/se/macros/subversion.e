////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49430 $
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
#include "cvs.sh"
#include "xml.sh"
#include "scc.sh"
#include "diff.sh"
#include "minihtml.sh"
#include "filewatch.sh"
#include "svc.sh"
#import "cvs.e"
#import "cvsutil.e"
#import "diff.e"
#import "files.e"
#import "filewatch.e"
#import "guiopen.e"
#import "main.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "projconv.e"
#import "saveload.e"
#import "sellist.e"
#import "sellist2.e"
#import "subversionutil.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "toast.e"
#require "sc/lang/String.e"

#require  "se/datetime/DateTime.e"
#import  "se/vc/VCCacheManager.e"
#require  "se/vc/VCRepositoryCache.e"
#import  "se/vc/VCBaseRevisionItem.e"
#require  "se/vc/VCBranch.e"
#import  "se/vc/VCCacheExterns.e"
#import  "se/vc/VCExclusion.e"
#import  "se/vc/VCFile.e"
#import  "se/vc/VCFileType.e"
#import  "se/vc/VCInfo.e"
#import  "se/vc/VCLabel.e"
#import  "se/vc/VCRepository.e"
#import  "se/vc/VCRevision.e"
#import  "se/vc/SVNCache.e"
#import  "se/vc/QueuedVCCommand.e"
#require  "se/vc/QueuedVCCommandManager.e"

#import "svc.e"
#import "treeview.e"
#import "tags.e"
#import "varedit.e"
#import "vc.e"
#import "wkspace.e"
#endregion

using sc.lang.String;
using se.vc.vccache.VCBranch;
using se.vc.vccache.VCFile;
using se.vc.vccache.VCLabel;
using se.vc.vccache.VCRepositoryCache;
using se.vc.vccache.VCBaseRevisionItem;
using se.vc.vccache.VCRevision;
using se.vc.vccache.QueuedVCCommandManager;
using se.vc.vccache.QueuedVCCommand;
using se.datetime.DateTime;

_str def_svn_other_branches="";

#define SUBVERSION_ENTRIES_FILENAME 'entries'
#define SUBVERSION_STATUS_VERSION_PREFIX 'Status against revision:'
#define VCSYSTEM_TITLE_SUBVERSION "Subversion"

QueuedVCCommandManager gQueuedVCCommandManager = null;

// This is a table of valid URLs.  These are reset every time we start the editor
// This is used for the history dialog for mapping URLs to local paths
static boolean gValidLocalPathTable:[];

definit()
{
   if ( def_svn_info==null ) {
      SVNInit(def_svn_info);
   }
   if ( upcase(arg(1))!='L' ) {
#if 0 //1:15pm 4/1/2013
      QueuedVCCommandManager newMgr();
      gQueuedVCCommandManager = newMgr;
      gQueuedVCCommandManager.start();
#endif

      gValidLocalPathTable = null;
   }
}

/**
 * Initialize all of the global data that we need to keep.
 *
 * @param def_cvs_info
 */
static void SVNInit(SVN_SETUP_INFO &svn_info)
{
   svn_info.svn_exe_name=SVN_EXE_NAME;
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
static boolean IsSVNFile(_str filename)
{
   filename=absolute(filename);
   _str path=filename;
   if ( !isdirectory(path) ) {
      path=_strip_filename(filename,'N');
   }
   String StdOutData,StdErrData;
   relativeFilename := relative(filename,path);
   status:=_CVSPipeProcess(_SVNGetExeAndOptions():+" info --xml ":+maybe_quote_filename(relativeFilename),
                           path,'P'def_cvs_shell_options,StdOutData,StdErrData,
                           false,null,null,null,-1,false,false);
   if ( status < 0 ) {
      return false;
   }
   if ( StdErrData.beginsWith("cygwin warning:") ) {
      StdErrData.makeEmpty();
   }
   // 10/28/2011
   // This will work, but in the interest of performance we will initially try
   // something lighter weight and see how it behaves
#if 0 //3:54pm 10/28/2011
   // If there is an error, this will not be valid XML
   origWID := _create_temp_view(auto tempWID);
   tempWID._insert_text(StdOutData);
   p_window_id = origWID;
   xmlHandle := _xmlcfg_open_from_buffer(tempWID,status);
   isSVN := false;
   if ( xmlHandle>=0 && !status ) {
      isSVN = true;
      _xmlcfg_close(xmlHandle);
   }
   _delete_temp_view(tempWID);
#else
   // 10/28/2011 this is a file checked out from subversion if there is data 
   // in the stdout output and not in the stderr output
   isSVN := (StdOutData.isNotEmpty() && StdErrData.isEmpty() );
   return(isSVN);
#endif
   return(false);
}

/**
 * Returns the name/path of the Subversion executable that we are configured to use.
 * If that is not found, we look for one in the path
 * @return Name of the Subversion executable
 */
_str _SVNGetSVNExeName()
{
   _str exe_name=def_svn_info.svn_exe_name;
   if ( !file_exists(exe_name)=='' ) {
#if __UNIX__
      exe_name=def_svn_info.svn_exe_name;
#else
      exe_name="svn.exe";
#endif
      exe_name=path_search(exe_name);
   }

   return(exe_name);
}

/**
 * Callback that is passed to _CVSCommand to build a "commit" command
 *
 * @param pinfo callback data - options for the commit command
 * @param output_filename - file to write output from command to
 * @param append_to_output - set to true if the output should be appended to rather
 *                           than overwritten
 *
 * @return string for commit command
 */
static _str SVNBuildCommitCommand(CVS_COMMIT_CALLBACK_INFO *pinfo,_str output_filename,boolean append_to_output)
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
   return(_SVNGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 commit 'comment_opt' 'pinfo->commit_options' ');
}

/**
 * Callback that is passed to _CVSCommand to build a "update" command
 *
 * @param pinfo callback data - options for the update command
 * @param output_filename - file to write output from command to
 * @param append_to_output - set to true if the output should be appended to rather
 *                           than overwritten
 *
 * @return string for update command
 */
static _str SVNBuildUpdateCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str update_options=*pdata;
   _str command=_SVNGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 --non-interactive update 'update_options' ';
   return(command);
}

/**
 * Callback that is passed to _CVSCommand to build a "add" command
 *
 * @param pinfo callback data - options for the add command
 * @param output_filename - file to write output from command to
 * @param append_to_output - set to true if the output should be appended to rather
 *                           than overwritten
 *
 * @return string for add command
 */
static _str SVNBuildAddCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str add_options=*pdata;
   return(_SVNGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 add --depth empty 'add_options' ');
}

/**
 * Callback that is passed to _CVSCommand to build a "remove" command
 *
 * @param pinfo callback data - options for the remove command
 * @param output_filename - file to write output from command to
 * @param append_to_output - set to true if the output should be appended to rather
 *                           than overwritten
 *
 * @return string for remove command
 */
static _str SVNBuildRemoveCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str add_options=*pdata;
   return(_SVNGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 remove --force 'add_options' ');
}

/**
 * Given <b>filename</b> returns the appropriate ".svn" path
 *
 * @param filename file to find .svn path for
 *
 * @return _str the appropriate ".svn" path for <b>filename</b>
 */
_str _SVNGetLocalSVNPath(_str filename)
{
   _str file_path=_file_path(filename);
   _str svn_path=file_path;
   _maybe_append_filesep(svn_path);
   svn_path=svn_path:+SUBVERSION_CHILD_DIR_NAME;
   _maybe_append_filesep(svn_path);
   return(svn_path);
}

/**
 * Given <b>filename</b> returns the appropriate ".svn/entries" filename
 *
 * @param filename file to find the entries file for
 *
 * @return _str the appropriate ".svn/entries" path for <b>filename</b>
 */
_str _SVNGetEntriesFilename(_str filename)
{
   _str svn_path=_SVNGetLocalSVNPath(filename);
   _str entries_filename=svn_path:+SUBVERSION_ENTRIES_FILENAME;
   return(entries_filename);
}

/**
 * Given a <b>filename</b> and an <b>attribute_name</b>, finds <b>filename</b> in the entries
 * file and returns the value of <b>attribute_name</b> in <b>entry_attribute</b>
 * @param filename a source file to get an entry for
 * @param attribute_name name of the attribute to get
 * @param entry_attribute attribute value is returned here
 * @deprecated Use _SVNGetAttributeFromCommand instead - this
 *             funciton is not compatible with Subversion 1.4
 *
 * @return int 0 if successful
 */
int _SVNGetEntryAttribute(_str filename,_str attribute_name,_str &entry_attribute)
{
   entry_attribute="";
   _str entries_filename=_SVNGetEntriesFilename(filename);
   int status=0;
   int xml_handle=_xmlcfg_open(entries_filename,status,VSXMLCFG_OPEN_ADD_PCDATA|VSENCODING_AUTOXML);
   if ( xml_handle>-1 ) {
      _str filename_for_xpath=_strip_filename(filename,'P');
      _str xpath="/wc-entries/entry[@name='"filename_for_xpath"']";
      int xml_node_index=_xmlcfg_find_simple(xml_handle,xpath);
      if ( xml_node_index<0 && filename_for_xpath=="" ) {
         // If filename_for_xpath is "", we must be looking at the directory
         // entry.  One customer had an entries file that had the following for
         // the name.
         xpath="/wc-entries/entry[@name='svn:this_dir']";
         xml_node_index=_xmlcfg_find_simple(xml_handle,xpath);
      }
      if ( xml_node_index>-1 ) {
         entry_attribute=_xmlcfg_get_attribute(xml_handle,xml_node_index,attribute_name);
         status=0;
      }else{
         status=xml_node_index;
         status=_SVNGetAttributeFromCommand(filename,attribute_name,entry_attribute);
      }
      _xmlcfg_close(xml_handle);
   }
   return(status);
}

/**
 * Prior to version Subversion 1.4 _SVNGetEntryAttribute would
 * open the .svn/entries file directly.  In Subversion 1.4 this
 * file is no longer XML but a more proprietary format, so we
 * use the "svn info" command to get these
 * @param filename
 * @param attribute_name name of the attribute to look for must
 *                       be cased the same as in the output from
 *                       "svn info", but not have the trailing
 *                       ':'
 * @param entry_attribute
 *
 * @return int
 */
int _SVNGetAttributeFromCommand(_str filename,_str attribute_name,_str &entry_attribute)
{
   // Keep the original directory
   _str origdir=getcwd();
   entry_attribute="";
   String StdOutData,StdErrData;
   status := 0;
   remote := IsSVNRemoteFile(filename);
   curErrData := StdErrData.get();

   do {
      _str path=_file_path(filename);
      if ( path!="" && !remote ) {
         // Change to the directory that that file is in.
         status = chdir(path,1);
      }
      if ( status ) {
         return status;
      }
      rfilename := "";
      if ( !remote ) {
         rfilename = _strip_filename(filename,'P');
      }else{
         rfilename = filename;
      }

      _str command=_SVNGetExeAndOptions()' info 'maybe_quote_filename(rfilename);

      status=_CVSPipeProcess(command,path,'P'def_cvs_shell_options,StdOutData,StdErrData,
                             false,null,null,null,-1,false,false);
   
      //say('_SVNGetAttributeFromCommand StdErrData='StdErrData);
      //say('p='pos("(is not a working copy)",StdErrData,1,'r'));
      if (status || pos("(Not a versioned resource)",StdOutData.get()) 
          || pos("(is not a working copy)",StdErrData.get(),1,'r') ) {
         if (!status) status=1;
         break;
      }
      if ( pos("svn: This client is too old to work with working copy",StdErrData) ) {
         return(INCORRECT_VERSION_RC);
      }
      _str outdata=StdOutData.get();
   
      nl := "";
      if ( pos("\r\n",outdata) ) {
         nl = "\r\n";
      }else{
         nl = "\n";
      }
   
   //   _str nl="\n";
   //#if !__UNIX__
   //   // Use \r\n on Windows
   //   nl="\r\n";
   //#endif
   
      // Check for errors
      _str curLine="";
      parse curErrData with curLine (nl) curErrData;
      if (isinteger(curLine)) {
         status=(int)curLine;
         break;
      }
   
      int attribute_name_len=length(attribute_name);
      for (;;) {
         parse outdata with curLine (nl) outdata;
         if ( curLine=="" ) break;
         _str curField=substr(curLine,1,attribute_name_len+1);
         if ( curField==attribute_name:+':' ) {
   
            // Use +2 because we have to strip ':' too
            entry_attribute=substr(curLine,attribute_name_len+2);
   
            // Strip any whitespace
            entry_attribute=strip(entry_attribute);
            break;
         }
      }
   } while (false);
   // Change back to original directory, we had changed to the directory the 
   // file was in
   chdirStatus := chdir(origdir,1);
   if ( chdirStatus ) status = chdirStatus;
   // Use a separate status, we don't want a 0 (good) status from chdir to 
   // supercede an earlier failure.

   return status;
}

/**
 * Run the log command for <b>filename</b> and put the results in <b>ErrorFilename</b>.
 * Uses the --stop-on-copy option right now
 * @param filename file to get log info for
 * @param temp_view_id view id opened with <b>ErrorFilename</B>
 * @param OutputFilename file that the output is redirected into
 * @param quiet if true, do not display error messages
 *
 * @return int 0 if successful
 */
int _SVNGetLogInfoForFile(_str filename,int &temp_view_id,boolean quiet=false,_str logOption="")
{
   _str remote_filename;
   int status=0;
   if ( IsSVNRemoteFile(filename) ) {
      remote_filename = filename;
   }else{
      status = _SVNGetFileURL(filename,remote_filename);
   }
   if ( status ) {
      return(status);
   }
   String StdOutData,StdErrData;
   commandString := " log --xml -v ";
   if ( !(def_svn_flags&SVN_FLAG_DO_NOT_USE_STOP_ON_COPY) ) {
      commandString = commandString:+" --stop-on-copy ";
   }
   status=_CVSPipeProcess(_SVNGetExeAndOptions():+commandString:+logOption:+" ":+maybe_quote_filename(remote_filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                          false,null,null,null,-1,false,false);
   if ( status ) {
      if ( !quiet ) {
         _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_RC,_SVNGetSVNExeName(),"log",status));
      }
      _SVCDisplayErrorOutputFromString(StdErrData,status);
      return(status);
   }
   int orig_wid=_create_temp_view(temp_view_id);
   _insert_text(StdOutData.get());

   p_window_id=orig_wid;
   return(status);
}

/**
 * @param filename Filename that may be a local filename or a 
 *                 subversion filename
 * 
 * @return boolean true if this is a remote subversion file 
 *         (note: "file://" is remote)
 */
static boolean IsSVNRemoteFile(_str filename)
{
   substr7 := substr(filename,1,7);
   return substr(filename,1,6)=="svn://"|| 
      substr7=="http://"||
      substr7=="file://"||
      substr(filename,1,9)=="svn+ssh://";
}

static _str getSortedListofAffectedFiles(VCFile (&affectedFiles)[])
{
   _str affectedPathsArray[];
   _str affectedPaths = "";
   if ( affectedFiles._length()>0 ) {
      VCFile curAffectedFile;
      foreach ( curAffectedFile in affectedFiles ) {
         // use substr to trim the leading '/' for formatting.
         //affectedPaths = affectedPaths:+
         affectedPathsArray[affectedPathsArray._length()] = substr(curAffectedFile.get_FileSpec(),2);
      }
      affectedPathsArray._sort('F');
   }
   foreach ( auto curItem in affectedPathsArray ) {
      affectedPaths = affectedPaths:+curItem:+"\n";
   }
   return affectedPaths;
}

static int getIndexForVersion(VCLabel &curLabel,int posInBranch,int branchIndex)
{
   index := -1;
   childIndex := _TreeGetFirstChildIndex(branchIndex);
   if ( childIndex>-1 ) {
      lastIndex := childIndex;
      for ( ;; ) {
         _TreeGetInfo(childIndex,auto state,auto bm1);
         if ( bm1!=_pic_branch ) {
            curVer := substr(_TreeGetCaption(childIndex),2);
            if ( isinteger(curVer) && (int)curVer > posInBranch ) {
               break;
            }
            lastIndex = childIndex;
         }
         childIndex = _TreeGetNextSiblingIndex(childIndex);
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

static void addLabelToBranch(VCLabel &curLabel,int posInBranch,int branchIndex)
{
   childIndex := _TreeGetFirstChildIndex(branchIndex);
   if ( childIndex>-1 ) {
      lastIndex := childIndex;
      for ( ;; ) {
         _TreeGetInfo(childIndex,auto state,auto bm1);
         if ( bm1!=_pic_branch ) {
            curVer := substr(_TreeGetCaption(childIndex),2);
            if ( isinteger(curVer) && (int)curVer > posInBranch ) {
               break;
            }
            lastIndex = childIndex;
         }
         childIndex = _TreeGetNextSiblingIndex(childIndex);
         if ( childIndex<0 ) break;
      }
      if ( lastIndex>-1 ) {
         cap := _TreeGetCaption(lastIndex);
         parse cap with cap ' -- (' auto labels ')';
         if ( labels!='' ) labels = labels:+', ';
         labels = labels:+curLabel.get_Name();
         _TreeSetCaption(lastIndex,cap' -- ('labels')');
      }
   }
}

/**
 * Add branch URL to the table, and and all the parent branches 
 * too. 
 */
static void addBranchToURLTable(_str branchName,_str repositoryRoot,_str (&branchToURLTable):[])
{
   _maybe_strip(repositoryRoot,'/');
   branchToURLTable:[repositoryRoot:+branchName'/'] = branchName'/';
}

static void addLabelsToURLTable(VCLabel (&labels)[], _str repositoryRoot,_str (&branchToURLTable):[])
{
   _maybe_strip(repositoryRoot,'/');
   VCLabel curLabel;
   foreach ( curLabel in labels ) {
      labelName := curLabel.get_Name();
      branchToURLTable:[repositoryRoot:+labelName'/'] = labelName'/';
   }
}

static void populateTreeFromCache(_str filename,VCRepositoryCache& cache,VCBaseRevisionItem& item,VCLabel(&labels)[],
                                  int (&revisionList)[],
                                  int (&revisionIndexList):[],
                                  int (&branchTable):[],
                                  _str (&URLToBranchTable):[],
                                  int(&indexTable):[]=null,
                                  int relIndex=TREE_ROOT_INDEX,int treeAddFlags=TREE_ADD_AS_CHILD)
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

      repositoryRoot := _GetDialogInfoHt("repositoryRoot");
      addBranchToURLTable(branchName,repositoryRoot,URLToBranchTable);
      branchIndex := _TreeAddItem(relIndex,branchName,treeAddFlags,_pic_branch,_pic_branch,expandBranch);

      branchTable:[branch.get_BranchID()] = branchIndex;
      for (i = 0; i < numChildren; i++) {
         //printRevisionTreeItem(*branch.getChildItem(i), padding:+"  ");
         populateTreeFromCache(filename,cache,*branch.getChildItem(i),labels,revisionList,revisionIndexList,branchTable,URLToBranchTable,indexTable,branchIndex,TREE_ADD_AS_CHILD);
      }
   } else if (item instanceof VCRevision) {
      // if this is a revision item, then print the details for it
      VCRevision revision = (VCRevision)item;
      //say(padding"R- "revision.get_HistoryInsertionNumber()", "revision.get_Number()", "revision.get_Author()", "revision.get_Timestamp()"): "revision.get_Comments());
      revisionNumber := revision.get_Number();
      revisionIndex := _TreeAddItem(relIndex,'r':+revisionNumber,treeAddFlags,_pic_file,_pic_file,-1);
      indexTable:[revisionNumber] = revisionIndex;
      
      _str lineArray[];
      lineArray[0]='<B>Author:</B>&nbsp;'revision.get_Author()'<br>';
      formattedDate := SVNGetFormattedDate(revision.get_Timestamp());
      DateTime revisionDate = DateTime.fromString(formattedDate);
      lineArray[lineArray._length()]='<B>Date:</B>&nbsp;'revisionDate.toStringLocal()'<br>';
      _str rawComments = revision.get_Comments();
      _str commentsBR = stranslate(rawComments, '<br>', '\n', 'l');
      lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentsBR;

      revisionID := revision.get_RevisionID();
      revisionList[revisionList._length()] = revisionID;
      revisionIndexList:[revisionID] = revisionIndex;
      _TreeSetUserInfo(revisionIndex,lineArray);
   }
}

/**
 * @param unformattedDate unformatted date from 
 *                        VCBaseRevisionItem.get_Timestamp()
 * 
 * @return _str Date in a string format accepted by DateTime.fromString() 
 *         formatted YYYY-MM-DD
 *         <B>T</B>HH:MM:SS.SSS<B>Z</B>
 */
static _str SVNGetFormattedDate(_str unformattedDate)
{
   formattedDate := substr(unformattedDate,1,4):+'-':+substr(unformattedDate,5,2):+'-'\
      :+substr(unformattedDate,7,2):+' T':+substr(unformattedDate,9,2):+':'\
      :+substr(unformattedDate,11,2):+':':+substr(unformattedDate,13,2):+'.'\
      :+substr(unformattedDate,15)'Z';
   return formattedDate;
}

void _before_write_state_SVNCache()
{
   if ( gQueuedVCCommandManager!=null ) gQueuedVCCommandManager.prepareForWriteState();
}

void _after_write_state_SVNCache()
{
   if ( gQueuedVCCommandManager!=null ) gQueuedVCCommandManager.recoverFromWriteState();
}

void _exit_SVNCache()
{
   gQueuedVCCommandManager = null;
}

_command void reset_queued_command_mgr() name_info(',')
{
   gQueuedVCCommandManager=null;
}

_command void show_queued_command_mgr() name_info(',')
{
   if ( gQueuedVCCommandManager==null ) {
   }
   _dump_var(gQueuedVCCommandManager);
}

/**
 * 
 * 
 * @param command commmand to run when finished updating cache
 * @param filename filename to run <B>command</B> on
 * @param repositoryRoot Root of repository for <B>filename</B> 
 * @param runOldHistory will be set to true if the user wants to run the old 
 *                      history command while this runs.
 * 
 * @return boolean true if update is being performed asynchronously
 */
static boolean SVNCacheUpdateCommand(_str command,_str filename,_str repositoryRoot,boolean &runOldHistory)
{
   runOldHistory = false;
   requiresAsyncUpdate := false;
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(repositoryRoot);
   if ( gQueuedVCCommandManager.cacheUpdatePending(repositoryRoot,auto pcurVCCommand=null) ) {
      result := _message_box(nls("The version cache required for '%s' is currently being built.  The command you requested will be run when the version cache has finished building.\n\nWould you like to launch the non-branch history facility now?",filename,command),"",MB_YESNO);
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
         result := _message_box(nls("Before showing history for '%s', a version cache must be built for %s.  The command you requested will be run when the version cache has finished building.\n\nWould you like to launch the non-branch history facility now?",filename,repositoryRoot),"",MB_YESNO);
         runOldHistory = (result==IDYES);
         cache.updateVersionCache(true);
         QueuedVCCommand vcCommand(cache,command,filename,repositoryRoot);
         gQueuedVCCommandManager.add(vcCommand);
         // show an alert
         _str msg = 'Sync for SVN repository 'cache.get_RepositoryUrl()' has started.';
         _ActivateAlert(ALERT_GRP_BACKGROUND_ALERTS, ALERT_SVN_CACHE_SYNC, msg);
      }else{
         cache.updateVersionCache(false);
      }
   }

   return requiresAsyncUpdate;
}
/**
 * Return the last path in the URL
 * 
 * @param URL Subversion URL
 * 
 * @return _str last path in <B>URL</B>
 */
static _str svnGetLastPath(_str URL)
{
   curURL := URL;
   _maybe_strip(curURL,'/');
   p := lastpos('/',curURL);
   if ( p ) {
      curURL = substr(curURL,p+1);
   }
   return curURL;
}

/**
 * @param URL Subversion URL
 * 
 * @return _str <B>URL</B> with the last path removed
 */
static _str svnStripLastPath(_str URL)
{
   curURL := URL;
   _maybe_strip(curURL,'/');
   curURL = _file_path(curURL);
   return curURL;
}

static boolean svnIsCheckedoutPath(_str localPath,_str URL)
{
   urlExists := false;
   if ( gValidLocalPathTable:[_file_case(localPath)]==null ) {
      
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
      gValidLocalPathTable:[_file_case(localPath)] = urlExists;
   }else{
      urlExists = gValidLocalPathTable:[_file_case(localPath)];
   }
   return urlExists;
}

/** 
 * Find mapping b/w local filename and svn URL 
 * 
 * @param curFilename_str filename from history dialog
 * @param URL_str SVN URL from history dialog
 * @param repositoryRoot_str Repository root from _SVNGetBranchForLocalFile()
 * @param localMapDir_str local directory returned here
 * @param remoteMapDir_str remove directory returned here
 */
static void getURLMapping(_str curFilename,_str URL,_str repositoryRoot_str,_str &localMapDir_str,_str &remoteMapDir_str)
{
   localMapDir := _file_path(curFilename);
   remoteMapDir := _file_path(URL);

   // We are going to take our map points from the last place we matched on a '/'
   // char, so we need to save these
   lastGoodLocalMapDir := localMapDir;
   lastGoodRemoteMapDir := remoteMapDir;

   for ( ;; ) {
      if ( localMapDir=="" || remoteMapDir=="" ) break;

      if ( !svnIsCheckedoutPath(localMapDir,remoteMapDir) ) break;
      
      // Save the last good paths, when we know to stop the paths we have will
      // already be invalid
      lastGoodLocalMapDir = localMapDir;
      lastGoodRemoteMapDir = remoteMapDir;

      // Set the paths to the parents of the current paths
      localMapDir = _parent_path(localMapDir);
      remoteMapDir = svnStripLastPath(remoteMapDir);
   }

   localMapDir  = lastGoodLocalMapDir;
   remoteMapDir = lastGoodRemoteMapDir;

   _maybe_append_filesep(localMapDir);
   localMapDir_str = localMapDir;

   _maybe_append(remoteMapDir,'/');
   remoteMapDir_str = remoteMapDir;
}

#define SHOW_AFFECTED_FILES_HTML "<BR><A href=\"fillInAffectedFiles\">Show Affected Files</A>"

/** 
 * Added affected paths for a version to the HTML pane at the bottom of the 
 * history dialog 
 * 
 * @param cache cache instance for this repository
 * @param revisionList List of revision IDs from VCRevision.get_RevisionID()
 * @param revisionIndexTable Table of treeview node indexes, indexed by revision 
 *                           ID (returned from VCRevision.get_RevisionID() )
 * @param repositoryRoot string for repository root (beginning of URL)
 */
static void deferAffectedFiles(VCRepositoryCache &cache,
                               int (&revisionList)[],
                               int (&revisionIndexTable):[],
                               _str repositoryRoot,
                               _str filename,
                               _str URL)
{
   treeIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for ( ;; ) {
      if ( treeIndex<0 ) break;

      curArray := _TreeGetUserInfo(treeIndex);
      curArray[curArray._length()] = SHOW_AFFECTED_FILES_HTML;
      _TreeSetUserInfo(treeIndex,curArray);

      treeIndex = _TreeGetNextIndex(treeIndex);
   }
   _SetDialogInfoHt("cache",cache);
   _SetDialogInfoHt("revisionList",revisionList);
   _SetDialogInfoHt("revisionIndexTable",revisionIndexTable);
   _SetDialogInfoHt("repositoryRoot",repositoryRoot);
   _SetDialogInfoHt("URL",URL);

}

void _SVNFillInAffectedFiles()
{
   VCRepositoryCache cache;
   int revisionList[];
   int revisionIndexTable:[];
   _str repositoryRoot;
   _str filename;
   _str URL;

   cache = _GetDialogInfoHt("cache");
   revisionList = _GetDialogInfoHt("revisionList");
   revisionIndexTable = _GetDialogInfoHt("revisionIndexTable");
   repositoryRoot = _GetDialogInfoHt("repositoryRoot");
   URL = _GetDialogInfoHt("URL");
   filename=SVNGetFilenameFromHistoryDialog();

   mou_hour_glass(1);
   getURLMapping(filename,URL,repositoryRoot,auto localMapDir,auto remoteMapDir);

   VCFile fileHash:[][];
   status := cache.getFilesForRevisionSet(revisionList,fileHash);
   if ( !status ) {
      int revisionID;
      VCFile files[];
      foreach ( revisionID => files in fileHash ) {
         _str fileArray[];
         fileArray[0] = "<BR><B>Files affected:</B><UL>";
         len := files._length();
         for ( i:=0;i<len;++i ) {
            curFileSpec := files[i].get_FileSpec();

            curFilename := substr(curFileSpec,2);

            localFilename := localMapDir:+_strip_filename(curFilename,'P');
            localFilename = stranslate(localFilename,FILESEP,'/');
            if ( file_eq(filename,localFilename) ) {
               fileArray[fileArray._length()] = "<LI>":+curFilename:+"</LI>\n";
            }else{
               fileArray[fileArray._length()] = "<LI><A href=\"":+localFilename:+"\">":+curFilename:+"</A></LI>\n";
            }
         }
         treeIndex := revisionIndexTable:[revisionID];
         fileArray[fileArray._length()] = "</UL>";

         if ( treeIndex!=null ) {
            if ( fileArray._length() ) {
               setUserInfo(treeIndex,fileArray);
            }
         }
      }
   }
   ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   mou_hour_glass(0);
}


static void setUserInfo(int treeIndex,STRARRAY &oneFileArray)
{
   int wid=p_window_id;
   _nocheck _control ctltree1;
   p_window_id=ctltree1;
   existingFileArray := _TreeGetUserInfo(treeIndex);
   len := oneFileArray._length();
   existingFileArrayLen := existingFileArray._length();
   int i;
   for ( i=existingFileArrayLen;i>-1;--i ) {
      if ( existingFileArray[i]==SHOW_AFFECTED_FILES_HTML ) {
         existingFileArray._deleteel(i);
         --existingFileArrayLen;
         break;
      }
   }
   for ( i=0;i<len;++i ) {
      existingFileArray[existingFileArray._length()] = oneFileArray[i];
   }
   _TreeSetUserInfo(treeIndex,existingFileArray);
   p_window_id=wid;
}

/** 
 * 
 * 
 * @param labels
 * @param branchTable
 * 
 * @return typeless
 */
static void addTagsToTree(VCLabel (&labels)[],int(&branchTable):[],_str &labelText) 
{
   VCLabel curLabel;
   foreach ( curLabel in labels ) {
      parentBranchID := curLabel.get_ParentBranchID();
      posInBranch    := curLabel.get_HistoryInsertionNumber();
      branchIndex := branchTable:[parentBranchID];
      if ( branchIndex!=null ) {
         index := ctltree1.getIndexForVersion(curLabel,(int)posInBranch,(int)branchIndex);
         labelText = labelText:+"<P><A href=\"":+index:+"\">":+curLabel.get_Name():+"<A>";
         if ( def_svn_flags&SVN_FLAG_SHOW_LABELS_IN_HISTORY ) {
            // Have to check this flag here because even if this flag is off we 
            // this is where labelText gets set
            if ( index<0 ) {
               // If there are no items, put the tag right on the branch
               index = branchIndex;
            }
            if ( index>-1 ) {
               curCap := _TreeGetCaption(index);
               tags   := "";
               if ( last_char(curCap)==')' ) {
                  parse curCap with curCap '(' tags ')';
                  tags = tags:+', ';
               }
               _TreeSetCaption(index,strip(curCap):+' (':+strip(tags):+curLabel.get_Name():+')');
            }
         }
      }
   }
}

/** 
 * Hide branches that do not have children 
 *  
 * @param branchTable tree indexes of branches
 */
static void hideEmptyBranches(int(&branchTable):[])
{
   int curIndex;
   _str hashIndex = "";
   int hiddenIndexes[];

   foreach ( hashIndex => curIndex in branchTable ) {
      if ( curIndex!=null ) {
         childIndex := _TreeGetFirstChildIndex(curIndex);
         if ( childIndex<0 ) {
            _TreeGetInfo(curIndex,auto ShowChildren,auto NonCurrentBMIndex,auto CurrentBMIndex,auto moreFlags);
            _TreeSetInfo(curIndex,ShowChildren,NonCurrentBMIndex,CurrentBMIndex,moreFlags|TREENODE_HIDDEN);
            hiddenIndexes[hiddenIndexes._length()] = curIndex;
         }
      }
   }
   _SetDialogInfoHt("hiddenIndexes",hiddenIndexes);
}

/**
 * Display the Subversion history dialog for <b>filename</b>
 * @param filename file to display Subversion history dialog for.  If this is
 *        '', uses the current buffer.  If there is no window open, it will
 *        display an open file dialog
 * @param quiet if true, do not display error messages
 * @param version if this is not null, it will set the current tree node in the
 *        dialog to this version
 * @param updateCache if false, do not attempt to update version cache
 *
 * @return int 0 if successful
 */
_command int svn_new_history(_str filename='',boolean quiet=false,
                             _str version=null,boolean updateCache=true,
                             boolean forceShowBranches=false) name_info(FILE_ARG'*,')
{
   if ( filename=='' ) {
      _str bufname='';
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
   if ( !isdirectory(filename) ) {
       if ( !file_exists(filename) ) {
          _message_box(get_message(FILE_NOT_FOUND_RC));
          return(1);
       }
       if ( !IsSVNFile(filename) ) {
          _message_box(get_message(SVN_FILE_NOT_CONTROLLED_RC,get_message(SVN_APP_NAME_RC)));
          return(1);
       }
   }

   _nocheck _control ctltree1;
   int wid=show('-new -hidden -xy _cvs_history_form');
   wid.p_caption=VCSYSTEM_TITLE_SUBVERSION' info for 'filename;
   int branchIndexes:[];
   int retVal = _SVNGetBranchForLocalFile(filename,auto branchName,auto repositoryRoot,auto subFilename);
   if (retVal != 0) {
      _message_box('SVN is currently unable to get information about this file.');
      return 0;
   }
   // detemrine if the user has a recent enough version of SVN to use vccacheupdtr
   isSvnVersionOK := isSvnVersionOkForVCCache();
   showBranches   := forceShowBranches; 
   if ( isSvnVersionOK && !forceShowBranches ) {
      // First be sure ther version of SVN supports history with branches, then
      // find out if the user wants to use them (this may prompt the user)
      status := getSVNShowBranches(showBranches);
      if ( status ) return status;
   }
   if ( !isSvnVersionOK || !showBranches ) {
      // if not, then just run the older version of svn-history
      svn_history(maybe_quote_filename(filename),quiet,version,false);
      return 0;
   }
   // try to update the cache, and maybe show the old dialog in the meantime
   if ( updateCache && SVNCacheUpdateCommand("svn_new_history",filename,repositoryRoot,auto runOldHistory) ) {
      if ( runOldHistory ) {
         svn_history(filename,quiet,version,false);
      }
      return 0;
   }
   wid.SVNFillProperHistory(filename,repositoryRoot,branchName,branchIndexes,quiet);
   if ( version!=null ) {
      int index=wid.ctltree1._TreeSearch(TREE_ROOT_INDEX,version,'T');
      if ( index>-1 ) {
         wid.ctltree1._TreeSetCurIndex(index);
      }
   }
   wid.p_visible = 1;

   return(0);
}

/**
 * Fills tree control in either from "old style" history, or 
 * using version cache 
 */
static void SVNFillProperHistory(_str filename,_str repositoryRoot,_str branchName,int(&branchIndexes):[],boolean quiet)
{
   boolean populateOldHistory = true;
   if ( def_svn_flags&SVN_FLAG_SHOW_BRANCHES ) {
      VCBranch root;
      VCLabel labels[];
      VCRepositoryCache cache = g_svnCacheManager.getSvnCache(repositoryRoot);

      status := cache.getRevisions(filename,root,labels,true);
      if ((root != null) && (root.getChildItemCount() > 0)) {
         minihtmlWID := _find_control("ctlminihtml1");
         minihtmlWID.SVNSetFileInfo(filename,auto URL,auto revision);
   
         int revisionList[];
         int revisionIndexTable:[];
         origWID := p_window_id;
         ctlTree1WID := _find_control("ctltree1");
         p_window_id = ctlTree1WID;
   
         _SetDialogInfoHt("repositoryRoot",repositoryRoot);
         populateTreeFromCache(filename,cache,root,labels,revisionList,revisionIndexTable,auto branchTable,auto URLToBranchTable,auto htmlText);
         _SetDialogInfoHt("URLToBranchTable",URLToBranchTable);
         deferAffectedFiles(cache,revisionList,revisionIndexTable,repositoryRoot,filename,URL);
         selectRevisionInTree(revision);
         addTagsToTree(labels, branchTable,auto labelText);
         if ( def_svn_flags&SVN_FLAG_HIDE_EMPTY_BRANCHES ) {
            hideEmptyBranches(branchTable);
         }
   
         p_window_id = origWID;
         minihtml1WID := _find_control("ctlminihtml1");
         minihtml1WID.p_text = minihtml1WID.p_text:+labelText;
         // flag that we don't need the old history
         populateOldHistory = false;
      }
   }
   if (populateOldHistory == true) {
      int temp_view_id;_str ErrorFilename;
      status := _SVNGetLogInfoForFile(filename,temp_view_id,quiet);
   
      if ( !status ) {
         SVNFillInHistoryXML(filename,temp_view_id,branchName,branchIndexes,auto versionIndexes);
      
         ctltree1.call_event(CHANGE_SELECTED,ctltree1._TreeCurIndex(),ctltree1,ON_CHANGE,'W');
         svn_history_add_menu();
         _delete_temp_view(temp_view_id);
      }
   }
}

/**
 * Display the Subversion history dialog for <b>filename</b>
 * @param filename file to display Subversion history dialog for.  If this is
 *        '', uses the current buffer.  If there is no window open, it will
 *        display an open file dialog
 * @param quiet if true, do not display error messages
 * @param version if this is not null, it will set the current tree node in the
 *        dialog to this version
 *
 * @return int 0 if successful
 */
_command int svn_history(_str filename='',boolean quiet=false,
                         _str version=null,boolean useNewHistory=def_svn_use_new_history!=0) name_info(FILE_ARG'*,')
{
   noBranches := 1;
   if ( def_svn_flags&SVN_FLAG_SHOW_BRANCHES ) {
      noBranches = 0;
   }
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_history(filename,noBranches);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:24am 4/10/2013
   for ( ;; ) {
      option := parse_file(filename);
      if ( substr(option,1,1)=='-' ) {
         if ( option=="--old-history" ) {
            useNewHistory = false;
         }
      }else{
         filename = option;
         break;
      }
   }
   if ( useNewHistory ) {
      return svn_new_history(filename,quiet,version);
   }
   if ( filename=='' ) {
      _str bufname='';
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
   if ( !isdirectory(filename) ) {
       if ( !file_exists(filename) ) {
          _message_box(get_message(FILE_NOT_FOUND_RC));
          return(1);
       }
       if ( !IsSVNFile(filename) ) {
          _message_box(get_message(SVN_FILE_NOT_CONTROLLED_RC,get_message(SVN_APP_NAME_RC)));
          return(1);
       }
   }
   int temp_view_id;_str ErrorFilename;
   status := _SVNGetLogInfoForFile(filename,temp_view_id,quiet);
   if ( status ) {
      if ( status==INCORRECT_VERSION_RC ) {
         _message_box( nls("The %s client '%s' is too old to work on this file",VCSYSTEM_TITLE_SUBVERSION,_SVNGetExeAndOptions(true)) );
      }else{
         _message_box(get_message(SVN_COULD_NOT_GET_LOG_INFO_RC,filename));
      }
      return(status);
   }

   _nocheck _control ctltree1;
   int wid=show('-new -hidden -xy _cvs_history_form');
   wid.p_caption=nls('%s info for %s',VCSYSTEM_TITLE_SUBVERSION,filename);
   int branchIndexes:[];

   wid.SVNFillInHistoryXML(filename,temp_view_id,"",branchIndexes,auto versionIndexes);

   wid.ctltree1.call_event(CHANGE_SELECTED,wid.ctltree1._TreeCurIndex(),wid.ctltree1,ON_CHANGE,'W');
   wid.svn_history_add_menu();
   if ( version!=null ) {
      int index=wid.ctltree1._TreeSearch(TREE_ROOT_INDEX,version,'T');
      if ( index>-1 ) {
         wid.ctltree1._TreeSetCurIndex(index);
      }
   }

   wid.p_visible = 1;

   _delete_temp_view(temp_view_id);

   return(0);
#endif
}

/**
 * Callback that is passed to _CVSCommand to build a "revert" command
 *
 * @param pinfo callback data - options for the revert command
 * @param output_filename - file to write output from command to
 * @param append_to_output - set to true if the output should be appended to rather
 *                           than overwritten
 *
 * @return string for revert command
 */
static _str BuildRevertCommand(typeless *pdata,_str output_filename,boolean append_to_output)
{
   _str appendop='>';
   if ( append_to_output ) {
      appendop='>>';
   }
   _str revert_options=*pdata;
   return(_SVNGetExeAndOptions()' 'appendop:+maybe_quote_filename(output_filename)' 2>&1 revert 'revert_options' ');
}

/**
 * Runs the Subversion revert command
 * @param filelist list of files to revert
 * @param OutputFilename file to put the Subversion output into
 *
 * @return int 0 if successful
 */
int _SVNRevert(_str (&filelist)[],_str OutputFilename)
{
   int i,len=filelist._length();
   for (i=0;i<len;++i) {
      if (filelist[i]=='') {
         _message_box(nls("Cannot revert blank filename"));
         return(1);
      }
      _LoadEntireBuffer(filelist[i]);

      // Re-cache any updated project files
      _str ext=_get_extension(filelist[i],true);
      if ( file_eq(ext,PRJ_FILE_EXT) ) {
         _ProjectCache_Update(filelist[i]);
      }
   }
   _str UpdateOptions='';
   boolean updated_new_dir=false;
   int status=_CVSCommand(filelist,BuildRevertCommand,&UpdateOptions,OutputFilename,true,0,updated_new_dir);
   _reload_vc_buffers(filelist);
   //if ( gaugeParent ) {
   //   cancel_form_set_parent(gaugeParent);
   //}
   _retag_vc_buffers(filelist);
   //if ( gaugeParent ) {
   //   cancel_form_set_parent(0);
   //}
   return(status);
}

/**
 * Get the name of the file the history dialog is being displayed for from the
 * dialog's caption
 *
 * @return _str name of the file that the dialog is being displayed for
 */
static _str SVNGetFilenameFromHistoryDialog()
{
   return( _CVSGetFilenameFromHistoryDialog(VCSYSTEM_TITLE_SUBVERSION:+' ') );
}

#define SVN_DELETING_TREE 0
#define SVN_WAS_RECURSIVE 1
#define SVN_TREE_FILE_INFO 2

/**
 * Refreshes the Subversion history dialog
 * @param DialogFilename if this is not '', will look for instances of the history
 *        dialog being displayed for this filename
 *
 * @return int 0 if successful
 */
/**
 * Checks a file out from subversion - actually uses "svn cat"
 * @param remote_filename URL of file to check out
 * @param checkout_options Options to pass to "svn cat "
 * @param OutputFilename Name of file  to receive output.If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param quiet If true, do not display error messages
 * @param debug_NOTUSED Deprecated - do not use - set _CVSDebug instead
 * @param NoHourglass if true, do not display hourglass
 *
 * @return int 0 if successful
 */
int _SVNCheckoutFile(_str remote_filename,
                     _str local_filename,
                     _str checkout_options='',
                     _str &OutputFilename='',
                     boolean quiet=false,boolean debug_NOTUSED=false,boolean NoHourglass=false)
{
   _str caption='';
   if ( !pos(" --non-interactive ",' ':+checkout_options:+' ') ) {
      checkout_options = checkout_options:+" --non-interactive";
   }
   String StdOutData,StdErrData;
   status := _CVSPipeProcess(_SVNGetExeAndOptions():+" cat ":+checkout_options:+' ':+maybe_quote_filename(remote_filename),
                             local_filename,
                             'P'def_cvs_shell_options,
                             StdOutData,StdErrData,false,null,null,null,-1,false,false);
   if ( status && !quiet ) {
      _message_box(nls("Could not checkout file %s.\n\n%s",remote_filename,get_message(status)));
   }
   OutputFilename = mktemp();
   orig_wid := _create_temp_view(auto temp_wid);
   p_window_id = temp_wid;
   maxLen :=_default_option(VSOPTION_WARNING_STRING_LENGTH);
   outDataLen := StdOutData.getLength();
   boolean changedLen = false;
   if ( maxLen<outDataLen ) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH,outDataLen+10);
      changedLen = true;
   }
   _insert_text(StdOutData.get(),true);
   if ( changedLen ) {
      _default_option(VSOPTION_WARNING_STRING_LENGTH,maxLen);
   }
   _save_file('+o 'maybe_quote_filename(OutputFilename));
   p_window_id = orig_wid;
   _delete_temp_view(temp_wid);

   return(status);
}

/**
 * Gets a "real" version from a tree node caption.  Strips off the first character
 * if it is not an integer because Subversion puts 'r' in front of all revision
 * numbers. 
 *  
 * Global because we use this for Mercurial 
 *
 * @param version_caption caption to convert
 *
 * @return _str converted caption
 */
_str SVNGetVersionFromCaption(_str version_caption)
{
   parse version_caption with version_caption '(' .;
   if ( isinteger(substr(version_caption,1,1)) ) {
      return(version_caption);
   }
   return(substr(version_caption,2));
}

/**
 * Callback for "View" button on subversion history dialog
 * @return 0 if successful
 */
int _svn_history_view_button()
{
   _nocheck _control ctltree1;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int version_index=_CVSGetVersionIndex(_TreeCurIndex(), true);
   _str version=SVNGetVersionFromCaption(_TreeGetCaption(version_index));

   p_window_id=wid;
   _str error_output_filename=mktemp();
   _CVSCreateTempFile(error_output_filename);
   _str temp_dir=mktemp();
   _str cvs_repository='';

   _str filename=SVNGetFilenameFromHistoryDialog();
   _str just_filename=_strip_filename(filename,'P');

   _str fileURL='';
   ctltree1.getSVNURLFromTreeIndex(fileURL,version_index);
   if ( fileURL=="" ) {
      // 8/9/2011
      // If show branches is off, we defer this information, so we have to fill
      // it in and try again.  We defer it until here because there is a slight
      // performance hit, and somebody with show branches shut off probably wants
      // the dialog to come up very quickly.

      _str URLToBranchTable:[];
      int retVal = _SVNGetBranchForLocalFile(filename,auto branchName,auto repositoryRoot,auto subFilename,auto URL);
      _SetDialogInfoHt("repositoryRoot",repositoryRoot);
      _SetDialogInfoHt("URL",URL);
      justBranchName := substr(branchName,length(repositoryRoot)+1);
      rootIndex := ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      if ( rootIndex>TREE_ROOT_INDEX ) ctltree1._TreeSetCaption(rootIndex,justBranchName);
      addBranchToURLTable(justBranchName,repositoryRoot,URLToBranchTable);
      _SetDialogInfoHt("URLToBranchTable",URLToBranchTable);
      ctltree1.getSVNURLFromTreeIndex(fileURL,version_index,justBranchName);
      if ( fileURL=="" ) {
         _message_box(nls("Could not get repository for %s",filename));
         return(1);
      }
   }
   status := _SVNCheckoutFile(fileURL,filename,'-r 'version,error_output_filename);
   if (status) {
      _SVCDisplayErrorOutputFromFile(error_output_filename,status);
      delete_file(error_output_filename);
      return(status);
   }
   _str local_filename=error_output_filename;
   int temp_view_id,orig_view_id;
   status=_open_temp_view(local_filename,temp_view_id,orig_view_id);
   if (status) {
      _message_box(nls("Could not open local version of %s",fileURL));
      return(status);
   }
   _str ext=_get_extension(fileURL);
   _SetEditorLanguage(_Ext2LangId(ext));
   // Tweek the buffer name so that if the user click save they get a "save as"
   // dialog
   p_buf_name=just_filename;
   p_window_id=orig_view_id;

   // This is what shows the file, it is not debug, do not comment it out
   _showbuf(temp_view_id.p_buf_id,true,'-new -modal',fileURL' (Version 'version')','S',true);
   _delete_temp_view(temp_view_id);
   delete_file(error_output_filename);
   return(status);
}

/**
 * Callback for "Revert" button on subversion history dialog
 *
 * @return int
 */
int _svn_history_revert_button()
{
   _str filename=_CVSGetFilenameFromHistoryDialog(VCSYSTEM_TITLE_SUBVERSION:+' ');
   _str filelist[]=null;
   filelist[0]=filename;
   _str OutputFilename=mktemp();

   boolean updated_new_dir=false;
   int status=_SVNRevert(filelist,OutputFilename);
   if (status) {
      _SVCDisplayErrorOutputFromFile(OutputFilename);
   }else{
      _svn_history_refresh_button();
   }
   return(status);
}

/**
 * Diff <b>filename</b> on disk with a particular version from subversion
 *
 * @param filename file to diff
 * @param version  Use -1 for most up to date version
 * @param ReadOnly Make local file read only in diff dialog
 * @param TagName  Tag to checkout
 * @param lang     Language ID (see {@link p_LangId} 
 *
 * @return 0 if successful
 */
static int SVNDiffWithVersion(_str filename,_str version=-1,
                              boolean ReadOnly=false,
                              _str TagName='',_str lang='',
                              _str remote_filename="")
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

   if ( remote_filename=="" ) {
      status=_SVNGetFileURL(filename,remote_filename);
      if ( remote_filename=="" ) {
         getURLErrorMessage(filename,status);
         return status;
      }
   }

   _str options='';
   if ( remote_version!='-1' ) {
      options=' -r 'remote_version;
   }

   status=_SVNCheckoutFile(remote_filename,filename,options,OutputFilename);
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
   _str local_version;
   status=_SVNGetAttributeFromCommand(filename,"Last Changed Rev",local_version);
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
   status=SVNGetFileStatus(filename,status_flags);
   if ( !status ) {
      if ( status_flags&SVN_STATUS_MODIFIED ) {
         modstr=' - Modified';
      }
   }
   if ( remote_version==-1 ) {
      remote_version = "TIP";
   }
   filenamenq := strip(filename,'B','"');
   _DiffModal(ro_opt' -r2 -bi2 -nomapping -file1title "':+filenamenq:+' (Version 'local_version' - Local' modstr')" -file2title "'remote_filename' (Version 'remote_version' - Remote)" 'maybe_quote_filename(filename)' 'temp_view_id.p_buf_id,
              "svn");
   _delete_temp_view(temp_view_id);
   delete_file(OutputFilename);
   p_window_id=wid;
   _set_focus();
   return(status);
}

/**
 * Callback for "Diff" button on subversion history dialog
 *
 * @return int
 */
int _svn_history_diff_button()
{
   _str version=SVNGetVersionFromCaption(ctltree1._TreeGetCaption(ctltree1._CVSGetVersionIndex(-1,true)));
   _str filename=SVNGetFilenameFromHistoryDialog();
   _str orig_date=_file_date(filename,'B');
   treeIndex := ctltree1._TreeCurIndex();
   ctltree1.getSVNURLFromTreeIndex(auto fileURL,treeIndex);
   status := SVNDiffWithVersion(filename,version,false,"","",fileURL);

   if ( _file_date(filename,'B')!=orig_date ) {
      status = SVNGetFileStatus(filename,auto fileStatus);
      svnSetDialogForFileStatus(fileStatus);
   }
   return(status);
}

static void svnSetDialogForFileStatus(int status_flags)
{
   text := ctlminihtml1.p_text;
   _str status_description='';
   if ( status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description='<FONT color=red>Needs update</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=UPDATE_CAPTION_UPDATE;
      ctlrevert.p_enabled=false;
   }
   if ( status_flags&SVN_STATUS_MODIFIED ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description=status_description:+'<FONT color=red>Locally modified</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=true;
   }
   if ( status_flags&SVN_STATUS_CONFLICT ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description=status_description:+'<FONT color=red>there are conflicts in the local file</FONT>';
      ctlupdate.p_enabled=false;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=true;
   }
   if ( status_description=='' ) {
      status_description='Up to date';
      ctlupdate.p_enabled=false;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=false;
   }

   newText := stranslate(text,'<B>Status:</B>&nbsp;'status_description'<br>','\<B\>Status\:\<\/B\>\&nbsp\;?@\<br\>','ri');
   ctlminihtml1.p_text = newText;
}

#if 0 //10:53am 11/15/2011
static int getFileSVNStatus(_str filename,SVN_FILE_STATUS &fileStatus)
{
   fileStatus = SVN_STATUS_UP_TO_DATE;
   String StdOutData,StdErrData;
   status:=_CVSPipeProcess(_SVNGetExeAndOptions():+" --show-updates --xml status ":+maybe_quote_filename(filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                           false,null,null,null,-1,false,false);
   if ( status ) {
      return status;
   }

   origWID := _create_temp_view(auto tempWID);
   _insert_text(StdOutData,true);
   p_window_id = origWID;
   xmlHandle := _xmlcfg_open_from_buffer(tempWID,status);
   
   if ( !status ) {
      pathIndex := _xmlcfg_find_simple(xmlHandle,"/status/target/entry/@path[file-eq(.,'"filename"')]");
      entryIndex := -1;
      if ( pathIndex>=0 ) {
         entryIndex = _xmlcfg_get_parent(xmlHandle,pathIndex);
      }
      if ( entryIndex>0 ) {
         itemStatusIndex := _xmlcfg_find_simple(xmlHandle,"wc-status[@item='modified']",entryIndex);
         if ( itemStatusIndex>0 ){
            // If we find this entry, we know the file is locally modified
            fileStatus |= SVN_STATUS_LOCALLY_MODIFIED;
         }

         itemStatusIndex = _xmlcfg_find_simple(xmlHandle,"repos-status[@item='modified']",entryIndex);
         if ( itemStatusIndex>0 ) {
            // If we find this entry, we know the file needs update
            fileStatus |= SVN_STATUS_NEEDS_UPDATE;
         }
      }
   }
   _delete_temp_view(tempWID);
   _xmlcfg_close(xmlHandle);

   return 0;
}
#endif

#if 0 //9:40am 6/23/2010
static void getSVNURLFromTreeIndex(_str &fileURL,int treeIndex)
{
   fileURL = "";
   repositoryRoot := _GetDialogInfoHt("repositoryRoot");
   URL := _GetDialogInfoHt("URL");
   filename:=SVNGetFilenameFromHistoryDialog();
   if ( repositoryRoot==null || URL==null ) return;

   getURLMapping(filename,URL,repositoryRoot,auto localMapDir,auto remoteMapDir);

   justName := substr(filename,length(localMapDir)+1);
   justName = stranslate(justName,'/',FILESEP);

   parentIndex := _TreeGetParentIndex(treeIndex);
   branchName :=_TreeGetCaption(parentIndex);

   if (length(remoteMapDir) != length(repositoryRoot) + 1) {
      // 12:30:42 PM 6/17/2010
      // This is the typical case, a normal checkout
      fileURL = repositoryRoot:+branchName:+'/':+justName;
   }else{
      // 12:30:48 PM 6/17/2010
      // If a user checks out a repository in the following fashion, we have to 
      // adjust.  This is because the remoteMapDir will have the extra piece that
      // will also be on justName
      // 
      // 1. cd /tmp
      // 2. mkdir foobar
      // 3. cd foobar
      // 4. svn co http://svn.apache.org/repos/asf/subversion/ -N svn 
      // 5. svn up -N svn/trunk 
      // 6. svn up -N svn/branches
      // 7. svn up -N svn/branches/1.6.x

      fileURL = repositoryRoot:+'/':+justName;
   }
}
#endif
/**
 * Return the last path in the URL
 * 
 * @param URL Subversion URL
 * 
 * @return _str last path in <B>URL</B>
 */
static _str SVNGetLastPath(_str URL)
{
   curURL := URL;
   _maybe_strip(curURL,'/');
   p := lastpos('/',curURL);
   if ( p ) {
      curURL = substr(curURL,p+1);
   }
   return curURL;
}
/**
 * @param URL  Subversion URL
 * @param lastPath value to check against the last directory in 
 *                 <B>URL</B>
 * 
 * @return boolean true if <B>lastPath</B> matches the last 
 *         directory in <B>URL</B>
 */
static boolean SVNLastPathMatches(_str URL,_str lastPath)
{
   return SVNGetLastPath(URL):==lastPath;
}

static _str gPathTable:[];
static void SVNGetLocalPathRepositoryRoot(_str filePath,_str &localPathRepository="",_str &remoteLocalRepositoryRoot="")
{
   localPathRepository = "";
   if ( gPathTable._indexin(_file_path(filePath))
        && gPathTable:[_file_path(filePath)]!=null ) {
      localPathRepository = gPathTable:[_file_path(filePath)];
      return;
   }
   curFilePath := filePath;
   lastCheckedOutPath := curFilePath;
   pathURL := "";
   lastPathURL := "";
   localLastPath := "";
   _SVNGetAttributeFromCommand(curFilePath,"Repository Root",auto repositoryRootURL);
   for ( ;; ) {
      _SVNGetAttributeFromCommand(curFilePath,"URL",pathURL);

      localLastPath = lastCheckedOutPath;
      _maybe_strip_filesep(localLastPath);
      localLastPath = _strip_filename(localLastPath,'P');

      if ( pathURL=="" ) break;
      if ( repositoryRootURL=="" ) break;

      lastCheckedOutPath = curFilePath;
      lastPathURL = pathURL;

      _maybe_strip_filesep(curFilePath);
      curFilePath = _strip_filename(curFilePath,'N');
   }
   gPathTable:[_file_path(filePath)] = lastCheckedOutPath;

   localPathRepository = lastCheckedOutPath;
   remoteLocalRepositoryRoot = lastPathURL;
}

/**
 * Finds the last valid URL prefix.  Once you know this you can 
 * calculate what is a branch, and what is a filename 
 * 
 * @param repositoryRoot 
 * @param URL URL of filename
 * @param URLToBranchTable Table built in 
 *                         <B>populateTreeFromCache</B>
 * 
 * @return _str Valid URL prefix
 */
static _str getLastValidPrefixPath(_str repositoryRoot,_str URL,_str (&URLToBranchTable):[])
{
   shortestURL := "";
   URL = _strip_filename(URL,'N');
   while ( URL != "" ) {
      if ( URLToBranchTable._indexin(URL) && URLToBranchTable:[URL] != null ) {
         shortestURL = URL;
      }
      lastURL := URL;
      _maybe_strip(URL,'/');
      URL = _strip_filename(URL,'N');
      if ( URL == lastURL ) break;
   }
   return shortestURL;
}

/**
 * Get a URL for the filename appearing the history dialog for 
 * the branch selected in the treeview 
 * 
 * @param fileURL file URL is returned here
 * @param treeIndex index into treview control
 */
static void getSVNURLFromTreeIndex(_str &fileURL,int treeIndex,_str branchName="")
{
   fileURL = "";
   repositoryRoot := _GetDialogInfoHt("repositoryRoot");
   URL := _GetDialogInfoHt("URL");
   filename:=SVNGetFilenameFromHistoryDialog();
   if ( branchName=="" && treeIndex > 0) branchName = _TreeGetCaption(_TreeGetParentIndex(treeIndex));
   
   // look for a tag name in parenthesis
   p := pos(' (',branchName);
   if ( p>1 ) {
      // It won't be the first character, so look for p>1, this way we know p-1
      // will not be a problem for substr
      // 
      branchName = substr(branchName,1,p-1);
   }
   if ( repositoryRoot==null || URL==null ) return;


   URLToBranchTable := _GetDialogInfoHt("URLToBranchTable");

   lastValidPath := getLastValidPrefixPath(repositoryRoot,URL,URLToBranchTable);
   if ( lastValidPath == "" ) return;

   justName := substr(URL,length(lastValidPath));

   fileURL = repositoryRoot:+branchName:+justName;
}

/**
 * Fills in the history dialog with the information that is stored in <b>view_id</b>
 *
 * @param filename file to fill in history for
 * @param view_id holds the svn output to fill the dialog in with
 */
static void SVNFillInHistory(_str filename,int view_id,_str branchName="")
{
   //ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   ctlminihtml1.p_text='';
   ctlminihtml2.p_text='';
   int form_wid=p_window_id;
   int orig_view_id=p_window_id;
   p_window_id=view_id;
   top();
   int index=-1;
   int rel_index=-1;
   int flags=0;
   int branchFolderIndex = form_wid.ctltree1._TreeAddItem(TREE_ROOT_INDEX,branchName,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
   for (;;) {
      if ( down() ) break;
      get_line(auto header_line);
      _str revision='';
      _str author='';
      _str date_and_time='';
      _str number_of_lines='';
      parse header_line with revision '|' author '|' date_and_time '|' number_of_lines .;
      if ( header_line=="" ) break;
      _str noflines;
      parse number_of_lines with noflines .;

      _nocheck _control ctltree1;

      if ( rel_index<0 ) {
         rel_index=branchFolderIndex;
         flags=TREE_ADD_AS_CHILD;
      }else{
         flags=TREE_ADD_BEFORE;
      }

      revision=strip(revision);
      index=form_wid.ctltree1._TreeAddItem(rel_index,revision,flags,_pic_file,_pic_file,-1);
      rel_index=index;

      if ( down() ) break;
      // Now we are on the "Changed paths:" line
      for (;;) {
      if ( down() ) break;
         get_line(auto cur_line);
         if ( cur_line=="" ) break;
      }
      int i;
      _str comment='';
      for (i=0;i<noflines;++i) {
         if ( down() ) break;
         get_line(auto cur_line);
         comment=comment:+cur_line"<br>";
      }
      form_wid.ctltree1.SVNSetVersionInfo(index,author,date_and_time,comment);
      down();
   }
   p_window_id=orig_view_id;
   _str URL='';
   ctlminihtml1.p_backcolor=0x80000022;
   ctlminihtml2.p_backcolor=0x80000022;
   ctlminihtml1.SVNSetFileInfo(filename);
}

static int getPCDataItem(int xmlhandle,int index,_str fieldName,_str &item)
{
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

static void SVNFillInHistoryXML(_str filename,int view_id,_str branchName,
                                int (&branchIndexes):[],
                                int (&versionIndexes):[])
{
   int form_wid=p_window_id;
   xmlhandle := _xmlcfg_open_from_buffer(view_id,auto status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( status ) return;

   _xmlcfg_find_simple_array(xmlhandle,"//logentry",auto indexArray);

   len := indexArray._length();
   rel_index := -1;
   index := 1;
   flags := 0;
   int branchFolderIndex = -1;
   if ( !branchIndexes._indexin(branchName) ) {
      _maybe_strip(branchName,'/');
      branchFolderIndex = form_wid.ctltree1._TreeAddItem(TREE_ROOT_INDEX,branchName,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
      branchIndexes:[branchName] = branchFolderIndex;
   }
   branchFolderIndex = branchIndexes:[branchName];

   for ( i:=0;i<len;++i ) {
      curIndex := (int)indexArray[i];
      revision := _xmlcfg_get_attribute(xmlhandle,curIndex,"revision");
      authorIndex := getPCDataItem(xmlhandle,curIndex,"author",auto author);
      date_and_timeIndex := getPCDataItem(xmlhandle,curIndex,"date",auto date_and_time);
      commentIndex := getPCDataItem(xmlhandle,curIndex,"msg",auto comment);

      // Get the list of files and directories that were also affected
      // at this revision
      _str affectedFilesDetails = '';
      _xmlcfg_find_simple_array(xmlhandle, "paths/path", auto affectedPathsIndices, curIndex);
      int numAffectedPaths = affectedPathsIndices._length();
      for ( j:=0;j<numAffectedPaths;++j ) {
         currentPathIndex := (int)affectedPathsIndices[j];

         fileURLIndex := _xmlcfg_get_first_child(xmlhandle,currentPathIndex,VSXMLCFG_NODE_PCDATA);
         if ( fileURLIndex>-1 ) {
            actionCode := _xmlcfg_get_attribute(xmlhandle, currentPathIndex, "action");
            fileURLText := _xmlcfg_get_value(xmlhandle,fileURLIndex);
            affectedFilesDetails :+= "<br>&nbsp;&nbsp;"actionCode" "fileURLText;
         }
      }
      
      _nocheck _control ctltree1;
      if ( rel_index<0 ) {
         rel_index = branchFolderIndex;
         flags = TREE_ADD_AS_CHILD;
      }else{
         flags = TREE_ADD_BEFORE;
         rel_index = index;
      }

#if 1 //8:51am 6/25/2009
      // Temporarily remove items from history dialog
      index = form_wid.ctltree1._TreeAddItem(rel_index,'r'revision,flags,_pic_file,_pic_file,-1);
      versionIndexes:[revision] = index;
      form_wid.ctltree1.SVNSetVersionInfo(index,author,date_and_time,comment,affectedFilesDetails);
      rel_index=index;
#endif
   }

   _str URL='';
   ctlminihtml1.p_backcolor=0x80000022;
   ctlminihtml2.p_backcolor=0x80000022;
   ctlminihtml1.SVNSetFileInfo(filename);
   _xmlcfg_close(xmlhandle);
}

/**
 * Look for string <B>revision</B> in history tree
 * 
 * @param revision revision as it would appear in the tree
 */
static void selectRevisionInTree(_str revision)
{
   int index=_TreeSearch(TREE_ROOT_INDEX,'r'revision,'it');
   if ( index>-1 ) {
      int state,bm1,bm2,flags;
      _TreeGetInfo(index,state,bm1,bm2,flags);
      _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
      _TreeSetCurIndex(index);
   }
}

/**
 * Used by SVNFillInHistoryXML(_strInHistory.  Fills in the top left pane of the history dialog with
 * the appropriate info about <b>filename</b>
 * @param filename file to fill in history info about
 */
static void SVNSetFileInfo(_str filename,_str &URL="",_str &revision="")
{
   _SVNGetFileURL(filename,URL);
   _str line='<B>File:</B> 'filename'<br>';
   line=line:+'<B>URL:</B> 'URL'<br>';

   revision='';
   int status=_SVNGetAttributeFromCommand(filename,"Last Changed Rev",revision);
   if ( !status ) {
      line=line:+'<B>Revision:</B> 'revision'<br>';
      ctltree1.selectRevisionInTree(revision);
   }
   int status_flags=0;
   status=SVNGetFileStatus(filename,status_flags);

   _str status_description='';
   if ( status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description='<FONT color=red>Needs update</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=UPDATE_CAPTION_UPDATE;
      ctlrevert.p_enabled=false;
   }
   if ( status_flags&SVN_STATUS_MODIFIED ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description=status_description:+'<FONT color=red>Locally modified</FONT>';
      ctlupdate.p_enabled=true;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=true;
   }
   if ( status_flags&SVN_STATUS_CONFLICT ) {
      if ( status_description!='' ) {
         status_description=status_description:+' and ';
      }
      status_description=status_description:+'<FONT color=red>there are conflicts in the local file</FONT>';
      ctlupdate.p_enabled=false;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=true;
   }
   if ( status_description=='' ) {
      status_description='Up to date';
      ctlupdate.p_enabled=false;
      ctlupdate.p_caption=UPDATE_CAPTION_COMMIT;
      ctlrevert.p_enabled=false;
   }

   line=line:+'<B>Status:</B>&nbsp;'status_description'<br>';
   line=line:+"\n<B>Tags:</B>\n";

   p_text=line;
}

/**
 * Stores info on a tree node in the history dialog for that revision
 * @param index index of node to store data on
 * @param author Author from Subversion
 * @param date_and_time date/time from Subversion
 * @param comment Comment from Subversion 
 * @param affectedPaths List of all file paths affected by this revision 
 */
static void SVNSetVersionInfo(int index,_str author,_str date_and_time,_str comment,_str affectedPaths='')
{
   _str lineArray[];
   lineArray[lineArray._length()]='<B>Author:</B>&nbsp;'author'<br>';
   lineArray[lineArray._length()]='<B>Date:</B>&nbsp;'date_and_time'<br>';
   // Replace comment string line endings with <br> to preserve formatting
   _str commentBR = stranslate(comment, '<br>', '\n', 'l');
   lineArray[lineArray._length()]='<B>Comment:</B>&nbsp;'commentBR;
   if( affectedPaths :!= '' ) {
      lineArray[lineArray._length()]='<br><B>Changed paths:</B><font face="Menlo, Monaco, Consolas, Courier New, Monospace">'affectedPaths'</font>';
   }
   _TreeSetUserInfo(index,lineArray);
}

/**
 * Get version of Subversion executable. 
 *  
 * @param version version is returned here.  Each piece has a 0 
 *                prepended, and it is converted to an int. So
 *                1.6.1 will be 10601, 1.4.4 is 10404.
 * 
 * @return int 0 if succesful
 */
static int SVNGetSVNVersion(int &version)
{
   String StdOutData,StdErrData;
   int status=_CVSPipeProcess(_SVNGetExeAndOptions()"--version --quiet",'','P'def_cvs_shell_options,StdOutData,StdErrData,
                              false,null,null,null,-1,false,false);
   strVersion := StdOutData.get();
   strVersion = stranslate(strVersion,'',"\n");
   strVersion = stranslate(strVersion,'',"\r");
   parse strVersion with auto v1 '.' auto v2 '.' auto v3 .;

   // On some clients "--version --quiet" does not simply return a version
   // number (1.2.3), but a string (1.2.3-blah-blah-1.2.3@12345-platform).  
   // Remove everything after the last digit.
   p := pos('[~0-9]',v3,1,'r');
   if ( p ) {
      if ( p>1 ) {
         v3 = substr(v3,1,p-1);
      }else{
         v3 = '0';
      }
   }
   // Take each piece of version, and pad with a 0
   if ( length(v1)<2 ) v1 = '0'v1;
   if ( length(v2)<2 ) v2 = '0'v2;
   if ( length(v3)<2 ) v3 = '0'v3;

   // Concatenate and convert to int
   strVersion = (v1:+v2:+v3);
   version = (int)strVersion;

   return status;
}

/**
 * Runs the "svn status -u" command for <b>filename</b> and returns SVN_STATUS_* flags based on the output
 * @param filename name of file to get status for
 * @param status_flags variable that status flags are returned in
 * @param remote_version remote version parsed out from output
 * @param subdir_info used by GUI update dialog to help tell new dirs from new files
 *
 * @return int 0 if successful
 */
static int SVNGetFileStatus(_str filename,int &status_flags,_str &remote_version='',SVN_SUBDIR_INFO &subdir_info=null)
{
   status_flags=0;
   String StdOutData,StdErrData;
   _str path=_file_path(filename);
   _str orig_path=getcwd();

   // Subversion's log command will not work with certain relative filenames, just
   // switch to that directory
   chdir(path);
   _str relative_filename=relative(filename);
#if !__UNIX__
   relative_filename=stranslate(relative_filename,FILESEP2,FILESEP);
#endif
   int status=_CVSPipeProcess(_SVNGetExeAndOptions()' status -u 'maybe_quote_filename(relative_filename),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                              false,null,null,null,-1,false,false);

   chdir(orig_path);
   if ( !status ) {
      int temp_view_id;
      int orig_wid=_create_temp_view(temp_view_id);
      _insert_text(StdOutData.get());
      top();
      _str version_line='',status_line;
      get_line(status_line);
      down();
      get_line(version_line);
      parse version_line with (SUBVERSION_STATUS_VERSION_PREFIX) remote_version;
      p_window_id=orig_wid;
      _delete_temp_view(temp_view_id);
      remote_version=strip(remote_version);
      SVNGetSVNVersion(auto version);
      status_flags=SVNGetStatusFlagsFromLine(status_line,version,auto working_revision,auto local_filename,'',subdir_info);
   }
   return(status);
}

/**
 * Checks to see if <b>line</b> is a "status against revision" line output from
 * svn status
 * @param line line from svn status output that we are not sure about
 *
 * @return boolean true if the line starts with "Status against revision:"
 */
static boolean SVNIsStatusAgainstRevision(_str line)
{
   return( substr(line,1,length(SUBVERSION_STATUS_VERSION_PREFIX))==SUBVERSION_STATUS_VERSION_PREFIX );
}

#define CONFLICT_TEXT_LIST_STRING " Text conflicts:"
#define CONFLICT_TREE_LIST_STRING " Tree conflicts:"
#define CONFLICT_LOCAL_ADD_STRING "local add, incoming add upon merge"
#define CONFLICT_LOCAL_DELETE_STRING "local delete, incoming delete upon merg"

/**
 * Converts a subversion status line to a set of flags
 * @param line Line output from subversion
 * @param version version of Subversion returned from 
 *                SVNGetSVNVersion
 * @param working_revision Version of this file that is local
 * @param local_filename Local file
 * @param root_path @path to set <I>local_filename</I> absolute to
 * @param info
 *
 * @return int set of SVN_STATUS_* flags
 */
static int SVNGetStatusFlagsFromLine(_str line,
                                     int version,
                                     _str &working_revision=0,
                                     _str &local_filename='',
                                     _str root_path='',
                                     SVN_SUBDIR_INFO &info=null)
{
   working_revision=0;
   int status_flags=0;
   noLocalFilename := false;
   if ( SVNIsStatusAgainstRevision(line) ) {
   }else if ( line=="Summary of conflicts:" ) {
   }else if ( substr(line,1,length(CONFLICT_TEXT_LIST_STRING)+1)==CONFLICT_TEXT_LIST_STRING ) {
   }else if ( substr(line,1,length(CONFLICT_TREE_LIST_STRING)+1)==CONFLICT_TREE_LIST_STRING ) {
   }else{
      switch ( substr(line,1,1) ) {
      case 'A':
         status_flags|=SVN_STATUS_SCHEDULED_FOR_ADDITION;break;
      case 'D':
         status_flags|=SVN_STATUS_SCHEDULED_FOR_DELETION;break;
      case 'M':
         status_flags|=SVN_STATUS_MODIFIED;break;
      case 'C':
         status_flags|=SVN_STATUS_CONFLICT;break;
      case 'X':
         status_flags|=SVN_STATUS_EXTERNALS_DEFINITION;break;
      case 'I':
         status_flags|=SVN_STATUS_IGNORED;break;
      case '?':
         status_flags|=SVN_STATUS_NOT_CONTROLED;break;
      case '!':
         status_flags|=SVN_STATUS_MISSING;break;
      case '~':
         status_flags|=SVN_STATUS_NODE_TYPE_CHANGED;break;
      }

      switch ( substr(line,2,1) ) {
      case 'M':
         status_flags|=SVN_STATUS_PROPS_MODIFIED;break;
      case 'C':
         status_flags|=SVN_STATUS_PROPS_ICONFLICT;break;
      }

      if ( substr(line,3,1)=='L' ) {
         status_flags|=SVN_STATUS_LOCKED;
      }

      if ( substr(line,4,1)=='+' ) {
         status_flags|=SVN_STATUS_SCHEDULED_WITH_COMMIT;
      }

      if ( substr(line,5,1)=='S' ) {
         status_flags|=SVN_STATUS_SWITCHED;
      }
      switch ( substr(line,7,1) ) {
      case 'C':
         break;
      case '>':
         noLocalFilename = true;
         if ( pos(CONFLICT_LOCAL_ADD_STRING,line) ) {
            status_flags|=SVN_STATUS_TREE_ADD_CONFLICT;
         } else if ( pos(CONFLICT_LOCAL_DELETE_STRING,line) ) {
            status_flags|=SVN_STATUS_TREE_DEL_CONFLICT;
         }
         break;
      }
      starCol := 9;
      if ( version<10600 ) {
         // Prior to Subversion 1.6, a '*' in column 8 meant a file was out of date.
         // Starting in version 1.6, it is in column 9
         starCol = 8;
      }
      if ( substr(line,starCol,1)=='*' ) {
         status_flags|=SVN_STATUS_NEWER_REVISION_EXISTS;
      }
      line=substr(line,10);
      working_revision='';
      if ( !noLocalFilename ) {
         parse line with working_revision local_filename;
         if ( local_filename=='' ) {
            // If this file was unknown, there will not be a revision
            local_filename=working_revision;
            working_revision='';
         }
         _str just_path=local_filename;
         if ( root_path!='' ) {
            local_filename=absolute(local_filename,root_path);
         }
         if ( isdirectory(local_filename) ) {
            _maybe_append_filesep(local_filename);
         }else if ( status_flags&SVN_STATUS_NEWER_REVISION_EXISTS && working_revision=='' ) {
            // If an file/directory only exists remotely, there is no way to tell what it is
            // except to run "svn ls <parentdir>"  In a nutshell, that is what this does
            _str remote_path='';
            // Strip off the parent directory, since we don't know if this is a file
            // or directory, we know there will not be a trailing FILESEP
            int status=_SVNGetFileURL(_strip_filename(local_filename,'N'),remote_path);
            if ( !status ) {
               // There is a possible optimization here to see if we have a file reported
               // in this directory already.  Since this funciton is supposed to be
               // a bit more lightweight and it would have to have all of the file
               // info for this directory, we are not going to do it right now, but
               // wait to see if it is fast enough.  Since we are optimized to only make
               // the one call only if there are files we cannot resolve, it is not
               // any less efficient than CVS.
               if ( info.SubdirHT:[remote_path]==null ) {
                  _SVNLs(_file_path(remote_path),info);
               }
               // if this is a directory, it will show up as the name with a '/' after it
               // even on windows, so we can just check '/'
               int len=info.SubdirHT:[remote_path]._length();
               int i;
               just_path=_strip_filename(just_path,'P');
               for (i=0;i<len;++i) {
                  if ( file_eq(just_path'/',info.SubdirHT:[remote_path][i]) ) {
                     _maybe_append_filesep(local_filename);break;
                  }
               }
            }
         }
      }
   }
   return(status_flags);
}

/**
 * Calls svn ls for <i>remote_path</i> and stores the results in <i>info</i>.
 * Used primarily to identify subdirectories that only exist remotely.
 *
 * @param remote_path remote path (URL) to run "ls" on
 * @param info structure to fill results into
 *
 * @return int 0 if successful
 */
int _SVNLs(_str remote_path,SVN_SUBDIR_INFO &info=null,_str &lsCommand="")
{
   _str ErrorFilename=mktemp();
   String StdOutData,StdErrData;
   int status=_CVSPipeProcess(_SVNGetExeAndOptions()' --non-interactive ls  'maybe_quote_filename(remote_path),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                              false,null,null,null,-1,false,false);
   lsCommand = _SVNGetExeAndOptions()' --non-interactive ls 'maybe_quote_filename(remote_path);
   if ( status ) {
      return(status);
   }
   int temp_view_id;
   int orig_wid=_create_temp_view(temp_view_id);
   _insert_text(StdErrData.get());
   _insert_text(StdOutData.get());
   top();up();
   while ( !down() ) {
      get_line(auto cur_line);
      if ( cur_line=='svn: URL non-existent in that revision' ) {
         // Just something invalid so we know that we looked up this path
         info.SubdirHT:[remote_path][0]=FILESEP:+FILESEP:+FILESEP;
         break;
      }
      int cur_len=info.SubdirHT:[remote_path]._length();
      info.SubdirHT:[remote_path][cur_len]=cur_line;
   }
   p_window_id=orig_wid;
   _delete_temp_view(temp_view_id);

   // Signify that we really have run the ls for this path.  We could fill in
   // info.SubdirHT based on some optimizations
   info.PathsLSWascalledFor:[remote_path]='';
   return(0);
}

/**
 * Callback for "Refresh" button on subversion history dialog
 *
 * @return int
 */
int _svn_history_refresh_button(_str DialogFilename='')
{
   int fid=0;
   if ( DialogFilename!='' ) {
      int last=_last_window_id();
      int i;
      for ( i=1;i<=last;++i ) {
         if ( !_iswindow_valid(i) ) continue;
          if ( i.p_name=='_cvs_history_form'  && i.p_caption==VCSYSTEM_TITLE_SUBVERSION' info for 'DialogFilename ) {
            fid=i;
         }
      }
   } else {
      fid=p_active_form;
   }
   if ( !fid ) {
      return(0);
   }
   _str filename=fid.SVNGetFilenameFromHistoryDialog();
   int temp_view_id;_str ErrorFilename;
   int status=_SVNGetLogInfoForFile(filename,temp_view_id);
   if ( status ) {
      if ( status==INCORRECT_VERSION_RC ) {
         _message_box( nls("The %s client '%s' is too old to work on this file",VCSYSTEM_TITLE_SUBVERSION,_SVNGetExeAndOptions(true)) );
      }
      return(status);
   }
   _SetDialogInfo(SVN_DELETING_TREE,1);
   fid.ctltree1._TreeDelete(TREE_ROOT_INDEX,'C');
   _SetDialogInfo(SVN_DELETING_TREE,0);
   int branchIndexes:[];
   _SVNGetBranchForLocalFile(filename,auto branchName,auto repositoryRoot,auto subFilename);
   fid.SVNFillProperHistory(filename,repositoryRoot,branchName,branchIndexes,true);
   fid.ctltree1.call_event(CHANGE_SELECTED,fid.ctltree1._TreeCurIndex(),fid.ctltree1,ON_CHANGE,'W');
   fid.p_caption=nls('%s info for %s',VCSYSTEM_TITLE_SUBVERSION,filename);

   _delete_temp_view(temp_view_id);
   return(0);
}

/**
 * Callback for "Update" button on subversion history dialog
 *
 * @return int
 */
int _svn_history_update_button()
{
   _str filename=SVNGetFilenameFromHistoryDialog();
   int wid=p_window_id;

   int status=0;
   if ( p_caption==UPDATE_CAPTION_UPDATE ) {
      status=svn_update(filename);
   } else if ( p_caption==UPDATE_CAPTION_COMMIT ) {
      status=svn_commit(filename);
   }

   p_window_id=wid;
   _set_focus();
   if ( !status ) {
      // Sometimes after an update the log command would fail, apparently
      // because the server was still doing some processing on the update.
      // This short delay seems to keep that from happening.
      delay(10);
      _svn_history_refresh_button();
   }
   return(status);
}

static void initFileInfo(WATCHED_FILE_INFO &fileInfo)
{
   fileInfo.filename       = "";
   fileInfo.watchedPath    = "";
   fileInfo.VCServerStatus = "";
   fileInfo.VCLocalStatus  = "";
   fileInfo.localDate      = "";
   fileInfo.changeType     = 0;
}

/**
 * Commits the files in <b>filelist</b> using <b>comment</b>
 * @param filelist list of files to commit
 * @param comment comment for the files to commit
 * @param OutputFilename file for output. If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param comment_is_filename if true, the <b>comment</b> param is the name of a file that contains the comment
 * @param commit_options options that get passed to SVNBuildCommitCommand
 * @param append_to_output if true <b>OutputFilename</b> is appended to instead of overwritten
 * @param pFiles_NOTUSED Not used for Subversion, but keeping params in sync with _CVS version of this
 * @param taglist_NOTUSED
 *
 * @return int 0 if successful
 */
int _SVNCommit(_str filelist[],_str comment,_str &OutputFilename,
               boolean comment_is_filename=false,_str commit_options='',
               boolean append_to_output=false,
               SVN_STATUS_INFO (*pFiles_NOTUSED)[]=null,
               _str taglist_NOTUSED='')
{
   OutputFilename = "";
   //CVS_COMMIT_CALLBACK_INFO info;
   //info.comment=comment;
   //info.comment_is_filename=comment_is_filename;
   //info.commit_options=commit_options;

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
   //int status=_CVSCommand(filelist,SVNBuildCommitCommand,&info,OutputFilename,append_to_output);
   _str comment_info_str="";
   if ( comment_is_filename ) {
      comment_info_str="-F ":+maybe_quote_filename(comment);
   }else{
      comment_info_str="-m ":+maybe_quote_filename(comment);
   }
   _str filelist_filename="";
   int status=_SVNWriteListFile(filelist,filelist_filename);
   _str command=_SVNGetExeAndOptions():+" commit --non-interactive ":+comment_info_str:+" ":+commit_options:+" --targets ":+maybe_quote_filename(filelist_filename);
   String StdOutData,StdErrData;
   status = _CVSPipeProcess(command,"",'P'def_cvs_shell_options,StdOutData,StdErrData,
                            false,null,null,null,-1,false,false);
   if ( status ) {
      _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_RC,_SVNGetSVNExeName(),"commit",status));
      _SccDisplayOutput(StdErrData.get(),true);
   }else{
      displayData := StdOutData.get();
      if ( pos('commit failed',StdErrData.get(),1,'i') ) {
         displayData = StdErrData.get();
      }
      _SccDisplayOutput(displayData,true);

      // Set the local status to blank so that these files no longer appear 
      // locally modified
      len = filelist._length();
      for ( i=0;i<len;++i ) {
         WATCHED_FILE_INFO fileInfo;
         initFileInfo(fileInfo);
         _GetFileInfo(filelist[i],fileInfo);
         fileInfo.VCLocalStatus = "";
         _SetFileInfo(filelist[i],fileInfo);
      }
   }
   //if ( !status && taglist!='' ) {
   //   _CVSTag(filelist,OutputFilename,taglist,true);
   //}
   delete_file(filelist_filename);
   _reload_vc_buffers(filelist);
   return(status);
}

int _SVNWriteListFile(_str (&filelist)[],_str &filelist_filename,boolean setFilename=true)
{
   if ( setFilename ) {
      // Dump the files into a list so that we can use the --targets option
      filelist_filename=mktemp();
   }
   int temp_wid,orig_wid;
   int status=_open_temp_view(filelist_filename,temp_wid,orig_wid,"+t");
   if (status) return(status);
   int i,len=filelist._length();

   boolean is_cygwin=false;
#if !__UNIX__
   _str svn_exe_name=_SVNGetSVNExeName();
   if (pos("cygwin",svn_exe_name)) {
      is_cygwin=true;
   }
#endif

   for ( i=0;i<len;++i ) {
      // For the Cygwin Subversion, it really wants to see a
      // /cygdrive/<driveletter>/pathWithUnixFilesep style filename
      _str cur=stranslate(relative(filelist[i]),'/',FILESEP);
#if !__UNIX__
      if ( is_cygwin ) {
         if ( substr(cur,2,1)==':' ) {
            cur="/cygdrive/":+substr(cur,1,1):+substr(cur,3);
         }
      }
#endif
      if (_UTF8()) cur = _MultiByteToUTF8(cur);
      insert_line(cur);
   }
   status=_save_file("+o");
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);
   return(status);
}

/**
 * Commit the current buffer, or <b>filename</b> if it is specified
 * @param filename file to commit, uses current buffer if ''.  If '' and no
 *        windows are open, it uses the Open file dialog to prompt
 * @return int 0 if successful
 */
_command int svn_commit(typeless filename='',_str comment=NULL_COMMENT) name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_commit(filename,comment);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:24am 4/10/2013
   int status=cvs_commit(filename,comment,_SVNCommit);
   return(status);
#endif
}

/**
 * Adds the menu to the history dialog
 */
static void svn_history_add_menu()
{
   int index=find_index("_svn_history_menu",oi2type(OI_MENU));
   if ( index ) {
      int b4height=p_client_height;
      int menu_handle=p_active_form._menu_load(index);
      p_active_form._menu_set(menu_handle);
   }
}

static int SVNDiffTwoURLs(_str URL1,_str URL2,_str version1="",_str version2="")
{
   version1=SVNGetVersionFromCaption(version1);
   version2=SVNGetVersionFromCaption(version2);
   _str OutputFilename1;
   int status=_SVNCheckoutFile(URL1,"",'-r 'version1,OutputFilename1);
   if ( status ) {
      // CVSCheckoutVersion would have given user an error message
      return(status);
   }
   _str OutputFilename2;
   status=_SVNCheckoutFile(URL2,"",'-r 'version2,OutputFilename2);
   if ( status ) {
      // CVSCheckoutVersion would have given user an error message
      return(status);
   }
   int orig_view_id,fileViewID1,fileViewID2,junk_view_id;

   // Open the first remote file, call select edit mode with the file's extension
   lang := _Filename2LangId(URL1);
   status = _open_temp_view(OutputFilename1,fileViewID1,orig_view_id);
   if ( status ) return(status);
   _SetEditorLanguage(lang);

   // Open the second remote file, call select edit mode with the file's extension
   p_window_id = orig_view_id;
   status = _open_temp_view(OutputFilename2,fileViewID2,junk_view_id);
   if ( status ) return(status);
   _SetEditorLanguage(lang);

   p_window_id = orig_view_id;

   _str dispname1=URL1' (Version 'version1' - Remote)';
   _str dispname2=URL2' (Version 'version2' - Remote)';

   status=_DiffModal('-r1 -r2 -viewid1 -viewid2 -nomapping -file1title "'dispname1'" -file2title "'dispname2'" 'fileViewID1' 'fileViewID2);

   // Close the views
    _delete_temp_view(fileViewID1);
    _delete_temp_view(fileViewID2);

   // Delete the temporary files
   delete_file(OutputFilename1);
   delete_file(OutputFilename2);

   return(status);
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
static int SVNDiffPastVersions(_str remote_filename,_str version1,_str version2)
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
   status=_SVNCheckoutFile(remote_filename,"",'-r 'version2,OutputFilename2);
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

int _OnUpdate_svn_history_diff_past(CMDUI &cmdui,int target_wid,_str command)
{
   if( target_wid.p_name != '_cvs_history_form' &&
       target_wid.p_parent.p_name != '_cvs_history_form' ) {

      return(MF_GRAYED);
   }
   _str ver1='',ver2='';
   int status=_SVNGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   status=_menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with other version...');
   return(MF_ENABLED);
}

/**
 * Command to be run from menu on history dialog, cannot be run from command line or key
 * Diffs two past verisons of the file being displayed
 *
 * @return int 0 if successful
 */
_command int svn_history_diff_past()
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return(COMMAND_CANCELLED_RC);
   }
   _str filename=SVNGetFilenameFromHistoryDialog();
   _str remote_filename='';
   int status=_SVNGetFileURL(filename,remote_filename);
   if ( status ) {
      _message_box(nls("Could not get remote filename for %s\n\n%s",filename,get_message(status)));
      return(status);
   }
   CVSHistoryDiffPast(remote_filename,SVNDiffPastVersions);
   return(0);
}

static _str _SVNGetRevisionString(int index)
{
   _str version=_TreeGetCaption(index);
   parse version with version " (" . ;
   return strip(version);
}

int _SVNGetVersionsFromHistoryTree(_str &ver1,_str &ver2='',int &index1=-1,int &index2=-1)
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   int state,bm1;
   _TreeGetInfo(index,state,bm1);

   while ( bm1==_pic_branch ) {
      index=_TreeGetParentIndex(index);
      if ( index<0 ) {
         return(1);
      }
      _TreeGetInfo(index,state,bm1);
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   ver1=_SVNGetRevisionString(index);
   index1 = index;

   for ( ;; ) {
      sibindex := _TreeGetPrevSiblingIndex(index);
      if ( sibindex<0 ) {
         sibindex = _TreeGetParentIndex(index);
         if ( sibindex<0 ) {
            return(1);
         }
      }
      index = sibindex;
      _TreeGetInfo(index,state,bm1);
      if ( bm1!=_pic_branch ) break;
   }
   if ( index==TREE_ROOT_INDEX ) {
      return(1);
   }
   ver2=_SVNGetRevisionString(index);
   index2 = index;

   p_window_id=wid;
   return(0);
}

int _OnUpdate_svn_history_diff_predecessor(CMDUI &cmdui,int target_wid,_str command)
{
   if( target_wid.p_name != '_cvs_history_form' &&
       target_wid.p_parent.p_name != '_cvs_history_form' ) {

      return(MF_GRAYED);
   }
   _str ver1='',ver2='';
   int status=_SVNGetVersionsFromHistoryTree(ver1,ver2);
   if ( status ) {
      return(MF_GRAYED);
   }
   _menu_set_state(cmdui.menu_handle,cmdui.menu_pos,0,'P','Diff version 'ver1' with version 'ver2);
   return(MF_ENABLED);
}

static void getURLErrorMessage(_str filename,int status)
{
   errString := nls("Could not get remote filename for %s\n\n%s",filename,get_message(status));
#if !__UNIX__
   // 11:05:08 AM 4/20/2010
   // On Windows our version of svn has trouble with "svn info abc.cpp" if the
   // file was actually checked in as "ABC.cpp".  This is a bit confusing to 
   // people since the file system itself is not case sensitive. 
   errString = errString :+ nls("\n\nIf this file is a valid Subversion resource, this could be an issue with the case of the local filename.");
#endif 
   _message_box(errString);
}

/**
 * Command to be run from menu on history dialog, cannot be run from command line or key
 *
 * Diffs the current item in the tree with the prior version
 *
 * @return int 0 if successful
 */
_command int svn_history_diff_predecessor()
{
   if ( p_active_form.p_name!='_cvs_history_form' ) {
      // Do not want to run this from the command line, etc.
      return(COMMAND_CANCELLED_RC);
   }
   int wid=ctltree1;
   _str ver1='',ver2='';
   int status=_SVNGetVersionsFromHistoryTree(ver1,ver2,auto treeIndex1,auto treeIndex2);
   if ( status ) {
      return(status);
   }
   _str filename=SVNGetFilenameFromHistoryDialog();
   _str remote_filename='';
   status=_SVNGetFileURL(filename,remote_filename);
   if ( status ) {
      getURLErrorMessage(filename,status);
      return(status);
   }
   // Have to do some extra work to get the branches for each file to be sure we
   // are comparing the right files.
   ctltree1.getSVNURLFromTreeIndex(auto fileURL1,treeIndex1);
   ctltree1.getSVNURLFromTreeIndex(auto fileURL2,treeIndex2); 
   if ( fileURL1!="" &&fileURL2!="" ) {
      SVNDiffTwoURLs(fileURL1,fileURL2,ver1,ver2);
   }else{
      SVNDiffPastVersions(remote_filename,ver1,ver2);
   }
   wid._set_focus();
   return(status);
}

_command int svn_review_and_commit(_str cmdline='') name_info(FILE_ARG'*,')
{
   int status = svn_diff_with_tip(cmdline);
   if (status == COMMAND_CANCELLED_RC) {
      return status;
   }
   return svn_commit(cmdline);
}

/**
 * Diff the current file, or file specified in <b>cmdline</b> with the tip
 * of the current branch in Subversion
 * @param cmdline a filename to be diffed
 *
 * @return int 0 if successful
 */
_command int svn_diff_with_tip(_str cmdline='') name_info(FILE_ARG'*,')
{
   // 4/10/2013
   // We supported a -readonly arg here. It seems we never used it.  Continue
   // pull off args.  We could potentially allow versions here.
   filename := "";
   for ( ;; ) {
      _str cur=parse_file(cmdline);
      if ( cur=='' ) break;
      _str ch1=substr(cur,1,1);
      if ( ch1=='-' ) {
      } else {
         filename=cur;
      }
   }
   if ( cmdline=='' ) filename=p_buf_name;
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_diff_with_tip(cmdline);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:27am 4/10/2013
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
   int status=SVNDiffWithVersion(filename,-1,false,'',lang);
   return(status);
#endif
}

/**
 * Diff the current file, or file specified in <b>cmdline</b> 
 * with the current BASE revision in the local working copy 
 * @param cmdline a filename to be diffed
 *
 * @return int 0 if successful
 */
_command int svn_diff_with_base(_str cmdline='') name_info(FILE_ARG'*,'){
   // 4/10/2013
   // We supported a -readonly arg here. It seems we never used it.  Continue
   // pull off args.  We could potentially allow versions here.
   filename := "";
   for ( ;; ) {
      _str cur=parse_file(cmdline);
      if ( cur=='' ) break;
      _str ch1=substr(cur,1,1);
      if ( ch1=='-' ) {
      } else {
         filename=cur;
      }
   }
   if ( cmdline=='' ) filename=p_buf_name;
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_diff_with_tip(cmdline);
   def_vc_system = orig_def_vc;
   return 0;

#if 0 //10:32am 4/10/2013
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
   // Load the working copy version of the file
   _LoadEntireBuffer(filename,lang);

   // get the relative filename
   path := _strip_filename(filename,'N');
   relativeFilename := relative(filename,path);

   // Use <svn cat -r BASE filename>  to get the local working
   // copy BASE revision, and place it in a temp buffer.
   _str tempFileBase = '';
   status := _SVNCheckoutFile(relativeFilename,filename, ' -r BASE', tempFileBase, true);
   if ( status ) {
      if ( status!=FILE_NOT_FOUND_RC ) {
         _str msg=nls("Could not checkout BASE version of '%s'",filename);
         _message_box(msg);
      }
      return(status);
   }

   int wid=p_window_id;
   int temp_view_id,orig_view_id;
   _str encoding_option=_load_option_encoding(filename);
   status=_open_temp_view(tempFileBase,temp_view_id,orig_view_id,encoding_option);
   p_window_id = wid;
   if ( status ) {
      if ( status ) {
         _message_box(nls("Could not open BASE version of  '%s'",filename));
      }
      delete_file(tempFileBase);
      return(status);
   }
   temp_view_id._SetEditorLanguage(lang);
   delete_file(tempFileBase);


   // Run diff between filename and the temp_view_id
   _str file1Title = '"' :+ filename :+ ' (Working Copy)"';
   _str file2Title = '"' :+ filename :+ ' (BASE)"';
   _str diffCmdLine = '-modal -nomapping -vcdiff svn -r2 -viewid2 -file1Title ' :+ file1Title :+ ' -file2title ' :+ file2Title :+ ' ' :+ maybe_quote_filename(filename) :+ ' ' :+ temp_view_id;
   status = _DiffModal(diffCmdLine,"svn");
   
   _delete_temp_view(temp_view_id);
   
   return (status);
#endif
}


static int _GetAllFilePathsForProject(_str projectFilename,_str workspaceFilename,STRARRAY &pathList)
{
   _str ProjectFiles[];
   _str workpacePath;
   int i;
   // Get all the project files in the workspace
   workpacePath=_file_path(workspaceFilename);
   STRARRAY fileList;
   _str pathHashtab:[];
   // Get all the files in the current project
   absProjectFilename := absolute(projectFilename,workpacePath);
   status := _getProjectFiles(workpacePath, absProjectFilename, fileList, 1);

   // Save all of the paths.   Use them as the key in a hashtable so we will
   // have list of unique paths

   // Be sure to add in the project's working directory in case there were no
   // files in it.
   projectWorkingDir := absolute(_ProjectGet_WorkingDir(_ProjectHandle(absProjectFilename)),_file_path(absProjectFilename));

   // This should have a filesep, but be certain
   _maybe_append_filesep(projectWorkingDir);

   // Add a . because later we will use _file_path
   fileList[fileList._length()] = projectWorkingDir:+'.';

   // Go through and make the hashtable
   fileListLen := fileList._length();
   for ( j:=0;j<fileListLen;++j ) {
      curPath := _file_case(_file_path(fileList[j]));
      pathHashtab:[curPath] = '';
   }
   // Copy the hashtable into pathList
   foreach ( auto key => auto val in pathHashtab ) {
      pathList[pathList._length()] = key;
   }
   return 0;
}

static int _GetAllFilePathsForWorkspace(_str workspaceFilename,STRARRAY &pathList)
{
   _str ProjectFiles[];
   _str workpace_path;
   int i;
   // Get all the project files in the workspace
   status:=_GetWorkspaceFiles(workspaceFilename,ProjectFiles);
   if (status) {
      _message_box(nls("Unable to open workspace '%s'",workspaceFilename));
      return(1);
   }
   workpace_path=_strip_filename(workspaceFilename,'N');
   STRARRAY fileList;
   _str pathHashtab:[];
   // Loop thru all the projects in the workspace
   for (i=0;i<ProjectFiles._length();++i) {
      _GetAllFilePathsForProject(ProjectFiles[i],workspaceFilename,pathList);
   }
#if 0 //12:55pm 4/5/2011
   // Copy the hashtable into pathList
   foreach ( auto key => auto val in pathHashtab ) {
      pathList[pathList._length()] = key;
   }
   // We are not removing anything from the list, we will let Subversion figure 
   // it out
#endif
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
static _str _SVNGetPath(_str caption='Choose path')
{
   return(_CVSGetPath(caption,'_svn_path_form'));
}

enum SVN_UPDATE_TYPE {
   SVN_UPDATE_PATH,
   SVN_UPDATE_WORKSPACE,
   SVN_UPDATE_PROJECT
};

/**
 * Shows the GUI update dialog for <b>path</b>
 * @param path Path to show update dialog for.  If path is "", it will use a dialog to prompt
 *
 * @return int
 */
_command int svn_update_directory,svn_gui_mfupdate(_str path='',SVN_UPDATE_TYPE updateType=SVN_UPDATE_PATH ) name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_gui_mfupdate(path);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:33am 4/10/2013
   path = strip(path,'B','"');
   if ( path=='' ) {
      path=_SVNGetPath();
      if ( path=='' ) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   if ( updateType!=SVN_UPDATE_PROJECT ) _maybe_append_filesep(path);
   _str list=path;
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
         }
      } else {
         path=cur;
         break;
      }
   }
   path=absolute(path);

   boolean could_not_verify_setup=false;
   int status=0;
   if ( status==COMMAND_CANCELLED_RC ) {
      return(status);
   }else if ( status ) could_not_verify_setup=true;

   SVN_STATUS_INFO Files[];
   _str vcs="Communicating with the ":+VCSYSTEM_TITLE_SUBVERSION:+" server.  This may take a moment";
   boolean operation_failed=false;

   STRARRAY pathList;
   STRARRAY pathsToUpdate;
   if ( updateType==SVN_UPDATE_WORKSPACE || updateType==SVN_UPDATE_PROJECT ) {
      // If this is a workspace comparison, we have to calculate which paths to
      // do. We get all of the workking paths for the projects, and then calculate
      // the minimum number of paths we do the update for
      workspacePath := _file_path(_workspace_filename);
      pathList = null;
      if ( updateType==SVN_UPDATE_WORKSPACE ) {
         _GetAllFilePathsForWorkspace(_workspace_filename,pathList);
         _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);
      } else if ( updateType==SVN_UPDATE_PROJECT ) {
         projectFilename := path;
         _GetAllFilePathsForProject(projectFilename,_workspace_filename,pathList);
         projectWorkingDir := _ProjectGet_WorkingDir(_ProjectHandle(projectFilename));
         _SVNGetUpdatePathList(pathList,projectWorkingDir,pathsToUpdate);
      }

      numPathsToUpdate := pathsToUpdate._length();

      _str badPathList="";
      if ( numPathsToUpdate ) {
         // We use a pointer to _CVSShowStallForm so that it is only called the first
         // iteration (because we set it to null after that)
         pfnStallForm := _CVSShowStallForm;
         for ( i:=0;i<numPathsToUpdate;++i ) {
            status=_SVNGetVerboseFileInfo(pathsToUpdate[i],Files,recurse_option,recurse_option,'',true,pfnStallForm/*_CVSShowStallForm*/,null/*_CVSKillStallForm*/,&vcs,null,false,-1,operation_failed,true);
            if ( status ) {
               if ( status == FILE_NOT_FOUND_RC ) {
                  badPathList = badPathList', 'pathsToUpdate[i];
               } else {
                  if (could_not_verify_setup) {
                     _message_box(nls("Could not get Subversion status information.\n\nSlickEdit's %s setup check also failed.  You may not have read access to these files, or your Subversion setup may be incorrect.",VCSYSTEM_TITLE_SUBVERSION));
                  }
                  // Have to manuall call _CVSKillStallForm
                  _CVSKillStallForm();
                  return(status);
               }
            }
            pfnStallForm = null;
         }
         
         // First get spaces
         badPathList = strip(badPathList);
         // Now get commas
         badPathList = strip(badPathList,'B',',');

         if ( badPathList!="" ) {
            _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_FOR_PATH_RC,badPathList));
         }
         // Have to manuall call _CVSKillStallForm
         _CVSKillStallForm();
      }
   } else {
      status=_SVNGetVerboseFileInfo(path,Files,recurse_option,recurse_option,'',true,_CVSShowStallForm,_CVSKillStallForm,&vcs,null,false,-1,operation_failed);
      if (status) {
         if (could_not_verify_setup) {
            _message_box(nls("Could not get Subversion status information.\n\nSlickEdit's %s setup check also failed.  You may not have read access to these files, or your Subversion setup may be incorrect.",VCSYSTEM_TITLE_SUBVERSION));
         }
         return(status);
      }
   }
   if ( Files._length() ) {
      SVNGUIUpdateDialog(Files,path,pathsToUpdate,'',recurse_option);
   } else if ( !status && !operation_failed ) {
      _message_box(nls("All files up to date"));
   }

   return(0);
#endif
}

_command int svn_gui_update_workspace() name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_gui_mfupdate_workspace();
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:34am 4/10/2013
   status := 0;
   workspacePath := _file_path(_workspace_filename);
   status = svn_gui_mfupdate(' -r 'maybe_quote_filename(workspacePath),SVN_UPDATE_WORKSPACE);
   return status;
#endif
}

_command int svn_gui_update_project(_str projectName=_project_name) name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_gui_mfupdate_project();
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:36am 4/10/2013
   status := 0;
   status = svn_gui_mfupdate(' -r 'maybe_quote_filename(projectName),SVN_UPDATE_PROJECT);
   return status;
#endif
}

/**
 * Runs svn update on the current buffer or <b>filename</b>.  This should
 * probably be re-done to do something more like _SVNCommit and re-use more
 * of the cvs code
 * @param filename name of file to update.  If "", uses the current buffer, if
 *        no current window, uses the open file dialog
 *
 * @return int 0 if successful
 */
_command int svn_update(_str filename='') name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_update(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:37am 4/10/2013
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
   _str OutputFilename='';
   int status=_SVNUpdate(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

/**
 * Gets information about <b>path</b> from Subversion.
 * To get the information that we need here, CVS would require us to run a status
 * and an update.  We want to keep the parameters in sync, so an unusual number of these are not actually
 * used.
 *
 * @param path path/file to get inormation about
 * @param Files Information is returned in this variable
 * @param module_name_NOTUSED stays here to keep params in sync w/ _CVS version of this function
 * @param recurse Recurse subdirs
 * @param run_from_path Path to run command from
 * @param treat_as_wildcard Treat <b>path</b> as a wildcard
 * @param pfnPreShellCallback callback to run before this function (usually used for animations)
 * @param pfnPostShellCallback callback to run after this function (usually used for animations)
 * @param pData data to pass to callback functions
 * @param IndexHTab Hash table of array indexes, indexed by filename
 * @param RunAsynchronous if true, run this command asynchronously
 * @param pid1 pid of "first" command (for Subversion there really only is one, CVS required two commands to get this information)
 * @param operation_failed This is set to true if the operation actually failed.  We often report the
 *                          return code from svn, and sometimes it returns 0 even though it failed.
 *
 * @return int 0 if successful
 */
int _SVNGetVerboseFileInfo(_str path,SVN_STATUS_INFO (&Files)[],_str module_name_NOTUSED='',
                           boolean recurse=true,_str run_from_path='',
                           boolean treat_as_wildcard=true,
                           typeless *pfnPreShellCallback=null,
                           typeless *pfnPostShellCallback=null,
                           typeless *pData=null,
                           int (&IndexHTab):[]=null,
                           boolean RunAsynchronous=false,
                           int &pid1=-1,boolean &operation_failed=false,
                           boolean quietFileNotFound=false)
{
   operation_failed=false;
   _str orig_path=getcwd();
   _str shell_path=path;
   if ( run_from_path!='' ) {
      int status=chdir(run_from_path,1);
      if ( status ) {
         return(status);
      }
      shell_path=run_from_path;
   }else{
      // If path is just a filename this will be the current directory and
      // that is ok. run_from_path is used below so it has to be set.
      run_from_path=_strip_filename(absolute(path),'N');
   }
   _str non_recursive_option='';
   if ( !recurse ) {
      non_recursive_option=' -N ';
   }
   path=strip(path);
   _str wildcard='';
   if ( treat_as_wildcard ) {
      wildcard=_strip_filename(path,'P');
   } else {
      wildcard=path;
   }
   _str async_option=RunAsynchronous?'a':'';
   String StdOutData,StdErrData;
   int status=_CVSPipeProcess(_SVNGetExeAndOptions()' --non-interactive  status --show-updates ' non_recursive_option' 'wildcard,shell_path,'P'def_cvs_shell_options:+async_option,StdOutData,StdErrData,
                              false,pfnPreShellCallback,pfnPostShellCallback,pData,pid1,false,false);
   if ( pos("'.' is not a working copy",StdErrData)!=0 ) {
      status = FILE_NOT_FOUND_RC;
   }
   if ( status || pos("Can't connect to host",StdErrData) ) {
      operation_failed=true;
      if (status!=COMMAND_CANCELLED_RC &&
          !(quietFileNotFound && status==FILE_NOT_FOUND_RC)
          ) {
         _message_box(get_message(SVN_COMMAND_RETURNED_ERROR_RC,_SVNGetSVNExeName(),"status",status));
         _SccDisplayOutput(StdErrData,true);
      }
      return(status);
   }

   // Do not check status here - it is unreliable. We will look through the
   // output instead
   if (status==COMMAND_CANCELLED_RC) {
      // It is ok to check for this status, it came from the user pressing the
      // ok button
      return(status);
   }
   int temp_view_id;
   int orig_wid=_create_temp_view(temp_view_id);
   _insert_text(StdErrData.get());
   _insert_text(StdOutData.get());

   status=SVNGetAllFileInfoFromOutput(temp_view_id,Files,run_from_path,IndexHTab);

   p_window_id=orig_wid;
   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Show the GUI update dialog
 * @param Files Info to dispaly in the dialog
 * @param path local path for
 * @param module_name deprecated
 * @param recursive true if update was recursive
 */
static void SVNGUIUpdateDialog(SVN_STATUS_INFO Files[],_str path,STRARRAY &pathList,_str module_name,boolean recursive)
{
   int formid=show('-xy -app -new _cvs_mfupdate_form');
   formid.p_active_form.p_caption=VCSYSTEM_TITLE_SUBVERSION:+' ':+formid.p_active_form.p_caption;
   formid._SetDialogInfo(SVN_WAS_RECURSIVE,recursive);
   formid.ctltree1.SVNSetupTree(Files,path,pathList);
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
void _SVNGetFileBitmap(SVN_STATUS_INFO &File,int &bitmap1,int default_bitmap=_pic_cvs_file,
                       boolean DoubleCheckConflict_NOTUSED=true)
{
   bitmap1=default_bitmap;
   if ( File.status_flags&SVN_STATUS_NOT_CONTROLED ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_qm;
      } else {
         bitmap1=_pic_cvs_file_qm;
      }
      return;
   }
   if ( File.status_flags&SVN_STATUS_MISSING ) {
      bitmap1=_pic_file_del;
      return;
   }
   if ( File.status_flags&SVN_STATUS_SCHEDULED_FOR_DELETION ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_m;
      }else{
         bitmap1=_pic_cvs_filem_mod;
      }
      return;
   }
   if ( File.status_flags&SVN_STATUS_SCHEDULED_FOR_ADDITION ) {
      if ( isdirectory(File.local_filename) ) {
         bitmap1=_pic_cvs_fld_p;
      }else{
         bitmap1=_pic_cvs_filep;
      }
      return;
   }
   if ( File.status_flags&SVN_STATUS_TREE_ADD_CONFLICT ) {
      bitmap1 = _pic_cvs_file_conflict_local_added;
      return;
   }
   if ( File.status_flags&SVN_STATUS_TREE_DEL_CONFLICT ) {
      bitmap1 = _pic_cvs_file_conflict_local_deleted;
      return;
   }

   if ( File.status_flags&SVN_STATUS_CONFLICT ) {
      bitmap1=_pic_cvs_file_conflict;
   }else{
      if ( File.status_flags&SVN_STATUS_MODIFIED ) {
         if ( File.status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
            bitmap1=_pic_file_old_mod;
         }else{
            bitmap1=_pic_file_mod;
         }
      }else if ( File.status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
         if ( last_char(File.local_filename)==FILESEP ) {
            if ( isdirectory(File.local_filename) ) {
               bitmap1=_pic_cvs_fld_date;
            }else{
               bitmap1=_pic_cvs_fld_m;
            }
         }else{
            if ( file_exists(File.local_filename) ) {
               bitmap1=_pic_file_old;
            }else{
               bitmap1=_pic_cvs_file_new;
            }
         }
      } else if ( File.status_flags&SVN_STATUS_PROPS_MODIFIED ) {
         if ( isdirectory(File.local_filename) ) {
            bitmap1=_pic_cvs_fld_mod;
         }
      }
   }
}

static _str GetRepositoryURLList(_str (&pathList)[])
{

   len := pathList._length();
   _str URLTable:[];
   for ( i:=0;i<len;++i ) {
      status := _SVNGetFileURL(pathList[i],auto curURL);
      if ( !status ) URLTable:[curURL] = "";
   }
   _str URLList = "";
   foreach ( auto key => auto value in URLTable ) {
      URLList = URLList', 'key;
   }
   URLList = strip(URLList);
   URLList = strip(URLList,'B',',');
   return URLList;
}

/**
 * Sets up the tree for the GUI update.
 * @param Files Files to put in the tree
 * @param path Root path for the update
 * @param module_name_NOTUSED Keeping params in sync w/ CVS version of this
 *        function
 */
static void SVNSetupTree(SVN_STATUS_INFO Files[],_str path,STRARRAY &pathList=null)
{
   _TreeDelete(TREE_ROOT_INDEX,'C');
   int PathIndexes1:[]=null;

   INTARRAY seedIndexList;
   int firstChild = -1;
   if ( pathList==null ) {
      firstChild=_TreeAddItem(TREE_ROOT_INDEX,path,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);

      // Seed the tree and table with the root index.  Since this is a local
      // directory, we know this exists
      _CVSSeedPathIndexes(path,PathIndexes1,firstChild);
   } else {
      len := pathList._length();
      for ( i:=0;i<len;++i ) {
         int newindex=_TreeAddItem(TREE_ROOT_INDEX,pathList[i],TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
         // Seed the tree and table with the root index.  Since this is a local
         // directory, we know this exists
         _CVSSeedPathIndexes(pathList[i],PathIndexes1,newindex);
         seedIndexList[seedIndexList._length()] = newindex;
      }
   }

   int QMIndexes[]=null;
   int i;
   for ( i=0;i<Files._length();++i ) {
      int parent_bitmap_index=_pic_fldopen;
      _str end_char=last_char(Files[i].local_filename);
      typeless isdir=isdirectory(Files[i].local_filename);
      if ( last_char(Files[i].local_filename)==FILESEP &&
           Files[i].status_flags==SVN_STATUS_MISSING ) {
         parent_bitmap_index=_pic_cvs_fld_m;
      }
      int index1=_CVSGetPathIndex(_file_path(Files[i].local_filename),path,PathIndexes1,_pic_fldopen,_pic_cvs_fld_m);

      int bitmap1 = -1;
      if ( isdir && file_eq(path,Files[i].local_filename) && firstChild>0 ) {
         _SVNGetFileBitmap(Files[i],auto rootBitmap);
         _TreeGetInfo(firstChild,auto state);
         _TreeSetInfo(firstChild,state,rootBitmap);
      }
      if ( isdir && Files[i].status_flags==SVN_STATUS_NOT_CONTROLED ) {
         // Save this for later
         QMIndexes[QMIndexes._length()]=index1;
      }else if (isdir && Files[i].status_flags==SVN_STATUS_PROPS_MODIFIED ) {
         pathIndex := _CVSGetPathIndex(_file_path(Files[i].local_filename),path,PathIndexes1,_pic_fldopen,_pic_cvs_fld_m);
         if ( pathIndex>0 ) {
            _SVNGetFileBitmap(Files[i],bitmap1);
            _TreeGetInfo(pathIndex,auto state);
            _TreeSetInfo(pathIndex,state,bitmap1);
         }
      }else if (Files[i].status_flags==SVN_STATUS_NOT_CONTROLED ) {
      }
      if ( parent_bitmap_index==_pic_cvs_fld_m ) {
         // This can't really be open, won't detect subfolders under it
         _TreeSetInfo(index1,-1);
      }
      if ( bitmap1<0 ) _SVNGetFileBitmap(Files[i],bitmap1);

      if ( end_char!=FILESEP && !isdir ) {
         int newindex1=_TreeAddItem(index1,_strip_filename(Files[i].local_filename,'P'),TREE_ADD_AS_CHILD,bitmap1,bitmap1,-1);
      }else{
         int node_flags=0;
         int state;
         int bm1,bm2;
         _TreeGetInfo(index1,state,bm1,bm2,node_flags);
         if ( Files[i].status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
            _TreeSetInfo(index1,state,_pic_cvs_fld_date,_pic_cvs_fld_date,node_flags);
         }else if ( Files[i].status_flags&SVN_STATUS_SCHEDULED_FOR_ADDITION ) {
            _TreeSetInfo(index1,state,_pic_cvs_fld_p,_pic_cvs_fld_p,node_flags);
         }
      }
   }
   for ( i=0;i<QMIndexes._length();++i ) {
      _TreeSetInfo(QMIndexes[i],0,_pic_cvs_fld_qm,_pic_cvs_fld_qm);
   }

   // We seeded the tree with each of the possible update paths.  If there were
   // no changes under these paths, there will be no children of those tree nodes
   // and we can delete them
   seedIndexListLength := seedIndexList._length();
   for ( i=0;i<seedIndexListLength;++i ) {
      childIndex := _TreeGetFirstChildIndex(seedIndexList[i]);
      if ( childIndex<0 ) {
         _TreeDelete(seedIndexList[i]);
      }
   }

   ctltree1._TreeSortTree();
   ctllocal_path_label._CVSSetPathLabel(path);
   URLList := GetRepositoryURLList(pathList);
   ctlrep_label._CVSSetPathLabel(URLList);
   _SetDialogInfo(SVN_TREE_FILE_INFO,Files);
   ctltree1._SVNEnableButtons();
}

/**
 * Gets the information from the svn status output and puts it into SVN_STATUS_INFO
 * structure
 * @param StatusOutputFilename File with output in it
 * @param Files Array of structure that get this information
 * @param root_path local root path
 * @param IndexHTab Hashtable of array indexes indexed by filename
 *
 * @return int
 */
static int SVNGetAllFileInfoFromOutput(int StatusOutputViewId,SVN_STATUS_INFO (&Files)[],_str root_path,
                                       int (&IndexHTab):[]=null
                                       )
{
   int orig_view_id=p_window_id;
   p_window_id=StatusOutputViewId;
   top();up();
   SVN_SUBDIR_INFO info;
   SVNGetSVNVersion(auto version);
   _str last_local_filename="";
   while ( !down() ) {
      _str cur_line='';
      get_line(cur_line);
      _str working_revision='';
      _str local_filename='';
      if ( !SVNIsStatusAgainstRevision(cur_line) && cur_line!="" ) {
         int status_flags=SVNGetStatusFlagsFromLine(cur_line,version,working_revision,local_filename,root_path,info);

         if ( local_filename=='' ) {
            int last=Files._length()-1;
            SVN_STATUS_INFO *plast_entry=&(Files[last]);
            plast_entry->status_flags |= status_flags;
         } else {
            int len=Files._length();
            SVN_STATUS_INFO *plast_entry=&(Files[len]);
            plast_entry->local_filename=local_filename;
            plast_entry->status_flags=status_flags;
            plast_entry->working_revision=working_revision;
            IndexHTab:[_file_case(plast_entry->local_filename)]=len;
         }

         last_local_filename = local_filename;
      }
   }
   p_window_id=orig_view_id;
   return(0);
}

int _svn_update_resolve_button()
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   int i,len=indexlist._length();
   int treewid=ctltree1;
   if ( len ) {
      resolveCommand := "svn resolve --accept working";
      msg := nls("Resolve this conflict?\n\nThis will run '%s %s'",resolveCommand,filelist[0]);
      if ( len>1 ) {
         msg = nls("Resolve these conflicts?\n\nThis will run '%s' for each selected file",resolveCommand);
      }
      result := _message_box(msg,"",MB_YESNOCANCEL);
      SVN_STATUS_INFO Files[];
      STRARRAY fileList;
      if ( result==IDYES ) {
         for (i=0;i<len;++i) {
            int state,bm1,bm2;
            //ctltree1._TreeGetInfo(ctltree1._TreeCurIndex(),state,bm1,bm2);
            ctltree1._TreeGetInfo(indexlist[i],state,bm1,bm2);

            _str filename=_CVSGetFilenameFromUpdateTree(indexlist[i]);
            fileList[fileList._length()] = filename;
            _SVNResolve(filename,auto fileInfo);
            Files[Files._length()] = fileInfo;
         }
         SVNRefreshTreeBitmaps(indexlist,fileList,Files);
      }
   }
   return 0;
}

/**
 * Callback for "Diff" button on subversion update dialog
 *
 * @return int
 */
int _svn_update_diff_button()
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
         status=SVNDiffPastVersions(remote_filename,local_version,version_to_compare);
         chdir(origdir,1);
      } else {
         status=SVNDiffWithVersion(filename,version_to_compare,false);
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
         SVN_STATUS_INFO info[];
         _str module_name='';
         _SVNGetVerboseFileInfo(filename,info);
         if ( info!=null ) {
            int bitmap_index;
            _SVNGetFileBitmap(info[0],bitmap_index);
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
 * Callback for "History" button on subversion update dialog
 *
 * @return int
 */
int _svn_update_history_button()
{
   _str filename=_CVSGetFilenameFromUpdateTree();
   return( svn_history(filename,1) );
}

/**
 * Callback for "Commit" button on subversion update dialog
 *
 * @return int
 */
int _svn_update_commit_button()
{
   int wid=p_window_id;
   SVN_STATUS_INFO Files[]=null;

   _str filelist[]=null;
   int indexlist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);
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
               _SVNCommit(filelist,temp_filename,OutputFilename,true,'',append_to_output,&Files,tag);
            }
            break;
         } else {
            _str cur=filelist[i];

            _str tempfiles[]=null;
            tempfiles[0]=cur;
            status=_SVCCheckLocalFilesForConflicts(tempfiles);
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
            status=_SVNCommit(tempfiles,temp_filename,OutputFilename,true,'',append_to_output,&Files,tag);
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

   SVNRefreshTreeBitmaps(indexlist,whole_filelist,Files);

   ctltree1._set_focus();
   _SVNEnableButtons();
   return(0);
}

/**
 * Update the bitmaps for certain items in the tree on GUI update dialog
 * @param indexlist List of tree indexes to check on
 * @param filelist List of filenames to check on
 * @param Files List of SVN_STATUS_INFO structs of items to check ondw
 */
static void SVNRefreshTreeBitmaps(int (&indexlist)[],_str (&filelist)[],SVN_STATUS_INFO (&Files)[])
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
         _SVNGetFileBitmap(Files[j],bm1);
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
 * Gets information about the version of <b>filename</b> on the repository
 * NOTE:Acceses repository, if you do not need something specifically from here,
 * try to use one of the funcitons that does not
 *
 * @param filename name of file to check on
 * @param current_version current version of the file returned here
 * @param author last author to check the file in returned here
 * @param date_and_time date/time of last check in returned here
 *
 * @return int 0 if successful
 */
int _SVNGetRemoteInfo(_str filename,_str &current_version,_str &author='',
                      _str &date_and_time='')
{
   int temp_view_id;_str ErrorFilename;
   int status=_SVNGetLogInfoForFile(filename,temp_view_id,true,"-q");
   if ( status ) {
      _message_box(get_message(SVN_COULD_NOT_GET_LOG_INFO_RC,filename));
      return(status);
   }
   xmlhandle := _xmlcfg_open_from_buffer(temp_view_id,status,VSXMLCFG_OPEN_ADD_PCDATA);
   if ( xmlhandle>=0 ) {
      childIndex := _xmlcfg_find_simple(xmlhandle,"/log");
      logEntryIndex := _xmlcfg_get_first_child(xmlhandle,childIndex,~(VSXMLCFG_NODE_PCDATA|VSXMLCFG_NODE_ATTRIBUTE) );
      if ( logEntryIndex>-1 ) {
         current_version = _xmlcfg_get_attribute(xmlhandle,logEntryIndex,"revision");

         authorIndex := _xmlcfg_find_child_with_name(xmlhandle,logEntryIndex,"author");
         if ( authorIndex>-1 ) {
            author = _xmlcfg_get_attribute(xmlhandle,logEntryIndex,"author");
         }

         date_and_timeIndex := _xmlcfg_find_child_with_name(xmlhandle,logEntryIndex,"date_and_time");
         if ( date_and_timeIndex>-1 ) {
            date_and_time = _xmlcfg_get_attribute(xmlhandle,logEntryIndex,"date");
         }
      }
      _xmlcfg_close(xmlhandle);
   }

   _delete_temp_view(temp_view_id);
   return(status);
}

/**
 * Looks at <i>index_to_update</i> to see if we can call update for that item
 * or if the first "real" parent directory is what we need to call update for
 *
 * @param index_to_update index that we want to call update for
 * @param parent_update_index "real" parent directory index that we can call update on
 *
 * @return non-zero if the "real" parent directory should be updated instead of
 *         <i>index_to_update</i>.  0 if <i>index_to_update</i> can be updated.
 */
static int SVNMustUpdateParentDirectory(int index_to_update,int &parent_update_index)
{
   // index_to_update could be a filename or a path.  Get the path index
   _str filename=_TreeGetCaption(index_to_update);
   int path_index=index_to_update;
   _str path_name='';
   if ( last_char(filename)==FILESEP ) {
      path_name=filename;
   }else{
      path_index=_TreeGetParentIndex(index_to_update);
      path_name=_TreeGetCaption(path_index);
   }

   // Get the bitmap indexes
   int state,bm1,bm2;
   _TreeGetInfo(path_index,state,bm1,bm2);

   // If this is not the picture for a folder that is out of date, return
   if ( bm1!=_pic_cvs_fld_date && 
        bm1!=_pic_cvs_fld_m ) {
      return(0);
   }

   int rv=0;
   // Have to look for a directory that exists locally
   for (;;) {
      _TreeGetInfo(path_index,state,bm1,bm2);
      if ( bm1<=0 || (bm1!=_pic_cvs_fld_date&&bm1!=_pic_cvs_fld_m) ) {
         break;
      }
      _str cur_path=_TreeGetCaption(path_index);
      rv=1;
      if ( isdirectory(cur_path) ) {
         // If this directory exists we can stop here
         break;
      }
      path_index=_TreeGetParentIndex(path_index);
   }
   parent_update_index=path_index;
   return(rv);
}

/**
 * Goes through the list of indexes and figures out if the "whole parent path"
 * needs to be updated instead.  If so, replaces those items in the lists with
 * the parent item
 * @param indexlist List of indexes in the tree, must be parallel to <b>filelist</b>
 * @param filelist List of filenames/paths, must be parallel to <b>indexlist</b>
 *
 * @return int 0 if successful
 */
static int SVNVerifyUpdateParents(int (&indexlist)[],_str (&filelist)[],boolean quiet)
{
   int parent_index_table:[];
   int i,len=indexlist._length();
   _str parent_update_path='';
   for (i=0;i<len;++i) {
      // In subversion we cannot update a directory that does not exist.  For
      // example, if we are in directory A, and B only exists on the server, and
      // A is the current directory, "svn update B" will not get us a copy of B.
      // parent_update_index is the index of a "real" directory that we can
      // actually update
      int parent_update_index;
      if ( SVNMustUpdateParentDirectory(indexlist[i],parent_update_index) ) {
         if ( parent_index_table:[parent_update_index]==null ) {
            // We have not yet prompted the user about this directory
            //
            // Add this directory to the table.  We will no longer prompt the user
            // about updating this directory
            parent_index_table:[parent_update_index]=parent_update_index;
            parent_update_path=_TreeGetCaption(parent_update_index);
            _str cur_item=_TreeGetCaption(indexlist[i]);
            int result;
            if ( quiet ) {
               result = IDOK;
            }else{
               result=_message_box(nls("In order to update '%s', you must update the entire '%s' directory.\n\nDo you wish to update this directory now?",cur_item,parent_update_path),"",MB_OKCANCEL);
            }
            if ( result!=IDOK ) {
               return(COMMAND_CANCELLED_RC);
            }

            {
               // Put the parent path in if it isn't there - linear search one
               // of the arrays.  Only wawnt to do this once,so we do it the same
               // iteration that we add the the parent_update_path to
               // parent_index_table
               int found=0,j;
               for (j=0;j<len;++j) {
                  if ( indexlist[j]==parent_update_index ) {
                     found=1;break;
                  }
               }
               if ( !found ) {
                  indexlist[indexlist._length()]=parent_update_index;
                  filelist[filelist._length()]=parent_update_path;
               }
            }
         }
         // If this is not a real path (it is a child file or path), remove it from the list
         if ( !file_eq(parent_update_path,filelist[i]) ) {
            indexlist._deleteel(i);
            filelist._deleteel(i);
            --i;--len;
         }
      }
   }
   return(0);
}

static int getMergeFiles(_str filename,_str &baseFilename,_str &rev1Filename,_str &rev2Filename)
{
   _str numberedFile1="";
   _str numberedFile2="";
   int numNumberedFiles=0;
   for ( ff:=1;;ff=0 ) {
      curMergeFile := file_match(filename'.*',ff);
      if ( curMergeFile=="" ) break;
      if ( file_eq(curMergeFile,filename) ) {
         // on Windows, we will hit "filename", even though we specified
         // "filename.*",  and we have to skip it.
         continue;
      }else if ( _get_extension(curMergeFile)=='mine' || _get_extension(curMergeFile)=='working') {
         rev2Filename = curMergeFile;
      }else {
         ++numNumberedFiles;
         if ( numberedFile1=="" ) {
            numberedFile1 = curMergeFile;
         }else{
            numberedFile2 = curMergeFile;
         }
      }
      if ( rev2Filename!="" && numberedFile1!="" && numberedFile2!="" ) break;
   }
   if ( rev2Filename=="" ) {
      _message_box(nls("Could not find file '%s.mine' or '%s.working'\n\nYou will have to resolve this conflict manually.",filename));
      return FILE_NOT_FOUND_RC;
   }
   if ( numNumberedFiles<2 ) {
      _message_box(nls("Could not find two revision files\n\nYou will have to resolve this conflict manually.",filename));
      return FILE_NOT_FOUND_RC;
   }
   file1num := substr(_get_extension(numberedFile1),2);
   file2num := substr(_get_extension(numberedFile2),2);
   if ( file1num<file2num ) {
      baseFilename = numberedFile1;
      rev1Filename = numberedFile2;
   }else{
      baseFilename = numberedFile2;
      rev1Filename = numberedFile1;
   }
   return 0;
}

int _SVNResolve(_str filename,SVN_STATUS_INFO &fileInfo)
{
   // get the relative filename
   path := _strip_filename(filename,'N');
   relativeFilename := relative(filename,path);

   _str command=_SVNGetExeAndOptions():+" --non-interactive resolve --accept working "maybe_quote_filename(relativeFilename);
   String StdOutData,StdErrData;
   status := _CVSPipeProcess(command,filename,'P'def_cvs_shell_options,StdOutData,StdErrData,
                            false,null,null,null,-1,false,false);
   if ( status ) {
      _message_box(nls("%s failed\n\nReturn code=%s",command,status));
      return status;
   }
   SVN_STATUS_INFO tempFiles[];
   status=_SVNGetVerboseFileInfo(filename,tempFiles,"",false,'',false,_CVSShowStallForm,_CVSKillStallForm);
   fileInfo = tempFiles[0];
   return status;
}

int _svn_update_merge_button()
{
   int indexlist[]=null;
   SVN_STATUS_INFO Files[]=null;
   _str fileList[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,fileList);

   _str curFile = "";
   foreach ( curFile in fileList ) {
      status := getMergeFiles(curFile,auto baseFilename,auto rev1Filename,auto rev2Filename);
      if ( status ) break;
      merge(baseFilename:+' ':+rev1Filename:+' 'rev2Filename:+' 'curFile);
      result := _message_box(nls("Resolve this conflict?\n\nThis will run '%s'","svn resolve --accept working "curFile),"",MB_YESNO);
      if ( result==IDYES ) {
         status = _SVNResolve(curFile,auto fileInfo);
         Files[Files._length()] = fileInfo;
         if ( status ) break;
      }else{
         // Still have to get file status
         SVN_STATUS_INFO tempFiles[];
         status=_SVNGetVerboseFileInfo(curFile,tempFiles,"",false,'',false,_CVSShowStallForm,_CVSKillStallForm);
         Files[Files._length()] = tempFiles[0];
      }
   }

   SVNRefreshTreeBitmaps(indexlist,fileList,Files);

   return 0;
}

/**
 * Callback for "Update" button on subversion update dialog
 *
 * @return int 0 if successful
 */
int _svn_update_update_button(_str UpdateOptions='')
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);

   int child_index_table:[];
   quiet := _GetDialogInfoHt("userClickedUpdateAll");
   quiet = quiet==null?false:quiet;
   int status=ctltree1.SVNVerifyUpdateParents(indexlist,filelist,quiet);
   if ( status ) {
      return(status);
   }

   // Check to see if there are conflicts in these files
   boolean conflict=false;
   int i;
   for ( i=0;i<indexlist._length();++i ) {
      int state,bm1;
      ctltree1._TreeGetInfo(indexlist[i],state,bm1);
      if ( bm1==_pic_cvs_file_conflict ) {
         conflict=true;
         break;
      }
   }

   if ( conflict ) {
      int result=_message_box(nls("This update will cause conflicts that will need to be resolved before a commit.\n\nContinue?"),'',MB_YESNO);
      if ( result==IDNO ) {
         return(COMMAND_CANCELLED_RC);
      }
   }

   _str OutputFilename='';
   SVN_STATUS_INFO Files[]=null;

   boolean updated_new_dir=false;
   status=_SVNUpdate(filelist,OutputFilename,false,&Files,updated_new_dir,UpdateOptions,p_active_form);

   if ( status ) {
      _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
      delete_file(OutputFilename);
      return(status);
   }

   if ( !updated_new_dir ) {
      SVNRefreshTreeBitmaps(indexlist,filelist,Files);
   } else {
      _str local_path;
      parse ctllocal_path_label.p_caption with 'Local Path:','i' local_path;

      Files._makeempty();
      _str module_name='';
      boolean recursive=_GetDialogInfo(SVN_WAS_RECURSIVE);
      _SVNGetVerboseFileInfo(local_path,Files,recursive);
      ctltree1.SVNSetupTree(Files,local_path);
   }

   if ( conflict ) {
      int len=filelist._length();
      for (i=0;i<len;++i) {
         _mdi.edit(maybe_quote_filename(filelist[i]));
         _mdi.p_child.search('^<<<<<<< ','@rh');
      }
   }
   delete_file(OutputFilename);
   return(status);
}

/**
 * Updates the files in <b>filelist</b>
 * @param filelist list of files to update
 * @param OutputFilename filename that gets the output of the svn update command.
 *        If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param append_to_output if true <b>OutputFilename</b> is appended to instead of overwritten
 * @param pFiles_NOTUSED Just here to keep parmas in sync with CVS version of this
 *        function
 * @param updated_new_dir is set to true if a new directory was updated
 * @param UpdateOptions options that will be passed to SVNBuildUpdateCommand
 * @param gaugeParent wid to be parent of gauge dialog
 *
 * @return int 0 if successful
 */
int _SVNUpdate(_str filelist[],_str &OutputFilename,
              boolean append_to_output=false,
               SVN_STATUS_INFO (*pFiles)[]=null,
              boolean &updated_new_dir=false,_str UpdateOptions='',
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
      if ( file_eq(ext,PRJ_FILE_EXT) ) {
         _ProjectCache_Update(filelist[i]);
      }
   }
   int status=_CVSCommand(filelist,SVNBuildUpdateCommand,&UpdateOptions,OutputFilename,append_to_output,pFiles,updated_new_dir,_SVNGetVerboseFileInfo);
   if ( status ) {
      displayOutputStatus := _SVCDisplayErrorOutputFromFile(OutputFilename,1);
      if ( displayOutputStatus ) {
         if ( status==FILE_NOT_FOUND_RC || status==PATH_NOT_FOUND_RC ) {
            _message_box(nls("Could not update file(s)\n\n%s\n\nIt is possible that the parent directory does not exist and has to be updated first",get_message(status)));
         }
      }
   }else{
      // Set the server status to blank so that these files no longer appear 
      // remotely modified (out of date)
      len = filelist._length();
      for ( i=0;i<len;++i ) {
         WATCHED_FILE_INFO fileInfo;
         initFileInfo(fileInfo);
         _GetFileInfo(filelist[i],fileInfo);
         fileInfo.VCServerStatus = "";
         _SetFileInfo(filelist[i],fileInfo);
      }
   }
   _reload_vc_buffers(filelist);
   _retag_vc_buffers(filelist);
   if ( gaugeParent ) {
      cancel_form_set_parent(gaugeParent);
   }
   return(status);
}

/**
 * Adds the files in filelist to Subversion
 * @param filelist file to add to Subversion
 * @param OutputFilename File that gets output from svn add command.  If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param append_to_output if true, <b>OutputFilename</b> is appended to rather than overwritten
 * @param pFiles Resulting file info from Subversion (status command run after add command if this param is not 0)
 * @param updated_new_dir set to true if we updated a new directory
 * @param add_options options to be passed to SVNBuildAddCommand
 *
 * @return int
 */
int _SVNAdd(_str filelist[],_str &OutputFilename,
            boolean append_to_output=false,
            SVN_STATUS_INFO (*pFiles)[]=null,
            boolean &updated_new_dir=false,
            _str add_options='')
{
   int status=_CVSCommand(filelist,SVNBuildAddCommand,&add_options,OutputFilename,append_to_output,pFiles,updated_new_dir,_SVNGetVerboseFileInfo);
   return(status);
}

/**
 * Adds <b>filename</b> current buffer to Subversion
 *
 * Should probably be re-written more like svn_commit
 * @param filename file to be added.    If this is
 *        '', uses the current buffer.  If there is no window open, it will
 *        display an open file dialog
 *
 * @return int 0 if successful
 */
_command int svn_add(_str filename='') name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_add(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:38am 4/10/2013
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
   filename = strip(filename,'B','"');
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   _str temp[]=null;
   temp[0]=filename;
   _str OutputFilename='';
   int status=_SVNAdd(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

/**
 * Reverts <b>filename</b> current buffer to version in
 * repository
 *
 * @param filename file to be added.    If this is
 *        '', uses the current buffer.  If there is no window open, it will
 *        display an open file dialog
 *
 * @return int 0 if successful
 */
_command int svn_revert(_str filename='') name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_revert(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:38am 4/10/2013
   if ( _no_child_windows() && filename=='' ) {
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
   } else if ( filename=='' ) {
      filename=p_buf_name;
   }
   if ( !file_exists(filename) ) {
      _message_box(nls("The file '%s' does not exist",filename));
      return(FILE_NOT_FOUND_RC);
   }
   _str temp[]=null;
   temp[0]=filename;
   _str OutputFilename='';
   int status=_SVNRevert(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

/**
 * Callback for "Add" button on subversion update dialog
 *
 * @return int
 */
int _svn_update_add_button()
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

   SVN_STATUS_INFO Files[]=null;
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
      status=SVNAddSelectedFiles(dirs,&Files,add_options);
      if ( status ) return(status);
   }

   if ( filenames._length() ) {
      status=SVNAddSelectedFiles(filenames,&Files,add_options);
      if ( status ) return(status);
   }

   if ( !dirs._length() ) {
      SVNRefreshTreeBitmaps(indexlist,filenames,Files);
   } else {
      _str local_path;
      parse ctllocal_path_label.p_caption with 'Local Path:','i' local_path;

      Files._makeempty();
      _str module_name='';
      boolean recursive=_GetDialogInfo(SVN_WAS_RECURSIVE);
      _SVNGetVerboseFileInfo(local_path,Files,recursive);

      int wid=p_window_id;
      p_window_id=ctltree1;
      SVNSetupTree(Files,local_path);

      // We just deleted and re-filled the tree.  We want to check and see if
      // there is anything that we just added that we can select.
      boolean selected=false;
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

/**
 * Adds the selected files to Subvesrion
 * @param filelist List of files to add
 * @param pFiles Resulting file info from Subversion (status command run after add command if this param is not 0)
 * @param add_options options to pass to SVNBuildAddCommand
 *
 * @return int 0 if successful
 */
static int SVNAddSelectedFiles(_str (&filelist)[],
                               SVN_STATUS_INFO (*pFiles)[]=null,
                               _str add_options='')
{
   _str OutputFilename='';

   boolean updated_new_dir=false;
   int status=_SVNAdd(filelist,OutputFilename,false,pFiles,updated_new_dir,add_options);

   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   delete_file(OutputFilename);

   return(status);
}

/**
 * Removes a file from Subversion
 * @param filename filename to remove from Subversion.  If this is
 *        '', uses the current buffer.  If there is no window open, it will
 *        display an open file dialog
 *
 * @return int 0 if successful
 */
_command int svn_remove(_str filename='') name_info(FILE_ARG'*,')
{
   orig_def_vc := def_vc_system;
   def_vc_system = "Subversion";
   svc_remove(filename);
   def_vc_system = orig_def_vc;
   return 0;
#if 0 //10:39am 4/10/2013
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
   int result=_message_box(nls("'%s' must be deleted by this operation.\n\nThis will use the --force option.\n\nDelete file now?",filename),'',MB_OKCANCEL);
   if ( result!=IDOK ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str temp[]=null;
   temp[0]=filename;
   _str OutputFilename='';
   int status=_SVNRemove(temp,OutputFilename);
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
#endif
}

/**
 * Remove items in <b>filelist</b> from Subversion
 * @param filelist list of files to remove
 * @param OutputFilename Name of file that gets the output of svn remove command.  If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param append_to_output if true <b>OutputFilename</b> is appended to instead of overwritten
 * @param pFiles Resulting file info from Subversion (status command run after add command if this param is not 0)
 * @param updated_new_dir updated_new_dir set to true if we updated a new directory
 * @param add_options options to be passed to SVNBuildAddCommand
 *
 * @return int 0 if successful
 */
int _SVNRemove(_str filelist[],_str &OutputFilename,
               boolean append_to_output=false,
               CVS_LOG_INFO (*pFiles)[]=null,
               boolean &updated_new_dir=false,
               _str add_options='')
{
   int status=_CVSCommand(filelist,SVNBuildRemoveCommand,&add_options,OutputFilename,append_to_output,pFiles,updated_new_dir);
   return(status);
}

/**
 * Shows the subversion setup dialog
 */
_command void svn_setup()
{
   config("Subversion", 'V');
}

/**
 *
 * @param URL Remot directory to checkout
 * @param directory_name local directory to checkout to
 * @param checkout_options options to pass to "cvs co"
 * @param OutputFilename Filename that gets the output of "svn co".  If "" is passed in, this will be filled in with a filename for the calller to delete
 * @param quietif true, do not display animations
 * @param debug deprecated, set _CVSDebug instead
 * @param NoHourglass if true do not change cursor to an hourglass
 *
 * @return int 0 if successful
 */
int _SVNCheckout(_str URL,_str directory_name,_str checkout_options,_str &OutputFilename,
                 boolean quiet=false,boolean debug=false,boolean NoHourglass=false)
{
   _str parent_directory=_GetParentDirectory(directory_name);
   _str rel_dir=relative(directory_name,parent_directory);
   if (first_char(rel_dir)==FILESEP) {
      rel_dir=substr(rel_dir,2);
   }
   _maybe_strip_filesep(rel_dir);
   typeless *pfnPreShellCallback=null,pfnPostShellCallback=null;
   _str caption='';
   if ( !quiet ) {
      pfnPreShellCallback=_CVSShowStallForm;
      pfnPostShellCallback=_CVSKillStallForm;
      caption='Checking out 'URL;
   }
   boolean append_to_output=true;
   if (OutputFilename=='') {
      OutputFilename=mktemp();
      append_to_output=false;
   }
   int status=_CVSCall('co','','',checkout_options' 'maybe_quote_filename(URL)' 'maybe_quote_filename(rel_dir),parent_directory,OutputFilename,
                      append_to_output,false,pfnPreShellCallback,pfnPostShellCallback,&caption,NoHourglass,_SVNGetExeAndOptions);
   if (OutputFilename!='' && !status) {
      int temp_view_id,orig_view_id;
      status=_open_temp_view(OutputFilename,temp_view_id,orig_view_id);
      if (!status) {
         top();up();
         status=(int)!search('(Caught signal)|(is already a file/something else)','@rh');
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
   }
   //delete_file(OutputFilename);
   return(status);
}
/**
 * returns true if <B>filename</B> is a file that was checked
 * out from Subversion.  Does this by looking to see if a Subversion
 * directory exists under filename's directory.
 *
 * @param filename filename to check
 *
 * @return true if file is a Subversion file.
 */
boolean IsSubversionFile(_str filename)
{
   _str URL;
   int status=_SVNGetFileURL(filename,URL);
   return(!status);
}
_command int svn_get_annotated_buffer(_str filename='') name_info(FILE_ARG'*,')
{
   lang := "";
   restore_linenum := false;
   if ( filename=='' ) {
      _str bufname='';
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
   if ( !IsSubversionFile(filename) ) {
      _message_box(nls("'%s' was not checked out from %s",filename,VCSYSTEM_TITLE_SUBVERSION));
      return(1);
   }
   relative_filename := relative(filename);
#if !__UNIX__
   relative_filename = stranslate(relative_filename,FILESEP2,FILESEP);
#endif
   if ( lang == '' ) {
      lang = _Filename2LangId(filename);
   }
   ln := p_line; col := p_col;
   mou_hour_glass(1);
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

   status = _CVSPipeProcess(_SVNGetExeAndOptions():+" annotate ":+cvs_tag_option:+" ":+maybe_quote_filename(relative_filename),'','P'def_cvs_shell_options,auto StdOutData,auto StdErrData);
   mou_hour_glass(0);
   if ( status ) {
      _message_box(nls("svn annotate failed for file '%s'\n\nsvn returned %s",relative_filename,status));
      return status;
   }
   edit('+t');
   _delete_line();

   p_DocumentName="Annotations for ":+filename;
   _SetEditorLanguage(lang);
   _insert_text_raw(StdOutData.get());
   p_modify=0;
   p_ReadOnly = 1;

   top();
   if ( restore_linenum ) {
      p_line = ln; p_col = col;
   }
   return status;
}

void _SVNEnableButtons()
{
   _EnableGUIUpdateButtons("svn");
}

int _svn_update_revert_button()
{
   int indexlist[]=null;
   _str filelist[]=null;

   ctltree1._CVSGetAllFilesFromUpdateTree(indexlist,filelist);
   if (filelist==null || filelist._length()==0) {
      return 0;
   }

   // Check to see if there are conflicts in these files
   boolean conflict=false;
   int i;
   for ( i=0;i<indexlist._length();++i ) {
      int state,bm1;
      ctltree1._TreeGetInfo(indexlist[i],state,bm1);
      if ( bm1==_pic_cvs_file_conflict ) {
         conflict=true;
         break;
      }
   }

   _str OutputFilename='';
   SVN_STATUS_INFO Files[]=null;

   status := _SVNRevert(filelist,OutputFilename);

   SVNRefreshTreeBitmaps(indexlist,filelist,Files);

   _SVCDisplayErrorOutputFromFile(OutputFilename,status,p_active_form);
   if (file_exists(OutputFilename)) {
      delete_file(OutputFilename);
   }

   if ( status ) {
      return(status);
   }

   return(status);
}

defeventtab _svn_history_choose_form;

void ctlok.on_create()
{
   if ( def_svn_flags&SVN_FLAG_SHOW_BRANCHES ) {
      ctlAllBranches.p_value = 1;
   }else{
      ctlCurBranch.p_value = 1;
   }
   // Retrieve prev form.  If user chooses not to prompt for this 
   // (SVN_FLAG_DO_NOT_PROMPT_FOR_BRANCHES) we will use def_svn_flags&SVN_FLAG_SHOW_BRANCHES
   // rather than show this form at all
   _retrieve_prev_form();
}

void ctlok.lbutton_up()
{
   showBranches := 0;
   if ( ctlAllBranches.p_value == 1 ) {
      // value for whether or not the user will show branches is returned in 
      // _param1
      _param1 = 1;
   }else if ( ctlCurBranch.p_value == 1 ) {
      _param1 = 0;
   }
   if ( ctlremember.p_value ) {
      // depending on whether or not the user has chosen to remember the setting
      // we will set the SVN_FLAG_SHOW_BRANCHES flag
      if ( _param1 ) {
         def_svn_flags |= SVN_FLAG_SHOW_BRANCHES;
      }else{
         def_svn_flags &= ~SVN_FLAG_SHOW_BRANCHES;
      }
      def_svn_flags |= SVN_FLAG_DO_NOT_PROMPT_FOR_BRANCHES;
   }
   // Save the form response.  If user chooses not to prompt for this 
   // (SVN_FLAG_DO_NOT_PROMPT_FOR_BRANCHES) we will use def_svn_flags&SVN_FLAG_SHOW_BRANCHES
   // rather than show this form at all
   _save_form_response();
   p_active_form._delete_window(0);
}

/**
 * May show _svn_history_choose_form
 * 
 * @param showBranches set to true if def_svn_flags&SVN_FLAG_SHOW_BRANCHES
 * @return int 0 if succesful. COMMAND_CANCELLED_RC if the 
 *         dialog is show and the user cancels it.
 */
static int getSVNShowBranches(boolean &showBranches)
{
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
#if 0 //9:21pm 5/4/2010
_command void test_getSVNShowBranches() name_info(',')
{
   status := getSVNShowBranches(auto showBranches);
   say('test_getSVNShowBranches status='status' showBranches='showBranches);
}
#endif
/**
 * @param path path to test
 * @param parentPath possible parent of <b>path</b>
 * 
 * @return boolean true if <b>path</b> is a child of <b>parentPath</b>
 */
boolean _pathIsParentDirectory(_str path,_str parentPath)
{
   lenPath := length(path);
   lenParentPath := length(parentPath);
   if ( lenPath < lenParentPath )  {
      return false;
   }
   pieceOfPath := substr(path,1,lenParentPath);
   match := file_eq(pieceOfPath,parentPath);
   return match;
}

static void getTopSVNPath(_str curPath,_str topPath,_str &topSVNPath)
{
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

#if 0 //2:57pm 7/15/2010
_command void test_show_paths_to_update() name_info(',')
{
   STRARRAY pathList;
   _GetAllProjectWorkingDirs(_workspace_filename,pathList);
   workspacePath := _file_path(_workspace_filename);
   STRARRAY pathsToUpdate;

   t1 := _time('b');
#if 0 //10:56am 6/7/2010
   say('****************************************************************************************************');
   say('pathsToUpdate._length()='pathsToUpdate._length());
   if ( pathsToUpdate._length() ) {
      say('pathsToUpdate[0]='pathsToUpdate[0]);
   }
#endif
   _SVNGetUpdatePathList(pathList,workspacePath,pathsToUpdate);
   t2 := _time('b');
   len := pathsToUpdate._length();
   say('****************************************************************************************************');
   say('time='(int)t2-(int)t1);
   for ( i:=0;i<len;++i ) {
      say('test_show_paths_to_update pathsToUpdate['i']='pathsToUpdate[i]);
   }
}
#endif

/**
 * Go through <B>projPaths</B> and figure out the minimum paths 
 * that need to be updated and return that in 
 * <B>workspacePath</B>.  Use <B>workspacePath</B> if possible 
 * 
 * @param projPaths list of project working paths returned by 
 *                  <B>GetAllProjectPaths</B>
 * @param workspacePath path that the workspace file exists in
 * @param pathsToUpdate list of paths that must be updated to 
 *                      get their version control status
 */
void _SVNGetUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[])
{
   _str pathsSoFar:[];

   len := projPaths._length();
//   say('****************************************************************************************************');
   for ( i:=0;i<len;++i ) {
      curPath := projPaths[i];
      getTopSVNPath(curPath,workspacePath,auto topSVNPath);
//      say('_SVNGetUpdatePathList curPath='curPath' topSVNPath='topSVNPath);
      if ( topSVNPath!="" && !pathsSoFar._indexin(topSVNPath) ) {
         pathsToUpdate[pathsToUpdate._length()] = topSVNPath;
         pathsSoFar:[topSVNPath] = "";
      }
   }

   // If we have a workspace with files added from several other directories, 
   // this still may not be the minimum set of paths.  Sort, and then remove any
   // paths where pathsToUpdate[i+1] is a substr of pathsToUpdate[i].  This will
   // elimate cases like:
   // pathsToUpdate[0] = c:\src\Proj1
   // pathsToUpdate[1] = c:\src\Proj1\io
   // pathsToUpdate[2] = c:\src\Proj1\log
   // pathsToUpdate[3] = c:\src\Proj1\diff
   //
   // Where only c:\src\Proj1 needs to be updated
   pathsToUpdate._sort('F');
   for ( i=0;i<pathsToUpdate._length();++i ) {
      if ( i+1>=pathsToUpdate._length() ) break;

      if ( file_eq(pathsToUpdate[i],substr(pathsToUpdate[i+1],1,length(pathsToUpdate[i]))) ) {
         pathsToUpdate._deleteel(i+1);
         --i;
      }
   }
}
