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
#include "treeview.sh"
#include "unittest.sh"
#include "pipe.sh"
#import "cjava.e"
#import "compile.e"
#import "context.e"
#import "debug.e"
#import "guiopen.e"
#import "help.e"
#import "javaopts.e"
#import "main.e"
#import "os2cmds.e"
#import "projconv.e"
#import "project.e"
#import "ptoolbar.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "unittest.e"
#import "util.e"
#import "vc.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#endregion

static const JAVA_SOURCE_FILE_EXT= ".java";

static _str junitJarFiles[];

definit() {
   junitJarFiles._makeempty();
}

/**
 * This restores the original command line that was modified for debugging a unit test
 */
void _utRestoreDebugCmdLineForJUnit()
{
   if (gDebuggedJUnit) {
      int handle;
      _str config;
      _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
      int debugTargetNode = _ProjectGet_TargetNode(handle, "debug", config);
      _ProjectSet_TargetCmdLine(handle, debugTargetNode, gUnitTestOldCmdLine);
   }
}

/**
 * Create a batch file that echos the lines
 * 
 * BEGIN_TEST
 * TEST testname
 * 
 * We need these lines to indicate the beginning of a series of tests, and it
 * looks better if we do it from a batch file
 * 
 * @param testName Name of test
 * 
 * @return Name of temp batch file created on success; empty string on failure
 */
_str _utCreateJUnitBeginTestBatchFile(_str testName)
{
   int status, tempViewID;
   _str exists, origViewID;
   origViewID = _create_temp_view(tempViewID);
   if (origViewID == "") {
      return "";
   }

   _str fileName = mktemp(1, EXTENSION_BATCH);
   _insert_text("echo BEGIN_TESTING\n");
   _insert_text("echo TEST "testName"\n");
   _insert_text(VS_UNITTEST_DELETE_CMD" "fileName"\n"); // clean up after ourselves
   status = _save_file("+O "_maybe_quote_filename(fileName));
   if (status) {
      return "";
   }
   _chmod("+x "_maybe_quote_filename(fileName));
   _delete_temp_view(tempViewID);
   activate_window((int) origViewID);
   return fileName;
}

/**
 * Create a batch file that echos the lines
 * 
 * ENDTEST
 * END_TESTING
 * 
 * and runs unittest_post_test. We need these lines to indicate the end of a test and the end of a series
 * of tests, and we have to do it in a batch file to ensure that the output
 * is displayed in the process buffer before unittest_post_test is run.
 * 
 * @param outputWindowID This is a param that is passed to unittest_post_test
 * @param startLine Passed to unittest_post_test
 * 
 * @return Name of temp batch file created on success; empty string on failure
 */
_str _utCreateJUnitEndTestBatchFile(int outputWindowID, int startLine)
{
   int status, tempViewID;
   _str exists, origViewID;
   origViewID = _create_temp_view(tempViewID);
   if (origViewID == "") {
      return "";
   }

   _str fileName = mktemp(1, EXTENSION_BATCH);
   _insert_text("echo ENDTEST\n");
   _insert_text("echo END_TESTING\n");
   _insert_text("echo "_chr(1)"unittest_post_test "outputWindowID" "startLine"\n"); // here's where we trigger a post-execution callback into VSE
   _insert_text(VS_UNITTEST_DELETE_CMD" "fileName"\n"); // clean up after ourselves
   status = _save_file("+O "_maybe_quote_filename(fileName));
   if (status) {
      return "";
   }
   _chmod("+x "_maybe_quote_filename(fileName));
   _delete_temp_view(tempViewID);
   activate_window((int) origViewID);
   return fileName;
}

/**
 * Identify if a class has JUnit 4-style tests/suites. 
 * 
 * @return 0 on success
 */
int _utExtractJUnit4TestsForContext()
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   tag_init_tag_browse_info(auto cm);
   numContextTags := tag_get_num_of_context();
   curClass := "";
   importsJunit := false;
   has_suite_annotations := false;

   for (tagID := 1; tagID <= numContextTags; tagID++) {
      if (tag_get_context_browse_info(tagID, cm) != 0) {
         continue;
      }
      // Skip abstract classes and interfaces
      if(cm.flags & SE_TAG_FLAG_ABSTRACT || cm.type_name == "interface") {
         return 1;
      }

      // RGH this might have to be enhanced a bit...what happens with inner classes, etc.?
      if (cm.type_name == "class") {
         packageName := className := "";
         _utSplitTestItemName(cm.class_name, packageName, className);
         if (packageName == "") {
            curClass = VS_UNITTEST_HIERSEPARATOR :+ cm.member_name;
         } else {
            curClass = packageName :+ VS_UNITTEST_HIERSEPARATOR :+ cm.member_name;
         }
         if (has_suite_annotations) {
            _utAddSuiteItemToCurrentTests(curClass);
         }
      } else if (cm.type_name == "import" && pos("^org\\.junit\\.", cm.member_name, 1, 'U')) {
         importsJunit = true;
      } else if (cm.type_name == "annotation" && importsJunit) { 
         if (pos(cm.member_name, VS_UNITTEST_JUNITANNOTATIONS) > 0) {
            _utAddClassItemToCurrentTests(curClass);
         } else if (pos(cm.member_name, VS_UNITTEST_JUNITSUITEANNOTATIONS) > 0) {
            // Have we seen our class yet?
            if (curClass != "") {
               _utAddSuiteItemToCurrentTests(curClass);
            } else {
               // If not, just mark that we've found the JUnit 4 suite annotations
               has_suite_annotations = true;
            }
         }
      }
   }
   return 0;
}
/**
 * Extract the JUnit unit tests for the current context
 * 
 * @return 0 on success
 */
int _utExtractJUnitTestsForContext(int language = VS_UNITTEST_LANGUAGE_JAVA)
{
   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContext(true);

   // Bin the tags for this context into several types
   typeless bins:[];
   _str tagTypes:[];
   tagTypes:["class"] = "";
   tagTypes:["func"] = "";
   tagTypes:["import"] = "";
   tagTypes:["annotation"] = "";
   _utCollateTags(tagTypes, bins);

   // Figure out if the context imports the JUnit package
   importsJUnit := true;
// importsJUnit := _utImportsJUnitPackage(bins:["import"]);

   // Figure out which classes extend TestCase, and which classes extend TestSuite
   int testCases:[];
   _utPareJUnitTestCases(bins:["class"], testCases, importsJUnit, language);
   int testSuites:[];
   _utPareJUnitTestSuites(bins:["func"], bins:["class"], testSuites, importsJUnit);
   // Do the same for JUnit 4-style tests
   if (importsJUnit) {
      _utPareJUnit4Tests(bins:["class"], bins:["annotation"]);
   }

   //_utPareJUnitTestMethods(testCases, bins:["func"]);

   return 0;
}

