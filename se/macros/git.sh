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
#pragma option(metadata,"git.e")


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

_metadata enum_flags GIT_FLAGS {
   GIT_FLAG_NONE=0x0,
   GIT_FLAG_FOLLOW_HISTORY=0x1
};

struct GIT_COMMIT_CALLBACK_INFO {
   bool comment_is_filename;
   _str comment;
   _str commit_options;
};

/* 
   Don't use this struct any more. 
   It is only use for converting
   old GIT data.
*/
struct GIT_SETUP_INFO {
   _str git_exe_name;
};

_str def_git_exe_path;
_str _git_cached_exe_path;

_str def_git_global_options;
