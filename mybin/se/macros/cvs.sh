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
#ifndef CVS_SH
#define CVS_SH

struct CVS_VERSION_INFO {
   _str RevisionNumber;
   _str Comment;
   _str Date;
   _str Author;
   _str Branches[];
   _str Labels[];
};

struct CVS_LOG_INFO {
   _str WorkingFile;
   _str Head;           // In cvs_gui_mfupdate used for remote version
   _str BranchFromLog;  // Don't know what this is used for(in cvs), always seems blank
   _str CurBranch;      // Current branch(from stick tag);
   _str RCSFile;
   CVS_VERSION_INFO VersionList[];
   CVS_VERSION_INFO *pSymbolicNames:[];
   CVS_VERSION_INFO Branches[];
   _str Description;     // In cvs_gui_mfupdate used for the code for cvs update
   _str KeywordType;
   _str Status;
   _str LocalVersion;
};

struct CVS_COMMIT_CALLBACK_INFO {
   boolean comment_is_filename;
   _str comment;
   _str commit_options;
};

struct CVS_INFO {
   _str cvs_exe_name;
   boolean check_login;
   _str cvs_hack_dir;
   _str CommandOptionTable:[]:[];
};

/**
 * CVS options including the path to the executable, checkin login id,
 * and hash table of command options.
 * 
 * @default null
 * @categories Configuration_Variables
 */
CVS_INFO def_cvs_info/*=null*/;

// Real limit seems to be 8191.  Set our limit a bit shorter
#define MAX_COMMAND_LINE_LENGTH  8000

#define CVS_CHILD_DIR_NAME      'CVS'
#define CVS_ROOT_FILENAME       'Root'
#define CVS_ENTRIES_FILENAME    'Entries'
#define CVS_REPOSITORY_FILENAME 'Repository'
#define CVS_PASS_FILENAME       '.cvspass'
#define ConvertedBranchNumber(a) stranslate(a,'.','.0.')

extern _str _CVSBuildCommitCommand(CVS_COMMIT_CALLBACK_INFO *pinfo,_str output_filename,boolean append_to_output);
extern int _CVSCommit(_str filelist[],_str comment,_str &OutputFilename='',
               boolean comment_is_filename=false,_str commit_options='',
               boolean append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               _str taglist='');
extern void _CVSShowStallForm(_str *pDialogCaption=null);
extern void _CVSKillStallForm();

#define CVS_DEBUG_SHOW_MESSAGES       0x1
#define CVS_DEBUG_DO_NOT_RUN_COMMANDS 0x2

#define UPDATE_CAPTION_UPDATE '&Update'
#define UPDATE_CAPTION_COMMIT '&Commit'
#define UPDATE_CAPTION_ADD 'Add'
#define UPDATE_CAPTION_MERGE '&Merge'

struct CVS_COMMIT_SET {
   _str Files[];
   _str CommentAll[];
   _str CommentFiles:[][];
   _str Tag;
   _str TimesCommittedList[];
   boolean autoPopulate;
};
//int _CVSPipeProcess(_str command,_str FileOrPath,_str shell_options,
//                    _str &StdOutData,_str &StdErrData,
//                    boolean debug=false,
//                    typeless *pfnPreShellCallback=0,typeless *pfnPostShellCallback=0,
//                    typeless *pData=0,int &pid=-1,boolean NoHourglass=false,
//                    boolean checkCVSDashD=true);


extern boolean _SVCRawDataAnyRunning();

#endif