/**
 * Extract the JUnit tests for the given file
 *
 * @param fileName The Java source file of interest
 * 
 * @return 0 on success, anything else indicates failure
 */
int _utExtractJUnitTestsForFile(_str fileName, int language = VS_UNITTEST_LANGUAGE_JAVA)
{
   int tempViewID, origViewID;
   loadOptions := "";
   if (!_utIsJavaSourceFile(fileName)) {
      _utDebugSay("_utExtractJUnitTestsForFile: "fileName" is not a Java file");
      return -1;
   }
   exists := false;

   int status = _open_temp_view(fileName, tempViewID, origViewID, loadOptions, exists, false, true);
   if (status) {
      _utDebugSay("_utExtractJUnitTestsForFile: "fileName" could not be opened");
      return status;
   }
   status = _utExtractJUnitTestsForContext(language);
   _delete_temp_view(tempViewID);

   activate_window((int) origViewID);
   return status;
}

int _utGuessLanguage(_str projectName)
{
   at := _utProjectAppType(projectName);
   if (stricmp(at, "gradle") == 0) {
      return VS_UNITTEST_LANGUAGE_GRADLE;
   }
   return VS_UNITTEST_LANGUAGE_JAVA;
}

/**
 * Extract the JUnit tests for a series of files
 * 
 * @param fileNames Array of filenames to search through
 * 
 * @return 0 on success, anything else indicates a failure
 */
int _utExtractJUnitTestsForFiles(_str (&fileNames)[])
{
   all_errors := true;
   status := 0;
   int i;

   language := _utGuessLanguage(_project_name);
   for (i = 0; i < fileNames._length(); i++) {
      status = _utExtractJUnitTestsForFile(fileNames[i], language);
      if (status) {
         _utDebugSay("Problem extracting JUnit tests for "fileNames[i]);
      } else {
         all_errors = false;
      }
   }

   return all_errors ? -1 : 0;
}

/**
 * Return the full path to the java interpreter
 * 
 * @return Full path to the java executable
 */
_str _utJavaEXE()
{
   _str javaList[];
   _str JDKPath;
   getJavaIncludePath(javaList, JDKPath);
   javaEXE :=  JDKPath :+ FILESEP :+ "bin" :+ FILESEP :+ "java" :+ EXTENSION_EXE;

   return javaEXE;
}

/**
 * Build the named JUnit project via a pipe
 * 
 * @param projectName Name of project to build
 * 
 * @return Return code from _pipe_project_command
 */
int _utBuildJUnitProject(_str projectName)
{
   _str oldProject = _project_name;
   workspace_set_active(projectName, true, false, false);
   project_build("build", false, true, 0, true);
   workspace_set_active(oldProject, true, false, false);

   return 0;
}

/**
 * Modifies the cmd line for the current project's Debug target to make it 
 * debug a JUnit unit test.
 * 
 * @param testName Name of method or class to test
 * 
 * @return The new command line
 */
_str _utModifyDebugCmdLineForJUnit(_str testName)
{
   int handle;
   _str config;
   _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
   int debugTargetNode = _ProjectGet_TargetNode(handle, "debug", config);
   _str cmdLine = _ProjectGet_TargetCmdLine(handle, debugTargetNode);
   gUnitTestOldCmdLine = cmdLine;
   _str mainClass = _GetJavaMainFromCommandLine(cmdLine);
   _str newCmdLine = cmdLine;
   if (mainClass == "") {
      if (pos(" . ", cmdLine" ")) {
         newCmdLine = stranslate(cmdLine" ", " "VS_UNITTEST_JUNITCORE" ", " . ");
      }
      else {
         newCmdLine = cmdLine" "VS_UNITTEST_JUNITCORE" ";
      }
   }
   else {
      mainClassPos := pos(mainClass, cmdLine);
      newCmdLine = substr(cmdLine, 1, mainClassPos-1) :+ " "VS_UNITTEST_JUNITCORE" ";
   }
   newCmdLine :+= testName;
   _ProjectSet_TargetCmdLine(handle, debugTargetNode, newCmdLine);
   gDebuggedJUnit = true;
   return newCmdLine;
}

/**
 * Parse the output of the JUnit test runner
 * 
 * @param outputWindowID ID of window to search through
 * @param startLine Line # at which to start parsing
 */
void _utParseJUnitOutput(int outputWindowID, int startLine)
{
   // Save the current buffer position
   origWindowID := p_window_id;
   _utPushSelection();
   typeless oldPos;
   if (!_iswindow_valid(outputWindowID) || !outputWindowID._isEditorCtl()) {
      // If the user closes the output window, then the previous window ID for the output
      // window is invalid. So we're going to make an assumption here and say that if it is
      // invalid, it was originally the window ID of the process/build buffer
      outputWindowID = _utActivateBuildOrProcessWindow();
   }
   if (p_window_id._isEditorCtl()) {
      p_window_id._save_pos2(oldPos);
   }
   p_window_id = outputWindowID;

   int endLine;
   _utParseOutputStartEnd(startLine, endLine);
   if (startLine < 0 || endLine < 0) {
      _utDebugSay("_utParseJUnitOutput: Couldn't find start & end markers: start="startLine", end="endLine);
   }

   int newSelection = _utParseOutputMarkSelection(startLine, endLine);

   int testStartLines[];
   int testEndLines[];
   _utParseOutputTestsStartEnd(startLine, endLine, testStartLines, testEndLines);
   int i;
   double percentComplete = 0, progressStep;
   if (testStartLines._length() < 1) {
      progressStep = 100.0;
   }
   else {
      progressStep = 100.0 / testStartLines._length();
   }
   for (i = 0; i < testStartLines._length(); i++) {
      _utParseJUnitOutputBlock(testStartLines[i], testEndLines[i]);
      percentComplete += progressStep;
      _utUpdateProgressBar(_utRound(percentComplete), VS_UNITTEST_GREEN);
   }

   _utUpdateAllGroupsStatus();

   // cleanup
   _free_selection(newSelection);
   p_window_id = origWindowID;
   if (p_window_id._isEditorCtl()) {
      _restore_pos2(oldPos);
   }
   _utPopSelection();
   _utExpandAllNodesWithDefects();
}

