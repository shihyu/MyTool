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
#include "VCCache.sh"
#require "sc/lang/String.e"
#require "se/vc/VCCacheManager.e"
#require "se/vc/VCRepositoryCache.e"
#require "se/vc/VCBaseRevisionItem.e"
#require "se/vc/VCBranch.e"
#require "se/vc/VCFile.e"
#require "se/vc/VCLabel.e"
#require "se/vc/VCRepository.e"
#import "help.e"
#import "main.e"
#import "subversion.e"
#import "subversionutil.e"
#import "cvsutil.e"
#import "stdprocs.e"
#import "stdcmds.e"
#endregion

using sc.lang.String;

using se.vc.vccache.VCCacheManager;
using se.vc.vccache.VCRepositoryCache;
using se.vc.vccache.VCBaseRevisionItem;
using se.vc.vccache.VCBranch;
using se.vc.vccache.VCFile;
using se.vc.vccache.VCLabel;
using se.vc.vccache.VCRepository;

/**
 * A global reference to an SVN version cache
 * 
 * @author shackett (9/11/2009)
 */
VCCacheManager g_svnCacheManager;

definit()
{
   VCCacheManager svnCacheManager();
   g_svnCacheManager = svnCacheManager;
}

/**
 * Updates the revision cache to store any check ins that have happened since 
 * the last call to this function. 
 * 
 * @author shackett (9/24/2009)
 */
_command void UpdateSvnVersionCache(_str svnURL="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   // get the cache for slickedit for now
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(svnURL);
   asyncUpdate := cache.requiresAsyncUpdate();
   int status = cache.updateVersionCache(asyncUpdate);
   if (status != 0) {
      message('Unable to dump contents of 'cache.get_RepositoryUrl()'.');
   }
   for ( ;; ) {
      if ( !cache.vcProcessRunning() ) {
         break;
      }
   }
   //gUpdateCacheTimer = _set_timer(1000,checkForCacheUpdate); 
}

/** 
 * Dumps the contents of the database to the VSAPI console window 
 *  
 * 1 = FILES table
 * 2 = FILE_REVISION_XREF table
 * 4 = REVISIONS table
 * 8 = BRANCHES table
 * 16 = REVISION_BRANCH_XREF table
 * 32 = LABELS table
 * 64 = REVISION_LABEL_XREF table
 * 
 * @author shackett (9/24/2009)
 * 
 * @param flags : Bitwise value 
 *              consisting of the
 *              listed flag
 *              values.
 */
_command void DumpDatabaseContents(_str svnURL="", int flags=255) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   // get the cache for slickedit for now
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(svnURL);
   // send the contents to the VSAPI console window
   cache.dumpDatabaseContents(flags);
}

/**
 * This is a sample command to show how the getRevisions function can be called 
 * and how the results can be traversed. 
 * 
 * @author shackett (9/24/2009)
 * 
 * @param fileName : the full path of the file to get revision history for.
 */
_command void GetFilesForRevision(_str svnURL="", int revisionID=0) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   VCFile files[];

   // get the cache for slickedit for now
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(svnURL);
   // get the revisions and labels for the specified file
   int status = cache.getFilesForRevision(revisionID, files);
   if (status == 0) {
      // print the file info
      int i;
      for (i = 0; i < files._length(); i++) {
         VCFile file = files[i];
         say("File: "file.get_FileSpec());
      }
   } else {
      message('Unable to get the files for revision with ID 'revisionID': status='status);
   }
}

/**
 * This is a sample command to show how the getRevisions function can be called 
 * and how the results can be traversed. 
 * 
 * @author shackett (9/24/2009)
 * 
 * @param fileName : the full path of the file to get revision history for.
 */
