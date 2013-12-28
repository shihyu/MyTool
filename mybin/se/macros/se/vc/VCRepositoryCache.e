////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#include "VCCache.sh"
#import "backtag.e"
#import "xmlcfg.e"
#import "main.e"
#import "files.e"
#import "subversionutil.e"
#import "stdprocs.e"
#import "fileman.e"
#require "se/datetime/DateTime.e"
#import "se/datetime/DateTimeInterval.e"
#require "se/vc/VCBranch.e"
#require "se/vc/VCLabel.e"
#require "se/vc/VCCacheExterns.e"
#require "se/vc/VCCacheExterns.e"
#endregion Imports

using se.datetime.DateTime;
using se.datetime.DateTimeInterval;

namespace se.vc.vccache;

#define SVN_CACHE_SUCCESS 0
#define SVN_INVALID_ARGS -1
#define SVN_DATABASE_ERROR -2
#define SVN_SHELL_ERROR -3
#define SVN_INCAPABLE_ERROR -4
#define SVN_LOG_PARSE_ERROR -5
#define SVN_TOO_LONG_ERROR -6

/**
 * The version cache manager for an SVN reporitory.  
 * 
 * @author shackett (9/11/2009)
 */
class VCRepositoryCache {
   private _str m_rootFolder = "";
   private _str m_repositoryUrl = "";
   private _str m_cacheFileName = "";
   private _str m_tempLogFileName = "";
   private _str m_statusFileName = "";
   private boolean m_isInitialized = false;
   private int m_processID = -1;

   // constructor
   public VCRepositoryCache()
   {
   }

   public _str get_RepositoryUrl()
   {
      return m_repositoryUrl;
   }

   public _str get_CacheFileName()
   {
      return m_cacheFileName;
   }

   public _str get_TempLogFileName()
   {
      return m_tempLogFileName;
   }

   public _str get_StatusFileName()
   {
      return m_statusFileName;
   }

   /**
   * Returns the name of the local cache database file that will be used.  This
   * file name is derived from the SVN URL.
   * 
   * @author shackett (9/24/2009)
   */
   private _str getModifiedFileName(_str append)
   {
      _str fileName = "";
      int prefixPos = pos("://", m_repositoryUrl);
      if (prefixPos > 0) {
         fileName = substr(m_repositoryUrl, prefixPos + 3);
      }
      fileName = stranslate(fileName, "_", "/");
      fileName = stranslate(fileName, "_", " ");
      fileName = stranslate(fileName, "", ":");
      return m_rootFolder:+fileName:+append;
   }

