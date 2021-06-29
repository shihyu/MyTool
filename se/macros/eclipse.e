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
#include "eclipse.sh"
#include "diff.sh"
#import "se/color/SymbolColorRuleBase.e"
#import "adaptiveformatting.e"
#import "commentformat.e"
#import "cbrowser.e"
#import "cjava.e"
#import "compile.e"
#import "diff.e"
#import "dir.e"
#import "files.e"
#import "ftpopen.e"
#import "guiopen.e"
#import "main.e"
#import "optionsxml.e"
#import "proctree.e"
#import "pushtag.e"
#import "saveload.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#import "setupext.e"
#import "xmlwrap.e"
#import "listproc.e"
#import "tagrefs.e"
#import "tags.e"
#import "tbcmds.e"
#import "tbfind.e"
#import "toolbar.e"
#import "tbprops.e"
#import "wkspace.e"
#endregion

static const ECLIPSE_MIN_IDLE_TIME= 500;

using se.color.SymbolColorRuleBase;

bool CalledFromEclipseFlag = false;
bool gEclipseInitialized = false;

/**
 * Clears the value of a configuration variable. 
 * 
 */
_command void eclipse_clear_var(_str varname="") name_info(',')
{
   index := find_index(varname,VAR_TYPE|BUFFER_TYPE);
   if (!index) {
     message(nls("Can't find variable '%s'",varname));
     return;
   }
   if (substr(varname,1,3)=='def') {
      _config_modify_flags(CFGMODIFY_DEFVAR);
   } else {
      _config_modify_flags(CFGMODIFY_MUSTSAVESTATE);
   }
   _set_var(index,"");
}

/**
 * Checks the file save options to see if we need to reset line 
 * modify markers after a save from Eclipse. 
 */
_command void eclipse_maybe_reset_modified_lines() name_info(',')
{
   int val = _fso_reset_line_modify();
   if (val == 1) {
      reset_modified_lines();
   }
}

_command void eclipse_find_in_files(_str path = '') name_info(',')
{
   find_in_files("",path);
}

/**
 * Opens Eclipse 'Open Resource' dialog.  Default key binding in
 * Eclipse is Ctrl+Shift+R. 
 */
_command void eclipse_open_resource() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.navigate.openResource","","");
   } else {
      smart_open();
   }
}

/**
 * Cycles forward through Eclipse view menu.
 */
_command void eclipse_next_view() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.nextView","","");
   } else {
      quick_navigate_toolwindows();
   }
}

/**
 * Cycles backward through Eclipse view menu.
 */
_command void eclipse_prev_view() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.previousView","","");
   } else {
      quick_navigate_toolwindows();
   }
}

/**
 * Toggles maximization of the active editor or view part in
 * Eclipse.
 */
_command void eclipse_maximize_part() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.maximizePart","","");
   } else {
      // todo
   }
}

/**
 * Opens the Eclipse 'New' Wizard.
 */
_command void eclipse_new_wizard() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.newWizard","","");
   } else {
      project_new_maybe_wizard();
   }
}

/**
 * Opens the Eclipse 'New' quick menu. 
 */
_command void eclipse_new_quick_menu() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.file.newQuickMenu","","");
   } else {
      project_new_maybe_wizard();
   }
}

/**
 * Cycles forward through the Eclipse editor menu. 
 */
_command void eclipse_next_editor() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.nextEditor","","");
   } else {
      list_buffers();
   }
}

/**
 * Cycles backward through the Eclipse editor menu. 
 */
_command void eclipse_prev_editor() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.nextEditor","","");
   } else {
      list_buffers();
   }
}

/**
 * Cycles forward through the Eclipse perspective menu. 
 */
_command void eclipse_next_perspective() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.nextPerspective","","");
   } else {
      // we don't have perspectives...
   }
}

/**
 * Cycles backward through the Eclipse perspective menu. 
 */
_command void eclipse_prev_perspective() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.previousPerspective","","");
   } else {
      // we don't have perspectives...
   }
}

/**
 * Activates editor when focus is on another Eclipse window. 
 * Default key binding in Eclipse is F12. 
 */
_command void eclipse_activate_editor() name_info(',')
{
    _eclipse_execute_command("org.eclipse.ui.window.activateEditor","","");
}

/**
 * Opens Eclipse quick gui access dialog.
 */
_command void eclipse_gui_quick_access() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.quickAccess","","");
   } else {
      // todo 
   }
}

/**
 * Opens Eclipse quick editor switch drop-down.
 */
_command void eclipse_quick_editor_switch() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.openEditorDropDown","","");
   } else {
      list_buffers();
   }
}

/**
 * Opens the Eclipse quick 'Show In...' menu.
 */
_command void eclipse_quick_show_in() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.navigate.showInQuickMenu","","");
   } else {
      int index = find_index("_eclipse_quick_show_in_menu", oi2type(OI_MENU));
      if (!index) {
         return;
      }
      int menu_handle = p_active_form._menu_load(index, 'P');
      x := 100;
      y := 100;
      x = mou_last_x('M') - x;
      y = mou_last_y('M') - y;
      _lxy2dxy(p_scale_mode, x, y);
      _map_xy(p_window_id, 0, x, y, SM_PIXEL);
      int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
      int status = _menu_show(menu_handle, flags, x, y);
      _menu_destroy(menu_handle);
   }
}

/**
 * Shows the Eclipse system menu.
 */
_command void eclipse_show_system_menu() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.showSystemMenu","","");
   }
}

/**
 * Shows the Eclipse 'show view' dialog.
 */
_command void eclipse_show_view() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.window.showViewMenu","","");
   } else {
      _tbContextMenu(true);
   }
}

/**
 * Navigates backward in the editor navigation history.
 */
_command void eclipse_backward_history() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.navigate.backwardHistory","","");
   } else {
      pop_bookmark();
   }
}

/**
 * Navigates forward in the editor navigation history.
 */
_command void eclipse_forward_history() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.navigate.forwardHistory","","");
   } else {
      push_tag();
   }
}

/**
 * Activates the 'Open Plug-in Artifact' gui in Eclipse. 
 */
_command void eclipse_open_plugin_artifact() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.pde.ui.openPluginArtifact","","");
   }
}

/**
 * Activates the Outline view in Eclipse.
 */
