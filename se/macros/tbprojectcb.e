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
#import "listbox.e"
#import "projconv.e"
#import "project.e"
#import "stdprocs.e"
#import "vstudiosln.e"
#import "wkspace.e"
#endregion

static int _tbproject_list_wids:[];
static int _tbproject_config_wids:[];

definit()
{
   if (arg(1) != 'L') {
      _tbproject_list_wids._makeempty();
      _tbproject_config_wids._makeempty();
   }
}

void _workspace_opened_toolbars_update()
{
   _toolbar_update_project_list();
   _toolbar_update_project_config();
}

void _toolbar_update_project_list()
{
   typeless i;
   for (i._makeempty();;) {
      _tbproject_list_wids._nextel(i);
      if (i._isempty()) break;
      if (_iswindow_valid(i)) {
         i._update_projects_cb();
      }
   }
   for (i._makeempty();;) {
      _tbproject_config_wids._nextel(i);
      if (i._isempty()) break;
      if (_iswindow_valid(i)) {
         i._update_project_configurations_cb();
      }
   }
}

void _toolbar_update_project_config()
{
   typeless i;
   for (i._makeempty();;) {
      _tbproject_config_wids._nextel(i);
      if (i._isempty()) break;
      if (_iswindow_valid(i)) {
         i._update_project_configurations_cb();
      }
   }
}

defeventtab _tbproject_list_etab;
static void _update_projects_cb()
{
   _lbdeselect_all();
   _lbclear();
   if (_workspace_filename == '') {
      _lbadd_item('no current project');
      p_text = 'no current project';
      return;
   }
   int i;
   filename := "";
   _str projects[] = null;
   int status = _GetWorkspaceFiles(_workspace_filename, projects);
   for (i = 0; i < projects._length(); ++i) {
      filename=strip(_strip_filename(GetProjectDisplayName(projects[i]),'P'),'B','"');
      _lbadd_item(filename, 0, _pic_project);
   }
   if (_project_name == '') {
      p_text = 'no current project';
   } else {
      current_project := GetProjectDisplayName(_project_name);
      p_text = strip(_strip_filename(current_project,'P'),'B','"');
   }
}

void _tbproject_list_etab.on_create()
{
   p_completion = NONE_ARG;
   p_style = PSCBO_NOEDIT;
   _tbproject_list_wids:[p_window_id] = p_window_id;
   _update_projects_cb();
}

void _tbproject_list_etab.on_destroy()
{
   _tbproject_list_wids._deleteel(p_window_id);
}

void _tbproject_list_etab.on_change(int reason, int index)
{
   // maybe we're already in the middle of updating...
   static bool on_update;
   if (on_update) return;

   if (reason == CHANGE_CLINE) {
      on_update = true;
      if (_workspace_filename != '') {

         // get the project files in the workspace to figure out which one this is
         _str projects[] = null;
         int status = _GetWorkspaceFiles(_workspace_filename, projects);
         if (projects._length() && index <= projects._length()) {
            // combo box index is 1-based
            _str project_name = projects[index - 1];
            project_name = absolute(project_name, _strip_filename(_workspace_filename, "NE"));
            if (project_name != _project_name) {
               workspace_set_active(project_name);
            }
         }
      }
      on_update = false;
   }
}

defeventtab _tbproject_config_etab;
static void _update_project_configurations_cb()
{
   if (p_user) return;
   _lbdeselect_all();
   _lbclear();
   if (_workspace_filename == '' || _project_name == '') {
      _lbadd_item('no current project');
      p_text = 'no current project';
      return;
   }

   int i;
   if (_workspace_filename != '' && (file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true)))) {
      _str config_names[];
      _str configList[];
      _SLNGetSolutionConfigs(_workspace_filename, configList);
      for (i = 0; i < config_names._length(); ++i) {
         _lbadd_item(config_names[i]);
      }
      p_text = gActiveSolutionConfig;

   } else {
      int handle = _ProjectHandle(_project_name);
      _str config_names[] = null;
      _ProjectGet_ConfigNames(handle, config_names);
      for (i = 0; i < config_names._length(); ++i) {
         _lbadd_item(config_names[i]);
      }
      active_config := GetCurrentConfigName(_project_name);
      p_text = active_config;
   }
}

void _tbproject_config_etab.on_create()
{
   p_user=0;
   p_completion = NONE_ARG;
   p_style = PSCBO_NOEDIT;
   _update_project_configurations_cb();
   _tbproject_config_wids:[p_window_id] = p_window_id;
}

void _tbproject_config_etab.on_destroy()
{
   _tbproject_config_wids._deleteel(p_window_id);
}

void _tbproject_config_etab.on_change(int reason)
{
   static bool on_update;
   if (on_update) return;

   {
      p_user=1;  // Ignore _update_project_configurations_cb()
      on_update = true;
      config_name := p_text;

      if (_workspace_filename != '' && (file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true)))) {
         solution_config_set_active(_maybe_quote_filename(config_name));
      } else {
         if (_project_name != '' && config_name != GetCurrentConfigName(_project_name)) {
            project_config_set_active(_maybe_quote_filename(config_name));
         }
      }
      on_update = false;
      p_user=0;
   }
}

