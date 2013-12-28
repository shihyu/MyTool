////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49227 $
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
#ifndef SUBVERSION_SH
#define SUBVERSION_SH


// STATUS FLAGS
// 
// status -u Col 1=='A'
#define SVN_STATUS_SCHEDULED_FOR_ADDITION 0x1
// status -u Col 1=='D'
#define SVN_STATUS_SCHEDULED_FOR_DELETION 0x2
// status -u Col 1=='M'
#define SVN_STATUS_MODIFIED               0x4
// status -u Col 1=='C'
#define SVN_STATUS_CONFLICT               0x8
// status -u Col 1=='X'
#define SVN_STATUS_EXTERNALS_DEFINITION   0x10
// status -u Col 1=='I'
#define SVN_STATUS_IGNORED                0x20
// status -u Col 1=='?'
#define SVN_STATUS_NOT_CONTROLED          0x40
// status -u Col 1=='!'
#define SVN_STATUS_MISSING                0x80
// status -u Col 1=='-'
#define SVN_STATUS_NODE_TYPE_CHANGED      0x100
// status -u Col 2=='M'
#define SVN_STATUS_PROPS_MODIFIED         0x200
// status -u Col 2=='C'
#define SVN_STATUS_PROPS_ICONFLICT        0x400
// status -u Col 3=='L'
#define SVN_STATUS_LOCKED                 0x800
// status -u Col 4=='+'
#define SVN_STATUS_SCHEDULED_WITH_COMMIT  0x1000
// status -u Col 5=='S'
#define SVN_STATUS_SWITCHED               0x2000
// status -u Col 8=='*'
#define SVN_STATUS_NEWER_REVISION_EXISTS  0x4000
#define SVN_STATUS_TREE_ADD_CONFLICT      0x8000
#define SVN_STATUS_TREE_DEL_CONFLICT      0x10000

// FILE STATUS STRUCTURE
struct SVN_STATUS_INFO {
   _str local_filename;
   int status_flags;
   _str working_revision;
};

#if __UNIX__
   #define SVN_EXE_NAME 'svn'
#else
   #define SVN_EXE_NAME 'svn.exe'
#endif


#define SVN_OPTION_FIND_NEXT_AFTER_DIFF 0x1
#define SVN_OPTION_RESTORE_COMMENT      0x2

struct SVN_SETUP_INFO {
   _str svn_exe_name;
};

enum_flags SVN_FLAGS {
   SVN_FLAG_HIDE_EMPTY_BRANCHES    = 0x1,
   SVN_FLAG_SHOW_BRANCHES          = 0x2,
   SVN_FLAG_SHOW_LABELS_IN_HISTORY = 0x4,
   SVN_FLAG_GET_BACKGROUND_FILE_STATUSES = 0x8,
   SVN_FLAG_DO_NOT_PROMPT_FOR_BRANCHES   = 0x10,
   SVN_FLAG_DO_NOT_USE_STOP_ON_COPY      = 0x20,
   SVN_FLAG_DO_NOT_USE_FRAMEWORK         = 0x40
};

struct SVN_BRANCH_INFO {
   _str repositoryRoot;
   _str branchesRoot;
   _str trunkRoot;
   _str date;
   _str branchInfo:[];
   _str branchmap_filename;
};

SVN_SETUP_INFO def_svn_info=null;
int def_svn_flags=0;
int def_svn_show_file_status = 0;

int def_svn_update_interval = 600;     // Frequency to get file status data from
                                       // server in seconds (default is 10 minutes)

/**
 * Struct of info from "svn ls".  This is the only way we can tell if something 
 * that only exists remotely is a dir or file.  There is a loophole though - if
 * a file exists in the directory, we can tell its a directory.  PathsLSWascalledFor
 * exists for this reason - we might not have to make the extra call.
 */
struct SVN_SUBDIR_INFO {
   _str SubdirHT:[][];
   _str PathsLSWascalledFor:[];
};

#define EDIT_BUTTON_CAPTION "&Edit"
#define UPDATE_BUTTON_CAPTION "&Update"
#define COMMIT_BUTTON_CAPTION "&Commit"

#define SUBVERSION_INFO_FILENAME 'subversioninfo.xml'
#define SUBVERSION_CHILD_DIR_NAME '.svn'

int def_vc_max_status_output_size = 8388608;

#endif
