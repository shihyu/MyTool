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
#include "project.sh"
#include "xml.sh"
#import "applet.e"
#import "cjava.e"
#import "compile.e"
#import "env.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "javaopts.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projmake.e"
#import "projutil.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "wizard.e"
#import "wkspace.e"
#import "sstab.e"
#import "xmldoc.e"
#import "cformat.e"
#endregion

static const GNUCOPTS_FORM_HEIGHT=     5730;
static const GNUCOPTS_FORM_WIDTH=      6950;
static const COMPILE_AS_DEFAULT=       "default";
static const COMPILE_AS_CPP=           "c++";
static const COMPILE_AS_C=             "c";
static const COMPILE_AS_OBJECTIVE_C=   "objective-c";
static const OPTIMIZATION_LEVEL_NONE=  "None (-O0)";
static const OPTIMIZATION_LEVEL_LOW=   "Low (-O1)";
static const OPTIMIZATION_LEVEL_MED=   "Med (-O2)";
static const OPTIMIZATION_LEVEL_HIGH=  "High (-O3)";
static const OPTIMIZATION_LEVEL_NA=    "Default";
static const DEBUG_LEVEL_MINIMAL=      "Minimal (-g1)";
static const DEBUG_LEVEL_DEFAULT=      "Default (-g2)";
static const DEBUG_LEVEL_MAXIMAL=      "Maximal (-g3)";
static const DEBUG_LEVEL_NA=           "Default";
static const OUTPUT_TYPE_EXECUTABLE=   "Executable (gcc/g++)";
static const OUTPUT_TYPE_STATIC=       "Object Library (*.a built with ar -rs)";
static _str OUTPUT_TYPE_SHARED() {
   return  (_isMac()?"Shared Library (*.dylib built with gcc/g++ -shared -fPIC)":"Shared Library (*.so built with gcc/g++ -shared -fPIC)");
}
static const GNU_BLANK_TREE_NODE_MSG=  "<double click here to add another entry>";
static const ADV_CODEGEN_CAPTION=      "Code Generation";
static const ADV_DEBUG_CAPTION=        "Debug";
static const ADV_LANGUAGE_CAPTION=     "Language";
static const ADV_OPT_CAPTION=          "Optimization";
static const ADV_PREPROC_CAPTION=      "Preprocessor";
static const ADV_MACHINE_CAPTION=      "Machine";


struct GCC_OPTION_INFO {
   _str option;
   _str usage; // should be "C" for compiler, "L" for linker, "CL" for both
   _str description;
};

struct GCC_MACHINE_INFO {
   _str            architecture;
   GCC_OPTION_INFO options[];
};

// arrays of options that are populated during definit
/*static*/ GCC_OPTION_INFO GCC_WARNING_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_OVERALL_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_LANGUAGE_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_PREPROCESSOR_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_DEBUG_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_OPTIMIZATION_OPTIONS[];
/*static*/ GCC_OPTION_INFO GCC_CODEGENERATION_OPTIONS[];
/*static*/ GCC_MACHINE_INFO GCC_MACHINE_OPTIONS[];

// hash tables for array indexes by option
static int warningIndexes:[];
static int codeGenIndexes:[];
static int debugIndexes:[];
static int languageIndexes:[];
static int optimizationIndexes:[];
static int preProcessorIndexes:[];

static _str gConfigList[];
static bool gIsProjectTemplate;

// IMPORTANT: if you change the order or contents of this struct, you
//            *must* also change getAllGNUOptions().  you will most likely
//            want to change setGNUOptionDefaults().
struct GNUC_OPTIONS {
   // compile tab
   _str    compileInputExt; // key used to find the compile command in the project file
   _str    compiler; // gcc, g++, etc
   bool verbose; // -v
   bool usePipes; // -pipe
   bool saveTemps; // -save-temps
   bool ansi; // -ansi
   bool traditional; // -traditional
   _str    compileAs; // -x language
   _str    defines;
   _str    compilerOther;
   _str    inputFilename; // %f or %p%n%e

   // code generation tab
   _str    optimizationLevel; // -O#
   bool debugInfo; // -g
   bool ggdbExtensions; //-ggdb
   bool profilerInfo; // -p
   bool gprofInfo; // -pg
   _str    debugLevel; // -g#
   bool gasInfo;    // -mgas

   // link tab
   _str    linker; // gcc, g++, ar, etc
   bool noDefaultLibs; // -nodefaultlibs
   bool noStdLibs; // -nostdlibs
   bool linkStatic; // -static
   bool linkSymbolic; // -symbolic
   _str    outputType; // exe, static, shared
   _str    outputFilename;
   _str    libs;
   _str    linkerOther;

   // directories tab
   _str     userIncludeDirs;
   _str     systemIncludeDirs;

   // warnings tab
   bool showAllWarnings; // -Wall
   bool pedantic; // -pedantic
   bool warningsAsErrors; // -Werror
   bool inhibitWarnings; // -w
   int     advancedWarnings:[];

   // advanced tab
   int     advancedCodeGen:[];
   int     advancedDebug:[];
   int     advancedLanguage:[];
   int     advancedOptimization:[];
   int     advancedPreprocessor:[];
   int     advancedMachine:[];

   // debugger tab
   _str    debuggerName;
   _str    debuggerOptions;
   _str    programArguments;

   // target nodes
   int     compileTargetNode;
   int     linkTargetNode;
   int     debugTargetNode;
   int     executeTargetNode;
};

_control ctlWarningsTree, ctlAdvancedTree;
defeventtab _gnuc_options_form;
static _str GNUC_PROJECT_NAME(...) {
   if (arg()) ctlCancel.p_user=arg(1);
   return ctlCancel.p_user;
}
static _str GNUC_CHANGING_CONFIG(...) {
   if (arg()) ctlCurConfig.p_user=arg(1);
   return ctlCurConfig.p_user;
}
static int GNUC_GPROJECT_HANDLE(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}
static GNUC_OPTIONS GNUC_INFO(...):[] {                
   if (arg()) ctlVerbose.p_user=arg(1);
   return ctlVerbose.p_user;
}
static int ADV_CODEGEN_ROOT_NODE(...) {
   if (arg()) ctlNoDefaultLibs.p_user=arg(1);
   return ctlNoDefaultLibs.p_user;
}
static int ADV_DEBUG_ROOT_NODE(...) {
   if (arg()) ctlNoStdLibs.p_user=arg(1);
   return ctlNoStdLibs.p_user;
}
static int ADV_LANGUAGE_ROOT_NODE(...) {
   if (arg()) ctlStatic.p_user=arg(1);
   return ctlStatic.p_user;
}
static int ADV_OPT_ROOT_NODE(...) {
   if (arg()) ctlSymbolic.p_user=arg(1);
   return ctlSymbolic.p_user;
}
static int ADV_PREPROC_ROOT_NODE(...) {
   if (arg()) ctlOutputTypeLabel.p_user=arg(1);
   return ctlOutputTypeLabel.p_user;
}
static int ADV_MACHINE_ROOT_NODE(...) {
   if (arg()) ctlOutputFileLabel.p_user=arg(1);
   return ctlOutputFileLabel.p_user;
}

void ctlLinkOrder.lbutton_up()
{
   _str libList = show('-modal _link_order_form',ctlLibraries.p_text);

   if (libList :!= '') {
      // pressing OK with no libraries will return
      // PROJECT_OBJECTS instead of ''
      if (libList :== PROJECT_OBJECTS) {
         ctlLibraries.p_text = '';
      } else {
         ctlLibraries.p_text = libList;
      }
   }
}

void ctlok.on_create(int projectHandle, _str options = "", _str curConfig="",
                     _str projectFilename = _project_name, bool isProjectTemplate = false)
{
   // store project handle and template info
   gIsProjectTemplate = isProjectTemplate;

   // store the project filename for use throughout this form since this may not be
   // modifying settings from the active project
   GNUC_PROJECT_NAME(projectFilename);

   // load the options
   loadGNUOptionsFromXML(_getSysconfigMaybeFixPath("projects":+FILESEP:+"gnucopts.xml"));

   // load the configurations list
   wid := p_window_id;
   p_window_id = ctlCurConfig.p_window_id;
   _str tempConfigList[] = null;
   gConfigList._makeempty();
   _ProjectGet_ConfigNames(projectHandle, tempConfigList);
   int i;
   for(i = 0; i < tempConfigList._length(); i++) {
      // if this is a gnuc config, keep it
      if(strieq(_ProjectGet_Type(projectHandle, tempConfigList[i]), "gnuc")) {
         _lbadd_item(tempConfigList[i]);
         gConfigList[gConfigList._length()] = tempConfigList[i];
         continue;
      }
   }

   // add "All Configurations" to list
   _lbadd_item(PROJ_ALL_CONFIGS);
   _lbtop();

   // select the appropriate configuration
   if (_lbfind_and_select_item(curConfig)) {
      // if the current config is not in the list, default to 'all configurations'
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, '', true);
   }
   p_window_id = wid;

   // setup controls
   oncreateDirectories();
   oncreateWarningsTree();
   oncreateAdvancedTree();

   // split the options passed in to the form
   tabName := "";
   compileInputExt := "";
   parse options with tabName " " compileInputExt;
   if (tabName == "Run/Debug") tabName = "Link";

   // parse the commands for each configuration
   // NOTE: the same set of options is intentionally passed for both the compile
   //       and link tools to build a complete option set covering all gcc usage
   GNUC_OPTIONS gnuOptions:[] = null;

   int j;
   for(j = 0; j < gConfigList._length(); j++) {
      _str configName = gConfigList[j];
      if(configName == PROJ_ALL_CONFIGS) continue;

      // initialize the options for this config
      setGNUOptionDefaults(gnuOptions:[configName]);

      // find the nodes
      if(compileInputExt != "") {
         // find the compile rule that matches this extension
         getExtSpecificCompileInfo(compileInputExt, projectHandle, configName, "", "", gnuOptions:[configName].compileTargetNode, true, false);
      } else {
         gnuOptions:[configName].compileTargetNode = _ProjectGet_TargetNode(projectHandle, "compile", configName);
         gnuOptions:[configName].linkTargetNode = _ProjectGet_TargetNode(projectHandle, "link", configName);
      }

      gnuOptions:[configName].debugTargetNode = _ProjectGet_TargetNode(projectHandle, "debug", configName);
      gnuOptions:[configName].executeTargetNode = _ProjectGet_TargetNode(projectHandle, "execute", configName);

      // parse the commands
      getGNUOptions(projectHandle, configName, gnuOptions:[configName].compileTargetNode, gnuOptions:[configName]);
      getGNUOptions(projectHandle, configName, gnuOptions:[configName].linkTargetNode, gnuOptions:[configName]);
      getGNUOptions(projectHandle, configName, gnuOptions:[configName].debugTargetNode, gnuOptions:[configName]);
      getGNUOptions(projectHandle, configName, gnuOptions:[configName].executeTargetNode, gnuOptions:[configName]);
   }

   // store the options globally
   GNUC_INFO(gnuOptions);

   // load combo boxes
   // compile as combo box
   p_window_id = ctlCompileAs.p_window_id;
   _lbadd_item(COMPILE_AS_DEFAULT);
   _lbadd_item(COMPILE_AS_CPP);
   _lbadd_item(COMPILE_AS_C);
   _lbadd_item(COMPILE_AS_OBJECTIVE_C);
   _lbtop();

   // optimization level combo box
   p_window_id = ctlOptimizationLevel.p_window_id;
   _lbadd_item(OPTIMIZATION_LEVEL_NONE);
   _lbadd_item(OPTIMIZATION_LEVEL_LOW);
   _lbadd_item(OPTIMIZATION_LEVEL_MED);
   _lbadd_item(OPTIMIZATION_LEVEL_HIGH);
   _lbadd_item(OPTIMIZATION_LEVEL_NA);
   _lbtop();
//   p_parent.p_text = _lbget_text();

   // debug level combo box
   p_window_id = ctlDebugLevel.p_window_id;
   _lbadd_item(DEBUG_LEVEL_MINIMAL);
   _lbadd_item(DEBUG_LEVEL_DEFAULT);
   _lbadd_item(DEBUG_LEVEL_MAXIMAL);
   _lbadd_item(DEBUG_LEVEL_NA);
//   status = _lbsearch(DEBUG_LEVEL_DEFAULT);
//   if(status) {
      _lbtop();
//   }
//   p_parent.p_text = _lbget_text();

   // output type combo box
   p_window_id = ctlOutputType.p_window_id;
   _lbadd_item(OUTPUT_TYPE_EXECUTABLE);
   _lbadd_item(OUTPUT_TYPE_STATIC);
   _lbadd_item(OUTPUT_TYPE_SHARED());
   _lbtop();

   // save the project handle and populate the form by triggering the on_change handler
   GNUC_GPROJECT_HANDLE(projectHandle);
   ctlCurConfig.call_event(CHANGE_CLINE, ctlCurConfig, ON_CHANGE, 'W');

   // make the appropriate tab the active one
   if(options == "") {
      ctlss_main_tab._retrieve_value();
   } else {
      ctlss_main_tab.sstActivateTabByCaption(tabName);
   }

   // restore the window id
   p_window_id = wid;

   _gnuc_options_form_initial_alignment();
}

void ctlok.on_destroy()
{
   // clean up the hash tables used for option <-> array index
   warningIndexes._makeempty();
   codeGenIndexes._makeempty();
   debugIndexes._makeempty();
   languageIndexes._makeempty();
   optimizationIndexes._makeempty();
   preProcessorIndexes._makeempty();

   // Save the active tab
   _str value = ctlss_main_tab.p_ActiveTab;
   ctlss_main_tab._append_retrieve( ctlss_main_tab.p_window_id, value );
}

static void oncreateDirectories()
{
//   ctlMoveUserIncludesUp.p_y = ctlMoveUserIncludesUp.p_y - 345;
//   ctlMoveUserIncludesDown.p_y = ctlMoveUserIncludesDown.p_y - 345;

   //ctlUserIncludesList._TreeSetDelimitedItemList(GetDirInfo(GetConfigText(), "I"), PATHSEP, false);
   //ctlSystemIncludesList._TreeSetDelimitedItemList(GetDirInfo(GetConfigText(), "S"), PATHSEP, false);
}

static void oncreateWarningsTree()
{
   // setup columns
   ctlWarningsTree._TreeSetColButtonInfo(0, 2000, TREE_BUTTON_PUSHBUTTON | TREE_BUTTON_SORT, 0, "Option");
   ctlWarningsTree._TreeSetColButtonInfo(1, ctlWarningsTree.p_width - 2350, TREE_BUTTON_WRAP, 0, "Description");

   ctlWarningsTree._TreeSetListFromArray(GCC_WARNING_OPTIONS, TREE_ROOT_INDEX, false, warningIndexes);
}

static void oncreateAdvancedTree()
{
   // setup columns
   ctlAdvancedTree._TreeSetColButtonInfo(0, 2500, TREE_BUTTON_PUSHBUTTON, 0, "Option");
   ctlAdvancedTree._TreeSetColButtonInfo(1, ctlAdvancedTree.p_width - 2850, TREE_BUTTON_WRAP, 0, "Description");

   // code generation options
   ADV_CODEGEN_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_CODEGEN_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   ctlAdvancedTree._TreeSetListFromArray(GCC_CODEGENERATION_OPTIONS, ADV_CODEGEN_ROOT_NODE(), false, codeGenIndexes);

   // debug options
   ADV_DEBUG_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_DEBUG_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   ctlAdvancedTree._TreeSetListFromArray(GCC_DEBUG_OPTIONS, ADV_DEBUG_ROOT_NODE(), false, debugIndexes);

   // language options
   ADV_LANGUAGE_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_LANGUAGE_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   ctlAdvancedTree._TreeSetListFromArray(GCC_LANGUAGE_OPTIONS, ADV_LANGUAGE_ROOT_NODE(), false, languageIndexes);

   // optimization options
   ADV_OPT_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_OPT_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   ctlAdvancedTree._TreeSetListFromArray(GCC_OPTIMIZATION_OPTIONS, ADV_OPT_ROOT_NODE(), false, optimizationIndexes);

   // preprocessor options
   ADV_PREPROC_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_PREPROC_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   ctlAdvancedTree._TreeSetListFromArray(GCC_PREPROCESSOR_OPTIONS, ADV_PREPROC_ROOT_NODE(), false, preProcessorIndexes);

   // machine options
   ADV_MACHINE_ROOT_NODE(ctlAdvancedTree._TreeAddItem(TREE_ROOT_INDEX, ADV_MACHINE_CAPTION, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD));
   {
      // add the individual machine node
      int i;
      for(i = 0; i < GCC_MACHINE_OPTIONS._length(); i++) {
         int machineNode = ctlAdvancedTree._TreeAddItem(ADV_MACHINE_ROOT_NODE(), GCC_MACHINE_OPTIONS[i].architecture, TREE_ADD_AS_CHILD, _pic_fldclos, _pic_fldopen, 0, TREENODE_BOLD);
         ctlAdvancedTree._TreeSetListFromArray(GCC_MACHINE_OPTIONS[i].options, machineNode, false, null);
      }
   }
}

