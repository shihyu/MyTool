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
#include "rte.sh"
#include "tagsdb.sh"
#import "cjava.e"
#import "compile.e"
#import "cfg.e"
#import "error.e"
#import "fileman.e"
#import "guiopen.e"
#import "javaopts.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "listbox.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "treeview.e"
#import "util.e"
#import "wkspace.e"
#endregion

static bool g_first;
int last_error;

// Jave Live errors def vars that are needed across multiple files
_str def_java_live_errors_jdk_6_dir = "";
_str def_java_live_errors_jvm_lib= "";
bool def_java_live_errors_enabled = true;
int def_java_live_errors_errored= 0;
int def_java_live_errors_incremental_compile = 0;
static bool _live_errors_auto_enable;
// Map from lang/profile_name to bool.
bool gvalid_profiles:[];

definit() {
   // IF java live errors is enabled but not quite configured, try to automatically set it up.
   _live_errors_auto_enable=def_java_live_errors_enabled && (def_java_live_errors_jdk_6_dir=='' || def_java_live_errors_jvm_lib=='');
   g_first = true;
   last_error = -1;
   gvalid_profiles._makeempty();
}

_str vsCfgPackage_for_LangRteProfiles(_str LangId) {
   return (vsCfgPackage_for_Lang(LangId):+VSXMLCFG_FILESEP:+'rte_profiles');
}

static _str profValidKey(_str langId, _str profileName)
{
   return langId'/'profileName;
}

static bool internIsProfileValid(_str langId, _str profileName)
{
   RTEGenericProfile prof;

   rc := rteReadProfile(langId, profileName, prof);
   if (rc == 0) {
      excmd := rte_expand_command_substitutions('', prof.program);
      if (file_exists(excmd)) {
         return true;
      } else if (path_search(prof.program) != '') {
         return true;
      } else {
         return false;
      }
   } else {
      return false;
   }
}

static bool isProfileValid(_str langId, _str profileName)
{
   key := profValidKey(langId,profileName);
   val := gvalid_profiles._indexin(key);
   if (val) {
      return *val;
   } else {
      rv := internIsProfileValid(langId,profileName);
      gvalid_profiles:[key] = rv;
      return rv;
   }
}

static void clearProfileCaches()
{
   gvalid_profiles._makeempty();
   rteUpdateBuffers(true);
}

void _prjupdate_rte()
{
   if (!_haveRealTimeErrors()) {
      return;
   }
   clearProfileCaches();
   rteForceUpdate();
}


/**
 * RTE does not work on Solaris 6, so this function can tell if the current OS is Solaris 5.6.
 * 
 * This function will be used to disable RTE in the case where the OS is Solaris 6.
 * 
 * @return 
 */
bool isSolaris56()
{
   if (_isUnix()) {
      struct UNAME info;
      _uname(info);
      return(info.release == '5.6' && info.sysname == 'SunOS');
   }
   return false;
}

bool has_rte_profiles(_str langId)
{
   return langId == 'java' || rte_get_profile_name(langId, false) != '';
}
static bool general_rte_enabled()
{
   return true;
}

// Return true if given project under the open workspace is a 
// java project. If `projname` is not supplied, then default to 
// the currently open project name.
static bool is_java_project(_str projname = '')
{
   if (projname == '') {
      projname = _project_name;
   }

   if (projname == '') {
      return false;
   } else {
      hProject := _ProjectHandle(projname);

      if (hProject < 0) {
         return false;
      } else {
         _ProjectGet_ActiveConfigOrExt(projname, hProject, auto config);
         ptype := _ProjectGet_Type(hProject, config);
         return ptype == 'java';
      }
   }
}

void _workspace_file_add_rte(_str projName, _str fileName)
{
   extension := _get_extension(fileName,false);
   lang      := _Ext2LangId(extension);
   if (!RTEEnabledForLang(lang) || !has_rte_profiles(lang)) {
      return;
   }

   int hProject = _ProjectHandle(projName);
   if (hProject) {
      int result = rteAddFile(hProject, fileName);
      if (result != 0) {
         rte_abort(result);
      }
   }
}
void _prjclose_rte(bool singleFileProject)
{
   if (!_haveRealTimeErrors()) {
      return;
   }
   if (singleFileProject) return;

   _ProjectGet_ActiveConfigOrExt(_project_name, auto hProject, auto config);
   if (hProject) {
      if (stricmp(_ProjectGet_Type(hProject, config), "java") == 0) {
         int result = rteRemoveProject(hProject);
         if (result != 0) {
            rte_abort(result);
         }
      }
   }
}

_str maybeCreateRTEOutputDir(){
   _str rte_path=_ConfigPath();
   _maybe_append_filesep(rte_path);
   rte_path :+= "java_rte_classes" :+ FILESEP;
   wspace_root := _strip_filename(_workspace_filename, 'EN');
   if (_isWindows()) {
      wspace_root = stranslate(wspace_root, "",":");
   }
   rte_output_dir :=  rte_path :+ wspace_root;
   if (!isdirectory(rte_output_dir) && _ProjectGet_ActiveType() == 'java') {
      int status = make_path(rte_output_dir);
      if (status != 0) {
         return("");
      } 
   }
   return(rte_output_dir);
}


