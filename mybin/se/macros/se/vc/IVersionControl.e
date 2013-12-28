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
#include "svc.sh"
#require "se/datetime/DateTime.e"
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
   * @param version Version of file to compare. This is version 
   *                specific information
   * @param options Options to pass to diff
   * 
   * @return int 
   */
   int diffLocalFile(_str localFilename,_str version="",int options=0);

   /** 
   * Get the URL or remote filename for <B>localFilename</B> 
   * 
   * @param localFilename File to get URL for
   * @param URL Set to URL or remote filename
   * 
   * @return int 0 if successful
   */
   int getLocalFileURL(_str localFilename,_str &URL);
   int getLocalFileBranch(_str localFilename,_str &URL);
   int getHistoryInformation(_str localFilename,SVCHistoryInfo (&historyInfo)[],int options=0);
   int getRepositoryInformation(_str URL,SVCHistoryInfo (&historyInfo)[],se.datetime.DateTime dateBack,int options=0);
   int getCurRevision(_str localFilename,_str &curRevision,_str &URL="",boolean quiet=false);
   int getCurLocalRevision(_str localFilename,_str &curRevision,boolean quiet=false);
   void getVersionNumberFromVersionCaption(_str versionCaption,_str &versionNumber);
   int getFile(_str localFilename,_str version,int &fileWID);
   int getRemoteFilename(_str localFilename,_str &remoteFilename);
   int getFileStatus(_str localFilename,SVCFileStatus &fileStatus,int options=0);

   int getMultiFileStatus(_str localPath,SVC_UPDATE_INFO (&filestatus)[],SVC_UPDATE_TYPE updateType=SVC_UPDATE_PATH,boolean recursive=true,int options=0,_str &remoteURL="");

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

   int checkout(_str URLPath,_str localPath,int options=0);

   SVCCommandsAvailable commandsAvailable();
   _str getCaptionForCommand(SVCCommands command,boolean withHotkey=true,boolean mixedCaseCaption=true);

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
   int getComment(_str &commentFilename,_str &tag,_str fileBeingCheckedIn,boolean showApplyToAll=true,
                  boolean &applyToAll=false,boolean showTag=true,boolean showAuthor=false,_str &author='');

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
   _str getFixedUpdatePath(boolean forceCalculation=false);

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
    * @return boolean true if <B>hotkeyLetter</B> is used as a 
    *         hotkey
    */
   boolean hotkeyUsed(_str hotkeyLetter,boolean onMenu=true);

   void getUpdatePathList(_str (&projPaths)[],_str workspacePath,_str (&pathsToUpdate)[]);

   int pushToRepository(_str path="",int options=0);
   int pullFromRepository(_str path="",int options=0);
   _str localRootPath();

   /**
    * @param localFilename Name of file in version control
    * 
    * @return int Number of versions of <B>localFilename</B> in 
    *         repository
    */
   int getNumVersions(_str localFilename);

   int enumerateVersions(_str localFilename,STRARRAY &versions,boolean quiet=false);
};