/**
 * Build a tree from the specified array.  If provided, the array
 * index of each item will be stored in an index hash table for
 * quick index lookup by name.  The index will also be stored in
 * the user data of the node for quick tree-to-array conversion.
 *
 * @param options    Array of options to be entered into the tree
 * @param parentNode Parent node to add all options to
 * @param allowDuplicates
 *                   Allow duplicate entries in the tree
 * @param indexHash  Hash table relating array index to option name
 */
static void _TreeSetListFromArray(GCC_OPTION_INFO options[], int parentNode = TREE_ROOT_INDEX,
                                  bool allowDuplicates = false, int (&indexHash):[] = null)
{
   i := 0;
   for(i = 0; i < options._length(); i++) {
      // make sure the node isnt already in the tree if duplicates are not allowed
      if(!allowDuplicates && _TreeSearch(parentNode, options[i].option) >= 0) {
         continue;
      }

      // store the index in the user data of the node
      int node = _TreeAddItem(parentNode, options[i].option "\t" options[i].description, TREE_ADD_AS_CHILD, 0, 0, -1, 0, i);
      _TreeSetCheckState(node,TCB_UNCHECKED);

      // add the index to the hash if available
      indexHash:[options[i].option] = i;
   }
}

/**
 * Find the specified node by caption and set its checkbox to the
 * specified value
 *
 * @param caption    Caption of node to find
 * @param value      Value of checkbox bitmap to be set
 * @param parentNode Parent node to search within
 */
static void _TreeSetCheckboxValue(_str caption, int value, int parentNode = TREE_ROOT_INDEX)
{
   int node = _TreeSearch(parentNode, caption);
   if(node < 0) return;

   if(value == null) value = TCB_UNCHECKED;
   _TreeSetCheckState(node,value);
}

/**
 * Find which tree contains the specified option and set its value
 *
 * @param options
 * @param parameter
 * @param value
 *
 * @return <0 no match
 */
static int findAndSetOption(GNUC_OPTIONS& options, _str parameter, int value)
{
   // try to determine where this advanced option belongs (advanced tree or other opts)
   int arrayIndex = warningIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedWarnings:[parameter] = value;
      return 0;
   }

   arrayIndex = codeGenIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedCodeGen:[parameter] = value;
      return 0;
   }

   arrayIndex = debugIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedDebug:[parameter] = value;
      return 0;
   }

   arrayIndex = languageIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedLanguage:[parameter] = value;
      return 0;
   }

   arrayIndex = optimizationIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedOptimization:[parameter] = value;
      return 0;
   }

   arrayIndex = preProcessorIndexes:[parameter];
   if(arrayIndex != null) {
      // set the value
      options.advancedPreprocessor:[parameter] = value;
      return 0;
   }

   // search the machine options without returning after the first match since
   // options can occur multiple times (ex: -msoft-float) across different
   // architectures.  the approach used here will set them all since you can
   // never compile for more than one architecture at a time.
   int i, j;
   for(i = 0; i < GCC_MACHINE_OPTIONS._length(); i++) {
      for(j = 0; j < GCC_MACHINE_OPTIONS[i].options._length(); j++) {
         if(parameter == GCC_MACHINE_OPTIONS[i].options[j].option) {
            // set the value
            options.advancedMachine:[parameter] = value;
            return 0;

            // stop looking in this particular architecture but continue to the next type
            //break;
         }
      }
   }

   // failure
   return -1;
}

/**
 * Get the options for the specified toolname in each
 * configuration.  The intent is that this function will
 * be called for both the 'compile' and 'link' tools
 * separately but with the same set of options.  This will
 * lead to a combination of any options that should be common
 * between the two as well as populating any compiler-only or
 * linker-only option sections.
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 *
 * @return
 */
static bool getGNUOptions(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options)
{
   if(targetNode < 0) return false;

   // get target name.  if there is no name, it must be a compile rule
   targetName := _ProjectGet_TargetName(projectHandle, targetNode);
   if(targetName == "") {
      targetName = "compile";
   }
   configNode := _ProjectGet_ConfigNode(projectHandle, config);

   // get info about the targets commands
   _str cmd = _ProjectGet_TargetCmdLine(projectHandle, targetNode);
   _str otherOptions = _ProjectGet_TargetOtherOptions(projectHandle, targetNode);

   switch(lowcase(targetName)) {
      case "compile":

         // start the defines with anything stored in the project which may be quoted
         options.defines = '';
         _str full_defines = _ProjectGet_Defines(projectHandle,config);
         while (full_defines != '') {
            _str define = parse_next_option(full_defines, false);
            // remove a leading /D or -D for the dialog
            prefix := substr(define, 1, 2);
            if (prefix == '/D' || prefix == '-D') {
               define = substr(define, 3);
            }
            strappend(options.defines, " " :+ define);
         }
         options.defines = strip(options.defines);

         // parse the command
         parseGNUCommand(targetName, cmd, otherOptions, options);

         // also save the include dirs for this configuration
         options.userIncludeDirs = _ProjectGet_IncludesList(projectHandle, config);
         options.systemIncludeDirs = _ProjectGet_SysIncludesList(projectHandle, config);
         return true;

      case "link":
         switch (_ProjectGet_GNUCOption(projectHandle, configNode, 'LinkerOutputType')) {
         case 'Executable':
            options.outputType = OUTPUT_TYPE_EXECUTABLE;
            break;
         case 'StaticLibrary':
            options.outputType = OUTPUT_TYPE_STATIC;
            break;
         case 'SharedLibrary':
            options.outputType = OUTPUT_TYPE_SHARED();
            break;
         default:
            {
               // no option set - make best guess
               _str command = cmd;
               _str executable = parse_file(cmd);
               executable = _strip_filename(executable, "PE");
               if (lowcase(executable):=='ar') {
                  options.outputType = OUTPUT_TYPE_STATIC;
               } else {
                  options.outputType = OUTPUT_TYPE_EXECUTABLE;
               }
               cmd = command;
            }
            break;
         }
         parseGNUCommand(targetName, cmd, otherOptions, options);
         options.outputFilename = _ProjectGet_OutputFile(projectHandle, config);
         options.libs=_ProjectGet_DisplayLibsList(projectHandle, config);
         return true;

      case "debug":
         // parse command
         parseGNUCommand(targetName, cmd, otherOptions, options);
         return true;

      case "execute":
         return true;
   }

   return false;
}

/**
 * Get the options for the specified toolname across all
 * configurations.  The control will only show a value if
 * all configurations share that value.
 *
 * @param allGNUOptions
 *               Options for all GNU configurations
 *
 * @return The combined set of options
 */
static GNUC_OPTIONS getAllGNUOptions(GNUC_OPTIONS allGNUOptions:[])
{
   // TODO:  There is an easier way to do most of this now:
   /*
   allGNUOptions._deleteel(PROJ_ALL_CONFIGS);
   GNUC_OPTIONS allGNUInfo = _get_matching_struct_values(allGNUOptions);
   */

   GNUC_OPTIONS allGNUInfo = null;
   _str sectionsList[] = null;
   sectionsList = GetHashTabIndexes(allGNUOptions);
   RemoveItemFromList(sectionsList, PROJ_ALL_CONFIGS);

   // if there is only one configuration, return its options
   if(sectionsList._length() == 1) {
      return allGNUOptions:[sectionsList[0]];
   }

   // NOTE:  It is CRITICAL that the fields of this struct get
   //        populated in the same order as they appear in the
   //        GNUC_OPTIONS struct
   k := 0;

   // get all options that are common to all configurations
   allGNUInfo.compiler              = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.verbose               = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.usePipes              = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.saveTemps             = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.ansi                  = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.traditional           = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.compileAs             = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.defines               = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.compilerOther         = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.inputFilename         = getMatchingValue(allGNUOptions, ++k, "");

   allGNUInfo.optimizationLevel     = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.debugInfo             = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.ggdbExtensions        = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.profilerInfo          = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.gprofInfo             = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.debugLevel            = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.gasInfo               = getMatchingValue(allGNUOptions, ++k, 2);

   allGNUInfo.linker                = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.noDefaultLibs         = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.noStdLibs             = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.linkStatic            = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.linkSymbolic          = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.outputType            = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.outputFilename        = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.libs                  = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.linkerOther           = getMatchingValue(allGNUOptions, ++k, "");

   allGNUInfo.userIncludeDirs       = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.systemIncludeDirs     = getMatchingValue(allGNUOptions, ++k, "");

   allGNUInfo.showAllWarnings       = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.pedantic              = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.warningsAsErrors      = getMatchingValue(allGNUOptions, ++k, 2);
   allGNUInfo.inhibitWarnings       = getMatchingValue(allGNUOptions, ++k, 2);

   // empty the tree of all values (defaulting all entries to false)
   allGNUInfo.advancedWarnings._makeempty();
   allGNUInfo.advancedCodeGen._makeempty();
   allGNUInfo.advancedDebug._makeempty();
   allGNUInfo.advancedLanguage._makeempty();
   allGNUInfo.advancedOptimization._makeempty();
   allGNUInfo.advancedPreprocessor._makeempty();
   allGNUInfo.advancedMachine._makeempty();

   getMatchingTreeValues(allGNUOptions, ++k, GCC_WARNING_OPTIONS, allGNUInfo.advancedWarnings, 2);
   getMatchingTreeValues(allGNUOptions, ++k, GCC_CODEGENERATION_OPTIONS, allGNUInfo.advancedCodeGen, 2);
   getMatchingTreeValues(allGNUOptions, ++k, GCC_DEBUG_OPTIONS, allGNUInfo.advancedDebug, 2);
   getMatchingTreeValues(allGNUOptions, ++k, GCC_LANGUAGE_OPTIONS, allGNUInfo.advancedLanguage, 2);
   getMatchingTreeValues(allGNUOptions, ++k, GCC_OPTIMIZATION_OPTIONS, allGNUInfo.advancedOptimization, 2);
   getMatchingTreeValues(allGNUOptions, ++k, GCC_PREPROCESSOR_OPTIONS, allGNUInfo.advancedPreprocessor, 2);

   ++k;
   int i;
   for(i = 0; i < GCC_MACHINE_OPTIONS._length(); i++) {
      getMatchingTreeValues(allGNUOptions, k, GCC_MACHINE_OPTIONS[i].options, allGNUInfo.advancedMachine, 2);
   }

   // debugger options
   allGNUInfo.debuggerName    = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.debuggerOptions = getMatchingValue(allGNUOptions, ++k, "");
   allGNUInfo.programArguments= getMatchingValue(allGNUOptions, ++k, "");

   return allGNUInfo;
}

/**
 * Check to see if the current configuration is one that uses
 * the GNU tools.  This is determined by checking the tool's copts
 * for the 'dialog:_gnu_options_form' option.
 *
 * @param projectHandle
 * @param targetNode
 * @param options
 *
 * @return T if it uses GNU, F otherwise
 */
static bool usesGNUDialog(int projectHandle, int targetNode, GNUC_OPTIONS& options)
{
   if(targetNode < 0) return false;

   // check for '_gnuc_options_form' as the dialog
   _str dialog = _ProjectGet_TargetDialog(projectHandle, targetNode);
   return (pos("_gnuc_options_form", dialog) > 0);
}

/**
 * Check to see if an option is selected in the specified
 * options tree
 *
 * @param optionHash
 * @param optionList
 * @param index
 *
 * @return T if the option is checked, F otherwise
 */
static bool isEnabled(int optionHash:[], GCC_OPTION_INFO optionList[], int index)
{
   return (optionHash:[optionList[index].option] == 1);
}

/**
 * Parse the next command line option from the command.  This
 * function was needed to handle special command lines that use
 * commas as delimiters.
 *
 * @param command The command from which to parse the next option
 * @param returnQuotes
 *                T to return the quotes around an option that contains spaces.
 *                F to strip the quotes.
 * @param allowCommaDelimiter
 *                T to allow comma as a delimiter
 *
 * @return The next option on the command line
 */
_str parse_next_option(_str& command, bool returnQuotes = true,
                       bool allowCommaDelimiter = false)
{
   offset := 1;
   delimiterLength := 0;

   while(offset <= length(command)) {
      ch := substr(command, offset, 1);

      if(ch == "\"") {
         endQuote := pos(ch, command, offset + 1);
         if(!endQuote) {
            endQuote = length(command);
         }

         offset = endQuote;

      } else if(ch == " " || (allowCommaDelimiter && ch == ",")) {
         while((ch == " " || (allowCommaDelimiter && ch == ","))&&(offset <= length(command))) {
            // keep up with how many delimiters are skipped so they will not
            // be included in the option when it is stripped off
            delimiterLength++;
            offset++;
            ch = substr(command, offset, 1);
         }
         break;
      }

      // next char
      offset++;
   }

   option := substr(command, 1, offset - 1 - delimiterLength);
   command = substr(command, offset);

   // calling strip(option,"B","\"") could remove a
   // trailing escaped quote so this more complicated
   // check is done
   if ((!returnQuotes)&&
       (length(option)>2)&&
       (substr(option,1,1)=="\"")&&
       (substr(option,length(option),1)=="\"")) {
      option=substr(option,2,length(option)-2);
   }

   return option;
}

/**
 * Store the changes made via the form in the structs that the
 * project form uses to store its data (so the changes will be
 * saved to the project file when the project form exits)
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 */
static void setGNUCommand(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options)
{
   if(targetNode < 0) return;
   configNode := _ProjectGet_ConfigNode(projectHandle, config);

   // get target name.  if there is no name, it must be a compile rule
   targetName := _ProjectGet_TargetName(projectHandle, targetNode);
   if(targetName == "") {
      targetName = "compile";
   }

   // if this command does not use the gnucopts dialog, do not modify its settings
   if(!usesGNUDialog(projectHandle, targetNode, options)) {
      return;
   }

   // User-defined target commandline preprocessor. This will typically
   // be defined by an OEM that needs to remove switches from a target
   // commandline (e.g. -Wall, -O* from link).
   ppindex := find_index('_GNUPreprocessTargetCmdLine',PROC_TYPE);

   // determine which command this is and build it accordingly
   switch(lowcase(targetName)) {
      case "compile":
         setGCCCommand(projectHandle, config, targetNode, options, ppindex);
         break;

      case "link":
         outputType := "Executable";
         if(options.outputType == OUTPUT_TYPE_STATIC) {
            setARCommand(projectHandle, config, targetNode, options, ppindex);
            outputType = 'StaticLibrary';
         } else {
            setGCCCommand(projectHandle, config, targetNode, options, ppindex);
            if (options.outputType == OUTPUT_TYPE_SHARED()) {
               outputType = 'SharedLibrary';
            }
         }
         _ProjectSet_GNUCOption(projectHandle, configNode, 'LinkerOutputType', outputType);
         break;

      case "debug":
         setGDBCommand(projectHandle, config, targetNode, options, ppindex);
         break;

      case "execute":
         setExecuteCommand(projectHandle, config, targetNode, options, ppindex);
         break;
   }
}