// Builds a classpath based on BinaryJar Items in the project file.
_str build_rte_classpath_from_workspace()
{
   _str jarnodes[]; jarnodes._makeempty();

   rc := _xmlcfg_find_simple_array(gWorkspaceHandle, "//Item[strieq(@Name,'"RTE_DEP_NAME"')]", jarnodes);
   if (rc == 0) {
      cp := '';
      foreach (auto node in jarnodes) {
         if (cp != '') {
            cp :+= PATHSEP;
         }
         cp :+= _xmlcfg_get_attribute(gWorkspaceHandle, (int)node, 'Value', 'nope');
      }
      return cp;
   } else {
      return '';
   }
}

bool has_rte_classpath_in_workspace()
{
   return gWorkspaceHandle >= 0 && _xmlcfg_find_simple(gWorkspaceHandle, "//List[strieq(@Name,'RTEDeps')]") >= 0;
}

static void maybeAutoEnable()
{
   if (_live_errors_auto_enable) {
      java_maybe_activate_live_errors();
      _live_errors_auto_enable=false;
   }
}

int _workspace_opened_rte(_str sp_from_android='')
{
   if(!(general_rte_enabled()) || !_haveContextTagging()) {
      return -1;
   }

   _str rte_output_dir = maybeCreateRTEOutputDir();

   if (rte_output_dir :== "") {
      return -1;
   }

   // Not necessarily a Java project in this workspace, 
   // so defer jdk path initialization till we are looking
   // at a project.
   jdk_classpath_initialized := false;
   result := 0;

   if (gWorkspaceHandle <= 0) {
      // This fails for single file projects, which is just fine, 
      // since this does nothing we need for those.
      return -1;
   }

   _str _projects[];
   _WorkspaceGet_ProjectFiles(gWorkspaceHandle, _projects);

   j := i := 0;
   if (_projects._length() < 1) {
      return -1;
   }
// say("rte workspace opened");
   for (i = 0; i < _projects._length(); i++) {
      _str _fullPath = _AbsoluteToWorkspace(_projects[i]);
      if (!_ProjectFileExists(_fullPath)) continue;
      int hProject = _ProjectHandle(_fullPath);
      config := "";
      _ProjectGet_ActiveConfigOrExt(_fullPath, hProject, config);
      _str type = lowcase(_ProjectGet_Type(hProject,config));
      sp_from_other := "";
      good := false;
      if (type == 'android') {
         // Android dependencies are AAR files, which we can not put on the classpath for RTE.
         rteShutdown(1);
      } else if (type == 'java') {
         if (!jdk_classpath_initialized) {
            java_get_jdk_classpath();
            maybeAutoEnable();
            if (!_java_live_errors_enabled()) {
               return -1;
            }
            result = rteSetJDKPath(def_jdk_install_dir);
            if (result != 0) {
               rte_abort(result);
               return -1;
            }
            jdk_classpath_initialized = true;
         }

         if (has_rte_classpath_in_workspace()) {
            cp := build_rte_classpath_from_workspace();
            if (cp != '') {
               result = rteAddProject(hProject);
               if (result != 0) {
                  rte_abort(result);
                  return(-1);
               }
            
               rteSetClassPath(hProject, cp);
               rteSetSourceComplianceLevel("None");
               rteSetJvmLibPath(hProject, def_java_live_errors_jvm_lib);
               _make_path(rte_output_dir);
               rteSetOutputDir(hProject, rte_output_dir);
               good = true;
            }
         } else {
            _str classPath = _ProjectGet_ClassPathList(hProject,config);
            _str compileLine = _ProjectGet_TargetCmdLine(hProject,_ProjectGet_TargetNode(hProject,'compile'));
            _str other_opts = _ProjectGet_TargetOtherOptions(hProject,_ProjectGet_TargetNode(hProject,'compile'));
            if (def_java_live_errors_other_options) {
               sp_from_other = rte_strip_sourcepath_from_other_options(other_opts);
               result = rteSetOtherOptions(other_opts);
               if (result != 0) {
                  rte_abort(result);
                  return(-1);
               }
            }
            _str start, rest;
            parse compileLine with start "-source " rest;
            src_compliance := substr(rest,1,3);
            if (!isnumber(src_compliance)) {
               src_compliance = substr(src_compliance,1,1);
               if (!isnumber(src_compliance)) {
                  src_compliance = "None";
               }
            }
            result = rteSetSourceComplianceLevel(src_compliance);
            if (result != 0) {
               rte_abort(result);
               return(-1);
            }
            _str new_classpath = prepare_rte_classpath(classPath, hProject, config, _fullPath);
            result = rteAddProject(hProject);
            if (result != 0) {
               rte_abort(result);
               return(-1);
            }
            result = rteSetClassPath(hProject, new_classpath);
            if (result != 0) {
               rte_abort(result);
               return(-1);
            }
            jvm_lib := def_java_live_errors_jvm_lib;
            if (!file_exists(jvm_lib)) {
               rte_abort(result);
               return(-1);
            }
            result = rteSetJvmLibPath(hProject, def_java_live_errors_jvm_lib);
            if (result != 0) {
               rte_abort(result);
               return(-1);
            }
            result = rteSetOutputDir(hProject, rte_output_dir);
            if (result != 0) {
               rte_abort(result);
               return(-1);
            }
            good = true;
         }
      } else {
         // Generic RTE support then?
         good = true;
      } 

      if (good && jdk_classpath_initialized) {
         _str fileList[];
         int status = _getProjectFiles(_workspace_filename, _fullPath, fileList, 1, hProject);
         if (status) {
            rte_abort(result);
            return(-1);
         }

         for (k := 0; k < fileList._length(); k++) {
            lang := _Filename2LangId(fileList[k]);
            if (RTEEnabledForLang(lang) && has_rte_profiles(lang)) {
               result = rteAddFile(hProject, fileList[k]);
               if (result != 0) {
                  rte_abort(result);
                  return(-1);
               }
               if (lang == 'java') {
                  _str pkg_root = find_pkg_root(hProject, fileList[k]);
                  rteMaybeAddToSourcePath(hProject, pkg_root);
               }
            }
         }

         if (sp_from_other != '' && def_java_live_errors_other_options && 
             jdk_classpath_initialized) {
            rteMaybeAddToSourcePath(hProject, sp_from_other);
         }

         if (sp_from_android != '' && jdk_classpath_initialized) {
            rteMaybeAddToSourcePath(hProject, sp_from_android);
         }
      }
   }
   return 0;
}

