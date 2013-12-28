////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47489 $
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
#include "tagsdb.sh"
#include "debug.sh"
#include "unittest.sh"
#include "xml.sh"
#include "minihtml.sh"
#import "cbrowser.e"
#import "compile.e"
#import "context.e"
#import "debuggui.e"
#import "dlgman.e"
#import "error.e"
#import "files.e"
#import "guicd.e"
#import "help.e"
#import "junit.e"
#import "last.e"
#import "main.e"
#import "os2cmds.e"
#import "projconv.e"
#import "project.e"
#import "ptoolbar.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "tagwin.e"
#import "toolbar.e"
#import "treeview.e"
#import "util.e"
#import "vc.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#endregion

_str def_unittest_junitjar = ""; // Holds the location of the user's junit.jar file

VS_UNITTEST_INFO gUnitTestCurrentTests:[]; // Main data structure. Holds a list of test entries index by fully-qualified test name
_utTreeCacheEntry gUnitTestTreeCache:[]; // We use this to keep track of tree indices for packages, classes, etc.
_utTraceEntry gUnitTestCurrentFailures:[][]; // Holds all the current failures and associated messages
int gUnitTestSelectionStack[]; // Stack that we can use to push and pop selections
int gUnitTestIconMatrix[][]; // This is a 2-D table which tells us what icon to use for a given unit test item and status
_str gUnitTestFromWhere=''; // This tells us how unittesting was invoked
_str gUnitTestOldCmdLine=''; // This holds the value of the original command line for the debug target
boolean gDebuggedJUnit=false; // Did we debug a JUnit test?
int gUnitTestParseLineNum=-1; // This is the line number in the ParseOutputWindow at which to start parsing
_str gUnitTestCmdLineArgs=""; // Command line arguments specified the last time ut or utd is invoked
int gUnitTestDebug = 0;
int gUnitTestParseOutputWindowID=-1; // This is the window ID of the buffer containing output of unit testing
static int gHierarchyLevels = 1; // If this is >0, we want a 3-level hierarchy: packages, classes, method. If this is 0, we want 2-level: classes, methods

// Some regular expressions used when parsing test output
_str _error_javaException2='^\tat:b#{#0[~\(]#}\({#1[~\)\:]#}\)';
_str _error_javaException3='^\tat:b#{#0[~\(]#}\({#1?#}\:{#2:i}\)';
_str _error_junitExceptionHeader= '^:i\):b#{#0[~\(]#}\({#1[~\)]#}\)';
_str _regex_TestMethod='^METHOD:b#{#0[~\(]#}\({#1[~\)]#}\){#2?#}';
_str _error_SlickC;


_str _utSlickUnitLocateTestMethod(_str testName, int &lineNum=null);
_command void sunit(_str testName='');
int _utSlickUnitRunTestSet(_str (&testNames)[]);
void _utSlickUnitRunAllTestMethods();


void _utDebugSay(_str line) {
   if (gUnitTestDebug & VS_UNITTEST_DEBUG) {
      say("!!! DEBUG: "line);
   }
}

/**
 * This is called when debugging has stopped or started
 */
int _utDebugCallback(int reason)
{
   if (reason == VSDEBUG_UPDATE_INITIALIZE) {
      _utOnDebugStart();
   }
   else if (reason == VSDEBUG_UPDATE_FINALIZE) {
      _utOnDebugStop();
   }
   return 0;
}

defload()
{
   _pic_ut_method = _update_picture(-1, "_ut_method.ico");
   _pic_ut_method_error = _update_picture(-1, "_ut_method_error.ico");
   _pic_ut_method_passed = _update_picture(-1, "_ut_method_passed.ico");
   _pic_ut_method_failure = _update_picture(-1, "_ut_method_failure.ico");
   _pic_ut_method_notrun = _update_picture(-1, "_ut_method_notrun.ico");
   _pic_ut_class = _update_picture(-1, "_ut_class.ico");
   _pic_ut_class_error = _update_picture(-1, "_ut_class_error.ico");
   _pic_ut_class_passed = _update_picture(-1, "_ut_class_passed.ico");
   _pic_ut_class_failure = _update_picture(-1, "_ut_class_failure.ico");
   _pic_ut_class_notrun = _update_picture(-1, "_ut_class_notrun.ico");
   _pic_ut_package = _update_picture(-1, "_ut_package.ico");
   _pic_ut_package_error = _update_picture(-1, "_ut_package_error.ico");
   _pic_ut_package_passed = _update_picture(-1, "_ut_package_passed.ico");
   _pic_ut_package_failure = _update_picture(-1, "_ut_package_failure.ico");
   _pic_ut_package_notrun = _update_picture(-1, "_ut_package_notrun.ico");

   _pic_ut_error = _update_picture(-1, "_ut_error.ico");
   _pic_ut_failure = _update_picture(-1, "_ut_failure.ico");
   _pic_ut_information = _update_picture(-1, "_ut_information.ico");

   gUnitTestIconMatrix[VS_UNITTEST_ITEM_METHOD][VS_UNITTEST_STATUS_NOTRUN] = _pic_ut_method_notrun;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_METHOD][VS_UNITTEST_STATUS_PASSED] = _pic_ut_method_passed;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_METHOD][VS_UNITTEST_STATUS_FAILED] = _pic_ut_method_failure;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_METHOD][VS_UNITTEST_STATUS_ERROR] = _pic_ut_method_error;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_METHOD][VS_UNITTEST_STATUS_IGNORE] = _pic_ut_method_notrun;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_CLASS][VS_UNITTEST_STATUS_NOTRUN] = _pic_ut_class_notrun;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_CLASS][VS_UNITTEST_STATUS_PASSED] = _pic_ut_class_passed;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_CLASS][VS_UNITTEST_STATUS_FAILED] = _pic_ut_class_failure;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_CLASS][VS_UNITTEST_STATUS_ERROR] = _pic_ut_class_error;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_SUITE][VS_UNITTEST_STATUS_NOTRUN] = _pic_ut_class_notrun;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_SUITE][VS_UNITTEST_STATUS_PASSED] = _pic_ut_class_passed;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_SUITE][VS_UNITTEST_STATUS_FAILED] = _pic_ut_class_failure;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_SUITE][VS_UNITTEST_STATUS_ERROR] = _pic_ut_class_error;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_PACKAGE][VS_UNITTEST_STATUS_NOTRUN] = _pic_ut_package_notrun;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_PACKAGE][VS_UNITTEST_STATUS_PASSED] = _pic_ut_package_passed;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_PACKAGE][VS_UNITTEST_STATUS_FAILED] = _pic_ut_package_failure;
   gUnitTestIconMatrix[VS_UNITTEST_ITEM_PACKAGE][VS_UNITTEST_STATUS_ERROR] = _pic_ut_package_error;

   _utReset();
   gUnitTestFromWhere = '';
   gUnitTestCmdLineArgs = '';
}

/**
 * Gets called any time a project is closed
 */
void _prjclose_unittest()
{
   debug_gui_remove_update_callback(_utDebugCallback);
   _utReset();
}

/**
 * Gets called any time a project is opened
 */
void _prjopen_unittest()
{
   // Make sure unit testing is enabled before adding our debug callback
   _str currentConfig = GetCurrentConfigName(_project_name);
   if (_utIsUnitTestEnabledForProject(_project_name, currentConfig)) {
      debug_gui_remove_update_callback(_utDebugCallback);
      debug_gui_add_update_callback(_utDebugCallback);
      // If we have a Java project open, convert the Unit Test command if necessary, for all configs 
      if (_utIsJavaProject(_project_name) == 1) {
         int handle = _ProjectHandle();
         _str List[];
         _ProjectGet_ConfigNames(handle,List);
         int i;
         for (i = 0; i < List._length(); i++) {
            _str config = List[i];
            int utNode = _ProjectGet_TargetNode(handle, "UnitTest", config); 
            if (utNode >= 0){ 
               _str cmdline = _ProjectGet_TargetCmdLine(handle, utNode);
               if (pos(VS_UNITTEST_JUNITTESTRUNNER,cmdline)) {
                  _str new_cmdline = stranslate(cmdline,VS_UNITTEST_JUNITCORE,VS_UNITTEST_JUNITTESTRUNNER); 
                  _ProjectSet_TargetCmdLine(handle, utNode, new_cmdline);
               }
            }
         }
      }
   }
}

defeventtab _tbunittest_form;

/**
 * Callback for when the unittest form is resized
 */
void _tbunittest_form.on_resize()
{
   // get the active form's client width and height in twips
   int clientHeight = _dy2ly(SM_TWIP, p_active_form.p_client_height) - _top_height() - _bottom_height();
   int clientWidth = _dx2lx(SM_TWIP, p_active_form.p_client_width);

   int halfHeight = (int) (clientHeight/2);
   int halfWidth = (int) (clientWidth/2);

   int newY = 20;
   ctlgauge_progress._move_window(ctlgauge_progress.p_x, newY, clientWidth-200, ctlgauge_progress.p_height);
   newY += ctlgauge_progress.p_height+20;
   ctlhtml_summary._move_window(0, newY, clientWidth, 500);
   newY += ctlhtml_summary.p_height+20;
   ctlbutton_utrerun._move_window(0, newY, ctlbutton_utrerun.p_width, ctlbutton_utrerun.p_height);
   ctlbutton_utdefects._move_window(ctlbutton_utrerun.p_x+ctlbutton_utrerun.p_width+25, ctlbutton_utrerun.p_y, ctlbutton_utdefects.p_width, ctlbutton_utdefects.p_height);
   newY += ctlbutton_utrerun.p_height+20;
   ctltabs1._move_window(ctltabs1.p_x, newY, clientWidth, (int) ((clientHeight-newY) * 0.6 - ctllabel_defectTrace.p_height));
   ctltree_hierarchy._move_window(0, 0, ctltabs1.p_child.p_width, ctltabs1.p_child.p_height);
   ctltree_failures._move_window(0, 0, ctltabs1.p_child.p_width, ctltabs1.p_child.p_height);
   newY += ctltabs1.p_height+5;
   ctllabel_defectTrace._move_window(ctllabel_defectTrace.p_x, newY, ctllabel_defectTrace.p_width, ctllabel_defectTrace.p_height);
   ctlpicture_defectTrace._move_window(ctlpicture_defectTrace.p_x, newY+50, ctlpicture_defectTrace.p_width, ctlpicture_defectTrace.p_height);
   newY += ctllabel_defectTrace.p_height;
   ctltree_stack._move_window(0, newY, ctltabs1.p_width, clientHeight-newY+_top_height()+_bottom_height());
}

void _tbunittest_form.on_load()
{
   ctltree_hierarchy._utRefreshHierarchyTree();
   _utSetupSummaryControl();
   _utReconcileGUIWithDefects();
}

/**
 * Callback for when the user left-double-clicks an item in the tree control
 */
void ctltree_hierarchy.ENTER,lbutton_double_click()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }

   // Find the entry in the cache
   _str key = _TreeGetUserInfo(index);
   if (!gUnitTestCurrentTests._indexin(key)) {
      //_utDebugSay(key" is not in current test set!");
      return;
   }

   switch (gUnitTestCurrentTests:[key].type) {
      case VS_UNITTEST_ITEM_CLASS:
      case VS_UNITTEST_ITEM_SUITE:
         _utGotoSource(key, "class");
         break;
      case VS_UNITTEST_ITEM_METHOD:
         _utGotoSource(key, "func");
         break;
   }
}

void ctltree_stack.on_change()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }
   // Get info about the current node, and if the node is not selected,
   // select it
   int state, bm1, bm2, flags;
   if (_TreeIsSelected(index)) {
      _TreeSelectLine(index, true);
   }
   // Ensure only one item is selected for now
   int numSelected = _TreeGetNumSelectedItems();
   if (numSelected > 1) {
      return;
   }

   _str caption = _TreeGetCaption(index);
   _str methodName = "", fileName = "", lineNum = "";
   _utParseStackTreeItemCaption(caption, methodName, fileName, lineNum);
   if (methodName == "" || fileName == "" || lineNum == "") {
      return;
   }
   int parentIndex = _TreeGetParentIndex(index);
   if (parentIndex < 0) {
      return;
   }
   _str fqMethodName = _TreeGetUserInfo(parentIndex);
   if (fqMethodName == "") {
      return;
   }

   // update the symbol preview window
   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   cm.file_name = fileName;
   cm.line_no = (int) lineNum;
   cm.member_name = methodName;
   cb_refresh_output_tab(cm, true, true, false, APF_UNIT_TEST);
}

void ctltree_stack.ENTER,lbutton_double_click()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }

   // Parse the caption
   _str caption = _TreeGetCaption(index);
   _str fqMethodName, fileName, foundFile = "";
   typeless lineNum=0;
   //parse caption with "at " fqMethodName " (" fileName ":" lineNum ")";
   _utParseStackTreeItemCaption(caption, fqMethodName, fileName, lineNum);
   if (fqMethodName == "" || fileName == "" || lineNum == "") {
      return;
   }

   _str userInfo = _TreeGetUserInfo(_TreeGetParentIndex(index));
   if (userInfo == "" || gUnitTestCurrentTests:[userInfo].language == VS_UNITTEST_LANGUAGE_JAVA) {
      // Parse the method name into constituent parts
      int dotpos1, dotpos2;
      dotpos1 = lastpos(".", fqMethodName);
      dotpos2 = lastpos(".", fqMethodName, dotpos1-1);
      _str methodName, className, packageName;
      methodName = substr(fqMethodName, dotpos1+1);
      className = substr(fqMethodName, dotpos2+1, dotpos1-dotpos2-1);
      packageName = substr(fqMethodName, 1, dotpos2-1);

      // Try to find the tag so that we can extract the filename from it
      int tagID = _utFindTagInNeighborhood(packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className :+ VS_UNITTEST_HIERSEPARATOR :+ methodName, "func");
      if (tagID >= 0) {
         tag_get_detail2(VS_TAGDETAIL_file_name, tagID, foundFile);
         if (pos(fileName, foundFile) == 0) {
            foundFile = _utFindFileInNeighborhood(fileName);
         }
      }
      else {
         foundFile = _utFindFileInNeighborhood(fileName);
      }

      if (foundFile == "") {
         message("Unable to locate file");
         return;
      }
      push_pos_in_file(foundFile, lineNum, 1);
   }
   else if (gUnitTestCurrentTests:[userInfo].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      int offset = (int) lineNum;
      fileName = _strip_filename(fileName,'E');
      fileName = fileName :+ _macro_ext;
      _str found = slick_path_search(fileName);
      if (found == "") {
         found = _utSlickUnitLocateTestMethod(fqMethodName);
         if (found == "") {
            _message_box(nls("File %s not found", fileName));
            return;
         }
      }
      fileName = found;
      int status = edit(maybe_quote_filename(fileName));
      if (status) {
         return;
      }
      status = st('-f 'offset);
   }
}