/**
 * Store the changes made via the form in the structs that the
 * project form uses to store its data (so the changes will be
 * saved to the project file when the project form exits).
 * Assume that this is a compile command and format the command
 * as such unless the target name is "link"
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 */
static void setGCCCommand(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options, int preprocessCmdLineIndex=0)
{
      // get target name.  if there is no name, it must be a compile rule
   targetName := _ProjectGet_TargetName(projectHandle, targetNode);
   if(targetName == "") {
      targetName = "compile";
   }

   isLinkCommand := strieq(targetName, "link");

   // start with the appropriate base command for the target type (gcc, g++, etc)
   command := "";
   if(isLinkCommand) {
      command = _maybe_quote_filename(options.linker);
   } else {
      command = _maybe_quote_filename(options.compiler);
      command :+= " -c";
   }

   // enable unix fileseps
   command :+= " %xup";

   // basic options
   if(options.verbose) {
      command :+= " -v";
   }
   if(options.usePipes) {
      command :+= " -pipe";
   }
   if(options.saveTemps) {
      command :+= " -save-temps";
   }

   // compiler options
   if(!isLinkCommand) {
      if(options.ansi) {
         command :+= " -ansi";
      }
      if(options.traditional) {
         command :+= " -traditional";
      }
      if(options.compileAs != COMPILE_AS_DEFAULT && options.compileAs != "") {
         command :+= " -x " options.compileAs;
      }
   }

   // defines
   if(!isLinkCommand) {
      command :+= " %defd";

      // save current defines into the project
      _str raw_defines = options.defines;
      all_defines := "";

      while (raw_defines != '') {
         _str define = parse_next_option(raw_defines,false);
         _checkDefine(define);
         if (define != '') {
            if (all_defines != '') {
               strappend(all_defines, ' ');
            }
            strappend(all_defines, '"'define'"');
         }
      }

      _ProjectSet_Defines(projectHandle,all_defines,config);
   }

   // code generation options
   if(options.optimizationLevel != "") {
      switch(options.optimizationLevel) {
         case OPTIMIZATION_LEVEL_NONE:
            command :+= " -O0";
            break;

         case OPTIMIZATION_LEVEL_LOW:
            command :+= " -O1";
            break;

         case OPTIMIZATION_LEVEL_MED:
            command :+= " -O2";
            break;

         case OPTIMIZATION_LEVEL_HIGH:
            command :+= " -O3";
            break;
      }
   }
   if(options.debugInfo) {
      // only put debug options if debug is enabled
      if(options.debugLevel != "") {
         switch(options.debugLevel) {
            case DEBUG_LEVEL_MINIMAL:
               command :+= " -g1";
               break;

            case DEBUG_LEVEL_MAXIMAL:
               command :+= " -g3";
               break;

            case DEBUG_LEVEL_DEFAULT:
            default:
               command :+= " -g";
               break;
         }
      } else {
         command :+= " -g";
      }
   }

   if(options.ggdbExtensions) {
      command :+= " -ggdb";
   }

   if(options.profilerInfo) {
      command :+= " -p";
   }
   if(options.gprofInfo) {
      command :+= " -pg";
   }
   if(options.gasInfo) {
      command :+= " -mgas";
   }

   // link options
   if(isLinkCommand) {
      if(options.noDefaultLibs) {
         command :+= " -nodefaultlibs";
      }
      if(options.noStdLibs) {
         command :+= " -nostdlibs";
      }
      if(options.linkStatic) {
         command :+= " -static";
      }
      if(options.linkSymbolic) {
         command :+= " -symbolic";
      }
      if(options.outputType == OUTPUT_TYPE_SHARED()) {
         command :+= " -shared -fPIC";
      }
   }

   // warnings
   if(options.showAllWarnings) {
      command :+= " -Wall";
   }
   if(options.pedantic) {
      command :+= " -pedantic";
   }
   if(options.warningsAsErrors) {
      command :+= " -Werror";
   }
   if(options.inhibitWarnings) {
      command :+= " -w";
   }

   if(!isLinkCommand) {
      // advanced warnings tree
      int i, j;
      for(i = 0; i < GCC_WARNING_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedWarnings, GCC_WARNING_OPTIONS, i)) {
            command :+= " " GCC_WARNING_OPTIONS[i].option;
         }
      }

      // advanced codegen tree
      for(i = 0; i < GCC_CODEGENERATION_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedCodeGen, GCC_CODEGENERATION_OPTIONS, i)) {
            command :+= " " GCC_CODEGENERATION_OPTIONS[i].option;
         }
      }

      // advanced debug tree
      for(i = 0; i < GCC_DEBUG_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedDebug, GCC_DEBUG_OPTIONS, i)) {
            command :+= " " GCC_DEBUG_OPTIONS[i].option;
         }
      }

      // advanced language tree
      for(i = 0; i < GCC_LANGUAGE_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedLanguage, GCC_LANGUAGE_OPTIONS, i)) {
            command :+= " " GCC_LANGUAGE_OPTIONS[i].option;
         }
      }

      // advanced optimization tree
      for(i = 0; i < GCC_OPTIMIZATION_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedOptimization, GCC_OPTIMIZATION_OPTIONS, i)) {
            command :+= " " GCC_OPTIMIZATION_OPTIONS[i].option;
         }
      }

      // advanced preprocessor tree
      for(i = 0; i < GCC_PREPROCESSOR_OPTIONS._length(); i++) {
         if(isEnabled(options.advancedPreprocessor, GCC_PREPROCESSOR_OPTIONS, i)) {
            command :+= " " GCC_PREPROCESSOR_OPTIONS[i].option;
         }
      }

      // advanced machine tree (maintain hash to prevent duplicates)
      bool machineOptions:[];
      for(i = 0; i < GCC_MACHINE_OPTIONS._length(); i++) {
         for(j = 0; j < GCC_MACHINE_OPTIONS[i].options._length(); j++) {
            if(isEnabled(options.advancedMachine, GCC_MACHINE_OPTIONS[i].options, j)) {
               // make sure this isnt a duplicate option across two machine trees
               if(machineOptions:[GCC_MACHINE_OPTIONS[i].options[j].option] != true) {
                  command :+= " " GCC_MACHINE_OPTIONS[i].options[j].option;
                  machineOptions:[GCC_MACHINE_OPTIONS[i].options[j].option] = true;
               }
            }
         }
      }
   }

   // other options placeholder
   otherOptions := "";
   if(isLinkCommand) {
      otherOptions = options.linkerOther;
   } else {
      otherOptions = options.compilerOther;
   }
   if(otherOptions != "") {
      command :+= " %~other";
   }

   // add the options to be parsed later
   if(isLinkCommand) {
      command :+= " -o \"%o\"";
//      command = command " %f"; // do not quote filename on linker since multiple objects will be placed there
//      command = command " %libs";
      command :+= " %objs";
   } else {
      command :+= " -o \"%bd%n%oe\"";
      command :+= " %i";
      if (options.inputFilename != '') {
         command :+= " " options.inputFilename;
      } else {
         command :+= " \"%f\"";
      }
   }

   // parse the list of libs looking for libLIBRARY.a and replace with -lLIBRARY
   if(options.libs != "") {
      _str origLibsList = options.libs;
      newLibsList := "";
      for(;;) {
         lib := "";
         parse origLibsList with lib " " origLibsList;
         if( lib=="" ) {
            if( origLibsList=="" ) {
               break;
            }
            continue;
         }

         // see if the library is in the form libLIBRARY.a
         lib = strip(lib);
         //ignore anything involing sub-directories
         if (!pos('[\\/]', lib, 1, 'R')) {
            if(pos("^([Ll][Ii][Bb])(.+)([.]a)$", lib, 1, "U") > 0) {
               newLibsList :+= " -l" substr(lib, pos("S2"), pos("2"));
            } else {
               newLibsList :+= " " lib;
            }
         } else {
            newLibsList :+= " " lib;
         }
      }

      // replace the old list with the updated list
      options.libs = strip(newLibsList);
   }

   if( preprocessCmdLineIndex!=0 ) {
      // User-defined target commandline preprocessor. This will typically
      // be defined by an OEM that needs to remove switches from a target
      // commandline (e.g. -Wall, -O* from link).
      call_index(projectHandle,command,config,targetName,preprocessCmdLineIndex);
   }

   // set the information in the project settings
   //say("CFG: " curConfig " CMD(" toolIndex "): " command);
   //say("CFG: " curConfig " OTH(" toolIndex "): " otherOptions);
   _ProjectSet_TargetCmdLine(projectHandle, targetNode, command, "", otherOptions);
   _ProjectSet_IncludesList(projectHandle, options.userIncludeDirs, config);
   //_ProjectSet_SysIncludesList(projectHandle, options.systemIncludeDirs);

   // only set output file and libs if this is the link target
   if(isLinkCommand) {
      _ProjectSet_OutputFile(projectHandle, options.outputFilename, config);

      _ProjectSet_DisplayLibsList(projectHandle, config, options.libs);
      
   }
}

/**
 * Store the changes made via the form in the structs that the
 * project form uses to store its data (so the changes will be
 * saved to the project file when the project form exits)
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 */
static void setARCommand(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options, int preprocessCmdLineIndex=0)
{
   _str command;

   // get target name.  if there is no name, it must be a compile rule
   targetName := _ProjectGet_TargetName(projectHandle, targetNode);
   if(targetName == "") {
      targetName = "compile";
   }

   isLinkCommand := strieq(targetName, "link");

   // start with the appropriate base command for the target type (ar, etc)
   if(isLinkCommand) {
      command = _maybe_quote_filename(options.linker);
      command :+= " -rs";
   } else {
      command = _maybe_quote_filename(options.compiler);
   }

   // add the options to be parsed later
   if(isLinkCommand) {
      command :+= " %xup";
      command :+= " \"%o\"";
      command :+= " %f"; // do not quote filename on linker since multiple objects will be placed there
   }

   // other options placeholder not appropriate for 'ar' command so skipping this step

   if( preprocessCmdLineIndex!=0 ) {
      // User-defined target commandline preprocessor. This will typically
      // be defined by an OEM that needs to remove switches from a target
      // commandline (e.g. -Wall, -O* from link).
      call_index(projectHandle,command,config,targetName,preprocessCmdLineIndex);
   }

   // set the information in the project settings
   //say("CFG: " curConfig " CMD(" toolIndex "): " command);
   _ProjectSet_TargetCmdLine(projectHandle, targetNode, command, "", "");
   _ProjectSet_OutputFile(projectHandle, options.outputFilename, config);
   _ProjectSet_IncludesList(projectHandle, options.userIncludeDirs, config);
   //_ProjectSet_SysIncludesList(projectHandle, options.systemIncludeDirs, config);
}

/**
 * Store the changes made via the form in the structs that the
 * project form uses to store its data (so the changes will be
 * saved to the project file when the project form exits)
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 */
static void setGDBCommand(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options, int preprocessCmdLineIndex=0)
{
   // basic debugger command
   command := _maybe_quote_filename(options.debuggerName);
   _str otherOptions = options.programArguments;
   if(strieq(command, "vsdebugio")) {
      command :+= " -prog \"%o\"";

      // other options placeholder
      if(otherOptions != "") {
         command :+= " %~other";
      }
   } else {
      if(options.debuggerOptions != "") {
         command :+= " " options.debuggerOptions;
      }

      if (otherOptions != "") {
         command :+= " --args \"%o\" %~other";
      } else {
         command :+= " \"%o\"";
      }
   }

   if( preprocessCmdLineIndex!=0 ) {
      // User-defined target commandline preprocessor. This will typically
      // be defined by an OEM that needs to remove switches from a target
      // commandline (e.g. -Wall, -O* from link).
      call_index(projectHandle,command,config,"debug",preprocessCmdLineIndex);
   }

   // set the information in the project settings
   _ProjectSet_TargetCmdLine(projectHandle, targetNode, command, "", otherOptions);
}

/**
 * Store the changes made via the form in the structs that the
 * project form uses to store its data (so the changes will be
 * saved to the project file when the project form exits)
 *
 * @param projectHandle
 * @param config
 * @param targetNode
 * @param options
 */
static void setExecuteCommand(int projectHandle, _str config, int targetNode, GNUC_OPTIONS& options, int preprocessCmdLineIndex=0)
{
   // basic execute command
   command :=  "\"%o\"";

   // other options placeholder
   _str otherOptions = options.programArguments;
   if(otherOptions != "") {
      command :+= " %~other";
   }

   if( preprocessCmdLineIndex!=0 ) {
      // User-defined target commandline preprocessor. This will typically
      // be defined by an OEM that needs to remove switches from a target
      // commandline (e.g. -Wall, -O* from link).
      call_index(projectHandle,command,config,"execute",preprocessCmdLineIndex);
   }

   // set the information in the project settings
   _ProjectSet_TargetCmdLine(projectHandle, targetNode, command, "", otherOptions);
}

