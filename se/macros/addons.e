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
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "doscmds.e"
#import "main.e"
#import "options.e"
#import "setupext.e"
#endregion

static const DEFAULTS_FILE= 'defaults';
static const SLICKDEF_FILE= 'slickdef';
static const WINDEFS_FILE= 'windefs';
static const MACOSXDEFS_FILE= 'macosxdefs';
static const COMMONDEFS_FILE= 'commondefs';

/**
 * Core shared libraries that are required just to get off the ground.
 */
static _str gCoreDLLModules[] = {
   "vsockapi"
};

/**
 * Slick-C module that are required to taxi to the runway and load
 * default.e, commondefs.e, and windefs.e, etc.
 */
static _str gIntrinsicSlickCModules[] = {
   // Other stuff
   "saveload",
   "files",
   "filewatch",
   "stdprocs",
   "stdcmds",
   "compile",
   "error",
   "last",
   "cfg",
   "csv",
   "url",
   "xmlcfg",
   "xml",
   "tbsearch",
   "tbshell",
   "tbterminal",
   "output",
   "mouse",  // Need mou_hour_glass
   "cua",
   "reflow",
   "options",
   "bind",
   "recmacro",
   "sellist",
   "listedit",
   "eclipse",
   "put",
   "complete",
   "window",
   "moveedge",
   "markfilt",
   "search",
   "clipbd",
   "quickstart",
};

/**
 * Slick-C class modules that are required to be loaded early on. 
 */
static _str gSlickCClassModules[] = {

   // Slick-C language intrinsics
   "sc/lang/DelayTimer",
   "sc/lang/IIterable",
   "sc/lang/IAssignTo",
   "sc/lang/IEquals",
   "sc/lang/IComparable",
   "sc/lang/IControlID",
   "sc/lang/IHashable",
   "sc/lang/IIndexable",
   "sc/lang/IArray",
   "sc/lang/IHashIndexable",
   "sc/lang/IHashTable",
   "sc/lang/IToString",
   "sc/lang/Range",
   "sc/lang/String",
   "sc/lang/Timer",
   "sc/lang/ScopedValueGuard",
   "sc/lang/ScopedTimeoutGuard",

   // Slick-C collection classes
   "sc/collections/Stack",
   "sc/collections/IList",
   "sc/collections/IMultiMap",
   "sc/collections/List",
   "sc/collections/Map",
   "sc/collections/MapItemCompare",
   "sc/collections/MultiMap",

   // Slick-C controls classes
   "sc/controls/SaveActiveWindow",
   "sc/controls/Table",

   // Slick-C editor utility classes
   "sc/editor/SavePosition",
   "sc/editor/SaveSearch",
   "sc/editor/TempEditor",
   "sc/editor/LockSelection",

   // Slick-C net classes and interfaces
   "sc/net/ISocketCommon",
   "sc/net/IServerSocket",
   "sc/net/IClientSocket",
   "sc/net/Socket",
   "sc/net/ServerSocket",
   "sc/net/ClientSocket",

   // Slick-C util classes and interfaces
   "sc/util/Rect",
   "sc/util/Point",

   // Filter functor interface
   "se/util/IFilter",

   // Observer functor interface
   "se/util/IObserver",

   // PathMapper class
   "se/util/IPathMapper",
   "se/util/PathMapper",

   // LanguageSettings api
   "se/lang/api/LanguageSettings",
   "se/lang/api/ExtensionSettings",
   "se/lang/api/BlockCommentSettings",

   // Advanced file type mapping
   "se/files/FileNameMapper",
   "filetypemanager",

   // Slick-C file utility classes
   "se/files/FileWatcherManager",
};

/**
 * Slick-C modules that are ran to set up default key bindings and settings.
 */
static _str gDefaultSlickCModules[] = {
   DEFAULTS_FILE,
   COMMONDEFS_FILE,
   WINDEFS_FILE,
};

/**
 * Slick-C module that are required to just get off the ground and load sysobjs.e.
 */