   /**
    * Initializes the version cache for the specific repository.  The cache 
    * database version is checked against CACHE_DB_VERSION, and if they don't 
    * match, the user will be prompted to see if they want to rebuild the 
    * cache. 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param repositoryUrl : the URL of the repository that this version cache 
    *                      manages.
    * @param cacheFileName : The file name of the version cache for this 
    *                      repository.
    * @param isReRun : set to true if this is being called recursively.  This 
    *                is for the case where the database version is not equal to
    *                the one in the cache file, and it must be rebuilt.
    */
   public boolean init(_str rootFolder, _str repositoryUrl, boolean isReRun=false) 
   {
      int response = -1;
      m_rootFolder = rootFolder;
      // create the directory if it doesn't exist
      if (path_exists(m_rootFolder) == false) {
         int success = make_path(m_rootFolder);
         if (success != 0) {
            _message_box('Unable to create path 'm_rootFolder);
            return false;
         }
      }
      m_repositoryUrl = repositoryUrl;
      m_cacheFileName = getModifiedFileName(".dbs");
      m_tempLogFileName = getModifiedFileName("_log.xml");
      m_statusFileName = getModifiedFileName("_status.txt");

      // open the database
      int status = 0;
      if ((m_cacheFileName != null) && (m_cacheFileName != "")) {
         status = vsOpenVCDatabase(repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
         if (status == 0) {
            m_isInitialized = true;
         } else {
            if (status == -1) {
               message('Error creating the cache file 'm_cacheFileName);
            } else if (status == -2) {
               // if this is not a rerun, try to fix the problem
               if (isReRun == false) {
                  _message_box('The cache file for 'm_repositoryUrl' is an older format and must be rebuilt.', 'SlickEdit', MB_OK);
                  delete_file(m_cacheFileName);
                  return init(m_rootFolder, repositoryUrl, true);
               }
            } else if (status == -3) {
               // if this is not a rerun, try to fix the problem
               if (isReRun == false) {
                  response = _message_box(m_repositoryUrl' does not match the SVN URL in the existing cache file.  Would you like to fix it?', 'SlickEdit', MB_YESNO);
                  // if so, then re-run initialization
                  if (response == IDYES) {
                     delete_file(m_cacheFileName);
                     return init(m_rootFolder, repositoryUrl, true);
                  }
               }
            } else if (status == -4) {
               message('Failure getting repository info for the cache file 'm_cacheFileName);
            } else if (status == -5) {
               message('Failure getting the table handles for the cache file 'm_cacheFileName);
            } else if (status == -6) {
               message('Failure setting the repository info for the cache file 'm_cacheFileName);
            }
         }
      }
      // make sure we close the database now!
      vsCloseVCDatabase(repositoryUrl);

      return (status == 0);
   }
   
   private boolean checkInitialization()
   {
      // if we are already initialized, then just return true
      if (m_isInitialized == false) {
         // we are not initialized, so try to re-initialize
         init(m_rootFolder, m_repositoryUrl, false);
      }
      return m_isInitialized;
   }

   /**
    * Fixes the case where something catastrophic happened and the version cache 
    * is in a bad state and needs to be rebuilt. 
    */
   public boolean repairCacheFile()
   {
      delete_file(m_cacheFileName);
      delete_file(m_tempLogFileName);
      return init(m_rootFolder, m_repositoryUrl, false);
   }

   /**
    * Takes a file reference from an SVN log file and determines which branch it 
    * belongs to.  The file spec (the file name withouth the branch prefix) is 
    * returned and the ID of its branch is also returned through two reference 
    * parameters. 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param fileName : the name of the file retrieved in the SVN log.
    * @param branchID : the ID of the branch that this particular file belongs 
    *                 to.
    * @param fileSpec : the name of the file without the branch prefix
    */
   private void getBranchIDForFile(_str fileName, int& branchID, _str& fileSpec)
   {
      int i = 0;
      _str fileParts[];
      _str branchRoot = "";
      int status = 0;
   
      // initialize the return vars
      branchID = -1;
      fileSpec = fileName;
   
      // split the file name into its parts
      split(fileName, "/", fileParts);
      if (fileParts._length() < 3)
         return;
   
      // get the first part of the path
      branchRoot = "/"fileParts[1];
      if (branchRoot != "/trunk") {
         // if this isn't the trunk, then get the second part of the path
         branchRoot = branchRoot :+ "/" :+ fileParts[2];
      }
      fileSpec = substr(fileName, branchRoot._length()+1);
      // see if it's in the database already
      VCBranch branch();
      status = vsGetBranchByName(m_repositoryUrl, branchRoot, branch);
      if (status == 0)
         branchID = branch.get_BranchID();
   } 

   /**
    * Returns whether or not the cache requires an asyncronous update or not. 
    * This is determined by subtracting the current timestamp from the timestamp 
    * when the cache was last updated, and if the day difference is > the value 
    * of def_vccache_synchro_update_limit, the it needs an async update. 
    * 
    * @return boolean : true if async update is required, false if not
    */
   public boolean requiresAsyncUpdate()
   {
      boolean retVal = false;
      _str lastUpdateTimestamp = "";
      getLastUpdateTimestamp(lastUpdateTimestamp);
      if ( lastUpdateTimestamp!="" ) {
         // Get DateTime instance for time stamp
         _str timeStamp = DateTime.fromTimeF(lastUpdateTimestamp);
         // Get DateTime instance for now
         DateTime dateNow;
         // Get DateTime instance for <def_vccache_synchro_update_limit> days ago
         dateLimit := dateNow.add(-def_vccache_synchro_update_limit,se.datetime.DT_DAY);
         // Get DateTimeInterval from def_vccache_synchro_update_limit days ago 
         // until dateNow
         DateTimeInterval interval = DateTimeInterval.fromString("name",dateLimit.toString()'/'dateNow.toString()); 
         filterResult := interval.filter(timeStamp);
         if ( !filterResult ) {
            // If timeStamp is in the range, do an asynchronous update
            retVal = true;
         }
      }else{
         // Probably file not present, perform update asynchronous
         retVal = true;
      }
      return retVal;
   }

   /**
    * Updated the version cache be getting the latest changes since the last 
    * time this function was called.
    * 
    * @author shackett (9/11/2009)
    * 
    * @return int 
    */
   public int updateVersionCache(boolean asyncUpdate)
   {
      if ( m_processID!=-1 ) return PROCESS_ALREADY_RUNNING_RC;

      // shell the vccacheupdtr executable
      _str exePath = get_env("VSLICKBIN1"):+VCCACHEUPDATER_EXE;
      if (file_exists(exePath) == false) {
         _message_box(nls("Unable to find %s.",VCCACHEUPDATER_EXE));
         return -1;
      }
      // build the command
      _str command = exePath:+' ':+_SVNGetExeAndOptions()' ':+maybe_quote_filename(m_repositoryUrl):+' ':+maybe_quote_filename(m_cacheFileName):+' ':+maybe_quote_filename(m_tempLogFileName):+' ':+CACHE_DB_VERSION;
      _str shellOptions = "PQ";
      if (def_vccache_debug) {
         command :+= ' 1';
         shellOptions = "P";
      } else {
         command :+= ' 0';
      }
      // do not run database
//      command :+= ' 1';
      // now run it and wait
      int pid = 0;
      int status = 0;

      if ( asyncUpdate ) {
         shellOptions :+= "A";
         if (def_vccache_debug) {
            say('updateVersionCache shelling command='command);
         }
         status = shell(command,shellOptions,"",pid);
         m_processID = pid;
      }else{
         status = shell(command,shellOptions);
         pid = -1;
      }

      switch (status) {
      case SVN_CACHE_SUCCESS:
         maybeLogDebugMessage('Completed SVN cache update');
         break;
      case SVN_SHELL_ERROR:
         _message_box('SVN was unable to complete successfully.');
         break;
      case SVN_INCAPABLE_ERROR:
         _message_box('The installed version of SVN is unable to complete successfully.');
         break;
      case SVN_LOG_PARSE_ERROR:
         _message_box('An error occurred while parsing the SVN log file.');
         break;
      }

      return status;
   }

   boolean vcProcessRunning() {
      rv := _IsProcessRunning(m_processID)!=0;
      return rv;
   }

   int getProcessPID() {
      return m_processID;
   }

   /**
    * Returns the last timestamp that the database was updated (in _time('f') 
    * format. If the cache has not yet been updated, then "" will be returned.
    * 
    * @author shackett (9/11/2009)
    */
   public int getLastUpdateTimestamp(_str &lastUpdateTimestamp)
   {
      // make sure the database is initialized
      if (checkInitialization() == false) {
         _message_box('The version cache for repository 'm_repositoryUrl' is not initialized.');
         return -1;
      }
      // open the database
      int status = vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box('Unable to access version cache "'m_cacheFileName'".');
         return -2;
      }
      // get the last update timestamp
      int retVal = vsGetLastUpdateTimestamp(m_repositoryUrl, lastUpdateTimestamp);
      // close the cache database
      vsCloseVCDatabase(m_repositoryUrl);
      return status;
   }