static void _ProjectSet_GNUCOption(int projectHandle, int configNode, _str option, _str value)
{
   if (projectHandle < 0 || configNode < 0) {
      return;
   }
   optionsNode := _xmlcfg_find_simple(projectHandle, "List[@Name='GNUC Options']", configNode);
   if (optionsNode < 0) {
      optionsNode = _xmlcfg_add(projectHandle, configNode, VPJTAG_LIST, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle, optionsNode, "Name", "GNUC Options", 0);
   }

   node := _xmlcfg_find_simple(projectHandle, "Item[@Name='"option"']", optionsNode);
   if (node < 0) {
      node = _xmlcfg_add(projectHandle, optionsNode, VPJTAG_ITEM, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(projectHandle, node, "Name", option, 0);
   }
   _xmlcfg_set_attribute(projectHandle, node, "Value", value, 0);
}

static _str _ProjectGet_GNUCOption(int projectHandle, int configNode, _str option)
{
   if (projectHandle < 0 || configNode < 0) {
      return '';
   }
   optionsNode := _xmlcfg_find_simple(projectHandle, "List[@Name='GNUC Options']", configNode);
   if (optionsNode > 0) {
      node := _xmlcfg_find_simple(projectHandle, "Item[@Name='"option"']", optionsNode);
      if (node > 0) {
         return _xmlcfg_get_attribute(projectHandle, node, "Value");
      }
   }
   return '';
}

/**
 * Set all possible GNU command options to their default values
 *
 * @param options Options struct to be defaulted
 */
static void setGNUOptionDefaults(GNUC_OPTIONS& options)
{
   // set the options to their defaults
   options.compileInputExt = "";
   options.compiler = "";
   options.verbose = false;
   options.usePipes = false;
   options.saveTemps = false;
   options.ansi = false;
   options.traditional = false;
   options.compileAs = "";
   options.defines = "";
   options.compilerOther = "";
   options.inputFilename = "";

   options.optimizationLevel = "";
   options.debugInfo = false;
   options.ggdbExtensions = false;
   options.profilerInfo = false;
   options.gprofInfo = false;
   options.debugLevel = "";
   options.gasInfo = false;

   options.linker = "";
   options.noDefaultLibs = false;
   options.noStdLibs = false;
   options.linkStatic = false;
   options.linkSymbolic = false;
   options.outputType = OUTPUT_TYPE_EXECUTABLE;
   options.outputFilename = "";
   options.libs = "";
   options.linkerOther = "";

   options.userIncludeDirs = "";
   options.systemIncludeDirs = "";

   options.showAllWarnings = false;
   options.pedantic = false;
   options.warningsAsErrors = false;
   options.inhibitWarnings = false;
   options.advancedWarnings = null;

   options.advancedCodeGen = null;
   options.advancedDebug = null;
   options.advancedLanguage = null;
   options.advancedOptimization = null;
   options.advancedPreprocessor = null;
   options.advancedMachine = null;

   options.debuggerName = "vsdebugio";
   options.debuggerOptions = "";
   options.programArguments = "";

   options.compileTargetNode = -1;
   options.linkTargetNode = -1;
   options.debugTargetNode = -1;
   options.executeTargetNode = -1;
}

/**
 * Parse the specified command, storing all options for use in the dialog
 *
 * @param targetName
 * @param command
 * @param otherOptions
 * @param options
 */
static void parseGNUCommand(_str targetName, _str command, _str otherOptions, GNUC_OPTIONS& options)
{
   // determine which command this is and parse it accordingly
   _str cmd = command;
   _str executable = parse_file(cmd, false);
   //say("parsing: " command" tool="tool" executable="executable);

   // set the options to their defaults
   switch(lowcase(targetName)) {
      case "compile":
         options.compiler = executable;
         options.compilerOther = otherOptions;
         parseGCCCommand(cmd, otherOptions, options);
         return;

      case "link":
         options.linker = executable;
         options.linkerOther = otherOptions;
         if (options.outputType == OUTPUT_TYPE_STATIC) {
            parseARCommand(cmd, otherOptions, options);
         } else {
            parseGCCCommand(cmd, otherOptions, options);
         }
         return;

      case "debug":
         options.debuggerName = executable;
         if(!strieq(executable, "vsdebugio")) {
            cmdarg := parse_file(cmd);
            debugopts := "";
            while (cmdarg != "") {
               if (cmdarg == "\"%o\"" || cmdarg == '--args') {
                  break;
               }
               if (debugopts != '') {
                  debugopts :+= " "cmdarg;
               } else {
                  debugopts = cmdarg;
               }
               cmdarg = parse_file(cmd);
            }
            options.debuggerOptions = debugopts;
         }

         // program arguments stored in other opts
         options.programArguments = otherOptions;
         return;

      case "execute":
         return;
   }
}

/**
 * Parse gcc/g++ command, storing all options for use in the dialog
 *
 * @param command
 * @param otherOptions
 * @param options
 */
static void parseGCCCommand(_str command, _str otherOptions, GNUC_OPTIONS& options)
{
   //say("command: " command);
   //say("other: " otherOptions);
   _str cmd = command;

   _str parameter = parse_next_option(cmd);
   i := 0;
   while(parameter != "") {
      //say("cmd[" i++ "]: " parameter);
      switch(parameter) {
         case "-c":
            // this parameter is auto generated and should be ignored
            break;

         case "-o":
            // this parameter is auto generated and has 1 parameter following
            // it that should also be ignored
            parameter = parse_next_option(cmd);
            break;

         case "-v":
            options.verbose = true;
            break;

         case "-pipe":
            options.usePipes = true;
            break;

         case "-save-temps":
            options.saveTemps = true;
            break;

         case "-ansi":
            options.ansi = true;
            break;

         case "-traditional":
            options.traditional = true;
            break;

         case "-x":
            // language identifier should follow -x
            options.compileAs = parse_next_option(cmd);
            break;

         case "-O0":
            options.optimizationLevel = OPTIMIZATION_LEVEL_NONE;
            break;

         case "-O":
         case "-O1":
            options.optimizationLevel = OPTIMIZATION_LEVEL_LOW;
            break;

         case "-O2":
            options.optimizationLevel = OPTIMIZATION_LEVEL_MED;
            break;

         case "-O3":
            options.optimizationLevel = OPTIMIZATION_LEVEL_HIGH;
            break;

         case "-g":
         case "-g2":
            options.debugInfo = true;
            options.debugLevel = DEBUG_LEVEL_DEFAULT;
            break;

         case "-g1":
            options.debugInfo = true;
            options.debugLevel = DEBUG_LEVEL_MINIMAL;
            break;

         case "-g3":
            options.debugInfo = true;
            options.debugLevel = DEBUG_LEVEL_MAXIMAL;
            break;

         case "-ggdb":
            options.ggdbExtensions = true;
            break;

         case "-p":
            options.profilerInfo = true;
            break;

         case "-pg":
            options.gprofInfo = true;
            break;

         case "-mgas":
            options.gasInfo = true;
            break;
   
         case "-nodefaultlibs":
            options.noDefaultLibs = true;
            break;

         case "-nostdlibs":
            options.noStdLibs = true;
            break;

         case "-static":
            options.linkStatic = true;
            break;

         case "-shared":
            options.outputType = OUTPUT_TYPE_SHARED();
            break;

         case "-symbolic":
            options.linkSymbolic = true;
            break;

         case "-Wall":
            options.showAllWarnings = true;
            break;

         case "-pedantic":
            options.pedantic = true;
            break;

         case "-Werror":
            options.warningsAsErrors = true;
            break;

         case "-w":
            options.inhibitWarnings = true;
            break;

         case "-I-":
         case "":
            break;

         default:
            // check for other supported parameters
            prefix := substr(parameter, 1, 2);
            // when upgrading to version 9.0 there may be some defines
            // in the command line.  This will find them and when they
            // hit OK in dialog, they will be saved with the other defines
            // and the command line will be set to %defd
            if(prefix == "-D") {
               // extract the define following the -D
               defineValue := substr(parameter, 3);
               if(defineValue != "") {
                  if(options.defines == "") {
                     options.defines = defineValue;
                  } else {
                     options.defines = options.defines " " defineValue;
                  }
               }
            } else if(prefix == "-I") {
               // ignore any includes that are stored as part of the command

            } else if(prefix == "\"%" || substr(parameter, 1, 1) == "%") {
               // ignore any % options that are added automatically (which begin with
               // either % or a quoted "%
               if (parameter :== "%f" || parameter :== "%p%n%e" ||
                   parameter :== '"%f"' || parameter :== '"%p%n%e"') {
                  options.inputFilename = parameter;
               }

            } else {
               // try to determine where this advanced option belongs (advanced tree or other opts)
               if(findAndSetOption(options, parameter, 1)) {
                  if(options.compilerOther == "") {
                     options.compilerOther = parameter;
                  } else {
                     options.compilerOther = options.compilerOther " " parameter;

                  }
               }
            }
      }

      // get the next parameter
      parameter = parse_next_option(cmd); //parse_file(cmd);
   }
}

/**
 * Parse ar command, storing all options for use in the dialog
 *
 * @param command
 * @param otherOptions
 * @param options
 */
static void parseARCommand(_str command, _str otherOptions, GNUC_OPTIONS& options)
{
   // no op
}

static void setGNUControls(GNUC_OPTIONS& options)
{
   // compile tab
   ctlCompiler.p_text = options.compiler;
   ctlVerbose.p_value = (int)options.verbose;
   ctlUsePipes.p_value = (int)options.usePipes;
   ctlSaveTemps.p_value = (int)options.saveTemps;
   ctlAnsi.p_value = (int)options.ansi;
   ctlTraditional.p_value = (int)options.traditional;
   ctlCompileAs.p_text = (options.compileAs!='')? options.compileAs : COMPILE_AS_DEFAULT;
   ctlPreprocessorDefines.p_text = options.defines;
   ctlOtherCompileOptions.p_text = options.compilerOther;

   // code generation tab
   ctlOptimizationLevel.p_text = (options.optimizationLevel != '')? options.optimizationLevel : OPTIMIZATION_LEVEL_NA;
   ctlEnableDebugging.p_value = (int)options.debugInfo;
   ctlGDBInformation.p_value = (int)options.ggdbExtensions;
   ctlEnableProfiling.p_value = (int)options.profilerInfo;
   ctlEnableGProf.p_value = (int)options.gprofInfo;
   ctlUseGAS.p_value = (int)options.gasInfo;
   if(ctlEnableDebugging.p_value == 0) {
      ctlDebugLevel.p_enabled = false;
   } else {
      ctlDebugLevel.p_enabled = true;
      ctlDebugLevel.p_text = (options.debugLevel != '')? options.debugLevel : DEBUG_LEVEL_NA;
   }

   // link tab
   switch(options.outputType) {
      case OUTPUT_TYPE_STATIC:
         enableLinkOptions(false);
         break;

      default:
         enableLinkOptions(true);
         ctlNoDefaultLibs.p_value = (int)options.noDefaultLibs;
         ctlNoStdLibs.p_value = (int)options.noStdLibs;
         ctlStatic.p_value = (int)options.linkStatic;
         ctlSymbolic.p_value = (int)options.linkSymbolic;
         ctlOtherLinkOptions.p_text = options.linkerOther;
   }
   ctlOutputType.p_text = options.outputType;
   ctlLinker.p_text = options.linker;
   ctlOutputFile.p_text = options.outputFilename;
   ctlLibraries.p_text = options.libs;

   // directories tab
   ctlUserIncludesList._TreeSetDelimitedItemList(options.userIncludeDirs, PATHSEP, false);

   // warnings tab
   ctlAllWarnings.p_value = (int)options.showAllWarnings;
   ctlWpedantic.p_value = (int)options.pedantic;
   ctlAllWarningsAsErrors.p_value = (int)options.warningsAsErrors;
   ctlInhibitAllWarnings.p_value = (int)options.inhibitWarnings;

   // warnings tab - advanced warnings tree
   int i, j;
   for(i = 0; i < GCC_WARNING_OPTIONS._length(); i++) {
      _str caption = GCC_WARNING_OPTIONS[i].option;
      fullCaption :=  GCC_WARNING_OPTIONS[i].option "\t" GCC_WARNING_OPTIONS[i].description;
      ctlWarningsTree._TreeSetCheckboxValue(fullCaption, options.advancedWarnings:[caption]);
   }

   // advanced tab - code generation options tree
   for(i = 0; i < GCC_CODEGENERATION_OPTIONS._length(); i++) {
      _str caption = GCC_CODEGENERATION_OPTIONS[i].option;
      fullCaption :=  GCC_CODEGENERATION_OPTIONS[i].option "\t" GCC_CODEGENERATION_OPTIONS[i].description;
      ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedCodeGen:[caption], ADV_CODEGEN_ROOT_NODE());
   }

   // advanced tab - debug options tree
   for(i = 0; i < GCC_DEBUG_OPTIONS._length(); i++) {
      _str caption = GCC_DEBUG_OPTIONS[i].option;
      fullCaption :=  GCC_DEBUG_OPTIONS[i].option "\t" GCC_DEBUG_OPTIONS[i].description;
      ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedDebug:[caption], ADV_DEBUG_ROOT_NODE());
   }
   // advanced tab - language options tree
   for(i = 0; i < GCC_LANGUAGE_OPTIONS._length(); i++) {
      _str caption = GCC_LANGUAGE_OPTIONS[i].option;
      fullCaption :=  GCC_LANGUAGE_OPTIONS[i].option "\t" GCC_LANGUAGE_OPTIONS[i].description;
      ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedLanguage:[caption], ADV_LANGUAGE_ROOT_NODE());
   }
   // advanced tab - optimization options tree
   for(i = 0; i < GCC_OPTIMIZATION_OPTIONS._length(); i++) {
      _str caption = GCC_OPTIMIZATION_OPTIONS[i].option;
      fullCaption :=  GCC_OPTIMIZATION_OPTIONS[i].option "\t" GCC_OPTIMIZATION_OPTIONS[i].description;
      ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedOptimization:[caption], ADV_OPT_ROOT_NODE());
   }
   // advanced tab - preprocessor options tree
   for(i = 0; i < GCC_PREPROCESSOR_OPTIONS._length(); i++) {
      _str caption = GCC_PREPROCESSOR_OPTIONS[i].option;
      fullCaption :=  GCC_PREPROCESSOR_OPTIONS[i].option "\t" GCC_PREPROCESSOR_OPTIONS[i].description;
      ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedPreprocessor:[caption], ADV_PREPROC_ROOT_NODE());
   }

   // advanced tab - machine options tree
   for(i = 0; i < GCC_MACHINE_OPTIONS._length(); i++) {
      // find the child node of ADV_MACHINE_ROOT_NODE that is this machine
      int machineNode = ctlAdvancedTree._TreeSearch(ADV_MACHINE_ROOT_NODE(), GCC_MACHINE_OPTIONS[i].architecture);
      if(machineNode < 0) continue;

      for(j = 0; j < GCC_MACHINE_OPTIONS[i].options._length(); j++) {
         _str caption = GCC_MACHINE_OPTIONS[i].options[j].option;
         fullCaption :=  GCC_MACHINE_OPTIONS[i].options[j].option "\t" GCC_MACHINE_OPTIONS[i].options[j].description;
         ctlAdvancedTree._TreeSetCheckboxValue(fullCaption, options.advancedMachine:[caption], machineNode);
      }
   }

   // refresh the trees to avoid paint problems
   ctlUserIncludesList._TreeRefresh();
   ctlWarningsTree._TreeRefresh();
   ctlAdvancedTree._TreeRefresh();

}

static void saveGNUCheckBoxOptions(_str configName, GNUC_OPTIONS (&allGNUOptions):[])
{
   if(configName == "") return;

   if(configName == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         // compile tab
         if(ctlVerbose.p_enabled && ctlVerbose.p_value != 2) {
            allGNUOptions:[i].verbose = ctlVerbose.p_value != 0;
         }
         if(ctlUsePipes.p_enabled && ctlUsePipes.p_value != 2) {
            allGNUOptions:[i].usePipes = ctlUsePipes.p_value != 0;
         }
         if(ctlSaveTemps.p_enabled && ctlSaveTemps.p_value != 2) {
            allGNUOptions:[i].saveTemps = ctlSaveTemps.p_value != 0;
         }
         if(ctlAnsi.p_enabled && ctlAnsi.p_value != 2) {
            allGNUOptions:[i].ansi = ctlAnsi.p_value != 0;
         }
         if(ctlTraditional.p_enabled && ctlTraditional.p_value != 2) {
            allGNUOptions:[i].traditional = ctlTraditional.p_value != 0;
         }

         // code generation tab
         if(ctlEnableDebugging.p_enabled && ctlEnableDebugging.p_value != 2) {
            allGNUOptions:[i].debugInfo = ctlEnableDebugging.p_value != 0;
         }
         if(ctlGDBInformation.p_enabled && ctlGDBInformation.p_value != 2) {
            allGNUOptions:[i].ggdbExtensions = ctlGDBInformation.p_value != 0;
         }
         if(ctlEnableProfiling.p_enabled && ctlEnableProfiling.p_value != 2) {
            allGNUOptions:[i].profilerInfo = ctlEnableProfiling.p_value != 0;
         }
         if(ctlEnableGProf.p_enabled && ctlEnableGProf.p_value != 2) {
            allGNUOptions:[i].gprofInfo = ctlEnableGProf.p_value != 0;
         }
         if(ctlUseGAS.p_enabled && ctlUseGAS.p_value != 2) {
            allGNUOptions:[i].gasInfo = ctlUseGAS.p_value != 0;
         }

         // link tab
         if(ctlNoDefaultLibs.p_enabled && ctlNoDefaultLibs.p_value != 2) {
            allGNUOptions:[i].noDefaultLibs = ctlNoDefaultLibs.p_value != 0;
         }
         if(ctlNoStdLibs.p_enabled && ctlNoStdLibs.p_value != 2) {
            allGNUOptions:[i].noStdLibs = ctlNoStdLibs.p_value != 0;
         }
         if(ctlStatic.p_enabled && ctlStatic.p_value != 2) {
            allGNUOptions:[i].linkStatic = ctlStatic.p_value != 0;
         }
         if(ctlSymbolic.p_enabled && ctlSymbolic.p_value != 2) {
            allGNUOptions:[i].linkSymbolic = ctlSymbolic.p_value != 0;
         }

         // directories tab
         // TODO

         // warnings tab
         if(ctlAllWarnings.p_enabled && ctlAllWarnings.p_value != 2) {
            allGNUOptions:[i].showAllWarnings = ctlAllWarnings.p_value != 0;
         }
         if(ctlWpedantic.p_enabled && ctlWpedantic.p_value != 2) {
            allGNUOptions:[i].pedantic = ctlWpedantic.p_value != 0;
         }
         if(ctlAllWarningsAsErrors.p_enabled && ctlAllWarningsAsErrors.p_value != 2) {
            allGNUOptions:[i].warningsAsErrors = ctlAllWarningsAsErrors.p_value != 0;
         }
         if(ctlInhibitAllWarnings.p_enabled && ctlInhibitAllWarnings.p_value != 2) {
            allGNUOptions:[i].inhibitWarnings = ctlInhibitAllWarnings.p_value != 0;
         }
      }
   } else {
      // compile tab
      if(ctlVerbose.p_enabled) {
         allGNUOptions:[configName].verbose = ctlVerbose.p_value != 0;
      }
      if(ctlUsePipes.p_enabled) {
         allGNUOptions:[configName].usePipes = ctlUsePipes.p_value != 0;
      }
      if(ctlSaveTemps.p_enabled) {
         allGNUOptions:[configName].saveTemps = ctlSaveTemps.p_value != 0;
      }
      if(ctlAnsi.p_enabled) {
         allGNUOptions:[configName].ansi = ctlAnsi.p_value != 0;
      }
      if(ctlTraditional.p_enabled) {
         allGNUOptions:[configName].traditional = ctlTraditional.p_value != 0;
      }

      // code generation tab
      if(ctlEnableDebugging.p_enabled) {
         allGNUOptions:[configName].debugInfo = ctlEnableDebugging.p_value != 0;
      }
      if(ctlGDBInformation.p_enabled) {
         allGNUOptions:[configName].ggdbExtensions = ctlGDBInformation.p_value != 0;
      }
      if(ctlEnableProfiling.p_enabled) {
         allGNUOptions:[configName].profilerInfo = ctlEnableProfiling.p_value != 0;
      }
      if(ctlEnableGProf.p_enabled) {
         allGNUOptions:[configName].gprofInfo = ctlEnableGProf.p_value != 0;
      }
      if(ctlUseGAS.p_enabled) {
         allGNUOptions:[configName].gasInfo = ctlUseGAS.p_value != 0;
      }

      // link tab
      if(ctlNoDefaultLibs.p_enabled) {
         allGNUOptions:[configName].noDefaultLibs = ctlNoDefaultLibs.p_value != 0;
      }
      if(ctlNoStdLibs.p_enabled) {
         allGNUOptions:[configName].noStdLibs = ctlNoStdLibs.p_value != 0;
      }
      if(ctlStatic.p_enabled) {
         allGNUOptions:[configName].linkStatic = ctlStatic.p_value != 0;
      }
      if(ctlSymbolic.p_enabled) {
         allGNUOptions:[configName].linkSymbolic = ctlSymbolic.p_value != 0;
      }

      // directories tab
      // TODO

      // warnings tab
      if(ctlAllWarnings.p_enabled) {
         allGNUOptions:[configName].showAllWarnings = ctlAllWarnings.p_value != 0;
      }
      if(ctlWpedantic.p_enabled) {
         allGNUOptions:[configName].pedantic = ctlWpedantic.p_value != 0;
      }
      if(ctlAllWarningsAsErrors.p_enabled) {
         allGNUOptions:[configName].warningsAsErrors = ctlAllWarningsAsErrors.p_value != 0;
      }
      if(ctlInhibitAllWarnings.p_enabled) {
         allGNUOptions:[configName].inhibitWarnings = ctlInhibitAllWarnings.p_value != 0;
      }
   }
}

