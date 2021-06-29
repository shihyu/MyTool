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
#include "markers.sh"
#include "toolbar.sh"
#include "se/ui/toolwindow.sh"
#import "debug.e"
#import "eclipse.e"
#import "help.e"
#import "main.e"
#import "tagrefs.e"
#import "tbprops.e"
#import "tbsearch.e"
#import "tbview.e"
#import "toolbar.e"
#import "tbterminal.e"
#import "se/ui/toolwindow.e"
#import "stdprocs.e"
#endregion

ToolWindowInfo g_toolwindowtab:[];

_command activate_search()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _str focus_ctl = _get_active_grep_view();
   return activate_tool_window("_tbsearch_form", true, focus_ctl, true);
}

_command activate_tagwin,activate_symbol,activate_preview()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Preview window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return activate_tool_window("_tbtagwin_form", true, "ctltaglist", true);
}

/**
 * Activate the References tool window.
 *  
 * @see push_ref
 * 
 * @categories Tagging_Functions
 */
_command activate_references()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( isEclipsePlugin() ) {
      _ActivateReferencesWindow();
   }
   return activate_tool_window("_tbtagrefs_form", true, "ctlrefname", true);
}

_command activate_build()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Build window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return activate_tool_window("_tbshell_form", true, "_shellEditor", true);
}

_command activate_terminal()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Terminal window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str focus_ctl = _get_active_terminal_view();
   return activate_tool_window("_tbterminal_form", true, focus_ctl, true);
}

_command activate_interactive()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Interactive window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   _str focus_ctl = _get_active_interactive_view();
   return activate_tool_window("_tbinteractive_form", true, focus_ctl, true);
}

_command activate_output()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_tool_window("_tboutputwin_form", true, "ctloutput", true);
}

_command activate_projects,activate_project_files()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //activate_project_tab('Projects','_proj_tooltab_tree');
   activate_tool_window('_tbprojects_form', true, '_proj_tooltab_tree', true);
}

/**
 * Activate the current context tool window and drop down the
 * list of symbols in the current context.
 * 
 * @param noDropDown  If 1, just activate window, 
 *                    do not drop down list.   
 */
_command void activate_context(_str noDropDown="") name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveCurrentContextToolBar()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Current Context toolbar");
      return;
   }
   // First activate the tool window
   activate_toolbar('_tbcontext_form', '_tbcontext_combo_etab');
   // Next drop down the list
   if (noDropDown==1) return;
   formwid  := _find_formobj('_tbcontext_form', 'n');
   if (!formwid) return;
   combowid := formwid._find_control('_tbcontext_combo_etab');
   if (!combowid) return;
   combowid.call_event(combowid,F4,'w');
}

_command void activate_defs,activate_project_procs,activate_project_defs()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Defs tool window");
      return;
   }
   //activate_project_tab('Defs','_proc_tree');
   activate_tool_window('_tbproctree_form', true, '_proc_tree', true);
}

_command void activate_files()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   activate_tool_window('_tbfilelist_form', true, 'ctl_filter', true);
}

_command void activate_files_files()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   activate_tool_window('_tbfilelist_form', true, 'ctl_filter', true);
   filelist_activate_tab(0/*FILELIST_SHOW_OPEN_FILES*/);
}

static void filelist_activate_tab(int tabIndex)
{
   formwid  := _find_formobj('_tbfilelist_form', 'n');
   if (!formwid) return;

   sstab := formwid._find_control("ctl_sstab");
   if (!sstab) return;

   sstab.p_ActiveTab = tabIndex;
}

_command void activate_files_project()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   activate_tool_window('_tbfilelist_form', true, 'ctl_proj_filter', true);
   filelist_activate_tab(1/*FILELIST_SHOW_PROJECT_FILES*/);
}

_command void activate_files_workspace()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   activate_tool_window('_tbfilelist_form', true, 'ctl_wksp_filter', true);
   filelist_activate_tab(2/*FILELIST_SHOW_WORKSPACE_FILES*/);
}

/**
 * Activate the Find Symbol tool window.
 *  
 * @see push_tag 
 * @see gui_push_tag 
 * 
 * @categories Tagging_Functions
 */
