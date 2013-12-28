////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50561 $
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


// IF we are running old macro compiler to convert Visual SlickEdit
//    macro to Slick-C.
#if __VERSION__<1.8
   #include "slick24.sh"
#else

#define KEEP 0
#define KEEP2 0

#define MAXINT       (0x7fffffff)

#define VSCFGFILE_USER_BOX "ubox.ini"
#define VSCFGFILE_USER_COLORSCHEMES "uscheme.ini"
#define VSCFGFILE_USER_VCS  'uservc.slk'
#define VSCFGFILE_USER_PRJTEMPLATES 'usrprjtemplates.vpt'
#define VSCFGFILE_COLORSCHEMES "vsscheme.ini"
#define VSCFGFILE_PRJTEMPLATES 'prjtemplates.vpt'
#define VSCFGFILE_OEMTEMPLATES 'oem.vpt'
#define VSCFGFILE_SYS_EXTPROJECTS 'sysproject.vpe'
#if __UNIX__
   #define VSCFGFILE_USER_FTP "uftp.ini"
   #define VSCFGFILE_PRJPACKS 'uprjpack.slk'
   #define VSCFGFILE_USER_EXTPROJECTS 'uproject.vpe'
#else
   #define VSCFGFILE_USER_FTP "ftp.ini"
   #define VSCFGFILE_PRJPACKS 'prjpacks.slk'
   #define VSCFGFILE_USER_EXTPROJECTS 'project.vpe'
#endif
#define VSCFGFILE_USER_PRINTSCHEMES "uprint.ini"
#define VSCFGFILE_USER_BEAUTIFIER "uformat.ini"
#define FORMAT_INI_FILENAME      "format.ini"

#define VSCFGFILE_ALIASES "alias.als.xml"

//#define SLICK_HELP_MAINPAGE  "VSE9Help.htm"
#define SLICK_HELP_MAINPAGE  "index.htm"

   /* some machine dependant constants. */
#if __UNIX__
   #define FILESEP "/"              /* Primary filename,directory separator */
   #define FILESEP2 "\\"              /* Secondary filename,directory separator */
   #define PATHSEP ":"
   #define EXTENSION_EXE ""
   #define EXTENSION_BATCH ""
   #define COMMANDSEP ";"
#else
   #define FILESEP "\\"              /* Primary filename,directory separator */
   #define FILESEP2  "/"              /* Secondary filename,directory separator */
   #define PATHSEP ";"
   #define EXTENSION_EXE ".exe"
   #define EXTENSION_BATCH ".cmd"
   #define COMMANDSEP "&"
#endif
   #define ARGSEP "-"
   #define EXE_FILE_RE "*":+EXTENSION_EXE;

#if __PCDOS__
   #define ALLFILES_RE  '*.*'
   #define _NAME_HAS_DRIVE 1
   #define DLLEXT '.dll'
#else
    #define ALLFILES_RE  '*'
    #define _NAME_HAS_DRIVE 0
    #define DLLEXT '.dll'
#endif
#define VSNULLSEEK      0x7fffffff

#if __MACOSX__
#define VSREGISTEREDTM  "(R)"
#else
#define VSREGISTEREDTM  "\x{00AE}"
#endif

#if __PCDOS__
#define VSREGISTEREDTM_TITLEBAR  "\x{00AE}"
#else
#define VSREGISTEREDTM_TITLEBAR  "(R)"
#endif

#define VSMAX_SETOLDLINENUMS_BUF_SIZE 10000000
#define _MAX_HSCROLL_POS 32000
#define _SLICKBIN "VSLICKBIN"
#define _SLICKMISC "VSLICKMISC"
#define _SLICKMACROS "VSLICKMACROS"
#define _SLICKPATH "VSLICKPATH"
#define _SLICKRESTORE "VSLICKRESTORE"
#define _SLICKEDITCONFIG "SLICKEDITCONFIG"
#define _VSECLIPSECONFIG "VSECLIPSECONFIG"
#define _VSECLIPSECONFIGVERSION "VSECLIPSECONFIGVERSION"
#define _SLICKCONFIG "SLICKEDITCONFIGVERSION"
#define _SLICKLOAD "VSLICKLOAD"
#define _SLICKSAVE "VSLICKSAVE"
#define _SLICKTAGS "VSLICKTAGS"
#define _SLICKREFS "VSLICKREFS"
#define _SLICKALIAS "VSLICKALIAS"
#define _MDIMENU "_mdi_menu"
#define USERMACS_FILE 'vusrmacs'       /* File to contain all user recorded macros. */
#define USERMODS_FILE 'vusrmods'       /* File which loads user macro modules. */
#define KEYTAB_MAXASCII  129
#define KEYTAB_MAXEXT    446
/* number of definable keys in a key table. */
#define _WINDOW_CONFIG_FILE "vrestore.slk"
#define _INI_FILE "vslick.ini"
#define BSC_FILE_EXT '.bsc'
#define REF_FILE_EXT '.vtr'
#define TAG_FILE_EXT '.vtg'
#define PRJ_TAG_FILE_EXT '.vtg'
#define PRJ_FILE_EXT '.vpj'
#define PRJ_FILE_BACKUP_EXT ".bakvpj"
#define WORKSPACE_FILE_EXT '.vpw'
#define WORKSPACE_FILE_BACKUP_EXT ".bakvpw"
#define ECLIPSE_WORKSPACE_FILE_EXT '.vpwecl'
#if __UNIX__
   #define WORKSPACE_STATE_FILE_EXT '.vpwhistu'
#else
   #define WORKSPACE_STATE_FILE_EXT '.vpwhist'
#endif

// Xcode projects are "workspaces"
#define XCODE_PROJECT_EXT '.pbxproj'
#define XCODE_PROJECT_SHORT_BUNDLE_EXT '.xcode'
#define XCODE_PROJECT_LONG_BUNDLE_EXT '.xcodeproj'
#define XCODE_LEGACY_VENDOR_NAME 'apple xcode'
#define XCODE_PROJECT_VENDOR_NAME 'xcode project'
    
#define XCODE_WKSPACE_BUNDLE_EXT '.xcworkspace'
#define XCODE_WKSPACE_VENDOR_NAME 'xcode workspace'

#define VCPP_PROJECT_FILE_EXT '.dsp'
#define VCPP_PROJECT_WORKSPACE_EXT '.dsw'

#define VISUAL_STUDIO_SOLUTION_EXT '.sln'

#define VISUAL_STUDIO_VB_PROJECT_EXT '.vbproj'
#define VISUAL_STUDIO_VCPP_PROJECT_EXT '.vcproj'
#define VISUAL_STUDIO_VCX_PROJECT_EXT '.vcxproj'
#define VISUAL_STUDIO_CSHARP_PROJECT_EXT '.csproj'
#define VISUAL_STUDIO_CSHARP_DEVICE_PROJECT_EXT '.csdproj'
#define VISUAL_STUDIO_VB_DEVICE_PROJECT_EXT '.vbdproj'
#define VISUAL_STUDIO_JSHARP_PROJECT_EXT '.vjsproj'
#define VISUAL_STUDIO_TEMPLATE_PROJECT_EXT '.etp'
#define VISUAL_STUDIO_DATABASE_PROJECT_EXT '.dbp'
#define VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT '.icproj'
#define VISUAL_STUDIO_FSHARP_PROJECT_EXT '.fsproj'
//#define VISUAL_STUDIO_UNITY_PROJECT_EXT '.unityproj'

#define VCPP_EMBEDDED_PROJECT_FILE_EXT '.vcp'
#define VCPP_EMBEDDED_PROJECT_WORKSPACE_EXT '.vcw'
#define VCPP_VENDOR_NAME 'microsoft visual c++'
#define VISUAL_STUDIO_VENDOR_NAME 'microsoft visual studio'
#define VISUAL_STUDIO_VCPP_VENDOR_NAME 'microsoft visual studio visual c++'
#define VISUAL_STUDIO_CSHARP_VENDOR_NAME 'microsoft visual studio csharp'
#define VISUAL_STUDIO_VB_VENDOR_NAME 'microsoft visual studio visual basic'
#define VISUAL_STUDIO_CSHARP_DEVICE_VENDOR_NAME 'microsoft visual studio csharp device'
#define VISUAL_STUDIO_VB_DEVICE_VENDOR_NAME 'microsoft visual studio visual basic device'
#define VISUAL_STUDIO_JSHARP_VENDOR_NAME 'microsoft visual studio jsharp'
#define VISUAL_STUDIO_FSHARP_VENDOR_NAME 'microsoft visual studio fsharp'
#define VISUAL_STUDIO_TEMPLATE_NAME 'microsoft visual studio enterprise template'
#define VISUAL_STUDIO_DATABASE_NAME 'microsoft visual studio database'
//#define VISUAL_STUDIO_UNITY_VENDOR_NAME 'microsoft visual studio unity'
#define VISUAL_STUDIO_MSBUILD_VENDOR_NAME 'microsoft visual studio msbuild'
#define ECLIPSE_VENDOR_NAME 'eclipse'
#define VCPP_EMBEDDED_VENDOR_NAME 'microsoft embedded visual tools'
#define TORNADO_WORKSPACE_EXT '.wsp'
#define TORNADO_PROJECT_EXT '.wpj'
#define TORNADO_VENDOR_NAME 'wind river tornado'
#define BORLANDCPP_VENDOR_NAME 'borland c++'
#define JBUILDER_PROJECT_EXT '.jpx'
#define JBUILDER_VENDOR_NAME 'borland jbuilder'
#define ANT_BUILD_FILE_EXT '.xml'
#define MAVEN_BUILD_FILE_EXT '.xml'
#define MAVEN_BUILD_FILE_NAME 'pom.xml'
#define NANT_BUILD_FILE_EXT '.build'
#define MACROMEDIA_FLASH_PROJECT_EXT '.flp'
#define MACROMEDIA_FLASH_VENDOR_NAME 'macromedia flash'

#define OS2SLICK_HELP_FILE   "ovslick.hlp"  // Default OS/2 help file

#define COMPILER_NAME_VS2              "Visual Studio 2"
#define COMPILER_NAME_VS4              "Visual Studio 4"
#define COMPILER_NAME_VS5              "Visual Studio 5"
#define COMPILER_NAME_VS6              "Visual Studio 6"
#define COMPILER_NAME_VSDOTNET         "Visual Studio .NET"
#define COMPILER_NAME_VS2003           "Visual Studio 2003"
#define COMPILER_NAME_VS2005           "Visual Studio 2005"
#define COMPILER_NAME_VS2005_EXPRESS   "Visual Studio 2005 Express"
#define COMPILER_NAME_VS2008           "Visual Studio 2008"
#define COMPILER_NAME_VS2008_EXPRESS   "Visual Studio 2008 Express"
#define COMPILER_NAME_VS2010           "Visual Studio 2010"
#define COMPILER_NAME_VS2010_EXPRESS   "Visual Studio 2010 Express"
#define COMPILER_NAME_VS2012           "Visual Studio 2012"
#define COMPILER_NAME_VS2012_EXPRESS   "Visual Studio 2012 Express"
#define COMPILER_NAME_VCPP_TOOLKIT2003 "Visual C++ Toolkit 2003"
#define COMPILER_NAME_PLATFORM_SDK2003 "Microsoft Platform SDK"
#define COMPILER_NAME_DDK              "Windows DDK"
#define COMPILER_NAME_BORLAND          "Borland C++"
#define COMPILER_NAME_BORLAND6         "Borland C++ Builder"
#define COMPILER_NAME_BORLANDX         "Borland C++ BuilderX"
#define COMPILER_NAME_CYGWIN           "Cygwin"
#define COMPILER_NAME_LCC              "LCC"
#define COMPILER_NAME_GCC              "GCC"
#define COMPILER_NAME_CC               "CC"
#define COMPILER_NAME_SUNCC            "Sun C++"
#define COMPILER_NAME_CL               "CL"
#define COMPILER_NAME_USR_INCLUDES     "Unix Includes"
#define COMPILER_NAME_LATEST           "Latest Version"
#define COMPILER_NAME_DEFAULT          "Default Compiler"

#define COMPILER_NAME_JBUILDER         "Borland JBuilder"
#define COMPILER_NAME_NETSCAPE         "Netscape"
#define COMPILER_NAME_SUPERCEDE        "SuperCede"
#define COMPILER_NAME_VISUALCAFE       "Visual Cafe"
#define COMPILER_NAME_JPP              "Microsoft Java VM"
#define COMPILER_NAME_IBM              "IBM Java Developer Kit"
#define COMPILER_NAME_SUN              "JDK"

/**
 * Assert that "cond" is true, otherwise create Slick-C(R) stack 
 * error and report file name and line number of error. 
 */
#define ASSERT(cond) _assert(cond, '"'#cond'" in file '__FILE__' on line '__LINE__)

struct available_compilers {
   boolean hasVC6;
   boolean hasDotNET;
   boolean hasDotNet2003;
   boolean hasDotNet2005;
   boolean hasDotNet2005Express;
   boolean hasDotNet2008;
   boolean hasDotNet2008Express;
   boolean hasDotNet2010;
   boolean hasDotNet2010Express;
   boolean hasDotNet2012;
   boolean hasDotNet2012Express;
   boolean hasToolkit;
   boolean hasPlatformSDK;
   boolean hasBorland;
   _str latestMS;
   _str latestGCC;
   _str latestCygwin;
   _str latestCC;
   _str latestLCC;
   _str latestDDK;
   _str latestBorland;
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

#define S390OPTENVVAR "VSLICK390OPT"
#define OS390NAMEPREFIX "OS/390"

#if __UNIX__
   #define DATASET_MOUNT_NAME "/DATASETS"
   #define DATASET_MOUNT_NAMESL "/DATASETS/"
   #define DATASET_MOUNT_NAMEONLY "DATASETS"
   #define DATASET_ROOT '//'
#else
   #define DATASET_ROOT '1:\'
#endif

   // vusrs13.0.0.0e
   #define USERSYSO_FILE_SUFFIX 'h'

#if __PCDOS__
   // non-UNIX platforms
   #define SLICK_TAGS_FILE   "tags.slk"
   #define SLICK_TAGS_DB     "tags.vtg"
   #define SLICK_HELP_FILE   "vslick.chm"  // Default Windows help file
   #define SLICK_HELPLIST_FILE   "vslick.lst"  // Help list file
   #define SLICK_HELPINDEX_FILE   "vslickindex.xml"  // Help index file
   #define _MDI_INTERFACE 1
   #define USERDEFS_FILE "vusrdefs"
   #define USEROBJS_FILE "vusrobjs"
   #define SYSOBJS_FILE "sysobjs"
   #define STATE_FILENAME "vslick.sta"
   #define SYSCPP_FILE    "syscpp.h"
   #define USERCPP_FILE   "usercpp.h"
   #define _MULTI_USER 1

   // Windows user config data path relative to %APPDATA%
   #define WIN_CONFIG_DIRNAME "My Visual SlickEdit Config"
#else
   // UNIX options
   #define SLICK_TAGS_FILE   "utags.slk"
   #define SLICK_TAGS_DB     "utags.vtg"
   #define SLICK_HELP_FILE   "WebHelp/index.htm"  // Default help file
   #define SLICK_HELPLIST_FILE   "uvslick.lst"  // Help list file
   #define SLICK_HELPINDEX_FILE   "vslickindex.xml"  // Help index file
   #define _MDI_INTERFACE 1
   #define USERDEFS_FILE "vunxdefs"
   #define USEROBJS_FILE "vunxobjs"
   //#define SYSOBJS_FILE "usysobjs"
   #define SYSOBJS_FILE "sysobjs" // Same forms as Windows... Yeah!!! -Tan
   #define STATE_FILENAME "vslick.stu"
   #define SYSCPP_FILE    "usyscpp.h"
   #define USERCPP_FILE   "unxcpp.h"
   #define _MULTI_USER 1
#endif

#define MAX_LINE 0x7fffffff
#define HEX_CHARSPERCOL 4

#define SYSTEM_LEXER_FILENAME  'vslick.vlx'
#define USER_LEXER_FILENAME 'user.vlx'
#define OEM_LEXER_FILENAME 'oem.vlx'
#define DEBUGGER_CONFIG_FILENAME 'debugger.xml'
#define COMPILER_CONFIG_FILENAME 'compilers.xml'
#define LEXER_FILE_LIST get_env('VSROOT'):+SYSTEM_LEXER_FILENAME:+PATHSEP:+get_env('VSROOT'):+OEM_LEXER_FILENAME:+PATHSEP:+usercfg_path_search(USER_LEXER_FILENAME)
/* Meaning of rc flags passed to internal commands (DEFC)*/
#define PAUSE_COMMAND  4               /* Command should wait for key press */

/* buffer flags for p_buf_flags property. */
#define VSBUFFLAG_HIDDEN               0x1  /* NEXT_BUFFER won't switch to this buffer */
#define VSBUFFLAG_THROW_AWAY_CHANGES   0x2  /* Allow quit without prompting on modified buffer */
#define VSBUFFLAG_KEEP_ON_QUIT         0x4  /* Don't delete buffer on QUIT.  */
#define VSBUFFLAG_REVERT_ON_THROW_AWAY 0x10
#define VSBUFFLAG_PROMPT_REPLACE       0x20
#define VSBUFFLAG_DELETE_BUFFER_ON_CLOSE 0x40  // Indicates whether a list box/edit window buffer
                                               // should be deleted when the dialog is closed
#define VSBUFFLAG_FTP_UPLOAD_IN_PROGRESS 0x80   /* Specifies that buffer is currently being uploaded via FTP*/
#define VSBUFFLAG_FTP_BINARY             0x100  /* Specifies that the FTP buffer should be transferred binary by default */


#define HIDE_BUFFER         VSBUFFLAG_HIDDEN
#define THROW_AWAY_CHANGES  VSBUFFLAG_THROW_AWAY_CHANGES
#define KEEP_ON_QUIT        VSBUFFLAG_KEEP_ON_QUIT
#define REVERT_ON_THROW_AWAY      VSBUFFLAG_REVERT_ON_THROW_AWAY
#define PROMPT_REPLACE_BFLAG      VSBUFFLAG_PROMPT_REPLACE
#define DELETE_BUFFER_ON_CLOSE    VSBUFFLAG_DELETE_BUFFER_ON_CLOSE



/* p_color_flags property. */
/* These color flags indicate what coloring should be applied. */
enum_flags ColorFlags {
   LANGUAGE_COLOR_FLAG,    
   MODIFY_COLOR_FLAG,      
   CLINE_COLOR_FLAG,      
};

// _clex_find flags
#define OTHER_CLEXFLAG        0x1
//ERROR_CLEXFLAG     =  0x2
#define KEYWORD_CLEXFLAG      0x4
#define NUMBER_CLEXFLAG       0x8
#define STRING_CLEXFLAG       0x10
#define COMMENT_CLEXFLAG      0x20
#define PPKEYWORD_CLEXFLAG    0x40
#define LINENUM_CLEXFLAG      0x80
#define SYMBOL1_CLEXFLAG      0x100    // punctuation
#define SYMBOL2_CLEXFLAG      0x200    // library functions
#define SYMBOL3_CLEXFLAG      0x400    // operators
#define SYMBOL4_CLEXFLAG      0x800    // other user defined
#define FUNCTION_CLEXFLAG     0x1000
#define NOSAVE_CLEXFLAG      0x2000
#define PARAMETER_CLEXFLAG    0x4000
// NOSAVE lines are treated like comments to
// simplify macro programming.
//#define NOSAVE_CLEXFLAG       0x2000



#define DIR_SIZE_COL      2
#define DIR_SIZE_WIDTH    10
#define DIR_DATE_COL      14
#define DIR_DATE_WIDTH    10
#define DIR_TIME_COL      26
#define DIR_TIME_WIDTH    (6+2*_dbcs())
#define DIR_ATTR_COL      (33+2*_dbcs())
#if __PCDOS__
   #define DIR_ATTR_WIDTH    5
   #define DIR_FILE_COL      (40+2*_dbcs())
#elif __UNIX__
   #define DIR_ATTR_WIDTH    10
   #define DIR_FILE_COL      (45+2*_dbcs())
#endif


/* Each entry in the names symbol table has a type. */
/* The type flags values are below. */
#define PROC_TYPE      0x1
#define VAR_TYPE       0x4
#define EVENTTAB_TYPE  0x8
#define COMMAND_TYPE   0x10
#define GVAR_TYPE      0x20
#define GPROC_TYPE     0x40
#define MODULE_TYPE    0x80
#define PICTURE_TYPE   0x100
#define BUFFER_TYPE    0x200
#define OBJECT_TYPE    0x400
#define OBJECT_MASK    0xf800
#define OBJECT_SHIFT   11
#define INFO_TYPE      0x10000
#define DLLCALL_TYPE   0x40000   /* Entries with this flag MUST also have the
                                    COMMAND_TYPE or PROC_TYPE flag. */
#define DLLMODULE_TYPE 0x80000
#define ENUM_TYPE      0x400000
#define ACLASS_TYPE    0x800000
#define INTERFACE_TYPE 0x1000000
#define CONST_TYPE     0x4000000
#define MISC_TYPE      0x20000000
#define IGNORECASE_TYPE  0x80000000


#define HELP_TYPES   ("proc="PROC_TYPE         " ""picture="PICTURE_TYPE       :+" ":+\
          "bufvar="BUFFER_TYPE     :+" ":+\
          "command="COMMAND_TYPE   " ""misc="MISC_TYPE         :+" ":+\
          "any=-1")

#define HELP_CLASSES  ("window=1 search=2 cursor=4 mark=8 misc=16 name=32":+" ":+\
           "string=64 display=128 keyboard=256 buffer=512"    :+" ":+\
           "file=1024 menu=2048 help=4096 cmdline=8192" :+" ":+\
           "language=16384 mouse=32768 any=-1")

#define PCB_TYPES ("command="COMMAND_TYPE:+" ":+"proc="PROC_TYPE)

/* view id of the internal command retrieve file ".command" */
#define RETRIEVE_VIEW_ID    VSWID_RETRIEVE
/* buf  id of the internal command retrieve file ".command" */
#define RETRIEVE_BUF_ID     0
/* View id activated before loading a system file */
/* into the hidden window for system files like .command, .kill, etc. */
#define HIDDEN_VIEW_ID      HIDDEN_WINDOW_ID
#define HIDDEN_WINDOW_ID    VSWID_HIDDEN
// Constant window handles
#define _desktop            1
#define _app                2
#define _mdi                3
#define _cmdline            4
#define VSWID_HIDDEN        5
#define VSWID_STATUS        6
#define VSWID_RETRIEVE      7

#define TERMINATE_MATCH    1  /* Old convention _file_ */
#define FILE_CASE_MATCH    2  /* _complete=_fposcase */
#define NO_SORT_MATCH      4  /* ns_ */
#define REMOVE_DUPS_MATCH  8  /* __ */
#define AUTO_DIR_MATCH     16
#define ONE_ARG_MATCH      32  // Command or completion supports one argument
                       // with spaces.
#define EXACT_CASE_MATCH   64
#define SMALLSORT_MATCH    128
#define EMACS_BUF_MATCH    256 /* Flag to make select_buffer capable of listing matches with '<>' chars in line */

#define MORE_ARG       "*"      /* Indicate more arguments. */
                        /* '!' indicates last argument. */
#define WORD_ARG       "w"      /* Match what was typed. */
                        /* Look for any file. */
#define NONE_ARG       ""
#define FILE_ARG       ("f:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
#define FILE_MAYBE_LIST_BINARIES_ARG       ("a:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|REMOVE_DUPS_MATCH))
#define FILENOAUTODIR_ARG       ("f:"(FILE_CASE_MATCH))
#define FILENOQUOTES_ARG   ("fnq:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH))
#define SEMICOLON_FILES_ARG   ("semicolonfiles:"(FILE_CASE_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH))
#define PROJECT_FILE_ARG   ("project_file:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
#define WORKSPACE_FILE_ARG ("wkspace_file:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|REMOVE_DUPS_MATCH))
#define DIR_ARG       ("dir:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
#define DIRNEW_ARG    ("dirnew:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH))
#define DIRNOQUOTES_ARG   ("dirnq:"(FILE_CASE_MATCH|AUTO_DIR_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH))
#define MULTI_FILE_ARG (FILE_ARG'*')
#define FILENEW_ARG   ("filenew:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
#define BUFFER_ARG     ("b:"FILE_CASE_MATCH)
#define EMACS_BUFFER_ARG ("b:"FILE_CASE_MATCH|EMACS_BUF_MATCH)
#define COMMAND_ARG    ("c:"(EXACT_CASE_MATCH|REMOVE_DUPS_MATCH))
#define PICTURE_ARG    "_pic"
#define FORM_ARG       ("_form:"EXACT_CASE_MATCH)
#define OBJECT_ARG     ("_object:"EXACT_CASE_MATCH)
#define OPTIONS_SEARCH_ARG     ("options:"NO_SORT_MATCH)
#define MODULE_ARG     "m"
#define DLLMODULE_ARG  '_dll'
              // look for procedure or command.
#define PC_ARG         ("pc:"EXACT_CASE_MATCH)
                   /* look Slick-C tag cmd,proc,form */
#define SLICKC_FILE_ARG ("scfile:"(FILE_CASE_MATCH|AUTO_DIR_MATCH))
#define MACROTAG_ARG   ("mt:"(REMOVE_DUPS_MATCH|TERMINATE_MATCH))
#define MACRO_ARG      ('k:'EXACT_CASE_MATCH)   // User recorded macro
#define DIFF_COMMANDS_ARG ('diff_command:'EXACT_CASE_MATCH)
#define PCB_TYPE       (COMMAND_TYPE|PROC_TYPE)
#define PCB_TYPE_ARG   "pcbt"   /* list proc,command, and built-in types. */
#define VAR_ARG        ("v:"EXACT_CASE_MATCH) /* look for variable. Global vars not included.*/
#define ENV_ARG        "e"      /* look for environment variables. */
#define MENU_ARG       ("_menu:"EXACT_CASE_MATCH)
#define MODENAME_ARG   ("mode:"EXACT_CASE_MATCH)
#define BOOKMARK_ARG   ("bookmark:"EXACT_CASE_MATCH)
#define HELP_ARG       ("h:"(TERMINATE_MATCH|ONE_ARG_MATCH|NO_SORT_MATCH))
                        /* command,macro,built-in,language */
                        /* the '-' means that duplicates are removed. */
#define HELP_TYPE       (COMMAND_TYPE|PROC_TYPE|MISC_TYPE)
#define HELP_TYPE_ARG  "ht"
#define HELP_CLASS_ARG "hc"
#define COLOR_FIELD_ARG "cf"
/* Match tagged procedure. */
#define TAG_ARG ("tag:"(REMOVE_DUPS_MATCH|SMALLSORT_MATCH|TERMINATE_MATCH))
#define CLASSNAME_ARG ("class:"(REMOVE_DUPS_MATCH|SMALLSORT_MATCH|TERMINATE_MATCH))

/******************************OLD ARG2 FLAGS******************************/
#define NCW_ARG2      0    // Ignored. Here for backward compatibility.
                           // Previously: Command allowed when there are no MDI child windows.
#define ICON_ARG2     0x2  // Command allowed when editor control window is iconized
                           // Not necessary if command does not require
                           // an editor control
#define CMDLINE_ARG2  0x4  // Command supports the command line.

#define MARK_ARG2     0x8  // ON_SELECT psuedo event should pass control on
                           // to this command and not deselect text first.
#define READ_ONLY_ARG2   0x10 // Command is allowed in read-only mode
                              // Not necessary if command does not require
                              // an editor control
#define QUOTE_ARG2    0x40   // Indicates that this command must be quoted when
                             // called during macro recording.  Needed only if
                             // command name is an invalid identifier or
                             // keyword.
#define LASTKEY_ARG2  0x80   // Command requires last_event value to be set
                             // when called during macro recording.
#define MACRO_ARG2  0x100    // This is a recorded macro command. Used for completion.
#define HELP_ARG2      0     // Ignored. Here for backward compatibility.
#define HELPSALL_ARG2  0     // Ignored. Here for backward compatibility.
#define TEXT_BOX_ARG2  0x800 // Command supports any text box control.
#define NOEXIT_SCROLL_ARG2 0x1000 // Do not exit scroll caused by using scroll bars.
#define EDITORCTL_ARG2 0x2000     // Command supports non-mdi editor control
#define NOUNDOS_ARG2   0x4000   // Do not automatically call _undo('s').
                                // Require macro to call _undo('s') to
                                // start a new level of undo.
#define REQUIRESMDI_ARG2 0x8000  // Command requires mdi interface may be because
                                 // it opens a new file or uses _mdi object.
/********************************************************************/


/******************************NEW ARG2 FLAGS******************************/