void ctlCurConfig.on_change(int reason)
{
   if (!p_active_form.p_visible && 
       (reason == CHANGE_OTHER || reason==CHANGE_CLINE_NOTVIS) ) {
      // We get 2 on_change events when before the dialog is visible.  One
      // happens when the textbox gets filled in(reason==CHANGE_OTHER), and the
      // other one we call ourselves.
      //
      // Since the one we call is later on(CHANGE_CLINE). Skip the first one
      return;
   }

   GNUC_CHANGING_CONFIG(1);

   int projectHandle = GNUC_GPROJECT_HANDLE();
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();
   configName := ctlCurConfig.p_text;

   // save all checkboxes since they dont have on_change events
   lastConfigName := _GetDialogInfoHt("GNUC_LAST_CONFIG");
   if ( lastConfigName==null ) {
      lastConfigName = "";
   }
   saveGNUCheckBoxOptions(lastConfigName, allGNUOptions);

   GNUC_INFO(allGNUOptions);

   // set the style of all checkboxes.  this is done because in 'all configurations' mode,
   // all checkboxes should be changed to 3-state in order to support the dont care state.
   // for a specific configuration, all checkboxes should be 2-state.
   style := PSCH_AUTO2STATE;
   if (configName == PROJ_ALL_CONFIGS) {
      style = PSCH_AUTO3STATEB;
   }
   p_active_form._set_all_check_box_styles(style);

   GNUC_OPTIONS currentCompileOptions = null;
   GNUC_OPTIONS currentLinkOptions = null;

   if(configName == PROJ_ALL_CONFIGS) {
      currentCompileOptions = getAllGNUOptions(allGNUOptions);
   } else {
      currentCompileOptions = allGNUOptions:[configName];
   }

   // check if this is a Clang++ project rather than a GNU project
   if (pos("clang", currentCompileOptions.compiler) > 0) {
      p_active_form.p_caption = "Clang++ Options";
   }

   // update the controls to reflect the options
   setGNUControls(currentCompileOptions);

   if(configName == PROJ_ALL_CONFIGS) {
      // enable all tabs for 'All Configurations' case
      ctlss_main_tab._setEnabled(0, 1); // compile tab
      ctlss_main_tab._setEnabled(1, 1); // codegen tab
      ctlss_main_tab._setEnabled(3, 1); // directories tab
      ctlss_main_tab._setEnabled(4, 1); // warnings tab
      ctlss_main_tab._setEnabled(5, 1); // misc tab
      ctlss_main_tab._setEnabled(2, 1); // link tab
      ctlss_main_tab._setEnabled(6, 1); // run/debug tab

   } else {
      // see if compile options tabs should be disabled
      if(usesGNUDialog(projectHandle, allGNUOptions:[configName].compileTargetNode, allGNUOptions:[configName])) {
         // enable compile related tabs
         ctlss_main_tab._setEnabled(0, 1); // compile tab
         ctlss_main_tab._setEnabled(1, 1); // codegen tab
         ctlss_main_tab._setEnabled(3, 1); // directories tab
         ctlss_main_tab._setEnabled(4, 1); // warnings tab
         ctlss_main_tab._setEnabled(5, 1); // misc tab

         // only process link command if setting up the default compile
         compileTargetName := _ProjectGet_TargetName(projectHandle, allGNUOptions:[configName].compileTargetNode);
         if(strieq(compileTargetName, "compile")) {
            // see if link options tab should be disabled
            if(usesGNUDialog(projectHandle, allGNUOptions:[configName].linkTargetNode, allGNUOptions:[configName])) {
               ctlss_main_tab._setEnabled(2, 1); // link tab
            } else {
               ctlss_main_tab._setEnabled(2, 0); // link tab
            }
         } else {
            // disable link tab
            ctlss_main_tab._setEnabled(2, 0); // link tab

            // set the form title to reflect that a compile rule is being modified
            _str inputExts = _ProjectGet_TargetInputExts(projectHandle, allGNUOptions:[configName].compileTargetNode);
            if(inputExts != "") {
               caption := p_active_form.p_caption;
               if(!pos(" - " allGNUOptions:[configName].compileInputExt, caption)) {
                  caption :+= " - compile(" inputExts ")";
                  p_active_form.p_caption = caption;
               }
            }
         }
      } else {
         // disable all compile/link related tabs
         ctlss_main_tab._setEnabled(0, 0); // compile tab
         ctlss_main_tab._setEnabled(1, 0); // codegen tab
         ctlss_main_tab._setEnabled(2, 0); // link tab
         ctlss_main_tab._setEnabled(3, 0); // directories tab
         ctlss_main_tab._setEnabled(4, 0); // warnings tab
         ctlss_main_tab._setEnabled(5, 0); // misc tab
      }

      // see if debug/run options tab should be disabled
      if(usesGNUDialog(projectHandle, allGNUOptions:[configName].debugTargetNode, allGNUOptions:[configName]) ||
         usesGNUDialog(projectHandle, allGNUOptions:[configName].executeTargetNode, allGNUOptions:[configName])) {

         ctlss_main_tab._setEnabled(6, 1); // run/debug tab
      } else {
         ctlss_main_tab._setEnabled(6, 0); // run/debug tab
      }
   }

   // record the current configuration for use next on_change
   _SetDialogInfoHt("GNUC_LAST_CONFIG",configName);
   GNUC_CHANGING_CONFIG(0);
}

void _gnuc_options_form.on_resize()
{
   padding := ctlss_main_tab.p_x;

   // how much did we change?
   widthDiff := p_width - (ctlCurConfig.p_x_extent + padding);
   heightDiff := p_height - (ctlok.p_y_extent + padding);

   // move the OK and Cancel buttons
   ctlok.p_y += heightDiff;
   ctlCancel.p_y = ctlok.p_y;

   // resize the configuration combobox
   ctlCurConfig.p_width += widthDiff;

   // resize the main tab control
   ctlss_main_tab.p_height += heightDiff;
   ctlss_main_tab.p_width += widthDiff;

   // resize the warnings tree, resizing the description column accordingly
   int colWidth;
   ctlWarningsTree.p_height += heightDiff;
   ctlWarningsTree.p_width += widthDiff;
   ctlWarningsTree._TreeGetColButtonInfo(0, colWidth, 0, 0, 0);
   ctlWarningsTree._TreeSetColButtonInfo(1, ctlWarningsTree.p_width - (colWidth + 350), TREE_BUTTON_WRAP, 0, "Description");

   // resize the advanced tree, resizing the description column accordingly
   ctlAdvancedTree.p_height += heightDiff;
   ctlAdvancedTree.p_width += widthDiff;
   ctlAdvancedTree._TreeGetColButtonInfo(0, colWidth, 0, 0, 0);
   ctlAdvancedTree._TreeSetColButtonInfo(1, ctlAdvancedTree.p_width - (colWidth + 350), TREE_BUTTON_WRAP, 0, "Description");

   // resize the controls on the directories tab
   xChange := (ctlIncDirLabel.p_x_extent + padding) - ctlUserIncludesList.p_x;
   ctlUserIncludesList.p_x += xChange;
   ctlUserIncludesList.p_width += (widthDiff - xChange);
   ctlMoveUserIncludesDown.p_x = ctlUserIncludesList.p_x_extent + 20;
   ctlMoveUserIncludesUp.p_x = ctlBrowseUserIncludes.p_x = ctlMoveUserIncludesDown.p_x;

   // enlarge the user includes list for now since the system includes are not used
   ctlUserIncludesList.p_height += heightDiff;

   // directories tab
   rightAlign := ctlss_main_tab.p_child.p_width - padding;
   alignUpDownListButtons(ctlUserIncludesList.p_window_id, 
                          rightAlign, 
                          ctlBrowseUserIncludes.p_window_id, 
                          ctlMoveUserIncludesUp.p_window_id, 
                          ctlMoveUserIncludesDown.p_window_id);

}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _gnuc_options_form_initial_alignment()
{
   padding := ctlss_main_tab.p_x;

   // compile tab
   rightAlign := ctlLanguageOptionsFrame.p_x_extent;
   sizeBrowseButtonToTextBox(ctlCompiler, ctlBrowseCompiler.p_window_id, ctlCompilerButton.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlOtherCompileOptions, ctlOtherCompilerButton.p_window_id, 0, rightAlign);

   // link tab
   rightAlign = ctlOutputType.p_x_extent;
   sizeBrowseButtonToTextBox(ctlLinker, ctlBrowseLinker.p_window_id, ctlLinkerButton.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlOutputFile, ctlToolCmdLineButton.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlLibraries.p_window_id, ctlLinkOrder.p_window_id, ctlLibrariesButton.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(ctlOtherLinkOptions, ctlOtherLinkButton.p_window_id, 0, rightAlign);

   // enforce a minimum size
   p_active_form._set_minimum_size(GNUCOPTS_FORM_WIDTH, GNUCOPTS_FORM_HEIGHT);

}

void ctlok.lbutton_up()
{
   // trigger an on_change event to force all controls to be scanned
   ctlCurConfig.call_event(CHANGE_CLINE, ctlCurConfig, ON_CHANGE, 'W');

   // save all options
   int projectHandle = GNUC_GPROJECT_HANDLE();

   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   int i;
   for(i = 0; i < gConfigList._length(); i++) {
      _str configName = gConfigList[i];

      // double check to make sure to handle old project files properly
      if(allGNUOptions._varformat() == VF_HASHTAB) {
         int compileTargetNode = allGNUOptions:[configName].compileTargetNode;
         if(compileTargetNode >= 0) {
            setGNUCommand(projectHandle, configName, compileTargetNode, allGNUOptions:[configName]);
         }

         int linkTargetNode = allGNUOptions:[configName].linkTargetNode;
         if(linkTargetNode >= 0) {
            setGNUCommand(projectHandle, configName, allGNUOptions:[configName].linkTargetNode, allGNUOptions:[configName]);
         }

         int debugTargetNode = allGNUOptions:[configName].debugTargetNode;
         if(debugTargetNode >= 0) {
            setGNUCommand(projectHandle, configName, debugTargetNode, allGNUOptions:[configName]);
         }

         int executeTargetNode = allGNUOptions:[configName].executeTargetNode;
         if(executeTargetNode >= 0) {
            setGNUCommand(projectHandle, configName, executeTargetNode, allGNUOptions:[configName]);
         }
      }
   }

   // close the gnu options dialog
   p_active_form._delete_window(0);
}

void ctlCompileAs.on_change(int reason)
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].compileAs = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].compileAs = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlDebugLevel.on_change(int reason)
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].debugLevel = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].debugLevel = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlOptimizationLevel.on_change(int reason)
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].optimizationLevel = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].optimizationLevel = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlOtherLinkOptions.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].linkerOther = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].linkerOther = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlOutputType.on_change(int reason)
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].outputType = p_text;

         // change linker program and disable controls as appropriate
         switch(allGNUOptions:[i].outputType) {
            case OUTPUT_TYPE_STATIC:
               allGNUOptions:[i].linker = "ar";
               enableLinkOptions(false);
               break;

            case OUTPUT_TYPE_EXECUTABLE:
            //case OUTPUT_TYPE_SHARED():  fall through
            default:
               // this should be set to match the compiler.  if the compiler is using gcc, the linker
               // should also be set to gcc.  mixing gcc and g++ may be ok in the link step, but
               // it is safer to keep them in synch.  the check is done just in case the compiler
               // has been changed and is neither gcc nor g++.  the default is g++.
               if(allGNUOptions:[i].compiler != "") {
                  allGNUOptions:[i].linker = allGNUOptions:[i].compiler;
               } else {
                  // default to g++ if no compiler specified
                  allGNUOptions:[i].linker == "g++";
               }
               enableLinkOptions(true);
               break;
         }
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].outputType = p_text;

      // change linker program and disable controls as appropriate
      switch(allGNUOptions:[ctlCurConfig.p_text].outputType) {
         case OUTPUT_TYPE_STATIC:
            allGNUOptions:[ctlCurConfig.p_text].linker = "ar";
            enableLinkOptions(false);
            break;

         case OUTPUT_TYPE_EXECUTABLE:
         //case OUTPUT_TYPE_SHARED(): fall through
         default:
            // this should be set to match the compiler.  if the compiler is using gcc, the linker
            // should also be set to gcc.  mixing gcc and g++ may be ok in the link step, but
            // it is safer to keep them in synch.  the check is done just in case the compiler
            // has been changed and is neither gcc nor g++.  the default is g++.
            if(allGNUOptions:[ctlCurConfig.p_text].compiler != "") {
               allGNUOptions:[ctlCurConfig.p_text].linker = allGNUOptions:[ctlCurConfig.p_text].compiler;
            } else {
               // default to g++ if no compiler specified
               allGNUOptions:[ctlCurConfig.p_text].linker = "g++";
            }
            enableLinkOptions(true);
            break;
      }
   }

   GNUC_INFO(allGNUOptions);

   // populate the form by triggering the on_change handler
   ctlCurConfig.call_event(CHANGE_CLINE, ctlCurConfig, ON_CHANGE, 'W');
}

void ctlLibraries.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].libs = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].libs = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlLinker.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].linker = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].linker = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlOutputFile.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].outputFilename = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].outputFilename = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlOtherCompileOptions.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].compilerOther = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].compilerOther = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlCompiler.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].compiler = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].compiler = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlPreprocessorDefines.on_change()
{
   if(GNUC_CHANGING_CONFIG() == 1) return;
   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         allGNUOptions:[i].defines = p_text;
      }
   } else {
      allGNUOptions:[ctlCurConfig.p_text].defines = p_text;
   }

   GNUC_INFO(allGNUOptions);
}

void ctlVerbose.lbutton_up()
{
   p_style = PSCH_AUTO2STATE;
   if(p_value == 2) {
      p_value = 0;
   }
}

void ctlEnableDebugging.lbutton_up()
{
   p_style = PSCH_AUTO2STATE;
   if(p_value == 2) {
      p_value = 0;
   }

   if(ctlEnableDebugging.p_value == 0) {
      ctlDebugLevel.p_enabled = false;
   } else {
      ctlDebugLevel.p_enabled = true;
   }
}

/**
 * Enable or disable certain controls on the link tab to
 * correspond with the linker executable in use
 *
 * @param enable   T for enabled, F for disabled
 * @param complete T for everything, F for everything except output file, output type, libs
 */
static void enableLinkOptions(bool enable, bool complete = false)
{
   // clear the value and enable/disable controls on linker tab
   // as appropriate for commands like 'ar'
   ctlNoDefaultLibs.p_value = 0;
   ctlNoDefaultLibs.p_enabled = enable;
   ctlNoStdLibs.p_value = 0;
   ctlNoStdLibs.p_enabled = enable;
   ctlStatic.p_value = 0;
   ctlStatic.p_enabled = enable;
   ctlSymbolic.p_value = 0;
   ctlSymbolic.p_enabled = enable;
   ctlOtherLinkOptionsLabel.p_enabled = enable;
   ctlOtherLinkOptions.p_text = "";
   ctlOtherLinkOptions.p_enabled = enable;

   if(complete) {
      ctlOutputTypeLabel.p_enabled = enable;
      ctlOutputType.p_text = "";
      ctlOutputType.p_enabled = enable;
      ctlOutputFileLabel.p_enabled = enable;
      ctlOutputFile.p_text = "";
      ctlOutputFile.p_enabled = enable;
      ctlLibrariesLabel.p_enabled = enable;
      ctlLibraries.p_text = "";
      ctlLibraries.p_enabled = enable;
      ctlOtherLinkOptionsLabel.p_enabled = enable;
      ctlOtherLinkOptions.p_text = "";
      ctlOtherLinkOptions.p_enabled = enable;
   }
}

int warningsTreeCheckToggle(int index)
{
   if(index > 0) {
      // get the bitmap information in the tree
      int pic, state, arrayIndex, value;
      _TreeGetInfo(index, state, pic);
      arrayIndex = _TreeGetUserInfo(index);

      value = _TreeGetCheckState(index);

      GNUC_OPTIONS allGNUOptions:[];
      allGNUOptions = GNUC_INFO();

      if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
         typeless i;
         for(i._makeempty();;) {
            allGNUOptions._nextel(i);
            if(i._isempty()) break;
            if(i == PROJ_ALL_CONFIGS) continue;

            allGNUOptions:[i].advancedWarnings:[GCC_WARNING_OPTIONS[arrayIndex].option] = value;
         }
      } else {
         allGNUOptions:[ctlCurConfig.p_text].advancedWarnings:[GCC_WARNING_OPTIONS[arrayIndex].option] = value;
      }

      GNUC_INFO(allGNUOptions);
   }

   return 0;
}

int ctlWarningsTree.on_change(int reason,int index)
{
   switch ( reason ) {
   case CHANGE_CHECK_TOGGLED:
      warningsTreeCheckToggle(index);
      break;
   }
   return 0;
}

int advancedTreeCheckToggle(int index)
{
   if(index > 0) {
      // get the bitmap information in the tree
      int pic, state, arrayIndex, value;
      _TreeGetInfo(index, state, pic);

      // make sure this is a leaf and not a folder (group) node
      if(state != -1) return 0;

      arrayIndex = _TreeGetUserInfo(index);

      _str parentCaption = _TreeGetCaption(_TreeGetParentIndex(index));

      value = _TreeGetCheckState(index);

      GNUC_OPTIONS allGNUOptions:[];
      allGNUOptions = GNUC_INFO();

      if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
         typeless i;
         for(i._makeempty();;) {
            allGNUOptions._nextel(i);
            if(i._isempty()) break;
            if(i == PROJ_ALL_CONFIGS) continue;

            switch(parentCaption) {
               case ADV_CODEGEN_CAPTION:
                  allGNUOptions:[i].advancedCodeGen:[GCC_CODEGENERATION_OPTIONS[arrayIndex].option] = value;
                  break;

               case ADV_DEBUG_CAPTION:
                  allGNUOptions:[i].advancedDebug:[GCC_DEBUG_OPTIONS[arrayIndex].option] = value;
                  break;

               case ADV_LANGUAGE_CAPTION:
                  allGNUOptions:[i].advancedLanguage:[GCC_LANGUAGE_OPTIONS[arrayIndex].option] = value;
                  break;

               case ADV_OPT_CAPTION:
                  allGNUOptions:[i].advancedOptimization:[GCC_OPTIMIZATION_OPTIONS[arrayIndex].option] = value;
                  break;

               case ADV_PREPROC_CAPTION:
                  allGNUOptions:[i].advancedPreprocessor:[GCC_PREPROCESSOR_OPTIONS[arrayIndex].option] = value;
                  break;

               default: {
                     // this must be a node in the machine options so get the caption and parse the option
                     // name out (everything before first tab)
                     caption := _TreeGetCaption(index);
                     tabPos := pos("\t", caption);
                     if(tabPos > 1) {
                        caption = substr(caption, 1, tabPos - 1);
                        allGNUOptions:[i].advancedMachine:[caption] = value;
                     }

                     break;
                  }
            }
         }

         // reset the controls so that the machine options will propagate to other machines
         // that share the same settings
         switch(parentCaption) {
            case ADV_CODEGEN_CAPTION:
            case ADV_DEBUG_CAPTION:
            case ADV_LANGUAGE_CAPTION:
            case ADV_OPT_CAPTION:
            case ADV_PREPROC_CAPTION:
               break;

            default: {
               GNUC_OPTIONS allConfigsOpts = getAllGNUOptions(allGNUOptions);
               setGNUControls(allConfigsOpts);
               break;
            }
         }

      } else {
         switch(parentCaption) {
            case ADV_CODEGEN_CAPTION:
               allGNUOptions:[ctlCurConfig.p_text].advancedCodeGen:[GCC_CODEGENERATION_OPTIONS[arrayIndex].option] = value;
               break;

            case ADV_DEBUG_CAPTION:
               allGNUOptions:[ctlCurConfig.p_text].advancedDebug:[GCC_DEBUG_OPTIONS[arrayIndex].option] = value;
               break;

            case ADV_LANGUAGE_CAPTION:
               allGNUOptions:[ctlCurConfig.p_text].advancedLanguage:[GCC_LANGUAGE_OPTIONS[arrayIndex].option] = value;
               break;

            case ADV_OPT_CAPTION:
               allGNUOptions:[ctlCurConfig.p_text].advancedOptimization:[GCC_OPTIMIZATION_OPTIONS[arrayIndex].option] = value;
               break;

            case ADV_PREPROC_CAPTION:
               allGNUOptions:[ctlCurConfig.p_text].advancedPreprocessor:[GCC_PREPROCESSOR_OPTIONS[arrayIndex].option] = value;
               break;

            default: {
                  // this must be a node in the machine options so get the caption and parse the option
                  // name out (everything before first tab)
                  caption := _TreeGetCaption(index);
                  tabPos := pos("\t", caption);
                  if(tabPos > 1) {
                     caption = substr(caption, 1, tabPos - 1);
                     allGNUOptions:[ctlCurConfig.p_text].advancedMachine:[caption] = value;
                  }

                  // reset the controls so that the machine options will propagate to other machines
                  // that share the same settings
                  setGNUControls(allGNUOptions:[ctlCurConfig.p_text]);

                  break;
               }
         }
      }

      GNUC_INFO(allGNUOptions);
   }

   _TreeRefresh();

   return 0;
}

