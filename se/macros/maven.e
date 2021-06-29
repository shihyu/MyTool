////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc. 
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
#include "maven.sh"
#include "rte.sh"
#import "diffprog.e"
#import "dir.e"
#import "doscmds.e"
#import "guiopen.e"
#import "help.e"
#import "pipe.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "rte.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "treeview.e"
#import "wizard.e"
#import "wkspace.e"
#import "xmlcfg.e"
#endregion

#define ORIGINAL_EXTERN_DEP_PROJ_NAME "External Tagging Dependencies"
#define EXTERN_DEP_PROJ_NAME "External_Tagging_Dependencies"
#define EXTERN_DEP_PROJ_TEMPLATE "External Dependencies"

// Path to the maven executable to use.  If empty, 
// we assume that the mvn on the PATH is the one we
// should use.
_str def_maven_exe;

static _str maven_exe()
{
   rv := 'mvn'EXTENSION_BATCH;

   if (def_maven_exe != '') {
      rv = def_maven_exe;
   } 

   return rv;
}

// Locates the path for the mvn that will be used, even if it is 
// not specified because it is on the path somewhere.
static _str resolved_mvn_exe()
{
   rv := maven_exe();
   if (rv == '' || !file_exists(rv)) {
      rv = path_search('mvn'EXTENSION_BATCH);
   }
   return rv;
}

static _str maven_cmd(_str params, _str mvnex = '')
{
   if (mvnex == '') {
      mvnex = maven_exe();
   }
   // -B for batchmode to turn off ansi escape sequences.
   return _maybe_quote_filename(mvnex)' -B 'params;
}

static _str maven_repo_root()
{
   rv := '';
   if (_isWindows()) {
      rv = get_env('USERPROFILE');
   } else {
      rv = get_env('HOME');
   }

   if (rv != '') {
      _maybe_append_filesep(rv);
      rv :+= '.m2'FILESEP'repository'FILESEP;
   }

   return rv;
}

_str maven_get_dep_key(MavenDependency dep) {
   return dep.groupId':'dep.artifactId':'dep.version;
}

// Gets the path in the cache that contains (possibly under subdirectories) the jar
// files for `dep`.  Specify overrideRoot for different cache location than the default.
_str maven_get_cache_path(MavenDependency dep, _str overrideRoot = '')
{
   _str rv;
   if (overrideRoot) {
      rv  = overrideRoot;
      _maybe_append_filesep(rv);
   } else {
      rv = maven_repo_root();
   }
   rv :+= stranslate(dep.groupId, FILESEP, '.'):+FILESEP:+dep.artifactId:+FILESEP:+dep.version:+FILESEP;
   return rv;
}

// Given a path the the location in the cache for a given dependency, 
// tries to find the binary or source jar for the dependency.  For maven repositories, 
// use maven_get_cache_path(dep) for the depRoot parameter. Returns '' if no jar was found.
_str resolve_cache_jar_path(_str depRoot, MavenDependency dep, JarPreference prefer)
{
   best := '';
   match := '+T '_maybe_quote_filename(depRoot);
   fn := '';
   for (fn = file_match(match, 1); fn != ''; fn = file_match(match, 0)) {
      _str base = dep.artifactId'-'dep.version;
      _str srcbase = base'-sources';
      _str fb = _strip_filename(_strip_filename(fn, 'P'), 'E');

      if (!endsWith(fn, '.jar') && !endsWith(fn, '.aar')) continue;

      if (fb == base && (best == '' || prefer == PREFER_BINARY)) {
         best = fn;
      } else if (fb == srcbase && (best == '' || prefer == PREFER_SRC)) {
         best = fn;
      }
   }

   return best;
}

_str maven_get_pom_xml_text_value(_str pomXmlFilePath, _str xpathQuery)
{
    valueString := "";
    int xmlStatus;
    int xmlHandle = _xmlcfg_open(pomXmlFilePath, xmlStatus, VSXMLCFG_OPEN_ADD_PCDATA);
    if(xmlHandle > 0) {
        // Look for the node and get the text value
        int foundNode = _xmlcfg_find_simple(xmlHandle, xpathQuery);
        if(foundNode > 0) {
            int textNode = _xmlcfg_get_first_child(xmlHandle, foundNode);
            if(textNode > 0) {
                valueString = _xmlcfg_get_value(xmlHandle, textNode);
            }
        }
        _xmlcfg_close(xmlHandle);
    }

    return valueString;
}