/**
 * Helper function for _utJUnitParseOutput. 
 * Parse a block of output for a single test
 * 
 * @param startLine line # that block starts
 * @param endLine line # that block ends
 */
void _utParseJUnitOutputBlock(int startLine, int endLine)
{
   language := _utGuessLanguage(_project_name);
   line := "Not found";
   typeless testName;
   p_line = startLine;
   get_line(line);
   parse line with "TEST " testName;
   testName = strip(testName);
   if (!gUnitTestCurrentTests._indexin(testName)) {
      _utDebugSay("_utParseJUnitOutputBlock: Test "testName" not found in current test set");
      return;
   }

   _utPushSelection();
   int newSelection = _utParseOutputMarkSelection(startLine, endLine);   
   
   runs := failures := errors := 0;
   _str methodName, classPkgName, testOutcome, className, packageName;
   int dotpos;
   int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
   if (hTree <= 0) {
      _utDebugSay("_utParseJUnitOutputBlock: Invalid hTree");
      return;
   }
   // We need to determine if the test was even found
   _begin_select(newSelection);
   if (search("^(Method|Class) not found", "@RhMI>") == 0) {
      message("Test not found: "testName);
      hTree._utUpdateTestItemStatus(testName, VS_UNITTEST_STATUS_NOTRUN);
      _free_selection(newSelection);
      _utPopSelection();
      return;
   }

   // We need to determine if this round of tests ran to completion
   testFinished := false;
   if (search("^OK", "@RMI>") == 0 || search("^FAILURES", "@RhMI>") == 0) {
      testFinished = true;
   }
   _begin_select(newSelection);
   numTestsStarted := 0;
   while (_utSearchForTestMethod() == 0) {
      numTestsStarted++;
   }

   _begin_select(newSelection);
   testNum := 0;
   while (_utSearchForTestMethod() == 0) {
      testNum++;
      _utParseTestMethod(methodName, classPkgName, testOutcome);
      dotpos = lastpos(".", classPkgName); // the last '.' is the break between package and class
      if(dotpos == 0) {
         packageName = "";
         className = VS_UNITTEST_HIERSEPARATOR :+ classPkgName;
         classPkgName = className;
         methodName = classPkgName :+ VS_UNITTEST_HIERSEPARATOR :+ methodName;
      } else {
         packageName = substr(classPkgName, 1, dotpos-1);
         className = substr(classPkgName, dotpos+1);
         classPkgName = packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
         methodName = classPkgName :+ VS_UNITTEST_HIERSEPARATOR :+ methodName;
      }
      _utAddMethodItemToCurrentTests(methodName, language);
      hTree._utAddTestItemToTree(methodName);

      // Determine the status of the test
      if (testOutcome == ".E") {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_ERROR);
         errors++;
      }
      else if (testOutcome == ".F") {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_FAILED);
         failures++;
      }
      else if (testOutcome == ".I") {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_IGNORE);
         runs--;
      }
      else if (!testFinished && testNum >= numTestsStarted) {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_NOTRUN);
         runs--;
      }
      else if (pos(".",testOutcome) > 0) {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_PASSED);
      }
      else {
         hTree._utUpdateTestItemStatus(methodName, VS_UNITTEST_STATUS_NOTRUN);
         runs--;
      }
      runs++;
   }

   int statusLine;
   _begin_select(newSelection);
   if (search("^OK", "@hUM>") == 0) {
      statusLine = p_line;
   }
   else if (search("^Tests run:", "@hUM>") == 0) {
      statusLine = p_line;
   }
   else {
      _utDebugSay("_utParseJUnitOutputBlock: Could not find status line");
      _free_selection(newSelection);
      _utPopSelection();
      return;
   }

   // Start parsing errors
   _utParseJUnitDefects(startLine, statusLine);
   
   typeless i;
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
   }

   // cleanup
   _free_selection(newSelection);
   _utPopSelection();
}

/**
 * Parse a single failure block and insert the messages into the correct slot in
 * the current failures.
 * 
 * @param startLine Starting line # of failure block
 * @param engLine Ending line # of failure block
 * @param fqMethodName Fully-qualified method name which acts as index into current failures
 */
void _utParseJUnitFailureBlock(int startLine, int endLine, _str fqMethodName)
{
   _utPushSelection();
   int blockSelection = _utParseOutputMarkSelection(startLine, endLine);
   _begin_select(blockSelection);
   p_col = 1;
   _str fileName, methodName;
   typeless lineNum;
   int index1, index2;
   while (_utJUnitSearchForError() == 0) {
      _utParseError(fileName, lineNum, methodName);
      index1 = gUnitTestCurrentFailures:[fqMethodName]._length()-1;
      index2 = gUnitTestCurrentFailures:[fqMethodName][index1].failures._length();
      gUnitTestCurrentFailures:[fqMethodName][index1].failures[index2].fileName = fileName;
      gUnitTestCurrentFailures:[fqMethodName][index1].failures[index2].lineNum = lineNum;
      gUnitTestCurrentFailures:[fqMethodName][index1].failures[index2].methodName = methodName;
   }
   _utPopSelection();
}

/**
 * Parse a whole series of failure or errors
 * 
 * @param startLine Line that the error/failure series begins
 * @param endLine Line that the error/failure series ends
 * @param type What type of series is this? Error or failure?
 */