_command activate_find_symbol()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return activate_tool_window('_tbfind_symbol_form', true, 'ctl_search_for', true);
}

_command activate_cbrowser,activate_project_classes,activate_symbols_browser()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Symbols tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   //activate_project_tab('Classes','ctl_class_tree_view');
   return activate_tool_window('_tbcbrowser_form', true, 'ctl_class_tree_view', true);
}

_command activate_ftp,activate_project_ftp()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "FTP");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   //activate_project_tab('FTP','_ctl_remote_dir');
   return activate_tool_window('_tbFTPOpen_form', true, '_ctl_remote_dir', true);
}

_command activate_project()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //activate_project_tab('','ctl_class_tree_view');
   return activate_tool_window('_tbcbrowser_form', true, 'ctl_class_tree_view', true);
}

_command activate_open,activate_project_open(bool restore_group=true)  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //activate_project_tab('Open','_openfile_list');
   return activate_tool_window('_tbopen_form', true, '_file_name_filter', restore_group);
}

static int _DebugToolbarOnUpdate(_str FormName='')
{
   if (!_haveDebugging()) {
      return(MF_GRAYED|MF_REQUIRES_PRO);
   }
   if (!_tbDebugQMode() || (FormName!='' && !_tbDebugListToolbarForm(FormName))) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

int _OnUpdate_activate_call_stack(CMDUI& cmdui, int target_wid, _str command)
{
   if( isEclipsePlugin() ){
      return MF_ENABLED;
   }
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_stack")) return MF_GRAYED;
   return (_DebugToolbarOnUpdate());
}

_command activate_call_stack()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( isEclipsePlugin() ) {
      return eclipse_show_callstack();
   }
   if (!debug_session_is_implemented("update_stack")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window('_tbdebug_stack_form', true, 'ctl_stack_tree', true);
}

int _OnUpdate_activate_locals(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_locals")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate());
}

_command activate_locals()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_locals")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window("_tbdebug_locals_form", true, "ctl_locals_tree", true);
}

int _OnUpdate_activate_locals2(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_locals")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate());
}

_command activate_locals2()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   activate_locals();
}

int _OnUpdate_activate_members(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_members")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate());
}

_command activate_members()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_members")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window("_tbdebug_members_form", true, "ctl_members_tree", true);
}

int _OnUpdate_activate_members2(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_members")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate());
}

_command activate_members2()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   activate_members();
}


void activate_tab(_str ActiveTabCaption, _str PutFocusOnCtlName,
                  _str FormName, _str TabControlName)
{
   if( !tw_is_allowed(FormName) ) {
      return;
   }
   int wid = tw_is_visible(FormName);
   if ( wid == 0 ) {
      // This will restore the users last location of the tool-window
      show_tool_window(FormName);
   }
   wid = tw_is_visible(FormName);
   if ( wid != 0 ) {
      tabid := wid._find_control(TabControlName);
      SSTABCONTAINERINFO info;
      int i, n = tabid.p_NofTabs;
      for ( i = 0; i < n; ++i ) {
         tabid._getTabInfo(i, info);
         if ( stranslate(info.caption, '', '&') == ActiveTabCaption ) {
            tabid.p_ActiveTab = i;
            p_window_id = tabid;
            ctlwid := wid._find_control(PutFocusOnCtlName);
            if ( ctlwid > 0 ) {
               ctlwid._set_focus();
            }
         }
      }
      if ( ActiveTabCaption == '' ) {
         wid._set_focus();
      }
   }
}

_command activate_watch()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( isEclipsePlugin() ){
      return eclipse_show_watches();
   }
   activate_tab('Watch1', 'ctl_watches_tree1', '_tbdebug_watches_form', 'ctl_watches_sstab');
}
int _OnUpdate_activate_watch(CMDUI& cmdui, int target_wid, _str command)
{
   if( isEclipsePlugin() ){
      return MF_ENABLED;
   }
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_watches")) return MF_GRAYED;
   return (_DebugToolbarOnUpdate());
}