void ctltree_failures.on_change,lbutton_up()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }

   // Find the entry in the cache
   _str keys[];
   _str key = _TreeGetUserInfo(index);
   keys[keys._length()] = key;
   _utPopulateStackTree(keys);
   _utPreviewKey(key);
}

void ctltree_failures.rbutton_down()
{
   int index = find_index('_ul2_tree', EVENTTAB_TYPE);
   ctltree_failures.call_event(index, RBUTTON_DOWN, 'E');
   ctltree_failures.call_event(ctltree_failures, LBUTTON_UP);
}

void ctltree_failures.rbutton_up()
{
   ctltree_failures.call_event(ctltree_hierarchy, RBUTTON_UP);
}

void ctltree_failures.ENTER,lbutton_double_click()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }

   // Find the entry in the cache
   _str key = _TreeGetUserInfo(index);
   if (!gUnitTestCurrentTests._indexin(key)) {
      //_utDebugSay(key" is not in current test set!");
      return;
   }

   // If the item is a class or method, jump to the code for it
   if (gUnitTestCurrentTests:[key].type == VS_UNITTEST_ITEM_CLASS) {
      _utGotoSource(key, "class");
   }
   else if (gUnitTestCurrentTests:[key].type == VS_UNITTEST_ITEM_METHOD) {
      _utGotoSource(key, "func");
   }
}

/**
 * Callback for when the user left-clicks an item in the tree control
 */
void ctltree_hierarchy.on_change()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }
   // Get info about the current node, and if the node is not selected,
   // select it
   int state, bm1, bm2, flags;
   _TreeGetInfo(index, state, bm1, bm2, flags);
   if (!_TreeIsSelected(index)) {
      _TreeSelectLine(index, true);
   }
   // Ensure only one item is selected for now
   int numSelected = _TreeGetNumSelectedItems();
   if (numSelected > 1) {
      return;
   }

   _str hashKeys[];
   _utRecursivelyGetUserInfo(index, hashKeys);
   _utPopulateStackTree(hashKeys);
   _utPreviewKey(_TreeGetUserInfo(index));
}

void ctltree_hierarchy.rbutton_down()
{
   int index = find_index('_ul2_tree', EVENTTAB_TYPE);
   ctltree_hierarchy.call_event(index, RBUTTON_DOWN, 'E');
   ctltree_hierarchy.call_event(ctltree_hierarchy, LBUTTON_UP);
}

void ctltree_hierarchy.rbutton_up()
{
   // Get the current tree item
   int index = _TreeCurIndex();
   if (index < 0) {
      return;
   }
   // Get info about the current node, and if the node is not selected,
   // select it
   int state, bm1, bm2, flags;
   _TreeGetInfo(index, state, bm1, bm2, flags);
   if (_TreeIsSelected(index)) {
      _TreeSelectLine(index, true);
   }
   // Ensure only one item is selected for now
   int numSelected = _TreeGetNumSelectedItems();
   if (numSelected > 1) {
      return;
   }

   _utDisplayTreeContextMenu();
}

/**
 * Split the caption of an item in the stack trace tree into its constituent parts
 * 
 * @param caption Caption of the item
 * @param fqMethodName (Output) Will hold the fully-qualified method name
 * @param fileName (Output) Will hold the filename
 * @param lineNum (Output) Will hold the line #
 */
void _utParseStackTreeItemCaption(_str caption, _str &fqMethodName, _str &fileName, _str &lineNum)
{
   parse caption with "at " fqMethodName " (" fileName ":" lineNum ")";
}

static void _utSetupSummaryControl()
{
   int htmlCtl = _find_object("_tbunittest_form.ctlhtml_summary");
   if (htmlCtl <= 0) {
      return;
   }
   _str contents = "";
   _str fontName, fontSize, flags;
   typeless charset;
   parse _default_font(CFG_DIALOG) with fontName','fontSize','flags','charset;
   if (!isinteger(charset)) {
      charset=-1;
   }
   if (!isinteger(fontSize)) {
      fontSize=8;
   }
   if (fontName != "") {
      htmlCtl._minihtml_SetProportionalFont(fontName, charset);
   }
   if (isinteger(fontSize)) {
      htmlCtl._minihtml_SetProportionalFontSize(3, (int) fontSize*10);
   }
}

//
//------- BEGIN JUnit-specific stuff
// 



//
//------- END JUnit-specific stuff
// 

/**
 * Iterate and display each test item in the current test set
 */
void _utDisplayTests()
{
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utDebugSay(i);
   }
}

/**
 * Iterate and display each failure in the current failure set
 */
void _utDisplayFailures()
{
   typeless i;
   int j,k;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentFailures._nextel(i);
      if (i._isempty()) {
         break;
      }
      for (j = 0; j < gUnitTestCurrentFailures:[i]._length(); j++) {
         say("   "gUnitTestCurrentFailures:[i][j].error" ("gUnitTestCurrentFailures:[i][j].type")");
         for (k = 0; k < gUnitTestCurrentFailures:[i][j].failures._length(); k++) {
            say("      "gUnitTestCurrentFailures:[i][j].failures[k].fileName":"gUnitTestCurrentFailures:[i][j].failures[k].lineNum" ("gUnitTestCurrentFailures:[i][j].failures[k].methodName")");
         }
      }
   }
}

/**
 * Recursively extract the indices of a tree node and all its children
 * 
 * @param index Starting index. Only this node and its descendants will be 
 * considered; not this node's siblings
 * @param childIndices (Output) Array which will contain the indices
 * 
 */
static void _utExtractChildIndices2(int index, int (&childIndices)[])
{
   childIndices[childIndices._length()] = index;
}
static void utTreeDoRecursively(int index, typeless cb, typeless &userData)
{
   _TreeDoRecursively(index, cb, userData);
}
void _utExtractChildIndices(int index, int (&childIndices)[])
{
   utTreeDoRecursively(index, _utExtractChildIndices2, childIndices);
}

/**
 * This gets triggered right after debugging has started.
 */
void _utOnDebugStart()
{
   // Nothing going on at the moment
}

/**
 * This gets triggered right after debugging has finished. We basically want
 * the opportunity to parse any JUnit output
 */
void _utOnDebugStop()
{
   if (gDebuggedJUnit) {
      _str fileName = _utCreateJUnitEndTestBatchFile(gUnitTestParseOutputWindowID, gUnitTestParseLineNum);
      concur_command(fileName);
      gDebuggedJUnit = false;
   }
}

/**
 * Handler for when Debug is selected on a method item
 */
_command int utDebugMethodItem()
{
   return(project_unittest_debug());
}

/**
 * Handler for when Run is selected on a method item
 */
_command int utRunMethodItem()
{
   _str key = _TreeGetUserInfo(_TreeCurIndex());
   if (!gUnitTestCurrentTests._indexin(key)) {
      return(0);
   }
   if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_JAVA) {
      return(junit());
   }
   else if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      sunit();
      return(0);
   }
   return(0);
}

/**
 * Handler for when Debug is selected on a class item
 */
_command int utDebugClassItem()
{
   return(project_unittest_debug());
}

/**
 * Handler for when Run is selected on a class item
 */
_command int utRunClassItem()
{
   //return(project_unittest());
   return(utRunMethodItem());
}

/**
 * Handler for when Run is selected on a package item
 */
_command int utRunPackageItem()
{
   //return(project_unittest());
   return(utRunMethodItem());
}

/**
 * Preview the key in the symbol window. The key is supposed to be the user info
 * attached to an item in a tree control which then acts as an index into the hash
 * of current tests
 * 
 * @param key Index into hash of current tests
 */
void _utPreviewKey(_str key)
{
   // Preview the symbol in the Symbol window
   if (!gUnitTestCurrentTests._indexin(key)) {
      return;
   }

   switch (gUnitTestCurrentTests:[key].type) {
      case VS_UNITTEST_ITEM_CLASS:
      case VS_UNITTEST_ITEM_SUITE:
         _utPreviewSymbol(key, "class");
         break;
      case VS_UNITTEST_ITEM_METHOD:
         _utPreviewSymbol(key, "func");
         break;
   }
}

/**
 * Preview the symbol in the symbol window
 * 
 * @param tagName Fully-qualified name of tag in package:class:method format
 * @param tagType Either "func" or "class"
 */
void _utPreviewSymbol(_str tagName, _str tagType)
{
   _str symbolWindowName = "_tbtagwin_form";
   int symbolWindow = _tbIsVisible(symbolWindowName);
   if (!symbolWindow) {
      return;
   }

   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   _str packageName;
   if (gUnitTestCurrentTests:[tagName].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      _utSplitTestItemName(tagName, packageName, cm.class_name, cm.member_name);
      cm.file_name = _utSlickUnitLocateTestMethod(cm.member_name, cm.line_no);
   } else {
      if (tagType == "func" || tagType == "class") {
         int tagID = _utFindTagInNeighborhood(tagName, tagType);
         if (tagID < 0) {
            return;
         }
         _utSplitTestItemName(tagName, packageName, cm.class_name, cm.member_name);
         tag_get_detail2(VS_TAGDETAIL_file_name, tagID, cm.file_name);
         tag_get_detail2(VS_TAGDETAIL_file_line, tagID, cm.line_no);
      }
   }

   if (cm.file_name != "" && (tagType == 'func' || tagType=='class')) {
      cb_refresh_output_tab(cm, true, true, false, APF_UNIT_TEST);
   }
}

/**
 * Display the context menu for a project tree item
 * 
 * @param projectName Name of project
 * @param menuHandle Handle of menu to insert into
 * @param menuPos Where on this menu should we insert the item?
 */
void _utDisplayProjectContextMenu(_str projectName, int menuHandle, int menuPos)
{
   int hTree = _find_object("_tbprojects_form._proj_tooltab_tree", 'N');
   if (_utIsUnitTestEnabledForProject(projectName, GetCurrentConfigName(projectName))) {
      numSelectedItems := hTree._TreeGetNumSelectedItems();
      int menuState;
      if (numSelectedItems == 1) {
         if (projectName == _project_name) {
            menuState = MF_ENABLED;
         }
         else {
            menuState = MF_GRAYED;
         }
      } 
      else {
         menuState = MF_GRAYED;
      }
      int subMenuHandle = _menu_insert(menuHandle, menuPos, MF_SUBMENU | menuState, 'Unit Test', "", "unittest");
      _menu_insert(subMenuHandle, 0, menuState, 'Run...', 'project_unittest');
      _menu_insert(subMenuHandle, 1, menuState, 'Debug...', 'project_unittest_debug');
   }
}

/**
 * Display the context menu for a unittest tree item
 */
void _utDisplayTreeContextMenu()
{
   _str key = _TreeGetUserInfo(_TreeCurIndex());
   // Find the entry in the cache
   if (!gUnitTestTreeCache._indexin(key)) {
      //_utDebugSay(key" is not in cache!");
      return;
   }
   // Locate the unittest menu
   int menuIndex;
   _str menuName = "_unittest_menu";
   menuIndex = find_index(menuName, oi2type(OI_MENU));
   if (!menuIndex) {
      _utDebugSay("unable to locate menu");
      return;
   }
   int menuHandle = p_active_form._menu_load(menuIndex, 'P');

   if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_JAVA) {
      // For JUnit...
      switch (gUnitTestTreeCache:[key].itemType) {
         case VS_UNITTEST_ITEM_METHOD:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run TestMethod', 'utRunMethodItem', '', 'Run this method');
            _menu_insert(menuHandle, 1, MF_ENABLED, 'Debug TestMethod', 'utDebugMethodItem', '', 'Run this method in the debugger');
            break;
         case VS_UNITTEST_ITEM_CLASS:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run TestCase', 'utRunClassItem', '', 'Run this TestCase');
            _menu_insert(menuHandle, 1, MF_ENABLED, 'Debug TestCase', 'utDebugClassItem', '', 'Run this TestCase in the debugger');
            break;
         case VS_UNITTEST_ITEM_PACKAGE:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run Child TestCases', 'utRunPackageItem', '', 'Run all TestCases that are children of this package node');
            break;
         default:
            _utDebugSay(key" is of UNKNOWN type");
            break;
      }
   }
   else if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      // For SlickUnit...
      switch (gUnitTestTreeCache:[key].itemType) {
         case VS_UNITTEST_ITEM_METHOD:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run TestMethod', 'utRunMethodItem', '', 'Run this TestMethod');
            break;
         case VS_UNITTEST_ITEM_CLASS:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run Child TestMethods', 'utRunClassItem', '', 'Run all TestMethods that are children of this node');
            break;
         case VS_UNITTEST_ITEM_PACKAGE:
            _menu_insert(menuHandle, 0, MF_ENABLED, 'Run Child TestMethods', 'utRunPackageItem', '', 'Run all TestMethods that are children of this node');
            break;
         default:
            _utDebugSay(key" is of UNKNOWN type");
            break;
      }
   }

   // Show the menu:
   int x = VSDEFAULT_INITIAL_MENU_OFFSET_X;
   int y = VSDEFAULT_INITIAL_MENU_OFFSET_Y;
   x = mou_last_x('M')-x;
   y = mou_last_y('M')-y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int menuFlags = VPM_LEFTALIGN | VPM_RIGHTBUTTON;
   int status = _menu_show(menuHandle, menuFlags, x, y);
   _menu_destroy(menuHandle);
}

/**
 * Split a test item name, like package:class:method into individual parts
 * 
 * @param fullName Fully-qualified name of item
 * @param packageName (Output)
 * @param className (Output)
 * @param methodName (Output). Optional; if provided, assumes that fullname
 * is the name of a method; if not provided, assumes fullname is a class
 */
void _utSplitTestItemName(_str fullName, _str &packageName, _str &className, _str &methodName=null)
{
   //say("_utSplitTestItemName fullName="fullName);
   if (methodName == null) {
      parse fullName with packageName VS_UNITTEST_HIERSEPARATOR className;
   } else {
      parse fullName with packageName VS_UNITTEST_HIERSEPARATOR className VS_UNITTEST_HIERSEPARATOR methodName;
   }
}

/**
 * Goto the source code for something, like a class or method
 * 
 * @param tagName Name of item, fully-qualified
 * @param tagType Type of item
 */
void _utGotoSource(_str tagName, _str tagType)
{
   _str methodName, className, packageName, fileName, classPkgName;
   int tagID, lineNum;
   if (gUnitTestCurrentTests:[tagName].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      if (tagType == "func") {
         _utSplitTestItemName(tagName, packageName, className, methodName);
         lineNum = 1;
         fileName = _utSlickUnitLocateTestMethod(methodName, lineNum);
         if (fileName == "") {
            message("Tag: "tagName" not found");
            return;
         }
         push_tag_in_file(methodName, fileName, "", "func", lineNum);
      }
   }
   else {
      if (tagType == "func" || tagType == "class") {
         tagID = _utFindTagInNeighborhood(tagName, tagType);
         if (tagID < 0) {
            _utSplitTestItemName(tagName, packageName, className, methodName);

            if(tagID < 0) {
               message("Tag: "tagName" not found");
               return;
            }
         }
         _utSplitTestItemName(tagName, packageName, className, methodName);
         tag_get_detail2(VS_TAGDETAIL_file_name, tagID, fileName);
         tag_get_detail2(VS_TAGDETAIL_file_line, tagID, lineNum);

         if (tagType == "func") {
            // Need to reget these because these might be different from the class passed in.
            // This is do the introspection of junit where the class a test function is found in through
            // introspection is different from the one that it is declared in. 
            // We want the declared version so that we can jump to the source. 
            tag_get_detail2(VS_TAGDETAIL_class_simple, tagID, className);

            classPkgName = className;

            push_tag_in_file(methodName, fileName, classPkgName, "func", lineNum);
         }
         else if (tagType == "class") {
            push_tag_in_file(className, fileName, packageName, "class", lineNum);
         }
      }
   }
}