_command void eclipse_show_outline() name_info(',')
{
   if (isEclipsePlugin()) {
      _eclipse_execute_command("org.eclipse.ui.views.showView","org.eclipse.ui.views.showView.viewId,org.eclipse.ui.views.showView.makeFast", "org.eclipse.ui.views.ContentOutline,false");
   } else {
      activate_defs();
   }
}

/**
 * Called from com.slickedit.eclipse.views.ViewListener to 
 * manually trigger the on_destroy event for a Slick-C form that 
 * is implemented as a dockable view in Eclipse. 
 * 
 * @param form Slick-C form which is being closed 
 */
_command void eclipse_destroy_view(_str form="") name_info(',')
{
   if (form != "") {
      int wid = _find_formobj(form,'N');
      // Only call ON_DESTROY if the wid's ON_CREATE has been called
      if ( wid && (wid.p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
         orig_wid := p_window_id;
         p_window_id = wid;
         call_event(wid,ON_DESTROY);
         p_window_id = orig_wid;
      }
   }
}

/**
 * Get the current symbol coloring scheme. 
 * 
 * @return _str scheme 
 */
_str eclipse_get_current_sc_scheme() 
{
   return def_symbol_color_profile;
}

/**
 * Get all symbol coloring schemes compatible with the current 
 * color scheme.  Wholesaled from SymbolColorAnalyzer.e. 
 * 
 * @return _str comma-delimited string of schemes 
 */
_str eclipse_get_compatible_sc_schemes()
{
    ret := "";
    int i;
    _str schemeNames[];
    se.color.SymbolColorRuleBase scc;
    scc.listProfiles(schemeNames, def_color_scheme);

    for (i = 0; i < schemeNames._length(); i++) {
       _str name = schemeNames[i];
       ret :+= name :+ ",";
    }
    return(ret);
}

/** 
 * Performs DIFFzilla on Eclipse backup history elements.
 * 
 * @param args A semicolon separated String containing the 
 *             arguments for DIFFzilla
 */
_command void eclipse_history_diff(_str args="") name_info(',')
{
   old_wid := p_window_id;
   int temp_view_id1,orig_view_id1,orig_view_id2,temp_view_id2,status;
   temp_view_id1 = orig_view_id1 = orig_view_id2 = temp_view_id2 = 0;

   if (args=="") return;
   _str suffix, diff_opts, file1, file2, use_rev1, use_rev2, set_ext;
   // diff_opts are the options for diff
   parse args with diff_opts ";" suffix;
   // file1 is the full file path for the first file
   parse suffix with file1 ";" suffix;
   // file2 is the full file path for the second file
   parse suffix with file2 ";" suffix;
   // use_rev1 tells us whether we are using a local revision for the first file
   parse suffix with use_rev1 ";" suffix;
   // use_rev2 tells us whether we are using a local revision for the second file
   parse suffix with use_rev2 ";" suffix;
   // set_ext is the full path to the file we should use for select_edit_mode
   parse suffix with set_ext ";";

   _str diff_cmdline = diff_opts;

   // if we are using local history revision elements, open temp views on these files
   // and set the appropriate edit mode.  otherwise we don't have to bother with this. 
   if (use_rev1 == "1") {
      status=_open_temp_view(file1,temp_view_id1,orig_view_id1);
      if ( status ) {
         _message_box(nls("Could not open local file '%s'",file1));
         return;
      }
      _str ext = _Filename2LangId(set_ext);
      _SetEditorLanguage(ext);
      diff_cmdline = "-viewid1 " :+ diff_cmdline :+ " " :+ temp_view_id1;
   } else {
      diff_cmdline :+= " " :+ file1;
   }

   if (use_rev2 == "1") {
      status=_open_temp_view(file2,temp_view_id2,orig_view_id2);
      if ( status ) {
         _message_box(nls("Could not open local file '%s'",file2));
         return;
      }
      _str ext = _Filename2LangId(set_ext);
      _SetEditorLanguage(ext);
      diff_cmdline = "-viewid2 " :+ diff_cmdline :+ " " :+ temp_view_id2;
   } else {
      diff_cmdline :+= " " :+ file2;
   }

   status=_DiffModal(diff_cmdline);
   // delete the view ids if necessary
   if (temp_view_id1 != 0) {
      _delete_temp_view(temp_view_id1);
   }
   if (temp_view_id2 != 0) {
      _delete_temp_view(temp_view_id2);
   }
   p_window_id = old_wid;
}

_command eclipse_navigate_buffers()
{
   _eclipse_dispatchCommand(ECLIPSE_NEXT_WINDOW);
}
_command eclipse_setmode(int mode=0)
{
 //  say("eclipse-setmode "mode);
   if (mode == 0) {
      set_env("VSECLIPSEPLUGIN");
   } else {
      set_env("VSECLIPSEPLUGIN", "1");
   }
}
int eclipse_get_xml_formatting_supported()
{
   return(XW_isSupportedLanguage() ? 1 : 0);
}
int eclipse_get_cw_enabled()
{
   currentState := _GetCommentWrapFlags(CW_ENABLE_COMMENT_WRAP);
   return(currentState ? 1 : 0);
}
int eclipse_get_af_on()
{
   return(adaptive_format_is_adaptive_on() ? 1 : 0);
}
int eclipse_get_af_support()
{
   return(adaptive_format_get_available_for_language(p_LangId) ? 1 : 0);
}
int eclipse_get_cw_support()
{
   return(commentwrap_isSupportedLanguage() ? 1 : 0);
}
int eclipse_istagging_supported(_str ext = null)
{
   return(_istagging_supported(_Ext2LangId(ext)) ? 1 : 0);
}
_command void eclipse_build_all() name_info(','VSARG2_EDITORCTL)
{
   if (isEclipsePlugin()) {
      _eclipse_workspace_build();
   } else {
      project_build();
   }
}
_command eclipse_set_cd(_str path = "")
{
   cd(path);
}
_command eclipse_organize_imports()
{
   _eclipse_dispatchCommand(ECLIPSE_ORGANIZE_IMPORTS);
}
_command vse_post_save()
{
//   call_list('_cbsave_');
  // p_window_id.p_modify = 0;
}
/**
 * Create the symbol browser in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createClassBrowser(typeless classBrowserForm='')
{
   // Access the parent form.
   // Create the symbol browser.
   _str classBrowserTemplateForm = ECLIPSE_CLASSBROWSER_FORM_NAME_STRING;
   int index = find_index(classBrowserTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int classBrowserContainer = _load_template(index, classBrowserForm, 'HPN');
   classBrowserContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   classBrowserForm.p_eventtab = find_index(ECLIPSE_CLASSBROWSER_FORM_NAME_STRING, EVENTTAB_TYPE);

   // Tell VSE to use the symbol browser in this parent form.
   cbrowser_setFormName(classBrowserForm.p_name);
   
   return classBrowserContainer;
}

_command int eclipse_destroyReferences() {
   int wid = _GetReferencesWID(false);
//   say('wid='wid);
   return(wid);
//   int old_wid = p_window_id;
//   p_window_id = refContainer;
//   refs_wid := _find_formobj('_tbtagrefs_form');
//   say('refs_wid='refs_wid);
//   call_event(refs_wid, ON_DESTROY, 'W');
//   p_window_id = old_wid;
}

/**
 * Create the symbol browser in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createClass(typeless classForm='')
{
   // Access the parent form.
   // Create the symbol browser.
   _str classTemplateForm = ECLIPSE_CLASS_FORM_NAME_STRING;
   int index = find_index(classTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int classContainer = _load_template(index, classForm, 'HPN');
   classContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   classForm.p_eventtab = find_index(ECLIPSE_CLASS_FORM_NAME_STRING, EVENTTAB_TYPE);

   // Tell VSE to use the symbol browser in this parent form.
   //cbrowser_setFormName(classForm.p_name);
   
   return classContainer;
}
/**
 * Resize the symbol browser in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
/*_command int eclipse_resizeClassBrowser(typeless *
 *  classBrowserForm='') { // Access the controls.
   int classBrowserContainer = classBrowserForm.p_child;

   // Resize reference output container.
   int formW = classBrowserForm.p_width;
   int formH = classBrowserForm.p_height;
   if (!formW || !formH) return(0);
   classBrowserContainer.p_width = formW;
   classBrowserContainer.p_height = formH;

   // Resize the controls.
   cbrowser_on_resize(formW, formH);

   return(0);
}*/ 

/**
 * Returns true if we are processing an internal call from Eclipse
 * We need to distinguish this from user commands so we do not get into
 * an infinite loop calling back into Eclipse
 * 
 **/
bool isInternalCallFromEclipse()
{
   return CalledFromEclipseFlag;
}
bool isDiffedEclipse(int wid = 0)
{
   if(wid == 0) {
      return false;
   }
   return _isdiffed(wid.p_buf_id);
}
bool setInternalCallFromEclipse(bool new_val = true)
{
//say("setInternalCallFromEclipse = "new_val);
   old_val := CalledFromEclipseFlag;
   CalledFromEclipseFlag = new_val;
   return old_val;
}

_command void eclipse_set_active_java(_str jdk_path = "") name_info(',')
{
   
   _maybe_append_filesep(jdk_path);
   def_active_java_config = get_jdk_from_root(jdk_path);
   _config_modify_flags(CFGMODIFY_DEFVAR);
  
}
/**
 * This is called after vsInit() and all the vsLibExport() are called
 * in vseInitialize().
 * 
 * @return 0 OK, !0 error
 */
_command int initialize_eclipse()
{
   // RGH - 5/25/2006
   // Changing the emulation in eclipse so that we base it on def_keys
   // Otherwise, when copying over an old config, the emulation that was previously
   // set will be overridden by what is in the eclipse preference store
   if (def_keys :!= '') {
      int status = _eclipse_changeActiveKeyConfiguration(def_keys);
   }
   gEclipseInitialized = true;
   _eclipse_set_tagging_excludes(def_tagging_excludes);
   // Set the gutter width to fit the Eclipse markers icons.
/*#if __UNIX__
   int newGutterWidth = (int)(0.12 * 1440);
#else
   int newGutterWidth = (int)(0.15 * 1440);
#endif
   int oldGutterWidth = _default_option('L');
   if (oldGutterWidth < newGutterWidth) {
      _default_option('L', newGutterWidth);
   }

 // def_deselect_copy = 0; 
   extensionList := "";
   int index = name_match('def-language-',1,MISC_TYPE);
   for (;index;) {
     name = substr(name_name(index),11);
     if (extensionList != "") extensionList :+= ",";
     extensionList :+= ""name;
     index = name_match('def-language-',0,MISC_TYPE);
   }
   _eclipse_setSupportedExtensions(extensionList);
   */
   return(0);
   
}
/**
 * Get comma-delimited list of all extensions for which 
 * SlickEdit has tagging support. 
 * 
 * @return _str
 */
_str eclipse_get_supported_extensions()
{
   retval := "";
   _str extList[];
   _GetAllExtensions(extList);
   for (i := 0; i < extList._length(); i++) {
      name := extList[i];
      supported := _istagging_supported(_Ext2LangId(name));
      if (supported) {
         retval :+= name :+ ',';
      }
   }
   return retval;
}
/**
 * Resize the FTP Open in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */

/*_command int eclipse_resizeFTPOpen(typeless ftpOpenForm='')
{ 
   
   // Access the controls.
   int ftpOpenContainer = ftpOpenForm.p_child;

   // Resize search output container.
   int formW = ftpOpenForm.p_width;
   int formH = ftpOpenForm.p_height;
   if (!formW || !formH) return(0);
   ftpOpenContainer.p_width = formW;
   ftpOpenContainer.p_height = formH;

   // Resize controls.
   //MK
   ftpOpenContainer.resizeFTPTabControls(formW, formH);
   
   return(0);
}*/
int eclipseGetBitmapIndex(_str bitmapName="")
{
   if (bitmapName == "") return(0);
   int bi = _update_picture(-1, bitmapName);
   return(bi);
}
_command int eclipse_debug()
{                                                     
   return _eclipse_dispatchCommand(ECLIPSE_DEBUG_CMD);
}
_command int eclipse_stop_debug()
{
   return _eclipse_dispatchCommand(ECLIPSE_STOP_DEBUG_CMD);
}
_command int eclipse_setbreakpoint() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_createbreakpoint(p_window_id, p_line);
}
_command int eclipse_browse_files()
{
   return _eclipse_dispatchCommand(ECLIPSE_BROWSE);
}
_command int eclipse_run_to_line()
{
   return _eclipse_dispatchCommand(ECLIPSE_RUN_TO_LINE_CMD);
}
_command int eclipse_step_over()
{
   return _eclipse_dispatchCommand(ECLIPSE_STEP_OVER_CMD);
}
_command int eclipse_step_into()
{
   return _eclipse_dispatchCommand(ECLIPSE_STEP_INTO_CMD);
}
_command int eclipse_step_return()
{
   return _eclipse_dispatchCommand(ECLIPSE_STEP_RETURN_CMD);
}
_command int eclipse_resume_execution()
{
   return _eclipse_dispatchCommand(ECLIPSE_RESUME_EXECUTION_CMD);
}
_command int eclipse_restart_debug()
{
   return _eclipse_dispatchCommand(ECLIPSE_RESTART_DEBUG_CMD);
}
_command int eclipse_clear_breakpoints()
{
   return _eclipse_dispatchCommand(ECLIPSE_CLEAR_ALL_BREAKPOINTS_CMD);
}
_command int eclipse_show_watches()
{
   return _eclipse_dispatchCommand(ECLIPSE_ACTIVATE_WATCH_VIEW_CMD);
}
_command int eclipse_show_callstack()
{
   return _eclipse_dispatchCommand(ECLIPSE_ACTIVATE_CALL_STACK_CMD);
}
_command int eclipse_show_variables()
{
    return _eclipse_dispatchCommand(ECLIPSE_ACTIVATE_VAR_VIEW_CMD);
}
_command int eclipse_show_breakpoints()
{
   return _eclipse_dispatchCommand(ECLIPSE_ACTIVATE_BREAKPOINT_VIEW_CMD);
}
_command int eclipse_run()
{
   if (isEclipsePlugin()) {
      return _eclipse_dispatchCommand(ECLIPSE_RUN_CMD);
   } else {
      return project_execute();
   }
}
_command int eclipse_enablebreakpoint() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_enablebreakpoint(p_window_id, p_line);
}