_str rte_strip_sourcepath_from_other_options(_str &other_opts){
   sp_index := pos("-sourcepath",other_opts);
   if (sp_index <= 0) {
      return '';
   }
   sp_start_index := pos(" ",other_opts,sp_index);
   if (sp_start_index <= 0) {
      return '';
   }
   next_option_start := pos(" -",other_opts,sp_start_index);
   int sp_end_index = next_option_start > 0 ? next_option_start - sp_start_index : -1; 
   sp_from_other_opts := substr(other_opts,sp_start_index,sp_end_index);
   parse other_opts with auto prefix "-sourcepath " sp_from_other_opts auto suffix;
   other_opts = prefix :+ suffix;
   return sp_from_other_opts; 
}

_str prepare_rte_classpath(_str classPath, int hProject, _str config, _str _fullPath=""){
   // Get dependency project classpaths
   if (_fullPath :== "") {
      _fullPath = _project_name;
   }
   _str DependencyProjects[]=null;
   dependencyClassPath := "";
   _ProjectGet_DependencyProjects(hProject, DependencyProjects, config);
   int j;
   for(j= 0 ; j < DependencyProjects._length(); j++) {
      strappend(dependencyClassPath, PATHSEP);
      _str dependencyFullPath = _AbsoluteToWorkspace(DependencyProjects[j]);

      int hDependencyProject = _ProjectHandle(dependencyFullPath);
      strappend(dependencyClassPath, _ProjectGet_ClassPathList(hDependencyProject, config));
   }

   if(dependencyClassPath != "") {
      strappend(classPath, dependencyClassPath); 
   }

   // Replace any environment variables with their values
   _str paths[];  paths._makeempty();

   // Make the rte jdk directory the first entry.
   cp0 := def_java_live_errors_jdk_6_dir;
   if (classPath != '') {
      cp0 :+= PATHSEP;
      cp0 :+= classPath;
   }

   _ProjectExpanded_ClassPathList(cp0, paths);

   _str output_path = _ProjectGet_ObjectDir(hProject,config);
   _str full_output_path = _AbsoluteToProject(output_path, _fullPath);

   jdk_classes :=  _ProjectCreate_CommandLineClasspath(paths, auto na, true);

   // strip out output directory from classpath that live errors sees
   if (full_output_path :!= "") {
     jdk_classes = stranslate(jdk_classes, "", full_output_path :+ FILESEP);
     jdk_classes = stranslate(jdk_classes, "", full_output_path);
   }
   if (output_path :!= "") {
     jdk_classes = stranslate(jdk_classes, "", output_path :+ FILESEP);
     jdk_classes = stranslate(jdk_classes, "", output_path);
   }
   return(jdk_classes);
}

_str find_pkg_root(int proj_handle, _str filename){
   dir := _strip_filename(filename, "N");
   _str packageName=FindPackage(filename,false);
   if (packageName == '') {
      packageName = FindPackage(filename,true);
      if (packageName == '') {
         return(dir);
      }
   }
   package_mod := stranslate(packageName, FILESEP,'.');
   package_mod :+= FILESEP;
   l1 := length(package_mod);
   l2 := length(dir);
   if( l1 > l2 ) {
      return(dir);
   }
   tail := substr(dir,l2-l1+1);
   if( package_mod!= tail ) {
      return(dir);
   }
   pkg_root := substr(dir, 1, l2 - l1);
   return(pkg_root);
}

static bool extra_push:[];


/**
 * This function is used to cycle through Java live errors in the current file.
 */
_command void rte_next_error() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION) 
{
   if (!_haveRealTimeErrors()) {
      return;
   }
   editor_wid := p_window_id;
   if (!_isEditorCtl()) {
      editor_wid = _mdi.p_child;
   }
   if (_no_child_windows() || !RTEEnabledForLang(_mdi.p_child.p_LangId)) {
      return;
   }
   int line = rteNextError(editor_wid.p_line, editor_wid.p_buf_name);
   if (line > -1) {
      editor_wid.goto_line(line);
   } else if (line == -1) {
      message("No errors found in current file.");
   }
}

