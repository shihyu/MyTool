////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50672 $
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
#ifndef SVC_SH
#define SVC_SH

#if __UNIX__
   #define VCSYSTEM_FILE       'uvcsys.slk'
   #define VC_ERROR_FILENAME   'vcs.slk'
   #define VC_ERROR_FILENAME2  'vcs2.slk'
   #define VC_COMMENT_FILENAME 'cmt.slk'
#else
   #define VCSYSTEM_FILE       'vcsystem.slk'
   #define VC_ERROR_FILENAME   '$vcs.slk'
   #define VC_ERROR_FILENAME2  '$vcs2.slk'
   #define VC_COMMENT_FILENAME '$cmt.slk'
#endif


struct SVC_AUTHENTICATE_INFO {
   _str username;
   _str password;
};

struct SVC_ANNOTATION {
   _str userid;
   _str date;
   _str version;
   long seek;
};

struct SVC_FILE_INFO {
   int annotationMarkerType;
   SVC_ANNOTATION annotations[];
};

struct SVC_QUEUE_ITEM {
   _str filename;
   _str VCSystem;
};

struct HISTORY_USER_INFO {
   _str actualRevision;
   _str lineArray[];
};

struct SVCHistoryInfo {
   _str revision;
   _str author;
   _str date;
   _str comment;
   _str affectedFilesDetails;
   int picIndex;
   int lsibIndex;
   int rsibIndex;
   int firstChildIndex;
   int parentIndex;
   boolean expandable;
   boolean hidden;
   _str revisionCaption;
   _str tagNames[];
};


enum_flags SVCHistoryAddFlags {
   ADDFLAGS_SIBLINGAFTER,
   ADDFLAGS_SIBLINGBEFORE,
   ADDFLAGS_ASCHILD,
};

enum_flags SVCFileStatus {
   SVC_STATUS_SCHEDULED_FOR_ADDITION,    // 0x00000001
   SVC_STATUS_SCHEDULED_FOR_DELETION,    // 0x00000002
   SVC_STATUS_MODIFIED,                  // 0x00000004
   SVC_STATUS_CONFLICT,                  // 0x00000008
   SVC_STATUS_EXTERNALS_DEFINITION,      // 0x00000010
   SVC_STATUS_IGNORED,                   // 0x00000020
   SVC_STATUS_NOT_CONTROLED,             // 0x00000040
   SVC_STATUS_MISSING,                   // 0x00000080
   SVC_STATUS_NODE_TYPE_CHANGED,         // 0x00000100
   SVC_STATUS_PROPS_MODIFIED,            // 0x00000200
   SVC_STATUS_PROPS_ICONFLICT,           // 0x00000400
   SVC_STATUS_LOCKED,                    // 0x00000800
   SVC_STATUS_SCHEDULED_WITH_COMMIT,     // 0x00001000
   SVC_STATUS_SWITCHED,                  // 0x00002000
   SVC_STATUS_NEWER_REVISION_EXISTS,     // 0x00004000
   SVC_STATUS_TREE_ADD_CONFLICT,         // 0x00008000
   SVC_STATUS_TREE_DEL_CONFLICT,         // 0x00010000
   SVC_STATUS_EDITED,                    // 0x00020000
   SVC_STATUS_NO_LOCAL_FILE,             // 0x00040000
   SVC_STATUS_PROPS_NEWER_EXISTS,        // 0x00080000
   SVC_STATUS_DELETED,                   // 0x00100000
   SVC_STATUS_UNMERGED,                  // 0x00200000
   SVC_STATUS_COPIED_IN_INDEX,           // 0x00400000
};