   /**
    * Mostly added for testing
    * 
    * @param newLastUpdateTimestamp  Timestamp to set
    * 
    * @return int 0 if succesful
    */
   public int setLastUpdateTimestamp(_str newLastUpdateTimestamp)
   {
      // make sure the database is initialized
      if (checkInitialization() == false) {
         _message_box('The version cache for repository 'm_repositoryUrl' is not initialized.');
         return -1;
      }
      // open the database
      int status = vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box('Unable to access version cache "'m_cacheFileName'".');
         return -2;
      }
      // get the last update timestamp
      int retVal = vsSetLastUpdateTimestamp(m_repositoryUrl, newLastUpdateTimestamp);
      // close the cache database
      vsCloseVCDatabase(m_repositoryUrl);
      return status;
   }

   /**
    * Returns all of the files that participated in a revision.
    * 
    * @author shackett (9/11/2009)
    * 
    * @param revisionID : the ID of the revision to get participating files for
    */
   public int getFilesForRevision(int revisionID, VCFile (&files)[])
   {
      // make sure the database is initialized
      if (checkInitialization() == false) {
         _message_box('The version cache for repository 'm_repositoryUrl' is not initialized.');
         return -1;
      }
      // open the database
      int status = vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box('Unable to access version cache "'m_cacheFileName'".');
         return -2;
      }
      // get the file set
      status = vsGetFilesForRevision(m_repositoryUrl, revisionID, files);
      // close the version cache
      vsCloseVCDatabase(m_repositoryUrl);
      return status;
   }

   /**
    * Returns a hastable of file collections that participated in each revision 
    * in the passed collection.  The retrned hashtable is keyed by the revision 
    * number. 
    * 
    * @author shackett (11/3/2009)
    * 
    * @param revisionIDs : a collection of revision IDs
    */
   public int getFilesForRevisionSet(int revisionIDs[], VCFile (&files):[][])
   {
      // make sure the database is initialized
      if (checkInitialization() == false) {
         _message_box('The version cache for repository 'm_repositoryUrl' is not initialized.');
         return -1;
      }
      // open the database
      int status = vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box('Unable to access version cache "'m_cacheFileName'".');
         return -2;
      }
      // get the files for each revision
      int i = 0;
      for (i = 0; i < revisionIDs._length(); i++) {
         int revisionID = revisionIDs[i];
         VCFile tempFiles[];
         vsGetFilesForRevision(m_repositoryUrl, revisionID, tempFiles);
         if (status == 0) {
            files:[revisionID] = tempFiles;
         }
      }
      // close the version cache
      vsCloseVCDatabase(m_repositoryUrl);
      return status;
   }

   /**
    * Returns the revision history given a file name.
    * 
    * @author shackett (9/11/2009)
    * 
    * @param fileName : the file that we want version history for
    */
   public int getRevisions(_str fileName, VCBranch& rootBranch, VCLabel (&labels)[], boolean getAllBranches=true, boolean getLabels=true)
   {
      int i, j, k = 0;
      int branchID = 0;
      VCBranch branch;
      VCLabel label;
      int parentbranchID = 0;
      int earliestRevisionNumber = 0;

      // make sure the database is initialized
      if (checkInitialization() == false) {
         _message_box('The version cache for repository 'm_repositoryUrl' is not initialized.');
         return -1;
      }
      // open the database
      int status = vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box('Unable to access version cache "'m_cacheFileName'".');
         return -2;
      }

      // determine the url for this file in SVN
      _str url = "";
      status = _SVNGetFileURL(fileName, url);
      if (status) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box(fileName' is not a under SVN source control.');
         return -3;
      }

      // make sure that the file is from this repository
      _str fileSpec = "";
      int curBranchID = -1;
      if (lowcase(substr(url, 1, m_repositoryUrl._length())) != lowcase(m_repositoryUrl)) {
         vsCloseVCDatabase(m_repositoryUrl);
         _message_box(fileName' is not in the 'm_repositoryUrl' repository.');
         return -4;
      } else {
         // trim the respository name to make the file spec
         _str trimmedUrl = substr(url, m_repositoryUrl._length() + 1);
         getBranchIDForFile(trimmedUrl, curBranchID, fileSpec);
      }

      // get the file object
      VCFile file;
      status = vsGetFileBySpec(m_repositoryUrl, fileSpec, file);
      if (status != 0) {
         vsCloseVCDatabase(m_repositoryUrl);
         maybeLogDebugMessage("I can't find information for "fileSpec);
         return -5;
      }
   
      // initializer the revisions and branches collections
      VCRevision revisions[];
      revisions._makeempty();
      VCBranch branches:[];
      branches._makeempty();
      labels._makeempty();

      // get the trunk branch
      VCBranch tempBranch;
      vsGetBranchByName(m_repositoryUrl, "/trunk", tempBranch);
      int trunkBranchID = tempBranch.get_BranchID();
      // add it to the branch hashtable
      branches:[trunkBranchID] = tempBranch;
      VCBranch* trunkBranch = branches._indexin(trunkBranchID);

      // get the branch exclusions for this file
      VCExclusion branchExclusions[];
      vsGetBranchExclusionsForFile(m_repositoryUrl, file.get_FileSpec(), branchExclusions);

      // convert that to a hashtable
      VCExclusion branchExclusionHash:[];
      branchExclusionHash._makeempty();
      for (i = 0; i < branchExclusions._length(); i++) {
         VCExclusion curExclusion = branchExclusions[i];
         branchExclusionHash:[curExclusion.get_ItemID()] = curExclusion;
      }

      // get all of the revisions for the file
      status = vsGetRevisionsForFile(m_repositoryUrl, file.get_FileID(), revisions);
      if (status == 0) {
         // sort the revision list
         revisions._sort();
         // get the earliest revision in the list
         if ( revisions._length() ) {
            earliestRevisionNumber = (int)revisions[0].get_Number();
         }
         // now load all of the branches that come after the first revision
         branchID = trunkBranchID + 1;
         status = 0;
         while (status == 0) {
            // don't fetch a branch that's on the branch exclusion list
            if (!(branchExclusionHash._indexin(branchID))) {
               status = vsGetBranchByID(m_repositoryUrl, branchID, tempBranch);
               // make sure that a) we got a valid branch and b) the branch comes after the earliest revision 
               if ((status == 0) && 
                   ((int)tempBranch.get_HistoryInsertionNumber() >= earliestRevisionNumber)) {
                     branches:[branchID] = tempBranch;
               }
            }
            branchID++;
         }
         // now traverse the list of revisions
         for (i = 0; i < revisions._length(); i++) {
            VCRevision revision = revisions[i];
            // get its parent branch and include this revision in its revision list
            int parentBranchID = revision.get_ParentBranchID();
            VCBranch* parentBranch = branches._indexin(parentBranchID);
            // now add the revision to the parent branch
            if (parentBranch) {
               parentBranch->addChildItem(revision);
            }
         }
      } else {
         maybeLogDebugMessage("I can't find any revisions for file "file.get_FileSpec());
      }
   
      // we now have a hashtable of branches that all contain their proper revisions.  Now we 
      // need to build the branch hierarchy
      foreach (branchID => branch in branches) {
         // find the parent branch
         parentbranchID = branch.get_ParentBranchID();
         // determine if we have already placed this branch in the hierarchy
         VCBranch* parentbranch = branches._indexin(parentbranchID);
         // if not, then search for the branch
         if (!parentbranch) {
            parentbranch = findBranch(parentbranchID, trunkBranch);
         }
         // if we still have nothing, then the branch should just not to be included
         if (parentbranch) {
            // add the current branch to the parent branch's child list (it will be inserted in the
            // correct historical location in the list automatically)
            parentbranch->addChildItem(branch);
         }
      }
      // now sort the branch hierarchy
      sortBranches(trunkBranch);

      // now get all of the labels that come after the earliest revision
      if (getLabels == true) {
         labels._makeempty();
         status = 0;
         int labelID = 0;
         // get the label exclusions for this file
         VCExclusion labelExclusions[];
         vsGetLabelExclusionsForFile(m_repositoryUrl, file.get_FileSpec(), labelExclusions);
         // convert that to a hashtable
         VCExclusion labelExclusionHash:[];
         labelExclusionHash._makeempty();
         for (i = 0; i < labelExclusions._length(); i++) {
            VCExclusion curExclusion = labelExclusions[i];
            labelExclusionHash:[curExclusion.get_ItemID()] = curExclusion;
         }
         // now figure out which labels are included
         while (status == 0) {
            VCLabel tempLabel;
            // don't fetch a label that's on the label exclusion list
            if (!(labelExclusionHash._indexin(labelID))) {
               status = vsGetLabelByID(m_repositoryUrl, labelID, tempLabel);
               // make sure that a) we got a valid label and b) the label comes after the earliest revision 
               if ((status == 0) && ((int)tempLabel.get_HistoryInsertionNumber() >= earliestRevisionNumber)) {
                  // add it to the collection
                  labels[labels._length()] = tempLabel;
               }
            }
            labelID++;
         }
         // now sort them by "copy from" number and revision number
         labels._sort();
      }
      // return the trunk branch
      rootBranch = *trunkBranch;
      // close the cache
      vsCloseVCDatabase(m_repositoryUrl);

      return 0;
   }

   /**
    * Finds a branch with a given barnch ID in a branch hierarchy rooted by 
    * rootBranch. 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param branchID : the ID of the branch we are looking for.
    * @param rootBranch : the root of the branch hierarchy to look through.
    * 
    * @return VCBranch* : the branch if found, null if not found
    */
   private VCBranch* findBranch(int branchID, VCBranch* rootBranch)
   {
      // if the branch equals the branch number, then return it
      if (rootBranch->get_BranchID() == branchID) {
         return rootBranch;
      } else {
         // iterate over the child items
         int numChildren = rootBranch->getChildItemCount();
         for (i := 0; i < numChildren; i++) {
            VCBaseRevisionItem* childItem = rootBranch->getChildItem(i);
            // if the child item is a branch, then recurse over it
            if (*childItem instanceof VCBranch) {
               VCBranch* childBranch = (VCBranch*)childItem;
               VCBranch* retVal = findBranch(branchID, childBranch);
               if (retVal)
                  return retVal;
            }
         }
      }
      return null;
   }
   
   /**
    * Recursively walks through the branch hierarchy and sorts the 
    * branch children. 
    */
   private void sortBranches(VCBranch* rootBranch)
   {
      // sort the branch
      rootBranch->sortChildren();
      // iterate over the child items
      int numChildren = rootBranch->getChildItemCount();
      for (i := 0; i < numChildren; i++) {
         VCBaseRevisionItem* childItem = rootBranch->getChildItem(i);
         // if the child item is a branch, then recurse over it
         if (*childItem instanceof VCBranch) {
            VCBranch* childBranch = (VCBranch*)childItem;
            sortBranches(childBranch);
         }
      }
   }

   /**
    * Prints a revision hierarchy to the vsapi console window.
    * 
    * @author shackett (9/11/2009)
    * 
    * @param item 
    * @param padding 
    */
   public void printRevisionTreeItem(VCBaseRevisionItem item, _str padding)
   {
      int i = 0;
   
      if (item instanceof VCBranch) {
         // if this is a branch item, then print the details for it and recurse the children   
         VCBranch branch = (VCBranch)item;
         say(padding"B- "branch.get_BranchID()", "branch.get_Number()", "branch.get_Name()", "branch.get_Author()", "branch.get_Timestamp()"): "branch.get_Comments());
         int numChildren = branch.getChildItemCount();
         for (i = 0; i < numChildren; i++) {
            printRevisionTreeItem(*branch.getChildItem(i), padding:+"  ");
         }
      } else if (item instanceof VCRevision) {
         // if this is a revision item, then print the details for it
         VCRevision revision = (VCRevision)item;
         say(padding"R- "revision.get_RevisionID()", "revision.get_Number()", "revision.get_Author()", "revision.get_Timestamp()"): "revision.get_Comments());
      } else if (item instanceof VCLabel) {
         // if this is a label item, then print the details for it
         VCLabel label = (VCLabel)item;
         say(padding"L- "label.get_LabelID()", "label.get_Number()", "label.get_Name()", "label.get_Author()", "label.get_Timestamp()"): "label.get_Comments());
      }
   }
   
   /**
    * Dumps the database contents to the vsapi console window.  This function 
    * uses a dump technique in the C code. 
    * 
    * @author shackett (9/11/2009)
    * 
    * @param flags : bitwise and these value to determine which tables to print:
    * 1 = FILES table
    * 2 = FILE_REVISION_XREF table
    * 4 = REVISIONS table
    * 8 = BRANCHES table
    * 16 = REVISION_BRANCH_XREF table
    * 32 = LABELS table
    * 64 = REVISION_LABEL_XREF table
    */
   public void dumpDatabaseContents(int flags)
   {
      vsOpenVCDatabase(m_repositoryUrl, m_cacheFileName, CACHE_DB_VERSION);
      vsDebugPrintTables(m_repositoryUrl, flags);
      vsCloseVCDatabase(m_repositoryUrl);
   }
   
   private void maybeLogDebugMessage(_str msg, boolean includeTimestamp=false)
   {
      if (def_vccache_debug) {
         if (includeTimestamp == true)
            msg = _time('F'):+' : ':+msg;
         say(msg);
      }
   }

   public boolean isSvnCapable()
   {
      _str shellCmd = _SVNGetExeAndOptions()' log --xml -v -rHEAD ':+maybe_quote_filename(m_repositoryUrl):+' > ':+maybe_quote_filename(m_tempLogFileName);
      if (def_vccache_debug == 1) {
         say('Running 'shellCmd);
      }
      int retVal = shell(shellCmd, 'Q');
      if (retVal != 0) {
         if (def_vccache_debug == 1) {
            say('Error running SVN: 'retVal);
         }
         return false;
      }
      // now parse it for the log entry node
      int status;
      int configHandle = _xmlcfg_open(m_tempLogFileName, status);
      if (status != 0) {
         if (def_vccache_debug == 1) {
            say('Error opening extended SVN version history: 'status);
         }
         return false;
      }
      _str logEntryNodes[];
      int i, j;
      _xmlcfg_find_simple_array(configHandle, "//logentry", logEntryNodes);
      if (logEntryNodes._length() == 0) {
         if (def_vccache_debug == 1) {
            say('Error parsing extended SVN version history: 'retVal);
         }
         _xmlcfg_close(configHandle);
         return false;
      } else {
          _str pathNodes[];
          _xmlcfg_find_simple_array(configHandle, "//paths/path", pathNodes);
          if (pathNodes._length() == 0) {
              if (def_vccache_debug == 1) {
                 say('No path items found in SVN version history: 'retVal);
              }
              _xmlcfg_close(configHandle);
              return false;
          }
          _str pathKind = _xmlcfg_get_attribute(configHandle, (int)pathNodes[0], 'kind', '');
          if (pathKind == '') {
              if (def_vccache_debug == 1) {
                 say("Path items don't include the required 'kind' attribute.");
              }
              _xmlcfg_close(configHandle);
              return false;
          }
      }
      _str revNum = _xmlcfg_get_attribute(configHandle, (int)logEntryNodes[0], 'revision', '');
      if (def_vccache_debug == 1) {
         say('Current SVN revision = 'revNum);
      }

      // close the XML DOM
      _xmlcfg_close(configHandle);
      // if we got here, then return true
      return true;
   }

   public void parseStatusFile(int &status, _str &msg)
   {
      status = SVN_CACHE_SUCCESS;
      msg = '';
      // if the status file doesn't exist, just assume success
      if (file_exists(m_statusFileName) == false) {
         return;
      }
      _str contents, statusVal, msgVal, completedVal, totalVal;
      int success = _GetFileContents(m_statusFileName, contents);
      // parse the contents
      parse contents with statusVal (';') msgVal (';') completedVal (';') totalVal;
      // get the status
      if (isinteger(statusVal) == true) {
         status = (int)statusVal;
      }
      // get the message
      msg = msgVal;
   }

};