void rteUpdateBuffers(bool AlwaysUpdate=false)
{
   if (!_haveRealTimeErrors() || isSolaris56()) {
      return;
   }

   if (!AlwaysUpdate && _idle_time_elapsed() < def_java_live_errors_sleep_interval) {
      return;
   }

   // if it's not a java buffer...bail
   if (_no_child_windows() || !has_rte_profiles(_mdi.p_child.p_LangId)) {
      return;
   }

   is_java_proj := is_java_project();

   if (is_java_proj) {
      maybeAutoEnable();
      if(!_java_live_errors_enabled()) {
         return;
      } else if (!general_rte_enabled()) {
         return;
      }

      if (def_java_live_errors_errored) {
         def_java_live_errors_enabled = false;
         _config_modify_flags(CFGMODIFY_DEFVAR);
         rte_abort(last_error);
         return;
      }
      if(def_java_live_errors_jdk_6_dir == '') {
         return;
      }
   }

   int editorctl_wid = _mdi.p_child;
   if(_isdiffed(editorctl_wid.p_buf_id)) {
      return;
   }

   if (g_first) {
      if (is_java_proj) {
         int result = JavaLiveErrors_SetOptionsFromDefVars();
         if (result != 0) {
            rte_abort(result);
            return;
         }
      }
/*      _str rte_path=_config_path();
      _maybe_append_filesep(rte_path);
      rte_path :+= "java_rte_classes";
      if (!isdirectory(rte_path)) {
         mkdir(rte_path);
      }*/
      isSingleFileProject := _workspace_filename == '';
      if (isSingleFileProject || _workspace_opened_rte()== 0) {
         g_first = false;
      }
      return;
   }
//   rteSetJDKPath(def_jdk_install_dir);
   int result = rteSetActiveBuffer(editorctl_wid.p_window_id, editorctl_wid.p_buf_id, editorctl_wid.p_buf_name,
                                   editorctl_wid.p_LangId);
   if (result != 0) {
      rte_abort(result);
      return;
   }
   // this adds the errors
   int status = rteUpdateEditor(editorctl_wid.p_window_id, editorctl_wid.p_buf_name, editorctl_wid.p_buf_id, 
                                editorctl_wid.p_LangId);
   orig_view_id := p_window_id;
   first_buf := 0;
   temp_view_id := 0;
   if (!HaveBuffer()) {
      return;
   }
   _open_temp_view('',temp_view_id,orig_view_id,'+bi 'RETRIEVE_BUF_ID);
   _next_buffer('NR');
   // there is at least 1 file open
   first_buf=p_buf_id;

   for (;;) {
      if (!(p_buf_flags&VSBUFFLAG_HIDDEN) &&  has_rte_profiles(p_LangId)) {
         p_KeepPictureGutter = true;
               rtePushBuffer(p_window_id, p_buf_id, p_buf_name, p_LangId);
      }

      _next_buffer('NR');
      if (p_buf_id == first_buf) {
         break;
      }
   }
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
}

/**
 * Determines if there are currently any open buffers.
 * 
 * @return bool   true if there are open buffers, false if not 
 *  
 * @categories Buffer_Functions
 */
bool HaveBuffer()
{
   return(buf_match('',1,'v')!='');
}

void _wkspace_close_rte()
{

}
void workspace_open_rte(_str name)
{
   if(is_java_project() && !_java_live_errors_enabled()) {
      return;
   }

   _workspace_opened_rte();

}
void _exit_rte()
{
   if (!_haveRealTimeErrors()) {
      return;
   }
   if(is_java_project() && !_java_live_errors_enabled()) {
      return;
   }
   rteShutdown(0);
}

// For turning off Live Errors when the editor is running.
// Will clear out error markers.
_command rteStop() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (_haveRealTimeErrors()) {
      rteShutdown(1);
   }
}

