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
#include "svc.sh"
#require "se/vc/VCRepository.e"
#require "se/vc/VCFile.e"
#require "se/vc/VCRevision.e"
#require "se/vc/VCBranch.e"
#require "se/vc/VCExclusion.e"
#require "se/vc/VCLabel.e"
#endregion Imports


using se.vc.vccache.VCRepository;
using se.vc.vccache.VCFile;
using se.vc.vccache.VCRevision;
using se.vc.vccache.VCBranch;
using se.vc.vccache.VCExclusion;
using se.vc.vccache.VCLabel;

// vccache functions
/**
 * Opens the specified database and makes sure that the repository URL and 
 * database version match 
 * 
 * @return int : 0 for success
 *				 -1 : Could not create new database
 *				 -2 : Existing database version is old
 *				 -3 : Repository url does not match
 *				 -4 : Failure getting repository info for the database
 *				 -5 : Failure getting the table handles
 *				 -6 : Failure setting the repository info
 *				 other : see return codes for btSession::openDB()
 */
extern int vsOpenVCDatabase(_str repositoryPath, _str databaseName, int databaseVersion);
extern void vsCloseVCDatabase(_str repositoryPath);
extern int vsDatabaseOK(_str repositoryPath);
extern int vsGetRepositoryInfo(_str repositoryPath, VCRepository repository);
extern int vsGetLastUpdateTimestamp(_str repositoryPath, _str lastUpdateTimestamp);
extern int vsSetLastUpdateTimestamp(_str repositoryPath, _str lastUpdateTimestamp);
extern int vsInsertFile(_str repositoryPath, VCFile file);
extern int vsGetFileByID(_str repositoryPath, int fileID, VCFile file);
extern int vsGetFileBySpec(_str repositoryPath, _str fileSpec, VCFile file);
extern int vsGetFilesForRevision(_str repositoryPath, int revisionID, VCFile (&files)[]);
extern int vsInsertRevision(_str repositoryPath, VCRevision revision);
extern int vsLinkFileToRevision(_str repositoryPath, int fileID, int revisionID, _str revisionNumber);
extern int vsGetRevisionByID(_str repositoryPath, int revisionID, VCRevision revision);
extern int vsGetRevisionsForFile(_str repositoryPath, int fileID, VCRevision (&revisions)[]);
extern int vsInsertBranch(_str repositoryPath, VCBranch branch);
extern int vsUpdateBranchParentID(_str repositoryPath, int branchID, int parentBranchID);
extern int vsLinkBranchToRevision(_str repositoryPath, int revisionID, int branchID, _str branchNumber, _str branchTimestamp);
extern int vsGetBranchByID(_str repositoryPath, int branchID, VCBranch branch);
extern int vsGetBranchByName(_str repositoryPath, _str branchName, VCBranch branch);
extern int vsGetBranchesForRevision(_str repositoryPath, int revisionID, VCBranch (&branches)[]);
extern int vsGetBranchExclusions(_str repositoryPath, int branchID, VCExclusion (&exclusions)[]);
extern int vsGetBranchExclusionsForFile(_str repositoryPath, _str fileSpec, VCExclusion (&exclusions)[]);
extern int vsInsertBranchExclusions(_str repositoryPath, VCExclusion (&exclusions)[]);
extern int vsInsertLabel(_str repositoryPath, VCLabel label);
extern int vsLinkLabelToRevision(_str repositoryPath, int revisionID, int labelID, _str labelNumber, _str labelTimestamp);
extern int vsGetLabelByID(_str repositoryPath, int labelID, VCLabel label);
extern int vsGetLabelByName(_str repositoryPath, _str labelName, VCLabel label);
extern int vsGetLabelsForRevision(_str repositoryPath, int revisionID, VCLabel (&labels)[]);
extern int vsGetLabelExclusions(_str repositoryPath, int labelID, VCExclusion (&exclusions)[]);
extern int vsGetLabelExclusionsForFile(_str repositoryPath, _str fileSpec, VCExclusion (&exclusions)[]);
extern int vsInsertLabelExclusions(_str repositoryPath, VCExclusion (&exclusions)[]);
extern int vsDebugPrintTables(_str repositoryPath, int tableFlags);
extern int vsVCCacheGetHistory(_str  pszLocalFilename,_str  pszDatabaseFilename, SVCHistoryInfo (&hrefVarHistoryInfo)[],_str svnEXEPath) ;
extern int vsGetSVNHistoryForCurrentBranch(_str pszLocalFilename, SVCHistoryInfo (&hrefVarHistoryInfo)[], _str dateBack, _str pszSVNExeName);