/**
 * Completely empty the tree
 * 
 * @param hTree Handle to a tree control
 */
void _utEmptyTree()
{
   _TreeDelete(TREE_ROOT_INDEX, "C");
}

/**
 * Adds a single test package item to the tree. Note that gHierarchyLevels
 * must be defined to be > 0 in order for this to have any discernible effect
 * 
 * @param packageName Name of package to add
 * @param force Forces the test to be added to the tree, even if it's already in the cache.
 * This is useful for when we already have a list of tests cached and we just want to redisplay
 * them. Default is false.
 * 
 * @return Index of newly added package item, or -1 on error
 */
int _utAddTestPackageToTree(_str packageName, boolean force=false)
{
   if (!gUnitTestCurrentTests._indexin(packageName)) {
      return -1;
   }

   if (gUnitTestCurrentTests:[packageName].type != VS_UNITTEST_ITEM_PACKAGE) {
      return -1;
   }

   if (gHierarchyLevels < 1) {
      return -1;
   }
   // Check to see if package is already present in the tree. If it isn't,
   // add it in and make this node the new parent
   int parentIndex = TREE_ROOT_INDEX;
   int newIndex;
   if (!gUnitTestTreeCache._indexin(packageName) || force) {
      int bitmap = _utGetIconHandle(gUnitTestCurrentTests:[packageName].type, gUnitTestCurrentTests:[packageName].status);
      newIndex = _TreeAddItem(parentIndex, packageName, TREE_ADD_AS_CHILD, bitmap, bitmap, 1, 0, packageName);
      gUnitTestTreeCache:[packageName].treeIndex = newIndex;
      gUnitTestTreeCache:[packageName].itemType = VS_UNITTEST_ITEM_PACKAGE;
   }
   return gUnitTestTreeCache:[packageName].treeIndex;
}

/**
 * Adds a single test class item to the tree.
 * 
 * @param classPkgName packageName:className of class to add
 * @param force Forces the test to be added to the tree, even if it's already in the cache.
 * This is useful for when we already have a list of tests cached and we just want to redisplay
 * them. Default is false.
 * 
 * @return Index of newly added class item, or -1 on error
 */
int _utAddTestClassToTree(_str classPkgName, boolean force=false)
{
   //say("_utAddTestClassToTree classPkgName="classPkgName);
   if (!gUnitTestCurrentTests._indexin(classPkgName)) {
      classPkgName = VS_UNITTEST_HIERSEPARATOR :+ classPkgName;
      if (!gUnitTestCurrentTests._indexin(classPkgName)) {
         return -1;
      }
   }

   if (gUnitTestCurrentTests:[classPkgName].type != VS_UNITTEST_ITEM_CLASS) {
      return -1;
   }

   _str packageName, className;
   _utSplitTestItemName(classPkgName, packageName, className);
   int newIndex;
   int parentIndex = _utAddTestPackageToTree(packageName);
   int bitmap = _utGetIconHandle(gUnitTestCurrentTests:[classPkgName].type, gUnitTestCurrentTests:[classPkgName].status);
   if (parentIndex < 0) {
      parentIndex = TREE_ROOT_INDEX;
   }
   if (!gUnitTestTreeCache._indexin(classPkgName) || force) {
      if (gHierarchyLevels > 0) {
         newIndex = _TreeAddItem(parentIndex, className, TREE_ADD_AS_CHILD, bitmap, bitmap, 0, 0, classPkgName);
      }
      else {
         newIndex = _TreeAddItem(parentIndex, _utConvertHashKeyToTestName(classPkgName), TREE_ADD_AS_CHILD, bitmap, bitmap, 0, 0, classPkgName);
      }
      gUnitTestTreeCache:[classPkgName].treeIndex = newIndex;
      gUnitTestTreeCache:[classPkgName].itemType = VS_UNITTEST_ITEM_CLASS;
   }
   return gUnitTestTreeCache:[classPkgName].treeIndex;
}

/**
 * Adds a single test method item to the tree
 * 
 * @param index Hash index of test method to add
 * @param force Forces the test to be added to the tree, even if it's already in the cache.
 * This is useful for when we already have a list of tests cached and we just want to redisplay
 * them. Default is false.
 */
int _utAddTestMethodToTree(_str index, boolean force=false)
{
   if (!gUnitTestCurrentTests._indexin(index)) {
      return -1;
   }

   if (gUnitTestCurrentTests:[index].type != VS_UNITTEST_ITEM_METHOD) {
      return -1;
   }

   VS_UNITTEST_INFO test = gUnitTestCurrentTests:[index];
   _str packageName, className, methodName, fqClassName, fqMethodName;
   int i, newIndex, parentIndex;

   _utSplitTestItemName(index, packageName, className, methodName);
   fqClassName = packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
   fqMethodName = index;
   parentIndex = TREE_ROOT_INDEX;

   // Check to see if packageName.className is already present in the tree
   parentIndex = _utAddTestClassToTree(fqClassName, force);
   parentIndex = parentIndex >= 0 ? parentIndex : TREE_ROOT_INDEX;
   // Check to see if packageName.className.methodName is already present in the tree
   if (!gUnitTestTreeCache._indexin(fqMethodName) || force) {
      int bitmap = _utGetIconHandle(gUnitTestCurrentTests:[index].type, gUnitTestCurrentTests:[index].status);
      newIndex = _TreeAddItem(parentIndex, methodName, TREE_ADD_AS_CHILD, bitmap, bitmap, -1, 0, fqMethodName);
      gUnitTestTreeCache:[fqMethodName].treeIndex = newIndex;
      gUnitTestTreeCache:[fqMethodName].itemType = VS_UNITTEST_ITEM_METHOD;
   }
   return gUnitTestTreeCache:[fqMethodName].treeIndex;
}

/**
 * Add a single test item to the tree control
 * 
 * @param index Hash index of test to add
 * @param force Forces the test to be added to the tree, even if it's already in the cache.
 * This is useful for when we already have a list of tests cached and we just want to redisplay
 * them. Default is false.
 * 
 * @return Index of newly added item, or -1 on error
 */
int _utAddTestItemToTree(_str index, boolean force=false)
{
   if (!gUnitTestCurrentTests._indexin(index)) {
      return -1;
   }

   if (gUnitTestCurrentTests:[index].type == VS_UNITTEST_ITEM_METHOD) {
      return _utAddTestMethodToTree(index, force);
   }
   else if (gUnitTestCurrentTests:[index].type == VS_UNITTEST_ITEM_CLASS) {
      return _utAddTestClassToTree(index, force);
   }
   else {
      return -1;
   }
}

/**
 * Repopulate the hierarchy tree with the current tests
 */
void _utRefreshHierarchyTree()
{
   gUnitTestTreeCache._makeempty();
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utAddTestItemToTree(i);
   }
}

/**
 * Recursively sort each subtree starting with the given parent index
 * 
 */
static void _utRecursivelySortTree2(int index)
{
   _TreeSortCaption(index);
}
void _utRecursivelySortTree()
{
   _TreeDoRecursively(TREE_ROOT_INDEX, (typeless)_utRecursivelySortTree2, null);
}

/**
 * Recursively get all the user infos for the selected tree node and all its children
 * 
 * @param treeIndex Starting index
 * @param infos (Output) Will hold all the user infos
 */
static void _utRecursivelyGetUserInfo2(int index, typeless (&infos)[])
{
   typeless info = _TreeGetUserInfo(index);
   infos[infos._length()] = info;
}
void _utRecursivelyGetUserInfo(int treeIndex, typeless (&infos)[])
{
   infos._makeempty();
   _TreeDoRecursively(treeIndex, (typeless)_utRecursivelyGetUserInfo2, infos);
}

/**
 * Populate the hierarchy tree control with the current set of tests
 */
void _utPopulateHierarchyTree()
{
   activate_toolbar("_tbunittest_form", "");
   gUnitTestTreeCache._makeempty();

   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   if (hTree <= 0) {
      _utDebugSay("_utPopulateHierarchyTree: invalid hTree");
      return;
   }
   hTree._utEmptyTree();

   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      hTree._utAddTestItemToTree(i);
   }
   hTree._utRecursivelySortTree();
   _utActivateTestsTab();
}

/**
 * Add a single test item to the hierarchy tree
 * 
 * @param testIndex Fully-qualified test name
 * @param force If true, force the test item to be added even if it already exists.
 * Default is false
 * 
 * @return 0 on success; anything else indicates failure
 */
int _utAddTestItemToHierarchyTree(_str testIndex, boolean force=false)
{
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   if (hTree <= 0) {
      return 1;
   }
   return hTree._utAddTestItemToTree(testIndex, force);
}

/**
 * Add a single test item to the defects tree
 * 
 * @param testIndex Fully-qualified test name
 * @param force If true, force the test item to be added even if it already exists.
 * Default is false
 * 
 * @return 0 on success; anything else indicates failure
 */
int _utAddTestItemToDefectsTree(_str testIndex, boolean force=false)
{
   int hTree = _find_object("_tbunittest_form.ctltree_failures");
   if (hTree <= 0) {
      return 1;
   }
   return hTree._utAddTestItemToTree(testIndex, force);
}

/**
 * Populate the stack trace tree control with the error messages for the fully-qualified
 * test items passed in
 * 
 * @param fqMethodNames An array of test item names that act as indices into
 * gCurrentFailures
 */
void _utPopulateStackTree(_str (&fqMethodNames)[])
{
   int hTree = _find_object("_tbunittest_form.ctltree_stack");
   if (hTree <= 0) {
      _utDebugSay("_utPopulateStackTree: invalid hTree");
      return;
   }
   hTree._utEmptyTree();

   int i, j, k, parentIndex;
   _str fqMethodName, caption;
   for (i = 0; i < fqMethodNames._length(); i++) {
      fqMethodName = fqMethodNames[i];
      for (j = 0; j < gUnitTestCurrentFailures:[fqMethodName]._length(); j++) {
         caption = gUnitTestCurrentFailures:[fqMethodName][j].error;
         int bitmap;
         if (gUnitTestCurrentTests:[fqMethodName].status == VS_UNITTEST_STATUS_FAILED) {
            bitmap = _pic_ut_failure;
         }
         else {
            bitmap = _pic_ut_error;
         }
         parentIndex = hTree._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, bitmap, bitmap, 1, 0, fqMethodName);
         for (k = 0; k < gUnitTestCurrentFailures:[fqMethodName][j].failures._length(); k++) {
            caption = "at "gUnitTestCurrentFailures:[fqMethodName][j].failures[k].methodName" ("gUnitTestCurrentFailures:[fqMethodName][j].failures[k].fileName":"gUnitTestCurrentFailures:[fqMethodName][j].failures[k].lineNum")";
            hTree._TreeAddItem(parentIndex, caption, TREE_ADD_AS_CHILD, _pic_ut_information, _pic_ut_information, -1);
         }
      }
   }
}

/**
 * Populate the failures tree control with the names of tests that had failures or errors
 */
void _utPopulateFailuresTree()
{
   int hTreeFailures = _find_object("_tbunittest_form.ctltree_failures");
   if (hTreeFailures <= 0) {
      _utDebugSay("_utPopulateFailuresTree: invalid hTree");
      return;
   }
   hTreeFailures._utEmptyTree();
   typeless i;
   _str caption, packageName, className, methodName;
   int treeIndex, defects = 0;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (gUnitTestCurrentTests:[i].type != VS_UNITTEST_ITEM_METHOD ||
          gUnitTestCurrentTests:[i].status == VS_UNITTEST_STATUS_PASSED || 
          gUnitTestCurrentTests:[i].status == VS_UNITTEST_STATUS_IGNORE) {
         continue;
      }
      defects++;
      _utSplitTestItemName(i, packageName, className, methodName);
      if (gUnitTestCurrentTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
         caption = methodName" - "packageName""className;
      }
      else {
         caption = methodName" - "packageName"."className;
      }
      int bitmap = _utGetIconHandle(gUnitTestCurrentTests:[i].type, gUnitTestCurrentTests:[i].status);
      treeIndex = hTreeFailures._TreeAddItem(TREE_ROOT_INDEX, caption, TREE_ADD_AS_CHILD, bitmap, bitmap, -1, 0, i);
   }
   if (defects > 0) {
      _utActivateDefectsTab();
   }
}

/**
 * Update the labels for run count, failure count, and error count by counting
 * up the number of each in the hierarchy tree
 */
void _utUpdateAllCountLabels()
{
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   if (hTree <= 0) {
      _utDebugSay("_utUpdateAllCountLabels: Unable to find hierarchy tree");
      return;
   }
   int passed, failed, errors, runs, notRun, ignored;
   hTree._utCountDefectsInSubtree(TREE_ROOT_INDEX, passed, failed, errors, notRun, ignored);
   runs = passed + failed + errors;

   // Using the html control...
   int htmlCtl = _find_object("_tbunittest_form.ctlhtml_summary");
   _str contents = "";
   _str bitmapRoot = get_env("VSROOT") :+ "bitmaps/";
   contents = contents :+ '<img src="file://'bitmapRoot'_ut_run_not_icon.ico"><b>Runs:</b> 'runs'&nbsp;&nbsp;<img src="file://'bitmapRoot'_ut_failure_not_icon.ico"><b>Failures:</b> 'failed'&nbsp;&nbsp;<img src="file://'bitmapRoot'_ut_error_not_icon.ico"><b>Errors:</b> 'errors'<br>';
   contents = contents :+ '<img src="file://'bitmapRoot'_ut_passed_not_icon.ico"><b>Passed:</b> 'passed'&nbsp;&nbsp;&nbsp;&nbsp;<img src="file://'bitmapRoot'_ut_notrun_not_icon.ico"><b>NotRun:</b> 'notRun'&nbsp;&nbsp;&nbsp;&nbsp;<img src="file://'bitmapRoot'_ut_notrun_not_icon.ico"><b>Ignored: </b> 'ignored;
   htmlCtl.p_text = contents;
}

/**
 * Reset the unit test GUI to a blank slate
 */