void rte_abort(int e){
   if (!_haveRealTimeErrors()) {
      return;
   }
   _message_box("Java Live Errors encountered a JVM-related error and must shut down.\n":+
                "Please select Build > Java Options and select the Live Errors tab to re-enable Live Errors.\n\n":+
                "Error: ":+get_message(e):+"\n\n":+
                "Note: Live Errors in SlickEdit 64-bit requires a 64-bit JVM.");
   rteShutdown(1);
   def_java_live_errors_enabled = false;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void rte_set_errored(int e){
   _config_modify_flags(CFGMODIFY_DEFVAR);
   def_java_live_errors_errored = 1;
   last_error = e;
}
bool _java_live_errors_supported() {
   return _haveRealTimeErrors() && !isSolaris56();
}

bool _java_live_errors_enabled() {
   return def_java_live_errors_enabled && 
          _java_live_errors_supported() && 
          def_java_live_errors_jdk_6_dir != "" && 
          def_java_live_errors_jvm_lib   != "" &&
          file_exists(def_java_live_errors_jvm_lib);
}

static int RTEEnabledForLang(_str langId)
{
   if (langId == 'java') {
      return _java_live_errors_enabled() ? 1 : 0;
   } else {
      // Note: Defaulting to off if not set.
      return _LangGetPropertyInt32(langId, VSLANGPROPNAME_RTE_LANG_ENABLED, 0);
   }
}

static void setRTEEnabledForLang(_str langId, int v)
{
   _LangSetPropertyInt32(langId, VSLANGPROPNAME_RTE_LANG_ENABLED, v);
}


// What's the RTE profile associated with this project?
static _str _ProjectGet_RteProfile(int handle, _str langId)
{
   rv := '';
   node := _xmlcfg_find_simple(handle, "//Item[strieq(@Name,'RTEProfile"langId"')]");
   if (node > 0) {
      rv = _xmlcfg_get_attribute(handle, node, 'Value', '');
   }

   return rv;
}

static int _ProjectSet_RteProfile(int handle, _str langId, _str profName)
{
   rv := 0;
   root := _xmlcfg_find_simple(handle, '/Project');

   if (root > 0) {
      rlist := _xmlcfg_find_simple(handle, "List[strieq(@Name,'RTE')]", root);
      if (rlist <= 0) {
         rlist = _xmlcfg_add(handle, root, 'List', VSXMLCFG_NODE_ELEMENT_START, 
                             VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(handle, rlist, 'Name', 'RTE');
      }
      profnode := _xmlcfg_find_simple(handle, "Item[strieq(@Name,'RTEProfile"langId"')]", 
                                      rlist);
      if (profnode <= 0) {
         profnode = _xmlcfg_add(handle, rlist, 'Item', VSXMLCFG_NODE_ELEMENT_START, 
                                VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(handle, profnode, 'Name', 'RTEProfile'langId);
         _xmlcfg_add_attribute(handle, profnode, 'Value', '');
      }
      _xmlcfg_set_attribute(handle, profnode, 'Value', profName);
   } else {
      rv = FILE_NOT_FOUND_RC;
   }

   return rv;
}

static _str rte_get_language_default_profile(_str langId)
{
   rv := '';

   langDefault := _LangGetProperty(langId, VSLANGPROPNAME_RTE_DEFAULT_PROFILE, 
                                   RTE_PROFILE_AUTO);

   if (langDefault == RTE_PROFILE_AUTO) {
      idx := _FindLanguageCallbackIndex('_%s_rte_get_profile_name', langId);
      if (idx > 0) {
         rv = call_index(idx);
      } else {
         // Does it have any?
         _str profiles[]; profiles._makeempty();

         _plugin_list_profiles(vsCfgPackage_for_LangRteProfiles(langId), profiles);
         foreach (auto prof in profiles) {
            if (isProfileValid(langId, prof)) {
               rv = prof;
               break;
            }
         }
      }
   } else {
      rv = langDefault;
   }

   return rv;
}

void rte_get_profiles_for_language(_str langId, _str (&profiles)[])
{
   profiles._makeempty();
   _plugin_list_profiles(vsCfgPackage_for_LangRteProfiles(langId), profiles);
}

// Get the RTE profile name for the currently open project, given 
// the language. Only returns profiles that are valid
_str rte_get_profile_name(_str langId, bool checkValidity = true)
{
   rv := '';

   _ProjectGet_ActiveConfigOrExt(_project_name, auto handle, auto config);
   if (handle > 0) {
      rv = _ProjectGet_RteProfile(handle, langId);
      if (rv == '') {
         rv = rte_get_language_default_profile(langId);
      }
      if (checkValidity && rv != '' && !isProfileValid(langId, rv)) {
         // Referred to a profile that is not installed.
         rv = '';
      }
   }

   return rv;
}

// Helper for RTE profiles that performs project var substitutions on 
// `cmd`.
_str rte_expand_command_substitutions(_str file, _str cmd)
{
   return _parse_project_command(cmd, file, _project_name, '');
}

// Per-language profile editing.
//
static const RTE_PROFILE_LANGUAGE_ID= "rte_langId";
defeventtab _rte_language_profiles_form;

static void update_profile_list() 
{
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);
   defaultSetting := _LangGetProperty(langId, VSLANGPROPNAME_RTE_DEFAULT_PROFILE, 
                                      RTE_PROFILE_AUTO);

   _ctl_profiles._TreeDelete(TREE_ROOT_INDEX,'C');
   _ctl_profiles._TreeSetColButtonInfo(0,2000,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   _ctl_profiles._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Program Status");
   _ctl_profiles._TreeAdjustLastColButtonWidth();
   _ctl_default_profile.p_cb_list_box._lbclear();
   _ctl_default_profile.p_cb_list_box._lbadd_item(RTE_PROFILE_AUTO);
   foundDefault := defaultSetting == RTE_PROFILE_AUTO;

   clearProfileCaches();

   _str profileNames[];
   _plugin_list_profiles(vsCfgPackage_for_LangRteProfiles(langId),profileNames);

   for (i:=0;i<profileNames._length();++i) {
      status := "Not found";
      if (isProfileValid(langId, profileNames[i])) {
         status = "Installed";
      }
      _ctl_profiles._TreeAddItem(TREE_ROOT_INDEX,profileNames[i]"\t"status,
                                 TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
      _ctl_default_profile.p_cb_list_box._lbadd_item(profileNames[i]);
      if (profileNames[i] == defaultSetting) {
         foundDefault = true;
      }
   }

   if (foundDefault) {
      _ctl_default_profile.p_cb_text_box.p_text = defaultSetting;
   } else {
      _ctl_default_profile.p_cb_text_box.p_text = RTE_PROFILE_AUTO;
   }

   update_buttons();
}
void _ctl_profiles.on_change(int reason,int index)
{
    update_buttons();
}

static _str getTreeProfile(int index)
{
   cap := _ctl_profiles._TreeGetCaption(index);
   spos := pos("\t", cap);
   return substr(cap, 1, spos - 1);
}

void _ctl_edit.lbutton_up()
{
   index:=_ctl_profiles._TreeCurIndex();
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);

   if (index > 0 && _ctl_profiles._TreeIndexIsValid(index) && langId != '') {
      profName := getTreeProfile(index);
      rc := edit_profile(langId,profName);
      if (rc != 0) {
         _message_box('Could not edit profile: 'get_message(rc));
      }
      update_profile_list();
      rteForceUpdate();
   }
}

static _str prompt_for_new_profile(_str langId, _str copyFrom = '')
{
   newProf := '';
   pkg := vsCfgPackage_for_LangRteProfiles(langId);
   do {
      if (newProf != '') {
         mb := _message_box('There is already a profile named 'newProf);
      }
      newProf = '';
      status := _plugin_prompt_add_profile(pkg, 
                                           newProf, 
                                           copyFrom);
      if (status) {
         newProf = '';
         break;
      }
   } while (_plugin_has_profile_ex(pkg, newProf));

   return newProf;
}

void _ctl_copy.lbutton_up()
{
   index:=_ctl_profiles._TreeCurIndex();
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);

   if (index > 0 && _ctl_profiles._TreeIndexIsValid(index) && langId != '') {
      srcProfile := getTreeProfile(index);
      pkg := vsCfgPackage_for_LangRteProfiles(langId);
      newProf := prompt_for_new_profile(langId, srcProfile);

      if (newProf != '') {
         RTEGenericProfile prof;
         rc := rteReadProfile(langId, srcProfile, prof);
         if (rc) {
            _message_box('Could not load source profile 'srcProfile': 'get_message(rc));
         } else {
            rc = rteWriteProfile(langId, newProf, prof);
            if (rc) {
               _message_box('Could not write new profile named 'newProf':'get_message(rc));
            } else {
               update_profile_list();
            }
         }
      }
   }
}

void _ctl_delete.lbutton_up()
{
   index:=_ctl_profiles._TreeCurIndex();
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);

   if (index > 0 && _ctl_profiles._TreeIndexIsValid(index) && langId != '') {
      pkg := vsCfgPackage_for_LangRteProfiles(langId);
      srcProfile := getTreeProfile(index);
      status := _message_box("Are you sure you want to delete the profile '"srcProfile"'?  This action can not be undone.", "Confirm Profile Delete", MB_YESNO | MB_ICONEXCLAMATION);
      if (status == IDYES) {
         _plugin_delete_profile(pkg, srcProfile);
         update_profile_list();
      }
   }
}

void _ctl_new.lbutton_up()
{
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);
   if (langId != '') {
      profName := prompt_for_new_profile(langId);
      if (profName != '') {
         RTEGenericProfile prof;

         prof.program = '';
         prof.cmdline = '%f';
         prof.runDirectory = '%rw';
         prof.minPeriodMs = 1000;
         rc := rteWriteProfile(langId, profName, prof);
         if (rc) {
            _message_box('Could not write profile 'profName': 'get_message(rc));
         } else {
            update_profile_list();
         }
      }
   }
}