_command void GetRevisionsForFile(_str fileName="") name_info(FILE_ARG'*'','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   VCBranch root;
   VCLabel labels[];
   url := "";

   // get the cache for slickedit for now
   _SVNGetBranchForLocalFile(fileName,auto branchName,auto repositoryRoot,auto subFilename);
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(repositoryRoot);

   // determine whether or not this file is in SVN
   int status = _SVNGetFileURL(fileName, url);
   if (status != 0) {
      _message_box(fileName' is not a under SVN source control.');
      return;
   }

   // determine if we need to do a file update
   asyncUpdate := cache.requiresAsyncUpdate();
   if (asyncUpdate == true) {
      _str msg = "The cache file for "cache.get_RepositoryUrl()" hasn't been ";
      msg :+= 'updated in more than 'def_vccache_synchro_update_limit' days and ';
      msg :+= 'must be updated synchronously.  Continue?';
      _str response = _message_box(msg, 'SlickEdit', MB_YESNO);
      // if so, then re-run initialization
      if (response != IDYES)
         return;
   }

   // update the version cache
   status = cache.updateVersionCache(asyncUpdate);
   if (status != 0) {
      message('Unable to update the cache for 'cache.get_RepositoryUrl()'.');
      return;
   }

   // get the revisions and labels for the specified file
   status = cache.getRevisions(fileName, root, labels, false);
   if (status == 0) {
      // now print the branch from the trunk
      cache.printRevisionTreeItem(root, "");
      // print the labels
      int i;
      for (i = 0; i < labels._length(); i++) {
         VCLabel label = labels[i];
         say("Label: "label.get_ParentBranchID()", "label.get_Number()", "label.get_Name()", "label.get_Author()", "label.get_Timestamp()"): "label.get_Comments());
      }
   } else {
      message('Unable to get the revisions for file 'fileName': status='status);
   }
}

/**
 * Tests to see whether or not the version of SVN is compatible with using 
 * vccacheupdtr to get SVN history. The version of SVN must be greater than 1.6
 * 
 * @return bool - true if compatible, false if not.
 */
bool isSvnVersionOkForVCCache()
{
   // Keep the original directory
   String StdOutData,StdErrData;
   status := 0;

   _str command = _SVNGetExeAndOptions()' --version';
   status=_CVSPipeProcess(command,'','P'def_cvs_shell_options,StdOutData,StdErrData,false,null,null,null,-1,false,false);
   if (status != 0) {
      return false;
   }
   // get the output data
   _str outdata = StdOutData.get();
   if (def_vccache_debug == 1) {
      say('Output from SVN version query='outdata);
   }
   // search for the version
   tokenPosBegin := pos('version', outdata);
   if (tokenPosBegin) {
      // add 8 (the length of 'version ')
      tokenPosBegin += 8;
      // search for the next whitespace after 'version ' (8 chars)
      tokenPosEnd := pos(' ', outdata, tokenPosBegin);
      if (tokenPosEnd) {
         // alright, let's get the version number
         versionNumber := substr(outdata, tokenPosBegin, tokenPosEnd - tokenPosBegin);
         versionNumber = strip(versionNumber);
         if (def_vccache_debug == 1) {
            say('Returned SVN version="'versionNumber'"');
         }
         // parse out the version number
         _str major;
         _str minor;
         _str rev;
         _str build;
         parse versionNumber with major '.' minor '.' rev '.' build;
         if ((isinteger(major) == true) && (isinteger(minor) == true)) {
            // make sure that the version is 1.6 or higher
            if (major > 2) {
               return true;
            } else if ((major == 1) && (minor >= 6)) {
               return true;
            }
         }
      }
   }
   return false;
}

/**
 * Fixes the case where something catastrophic happened and the version cache 
 * is in a bad state and needs to be rebuilt. 
 */
_command void repair_version_cache(_str svnURL="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   // get the cache for slickedit for now
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(svnURL);
   // repair the version cache
   success := cache.repairCacheFile();
   if (success == true) {
      _message_box('Successfully repaired version cache for 'svnURL'.');
      // update the def-var to use the new style SVN history
      def_svn_use_new_history = 1;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else {
      _message_box('Unable to repair version cache for 'svnURL'.');
   }
}

/**
 * Fixes the case where something catastrophic happened and the version cache 
 * is in a bad state and needs to be rebuilt. 
 */
_command void is_branch_history_available(_str svnURL="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return;
   }
   // get the cache for slickedit for now
   VCRepositoryCache cache = g_svnCacheManager.getSvnCache(svnURL);
   // repair the version cache
   success := cache.isSvnCapable();
   if (success == true) {
      _message_box('Repository 'svnURL' is capable of performing SVN branch history.');
   } else {
      _message_box('Repository 'svnURL' is not capable of performing SVN branch history.');
   }
}