_command activate_watch2()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   activate_tab('2', 'ctl_watches_tree2', '_tbdebug_watches_form', 'ctl_watches_sstab');
}
int _OnUpdate_activate_watch2(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_activate_watch(cmdui, target_wid, command);
}

_command activate_watch3()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   activate_tab('3', 'ctl_watches_tree3', '_tbdebug_watches_form', 'ctl_watches_sstab');
}
int _OnUpdate_activate_watch3(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_activate_watch(cmdui, target_wid, command);
}

_command activate_watch4()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   activate_tab('4', 'ctl_watches_tree4', '_tbdebug_watches_form', 'ctl_watches_sstab');
}
int _OnUpdate_activate_watch4(CMDUI& cmdui, int target_wid, _str command)
{
   return _OnUpdate_activate_watch(cmdui, target_wid, command);
}

int _OnUpdate_activate_autos(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_autos")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate());
}
_command activate_autos()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_autos")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window("_tbdebug_autovars_form", true, "ctl_autovars_tree", true);
}

int _OnUpdate_activate_variables(CMDUI& cmdui, int target_wid, _str command)
{
   if(isEclipsePlugin()){
      return MF_ENABLED;
   }
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_autos")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate('_tbdebug_autovars_form'));
}

_command activate_variables()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( isEclipsePlugin() ) {
      return eclipse_show_variables();
   }
   if (!debug_session_is_implemented("update_autos")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window('_tbdebug_autovars_form', true, 'ctl_autovars_tree', true);
}

int _OnUpdate_activate_threads(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_threads")) return MF_GRAYED;
   return (_DebugToolbarOnUpdate());
}

_command activate_threads() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_threads")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window('_tbdebug_threads_form', true, 'ctl_threads_tree', true);
}

int _OnUpdate_activate_classes(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_classes")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate('_tbdebug_classes_form'));
}

_command activate_classes() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_classes")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window("_tbdebug_classes_form", true, "ctl_classes_tree", true);
}

int _OnUpdate_activate_registers(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_registers")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate('_tbdebug_regs_form'));
}

_command activate_registers()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_registers")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window('_tbdebug_regs_form', true, 'ctl_registers_tree', true);
}

int _OnUpdate_activate_memory(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_memory")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate('_tbdebug_memory_form'));
}

_command activate_memory()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("update_memory")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window('_tbdebug_memory_form', true, 'ctl_address_combo', true);
}
int _OnUpdate_activate_breakpoints(CMDUI& cmdui, int target_wid, _str command)
{
   return(_project_name!='')? MF_ENABLED:MF_GRAYED;
}

_command activate_breakpoints()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( isEclipsePlugin() ){
      return eclipse_show_breakpoints();
   }
   return activate_tool_window("_tbdebug_breakpoints_form", true, "ctl_breakpoints_tree", true);
}

_command activate_annotations() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveCodeAnnotations()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Code Annotations tool window");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return activate_tool_window('_tbannotations_browser_form', true, '_annotation_tree', true);
}

_command activate_messages() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild() && !_haveXMLValidation() && !_haveRealTimeErrors()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "The Messages tool window");
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG;
   }
   return activate_tool_window('_tbmessages_browser_form', true, '_message_tree', true);
}

_command activate_bookmarks()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if( isEclipsePlugin() ){
      int new_wid = eclipse_gotobookmark();
      if (new_wid > 0) return 0;
      return new_wid;
   }
   return activate_tool_window("_tbbookmarks_form", true, "ctl_bookmarks_tree", true);
}

int _OnUpdate_activate_exceptions(CMDUI& cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) return (MF_GRAYED|MF_REQUIRES_PRO);
   if (!debug_session_is_implemented("update_exceptions")) return MF_GRAYED;
   return(_DebugToolbarOnUpdate('_tbdebug_exceptions_form'));
}

_command activate_exceptions()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (!debug_session_is_implemented("enable_exception")) {
      popup_message(get_message(DEBUG_FEATURE_NOT_IMPLEMENTED_RC));
      return DEBUG_FEATURE_NOT_IMPLEMENTED_RC;
   }
   return activate_tool_window("_tbdebug_exceptions_form", true, "ctl_exceptions_tree", true);
}