_command int eclipse_disablebreakpoint() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_disablebreakpoint(p_window_id, p_line);
}

_command int eclipse_togglebreakpoint() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_togglebreakpoint(p_window_id, p_line);
}
_command int eclipse_togglebreakpointenabled() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_toggle_breakpoint_enable(p_window_id, p_line);
}
_command int eclipse_removebreakpoint() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_removebreakpoint(p_window_id, p_line);
}

_command int eclipse_breakpointProperties() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return _eclipse_breakpointProperties(p_window_id, p_line);
}
_command eclipse_override_methods()
{
   _eclipse_dispatchCommand(ECLIPSE_OVERRIDE_METHODS);
}
_command int eclipse_addbookmark(typeless arg1='') name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(_eclipse_addbookmark(p_window_id, arg1));
}

_command int eclipse_removebookmark() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(_eclipse_removebookmark(p_window_id, p_line));
}

_command int eclipse_gotobookmark(typeless arg1='') name_info(','VSARG2_EDITORCTL)
{
   return (_eclipse_gotobookmark(p_window_id, arg1)); 
}

_command int eclipse_bookmark_exists() name_info(','VSARG2_EDITORCTL)
{
   return (_eclipse_bookmark_exists(p_window_id, p_line)); 
}

_command int eclipse_addtask() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(_eclipse_addtaskmark(p_window_id));
}

