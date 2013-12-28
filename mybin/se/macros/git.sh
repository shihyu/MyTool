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
#ifndef GIT_SH
#define GIT_SH

struct GIT_VERSION_INFO {
   _str ParentRevisionNumber;
   _str RevisionNumber;
   _str Subject;
   _str Body;
   _str Date;
   _str Author;
   _str Committer;
};

enum GIT_STATE {
   GIT_UNCHANGED,
   GIT_NEW,
   GIT_MODIFIED,
   GIT_DELETED
};

struct GIT_FILE_STATUS {
   _str filename;
   GIT_STATE state;
};

struct GIT_LOG_INFO {
   _str WorkingFile;
   _str Head;
   _str CurBranch;
   _str LocalVersion;
   GIT_STATE State;
   GIT_VERSION_INFO VersionList[];
};

struct GIT_COMMIT_CALLBACK_INFO {
   boolean comment_is_filename;
   _str comment;
   _str commit_options;
};

#if __UNIX__
   #define GIT_EXE_NAME 'git'
#else
   #define GIT_EXE_NAME 'git.exe'
#endif

struct GIT_SETUP_INFO {
   _str git_exe_name;
};


/**
 * CVS options including the path to the executable, checkin login id,
 * and hash table of command options.
 * 
 * @default null
 * @categories Configuration_Variables
 */
GIT_SETUP_INFO def_git_info;

// Real limit seems to be 8191.  Set our limit a bit shorter
#define MAX_COMMAND_LINE_LENGTH  8000

#define GIT_CHILD_DIR_NAME      '.git'
#define GIT_CYGWIN_PREFIX       '/cygdrive/'

#define GIT_DEBUG_SHOW_MESSAGES       0x1
#define GIT_DEBUG_DO_NOT_RUN_COMMANDS 0x2

#define UPDATE_CAPTION_UPDATE '&Update'
#define UPDATE_CAPTION_COMMIT '&Commit'
#define UPDATE_CAPTION_ADD 'Add'
#define UPDATE_CAPTION_MERGE '&Merge'

#endif