_command activate_sessions() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return activate_toolbar("_tbdebug_sessions_form","_tbdebug_combo_etab");
}

_command activate_find()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_tool_window("_tbfind_form", true, "_findstring", true);
}

/**
 * Toggles the display of the Context Tagging(R) toolbar.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_tagging()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging"VSREGISTEREDTM);
      return;
   }
   toggle_toolbar('_tbtagging_form');
}

/**
 * Toggles the display of the Context Tagging(R) toolbar.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_vc()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version Control");
      return;
   }
   toggle_toolbar('_tbvc_form');
}

/**
 * Toggles the display of the HTML toolbar.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_html()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   toggle_toolbar('_tbhtml_form');
}

/**
 * Toggles the display of the Standard toolbar.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_standard() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   toggle_toolbar('_tbstandard_form');
}

/**
 * Toggles the display of the Android toolbar.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_android()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build");
      return;
   }
   toggle_toolbar('_tbandroid_form');
}

/**
 * Toggles the display of the Debug Sessions tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_debug_sessions()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   toggle_toolbar('_tbdebug_sessions_form');
}

/**
 * Toggles the display of the Current Context tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_context()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveCurrentContextToolBar()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Current Context toolbar");
      return;
   }
   toggle_toolbar('_tbcontext_form');
}

/**
 * Toggles the display of the Debug toolbar.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_debug()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   toggle_toolbar('_tbdebugbb_form');
}

/**
 * Toggles the display of the FTP Client tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftp()  name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "FTP");
      return;
   }
   tw_toggle_tabgroup('_tbFTPClient_form');
}
/**
 * Toggles the display of the FTP Client tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftp_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "FTP");
      return;
   }
   tw_toggle_tabgroup('_tbFTPClient_form', toggle_pinned:true);
}

/**
 * Toggles the display of the Slick-C(R) Stack tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_stack()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbslickc_stack_form');
}

/**
 * Toggles the display of the Slick-C(R) Stack tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_stack_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbslickc_stack_form', toggle_pinned:true);
}

/**
 * Toggles the display of the Symbol Properties tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_properties()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   tw_toggle_tabgroup('_tbsymbol_props_form');
}

/**
 * Toggles the display of the Symbol Properties tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_properties_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   tw_toggle_tabgroup('_tbsymbol_props_form', toggle_pinned:true);
}

/**
 * Toggles the display of the Symbol Arguments tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_arguments()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   tw_toggle_tabgroup('_tbsymbol_args_form');
}

/**
 * Toggles the display of the Symbol Arguments tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_arguments_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   tw_toggle_tabgroup('_tbsymbol_args_form', toggle_pinned:true);
}

/**
 * Toggles the display of the Search results tool window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_search()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbsearch_form', '_search_tab');
}
/**
 * Toggles the display of the Search results tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_search_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbsearch_form', '_search_tab', toggle_pinned:true);
}

/**
 * Toggles the display of the Preview tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_symbol,toggle_tagwin,toggle_preview()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   tw_toggle_tabgroup('_tbtagwin_form','ctltaglist');
}

/**
 * Toggles the display of the Preview tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_preview_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   tw_toggle_tabgroup('_tbtagwin_form','ctltaglist', toggle_pinned:true);
}

/**
 * Toggles the display of the References tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_refs,toggle_tagrefs()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }
   tw_toggle_tabgroup('_tbtagrefs_form','ctlrefname');
}

/**
 * Toggles the display of the References tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_refs_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "References");
      return;
   }
   tw_toggle_tabgroup('_tbtagrefs_form','ctlrefname', toggle_pinned:true);
}

/**
 * Toggles the display of the Build tool window.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_build,toggle_shell()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Build window");
      return;
   }
   tw_toggle_tabgroup('_tbshell_form','_shellEditor');
}
/**
 * Toggles the display of the Build tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_build_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Build window");
      return;
   }
   tw_toggle_tabgroup('_tbshell_form','_shellEditor', toggle_pinned:true);
}

/**
 * Toggles the display of the Terminal tool
 * window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_terminal()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbterminal_form', '_terminal_tab');
}
/**
 * Toggles the display of the Terminal tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_terminal_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbterminal_form', '_terminal_tab', toggle_pinned:true);
}

/**
 * Toggles the display of the Interactive tool
 * window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_interactive()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbinteractive_form', '_terminal_tab');
}
/**
 * Toggles the display of the Interactive tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_interactive_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbinteractive_form', '_terminal_tab', toggle_pinned:true);
}


/**
 * Toggles the display of the Output tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_output,toggle_outputwin()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tboutputwin_form','ctloutput');
}
/**
 * Toggles the display of the Output tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_output_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tboutputwin_form','ctloutput', toggle_pinned:true);
}

/**
 * Toggles the display of the File Tabs tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_filetabs,toggle_bufftabs()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFileTabsWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "File Tabs tool window");
      return;
   }
   tw_toggle_tabgroup('_tbbufftabs_form');
}

/**
 * Toggles the display of the Projects tool window.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_projects,toggle_project() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbprojects_form','_proj_tooltab_tree');
}
/**
 * Toggles the display of the Projects tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_projects_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbprojects_form','_proj_tooltab_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Defs tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_defs,toggle_procs,toggle_proctree() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Defs tool window");
      return;
   }
   tw_toggle_tabgroup('_tbproctree_form','_proc_tree');
}
/**
 * Toggles the display of the Defs tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_defs_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if (!_haveDefsToolWindow()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "Defs tool window");
      return;
   }
   tw_toggle_tabgroup('_tbproctree_form','_proc_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Files tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_files() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbfilelist_form','_file_list');
}
/**
 * Toggles the display of the Files tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_files_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbfilelist_form','_file_list', toggle_pinned:true);
}

/**
 * Toggles the display of the Find Symbol tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions, Search_Functions
 */
