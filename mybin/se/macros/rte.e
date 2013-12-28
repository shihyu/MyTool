////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48298 $
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
#import "fileman.e"
#import "javaopts.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "projconv.e"
#import "project.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "wkspace.e"
#endregion

static boolean g_first;
int last_error;

// Jave Live errors def vars that are needed across multiple files
_str def_java_live_errors_jdk_6_dir = "";
_str def_java_live_errors_jvm_lib= "";
int def_java_live_errors_enabled = 0;
int def_java_live_errors_first = 1;
int def_java_live_errors_errored= 0;
int def_java_live_errors_incremental_compile = 0;


definit()
{
   g_first = true;
   last_error = -1;
}


/**
 * RTE does not work on Solaris 6, so this function can tell if the current OS is Solaris 5.6.
 * 
 * This function will be used to disable RTE in the case where the OS is Solaris 6.
 * 
 * @return 
 */
boolean isSolaris56()
{
#if __UNIX__
   struct UNAME info;
   _uname(info);
   return(info.release == '5.6' && info.sysname == 'SunOS');
#else
   return false;
#endif
}

void _workspace_file_add_rte(_str projName, _str fileName)
{
   if(def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }
   extension := _get_extension(fileName,false);
   lang      := _Ext2LangId(extension);
   if (!_LanguageInheritsFrom('java', lang)) {
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
void _project_close_rte(_str projName)
{
   if(def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }

   int hProject = _ProjectHandle(projName);
   if (hProject) {
      int result = rteRemoveProject(hProject);
      if (result != 0) {
         rte_abort(result);
      }
   }
}

_str maybeCreateRTEOutputDir(){
   _str rte_path=_ConfigPath();
   _maybe_append_filesep(rte_path);
   rte_path = rte_path :+ "java_rte_classes" :+ FILESEP;
   _str wspace_root = _strip_filename(_workspace_filename, 'EN');
#if !__UNIX__
   wspace_root = stranslate(wspace_root, "",":");
#endif
   _str rte_output_dir = rte_path :+ wspace_root;
   if (!isdirectory(rte_output_dir) && _ProjectGet_ActiveType() == 'java') {
      int status = make_path(rte_output_dir);
      if (status != 0) {
         return("");
      } 
   }
   return(rte_output_dir);
}
int _workspace_opened_rte(_str sp_from_android='')
{
   if(def_java_live_errors_enabled == 0 || isSolaris56()) {
      return -1;
   }

   _str rte_output_dir = maybeCreateRTEOutputDir();

   if (rte_output_dir :== "") {
      return -1;
   }

   java_get_jdk_classpath();


   _str _projects[];
   int result = rteSetJDKPath(def_jdk_install_dir);
   if (result != 0) {
      rte_abort(result);
      return -1;
   }
   if (gWorkspaceHandle <= 0) {
      return -1;
   }
   _WorkspaceGet_ProjectFiles(gWorkspaceHandle, _projects);

   int j = 0, i = 0;
   if (_projects._length() < 1) {
      return -1;
   }
// say("rte workspace opened");
   _str cur_db = tag_current_db();
   tag_read_db(_GetWorkspaceTagsFilename());
   for (i = 0; i < _projects._length(); i++) {
      _str _fullPath = _AbsoluteToWorkspace(_projects[i]);

      int hProject = _ProjectHandle(_fullPath);
      _str config = '';
      _ProjectGet_ActiveConfigOrExt(_fullPath, hProject, config);
      _str type = _ProjectGet_Type(hProject,config);
      _str sp_from_other = '';
      if (type == 'java') {
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
         _str src_compliance = substr(rest,1,3);
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
         _str prefix = def_java_live_errors_jdk_6_dir;
         _maybe_append_filesep(prefix);
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

         _str fileList[];
         int status = _getProjectFiles(_workspace_filename, _fullPath, fileList, 1, hProject);
         if (status) {
            rte_abort(result);
            return(-1);
         }

         for (k := 0; k < fileList._length(); k++) {
            if (_get_extension(fileList[k]) == 'java') {
               result = rteAddFile(hProject, fileList[k]);
               if (result != 0) {
                  rte_abort(result);
                  return(-1);
               }
               _str pkg_root = find_pkg_root(hProject, fileList[k]);
               rteMaybeAddToSourcePath(hProject, pkg_root);
            }
         }

         if (sp_from_other != '' && def_java_live_errors_other_options) {
            rteMaybeAddToSourcePath(hProject, sp_from_other);
         }

         if (sp_from_android != '') {
            rteMaybeAddToSourcePath(hProject, sp_from_android);
         }

      }

   }
   tag_read_db(cur_db);
   return 0;
}

_str rte_strip_sourcepath_from_other_options(_str &other_opts){
   int sp_index = pos("-sourcepath",other_opts);
   if (sp_index <= 0) {
      return '';
   }
   int sp_start_index = pos(" ",other_opts,sp_index);
   if (sp_start_index <= 0) {
      return '';
   }
   int next_option_start = pos(" -",other_opts,sp_start_index);
   int sp_end_index = next_option_start > 0 ? next_option_start - sp_start_index : -1; 
   _str sp_from_other_opts = substr(other_opts,sp_start_index,sp_end_index);
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
   _str dependencyClassPath="";
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
   _str translated_class_path = _replace_envvars2(classPath);

   _str output_path = _ProjectGet_ObjectDir(hProject,config);
   _str full_output_path = _AbsoluteToProject(output_path, _fullPath);

   _str jdk_classes = def_java_live_errors_jdk_6_dir :+ PATHSEP :+ translated_class_path :+ PATHSEP;

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
   _str dir = _strip_filename(filename, "N");
   _str packageName=FindPackage(filename,false);
   if (packageName == '') {
      packageName = FindPackage(filename,true);
      if (packageName == '') {
         return(dir);
      }
   }
   _str package_mod=stranslate(packageName, FILESEP,'.');
   package_mod = package_mod :+ FILESEP;
   int l1 = length(package_mod);
   int l2 = length(dir);
   if( l1 > l2 ) {
      return(dir);
   }
   _str tail = substr(dir,l2-l1+1);
   if( package_mod!= tail ) {
      return(dir);
   }
   _str pkg_root = substr(dir, 1, l2 - l1);
   return(pkg_root);
}

static boolean extra_push:[];


/**
 * This function is used to cycle through Java live errors in the current file.
 */
_command void rte_next_error() name_info(','VSARG2_EDITORCTL) {
   int editor_wid = p_window_id;
   if (!_isEditorCtl()) {
      editor_wid = _mdi.p_child;
   }
   if (_no_child_windows() || !_mdi.p_child._LanguageInheritsFrom('java')) {
      return;
   }
   if(def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }
   int line = rteNextError(editor_wid.p_line, editor_wid.p_buf_name);
   if (line > -1) {
      editor_wid.goto_line(line);
   } else if (line == -1) {
      message("No errors found in current file.");
   }
}

void rteUpdateBuffers()
{
   // if it's not a java buffer...bail
   if (_no_child_windows() || !_mdi.p_child._LanguageInheritsFrom('java')) {
      return;
   }

   // only trying to activate live errors for them the first time this module is loaded
   if (def_java_live_errors_first) {
      java_maybe_activate_live_errors();
      if (def_java_live_errors_enabled == 0) {
         // if we haven't automatically activated live errors based on JDK 6...
         def_java_live_errors_jdk_6_dir = "";
         def_java_live_errors_jvm_lib = "";
      } else {
/*         _str rte_path=_config_path();
         _maybe_append_filesep(rte_path);
         rte_path = rte_path :+ "java_rte_classes";
         if (!isdirectory(rte_path)) {
            mkdir(rte_path);
         }*/
      }
      def_java_live_errors_first= 0;
   }

   if(def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }
   if (def_java_live_errors_errored) {
      def_java_live_errors_enabled = 0;
      rte_abort(last_error);
      return;
   }
   if(def_java_live_errors_jdk_6_dir == '') {
      return;
   }

   int editorctl_wid = _mdi.p_child;
   if(_isdiffed(editorctl_wid.p_buf_id)) {
      return;
   }

   if (g_first) {

      int result = JavaLiveErrors_SetOptionsFromDefVars();
      if (result != 0) {
         rte_abort(result);
         return;
      }
/*      _str rte_path=_config_path();
      _maybe_append_filesep(rte_path);
      rte_path = rte_path :+ "java_rte_classes";
      if (!isdirectory(rte_path)) {
         mkdir(rte_path);
      }*/
      if (_workspace_opened_rte()== 0) {
         g_first = false;
      }
      return;
   }
//   rteSetJDKPath(def_jdk_install_dir);
   int result = rteSetActiveBuffer(editorctl_wid.p_window_id, editorctl_wid.p_buf_id, editorctl_wid.p_buf_name);
   if (result != 0) {
      rte_abort(result);
      return;
   }
   // this adds the errors
   int status = rteUpdateEditor(editorctl_wid.p_window_id, editorctl_wid.p_buf_name, editorctl_wid.p_buf_id);
   int orig_view_id = p_window_id;
   int first_buf = 0;
   int temp_view_id = 0;
   if (!HaveBuffer()) {
      return;
   }
   _open_temp_view('',temp_view_id,orig_view_id,'+bi 'RETRIEVE_BUF_ID);
   _next_buffer('NR');
   // there is at least 1 file open
   first_buf=p_buf_id;

   for (;;) {
      if (!(p_buf_flags&VSBUFFLAG_HIDDEN) &&  _get_extension(p_buf_name) == "java") {
         p_KeepPictureGutter = true;
         if ( p_file_date == '' || p_file_date == 0 ) {
            save();
         }
      
//         if(p_modify) {
               rtePushBuffer(p_window_id, p_buf_id, p_buf_name);
//         }
//         }
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
 * @return boolean         true if there are open buffers, false if not 
 *  
 * @categories Buffer_Functions
 */
boolean HaveBuffer()
{
   return(buf_match('',1,'v')!='');
}

void _wkspace_close_rte()
{

}
void workspace_open_rte(_str name)
{
   if (def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }

   _workspace_opened_rte();

}
void _exit_rte()
{
   if (def_java_live_errors_enabled == 0 || isSolaris56()) {
      return;
   }
   rteShutdown(0);
}

// For turning off Live Errors when the editor is running.
// Will clear out error markers.
_command rteStop()
{
   rteShutdown(1);
}

void rte_abort(int e){
   _message_box("Java Live Errors encountered a JVM-related error and must shut down.\n":+
                "Please select Build > Java Options and select the Live Errors tab to re-enable Live Errors.\n\n":+
                "Error: ":+get_message(e):+"\n\n":+
                "Note: Live Errors in SlickEdit 64-bit requires a 64-bit JVM.");
   rteShutdown(1);
   def_java_live_errors_enabled = 0;
}

void rte_set_errored(int e){
   def_java_live_errors_errored = 1;
   last_error = e;
}