static _str gCoreSlickCModules[] = {

   // DJB 08-07-2013
   // Reloading error.e has not been necessary for years.
   //"error",   // After setting def_error_re, init again
   "forall",
   "math",
   "dir",
   "fileman",
   "get",
   "restore",
   "c",
   "cfcthelp",
   "cidexpr",
   "csymbols",
   "ccontext",
   "cjava",
   "cutil",
   "smartp",
   "pascal",
   "slickc",
   "codehelp",
   "codehelputil",

   // DJB (07/03/2006)
   // always load language support, even on Windows
   "4gl",
   "progress4gl",
   "actionscript",
   "ada",
   "ansic",
   "antlr",
   "asm",
   "awk",
   "clojure",
   //"ch",  //  don't need a macro file for this any more.
   "cics",
   "cobol",
   "d",
   "db2",
   "fortran",
   "gradle",
   "groovy",
   "json",
   "model204",
   "modula",
   "msqbas",
   "objc",
   "perl",
   "pl1",
   "plsql",
   "prg",
   "properties",
   "python",
   "ruby",
   "rul",
   "sas",
   "sqlservr",
   "tcl",
   "vbscript",
   "verilog",
   "vhdl",
   "lua",
   "css",
   "systemverilog",
   "vera",
   "ps1",
   "javascript",
   "erlang",
   "haskell",
   "fsharp",
   "markdown",
   "coffeescript",
   "googlego",
   "ttcn",
   "cg",
   "matlab",
   "sbt",
   "scala",
   "kotlin",
   "protocolbuf",
   "pro",
   "sabl",
   "cmake",
   "ninja",
   "swift",
   "rlang",
   "rust",

   "pmatch",
   "doscmds",
   "os2cmds",
   "extern",
   "env",
   "util",
   "selcob",
   //"index",
};

/**
 * The rest of the Slick-C modules we need to load.
 */
static _str gOtherSlickCModules[] = {

   // load _open_temp_view,_delete_temp_view,_create_temp_view ...
   "sellist2",
   "seltree",
   "ini",
   "menu",
   "tags",
   "taggui",
   "taghilite",
   "ctags",
   "compare",
   "alias",
   "bookmark",
   "pushtag",
   "dlgeditv",
   "deupdate",
   "dlgman",
   "tbfilelist",
   "controls",
   "spin",
   "listbox",
   "treeview",
   "sstab",
   "combobox",
   "dirlist",
   "dirlistbox",
   "dirtree",
   "drvlist",
   "filelist",
   "frmopen",
   "guiopen",
   "listproc",
   "color",
   "guicd",
   "picture",
   "inslit",
   "filters",
   "font",
   "wfont",
   "fsort",
   "spell",
   "mprompt",
   "seek",
   "projconv",
   "projgui",
   "projutil",
   "fileproject",
   "project",
   "ptoolbar",
   "tbopen",
   "vstudiosln",
   "wkspace",
   "newworkspace",
   "projmake",
   "wman",
   "packs",
   "rte",
   "tbfind",

   "docsearch",
   "guifind",
   "guireplace",

   "ftpq",
   "ftp",
   "ftpclien",
   "ftpopen",
   "ftpparse",
   "sftp",
   "sftpclien",
   "sftpopen",
   "sftpparse",
   "sftpq",
   "makefile",
   "context",
   "cbrowser",
   "autocomplete",
   // Be sure that proctree stays under cbrowser because cbrowser loads the bitmaps
   "proctree",
   "tbclass",
   "caddmem",
   "printcommon",
   "winman",
   "print",
   "b2k",
   "keybindings",
   "event",
   "mfsearch",
   "bgsearch",
   "dockchannel",
   "toolbar",
   "qtoolbar",
   "tbview",
   "tbcontrols",
   "tbdefault",
   "tbprops",
   "tbcmds",
   "tbdeltasave",
   //tbResetAll(); // Setup initial toolbars
   "searchcb",
   "config",
   "pconfig",
   "filecfg",
   "fontcfg",
   "setupext",

   // Need to load this early for modules that need tw_find_form()
   "se/ui/tblegacy",
   "se/ui/toolwindow",
   "se/ui/mainwindow",
   "se/ui/twprops",
   "se/ui/twevent",
   "se/ui/twautohide",

   // VersionControlSettings api
   "se/vc/VersionControlSettings",

   "calc",
   "hex",
   //"readonly",
   //"findfile",
   "menuedit",
   "tagwin",
   "tagrefs",
   "tagcalls",
   "tagfind",
   "backtag",
   "tagform",
   "debug",
   "debuggui",
   "debugpkg",
   "deltasave",
   "coolfeatures",
   "tbregex",
   "errorcfgdlg",
   "hotspots",
   "tbprojectcb",
   "guidgen",
   "licensemgr",
   "moveline",
   "tbclipbd",
   "docbook",
   "rexx",
   "tbxmloutline",
   "bhrepobrowser",
   "gitrepobrowser",

   // All Languages
   "se/options/AllLanguagesTable",
   "alllanguages",

   "varedit",
   "aliasedt",
   "pipe",
   "plgman",
};

