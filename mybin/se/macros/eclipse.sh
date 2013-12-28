////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45613 $
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
#ifndef ECLIPSE_SH
#define ECLIPSE_SH

// View names.
#define ECLIPSE_SEARCHOUTPUT_VIEW_NAME "SlickEditSearchOutputView"
#define ECLIPSE_SYMBOLOUTPUT_VIEW_NAME "SlickEditSymbolOutputView"
#define ECLIPSE_OUTPUT_VIEW_NAME "SlickEditOutputView"
#define ECLIPSE_REFERENCESOUTPUT_VIEW_NAME "SlickEditReferencesOutputView"
#define ECLIPSE_BUILDOUTPUT_VIEW_NAME "SlickEditBuildOutputView"
#define ECLIPSE_CLASSBROWSER_VIEW_NAME "SlickEditClassBrowserView"
#define ECLIPSE_FTPOPEN_VIEW_NAME "SlickEditFTPOpenView"

// SWT container forms.
#define ECLIPSE_PROCTREE_CONTAINERFORM_NAME "ctlEclipseProcTreeForm"
#define ECLIPSE_SEARCHOUTPUT_CONTAINERFORM_NAME "ctlEclipseSearchOutputForm"
#define ECLIPSE_SYMBOLOUTPUT_CONTAINERFORM_NAME "ctlEclipseSymbolOutputForm"
#define ECLIPSE_REFERENCESOUTPUT_CONTAINERFORM_NAME "ctlEclipseReferencesOutputForm"
#define ECLIPSE_BUILDOUTPUT_CONTAINERFORM_NAME "ctlEclipseBuildOutputForm"
#define ECLIPSE_CLASSBROWSER_CONTAINERFORM_NAME "ctlEclipseClassBrowserForm"
#define ECLIPSE_FTPOPEN_CONTAINERFORM_NAME "ctlEclipseFTPOpenForm"
#define ECLIPSE_FTPCLIENT_CONTAINERFORM_NAME "ctlEclipseFTPClientForm"
#define ECLIPSE_CLASS_CONTAINERFORM_NAME "ctlEclipseClassForm"
#define ECLIPSE_EMULATION_CONTAINERFORM_NAME "ctlEclipseEmulationForm"
#define ECLIPSE_OUTPUT_CONTAINERFORM_NAME "ctlEclipseOutputForm"

// Slick-C forms.
#define ECLIPSE_PROCTREE_FORM_NAME_STRING '_tbproctree_form'
#define ECLIPSE_SEARCHOUTPUT_FORM_NAME_STRING '_tbsearch_form'
#define ECLIPSE_SYMBOLOUTPUT_FORM_NAME_STRING '_tbtagwin_form'
#define ECLIPSE_REFERENCESOUTPUT_FORM_NAME_STRING '_tbtagrefs_form'
#define ECLIPSE_BUILDOUTPUT_FORM_NAME_STRING '_eclipseBuildOutputForm'
#define ECLIPSE_CLASS_FORM_NAME_STRING '_tbclass_form'
#define ECLIPSE_CLASSBROWSER_FORM_NAME_STRING '_tbcbrowser_form'
#define ECLIPSE_FTPOPEN_FORM_NAME_STRING '_tbFTPOpen_form'
#define ECLIPSE_FTPCLIENT_FORM_NAME_STRING '_tbFTPClient_form'
#define ECLIPSE_EMULATION_FORM_NAME_STRING '_eclipse_emulation_form'
#define ECLIPSE_OUTPUT_FORM_NAME_STRING '_tboutputwin_form'

//Java Command IDs that can be invoked with _eclipse_dispatchCommand(String cmdId)
#define ECLIPSE_RESTART_DEBUG_CMD 'com.slickedit.core.commands.RestartDebug'
#define ECLIPSE_STOP_DEBUG_CMD 'com.slickedit.core.commands.StopDebug'
#define ECLIPSE_RUN_CMD 'com.slickedit.core.commands.Run'
#define ECLIPSE_STEP_OVER_CMD 'com.slickedit.core.commands.StepOver'
#define ECLIPSE_RUN_TO_LINE_CMD 'com.slickedit.core.commands.RunToLine'
#define ECLIPSE_CLEAR_ALL_BREAKPOINTS_CMD 'com.slickedit.core.commands.ClearAllBreakpoints'
#define ECLIPSE_STEP_INTO_CMD 'com.slickedit.core.commands.StepInto'
#define ECLIPSE_STEP_RETURN_CMD 'com.slickedit.core.commands.StepReturn'
#define ECLIPSE_RESUME_EXECUTION_CMD 'com.slickedit.core.commands.ResumeExecution'
#define ECLIPSE_ACTIVATE_BREAKPOINT_VIEW_CMD 'com.slickedit.core.commands.ActiveBreakpointView'
#define ECLIPSE_ACTIVATE_VAR_VIEW_CMD 'com.slickedit.core.commands.ActivateVarView'   
#define ECLIPSE_ACTIVATE_CALL_STACK_CMD 'com.slickedit.core.commands.ActivateCallStack'
#define ECLIPSE_ACTIVATE_WATCH_VIEW_CMD 'com.slickedit.core.commands.ActivateWatchView'
#define ECLIPSE_DEBUG_CMD "com.slickedit.core.commands.Debug"