enum_flags SVCCommandsAvailable {
   SVC_COMMAND_AVAILABLE_COMMIT,
   SVC_COMMAND_AVAILABLE_EDIT,
   SVC_COMMAND_AVAILABLE_DIFF,
   SVC_COMMAND_AVAILABLE_HISTORY,
   SVC_COMMAND_AVAILABLE_MERGE,
   SVC_COMMAND_AVAILABLE_REVERT,
   SVC_COMMAND_AVAILABLE_UPDATE,
   SVC_COMMAND_AVAILABLE_ADD,
   SVC_COMMAND_AVAILABLE_REMOVE,
   SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_FIXED_PATH,
   SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PATH,
   SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_PROJECT,
   SVC_COMMAND_AVAILABLE_GUI_MFUPDATE_WORKSPACE,
   SVC_COMMAND_AVAILABLE_GET_URL_CHILDREN,
   SVC_COMMAND_AVAILABLE_CHECKOUT,
   SVC_COMMAND_AVAILABLE_BROWSE_REPOSITORY,
   SVC_COMMAND_AVAILABLE_PUSH_TO_REPOSITORY,
   SVC_COMMAND_AVAILABLE_PULL_FROM_REPOSITORY,
   SVC_COMMAND_AVAILABLE_HISTORY_DIFF,
};

enum SVCCommands {
   SVC_COMMAND_COMMIT,
   SVC_COMMAND_EDIT,
   SVC_COMMAND_DIFF,
   SVC_COMMAND_HISTORY,
   SVC_COMMAND_MERGE,
   SVC_COMMAND_REVERT,
   SVC_COMMAND_UPDATE,
   SVC_COMMAND_ADD,
   SVC_COMMAND_REMOVE,
   SVC_COMMAND_CHECKOUT,
   SVC_COMMAND_BROWSE_REPOSITORY,
   SVC_COMMAND_PUSH_TO_REPOSITORY,
   SVC_COMMAND_PULL_FROM_REPOSITORY,
   SVC_COMMAND_HISTORY_DIFF,
};

enum_flags SVCSystemSpecificFlags {
   SVC_REQUIRES_EDIT,
   SVC_UPDATE_PATHS_RECURSIVE
}

struct SVCHistoryFileInfo {
   _str URL;
   _str localFilename;
   _str currentRevision;
   _str currentLocalRevision;

   _str revisionCaptionToSelectInTree;

   SVCFileStatus fileStatus;
};

struct SVC_UPDATE_INFO {
   _str filename;
   SVCFileStatus status;
};

enum SVC_UPDATE_TYPE {
   SVC_UPDATE_PATH,
   SVC_UPDATE_WORKSPACE,
   SVC_UPDATE_PROJECT
};

enum SVC_HISTORY_BRANCH_OPTIONS {
   SVC_HISTORY_NOT_SPECIFIED,
   SVC_HISTORY_NO_BRANCHES,
   SVC_HISTORY_WITH_BRANCHES
};

#define SVC_UPDATE_CAPTION_UPDATE '&Update'
#define SVC_UPDATE_CAPTION_COMMIT '&Commit'
#define SVC_UPDATE_CAPTION_ADD 'Add'
#define SVC_UPDATE_CAPTION_MERGE '&Merge'
#define SVC_UPDATE_CAPTION_RESOLVE 'Resolve'

#define SVC_BITMAP_LIST_UPDATE _pic_file_old' '_pic_file_old_mod' '_pic_cvs_fld_m' '_pic_cvs_file_error' '_pic_cvs_file_obsolete' '_pic_cvs_file_new' '_pic_cvs_fld_date' '_pic_file_del
#define SVC_BITMAP_LIST_COMMITABLE _pic_file_mod' '_pic_cvs_fld_mod' '_pic_cvs_file_conflict_updated' '_pic_cvs_filem' '_pic_cvs_filep' '_pic_cvs_fld_p' '_pic_cvs_filem_mod
#define SVC_BITMAP_LIST_ADD _pic_cvs_file_qm' '_pic_cvs_fld_qm
#define SVC_BITMAP_LIST_CONFLICT _pic_cvs_file_conflict' '_pic_cvs_file_conflict_local_added' '_pic_cvs_file_conflict_local_deleted
#define SVC_BITMAP_LIST_COMMIT_DEL _pic_cvs_filem
#define SVC_BITMAP_LIST_FOLDER _pic_fldopen

#define DEFAULT_NUM_VERSIONS_IN_REP_BROWSER 1000

int def_svc_logging=0;

#endif   // SVC_SH
