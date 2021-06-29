////////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc. 
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
#ifndef GRADLE_SH
#define GRADLE_SH
#pragma option(metadata,"gradle.e")
#include "maven.sh"

struct ProjectWizardSpecializations
{
   _str buildSystemName;    // 'Gradle' or 'sbt'.
   int  validBuildSystemPath;   // index for bool func(path) that returns true if path is a valid path 
                                // for the build system install.
   _str sourcePaths[];
   int executeTask;            // Function that generates execute task to be appended to build file, if applicable.  executeTask(GradleWizData*)
   int  loadKnownTasks;         // Index for function that loads known tasks.  load_known_tasks(GradleWizData*)
   int  setBuildSystemHome;     // Index of function that saves the build system home.  setBuildSystemHome(_str path)

   //_str wiz_gradle_exe(bool useWrapper, bool forProjectFile = true, GradleWizData* )
   int buildSystemExePath;     
   bool addDebugTask;

   // _str buildSystemInvocationParams(_str cmd, _str buildFileName)
   int buildSystemInvocationParams;    // Index for function that can return the correct parameters
                                       // for invoking a build system command.  Needs only supply the
                                       // command line parameters, not the exectuable name.
   // bool buildFileExists(_str projDir)
   int buildFileExists;                   // Should return true if there's a build file in the given project directory.

   _str guessedBuildSystemHome;        // Guess as to where the build system is. 
};

struct GradleProjectInfo
{
   _str name;              // Project name. Sub-project names start with leading ':'.
   bool isRootProject;
   _str dir;               // Absolute root directory for the project.
   _str tasks[];           // Known task names
   _str compilerVer;       // Used for some languages to get stdlib source for tagging.
   _str libSource[];       // Array of paths for library source, if available.
};

struct GradleWizData
{
   // Settings passed into wizard initially.
   _str configName;
   _str projectDir;
   _str implicitProjName;  // Generally, the name of the directory the root project is in.
   _str buildFilePath;
   _str wrapperFilePath;
   _str guessedGradleHome;
   _str projectType;
   bool importing;
   bool shouldImportFiles;
   bool shouldGenerateFiles;
   _str sdk; // Only set for android projects.

   // Temporary data created by dialog for completion.
   _str knownTasks[];
   bool parsedTasks;
   GradleProjectInfo allProjects[];  // Includes the root project.  
   MavenDependency dependencies:[];
   MavenDependency flatDeps[];  // Flat array of dependencies used when organizing the data in a tree control.

   // Data extracted from the dialog.
   _str selectedGradleHome;
   bool useGradleWrapper;
   _str execTaskName;
   _str exposedTaskNames[];
   _str mainPackage;
   _str mainClass;
   bool generatingMain;
   _str execTaskArgs;
   int toolMajVer;
   int toolMinVer;

   // Overrides that allow this wizard to be used for SBT as well, 
   // which has a similar setup process.
   ProjectWizardSpecializations special;
};

#endif
