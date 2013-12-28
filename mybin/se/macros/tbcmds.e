////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46471 $
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
#include "toolbar.sh"
#import "eclipse.e"
#import "tagrefs.e"
#import "tbprops.e"
#import "tbsearch.e"
#import "tbview.e"
#import "toolbar.e"
#endregion

_command activate_search()  name_info(','VSARG2_EDITORCTL)
{
   _str focus_ctl = _get_active_grep_view();
   return activate_toolbar("_tbsearch_form", focus_ctl);
}

_command activate_tagwin,activate_symbol,activate_preview()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbtagwin_form","ctltaglist");
}

_command activate_references()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ) {
      _ActivateReferencesWindow();
   }
   return activate_toolbar("_tbtagrefs_form","ctlrefname");
}

_command activate_build()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbshell_form","_shellEditor");
}

_command activate_output()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tboutputwin_form","ctloutput");
}

_command activate_projects,activate_project_files()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('Projects','_proj_tooltab_tree');
   activate_toolbar('_tbprojects_form','_proj_tooltab_tree');
}

/**
 * Activate the current context tool window and drop down the
 * list of symbols in the current context.
 * 
 * @param noDropDown  If 1, just activate window, 
 *                    do not drop down list.   
 */
_command void activate_context(_str noDropDown="") name_info(','VSARG2_EDITORCTL)
{
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

_command activate_defs,activate_project_procs,activate_project_defs()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('Defs','_proc_tree');
   activate_toolbar('_tbproctree_form','_proc_tree');
}

_command void activate_files()  name_info(','VSARG2_EDITORCTL)
{
   activate_toolbar('_tbfilelist_form','ctl_filter');
}

_command void activate_files_files()  name_info(','VSARG2_EDITORCTL)
{
   activate_toolbar('_tbfilelist_form','ctl_filter');
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

_command void activate_files_project()  name_info(','VSARG2_EDITORCTL)
{
   activate_toolbar('_tbfilelist_form','ctl_proj_filter');
   filelist_activate_tab(1/*FILELIST_SHOW_PROJECT_FILES*/);
}

_command void activate_files_workspace()  name_info(','VSARG2_EDITORCTL)
{
   activate_toolbar('_tbfilelist_form','ctl_wksp_filter');
   filelist_activate_tab(2/*FILELIST_SHOW_WORKSPACE_FILES*/);
}

_command activate_find_symbol()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbfind_symbol_form','ctl_search_for');
}

_command activate_cbrowser,activate_project_classes,activate_symbols_browser()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('Classes','ctl_class_tree_view');
   return activate_toolbar('_tbcbrowser_form','ctl_class_tree_view');
}

_command activate_ftp,activate_project_ftp()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('FTP','_ctl_remote_dir');
   return activate_toolbar('_tbFTPOpen_form','_ctl_remote_dir');
}

_command activate_project()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('','ctl_class_tree_view');
   return activate_toolbar('_tbcbrowser_form','ctl_class_tree_view');
}

_command activate_open,activate_project_open()  name_info(','VSARG2_EDITORCTL)
{
   //activate_project_tab('Open','_openfile_list');
   return activate_toolbar('_tbopen_form','_file_name_filter');
}

int _DebugToolbarOnUpdate(_str FormName='')
{
   if (!_tbDebugQMode() || (FormName!='' && !_tbDebugListToolbarForm(FormName))) {
      return(MF_GRAYED);
   }
   return(MF_ENABLED);
}

int _OnUpdate_activate_call_stack(CMDUI &cmdui,int target_wid,_str command)
{
   if( isEclipsePlugin() ){
      return MF_ENABLED;
   }
   return (_DebugToolbarOnUpdate());
}

_command activate_call_stack()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ) {
      return eclipse_show_callstack();
   }
   return activate_toolbar('_tbdebug_stack_form','ctl_stack_tree');
}

int _OnUpdate_activate_locals(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate());
}

_command activate_locals()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_locals_form","ctl_locals_tree");
}

int _OnUpdate_activate_locals2(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate());
}

_command activate_locals2()  name_info(','VSARG2_EDITORCTL)
{
   activate_locals();
}

int _OnUpdate_activate_members(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate());
}

_command activate_members()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_members_form","ctl_members_tree");
}

int _OnUpdate_activate_members2(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate());
}

_command activate_members2()  name_info(','VSARG2_EDITORCTL)
{
   activate_members();
}

int _OnUpdate_activate_watch(CMDUI &cmdui,int target_wid,_str command)
{
   if( isEclipsePlugin() ){
      return MF_ENABLED;
   }
   return (_DebugToolbarOnUpdate());
}

_command activate_watch()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ){
      return eclipse_show_watches();
   }
   activate_tab('Watch1','ctl_watches_tree1','_tbdebug_watches_form','ctl_sstab');
}

_command activate_watch2()  name_info(','VSARG2_EDITORCTL)
{
   activate_tab('2','ctl_watches_tree1','_tbdebug_watches_form','ctl_sstab');
}