_command void toggle_find_symbol() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return;
   }
   tw_toggle_tabgroup('_tbfind_symbol_form','ctl_search_for');
}
/**
 * Toggles the display of the Find Symbol tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions, Search_Functions
 */
_command void toggle_find_symbol_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Find Symbol");
      return;
   }
   tw_toggle_tabgroup('_tbfind_symbol_form','ctl_search_for', toggle_pinned:true);
}

/**
 * Toggles the display of the Symbols tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_cbrowser() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Symbols tool window");
      return;
   }
   tw_toggle_tabgroup('_tbcbrowser_form','ctl_class_tree_view');
}
/**
 * Toggles the display of the Symbols tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_cbrowser_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Symbols tool window");
      return;
   }
   tw_toggle_tabgroup('_tbcbrowser_form','ctl_class_tree_view', toggle_pinned:true);
}

/**
 * Toggles the display of the Open tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_open() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //tw_toggle_tabgroup('_tbopen_form','_file_tree');
   tw_toggle_tabgroup('_tbopen_form','_file_name_filter');
}
/**
 * Toggles the display of the Open tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_open_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   //tw_toggle_tabgroup('_tbopen_form','_file_tree');
   tw_toggle_tabgroup('_tbopen_form','_file_name_filter', toggle_pinned:true);
}

/**
 * Toggles the display of the FTP tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftpopen() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "FTP");
      return;
   }
   tw_toggle_tabgroup('_tbFTPOpen_form','_ctl_remote_dir');
}
/**
 * Toggles the display of the FTP tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftpopen_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveFTP()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION, "FTP");
      return;
   }
   tw_toggle_tabgroup('_tbFTPOpen_form','_ctl_remote_dir', toggle_pinned:true);
}

/**
 * Toggles the display of the Project Tools toolbar.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_project_tools() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   toggle_toolbar('_tbproject_tools_form');
}

/**
 * Toggles the display of the Call Stack tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_call_stack()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_stack_form','ctl_stack_tree');
}
/**
 * Toggles the display of the Call Stack tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_call_stack_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_stack_form','ctl_stack_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Locals tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_locals()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_locals_form','ctl_locals_tree');
}

/**
 * Toggles the display of the Locals tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_locals_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_locals_form','ctl_locals_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Members tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_members()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_members_form','ctl_members_tree');
}
/**
 * Toggles the display of the Members tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_members_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_members_form','ctl_members_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Watch tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_watch()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_watches_form','ctl_watches_sstab');
}
/**
 * Toggles the display of the Watch tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_watch_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_watches_form','ctl_watches_sstab', toggle_pinned:true);
}

/**
 * Toggles the display of the Autos tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_variables()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_autovars_form','ctl_autovars_tree');
}
/**
 * Toggles the display of the Autos tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_variables_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_autovars_form','ctl_autovars_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Threads tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_threads()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_threads_form','ctl_threads_tree');
}
/**
 * Toggles the display of the Threads tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_threads_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_threads_form','ctl_threads_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Loaded Classes tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_classes()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_classes_form','ctl_classes_tree');
}
/**
 * Toggles the display of the Loaded Classes tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_classes_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_classes_form','ctl_classes_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Exceptions tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_exceptions()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_exceptions_form','ctl_exceptions_tree');
}
/**
 * Toggles the display of the Exceptions tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_exceptions_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_exceptions_form','ctl_exceptions_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Registers tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_registers()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_regs_form','ctl_registers_tree');
}
/**
 * Toggles the display of the Registers tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_registers_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_regs_form','ctl_registers_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Memory tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_memory()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_memory_form','ctl_memory_tree');
}
/**
 * Toggles the display of the Memory tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_memory_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_memory_form','ctl_memory_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Breakpoints tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_breakpoints()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_breakpoints_form','ctl_breakpoints_tree');
}
/**
 * Toggles the display of the Breakpoints tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_breakpoints_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   tw_toggle_tabgroup('_tbdebug_breakpoints_form','ctl_breakpoints_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Bookmarks tool window.
 *
 * @categories Toolbar_Functions, Bookmark_Functions
 */
