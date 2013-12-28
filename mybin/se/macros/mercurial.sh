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
#ifndef HG_SH
#define HG_SH

struct HG_VERSION_INFO {
   _str ParentRevisionNumber;
   _str RevisionNumber;
   _str Subject;
   _str Body;
   _str Date;
   _str Author;
   _str Committer;
   _str Tag;
   _str Node;
   _str ParentRevisions[];
};

enum HG_FILE_STATE {
   HG_STATUS_UNCHANGED,
   HG_STATUS_MODIFIED,
   HG_STATUS_NEW,
   HG_STATUS_DELETED,
   HG_STATUS_CLEAN,
   HG_STATUS_MISSING,
   HG_STATUS_NOT_CONTROLED,
   HG_STATUS_IGNORED
};


struct HG_STATUS_INFO {
   _str local_filename;
   HG_FILE_STATE file_state;
   _str working_revision;
};

struct HG_FILE_STATUS {
   _str filename;
   HG_FILE_STATE state;
};

struct HG_LOG_INFO {
   _str WorkingFile;
   _str Head;
   _str CurBranch;
   _str LocalVersion;
   HG_FILE_STATE State;
   HG_VERSION_INFO VersionList[];
};

struct HG_COMMIT_CALLBACK_INFO {
   boolean comment_is_filename;
   _str comment;
   _str commit_options;
};

#if __UNIX__
   #define HG_EXE_NAME 'hg'
#else
   #define HG_EXE_NAME 'hg.exe'
#endif

struct HG_SETUP_INFO {
   _str hg_exe_name;
};


/**
 * CVS options including the path to the executable, checkin login id,
 * and hash table of command options.
 * 
 * @default null
 * @categories Configuration_Variables
 */
HG_SETUP_INFO def_hg_info;

// Real limit seems to be 8191.  Set our limit a bit shorter
#define MAX_COMMAND_LINE_LENGTH  8000

#define HG_CHILD_DIR_NAME      '.hg'
#define HG_CYGWIN_PREFIX       '/cygdrive/'

#define HG_DEBUG_SHOW_MESSAGES       0x1
#define HG_DEBUG_DO_NOT_RUN_COMMANDS 0x2

#define UPDATE_CAPTION_UPDATE '&Update'
#define UPDATE_CAPTION_COMMIT '&Commit'
#define UPDATE_CAPTION_ADD 'Add'
#define UPDATE_CAPTION_MERGE '&Merge'

#endif