/*
   NOTE:

   VSARG2_MARK,VSARG2_NOEXIT_SCROLL,
   VSARG2_READ_ONLY, VSARG2_ICON are now
   ignored if the command does not require an
   editor control.

       VSARG2_REQUIRES_EDITORCTL
                or
       VSARG2_REQUIRES_MDI_EDITORCTL

   This is different than versions <= 3.0
*/
#define VSARG2_NCW      0      // Ignored. Here for backward compatibility.
                               // Previously: Command allowed when there are no MDI child windows.
#define VSARG2_CMDLINE  0x4    // Command supports the command line.
                               // VSARG2_CMDLINE allows a fundamental mode
                               // key binding to be inherited by the command line
#define VSARG2_MARK     0x8    // ON_SELECT event should pass control on
                               // to this command and not deselect text first.
                               // Ignored if command does not require an editor control
#define VSARG2_LINEHEX   0x20  // Do not reset p_hex_nibble and p_hex_field
#define VSARG2_QUOTE     0x40  // Indicates that this command must be quoted when
                               // called during macro recording.  Needed only if
                               // command name is an invalid identifier or
                               // keyword.
#define VSARG2_LASTKEY  0x80   // Command requires last_event value to be set
                               // when called during macro recording.
#define VSARG2_MACRO     0x100      // This is a recorded macro command. Used for completion.
#define VSARG2_HELP      0          // Ignored. Here for backward compatibility.
#define VSARG2_HELPSALL  0          // Ignored. Here for backward compatibility.
#define VSARG2_TEXT_BOX  0x800      // Command supports any text box control.
                                    // VSARG2_TEXT_BOX allows a fundamental mode
                                    // key binding to be inherited by a text box
#define VSARG2_NOEXIT_SCROLL 0x1000 // Do not exit scroll caused by using scroll bars.
                                    // Ignored if command does not require an editor control
#define VSARG2_EDITORCTL   0x2000   // Command allowed in editor control.
                                    // VSARG2_EDITORCTL allows a fundamental mode
                                    // key binding to be inherited by a non-MDI editor control
#define VSARG2_NOUNDOS     0x4000   // Do not automatically call _undo('s').
                                    // Require macro to call _undo('s') to
                                    // start a new level of undo.
// Command allowed when editor control is in strict read only mode
// Ignored if command does not require an editor control
#define VSARG2_READ_ONLY   0x10
// Command allowed when editor control window is iconized
// Ignored if command does not require an editor control
#define VSARG2_ICON        0x2


// Command requires any editor control
#define VSARG2_REQUIRES_EDITORCTL       (VSARG2_REQUIRES_MDI_EDITORCTL|EDITORCTL_ARG2)
#define VSARG2_REQUIRES_MDI_EDITORCTL   0x00010000 // Command requires mdi editor control


#define VSARG2_REQUIRES_AB_SELECTION    0x00020000 // Command requires selection in active buffer
#define VSARG2_REQUIRES_BLOCK_SELECTION 0x00040000 // Command requires block/column selection in any buffer
#define VSARG2_REQUIRES_CLIPBOARD       0x00080000 // Command requires editorctl clipboard
#define VSARG2_REQUIRES_FILEMAN_MODE    0x00100000 // Command requires active buffer to be in fileman mode
#define VSARG2_REQUIRES_TAGGING         0x00200000 // Command requires vs_[ext]_list_tags or ext_proc_search
#define VSARG2_REQUIRES_UNICODE_BUFFER  0x00400000 // Command requires p_utf8==true

#define VSARG2_REQUIRES_SELECTION       0x00800000 // Command requires a selection in any buffer
#define VSARG2_REQUIRES_MDI             0x00008000 // Command requires mdi interface may be because
                                                   // it opens a new file or uses _mdi object.
#define VSARG2_ONLY_BIND_MODALLY        0x01000000
#define VSARG2_REQUIRES_PROJECT_SUPPORT 0x02000000 // Command requires project support
#define VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW  0x04000000  // Command requires min/max/restore/iconize window support
#define VSARG2_REQUIRES_TILED_WINDOWING    0x08000000            // Command requires tiled windowing
#define VSARG2_REQUIRES_GUIBUILDER_SUPPORT 0x10000000            // Command requires gui builder support

#define VSARG2_EXECUTE_FROM_MENU_ONLY      0x80000000  // This command can only be executed from a menu.
                                                       // This flag is in a way redundant since you can get the same
                                                       // effect with more control by writing an _OnUpdate.  However, it
                                                       // takes much less time to just add this attribute to a command.


#define VSARG2_REQUIRES  (VSARG2_REQUIRES_TAGGING|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_AB_SELECTION|VSARG2_REQUIRES_BLOCK_SELECTION|VSARG2_REQUIRES_CLIPBOARD|VSARG2_REQUIRES_FILEMAN_MODE|VSARG2_REQUIRES_SELECTION|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW|VSARG2_REQUIRES_TILED_WINDOWING|VSARG2_REQUIRES_GUIBUILDER_SUPPORT)

// auto-restore flags
enum_flags AutoRestoreFlags {
   RF_CLIPBOARDS = 0x1,
   RF_CWD = 0x2,
   RF_PROCESS = 0x4,
   RF_PROJECTFILES = 0x8,
   RF_LINEMODIFY = 0x10,
   RF_NOSELDISP = 0x20,
   RF_CBROWSER_TREE = 0x40,
   RF_WORKSPACE = 0x80,
};

// line number flags
enum_flags LineNumbersFlags {
   LNF_ON,
   LNF_AUTOMATIC,
};

// Horizontal scrolling gets faster over time
#define DEF_CHG_COUNT 10
#define DEF_DEC_DELAY_BY 0
/* DEF_MIN_DELAY=0 */
#define DEF_INC_MAX_SKIP_BY  2
#define DEF_MAX_SKIP  5

/* Fast line scrolling gets faster over time*/
#define DEF_FS_MAX_SKIP 4
#define DEF_FS_INC_MAX_SKIP_BY  2
#define DEF_FS_CHG_COUNT 5

#define INITIAL_LANGUAGE_MARGINS "1 254"   /* initial language margins before */
                                       /* default is set. */
// p_window_flags constants
#define HIDE_WINDOW_OVERLAP 0x1 // Indicates window is hidden window used
                   // for storing system views and buffers.
#define OVERRIDE_CURLINE_RECT_WFLAG 0x4
#define CURLINE_RECT_WFLAG 0x8
#define OVERRIDE_CURLINE_COLOR_WFLAG 0x10
#define CURLINE_COLOR_WFLAG 0x20

// New p_window_flags constants
#define VSWFLAG_HIDDEN                    0x1
#define VSWFLAG_ON_CREATE_ALREADY_CALLED  0x2
#define VSWFLAG_OVERRIDE_CURLINE_RECT     0x4
#define VSWFLAG_CURLINE_RECT              0x8
#define VSWFLAG_OVERRIDE_CURLINE_COLOR    0x10
#define VSWFLAG_CURLINE_COLOR             0x20
#define VSWFLAG_REGISTERED                0x40
#define VSWFLAG_ON_RESIZE_ALREADY_CALLED  0x80
#define VSWFLAG_NOLCREADWRITE             0x100

/* flags for p_word_wrap_style property */
enum_flags WordWrapStyle {
   STRIP_SPACES_WWS  = 0x1,
   WORD_WRAP_WWS     = 0x2,
   JUSTIFY_WWS       = 0x4,
   ONE_SPACE_WWS     = 0x8,
};

/* Old search flags */
#define IGNORECASE_SEARCH           0x1
#define MARK_SEARCH                 0x2
#define POSITIONONLASTCHAR_SEARCH   0x4
#define REVERSE_SEARCH              0x8
#define RE_SEARCH                  0x10
#define WORD_SEARCH                0x20
#define UNIXRE_SEARCH              0x40
#define NO_MESSAGE_SEARCH          0x80
#define GO_SEARCH                 0x100
#define INCREMENTAL_SEARCH        0x200
#define WRAP_SEARCH               0x400
#define HIDDEN_TEXT_SEARCH        0x800
#define SCROLL_STYLE_SEARCH       0x1000
#define BINARYDBCS_SEARCH         0x2000
#define BRIEFRE_SEARCH            0x4000
#define PRESERVE_CASE_SEARCH      0x8000
#define PROMPT_WRAP_SEARCH      0x400000

/* New search ranges */
#define VSSEARCHRANGE_CURRENT_BUFFER      0
#define VSSEARCHRANGE_CURRENT_SELECTION   1
#define VSSEARCHRANGE_CURRENT_PROC        2
#define VSSEARCHRANGE_ALL_BUFFERS         3

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
#define MF_CHECKED         1
#define MF_UNCHECKED       2
#define MF_GRAYED          4
#define MF_ENABLED         8
#define MF_SUBMENU         16
#define MF_DELETED         64

/* Draw modes.  Windows Rastore Ops.  SetROP2 */
#define DM_NOT             6    /* Invert what is drawn over. */


//#define CFG_PAST_END_OF_LINE   -1
enum CFGColorConstants {
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
   CFG_UNKNOWNXMLELEMENT       = 33,
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
   CFG_FLOATING_NUMBER         = 56,
   CFG_HEX_NUMBER              = 57,
   CFG_SINGLEQUOTED_STRING     = 58,
   CFG_BACKQUOTED_STRING       = 59,
   CFG_UNTERMINATED_STRING     = 60,
   CFG_INACTIVE_CODE           = 61,
   CFG_INACTIVE_KEYWORD        = 62,
   CFG_IMAGINARY_SPACE         = 63,
   CFG_INACTIVE_COMMENT        = 64,
   CFG_MODIFIED_ITEM           = 65,
   CFG_NAVHINT                 = 66,
   CFG_XML_CHARACTER_REF       = 67,
   CFG_SEARCH_RESULT_TRUNCATED = 68,
   CFG_MARKDOWN_HEADER         = 69,
   CFG_MARKDOWN_CODE           = 70,
   CFG_MARKDOWN_BLOCKQUOTE     = 71,
   CFG_MARKDOWN_LINK           = 72,

   CFG_DOCUMENT_TAB_ACTIVE     = 73,
   CFG_DOCUMENT_TAB_SELECTED   = 74,
   CFG_DOCUMENT_TAB_UNSELECTED = 75,

   // last color ID
   CFG_LAST_COLOR_PLUS_ONE,
   CFG_LAST_DEFAULT_COLOR      = (CFG_LAST_COLOR_PLUS_ONE-1)

   // Legacy constants
   ,CFG_MODIFIED_FILE_TAB       = CFG_DOCUMENT_TAB_MODIFIED
};

// Some configurable fonts that dont have color
#define CFG_MENU                (-1)
#define CFG_DIALOG              (-2)
#define CFG_MDICHILDICON        (-3)
#define CFG_MDICHILDTITLE       (-4)
#define CFG_HEX_SOURCE_WINDOW          (-5)
#define CFG_UNICODE_SOURCE_WINDOW      (-6)
#define CFG_FILE_MANAGER_WINDOW        (-7)
#define CFG_DIFF_EDITOR_WINDOW         (-8)
#define CFG_MINIHTML_PROPORTIONAL      (-9)
#define CFG_MINIHTML_FIXED             (-10)
#define CFG_DOCUMENT_TABS              (-11)

// largest color

#define OI_FIRST             OI_MDI_FORM
#define OI_MDI_FORM          1
#define OI_FORM              2
#define OI_TEXT_BOX          3
#define OI_CHECK_BOX         4
#define OI_COMMAND_BUTTON    5
#define OI_RADIO_BUTTON      6
#define OI_FRAME             7
#define OI_LABEL             8
#define OI_LIST_BOX          9
#define OI_HSCROLL_BAR       10
#define OI_VSCROLL_BAR       11
#define OI_COMBO_BOX         12
#define OI_HTHELP            13
#define OI_PICTURE_BOX       14
#define OI_IMAGE             15
#define OI_GAUGE             16
#define OI_SPIN              17
#define OI_MENU              18
#define OI_MENU_ITEM         19
#define OI_TREE_VIEW         20
#define OI_SSTAB             21
#define OI_DESKTOP           22
#define OI_SSTAB_CONTAINER   23
#define OI_EDITOR            24
#define OI_MINIHTML          25
#define OI_SWITCH            26
#define OI_TEXTBROWSER       27
#define OI_LAST              OI_TEXTBROWSER

#define CW_MAX_BUTTON      0x1  // Not yet supported
#define CW_MIN_BUTTON      0x2  // Not yet supported
#define CW_NO_CONTROL_BOX  0x4  // Not yet supported
#define CW_HIDDEN          0x8
#define CW_MINIMIZED       0x10 // Not yet supported.
#define CW_MAXIMIZED       0x20 // Not yet supported.
#define CW_CHILD           0x40
#define CW_PARENT          0x80
/*                   =0x100 */
#define CW_RIGHT_JUSTIFY   0x200
#define CW_LEFT_JUSTIFY    0x400
#define CW_CENTER_JUSTIFY  0x800  // Not yet suported
#define CW_BSDEFAULT       0x1000
#define CW_EDIT            0x2000
#define CW_COMBO_LIST_ALWAYS  0x4000
#define CW_COMBO_NOEDIT    0x8000
#define CW_CLIP_CONTROLS   0x40000

/* Property border styles. p_border_style */
#define BDS_NONE           0
#define BDS_FIXED_SINGLE   1
#define BDS_SIZABLE        2
#define BDS_DIALOG_BOX     3   /* FIXED_DOUBLE */
#define BDS_FIXED_DOUBLE   3   /* Same as DIALOG BOX */
#define BDS_SUNKEN         4
#define BDS_SUNKEN_LESS    5
#define BDS_ROUNDED        6

/* Gauge styles. p_style */
#define PSGA_HORZ_WITH_PERCENT  0
#define PSGA_VERT_WITH_PERCENT  1
#define PSGA_HORIZONTAL         2
#define PSGA_VERTICAL           3
#define PSGA_HORZ_ACTIVITY      4
#define PSGA_VERT_ACTIVITY      5

/* Picture styles. p_style. */
#define PSPIC_DEFAULT           0
#define PSPIC_PUSH_BUTTON       1
#define PSPIC_PARTIAL_BUTTON    PSPIC_PUSH_BUTTON  /* Renamed to PS_PIC_PUSH_BUTTON for clarity */
#define PSPIC_AUTO_BUTTON       2
#define PSPIC_AUTO_CHECK        3
/*
    PSPIC_BUTTON is used to create an efficient button (no system window) with
    a caption.
    It is also used to create an image control with a picture that
    does not have a border. This is a way to have toolbar bitmap that has
    two states but only requires a bitmap containing one state.
*/
#define PSPIC_BUTTON            4
#define PSPIC_SPLIT_PUSH_BUTTON 5  /* A PushButton that is split with button-part on the left, and drop-down arrow on right, separated by a divider. */
#define PSPIC_SPLIT_BUTTON      6  /* A ToolButton that is split with button-part on the left, and drop-down arrow on right, separated by a divider. */
// Some addition image control style
#define PSPIC_SIZEVERT          7
#define PSPIC_SIZEHORZ          8
#define PSPIC_GRABBARVERT       9
#define PSPIC_GRABBARHORZ       10
#define PSPIC_TOOLBAR_DIVIDER_VERT 11
#define PSPIC_TOOLBAR_DIVIDER_HORZ 12
#define PSPIC_FLAT_BUTTON          13
#define PSPIC_HIGHLIGHTED_BUTTON   14
#define PSPIC_FLAT_MONO_BUTTON     15
//#define PSPIC_DEFAULT_TRANSPARENT  16  /* Obsolete. If you want transparency, then create an image with transparency. */

/* additional fill styles */
#define PSPIC_FILL_GRADIENT_HORIZONTAL 17
#define PSPIC_FILL_GRADIENT_VERTICAL   18
#define PSPIC_FILL_GRADIENT_DIAGONAL   19

#define PSPIC_SPLIT_HIGHLIGHTED_BUTTON   20  /* A ToolButton that is flat, highlighted on mouse-over, split with button-part on the left, and drop-down arrow on right, separated by a divider. */

// Image control orientation styles
#define PSPIC_OHORIZONTAL  0
#define PSPIC_OVERTICAL    1

/* Scroll bar style. p_scroll_bars */
#define SB_NONE         0
#define SB_HORIZONTAL   1
#define SB_VERTICAL     2
#define SB_BOTH         3

/* Validate styles. p_validate_style. Effects text box and combo box. */
#define VS_NONE     0
#define VS_INTEGER  1

/* Init styles. p_init_style. Effects form. */
#define IS_NONE        0x0
#define IS_SAVE_XY     0x1
#define IS_REINIT      0x2
#define IS_HIDEONDEL   0x4

/* p_indent_style. p_init_style.. */
enum VSIndentStyle {
   INDENT_NONE       = 0,
   INDENT_AUTO       = 1,
   INDENT_SMART      = 2,
};

/* max click style. p_max_click */
#define MC_SINGLE   0
#define MC_DOUBLE   1
#define MC_TRIPLE   2

/* Multi select style. p_multi_select */
#define MS_NONE          0
#define MS_SIMPLE_LIST   1
#define MS_EXTENDED      2
#define MS_EDIT_WINDOW   3

/* Spin control states. p_value */
#define SPIN_STATE_NORMAL  0x00
#define SPIN_STATE_UP      0x01
#define SPIN_STATE_DOWN    0x02
#define SPIN_STATE_HOT     0x04

//
// Mouse pointers (p_mouse_pointer)
//

// Built-in
#define MP_DEFAULT    0
#define MP_ARROW      (-1)
#define MP_CROSS      (-2)
#define MP_IBEAM      (-3)
#define MP_ICON       (-4)
#define MP_SIZE       (-5)
#define MP_SIZENESW   (-6)
#define MP_SIZENS     (-7)
#define MP_SIZENWSE   (-8)
#define MP_SIZEWE     (-9)
#define MP_UP_ARROW   (-10)
#define MP_HOUR_GLASS (-11)
#define MP_BUSY       (-12)
#define MP_SIZEHORZ   (-13)
#define MP_SIZEVERT   (-14)
#define MP_HAND       (-15)
#define MP_NODROP     (-16)
#define MP_SPLITVERT  (-17)
#define MP_SPLITHORZ  (-18)

#define MP_LISTBOXBUTTONSIZE     (-118)
#define MP_ALLOWCOPY             (-119)
#define MP_ALLOWDROP             (-120)
#define MP_LEFTARROW_DROP_TOP    (-121)
#define MP_LEFTARROW_DROP_BOTTOM (-122)
#define MP_LEFTARROW_DROP_RIGHT  (-123)
#define MP_LEFTARROW_DROP_LEFT   (-124)
#define MP_LEFTARROW             (-125)
#define MP_RIGHTARROW            (-126)
#define MP_MOVETEXT              (-127)
#define MP_MAX       (MP_MOVETEXT)
// Custom cursor (e.g. user set picture index).
// It is illegal for the user to set this value.
#define MP_CUSTOM    -128

/* Alignment styles. */
#define AL_MASK            3     // left,right,center mask
#define AL_LEFT            0
#define AL_RIGHT           1
#define AL_CENTER          2
#define AL_VCENTER         4
#define AL_VCENTERRIGHT    5
#define AL_CENTERBOTH      6
#define AL_BOTTOM         8
#define AL_BOTTOMRIGHT    9
#define AL_BOTTOMCENTER   10

/* Check box style. p_style. */
#define PSCH_AUTO2STATE   0
#define PSCH_AUTO3STATEA  1    /* Gray, check, uncheck. */
#define PSCH_AUTO3STATEB  2    /* Gray, uncheck, check */
/* Combo box style. p_style. */
#define PSCBO_EDIT         0    /* Standard.  List drops down. */
#define PSCBO_LIST_ALWAYS  1    /* List is always present. Can edit. */
#define PSCBO_NOEDIT       2    /* Must select list item to modify text box. */

/* SSTab style */
#define PSSSTAB_DEFAULT        0
#define PSSSTAB_DOCUMENT_TABS  1  /* Mac only. Draw tabs using a document-style. Used by File Tabs tool-window. */

/* Scale modes.  Setting the scale mode not support. */
//SM_USER    = 0
#define SM_TWIP      1
#define SM_PIXEL     3

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


#define IDOK                0x00000400
#define IDSAVE              0x00000800
#define IDSAVEALL           0x00001000
#define IDOPEN              0x00002000
#define IDYES               0x00004000
#define IDYESTOALL          0x00008000
#define IDNO                0x00010000
#define IDNOTOALL           0x00020000
#define IDABORT             0x00040000
#define IDRETRY             0x00080000
#define IDIGNORE            0x00100000
#define IDCLOSE             0x00200000
#define IDCANCEL            0x00400000
#define IDDISCARD           0x00800000
#define IDHELP              0x01000000
#define IDAPPLY             0x02000000
#define IDRESET             0x04000000
#define IDRESTOREDEFAULTS   0x08000000

#define MB_ICONMASK         0xF0000000

#define MB_OK               IDOK
#define MB_OKCANCEL         (IDOK|IDCANCEL)
#define MB_ABORTRETRYIGNORE (IDABORT|IDRETRY|IDIGNORE)
#define MB_SAVEDISCARD      (IDSAVE|IDDISCARD)
#define MB_SAVEDISCARDCANCEL (IDSAVE|IDDISCARD|IDCANCEL)
#define MB_APPLYDISCARDCANCEL (IDAPPLY|IDDISCARD|IDCANCEL)
#define MB_YESNOCANCEL      (IDYES|IDNO|IDCANCEL)
#define MB_YESNO            (IDYES|IDNO)
#define MB_RETRYCANCEL      (IDRETRY|IDCANCEL)
#define MB_ICONHAND         0x10000000
#define MB_ICONQUESTION     0x20000000
#define MB_ICONEXCLAMATION  0x40000000
#define MB_ICONINFORMATION  0x80000000
#define MB_ICONSTOP         MB_ICONHAND
#define MB_ICONNONE         MB_ICONMASK
#define MB_ICONDEFAULT      MB_ICONEXCLAMATION
//#define MB_DEFBUTTON1       0x00000000   Use new _message_box parameter
//#define MB_DEFBUTTON2       0x00000100   Use new _message_box parameter
//#define MB_DEFBUTTON3       0x00000200   Use new _message_box parameter

//#define MB_SYSTEMMODAL      0x00001000   /* Not supported on UNIX or OS/2*/
//MB_MODAL           =0x00002000  // MB_TASKMODAL
//MB_MODELESS        =MB_MODEMASK

// used by auto-reload dialog
#define IDDIFFFILE 8

/* p_draw_style */
#define PSDS_FIRST            PSDS_SOLID
#define PSDS_SOLID            0
#define PSDS_DASH             1
#define PSDS_DOT              2
#define PSDS_DASHDOT          3  // May only be supported on MS Windows
#define PSDS_DASHDOTDOT       4  // May only be supported on MS Windows
#define PSDS_NULL             5  // May only be supported on MS Windows
#define PSDS_INSIDE_SOLID     6
#define PSDS_LAST             PSDS_INSIDE_SOLID

/* p_draw_mode */
#define PSDM_FIRST            PSDM_BLACK
#define PSDM_BLACK            1
#define PSDM_NOTMERGEPEN      2
#define PSDM_MASKNOTPEN       3
#define PSDM_NOTCOPYPEN       4
#define PSDM_MASKPENNOT       5
#define PSDM_NOT              6
#define PSDM_XORPEN           7
#define PSDM_NOTMASKPEN       8
#define PSDM_MASKPEN          9
#define PSDM_NOTXORPEN        10
#define PSDM_NOP              11
#define PSDM_MERGENOTPEN      12
#define PSDM_COPYPEN          13
#define PSDM_MERGEPENNOT      14
#define PSDM_MERGEPEN         15
#define PSDM_WHITE            16
#define PSDM_LAST             PSDM_WHITE

/* p_fill_style */
#define PSFS_FIRST            PSFS_SOLID
#define PSFS_SOLID            0
#define PSFS_TRANSPARENT      1
#define PSFS_LAST             PSFS_TRANSPARENT

#define _HANDLE_WIDTH  75    /* twips width of dialog editor handle. */
#define _HANDLE_HEIGHT 75    /* twips height of dialog editor handle. */

/* Names dialog editor tool bar bitmap files with .bmp extension. */
#define DE_ARROW '_sarrow'
#define DE_LABEL '_labelb'
#define DE_TEXT_BOX '_textbox'
#define DE_EDIT_WINDOW '_editwin'
#define DE_FRAME '_frameb'
#define DE_COMMAND_BUTTON '_cmdbtn'
#define DE_RADIO_BUTTON '_radbtn'
#define DE_CHECK_BOX '_checkbx'
#define DE_COMBO_BOX '_combobx'
#define DE_LIST_BOX '_listbox'
#define DE_VSCROLL_BAR '_vscroll'
#define DE_HSCROLL_BAR '_hscroll'
#define DE_DRIVE_LIST '_drvlist'
#define DE_FILE_LIST '_fillist'
#define DE_DIRECTORY_LIST '_dirlist'
#define DE_PICTURE_BOX '_picture'
#define DE_NONE '.'
#define DE_IMAGE '_imageb'
#define DE_GAUGE '_gaugeb'
#define DE_SPIN '_spinb'
#define DE_TREE_VIEW '_tree'
#define DE_SSTAB '_sstabb'
#define DE_SSTAB_CONTAINER '_sstabb_container'
#define DE_MINIHTML '_minihtm'
#define DE_SWITCH '_switchb'

/*#define DEBITMAP_LIST (\
    DE_ARROW'='0' ':+\
    DE_NONE'='0' ':+\*/
#define DEBITMAP_LIST (\
    DE_ARROW'='0' ':+\
    DE_MINIHTML'='OI_MINIHTML' ':+\
    DE_LABEL'='OI_LABEL' ':+\
    DE_SPIN'='OI_SPIN' ':+\
    DE_TEXT_BOX'='OI_TEXT_BOX' ':+\
    DE_EDIT_WINDOW'='OI_EDITOR' ':+\
    DE_FRAME'='OI_FRAME' ':+\
    DE_COMMAND_BUTTON'='OI_COMMAND_BUTTON' ':+\
    DE_RADIO_BUTTON'='OI_RADIO_BUTTON' ':+\
    DE_CHECK_BOX'='OI_CHECK_BOX' ':+\
    DE_COMBO_BOX'='OI_COMBO_BOX' ':+\
    DE_LIST_BOX'='OI_LIST_BOX' ':+\
    DE_VSCROLL_BAR'='OI_VSCROLL_BAR' ':+\
    DE_HSCROLL_BAR'='OI_HSCROLL_BAR' ':+\
    DE_DRIVE_LIST'='OI_COMBO_BOX' ':+\
    DE_FILE_LIST'='OI_LIST_BOX' ':+\
    DE_DIRECTORY_LIST'='OI_TREE_VIEW' ':+\
    DE_PICTURE_BOX'='OI_PICTURE_BOX' ':+\
    DE_GAUGE'='OI_GAUGE' ':+\
    DE_IMAGE'='OI_IMAGE' ':+\
    DE_SSTAB'='OI_SSTAB' ':+\
    DE_TREE_VIEW'='OI_TREE_VIEW' ':+\
    DE_SWITCH'='OI_SWITCH)

#define LB_PICTURE_RE '(^?+\: *)'
//#define LB_RE '(^? *)'
#define LB_RE '^?'

#define VSCF_VSTEXTINFO   "SlickEdit Text"
#define VSCF_VSCONTROLS   "SlickEdit Controls"
#define VSCF_TEXT         "text/plain"
#define VSCF_UNICODETEXT  "text/plain"

#define DRIVE_NOROOTDIR  1
#define DRIVE_REMOVABLE  2
#define DRIVE_FIXED      3
#define DRIVE_REMOTE     4
#define DRIVE_CDROM      5
#define DRIVE_RAMDISK    6

//  Arguments to Combo Box ON_CHANGE event.
// These events are generated by macros and are
// not hard wired into the editor
#define CHANGE_OTHER 0         // Text box value changed.
#define CHANGE_CLINE 1         // Text box value changed by
                    // changing selected line in list.
#define CHANGE_CLINE_NOTVIS 2  // Text box value changed by
                    // changing selected line while
                    // list is invisible
#define CHANGE_CLINE_NOTVIS2 3 // Text box value changed by
                    // changing selected line while
                    // list is invisible. Sent to user level 2
                    // inheritance only.

#define CHANGE_BUTTON_PRESS         4 //Treeview with buttons on it

#define CHANGE_BUTTON_SIZE          5 //Treeview with buttons on it
/**
 * @deprecated Use CHANGE_BUTTON_SIZE for immediate changes, to save column 
 *             widths use another on_change event.
 */
#define CHANGE_BUTTON_SIZE_RELEASE  6 
#define CHANGE_HIGHLIGHT            7 // line was highlighted in 
                                      //combo box or list box


//  Arguments to List Box ON_CHANGE event.
#define CHANGE_SELECTED 10     // User's selection has changed
#define CHANGE_PATH 11         // Path was changed in a directory
                    // list box
#define CHANGE_FILENAME 12      // filename was changed in file
                    // list box
#define CHANGE_DRIVE 13         // Drive changed in drive combo box