_command void toggle_bookmarks()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbbookmarks_form','ctl_bookmarks_tree');
}
/**
 * Toggles the display of the Bookmarks tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Bookmark_Functions
 */
_command void toggle_bookmarks_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbbookmarks_form','ctl_bookmarks_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Find and Replace tool window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_find() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbfind_form', '_findstring');
}
/**
 * Toggles the display of the Find and Replace tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_find_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbfind_form', '_findstring', toggle_pinned:true);
}

/**
 * Toggles the display of the Backup History tool window.
 *
 * @categories Toolbar_Functions, File_Functions
 */
_command void toggle_deltasave,toggle_backup_history()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   tw_toggle_tabgroup('_tbdeltasave_form', 'ctltree1');
}
/**
 * Toggles the display of the Backup History tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions, File_Functions
 */
_command void toggle_backup_history_pinned()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveBackupHistory()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION_1ARG, "Backup History");
      return;
   }
   tw_toggle_tabgroup('_tbdeltasave_form', 'ctltree1', toggle_pinned:true);
}

/**
 * Toggles the display of the Code Annotations tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_annotations,toggle_annotations_browser() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Code Annotations tool window");
      return;
   }
   tw_toggle_tabgroup('_tbannotations_browser_form', '_type_list');
}

/**
 * Toggles the display of the Code Annotations tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_annotations_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "The Code Annotations tool window");
      return;
   }
   tw_toggle_tabgroup('_tbannotations_browser_form', '_type_list', toggle_pinned:true);
}

/**
 * Toggles the display of the Message List tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_messages() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbmessages_browser_form',
                      '_message_tree');
}
/**
 * Toggles the display of the Message List tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_messages_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbmessages_browser_form', '_message_tree', toggle_pinned:true);
}

/**
 * Toggles the display of the Clipboards tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_clipboards() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbclipboard_form', 'ctl_clipboard_list');
}

/**
 * Toggles the display of the Clipboards tool window between pinned and unpinned states.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_clipboards_pinned() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   tw_toggle_tabgroup('_tbclipboard_form', 'ctl_clipboard_list', toggle_pinned:true);
}

_command activate_clipboards()  name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   return activate_tool_window("_tbclipboard_form", true, 'ctl_clipboard_list', true);
}

/**
 * Activate the tabgroup that FormName tool window is tab-linked
 * into. Focus is put into the tool window that is active in the
 * tab group (not necessarily the tool window FormName).
 * <p>
 * Used to provide backward compatibility for activate_project_toolbar,
 * activate_output_toolbar legacy commands, since the tabs for the old
 * Project and Output toolbars were broken into separate tool windows.
 * 
 * @param FormName Name of the tool window form to find in tabgroup.
 * 
 * @return The wid of the active tool window (not necessarily the same
 * as the tool window with name FormName); otherwise 0.
 */