_command activate_watch3()  name_info(','VSARG2_EDITORCTL)
{
   activate_tab('3','ctl_watches_tree1','_tbdebug_watches_form','ctl_sstab');
}

_command activate_watch4()  name_info(','VSARG2_EDITORCTL)
{
   activate_tab('4','ctl_watches_tree1','_tbdebug_watches_form','ctl_sstab');
}

int _OnUpdate_activate_autos(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate());
}

_command activate_autos()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_autovars_form","ctl_autovars_tree");
}

int _OnUpdate_activate_variables(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()){
      return MF_ENABLED;
   }
   return(_DebugToolbarOnUpdate('_tbdebug_autovars_form'));
}

_command activate_variables()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ) {
      return eclipse_show_variables();
   }
   return activate_toolbar('_tbdebug_autovars_form','ctl_autovars_tree');
}

int _OnUpdate_activate_threads(CMDUI &cmdui,int target_wid,_str command)
{
   return (_DebugToolbarOnUpdate());
}

_command activate_threads() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbdebug_threads_form','ctl_threads_tree');
}

int _OnUpdate_activate_classes(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate('_tbdebug_classes_form'));
}

_command activate_classes() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_classes_form","ctl_classes_tree");
}

int _OnUpdate_activate_registers(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate('_tbdebug_regs_form'));
}

_command activate_registers()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbdebug_regs_form','ctl_registers_tree');
}

int _OnUpdate_activate_memory(CMDUI &cmdui,int target_wid,_str command)
{
   return(_DebugToolbarOnUpdate('_tbdebug_memory_form'));
}

_command activate_memory()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbdebug_memory_form','ctl_address_combo');
}
int _OnUpdate_activate_breakpoints(CMDUI &cmdui,int target_wid,_str command)
{
   return(_project_name!='')? MF_ENABLED:MF_GRAYED;
}

_command activate_breakpoints()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ){
      return eclipse_show_breakpoints();
   }
   return activate_toolbar("_tbdebug_breakpoints_form","ctl_breakpoints_tree");
}

_command activate_annotations() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbannotations_browser_form', '_annotation_tree');
}

_command activate_messages() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbmessages_browser_form', '_message_tree');
}

_command activate_bookmarks()  name_info(','VSARG2_EDITORCTL)
{
   if( isEclipsePlugin() ){
      int new_wid = eclipse_gotobookmark();
      if (new_wid > 0) return 0;
      return new_wid;
   }
   return activate_toolbar("_tbbookmarks_form","ctl_bookmarks_tree");
}

_command activate_exceptions()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_exceptions_form","ctl_exceptions_tree");
}

_command activate_sessions() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbdebug_sessions_form","_tbdebug_combo_etab");
}

_command activate_find()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbfind_form","_findstring");
}

/**
 * Toggles the display of the Context Tagging(R) toolbar.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_tagging()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbtagging_form');
}

/**
 * Toggles the display of the Current Context tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_context()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbcontext_form');
}

/**
 * Toggles the display of the HTML toolbar.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_html()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbhtml_form');
}

/**
 * Toggles the display of the FTP Client tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftp()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbFTPClient_form');
}

/**
 * Toggles the display of the Slick-C(R) Stack tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_stack()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbslickc_stack_form');
}

/**
 * Toggles the display of the Symbol Properties tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_properties()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbprops_form');
}

/**
 * Toggles the display of the Search results tool window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_search()  name_info(','VSARG2_EDITORCTL)
{
   _str focus_ctl = _get_active_grep_view();
   _tbToggleTabGroupToolbar('_tbsearch_form',focus_ctl);
}

/**
 * Toggles the display of the Preview tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_symbol,toggle_tagwin,toggle_preview()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbtagwin_form','ctltaglist');
}

/**
 * Toggles the display of the References tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_refs,toggle_tagrefs()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbtagrefs_form','ctlrefname');
}

/**
 * Toggles the display of the Build tool window.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_build,toggle_shell()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbshell_form','_shellEditor');
}

/**
 * Toggles the display of the Output tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_output,toggle_outputwin()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tboutputwin_form','ctloutput');
}

/**
 * Toggles the display of the File Tabs tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_filetabs,toggle_bufftabs()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbbufftabs_form');
}

/**
 * Toggles the display of the Projects tool window.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_projects,toggle_project() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbprojects_form','_proj_tooltab_tree');
}

/**
 * Toggles the display of the Defs tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_defs,toggle_procs,toggle_proctree() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbproctree_form','_proc_tree');
}

/**
 * Toggles the display of the Files tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_files() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbfilelist_form','_file_list');
}

/**
 * Toggles the display of the Find Symbol tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions, Search_Functions
 */
_command void toggle_find_symbol() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbfind_symbol_form','ctl_search_for');
}