int ctlAdvancedTree.on_change(int reason,int index)
{
   switch ( reason ) {
   case CHANGE_CHECK_TOGGLED:
      advancedTreeCheckToggle(index);
      break;
   }
   return 0;
}

static void RemoveItemFromList(_str (&List)[],_str StringToRemove)
{
   int i;
   for (i=0;i<List._length();++i) {
      if (List[i]==StringToRemove) {
         List._deleteel(i);--i;
      }
   }
}

static typeless getMatchingValue(GNUC_OPTIONS allGNUOpts:[],
                                int index,typeless defaultValue)
{
   _str LastValue=defaultValue;
   LastIndex := "";
   _str Indexes[]=GetHashTabIndexes(allGNUOpts);
   if (Indexes._length()==1) {
      typeless tmp1=allGNUOpts:[Indexes[0]];
      return(tmp1[index]);
   }
   typeless i;
   for (i._makeempty();;) {
      allGNUOpts._nextel(i);
      if (i._isempty()) break;
      if (LastIndex!="") {
         typeless tmp1=allGNUOpts:[LastIndex];
         typeless tmp2=allGNUOpts:[i];
         if (index!=-1) {
            if (tmp1[index]!=tmp2[index]) {
               return(defaultValue);
            }
            LastValue=tmp2[index];
         }else{
            if (tmp1!=tmp2) {
               return(defaultValue);
            }
            LastValue=tmp2;
         }
      }
      LastIndex=i;
   }
   return(LastValue);
}

/**
 * The default value of all checkboxes in the tree is
 * false (unchecked).
 *
 * @param allGNUOpts
 * @param index
 * @param optionList
 * @param treeValues
 */
static void getMatchingTreeValues(GNUC_OPTIONS allGNUOpts:[], int index,
                                  GCC_OPTION_INFO optionList[], int (&treeValues):[],
                                  typeless defaultValue)
{
   indexes := _get_hashtab_keys(allGNUOpts);

   // if there is only one configuration, return its values
   if(indexes._length() == 1) {
      typeless config = allGNUOpts:[indexes[0]];
      treeValues = config[index];
      return;
   }

   // iterate thru all options in array, comparing its value across all configurations
   int i;
   outerloop:
   for(i = 0; i < optionList._length(); i++) {
      _str option = optionList[i].option;
      lastIndex := "";
      typeless lastValue = defaultValue;
      typeless j;
      for(j._makeempty();;) {
         allGNUOpts._nextel(j);
         if(j._isempty()) break;
         if(lastIndex != "") {
            typeless config1 = allGNUOpts:[lastIndex];
            typeless config2 = allGNUOpts:[j];
            if(index != -1) {
               if(config1[index]:[option] != config2[index]:[option]) {
                  treeValues:[option] = defaultValue;
                  continue outerloop;
               }
               lastValue = config2[index]:[option];
            } else {
               if(config1 != config2) {
                  treeValues:[option] = defaultValue;
                  continue outerloop;
               }
               lastValue = config2;
            }
         }
         lastIndex = j;
      }

      // value is consistent across all trees
      treeValues:[option] = lastValue;
   }
}

void ctlBrowseUserIncludes.lbutton_up()
{
   wid := p_window_id;
   // TODO: save and restore def_cd variable here
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;

   _TreeBottom();
   lastIndex := _TreeCurIndex(); // get the index of the <double click... line
   _TreeAddItem(lastIndex,result,TREE_ADD_BEFORE);
   _TreeUp(); // select the newly added item
   _set_focus();
}

void ctlMoveUserIncludesUp.lbutton_up()
{
   // find the tree control relative to the edit control
   wid := p_window_id;
   p_window_id = wid.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if(index > 0) {
      // handle special cases where this is the new entry node or the prev
      // node is the new entry node
      prevIndex := _TreeGetPrevSiblingIndex(index);
      if(prevIndex == -1) return;
      if(strieq(_TreeGetCaption(index), GNU_BLANK_TREE_NODE_MSG)) return;
      if(strieq(_TreeGetCaption(prevIndex), GNU_BLANK_TREE_NODE_MSG)) return;

      _TreeMoveUp(index);

      // trigger the on_change event so that the data will be saved
      call_event(CHANGE_SELECTED, index,
                 find_index("_gnuc_options_form.ctlUserIncludesList", EVENTTAB_TYPE),
                 ON_CHANGE, 'E');
   }

   p_window_id = wid;
}

void ctlMoveUserIncludesDown.lbutton_up()
{
   // find the tree control relative to the edit control
   wid := p_window_id;
   p_window_id = wid.p_prev.p_prev.p_prev;

   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if(index > 0) {
      // handle special cases where this is the new entry node or the next node
      // is the new entry node
      nextIndex := _TreeGetNextSiblingIndex(index);
      if(nextIndex == -1) return;
      if(strieq(_TreeGetCaption(index), GNU_BLANK_TREE_NODE_MSG)) return;
      if(strieq(_TreeGetCaption(nextIndex), GNU_BLANK_TREE_NODE_MSG)) return;

      _TreeMoveDown(index);

      // trigger the on_change event so that the data will be saved
      call_event(CHANGE_SELECTED, index,
                 find_index("_gnuc_options_form.ctlUserIncludesList", EVENTTAB_TYPE),
                 ON_CHANGE, 'E');
   }

   p_window_id = wid;
}

typeless ctlUserIncludesList.on_change(int reason,int index,int col=-1,_str value="",int wid=0)
{
   if (GNUC_CHANGING_CONFIG() == 1) return 0;
   if (reason == CHANGE_BUTTON_SIZE) return 0;

   if((reason == CHANGE_EDIT_OPEN) || (reason == CHANGE_EDIT_QUERY)) {
      // if this is the new entry node, clear the message
      if(strieq(arg(4), GNU_BLANK_TREE_NODE_MSG)) {
         arg(4) = "";
      }
      //_post_call(_SetEditInPlaceCompletion,DIR_ARG);
   }

   if (reason == CHANGE_EDIT_OPEN_COMPLETE) {
      typeless completion = (p_window_id == _control ctlUserIncludesList) ? DIR_ARG : NONE_ARG;
      if (wid != 0) wid.p_completion = completion;
   }

   if(reason == CHANGE_EDIT_CLOSE) {
      // check the old caption to see if it is the new entry node
      wasNewEntryNode := strieq(_TreeGetCaption(index), GNU_BLANK_TREE_NODE_MSG);

      // HS2-CHG: or if nth. was changed (e.g. by double clicking around
      // if the node changed and is now empty, delete it
      if( (arg(4) == "") || strieq(arg(4), GNU_BLANK_TREE_NODE_MSG)) {
         if(wasNewEntryNode) {
            arg(4) = GNU_BLANK_TREE_NODE_MSG;
            return 0;
         } else {
            _TreeDelete(index);
            return DELETED_ELEMENT_RC;
         }
      }

      // make sure the last node in the tree is the new entry node
      if(wasNewEntryNode) {
         // unbold the existing node
         _TreeSetInfo(index, 0, -1, -1, 0);

         // bold the new entry node
         int newIndex = _TreeAddListItem(GNU_BLANK_TREE_NODE_MSG);
         _TreeSetInfo(newIndex, -1, -1, -1, TREENODE_BOLD);

      }
   }

   GNUC_OPTIONS allGNUOptions:[];
   allGNUOptions = GNUC_INFO();

   if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
      typeless i;
      for(i._makeempty();;) {
         allGNUOptions._nextel(i);
         if(i._isempty()) break;
         if(i == PROJ_ALL_CONFIGS) continue;

         switch(p_name) {
            case "ctlUserIncludesList":
               allGNUOptions:[i].userIncludeDirs = ctlUserIncludesList._TreeGetDelimitedItemList(PATHSEP);
               break;
         }
      }
   } else {
      switch(p_name) {
         case "ctlUserIncludesList":
            allGNUOptions:[ctlCurConfig.p_text].userIncludeDirs = ctlUserIncludesList._TreeGetDelimitedItemList(PATHSEP);
            break;
      }
   }

   GNUC_INFO(allGNUOptions);

   return 0;
}
void ctlUserIncludesList.'DEL'()
{
   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();
   if(index > 0) {
      // cannot delete new entry node
      if(strieq(_TreeGetCaption(index), GNU_BLANK_TREE_NODE_MSG)) {
         return;
      }
      _TreeDelete(index);

      // HS2-ADD: trigger an on_change event to force all controls to be scanned
      ctlUserIncludesList.call_event(CHANGE_SELECTED,index,ctlUserIncludesList,ON_CHANGE, 'W');
   }
}