void _utResetGUI()
{
   _str widgetNames[];
   widgetNames[widgetNames._length()] = "ctltree_stack";
   widgetNames[widgetNames._length()] = "ctltree_failures";
   widgetNames[widgetNames._length()] = "ctltree_hierarchy";
   int i, hWidget;
   for (i = 0; i < widgetNames._length(); i++) {
      hWidget = _find_object("_tbunittest_form."widgetNames[i]);
      if (hWidget > 0) {
         hWidget._utEmptyTree();
      }
   }
   hWidget = _find_object("_tbunittest_form.ctlhtml_summary");
   if (hWidget > 0) {
      hWidget.p_text="";
   }
   _utUpdateProgressBar(0, VS_UNITTEST_BLACK);
   _utUpdateAllCountLabels();
}

/**
 * Reset all the static variables used to keep track of state
 */
void _utResetInternals()
{
   gUnitTestCurrentTests._makeempty();
   gUnitTestTreeCache._makeempty();
   gUnitTestCurrentFailures._makeempty();

   gUnitTestSelectionStack._makeempty();
   gDebuggedJUnit = false;
   gUnitTestOldCmdLine = '';
   gUnitTestParseLineNum=-1;
   gUnitTestParseOutputWindowID=-1;
}

/**
 * Reset everything about unit testing
 */
void _utReset()
{
   _utResetInternals();
   _utResetGUI();
}

/**
 * Pushes the current selection onto the stack so that it can be conveniently
 * restored later on.
 * 
 * @return Handle to the selection which was just pushed
 */
int _utPushSelection()
{
   int oldSelection = _duplicate_selection('');
   if (oldSelection >= 0) {
      gUnitTestSelectionStack[gUnitTestSelectionStack._length()] = oldSelection;
   }
   return oldSelection;
}

/**
 * Pops the previous selection from the stack and makes it active.
 * 
 * @return Handle to the selection which was just popped
 */
int _utPopSelection()
{
   if (gUnitTestSelectionStack._length() > 0) {
      int prevSelection = gUnitTestSelectionStack[gUnitTestSelectionStack._length()-1];
      _show_selection(prevSelection);
      gUnitTestSelectionStack._deleteel(gUnitTestSelectionStack._length()-1);
      return prevSelection;
   }
   return -1;
}

/**
 * Round a double to an int
 */
int _utRound(double value)
{
   // Magical! Typecasting to an int actually rounds!
   return (int) value;
}

/**
 * Attempts to locate a file
 * 
 * @param fileName Relative filename
 * @param tagName Name of tag to help us find this file in the tag DB. 
 * Can be empty, in which case the tagDB is not searched
 * @param searchPaths Array of extra directories to look through. Can be empty
 * in which case only the workspace is searched
 * @param prompt Should the user be prompted if the file can't be found automatically?
 * Default is true
 * 
 * @return Full path to file if it is found; empty string otherwise
 */
_str _utFindFileInNeighborhood(_str fileName, _str tagName="", _str (&searchPaths)[]=null, 
                               boolean prompt=true)
{
   // First look in the active project, workspace, and include path
   _str found_filename = _ProjectWorkspaceFindFile(fileName);
   if (found_filename != '') {
      return found_filename;
   }

   // now try other directories or prompting
   static _str last_dir;
   if (last_dir != '' && file_exists(last_dir:+fileName)) {
      return last_dir:+fileName;
   }
   else if (prompt) {
      // Prompt as a last resort
      _str found_dir=_strip_filename(fileName,"N");
      _str just_filename=_strip_filename(fileName,"P");
      found_filename = _ChooseDirDialog('',found_dir,just_filename);
      if (found_filename=='') {
         return("");
      }
      last_dir=found_filename;
      return found_filename:+just_filename;
   }
   return "";
}

/**
 * Attempts to locate a tag in the current 'neighborhood',
 * which might be the active project or current workspace
 * 
 * @param tagName Name of tag to find. For now, this should be a fully-qualified
 * method name, like packageName:className:methodName
 * @param tagType Should be either 'class' or 'func'
 * 
 * @return tagID if found; negative on failure
 */
int _utFindTagInNeighborhood(_str tagName, _str tagType)
{
   int tagDB = tag_read_db(_GetWorkspaceTagsFilename());
   int i, tagID;
   _str className, methodName, packageName;
   if (tagType == "func") {
      _utSplitTestItemName(tagName, packageName, className, methodName);
      if(packageName != "") {
         tagID = tag_find_tag(methodName, tagType, packageName :+ VS_TAGSEPARATOR_package :+ className);
      } else {
         tagID = tag_find_tag(methodName, tagType, className);
      }
      tag_reset_find_tag();

      // Could not find tag. This might mean that this is a function that is defined in a different
      // class then the one specified. This can happen through the java unit test's introspection which
      // will come back with a function in the derived class but is really defined in the base class.
      // Look up the class that we are given and then find it's parents. Pair each of it's parent's with
      // the method name to see if we come up with a match. Then use that.
      if(tagID < 0) {
         int classTagID = tag_find_tag(className, 'class', packageName);

         // Found the class. Now look for it's parents.
         if(classTagID == 0) {
            VS_TAG_BROWSE_INFO cm;
            _str class_parents,tag_database,lang,file_name                       ;
            int line_no;
            tag_get_detail2(VS_TAGDETAIL_file_name, classTagID, file_name);
            tag_get_detail2(VS_TAGDETAIL_file_line, classTagID, line_no);
            tag_get_detail2(VS_TAGDETAIL_class_parents, classTagID, class_parents);
            tag_get_detail2(VS_TAGDETAIL_language_id, classTagID, lang);
            tag_reset_find_tag();
            _str parents[];
            typeless tag_files = tags_filenamea(lang);
            tag_get_parents_of(className, class_parents, tag_current_db(), tag_files, file_name, 
                           line_no, 0, parents);
            for(i = 0; i < parents._length(); i++) {
               _str classPkgName;

               //  Search for thispackage class method combo
               if(packageName != "") {
                  classPkgName = packageName :+ VS_TAGSEPARATOR_package :+ parents[i];
               } else {
                  classPkgName = parents[i];
               }

               // Found a match. Return. 
               tagID = tag_find_tag(methodName, tagType, classPkgName);
               if(tagID == 0) {
                  tag_reset_find_tag();
                  return tagID;
               }
            }
         }
      }
      tag_reset_find_tag();
      return tagID;
   }
   else if (tagType == "class") {
      _utSplitTestItemName(tagName, packageName, className);
      tagID = tag_find_tag(className, tagType, packageName);
      tag_reset_find_tag();
      return tagID;
   }
   else {
      return BT_RECORD_NOT_FOUND_RC;
   }
}

/**
 * Expand all subtrees that contain tests that either failed or had errors
 * 
 * @param index Node at which to start doing this recursively. Default is TREE_ROOT_INDEX
 * @param extra Extra param not used in this function
 */
static void _utExpandNodeWithDefects(int index, typeless extra=null)
{
   int childIndex = _TreeGetFirstChildIndex(index);
   _str key;
   while (childIndex >= 0) {
      key = _TreeGetUserInfo(childIndex);
      if (gUnitTestCurrentTests:[key].status != VS_UNITTEST_STATUS_PASSED) {
         _TreeSetInfo(index, 1);
         return;
      }
      childIndex = _TreeGetNextSiblingIndex(childIndex);
   }
}
void _utExpandAllNodesWithDefects(int index=TREE_ROOT_INDEX)
{
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   // First collapse them all
   int siblingIndex;
   if (index == TREE_ROOT_INDEX) {
      int firstChildIndex = hTree._TreeGetFirstChildIndex(index);
      if (firstChildIndex < 0) {
         // no children; nothing to do
         return;
      }
      siblingIndex = firstChildIndex;
   }
   else {
      siblingIndex = hTree._TreeGetNextSiblingIndex(index);
   }
   while (siblingIndex >= 0) {
      hTree._TreeSetInfo(siblingIndex, 0);
      siblingIndex = hTree._TreeGetNextSiblingIndex(siblingIndex);
   }
   hTree._TreeDoRecursively(index, _utExpandNodeWithDefects, null);
   hTree._TreeRefresh();
}

/**
 * Set the status of all the tests that are rooted at the given index in the
 * hierarchy tree control.
 * 
 * @param index Starting index. This index and all its children will be set to
 * the given status
 * @param status New status
 */
static void _utMarkStatusOfSubtree2(int index, int status)
{
   _str key = _TreeGetUserInfo(index);
   if (!gUnitTestCurrentTests._indexin(key)) {
      _utDebugSay("_utMarkStatusOfSubtree2: Key "key" not found");
      return;
   }
   gUnitTestCurrentTests:[key].status = status;
}

void _utMarkStatusOfSubtree(int index, int status)
{
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   if (hTree <= 0) {
      // Couldn't get a handle to the tree control!
      _utDebugSay("_utMarkStatusOfSubtree: invalid hTree");
      return;
   }

   hTree.utTreeDoRecursively(index, _utMarkStatusOfSubtree2, status);
}

/**
 * Count the number of successes, failures, and errors at a given node
 * and all its children (recursively)
 * 
 * @param index Starting index of tree
 * @param passed (Output) Will hold # of successes
 * @param failed (Output) Will hold # of failures
 * @param errors (Output) Will hold # of errors
 */
static void _utCountDefectsInSubtree2(int treeIndex, int (&counters):[])
{
   _str key = _TreeGetUserInfo(treeIndex);
   if (!gUnitTestCurrentTests._indexin(key)) {
      return;
   }
   if (gUnitTestCurrentTests:[key].type != VS_UNITTEST_ITEM_METHOD) {
      return;
   }
   switch (gUnitTestCurrentTests:[key].status) {
      case VS_UNITTEST_STATUS_ERROR:
         counters:['errors']++;
         break;
      case VS_UNITTEST_STATUS_FAILED:
         counters:['failed']++;
         break;
      case VS_UNITTEST_STATUS_PASSED:
         counters:['passed']++;
         break;
      case VS_UNITTEST_STATUS_NOTRUN:
         counters:['notrun']++;
         break;
      case VS_UNITTEST_STATUS_IGNORE:
         counters:['ignored']++;
         break;
   }
}
int _utCountDefectsInSubtree(int index, int &passed, int &failed, int &errors, int &notRun, int &ignored)
{
   int counters:[];
   counters:['passed'] = 0;
   counters:['failed'] = 0;
   counters:['errors'] = 0;
   counters:['notrun'] = 0;
   counters:['ignored'] = 0;
   utTreeDoRecursively(index, _utCountDefectsInSubtree2, counters);
   passed = counters:['passed'];
   failed = counters:['failed'];
   errors = counters:['errors'];
   notRun = counters:['notrun'];
   ignored = counters:['ignored'];
   int defects = failed + errors + notRun;
   return defects;
}

/**
 * Update the status of a group (e.g. class or package). Works by recursively
 * counting the # of passed, failures, and errors. If even a single error
 * exists, the new status will be set to VS_UNITTEST_STATUS_ERROR. If even
 * a single failure exists, the new status will be VS_UNITTEST_STATUS_FAILED.
 * Otherwise, the new status is VS_UNITTEST_STATUS_PASSED.
 * 
 * @param treeIndex Index of class or package in tree
 */
void _utUpdateGroupStatus(int treeIndex)
{
   _str key = _TreeGetUserInfo(treeIndex);
   if (!gUnitTestCurrentTests._indexin(key)) {
      _utDebugSay("_utUpdateGroupStatus: "key" not in gCurrentTests");
      return;
   }
   if (gUnitTestCurrentTests:[key].type != VS_UNITTEST_ITEM_CLASS &&
       gUnitTestCurrentTests:[key].type != VS_UNITTEST_ITEM_PACKAGE) {
      _utDebugSay("_utUpdateGroupStatus: "key" not a class or package");
      return;
   }

   int passed, failed, errors, notRun, total, ignored;
   _utCountDefectsInSubtree(treeIndex, passed, failed, errors, notRun, ignored);
   total = passed + failed + errors + notRun + ignored;
   if (errors > 0) {
      _utUpdateTestItemStatus(key, VS_UNITTEST_STATUS_ERROR);
   }
   else if (failed > 0) {
      _utUpdateTestItemStatus(key, VS_UNITTEST_STATUS_FAILED);
   }
   else if (notRun > 0 || total < 1) {
      _utUpdateTestItemStatus(key, VS_UNITTEST_STATUS_NOTRUN);
   }
   else {
      _utUpdateTestItemStatus(key, VS_UNITTEST_STATUS_PASSED);
   }
}

/**
 * Update the status of all the groups (classes or packages) in the
 * hierarchy tree
 */
void _utUpdateAllGroupsStatus()
{
   int hTree = _find_object('_tbunittest_form.ctltree_hierarchy');
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestTreeCache._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (gUnitTestTreeCache:[i].itemType != VS_UNITTEST_ITEM_CLASS &&
          gUnitTestTreeCache:[i].itemType != VS_UNITTEST_ITEM_PACKAGE) {
         continue;
      }
      hTree._utUpdateGroupStatus(gUnitTestTreeCache:[i].treeIndex);
   }
}

/**
 * Update the progress meter with a new value and, optionally, new color
 * 
 * @param percentComplete % of task complete. If negative, progress remains unchanged
 * @param newColor New color. If blank, color remains unchanged
 */
void _utUpdateProgressBar(int percentComplete=-1, int color=-1)
{
   int hWidget = _find_object('_tbunittest_form.ctlgauge_progress');
   if (hWidget <= 0) {
      //_utDebugSay("_utUpdateProgressBar: Unable to get handle to progress gauge");
      return;
   }
   if (percentComplete >= 0) {
      hWidget.p_value = percentComplete;
   }
   if (color >= 0) {
      hWidget.p_forecolor = color;
   }
}

/**
 * Set the status of all tests
 * 
 * @param status New test status
 */
void _utUpdateStatusOfAllTests(int status)
{
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utUpdateTestItemStatus(i, status);
   }
}

/**
 * Searches for unittest-specific errors in the current selection.
 * This was more or less copied and modified from error.e
 * 
 * @param searchOptions Optional parameters to pass to search()
 * 
 * @return status from search()
 */
int _utJUnitSearchForError(_str searchOptions='@M>')
{
   _str pattern='';
   or_re(pattern, _error_javaException2);
   or_re(pattern, _error_javaException3);

   if (pos('-',searchOptions)){
      up();_end_line();
   }

   save_pos(auto p);
   int status = search('^('pattern')',searchOptions'ri');

   return status;
}

/**
 * Searches for unittest-specific exception header in the current selection.
 * This looks something like
 * 1) testHashCode(org.apache.avalon.framework.test.EnumTestCase)java.lang.ArithmeticException: / by zero
 *  
 * This could also look like 
 * 1) testHashCode[5]... 
 * in the case of a parameterized test 
 *  
 * @param searchOptions Optional parameters to pass to search()
 * 
 * @return status from search()
 */