int activate_toolwindow_tabgroup(_str FormName)
{
   if ( !tw_is_allowed(FormName) ) {
      return 0;
   }
   int wid = tw_is_visible(FormName);
   if ( wid == 0 ) {
      return 0;
   }
   wid = tw_next_window(wid, 'C', false);
   if ( wid > 0 ) {
      tw_set_active(wid);
      call_event(wid, ON_GOT_FOCUS, 'W');
   }
   return wid;
}

/**
 * Provided for backward compatibility.
 * <p>
 * Explanation:
 * Pre-10.0, the Projects, Defs, Symbols, Open, and FTP tool windows
 * were tabs of a single toolbar called Project.
 * activate_project_toolbar was intended to activate that toolbar and
 * set focus to the active tab. As of 10.0, those tabs are now separate
 * tool windows, so the old behavior no longer applies. As a way of
 * maintaining a degree of backward compatiblity, one of the 5 tool
 * windows that correspond to the old tabs of the Project toolbar will
 * be located. If one of those tool windows exists in a tabgroup, then
 * the active tab of the tabgroup is given focus. If no tool window is
 * found, or is not active in the tabgroup, then the first tool window
 * that corresponds to the first old toolbar tab is activated.
 */
_command void activate_project_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if( 0!=activate_toolwindow_tabgroup('_tbprojects_form') ) return;
   if( _haveDefsToolWindow() && 0!=activate_toolwindow_tabgroup('_tbproctree_form') ) return;
   if( _haveContextTagging() && 0!=activate_toolwindow_tabgroup('_tbcbrowser_form') ) return;
   if( _haveSmartOpen() && 0!=activate_toolwindow_tabgroup('_tbopen_form') ) return;
   if( _haveFTP() && 0!=activate_toolwindow_tabgroup('_tbftpopen_form') ) return;
   // If we got here, then one of the following:
   // 1. None of the tool windows are showing.
   // 2. One or more of the tool windows are auto hidden, but none are active.
   // Arbitrarily pick the first tab of the old Project toolbar grouping
   // to show.
   activate_projects();
}

/**
 * Provided for backward compatibility.
 * <p>
 * Explanation:
 * Pre-10.0, the Search, Symbol, References, Build, and Output tool windows were tabs
 * of a single toolbar called Output. activate_output_toolbar was intended
 * to activate that toolbar and set focus to the active tab. As of 10.0,
 * those tabs are now separate tool windows, so the old behavior no longer
 * applies. As a way of maintaining a degree of backward compatiblity, one
 * of the 5 tool windows that correspond to the old tabs of the Output toolbar
 * will be located. If one of those tool windows exists in a tabgroup, then
 * the active tab of the tabgroup is given focus. If no tool window is found,
 * or is not active in the tabgroup, then the first tool window that corresponds
 * to the first old toolbar tab is activated.
 */
_command void activate_output_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   if( 0!=activate_toolwindow_tabgroup('_tbsearch_form') ) return;
   if( _haveContextTagging() && 0!=activate_toolwindow_tabgroup('_tbtagwin_form') ) return;
   if( _haveContextTagging() &&  0!=activate_toolwindow_tabgroup('_tbtagrefs_form') ) return;
   if( 0!=activate_toolwindow_tabgroup('_tbshell_form') ) return;
   if( 0!=activate_toolwindow_tabgroup('_tbterminal_form') ) return;
   if( 0!=activate_toolwindow_tabgroup('_tboutputwin_form') ) return;
   // If we got here, then one of the following:
   // 1. None of the tool windows are showing.
   // 2. One or more of the tool windows are auto hidden, but none are active.
   // Arbitrarily pick the first tab of the old Output toolbar grouping
   // to show.
   activate_search();
}

