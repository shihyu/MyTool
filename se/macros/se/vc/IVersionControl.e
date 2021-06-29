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
#include "svc.sh"
#require "se/datetime/DateTime.e"
#require "sc/lang/String.e"
#endregion Imports


/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

interface IVersionControl {
   /**
   * Diff file <B>localFilename</B> with tip of it's branch in 
   * version control 
   * @param localFilename File to compare
   * @param version Version of file to compare. 
   *                This is version specific information.
   *                "BASE" refers to the BASE file version, and can be
   *                treated the same as "" if the system does not support -rBASE. 
   * @param options Options to pass to diff
   * 
   * @return int 
   */
   int diffLocalFile(_str localFilename,_str version="",int options=0,bool modal=false);

   /** 
   * Get the URL or remote filename for <B>localFilename</B> 
   * 
   * @param localFilename File to get URL for
   * @param URL Set to URL or remote filename
   * 
   * @return int 0 if successful
   */
   int getLocalFileURL(_str localFilename,_str &URL);
   int getLocalFileBranch(_str localFilename,_str &branchName);
   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0,_str branchName="");
   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0);

   int getRepositoryRoot(_str URL,_str &URLRoot="");
   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",bool quiet=false);
   int getCurLocalRevision(_str localFilename,_str &curRevision,bool quiet=false);

   void getVersionNumberFromVersionCaption(_str versionCaption,_str &versionNumber);
   _str getBaseRevisionSpecialName();
   _str getHeadRevisionSpecialName();
   _str getPrevRevisionSpecialName();
   int getFile(_str localFilename,_str version,int &fileWID,bool getIndexVersion=false);
   int getRemoteFilename(_str localFilename,_str &remoteFilename);
   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0,bool checkForUpdates=true);

   int getMultiFileStatus(_str localPath,SVC_UPDATE_INFO (&filestatus)[],SVC_UPDATE_TYPE updateType=SVC_UPDATE_PATH,bool recursive=true,int options=0,_str &remoteURL="");

   int updateFile(_str localFilename,int options=0);
   int updateFiles(_str (&localFilenames)[],int options=0);

   int editFile(_str localFilename,int options=0);
   int editFiles(_str (&localFilenames)[],int options=0);

   int revertFile(_str localFilename,int options=0);
   int revertFiles(_str (&localFilename)[],int options=0);

   int commitFile(_str localFilename,_str comment=null,int options=0);
   int commitFiles(_str (&localFilename)[],_str comment=null,int options=0);

   int addFile(_str localFilename,_str comment=null,int options=0);
   int addFiles(_str (&localFilename)[],_str comment=null,int options=0);

   int removeFile(_str localFilename,_str comment=null,int options=0);
   int removeFiles(_str (&localFilename)[],_str comment=null,int options=0);

   int resolveFile(_str localFilename,_str comment=null,int options=0);
   int resolveFiles(_str (&localFilename)[],_str comment=null,int options=0);

   int mergeFile(_str localFilename,int options=0);

   int getURLChildDirectories(_str URLPath,STRARRAY &urlChildDirectories);

   int checkout(_str URLPath,_str localPath,int options=0,_str revision="");
   int switchBranches(_str branchName,_str localPath,SVCSwitchBranch options=0);

   SVCCommandsAvailable commandsAvailable();
   _str getCaptionForCommand(SVCCommands command,bool withHotkey=true,bool mixedCaseCaption=true);

   /**
    * @param commentFilename Filename that the comment will be 
    *                        written to.  If this value is "", a
    *                        temp filename will be created and
    *                        returned in this variable.
    * @param tag Value of Tag textbox is returned here
    * @param fileBeingCheckedIn Local filename of file being 
    *                           checked in
    * @param showApplyToAll Show the "Apply to all" checkbox
    * @param applyToAll Returned value of "Apply to all" checkbox
    * @param showTag If true, show the "Tag" textbox
    * @param showAuthor If true, show the "Author" textbox
    * @param author Value of Author textbox is returned here
    * 
    * @return int 0 if successful
    */
   int getComment(_str &commentFilename,_str &tag,_str fileBeingCheckedIn,bool showApplyToAll=true,
                  bool &applyToAll=false,bool showTag=true,bool showAuthor=false,_str &author='');

   _str getSystemNameCaption();

   /**
    * Used for system specific information that might need to be 
    * called from places other than svc.e (or from svc.e in very 
    * specific instances where it cannot be avoided). 
    *  
    * If this is not needed for a given system, implement and 
    * return "". 
    * 
    * @param fieldName Name of value to query
    * 
    * @return _str value for <B>fieldName</B>
    */
   _str getSystemSpecificInfo(_str fieldName);
   SVCSystemSpecificFlags getSystemSpecificFlags();

   /**
    * For systems that have a fixed update path (systems that have 
    * a viewspec specified, and the default would be to update that
    * path). 
    *  
    * This will be used on menu actions, so if the path 
    * is currently unknown, implementations should return "" rather
    * than access a filesystem or version control system to get the 
    * path unless <B>forceCalculation</B> is true. 
    *  
    * For implementations where this does not apply, 
    * return "" and not specify 
    * SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_FIXED_PATH in 
    * commandsAvailable(). 
    *  
    * @path forceCalculation force calculation of the path. 
    *  
    * @return _str path to update
    */
   _str getFixedUpdatePath(bool forceCalculation=false);

   /** 
    * Checks to see if a hotkey is already used. 
    *  
    * Implementations should return true if one of the menu 
    * captions for a command uses this letter as a hotkey. This 
    * allows generic code in svc.e to calculate hotkey items for 
    * things like "Compare with" and  "Setup"
    * 
    * @param hotkeyLetter Letter to check
    * 
    * @return bool true if <B>hotkeyLetter</B> is used as a hotkey
    */
   bool hotkeyUsed(_str hotkeyLetter,bool onMenu=true);

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]);

   int pushToRepository(_str path="",_str branch="",_str remote="",int flags=0);
   int pullFromRepository(_str path="",_str branchName="",_str remote="",int options=0);
   int stash(_str path="", SVCStashFlags options=0,STRARRAY &listOfStashes=null);
   int getStashList(STRARRAY &listOfStashes, _str path="", SVCStashFlags options=0);
   _str localRootPath(_str path="");

   /**
    * @param localFilename Name of file in version control
    * 
    * @return int Number of versions of <B>localFilename</B> in 
    *         repository
    */
   int getNumVersions(_str localFilename);

   int enumerateVersions(_str localFilename,STRARRAY &versions,bool quiet=false,_str branchName="");

   void beforeWriteState();
   void afterWriteState();

   _str getFilenameRelativeToBranch(_str localFilename);
   int getPushPullInfo(_str &branchName, _str &pushRepositoryName, _str &pullRepositoryName, _str &path="");
   int getBranchNames(STRARRAY &branches,_str &currentBranch,_str path,bool forPushPullCombo=false,_str pullRepositoryName="",SVCBranchFlags options=0);
   int getBranchForCommit(_str commitVersion,_str &branchForCommit, _str path);
   /**
    * @return bool true if system lists files for empty 
    *         directories.  This is important because for systems
    *         that list the files, we want to remove empty
    *         uncontrolled directories in the GUI.  For systems
    *         that do not list the files in the uncontrolled
    *         directories, we cannot remove the directories.
    */
   bool listsFilesInUncontrolledDirectories();
};