int _utSearchForExceptionHeader(_str searchOptions='@M>')
{
   _str pattern='';
   or_re(pattern, _error_junitExceptionHeader);

   if (pos('-',searchOptions)){
      up();_end_line();
   }

   save_pos(auto p);
   int status = search('^('pattern')',searchOptions'ri');
   if (status == 0) {
      down();_end_line();
   }

   return status;
}

/**
 * Searches for a unittest method in the current selection
 * This looks something like
 * METHOD foo(some.class.in.some.package) .E
 * 
 * @param searchOptions Optional parameters to pass to search()
 * 
 * @return status from search()
 */
int _utSearchForTestMethod(_str searchOptions='@M>')
{
   _str pattern='';
   or_re(pattern, _regex_TestMethod);

   if (pos('-',searchOptions)){
      up();_end_line();
   }

   save_pos(auto p);
   int status = search('^('pattern')',searchOptions'ri');

   return status;
}

/**
 * Parses the last exception header found by _utSearchForExceptionHeader and
 * tries to extract the exception name, class name, and method name
 * 
 * @param exception
 * @param className
 * @param methodName
 */
void _utParseExceptionHeader(_str &exception, _str &className, _str &methodName)
{
   _str match = get_match_text();
   int status = pos(_error_junitExceptionHeader, match, 1, 'ri');
   if (status == 0) {
      return;
   }

   methodName = substr(match, pos('S0'), pos('0'));
   className = substr(match, pos('S1'), pos('1'));
   get_line(exception);
}

/**
 * Parses the last error found by _utSearchForError and tries to extract the
 * filename, line#, and method name.
 * 
 * @param filename (Output)
 * @param line (Output)
 * @param methodName (Output)
 * 
 * @return true if a valid error message was parsed; false otherwise
 */
boolean _utParseError(_str &filename, _str &line, _str &methodName)
{
   _str temp = get_match_text();
   boolean status = pos(_error_javaException2, temp, 1, 'ri') ||
                    pos(_error_javaException3, temp, 1, 'ri');
   if (!status) {
      return false;
   }

   methodName = substr(temp, pos('S0'), pos('0'));
   filename = substr(temp, pos('S1'), pos('1'));
   line = substr(temp, pos('S2'), pos('2'));
   int default_start1 = pos('s1');
   int default_start2 = pos('s2');

   if (substr(filename, 1, 1) != '"') {
      filename = maybe_quote_filename(filename);
   }

   return true;
}

/**
 * Parses the last test method found by _utSearchForTestMethod and tries to
 * extract the methodName, classPkgName, and testOutcome
 * 
 * @param methodName (Output)
 * @param classPkgName (Output)
 * @param testOutcome (Output)
 * 
 * @return true if a valid test method was parsed; false otherwise
 */
boolean _utParseTestMethod(_str &methodName, _str &classPkgName, _str &testOutcome)
{
   _str temp = get_match_text();
   boolean status = (pos(_regex_TestMethod, temp, 1, 'ri') != 0);
   if (!status) {
      return false;
   }

   methodName = substr(temp, pos('S0'), pos('0'));
   classPkgName = substr(temp, pos('S1'), pos('1'));
   testOutcome = substr(temp, pos('S2'), pos('2'));

   return true;
}

/**
 * Command that is run after JUnit batch file is finished running. This is not meant
 * to be run interactively
 */
_command unittest_post_test(_str args='')
{
   if (args == "") {
      popup_imessage("This command is not meant to be called directly by the user");
      return(0);
   }
   typeless outputWindowID, startLine;
   parse args with outputWindowID " " startLine;
   activate_toolbar("_tbunittest_form", "");
   _utParseJUnitOutput(outputWindowID, startLine);
   _utReconcileGUIWithDefects();
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy", 'N');
   if (hTree <= 0) {
      return(0);
   }
   hTree._utRecursivelySortTree();
}

/**
 * Update the GUI to reflect the state of any defects
 */
void _utReconcileGUIWithDefects()
{
   int passed, failed, errors, runs, notRun, ignored;
   int hTree = _find_object('_tbunittest_form.ctltree_hierarchy');
   int defects = hTree._utCountDefectsInSubtree(TREE_ROOT_INDEX, passed, failed, errors, notRun, ignored);
   int total = failed + errors + passed + notRun;
   _utActivateTestsTab();
   if (total < 1) {
      _utUpdateProgressBar(0, VS_UNITTEST_BLACK);
   }
   else if (defects == 0) {
      _utUpdateProgressBar(100, VS_UNITTEST_GREEN);
   }
   else {
      _utUpdateProgressBar(100, VS_UNITTEST_RED);
   }
   _utPopulateFailuresTree();
   _utUpdateAllCountLabels();
   _utExpandAllNodesWithDefects();
}

static void _utPrintNode(int index, typeless &extra)
{
   say(_TreeGetCaption(index));
}

/**
 * Run all the tests that were selected to be run
 * 
 * @param cmdLine Command used to run each test. Necessary for JUnit; can be
 * omitted for SlickUnit
 */
void _utRunAllSelectedTests(_str cmdLine="")
{
   typeless i;
   _str testNames[];
   if (_utCountHashElements(gUnitTestCurrentTests) < 1) {
      message("No tests found");
      return;
   }
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      switch (gUnitTestCurrentTests:[i].type) {
         case VS_UNITTEST_ITEM_CLASS:
         case VS_UNITTEST_ITEM_SUITE:
         case VS_UNITTEST_ITEM_METHOD:
            if (gUnitTestCurrentTests:[i].selected) {
               testNames[testNames._length()] = i;
            }
            break;
         default:
            break;
      }
   }
   if (cmdLine != "" && gUnitTestCurrentTests:[testNames[0]].language == VS_UNITTEST_LANGUAGE_JAVA) {
      _utRunJUnitTestSet(testNames, cmdLine);
   }
   else if (gUnitTestCurrentTests:[testNames[0]].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      _utSlickUnitRunTestSet(testNames);
   }
}

/**
 * Starting at the currently selected node in one of the Unit Test toolbar trees,
 * recurse down and extract all Tests along the way
 */
void _utExtractTestsFromTree()
{
   int treeIndex = _TreeCurIndex();
   if (treeIndex < 0) {
      return;
   }
   int searchIndices[], i;
   _utExtractChildIndices(treeIndex, searchIndices);
   _str key;
   VS_UNITTEST_INFO oldTests:[];
   oldTests = gUnitTestCurrentTests;
   _utResetInternals();
   for (i = 0; i < searchIndices._length(); i++) {
      key = _TreeGetUserInfo(searchIndices[i]);
      if (oldTests:[key].type == VS_UNITTEST_ITEM_CLASS ||
          oldTests:[key].type == VS_UNITTEST_ITEM_SUITE) {
         _utAddClassItemToCurrentTests(key, oldTests:[key].language);
      }
      else if (oldTests:[key].type == VS_UNITTEST_ITEM_METHOD) {
         _utAddMethodItemToCurrentTests(key, oldTests:[key].language);
      }
   }
   // Gonna have to modify this later when we allow multiple selections
   key = _TreeGetUserInfo(treeIndex);
   if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_JAVA) {
      switch (gUnitTestCurrentTests:[key].type) {
         case VS_UNITTEST_ITEM_CLASS:
         case VS_UNITTEST_ITEM_SUITE:
         case VS_UNITTEST_ITEM_METHOD:
            gUnitTestCurrentTests:[key].selected = true;
            break;
         case VS_UNITTEST_ITEM_PACKAGE:
            // If the selected item was a package, we need to recurse and mark
            // classes beneath this node as selected
            for (i = 0; i < searchIndices._length(); i++) {
               key = _TreeGetUserInfo(searchIndices[i]);
               switch (gUnitTestCurrentTests:[key].type) {
                  case VS_UNITTEST_ITEM_CLASS:
                  case VS_UNITTEST_ITEM_SUITE:
                     gUnitTestCurrentTests:[key].selected = true;
                     break;
               }
            }
            break;
      }
   }
   else if (gUnitTestCurrentTests:[key].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      switch (gUnitTestCurrentTests:[key].type) {
         // If the selected item was not a method, we need to recurse and mark
         // methods beneath this node as selected
         case VS_UNITTEST_ITEM_CLASS:
         case VS_UNITTEST_ITEM_SUITE:
         case VS_UNITTEST_ITEM_PACKAGE:
            for (i = 0; i < searchIndices._length(); i++) {
               key = _TreeGetUserInfo(searchIndices[i]);
               switch (gUnitTestCurrentTests:[key].type) {
                  case VS_UNITTEST_ITEM_METHOD:
                     gUnitTestCurrentTests:[key].selected = true;
                     break;
               }
            }
            break;
         case VS_UNITTEST_ITEM_METHOD:
            gUnitTestCurrentTests:[key].selected = true;
            break;
      }
   }
}

/**
 * Starting at the currently selected node in the project tree, recurse down
 * and extract all the TestCases and TestSuites along the way
 */
void _utExtractTestsFromProjectTree()
{
   int treeIndex = _TreeCurIndex();
   if (_projecttbIsWorkspaceFileNode(treeIndex)) {
      _utDebugSay("WorkspaceFile");
      return;
   } 
   else if (_projecttbIsWorkspaceFolderNode(treeIndex)) {
      _utDebugSay("WorkspaceFolder");
      return;
   } 
   else if (_projecttbIsWorkspaceNode(treeIndex)) {
      _utDebugSay("Workspace");
      return;
   }

   gUnitTestCurrentTests._makeempty();
   int searchIndices[], i;
   _str fileNames[], fileName, fullPath;
   _utExtractChildIndices(treeIndex, searchIndices);
   for (i = 0; i < searchIndices._length(); i++) {
      if (!getTreeFile(p_window_id, searchIndices[i], fileName,  fullPath)) {
         fileNames[fileNames._length()] = fullPath;
      }
   }
   if (_utIsJavaProject(_project_name) == 1) {
      _utExtractJUnitTestsForFiles(fileNames);
   }
}

/**
 * Determines if the filename is a C++ source file
 * 
 * @param fileName
 * 
 * @return true if filename is a C++ source file; false otherwise
 */
boolean _utIsCPPSourceFile(_str fileName)
{
   _str extensions[];
   extensions[extensions._length()] = ".cpp";
   extensions[extensions._length()] = ".cxx";
   extensions[extensions._length()] = ".cc";
   int i;
   for (i = 0; i <extensions._length(); i++) {
      if (_utIsSourceFileOfSpecificType(fileName, extensions[i])) {
         return true;
      }
   }

   return false;
}

/**
 * Determines if the filename is a C++ header file
 * 
 * @param fileName
 * 
 * @return true if filename is a C++ header file; false otherwise
 */
boolean _utIsCPPHeaderFile(_str fileName)
{
   _str extensions[];
   extensions[extensions._length()] = ".h";
   extensions[extensions._length()] = ".hpp";
   int i;
   for (i = 0; i <extensions._length(); i++) {
      if (_utIsSourceFileOfSpecificType(fileName, extensions[i])) {
         return true;
      }
   }

   return false;
}

/**
 * Determines if the filename is of a specific type
 * 
 * @param fileName
 * @param type
 * 
 * @return true if filename is of specified type; false otherwise
 */
boolean _utIsSourceFileOfSpecificType(_str fileName, _str type)
{
   _str extension = _get_extension(fileName,  true);
   if (!file_eq(extension,  type)) {
      return false;
   }
   return true;
}

/**
 * Determine if unit testing is enabled for the given project
 * 
 * @param projectName Name of project of interest
 * @param config Name of configuration to use
 * 
 * @return true if unit testing is enabled; false otherwise
 */
boolean _utIsUnitTestEnabledForProject(_str name, _str config)
{
   int status;
   int handle;
   // check that it ends in the proper extension
   _str extension = _get_extension(name, true);
   if (!file_eq(extension, PRJ_FILE_EXT)) {
      return false;
   }
   handle = _ProjectHandle(name);
   if (handle < 0) {
      // We had a problem opening the project
      return false;
   }

   if (config == "") {
      // No config specified? Use the active one
      config = GetCurrentConfigName(name);
   }
   int node = _ProjectGet_TargetNode(handle, "UnitTest", config);
   if (node < 0) {
      return false;
   }
   else {
      return true;
   }
}

/**
 * Determines if the filename & config combo is of a specific type
 * 
 * @param name The name of a project file
 * @param config Name of config to check. If blank (the default), will use the active config
 * for the named project
 * @param type Project type to compare against
 * 
 * @return 0 if project is not of this type, 1 if it is, -1 if there was an error
 */
int _utIsProjectOfSpecificType(_str name, _str config="", _str type="")
{   
   int status;
   int handle;
   // check that it ends in the proper extension
   _str extension = _get_extension(name, true);
   if (!file_eq(extension, PRJ_FILE_EXT)) {
      return -1;
   }
   handle = _xmlcfg_open(name, status, VSXMLCFG_OPEN_REFCOUNT);
   if (handle < 0 || status != 0) {
      // We had a problem opening the project
      return -1;
   }

   if (config == "") {
      // No config specified? Use the active one
      config = GetCurrentConfigName(name);
   }
   _str projectType = _ProjectGet_Type(handle, config);

   // close the file
   _xmlcfg_close(handle);

   if (stricmp(projectType, type) == 0) {
      return 1;
   }

   return 0;
}

/**
 * Split a string into tokens delmited by a common separator. This is
 * in the same spirit as PHP's split() function
 * 
 * @param source The original string
 * @param dest (Output) Hash that will hold all the tokens
 * @param separator The delimiter
 */
void _utSplitString(_str source, _str (&dest)[], _str separator)
{
   dest._makeempty();
   _str token;
   _str remainder = source;
   while (remainder != "") {
      parse remainder with token (separator) remainder;
      dest[dest._length()] = token;
   }
}

/**
 * Join an array of strings into a single string delimited by a common
 * separator. This is in the same spirit as PHP's join() function
 * 
 * @param source The input array of strings to join
 * @param separator The delimiter
 * 
 * @return The resultant joined string
 */
_str _utJoinStrings(_str (&source)[], _str separator)
{
   _str result = "";
   int i;
   int numStrings = source._length();
   for (i = 0; i < numStrings; i++) {
      if (i < (numStrings-1)) {
         result = result :+ source[i] :+ separator;
      }
      else {
         result = result :+ source[i];
      }
   }
   return result;
}

/**
 * Determine if the class identified by the tagID extends the JUnit Test
 * interface
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 * 
 * @param tagID ID of the tag to lookup. This is expected to be a tag for a class
 * @param importsJUnit Does the context of this tag import the JUnit package?
 * 
 * @return A string indicating which JUnit class this class extends, e.g.
 * TestCase or TestSuite. If the class does not extend JUnit, then this will be blank.
 */