void _utParseJUnitDefectSeries(int startLine, int endLine, _str type)
{
   _str fileName, exception, className, methodName, fqMethodName;
   int lineNum, dotpos, i, index1;
   int blockHeaderLines[];
   _str blockHeaders[];
   _utPushSelection();
   int newSelection = _utParseOutputMarkSelection(startLine, endLine);
   _begin_select(newSelection);
   p_col = 1;
   while (_utSearchForExceptionHeader() == 0) {
      blockHeaderLines[blockHeaderLines._length()] = p_line;
      _utParseExceptionHeader(exception, className, methodName);
      dotpos = lastpos(".", className);
      if (dotpos == 0) {
         fqMethodName = VS_UNITTEST_HIERSEPARATOR :+ className :+ VS_UNITTEST_HIERSEPARATOR :+ methodName;
      }
      else {
         className = substr(className, 1, dotpos-1) :+ VS_UNITTEST_HIERSEPARATOR :+ substr(className, dotpos+1);
         fqMethodName = className :+ VS_UNITTEST_HIERSEPARATOR :+ methodName;
      }

      if (!gUnitTestCurrentTests._indexin(fqMethodName)) {
         _utDebugSay("_utParseJUnitErrorsAndFailures: "fqMethodName" not in set of current tests");
         continue;
      }

      index1 = gUnitTestCurrentFailures:[fqMethodName]._length();
      gUnitTestCurrentFailures:[fqMethodName][index1].error = exception;
      gUnitTestCurrentFailures:[fqMethodName][index1].type = type;
      blockHeaders[blockHeaders._length()] = fqMethodName;

      // update the tree here for an error...we might have missed it if there were
      // some println statements thrown in the mix
      int hTree = _find_object("_tbunittest_form.ctltree_hierarchy");
      if (hTree <= 0) {
         _utDebugSay("_utParseJUnitOutputBlock: Invalid hTree");
         return;
      }
      hTree._utUpdateTestItemStatus(fqMethodName, VS_UNITTEST_STATUS_ERROR);
   }
   if (blockHeaderLines._length() != blockHeaders._length()) {
      _free_selection(newSelection);
      _utPopSelection();
      return;
   }
   int blockEndLine;
   for (i = 0; i < blockHeaderLines._length(); i++) {
      if (i < (blockHeaderLines._length()-1)) {
         blockEndLine = blockHeaderLines[i+1]-1;
      }
      else {
         blockEndLine = endLine;
      }
      _utParseJUnitFailureBlock(blockHeaderLines[i], blockEndLine, blockHeaders[i]);
   }
   // cleanup
   _free_selection(newSelection);
   _utPopSelection();
}

/**
 * Helper function for _utParseJUnitOutput. Parses errors and failures
 * 
 * @param startLine line # that block starts
 * @param endLine line # that block ends
 */
void _utParseJUnitDefects(int startLine, int endLine)
{
   // JUnit 4 does not differentiate errors and failures
   _begin_select("");
   p_col = 1;
   regex2 := "^There was|were \\:i failure";
   failuresStartLine := failuresEndLine := 0;
   if (search(regex2,  "@hUM>") == 0) {
      failuresStartLine = p_line;
   }

   if (failuresStartLine > 0) {
      failuresEndLine = endLine;
   }

   if (failuresEndLine > 0) {
      _utParseJUnitDefectSeries(failuresStartLine, failuresEndLine, "failure");
   }
}

/**
 * Run all the JUnit test cases and suites in the current test set
 * 
 * @param cmdLine Command line specifying how to run each test
 */
void _utRunAllJUnitTestCases(_str cmdLine)
{
   typeless i;
   _str classPkgNames[];
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (gUnitTestCurrentTests:[i].type == VS_UNITTEST_ITEM_CLASS ||
          gUnitTestCurrentTests:[i].type == VS_UNITTEST_ITEM_SUITE) {
         classPkgNames[classPkgNames._length()] = i;
      }
   }
   _utRunJUnitTestSet(classPkgNames, cmdLine);
}

/**
 * Run all the JUnit test methods in the current test set
 * 
 * @param cmdLine Command line specifying how to run each test, from _project_command
 */
void  _utRunAllJUnitTestMethods(_str cmdLine)
{
   typeless i;
   _str methodNames[];
   for (i._makeempty(); ; ) {
      gUnitTestCurrentTests._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (gUnitTestCurrentTests:[i].type == VS_UNITTEST_ITEM_METHOD) {
         methodNames[methodNames._length()] = i;
      }
   }
   _utRunJUnitTestSet(methodNames, cmdLine);
}

/**
 * Produces an array of test methods. Each item in the array is of the form packageName:className:methodName
 * 
 * @param testCases Classes which have been determined to be subclasses of JUnit TestCase.
 * Each index in this hash must be fully qualified, e.g. "pkgName:className"
 * @param testMethods A hash of method names to tagIDs in the current context. Each index
 * in this hash must be fully qualified, e.g. "pkgName:className:methodName"
 */
void _utPareJUnitTestMethods(int (&testCases):[], int (&testMethods):[])
{
   typeless i;
   _str methodName, className, packageName, classPkgName;
   for (i._makeempty(); ; ) {
      testMethods._nextel(i);
      if (i._isempty()) {
         break;
      }
      // Split the current index into constituent parts
      _utSplitTestItemName(i, packageName, className, methodName);
      classPkgName = packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
      if (testCases._indexin(classPkgName)) {
         // Only considering classes that begin with 'test' for now
         if (substr(methodName, 1, 4) != "test") {
            continue;
         }
         // Insert items for the method, package, and class
         /*_utAddMethodItemToCurrentTests(i, testMethods:[i]);
         _utAddClassItemToCurrentTests(classPkgName, testCases:[classPkgName]);
         _utAddPackageItemToCurrentTests(packageName);*/
         _utAddMethodItemToCurrentTests(i, VS_UNITTEST_LANGUAGE_JAVA);
      }
   }
}

/**
 * Fix up the classpath. This means quoting each path in the classpath
 * 
 * @param classPath The input classpath
 * 
 * @return The fixed-up classpath
 */
_str _utFixupClassPath(_str classPath)
{
   _str classPaths[];
   _utSplitString(classPath, classPaths, PATHSEP);
   int i;
   for (i = 0; i < classPaths._length(); i++) {
      // We want to strip leading and trailing whitespace and quote characters...
      classPaths[i] = strip(classPaths[i], "B", "\"\t ");
      if (length(classPaths[i] > 1)) {
         // ...and also trailing slashes, but only if it's not the only character
         // in the classpath, because that would indicate the root
         classPaths[i] = strip(classPaths[i], "T", FILESEP);
      }
   }
   result :=  '"' :+ _utJoinStrings(classPaths, PATHSEP) :+ '"';
   //_message_box("result="result);
   return result;
}

/**
 * Fix up the classpath inside a command line.
 * 
 * @param cmdLine A command line potentially containing '-classpath'
 * 
 * @return The fixed-up command line
 */
_str _utFixupClassPathInCommand(_str cmdLine)
{
   pos1 := pos("-classpath", cmdLine, 1, "I");
   pos2 := pos(VS_UNITTEST_JUNITCORE, cmdLine, 1, "I");
   if (pos1 < 1) {
      return cmdLine;
   }
   pos1 += length("-classpath");
   while (substr(cmdLine, pos1, 1) == " ") {
      pos1++;
   }
   if (pos2 < 1) {
      pos2 = length(cmdLine);
   }
   pos2 -= 1;
   while (substr(cmdLine, pos2, 1) == " ") {
      pos2--;
   }
   _str classPath = _utFixupClassPath(substr(cmdLine, pos1, pos2-pos1+1));
   result := substr(cmdLine, 1, pos1-1) :+ classPath :+ substr(cmdLine, pos2+1);
   //_message_box("result="result);
   return result;
}