/**
 * Other shared libraries that we need to load.
 */
static _str gOtherDLLModules[] = {
   "vsscc",
   "tagsdb",
   "cparse",
   "cformat",
   "filewatcher",
   "vccache",
   "vsdebug",
   "vsrefactor",
   "vsRTE",
   "vsvcs",
   "vsxmlutl",

   "winutils",
   "vchack",
};

/**
 * Final set of Slick-C modules to load after all DLLs are loaded.
 */
static _str gDLLDependantSlickCModules[] = {
   "vlstobjs",
   "savecfg",
   "ccode",
   "selcode",
   "seldisp",
   "calib",

   "vchack",

   // want hour glass code soon.
   "se/util/MousePointerGuard",
   "diff",
   "diffprog",
   "diffedit",
   "diffmf",
   "diffencode",
   "diffinsertsym",
   "difftags",
   "se/diff/DiffSession",
   "diffsetup",
   "merge",
   "history",
   "compword",
   "cformat",
   "csbeaut",
   "beautifier",
   "hformat",
   "adaformat",
   "refactor",
   "refactorgui",
   "javacompilergui",
   "jrefactor",
   "quickrefactor",
   "java",

   // DJB (07/03/2006)
   // always load these, even on Windows
   "argument",
   "briefsch",
   "briefutl",
   "poperror",

   "prefix",
   "emacs",
   "gemacs",

   "ex",
   "vi",
   "vicmode",
   "viimode",
   "vivmode",
   "ispf",
   "ispflc",
   "ispfsrch",

   "html",
   "htmltool",
   "bufftabs",
   "enum",
   "box",
   "commentformat",
   "xmlwrap",
   "xmlwrapgui",
   "ppedit",
   "autosave",
   "xmldoc",
   "javadoc",
   "javaopts",
   "applet",
   "gwt",
   "ejb",
   "wizard",
   "gnucopts",
   "vcppopts",
   "phpopts",
   "pythonopts",
   "perlopts",
   "rubyopts",
   "monoopts",

   "svc",
   "vc",
   "svcurl",
   "svchistory",
   "svcupdate",
   "svcrepobrowser",
   "svcquery",
   "svcstash",
   "svcswitch",
   "cvsutil",
   "svccomment",
   "svcpushpull",
   "mercurial",

   "se/vc/IVersionControl",
   "se/vc/IVersionedFile",
   "se/vc/BackupHistoryVersionedFile",
   "se/vc/GitVersionedFile",
   "se/vc/HgVersionedFile",
   "se/vc/PerforceVersionedFile",
   "se/vc/SVNVersionedFile",
   "se/vc/CVSClass",
   "se/vc/GitClass",
   "se/vc/Hg",
   "se/vc/Perforce",
   "se/vc/SVN",
   "se/vc/VCCacheManager",
   "se/vc/VCRepositoryCache",
   "se/vc/VCBaseRevisionItem",
   "se/vc/VCBranch",
   "se/vc/IBuildFile",
   "se/vc/CVSBuildFile",
   "se/vc/GitBuildFile",
   "se/vc/HgBuildFile",
   "se/vc/NormalBuildFile",
   "se/vc/SubversionBuildFile",
   "se/vc/VCCacheExterns",
   "se/vc/VCExclusion",
   "se/vc/VCFile",
   "se/vc/VCFileType",
   "se/vc/VCInfo",
   "se/vc/VCLabel",
   "se/vc/VCRepository",
   "se/vc/VCRevision",
   "se/vc/SVNCache",
   "se/vc/QueuedVCCommand",
   "se/vc/QueuedVCCommandManager",

   "subversion",
   "svcautodetect",
   "subversionbrowser",
   "subversionutil",
   "historydiff",
   "surround",
   "j2me",
   "upcheck",
   "hotfix",
   "contact_support",
   "junit",
   "unittest",
   "xcode",
   "maven",
   "codetemplate",
   "ctcategory",
   "ctitem",
   "ctadditem",
   "ctviews",
   "ctmanager",
   "ctoptions",
   // moved this from a batch macro - sg - 12.11.07
   "assocft",
   "android",
   "tornado",
   "layouts",

   // adaptive formatting - sg - 9.18.07
   "sc/collections/Stack",
   "se/adapt/AdaptiveFormattingScannerBase",
   "se/adapt/GenericAdaptiveFormattingScanner",
   "se/lang/cpp/CPPAdaptiveFormattingScanner",
   "se/lang/pas/PascalAdaptiveFormattingScanner",
   "se/lang/dbase/DBaseAdaptiveFormattingScanner",
   "se/lang/tcl/TCLAdaptiveFormattingScanner",
   "se/lang/html/HTMLAdaptiveFormattingScanner",
   "adaptiveformatting",

   // new options dialog - sg - 9.11.07
   "se/options/IPropertyDependency",
   "se/options/PropertyDependencySet",
   "se/options/CategoryHelpPanel",
   "se/options/Condition",
   "se/options/IPropertyTreeMember",
   "se/options/Property",
   "se/options/PropertyGroup",
   "se/options/BooleanProperty",
   "se/options/ColorProperty",
   "se/options/DependencyTree",
   "se/options/NumericProperty",
   "se/options/Path",
   "se/options/PropertyGetterSetter",
   "se/options/RelationTable",
   "se/options/Select",
   "se/options/SelectChoice",
   "se/options/TextProperty",
   "se/options/OptionsPanelInfo",
   "se/options/DialogTransformer",
   "se/options/DialogEmbedder",
   "se/options/DialogExporter",
   "se/options/DialogTagger",
   "se/options/PropertySheet",
   "se/options/PropertySheetEmbedder",
   "se/options/OptionsXMLParser",
   "se/options/OptionsData",
   "se/options/OptionsHistoryNavigator",
   "se/options/OptionsTree",
   "se/options/OptionsConfigTree",
   "se/options/OptionsExportTree",
   "se/options/OptionsImportTree",
   "se/options/ExportImportGroup",
   "se/options/ExportImportGroupManager",
   "se/options/OptionsConfigurationXMLParser",
   "optionsxml",
   "propertysheetform",

   "sc/controls/CheckboxTree",
   "se/options/OptionsCheckBoxTree",
   "sc/controls/RubberBand",

   // Message Lists
   "se/util/Observer",
   "se/util/Subject",
   "se/lineinfo/FieldInfo",
   "se/lineinfo/LineInfo",
   "se/lineinfo/LineInfoCollection",
   "se/lineinfo/LineInfoBrowser",
   "se/lineinfo/LineInfoDefinitions",
   "se/lineinfo/LineInfoFiles",
   "se/lineinfo/RelocatableMarker",
   "se/lineinfo/TypeInfo",
   "se/messages/Message",
   "se/messages/MessageCollection",
   "se/messages/MessageBrowser",

   // DateTime
   "se/datetime/DateTime",
   "se/datetime/DateTimeDuration",
   "se/datetime/DateTimeInterval",
   "se/datetime/DateTimeFilters",
   "annotations",
   "calendar",

   // Tagging and Symbol Coloring
   "se/tags/SymbolInfo",
   "se/tags/SymbolTable",
   "se/tags/TaggingGuard",
   "se/color/ColorInfo",
   "se/color/ColorScheme",
   "se/color/DefaultColorsConfig",
   "se/color/IColorCollection",
   "se/color/LineNumberRanges",
   "se/color/SymbolColorRule",
   "se/color/SymbolColorRuleBase",
   "se/color/SymbolColorRuleIndex",
   "se/color/SymbolColorAnalyzer",
   "se/color/SymbolColorConfig",
   "se/color/SymbolColorDoubleBuffer",

   // Net
   "se/net/IOnCancelHandler",
   "se/net/IServerConnection",
   "se/net/IServerConnectionObserver",
   "se/net/ServerConnection",
   "se/net/ServerConnectionObserver",
   "se/net/ServerConnectionObserverDialog",
   "se/net/ServerConnectionObserverMessage",
   "se/net/ServerConnectionObserverFormInstance",
   "se/net/ServerConnectionPool",

   // Search
   "se/search/SearchResults",
   "se/search/FindNextFile",
   "se/search/SearchExpr",
   "se/search/SearchColors",

   "vsnet",
   "codewarrior",
   "bbedit",

   // DBGp
   "se/debug/dbgp/dbgp",
   "se/debug/dbgp/dbgputil",
   "se/debug/dbgp/DBGpOptions",

   // Xdebug
   "se/debug/xdebug/xdebug",
   "se/debug/xdebug/xdebugattach",
   "se/debug/xdebug/xdebugutil",
   "se/debug/xdebug/xdebugprojutil",
   "se/debug/xdebug/XdebugConnectionMonitor",
   "se/debug/xdebug/XdebugConnectionProgressDialog",
   "se/debug/xdebug/XdebugOptions",

   // pydbgp
   "se/debug/pydbgp/pydbgp",
   "se/debug/pydbgp/pydbgpattach",
   "se/debug/pydbgp/pydbgputil",
   "se/debug/pydbgp/PydbgpConnectionMonitor",
   "se/debug/pydbgp/PydbgpConnectionProgressDialog",

   // menu and toolbar customizations
   "sc/controls/customizations/UserControl",
   "sc/controls/customizations/MenuControl",
   "sc/controls/customizations/ToolbarControl",
   "sc/controls/customizations/UserModification",
   "sc/controls/customizations/MenuModification",
   "sc/controls/customizations/ToolbarModification",
   "sc/controls/customizations/Separator",
   "sc/controls/customizations/MenuSeparator",
   "sc/controls/customizations/ToolbarSeparator",
   "sc/controls/customizations/CustomizationHandler",
   "sc/controls/customizations/MenuCustomizationHandler",
   "sc/controls/customizations/ToolbarCustomizationHandler",

   // perl5db
   "se/debug/perl5db/perl5db",
   "se/debug/perl5db/perl5dbattach",
   "se/debug/perl5db/Perl5dbConnectionMonitor",
   "se/debug/perl5db/Perl5dbConnectionProgressDialog",
   "se/debug/perl5db/perl5dbutil",

   // rdbgp
   "se/debug/rdbgp/rdbgp",
   "se/debug/rdbgp/rdbgpattach",
   "se/debug/rdbgp/RdbgpConnectionMonitor",
   "se/debug/rdbgp/RdbgpConnectionProgressDialog",
   "se/debug/rdbgp/rdbgputil",

   // jdwp, windbg, lldb, gdb, and mono
   "se/debug/java/jdwp",
   "se/debug/windbg/windbg",
   "se/debug/lldb/lldb",
   "se/debug/gdb/gdb",
   "se/debug/mono/mono",

   // product improvement program
   "pip",
   "enterpriseoptions",

   // notifications
   "notifications",
   "tbnotification",

   "se/ui/IHotspotMarker",
   "se/ui/IKeyEventCallback",
   "se/ui/ITextChangeListener",
   "se/ui/IOvertypeListener",
   "se/ui/TextChange",
   "se/ui/EventUI",
   "se/ui/NavMarker",
   "se/ui/OvertypeMarker",
   "se/ui/StreamMarkerGroup",
   "se/ui/HotspotMarkers",
   "se/ui/DocSearchForm",

   // auto bracket
   "se/autobracket/IAutoBracket",
   "se/autobracket/DefaultAutoBracket",
   "se/autobracket/AutoBracketListener",
   "se/lang/generic/GenericAutoBracket",
   "se/lang/cpp/CPPAutoBracket",
   "se/lang/objectivec/ObjectiveCAutoBracket",
   "se/lang/markdown/MarkdownAutoBracket",
   "se/lang/matlab/MatlabAutoBracket",
   "se/lang/xml/XMLAutoBracket",
   "se/ui/AutoBracketMarker",
   "se/alias/AliasFile",
   "autobracket",

   // toast notification messages
   "toast",
};