_command int eclipse_removetask() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   return(_eclipse_removetask(p_window_id, p_line));
}
_command int eclipse_createOutput(typeless outputForm='')
{
   //this is the container form
   //create the contents
   _str outputFormTemplate = ECLIPSE_OUTPUT_FORM_NAME_STRING;
   int index = find_index(outputFormTemplate, oi2type(OI_FORM));
   if(!index){
      return 0;
   }
   int child = index.p_child;
   int outputContainer = _load_template(index, outputForm, 'HPN');
   outputContainer.p_visible = true;
   editor_ctl := outputContainer._find_control("ctloutput");
  // editor_ctl.p_MouseActivate = MA_ACTIVATE;
  // outputForm.p_eventtab = find_index(ECLIPSE_OUTPUT_FORM_NAME_STRING, EVENTTAB_TYPE);
   editor_ctl.p_eventtab = find_index('_tboutputwin_form.ctloutput', EVENTTAB_TYPE);
   return editor_ctl;
}
_command int eclipse_list_buffers()
{
   return _eclipse_list_buffers();
}
/**
 * Create the proc tree in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createProcTree(typeless proctreeform='')
{
   // Access the parent form.

   // Create the proc tree.
   _str procTreeTemplateForm = ECLIPSE_PROCTREE_FORM_NAME_STRING;
   int index = find_index(procTreeTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int procTreeContainer = _load_template(index, proctreeform, 'HPN');
   procTreeContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   proctreeform.p_eventtab = find_index(ECLIPSE_PROCTREE_FORM_NAME_STRING, EVENTTAB_TYPE);

   // Tell VSE to use the proc tree in this parent form.
   //proctree_setFormName(proctreeform.p_name);
   return(0);
}

void _on_popup2_eclipse(_str menu_name, int menu_handle) {
   if(isEclipsePlugin()) {
      omh := 0;
      omp := 0;
      // Get rid of Create New Annotation... menu item
      int status= _menu_find(menu_handle, "new_annotation", omh, omp);
      if (status == 0) {
         _menu_delete(menu_handle, omp);
      }
      status= _menu_find(menu_handle, "show_file_in_projects_tb", omh, omp);
      if (status == 0) {
         _menu_delete(menu_handle, omp);
      }
      status= _menu_find(menu_handle, "project_edit_project_with_file", omh, omp);
      if (status == 0) {
         _menu_delete(menu_handle, omp);
      }
      status= _menu_find(menu_handle, "cf", omh, omp);
      if (status == 0) {
          _menu_insert(menu_handle,++omp,MF_ENABLED,"Show In Navigator",
                       "eclipse_show_in_navigator");
      }
      if("_tagbookmark_menu" == menu_name) {
         _handle_popup2(menu_handle, false);
         return;
      }
      _handle_popup2(menu_handle, _isEditorCtl(false));
   }
}

/**
 * Show the current file in the Eclipse Navigator view. 
 * 
 */