#define CHANGE_EXPANDED 14      // A tree node was expanded
#define CHANGE_COLLAPSED 15     // A tree node was collapsed
#define CHANGE_LEAF_ENTER 16    // User pressed enter on leafs tree node
                                // If you want ENTER for nodes and leaves,
                                // define your own ENTER key.

                                // For CHANGE_EXPANDED and CHANGE_COLLAPSED
                                // the on_change function may return a new index
                                // to be activated.  If you do not want to do
                                // this, return -1
#define CHANGE_SCROLL 17
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
#define CHANGE_EDIT_OPEN  20    // A textbox is about to be opened
#define CHANGE_EDIT_CLOSE 21    // A textbox is about to close
#define CHANGE_EDIT_QUERY 22    // Query whether a textbox can be opened
#define CHANGE_EDIT_OPEN_COMPLETE  23    // A textbox is open
#define CHANGE_EDIT_PROPERTY       24
#define CHANGE_NODE_BUTTON_PRESS   25
#define CHANGE_CHECK_TOGGLED       26
#define CHANGE_SWITCH_TOGGLED      27
#define CHANGE_SCROLL_MARKER_CLICKED 28
#define TREE_EDIT_COLUMN_BIT         (0x40000000)



// Arguments to Spin ON_CHANGE event
#define CHANGE_NEW_FOCUS 20     // Called before ON_SPIN_UP and ON_SPIN_DOWN
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

#define CHANGE_CLICKED_ON_HTML_LINK  32

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
#define CHANGE_AUTO_SHOW 34

// CHANGE_FLAGS is sent to a tree control when node flags are changed in 
// _TreeSetInfo
#define CHANGE_FLAGS     35

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


// Arguments to Combo Box ON_DROP_DOWN event.
// These events are generated by macros and are
// not hard wired into the editor
#define DROP_UP    0     // After combo list box is made invisible
#define DROP_DOWN  1     // Before combo list box is made visible
#define DROP_INIT  2     // Before retrieve next/previous.  Used to initialize
              // the list box before is used.
#define DROP_UP_SELECTED 3     // Mouse release while on valid
                    // selection in list box
                    // and list is visible

// boolean value (deprecated, use 'true' instead)
#define TRUE 1
// boolean value (deprecated, use 'false' instead)
#define FALSE 0

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
#define OFN_ALLOWMULTISELECT  0x1  // Allow multiple file selection
                                   // When set, user must process
#define OFN_FILEMUSTEXIST     0x2  // File(s) selected must exist
#define OFN_CHANGEDIR         0x4  // Ignored for backward compatibility

#define OFN_NOOVERWRITEPROMPT 0x8  // Don't prompt user with overwrite exisiting dialog. */
#define OFN_SAVEAS            0x10 // File list box does not select files and
                                   // user is prompted whether to overwrite an
                                   // existing file.
#define OFN_DELAYFILELIST     0x20 // Display dialog box before displaying
                                   // list.
#define OFN_NODELWINDOW       0x40 // Open file dialog is not deleted
                                   // when user selects cancel. Instead
                                   // window is made invisible.
#define OFN_READONLY          0x80 // Show read only button. Can't be used
                                   // with OFN_READONLY
                                   // See OFN_PREFIXFLAGS flag
#define OFN_KEEPOLDFILE       0x100 // Show keep old name button
                                    // See OFN_PREFIXFLAGS flag
#define OFN_PREFIXFLAGS       0x200 // Prefix result with -r if
                                    // OFN_READONLY flag given and -n if
                                    // OFN_KEEPOLDFILE flag given and -a if
                                    // OFN_APPEND given.
#define OFN_SAVEAS_FORMAT     0x400
#define OFN_SET_LAST_WILDCARDS 0x800
#if 0
      #define OFN_KEEPDIR           0x400 // Show keep dir check box
#endif
#define OFN_NOCHANGEDIR        0x1000  // Dont' show Change dir check box

#define OFN_APPEND            0x2000 // Show append button.
#define OFN_NODATASETS        0x4000 // OS390 ONLY. Don't allow datasets
#define OFN_ADD_TO_PROJECT    0x8000 // Add saved file to project
#define OFN_EDIT			     	0x10000  // Use as an open dialog, rather than a save

#define EDC_OUTPUTINI       0x1
#define EDC_OUTPUTSTRING    0x2
//EDC_OUTPUTBUFFER =0x4
//EDC_OUTPUTFILE   =0x8
#define EDC_INPUTINI        0x10
#define EDC_INPUTSTRING     0x20
//EDC_INPUTBUFFER  =0x40
//EDC_INPUTFILE    =0x80

// Selection list dialog flags
#define SL_ALLOWMULTISELECT  0x1
#define SL_NOTOP             0x2
#define SL_VIEWID            0x4   // View always deleted.
#define SL_FILENAME          0x8
#define SL_NOISEARCH         0x10
#define SL_NODELETELIST      0x20  // Can preserve buffer this way
#define SL_SELECTCLINE       0x40  // Select current line.
#define SL_MATCHCASE         0x80  // Case sensitive i-search
#define SL_INVERT            0x8000// Invert button for muli-select
#define SL_SELECTALL         0x100 // Select all button for multi-select
#define SL_HELPCALLBACK      0x200
#define SL_DEFAULTCALLBACK   0x400 // Call the callback routine when enter
                           // pressed
#define SL_COMBO             0x800 // Display combo box above list box
#define SL_MUSTEXIST         0x1000
#define SL_BUFID             0x2000
#define SL_DESELECTALL       0x4000  // Deselect all before selecting anything
#define SL_NORETRIEVEPREV    0x10000 // Don't retrieve last combo box value
                             // By default, last combo box value
                             // is restored when initial_value not given.
                             // Has no effect if SL_COMBO not given
#define SL_COLWIDTH          0x20000 // Not supported by _sellist_form.
                                     // Computer largest first column text string
                                     // and set up two columns
#define SL_SELECTPREFIXMATCH 0x40000 // Effects SL_COMBO only.
                                     // When typing in the combo box
                                     // and text is a prefix match
                                     // of the text in the list box,
                                     // list box line is selected.
#define SL_CLOSEBUTTON       0x80000  // Use Close instead of Cancel button
#define SL_CHECKLIST         0x100000 // Override default bitmaps and use
                                      // checkbox bitmaps/behavior

#define SL_SIZABLE           0x200000 // Dialog box is made resizable
#define SL_DELETEBUTTON      0x400000 // Delete button (select_tree only)
#define SL_XY_WIDTH_HEIGHT   0x800000 // Save/restore x, y, width and height (select_tree only)
#define SL_GET_TREEITEMS    0x1000000 // Returns entire tree in results

// Selection list default button captions
#define SL_BUTTON_CANCEL      "Cancel:_sellistcancel"
#define SL_BUTTON_CLOSE       "Close:_sellistcancel"
#define SL_BUTTON_HELP        "&Help:_sellisthelp"
#define SL_BUTTON_INVERT      "&Invert:_sellistinvert"
#define SL_BUTTON_SELECTALL   "Select &All:_sellistselect_all"

// Selection list call back events
#define SL_ONINIT       1   // Dialog being initialized
#define SL_ONDEFAULT    2   // Enter pressed and SL_DEFAULTCALLBACK specified
#define SL_ONLISTKEY    3   // List box fall through key
#define SL_ONUSERBUTTON 4   // User button pressed
#define SL_ONSELECT     5   // Select item(s) changed
#define SL_ONINITFIRST  6   // First Dialog initialized callback, before autosizing
#define SL_ONDELKEY     7   // The del key was pressed inside the list box
#define SL_ONCLOSE      8   // Dialog is about to be closed
#define SL_ONRESIZE     9   // Dialog has resized
                            // 
// Selection tree call back events (first 9 events are the selection list events).
#define ST_ONLOAD       10  // Dialog has loaded and ready to set initial focus.
                            //
// save() and file() argument 2 flags
#define SV_RETURNSTATUS      0x1
#define SV_OVERWRITE         0x2
#define SV_POSTMSGBOX        0x4 /* Required when unsafe to display message box. */
#define SV_RETRYSAVE         0x8
#define SV_NOADDFILEHIST     0x10

// _tprint flags
#define TPRINT_FORM_FEED_AFTER_LAST_PAGE  0x1

// _print() print_flags
#define PRINT_LEFT_HEADER     0
#define PRINT_RIGHT_HEADER    1
#define PRINT_CENTER_HEADER   2
#define PRINT_LEFT_FOOTER     (0<<2)
#define PRINT_RIGHT_FOOTER    (1<<2)
#define PRINT_CENTER_FOOTER   (2<<2)
#define PRINT_TWO_UP          0x010
#define PRINT_COLOR           0x020
#define PRINT_FONTATTRS       0x040
#define PRINT_VISIBLEONLY     0x080
#define PRINT_HEX             0x100
#define PRINT_BACKGROUND      0x200

// _print() call back events
#define PRINT_ONINIT    0
#define PRINT_ONEXIT    1
#define PRINT_ONPAGE    2
// _font_type() flags.

#define RASTER_FONTTYPE      0x001
#define DEVICE_FONTTYPE      0x002
#define TRUETYPE_FONTTYPE    0x004
#define FIXED_FONTTYPE       0x008
#define OUTLINE_FONTTYPE     0x100
#define KERNING_FONTTYPE     0x200

// Font flags
#define F_BOLD   0x1
#define F_ITALIC 0x2
#define F_STRIKE_THRU  0x4
#define F_UNDERLINE    0x8
#define F_PRINTER      0x200
#define F_INHERIT_STYLE  0x400
#define F_INHERIT_COLOR_ADD_STYLE    0x800
#define F_INHERIT_FG_COLOR           0x1000
#define F_INHERIT_BG_COLOR           0x2000
// _choose_font() flags
#define CF_SCREENFONTS   0x00000001
#define CF_PRINTERFONTS  0x00000002
#define CF_EFFECTS       0x00000100
#define CF_FIXEDPITCHONLY   0x00004000

#define TB_RETRIEVE       0x1
#define TB_RETRIEVE_INIT  (0x2|TB_RETRIEVE)
#define TB_VIEWID_INPUT   0x4
#define TB_VIEWID_OUTPUT  0x8
#define TB_QUERY_COMPAT   0x10

// Name info flags for form objects
#define FF_MODIFIED        0x1
#define FF_SYSTEM          0x2

// _sys_help options
#define HELP_CONTEXT       0x0001    /* Display topic in ulTopic */
//HELP_QUIT      = 0x0002  /* Terminate help */
#define HELP_CONTENTS      0x0003
#define HELP_HELPONHELP    0x0004  /* Display help on using help */
//HELP_SETINDEX  =   0x0005  /* Set current Index for multi index help */
//HELP_SETCONTENTS = 0x0005
//HELP_CONTEXTPOPUP= 0x0008
#define HELP_FORCEFILE     0x0009    /* Load a help file */
#define HELP_KEY           0x0101    /* Display topic for keyword in offabData */
//HELP_COMMAND    =  0x0102
#define HELP_PARTIALKEY    0x0105
//HELP_MULTIKEY   =  0x0201
//HELP_SETWINPOS  =  0x0203
#define HELP_INDEX         0xf001
#define HELP_VALIDATE       0xf002
#define HELP_TITLE          0xf003  //Used vshlp.dll to get windows help file title

// Undo flags
#define LINE_DELETES_UNDONE      1
#define CURSOR_MOVEMENT_UNDONE   2
#define MARK_CHANGE_UNDONE       4
#define TEXT_CHANGE_UNDONE       8
#define LINE_INSERTS_UNDONE      16
#define MODIFY_FLAG_UNDONE       32
#define LINE_FLAGS_UNDONE        64
#define FILE_FORMAT_CHANGE_UNDONE   128
#define COLOR_CHANGE_UNDONE          256
#define MARKUP_CHANGE_UNDONE         512

typeless _argument;      // '' or integer count used by some commands.
                         // Set by argument command.
typeless _arg_complete;  /* Completion functions may set this var to non-zero */
                         /* value to indicate that more typing is necessary */
                         /* Ex. '\macros\' is not a complete file spec. */

int def_argument_completion_options;

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
 * Default selection list font.
 *
 * @categories Configuration_Variables
 * @see def_qt_jsellist_font
 * @see _sellist_form
 */
_str def_qt_sellist_font;
/**
 * Default selection list font for Japanese and other double byte locales.
 *
 * @categories Configuration_Variables
 * @see def_qt_sellist_font
 * @see _sellist_form
 */
_str def_qt_jsellist_font;

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
 * Set to true when the user selects an emulation
 * from the emulations dialog.  This is to prevent us
 * from prompting again for an emulation when they
 * upgrade or patch SlickEdit.
 *
 * @default false
 * @categories Configuration_Variables
 * @see def_keys
 */
boolean def_emulation_was_selected;


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
 * The format of this variable is:
 * <pre>
 *    [on/off]  [ksize]
 * </pre>
 * where [on/off] is 0 or 1, and [ksize] is the number of kilobytes
 * for the load partial threshold.
 * 
 * @default '1 8000'
 * @categories Configuration_Variables
 */
_str def_max_loadall;

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
   ,def_save_options           /* Default save options. Backup overwritten files*/
   ,def_preload_ext            /* Default file extensions to be pre-loaded */
                               /* to allow eof character in middle of file. */
   ,def_select_style           /* Default select style. */
   ,def_persistent_select
   ,def_word_chars       /* Specifies word characters used by */
                         /* next word, prev word and searching. */
   ,def_user_args        /* User defined completion equates. */
   ,_error_file          /* Absolute name of error file. */
   ,_grep_buffer         /* Absolute name of multi-file find output buffer. */
#if __PCDOS__
   ,_fpos_case           /* 'i' if file system is case insensitive. */
                         /* Otherwise ''. */
#else
   ,_fpos_case            /* UNIX file system is case sensitive. */
#endif
   ,_macro_ext           /* Macro source code extension with . */
                         /* SLICKEXT envvar may set this. */
   ,_tag_pass            // Number of passes.  May be used by "ext"_proc_search(). */
                         // Initialized to one before first call.
                         // perl.e places several 3 values in this string.

   ,def_next_word_style  //Determines whether prev-word and
                         //next-word (C-right & C-left) move to the
                         //beginning or end of the word.
   ,def_pmatch_style2    // 0-MoveCursor,1-Highlight,None-'' What to do when type
                         // close paren
                         // If !=0, alt+letter invokes menu bar drop-down
   ,def_wh               // Help files used by wh,wh2,wh3 commands
   ,def_mdi_menu         // Name of default MDI menu bar
   ,_cur_mdi_menu        // Current name of MDI menu.
   ,def_mffind_style
   ,COMPILE_ERROR_FILE
   ,def_mdibb   // Name of default button bar
   // Under OS/2 Menu font can be changed by droping configured ICON onto
   // editor.  Record original font and check if it changes.
   ,_origMdiMenuFont
   ;

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
boolean def_close_window_like_1fpw;

_str _project_name;        // Name of open project.  '' if not project open
_str _project_DebugCallbackName;  //DebugCallbackName for current project or '' if not project open
boolean _project_DebugConfig;     //True if current project configuration needs the Debug menu
_str _project_extTagFiles;
_str _project_extExtensions;

/**
 * Controls whether Alt menu hot keys are enabled for shortcut access
 * to the MDI menu.
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

_str  // The configuration variables below should have been boolean but
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
 * Additional text / printer codes to prepend to output file
 * when printing on Unix.
 *
 * @default ''
 * @categories Configuration_Variables
 */
_str def_leading_codes;
/**
 * Additional text / printer codes to append to output file when
 * printing on Unix.
 *
 * @default ''
 * @categories Configuration_Variables
 */
_str def_trailing_codes;
/**
 * Device to send printout to when printing on Unix.
 *
 * @default '/dev/lp0'
 * @categories Configuration_Variables
 */
_str def_tprint_device;


boolean def_highlight_matching_parens;   // highlight parens under cursor

/**
 * Exit setting - do they want to shut down SlickEdit when time elapses.
 *
 * @default 0
 * @categories Configuration_Variables
 */
boolean def_exit_on_autosave;
/**
 * If enabled, syntax indent on Enter inserts real indent
 * rather than just positioning cursor in virtual space.
 *
 * @default 0
 * @categories Configuration_Variables
 */
boolean def_enter_indent;
/**
 * Change directory in editor when changing directory
 * in open and save as dialog boxes.
 *
 * @default OFN_CHANGEDIR;
 * @categories Configuration_Variables
 */
int def_change_dir;
#if __PCDOS__
/**
 * If set to 1, use the older Windows XP style open dialog when
 * running on Windows Vista, Windows 7, or later
 * @default 0
 * @categories Configuration_Variables
 */
int def_use_xp_opendialog;
#endif
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
boolean def_add_to_project_save_as;

/**
 * Cursor left/right wrap to previous/next line (respectively).
 *
 * @default 0 (in most emulations)
 * @categories Configuration_Variables
 *
 * @see cursor_left
 * @see cursor_right
 */
boolean def_cursorwrap;
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
boolean def_hack_tabs;

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
boolean def_vim_change_cursor;  
/**
 * If on, and in Vim emulation, ESC during any codehelp or 
 * autocomplete will not only dismiss the dialog, but also 
 * switch to command mode. 
 *  
 * @default false 
 * @categories Configuration_Variables
 */
boolean def_vim_esc_codehelp;  
/**
 * If on, and in Vim emulation, there will be a warning prompt 
 * when staying in Ex mode. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
boolean def_vim_stay_in_ex_prmpt;  
/**
 * If on, and in Vim emulation, switch to command mode any 
 * buffer switch. 
 *  
 * @default false 
 * @categories Configuration_Variables
 */
boolean def_vim_start_in_cmd_mode;  
boolean def_restore_cursor;   //Cursor Position is restored after a replace
int def_updown_col;       //Cursor stays in straight line when moving up
boolean def_reflow_next;  //After reflow-paragraph command place cursor on
                          //Next paragraph
boolean def_pmatch_style;     //Set to 0 for fast brace matching
boolean def_stay_on_cmdline;
/**
 * Delay inserting of file list in open file
 * dialog until user is done typing filename.
 *
 * @default 1
 * @categories Configuration_Variables
 */
boolean def_delay_filelist;
boolean def_start_on_cmdline;
boolean def_start_on_first;   //When editing 'A B C' start on A

/**
 * If enabled, do not display file list when exiting w/modified buffers.
 *
 * @default 0
 * @categories Configuration_Variables
 * @see safe_exit
 */
boolean def_exit_file_list;

/**
 * If enabled, cancel current selection after paste.
 *
 * @default 1 (in most emulations)
 * @categories Configuration_Variables
 * @see copy
 */
boolean def_deselect_paste;
/**
 * If enabled, cancel current selection after copy.
 *
 * @default 1 (in most emulations)
 * @categories Configuration_Variables
 * @see copy
 */
boolean def_deselect_copy;

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

boolean def_pull;             //backspace pulls characters event when in replace mode

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
boolean def_jmp_on_tab;

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
boolean def_linewrap;

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
boolean def_join_strips_spaces;

// Open file dialog keep dir check box value.
boolean def_keep_dir;

/**
 * If enabled, operate on current word starting at the cursor
 * position instead of the beginning of the word.
 *
 * @default false, true for Emacs
 * @categories Configuration_Variables
 * @see cur_word
 */
boolean def_from_cursor;

boolean def_unix_expansion;  // Expand ~ and $ like UNIX shells.
boolean def_process_tab_output;  // Default build window output to tab in output toolbar

/**
 * Options controlling API help indexing.
 * <ul>
 * <li><b>HF_CLOSE</b>
 * <li><b>HF_EXACTMATCH</b>
 * <li><b>HF_USEDEFAULT</b>
 * </ul>
 *
 * @default HF_CLOSE
 * @categories Configuration_Variables
 */
int def_help_flags;

int def_mouse_menu_style;
//boolean def_mouse_paste;