/**
 * Slick-C modules that only need to be compiled, but not loaded. 
 * Typically, these modules are ones that contain a defmain(), that is, 
 * they are Slick-C batch scripts. 
 */
static _str gCompileOnlySlickCModules[] = {
   SYSOBJS_FILE,
   "addons",
   "altsetup",
   "bbeditdef",
   "briefdef",
   "cleanup",
   "cmmode",
   "codewarriordef",
   "codewrightdef",
   "commondefs",
   "defaults",
   "cwprojconv",
   "draw",
   "eclipsedef",
   //"editflst",
   "emacsdef",
   "emulate",
   "fill",
   "gendtd",
   "gnudef",
   "guisetup",
   "ispfdef",
   "macosxdefs",
   "maketags",
   "postinstall",
   "slickdef",
   "updateobjs",
   "vcppdef",
   "videf",
   "vlstcfg",
   "vlstkeys",
   "vlstobjs",
   "vsnetdef",
   "vusrmods",
   "windefs",
   "xcodedef",
   "convert2cfgxml",
   "convert_box_ini",
   "convert_def_vc_providers",
   "convert_errorre_xml",
   "convert_searches_xml",
   "convert_symbolcoloring_xml",
   "convert_uformat_ini",
   "convert_ftp_ini",
   "convert_uscheme_ini",
   "convert_vusr_beautifier_xml",
   "convertvlx2cfgxml",
   "lang2cfgxml",
};


