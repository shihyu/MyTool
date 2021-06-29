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
#pragma option(pedantic,on)
#include "slick.sh"
#include "gradle.sh"
#include "pipe.sh"
#include "xml.sh"
#import "ctadditem.e"
#import "diffprog.e"
#import "files.e"
#import "gradle.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "treeview.e"
#import "wizard.e"
#import "wkspace.e"
#import "saveload.e"
#import "vc.e"
#import "applet.e"

/** Location of the sbt install.  If not set, we look
 *  at the SBT_HOME environment variable, or just look for it 
 *  in standard install locations.
 */
_str def_sbt_home;

static _str unix_paths[] = {
   '/usr/share/sbt', '/usr/local/share/sbt', '/opt/sbt'
};
static _str windows_paths[];

static _str SBT_WRAPPER_EXTENSION() {
   return (_isWindows() ? ".bat":"");
}

static _str sbt_exe_relpath()
{
   return FILESEP'bin'FILESEP'sbt'SBT_WRAPPER_EXTENSION();
}

bool sbt_exe_exists(_str installDir) 
{
   return file_exists(installDir:+sbt_exe_relpath());
}

// Either return the set location, or try to find a candidate if 
// none is configured.
_str sbt_install_location() 
{
   _str rv = def_sbt_home;

   if (rv == '') {
      rv = get_env('SBT_HOME');
      if (rv == '' || !sbt_exe_exists(rv)) {
         _str locations[] =  _isUnix() ? unix_paths : windows_paths;
         rv = check_locations_for(sbt_exe_relpath(), locations);
      }

      if (rv == '') {
         rv = path_search('sbt'SBT_WRAPPER_EXTENSION(), 'PATH', 'P');
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

_str configured_sbt_exe()
{
   il := sbt_install_location();
   if (il == '') {
      return '';
   }

   return _maybe_quote_filename(il :+ sbt_exe_relpath());
}

// Runs the semicolon separated list of commands in 'cmds', 
// and if successful, returns >=0, and the temp view that contains
// the command's output. Returns a negative error code on error.
// If there is no error code, tempView exists, and may have error output
// from exec/SBT.
//
// Where possible, batching together sbt commands can help 
// performance, at least until we can run sbt as a long running shell.
int run_sbt_commands(_str cmds, int& tempView, int& origView)
{
   _str cmdArr[];

   split(cmds, ";", cmdArr);
   if (cmdArr._length() == 0) {
      return VSRC_INVALID_ARGUMENT;
   }

   cmdline := configured_sbt_exe();

   if (cmdline == '') {
      message('Location of SBT is not configured.');
      return FILE_NOT_FOUND_RC;
   }

   if (_isUnix()) {
      // Have to set this property to prevent SBT from hanging when 
      // the included JLine library execs 'stty' to fiddle with terminal settings.
      cmdline :+= ' -J-Djline.terminal="none" ';
   } else {
      cmdline :+= ' ';
   }
   cmd     := '';

   foreach (cmd in cmdArr) {
      cmdline :+= '"'cmd'" ';
   }

   oldmp := p_mouse_pointer;
   p_mouse_pointer = MP_HOUR_GLASS;

   rc = exec_command_to_temp_view(cmdline,tempView,origView, -1, 0, true);
   p_mouse_pointer = oldmp;

   return rc;
}

static int run_sbt_command_with_error_handling(_str cmds, int& tmpView, int &origView)
{
   rc := run_sbt_commands(cmds, tmpView, origView);

   if (rc > 0) {
      message('Error running SBT command: 'cmds);
      rc = FILE_NOT_FOUND_RC;
   }

   return rc;
}

static void goto_last_info_line()
{
   p_line = p_Noflines;
   rc := search('^\[info\]', '-<@l');
   if (rc != 0) {
      p_line = 1;
   }
}

static int get_known_task_names(_str (&tasks)[]) 
{
   int output_view, orig_view;

   rc := run_sbt_command_with_error_handling('tasks -V', output_view, orig_view);
   if (rc < 0) {
      return rc;
   }

   tasks._makeempty();

   // Skip any download or other noise from sbt/ivy at the beginning of the command.
   // This can happen the first time SBT is used on a system.
   top();
   goto_last_info_line();
   while (down() == 0) {
      _first_non_blank();
      if (p_col > 1) {
         word := cur_word(auto startCol);
         if (word != '') {
            tasks :+= word;
         }
      }
      p_line += 1;
   }
   _delete_temp_view(output_view);
   p_window_id = orig_view;

   return 0;
}

#define PSD_RE '^\[info\] +\* +' 
static void parse_source_dirs(_str (&srcDirs)[])
{
   int rc;

   srcDirs._makeempty();
   for (rc = search(PSD_RE, '>l@'); rc == 0; rc = search(PSD_RE, '>l@')) {
      get_line(auto line);
      stPos := text_col(line, p_col, 'P');
      srcDirs :+= strip(substr(line, stPos));
   }
}

static int get_source_directories(_str (&srcDirs)[])
{
   int output_view, orig_view;

   rc := run_sbt_command_with_error_handling('show sourceDirectories', output_view, orig_view);
   if (rc != 0) {
      return rc;
   }

   top();
   parse_source_dirs(srcDirs);
   p_window_id = orig_view;
   _delete_temp_view(output_view);

   return rc;
}

//
// Project support and wizard.


_str wiz_sbt_exe(bool useWrapper, bool forProjectFile = true, struct GradleWizData* wd = null)
{
   _str path;

   if (forProjectFile) {
      path = '"%(SE_SBT_HOME)'FILESEP'bin'FILESEP'sbt'SBT_WRAPPER_EXTENSION()'"';
   } else {
      path = '"'wd->selectedGradleHome:+FILESEP'bin'FILESEP'sbt'SBT_WRAPPER_EXTENSION()'"';
   }

   return path;
}

_str gen_sbt_execute_task()
{
   // We get 'run' for free, no?
   return '';
}

int load_known_sbt_tasks(GradleWizData* wd)
{
   // Temporarily apply sbt home from wizard data, so get_known_task_names() uses an up-to-date path.
   curSbtHome := def_sbt_home;
   def_sbt_home = wd->selectedGradleHome;

   wd->knownTasks._makeempty();
   get_known_task_names(wd->knownTasks);
   wd->knownTasks._sort();
   wd->parsedTasks = true;

   // Restore the setting so a cancel of the dialog won't leave this change in place.
   def_sbt_home = curSbtHome;

   // The wizard data also has projects.  We only support one project per sbt 
   // build for now.
   GradleProjectInfo pr;

   pr.name = wd->implicitProjName;
   pr.isRootProject = true;
   pr.dir = wd->projectDir;
   _maybe_strip_filesep(pr.dir);
   pr.tasks = wd->knownTasks;
   pr.compilerVer = '';
   pr.libSource._makeempty();

   wd->allProjects._makeempty();
   wd->allProjects :+= pr;

   return 0;
}

void save_sbt_home(_str path)
{
   def_sbt_home = path;
}

_str sbt_invocation_params(_str cmd, _str buildFileName)
{
   if (_isUnix()) {
      return ' -J-Djline.terminal="none" "'cmd'"';
   } else {
      return ' "'cmd'"';
   }
}

bool sbt_build_file_exists(_str projDir)
{
   s := projDir;
   _maybe_append_filesep(s);

   return file_exists(s'build.sbt');
}

// Specializations so we can use gradle's build system wizard.
static void sbt_specializations(ProjectWizardSpecializations& spec)
{
   spec.addDebugTask = false;
   spec.buildFileExists = find_index('sbt_build_file_exists', PROC_TYPE);
   spec.buildSystemExePath = find_index('wiz_sbt_exe', PROC_TYPE);
   spec.buildSystemInvocationParams = find_index('sbt_invocation_params', PROC_TYPE);
   spec.buildSystemName = 'sbt';
   spec.executeTask = find_index('gen_sbt_execute_task', PROC_TYPE);
   spec.guessedBuildSystemHome = sbt_install_location();
   spec.loadKnownTasks = find_index('load_known_sbt_tasks', PROC_TYPE);
   spec.setBuildSystemHome = find_index('save_sbt_home', PROC_TYPE);
   spec.sourcePaths._makeempty();
   spec.sourcePaths :+= 'src';
   spec.sourcePaths :+= 'src/main';
   spec.sourcePaths :+= 'src/main/java';
   spec.sourcePaths :+= 'src/main/resources';
   spec.sourcePaths :+= 'src/main/scala';
   spec.validBuildSystemPath = find_index('sbt_exe_exists', PROC_TYPE);
}

_command int new_sbt_proj(_str configName = 'Release') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   ProjectWizardSpecializations spec;
   sbt_specializations(spec);

   return setup_build_system_proj(configName, spec);
}

_command int reconfigure_sbt_project() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   ph := _ProjectHandle();

   if (ph < 0) {
      message("No project is open to be reconfigured.");
      return 0;
   }

   if (_ProjectGet_AppType(ph) != 'sbt') {
      message('Open project is not a sbt project');
      return 0;
   }

   ProjectWizardSpecializations spec;

   sbt_specializations(spec);
   setup_build_system_proj('Release', spec, false, false);
   return 0;
}