_command void gnucoptions(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return;
   }
   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   if (configName == "") configName = GetCurrentConfigName();
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_gnuc_options_form',configName,ctlbutton_wid,LBUTTON_UP,'W');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   status := ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'BUILD', 'I');
   }
   if( status < 0 ) {
      _message_box('COMPILE or BUILD command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}

_command void clangoptions(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return;
   }
   if (configName == "") configName = GetCurrentConfigName();
   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_gnuc_options_form',configName,ctlbutton_wid,LBUTTON_UP,'W');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   status := ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'BUILD', 'I');
   }
   if( status < 0 ) {
      _message_box('COMPILE or BUILD command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}

_command void gnudoptions(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return;
   }
   if (configName == "") configName = GetCurrentConfigName();
   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_gnuc_options_form',configName,ctlbutton_wid,LBUTTON_UP,'W');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   status := ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'BUILD', 'I');
   }
   if( status < 0 ) {
      _message_box('COMPILE or BUILD command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}


// wizard functions ================================================================================
static const GNUCWIZ_PROJ_EXECUTABLE=        "Executable";
static const GNUCWIZ_PROJ_SHARED_LIBRARY=    "Shared library";
static const GNUCWIZ_PROJ_STATIC_LIBRARY=    "Static library";

static const GNUCWIZ_APP_EMPTY_PROJECT=      "An empty project";
static const GNUCWIZ_APP_WITH_MAIN=          "An application with a main() function";
static const GNUCWIZ_APP_HELLO_WORLD=        "A \"Hello World\" application";

static const GNUCWIZ_BUILD_VSBUILD=          "Build without a makefile (dependencies automatically checked)";
static const GNUCWIZ_BUILD_AUTO_MAKEFILE=    "Build with an auto-generated, auto-maintained makefile";
static const GNUCWIZ_BUILD_MAKEFILE=         "Build with a user-maintained makefile or custom build command";

static const GNUCWIZ_LANGUAGE_C=             "C";
static const GNUCWIZ_LANGUAGE_ANSIC=         "ANSI C";
static const GNUCWIZ_LANGUAGE_CPP=           "C++";

static const GNUCWIZ_DNAOFE_BASE=            "Do not append output file extension";


struct GNUC_WIZARD_INFO
{
   typeless callback_table:[];
   _str projectType;
   _str language;
   _str appType;
   _str buildSystem;
   _str makefile;
   bool modifyExtension;
};

// global variable to store collected information from the wizard
GNUC_WIZARD_INFO gGNUCWizardInfo;

static int gnuc_slide0create()
{
   _nocheck _control ctls0_Executable;
   _nocheck _control ctls0_DoNotModifyOutputExt;
   _nocheck _control ctls0_cpp;

   // default project type to executable
   ctls0_Executable.p_value = 1;

   // load the configuration list from the project file
   int projectHandle = _ProjectHandle();
   _str configList[] = null;
   _ProjectGet_ConfigNames(projectHandle, configList);

   // update the project file to reflect the selections
   doNotModifyOutputExtValue := 0;
   i := 0;
   for(i = 0; i < configList._length(); i++) {
      // if there is a '.' in the output filename, there is already an extension so
      // default this to on.  otherwise, default it to off.
      _str outputfile = _ProjectGet_OutputFile(projectHandle, configList[i]);
      if(pos(".", outputfile) > 0) {
         doNotModifyOutputExtValue = 1;
      }
   }
   ctls0_DoNotModifyOutputExt.p_value = doNotModifyOutputExtValue;

   // default source type to C++
   ctls0_cpp.p_value = 1;

   // default the global struct
   gGNUCWizardInfo.projectType = "";
   gGNUCWizardInfo.language = "";
   gGNUCWizardInfo.appType = "";
   gGNUCWizardInfo.buildSystem = "";
   gGNUCWizardInfo.makefile = "";
   gGNUCWizardInfo.modifyExtension = ctls0_DoNotModifyOutputExt.p_value == 0;

   return 0;
}

static int gnuc_slide0shown()
{
   // NO-OP
   return 0;
}

static int gnuc_slide0next()
{
   _nocheck _control ctls0_Executable;
   _nocheck _control ctls0_SharedLibrary;
   _nocheck _control ctls0_StaticLibrary;
   _nocheck _control ctls0_DoNotModifyOutputExt;
   _nocheck _control ctls0_c;
   _nocheck _control ctls0_ansic;
   _nocheck _control ctls0_cpp;

   WIZARD_INFO* info = _WizardGetPointerToInfo();

   // store the project type
   if(ctls0_SharedLibrary.p_value == 1) {
      // disable the application type slide
      info->callbackTable:["ctlslide1.skip"] = 1;
      gGNUCWizardInfo.projectType = GNUCWIZ_PROJ_SHARED_LIBRARY;
      gGNUCWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   } else if(ctls0_StaticLibrary.p_value == 1) {
      // disable the application type slide
      info->callbackTable:["ctlslide1.skip"] = 1;
      gGNUCWizardInfo.projectType = GNUCWIZ_PROJ_STATIC_LIBRARY;
      gGNUCWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   } else {
      // enable the application type slide
      info->callbackTable:["ctlslide1.skip"] = null;
      gGNUCWizardInfo.projectType = GNUCWIZ_PROJ_EXECUTABLE;
   }

   // store do not modify ext
   if(ctls0_DoNotModifyOutputExt.p_value == 1) {
      gGNUCWizardInfo.modifyExtension = false;
   } else {
      gGNUCWizardInfo.modifyExtension = true;
   }

   // store the language
   if(ctls0_c.p_value == 1) {
      gGNUCWizardInfo.language = GNUCWIZ_LANGUAGE_C;
   } else if(ctls0_ansic.p_value == 1) {
      gGNUCWizardInfo.language = GNUCWIZ_LANGUAGE_ANSIC;
   } else {
      gGNUCWizardInfo.language = GNUCWIZ_LANGUAGE_CPP;
   }

   return 0;
}

static int gnuc_slide1create()
{
   _nocheck _control ctls1_EmptyProject;

   // default app type to empty project
   ctls1_EmptyProject.p_value = 1;

   return 0;
}

static int gnuc_slide1shown()
{
   // NO-OP
   return 0;
}

static int gnuc_slide1next()
{
   _nocheck _control ctls1_EmptyProject;
   _nocheck _control ctls1_AppWithMain;
   _nocheck _control ctls1_HelloWorldApp;

   // store the app type
   if(ctls1_AppWithMain.p_value == 1) {
      gGNUCWizardInfo.appType = GNUCWIZ_APP_WITH_MAIN;
   } else if(ctls1_HelloWorldApp.p_value == 1) {
      gGNUCWizardInfo.appType = GNUCWIZ_APP_HELLO_WORLD;
   } else {
      gGNUCWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   }

   return 0;
}

static int gnuc_slide2create()
{
   _nocheck _control ctls2_vsbuild;

   // default to vsbuild
   ctls2_vsbuild.p_value = 1;

   return 0;
}

static int gnuc_slide2shown()
{
   // NO-OP
   return 0;
}

static int gnuc_slide2next()
{
   _nocheck _control ctls2_vsbuild;
   _nocheck _control ctls2_AutoMakefile;
   _nocheck _control ctls2_Makefile;

   // store the build system
   if(ctls2_AutoMakefile.p_value == 1) {
      gGNUCWizardInfo.buildSystem = GNUCWIZ_BUILD_AUTO_MAKEFILE;
   } else if(ctls2_Makefile.p_value == 1) {
      gGNUCWizardInfo.buildSystem = GNUCWIZ_BUILD_MAKEFILE;
   } else {
      gGNUCWizardInfo.buildSystem = GNUCWIZ_BUILD_VSBUILD;
   }

   return 0;
}

static const GCC_VERSIONS= 5;
static _str gnuc_check_cygwin_name(bool useCPP)
{
   if (_isUnix()) {
      return("");
   }
   cygwinPath := _cygwin_path():+'bin':+FILESEP;
   gccName := '';
   if (isdirectory(cygwinPath)) {
      filename := ((useCPP) ? 'g++' : 'gcc');
      if (!file_exists(cygwinPath:+filename:+'.exe')) {
         ver := 2;
         while (ver < GCC_VERSIONS) {
            filename = ((useCPP) ? 'g++-' : 'gcc-'):+ver;
            if (file_exists(cygwinPath:+filename:+'.exe')) {
               gccName = filename;
            }
            ++ver;
         }
      } else {
         gccName = filename;
      }
   }
   return(gccName);
}

static void gnuc_set_gcc(_str language, int projectHandle, int compileTargetNode, int linkTargetNode)
{ 
   gppName := 'g++';
   gccName := 'g++';
   switch(language) {
   case GNUCWIZ_LANGUAGE_C:
   case GNUCWIZ_LANGUAGE_ANSIC:
      gccName = 'gcc';
      break;

   case GNUCWIZ_LANGUAGE_CPP:
   default:
      break;
   }

   command := cmd := _ProjectGet_TargetCmdLine(projectHandle, compileTargetNode);
   filename := parse_file(cmd);
   // check if this is a Clang++ project rather than a GNU project
   if (pos("clang", filename) > 0) {
      gccName = (gccName == gppName)? "clang++" : "clang";
      gppName = "clang++";
   }
   if (filename :== 'g++') { // check if target is the default 'g++'
      cygName := gnuc_check_cygwin_name(gccName :== 'g++');
      if (cygName != '') {
         gccName = cygName;
      }
   }
   if (language == GNUCWIZ_LANGUAGE_ANSIC) {
      strappend(gccName, ' -ansi');
   }
   command = stranslate(command, gccName, gppName);
   _ProjectSet_TargetCmdLine(projectHandle, compileTargetNode, command);

   // change the link command
   command = cmd =_ProjectGet_TargetCmdLine(projectHandle, linkTargetNode);
   filename = parse_file(cmd);
   if (filename :== gppName) { // check if target is the default 'g++'
      command = stranslate(command, gccName, gppName);
   }
   _ProjectSet_TargetCmdLine(projectHandle, linkTargetNode, command);
}
static int gnuc_finish_crosscpp_wizard() {
   return gnuc_finish(true);
}
static int gnuc_finish(bool crossPlatform=false)
{
   status := 0;

   // show recap form
   status = gnuc_show_new_project_info();
   if(status) return status;

   origViewID := p_window_id;
   useCOnly := !strieq(gGNUCWizardInfo.language, GNUCWIZ_LANGUAGE_CPP);

   // check to see if anything should be generated (not "EmptyProject")
   switch(gGNUCWizardInfo.appType) {
      case GNUCWIZ_APP_WITH_MAIN:
      case GNUCWIZ_APP_HELLO_WORLD: {
         // create the file
         filename := "";
         status = generate_cppmain(filename, useCOnly, strieq(gGNUCWizardInfo.appType, GNUCWIZ_APP_HELLO_WORLD));
         if(status) {
            return (status == "") ? COMMAND_CANCELLED_RC : status;
         }

         // edit the file that was just created and position the
         // cursor to the desired starting point
         status = edit(_maybe_quote_filename(filename));
         if(!status) {
            if(useCOnly) {
               search("printf", "@");
            } else {
               search("cout", "@");
            }
         }
         break;
   }

   case GNUCWIZ_APP_EMPTY_PROJECT:
   default:
      break;
   }

   // restore the view id
   p_window_id = origViewID;

   if(status) return status;

   // load the configuration list from the project file
   int projectHandle = _ProjectHandle();
   _str configList[] = null;
   _ProjectGet_ConfigNames(projectHandle, configList);
   defaultConfig := "";

   // update the project file to reflect the selections
   i := 0;
   for(i = 0; i < configList._length(); i++) {
      // find the config node
      int configNode = _ProjectGet_ConfigNode(projectHandle, configList[i]);
      if(configNode < 0) continue;
      _str configName=_xmlcfg_get_attribute(projectHandle,configNode,'Name');
      if (strieq(configName,'windebug') && _isWindows()) {
         defaultConfig=configName;
      } else if (strieq(configName,'macdebug') && _isMac()) {
         defaultConfig=configName;
      } else if (strieq(configName,'unixdebug') && _isUnix()) {
         defaultConfig=configName;
      }

      // find the relevant target nodes
      int compileTargetNode = _ProjectGet_TargetNode(projectHandle, "compile", configList[i]);
      int linkTargetNode = _ProjectGet_TargetNode(projectHandle, "link", configList[i]);
      int debugTargetNode = _ProjectGet_TargetNode(projectHandle, "debug", configList[i]);
      int executeTargetNode = _ProjectGet_TargetNode(projectHandle, "execute", configList[i]);
      int buildTargetNode = _ProjectGet_TargetNode(projectHandle, "build", configList[i]);
      int rebuildTargetNode = _ProjectGet_TargetNode(projectHandle, "rebuild", configList[i]);

      // change the link command to build the appropriate type of output
      switch(gGNUCWizardInfo.projectType) {
         case GNUCWIZ_PROJ_SHARED_LIBRARY: {
            // get the link command and add -shared -fPIC to it
            _str command = _ProjectGet_TargetCmdLine(projectHandle, linkTargetNode);
            command :+= " -shared -fPIC";
            _ProjectSet_TargetCmdLine(projectHandle, linkTargetNode, command);

            // clear the debug and execute commands
            _ProjectSet_TargetCmdLine(projectHandle, debugTargetNode, "");
            _ProjectSet_TargetCmdLine(projectHandle, executeTargetNode, "");

            // make sure the output filename ends with '.so' or '.dll' if requested
            if(gGNUCWizardInfo.modifyExtension) {
               _str sharedLibExt;
               if (_isMac()) {
                  sharedLibExt = "dylib";
               } else if (_isUnix()) {
                  sharedLibExt = "so";
               } else {
                  sharedLibExt = "dll";
               }
               _str outputfile = _ProjectGet_OutputFile(projectHandle, configList[i]);
               if(pos("[.]" sharedLibExt "$", outputfile, 1, "U") == 0) {
                  outputfile :+= "." sharedLibExt;
               }
               _ProjectSet_OutputFile(projectHandle, outputfile, configList[i]);
            }
            _ProjectSet_GNUCOption(projectHandle, configNode, 'LinkerOutputType', 'SharedLibrary');
            break;
         }

         case GNUCWIZ_PROJ_STATIC_LIBRARY: {
            // change link command to 'ar -rs %xup "%o" %f'
            _str command = "ar -rs %xup \"%o\" %f";
            _ProjectSet_TargetCmdLine(projectHandle, linkTargetNode, command);

            // clear the debug and execute commands
            _ProjectSet_TargetCmdLine(projectHandle, debugTargetNode, "");
            _ProjectSet_TargetCmdLine(projectHandle, executeTargetNode, "");
            _ProjectSet_GNUCOption(projectHandle,configNode, 'LinkerOutputType', 'StaticLibrary');

            // make sure the output filename ends with '.a' if requested
            if(gGNUCWizardInfo.modifyExtension) {
               _str outputfile = _ProjectGet_OutputFile(projectHandle, configList[i]);
               if(pos("[.]a$", outputfile, 1, "U") == 0) {
                  outputfile :+= ".a";
               }
               _ProjectSet_OutputFile(projectHandle, outputfile, configList[i]);
            }
            break;
         }

         case GNUCWIZ_PROJ_EXECUTABLE: {
            if (_isWindows()) {
               // make sure the executable ends with '.exe' if requested and only if on windows
               if(gGNUCWizardInfo.modifyExtension) {
                  _str outputfile = _ProjectGet_OutputFile(projectHandle, configList[i]);
                  if(pos("[.]exe$", outputfile, 1, "U") == 0) {
                     outputfile :+= ".exe";
                  }
                  _ProjectSet_OutputFile(projectHandle, outputfile, configList[i]);
               }
            }
            _ProjectSet_GNUCOption(projectHandle, configNode, 'LinkerOutputType', 'Executable');
            break;
         }

         default:
            break;
      }

      if(status) return status;

      gnuc_set_gcc(gGNUCWizardInfo.language, projectHandle, compileTargetNode, linkTargetNode);

      // change the make/rebuild commands to the appropriate build command
      switch(gGNUCWizardInfo.buildSystem) {
         case GNUCWIZ_BUILD_AUTO_MAKEFILE: {
            // add buildsystem and makefile to GLOBAL section, defaulting the value to '%rp%rn.mak'
            _ProjectSet_BuildSystem(projectHandle, "automakefile");

            if(gGNUCWizardInfo.makefile == "") {
               gGNUCWizardInfo.makefile = "%rp%rn.mak";
            }

            useGNU := true;
            _str platform_makefile=gGNUCWizardInfo.makefile;
            if (crossPlatform) {
               platform_makefile=_strip_filename(gGNUCWizardInfo.makefile,'E');
               if (strieq(substr(configName,1,3),'win')) {
                  platform_makefile :+= "-vcpp";
                  useGNU=false;
               } else {
                  platform_makefile :+= "-gnu";
               }
               platform_makefile :+= _get_extension(gGNUCWizardInfo.makefile,true);

            }
            // add the makefile to the project
            // NOTE: this should be done *before* the 'makefile' value is set in the 'GLOBAL'
            //       section to avoid triggering the makefile regeneration when the makefile
            //       is added
            _AddFileToProject(_maybe_quote_filename(_parse_project_command(platform_makefile, "", _project_name, "")));
            _ProjectSet_BuildMakeFile(projectHandle, strip(gGNUCWizardInfo.makefile,'B','"'));
            // replace build command with "make makefilename" and clear the dialog
            _str makeCommand = ((useGNU)?_findGNUMake():'nmake') " -f \"" platform_makefile "\" CFG=%b";
            _ProjectSet_TargetCmdLine(projectHandle, buildTargetNode, makeCommand);
            _ProjectSet_TargetDialog(projectHandle, buildTargetNode, "");

            // replace rebuild command with "make makefilename" and clear the dialog
            _str rebuildCommand = ((useGNU)?_findGNUMake():'nmake') " -f \"" platform_makefile "\" rebuild CFG=%b";
            _ProjectSet_TargetCmdLine(projectHandle, rebuildTargetNode, rebuildCommand);
            _ProjectSet_TargetDialog(projectHandle, rebuildTargetNode, "");
            break;
         }

         case GNUCWIZ_BUILD_MAKEFILE: {
            // replace make command with "make makefilename" and clear the dialog
            _ProjectSet_TargetCmdLine(projectHandle, buildTargetNode, "make");
            _ProjectSet_TargetDialog(projectHandle, buildTargetNode, "");

            // clear the rebuild command
            _ProjectSet_TargetCmdLine(projectHandle, rebuildTargetNode, "");
            _ProjectSet_TargetDialog(projectHandle, rebuildTargetNode, "");
            break;
         }

         case GNUCWIZ_BUILD_VSBUILD:
            _ProjectSet_BuildSystem(projectHandle, "vsbuild");
            break;

         default:
            break;
      }
   }

   // save the project file
   _ProjectSave(projectHandle);
   if (defaultConfig!='') {
      project_config_set_active(defaultConfig);
   }

   // if this should have an autogenerated makefile, do it now
   if(gGNUCWizardInfo.buildSystem == GNUCWIZ_BUILD_AUTO_MAKEFILE) {
      generate_makefile(_project_name, "", false, false);
   }

   // if this was an empty project, open the project properties
   if(gGNUCWizardInfo.appType == GNUCWIZ_APP_EMPTY_PROJECT) {
      project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
   }

   return 0;
}

_command int gnuc_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // setup callback table
   gGNUCWizardInfo.callback_table._makeempty();
   gGNUCWizardInfo.callback_table:["ctlslide0.create"] = gnuc_slide0create;
   gGNUCWizardInfo.callback_table:["ctlslide0.shown"] = gnuc_slide0shown;
   gGNUCWizardInfo.callback_table:["ctlslide0.next"] = gnuc_slide0next;
   gGNUCWizardInfo.callback_table:["ctlslide1.create"] = gnuc_slide1create;
   gGNUCWizardInfo.callback_table:["ctlslide1.shown"] = gnuc_slide1shown;
   gGNUCWizardInfo.callback_table:["ctlslide1.next"] = gnuc_slide1next;
   gGNUCWizardInfo.callback_table:["ctlslide2.create"] = gnuc_slide2create;
   gGNUCWizardInfo.callback_table:["ctlslide2.shown"] = gnuc_slide2shown;
   gGNUCWizardInfo.callback_table:["ctlslide2.next"] = gnuc_slide2next;
   gGNUCWizardInfo.callback_table:["finish"] = gnuc_finish;

   // setup wizard
   WIZARD_INFO info;
   info.callbackTable = gGNUCWizardInfo.callback_table;
   info.parentFormName = "_gnuc_wizard_form";
   info.dialogCaption = "Create GNU C/C++ Project";

   // start the wizard
   int status = _Wizard(&info);

   return status;
}

_command int clang_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // setup callback table
   gGNUCWizardInfo.callback_table._makeempty();
   gGNUCWizardInfo.callback_table:["ctlslide0.create"] = gnuc_slide0create;
   gGNUCWizardInfo.callback_table:["ctlslide0.shown"] = gnuc_slide0shown;
   gGNUCWizardInfo.callback_table:["ctlslide0.next"] = gnuc_slide0next;
   gGNUCWizardInfo.callback_table:["ctlslide1.create"] = gnuc_slide1create;
   gGNUCWizardInfo.callback_table:["ctlslide1.shown"] = gnuc_slide1shown;
   gGNUCWizardInfo.callback_table:["ctlslide1.next"] = gnuc_slide1next;
   gGNUCWizardInfo.callback_table:["ctlslide2.create"] = gnuc_slide2create;
   gGNUCWizardInfo.callback_table:["ctlslide2.shown"] = gnuc_slide2shown;
   gGNUCWizardInfo.callback_table:["ctlslide2.next"] = gnuc_slide2next;
   gGNUCWizardInfo.callback_table:["finish"] = gnuc_finish;

   // setup wizard
   WIZARD_INFO info;
   info.callbackTable = gGNUCWizardInfo.callback_table;
   info.parentFormName = "_gnuc_wizard_form";
   info.dialogCaption = "Create Clang++ Project";

   // start the wizard
   int status = _Wizard(&info);

   return status;
}

_command int crosscpp_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // setup callback table
   gGNUCWizardInfo.callback_table._makeempty();
   gGNUCWizardInfo.callback_table:["ctlslide0.create"] = gnuc_slide0create;
   gGNUCWizardInfo.callback_table:["ctlslide0.shown"] = gnuc_slide0shown;
   gGNUCWizardInfo.callback_table:["ctlslide0.next"] = gnuc_slide0next;
   gGNUCWizardInfo.callback_table:["ctlslide1.create"] = gnuc_slide1create;
   gGNUCWizardInfo.callback_table:["ctlslide1.shown"] = gnuc_slide1shown;
   gGNUCWizardInfo.callback_table:["ctlslide1.next"] = gnuc_slide1next;
   gGNUCWizardInfo.callback_table:["ctlslide2.create"] = gnuc_slide2create;
   gGNUCWizardInfo.callback_table:["ctlslide2.shown"] = gnuc_slide2shown;
   gGNUCWizardInfo.callback_table:["ctlslide2.next"] = gnuc_slide2next;
   gGNUCWizardInfo.callback_table:["finish"] = gnuc_finish_crosscpp_wizard;

   // setup wizard
   WIZARD_INFO info;
   info.callbackTable = gGNUCWizardInfo.callback_table;
   info.parentFormName = "_gnuc_wizard_form";
   info.dialogCaption = "Create Cross Platform C++ Project";

   // start the wizard
   int status = _Wizard(&info);

   return status;
}

static int gnuc_show_new_project_info()
{
   status := 0;

   line := "";
   _add_line_to_html_caption(line, "<B>Project Type:</B>");
   _add_line_to_html_caption(line, gGNUCWizardInfo.projectType);
   _add_line_to_html_caption(line, "");
   _add_line_to_html_caption(line, "<B>Source Type:</B>");
   _add_line_to_html_caption(line, gGNUCWizardInfo.language);
   _add_line_to_html_caption(line, "");
   if(gGNUCWizardInfo.projectType == GNUCWIZ_PROJ_EXECUTABLE) {
      _add_line_to_html_caption(line, "<B>Application Type:</B>");
      _add_line_to_html_caption(line, gGNUCWizardInfo.appType);
      _add_line_to_html_caption(line, "");
   }
   _add_line_to_html_caption(line, "<B>Build System:</B>");
   _add_line_to_html_caption(line, gGNUCWizardInfo.buildSystem);
   if(gGNUCWizardInfo.buildSystem == GNUCWIZ_BUILD_AUTO_MAKEFILE && gGNUCWizardInfo.makefile != "") {
      _add_line_to_html_caption(line, "Makefile: " gGNUCWizardInfo.makefile);
   }

   status = show("-modal _new_project_info_form",
                 "Creating a skeleton project for you with the following specifications:",
                 line);
   if(status == "") {
      return COMMAND_CANCELLED_RC;
   }
   return status;
}

static int generate_cppmain(_str& filename, bool useCOnly, bool addHelloWorld)
{
   // build filename with appropriate extension
   filename = _strip_filename(_project_name,'E') :+ (useCOnly ? ".c" : ".cpp");

   // if the file already exists, see if it should be overwritten
   if (file_exists(filename)) {
      int result = _message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if(result == IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      } else if(result == IDNO) {
         return 1;
      }
   }

   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = filename;
   p_UTF8 = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr = indent_string(p_SyntaxIndent);

   if(useCOnly) {
      insert_line("#include <stdio.h>");
      insert_line("");
      insert_line("int main (int argc, char *argv[])");
      insert_line("{");
      if(addHelloWorld) {
         insert_line(indentStr "printf(\"hello world\\n\");");
      }
      insert_line(indentStr "return(0);");
      insert_line("}");
      insert_line("");
   } else {
      //insert_line("#include <iostream.h>");
      insert_line("#include <iostream>");
      insert_line("");
      insert_line("using namespace std;");
      insert_line("");
      insert_line("int main (int argc, char *argv[])");
      insert_line("{");
      if(addHelloWorld) {
         insert_line(indentStr "cout << \"hello world\" << endl;");
      }
      insert_line(indentStr "return(0);");
      insert_line("}");
      insert_line("");
   }
   int status=_save_file(build_save_options(p_buf_name));

   _AddFileToProject(filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

defeventtab _gnuc_wizard_form;
void ctls0_Executable.lbutton_up()
{
   if (_isUnix()) {
      ctls0_DoNotModifyOutputExt.p_caption = GNUCWIZ_DNAOFE_BASE;
   } else {
      ctls0_DoNotModifyOutputExt.p_caption = GNUCWIZ_DNAOFE_BASE " (.exe)";
   }
}

void ctls0_SharedLibrary.lbutton_up()
{
   _str sharedLibExt;
   if (_isMac()) {
      sharedLibExt = "dylib";
   } else if (_isUnix()) {
      sharedLibExt = "so";
   } else {
      sharedLibExt = "dll";
   }
   ctls0_DoNotModifyOutputExt.p_caption = GNUCWIZ_DNAOFE_BASE " (."sharedLibExt")";
}

void ctls0_StaticLibrary.lbutton_up()
{
   ctls0_DoNotModifyOutputExt.p_caption = GNUCWIZ_DNAOFE_BASE " (.a)";
}

void ctls2_vsbuild.lbutton_up()
{
   // disable the makefile textbox
   ctlMakefileExplanation.p_enabled = false;
   ctlMakefileLabel.p_enabled = false;
   ctlMakefile.p_enabled = false;
}

void ctls2_AutoMakefile.lbutton_up()
{
   // enable the makefile textbox
   ctlMakefileExplanation.p_enabled = true;
   ctlMakefileLabel.p_enabled = true;
   ctlMakefile.p_enabled = true;
}

void ctls2_Makefile.lbutton_up()
{
   // disable the makefile textbox
   ctlMakefileExplanation.p_enabled = false;
   ctlMakefileLabel.p_enabled = false;
   ctlMakefile.p_enabled = false;
}

void ctlMakefile.on_change()
{
   gGNUCWizardInfo.makefile = p_text;
}

int loadGNUOptionsFromXML(_str xmlOptionsFilename, _str machineName = "")
{
   // empty all of the arrays
   GCC_WARNING_OPTIONS._makeempty();
   GCC_OVERALL_OPTIONS._makeempty();
   GCC_LANGUAGE_OPTIONS._makeempty();
   GCC_PREPROCESSOR_OPTIONS._makeempty();
   GCC_DEBUG_OPTIONS._makeempty();
   GCC_OPTIMIZATION_OPTIONS._makeempty();
   GCC_CODEGENERATION_OPTIONS._makeempty();
   GCC_MACHINE_OPTIONS._makeempty();


   status := 0;
   typeless nodeList[] = null;
   int i;

   int handle = _xmlcfg_open(xmlOptionsFilename, status);
   if(handle < 0) {
      return status;
   }

   // find the warnings option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Warning']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_WARNING_OPTIONS[GCC_WARNING_OPTIONS._length()] = info;
   }

   // find the overall option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Overall']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_OVERALL_OPTIONS[GCC_OVERALL_OPTIONS._length()] = info;
   }

   // find the language option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Language']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_LANGUAGE_OPTIONS[GCC_LANGUAGE_OPTIONS._length()] = info;
   }

   // find the preprocessor option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Preprocessor']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_PREPROCESSOR_OPTIONS[GCC_PREPROCESSOR_OPTIONS._length()] = info;
   }

   // find the debug option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Debug']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_DEBUG_OPTIONS[GCC_DEBUG_OPTIONS._length()] = info;
   }

   // find the optimization option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Optimization']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_OPTIMIZATION_OPTIONS[GCC_OPTIMIZATION_OPTIONS._length()] = info;
   }

   // find the code generation option set
   _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='CodeGeneration']//Option", nodeList);
   for(i = 0; i < nodeList._length(); i++) {
      int node = nodeList[i];

      GCC_OPTION_INFO info;
      info.option = _xmlcfg_get_attribute(handle, node, "Name");
      info.description = _xmlcfg_get_attribute(handle, node, "Description");

      // add it to the array
      GCC_CODEGENERATION_OPTIONS[GCC_CODEGENERATION_OPTIONS._length()] = info;
   }

   // find the machine option set
   typeless machineList[] = null;
   int k;
   if(machineName == "") {
      _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Machine']", machineList);
   } else {
      _xmlcfg_find_simple_array(handle, "/GNUCOptions/OptionSet[@Type='Machine'][@Architecture='" machineName "']", machineList);
   }
   for(k = 0; k < machineList._length(); k++) {
      GCC_MACHINE_INFO machineInfo = null;
      machineInfo.architecture = _xmlcfg_get_attribute(handle, machineList[k], "Architecture");

      _xmlcfg_find_simple_array(handle, "Option", nodeList, machineList[k]);
      // get options for this machine
      for(i = 0; i < nodeList._length(); i++) {
         int node = nodeList[i];

         GCC_OPTION_INFO info;
         info.option = _xmlcfg_get_attribute(handle, node, "Name");
         info.description = _xmlcfg_get_attribute(handle, node, "Description");

         // add it to the array
         machineInfo.options[machineInfo.options._length()] = info;
      }

      // add it to the machine array
      GCC_MACHINE_OPTIONS[GCC_MACHINE_OPTIONS._length()] = machineInfo;
   }

   // close the file
   _xmlcfg_close(handle);

   return status;
}