#define ECLIPSE_ORGANIZE_IMPORTS "com.slickedit.javasup.commands.refactor.VSEOrganizeImportsAction"
#define ECLIPSE_NEXT_WINDOW "com.slickedit.core.commands.VSENextWindow"
#define ECLIPSE_BROWSE "com.slickedit.core.commands.BrowseForOpen"
#define ECLIPSE_OVERRIDE_METHODS "com.slickedit.javasup.commands.refactor.VSEOverrideMethodsAction"

//Events
#define ECLIPSE_EV_HEX_TOGGLE "com.slickedit.core.events.HexToggle"
#define ECLIPSE_EV_LINE_HEX_TOGGLE "com.slickedit.core.events.LineHexToggle"
#define ECLIPSE_EV_SPECIAL_CHARS_TOGGLE "com.slickedit.core.events.SpecialCharsToggle"
#define ECLIPSE_EV_NLCHARS_TOGGLE "com.slickedit.core.events.NewLineCharsToggle"
#define ECLIPSE_EV_TABCHARS_TOGGLE "com.slickedit.core.events.TabCharsToggle"
#define ECLIPSE_EV_SPACECHARS_TOGGLE "com.slickedit.core.events.SpaceCharsToggle"
#define ECLIPSE_EV_LINE_NUMS_TOGGLE"com.slickedit.core.events.LineNumbersToggle"
#define ECLIPSE_EV_SOFTWRAP_TOGGLE "com.slickedit.core.events.SoftWrapToggle"
#define ECLIPSE_EV_INDENT_TABS_TOGGLE "com.slickedit.core.events.IndentWithTabsToggle"
#define ECLIPSE_EV_WORD_WRAP_TOGGLE "com.slickedit.core.events.WordWrapToggle"
#define ECLIPSE_EV_READ_ONLY_TOGGLE "com.slickedit.core.events.ReadOnlyToggle"

