////////////////////////////////////////////////////////////////////////////////////
// Copyright 2016 SlickEdit Inc. 
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
#include "slick.sh"
#include "gradle.sh"
#include "maven.sh"
#include "pipe.sh"
#include "rte.sh"
#include "xml.sh"
#import "android.e"
#import "compile.e"
#import "ctadditem.e"
#import "debug.e"
#import "diffprog.e"
#import "dir.e"
#import "env.e"
#import "files.e"
#import "fileman.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "maven.e"
#import "os2cmds.e"
#import "picture.e"
#import "pipe.e"
#import "projconv.e"
#import "project.e"
#import "ptoolbar.e"
#import "rte.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "se/ui/toolwindow.e"
#import "treeview.e"
#import "unittest.e"
#import "vc.e"
#import "wizard.e"
#import "wkspace.e"
#import "saveload.e"
#import "applet.e"

static _str GRADLE_WRAPPER_EXTENSION() {
   return (_isWindows() ? ".bat":"");
}
static const NO_EXEC_TASK= "<NONE>";

static int def_gradle_debug = 0;

static GradleWizData wizData;

/** Location of the gradle install.  If not set, we look
 *  at the GRADLE_HOME environment variable, or just look for
 *  it on the system path.
 */
_str def_gradle_home = '';

_str gUnitTestSubset = '';

definit()
{
   gUnitTestSubset = '';
}

defeventtab _gradle_project_wizard_form;

_str gradle_exe_relpath()
{
   return '/bin/gradle'GRADLE_WRAPPER_EXTENSION();
}

bool gradle_exe_exists(_str installDir) 
{
   return file_exists(installDir:+gradle_exe_relpath());
}

// We don't need the gradle home if the project we're opening/importing
// has a gradle wrapper.
bool maybe_valid_gradle_home_path(_str installDir)
{
   return wizData.useGradleWrapper || gradle_exe_exists(installDir);
}

static _str unix_paths[] = {
   '/usr/share/gradle', '/usr/local/share/gradle', '/opt/gradle'
};

// Path to gradle init script that implements our test listener for unit
// test support.
static _str testListenerPath() 
{
   return _getSlickEditInstallPath()'toolconfig'FILESEP'gradle'FILESEP'testlistener.gradle';
}

//TODO: Are there standard install locations on windows, looks like they
// just have zip files you can plop down anywhere.
static _str windows_paths[];

void ctl_check_all.lbutton_up()
{
   int i;

   for (i = 1; i <= ctl_deptree._TreeGetNumChildren(TREE_ROOT_INDEX); i++) {
      ctl_deptree._TreeSetCheckState(i, TCB_CHECKED);
   }
}

void ctl_uncheck_all.lbutton_up()
{
   int i;

   for (i = 1; i <= ctl_deptree._TreeGetNumChildren(TREE_ROOT_INDEX); i++) {
      ctl_deptree._TreeSetCheckState(i, TCB_UNCHECKED);
   }
}

// Loops through the given locations (abs dirs), returning the
// first one that has a file named location+pathSuffix.
_str check_locations_for(_str pathSuffix, _str locations[])
{
   rv               := '';

   foreach (auto loc in locations) {
      if (file_exists(loc:+pathSuffix)) {
         rv = loc;
         break;
      }
   }

   return rv;
}

/** 
 * Where is the gradle we're supposed to use installed? 
 */
_str gradle_install_location() 
{
   _str rv = def_gradle_home;

   if (rv == '') {
      rv = get_env('GRADLE_HOME');
      if (rv == '' || !gradle_exe_exists(rv)) {
         _str locations[] =  _isUnix() ? unix_paths : windows_paths;
         rv = check_locations_for(gradle_exe_relpath(), locations);
      }

      if (rv == '') {
         rv = path_search('gradle'GRADLE_WRAPPER_EXTENSION(), 'PATH', 'P');
         if (rv!='') {
            rv=_strip_filename(rv,'N');
            if (_last_char(rv)==FILESEP || _last_char(rv)==FILESEP2) {
               // Assume it's the some kind of "bin" dir to be stripped
               rv=substr(rv,1,length(rv)-1);
               rv=_strip_filename(rv,'N');
               if (_last_char(rv)==FILESEP || _last_char(rv)==FILESEP2) {
                  rv=substr(rv,1,length(rv)-1);
               }
            }
         }
      }
   }

   return rv;
}

static bool is_importing_gradle_build()
{
   importing := _WorkspaceGet_EnvironmentVariable(gWorkspaceHandle, 
                                                  'SE_IMPORTING_WORKSPACE');
   return importing == '1';
}

static bool gradle_wrapper_exists()
{
   wsdir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(wsdir);
   return file_exists(wsdir'gradlew'GRADLE_WRAPPER_EXTENSION());
}

static bool curproj_needs_gradle_home()
{
   wsdir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(wsdir);

   has_wrapper := gradle_wrapper_exists();

   if (has_wrapper) {
      // Just because there's a wrapper file, that doesn't mean that 
      // we're using it.  Take a peek at the project execute task, and
      // see if it's using the wrapper.
      _ProjectGet_ActiveConfigOrExt(_project_name, auto handle, auto config);
      tnode := _ProjectGet_TargetNode(handle, 'Build', config);
      if (tnode >=0 ) {
         cmd := _ProjectGet_TargetCmdLine(handle, tnode);
         has_wrapper = pos('gradlew'GRADLE_WRAPPER_EXTENSION(), cmd) > 0;
      }
   }

   return !has_wrapper;
}

// Sets environment variables used inside of project files for gradle projects.
// Returns 0 on success.
int setup_gradle_environment()
{
   rv := 1;
   gh := gradle_install_location();
   pt := _ProjectGet_Type(_ProjectHandle(), 'Release');
   if (curproj_needs_gradle_home()) {
      if (gh == '') {
         // Not set yet for this configuration.
         prompt_for_gradle_home();
         gh = def_gradle_home;
      }
      if (pt == 'android') {
         // We don't care about the gh one way or another, so we are succesful.
         rv = 0;
      }

      if (gh != '') {
         set_env('SE_GRADLE_HOME', gh);
         _restore_origenv(false);
         set('SE_GRADLE_HOME='gh);
         rv = 0;
      }
   } else {
      // Project doesn't need gradle home set, so we can't fail.
      rv = 0;
   }

   set_env('SE_GRADLE_TEST_PARAMS', gUnitTestSubset);
   set('SE_GRADLE_TEST='gUnitTestSubset);

   set_env('SE_GRADLE_WRAPPER_EXT', GRADLE_WRAPPER_EXTENSION());
   set('SE_GRADLE_WRAPPER_EXT=' :+ GRADLE_WRAPPER_EXTENSION());

   _ProjectGet_ActiveConfigOrExt(_project_name, auto handle, auto config);
   targetNode := _ProjectGet_TargetNode(handle, "Execute", config);
   if (targetNode != -1 && pos('SLICKEDIT_GRADLE_UNPACKED_ARGS', _ProjectGet_TargetCmdLine(handle, targetNode)) != 0) {
      // For newer versions of Gradle, we can pass the arguments on the command line.
      uargs := '';
      dArgs := currentDebugArguments();
      if (dArgs != '') {
         uargs = dArgs;
         clearDebugArguments();
      } else {
         uargs = unpack_commandline_arguments(_ProjectGet_TargetOtherOptions(handle, targetNode));
      }
      if (uargs != '') {
         uargs = ' --args="'uargs'"';
      }
      set_env('SLICKEDIT_GRADLE_UNPACKED_ARGS', uargs);
      set('SLICKEDIT_GRADLE_UNPACKED_ARGS='uargs);
   } else {
      packedArgs := '';
      dArgs := currentDebugArguments();
      if (dArgs != '') {
         clearDebugArguments();
         packedArgs = pack_commandline_arguments(dArgs);
      } else {
         if (targetNode != -1) {
            packedArgs = _ProjectGet_TargetOtherOptions(handle, targetNode);
         }
      }
      set_env('SLICKEDIT_GRADLE_EXEC_ARGS', packedArgs);
      set('SLICKEDIT_GRADLE_EXEC_ARGS='packedArgs);
   }

   if (pt == "java") {
      // For the java plugin, we need to set JAVA_HOME to point to the correct java. 
      // You can't set the java version like you can say for Kotlin with the kotlin plugin.
      cname := _ProjectGet_ActualCompilerConfigName(handle, config, 'java');
      if (cname != "" && cname != COMPILER_NAME_NONE) {
         cfgFile := _ConfigPath():+COMPILER_CONFIG_FILENAME;
         if (!refactor_config_is_open(cfgFile)) {
            refactor_config_open(cfgFile);
         }

         compiler_root := "";
         status := refactor_config_get_java_source(cname, compiler_root);
         _maybe_strip_filesep(compiler_root);
         if (!status && compiler_root != '') {
            set_env('JAVA_HOME', compiler_root);
            set('JAVA_HOME='compiler_root);
         }
      }
   }

   return rv;
}

int _java_set_environment(int projectHandle, _str config, _str target, 
                          bool quite, _str error_hint)
{
   rv := 0;
   if (_ProjectGet_AppType(projectHandle, config) == 'gradle') {
      rv = setup_gradle_environment();
   }

   return rv;
}

int _android_set_environment(int projectHandle, _str config, _str target, 
                            bool quite, _str error_hint)
{
   rv := 0;
   if (_ProjectGet_AppType(projectHandle, config) == 'gradle') {
      rv = setup_gradle_environment();
   }

   return rv;
}

// Creates the default source dirs for a gradle project that
// uses the Groovy plugin.
void make_build_system_source_dirs(_str projDir)
{
   _str d;

   foreach (d in wizData.special.sourcePaths) {
      mkdir(projDir'/'d);
   }
}

static _str build_system_template(_str lang, _str tmplName)
{
   rv := _getSysconfigPath()'templates/ItemTemplates/'wizData.special.buildSystemName'/'lang'/'tmplName'/'tmplName'.setemplate';
   return rv;
}

static int copy_build_template(_str projDir, _str projType, _str itemName = 'Basic', _str (*options):[] = null)
{
   ctOptions_t params;

   if (options != null) {
      _str k, v;

      foreach (k, v in *options) {
         ctTemplateContent_ParameterValue_t pv;

         pv.Prompt = false;
         pv.PromptString = '';
         pv.Value = v;
         params.Parameters:[k] = pv;
      }
   }

   templatePath := build_system_template(projType, itemName);
   destDir := projDir;
   _str projectName='';
   if (itemName == 'Basic') {
      projectName=_project_name;
   }

   return add_item(templatePath, itemName, destDir, projectName, false, null, params);
}