enum_flags ChangeDirectoryFlags {
   CDFLAG_CHANGE_DIR_IN_BUILD_WINDOW = 0x1,
   CDFLAG_EXPAND_ALIASES_IN_CD_FORM  = 0x2,
   CDFLAG_NO_SYS_DIR_CHOOSER         = 0x4,
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
 * Maximium files listed under Winodw menu.
 *
 * @default 9
 * @categories Configuration_Variables
 */
int def_max_windowhist;

/**
 * Bitwise flags that are checked in vsc_list_tags() to fine-tune
 * tagging options.
 * <ul>
 * <li><b>1</b>   -- Do NOT skip over function definitions/prototypes
 *                   that do not have a semicolon or open brace
 *                   following the parameter list.  C++ source code
 *                   that uses Microsoft MFC macro definitions are
 *                   one of the reasons a user may want to skip over
 *                   these types of definitions.  Set this option
 *                   when you do not want old C-style function definitions
 *                   skipped.
 * <li><b>2</b>   -- Tag C/C++ prototypes.
 * <li><b>4</b>   -- Do not skip over old style C/C++ prototypes
 *                   that do not have an explicit return type.
 *                   This should be off in order for local-variable
 *                   search to work properly, otherwise it is very
 *                   difficult to distinguish a function call from
 *                   a prototype.
 * <li><b>8</b>   -- Do not break out of parsing a function if we see
 *                   a brace in column 1.  We normally do this as a
 *                   safeguard against parsing past the end of a proc
 *                   when the braces mismatch.
 * <li><b>16</b>  -- Ignore stray identifiers that may be preprocessing.
 * <li><b>32</b>  -- Ignore Visual C++ bracketted Attributes in C++ code.
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
boolean def_brief_word;

boolean def_vcpp_word;         // If true, Visual C++ style next/prev-word, select word and delete word
boolean def_subword_nav;
_str def_debug_vsdebugio_port; // port to connect to vsdebugio on

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
boolean def_autoreload_timeout_notifications;

/**
 * Always initialize Find and Replace tool window with defaultsearch options.
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
 * Highlight current and all matching occurences in current view when using
 * incremental search (i-search).
 *
 * @default 1
 * @categories Configuration_Variables
 *
 * @see i_search
 */
int def_search_incremental_highlight;

#if __OS390__ || __TESTS390__
   #define TAG_DEFAULT_BUFFER_RETAG_INTERVAL 6000
#elif __UNIX__
   #define TAG_DEFAULT_BUFFER_RETAG_INTERVAL 3000
#else
   #define TAG_DEFAULT_BUFFER_RETAG_INTERVAL 1000
#endif
/**
 * Amount of idle time in milliseconds to wait before
 * retagging buffers in the background.
 *
 * @default 1000 (3000 on Unix)
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
int _pic_fldclos12;      // Closed file folder bitmap. (12 pixel)
int _pic_fldopen12;      // Opened file folder bitmap (12 pixel)
int _pic_tt;             // True Type font bitmap
int _pic_printer;        // Printer font bitmap
int _pic_lbplus;         // List box Plus bitmap
int _pic_lbminus;        // List box Minus bitmap
int _pic_lbvs;           // List Box SlickEdit
int _pic_file;           // _file bitmap used by tree view control
int _pic_file_red_edge;// _file bitmap used by tree view control when a buffer is modified
int _pic_file_d;         // _file bitmap used by tree view control, looks disabled
int _pic_file12;         // _file bitmap used by tree view control (12 pixel)
int _pic_file_d12;       // _file bitmap used by tree view control, looks disabled (12 pixel)
int _pic_fldtags;        // _tags bitmap used by symbol browser and context toolbar
int _pic_fldctags;       // closed _tags bitmap used by symbol browser and context toolbar
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
int _pic_treecb_blank;           // Blank placeholder

// These bitmaps are loaded by cbrowser.e, but only stored in a static hashtable
int _pic_xml_tag;                // xml element picture
int _pic_xml_attr;               // xml attribute picture
int _pic_xml_target;             // ant target picture

// Bitmaps for OS/390 job utilities.
int _pic_job;                    // job
int _pic_jobdd;                  // job DD

// Bitmap for auto complete
int _pic_light_bulb;
int _pic_syntax;
int _pic_alias;
int _pic_keyword;
int _pic_complete_prev;
int _pic_complete_next;

// Bitmaps for symbol references and search results
int _pic_editor_reference;
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
int _pic_file_buf_mod;
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
int _pic_diff_path_up;
int _pic_diff_path_down;
int _pic_diff_all_symbols;
int _pic_diff_one_symbol;
int _pic_file_reload_overlay;
int _pic_file_date_overlay;
int _pic_file_mod_overlay;
int _pic_file_checkout_overlay;

#define USE_CVS_ANIMATION_PICS 0
#if USE_CVS_ANIMATION_PICS
int _cvs_animation_pics[];
#define CVS_STALL_PICTURE_PREFIX '_cvstx'
#endif

// These bitmaps are just for unit testing
int _pic_ut_method;
int _pic_ut_method_error;
int _pic_ut_method_passed;
int _pic_ut_method_failure;
int _pic_ut_method_notrun;
int _pic_ut_class;
int _pic_ut_class_error;
int _pic_ut_class_passed;
int _pic_ut_class_failure;
int _pic_ut_class_notrun;
int _pic_ut_package;
int _pic_ut_package_error;
int _pic_ut_package_passed;
int _pic_ut_package_failure;
int _pic_ut_package_notrun;
int _pic_ut_error;
int _pic_ut_failure;
int _pic_ut_information;

// Bitmaps for tool window panel title bar captions
int _pic_xclose_mono;
int _pic_pinin_mono;
int _pic_pinout_mono;

// bitmaps for enhanced open tool window
int _pic_otb_cd_up;
int _pic_otb_file_disk_open;
int _pic_otb_file_proj;
int _pic_otb_file_proj_open;
int _pic_otb_file_wksp;
int _pic_otb_file_wksp_open;
int _pic_otb_file_hist;              // _filehist.bmp
int _pic_otb_file_hist_open;         // _filehisto.bmp
int _pic_otb_file_open;
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
#define COMPILEFLAG_CLEARPROCESSBUFFER 1
#define COMPILEFLAG_CDB4COMPILE 0x2

_str def_save_on_compile;
int def_max_fhlen;        // Maximum length of filenames under menus
boolean _no_mdi_bind_all;  // When non-zero, menu_mdi_bind_all call is
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
 * </ul>
 *
 * @default EXIT_CONFIG_ALWAYS
 * @categories Configuration_Variables
 * @see safe_exit
 */
int def_exit_flags;
int def_re_search;   // Set to RE_SEARCH or UNIXRE_SEARCH

/**
 * When on, text selected with the mouse is copied to the clipboard.
 *
 * @default 'true' on Unix, 'false' otherwise
 * @categories Configuration_Variables
 *
 * @see _autoclipboard
 * @see mou_paste
 */
boolean def_autoclipboard;

boolean _in_quit;   // In quit command
boolean _in_project_close;   // In workspace_close_project function
boolean _in_workspace_close; // In workspace-close command
boolean _in_exit_list;
boolean _in_help;            // prompt not reentrant.
int def_max_autosave;  //Largest file in K to autosave

/**
 * Enable drag and drop of text within the editor?
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_dragdrop;
int def_pmatch_max_diff;

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
enum_flags AdaptiveFormattingFlags {
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
boolean def_warn_adaptive_formatting;

/**
 * Whether adaptive formatting is on by default. 
 * Adaptive Formatting is controlled individually by
 * language def-vars.  However, if no language 
 * def-var exists, we consult this value. 
 *  
 * @default true 
 * @categories Configuration_Variables
 */
boolean def_adaptive_formatting_on;

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

#define HF_CLOSE 0x1
#define HF_EXACTMATCH 0x2
#define HF_USEDEFAULT 0x4

#define EDIT_DEFAULT_FLAGS  (VCF_AUTO_CHECKOUT|EDIT_RESTOREPOS)
#define VCF_AUTO_CHECKOUT   0x1  // This flag must not overlap with EDIT_??? flag
#define VCF_EXIT_CHECKIN    0x2
#define VCF_SET_READ_ONLY   0x4
#define EDIT_RESTOREPOS     0x4
#define EDIT_NOADDHIST      0x8
#define EDIT_NOSETFOCUS     0x10
#define EDIT_NOUNICONIZE    0x20
#define EDIT_NOWARNINGS     0x40
#define EDIT_NOEXITSCROLL   0x80
#define EDIT_SMARTOPEN      0x100

#define VPM_LEFTBUTTON   0x0000
#define VPM_RIGHTBUTTON  0x0002
#define VPM_LEFTALIGN    0x0000
#define VPM_CENTERALIGN  0x0004
#define VPM_RIGHTALIGN   0x0008

#define SC_SIZE         0xF000
#define SC_MOVE         0xF010
#define SC_MINIMIZE     0xF020
#define SC_MAXIMIZE     0xF030
#define SC_NEXTWINDOW   0xF040
#define SC_PREVWINDOW   0xF050
#define SC_CLOSE        0xF060
#define SC_RESTORE      0xF120


#define EMBEDDEDLANGUAGEMASK_LF VSLF_EMBEDDEDLANGUAGEMASK
#define MULTILINEINFOMASK_LF VSLF_LEXER_STATE_INFO
#define COMMENTINFOMASK_LF  VSLF_COMMENT_INFO_MASK
#define MLCOMMENTLEVEL_LF   VSLF_MLCOMMENTLEVEL
#define MLCOMMENTINDEX_LF   VSLF_MLCOMMENTINDEX
#define LINEFLAGSMASK_LF  VSLF_LINEFLAGSMASK

#define CURLINEBITMAP_LF  VSLF_CURLINEBITMAP
#define MODIFY_LF         VSLF_MODIFY
#define INSERTED_LINE_LF  VSLF_INSERTED_LINE
#define HIDDEN_LF         VSLF_HIDDEN
#define MINUSBITMAP_LF    VSLF_MINUSBITMAP
#define PLUSBITMAP_LF     VSLF_PLUSBITMAP
#define NEXTLEVEL_LF      VSLF_NEXTLEVEL
#define LEVEL_LF          VSLF_LEVEL
#define NOSAVE_LF         VSLF_NOSAVE
#define VIMARK_LF         VSLF_VIMARK
#define EOL_MISSING_LF    VSLF_EOL_MISSING

// Flags for _lineflags() function
#define VSLF_EMBEDDEDLANGUAGEMASK 0xE0

// Mask multi-line comments, strings, and embedded languages
#define VSLF_LEXER_STATE_INFO 0xff


// Mask multi-line comments, strings
#define VSLF_COMMENT_INFO_MASK 0x1f

#define VSLF_MLCOMMENTINDEX   0x18   //Indicates which multi-line comment.
                          //Only four are allowed. Must know which
                          //multi-line comment we are in so we know
                          //what will terminate it.
#define VSLF_MLCOMMENTLEVEL   0x07   //Indicates multi-line comment nest level

#define VSLF_CURLINEBITMAP  0x00000200
#define VSLF_MODIFY         0x00000400
#define VSLF_INSERTED_LINE  0x00000800
#define VSLF_HIDDEN         0x00001000
#define VSLF_MINUSBITMAP    0x00002000
#define VSLF_PLUSBITMAP     0x00004000
#define VSLF_NEXTLEVEL      0x00008000
#define VSLF_LEVEL          0x001F8000
#define VSLF_NOSAVE         0x00200000   //Display this line in no save color
#define VSLF_VIMARK         0x00400000   //Used by VImacro to mark lines
#define VSLF_READONLY       0x00800000
#define VSLF_EOL_MISSING    0x01000000

#define VSLF_LINEFLAGSMASK     0x01ffffff

#define _LevelIndex(bl_flags)  (((bl_flags) & VSLF_LEVEL)>>15)
#define _Index2Level(level)   ((level)<<15)

// p_MouseActivate property values
// Determines what happens when user clicks on edit window
#define MA_DEFAULT          0
#define MA_ACTIVATE         1
#define MA_ACTIVATEANDEAT   2
#define MA_NOACTIVATE       3
#define MA_NOACTIVATEANDEAT 4

#define VF_FREE     0   // Variable is on free list
               // If you get this, you screwed up with pointers.
#define VF_LSTR     2
#define VF_INT      3
#define VF_ARRAY    4
#define VF_HASHTAB  5
#define VF_PTR      7
#define VF_EMPTY    8
#define VF_FUNPTR   9
#define VF_OBJECT  10 // class instance
#define VF_WID     11 // window id
#define VF_INT64   12 // 64-bit integer (Slick-C long)
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
boolean def_cfgfiles;
/**
 * Use local state file in configuration directory.
 * If set to 0, always use the global state file.
 * If you don't have disk space, set this to zero.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_localsta;

int _config_modify;   /* Initialized by stdcmds.e. */
                      /* Non-zero if user configuration has been modified.*/
// _config_modify flags
#define CFGMODIFY_ALLCFGFILES  0x001 // For backward compatibility.
                              // New macros should use the constants below.
#define CFGMODIFY_DEFVAR    0x002  // Set macro variable with prefix "def_"
#define CFGMODIFY_DEFDATA   0x004  // Set symbol with prefix "def_"
#define CFGMODIFY_OPTION    0x008  // color, scroll style, insert state or
                           // any option which the list_config
                           // command generates source for.
#define CFGMODIFY_RESOURCE     0x010  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
#define CFGMODIFY_SYSRESOURCE  0x020  // FORM, BITMAP, MENU, BUTTON BAR, TOOL BAR
#define CFGMODIFY_LOADMACRO  0x040  // vusermacs is screened out of this.
                            // Must write state file if user load
#define CFGMODIFY_LOADDLL    0x080  // Must write state file if user loads
                            // a DLL.
#define CFGMODIFY_KEYS       0x100  // Modify keys
#define CFGMODIFY_USERMACS   0x200  // vusrmacs was loaded.
#define CFGMODIFY_MUSTSAVESTATE  (CFGMODIFY_LOADMACRO|CFGMODIFY_LOADDLL)
#define CFGMODIFY_DELRESOURCE  0x400 // Sometimes must write state file
                             // when resource is deleted.
                             // This should be used with
                             // CFGMODIFY_RESOURCE or
                             // CFGMODIFY_SYSRESOURCE

// Some _default_option() constants
// VSOPTION_APIFLAGS
const VSAPIFLAG_SAVERESTORE_EDIT_WINDOWS                 = 0x1;
const VSAPIFLAG_TOOLBAR_DOCKING                          = 0x2;
const VSAPIFLAG_MDI_MENUS                                = 0x4;
const VSAPIFLAG_MDI_WINDOW                               = 0x8;
const VSAPIFLAG_CONFIGURABLE_CMDLINE_COLOR               = 0x10;
const VSAPIFLAG_CONFIGURABLE_CMDLINE_FONT                = 0x20;
const VSAPIFLAG_CONFIGURABLE_STATUS_COLOR                = 0x40;
const VSAPIFLAG_CONFIGURABLE_STATUS_FONT                 = 0x80;
const VSAPIFLAG_CONFIGURABLE_ALT_MENU_HOTKEYS            = 0x100;
const VSAPIFLAG_CONFIGURABLE_ONE_FILE_PER_WINDOW         = 0x200;
const VSAPIFLAG_CONFIGURABLE_VCPP_SETUP                  = 0x400;
/* reserved                                                0x800; */
const VSAPIFLAG_ALLOW_DIALOG_EDITING                     = 0x1000;
const VSAPIFLAG_ALLOW_PROJECT_SUPPORT                    = 0x2000;
const VSAPIFLAG_ALLOW_DIALOG_ACCESS_TO_PROJECTS          = VSAPIFLAG_ALLOW_PROJECT_SUPPORT;
const VSAPIFLAG_SAVERESTORE_CWD                          = 0x4000;
const VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_FILENAME       = 0x8000;
const VSAPIFLAG_GOTO_BOOKMARK_RESTORES_BY_DOCUMENTNAME   = 0x10000;
// The OEM kit is being used as an eclipse plug-in        
const VSAPIFLAG_ECLIPSE_PLUGIN                           = 0x400000;
const VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW        = 0x800000;
const VSAPIFLAG_ALLOW_TILED_WINDOWING                    = 0x1000000;
const VSAPIFLAG_ALLOW_JGUI_SUPPORT                       = 0x2000000;
const VSAPIFLAG_VISUALSTUDIO_PLUGIN                      = 0x4000000;
/* reserved                                                0x8000000; */
/* reserved                                                0x10000000; */
const VSAPIFLAG_MDI_TABGROUPS                            = 0x20000000;
const VSAPIFLAG_CONFIGURABLE_DOCUMENT_TABS_FONT          = 0x40000000;

const VSOPTION_WARNING_ARRAY_SIZE               = 1;
const VSOPTION_WARNING_STRING_LENGTH            = 2;
const VSOPTION_VERTICAL_LINE_COL                = 3;
const VSOPTION_WEAK_ERRORS                      = 4;
const VSOPTION_AUTO_ZOOM_SETTING                = 5;
const VSOPTION_MAXIMIZE_FIRST_MDICHILD          = VSOPTION_AUTO_ZOOM_SETTING;
const VSOPTION_MAXTABCOL                        = 6;
const VSOPTION_CURSOR_BLINK                     = 7;
const VSOPTION_DISPLAY_TEMP_CURSOR              = 8;
const VSOPTION_LEFT_MARGIN                      = 9;
const VSOPTION_DISPLAY_TOP_OF_FILE              = 10;
const VSOPTION_HORIZONTAL_SCROLL_BAR            = 11;
const VSOPTION_VERTICAL_SCROLL_BAR              = 12;
const VSOPTION_HIDE_MOUSE                       = 13;
const VSOPTION_ALT_ACTIVATES_MENU               = 14;
const VSOPTION_DRAW_BOX_AROUND_CURRENT_LINE     = 15;
const VSOPTION_MAX_MENU_FILENAME_LEN            = 16;
const VSOPTION_PROTECT_READONLY_MODE            = 17;
const VSOPTION_PROCESS_BUFFER_CR_ERASE_LINE     = 18;
const VSOPTION_ENABLE_FONT_FLAGS                = 19;
const VSOPTION_APIFLAGS                         = 20;
const VSOPTION_HAVECMDLINE                      = 21;
const VSOPTION_QUIET                            = 22;
const VSOPTION_SHOWTOOLTIPS                     = 23;
const VSOPTION_TOOLTIPDELAY                     = 24;
const VSOPTION_HAVEMESSAGELINE                  = 25;
const VSOPTION_HAVEGETMESSAGELINE               = 26;
const VSOPTION_MACRO_SOURCE_LEVEL               = 27;
const VSOPTION_VSAPI_SOURCE_LEVEL               = 28;
const VSOPTION_APPLY_LOCAL_STATE_FILE_CHANGES   = 29;
//#define VSOPTION_EMBEDDED              30   // Use new p_embedded property
const VSOPTION_DISPLAYVERSIONMESSAGE            = 31;
const VSOPTION_CXDRAGMIN                        = 32;
const VSOPTION_CYDRAGMIN                        = 33;
const VSOPTION_DRAGDELAY                        = 34;
const VSOPTION_MDI_SHOW_WINDOW_FLAGS            = 35;   //4:26pm 4/20/1998
                                                         //Dan added for to support hiding mdi
                                                         //on startup
const VSOPTION_SEARCHDEFAULTFLAGS               = 36;
const VSOPTION_MAX_STACK_DUMP_LINE_LENGTH       = 37;
const VSOPTION_MAX_STACK_DUMP_ARGUMENT_NOFLINES = 38;
const VSOPTION_NEXTWINDOWSTYLE                  = 39;
const VSOPTION_CODEHELP_FLAGS                   = 40;
                                                   
const VSOPTION_LINE_NUMBERS_LEN                 = 41;
const VSOPTION_LCREADWRITE                      = 42;  /* non-zero want prefix area */
const VSOPTION_LCREADONLY                       = 43;  /* non-zero want prefix area */
const VSOPTION_LCMAXNOFLINECOMMANDS             = 44;
const VSOPTION_RIGHT_CONTROL_IS_ENTER           = 45; /* obsolete */
const VSOPTION_DOUBLE_CLICK_TIME                = 46;
const VSOPTION_LCNOCOLON                        = 47;
const VSOPTION_PACKFLAGS1                       = 48;
   #define VSPACKFLAG1_STD (0x1)
   #define VSPACKFLAG1_COB (0x2)
   #define VSPACKFLAG1_PLI (0x4)
   #define VSPACKFLAG1_ASM (0x8)
   #define VSPACKFLAG1_CICS (0x10)
   #define VSPACKFLAG1_C    (0x20)
   #define VSPACKFLAG1_JAVA (0x40)
   #define VSPACKFLAG1_PKGA (VSPACKFLAG1_STD|VSPACKFLAG1_COB|VSPACKFLAG1_PLI|VSPACKFLAG1_ASM)
const VSOPTION_PACKFLAGS2                       = 49;
const VSOPTION_UTF8_SUPPORT                     = 50;
const VSOPTION_UNICODE_CALLS_AVAILABLE          = 51;
const VSOPTION_OPTIMIZE_UNICODE_FIXED_FONTS     = 52;
const VSOPTION_JAWS_MODE                        = 53;
const VSOPTION_JGUI_SOCKET                      = 54;
const VSOPTION_SHOW_SPLASH                      = 55;  /* 1=Show the splash screen on startup */
const VSOPTION_FORCE_WRAP_LINE_LEN              = 56;
const VSOPTION_APPLICATION_CAPTION_FLAGS        = 57;
const VSOPTION_IPVERSION_SUPPORTED              = 58;
enum VSIPVersion {
   VSIPVERSION_ALL = 0,
   VSIPVERSION_4 = 1,
   VSIPVERSION_6 = 2,
};
const VSOPTION_NO_BEEP                          = 59;
const VSOPTION_NEW_WINDOW_WIDTH                 = 60;
const VSOPTION_NEW_WINDOW_HEIGHT                = 61;
const VSOPTION_USE_CTRL_SPACE_FOR_IME           = 62;
// Do not write any files into the
// configuration files.
// This option is needed for creating a licensing file
// during the installation process which may have
// administrator or root access.  We do not want
// configuration files written during installation
// process.
const VSOPTION_CANT_WRITE_CONFIG_FILES    =63;
// Option when clicking in a registered MDI editor control, that does not 
// have focus, to place caret at mouse hit coordinates in addition to 
// giving focus.
const VSOPTION_PLACE_CARET_ON_FOCUS_CLICK       = 64;
// When get value, non-zero value means keep command line visible.
// When setting value, specify 1 to increment, 0 to decrement. Returns current count
#define VSOPTION_STAY_IN_GET_STRING_COUNT   65

// A value of zero means the default IME usage of Option+Key on the Mac
// A non-zero value allows the Alt/Option key to be used for Windows-style key bindings
const VSOPTION_MAC_ALT_KEY_BEHAVIOR    =   67;
   const VSOPTION_MAC_ALT_KEY_DEFAULT_IME_BEHAVIOR    = 0;
   const VSOPTION_MAC_ALT_KEY_WINDOWS_STYLE_BEHAVIOR  = 1;
const VSOPTION_NO_ANTIALIAS            =   68;
const VSOPTION_MAC_USE_COMMAND_KEY_FOR_HOT_KEYS = 69;
const VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS = VSOPTION_MAC_USE_COMMAND_KEY_FOR_HOT_KEYS;
const VSOPTION_USE_CLEAR_KEY_AS_NUMLOCK_KEY    =70;
const VSOPTION_CLEAR_KEY_NUMLOCK_STATE         =71;
const VSOPTION_INITIAL_CLEAR_KEY_NUMLOCK_STATE =72;
const VSOPTION_MAC_RESIZE_BORDERS              =73;
const VSOPTION_CURSOR_BLINK_RATE               =74;
// Do not read vrestore.slk or other user configuration files.
// This option is used to simplify starting the editor
// when you have a corrupt vrestore.slk, and is also used
// by utility programs that launch the editor, like vsmktags
const VSOPTION_DONT_READ_CONFIG_FILES          =75;
const VSOPTION_MDI_ALLOW_CORNER_TOOLBAR        =76;
const VSOPTION_MAC_HIGH_DPI_SUPPORT            =77;
   const VSOPTION_MAC_HIGH_DPI_AUTO = 0;
   const VSOPTION_MAC_HIGH_DPI_ON = 1;
   const VSOPTION_MAC_HIGH_DPI_OFF = 2;
const VSOPTION_MAC_SHOW_FULL_MDI_CHILD_PATH    =78;
   const VSOPTION_TAB_TITLE_SHORT_NAME =0;
   const VSOPTION_TAB_TITLE_NAME_AND_PATH =1;
   const VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_FULL_PATH =1;
   const VSOPTION_TAB_TITLE_NAME_FOLLOWED_BY_PATH=2;
   const VSOPTION_TAB_TITLE_FULL_PATH=3;
const VSOPTION_TAB_TITLE                     =79;
   const VSOPTION_SPLIT_WINDOW_EVENLY           =0;
   const VSOPTION_SPLIT_WINDOW_STRICT_HALVING   =1;
const VSOPTION_SPLIT_WINDOW                  =80;
   const VSOPTION_ZOOM_WHEN_ONE_WINDOW_NEVER   =0;
   const VSOPTION_ZOOM_WHEN_ONE_WINDOW_ALWAYS  =1;
   const VSOPTION_ZOOM_WHEN_ONE_WINDOW_AUTO    =2;
const VSOPTION_ZOOM_WHEN_ONE_WINDOW          =81;
const VSOPTION_TAB_MODIFIED_COLOR            =82;
const VSOPTION_JOIN_WINDOW_WITH_NEXT         =83;
/*const VSOPTION_DRAGGING_DOCUMENT_TAB         =84;*/
const VSOPTION_AUTO_RESTORING_TO_NEW_SCREEN_SIZE =85;

#define VSOPTIONZ_PAST_EOF               1000

#define VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB  1001
   #define VSSPECIALCHAR_NOT_USED_1    0
   #define VSSPECIALCHAR_NOT_USED_2    1
   #define VSSPECIALCHAR_NOT_USED_3    2
   #define VSSPECIALCHAR_NOT_USED_4    3
   #define VSSPECIALCHAR_NOT_USED_5    4
   #define VSSPECIALCHAR_EOF           5
   #define VSSPECIALCHAR_FORMFEED      6
   #define VSSPECIALCHAR_OTHER_CTRL_CHAR 7
   #define VSSPECIALCHAR_EOL           8
   #define VSSPECIALCHAR_CR            9
   #define VSSPECIALCHAR_LF            10

   #define VSSPECIALCHAR_MAX     20

#define VSOPTIONZ_APPLICATION_NAME       1002
#define VSOPTIONZ_SUPPORTED_TOOLBARS_LIST  1003
#define VSOPTIONZ_LANG                     1004
#define VSOPTIONZ_SPECIAL_CHAR_XLAT_TAB_UTF8 1005
#define VSOPTIONZ_DEFAULT_FIND_WINDOW_OPTIONS 1006

#define DEFAULT_SPECIAL_CHARS    SHOWSPECIALCHARS_CTRL_CHARS

enum_flags VSShowSpecialChars {
   SHOWSPECIALCHARS_NLCHARS    = 0x01,
   SHOWSPECIALCHARS_TABS       = 0x02,
   SHOWSPECIALCHARS_SPACES     = 0x04,
   SHOWSPECIALCHARS_CTRL_CHARS = 0x08,
   SHOWSPECIALCHARS_EOF        = SHOWSPECIALCHARS_CTRL_CHARS,
   SHOWSPECIALCHARS_FORMFEED   = SHOWSPECIALCHARS_CTRL_CHARS,
   SHOWSPECIALCHARS_ALL        = 0xff,
};

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
int def_diff_options;
#define DIFF_EXPAND_TABS                        0x01
#define DIFF_IGNORE_LSPACES                     0x02
#define DIFF_IGNORE_TSPACES                     0x04
#define DIFF_IGNORE_SPACES                      0x08
#define DIFF_IGNORE_CASE                        0x10
#define DIFF_OUTPUT_INTERLEAVED                 0x20
#define DIFF_DONT_COMPARE_EOL_CHARS             0x40
#define DIFF_OUTPUT_BOOLEAN                     0x400
#define DIFF_LEADING_SKIP_COMMENTS              0x800
#define DIFF_NO_BUFFER_SETUP                    0x4000
#define DIFF_DONT_MATCH_NONMATCHING_LINES       0x8000
#define DIFF_MFDIFF_REQUIRE_TEXT_MATCH          0x10000
#define DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH     0x20000
#define DIFF_MFDIFF_SIZE_ONLY_MATCH_IS_MISMATCH 0x40000
#define DIFF_NO_SOURCE_DIFF                     0x80000
#define DIFF_BALANCE_BUFFERS                    0x100000
#define DIFF_NO_BALANCE_BUFFERS_WARNING         0x200000

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
int def_diff_edit_options;
#define DIFFEDIT_START_AT_TOP          0x04
#define DIFFEDIT_START_AT_FIRST_DIFF   0x08
#define DIFFEDIT_CURFILE_INIT          0x10
#define DIFFEDIT_AUTO_JUMP             0x20
#define DIFFEDIT_SHOW_GAUGE            0x40
#define DIFFEDIT_NO_AUTO_MAPPING       0x1000
#define DIFFEDIT_AUTO_CLOSE            0x2000
#define DIFFEDIT_NO_PROMPT_ON_MFCLOSE  0x4000
#define DIFFEDIT_BUTTONS_AT_TOP        0x8000
#define DIFFEDIT_SPAWN_MFDIFF          0x10000
//Other flags reserved...
int def_diff_max_intraline_len;

_str def_diff_font_info;
int def_diff_num_sessions;    // number of unnamed diff sessions to be kept

int GMFDiffViewOptions;
#define DIFF_VIEW_MATCHING_FILES  0x1
#define DIFF_VIEW_VIEWED_FILES    0x2
#define DIFF_VIEW_DIFFERENT_FILES 0x4
#define DIFF_VIEW_MISSING_FILES1  0x8
#define DIFF_VIEW_MISSING_FILES2  0x10

#define DIFF_VIEW_DIFFERENT_SYMBOLS 0x20
#define DIFF_VIEW_MATCHING_SYMBOLS  0x40
#define DIFF_VIEW_MISSING_SYMBOLS1   0x80
#define DIFF_VIEW_MISSING_SYMBOLS2  0x100
#define DIFF_VIEW_MOVED_SYMBOLS     0x200

#define LINE_NUMBERS_LEN  6

boolean def_seldisp_single;
boolean def_auto_landscape;
#define SELDISP_COLLAPSEPROCCOMMENTS 0x1
#define SELDISP_SHOWPROCCOMMENTS 0x2
#define SELDISP_EXPANDSUBLEVELS  0x4
#define SELDISP_COLLAPSESUBLEVELS 0x8
int def_seldisp_flags;
int def_seldisp_maxlevel;

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
boolean def_copy_noselection;
/**
 * Copy to clipboard will execute stop_build in the Build window
 * if there is no selection and the last key was Ctrl+C.
 *
 * #default true;
 * @categories Configuration_Variables
 *
 * @see copy_to_clipboard
 * @see stop_build
 */
boolean def_stop_process_noselection;

#define MFFIND_BUFFER            '<Current Buffer>'
#define MFFIND_BUFFERS           '<All Buffers>'
#define MFFIND_BUFFER_DIR        '<Current Buffer Directory>'
#define MFFIND_PROJECT_FILES     '<Project>'
#define MFFIND_WORKSPACE_FILES   '<Workspace>'

#define MFFIND_CURBUFFERONLY 0x01   // deprecated
#define MFFIND_FILESONLY     0x02
#define MFFIND_APPEND        0x04
#define MFFIND_MDICHILD      0x08
#define MFFIND_SINGLE        0x10
#define MFFIND_GLOBAL        0x20
#define MFFIND_THREADED      0x40
#define MFFIND_SINGLELINE    0x80
#define MFFIND_LEAVEOPEN     0x100  // for mfreplace
#define MFFIND_DIFF          0x200  // for mfreplace
#define MFFIND_MATCHONLY     0x400
#define MFFIND_QUIET         0x800

#define SW_HIDE             0  // Make window invisible
#define SW_NORMAL           1
#define SW_SHOWMINIMIZED    2  // Show window iconized
#define SW_SHOWMAXIMIZED    3  // Show window maximized
#define SW_SHOWNOACTIVATE   4  // Make window visible without changing Z order
#define SW_SHOW             5  // Make window visible and change Z order
#define SW_RESTORE          9  // Restore window

enum SSTAB_ORIENTATION {
   SSTAB_OTOP          = 0,  // tab-row-on-top orientation
   SSTAB_OBOTTOM       = 1,  // tab-row-on-bottom orientation
   SSTAB_OLEFT         = 2,  // tab-row-on-left orientation
   SSTAB_ORIGHT        = 3,  // tab-row-on-right orientation
};

// Deprecated p_GrabbarLocation values
#define SSTAB_GRABBARLOCATION_TOP    0
#define SSTAB_GRABBARLOCATION_BOTTOM 1
#define SSTAB_GRABBARLOCATION_LEFT   2
#define SSTAB_GRABBARLOCATION_RIGHT  3

// Deprecated p_MultiRow values
#define SSTAB_MULTIROW_NONE       0
#define SSTAB_MULTIROW_MULTIROW   1
#define SSTAB_MULTIROW_BESTFIT    2

struct SSTABCONTAINERINFO {

   // true if tab is enabled
   boolean enabled;
   // Order of the tab (left-to-right). This will typically be the
   // same as the index.
   int order;
   // Index of picture displayed on the tab
   int picture;
   // true if caption is partially displayed
   boolean partialCaption;
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

_str gerror_info:[];   // Hash table containing filenames which have
                       // old line numbers set.

/*
    1-Multi-file find uses find_next/find_prev
    2-Multi-file find uses next_error/prev_error
    Both bits can be on.
 */
int def_mfflags;
//3:35pm 3/24/1997:Dan added for tree control
#define TREE_NO_LINES         0
#define TREE_OS_DEFAULT_LINES 1
#define TREE_DOTTED_LINES TREE_OS_DEFAULT_LINES   // For compatibility
#define TREE_SOLID_LINES  TREE_OS_DEFAULT_LINES   // For compatibility
#define TREE_NO_FIRST_LEVEL_LINES  0x80           // For compatibility

#define TREENODE_HIDDEN     0x01    // node and children nodes are not visible in tree
//#define TREENODE_SELECTED   0x02  // deprecated use _TreeIsSelected(int) and _TreeSelectLine(int)
#define TREENODE_BOLD       0x04    // node caption is bold
#define TREENODE_ALTCOLOR   0x08    // node is colored same as modified line 
                                    // color.  When this is shut off, it will
                                    // restore the regular tree foreground and
                                    // background color.  Do not use this in 
                                    // conjunction with _TreeSetColor(),
                                    // _TreeSetColColor(), _TreeSetRowColor()
#define TREENODE_FORCECOLOR 0x10    // node is always colored red
#define TREENODE_GRAYTEXT   0x20    // node is colored gray
#define TREENODE_DISABLED   0x40    // node is colored gray, no node edits
#define TREENODE_ITALIC     0x80    // node caption is italic
#define TREENODE_UNDERLINE  0x100   // node caption is underlined
#define TREENODE_FIRSTCOLUMNSPANS  0x200   // node caption is underlined

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
   boolean current;           // is this the current item in the tree?
   TREENODESTATE children[];  // list of children under this node
};

//7:15pm 4/29/1997:These are for the push buttton list box stuff
#define LB_BUTTON_NOPUSH      0
#define LB_BUTTON_PUSH_BUTTON 1
#define LB_BUTTON_STICKY      2

#define TREE_ADD_AFTER      0x0 /* Add a node after  sibling in order */
#define TREE_ADD_BEFORE     0x1 /* Add a node before sibling in order */
#define TREE_ADD_AS_CHILD   0x2
//These sort flags cannot be used in combination with each other
#define TREE_ADD_SORTED_CS       0x4
#define TREE_ADD_SORTED_CI       0x8
#define TREE_ADD_SORTED_FILENAME 0x10
#define TREE_ADD_SORTED_DESCENDING 0x20

#define TREE_ROOT_INDEX     0

// Used with the "show children" parameter
#define TREE_NODE_LEAF           -1
#define TREE_NODE_COLLAPSED      0
#define TREE_NODE_EXPANDED       1

/* Constants for 'tree_to_node' */
#define TO_PREVSIB 0x1   /* To previous(left) sibling */
#define TO_NEXTSIB 0x2   /* To next(right) sibling    */
#define TO_PARENT  0x4   /* To parent                 */
#define TO_LCHILD  0x8   /* To left-most child        */

/* Constants for 'tree_traverse' */
#define TRAVERSE_PREORDER  0x1
#define TRAVERSE_INORDER   0x2
#define TRAVERSE_POSTORDER 0x4

#define TREE_NODE_CHILD  1
#define TREE_NODE_PARENT 2

#define VCPP_STARTUP_TIMEOUT 30
#define VCPP_EXE_FILENAME 'msdev.exe'
#define VCPP_CLASSNAME_PREFIX 'Afx'
#define VCPP_WINDOWTITLE_PREFIX 'Microsoft Developer Studio'

// Label Style argument constants
#define MULTI_LABEL_DEFAULT 0x1
#define MULTI_LABEL_SUNKEN 0x2

// Label AutoSizeStyle argument constants
#define MULTI_LABEL_AUTOSIZE_DEFAULT 0
#define MULTI_LABEL_AUTOSIZE_INDIV 1
#define MULTI_LABEL_AUTOSIZE_REST 2

// _SetListColInfo method Style argument constants
#define LBCOLSTYLE_LABEL      0
#define LBCOLSTYLE_BUTTON     1
#define LBCOLSTYLE_2STATE     2

#define VSMARKFLAG_BINARY            1
//#define VSMARKFLAG_DELETE_LAST_LINE  2
//#define VSMARKFLAG_ALREADYADJUSTED   4
#define VSMARKFLAG_COPYNOSAVELF      8

//      p_ModifyFlags
#define MODIFYFLAG_AUTOSAVE_DONE       0x0002
#define MODIFYFLAG_DELPHI              0x0004
#define MODIFYFLAG_TAGGED              0x0008
#define MODIFYFLAG_PROCTREE_UPDATED    0x0010
#define MODIFYFLAG_CONTEXT_UPDATED     0x0020
#define MODIFYFLAG_LOCALS_UPDATED      0x0040
#define MODIFYFLAG_FCTHELP_UPDATED     0x0080
#define MODIFYFLAG_TAGWIN_UPDATED      0x0100
#define MODIFYFLAG_CONTEXTWIN_UPDATED  0x0200
#define MODIFYFLAG_FTP_NEED_TO_SAVE    0x0400
#define MODIFYFLAG_AUTOEXT_UPDATED     0x0800
#define MODIFYFLAG_PROCTREE_SELECTED   0x1000
#define MODIFYFLAG_LC_UPDATED          0x2000
#define MODIFYFLAG_XMLTREE_UPDATED     0x4000
// Warning: MODIFYFLAG_JGUI_UPDATED is also defined in heap.h
#define MODIFYFLAG_JGUI_UPDATED        0x8000  //Indicates that Java GUI Builder has buffer contents
#define MODIFYFLAG_STATEMENTS_UPDATED  0x10000
#define MODIFYFLAG_AUTO_COMPLETE_UPDATED  0x20000
#define MODIFYFLAG_CLASS_UPDATED          0x40000
#define MODIFYFLAG_CLASS_SELECTED         0x80000
#define MODIFYFLAG_BGRETAG_THREADED       0x100000
#define MODIFYFLAG_CONTEXT_THREADED       0x200000
#define MODIFYFLAG_LOCALS_THREADED        0x400000
#define MODIFYFLAG_STATEMENTS_THREADED    0x800000
#define MODIFYFLAG_SYMBOL_COLORING_RESET  0x1000000
#define MODIFYFLAG_SCROLL_MARKER_UPDATED  0x2000000
#define MODIFYFLAG_TOKENLIST_UPDATED      0x4000000

/**
 * Control dynamic tagging options.  Consists of a bitset of AUTOTAG_* flags.
 * <ul>
 * <li><b>AUTOTAG_ON_SAVE            </b> -- Tag file on save
 * <li><b>AUTOTAG_BUFFERS            </b> -- Background tag buffers
 * <li><b>AUTOTAG_PROJECT_ONLY       </b> -- Background tag project buffers only (obsolete?)
 * <li><b>AUTOTAG_FILES              </b> -- Background tag all files
 * <li><b>AUTOTAG_SYMBOLS            </b> -- Refresh tag window (symbols tab)
 * <li><b>AUTOTAG_FILES_PROJECT_ONLY </b> -- Background tag project files only
 * <li><b>AUTOTAG_CURRENT_CONTEXT    </b> -- Background update current context
 * <li><b>AUTOTAG_UPDATE_CALLSREFS   </b> -- Update call tree and references
 *                                           on change event for symbols
 *                                           browser and proctree
 * </ul>
 *
 * @default AUTOTAG_ON_SAVE | AUTOTAG_BUFFERS | AUTOTAG_SYMBOLS |
 *          AUTOTAG_FILES_PROJECT_ONLY | AUTOTAG_CURRENT_CONTEXT
 * @categories Configuration_Variables
 */
int def_autotag_flags2;

#include "rc.sh"
#define VSWID_TOP      -1
#define VSWID_BOTTOM   -2

//These are options for *_list_tags and *_list_locals
#define VSLTF_OUTPUT_LINE_NUMBERS   0x0001   // [OBSOLETE] output only line numbers
#define VSLTF_PROCS                 0x0002   // [OBSOLETE] List proctree (def_proctree_flags) only
#define VSLTF_TREE_OUTPUT           0x0004   // [OBSOLETE] Output to a tree control
#define VSLTF_TREE_OUTPUT_HIDDEN    0x0008   // [OBSOLETE] Output to tree control hidden
#define VSLTF_LIST_OUTPUT           0x0010   // [OBSOLETE] Output to list control
#define VSLTF_SKIP_OUT_OF_SCOPE     0x0020   // Skip locals that are out of scope
#define VSLTF_SET_TAG_CONTEXT       0x0040   // Set tagging context at cursor position
#define VSLTF_SET_TAG_MATCHES       0x0080   // [OBSOLETE] Insert tags into match set
#define VSLTF_LIST_OCCURRENCES      0x0100   // Insert references into tags database
#define VSLTF_START_LOCALS_IN_CODE  0x0200   // Parse locals without first parsing header
#define VSLTF_READ_FROM_STRING      0x0400   // [6.0] arg(3)=buffer, arg(6)=buffer_len
#define VSLTF_LIST_STATEMENTS       0x0800   // [9.0] list statements as well as contexts
#define VSLTF_LIST_LOCALS           0x1000   // [15.0] list local variables in current function
#define VSLTF_ASYNCHRONOUS          0x2000   // [15.0] request to update tags in background thread
#define VSLTF_READ_FROM_EDITOR      0x4000   // [15.0] reading input from an editor control
#define VSLTF_ASYNCHRONOUS_DONE     0x8000   // [16.0] special flag for job to indicate tagging done
#define VSLTF_BEAUTIFIER            0x10000  // [17.0] Set when this is associated with a beautifier job.
#define VSLTF_SAVE_TOKENLIST        0x20000  // [18.0] Set when building current context and saving token list
#define VSLTF_INCREMENTAL_CONTEXT   0x40000  // [18.0] Used for incremental parsing

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
int def_proctree_flags;
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
int def_proc_tree_options;

/**
 * Initial level to expand file node to in the Defs tab of the project toolbar.
 *
 * <p>
 * Valid values:
 * <ul>
 * <li>0 Normal processing takes place. If "Auto Expand" is on, then
 *     the current symbol is found in the tree. If "Auto Expand" is off,
 *     then the tree is not expanded.
 * <li>1 One level.
 * <li>2 Two levels.
 * </ul>
 * </p>
 */
int def_proc_tree_expand_level;

int def_tag_select_options;

#define PROC_TREE_SORT_FUNCTION   0x1
#define PROC_TREE_SORT_LINENUMBER 0x2
#define PROC_TREE_AUTO_EXPAND     0x4
#define PROC_TREE_ONLY_TAGGABLE   0x8
#define PROC_TREE_NO_STRUCTURE    0x10
#define PROC_TREE_AUTO_STRUCTURE  0x20
#define PROC_TREE_NO_BUFFERS      0x40
#define PROC_TREE_STATEMENTS      0x80

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
#define TAGFILE_MODIFIED_CALLBACK_PREFIX   "_TagFileModified_"
#define TAGFILE_ADD_REMOVE_CALLBACK_PREFIX "_TagFileAddRemove_"
#define TAGFILE_REFRESH_CALLBACK_PREFIX    "_TagFileRefresh_"

#define SYMBOL_TAB_CAPTION_STRING 'Symbol'
#define REFS_TAB_CAPTION_STRING   'Refs'

/**
 * Default size in kilobytes for tag file cache. 
 *
 * @default 64M
 * @categories Configuration_Variables
 */
int def_tagging_cache_size;
/**
 * If the current machine has lots of memory available, we can 
 * dedicate more memory to tagging cache.  This is the maximum 
 * amount we should stretch out the tagging cache to. 
 * If we can not get this much memory, we will at least get the 
 * amount specified in {@link def_tagging_cache_size}. 
 *
 * @default 192M
 * @categories Configuration_Variables
 */
int def_tagging_cache_max;
/**
 * Directories to be excluded from tagging. 
 *
 * @default nothing 
 * @categories Configuration_Variables
 */
_str def_tagging_excludes;

_str _last_wildcards;
#define PROJTOOLTAB_FILES      0
#define PROJTOOLTAB_PROCS      1
#define PROJTOOLTAB_CLASSES    2
#define PROJTOOLTAB_OPEN       3

#define OUTPUTTOOLTAB_SEARCH 0
#define OUTPUTTOOLTAB_SYMBOL 1
#define OUTPUTTOOLTAB_REFS   2
#define OUTPUTTOOLTAB_SHELL  3
#define OUTPUTTOOLTAB_OUTPUT 4
#define OUTPUTTOOLTAB_XMLOUT OUTPUTTOOLTAB_OUTPUT

#endif

int def_open_style;

enum OpenStyle {
   OPEN_BROWSE_FOR_FILES,
   OPEN_SMART_OPEN,
};

boolean def_prompt_open_style;

/**
 * Use the Mac-style save prompt (Save/Don't Save/Cancel) on Mac
 * OS X. If false, Windows-style Yes/No/Cancel buttons are used.
 */
boolean def_mac_save_prompt_style;

/**
 * Use Recycle Bin on Windows, or Trash on Mac, when deleting a
 * file from the Open toolwindow
 */
boolean def_delete_uses_recycle_bin;

#if __UNIX__
/**
 * Unix command to be used to send files to the trash when 
 * {@link recycle_file} is called. Ignored on Windows and Mac. 
 * Not required unless the trash command cannot be determined. 
 *  
 * Use %f as the placeholder where the file path should be 
 * specified. Do not use quotes, as the file path will be quoted 
 * if necessary. 
 * @example trash_a_file --file %f 
 */
_str def_trash_command;
#endif

/**
 * The same options dialog is used for many purposes.  This is a list of them.
 */
enum OptionsPurpose {
   OP_CONFIG,                    // regular old options configuration
   OP_EXPORT,                    // used to display export groups
   OP_IMPORT,                    // used to display an import package
   OP_QUICK_START                // the quick start configuration wizard
};

#define OPTIONS_CHOICE_DELIMITER '*+*'

#define ALL_LANGUAGES_ID         '*ALL_LANGUAGES*'

/**
 * These define events that may need to be triggered when certain options 
 * change. 
 */
enum_flags OptionsChangeEventFlags {
   OCEF_RESTART,
   OCEF_MENU_BIND,
   OCEF_REINIT_SOCKET,
   OCEF_WRITE_COMMENT_BLOCKS,
   OCEF_LOAD_USER_LEXER_FILE,
   OCEF_TAGGING_RESTART,
   OCEF_THREAD_RESTART,
   OCEF_DIALOG_FONT_RESTART,
};

#define OPTIONS_ERROR_DELIMITER  '*:*'

enum OptionsPanelSwitchReason {
   OPTIONS_SWITCHING,
   OPTIONS_APPLYING,
   OPTIONS_CANCELLING,
};

#define OPTIONS_CHANGE_CALLBACK_KEY  "options_change_callback_key"

#define VSEMBEDDED_BOTH      0
#define VSEMBEDDED_IGNORE    1
#define VSEMBEDDED_ONLY      2

enum_flags AutoCodeInfoFlags {

   // Do function argument help
   VSAUTOCODEINFO_DO_FUNCTION_HELP                    = 0x1,

   // Do auto-list members of class or list-symbols
   VSAUTOCODEINFO_DO_LIST_MEMBERS                     = 0x2,

   // the identifier is followed by a parenthesis
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN            = 0x4,

   // Indicate function argument help has been 
   // requested for template class type declaration.
   //    stack<...
   VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST                 = 0x8,

   // C++ class initializer list
   //    MYCLASS::MYCLASS(..): a(
   VSAUTOCODEINFO_IN_INITIALIZER_LIST                 = 0x10,

   // Argument list for call using function pointer
   //    (*pfn)(a,b...
   VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST         = 0x10,

   // May be in C++ class initializer list
   //    MYCLASS(..): a(
   VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST           = 0x20,

   // Either var with parenthesized initializer
   // or a prototype declaration.
   //    MYCLASS a(
   VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL               = 0x40,

   // Option to _c_fcthelp_get to just check in
   // cursor is inside template declaration.
   VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST            = 0x80,

   // True if an operator was typed rather than an 
   // explicit list-members or function argument 
   // help command.
   VSAUTOCODEINFO_OPERATOR_TYPED                      = 0x100,

   // True if context is after goto keyword
   //    goto label;
   VSAUTOCODEINFO_IN_GOTO_STATEMENT                   = 0x200,

   // True if context is after throw keyword
   //    throw excepshun;
   VSAUTOCODEINFO_IN_THROW_STATEMENT                  = 0x400,

   // Needed for BASIC like languages like SABL
   VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS         = 0x800,

   // List syntax expansion choices (kind of obsolete)
   VSAUTOCODEINFO_DO_SYNTAX_EXPANSION                 = 0x1000,

   // void foo::bar(), foo refers to class only
   VSAUTOCODEINFO_NOT_A_FUNCTION_CALL                 = 0x2000,

   // #<here>
   VSAUTOCODEINFO_IN_PREPROCESSING                    = 0x4000,

   // In javadoc comment or XMLDoc comment
   VSAUTOCODEINFO_IN_JAVADOC_COMMENT                  = 0x8000,

   // auto list parameters (type analysis)
   VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS                 = 0x10000,

   // in string or numeric argument
   VSAUTOCODEINFO_IN_STRING_OR_NUMBER                 = 0x20000,

   // has '*' or '&' as part of prefixexp
   VSAUTOCODEINFO_HAS_REF_OPERATOR                    = 0x40000,

   // has [] array accessor after lastid
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET          = 0x80000,

   // import MYCLASS;
   VSAUTOCODEINFO_IN_IMPORT_STATEMENT                 = 0x100000,

   // class CName; struct tm; union Boss;
   VSAUTOCODEINFO_HAS_CLASS_SPECIFIER                 = 0x200000,

   // x * y, cursor on *
   VSAUTOCODEINFO_CPP_OPERATOR                        = 0x400000,

   // #include <here>
   VSAUTOCODEINFO_IN_PREPROCESSING_ARGS               = 0x800000,

   // mask for context tagging actions
   VSAUTOCODEINFO_DO_ACTION_MASK = (VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_DO_LIST_MEMBERS|VSAUTOCODEINFO_OPERATOR_TYPED),

   // Objective-C specific tagging case
   VSAUTOCODEINFO_OBJECTIVEC_CONTEXT                  = 0x1000000,

   // SlickEdit reserves the first 28 bits.  You may
   // use the other 4 bits for anything you want.
   VSAUTOCODEINFO_USER1                               = 0x10000000,
   VSAUTOCODEINFO_USER2                               = 0x20000000,
   VSAUTOCODEINFO_USER3                               = 0x40000000,
   VSAUTOCODEINFO_USER4                               = 0x80000000,
};

struct VSAUTOCODE_ARG_INFO {
   _str prototype;
   int argstart[];    // 0..# of arguments in prototype.  Start pos of this arg
                      // argstart[0] is start of function name.
   int arglength[];   // 0..# of arguments in prototype.  Start pos of this arg
                      // arglength[0] is length of function name.
                      // arglength[i]==0 indicates nothing to do.

   int ParamNum;      // 0..# of arguments -1.  Argument to highlight
                      // -1 indicates highlight nothing.

   _str ParamName;    // Name of current argument

   _str ParamType;    // declared type of current argument (ParamNum)

   struct {
      _str filename;     // Filename containing a tag
      int linenum;       // line number of a tag.
      int comment_flags; // ORed VSCODEHELP_COMMENTFLAG_?? flags or 0
      _str comments;     // Comments of a tag.  Set this to null
                         // and set taginfo if you want to defer retrieving
                         // the comments like we typically do.
      _str taginfo;      // Typically this is tag specification built by
                         // tag_tree_compose_tag or tag_tree_compose_fast.

   } tagList[];   // Array of information for retrieving comments
                  // The first element in this array is for this tag.
                  // Subsequent entries are for duplicates.  For
                  // example, a proc and a proto with the same signature
                  // may both has comments.
};

int def_tag_max_function_help_protos;
int def_tag_max_list_members_symbols;
int def_tag_max_list_matches_symbols;
int def_tag_max_list_matches_time;
int def_tag_max_list_members_time;
int def_tag_max_find_context_tags;

#if __OS390__ || __TESTS390__
   #define VSCODEHELP_MAXFUNCTIONHELPPROTOS    50
   #define VSCODEHELP_MAXLISTGLOBALSYMBOLS     50
   #define VSCODEHELP_MAXLISTMEMBERSSYMBOLS   500
   #define VSCODEHELP_MAXLISTMATCHESSYMBOLS   100
   #define VSCODEHELP_MAXLISTMATCHESTIME     1000  /* milliseconds */
   #define VSCODEHELP_MAXLISTMEMBERSTIME     1000  /* milliseconds */
   #define VSCODEHELP_MAXFINDCONTEXTTAGS      300
   #define VSCODEHELP_MAXSKIPPREPROCESSING    100
   #define VSCODEHELP_MAXRECURSIVETYPESEARCH   32
#else
   #define VSCODEHELP_MAXFUNCTIONHELPPROTOS   100
   #define VSCODEHELP_MAXLISTGLOBALSYMBOLS    100
   #define VSCODEHELP_MAXLISTMEMBERSSYMBOLS  1000
   #define VSCODEHELP_MAXLISTMATCHESSYMBOLS   200
   #define VSCODEHELP_MAXLISTMATCHESTIME     1000  /* milliseconds */
   #define VSCODEHELP_MAXLISTMEMBERSTIME     1000  /* milliseconds */
   #define VSCODEHELP_MAXFINDCONTEXTTAGS     1000
   #define VSCODEHELP_MAXSKIPPREPROCESSING    100
   #define VSCODEHELP_MAXRECURSIVETYPESEARCH   64
#endif

#define VSCODEHELP_COMMENTFLAG_HTML     0x1
#define VSCODEHELP_COMMENTFLAG_JAVADOC  0x2
#define VSCODEHELP_COMMENTFLAG_XMLDOC   0x4
#define VSCODEHELP_COMMENTFLAG_DOXYGEN  0x8


// BIT FLAGS for _ext_get_return_type_of_prefix related functions
#define VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS  0x0002
#define VSCODEHELP_RETURN_TYPE_CONST_ONLY      0x0004
#define VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY   0x0008
#define VSCODEHELP_RETURN_TYPE_STATIC_ONLY     0x0010
#define VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY    0x0020
#define VSCODEHELP_RETURN_TYPE_ARRAY           0x0040
#define VSCODEHELP_RETURN_TYPE_HASHTABLE       0x0080
#define VSCODEHELP_RETURN_TYPE_HASHTABLE2      0x0100
#define VSCODEHELP_RETURN_TYPE_OUT             0x0200
#define VSCODEHELP_RETURN_TYPE_REF             0x0400
#define VSCODEHELP_RETURN_TYPE_ARRAY_TYPES     (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2)
#define VSCODEHELP_RETURN_TYPE_INCLASS_ONLY    0x0800
#define VSCODEHELP_RETURN_TYPE_FILES_ONLY      0x1000
#define VSCODEHELP_RETURN_TYPE_FUNCS_ONLY      0x2000
#define VSCODEHELP_RETURN_TYPE_DATA_ONLY       0x4000
#define VSCODEHELP_RETURN_TYPE_BUILTIN         0x8000

/*
   Specify the VSBMFLAG_SHOWNAME if you want the bookmark
   name displayed at the left edge of the edit window.  Note
   that the user can select not to show any bookmark names
   on the left edge.
*/
#define VSBMFLAG_SHOWNAME     0x1
/*
   VSBMFLAG_STANDARD has the following effects:
     * bookmark is diplayed in bookmark list
     * next_bookmark and prev_bookmark will traverse this bookmark.
*/
#define VSBMFLAG_STANDARD     0x2

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
#define VSBMFLAG_PUSHED       0x4

/*
   Specify the VSBMFLAG_SHOWPIC if you want the bookmark
   bitmap displayed at the left edge of the edit window.
*/
#define VSBMFLAG_SHOWPIC      0x8

/*
    This flag is used to indicate that a bookmark represents an
    annotation.  Annotations are treated like regular bookmarks,
    but they can also have a verbose description and a hash table
    of attributes.
*/
#define VSBMFLAG_ANNOTATION   0x10

int def_max_bm_tags;
boolean def_use_workspace_bm;
boolean def_show_bm_tags;
boolean def_bm_show_picture;
boolean def_cleanup_pushed_bookmarks_on_quit;
boolean def_search_result_push_bookmark;

/**
 * SlickEdit RGB color of scroll markup for bookmarks. After 
 * changing this, you will have to restart the editor. 
 *
 * @categories Configuration_Variables
 */
int def_bm_scrollmarkup_color;



#define VSTBBORDER_BORDER    0x1
#define VSTBBORDER_GRABBARS  0x2

struct CMDUI {
   int menu_handle;   // 0 if not called from menu
   int menu_pos;      // undefined if menu_handle==0
   boolean inMenuBar; // undefined if menu_handle==0
   _str reserved;     // undefined
   int button_wid;    // 0 if not called from toolbar button
};

#define VSTBREFRESHBY_READ_ONLY                  1
#define VSTBREFRESHBY_UNDO                       2
#define VSTBREFRESHBY_REDO                       3
#define VSTBREFRESHBY_SELECTION                  4
#define VSTBREFRESHBY_CREATEDESTROY_MDICHILD     5
#define VSTBREFRESHBY_MDICHILD_WINDOW_STATE      6
#define VSTBREFRESHBY_ADDREMOVE_BOOKMARK         7
#define VSTBREFRESHBY_STARTSTOP_MACRO_RECORDING  8

#define VSTBREFRESHBY_PROJECT                    9
#define VSTBREFRESHBY_INTERNAL_CLIPBOARDS        10
#define VSTBREFRESHBY_SWITCHBUF                  11
#define VSTBREFRESHBY_APPLICATION_GOT_FOCUS      12
#define VSTBREFRESHBY_DEBUGGING                  13
#define VSTBREFRESHBY_BACK_FORWARD               14

// Start your own values here or just use this one
#define VSTBREFRESHBY_USER                       1000

// ALL TAG FILES in absolute format, duplicates removed
//    Project tags, all extension tag files, all global tag files
_str gtag_filelist[];
_str gtag_filelist_project[];
_str gtag_filelist_ext[];
boolean gtag_filelist_cache_updated;

 int gNoTagCallList;  // Delay tag file refresh calls to weed out duplicates
                      // initialized in stdcmds.e
#define VSSCC_OK                                  0

#if 0 //10:48am 3/31/2011
#define VSSCC_E_INITIALIZEFAILED                  -1
#define VSSCC_E_UNKNOWNPROJECT                    -2
#define VSSCC_E_COULDNOTCREATEPROJECT             -3
#define VSSCC_E_NOTCHECKEDOUT                     -4
#define VSSCC_E_ALREADYCHECKEDOUT                 -5
#define VSSCC_E_FILEISLOCKED                      -6
#define VSSCC_E_FILEOUTEXCLUSIVE                  -7
#define VSSCC_E_ACCESSFAILURE                     -8
#define VSSCC_E_CHECKINCONFLICT                   -9
#define VSSCC_E_FILEALREADYEXISTS                 -10
#define VSSCC_E_FILENOTCONTROLLED                 -11
#define VSSCC_E_FILEISCHECKEDOUT                  -12
#define VSSCC_E_NOSPECIFIEDVERSION                -13
#define VSSCC_E_OPNOTSUPPORTED                    -14
#define VSSCC_E_NONSPECIFICERROR                  -15
#define VSSCC_E_OPNOTPERFORMED                    -16
#define VSSCC_E_TYPENOTSUPPORTED                  -17
#define VSSCC_E_VERIFYMERGE                       -18
#define VSSCC_E_FIXMERGE                          -19
#define VSSCC_E_SHELLFAILURE                      -20
#define VSSCC_E_INVALIDUSER                       -21
#define VSSCC_E_PROJECTALREADYOPEN                -22
#define VSSCC_E_PROJSYNTAXERR                     -23
#define VSSCC_E_INVALIDFILEPATH                   -24
#define VSSCC_E_PROJNOTOPEN                       -25
#define VSSCC_E_NOTAUTHORIZED                     -26
#define VSSCC_E_FILESYNTAXERR                     -27
#define VSSCC_E_FILENOTEXIST                      -28
#endif

#define VSSCC_COMMAND_GET         0
#define VSSCC_COMMAND_CHECKOUT    1
#define VSSCC_COMMAND_CHECKIN     2
#define VSSCC_COMMAND_UNCHECKOUT  3
#define VSSCC_COMMAND_ADD         4
#define VSSCC_COMMAND_REMOVE      5
#define VSSCC_COMMAND_DIFF        6
#define VSSCC_COMMAND_HISTORY     7
#define VSSCC_COMMAND_RENAME      8
#define VSSCC_COMMAND_PROPERTIES  9
#define VSSCC_COMMAND_OPTION      10

#define SCC_CAP_REMOVE            0x00000001   // Supports the SCC_Remove command
#define SCC_CAP_RENAME            0x00000002   // Supports the SCC_Rename command
#define SCC_CAP_DIFF              0x00000004   // Supports the SCC_Diff command
#define SCC_CAP_HISTORY           0x00000008   // Supports the SCC_History command
#define SCC_CAP_PROPERTIES        0x00000010   // Supports the SCC_Properties command
#define SCC_CAP_RUNSCC            0x00000020   // Supports the SCC_RunScc command
#define SCC_CAP_GETCOMMANDOPTIONS 0x00000040   // Supports the SCC_GetCommandOptions command
#define SCC_CAP_QUERYINFO         0x00000080   // Supports the SCC_QueryInfo command
#define SCC_CAP_GETEVENTS         0x00000100   // Supports the SCC_GetEvents command
#define SCC_CAP_GETPROJPATH       0x00000200   // Supports the SCC_GetProjPath command
#define SCC_CAP_ADDFROMSCC        0x00000400   // Supports the SCC_AddFromScc command
#define SCC_CAP_COMMENTCHECKOUT   0x00000800   // Supports a comment on Checkout
#define SCC_CAP_COMMENTCHECKIN    0x00001000   // Supports a comment on Checkin
#define SCC_CAP_COMMENTADD        0x00002000   // Supports a comment on Add
#define SCC_CAP_COMMENTREMOVE     0x00004000   // Supports a comment on Remove
#define SCC_CAP_TEXTOUT           0x00008000   // Writes text to an IDE-provided output function
#define SCC_CAP_ADD_STORELATEST   0x00200000   // Supports storing files without deltas
#define SCC_CAP_HISTORY_MULTFILE  0x00400000   // Multiple file history is supported
#define SCC_CAP_IGNORECASE        0x00800000   // Supports case insensitive file comparison
#define SCC_CAP_IGNORESPACE       0x01000000   // Supports file comparison that ignores white space
#define SCC_CAP_POPULATELIST      0x02000000   // Supports finding extra files
#define SCC_CAP_COMMENTPROJECT    0x04000000   // Supports comments on create project
#define SCC_CAP_REMOVE_KEEP       0x08000000   // Supports option to keep/delete local file on Remove
#define SCC_CAP_DIFFALWAYS        0x10000000   // Supports diff in all states if under control
#define SCC_CAP_GET_NOUI          0x20000000   // Provider doesn't support a UI for SccGet,
                                               //   but IDE may still call SccGet function.

#define VSSCC_STATUS_INVALID          -1     // Status could not be obtained, don't rely on it
#define VSSCC_STATUS_NOTCONTROLLED    0x0000 // File is not under source control
#define VSSCC_STATUS_CONTROLLED       0x0001 // File is under source code control
#define VSSCC_STATUS_CHECKEDOUT       0x0002 // Checked out to current user at local path
#define VSSCC_STATUS_OUTOTHER         0x0004 // File is checked out to another user
#define VSSCC_STATUS_OUTEXCLUSIVE     0x0008 // File is exclusively check out
#define VSSCC_STATUS_OUTMULTIPLE      0x0010 // File is checked out to multiple people
#define VSSCC_STATUS_OUTOFDATE        0x0020 // The file is not the most recent
#define VSSCC_STATUS_DELETED          0x0040 // File has been deleted from the project
#define VSSCC_STATUS_LOCKED           0x0080 // No more versions allowed
#define VSSCC_STATUS_MERGED           0x0100 // File has been merged but not yet fixed/verified
#define VSSCC_STATUS_SHARED           0x0200 // File is shared between projects
#define VSSCC_STATUS_PINNED           0x0400 // File is shared to an explicit version
#define VSSCC_STATUS_MODIFIED         0x0800 // File has been modified/broken/violated
#define VSSCC_STATUS_OUTBYUSER        0x1000 // File is checked out by current user someplace

#define VSSCC_PROJECT_NAME      1
#define VSSCC_LOCAL_PATH        2
#define VSSCC_AUX_PATH_INFO     3
#define VSSCC_PROVIDER_DLL_PATH 4
#define VSSCC_PROVIDER_NAME     5

#define SCC_PREFIX        'SCC:'
#define SCC_PREFIX_LENGTH 4

_str def_vc_system;     //The current vcs

#define VCS_CHECKOUT           'checkout'
#define VCS_CHECKIN_NEW        'checkin_new'
#define VCS_CHECKIN            'checkin'
#define VCS_CHECKOUT_READ_ONLY 'checkout_read_only'
#define VCS_CHECKIN_DISCARD    'checkin_discard'
#define VCS_PROPERTIES         'properties'
#define VCS_DIFFERENCE         'difference'
#define VCS_HISTORY            'history'
#define VCS_REMOVE             'remove'
#define VCS_LOCK               'lock'
#define VCS_MANAGER            'manager'
#define NULL_COMMENT _chr(0)

#define READ_ONLY_ERROR_MESSAGE 'This command is not allowed in read only mode'

  int _in_firstinit;

int _chdebug;
boolean ginFunctionHelp;
boolean gFunctionHelp_pending;

#define RBFORM_CHECKBOXES 0x1

#define DIFF_REPORT_CREATED              0x1
#define DIFF_REPORT_LOADED               0x2
#define DIFF_REPORT_DIFF                 0x4
#define DIFF_REPORT_FILE_CHANGE          0x8
#define DIFF_REPORT_COPY_FILE           0x10
#define DIFF_REPORT_COPY_TREE           0x20
#define DIFF_REPORT_COPY_TREE_FILE      0x40
#define DIFF_REPORT_DELETE_FILE         0x80
#define DIFF_REPORT_DELETE_TREE        0x100
#define DIFF_REPORT_DELETE_TREE_FILE   0x200
#define DIFF_REPORT_SAVED_DIFF_STATE   0x400
#define DIFF_REPORT_SAVED_PATH1_LIST   0x800
#define DIFF_REPORT_SAVED_PATH2_LIST  0x1000
#define DIFF_REPORT_REFRESH_CHANGED   0x2000
#define DIFF_REPORT_REFRESH_ALL       0x4000

/**
 * Set this variable to 1 to change the current working 
 * directory to the file that currently has focus in the editor.
 * This variable is on by default in the GNU Emacs emulation, 
 * and off in all other emulations. 
 * @categories Configuration_Variables 
 */ 
boolean def_switchbuf_cd;
boolean _hit_defmain;


#define HKEY_CLASSES_ROOT           ( 0x80000000 )
#define HKEY_CURRENT_USER           ( 0x80000001 )
#define HKEY_LOCAL_MACHINE          ( 0x80000002 )
#define HKEY_USERS                  ( 0x80000003 )
#define HKEY_PERFORMANCE_DATA       ( 0x80000004 )
#define HKEY_CURRENT_CONFIG         ( 0x80000005 )
#define HKEY_DYN_DATA               ( 0x80000006 )

#define DIFF_LIST_FILE_EXT 'dls'
#define DIFF_STATEFILE_EXT 'dif'

#define VSIMPLEMENT_ABSTRACT  0x1

enum_flags VSCodeHelpFlags {
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
};

int def_codehelp_flags;       // bitset of VSCODEHELPFLAG_*

// Timeout for trying a UNC path \\server\share\...
int def_fileio_timeout;
// continue to timeout after failure of def_fileio_timeout for
// this amount of time.
int def_fileio_continue_to_timeout;
/**
 * Delay in milliseconds before auto-list members
 * pops up after you type a member access operator such as '->'.
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
 * @default 2
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
 * @default 500
 * @categories Configuration_Variables
 */
int def_background_tagging_maximum_jobs;
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
boolean def_background_tagging_minimize_write_locking;

#define VSCODEHELPDCLFLAG_VERBOSE     0x1
#define VSCODEHELPDCLFLAG_SHOW_CLASS  0x2
#define VSCODEHELPDCLFLAG_SHOW_ACCESS 0x4
#define VSCODEHELPDCLFLAG_SHOW_INLINE 0x8
#define VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF 0x10
#define VSCODEHELPDCLFLAG_SHOW_STATIC 0x20

// p_ProtectReadOnlyMode values
#define VSPROTECTREADONLYMODE_OPTIONAL 0
#define VSPROTECTREADONLYMODE_ALWAYS   1
#define VSPROTECTREADONLYMODE_NEVER    2

boolean def_word_continue;

#define VSCURWORD_WHOLE_WORD       0
#define VSCURWORD_FROM_CURSOR      1
#define VSCURWORD_AT_END_USE_PREV  2
#define VSCURWORD_BEFORE_CURSOR    3

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
extern boolean _findFirstTimeOut(_str pszFilename, int milliTimeout,int milliContinueToFail);

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


#define VSCHARSET_ANSI            0
#define VSCHARSET_DEFAULT         1
#define VSCHARSET_SYMBOL          2
#define VSCHARSET_SHIFTJIS        128
#define VSCHARSET_HANGEUL         129
#define VSCHARSET_GB2312          134
#define VSCHARSET_CHINESEBIG5     136
#define VSCHARSET_OEM             255
#define VSCHARSET_JOHAB           130
#define VSCHARSET_HEBREW          177
#define VSCHARSET_ARABIC          178
#define VSCHARSET_GREEK           161
#define VSCHARSET_TURKISH         162
#define VSCHARSET_THAI            222
#define VSCHARSET_EASTEUROPE      238
#define VSCHARSET_RUSSIAN         204
#define VSCHARSET_MAC             77
#define VSCHARSET_BALTIC          186
#define VSCHARSET_VIETNAMESE      163

#define VSCOBOL_SQL_LEXER_NAME    "def-cobol-sql-lexer-name"
#define VSHTML_ASP_LEXER_NAME     "def-html-asp-lexer-name"


#define VC_ADVANCED_PROJECT       0x1
#define VC_ADVANCED_BUFFERS       0x2
#define VC_ADVANCED_AVAILABLE     0x4
#define VC_ADVANCED_NO_SAVE_FILES 0x8
#define VC_ADVANCED_NO_PROMPT     0x10

int def_vc_advanced_options;
int def_smart_diff_limit;
int def_max_fast_diff_size;
int def_optimize_sccprjfiles;

#define PROJECT_TOOLBAR_NAME '_proj_tooltab_tree'

int def_record_dataset_mode;   // For now set this to 0 or 1

#define REGULAR_ALIAS_FILE 0
#define DOCCOMMENT_ALIAS_FILE 1
#define SYMTRANS_ALIAS_FILE 2
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
#define EB_ASCII_0 48
#define EB_ASCII_9 57
#define EB_ASCII_a 97
#define EB_ASCII_z 122
#define EB_ASCII_A 65
#define EB_ASCII_Z 90
#define EB_ASCII_SPACE 32
#define EB_ASCII_UNDERSCORE 95

int _ftpsave_override;

_str _last_open_path;
_str _last_open_cwd;

#define SPACEUNIT_BLOCKS 1
#define SPACEUNIT_TRACKS 2
#define SPACEUNIT_CYLS 3
#define SPACEUNIT_KB 4
#define SPACEUNIT_MB 5
#define RECFM_F 1
#define RECFM_V 2
#define RECFM_FB 3
#define RECFM_VB 4
#define RECFM_FBS 5
#define RECFM_VBS 6
#define DSORG_PO 1
#define DSORG_POU 2
#define DSORG_PS 3
#define DSORG_PSU 4

// Common to all beautifiers/formatters
_str _format_user_ini_filename;

// cformat
#define CF_DEFAULT_SCHEME_NAME "Default"

// hformat
#define HF_DEFAULT_SCHEME_NAME "Default"

// adaformat
#define ADAF_DEFAULT_SCHEME_NAME "Default"

enum KeywordCaseValues {
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
   boolean m_landscape;
   boolean m_selection;
   boolean m_haveSelection;
   int m_copyCount;
   boolean m_collate;
};
struct SEQtPageSetupOptions {
   boolean m_landscape;
};
extern int _QtPageSetupDialog(SEQtPrintOptions &options,boolean show);
extern int _QtPrintDialog(SEQtPrintOptions &options,boolean show);
extern void _QtPrintDialogRestore(SEQtPrintOptions &options);

#define END_SENTENCE_CHARS '.!?'
#define END_OF_SENTENCE_RE '((.|!|\?)[.!?"'')\]]*\c($|  ))'
#define PARAGRAPH_SKIP_CHARS ' \t'
#define PARAGRAPH_SEP_RE      ('(^['PARAGRAPH_SKIP_CHARS']*$)')
#define SKIP_PARAGRAPH_SEP_RE ('^~(['PARAGRAPH_SKIP_CHARS']*$)')
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
boolean _mfrefIsActive;
boolean _mfXMLOutputIsActive;

#define PROJPROPTAB_FILES 0
#define PROJPROPTAB_DIRECTORIES 1
#define PROJPROPTAB_TOOLS 2
#define PROJPROPTAB_BUILDOPTS 3
#define PROJPROPTAB_OPENCOMMAND 4
// ProjectPacks defines all the values for a project pack.
boolean def_error_check_help_items;

/**
 * Set this to 'false' to disable all AutoSave and Context Tagging&reg; 
 * timer functions.  This is for debugging purposes only.  This 
 * variable should NEVER be modified programatically.  If you want to 
 * just turn off timers temporarily use _use_timers instead. 
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_use_timers/*=true*/;
/**
 * This variable can be used to temporarily disable all AutoSave
 * and Context Tagging&reg; timer functions.  This is reset to 1 
 * every time the editor is started.  To permanently disable 
 * timer functions, set def_use_timers to 0. 
 */
int _use_timers/*=1*/;


#define VSJAVADOCFLAG_BEAUTIFY         0x1
#define VSJAVADOCFLAG_ALIGN_PARAMETERS 0x2
#define VSJAVADOCFLAG_ALIGN_EXCEPTIONS 0x4
#define VSJAVADOCFLAG_BLANK_LINE_AFTER_PARAMETERS  0x8
#define VSJAVADOCFLAG_BLANK_LINE_AFTER_RETURN      0x10
#define VSJAVADOCFLAG_BLANK_LINE_AFTER_DESCRIPTION 0x20
#define VSJAVADOCFLAG_ALIGN_RETURN     0x40
#define VSJAVADOCFLAG_ALIGN_DEPRECATED 0x80
#define VSJAVADOCFLAG_BLANK_LINE_AFTER_EXAMPLE     0x100
#define VSJAVADOCFLAG_BLANK_LINE_AFTER_LAST_PARAM  0x200
#define VSJAVADOCFLAG_DEFAULT_ON                   (0xffff00)
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

boolean def_project_auto_build;

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


_command void first_non_blank(...);


_command void end_line();
_command void end_line_text_toggle();


_command int cursor_up(_str count='',_str doScreenLines='');


_command int cursor_down(_str count='',_str doScreenLines='');
_command void top_of_buffer();



_command void bottom_of_buffer();
_command void page_up();
_command void page_down();


_command void cursor_left(...);


_command void cursor_right(...);


_command void delete_char(_str force_wrap='');
_command void linewrap_delete_char();
_command void rubout(_str force_wrap='');
_command void linewrap_rubout();
_command void top_of_window();


_command void bottom_of_window();
_command void split_line();
_command int join_line(_str stripLeadingSpaces='');


_command int begin_select(_str markid='',boolean LockSelection=true,boolean RestoreScrollPos=false);

_command end_select(_str markid='');
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
_command void process_enter();
_command void process_begin_line();
_command void process_up();
_command void process_down();
_command void process_rubout();

_command _str cload(...);


_command color_modified_toggle();
_command color_language_toggle();

_command color_toggle();
_command keyin_space();
_command keyin_enter();

_command delete_word();


_command cut_word();
_command void next_word();

_command void complete_prev(_str exactMatch='');


_command void complete_next(_str exactMatch='');

_command complete_more();
_command int save(_str cmdline='',int flags= -1);


_command void c_endbrace();
_command wh(_str word="");
_command void re_toggle();

_command void case_toggle();
_command void list_symbols();
_command void codehelp_complete();
_command void function_argument_help();
_command int paste(_str name='',boolean isClipboard=true);


_command void cua_select();


_command int copy_to_clipboard(_str name='');
_command int mou_click(_str mark_name="",
                       _str option="",  /* C, M, or E  == Copy, Move, Extend */
                       boolean select_words=false);
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
_str get_extension(_str buf_name,boolean returnDot=false);
int _xml_get_error_info(int iHandle, int errIndex, int &line, int &col, _str &fn, _str &msg);
int _xmlcfg_find_simple_array(int iHandle,_str QueryStr,_str (&Array)[],
                              int NodeIndex=TREE_ROOT_INDEX,int FindFlags=0);
void split(_str delimited_string, _str delimiter, _str (&string_array)[]);
void _UpdateSlickCStack(int ignoreNStackItems=0,int errorCode=0,_str DumpFileName="");
void messageNwait(_str msg="");

/**
 * List of file extensions of files that are identified to
 * the project system as dependencies when loading a project
 * from a Makefile.
 *
 * @default '.h .hpp .hxx'
 * @categories Configuration_Variables
 */
_str def_add_to_prj_dep_ext;

/**
 * Options for the symbol referencing system.  This is a bitset 
 * of the following flags. 
 *  
 * <ul> 
 * <li><b>VSREF_FIND_INCREMENTAL</b> -- 
 * Find references incrementally instead of searching all 
 * matching files right away. 
 * </li>
 * <li><b>VSREF_DO_NOT_GO_TO_FIRST</b> -- 
 * Just find the references, do not navigate to the first 
 * reference when the references search is invoked.</li> 
 * <li><b>VSREF_NO_WORKSPACE_REFS</b> -- 
 * Do not build workspace tag files with 
 * cross-referencing indexes by default.</li> 
 * <li><b>VSREF_HIGHLIGHT_MATCHES</b> -- 
 * Highlight references matches in the editor.</li>
 * <li><b>VSREF_SEARCH_WORDS_ANYWAY</b> -- 
 * Search for word matches if a symbol can not be found 
 * by the tagging system.</li>
 * <li><b>VSREF_ALLOW_MIXED_LANGUAGES</b> -- 
 * Allow a references search to include files that are 
 * in different language modes.</li>
 * </ul>
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_references_options;

#define MACRO_MAKE_RE '(tornadomake|javaviewdoc|tornadorebuild)([ \t]|$)'

// p_LCBufFlags
#define VSLCBUFFLAG_READWRITE          0x1  /* prefix area on/off*/
#define VSLCBUFFLAG_LINENUMBERS        0x2  /* Line numbers on/off */
#define VSLCBUFFLAG_LINENUMBERS_AUTO   0x4  /* Line numbers automatic*/
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
   boolean result_doAll; // Set by find()
   int result_startCol;  // Set by find()
   int result_endCol;    // Set by find()
   _str orig_searchString;  // Unprocessed search string
   _str searchOptions;
};
 VSSEARCH_BOUNDS old_search_bounds;