extern void _handle_popup2(int menu_handle, boolean isEditor);
extern int _eclipse_createbreakpoint(int wid, int line);
extern int _eclipse_togglebreakpoint(int wid, int line);
extern int _eclipse_removebreakpoint(int wid, int line);
extern int _eclipse_enablebreakpoint(int wid, int line);
extern int _eclipse_disablebreakpoint(int wid, int line);
extern int _eclipse_breakpointProperties(int wid, int line);
extern int _eclipse_addbookmark(int wid, _str label);
extern int _eclipse_addtaskmark(int wid);
extern int _eclipse_gotobookmark(int wid, _str label);
extern int _eclipse_bookmark_exists(int wid, int line);
extern int _eclipse_debug_active();
extern _str _eclipse_evaluate_expression(_str e);
extern int _eclipse_removebookmark(int wid, int line);
extern int _eclipse_removetask(int wid, int line);
extern int _eclipse_save(int wid, _str cmdline,int flags);
extern int _eclipse_set_dirty(int wid, boolean val);
extern int _eclipse_save_as(int wid, _str cmdline,int flags);
extern int _eclipse_new(int wid, _str cmdline);
extern int _eclipse_close_editor(int wid, _str bufname,int modifyFlags);
extern void _eclipse_help(_str keyword);
extern int _eclipse_set_def_font();
extern int _eclipse_next_error(int wid);
extern int _eclipse_prev_error(int wid);
extern int _eclipse_next_bookmark(int wid);
extern int _eclipse_prev_bookmark(int wid);
extern int _eclipse_get_eclipse_version_string(_str&);
extern int _eclipse_get_jdt_version_string(_str&);
extern int _eclipse_get_cdt_version_string(_str&);
extern int _eclipse_get_project_tagfile_string(_str&);
extern int _eclipse_get_project_includes_string(_str&);
extern int _eclipse_get_project_defines_string(_str&);
extern int _eclipse_get_c_project_name_string(_str&);
extern int _eclipse_set_tagging_excludes(_str);
extern int _eclipse_get_active_project_name(_str&);
extern int _eclipse_get_workspace_name(_str&);
extern int _eclipse_get_workspace_dir(_str&);
extern int _eclipse_get_project_dir(_str&);
extern int _eclipse_open(int wid, _str filename);
extern int _eclipse_list_buffers();
extern int _eclipse_refresh_workspace();
extern int _eclipse_close_all(...);
extern int eclipse_setNoMoreGTK();
extern int _eclipse_doIdleWork();
_command eclipse_plugin_disable();
_command javaMenu_handler(_str cmdName="");
_command eclipse_Compact();
_command eclipse_BlockComment();
_command eclipse_BlockUncomment();
_command eclipse_LineComment();
_command eclipse_LineUncomment();
extern int _eclipse_changeActiveKeyConfiguration(_str emulation);
extern int _eclipse_list_keys(_str emulation, _str keyListText);
extern int _eclipse_setSupportedExtensions(_str extensions);
extern int _refswindow_Activate();
extern _str eclipse_get_version();
extern _str _getEclipseBuildDate();
extern int _refswindow_IsActive();
extern int _symbolwindow_Activate();
extern int _outputWindow_QFormWID(int forceCreate);
extern int _outputWindow_activate();
extern int _cbquit_eclipse(int buf_id,_str buf_name,_str DocumentName,int buf_flags);
extern int _isClassBrowserActive();
extern int _activateClassBrowser();
extern int _eclipse_dispatchCommand(_str cmd_id);
extern int _eclipse_toggle_breakpoint_enable(int wid, int line);
extern void translateKeySequences(var keyList);
extern int _eclipse_workspace_build();
extern int _eclipse_project_build();
extern int _eclipse_project_clean();
extern int _eclipse_get_all_jdks(_str eclipse_jdks);
extern void _eclipse_file_open();
extern int _eclipse_update_tag_list(_str proj_name); 
extern int _eclipse_get_projects_tagfiles(_str projectTagFiles); 
extern int _eclipse_get_toast_coords(_str coords); 
extern int _eclipse_validate_edit(_str fname);
extern void _eclipse_show_in_navigator();
extern void _eclipse_split_window_horiz();
extern void _eclipse_split_window_vert();
extern void _eclipse_change_window(_str dir);
extern void _eclipse_delete_window(_str dir);
extern void _eclipse_next_window();
extern void _eclipse_prev_window();
extern void _eclipse_full_screen();
extern int _eclipse_set_breakpoint_in_file(_str file, int line);
extern int _eclipse_ProjectWorkspaceFindFile(_str file, _str&);
extern int _eclipse_paintStatusIcons(_str imageFileName, int show);
extern int _eclipse_retag();
/**
 * Allows programmatic execution of Eclipse commands from the
 * Slick-C environment, as long as the correct command 
 * identifier is provided.  Parameters are optional.  Note that 
 * some commands in Eclipse are specific to a certain editor, 
 * and thus, will not work when launched from the SlickEdit 
 * editor. 
 *  
 * Write your own Slick-C wrapper function to 
 * _eclipse_execute_command in order to set a key binding to the
 * Eclipse command of choice. 
 *  
 * Use the Eclipse Keys dialog in conjunction with the Plug-in 
 * Registry View in order to find the id and parameter 
 * information for the command you wish to execute. 
 *  
 * @param id Identifier of the Eclipse command. 
 * @param paramNames Comma delimited string of the paramater 
 *                   names to pass to id.  Can be null or empty
 *                   string.
 * @param paramValues Comma delimited string of the parameter 
 *                    values for the params specified in
 *                    paramNames. Can be null or empty string.
 * 
 * @example
 * <pre>
 * // Execute a command with no parameters - Bring up the About Eclipse dialog 
 * _eclipse_execute_command("org.eclipse.ui.help.aboutAction","","");
 * </pre>
 *
 * @example
 * <pre>
 * // Execute a command with parameters - Show the Problems view 
 * _eclipse_execute_command("org.eclipse.ui.window.showViewMenu","org.eclipse.ui.views.showView.viewId","ProblemView"); 
 * </pre>
 * 
 */
extern void _eclipse_execute_command(_str id, _str paramNames, _str paramValues);

#endif