_command void eclipse_show_in_navigator() name_info(',')
{
    _eclipse_show_in_navigator();
}
/**
 * Create the symbol output in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createSymbolOutput(typeless symbolOutputForm='')
{
   // Access the parent form.

   // Create the symbol output editor.
   _str symbolOutputTemplateForm = ECLIPSE_SYMBOLOUTPUT_FORM_NAME_STRING;
   int index = find_index(symbolOutputTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int symbolOutputContainer = _load_template(index, symbolOutputForm, 'HPN');
   symbolOutputContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   symbolOutputForm.p_eventtab = find_index(ECLIPSE_SYMBOLOUTPUT_FORM_NAME_STRING, EVENTTAB_TYPE);
   return symbolOutputContainer;
}
/**
 * Create the references output in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createReferencesOutput(...)
{
   // Access the parent form.
   int referencesOutputForm = arg(1);

   // Create the references output editor.
   _str referencesOutputTemplateForm = ECLIPSE_REFERENCESOUTPUT_FORM_NAME_STRING;
   int index = find_index(referencesOutputTemplateForm, oi2type(OI_FORM));
 //  say(referencesOutputTemplateForm);
  // say(index);
   if (!index) return(0);
   int child = index.p_child;
   int referencesOutputContainer = _load_template(index, referencesOutputForm, 'HPN');
   referencesOutputContainer.p_visible = true;
  // say('form name='referencesOutputContainer.p_active_form.p_name);

   // Add an event table and hook A-F4 to prevent the form from being closed.
   referencesOutputForm.p_eventtab = find_index(ECLIPSE_REFERENCESOUTPUT_FORM_NAME_STRING, EVENTTAB_TYPE);
   return referencesOutputContainer;
}
_command int eclipse_createSearchOutput(...)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   _nocheck _control list1;
   // Access the parent form.
   int searchOutputForm = arg(1);

   // Create the search output editor.
   _str searchOutputTemplateForm = ECLIPSE_SEARCHOUTPUT_FORM_NAME_STRING;
   int index = find_index(searchOutputTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int searchOutputContainer = _load_template(index, searchOutputForm, 'HPN');
   searchOutputContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   searchOutputForm.p_eventtab = find_index(ECLIPSE_SEARCHOUTPUT_FORM_NAME_STRING, EVENTTAB_TYPE);
   list1_wid := searchOutputContainer._find_control("_search_tab");
   activate_window(orig_view_id);
   return(list1_wid);
}
/**
 * Create the FTP Open in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createFTPOpen(...)
{
   // Access the parent form.
   int ftpOpenForm = arg(1);

   // Create the search output editor.
   _str ftpOpenTemplateForm = ECLIPSE_FTPOPEN_FORM_NAME_STRING;
   int index = find_index(ftpOpenTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int ftpOpenContainer = _load_template(index, ftpOpenForm, 'HPN');
   ftpOpenContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   ftpOpenForm.p_eventtab = find_index(ECLIPSE_FTPOPEN_FORM_NAME_STRING, EVENTTAB_TYPE);
   return(ftpOpenContainer);
}
/**
 * Create the FTP Client in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_createFTPClient(...)
{
   // Access the parent form.
   int ftpClientForm = arg(1);

   // Create the search output editor.
   _str ftpClientTemplateForm = ECLIPSE_FTPCLIENT_FORM_NAME_STRING;
   int index = find_index(ftpClientTemplateForm, oi2type(OI_FORM));
   if (!index) return(0);
   int child = index.p_child;
   int ftpClientContainer = _load_template(index, ftpClientForm, 'HPN');
   ftpClientContainer.p_visible = true;

   // Add an event table and hook A-F4 to prevent the form from being closed.
   ftpClientForm.p_eventtab = find_index(ECLIPSE_FTPCLIENT_FORM_NAME_STRING, EVENTTAB_TYPE);
   return(ftpClientContainer);
}

_command int eclipse_resizeOutput(...)
{
   int outputForm = arg(1);
   int outputContainer = outputForm.p_child;
   ctlOutput := outputContainer._find_control("ctloutput");

   // Resize search output container.
   int formW = outputForm.p_width;
   int formH = outputForm.p_height;
   if (!formW || !formH) return(0);
   outputContainer.p_width = formW;
   outputContainer.p_height = formH;

   // Resize search output editor.
   ctlOutput.p_width = formW;
   ctlOutput.p_height = formH;
   return(0);

}

/** 
 * Resize the SWT container for a SlickC form
 * 
 * @param containerWid window_id for the container
 * 
 * @return 1 for success, 0 for failure
 * */
int eclipse_resizeContainer(int containerWid){
   int w = containerWid.p_parent.p_width;
   int h = containerWid.p_parent.p_height;
   if (!w || !h) return(0);
   containerWid.p_width = w;
   containerWid.p_height = h;
   return(1);
}

/**
 * Resize the proc tree in the specified parent form.
 * 
 * @return 0 OK, !0 error
 */
_command int eclipse_resizeProcTree(...)
{
   // Access the controls.
   int proctreeform = arg(1);
   int proctreeContainer = proctreeform.p_child;
   ctlcurpath := proctreeContainer._find_control("ctlcurpath");
   ctlproctree := proctreeContainer._find_control("_proc_tree");

   // Resize proc tree container.
   int formW = proctreeform.p_width;
   int formH = proctreeform.p_height;
   proctreeContainer.p_width = formW;
   proctreeContainer.p_height = formH;

   // Resize label.
   ctlcurpath.p_width = formW - 2 * ctlcurpath.p_x;

   // Resize tree view.
   ctlproctree.p_width = formW - 2 * ctlproctree.p_x;
   ctlproctree.p_y_extent = formH ;

   // Refresh the label and proc tree.
   ctlcurpath.refresh('R');
   ctlproctree.refresh('R');
   return(0);
}
/**
 * Determine if the the current mdi child is modified on disk
 * 
 * @return 1 if modified on disk.  2 if file not there anymore. 0 if not modified
 * 
 **/ 
int eclipse_modified_on_disk()
{
      p_window_id = _mdi.p_child;
   if (_iswindow_valid(p_window_id) && p_mdi_child) {
      if (file_exists(p_buf_name)) {
         _str bfiledate=_file_date(p_buf_name,'B');
         if (bfiledate!='' && bfiledate!=0 && p_file_date:!=bfiledate && !_FileIsRemote(p_buf_name) && p_file_date!='' && p_file_date!=0) {
            return 1;
         } 
      } else {
         // File is missing
         return 2;
      }
   }
   return 0;
}
/**
 * Reload the current buffer from disk
 * 
 **/
