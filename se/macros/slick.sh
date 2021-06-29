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
#ifndef SLICK_SH
#define SLICK_SH

// specify that metadata for declarations in this header
// are to be only compiled into main.ex
#pragma option(metadata,"main.e")


// IF we are running old macro compiler to convert Visual SlickEdit
//    macro to Slick-C.
#if __VERSION__<1.8
   #include "slick24.sh"
#else

const MAXINT= (0x7fffffff);

const NO_NAME= 'Untitled<';

const VSCFGPLUGIN_PREFIX='plugin:';
const VSCFGPLUGIN_DIR=   'plugin://';
const VSCFGPLUGIN_BASE=  'plugin://com_slickedit.base/';
const VSCFGFILE_USER_PRJTEMPLATES= 'usrprjtemplates.vpt';
const VSCFGFILE_PRJTEMPLATES= 'prjtemplates.vpt';
const VSCFGFILE_OEMTEMPLATES= 'oem.vpt';
const VSCFGFILE_USER=         'user.cfg.xml';
const VSCFGFILE_USER_MENUS=   'userMenus.xml';

const VSCFGFILEEXT_CFGXML= ".cfg.xml";
const VSCFGFILEEXT_ALIASES= ".als.xml";
const VSCFGFILE_ALIASES= ("alias":+VSCFGFILEEXT_ALIASES);

//#define SLICK_HELP_MAINPAGE  "VSE9Help.htm"
const SLICK_HELP_MAINPAGE=  "index.htm";
const DELTA_ARCHIVE_EXT  =  ".vsdelta2";
const DELTA_DIR_NAME     =  "vsdelta";
const SAVELOG_FILE       =  "savelog.xml";
//#define BITMAPS_DIR   ("bitmaps.zip":+_FILESEP:+"bitmaps")
#define VSE_BITMAPS_DIR   ("bitmaps")

/* some machine dependant constants. */
#define FILESEP    (_FILESEP:+"")
#define FILESEP2   (_FILESEP2:+"")
#define PATHSEP    (_PATHSEP:+"")
/* 
  smb://, http://, and plugin:// are all valid filespecs.
  The following will corectly parse a list of files/paths
  separated with PATHSEP on Unix.

  Example
      parse filename_list with filename (PARSE_PATHSEP_RE),'r' filename_list;
*/
#define PARSE_PATHSEP_RE (_isUnix()?('\:~(//)'):';')

#define COMMANDSEP (_COMMANDSEP:+"")
_str _FILESEP; // \  /
_str _FILESEP2; // /  \
_str _PATHSEP; // ;  :
_str _COMMANDSEP; // ";" "&"

#define EXTENSION_EXE      (_isWindows()? ".exe" : "")
#define EXTENSION_BATCH    (_isWindows()? ".cmd" : "")
#define EXTENSION_BAT      (_isWindows()? ".bat" : "")
const ARGSEP= "-";
#define EXE_FILE_RE "*":+EXTENSION_EXE;

_str ALLFILES_RE;  // '*.*' '*'

#define _NAME_HAS_DRIVE (_isWindows())
#define DLLEXT  (_isWindows()? ".dll" : "")

const VSNULLSEEK=-3;

const VSREGISTEREDTM= "\x{00AE}";

const VSREGISTEREDTM_TITLEBAR= "\x{00AE}";

const _SLICKBIN= "VSLICKBIN";
const _SLICKMISC= "VSLICKMISC";
const _SLICKMACROS= "VSLICKMACROS";
const _SLICKPATH= "VSLICKPATH";
const _SLICKRESTORE= "VSLICKRESTORE";
const _SLICKEDITCONFIG= "SLICKEDITCONFIG";
const _VSECLIPSECONFIG= "VSECLIPSECONFIG";
const _VSECLIPSECONFIGVERSION= "VSECLIPSECONFIGVERSION";
const _SLICKCONFIG= "SLICKEDITCONFIGVERSION";
const _SLICKLOAD= "VSLICKLOAD";
const _SLICKSAVE= "VSLICKSAVE";
const _SLICKTAGS= "VSLICKTAGS";
const _SLICKREFS= "VSLICKREFS";
const _SLICKALIAS= "VSLICKALIAS";
const _MDIMENU= "_mdi_menu";
const USERMACS_FILE= 'vusrmacs';       /* File to contain all user recorded macros. */
const USERMODS_FILE= 'vusrmods';       /* File which loads user macro modules. */
const USERMENUS_FILE= 'userMenus';
const USERTOOLBARS_FILE= 'userToolbars';
/* number of definable keys in a key table. */
const _WINDOW_CONFIG_FILE= "vrestore.slk";
const BSC_FILE_EXT= '.bsc';
const REF_FILE_EXT= '.vtr';
const TAG_FILE_EXT= '.vtg';
const PRJ_TAG_FILE_EXT= '.vtg';
const PRJ_FILE_EXT= '.vpj';
const PRJ_FILE_BACKUP_EXT= ".bakvpj";
const WORKSPACE_FILE_EXT= '.vpw';
const WORKSPACE_FILE_BACKUP_EXT= ".bakvpw";
const ECLIPSE_WORKSPACE_FILE_EXT= '.vpwecl';

const WORKSPACE_STATE_FILE_EXT_UNIX=  ".vpwhistu";
const WORKSPACE_STATE_FILE_EXT_WINDOWS= ".vpwhist";
#define WORKSPACE_STATE_FILE_EXT  (_isUnix()? WORKSPACE_STATE_FILE_EXT_UNIX : WORKSPACE_STATE_FILE_EXT_WINDOWS)

// Xcode projects are "workspaces"
const XCODE_PROJECT_EXT= '.pbxproj';
const XCODE_PROJECT_SHORT_BUNDLE_EXT= '.xcode';
const XCODE_PROJECT_LONG_BUNDLE_EXT= '.xcodeproj';
const XCODE_LEGACY_VENDOR_NAME= 'apple xcode';
const XCODE_PROJECT_VENDOR_NAME= 'xcode project';
    
const XCODE_WKSPACE_BUNDLE_EXT= '.xcworkspace';
const XCODE_WKSPACE_VENDOR_NAME= 'xcode workspace';

const VCPP_PROJECT_FILE_EXT= '.dsp';
const VCPP_PROJECT_WORKSPACE_EXT= '.dsw';

const VISUAL_STUDIO_SOLUTION_EXT= '.sln';

const VISUAL_STUDIO_VB_PROJECT_EXT= '.vbproj';
const VISUAL_STUDIO_VCPP_PROJECT_EXT= '.vcproj';
const VISUAL_STUDIO_VCX_PROJECT_EXT= '.vcxproj';
const VISUAL_STUDIO_CSHARP_PROJECT_EXT= '.csproj';
const VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT= '.csdproj';
const VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT= '.vbdproj';
const VISUAL_STUDIO_JSHARP_PROJECT_EXT= '.vjsproj';
const VISUAL_STUDIO_TEMPLATE_PROJECT_EXT= '.etp';
const VISUAL_STUDIO_DATABASE_PROJECT_EXT= '.dbp';
const VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT= '.icproj';
const VISUAL_STUDIO_FSHARP_PROJECT_EXT= '.fsproj';
//#define VISUAL_STUDIO_UNITY_PROJECT_EXT '.unityproj'

const VCPP_EMBEDDED_PROJECT_FILE_EXT= '.vcp';
const VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT= '.vcw';
const VCPP_VENDOR_NAME= 'microsoft visual c++';
const VISUAL_STUDIO_VENDOR_NAME= 'microsoft visual studio';
const VISUAL_STUDIO_VCPP_VENDOR_NAME= 'microsoft visual studio visual c++';
const VISUAL_STUDIO_CSHARP_VENDOR_NAME= 'microsoft visual studio csharp';
const VISUAL_STUDIO_VB_VENDOR_NAME= 'microsoft visual studio visual basic';
const VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME= 'microsoft visual studio csharp device';
const VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME= 'microsoft visual studio visual basic device';
const VISUAL_STUDIO_JSHARP_VENDOR_NAME= 'microsoft visual studio jsharp';
const VISUAL_STUDIO_FSHARP_VENDOR_NAME= 'microsoft visual studio fsharp';
const VISUAL_STUDIO_TEMPLATE_NAME= 'microsoft visual studio enterprise template';
const VISUAL_STUDIO_DATABASE_NAME= 'microsoft visual studio database';
//#define VISUAL_STUDIO_UNITY_VENDOR_NAME 'microsoft visual studio unity'
const VISUAL_STUDIO_MSBUILD_VENDOR_NAME= 'microsoft visual studio msbuild';
const ECLIPSE_VENDOR_NAME= 'eclipse';
const VCPP_EMBEDDED_VENDOR_NAME= 'microsoft embedded visual tools';
const TORNADO_WORKSPACE_EXT= '.wsp';
const TORNADO_PROJECT_EXT= '.wpj';
const TORNADO_VENDOR_NAME= 'wind river tornado';
const BORLANDCPP_VENDOR_NAME= 'borland c++';
const JBUILDER_PROJECT_EXT= '.jpx';
const JBUILDER_VENDOR_NAME= 'borland jbuilder';
const ANT_BUILD_FILE_EXT= '.xml';
const MAVEN_BUILD_FILE_EXT= '.xml';
const MAVEN_BUILD_FILE_NAME= 'pom.xml';
const NANT_BUILD_FILE_EXT= '.build';
const MACROMEDIA_FLASH_PROJECT_EXT= '.flp';
const MACROMEDIA_FLASH_VENDOR_NAME= 'macromedia flash';
const GRADLE_BUILD_FILE= 'GRADLE_BUILD_FILE';

const COMPILER_NAME_VS2=              "Visual Studio 2";
const COMPILER_NAME_VS4=              "Visual Studio 4";
const COMPILER_NAME_VS5=              "Visual Studio 5";
const COMPILER_NAME_VS6=              "Visual Studio 6";
const COMPILER_NAME_VSDOTNET=         "Visual Studio .NET";
const COMPILER_NAME_VS2003=           "Visual Studio 2003";
const COMPILER_NAME_VS2005=           "Visual Studio 2005";
const COMPILER_NAME_VS2005_EXPRESS=   "Visual Studio 2005 Express";
const COMPILER_NAME_VS2008=           "Visual Studio 2008";
const COMPILER_NAME_VS2008_EXPRESS=   "Visual Studio 2008 Express";
const COMPILER_NAME_VS2010=           "Visual Studio 2010";
const COMPILER_NAME_VS2010_EXPRESS=   "Visual Studio 2010 Express";
const COMPILER_NAME_VS2012=           "Visual Studio 2012";
const COMPILER_NAME_VS2012_EXPRESS=   "Visual Studio 2012 Express";
const COMPILER_NAME_VS2013=           "Visual Studio 2013";
const COMPILER_NAME_VS2013_EXPRESS=   "Visual Studio 2013 Express";
const COMPILER_NAME_VS2015=           "Visual Studio 2015";
const COMPILER_NAME_VS2015_EXPRESS=   "Visual Studio 2015 Express";
const COMPILER_NAME_VS2017=           "Visual Studio 2017";
const COMPILER_NAME_VS2019=           "Visual Studio 2019";
const COMPILER_NAME_VCPP_TOOLKIT2003= "Visual C++ Toolkit 2003";
const COMPILER_NAME_PLATFORM_SDK2003= "Microsoft Platform SDK";
const COMPILER_NAME_DDK=              "Windows DDK";
const COMPILER_NAME_BORLAND=          "Borland C++";
const COMPILER_NAME_BORLAND6=         "Borland C++ Builder";
const COMPILER_NAME_BORLANDX=         "Borland C++ BuilderX";
const COMPILER_NAME_CYGWIN=           "Cygwin";
const COMPILER_NAME_LCC=              "LCC";
const COMPILER_NAME_GCC=              "GCC";
const COMPILER_NAME_CLANG=            "Clang";
const COMPILER_NAME_CC=               "CC";
const COMPILER_NAME_SUNCC=            "Sun C++";
const COMPILER_NAME_CL=               "CL";
const COMPILER_NAME_USR_INCLUDES=     "Unix Includes";
const COMPILER_NAME_LATEST=           "Latest Version";
const COMPILER_NAME_DEFAULT=          "Default Compiler";
const COMPILER_NAME_NONE=             "None";

const COMPILER_NAME_JBUILDER=         "Borland JBuilder";
const COMPILER_NAME_NETSCAPE=         "Netscape";
const COMPILER_NAME_SUPERCEDE=        "SuperCede";
const COMPILER_NAME_VISUALCAFE=       "Visual Cafe";
const COMPILER_NAME_JPP=              "Microsoft Java VM";
const COMPILER_NAME_IBM=              "IBM Java Developer Kit";
const COMPILER_NAME_SUN=              "JDK";


const CONFIG_AUTOMATIC= "Automatic";

// wrap flags for _rubout and _delete_char
const VSWRAPFLAG_LINEWRAP=   0x1;
const VSWRAPFLAG_WORDWRAP=   0x2;
/**
 * Assert that "cond" is true, otherwise create Slick-C(R) stack 
 * error and report file name and line number of error. 
 */
#define ASSERT(cond) _assert(cond, '"'#cond'" in file '__FILE__' on line '__LINE__)

struct available_compilers {
   bool hasVC6;
   bool hasDotNET;
   bool hasDotNet2003;
   bool hasDotNet2005;
   bool hasDotNet2005Express;
   bool hasDotNet2008;
   bool hasDotNet2008Express;
   bool hasDotNet2010;
   bool hasDotNet2010Express;
   bool hasDotNet2012;
   bool hasDotNet2012Express;
   bool hasDotNet2013;
   bool hasDotNet2013Express;
   bool hasDotNet2015;
   bool hasDotNet2015Express;
   bool hasDotNet2017;
   bool hasToolkit;
   bool hasPlatformSDK;
   bool hasBorland;
   _str latestMS;
   _str latestGCC;
   _str latestCygwin;
   _str latestCC;
   _str latestLCC;
   _str latestDDK;
   _str latestBorland;
   _str latestCLANG;
};

struct DotNetFrameworkInfo {
   _str name;
   _str version;
   _str sdk_dir;
   _str install_dir;
   _str maketags_args;
   _str display_name;
};

struct XcodeSDKInfo{
   _str name;
   _str canonicalName;
   _str sdk_root;
   _str framework_root;
};

// vusrs13.0.0.0e
#define USERSYSO_FILE_PREFIX  (_isUnix()? "vunxs" : "vusrs" )
const USERSYSO_FILE_SUFFIX= 't';

const SLICK_HELPINDEX_FILE= "slickeditindex.xml";  // Help index file
const _MDI_INTERFACE= 1;
const SYSOBJS_FILE= "sysobjs";

#define SLICK_TAGS_FILE       (_isUnix()? "utags.slk"        : "tags.slk"   )
#define SLICK_TAGS_DB         (_isUnix()? "utags.vtg"        : "tags.vtg"   )
#define SLICK_HELP_FILE       ((_isWindows() && machine_bits()==64) ?"slickedit5.qhc":"slickedit.qhc")
#define USERKEYS_FILE         (_isUnix()? "vunxkeys"         : "vusrkeys"   )
#define USERDATA_FILE         (_isUnix()? "vunxdata"         : "vusrdata"   )
#define USERDEFS_FILE         (_isUnix()? "vunxdefs"         : "vusrdefs"   )
#define USEROBJS_FILE         (_isUnix()? "vunxobjs"         : "vusrobjs"   )
const STATE_FILENAME=        ("vslick.sta");
#define SYSCPP_FILE           (_isUnix()? "usyscpp.h"        : "syscpp.h"   )
#define USERCPP_FILE          (_isUnix()? "unxcpp.h"         : "usercpp.h"  )

#define VS_SSH_ASKPASS_COMMAND ("vs-ssh-askpass":+EXTENSION_EXE)

const MAX_LINE= 0x7fffffff;

const DEBUGGER_CONFIG_FILENAME= 'debugger.xml';
const COMPILER_CONFIG_FILENAME= 'compilers.xml';

/* Meaning of rc flags passed to internal commands (DEFC)*/
const PAUSE_COMMAND=  4;               /* Command should wait for key press */

/* buffer flags for p_buf_flags property. */
const VSBUFFLAG_HIDDEN=               0x1;  /* NEXT_BUFFER won't switch to this buffer */;
const VSBUFFLAG_THROW_AWAY_CHANGES=   0x2;  /* Allow quit without prompting on modified buffer */
const VSBUFFLAG_KEEP_ON_QUIT=         0x4;  /* Don't delete buffer on QUIT.  */
const VSBUFFLAG_REVERT_ON_THROW_AWAY= 0x10;
const VSBUFFLAG_PROMPT_REPLACE=       0x20;
const VSBUFFLAG_DELETE_BUFFER_ON_CLOSE= 0x40;  // Indicates whether a list box/edit window buffer
                                               // should be deleted when the dialog is closed
const VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS= 0x80;   /* Specifies that buffer is currently being uploaded via FTP*/
const VSBUFFLAG_FTP_BINARY=             0x100;  /* Specifies that the FTP buffer should be transferred binary by default */
const VSBUFFLAG_DISABLE_SPELL_CHECK_WHILE_TYPING=  0x200;  /* Don't allow spell checking while typing for this buffer */


const HIDE_BUFFER=         VSBUFFLAG_HIDDEN;
const THROW_AWAY_CHANGES=  VSBUFFLAG_THROW_AWAY_CHANGES;
const KEEP_ON_QUIT=        VSBUFFLAG_KEEP_ON_QUIT;
const REVERT_ON_THROW_AWAY=      VSBUFFLAG_REVERT_ON_THROW_AWAY;
const PROMPT_REPLACE_BFLAG=      VSBUFFLAG_PROMPT_REPLACE;
const DELETE_BUFFER_ON_CLOSE=    VSBUFFLAG_DELETE_BUFFER_ON_CLOSE;



/* p_color_flags property. */
/* These color flags indicate what coloring should be applied. */
_metadata enum_flags ColorFlags {
   LANGUAGE_COLOR_FLAG,    
   MODIFY_COLOR_FLAG,      
   CLINE_COLOR_FLAG,      
};

// _clex_find flags
const OTHER_CLEXFLAG=        0x1;
//ERROR_CLEXFLAG     =  0x2
const KEYWORD_CLEXFLAG=      0x4;
const NUMBER_CLEXFLAG=       0x8;
const STRING_CLEXFLAG=       0x10;
const COMMENT_CLEXFLAG=      0x20;
const PPKEYWORD_CLEXFLAG=    0x40;
const LINENUM_CLEXFLAG=      0x80;
const SYMBOL1_CLEXFLAG=      0x100;    // punctuation
const SYMBOL2_CLEXFLAG=      0x200;    // library functions
const SYMBOL3_CLEXFLAG=      0x400;    // operators
const SYMBOL4_CLEXFLAG=      0x800;    // other user defined
const FUNCTION_CLEXFLAG=     0x1000;
const NOSAVE_CLEXFLAG=      0x2000;
const PARAMETER_CLEXFLAG=    0x4000;
// NOSAVE lines are treated like comments to
// simplify macro programming.
//#define NOSAVE_CLEXFLAG       0x2000



const DIR_SIZE_COL=      2;
const DIR_SIZE_WIDTH=    10;
const DIR_DATE_COL=      14;
const DIR_DATE_WIDTH=    10;
const DIR_TIME_COL=      26;
const DIR_TIME_WIDTH=    (6);
const DIR_ATTR_COL=      (33);

   int DIR_ATTR_WIDTH;  //  5    10
   int DIR_FILE_COL;    //  (40+2*_dbcs())   (45+2*_dbcs())


/* Each entry in the names symbol table has a type. */
/* The type flags values are below. */
const PROC_TYPE=      0x1;
const VAR_TYPE=       0x4;
const EVENTTAB_TYPE=  0x8;
const COMMAND_TYPE=   0x10;
const GVAR_TYPE=      0x20;
const GPROC_TYPE=     0x40;
const MODULE_TYPE=    0x80;
const PICTURE_TYPE=   0x100;
const BUFFER_TYPE=    0x200;
const OBJECT_TYPE=    0x400;
const OBJECT_MASK=    0xf800;
const OBJECT_SHIFT=   11;
const INFO_TYPE=      0x10000;
const DLLCALL_TYPE=   0x40000;   /* Entries with this flag MUST also have the
                                    COMMAND_TYPE or PROC_TYPE flag. */
const DLLMODULE_TYPE= 0x80000;
const ENUM_TYPE=      0x400000;
const ACLASS_TYPE=    0x800000;
const INTERFACE_TYPE= 0x1000000;
const CONST_TYPE=     0x4000000;
const MISC_TYPE=      0x20000000;
const IGNORECASE_TYPE=  0x80000000;


const HELP_TYPES= ( "proc="PROC_TYPE           :+" ":+
                     "var="VAR_TYPE             :+" ":+
                     "eventtab="EVENTTAB_TYPE   :+" ":+
                     "command="COMMAND_TYPE     :+" ":+
                     "gvar="GVAR_TYPE           :+" ":+
                     "gproc="GPROC_TYPE         :+" ":+
                     "module="MODULE_TYPE       :+" ":+
                     "picture="PICTURE_TYPE     :+" ":+
                     "bufvar="BUFFER_TYPE       :+" ":+
                     "object="OBJECT_TYPE       :+" ":+
                     "info="INFO_TYPE           :+" ":+
                     "dllcall="DLLCALL_TYPE     :+" ":+
                     "dllmodule="DLLMODULE_TYPE :+" ":+
                     "enum="ENUM_TYPE           :+" ":+
                     "class="ACLASS_TYPE        :+" ":+
                     "interface="INTERFACE_TYPE :+" ":+
                     "const="CONST_TYPE         :+" ":+
                     "misc="MISC_TYPE           :+" ":+
                     "any=-1 ");

const HELP_CLASSES=  ("window=1 search=2 cursor=4 mark=8 misc=16 name=32":+" ":+
           "string=64 display=128 keyboard=256 buffer=512"    :+" ":+
           "file=1024 menu=2048 help=4096 cmdline=8192" :+" ":+
           "language=16384 mouse=32768 any=-1");

const PCB_TYPES= ("command="COMMAND_TYPE:+" ":+"proc="PROC_TYPE);

// Constant window handles
const _desktop=            1;
const _app=                2;
const _mdi=                3;
const _cmdline=            4;
const VSWID_HIDDEN=        5;
const VSWID_STATUS=        6;
const VSWID_RETRIEVE=      7;

/* view id of the internal command retrieve file ".command" */
const RETRIEVE_VIEW_ID=    VSWID_RETRIEVE;
/* buf  id of the internal command retrieve file ".command" */
const RETRIEVE_BUF_ID=     0;
/* View id activated before loading a system file */
/* into the hidden window for system files like .command, .kill, etc. */
const HIDDEN_WINDOW_ID=    VSWID_HIDDEN;
const HIDDEN_VIEW_ID=      HIDDEN_WINDOW_ID;

const TERMINATE_MATCH=    0x01;  /* Old convention _file_ */
const FILE_CASE_MATCH=    0x02;  /* _complete=_fposcase */
const NO_SORT_MATCH=      0x04;  /* ns_ */
const REMOVE_DUPS_MATCH=  0x08;  /* __ */
const AUTO_DIR_MATCH=     0x10;
const ONE_ARG_MATCH=      0x20;  // Command or completion supports one argument
                       // with spaces.
const EXACT_CASE_MATCH=   0x40;
const SMALLSORT_MATCH=    0x80;
const EMACS_BUF_MATCH=    0x100; /* Flag to make select_buffer capable of listing matches with '<>' chars in line */
const APPEND_SPACE_MATCH=  0x200;  /* When space bar is pressed, always insert a space instead of completing more. */
const MAYBE_APPEND_SPACE_MATCH=  0x400; /* When space bar is pressed, insert a space if no more can be completed. */
const DISKIO_TIMEOUT_MATCH=  0x800; /* Intended for completion tasks which do a findfirst/findnext on disk files. */
const REMOVE_DUPS_REL_ABS_MATCH=  0x1000;  /* Remove relative vs absolute files */


const MORE_ARG=       "*";      /* Indicate more arguments. */
                        /* '!' indicates last argument. */
const WORD_ARG=       "w";      /* Match what was typed. */
                        /* Look for any file. */
const NONE_ARG=       "";
const FILE_ARG=       ("f:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH));
const FILE_MAYBE_LIST_BINARIES_ARG=       ("a:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|REMOVE_DUPS_REL_ABS_MATCH));
const FILENOAUTODIR_ARG=       ("f:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH));
const FILENOQUOTES_ARG=   ("fnq:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
const SEMICOLON_FILES_ARG=   ("semicolonfiles:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
const PROJECT_FILE_ARG=   ("project_file:"(FILE_CASE_MATCH|AUTO_DIR_MATCH));
const WORKSPACE_FILE_ARG= ("wkspace_file:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|REMOVE_DUPS_MATCH));
const PROJECT_FILENAME_ARG=   ("project_filename:"(FILE_CASE_MATCH|AUTO_DIR_MATCH));
const DIR_ARG=       ("dir:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH));
const DIRNOQUOTES_ARG=   ("dirnq:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
const DIRNEW_ARG=    ("dir:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH|APPEND_SPACE_MATCH));
const DIRNEW_NOQUOTES_ARG=    ("dirnq:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH|APPEND_SPACE_MATCH));
const MULTI_FILE_ARG= (FILE_ARG'*');
const FILENEW_ARG=   ("f:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|APPEND_SPACE_MATCH));
const FILENEW_NOQUOTES_ARG=   ("fnq:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|APPEND_SPACE_MATCH));
const PATH_SEARCH_ARG=    ("path_search:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
const PATH_SEARCH_NOQUOTES_ARG=    ("path_searchnq:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
const BUFFER_ARG=     ("b:"FILE_CASE_MATCH);
const EMACS_BUFFER_ARG= ("b:"(FILE_CASE_MATCH|EMACS_BUF_MATCH));
const COMMAND_ARG=    ("c:"(EXACT_CASE_MATCH|REMOVE_DUPS_MATCH));
const COMMANDLINE_ARG= ("cl:"(EXACT_CASE_MATCH|REMOVE_DUPS_MATCH));
const PICTURE_ARG=    "_pic";
const FORM_ARG=       ("_form:"EXACT_CASE_MATCH);
const OBJECT_ARG=     ("_object:"EXACT_CASE_MATCH);
const OPTIONS_SEARCH_ARG=     ("options:"NO_SORT_MATCH);
const MODULE_ARG=     "m";
const DLLMODULE_ARG=  '_dll';
              // look for procedure or command.
const PC_ARG=         ("pc:"EXACT_CASE_MATCH);
                   /* look Slick-C tag cmd,proc,form */
const SLICKC_FILE_ARG= ("scfile:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH));
const MACROTAG_ARG=   ("mt:"(REMOVE_DUPS_MATCH|TERMINATE_MATCH));
const MACRO_ARG=      ('k:'EXACT_CASE_MATCH);   // User recorded macro
const DIFF_COMMANDS_ARG= ('diff_command:'EXACT_CASE_MATCH);
const PCB_TYPE=       (COMMAND_TYPE|PROC_TYPE);
const PCB_TYPE_ARG=   "pcbt";   /* list proc,command, and built-in types. */
const VAR_ARG=        ("v:"EXACT_CASE_MATCH); /* look for variable. Global vars not included.*/
const ENV_ARG=        "e";      /* look for environment variables. */
const MENU_ARG=       ("_menu:"EXACT_CASE_MATCH);
const MODENAME_ARG=   ("mode:"EXACT_CASE_MATCH);
const BOOKMARK_ARG=   ("bookmark:"EXACT_CASE_MATCH);
const HELP_ARG=       ("h:"(TERMINATE_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH));
                        /* command,macro,built-in,language */
                        /* the '-' means that duplicates are removed. */
const HELP_TYPE=       (COMMAND_TYPE|PROC_TYPE|MISC_TYPE);
const HELP_TYPE_ARG=  "ht";
const HELP_CLASS_ARG= "hc";
const COLOR_FIELD_ARG= "cf";
/* Match tagged procedure. */
const TAG_ARG= ("tag:"(REMOVE_DUPS_MATCH|SMALLSORT_MATCH|TERMINATE_MATCH));
const CLASSNAME_ARG= ("class:"(REMOVE_DUPS_MATCH|SMALLSORT_MATCH|TERMINATE_MATCH));
const CTAGS_ARG= ("ctags:"(REMOVE_DUPS_MATCH|SMALLSORT_MATCH|TERMINATE_MATCH));
const PLUGIN_ARG= ("plg:"(FILE_CASE_MATCH|DISKIO_TIMEOUT_MATCH|AUTO_DIR_MATCH));

/******************************OLD ARG2 FLAGS******************************/
const NCW_ARG2=      0;    // Ignored. Here for backward compatibility.
                           // Previously: Command allowed when there are no MDI child windows.
const ICON_ARG2=     0x2;  // Command allowed when editor control window is iconized
                           // Not necessary if command does not require
                           // an editor control
const CMDLINE_ARG2=  0x4;  // Command supports the command line.

const MARK_ARG2=     0x8;  // ON_SELECT psuedo event should pass control on
                           // to this command and not deselect text first.
const READ_ONLY_ARG2=   0x10; // Command is allowed in read-only mode
                              // Not necessary if command does not require
                              // an editor control
const QUOTE_ARG2=    0x40;   // Indicates that this command must be quoted when
                             // called during macro recording.  Needed only if
                             // command name is an invalid identifier or
                             // keyword.
const LASTKEY_ARG2=  0x80;   // Command requires last_event value to be set
                             // when called during macro recording.
const MACRO_ARG2=  0x100;    // This is a recorded macro command. Used for completion.
const HELP_ARG2=      0;     // Ignored. Here for backward compatibility.
const HELPSALL_ARG2=  0;     // Ignored. Here for backward compatibility.
const TEXT_BOX_ARG2=  0x800; // Command supports any text box control.
const NOEXIT_SCROLL_ARG2= 0x1000; // Do not exit scroll caused by using scroll bars.
const EDITORCTL_ARG2= 0x2000;     // Command supports non-mdi editor control
const NOUNDOS_ARG2=   0x4000;   // Do not automatically call _undo('s').
                                // Require macro to call _undo('s') to
                                // start a new level of undo.
const REQUIRESMDI_ARG2= 0x8000;  // Command requires mdi interface may be because
                                 // it opens a new file or uses _mdi object.
/********************************************************************/


/******************************NEW ARG2 FLAGS******************************/

/**
 * These flags are used in the second part of the name_info() clause 
 * for command definitions. 
 * <pre> 
 *    _command void sample_command(_str file="") name_info(FILENOQUOTES_ARG','VSARG2_READONLY)
 *    {
 *    }
 * </pre> 
 * <p>
 * <b>NOTE:</b>
 * <p>
 * VSARG2_MARK,VSARG2_NOEXIT_SCROLL,
 * VSARG2_READ_ONLY, VSARG2_ICON are now
 * ignored if the command does not require an
 * editor control.
 * <pre>
 *      VSARG2_REQUIRES_EDITORCTL
 *               or
 *      VSARG2_REQUIRES_MDI_EDITORCTL
 * </pre>
 * <p>
 * This is different than versions <= 3.0
 */
enum_flags NameInfoArg2Flags {
   /**
    * Ignored. Here for backward compatibility.
    * Previously: Command allowed when there are no MDI child windows.
    */
   VSARG2_NCW = 0,
   /**
    * Command allowed when editor control window is iconized. 
    * Ignored if command does not require an editor control. 
    */
   VSARG2_ICON = 0x2,
   /**
    * Command supports the command line.
    * <p>
    * VSARG2_CMDLINE allows a fundamental mode
    * key binding to be inherited by the command line
    */
   VSARG2_CMDLINE = 0x4,
   /**
    * ON_SELECT event should pass control on
    * to this command and not deselect text first.
    * Use this when a command works with selections,
    * otherwise the selection will be cleared before the
    * command is executed. 
    * <p> 
    * Ignored if command does not require an editor control
    */
   VSARG2_MARK = 0x8,
   /**
    * Command allowed when editor control is in strict read only mode. 
    * Ignored if command does not require an editor control. 
    */
   VSARG2_READ_ONLY = 0x10,
   /**
    * Do not reset p_hex_nibble and p_hex_field
    */
   VSARG2_LINEHEX = 0x20,
   /**
    * Indicates that this command must be quoted when
    * called during macro recording.  Needed only if
    * command name is an invalid identifier or keyword.
    */
   VSARG2_QUOTE = 0x40,
   /**
    * Command requires last_event value to be set 
    * when called during macro recording.
    */  
   VSARG2_LASTKEY = 0x80,
   /**
    * This is a user recorded macro command. Used for completion.
    */
   VSARG2_MACRO = 0x100,
   /**
    * Ignored. Here for backward compatibility.
    */
   VSARG2_HELP = 0, // was 0x200
   /**
    * Commands which move to a line number but DO NOT require an 
    * editor control may find this flag useful. Normally, it's not needed. 
    * For example, the next-error and prev-error commands use this.
   */
   VSARG2_AUTO_DESELECT = 0x200,
   /**
    * Ignored. Here for backward compatibility.
    */
   VSARG2_HELPSALL = 0, // was 0x400
   /**
    * Command supports any text box control.
    * VSARG2_TEXT_BOX allows a fundamental mode
    * key binding to be inherited by a text box
    */
   VSARG2_TEXT_BOX = 0x800,
   /**
    * Do not exit scroll caused by using scroll bars. 
    * Ignored if command does not require an editor control.
    */
   VSARG2_NOEXIT_SCROLL = 0x1000,
   /**
    * Command allowed in editor control.
    * VSARG2_EDITORCTL allows a fundamental mode
    * key binding to be inherited by a non-MDI editor control
    */
   VSARG2_EDITORCTL = 0x2000,
   /**
    * Do not automatically call _undo('s').
    * Require macro to call _undo('s') to  start a new level of undo.
    */
   VSARG2_NOUNDOS = 0x4000,
   /**
    * Command requires mdi interface may be because 
    * it opens a new file or uses _mdi object.
    */
   VSARG2_REQUIRES_MDI = 0x8000,
   /**
    * Command requires mdi editor control
    */
   VSARG2_REQUIRES_MDI_EDITORCTL = 0x00010000,
   /**
    * Command requires any editor control
    */
   VSARG2_REQUIRES_EDITORCTL = (VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_EDITORCTL),
   
   /**
    * Command requires selection in active buffer
    */
   VSARG2_REQUIRES_AB_SELECTION = 0x00020000,
   /**
    * Command requires block/column selection in any buffer
    */
   VSARG2_REQUIRES_BLOCK_SELECTION = 0x00040000,
   /**
    * Command requires editorctl clipboard
    */
   VSARG2_REQUIRES_CLIPBOARD = 0x00080000,
   /**
    * Command requires active buffer to be in fileman mode
    */
   VSARG2_REQUIRES_FILEMAN_MODE = 0x00100000,
   /**
    * Command requires vs_[ext]_list_tags or ext_proc_search
    */
   VSARG2_REQUIRES_TAGGING = 0x00200000,
   /**
    * Command requires p_utf8==true
    */
   VSARG2_REQUIRES_UNICODE_BUFFER = 0x00400000,
   
   /**
    * Command requires a selection in any buffer
    */
   VSARG2_REQUIRES_SELECTION = 0x00800000,

   /**
    * 
    */
   VSARG2_ONLY_BIND_MODALLY = 0x01000000,
   /**
    * Command requires project support
    */
   VSARG2_REQUIRES_PROJECT_SUPPORT = 0x02000000,
   /**
    * Command requires min/max/restore/iconize window support
    */
   VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW = 0x04000000,
   /**
    * Command requires tiled windowing
    */
   VSARG2_REQUIRES_TILED_WINDOWING = 0x08000000,
   /**
    * Execute this command for each cursor when in multi-cursor mode
    */
   VSARG2_MULTI_CURSOR = 0x10000000,
   /**
    * Command requires SlickEdit Pro edition.
    */
   VSARG2_REQUIRES_PRO_EDITION = 0x20000000,
   /**
    * Command requires SlickEdit Pro or Standard edition.
    */
   VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION = 0x40000000,
   
   /**
    * This command can only be executed from a menu.                  
    * This flag is in a way redundant since you can get the same      
    * effect with more control by writing an _OnUpdate.  However, it  
    * takes much less time to just add this attribute to a command.   
    */
   VSARG2_EXECUTE_FROM_MENU_ONLY = 0x80000000,
   
   /**
    * Bitset of all VSARG2_REQUIRES flags
    */
   VSARG2_REQUIRES = (VSARG2_REQUIRES_TAGGING|
                      VSARG2_REQUIRES_MDI_EDITORCTL|
                      VSARG2_REQUIRES_AB_SELECTION|
                      VSARG2_REQUIRES_BLOCK_SELECTION|
                      VSARG2_REQUIRES_CLIPBOARD|
                      VSARG2_REQUIRES_FILEMAN_MODE|
                      VSARG2_REQUIRES_SELECTION|
                      VSARG2_REQUIRES_MDI|
                      VSARG2_REQUIRES_PROJECT_SUPPORT|
                      VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW|
                      VSARG2_REQUIRES_TILED_WINDOWING),
};

// auto-restore flags
_metadata enum_flags {
   RF_CLIPBOARDS     = 0x1,
   RF_CWD            = 0x2,
   RF_PROCESS        = 0x4,
   RF_PROJECTFILES   = 0x8,
   RF_LINEMODIFY     = 0x10,
   RF_NOSELDISP      = 0x20,
   RF_CBROWSER_TREE  = 0x40,
   RF_WORKSPACE      = 0x80,
   RF_PROJECTS_TREE  = 0x100,
   RF_PROJECT_LAYOUT = 0x200,  // Not implemented yet
};

// Hints passed to restore() during startup, workspace open
enum_flags AutoRestoreHint {
   RH_NO_RESTORE_FILES       = 0x1,  // Restore files
   RH_RESTORING_FROM_PROJECT = 0x2,  // Restoring from a project/workspace
   RH_NO_RESTORE_LAYOUT      = 0x4,  // Restore tool-window layout
   RH_NO_RESET_LAYOUT        = 0x8,  // Do not reset tool-window layout (e.g. when layout not found)
};

// Window layout area flags
enum_flags WindowLayoutArea {
   WLAYOUT_MAINAREA = 0x1,  // Note that dock-channels are included in MAINAREA
   WLAYOUT_MDIAREA  = 0x2,

   WLAYOUT_ALL = 0x3
};

enum_flags RestoreStateFlag {
   RESTORESTATE_POSTCLEANUP     = 0x1,  // Do post-cleanup after restoring state. Includes deleting empty/unused floating windows
   RESTORESTATE_NONAMEMATCH     = 0x2,  // Do not match on name when restoring windows. This implies ~RESTORESTATE_NOINSTANCEMATCH.
   RESTORESTATE_NOINSTANCEMATCH = 0x4,  // Do not match on instance/tile-id when restoring windows. This implies ~RESTORESTATE_NONAMEMATCH.
   RESTORESTATE_ONLYFLOATING    = 0x8   // Only restore to floating windows.
};
_metadata enum_flags DIRPROJFLAGS {
   DIRPROJFLAG_RECURSIVE       = 0x1,
   DIRPROJFLAG_ADD_AS_WILDCARD = 0x2,
   /* Applies to "ADD_AS_WILDCARD" only.
      Create a parent directory folder for
      each wildcard.
    */
   DIRPROJFLAG_DIRECTORY_FOLDER= 0x4,  
   DIRPROJFLAG_FOLLOW_SYMLINKS = 0x8,
   DIRPROJFLAG_DONT_PROMPT     = 0x10,
   /* Applies when Recursive and
      NOT adding a wildcard. Create
      folders for sub directories
   */
   DIRPROJFLAG_CREATE_SUBFOLDERS  = 0x20,

   DIRPROJFLAG_OPTION_ACTIVE_OPEN_TOOL_WINDOW =0x80,
   DIRPROJFLAG_OPTION_ACTIVE_PROJECTS_TOOL_WINDOW =0x100,
};

enum DockAreaFlag {
   DOCKAREA_LEFT   = 0x1,
   DOCKAREA_TOP    = 0x2,
   DOCKAREA_RIGHT  = 0x4,
   DOCKAREA_BOTTOM = 0x8,

   DOCKAREA_NONE   = 0
};

enum WindowRestorePosition {
   RESTORE_LAST     = 0,  // Restore to last known position, either docked or floating
   RESTORE_DOCKED   = 1,  // Restore to last docked position
   RESTORE_FLOATING = 2   // Restore to last floating position
};

enum DockAreaPos {
   DOCKAREAPOS_NONE   = 0,
   DOCKAREAPOS_LEFT,
   DOCKAREAPOS_TOP,
   DOCKAREAPOS_RIGHT,
   DOCKAREAPOS_BOTTOM,
   DOCKAREAPOS_COUNT,

   DOCKAREAPOS_FIRST = DOCKAREAPOS_LEFT,
   DOCKAREAPOS_LAST = DOCKAREAPOS_BOTTOM,
};

// line number flags
_metadata enum_flags LineNumbersFlags {
   LNF_ON,
   LNF_AUTOMATIC,
};

// Horizontal scrolling gets faster over time
const DEF_CHG_COUNT= 10;
const DEF_DEC_DELAY_BY= 0;
/* DEF_MIN_DELAY=0 */
const DEF_INC_MAX_SKIP_BY=  2;
const DEF_MAX_SKIP=  5;

// p_window_flags constants
const HIDE_WINDOW_OVERLAP= 0x1; // Indicates window is hidden window used
                   // for storing system views and buffers.
const OVERRIDE_CURLINE_RECT_WFLAG= 0x4;
const CURLINE_RECT_WFLAG= 0x8;
const OVERRIDE_CURLINE_COLOR_WFLAG= 0x10;
const CURLINE_COLOR_WFLAG= 0x20;

// New p_window_flags constants
const VSWFLAG_HIDDEN=                    0x1;
const VSWFLAG_ON_CREATE_ALREADY_CALLED=  0x2;
const VSWFLAG_OVERRIDE_CURLINE_RECT=     0x4;
const VSWFLAG_CURLINE_RECT=              0x8;
const VSWFLAG_OVERRIDE_CURLINE_COLOR=    0x10;
const VSWFLAG_CURLINE_COLOR=             0x20;
const VSWFLAG_REGISTERED=                0x40;
const VSWFLAG_ON_RESIZE_ALREADY_CALLED=  0x80;
const VSWFLAG_NOLCREADWRITE=             0x100;
// For non-editor controls only.
const VSWFLAG_NO_AUTO_MAP_PAD_KEYS=      0x200;
const VSWFLAG_SHOW_MINIMAP=              0x400;

/* flags for p_word_wrap_style property */
_metadata enum_flags WordWrapStyle {
   STRIP_SPACES_WWS  = 0x1,
   WORD_WRAP_WWS     = 0x2,
   JUSTIFY_WWS       = 0x4,
   ONE_SPACE_WWS     = 0x8,
   PARTIAL_WWS       = 0x10,
};

/* Old search flags */
const IGNORECASE_SEARCH=           0x1;
const MARK_SEARCH=                 0x2;
const POSITIONONLASTCHAR_SEARCH=   0x4;
const REVERSE_SEARCH=              0x8;
const RE_SEARCH=                  0x10;
const WORD_SEARCH=                0x20;
const VIMRE_SEARCH=               0x40; // Old UNIXRE_SEARCH was 0x40
const NO_MESSAGE_SEARCH=          0x80;
const GO_SEARCH=                 0x100;
const INCREMENTAL_SEARCH=        0x200;
const WRAP_SEARCH=               0x400;
const HIDDEN_TEXT_SEARCH=        0x800;
const SCROLL_STYLE_SEARCH=       0x1000;
const BINARYDBCS_SEARCH=         0x2000;
const BRIEFRE_SEARCH=            0x4000;
const PRESERVE_CASE_SEARCH=      0x8000;
const PROMPT_WRAP_SEARCH=      0x400000;
const WILDCARDRE_SEARCH=      0x2000000;
const PERLRE_SEARCH=          0x4000000;
const UNIXRE_SEARCH=        PERLRE_SEARCH;

/* New search ranges */
const VSSEARCHRANGE_CURRENT_BUFFER=      0;
const VSSEARCHRANGE_CURRENT_SELECTION=   1;
const VSSEARCHRANGE_CURRENT_PROC=        2;
const VSSEARCHRANGE_ALL_BUFFERS=         3;

const VSSEARCHRANGE_PROJECT=             4;
const VSSEARCHRANGE_WORKSPACE=           5;

// previous search parameters
int old_search_flags;
int old_search_flags2;
_str old_search_string;
_str old_replace_string;
_str old_word_re;
typeless old_search_reserved;
_str old_search_mark;
int old_search_range;
int old_go;

/* Flags for _set_menu_state function. */
const MF_CHECKED=         1;
const MF_UNCHECKED=       2;
const MF_GRAYED=          4;
const MF_ENABLED=         8;
const MF_SUBMENU=         16;
const MF_DELETED=         64;
const MF_REQUIRES_PRO=    128;
const MF_REQUIRES_PRO_OR_STANDARD=    256;

//#define CFG_PAST_END_OF_LINE   -1
_metadata enum CFGColorConstants {
   CFG_NULL                    = 0,
   CFG_SELECTION               = 1,
   CFG_WINDOW_TEXT             = 2,
   CFG_SBCS_DBCS_SOURCE_WINDOW = CFG_WINDOW_TEXT,
   CFG_CLINE                   = 3,
   CFG_SELECTED_CLINE          = 4,
   CFG_MESSAGE                 = 5,
   CFG_STATUS                  = 6,
   CFG_CMDLINE                 = 7,
   CFG_CURSOR                  = 8,
   //CFG_CMDLINE_SELECT        = 9,
   //CFG_LIST_BOX_SELECT       = 10,
   //CFG_LIST_BOX              = 11,
   CFG_ERROR                   = 12,
   CFG_MODIFIED_LINE           = 13,
   CFG_INSERTED_LINE           = 14,
   CFG_FUNCTION_HELP           = 15,
   CFG_FUNCTION_HELP_FIXED     = 16,
   CFG_KEYWORD                 = 17,
   CFG_LINENUM                 = 18,
   CFG_NUMBER                  = 19,
   CFG_STRING                  = 20,
   CFG_COMMENT                 = 21,
   CFG_PPKEYWORD               = 22,
   CFG_SYMBOL1                 = 23,   // punctuation
   CFG_PUNCTUATION             = CFG_SYMBOL1,
   CFG_SYMBOL2                 = 24,   // library functions
   CFG_LIBRARY_SYMBOL          = CFG_SYMBOL2,
   CFG_SYMBOL3                 = 25,   // operators
   CFG_OPERATOR                = CFG_SYMBOL3,
   CFG_SYMBOL4                 = 26,   // other user defined
   CFG_USER_DEFINED            = CFG_SYMBOL4,
   CFG_IMAGINARY_LINE          = 27,
   CFG_NOSAVE_LINE             = 27,
   CFG_FUNCTION                = 28,
   CFG_LINEPREFIXAREA          = 29,
   CFG_FILENAME                = 30,
   CFG_HILIGHT                 = 31,
   CFG_ATTRIBUTE               = 32,
   CFG_UNKNOWN_TAG             = 33,
   CFG_UNKNOWNXMLELEMENT       = CFG_UNKNOWN_TAG,
   CFG_XHTMLELEMENTINXSL       = 34,
   CFG_ACTIVECAPTION           = 35,
   CFG_INACTIVECAPTION         = 36,
   CFG_SPECIALCHARS            = 37,
   CFG_CURRENT_LINE_BOX        = 38,
   CFG_VERTICAL_COL_LINE       = 39,
   CFG_MARGINS_COL_LINE        = 40,
   CFG_TRUNCATION_COL_LINE     = 41,
   CFG_PREFIX_AREA_LINE        = 42,
   CFG_BLOCK_MATCHING          = 43,
   CFG_INC_SEARCH_CURRENT      = 44,
   CFG_INC_SEARCH_MATCH        = 45,
   CFG_HEX_MODE_COLOR          = 46,
   CFG_SYMBOL_HIGHLIGHT        = 47,

   CFG_DOCUMENT_TAB_MODIFIED   = 48,

   CFG_LINE_COMMENT            = 49,
   CFG_DOCUMENTATION           = 50,
   CFG_DOC_KEYWORD             = 51,
   CFG_DOC_PUNCTUATION         = 52,
   CFG_DOC_ATTRIBUTE           = 53,
   CFG_DOC_ATTR_VALUE          = 54,
   CFG_IDENTIFIER              = 55,
   CFG_IDENTIFIER2             = 56,
   CFG_FLOATING_NUMBER         = 57,
   CFG_HEX_NUMBER              = 58,
   CFG_SINGLEQUOTED_STRING     = 59,
   CFG_BACKQUOTED_STRING       = 60,
   CFG_UNTERMINATED_STRING     = 61,
   CFG_INACTIVE_CODE           = 62,
   CFG_INACTIVE_KEYWORD        = 63,
   CFG_IMAGINARY_SPACE         = 64,
   CFG_INACTIVE_COMMENT        = 65,
   CFG_MODIFIED_ITEM           = 66,
   CFG_NAVHINT                 = 67,
   CFG_XML_CHARACTER_REF       = 68,
   CFG_SEARCH_RESULT_TRUNCATED = 69,
   CFG_MARKDOWN_HEADER         = 70,
   CFG_MARKDOWN_CODE           = 71,
   CFG_MARKDOWN_BLOCKQUOTE     = 72,
   CFG_MARKDOWN_LINK           = 73,
   CFG_MARKDOWN_LINK2          = 74,
   CFG_MARKDOWN_BULLET         = 75,
   CFG_MARKDOWN_EMPHASIS       = 76,
   CFG_MARKDOWN_EMPHASIS2      = 77,
   CFG_MARKDOWN_EMPHASIS3      = 78,
   CFG_CSS_ELEMENT             = 79,
   CFG_CSS_CLASS               = 80,
   CFG_CSS_PROPERTY            = 81,
   CFG_CSS_SELECTOR            = 82,
   CFG_DOCUMENT_TAB_ACTIVE     = 83,
   CFG_DOCUMENT_TAB_SELECTED   = 84,
   CFG_DOCUMENT_TAB_UNSELECTED = 85,
   CFG_SELECTIVE_DISPLAY_LINE  = 86,
   CFG_TAG                     = 87,
   CFG_UNKNOWN_ATTRIBUTE       = 88,

   CFG_REF_HIGHLIGHT_0         = 89,
   CFG_REF_HIGHLIGHT_1         = 90,
   CFG_REF_HIGHLIGHT_2         = 91,
   CFG_REF_HIGHLIGHT_3         = 92,
   CFG_REF_HIGHLIGHT_4         = 93,
   CFG_REF_HIGHLIGHT_5         = 94,
   CFG_REF_HIGHLIGHT_6         = 95,
   CFG_REF_HIGHLIGHT_7         = 96,
   CFG_MINIMAP_DIVIDER         = 97,

   CFG_YAML_TEXT_COLON         = 98, 
   CFG_YAML_TEXT               = 99, 
   CFG_YAML_TAG                = 100,
   CFG_YAML_DIRECTIVE          = 101,
   CFG_YAML_ANCHOR_DEF         = 102,
   CFG_YAML_ANCHOR_REF         = 103,
   CFG_YAML_PUNCTUATION        = 104,
   CFG_YAML_OPERATOR           = 105,    
   CFG_MARKDOWN_EMPHASIS4      = 106,

   // last color ID
   CFG_LAST_COLOR_PLUS_ONE,
   CFG_LAST_DEFAULT_COLOR      = (CFG_LAST_COLOR_PLUS_ONE-1)

   // Legacy constants
   ,CFG_MODIFIED_FILE_TAB       = CFG_DOCUMENT_TAB_MODIFIED
};

// Some configurable fonts that dont have color
const CFG_MENU=                (-1);
const CFG_DIALOG=              (-2);
const CFG_MDICHILDICON=        (-3);
const CFG_MDICHILDTITLE=       (-4);
const CFG_HEX_SOURCE_WINDOW=          (-5);
const CFG_UNICODE_SOURCE_WINDOW=      (-6);
const CFG_FILE_MANAGER_WINDOW=        (-7);
const CFG_DIFF_EDITOR_WINDOW=         (-8);
const CFG_MINIHTML_PROPORTIONAL=      (-9);
const CFG_MINIHTML_FIXED=             (-10);
const CFG_DOCUMENT_TABS=              (-11);
const CFG_UNICODE_DIFF_EDITOR_WINDOW= (-12);
const CFG_SBCS_DBCS_MINIMAP_WINDOW   =(-13);
const CFG_UNICODE_MINIMAP_WINDOW     =(-14);

// largest color

const OI_MDI_FORM=          1;
const OI_FIRST=             OI_MDI_FORM;
const OI_FORM=              2;
const OI_TEXT_BOX=          3;
const OI_CHECK_BOX=         4;
const OI_COMMAND_BUTTON=    5;
const OI_RADIO_BUTTON=      6;
const OI_FRAME=             7;
const OI_LABEL=             8;
const OI_LIST_BOX=          9;
const OI_HSCROLL_BAR=       10;
const OI_VSCROLL_BAR=       11;
const OI_COMBO_BOX=         12;
const OI_HTHELP=            13;
const OI_PICTURE_BOX=       14;
const OI_IMAGE=             15;
const OI_GAUGE=             16;
const OI_SPIN=              17;
const OI_MENU=              18;
const OI_MENU_ITEM=         19;
const OI_TREE_VIEW=         20;
const OI_SSTAB=             21;
const OI_DESKTOP=           22;
const OI_SSTAB_CONTAINER=   23;
const OI_EDITOR=            24;
const OI_MINIHTML=          25;
const OI_SWITCH=            26;
const OI_TEXTBROWSER=       27;
const OI_LAST=              OI_TEXTBROWSER;

const CW_MAX_BUTTON=      0x1;  // Not yet supported
const CW_MIN_BUTTON=      0x2;  // Not yet supported
const CW_NO_CONTROL_BOX=  0x4;  // Not yet supported
const CW_HIDDEN=          0x8;
const CW_MINIMIZED=       0x10; // Not yet supported.
const CW_MAXIMIZED=       0x20; // Not yet supported.
const CW_CHILD=           0x40;
const CW_PARENT=          0x80;
/*                   =0x100 */
const CW_RIGHT_JUSTIFY=   0x200;
const CW_LEFT_JUSTIFY=    0x400;
const CW_CENTER_JUSTIFY=  0x800;  // Not yet suported
const CW_BSDEFAULT=       0x1000;
const CW_EDIT=            0x2000;
const CW_COMBO_LIST_ALWAYS=  0x4000;
const CW_COMBO_NOEDIT=    0x8000;
const CW_CLIP_CONTROLS=   0x40000;

/* Property border styles. p_border_style */
const BDS_NONE=           0;
const BDS_FIXED_SINGLE=   1;
const BDS_SIZABLE=        2;
const BDS_DIALOG_BOX=     3;   /* FIXED_DOUBLE */
const BDS_FIXED_DOUBLE=   3;   /* Same as DIALOG BOX */
const BDS_SUNKEN=         4;
const BDS_SUNKEN_LESS=    5;
const BDS_ROUNDED=        6;

/* Gauge styles. p_style */
const PSGA_HORZ_WITH_PERCENT=  0;
const PSGA_VERT_WITH_PERCENT=  1;
const PSGA_HORIZONTAL=         2;
const PSGA_VERTICAL=           3;
const PSGA_HORZ_ACTIVITY=      4;
const PSGA_VERT_ACTIVITY=      5;

/* Picture styles. p_style. */
const PSPIC_DEFAULT=           0;
const PSPIC_PUSH_BUTTON=       1;
const PSPIC_PARTIAL_BUTTON=    PSPIC_PUSH_BUTTON;  /* Renamed to PS_PIC_PUSH_BUTTON for clarity */
const PSPIC_AUTO_BUTTON=       2;
const PSPIC_AUTO_CHECK=        3;
/*
    PSPIC_BUTTON is used to create an efficient button (no system window) with
    a caption.
    It is also used to create an image control with a picture that
    does not have a border. This is a way to have toolbar bitmap that has
    two states but only requires a bitmap containing one state.
*/
const PSPIC_BUTTON=            4;
const PSPIC_SPLIT_PUSH_BUTTON= 5;  /* A PushButton that is split with button-part on the left, and drop-down arrow on right, separated by a divider. */
const PSPIC_SPLIT_BUTTON=      6;  /* A ToolButton that is split with button-part on the left, and drop-down arrow on right, separated by a divider. */
// Some addition image control style
const PSPIC_SIZEVERT=          7;
const PSPIC_SIZEHORZ=          8;
const PSPIC_GRABBARVERT=       9;
const PSPIC_GRABBARHORZ=       10;
const PSPIC_TOOLBAR_DIVIDER_VERT= 11;
const PSPIC_TOOLBAR_DIVIDER_HORZ= 12;
const PSPIC_FLAT_BUTTON=          13;
const PSPIC_HIGHLIGHTED_BUTTON=   14;
const PSPIC_FLAT_MONO_BUTTON=     15;
//#define PSPIC_DEFAULT_TRANSPARENT  16  /* Obsolete. If you want transparency, then create an image with transparency. */

/* additional fill styles */
const PSPIC_FILL_GRADIENT_HORIZONTAL= 17;
const PSPIC_FILL_GRADIENT_VERTICAL=   18;
const PSPIC_FILL_GRADIENT_DIAGONAL=   19;

const PSPIC_SPLIT_HIGHLIGHTED_BUTTON=   20;  /* A ToolButton that is flat, highlighted on mouse-over, split with button-part on the left, and drop-down arrow on right, separated by a divider. */

// Image control orientation styles
const PSPIC_OHORIZONTAL=  0;
const PSPIC_OVERTICAL=    1;

/* Scroll bar style. p_scroll_bars */
const SB_NONE=         0;
const SB_HORIZONTAL=   1;
const SB_VERTICAL=     2;
const SB_BOTH=         3;

/* Validate styles. p_validate_style. Effects text box and combo box. */
const VS_NONE=     0;
const VS_INTEGER=  1;

/* Init styles. p_init_style. Effects form. */
const IS_NONE=        0x0;
const IS_SAVE_XY=     0x1;
const IS_REINIT=      0x2;
const IS_HIDEONDEL=   0x4;

/* p_indent_style. p_init_style.. */
_metadata enum VSIndentStyle {
   INDENT_NONE       = 0,
   INDENT_AUTO       = 1,
   INDENT_SMART      = 2,
};

enum VSFuncParamAlignStyle {
   FPAS_ALIGN_ON_PARENS       = 0,
   FPAS_CONTINUATION_INDENT   = 1,
   FPAS_AUTO                  = 2,
};

/* max click style. p_max_click */
const MC_SINGLE=   0;
const MC_DOUBLE=   1;
const MC_TRIPLE=   2;

/* Multi select style. p_multi_select */
const MS_NONE=          0;
const MS_SIMPLE_LIST=   1;
const MS_EXTENDED=      2;
const MS_EDIT_WINDOW=   3;

/* Spin control states. p_value */
const SPIN_STATE_NORMAL=  0x00;
const SPIN_STATE_UP=      0x01;
const SPIN_STATE_DOWN=    0x02;
const SPIN_STATE_HOT=     0x04;

//
// Mouse pointers (p_mouse_pointer)
//

// Built-in
const MP_DEFAULT=    0;
const MP_ARROW=      (-1);
const MP_CROSS=      (-2);
const MP_IBEAM=      (-3);
const MP_ICON=       (-4);
const MP_SIZE=       (-5);
const MP_SIZENESW=   (-6);
const MP_SIZENS=     (-7);
const MP_SIZENWSE=   (-8);
const MP_SIZEWE=     (-9);
const MP_UP_ARROW=   (-10);
const MP_HOUR_GLASS= (-11);
const MP_BUSY=       (-12);
const MP_SIZEHORZ=   (-13);
const MP_SIZEVERT=   (-14);
const MP_HAND=       (-15);
const MP_NODROP=     (-16);
const MP_SPLITVERT=  (-17);
const MP_SPLITHORZ=  (-18);
const MP_WHATSTHIS=  (-19);

const MP_LISTBOXBUTTONSIZE=     (-118);
const MP_ALLOWCOPY=             (-119);
const MP_ALLOWDROP=             (-120);
const MP_LEFTARROW_DROP_TOP=    (-121);
const MP_LEFTARROW_DROP_BOTTOM= (-122);
const MP_LEFTARROW_DROP_RIGHT=  (-123);
const MP_LEFTARROW_DROP_LEFT=   (-124);
const MP_LEFTARROW=             (-125);
const MP_RIGHTARROW=            (-126);
const MP_MOVETEXT=              (-127);
const MP_MAX=       (MP_MOVETEXT);
// Custom cursor (e.g. user set picture index).
// It is illegal for the user to set this value.
const MP_CUSTOM=    -128;

/* Alignment styles. */
const AL_MASK=            3;     // left,right,center mask
const AL_LEFT=            0;
const AL_RIGHT=           1;
const AL_CENTER=          2;
const AL_VCENTER=         4;
const AL_VCENTERRIGHT=    5;
const AL_CENTERBOTH=      6;
const AL_BOTTOM=         8;
const AL_BOTTOMRIGHT=    9;
const AL_BOTTOMCENTER=   10;

/* Check box style. p_style. */
const PSCH_AUTO2STATE=   0;
const PSCH_AUTO3STATEA=  1;    /* Gray, check, uncheck. */
const PSCH_AUTO3STATEB=  2;    /* Gray, uncheck, check */
/* Combo box style. p_style. */
const PSCBO_EDIT=         0;    /* Standard.  List drops down. */
const PSCBO_LIST_ALWAYS=  1;    /* List is always present. Can edit. */
const PSCBO_NOEDIT=       2;    /* Must select list item to modify text box. */

/* SSTab style */
const PSSSTAB_DEFAULT=        0;
const PSSSTAB_DOCUMENT_TABS=  1;  /* Mac only. Draw tabs using a document-style. Used by File Tabs tool-window. */

/* Scale modes.  Setting the scale mode not support. */
//SM_USER    = 0
const SM_TWIP=      1; // Scaled twips
const SM_RTWIP=     2; // Real twips
const SM_PIXEL=     3;

enum VSystemMetrics {
   VSM_CXFULLSCREEN=0,
   VSM_CYFULLSCREEN,
   VSM_CYSMCAPTION,
   VSM_CXDLGFRAME,
   VSM_CYDLGFRAME,
   VSM_CXBORDER,
   VSM_CYBORDER,
   VSM_CXCTLBORDER,
   VSM_CYCTLBORDER,
   VSM_CXCTL3DFOCUSRECTBORDER,
   VSM_CYCTL3DFOCUSRECTBORDER,
   VSM_CYCAPTION,
   VSM_CXFRAME,
   VSM_CYFRAME,
   VSM_CXSIZE,
   VSM_CYSIZE,
   VSM_CYHSCROLL,
   VSM_CXVSCROLL,
   VSM_CYMENU,

   VSM_TOOLBAR_HANDLE_EXTENT,
};


const IDOK=                0x00000400;
const IDSAVE=              0x00000800;
const IDSAVEALL=           0x00001000;
const IDOPEN=              0x00002000;
const IDYES=               0x00004000;
const IDYESTOALL=          0x00008000;
const IDNO=                0x00010000;
const IDNOTOALL=           0x00020000;
const IDABORT=             0x00040000;
const IDRETRY=             0x00080000;
const IDIGNORE=            0x00100000;
const IDCLOSE=             0x00200000;
const IDCANCEL=            0x00400000;
const IDDISCARD=           0x00800000;
const IDHELP=              0x01000000;
const IDAPPLY=             0x02000000;
const IDRESET=             0x04000000;
const IDRESTOREDEFAULTS=   0x08000000;

const MB_ICONMASK=         0xF0000000;

const MB_OK=               IDOK;
const MB_OKCANCEL=         (IDOK|IDCANCEL);
const MB_ABORTRETRYIGNORE= (IDABORT|IDRETRY|IDIGNORE);
const MB_SAVEDISCARD=      (IDSAVE|IDDISCARD);
const MB_SAVEDISCARDCANCEL= (IDSAVE|IDDISCARD|IDCANCEL);
const MB_APPLYDISCARDCANCEL= (IDAPPLY|IDDISCARD|IDCANCEL);
const MB_YESNOCANCEL=      (IDYES|IDNO|IDCANCEL);
const MB_YESNO=            (IDYES|IDNO);
const MB_RETRYCANCEL=      (IDRETRY|IDCANCEL);
const MB_ICONHAND=         0x10000000;
const MB_ICONQUESTION=     0x20000000;
const MB_ICONEXCLAMATION=  0x40000000;
const MB_ICONINFORMATION=  0x80000000;
const MB_ICONSTOP=         MB_ICONHAND;
const MB_ICONNONE=         MB_ICONMASK;
const MB_ICONDEFAULT=      MB_ICONEXCLAMATION;
//#define MB_DEFBUTTON1       0x00000000   Use new _message_box parameter
//#define MB_DEFBUTTON2       0x00000100   Use new _message_box parameter
//#define MB_DEFBUTTON3       0x00000200   Use new _message_box parameter

//#define MB_SYSTEMMODAL      0x00001000   /* Not supported on UNIX or OS/2*/
//MB_MODAL           =0x00002000  // MB_TASKMODAL
//MB_MODELESS        =MB_MODEMASK

// used by auto-reload dialog
#define IDDIFFFILE 8

/* p_draw_style */
const PSDS_SOLID=            0;
const PSDS_FIRST=            PSDS_SOLID;
const PSDS_DASH=             1;
const PSDS_DOT=              2;
const PSDS_DASHDOT=          3;  // May only be supported on MS Windows
const PSDS_DASHDOTDOT=       4;  // May only be supported on MS Windows
const PSDS_NULL=             5;  // May only be supported on MS Windows
const PSDS_INSIDE_SOLID=     6;
const PSDS_LAST=             PSDS_INSIDE_SOLID;

/* p_draw_mode */
const PSDM_BLACK=            1;
const PSDM_FIRST=            PSDM_BLACK;
const PSDM_NOTMERGEPEN=      2;
const PSDM_MASKNOTPEN=       3;
const PSDM_NOTCOPYPEN=       4;
const PSDM_MASKPENNOT=       5;
const PSDM_NOT=              6;
const PSDM_XORPEN=           7;
const PSDM_NOTMASKPEN=       8;
const PSDM_MASKPEN=          9;
const PSDM_NOTXORPEN=        10;
const PSDM_NOP=              11;
const PSDM_MERGENOTPEN=      12;
const PSDM_COPYPEN=          13;
const PSDM_MERGEPENNOT=      14;
const PSDM_MERGEPEN=         15;
const PSDM_WHITE=            16;
const PSDM_LAST=             PSDM_WHITE;

/* p_fill_style */
const PSFS_SOLID=            0;
const PSFS_FIRST=            PSFS_SOLID;
const PSFS_TRANSPARENT=      1;
const PSFS_LAST=             PSFS_TRANSPARENT;

const _HANDLE_WIDTH=  75;    /* twips width of dialog editor handle. */
const _HANDLE_HEIGHT= 75;    /* twips height of dialog editor handle. */

//#define LB_RE '(^? *)'
#define LB_RE '^?'

const VSCF_VSTEXTINFO=   "SlickEdit Text";
const VSCF_VSCONTROLS=   "SlickEdit Controls";
const VSCF_TEXT=         "text/plain";
const VSCF_UNICODETEXT=  "text/plain";

const DRIVE_NOROOTDIR=  1;
const DRIVE_REMOVABLE=  2;
const DRIVE_FIXED=      3;
const DRIVE_REMOTE=     4;
const DRIVE_CDROM=      5;
const DRIVE_RAMDISK=    6;

//  Arguments to Combo Box ON_CHANGE event.
// These events are generated by macros and are
// not hard wired into the editor
const CHANGE_OTHER= 0;         // Text box value changed.
const CHANGE_CLINE= 1;         // Text box value changed by
                    // changing selected line in list.
const CHANGE_CLINE_NOTVIS= 2;  // Text box value changed by
                    // changing selected line while
                    // list is invisible
const CHANGE_CLINE_NOTVIS2= 3; // Text box value changed by
                    // changing selected line while
                    // list is invisible. Sent to user level 2
                    // inheritance only.

const CHANGE_BUTTON_PRESS=         4; //Treeview with buttons on it

const CHANGE_BUTTON_SIZE=          5; //Treeview with buttons on it
/**
 * @deprecated Use CHANGE_BUTTON_SIZE for immediate changes, to save column 
 *             widths use another on_change event.
 */
const CHANGE_BUTTON_SIZE_RELEASE=  6;
const CHANGE_HIGHLIGHT=            7; // line was highlighted in 
                                      //combo box or list box


//  Arguments to List Box ON_CHANGE event.
const CHANGE_SELECTED= 10;     // User's selection has changed
const CHANGE_PATH= 11;         // Path was changed in a directory
                    // list box
const CHANGE_FILENAME= 12;      // filename was changed in file
                    // list box
const CHANGE_DRIVE= 13;         // Drive changed in drive combo box

const CHANGE_EXPANDED= 14;      // A tree node was expanded
const CHANGE_COLLAPSED= 15;     // A tree node was collapsed
const CHANGE_LEAF_ENTER= 16;    // User pressed enter on leafs tree node
                                // If you want ENTER for nodes and leaves,
                                // define your own ENTER key.

                                // For CHANGE_EXPANDED and CHANGE_COLLAPSED
                                // the on_change function may return a new index
                                // to be activated.  If you do not want to do
                                // this, return -1
const CHANGE_SCROLL= 17;
    /*
    For on_change function with CHANGE_EDIT_OPEN,
    CHANGE_EDIT_CLOSE, and CHANGE_EDIT_QUERY
    reasons:
      arg(1) is reason
      arg(2) is index
      arg(3) is col.  col can be -1 if there are no colums.
      arg(4) is the text.  For CHANGE_EDIT_OPEN, modify the text to be
             what you want to be in the text box.  For CHANGE_EDIT_CLOSE
             ,modify the text to be what you want to go back into the tree
             control.  Changing text has no effect for CHANGE_EDIT_QUERY,
             but it is still provided so that this may be used to help make
             the decision weather or not to allow a window to be created.

      When you get an event with reason CHANGE_EDIT_OPEN, you can
      prevent an edit box from coming up by returning -1.

      When you get an event with reason CHANGE_EDIT_CLOSE, you can
      prevent changes from being made to the edit box from coming up by
      returning -1.

      When you get an event with reason CHANGE_EDIT_QUERY, you can
      prevent an edit box from coming up by returning -1.

      For any of these events, if you delete the node, return  DELETED_ELEMENT_RC.

      The above applies for CHANGE_EDIT_OPEN_COMPLETE, except arg(5) will be the 
      window id of the 

      For CHANGE_EDIT_PROPERTY, if the user returns TREE_EDIT_COLUMN_BIT we
      will automatically edit the column that is OR'd in. 

      example:
         return TREE_EDIT_COLUMN_BIT    // edit column 0
         return TREE_EDIT_COLUMN_BIT|1  // edit column 1
    */
const CHANGE_EDIT_OPEN=  20;    // A textbox is about to be opened
const CHANGE_EDIT_CLOSE= 21;    // A textbox is about to close
const CHANGE_EDIT_QUERY= 22;    // Query whether a textbox can be opened
const CHANGE_EDIT_OPEN_COMPLETE=  23;    // A textbox is open
const CHANGE_EDIT_PROPERTY=       24;
const CHANGE_NODE_BUTTON_PRESS=   25;
const CHANGE_CHECK_TOGGLED=       26;
const CHANGE_SWITCH_TOGGLED=      27;
const CHANGE_SCROLL_MARKER_CLICKED= 28;
const TREE_EDIT_COLUMN_BIT=         (0x40000000);



// Arguments to Spin ON_CHANGE event
const CHANGE_NEW_FOCUS= 20;     // Called before ON_SPIN_UP and ON_SPIN_DOWN
                     // event.  Return '' or window id
                     // of control to get focus.

/** 
 * ON_CHANGE(CHANGE_TABDEACTIVATED, new-index). 
 *
 * <p>
 *
 * The current tab (p_ActiveTab) is being deactivated, and 
 * the new tab at new-index is becoming active. This event 
 * is immediate followed by 
 * ON_CHANGE(CHANGE_TABACTIVATED,new-index). Use p_ActiveTab 
 * to query the old-index. 
 *
 * @appliesTo SSTab
 */
const CHANGE_TABDEACTIVATED = 30;

/** 
 * ON_CHANGE(CHANGE_TABACTIVATED, new-index). 
 *
 * <p> 
 *
 * The tab specified by new-index has become active. This event is 
 * immediate preceded by 
 * ON_CHANGE(CHANGE_TABDEACTIVATED,new-index). 
 *
 * @appliesTo SSTab
 */
const CHANGE_TABACTIVATED = 31;

const CHANGE_CLICKED_ON_HTML_LINK=  32;

/**
 * Obsolete.
 *
 * <p> 
 *
 * ON_CHANGE(CHANGE_TABCLOSE). 
 *
 * <p> 
 *
 * X close button on the grabbar was pressed. 
 * 
 */
//const CHANGE_TABCLOSE = 33;

// CHANGE_AUTO_SHOW sent to tool window form BEFORE it is auto shown
const CHANGE_AUTO_SHOW= 34;

// CHANGE_FLAGS is sent to a tree control when node flags are changed in 
// _TreeSetInfo
const CHANGE_FLAGS=     35;

/** 
 * ON_CHANGE(CHANGE_TAB_DROP_DOWN_CLICK). 
 *
 * <p> 
 *
 * The drop-down list was clicked. 
 *
 * @appliesTo SSTab
 */
const CHANGE_TAB_DROP_DOWN_CLICK = 36;

/** 
 * ON_CHANGE(CHANGE_TABMOVED, from-index, to-index). 
 *
 * <p> 
 *
 * Tab was moved from <code>from-index</code> to 
 * <code>to-index</code>. 
 *
 * <p> 
 *
 * Use this event/reason when you are keeping a parallel array 
 * of items in sync with the tab order. 
 *
 * @appliesTo SSTab
 */
const CHANGE_TABMOVED = 37;

/**
 * ON_CHANGE(CHANGE_TABCLOSED, index).
 *
 * <p>
 *
   Tab found at <code>index</code> was closed.
 *
 * <p>
 *
 * @appliesTo SSTab
 */
const CHANGE_TAB_CLOSE_BUTTON_CLICKED = 38;

/**
 * LBUTTON_DOWN(CHANGE_SPLIT_BUTTON)
 * LBUTTON_UP(CHANGE_SPLIT_BUTTON)
 *
 * <p>
 *
   Split-button part of a PSPIC_SPLIT_PUSH_BUTTON or
   PSPIC_SPLIT_BUTTON was pressed/released.
 *
 * @appliesTo Picture_Box, Image
 */
const CHANGE_SPLIT_BUTTON = 39;
const CHANGE_BUTTON_RCLICK = 40; //Treeview with buttons on it
const CHANGE_DELKEY_2 = 41;
const CHANGE_BOTTOM_REACHED = 42;


// Arguments to Combo Box ON_DROP_DOWN event.
// These events are generated by macros and are
// not hard wired into the editor
const DROP_UP=    0;     // After combo list box is made invisible
const DROP_DOWN=  1;     // Before combo list box is made visible
const DROP_INIT=  2;     // Before retrieve next/previous.  Used to initialize
              // the list box before is used.
const DROP_UP_SELECTED= 3;     // Mouse release while on valid
                    // selection in list box
                    // and list is visible
const DROP_DELETE_ITEM= 4;   // Del key pressed while list visible. Not supported by LIST_ALWAYS

// boolean value (deprecated, use 'true' instead)
#define TRUE VSDEPRECATECONSTANT(1)
// boolean value (deprecated, use 'false' instead)
#define FALSE VSDEPRECATECONSTANT(0)

// Choose directory dialog flags
enum_flags ChooseDirectoryFlags {
   CDN_SHOW_EXPAND_ALIAS,        // show "expand alias" button
   CDN_SHOW_PROCESS_CHDIR,       // show "process chdir" button
   CDN_SHOW_SAVE_SETTINGS,       // show "save settings" button
   CDN_SHOW_RECURSIVE,           // show Recursive checkbox
   CDN_PATH_MUST_EXIST,          // file must exist
   CDN_ALLOW_CREATE_DIR,         // allow create directory
   CDN_CHANGE_DIRECTORY,         // change directory on open
   CDN_NO_SYS_DIR_CHOOSER,       // force it to use _cd_form 
};

// Open file dialog flags
const OFN_ALLOWMULTISELECT=  0x1;  // Allow multiple file selection
                                   // When set, user must process
const OFN_FILEMUSTEXIST=     0x2;  // File(s) selected must exist
const OFN_CHANGEDIR=         0x4;  // Ignored for backward compatibility

const OFN_NOOVERWRITEPROMPT= 0x8;  // Don't prompt user with overwrite exisiting dialog. */
const OFN_SAVEAS=            0x10; // File list box does not select files and;
                                   // user is prompted whether to overwrite an
                                   // existing file.
const OFN_DELAYFILELIST=     0x20; // Display dialog box before displaying
                                   // list.
const OFN_NODELWINDOW=       0x40; // Open file dialog is not deleted
                                   // when user selects cancel. Instead
                                   // window is made invisible.
const OFN_READONLY=          0x80; // Show read only button. Can't be used
                                   // with OFN_READONLY
                                   // See OFN_PREFIXFLAGS flag
const OFN_KEEPOLDFILE=       0x100; // Show keep old name button
                                    // See OFN_PREFIXFLAGS flag
const OFN_PREFIXFLAGS=       0x200; // Prefix result with -r if
                                    // OFN_READONLY flag given and -n if
                                    // OFN_KEEPOLDFILE flag given and -a if
                                    // OFN_APPEND given.
const OFN_SAVEAS_FORMAT=     0x400;
const OFN_SET_LAST_WILDCARDS= 0x800;
#if 0
      #define OFN_KEEPDIR           0x400 // Show keep dir check box
#endif
const OFN_NOCHANGEDIR=        0x1000;  // Dont' show Change dir check box

const OFN_APPEND=            0x2000; // Show append button.
const OFN_NODATASETS=        0x4000; // OS390 ONLY. Don't allow datasets
const OFN_ADD_TO_PROJECT=    0x8000; // Add saved file to project
const OFN_EDIT=			     	0x10000;  // Use as an open dialog, rather than a save

const EDC_OUTPUTINI=       0x1;
const EDC_OUTPUTSTRING=    0x2;
//EDC_OUTPUTBUFFER =0x4
//EDC_OUTPUTFILE   =0x8
const EDC_INPUTINI=        0x10;
const EDC_INPUTSTRING=     0x20;
//EDC_INPUTBUFFER  =0x40
//EDC_INPUTFILE    =0x80

// Selection list dialog flags
const SL_ALLOWMULTISELECT=  0x1;
const SL_NOTOP=             0x2;
const SL_VIEWID=            0x4;   // View always deleted.
const SL_FILENAME=          0x8;
const SL_NOISEARCH=         0x10;
const SL_NODELETELIST=      0x20;  // Can preserve buffer this way
const SL_SELECTCLINE=       0x40;  // Select current line.
const SL_MATCHCASE=         0x80;  // Case sensitive i-search
const SL_INVERT=            0x8000;// Invert button for muli-select
const SL_SELECTALL=         0x100; // Select all button for multi-select
const SL_HELPCALLBACK=      0x200;
const SL_DEFAULTCALLBACK=   0x400; // Call the callback routine when enter
                           // pressed
const SL_COMBO=             0x800; // Display combo box above list box
const SL_MUSTEXIST=         0x1000;
const SL_BUFID=             0x2000;
const SL_DESELECTALL=       0x4000;  // Deselect all before selecting anything
const SL_NORETRIEVEPREV=    0x10000; // Don't retrieve last combo box value
                             // By default, last combo box value
                             // is restored when initial_value not given.
                             // Has no effect if SL_COMBO not given
const SL_COLWIDTH=          0x20000; // Not supported by _sellist_form.
                                     // Computer largest first column text string
                                     // and set up two columns
const SL_SELECTPREFIXMATCH= 0x40000; // Effects SL_COMBO only.
                                     // When typing in the combo box
                                     // and text is a prefix match
                                     // of the text in the list box,
                                     // list box line is selected.
const SL_CLOSEBUTTON=       0x80000;  // Use Close instead of Cancel button
const SL_CHECKLIST=         0x100000; // Override default bitmaps and use
                                      // checkbox bitmaps/behavior

const SL_SIZABLE=           0x200000; // Dialog box is made resizable
const SL_DELETEBUTTON=      0x400000; // Delete button (select_tree only)
const SL_XY_WIDTH_HEIGHT=   0x800000; // Save/restore x, y, width and height
const SL_GET_TREEITEMS=    0x1000000; // Returns entire tree in results
const SL_USE_OVERLAYS=     0x2000000; // Use second set of bitmaps as overlays
const SL_ADDBUTTON=        0x4000000; // Add button (select_tree only)
const SL_GET_ITEMS_RAW=    0x8000000; // Returns results as raw text, no quoting of filenames (select_tree only)
const SL_RESTORE_XY=       0x10000000; // Save/restore x, y position
const SL_RESTORE_HEIGHT=   0x20000000; // Save/restore form height (but not width)
const SL_RESTORE_WIDTH=    0x40000000; // Save/restore form width (but not height)
const SL_RESTORE_XYWH=     0x70800000; // Same effect as SL_XY_WIDTH_HEIGHT

// Selection list default button captions
const SL_BUTTON_CANCEL=      "Cancel:_sellistcancel";
const SL_BUTTON_CLOSE=       "Close:_sellistcancel";
const SL_BUTTON_HELP=        "&Help:_sellisthelp";
const SL_BUTTON_INVERT=      "&Invert:_sellistinvert";
const SL_BUTTON_SELECTALL=   "Select &All:_sellistselect_all";

// Selection list call back events
const SL_ONINIT=       1;   // Dialog being initialized
const SL_ONDEFAULT=    2;   // Enter pressed and SL_DEFAULTCALLBACK specified
const SL_ONLISTKEY=    3;   // List box fall through key
const SL_ONUSERBUTTON= 4;   // User button pressed
const SL_ONSELECT=     5;   // Select item(s) changed
const SL_ONINITFIRST=  6;   // First Dialog initialized callback, before autosizing
const SL_ONDELKEY=     7;   // The del key was pressed inside the list box
const SL_ONCLOSE=      8;   // Dialog is about to be closed
const SL_ONRESIZE=     9;   // Dialog has resized
                            // 
// Selection tree call back events (first 9 events are the selection list events).
const ST_ONLOAD=       10;  // Dialog has loaded and ready to set initial focus.
const ST_BUTTON_PRESS= 11;  // User clicked on column headers of tree for _select_tree

// save() and file() argument 2 flags
const SV_RETURNSTATUS=      0x1;
const SV_OVERWRITE=         0x2;
const SV_POSTMSGBOX=        0x4; /* Required when unsafe to display message box. */
const SV_RETRYSAVE=         0x8;
const SV_NOADDFILEHIST=     0x10;
const SV_QUIET=             0x20;

// _tprint flags
const TPRINT_FORM_FEED_AFTER_LAST_PAGE=  0x1;

// _print() print_flags
const PRINT_LEFT_HEADER=     0;
const PRINT_RIGHT_HEADER=    1;
const PRINT_CENTER_HEADER=   2;
const PRINT_LEFT_FOOTER=     (0<<2);
const PRINT_RIGHT_FOOTER=    (1<<2);
const PRINT_CENTER_FOOTER=   (2<<2);
const PRINT_TWO_UP=          0x010;
const PRINT_COLOR=           0x020;
const PRINT_FONTATTRS=       0x040;
const PRINT_VISIBLEONLY=     0x080;
const PRINT_HEX=             0x100;
const PRINT_BACKGROUND=      0x200;

// _print() call back events
const PRINT_ONINIT=    0;
const PRINT_ONEXIT=    1;
const PRINT_ONPAGE=    2;
// _font_type() flags.

const RASTER_FONTTYPE=      0x001;
const DEVICE_FONTTYPE=      0x002;
const TRUETYPE_FONTTYPE=    0x004;
const FIXED_FONTTYPE=       0x008;
const OUTLINE_FONTTYPE=     0x100;
const KERNING_FONTTYPE=     0x200;

// Font flags
const F_BOLD=   0x1;
const F_ITALIC= 0x2;
const F_STRIKE_THRU=  0x4;
const F_UNDERLINE=    0x8;
const F_PRINTER=      0x200;
const F_INHERIT_STYLE=  0x400;
const F_INHERIT_COLOR_ADD_STYLE= 0x800;
const F_INHERIT_FG_COLOR=        0x1000;
const F_INHERIT_BG_COLOR=        0x2000;
const F_NO_COLOR_BLENDING=       0x8000;
// _choose_font() flags
const CF_SCREENFONTS=   0x00000001;
const CF_PRINTERFONTS=  0x00000002;
const CF_EFFECTS=       0x00000100;
const CF_FIXEDPITCHONLY=   0x00004000;

const TB_RETRIEVE=       0x1;
const TB_RETRIEVE_INIT=  (0x2|TB_RETRIEVE);
const TB_VIEWID_INPUT=   0x4;
const TB_VIEWID_OUTPUT=  0x8;
const TB_QUERY_COMPAT=   0x10;

// Name info flags for form objects
const FF_MODIFIED=        0x1;
const FF_SYSTEM=          0x2;

// _sys_help options
const HELP_CONTEXT=       0x0001;    /* Display topic in ulTopic */
//HELP_QUIT      = 0x0002  /* Terminate help */
const HELP_CONTENTS=      0x0003;
const HELP_HELPONHELP=    0x0004;  /* Display help on using help */
//HELP_SETINDEX  =   0x0005  /* Set current Index for multi index help */
//HELP_SETCONTENTS = 0x0005
//HELP_CONTEXTPOPUP= 0x0008
const HELP_FORCEFILE=     0x0009;    /* Load a help file */
const HELP_KEY=           0x0101;    /* Display topic for keyword in offabData */
//HELP_COMMAND    =  0x0102
const HELP_PARTIALKEY=    0x0105;
//HELP_MULTIKEY   =  0x0201
//HELP_SETWINPOS  =  0x0203
const HELP_INDEX=         0xf001;
const HELP_VALIDATE=       0xf002;
const HELP_TITLE=          0xf003;  //Used vshlp.dll to get windows help file title

// Undo flags
const LINE_DELETES_UNDONE=      1;
const CURSOR_MOVEMENT_UNDONE=   2;
const MARK_CHANGE_UNDONE=       4;
const TEXT_CHANGE_UNDONE=       8;
const LINE_INSERTS_UNDONE=      16;
const MODIFY_FLAG_UNDONE=       32;
const LINE_FLAGS_UNDONE=        64;
const FILE_FORMAT_CHANGE_UNDONE=   128;
const COLOR_CHANGE_UNDONE=          256;
const MARKUP_CHANGE_UNDONE=         512;

const VS_CTL_TEXT_FORECOLOR=  0x80000008;
const VS_CTL_TEXT_BACKCOLOR=  0x80000005;
const VS_CTL_BUTTON_FACE_BACKCOLOR=  0x8000000F;
const VS_CTL_HIGHLIGHT_FORECOLOR=  0x8000000E;
const VS_CTL_HIGHLIGHT_BACKCOLOR=  0x8000000D;
const VS_CTL_GRAY_TEXT_FORECOLOR=  0x80000011;
const VS_CTL_LISTBOX_FORECOLOR=    0x80000020;
const VS_CTL_LISTBOX_BACKCOLOR=    0x80000021;
const VS_CTL_DIALOG_BACKCOLOR=     0x80000022;
const VS_CTL_ACTIVECAPTION_FORECOLOR= 0x80000023;
const VS_CTL_ACTIVECAPTION_BACKCOLOR= 0x80000024;
const VS_CTL_INACTIVECAPTION_FORECOLOR= 0x80000025;
const VS_CTL_INACTIVECAPTION_BACKCOLOR= 0x80000026;
const VS_CTL_LT_BUTTON_FACE_BACKCOLOR= 0x80000028   /* Calculated color */;
const VS_CTL_3DDKSHADOW= 0x80000030;
const VS_CTL_GRADIENTACTIVECAPTION_BACKCOLOR= 0x80000031;
const VS_CTL_GRADIENTINACTIVECAPTION_BACKCOLOR= 0x80000032;
const VS_CTL_LINK_COLOR= 0x80000033;

typeless _argument;      // '' or integer count used by some commands.
                         // Set by argument command.
typeless _arg_complete;  /* Completion functions may set this var to non-zero */
                         /* value to indicate that more typing is necessary */
                         /* Ex. '\macros\' is not a complete file spec. */

bool def_use_word_help_url;
int def_argument_completion_options;
bool def_prompt_unnamed_save_all;
//bool def_prompt_unnamed_save_all_workspace;

int def_inclusive_block_sel;
/**
 * Indicate when last selection was done with mouse or 
 * shift-arrow keys or search. 
 *
 * <dl>
 *    <dt>0</dt><dd>Last selection not a CUA selection.</dd>
 *    <dt>1</dt><dd>Last selection was a CUA selection.</dd>
 *    <dt>2</dt><dd>Last selection was a CUA word-selection.</dd>
 * </dl>
 * 
 */
int _cua_select;

/**
 * Specifies a persistent select style ('P') for some selection functions.
 * Set to '' for a non-persistent select style.
 *
 * @default 'P'
 * @categories Configuration_Variables
 *
 * @see select_line
 * @see select_block
 * @see select_char
 * @see select_code_block
 */
_str def_advanced_select;

/**
 * Directory where auto-save information will be stored.
 * If set to '', it will use an 'autosave' subdirectory under
 * the configuration directory.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_as_directory;

/**
 * Auto-save timer settings.  Consists of three space-delimited values:
 * "inactive time", "absolute time", and "config amount"
 *
 * @default 'm1 m1 0'
 * @categories Configuration_Variables
 */
_str def_as_timer_amounts;

/**
 * Name of the current active color scheme.
 * Consists of scheme name followed by "(modified)" if the
 * colors have been modified since selecting the scheme.
 * Set to "(init)" to indicate to use the default
 * color scheme initially.
 *
 * @default "(init)"
 * @categories Configuration_Variables
 */
_str def_color_scheme;

/**
 * Name of the current active embedded color scheme.
 * Consists of scheme name followed by "(modified)" if the
 * colors have been modified since selecting the scheme.
 * Set to "(init)" to indicate to use the default
 * embedded color scheme initially.
 *
 * @default "(init)"
 * @categories Configuration_Variables
 */
_str def_embedded_color_scheme;

/**
 * Controls how fast the editor or a list box is scrolled when you
 * create a selection and drag the mouse outside of the editor control.
 * Scrolling gets faster as you move the mouse further past edge.
 * Contains scroll speed levels, ordered from slowest to fastest.
 * Each pair is of the form ( timer delay in milliseconds .
 * number of lines to scroll ).
 *
 * @default '30.0 20.3 10.4 10.6'
 * @categories Configuration_Variables
 */
_str def_scroll_speeds;

/**
 * File filters used by File Open and File Save As dialogs.
 * Separate each file filter with a comma.
 * Place file patterns in parentheses.
 * Separate file patterns with a semicolon.
 * The first file filter is used to initialize the file list.
 * <p>
 *
 * @example
 * <pre>
 *    Basic Files (*.bas), All Files (*.*)
 *    C Files (*.cpp;*.cxx;*.c;*.h), All Files (*.*)
 * </pre>
 *
 * @categories Configuration_Variables
 */
_str def_file_types;

/**
 * File filters used by Find and Replace dialogs. Separate each 
 * file filter with a comma. Place file patterns in parentheses.
 * Separate file patterns with a semicolon. The first file 
 * filter is used to initialize the file list. 
 *  
 * This list is automatically updated with uses of the Find 
 * dialog. 
 * <p>
 *
 * @example
 * <pre>
 *    Basic Files (*.bas), All Files (*.*)
 *    C Files (*.cpp;*.cxx;*.c;*.h), All Files (*.*)
 * </pre>
 *
 * @categories Configuration_Variables
 */
_str def_find_file_types;

/**
 * Option for how to display key bindings on menus and tooltips.
 * <ul>
 * <li>'S' -- Return Slick-C&reg; source code event name.
 * <li>'L' -- Return long menu bar event name.
 * <li>'C' -- Return condensed menu bar event name.
 * </ul>
 *
 * @default 'L'
 * @categories Configuration_Variables
 * @see event2name
 */
_str def_keydisp;

/**
 * Name of active emulation keys help item.
 *
 * @default ""
 * @categories Configuration_Variables
*/
_str def_keys;

/**
 * Set to false if the quick start wizard should be allowed. The
 * quick start wizard is not displayed if the user has an
 * existing config.
 *
 * @default true
 */
bool _allow_quick_start_wizard;


/** 
 * When non-zero, writes debugging information out to 
 * SLICKEDITCONFIGVERSION/logs/beautifier_debug.html. 
 *  
 * @default 0 
 * @categories Configuration_Variables 
 */
int def_beautifier_debug;

/**
 * Controls whether the editor inserts lines above ('A') or
 * below ('B') the current line when pasting text.
 * <p>
 *
 * @default "A" (for most emulations)
 * @categories Configuration_Variables
 * @see get
 * @see paste
*/
_str def_line_insert;

/**
 * Default load options used when opening files in the editor.
 * The options consist of a string of command line options
 * supported by the <tt>edit</tt> command.
 * <p>
 *
 * @default '+L -LF +LE -S -E +U:32000 -N +BP';
 * @categories Configuration_Variables
 *
 * @see edit
 */
_str def_load_options;

/**
 * This option controls whether a file is loaded entirely into
 * memory or if it should be partially loaded by block-by-block. 
 *  
 * <p>When true, load partial is enabled accorder to 
 * def_load_partial_ksize; 
 * 
 * @default 1
 * @categories Configuration_Variables
 */
bool def_load_partial;

/**
 * This option controls whether a file is loaded entirely into
 * memory or if it should be partially loaded by block-by-block.
 *  
 * Files >= this size will be partially loaded. Partial loading 
 * must be enabled by the def_load_partial variable. 
 * 
 * @default 8000
 * @categories Configuration_Variables
 */
_str def_load_partial_ksize;

/** 
 * This option contains a space-delimited list of all the 
 * user-loaded macros and shared libraries. 
 *  
 * Slick-C macros must have ".ex" extension. DLL files 
 * must have extension specified if there is one. 
 * Filenames with spaces are in double quotes. 
 * 
 * @default ""
 * @categories Configuration_Variables
 */
_str def_macfiles;


/**
 *  Initial values for variables below are defined in "main.e"
 */
 _str
   _help_file_spec             /* Path to 'slick.doc' */
   ,_error_file          /* Absolute name of error file. */
   ,_grep_buffer         /* Absolute name of multi-file find output buffer. */
   ,_fpos_case           /* 'I' if file system is case insensitive. */
                         /* Otherwise ''. UNIX file system is case sensitive. */
                         // Mac is case insensitive
   ,_macro_ext           /* Macro source code extension with . */
                         /* SLICKEXT envvar may set this. */
   ,_tag_pass            // Number of passes.  May be used by "ext"_proc_search(). */
                         // Initialized to one before first call.
                         // perl.e places several 3 values in this string.
   ,COMPILE_ERROR_FILE  // "$errors.tmp" "vserrors.tmp"
   // Under OS/2 Menu font can be changed by droping configured ICON onto
   // editor.  Record original font and check if it changes.
   ,_origMdiMenuFont
   ;

/**
 * Default save options. Backup overwritten files.
 * 
 * @default "-O"
 * @categories Configuration_Variables 
 *  
 * @see save()
 */
_str def_save_options;
/**
 * Default file extensions to be pre-loaded.
 * 
 * @default ""
 * @categories Configuration_Variables
 */
_str def_preload_ext;
/**
 * Selection style. 
 * <ul>
 * <li>C - selection extends as the cursor moves  
 * <li>E - exclusive
 * <li>N - specifies a non-inclusive selection
 * <li>I - inclusive 
 * </ul> 
 * 
 * @default "E"
 * @categories Configuration_Variables
 */
_str def_select_style;
/**
 * This option determines when selections are deselected.
 * <ul> 
 * <li>D - delete selection before insert
 * <li>N - auto-deselect (i.e. when cursor moves)
 * <li>Y - selections are persistent
 * </ul> 
 * 
 * @default "D"
 * @categories Configuration_Variables
 */
_str def_persistent_select;
/**
 * Specifies word characters used by next word, prev word and searching.
 * 
 * @default "A-Za-z0-9_$"
 * @categories Configuration_Variables 
 *  
 * @see next_word 
 * @see prev_word 
 */
_str def_word_chars;
/**
 * User defined completion equates.
 * 
 * @default ""
 * @categories Configuration_Variables
 */
_str def_user_args;
/**
 * Determines whether prev-word and next-word (C-right & C-left) move to the 
 * beginning or end of the word. 
 * <ul> 
 * <li>(B)eginning of the word
 * <li>(E)nd of the word 
 * </ul> 
 * 
 * @default "E"
 * @categories Configuration_Variables
 *  
 * @see next_word 
 * @see prev_word 
 */
_str def_next_word_style;
/**
 * Help files used by wh,wh2,wh3 commands.
 * 
 * @see wh 
 * @see wh2 
 * @see wh3 
 * @see help 
 *  
 * @deprecated See {@link help()}
 */
_str def_wh;
/**
 * Name of default MDI menu bar
 * 
 * @default "_mdi_menu"
 * @categories Configuration_Variables
 */
_str def_mdi_menu;
/**
 * Current name of MDI menu.
 * 
 * @default  "_mdi_menu"
 * @categories Configuration_Variables
 */
_str _cur_mdi_menu;
/**
 * Multi-file find GUI style option
 * 
 * @default 2
 */
_str def_mffind_style;
/**
 * Name of default button bar
 * 
 * @default ""
 * @categories Configuration_Variables
 */
_str def_mdibb;

/**
 * One file per window.
 * <p>
 * If enabled, each file you open will be allocated in its own window.
 * If disabled, each file will open in the same window.
 * <p>
 *
 * @default true
 * @categories Configuration_Variables
 * @see new
 * @see edit
 * @see quit
 * @see close_window
 */
_str def_one_file;
/**
 * If one file per window is turned off, this controls whether or not
 * close window will attempt to close the current file if it is
 * not modified and there is only <em>one</em> window open.  If disabled,
 * close window will <em>only</em> close the window.
 *
 * @default true
 * @categories Configuration_Variables
 * @see def_one_file
 * @see close_window
 */
bool def_close_window_like_1fpw;

_str _project_name;        // Name of open project.  '' if not project open
_str _project_DebugCallbackName;  //DebugCallbackName for current project or '' if not project open
bool _project_DebugConfig;     //True if current project configuration needs the Debug menu
_str _project_extTagFiles;
_str _project_extExtensions;

/**
 * Controls whether Alt menu hot keys are enabled for shortcut access
 * to the MDI menu.  If !=0, alt+letter invokes menu bar drop-down.
 *
 * @default 1, (0 for Emacs and Brief emulations)
 * @categories Configuration_Variables
 */
_str def_alt_menu;

/**
 * Determines whether text box is CUA style.
 * "0" is false and all other string values are true.
 *
 * @default "" (true)
 * @categories Configuration_Variables
 */
_str def_cua_textbox;

/**
 * Try to exit process buffer when closing editor.
 * "0" is false and all other string values are true.
 *
 * @default "" (true)
 * @categories Configuration_Variables
 * @see safe_exit
 */
_str def_exit_process;

/**
 * Bind open, find, and replace commands (among others) to
 * massively simplified command line prompts
 * "0" is false and all other string values are true.
 * <p>
 *
 * @default 1 (true)
 * @categories Configuration_Variables
 *
 * @see gui_open
 * @see gui_find
 * @see gui_replace
 */
_str def_gui;

/**
 * If enabled, when searching leave the last occurance of search
 * string found selected.
 * <p>
 *
 * @default 1 (true for most emulations)
 * @categories Configuration_Variables
 *
 * @see gui_find
 * @see find
 * @see find_next
 */
_str def_leave_selected;

/**
 * If enabled, preserve Column when going to top or
 * bottom of buffer. 
 *  
 * @default 0 (false, for most emulations)
 * @categories Configuration_Variables
 */
_str def_top_bottom_style;

/** 
 * Indicates whether '?' is used for completion
 * 
 * @default '' (true)
 * @categories Configuration_Variables
 */
_str def_qmark_complete;

_str  // The configuration variables below should have been bool but
      // are not for backward compatibility with VS user configuration files.
      // For these strings "0" is false and all other string values are true.
   def_scursor_style     // boolean string. Shift+<cursor key> style.  0 specifies character selection.
   ,def_prompt           // boolean string. Prompt commands with GET_STRING switch.
   ,def_modal_tab;       // boolean string. If non-zero and text is selected, text is indented

_str _proc_found;         // Name of procedure found by next_proc or prev_proc commands
// Some UNIX text mode printing strings.
_str def_tprint_cheader
   ,def_tprint_cfooter
   /*
   options -->   print_flags,blank_lines_after_header,
                 blank_lines_before_footer,lines_per_page,
                 columns_per_line,linenums_every,
   */
   ,def_tprint_options
   ,def_tprint_lheader,def_tprint_lfooter
   ,def_tprint_rheader,def_tprint_rfooter
   ,def_tprint_command
   ,def_tprint_filter
   ,def_tprint_pscommand;

// Options for tprint command. (Must set variables manually.)
// Old text mode macro variables.

/**
 * Device to send printout to when printing on Unix.
 *
 * @default '/dev/lp0'
 * @categories Configuration_Variables
 */
_str def_tprint_device;


bool def_highlight_matching_parens;   // highlight parens under cursor

/**
 * Exit setting - do they want to shut down SlickEdit when time elapses.
 *
 * @default 0
 * @categories Configuration_Variables
 */
bool def_exit_on_autosave;
/**
 * If enabled, syntax indent on Enter inserts real indent
 * rather than just positioning cursor in virtual space.
 *
 * @default 0
 * @categories Configuration_Variables
 */
bool def_enter_indent;
/**
 * Change directory in editor when changing directory
 * in open and save as dialog boxes.
 *
 * @default OFN_CHANGEDIR;
 * @categories Configuration_Variables
 */
int def_change_dir;

/**
 * If set to 1, use the older Windows XP style open dialog when
 * running on Windows Vista, Windows 7, or later
 * @default 0
 * @categories Configuration_Variables
 */
int def_use_xp_opendialog;

/** 
 * Switch buffers Eclipse-style, with CTRL-PAGEUP and
 * CTRL-PAGEDOWN (SWT events)
 * 
 * Used in plugin only.
 * 
 * @default 1
 * @categories Configuration_Variables
 */
int def_eclipse_switchbuf;

/**
 * If enabled, add a file being saved in save-as dialog box to a
 * current project.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_add_to_project_save_as;

/**
 * Cursor left/right wrap to previous/next line (respectively).
 *
 * @default 0 (in most emulations)
 * @categories Configuration_Variables
 *
 * @see cursor_left
 * @see cursor_right
 */
bool def_cursorwrap;
/**
 * By default, pressing the Backspace key when the previous character
 * is a tab causes the rest of the line to be moved to the previous tab stop.
 * If you are using a mode that has a syntax indent for each level that is
 * different from the Tab settings, do not enable this setting.
 * <p>
 * If you want your Backspace key to delete through tab characters
 * one column at a time, enable this setting.
 * <p>
 *
 * @default 0
 * @categories Configuration_Variables
 */
bool def_hack_tabs;

/**
 * Indicates whether or not to change the cursor between Vim
 * command and insert mode. 
 *  
 * There is an issue with the cursor appearing longer than it 
 * should in UTF8 files on Linux and UNIX system. 
 *  
 * @default true
 * @categories Configuration_Variables
 */
bool def_vim_change_cursor;  
/**
 * If on, and in Vim emulation, ESC during any codehelp or 
 * autocomplete will not only dismiss the dialog, but also 
 * switch to command mode. 
 *  
 * @default false 
 * @categories Configuration_Variables
 */
bool def_vim_esc_codehelp;  
/**
 * If on, and in Vim emulation, there will be a warning prompt 
 * when staying in Ex mode. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
bool def_vim_stay_in_ex_prmpt;  
/**
 * If on, and in Vim emulation, switch to command mode any 
 * buffer switch. 
 *  
 * @default false 
 * @categories Configuration_Variables
 */
bool def_vim_start_in_cmd_mode;
/**
 * Cursor Position is restored after a replace
 * 
 * @default 0
 * @categories Configuration_Variables
 */
bool def_restore_cursor;
/**
 * Cursor stays in straight line when moving up or down.
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_updown_col;
/**
 * After reflow-paragraph command, place cursor on next paragraph
 * 
 * @default false
 * @categories Configuration_Variables
 */
bool def_reflow_next;

/**
 * Set to 'false' for fast brace matching. 
 *  
 * When set to 'true', {@link find_matching_paren()} uses slower paren matching 
 * that searches for and checks all types of parenthesis pairs in the search. 
 * This mode is slower, but more strict.
 * 
 * @default false 
 * @categories Configuration_Variables
 */
bool def_pmatch_style;
/**
 * What to do when typing close paren. 
 * <ul> 
 * <li>0 - MoveCursor
 * <li>1 - Highlight
 * <li>'' - None
 * </ul>
 * 
 * @default 1
 * @categories Configuration_Variables
 */
_str def_pmatch_style2;
/**
 * Maximum distance, in kilobytes, to search forward/backward to find matching paren.
 * 
 * @default 80000
 * @categories Configuration_Variables
 */
int def_pmatch_max_diff_ksize;
/**
 * Maximum number of nesting levels to search for matching paren.
 * 
 * @default 500
 * @categories Configuration_Variables
 */
int def_pmatch_max_level;
/**
 * Turn off paren matching if the buffer is larger this value, measured in 
 * kilobytes.  The default is 1024, which means paren matching will be disabled 
 * for files larger than 1 megabyte.
 * 
 * @default 1024
 * @categories Configuration_Variables
 */
int def_pmatch_max_ksize;

bool def_stay_on_cmdline;
/**
 * Delay inserting of file list in open file
 * dialog until user is done typing filename.
 *
 * @default 1
 * @categories Configuration_Variables
 */
bool def_delay_filelist;
bool def_start_on_cmdline;
bool def_start_on_first;   //When editing 'A B C' start on A

/**
 * If enabled, do not display file list when exiting w/modified buffers.
 *
 * @default 0
 * @categories Configuration_Variables
 * @see safe_exit
 */
bool def_exit_file_list;

/**
 * If enabled, cancel current selection after paste.
 *
 * @default 1 (in most emulations)
 * @categories Configuration_Variables
 * @see copy
 */
bool def_deselect_paste;
/**
 * If enabled, cancel current selection after copy.
 *
 * @default 1 (in most emulations)
 * @categories Configuration_Variables
 * @see copy
 */
bool def_deselect_copy;

/**
 * Controls whether or not when the editor exits, if it will save
 * data about the last editor session: including open files, file positions,
 * clipboards, bookmarks, and window sizes and positions.
 *
 * @default 1
 * @categories Configuration_Variables
 *
 * @see auto_restore
 */
int def_auto_restore;

bool def_pull;             //backspace pulls characters event when in replace mode

/**
 * By default, moving the cursor over a tab character with the
 * Left or Right arrow key causes the cursor to jump across the
 * virtual space. To allow the Left and Right arrow keys to
 * cursor into virtual space of tab characters, disable this
 * option.
 * <p>
 * Also, when positioning the cursor with the mouse, this option
 * also controls whether or not the cursor position is snapped
 * to the nearest real character instead of allowing it to be
 * placed in virtual space.
 * <p>

 * @default 1
 * @categories Configuration_Variables
 *
 * @see cursor_left
 * @see cursor_right
 */
bool def_jmp_on_tab;

/**
 * The line wrap on text option affects whether line wrapping
 * occurs when the left margin is reached or column one is
 * reached for the Left and Backspace key configurations.
 * By default, when the word wrap option is enabled, wrapping
 * occurs when the left margin is reached regardless of the Left
 * or Backspace key configurations. Mark this check box if you
 * want wrapping to occur when column one is reached.

 * @default 1
 * @categories Configuration_Variables
 *
 * @see wordwrap_left
 * @see wordwrap_right
 * @see wordwrap_rubout
 */
bool def_linewrap;

/**
 * When you hit delete at the end of a line, the following line 
 * will be joined to the current line and leading spaces will be 
 * removed.  Set this to false to preserve the leading spaces 
 * when lines are joined in this manner. 
 * 
 * @default true
 * @categories Configuration_Variables
 *
 * @see wordwrap_delete_char 
 * @see def_linewrap 
 */
bool def_join_strips_spaces;

// Open file dialog keep dir check box value.
bool def_keep_dir;

/**
 * If enabled, operate on current word starting at the cursor
 * position instead of the beginning of the word.
 *
 * @default false, true for Emacs
 * @categories Configuration_Variables
 * @see cur_word
 */
bool def_from_cursor;

bool def_unix_expansion;  // Expand ~ and $ like UNIX shells.
bool def_process_tab_output;  // Default build window output to tab in output toolbar

int def_mouse_menu_style;
//bool def_mouse_paste;

enum_flags ChangeDirectoryFlags {
   CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW = 0x1,
   CDFLAG_EXPAND_ALIASES_IN_CD_FORM  = 0x2,
   CDFLAG_NO_SYS_DIR_CHOOSER         = 0x4,
   CDFLAG_CHANGE_DIR_IN_TERMINAL_WINDOWS = 0x8,
};

/**
 * Change directory options.  Bitset of the following:
 * <ul>
 * <li><b>CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW</b> -- Also change directory in build window.
 * <li><b>CDFLAG_EXPAND_ALIASES_IN_CD_FORM </b> -- Expand aliases in the change directory form
 * <li><b>CDFLAG_NO_SYS_DIR_CHOOSER        </b> -- Windows only - defeat windows "Browse for folder" dialog
 * </ul>
 *
 * @default 3
 * @categories Configuration_Variables
 */
int def_cd;

/**
 * Maximium files listed under File menu.
 *
 * @default 9
 * @categories Configuration_Variables
 */
int def_max_filehist;

/**
 * Maximium files listed under File > All Files menu.
 *
 * @default 64
 * @categories Configuration_Variables
 */
int def_max_allfileshist;

/**
 * Maximium files listed under Project menu.
 *
 * @default 9
 * @categories Configuration_Variables
 */
int def_max_workspacehist;

/**
 * Maximium files listed under Winodw menu.
 *
 * @default 9
 * @categories Configuration_Variables
 */
int def_max_windowhist;

/**
 * When set to 'true', display file, window, and project history information 
 * on menus verbosely as "filename full_path_to/filename" (note the actual file 
 * name part is repeated).  When set to 'false', the file history information 
 * is displayed more compactly as "filename full_path_to/"  This makes it possible 
 * to see more of the path without redundantly displaying the filename. 
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_filehist_verbose;

_metadata enum_flags CPPTaggingFlags {
   CTAGS_FLAGS_TAG_PROTOTYPES_WITH_NO_SEMICOLON = 0x01,
   CTAGS_FLAGS_TAG_PROTOTYPES                   = 0x02,
   CTAGS_FLAGS_TAG_PROTOTYPES_WITH_NO_RETURN    = 0x04,
   CTAGS_FLAGS_STOP_ON_BRACE_IN_COLUMN_1        = 0x08,
   CTAGS_FLAGS_IGNORE_STRAY_IDENTIFIERS         = 0x10,
   CTAGS_FLAGS_IGNORE_VCPP_ATTRIBUTES           = 0x20,
   CTAGS_FLAGS_NO_LOCAL_DEFINES                 = 0x40,
   CTAGS_FLAGS_CPP_LOCAL_DEFINES                = 0x40,
   CTAGS_FLAGS_CPP_PROJECT_DEFINES              = 0x80,
   CTAGS_FLAGS_NO_CPP_GLOBAL_DEFINES            = 0x100,
};

/**
 * Bitwise flags that are checked in vsc_list_tags() to fine-tune
 * tagging options.
 * <ul>
 * <li><b>0x1</b>   -- Do NOT skip over function definitions/prototypes
 *                     that do not have a semicolon or open brace
 *                     following the parameter list.  C++ source code
 *                     that uses Microsoft MFC macro definitions are
 *                     one of the reasons a user may want to skip over
 *                     these types of definitions.  Set this option
 *                     when you do not want old C-style function definitions
 *                     skipped.
 * <li><b>0x2</b>   -- Tag C/C++ prototypes.
 * <li><b>0x4</b>   -- Do not skip over old style C/C++ prototypes
 *                     that do not have an explicit return type.
 *                     This should be off in order for local-variable
 *                     search to work properly, otherwise it is very
 *                     difficult to distinguish a function call from
 *                     a prototype.
 * <li><b>0x8</b>   -- Do not break out of parsing a function if we see
 *                     a brace in column 1.  We normally do this as a
 *                     safeguard against parsing past the end of a proc
 *                     when the braces mismatch.
 * <li><b>0x10</b>  -- Ignore stray identifiers that may be preprocessing.
 * <li><b>0x20</b>  -- Ignore Visual C++ bracketted Attributes in C++ code.
 * <li><b>0x40</b>  -- Dynamically expand local #defines within the current file 
 *                     as if they were defined in the C/C++ Preprocessing options. 
 * <li><b>0x80</b>  -- Dynamically expand project #defines from the current 
 *                     project and build configuration
 * <li><b>0x100</b> -- Do not dynamically expand global #defines from the current 
 *                     project and build configuration (def_[lang]_preprocessing_options)
 * </ul>
 *
 * @default 2
 * @categories Configuration_Variables, Tagging_Functions
 */
int def_ctags_flags;

/**
 * If true, use Brief style select word and delete word.
 *
 * @default false, except for Brief emulation
 * @categories Configuration_Variables
 */
bool def_brief_word;

bool def_vcpp_word;         // If true, Visual C++ style next/prev-word, select word and delete word
bool def_subword_nav;

/**
 * Application activation options.
 *
 * <ul>
 * <li><b>ACTAPP_AUTORELOADON</b> --
 *     Automatically reload files that have changed on disk?
 * <li><b>ACTAPP_SAVEALLONLOSTFOCUS</b> --
 *     Save all files when SlickEdit loses focus?
 * <li><b>ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED</b> --
 *     Automatically reload with no prompting unless the buffer is modified?
 * <li><b>ACTAPP_WARNONLYIFBUFFERMODIFIED</b> --
 *     Only warn the user when the file is modified outside SlickEdit?
 * <li><b>ACTAPP_AUTOREADONLY</b> --
 *     Automatically update read-only status of files on disk?
 * </ul>
 *
 * @default ACTAPP_AUTORELOADON|ACTAPP_AUTOREADONLY
 * @categories Configuration_Variables
 */
int def_actapp;

/** 
 * If 1, auto readonly (def_actapp&ACTAPP_AUTOREADONLY) will 
 * perform a fast check (only check attribute on disk, do not 
 * open file).  Only affects Windows (more stringent test is 
 * fast enough in UNIX) 
 *
 * @default true
 * @categories Configuration_Variables
 */
int def_fast_auto_readonly;

/** 
 * Maximum time (in milliseconds) to wait on a file before 
 * timing out and skipping auto reload 
 * @categories Configuration_Variables 
 * @default 1000
 * @deprecated use def_autoreload_timeout_threshold
 */
int def_reload_timeout_threshold;

/** 
 * If set to non-zero, toast popups will show up when a file is 
 * not reloaded because of timeout 
 * @deprecated use def_autoreload_timeout_threshold 
 */
int def_reload_timeout_notifications;

/** 
 * Maximum time (in milliseconds) to wait on a file before 
 * timing out and skipping auto reload 
 * @categories Configuration_Variables 
 * @default 5000
 */
int def_autoreload_timeout_threshold;

/** 
 * If set to non-zero, toast popups will show up when a file is 
 * not reloaded because of timeout 
 */
bool def_autoreload_timeout_notifications;

/**
 * Always initialize Mini-Find/Find and Replace tool window with
 * default search options.
 *
 * @default 0
 * @categories Configuration_Variables
 * @see gui_find
 * @see gui_replace
 */
int def_find_init_defaults;

/**
 * Always close Find and Replace tool window after default action.
 *
 * @default 1
 * @categories Configuration_Variables
 *
 * @see gui_find
 * @see gui_replace
 */
int def_find_close_on_default;

/**
 * Hitting "Preview All..." after a Replace or Replace in Files will 
 * show the modfied file(s) on the left side rather than the right.
 *
 * @default 0
 * @categories Configuration_Variables
 *
 * @see gui_find
 * @see gui_replace
 */
bool def_replace_preview_all_reverse_sides;

/**
 * Highlight current and all matching occurences in current view when using
 * incremental search (i-search).
 *
 * @default 1
 * @categories Configuration_Variables
 *
 * @see i_search
 */
int def_search_incremental_highlight;

/**
 * Amount of idle time in milliseconds to wait before
 * retagging buffers in the background.
 *
 * @default 2000 (2 seconds)
 * @categories Configuration_Variables
 */
int def_buffer_retag;

/**
 * Options for background file tagging.
 * Consists of three parts (space separated):
 * <ol>
 * <li><b>activate interval</b> -- seconds in idle time to wait before
 *                                 starting background tagging
 * <li><b>maximum files to check</b> -- maximum files per iteration
 * <li><b>maximum number to retag</b> -- maximum to retag per iteration
 * <li><b>timeout before retagging</b> -- time in seconds before
 *                                        re-activating background tagging
 * </ol>
 *
 * @default '30 10 3 600';
 * @categories Configuration_Variables
 */
_str def_bgtag_options;

/**
 * Auto-save flags.  Composed of a bitset of AS_*
 *
 * <ul>
 * <li><b>AS_ON</b> -- Auto-save is on
 * <li><b>AS_ASDIR</b> -- Auto-save to different directory
 * <li><b>AS_SAMEFN</b> -- Auto-save to same file
 * <li><b>AS_DIFFERENT_EXT</b> -- Auto-save to Generated extension
 * <li><b>AS_SAVE_WINDOWS</b> -- Auto-save window configuration
 * </ul>
 *
 * @default AS_ASDIR
 * @categories Configuration_Variables
 */
int def_as_flags;

/**
 * Restore option flags.  Composed of a bitset of RF_*.
 * This effects what aspects of the editor are restored
 * when the editor is closed and restarted or when we
 * switch workspaces (in the case of RF_PROJECTFILES).
 *
 * <ul>
 * <li><b>RF_CLIPBOARDS</b> -- Restore clipboards
 * <li><b>RF_CWD</b> -- Restore current working directory
 * <li><b>RF_PROCESS</b> -- Restore Build Window
 * <li><b>RF_PROJECTFILES</b> -- Restore files on a per-workspace basis
 * <li><b>RF_LINEMODIFY</b> -- Restore line modification colors
 * <li><b>RF_NOSELDISP</b> -- If this flag is not set, restore selective display
 * <li><b>RF_CBROWSER_TREE</b> -- Restore expanded nodes in Symbols tool window
 * </ul>
 *
 * @default RF_CWD|RF_PROJECTFILES
 * @categories Configuration_Variables
 */
int def_restore_flags;

/**
 * Delay in milliseconds before scrolling list box
 * when dragging mouse.
 *
 * @default 50
 * @categories Configuration_Variables
 */
int def_init_delay;

int _display_wid;    //  Window id of properties being displayed.

/**
 * Maximum number of clipboards.
 *
 * @default 50 (46 for vi emulation)
 * @categories Configuration_Variables, Clipboard_Functions
 *
 * @see clipboards
 */
int def_clipboards;
int def_read_ahead_lines; // Default lines to read from disk when scrolling.
int def_vcpp_version;     // Version of Visual C++ being used by user
// BITMAP handles
int _pic_drremov;        /* Floppy drive bitmap for drive list. */
int _pic_drfixed;        /* Fixed drive bitmap for drive list. */
int _pic_drremote;       /* Network drive bitmap for drive list. */
int _pic_drcdrom;        /* CD rom drive bitmap for drive list. */
int _pic_cbarrow;        /* Combo box arrow bitmap */
int _pic_cbdots;         /* Combo box dot dot dot bitmap. */
int _pic_cbdis;          /* Combo box disabled arrow. */
int _pic_fldclos;        // Closed file folder bitmap.
int _pic_fldaop;         // Active opened file folder bitmap
int _pic_fldopen;        // Opened file folder bitmap
int _pic_fldclos12;      // Closed file folder bitmap. (same as _pic_fldclos)
int _pic_fldopen12;      // Opened file folder bitmap (same as _pic_fldopen)
int _pic_tt;             // True Type font bitmap
int _pic_printer;        // Printer font bitmap
int _pic_lbplus;         // List box Plus bitmap
int _pic_lbminus;        // List box Minus bitmap
int _pic_lbvs;           // List Box SlickEdit
int _pic_file;           // _file bitmap used by tree view control
int _pic_file_d;         // _file bitmap used by tree view control, looks disabled
int _pic_file12;         // _file bitmap used by tree view control (same as _pic_file)
int _pic_file_d12;       // _file bitmap used by tree view control, looks disabled (12 pixel)
int _pic_fldtags;        // _tags bitmap used by symbol browser and context toolbar
int _pic_fldctags;       // closed _tags bitmap used by symbol browser and context toolbar
int _pic_symbol_public;  // blank symbol overlay (double-wide)
int _pic_symbol_assign;  // symbol assignment overlay (double-wide)
int _pic_symbol_const;   // symbol const usage overlay (double-wide)
int _pic_symbol_nonconst;// symbol non-const usage overlay (double-wide)
int _pic_symbol_unknown; // referenced symbol not found overlay (double-wide)
int _pic_func;           // Fx bitmap for the tree control
int _pic_sm_func;        // smaller version of Fx bitmap for the tree control
int _pic_sm_file;        // smaller version of _file bitmap used by tree view control
int _pic_sm_file_d;      // looks disabled
//Bitmaps for multi-file diff
int _pic_file_match;     // Just a file bitmap, files match, copied so we can have a message
int _pic_filed;          // Red, for different files
int _pic_filed2;         // Blue, different files the user has viewed
int _pic_filem;          // Has a minus sign, file does not exist
int _pic_filep;          // File with a plus.  File only exists in this path
int _pic_fldopenp;       // Folder with a plus.  Direcetory only exists in this path
int _pic_fldopenm;       // Folder with a minus.  Direcetory does not exist
int _pic_search12;       // Search results file bitmap. (12 pixel)
int _pic_build12;        // Build window file bitmap. (12 pixel)
int _pic_treesave;
int _pic_treesave_blank;

int _pic_symbol;        // Just a file bitmap, symbols match, copied so we can have a message
int _pic_symbold;       // Red file for different symbols
int _pic_symbold2;      // Blue, different symbol the user has viewed
int _pic_symbolm;       // Has a minus sign, symbol does not exist
int _pic_symbolp;       // File with a plus.  Symbol only exists in this path

int _pic_symbolmoved;      // Bitmap for moved functions


//New Project toobar bitmaps for files under SCC
int _pic_vc_co_user_w;           // File under version control checked out by user, writable
int _pic_vc_co_user_r;           // File under version control checked out by user, read-only
int _pic_vc_co_other_m_w;        // File under version control checked out by other user multiple, writable
int _pic_vc_co_other_m_r;        // File under version control checked out by other user multiple, read-only
int _pic_vc_co_other_x_w;        // File under version control checked out by other user exclusive, writable
int _pic_vc_co_other_x_r;        // File under version control checked out by other user exclusive, read-only
int _pic_vc_available_w;         // File under version control not checked writable
int _pic_vc_available_r;         // File under version control not checked read-only
int _pic_doc_d;                  // File disabled after cut
int _pic_doc_w;                  // File NOT under version control writable
int _pic_doc_r;                  // File NOT under version control read-only
int _pic_doc_ant;                // File is an ant XML build file
int _pic_tfldclos;               // "Tall" closed folder to match the new file bitmaps
int _pic_tfldclosdisabled;       // _pic_tfldclos disabled
int _pic_tfldopen;               // "Tall" open folder to match the new file bitmaps
int _pic_tfldopendisabled;       // _pic_tfldopen disabled

int _pic_tpkgclos;               // "Tall" closed package to match the new file bitmaps

int _pic_tproject;               // "Tall" _project bitmap used by project toolbar
int _pic_project;                // Project bitmap for project toolbar
int _pic_project2;               // (for backwards compatibility, identical to _pic_project)
int _pic_workspace;              // New "root" bitmap for project toolbar
int _pic_project_dependency;     // Project bitmap for project toolbar dependencies
int _pic_treecb_blank;           // Blank placeholder

// These bitmaps are loaded by cbrowser.e, but only stored in a static hashtable
int _pic_xml_tag;                // xml element picture
int _pic_xml_taguse;             // xml element instance picture
int _pic_xml_attr;               // xml attribute picture
int _pic_xml_target;             // ant target picture

// Bitmaps for OS/390 job utilities.
int _pic_job;                    // job
int _pic_jobdd;                  // job DD

// Bitmap for auto complete
int _pic_light_bulb;
int _pic_syntax;
int _pic_alias;
int _pic_surround_alias;
int _pic_keyword;
int _pic_complete_prev;
int _pic_complete_next;

// Bitmap for diff
int _pic_merge_left;
int _pic_merge_right;

// Bitmaps for symbol references and search results
int _pic_editor_reference;
int _pic_editor_ref_assign;
int _pic_editor_ref_const;
int _pic_editor_ref_nonconst;
int _pic_editor_ref_unknown;
int _pic_editor_search;

// Bitmap for dynamic surround
int _pic_surround;

// These bitmaps are new, but do not need to be cvs specific
int _pic_branch;
int _pic_file_old;
int _pic_file_mod;
int _pic_file_mod_prop;
int _pic_file_old_mod;

// These bitmaps borrow from the cvs bitmaps, but need new captions specific to
// handling files that have been changed or deleted on disk while open. 
int _pic_file_del;
int _pic_file_lock;
int _pic_file_mod2;

// These bitmaps are just for cvs
int _pic_cvs_file;
int _pic_cvs_file_qm;
int _pic_cvs_fld_qm;
int _pic_cvs_file_obsolete;
int _pic_cvs_file_new;
int _pic_cvs_filem;
int _pic_cvs_filem_mod;
int _pic_cvs_filep;
int _pic_cvs_fld_date;
int _pic_cvs_fld_mod;
int _pic_cvs_fld_mod_date;
int _pic_cvs_fld_m;
int _pic_cvs_fld_p;
int _pic_cvs_file_error;
int _pic_cvs_fld_error;
int _pic_cvs_file_conflict;
int _pic_cvs_file_conflict_updated;
int _pic_cvs_file_conflict_local_added;
int _pic_cvs_file_conflict_local_deleted;
int _pic_cvs_file_copied;
int _pic_cvs_file_not_merged;
int _pic_cvs_module;
int _pic_vc_user_bitmap;
int _pic_vc_label_bitmap;
int _pic_vc_floatingdate_bitmap;
int _pic_linked_bitmap;
int _pic_del_linked_bitmap;
int _pic_diff_code_bitmap;
int _pic_del_diff_code_bitmap;
int _pic_diff_doc_bitmap;
int _pic_del_diff_doc_bitmap;
int _pic_diff_path_up;
int _pic_diff_path_down;
int _pic_diff_all_symbols;
int _pic_diff_one_symbol;
int _pic_file_reload_overlay;
int _pic_file_date_overlay;
int _pic_file_mod_overlay;
int _pic_file_checkout_overlay;
int _pic_file_unkown_overlay;
int _pic_file_deleted_overlay;
int _pic_file_add_overlay;
int _pic_file_conflict_overlay;
int _pic_file_copied_overlay;
int _pic_file_not_merged_overlay;
int _pic_file_locked_overlay;

#define USE_CVS_ANIMATION_PICS 0
#if USE_CVS_ANIMATION_PICS
int _cvs_animation_pics[];
const CVS_STALL_PICTURE_PREFIX= '_cvstx';
#endif

// These bitmaps are just for unit testing
int _pic_ut_method;
int _pic_ut_class;
int _pic_ut_package;
int _pic_ut_suite;
int _pic_ut_error;
int _pic_ut_failure;
int _pic_ut_information;
int _pic_ut_notrun;
int _pic_ut_runs;
int _pic_ut_passed;
int _pic_ut_overlay_error;
int _pic_ut_overlay_passed;
int _pic_ut_overlay_failure;
int _pic_ut_overlay_notrun;

// Bitmaps for tool window panel title bar captions
int _pic_xclose_mono;
int _pic_pinin_mono;
int _pic_pinout_mono;

// bitmaps for enhanced open tool window
int _pic_otb_cd_up;
int _pic_otb_file_proj;
int _pic_otb_file_wksp;
int _pic_otb_file_hist;
int _pic_otb_overlay_open;
int _pic_otb_network;
int _pic_otb_computer;
int _pic_otb_favorites;
int _pic_otb_server;
int _pic_otb_share;
int _pic_otb_cdrom;
int _pic_otb_remote;
int _pic_otb_floppy;
int _pic_otb_fixed;

//bitmaps for enhanced backup History tool window
int _pic_bh_cvs_commit;
int _pic_bh_cvs_update;
int _pic_bh_project_tag;
int _pic_bh_workspace_tag;

/** 
 * The maximum number of entries to be stored in filepos.slk for keeping 
 * track of the cursor positions, certain user-selected formatting 
 * options and language mode.  The size of this file is limited for 
 * performance reasons. 
 *
 * @default 1000
 * @categories Configuration_Variables
 */
int def_max_filepos;
int _default_keys;               /* Index of default-keys key table. */

/**
 * Compile flags, bitset of the following:
 * <ul>
 * <li><b>COMPILEFLAG_CLEARPROCESSBUFFER</b> -- clear build window
 * <li><b>COMPILEFLAG_CDB4COMPILE</b> -- change directory before compile
 * </ul>
 *
 * @default COMPILEFLAG_CDB4COMPILE;
 * @categories Configuration_Variables
 */
int def_compile_flags;
const COMPILEFLAG_CLEARPROCESSBUFFER= 1;
const COMPILEFLAG_CDB4COMPILE= 0x2;

_str def_save_on_compile;
/**
 * Maximum file name length for recent file history on the File
 * menu and Project menu.

 * @default 80
 * @categories Configuration_Variables
 *
 */
int def_max_fhlen;        // Maximum length of filenames under menus
/**
 * Determines whether <buf_id> is append to all buffers listed
 * in the Buffers list of the Files Tool window.
 *
 * @default 80
 * @categories Configuration_Variables
 *
 */
bool def_display_buffer_id; 
bool _no_mdi_bind_all;  // When non-zero, menu_mdi_bind_all call is
                           // ignored.

/**
 * Boolean which indicates whether error
 * processing commands should try to look
 * for bufname.err files.
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_err;

int def_mfsearch_init_flags; // Search init flags.

/**
 * Exit options.  Bitset of EXIT_*
 * <ul>
 * <li><b>EXIT_CONFIG_ALWAYS </b> -- always save configuration
 * <li><b>EXIT_CONFIG_PROMPT </b> -- always prompt to save configuration
 * <li><b>EXIT_CONFIRM       </b> -- confirm exit before closing editor
 * <li><b>SAVE_CONFIG_IMMEDIATELY</b> -- save configuration changes immediately 
 *                                       instead of waiting for exit.
 * <li><b>SAVE_CONFIG_IMMEDIATELY_SHARE_CONFIG</b> -- save configuration changes immediately 
 *       instead of waiting for exit. Support multiple instances sharing the same configuration.
 * </ul>
 *
 * @default EXIT_CONFIG_ALWAYS
 * @categories Configuration_Variables
 * @see safe_exit
 */
int def_exit_flags;
int def_re_search2;   // Set to VSSEARCHFLAG_RE or VSSEARCHFLAG_PERLRE

/**
 * When on, text selected with the mouse is copied to the clipboard.
 *
 * @default 'true' on Unix, 'false' otherwise
 * @categories Configuration_Variables
 *
 * @see _autoclipboard
 * @see mou_paste
 */
bool def_autoclipboard;

bool _in_quit;   // In quit command
bool _in_close_all;       // In close_all function
bool _in_project_close;   // In workspace_close_project function
bool _in_workspace_close; // In workspace-close command
bool _in_exit_list;
bool _in_help;            // prompt not reentrant.
int def_max_autosave_ksize;  //Largest file in K to autosave

/**
 * Enable drag and drop of text within the editor?
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_dragdrop;

/**
 * COBOL copy book path.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_cobol_copy_path;

/**
 * COBOL copy book file extensions
 *  
 * @default ". .cpy .cbl .cob .cobol"
 * @categories Configuration_Variables
 */
_str def_cobol_copy_extensions;

/**
 * ASM390 macro path.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_asm390_macro_path;

/**
 * ASM390 macro file extensions 
 *  
 * @default ". .asm .asm390 .inc .maclib .mlc .mac"
 * @categories Configuration_Variables
 */
_str def_asm390_macro_extensions;

/**
 * PL/I include path.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_pl1_include_path;

/**
 * List of modules loaded via oemaddons.e.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_oemaddons_modules;

/**
 * Maximum number of items to insert when refreshing open
 * categories in the symbol browser.
 *
 * @default CB_LOW_WATER_MARK=2000
 * @categories Configuration_Variables
 */
int def_cbrowser_low_refresh;
/**
 * Maximum number of items to insert when expanding nodes in the symbol
 * browser without prompting for confirmation.
 *
 * @default CB_HIGH_WATER_MARK=4000
 * @categories Configuration_Variables
 */
int def_cbrowser_high_refresh;
/**
 * Maximum number of items to insert when expanding nodes in the symbol
 * browser without prompting twice.
 *
 * @default CB_FLOOD_WATER_MARK=16000
 * @categories Configuration_Variables
 */
int def_cbrowser_flood_refresh;

/**
 * Maximum number of symbol references to find
 * before stopping search.
 *
 * @default CB_MAX_REFERENCES=1024
 * @categories Configuration_Variables
 *
 * @see push_ref
 * @see find_refs
 */
int def_cb_max_references;

_str def_refactor_active_config;

_str def_active_java_config;

/**
 * Keeps track of the different things that can be inferred with 
 * adaptive formatting. 
 */
_metadata enum_flags AdaptiveFormattingFlags {
   AFF_BEGIN_END_STYLE,                //   0x1
   AFF_INDENT_WITH_TABS,               //   0x2
   AFF_SYNTAX_INDENT,                  //   0x4
   AFF_TABS,                           //   0x8
   AFF_NO_SPACE_BEFORE_PAREN,          //  0x10
   AFF_PAD_PARENS,                     //  0x20
   AFF_INDENT_CASE,                    //  0x40
   AFF_KEYWORD_CASING,                 //  0x80
   AFF_TAG_CASING,                     // 0x100
   AFF_ATTRIBUTE_CASING,               // 0x200
   AFF_VALUE_CASING,                   // 0x400
   AFF_HEX_VALUE_CASING,               // 0x800
};

/**
 * Default adaptive formatting flags for a buffer.  See 
 * p_adaptive_formatting_flags. 
 *  
 * @default 0 
 * @categories Configuration_Variables
 */
int def_adaptive_formatting_flags;

/**
 * Whether we warn the user that adaptive formatting 
 * has occurred. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
bool def_warn_adaptive_formatting;

/**
 * Whether adaptive formatting is on by default. 
 * Adaptive Formatting is controlled individually by
 * language def-vars.  However, if no language 
 * def-var exists, we consult this value. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
bool def_adaptive_formatting_on;

/**
 * Array of booleans corresponding to tag types and indicating
 * if the type should be filtered out (1=allow; 0=disallow).
 *
 * @default 1,1,1, ...
 * @categories Configuration_Variables
 */
int def_cb_filter_by_types[];

typeless
   _param1          //Modal Dialog Box Result Parameter 1
   ,_param2         //Modal Dialog Box Result Parameter 2
   ,_param3         //Modal Dialog Box Result Parameter 3
   ,_param4         //Modal Dialog Box Result Parameter 4
   ,_param5         //Modal Dialog Box Result Parameter 5
   ,_param6         //Modal Dialog Box Result Parameter 6
   ,_param7         //Modal Dialog Box Result Parameter 7
   ,_param8         //Modal Dialog Box Result Parameter 8
   ,_param9         //Modal Dialog Box Result Parameter 9
   ,_param10        //Modal Dialog Box Result Parameter 10
   ,_param11        //Modal Dialog Box Result Parameter 11
   ;

const VCF_AUTO_CHECKOUT=   0x1;  // This flag must not overlap with EDIT_??? flag
const VCF_EXIT_CHECKIN=    0x2;
const VCF_SET_READ_ONLY=   0x4;
const VCF_PROMPT_TO_ADD_NEW_FILES=         0x8;
const VCF_PROMPT_TO_REMOVE_DELETED_FILES= 0x10;
const EDIT_RESTOREPOS=     0x4;
const EDIT_NOADDHIST=      0x8;
const EDIT_NOSETFOCUS=     0x10;
const EDIT_NOUNICONIZE=    0x20;
const EDIT_NOWARNINGS=     0x40;
const EDIT_NOEXITSCROLL=   0x80;
const EDIT_SMARTOPEN=      0x100;
const EDIT_CHECK_LINE_ENDINGS=0x200;
const EDIT_DEFAULT_FLAGS=  (VCF_AUTO_CHECKOUT|EDIT_RESTOREPOS|EDIT_CHECK_LINE_ENDINGS);

const VPM_LEFTBUTTON=   0x0000;
const VPM_RIGHTBUTTON=  0x0002;
const VPM_LEFTALIGN=    0x0000;
const VPM_CENTERALIGN=  0x0004;
const VPM_RIGHTALIGN=   0x0008;

const SC_SIZE=         0xF000;
const SC_MOVE=         0xF010;
const SC_MINIMIZE=     0xF020;
const SC_MAXIMIZE=     0xF030;
const SC_NEXTWINDOW=   0xF040;
const SC_PREVWINDOW=   0xF050;
const SC_CLOSE=        0xF060;
const SC_RESTORE=      0xF120;


// Flags for _lineflags() function
const VSLF_EMBEDDED_LANGUAGE_MASK= 0x7C00;

const EMBEDDEDLANGUAGEMASK_LF= VSLF_EMBEDDED_LANGUAGE_MASK;

// Mask multi-line comments, strings, and embedded languages
const VSLF_LEXER_STATE_INFO= 0x7fff;


// Mask multi-line comments, strings
const VSLF_COMMENT_INFO_MASK= 0x3ff;

const VSLF_MLCOMMENTINDEX=   0x3f0;   //Indicates which multi-line comment.
const VSLF_MLCOMMENTLEVEL=   0x0F;   //Indicates multi-line comment nest level

const VSLF_CURLINEBITMAP=  0x00008000;
const VSLF_MODIFY=         0x00010000;
const VSLF_INSERTED_LINE=  0x00020000;
const VSLF_HIDDEN=         0x00040000;
const VSLF_MINUSBITMAP=    0x00080000;
const VSLF_PLUSBITMAP=     0x00100000;
const VSLF_NEXTLEVEL=      0x00200000;
const VSLF_LEVEL=          0X07E00000;   // 6-bits
const VSLF_NOSAVE=         0x08000000;   //Display this line in no save color
const VSLF_VIMARK=         0x10000000;   //Used by VImacro to mark lines
const VSLF_READONLY=       0x20000000;
const VSLF_EOL_MISSING=    0x40000000;

const VSLF_LINEFLAGSMASK=     0x7FFFFFFF;

#define _LevelIndex(bl_flags)  (((bl_flags) & VSLF_LEVEL)>>21)
#define _Index2Level(level)   ((level)<<21)

const MLCOMMENTLEVEL_LF=   VSLF_MLCOMMENTLEVEL;
const LINEFLAGSMASK_LF=  VSLF_LINEFLAGSMASK;

const CURLINEBITMAP_LF=  VSLF_CURLINEBITMAP;
const MODIFY_LF=         VSLF_MODIFY;
const INSERTED_LINE_LF=  VSLF_INSERTED_LINE;
const HIDDEN_LF=         VSLF_HIDDEN;
const MINUSBITMAP_LF=    VSLF_MINUSBITMAP;
const PLUSBITMAP_LF=     VSLF_PLUSBITMAP;
const NEXTLEVEL_LF=      VSLF_NEXTLEVEL;
const LEVEL_LF=          VSLF_LEVEL;
const NOSAVE_LF=         VSLF_NOSAVE;
const VIMARK_LF=         VSLF_VIMARK;
const EOL_MISSING_LF=    VSLF_EOL_MISSING;

// p_MouseActivate property values
// Determines what happens when user clicks on edit window
const MA_DEFAULT=          0;
const MA_ACTIVATE=         1;
const MA_ACTIVATEANDEAT=   2;
const MA_NOACTIVATE=       3;
const MA_NOACTIVATEANDEAT= 4;

const VF_FREE=     0;   // Variable is on free list
               // If you get this, you screwed up with pointers.
const VF_LSTR=     2;
const VF_INT=      3;
const VF_ARRAY=    4;
const VF_HASHTAB=  5;
const VF_PTR=      7;
const VF_EMPTY=    8;
const VF_FUNPTR=   9;
const VF_OBJECT=  10; // class instance
const VF_WID=     11; // window id
const VF_INT64=   12; // 64-bit integer (Slick-C long)
const VF_INTERNAL=13; // internal string representation (substituted with VF_LSTR, _varformat() will never return this value)
const VF_DOUBLE=  14; // high-precision integer or floating point (Slick-C double)
#define VF_IS_STRUCT(obj)   (obj._varformat()==VF_OBJECT || obj._varformat()==VF_ARRAY)
#define VF_IS_INT(obj)   (obj._varformat()==VF_INT || obj._varformat()==VF_WID || obj._varformat()==VF_INT64)

/**
 * If disabled, do not generate source files (vusrdefs.e, vusrobjs.e, etc)
 * when saving the configuration.  Typically non-zero, advanced users may
 * never want source files for configuration.
 *
 * @default true
 * @categories Configuration_Variables
 *
 * @see save_config
 */
bool def_cfgfiles;

int _config_modify;   /* Initialized by stdcmds.e. */
                      /* Non-zero if user configuration has been modified.*/
// _config_modify flags
const CFGMODIFY_ALLCFGFILES=  0x001; // For backward compatibility.
                              // New macros should use the constants below.
const CFGMODIFY_DEFVAR=    0x002;  // Set macro variable with prefix "def_"
const CFGMODIFY_DEFDATA=   0x004;  // Set symbol with prefix "def_";
const CFGMODIFY_OPTION=    0x008;  // color, scroll style, insert state or
                           // any option stored in user.cfg.xml
const CFGMODIFY_RESOURCE=     0x010;  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
const CFGMODIFY_SYSRESOURCE=  0x020;  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
const CFGMODIFY_LOADMACRO=  0x040;  // vusermacs is screened out of this.
                            // Must write state file if user load
const CFGMODIFY_LOADDLL=    0x080;  // Must write state file if user loads
                            // a DLL.
const CFGMODIFY_KEYS=       0x100;  // Modify keys
const CFGMODIFY_USERMACS=   0x200;  // vusrmacs was loaded.
const CFGMODIFY_MUSTSAVESTATE=  (CFGMODIFY_LOADMACRO|CFGMODIFY_LOADDLL);
const CFGMODIFY_DELRESOURCE=  0x400; // Sometimes must write state file
const CFGMODIFY_MUSTSAVESTATE_MASK=  (CFGMODIFY_MUSTSAVESTATE|CFGMODIFY_RESOURCE|CFGMODIFY_SYSRESOURCE|CFGMODIFY_USERMACS|CFGMODIFY_DELRESOURCE|CFGMODIFY_KEYS);
                             // when resource is deleted.
                             // This should be used with
                             // CFGMODIFY_RESOURCE or
                             // CFGMODIFY_SYSRESOURCE

// Some _default_option() constants
// VSOPTION_APIFLAGS
_metadata enum_flags VSAPIFLAGS {
   VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS                 = 0x1,
   VSAPIFLAG_TOOLBAR_DOCKING                          = 0x2,
   VSAPIFLAG_MDI_MENUS                                = 0x4,
   VSAPIFLAG_MDI_WINDOW                               = 0x8,
   VSAPIFLAG_CONFIGURABLE_CMDLINE_COLOR               = 0x10,
   VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT                = 0x20,
   VSAPIFLAG_CONFIGURABLE_STATUS_COLOR                = 0x40,
   VSAPIFLAG_CONFIGURABLE_STATUS_FONT                 = 0x80,
   VSAPIFLAG_CONFIGURABLE_ALT_MENU_HOTKEYS            = 0x100,
   VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW         = 0x200,
   VSAPIFLAG_CONFIGURABLE_VCPP_SETUP                  = 0x400,
   /* reserved                                                0x800, */
   VSAPIFLAG_ALLOW_DIALOG_EDITING                     = 0x1000,
   VSAPIFLAG_ALLOW_PROJECT_SUPPORT                    = 0x2000,
   VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS          = VSAPIFLAG_ALLOW_PROJECT_SUPPORT,
   VSAPIFLAG_SAVERESTORE_CWD                          = 0x4000,
   VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_FILENAME       = 0x8000,
   VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_DOCUMENTNAME   = 0x10000,
   // The OEM kit is being used as an eclipse plug-in        
   VSAPIFLAG_ECLIPSE_PLUGIN                           = 0x400000,
   VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW        = 0x800000,
   VSAPIFLAG_ALLOW_TILED_WINDOWING                    = 0x1000000,
   //const VSAPIFLAG_ALLOW_JGUI_SUPPORT                       = 0x2000000,
   VSAPIFLAG_VISUALSTUDIO_PLUGIN                      = 0x4000000,
   /* reserved                                                0x8000000, */
   /* reserved                                                0x10000000, */
   VSAPIFLAG_MDI_TABGROUPS                            = 0x20000000,
   VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT          = 0x40000000,
};

_metadata const VSOPTION_WARNING_ARRAY_SIZE               = 1;
_metadata const VSOPTION_WARNING_STRING_LENGTH            = 2;
_metadata const VSOPTION_VERTICAL_LINE_COL                = 3;
_metadata const VSOPTION_WEAK_ERRORS                      = 4;
_metadata const VSOPTION_AUTO_ZOOM_SETTING                = 5;
_metadata const VSOPTION_MAXIMIZE_FIRST_MDICHILD          = VSOPTION_AUTO_ZOOM_SETTING;
_metadata const VSOPTION_MAXTABCOL                        = 6;
_metadata const VSOPTION_CURSOR_BLINK                     = 7;
_metadata const VSOPTION_DISPLAY_TEMP_CURSOR              = 8;
_metadata const VSOPTION_LEFT_MARGIN                      = 9;
_metadata const VSOPTION_DISPLAY_TOP_OF_FILE              = 10;
_metadata const VSOPTION_HORIZONTAL_SCROLL_BAR            = 11;
_metadata const VSOPTION_VERTICAL_SCROLL_BAR              = 12;
_metadata const VSOPTION_HIDE_MOUSE                       = 13;
_metadata const VSOPTION_ALT_ACTIVATES_MENU               = 14;
_metadata const VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE     = 15;
_metadata const VSOPTION_MAX_MENU_FILENAME_LEN            = 16;
_metadata const VSOPTION_PROTECT_READONLY_MODE            = 17;
_metadata const VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE     = 18;
_metadata const VSOPTION_ENABLE_FONT_FLAGS                = 19;
_metadata const VSOPTION_APIFLAGS                         = 20;
_metadata const VSOPTION_HAVECMDLINE                      = 21;
_metadata const VSOPTION_QUIET                            = 22;
_metadata const VSOPTION_SHOWTOOLTIPS                     = 23;
_metadata const VSOPTION_TOOLTIPDELAY                     = 24;
_metadata const VSOPTION_HAVEMESSAGELINE                  = 25;
_metadata const VSOPTION_HAVEGETMESSAGELINE               = 26;
_metadata const VSOPTION_MACRO_SOURCE_LEVEL               = 27;
_metadata const VSOPTION_VSAPI_SOURCE_LEVEL               = 28;
_metadata const VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES   = 29;
//#define VSOPTION_EMBEDDED              30   // Use new p_embedded property
_metadata const VSOPTION_DISPLAYVERSIONMESSAGE            = 31;
_metadata const VSOPTION_CXDRAGMIN                        = 32;
_metadata const VSOPTION_CYDRAGMIN                        = 33;
_metadata const VSOPTION_DRAGDELAY                        = 34;
_metadata const VSOPTION_MDI_SHOW_WINDOW_FLAGS            = 35;   //4:26pm 4/20/1998
                                                         //Dan added for to support hiding mdi
                                                         //on startup
_metadata const VSOPTION_SEARCHDEFAULTFLAGS               = 36;
_metadata const VSOPTION_MAX_STACK_DUMP_LINE_LENGTH       = 37;
_metadata const VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES = 38;
_metadata const VSOPTION_NEXTWINDOWSTYLE                  = 39;
_metadata const VSOPTION_CODEHELP_FLAGS                   = 40;
                                                   
_metadata const VSOPTION_LINE_NUMBERS_LEN                 = 41;
_metadata const VSOPTION_LCREADWRITE                      = 42;  /* non-zero want prefix area */
_metadata const VSOPTION_LCREADONLY                       = 43;  /* non-zero want prefix area */
_metadata const VSOPTION_LCMAXNOFLINECOMMANDS             = 44;
_metadata const VSOPTION_RIGHT_CONTROL_IS_ENTER           = 45; /* obsolete */
_metadata const VSOPTION_DOUBLE_CLICK_TIME                = 46;
_metadata const VSOPTION_LCNOCOLON                        = 47;
_metadata const VSOPTION_PACKFLAGS1                       = 48;
   const VSPACKFLAG1_STD=(0x1);
   const VSPACKFLAG1_COB=(0x2);
   const VSPACKFLAG1_PLI=(0x4);
   const VSPACKFLAG1_ASM=(0x8);
   const VSPACKFLAG1_CICS=(0x10);
   const VSPACKFLAG1_C=   (0x20);
   const VSPACKFLAG1_JAVA= (0x40);
   const VSPACKFLAG1_PKGA= (VSPACKFLAG1_STD|VSPACKFLAG1_COB|VSPACKFLAG1_PLI|VSPACKFLAG1_ASM);
_metadata const VSOPTION_PACKFLAGS2                       = 49;
_metadata const VSOPTION_UTF8_SUPPORT                     = 50;
_metadata const VSOPTION_UNICODE_CALLS_AVAILABLE          = 51;
_metadata const VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS     = 52;
_metadata const VSOPTION_JAWS_MODE                        = 53;
_metadata const VSOPTION_JGUI_SOCKET                      = 54;
_metadata const VSOPTION_SHOW_SPLASH                      = 55;  /* 1=Show the splash screen on startup */
_metadata const VSOPTION_FORCE_WRAP_LINE_LEN              = 56;
_metadata const VSOPTION_APPLICATION_CAPTION_FLAGS        = 57;
_metadata const VSOPTION_IPVERSION_SUPPORTED              = 58;
_metadata enum VSIPVersion {
   VSIPVERSION_ALL = 0,
   VSIPVERSION_4 = 1,
   VSIPVERSION_6 = 2,
};
_metadata const VSOPTION_NO_BEEP                          = 59;
_metadata const VSOPTION_NEW_WINDOW_WIDTH                 = 60;
_metadata const VSOPTION_NEW_WINDOW_HEIGHT                = 61;
_metadata const VSOPTION_USE_CTRL_SPACE_FOR_IME           = 62;
// Do not write any files into the
// configuration files.
// This option is needed for creating a licensing file
// during the installation process which may have
// administrator or root access.  We do not want
// configuration files written during installation
// process.
_metadata const VSOPTION_CANT_WRITE_CONFIG_FILES    =63;
// Option when clicking in a registered MDI editor control, that does not 
// have focus, to place caret at mouse hit coordinates in addition to 
// giving focus.
_metadata const VSOPTION_PLACE_CARET_ON_FOCUS_CLICK       = 64;
// When get value, non-zero value means keep command line visible.
// When setting value, specify 1 to increment, 0 to decrement. Returns current count
_metadata const VSOPTION_STAY_IN_GET_STRING_COUNT=   65;

// A value of zero means the default IME usage of Option+Key on the Mac
// A non-zero value allows the Alt/Option key to be used for Windows-style key bindings
_metadata const VSOPTION_MAC_ALT_KEY_BEHAVIOR    =   67;
   _metadata const VSOPTION_MAC_ALT_KEY_DEFAULT_IME_BEHAVIOR    = 0;
   _metadata const VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR  = 1;
_metadata const VSOPTION_NO_ANTIALIAS            =   68;
_metadata const VSOPTION_MAC_USE_COMMAND_KEY_FOR_HOT_KEYS = 69;
_metadata const VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS = VSOPTION_MAC_USE_COMMAND_KEY_FOR_HOT_KEYS;
_metadata const VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY    =70;
_metadata const VSOPTION_CLEAR_KEY_NUMLOCK_STATE         =71;
_metadata const VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE =72;
/**
 * @deprecated Even though VSOPTION_MAC_RESIZE_BORDERS is no longer supported,
 *             it's needed so that old vusrdata.e files can be compiled.
 */
_metadata const VSOPTION_MAC_RESIZE_BORDERS              =73;
_metadata const VSOPTION_CURSOR_BLINK_RATE               =74;
// Do not read vrestore.slk or other user configuration files.
// This option is used to simplify starting the editor
// when you have a corrupt vrestore.slk, and is also used
// by utility programs that launch the editor, like vsmktags
_metadata const VSOPTION_DONT_READ_CONFIG_FILES          =75;
_metadata const VSOPTION_MDI_ALLOW_CORNER_TOOLBAR        =76;
_metadata const VSOPTION_MAC_HIGH_DPI_SUPPORT            =77;
   _metadata const VSOPTION_MAC_HIGH_DPI_AUTO = 0;
   _metadata const VSOPTION_MAC_HIGH_DPI_ON = 1;
   _metadata const VSOPTION_MAC_HIGH_DPI_OFF = 2;
_metadata const VSOPTION_MAC_SHOW_FULL_MDI_CHILD_PATH    =78;
   _metadata const VSOPTION_TAB_TITLE_SHORT_NAME =0;
   _metadata const VSOPTION_TAB_TITLE_NAME_AND_PATH =1;
   _metadata const VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_FULL_PATH =1;
   _metadata const VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_PATH=2;
   _metadata const VSOPTION_TAB_TITLE_FULL_PATH=3;
_metadata const VSOPTION_TAB_TITLE                     =79;
   _metadata const VSOPTION_SPLIT_WINDOW_EVENLY           =0;
   _metadata const VSOPTION_SPLIT_WINDOW_STRICT_HALVING   =1;
_metadata const VSOPTION_SPLIT_WINDOW                  =80;
   _metadata const VSOPTION_ZOOM_WHEN_ONE_WINDOW_NEVER   =0;
   _metadata const VSOPTION_ZOOM_WHEN_ONE_WINDOW_ALWAYS  =1;
   _metadata const VSOPTION_ZOOM_WHEN_ONE_WINDOW_AUTO    =2;
_metadata const VSOPTION_ZOOM_WHEN_ONE_WINDOW          =81;
_metadata const VSOPTION_TAB_MODIFIED_COLOR            =82;
_metadata const VSOPTION_JOIN_WINDOW_WITH_NEXT         =83;
/*const VSOPTION_DRAGGING_DOCUMENT_TAB         =84;*/
_metadata const VSOPTION_AUTO_RESTORING_TO_NEW_SCREEN_SIZE =85;
_metadata const VSOPTION_MULTI_CURSOR_AUTO_MERGE       =86;
_metadata const VSOPTION_SPECIAL_CHAR_TAB_OPTION       =87;
_metadata const VSOPTION_SPECIAL_CHAR_SPACE_OPTION     =88;
   // Hovering over a dock-channel Tab raises the auto-hide window
   _metadata const VSOPTION_DOCKCHANNEL_HOVER  =0x1;
_metadata const VSOPTION_DOCKCHANNEL_FLAGS             =89;
// Milliseconds to wait before raising auto-hide window for hovered dock-channel
_metadata const VSOPTION_DOCKCHANNEL_HOVER_DELAY       =90;
// Milliseconds to wait before lowering auto-hide window 
// when unfocused and mouse not inside.
_metadata const VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY     =91;
_metadata const VSOPTION_DRAW_SELECTIVE_DISPLAY_LINES  =92;
_metadata const VSOPTION_WIN_RESOLVE_SYMLINKS          =95;
_metadata const VSOPTION_INITIALLY_DISABLE_EDITOR_CONTROL_KEY_INPUT  =96;
_metadata const VSOPTION_MAX_ALLOCATORS                =97;

_metadata const VSOPTION_AUTO_MAP_PAD_KEYS             = 101;
_metadata const VSOPTION_EDITORCONFIG_FLAGS            = 102;
_metadata const VSOPTION_MAX_DELTA_SIZE_IN_K           = 103;
_metadata const VSOPTION_MIN_FAST_DELTA_SIZE_IN_K      = 104;
_metadata const VSOPTION_FORCERO                       = 105;
_metadata const VSOPTION_AUTORESTORE_MULTIPLE_MONITOR_CONFIGS  = 106;
_metadata const VSOPTION_MINIMAP_MOVE_CURSOR_ON_CLICK  = 107;
_metadata const VSOPTION_MINIMAP_WIDTH_IS_FIXED        = 108;
_metadata const VSOPTION_MINIMAP_WIDTH                 = 109;
_metadata const VSOPTION_MINIMAP_WIDTH_PERCENTAGE      = 110;
_metadata const VSOPTION_MINIMAP_DELAYED_UPDATING      = 111;
_metadata const VSOPTION_MINIMAP_SHOW_VERTICAL_LINES   = 112;
_metadata const VSOPTION_MINIMAP_LEFT_MARGIN           = 113;
_metadata const VSOPTION_MINIMAP_SHOW_MODIFIED_LINES   = 114;
_metadata const VSOPTION_MINIMAP_ALTERNATE_SEARCH_HILIGHTING= 115;
_metadata const VSOPTION_MINIMAP_SHOW_TOOLTIP          = 116;
_metadata const VSOPTION_BACKUP_HISTORY_VERIFY_CHECKSUMS=117;
_metadata const VSOPTION_DIFF_TIMEOUT_IN_SECONDS       = 118;
_metadata const VSOPTION_DIR_PROJECT_FLAGS             = 119;
_metadata const VSOPTION_XTERM_BUILD_COLORING          = 120;
_metadata const VSOPTION_BETA_NUMBER                   = 121;
_metadata const VSOPTION_SHOW_EXTRA_LINE_AFTER_LAST_NL = 122;
_metadata const VSOPTION_LOCALSTA                      = 123;
_metadata const VSOPTION_PREFER_SHORT_FILENAMES        = 124;
_metadata const VSOPTION_MAC_USE_SCROLL_PERFORMANCE_HACK = 125;
_metadata const VSOPTION_NEW_OPTION                    = 126;
_metadata const VSOPTION_ALLOW_FILE_LOCKING            = 127;
_metadata const VSOPTION_LOAD_PLUGINS                  = 128;
_metadata const VSOPTION_AUTO_BUILD_TAG_FILES          = 129;

_metadata const VSOPTIONZ_PAST_EOF               =1000;

_metadata const VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB  =1001;
   const VSSPECIALCHAR_NOT_USED_1=    0;
   const VSSPECIALCHAR_NOT_USED_2=    1;
   const VSSPECIALCHAR_NOT_USED_3=    2;
   const VSSPECIALCHAR_NOT_USED_4=    3;
   const VSSPECIALCHAR_NOT_USED_5=    4;
   const VSSPECIALCHAR_EOF=           5;
   const VSSPECIALCHAR_FORMFEED=      6;
   const VSSPECIALCHAR_OTHER_CTRL_CHAR= 7;
   const VSSPECIALCHAR_EOL=           8;
   const VSSPECIALCHAR_CR=            9;
   const VSSPECIALCHAR_LF=            10;

   const VSSPECIALCHAR_MAX=     20;

_metadata const VSOPTIONZ_APPLICATION_NAME       =1002;
_metadata const VSOPTIONZ_SUPPORTED_TOOLBARS_LIST  =1003;
_metadata const VSOPTIONZ_LANG                     =1004;
_metadata const VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8 =1005;
_metadata const VSOPTIONZ_DEFAULT_FIND_WINDOW_OPTIONS =1006;
_metadata const VSOPTIONZ_DATE_FORMAT_UNIX            =1007;
_metadata const VSOPTIONZ_TIME_FORMAT_UNIX            =1008;
_metadata const VSOPTIONZ_APP_THEME                   =1009;
_metadata const VSOPTIONZ_MINIMAP_NO_ANTI_ALIASING    =1010;
_metadata const VSOPTIONZ_DEFAULT_EXCLUDES            =1011;
_metadata const VSOPTIONZ_DIR_PROJECT_EXCLUDES        =1012;
_metadata const VSOPTIONZ_DIR_PROJECT_INCLUDES        =1013;
_metadata const VSOPTIONZ_DIR_PROJECT_TYPE            =1014;
_metadata const VSOPTIONZ_ZIP_EXT_LIST                =1015;
_metadata const VSOPTIONZ_APP_THEME_AUTO              =1016;

_metadata enum_flags VSShowSpecialChars {
   SHOWSPECIALCHARS_NLCHARS    = 0x01,
   SHOWSPECIALCHARS_TABS       = 0x02,
   SHOWSPECIALCHARS_SPACES     = 0x04,
   SHOWSPECIALCHARS_CTRL_CHARS = 0x08,
   SHOWSPECIALCHARS_EOF        = SHOWSPECIALCHARS_CTRL_CHARS,
   SHOWSPECIALCHARS_FORMFEED   = SHOWSPECIALCHARS_CTRL_CHARS,
   SHOWSPECIALCHARS_ALL        = 0xff,
};

const DEFAULT_SPECIAL_CHARS=  SHOWSPECIALCHARS_CTRL_CHARS;


/**
 * File differencing options.  Bitset of DIFF_*
 * <ul>
 * <li><b>DIFF_EXPAND_TABS            </b> -- expand tabs to spaces
 * <li><b>DIFF_IGNORE_LSPACES         </b> -- ignore leading white space
 * <li><b>DIFF_IGNORE_TSPACES         </b> -- ignore trailing white space
 * <li><b>DIFF_IGNORE_SPACES          </b> -- ignore all white space in line
 * <li><b>DIFF_IGNORE_CASE            </b> -- ignore text case
 * <li><b>DIFF_OUTPUT_INTERLEAVED     </b> -- display interleaved output instead of side-by-side difference
 * <li><b>DIFF_DONT_COMPARE_EOL_CHARS </b> -- do not compare end of line characters
 * <li><b>DIFF_OUTPUT_BOOLEAN         </b> -- output boolean
 * <li><b>DIFF_LEADING_SKIP_COMMENTS  </b> -- skip leading comments in each file
 * <li><b>DIFF_NO_BUFFER_SETUP        </b> -- no buffer setup
 * </ul>
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_diff_flags;
const DIFF_EXPAND_TABS=                        0x01;
const DIFF_IGNORE_LSPACES=                     0x02;
const DIFF_IGNORE_TSPACES=                     0x04;
const DIFF_IGNORE_SPACES=                      0x08;
const DIFF_IGNORE_CASE=                        0x10;
const DIFF_OUTPUT_INTERLEAVED=                 0x20;
const DIFF_DONT_COMPARE_EOL_CHARS=             0x40;
const DIFF_OUTPUT_BOOLEAN=                     0x400;
const DIFF_LEADING_SKIP_COMMENTS=              0x800;
const DIFF_NO_BUFFER_SETUP=                    0x4000;
const DIFF_DONT_MATCH_NONMATCHING_LINES=       0x8000;
const DIFF_MFDIFF_REQUIRE_TEXT_MATCH=          0x10000;
const DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH=     0x20000;
const DIFF_MFDIFF_SIZE_ONLY_MATCH_IS_MISMATCH= 0x40000;
const DIFF_NO_SOURCE_DIFF=                     0x80000;
const DIFF_BALANCE_BUFFERS=                    0x100000;
const DIFF_NO_BALANCE_BUFFERS_WARNING=         0x200000;
const DIFF_SKIP_ALL_COMMENTS=                  0x400000;
const DIFF_SKIP_LINE_NUMBERS=                  0x800000;
const DIFF_USE_SOURCE_DIFF_TOKEN_MAPPINGS=     0x1000000;
const DIFF_DONT_STORE_RESULTS =                0x8000000;
const DIFF_ALWAYS_STORE_RESULTS =              0x10000000;

/**
 * Difference editor options.  Bitset of DIFFEDIT_*.
 * <ul>
 * <li><b>DIFFEDIT_START_AT_TOP        </b> -- start at top of file
 * <li><b>DIFFEDIT_START_AT_FIRST_DIFF </b> -- start at first diff in file
 * <li><b>DIFFEDIT_CURFILE_INIT        </b> -- initialize Diff dialog with current file
 * <li><b>DIFFEDIT_AUTO_JUMP           </b> -- automatically jump to next diff after merge
 * <li><b>DIFFEDIT_SHOW_GAUGE          </b> -- show gauge during diff
 * <li><b>DIFFEDIT_NO_AUTO_MAPPING     </b> -- disable automatic directory mapping in diff dialog
 * <li><b>DIFFEDIT_AUTO_CLOSE          </b> -- automatically close diff dialog after last difference
 * <li><b>DIFFEDIT_NO_PROMPT_ON_MFCLOSE</b> -- do not prompt when multi-file diff dialog is closed
 * <li><b>DIFFEDIT_BUTTONS_AT_TOP      </b> -- move diff buttons to the top of dialog
 * <li><b>DIFFEDIT_SPAWN_MFDIFF        </b> -- run multi-file diff in background
 * </ul>
 *
 * @default
 * @categories Configuration_Variables
 */
int def_diff_edit_flags;
const DIFFEDIT_START_AT_TOP=          0x04;
const DIFFEDIT_START_AT_FIRST_DIFF=   0x08;
const DIFFEDIT_CURFILE_INIT=          0x10;
const DIFFEDIT_AUTO_JUMP=             0x20;
const DIFFEDIT_SHOW_GAUGE=            0x40;
const DIFFEDIT_NO_AUTO_MAPPING=       0x1000;
const DIFFEDIT_AUTO_CLOSE=            0x2000;
const DIFFEDIT_NO_PROMPT_ON_MFCLOSE=  0x4000;
const DIFFEDIT_BUTTONS_AT_TOP=        0x8000;
const DIFFEDIT_SPAWN_MFDIFF=          0x10000;
const DIFFEDIT_HIDE_CURRENT_CONTEXT=  0x20000;
const DIFFEDIT_HIDE_MARGIN_BUTTONS=   0x40000;
//Other flags reserved...
int def_diff_max_intraline_len;

_str def_diff_font_info;
int def_diff_num_sessions;    // number of unnamed diff sessions to be kept

int GMFDiffViewOptions;
const DIFF_VIEW_MATCHING_FILES=  0x1;
const DIFF_VIEW_VIEWED_FILES=    0x2;
const DIFF_VIEW_DIFFERENT_FILES= 0x4;
const DIFF_VIEW_MISSING_FILES1=  0x8;
const DIFF_VIEW_MISSING_FILES2=  0x10;

const DIFF_VIEW_DIFFERENT_SYMBOLS= 0x20;
const DIFF_VIEW_MATCHING_SYMBOLS=  0x40;
const DIFF_VIEW_MISSING_SYMBOLS1=   0x80;
const DIFF_VIEW_MISSING_SYMBOLS2=  0x100;
const DIFF_VIEW_MOVED_SYMBOLS=     0x200;

bool def_auto_landscape;

/**
 * Selective display options. 
 *  
 * <ul> 
 *     <li>SELDISP_COLLAPSEPROCCOMMENTS (0x0001) -- 
 *     In {@link show_procs}, specifies that the comments preceeding a 
 *     function definition or declaration should be collapsed as a separate 
 *     selective-display region.
 * </li> 
 * <li>SELDISP_SHOWPROCCOMMENTS (0x0002) -- 
 *     In {@link show_procs}, specifies that the comments preceeding a function 
 *     definition or declaration should remain visible. 
 *     If neither this flag nor SELDISP_COLLAPSEPROCCOMMENTS are set, 
 *     the comments will be hidden entirely.
 * </li> 
 * <li>SELDISP_EXPANDSUBLEVELS (0x0004) -- 
 *     In {@link plusminus}, specifies that when expanding a selective display 
 *     region with nested regions, that the nested regions should also be expanded.
 * </li> 
 *     <li>SELDISP_COLLAPSESUBLEVELS (0x0008) -- 
 *     In {@link plusminus}, specifies that when expanding a selective display 
 *     region with nested regions, that the nested regions should be collapsed. 
 * </li> 
 * <li>SELDISP_SHOW_OTHER_SYMBOLS (0x0010) --
 *     In {@link show_procs}, specifies that other symbols should be collapsed 
 *     in the same way functions are handled.  If this is not specified, 
 *     non-function symbols will be hidden entirely. 
 * </li> 
 * <li>SELDISP_COLLAPSE_PROC_BODIES (0x0020) -- 
 *     In {@link show_procs}, specifies that the bodies of function definitions 
 *     should be collapsed as a separate selective-display region. 
 * </li> 
 * <li>SELDISP_SHOW_PROC_BODIES (0x0040) -- 
 *     In {@link show_procs}, specifies that the bodies of function definitions 
 *     should remain visible.
 * </li> 
 * <li>SELDISP_SHOW_BLANK_LINES (0x0080) -- 
 *     In {@link show_procs}, specifies that blank lines separating 
 *     functions and other symbols should remain visible.
 * </li> 
 * <li>SELDISP_COLLAPSE_DOC_COMMENTS (0x0100) -- 
 *     In {@link hide_all_comments} specifies that any documentation
 *     comment should be collapsed. 
 *     In {@link show_procs}, specifies that the action specified for function 
 *     comments (Show, Collapse, or Hide), should be specifically applied to 
 *     documentation comments. 
 * </li> 
 * <li>SELDISP_COLLAPSE_OTHER_COMMENTS (0x0200) -- 
 *     In {@link hide_all_comments} specifies that any non-documentation
 *     comment should be collapsed. 
 *     In {@link show_procs}, specifies that the action specified for function 
 *     comments (Show, Collapse, or Hide), should be specifically applied to 
 *     non-documentation comments. 
 * </li> 
 * </ul> 
 *  
 * @default SELDISP_SHOWPROCCOMMENTS (2)
 * @categories Configuration_Variables
 *
 * @see show_procs
 * @see hide_all_comments
 */
int def_seldisp_flags;
/**
 * Selective display nesting options.   Specifies the maximum level of nested 
 * selective display regions to create. 
 *  
 * @default 25
 * @categories Configuration_Variables
 *
 * @see show_braces
 * @see show_indent 
 * @see show_statements 
 */
int def_seldisp_maxlevel;
/**
 * Selective display nesting options.   Specifies the minimum level of nested 
 * selective display regions to leave expanded.  Anything nested deeper than 
 * this level will not be collapsed. 
 *  
 * @default 20
 * @categories Configuration_Variables
 *
 * @see show_braces
 * @see show_indent
 * @see show_statements 
 */
int def_seldisp_minlevel;
/**
 * Specifies that selective display regions can be expanded or collapsed 
 * with a single click (rather than requiring a double-click).
 *  
 * @default false
 * @categories Configuration_Variables
 *
 * @see mou_click
 * @see mou_select_word 
 * @see plusminus 
 */
bool def_seldisp_single;

int def_vcpp_flags;
int _Nofchanges;

/**
 * Copy to clipboard will copy the current line if there is no selection.
 *
 * @default true
 * @categories Configuration_Variables
 *
 * @see cut
 * @see copy_to_clipboard
 */
bool def_copy_noselection;
/**
 * Copy to clipboard will execute stop_build in the Build window
 * if there is no selection and the last key was Ctrl+C.
 *
 * @default true;
 * @categories Configuration_Variables
 *
 * @see copy_to_clipboard
 * @see stop_build
 */
bool def_stop_process_noselection;

const MFFIND_BUFFER=            '<Current Buffer>';
const MFFIND_BUFFERS=           '<All Buffers>';
const MFFIND_BUFFER_DIR=        '<Current Buffer Directory>';
const MFFIND_PROJECT_FILES=     '<Project>';
const MFFIND_WORKSPACE_FILES=   '<Workspace>';

const MFFIND_DEFAULT_EXCLUDES=  '<Default Excludes>';
const MFFIND_BINARY_FILES=      '<Binary Files>';

const MFFIND_CURBUFFERONLY= 0x01;   // deprecated
const MFFIND_FILESONLY=     0x02;
const MFFIND_APPEND=        0x04;
const MFFIND_MDICHILD=      0x08;
const MFFIND_SINGLE=        0x10;
const MFFIND_GLOBAL=        0x20;
const MFFIND_THREADED=      0x40;
const MFFIND_SINGLELINE=    0x80;
const MFFIND_LEAVEOPEN=     0x100;  // for mfreplace
const MFFIND_DIFF=          0x200;  // for mfreplace
const MFFIND_MATCHONLY=     0x400;
const MFFIND_QUIET=         0x800;
const MFFIND_LOOKINZIPFILES= 0x1000;
const MFFIND_LIST_CURRENT_CONTEXT = 0x2000;
const MFFIND_FIND_FILES = 0x4000;
const MFFIND_INTERNAL_EXCLUDE_BINARY_FILES=0x8000;

const SW_HIDE=             0;  // Make window invisible
const SW_NORMAL=           1;
const SW_SHOWMINIMIZED=    2;  // Show window iconized
const SW_SHOWMAXIMIZED=    3;  // Show window maximized
const SW_SHOWNOACTIVATE=   4;  // Make window visible without changing Z order
const SW_SHOW=             5;  // Make window visible and change Z order
const SW_SHOWNOACTIVATE_FOCUS_LATER= 6;  // Show no activate but allow to get focus later.
const SW_RESTORE=          9;  // Restore window

enum SSTAB_ORIENTATION {
   SSTAB_OTOP          = 0,  // tab-row-on-top orientation
   SSTAB_OBOTTOM       = 1,  // tab-row-on-bottom orientation
   SSTAB_OLEFT         = 2,  // tab-row-on-left orientation
   SSTAB_ORIGHT        = 3,  // tab-row-on-right orientation
};

// Deprecated p_GrabbarLocation values
const SSTAB_GRABBARLOCATION_TOP=    0;
const SSTAB_GRABBARLOCATION_BOTTOM= 1;
const SSTAB_GRABBARLOCATION_LEFT=   2;
const SSTAB_GRABBARLOCATION_RIGHT=  3;

// Deprecated p_MultiRow values
const SSTAB_MULTIROW_NONE=       0;
const SSTAB_MULTIROW_MULTIROW=   1;
const SSTAB_MULTIROW_BESTFIT=    2;

struct SSTABCONTAINERINFO {

   // true if tab is enabled
   bool enabled;
   // Order of the tab (left-to-right). This will typically be the
   // same as the index.
   int order;
   // Index of picture displayed on the tab
   int picture;
   // true if caption is partially displayed
   bool partialCaption;
   // Top-left corner of tab in pixels, (0,0) if tab is not visible
   int tx, ty;
   // Bottom-right corner of tab in pixels, (0,0) if tab is not visible
   int bx, by;
   // Tab width in pixels, 0 if tab is not visible.
   // Note that this is measured in the direction of the text, so
   // a vertical left/right orientation would give you the height
   // of the tab in the viewer's (non-relativistic) reference frame.
   int width;
   // Caption text on the tab
   _str caption;
   // Help topic
   _str help;
   // Tooltip text to show when hovering with mouse
   _str tooltip;

};
const ECPROPSETFLAG_INDENT_WITH_TABS=       0x0001;
const ECPROPSETFLAG_SYNTAX_INDENT=          0x0002;
const ECPROPSETFLAG_TAB_SIZE=               0x0004;
const ECPROPSETFLAG_EOL_STYLE=              0x0008;
const ECPROPSETFLAG_CHARSET=                0x0010;
const ECPROPSETFLAG_STRIP_TRAILING_SPACES=  0x0020;
const ECPROPSETFLAG_INSERT_FINAL_NEWLINE=   0x0040;
const ECPROPSETFLAG_MAX_LINE_LENGTH=        0x0080;
const ECPROPSETFLAG_BEAUTIFIER_DEFAULT_PROFILE=  0x0100;

struct EDITOR_CONFIG_PROPERITIES {
    int m_property_set_flags;
    bool m_indent_with_tabs;
    int m_syntax_indent;
    int m_tab_size;
    _str m_eol_style; // d,u, m
    _str m_charset;
    bool m_strip_trailing_spaces;
    bool m_insert_final_newline;
    int m_max_line_length;
    _str m_beautifier_default_profile;
    _str m_option_files[];
};

_str gerror_info:[];   // Hash table containing filenames which have
                       // old line numbers set.

/*
    1-Multi-file find uses find_next/find_prev
    2-Multi-file find uses next_error/prev_error
    Both bits can be on.
 */
int def_mfflags;
//3:35pm 3/24/1997:Dan added for tree control
const TREE_NO_LINES=         0;
const TREE_OS_DEFAULT_LINES= 1;
const TREE_DOTTED_LINES= TREE_OS_DEFAULT_LINES;   // For compatibility
const TREE_SOLID_LINES=  TREE_OS_DEFAULT_LINES;   // For compatibility
const TREE_NO_FIRST_LEVEL_LINES=  0x80;           // For compatibility

const TREENODE_HIDDEN=     0x01;    // node and children nodes are not visible in tree
//#define TREENODE_SELECTED   0x02  // deprecated use _TreeIsSelected(int) and _TreeSelectLine(int)
const TREENODE_BOLD=       0x04;    // node caption is bold
const TREENODE_ALTCOLOR=   0x08;    // node is colored same as modified line 
                                    // color.  When this is shut off, it will
                                    // restore the regular tree foreground and
                                    // background color.  Do not use this in 
                                    // conjunction with _TreeSetColor(),
                                    // _TreeSetColColor(), _TreeSetRowColor()
const TREENODE_FORCECOLOR= 0x10;    // node is always colored red
const TREENODE_GRAYTEXT=   0x20;    // node is colored gray
const TREENODE_DISABLED=   0x40;    // node is colored gray, no node edits
const TREENODE_ITALIC=     0x80;    // node caption is italic
const TREENODE_UNDERLINE=  0x100;   // node caption is underlined
const TREENODE_FIRSTCOLUMNSPANS=  0x200;   // node caption is underlined
const TREENODE_HIDEINDICATOR= 0x400;       // do not show > or \/ indicator

/**
 * This struct is used to save and restore the contents
 * of a tree control.
 */
struct TREENODESTATE {
   _str caption;              // node caption
   int bm1, bm2;              // current and other bitmaps
   int show_children;         // show children (-1, 0, or 1)
   int flags;                 // TREENODE_* flags
   typeless user_info;        // user info for node
   bool current;              // is this the current item in the tree?
   TREENODESTATE children[];  // list of children under this node
   int overlays[];            // save overlay bitmaps
};

//7:15pm 4/29/1997:These are for the push buttton list box stuff
const LB_BUTTON_NOPUSH=      0;
const LB_BUTTON_PUSH_BUTTON= 1;
const LB_BUTTON_STICKY=      2;

const TREE_ADD_AFTER=      0x0; /* Add a node after  sibling in order */
const TREE_ADD_BEFORE=     0x1; /* Add a node before sibling in order */
const TREE_ADD_AS_CHILD=   0x2;
//These sort flags cannot be used in combination with each other
const TREE_ADD_SORTED_CS=       0x4;
const TREE_ADD_SORTED_CI=       0x8;
const TREE_ADD_SORTED_FILENAME= 0x10;
const TREE_ADD_SORTED_DESCENDING= 0x20;
const TREE_ADD_AS_FIRST_CHILD=    0x40;
const TREE_OVERLAY_BITMAP1=       0x80;

const TREE_ROOT_INDEX=     0;

// Used with the "show children" parameter
const TREE_NODE_LEAF=           -1;
const TREE_NODE_COLLAPSED=      0;
const TREE_NODE_EXPANDED=       1;

/* Constants for 'tree_to_node' */
const TO_PREVSIB= 0x1;   /* To previous(left) sibling */
const TO_NEXTSIB= 0x2;   /* To next(right) sibling    */
const TO_PARENT=  0x4;   /* To parent                 */
const TO_LCHILD=  0x8;   /* To left-most child        */

/* Constants for 'tree_traverse' */
const TRAVERSE_PREORDER=  0x1;
const TRAVERSE_INORDER=   0x2;
const TRAVERSE_POSTORDER= 0x4;

const TREE_NODE_CHILD=  1;
const TREE_NODE_PARENT= 2;

const VCPP_STARTUP_TIMEOUT= 30;
const VCPP_EXE_FILENAME= 'msdev.exe';
const VCPP_CLASSNAME_PREFIX= 'Afx';
const VCPP_WINDOWTITLE_PREFIX= 'Microsoft Developer Studio';

// Label Style argument constants
const MULTI_LABEL_DEFAULT= 0x1;
const MULTI_LABEL_SUNKEN= 0x2;

// Label AutoSizeStyle argument constants
const MULTI_LABEL_AUTOSIZE_DEFAULT= 0;
const MULTI_LABEL_AUTOSIZE_INDIV= 1;
const MULTI_LABEL_AUTOSIZE_REST= 2;

// _SetListColInfo method Style argument constants
const LBCOLSTYLE_LABEL=      0;
const LBCOLSTYLE_BUTTON=     1;
const LBCOLSTYLE_2STATE=     2;

const VSMARKFLAG_BINARY=            1;
//#define VSMARKFLAG_DELETE_LAST_LINE  2
//#define VSMARKFLAG_ALREADYADJUSTED   4
const VSMARKFLAG_COPYNOSAVELF=      8;
// Effects BLOCK copy,move,overlay,adjust.
// source will include text to end of line.
// Useful if copy proportional font BLOCK to temp view which 
// can't have a font and then copy/overlay/adjust the BLOCK
// somewhere else.
const VSMARKFLAG_BLOCK_INCLUDE_REST_OF_LINE=     0x40;
// Only supports copy to cursor with BLOCK selection
const VSMARKFLAG_BLOCK_OPERATE_ON_VISIBLE_LINES=  0x80;
// Supports fill selection only.
const VSMARKFLAG_FILL_NO_FILL=                 0X100;
// Supports fill selection only.
const VSMARKFLAG_FILL_INSERT_ONCE=             0X200;
// When on, lines that are copied also copy the MODIFY and INSERTED_LINE lin flags instead
// of marking all inserted lines as INSERTED_LINE
const VSMARKFLAG_COPYLINEMODIFY= 0x400;
/*
Only supported if source and destination buffers have same newline characters.
Note that new line characters for last line are not preserved and must be
adjust by caller.
*/
const VSMARKFLAG_KEEP_SRC_NLCHARS=0x800;
// Convert Hex view paste data as binary
const VSMARKFLAG_PASTE_HEX_VIEW =0x1000;
// Effects filling BLOCK selection only.
// Don't fill block if filling past end of line.
const VSMARKFLAG_FILL_BLOCK_ONLY_IF_LINE_LONG_ENOUGH=  0x2000;


//      p_ModifyFlags
const MODIFYFLAG_AUTOSAVE_DONE=       0x0002;
const MODIFYFLAG_DELPHI=              0x0004;
const MODIFYFLAG_TAGGED=              0x0008;
//#define MODIFYFLAG_PROCTREE_UPDATED    0x0010
const MODIFYFLAG_CONTEXT_UPDATED=     0x0020;
const MODIFYFLAG_LOCALS_UPDATED=      0x0040;
const MODIFYFLAG_FCTHELP_UPDATED=     0x0080;
//#define MODIFYFLAG_TAGWIN_UPDATED      0x0100
const MODIFYFLAG_CONTEXTWIN_UPDATED=  0x0200;
const MODIFYFLAG_FTP_NEED_TO_SAVE=    0x0400;
const MODIFYFLAG_AUTOEXT_UPDATED=     0x0800;
//#define MODIFYFLAG_PROCTREE_SELECTED   0x1000
const MODIFYFLAG_LC_UPDATED=          0x2000;
const MODIFYFLAG_XMLTREE_UPDATED=     0x4000;
// Warning: MODIFYFLAG_JGUI_UPDATED is also defined in heap.h
const MODIFYFLAG_JGUI_UPDATED=        0x8000;  //Indicates that Java GUI Builder has buffer contents
const MODIFYFLAG_STATEMENTS_UPDATED=  0x10000;
const MODIFYFLAG_AUTO_COMPLETE_UPDATED=  0x20000;
//#define MODIFYFLAG_CLASS_UPDATED          0x40000
//#define MODIFYFLAG_CLASS_SELECTED         0x80000
const MODIFYFLAG_BGRETAG_THREADED=       0x100000;
const MODIFYFLAG_CONTEXT_THREADED=       0x200000;
const MODIFYFLAG_LOCALS_THREADED=        0x400000;
const MODIFYFLAG_STATEMENTS_THREADED=    0x800000;
const MODIFYFLAG_SYMBOL_COLORING_RESET=  0x1000000;
const MODIFYFLAG_SCROLL_MARKER_UPDATED=  0x2000000;
const MODIFYFLAG_TOKENLIST_UPDATED=      0x4000000;

/**
 * Control dynamic tagging options.  Consists of a bitset of AUTOTAG_* flags.
 * <ul>
 * <li><b>AUTOTAG_ON_SAVE            </b> -- Tag file on save
 * <li><b>AUTOTAG_BUFFERS            </b> -- Background tag open files
 * <li><b>AUTOTAG_FILES              </b> -- Background tag all files
 * <li><b>AUTOTAG_FILES_PROJECT_ONLY </b> -- Background tag workspace files only
 * <li><b>AUTOTAG_SYMBOLS            </b> -- Refresh tag window (symbols tab)
 * <li><b>AUTOTAG_CURRENT_CONTEXT    </b> -- Background update current context
 * <li><b>AUTOTAG_UPDATE_CALLSREFS   </b> -- Update call tree and references
 *                                           on change event for symbols
 *                                           browser and proctree
 * <li><b>AUTOTAG_CURRENT_CONTEXT      </b> -- Background update symbols in current file
 * <li><b>AUTOTAG_UPDATE_CALLSREFS     </b> -- Update call tree and references on change
 * <li><b>AUTOTAG_BUFFERS_NO_THREADS   </b> -- Do not use thread for tagging buffer or save 
 * <li><b>AUTOTAG_WORKSPACE_NO_THREADS </b> -- Do not use threads for tagging workspace files
 * <li><b>AUTOTAG_LANGUAGE_NO_THREADS  </b> -- Do not use threads for language support tag files
 * <li><b>AUTOTAG_SILENT_THREADS       </b> -- Report background tagging activity on status bar
 * <li><b>AUTOTAG_WORKSPACE_NO_OPEN    </b> -- Do not update workspace tag file when workspace is opened
 * <li><b>AUTOTAG_WORKSPACE_NO_ACTIVATE</b> -- Do not update workspace tag file on app activate
 * <li><b>AUTOTAG_DISABLE_ALL_THREADS  </b> -- Disable all threaded tagging options
 * <li><b>AUTOTAG_DISABLE_ALL_BG       </b> -- Disable all background tagging options
 * <li><b>AUTOTAG_ON_SWITCHBUF         </b> -- Background tag modified buffers on switchbuf
 * </ul>
 *
 * @default AUTOTAG_ON_SAVE | 
 *          AUTOTAG_BUFFERS |
 *          AUTOTAG_SYMBOLS |
 *          AUTOTAG_ON_SWITCHBUF |
 *          AUTOTAG_FILES_PROJECT_ONLY |
 *          AUTOTAG_CURRENT_CONTEXT
 *  
 * @categories Configuration_Variables
 */
int def_autotag_flags2;

#include "rc.sh"
const VSWID_TOP=      -1;
const VSWID_BOTTOM=   -2;

//These are options for *_list_tags and *_list_locals
const VSLTF_OUTPUT_LINE_NUMBERS=     0x0001;   // [OBSOLETE] output only line numbers
const VSLTF_PROCS=                   0x0002;   // [OBSOLETE] List proctree (def_proctree_flags) only
const VSLTF_TREE_OUTPUT=             0x0004;   // [OBSOLETE] Output to a tree control
const VSLTF_TREE_OUTPUT_HIDDEN=      0x0008;   // [OBSOLETE] Output to tree control hidden
const VSLTF_LIST_OUTPUT=             0x0010;   // [OBSOLETE] Output to list control
const VSLTF_SKIP_OUT_OF_SCOPE=       0x0020;   // [DEPRECATED] Skip locals that are out of scope
const VSLTF_SET_TAG_CONTEXT=         0x0040;   // Set tagging context at cursor position
const VSLTF_SET_TAG_MATCHES=         0x0080;   // [21.0] Insert tags into match set
const VSLTF_LIST_OCCURRENCES=        0x0100;   // Insert references into tags database
const VSLTF_START_LOCALS_IN_CODE=    0x0200;   // Parse locals without first parsing header
const VSLTF_READ_FROM_STRING=        0x0400;   // [6.0] arg(3)=buffer, arg(6)=buffer_len
const VSLTF_LIST_STATEMENTS=         0x0800;   // [9.0] list statements as well as contexts
const VSLTF_LIST_LOCALS=             0x1000;   // [15.0] list local variables in current function
const VSLTF_ASYNCHRONOUS=            0x2000;   // [15.0] request to update tags in background thread
const VSLTF_READ_FROM_EDITOR=        0x4000;   // [15.0] reading input from an editor control
const VSLTF_ASYNCHRONOUS_DONE=       0x8000;   // [16.0] special flag for job to indicate tagging done
const VSLTF_BEAUTIFIER=              0x10000;  // [17.0] Set when this is associated with a beautifier job.
const VSLTF_SAVE_TOKENLIST=          0x20000;  // [18.0] Set when building current context and saving token list
const VSLTF_INCREMENTAL_CONTEXT=     0x40000;  // [18.0] Used for incremental parsing
const VSLTF_REMOVE_FILE=             0x80000;  // [20.0] Remove the given file from a tag database
const VSLTF_FIND_SYMBOLS=            0x100000; // [21.0] Search for symbols matching a search specification
const VSLTF_READ_FROM_STRING_IS_ACP= 0x200000; // string is active page and not Utf-8
const VSLTF_NO_SAVE_COMMENTS=        0x400000; // [25.0] Do not store documentation comments when tagging

#define USE_T_FOR_TOOLS  0
#define USE_B_FOR_BUILD  1

/**
 * Symbol filters used by Find Symbol tool window.
 * This setting contains a bitset of VS_TAGFILTER_* flags used for
 * selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_find_symbol_flags;
/**
 * Symbol filters used by Preview tool window.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_tagwin_flags;
/**
 * Symbol filters used by References tool window.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_references_flags;
/**
 * Symbol filters used by Defs tool window.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
enum_flags SETagFilterFlags def_proctree_flags;
/**
 * Symbol filters used by go to definition symbol search dialog.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @see gui_push_tag
 * @categories Configuration_Variables
 */
int def_tagselect_flags;
/**
 * Symbol filters used by JavaDoc editor.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_javadoc_filter_flags;
/**
 * Symbol filters used by XMLDoc editor.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_xmldoc_filter_flags;
/**
 * Symbol filters used by the Class tool window.
 * This setting contains a bitset of VS_TAGFILTER_* flags used
 * for selecting which symbol types to display.
 *
 * @categories Configuration_Variables
 */
int def_class_flags;

/**
 * Initial level to expand file node to in the Defs tab of the project toolbar. 
 * 
 * If "Auto Collapse" is on, then the tree will be collapsed back to this level 
 * each time before it is automatically expanded.  Using this technique, the 
 * tree is maintained in a state where only the segment of the tree under the 
 * cursor is expanded, and the rest of the tree is only expanded to the level 
 * the user wants. 
 * 
 * Valid values:
 * <ul>
 * <li>0 Normal processing takes place. If "Auto Expand" is on, then
 *     the current symbol is found in the tree. If "Auto Expand" is off,
 *     then the tree is not expanded.
 * <li>1 One level.
 * <li>2 Two levels. 
 * <li>-1 Expand up to statement level</li>
 * </ul>
 *  
 * @categories Configuration_Variables
 */
int def_proc_tree_expand_level;

int def_tag_select_options;

enum_flags DefsToolWindowOptions {
   PROC_TREE_SORT_FUNCTION=   0x1,
   PROC_TREE_SORT_LINENUMBER= 0x2,
   PROC_TREE_AUTO_EXPAND=     0x4,
   PROC_TREE_ONLY_TAGGABLE=   0x8,  /* OBSOLETE */
   PROC_TREE_NO_STRUCTURE=    0x10,
   PROC_TREE_AUTO_STRUCTURE=  0x20,
   PROC_TREE_NO_BUFFERS=      0x40, /* OBSOLETE */
   PROC_TREE_STATEMENTS=      0x80, /* VIRTUALLY OBSOLETE, replaced with per-language / per-file option */
   PROC_TREE_SINGLE_CLICK=    0x100,
   PROC_TREE_AUTO_COLLAPSE=   0x200,
};

/**
 * Defs tool window options.  Bitset of the following flags.
 * <ul> 
 * <li>PROC_TREE_SORT_FUNCTION   -- sort by function name</li>     
 * <li>PROC_TREE_SORT_LINENUMBER -- sort by line number</li>       
 * <li>PROC_TREE_AUTO_EXPAND     -- auto expand tree</li>   
 * <li>PROC_TREE_ONLY_TAGGABLE   -- obsolete</li>     
 * <li>PROC_TREE_NO_STRUCTURE    -- no structure</li>    
 * <li>PROC_TREE_AUTO_STRUCTURE  -- obsolete</li>      
 * <li>PROC_TREE_NO_BUFFERS      -- do not show buffers (always true)</li>  
 * <li>PROC_TREE_STATEMENTS      -- show statements</li>  
 * <li>PROC_TREE_SINGLE_CLICK    -- single click to jump to symbol, shift-click to jump to declaration.</li>    
 * </ul>
 * 
 * @categories Configuration_Variables
 */
DefsToolWindowOptions def_proc_tree_options;

/*
    _TagFileRefresh_*     Callbacks are called when a tag file
                          is added or removed.  It is also
                          called when a tag file is modified.
    _TagFileAddRemove_*   Callbacks are called when a tag file
                          is added or removed.

    _TagFileModified_*    Callbacks are called when a tag file
                          is modified.


    If you use the _TagFileRefresh_ callback, do not implement
    a _TagFileModified_ or a _TagFileAddRemove_ function.

    If you implement _TagFileAddRemove_ and _TagFileModified_,
    do not implement a _TagFileRefresh_ callback.
*/
const TAGFILE_MODIFIED_CALLBACK_PREFIX=   "_TagFileModified_";
const TAGFILE_ADD_REMOVE_CALLBACK_PREFIX= "_TagFileAddRemove_";
const TAGFILE_REFRESH_CALLBACK_PREFIX=    "_TagFileRefresh_";

const SYMBOL_TAB_CAPTION_STRING= 'Symbol';
const REFS_TAB_CAPTION_STRING=   'Refs';

/**
 * Default size in kilobytes for tag file cache. 
 *
 * @default 64M
 * @categories Configuration_Variables
 */
int def_tagging_cache_ksize;
/**
 * If the current machine has lots of memory available, we can 
 * dedicate more memory to tagging cache.  This is the maximum 
 * amount we should stretch out the tagging cache to. 
 * If we can not get this much memory, we will at least get the 
 * amount specified in {@link def_tagging_cache_ksize}. 
 *
 * @default 192M
 * @categories Configuration_Variables
 */
int def_tagging_cache_max_ksize;
/**
 * If 'true', use memory mapped files for tag databases. 
 * This relies on the operating system for tag file caching, and effectively 
 * makes the tagging cache size ({@link
 * def_tagging_cache_ksize}) irrelevant.
 *  
 * This feature is not enabled on all platforms, and can be problematic 
 * on 32-bit systems due to limited amounts or memory mapping space. 
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_tagging_use_memory_mapped_files;
/**
 * If 'true', use independent file caches for each tag database, rather 
 * than using a single multi-file database cache.  Turning on this feature 
 * can allow memory usage to increase by a factor equal to the number of 
 * open tag files, whereas with the feature turned off, memory usage was 
 * limited to the size of the single shared database file cache. 
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_tagging_use_independent_file_caches;
/**
 * Set to the maximum number of symbol sets to store for current context tagging, 
 * statement tagging, local variable tagging, and context tagging search results. 
 *  
 * The symbol sets are stored in a MRU (most recently used) queue so that older 
 * results are automatically removed from the cache when it reaches this size. 
 * 
 * The mininum allowed is 10 items, but if you have enough memory available, 
 * it is recommended to set this to at least five times the number of files 
 * you typically keep open at one time.  For very large files, each item in the 
 * cache can consume a megabyte of memory on average.
 *
 * @default 250
 * @categories Configuration_Variables 
 * @since 21.0 
 */
int def_context_tagging_max_cache;
/**
 * Directories to be excluded from tagging. 
 *
 * @default nothing 
 * @categories Configuration_Variables
 */
_str def_tagging_excludes;

_str _last_wildcards;
const PROJTOOLTAB_FILES=      0;
const PROJTOOLTAB_PROCS=      1;
const PROJTOOLTAB_CLASSES=    2;
const PROJTOOLTAB_OPEN=       3;

const OUTPUTTOOLTAB_SEARCH= 0;
const OUTPUTTOOLTAB_SYMBOL= 1;
const OUTPUTTOOLTAB_REFS=   2;
const OUTPUTTOOLTAB_SHELL=  3;
const OUTPUTTOOLTAB_OUTPUT= 4;
const OUTPUTTOOLTAB_XMLOUT= OUTPUTTOOLTAB_OUTPUT;

#endif

/**
 * Indicates if the file open command should allow you to browse for files 
 * using the system dialog or use the SlickEdit Open tool window. 
 * Set to one of: 
 * <ul> 
 * <li>OPEN_BROWSE_FOR_FILES</li>
 * <li>OPEN_SMART_OPEN</li>
 * </ul>
 *
 * @default OPEN_SMART_OPEN
 * @categories Configuration_Variables 
 */
int def_open_style;

_metadata enum OpenStyle {
   OPEN_BROWSE_FOR_FILES,
   OPEN_SMART_OPEN,
};
/** 
 * Indicates if the file open command should prompt whether to browse for files 
 * using the system dialog or to use the SlickEdit Open tool window. 
 * If <code>false</code>, it will use the option determined by {@link def_open_style}. 
 *
 * @default true
 * @categories Configuration_Variables 
 */
bool def_prompt_open_style;

/**
 * Use the Mac-style save prompt (Save/Don't Save/Cancel) on Mac
 * OS X. If false, Windows-style Yes/No/Cancel buttons are used.
 *
 * @default true
 * @categories Configuration_Variables 
 */
bool def_mac_save_prompt_style;

/**
 * Use Recycle Bin on Windows, or Trash on Mac, when deleting a
 * file from the Open toolwindow
 *  
 * @note 
 * Note that this def var is intentionally ignored by some features. 
 * For example, the Update Directory dialog ignores this setting and always 
 * tries to recyle files that are deleted.
 *
 * @default false
 * @categories Configuration_Variables 
 */
bool def_delete_uses_recycle_bin;


/**
 * Unix command to be used to send files to the trash when 
 * {@link recycle_file} is called. Ignored on Windows and Mac. 
 * Not required unless the trash command cannot be determined. 
 *  
 * Use %f as the placeholder where the file path should be 
 * specified. Do not use quotes, as the file path will be quoted 
 * if necessary. 
 *  
 * @example 
 * <pre>
 *    trash_a_file --file %f 
 * </pre>
 *
 * @default ""
 * @categories Configuration_Variables 
 */
_str def_trash_command;


/**
 * The same options dialog is used for many purposes.  This is a list of them.
 */
_metadata enum OptionsPurpose {
   OP_CONFIG,                    // regular old options configuration
   OP_EXPORT,                    // used to display export groups
   OP_IMPORT,                    // used to display an import package
   OP_QUICK_START                // the quick start configuration wizard
};

const OPTIONS_CHOICE_DELIMITER= '*+*';

const ALL_LANGUAGES_ID=         '*ALL_LANGUAGES*';

/**
 * These define events that may need to be triggered when certain options 
 * change. 
 */
_metadata enum_flags OptionsChangeEventFlags {
   OCEF_RESTART,
   OCEF_MENU_BIND,
   OCEF_REINIT_SOCKET,
   OCEF_WRITE_COMMENT_BLOCKS,
   OCEF_LOAD_USER_LEXER_FILE,
   OCEF_TAGGING_RESTART,
   OCEF_THREAD_RESTART,
   OCEF_DIALOG_FONT_RESTART,
   OCEF_NONE = 0x0
};

const OPTIONS_ERROR_DELIMITER=  '*:*';

enum OptionsPanelSwitchReason {
   OPTIONS_SWITCHING,
   OPTIONS_APPLYING,
   OPTIONS_CANCELLING,
};

const OPTIONS_CHANGE_CALLBACK_KEY=  "options_change_callback_key";

const VSEMBEDDED_BOTH=      0;
const VSEMBEDDED_IGNORE=    1;
const VSEMBEDDED_ONLY=      2;

/*
   Specify the VSBMFLAG_SHOWNAME if you want the bookmark
   name displayed at the left edge of the edit window.  Note
   that the user can select not to show any bookmark names
   on the left edge.
*/
const VSBMFLAG_SHOWNAME=     0x1;
/*
   VSBMFLAG_STANDARD has the following effects:
     * bookmark is diplayed in bookmark list
     * next_bookmark and prev_bookmark will traverse this bookmark.
*/
const VSBMFLAG_STANDARD=     0x2;

/*
   This flag is used by the push_bookmark command.  PUSHED bookmarks
   are mainly useful for tagging where the bookmarks are very temporary.
   By convention, PUSHED bookmarks do not appear on the left edge
   or in the bookmarks dialog and are ignored by all commands excepted
   the pop_bookmark command.  Don't specify the VSBMFLAG_SHOWNAME or
   VSBMFLAG_STANDARD flags when using this flag.

   In case you were wondering, tag boookmarks are named to simplify
   save and restoring bookmarks.
*/
const VSBMFLAG_PUSHED=       0x4;

/*
   Specify the VSBMFLAG_SHOWPIC if you want the bookmark
   bitmap displayed at the left edge of the edit window.
*/
const VSBMFLAG_SHOWPIC=      0x8;

/*
    This flag is used to indicate that a bookmark represents an
    annotation.  Annotations are treated like regular bookmarks,
    but they can also have a verbose description and a hash table
    of attributes.
*/
const VSBMFLAG_ANNOTATION=   0x10;

/*
    This flag is used to indicate that a bookmark represents a
    bookmark pushed as part of a references search.
*/
const VSBMFLAG_REFERENCES=   0x20;

int def_max_bm_tags;
bool def_use_workspace_bm;
bool def_show_bm_tags;
bool def_bm_show_picture;
bool def_cleanup_pushed_bookmarks_on_quit;
bool def_search_result_push_bookmark;

/**
 * SlickEdit RGB color of scroll markup for bookmarks. After 
 * changing this, you will have to restart the editor. 
 *
 * @categories Configuration_Variables
 */
int def_bm_scrollmarkup_color;



const VSTBBORDER_BORDER=    0x1;  // deprecated
const VSTBBORDER_GRABBARS=  0x2;  // deprecated

struct CMDUI {
   int menu_handle;   // 0 if not called from menu
   int menu_pos;      // undefined if menu_handle==0
   bool inMenuBar; // undefined if menu_handle==0
   _str reserved;     // undefined
   int button_wid;    // 0 if not called from toolbar button
};

const VSTBREFRESHBY_READ_ONLY=                  1;
const VSTBREFRESHBY_UNDO=                       2;
const VSTBREFRESHBY_REDO=                       3;
const VSTBREFRESHBY_SELECTION=                  4;
const VSTBREFRESHBY_CREATEDESTROY_MDICHILD=     5;
const VSTBREFRESHBY_MDICHILD_WINDOW_STATE=      6;
const VSTBREFRESHBY_ADDREMOVE_BOOKMARK=         7;
const VSTBREFRESHBY_STARTSTOP_MACRO_RECORDING=  8;

const VSTBREFRESHBY_PROJECT=                    9;
const VSTBREFRESHBY_INTERNAL_CLIPBOARDS=        10;
const VSTBREFRESHBY_SWITCHBUF=                  11;
const VSTBREFRESHBY_APPLICATION_GOT_FOCUS=      12;
const VSTBREFRESHBY_DEBUGGING=                  13;
const VSTBREFRESHBY_BACK_FORWARD=               14;

// Start your own values here or just use this one
const VSTBREFRESHBY_USER=                       1000;

// ALL TAG FILES in absolute format, duplicates removed
//    Project tags, all extension tag files, all global tag files
bool gtag_filelist_cache_updated;
// Delay tag file refresh calls to weed out duplicates
// initialized in stdcmds.e
bool gNoTagCallList;  
                     
const VSSCC_OK=                                  0;
const VSSCC_COMMAND_GET=         0;
const VSSCC_COMMAND_CHECKOUT=    1;
const VSSCC_COMMAND_CHECKIN=     2;
const VSSCC_COMMAND_UNCHECKOUT=  3;
const VSSCC_COMMAND_ADD=         4;
const VSSCC_COMMAND_REMOVE=      5;
const VSSCC_COMMAND_DIFF=        6;
const VSSCC_COMMAND_HISTORY=     7;
const VSSCC_COMMAND_RENAME=      8;
const VSSCC_COMMAND_PROPERTIES=  9;
const VSSCC_COMMAND_OPTION=      10;

const SCC_CAP_REMOVE=            0x00000001;   // Supports the SCC_Remove command
const SCC_CAP_RENAME=            0x00000002;   // Supports the SCC_Rename command
const SCC_CAP_DIFF=              0x00000004;   // Supports the SCC_Diff command
const SCC_CAP_HISTORY=           0x00000008;   // Supports the SCC_History command
const SCC_CAP_PROPERTIES=        0x00000010;   // Supports the SCC_Properties command
const SCC_CAP_RUNSCC=            0x00000020;   // Supports the SCC_RunScc command
const SCC_CAP_GETCOMMANDOPTIONS= 0x00000040;   // Supports the SCC_GetCommandOptions command
const SCC_CAP_QUERYINFO=         0x00000080;   // Supports the SCC_QueryInfo command
const SCC_CAP_GETEVENTS=         0x00000100;   // Supports the SCC_GetEvents command
const SCC_CAP_GETPROJPATH=       0x00000200;   // Supports the SCC_GetProjPath command
const SCC_CAP_ADDFROMSCC=        0x00000400;   // Supports the SCC_AddFromScc command
const SCC_CAP_COMMENTCHECKOUT=   0x00000800;   // Supports a comment on Checkout
const SCC_CAP_COMMENTCHECKIN=    0x00001000;   // Supports a comment on Checkin
const SCC_CAP_COMMENTADD=        0x00002000;   // Supports a comment on Add
const SCC_CAP_COMMENTREMOVE=     0x00004000;   // Supports a comment on Remove
const SCC_CAP_TEXTOUT=           0x00008000;   // Writes text to an IDE-provided output function
const SCC_CAP_ADD_STORELATEST=   0x00200000;   // Supports storing files without deltas
const SCC_CAP_HISTORY_MULTFILE=  0x00400000;   // Multiple file history is supported
const SCC_CAP_IGNORECASE=        0x00800000;   // Supports case insensitive file comparison
const SCC_CAP_IGNORESPACE=       0x01000000;   // Supports file comparison that ignores white space
const SCC_CAP_POPULATELIST=      0x02000000;   // Supports finding extra files
const SCC_CAP_COMMENTPROJECT=    0x04000000;   // Supports comments on create project
const SCC_CAP_REMOVE_KEEP=       0x08000000;   // Supports option to keep/delete local file on Remove
const SCC_CAP_DIFFALWAYS=        0x10000000;   // Supports diff in all states if under control
const SCC_CAP_GET_NOUI=          0x20000000;   // Provider doesn't support a UI for SccGet,
                                               //   but IDE may still call SccGet function.

const VSSCC_STATUS_INVALID=          -1;     // Status could not be obtained, don't rely on it
const VSSCC_STATUS_NOTCONTROLLED=    0x0000; // File is not under source control
const VSSCC_STATUS_CONTROLLED=       0x0001; // File is under source code control
const VSSCC_STATUS_CHECKEDOUT=       0x0002; // Checked out to current user at local path
const VSSCC_STATUS_OUTOTHER=         0x0004; // File is checked out to another user
const VSSCC_STATUS_OUTEXCLUSIVE=     0x0008; // File is exclusively check out
const VSSCC_STATUS_OUTMULTIPLE=      0x0010; // File is checked out to multiple people
const VSSCC_STATUS_OUTOFDATE=        0x0020; // The file is not the most recent
const VSSCC_STATUS_DELETED=          0x0040; // File has been deleted from the project
const VSSCC_STATUS_LOCKED=           0x0080; // No more versions allowed
const VSSCC_STATUS_MERGED=           0x0100; // File has been merged but not yet fixed/verified
const VSSCC_STATUS_SHARED=           0x0200; // File is shared between projects
const VSSCC_STATUS_PINNED=           0x0400; // File is shared to an explicit version
const VSSCC_STATUS_MODIFIED=         0x0800; // File has been modified/broken/violated
const VSSCC_STATUS_OUTBYUSER=        0x1000; // File is checked out by current user someplace

const VSSCC_PROJECT_NAME=      1;
const VSSCC_LOCAL_PATH=        2;
const VSSCC_AUX_PATH_INFO=     3;
const VSSCC_PROVIDER_DLL_PATH= 4;
const VSSCC_PROVIDER_NAME=     5;

const SCC_PREFIX=        'SCC:';
const SCC_PREFIX_LENGTH= 4;

_str def_vc_system;     //The current vcs


const VCGET=        'get';
const VCCHECKOUT=   'checkout';
const VCCHECKIN=    'checkin';
const VCUNLOCK=     'unlock';
const VCADD=        'add';
const VCLOCK=       'lock';
const VCREMOVE=     'remove';
const VCHISTORY=    'history';
const VCDIFF=       'difference';
const VCPROPERTIES= 'properties';
const VCMANAGER=    'manager';

const VCS_CHECKOUT=           VCCHECKOUT;
const VCS_CHECKIN_NEW=        VCADD;
const VCS_CHECKIN=            VCCHECKIN;
const VCS_CHECKOUT_READ_ONLY= VCGET;
const VCS_CHECKIN_DISCARD=    VCUNLOCK;
const VCS_PROPERTIES=         VCPROPERTIES;
const VCS_DIFFERENCE=         VCDIFF;
const VCS_HISTORY=            VCHISTORY;
const VCS_REMOVE=             VCREMOVE;
const VCS_LOCK=               VCLOCK;
const VCS_MANAGER=            VCMANAGER;

const NULL_COMMENT= "\0";

const READ_ONLY_ERROR_MESSAGE= 'This command is not allowed in read only mode';

  int _in_firstinit;

int _chdebug;
bool ginFunctionHelp;
bool gFunctionHelp_pending;

const RBFORM_CHECKBOXES= 0x1;

const DIFF_REPORT_CREATED=              0x1;
const DIFF_REPORT_LOADED=               0x2;
const DIFF_REPORT_DIFF=                 0x4;
const DIFF_REPORT_FILE_CHANGE=          0x8;
const DIFF_REPORT_COPY_FILE=           0x10;
const DIFF_REPORT_COPY_TREE=           0x20;
const DIFF_REPORT_COPY_TREE_FILE=      0x40;
const DIFF_REPORT_DELETE_FILE=         0x80;
const DIFF_REPORT_DELETE_TREE=        0x100;
const DIFF_REPORT_DELETE_TREE_FILE=   0x200;
const DIFF_REPORT_SAVED_DIFF_STATE=   0x400;
const DIFF_REPORT_SAVED_PATH1_LIST=   0x800;
const DIFF_REPORT_SAVED_PATH2_LIST=  0x1000;
const DIFF_REPORT_REFRESH_CHANGED=   0x2000;
const DIFF_REPORT_REFRESH_ALL=       0x4000;

/**
 * Set this variable to 1 to change the current working 
 * directory to the file that currently has focus in the editor.
 * This variable is on by default in the GNU Emacs emulation, 
 * and off in all other emulations. 
 * @categories Configuration_Variables 
 */ 
bool def_switchbuf_cd;
bool _hit_defmain;


const HKEY_CLASSES_ROOT=           ( 0x80000000 );
const HKEY_CURRENT_USER=           ( 0x80000001 );
const HKEY_LOCAL_MACHINE=          ( 0x80000002 );
const HKEY_USERS=                  ( 0x80000003 );
const HKEY_PERFORMANCE_DATA=       ( 0x80000004 );
const HKEY_CURRENT_CONFIG=         ( 0x80000005 );
const HKEY_DYN_DATA=               ( 0x80000006 );

const DIFF_LIST_FILE_EXT= 'dls';
const DIFF_STATEFILE_EXT= 'dif';

const VSIMPLEMENT_ABSTRACT=  0x1;

_metadata enum_flags VSCodeHelpFlags {
   VSCODEHELPFLAG_AUTO_FUNCTION_HELP                  =        0x1,
   VSCODEHELPFLAG_AUTO_LIST_MEMBERS                   =        0x2,
   // When on, pressing space bar during list members always
   // inserts a space.
   VSCODEHELPFLAG_SPACE_INSERTS_SPACE                 =        0x4,
   // When on, selecting an item in during list members which
   // requires an open paren,'<', or additional characters,
   // automatically inserts the additinal characters.
   VSCODEHELPFLAG_INSERT_OPEN_PAREN                   =        0x8,
   // When on, pressing space during list members completes
   // the word.
   VSCODEHELPFLAG_SPACE_COMPLETION                    =       0x10,
   // Get comments while doing list help or hover over
   VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS             =       0x20,
   // Get comments while doing function help
   VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS           =       0x40,
   // Disable auto syntax help on space key
   VSCODEHELPFLAG_AUTO_SYNTAX_HELP                    =       0x80,
   // Replace identifier, even part after cursor (default on)
   VSCODEHELPFLAG_REPLACE_IDENTIFIER                  =      0x100,
   // Preserve ideitifier, including part after cursor (default on)
   VSCODEHELPFLAG_PRESERVE_IDENTIFIER                 =      0x200,
   // Do automatic paramater completion (default on)
   VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION           =      0x400,
   // Do not insert space after comma for auto parameter completion (default on)
   VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA                =      0x800,
   // Do automatic paramater information (default on)
   VSCODEHELPFLAG_AUTO_LIST_PARAMS                    =     0x1000,
   // Do paramater type matching (default on)
   VSCODEHELPFLAG_PARAMETER_TYPE_MATCHING             =     0x2000,
   // Do not insert space after paren for auto parameter completion (default on)
   VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN                =     0x4000,
   // Reserved for future use
   VSCODEHELPFLAG_RESERVED_ON                         =     0x8000,
   // Strict list select?
   VSCODEHELPFLAG_STRICT_LIST_SELECT                  =    0x10000,
   // Display info when mouse hovers over a symbol?
   VSCODEHELPFLAG_MOUSE_OVER_INFO                     =    0x20000,
   // Do automatic listing of symbols with matching types on return, equals, etc
   VSCODEHELPFLAG_AUTO_LIST_VALUES                    =    0x40000,
   // Go to tag finds procs (definitions) first
   VSCODEHELPFLAG_FIND_TAG_PREFERS_DEFINITION         =   0x100000,
   // Go to tag finds prototypes (declarations) first
   VSCODEHELPFLAG_FIND_TAG_PREFERS_DECLARATION        =   0x200000,
   // Avoid going to the same tag the cursor is already on
   VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE          =   0x400000,
   // Do not show options for jump to proto / proc on Select Symbol dialog
   VSCODEHELPFLAG_FIND_TAG_HIDE_OPTIONS               =   0x800000,
   // Highlight matches for current symbol under cursor in buffer
   VSCODEHELPFLAG_HIGHLIGHT_TAGS                      =  0x1000000,
   // Go to tag includes forward class declarations (default is to ignore them)
   VSCODEHELPFLAG_FIND_FORWARD_CLASS_DECLARATIONS     =  0x2000000,
   // Use case sensitivity when completing identifiers
   VSCODEHELPFLAG_IDENTIFIER_CASE_SENSITIVE           =  0x4000000,
   // Use case sensitivity when on go to definition
   VSCODEHELPFLAG_GO_TO_DEF_CASE_SENSITIVE            =  0x8000000,
   // Use case sensitivity when using list members
   VSCODEHELPFLAG_LIST_MEMBERS_CASE_SENSITIVE         = 0x10000000,
   // Go to tag attempts to filter out overloaded function signatures
   VSCODEHELPFLAG_FILTER_OVERLOADED_FUNCTIONS         = 0x20000000,
   // Go to tag prefers to jump to symbols in current project
   VSCODEHELPFLAG_FIND_TAG_PREFERS_PROJECT            = 0x40000000,
   // Go to tag pops up message box when symbol is not found.
   VSCODEHELPFLAG_FIND_TAG_ERROR_NO_MESSAGE_BOX       = 0x80000000,

   // Go to tag only lists symbols in current workspace
   VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_WORKSPACE        = 0x100000000,
   // Go to tag only lists symbols in current project
   VSCODEHELPFLAG_FIND_TAG_SHOW_ONLY_PROJECT          = 0x200000000,

   // Evaluate and display return type of symbols on mouse-over (useful for mouse-over)
   VSCODEHELPFLAG_DISPLAY_RETURN_TYPE                 = 0x400000000,

   // Do not show preview of symbol under mouse?
   VSCODEHELPFLAG_NO_PREVIEW_INFO                     = 0x800000000,
   // Do not get comments when previewing symbol under mouse
   VSCODEHELPFLAG_PREVIEW_NO_COMMENTS                 = 0x1000000000,
   // Evaluate and display return type of symbols when previewing symbol
   VSCODEHELPFLAG_PREVIEW_RETURN_TYPE                 = 0x2000000000,

   // Auto-insert "ref" and "out" or other langauge-specific 
   // function parameter decorations during function help.
   VSCODEHELPFLAG_NO_INSERT_PARAMETER_KEYWORDS        = 0x4000000000,

   // Show statements in the Defs tool window for this language by default?
   VSCODEHELPFLAG_SHOW_STATEMENTS_IN_DEFS             = 0x8000000000,

   // Use subword matching when completing identifiers (reverse flag)
   VSCODEHELPFLAG_COMPLETION_NO_FUZZY_MATCHES         = 0x10000000000,
   // Use subword matching when completing identifiers (reverse flag)
   VSCODEHELPFLAG_COMPLETION_NO_SUBWORD_MATCHES       = 0x20000000000,
   // Use subword matching when using list members (reverse flag)
   VSCODEHELPFLAG_LIST_MEMBERS_NO_SUBWORD_MATCHES     = 0x40000000000,

   // Store documentation comments when tagging
   VSCODEHELPFLAG_NO_COMMENT_TAGGING                  = 0x80000000000,

   // Use subword matching on second attempt only
   VSCODEHELPFLAG_SUBWORD_MATCHING_ONLY_ON_RETRY      = 0x100000000000,
   // Initial subword matching looks for tags matching first char of pattern
   VSCODEHELPFLAG_SUBWORD_MATCHING_GLOBALS_FIRST_CHAR = 0x200000000000,
   // Limit subword matching to workspace tag files only
   VSCODEHELPFLAG_SUBWORD_MATCHING_WORKSPACE_ONLY     = 0x400000000000,
   // Limit subword matching to workspace tag files plus auto-updated tag files
   VSCODEHELPFLAG_SUBWORD_MATCHING_INC_AUTO_UPDATED   = 0x800000000000,
   // Limit subword matching to workspace tag files plus compiler tag files
   VSCODEHELPFLAG_SUBWORD_MATCHING_INC_COMPILER       = 0x1000000000000,
   // Relax symbol pattern matching character order constraints
   VSCODEHELPFLAG_SUBWORD_MATCHING_RELAX_ORDER        = 0x2000000000000,

   // Go to tag attempts to find all instances where a virtual
   // function is overridden in derived classes (reverse flag)
   VSCODEHELPFLAG_FIND_NO_DERIVED_VIRTUAL_OVERRIDES   = 0x10000000000000,

   // no flags
   VSCODEHELPFLAG_NULL = 0,
   // Default language specific flags
   VSCODEHELPFLAG_DEFAULT_FLAGS = VSCODEHELPFLAG_AUTO_FUNCTION_HELP|
                                  VSCODEHELPFLAG_AUTO_LIST_MEMBERS|
                                  VSCODEHELPFLAG_RESERVED_ON|
                                  VSCODEHELPFLAG_INSERT_OPEN_PAREN|
                                  VSCODEHELPFLAG_SPACE_INSERTS_SPACE|
                                  VSCODEHELPFLAG_DISPLAY_FUNCTION_COMMENTS|
                                  VSCODEHELPFLAG_DISPLAY_MEMBER_COMMENTS|
                                  VSCODEHELPFLAG_REPLACE_IDENTIFIER|
                                  VSCODEHELPFLAG_PRESERVE_IDENTIFIER|
                                  VSCODEHELPFLAG_AUTO_PARAMETER_COMPLETION|
                                  VSCODEHELPFLAG_NO_SPACE_AFTER_COMMA|
                                  VSCODEHELPFLAG_AUTO_LIST_PARAMS|
                                  VSCODEHELPFLAG_PARAMETER_TYPE_MATCHING|
                                  VSCODEHELPFLAG_NO_SPACE_AFTER_PAREN|
                                  VSCODEHELPFLAG_MOUSE_OVER_INFO|
                                  VSCODEHELPFLAG_FIND_TAG_PREFERS_ALTERNATE
};

/**
 * Bitset of VSCODEHELPFLAG_*
 *
 * @default VSCODEHELPFLAG_DEFAULT_FLAGS
 * @categories Configuration_Variables
 */
VSCodeHelpFlags def_codehelp_flags;

// Timeout for trying a UNC path \\server\share\...
int def_fileio_timeout;
// continue to timeout after failure of def_fileio_timeout for
// this amount of time.
int def_fileio_continue_to_timeout;
/**
 * Delay in milliseconds before Auto-display parameter information feature 
 * displays function help after you type a function call operator such as '('. 
 * Setting this to 0 means display help immediately.
 *
 * @default 0
 * @categories Configuration_Variables
 *
 * @see auto_codehelp_key
 */
int def_codehelp_idle;
/**
 * Amount of idle time in milliseconds before updating
 * the parameter list when parameter information is active
 * after a key is pressed (causing the word prefix under the
 * cursor to change).
 *
 * @default 50 ms (200 on Unix)
 * @categories Configuration_Variables
 */
int def_codehelp_key_idle;
/**
 * Amount of idle time in milliseconds before updating
 * the list of symbols when list members is active.
 *
 * @default 50 msg (400 on Unix)
 * @categories Configuration_Variables
 */
int def_memberhelp_idle;
/**
 * Amount of idle time in milliseconds before updating the
 * current context window, Defs tool window, and Symbol tool window.
 *
 * @default 500 ms (1000 on Unix)
 * @categories Configuration_Variables
 */
int def_update_tagging_idle;
/**
 * Amount of idle time in milliseconds to wait before updating the
 * current context window, Defs tool window, and Symbol tool window 
 * if we have already waited 'def_update_tagging_idle', but the 
 * background tagging has not yet updated the current context. 
 *
 * @default 250 ms
 * @categories Configuration_Variables
 */
int def_update_tagging_extra_idle;

/**
 * Specifies the amount of time in milliseconds to wait before starting 
 * to gather background tagging results. 
 * <p> 
 * This setting will also be used to calculate a minimum amount of idle
 * time to wait before processing background tagging jobs that require 
 * foreground tagging work, such as files containing embedded code or files 
 * that use a proc-search for finding symbols.  The idle time delay in 
 * microseconds for slower tagging jobs is calculated by multiplying 
 * this setting by 50 and adding 1 second. 
 *  
 * @default 100 ms
 * @categories Configuration_Variables
 */
int def_background_tagging_idle;
/**
 * Specifies the maximum amount of time in milliseconds to spend gathering 
 * background tagging results before returning control to the editor.
 * 
 * @default 1000 ms
 * @categories Configuration_Variables
 */
int def_background_tagging_timeout;
/**
 * Specifies the number of threads to dedicate to processing background tagging jobs. 
 * This setting requires you to restart the editor for a change to take effect. 
 * 
 * @default 4
 * @categories Configuration_Variables
 */
int def_background_tagging_threads;
/**
 * Specifies whether an additional tagging thread is dedicated to reading files 
 * from disk.  This improves performance by pipelining file reading and parsing. 
 * This option has no effect if {@link def_background_tagging_threads} == 0. 
 * This setting requires you to restart the editor for a change to take effect. 
 * 
 * @default 1
 * @categories Configuration_Variables
 */
int def_background_reader_threads;
/**
 * Specifies whether an additional tagging thread is dedicated to writing to the
 * tag database.  This improves performance by pipelining parsing and writing to 
 * the tag database.  In addition, it eliminaates contention for the tag database. 
 * This option has no effect if {@link def_background_tagging_threads} == 0. 
 * This setting requires you to restart the editor for a change to take effect. 
 * 
 * @default 1
 * @categories Configuration_Variables
 */
int def_background_database_threads;
/**
 * Specifies the maximum number of active background tagging jobs that can be 
 * in any stage of the background tagging queue.  This limit is in place to 
 * guard against background tagging using excessive amounts of memory while 
 * processing files. 
 * <p> 
 * This option has no effect if {@link def_background_tagging_threads} == 0. 
 * This setting requires you to restart the editor for a change to take effect. 
 * 
 * @default 1000
 * @categories Configuration_Variables
 */
int def_background_tagging_maximum_jobs;
/**
 * Specifies the maximum number of byes that should be devoted to 
 * background tagging jobs in any stage of the background tagging queue. 
 * This limit is in place to guard against background tagging using 
 * excessive amounts of memory while processing files. 
 * <p> 
 * This option has no effect if {@link def_background_tagging_threads} == 0. 
 * This setting requires you to restart the editor for a change to take effect. 
 * 
 * @default 32000 (32 megabytes)
 * @categories Configuration_Variables
 */
int def_background_tagging_max_ksize;
/**
 * Specifies that the background tagging engine should using an alternate 
 * technique to write to the database in order to minimize the amount of time 
 * the database is locked for writing.  This technique requires more memory because 
 * it caches copies of database blocks in memory while updating the database. 
 * This allows the main thread to continue reading the un-modified version of 
 * the database and the changes to be quickly swapped in after all the records 
 * have been updated in the background. 
 * <p> 
 * While there is no set limit on how much more memory this option uses, 
 * in general, it will require an additional 10-50M while background tagging 
 * is running. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_background_tagging_minimize_write_locking;

const VSCODEHELPDCLFLAG_VERBOSE=     0x1;
const VSCODEHELPDCLFLAG_SHOW_CLASS=  0x2;
const VSCODEHELPDCLFLAG_SHOW_ACCESS= 0x4;
const VSCODEHELPDCLFLAG_SHOW_INLINE= 0x8;
const VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF= 0x10;
const VSCODEHELPDCLFLAG_SHOW_STATIC= 0x20;

// p_ProtectReadOnlyMode values
const VSPROTECTREADONLYMODE_OPTIONAL= 0;
const VSPROTECTREADONLYMODE_ALWAYS=   1;
const VSPROTECTREADONLYMODE_NEVER=    2;

bool def_word_continue;

const VSCURWORD_WHOLE_WORD=       0;
const VSCURWORD_FROM_CURSOR=      1;
const VSCURWORD_AT_END_USE_PREV=  2;
const VSCURWORD_BEFORE_CURSOR=    3;


/**
 * Lists keys under path specified.
 * 
 * @param root           one of the HKEY_* constants
 * @param subKey         name of subkey
 * @param array          Keys are added or appended to this array.
 * @param appendKeys     When true, keys are added to array instead 
 *                       of the array being cleared first.
 * 
 * @return int           0 for success, non-zero for error
 */
extern int _ntRegListKeys(int root, _str subkey, _str (&array)[], bool doAppend=false);
/**
 * Retrieves the data value from the given subkey.
 * 
 * @param root 
 * @param subkey 
 * @param defaultValue 
 * 
 * @return _str
 *
 * @categories Miscellaneous_Functions
 */
extern _str _ntRegQueryValue(int root, _str subkey, _str defaultValue = "", _str valueName = "");

/**
 * Retrieves a name/value pair from a subkey.
 * 
 * @param root                      one of the HKEY_* constants
 * @param _strSubKeyName            name of subkey
 * @param hvarValName               (by-ref) name
 * @param hvarValVal                (by-ref) value
 * @param FindFirst                 1 to find the first pair, 0 to find the next 
 *                                  pair, -1 to close the key
 *  
 * Note that after opening a subkey to look at its data, you must call this 
 * function with FindFirst set to -1 to close the key and clean up after 
 * yourself. 
 * 
 * @return int                      0 on success, 1 on error, 2 if no more keys 
 *                                  can be found
 *  
 * @categories Miscellaneous_Functions
 */
extern int _ntRegFindFirstValue(int root,_str _strSubKeyName,_str &hvarValName,_str &hvarValVal, int findFirst);

/**
 * Retrieves a subkey from a parent key.
 * 
 * @param root                      one of the HKEY_* constants
 * @param _strSubKeyName            path of subkey
 * @param hvarValName               (by-ref) name
 * @param FindFirst                 1 to find the first pair, 0 to find the next 
 *                                  pair, -1 to close the key
 *  
 * Note that after opening a subkey to look at its data, you must call this 
 * function with findFirst set to -1 to close the key and clean up after 
 * yourself. 
 * 
 * @return int                      0 on success, 1 on error, 2 if no more keys 
 *                                  can be found
 *  
 * @categories Miscellaneous_Functions
 */
extern int _ntRegFindFirstSubKey(int root,_str _strSubKeyPath, _str &hvarKeyName, int findFirst);

/**
 * Finds the latest version subkey underneath the given subkey.
 * 
 * @param root                      one of the HKEY_* constants
 * @param subkey                    path of subkey
 * @param version                   (by-ref) latest version found
 * @param requiredMajor             (optional) if you require a particular major 
 *                                  version, send it here, otherwise use 0.
 * 
 * @return int                      0 on success, non-zero on error 
 *  
 * @categories Miscellaneous_Functions
 */
extern int _ntRegFindLatestVersion(int root, _str subkey, _str &version, int requiredMajor = 0);

/**
 * Retrieves a data value from the latest version subkey underneath the given 
 * subkey.   
 * 
 * @param root                      one of the HKEY_* constants
 * @param prefixPath                path of subkey which contains version 
 *                                  subkeys
 * @param suffixPath                additional path to be added to the version 
 *                                  subkeys  
 * @param valueName                 name of data value to fetch
 * 
 * @return _str                     retrieved data value, "" if none is found 
 *  
 * @categories Miscellaneous_Functions
 */
extern _str _ntRegGetLatestVersionValue(int root, _str prefixPath, _str suffixPath, _str valueName);

/**
 * Check if calling find first for the UNC path specified will 
 * succeed in a short amount of time. 
 *  
 * <p> In the future, this function can be modified to support 
 * all UNC paths (like \\server or \\server\share.  Also, this 
 * could be enhanced to support non-UNC paths.
 *  
 * @param pszFilename
 * @param milliTimeout
 * @param milliContinueToFail
 * 
 * @return Returns true if calling find first for the UNC path 
 *         specified will succeed in a short amount of time.
 *         Some invalid paths return quickly with failure.
 */
extern bool _findFirstTimeOut(_str pszFilename, int milliTimeout,int milliContinueToFail);

extern int _fileIOTimeOut(_str pszFilename, int milliTimeout);


struct AUTORELOAD_FILE_INFO {
   _str bfileDate;
   int readOnly;
};
/**
 * @param fileInputList List of files to check to see if they 
 *                      are fast enough to reload
 * @param fileOutputList Hash table of files that are OK for 
 *                       reload. The table is indexed by the
 *                       names. Use
 *                       fileOutputTable._indexin(_file_case(filename))
 *                       to check if a file is OK to reload
 * @param milliTimeout Amount of time to wait on a file before 
 *                     marking it slow. This is also how long we
 *                     will wait on a batch of files, but the
 *                     thread will continue to run, so other
 *                     files will be reloaded on subsequent
 *                     tries
 * @param getReadOnlyInfo set to 1 to get auto reload 
 *                        information
 * @param  fastReadonly set to 1 if we are using fast readonly
 * 
 * @return int 0 if successful
 */
extern int _GetFastReloadInfoTable(_str (&fileInputList)[],int getReadOnlyInfo,int fastReadonly,AUTORELOAD_FILE_INFO (&fileOutputTable):[],int milliTimeout);


/**
 * 
 * @param fileOutputList List of files that are slow and will 
 *                       not be reloaded
 * 
 * @return int 0 if successful
 */
extern int _GetSlowReloadFiles(_str (&fileOutputTable):[]);


const VSCHARSET_ANSI=            0;
const VSCHARSET_DEFAULT=         1;
const VSCHARSET_SYMBOL=          2;
const VSCHARSET_SHIFTJIS=        128;
const VSCHARSET_HANGEUL=         129;
const VSCHARSET_GB2312=          134;
const VSCHARSET_CHINESEBIG5=     136;
const VSCHARSET_OEM=             255;
const VSCHARSET_JOHAB=           130;
const VSCHARSET_HEBREW=          177;
const VSCHARSET_ARABIC=          178;
const VSCHARSET_GREEK=           161;
const VSCHARSET_TURKISH=         162;
const VSCHARSET_THAI=            222;
const VSCHARSET_EASTEUROPE=      238;
const VSCHARSET_RUSSIAN=         204;
const VSCHARSET_MAC=             77;
const VSCHARSET_BALTIC=          186;
const VSCHARSET_VIETNAMESE=      163;

const VSCOBOL_SQL_LEXER_NAME=    "def-cobol-sql-lexer-name";
const VSHTML_ASP_LEXER_NAME=     "def-html-asp-lexer-name";


const VC_ADVANCED_PROJECT=       0x1;
const VC_ADVANCED_BUFFERS=       0x2;
const VC_ADVANCED_AVAILABLE=     0x4;
const VC_ADVANCED_NO_SAVE_FILES= 0x8;
const VC_ADVANCED_NO_PROMPT=     0x10;

int def_vc_advanced_options;
int def_smart_diff_limit;
int def_smart_diff_iterations;
int def_max_diff_markup;
int def_max_fast_diff_size;
int def_optimize_sccprjfiles;

/**
 * When using source diff, this array specifies a list of token 
 * exclusion mappings to indicate that certain token differences can be 
 * treated as if they were merely whitespace.  This is helpful when a large 
 * number of symbols have been renamed and you are trying to compare files 
 * to find more significant changes. 
 *  
 * Each item in the array is of the form: 
 * <pre>
 *    left_token_text;right_token_text
 * </pre> 
 * Duplicate entries are allowed.
 *  
 * @default null
 * @categories Configuration_Variables
 *
 * @see diff
 */
_str def_sourcediff_token_mappings[];


const PROJECT_TOOLBAR_NAME= '_proj_tooltab_tree';

int def_record_dataset_mode;   // For now set this to 0 or 1

const REGULAR_ALIAS_FILE= 0;
const DOCCOMMENT_ALIAS_FILE= 1;
const SYMTRANS_ALIAS_FILE= 2;
/**
 * Controls whether aliases are case sensitive ('e') or not ('i').
 *
 * @default 'e'
 * @categories Configuration_Variables
 *
 * @see expand_alias
 */
_str def_alias_case;
/**
 * Stores long version of days of the week as a space separated list.  Used by 
 * alias mechanism to translation the %\h% (user formatted date) escape 
 * sequence. 
 * 
 * @default "Sunday Monday Tuesday Wednesday Thursday Friday Saturday"
 * @categories Configuration_Variables
 */
_str def_long_weekday_names;
/**
 * Stores short version of days of the week as a space separated list.  Used by 
 * alias mechanism to translation the %\h% (user formatted date) escape 
 * sequence. 
 * 
 * @default "Sun. Mon. Tues. Wed. Thur. Fri. Sat."
 * @categories Configuration_Variables
 */
_str def_short_weekday_names;
/**
 * Stores long version of the months of the year as a space separated list. Used
 * by alias mechanism to translation the %\h% (user formatted date) escape 
 * sequence. 
 * 
 * @default "January February March April May June July August September October November December"
 * @categories Configuration_Variables
 */
_str def_long_month_names;
/**
 * Stores short version of the months of the year as a space separated list. 
 * Used by alias mechanism to translation the %\h% (user formatted date) escape 
 * sequence. 
 * 
 * @default "Jan. Feb. Mar. Apr. May June July Aug. Sept. Oct. Nov. Dec."
 * @categories Configuration_Variables
 */
_str def_short_month_mames;

int _loadrc;
const EB_ASCII_0= 48;
const EB_ASCII_9= 57;
const EB_ASCII_a= 97;
const EB_ASCII_z= 122;
const EB_ASCII_A= 65;
const EB_ASCII_Z= 90;
const EB_ASCII_SPACE= 32;
const EB_ASCII_UNDERSCORE= 95;

int _ftpsave_override;

_str _last_open_path;
_str _last_open_cwd;

// Common to all beautifiers/formatters
_str _format_user_ini_filename;

// cformat
const CF_DEFAULT_SCHEME_NAME= "Default";

// hformat
const HF_DEFAULT_SCHEME_NAME= "Default";

// adaformat
const ADAF_DEFAULT_SCHEME_NAME= "Default";

_metadata enum KeywordCaseValues {
   WORDCASE_PRESERVE       = -1,
   WORDCASE_LOWER          = 0,
   WORDCASE_UPPER          = 1,
   WORDCASE_CAPITALIZE     = 2,
};

/**
 * This list gets looked at for automatically generated commands
 * like project commands.and when ENTER is pressed in the build window.
 *
 * @default Windows:  'vsbuild java pkzip pkunzip unzip';
 *          Unix:     'vsbuild java ls echo cp mv rm mkdir rmdir cd diff find more sed set export setenv'
 * @categories Configuration_Variables
 */
_str def_no_error_info_commands2;
/**
 * This list is examined when certain commands, such as project 
 * commands, are automatically generated and when ENTER is pressed in 
 * the build window. 
 *  
 * <p> This is a list of commands for which we do not need to insert 
 * the current directory. 
 *
 * @default Windows:  'cl javac sj sgrep vst msdev';
 *          Unix:     'cc CC gcc g++ vst javc sgrep c89 c++ vscomp.rexx'
 * @categories Configuration_Variables
 */
_str def_no_error_info_commands;
/**
 * This regular expression gets looked at when you press ENTER in the
 * build window.
 *
 * @default '^?*make?*$';
 * @categories Configuration_Variables
 */
_str def_error_info_commands_re;

/**
 * This list gets looked at for automatically generated commands
 * like project commands and when ENTER is pressed in
 * the build window.
 */
_str def_error_info_commands;

_str _extra_word_chars;
struct VSPRINTOPTIONS{  // Used by _PrintPreview_form
   _str print_font;
   _str print_header;
   _str print_footer;
   _str print_options;
   _str print_cheader;
   _str print_cfooter;
   _str print_rheader;
   _str print_rfooter;
};
VSPRINTOPTIONS gvsPrintOptions;
struct SEQtPrintOptions {
   _str m_deviceName;
   bool m_landscape;
   bool m_selection;
   bool m_haveSelection;
   int m_copyCount;
   bool m_collate;
};
struct SEQtPageSetupOptions {
   bool m_landscape;
};
extern int _QtPageSetupDialog(SEQtPrintOptions &options,bool show);
extern int _QtPrintDialog(SEQtPrintOptions &options,bool show);
extern void _QtPrintDialogRestore(SEQtPrintOptions &options);

const END_SENTENCE_CHARS= '.!?';
const END_OF_SENTENCE_RE= '((.|!|\?)[.!?"'')\]]*\c($|  ))';
const PARAGRAPH_SKIP_CHARS= ' \t';
const PARAGRAPH_SEP_RE=      ('(^['PARAGRAPH_SKIP_CHARS']*$)');
const SKIP_PARAGRAPH_SEP_RE= ('^~(['PARAGRAPH_SKIP_CHARS']*$)');
struct PackageInfo {
   _str filename;
   _str section;
};
// ProjectConfig defines all the values for a project configuration.
struct ProjectConfig {
   _str config; // configuration name
   _str objdir; // object directory
   PackageInfo CopyFrom; //Only for creating a new one.
};
bool _mfrefIsActive;
bool _mfXMLOutputIsActive;

// ProjectPacks defines all the values for a project pack.
bool def_error_check_help_items;

/**
 * Set this to 'false' to disable all AutoSave and Context Tagging&reg; 
 * timer functions.  This is for debugging purposes only.  This 
 * variable should NEVER be modified programatically.  If you want to 
 * just turn off timers temporarily use _use_timers instead. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_use_timers/*=true*/;
/**
 * This variable can be used to temporarily disable all AutoSave
 * and Context Tagging&reg; timer functions.  This is reset to 1 
 * every time the editor is started.  To permanently disable 
 * timer functions, set def_use_timers to 0. 
 */
int _use_timers/*=1*/;


const VSJAVADOCFLAG_BEAUTIFY=                     0x1;
const VSJAVADOCFLAG_ALIGN_PARAMETERS=             0x2;
const VSJAVADOCFLAG_ALIGN_EXCEPTIONS=             0x4;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS=  0x8;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN=      0x10;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION= 0x20;
const VSJAVADOCFLAG_ALIGN_RETURN=                 0x40;
const VSJAVADOCFLAG_ALIGN_DEPRECATED=             0x80;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE=     0x100;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM=  0x200;
const VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS=     0x400;
const VSJAVADOCFLAG_DEFAULT_ON=                   (0xffff00);
/**
 * These setting is used by the JavaDoc editor when reformatting
 * JavaDoc comments.  This is a bitset of VSJAVADOCFLAG_*.
 * <ul>
 * <li>VSJAVADOCFLAG_BEAUTIFY
 * -- Beautify JavaDoc comments when exiting the JavaDoc editor
 * <li>VSJAVADOCFLAG_ALIGN_PARAMETERS
 * -- Align function parameters
 * <li>VSJAVADOCFLAG_ALIGN_EXCEPTIONS
 * -- Align exception names
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS
 * -- Add blank line after parameter list
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN
 * -- Add blank line after @return statement
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION
 * -- Add blank line after symbol's description
 * <li>VSJAVADOCFLAG_ALIGN_RETURN
 * -- Align comments for @return statement
 * <li>VSJAVADOCFLAG_ALIGN_DEPRECATED
 * -- Align comments for @deprecated
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE
 * -- Add balnk line after example
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM
 * -- Add blank line after last parameter comment
 * <li>VSJAVADOCFLAG_BLANK_LINE_AFTER_REMARKS
 * -- Add blank line after remarks (XMLDOC)
 * </ul>
 *
 * @categories Configuration_Variables
 */
int def_javadoc_format_flags;
/**
 * Minimum number of characters for parameter names.
 * This setting is used by the JavaDoc editor when
 * reformatting JavaDoc comments.
 *
 * @default 6
 * @categories Configuration_Variables
 */
int def_javadoc_parammin;
/**
 * Maximum number of characters for parameter names.
 * This setting is used by the JavaDoc editor when reformatting
 * JavaDoc comments.  If the name is longer than this, the
 * parameter comment will be continued on the next line.
 *
 * @default 10
 * @categories Configuration_Variables
 */
int def_javadoc_parammax;
/**
 * Minimum number of characters for exception names.
 * This setting is used by the JavaDoc editor when
 * reformatting JavaDoc comments.
 *
 * @default 6
 * @categories Configuration_Variables
 */
int def_javadoc_exceptionmin;
/**
 * Maximum number of characters for exception names.
 * This setting is used by the JavaDoc editor when reformatting
 * JavaDoc comments.  If the name is longer than this, the
 * exception comment will be continued on the next line.
 *
 * @default 10
 * @categories Configuration_Variables
 */
int def_javadoc_exceptionmax;

bool def_project_auto_build;

_command void cmdclear_message();
_command void key_not_defined();
_command undo();
_command undo_cursor();
_command redo();
_command void nosplit_insert_line();
_command void split_insert_line();
_command void maybe_split_insert_line();


_command void ctab();

_command void cbacktab();
_command void move_text_tab();
_command void move_text_backtab();
_command scroll_begin_line();
_command scroll_end_line();

_command void begin_line();


_command void begin_line_text_toggle();


_command void first_non_blank(_str extra_search_option="");
_command void last_non_blank(_str extra_search_option="");


_command void end_line();
_command void end_line_text_toggle();


_command int cursor_up(_str count="",_str doScreenLines="");


_command int cursor_down(_str count="",_str doScreenLines="");
_command void top_of_buffer();



_command void bottom_of_buffer();
_command void page_up();
_command void page_down();


_command void cursor_left(...);


_command void cursor_right(...);


_command void delete_char(_str force_wrap="");
_command void linewrap_delete_char();
_command void rubout(_str force_wrap="");
_command void linewrap_rubout();
_command void top_of_window();


_command void bottom_of_window();
_command void split_line();
_command int join_line(_str stripLeadingSpaces="");


_command int begin_select(_str markid="",bool LockSelection=true,bool RestoreScrollPos=false);

_command end_select(_str markid="");
_command void select_line();
_command void select_block();
_command void select_char();


_command void deselect();


_command int copy_to_cursor(...);
_command int move_to_cursor(...);

_command void delete_selection();
_command void gui_fill_selection();


_command fill_selection(...);
_command adjust_block_selection();
_command void overlay_block_selection();
_command void shift_selection_left(...);
_command void shift_selection_right(...);
_command void quote_key();
_command void insert_toggle();

_command void cmdline_toggle();
_command void normal_character();
_command void keyin_buf_name();
_command void nothing();
_command void retrieve_prev();
_command void retrieve_next();
_command nf();
_command void version();

_command cap_word();
_command void begin_word();
_command void next_word();
_command void prev_word();
_command void select_word();
_command void line_to_top();
_command void line_to_bottom();
_command upcase_word();
_command lowcase_word();


_command copy_word();


_command void fundamental_mode();

_command void count_lines();

_command int cload(_str filename="",_str only_convert_profile_name="");


_command color_modified_toggle();
_command color_language_toggle();

_command color_toggle();
_command keyin_space();
_command keyin_enter();

_command delete_word();


_command cut_word();
_command void next_word();

_command int save(_str cmdline="",int flags= -1);


_command void c_endbrace();
_command wh(_str word="");
_command void re_toggle();

_command void case_toggle();
_command void list_symbols();
_command void codehelp_complete();
_command void function_argument_help();
_command int paste(_str name="",bool isClipboard=true,_str overide_mark_type='', int overide_lines_per_cursor=0, _str override_strip_spaces_option='',int MarkFlags=-1);


_command void cua_select();


_command int copy_to_clipboard(_str name="",int MarkFlags=-1);
_command int mou_click(_str mark_name="",
                       _str option="",  /* C, M, or E  == Copy, Move, Extend */
                       bool select_words=false,
                       int add_cursor=0);
_command void mou_extend_selection();
_command void mou_select_line();

/**
 * @return Returns number of lines to scroll for wheel_down and
 *         wheel_up events.
 */
int mou_wheel_scroll_lines();

/**
 * @return Returns number of characters to scroll for wheel_left
 *         and wheel_right events.
 */
int mou_wheel_scroll_chars();

void save_pos(typeless &p, typeless useRealLineNumbers="");
void restore_pos(typeless p);
_str get_extension(_str buf_name,bool returnDot=false);
void split(_str delimited_string, _str delimiter, _str (&string_array)[]);
void _UpdateSlickCStack(int ignoreNStackItems=0,int errorCode=0,_str DumpFileName="");
void messageNwait(_str msg="");

/**
 * List of file extensions of files that are identified to
 * the project system as dependencies when loading a project
 * from a Makefile.
 *
 * @default ".h .hpp .hxx"
 * @categories Configuration_Variables
 */
_str def_add_to_prj_dep_ext;

/**
 * Control References tool window behavior options. 
 * Consists of a bitset of VSREF_* flags.
 * <ul>
 * <li><b>VSREF_FIND_INCREMENTAL      </b> -- If on, reference queries are faster because analysis stops when a file is found containing a valid reference. When set to Off, all files with potential references are searched and analyzed so that the files which do not contain any references are removed.
 * <li><b>VSREF_DO_NOT_GO_TO_FIRST    </b> -- If off, Go to Reference searches for references but does not jump immediately to the first reference. When on, Go to Reference searches for references and automatically jumps to the first one.
 * <li><b>VSREF_NO_WORKSPACE_REFS     </b> -- If on, newly created workspace and project tag files are not built with support for symbol cross-references.
 * <li><b>VSREF_HIGHLIGHT_MATCHES     </b> -- If on, each reference is highlighted within files.
 * <li><b>VSREF_SEARCH_WORDS_ANYWAY   </b> -- If on, Go to Reference will search for simple word matches if the symbol under the cursor is not found by Context Tagging®
 * <li><b>VSREF_ALLOW_MIXED_LANGUAGES </b> -- If on, allow the system to also search for references in files that do not match the source language for the symbol in question.
 * <li><b>VSREF_NO_AUTO_PUSH          </b> -- If off, Go to Reference will always create a new item on the top of the references stack.  If not enabled, you can still manually add searches to the stack using the 'Add' tool button on the References tool window.
 * <li><b>VSREF_NO_AUTO_POP           </b> -- If off, Pop Bookmark will automatically remove the top-most item from the references stack if the originating bookmark was created using Go to Reference.
 * <li><b>VSREF_NO_AUTO_FINISH        </b> -- If off, Find Next will automatically remove the top-most item from the references stack when there are no more occurrences.
 * <li><b>VSREF_NO_HIGHLIGHT_ALL      </b> -- If off, only the current set of references will be highlighted, not each one on the references stack.
 * </ul>
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_references_options;

const MACRO_MAKE_RE= '(tornadomake|javaviewdoc|tornadorebuild)([ \t]|$)';

// p_LCBufFlags
const VSLCBUFFLAG_READWRITE=          0x1;  /* prefix area on/off*/
const VSLCBUFFLAG_LINENUMBERS=        0x2;  /* Line numbers on/off */
const VSLCBUFFLAG_LINENUMBERS_AUTO=   0x4;  /* Line numbers automatic*/
//#define VSLCBUFFLAG_LEADINGZEROS  0x4

struct VSSEARCH_BOUNDS {
   //_str searchString;
   //_str replaceString;
   //_str searchOptions;   // E, I, R, W:PS W:SS W (CH=X XH=NX default=H)
   _str startLabel;
   _str endLabel;
   int startCol;     // -1==null
   int endCol;       // -1==null
   _str startCmd;    // FIRST, LAST, PREV, NEXT, ALL, ALLLAST
   bool result_doAll; // Set by find()
   int result_startCol;  // Set by find()
   int result_endCol;    // Set by find()
   _str orig_searchString;  // Unprocessed search string
   _str searchOptions;
};
 VSSEARCH_BOUNDS old_search_bounds;
const VSLCFLAG_ERROR=         0x1;
const VSLCFLAG_CHANGE=        0x2;
const VSLCFLAG_BOUNDS=        0x4;
const VSLCFLAG_MASK=          0x8;
const VSLCFLAG_COLS=          0x10;
const VSLCFLAG_TABS=          0x20;

_metadata enum_flags VSRenumberFlags {
   VSRENUMBER_DUMMY  = 0x1,    // This flag is taken because of multiline-if (fortran)
   VSRENUMBER_COBOL  = 0x2,    // number for COBOL (columns 1-6)
   VSRENUMBER_STD    = 0x4,    // number for standard number columns (73-80)
   VSRENUMBER_ALL    = (VSRENUMBER_COBOL|VSRENUMBER_STD),
};

/**
 * ISPF Emulation options.
 * Contains a bitset of VSISPF_* flags:
 * <ul>
 * <li><b>VSISPF_RIGHT_CONTROL_IS_ENTER</b>
 * <li><b>VSISPF_CURSOR_TO_LC_ON_ENTER</b>
 * </ul>
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_ispf_flags;
/**
 * Enable XEDIT extensions to ISPF emulation?
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_ispf_xedit;
_str def_page;
bool _dos_NextErrorIfNonZero;
bool _dos_quiet;

/**
 * If non-zero, reset-next-error is called.
 * before a compile or make commands is executed.
 *
 * @default ""
 * @categories Configuration_Variables
 *
 * @see dos
 * @see _project_command
 */
_str def_auto_reset;

//bool def_ispf_autosave;
bool ispf_process_return(bool nullReturn);

const TREE_BUTTON_PUSHED=     0x1;

//These are mutually exclusive
const TREE_BUTTON_PUSHBUTTON= 0x2;
const TREE_BUTTON_STICKY=     0x4;

const TREE_BUTTON_SORT=            0x8;
const TREE_BUTTON_SORT_EXACT=      0x10;
const TREE_BUTTON_SORT_DESCENDING= 0x20;  //Do not specify this flag,used internally
const TREE_BUTTON_SORT_NUMBERS=    0x40;
const TREE_BUTTON_SORT_FILENAME=   0x80;

const TREE_BUTTON_AL_RIGHT=        0x100;
const TREE_BUTTON_AL_CENTER=       0x200;

// This flag is no longer used, use _TreeSetColEditStyle 
// and_TreeSetNodeEditStyle with the TreeEditStyle flags instead
//#define TREE_BUTTON_EDITABLE        0x400

const TREE_BUTTON_WRAP=            0x800;
const TREE_BUTTON_FIXED_WIDTH=     0x1000;
const TREE_BUTTON_AUTOSIZE=        0x2000;  // Currently only works on the last button
const TREE_BUTTON_IS_FILENAME=     0x4000;  // Elide filename if column isn't wide enough

// This flag is no longer used, use _TreeSetColEditStyle 
// and_TreeSetNodeEditStyle with the TreeEditStyle flags instead
//#define TREE_BUTTON_COMBO           0x8000

const TREE_BUTTON_IS_DATETIME=      0x10000;  // localize from _time('B')
const TREE_BUTTON_SORT_COLUMN_ONLY= 0x20000;  // only sort by the selected column

const TREE_BUTTON_SORT_DATE=               0x40000;  // Can be used in conjunction with TREE_BUTTON_SORT_TIME
const TREE_BUTTON_SORT_TIME=               0x80000;  // Can be used in conjunction with TREE_BUTTON_SORT_DATE

const TREE_BUTTON_DYNAMIC_WIDTH=     0x100000; // Tree column resizes automatically to contents
const TREE_BUTTON_SORT_NONE=         0x200000; // Do not sort this column

enum TreeEditStyle {
   TREE_EDIT_TEXTBOX                = 0x1,
   TREE_EDIT_COMBOBOX               = 0x2,
   TREE_EDIT_EDITABLE_COMBOBOX      = 0x4,
   TREE_EDIT_BUTTON                 = 0x8,
};

const TREE_GRID_NONE= 0x0;
const TREE_GRID_HORZ= 0x1;
const TREE_GRID_VERT= 0x2;
const TREE_GRID_BOTH= 0x3;
const TREE_GRID_ALTERNATE_ROW_COLORS= 0x4;

const VSMIGFLAG_ALIASES=        0x1;
const VSMIGFLAG_COMMENTSTYLE= 0x2;
const VSMIGFLAG_COLORCODING=  0x4;
const VSMIGFLAG_BEAUTIFIER=   0x8;
const VSMIGFLAG_VCS=          0x10;
const VSMIGFLAG_PACKAGES=     0x20;
const VSMIGFLAG_FTP=          0x40;
const VSMIGFLAG_COLORSCHEMES= 0x80;
const VSMIGFLAG_PRINTSCHEMES= 0x100;
int def_migrate_flags;

const VSMHFINDANAMEFLAG_INCREASE_HEIGHT= 0x1;
const VSMHFINDANAMEFLAG_CENTER_SCROLL=   0x2;

/**
 * Expected indentation columns corresponding to different
 * cobol data section level numbers.  Speace separated list
 * of pairs (level=column).
 *
 * @default "01=8 03=12 05=16 07=20 77=8 88=8";
 * @categories Configuration_Variables
 */
_str def_cobol_levels;

/**
 * If true, interpret style 3 braces (as shown in the
 * C extension options dialog, as the following:
 * <pre>
 *    if (cond)
 *       {
 *          ++i;
 *       }
 * </pre>
 * instead of the default behavior of:
 * <pre>
 *    if (cond)
 *       {
 *       ++i;
 *       }
 * </pre>
 *
 * @default false
 * @categories Configuration_Variables
 */
int def_style3_indent_all_braces;

/**
 * When doing syntax expansion for C-like languages,
 * if the user typed "} else" or "}else", always
 * prompt to expand "else" or "else if".  Otherwise,
 * you are only prompted if "else" is incomplete,
 * like "} el[Space]".
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_always_prompt_for_else_if;


/**
 * Indent C++ member access specifiers, public: private: 
 * protected: in classes and structs.  False indicates to indent 
 * with class/struct column. 
 *  
 * @default false
 * @categories Configuration_Variables
 */
bool def_indent_member_access_specifier;

/**
 * When deleting an open brace from a brace block
 * that encloses a single line statement, leave
 * the statement hanging instead of pulling it up
 * to the same line if the current column is greater
 * than or equal to this value.  To always force
 * hanging statements, set this number to 0.
 * 
 * @example
 * <pre>if (condition)
 *    doSomething();</pre>
 * 
 * instead of
 * <pre>if (condition) doSomething();</pre>
 * 
 * @default 40
 * @categories Configuration_Variables
 */
int def_hanging_statements_after_col;

/**
 * This option controls the behavior of the active code block surround
 * mode.  It consists of a set of bit flags of VS_SURROUND_MODE_*.
 * <ul>
 * <li>VS_SURROUND_MODE_ENABLED   -- Enable dynamic surround
 * <li>VS_SURROUND_MODE_DRAW_BOX  -- Draw box around surround block
 * <li>VS_SURROUND_MODE_JUMP_FAST -- Jump over block statements
 * <li>VS_SURROUND_MODE_EDITABLE  -- Allow primitive editing
 * </ul>
 *
 * @default 0xFFFF
 * @categories Configuration_Variables
 */
int def_surround_mode_flags/*=0xffff*/;

const VS_SURROUND_MODE_ENABLED=    0x0001;
const VS_SURROUND_MODE_DRAW_BOX=   0x0002;
const VS_SURROUND_MODE_JUMP_FAST=  0x0004;
const VS_SURROUND_MODE_EDITABLE=   0x0008;
const VS_SURROUND_MODE_DRAW_ARROW= 0x0010;


_str _html_tempfile; //Used for running applets
_str _vcpp_compiler_option_tempfile; //Used for options to compile files
#define C_DEL_TAG_PREFIX "//DEL "

struct WIZARD_INFO {
   _str parentFormName;
   typeless callbackTable:[];
   _str dialogCaption;
   typeless wizardData;
};

#define VSSAMPLEWORKSPACECPP   ("ucpp":+_FILESEP)
#define VSSAMPLEWORKSPACECLANG ("clang":+_FILESEP)
#define VSSAMPLEWORKSPACEJAVA  ("java":+_FILESEP)

enum_flags WorkspaceHistoryOptions {
   WORKSPACE_OPT_COPYSAMPLES,
   WORKSPACE_OPT_NO_PROJECT_HIST,
   WORKSPACE_OPT_NO_SORT_PROJECTS,
   WORKSPACE_OPT_NONE=0x0
};

/**
 * This option controls workspace behavior. 
 * It consists of a set of bit flags of WORKSPACE_OPT_* 
 * <ul> 
 * <li>WORKSPACE_OPT_COPYSAMPLES</li>  -- Copy sample workspaces to configuration directory 
 * <li>WORKSPACE_OPT_NO_PROJECT_HIST</li> -- Do not track current active project along with workspace history 
 * <li>WORKSPACE_OPT_NO_SORT_PROJECTS</li> -- Do not sort workspaces and project names under the All Workspace menu
 * </ul>
 *
 * @default WORKSPACE_OPT_COPYSAMPLES
 * @categories Configuration_Variables
 */
WorkspaceHistoryOptions def_workspace_flags;

_str def_tornado_version;
int _trialMessageDisplayedFlags1;
bool def_focus_select;
const NULL_MARKID=  -1;


const VSXML_VALIDATION_SCHEME_WELLFORMEDNESS=  0x1;
const VSXML_VALIDATION_SCHEME_VALIDATE=        0x2;
const VSXML_VALIDATION_SCHEME_AUTO=            (VSXML_VALIDATION_SCHEME_WELLFORMEDNESS | VSXML_VALIDATION_SCHEME_VALIDATE);



const VSXMLCFG_FIND_APPEND=       0x1;
const VSXMLCFG_FIND_VALUES=       0x2;

const VSXMLCFG_ELEMENT_START=                   0x1;
const VSXMLCFG_ELEMENT_END=                     0x2;
const VSXMLCFG_ELEMENT_XML_DECLARATION=         0x4;
const VSXMLCFG_ELEMENT_PROCESSING_INSTRUCTION=  0x8;
const VSXMLCFG_ELEMENT_COMMENT=                 0x10;
const VSXMLCFG_ELEMENT_DOCTYPE=                 0x20;

//#define VSXMLCFG_SAVE_ALL_ON_ONE_LINE              0x1
const VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR=         0x2;
const VSXMLCFG_SAVE_DOS_EOL=                      0x4;
const VSXMLCFG_SAVE_UNIX_EOL=                     0x8;
const VSXMLCFG_SAVE_SPACE_AROUND_EQUAL=           0x10;
const VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE= 0x20;
// PCDATA will not be automatically indented on a new line
// Ideal for cases like: <Tag>Value</Tag>
const VSXMLCFG_SAVE_PCDATA_INLINE=                0x40;
// Add a trailing space after the last attribute quote, but only
// on nodes that are solely attributed.
// Example: <MyTag Name="Tag2" Value="Whatever" />
// This is a special case for Visual Studio XML project formats
// It includes the VSXMLCFG_SAVE_ALL_ON_ONE_LINE flag
const VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE=      0x100;
const VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE=            0x200;
const VSXMLCFG_SAVE_SPACE_AFTER_LAST_ATTRIBUTE=   (0x80 | VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE);

const VSXMLCFG_SAVE_PRESERVE_PCDATA=             0x800;
/* For PCDATA nodes created after the file is opened,
   add the current indent level to the indent of pcdata text.
   This is has no effect if the pcdata is on one line.
*/
const VSXMLCFG_SAVE_REINDENT_PCDATA_RELATIVE=   0x1000;
/* Add new-line before and after PCData if one doesn't already
   exist.
   Make indent for all lines of PCData the same
*/ 
const VSXMLCFG_SAVE_REINDENT_PCDATA=            0x2000;
    /* 
       Sort attribute value output for better diff
     
       <attrs c="c" a="a" b="b"/> is output as
       <attrs a="a' b="b" c="c"/>
    */ 
const VSXMLCFG_SAVE_SORT_ATTRIBUTES=     0x10000;

const VSXMLCFG_ADD_ATTR_AT_END=        0;
const VSXMLCFG_ADD_ATTR_AT_BEGINNING=  0x1;

const VSXMLCFG_ADD_AFTER=        0;  /* Add a node after sibling in order */
const VSXMLCFG_ADD_BEFORE=       1;  /* Add a node before sibling in order */
const VSXMLCFG_ADD_AS_CHILD=     2;  /* Add after last child */
const VSXMLCFG_ADD_AS_FIRST_CHILD=  3; /* Add before first child */

const VSXMLCFG_STATUS_INCOMPLETE=       0x1;
const VSXMLCFG_STATUS_READ_INVALID_TAG= 0x2;
const VSXMLCFG_STATUS_OPEN_ALREADY=     0x4;

//Name contains name of element.  Value is null.
const VSXMLCFG_NODE_ELEMENT_START=           0x1;
//Name contains name of element.  Value is null.
const VSXMLCFG_NODE_ELEMENT_START_END=       0x2;
//Name is set to "xml".   Attributes are set.  For compatibility with XPath,
//the _xmlcfg_find_XXX functions won't find these attributes
const VSXMLCFG_NODE_XML_DECLARATION=         0x4;
//Name is set to the processor name (not including '?').  Value is set to
//all data after the processor name not including leading white space.
const VSXMLCFG_NODE_PROCESSING_INSTRUCTION=  0x8;
//Name is set to null.  Value contains all data not
//including leading '!--' and trailing '--'.
const VSXMLCFG_NODE_COMMENT=                 0x10;
//Name is set to "DOCTYPE".  For convience, the DOCTYPE information is stored
// as attributes so it can be more easily identified an modified.   A "root"
// attribute is set to the document root element specified.  A "PUBLIC" attribute
// is set to the public literal specified.  A "SYSTEM" attribute is set to the
// system literal.  A "DTD" attribute is set to the internal DTD subset.
// For compatibility with XPath, the _xmlcfg_find_XXX functions won't find these attributes.
const VSXMLCFG_NODE_DOCTYPE=                 0x20;
//Name is set to attribute name.  Value is set to value of attribute not including quotes.
const VSXMLCFG_NODE_ATTRIBUTE=               0x40;
//Name is set to null.  Value is set to the PCDATA text.
const VSXMLCFG_NODE_PCDATA=                  0x80;
//Name is set to null.  Value is set to the CDATA text.
const VSXMLCFG_NODE_CDATA=                   0x100;
const VSXMLCFG_COPY_SRC_CHILDREN=           0x200;
const VSXMLCFG_COPY_BEFORE=                  VSXMLCFG_ADD_BEFORE;
const VSXMLCFG_COPY_AS_CHILD=                VSXMLCFG_ADD_AS_CHILD;
const VSXMLCFG_COPY_AS_FIRST_CHILD=          VSXMLCFG_ADD_AS_FIRST_CHILD;
const VSXMLCFG_COPY_CHILDREN=               (VSXMLCFG_COPY_SRC_CHILDREN|VSXMLCFG_COPY_AS_CHILD);

const VSXMLCFG_OPEN_ADD_ALL_PCDATA=  0x1;
const VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR=  0x2;
const VSXMLCFG_OPEN_REFCOUNT=              0x4;
const VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA=  0x8;
const VSXMLCFG_OPEN_REFCOPY=                   0x20;
const VSXMLCFG_OPEN_REINDENT_PCDATA=           0x40;
const VSXMLCFG_OPEN_ADD_PCDATA=  VSXMLCFG_OPEN_ADD_ALL_PCDATA;

// See builtins.e for more information.
//
// The advantage to using these is that if you declare the
// variables used to refer to these controls using these
// types rather than 'int' or 'typeless', you can get context
// tagging for the members of the controls.
//
#define CTL_CONTROL  int
#define CTL_FORM     int
#define CTL_HELP     int
#define CTL_TREE     int
#define CTL_LISTBOX  int
#define CTL_SSTAB    int
#define CTL_COMBO    int
#define CTL_TEXT     int
#define CTL_EDITOR   int
#define CTL_PPREVIEW int
#define CTL_WINDOW   int
#define CTL_BASEWIN  int
#define CTL_MDI      int
#define CTL_MENU     int
#define CTL_MENUITEM int
#define CTL_SSTABC   int
#define CTL_SPIN     int
#define CTL_GAUGE    int
#define CTL_IMAGE    int
#define CTL_PICTURE  int
#define CTL_VSCROLL  int
#define CTL_HSCROLL  int
#define CTL_SCROLL   int
#define CTL_LABEL    int
#define CTL_FRAME    int
#define CTL_RADIO    int
#define CTL_BUTTON   int
#define CTL_CHECK    int

const VSCP_ACTIVE_CODEPAGE=     0;

//#define VSCP_FIRST            29999
const VSCP_EBCDIC_SBCS=           29999;
const VSCP_CYRILLIC_KOI8_R=  30000;
const VSCP_ISO_8859_1=       30001;   /* Western European - Latin 1 */
const VSCP_ISO_8859_2=       30002;   /* Central and Eastern Europe - Latin 2*/
const VSCP_ISO_8859_3=       30003;   /* Esperanto - Latin 3 */
const VSCP_ISO_8859_4=       30004;   /* Latin 4 */
const VSCP_ISO_8859_5=       30005;   /* Cyrillic */
const VSCP_ISO_8859_6=       30006;   /* Arabic */
const VSCP_ISO_8859_7=       30007;   /* Greek */
const VSCP_ISO_8859_8=       30008;   /* Hebrew */
const VSCP_ISO_8859_9=       30009;   /* Latin 5 */
const VSCP_ISO_8859_10=      30010;   /* Latin 6 */
//#define VSCP_LAST             30010


const VSENCODING_AUTOUNICODE=         0x1;
const VSENCODING_AUTOTEXT=            0x2;
const VSENCODING_AUTOEBCDIC=          0x4;
const VSENCODING_AUTOUNICODE2=        0x8;
const VSENCODING_AUTOEBCDIC_AND_UNICODE=   (VSENCODING_AUTOEBCDIC|VSENCODING_AUTOUNICODE);
const VSENCODING_AUTOEBCDIC_AND_UNICODE2=   (VSENCODING_AUTOEBCDIC|VSENCODING_AUTOUNICODE2);

const VSENCODING_AUTOXML=             0x11;
const VSENCODING_AUTOHTML=            0x12;
const VSENCODING_AUTOHTML5=           0x13;
const VSENCODING_AUTOTEXTUNICODE=     0x14;
const VSENCODING_AUTOUNICODEUTF8=     0x15;
const VSENCODING_AUTOUNICODE2UTF8=    0x16;

const VSENCODING_UTF8=                    70;
const VSENCODING_UTF8_WITH_SIGNATURE=     71;
const VSENCODING_UTF16LE=                 72;
const VSENCODING_UTF16LE_WITH_SIGNATURE=  73;
const VSENCODING_UTF16BE=                 74;
const VSENCODING_UTF16BE_WITH_SIGNATURE=  75;
const VSENCODING_UTF32LE=                 76;
const VSENCODING_UTF32LE_WITH_SIGNATURE=  77;
const VSENCODING_UTF32BE=                 78;
const VSENCODING_UTF32BE_WITH_SIGNATURE=  79;
const VSENCODING_MAX=                     100;
bool gmarkfilt_utf8;

const VSBPFLAG_BREAKPOINT=        0x00000001;    /* Break point on this line*/
const VSBPFLAG_EXEC=              0x00000002;    /* Line about to be executed. */
const VSBPFLAG_STACKEXEC=         0x00000004;    /* Call Stack execution line */
const VSBPFLAG_BREAKPOINTDISABLED=   0x00000008; /* Break point disabled*/


const OEFLAG_REMOVE_FROM_OPEN=  0x1;
const OEFLAG_REMOVE_FROM_SAVEAS= 0x2;
const OEFLAG_BINARY=             0x4;
const OEFLAG_REMOVE_FROM_DIFF=   0x8;
const OEFLAG_REMOVE_FROM_NEW=    0x10;
//#define OEFLAG_KEEP_FOR_APPEND    0x8
int def_mfdiff_functions;

enum_flags CLEX_MATCH_FLAGS {
    CLEXMF_NONE             =0x0000,
    CLEXMF_CHECK_FIRST      =0x0001,
    CLEXMF_FIRST_NON_BLANK  =0x0002,


    CLEXMF_REGEX            =0x0004,
    CLEXMF_PERLRE           =0x0008,

    // multi-line continuation flags
    CLEXMF_END_REGEX        =0x0010,
    CLEXMF_END_PERLRE       =0x0020,
    CLEXMF_MULTILINE        =0x0040,
    CLEXMF_TERMINATE        =0x0080,
    // If m_embeded_lexer=htmlEOF, check for lexer (html) which is
    // a case insensitive prefix match. Lexer name must be at least 3
    // letters so short lexer names (like "D") don't get errouneously mattched.
    CLEXMF_EMBEDDED_LEXER_PREFIX_MATCH =0x0100,
    /* Don't color as embedded if not already coloring as embedded.
       Often used with interpolated strings.
    */
    CLEXMF_DONT_COLOR_AS_EMBEDDED_IF_POSSIBLE =0x0200,
    /* Color as embbedded if profile found, otherwise the
       type color is used.
       Could be used with interpolated strings.
       Often used by herdoc-type strings or R"<word>(...)<word>"
    */
    CLEXMF_COLOR_AS_EMBEDDED_IF_FOUND=0x0400,
    /* Typically, the "end" is found by searching for it 
       before tokenization. When this is done, the end can be found
       in a string or comment. For example, in HTML the </script> tag
       terminates the embedded script even if it is found inside a quoted
       string or comment. However, for the Java JSP ${ embedded-code }
       construct, you don't want the end brace ('}') terminating the
       embedded-code if it's found in a string literal. Specify this
       flag to avoid finding the end in a string or comment.
     
       NOTE: Interpolated strings automatically use this 
    */ 
    CLEXMF_EMBEDDED_END_IS_TOKEN            =0x000800,
    CLEXMF_APPLY_MULTILINE_AT_EOL           =0x008000,
    CLEXMF_END_EMBEDED_AT_BOL_IF_POSSIBLE   =0x010000,
    //CLEXMF_CONTINUE_UNTIL_INDENTED_LTE      =0x800000
};
struct COMMENT_TYPE {
   _str type;  // Color type
   _str delim1;
   _str delim2;
   int startcol,endcol;
   int end_startcol,end_endcol;
   // 0 - Default. Sort smallest to largest
   // Useful if more than one item matches a token (one is probably a regex)
   int order; 
   // 0 case-insensitive 1 case-sensitive 2 <null>
   int case_sensitive;

   _str start_color;
   _str end_color;
   _str color_to_eol;
   _str end_color_to_eol;
   _str escape_char;
   _str line_continuation_char;
   _str doubles_char;
   _str embedded_lexer;
   CLEX_MATCH_FLAGS flags;

   int nesting;
   _str nestingStart;
   _str nestingEnd;
   // When save the new flags, try to keep the original order.
   _str orig_flags;
   COMMENT_TYPE comments[];
};

/**
 * Indicates whether or not to automatically un-indent when the
 * backspace key is pressed at the start of a first word on a
 * current line.
 */
_metadata enum_flags VSCommentEditingFlags {
   
   /**
    * Indicates whether or not to automatically insert a '*'
    * on the continuing line when you hit ENTER to split a line
    * that is part of a javaDoc comment.
    */
   VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_ASTERISK   = 0x0000001,
   /**
    * Indicates whether or not to automatically create a skeleton
    * javaDoc comment when you hit ENTER to split a line containing
    * /&ast;&ast;|&ast;/.
    */
   VS_COMMENT_EDITING_FLAG_AUTO_JAVADOC_COMMENT    = 0x0000002,
   /**
    * Indicates whether or not to automatically create a skeleton
    * xmlDoc comment when you hit ENTER (in C# or C++) after a line
    * containing ///.  In C#, this will create a skeleton comment
    * when you hit the final / of /// on a line before a declaration.
    */
   VS_COMMENT_EDITING_FLAG_AUTO_XMLDOC_COMMENT     = 0x0000004,
   /**
    * Indicates whether or not to automatically insert a leading '//'
    * on the continuing line when you hit ENTER to split a line
    * contining a continued line comment.
    */
   VS_COMMENT_EDITING_FLAG_SPLIT_LINE_COMMENTS     = 0x0000008,
   /**
    * Indicates whether or not to automatically insert a leading '//'
    * on the continuing line when you hit ENTER at the end of the a
    * line that is part of a group of line comments.
    */
   VS_COMMENT_EDITING_FLAG_EXTEND_LINE_COMMENTS    = 0x0000010,
   /**
    * Indicate whether or not to automatically join line comments and
    * JavaDoc comments when a line is joined.
    */
   VS_COMMENT_EDITING_FLAG_JOIN_COMMENTS           = 0x0000020,
   /**
    * Indicates whether or not to automatically split a string when
    * you hit ENTER inside of a double quoted string in "C" like languages.
    */
   VS_COMMENT_EDITING_FLAG_SPLIT_STRINGS           = 0x0000040,
   /**
    * Indicates whether or not to automatically create a skeleton
    * javaDoc comment when you hit ENTER to split a line containing
    * /&ast;&ast;|&ast;/.
    */
   VS_COMMENT_EDITING_FLAG_AUTO_DOC_COMMENT        = 0x0000080,
   /**
    * When creating a new comment for a symbol, create it using 
    * Javadoc style comment delimeters. 
    */
   VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC          = 0x0000100,
   /**
    * When creating a new comment for a symbol, create it using 
    * XMLDOC style comment delimeters. 
    */
   VS_COMMENT_EDITING_FLAG_CREATE_XMLDOC           = 0x0000200,
   /**
    * When creating a new comment for a symbol, create it using 
    * Doxygen style comment delimeters.  This flag works in conjunction 
    * with  VS_COMMENT_EDITING_FLAG_CREATE_JAVADOC and 
    * VS_COMMEN_EDITING_FLAG_CREATE_XMLDOC in order to specify 
    * which style of Doxygen style comment to create.
    */
   VS_COMMENT_EDITING_FLAG_CREATE_DOXYGEN          = 0x0000400,
   /**
    * Do not prompt for documentation comment style options, just update 
    * comments with whatever comemnt delimeters they started with.
    */
   VS_COMMENT_EDITING_FLAG_CREATE_DEFAULT          = 0x0000800,
}
/**
 * Default value for comment editing flags.
 */
const VS_COMMENT_EDITING_FLAG_DEFAULT=                  0xfffff0ef;

/**
 * Set to the directory where the default JDK (Java Development Kit)
 * is installed.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_jdk_install_dir;

/**
 * Set to the directory where the default Mono Development Kit is installed.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_mono_install_dir;

/**
 * Set to the directory in which the Ant build tool is installed.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_ant_install_dir;

/**
 * Set to the directory in which the NAnt build tool is 
 * installed. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_nant_install_dir;

/**
 * Set to the path to 'php' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_php_exe_path;

/**
 * Set to the path to 'python' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_python_exe_path;

/**
 * Set to the path to 'perl' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_perl_exe_path;

/**
 * Set to the path to 'ruby' executable. 
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_ruby_exe_path;

_metadata enum ShowProjectFilesInOpenDialog {
   PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG=0,
   PROJECT_ADD_SHOWS_FILES_ALREADY_IN_PROJECT=1,
   PROJECT_ADD_HIDES_FILES_ALREADY_IN_PROJECT=2,
};

/**
 * Specifies whether or not to hide files that are already in the 
 * project when adding source files to the project 
 * (using the Add Source Files dialog).
 * <ul> 
 * <li>PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG -- 
 *     Hides files that are already in the project, provided the native
 *     operating system open dialog supports filtering.
 * <li>PROJECT_ADD_SHOWS_FILES_ALREADY_IN_PROJECT -- 
 *     Always show all files, including files already in the project. 
 * <li>PROJECT_ADD_HIDES_FILES_ALREADY_IN_PROJECT -- 
 *     Hides files that are already in the project.  Note that on some platforms,
 *     this will use the generic open file dialog rather than the native
 *     operating system open file dialog.
 * </ul> 
 * 
 * @default 0 -- PROJECT_ADD_HIDES_FILES_IF_SUPPORTED_IN_NATIVE_DIALOG
 * @categories Configuration_Variables
 */
ShowProjectFilesInOpenDialog def_show_prjfiles_in_open_dlg;

int def_max_makefile_menu; // Limit of number of makefiles/ant files display on build menu
int def_show_makefile_target_menu; // 0=disabled, 1=enabled, 2=only enabled on project toolbar (not on build menu)
int def_resolve_dependency_symlinks; // 0=no, 1=yes (this *must* always be 0 if not UNIX)

const VSFILETYPE_NORMAL_FILE=   1;
const VSFILETYPE_DATASET_FILE=  2;
const VSFILETYPE_REMOTE_OS390_DATASET_FILE= 3;
const VSFILETYPE_REMOTE_OS390_HFS_FILE=     4;
const VSFILETYPE_JAR_FILE=      5;
const VSFILETYPE_URL_FILE=      6;
const VSFILETYPE_GVFS_FILE=     7;
const VSFILETYPE_PLUGIN_FILE=   8;
const VSFILETYPE_GZIP_FILE=     9;
const VSFILETYPE_TAR_FILE=      10;
const VSFILETYPE_UNC_FILE=      11;

_str def_url_proxy;
_str def_url_proxy_bypass;

/**
 * Default non-extension specific encoding load option.
 *
 * @default '+fautounicode'
 * @categories Configuration_Variables
 */
_str def_encoding;

/** 
 * Determines whether text files are loaded as SBCS/DBCS or 
 * Unicode (Utf-8). 
 *  
 * <p>When true, for platforms like Linux and Mac which 
 * may default to Utf-8 encoded text, files will be loaded in 
 * Unicode mode. Otherwise, files are loaded as SBCS/DBCS in 
 * the default code page. 
 *  
 * <p>By default, this variable is set to true. 
 */
bool def_autotext;

/*
  This create option has been removed becaused it exagerated coding errors.
  For example,  create and XMLCFG file and then don't close it because of a bug.
  Next time you call _xmlcfg_open, you get the wrong file.
*/
const VSXMLCFG_CREATE_IF_EXISTS_CLEAR=   0;
const VSXMLCFG_CREATE_IF_EXISTS_OPEN=    1;
const VSXMLCFG_CREATE_IF_EXISTS_ERROR=   2;
const VSXMLCFG_CREATE_IF_EXISTS_CREATE=  3;

struct UNAME {
   _str sysname;  // Ex.  Linux
   /* Name of this computer on the network.  */
   _str nodename;

   /* Current release level of this implementation.  */
   _str release;
   /* Current version level of this release.  */
   _str version;
   /* Name of the hardware type the system is running on.  */
   _str cpumachine;
};
extern int _uname(UNAME &info);

// Describe how auto validate should behave
// We need this because depending on how the file is opened
// we may want to limit or disable auto validate because
// it can interupt the user.  For example, if the user
// did a global multi file search.  Each time they hit
// move find next between files validation would occur
// which would switch the tab
//
int gXMLAutoValidateBehavior;
const VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE=   -1;
const VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE=     0;
const VSXML_AUTOVALIDATE_BEHAVIOR_NO_MOVE=    1;

const CSIDL_PERSONAL=                  0x0005;
const CSIDL_DESKTOP=                   0x0010;
const CSIDL_LOCAL_APPDATA=             0x001c;
const CSIDL_PROGRAM_FILES=             0x0026;
const CSIDL_PROGRAM_FILESX86=          0x002a;
const CSIDL_WINDOWS=                   0x0024;
const CSIDL_COMMON_DOCUMENTS=          0x002e;

const JAVADOCHREFINDICATOR= "\1";

// Smarttab values
_metadata enum VSSmartTab {
   VSSMARTTAB_INDENT                = 0,   // Indent to the next tab stop
   VSSMARTTAB_MAYBE_REINDENT_STRICT = 1,   // Reindent the current line if cursor
                                           // is in preceding whitespace
   VSSMARTTAB_MAYBE_REINDENT        = 2,   // Reindents the current line if the new
                                           // column position is before the current
                                           // column position.  Otherwise, the TAB key
                                           // indents to the next tab stop.
   VSSMARTTAB_ALWAYS_REINDENT       = 3,   // Reindents the current line regardless
                                          // where the cursor is (GNU Emacs style)
};
enum VSTabStyle {
   VSTABSTYLE_SYNTAX_INDENT   = 0,   // Indent by syntax indent from cursor location
   VSTABSTYLE_USE_SYNTAX_INDENT_AS_TAB_STOPS = 1,
   VSTABSTYLE_USE_TAB_STOPS   = 2,
};
int def_maxcombohist;  // Default maximum combo box retrieval list


// IMPORTANT: These two version #defines are deprecated and used
//            only for upgrading old projects.  All new code
//            should check VPW_FILE_VERSION and VPJ_FILE_VERSION instead.
const PROJECT_FILE_VERSION= 7.0;
const WORKSPACE_FILE_VERSION= 8;

// Version of workspace, project, template, and ext-specific project
// files supported by this release of Visual SlickEdit
// Version 8.1
const VPT_FILE_VERSION81= 8.1;
const VPJ_FILE_VERSION81= 8.1;
const VPW_FILE_VERSION81= 8.1;
const VPE_FILE_VERSION81= 8.1;

const VPT_DTD_PATH81= "http://www.slickedit.com/dtd/vse/8.1/vpt.dtd";
const VPJ_DTD_PATH81= "http://www.slickedit.com/dtd/vse/8.1/vpj.dtd";
const VPW_DTD_PATH81= "http://www.slickedit.com/dtd/vse/8.1/vpw.dtd";
const VPE_DTD_PATH81= "http://www.slickedit.com/dtd/vse/8.1/vpe.dtd";

const VSDEBUG_DTD_PATH81= "http://www.slickedit.com/dtd/vse/8.1/vsdebugger.dtd";

// Version 9.0
const VPT_FILE_VERSION90= 9.0;
const VPJ_FILE_VERSION90= 9.0;
const VPW_FILE_VERSION90= 9.0;
const VPE_FILE_VERSION90= 9.0;

const VPT_DTD_PATH90= "http://www.slickedit.com/dtd/vse/9.0/vpt.dtd";
const VPJ_DTD_PATH90= "http://www.slickedit.com/dtd/vse/9.0/vpj.dtd";
const VPW_DTD_PATH90= "http://www.slickedit.com/dtd/vse/9.0/vpw.dtd";
const VPE_DTD_PATH90= "http://www.slickedit.com/dtd/vse/9.0/vpe.dtd";

const VSDEBUG_DTD_PATH90= "http://www.slickedit.com/dtd/vse/9.0/vsdebugger.dtd";

// Version 9.1
const VPT_FILE_VERSION91= 9.1;
const VPJ_FILE_VERSION91= 9.1;
const VPW_FILE_VERSION91= 9.1;
const VPE_FILE_VERSION91= 9.1;

const VPT_DTD_PATH91= "http://www.slickedit.com/dtd/vse/9.1/vpt.dtd";
const VPJ_DTD_PATH91= "http://www.slickedit.com/dtd/vse/9.1/vpj.dtd";
const VPW_DTD_PATH91= "http://www.slickedit.com/dtd/vse/9.1/vpw.dtd";
const VPE_DTD_PATH91= "http://www.slickedit.com/dtd/vse/9.1/vpe.dtd";

const VSDEBUG_DTD_PATH91= "http://www.slickedit.com/dtd/vse/9.1/vsdebugger.dtd";

// Version 10.0
const VPT_FILE_VERSION100= 10.0;
const VPJ_FILE_VERSION100= 10.0;
const VPW_FILE_VERSION100= 10.0;
const VPE_FILE_VERSION100= 10.0;

const COMPILERS_XML_VERSION100= 10.0;

const VPT_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/vpt.dtd";
const VPJ_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/vpj.dtd";
const VPW_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/vpw.dtd";
const VPE_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/vpe.dtd";

const VSDEBUG_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/vsdebugger.dtd";

const COMPLIERS_XML_DTD_PATH100= "http://www.slickedit.com/dtd/vse/10.0/compilers.dtd";

// Current Version
const VPT_FILE_VERSION= VPT_FILE_VERSION100;
const VPJ_FILE_VERSION= VPJ_FILE_VERSION100;
const VPW_FILE_VERSION= VPW_FILE_VERSION100;
const VPE_FILE_VERSION= VPE_FILE_VERSION100;

const COMPILERS_XML_VERSION= COMPILERS_XML_VERSION100;

const VPT_DTD_PATH= VPT_DTD_PATH100;
const VPJ_DTD_PATH= VPJ_DTD_PATH100;
const VPW_DTD_PATH= VPW_DTD_PATH100;
const VPE_DTD_PATH= VPE_DTD_PATH100;

const VSDEBUG_DTD_PATH= VSDEBUG_DTD_PATH100;

const COMPLIERS_XML_DTD_PATH= COMPLIERS_XML_DTD_PATH100;

//Workspace cache variables
   _str gActiveConfigName;   // Can be '' if no project is active.
   _str gActiveTargetDestination;   // Can be '' if no project is active.
   _str _workspace_filename;
   int gWorkspaceHandle;     // Handle to XMLCFG tree or -1 if no workspace open.
   int gProjectHashTab:[/*AbsoluteProjectName*/]; //gProjectHashTab:[AbsoluteProjectName]= ProjectHandle
   int gProjectExtHandle;    // Handle to XMLCFG tree or -1 if not initialized yet.

const VPJ_SHOWONMENU_HIDEIFNOCMDLINE=  'HideIfNoCmdLine';
const VPJ_SHOWONMENU_NEVER=  'Never';
const VPJ_SHOWONMENU_ALWAYS=  'Always';

const VPJTAG_PROJECT= "Project";
const VPJTAG_MACRO=   "Macro";
const VPJTAG_CONFIG=  "Config";
const VPJTAG_FILES=   "Files";
const VPJTAG_DEPENDENCIES= "Dependencies";
const VPJTAG_DEPENDENCY= "Dependency";
const VPJTAG_EXECMACRO=    "ExecMacro";
const VPJTAG_APPTYPETARGETS=    "AppTypeTargets";
const VPJTAG_APPTYPETARGET=    "AppTypeTarget";
const VPJTAG_TARGET=    "Target";
const VPJTAG_RULE=      "Rule";
const VPJTAG_EXEC=      "Exec";
const VPJTAG_CALLTARGET=  "CallTarget";
const VPJTAG_SET=         "Set";
const VPJTAG_FOLDER=    "Folder";
const VPJTAG_CUSTOMFOLDERS= "CustomFolders";
const VPJTAG_F= "F";
const VPJTAG_MENU=    "Menu";
const VPJTAG_INCLUDE= "Include";
const VPJTAG_INCLUDES= "Includes";
const VPJTAG_SYSINCLUDES= "SysIncludes";
const VPJTAG_SYSINCLUDE= "SysInclude";
const VPJTAG_LIB= "Lib";
const VPJTAG_LIBS= "Libs";
const VPJTAG_CLASSPATH= "ClassPath";
const VPJTAG_CLASSPATHELEMENT= "ClassPathElement";
//const VPJTAG_RULE= "Rule";
const VPJTAG_RULES= "Rules";
const VPJTAG_PREBUILDCOMMANDS= "PreBuildCommands";
const VPJTAG_POSTBUILDCOMMANDS= "PostBuildCommands";
const VPJTAG_COMPATIBLEVERSIONS= "CompatibleVersions";
const VPJTAG_PREVVERSION= "PrevVersion";
const VPJTAG_LIST= "List";
const VPJTAG_ITEM= "Item";

const VPJX_PROJECT=  ("/"VPJTAG_PROJECT);
const VPJX_MACRO=    (VPJX_PROJECT"/"VPJTAG_MACRO);
const VPJX_CONFIG=   (VPJX_PROJECT"/"VPJTAG_CONFIG);
const VPJX_FILES=    (VPJX_PROJECT"/"VPJTAG_FILES);
#define VPJX_DEPENDENCIES(ConfigName,DependsRef) (VPJX_CONFIG "[strieq(@Name,'" ConfigName "')]/" VPJTAG_DEPENDENCIES "[strieq(@Name,'" DependsRef "')]")
#define VPJX_DEPENDENCY(ConfigName,DependsRef) (VPJX_DEPENDENCIES(ConfigName,DependsRef)"/"VPJTAG_DEPENDENCY)
const VPJX_DEPENDENCIES_DEPRECATED= (VPJX_PROJECT"/"VPJTAG_DEPENDENCIES);
const VPJX_DEPENDENCY_DEPRECATED= (VPJX_DEPENDENCIES_DEPRECATED"/"VPJTAG_DEPENDENCY);
const VPJX_EXECMACRO= (VPJX_MACRO"/"VPJTAG_EXECMACRO);
const VPJX_APPTYPETARGETS= (VPJX_CONFIG"/"VPJTAG_APPTYPETARGETS);
const VPJX_APPTYPETARGET= (VPJX_APPTYPETARGETS"/"VPJTAG_APPTYPETARGET);
const VPJX_MENU=     (VPJX_CONFIG"/"VPJTAG_MENU);
const VPJX_COMPATIBLEVERSIONS= (VPJX_PROJECT"/"VPJTAG_COMPATIBLEVERSIONS);
const VPJX_POSTBUILDCOMMANDS=  (VPJX_CONFIG"/"VPJTAG_POSTBUILDCOMMANDS);
const VPJX_PREBUILDCOMMANDS=   (VPJX_CONFIG"/"VPJTAG_PREBUILDCOMMANDS);

const VPWTAG_WORKSPACE= "Workspace";
const VPWTAG_PROJECTS= "Projects";
const VPWTAG_PROJECT= "Project";
const VPWTAG_ENVIRONMENT= "Environment";
const VPWTAG_SET=         "Set";
const VPWTAG_TAGFILES= "TagFiles";
const VPWTAG_TAGFILE= "TagFile";
const VPWTAG_COMPATIBLEVERSIONS= "CompatibleVersions";
const VPWTAG_PREVVERSION= "PrevVersion";

const VPWX_WORKSPACE= ("/"VPWTAG_WORKSPACE);
const VPWX_PROJECTS=  (VPWX_WORKSPACE"/"VPWTAG_PROJECTS);
const VPWX_PROJECT=   (VPWX_PROJECTS"/"VPWTAG_PROJECT);
const VPWX_ENVIRONMENT=  (VPWX_WORKSPACE"/"VPWTAG_ENVIRONMENT);
const VPWX_SET=          (VPWX_ENVIRONMENT"/"VPWTAG_SET);
const VPWX_TAGFILES=  (VPWX_WORKSPACE"/"VPWTAG_TAGFILES);
const VPWX_TAGFILE=   (VPWX_TAGFILES"/"VPWTAG_TAGFILE);
const VPWX_COMPATIBLEVERSIONS=  (VPWX_WORKSPACE"/"VPWTAG_COMPATIBLEVERSIONS);


const VPTTAG_TEMPLATES=  "Templates";
const VPTTAG_TEMPLATE=  "Template";

const VPTX_TEMPLATES= ("/"VPTTAG_TEMPLATES);
const VPTX_TEMPLATE=  (VPTX_TEMPLATES"/"VPTTAG_TEMPLATE);

const VPJ_TAGGINGOPTION_WORKSPACE=  'Workspace';
const VPJ_TAGGINGOPTION_PROJECT=    'Project';
const VPJ_TAGGINGOPTION_PROJECT_NOREFS=    'ProjectNorefs';
const VPJ_TAGGINGOPTION_NONE=       'None';

const VPJ_SAVEOPTION_SAVECURRENT= 'SaveCurrent';
const VPJ_SAVEOPTION_SAVEALL=     'SaveAll';
const VPJ_SAVEOPTION_SAVEMODIFIED=  'SaveModified';
const VPJ_SAVEOPTION_SAVENONE=     'SaveNone';
const VPJ_SAVEOPTION_SAVEWORKSPACEFILES=  'SaveWorkspaceFiles';

const VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER= 'ProcessBuffer';
const VPJ_CAPTUREOUTPUTWITH_REDIRECTION=  'Redirection';

#define BBINDENT_X (40/_twips_per_pixel_x())

#define XPATH_STRIEQ(AttrName,RuleName)  "[strieq(@"AttrName",'"RuleName"')]"
#define XPATH_FILEEQ(AttrName,RuleName)  "[file-eq(@"AttrName",'"RuleName"')]"
#define XPATH_CONTAINS(AttrName,String,Options) "[contains(@"AttrName",'"String"','"Options"')]"

#define EXTRA_FILE_FILTERS (_isWindows()? "ZIP Files (*.zip),JAR Files (*.jar),Java Class Files (*.class),.NET DLL Files (*.dll)" : "ZIP Files (*.zip),JAR Files (*.jar),Java Class Files (*.class)" )

_str _get_string;
_str _get_string2;
_str WILDCARD_CHARS; //  '*?' '*?[]^\'

const VPJ_AUTOFOLDERS_PACKAGEVIEW=  "PackageView";
const VPJ_AUTOFOLDERS_DIRECTORYVIEW= "DirectoryView";
const VPJ_AUTOFOLDERS_CUSTOMVIEW=    "";

typedef _str STRARRAY[];
typedef _str (*STRARRAYPTR)[];
typedef int  INTARRAY[];
typedef typeless TYPELESSARRAY[];
typedef _str STRHASHTABARRAY:[][];
typedef _str STRHASHTAB:[];
typedef int  INTHASHTAB:[];
typedef typeless TYPELESSHASHTAB:[];
typedef void (*pfnTreeSaveCallback)(int xml_handle,int xml_index,int tree_index);
typedef void (*pfnTreeLoadCallback)(int xml_handle,int xml_index,int tree_index);
typedef void (*pfnTreeDoRecursivelyCallback)(int index, typeless extra);
#define ARRAY_APPEND(a,b) a :+= b

struct PASSWD {
  _str pw_name;       /* user name */
  _str pw_passwd;     /* user password */
  int  pw_uid;        /* user id */
  int  pw_gid;        /* group id */
  _str pw_gecos;      /* real name */
  _str pw_dir;        /* home directory */
  _str pw_shell;      /* shell program */
};

// Picture with lowest order is displayed on top
const VSPIC_ORDER_DEBUGGER=            100;
const VSPIC_ORDER_BPM=                 101;
const VSPIC_ORDER_ANNOTATION=          200;
const VSPIC_ORDER_ANNOTATION_GRAY=     201;
const VSPIC_ORDER_SET_BOOKMARK=        202;
const VSPIC_ORDER_PUSHED_BOOKMARK=     203;

const VSPIC_ORDER_PLUS=                500;
const VSPIC_ORDER_MINUS=               501;

// Deprecated:  Use VSLINEMARKERINFO
struct VSLINEMARKERLISTITEM {
   int LineMarkerIndex;
   int LineNum;
   int BMIndex;
   int type;
   _str msg;
   int MousePointer;
   int RGBBoxColor;
   int NofLines;
};

// Deprecated:  Use VSLINEMARKERINFO or VSSTREAMMARKERINFO
typedef VSLINEMARKERLISTITEM  VSPICLISTITEM;


// Deprecated:  Use VSSTREAMMARKERINFO
struct VSSTREAMMARKERLISTITEM {
   bool isDeferred;
   typeless Buffer;
   long StartOffset;
   int  Length;
   int  BMIndex;
   int  type;
   int  MousePointer;
   int  RGBBoxColor;
   int  ColorIndex;
   _str msg;
};

/*
   When on, indicates that this Pic should be removed when the
   area size is zero.
*/
const VSMARKERTYPEFLAG_AUTO_REMOVE=        0x10;

/*
   When on, that a box should be draw around the lines contained in this
   area.  You can also have a bitmap displayed on the first line of the selection.
*/
const VSMARKERTYPEFLAG_DRAW_BOX=                   0x20;
const VSMARKERTYPEFLAG_UNDO=                       0x40;
const VSMARKERTYPEFLAG_COPYPASTE=                  0x80;
const VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT=      0x100;
const VSMARKERTYPEFLAG_DRAW_FOCUS_RECT=            0x200;
const VSMARKERTYPEFLAG_DRAW_SQUIGGLY=              0x400;
const VSMARKERTYPEFLAG_DRAW_LINE_LEFT=             0x800;
const VSMARKERTYPEFLAG_DRAW_LINE_RIGHT=            0x1000;
const VSMARKERTYPEFLAG_DRAW_SQUIGGLY_LEFT=         0x2000;
const VSMARKERTYPEFLAG_DRAW_SQUIGGLY_RIGHT=        0x4000;
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT=     0x10000;
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT=  0x20000;
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT=    0x40000;
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT= 0x80000;
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_RIGHT=   (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT);
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_LEFT=    (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT);
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_BOTH=  (VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT);
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_BOTH=     (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT);
const VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_BOTH=    (VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_RIGHT);
const VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER=     0x100000;
const VSMARKERTYPEFLAG_USE_MARKER_TYPE_COLOR=      0x400000;

/**
 * Struct created by _list_processes()
 */
struct PROCESS_INFO {
   _str    owner;        // user id of owner (may be empty on Windows)
   bool is_system;    // system process or owned by root on Unix
   int     pid;          // process ID
   int     parent_pid;   // process ID of parent process
   _str    name;         // name of process
   _str    title;        // title of process on Windows, or command and args on Unix
   _str    start_time;   // startup time for process, unix only, display only
   _str    cpu_time;     // amount of time running (unix only)
   _str    ptty;         // tty attached process is attached to (unix only)
   long    hwnd;         // window handle (Windows only)
};
extern int _list_processes(PROCESS_INFO (&process_list)[]);

const FUNDAMENTAL_LANG_ID=   'fundamental';

const VSDEFAULT_INITIAL_MENU_OFFSET_X=  0;
const VSDEFAULT_INITIAL_MENU_OFFSET_Y=  0;

/**
 * These are options passed to all CVS operations before the command name.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_cvs_global_options;
/**
 * These are options passed to all Subversion operations before the command name.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_svn_global_options;

int _CVSDebug;

_metadata enum_flags CVS_FLAGS {
   CVS_ALWAYS_USE_DASH_D   = 0x1,
   CVS_USE_TOOLBAR_BITMAPS = 0x2,
   CVS_FIND_NEXT_AFTER_DIFF= 0x4,
   CVS_RESTORE_COMMENT     = 0x8,
   CVS_RESTORE_TAGS        = 0x10,
   CVS_SHOW_LABELS_IN_TREE = 0x20,
   CVS_SHOW_MERGE_BUTTON   = 0x40,
   CVS_HIDE_EMPTY_DIRECTORIES =  0x80
};

/**
 * CVS options.  Bitset of CVS_*
 * <ol>
 * <li><b>CVS_ALWAYS_USE_DASH_D</b> -- always use the "-d" option with cvs update
 * <li><b>CVS_USE_TOOLBAR_BITMAPS</b> -- show CVS file status in project tool window
 * <li><b>CVS_FIND_NEXT_AFTER_DIFF</b> -- advance to next item after diff
 * <li><b>CVS_RESTORE_COMMENT</b> -- restore last checkin comment
 * <li><b>CVS_RESTORE_TAGS</b> -- restore last checkin tag(s)
 * <li><b>CVS_SHOW_LABELS_IN_TREE</b> -- show labels in version history tree
 * </ol>
 *
 * @default CVS_RESTORE_COMMENT;
 * @categories Configuration_Variables
 */
int def_cvs_flags;

/**
 * CVS shell options.
 *
 * @default 'Q'
 * @categories Configuration_Variables
 *
 * @see shell
 */
_str def_cvs_shell_options;

/**
 * If enabled, enter block insert mode immediately after typing
 * printable characters if there is a block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_do_block_mode_key;
/**
 * If enabled, support Delete while in block insert mode.
 * If disabled, Delete merely deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_do_block_mode_delete;
/**
 * If enabled, support Backspace while in block insert mode.
 * If disabled, Backspace merely deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_do_block_mode_backspace;

/**
 * If enabled, support Del while in block insert mode.
 * If disabled, Del deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_do_block_mode_del_key;

/**
 * Sets maximum buffer size in killobytes for search results 
 * buffer. 
 * @categories Configuration_Variables
 */
int def_max_mffind_output_ksize;

enum_flags {
   DELTASAVE_BACKUP_FILES,
   DELTASAVE_DELTA_FOR_MATCHING_FILES,
}
const DELTASAVE_DEFAULT_NUMVERSIONS= 400;
/**
 * Default max time (in milliseconds) that diff will run before 
 * backup history times out and stores a whole version of the 
 * file. 
 */
const DELTASAVE_DEFAULT_TIMEOUT=     3000;
/** 
 * Max time to wait for file compare before storing whole 
 * version (in milliseconds) 
 */
int def_deltasave_timeout;

/**
 * If non-zero, use the <B>def_deltasave_timeout</B> as the 
 * amount of milliseconds to wait on a file compare before 
 * storing the entire version of a file in backup history 
 */
int def_deltasave_use_timeout;

/**
 * Backup history options.  Bitset of DELTASAVE_*.
 * <ul>
 * <li><b>DELTASAVE_BACKUP_FILES</b> -- enable backup history
 * <li><b>DELTASAVE_DELTA_FOR_MATCHING_FILES</b> -- create backup history entry 
 *                                                  on save even if file has not
 *                                                  changed.
 * </ul>
 *
 * @default 0
 * @categories Configuration_Variables
 */
int def_deltasave_flags;
/**
 * Maximum number of backup history revisions to create per file.
 *
 * @default 400
 * @categories Configuration_Variables
 */
int def_deltasave_versions;
/**
 * Backup history options.  List of seimicolon delimited
 * ant-like filespecs that should be excluded from backup
 * history.
 * 
 * @example
 * <pre>
 *   path1/    -- don't backup files under a directory named "path1"
 *   *.bak     -- don't backup files with extension "bak"
 * </pre>
 *
 * @default 0
 * @categories Configuration_Variables
 */
_str def_deltasave_exclusions;

bool def_updown_screen_lines;
int def_process_softwrap;
bool def_SoftWrap;
bool def_SoftWrapOnWord;


const LOI_SYNTAX_INDENT= "syntax_indent";
const LOI_SYNTAX_EXPANSION= "syntax_expansion";
const LOI_MIN_ABBREVIATION= "minimum_abbreviation";
const LOI_INDENT_CASE_FROM_SWITCH= "indent_case";
const LOI_KEYWORD_CASE= "wc_keyword";
const LOI_BEGIN_END_COMMENTS= "begin_end_comments";
const LOI_INDENT_FIRST_LEVEL= "indent_first_level";
const LOI_MULTILINE_IF_EXPANSION= "multiline_if_expansion";
const LOI_MAIN_STYLE= "main_style";
const LOI_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS= "listalign_fun_call_params";
const LOI_BEGIN_END_STYLE= "begin_end_style";
const LOI_PAD_PARENS= "sppad_parens";
const LOI_NO_SPACE_BEFORE_PAREN= "no_space_before_paren";
const LOI_POINTER_STYLE= "pointer_style";
const LOI_FUNCTION_BEGIN_ON_NEW_LINE= "function_begin_on_new_line";
const LOI_INSERT_BEGIN_END_IMMEDIATELY= "insert_begin_end_immediately";
const LOI_INSERT_BLANK_LINE_BETWEEN_BEGIN_END= "insert_blank_line_between_begin_end";
const LOI_QUICK_BRACE= "quick_brace";
const LOI_CUDDLE_ELSE= "nl_before_else";
const LOI_DELPHI_EXPANSIONS= "delphi_expansions";              // pascal
const LOI_TAG_CASE= "wc_tag_name";
const LOI_ATTRIBUTE_CASE= "wc_attr_name";
const LOI_WORD_VALUE_CASE= "wc_attr_word_value";
const LOI_HEX_VALUE_CASE= "wc_attr_hex_value";
const LOI_QUOTE_NUMBER_VALUES= "quote_attr_number_value";
const LOI_QUOTE_WORD_VALUES= "quote_attr_word_value";
const LOI_LOWERCASE_FILENAMES_WHEN_INSERTING_LINKS= "lowercase_filenames_when_inserting_links";
const LOI_USE_COLOR_NAMES= "use_color_names";
const LOI_USE_DIV_TAGS_FOR_ALIGNMENT= "use_div_tags_for_alignment";
const LOI_USE_PATHS_FOR_FILE_ENTRIES= "use_paths_for_file_entries";
const LOI_AUTO_VALIDATE_ON_OPEN= "auto_validate_on_open";
const LOI_AUTO_WELLFORMEDNESS_ON_OPEN= "auto_wellformedness_on_open";
const LOI_AUTO_CORRELATE_START_END_TAGS= "auto_correlate_start_end_tags";
const LOI_AUTO_SYMBOL_TRANSLATION= "auto_symbol_translation";
const LOI_INSERT_RIGHT_ANGLE_BRACKET= "insert_right_angle_bracket";     // deprecated
const LOI_COBOL_SYNTAX= "cobol_syntax";                   // cobol only
const LOI_AUTO_INSERT_LABEL= "auto_insert_label";              // vhdl only
const LOI_RUBY_STYLE= "ruby_style";                     // ruby only

// List of language properties not in VS_LANGUAGE_OPTIONS::m_properties
const VSLANGPROPNAME_AUTO_LEFT_MARGIN=    "auto_left_margin";
const VSLANGPROPNAME_BOUNDS=       "bounds";
const VSLANGPROPNAME_AUTO_CAPS=    "auto_caps";
const VSLANGPROPNAME_COLOR_FLAGS=    "color_flags";
const VSLANGPROPNAME_FIXED_WIDTH_RIGHT_MARGIN=    "fixed_width_right_margin";
const VSLANGPROPNAME_HEX_MODE=    "hex_mode";
const VSLANGPROPNAME_INDENT_WITH_TABS=    "indent_with_tabs";
const VSLANGPROPNAME_INDENT_STYLE=    "indent_style";
const VSLANGPROPNAME_EVENTTAB_NAME=    "eventtab_name";
const VSLANGPROPNAME_LEXER_NAME=    "lexer_name";
const VSLANGPROPNAME_LINE_NUMBERS_LEN=    "line_numbers_len";
const VSLANGPROPNAME_LINE_NUMBERS_FLAGS=    "line_numbers_flags";
const VSLANGPROPNAME_MARGINS=    "margins";
const VSLANGPROPNAME_MODE_NAME=    "mode_name";
const VSLANGPROPNAME_SHOW_SPECIAL_CHARS_FLAGS=    "show_special_chars_flags";
const VSLANGPROPNAME_SOFT_WRAP=    "soft_wrap";
const VSLANGPROPNAME_SOFT_WRAP_ON_WORD=    "soft_wrap_on_word";
const VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING=    "spell_check_while_typing";
const VSLANGPROPNAME_SPELL_CHECK_WHILE_TYPING_ELEMENTS="spell_check_while_typing_elements";
const VSLANGPROPNAME_TABS=       "tabs";
const VSLANGPROPNAME_TRUNCATE_LENGTH=    "truncate_length";
const VSLANGPROPNAME_WORD_CHARS=        "word_chars";
const VSLANGPROPNAME_WORD_WRAP_FLAGS=    "word_wrap_flags";


const VSLANGPROPNAME_CW_FLAGS=          "cw_flags";
const VSLANGPROPNAME_CW_STYLE=          "cw_style";
const VSLANGPROPNAME_CW_LINE_COMMENT_MIN=  "cw_line_comment_min";
const VSLANGPROPNAME_CW_FIXED_WIDTH_SIZE=  "cw_fixed_width_size";
const VSLANGPROPNAME_CW_FIXED_WIDTH_MAX_RIGHT_COLUMN=  "cw_fixed_width_max_right_column";
const VSLANGPROPNAME_CW_FIXED_RIGHT_COLUMN=            "cw_fixed_right_column";
const VSLANGPROPNAME_CW_AUTOMATIC_WIDTH_MAX_RIGHT_COLUMN= "cw_automatic_width_max_right_margin";

const VSLANGPROPNAME_BEAUTIFIER_DEFAULT_PROFILE=    "beautifier_default_profile";
const VSLANGPROPNAME_RTE_DEFAULT_PROFILE=    "rte_default_profile";
const VSLANGPROPNAME_RTE_LANG_ENABLED=    "rte_lang_enabled";
const VSLANGPROPNAME_TAB_CYCLES_INDENT=    "tab_cycles_indents";
const VSLANGPROPNAME_BEAUTIFIER_EXPANSION_FLAGS=    "beautifier_expansion_flags";
const VSLANGPROPNAME_CONTEXT_MENU=    "context_menu";
const VSLANGPROPNAME_CONTEXT_MENU_IF_SELECTION=    "context_menu_if_selection";

const VSLANGPROPNAME_INHERITS_FROM=    "inherits_from";
const VSLANGPROPNAME_NUMBERING_STYLE=    "numbering_style";
const VSLANGPROPNAME_REFERENCED_IN_LANGIDS=    "referenced_in_langids";
const VSLANGPROPNAME_BEGIN_END_PAIRS=    "begin_end_pairs";
const VSLANGPROPNAME_SMART_TAB=    "smart_tab";
//const VSLANGPROPNAME_ALIAS_FILENAME=    "alias_filename";
const VSLANGPROPNAME_CODE_MARGINS=    "code_margins";
const VSLANGPROPNAME_DIFF_COLUMNS=    "diff_columns";
const VSLANGPROPNAME_ADAPTIVE_FORMATTING_FLAGS=    "adaptive_formatting_flags";
const VSLANGPROPNAME_USE_ADAPTIVE_FORMATTING=    "use_adaptive_formatting";
const VSLANGPROPNAME_SURROUND_FLAGS=    "surround_flags";
const VSLANGPROPNAME_CODE_HELP_FLAGS=     "code_help_flags";
const VSLANGPROPNAME_AUTO_COMPLETE_FLAGS=    "auto_complete_flags";
const VSLANGPROPNAME_AUTO_COMPLETE_MIN=        "auto_complete_min";
const VSLANGPROPNAME_SYMBOL_COLORING_FLAGS=    "symbol_coloring_flags";
//const VSLANGPROPNAME_DOC_COMMENT_FLAGS=    "doc_comment_flags";
//const VSLANGPROPNAME_COMMENT_WRAP_OPTIONS=    "comment_wrap_options";
const VSLANGPROPNAME_BACKSPACE_UNINDENTS=    "backspace_unindents";
//const VSLANGPROPNAME_XML_WRAP_OPTIONS=    "xml_wrap_options";
const VSLANGPROPNAME_LOAD_FILE_OPTIONS=    "load_file_options";
const VSLANGPROPNAME_SAVE_FILE_OPTIONS=    "save_file_options";
const VSLANGPROPNAME_REAL_INDENT=    "real_indent";
const VSLANGPROPNAME_AUTO_CASE_KEYWORDS=    "auto_case_keywords";
const VSLANGPROPNAME_COMMENT_EDITING_FLAGS=    "comment_editing_flags";
const VSLANGPROPNAME_COMMENT_BOX_OPTIONS=  "comment_box_options";
const VSLANGPROPNAME_AUTO_BRACKET_FLAGS=    "auto_bracket_flags";
const VSLANGPROPNAME_AUTO_SURROUND_FLAGS=    "auto_surround_flags";
const VSLANGPROPNAME_EXPAND_ALIAS_ON_SPACE=    "expand_alias_on_space";
const VSLANGPROPNAME_AUTO_COMPLETE_POUND_INCLUDE=    "auto_complete_pound_include";
const VSLANGPROPNAME_AUTO_COMPLETE_SUBWORDS=    "auto_complete_subwords";
const VSLANGPROPNAME_SELECTIVE_DISPLAY_FLAGS=    "selective_display_flags";
const VSLANGPROPNAME_AUTO_CLOSE_BRACE_PLACEMENT=  "auto_close_brace_placement";
const VSLANGPROPNAME_SMART_PASTE=    "smart_paste";
const VSLANGPROPNAME_INCLUDE_RE=  "include_re";
const VSLANGPROPNAME_DEBUG_PRINT_FUNCTION=  "debug_print_function";
const VSLANGPROPNAME_SHOW_MINIMAP=  "show_minimap";
const VSLANGPROPNAME_HEX_NOFCOLS=  "hex_nofcols";
const VSLANGPROPNAME_HEX_BYTES_PER_COL=  "hex_bytes_per_col";
const VSLANGPROPNAME_USE_CONTINUATION_INDENT_ON_FUNCTION_PARAMETERS_LIST= "listalign_fun_call_params_list";
const VSLANGPROPNAME_TAB_STYLE=    "tab_style";
/**
 * This struct encapsulates language specific options stored in 
 * the language.<LangId> profile
 *  
 * @see _GetDefaultLanguageOptions() 
 * @see _SetDefaultLanguageOptions() 
 */
typedef typeless VS_LANGUAGE_OPTIONS;
extern _str _LangOptionsGetProperty(VS_LANGUAGE_OPTIONS &langOptions,_str propertyName, _str defaultValue='',bool &apply=null);
extern _str _LangOptionsSetProperty(VS_LANGUAGE_OPTIONS &langOptions,_str propertyName, _str value,bool &apply=null);

/** 
 * Essential language specific options. 
 * These are only the options found in def-language-[lang].  
 */
struct VS_LANGUAGE_SETUP_OPTIONS {
   _str mode_name;
   _str tabs;
   _str margins;
   _str keytab_name;
   int word_wrap_style;
   bool indent_with_tabs;
   int show_tabs;
   int indent_style;
   _str word_chars;
   _str lexer_name;
   int color_flags;
   int line_numbers_len;
   int TruncateLength;
   _str bounds;
   int caps;
   bool SoftWrap;
   bool SoftWrapOnWord;
   int hex_mode;
   int line_numbers_flags;
   bool AutoLeftMargin;
   int FixedWidthRightMargin;
};
// compatibility with pre-12.0 slickedit
typedef VS_LANGUAGE_SETUP_OPTIONS VSEXTSETUPOPTIONS;

/**
 * Sets language specific options for a specific language.
 *
 * @param lang          File language ID (see {@link p_LangId}).
 *                      For list of language types, 
 *                      use our Language Options dialog
 *                      ("Tools", "Options...", "Language Manager")
 * @param langOptions   New language specific options for
 *                      <i>pszExtension</i>.  Since all options are
 *                      must be set, use the 
 *                      <b>vsGetDefaultLanguageOptions</b>
 *                      first to query the existing value before
 *                      setting new values.
 *
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions
 *
 * @categories Configuration_Functions
 */
extern void _SetDefaultLanguageOptions(_str langId, VS_LANGUAGE_OPTIONS &options);

/**
 * Gets language specific options for a specific language type.
 *
 * @return Returns 0 if successful.
 *
 * @param lang          Language ID (see {@link p_LangId}).
 *                      For list of language types, 
 *                      use our Language Manager dialog
 *                      ("Tools", "Options...", "Language Manager")
 * @param langOptions   Initialized to language specific options 
 *                      for <i>pszLangId</i>.
 *    
 * @see _SetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteLanguageOptions
 * @see _SetDefaultLanguageOptions
 *
 * @categories Configuration_Functions
 */
extern int _GetDefaultLanguageOptions(_str langId, VS_LANGUAGE_OPTIONS &options);
//extern int _LangSetDefaultIndentWithTabs(_str langId, bool value, bool createNewLang=false);



/**
 * Returns true if language has been defined.
 * 
 * @param langId 
 * 
 * @return Returns true if language has been defined.
 *  
 * @categories Configuration_Functions
 */
extern bool _LangIsDefined(_str langId);


/**
 * Clears cache for LangId profile
 * 
 * @param langId 
 *  
 * @categories Configuration_Functions
 */
extern void _LangClearCache(_str langId);
/**
 * Returns a language property value
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param defaultValue    return value if propert doesn't 
 *                        exist.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @return Returns property value for language specified
 *  
 * @categories Configuration_Functions 
 *  
 */
extern _str _LangGetProperty(_str langId,_str propertyName,_str defaultValue='', bool &apply=null);
/**
 * Returns the default beautifier profile for the language 
 * specified.
 * 
 * @param langId 
 * 
 * @return Returns the default beautifier profile for the 
 * language. Return "", if no beautifer valid default profile 
 * exists. 
 *  
 * @categories Configuration_Functions 
 *  
 */
extern _str _LangGetBeautifierDefault(_str langId);
/**
 * Returns XML value for property
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @return If successful, Returns XMLCFG handle for xml value. 
 *         Otherwise, a negative error code is return.
 *  
 * @categories Configuration_Functions 
 *  
 */
extern int _LangGetPropertyXml(_str langId,_str propertyName, bool &apply=null);
/**
 * Retrieves property attributes for attr element
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param hashtab (Output only) Set to attributes of first 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 *  
 * @categories Configuration_Functions 
 *  
 */
extern void _LangGetPropertyAttrs(_str langId,_str propertyName, _str (&hashtab):[], bool &apply=null);
/**
 * Retrieves property attributes for attr element and puts them 
 * in class where class members match the attribute names. 
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param className Class name. Used to construct new instance.
 * @param classInst (Output only) Results for attributes 
 *                of first &lt;attr&gt; element beneath the
 *                &lt;p&gt; element.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 *  
 * @categories Configuration_Functions 
 *  
 */
extern void _LangGetPropertyClass(_str langId,_str propertyName, _str className, typeless &classInst, bool &apply=null);

/**
 * Returns a 32-bit integer language property value
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param defaultValue    return value if propert doesn't 
 *                        exist.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @return Returns property value for language specified
 *  
 * @categories Configuration_Functions 
 *  
 */
extern bool _LangGetPropertyBool(_str langId,_str propertyName,bool defaultValue=false, bool &apply=null);
/**
 * Returns a 32-bit integer language property value
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param defaultValue    return value if propert doesn't 
 *                        exist.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @return Returns property value for language specified
 *  
 * @categories Configuration_Functions 
 *  
 */
extern int _LangGetPropertyInt32(_str langId,_str propertyName,int defaultValue=0, bool &apply=null);

/**
 * Returns a 64-bit integer language property value
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param defaultValue    return value if propert doesn't 
 *                        exist.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @return Returns property value for language specified
 *  
 * @categories Configuration_Functions 
 *  
 */
extern long _LangGetPropertyInt64(_str langId,_str propertyName,long defaultValue=0, bool &apply=null);

/**
 * Sets a property value for the specified language.
 * 
 * @param langId 
 * @param propertyName    Property name
 * @param value           value for property
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetProperty(_str langId,_str propertyName,_str value, bool &apply=null);
/**
 * Sets a property value to XML for the specified language.
 * 
 * @param langId 
 * @param propertyName    Property name
 * @param handle          XMLCFG handle 
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetPropertyXml(_str langId,_str propertyName,int handle, bool &apply=null);

/**
 * sets property attrs for profile specified.
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param hashtab Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetPropertyAttrs(_str langId,_str propertyName,_str (&hashtab):[], bool &apply=null);

/**
 * sets property attrs for profile specified.
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param classInst Attribute name and value pairs. Put in 
 *                &lt;attr&gt; element beneath the &lt;p&gt;
 *                element.
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetPropertyClass(_str langId,_str propertyName,typeless &classInst, bool &apply=null);

/**
 * Sets a propert value for the specified language.
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param value           
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetPropertyInt32(_str langId,_str propertyName,int value, bool &apply=null);

/**
 * Sets a propert value for the specified language.
 * 
 * @param langId 
 * @param propertyName    Language specific property name
 * @param value 
 * @param apply           Set to "apply" attribute for property. 
 *                        If not present set to true.
 * 
 * @categories Configuration_Functions 
 *  
 */
extern void _LangSetPropertyInt64(_str langId,_str propertyName,long value, bool &apply=null);

/**
 * Takes a space-delimited list of extensions and maps them to 
 * the given language.  Any extensions which currently map to 
 * the language but which are not in the list will have their 
 * mappings removed. 
 * 
 * @param langId 
 * @param extlist 
 *  
 * @categories Configuration_Functions
 */
extern void _LangSetExtensions(_str langId, _str extlist);

/**
 * Returns a space delimited list of all the extensions that map 
 * to the given language. 
 * 
 * @param langId 
 * 
 * @return _str 
 *  
 * @categories Configuration_Functions
 */
extern _str _LangGetExtensions(_str langId);

/**
 * Sets the language that the given extension refers to.  All 
 * files opened with the given extension will be put into the 
 * specified language mode. 
 * 
 * @param ext                 extension to set value for
 * @param langId              langugage extension refers to 
 *  
 * @see _ExtensionGetRefersTo 
 *  
 * @categories Configuration_Functions
 */
extern void _ExtensionSetRefersTo(_str ext, _str langId);

/**
 * Gets the language that the given extension refers to.  All 
 * files opened with the given extension are put into the 
 * specified language mode. 
 * 
 * @param ext                 extension to get value for 
 *  
 * @return                    langugage extension refers to 
 *  
 * @see _ExtensionSetRefersTo 
 *  
 * @categories Configuration_Functions
 */
extern _str _ExtensionGetRefersTo(_str ext);

/**
 * Indicates that the given extension should be ignored, delegating to the 
 * inner file extension or inner file name to determine the correct language mode. 
 *  
 * This option has a lower precedence than referring an extension to a language mode.
 *  
 * @param ext                 extension to set value for
 * @param yesno               'yes' to ignore suffix, no to handle normally.
 *  
 * @see _ExtensionGetRefersTo 
 *  
 * @categories Configuration_Functions
 */
extern void _ExtensionSetIgnoreSuffix(_str ext, bool yesno);

/**
 * Indicates that the given extension should be ignored, delegating to the 
 * inner file extension or inner file name to determine the correct language mode. 
 *  
 * This option has a lower precedence than referring an extension to a language mode.
 * 
 * @param ext                 extension to get value for 
 *  
 * @return                    'true' to ignore suffix, 'false' to treat as 'Plain Text'
 *  
 * @see _ExtensionSetRefersTo 
 *  
 * @categories Configuration_Functions
 */
extern bool _ExtensionGetIgnoreSuffix(_str ext);

/**
 * Sets the encoding for this extension.  This option is 
 * accessible on the File Extension Manager. 
 *
 * @param ext                 extension to set value for
 * @param value               new value 
 *  
 * @see _ExtensionGetEncoding 
 *  
 * @categories Configuration_Functions
 */
extern void _ExtensionSetEncoding(_str ext, _str encoding);

/**
 * Gets the encoding for this extension.  This option is 
 * accessible on the File Extension Manager. 
 *
 * @param ext                 extension to get value for
 *  
 * @return                    encoding info for this extension 
 *  
 * @see _ExtensionGetEncoding 
 *  
 * @categories Configuration_Functions
 */
extern _str _ExtensionGetEncoding(_str ext);

/**
 * Sets the default dtd for this extension.  This option is 
 * accessible on the File Extension Manager. 
 *
 * @param ext                 extension to set value for
 *  
 * @return                    encoding info for this extension 
 *  
 * @see _ExtensionGetDefaultDTD 
 *  
 * @categories Configuration_Functions
 */
extern void _ExtensionSetDefaultDTD(_str ext, _str dtd);

/**
 * Gets the default dtd for this extension.  This option is 
 * accessible on the File Extension Manager. 
 *
 * @param ext                 extension to get value for
 *  
 * @return                    encoding info for this extension
 *  
 * @see _ExtensionSetDefaultDTD 
 *  
 * @categories Configuration_Functions
 */
extern _str _ExtensionGetDefaultDTD(_str ext);

/**
 * Sets the file association information for this extension. 
 * This option is accessible on the File Extension Manager. 
 *
 * @param ext                 extension to set value for
 * @param useFA               whether to use file assocation for 
 *                            this extension
 * @param openApp             application to use to open files 
 *                            of this type
 *  
 * @see _ExtensionGetFileAssociation 
 *  
 * @categories Configuration_Functions
 */
extern void _ExtensionSetFileAssociation(_str ext, int useFA, _str openApp);

/**
 * Gets the file association for this extension.  This option is
 * accessible on the File Extension Manager. 
 *
 * @param ext                 extension to get value for
 * @param useFA               whether to use file assocation for 
 *                            this extension
 * @param openApp             application to use to open files 
 *                            of this type
 *  
 * @see _ExtensionSetFileAssociation 
 *  
 * @categories Configuration_Functions
 */
extern int _ExtensionGetFileAssociation(_str ext, int& useFA, _str& openApp);

/**
 * Creates a new language with the given options.
 * 
 * @param langId     Language ID (see {@link p_LangId} 
 * @param langOptions   Structure with options.
 *  
 * @see _CreateExtension 
 * @see _ExtSetupToInfo 
 *  
 * @categories Configuration_Functions
 */
extern void _CreateNewLanguage(_str langId, VS_LANGUAGE_OPTIONS &langOptions);

/**
 * Creates file extension specific setup data which is used by the
 * File Extension Manager options dialog.  This procedure is typically used 
 * when associating a physical file extension with a specific language, or when
 * setting up encoding and application preferences for a physical file 
 * extension. 
 *  
 * @example 
 * <pre>
 *    _CreateExtension('ada', 'ada');
 *    _CreateExtension('ads', 'ada');
 * </pre>
 *  
 * @param extension        File extension to be configured.
 * @param langId           Language ID (see {@link p_LangId} 
 * @param encoding         (optional) default file encoding 
 * @param openApplication  (optional) path for external application used to 
 *                         open this type of file when double-clicked on in
 *                         project file browser.
 * @param useAssociation   (optional, Windows only) use Windows file 
 *                         association to select application for opening this
 *                         type of file when double-clicked on in the
 *                         project file browser.
 *
 * 
 * @see _CreateLanguage
 * @categories Configuration_Functions 
 */
extern void _CreateExtension(_str ext, _str langId, _str encoding='', _str openApp='', int useAssociation=0, int ignoreSuffix=0);

/**
 * Removes the language setup options for the specific 
 * language, as specified by the given language ID. 
 * Note that 'lang' must be a real language ID, not a 
 * referred file extension. 
 *
 * @param lang    Language ID (see {@link p_LangId} 
 *
 * @see _SetDefaultLanguageOptions
 * @see _GetDefaultLanguageOptions
 * @see _SetExtensionReferTo
 * @see _DeleteExtensionOptions 
 * @see _Filename2LangId 
 * @see _Ext2LangId
 * @see setupext 
 *
 * @categories Configuration_Functions 
 * @since 13.0 
 */
extern void _DeleteLanguageOptions(_str langId);

/** 
 * Deletes a file extension mapping.
 *
 * @param extension  File extension. 
 *                   For list of file extensions, use our
 *                   Language Options dialog ("Tools",
 *                   "Options...", "File Extension Manager").
 *  
 * @see _CreateExtension 
 * @see _DeleteLanguageOptions 
 * @see _Filename2LangId 
 * @see _Ext2LangId
 * @see setupext 
 *
 * @categories Configuration_Functions
 */
extern void _DeleteExtension(_str ext);

/**
 * Retrieves a list of the lang ids of all the languages 
 * currently set up within SlickEdit.   
 * 
 * @param langs      language ids (see {@link p_LangId}) 
 *  
 * @categories Miscellaneous_Functions
 */
extern void _GetAllLangIds(_str (&langs)[]);

/**
 * Retrieves a list of all the extensions currently configured 
 * in SlickEdit 
 * 
 * @param extList    list of extensions
 *  
 * @categories Miscellaneous_Functions
 */
extern void _GetAllExtensions(_str (&extList)[]);

/**
 * Default open and save as file extension.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_ext;
int def_maxbackup_ksize;
_str gMissingDllList;
_str def_wide_ext;
_str def_word_delim;
/**
 * Regular expression for customizing error handling.
 *
 * @default
 * @categories Configuration_Variables
 *
 * @see next_error
 * @see prev_error
 */
typeless def_print_filter;
typeless def_print_command;

/**
 * Buffer list options.
 * <ul>
 * <li><b>SORT_BUFLIST_FLAG</b> -- sort the buffer list
 * <li><b>SEPARATE_PATH_FLAG</b> -- separate paths
 * <li><b>SHOW_SYSTEM_BUFFERS_FLAG</b> -- show system buffers
 * <li><b>SELECT_ACTIVE_BUFFER</b> -- select the active buffer
 * <li><b>FORCE_OLD_BUFLIST</b> -- Use old list buffers dialog
 * </ul>
 *
 * @default SORT_BUFLIST_FLAG | SEPARATE_PATH_FLAG
 * @categories Configuration_Variables
 *
 * @see list_buffers
 * @see list_modified
 */
int def_buflist;

_str def_preplace;
/**
 * If enabled, allow cursor to be positioned in virtual
 * space past the end of the line when clicking with the mouse.
 *
 * @default false
 * @categories Configuration_Variables
 *
 * @see mou_click
 */
_str def_click_past_end;
_str def_show_cb_name;

/**
 * Selecting text with CHAR selection, either with mouse or CUA Shift-keys,
 * will select newline chars at end of selected text in the following cases:
 *
 * <ol>
 *   <li>Selection begins and ends on same line AND beginning of selection
         is at beginning of line.
 *   <li>Selecting backward and beginning of selection is before end of selection.
 *   <li>Selecting forward and end of selection is after beginning of selection.
 * </ol>
 *
 * <p>
 * The selected lines, internally, are treated as a LINE selection, while
 * being seen by the user as a CHAR selection. This facilitates copy/cut
 * of PIC data (e.g. breakpoints) as if the selected lines were part of a
 * LINE selection, but the user can still paste the copied/cut selection
 * as a CHAR selection.
 * </p>
 *
 * @example Example of keys and events that use this setting: Shift+Home, Shift+End,
 * Shift+Left, Shift+Right, Shift+Down, LButton-down and drag to select.
 */
const VS_WPSELECT_NEWLINE=       0x1;

/**
 * Selecting text with mouse from left margin will use a CHAR selection instead
 * of a LINE selection. In addition, the newline chars of the last selected line
 * are included in the selection, which effectively selects the entire line.
 *
 * <p>
 * The selected lines, internally, are treated as a LINE selection, while
 * being seen by the user as a CHAR selection. This facilitates copy/cut
 * of PIC data (e.g. breakpoints) as if the selected lines were part of a
 * LINE selection, but the user can still paste the copied/cut selection
 * as a CHAR selection.
 * </p>
 */
const VS_WPSELECT_MOU_CHAR_LINE= 0x2;

/**
 * @return Word processor style selection flags. See VS_WPSELECT_* for more
 * information.
 */
int def_wpselect_flags;

/**
 * Set to true if you want next_bookmark and prev_bookmark to ONLY navigate
 * bookmarks in the current buffer/file.
 */
bool def_vcpp_bookmark;

/**
 * Do extra checking to see if the file's contents have been modified when its
 * timestamp has changed.  When on we will always perform this 
 * check.
 * 
 * <p>This variable was previously deprecated. It is no longer
 * used but in order for a users configure to be transfered
 * correctly, we can't have a compilation error due to this
 * variable being deprecated. see
 * def_autoreload_compare_whole_file and
 * def_autoreload_compare_whole_file_max_size
 *
 * @default false
 * @categories Configuration_Variables 
 */
bool def_filetouch_checking;

/**
 * When true, if size of buffer is below
 * <B>def_autoreload_compare_whole_file_max_size</B>, compare
 * buffer contents to file before reporting it as modified.
 * This is for file systems that get dates incorrect.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_autoreload_compare_contents;

/**
 * Maximum file size in bytes on which we will perform whole 
 * file comparision when <B>def_autoreload_compare_contents</B> 
 * is true.
 * 
 * @default 2000
 * @categories Configuration_Variables
 */
int def_autoreload_compare_contents_max_ksize;

/** 
 * Show all files that need to be reloaded or resaved in a single select tree
 * dialog, rather than one dialog per file.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_batch_reload_files;

/**
 * C/C++ style options -- STYLE 1 braces
 *
 * <pre>
 * if (expr)
 * {
 *    ++i;
 * }
 * </pre>
 */
const VS_C_OPTIONS_STYLE1_FLAG=                   0x0001;
/**
 * C/C++ style options -- STYLE 2 braces
 *
 * <pre>
 * if (expr)
 *    {
 *    ++i;
 *    }
 * </pre>
 */
const VS_C_OPTIONS_STYLE2_FLAG=                   0x0002;
/**
 * C/C++ style options -- insert braces immediately
 */
const VS_C_OPTIONS_BRACE_INSERT_FLAG=             0x0004;
/**
 * C/C++ style options -- insert blank line between braces
 */
const VS_C_OPTIONS_BRACE_INSERT_LINE_FLAG=        0x0008;
/**
 * C/C++ style options -- no space before paren
 *
 * <pre>
 * if(expr) {
 *    ++i;
 * }
 * </pre>
 */
const VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN=         0x0010;   // "if(" or "if ("
/**
 * C/C++ style options -- insert function braces on new line
 */
const VS_C_OPTIONS_BRACE_INSERT_FUNCTION_FLAG=    0x0020;
/**
 * C/C++ style options -- char* p;
 */
const VS_C_OPTIONS_SPACE_AFTER_POINTER=           0x0040;
/**
 * C/C++ style options -- char * p;
 */
const VS_C_OPTIONS_SPACE_SURROUNDS_POINTER=       0x0080;
/**
 * C/C++ style options -- if ([space][cursor][space])
 */
const VS_C_OPTIONS_INSERT_PADDING_BETWEEN_PARENS= 0x0100;
/**
 * C/C++ style options -- quick brace/unbrace one lines statements
 *                     -- if ( cond ) doSomething();
 *                     -- if ( cond ) {
 *                           doSomething();
 *                        }
 */
const VS_C_OPTIONS_NO_QUICK_BRACE_UNBRACE= 0x0200;
/**
 * C/C++ style options -- "else" on same line as "}" 
 *                     -- primarily applies to quick brace 
 *                     -- if ( cond )
 *                           doSomething();
 *                        else
 *                           doSomethingElse();
 *                     -- if ( cond ) {
 *                           doSomething();
 *                        }
 *                        else {
 *                           doSometingElse();
 *                        }
 * 
 */
const VS_C_OPTIONS_ELSE_ON_LINE_AFTER_BRACE= 0x0400;


// Commands to pass to HtmlHelp()

const HH_DISPLAY_TOPIC=        0x0000;
//const HH_HELP_FINDER=          0x0000;
const HH_DISPLAY_TOC=          0x0001;
const HH_DISPLAY_INDEX=        0x0002;     // Windows only
const HH_DISPLAY_SEARCH=       0x0003;     // Windows only
//const HH_SET_WIN_TYPE=         0x0004;
//const HH_GET_WIN_TYPE=         0x0005;
//const HH_GET_WIN_HANDLE=       0x0006;
//const HH_ENUM_INFO_TYPE=       0x0007;
//const HH_SET_INFO_TYPE=        0x0008;
//const HH_SYNC=                 0x0009;
//const HH_RESERVED1=            0x000A;
//const HH_RESERVED2=            0x000B;
//const HH_RESERVED3=            0x000C;
const HH_KEYWORD_LOOKUP=       0x000D;
//const HH_DISPLAY_TEXT_POPUP=   0x000E;
//const HH_HELP_CONTEXT=         0x000F;
//const HH_TP_HELP_CONTEXTMENU=  0x0010;
//const HH_TP_HELP_WM_HELP=      0x0011;
//const HH_CLOSE_ALL=            0x0012;
//const HH_ALINK_LOOKUP=         0x0013;
//const HH_GET_LAST_ERROR=       0x0014;
//const HH_ENUM_CATEGORY=        0x0015;
//const HH_ENUM_CATEGORY_IT=     0x0016;
//const HH_RESET_IT_FILTER=      0x0017;
//const HH_SET_INCLUSIVE_FILTER= 0x0018;
//const HH_SET_EXCLUSIVE_FILTER= 0x0019;
//const HH_INITIALIZE=            0x001C;
//const HH_UNINITIALIZE=          0x001D;
//const HH_PRETRANSLATEMESSAGE=  0x00fd;
//const HH_SET_GLOBAL_PROPERTY=  0x00fc;

const BG_SEARCH_ACTIVE=         (0x01);
const BG_SEARCH_UPDATE=         (0x02);
const BG_SEARCH_TERMINATING=    (0x04);
int gbgm_search_state;

/**
 * When on, cursor up/down/left/right moves to begin/end of selection.
 * Enabled by default in Visual C++ and Visual Studio emulations.
 *
 * @default false
 * @categories Configuration_Variables
 *
 * @see cursor_left
 * @see cursor_right
 */
bool def_cursor_beginend_select;
/**
 * If enabled, cursor movement emulates having real tabs rather
 * than spaces in the leading whitespace of a line.
 *
 * @default false
 * @categories Configuration_Variables
 */
bool def_emulate_leading_tabs;

struct VSEVENT_BINDING {
   int iEvent;
   int iEndEvent;
   int binding;
};

/**
 * Types that can be imported to the project properties dialog.
 *
 * @default "Text Files (*.txt)";
 * @categories Configuration_Variables
 */
_str def_import_file_types;

/**
 * Options for current context tool window. 
 * This is a bitset of the following flags:
 * <ul> 
 * <li>CONTEXT_TOOLBAR_ADD_LOCALS -- 
 * Do not include local variables in the list and do not 
 * display them as the current context.
 * <li>CONTEXT_TOOLBAR_SORT_BY_LINE -- sort the items in the list 
 * by line number rather than alphabetically. 
 * <li>CONTEXT_TOOLBAR_DISPLAY_LOCALS -- 
 * include local variables when
 * displaying the current symbol under the cursor. 
 * Set to "0" to only show tags in context. 
 * Note that the drop down list will always be display locals 
 * for navigation purposes independent of this setting. 
 * </ul>
 *
 * @default CONTEXT_TOOLBAR_ADD_LOCALS=1
 * @categories Configuration_Variables
 */
int def_context_toolbar_flags;
const CONTEXT_TOOLBAR_ADD_LOCALS=     0x01;
const CONTEXT_TOOLBAR_SORT_BY_LINE=   0x02;
const CONTEXT_TOOLBAR_DISPLAY_LOCALS= 0x04;

int def_autoclose_flags/*=3*/;

// Java Refactoring def vars
int def_jrefactor_auto_import; // Determines whether auto add import functionality is used

/**
 * JDK 6 root directory.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_java_live_errors_jdk_6_dir;
/**
 * JDK 6 jvm lib file
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_java_live_errors_jvm_lib;
/**
 * Tracks whether or not the RTE thread has reported an error during
 * compilation
 *
 * @default false 
 * @categories Configuration_Variables
 */
int def_java_live_errors_errored;
/**
 * Amount of time in microseconds to wait before Java live
 * errors should update the current buffer.
 *
 * @default 250
 * @categories Configuration_Variables
 */
int def_java_live_errors_sleep_interval;
/**
 * If enabled, show pedantic Java warnings with live errors.
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_java_live_errors_pedantic;
/**
 * If enabled, do not display asserts for Java live errors.
 *
 * @default false
 * @categories Configuration_Variables
 */
int def_java_live_errors_no_asserts;
/**
 * If enabled, show Java deprecation warnings with live errors.
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_java_live_errors_deprecation_warning;
/**
 * If enabled, do not show warnings with Java live errors.
 *
 * @default 1
 * @categories Configuration_Variables
 */
int def_java_live_errors_no_warnings;
/**
 * Enable incremental compilation with Java live errors.
 * This will slightly improve performance.
 *
 * @default false
 * @categories Configuration_Variables
 */
int def_java_live_errors_incremental_compile;
/**
 * If enabled, use 'Other Options' from the 'Compiler' tab for 
 * Java live errors. 
 *
 * @default 0 
 * @categories Configuration_Variables
 */
int def_java_live_errors_other_options;

/**
 * Initial Java heap size for live errors.  0 means use Java 
 * default.  Only intended to be modified through Java Options. 
 *
 * @default 0 
 * @categories Configuration_Variables
 */
int def_java_live_errors_init_heap_size;
/**
 * Maximum Java heap size for live errors.  0 means use Java 
 * default.  Only intended to be modified through Java Options. 
 *
 * @default 0 
 * @categories Configuration_Variables
 */
int def_java_live_errors_max_heap_size;
/**
 * Java stack size for live errors. 0 means use Java default. 
 * Only intended to be modified through Java Options. 
 *
 * @default 0 
 * @categories Configuration_Variables
 */
int def_java_live_errors_stack_size;
/**
 * List of J2ME phone types.
 *
 * @default 'DefaultColorPhone;DefaultGrayPhone;MediaControlSkin;QwertyDevice'
 * @categories Configuration_Variables
 */
_str def_j2me_phone_types/*='DefaultColorPhone;DefaultGrayPhone;MediaControlSkin;QwertyDevice'*/;
/**
 * Tell antmake to use SE classpath settings  
 *
 * @default 1  
 * @categories Configuration_Variables
 */
int def_antmake_use_classpath;
/**
 * Tell Eclipse to open extensionless files with SlickEdit.  
 *
 * @default true  
 * @categories Configuration_Variables
 */
bool def_eclipse_extensionless;
/**
 * Tell Eclipse to attempt to decipher language mode for 
 * extensionless files with SlickEdit. 
 *
 * @default true  
 * @categories Configuration_Variables
 */
bool def_eclipse_check_ext_mode;
/**
 * Display targets imported from external Ant files 
 *
 * @default true  
 * @categories Configuration_Variables
 */
bool def_antmake_display_imported_targets;
/**
 * Filter matches for Ant goto_definition functionality for 
 * visibility: do not show results which are not visible from 
 * where the command was invoked. 
 *
 * @default false 
 * @categories Configuration_Variables
 */
bool def_antmake_filter_matches;
/**
 * Parse XML files when opened in order to identify Ant build 
 * files. 
 *
 * @default true  
 * @categories Configuration_Variables
 */
bool def_antmake_identify;
/**
 * Maximum size of a file that _IsAntBuildFile will recognize
 *
 * @default true  
 * @categories Configuration_Variables
 */
int def_max_ant_file_size;


const VSBLRESULTFLAG_NEWFILECREATED=      0x1;
const VSBLRESULTFLAG_NEWTEMPFILECREATED=  0x2;
const VSBLRESULTFLAG_NEWFILELOADED=       0x4;
const VSBLRESULTFLAG_READONLYACCESS=      0x8;
const VSBLRESULTFLAG_ANOTHERPROCESS=      0x10;
const VSBLRESULTFLAG_READONLY=            (VSBLRESULTFLAG_READONLYACCESS|VSBLRESULTFLAG_ANOTHERPROCESS);
const VSBLRESULTFLAG_NEW=                 (VSBLRESULTFLAG_NEWFILECREATED|VSBLRESULTFLAG_NEWTEMPFILECREATED|VSBLRESULTFLAG_NEWFILELOADED);

// this tells us when postinstall.e was last run...well not so much 'when' as much as
// 'which version'
_str _post_install_version;

struct WORKSPACE_LIST {
   bool isFolder;
   _str filename;    // directory name or filename
   _str caption;
   union {
      _str description;  // If name is a filename, this is the description
      WORKSPACE_LIST list[];
   } u;
   _str projectname;  // current selected project
};

WORKSPACE_LIST def_workspace_info[];

/**
 * Sets p_completion on the EditInPlace text box of the active
 * tree control if there is one
 *
 * @param completion The completion argument to use
 *
 * @categories Tree_View_Methods 
 *  
 * @deprecated This is done during CHANGE_EDIT_OPEN_COMPLETE
 */
extern void _SetEditInPlaceCompletion(_str completion);

// SlickEdit Tools specific stuff
int def_msvsp_temp_wid;

/**
 * Enables automatic completion of C style comment block start and end markers. 
 * Typing <pre>    /&#42</pre> on a blank line will auto complete to <pre>    /&#42&#42/</pre>  
 * with the cursor placed between the two astericks.
 *
 * @default true
 * @categories Configuration_Variables
 */
bool def_auto_complete_block_comment;

/** 
 * Modes for commenting lines 
 *    LEFT_MARGIN - put comments at left margin (overstrike)
 *    LEVEL_OF_INDENT - at level of indent of first line of
 *    selection
 *    START_AT_COLUMN - comments at a certain column
 */
_metadata enum COMMENT_LINE_MODE{
   LEFT_MARGIN,
   LEVEL_OF_INDENT,
   START_AT_COLUMN
};

/**
 * Default line comment mode. 
 *  
 * @default LEFT_MARGIN
 */
COMMENT_LINE_MODE def_comment_line_mode;

//Comment wrap default settings and constants
/**
 * Number of consecutive line comments needed for the comment wrapping feature
 * to recognize the line comments as a block that can be wrapped.
 *
 * @default 2
 * @categories Configuration_Variables
 */
int def_cw_line_comment_min;

/** 
 * When non-zero, only workspace files show up in version 
 * control GUI updates.  This will reduce noise in wildcard 
 * projects. 
 */
int def_svc_update_only_shows_wkspace_files;
/** 
 * When non-zero, only controlled files show up in version 
 * control GUI updates.  This will reduce noise in some setups. 
 */
int def_svc_update_only_shows_controlled_files;
/**
 * Maximum number of lines in a block comment or in a block of consecutive line 
 * comments that will be analyzed when trying to automatically determine the 
 * proper width on the comment. Comment wrapping will look analyze at most 
 * def_cw_analyze_lines_max number of lines above the cursor position and 
 * def_cw_analyze_lines_max number of lines below the cursor postion. 
 *
 * @default 100
 * @categories Configuration_Variables
 */
int def_cw_analyze_lines_max;

// String holding default comemnt wrap settings
_str CW_commentWrapDefaultsStr;
//Default values for fixed width and right margin.  Used only when
// extensions dialog returns strings that can not be parsed to int
int CW_defaultFixedWidth;
int CW_defaultRightMargin;
int CW_defaultLineCommentMin;
//Constants used to look up comment wrap settings
_metadata enum CommentWrapSettings {
   CW_ENABLE_BLOCK_WRAP          =  1,
   CW_ENABLE_DOCCOMMENT_WRAP     =  2,
   CW_AUTO_OVERRIDE              =  3,
   CW_JAVADOC_AUTO_INDENT        =  4,
   CW_USE_FIXED_WIDTH            =  5,
   CW_FIXED_WIDTH_SIZE           =  6,
   CW_USE_FIRST_PARA             =  7,
   CW_USE_FIXED_MARGINS          =  8,
   CW_RIGHT_MARGIN               =  9,
   CW_MAX_RIGHT                  = 10,
   CW_MAX_RIGHT_COLUMN           = 11,
   CW_MAX_RIGHT_DYN              = 12,
   CW_MAX_RIGHT_COLUMN_DYN       = 13,
   CW_MATCH_PREV_PARA            = 14,
   CW_ENABLE_LINEBLOCK_WRAP      = 15,
   CW_ENABLE_COMMENT_WRAP        = 16,
   CW_LINE_COMMENT_MIN           = 17,
};
//Constants used to look up xml/html wrap settings
//const  XW_ENABLE_FEATURE=           1;
const  XW_ENABLE_CONTENTWRAP=         2;
const  XW_ENABLE_TAGLAYOUT=           3;
const  XW_DEFAULT_SCHEME=             4;
const XW_NODEFAULTSCHEME= '__NODEFAULT';
_str XW_xmlWrapDefaultsStr;
_str XW_xmlWrapDefaultsStrDocbook;
/**
 * Default xml/html tag nesting depth for searching tags that preserve content.
 *
 * @default 10
 * @categories Configuration_Variables
 */
int def_xw_pre_tag_search_depth;

//Define the triggers and styles for Doc Comment skeleton creation
const DocCommentTrigger1=      '/**';
const DocCommentTrigger2=      '/*!';
const DocCommentTrigger3=      '///';
const DocCommentTrigger4=      '//!';
const DocCommentStyle1=        '@';
const DocCommentStyle2=        '\';
const DocCommentStyle3=        '<>';

/**
 * This struct encapsulates the information needed to
 * perform syntax expansion and display syntax expansion choices.
 * <p>
 * This information is plugged into a hash table, mapping
 * the keyword that triggers syntax expansion to this entry.
 *
 * @example
 * <pre>
 * SYNTAX_EXPANSION_INFO space_words:[] = {
 *     if     => { "if ( ... ) { ... }" },
 *     do     => { "do { ... } while ( ... );" },
 * }
 * </pre>
 */
struct SYNTAX_EXPANSION_INFO {
   _str statement;
};

// Stringize macro that double-quotes the input argument
#define stringize(a) #a

// token IDs for <ext>_next_sym() and <ext>_prev_sym() functions
const TK_ID= 1;
const TK_NUMBER= 2;
const TK_STRING= 3;
const TK_KEYWORD= 4;

struct VSSTREAMMARKERINFO {
   bool isDeferred;
   union {
      int buf_id;
      _str DeferredBufName;
   };
   long StartOffset;
   long Length;
   int BMIndex;
   int type;
   int MousePointer;
   int RGBBoxColor;
   int ColorIndex;
   _str msg;
};
struct VSLINEMARKERINFO {
   bool isDeferred;
   union {
      int buf_id;
      _str DeferredBufName;
   };
   int LineNum;  // Set to -1 for markids
   int NofLines;
   int BMIndex;
   int type;
   _str msg;
   int MousePointer;
   int RGBBoxColor;
   int markid;
};

extern int _StreamMarkerGet(int StreamMarkerIndex,VSSTREAMMARKERINFO &info);
extern int _LineMarkerGet(int LineMarkerIndex,VSLINEMARKERINFO &info);

/**
 * Disable replace tooltip helper used for search and replace.
 *
 * @categories Configuration_Variables
 */
bool def_disable_replace_tooltip;

/**
 * Disables automatic error markers after builds are complete.
 *
 * @categories Configuration_Variables
 */
bool def_disable_postbuild_error_markers;

/**
 * Disables automatic error scroll markers after builds are 
 * complete. 
 *
 * @categories Configuration_Variables
 */
bool def_disable_postbuild_error_scroll_markers;

const VSDEFAULT_DIALOG_FONT_SIZE = 8;
const VSDEFAULT_DIALOG_FONT_NAME = "Default Dialog Font";
const VSOEM_FIXED_FONT_NAME = "OEM Fixed Font";
const VSANSI_VAR_FONT_NAME = "ANSI Proportional Font";
const VSANSI_FIXED_FONT_NAME = "ANSI Fixed Font";
const VSDEFAULT_UNICODE_FONT_NAME = "Default Unicode Font";
const VSDEFAULT_FIXED_FONT_NAME = "Default Fixed Font";
const VSDEFAULT_COMMAND_LINE_FONT_NAME = "Default Command Line Font";
const VSDEFAULT_MENU_FONT_NAME = "Default Menu Font";
const VSDEFAULT_MDICHILD_FONT_NAME = "Default MDI Child Font";

// Indicates whetherCompletion e and edit lists binary files.
// When in Brief emulation, a_match should screen out binary files based on
// extension list in def_binary_ext
bool def_list_binary_files;

/**
 * Additional clipboard formats to push to the system clipboard.
 * One or more of the following formats are available:
 *
 *    'H' - 'HTML Format'
 *
 * @categories Configuration_Variables
 */
_str def_clipboard_formats;

/**
 * Maximum size (in bytes) for preview displayed in Clipboards 
 * tool window
 *
 * @categories Configuration_Variables
 */
int def_clipboards_max_preview;

/**
 * Shows or hides dot files in file and directory list controls,
 * as in Open/Edit dialog.
 *
 * @categories Configuration_Variables
 */
bool def_filelist_show_dotfiles;

/**
 * Maximum number of error markers to process in postbuild. Set 
 * to &lt;0 to always process all errors. 
 *  
 * @categories Configuration_Variables
 */
int def_max_error_markers;

/**
 * Toggles selection type between block and character.  Off by
 * default.  Used in Eclipse emulation.
 *  
 * @categories Configuration_Variables
 */
bool def_select_type_block;

/**
 * Settings for using the select_proc command. 
 *  
 *    'SELECT_PROC_NO_COMMENTS' - Do not select the comment
 *    header as part of select_proc
 */
enum_flags SELECT_PROC_FLAGS {
   SELECT_PROC_NONE = 0x0,
   SELECT_PROC_NO_COMMENTS = 0x1,
};

/**
 * Default flags for using select_proc command.
 *  
 * @categories Configuration_Variables
 */
SELECT_PROC_FLAGS def_select_proc_flags;

/**
 * Defines maximum number of recently used document modes
 * displayed to the user on the New File dialog.
 *  
 * @categories Configuration_Variables
 */
int def_max_doc_mode_mru;

/**
 * Defines maximum number of recently used project types
 * displayed to the user on the New Project dialog.
 *  
 * @categories Configuration_Variables
 */
int def_max_proj_type_mru;

/**
 * Determines whether to prompt the user to select a project 
 * when using the command 'show_file_in_projects_tb' or to just 
 * expand all relevant projects in the project tool window. 
 * 
 * @categories Configuration_Variables
 */
bool def_show_all_proj_with_file;
/**
 * Determines whether Alt+Shift+Left/Right/Up/Down/Home/End 
 * should create a block selection. 
 */
bool def_cua_select_alt_shift_block=true;

/**
 * Determines whether block mode fills a block selection when 
 * the block selection is past the end of the line.
 */
bool def_block_mode_fill_only_if_line_long_enough=false;

struct HTML_INFO_STRUCT {
   int browser[];
   _str exePath[];
   _str app[];
   _str topic[];
   _str item[];
   int useDDE[];
};

struct NTINDEXHELPOPTIONS {
   bool usedde;
   _str dde_server;  // MSIN for VC++
   _str dde_topic;   //vcbks40.mvb for VC++ 4.0
   _str dde_item;    //KeywordLookup(`%K') for VC++
   _str CmdViewer;
};

/**
 * Used by the options and also by anything else that wants to declare a 
 * property sheet. 
 */
struct PropertySheetItem {
   _str Caption;
   _str Value;
   int ChangeEvents;
};

/**
 * PROJECTPACKS struct - used to hold info about project types. 
 * Used by wkspace.e and packs.e. 
 */
struct PROJECTPACKS {
   int Node;
   int Modified;        // Flag: 1=pack modified
   int User;            // Flag: 1=user-defined pack
};

// pictures used with the enhanced open toolbar
int _pic_hist_file;              // _filehist.bmp
int _pic_wksp_file;              // _filewksp.bmp
int _pic_proj_file;              // _fileprj.bmp
int _pic_folder;                 // _fldclos.bmp
int _pic_disk_file;              // _file.bmp

/**
 * Returns the x, y, width, and height for the monitor
 * this window is on.  The monitor is determined by checking
 * the monitor that the form for this window is primarily on.
 *
 * @param screen_x    Pixel X coordinate for this monitor
 * @param screen_y    Pixel Y coordinate for this monitor
 * @param screen_width  Pixel width for this monitor
 * @param screen_height Pixel height for this monitor
 * 
 * @categories Display_Functions
 */
extern void _GetScreen(int &screen_x,int &screen_y,int &screen_width,int &screen_height);

/**
 * Returns the visible x, y, width, and height for the monitor
 * the given point (pt_x,pt_y) is on.  The monitor is determined
 * by checking the monitor that contains the given point. 
 *
 * @param pt_x        Pixel x coordinate of point to test.
 * @param pt_y        Pixel y coordinate of point to test.
 * @param screen_x    Pixel X coordinate for this monitor
 * @param screen_y    Pixel Y coordinate for this monitor
 * @param screen_width  Pixel width for this monitor
 * @param screen_height Pixel height for this monitor
 *  
 * @categories Display_Functions
 */
extern void _GetScreenFromPoint(int pt_x, int pt_y, int& screen_x, int& screen_y, int& screen_width, int& screen_height);

/**
 * Returns the visible x, y, width, and height for the monitor
 * this window is on.  The monitor is determined by checking
 * the monitor that the form for this window is primarily on.
 *
 * <p>For Windows, this allows to you to make sure a window does not
 * overlap the task bar
 *
 * @param screen_x    Pixel X coordinate for this monitor
 * @param screen_y    Pixel Y coordinate for this monitor
 * @param screen_width  Pixel width for this monitor
 * @param screen_height Pixel height for this monitor 
 *  
 * @categories Display_Functions
 */
extern void _GetVisibleScreen(int &screen_x,int &screen_y,int &screen_width,int &screen_height);

/**
 * Returns the visible x, y, width, and height for the monitor
 * the given point (pt_x,pt_y) is on.  The monitor is determined
 * by checking the monitor that contains the given point. 
 *
 * @param pt_x        Pixel x coordinate of point to test.
 * @param pt_y        Pixel y coordinate of point to test.
 * @param screen_x    Pixel X coordinate for this monitor
 * @param screen_y    Pixel Y coordinate for this monitor
 * @param screen_width  Pixel width for this monitor
 * @param screen_height Pixel height for this monitor
 *  
 * @categories Display_Functions
 */
extern void _GetVisibleScreenFromPoint(int pt_x, int pt_y, int& screen_x, int& screen_y, int& screen_width, int& screen_height);

/**
 * @param AllowedLineLen   Lines lengths greater than this length are flagged.
 * @param LineNumbers      (Ouput only) ASCIIZ string.
 *                         Set to a space delimited list of line numbers of lines which are too long.
 *                         Lines with the VSLF_NOSAVE flag set are ignored.
 * @param FromCursor       (optional)
 * @param MaxLineLen       (optional)
 *
 * @return Returns 0 if there are no lines longer than the AllowedLineLen specified.
 *         At the moment only the physical line length is checked as if tab characters count
 *         as 1 character.  We may change this in the future.
 *
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Editor_Control_Methods, File_Functions
 */
extern bool _CheckLineLengths(int AllowedLineLen,_str &LineNumbers,int FromCursor=0,int &MaxLineLen=0);



/**
 * @return Returns 1 if the file contains uppercase letters and no lowercase letters.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 *
 */
extern int _GetCaps();
extern void _ReadEntireFile();

/**
 *
 * Determines the file type given the absolute (make sure the
 * <i>filename</i> is absolute) <i>filename</i> specified.  This function is
 * needed because SlickEdit has some NFS-like features for handling some
 * special files.  These special files may have performance limitations or other
 * limitations.  This function lets you check the type and special case
 * operations.  For example, the filename
 * "c:\java\src.zip\java\lang\Object.java" is a special file type because Visual
 * SlickEdit will treat "src.zip" like a directory so that files can be loaded
 * out of a zip (or jar) file without requiring much special code.  Currently,
 * SlickEdit's NFS-like layer does not support writing to zip or jar
 * files.
 *
 * @return  Returns one of the VSFILETYPE_* constants defined in "slick.sh."
 *
 * @see     gui_fill_selection
 *
 * @categories File_Functions
 */
extern int _FileQType(_str filename);
extern bool _FileIsRemote(_str filename);
extern bool _FileIsWritable(_str filename);
extern bool _WinFileIsWritable(int wid);
extern int _WinGetLeftEdge(int wid,bool do_refresh_scroll=true);

extern void _RegisterAlert(_str alertGroupID);
extern void _UnregisterAlert(_str alertGroupID);
extern void _ActivateAlert(_str alertGroupID, _str alertID, _str msg='', _str header='', int showToast=1);
extern void _DeactivateAlert(_str alertGroupID, _str alertID, _str msg='', _str header='', int showToast=0);
extern void _ClearLastAlert(_str alertGroupID, _str alertID='');
extern void _SetAlertGroupStatus(_str alertGroupID, int enabled=1, int showPopups=1);
extern void _SetAlertStatus(_str alertGroupID, _str alertID, int enabled=1, int showPopups=1);
extern void _GetAlertGroup(_str alertGroupID, typeless alertGroup);
extern void _GetAlert(_str alertGroupID, _str alertID, typeless alert);
extern void _SetAlert(_str alertGroupID, _str alertID, typeless alert);
extern _str _GetAlertHistory();
extern void _SetAlertHistory(_str history);

extern void _LCClearAll();
extern _str _LCQDataAtIndex(int iLineCommand);
extern int _LCQLineNumberAtIndex(int iLineCommand);
extern _str _LCQData();
extern int _LCQLineNumber();
extern void _LCSetData(_str pszLineCommmand);
extern int _LCQNofLineCommands();
extern bool _LCIsReadWrite();
extern void _LCSetFlags(int flags,int mask);
extern int _LCQFlags();
extern void _LCSetDataAtIndex(int iLineCommand,_str pszLineCommmand);
extern int _LCQFlagsAtIndex(int iLineCommand);
extern void _LCSetFlagsAtIndex(int iLineCommand,int flags,int mask);

extern bool _demo();
extern bool _trial();

/**
 * Returns whether or not the specified file exists or not.
 * 
 * @param filename - The file to check for existence.
 * 
 * @return bool    - True if the file exists, false if not. 
 *  
 * @categories File_Functions
 */
extern bool file_exists(_str filename);


/**
 * NT only
 *
 *
 * @param MemoryLoad percent of memory in use
 * @param TotalPhys  (k) physical memory
 * @param AvailPhys  (k) free physical memory
 * @param TotalPageFile  (k) paging file size
 * @param AvailPageFile  (k) free paging file size
 * @param TotalVirtual   (k) virtual address size
 * @param AvailVirtual   (k) free virtual address size
 */
extern void ntGlobalMemoryStatus(long &MemoryLoad,
                                 long &TotalPhys,
                                 long &AvailPhys,
                                 long &TotalPageFile,
                                 long &AvailPageFile,
                                 long &TotalVirtual,
                                 long &AvailVirtual);
/**
 * NT only
 *
 * @param path    Path to look at
 * @param TotalSpace (k) Total disk space
 * @param FreeSpace  (k) Free disk space
 *
 * @return 0 if successful.
 */
extern int _GetDiskSpace(_str path,long &TotalSpace,long &FreeSpace);
extern _str _SpillFilename();
extern void ntGetVersionEx(int &MajorVersion,int &hvarMinorVersion,int &BuildNumber,int &PlatformId,_str &CSDVersion, int &ProductType);
extern int ntIs64Bit();

extern int ntGetVolumeInformation(_str Path,_str &FSName,int &FSFlags);

extern int _uname(UNAME &info);
/**
 * Sets caching option for HTTP files
 *
 * @param option <DL COMPACT>
 *               <DT>0</DT><DD>No caching</DD>
 *               <DT>1</DT><DD>Read from cache or update cache</DD>
 *               <DT>2</DT><DD>Recache.  Read-read file and update cache</DD>
 *               </DL>
 *
 * @return Returns previous setting
 */
extern int _UrlSetCaching(int option);
extern bool _UrlSetIncludeHeader(bool onoff);
/**
 * Set proxy host and port settings for given protocol.
 * <P>
 * Note: Pass in "" for the host if you want to clear the proxy settings
 * for a particular protocol.
 *
 * @param pszProto Protocol to set proxy settings for
 *
 * @param pszProxyHost
 *                 Proxy host
 *
 * @param iProxyPort
 *                 Proxy port
 *
 * @return If protocol is registered 0 (success) is returned and
 *         pszProxyHost and iProxyPort are assigned to registered
 *         protocol handler. Otherwise, URL_PROTO_NOT_SUPPORTED_RC
 *         is returned.
 */
extern int _UrlSetProxy(_str pszProto,_str pszProxyHost,int iProxyPort);
/**
 * Set a string of space-delimited host prefixes. These prefixes
 * are exceptions to the proxy rules set for all protocols. Pass
 * in "" to clear the bypass list.
 *
 * @param pszProxyBypass
 *
 * @return 0 on success.
 */
extern int _UrlSetProxyBypass(_str pszProxyBypass);
/**
 * Get proxy host and port settings for given protocol. Returns
 * a string of the form: "host:port" to signify the proxy host and
 * port to use.
 * <P>
 * Note: The string returned is static and should be copied before
 * any manipulation is done on it.
 *
 * @param pszProto Protocol to return proxy settings for
 *
 * @return If protocol is not registered then 0 (null) is returned.
 *         Otherwise, the string containing proxy information is returned.
 */
extern _str _UrlGetProxy(_str pszProto);
/**
 * Get proxy host and port settings for all registered protocols. Returns
 * a space-delimited string of the form: "proto1=host:port proto2=host:port ..."
 * to signify the proxy host and port to use for the protocol specifed before
 * the '='.
 * <P>
 * Note: The string returned is static and should be copied before
 * any manipulation is done on it.
 *
 * @return If there are no registered protocols then 0 (null) is returned.
 *         If no protocols have proxies then an empty string is returned.
 *         Otherwise, the string containing proxy infomation is returned.
 */
extern _str _UrlGetAllProxies();
/**
 * Return a string of space-delimited host prefixes. These prefixes
 * are exceptions to the proxy rules set for all protocols.
 *
 * @return String of space-delimited proxy bypass hosts.
 */
extern _str _UrlGetProxyBypass();
/**
 * Clear proxy settings from all registered protocols, and clear
 * the host bypass list.
 */
extern void _UrlClearAllProxies();
extern _str _XServerVendor(); // Unix only


/**
 * Kill a process given the process's ID
 *
 * @param pid        process to kill
 * @param exit_code  exit code for process
 */
extern void _kill_process(int pid, int exit_code=0);
/**
 * Resolve link for filename. UNIX only. If filename does not exist, then
 * "" is returned. If filename is not a link, then original filename is returned.
 * If filename is not an absolute path, then it is assumed relative to current
 * directory.
 *
 * @param filename Filename to resolve link for
 *
 * @return Resolved link filename. 
 *  
 * @deprecated Use {@link absolute(path,null,true)} instead, which is more portable. 
 */
extern _str _FileReadLink(_str filename);

extern int _FileOpen(_str pszFilename,int option);
extern int _FileClose(int fh);


/**
 * This function is executed when the on_hsb_thumb_pos event occurs to
 * horizontally scroll the current window.  This event occurs while the user
 * drags the thumb (elevator).  The <i>hsb_pos</i> argument is a number between
 * 0 and 32000.
 *
 * @categories Miscellaneous_Functions
 *
 */
extern void _hsb_thumb_pos();
/**
 * <p>If <i>proc_name</i> is '', then this procedure searches for the first or
 * next occurrence of a Java language function definition.  Search always starts
 * from cursor position.  The <i>find_first</i> parameter indicates whether this
 * is the first or next call.  <i>proc_name</i> is set to the name of the
 * function found.</p>
 *
 * <p>If <i>proc_name</i> is not '', then a search for a Java language
 * function definition with name <i>proc_name</i> is performed.  Searching
 * begins at the cursor position.  <i>find_first</i> must be non-zero if
 * <i>proc_name</i> is not ''.  The cursor is placed on the definition found, if
 * one is found.</p>
 *
 * @return Returns 0 if successful.  Otherwise a non-zero value is returned.
 *
 * @appliesTo Editor_Control, Edit_Window
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
extern int java_proc_search(_str &proc_name, int find_first);
/**
 * Switches to the previous buffer if <i>buf_id</i> is equal to the current
 * buffer's buffer id (p_buf_id) and the current window id is not the hidden
 * window id.
 *
 * @return Returns 0.
 *
 * @appliesTo Edit_Window
 *
 * @categories Buffer_Functions
 *
 */
extern int _keepquit_id(int buf_id);

/**
 * <p>If <i>proc_name</i> is '', then this procedure searches for the first or
 * next occurrence of a PASCAL language function definition.  Search
 * always starts from the cursor position.  The <i>find_first</i>
 * parameter indicates whether this is the first or next call.
 * <i>proc_name</i> is set to the name of the function found.</p>
 *
 * <p>If <i>proc_name</i> is not '', then a search for a PASCAL language
 * function definition with name <i>proc_name</i> is performed.
 * Searching begins at the cursor position.  <i>find_first</i> must be
 * non-zero if <i>proc_name</i> is not ''.  The cursor is placed on the
 * function definition, if one is found.</p>
 *
 * @return Returns 0 if successful.  Otherwise a non-zero value is returned.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 *
 */
extern int pas_proc_search(_str &procname,int find_first);

/**
 * Gets the path of the binaries for Visual C++/Visual Studio
 *
 * @param Path Path of binaries
 * @param UserSpecifiedVersion Version of Visual C++/Visual Studio user has.  If
 *                             not certain, use -1
 * @param AppendExename (optional) If true, append the name of the executable
 *
 * @categories Miscellaneous_Functions
 *
 * @return 0 if succesful
 */
extern int GetVCPPBinPath(_str &Path,int UserSpecifiedVersion,int AppendExename=0);
/**
 * Opens the current file in Visual Studio (2003 or 2005), optionally positioning
 * the caret to a specific line and column coordinate.
 * This method first tries to connect to an already running instance of Visual Studio 2003 or 2005.
 * If there is no running instance, a new instance is created. It will not connect to Visual Studio
 * versions lower than 2003 (internal version 7.1)
 * Windows Only
 *
 * @param Path   Full path to the file
 * @param Line   Optional line number to center on. (Line numbers are 1-based)
 * @param Col    Optional column number to place caret on. Only works if Line is > 0
 *
 * @categories Miscellaneous_Functions
 *
 * @return 1 indicates success
 *         -1 indicates Visual Studio could not be started.
 *         0 indicates Visual Studio is started, but the file could not be opened
 */
extern int vstudio_open_file(_str Path, int Line, int Col);
/**
 * Opens the Visual Studio Solution (.sln) file in the specified
 * version of Visual Studio .NET.
 *
 * @param solutionFilePath   Full path to the .sln file
 * @param VStudioVersion   Version of Visual Studio to open (7.1, 8.0, and up)
 *
 * @categories Miscellaneous_Functions
 *
 * @return 1 indicates success
 *         -1 indicates Visual Studio could not be started.
 *         0 indicates Visual Studio is started, but the solution could not be opened
 */
extern int vstudio_open_solution(_str solutionFilePath, _str VStudioVersion);
/**
 * Returns the number of installed MSDN (Help 2.0) collections.
 * This count is then used when calling msdn_collection_info
 * Windows Only
 *
 * @return Number of available collections
 *
 * @see msdn_collection_info
 * @see msdn_keyword_help
 */
extern int msdn_num_collections();
/**
 * Returns the collection name and namespace (url) for an installed collection
 * Windows Only
 *
 * @param index  Index value from zero (0) to (msdn_num_collections - 1)
 * @param collectionName
 *               Output parameter for the "friendly" readable name, eg "MSDN Library for Visual Studio".
 * @param url    Output parameter for the ms-help:// protocol url, eg ms.vscc.v80
 *
 * @return 0 if successful, -1 if the index value is out-of-range.
 *
 * @see msdn_num_collections
 * @see msdn_keyword_help
 */
extern int msdn_collection_info(int index, _str& collectionName, _str& url);
/**
 * Invokes the MSDN Help 2.0 viewer an attempts to locate a supplied keyword in the index.
 * Windows only
 *
 * @param keyword    String representing the search keyword
 * @param collection The url of the help collection to search, (eg ms-help://ms.vscc.v80).
 *                   NOTE: This parameter "default", or else it must contain the
 *                   ms-help:// protocol string before the namespace value.
 * @param filter     Optional filter to limit the index and search values. For example, the MSDN
 *                   library for Visual Studio can be limited to specific languages or technologies
 *                   depending on what has been installed. Some common filters are
 *                   "Visual C++", ".NET Frameword", "Office Development"
 *
 * @return 1 if successful, -1 if the Help Viewer (dexplore.exe) could not be launched
 *
 * @see msdn_num_collections
 * @see msdn_collection_info
 */
extern int msdn_keyword_help(_str keyword, _str collection, _str filter);
/**
 * Sets the buffer flags for the buffer specified.
 *
 * @param buf_id    Buffer id
 * @param BufFlags  Flags (combination of VSWBUF
 *
 * @categories Buffer_Functions
 */
extern void _BufSetFlags(int buf_id,int BufFlags);
/**
 * Creates a editor window and attaches the buffer corresponding to buffer
 * ID.
 *
 * @param buf_id  ID of the buffer
 *
 * @return If successful returns the window ID.  Otherwise a negative return code.
 *
 * @categories Buffer_Functions
 */
extern int _CreateTempEditor2(int buf_id);
/**
 * Saves the current editors cursor position in the buffer.  When the buffer is
 * attached to another window, the buffer cursor position is used.
 */
extern void _SaveCursorInfo();

/**
 * Retrieves the buffer ids of the currently open buffers in the
 * same order as _next_buffer/_prev_buffer.  This has the
 * advantage of the getting the list of buffer ids in order
 * without actually switching buffers and potentially mucking up
 * scroll position information.
 *
 * @param next_option         1 to go in the same order as
 *                            _next_buffer, 0 to use
 *                            _prev_buffer order
 * @param idList              list of buffer ids
 *
 * @categories Buffer_Functions
 */
extern void _getBufferIdList(int next_option, int (&idList)[]);

extern void _find_old_eclipse_default_config(_str path_prefix, _str &old_default_config, _str &new_default_config);
extern void _find_old_default_config(_str path_prefix, _str &old_default_config, _str &new_default_config);

/**
 * Determine whether filename is an HTTP url.
 *
 * @param filename  Name of filename / path to check.
 *
 * @return Return true if the given file path starts with "http://"
 */
extern bool _isHTTPFile(_str filename);

/**
 * Shrink path to fit into width in the same units as <b>_text_width</b>.
 * Useful for displaying filenames in a control that is not wide enough to fit
 * the entire text. Width is in units of the scale mode of the active window.
 * Use p_width to retrieve the width of the active window (e.g. control). Use
 * _text_width to retrieve the width of a string in the active window using the
 * current font for that window. ".." is used to indicate missing (shrunk) path
 * information.
 *
 * @param filename Path to shrink.
 * @param width    Width to shrink into in scale mode units of active window.
 *
 * @return Shrunk path.
 */
extern _str _ShrinkFilename(_str path, int width);

enum {
   SLICKC_DEBUG_OFF=0,           // turn off debugging support
   SLICKC_DEBUG_ON=1,            // turn on debugging support
   SLICKC_DEBUG_SUSPEND,         // suspend the interpreter now
   SLICKC_DEBUG_HOLD_EVENTS,     // block step or breakpoint events
   SLICKC_DEBUG_RELEASE_EVENTS,  // allow step or breakpoint events
   SLICKC_DEBUG_ENABLED,         // test if debugging support is enabled
   SLICKC_DEBUG_CONNECTED,       // test if debugger is connected
   SLICKC_DEBUG_SUSPENDED,       // test if debugger is suspended
   SLICKC_DEBUG_STEPPING         // test if debugger is stepping
};

/**
 * Start or stop the Slick-C debugging protocol.  Slick-C 
 * implements a JDWP (Java Debug Wire Protocol) server that 
 * hooks into the interpreter loop when enabled. 
 * Turning on debugging will allow a JDWP enabled debugger 
 * (SlickEdit) to connect to us.  Turning off debugging will 
 * terminate the debugger connection. 
 * 
 * @param  on_off  see SLICKC_DEBUG_* options above. 
 * @param  port    port number to connect to 
 *
 * @return 'true' if Slick-C&reg; debugging was originally enabled,
 *         'false' otherwise.
 *
 * @categories Macro_Programming_Functions
 */
extern bool _SlickCDebugging(int on_off, _str port);
/** 
 * Poll for commands for the Slick-C&reg; JDWP debugger server 
 * to handle and respond to.  If debugging is not current 
 * enabled or connected, this function will do nothing. 
 * 
 * @param max_time   maximum amount of time in ms to spend 
 *                   processing before returning control to
 *                   SlickEdit.
 * 
 * @return 0 on success, <0 on error.
 *
 * @categories Macro_Programming_Functions
 */
extern int _SlickCDebugHandler(int max_time=5000);
/**
 * Start or stop Slick-C&reg; profiling data collection.
 * Turning on profiling will clear any currently
 * collected profiling data.
 *
 * @param  on_off  'true' to turn on profiling;
 *                 'false' to turn it off.
 *
 * @return 'true' if Slick-C&reg; profiling was originally enabled,
 *         'false' otherwise.
 *
 * @see profile
 * @see _InsertSlickCProfilingData
 * @categories Macro_Programming_Functions
 */
extern bool _SlickCProfiling(bool on_off);
/**
 * Insert Slick-C&reg; profiling data to the designated editor
 * control.  The data is inserted one line per function, and
 * tab-separated. The columns are as follows:
 * <ol>
 * <li>module name -- loaded module function comes from
 * <li>offset -- offset of function within module
 * <li>function name -- optional
 * <li>number of calls
 * <li>mininimum time in function and descendants
 * <li>maxinimum time in function and descendants
 * <li>total time in function and descendants
 * <li>mininimum time in function only
 * <li>maxinimum time in function only
 * <li>total time in function only
 * <li>future data
 * </ol>
 *
 * @param wid   Editor control to insert into.
 *
 * @see profile
 * @see _SlickCProfiling
 * @categories Macro_Programming_Functions
 */
extern void _InsertSlickCProfilingData(int wid);
/**
 * Determine the line number of a function found at the given offset 
 * within a compiled and loaded Slick-C module. 
 * 
 * @param module_name   name of module function comes from
 * @param proc_name     name of function offset is within
 * @param offset        code offset within function. 
 *  
 * @return Return the line number of the given offset in the source file on success, 
 *         Return error code <0 on error. 
 * 
 * @see profile
 * @see _SlickCProfiling
 * @categories Macro_Programming_Functions
 */
extern int _GetSlickCLineNumberFromOffset(_str module_name, _str proc_name, int offset);
/**
 * Determine the name of the function found at the given offset 
 * within a compiled and loaded Slick-C module. 
 * 
 * @param module_name   name of module function comes from
 * @param offset        code offset within function. 
 * @param proc_name     (output) set to name of function 
 * 
 * @return 0 on success, <0 on error.
 * 
 * @see profile
 * @see _SlickCProfiling
 * @categories Macro_Programming_Functions
 */
extern int _GetSlickCFunctionNameFromOffset(_str module_name, int offset, _str &found_proc_name);

/**
 * Set the timeout amount for performance critical functions. 
 * The timeout is not a strict timeout, it's a software timeout. 
 * Use {@link _CheckTimeout()} to test if the timeout is expired. 
 * <p> 
 * It is good practice to clear the timeout after you are done 
 * with it by calling _SetTimeout(0). 
 * 
 * @param ms   number of milliseconds to time out after. 
 *             use 0 to clear an existing timeout.
 * 
 * @return Normally will return 'ms', but if there is an existing 
 *         earlier timeout, the earlier timeout will be returned.
 *  
 * @categories Macro_Programming_Functions
 */
extern int _SetTimeout(int ms);
/** 
 * Check if a timeout set using {@link _SetTimeout()} has expired. 
 * This is a software timeout.  Nothing will happen when the timeout 
 * passes, it's up to you to call _CheckTimeout() yourself and 
 * handle the situation. 
 * 
 * @return 'true' if the timeout is expired. 
 *  
 * @categories Macro_Programming_Functions
 */
extern bool _CheckTimeout();
/** 
 * Check how many milliseconds are remaining before the timeout 
 * set using {@link _SetTimeout()} will expire. 
 *  
 * This is a software timeout.  Nothing will happen when the timeout 
 * passes, it's up to you to call _CheckTimeout() yourself and 
 * handle the situtation. 
 * 
 * @return 0 if the timeout is expired, 
 *         &gt;0 is the number of milliseconds remaining, 
 *         &gt;= MAXINT if there is no timeout set.
 *  
 * @categories Macro_Programming_Functions
 */
extern int _GetTimeoutRemaining();
/** 
 * Saves the current timeout value for restoring later. 
 *  
 * @param timeoutValue    (output only) timeout value
 *  
 * @see _SetTimeout() 
 * @see _CheckTimeout() 
 * @see _RestoreTimeout() 
 *  
 * @example 
 * <pre> 
 * void someFunction(bool alwaysUpdate) {
 *    _SaveTimeout(auto origTimeout);
 *    _SetTimeout(alwaysUpdate? 0:1000);
 *    // do stuff
 *    _RestoreTimeout(origTimeout);
 * }
 * </pre>
 *  
 * @categories Macro_Programming_Functions
 */
extern void _SaveTimeout(long &timeoutValue);
/** 
 * Restore the previously set timeout value.  Note that the timeout value 
 * maybe reflect a timeout which is already past. 
 *  
 * @param timeoutValue    timeout value from {@link _SaveTimeout()} 
 *  
 * @see _SetTimeout() 
 * @see _CheckTimeout() 
 * @see _SaveTimeout() 
 *  
 * @categories Macro_Programming_Functions
 */
extern void _RestoreTimeout(long timeoutValue);


/**
 *
 * @return Returns true if editor calls are in UTF-8 mode.
 *         UTF-8 mode allows the editor to support UNICODE.
 *
 * @see _dbcsIsLeadByte
 * @see _dbcsStartOfDBCS
 * @see _dbcsSubstr
 *
 * @categories Miscellaneous_Functions
 *
 */
extern bool _UTF8();

/**
 * Places cursor at the beginning of the current character.  This function
 * supports DBCS and UTF-8 buffers with composite characters.
 *
 * @return Returns true if the cursor moved.
 *
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories CursorMovement_Functions, Edit_Window_Methods, Editor_Control_Methods
 */
extern bool _begin_char();

/**
 * Window currently using mou_capture.
 *
 * @appliesTo All_Window_Objects
 *
 * @see mou_capture
 * @see mou_release
 *
 * @categories Mouse_Functions
 *
 * @return Window ID for mouse capture, 0 if no window current
 *         has capture.
 *
 */
extern int mou_has_captured();

/**
 * @return Returns 'true' if SlickEdit can locate a delta backup for the given file.
 *
 * @param Filename   file to check for
 */
extern int DSBackupVersionExists(_str Filename);
/** 
 * Get the backup history archive filename for the local file 
 * <B>Filename</B>. 
 * 
 * @param Filename filename to get archive filename for.
 * 
 * @return _str Archive filename for <B>Filename</B>.
 */
extern _str DSGetArchiveFilename(_str Filename);
/**
 * Create a delta backup for a given file
 *
 * @param Filename file to backup 
 * @param doCurBufnameCheck Check that current buffer name and <b>Filename</b> 
 *                          are equivalent.
 *
 * @return 0 if successful
 */
extern int DSCreateDelta(_str Filename);
extern int DSCreateDelta2(_str Filename);
extern int DSUpgradeArchive(_str Filename);
/**
 * Extract a copy of the file and version specified into a new window
 *
 * @param Filename file to extract
 * @param iVersion Version to extract
 * @param status   status for this operation.  0 if successful
 * @param AlternatePath
 *                 If filename is different than original, path for filename of new buffer
 *
 * @return Window id of new buffer. File is not saved on disk
 */
extern int DSExtractVersion(_str Filename,int iVersion,int &status,_str AlternatePath="");
extern int DSExtractMostRecentVersion(_str Filename,int &status,_str AlternatePath="");
/**
 * Get the number of version of a specified file
 *
 * @param Filename
 *               file to check
 *
 * @return number of versions of <B>Filename</B> available
 */
extern int DSGetNumVersions(_str Filename);
/**
 * Get a list of versions/dates of a given file.  This list is in a format friendly to columnized list boxes/tree controls
 *
 * @param Filename Filename to list versions of
 * @param versionList
 *                 List is stored in this array
 *
 * @return 0 if successful
 */
extern int DSListVersions(_str Filename,_str versionList[]);
extern int DSListVersionDates(_str Filename,_str versionList[]);
/**
 * Stores a comment for a version of a specified file. 
 *
 * @param Filename Filename for which to set a comment
 * @param iVersion Version to which to attatch comment
 * @param Comment  Comment text to set
 *
 * @return 0 if successful
 */
extern int DSSetVersionComment(_str Filename,int iVersion,_str Comment="");
/**
 * Stores a project tag for a version of a specified file. 
 *
 * @param Filename Filename for which to set a comment
 * @param iVersion Version to which to attatch comment
 * @param projectTag  Project tag to set
 *
 * @return 0 if successful
 */
extern int DSSetPWTag(_str Filename, int iVersion, _str PWTag="", int tagType = 0);
extern int DSUpgradeArchiveTree(_str oldPath, _str configPathBase,STRARRAY couldNotUpgradeList, int cancel_form_wid=0);
extern int DSGetChecksum(int WID);

extern int _SaveSelDisp(_str pszFilename,_str pszFileDate);
extern int _RestoreSelDisp(_str pszFilename,_str pszFileDate,bool RestoreSelDisp,bool RestoreLineModify);
extern int _MallocTotal();
extern int _MallocCount();
extern bool _wf_isconnected();
extern void wf_terminate_dde();
extern bool delphiIsRunning();
bool delphiIsBufInDelphi(_str buf_name);
extern int delphiSaveBuffer(_str buf_name);
void delphi1AppDeactivate();
void delphiAppDeactivate();
void delphi1AppActivate();
void delphiAppActivate();
extern int delphiSaveAsBuffer(_str buf_name);
_command int delphi_stop(int status=0);
extern int delphiCloseBuffer(_str buf_name);
int delphiUpdateCloseAll(int status=0);
extern void _updateTextChange();
extern void _CallbackSelectMode(int wid,_str pszExtension);
extern int _SlickCCheckModuleLinks(int module_index);
extern void _userLogFile(typeless &);
extern int _BufQFlags(int buf_id);
extern int _BufGetNewline(int buf_id);
extern void _BinaryToHexView_insert_text(int wid,_str &binary, int bytes_per_col=0,int Nofcols=0);
extern int _HexViewToBinary(_str &hex_view, _str &binary);
/**
 * @deprecated Use {@link _LanguageCallbackProcessBuffer()}
 */
extern void _ExtCallbackProcessBuffer(int reqFlags);
/**
 * This function tells the language specific callbacks to be 
 * executed.  The language specific callbacks start with the 
 * prefix _CBProcessBuffer_[lang]_, where [lang] is a language ID. 
 * 
 * @param int reqFlags 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Miscellaneous_Functions
 */
extern void _LanguageCallbackProcessBuffer(int reqFlags=0);
extern int _userName(_str &name);
extern int _registervs(_str pszExeFilename);
extern int _associatefiletypetovs(_str pszExtnodot, ...);
extern int ntSupportOpenDialog();
extern int _timer_is_valid(typeless timer_handle);
extern void _set_timer_alternate(typeless timer_handle,int alternateInterval,int alternateIdleTime);
extern int _DelTree(_str rootPath,bool removeRootPath);
extern int _AppHasFocus();
extern int _get_command_index_for_key(int wid, _str key);
extern void _reset_idle();
extern int _IsFileMatchedExtension(_str pszFilename,_str pszPattern);
extern int VCPPIsUp(int iUserSpecifiedVersion);
extern int VCPPIsVisible(int iUserSpecifiedVersion);
extern void VCPP5Help(_str pszString,int iUserSpecifiedVersion);
extern int VCPPIsVSEOnMenu(int iUserSpecifiedVersion);
extern int MaybeAddVSEToVCPPRegEntry(_str pszEditorPath,_str pszArgs,_str pszDir);
extern void VCPPListAvailableVersions();
extern int AppMenu(_str pszClassName,_str pszTitle,_str pszMenuSpec,
            int fClassPrefixSearch,int fTitlePrefixSearch,int fActivateApp);
extern int MaybeAddVSEToVCPPMenu(int iVersion);
extern int FindVCPPReloadMessageBox();
extern void _FreeSccDll();
extern int _DragDropStart(int wid);

/**
 * Begins a drag/drop operation with a list of files.  You can
 * drag the files to the editor window or to another application
 * to open them.
 *
 * @param files
 * @categories File_Functions
 */
extern void _DragFiles(_str (&files)[]);

extern int _InsertProjectFileListXML(int handle,
                              var hvarIndexList,
                              int iMaxSccNum,
                              int iMenuCloseIndex,
                              int iMenuOpenIndex,
                              int iCurrentVCSIsScc,
                              int iParentIndex,
                              var hvarExtToNodeHashTab,
                              bool NormalizeFolderNames);
extern int _InsertProjectFileList(var hvarFileList,
                           var hvarExtToNodeHashTab,
                           var hvarIndexList,
                           int iMaxInsertNum,
                           int iMaxSccNum,
                           int iCurrentVCSIsScc,...);
extern void _InsertProjectFileListXML_WithoutFolders(int treeParentIndex,
                                              int workspaceHandle,
                                              typeless hvarProjectHandleList,
                                              _str pszFilter,
                                              int pic_file);
extern int _FilterTreeControl(_str pszFilter,bool iPrefixFilter, bool iSearchUserInfo=false,_str iREType='&',int iColIndex=0);
/**
 * Add a file to the file list with default correct column formatting
 * The current object should be the tree control.
 * 
 * @param tree_index    tree index to insert file under
 * @param file          absolute path to file to add 
 * @param filter_text   file name filter pattern 
 * @param buf_id        buffer ID
 * @param pic_file      index for display bitmap for file
 * @param node_flags    bitset of tree node flags (TREENODE_*)
 * 
 * @return tree index of file after it has been inserted
 */
extern int _FileListAddFile(int tree_index, _str file, _str filter_text, int buf_id, int pic_file, int node_flags=0);

/**
 * Add all of the files in <B>projectFilename</B> to the tree 
 * control that is active. 
 *  
 * @param workspaceFilename filename of the workspace that 
 *                          <B>projectFilename</B> is in
 * @param projectFilename   filename of the project to insert 
 *                          the files for
 * @param parentIndex       parent index in the tree to insert itmes 
 *                          for
 * @param BMIndex           index for display bitmap for files
 * 
 * @return 0 if successful
 */
extern int _FileListAddFilesInProject(_str workspaceFilename,_str projectFilename,int parentIndex,int BMIndex,_str filterText="");
extern int _FileTreeAddFile(_str pszFile, _str originFlags, int iBufId, _str pszFilter, int (&picIndices):[]);
extern void _FileTreeAddFileOrigin(int index, _str pszAddedOrigins, int iBufId, _str pszFilter, int (&picIndices):[]);
extern int _FileTreeRemoveFileOriginFromFile(int iIndex, _str pszOriginsToRemove, _str pszFilter, int (&picIndices):[]);
extern int _FileTreeRemoveFileOrigin(_str pszOriginsToRemove, _str (&deletedCaptions)[], _str pszFilter, int (&picIndices):[]);
extern _str _BufName2Caption();
extern bool _SCIMRunning();

extern int scBPMQFlags();
extern int _GetMouWindow();
extern int _find_tile(_str buf_name);
_command start_process_tab(bool OpenInCurrentWindow=false,
                       bool doSetFocus=true,
                       bool quiet=false,
                       bool uniconize=true,
                       _str idname='');
_command start_process(bool OpenInCurrentWindow=false,
                       bool doSetFocus=true,
                       bool quiet=false,
                       bool uniconize=true,
                       _str idname='');
extern void _PrintPreviewSetScale(int ScaleMult,int MaxWidth,int MaxHeight);
extern void _PrintPreviewScrollRight();
extern void _PrintPreviewScrollLeft();
extern void _PrintPreviewScrollUp();
extern void _PrintPreviewScrollDown();
extern int _PrintPreviewQNofPages();
extern int _PrintPreviewQPageNumber();
extern void _PrintPreviewNextPage();
extern void _PrintPreviewPrevPage();
extern void _PrintPreviewTop();
extern void _PrintPreviewBottom();
extern void _DebugWindowSave(_str &info);
extern void _DebugWindowRestore(_str &info);
extern bool _QueryEndSession();
bool isEclipsePlugin();
extern _command typeless show(_str cmdline="", ...);
extern void mou_hour_glass(bool onoff);
extern void _macro_delete_line();

#if 1 /*__PCDOS__*/
extern void ntGetSpecialFolderPath(_str &hvarAppDataPath,int csidl_special_folder);
/**
 * Show the standard Windows style directory browser dialog.
 * 
 * @param dir_from_dialog     directory to initialize dialog to 
 * @param title               dialog caption (default "Select a directory")
 * @param flags               bitset 
 *                            <ul> 
 *                            <li>0x1 -- show make new directory button
 *                            <li>0x2 -- validate that directory exists
 *                            </ul>
 * 
 * @return Returns the selected directory, or '' if cancelled. 
 *  
 * @categories File_Functions
 * @since 13.0
 */
extern _str _ntBrowseForFolder(_str dir_from_dialog,_str title=null,int flags=0);
extern _str NTNetGetConnection(_str DriveString);
/**
 * Populate a temp buffer with a list of computers on the 
 * domain. Windows only. 
 * 
 * @param wid Buffer/Window ID. Should be a temp view.
 * 
 * @return int Number of computer names in the list, or -1 for 
 *         an error
 */
extern int NTNetGetDomainComputers(int wid);
/**
 * Populate a temp buffer with a list of the browsable file 
 * shares from a network peer computer. Windows only.
 * 
 * @param wid Buffer/Window ID. Should be a temp view.
 * @param pszComputerName Name of computer returned from 
 *                        NTNetGetDomainComputers
 * 
 * @return int Number of shares, or -1 for error
 */
extern int NTNetGetComputerShares(int wid, _str pszComputerName);
/**
 * Gets current user setting for showing or hiding hidden files 
 * and folders in Windows Explorer 
 * 
 * @return int Combination of FILEATTR_HIDDEN (0x2) and 
 *         possibly FILEATTR_SYSTEM (0x4)
 */
extern int ntGetExplorerShowHiddenFlags();
extern int ntGetMaxCommandLength();
extern int ntGetVolumeSN(_str pszPath,var hvarVSN);
extern int NTGetElevationType();
extern int NTIsElevated();
extern int ntIISGetVirtualDirectoryPath(_str vdirpath, _str &path);
// Use _ShellExecute() instead with the SHELLEXECUTEFLAG_WAIT_FOR_COMPLETION flag.
extern int NTShellExecuteEx(_str pszOperation, _str pszFilename, _str pszParams, _str pszDir, int &exitCode);
#endif

const SHELLEXECUTEFLAG_DEFAULT=  0;
const SHELLEXECUTEFLAG_WAIT_FOR_COMPLETION=  1;
/** 
 * Used to lauch a file using the OSes file associations 
 *  
 * <p> This function is only supported by Windows and Mac. 
 *  
 * @param pszOperation    The null or "open" are supported on 
 *                        Windows and Mac. Windows supports any
 *                        operation supported by the Win32
 *                        function ShellExecuteEx.
 * @param pszFilename     Filename to operate on.
 * @param pszParams       This parameter is only supported on 
 *                        Windows.
 * @param pszDir          This parameter is only supported on 
 *                        Windows.
 * @param ShellExecuteFlags   This paramater is only supported 
 *                            on windows. Mac runs everything
 *                            asynchrounsly.
 * 
 * @return 
 */
extern int _ShellExecute(_str pszFilename,_str pszOperation=null,_str pszParams=null,_str pszDir=null,int ShellExecuteFlags=SHELLEXECUTEFLAG_DEFAULT);

extern _str vscf_iserror();
extern int vscf_adjusted_linenum();
extern int vsada_format(typeless origEncoding,_str inFilename,int inViewId,_str outFilename,int startIndent,int startLinenum,var htOptions,int vseFlags);
extern typeless vsadaformat_iserror();
extern int vsadaformat_adjusted_linenum();

/**
 * Does the current source language match or 
 * inherit from the given language? 
 * <p>
 * If 'lang' is not specified, the current object
 * must be an editor control.
 *
 * @param parent  language ID to compare to
 * @param lang    current language ID 
 *                (default={@link p_LangId})
 *
 * @return 'true' if the language matches, 'false' otherwise.
 *  
 * @see _FindLanguageCallbackIndex 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions 
 * @since 13.0
 */
extern bool _LanguageInheritsFrom(_str parent, _str lang=null);

/**
 * Does the current source language have the given language in 
 * it's list of languages which symbols can be referenced in? 
 * <p>
 * If 'lang' is not specified, the current object
 * must be an editor control.
 *
 * @param ref_lang      language ID to check reference in
 * @param lang          current language ID 
 *                      (default={@link p_LangId})
 *  
 * @return 'true' if the language matches, 'false' otherwise.
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 17.0
 */
extern bool _LanguageReferencedIn(_str ref_lang, _str lang=null);

/**
 * This function is used to look up a language-specific
 * callback function.
 * <p>
 * Return the names table index for the callback function for the
 * current language, or a language we inherit behavior from.
 * The current object should be an editor control.
 *
 * @param callback_name  name of callback to look up, with a
 *                       '%s' marker in place where the language
 *                       ID would be normally located.
 * @param lang           current language ID
 *                       (default={@link p_LangId})
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 *  
 * @see _LanguageInheritsFrom 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
extern int _FindLanguageCallbackIndex(_str callback_name, _str lang=null);

/**
 * @return Returns non-zero value if this editor controls 
 * language mode supports tag navigation commands include 
 * <b>show_procs</b>, <b>list_tags</b>, 
 * <b>next_proc</b>, <b>prev_proc</b>, <b>find_tag</b>, and
 * <b>push_tag</b>.
 *
 * @param wid     Window id of MDI frame window.
 * @param lang    current language ID 
 *                (default={@link p_LangId})
 *  
 * @see _QLocalsSupported
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
extern bool _QTaggingSupported(int wid=0, _str lang=null);

/**
 * @return Returns non-zero value if this editor controls 
 * language mode supports local tag navigation commands such as
 * <b>list_localss</b> and <b>find_tag</b> and <b>push_tag</b> 
 * for locally declared variables. 
 *
 * @param wid     Window id of MDI frame window.
 * @param lang    current language ID 
 *                (default={@link p_LangId})
 *  
 * @see _QTaggingSupported
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 24.0
 */
extern bool _QLocalsSupported(int wid=0, _str lang=null);

/** 
 * @return Returns 'true' if the given file has support 
 * for a load-tags callback function, such as for loading 
 * symbols from a ZIP file or a DLL with metadata or a 
 * Java class file or JAR file. 
 *  
 * @param filename   name of file to test, defaults to current file
 * 
 * @see push_tag
 * @see gui_make_tags
 * @see make_tags
 * @see _QTaggingSupported
 * @see _QLocalsSupported
 * 
 * @categories Search_Functions, Tagging_Functions
 */
extern bool _QBinaryLoadTagsSupported(_str filename=null);

/** 
 * Suspend buffer callbacks. This is needed in cases where you 
 * modify the buffer but will put it back the way it was.  There 
 * are cases (DIFFzilla) where when this happens a callback is 
 * triggered that causes erroneous data and it is not corrected 
 * merely by the buffer being put back to its original contents.
 * 
 * @param bufID Buffer ID to suspend/unsuspend callback for
 * @param isSuspended 1 to suspend callbacks, 0 to unsuspend 
 *                    them.
 */
extern void _CallbackBufSuspendAll(int bufID,int isSuspended);

/**
 * Gets the suspend state of the callbacks for <B>bufID</B>
 *  
 * @param bufID buffer to get the suspend state for
 * 
 * @return int 0 if the callbacks are not suspended, >=0 if they 
 *         are.
 */
extern int _CallbackBufSuspended(int bufID);

/**
 * Find the language type that the given file extension is mapped to.
 * This will first check if there is a language-to-extension mapping 
 * for 'ext', then it will check for language setup information 'ext'.
 * Failing that, it will attempt to do a case-insensitive search for 
 * a language mapping, if the default operating system file system is 
 * case-insensitive.
 * 
 * @param ext  file name extension
 * 
 * @return Returns the language ID for the language mode 
 *         associated with the given file extension.
 *         Returns '' if no match is found.
 *
 * @categories Miscellaneous_Functions
 */
extern _str _Ext2LangId(_str ext);

/** 
 * Converts the unique display name for a language to it's 
 * language ID (canonical file extension).  This 
 * function will only search your current language setup. 
 * It will not attempt to autoload additional language 
 * features. 
 * 
 * @param mode_name     Display name for language type 
 * 
 * @return The language ID for the language 
 *         corresponding to 'mode_name'. 
 *  
 * @categories Miscellaneous_Functions 
 */
extern _str _Modename2LangId(_str mode_name);

/** 
 * Converts a language ID (canonical file extension) to 
 * the unique display name for a language.
 * 
 * @param lang    Language ID (see {@link p_LangId} 
 * 
 * @return The mode name for the language.
 *  
 * @categories Miscellaneous_Functions 
 */
extern _str _LangId2Modename(_str lang);

/** 
 * Converts a language ID (canonical file extension) to 
 * the unique display name for a language.
 * 
 * @param lang    Language ID (see {@link p_LangId} 
 * 
 * @return The mode name for the language.
 *  
 * @categories Miscellaneous_Functions 
 */
extern _str _LangGetModeName(_str lang);

/** 
 * Compare two language mode names. 
 * Language mode names are case-insensitive.
 *  
 * @categories Miscellaneous_Functions
 */
extern bool _ModenameEQ(_str a,_str b);

/** 
 * Locates the first language specification that uses the 
 * given lexer name.  Note there is no guarantee that the 
 * mapping form lexer names to languages should be unique, 
 * so use this function sparingly, as it will *only* find 
 * the first match. 
 * 
 * @param lexer_name     Language lexer name 
 * 
 * @return The language ID for the language 
 *         corresponding to 'lexer_name'. 
 *  
 * @see _LangId2LexerName 
 * @see _Modename2LangId 
 * @see _Filename2LangId 
 * @see _Ext2LangId 
 *  
 * @categories Miscellaneous_Functions 
 */
extern _str _LexerName2LangId(_str lexer_name);

/**
 * @return Return the name of the color coding lexer for the 
 *         given language ID. 
 * 
 * @param lang File language ID (see {@link p_LangId}).
 *  
 * @see _Ext2LangId 
 * @see _Filename2LangId 
 *  
 * @categories Miscellaneous_Functions
 * @deprecated Use {@link _LangGetLexerName()}. 
 */
extern _str _LangId2LexerName(_str lang);

/**
 * @return Return the name of the color coding lexer for the 
 *         given language ID. 
 * 
 * @param lang File language ID (see {@link p_LangId}).
 *  
 * @see _Ext2LangId 
 * @see _Filename2LangId 
 *  
 * @categories Miscellaneous_Functions
 */
extern _str _LangGetLexerName(_str lang);

/**
 * @return Return absolute path of user's local configuration 
 * directory with a trailing file separator. 
 *
 * @categories File_Functions
 */
extern _str _ConfigPath();

/**
 * @return Return absolute path of user's local
 * Downloads with a trailing file separator.
 *
 * @categories File_Functions
 */
extern _str _DownloadsPath();
/**
 * @return Return absolute path of user's local
 * home directory with a trailing file separator.
 *
 * @categories File_Functions
 */
extern _str _HomePath();
/**
 * @return Return absolute path of user's local
 * documents directory with a trailing file separator.
 *
 * @categories File_Functions
 */
extern _str _DocumentsPath();

/**
 * @return Return the date the SlickEdit executable was built. 
 *         The date is returned in the standard format of "MMM dd YYYY". 
 *
 * @categories Miscellaneous_Functions
 */
extern _str _getSlickEditBuildDate();

/**
 * Retrieve the registered MDI child (p_mdi_child != 0) from an 
 * MDI child form. 
 *  
 * @param wid MDI child form which contains the registered MDI 
 *            child (p_mdi_child == _mdi).
 * 
 * @return Window id of registered MDI child.
 */
extern int _MDIGetChildFromForm(int wid);

/**
 * Retrieve the MDI child form that contains the registered MDI 
 * child (p_mdi_child != 0). 
 *  
 * @param wid Registered MDI child (p_mdi_child != 0) which is 
 *            contained by MDI child form.
 * 
 * @return Window id of MDI child form.
 */
extern int _MDIGetFormFromChild(int wid);

/**
 * Create a new horizontal tabgroup from editor control
 * specified by <code>wid</code>. If editor control is already
 * part of a tabgroup, then it is removed and inserted into new
 * tabgroup. Set <code>insertAfter=true</code> to insert new 
 * tabgroup below current tabgroup. 
 *
 * @param wid
 */
extern void _MDIChildNewHorizontalTabGroup(int wid, bool insertAfter, bool edge=false);

/**
 * Create a new vertical tabgroup from editor control
 * specified by <code>wid</code>. If editor control is already
 * part of a tabgroup, then it is removed and inserted into new
 * tabgroup. Set <code>insertAfter=true</code> to insert new 
 * tabgroup to the right of current tabgroup. 
 *
 * @param wid
 */
extern void _MDIChildNewVerticalTabGroup(int wid, bool insertAfter, bool edge=false);

/**
  * Save window layout <code>state</code> of MDI form and encode
  * to string. Used by auto-restore. Specify which areas to save 
  * by setting <code>areas</code> to one or more 
  * WindowLayoutArea flags. 
  *
  * @param state 
  * @param areas 
  */
extern void _MDISaveState(_str& state, int areas);

/**
  * Restore window layout <code>state</code> of MDI form 
  * returned from <code>_MDISaveState</code>. Used by 
  * auto-restore. Specify which areas to restore by setting 
  * <code>areas</code> to one or more WindowLayoutArea flags. 
  * Set optional <code>flags</code> to one or more 
  * RestoreStateFlag. 
  *
  * @param state 
  * @param areas 
  * @param flags 
  *
  * @return true on success.
  */
extern bool _MDIRestoreState(_str& state, int areas, int flags);

/** 
 * Save layout <code>state</code> for specified mdi-window 
 * <code>mdi_wid</code> and return as encoded string. Specify 
 * which areas to restore by setting <code>areas</code> to one 
 * or more WindowLayoutArea flags. 
 *
 * @param mdi_wid 
 * @param state 
 * @param areas 
 */
extern void _MDIWindowSaveLayout(int mdi_wid, _str& state, int areas);

/**
 * Restore windows from array <code>wids</code> into specified 
 * mdi window <code>mdi_wid</code> using layout 
 * <code>state</code> returned from 
 * <code>_MDIWindowSaveLayout</code>. Specify which areas to 
 * restore by setting <code>areas</code> to one or more 
 * WindowLayoutArea flags. Set optional <code>flags</code> to 
 * one or more RestoreStateFlag. 
 * 
 * @param mdi_wid 
 * @param state 
 * @param areas 
 * @param flags 
 * @param wids 
 *
 * @return true on success.
 */
extern bool _MDIWindowRestoreLayout(int mdi_wid, _str& state, int areas, int flags, int (&wids)[]);

/**
 * Float/dock MDI child window <code>wid</code>.
 *
 * @param wid
 * @param doFloat   If true window is floated
 */
extern void _MDIChildFloatWindow(int wid,bool doFloat);

/**
 * Return true if MDI child window <code>wid</code> is a 
 * floating window, false if a docked window. 
 *  
 * @param wid
 *
 * @return bool.
 */
extern bool _MDIChildIsFloating(int wid);

/**
 * 
 * Indicates that the mouse is captured.
 * 
 * @author cmaurer (1/29/2008)
 * 
 * @return Returns true if the mouse has been captured by 
 *         mou_capture or a vlayer call vset_capture() (or
 *         Windows SetCapture() call).
 *         
 */
extern bool mou_is_captured();

/**
 * Starts from cursor position and skips over spaces, tabs, and comments.
 *
 * @param options may contain one or more of the following option letters: 
 * <dl compact> 
 * <dt>-<dd>Search backwards
 * <dt>m<dd>Search within selection
 * <dt>h<dd>Search through hidden lines.
 * <dt>c<dd>Skip spaces within comments
 * <dt>q<dd>Quick mode -- does not check for embedded code
 * </pre>
 * </ul>
 * @return  Returns 0 if non-blank character is found, nonzero 
 * otherwise. If this functions fails the cursor is moved but its final 
 * location may not be the top or bottom of the buffer (we need to change 
 * this should be more concrete). 
 *    
 * @see _clex_find
 * @see p_color_flags
 * @see _clex_load
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Search_Functions
 */
extern int _clex_skip_blanks(_str options='');

/**
 * Creates a zip package with the given file name, containing the given array of
 * files.  All file names (in the zip file name and in the array) must include 
 * full paths to the file. 
 * 
 * @param filename            name of zip file
 * @param files               files to be zipped up and included
 * 
 * @return                    0 for success, error code otherwise 
 *  
 * @categories File_Functions
 */
extern int _ZipCreate(_str filename, _str (&files)[], int (&zipStatus)[], _str (&archiveFilenames)[]=null);

/**
 * Appends to a zip package with the given file name, containing
 * the given array of files.  All file names (in the zip file 
 * name and in the array) must include full paths to the file. 
 * 
 * @param filename            name of zip file
 * @param files               files to be zipped up and included
 * 
 * @return                    0 for success, error code otherwise 
 *  
 * @categories File_Functions
 */
extern int _ZipAppend(_str filename, _str (&files)[], int (&zipStatus)[], _str (&archiveFilenames)[]=null);

/**
 * Close cached zip file so that it can be written to.
 *  
 * <P>Only closes the zip file if the reference count is 0.
 *  
 * <P>Reference count is 0 if no files in the zip file are open.
 *  
 * @param filename file to close
 * 
 */
extern void _ZipClose(_str filename);

/**
 * Get logged in user name.
 * 
 * @return Logged in user name.
 */
extern _str _GetUserName();

/**
 * @return Returns <i>filename</i> with part stripped.  P=Path, D=Drive,
 * E=Extension, N=Name, /=FileSep.
 *
 * @categories File_Functions, String_Functions
 *
 */
extern _str _strip_filename(_str name,_str options);

/**
 * Returns extension of buffer name without dot unless returnDot is true.
 *
 * @param buf_name  Filename to get extension from.
 * @param returnDot Specify true if you want '.' included in return value.
 * @return Returns extension of buffer name.
 *
 * @categories File_Functions
 */
extern _str _get_extension(_str buf_name,bool returnDot=false);

/** 
 * @return 
 * Returns <i>filename</i> in operating system specific case.
 * For DOS and Windows NT, file names are case-insensitive,
 * so they are converted to lower case.  This is useful for
 * storing filenames in a case-agnostic manner.
 * <p>
 * <i>_file_case()</i> should be used under rare cirumstances.
 * It is preferrable to use {@link file_eq()} to compare files
 * without modifying their case.
 *
 * @param filename   File path to convert.
 * 
 * @categories File_Functions
 */
extern _str _file_case(_str a);

/**
 * @return Returns true if <i>filename,</i> needs to be quoted 
 *         when passed as an argument to an external program.
 *  
 * @param filename     file name or file path or directory path 
 * @param filenameLen  (optional) length(filename) 
 *
 * @categories File_Functions
 */
extern bool _filename_needs_to_be_quoted(_str filename, int filenameLen=-1);

/**
 * @return Returns <i>filename,</i> with quotes around it, 
 *         if it contains a space character or another character
 *         which is special to the file system (os dependent).
 *         Otherwise <i>filename</i> is returned unaltered.
 *
 * @param filename     file name or file path or directory path 
 *  
 * @categories File_Functions
 */
extern _str _maybe_quote_filename(_str filename);

/**
 * @return 
 * Returns <i>filename,</i> with quotes removed. 
 * This function will also strip leading spaces if present.
 *
 * @param filename     file name or file path or directory path 
 *  
 * @categories File_Functions
 */
extern _str _maybe_unquote_filename(_str filename);

/**
 * Strip the FILESEP charactor (/ or backslash) from the end of the given 
 * string if the string ends with a FILESEP. 
 * 
 * @param path    (reference) string to strip FILESEP from
 *  
 * @categories String_Functions, File_Functions 
 *  
 * @see _maybe_append_filesep 
 * @see _maybe_strip 
 */
extern void _maybe_strip_filesep(_str &path);

/**
 * If the given path does not already end with a file separator, then we add 
 * one.  Use checkForQuotes = false to do a "dumb" check, where we simply look 
 * at the last character and add a file separator.  Set to true to do a smarter 
 * check that determines if the path is enclosed in double quotes, therefore 
 * checking the last character before the closing quote. 
 *  
 * If double quotes are found in the initial path, they will be in the final 
 * path.  No checking to determine if they are necessary is done.  That's your 
 * own business. 
 * 
 * @param path                      path to possibly add a filesep to
 * @param checkForQuotes            whether to check if the path is in quotes 
 *  
 * @categories File_Functions
 */
extern void _maybe_append_filesep(_str &path, bool checkForQuotes = false);

/**
 * Append the string 'ch' (usually a single character) to the end of the given 
 * string if the string does not already end with 'ch'.  By default, do not 
 * append 'ch' if the string is initially empty. 
 * 
 * @param text           (reference) string to append to
 * @param ch             character or token to append
 * @param appendIfEmpty  (default false) append 'ch' if 'text' is empty 
 *  
 * @categories String_Functions 
 *  
 * @see _maybe_prepend 
 * @see _maybe_append_filesep 
 * @see _maybe_strip 
 */
extern void _maybe_append(_str& text, _str ch, bool appendIfEmpty=false);
/**
 * Prepend the string 'ch' (usually a single character) to the beginning of the 
 * given string if the string does not already start with 'ch'.  By default, 
 * do not add 'ch' if the string is initially empty. 
 * 
 * @param text           (reference) string to prepend onto
 * @param ch             character or token to add
 * @param appendIfEmpty  (default false) add 'ch' if 'text' is empty 
 *  
 * @categories String_Functions 
 *  
 * @see _maybe_prepend 
 * @see _maybe_append_filesep 
 * @see _maybe_strip 
 */
extern void _maybe_prepend(_str& text, _str ch, bool appendIfEmpty=false);
/**
 * Strip the 'ch' (usually a single character) from the end of the given 
 * string if the string ends with it. 
 * 
 * @param text             (reference) string to strip chars from the end of
 * @param ch               character or token to remove 
 * @param stripFromFront   strip from beginning of string instead of end
 *  
 * @categories String_Functions
 *  
 * @see _maybe_append
 * @see _maybe_strip_filesep
 */
extern void _maybe_strip(_str &text, _str ch, bool stripFromFront=false);

/**
 * @return Returns first character of <i>string</i>. 
 * If string is null, the empty string is returned.
 *
 * @param string   string to get the first character from 
 * @param isUtf8   specific UTF-8 option (e.g. {@link p_UTF8})          
 *  
 * @categories String_Functions 
 *  
 * @see first_char 
 * @see last_char 
 * @see _last_char 
 */
extern _str _first_char(_str string, int isUtf8=-1);
/**
 * @return Returns last character of <i>string</i>. 
 * If string is null, the empty string is returned.
 *
 * @param string   string to get the first character from 
 * @param isUtf8   specific UTF-8 option (e.g. {@link p_UTF8})          
 *
 * @categories String_Functions
 *  
 * @see last_char 
 * @see raw_last_char 
 * @see first_char 
 * @see _first_char 
 */
extern _str _last_char(_str string, int isUtf8=-1);

/** 
 * @return 
 * Calculate a hash code for the given string.
 * 
 * @param str             string to calculate hash code for
 * @param isFileName      is 'str' a file name or path?
 * @param caseSensitive   is 'str' case sensitive?  Ignored if 'isFileName' is true
 * 
 * @categories String_Functions
 */
extern int _string_hash(_str str, bool isFileName=false, bool caseSensitive=true);

/**
 * @return 
 * Convert the given number to a hexadecimal string, with optional leading 
 * zero or space padding, and an optional prefix, such as "0x" 
 * 
 * @param val             integer to convert to hex
 * @param base            number base (default, 16 for hexadecimal)
 * @param zeroPadWidth    pad number with leading zeros to this width
 * @param spacePadWidth   pad number with leading spaces to this width
 *  
 * @see dec2hex
 * @categories String_Functions
 */
extern _str _dec2hex(long val, int base=16, int zeroPadWidth=0, int spacePadWidth=0);

/** 
 * @return Returns <i>val</i> of base 16 or <i>base</i> specified in base 10. 
 *         Only bases 2, 8, 10, and 16 are supported. 
 *         If <i>number</i> is null, empty, or otherwise invalid, 0 is returned
 *         and <i>success</i> is set to false.
 *  
 * @param val     string containing number to convert 
 *                <ul>
 *                <li>0xNNNN, xNNNN, or NNNN  represent a valid hex number </li>
 *                <li>0NNNN for an Octal number 0bNNNN</li>
 *                <li>0bNNNN or bNNNN represent a valid binary number</li>
 *                </ul>
 * @param base    input number base. Defaults to 16. 
 * @param success set to 'false' if 'val' is in invalid number 
 * 
 * Binary numbers may start with 'b' or '0b'. 
 * Hex numbers may start with '0x' or 'x'. 
 * Octal numbers may start with the digit '0'.
 *  
 * A trailing 'L' indicates that the number should be treated as a 64-bit integer. 
 * A trailing 'U' indicates that the number should be treated as unsigned. 
 * 'U' and 'L' can be used in combination. 
 *  
 * @see hex2dec 
 * @see _hex2long
 * @categories String_Functions
 */
extern int _hex2dec(_str val, int base=16, bool &success=null);

/** 
 * @return Returns <i>val</i> of base 16 or <i>base</i> specified in base 10. 
 *         Only bases 2, 8, 10, and 16 are supported. 
 *         If <i>number</i> is null, empty, or otherwise invalid, 0 is returned
 *         and <i>success</i> is set to false.
 *  
 * @param val     string containing number to convert 
 *                <ul>
 *                <li>0xNNNN, xNNNN, or NNNN  represent a valid hex number </li>
 *                <li>0NNNN for an Octal number 0bNNNN</li>
 *                <li>0bNNNN or bNNNN represent a valid binary number</li>
 *                </ul>
 * @param base    input number base. Defaults to 16.
 * @param success set to 'false' if 'val' is in invalid number 
 * 
 * Binary numbers may start with 'b' or '0b'. 
 * Hex numbers may start with '0x' or 'x'. 
 * Octal numbers may start with the digit '0'.
 *  
 * A trailing 'L' indicates that the number should be treated as a 64-bit integer. 
 * A trailing 'U' indicates that the number should be treated as unsigned. 
 * 'U' and 'L' can be used in combination. 
 *  
 * @see hex2dec 
 * @see _hex2dec 
 * @categories String_Functions
 */
extern long _hex2long(_str val, int base=16, bool &success=null);

/** 
 * @return 
 * Convert the given number to a floating point string, with optional leading 
 * space or trailing space padding, and using the decimal precision specified. 
 *  
 * The formatting options are: 
 * <ul> 
 *    <li><b>'g'</b> -- scientific notation with base 10 exponent</li>
 *    <li><b>'f'</b> -- floating point notation, no exponent (can be very long)</li>
 *    <li><b>'x'</b> -- hexadecimal floating point notation with base 10 exponent </li>
 * </ul>
 * 
 * @param number             number to format
 * @param formatOption       one of formatting options described above
 * @param decimalPrecision   max number of digits after decimal point
 * @param spaceBeforeDot     number of spaces to pad before the number up to the decimal point
 * @param spacePadWidth      min number of spaces to pad after number
 * 
 * @see dec2hex
 * @categories String_Functions
 */
extern _str _double2asc(typeless number, _str formatOption, int decimalPrecision=10, int spaceBeforeDot=0, int spacePadWidth=0);

const FLMFOFLAG_DIRECTORIES=       0x1;
const FLMFOFLAG_DISKFILES=         0x2;
const FLMFOFLAG_PROJECTFILES=      0x4;
const FLMFOFLAG_WORKSPACEFILES=    0x8;
const FLMFOFLAG_HISTORYFILES=     0x10;
const FLMFOFLAG_OPENFILES=        0x20;
const FLMFOFLAG_SAMEDIRFILES=     0x40;
const FLMFOFLAG_ORIGINMASK=       0x7f;
const FLMFOFLAG_ISDOTDOTDIR=      0x80;
const FLMFOFLAG_MODIFIED=        0x100;
const FLMFOFLAG_BITMAPMASK=     (FLMFOFLAG_ORIGINMASK | FLMFOFLAG_ISDOTDOTDIR);
//#define FLMFOFLAG_MODIFIERMASK   (FLMFOFLAG_MODIFIED|FLMFOFLAG_ISDOTDOTDIR)

/**
 * Creates a new File List Manager instance handle, or returns 
 * an existing one. All list manager clients should reserve 
 * their own instance handle by specifying a unique name. 
 * 
 * @param  clientName Unique string of caller/client
 * @return int instance data handle 
 */
extern  int FileListManager_GetHandle(_str clientName);
/**
 * Frees the memory used by a File List Manager client
 * 
 * @param flmHandle Handle to instance data
 */
extern void FileListManager_ReleaseHandle(int flmHandle);
/**
 * Forces the file list manager to refresh the list of files in 
 * the current workspace. 
 * 
 * @param flmHandle Handle to instance data
 */
extern void FileListManager_RefreshWorkspaceFiles(int flmHandle, bool forceRefresh=false);
extern void FileListManager_SetDisplayCallback(int flmHandle, int WID);
/**
 * Forces the file list manager to refresh the list of files 
 * currently open in the editor. 
 * @param flmHandle Handle to instance data
 */
extern void FileListManager_RefreshOpenFiles(int flmHandle);
/**
 * Forces the files list manager to re-read the list of file 
 * open history from the MDI menu 
 * @param flmHandle Handle to instance data
 */
extern void FileListManager_RefreshFileHistory(int flmHandle);
/**
 * Forces the files list manager to compile a list of files (and
 * subdirectory names) in the specified directory path. 
 * 
 * @param flmHandle Handle to instance data
 * @param directoryPath Full path to the directory in question 
 * @param showHidden If true, include hidden files and "dot" 
 *                   files in the results
 */
extern void FileListManager_RefreshDiskFiles(int flmHandle, _str directoryPath, bool showHidden =false);

/**
 * Forces the files list manager to compile a list of files in 
 * the specified directory path. 
 * 
 * @param flmHandle Handle to instance data
 * @param directoryPath Full path to the directory in question 
 * @param showHidden If true, include hidden files and "dot" 
 *                   files in the results
 */
extern void FileListManager_RefreshSameDirFiles(int flmHandle, _str directoryPath, bool showHidden =false);

/** 
 * Loads all of the file information for the files in iWID
 * 
 * @param flmHandle Handle to instance data
 * @param iWID Window ID of tree control with filenames
 */
void FileListManager_LoadDisplayedInfo(int flmHandle, int treeWID);
/**
 * Sets which bitmap is used to represent a file or directory 
 * when the list is used to populate a tree control.  
 * 
 * @param flmHandle 
 * @param fileTypeFlag One of file origin flags (eg: 
 *                     FLMFOFLAG_PROJECTFILES )
 * @param picIndex Bitmap index for "normal" file 
 * @param openPicIndex Bitmap index for a file that is open 
 *                (FLMFOFLAG_ISOPEN flag is set)
 */
extern void FileListManager_SetFileTypeBitmap(int flmHandle, int fileTypeFlag, int picIndex, int openPicIndex);
/**
 * Sets a "files of type" filter, which is just a semicolon 
 * separated list of file extensions. 
 * 
 * @param flmHandle Handle to instance data
 * @param extensions Slick-C array of strings, which are file 
 *                   extensions to be filtered on. This is the
 *                   semicolon delimited list which has already
 *                   been split up.
 */
extern void FileListManager_SetExtensionFilter(int flmHandle, _str (&extensions)[]);
/**
 * Populate a tree control with the current file list.
 * 
 * 
 * @param flmHandle Handle to instance data
 * @param treeWid Window ID of the tree control
 * @param treeNode Tree node to receive the list (eg: 
 *                 TREE_ROOT_INDEX)
 * @param whichFileSetsFlags Combination of FLMFOFLAG_??? values 
 *                    to determine which sets are to be shown
 * @param filter Optional wildcard filter 
 * @param prefixMatch Indicates if prefix matching should be 
 *                    done when applying the filter
 * @see  FileListManager_InsertSortedListIntoTree
 * @note Slick-C caller should wrap this call with 
 *       _TreeBeginUpdate and _TreeEndUpdate calls.
 */
extern int FileListManager_InsertListIntoTree(int flmHandle, int treeWid, int treeNode, int whichFileSetsFlags, _str filter='', bool prefixMatch=false, _str curDir='',bool emptyPrefixMatchesEverything=false,bool bResizeColumnsToContents=true,bool bShowRelativeDirs=true,int iWildcardExtMatchStyle=OPENTB_WC_CURDIR_EXACT_MATCHING ,int iWildcardMatchStyle=OPENTB_WC_RECURSIVE_EXACT_MATCHING,int iNonWildcardMatchStyle=OPENTB_WC_RECURSIVE_CONTAINS_MATCHING,int tbopen_cols=0);
/**
 * Populate a tree control with a sorted file list.
 * Works just like FileListManager_InsertListIntoTree, but 
 * allows specifying a non-Default sort order. 
 * 
 * @param flmHandle Refer to FileListManager_InsertListIntoTree 
 *                  for all this and other parameters
 * @param sortOrder One of the FLMSORT_??? constants 
 * @see FLMSORT_DEFAULT 
 * @see FLMSORT_FILENAME_ASC 
 * @see FLMSORT_FILENAME_DESC 
 * @see FLMSORT_FULLPATH_ASC 
 * @see FLMSORT_FULLPATH_DESC 
 * @see  FileListManager_InsertListIntoTree
 * @note Slick-C caller should wrap this call with 
 *       _TreeBeginUpdate and _TreeEndUpdate calls.
 */
extern int FileListManager_InsertSortedListIntoTree(int flmHandle, int treeWid, int treeNode, int whichFileSetsFlags, int sortOrder, _str filter='', bool prefixMatch=false, _str curDir='');

/**
 * Selects the matching tree item for the given key.  This is 
 * meant to add incremental search to the tree. 
 *  
 * @param wid   window id of tree
 * @param key   search key
 */
extern int FileListManager_SelectMatch(int wid, _str key);

/** Default sort order for FileListManager. Groups by file type
 *  (disk files, project/workspace, etc), then sorts by file
 *  name.
*/
const FLMSORT_DEFAULT= 0;
/**
 * Sorts by file name (no path), ascending
 */
const FLMSORT_FILENAME_ASC= 1;
/**
 * Sorts by file name (no path), descending
 */
const FLMSORT_FILENAME_DESC= 2;
/**
 * Sorts by full file path, ascending
 */
const FLMSORT_FULLPATH_ASC= 3;
/**
 * Sorts by full file path, descending
 */
const FLMSORT_FULLPATH_DESC= 4;
///////////////////////////////////////////////////////
// Project support methods (from the projsupp library)
//////////////////////////////////////////////////////

// Xcode project support methods
extern int _InsertXcodeProjectHierarchy(_str projectPath, int treeID, int iParentIndex);
extern int _InsertXcodeProjectFileList(_str projectPath, int windowID, bool AbsolutePaths);
extern int _GetXcodeProjectConfigurations(_str projectPath,_str (&configurations)[]);
extern int _GetXcodeWorkspaceSchemes(_str workspacePath,_str (&schemes)[]);
extern int _GetXcodeProjectName(_str projectPath, _str& projectName);
extern int _GetXcodeProjectOutputFilename(_str projectPath, _str configString, _str sdkName, _str& outputFilePath);
extern int _GetXcodeProjectSDKRoot(_str projectPath, _str configString, _str& sdkRoot);
extern int _GetXcodeProjectGetSubProjects(_str projectPath,_str (&projects)[]);
extern void _XcodeProjectClosed();

/**
 * Clears the internal cache of file lists for this workspace.
 *  
 * @categories Project_Functions
 */
extern void _clearWorkspaceFileListCache();

/**
 * Starts a new cache of file lists for a workspace.
 * 
 * @param workspaceFile             full path to new workspace 
 *                                  file
 *  
 * @categories Project_Functions
 */
extern void _openNewWorkspaceFileListCache(_str workspaceFile);

/**
 * Clears the cached file list for the given project.  This 
 * should be called whenever a project changes. 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 *  
 * @categories Project_Functions
 */
extern void _clearProjectFileListCache(_str workspaceFile, _str projectFile);

/**
 * Returns the number of files in the current project.
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * 
 * @return int                   number of files in project
 *  
 * @categories Project_Functions
 */
extern int _getNumProjectFiles(_str workspaceFile, _str projectFile);

/**
 * Returns whether the project's list of files has been cached.
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * 
 * @return int 
 *  
 * @categories Project_Functions
 */
extern int _isProjectInfoCached(_str workspaceFile, _str projectFile);

/**
 * Retrieves a list of the files in the given project.
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param filelist               array to fill with file names
 * @param absolutePath           non-zero to retrieve absolute 
 *                               paths, zero to retrieve paths
 *                               relative to the project file
 * 
 * @return int                   0 on success, non-zero 
 *                               otherwise
 *  
 * @categories Project_Functions
 */
extern int _getProjectFiles(_str workspaceFile, _str projectFile, _str (&filelist)[], int absolutePath, int projectHandle = -1,bool expandWildCardsInAssociatedProjects=true);

/**
 * Retrieves a list of the derived source files in the given 
 * project.  Derived source files are created by rules run 
 * during compilation. 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param filelist               array to fill with file names
 * @param absolutePath           non-zero to retrieve absolute 
 *                               paths, zero to retrieve paths
 *                               relative to the project file
 * 
 * @return int                   0 on success, non-zero 
 *                               otherwise
 *  
 * @categories Project_Functions
 */
extern int _getProjectDerivedSourceFiles(_str workspaceFile, _str projectFile, _str (&filelist)[], int absolutePath, int projectHandle = -1);

/**
 * Determines if the given file is in the given project.
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param file                   file to look for
 * 
 * @return int                   1 if file is in project, 0 if 
 *                               file is not in project
 *  
 * @categories Project_Functions
 */
extern int _isFileInProject(_str workspaceFile, _str projectFile, _str file);

/**
 * Determines if the given file is a derived source file in the 
 * given project.  A derived source file is a file that is not 
 * in the project, but is created by one of the rules run in the
 * one of the tool steps. 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param file                   full path of file to look for
 * 
 * @return int                   1 if file is a derived source 
 *                               file in project, 0 if file is
 *                               otherwise
 *  
 * @categories Project_Functions
 */
extern int _isDerivedSourceFile(_str workspaceFile, _str projectFile, _str file);

/**
 * Retrieves a list of the project files included in this 
 * workspace.  Paths are relative. 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projFileList           relative paths of projects
 * 
 * @return int                   0 on success, non-zero 
 *                               otherwise
 *  
 * @categories Project_Functions
 */
extern int _getProjectFilesInWorkspace(_str workspaceFile, _str (&projFileList)[]);

/**
 * Retrieves a list of the files in the given workspace.
 * 
 * @param workspaceFile          full path to workspace file
 * @param filelist               array to fill with file names
 * 
 * @return int                   0 on success, non-zero 
 *                               otherwise
 *  
 * @categories Project_Functions
 */
extern int _getWorkspaceFiles(_str workspaceFile, _str (&filelist)[]);

/**
 * Searches for a file in a specified project.
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param file                   file to search for
 * @param checkPath              true to check the whole path, 
 *                               false for just the file name
 * @param returnAll              true to return all results in a 
 *                               string, false to return the
 *                               first found
 * @param matchPathSuffix        When true, path suffix specified in
 *                               filename must match path of
 *                               project file.
 *  
 * @return _str                  space-delimited list of full 
 *         matching paths.  Paths with spaces will be
 *         double-quoted
 *  
 * @categories Project_Functions
 */
extern _str _projectFindFile(_str workspaceFile, _str projectFile, _str file, 
                             int checkPath = 1, int returnAll = 0, int matchPathSuffix = 0);

/**
 * Returns the tagging option for the specified project from the project 
 * file cache.  The result is one of "Workspace", "Project", or "None" 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 *  
 * @return Returns "Workspace" if the project should be tagged as part of 
 *         the workspace tag file.  Returns "Project" if the project should be
 *         tagged as part of the project tag file.  Returns "None" if the
 *         files in the project should not be tagged.
 *  
 * @categories Project_Functions
 */
extern _str _projectGetTaggingOption(_str workspaceFile, _str projectFile);

/**
 * Searches for a file in a specified project using prefix 
 * matching.  Attempts to match only the filename, even if a 
 * full path is sent 
 * 
 * @param workspaceFile          full path to workspace file
 * @param projectFile            full path to project file
 * @param file                   file to search for - only the 
 *                               stripped filename will be used
 * @param list                   list of matching files 
 * 
 *  
 * @categories Project_Functions
 */
extern void _projectMatchFile(_str workspaceFile, _str projectFile, _str file, _str (&list)[],bool append,bool force_case_insensitive_matching=false);


/** 
 * Set dependency extensions for project inclusion when parsing 
 * Tornado projects. 
 * 
 * @param ext
 */
extern void _projectSetDependencyExtensions(_str ext);

// Visual Studio .vcxproj methods
extern int _InsertVCXProjectHierarchy(_str workspaceFilePath, _str projectFilePath, int isFilterFile, int treeID, int iParentIndex);
extern int _InsertVCXProjectFileList(_str projectFilePath, int xmlHandle, int viewListID, bool absPaths, bool indentSpace);
extern int _VCXProjectInsertFile(_str projectFilePath, _str fileName, _str itemType, _str folderPath);
extern int _VCXProjectDeleteFile(_str projectFilePath, _str fileName);
extern int _VCXProjectInsertFolder(_str projectFilePath, _str folderPath, _str extensions, _str uuid);
extern int _VCXProjectDeleteFolder(_str projectFilePath, _str folderPath, int removeFiles);

extern void _SLNGetSolutionConfigs(_str solutionFileName, _str (&configs)[]);
extern void _SLNSolutionConfigToProjectConfig(_str solutionFileName, _str projectFileName, _str configName, _str& projectConfigName);
extern void _SLNSolutionConfigClose();

extern void _MSBuildGetCustomView(int srcHandle, int destHandle, int filesNode, _str projectFilePath);
extern bool _csproj2005Get_AutoAddWildcards(int handle,_str (&wildcardList)[]=null, _str (&excludeList)[]=null);

/** 
 * Set extensions for generic MSBUILD project types
 * 
 * @param ext '.projtype1;.projtype2'
 */
extern void _VisualStudioSetMSBuildProjectExtensions(_str exts);

extern int _ProjectBuildTree(_str workspaceFile, 
                             _str projectFile,
                             int handle,
                             int iMaxSccNum,
                             int iCurrentVCSIsScc,
                             int iParentIndex,
                             bool NormalizeFolderNames,
                             int RefilterWildcards=0);

extern int _ProjectTreeUpdateWildcard(_str workspaceFile,
                                      _str projectFile, 
                                      int wid, int handle,
                                      int root_index, int folder_index);

// Creation of a desktop shortcut on Gnome/KDE
#if 1 /*__UNIX__ && !__MACOSX__*/
extern void _X11CreateDesktopShortcut();
#endif

#if 1 /*__MACOSX__*/
/**
 * Use to turn on/off the blue focus rectangle that the Mac 
 * draws over the top of some focused controls. Exported from 
 * macutils 
 * @param windowID WinID of a tree, list, combo, or text box 
 *                 control
 * @param policy If 0, turn off the focus rectangle, 1 to turn 
 *               it back on.
 */
void macSetShowsFocusRect(int windowID, int policy);
#endif

extern void _AddTextChangeCallback(int wid, int index);
extern void _RemoveTextChangeCallback(int wid, int index);
/**
 * Creates a new empty clipboard when can have one or 
 * more clipboards added to it. 
 *  
 * Note: _clipboard_close() must be called to free memory.
 *  
 * @see _copy_color_coding_to_clipboard 
 * @see copy_to_clipboard
 * @see _clipboard_close
 * @see _clipboard_open
 *
 * @categories Clipboard_Functions
 */
extern void _clipboard_open();
/**
 * Places the newly created clipboard onto the system 
 * clipboard. 
 *  
 * Note: _clipboard_close() must be called to free memory. 
 *  
 * @param isClipboard
 *               Indicates whether operation is performed for the clipboard or selection.  Effects Unix only.
 *  
 * @see _copy_color_coding_to_clipboard 
 * @see copy_to_clipboard
 * @see _clipboard_close
 * @see _clipboard_open
 *
 * @categories Clipboard_Functions
 */
extern void _clipboard_close(bool isClipboard);

_metadata enum_flags AutoBracketFlags {
   AUTO_BRACKET_ENABLE              = 0x00000001,
   AUTO_BRACKET_PAREN               = 0x00000002,
   AUTO_BRACKET_BRACKET             = 0x00000004,
   AUTO_BRACKET_ANGLE_BRACKET       = 0x00000008,
   AUTO_BRACKET_DOUBLE_QUOTE        = 0x00000010,
   AUTO_BRACKET_SINGLE_QUOTE        = 0x00000020,
   AUTO_BRACKET_PAREN_PAD           = 0x00000040,
   AUTO_BRACKET_BRACKET_PAD         = 0x00000080,
   AUTO_BRACKET_ANGLE_BRACKET_PAD   = 0x00000100,
   AUTO_BRACKET_BRACE               = 0x00000200,
   AUTO_BRACKET_BRACE_PAD           = 0x00000400,
   AUTO_BRACKET_DEFAULT             = AUTO_BRACKET_PAREN|AUTO_BRACKET_BRACKET|AUTO_BRACKET_DOUBLE_QUOTE|AUTO_BRACKET_SINGLE_QUOTE|AUTO_BRACKET_BRACE,
};

const AUTO_BRACKET_DEFAULT_OFF=             0;
const AUTO_BRACKET_DEFAULT_ON=              AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT;
const AUTO_BRACKET_DEFAULT_C_STYLE=         AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT|AUTO_BRACKET_ANGLE_BRACKET;
const AUTO_BRACKET_DEFAULT_HTML_STYLE=      AUTO_BRACKET_DEFAULT|AUTO_BRACKET_ANGLE_BRACKET;

_metadata enum_flags AutoBracketKeys {
   AUTO_BRACKET_KEY_ENTER           = 0x00000001,
   AUTO_BRACKET_KEY_TAB             = 0x00000002,
};

int def_autobracket_mode_keys;

_metadata enum FileTabSortOrders {
   FILETAB_ALPHABETICAL,
   FILETAB_MOST_RECENTLY_OPENED,
   FILETAB_MOST_RECENTLY_VIEWED,
   FILETAB_MANUAL,
};

_metadata enum FileTabNewFilePosition {
   FILETAB_NEW_FILE_ON_RIGHT,
   FILETAB_NEW_FILE_ON_LEFT,
   FILETAB_NEW_FILE_TO_RIGHT,
   FILETAB_NEW_FILE_TO_LEFT,
};

enum UseFileInfoOverlayFlags {
   FILE_OVERLAYS_NONE,
   FILE_OVERLAYS_NODE,
   FILE_OVERLAYS_PROPAGATE_UP
};

enum TreeDelegatesList {
   DEFAULT_DELEAGATE,
   GIT_GRAPH_DELEGATE
};

enum_flags EventPendingFlags {
   // Check for key events
   EVENTPENDING_KEY         = 0x00000001,
   // Check for mouse events
   EVENTPENDING_MOUSE       = 0x00000002,
   // Check for mouse-move event
   EVENTPENDING_MOUSE_MOVE  = 0x00000004,
   // Check for key events from recorded macro playback
   EVENTPENDING_MACRO       = 0x00000008
};
extern bool _ComboBoxListVisible();
extern void _size_hint(int &width,int &height);
extern int _frame_width();


/**
 * Gets the minimum width of a resizable form.
 * @appliesTo Form
 * @categories Form_Methods
 */
extern int _minimum_width();

/**
 * Gets the minimum height of a resizable form.
 * @appliesTo Form
 * @categories Form_Methods
 */
extern int _minimum_height();

/**
 * Gets the maximum height of a resizable form.
 * @appliesTo Form
 * @categories Form_Methods
 */
extern int _maximum_height();

/**
 * Gets the maximum width of a resizable form.
 * @appliesTo Form
 * @categories Form_Methods
 */
extern int _maximum_width();

/**
 * Sets the minimum size of a resizable form.
 * @param minX Min width in form coordinates
 * @param minY Min height in form coordinates
 * @appliesTo Form
 * @categories Form_Methods
 */
extern void _set_minimum_size(int minX, int minY);

/**
 * Sets the maximum height of a resizable form
 * @param maxWidth Max width in form coordinate. Use -1 for
 *                 unbounded width.
 * @param maxHeight Max height in form coordinate. Use -1 for
 *                  unbounded height.
 * @appliesTo Form
 * @categories Form_Methods
 */
extern void _set_maximum_size(int maxWidth, int maxHeight);

/**
 * Used to set the tooltip for a window at runtime. Used by
 * buttons that need to append to tooltip message displayed
 * (e.g. key bindings, etc.) without altering the original
 * p_message property value.
 *
 * @param s
 *
 * @appliesTo Picture_Box, Image
 * @categories Picture_Box_Methods, Image_Methods
 */
extern void _set_tooltip(_str s);

_metadata enum StripTrailingSpacesOption {
   STSO_OFF = 0,
   STSO_STRIP_ALL = 1,
   STSO_STRIP_MODIFIED = 2
}

_metadata enum ExpandTabsOption {
   ETO_OFF = 0,
   ETO_EXPAND_ALL = 1,
   ETO_EXPAND_MODIFIED = 2
};

// Cached setting from Admin.xml
bool def_hotfix_auto_prompt = true;

// Cached setting from Admin.xml
_str def_auto_hotfixes_path = '';

extern void _hotfix_auto_search(_str autoLoadDir, _str hotfixesDir);

/**
 * Determines if the hotfix auto search thread has finished running.
 * 
 * @return int         1 if thread is not running, 0 if it is still working 
 */
extern int _hotfix_auto_search_finished();

struct PERFILEDATA_INFO {
   _str m_filename;
   long m_seekPos;
   int m_col;
   int m_hexMode;
   int m_selDisp;
   int m_encodingSetByUser;
   int m_softWrap;
   _str m_xmlWrapScheme;
   _str m_xmlWrapOptions;
   _str m_langId;
};

/**
 * Initializes the per-file data system.
 * 
 * @param configDir              current configuration directory
 *  
 * @categories File_Functions
 */
extern void _per_file_data_init(_str configDir, int maxRecords);

/**
 * Does the exit tasks for the per-file data system.
 * 
 * @categories File_Functions
 */
extern void _per_file_data_exit();

/**
 * Updates the amount of per-file data records we want to keep.
 * 
 * @param limit                  new limit 
 *  
 * @categories File_Functions
 */
extern void _per_file_data_update_max_records(int maxRecords);

/**
 * Retrieves the per-file data for the given file.
 * 
 * @param filename               file to fetch data for
 * @param info                   VSPERFILE_INFO struct to hold data
 * 
 * @return int                   0 on success, non-zero if we do not have data 
 *                               for the given file
 *  
 * @categories File_Functions
 */
extern int _per_file_data_get_info(_str filename, PERFILEDATA_INFO &info);

/**
 * Sets the per-file data.  The filename is part of the VSPERFILE_INFO struct.
 * 
 * @param info                   VSPERFILE_INFO struct containing data
 * 
 * @return int                   0 on success, non-zero if we were unable to 
 *                               store this per-file data
 *  
 * @categories File_Functions
 */
extern int _per_file_data_set_info(PERFILEDATA_INFO &info, int setSDNum = 1);

/**
 * Clears the per-file data for the given file.
 * 
 * @param filename               file to clear data for
 *  
 * @categories File_Functions
 */
extern void _per_file_data_clear_info(_str filename);

struct FILELANGMAP_FILEPATTERN {
   _str m_regex;
   _str m_langId;
};

extern void _file_name_map_update_maps();

extern _str _file_name_map_file_to_language(_str filename);

extern void _file_name_map_initialize();

const F2LI_NO_CHECK_OPEN_BUFFERS=     0x1;            // do not check for file in list of open buffers
const F2LI_NO_CHECK_PERFILE_DATA=     0x2;            // do not check data from previously opened files
const F2LI_NO_CHECK_BINARY_DATA=    0x4;            // do not check file contents for binary data

/**
 * Returns the language mode associated with the given file.
 *
 * The <b>Language Options dialog box</b> allows you to map an
 * extension that to a language mode.  This function performs
 * that translation, and will also use the buffer
 * name to determine the language mode.
 *
 * If the file's actual extension matches a
 * <code>_[ext]_Filename2LangId()</code> callback, it will first
 * try the callback to see if the file, based on it's path or name
 * should be referred to an alternate language.
 *
 * Otherwise, if the file's actual extension matches a
 * <code>suffix_[ext]</code> callback, it will open the file
 * in a temporary view and try the callback to determine the
 * file's actual language type.
 *
 * @return Returns the language ID for the given file.
 *
 * @param file_name        source file name with path
 * @param options          one or more of the following flags ORed together:
 * <dl>
 * <dt>F2LI_NO_CHECK_OPEN_BUFFERS</dt><dd>Do not go through open buffers
 * to determine lang id.  Normally, we see if the file is already open
 * and then return its p_LangId property.  If this flag is included,
 * this step is skipped</dd>
 * <dt>F2LI_NO_CHECK_PERFILE_DATA</dt><dd>Do not go through data saved
 * for previously opened files to determine lang id.  Normally, we check
 * the data stored in perfile.xml to see if this file has been opened
 * before and has a stored lang id.  If this flag is included, this step
 * is skipped</dd>
 * </dl>
 *
 * @see get_extension
 * @see _Ext2LangId
 *
 * @categories Miscellaneous_Functions
 */
extern _str _Filename2LangId(_str filename, int options = 0);

/**
 * Searches the macros directory for a file.
 * 
 * @param name                name of file to look for
 * @param options             a string of zero or more of the following:
 * <dl>
 * <dt>'P'</dt><dd>Program search.  Does not effect UNIX.</dd>
 * <dt>'M'</dt><dd>Program search including search for .e and .ex Slick-
 * C batch macros.</dd>
 * <dt>'S'</dt><dd>Don't search in current directory.  Does not effect
 * UNIX.</dd> 
 * </dl>
 * 
 * @return _str               full path to file, relative to macros directory. 
 *                            Empty string if file is not found
 *
 * @categories File_Functions
 */
extern _str _macro_path_search(_str name, _str options = '');

extern void _SlickEditUtil_UpdateOptions();

/**
 * Format binary time <code>timeb</code> according to the 
 * <code>format</code> specification and return result. Use 
 * <code>_time('B')</code> to get a binary time. 
 *
 * <p>
 *
 * Uses the same conversion-specifiers as the operating system 
 * implementation of <code>strftime</code>.
 * 
 * @param format  Format specification.
 * @param timeb   Binary time string. null or '' uses current 
 *                time.
 * 
 * @return String result. "" on failure.
 *
 * @example 
 * <pre>
 * April 20, 2011 === "%B %e, %Y"
 * 2011-4-20 === "%Y-%m-%d"
 * 11:31 pm === %I:%M %p 
 * </pre>
 */
extern _str strftime(_str format, _str timeb=null);

/** 
 *  Flags that can be passed into beautify_buffer or
 *  beautify_buffer_selection.
 */
const BEAUT_FLAG_SNIPPET= 0x1  ;
const BEAUT_FLAG_TYPING=  0x2;
const BEAUT_FLAG_AUTOBRACKET=  0x4;
const BEAUT_FLAG_ALIAS=   0x8;
const BEAUT_FLAG_COMPLETION= 0x10;
const BEAUT_FLAG_NONE=    0x0;


/**
 * Flags for 
 * se.lang.api.LanguageSettings.getBeautifierExpansions 
 */
_metadata enum_flags BeautifierExpansions {
	BEAUT_EXPAND_SYNTAX,                  // Beautify syntax expansions.
	BEAUT_EXPAND_ON_EDIT,                 // Beautify as the user types.
	BEAUT_EXPAND_ALIAS,                   // Run the beautifier on language alias expansions.
	BEAUT_EXPAND_PASTE,                   // Beautify on paste or drag and drop.
   BEAUT_ON_TAB,                         // Tab beautifies as well as re-indents lines.
};
const BEAUT_EXPAND_DEFAULTS=    (BEAUT_EXPAND_SYNTAX|BEAUT_EXPAND_ALIAS);

_metadata enum AutoBracePlace {
   AUTOBRACE_PLACE_SAMELINE,
   AUTOBRACE_PLACE_NEXTLINE,
   AUTOBRACE_PLACE_AFTERBLANK,
};

int def_double_click_tab_action = 0;
int def_middle_click_tab_action = 0;

STRARRAY def_svc_browser_url_list;

_metadata enum TabClickActions {
   TBA_NONE,
   TBA_CLOSE,
   TBA_ZOOM,
   TBA_FLOAT,
   TBA_SPLIT_HORZ,
   TBA_SPLIT_VERT,
   TBA_ONE_WINDOW,
};

/**
 * Finds most recent modal dialog 
 *  
 * @return Retunws window id of most recent modal dialog. 
 *         Returns 0 if non exist.
 */
extern int _ModalDialog();

// QToolbar API
extern int _IsQToolbar(int);
extern void _QToolbarGetState(_str& state);
extern void _QToolbarSetState(_str state);
extern void _QToolbarRemoveAll();
extern void _QToolbarRemove(int);
extern void _QToolbarAdd(int,int);
extern void _QToolbarAddBreak(int);
extern void _QToolbarSetSpacing(int);
extern void _QToolbarSetUnifiedToolbar(int);
extern int _QToolbarGetUnifiedToolbar();
extern void _QToolbarSetDockable(int, int);
extern void _QToolbarSetFloating(int, int);
extern int  _QToolbarGetFloating(int);
extern void _QToolbarSetMovable(int, int);
extern int  _QToolbarGetMovable(int);
extern void _QToolbarUpdateSize(int);
extern enum DockingArea _QToolbarGetDockArea(int);

/**
 * Increments or decrements MacGiveKeyToSlickEdit option. 
 *  
 * When MacGiveKeyToSlickEdit is greater than 0, all keys are 
 * given to SlickEdit. 
 *  
 * @param push_pop   When true, MacGiveKeyToSlickEdit 
 *                   incremented. When false
 *                   MacGiveKeyToSlickEdit is decremented but it
 *                   is never decrement past 0.
 *  
 */
extern void _MacGiveKeyToSlickEdit(bool push_pop);

#if 1 /*__MACOSX__*/
extern void _MacGetMemoryInfo(long &totalMemKSize,long &freeKSize);
extern bool _MacFullScreenSupported();
#endif

extern void _ComboBoxSetDragDrop(int, int);
extern void _ComboBoxSetPlaceHolderText(int, _str);

/**
 * Set the message to be displayed on the splash screen 
 * to indicate progress as we are initializing the editor. 
 */
extern void _SplashScreenStatus(_str msg);
/**
 * Close the splash screen. 
 */
extern void _SplashScreenHide();

/**
 * Temporarily suspends undo 
 *  
 * <p>This function is used in conjuction with vsResumeUndo in 
 * order to perform temporary buffer modifications so that undo 
 * steps are not recorded for the temporary buffer 
 * modifications. As long as the buffer is 
 * restored to it's original state before vsSuspendUndo is 
 * called, no issues with undo will occur. 
 *  
 * @param wid   Window id of editor control.  0 specifies the
 * current object.
 * 
 * @return 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
extern int _SuspendUndo(int wid);
extern void _ResumeUndo(int wid,int maxundos);
/**
 * Add an undo push modify state to save the current modify 
 * state 
 *  
 * <p>Must call _UndoPopModify after calling this function. 
 *  
 * @param wid	Window id of editor control.  0 specifies the
 * current object.
 */
extern void _UndoPushModify(int wid);
/**
 * Add an undo pop modify state to restore the pushed undo 
 * modify current modify state 
 *  
 */
extern void _UndoPopModify(int wid);
/**
 * This is used for optimizing scrolling for Mac.  If gives a 
 * hint to the drawing engine as to what vertical scroll occured
 * on the screen. See scroll_up and scroll_down macros. 
 *  
 * @param count
 */
extern void _set_scroll_optimization(int count);
/**
 * When a Qt widget is hosted within a foreign system window, Qt 
 * drag drop can not be supported because Qt can't correctly 
 * locate the mouse. 
 *  
 * @return true if the editor control support Qt drag drop
 */
extern bool _EditorCtlSupportsDragDrop();

extern void _TextBrowserLoadFile(int wid, _str filename);
extern void _TextBrowserSetHtml(int wid, _str html);
extern void _TextBrowserPageOp(int wid, int op);
extern void _TextBrowserShrinkToFit(int minWidth=0, int minHeight=0);

/**
 * Finds MDI child document window within the current MDI window
 * 
 * @param wid    MDI child window id (editor wid)
 * @param option_letter
 *               One of the following:
 *               <dl compact>
 *               <dt><b>'L'</b> <dd>find document to left
 *               <dt><b>'R'</b> <dd>find document to right
 *               <dt><b>'A'</b> <dd>find document above
 *               <dt><b>'B'</b> <dd>find document below
 *               <dt><b>'N'</b> <dd>find next document (active or not)
 *               <dt><b>'n'</b> <dd>Same as 'N' but non circular
 *               <dt><b>'P'</b> <dd>find previous document (active or not)
 *               <dt><b>'p'</b> <dd>Same as 'P' but not circular
 *               <dt><b>"C"</b> <dd>find current document tab within tab group
 *               <dt><b>'1'</b> <dd>find next document within tab group
 *               <dt><b>'2'</b> <dd>find previous document within tab group
 *               <dt><b>'F'</b> <dd>find first document within tab group
 *               <dt><b>'Z'</b> <dd>find last document within tab group
 *               <dt><b>'G'</b> <dd>find next tab group
 *               <dt><b>'H'</b> <dd>find previous tab group
 *               <dt><b>'g'</b> <dd>Same as 'G' but not circular
 *               <dt><b>'h'</b> <dd>Same as 'H' but not circular
 *               </dl>
 * @param move_or_close
 *               True means window edge can be sized
 *               with active window
 * 
 * @return Non-zero window id
 */
extern int _MDINextDocumentWindow(int wid,_str option_letter,bool move_or_close);
/**
 * Change size of window
 * 
 * @param wid    MDI child window id (editor wid)
 * @param add    Pixels to add or remove
 * @param before  size edge before or after wid.
 * 
 * @return Returns amount size of tile was changed.
 */
extern int _MDIChangeDocumentWindowSize(int wid,int add,bool before);


struct MDIDocumentTabInfo {
   _str caption;
   int wid;
};
struct MDIDocumentTabGroupInfo {
   int nextGroup_wid;
   int prevGroup_wid;
   int NofTabs;
   int active_index;
   MDIDocumentTabInfo tabInfo[];
};

/**
 * Retrieve document tab group info for editor window 
 * <code>wid</code>. 
 *  
 * @param wid
 * @param info
 * @param option   One of the following:
 *    <dl compact>
 *    <dt><b>'B'</b> <dd>Basic group info. tabInfo array not filled in
 *    <dt><b>'A'</b> <dd>All info. Fill in tabInfo array
 *    </dl>
 */
extern void _MDIGetDocumentTabGroupInfo(int wid, MDIDocumentTabGroupInfo &info, _str option);  

/**
 * Move a document window to the same document group as another document window 
 *  
 * @param move_wid MDI child window id (editor wid) to move
 * @param to_wid   MDI child window id (editor wid) of destination document group
 */
extern void _MDIMoveToDocumentTabGroup(int move_wid,int to_wid);

/**
 * Return window id's of all mdi windows into 
 * <code>window_list</code>. Set <code>includeHidden=true</code> 
 * to include hidden mdi-windows. 
 *  
 * @param window_list 
 * @param includeHidden 
 */
extern void _MDIGetMDIWindowList(int (&array)[], bool includeHidden=false);
/**
 * Return window id most recent active MDI window
 *  
 *  
 * @return Return window id of most recent active MDI window
 */
extern int  _MDICurrent();
/**
 * Return window id most recent floating (non-main) active MDI 
 * window 
 *  
 * Note: This will not return floating tool window groups that 
 * do not have and MDI area.
 *  
 * @return Return window id of most recently floating (non-main)
 *         active MDI window. May return 0.
 */
extern int  _MDICurrentFloating();
/**
 * Return mdi window id most recently active MDI window<p>
 * 
 * @param wid Window of an MDI child window
 * 
 * @return Return window id of most recently active MDI window
 */
extern int  _MDIFromChild(int wid);
/**
 * Return current mdi child window id of the specified MDI 
 * window.
 *  
 * @param mdi_wid   Window of an MDI window 
 *  
 * @return Return current mdi child window id of the 
 * specified MDI window. 
 */
extern int _MDICurrentChild(int mdi_wid);

/**
 * Returns true if window is parented to an MDI window with a 
 * visible MDI area 
 *  
 * @param wid    valid window id of window that might be 
 *               parented to an MDI window
 * 
 * @return Returns true if window is parented to an MDI window 
 * with a visible MDI area 
 */
extern bool _MDIWindowHasMDIArea(int wid);
/**
 * @return	Returns an instance handle (window id) to the object, 
 *  
 * <i>object_name</i>.  Returns 0 if an instance is not found.  
 * Specify the 'N' option if you only want to find a non-edited 
 * instance of an object. Specify the 'E' option if you only 
 * want to find an edited instance of an object. Specify NULL if 
 * you want both edited and non-edited instances of an object.  
 *
 * @param mdi_wid       Window object found must be in this mdi 
 *                      window.
 * @param pszName       is a string in the format: form_name[.control_name]
 * @param pszOptions    "N" or "E", as described above
 *
 * @see _find_formobj
 * @see _find_object
 * @see _find_control
 *
 * @appliesTo	All_Window_Objects
 * @categories Form_Methods
 */
extern int _MDIFindFormObject(int mdi_wid,_str form_name, _str option);

/**
 * User properties are string values indexed by 
 * <code>name</code>. User properies are saved and restored by 
 * the MDI window <code>mdi_wid</code>. Set a user property 
 * value to null to remove it. If user property does not exist, 
 * then <code>value</code> is undefined. 
 * 
 * @param mdi_wid 
 * @param name 
 * @param value 
 * 
 * @return true if user property exists.
 */
extern bool _MDIGetUserProperty(int mdi_wid, _str name, _str& value);
extern void _MDISetUserProperty(int mdi_wid, _str name, _str value);

extern bool _FileRegexMatchName(_str wildcards,_str name);
extern bool _FileRegexMatchPath(_str wildcards,_str filename);
extern bool _FileRegexMatchExcludePath(_str wildcards, _str filename);

/**
 * Utility function for find buffer with matching p_modified_temp_name
 * 
 * @param modified_temp_name
 * 
 * @return If found, buffer_id is returned (>=0). Otherwise -1 is returned.
 */
extern int _FindModifiedTempName(_str modified_temp_name);

extern bool _MultiCursorNext(bool findFirst);
extern void _MultiCursorAdd();
extern bool _MultiCursor();
extern int _MultiCursorCount();
extern void _MultiCursorClearAll();
extern void _MultiCursorClearAllIfOtherBuffer();
extern bool _MultiCursorAlreadyLooping();
extern void _MultiCursorLoopDone();
//extern void _MultiCursorUpdate();
extern bool _MultiCursorLastLoopIteration();
extern bool _MultiCursorFirstLoopIteration();
extern bool _MultiCursorActiveLoopIteration();
extern void _MultiCursorMergeOverlap();
extern int _MultiCursorAddFromActiveSelection();
const MULTI_CURSOR_SUPPORTS_BLOCK_MARK= 0;

extern _str _parse_project_command_slickc(_str &additionalWordOptions,_str & additionalParenOptions,
                                          bool recurse,
                                          _str & workspace_filename,
                                          _str & command,_str & buf_name,_str & project_name,
                                          _str & cword,_str & argline,_str & ToolName,
                                          _str & ClassPath,
                                          int &handle,_str &config,_str &outputFile);
extern long _idle_time();
extern int _ConvertCol(int fromEncoding,int toEncoding,bool resultIsInBytes=false);

/**
 * Sets a pending show state for when a form becomes visible.
 *  
 * Typically used to set a form to maximized when it becomes 
 * visible. 
 * 
 * @param wid     Window id
 * @param state   'N','F','M'
 */
extern void _SetPendingWindowState(int wid,_str state);

/**
 * Delete the first instance of <B>string</B>.
 *  
 * @param string String to delete.
 * 
 * @return int 0 if successful, STRING_NOT_FOUND_RC  if 
 *         <B>string</B> is not found.
 */
extern int _ComboBoxDelete(_str string);

/**
 * Returns the line truncation for the current line, or line 
 * string if supplied, calling the custom truncation line length
 * callback if available. In order to properly support this 
 * callback, users should reference this function instead of 
 * p_TruncateLength, wherever necessary. 
 *  
 * @param line string (optional) 
 * @param nOfBytes number of bytes in line (optional) 
 *  
 * @return Returns the truncation line length.
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
extern int _TruncateLengthC(_str line=null, int nOfBytes=0);


extern _str _GuidNew();
/* 
   Returns OS default encoding which is either a non-zero code page or
   VSENCODING_UTF8.
*/
extern int _GetDefaultEncoding();
/* 
   Returns OS default non-Utf-8 code page.
*/
extern int _GetACP();
/**
 * Creates all non-existant directory for path 
 * specified.
 *  
 * @param path             Path to create directories for.
 * @param filePartPresent  Specify true if last part of path is 
 *                         filename (i.e file.cpp)..
 * @param permissions      Unix/Mac permissions.
 * 
 * @return 
 */
extern int _make_path(_str path,bool filePartPresent=false,int permissions=0755);

/**
 * Generate event bindings profile data from the given event 
 * table (kt_index). 
 *  
 * @param escapedPackage  Destination package
 * @param profileName     Destination profile
 * @param kt_index  Event table
 * 
 * @return  Returns 0 if successful.
 */
extern int _eventtab_set_profile(_str escapedPackage, _str profileName, int kt_index);
/**
 * Determines whether event table has been modified. 
 *  
 * @param keytab_index  Event table index into names table 
 * 
 * @return  Returns true if event table was modified.
 */
extern bool _eventtab_get_modify(int keytab_index);
/**
 * Sets the modify state for and event table. 
 *  
 * @param keytab_index  Event table index into names table 
 * @param modify
 */
extern void _eventtab_set_modify(int keytab_index, bool modify);
/**
 * Fetch .editorconfig property settings for the specified 
 * file. 
 *  
 * @param filename  Input only.
 * @param ecprops  Output only. 
 * @param langId. Input Only.
 */
extern void _EditorConfigGetProperties(_str filename, EDITOR_CONFIG_PROPERITIES &ecprops,_str langId,int support_flags);
/** 
 * Clears the editor config cache so new modifications can be 
 * read. 
 *  
 */
extern void _EditorConfigClearCache();
extern int _grep_file_list(int list_wid, long &NofFilesSearched, bool readFilesFromDisk, _str search_string, _str options, typeless callback, typeless &callback_args,typeless maybe_cancel_callback,int mfflags=0);
/**
 * Determines whether exiting the application should be ignored. 
 *  
 * <p>Note: When processEvents() in Qt is called, an attempt to 
 * close the application can't be ignored even when ignore user 
 * input is specified. Application must handle ignore a 
 * disallowed attempt to exit the application. 
 * 
 * @return bool Returns false when attempt to exit the 
 *         application should be ignored.
 */
extern bool _AllowExit();
/**
 * Determines the stream marker type used by spell checking 
 * while typing. 
 *  
 * @return Returns marker type handle used by spell checking 
 *         while typing.
 */
extern int _spellwt_get_marker_type();

/**
 * Translate font into valid OS font. 
 *  
 * @param fontName        (input/output) font name to 
 *                        translate.
 * @param pointSizex10    (input/output) font point size x 10
 * @param fontFlags       (input/output) font flags
 *  
 * @categories Miscellaneous_Functions
 */
extern void _xlat_font(_str &fontName, int &pointSizex10=0,int &fontFlags=0);

/**
 * Translate default font into valid OS font. 
 *  
 * @param fontIndex is one of the following constants defined in "slick.sh":
 * <UL>
 *    <LI>CFG_CMDLINE
 *    <LI>CFG_MESSAGE
 *    <LI>CFG_STATUS
 *    <LI>CFG_SBCS_DBCS_SOURCE_WINDOW
 *    <LI>CFG_HEX_SOURCE_WINDOW
 *    <LI>CFG_UNICODE_SOURCE_WINDOW
 *    <LI>CFG_FILE_MANAGER_WINDOW
 *    <LI>CFG_DIFF_EDITOR_WINDOW
 *    <LI>CFG_UNICODE_DIFF_EDITOR_WINDOW
 *    <LI>CFG_FUNCTION_HELP
 *    <LI>CFG_FUNCTION_HELP_FIXED
 *    <LI>CFG_MENU
 *    <LI>CFG_DIALOG
 *    <LI>CFG_MINIHTML_PROPORTIONAL
 *    <LI>CFG_MINIHTML_FIXED
 *    <LI>CFG_DOCUMENT_TABS
 * </UL>
 * @param fontName        (output) font name
 * @param pointSizex10    (output) font point size x 10
 * @param fontFlags       (output) font flags 
 * @param fontHeight      (output) font height in TWIPS (see {@link _dy2ly}). 
 *  
 * @see _default_font 
 * @see _xlat_font 
 * @categories Miscellaneous_Functions
 */
extern void _xlat_default_font(int fontIndex, _str &fontName, int &pointSizex10=0,int &fontFlags=0,int &fontHeight=0);

/**
 * Get branch model info for a Git repository
 *  
 * @param path Root path of Git repository
 * @param gitPath absolute path to Git executable
 * @param forceRun (int arg(3)) force the git graph to be 
 *                 refilled
 * @param specificBranch (_str arg(4)) only show graph current 
 *                       branch in repository
 * 
 * @return int 0 if succesful
 */
extern int _GitGetBranchInfo(_str path,_str gitPath,...);
/**
 * Stop any timers that the Git repository browser has running
 */
extern void _GitBranchClose();
/**
 * 
 * 
 * @author dhenry (7/22/2016)
 * 
 * @return int 
 */
extern int _GitClearBranchModelInfo();
/**
 * 
 * @return int Returns 1 if Git thread is still running.
 */
extern int _GitGettingInfo();

extern _str _GitGetBranchName(int branchIndex);
extern _str _GitGetBranchHash(int branchIndex);
extern _str _GitCurBranchEndHash();

struct GitCommitInfo {
   _str hash;
   _str parentHash;
   _str otherParents[];
   _str authorName;
   _str authorEmail;
   _str committerDate;
   _str dateTime;
   _str comment;
   _str longComment[];
   _str modifiedFiles[];
   _str stagedFiles[];
};
extern int _GitGetCommitInfo(_str gitPath,_str path,_str hash,GitCommitInfo &commitInfo);
extern int _GitGetDiffInfo(_str path,_str gitPath,_str (&diffInfo):[]:[][],_str hash);

struct AUTORESTORE_MONITOR_CONFIG {
   _str m_monitor_config;
   _str m_screen;
   _str m_mdistate;
   // GLOBAL window/monitor stuff. 
   // old _srg_debug_window2, _srg_toolbars5
   // <CR>'s removed.
   _str m_global_mon_info:[];  
   // layouts, <CR>'s removed.
   _str m_project_mon_info:[];
};

/**
 * 
 * @param job_name      Gives the thread job a name. Can help 
 *                      debug thread issues.
 * @param thread_name   Indicates the thread that should be 
 *                      started. Currently only
 *                      "plgman_downloader" is supported.
 * @param thread_arg    Arguments depend on thread started.
 * 
 * @return 
 */
extern int _job_start(_str job_name,_str thread_name, typeless &thread_arg);
/**
 * 
 * @param job_handle   Handle of job created by _job_start
 * @param millitimeout  Specifies how long to wait for thread to 
 *                      finish. If thread is still running,
 *                      attempts to cancel thread.
 * 
 * @return Returns 0 and closes job_handle if job isn't running 
 *         any more. Possible error codes are CMRC_TIMEOUT or
 *         INVALID_ARGUMENT_RC
 */
extern int _job_close(int job_handle, int millitimeout=-1);
/**
 * 
 * @param job_handle   Handle of job created by _job_start
 * @param progress_info    Returned info depends on 
 *                         thread_name. Set to null if
 *                         job_handle isn't valid or this call
 *                         isn't supported by this thread.
 */
extern void _job_get_progress(int job_handle, typeless &progress_info);
/**
 * Determines if a thread job is still running. 
 *  
 * @param job_handle   Handle of job created by _job_start
 * 
 * @return Returns true if job handle is valid and the thread is 
 *         still running. Otherwise, false is returned.
 */
extern bool _job_is_running(int job_handle);

/**
 * Initialize spell checking while typing. 
 *  
 * @param enabled   Turn spell checking while typing on/off.
 * @param elements  Elements to spell check. Ignored for 
 *                  XML/HTML/BBC.
 */
extern void _spell_check_while_typing_init(bool enabled, _str elements);

extern void _SeparateWildcardPath(_str filename, _str& path, _str& wildcard);

const TREE_CUSTOM_DELEGATE_GIT_BRANCHES= 1;

/** 
 * @deprecated 
 * A universally deprecated constant used to indicate that an integer #define is deprecated.
 */
const VSDeprecatedZeroConstant = 0;
/**
 * Preprocessing macro to use in a #define to indicate that the macro is deprecated.
 */
#define VSDEPRECATECONSTANT(n) (n+VSDeprecatedZeroConstant)


extern void _VPJAddTree(_str projectFile, _str tree, int handle, int wid, int listwid, int folderNode, int customFolders, _str (&newFilesAdded)[]);
extern void _VPJUpdateCustomFolders(int handle, int filesNode, int filterExtensions, int addFolders);
extern void _VPJExpandWildcards(int handle, _str workspaceFile, _str projectFile);
extern void _VPJRefilterWildcards(int handle);
extern void _VPJGetWildcards(int handle, int (&wildcardNodes)[]);
extern int _VPJHasWildcards(int handle);

struct _ScreenInfo {
   int x;
   int y;
   int width;
   int height;
   int actual_width;
   int actual_height;
};
extern void _GetAllScreens(_ScreenInfo (&list)[]);
/**
 * Indicates whether the minimap slider is currently being dragged.
 *  
 * @param wid     Window id
 */
extern bool _MinimapInScroll(int wid);
/**
 *  Checks buffer for inconsistent line endings.
 * 
 * @return _str Returns '' if line endings are consistent. 
 *         Otherwise, a comma delimited string with the most
 *         common line ending found first is returned (see
 *         examples).
 *  
 * @example
 * <pre>
 *    CRLF(10), LF(1)
 *    LF(1200), CR(2)
 * </pre>
 * @appliesTo Edit_Window, Editor_Control 
 * 
 * @see _CorrectLineEndings
 *
 * @categories  Edit_Window_Methods, Editor_Control_Methods
 */
extern _str _CheckLineEndings();

extern void filewatcher_stop_async_work();

/* This function is reserved for SlickEdit interanal use */
extern int _file_open(_str pszFilename,int option);
/* This function is reserved for SlickEdit interanal use */
extern int _file_close(int fh);
extern void _ResetModifiedLineFlags();


/**
 * Delete cached information for the given name entry.  Currently, this only 
 * operates on PICTURE types by deleting the cached image bitmap information. 
 * This is necessary when switching themes, so that we can reload the correct 
 * image without having to entirely reload the icon. 
 * 
 * @param picture_index    name index
 * 
 * @categories Names_Table_Functions
 */
extern void _delete_picture_cache_data(int picture_index);
/** 
 * Determines the default theme for this OS. 
 *  
 * <p>Currently only useful for macOS.
 * 
 * @return _str Returns one of SlickEdit's supported themes
 */
extern _str _GetAppThemeForOS();
/** 
 * Determines the default color profile for this OS. 
 *  
 * <p>Currently only useful for macOS.
 * 
 * @return _str Returns one of SlickEdit's supported themes
 */
extern _str _GetColorProfileForOS();

/** 
 * Returns the concurrent process idname for the current 
 * buffer. null is returned if the current buffer 
 * does not have a concurrent process running in it.
 *  
 * <p>Currently only usefule for macOS.
 * 
 * @return _str Returns one of SlickEdit's supported themes
 */
extern _str _ConcurProcessName();
/**
 * 
 * 
 * @author cmaurer (5/13/20)
 * 
 * @param markid   -1 for default selection. Otherwise, must be 
 *                 valid markid.
 * @param flags       VSMARKFLAG_*
 * @param EOLChars    Null for platform specific newline chars 
 *                    between lines. 
 * @return _str     Returns selected text. Returns null if no 
 *         text is selected or invalid markid.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
extern _str _GetSelectedText(int markid=-1, int flags=-1, _str EOLChars=null);
/**
 * MarkerType used by interactive tool window to indicate 
 * leading text that should not be color coded. 
 * 
 * @return int  Returns marker type (_MarkerTypeAlloc())
 */
extern int _InteractiveOutputMarkerType();
/**
 * Returns number of Utf-8 characters in range specified. 
 * 
 * <p>Note that no save characters are counted. 
 * 
 * @param start_offset Start seek position in editor buffer.
 * @param end_offset   End seek position in editor buffer. 
 *  
 * @return seSeekPosRet Returns number of Utf-8 characters in 
 *         range specified.
 * 
 * @appliesTo Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods, Selection_Functions
 */
long _UTF8CountCharsInRange(long start_offset, long end_offset);
/**
 *  Try to get read/write access to the file config-multi-access.
 *  
 *  <p>This has no effect unless config sharing is turned on.
 *  (def_exit_flags & EXIT_CONFIG_ALWAYS_SHARE_CONFIG).
 */
extern void _ConfigUpdateShareMode();

#endif