static int generate_scala_with_main2(_str filename,_str ClassName,_str package,int &linenum) {
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   if (package!='') {
      insert_line('package 'package);
      insert_line('');
   }

   insert_line('object 'ClassName' {');
   insert_line(indentStr'def main(args: Array[String]) {');
   insert_line(indentStrX2);
   linenum=p_line;
   insert_line(indentStr'}');
   insert_line('}');
   int status=_save_file('+o');

   //_AddFileToProject(filename);
   //_param1=filename;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int generate_kotlin_with_main2(_str filename,_str ClassName,_str package,int &linenum) {
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr=indent_string(p_SyntaxIndent);
   if (package!='') {
      insert_line('package 'package);
      insert_line('');
   }
   insert_line('fun main(args: Array<String>) {');
   insert_line(indentStr);
   linenum=p_line;
   insert_line('}');

   int status=_save_file('+o');
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int generate_java_with_main2(_str filename,_str ClassName,_str package,int &linenum) {
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   if (package!='') {
      insert_line('package 'package';');
      insert_line('');
   }

   insert_line('public class 'ClassName' {');
   insert_line(indentStr'public static void main(String[] args) {');
   insert_line(indentStrX2);
   linenum=p_line;
   insert_line(indentStr'}');
   insert_line('}');
   int status=_save_file('+o');

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int generate_groovy_with_main2(_str filename,_str ClassName,_str package,int &linenum) {
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   if (package!='') {
      insert_line('package 'package);
      insert_line('');
   }

   insert_line('class 'ClassName' {');
   insert_line(indentStr'static void main(String[] args) {');
   insert_line(indentStrX2);
   linenum=p_line;
   insert_line(indentStr'}');
   insert_line('}');
   int status=_save_file('+o');

   //_AddFileToProject(filename);
   //_param1=filename;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

// Generates a build init script that tries to download source jars for
// the given artifacts.  Artifacts are in the usual 'group:artifactId:version' format.
// are downloaded for the versions of kotlin we reference. Returns the 
// path to the filename.
static _str generate_source_downloading_init(_str (&artifacts)[])
{
   file := mktemp(1, ".gradle");
   origWid := _create_temp_view(auto tmpWid, '');
   if (origWid == 0) {
      return '';
   }
   p_window_id = tmpWid;
   top();
   _insert_text("allprojects {\n":+
                "  configurations {\n":+
                "    seKotSrc\n":+
                "  }\n":+
                "  dependencies {\n");
   foreach (auto art in artifacts) {
      _insert_text("    seKotSrc \""art":sources\"\n");
   }
   
   _insert_text("  }\n":+
                "  task seEnsureSource {\n":+
                "    doLast {\n":+
                "      configurations.seKotSrc.each { file -> \n":+
                "        println \"$file.path@\"\n":+
                "      }\n":+
                "    }\n":+
                "  }\n":+
                "}\n");

   _save_file(file);
   p_window_id = origWid;
   _delete_temp_view(tmpWid);
   return file;
}

static void generate_gradle_main(_str projDir, _str projType, _str package, _str mainClass) {
   destDir := projDir;

   _maybe_append_filesep(destDir);
   destDir :+= 'src'FILESEP'main'FILESEP:+projType;

   // Generate directory structure for package at location default gradle build file
   // will understand.
   if (package != '') {
      _str p;
      pcs := split2array(package, '.');

      foreach (p in pcs) {
         _maybe_append_filesep(destDir);
         destDir :+= p;
         mkdir(destDir);
      }
   }
   _maybe_append_filesep(destDir);
   ext := projType;
   if (projType == 'kotlin') {
      ext = 'kt';
   }
   filename := destDir:+mainClass".":+ext;

   if (file_exists(filename)) {
      int result=_message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if (result==IDCANCEL) {
         return;
      } 
   }

   int linenum, status;
   if (projType == 'groovy') {
      status=generate_groovy_with_main2(filename,mainClass,package,linenum);
   } else if (projType == 'scala') {
      status=generate_scala_with_main2(filename,mainClass,package,linenum);
   } else if (projType == 'kotlin') {
      status=generate_kotlin_with_main2(filename,mainClass,package,linenum);
   } else {
      status=generate_java_with_main2(filename,mainClass,package,linenum);
   }
   if (!status) {
      status=_mdi.p_child.edit(_maybe_quote_filename(filename));
      if (!status) {
         int child_wid=_mdi.p_child;
         child_wid.p_line=linenum;child_wid._end_line();
      }
   }
}

// Finds the gradle wrapper script to use for the given
// project dir.  If found, builds a relative path from projDir
// to the directory that contains the wrapper script and stores
// it in "relPath".  Returns false if no wrapper is found.
static bool find_gradle_wrapper_script(_str projDir, _str& relPath)
{
   cdir := projDir;
   relPath = '';
   while (cdir._length() > 0) {
      _maybe_append_filesep(cdir);
      if (file_exists(cdir'gradlew'GRADLE_WRAPPER_EXTENSION())) {
         return true;
      }
      cdir = substr(cdir, 1, cdir._length()-1);
      slPos := lastpos(FILESEP, cdir);
      if (slPos < 1) {
         return false;
      }
      cdir = substr(cdir, 1, slPos - 1);
      relPath :+= '..' :+ FILESEP;
   }

   return false;
}

// Uses project expansions if forProjectFile is true.
_str wiz_gradle_exe(bool useWrapper, bool forProjectFile = true, GradleWizData* wd = null)
{
   _str path;

   if (useWrapper) {
      find_gradle_wrapper_script(wizData.projectDir, auto relPath);
      if (forProjectFile) {
         path = '"%rw'relPath'gradlew'GRADLE_WRAPPER_EXTENSION()'"';
      } else {
         path = '"'wizData.projectDir :+ relPath :+ 'gradlew'GRADLE_WRAPPER_EXTENSION()'"';
      }
   } else {
      if (forProjectFile) {
         path = '"%(SE_GRADLE_HOME)'FILESEP'bin'FILESEP'gradle'GRADLE_WRAPPER_EXTENSION()'"';
      } else {
         path = '"'wizData.selectedGradleHome'bin'FILESEP'gradle'GRADLE_WRAPPER_EXTENSION()'"';
      }
   }

   return path;
}

static bool wiz_wrapper_exists()
{
   return file_exists(wizData.projectDir'gradlew'GRADLE_WRAPPER_EXTENSION());
}

static _str first_group()
{
   return  get_text(match_length('1'), match_length('S1'));
}

static _str gradle_err(_str msg)
{
   return msg'  See Output window for error logs.';
}


// Extracts dependency information from the output of 
// Gradle's 'dependencies' command.
static int parse_dependencies(int tempView)
{
   wizData.dependencies._makeempty();
   p_line = 0;
   for (; down() == 0;) {
      get_line(auto line);
      if (line == '') {
         continue;
      }

      status := pos('^[|+\\\- ]+([^:]+):([^:]+):(.*$)', line, 1, 'L');
      if (status > 0) {
         MavenDependency dep;

         dep.groupId = substr(line, pos('S1'), pos('1'));
         dep.artifactId = substr(line, pos('S2'), pos('2'));
         dep.version = substr(line, pos('S3'), pos('3'));

         // Some versions have some noise trailing after a space, like "1.2.3 (*)".  Cut that out.
         sppos := pos(' ', dep.version);
         if (sppos > 0) {
            dep.version = substr(dep.version, 1, sppos-1);
         }

         if (dep.groupId != '' && dep.artifactId != '' && dep.version != '') {
            wizData.dependencies:[maven_get_dep_key(dep)] = dep;
         } 
      }
   }

   return 0;
}

static int new_parse_tasks(int tmpView, _str (&allTasks)[])
{
   bool tmptasks:[]; 
   orig_wid := p_window_id;
   p_window_id = tmpView;
   top();
   rc = search('^([a-zA-Z0-9:][a-zA-Z0-9:-_]+)(:?$| - )', '+@L>');
   while (rc == 0) {
      tname := first_group();
      tmptasks:[tname] = true;
      rc = search('^([a-zA-Z0-9:][a-zA-Z0-9:-_]+)(:?$| - )', '+@L>');
   }
   
   allTasks._makeempty();
   foreach (auto k, auto v in tmptasks) {
      allTasks :+= k;
   }
   allTasks._sort();

   p_window_id = orig_wid;
   return 0;
}

static int extract_compiler_versions(int tmpView, bool (&subProjNames):[], _str (&buildVers):[], _str &errMsg)
{
   rc := 0;
   orig_wid := p_window_id;
   p_window_id = tmpView;

   do {
     top(); 
     rc = search('^Root project', '>@L');
     rootProjName := wizData.implicitProjName;
     if (rc != 0 && subProjNames._length() == 0) {
        // In this case, this project is the sub-project of 
        // another project. Extract the name so we can treat it
        // as the root project.
        top();
        rc = search("^Project '?:(.*)'?$", '>@L');
        if (rc != 0) {
           errMsg = 'Could not find gradle project.';
           break;
        }
        rootProjName = first_group();
     } 

     rc = search('^classpath', '>@L');
     if (rc == 0) {
        down();
        get_line(auto ln);
        if (!beginsWith(ln, 'No dependencies')) {
           rc = search('org.jetbrains.kotlin:kotlin-stdlib:([^ ]+)$', '>@L');
           if (rc == 0) {
              buildVers:[rootProjName] = first_group();
           }
        }
     }

     typeless i;
     for (i._makeempty();;) {
        subProjNames._nextel(i);
        if (i._isempty()) break;
        top();
        rc = search("^Project '?:"i"'?$", '>@L');
        if (rc != 0) continue;

        rc = search('^classpath', '>@L');
        if (rc != 0) continue;
        down();
        get_line(auto ln);
        if (!beginsWith(ln, 'No dependencies')) {
           rc = search('org.jetbrains.kotlin:kotlin-stdlib:([^ ]+)$', '>@L');
           if (rc == 0) {
              buildVers:[':'i] = first_group();
           }
        }
     }

     // These entries are optional, so not finding one isn't an error.
     rc = 0;
   } while (false);

   p_window_id = orig_wid;
   return rc;
}

static int extract_project_dirs(GradleWizData* wd, int tmpView, bool (&subProjNames):[], _str (&projDirMap):[], _str& errMsg)
{
   orig_wid := p_window_id;
   p_window_id = tmpView;

   do {
      top();
      rc = search('^Root project', '>@L');
      rootProjName := '';
      if (rc != 0 && subProjNames._length() == 0) {
         // In this case, this project is the sub-project of 
         // another project. Extract the name so we can treat it
         // as the root project.
         top();
         rc = search("^Project '?:(.*)'?$", '>@L');
         if (rc != 0) {
            errMsg = 'Could not find gradle project.';
            break;
         }
         rootProjName = first_group();
      } else if (rc == 0) {
         rc = search('name: (.*)$', '>@L');
         if (rc != 0) {
            errMsg = 'Could not find root project name:'rc;
            break;
         }
         rootProjName = first_group();
      }

      if (rc != 0 || rootProjName == '') {
         errMsg = 'Could not find any root project name:'rc;
         break;
      }

      rc = search('^projectDir: (.*)$', '>@L');
      if (rc != 0) {
         errMsg = 'Could not find project dir for root project.';
         break;
      }
      projDirMap:[rootProjName] = first_group();

      typeless i;
      for (i._makeempty();;) {
         subProjNames._nextel(i);
         if (i._isempty()) break;
         top();
         rc = search("^Project '?:"i"'?$", '>@L');
         if (rc != 0) {
            errMsg = 'Could not find properties for project 'i;
            break;
         }
         rc = search('^projectDir: (.*)$', '>@L');
         if (rc != 0) {
            errMsg = 'Could not find project dir for project 'i;
            break;
         }
         projDirMap:[':'i] = first_group();
      }
   } while (false);

   p_window_id = orig_wid;
   return rc;
}

// Adds only the tasks runnable from the given project to the tasks
// array in ``gpi``.
static void extract_tasks_for_project(GradleProjectInfo& gpi, _str (&allTasks)[])
{
   _str t;
   bool set:[];

   if (gpi.isRootProject) {
      // Root project sees all known commands, and can execute them, sending the
      // command to all sub-projects that implement the command.
      foreach (t in allTasks) {
         // allTasks should always have the fully qualified tasks now, so
         // we need to un-qualify them.
         if (t != 'Rules') {
            // False match we get when a gradle file has rules defined.
            set:[':'t] =true;
            colpos := lastpos(':', t);
            if (colpos > 1) {
               // If it's qualified, we could also run it as an unqualified
               // task from the root project.
               set:[substr(t, colpos+1)] = true;
            }
         }
      }
   } else {

      // Sub project - just the command that are specific to the sub-project.
      foreach (t in allTasks) {
         set:[':'t] = true;
         if (beginsWith(t, gpi.name)) {
            // This command is in or under this project, so also 
            // provide a un-qualified task name that means "run this task
            // for this project, and any sub-projects that support it".
            colpos := lastpos(':', t);
            set:[substr(t, colpos +1)] = true;
         }
      }
   }

   foreach (auto k, auto v in set) {
      gpi.tasks :+= k;
   }
   gpi.tasks._sort();
}

static bool gradle_ver_at_least(int majv, int minv)
{
   if (wizData.toolMajVer > majv) {
      return true;
   }

   if (majv == wizData.toolMajVer && wizData.toolMinVer >= minv) {
      return true;
   }

   return false;
}

static int parse_gradle_version(int tempView)
{
   origView := p_window_id;
   p_window_id = tempView;
   top();
   rc = search('^Gradle ([0-9]+\.[0-9]+)', '>@L');
   if (rc != 0) {
      return rc;
   }

   _str pcs[];
   ver := first_group();
   split(ver, '.', pcs);
   if (pcs._length() == 0) {
      return DATA_ERROR_RC;
   }
   if (!isinteger(pcs[0])) {
      return CMRC_BAD_LENGTH;
   }
   wizData.toolMajVer = (int)pcs[0];

   if (pcs._length() > 1) {
      if (!isinteger(pcs[1])) {
         return CMRC_BAD_LENGTH;
      }
      wizData.toolMinVer = (int)pcs[1];
   } else {
      wizData.toolMinVer = 0;
   }

   return 0;
}

static _str command_for_all_projects(bool (&subProjNames):[], _str cmd)
{
   cmdstring := cmd' ';
   typeless i;
   for (i._makeempty();;) {
      subProjNames._nextel(i);
      if (i._isempty()) break;
      cmdstring :+= i :+ ':'cmd' ';
   }
   return cmdstring;
}

static int new_get_project_info(GradleWizData* wd)
{
   daemon := ''; // ' --no-daemon';
   wd->allProjects._makeempty();
   useExistingWrapper := wizData.useGradleWrapper && find_gradle_wrapper_script(wizData.projectDir, auto notused);
   capbase := 'Working: ';
   progress := progress_show(capbase, 300);


   progress.p_caption = capbase'version';
   cmdline := wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(wizData.buildFilePath) :+ '--version';
   rc := exec_command_to_temp_view(cmdline, auto tempView, auto origView, progress, 50);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err('Error invoking gradle: 'rc), 'SlickEdit', MB_OK|MB_ICONSTOP);
      return rc;
   }
   progress_set(progress, 50);
   rc = parse_gradle_version(tempView);
   p_window_id = origView;
   _delete_temp_view(tempView);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err('Error invoking gradle: 'rc), 'SlickEdit', MB_OK|MB_ICONSTOP);
      return rc;
   }
  
   // Run check to force dependencies to download, so we can prefer source
   // jars for dependencies if they are available.
   progress.p_caption = capbase'downloading binary dependencies';
   cmdline = wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(wizData.buildFilePath) :+ daemon' check';
   rc = exec_command_to_temp_view(cmdline, tempView, origView, progress, 50);
   progress_set(progress, 100);
   p_window_id = origView;
   _delete_temp_view(tempView);

   // The tasks command we always want to run from the root project, because
   // we need to see tasks for all of the projects, not just the active ones.
   rootBuild := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(rootBuild);
   rootBuild :+= 'build.gradle';

   progress.p_caption = capbase'tasks';
   cmdline = wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(rootBuild) :+ daemon' tasks --all';
   rc = exec_command_to_temp_view(cmdline, tempView, origView, progress, 50);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err('Error invoking gradle: 'rc), 'SlickEdit', MB_OK|MB_ICONSTOP);
      return rc;
   }
   progress_set(progress, 150);

   _str allTasks[];

   allTasks._makeempty();
   rc = new_parse_tasks(tempView, allTasks);
   p_window_id = origView;
   _delete_temp_view(tempView);
   if (rc != 0) return rc;

   bool subProjNames:[];
   _str tname;

   foreach (tname in allTasks) {
      idx := lastpos(':', tname);
      if (idx > 1) {
         subProjNames:[substr(tname, 1, idx-1)] = true;
      }
   }

   // Extract dependencies for possible use by tagging.
   progress.p_caption = capbase'resolving dependencies';
   cmdline = wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(rootBuild) :+ ' 'command_for_all_projects(subProjNames, 'dependencies');
   rc = exec_command_to_temp_view(cmdline, tempView, origView, progress, 50);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err('Error invoking gradle: 'rc), 'SlickEdit', MB_OK|MB_ICONSTOP);
      return rc;
   }
   progress_set(progress, 200);
   parse_dependencies(tempView);
   p_window_id = origView;
   _delete_temp_view(tempView);

   cmdstring := command_for_all_projects(subProjNames, 'properties');
   cmdline = wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(rootBuild) :+ daemon' 'cmdstring;
   rc = exec_command_to_temp_view(cmdline, tempView, origView, progress, 50);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err('Error invoking gradle props: 'rc));
      return rc;
   }
   progress_set(progress, 250);
   refresh('W');

   _str projDirs:[];

   rc = extract_project_dirs(wd, tempView, subProjNames, projDirs, auto errMsg);
   p_window_id = origView;
   _delete_temp_view(tempView);
   if (rc != 0) {
      progress_close(progress);
      _message_box(gradle_err(errMsg': 'rc));
      return rc;
   }

   needBuildEnv := wizData.projectType == 'kotlin';
   _str buildVers:[];
   typeless i;
   if (needBuildEnv) {
      cmdstring = command_for_all_projects(subProjNames, 'buildEnvironment');
      cmdline = wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(rootBuild) :+ daemon' 'cmdstring;
      rc = exec_command_to_temp_view(cmdline, tempView, origView, progress, 50);
      if (rc != 0) {
         progress_close(progress);
         _message_box(gradle_err('Error invoking gradle buildEnvironment: 'rc));
         return rc;
      }
      progress_set(progress, 300);
      refresh('W');

      rc = extract_compiler_versions(tempView, subProjNames, buildVers, errMsg);
      p_window_id = origView;
      _delete_temp_view(tempView);
      if (rc != 0) {
         progress_close(progress);
         _message_box(gradle_err(errMsg': 'rc));
         return rc;
      }

      // Not all projects will have build/compiler versions, 
      // but if the root project does, projects that are not
      // specified inherit that version.
      rootVersion := '';
      vp := buildVers._indexin(wizData.implicitProjName);
      if (vp) {
         rootVersion = *vp;
      }
      if (rootVersion != '') {
         for (i._makeempty();;) {
            projDirs._nextel(i);
            if (i._isempty()) break;
            if (!buildVers._indexin(i) || buildVers:[i] == '') {
               buildVers:[i] = rootVersion;
            }
         }
      }
   }                    

   for (i._makeempty();;) {
      projDirs._nextel(i);
      if (i._isempty()) break;
      GradleProjectInfo gpi;

      gpi.isRootProject = !beginsWith(i, ':', true);
      if (gpi.isRootProject) {
         gpi.name = i;
      } else {
         gpi.name = substr(i, 2);  // Strip off leading ':'.
      }
      gpi.dir = projDirs:[i];
      bv := buildVers._indexin(i);
      if (bv) {
         gpi.compilerVer = *bv;
      } else {
         gpi.compilerVer = '';
      }
      extract_tasks_for_project(gpi, allTasks);
      wd->allProjects :+= gpi;
   }

   progress_close(progress);
   return 0;
}