_command int eclipse_reload_buf()
{
   p_window_id = _mdi.p_child;
   _str bfiledate=_file_date(p_buf_name,'B');
   if (bfiledate!='' && bfiledate!=0 && p_file_date:!=bfiledate && !_FileIsRemote(p_buf_name)) {

   //   _open_temp_view("",actapp_view_id,orig_view_id,"+bi "RETRIEVE_BUF_ID);
      options := "";
      if (p_buf_width==1) {
         options='+LW';
      } else if (p_buf_width) {
         options='+'p_buf_width;
      }
      encoding_set_by_user := -1;
      _str encoding_str=_load_option_encoding(p_buf_name);
      //say('lo encoding_str='encoding_str);
      // IF the user has overriden default encoding recognition  AND
      //
      if (p_encoding_set_by_user!= -1) {
         int encoding;
         if (p_encoding_set_by_user==VSENCODING_AUTOUNICODE || p_encoding_set_by_user==VSENCODING_AUTOXML ||
             p_encoding_set_by_user==VSENCODING_AUTOUNICODE2 ||
             p_encoding_set_by_user==VSENCODING_AUTOEBCDIC || p_encoding_set_by_user==VSENCODING_AUTOEBCDIC_AND_UNICODE ||
             p_encoding_set_by_user==VSENCODING_AUTOEBCDIC_AND_UNICODE2
                ) {
            // The user chose some specific automatic processing.
            // Just reuse it.
            encoding_set_by_user=encoding=p_encoding_set_by_user;
         } else if (_last_char(_EncodingToOption(p_encoding))=='s') {
            // The current file has a signature. Automatic processing will
            // redetect this file and we can enhance this by automatically detecting
            // signatures.
            // Smarten what the user has requisted
            // WARNING: This won't work if the user removes the signature in
            // another application and then switches back.
            encoding_set_by_user=encoding=VSENCODING_AUTOUNICODE;
         } else {
            // No signature, must assume the user knows best.
            encoding_set_by_user=encoding=p_encoding_set_by_user;
         }
         encoding_str=_EncodingToOption(encoding);
      }
      //say('ar: e_set_by_user='encoding_set_by_user);
      //say('ar: encoding_str='encoding_str);
      options :+= ' 'encoding_str;
      _str doc_name=p_DocumentName;
      if (doc_name=="") {
         doc_name=p_buf_name;
      }
      _str buf_name=p_buf_name;
      int buf_id=p_buf_id;
      modify := p_modify;
      typeless p;
      save_pos(p,'L');
      int oldp_line_numbers_len=p_line_numbers_len;
     // activate_window(orig_view_id);_set_focus();
   
      //disabled_wid_list=_enable_non_modal_forms(0,_mdi);
      int result=IDYES;
      // IF no reload prompt
      if (def_actapp&ACTAPP_SUPPRESSPROMPTUNLESSMODIFIED) {
      } else {
         if (_isWindows()) {
            if ((_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)) {
               if (_mdi.p_window_state=='I') {
                  _mdi.p_window_state='R';
               }
            }
         }
      }
      //_enable_non_modal_forms(1,0,disabled_wid_list);
   //   activate_window(orig_view_id);
   
      if (result==IDYES) {
         /* Make a view&buffer windows list which contains window and position info. */
         /* for all windows. */
         temp_view_id := _list_bwindow_pos(buf_id);
        // activate_window(actapp_view_id);
         // Use def_load_options for network,spill, and undo options. */
         int status=load_files(build_load_options(buf_name):+' +q +d +r +l ':+options' ':+_maybe_quote_filename(buf_name));
         if (status) {
            if (status==NEW_FILE_RC) {
               status=FILE_NOT_FOUND_RC;
               _delete_buffer();
            }
       //     activate_window(orig_view_id);_set_focus();
            _message_box(nls("Unable to reload %s",doc_name)"\n\n"get_message(status));
            p_file_date=(long)bfiledate;
         } else {
            // Just in case this file has really long lines,
            // temporarily turn off softwrap to improve performance a ton.
            orig_SoftWrap:=p_SoftWrap;
            p_SoftWrap=false;
            p_line_numbers_len=oldp_line_numbers_len;
            p_encoding_set_by_user=encoding_set_by_user;
            restore_pos(p);
            // Need to do an add buffer here so the debugging
            // information is updated.
            // load_files with +r options calls the delete buffer
            // callback.  Here we readd this buffer.
            call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
            call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
            _set_bwindow_pos(temp_view_id);
            p_SoftWrap=orig_SoftWrap;
         }
         if (temp_view_id) {
            _delete_temp_view(temp_view_id);
         }
      } else {
   //      activate_window(actapp_view_id);
         p_file_date=(long)bfiledate;
         if (result == 8) {
            _DiffModal('-r2 -b1 -d2 '_maybe_quote_filename(doc_name)' '_maybe_quote_filename(doc_name));
         }
      }
   }
 //  activate_window(actapp_view_id);
 //  _delete_temp_view(actapp_view_id);
   return 0;

}

 /**
  * Synchronize buffer date with file date.  This is called from Eclipse
  * to prevent reload message from displaying repeatingly
  * 
  **/ 
_command eclipse_sync_buf_date()
{
   typeless bfiledate=_file_date(p_buf_name,'B');
   if (bfiledate!='' && bfiledate!=0 && p_file_date!=bfiledate && !_FileIsRemote(p_buf_name)) {
      p_file_date=(long)bfiledate;
   }
   call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
   call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
}

/*_command eclipse_test_show_version()
{
   _str eclipseVersion;

   _eclipse_get_eclipse_version_string(eclipseVersion);
   _eclipse_get_jdt_version_string(jdtVersion);
   _eclipse_get_cdt_version_string(cdtVersion);
   
 //  say("Eclipse version = "eclipseVersion);
 //  say("JDT version = "jdtVersion);
//say("CDT version = "cdtVersion);
}
  */
/**
 * Do work when VSE is idle.
 */
void eclipseDoIdleWork(bool AlwaysUpdate=false)
{
   if (isEclipsePlugin()) {
      if (!AlwaysUpdate && _idle_time_elapsed() < ECLIPSE_MIN_IDLE_TIME) return;
      if (gEclipseInitialized) {
         _eclipse_doIdleWork();
      }
   }
}

void eclipse_reposition_text(...)
{
   int wid = arg(1);
   if(wid > 0) {
      col := wid.p_col;
      wid.goto_col(1);
      wid.center_line();
      wid.goto_col(col);
   }
}