/**
 * Prepend vsjunit.jar to the class path if necessary. 
 * vsjunit.jar should be the first element in the class path 
 * because we have a custom implementation of 
 * org.junit.internal.TextListener for build window output. 
 * 
 * @param projectName Name of project
 * @param config Configuration whose classpath we want to modify
 */
void _utMaybePrependVSJUnitJar(_str projectName, _str config)
{
   _str vsroot = _getSlickEditInstallPath();
   jarFile :=  vsroot"vsjunit"FILESEP"vsjunit.jar";
   index := -1;
   _str foundItem = _utFindItemInClassPath("\\"FILESEP"vsjunit.jar", projectName, config, index);
   if (foundItem == "") {
      // if we didn't find the jar file in the class path, add it in front
      _utPrependItemToClassPath(jarFile, projectName, config);
   } else if (index != 0){ 
      // if we found it (and it's not the first item), delete it and prepend it 
      _utDeleteItemInClassPath(foundItem, projectName, config);
      if (file_exists(foundItem)) {
         _utPrependItemToClassPath(foundItem, projectName, config);
      } else {
         _utPrependItemToClassPath(jarFile, projectName, config);
      }
   }
}

static _str _utFindClassPath(_str item, _str (&classPaths)[], int &index = null)
{
   int i;
   for (i = 0; i < classPaths._length(); i++) {
      if (pos(item, classPaths[i], 1, "RI") > 0 || classPaths[i] == item) {
         if (index != null) {
            index = i;
         }
         return classPaths[i];
      }
   }
   if (index != null) {
      index = -1;
   }
   return "";
}


// junit dependencies
/* 
   hamcrest-core-1.3.jar
   junit-4.12.jar
   junit-jupiter-api-5.0.1.jar
   junit-jupiter-engine-5.0.1.jar
   junit-platform-commons-1.0.1.jar
   junit-platform-engine-1.0.1.jar
   junit-platform-launcher-1.0.1.jar
   junit-platform-runner-1.0.1.jar
   junit-vintage-engine-4.12.1.jar
   opentest4j-1.0.0.jar
*/


static void _getVSJunitFiles(_str (&jarFiles)[])
{
   filepath := _maybe_quote_filename(_getSlickEditInstallPath():+"vsjunit":+FILESEP:+"*.jar");
   filename := file_match(filepath, 1);
   for (;;) {
      if (filename == '') break;
      if (_strip_filename(filename, "P") :!= "vsjunit.jar") {
         jarFiles[jarFiles._length()] = filename;
      }
      filename = file_match(filepath, 0);
   }
}

void _utMaybeAddJUnitJars(_str (&classPaths)[])
{
   vsjunitpath := _getSlickEditInstallPath():+"vsjunit":+FILESEP;
   if (junitJarFiles == null || junitJarFiles._isempty()) {
      _getVSJunitFiles(junitJarFiles);
   }

   int i;
   addjar := true;
   for (i = 0; i < classPaths._length(); i++) {
      if (_strip_filename(classPaths[i], "P") :== "vsjunit.jar") {
         if (classPaths[i] :!= vsjunitpath:+"vsjunit.jar") {
            // remove old versions
            classPaths._deleteel(i);
         } else {
            addjar = false;
         }
         break;
      }
   }

   // prepend junit runner
   if (addjar) {
       classPaths._insertel(vsjunitpath:+"vsjunit.jar", 0);
   }
   // append support jars
   for (i = 0; i < junitJarFiles._length(); i++) {
      classPaths[classPaths._length()] = junitJarFiles[i];
   }
}


/**
 * Before we attempt JUnit testing for the first time, we need to compile our
 * own TestRunner, vsjunit.jar.
 */
void _utCompileJUnitRunner()
{
   vsbin := get_env("VSLICKBIN1");
   _str vsroot = _getSlickEditInstallPath();
   projectName :=  vsroot"vsjunit"FILESEP"vsjunit.vpj";
   if (file_exists(vsroot"vsjunit"FILESEP"vsjunit.jar")) {
      return;
   }
}

/**
 * For Java projects with unit testing enabled, check to make sure vsjunit.jar is built
 * and add vsjunit.jar and junit.jar to the classpath if necessary
 * 
 * @param projectName Name of project to check
 */
void _utPrepForJUnit(_str projectName)
{
   int projectHandle = _ProjectHandle(projectName);
   currentConfig := GetCurrentConfigName(projectName);
   if (strieq(_ProjectGet_Type(projectHandle, currentConfig), "java")) {
      if (_ProjectGet_TargetNode(projectHandle, "UnitTest", currentConfig) >= 0) {
         if (!file_exists(_getSlickEditInstallPath() :+ "vsjunit"FILESEP"vsjunit.jar")) {
            _message_box("The file 'vsjunit.jar' could not be built. If you have not already done so, please download the JUnit package from www.junit.org and try again. If this problem persists, please contact SlickEdit for assistance.");
            return;
         }
      }
   }
}

/**
 * Parse the progress line of the JUnit output. This is the line
 * that looks like "...F.."
 * 
 * @param outputWindowID window ID of editor control in which JUnit output is being sent
 * @param progressLineNum Pre-determined line # of the progress line within this editor control
 * @param runs (Output) Holds the # of runs. Optional (default=null)
 * @param failures (Output) Holds the # of failures . Optional (default=null)
 * @param errors (Output) Holds the # of errors. Optional (default=null)
 */
void _utMonitorJUnitProgressLine(int outputWindowID, int progressLineNum, int &runs=null, int &failures=null, int &errors=null)
{
   // Gotta save the cursor position so we can restore it later
   typeless oldPos;
   outputWindowID._save_pos2(oldPos);
   outputWindowID.goto_line(progressLineNum);
   _str line;
   outputWindowID.get_line(line);
   // The rest of this is just looking at the status line and counting up
   // the # of failures, errors and runs
   
   if (runs != null) {
      runs = 0;
   }
   if (errors != null) {
      errors = 0;
   }
   if (failures != null) {
      failures = 0;
   }
   int i;
   _str currentChar;
   for (i = 1; i <= length(line); i++) {
      currentChar = substr(line, i, 1);
      if (currentChar == "." && runs != null) {
         runs++;
      }
      else if (currentChar == "F" && failures != null) {
         failures++;
      }
      else if (currentChar == "E" && errors != null) {
         errors++;
      }
   }
   outputWindowID._restore_pos2(oldPos);
}