_str _utDoesClassExtendJUnit(int tagID, boolean importsJUnit)
{
   int flags;
   _str result='', type = '';
   if (tagID < 0) {
      return result;
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   _str name;
   tag_get_detail2(VS_TAGDETAIL_context_name, tagID, name);

   typeless tagDetail;
   tag_get_detail2(VS_TAGDETAIL_context_class, tagID, tagDetail);
   if (pos(VS_TAGSEPARATOR_package, tagDetail) > 0) {
      // This indicates a nested class, which is not counted
      return result;
   }

   tag_get_detail2(VS_TAGDETAIL_context_flags, tagID, flags);
   tag_get_detail2(VS_TAGDETAIL_context_type, tagID, type);
   // Ignore abstract classes or interfaces
   if(flags & VS_TAGFLAG_abstract || type == 'interface') {
      return result;
   }

   _str class_parents, file_name;
   int line_no;
   tag_get_detail2(VS_TAGDETAIL_context_parents, tagID, class_parents);
   tag_get_detail2(VS_TAGDETAIL_context_file, tagID, file_name);
   tag_get_detail2(VS_TAGDETAIL_context_start_linenum, tagID, line_no);

   _str parents[];
   typeless tag_files = tags_filenamea(p_LangId);
   tag_get_parents_of(name, class_parents,"", tag_files,
                          file_name, line_no, 0, parents);

   int i;
   _str longFormCase = VS_UNITTEST_JUNIT_PKGNAME :+ VS_TAGSEPARATOR_package :+ VS_UNITTEST_JUNIT_CASE;
   _str longFormSuite = VS_UNITTEST_JUNIT_PKGNAME :+ VS_TAGSEPARATOR_package :+ VS_UNITTEST_JUNIT_SUITE;
   _str shortFormCase = VS_UNITTEST_JUNIT_CASE;
   _str shortFormSuite = VS_UNITTEST_JUNIT_SUITE;
   for (i = 0; i < parents._length(); i++) {
      if ((parents[i] == shortFormCase /*&& importsJUnit*/) || parents[i] == longFormCase) {
         result = VS_UNITTEST_JUNIT_CASE;
         break;
      }
      else if ((parents[i] == shortFormSuite /*&& importsJUnit*/) || parents[i] == longFormSuite) {
         result = VS_UNITTEST_JUNIT_SUITE;
         break;
      }
   }

   return result;
}

/**
 * Determine if the class identified by the fully-qualified class name extends the JUnit Test
 * interface
 *
 * @param fqClassName Fully-qualified class name (i.e. package_name:class_name)
 * @boolean importsJUnit Does the context import the JUnit package?
 * 
 * @return A string indicating which JUnit class this class extends, e.g.
 * TestCase or TestSuite. If the class does not extend JUnit, then this will be blank.
 */
_str _utDoesClassExtendJUnit2(_str fqClassName, boolean importsJUnit)
{
   _str packageName, className;

   _utSplitTestItemName(fqClassName, packageName, className);
   if (className == "") {
      className = packageName;
      packageName = "";
   }
   int tagID = _utLocateNamedClass(className, packageName);
   return _utDoesClassExtendJUnit(tagID, importsJUnit);
}

/**
 * Get the ID of the named class belonging to a particular package
 * 
 * @param className Name of class
 * @param packageName Name of package class belongs to; default = "*" (for any package)
 * 
 * @return The ID of the tag, or a value < 0 if the tag could not be found in the 
 * current context
 */
int _utLocateNamedClass(_str className, _str packageName = "*")
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Create a list of all the tagIDs that match this class name
   int tagIDs[];
   tagID := tag_find_context_iterator(className, true, true);
   if (tagID > 0) tagIDs[tagIDs._length()] = tagID;
   tagID = tag_next_context_iterator(className, tagID, true, true);
   while (tagID >= 0) {
      tagIDs[tagIDs._length()] = tagID;
      tagID = tag_next_context_iterator(className, tagID, true, true);
   }

   // Now search through those tagIDs till we find one that is contained in 
   // the specified packageName
   typeless tagDetail, innerName="", outerName="";
   int i;
   for (i = 0; i < tagIDs._length(); i++) {
      tagID = tagIDs[i];
      tag_get_detail2(VS_TAGDETAIL_context_type, tagID, tagDetail);
      if (tagDetail == "class") {
         if (packageName == "*") {
            // User doesn't care what package this class is in
            return tagID;
         }
         tag_get_detail2(VS_TAGDETAIL_context_class, tagID, tagDetail);
         tag_split_class_name(tagDetail, innerName, outerName);
         if (innerName == packageName) {
            return tagID;
         }
      }
   }

   return BT_RECORD_NOT_FOUND_RC;
}

/**
 * Get the ID of the named method belonging to a particular class in a particular package
 * 
 * @param methodName Name of method
 * @param className Name of containing class; default = '*' for any class
 * @param packageName Name of containing package; default = '*' for any package
 * 
 * @return The ID of the tag, or a value < 0 if the tag could not be found in the current
 * context
 */
int _utLocateNamedMethod(_str methodName, _str className = "*", _str packageName = "*")
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // Compile a list of all the methods with this name
   int tagIDs[];
   tagID := tag_find_context_iterator(methodName, true, true);
   if (tagID > 0) tagIDs[tagIDs._length()] = tagID;
   tagID = tag_next_context_iterator(methodName, tagID, true, true);
   while (tagID >= 0) {
      tagIDs[tagIDs._length()] = tagID;
      tagID = tag_next_context_iterator(methodName, tagID, true, true);
   }

   // Search through those tagIDs to find a function that is in the specified class
   // and package
   typeless tagDetail;
   int classTagID;
   int i;
   for (i = 0; i < tagIDs._length(); i++) {
      tagID = tagIDs[i];
      tag_get_detail2(VS_TAGDETAIL_context_type, tagID, tagDetail);
      if (tagDetail == "func") {
         if (className == "*" && packageName == "*") {
            return tagID;
         }
         classTagID = _utLocateNamedClass(className, packageName);
         if (classTagID >= 0) {
            return tagID;
         }
      }
   }

   return BT_RECORD_NOT_FOUND_RC;
}

/**
 * Get the ID of the named test item by figuring out if the item is a class or
 * method and then returning the tagID of that method or class via 
 * _utLocateNamedMethod or _utLocatedNamedClass
 * 
 * @param testItem Fully-qualified name of item, like package.class.method or
 * package:class:method
 * @param itemType (Output) Output param that will tell you if the item was
 * determined to be a class or a method
 * 
 * @return tagID if item was found; <0 if there was an error
 */
int _utLocateNamedItemInWorkspace(_str testItem, int &itemType)
{
   _str hashKey, packageName, className, methodName;
   int tagID;

   // First assume the item is a class name
   if (pos(VS_UNITTEST_HIERSEPARATOR, testItem) > 0) {
      hashKey = testItem;
   }
   else {
      hashKey = _utConvertTestNameToHashKey(VS_UNITTEST_ITEM_CLASS, testItem);
   }
   
   _utSplitTestItemName(hashKey, packageName, className, methodName);
   tagID = _utFindTagInNeighborhood(hashKey, "class");
   if (tagID >= 0) {
      // We want to figure out if this class is a TestSuite or a TestCase
      _str fileName;
      tag_get_detail2(VS_TAGDETAIL_file_name, tagID, fileName);
      _str tagTypes:[];
      typeless bins;
      tagTypes:["import"] = '';
      _utCollateTagsForFile(tagTypes, bins, fileName);
      boolean importsJUnit = true;//_utImportsJUnitPackage(bins:['import']);
      _str classPkgName = packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
      hashKey = hashKey :+ VS_UNITTEST_HIERSEPARATOR :+ "suite";
      tagID = _utFindTagInNeighborhood(hashKey, "func");
      if (tagID >= 0) {
         itemType = VS_UNITTEST_ITEM_SUITE;
      }
      else {
         itemType = VS_UNITTEST_ITEM_CLASS;
      }
      return tagID;
   }

   if (pos(VS_UNITTEST_HIERSEPARATOR, testItem) > 0) {
      hashKey = testItem;
   }
   else {
      hashKey = _utConvertTestNameToHashKey(VS_UNITTEST_ITEM_METHOD, testItem);
   }
   _utSplitTestItemName(hashKey, packageName, className, methodName);
   tagID = _utFindTagInNeighborhood(hashKey, "func");
   if (tagID >= 0) {    
      itemType = VS_UNITTEST_ITEM_METHOD;
      return tagID;
   }

   itemType = VS_UNITTEST_ITEM_UNKNOWN;
   return BT_RECORD_NOT_FOUND_RC;
}

/**
 * Converts a fully-qualified test name, like org.apache.avalon.framework.test.EnumTestCase,
 * to a hash key, like org.apache.avalon.framework.test:EnumTestCase
 * 
 * @param itemType One of the VS_UNITTEST_ITEM_ constants
 * @param itemName Name of test item
 * 
 * @return Hash key on success; empty string on failure
 */
_str _utConvertTestNameToHashKey(int itemType, _str itemName)
{
   _str hashKey = "";
   int lastDot, nextLastDot;
   switch (itemType) {
      case VS_UNITTEST_ITEM_PACKAGE:
         hashKey = itemName;
         break;
      case VS_UNITTEST_ITEM_CLASS:
      case VS_UNITTEST_ITEM_SUITE:
         lastDot = lastpos('.', itemName);
         if (lastDot > 0) {            
            hashKey = substr(itemName, 1, lastDot-1) :+ VS_UNITTEST_HIERSEPARATOR :+ 
               substr(itemName, lastDot+1);
         }
         break;
      case VS_UNITTEST_ITEM_METHOD:
         lastDot = lastpos('.', itemName);
         if (lastDot > 0) {
            nextLastDot = lastpos('.', itemName, lastDot-1);
            if (nextLastDot > 0) {
               hashKey = substr(itemName, 1, nextLastDot-1) :+ VS_UNITTEST_HIERSEPARATOR :+ 
                  substr(itemName, nextLastDot+1, lastDot-nextLastDot-1) :+ VS_UNITTEST_HIERSEPARATOR :+
                  substr(itemName, lastDot+1);
            }
         }
         break;
      default:
         break;
   }
   return hashKey;
}

/**
 * Converts a hash key into a fully-qualified test item
 * 
 * @param hashKey
 *
 * @return hashKey converted into a test name
 */
_str _utConvertHashKeyToTestName(_str itemName)
{
   _str res = stranslate(itemName, '.', VS_UNITTEST_HIERSEPARATOR);
   return stranslate(res, '.', VS_TAGSEPARATOR_package);
}

/**
 * Pares/keeps elements with value = key from the input hash
 * 
 * @param inputHash
 * @param outputHash (Output)
 * @param key The value to match
 * @param option If 'P', elements matching key are removed; if 'K' elements that
 * match key are kept, if anything else, nothing happens and the output will be empty
 */
void _utPareFromHash(typeless (&inputHash):[], typeless (&outputHash):[], typeless key, _str option='P')
{
   outputHash._makeempty();
   typeless i;
   for (i._makeempty(); ; ) {
      inputHash._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (option == 'P' && inputHash:[i] != key) {
         outputHash:[i] = inputHash:[i];
      }
      else if (option == 'K' && inputHash:[i] == key) {
         outputHash:[i] = inputHash:[i];
      }
   }
}

/**
 * Add a method item to the current test set.
 * 
 * @param fqMethodName packageName:className:methodName
 * @param language What language is the test item written in? Default is
 * VS_UNITTEST_LANGUAGE_JAVA
 */
void _utAddMethodItemToCurrentTests(_str fqMethodName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   if (!gUnitTestCurrentTests._indexin(fqMethodName)) {
      _utInitUnitTestInfo(gUnitTestCurrentTests:[fqMethodName], language);
      gUnitTestCurrentTests:[fqMethodName].type = VS_UNITTEST_ITEM_METHOD;
      _str methodName, className, packageName;
      _utSplitTestItemName(fqMethodName, packageName, className, methodName);
      _utAddClassItemToCurrentTests(packageName :+ VS_UNITTEST_HIERSEPARATOR className, language);
   }
}

/**
 * Add a class item to the current test set.
 * 
 * @param classPkgName packageName:className
 * @param language What language is the test item written in? Default is
 * VS_UNITTEST_LANGUAGE_JAVA
 */
void _utAddClassItemToCurrentTests(_str classPkgName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   if (!gUnitTestCurrentTests._indexin(classPkgName)) {
      _utInitUnitTestInfo(gUnitTestCurrentTests:[classPkgName], language);
      gUnitTestCurrentTests:[classPkgName].type = VS_UNITTEST_ITEM_CLASS;
      _str className, packageName;
      _utSplitTestItemName(classPkgName, packageName, className);
      _utAddPackageItemToCurrentTests(packageName, language);
   }
}

/**
 * Add a suite item to the current test set
 *
 * @param classPkgName packageName:className
 * @param language What language is the test item written in? Default is
 * VS_UNITTEST_LANGUAGE_JAVA
 */
void _utAddSuiteItemToCurrentTests(_str classPkgName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   if (!gUnitTestCurrentTests._indexin(classPkgName)) {
      _utInitUnitTestInfo(gUnitTestCurrentTests:[classPkgName], language);
      gUnitTestCurrentTests:[classPkgName].type = VS_UNITTEST_ITEM_SUITE;
      _str className, packageName;
      _utSplitTestItemName(classPkgName, packageName, className);
      _utAddPackageItemToCurrentTests(packageName, language);
   }
}

/**
 * Add a package item to the current test set.
 * 
 * @param packageName Name of package
 * @param language What language is the test item written in? Default is
 * VS_UNITTEST_LANGUAGE_JAVA
 */
void _utAddPackageItemToCurrentTests(_str packageName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   if (!gUnitTestCurrentTests._indexin(packageName)) {
      _utInitUnitTestInfo(gUnitTestCurrentTests:[packageName], language);
      gUnitTestCurrentTests:[packageName].type = VS_UNITTEST_ITEM_PACKAGE;
   }
}

/**
 * Add an item of a specified type to the current test set
 * 
 * @param itemType One of the VS_UNITTEST_ITEM_ constants
 * @param itemName Fully-qualified name of item
 * @param language What language is the test item written in? Default is
 * VS_UNITTEST_LANGUAGE_JAVA
 */
void _utAddTestItemToCurrentTests(int itemType, _str itemName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   switch (itemType) {
      case VS_UNITTEST_ITEM_METHOD:
         _utAddMethodItemToCurrentTests(itemName, language);
         break;
      case VS_UNITTEST_ITEM_CLASS:
         _utAddClassItemToCurrentTests(itemName, language);
         break;
      case VS_UNITTEST_ITEM_SUITE:
         _utAddSuiteItemToCurrentTests(itemName, language);
         break;
      case VS_UNITTEST_ITEM_PACKAGE:
         _utAddPackageItemToCurrentTests(itemName, language);
         break;
      default:
         break;
   }
}

/**
 * Add an item of an unknown type to the current test set. Essentially we try to 
 * determine if the item is a method and if it is, add it as a method. Otherwise,
 * add it as a class
 * 
 * @param itemName Fully-qualified name in package.class.method format
 * @param language Optional. Defaults to VS_UNITTEST_LANGUAGE_JAVA
 * 
 * @return The hash key that was added; empty string indicates an error
 */