/**
 * Activate that "Symbol Properties" tool window. 
 *  
 * @note 
 * Provided for backward compatibility.
 * <p>
 * Explanation:
 * Pre-13.0, the Symbol Properties and Symbol Arguments tool windows were tabs
 * of a single toolbar. activate_tag_properties_toolbar was intended
 * to activate that toolbar and set focus to the active tab. As of 23.0,
 * those tabs are now separate tool windows, so the old behavior no longer
 * applies. As a way of maintaining a degree of backward compatiblity, one
 * of the 2 tool windows that correspond to the old tabs of the Output toolbar
 * will be located. If one of those tool windows exists in a tabgroup, then
 * the active tab of the tabgroup is given focus. If no tool window is found,
 * or is not active in the tabgroup, then the first tool window that corresponds
 * to the first old toolbar tab is activated. 
 */
_command void activate_tag_properties_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   activate_tool_window("_tbsymbol_props_form", true, "ctl_name_text_box", true);
}

/**
 * Activate that "Symbol Arguments" tool window. 
 *  
 * @note 
 * Provided for backward compatibility.
 * <p>
 * Explanation:
 * Pre-13.0, the Symbol Properties and Symbol Arguments tool windows were tabs
 * of a single toolbar. activate_tag_arguments_toolbar was intended
 * to activate that toolbar and set focus to the active tab. As of 23.0,
 * those tabs are now separate tool windows, so the old behavior no longer
 * applies. As a way of maintaining a degree of backward compatiblity, one
 * of the 2 tool windows that correspond to the old tabs of the Output toolbar
 * will be located. If one of those tool windows exists in a tabgroup, then
 * the active tab of the tabgroup is given focus. If no tool window is found,
 * or is not active in the tabgroup, then the first tool window that corresponds
 * to the first old toolbar tab is activated. 
 */
_command void activate_tag_arguments_toolbar() name_info(','VSARG2_EDITORCTL|VSARG2_READ_ONLY|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveContextTagging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Context Tagging":+VSREGISTEREDTM_TITLEBAR);
      return;
   }
   activate_tool_window("_tbsymbol_args_form", true, "ctl_aname_text_box", true);
}


/**
 * Display menu of open tool windows for navigation.
 *
 */
_command void quick_navigate_toolwindows() name_info(','VSARG2_READ_ONLY)
{
   int objhandle = find_index("_active_toolwindow_menu", oi2type(OI_MENU));
   if ( !objhandle ) {
      return;
   }
   int menu_handle = p_active_form._menu_load(objhandle, 'P');
   cur := 0;
   i := 0;
   // put an item in for the editor window
   if ( !_no_child_windows() ) {
      _menu_insert(menu_handle, cur++, MF_ENABLED, 'Editor', 'activate_editor');
   }
   _str formName;
   ToolWindowInfo info;
   foreach ( formName => info in g_toolwindowtab ) {

      int wid = tw_is_visible(formName);
      // menu insert if the tool window is open, and it's not file tabs
      if ( wid > 0 && wid.p_caption != 'File Tabs' ) {
         _menu_insert(menu_handle, cur++, MF_ENABLED, wid.p_caption, 'activate_and_focus_tool_window 'formName);
      }
   }
   x := 100;
   y := 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode, x, y);
   _map_xy(p_window_id, 0, x, y, SM_PIXEL);
   int flags2 = VPM_LEFTALIGN|VPM_LEFTBUTTON;
   int status = _menu_show(menu_handle, flags2, x, y);
   _menu_destroy(menu_handle);
}

_command void activate_and_focus_tool_window(_str form_name='') name_info(',')
{
   int wid = activate_tool_window(form_name);
   if ( wid ) {
      wid._set_focus();
   }
}