static const CSHARP_PROJ_CONSOLE_APPLICATION=   "exe";
static const CSHARP_PROJ_WINDOWS_APPLICATION=   "winexe";
static const CSHARP_PROJ_LIBRARY=               "library";

struct CSHARP_WIZARD_INFO {
   typeless callback_table:[];
   _str projectType;
   _str appType;
   //bool modifyExtension;
};

// global variable to store collected information from the wizard
static CSHARP_WIZARD_INFO gCSharpWizardInfo;

static int csharp_slide0create()
{
   _nocheck _control ctls0_console_app;

   // default project type to executable
   ctls0_console_app.p_value = 1;

#if 0
   // load the configuration list from the project file
   int projectHandle = _ProjectHandle();
   _str configList[] = null;
   _ProjectGet_ConfigNames(projectHandle, configList);
   // update the project file to reflect the selections
   doNotModifyOutputExtValue := 0;
   i := 0;
   for(i = 0; i < configList._length(); i++) {
      // if there is a '.' in the output filename, there is already an extension so
      // default this to on.  otherwise, default it to off.
      _str outputfile = _ProjectGet_OutputFile(projectHandle, configList[i]);
      if(pos(".", outputfile) > 0) {
         doNotModifyOutputExtValue = 1;
      }
   }
   ctls0_DoNotModifyOutputExt.p_value = doNotModifyOutputExtValue;

   // default source type to C++
   ctls0_cpp.p_value = 1;
#endif

   // default the global struct
   gCSharpWizardInfo.projectType = "";
   gCSharpWizardInfo.appType = "";
   //gCSharpWizardInfo.modifyExtension = ctls0_DoNotModifyOutputExt.p_value == 0;

   return 0;
}

static int csharp_slide0shown()
{
   // NO-OP
   return 0;
}

static int csharp_slide0next()
{
   _nocheck _control ctls0_console_app;
   _nocheck _control ctls0_library;
   _nocheck _control ctls0_windows_app;
   //_nocheck _control ctls0_DoNotModifyOutputExt;

   WIZARD_INFO* info = _WizardGetPointerToInfo();

   // store the project type
   if(ctls0_library.p_value == 1) {
      //// disable the application type slide
      //info->callbackTable:["ctlslide1.skip"] = 1;
      gCSharpWizardInfo.projectType = CSHARP_PROJ_LIBRARY;
      gCSharpWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   } else if(ctls0_windows_app.p_value == 1) {
      // disable the application type slide
      //info->callbackTable:["ctlslide1.skip"] = 1;
      gCSharpWizardInfo.projectType = CSHARP_PROJ_WINDOWS_APPLICATION;
      gCSharpWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   } else {
      // enable the application type slide
      //info->callbackTable:["ctlslide1.skip"] = null;
      gCSharpWizardInfo.projectType = CSHARP_PROJ_CONSOLE_APPLICATION;
   }
#if 0
   // store do not modify ext
   if(ctls0_DoNotModifyOutputExt.p_value == 1) {
      gCSharpWizardInfo.modifyExtension = false;
   } else {
      gCSharpWizardInfo.modifyExtension = true;
   }
#endif
   _nocheck _control ctls0_radio1;
   _nocheck _control ctls0_radio2;
   _nocheck _control ctls0_radio3;

   // store the app type
   if(ctls0_radio2.p_value == 1) {
      gCSharpWizardInfo.appType = GNUCWIZ_APP_WITH_MAIN;
   } else if(ctls0_radio3.p_value == 1) {
      gCSharpWizardInfo.appType = GNUCWIZ_APP_HELLO_WORLD;
   } else {
      gCSharpWizardInfo.appType = GNUCWIZ_APP_EMPTY_PROJECT;
   }

   return 0;
}

/*static int csharp_show_new_project_info()
{
   status := 0;

   line := "";
   _add_line_to_html_caption(line, "<B>Output Type:</B>");
   _add_line_to_html_caption(line, gCSharpWizardInfo.projectType);
   _add_line_to_html_caption(line, "");
   if(gCSharpWizardInfo.projectType == GNUCWIZ_PROJ_EXECUTABLE) {
      _add_line_to_html_caption(line, "<B>Application Type:</B>");
      _add_line_to_html_caption(line, gCSharpWizardInfo.appType);
      _add_line_to_html_caption(line, "");
   }
   status = show("-modal _new_project_info_form",
                 "Creating a skeleton project for you with the following specifications:",
                 line);
   if(status == "") {
      return COMMAND_CANCELLED_RC;
   }
   return status;
} */

static int generate_csharp_main(_str& filename, bool addHelloWorld)
{
   // build filename with appropriate extension
   name:='Program';
   filename= _strip_filename(_project_name,'N') :+ name:+'.cs';

   // if the file already exists, see if it should be overwritten
   if (file_exists(filename)) {
      int result = _message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if(result == IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      } else if(result == IDNO) {
         return 1;
      }
   }

   temp_view_id := 0;
   int orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = filename;
   //p_UTF8 = _load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr = indent_string(p_SyntaxIndent);
   _str indentStr2 = indent_string(p_SyntaxIndent*2);

   insert_line("using System;");
   insert_line("");
   insert_line("class ":+name:+" {");
   insert_line(indentStr:+'static void Main(string[] args) {');
   if(addHelloWorld) {
      insert_line(indentStr2:+'Console.WriteLine("hello world!");');
   }
   insert_line(indentStr:+"}");
   insert_line("}");
   c_beautify();
   int status=_save_file(build_save_options(p_buf_name));

   _AddFileToProject(filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}
static int csharp_finish(bool crossPlatform=false)
{
   status := 0;

   // show recap form
   //status = csharp_show_new_project_info();
   //if(status) return status;

   origViewID := p_window_id;

   // check to see if anything should be generated (not "EmptyProject")
   switch(gCSharpWizardInfo.appType) {
   case GNUCWIZ_APP_WITH_MAIN:
   case GNUCWIZ_APP_HELLO_WORLD: {
      // create the file
      filename := "";
      status = generate_csharp_main(filename, strieq(gCSharpWizardInfo.appType, GNUCWIZ_APP_HELLO_WORLD));
      if(status) {
         return (status == "") ? COMMAND_CANCELLED_RC : status;
      }

      // edit the file that was just created and position the
      // cursor to the desired starting point
      status = edit(_maybe_quote_filename(filename));
      if(!status) {
         search("Console.WriteLine", "@");
      }
      break;
   }
   case GNUCWIZ_APP_EMPTY_PROJECT:
   default:
      break;
   }

   // restore the view id
   p_window_id = origViewID;

   if(status) return status;

   int projectHandle = _ProjectHandle();

   if (gCSharpWizardInfo.projectType!=CSHARP_PROJ_CONSOLE_APPLICATION) {
      typeless array[];
      _xmlcfg_find_simple_array(projectHandle,"/Project/Config/Menu/Target[@Name='Build']/Exec",array);
      for (i:=0;i<array._length();++i) {
         node:=array[i];
         cmdline:=_xmlcfg_get_attribute(projectHandle,node,'CmdLine');
         parse cmdline with auto before '-target:exe' auto rest;
         if (before!='') {
            cmdline=before' -target:'gCSharpWizardInfo.projectType;
            if (rest!='') {
               strappend(cmdline,' ':+rest);
            }
            _xmlcfg_set_attribute(projectHandle,node,'CmdLine',cmdline);
         }
      }
      if (gCSharpWizardInfo.projectType==CSHARP_PROJ_LIBRARY) {
         _xmlcfg_find_simple_array(projectHandle,"/Project/Config",array);
         for (i=0;i<array._length();++i) {
            node:=array[i];
            cmdline:=_xmlcfg_get_attribute(projectHandle,node,'OutputFile');
            cmdline=stranslate(cmdline,'.dll','%exe');
            _xmlcfg_set_attribute(projectHandle,node,'OutputFile',cmdline);
         }
      }
   }

   _str configList[] = null;
   _ProjectGet_ConfigNames(projectHandle, configList);
   defaultConfig := "";


   // save the project file
   _ProjectSave(projectHandle);
   if (defaultConfig!='') {
      project_config_set_active(defaultConfig);
   }

   // if this was an empty project, open the project properties
   if(gCSharpWizardInfo.appType == GNUCWIZ_APP_EMPTY_PROJECT) {
      project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
   }

   return 0;
}
_command int csharp_csc_wizard(_str dialogCaption="Create C# (csc) Project") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   // setup callback table
   gCSharpWizardInfo.callback_table._makeempty();
   gCSharpWizardInfo.callback_table:["ctlslide0.create"] = csharp_slide0create;
   gCSharpWizardInfo.callback_table:["ctlslide0.shown"] = csharp_slide0shown;
   gCSharpWizardInfo.callback_table:["ctlslide0.next"] = csharp_slide0next;
   gCSharpWizardInfo.callback_table:["finish"] = csharp_finish;

   // setup wizard
   WIZARD_INFO info;
   info.callbackTable = gCSharpWizardInfo.callback_table;
   info.parentFormName = "_csharp_wizard_form";
   info.dialogCaption = dialogCaption;

   // start the wizard
   int status = _Wizard(&info);
   return status;
}
_command int csharp_mono_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   return csharp_csc_wizard("Create C# Mono Project");
}

defeventtab _csharp_wizard_form;
void ctls0_console_app.on_create() {
   ctls0_radio1.p_value=1;
}
void ctls0_console_app.lbutton_up()
{
    if (ctls0_library.p_value) {
       ctls0_radio1.p_enabled=ctls0_radio2.p_enabled=ctls0_radio3.p_enabled=false;
    } else {
       ctls0_radio1.p_enabled=ctls0_radio2.p_enabled=ctls0_radio3.p_enabled=true;
    }
}