_str _utAddUnknownItemToCurrentTests(_str itemName, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   int tagID, itemType = VS_UNITTEST_ITEM_UNKNOWN;
   tagID = _utLocateNamedItemInWorkspace(itemName, itemType);
   if (itemType == VS_UNITTEST_ITEM_UNKNOWN) {
      // Take a chance and assume the specified test is a TestCase class
      itemType = VS_UNITTEST_ITEM_CLASS;
   }
   _str hashKey;
   if (pos(VS_UNITTEST_HIERSEPARATOR, itemName) > 0) {
      hashKey = itemName;
   }
   else {
      hashKey = _utConvertTestNameToHashKey(itemType, itemName);
   }
   switch (itemType) {
      case VS_UNITTEST_ITEM_METHOD:
         _utAddMethodItemToCurrentTests(hashKey, language);
         break;
      case VS_UNITTEST_ITEM_SUITE:
         _utAddSuiteItemToCurrentTests(hashKey, language);
         break;
      default:
         _utAddClassItemToCurrentTests(hashKey, language);
         break;
   }
   return hashKey;
}

/**
 * Initialize a VS_UNITTEST_INFO structure to useful defaults. Optionally
 * copies over relevant information from the gTagCache
 * 
 * @param info (Output) A VS_UNITTEST_INFO structure to initialize
 * @param language What language is this test written in? Default is VS_UNITTEST_LANGUAGE_JAVA
 * 
 * @return 0 on success, anything else indicates failure. The only time it would fail
 * is if a tagID is provided but no corresponding entry exists in the gTagCache
 */
int _utInitUnitTestInfo(VS_UNITTEST_INFO &info, int language=VS_UNITTEST_LANGUAGE_JAVA)
{
   info.fileName = "";
   info.projectName = "";
   info.status = VS_UNITTEST_STATUS_NOTRUN;
   info.type = VS_UNITTEST_ITEM_UNKNOWN;
   info.selected = false;
   info.language = language;

   return 0;
}

/**
 * Collates the tags for a given file and bins them into category-specific
 * hashes
 * 
 * @param tagTypes Hash of bin names
 * @param bins (Output) Hashtable of hashtables, like bins:["class"]:["class1"]
 * @param fileName Name of file
 */
void _utCollateTagsForFile(_str (&tagTypes):[], typeless (&bins):[], _str fileName)
{
   int tempViewID, origViewID;
   _str loadOptions = "";
   boolean exists = false;
   int status = _open_temp_view(fileName, tempViewID, origViewID, loadOptions, exists, false, true);
   if (status) {
      _utDebugSay("_utCollateTagsForFile: Unable to open temp view for "fileName);
      return;
   }

   _utCollateTags(tagTypes, bins);
   _delete_temp_view(tempViewID);
   activate_window((int) origViewID);
}

/**
 * Collates the tags from a tagging context and bins them into category-specific
 * hashes
 * 
 * @param tagTypes Hash of bin names
 * @param bins (Output) Hashtable of hashtables, like bins:["class"]:["class1"]
 */