static int find_root_project(GradleProjectInfo (&infs)[])
{
   i := 0;
   for (; i < infs._length(); i++) {
      if (infs[i].isRootProject) {
         return i;
      }
   }

   return -1;
}

static int find_project_by_name(_str name)
{
   for (i := 0; i < wizData.allProjects._length(); i++) {
      if (wizData.allProjects[i].name == name) {
         return i;
      }
   }

   return -1;
}

static void populate_tasks(GradleWizData* wd, GradleProjectInfo& inf)
{
   wd->knownTasks._makeempty();
   _str t;
   foreach (t in inf.tasks) {
      wd->knownTasks :+= t;
   }
}

int load_known_tasks(GradleWizData* wd)
{
   // Temporarily update def_gradle_home with the gradle home selected by the user.
   curGradleHome := def_gradle_home;

   rc := new_get_project_info(wd);
   if (rc < 0) {
      return rc;
   }

   rootIdx := find_root_project(wd->allProjects);
   if (rootIdx < 0) {
      return FILE_NOT_FOUND_RC;
   }
   populate_tasks(wd, wd->allProjects[rootIdx]);

   // Restore home, so we won't persist this change if the user
   // cancels out of the wizard.
   def_gradle_home = curGradleHome;
   wizData.parsedTasks = true;
   return 0;
}

static int gradle_paths_create()
{
   _nocheck _control _ctl_gradle_home;
   _nocheck _control _ctl_gradlewrapper;
   _nocheck _control _browsedir1;

   load_workspace_persistent_settings(auto useWrapperCheckState);

   _ctl_gradle_home.p_text = wizData.guessedGradleHome;
   _ctl_gradlewrapper.p_value = (int)(useWrapperCheckState && find_gradle_wrapper_script(wizData.projectDir, auto notUsed));
   wizData.useGradleWrapper = _ctl_gradlewrapper.p_value != 0;

   sizeBrowseButtonToTextBox(_ctl_gradle_home.p_window_id, 
                             _browsedir1.p_window_id, 0, 
                             _ctl_gradle_home.p_active_form.p_width);
   return 0;
}

static int gradle_select_create()
{
   _nocheck _control _ctl_gradle_home;
   _nocheck _control _ctl_gradlewrapper;
   _nocheck _control _browsedir1;

   _ctl_gradle_home.p_text = wizData.guessedGradleHome;
   _ctl_gradlewrapper.p_visible = false;

   sizeBrowseButtonToTextBox(_ctl_gradle_home.p_window_id, 
                             _browsedir1.p_window_id, 0, 
                             _ctl_gradle_home.p_active_form.p_width);
   return 0;
}

static void update_paths_state(typeless dummy = null)
{
   _nocheck _control _ctl_gradle_home;
   _nocheck _control _ctl_home_error;
   homedir := strip(_ctl_gradle_home.p_text);

   if (wizData.importing && wizData.special.buildSystemName == 'Gradle') {
      _ctl_gradle_home.p_enabled = _ctl_gradlewrapper.p_value == 0;
   }

   if (call_index(homedir, wizData.special.validBuildSystemPath)) {
      _ctl_home_error.p_visible = false;
   } else {
      _ctl_home_error.p_caption = "* '"homedir"' is not a valid "wizData.special.buildSystemName" install";
      _ctl_home_error.p_visible = true;
   }
}

void _ctl_gradle_home.on_change()
{
   update_paths_state();
}

_str gen_gradle_execute_task()
{
   suffix := '';
   if (wizData.projectType == 'kotlin') {
      // If the file with main() in it is named XXX, then 
      // the class that gets generated is XXXKt.
      suffix = 'Kt';
   }
   rv :=  "task execute(type: JavaExec) {\n   classpath=sourceSets.main.runtimeClasspath\n   main=\"";

   if (wizData.mainPackage != '') {
      rv :+= wizData.mainPackage;
      _maybe_append(rv, '.');
   }
   rv :+= wizData.mainClass;
   rv :+= suffix;
   rv :+= "\"\n";
   rv :+= '   args = System.getenv("SLICKEDIT_GRADLE_EXEC_ARGS")?.tokenize(' :+ "'\\1') ?: []";
   return rv"\n}\n";
}

static int gradle_select_next()
{
   rv := 1;
   update_paths_state();
   homedir := strip(_ctl_gradle_home.p_text);
   if (call_index(homedir, wizData.special.validBuildSystemPath)) {
      rv = 0;
      wizData.selectedGradleHome = homedir;
      _maybe_append_filesep(wizData.selectedGradleHome);
   }

   return rv;
}

