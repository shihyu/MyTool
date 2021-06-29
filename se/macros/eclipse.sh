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
#pragma option(metadata,"eclipse.e")

// View names.
const ECLIPSE_SEARCHOUTPUT_VIEW_NAME= "SlickEditSearchOutputView";
const ECLIPSE_SYMBOLOUTPUT_VIEW_NAME= "SlickEditSymbolOutputView";
const ECLIPSE_OUTPUT_VIEW_NAME= "SlickEditOutputView";
const ECLIPSE_REFERENCESOUTPUT_VIEW_NAME= "SlickEditReferencesOutputView";
const ECLIPSE_BUILDOUTPUT_VIEW_NAME= "SlickEditBuildOutputView";
const ECLIPSE_CLASSBROWSER_VIEW_NAME= "SlickEditClassBrowserView";
const ECLIPSE_FTPOPEN_VIEW_NAME= "SlickEditFTPOpenView";

// SWT container forms.
const ECLIPSE_PROCTREE_CONTAINERFORM_NAME= "ctlEclipseProcTreeForm";
const ECLIPSE_SEARCHOUTPUT_CONTAINERFORM_NAME= "ctlEclipseSearchOutputForm";
const ECLIPSE_SYMBOLOUTPUT_CONTAINERFORM_NAME= "ctlEclipseSymbolOutputForm";
const ECLIPSE_REFERENCESOUTPUT_CONTAINERFORM_NAME= "ctlEclipseReferencesOutputForm";
const ECLIPSE_BUILDOUTPUT_CONTAINERFORM_NAME= "ctlEclipseBuildOutputForm";
const ECLIPSE_CLASSBROWSER_CONTAINERFORM_NAME= "ctlEclipseClassBrowserForm";
const ECLIPSE_FTPOPEN_CONTAINERFORM_NAME= "ctlEclipseFTPOpenForm";
const ECLIPSE_FTPCLIENT_CONTAINERFORM_NAME= "ctlEclipseFTPClientForm";
const ECLIPSE_CLASS_CONTAINERFORM_NAME= "ctlEclipseClassForm";
const ECLIPSE_EMULATION_CONTAINERFORM_NAME= "ctlEclipseEmulationForm";
const ECLIPSE_OUTPUT_CONTAINERFORM_NAME= "ctlEclipseOutputForm";

// Slick-C forms.
const ECLIPSE_PROCTREE_FORM_NAME_STRING= '_tbproctree_form';
const ECLIPSE_SEARCHOUTPUT_FORM_NAME_STRING= '_tbsearch_form';
const ECLIPSE_SYMBOLOUTPUT_FORM_NAME_STRING= '_tbtagwin_form';
const ECLIPSE_REFERENCESOUTPUT_FORM_NAME_STRING= '_tbtagrefs_form';
const ECLIPSE_BUILDOUTPUT_FORM_NAME_STRING= '_eclipseBuildOutputForm';
const ECLIPSE_CLASS_FORM_NAME_STRING= '_tbclass_form';
const ECLIPSE_CLASSBROWSER_FORM_NAME_STRING= '_tbcbrowser_form';
const ECLIPSE_FTPOPEN_FORM_NAME_STRING= '_tbFTPOpen_form';
const ECLIPSE_FTPCLIENT_FORM_NAME_STRING= '_tbFTPClient_form';
const ECLIPSE_EMULATION_FORM_NAME_STRING= '_eclipse_emulation_form';
const ECLIPSE_OUTPUT_FORM_NAME_STRING= '_tboutputwin_form';

//Java Command IDs that can be invoked with _eclipse_dispatchCommand(String cmdId)
const ECLIPSE_RESTART_DEBUG_CMD= 'com.slickedit.core.commands.RestartDebug';
const ECLIPSE_STOP_DEBUG_CMD= 'com.slickedit.core.commands.StopDebug';
const ECLIPSE_RUN_CMD= 'com.slickedit.core.commands.Run';
const ECLIPSE_STEP_OVER_CMD= 'com.slickedit.core.commands.StepOver';
const ECLIPSE_RUN_TO_LINE_CMD= 'com.slickedit.core.commands.RunToLine';
const ECLIPSE_CLEAR_ALL_BREAKPOINTS_CMD= 'com.slickedit.core.commands.ClearAllBreakpoints';
const ECLIPSE_STEP_INTO_CMD= 'com.slickedit.core.commands.StepInto';
const ECLIPSE_STEP_RETURN_CMD= 'com.slickedit.core.commands.StepReturn';
const ECLIPSE_RESUME_EXECUTION_CMD= 'com.slickedit.core.commands.ResumeExecution';
const ECLIPSE_ACTIVATE_BREAKPOINT_VIEW_CMD= 'com.slickedit.core.commands.ActiveBreakpointView';
const ECLIPSE_ACTIVATE_VAR_VIEW_CMD= 'com.slickedit.core.commands.ActivateVarView'   ;
const ECLIPSE_ACTIVATE_CALL_STACK_CMD= 'com.slickedit.core.commands.ActivateCallStack';
const ECLIPSE_ACTIVATE_WATCH_VIEW_CMD= 'com.slickedit.core.commands.ActivateWatchView';
const ECLIPSE_DEBUG_CMD= "com.slickedit.core.commands.Debug";

const ECLIPSE_ORGANIZE_IMPORTS= "com.slickedit.javasup.commands.refactor.VSEOrganizeImportsAction";
const ECLIPSE_NEXT_WINDOW= "com.slickedit.core.commands.VSENextWindow";
const ECLIPSE_BROWSE= "com.slickedit.core.commands.BrowseForOpen";
const ECLIPSE_OVERRIDE_METHODS= "com.slickedit.javasup.commands.refactor.VSEOverrideMethodsAction";

//Events
const ECLIPSE_EV_HEX_TOGGLE= "com.slickedit.core.events.HexToggle";
const ECLIPSE_EV_LINE_HEX_TOGGLE= "com.slickedit.core.events.LineHexToggle";
const ECLIPSE_EV_SPECIAL_CHARS_TOGGLE= "com.slickedit.core.events.SpecialCharsToggle";
const ECLIPSE_EV_NLCHARS_TOGGLE= "com.slickedit.core.events.NewLineCharsToggle";
const ECLIPSE_EV_TABCHARS_TOGGLE= "com.slickedit.core.events.TabCharsToggle";
const ECLIPSE_EV_SPACECHARS_TOGGLE= "com.slickedit.core.events.SpaceCharsToggle";
const ECLIPSE_EV_LINE_NUMS_TOGGLE="com.slickedit.core.events.LineNumbersToggle";
const ECLIPSE_EV_SOFTWRAP_TOGGLE= "com.slickedit.core.events.SoftWrapToggle";
const ECLIPSE_EV_INDENT_TABS_TOGGLE= "com.slickedit.core.events.IndentWithTabsToggle";
const ECLIPSE_EV_WORD_WRAP_TOGGLE= "com.slickedit.core.events.WordWrapToggle";
const ECLIPSE_EV_READ_ONLY_TOGGLE= "com.slickedit.core.events.ReadOnlyToggle";

extern void _handle_popup2(int menu_handle, bool isEditor);
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
extern int _eclipse_set_dirty(int wid, bool val);
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

