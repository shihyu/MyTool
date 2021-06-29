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
#pragma option(metadata,"unittest.e")


// Some constants
const VS_UNITTEST_JUNIT_PKGNAME= "junit.framework";
const VS_UNITTEST_JUNIT_CASE= "TestCase";
const VS_UNITTEST_JUNIT_SUITE= "TestSuite";
const VS_UNITTEST_JUNITCORE= "org.junit.runner.JUnitCore";
const VS_UNITTEST_JUNITTESTRUNNER= "junit.slickedit.TestRunner";
//const VS_UNITTEST_JUNITANNOTATIONS= "Test,Ignore,org.junit.Test,org.junit.Ignore";
const VS_UNITTEST_JUNITANNOTATIONS= "org.junit.jupiter.api.Test,Test,Ignore,org.junit.Test,org.junit.Ignore,ParameterizedTest,RepeatedTest,TestFactory,TestTemplate";
const VS_UNITTEST_JUNITSUITEANNOTATIONS= "Suite,Suite.SuiteClasses,org.junit.runners.Suite,org.junit.runners.Suite.SuiteClasses";

const VS_UNITTEST_HIERSEPARATOR= "!";

const VS_UNITTEST_STATUS_NOTRUN= 0;
const VS_UNITTEST_STATUS_PASSED= 1;
const VS_UNITTEST_STATUS_FAILED= 2;
const VS_UNITTEST_STATUS_ERROR= 3;
const VS_UNITTEST_STATUS_IGNORE= 4 ;

const VS_UNITTEST_ITEM_UNKNOWN= -1;
const VS_UNITTEST_ITEM_METHOD= 0;
const VS_UNITTEST_ITEM_CLASS= 1;
const VS_UNITTEST_ITEM_PACKAGE= 2;
const VS_UNITTEST_ITEM_PROJECT= 3 ;
const VS_UNITTEST_ITEM_SUITE= 4;

const VS_UNITTEST_RED= 0x000000FF;
const VS_UNITTEST_GREEN= 0x00008000;
const VS_UNITTEST_BLACK= 0x00000000;

const VS_UNITTEST_LANGUAGE_UNKNOWN= 0;
const VS_UNITTEST_LANGUAGE_JAVA= 1;
const VS_UNITTEST_LANGUAGE_SLICKC= 2;
const VS_UNITTEST_LANGUAGE_GRADLE = 3;

const VS_UNITTEST_DEBUG= 0x1;

#define VS_UNITTEST_DELETE_CMD (_isUnix()? "rm -f" : "del")

// Some datatypes
struct VS_UNITTEST_INFO {
   int type;
   _str fileName;
   _str projectName;
   int status;
   bool selected; // this tells us whether the test item was selected to run
   int language; // this tell us what programming language this unit test is in.
};

struct _utTreeCacheEntry {
   int treeIndex;
   int itemType;
};

struct _utFailureMessage {
   _str fileName;
   _str lineNum;
   _str methodName;
};

struct _utTraceEntry {
   _str type; // e.g. "failure" or "error"
   _str error; // specific exception/error that occurred
   _utFailureMessage failures[]; // array of error messages corresponding to the stack trace
};

// Some global vars used to keep track of state
VS_UNITTEST_INFO gUnitTestCurrentTests:[]; // Main data structure. Holds a list of test entries index by fully-qualified test name
_utTreeCacheEntry gUnitTestTreeCache:[]; // We use this to keep track of tree indices for packages, classes, etc.
_utTraceEntry gUnitTestCurrentFailures:[][]; // Holds all the current failures and associated messages
int gUnitTestSelectionStack[]; // Stack that we can use to push and pop selections
int gUnitTestOverlayMatrix[]; // This is a table which tells us what icon overlay to use for a given unit test status
int gUnitTestIconMatrix[];    // This is a table which tells us what icon to use for a given unit test item
_str gUnitTestFromWhere; // This tells us how unittesting was invoked
_str gUnitTestOldCmdLine; // This holds the value of the original command line for the debug target
bool gDebuggedJUnit; // Did we debug a JUnit test?
_str gUnitTestCmdLineArgs; // Command line arguments specified the last time ut or utd is invoked
int gUnitTestParseLineNum; // This is the line number in the ParseOutputWindow at which to start parsing
int gUnitTestParseOutputWindowID; // This is the window ID of the buffer containing output of unit testing
_str _error_SlickC;