/**
 * Pipe a non-interactive command, sending its output to the specified
 * editor control. When the command has exited, return the exit status.
 * 
 * @param cmdLine Command line to execute
 * @outputWindowID Window ID of an editor control. Default is -1, which
 * implies that we should direct output to the Build output window
 * 
 * @return Exit status of the process
 */
int _utPipeCommand(_str cmdLine, int outputWindowID=-1)
{
   int inFile, outFile, errFile;
   if (outputWindowID < 0) {
      outputWindowID = activateOutputWindow();
   }
   int processHandle = _PipeProcess(cmdLine, inFile, outFile, errFile, "");
   if (processHandle < 0) {
      _utDebugSay("process creation failed with status="processHandle);
      return processHandle;
   }
   done := false;
   buffer := "";
   maxBufferLength := 1024;
   outputWindowID.bottom();
   outputWindowID._insert_text(cmdLine"\n");
   int status;
   while (!done) {
      if (inFile >= 0 && _PipeIsReadable(inFile)) {
         buffer = "";
         status = _PipeRead(inFile, buffer, maxBufferLength, 0);
         if (status) {
            _utDebugSay("_PipeRead on input failed. status="status);
         }
         else {
            outputWindowID._insert_text(buffer);
         }
      }
      if (errFile >= 0 && _PipeIsReadable(errFile)) {
         buffer = "";
         status=_PipeRead(errFile, buffer, maxBufferLength, 0);
         if (status) {
            _utDebugSay("_PipeRead on err failed. status="status);
         }
         else {
            outputWindowID._insert_text(buffer);
         }
      }
      refresh();
      process_events(done);
      if (_PipeIsProcessExited(processHandle)) {
         done = true;
      }
   }

   status = _PipeEndProcess(processHandle);
   _PipeClose(inFile);
   _PipeClose(outFile);
   _PipeClose(errFile);
   return status;
}

/**
 * Parse the status line of the JUnit output. This is the line that looks
 * like "OK (3 tests)" or "Tests run: 5,  Failures: 1,  Errors: 0"
 * 
 * @param statusLineNum Pre-determined line # of the status line within this editor control
 * @param runs (Output) Holds the # of runs. Optional (default=null)
 * @param failures (Output) Holds the # of failures . Optional (default=null)
 * @param errors (Output) Holds the # of errors. Optional (default=null)
 */
void _utParseJUnitOutputStatusLine(int statusLineNum, int &runs=null, int &failures=null, int &errors=null)
{
   goto_line(statusLineNum);
   get_line(auto line);

   if (runs != null) {
      runs = 0;
   }
   if (errors != null) {
      errors = 0;
   }
   if (failures != null) {
      failures = 0;
   }

   if (substr(line, 1, 2) == "OK") {
      // This means all tests passed
      _str num1;
      parse line with "OK (" num1 " tests)";
      if (runs != null) {
         runs = isnumber(num1) ? (int) num1 : 0;
      }
      if (failures != null) {
         failures = 0;
      }
      if (errors != null) {
         errors = 0;
      }
   }
   else {
      // This means we had some problems
      _str num1, num2, num3;
      parse line with "Tests run: " num1 ",  Failures: " num2 ",  Errors: " num3;
      if (runs != null) {
         runs = isnumber(num1) ? (int) num1 : 0;
      }
      if (failures != null) {
         failures = isnumber(num2) ? (int) num2 : 0;
      }
      if (errors != null) {
         errors = isnumber(num3) ? (int) num3 : 0;
      }
   }
}

int _utPipeAndParseJUnitOutput(_str cmdLine, int outputWindowID)
{
   int inFile, outFile, errFile;
   if (outputWindowID < 0) {
      outputWindowID = activateOutputWindow();
   }
   int processHandle = _PipeProcess(cmdLine, inFile, outFile, errFile, "");
   if (processHandle < 0) {
      return processHandle;
   }
   done := false;
   buffer := "";
   maxBufferLength := 1024;

   outputWindowID.bottom();
   progressLineNum := outputWindowID.p_line;

   int status;
   runs := errors := failures := 0;
   while (!done) {
      if (inFile >= 0 && _PipeIsReadable(inFile)) {
         buffer = "";
         status = _PipeRead(inFile, buffer, maxBufferLength, 0);
         if (status) {
            _utDebugSay("_PipeRead on input failed. status="status);
         }
         else {
            outputWindowID._insert_text(buffer);
            _utMonitorJUnitProgressLine(outputWindowID, progressLineNum, runs, failures, errors);
         }
      }
      if (errFile >= 0 && _PipeIsReadable(errFile)) {
         buffer = "";
         status=_PipeRead(errFile, buffer, maxBufferLength, 0);
         if (status) {
            _utDebugSay("_PipeRead on err failed. status="status);
         }
         else {
            outputWindowID._insert_text(buffer);
         }
      }
      refresh();
      process_events(done);
      if (_PipeIsProcessExited(processHandle)) {
         done = true;
      }
   }
   status = _PipeEndProcess(processHandle);
   _PipeClose(inFile);
   _PipeClose(outFile);
   _PipeClose(errFile);

   _utMonitorJUnitProgressLine(outputWindowID, progressLineNum, runs, failures, errors);
   _utDebugSay("Runs: "runs" Failures: "failures" Errors: "errors);
   return status;
}

/**
 * Creates the batch macro needed to run a series of unittests in the
 * build window.
 * 
 * @param Array of fully-qualified class names which acts as
 * a set of indices into gCurrentTests
 * @param cmdLine The complete command line to execute a JUnit test case
 * @param outputWindowID ID of the window that will capture the output of this
 * batch macro when it is run
 * 
 * @return The name of the created batch macro, or '' if there was a problem
 * creating it.
 */
