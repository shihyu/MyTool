////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46714 $
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
#ifndef PROJECT_SH
#define PROJECT_SH


#define TOOLNAMEKEYPREFIX "usertool_"
#define APPTOOLNAMEKEYPREFIX "apptool_"
#define ALL_CONFIGS "All Configurations"
#define FIRST_CONFIG_NAME "Release"
#define PROJECT_OBJECTS "<ProjectObjects>"

#define BLANK_TREE_NODE_MSG "<double click here to add another entry>"

/*
  IMPORTANT: If you change this structure, you MUST change the code in
  GetAllConfigsToolInfo() and GetAllAppTypesToolInfo().  You will probably also
  need to modify isProjectToolModified().
*/
struct ProjectToolStruct {
   _str name;             // Target name displayed in combo box
   _str nameKey;          // key to tool info in OLD project file
   _str menuCmd;          // menu command
   _str cmd;              // command line
   _str caption;          // menu caption
   _str accel;            // menu key bindings
   int outputConcur;      // 1=output to build window
   int captureOutput;     // 1=capture output
   int hideOptions;       // 0=never, 1=empty, 2=always
   int clearProcessBuf;   // 1=clear the process buffer
   int saveOptions;       // 0=none,1=current,2=all,3=modified
   int changeDir;         // 1=change to project directory
   int explicitSave;      // 1=explicit save option: option was from project file
                          //  or directly selected using toggle buttons. This is set
                          //  to 0 when project file does not specify explicit save
                          //  options and we default to def_save_on_compile
   int useVsBuild;
   _str optionsDialog;    // Name of options dialog for compiler.  if '', no
                          // options dialog.

   _str otherOptions;     // Other options parsed into the %~other macro of cmd
                          // if there is a dialog for the compiler.

   boolean readOnly;      // Command line textbox is read only.  Can only be changed
                          // by changing the options in the dialog.
   boolean disableCaptureOutput;  // Capture Output frame is disabled.
   int buildFirst;    // When on, must invoke build command before invoking
                      // this command.  Disabled for compile, build, rebuild
   ProjectToolStruct apptoolHashtab:[];
   _str appletClass;       // If this is an execute tool, it could be an applet.
                           // If it is an applet, we offer the user an option to
                           // specify an applet class, but it is not part of the
                           // command line, and it has to be parsed out during
                           // readAndParseProjectToolList.
   int runInXterm;         // 1 to run command in an X terminal (xterm,aixterm,dtterm,...)
   _str outputExtension;   // extension that objects compiled with this command should have
   int noLinkObject;       // 0 if the output object of this command should be passed to the linker
   int verbose;            // 1 if this should cause vsbuild to be used with the -v option
   int beep;               // 1 if this should cause vsbuild to be used with the -beep option
   _str preMacro;          // macro to run before this command is executed
   //_str postMacro;         // macro to run after this command is executed
};

struct ProjectFilterStruct {
   _str name;             // filter name
   _str pattern;          // filter pattern: each subpattern semicolon separated
   _str command;          // application command
   int useFileAssoc;      // 1=use file association (Windows only)
};
struct ProjectDirStruct {
   //_str WorkingDir;
   _str UserIncludeDirs;
   _str SystemIncludeDirs;
   _str ReferencesFile;
};
struct ProjectCmdStruct {
   _str PreBuildCmds;   // Pre-build commands to be executed by vsbuild
   _str PostBuildCmds;  // Post-build commands to be executed by vsbuild
   _str StopOnPreBuildErrors;
   _str StopOnPostBuildErrors;
};
struct ProjectConfigInfo {
   int                 FilesViewId;    //Files that are specific to this configuration
   ProjectDirStruct    DirInfo;        //Directory info for this configuration
   ProjectToolStruct   ToolInfo[];     //Tool information for this configuration
   ProjectCmdStruct    CmdInfo;        //Pre/Post build command lists
   //_str                Macro;          //Macro for this configuration
   _str                Classpath;      //Classpath for java
   _str                AppType;        //Execution type.  This just for java right now
   _str                Libs;           //List of libraries to link with
   _str                OutputFile;     //Target output file name
   //_str                LangType;       //Language of the configuration (c, java, etc)
};
struct ProjectAllConfigs {
   ProjectConfigInfo ProjectSettings:[];     //Indexed by config name
   _str Macro;
   _str WorkingDir;
   _str AppTypeList;
   _str AutoMakefile;
   _str BuildSystem; // 'vsbuild', 'automakefile', or blank implies custom
};

struct PROJECT_RULE_INFO {
   _str InputExts;        
   _str OutputExts;
   int LinkObject;
   _str Dialog;
   int Deletable;
   _str RunFromDir;

   _str Exec_Type;             // Type attribute from first <Exec>
   _str Exec_CmdLine;          // CmdLine attribute from first <Exec>
   _str Exec_OtherOptions;     // OtherOptions attribute from first <Exec>
};

struct PROJECT_TARGET_INFO {
   _str Name;             // Target name displayed in combo box
   _str MenuCaption;
   _str OutputExts;
   int LinkObject;
   int BuildFirst;
   int Verbose;
   int Beep;
   _str SaveOption;
   _str Dialog;
   int Deletable;
   _str ShowOnMenu;
   int EnableBuildFirst;
   _str CaptureOutputWith;
   int ClearProcessBuffer;
   int RunInXterm;
   _str PreMacro;
   _str RunFromDir;
   _str AppletClass;