/**
 * Unused as of 5/2/07 because we have removed the native 
 * Eclipse emulation form...in favor of the SlickEdit form. 
 */
/*_command void eclipse_change_emulation(_str emulation="cua")
{
   // RGH - 5/25/2006
   // Changed all the checks to match the values of def_keys
   set_emulation := "";
   new_keys := "";
   if (emulation == "cua" || emulation == "windows-keys") {
      set_emulation='windows';
      new_keys="windows-keys";
   } else if (emulation == "slick") {
      set_emulation='slick';
      new_keys="";
   } else if (emulation == "brief-keys") {
      set_emulation='brief';
      new_keys="brief-keys";
   } else if (emulation == "epsilon-keys" || emulation == "emacs-keys") {
      set_emulation='emacs';
      new_keys="emacs-keys";
   } else if (emulation == "vi-keys") {
      set_emulation='vi';
      new_keys="vi-keys";
   } else if (emulation == "gnuemacs-keys") {
      set_emulation='gnu';
      new_keys="gnuemacs-keys";
   } else if (emulation == "vcpp-keys") {
      set_emulation='vcpp';
      new_keys="vcpp-keys";
   } else if (emulation == "ispf-keys") {
      set_emulation='ispf';
      new_keys="ispf-keys";
   } else if (emulation == "codewarrior-keys") {
      set_emulation='codewarrior';
      new_keys="codewarrior-keys";
   } else if (emulation == "codewright-keys") {
      set_emulation='codewright';
      new_keys="codewright-keys";
   } else if (emulation == "xcode-keys") {
      set_emulation='xcode';
      new_keys="xcode-keys";
   } else if (emulation == "bbedit-keys") {
      set_emulation='bbedit';
      new_keys="bbedit-keys";
   } else if (emulation == "vsnet-keys") {
      set_emulation='vsnet';
      new_keys="vsnet-keys";
   }
   if (def_keys==new_keys) return;
   macro := "emulate";
   filename := get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext'x');
   if (filename=='') {
      filename=get_env('VSROOT')'macros':+FILESEP:+(macro:+_macro_ext);
   }
   if (filename=='') {
      _message_box("File '%s' not found",macro:+_macro_ext'x');
      return;
   }
   orig_wid := p_window_id;
   p_window_id=_mdi.p_child;
   _no_mdi_bind_all=1;
   macro=_maybe_quote_filename(macro);
   int status=shell(macro' 'set_emulation);
   _no_mdi_bind_all=0;
   p_window_id=orig_wid;
   if (status) {
      _message_box(nls("Unable to set emulation.\n\nError probably caused by missing macro compiler or incorrect macro compiler version."));
      return;
   }
}*/

/**
 * Unused as of 5/2/07 because we have removed the native 
 * Eclipse emulation form...in favor of the SlickEdit form. 
 */
/**
 * Tell Eclipse to change its key configuration. This should in turn
 * change SlickEdit's emulation.
 * 
 * @param emulation emulation: windows/cua, slick, brief, emacs/epsilon, vi, gnuemacs, vcpp, ispf, codewarrior
 */
/*void eclipseChangeKeyConfiguration(_str emulation)
{
   _eclipse_changeActiveKeyConfiguration(emulation);
}*/

/**
 * Unused as of 5/2/07 because we have removed the native 
 * Eclipse emulation form...in favor of the SlickEdit form. 
 */
/**
 * List all key bindings in the current emulation.
 */
/*_command void eclipse_list_keys()
{
   // Get the current emulation.
   _str emulation;
   switch (lowcase(def_keys)) {
   case '':
      emulation = "slick";
      break;
   case 'windows-keys':
      emulation = "cua";
      break;
   case 'brief-keys':
      emulation = "brief";
      break;
   case 'emacs-keys':
      emulation = "epsilon";
      break;
   case 'vi-keys':
      emulation = "vi";
      break;
   case 'gnuemacs-keys':
      emulation = "gnuemacs";
      break;
   case 'vcpp-keys':
      emulation = "vcpp";
      break;
   case 'ispf-keys':
      emulation = "ispf";
      break;
   case 'codewarrior-keys':
      emulation = "codewarrior";
      break;
   }

   // Get the list of key bindings.
   //say("eclipse_list_keys");
   _str keyList[];
   int index = name_match('default-keys',1,EVENTTAB_TYPE);
   build_keydefs(keyList, index, '');

   // Translate the key sequence from Slick-C convention to Eclipse.
   translateKeySequences(keyList);

   // Pass the key list back to Eclipse.
   int i;
   keyListText := "";
   for (i=0; i<keyList._length(); i++) {
      if (!length(keyList[i])) continue;
      if (length(keyListText)) {
         keyListText :+= "\n";
      }
      keyListText :+= ""keyList[i];
   }
   _eclipse_list_keys(emulation, keyListText);
}*/

/**
 * Unused as of 5/2/07 because we have removed the native 
 * Eclipse emulation form...in favor of the SlickEdit form. 
 */
/**
 * Build a list of key definitions for the specified key binding table.
 */
/*static void build_keydefs(_str (&keyList)[], int * 
_root_keys,_str prefix_keys) { * 
   VSEVENT_BINDING list[];
   int NofBindings;
   list_bindings(_root_keys,list);
   NofBindings=list._length();
   // Find first non-null key binding.
   int index;
   i := 0;
   if (prefix_keys=='') {
      for (; i<NofBindings; ++i) {
         index=list[i].binding; 
         if (index) {
            if (index & 0xffff0000) return;
            break;
         }
      }
   }

   // Build the list of key bindings to Slick-C commands and functions.
   _str keyname;
   keyCount := keyList._length();
   for (; i<NofBindings; ++i) {
      index=list[i].binding; 
      if (index && (name_type(index)& (COMMAND_TYPE|PROC_TYPE))) {
         keyname = event2name(index2event(i));
         keyList[keyCount] = prefix_keys:+keyname;
         keyCount++;
      }
   }

   // Go thru the multi-key sequence bindings.
   for (i=0; i<NofBindings; ++i) {
      index=list[i].binding; 
      if (index && (name_type(index) & EVENTTAB_TYPE)) {
         keyname = event2name(index2event(i));
         build_keydefs(keyList, index, prefix_keys:+keyname' ');
      }
   }
}*/
_command eclipse_update_editor_status()
{
/*   if(p_window_id.p_SoftWrap)
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_SOFTWRAP_ON);
   }
   else
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_SOFTWRAP_OFF);
   }
   if(p_window_id.p_word_wrap_style & WORD_WRAP_WWS)
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_WORDWRAP_ON);
   }
   else
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_WORDWRAP_OFF);
   }
   if(p_window_id.p_indent_with_tabs)
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_INDENT_TABS_ON);
   }
   else
   {
      _eclipse_dispatchCommand(ECLIPSE_EV_INDENT_TABS_OFF);
   }*/

}