_str _utCreateJUnitBatchFile(_str (&classPkgNames)[], _str cmdLine, int outputWindowID)
{
   int status, tempViewID;
   _str exists, origViewID;
   origViewID = _create_temp_view(tempViewID);
   if (origViewID == "") {
      return "";
   }

   cmdLine = _utFixupClassPathInCommand(cmdLine);
   int i;
   _str classPkgName;
   _str fileName = mktemp(1, EXTENSION_BATCH);
   _insert_text("echo BEGIN_TESTING\n");
   for (i = 0; i < classPkgNames._length(); i++) {
      classPkgName = classPkgNames[i];
      _insert_text("echo TEST "classPkgName"\n");
      classPkgName = strip(classPkgName, 'L', VS_UNITTEST_HIERSEPARATOR);
      classPkgName = _utConvertHashKeyToTestName(classPkgName);
      cmd :=  cmdLine :+ " " :+ classPkgName :+ "\n";
      _insert_text(cmd);
      //_insert_text("echo "cmd);
      _insert_text("echo ENDTEST\n");
   }

   outputWindowID.bottom();
   _insert_text("echo END_TESTING\n");
   _insert_text("echo "_chr(1)"unittest_post_test "outputWindowID" "outputWindowID.p_line"\n"); // here's where we trigger a post-execution callback into VSE
   _insert_text(VS_UNITTEST_DELETE_CMD" "fileName"\n"); // clean up after ourselves
   status = _save_file("+O "_maybe_quote_filename(fileName));
   if (status) {
      return "";
   }
   _chmod("+x "_maybe_quote_filename(fileName));
   _delete_temp_view(tempViewID);
// copy_file(fileName, 'C:\\JUNIT.txt');
   activate_window((int) origViewID);
   
   return fileName;
}

/**
 * Run a series of JUnit test cases
 * 
 * @param classPkgNames Array of fully-qualified class names which acts as
 * as a set of indices into gCurrentTests
 * @param cmdLine The complete command line to execute a JUnit test case
 * 
 * @return 0 on success; anything else indicates failure
 */
int _utRunJUnitTestSet(_str (&classPkgNames)[], _str cmdLine)
{
   if (classPkgNames._length() < 1) {
      message("No tests found!");
      return -1;
   }

   // Gradle tests are different, in that you can't run the
   // build step separately, so once we get here, the tests 
   // have already been run, and the results are ready to be
   // parsed by unittest_post_test. Special casing here allows
   // gradle to share the code paths setting everything up
   // with the standard JUnit code.
   if (cmdLine != 'gradle') {
      int buildWindowID = _utActivateBuildOrProcessWindow();
      _str batchFileName = _utCreateJUnitBatchFile(classPkgNames, cmdLine, buildWindowID);
      if (batchFileName == "") {
         _utDebugSay("_utRunJUnitTestSet: Unable to create batch macro");
         return FILE_NOT_FOUND_RC;
      }
      buildWindowID.bottom();
      startLine := buildWindowID.p_line;
      concur_command(batchFileName);
   }

   return 0;
}

/**
 * Run a single JUnit TestCase
 * 
 * @param classPkgName Fully-qualified name of class which acts as index into gCurrentTests
 * 
 * @return 0 on success, anything else indicates a problem
 */
int _utRunJUnitTestCase(_str classPkgName, _str cmdLine)
{
   _str classPkgNames[];
   classPkgNames[classPkgNames._length()] = classPkgName;
   return _utRunJUnitTestSet(classPkgNames, cmdLine);
}

/**
 * Given a hash of classnames-tagIDs, determines which of these are subclasses
 * of JUnit TestCase and places them in the output hash
 * 
 * @param inputClasses
 * @param outputClasses (Output)
 * @param importsJUnit Does the context import the JUnit package?
 */
void _utPareJUnitTestCases(int (&inputClasses):[], int (&outputClasses):[], bool importsJUnit, int language = VS_UNITTEST_LANGUAGE_JAVA)
{
   outputClasses._makeempty();
   typeless i;
   for (i._makeempty(); ; ) {
      inputClasses._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (_utDoesClassExtendJUnit(inputClasses._el(i), importsJUnit) == VS_UNITTEST_JUNIT_CASE) {
         outputClasses:[i] = inputClasses:[i];
      }

      if (outputClasses._indexin(i)) {
         _utAddClassItemToCurrentTests(i, language);
      }
   }
}

/**
 * Given a hash of classnames-tagIDs, and annotations-tagIDs, 
 * determines which classes contain JUnit tests, and places them
 * in the output hash. 
 * 
 * @param inputClasses
 * @param inputAnnotations
 */
void _utPareJUnit4Tests(int (&inputClasses):[], int (&inputAnnotations):[])
{
   typeless i;
   _str className, packageName, annotationName;
   for (i._makeempty(); ; ) {
      inputAnnotations._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utSplitTestItemName(i, packageName, className, annotationName);
      fullname :=  packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
      if (pos(annotationName, VS_UNITTEST_JUNITANNOTATIONS) > 0) {
         _utAddClassItemToCurrentTests(fullname);
      } else if (pos(annotationName, VS_UNITTEST_JUNITSUITEANNOTATIONS) > 0) {
         _utAddSuiteItemToCurrentTests(fullname);
      }
   }
}

/**
 * Given a hash of classnames-tagIDs, and methods-tagIDs, 
 * determines which classes define a suite method, and places 
 * them in the output hash. 
 * 
 * @param inputFuncs
 * @param inputClasses
 * @param outputClasses (Output)
 * @param importsJUnit Does the context import the JUnit package?
 */
void _utPareJUnitTestSuites(int (&inputFuncs):[], int (&inputClasses):[], int (&outputClasses):[], bool importsJUnit)
{
   outputClasses._makeempty();
   typeless i;
   _str className, packageName, methodName;
   for (i._makeempty(); ; ) {
      inputFuncs._nextel(i);
      if (i._isempty()) {
         break;
      }
      _utSplitTestItemName(i, packageName, className, methodName);
      // Do we have a 'suite' method defined?
      if (importsJUnit && methodName == "suite") {
         // Get the tag ID for the class with this suite method
         fullClass :=  packageName :+ VS_UNITTEST_HIERSEPARATOR :+ className;
         typeless j;
         for (j._makeempty(); ; ) {
            inputClasses._nextel(j);
            if (j._isempty()) {
               // Didn't find an exact match...just add the suite method's tag ID
               outputClasses:[i] = inputFuncs:[i];
               _utAddSuiteItemToCurrentTests(i);
               break;
            }
            if (j == fullClass) {
               // Found it
               outputClasses:[i] = inputClasses:[j];
               _utAddSuiteItemToCurrentTests(j);
               break;
            }
         }
      }
   }
}

/**
 * Determines if the given file imports the junit package
 * 
 * @param fileName Name of file to look through
 * 
 * @return True if the file contains an import statement for JUnit packages,
 * false otherwise
 */
