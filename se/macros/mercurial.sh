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
#pragma option(metadata,"mercurial.e")

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
   bool comment_is_filename;
   _str comment;
   _str commit_options;
};

/* 
   Don't use this struct any more. 
   It is only use for converting
   old CVS data.
*/
struct HG_SETUP_INFO {
   _str hg_exe_name;
};


_str def_hg_exe_path;
_str _hg_cached_exe_path;