/**
 * Toggles the display of the Symbols tool window.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_cbrowser() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbcbrowser_form','ctl_class_tree_view');
}

/**
 * Toggles the display of the Open tool window.
 *
 * @categories Toolbar_Functions, Buffer_Functions
 */
_command void toggle_open() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbopen_form','_file_tree');
}

/**
 * Toggles the display of the FTP tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_ftpopen() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbFTPOpen_form','_ctl_remote_dir');
}

/**
 * Toggles the display of the Standard toolbar.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_standard() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbstandard_form');
}

/**
 * Toggles the display of the Project Tools toolbar.
 *
 * @categories Toolbar_Functions, Project_Functions
 */
_command void toggle_project_tools() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbproject_tools_form');
}

/**
 * Toggles the display of the Debug toolbar.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_debug()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebugbb_form');
}

/**
 * Toggles the display of the Debug Sessions tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_debug_sessions()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_sessions_form');
}

/**
 * Toggles the display of the Call Stack tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_call_stack()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_stack_form','ctl_stack_tree');
}

/**
 * Toggles the display of the Locals tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_locals()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_locals_form','ctl_locals_tree');
}

/**
 * Toggles the display of the Members tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_members()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_members_form','ctl_members_tree');
}

/**
 * Toggles the display of the Watch tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_watch()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_watches_form','ctl_watches_tree1');
}

/**
 * Toggles the display of the Autos tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_variables()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_autovars_form','ctl_autovars_tree');
}

/**
 * Toggles the display of the Threads tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_threads()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_threads_form','ctl_threads_tree');
}

/**
 * Toggles the display of the Loaded Classes tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_classes()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_classes_form','ctl_classes_tree');
}

/**
 * Toggles the display of the Exceptions tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_exceptions()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_exceptions_form','ctl_exceptions_tree');
}

/**
 * Toggles the display of the Registers tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_registers()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_regs_form','ctl_registers_tree');
}

/**
 * Toggles the display of the Memory tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_memory()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_memory_form','ctl_memory_tree');
}

/**
 * Toggles the display of the Breakpoints tool window.
 *
 * @categories Toolbar_Functions, Debugger_Commands
 */
_command void toggle_breakpoints()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdebug_breakpoints_form','ctl_breakpoints_tree');
}

/**
 * Toggles the display of the Bookmarks tool window.
 *
 * @categories Toolbar_Functions, Bookmark_Functions
 */
_command void toggle_bookmarks()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbbookmarks_form','ctl_bookmarks_tree');
}

/**
 * Toggles the display of the Find and Replace tool window.
 *
 * @categories Toolbar_Functions, Search_Functions
 */
_command void toggle_find() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbfind_form', '_findstring');
}

/**
 * Toggles the display of the Backup History tool window.
 *
 * @categories Toolbar_Functions, File_Functions
 */
_command void toggle_deltasave,toggle_backup_history()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbdeltasave_form', 'ctltree1');
}

/**
 * Toggles the display of the Code Annotations tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_annotations_browser() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbannotations_browser_form',
                            '_type_list');
}

/**
 * Toggles the display of the Message List tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_messages() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbmessages_browser_form',
                            '_message_tree');
}

/**
 * Toggles the display of the Clipboards tool window.
 *
 * @categories Toolbar_Functions
 */
_command void toggle_clipboards() name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbclipboard_form', 'ctl_clipboard_list');
}

_command activate_clipboards()  name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar("_tbclipboard_form", 'ctl_clipboard_list');
}

/**
 * Toggles the display of the Android toolbar.
 *
 * @categories Toolbar_Functions, Tagging_Functions
 */
_command void toggle_android()  name_info(','VSARG2_EDITORCTL)
{
   _tbToggleTabGroupToolbar('_tbandroid_form');
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
_command void activate_project_toolbar() name_info(','VSARG2_EDITORCTL)
{
   if( 0!=activate_toolbar_tabgroup('_tbprojects_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbproctree_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbcbrowser_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbopen_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbftpopen_form') ) return;
   // If we got here, then one of the following:
   // 1. None of the tool windows are showing.
   // 2. One or more of the tool windows are auto hidden, but none are active.
   // Arbitrarily pick the first tab of the old Output toolbar grouping
   // to show.
   tbSmartShow('_tbprojects_form');
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
_command void activate_output_toolbar() name_info(','VSARG2_EDITORCTL)
{
   if( 0!=activate_toolbar_tabgroup('_tbsearch_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbtagwin_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbtagrefs_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tbshell_form') ) return;
   if( 0!=activate_toolbar_tabgroup('_tboutputwin_form') ) return;
   // If we got here, then one of the following:
   // 1. None of the tool windows are showing.
   // 2. One or more of the tool windows are auto hidden, but none are active.
   // Arbitrarily pick the first tab of the old Project toolbar grouping
   // to show.
   tbSmartShow('_tbsearch_form');
}

_command void activate_tag_properties_toolbar() name_info(','VSARG2_EDITORCTL)
{
   activate_tab('Properties','','_tbprops_form','ctl_props_sstab');
}