/**
 * Maximum number of 'vstw' processes to run asynchronously.
 */
const MAX_VSTW_PROCESSES = 8;

/**
 * Compile and optionally load or run a set of Slick-C modules. 
 * The compiles are launched asynchronously in the background, so that they 
 * can be done in parallel.  The modules are then loaded by the main thread 
 * synchronously in the order that they were given. 
 * 
 * @param path          path to macros directory
 * @param moduleList    array of strings with modules names to load
 * @param doLoad        'true' if we want load the modules after compiling them
 * @param doShell       'true' if we want to run the modules after compiling them
 */
static void makeNloadArray(_str path, _str (&moduleList)[], bool doLoad=true, bool doShell=false)
{

   int makeProcessIds[];
   compile_i := load_i := 0;
   _maybe_append_filesep(path);

   loop {
      // launch asynchronous builds of this item
      while (compile_i < moduleList._length() && compile_i-load_i < MAX_VSTW_PROCESSES) {
         macro_filename := moduleList[compile_i];
         macro_filename = stranslate(macro_filename, FILESEP, "/");
         module_path := path:+macro_filename:+_macro_ext;
         message(nls('making:')' 'module_path);
         make_status := _make(_maybe_quote_filename(module_path), /*async*/true);
         //messageNwait("makeNloadArray: HERE");
         process_make_rc(make_status,module_path,true);
         makeProcessIds[compile_i++] = make_status;
      }

      // check if the first item in the list has finished
      while (load_i < makeProcessIds._length()) {
         if (makeProcessIds[load_i] != 0 && _IsProcessRunning(makeProcessIds[load_i])) {
            break;
         }
         if (doLoad) {
            macro_filename := moduleList[load_i];
            macro_filename = stranslate(macro_filename, FILESEP, "/");
            module_path := path:+macro_filename:+_macro_ext;
            makeNload(_maybe_quote_filename(module_path),doLoad);
         } else if (doShell) {
            macro_filename := moduleList[load_i];
            macro_filename = stranslate(macro_filename, FILESEP, "/");
            module_path := path:+macro_filename;
            rc = 0;
            status := shell('"':+module_path:+'"');
            process_make_rc(status,macro_filename);
         }
         makeProcessIds[load_i++] = 0;
         break;
      }

      // stop when everything is loaded and built
      if (compile_i >= moduleList._length() && load_i >= moduleList._length()) {
         //messageNwait("makeNloadArray: DONE HERE");
         break;
      }
   }
}