   _str Exec_Type;             // Type attribute from first <Exec>
   _str Exec_CmdLine;          // CmdLine attribute from first <Exec>
   _str Exec_OtherOptions;     // OtherOptions attribute from first <Exec>

   PROJECT_RULE_INFO Rules:[]; // Rules that extend this target
};

struct PROJECT_DEPENDENCY_INFO {
   _str Project;
   _str Config;
   _str Target;
};

struct PROJECT_CONFIG_INFO {
   _str Name;
   _str Type;   // 'java', 'gnuc', 'vcpp', or blank implies custom
   _str AppType;  // One of AppTypes from AppTypeList or blank if AppTypeList not set
   _str AppTypeList;  // Comma delimited list of AppType names or blank
   _str RefFile;
   _str OutputFile;
   _str DebugCallbackName;
   _str ObjectDir;
   _str Libs;         // Space delimited list of libs
   _str Includes;     // PATHSEP delimited list of include directories.  This is not an array because project properties
                      // needs to compare these commands.
   _str AssociatedIncludes; // PATHSEP delimited list of include directories.  This is not an array because project properties
                            // needs to compare these commands.
   int StopOnPreBuildError;
   _str PreBuildCommands;   // \1 delimited list of command lines.  This is not an array because project properties
                            // needs to compare these commands.
   int StopOnPostBuildError;
   _str PostBuildCommands;  // \1 delimited list of command lines.  This is not an array because project properties
                            // needs to compare these commands.
   _str ClassPath;          // PATHSEP delimite list.  This is not an array because project properties
                            // needs to compare these commands.
   _str CompilerConfigName;
   _str Defines;
   _str AssociatedDefines;
   PROJECT_TARGET_INFO TargetInfo:[];
   _str TargetList;         // \1 delimited list of target names.
   PROJECT_DEPENDENCY_INFO DependencyInfo:[]; // list of projects this config is dependent upon
   boolean IncludesMatchForAllConfigs;
};

struct VS2005SolutionItems{
   _str FolderName;
   _str FolderGuid;
   _str ParentGuid;
   _str SolutionFiles[];
};

#define APPTYPE_APPLET      "applet"
#define APPTYPE_APPLICATION "application"
#define APPTYPE_J2ME        "j2me"
#define APPTYPE_GWT         "gwt"
#define APPTYPE_ANDROID     "android"
#define APPTYPE_CUSTOM      "custom"

#define SAVENONE 0
#define SAVECURRENT 1
#define SAVEALL 2
#define SAVEMODIFIED 3
#define SAVEWORKSPACEFILES 4
#define SAVENONUNIFORMOPTIONS 5

#define HIDENEVER  0
#define HIDEEMPTY  1
#define HIDEALWAYS 2
#define HIDENONUNIFORMOPTIONS 3

#define PROJECTPROPERTIES_TABINDEX_FILES        0
#define PROJECTPROPERTIES_TABINDEX_DIRECTORIES  1
#define PROJECTPROPERTIES_TABINDEX_TOOLS        2
#define PROJECTPROPERTIES_TABINDEX_BUILDOPTIONS 3
#define PROJECTPROPERTIES_TABINDEX_COMPILELINK  4
#define PROJECTPROPERTIES_TABINDEX_DEPENDENCIES 5
#define PROJECTPROPERTIES_TABINDEX_OPENCOMMAND  6

// the filename part regex is redefined here because the builtin \:f does not support
// spaces within filenames
#if __UNIX__
   #define PROJ_FILENAME_REGEX "([^/\\t\"']+)"
   
   // this has to be separate from PROJ_FILENAME_REGEX because parens cannot be allowed for this case
   #define EXT_SPECIFIC_COMPILE_REGEX "compile\\("  "([^/\\t\"'\\(\\)]+)"  "\\)"
#else
   #define PROJ_FILENAME_REGEX "([^\\[\\]\\:\\\\/<>|=+;,\\t\"']+)"
   
   // this has to be separate from PROJ_FILENAME_REGEX because parens cannot be allowed for this case
   #define EXT_SPECIFIC_COMPILE_REGEX "compile\\("  "([^\\[\\]\\:\\\\/<>|=+;,\\t\"'\\(\\)]+)"  "\\)"
#endif


struct WILDCARD_FILE_ATTRIBUTES {
   boolean Recurse;
   _str Excludes;
};
struct XMLVARIATIONS {
   _str vpjx_files;
   _str vpjtag_folder;
   _str vpjattr_folderName;
   _str vpjattr_filters;
   _str vpjtag_f;
   _str vpjattr_n;
   boolean doNormalizeFile;
};

// options to give to boolean _ProjectGet_Option
#define PROJ_OPT_WCHAR_NATIVE    1
#define PROJ_OPT_VC6_RULES       2

/**
 * Retrieves the file version from a Visual Studio solution (.sln)
 * 
 * @param SolutionFilePath
 *               Full path to solution file
 * 
 * @return The solution file version, eg- '9.0'
 * @example Current file versions are:
 * '7.0' - Visual Studio 2002
 * '8.0' - Visual Studio 2003
 * '9.0' - Visual Studio 2005
 */
extern _str vstudio_solution_file_version(_str SolutionFilePath);

/**
 * Determines the version of Visual Studio to be used with a solution.
 * 
 * @param SolutionFilePath Full path to solution file
 * 
 * @return The Visual Studio version, eg- '7.1'
 * @example Current Visual Studio application versions:
 * '7.0' - Visual Studio 2002
 * '7.1' - Visual Studio 2003
 * '8.0' - Visual Studio 2005
 */
extern _str vstudio_application_version(_str SolutionFilePath);

#endif