_str maven_get_artifact_name(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/artifactId');
}

_str maven_get_artifact_version(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/version');
}

_str maven_get_artifact_packaging(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/packaging');
}

_str maven_get_project_name(_str pomXmlFilePath)
{
    return maven_get_pom_xml_text_value(pomXmlFilePath,'project/name');
}

//
// Don't mess with me, I'm a wizard.
//
struct MvnWizardData
{
   _str mvn_exe;  // If the user had to select a mvn exe, it will be here.
   MavenDependency globalDeps[];
};

static MvnWizardData gWiz;

static int mvnwiz_select_executable()
{
   _nocheck _control ctl_maven_exe;
   _nocheck _control _browsefile;

   ctl_maven_exe.p_text = gWiz.mvn_exe;
   sizeBrowseButtonToTextBox(ctl_maven_exe.p_window_id, _browsefile.p_window_id, 
                             0, ctl_maven_exe.p_active_form.p_width - ctl_maven_exe.p_x);

   return 0;
}

static int mvnwiz_save_executable()
{
   mpath := strip(ctl_maven_exe.p_text);
   rv := file_exists(mpath) ? 0 : 1;
   if (rv != 0) return rv;
   gWiz.mvn_exe = mpath;

   return 0;
}

static int do_nothing()
{
   return 0;
}

static int apply_wizard_settings()
{
   save_gwiz_preferences();
   def_maven_exe = gWiz.mvn_exe;
   _ProjectSave(_ProjectHandle());
   _project_refresh();
   return 0;
}

#define WIZ_CFG_NAME "MvnCfg"