bool _utFileImportsJUnitPackage(_str fileName)
{
   int status, tempViewID, origViewID;
   loadOptions := "";
   exists := false;
   status = _open_temp_view(fileName, tempViewID, origViewID, loadOptions, exists, false, true);
   if (status) {
      _utDebugSay("_utExtractJUnitTestsForFile: "fileName" could not be opened");
      return false;
   }

   _str tagTypes:[];
   tagTypes:["imports"] = "";
   typeless bins:[];
   _utCollateTags(tagTypes, bins);
   importsJUnit := _utImportsJUnitPackage(bins:["import"]);
   _delete_temp_view(tempViewID);
   return importsJUnit;
}

/**
 * Determines if the filename is a Java source file
 * 
 * @param fileName
 * 
 * @return true if filename is a Java source file; false otherwise
 */
bool _utIsJavaSourceFile(_str fileName)
{
   lang := _Ext2LangId(_get_extension(fileName));
   return lang == 'java' || lang == 'scala' || _LanguageInheritsFrom('kotlin', lang) || lang == 'groovy';
}

/**
 * Determines if the specified project/config combo is a Java project
 * 
 * @param name Name of project to check
 * @param config Name of config to check. Default is blank, in which case currently
 * active config is used
 * 
 * @return 0 if not Java, 1 if is Java, -1 on error
 */
int _utIsJavaProject(_str name, _str config="")
{
   return (int)(_utIsProjectOfSpecificType(name, config, "java") || _utIsProjectOfSpecificType(name, config, "scala") ||
      _utIsProjectOfSpecificType(name, config, "kotlin") || _utIsProjectOfSpecificType(name, config, "groovy") ||
                _utIsProjectOfSpecificType(name, config, "android"));
}

/**
 * Determines if the current context has an 'import junit' line
 * 
 * @param imports A hash table of tagname-tagID tuples representing a list of
 * import statements
 * 
 * @return true or false
 */
bool _utImportsJUnitPackage(int (&imports):[])
{
   int status;
   _str tagName, typeName, fileName, className;
   int lineNum, tagFlags;
   typeless i;
   for (i._makeempty(); ; ) {
      imports._nextel(i);
      if (i._isempty()) {
         break;
      }
      if (pos("^junit\\.framework\\.", i, 1, 'U') || pos("^org\\.junit\\.", i, 1, 'U')) {
         return true;
      }
   }

   return false;
}

/**
 * Run a series of JUnit tests from the tests tree, failures tree,
 * project tree, or the command line. If run from a tree control, the selected
 * item in that tree control and all its children are run. If started from
 * the command line, the argument given is used as the fully-qualified name of
 * the test to run (package.class or package.class.method). If not argument is given,
 * the active item in the project tree and all its children are run.
 * 
 * @param testName Optional. Name of test to run
 */
_command int junit(_str testName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Unit testing");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _utPrepForJUnit(_project_name);

   if (testName != "") {
      gUnitTestCmdLineArgs = testName;
      return(_project_command2("unittest", false, true, 0, false, "go", ""));
   }
   else if (p_window_id == _find_object("_tbunittest_form.ctltree_hierarchy", "N")) {
      return(_project_command2("unittest", false, true, 0, false, "go", ""));
   }
   else if (p_window_id == _find_object("_tbunittest_form.ctltree_failures", "N")) {
      return(_project_command2("unittest", false, true, 0, false, "go", ""));
   }

   hTree := _tbGetActiveProjectsTreeWid();
   if (hTree <= 0) {
      message("Project toolbar must be active");
      return(0);
   }
   int numSelected = hTree._TreeGetNumSelectedItems();
   if (numSelected != 1) {
      message("You must select exactly one item in the project tree");
      return(0);
   }
   if (_project_name != hTree._projecttbTreeGetCurProjectName()) {
      message("Only items in the active project may be unit tested");
      return(0);
   }
   return(_project_command2("unittest", false, true, 0, false, "go", ""));
}

/**
 * This command starts debugging a JUnit test. It can be triggered from
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
_command int junit_debug(_str key="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild() || !_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _utPrepForJUnit(_project_name);

   //int hHierarchyTree = _find_object("_tbunittest_form.ctltree_hierarchy", "N");
   //int hFailuresTree = _find_object("_tbunittest_form.ctltree_failures", "N");
   hProjectTree := _tbGetActiveProjectsTreeWid();

   testName := "";
   unittest_pre_build();
   if (key != "") {
      // If the key is not empty, we must have been called from the command line
      key = _utAddUnknownItemToCurrentTests(key);
   }
   else if (gUnitTestFromWhere == "hierarchyTree" || gUnitTestFromWhere == "failuresTree") {
      // Were we called from the hierarchy tree or the failures tree?
      if (gUnitTestFromWhere == "hierarchyTree") {
         p_window_id = _find_object("_tbunittest_form.ctltree_hierarchy", "N");
      } else if (gUnitTestFromWhere == "failuresTree") {
         p_window_id = _find_object("_tbunittest_form.ctltree_failures", "N");
      }
      treeIndex := _TreeCurIndex();
      key = _TreeGetUserInfo(treeIndex);
      if (!gUnitTestCurrentTests._indexin(key)) {
         return(0);
      }
      _utExtractTestsFromTree();
      _utResetGUI();
      _utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);
   }
   else if (gUnitTestFromWhere == "projectTree" || key == "") {
      // Were we invoked from the project tree (or the command line w/o args)?
      p_window_id = hProjectTree;
      hProjectTree._utExtractTestsFromProjectTree();
      key = _utHelpFindTest();
      _utReset();
      if (key == "") {
         return(0);
      }
      _utAddUnknownItemToCurrentTests(key);
      _utUpdateStatusOfAllTests(VS_UNITTEST_STATUS_NOTRUN);
   }

   if (key == "") {
      message("No tests could be found; please enter the name of a test to debug on the command line");
      return(0);
   }

   testName = _utConvertHashKeyToTestName(key);
   gUnitTestParseOutputWindowID = _utActivateBuildOrProcessWindow();
   gUnitTestParseOutputWindowID.bottom();
   gUnitTestParseLineNum = gUnitTestParseOutputWindowID.p_line;
   _str fileName = _utCreateJUnitBeginTestBatchFile(key);
   int status;
   concur_command(fileName);
   if (_utPositionCursorForDebugging(key) != 0) {
      message("Unable to set breakpoint automatically. Please set one manually and retry.");
      return(DEBUG_BREAKPOINT_NOT_FOUND_RC);
   }
   if (substr(testName,1,1)==".") {
      testName=substr(testName,2);
   }
   return(debug_run_to_cursor(false, "unittest "testName));
}