static int gradle_paths_next() 
{
   _nocheck _control _ctl_gradle_home;
   _nocheck _control _ctl_gradlewrapper;
   _nocheck _control _ctl_home_error;
   int               rv;

   update_paths_state();

   homedir := strip(_ctl_gradle_home.p_text);
   if (call_index(homedir, wizData.special.validBuildSystemPath)) {
      wizData.selectedGradleHome = homedir;
      _maybe_append_filesep(wizData.selectedGradleHome);
      wizData.useGradleWrapper = (_ctl_gradlewrapper.p_value != 0);

      if (!call_index(wizData.projectDir, wizData.special.buildFileExists)) {
         // Make sure this exists, because next step will be extracting task 
         // names the build file.
         _str params:[];

         if (wizData.generatingMain) {
            params:['executetask'] = call_index(&wizData, wizData.special.executeTask);
         } else {
            params:['executetask'] = '';
         }

         rv = copy_build_template(wizData.projectDir, wizData.projectType, 'Basic', 
                                   &params);
         make_build_system_source_dirs(wizData.projectDir);
      } else {
         rv = 0;
      }

      if (rv == 0 && !wizData.parsedTasks) {
         rv = call_index(&wizData, wizData.special.loadKnownTasks);
      }
   } else {
      rv = 1;
   }

   return rv;
}

static int gradle_paths_show()
{
   _nocheck _control ctllabel1;
   ctllabel1.p_caption = wizData.special.buildSystemName' Home';

   if (wizData.special.buildSystemName != 'Gradle') {
      _nocheck _control _ctl_gradlewrapper;

      _ctl_gradlewrapper.p_value = 0;
      _ctl_gradlewrapper.p_visible = false;
   }
   update_paths_state();
   return 0;
}

void _ctl_gradlewrapper.lbutton_up()
{
   if (wizData.importing && wizData.special.buildSystemName == 'Gradle') {
      _ctl_gradle_home.p_enabled = _ctl_gradlewrapper.p_value == 0;
      // Keep this in sync, some code will check this when this
      // page is not active.
      wizData.useGradleWrapper = _ctl_gradlewrapper.p_value != 0;
      update_paths_state();
   }
}

static _str unpack_commandline_arguments(_str args, bool useQuotes = true)
{
   _str aar[];
   split(args, _UTF8Chr(1), aar);
   int i;
   rv := '';
   for (i = 0; i < aar._length(); i++) {
      x := aar[i];
      if (pos(' ', x) != 0 || x._length() == 0) {
         if (useQuotes) {
            x = '"'x'"';
         } else {
            x = stranslate(x, "\\ ", " ");
         }
      }
      rv :+= x' ';
   }

   return strip(rv);
}

// Gets the relative path of the directory for the given dependency.
static _str get_artifact_rel_path(MavenDependency dep)
{
   return dep.groupId:+FILESEP:+dep.artifactId:+FILESEP:+dep.version;
}

// Returns TCB_CHECKED if the dependency is already represented in array paths to 
// dependency jars, `files`.
static int check_status(_str (&files)[], MavenDependency dep)
{
   depstr := get_artifact_rel_path(dep):+FILESEP;
   foreach (auto wc in files) {
      if (pos(depstr, wc) != 0) {
         return TCB_CHECKED;
      }
   }
   return TCB_UNCHECKED;
}