void _utCollateTags(_str (&tagTypes):[], typeless (&bins):[])
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   bins._makeempty();
   int numContextTags = tag_get_num_of_context();

   int tagID, startLine, startPos, scopeLine, scopePos, endLine, endPos, tagFlags;
   _str tagName, tagType, fileName, classPkgName, arguments, returnType, packageName, className;
   _str pkg = '';

   for (tagID = 0; tagID <= numContextTags; tagID++) {
      packageName = '';
      if (tag_get_context(tagID, tagName, tagType, fileName, startLine, startPos, scopeLine, scopePos,
                      endLine, endPos, classPkgName, tagFlags, arguments, returnType) != 0) {
         continue;
      }
      if (tagType == 'package') {
         // this may come through as 2 part now...
         pkg = classPkgName == '' ? tagName : classPkgName :+ VS_TAGSEPARATOR_package :+ tagName; 
      }
      if (tagTypes._indexin(tagType)) {
         int class_name_index = lastpos(VS_TAGSEPARATOR_package,classPkgName);
         if (classPkgName == pkg) {
            packageName = classPkgName;
            className = "";
         } else if (class_name_index > 0 && length(classPkgName > class_name_index + 1)) {
            packageName = substr(classPkgName,1,class_name_index-1);
            className = substr(classPkgName,class_name_index+1);
         } else {
            packageName = "";
            className = classPkgName;
         }
         if (tagType == 'func' || tagType == 'annotation') {
            if (className == "") {
               if (packageName == pkg){
                  bins:[tagType]:[pkg :+ VS_UNITTEST_HIERSEPARATOR :+ _strip_filename(fileName, 'PE') :+ VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
               } else if (packageName != "") {
                  bins:[tagType]:[VS_UNITTEST_HIERSEPARATOR :+ packageName :+ VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
               } else{
                  //really nothing to go on here...
                  bins:[tagType]:[VS_UNITTEST_HIERSEPARATOR :+ className :+ VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
               }
            }
            else {
               bins:[tagType]:[packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className :+ VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
            }
         } 
         else if (tagType == "class") {
            if (packageName == "") {
               bins:[tagType]:[VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
            }
            else {
               bins:[tagType]:[packageName :+ VS_UNITTEST_HIERSEPARATOR :+ tagName] = tagID;
            }
         }
         else {
            // garbage
            bins:[tagType]:[tagName] = tagID;
         }
      }
   }
}

/**
 *  Returns the # of elements in the input hash. I can't believe this isn't already
 * provided...
 * 
 * @param inputHash
 * 
 * @return # of elements in the input
 */
int _utCountHashElements(typeless (&inputHash):[])
{
   int numElements = 0;
   typeless i;
   for (i._makeempty(); ; ) {
      inputHash._nextel(i);
      if (i._isempty()) {
         break;
      }
      numElements++;
   }

   return numElements;
}

/**
 * Debug function. Prints information about each test
 * 
 * @param tests Array of VS_UNITTEST_INFO
 */
void _utSayAllTests(VS_UNITTEST_INFO (&tests):[])
{
   typeless i;
   _str packageName, className, methodName;
   for (i._makeempty(); ; ) {
      tests._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utSplitTestItemName(i, packageName, className, methodName);
      switch (tests:[i].type) {
         case VS_UNITTEST_ITEM_METHOD:
            say("METHOD: PKG="packageName", CLASS="className", METHOD="methodName);
            break;
         case VS_UNITTEST_ITEM_CLASS:
            say("CLASS: PKG="packageName", CLASS="className);
            break;
         case VS_UNITTEST_ITEM_PACKAGE:
            say("PKG: PKG="packageName);
            break;
      }
   }
}

/**
 * Return the current set of tests for external use. This should only be used for
 * testing purposes
 * 
 * @param output (Output) Holds gCurrentTests upon return
 */
void _utGetCurrentTests(VS_UNITTEST_INFO (&output):[])
{
   output = gUnitTestCurrentTests;
}

/**
 * Retrieve the handle to the icon for the specified item and status
 *
 * @param item One of the VS_UNITTEST_ITEM_ constants
 * @param status One of the VS_UNITTEST_STATUS_ constants
 * 
 * @return Handle to the icon on success; <0 on error
 */
int _utGetIconHandle(int item, int status)
{
   if (item < 0 || status < 0) {
      return -1;
   }

   if (item >= gUnitTestIconMatrix._length()) {
      return -1;
   }
   if (status >= gUnitTestIconMatrix[item]._length()) {
      return -1;
   }

   return gUnitTestIconMatrix[item][status];
}

/**
 * Update the status field for a given test item. This will change
 * the member and also update the GUI accordingly
 *
 * @param index Index of item within gCurrentTests
 * @param status New status
 */
void _utUpdateTestItemStatus(_str index, int status)
{
   if (!gUnitTestCurrentTests._indexin(index)) {
      return;
   }
   gUnitTestCurrentTests:[index].status = status;
   if (!gUnitTestTreeCache._indexin(index)) {
      return;
   }
   int showChildren, bm1, bm2, moreFlags, lineNumber;
   int treeIndex = gUnitTestTreeCache:[index].treeIndex;
   _TreeGetInfo(treeIndex, showChildren, bm1, bm2, moreFlags, lineNumber);
   int bitmap = _utGetIconHandle(gUnitTestCurrentTests:[index].type, gUnitTestCurrentTests:[index].status);
   if (status == VS_UNITTEST_STATUS_IGNORE) {
      moreFlags = moreFlags | TREENODE_GRAYTEXT;
   }
   if (bitmap >= 0) {
      _TreeSetInfo(treeIndex, showChildren, bitmap, bitmap, moreFlags);
   }
}

/* 
   We may not need this, but this code gaurentees that globals start
   and a default state.
*/
definit() {
   if (arg(1):!='L') {
      _utReset();
   }
}

/**
 * This is called when the editor is closed
 */
/*
void _exit_unittest()
{
   _utReset();
}*/

/**
 * This is called when the workspace is closed
 */
void _wkspace_close_unittest()
{
   _utReset();
}

_command test_unittest()
{
   return(_project_command2('Foo', false, true, 0, false, 'go', ''));
}

/**
 * Position the cursor for debugging, so that we can do a run-to-cursor
 * and it will go to a sensible location
 * 
 * @param hashKey Test name
 * 
 * @return 0 on success, anything else indicates failure
 */
int _utPositionCursorForDebugging(_str hashKey)
{
   if (!gUnitTestCurrentTests._indexin(hashKey)) {
      return DEBUG_BREAKPOINT_NOT_FOUND_RC;
   }

   _str keyPackage, keyClass, keyMethod;
   _utSplitTestItemName(hashKey, keyPackage, keyClass, keyMethod);
   int numBreakPoints = dbg_get_num_breakpoints();
   int i, lineNum, count;
   _str className, threadName, methodName, fileName, address, condition;
   boolean enabled;
   for (i = 1; i <= numBreakPoints; i++) {
      // See if we have a breakpoint somewhere in this scope
      dbg_get_breakpoint(i, count, condition, threadName, className, methodName,
                         fileName, lineNum, enabled, address);
      if (gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_CLASS ||
          gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_SUITE) {
         if (className == keyPackage"."keyClass) {
            push_pos_in_file(fileName, lineNum, 1);
            return 0;
         }
      }
      else if (gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_METHOD) {
         if (className"."methodName == keyPackage"."keyClass"."keyMethod) {
            push_pos_in_file(fileName, lineNum, 1);
         }
         return 0;
      }
      else {
         // Get out of this loop
         break;
      }
   }

   int tagID, status, tagFlags;
   _str tagName, typeName;
   // If we got this far, then we could find no breakpoint in the relevant scope.
   if (gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_METHOD) {
      // So if this is a method, just put the cursor on the first line of that method
      _utGotoSource(hashKey, "func");
      return 0;
   }
   else if (gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_CLASS) {
      // If this is a TestCase find the first test method in this class and put 
      // the cursor on the first line of that method
      tag_read_db(_GetWorkspaceTagsFilename());
      status = tag_find_in_class(keyPackage :+ VS_TAGSEPARATOR_package :+ keyClass);
      while (status == 0) {
         tag_get_info(tagName, typeName, fileName, lineNum, className, tagFlags);
         if (typeName == "func" && substr(tagName, 1, 4) == "test") {
            push_pos_in_file(fileName, lineNum, 1);
            tag_reset_find_in_class();
            return 0;
         }
         status = tag_next_in_class();
      }
      tag_reset_find_in_class();
   }
   else if (gUnitTestCurrentTests:[hashKey].type == VS_UNITTEST_ITEM_SUITE) {
      // If this is a TestSuite find the suite() method and start debugging there
      tagID = _utFindTagInNeighborhood(keyPackage :+ VS_UNITTEST_HIERSEPARATOR :+ keyClass :+ "suite", "func");
      if (tagID >= 0) {
         tag_get_detail2(VS_TAGDETAIL_file_name, tagID, fileName);
         tag_get_detail2(VS_TAGDETAIL_file_line, tagID, lineNum);
         push_pos_in_file(fileName, lineNum, 1);
         return 0;
      }
   }

   return DEBUG_BREAKPOINT_NOT_FOUND_RC;
}

/**
 * This command starts debugging a unit test. It can be triggered from
 * different contexts: the tests tree, the defects tree, the project tree,
 * or the command line. If it is triggered from a tree control, the selected
 * item is assumed to the the test of interest. If triggered from the command line,
 * the argument given to the command is assumed to be the name of the test in
 * package.class.method format. If no argument is given, the selected item in
 * the project tree is used as the test of interest.
 * 
 * @param key Optional. Specifies a fully-qualified test class/suite or method
 *
 * @return The return code from debug-run-to-cursor
 */
_command int project_unittest_debug,utd,unittest_debug(_str key="")
{
   return(junit_debug(key));
}

/**
 * Prompt the user for the name of a unit test by presenting a list of all tests
 * found
 */
static _str select_main_callback(int sl_event,_str &result,_str info)
{
   return('');
}
_str _utHelpFindTest()
{
   _str testNames[];
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      switch (gUnitTestCurrentTests:[i].type) {
         case VS_UNITTEST_ITEM_CLASS:
         case VS_UNITTEST_ITEM_METHOD:
         case VS_UNITTEST_ITEM_SUITE:
            testNames[testNames._length()] = i;
            break;
         default:
            break;
      }
   }

   _str testName = "";
   if (testNames._length() == 0) {
      _message_box("No tests found! Please create a TestCase");
   }
   else if (testNames._length() == 1) {
      testName = testNames[0];
   }
   else {
      testName = show('_sellist_form -mdi -modal -reinit', 'Select Test', SL_SELECTCLINE, testNames, '', 
                      '',                     // help item name
                      '',                     // font
                      select_main_callback,   // Call back function
                      '',                     // Item list separator
                      'select_main_class'     // retrieve form name
                      );
   }
   return testName;
}

/**
 * Convenient way to start running all testcases in the tests tree which have
 * defects.
 */
_command int ut_defects,unittest_defects()
{
   typeless i;
   i._makeempty();
   gUnitTestCurrentTests._nextel(i);
   if (i._isempty()) {
      message("No tests found");
      return(0);
   }
   if (gUnitTestCurrentTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      sunit("-defects");
      return(0);
   }
   else {
      return(junit("-defects"));   
   }
}

/**
 * Convenient way to start running all testcases in the tests tree
 */
_command int ut_rerun,unittest_rerun()
{
   typeless i;
   i._makeempty();
   gUnitTestCurrentTests._nextel(i);
   if (i._isempty()) {
      message("No tests found");
      return(0);
   }
   if (gUnitTestCurrentTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      sunit("-all");
      return(0);
   }
   else {
      return(junit("-all"));   
   }
}

/**
 * Run a series of unit tests from the tests tree, failures tree,
 * project tree, or the command line. If run from a tree control, the selected
 * item in that tree control and all its children are run. If started from
 * the command line, the argument given is used as the fully-qualified name of
 * the test to run (package.class or package.class.method). If not argument is given,
 * the active item in the project tree and all its children are run.
 */
_command int project_unittest,ut,unittest(_str testName="")
{
   return(junit(testName));
}

/**
 * Extracts tests from the project tree and runs them. Not meant to be called
 * directly by user
 */
_command int unittest_post_build(_str cmdLine='')
{
   if (cmdLine == "") {
      popup_imessage("This command is not meant to be called directly by the user");
      return(1);
   }

   if (gUnitTestFromWhere == "projectTree" || (gUnitTestFromWhere == "cmdLine" && gUnitTestCmdLineArgs == "")) {
      _utExecuteFromProjectTree(cmdLine);
   }
   else if (gUnitTestFromWhere == "hierarchyTree") {
      _utExecuteFromHierarchyTree(cmdLine);
   }
   else if (gUnitTestFromWhere == "failuresTree") {
      _utExecuteFromFailuresTree(cmdLine);
   }
   else if (gUnitTestFromWhere == "cmdLine") {
      _utExecuteFromCmdLine(cmdLine);
   }
   else if (gUnitTestFromWhere == "rerunAll") {
      _utExecuteAllTests(cmdLine);
   }
   else if (gUnitTestFromWhere == "rerunDefects") {
      _utExecuteAllDefectiveTests(cmdLine);
   }
   gUnitTestCmdLineArgs = "";
   gUnitTestFromWhere = "";
   return(0);
}

/**
 * Executes a set of tests when unit testing is invoked from the project toolbar
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteFromProjectTree(_str cmdLine='')
{
   int hProjectTree = _find_object("_tbprojects_form._proj_tooltab_tree",'N');
   hProjectTree._utExtractTestsFromProjectTree();
   _utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);
   _utRunAllJUnitTestCases(cmdLine);
}

/**
 * Executes a set of tests when unit testing is invoked from the Tests tab
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteFromHierarchyTree(_str cmdLine='')
{
   int hHierarchyTree = _find_object("_tbunittest_form.ctltree_hierarchy",'N');
   hHierarchyTree._utExtractTestsFromTree();
   _utResetGUI();
   _utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);
   _utRunAllSelectedTests(cmdLine);
}

/**
 * Executes a set of tests when unit testing is invoked from the Defects tab
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteFromFailuresTree(_str cmdLine='')
{
   int hFailuresTree = _find_object("_tbunittest_form.ctltree_failures",'N');
   hFailuresTree._utExtractTestsFromTree();
   _utResetGUI();
   _utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);
   _utRunAllSelectedTests(cmdLine);
}

/**
 * Executes a set of tests when unit testing is invoked from the command line
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteFromCmdLine(_str cmdLine='')
{
   _str hashKey = _utAddUnknownItemToCurrentTests(gUnitTestCmdLineArgs);
   _utRunJUnitTestCase(hashKey, cmdLine);
}

/**
 * Executes all the test cases in the current test set
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteAllTests(_str cmdLine='')
{
   int hHierarchyTree = _find_object("_tbunittest_form.ctltree_hierarchy",'N');
   VS_UNITTEST_INFO oldTests:[] = gUnitTestCurrentTests;
   _utReset();
   gUnitTestCurrentTests = oldTests;
   hHierarchyTree._utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);

   typeless i;
   gUnitTestCurrentTests._nextel(i);
   if (i._isempty()) {
      message("No tests found");
      return;
   }
   if (gUnitTestCurrentTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      _utSlickUnitRunAllTestMethods();
   }
   else {
      _utRunAllJUnitTestCases(cmdLine);
   }
}

/**
 * Executes all test cases with defects in the current test set
 * 
 * @param cmdLine The parsed command line from _project_command
 */
void _utExecuteAllDefectiveTests(_str cmdLine='')
{
   // Sift through the current test set and select only the test cases that had defects the
   // last go around
   VS_UNITTEST_INFO failedTests:[] = gUnitTestCurrentTests;
   _utReset();
   typeless i;
   for (i._makeempty(); ; ) {
      failedTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (failedTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
         if (failedTests:[i].type == VS_UNITTEST_ITEM_METHOD && failedTests:[i].status != VS_UNITTEST_STATUS_PASSED) {
            _utAddTestItemToCurrentTests(failedTests:[i].type, i, VS_UNITTEST_LANGUAGE_SLICKC);
         }
      }
      else {
         if (failedTests:[i].type == VS_UNITTEST_ITEM_CLASS && failedTests:[i].status != VS_UNITTEST_STATUS_PASSED) {
            _utAddTestItemToCurrentTests(failedTests:[i].type, i, VS_UNITTEST_LANGUAGE_JAVA);
         }
      }
   }
   int hHierarchyTree = _find_object("_tbunittest_form.ctltree_hierarchy",'N');
   hHierarchyTree._utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);

   i._makeempty();
   failedTests._nextel(i);
   if (i._isempty()) {
      message("No tests found");
      return;
   }
   if (failedTests:[i].language == VS_UNITTEST_LANGUAGE_SLICKC) {
      _utSlickUnitRunAllTestMethods();
   }
   else {
      _utRunAllJUnitTestCases(cmdLine);
   }
}

/**
 * Deletes a specified item in the classpath for a specified 
 * project and configuration 
 * 
 * @param item Item to delete 
 * @param projectName Name of project. Default is current project
 * @param config Configuration to search in. Default is current config. You
 * can also specify '*' to search through all configs
 * 
 * @return The class path item if it was found; "" otherwise
 */
void _utDeleteItemInClassPath(_str item, _str projectName=_project_name, _str config="")
{
   int projectHandle = _ProjectHandle(projectName);
   _str configs[];
   if (config == "") {
      configs[0] = GetCurrentConfigName(projectName);
   }
   else if (config == "*") {
      _ProjectGet_ConfigNames(projectHandle, configs);
   }
   else {
      configs[0] = config;
   }

   int i, j;
   _str classPaths[];
   for (i = 0; i < configs._length(); i++) {
      _ProjectGet_ClassPath(projectHandle, classPaths, configs[i]);
      for (j = 0; j < classPaths._length(); j++) {
         if (pos(item, classPaths[j], 1, "RI") > 0 || classPaths[j] == item) {
            classPaths._deleteel(j);
         } 
      }
      _str classPathList = _utJoinStrings(classPaths, PATHSEP);
      _ProjectSet_ClassPathList(_ProjectHandle(projectName), classPathList, configs[i]);
      _ProjectSave(_ProjectHandle(projectName));
   }
}

/**
 * Determines if a specified item is present in the classpath for a specified
 * project and configuration
 * 
 * @param item Item to search for
 * @param projectName Name of project. Default is current project
 * @param config Configuration to search in. Default is current config. You
 * can also specify '*' to search through all configs
 * @param item Optional arg to hold the index of where item was found
 * 
 * @return The class path item if it was found; "" otherwise
 */
_str _utFindItemInClassPath(_str item, _str projectName=_project_name, _str config="", int &index = null)
{
   int projectHandle = _ProjectHandle(projectName);
   _str configs[];
   if (config == "") {
      configs[0] = GetCurrentConfigName(projectName);
   }
   else if (config == "*") {
      _ProjectGet_ConfigNames(projectHandle, configs);
   }
   else {
      configs[0] = config;
   }

   int i, j;
   _str classPaths[];
   for (i = 0; i < configs._length(); i++) {
      _ProjectGet_ClassPath(projectHandle, classPaths, configs[i]);
      for (j = 0; j < classPaths._length(); j++) {
         if (pos(item, classPaths[j], 1, "RI") > 0 || classPaths[j] == item) {
            if (index != null) {
               index = j;
            }
            return classPaths[j];
         }
      }
   }
   return "";
}

/**
 * Add a new item to the class path for the specified project and configuration
 * 
 * @param item New item to add
 * @param projectName Name of project
 * @param config Configuration of interest
 */
void _utAddItemToClassPath(_str item, _str projectName, _str config)
{
   _str classPaths[];
   _ProjectGet_ClassPath(_ProjectHandle(projectName), classPaths, config);
   classPaths[classPaths._length()] = item;
   _str classPathList = _utJoinStrings(classPaths, PATHSEP);
   _ProjectSet_ClassPathList(_ProjectHandle(projectName), classPathList, config);
   _ProjectSave(_ProjectHandle(projectName));
}

/**
 * Prepend a new item to the class path for the specified 
 * project and configuration 
 * 
 * @param item New item to add
 * @param projectName Name of project
 * @param config Configuration of interest
 */
void _utPrependItemToClassPath(_str item, _str projectName, _str config)
{
   _str classPaths[];
   _ProjectGet_ClassPath(_ProjectHandle(projectName), classPaths, config);
   classPaths._insertel(item, 0, 1);
   _str classPathList = _utJoinStrings(classPaths, PATHSEP);
   _ProjectSet_ClassPathList(_ProjectHandle(projectName), classPathList, config);
   _ProjectSave(_ProjectHandle(projectName));
}

/**
 * Determine the manner in which a unit test command was invoked
 *
 * @return A string indicating the invocation method
 */
_str _utDetermineInvocationMethod()
{
   _str invocationMethod = "";
   if (strieq(gUnitTestCmdLineArgs, "-all")) {
      invocationMethod = "rerunAll";
   }
   else if (strieq(gUnitTestCmdLineArgs, "-defects")) {
      invocationMethod = "rerunDefects";
   }
   else if (p_window_id == _find_object("_tbprojects_form._proj_tooltab_tree",'N')) {
      invocationMethod = "projectTree";
   }
   else if (p_window_id == _find_object("_tbunittest_form.ctltree_hierarchy", 'N')) {
      invocationMethod = "hierarchyTree";
   }
   else if (p_window_id == _find_object("_tbunittest_form.ctltree_failures", 'N')) {
      invocationMethod = "failuresTree";
   }
   else {
      invocationMethod = "cmdLine";
   }

   return invocationMethod;
}

/**
 * Add the unittest submenu as an entry to the Build menu in the main menu bar
 * 
 * @param menuHandle Handle to Build menu
 */
void _utAddBuildSubmenu(int menuHandle)
{
   int i, numItems = _menu_info(menuHandle, 'c');
   int hTree = _find_object("_tbprojects_form._proj_tooltab_tree", 'N');
   if (hTree <= 0) {
      return;
   }
   _str projectName = hTree._projecttbTreeGetCurProjectName();
   for (i = 0; i < numItems; i++) {
      int flags, subMenuHandle;
      _str caption;
      _menu_get_state(menuHandle, i, flags, 'p', caption, subMenuHandle);
      caption = stranslate(caption, '', '&');
      if (strieq(caption, 'Show GUI Builder')) {
         _utDisplayProjectContextMenu(projectName, menuHandle, i+1);
         break;
      }
   }
}

/**
 * The pre-build macro. Essentially resets the state of unit testing
 * 
 * @return 0 on success; anything else indicates failure.
 */
_command int unittest_pre_build()
{
   gUnitTestFromWhere = _utDetermineInvocationMethod();
   activate_toolbar("_tbunittest_form", "");
   if (gUnitTestFromWhere == "projectTree" || gUnitTestFromWhere == "cmdLine") {
      _utReset();
   }
   return(0);
}

/**
 * Activate the Tests tab on the unit test toolbar and make the tree control
 * inside it active
 */
_command void unittest_activate_tests()
{
   activate_tab("Tests", 'ctltree_hierarchy', "_tbunittest_form", 'ctltabs1');
}

void _utActivateTestsTab()
{
   activate_tab("Tests", '', "_tbunittest_form", 'ctltabs1');
}

/**
 * Activate the Defects tab on the unit test toolbar and make the tree control
 * inside it active
 */
_command void unittest_activate_defects()
{
   activate_tab("Defects", 'ctltree_defects', "_tbunittest_form", 'ctltabs1');
}

/**
 * Activate the unittests form itself
 */
_command unittest_activate_form()
{
   return activate_toolbar("_tbunittest_form", "");
}

/**
 * Activate the Defects tab on the unit test toolbar
 */
void _utActivateDefectsTab()
{
   activate_tab("Defects", '', "_tbunittest_form", 'ctltabs1');
}

/**
 * Helper function for output parsing. Creates an active selection from the
 * specified start line to the specified end line. This is then used to confine subsequent
 * search operations
 * 
 * @param startLine Line # to start selection
 * @param endLine Line # to end selection
 * 
 * @return Handle to selection
 */
int _utParseOutputMarkSelection(int startLine, int endLine)
{
   goto_line(startLine);
   int newSelection = _alloc_selection();
   _select_line(newSelection);
   goto_line(endLine);
   _select_line(newSelection);
   if (_show_selection(newSelection) != 0) {
      _utDebugSay("Had a problem showing selection");
   }


   return newSelection;
}

/**
 * Helper function for output parsing. Determines the start and end of each block of
 * output.
 * 
 * @param startLine Line to start searching from
 * @param endLine Last line that test output could possibly be on. We need this in
 * case testing was aborted; not every test start will have a corresponding test end
 * @param testStartLines (Output) Array of ints that will hold the starting line number of
 * each block of output
 * @param testEndLines (Output) Array of ints that will hold the ending line number of eahc
 * block of output
 */
void _utParseOutputTestsStartEnd(int startLine, int endLine, int (&testStartLines)[], int (&testEndLines)[])
{
   int status;
   _begin_select();
   status = search("TEST", "@WEM>");
   while (status == 0) {
      testStartLines[testStartLines._length()] = p_line;
      status = repeat_search("@+>");
   }
   _begin_select();
   status = search("ENDTEST", "@WEM>");
   while (status == 0) {
      testEndLines[testEndLines._length()] = p_line;
      status = repeat_search("@+>");
   }

   // Verify that each start line has a corresponding end line
   if (testStartLines._length() != testEndLines._length()) {
      int i;
      // There has to be more start lines than end lines
      for (i = testEndLines._length(); i < testStartLines._length(); i++) {
         testEndLines[i] = endLine;
      }
   }
}

/**
 * Helper function for output parsing. Determines the starting line # and
 * ending line # of output for this run of unit tests
 * 
 * @param startLine (Output) Will contain start line #. Will be -1 if undefined
 * @param endLine (Output) will contain end line #. -1 indicates undefined
 */
void _utParseOutputStartEnd(int &startLine, int &endLine)
{
   p_line = startLine;
   // First we need to figure out where unit testing began...
   if (search("BEGIN_TESTING", "WE>") != 0) {
      startLine = -1;
   }
   else {
      startLine = p_line;
   }
   // ...and where it ended.
   if (search("END_TESTING", "WE>") != 0) {
      endLine = -1;
   }
   else {
      endLine = p_line;
   }
}

/**
 * Returns the wid of the process buffer, if it is open. If not, then we activate the
 * build window and return its window ID
 */
int _utActivateBuildOrProcessWindow()
{
   if (_no_child_windows()) {
      return activateBuildWindow();
   }
   int windowID = _mdi.p_child._find_tile(".process");
   if (windowID <= 0) {
      windowID = activateBuildWindow();
   }
   return windowID;
}