#define VSLCFLAG_ERROR         0x1
#define VSLCFLAG_CHANGE        0x2
#define VSLCFLAG_BOUNDS        0x4
#define VSLCFLAG_MASK          0x8
#define VSLCFLAG_COLS          0x10
#define VSLCFLAG_TABS          0x20

enum_flags VSRenumberFlags {
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
boolean def_ispf_xedit;
_str def_page;
boolean _dos_NextErrorIfNonZero;
boolean _dos_quiet;

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

//boolean def_ispf_autosave;
boolean ispf_process_return(boolean nullReturn);

#define TREE_BUTTON_PUSHED     0x1

//These are mutually exclusive
#define TREE_BUTTON_PUSHBUTTON 0x2
#define TREE_BUTTON_STICKY     0x4

#define TREE_BUTTON_SORT            0x8
#define TREE_BUTTON_SORT_EXACT      0x10
#define TREE_BUTTON_SORT_DESCENDING 0x20  //Do not specify this flag,used internally
#define TREE_BUTTON_SORT_NUMBERS    0x40
#define TREE_BUTTON_SORT_FILENAME   0x80

#define TREE_BUTTON_AL_RIGHT        0x100
#define TREE_BUTTON_AL_CENTER       0x200

// This flag is no longer used, use _TreeSetColEditStyle 
// and_TreeSetNodeEditStyle with the TreeEditStyle flags instead
//#define TREE_BUTTON_EDITABLE        0x400

#define TREE_BUTTON_WRAP            0x800
#define TREE_BUTTON_FIXED_WIDTH     0x1000
#define TREE_BUTTON_AUTOSIZE        0x2000  // Currently only works on the last button
#define TREE_BUTTON_IS_FILENAME     0x4000  // Elide filename if column isn't wide enough

// This flag is no longer used, use _TreeSetColEditStyle 
// and_TreeSetNodeEditStyle with the TreeEditStyle flags instead
//#define TREE_BUTTON_COMBO           0x8000

#define TREE_BUTTON_IS_DATETIME     0x10000  // localize from _time('B')
#define TREE_BUTTON_SORT_COLUMN_ONLY 0x20000  // only sort by the selected column

#define TREE_BUTTON_SORT_DATE               0x40000  // Can be used in conjunction with TREE_BUTTON_SORT_TIME
#define TREE_BUTTON_SORT_TIME               0x80000  // Can be used in conjunction with TREE_BUTTON_SORT_DATE

enum TreeEditStyle {
   TREE_EDIT_TEXTBOX                = 0x1,
   TREE_EDIT_COMBOBOX               = 0x2,
   TREE_EDIT_EDITABLE_COMBOBOX      = 0x4,
   TREE_EDIT_BUTTON                 = 0x8,
};

#define TREE_GRID_NONE 0x0
#define TREE_GRID_HORZ 0x1
#define TREE_GRID_VERT 0x2
#define TREE_GRID_BOTH 0x3
#define TREE_GRID_ALTERNATE_ROW_COLORS 0x4

#define VSMIGFLAG_ALIASES        0x1
#define VSMIGFLAG_COMMENTSTYLE 0x2
#define VSMIGFLAG_COLORCODING  0x4
#define VSMIGFLAG_BEAUTIFIER   0x8
#define VSMIGFLAG_VCS          0x10
#define VSMIGFLAG_PACKAGES     0x20
#define VSMIGFLAG_FTP          0x40
#define VSMIGFLAG_COLORSCHEMES 0x80
#define VSMIGFLAG_PRINTSCHEMES 0x100
int def_migrate_flags;

#define VSMHFINDANAMEFLAG_INCREASE_HEIGHT 0x1
#define VSMHFINDANAMEFLAG_CENTER_SCROLL   0x2

/**
 * Expected indentation columns corresponding to different
 * cobol data section level numbers.  Speace separated list
 * of pairs (level=column).
 *
 * @default '01=8 03=12 05=16 07=20 77=8 88=8';
 * @categories Configuration_Variables
 */
_str def_cobol_levels;
int def_max_workspacehist;


struct VSAUTOLOADEXT {
   _str macroName;
   _str modeName;
};
VSAUTOLOADEXT gAutoLoadExtHashtab:[];

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
boolean def_always_prompt_for_else_if;


/**
 * Indent C++ member access specifiers, public: private: 
 * protected: in classes and structs.  False indicates to indent 
 * with class/struct column. 
 *  
 * @default false
 * @categories Configuration_Variables
 */
boolean def_indent_member_access_specifier;

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
int def_surround_mode_options/*=0xffff*/;

#define VS_SURROUND_MODE_ENABLED    0x0001
#define VS_SURROUND_MODE_DRAW_BOX   0x0002
#define VS_SURROUND_MODE_JUMP_FAST  0x0004
#define VS_SURROUND_MODE_EDITABLE   0x0008
#define VS_SURROUND_MODE_DRAW_ARROW 0x0010


_str _html_tempfile; //Used for running applets
_str _vcpp_compiler_option_tempfile; //Used for options to compile files
#define C_DEL_TAG_PREFIX "//DEL "

struct WIZARD_INFO {
   _str parentFormName;
   typeless callbackTable:[];
   _str dialogCaption;
   typeless wizardData;
};

#define VSMISCDATASETSUFFIX ".VSLICK.MISC"
#define VSTMPOUTPUTDATASETSUFFIX ".VSLICK.TEMP.OUTPUT"
#define VSTMPJCLDATASETSUFFIX ".VSLICK.TEMP.JCL"

#if __UNIX__
   #define VSSAMPLEWORKSPACECPP 'ucpp/'
   #define VSSAMPLEWORKSPACEJAVA 'java/'
#else
   #define VSSAMPLEWORKSPACECPP 'DevStudio\cpp\'
   #define VSSAMPLEWORKSPACEJAVA 'java\'
#endif

#define WORKSPACE_OPT_COPYSAMPLES 0x1
int def_workspace_options;

_str def_tornado_version;
int _trialMessageDisplayedFlags1;
boolean def_focus_select;
#define NULL_MARKID  -1


#define VSXML_VALIDATION_SCHEME_WELLFORMEDNESS  0x1
#define VSXML_VALIDATION_SCHEME_VALIDATE        0x2
#define VSXML_VALIDATION_SCHEME_AUTO            (VSXML_VALIDATION_SCHEME_WELLFORMEDNESS | VSXML_VALIDATION_SCHEME_VALIDATE)



#define VSXMLCFG_FIND_APPEND       0x1
#define VSXMLCFG_FIND_VALUES       0x2

#define VSXMLCFG_ELEMENT_START                   0x1
#define VSXMLCFG_ELEMENT_END                     0x2
#define VSXMLCFG_ELEMENT_XML_DECLARATION         0x4
#define VSXMLCFG_ELEMENT_PROCESSING_INSTRUCTION  0x8
#define VSXMLCFG_ELEMENT_COMMENT                 0x10
#define VSXMLCFG_ELEMENT_DOCTYPE                 0x20

#define VSXMLCFG_SAVE_ALL_ON_ONE_LINE              0x1
#define VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR         0x2
#define VSXMLCFG_SAVE_DOS_EOL                      0x4
#define VSXMLCFG_SAVE_UNIX_EOL                     0x8
#define VSXMLCFG_SAVE_SPACE_AROUND_EQUAL           0x10
#define VSXMLCFG_SAVE_CLOSE_BRACE_ON_SEPARATE_LINE 0x20
// PCDATA will not be automatically indented on a new line
// Ideal for cases like: <Tag>Value</Tag>
#define VSXMLCFG_SAVE_PCDATA_INLINE                0x40
// Add a trailing space after the last attribute quote, but only
// on nodes that are solely attributed.
// Example: <MyTag Name="Tag2" Value="Whatever" />
// This is a special case for Visual Studio XML project formats
// It includes the VSXMLCFG_SAVE_ALL_ON_ONE_LINE flag
#define VSXMLCFG_SAVE_SPACE_AFTER_LAST_ATTRIBUTE   (0x80 | VSXMLCFG_SAVE_ALL_ON_ONE_LINE)
#define VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE      0x100
#define VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE            0x200
#define VSXMLCFG_SAVE_PRESERVE_PCDATA_INDENT       0x400

#define VSXMLCFG_ADD_ATTR_AT_END        0
#define VSXMLCFG_ADD_ATTR_AT_BEGINNING  0x1

#define VSXMLCFG_ADD_AFTER        0x0  /* Add a node after sibling in order */
#define VSXMLCFG_ADD_BEFORE       0x1  /* Add a node before sibling in order */
#define VSXMLCFG_ADD_AS_CHILD     0x2  /* Add after last child */

#define VSXMLCFG_STATUS_INCOMPLETE       0x1
#define VSXMLCFG_STATUS_READ_INVALID_TAG 0x2
#define VSXMLCFG_STATUS_OPEN_ALREADY     0x4

//Name contains name of element.  Value is null.
#define VSXMLCFG_NODE_ELEMENT_START           0x1
//Name contains name of element.  Value is null.
#define VSXMLCFG_NODE_ELEMENT_START_END       0x2
//Name is set to "xml".   Attributes are set.  For compatibility with XPath,
//the _xmlcfg_find_XXX functions won't find these attributes
#define VSXMLCFG_NODE_XML_DECLARATION         0x4
//Name is set to the processor name (not including '?').  Value is set to
//all data after the processor name not including leading white space.
#define VSXMLCFG_NODE_PROCESSING_INSTRUCTION  0x8
//Name is set to null.  Value contains all data not
//including leading '!--' and trailing '--'.
#define VSXMLCFG_NODE_COMMENT                 0x10
//Name is set to "DOCTYPE".  For convience, the DOCTYPE information is stored
// as attributes so it can be more easily identified an modified.   A "root"
// attribute is set to the document root element specified.  A "PUBLIC" attribute
// is set to the public literal specified.  A "SYSTEM" attribute is set to the
// system literal.  A "DTD" attribute is set to the internal DTD subset.
// For compatibility with XPath, the _xmlcfg_find_XXX functions won't find these attributes.
#define VSXMLCFG_NODE_DOCTYPE                 0x20
//Name is set to attribute name.  Value is set to value of attribute not including quotes.
#define VSXMLCFG_NODE_ATTRIBUTE               0x40
//Name is set to null.  Value is set to the PCDATA text.
#define VSXMLCFG_NODE_PCDATA                  0x80
//Name is set to null.  Value is set to the CDATA text.
#define VSXMLCFG_NODE_CDATA                   0x100
#define VSXMLCFG_COPY_CHILDREN                0x200
#define VSXMLCFG_COPY_BEFORE                  VSXMLCFG_ADD_BEFORE
#define VSXMLCFG_COPY_AS_CHILD                VSXMLCFG_ADD_AS_CHILD


#define VSXMLCFG_OPEN_ADD_PCDATA  VSXMLCFG_OPEN_ADD_ALL_PCDATA

#define VSXMLCFG_OPEN_ADD_ALL_PCDATA  0x1
#define VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR  0x2
#define VSXMLCFG_OPEN_REFCOUNT              0x4
#define VSXMLCFG_OPEN_ADD_NONWHITESPACE_PCDATA  0x8
#define VSXMLCFG_OPEN_REFCOPY                   0x20
#define VSXMLCFG_OPEN_REINDENT_PCDATA           0x40
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

#define VSCP_ACTIVE_CODEPAGE     0
#define VSCP_FIRST            29999
#define VSCP_EBCDIC_SBCS           29999
#define VSCP_CYRILLIC_KOI8_R  30000
#define VSCP_ISO_8859_1       30001   /* Western European - Latin 1 */
#define VSCP_ISO_8859_2       30002   /* Central and Eastern Europe - Latin 2*/
#define VSCP_ISO_8859_3       30003   /* Esperanto - Latin 3 */
#define VSCP_ISO_8859_4       30004   /* Latin 4 */
#define VSCP_ISO_8859_5       30005   /* Cyrillic */
#define VSCP_ISO_8859_6       30006   /* Arabic */
#define VSCP_ISO_8859_7       30007   /* Greek */
#define VSCP_ISO_8859_8       30008   /* Hebrew */
#define VSCP_ISO_8859_9       30009   /* Latin 5 */
#define VSCP_ISO_8859_10      30010   /* Latin 6 */
#define VSCP_LAST             30010


#define VSENCODING_AUTOUNICODE         0x1
#define VSENCODING_AUTOXML             0x2
#define VSENCODING_AUTOEBCDIC          0x4
#define VSENCODING_AUTOUNICODE2        0x8
#define VSENCODING_AUTOEBCDIC_AND_UNICODE   (VSENCODING_AUTOEBCDIC|VSENCODING_AUTOUNICODE)
#define VSENCODING_AUTOEBCDIC_AND_UNICODE2   (VSENCODING_AUTOEBCDIC|VSENCODING_AUTOUNICODE2)
#define VSENCODING_AUTOHTML            0x10

#define VSENCODING_UTF8                    70
#define VSENCODING_UTF8_WITH_SIGNATURE     71
#define VSENCODING_UTF16LE                 72
#define VSENCODING_UTF16LE_WITH_SIGNATURE  73
#define VSENCODING_UTF16BE                 74
#define VSENCODING_UTF16BE_WITH_SIGNATURE  75
#define VSENCODING_UTF32LE                 76
#define VSENCODING_UTF32LE_WITH_SIGNATURE  77
#define VSENCODING_UTF32BE                 78
#define VSENCODING_UTF32BE_WITH_SIGNATURE  79
#define VSENCODING_MAX                     100
_str _xmlTempTagFileList:[];
boolean gmarkfilt_utf8;
int def_smarttab;  // Default extension specific setting

#define VSBPFLAG_BREAKPOINT        0x00000001    /* Break point on this line*/
#define VSBPFLAG_EXEC              0x00000002    /* Line about to be executed. */
#define VSBPFLAG_STACKEXEC         0x00000004    /* Call Stack execution line */
#define VSBPFLAG_BREAKPOINTDISABLED   0x00000008 /* Break point disabled*/


#define OEFLAG_REMOVE_FROM_OPEN  0x1
#define OEFLAG_REMOVE_FROM_SAVEAS 0x2
#define OEFLAG_BINARY             0x4
#define OEFLAG_REMOVE_FROM_DIFF   0x8
#define OEFLAG_REMOVE_FROM_NEW    0x10
//#define OEFLAG_KEEP_FOR_APPEND    0x8
int def_mfdiff_functions;

struct COMMENT_TYPE {
   //Applies to both
   int type;
   _str delim1;
   _str cf_or_l;
   int startcol;
   boolean isDocumentation;

   //Multiline specific
   _str delim2;
   _str colorname;
   int lastchar;
   int nesting;
   _str idchars;
   //_str keywords;
   //_str attributes:[];//3:02pm 1/6/1998 For html embedded languages

   //Line specific
   int endcol;
   int repeat;
   boolean precededbyblank;
   boolean backslashContinuation;
};

/**
 * Indicates whether or not to automatically un-indent when the
 * backspace key is pressed at the start of a first word on a
 * current line.
 */
enum_flags IndentFlags {
/**
 * Default value for indent flags.
 */
   VS_INDENT_FLAG_DEFAULT                          = 0x00000000,
   VS_INDENT_FLAG_BACKSPACE_UNINDENT               = 0x00000001,
};

enum_flags VSCommentEditingFlags {
   
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
}
/**
 * Default value for comment editing flags.
 */
#define VS_COMMENT_EDITING_FLAG_DEFAULT                  0xffffffef

/**
 * Set to the directory where the default JDK (Java Development Kit)
 * is installed.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_jdk_install_dir;

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

int def_max_makefile_menu; // Limit of number of makefiles/ant files display on build menu
int def_show_makefile_target_menu; // 0=disabled, 1=enabled, 2=only enabled on project toolbar (not on build menu)
int def_show_prjfiles_in_open_dlg; // 0=disabled, 1=enabled
int def_resolve_dependency_symlinks; // 0=no, 1=yes (this *must* always be 0 if not UNIX)

#define VSFILETYPE_NORMAL_FILE   1
#define VSFILETYPE_DATASET_FILE  2
#define VSFILETYPE_REMOTE_OS390_DATASET_FILE 3
#define VSFILETYPE_REMOTE_OS390_HFS_FILE     4
#define VSFILETYPE_JAR_FILE      5
#define VSFILETYPE_URL_FILE      6

_str def_url_proxy;
_str def_url_proxy_bypass;

/**
 * Default non-extension specific encoding load option.
 *
 * @default '+fautounicode'
 * @categories Configuration_Variables
 */
_str def_encoding;

/*
  This create option has been removed becaused it exagerated coding errors.
  For example,  create and XMLCFG file and then don't close it because of a bug.
  Next time you call _xmlcfg_open, you get the wrong file.
*/
#define VSXMLCFG_CREATE_IF_EXISTS_CLEAR   0
#define VSXMLCFG_CREATE_IF_EXISTS_OPEN    1
#define VSXMLCFG_CREATE_IF_EXISTS_ERROR   2
#define VSXMLCFG_CREATE_IF_EXISTS_CREATE  3

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

struct HTML_INSERT_TAG_ARGS {
   _str file_name;
   int line_no;
   _str class_name;
   int tag_flags;
   _str signature;
};

// Describe how auto validate should behave
// We need this because depending on how the file is opened
// we may want to limit or disable auto validate because
// it can interupt the user.  For example, if the user
// did a global multi file search.  Each time they hit
// move find next between files validation would occur
// which would switch the tab
//
int gXMLAutoValidateBehavior;
#define VSXML_AUTOVALIDATE_BEHAVIOR_DISABLE   -1
#define VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE     0
#define VSXML_AUTOVALIDATE_BEHAVIOR_NO_MOVE    1

#define CSIDL_PERSONAL                  0x0005
#define CSIDL_DESKTOP                   0x0010
#define CSIDL_LOCAL_APPDATA             0x001c
#define CSIDL_PROGRAM_FILES             0x0026
#define CSIDL_WINDOWS                   0x0024
#define CSIDL_COMMON_DOCUMENTS          0x002e

#define JAVADOCHREFINDICATOR _chr(1)

// Smarttab values
enum VSSmartTab {
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

int def_maxcombohist;  // Default maximum combo box retrieval list


// IMPORTANT: These two version #defines are deprecated and used
//            only for upgrading old projects.  All new code
//            should check VPW_FILE_VERSION and VPJ_FILE_VERSION instead.
#define PROJECT_FILE_VERSION 7.0
#define WORKSPACE_FILE_VERSION 8

// Version of workspace, project, template, and ext-specific project
// files supported by this release of Visual SlickEdit
// Version 8.1
#define VPT_FILE_VERSION81 8.1
#define VPJ_FILE_VERSION81 8.1
#define VPW_FILE_VERSION81 8.1
#define VPE_FILE_VERSION81 8.1

#define VPT_DTD_PATH81 "http://www.slickedit.com/dtd/vse/8.1/vpt.dtd"
#define VPJ_DTD_PATH81 "http://www.slickedit.com/dtd/vse/8.1/vpj.dtd"
#define VPW_DTD_PATH81 "http://www.slickedit.com/dtd/vse/8.1/vpw.dtd"
#define VPE_DTD_PATH81 "http://www.slickedit.com/dtd/vse/8.1/vpe.dtd"

#define VSDEBUG_DTD_PATH81 "http://www.slickedit.com/dtd/vse/8.1/vsdebugger.dtd"

// Version 9.0
#define VPT_FILE_VERSION90 9.0
#define VPJ_FILE_VERSION90 9.0
#define VPW_FILE_VERSION90 9.0
#define VPE_FILE_VERSION90 9.0

#define VPT_DTD_PATH90 "http://www.slickedit.com/dtd/vse/9.0/vpt.dtd"
#define VPJ_DTD_PATH90 "http://www.slickedit.com/dtd/vse/9.0/vpj.dtd"
#define VPW_DTD_PATH90 "http://www.slickedit.com/dtd/vse/9.0/vpw.dtd"
#define VPE_DTD_PATH90 "http://www.slickedit.com/dtd/vse/9.0/vpe.dtd"

#define VSDEBUG_DTD_PATH90 "http://www.slickedit.com/dtd/vse/9.0/vsdebugger.dtd"

// Version 9.1
#define VPT_FILE_VERSION91 9.1
#define VPJ_FILE_VERSION91 9.1
#define VPW_FILE_VERSION91 9.1
#define VPE_FILE_VERSION91 9.1

#define VPT_DTD_PATH91 "http://www.slickedit.com/dtd/vse/9.1/vpt.dtd"
#define VPJ_DTD_PATH91 "http://www.slickedit.com/dtd/vse/9.1/vpj.dtd"
#define VPW_DTD_PATH91 "http://www.slickedit.com/dtd/vse/9.1/vpw.dtd"
#define VPE_DTD_PATH91 "http://www.slickedit.com/dtd/vse/9.1/vpe.dtd"

#define VSDEBUG_DTD_PATH91 "http://www.slickedit.com/dtd/vse/9.1/vsdebugger.dtd"

// Version 10.0
#define VPT_FILE_VERSION100 10.0
#define VPJ_FILE_VERSION100 10.0
#define VPW_FILE_VERSION100 10.0
#define VPE_FILE_VERSION100 10.0

#define COMPILERS_XML_VERSION100 10.0

#define VPT_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/vpt.dtd"
#define VPJ_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/vpj.dtd"
#define VPW_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/vpw.dtd"
#define VPE_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/vpe.dtd"

#define VSDEBUG_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/vsdebugger.dtd"

#define COMPLIERS_XML_DTD_PATH100 "http://www.slickedit.com/dtd/vse/10.0/compilers.dtd"

// Current Version
#define VPT_FILE_VERSION VPT_FILE_VERSION100
#define VPJ_FILE_VERSION VPJ_FILE_VERSION100
#define VPW_FILE_VERSION VPW_FILE_VERSION100
#define VPE_FILE_VERSION VPE_FILE_VERSION100

#define COMPILERS_XML_VERSION COMPILERS_XML_VERSION100

#define VPT_DTD_PATH VPT_DTD_PATH100
#define VPJ_DTD_PATH VPJ_DTD_PATH100
#define VPW_DTD_PATH VPW_DTD_PATH100
#define VPE_DTD_PATH VPE_DTD_PATH100

#define VSDEBUG_DTD_PATH VSDEBUG_DTD_PATH100

#define COMPLIERS_XML_DTD_PATH COMPLIERS_XML_DTD_PATH100

//Workspace cache variables
   _str gActiveConfigName;   // Can be '' if no project is active.
   _str gActiveTargetDestination;   // Can be '' if no project is active.
   _str _workspace_filename;
   int gWorkspaceHandle;     // Handle to XMLCFG tree or -1 if no workspace open.
   int gProjectHashTab:[/*AbsoluteProjectName*/]; //gProjectHashTab:[AbsoluteProjectName]= ProjectHandle
   int gProjectExtHandle;    // Handle to XMLCFG tree or -1 if not initialized yet.

#define VPJ_SHOWONMENU_HIDEIFNOCMDLINE  'HideIfNoCmdLine'
#define VPJ_SHOWONMENU_NEVER  'Never'
#define VPJ_SHOWONMENU_ALWAYS  'Always'

#define VPJTAG_PROJECT "Project"
#define VPJTAG_MACRO   "Macro"
#define VPJTAG_CONFIG  "Config"
#define VPJTAG_FILES   "Files"
#define VPJTAG_DEPENDENCIES "Dependencies"
#define VPJTAG_DEPENDENCY "Dependency"
#define VPJTAG_EXECMACRO    "ExecMacro"
#define VPJTAG_APPTYPETARGETS    "AppTypeTargets"
#define VPJTAG_APPTYPETARGET    "AppTypeTarget"
#define VPJTAG_TARGET    "Target"
#define VPJTAG_RULE      "Rule"
#define VPJTAG_EXEC      "Exec"
#define VPJTAG_CALLTARGET  "CallTarget"
#define VPJTAG_SET         "Set"
#define VPJTAG_FOLDER    "Folder"
#define VPJTAG_CUSTOMFOLDERS "CustomFolders"
#define VPJTAG_F "F"
#define VPJTAG_MENU    "Menu"
#define VPJTAG_INCLUDE "Include"
#define VPJTAG_INCLUDES "Includes"
#define VPJTAG_SYSINCLUDES "SysIncludes"
#define VPJTAG_SYSINCLUDE "SysInclude"
#define VPJTAG_LIB "Lib"
#define VPJTAG_LIBS "Libs"
#define VPJTAG_CLASSPATH "ClassPath"
#define VPJTAG_CLASSPATHELEMENT "ClassPathElement"
//#define VPJTAG_RULE "Rule"
#define VPJTAG_RULES "Rules"
#define VPJTAG_PREBUILDCOMMANDS "PreBuildCommands"
#define VPJTAG_POSTBUILDCOMMANDS "PostBuildCommands"
#define VPJTAG_COMPATIBLEVERSIONS "CompatibleVersions"
#define VPJTAG_PREVVERSION "PrevVersion"
#define VPJTAG_LIST "List"
#define VPJTAG_ITEM "Item"

#define VPJX_PROJECT  ("/"VPJTAG_PROJECT)
#define VPJX_MACRO    (VPJX_PROJECT"/"VPJTAG_MACRO)
#define VPJX_CONFIG   (VPJX_PROJECT"/"VPJTAG_CONFIG)
#define VPJX_FILES    (VPJX_PROJECT"/"VPJTAG_FILES)
#define VPJX_DEPENDENCIES(ConfigName,DependsRef) (VPJX_CONFIG "[strieq(@Name,'" ConfigName "')]/" VPJTAG_DEPENDENCIES "[strieq(@Name,'" DependsRef "')]")
#define VPJX_DEPENDENCY(ConfigName,DependsRef) (VPJX_DEPENDENCIES(ConfigName,DependsRef)"/"VPJTAG_DEPENDENCY)
#define VPJX_DEPENDENCIES_DEPRECATED (VPJX_PROJECT"/"VPJTAG_DEPENDENCIES)
#define VPJX_DEPENDENCY_DEPRECATED (VPJX_DEPENDENCIES_DEPRECATED"/"VPJTAG_DEPENDENCY)
#define VPJX_EXECMACRO (VPJX_MACRO"/"VPJTAG_EXECMACRO)
#define VPJX_APPTYPETARGETS (VPJX_CONFIG"/"VPJTAG_APPTYPETARGETS)
#define VPJX_APPTYPETARGET (VPJX_APPTYPETARGETS"/"VPJTAG_APPTYPETARGET)
#define VPJX_MENU     (VPJX_CONFIG"/"VPJTAG_MENU)
#define VPJX_COMPATIBLEVERSIONS (VPJX_PROJECT"/"VPJTAG_COMPATIBLEVERSIONS)

#define VPWTAG_SYSVPEVERSION "SysVPEVersion"

#define VPWTAG_WORKSPACE "Workspace"
#define VPWTAG_PROJECTS "Projects"
#define VPWTAG_PROJECT "Project"
#define VPWTAG_ENVIRONMENT "Environment"
#define VPWTAG_SET         "Set"
#define VPWTAG_TAGFILES "TagFiles"
#define VPWTAG_TAGFILE "TagFile"
#define VPWTAG_COMPATIBLEVERSIONS "CompatibleVersions"
#define VPWTAG_PREVVERSION "PrevVersion"

#define VPWX_WORKSPACE ("/"VPWTAG_WORKSPACE)
#define VPWX_PROJECTS  (VPWX_WORKSPACE"/"VPWTAG_PROJECTS)
#define VPWX_PROJECT   (VPWX_PROJECTS"/"VPWTAG_PROJECT)
#define VPWX_ENVIRONMENT  (VPWX_WORKSPACE"/"VPWTAG_ENVIRONMENT)
#define VPWX_SET          (VPWX_ENVIRONMENT"/"VPWTAG_SET)
#define VPWX_TAGFILES  (VPWX_WORKSPACE"/"VPWTAG_TAGFILES)
#define VPWX_TAGFILE   (VPWX_TAGFILES"/"VPWTAG_TAGFILE)
#define VPWX_COMPATIBLEVERSIONS  (VPWX_WORKSPACE"/"VPWTAG_COMPATIBLEVERSIONS)


#define VPTTAG_TEMPLATES  "Templates"
#define VPTTAG_TEMPLATE  "Template"

#define VPTX_TEMPLATES ("/"VPTTAG_TEMPLATES)
#define VPTX_TEMPLATE  (VPTX_TEMPLATES"/"VPTTAG_TEMPLATE)

#define VPJ_SAVEOPTION_SAVECURRENT 'SaveCurrent'
#define VPJ_SAVEOPTION_SAVEALL     'SaveAll'
#define VPJ_SAVEOPTION_SAVEMODIFIED  'SaveModified'
#define VPJ_SAVEOPTION_SAVENONE     'SaveNone'
#define VPJ_SAVEOPTION_SAVEWORKSPACEFILES  'SaveWorkspaceFiles'

#define VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER 'ProcessBuffer'
#define VPJ_CAPTUREOUTPUTWITH_REDIRECTION  'Redirection'

#define BBINDENT_X (40/_twips_per_pixel_x())

#define XPATH_STRIEQ(AttrName,RuleName)  "[strieq(@"AttrName",'"RuleName"')]"
#define XPATH_FILEEQ(AttrName,RuleName)  "[file-eq(@"AttrName",'"RuleName"')]"
#define XPATH_CONTAINS(AttrName,String,Options) "[contains(@"AttrName",'"String"','"Options"')]"

#define fileieq(a,b) strieq(a,b)
#if __UNIX__
#define EXTRA_FILE_FILTERS  "ZIP Files (*.zip),JAR Files (*.jar),Java Class Files (*.class)"
#else
#define EXTRA_FILE_FILTERS  "ZIP Files (*.zip),JAR Files (*.jar),Java Class Files (*.class),.NET DLL Files (*.dll)"
#endif
_str _get_string;
_str _get_string2;
#if __PCDOS__
   #define WILDCARD_CHARS  '*?'
#elif __UNIX__
   // removed (){}|
   #define WILDCARD_CHARS  '*?[]^\'
#else
  what are the wild card characters
#endif

#define VPJ_AUTOFOLDERS_PACKAGEVIEW  "PackageView"
#define VPJ_AUTOFOLDERS_DIRECTORYVIEW "DirectoryView"
#define VPJ_AUTOFOLDERS_CUSTOMVIEW    ""

typedef _str STRARRAY[];
typedef _str (*STRARRAYPTR)[];
typedef int  INTARRAY[];
typedef _str STRHASHTABARRAY:[][];
typedef _str STRHASHTAB:[];
typedef void (*pfnTreeSaveCallback)(int xml_handle,int xml_index,int tree_index);
typedef void (*pfnTreeLoadCallback)(int xml_handle,int xml_index,int tree_index);
typedef void (*pfnTreeDoRecursivelyCallback)(int index, typeless extra);
#define ARRAY_APPEND(a,b) a[a._length()]=b

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
#define VSPIC_ORDER_DEBUGGER            100
#define VSPIC_ORDER_BPM                 101
#define VSPIC_ORDER_ANNOTATION          200
#define VSPIC_ORDER_ANNOTATION_GRAY     201
#define VSPIC_ORDER_SET_BOOKMARK        202
#define VSPIC_ORDER_PUSHED_BOOKMARK     203

#define VSPIC_ORDER_PLUS                500
#define VSPIC_ORDER_MINUS               501

// Deprecated:  Use VSLINEMARKERINFO or VSSTREAMMARKERINFO
#define VSPICLISTITEM VSLINEMARKERLISTITEM

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

// Deprecated:  Use VSSTREAMMARKERINFO
struct VSSTREAMMARKERLISTITEM {
   boolean isDeferred;
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
#define VSMARKERTYPEFLAG_AUTO_REMOVE        0x10

/*
   When on, that a box should be draw around the lines contained in this
   area.  You can also have a bitmap displayed on the first line of the selection.
*/
#define VSMARKERTYPEFLAG_DRAW_BOX                   0x20
#define VSMARKERTYPEFLAG_UNDO                       0x40
#define VSMARKERTYPEFLAG_COPYPASTE                  0x80
#define VSMARKERTYPEFLAG_COPY_CHAR_LINE_SELECT      0x100
#define VSMARKERTYPEFLAG_DRAW_FOCUS_RECT            0x200
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY              0x400
#define VSMARKERTYPEFLAG_DRAW_LINE_LEFT             0x800
#define VSMARKERTYPEFLAG_DRAW_LINE_RIGHT            0x1000
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY_LEFT         0x2000
#define VSMARKERTYPEFLAG_DRAW_SQUIGGLY_RIGHT        0x4000
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT     0x10000
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT  0x20000
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT    0x40000
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT 0x80000
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_RIGHT   (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT)
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_LEFT    (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT)
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_BOTH  (VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT)
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_BOTH     (VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_TOP_RIGHT)
#define VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_BOTH    (VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_LEFT|VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTH_RIGHT)
#define VSMARKERTYPEFLAG_DRAW_SCROLL_BAR_MARKER     0x100000

boolean def_project_prop_show_curconfig;

/**
 * Struct created by _list_processes()
 */
struct PROCESS_INFO {
   _str    owner;        // user id of owner (may be empty on Windows)
   boolean is_system;    // system process or owned by root on Unix
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

#define FUNDAMENTAL_LANG_ID   'fundamental'

#define XSD_SETUP 'MN=XSD,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XMLSCHEMA,CF=1,'
#define XMLDOC_SETUP 'MN=XMLDOC,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XML,CF=1,'
#define VPJ_SETUP 'MN=VPJ,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=1,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XML,CF=1,'
#define DOCBOOK_SETUP 'MN=DocBook,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=\p{isXMLNameChar}?!,LN=XML,CF=1,'
#define XHTML_SETUP 'MN=XHTML,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=\p{isXMLNameChar}?!,LN=XHTML,CF=1,'
#define ANT_SETUP 'MN=Ant,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XML,CF=1,'
#define ANDROID_SETUP 'MN=Android Resource XML,TABS=+4,MA=1 74 1,KEYTAB=xml-keys,WW=1,IWT=0,ST='DEFAULT_SPECIAL_CHARS',IN=2,WC=A-Za-z0-9_:$?.!\-,LN=XML,CF=1,'

#define VSDEFAULT_INITIAL_MENU_OFFSET_X  0
#define VSDEFAULT_INITIAL_MENU_OFFSET_Y  0

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

enum_flags CVS_FLAGS {
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
boolean def_do_block_mode_key;
/**
 * If enabled, support Delete while in block insert mode.
 * If disabled, Delete merely deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_do_block_mode_delete;
/**
 * If enabled, support Backspace while in block insert mode.
 * If disabled, Backspace merely deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_do_block_mode_backspace;

/**
 * If enabled, support Del while in block insert mode.
 * If disabled, Del deletes the block selection.
 *
 * @default true
 * @categories Configuration_Variables
 */
boolean def_do_block_mode_del_key;

/**
 * Sets maximum buffer size for search results buffer.
 * @categories Configuration_Variables
 */
int def_max_mffind_output;

enum_flags {
   DELTASAVE_BACKUP_FILES,
   DELTASAVE_DELTA_FOR_MATCHING_FILES,
}
#define DELTASAVE_DEFAULT_NUMVERSIONS 400
/**
 * Default max time (in milliseconds) that diff will run before 
 * backup history times out and stores a whole version of the 
 * file. 
 */
#define DELTASAVE_DEFAULT_TIMEOUT     3000
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
 * Backup history options.  List of files and/or directories 
 * excluded from backup history.  This list should be separated 
 * by ';' on Windows and separated using ':' on Unix platforms.
 *
 * @default 0
 * @categories Configuration_Variables
 */
_str def_deltasave_exclusions;

boolean def_updown_screen_lines;
int def_process_softwrap;
boolean def_SoftWrap;
boolean def_SoftWrapOnWord;


/**
 * This struct encapsulates all common language specific options. 
 *  
 * @see _GetDefaultLanguageOptions() 
 * @see _SetDefaultLanguageOptions() 
 */
struct VS_LANGUAGE_OPTIONS {
   _str szRefersToLanguage;
   _str szLexerName;
   int ColorFlags;
   int LeftMargin;
   int RightMargin;
   int NewParagraphMargin;
   int WordWrapStyle;  // see VSWWS_??? flags
   boolean IndentWithTabs;  // Boolean
   boolean DisplayLineNumbers;  // Boolean
   boolean SyntaxExpansion;  // Boolean.  Ignored for fundamental extension
   _str szTabs;
   _str szModeName;
   _str szBeginEndPairs;  // We may dump this in the future
   _str szAliasFilename;
   _str szEventTableName;
   _str szWordChars;
   int IndentStyle; // see VSINDENTSTYLE_???
   int SyntaxIndent;  // Number of characters to indent.   Ignored for fundamental extension
   // version=1
   int TruncateLength;
   _str encoding;   // string
   _str default_dtd;   // .vtg or .dtd file
   // version=2
   boolean UseFileAssociation;
   _str szOpenApplication;
   // version=3
   _str szInheritsFrom;
   // version=4
   int BoundsStart;
   int BoundsEnd;
   int AutoCaps;
   boolean SoftWrap;
   boolean SoftWrapOnWord;
   // version 5
   int minAbbrev;
   // version = 6
   int IndentCaseFromSwitch;        // boolean
   int PadParens;                   // boolean
   int NoSpaceBeforeParen;          // boolean
   int BeginEndStyle;
   int PointerStyle;
   int FunctionBraceOnNewLine;      // boolean
   int ShowTabs;                    // boolean
   int KeywordCasing;
   int TagCasing;
   int AttributeCasing;
   int ValueCasing;
   int HexValueCasing;
   // version 7
   _str szFileExtensions;
   // version 8
   int HexMode;
   int LineNumbersLen;
   // version, 9
   int LineNumbersFlags;
};

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
   boolean indent_with_tabs;
   int show_tabs;
   int indent_style;
   _str word_chars;
   _str lexer_name;
   int color_flags;
   int line_numbers_len;
   int TruncateLength;
   _str bounds;
   int caps;
   boolean SoftWrap;
   boolean SoftWrapOnWord;
   int hex_mode;
   int line_numbers_flags;
};
// compatibility with pre-12.0 slickedit
typedef VS_LANGUAGE_SETUP_OPTIONS VSEXTSETUPOPTIONS;

/**
 * Default open and save as file extension.
 *
 * @default ""
 * @categories Configuration_Variables
 */
_str def_ext;
_str def_maxbackup;
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
typeless def_print_device;
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
typeless def_toolboxtab;
typeless def_bbtb_colors;
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
#define VS_WPSELECT_NEWLINE       0x1

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
#define VS_WPSELECT_MOU_CHAR_LINE 0x2

/**
 * @return Word processor style selection flags. See VS_WPSELECT_* for more
 * information.
 */
int def_wpselect_flags;

/**
 * Set to true if you want next_bookmark and prev_bookmark to ONLY navigate
 * bookmarks in the current buffer/file.
 */
boolean def_vcpp_bookmark;

/**
 * Do extra checking to see if the file's contents have been modified when its
 * timestamp has changed.  When on we will always perform this 
 * check. 
 *
 * @default false
 * @categories Configuration_Variables 
 * @deprecated see def_autoreload_compare_whole_file and 
 *             def_autoreload_compare_whole_file_max_size
 */
boolean def_filetouch_checking;

/**
 * When true, if size of buffer is below
 * <B>def_autoreload_compare_whole_file_max_size</B>, compare
 * buffer contents to file before reporting it as modified.
 * This is for file systems that get dates incorrect.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_autoreload_compare_contents;

/**
 * Maximum file size in bytes on which we will perform whole 
 * file comparision when <B>def_autoreload_compare_contents</B> 
 * is true.
 * 
 * @default 2000000
 * @categories Configuration_Variables
 */
int def_autoreload_compare_contents_max_size;

/** 
 * Show all files that need to be reloaded or resaved in a single select tree
 * dialog, rather than one dialog per file.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_batch_reload_files;

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
#define VS_C_OPTIONS_STYLE1_FLAG                   0x0001
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
#define VS_C_OPTIONS_STYLE2_FLAG                   0x0002
/**
 * C/C++ style options -- insert braces immediately
 */
#define VS_C_OPTIONS_BRACE_INSERT_FLAG             0x0004
/**
 * C/C++ style options -- insert blank line between braces
 */
#define VS_C_OPTIONS_BRACE_INSERT_LINE_FLAG        0x0008
/**
 * C/C++ style options -- no space before paren
 *
 * <pre>
 * if(expr) {
 *    ++i;
 * }
 * </pre>
 */
#define VS_C_OPTIONS_NO_SPACE_BEFORE_PAREN         0x0010   // "if(" or "if ("
/**
 * C/C++ style options -- insert function braces on new line
 */
#define VS_C_OPTIONS_BRACE_INSERT_FUNCTION_FLAG    0x0020
/**
 * C/C++ style options -- char* p;
 */
#define VS_C_OPTIONS_SPACE_AFTER_POINTER           0x0040
/**
 * C/C++ style options -- char * p;
 */
#define VS_C_OPTIONS_SPACE_SURROUNDS_POINTER       0x0080
/**
 * C/C++ style options -- if ([space][cursor][space])
 */
#define VS_C_OPTIONS_INSERT_PADDING_BETWEEN_PARENS 0x0100
/**
 * C/C++ style options -- quick brace/unbrace one lines statements
 *                     -- if ( cond ) doSomething();
 *                     -- if ( cond ) {
 *                           doSomething();
 *                        }
 */
#define VS_C_OPTIONS_NO_QUICK_BRACE_UNBRACE 0x0200
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
#define VS_C_OPTIONS_ELSE_ON_LINE_AFTER_BRACE 0x0400


// Commands to pass to HtmlHelp()

#define HH_DISPLAY_TOPIC        0x0000
//#define HH_HELP_FINDER          0x0000
#define HH_DISPLAY_TOC          0x0001
#define HH_DISPLAY_INDEX        0x0002     // Windows only
#define HH_DISPLAY_SEARCH       0x0003     // Windows only
//#define HH_SET_WIN_TYPE         0x0004
//#define HH_GET_WIN_TYPE         0x0005
//#define HH_GET_WIN_HANDLE       0x0006
//#define HH_ENUM_INFO_TYPE       0x0007
//#define HH_SET_INFO_TYPE        0x0008
//#define HH_SYNC                 0x0009
//#define HH_RESERVED1            0x000A
//#define HH_RESERVED2            0x000B
//#define HH_RESERVED3            0x000C
#define HH_KEYWORD_LOOKUP       0x000D
//#define HH_DISPLAY_TEXT_POPUP   0x000E
//#define HH_HELP_CONTEXT         0x000F
//#define HH_TP_HELP_CONTEXTMENU  0x0010
//#define HH_TP_HELP_WM_HELP      0x0011
//#define HH_CLOSE_ALL            0x0012
//#define HH_ALINK_LOOKUP         0x0013
//#define HH_GET_LAST_ERROR       0x0014
//#define HH_ENUM_CATEGORY        0x0015
//#define HH_ENUM_CATEGORY_IT     0x0016
//#define HH_RESET_IT_FILTER      0x0017
//#define HH_SET_INCLUSIVE_FILTER 0x0018
//#define HH_SET_EXCLUSIVE_FILTER 0x0019
//#define HH_INITIALIZE            0x001C
//#define HH_UNINITIALIZE          0x001D
//#define HH_PRETRANSLATEMESSAGE  0x00fd
//#define HH_SET_GLOBAL_PROPERTY  0x00fc

_str process_retrieve_id;
boolean process_first_retrieve;

#define BG_SEARCH_ACTIVE         (0x01)
#define BG_SEARCH_UPDATE         (0x02)
#define BG_SEARCH_TERMINATING    (0x04)
int gbgm_search_state;

_str def_mffind_pathsep;

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
boolean def_cursor_beginend_select;
/**
 * If enabled, cursor movement emulates having real tabs rather
 * than spaces in the leading whitespace of a line.
 *
 * @default false
 * @categories Configuration_Variables
 */
boolean def_emulate_leading_tabs;

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
#define CONTEXT_TOOLBAR_ADD_LOCALS     0x01
#define CONTEXT_TOOLBAR_SORT_BY_LINE   0x02
#define CONTEXT_TOOLBAR_DISPLAY_LOCALS 0x04

int def_autoclose_flags/*=3*/;

// Unit testing stuff
_str def_unittest_basepath; // base path for unit testing the unit testing feature
_str def_unittest_junitjar; // location of junit.jar

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
 * Enable Java live errors?
 *
 * @default false
 * @categories Configuration_Variables
 */
int def_java_live_errors_enabled;
/**
 * First time live errors has been initialized?
 *
 * @default true 
 * @categories Configuration_Variables
 */
int def_java_live_errors_first;
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
boolean def_eclipse_extensionless;
/**
 * Tell Eclipse to attempt to decipher language mode for 
 * extensionless files with SlickEdit. 
 *
 * @default true  
 * @categories Configuration_Variables
 */
boolean def_eclipse_check_ext_mode;
/**
 * Display targets imported from external Ant files 
 *
 * @default true  
 * @categories Configuration_Variables
 */
boolean def_antmake_display_imported_targets;
/**
 * Filter matches for Ant goto_definition functionality for 
 * visibility: do not show results which are not visible from 
 * where the command was invoked. 
 *
 * @default false 
 * @categories Configuration_Variables
 */
boolean def_antmake_filter_matches;
/**
 * Parse XML files when opened in order to identify Ant build 
 * files. 
 *
 * @default true  
 * @categories Configuration_Variables
 */
boolean def_antmake_identify;
/**
 * Maximum size of a file that _IsAntBuildFile will recognize
 *
 * @default true  
 * @categories Configuration_Variables
 */
int def_max_ant_file_size;


#define VSBLRESULTFLAG_NEWFILECREATED      0x1
#define VSBLRESULTFLAG_NEWTEMPFILECREATED  0x2
#define VSBLRESULTFLAG_NEWFILELOADED       0x4
#define VSBLRESULTFLAG_READONLYACCESS      0x8
#define VSBLRESULTFLAG_ANOTHERPROCESS      0x10
#define VSBLRESULTFLAG_READONLY            (VSBLRESULTFLAG_READONLYACCESS|VSBLRESULTFLAG_ANOTHERPROCESS)
#define VSBLRESULTFLAG_NEW                 (VSBLRESULTFLAG_NEWFILECREATED|VSBLRESULTFLAG_NEWTEMPFILECREATED|VSBLRESULTFLAG_NEWFILELOADED)

// this tells us when postinstall.e was last run...well not so much 'when' as much as
// 'which version'
_str _post_install_version;

/**
 * Used by _WinRect api for getting window rectangles in various
 * coordinate mappings, scale modes. Use the _WinRect* api.
 */
struct WINRECT {
   int wid;
   int x1,y1;
   int x2,y2;
};

extern void _WinRectInit(WINRECT& r);

/**
 * Set WINRECT structure to dimensions of window passed in.
 *
 * @param r
 * @param wid
 * @param toWid      (optional). Map dimensions relative to toWid.
 *                   Defaults to 0 (desktop).
 * @param scale_mode (optional). The output scale mode for dimensions.
 *                   May be SM_PIXEL or SM_TWIP. Defaults to SM_PIXEL.
 */
extern void _WinRectSet(WINRECT& r, int wid, int toWid=0, int scale_mode=SM_PIXEL);

/**
 * Set coordinates for a WINRECT rectangle explicitly.
 *
 * @param r
 * @param wid
 * @param x1
 * @param y1
 * @param x2
 * @param y2
 */
extern void _WinRectSetSubRect(WINRECT& r, int wid, int x1, int y1, int x2, int y2);

/**
 * @param r
 * @param wid
 * @param x
 * @param y
 *
 * @return true if mouse coordinates are inside the WINRECT r.
 */
extern boolean _WinRectPointInside(WINRECT r, int wid, int x, int y);

/**
 * Draw a rectangle border using WINRECT coordinates relative to
 * active window.
 * <p>
 * Options similar to _draw_rect function but initialization
 * and cleanup are taken care of.
 *
 * @param r
 * @param color
 * @param options    See _draw_rect help for options.
 * @param draw_width (optional). p_draw_width. See help. -1 to use current p_draw_width setting.
 * @param draw_mode  (optional). p_draw_mode. See help. -1 to use current p_draw_mode setting.
 * @param draw_style (optional). p_draw_style. See help. -1 to use current p_draw_style setting.
 */
extern void _WinRectDrawRect(WINRECT r, int color, _str options,
                             int draw_width= -1,
                             int draw_mode= -1,
                             int draw_style= -1);

struct WORKSPACE_LIST {
   boolean isFolder;
   _str filename;   // directory name or filename
   _str caption;
   union {
      _str description;  // If name is a filename, this is the description
      WORKSPACE_LIST list[];
   } u;
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
boolean def_auto_complete_block_comment;

/** 
 * Modes for commenting lines 
 *    LEFT_MARGIN - put comments at left margin (overstrike)
 *    LEVEL_OF_INDENT - at level of indent of first line of
 *    selection
 *    START_AT_COLUMN - comments at a certain column
 */
enum COMMENT_LINE_MODE{
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

/**
 * Struct holding the language extension comment settings
 */
typedef struct {
   _str tlc;
   _str trc;
   _str blc;
   _str brc;
   _str bhside;
   _str thside;
   _str lvside;
   _str rvside;
   _str comment_left;
   _str comment_right;
   int  comment_col;
   boolean firstline_is_top;
   boolean lastline_is_bottom;
   COMMENT_LINE_MODE mode;
} BlockCommentSettings_t;

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
enum CommentWrapSettings {
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
//#define  XW_ENABLE_FEATURE           1
#define  XW_ENABLE_CONTENTWRAP         2
#define  XW_ENABLE_TAGLAYOUT           3
#define  XW_DEFAULT_SCHEME             4
#define XW_NODEFAULTSCHEME '__NODEFAULT'
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
#define DocCommentTrigger1      '/**'
#define DocCommentTrigger2      '/*!'
#define DocCommentTrigger3      '///'
#define DocCommentTrigger4      '//!'
#define DocCommentStyle1        '@'
#define DocCommentStyle2        '\'
#define DocCommentStyle3        '<>'

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
#define TK_ID 1
#define TK_NUMBER 2
#define TK_STRING 3
#define TK_KEYWORD 4

struct VSSTREAMMARKERINFO {
   boolean isDeferred;
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
   boolean isDeferred;
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
boolean def_disable_replace_tooltip;

/**
 * Disables automatic error markers after builds are complete.
 *
 * @categories Configuration_Variables
 */
boolean def_disable_postbuild_error_markers;

/**
 * Disables automatic error scroll markers after builds are 
 * complete. 
 *
 * @categories Configuration_Variables
 */
boolean def_disable_postbuild_error_scroll_markers;

/**
 * Maximum number of search results windows.
 *
 * @default 32
 */
int def_max_search_results_buffers;


#define VSDEFAULT_DIALOG_FONT_NAME "Default Dialog Font"
#define VSDEFAULT_DIALOG_FONT_SIZE 8

// Indicates whetherCompletion e and edit lists binary files.
// When in Brief emulation, a_match should screen out binary files based on
// extension list in def_binary_ext
boolean def_list_binary_files;

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
boolean def_filelist_show_dotfiles;

/**
 * Maximum number of error markers to process in postbuild. Set 
 * to &lt;0 to always process all errors. 
 *  
 * @categories Configuration_Variables
 */
int def_max_error_markers;

/**
 * Default flags for using select_proc command.
 *  
 * @categories Configuration_Variables
 */
int def_select_proc_flags;

/**
 * Toggles selection type between block and character.  Off by
 * default.  Used in Eclipse emulation.
 *  
 * @categories Configuration_Variables
 */
boolean def_select_type_block;

/**
 * Settings for using the select_proc command. 
 *  
 *    'SELECT_PROC_NO_COMMENTS' - Do not select the comment
 *    header as part of select_proc
 */
enum_flags SELECT_PROC_FLAGS {
   SELECT_PROC_NO_COMMENTS = 0x1,
};

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
boolean def_show_all_proj_with_file;

struct HTML_INFO_STRUCT {
   int browser[];
   _str exePath[];
   _str app[];
   _str topic[];
   _str item[];
   int useDDE[];
};

struct NTINDEXHELPOPTIONS {
   boolean usedde;
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
int _pic_open_file;              // _fileo.bmp
int _pic_hist_file;              // _filehist.bmp
int _pic_hist_open_file;         // _filehisto.bmp
int _pic_wksp_file;              // _filewksp.bmp
int _pic_wksp_open_file;         // _filewkspo.bmp
int _pic_proj_file;              // _fileprj.bmp
int _pic_proj_open_file;         // _fileprjo.bmp
int _pic_folder;                 // _fldclos.bmp
int _pic_disk_file;              // _file.bmp
int _pic_disk_open_file;         // _filedisko.bmp

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
extern boolean _CheckLineLengths(int AllowedLineLen,_str &LineNumbers,int FromCursor=0,int &MaxLineLen=0);



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
extern boolean _FileIsRemote(_str filename);
extern boolean _FileIsWritable(_str filename);
extern boolean _WinFileIsWritable(int wid);
extern boolean _DataSetIsFile(_str filename);
extern boolean _DataSetIsMember(_str filename);
extern _str _DataSetNameOnly(_str filename);
extern _str _DataSetMemberOnly(_str filename);
extern boolean _DataSetSupport();

extern void _RegisterAlert(int alertGroupID);
extern void _UnregisterAlert(int alertGroupID);
extern void _ActivateAlert(int alertGroupID, int alertID, _str msg='', _str header='', int showToast=1);
extern void _DeactivateAlert(int alertGroupID, int alertID, _str msg='', _str header='', int showToast=0);
extern void _ClearLastAlert(int alertGroupID, int alertID);
extern void _SetAlertGroupStatus(int alertGroupID, int enabled=1, int showPopups=1);
extern void _SetAlertStatus(int alertGroupID, int alertID, int enabled=1, int showPopups=1);
extern void _GetAlertGroup(int alertGroupID, typeless alertGroup);
extern void _GetAlert(int alertGroupID, int alertID, typeless alert);

extern void _LCClearAll();
extern _str _LCQDataAtIndex(int iLineCommand);
extern int _LCQLineNumberAtIndex(int iLineCommand);
extern _str _LCQData();
extern int _LCQLineNumber();
extern void _LCSetData(_str pszLineCommmand);
extern int _LCQNofLineCommands();
extern boolean _LCIsReadWrite();
extern void _LCSetFlags(int flags,int mask);
extern int _LCQFlags();
extern void _LCSetDataAtIndex(int iLineCommand,_str pszLineCommmand);
extern int _LCQFlagsAtIndex(int iLineCommand);
extern void _LCSetFlagsAtIndex(int iLineCommand,int flags,int mask);

extern boolean _demo();
extern boolean _trial();

/**
 * Returns whether or not the specified file exists or not.
 * 
 * @param filename - The file to check for existence.
 * 
 * @return boolean - True if the file exists, false if not. 
 *  
 * @categories File_Functions
 */
extern boolean file_exists(_str filename);


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
extern boolean _UrlSetIncludeHeader(boolean onoff);
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
extern int _isHTTPFile(_str filename);

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
extern boolean _SlickCDebugging(int on_off, _str port);
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
extern boolean _SlickCProfiling(boolean on_off);
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
 * handle the situtation. 
 * 
 * @return 'true' if the timeout is expired. 
 *  
 * @categories Macro_Programming_Functions
 */
extern int _CheckTimeout();

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
extern boolean _UTF8();

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
extern boolean _begin_char();

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

extern int _SaveSelDisp(_str pszFilename,_str pszFileDate);
extern int _RestoreSelDisp(_str pszFilename,_str pszFileDate,boolean RestoreSelDisp,boolean RestoreLineModify);
extern int _MallocTotal();
extern int _MallocCount();
extern boolean _wf_isconnected();
extern void wf_terminate_dde();
extern boolean delphiIsRunning();
boolean delphiIsBufInDelphi(_str buf_name);
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
extern void _LanguageCallbackProcessBuffer(int reqFlags);
extern int _userName(_str &name);
extern int _registervs(_str pszExeFilename);
extern int _associatefiletypetovs(_str pszExtnodot, ...);
extern int ntSupportOpenDialog();
extern int _timer_is_valid(typeless timer_handle);
extern void _set_timer_alternate(typeless timer_handle,int alternateInterval,int alternateIdleTime);
extern int _DelTree(_str rootPath,boolean removeRootPath);
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
                              boolean NormalizeFolderNames);
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
extern int _FilterTreeControl(_str pszFilter,boolean iPrefixFilter, boolean iSearchUserInfo=false,_str iREType='&',int iColIndex=0);
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
extern boolean _SCIMRunning();

extern int scBPMQFlags();
extern int _GetMouWindow();
extern int _find_tile(_str buf_name);
_command start_process_tab(boolean OpenInCurrentWindow=false,
                       boolean doSetFocus=true,
                       boolean quiet=false,
                       boolean uniconize=true);
_command start_process(boolean OpenInCurrentWindow=false,
                       boolean doSetFocus=true,
                       boolean quiet=false,
                       boolean uniconize=true);
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
extern boolean _QueryEndSession();
boolean isEclipsePlugin();
extern _command typeless show(_str cmdline="", ...);
extern void mou_hour_glass(boolean onoff);
extern void _macro_delete_line();

#if __PCDOS__
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
extern int NTShellExecute(_str pszOperation,_str pszFilename,_str pszParams,_str pszDir);
extern int ntGetMaxCommandLength();
extern int ntGetVolumeSN(_str pszPath,var hvarVSN);
extern int NTGetElevationType();
extern int NTIsElevated();
extern int NTShellExecuteEx(_str pszOperation, _str pszFilename, _str pszParams, _str pszDir, int &exitCode);
extern int ntIISGetVirtualDirectoryPath(_str vdirpath, _str &path);
#endif

extern _str vscf_iserror();
extern int vscf_adjusted_linenum();
extern int vsada_format(typeless origEncoding,_str inFilename,int inViewId,_str outFilename,int startIndent,int startLinenum,var htOptions,int vseFlags);
extern typeless vsadaformat_iserror();
extern int vsadaformat_adjusted_linenum();
extern int vsh_format(int,_str,int,_str,int,int,typeless&,typeless&,typeless&,int);
extern int vsx_format(int,_str,int,_str,int,int,typeless&,typeless&,typeless&,int);
extern _str vshf_iserror();
extern int vshf_adjusted_linenum();

/**
 * Allows you to create a language which has it's own set of 
 * options, but can inherit support callbacks from another 
 * language. 
 *
 * @param lang    Language ID (see {@link p_LangId} 
 *
 * @param parent  <i>lang</i> is set to inherit language 
 *                specific callbacks from the language
 *                specified by <i>parent</i>.
 *                If NULL, remove language inheritance
 *                for <i>lang</i>.
 *
 * @see _SetDefaultLanguageOptions
 * @see _DeleteLanguageOptions
 * @see _LanguageInheritsFrom 
 * @see _FindLanguageCallbackIndex 
 *
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions 
 * @since 13.0
 */
extern void _SetLanguageInheritsFrom(_str lang, _str parent);

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
 * @see _SetLanguageInheritsFrom 
 * @see _FindLanguageCallbackIndex 
 *  
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions 
 * @since 13.0
 */
extern boolean _LanguageInheritsFrom(_str parent, _str lang=null);

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
extern boolean _LanguageReferencedIn(_str ref_lang, _str lang=null);

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
 * @see _SetLanguageInheritsFrom 
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
 * @appliesTo Edit_Window, Editor_Control
 * @categories Tagging_Functions
 * @since 13.0
 */
extern boolean _QTaggingSupported(int wid=0, _str lang=null);

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
 * 
 * @categories Search_Functions, Tagging_Functions
 */
extern boolean _QBinaryLoadTagsSupported(_str filename=null);

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
 * @see _LangId2Modename
 * @see _Filename2LangId 
 * @see _Ext2LangId 
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
 * @see _Modename2LangId 
 * @see _Filename2LangId 
 * @see _Ext2LangId 
 *  
 * @categories Miscellaneous_Functions 
 */
extern _str _LangId2Modename(_str lang);

/** 
 * Compare two language mode names. 
 * Language mode names are case-insensitive.
 *  
 * @categories Miscellaneous_Functions
 */
extern boolean _ModenameEQ(_str a,_str b);

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
 */
extern _str _LangId2LexerName(_str lang);

/**
 * @return Return absolute path of user's local configuration 
 * directory with a trailing file separator. 
 *
 * @categories File_Functions
 */
extern _str _ConfigPath();

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
 * tabgroup.
 *
 * @param wid  Editor control window handle.
 */
extern void _MDIChildNewHorizontalTabGroup(int wid,boolean insertAfter);

/**
 * Create a new vertical tabgroup from editor control
 * specified by <code>wid</code>. If editor control is already
 * part of a tabgroup, then it is removed and inserted into new
 * tabgroup.
 *
 * @param wid  Editor control window handle.
 */
extern void _MDIChildNewVerticalTabGroup(int wid,boolean insertAfter);

/**
  * Save MDI form <code>state</code> and encode to string. Used 
  * by auto-restore. 
  * 
  * @return slickedit::SEString 
  */
extern void _MDISaveState(_str& state);
/**
  * Restore MDI form <code>state</code> returned from 
  * <code>_MDIGetState</code>. Used by auto-restore. 
  *
  * @param state
  *
  * @return true on success.
  */
extern boolean _MDIRestoreState(_str state);

/**
 * Float/dock MDI child window <code>wid</code>.
 *
 * @param wid
 * @param doFloat   If true window is floated
 */
extern void _MDIChildFloatWindow(int wid,boolean doFloat);

/**
 * Return true if MDI child window <code>wid</code> is a 
 * floating window, false if a docked window. 
 *  
 * @param wid
 *
 * @return bool.
 */
extern boolean _MDIChildIsFloating(int wid);

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
extern boolean mou_is_captured();

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
extern int _CreateZipFile(_str filename, _str (&files)[], int (&zipStatus)[], _str (&archiveFilenames)[]=null);

/**
 * Get logged in user name.
 * 
 * @return Logged in user name.
 */
extern _str _GetUserName();

/**
 * @return Returns <i>filename</i> with part stripped.  P=Path, D=Drive,
 * E=Extension, N=Name.
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
extern _str _get_extension(_str buf_name,boolean returnDot=false);

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

#define FLMFOFLAG_DIRECTORIES    1
#define FLMFOFLAG_DISKFILES     2
#define FLMFOFLAG_PROJECTFILES  4
#define FLMFOFLAG_WORKSPACEFILES 8
#define FLMFOFLAG_HISTORYFILES  16
#define FLMFOFLAG_OPENFILES     32
#define FLMFOFLAG_ORIGINMASK        63
#define FLMFOFLAG_ISDOTDOTDIR    64
#define FLMFOFLAG_MODIFIED     128
#define FLMFOFLAG_BITMAPMASK     (FLMFOFLAG_ORIGINMASK | FLMFOFLAG_ISDOTDOTDIR)
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
extern void FileListManager_RefreshWorkspaceFiles(int flmHandle, boolean forceRefresh=false);
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
extern void FileListManager_RefreshDiskFiles(int flmHandle, _str directoryPath, boolean showHidden =false);
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
extern int FileListManager_InsertListIntoTree(int flmHandle, int treeWid, int treeNode, int whichFileSetsFlags, _str filter='', boolean prefixMatch=false, _str curDir='',boolean emptyPrefixMatchesEverything=false,boolean bResizeColumnsToContents=true);
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
extern int FileListManager_InsertSortedListIntoTree(int flmHandle, int treeWid, int treeNode, int whichFileSetsFlags, int sortOrder, _str filter='', boolean prefixMatch=false, _str curDir='');

/** Default sort order for FileListManager. Groups by file type
 *  (disk files, project/workspace, etc), then sorts by file
 *  name.
*/
#define FLMSORT_DEFAULT 0
/**
 * Sorts by file name (no path), ascending
 */
#define FLMSORT_FILENAME_ASC 1
/**
 * Sorts by file name (no path), descending
 */
#define FLMSORT_FILENAME_DESC 2
/**
 * Sorts by full file path, ascending
 */
#define FLMSORT_FULLPATH_ASC 3
/**
 * Sorts by full file path, descending
 */
#define FLMSORT_FULLPATH_DESC 4
///////////////////////////////////////////////////////
// Project support methods (from the projsupp library)
//////////////////////////////////////////////////////

// Xcode project support methods
extern int _InsertXcodeProjectHierarchy(_str projectPath, int treeID, int iParentIndex);
extern int _InsertXcodeProjectFileList(_str projectPath, int windowID, boolean AbsolutePaths);
extern int _GetXcodeProjectConfigurations(_str projectPath,_str (&configurations)[]);
extern int _GetXcodeWorkspaceSchemes(_str workspacePath,_str (&schemes)[]);
extern int _GetXcodeProjectName(_str projectPath, _str& projectName);
extern int _GetXcodeProjectOutputFilename(_str projectPath, _str configString, _str sdkName, _str& outputFilePath);
extern int _GetXcodeProjectSDKRoot(_str projectPath, _str configString, _str& sdkRoot);
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
extern int _getProjectFiles(_str workspaceFile, _str projectFile, _str (&filelist)[], int absolutePath, int projectHandle = -1);

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
extern void _projectMatchFile(_str workspaceFile, _str projectFile, _str file, _str (&list)[],boolean append);


/** 
 * Set dependency extensions for project inclusion when parsing 
 * Tornado projects. 
 * 
 * @param ext
 */
extern void _projectSetDependencyExtensions(_str ext);

// Visual Studio .vcxproj methods
extern int _InsertVCXProjectHierarchy(_str projectFilePath, int isFilterFile, int treeID, int iParentIndex);
extern int _InsertVCXProjectFileList(_str projectFilePath, int xmlHandle, int viewListID, boolean absPaths, boolean indentSpace);
extern int _VCXProjectInsertFile(_str projectFilePath, _str fileName, _str itemType, _str folderPath);
extern int _VCXProjectDeleteFile(_str projectFilePath, _str fileName);
extern int _VCXProjectInsertFolder(_str projectFilePath, _str folderPath, _str extensions, _str uuid);
extern int _VCXProjectDeleteFolder(_str projectFilePath, _str folderPath, int removeFiles);

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
                             boolean NormalizeFolderNames,
                             int RefilterWildcards=0);

// Creation of a desktop shortcut on Gnome/KDE
#if __UNIX__ && !__MACOSX__
extern void _X11CreateDesktopShortcut();
#endif

#if __MACOSX__
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
extern void _clipboard_close(boolean isClipboard);

enum_flags AutoBracketFlags {
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

#define AUTO_BRACKET_DEFAULT_OFF             0
#define AUTO_BRACKET_DEFAULT_ON              AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT
#define AUTO_BRACKET_DEFAULT_C_STYLE         AUTO_BRACKET_ENABLE|AUTO_BRACKET_DEFAULT|AUTO_BRACKET_ANGLE_BRACKET
#define AUTO_BRACKET_DEFAULT_HTML_STYLE      AUTO_BRACKET_DEFAULT|AUTO_BRACKET_ANGLE_BRACKET

enum_flags AutoBracketKeys {
   AUTO_BRACKET_KEY_ENTER           = 0x00000001,
   AUTO_BRACKET_KEY_TAB             = 0x00000002,
};

int def_autobracket_mode_keys;

enum FileTabSortOrders {
   FILETAB_ALPHABETICAL,
   FILETAB_MOST_RECENTLY_OPENED,
   FILETAB_MOST_RECENTLY_VIEWED,
   FILETAB_MANUAL,
};

enum FileTabNewFilePosition {
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
extern boolean _ComboBoxListVisible();
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

static enum StripTrailingSpacesOption {
   STSO_OFF = 0,
   STSO_STRIP_ALL = 1,
   STSO_STRIP_MODIFIED = 2
}

boolean def_hotfix_auto_prompt = true;

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

extern void _file_name_map_update_maps(_str (&vshPathMap):[], FILELANGMAP_FILEPATTERN (&vshPatternMap)[]);

extern _str _file_name_map_file_to_language(_str filename);

extern void _file_name_map_initialize();

#define F2LI_NO_CHECK_OPEN_BUFFERS     0x1            // do not check for file in list of open buffers
#define F2LI_NO_CHECK_PERFILE_DATA     0x2            // do not check data from previously opened files

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

extern void _set_ant_options(int identify, int maxSize);

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
#define BEAUT_FLAG_SNIPPET 0x1  
#define BEAUT_FLAG_TYPING  0x2
#define BEAUT_FLAG_AUTOBRACKET  0x4
#define BEAUT_FLAG_ALIAS   0x8
#define BEAUT_FLAG_NONE    0x0


/**
 * Flags for 
 * se.lang.api.LanguageSettings.getBeautifierExpansions 
 */
enum_flags BeautifierExpansions {
	BEAUT_EXPAND_SYNTAX,                  // Beautify syntax expansions.
	BEAUT_EXPAND_ON_EDIT,                 // Beautify as the user types.
	BEAUT_EXPAND_ALIAS,                   // Run the beautifier on language alias expansions.
	BEAUT_EXPAND_PASTE,                   // Beautify on paste or drag and drop.
};
#define BEAUT_EXPAND_DEFAULTS    (BEAUT_EXPAND_SYNTAX|BEAUT_EXPAND_ALIAS)

enum AutoBracePlace {
   AUTOBRACE_PLACE_SAMELINE,
   AUTOBRACE_PLACE_NEXTLINE,
   AUTOBRACE_PLACE_AFTERBLANK,
};

enum CommonBeautifierIndices {
   CBI_PROFILE_NAME = 0,
   CBI_LANG_ID,
   CBI_SYNTAX_INDENT,
   CBI_TAB_INDENT,
   CBI_INDENT_POLICY,
   CBI_MEMBER_ACCESS_INDENT,
   CBI_MEMBER_ACCESS_INDENT_WIDTH, 
   CBI_MEMBER_ACCESS_RELATIVE_INDENT,
   CBI_INDENT_CASE,
   CBI_CASE_INDENT_WIDTH,
   CBI_CONTINUATION_WIDTH,
   CBI_FUNCALL_PARAM_ALIGN,
   CBI_NL_AT_END_OF_FILE,
   CBI_ORIGINAL_TAB,
   CBI_INDENT_USE_ORIGINAL_TAB,
   CBI_RM_TRAILING_WS,
   CBI_RM_DUP_WS,
   COMMON_OPTION_END
};

int def_double_click_tab_action = 0;
int def_middle_click_tab_action = 0;

enum TabClickActions {
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
extern int _QToolbarGetDockArea(int);

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
extern void _MacGiveKeyToSlickEdit(boolean push_pop);

#if __MACOSX__
extern void _MacGetMemoryInfo(long &totalMemKSize,long &freeKSize);
#endif

extern void _ComboBoxSetDragDrop(int, int);

/**
 * Set the message to be displayed on the splash screen 
 * to indicate progress as we are initializing the editor. 
 */
extern void _SplashScreenStatus(_str msg);

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
extern boolean _EditorCtlSupportsDragDrop();

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
 *               <dt><b>'1'</b> <dd>find next document within tab group
 *               <dt><b>'2'</b> <dd>find previous document within tab group
 *               <dt><b>'F'</b> <dd>find first document within
 *               tab group
 *               <dt><b>'Z'</b> <dd>find last document
 *               within tab group
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
extern int _MDINextDocumentWindow(int wid,_str option_letter,boolean move_or_close);
/**
 * Change size of window
 * 
 * @param wid    MDI child window id (editor wid)
 * @param add    Pixels to add or remove
 * @param before  size edge before or after wid.
 * 
 * @return Returns amount size of tile was changed.
 */
extern int _MDIChangeDocumentWindowSize(int wid,int add,boolean before);


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
 * Return window id's of all mdi windows
 *  
 * @param window_list  Array of mdi window window id's
 */
extern void _MDIGetMDIWindowList(int (&array)[]);
/**
 * Return window id most recently active MDI window
 *  
 *  
 * @return Return window id of most recently active MDI window
 */
extern int  _MDICurrent();
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

#endif