/** Use this when we are telling users that a command is
 *  disabled in the plugin. */
void eclipse_show_disabled_msg(_str command = ''){
   if (command :== '') {
      message("Command is disabled for SlickEdit Core.");
   } else {
      message(command" is disabled for SlickEdit Core.");
   }
}
/**
 * Translate the specified Slick-C&reg; key sequences to Eclipse format.
 * <pre>
 *    C-      ==> Ctrl+
 *    A-      ==> Alt+
 *    S-      ==> Shift+
 *    C-S-    ==> Ctrl+Shift+
 *    C-A-    ==> Ctrl+Alt+
 * </pre>
 * 
 * @param keyList key sequences
 */
/*
static void translateKeySequences(_str (&keyList)[])
{
   _str keySequence, newSequence, oneChar;
   int i, j;
   bool changed, expectingCharOrModifier, dontTake;
   //say("translateKeySequences");
   for (i=0; i<keyList._length(); i++) {
      keySequence = keyList[i];

      // Special cases.
      //    LBUTTON-DOWN
      //    MOUSE-MOVE
      if (pos("BUTTON|MOUSE|PAD-", keySequence, 1, "IR")) {
         //say("   SKIPPING '"keyList[i]"'");
         keyList[i] = "";
         continue;
      }

      // Translate the key sequence.
      newSequence = "";
      changed = false;
      expectingCharOrModifier = false;
      while (length(keySequence)) {
         if (pos('C-', keySequence, 1, "I") == 1) {
            newSequence :+= "Ctrl+";
            keySequence = substr(keySequence, 3);
            expectingCharOrModifier = true;
         } else if (pos('A-', keySequence, 1, "I") == 1) {
            newSequence :+= "Alt+";
            keySequence = substr(keySequence, 3);
            expectingCharOrModifier = true;
         } else if (pos('S-', keySequence, 1, "I") == 1) {
            newSequence :+= "Shift+";
            keySequence = substr(keySequence, 3);
            expectingCharOrModifier = true;
         } else {
            // Skip over non-modifier key binding.
            if (!changed) break;

            // Special characters need to be expanded into words.
            oneChar = substr(keySequence, 1, 1);
            if (expectingCharOrModifier) {
               if (oneChar == ' ') {
                  newSequence :+= "Space";
               } else {
                  newSequence :+= ""oneChar;
               }
               expectingCharOrModifier = false;
            } else {
               // Retain the character as is.
               newSequence :+= ""oneChar;
            }
            keySequence = substr(keySequence, 2);
         }
         changed = true;
      }

      // If sequence was not translated, skip it.
      if (!changed) {
         // Let the function keys go through.
         if (pos("F", keySequence, 1, "I") == 1) {
            newSequence = keySequence;
         } else {
            //say("   SKIPPING '"keyList[i]"'");
            keyList[i] = "";
            continue;
         }
      }

      // Translate special key names.
      //   INS        ==> Insert
      //   DEL        ==> Delete
      //   UP         ==> Arrow_Up
      //   DOWN       ==> Arrow_Down
      //   LEFT       ==> Arrow_Left
      //   RIGHT      ==> Arrow_Right
      //   PGUP       ==> Page_Up
      //   PGDN       ==> Page_Down
      if (pos("+INS", newSequence, 1, "I")) {
         j = pos("+INS", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Insert"substr(newSequence, j+4);
      } else if (pos("+DEL", newSequence, 1, "I")) {
         j = pos("+DEL", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Delete"substr(newSequence, j+4);
      } else if (pos("+UP", newSequence, 1, "I")) {
         j = pos("+UP", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Arrow_Up"substr(newSequence, j+3);
      } else if (pos("+DOWN", newSequence, 1, "I")) {
         j = pos("+DOWN", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Arrow_Down"substr(newSequence, j+5);
      } else if (pos("+LEFT", newSequence, 1, "I")) {
         j = pos("+LEFT", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Arrow_Left"substr(newSequence, j+5);
      } else if (pos("+RIGHT", newSequence, 1, "I")) {
         j = pos("+RIGHT", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Arrow_Right"substr(newSequence, j+6);
      } else if (pos("+PGUP", newSequence, 1, "I")) {
         j = pos("+PGUP", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Page_Up"substr(newSequence, j+5);
      } else if (pos("+PGDN", newSequence, 1, "I")) {
         j = pos("+PGDN", newSequence, 1, "I");
         newSequence = substr(newSequence, 1, j)"Page_Down"substr(newSequence, j+5);
      }

      // Don't take certain sequence.
      dontTake = false;
      for (j=0; j<gKeySequencesNotToTake._length(); j++) {
         if (newSequence == gKeySequencesNotToTake[j]) {
            //say("   NOT TAKING '"keyList[i]"'");
            keyList[i] = "";
            dontTake = true;
            break;
         }
      }
      if (dontTake) continue;

      // Update the key sequence.
      //say("   '"keyList[i]"'  ==> '"newSequence"'");
      keyList[i] = newSequence;
   }
}
 */
defeventtab _tboutputwin_form;
_tboutputwin_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}

defeventtab _tbsearch_form;
_tbsearch_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}

defeventtab _eclipseBuildOutputForm;
_eclipseBuildOutputForm.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
_eclipseBuildOutputForm.'C-M'()
{
   if (def_keys == 'eclipse-keys') {
      eclipse_maximize_part();
   }
}
_eclipseBuildOutputForm.'F12'()
{
   eclipse_activate_editor();
}

defeventtab _tbtagwin_form;
_tbtagwin_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbproctree_form;
_tbproctree_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbtagrefs_form;
_tbtagrefs_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbclass_form;
_tbclass_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbcbrowser_form;
_tbcbrowser_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbFTPOpen_form;
_tbFTPOpen_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
defeventtab _tbFTPClient_form;
_tbFTPClient_form.'A-F4'()
{
   // Do nothing... and prevent the SWTForm from being closed.
}