static void update_buttons()
{

   index:=_ctl_profiles._TreeCurIndex();
   if (index >= 0 && _ctl_profiles._TreeGetFirstChildIndex(TREE_ROOT_INDEX) >= 0) {
      _ctl_edit.p_enabled = true;
      langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);
      if (langId._length() > 0) {
         profName := getTreeProfile(index);
         _ctl_delete.p_enabled = !_plugin_has_builtin_profile(vsCfgPackage_for_LangRteProfiles(langId), profName);
      } else {
         _ctl_delete.p_enabled = true;
      }
      _ctl_copy.p_enabled = true;
   } else {
      _ctl_edit.p_enabled = false;
      _ctl_delete.p_enabled = false;
      _ctl_copy.p_enabled = false;
   }
}


void _rte_language_profiles_form_init_for_options(_str langId)
{
   clearProfileCaches();
   _SetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID, langId);
   _ctl_enabled.p_value = RTEEnabledForLang(langId);
   update_profile_list();
}

bool _rte_language_profiles_form_apply()
{
   clearProfileCaches();
   rteForceUpdate();
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);
   if (langId != '') {
      disabling := RTEEnabledForLang(langId) && !_ctl_enabled.p_value;
      _LangSetProperty(langId, VSLANGPROPNAME_RTE_DEFAULT_PROFILE, 
                       _ctl_default_profile.p_cb_text_box.p_text);
      setRTEEnabledForLang(langId, _ctl_enabled.p_value);
      rteForceUpdate();
      if (disabling) {
      }
   }

   return true;
}

bool _rte_language_profiles_form_is_modified()
{
   langId := _GetDialogInfoHt(RTE_PROFILE_LANGUAGE_ID);

   if (langId != '') {
      curDefault := _LangGetProperty(langId, VSLANGPROPNAME_RTE_DEFAULT_PROFILE, 
                                     RTE_PROFILE_AUTO);
      curEnabled := RTEEnabledForLang(langId);
      return curDefault != _ctl_default_profile.p_cb_text_box.p_text || curEnabled != _ctl_enabled.p_value;
   } else {
      return false;
   }
}