// Gets the project settings List node, creating it if it doesn't already exist.
static int get_project_settings_node(int handle)
{
   root := _xmlcfg_find_simple(handle, '/Project');
   if (root < 0) {
      message('No project tag?');
      return root;
   }

   lst := _xmlcfg_find_simple(handle, "List[strieq(@Name, '" :+ WIZ_CFG_NAME :+ "')]", root);
   if (lst < 0) {
      lst = _xmlcfg_add(handle, root, 'List', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(handle, lst, 'Name', WIZ_CFG_NAME);
   }

   return lst;
}

static _str lookup_list_value(int handle, int cfgroot, _str name, _str defaultValue)
{
   n := _xmlcfg_find_simple(handle, "Item[strieq(@Name,'"name"')]", cfgroot);
   if (n >= 0) {
      return _xmlcfg_get_attribute(handle, n, 'Value', defaultValue);
   } else {
      return defaultValue;
   }
}

// Initializes gWiz, pulling in any saved settings from the last wizard run.
static void init_gwiz()
{
   gWiz._makeempty();
   handle := _ProjectHandle();
   cfgr := get_project_settings_node(handle);
   if (cfgr < 0) return;

   gWiz.mvn_exe = lookup_list_value(handle, cfgr, 'mvn_exe', resolved_mvn_exe());

   //TODO directly access the mvn_exe item from the project when we need the maven exe, or leave in the def var, and just update it when the project is opened?
   //TODO need dialog to browse files for mvn_exe, not directories.
}

static void create_list_item(int handle, int cfgroot, _str name, _str value)
{
   n := _xmlcfg_add(handle, cfgroot, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if (n >= 0) {
      _xmlcfg_add_attribute(handle, n, 'Name', name);
      _xmlcfg_add_attribute(handle, n, 'Value', value);
   }
}

static void set_list_value(int handle, int cfgroot, _str name, _str value)
{
   n := _xmlcfg_find_simple(handle, "Item[strieq(@Name,'" :+ name :+ "')]", cfgroot);
   if (n >= 0) {
      _xmlcfg_set_attribute(handle, n, 'Value', value);
   } else {
      create_list_item(handle,cfgroot,name,value);
   }
}

int get_cleared_rte_deps_node()
{
   handle := gWorkspaceHandle;
   if (handle < 0) {
      return VSRC_NO_CURRENT_WORKSPACE;
   }

   root := _xmlcfg_find_simple(handle, '/Workspace');
   if (root < 0) {
      return FILE_NOT_FOUND_RC;
   }
   list := _xmlcfg_find_simple(handle, "List[strieq(@Name,'RTEDeps')]", root);
   if (list < 0) {
      list = _xmlcfg_add(handle, root, 'List', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(handle, list, 'Name', 'RTEDeps');
   } else {
      // Get rid of the children, we're rebuilding the list from scratch.
      _xmlcfg_delete(handle, list, true);
   }
   return list;
}

// Returns the handle to the dependency project for the current workspace, 
//  If the project does not exist, then it is created.
// Returns <0 error code on error.
static int extern_dependency_project_handle()
{
   if (_workspace_filename == '') {
      return VSRC_NO_CURRENT_WORKSPACE;
   }

   wsdir := _strip_filename(_workspace_filename, 'N');
   _maybe_append_filesep(wsdir);
   edpname := wsdir :+ EXTERN_DEP_PROJ_NAME :+ PRJ_FILE_EXT;
   old_edpname := wsdir :+ ORIGINAL_EXTERN_DEP_PROJ_NAME :+ PRJ_FILE_EXT;

   // Beta 2 had a different dependency project name than beta 3 and
   // after, so fix that up if we spot it. 
   if (file_exists(old_edpname)) {
      workspace_remove(old_edpname);
      // Don't replace an existing dep project if we have one.
      if (file_exists(edpname)) {
         delete_file(old_edpname);
      } else {
         // Rename the old one so they keep their dependency selections.
         move(_maybe_quote_filename(old_edpname)' '_maybe_quote_filename(edpname));
         _WorkspaceAdd_Project(gWorkspaceHandle, EXTERN_DEP_PROJ_NAME :+ PRJ_FILE_EXT);
         _WorkspaceSave(gWorkspaceHandle);
         toolbarUpdateWorkspaceList();
      }
   }

   rv := 0;
   if (!file_exists(edpname)) {
      orig := _project_name;
      workspace_new_project(false, EXTERN_DEP_PROJ_TEMPLATE, EXTERN_DEP_PROJ_NAME, wsdir, true, '', '', false, false);

      // Can't set the TagFile from the project template?
      rc := 0;
      phand := _ProjectHandle(edpname, rc);
      if (rc == 0) {
         node := _xmlcfg_find_simple(phand, '/Project');
         if (node >= 0) {
            _xmlcfg_add_attribute(phand, node, 'TagFile', 'ProjectNorefs');
            _ProjectSet_AutoFolders(phand, VPJ_AUTOFOLDERS_CUSTOMVIEW);
            _ProjectSave(phand);
            _project_update_files_retag(edpname, true, true, true, true, false, false, true);
         }

      }
      workspace_set_active(orig);
  }

   status := 0;
   rv = _ProjectHandle(edpname, status);
   if (status < 0) {
      rv = status;
   }

   return rv;
}


// Populates `files` with all of the jar file dependencies defined
// in the project with the given handle.  This only returns the dependencies
// added by add_dependency_jar_files, it does not return any jars that the
// user added to the dependencies project.
void get_jar_dependencies(int handle, _str (&files)[])
{
   _str deps[]; deps._makeempty();
   files._makeempty();
   dephand := extern_dependency_project_handle();
   if (dephand >= 0) {
      _xmlcfg_find_simple_array(dephand, "/Project/Files/Folder/F[strieq(@Type,'"JAR_DEPENDENCY_FILE_TYPE"')]", deps);
      foreach (auto node in deps) {
         fn := _xmlcfg_get_attribute(dephand, (int)node, 'N', '');
         if (fn != '') {
            files :+= fn;
         }
      }
   }
}

// Removes the dependency jars from a project.
// TODO will change once project dependency changes are in.
void remove_existing_jar_dependencies(int handle)
{
   // Clean up old dependencies.  Dependencies are currently marked with a JAR_DEPENDENCY_FILE_TYPE type.
   _str oldDeps[]; oldDeps._makeempty();
   dephand := extern_dependency_project_handle();
   if (dephand >= 0) {
      _xmlcfg_find_simple_array(dephand, "//F[strieq(@Type,'"JAR_DEPENDENCY_FILE_TYPE"')]", oldDeps);
      foreach (auto x in oldDeps) {
         _xmlcfg_delete(dephand, (int)x);
      }
   }
}

// Adds a set of jar files as dependency jar files for the project.
void add_dependency_jar_files(int handle, _str (&files)[])
{
   dephand := extern_dependency_project_handle();

   if (dephand >= 0) {
      depfold := _xmlcfg_find_simple(dephand, "/Project/Files/Folder[strieq(@Name,'Jar Files')]");
      if (depfold < 0) {
         // Make a folder.
         dfparent := _xmlcfg_find_simple(dephand, "/Project/Files");
         if (dfparent < 0) {
            message('Could not find /Project/Files');
            return;
         }

         depfold = _ProjectAdd_Folder(dephand, 'Jar Files', '*.jar;*.aar', dfparent);
         if (depfold < 0) {
            message('Could not create "Jar Files" folder.');
            return;
         }
      }

      foreach (auto file in files) {
         fn := _xmlcfg_add(dephand, depfold, 'F', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         if (fn < rc) {
            message('Failed adding 'file);
            return;
         }
         _xmlcfg_add_attribute(dephand, fn, 'N', file);
         _xmlcfg_add_attribute(dephand, fn, 'Type', JAR_DEPENDENCY_FILE_TYPE);
      }

      _ProjectSave(dephand);
   }
}

// Parses the dependency list from the current view.
static void parse_mvn_dependencies(MavenDependency (&deps):[]) 
{
   top();
   save_search(auto s1, auto s2, auto s3, auto s4, auto s5);
   rc := 0;
   for (rc = search('^\[INFO] *([^: ]+):([^: ]+):[^:]*:([^:]+):.*$', '@L'); rc == 0; rc = repeat_search('@L')) {
      MavenDependency dep; dep._makeempty();
      dep.groupId = strip(get_text(match_length('1'), match_length('S1')));
      dep.artifactId = strip(get_text(match_length('2'), match_length('S2')));
      dep.version = strip(get_text(match_length('3'), match_length('S3')));
      if (dep.groupId != '' && dep.artifactId != ''&& dep.version != '') {
         deps:[maven_get_dep_key(dep)] = dep;
      }
      right();
   }
   restore_search(s1, s2, s3, s4, s5);
}

static int check_status(_str (&files)[], MavenDependency dep)
{
   depstr := maven_get_cache_path(dep);
   foreach (auto wc in files) {
      if (pos(depstr, wc) != 0) {
         return TCB_CHECKED;
      }
   }
   return TCB_UNCHECKED;
}

static void cd_to_cur_project_dir()
{
   pdir := _strip_filename(_project_name, 'N');
   cd('+p 'pdir, '1');
}

static int mvnwiz_select_dependencies()
{
   ctl_dep_tree._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Artifact");
   ctl_dep_tree._TreeSetColButtonInfo(1,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Group");
   ctl_dep_tree._TreeSetColButtonInfo(2,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Version");
   ctl_dep_tree._TreeAdjustLastColButtonWidth();

   cd_to_cur_project_dir();

   prog := progress_show('Examining dependencies...', 200);
   handle := _ProjectHandle();
   _str curDeps[]; 

   get_jar_dependencies(handle, curDeps);
   progress_set(prog, 10);
   rc := exec_command_to_temp_view(maven_cmd('dependency:list', gWiz.mvn_exe), auto tempView, auto origView, prog, 100);
   if (rc < 0) {
      _message_box('Could not run mvn dependency:list, see output window for details.');
      return rc;
   }

   MavenDependency depset:[]; depset._makeempty();
   parse_mvn_dependencies(depset);
   activate_window(origView);
   _delete_temp_view(tempView);

   progress_set(prog, 100);

   prog.p_caption = 'Checking source dependencies...';
   rc = exec_command_to_temp_view(maven_cmd('dependency:sources', gWiz.mvn_exe), tempView, origView, prog, 100);
   if (rc < 0) {
      _message_box('Could not run mvn dependency:sources, see output window for details.');
      return rc;
   }
   activate_window(origView);
   _delete_temp_view(tempView);

   progress_close(prog);

   ctl_dep_tree._TreeBeginUpdate(TREE_ROOT_INDEX);
   foreach (auto dep in depset) {
      leaf := ctl_dep_tree._TreeAddItem(TREE_ROOT_INDEX, dep.artifactId"\t"dep.groupId"\t"dep.version, TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
      ctl_dep_tree._TreeSetUserInfo(leaf, gWiz.globalDeps._length());
      gWiz.globalDeps :+= dep;
      ctl_dep_tree._TreeSetCheckable(leaf, 1, 0, check_status(curDeps, dep));
   }
   ctl_dep_tree._TreeEndUpdate(TREE_ROOT_INDEX);
   ctl_dep_tree._TreeAdjustColumnWidths(-1);

   return 0;
}

static int mvnwiz_save_dependencies()
{
   MavenDependency checked[];

   int info;
   tindex := ctl_dep_tree._TreeGetNextCheckedIndex(1, info);

   // Make a set of checked dependencies, with no duplicates.
   checked._makeempty();
   while (tindex >= 0) {
      dindex := ctl_dep_tree._TreeGetUserInfo(tindex);
      dep := gWiz.globalDeps[dindex];
      checked :+= dep;
      tindex = ctl_dep_tree._TreeGetNextCheckedIndex(0, info);
   }

   handle := _ProjectHandle();
   remove_existing_jar_dependencies(handle);

   rr := maven_repo_root();
   // Make sure we know where the jar files live.
   if (rr == '' || !file_exists(rr)) {
      _message_box("Can't find maven cache dir: "rr);
      return FILE_NOT_FOUND_RC;
   }

   _str tagJars[]; tagJars._makeempty();
   foreach (auto dep in checked) {
      rf := resolve_cache_jar_path(maven_get_cache_path(dep, rr), dep, PREFER_SRC);
      if (rf != '') {
         tagJars :+= rf;
      }
   }
   add_dependency_jar_files(handle, tagJars);

   // Save all binary dependencies so we know the classpath, and for RTE.
   list := get_cleared_rte_deps_node();
   if (list >= 0) {
      foreach (dep in gWiz.globalDeps) {
         path := resolve_cache_jar_path(maven_get_cache_path(dep, rr), dep, PREFER_BINARY);
         if (path != '') {
            n := _xmlcfg_add(gWorkspaceHandle, list, 'Item', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_add_attribute(gWorkspaceHandle, n, 'Name', RTE_DEP_NAME);
            _xmlcfg_add_attribute(gWorkspaceHandle, n, 'Value', path);
         }
      }
      // RTE deps go in workspace, not project.
      _WorkspaceSave(gWorkspaceHandle);
   }

   return 0;
}

// Saves selections from gWiz so they will be unchanged the next time the dialog is started.
static void save_gwiz_preferences()
{
   handle := _ProjectHandle();
   cfgr := get_project_settings_node(handle);
   if (cfgr < 0) return;

   set_list_value(handle, cfgr, 'mvn_exe', gWiz.mvn_exe);
}

static int start_mvn_wizard(_str caption)
{
   WIZARD_INFO info;

   clear_output_window();
   init_gwiz();
   info.callbackTable._makeempty();

   info.callbackTable:["ctlslide0.create"] = mvnwiz_select_executable;
   info.callbackTable:["ctlslide0.shown"] = do_nothing;
   info.callbackTable:["ctlslide0.next"] = mvnwiz_save_executable;
   info.callbackTable:["ctlslide0.skip"] = 0;

   info.callbackTable:["ctlslide1.create"] = mvnwiz_select_dependencies;
   info.callbackTable:["ctlslide1.shown"] = do_nothing;
   info.callbackTable:["ctlslide1.next"] = mvnwiz_save_dependencies;
   info.callbackTable:["ctlslide1.skip"] = 0;

   info.callbackTable:["finish"] = apply_wizard_settings;
   info.parentFormName = "_maven_cfg_wizard_form";
   info.dialogCaption = caption;

   return _Wizard(&info);
}

/**
 * Starts up the dialog that allows maven project specific 
 * configuration. 
 * 
 * @return int 
 */
_command int reconfigure_maven_project() name_info(','VSARG2_REQUIRES_PRO_EDITION)
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

   if (_ProjectGet_TemplateName(ph) != 'Maven') {
      message('Open project is not a Maven project');
      return 0;
   }

   start_mvn_wizard('Configuring Maven Project');

   return 0;
}

defeventtab _maven_cfg_wizard_form;

void _browsefile.lbutton_up()
{
   fdir := ctl_maven_exe.p_text;
   filters := '';
   wcs := '';
   if (_isWindows()) {
      filters = "Batch Files (*.cmd)";
      wcs = "*.cmd";
   }
   rv := _OpenDialog('-modal', "Select `mvn` executable", wcs, filters, OFN_FILEMUSTEXIST, "", '', fdir);
   if (rv != '') {
      ctl_maven_exe.p_text = _maybe_unquote_filename(rv);
   }
}


void ctl_check_all.lbutton_up()
{
   int i;

   for (i = 1; i <= ctl_dep_tree._TreeGetNumChildren(TREE_ROOT_INDEX); i++) {
      ctl_dep_tree._TreeSetCheckState(i, TCB_CHECKED);
   }
}

void ctl_uncheck_all.lbutton_up()
{
   int i;

   for (i = 1; i <= ctl_dep_tree._TreeGetNumChildren(TREE_ROOT_INDEX); i++) {
      ctl_dep_tree._TreeSetCheckState(i, TCB_UNCHECKED);
   }
}

#define MAVEN_OPTIONS_MENU "Maven Options"
// If this is an older project that doesn't have a "Maven Options" menu entry, 
// add it in.
void maybe_add_reconfigure_menu_entry(int handle)
{
   _str cfgs[];  cfgs._makeempty();
   mh := _xmlcfg_find_simple_array(handle, '/Project/Config', cfgs);
   changed := false;
   foreach (auto cfg in cfgs) {
      ch := (int)cfg;
      menuroot := _xmlcfg_find_simple(handle, 'Menu', ch);
      ment := _xmlcfg_find_simple(handle, "Target[strieq(@Name,'":+MAVEN_OPTIONS_MENU:+"')]", menuroot);
      if (ment < 0) {
         changed = true;
         ment = _xmlcfg_add(handle, menuroot, 'Target', VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_FIRST_CHILD);
         _xmlcfg_add_attribute(handle, ment, 'Name', MAVEN_OPTIONS_MENU);
         _xmlcfg_add_attribute(handle, ment, 'MenuCaption', 'Maven &Options');
         _xmlcfg_add_attribute(handle, ment, 'ShowOnMenu', 'HideIfNoCmdLine');
         _xmlcfg_add_attribute(handle, ment, 'Deletable', '0');
         _xmlcfg_add_attribute(handle, ment, 'SaveOption', 'SaveNone');
         ex := _xmlcfg_add(handle, ment, 'Exec', VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(handle, ex, 'CmdLine', 'reconfigure-maven-project');
         _xmlcfg_add_attribute(handle, ex, 'Type', 'Slick-C');
      }
   }
   if (changed) {
      _ProjectSave(handle);
   }
}

void _prjopen_maven(bool singleFileProject)
{
   if (singleFileProject) return;
   if (!_haveBuild()) {
      return;
   }
   int h = _ProjectHandle();
   if (h) {
      if (_ProjectGet_TemplateName(h) == 'Maven') {
         maybe_add_reconfigure_menu_entry(h);
         cfgr := get_project_settings_node(h);
         if (cfgr >= 0) {
            mex := lookup_list_value(h, cfgr, 'mvn_exe', resolved_mvn_exe());
            if (file_exists(mex)) {
               def_maven_exe = mex;
            } else if (mex != '') {
               message('Did not find maven executable for project: 'mex);
            }
         }
      }
   }
}


// Called by RTE to get the classpath for the project.
_str maven_project_classpath(int hProject)
{
   rv := build_rte_classpath_from_workspace();
   return rv;
}

/**
 * Called by the maven template when creating a workspace for a 
 * .pom file. 
 */
_command int new_maven_project(_str configName = 'Release') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   return reconfigure_maven_project();
}