/**
 * Load an array of DLLs.
 * 
 * @param dllpath     path to 'win' directory where DLLs are located 
 * @param moduleList  list of DLLs to load
 */
static void dllloadNcheckArray(_str dllpath, _str (&moduleList)[])
{
   _maybe_append_filesep(dllpath);
   foreach (auto dll_filename in moduleList) {
      dll_filename = stranslate(dll_filename, FILESEP, "/");
      dllloadNcheck(dllpath:+dll_filename);
   }
}


static _str gMissingFileList[]=null;
defmain()
{
   gMissingFileList=null;
   int orig_def_actapp=def_actapp;
   def_actapp=0;
   _use_timers=0;
   dllpath := editor_name('P');
   _str filename;
   if (_isUnix()) {
      dllpath=editor_name('P');
      filename='';
   } else {
      filename=dllpath:+'cparse':+DLLEXT;
      _str qfilename=filename;
      if ( pos(' ',filename) ) {
         qfilename='"'qfilename'"';
      }
      if (file_match(' -p 'qfilename,1)=='') {
         filename=get_env('VSLICKBIN1'):+('cparse':+DLLEXT);
         dllpath=substr(filename,1,pathlen(filename));
      }
   }
#if 0
  if ( _menu_file_spec=='' && _help_file_spec=='' ) {
     options=lowcase(get_env('VSLICK'));
     parse options with '-m' _menu_file_spec .;
     parse options with '-h' _help_file_spec .;
  }
#endif
  /* find main and assume rest of macro source files there.*/
  path := "";
  name := "";
  new_name := "";
  if ( arg(1)!='' ) {
     path=arg(1);
  } else {
     /* Duplicating code here for SLICK_PATH_SEARCH() function */
     /* so that this code does not have to be in main.e */
     name='main'_macro_ext;
     new_name= path_search(name,_SLICKPATH);
     if ( new_name=='' ) {
        new_name= path_search(name);
     }
     path= substr(new_name,1,pathlen(new_name));
  }

  if (_isWindows()) {
     // Required early on for user config path information
     _dllexport("void winutils:ntGetSpecialFolderPath(VSHREFVAR hvarAppDataPath,int csidl_special_folder)",0,0);
  }

  // Load the intrinsic Slick-C modules
  makeNloadArray(path, gIntrinsicSlickCModules);

  // Load the Slick-C class modules
  makeNloadArray(path, gSlickCClassModules);

  // Load the Core DLL modules
  dllloadNcheckArray(dllpath, gCoreDLLModules);

  // now we can set up defaults and keybindings
  if (_isMac()) gDefaultSlickCModules :+= MACOSXDEFS_FILE;
  makeNloadArray(path, gDefaultSlickCModules, false, true);

  // Make sure we have some key bindings
  _set_emulation_key_bindings(true);

  // Load the Core Slick-C modules
  makeNloadArray(path, gCoreSlickCModules);

  // compile all the Slick-C batch macro files
  makeNloadArray(path, gCompileOnlySlickCModules, false);

  // Load system forms.
  rc='';
  //filename=get_env('VSROOT')'macros':+FILESEP:+(SYSOBJS_FILE:+_macro_ext);
  filename = path:+(SYSOBJS_FILE:+_macro_ext);
  if ( filename!='') {
     message(nls('Running %s',filename));
     rc=xcom('"'filename'"');
     process_make_rc(rc,filename);
  }
  menu_mdi_bind_all();
  if ( rc=='' || ! rc ) {
     clear_message();
  }

  // load other Slick-C modules
  makeNloadArray(path, gOtherSlickCModules);

  // load other DLL modules
  dllloadNcheckArray(dllpath, gOtherDLLModules);

  refresh();
  makeNload(path'help');   /* help must be loaded last. */
  if (_isUnix()) {
     dllloadNcheck(dllpath:+'vshlp');
  } else {
     _dllexport("int vshlp:_SaveSelDisp(VSPSZ pszFilename,VSPSZ pszFileDate)");
     _dllexport("int vshlp:_RestoreSelDisp(VSPSZ pszFilename,VSPSZ pszFileDate)");

     _dllexport("_command void vshlp:vshlp_version()",0,0);
     //_dllexport("int vshlp:_JavaGetClassRefList(VSPSZ pszClassFilename,VSHREFVAR hvarArray)",0,0);
     _dllexport("int vshlp:_InsertProjectFileList(VSHREFVAR,VSHREFVAR,,VSHREFVAR,int,int,int)",0,0);
     _dllexport("int vshlp:_InsertProjectFileListXML(int,VSHREFVAR,int,int,int,int,int,VSHREFVAR,int)",0,0);
     _dllexport("void vshlp:_InsertProjectFileListXML_WithoutFolders(int treeParentIndex,int workspaceHandle,VSHREFVAR hvarProjectHandleList,VSPSZ pszFilter,int pic_file)",0,0);
     _dllexport("void vshlp:_FreeSccDll()",0,0);
     _dllexport("int vshlp:_IsFileMatchedExtension(VSPSZ pszFilename,VSPSZ pszPattern)",0,0);
     _dllexport("int vshlp:_GetDiskSpace(VSPSZ pszPath,VSHREFVAR hvarTotalSpace,VSHREFVAR hvarFreeSpace)",0,0);
     _dllexport("int vshlp:_FilterTreeControl(VSPSZ pszFilter,int iPrefixFilter)",0,0);
     _dllexport("int vshlp:_FileTreeRemoveFileOriginFromFile(int iIndex, VSPSZ pszOriginsToRemove, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
     _dllexport("int vshlp:_FileTreeRemoveFileOrigin(VSPSZ pszOriginsToRemove, VSHREFVAR deletedCaptions, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
     _dllexport("void vshlp:_FileTreeAddFileOrigin(int index, VSPSZ pszAddedOrigins, int iBufId, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
     _dllexport("int vshlp:_FileTreeAddFile(VSPSZ pszFile, VSPSZ pszOrigins, int iBufId, VSPSZ pszFilter, VSHREFVAR htPicIndices)",0,0);
     _dllexport("int vshlp:_FileListAddFile(int iTreeIndex,VSPSZ pszFile,VSPSZ pszFilter,int iBufId,int iPicFile,int iTreeNodeFlags)",0,0);
     _dllexport("int vshlp:_FileListAddFilesInProject(VSPSZ pszWorkspaceFile,VSPSZ pszProjectFile,int iTreeIndex,int iPicIndex)",0,0);
     _dllexport("int vsvcs:DSUpgradeArchiveTree(VSPSZ pszOldConfigPath, VSPSZ pszConfigPathBase)",0,0);
  }

  // load other Slick-C modules that needed the DLL's loaded first
  makeNloadArray(path, gDLLDependantSlickCModules);

  // Now that all modules have been loaded. Do more setup for emulation.
  _set_emulation_key_bindings();
  _eventtab_get_mode_keys('process-keys',1);
  _eventtab_get_mode_keys('fileman-keys',1);
  _eventtab_get_mode_keys('grep-keys',1);

  // Mark system forms
  int index=name_match('',1,OBJECT_TYPE);
  for (;;) {
     if (!index) break;
     if (substr(name_name(index),1,1)!='-') {
        if (name_info(index)!='') set_name_info(index,'');
     } else {
        set_name_info(index,FF_SYSTEM);
     }
     index=name_match('',0,OBJECT_TYPE);
  }

  // restore app activation flags and timers
  def_actapp=orig_def_actapp;
  _use_timers=1;

  /* By convention, vusrmods is a batch program which loads all */
  /* user specific modules and restores the users previous setup. */
  _str vusrmods_name=slick_path_search(USERMODS_FILE:+_macro_ext);
  if ( vusrmods_name!='' ) {
     message(nls('Running %s',vusrmods_name));
     status := shell('"'vusrmods_name'"');
     if ( status ) {
        rc=status;
        return(status);
     }
  }

  // Let the user know about any files that were not restored
  showMissingFileList(gMissingFileList);
  rc=0;
  return(0);
}
static void dllloadNcheck(_str filename)
{
   int status=_dllload(filename);
   if (status==FILE_NOT_FOUND_RC) {
      static int numWarnings;
      gMissingFileList[gMissingFileList._length()]=filename'.dll';
      if (!numWarnings) {
         int result=_message_box(nls("DLL File %s not found\nThis maybe normal if you are building a small state file for an OEM installation, and you will not be warned about other missing DLLs\n\nContinue?",filename),'',MB_YESNO);
         if (result==IDNO) {
            stop();
         }
      }
      ++numWarnings;
   }
}

static void showMissingFileList(_str (&fileList)[])
{
   if (fileList!=null) {
      show('-modal _sellist_form','The following files were missing',0,fileList);
   }
}