_str _rte_language_profiles_form_export_settings(_str &file, _str &args, _str langId)
{
   error := '';
   dest_handle:=_xmlcfg_create('',VSENCODING_UTF8);
   NofProfiles:=_xmlcfg_export_profiles(dest_handle,vsCfgPackage_for_LangRteProfiles(langId));
   if (!NofProfiles) {
      _xmlcfg_close(dest_handle);
      return error;
   }

   justName:=vsCfgPackage_for_LangRteProfiles(langId)'.cfg.xml';
   destFilename:=file:+justName;
   status:=_xmlcfg_save(dest_handle,-1,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE,destFilename);
   if (status) {
      error=get_message(status);
   }
   //_showxml(dest_handle);
   _xmlcfg_close(dest_handle);
   file=justName;
   return error;
}

_str _rte_language_profiles_form_import_settings(_str &file, _str &args, _str langId)
{
   error := '';
   if (file!='') {
      _xmlcfg_import_from_file(file);
   }
   return error;
}

defeventtab _rte_profile_form;
static RTEGenericProfile gEditProfile;  // Profile used when editing.

static int edit_profile_inplace(_str langId)
{
   rc := 0;

   res := show('-modal _rte_profile_form');
   if (res == IDOK) {
      // Save it.
      rc = rteWriteProfile(langId, gEditProfile.origProfileName, gEditProfile);
      if (rc != 0) {
         _message_box('Error saving profile: 'get_message(rc));
      }
   }

   return rc;
}

static void update_env_buttons()
{
   index:=_ctl_envvars._TreeCurIndex();
   if (index > 0 && _ctl_envvars._TreeIndexIsValid(index)) {
      _ctl_edit_envvar.p_enabled = true;
      _ctl_del_envvar.p_enabled = true;
   } else {
      _ctl_edit_envvar.p_enabled = false;
      _ctl_del_envvar.p_enabled = false;
   }
}

// Edits a profile.
static int edit_profile(_str langId, _str profileName)
{
   rc := rteReadProfile(langId, profileName, gEditProfile);
   if (rc == 0) {
      gEditProfile.origProfileName = profileName;
      gEditProfile.newProfileName = profileName;
      rc = edit_profile_inplace(langId);
   }

   return rc;
}

static void complain(_str msg)
{
   _ctl_error.p_caption = msg;
   _ctl_error.p_forecolor = 0x000000FF;
   _ctl_save.p_enabled = false;
}

static bool validate()
{
   prg := _ctl_program.p_text;
   if (prg == '' || (!file_exists(prg) && path_search(prg) == '') ) {
      complain('"Program" must be a absolute path to a program, ' :+
         'or a program on the PATH.');
      return false;
   }

   cmd := _ctl_cmdline.p_text;
   if (pos('%f', cmd) <= 0) {
      complain('"Command line" must designate the position of the ' :+
               'file name to check with "%f".');
      return false;
   }
  
   // Don't care about runFrom dir, if it's empty we default to %rw.

   mp := _ctl_minPeriodMs.p_text;
   isint := (mp != '' && isinteger(mp));
   isbad := isint ? (int)mp <= 0 : true;

   if (isbad) {
      complain('"Minimum times between runs" should be an integer > 0');
      return false;
   }

   _ctl_error.p_forecolor = 0x80000008;
   _ctl_error.p_caption = 'Status: OK';
   _ctl_save.p_enabled = true;
   return true;
}

void _ctl_cmdline.on_change2()
{
   validate();
}

void _ctl_program.on_change2()
{
   validate();
}

void _ctl_minPeriodMs.on_change2()
{
   validate();
}

static void readEnvVar(int index, _str& key, _str& val)
{
   if (index > 0 && _ctl_envvars._TreeIndexIsValid(index)) {
      cap := _ctl_envvars._TreeGetCaption(index);
      delim := pos("\t", cap);
      if (delim) {
         key = substr(cap, 1, delim-1);
         val = substr(cap, delim+1);
      } else {
         key = '';
      }
   } else {
      key = '';
   }
}

void _ctl_save.lbutton_up()
{
   if (validate()) {
      gEditProfile.program = _ctl_program.p_text;
      gEditProfile.cmdline = _ctl_cmdline.p_text;
      gEditProfile.runDirectory = _ctl_rundir.p_text;
      gEditProfile.minPeriodMs = (int)_ctl_minPeriodMs.p_text;
      gEditProfile.environment._makeempty();

      int i; 
      for (i = _ctl_envvars._TreeGetFirstChildIndex(0); i >= 0; 
            i = _ctl_envvars._TreeGetNextSiblingIndex(i)) {
         _str k, v;
         readEnvVar(i, k, v);
         if (k != '') {
            gEditProfile.environment:[k] = v;
         }
      }
      p_active_form._delete_window(IDOK);
      clearProfileCaches();
   }
}

void _ctl_browsefile.lbutton_up()
{
   fdir := _ctl_program.p_text;
   if (!file_exists(fdir)) {
      fdir = path_search(fdir);
   }
   filters := '';
   wcs := '';
   if (_isWindows()) {
      filters = "Batch Files (*.cmd)";
      wcs = "*.cmd";
   }
   base := _strip_filename(fdir, 'N');
   file := _strip_filename(fdir, 'P');
   rv := _OpenDialog('-modal', "Select error checking program", wcs, filters, OFN_FILEMUSTEXIST, "", file, base);
   if (rv != '') {
      _ctl_program.p_text = _maybe_unquote_filename(rv);
   }
}

