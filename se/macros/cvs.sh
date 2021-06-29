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
#pragma option(metadata,"cvs.e")

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
   bool comment_is_filename;
   _str comment;
   _str commit_options;
};

/* 
   Don't use this struct any more. 
   It is only use for converting
   old CVS data.
*/
struct CVS_INFO {
   _str cvs_exe_name;
   bool check_login;
   _str cvs_hack_dir;
   _str CommandOptionTable:[]:[];
};

// CVS executable name
_str def_cvs_exe_path;
_str _cvs_cached_exe_path;
struct CVS_OTHER_INFO {
   bool check_login;
   _str cvs_hack_dir;
   _str CommandOptionTable:[]:[];
};


const CVS_CHILD_DIR_NAME=      'CVS';
const CVS_ROOT_FILENAME=       'Root';
const CVS_ENTRIES_FILENAME=    'Entries';
const CVS_REPOSITORY_FILENAME= 'Repository';
const CVS_PASS_FILENAME=       '.cvspass';

extern _str _CVSBuildCommitCommand(CVS_COMMIT_CALLBACK_INFO *pinfo,_str output_filename,bool append_to_output);
extern int _CVSCommit(_str filelist[],_str comment,_str &OutputFilename='',
               bool comment_is_filename=false,_str commit_options='',
               bool append_to_output=false,CVS_LOG_INFO (*pFiles)[]=null,
               _str taglist='');
extern void _CVSShowStallForm(_str *pDialogCaption=null);
extern void _CVSKillStallForm();

const CVS_DEBUG_SHOW_MESSAGES=       0x1;
const CVS_DEBUG_DO_NOT_RUN_COMMANDS= 0x2;

struct CVS_COMMIT_SET {
   _str Files[];
   _str CommentAll[];
   _str CommentFiles:[][];
   _str Tag;
   _str TimesCommittedList[];
   bool autoPopulate;
};
//int _CVSPipeProcess(_str command,_str FileOrPath,_str shell_options,
//                    _str &StdOutData,_str &StdErrData,
//                    bool debug=false,
//                    typeless *pfnPreShellCallback=0,typeless *pfnPostShellCallback=0,
//                    typeless *pData=0,int &pid=-1,bool NoHourglass=false,
//                    bool checkCVSDashD=true);


extern bool _SVCRawDataAnyRunning();

/** 
 * This struct contains the information describing
 * what expressions to search for in version labels and
 * consider as defect ID's
 */ 
struct VC_DEFECT_LABEL_REGEX { _str re; _str url; };