static int gradle_deps_create() 
{
   if (wizData.dependencies._length() == 0) {
      // If we're being called by the update-project-dependencies command, 
      // we won't have this data yet, so load it.
      rc := new_get_project_info(&wizData);
      if (rc != 0) {
         return rc;
      }
   }

   wizData.flatDeps._makeempty();

   // Extract current dependency set.
   _str wildcards[]; wildcards._makeempty();

   handle := _ProjectHandle(_project_name, auto status);
   get_jar_dependencies(handle, wildcards);

   ctl_deptree._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Artifact");
   ctl_deptree._TreeSetColButtonInfo(1,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Group");
   ctl_deptree._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Version");
   ctl_deptree._TreeAdjustLastColButtonWidth();

   ctl_deptree._TreeBeginUpdate(TREE_ROOT_INDEX);
   foreach (auto key => auto dep in wizData.dependencies) {
      leaf := ctl_deptree._TreeAddItem(TREE_ROOT_INDEX, dep.artifactId"\t"dep.groupId"\t"dep.version, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      ctl_deptree._TreeSetUserInfo(leaf, wizData.flatDeps._length());
      wizData.flatDeps :+= dep;
      ctl_deptree._TreeSetCheckable(leaf, 1, 0, check_status(wildcards, dep));
   }

   ctl_deptree._TreeEndUpdate(TREE_ROOT_INDEX);

   return 0;
}

static int project_idx_for_cur_project()
{
   dir := _strip_filename(_project_name, 'N');
   _maybe_strip_filesep(dir);
   for (i := 0; i < wizData.allProjects._length(); i++) {
      if (dir == wizData.allProjects[i].dir) {
         return i;
      }
   }

   return -1;
}

// Returns the gradle task name of the execute build target, if any.
// Returns '' if not found.
static _str extract_execute_gradle_task(int ph)
{
   rv := '';
   curConfig := GetCurrentConfigName();

   rc := _xmlcfg_find_simple(ph, "/Project/Config[@Name='"curConfig"']/Menu/Target[@Name='Execute']");
   if (rc >= 0) {
      enode := _xmlcfg_find_child_with_name(ph, rc, 'Exec');
      if (enode >= 0) {
         cmdline := _xmlcfg_get_attribute(ph, enode, 'CmdLine', '');
         exst := pos('-b "[^"]+" ([^ ]+)', cmdline, 1, 'L');
         if (exst > 0) {
            rv = substr(cmdline, pos('S1'), pos('1'));
         }
      }
   }

   return rv;
}

static int gradle_tasks_create() 
{
   _nocheck _control _ctl_execute_task;

   handle := _ProjectHandle(_project_name, auto status);
   if (wizData.parsedTasks) {
      pi := project_idx_for_cur_project();
      selectedTarget := extract_execute_gradle_task(handle);

      if (pi >= 0) {
         _ctl_execute_task.p_cb_list_box._lbadd_item(NO_EXEC_TASK);
         _ctl_execute_task.p_cb_list_box._lbselect_line();
         foreach (auto l in wizData.allProjects[pi].tasks) {
            _ctl_execute_task.p_cb_list_box._lbadd_item(l);
            if (wizData.generatingMain && (l == selectedTarget || (selectedTarget == '' && (l == 'execute' || l == 'run')))) {
               _ctl_execute_task.p_cb_list_box._lbselect_line();
            }
         }

         _ctl_menu_tasks._TreeUncheckAll();
         foreach (l in wizData.allProjects[pi].tasks) {
            idx := _ctl_menu_tasks._TreeAddListItem(l);
            cstate := (_ProjectDoes_TargetExist(handle, l)) ? TCB_CHECKED : TCB_UNCHECKED;
            _ctl_menu_tasks._TreeSetCheckable(idx, 1, 0, cstate);
         }
      }
   }
   execTarg := _ProjectGet_TargetNode(handle, "execute");
   if (execTarg > 0) {
      args := _ProjectGet_TargetOtherOptions(handle, execTarg);
      ctl_exec_args.p_text = unpack_commandline_arguments(args);
   } else {
      ctl_exec_args.p_text = '';
   }

   return 0;
}

// Takes a command line string like '"arg 1" arg2'
// and packs it into the format we use to pass the information
// to gradle.
static _str pack_commandline_arguments(_str txt)
{
   i := 1;
   pc := '';
   rv := '';
   for (pc = _pos_parse_wordsep(i, txt, ' '); pc != null; pc = _pos_parse_wordsep(i, txt, ' ')) {
      rv :+= pc;
      rv :+= _UTF8Chr(1);
   }
   if (rv._length() > 0) {
      rv = substr(rv, 1, rv._length() - 1);
   }

   return rv;
}

static int save_tasks_settings()
{
   et := _ctl_execute_task.p_cb_list_box.p_text;

   if (et == NO_EXEC_TASK) {
      wizData.execTaskName = "";
   } else {
      wizData.execTaskName = et;
   }

   int info;
   index := _ctl_menu_tasks._TreeGetNextCheckedIndex(1, info);

   wizData.exposedTaskNames._makeempty();
   while (index >= 0) {
      wizData.exposedTaskNames[wizData.exposedTaskNames._length()] = _ctl_menu_tasks._TreeGetCaption(index);
      index = _ctl_menu_tasks._TreeGetNextCheckedIndex(0, info);
   }
   wizData.execTaskArgs = pack_commandline_arguments(ctl_exec_args.p_text);

   return 0;
}

static _str gradle_cfg_dir()
{
   rv := '';
   if (_isWindows()) {
      rv = get_env('USERPROFILE');
   } else {
      rv = get_env('HOME');
   }

   if (rv != '') {
      _maybe_append_filesep(rv);
      rv :+= '.gradle'FILESEP;
   }
   return rv;
}

static _str resolve_jar_path(_str gradle_cfg, MavenDependency dep, JarPreference prefer)
{
   // There can be source jars in the maven repo that lives in the android Sdk, so
   // check there first.
   rv := '';
   if (wizData.projectType == 'android' && wizData.sdk != '') {
      path := wizData.sdk'extras'FILESEP'android'FILESEP'm2repository'FILESEP;
      rv = resolve_cache_jar_path(maven_get_cache_path(dep, path), dep, prefer);
   }
   if (rv == '') {
      // Check gradle cache.
      rv = resolve_cache_jar_path(gradle_cfg:+get_artifact_rel_path(dep):+FILESEP, dep, prefer);
   }

   return rv;
}

static int save_deps_settings()
{
   MavenDependency depset:[];
   int info;
   tindex := ctl_deptree._TreeGetNextCheckedIndex(1, info);

   // Make a set of checked dependencies, with no duplicates.
   depset._makeempty();
   while (tindex >= 0) {
      dindex := ctl_deptree._TreeGetUserInfo(tindex);
      dep := wizData.flatDeps[dindex];
      depset:[dep.groupId':'dep.artifactId':'dep.version] = dep;
      tindex = ctl_deptree._TreeGetNextCheckedIndex(0, info);
   }

   // Try to get source versions of dependencies where possible.
   _str artifacts[]; artifacts._makeempty();
   _str depPaths[]; 

   foreach (auto key => auto dep in depset) {
      artifacts :+= dep.groupId':'dep.artifactId':'dep.version;
   }
   prog := progress_show('Updating source jars...', 100);
   load_source_jar_paths(prog, 100, artifacts, depPaths);  // We don't look at the paths, but this forces the jars to be present.
   progress_close(prog);

   // Make sure we know where the jar files live.
   modroot := gradle_cfg_dir();
   if (modroot == '' || !file_exists(modroot)) {
      _message_box("Can't find gradle config dir.");
      return FILE_NOT_FOUND_RC;
   }
   modroot :+= 'caches'FILESEP'modules-2'FILESEP'files-2.1'FILESEP;

   handle := _ProjectHandle(_project_name, auto status);
   remove_existing_jar_dependencies(handle);

   // Add the new dependencies to the folder.
   _str tagJars[]; tagJars._makeempty();
   foreach (dep in depset) {
      path :=resolve_jar_path(modroot, dep, PREFER_SRC);
      if (path == '') {
         message('could not resolve 'get_artifact_rel_path(dep));
         continue;
      }

      if (endsWith(path, '.aar')) {
         // Android AAR files have the classes we'd like to tag in a classes.jar file.
         path :+= FILESEP'classes.jar';
      }

      tagJars :+= path;
   }
   add_dependency_jar_files(handle, tagJars);

   // We need to save a separate list of just binary jars for all dependencies, so we can hand these off to RTE when it is enabled.
   list := get_cleared_rte_deps_node();
   if (list >= 0) {
      foreach (dep in wizData.flatDeps) {
         path := resolve_jar_path(modroot, dep, PREFER_BINARY);
         n := _xmlcfg_add(gWorkspaceHandle, list, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(gWorkspaceHandle, n, 'Name', RTE_DEP_NAME);
         _xmlcfg_add_attribute(gWorkspaceHandle, n, 'Value', path);
      }
      _WorkspaceSave(gWorkspaceHandle);
   }

   _ProjectSave(handle);
   _project_refresh();
   rteSetClassPath(handle, gradle_project_classpath(handle));

   return 0;
}

// Callback from RTE where we can build a classpath from
// all of the dependency jars.
_str gradle_project_classpath(int hProject)
{
   return build_rte_classpath_from_workspace();
}

static int do_nothing()
{
   return 0;
}

static bool aGradleTarget(int projHand, int targHand)
{
   rv := false;

   exec := _xmlcfg_find_simple(projHand, 'Exec', targHand);
   if (exec >= 0) {
      cmdline := _xmlcfg_get_attribute(projHand, exec, 'CmdLine', '');
      rv = (pos('gradle', cmdline) != 0) || (pos('sbt', cmdline) != 0);
   }

   return rv;
}

static _str maybe_specify_buildfile_flag(_str buildFileName, bool projDirPrefix = false)
{
   if (file_exists(buildFileName)) {
      prefix := '';
      if (projDirPrefix) {
         prefix = '%rw';
      }
      return ' -b "'prefix :+ buildFileName'" ';
   }
   return ' ';
}

_str gradle_invocation_params(_str cmd, _str buildFileName)
{
   if (cmd == 'unittest') {
      // run the test target for unit-tests, and be sure to include
      // our test listener so we have results understandable to
      // the unittest module.
      return maybe_specify_buildfile_flag(buildFileName, true)' -I "'testListenerPath()'" cleanTest test %(SE_GRADLE_TEST_PARAMS)';
   }

   exectask := extract_execute_gradle_task(_ProjectHandle());
   if (exectask == '') {
      exectask = 'execute';
   }

   if ((cmd == exectask || beginsWith(cmd, exectask)) && gradle_ver_at_least(4, 9)) {
      return maybe_specify_buildfile_flag(buildFileName, true) :+ cmd :+ " %(SLICKEDIT_GRADLE_UNPACKED_ARGS)";
   }
   return maybe_specify_buildfile_flag(buildFileName, true) :+ cmd;
}

static _str mk_gradle_cmdline(_str gradleExe, _str gradleTaskName, _str buildFileName)
{
   return gradleExe:+call_index(gradleTaskName, buildFileName, wizData.special.buildSystemInvocationParams);
}

static void merge_target(int projHandle, int targ, _str caption, _str gradleExe, _str gradleTaskName, _str buildFileName)
{
   exec := _xmlcfg_find_child_with_name(projHandle, targ, 'Exec');
   if (exec >= 0) {
      _xmlcfg_set_attribute(projHandle, exec, 'CmdLine', mk_gradle_cmdline(gradleExe, gradleTaskName, buildFileName));
   }
}

static void add_target(int projHandle, int menuNode, _str caption, _str gradleExe, _str gradleTaskName, _str buildFileName)
{
   targ := _xmlcfg_add(projHandle, menuNode, 'Target', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   if (targ < 0) {
      return;
   }

   _xmlcfg_add_attribute(projHandle, targ, 'Name', caption);
   _xmlcfg_add_attribute(projHandle, targ, 'MenuCaption', 'Gradle 'caption);
   _xmlcfg_add_attribute(projHandle, targ, 'CaptureOutputWith', 'ProcessBuffer');
   _xmlcfg_add_attribute(projHandle, targ, 'RunFromDir', '%rw');
   if (strieq(caption,'build')) _xmlcfg_add_attribute(projHandle, targ, 'SaveOption', 'SaveWorkspaceFiles');
   if (strieq(caption,'debug')) _xmlcfg_add_attribute(projHandle, targ, 'BuildFirst', '1');
   if (strieq(caption, 'unittest')) {
      _xmlcfg_add_attribute(projHandle, targ, 'PreMacro', 'unittest_pre_build');
      _xmlcfg_add_attribute(projHandle, targ, 'ClearProcessBuffer', '1');
      _xmlcfg_add_attribute(projHandle, targ, 'ShowOnMenu', 'Never');
      _xmlcfg_add_attribute(projHandle, targ, 'BuildFirst', '0');

   }

   exec := _xmlcfg_add(projHandle, targ, 'Exec', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (exec < 0) {
      return;
   }

   _xmlcfg_add_attribute(projHandle, exec, 'CmdLine', mk_gradle_cmdline(gradleExe, gradleTaskName,buildFileName));
   if (strieq(caption, 'execute')) {
      _xmlcfg_add_attribute(projHandle, exec, "OtherOptions", wizData.execTaskArgs);
   }
}

static void update_project_targets(_str gradleExe)
{
   ph := _ProjectHandle();
   bfn := _strip_filename(wizData.buildFilePath, 'P');

   if (ph >= 0) {
      _str configs[];

      _xmlcfg_find_simple_array(ph, '/Project/Config', configs);

      int cfg;
      foreach (cfg in configs) {
         _str existingTargets[];

         menuH := _xmlcfg_find_simple(ph, 'Menu', cfg);
         if (menuH < 0) {
            menuH = _xmlcfg_add(ph, cfg, 'Menu', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
            if (menuH < 0) {
               message('Could not create Menu tag');
               continue;
            }
         }

         _xmlcfg_find_simple_array(ph, 'Menu/Target', existingTargets, cfg);

         // Collect just the records of the existing gradle targets, so 
         // we know whether to create a new one, or merge changes to an existing
         // one.
         int targ;
         int existing_gradle_targs:[]; existing_gradle_targs._makeempty();
         foreach (targ in existingTargets) {
            if (aGradleTarget(ph, targ) && _xmlcfg_get_attribute(ph, targ, 'Deletable', '1') != '0') {
               key := lowcase(_xmlcfg_get_attribute(ph, targ, 'Name', ''));
               existing_gradle_targs:[key] = targ;
            }
         }

         _str task;
         addedExecTasks := false;

         if (wizData.execTaskName != '') {
            etask := existing_gradle_targs._indexin('execute');
            if (etask) {
               merge_target(ph, *etask, 'Execute', gradleExe, wizData.execTaskName, bfn);
               *etask = -1;
            } else {
               add_target(ph, menuH, 'Execute', gradleExe, wizData.execTaskName, bfn);
            }
            
            if (wizData.special.addDebugTask) {
               dtask := existing_gradle_targs._indexin('debug');
               if (dtask) {
                  merge_target(ph, *dtask, 'Debug', gradleExe, wizData.execTaskName' --debug-jvm', bfn);
                  *dtask = -1;
               } else {
                  add_target(ph, menuH, 'Debug', gradleExe, wizData.execTaskName' --debug-jvm', bfn);
               }
            }
            addedExecTasks = true;
         }

         if (wizData.special.buildSystemName == 'Gradle') {
            uttask := existing_gradle_targs._indexin('unittest');
            if (uttask) {
               merge_target(ph, *uttask, 'UnitTest', gradleExe, 'unittest', bfn);
               *uttask = -1;
            } else {
               add_target(ph, menuH, 'UnitTest', gradleExe, 'unittest', bfn);
            }
         }

         foreach (task in wizData.exposedTaskNames) {
            ctask := _Capitalize(task);
            if (!addedExecTasks || (ctask != 'Execute' && ctask != 'Debug')) {
               targent := existing_gradle_targs._indexin(lowcase(task));
               if (targent) {
                  merge_target(ph, *targent, ctask, gradleExe, task, bfn);
                  *targent = -1;  // Mark as referenced, so it doesn't get deleted.
               } else {
                  add_target(ph, menuH, ctask, gradleExe, task, bfn);
               }
            }
         }

         // Delete any targets not included in exposedTaskNames.
         foreach (auto tkey => auto tnode in existing_gradle_targs) {
            if (tnode >= 0) {
               _xmlcfg_delete(ph, tnode, false);
            }
         }

      }
   }
   _ProjectSave(ph);
}

static _str SourceWildcards[] = {
   '*.scala', 
   '*.java', 
   '*.js', 
   '*.kt*', 
   '*.groovy', 
   '*.gvy', 
   '*.gy', 
   '*.gradle' 
};

static _str AndSourceWildcards[] = {
   "*.c",
   "*.cpp",
   "*.xml", 
   "*.cfg",
   "*.properties", 
   "*.png", 
   "*.apk", 
   "*.dex",  // double check, not sure if there are still dex files.
   "*.prop",
   "*.jni", 
   "*.jar"
};

// Returns true if this is one of the wildcards the gradle module set up 
// when the project was created/imported.
static bool se_created_wildcard(int projHandle, int node)
{
   wc := _xmlcfg_get_attribute(projHandle, node, 'N');
   if (wc == '') return false;

   foreach (auto swc in SourceWildcards) {
      if (swc == wc) return true; 
   }

   if (wizData.projectType == 'android') {
      foreach (swc in AndSourceWildcards) {
         if (swc == wc) return true; 
      }
   }
   return false;
}

// Removes the wildcard file entries we supply in the current project, 
// leaving any user-added wildcards alone.
static void remove_project_sourcefiles(int ph)
{
   _str nodes[]; nodes._makeempty();

   if (def_gradle_debug > 0) say('remove_project_sourcefiles '_project_name);
   folder := _xmlcfg_find_simple(ph, "/Project/Files[@AutoFolders='PackageView']");

   if (folder < 0) {
      if (def_gradle_debug > 0) say('   find folder err 'folder);
      return;
   }

   rc := _xmlcfg_find_simple_array(ph, '//F', nodes, folder);
   if (rc < 0) {
      if (def_gradle_debug > 0) say('   find nodes err 'get_message(rc));
      return;
   }

   foreach (auto nd in nodes) {
      node := (int)nd;
      if (se_created_wildcard(ph, node)) {
         _xmlcfg_delete(ph, node);
      }
   }
}

static void add_source_files_to_project(int projIndex)
{
   pdir := wizData.allProjects[projIndex].dir;
   _maybe_append_filesep(pdir);

   exclude := '';
   int i;

   wkparent := _strip_filename(_workspace_filename, 'N');
   if (endsWith(wkparent, FILESEP)) {
      wkparent = substr(wkparent, 1, wkparent._length() - 1);
   }
   // We call absolute here to resolve symlinks.  The project directories gathered
   // from gradle are resolved to their 'real' location, so we need to do the same here, 
   // otherwise the call to 'relative()' below will produce paths not usable for the excludes 
   // list.
   wkparent = absolute(wkparent, null, true);
   if (def_gradle_debug > 0) say('add_source_files_to_project 'projIndex' 'wizData.allProjects[projIndex].dir' ('_project_name')');
   for (i = 0; i < wizData.allProjects._length(); i++) {
      if (i == projIndex || wizData.allProjects[i].isRootProject) continue;
      if (!beginsWith(wizData.allProjects[i].dir, pdir, true)) continue;
      if (exclude != '') {
         exclude :+= ';';
      }

      wkRel := relative(wizData.allProjects[i].dir, pdir);
      _maybe_append_filesep(wkRel);
      relPath := wkRel;
      _maybe_append_filesep(relPath);
      exclude :+= relPath;
   }
   if (wizData.projectType == 'android') {
      if (exclude != '') {
         exclude :+= ';';
      }
      exclude :+= '.gradle/;.idea/;build/;gradle/;.externalNativeBuild/';
   }

   if (def_gradle_debug > 0) say('  exclude='exclude);
   ph := _ProjectHandle();
   if (def_gradle_debug > 0) say('   ph = '_xmlcfg_get_filename(ph));
   remove_project_sourcefiles(ph);
   _str wild;
   foreach (wild in SourceWildcards) {
      _ProjectAdd_Wildcard(ph, wild, exclude, true, false);
   }

   if (wizData.projectType == 'android') {
      foreach (wild in AndSourceWildcards) {
         _ProjectAdd_Wildcard(ph, wild, exclude, true, false);
      }
   }

   if (wizData.projectType == 'kotlin') {
      // Stash compiler and library source information in the project file, where
      // auto tagging can use it.
      root := _ProjectGet_ConfigNode(ph, wizData.configName);
      list := _xmlcfg_add(ph, root, 'List', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(ph, list, 'Name', 'KotlinVersion');
      src := '';
      foreach (src in wizData.allProjects[projIndex].libSource) {
         n := _xmlcfg_add(ph, list, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(ph, n, 'Name', 'SourceJar');
         _xmlcfg_add_attribute(ph, n, 'Value', src);
      }
      ver := _xmlcfg_add(ph, list, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(ph, ver, 'Name', 'Version');
      _xmlcfg_add_attribute(ph, ver, 'Value', wizData.allProjects[projIndex].compilerVer);
   }
   _ProjectSave(ph);
}

static int apply_select_settings()
{
   rv := 1;

   if (call_index(wizData.selectedGradleHome, wizData.special.validBuildSystemPath)) {
      call_index(wizData.selectedGradleHome, wizData.special.setBuildSystemHome);
      rv = 0;
   }

   return rv;
}

const GR_PERSIST_NAME = "GradleOptions";
const GR_WRAPPER_NAME = "UseWrapper";

// We need so save some preferences for the workspace.
// Expects wizData to be filled out.
static void load_workspace_persistent_settings(bool& useWrapperCheckState)
{
   if (gWorkspaceHandle < 0) {
      return;
   }

   lst := _xmlcfg_find_simple(gWorkspaceHandle, "/Workspace/List[strieq(@Name,'" :+ GR_PERSIST_NAME :+ "')]");
   if (lst < 0) {
      useWrapperCheckState = find_gradle_wrapper_script(wizData.projectDir, auto relPath);
   } else {
      if (wizData.projectType == 'android') {
         // non negotiable.
         useWrapperCheckState = true;
      } else {
         wropt := _xmlcfg_find_simple(gWorkspaceHandle, "Item[strieq(@Name, '" :+ GR_WRAPPER_NAME :+ "')]", lst);
         if (wropt < 0) {
            useWrapperCheckState = find_gradle_wrapper_script(wizData.projectDir, auto relPath);
         } else {
            useWrapperCheckState = _xmlcfg_get_attribute(gWorkspaceHandle, wropt, 'Value', '1') == '1';
         }
      }
   }
}

static void save_workspace_persistent_settings(bool useWrapperCheckState)
{
   if (gWorkspaceHandle < 0) {
      return;
   }

   wsnode := _xmlcfg_find_simple(gWorkspaceHandle, "Workspace");
   if (wsnode < 0) {
      return;
   }
   lst := _xmlcfg_find_simple(gWorkspaceHandle, "List[strieq(@Name, '" :+ GR_PERSIST_NAME :+ "')]", wsnode);
   if (lst >= 0) {
      _xmlcfg_delete(gWorkspaceHandle, lst);
   }
   lst = _xmlcfg_add(gWorkspaceHandle, wsnode, 'List', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(gWorkspaceHandle, lst, 'Name', GR_PERSIST_NAME);

   wropt := _xmlcfg_add(gWorkspaceHandle, lst, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(gWorkspaceHandle, wropt, 'Name', GR_WRAPPER_NAME);
   _xmlcfg_add_attribute(gWorkspaceHandle, wropt, 'Value', useWrapperCheckState ? '1' : '0');

   _WorkspaceSave(gWorkspaceHandle);
}

/**
 * Nested sub-projects have ':' in their name, but we don't want 
 * to have that in a filename.  So we remap it here.  In the 
 * future, we may go from flat project display to moving the 
 * project into a hierarchy that matches the directory 
 * structure, and then we'll just be stripping off the prefix 
 * here.  (the issue is how it looks in the tree, there's no 
 * problem with a name clash, as the vpj file is put in the 
 * gradle project directory). 
 */
static _str remap_prj_name(_str name)
{
   _str rv;

   rpos := lastpos(':', name);
   if (rpos >= 1) {
      rv = substr(name, rpos+1);
   } else {
      rv = name;
   }
   return rv;
}

static int create_all_subprojects()
{
   int i;
   wizData.execTaskName = ''; // Inhibit creating exec task for sub-projects.
   wizData.exposedTaskNames._makeempty();
   wizData.exposedTaskNames :+= 'Build'; // Force re-creation of build tasks to match wrapper setup.
   if (def_gradle_debug > 0) say('create_all_subprojects()');
   for (i = 0; i < wizData.allProjects._length(); i++) {
      if (def_gradle_debug > 0) say('  checking 'i' 'wizData.allProjects[i].dir);
      if (wizData.allProjects[i].isRootProject) continue;
      if (def_gradle_debug > 0) say('   subproject 'wizData.allProjects[i].name', 'wizData.allProjects[i].dir);
      prjName := wizData.allProjects[i].dir; _maybe_append_filesep(prjName);
      remappedPrj := remap_prj_name(wizData.allProjects[i].name);
      prjName :+= remappedPrj'.vpj';

      // If a sub-project is being added by the new projects wizard, the project
      // file will already exist with the right template, so we don't need to create anything.
      // There won't be a project if this is an import of a gradle project with sub-projects.
      if (!file_exists(prjName)) {
         prjTmp := '';
         if (wizData.projectType == 'android') {
            prjTmp = 'Android - Application';
         } else {
            prjTmp = guess_gradle_project_template_type(wizData.allProjects[i].dir);
         }
         if (def_gradle_debug > 0) say('   template='prjTmp);
         rc := workspace_new_project(false, prjTmp, remappedPrj, wizData.allProjects[i].dir, true, 
                                     remappedPrj, '', false, false);
         // Sanity check - is the project what we think it is?
         if (_strip_filename(_project_name, 'P') != remappedPrj'.vpj') {
            if (def_debug_android > 0) say('  project not opened? '_project_name' is not the right name.');
            rc = FILE_NOT_FOUND_RC;
         }
         if (def_gradle_debug > 0) say('  new project='rc);
         if (rc != 0) {
            return rc;
         }
      } else {
         rc :=_ProjectOpen(prjName);
         if (rc < 0) {
            if (def_debug_android > 0) say('   could not open existing? 'prjName', 'get_message(rc));
         }
      }

      pdir := wizData.allProjects[i].dir;
      _maybe_append_filesep(pdir);
      add_source_files_to_project(i);

      if (wizData.projectType == 'android') {
         _android_project_setup(false);

         // There's already a unittest menu entry, we just need to update it with the correct command
         // so the JUnit support works with android.
         handle := _ProjectHandle(_project_name);
         wrapper := '%wpgradlew%(SE_GRADLE_WRAPPER_EXT)';
         utdbg := _ProjectGet_TargetNode(handle, 'unittest', 'Debug');
         _ProjectSet_TargetCmdLine(handle, utdbg, wrapper' 'gradle_invocation_params('unittest', wizData.buildFilePath));

         utrls := _ProjectGet_TargetNode(handle, 'unittest', 'Release');
         _ProjectSet_TargetCmdLine(handle, utrls, wrapper' 'gradle_invocation_params('unittest', wizData.buildFilePath));
         _ProjectSave(handle);
      } else {
         wizData.projectDir = wizData.allProjects[i].dir;
         useGradleWrapper := wizData.useGradleWrapper && find_gradle_wrapper_script(wizData.projectDir, auto notUsed);
         update_project_targets(wiz_gradle_exe(useGradleWrapper, true));
      }
   }
   if (def_gradle_debug > 0) say('create_all_subprojects() done');
   return 0;
}

void save_gradle_home(_str path)
{
   def_gradle_home = path;
}

// Uses some trickery to get gradle to load the source jars for artifacts, and 
// returns the paths to the jars found that way.
static void load_source_jar_paths(CTL_FORM progress, int progCount, _str (&artifacts)[], _str (&paths)[])
{
   // Generate init file that adds our code for forcing source dependencies and listing them.
   fname := generate_source_downloading_init(artifacts);
   if (fname == '') {
      return;
   }

   useExistingWrapper := wizData.useGradleWrapper && find_gradle_wrapper_script(wizData.projectDir, auto notused);
   cmdline := wiz_gradle_exe(useExistingWrapper, false) :+ maybe_specify_buildfile_flag(wizData.buildFilePath) :+ ' -I '_maybe_quote_filename(fname)' :seEnsureSource';
   rc := exec_command_to_temp_view(cmdline, auto tempView, auto origView, progress, progCount);
   if (rc != 0) {
      return;
   }
   p_window_id = tempView;
   paths._makeempty();
   top();
   for (; down() == 0; ) {
      get_line(auto line);
      line = strip(line);
      if (!endsWith(line, '@')) continue;
      paths :+= substr(line, 1, length(line)-1);
   }
   p_window_id = origView;
   _delete_temp_view(tempView);
   delete_file(fname);

   return;
}

static int apply_wizard_settings()
{
   if (def_gradle_debug > 0) say('apply_wizard_settings()');
   save_workspace_persistent_settings(wizData.useGradleWrapper);

   needWrapper := wizData.useGradleWrapper && !wiz_wrapper_exists();
   frm := progress_show(needWrapper ? "Generating "wizData.special.buildSystemName" wrapper" : "Updating project", 33);
   
   if (needWrapper) {
      // Go ahead and generate the wrapper.
      cmdline := wiz_gradle_exe(false, false) :+ maybe_specify_buildfile_flag(wizData.buildFilePath) :+ ' wrapper';
      //shell(cmdline, 'Q');
      rc := exec_command_to_window(cmdline, output_window_text_control(), -1, frm, 10);
      if (rc < 0) {
         return rc;
      }
   }

   progress_set(frm, 30);

   call_index(wizData.selectedGradleHome, wizData.special.setBuildSystemHome);

   useGradleWrapper := wizData.useGradleWrapper && find_gradle_wrapper_script(wizData.projectDir, auto notUsed);
   exeToUse := call_index(useGradleWrapper, true, &wizData, wizData.special.buildSystemExePath);

   if (wizData.projectType != 'android') {
      update_project_targets(exeToUse);
   }

   if (wizData.generatingMain && wizData.shouldGenerateFiles && !wizData.importing) {
      generate_gradle_main(wizData.projectDir, wizData.projectType, wizData.mainPackage, wizData.mainClass);
      progress_increment(frm);
      refresh('W');
   }

   if (wizData.shouldImportFiles) {
      idx := find_root_project(wizData.allProjects);
      if (idx < 0) {
         // Not all wizards do multiproject work.
         if (def_gradle_debug > 0) say('  single project');
         GradleProjectInfo pi;

         pi.dir = wizData.projectDir;
         pi.isRootProject = true;
         wizData.allProjects :+= pi;
         idx = 0;
      } else {
         if (def_gradle_debug > 0) say('  root='wizData.allProjects[idx].dir' 'wizData.allProjects[idx].name'.vpj');
      }
      if (wizData.projectType == 'android') {
         _android_project_setup(true);
      }
      add_source_files_to_project(idx);
      _project_update_files_retag(_project_name, false, false, false, true, false, true, true, false, true);
      progress_increment(frm);
      refresh('W');
   }

   progress_increment(frm);
   progress_close(frm);

   return 0;
}

static void pick_project_update()
{
   if (_ctl_project_withmain.p_value != 0) {
      _ctl_class_box.p_enabled = true;
      if (_ctl_main_class_name.p_text == '') {
         _ctl_class_error.p_caption = 'Class name is a required field.';
         _ctl_class_error.p_visible = true;
      } else {
         _ctl_class_error.p_visible = false;
      }
   } else {
      _ctl_class_box.p_enabled = false;
      _ctl_class_error.p_visible = false;
   }
   _ctl_class_box.p_enabled = (_ctl_project_withmain.p_value != 0); 
}

void _ctl_main_class_name.on_change()
{
   pick_project_update();
}

void _ctl_project_empty.lbutton_up()
{
   pick_project_update();
}

void _ctl_project_withmain.lbutton_up()
{
   pick_project_update();
}

static int gradle_pick_project_type()
{
   _ctl_project_withmain.p_value = 1;
   pick_project_update();
   return 0;
}

static int save_project_type()
{
   pick_project_update();
   if (!_ctl_class_error.p_visible) {
      wizData.generatingMain = (_ctl_project_withmain.p_value != 0);
      if (wizData.generatingMain) {
         wizData.mainClass = _ctl_main_class_name.p_text;
         wizData.mainPackage = _ctl_main_class_package.p_text;
      }
   }
   return _ctl_class_error.p_visible ? 1 : 0;
}

static int start_gradle_wizard(_str caption)
{
   WIZARD_INFO info;

   info.callbackTable._makeempty();
   
   info.callbackTable:["ctlslide0.create"] = gradle_pick_project_type;
   info.callbackTable:["ctlslide0.shown"] = do_nothing;
   info.callbackTable:["ctlslide0.next"] = save_project_type;
   info.callbackTable:["ctlslide0.skip"] = wizData.importing ? 1 : 0;

   info.callbackTable:["ctlslide1.create"] = gradle_paths_create;
   info.callbackTable:["ctlslide1.shown"] = gradle_paths_show;
   info.callbackTable:["ctlslide1.next"] = gradle_paths_next;
   info.callbackTable:["ctlslide1.skip"] = null;

   info.callbackTable:["ctlslide2.create"] = gradle_tasks_create;
   info.callbackTable:["ctlslide2.shown"] = do_nothing;
   info.callbackTable:["ctlslide2.next"] = save_tasks_settings;
   info.callbackTable:["ctlslide2.skip"] = null;

   info.callbackTable:["ctlslide3.create"] = gradle_deps_create;
   info.callbackTable:["ctlslide3.shown"] = do_nothing;
   info.callbackTable:["ctlslide3.next"] = save_deps_settings;
   info.callbackTable:["ctlslide3.skip"] = wizData.special.buildSystemName != 'Gradle';

   info.callbackTable:["finish"] = apply_wizard_settings;
   info.parentFormName = "_gradle_project_wizard_form";
   info.dialogCaption = caption;

   return _Wizard(&info);
}

static int start_tagdep_wizard(_str caption)
{
   WIZARD_INFO info;

   info.callbackTable._makeempty();
   
   info.callbackTable:["ctlslide0.create"] = do_nothing;
   info.callbackTable:["ctlslide0.shown"] = do_nothing;
   info.callbackTable:["ctlslide0.next"] = do_nothing;
   info.callbackTable:["ctlslide0.skip"] = 1;

   info.callbackTable:["ctlslide1.create"] = do_nothing;
   info.callbackTable:["ctlslide1.shown"] = do_nothing;
   info.callbackTable:["ctlslide1.next"] = do_nothing;
   info.callbackTable:["ctlslide1.skip"] = 1;

   info.callbackTable:["ctlslide2.create"] = do_nothing;
   info.callbackTable:["ctlslide2.shown"] = do_nothing;
   info.callbackTable:["ctlslide2.next"] = do_nothing;
   info.callbackTable:["ctlslide2.skip"] = 1;

   info.callbackTable:["ctlslide3.create"] = gradle_deps_create;
   info.callbackTable:["ctlslide3.shown"] = do_nothing;
   info.callbackTable:["ctlslide3.next"] = save_deps_settings;
   info.callbackTable:["ctlslide3.skip"] = 0;

   info.callbackTable:["finish"] = do_nothing;
   info.parentFormName = "_gradle_project_wizard_form";
   info.dialogCaption = caption;

   return _Wizard(&info);
}

static _str build_file_name()
{
   rv := 'build.gradle';

   if (gWorkspaceHandle >= 0) {
      ev := _WorkspaceGet_EnvironmentVariable(gWorkspaceHandle, GRADLE_BUILD_FILE);
      if (ev != '') {
         rv = ev;
      }
   }

   return rv;
}

bool gradle_build_file_exists(_str projDir)
{
   _maybe_append_filesep(projDir);
   return file_exists(projDir :+ build_file_name());
}

/**
 * Assumes the project is already open.  Opens a dialog to 
 * prompt the user for gradle settings. 
 */
int setup_build_system_proj(_str configName, ProjectWizardSpecializations& spec, bool importFiles = true, bool generateFiles = true)
{
   int     handle       = _ProjectHandle();

   wizData.configName = configName;
   wizData.projectDir = _file_path(_project_name);
   wizData.implicitProjName = _strip_filename(wizData.projectDir, 'P');
   wizData.wrapperFilePath = wizData.projectDir'gradlew'GRADLE_WRAPPER_EXTENSION();
   wizData.guessedGradleHome = spec.guessedBuildSystemHome;
   wizData.projectType = _ProjectGet_Type(handle, configName);
   wizData.knownTasks._makeempty();
   wizData.parsedTasks = false;
   wizData.importing = call_index(wizData.projectDir, spec.buildFileExists);
   wizData.mainPackage = '';
   wizData.mainClass = 'Main';
   wizData.generatingMain = false;
   wizData.shouldImportFiles = importFiles;
   wizData.shouldGenerateFiles = generateFiles;
   wizData.special = spec;

   if (wizData.projectType == 'android') {
      _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto target, false);
      wizData.sdk = sdk;
   }

   bfn := build_file_name();
   wizData.buildFilePath = wizData.projectDir :+ bfn;

   if (!wizData.importing) {
      // This is already set in the importing case in wkspace.e, we want to set 
      // it for the new project case.
      _WorkspaceSet_EnvironmentVariable(gWorkspaceHandle, GRADLE_BUILD_FILE, bfn);
   }

   title := "Create "wizData.special.buildSystemName" Project";

   if (!wizData.shouldGenerateFiles) {
      title = "Configure "wizData.special.buildSystemName" Project "_project_name;
   } else if (wizData.importing) {
      title = "Import "wizData.special.buildSystemName" Project";
   }

   clear_output_window();
   rv := start_gradle_wizard(title);

   if (rv == 0) {
      _DebugUpdateMenu();
   }

   return rv;
}

static void gradle_specializations(ProjectWizardSpecializations& spec)
{
   spec.addDebugTask = true;
   spec.buildFileExists = find_index('gradle_build_file_exists', PROC_TYPE);
   spec.buildSystemExePath = find_index('wiz_gradle_exe', PROC_TYPE);
   spec.buildSystemInvocationParams = find_index('gradle_invocation_params', PROC_TYPE);
   spec.buildSystemName = 'Gradle';
   spec.executeTask = find_index('gen_gradle_execute_task', PROC_TYPE);
   spec.guessedBuildSystemHome = gradle_install_location();
   spec.loadKnownTasks = find_index('load_known_tasks', PROC_TYPE);
   spec.setBuildSystemHome = find_index('save_gradle_home', PROC_TYPE);
   spec.sourcePaths._makeempty();
   spec.sourcePaths :+= 'src';
   spec.sourcePaths :+= 'src/main';
   spec.sourcePaths :+= 'src/main/groovy';
   spec.sourcePaths :+= 'src/main/java';
   spec.sourcePaths :+= 'src/main/resources';
   spec.sourcePaths :+= 'src/main/scala';
   spec.sourcePaths :+= 'src/main/kotlin';
   spec.sourcePaths :+= 'src/test';
   spec.sourcePaths :+= 'src/test/groovy';
   spec.sourcePaths :+= 'src/test/java';
   spec.sourcePaths :+= 'src/test/resources';
   spec.sourcePaths :+= 'src/test/scala';
   spec.sourcePaths :+= 'src/test/kotlin';
   spec.validBuildSystemPath = find_index('maybe_valid_gradle_home_path', PROC_TYPE);
}

static populate_android_wizdata(ProjectWizardSpecializations spec)
{
   wizData.configName = 'Debug';
   wizData.projectDir = _file_path(_project_name);
   wizData.implicitProjName = _strip_filename(wizData.projectDir, 'P');
   wizData.wrapperFilePath = wizData.projectDir'gradlew'GRADLE_WRAPPER_EXTENSION();
   wizData.guessedGradleHome = spec.guessedBuildSystemHome;
   wizData.selectedGradleHome = spec.guessedBuildSystemHome;
   _maybe_append_filesep(wizData.selectedGradleHome);
   wizData.projectType = 'android';
   wizData.knownTasks._makeempty();
   wizData.parsedTasks = false;
   wizData.importing = true;
   wizData.mainPackage = '';
   wizData.mainClass = 'Main';
   wizData.generatingMain = false;
   wizData.shouldImportFiles = true;
   wizData.shouldGenerateFiles = true;
   wizData.special = spec;
   wizData.useGradleWrapper = true;
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto target, false);
   wizData.sdk = sdk;
}

static bool creatingSubprojects = false;
_command int new_gradle_proj(_str configName = 'Release') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (creatingSubprojects) {
      if (def_gradle_debug > 0) say('new_gradle_proj('configName') '_project_name'  doing nothing, creating subprojects');
      return 0;
   }

   if (def_gradle_debug > 0) say('new_gradle_proj('configName') '_project_name);
   ProjectWizardSpecializations spec;

   gradle_specializations(spec);

   rc := 0;
   pt := _ProjectGet_Type(_ProjectHandle(), configName);
   if (def_gradle_debug > 0) say('   type='pt);
   if (pt == 'android') {
      // Don't ask a lot of questions that are implicit to the 
      // android structure, android_project_setup() will fill in the 
      // necessary skeleton in place.
      populate_android_wizdata(spec);
      new_get_project_info(&wizData);
      rc = apply_wizard_settings();
   } else {
      rc = setup_build_system_proj(configName, spec, true, true);
   }

   if (rc == 0) {
      creatingSubprojects = true;
      rc = create_all_subprojects();
      creatingSubprojects = false;
   }
   if (def_gradle_debug > 0) say('new_gradle_proj: done');

   return rc;
}

/**
 * Scans subdirectories of the root build.gradle for the current
 * workspace for new subprojects that don't have an entry in 
 * settings.gradle, and may or may not have a SlickEdit project 
 * yet, and adds them to to settings.gradle, and gives them a 
 * SlickEdit project if non exists. 
 */
_command int add_gradle_subprojects() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   if (def_gradle_debug > 0) say('add_gradle_subprojects() '_project_name);

   wkDir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(wkDir);

   // Find any projects that are in a subdirectory under the root project, 
   // but don't have a entry in settings.gradle.
   _str newProjs[]; newProjs._makeempty();
   match := wkDir' +X';
   subdir := file_match(match, 1);

   while (subdir != '') {
      pBaseName := _strip_filename(_strip_filename(subdir, '/'), 'P');
      if (def_gradle_debug > 0) say('   subdir 'subdir', name='pBaseName'.');
      if (pBaseName != '.' && pBaseName != '..'  && file_exists(subdir'build.gradle') && gradle_project_not_added(wkDir, pBaseName)) {
         newProjs :+= _strip_filename(subdir, '/');
         if (def_gradle_debug > 0) say('   found new project 'subdir);
      }
      subdir = file_match(match, 0);
   }

   if (newProjs._length() == 0) {
      if (def_gradle_debug > 0) say('   nothing to do');
      return 0;
   }

   // Add new projects to settings.gradle first, otherwise any gradle 
   // commands on the sub-projects are not going to work.
   msg := 'Added: ';
   sg := wkDir'settings.gradle';
   rc = _open_temp_view(sg, auto tempWid, auto origWid);
   if (rc < 0) {
      _message_box('Could not open "'sg'". Sub-projects not added.');
      return rc;
   }
   bottom();
   insert_line('');
   foreach (auto pdir in newProjs) {
      pName := _strip_filename(pdir, 'P');
      insert_line("include ':"pName"'");
      msg :+ pName' ';
   }
   save('', SV_OVERWRITE);
   activate_window(origWid);
   _delete_temp_view(tempWid);

   // Finally, everything is in place for the regular initialization of
   // the new subprojects. We need to open the root project so we get all of the
   // information for all sub-projects.
   curProject := _project_name;
   rootProj := _strip_filename(_workspace_filename, 'E')'.vpj';
   rc := _ProjectOpen(rootProj);
   if (rc != 0) {
      _message_box('Could not open root project 'rootProj': 'get_message(rc));
      return rc;
   }
   cd('+p '_strip_filename(rootProj, 'N'));

   ProjectWizardSpecializations spec;
   gradle_specializations(spec);

   pt := _ProjectGet_Type(_ProjectHandle(), GetCurrentConfigName());
   if (def_gradle_debug > 0) say('   type='pt);
   if (pt == 'android') {
      populate_android_wizdata(spec);
   }
   if (def_gradle_debug > 0) say('  cur_project='_project_name', projDir='wizData.projectDir);
   new_get_project_info(&wizData);
   creatingSubprojects = true;
   create_all_subprojects();
   creatingSubprojects = false;

   // The root project needs its wildcards updated, so it doesn't pick up files for
   // the new subproject(s).
   rooti := find_root_project(wizData.allProjects);
   if (rooti >= 0) {
      rc =_ProjectOpen(wizData.allProjects[rooti].dir :+ FILESEP :+ wizData.allProjects[rooti].name'.vpj');
      if (rc < 0) {
         if (def_debug_android > 0) say('  no open root 'get_message(rc));
      } else {
         add_source_files_to_project(rooti);
      }
   } else {
      if (def_debug_android > 0) say('  root project not found?');
   }

   _ProjectOpen(curProject);
   cd('+p '_strip_filename(curProject, 'N'));
   message(msg);
   return 0;
}

/**
 * Starts the gradle project wizard on an existing gradle 
 * project, allowing up to update the settings and tasks that 
 * are exposed to the Build menu. 
 */
_command int reconfigure_gradle_project() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //javaPath=path_search("javac.exe","PATH","P");

   ph := _ProjectHandle();

   if (ph < 0) {
      message("No project is open to be reconfigured.");
      return 0;
   }

   if (_ProjectGet_AppType(ph) != 'gradle') {
      message('Open project is not a Gradle project');
      return 0;
   }

   ProjectWizardSpecializations spec;

   gradle_specializations(spec);
   setup_build_system_proj('Release', spec, false, false);
   return 0;
}

int setup_for_deps(_str configName, ProjectWizardSpecializations& spec, bool importFiles = true, bool generateFiles = true)
{
   int     handle       = _ProjectHandle();

   wizData.configName = configName;
   wizData.projectDir = _file_path(_project_name);
   wizData.implicitProjName = _strip_filename(wizData.projectDir, 'P');
   wizData.wrapperFilePath = wizData.projectDir'gradlew'GRADLE_WRAPPER_EXTENSION();
   wizData.guessedGradleHome = spec.guessedBuildSystemHome;
   wizData.projectType = _ProjectGet_Type(handle, configName);
   wizData.knownTasks._makeempty();
   wizData.parsedTasks = false;
   wizData.importing = false;
   wizData.mainPackage = '';
   wizData.mainClass = 'Main';
   wizData.generatingMain = false;
   wizData.shouldImportFiles = importFiles;
   wizData.shouldGenerateFiles = generateFiles;
   wizData.special = spec;
   wizData.selectedGradleHome = wizData.guessedGradleHome;
   wizData.dependencies._makeempty();  

   if (wizData.projectType == 'android') {
      return 0;
   }

   bfn := build_file_name();
   wizData.buildFilePath = wizData.projectDir :+ bfn;

   title := "Update "wizData.special.buildSystemName" Project Dependencies";
   clear_output_window();
   rv := start_tagdep_wizard(title);

   if (rv == 0) {
      _DebugUpdateMenu();
   }

   return rv;
}

/**
 * Starts just the tagging dependency selection part of the 
 * wizard. 
 * 
 */
_command int update_gradle_tagdeps() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //javaPath=path_search("javac.exe","PATH","P");

   ph := _ProjectHandle();

   if (ph < 0) {
      message("No project is open to be reconfigured.");
      return 0;
   }

   if (_ProjectGet_AppType(ph) != 'gradle') {
      message('Open project is not a Gradle project');
      return 0;
   }

   ProjectWizardSpecializations spec;

   gradle_specializations(spec);
   setup_for_deps('Release', spec, false, false);
   return 0;
}
void prompt_for_gradle_home() 
{
   WIZARD_INFO info;

   info.callbackTable._makeempty();
   
   info.callbackTable:["ctlslide0.create"] = do_nothing;
   info.callbackTable:["ctlslide0.shown"] = do_nothing;
   info.callbackTable:["ctlslide0.next"] = do_nothing;
   info.callbackTable:["ctlslide0.skip"] = 1;

   info.callbackTable:["ctlslide1.create"] = gradle_select_create;
   info.callbackTable:["ctlslide1.shown"] = gradle_paths_show;
   info.callbackTable:["ctlslide1.next"] = gradle_select_next;
   info.callbackTable:["ctlslide1.skip"] = null;

   info.callbackTable:["ctlslide2.create"] = do_nothing;
   info.callbackTable:["ctlslide2.shown"] = do_nothing;
   info.callbackTable:["ctlslide2.next"] = do_nothing;
   info.callbackTable:["ctlslide2.skip"] = 1;

   info.callbackTable:["ctlslide3.create"] = do_nothing;
   info.callbackTable:["ctlslide3.shown"] = do_nothing;
   info.callbackTable:["ctlslide3.next"] = do_nothing;
   info.callbackTable:["ctlslide3.skip"] = 1;

   info.callbackTable:["finish"] = apply_select_settings;
   info.parentFormName = "_gradle_project_wizard_form";
   info.dialogCaption = "Find "wizData.special.buildSystemName" Directory";

   wizData.guessedGradleHome = '';
   gradle_specializations(wizData.special);

   _Wizard(&info);
}

// Runs the unit tests task.  If key is != '', it's taken to be a 
// single test or test suite that should be run.
_command void gradle_run_unittest(_str key = "") name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (key != '') {
      gUnitTestSubset = '--tests "'translate(key, '.', '!')'"';
   }

   _project_command('unittest', '', '');
   gUnitTestSubset = '';
}

_command void gradle_post_unittest() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
  // Pass in a sentinel that lets the post-build code know that 
  // gradle has already run the tests.  It still does the work of
  // setting up the test toolbar tree.
  unittest_post_build('gradle');
  outWindow := _utActivateBuildOrProcessWindow(); 
  startLine := 1;
  unittest_post_test(outWindow' 'startLine);
}

// Called to kick off debugging for the defined unit test command for gradle.
_command int gradle_debug_unittest(_str key='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   handle := 0;
   config := "";
   _ProjectGet_ActiveConfigOrExt(_project_name,handle,config);
   if (handle < 0) {
      message("No open project.");
      return handle;
   }
  targ := _ProjectGet_TargetNode(handle, 'unittest', config);
  if (targ < 0) {
     message('No unittest target found.');
     return targ;
  }
  if (key != '') {
     gUnitTestSubset = '--tests "'translate(key, '.', '!')'"';
  }

  clear_pbuffer();
  unittest_pre_build();
  unittest_post_build('gradle');
  dbcb := _ProjectGet_DebugCallbackName(handle,config);
  if (dbcb == 'jdwp') {
     cmdline := _ProjectGet_TargetCmdLine(handle, targ, true) ' --debug-jvm';
     expandedCmdline := _parse_project_command(cmdline, '', _project_name, '');
     rc := concur_command(expandedCmdline, true);
     if (rc != 0) {
        gUnitTestSubset = '';
        return rc;
     }

     session_name := 'UnitTest: '_project_name;
     attach_info := "host=127.0.0.1,port=5005,session="session_name;
     debug_begin("jdwp", "127.0.0.1", "5005", "", def_debug_timeout);
     debug_go(true);
  } else if (dbcb == 'scaladbgp') {
     scalaDebug := find_index('scala_debug', COMMAND_TYPE);
     if (scalaDebug == 0) {
        message("Couldn't find scala_debug command.");
        gUnitTestSubset = '';
        return COMMAND_NOT_FOUND_RC;
     }
     rc := call_index('{unittest}', scalaDebug);
     if (rc < 0) {
        _message_box('Could not launch scala debugger: 'rc);
        gUnitTestSubset = '';
        return rc;
     }

     // Normally, scala_debug is executed by the build system, 
     // which triggers a _scala_project_command_status callback.
     // Since we called it directly, we need to trigger that callback
     // ourselves.
     projCb := find_index('_scala_project_command_status', PROC_TYPE|COMMAND_TYPE);
     if (projCb == 0) {
        message("Couldn't find project command status command.");
        gUnitTestSubset = '';
        return COMMAND_NOT_FOUND_RC;
     }
     errHint := "";
     return call_index(handle, config, rc, '', 'debug', '', '', 'go', false, errHint, '', '', 
                       projCb);
  }

  gUnitTestSubset = '';
  return 0;
}

// Kick RTE after we build.  This helps the case where a build
// generates a source file that is referenced by the project. Without
// this, any errors due to the missing source would stick around after
// the build, because RTE doesn't know it needs to recompile.
void _postbuild_gradle()
{
   ph := _ProjectHandle();
   if (ph < 0) {
      return;
   }

   if (_ProjectGet_AppType(ph) != 'gradle') {
      return;
   }

   rteForceUpdate();
}


#define GRADLE_UPDATE_DEPENDENCIES "Update Gradle Dependencies"

// If this is an older project that doesn't have a menu entry to update
// just the dependencies of the gradle project.
static void maybe_add_update_menu_entry(int handle)
{
   _str cfgs[];  cfgs._makeempty();
   mh := _xmlcfg_find_simple_array(handle, '/Project/Config', cfgs);
   changed := false;
   foreach (auto cfg in cfgs) {
      ch := (int)cfg;
      menuroot := _xmlcfg_find_simple(handle, 'Menu', ch);
      ment := _xmlcfg_find_simple(handle, "Target[strieq(@Name,'":+GRADLE_UPDATE_DEPENDENCIES:+"')]", menuroot);
      if (ment < 0) {
         changed = true;
         ment = _xmlcfg_add(handle, menuroot, 'Target', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_FIRST_CHILD);
         _xmlcfg_add_attribute(handle, ment, 'Name', GRADLE_UPDATE_DEPENDENCIES);
         _xmlcfg_add_attribute(handle, ment, 'MenuCaption', 'Update Gradle Dependencies');
         _xmlcfg_add_attribute(handle, ment, 'ShowOnMenu', 'HideIfNoCmdLine');
         _xmlcfg_add_attribute(handle, ment, 'Deletable', '0');
         _xmlcfg_add_attribute(handle, ment, 'SaveOption', 'SaveNone');
         ex := _xmlcfg_add(handle, ment, 'Exec', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(handle, ex, 'CmdLine', 'update-gradle-tagdeps');
         _xmlcfg_add_attribute(handle, ex, 'Type', 'Slick-C');
      }
   }
   if (changed) {
      _ProjectSave(handle);
   }
}

void _prjopen_gradle(bool singleFileProject)
{
   if (singleFileProject) return;
   if (!_haveBuild()) {
      return;
   }
   int h = _ProjectHandle();
   if (h) {
      if (pos('Gradle', _ProjectGet_TemplateName(h)) > 0) {
         maybe_add_update_menu_entry(h);
      }
   }
}