void _rte_profile_form.on_resize()
{
   hmargin := 300;
   vmargin := 100;
   bmargin := 60;

   _ctl_cancel.p_x = p_width - hmargin - _ctl_cancel.p_width;
   _ctl_cancel.p_y = p_height - vmargin - _ctl_cancel.p_height;

   _ctl_save.p_x = _ctl_cancel.p_x - bmargin - _ctl_save.p_width;
   _ctl_save.p_y = _ctl_cancel.p_y;

   _ctl_group.p_x = hmargin;
   _ctl_group.p_width = p_width - 2*hmargin;
   _ctl_group.p_y = vmargin;
   _ctl_group.p_height = p_height - _ctl_save.p_height - vmargin*3;

   _ctl_error.p_x = hmargin;
   _ctl_error.p_width = _ctl_group.p_width - 2*hmargin;
   _ctl_error.p_height = _ctl_group.p_height - vmargin - _ctl_error.p_y;

   tbrmargin := _ctl_group.p_width - hmargin - _ctl_browsefile.p_width;
   _ctl_profile_name.p_width = tbrmargin - _ctl_profile_name.p_x;
   _ctl_program.p_width = tbrmargin - _ctl_program.p_x;
   sizeBrowseButtonToTextBox(_ctl_program.p_window_id, _ctl_browsefile.p_window_id, 
                             0, 0);
   _ctl_cmdline.p_width = tbrmargin - _ctl_cmdline.p_x;
   _ctl_rundir.p_width = tbrmargin - _ctl_rundir.p_x;
   _ctl_minPeriodMs.p_width = tbrmargin - _ctl_minPeriodMs.p_x;

   _ctl_add_envvar.p_x = _ctl_browsefile.p_x;
   _ctl_del_envvar.p_x = _ctl_browsefile.p_x;
   _ctl_edit_envvar.p_x = _ctl_browsefile.p_x;
   _ctl_envvars.p_width = tbrmargin - _ctl_envvars.p_x;
}

void _ctl_save.on_create()
{
   p_active_form.p_caption = 'Edit profile "'gEditProfile.origProfileName'"';
   _ctl_profile_name.p_text = gEditProfile.origProfileName;
   _ctl_profile_name.p_enabled = false;
   _ctl_program.p_text = gEditProfile.program;
   _ctl_cmdline.p_text = gEditProfile.cmdline;
   _ctl_rundir.p_text = gEditProfile.runDirectory;
   _ctl_minPeriodMs.p_text = gEditProfile.minPeriodMs;
   _ctl_error.p_caption = '';
   sizeBrowseButtonToTextBox(_ctl_program.p_window_id, _ctl_browsefile.p_window_id, 
                             0, 0);

   _ctl_envvars._TreeDelete(TREE_ROOT_INDEX,'C');
   _ctl_envvars._TreeSetColButtonInfo(0,1300,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Name");
   _ctl_envvars._TreeSetColButtonInfo(1,-1,TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT,0,"Value");
   _ctl_envvars._TreeAdjustLastColButtonWidth();

   k := '';
   v := '';

   foreach (k, v in gEditProfile.environment) {
      _ctl_envvars._TreeAddItem(TREE_ROOT_INDEX,k"\t"v,
                                TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
   }

   validate();
   update_env_buttons();
}

static bool alreadyHaveEnv(_str key)
{
   rv := false;

   int i; 
   for (i = _ctl_envvars._TreeGetFirstChildIndex(0); i >= 0; 
         i = _ctl_envvars._TreeGetNextSiblingIndex(i)) {
      _str k, v;
      readEnvVar(i, k, v);
      if (k == key) {
         rv = true;
         break;
      }
   }

   return rv;
}

static void do_edit_envvar()
{
   index:=_ctl_envvars._TreeCurIndex();

   if (index > 0 && _ctl_envvars._TreeIndexIsValid(index)) {
      readEnvVar(index, auto key, auto val);
      _str promptResult = show("-modal _textbox_form",
                               "Edit the value of "key,
                               0,
                               "",
                               "",
                               "",
                               "",
                               "Value:" val );

      if (promptResult:=="") {
         return;
      }

      _ctl_envvars._TreeSetCaption(index, strip(key)"\t"_param1);
      update_env_buttons();
   }
}

void _ctl_add_envvar.lbutton_up()
{
   working := true;

   do {
      _str promptResult = show("-modal _textbox_form",
                               "Enter the new environment variable",
                               0,
                               "",
                               "",
                               "",
                               "",
                               "Name:" "",
                               "Value:" "" );

      if (promptResult:=="") {
         return;
      }

      if (alreadyHaveEnv(_param1)) {
         _message_box('Environment var "'_param1'" already exists.');
         continue;
      }

      _ctl_envvars._TreeAddItem(TREE_ROOT_INDEX,strip(_param1)"\t"_param2,
                                TREE_ADD_AS_CHILD,0,0,TREE_NODE_LEAF);
      working = false;
      update_env_buttons();
   } while (working);
}

void _ctl_del_envvar.lbutton_up()
{
   index:=_ctl_envvars._TreeCurIndex();

   if (index > 0 && _ctl_envvars._TreeIndexIsValid(index)) {
      _ctl_envvars._TreeDelete(index);
      update_env_buttons();
   }
}

void _ctl_edit_envvar.lbutton_up()
{
   do_edit_envvar();
}

void _ctl_envvars.on_change2()
{
   update_env_buttons();
}

