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
#include "se/ui/toolwindow.sh"
#include "dockchannel.sh"
#include "debug.sh"
#require "sc/controls/SaveActiveWindow.e"
#import "help.e"
#import "mprompt.e"
#import "stdprocs.e"
#import "tbview.e"
#import "picture.e"
#import "main.e"
#import "toolbar.e"
#import "dlgman.e"
#import "files.e"
#import "window.e"
#import "se/ui/twevent.e"
#import "se/ui/mainwindow.e"
#import "se/ui/twautohide.e"
#endregion

// This table is modified during editor execution and
// autorestored.
ToolWindowInfo g_toolwindowtab:[];

// Default tool-window setup used by tw_reset_all()
static ToolWindowInfo init_toolwindowtab:[] = {
   '_tbsymbol_props_form'        => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbsymbol_args_form'         => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbslickc_stack_form'        => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, 0},
   '_tbprojects_form'            => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, 0},
   '_tbproctree_form'            => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, TW_REQUIRE_DEFS},
   '_tbcbrowser_form'            => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbfind_symbol_form'         => {TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbfilelist_form'            => {TWF_SUPPORTS_MULTIPLE | TWF_NO_DOCKING | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, 0},
   '_tbopen_form'                => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_LEFT, 0},
   '_tbFTPOpen_form'             => {0, DOCKAREAPOS_LEFT,   TW_REQUIRE_FTP},
   '_tbFTPClient_form'           => {0, DOCKAREAPOS_BOTTOM, TW_REQUIRE_FTP},
   '_tbunittest_form'            => {0, DOCKAREAPOS_NONE, TW_REQUIRE_BUILD},
   '_tbsearch_form'              => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, 0},
   '_tbtagwin_form'              => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbtagrefs_form'             => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbshell_form'               => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_BUILD},
   '_tbterminal_form'            => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_BUILD},
   '_tbinteractive_form'         => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_BUILD},
   '_tboutputwin_form'           => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, 0},
   '_tbbookmarks_form'           => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_NONE, 0},
   '_tbbufftabs_form'            => {TWF_SUPPORTS_MULTIPLE | TWF_FIXEDHEIGHT | TWF_NO_TABLINK, DOCKAREAPOS_BOTTOM, TW_REQUIRE_BUFFTABS},
   '_tbdebug_stack_form'         => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_LEFT,   TW_REQUIRE_DEBUGGING},
   '_tbdebug_locals_form'        => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_BOTTOM, TW_REQUIRE_DEBUGGING},
   '_tbdebug_members_form'       => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_BOTTOM, TW_REQUIRE_DEBUGGING},
   '_tbdebug_watches_form'       => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_BOTTOM, TW_REQUIRE_DEBUGGING},
   '_tbdebug_autovars_form'      => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_BOTTOM, TW_REQUIRE_DEBUGGING},
   '_tbdebug_threads_form'       => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbdebug_classes_form'       => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbdebug_regs_form'          => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbdebug_memory_form'        => {TWF_WHEN_DEBUGGER_STARTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbdebug_breakpoints_form'   => {TWF_LIST_WITH_DEBUG_TOOLWINDOWS | TWF_WHEN_DEBUGGER_SUPPORTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbdebug_exceptions_form'    => {TWF_LIST_WITH_DEBUG_TOOLWINDOWS | TWF_WHEN_DEBUGGER_SUPPORTED_ONLY, DOCKAREAPOS_NONE, TW_REQUIRE_DEBUGGING},
   '_tbfind_form'                => {TWF_NO_DOCKING | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, 0},
   '_tbregex_form'               => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, 0},
   '_tbsymbolcalls_form'         => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbsymbolcallers_form'       => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbbaseclasses_form'         => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbderivedclasses_form'      => {TWF_SUPPORTS_MULTIPLE | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbdeltasave_form'           => {0, DOCKAREAPOS_NONE, TW_REQUIRE_BACKUP_HISTORY},
   '_tbannotations_browser_form' => {0, DOCKAREAPOS_NONE, TW_REQUIRE_PRO_MACROS},
   '_tbmessages_browser_form'    => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_BOTTOM, TW_REQUIRE_BUILD|TW_REQUIRE_REALTIMEERRORS},
   '_tbclass_form'               => {TWF_SUPPORTS_MULTIPLE, DOCKAREAPOS_LEFT, TW_REQUIRE_CONTEXT_TAGGING},
   '_tbclipboard_form'           => {TWF_SUPPORTS_MULTIPLE | TWF_NO_DOCKING | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, 0},
   '_tbnotification_form'        => {TWF_NO_DOCKING | TWF_DISMISS_LIKE_DIALOG, DOCKAREAPOS_NONE, 0},
};

// Default width, height for a docked tool-window in twips
static const TWDEFAULT_DOCKED_WIDTH=  (5700);
static const TWDEFAULT_DOCKED_HEIGHT= (3450);

int def_toolwindow_options = 0;

definit()
{
   if( g_toolwindowtab == null ) {
      g_toolwindowtab = init_toolwindowtab;
   } else if( arg(1) == 'L' ) {
      _str form_name;
      ToolWindowInfo info;
      foreach ( form_name=> info in init_toolwindowtab ) {
         // IF we added a tool window, add it on load
         if ( !g_toolwindowtab._indexin(form_name) ) {
            g_toolwindowtab:[form_name] = info;
         } else {
            ToolWindowInfo info2 = g_toolwindowtab:[form_name];
            info2.flags &= ~(TWF_SYSTEM_MASK);
            info2.flags |= (info.flags & TWF_SYSTEM_MASK);
            info2.rflags = info.rflags;
            g_toolwindowtab:[form_name] = info2;
         }
      }
   }
}

bool tw_is_docking_allowed()
{
   // Docking allowed globally?
   dockingAllowed := 0 != (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_TOOLBAR_DOCKING);
   return dockingAllowed;
}

_command void tw_refresh_all()
{
   _str visibleFormList[];
   _str currentFormList[];
   foreach ( auto formName => . in g_toolwindowtab ) {
      if ( tw_is_visible(formName) ) {
         visibleFormList :+= formName;
      }
      if ( tw_is_current_form(formName) ) {
         currentFormList :+= formName;
      }
   }
   foreach ( formName in visibleFormList ) {
      tw_toggle(formName);
      tw_toggle(formName);
   }
   foreach ( formName in currentFormList ) {
      tw_show_tabgroup(formName);
   }
}

void tw_sanity()
{
   _str formName;
   ToolWindowInfo info;
   foreach ( formName => info in g_toolwindowtab ) {

      if ( !isinteger(info.flags) ) {
         g_toolwindowtab:[formName].flags = 0;
      }
   }

   // Ensure all available tool-windows are in the table
   foreach ( formName => info in init_toolwindowtab ) {

      if( !g_toolwindowtab._indexin(formName) ) {
         g_toolwindowtab:[formName] = info;
      }
   }
}

ToolWindowInfo* tw_find_info(_str formName)
{
   return g_toolwindowtab._indexin(formName);
}

ToolWindowInfo* tw_find_info_by_caption(_str caption, int& index)
{
   _str fn;
   ToolWindowInfo twinfo;
   foreach ( fn => twinfo in g_toolwindowtab ) {
      index = find_index(fn, oi2type(OI_FORM));
      if ( index != 0 && strieq(index.p_caption, caption) ) {
         return g_toolwindowtab._indexin(fn);
      }
   }
   // Not found
   return null;
}

_str tw_get_caption(_str formName)
{
   index := find_index(formName, oi2type(OI_FORM));
   if (index) {
      return index.p_caption;
   }

   return '';
}

/**
 * Register a form in g_toolwindowtab table. Registered forms 
 * are remembered across sessions. 
 * 
 * @param formName  Name of form.
 * @param flags     ToolWindowFlag flags.
 * @param preferredArea 
 * @param rflags    ToolWindowRequirementFlag flags.
 *
 * @return 0 on success, <0 on error.
 */

int tw_register_form(_str formName, int flags, DockAreaPos preferredArea, int rflags=0)
{
   tw_sanity();

   int index = find_index(formName, oi2type(OI_FORM));
   if ( !index) {
      return VSRC_FORM_NOT_FOUND;
   }

   if ( !g_toolwindowtab._indexin(formName) ) {
      ToolWindowInfo info;
      info.flags = flags;
      info.preferredArea = preferredArea;
      info.rflags = rflags;
      g_toolwindowtab:[formName] = info;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // All good
   return 0;
}

/**
 * Load form window. Return window id of created form. 
 * 
 * @param formName  Name of form.
 * 
 * @return Window id on success, <0 on error.
 */
int tw_load_form(_str formName)
{
   ToolWindowInfo* info = tw_find_info(formName);
   if ( !info ) {
      return VSRC_TOOL_WINDOW_NOT_FOUND;
   }
   int index = find_index(formName, oi2type(OI_FORM));
   if ( !index) {
      return VSRC_FORM_NOT_FOUND;
   }
   // P = Child window
   // N = Force no border
   noBorder := "PN";
   // C = Do not call on_create(), on_load(), on_resize().
   // If a tool-window attempts to show itself before it has
   // been inserted into a layout (_tbunittest_form), then it
   // will keep recursing and loading up the same form. Delay 
   // calling on_create()/on_load() until after it is inserted
   // into a layout.
   int wid = _load_template(index, _mdi, 'CH':+noBorder);
   if ( wid > 0 ) {
      int status = tw_register(wid, info->flags, info->preferredArea);
      if ( status ) {
         wid._delete_window();
         return status;
      }
      // Defer on_create/on_load/on_resize() to _on_create_tool_window()
      // W = Call on_create(), on_load(), on_resize() for registered window
      //_load_template(wid, _mdi, 'WH':+noBorder);
   }
   return wid;
}

/**
 * If form window is already loaded, then delete it before 
 * reloading. Return window id of created form. 
 * 
 * @param formName  Name of form.
 * @param flags     ToolWindowFlag flags.
 * 
 * @return Window id on success, <0 on error.
 */
static int tw_reload_form(_str formName)
{
   // We probably don't need to look for duplicates,
   // here because this is odd error handling code.
   int wid = _find_formobj(formName, 'N');
   if( wid != 0 ) {
      if ( wid.p_isToolWindow ) {
         // Delete with prejudice
         wid._delete_window();
         wid = 0;
      }
   }
   return tw_load_form(formName);
}

/**
 * Return true if <code>wid</code> is a visible tool-window. 
 * 
 * @param wid 
 * 
 * @return bool
 */
bool tw_is_visible_window(int wid)
{
   if ( !wid || !wid.p_isToolWindow ) {
      return false;
   }
   // Raised autohide window?
   if ( tw_is_auto_raised(wid) ) {
      return true;
   }
   // Part of a dockarea?
   if ( tw_next_window(wid, 'N', false) ) {
      return true;
   }
   // Not visible
   return false;
}

/**
 * Return visible tool-window wid for form 
 * <code>form_name</code>, or 0 if not visible. Set 
 * <code>to_mdi_wid</code> if you only want the visible wid on a 
 * specific mdi window. 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_visible(_str form_name, int to_mdi_wid=0)
{
   int mdi_wid = to_mdi_wid > 0 ? to_mdi_wid : _MDICurrent();
   // check if this tool window is docked to the MDI window
   int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
   // IF this tool window is not docked in the MDI window
   if ( !wid && !to_mdi_wid ) {
      // Find this tool window anywhere
      wid = _find_formobj(form_name, 'n');
   }
   if ( tw_is_visible_window(wid) ) {
      return wid;
   }
   // No visible window
   return 0;
}

/**
 * Return true if <code>wid</code> is a docked tool-window or 
 * the child of a docked tool-window. Use 
 * <code>p_DockingArea</code> if you need to know which side the 
 * window is docked. 
 *
 * <p>
 *
 * A docked tool-window is a window that is part of an 
 * mdi-window (floating or not) that has an mdi-area (editor 
 * windows). Auto-hide windows (whether raised or lowered) are 
 * always docked. 
 * 
 * @param wid 
 * 
 * @return bool    
 */
bool tw_is_docked_window(int wid)
{
   if ( !wid ) {
      return false;
   }
   int formwid = wid.p_active_form;
   if ( !formwid.p_isToolWindow ) {
      return false;
   }
   int mdi_wid = _MDIFromChild(formwid);
   if ( mdi_wid > 0 ) {
      return _MDIWindowHasMDIArea(mdi_wid);
   }
   return false;
}

/**
 * Return docked tool-window wid for form 
 * <code>form_name</code>, or 0 if no docked window exists. Set 
 * <code>to_mdi_wid</code> if you only want the docked wid on a 
 * specific mdi window. 
 *
 * <p>
 *
 * A docked tool-window is a window that is part of an 
 * mdi-window (floating or not) that has an mdi-area (editor 
 * windows). Auto-hide windows (whether raised or lowered) are 
 * always docked. 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_docked(_str form_name, int to_mdi_wid=0)
{
   int mdi_wid = to_mdi_wid > 0 ? to_mdi_wid : _MDICurrent();
   int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
   if ( wid > 0 && tw_is_docked_window(wid) ) {
      return wid;
   }
   if ( to_mdi_wid > 0 ) {
      // Not docked
      return 0;
   }
   // Check all mdi windows (to_mdi_wid == -1)
   int mwids[];
   int mwid;
   _MDIGetMDIWindowList(mwids);
   foreach ( mwid in mwids ) {
      if ( mwid == mdi_wid ) {
         // We already checked the current window
         continue;
      }
      wid = _MDIFindFormObject(mwid, form_name, 'n');
      if ( wid > 0 && tw_is_docked_window(wid) ) {
         return wid;
      }
   }
   // Not docked
   return 0;
}

/**
 * Return true if <code>wid</code> is an undocked tool-window or
 * the child of an undocked tool-window. 
 *
 * <p>
 *
 * An undocked tool-window is a window that is part of a 
 * floating mdi-window that has no mdi-area (no editor windows). 
 * Auto-hide windows (whether raised or lowered) are never 
 * undocked. 
 * 
 * @param wid 
 * 
 * @return bool
 */
bool tw_is_undocked_window(int wid)
{
   if ( !wid ) {
      return false;
   }
   int formwid = wid.p_active_form;
   if ( !formwid.p_isToolWindow ) {
      return false;
   }
   int mdi_wid = _MDIFromChild(formwid);
   if ( mdi_wid > 0 ) {
      return !_MDIWindowHasMDIArea(mdi_wid);
   }
   return false;
}

/**
 * Return undocked tool-window wid for form 
 * <code>form_name</code>, or 0 if no undocked window exists. 
 * Set <code>to_mdi_wid</code> if you only want the undocked wid 
 * on a specific mdi window. 
 *
 * <p>
 *
 * An undocked tool-window is a window that is part of a 
 * floating mdi-window that has no mdi-area (no editor windows). 
 * Auto-hide windows (whether raised or lowered) are never 
 * undocked. 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_undocked(_str form_name, int to_mdi_wid=0)
{
   int mdi_wid = to_mdi_wid > 0 ? to_mdi_wid : _MDICurrent();
   int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
   if ( wid > 0 && tw_is_undocked_window(wid) ) {
      return wid;
   }
   if ( to_mdi_wid > 0 ) {
      // Not undocked
      return 0;
   }
   // Check all mdi windows (to_mdi_wid == -1)
   int mwids[];
   int mwid;
   _MDIGetMDIWindowList(mwids);
   foreach ( mwid in mwids ) {
      if ( mwid == mdi_wid ) {
         // We already checked the current window
         continue;
      }
      wid = _MDIFindFormObject(mwid, form_name, 'n');
      if ( wid > 0 && tw_is_undocked_window(wid) ) {
         return wid;
      }
   }
   // Not undocked
   return 0;
}

/** 
 * @return 
 * Return true if <code>wid</code> is a dockable tool-window 
 * and docking is allowed. 
 *
 * @param wid 
 */
bool tw_is_dockable_window(int wid)
{
   if ( isEclipsePlugin() || !tw_is_docking_allowed() ) {
      return false;
   }
   if ( !wid || !wid.p_isToolWindow ) {
      return false;
   }
   ToolWindowInfo* twinfo = tw_find_info(wid.p_name);
   if ( !twinfo || 0 != (twinfo->flags & TWF_NO_DOCKING) ) {
      return false;
   }
   return true;
}

/**
 * Return true if <code>wid</code> is a solo tool-window. 
 *
 * <p>
 *
 * A solo tool-window is one that floats by itself (no other 
 * tool-windows or document windows). 
 *  
 * @param wid 
 * 
 * @return bool
 */
bool tw_is_solo_window(int wid)
{
   if ( tw_is_undocked_window(wid) && wid == tw_next_window(wid, 'N', false) ) {
      return true;
   }
   // Not a solo tool-window
   return false;
}

/**
 * Return solo tool-window wid for form <code>form_name</code>, 
 * or 0 if no solo window exists. 
 *
 * <p>
 *
 * A solo tool-window is one that floats by itself (no other 
 * tool-windows or document windows). 
 *  
 * @param form_name 
 * 
 * @return bool
 */
int tw_is_solo(_str form_name)
{
   // Check all mdi windows (to_mdi_wid == -1)
   int mwids[];
   int mwid;
   _MDIGetMDIWindowList(mwids);
   foreach ( mwid in mwids ) {
      if ( mwid == _mdi ) {
         // main mdi-window cannot be solo
         continue;
      }
      int wid = _MDIFindFormObject(mwid, form_name, 'n');
      if ( wid > 0 && tw_is_solo_window(wid) ) {
         return wid;
      }
   }
   // Not a solo tool-window
   return 0;
}

/**
 * Return true if <code>wid</code> is current Tab in its 
 * tabgroup, or raised auto-hide window. 
 * 
 * @param wid 
 * 
 * @return bool
 */
bool tw_is_current(int wid)
{
   if ( !wid || !wid.p_isToolWindow ) {
      return false;
   }
   if ( !testFlag(wid.p_window_flags, VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
      return false;
   }
   if ( tw_is_auto_raised(wid)
        || wid == tw_next_window(wid, 'C', false) ) {

      return true;
   }
   return false;
}

/**
 * Return current tool-window wid (e.g. current Tab in tabgroup,
 * raised auto-hide window) for form <code>form_name</code>, or 
 * 0 if not current. Set <code>to_mdi_wid</code> if you only 
 * want the current wid on a specific mdi window. 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_current_form(_str form_name, int to_mdi_wid=0)
{
   int wid = tw_is_visible(form_name, to_mdi_wid);
   if ( wid > 0 && tw_is_current(wid) ) {
      return wid;
   }
   return 0;
}

/**
 *  Test whether window <code>wid</code> is, or is a child of, a
 *  current tool-window. 
 * 
 * @param wid 
 * 
 * @return bool
 *
 * @see tw_is_current
 */
bool tw_is_wid_active(int wid)
{
   if ( !wid || !_iswindow_valid(wid) ) {
      return false;
   }
   return tw_is_current(wid.p_active_form);
}

/**
 * @return 
 * Returns 'true' if 'form_wid1' and 'form_wid2' are docked on the 
 * same floating editor window group. 
 * 
 * @param form_wid1    first tool window instance
 * @param form_wid2    second tool window instance 
 *  
 * @see tw_is_docked_window 
 * @see _MDIFromChild() 
 */
bool tw_is_from_same_mdi(int form_wid1,int form_wid2) 
{
   if (form_wid1.p_parent==form_wid2) return true;
   if (form_wid2.p_parent==form_wid1) return true;
   int mdi_wid1=_MDIFromChild(form_wid1);
   int mdi_wid2=_MDIFromChild(form_wid2);
   if (!mdi_wid1 && !mdi_wid2) {
      // Assume multiple MDI windows not supported
      return true;
   }
   if (!mdi_wid1 || !mdi_wid2) {
      return false;
   }
   if (mdi_wid1==mdi_wid2) {
      return true;
   }
   if (tw_is_docked_window(form_wid1)) {
      return !tw_is_docked_window(form_wid2);
   }
   if (tw_is_docked_window(form_wid2)) {
      return true;
   }
   // Both are floating tool windows
   return true;
}


static bool _onCreateAlreadyCalled()
{
   return testFlag(p_window_flags, VSWFLAG_ON_CREATE_ALREADY_CALLED);
}

/**
 * Find most "immediate" tool-window with name 
 * <code>form_name</code> and return window id. 
 *
 * <p>
 *
 * Set mdi-window id <code>mdi_wid</code> to find window on a 
 * specific mdi-window (defaults to 0 which finds on current 
 * mdi-window). Make sure to also include the 
 * <code>TWFF_CURRENT_MDI</code> flag in <code>flags</code>. 
 *
 * <p>
 *
 * Set <code>flags</code> to one or more of 
 * <code>ToolWindowFindFormFlag</code> to narrow search 
 * criteria. Flags default to all criteria (-1). 
 *
 * <p>
 *
 * Note that window returned may not be current/visible. 
 *
 * <p>
 *
 * Note that a window that has not had ON-CREATE called yet will
 * not be found. 
 *
 * <p>
 *
 * Search for the most immediate tool-window is in the following 
 * order: 
 * <li>Active form.
 * <li>Form with focus.
 * <li>Current MDI window.
 * <li>Undocked window.
 * <li>Any where.
 * 
 * @param form_name 
 * 
 * @return Window id. 
 */
int tw_find_form(_str form_name, int mdi_wid=0, int flags=-1)
{
   if ( !tw_find_info(form_name) ) {
      return 0;
   }

   formwid := 0;
   do {

      // Case: Active form
      if ( testFlag(flags, TWFF_ACTIVE_FORM) ) {
         if ( p_active_form.p_name :== form_name && !p_active_form.p_edit) {
            if ( p_active_form._onCreateAlreadyCalled() ) {
               formwid = p_active_form;
               break;
            }
         }
      }

      // Case: Form with focus
      if ( testFlag(flags, TWFF_FOCUS_FORM) ) {
         wid := _get_focus();
         if ( wid > 0 && wid.p_active_form.p_name :== form_name && !wid.p_active_form.p_edit) {
            if ( wid.p_active_form._onCreateAlreadyCalled() ) {
               formwid = wid.p_active_form;
               break;
            }
         }
      }

      // Case: Current MDI window
      if ( testFlag(flags, TWFF_CURRENT_MDI) ) {
         mdi_wid = mdi_wid == 0 ? _MDICurrent() : mdi_wid;
         if ( mdi_wid > 0 ) {
            int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
            if ( wid > 0 && wid._onCreateAlreadyCalled() ) {
               formwid = wid;
               break;
            }
         }
      }

      // Case: Undocked window
      if ( testFlag(flags, TWFF_UNDOCKED) ) {
         int wid = tw_is_undocked(form_name);
         if ( wid > 0 && wid._onCreateAlreadyCalled() ) {
            formwid = wid;
            break;
         }
      }

      // Case: Any where
      // rb - I'm not sure the "any where" case is needed
      if ( testFlag(flags, TWFF_ANY) ) {
         int wid = _find_formobj(form_name, 'n');
         if ( wid > 0 && wid._onCreateAlreadyCalled() ) {
            formwid = wid;
            break;
         }
      }

   } while ( false );

   return formwid;
}

/**
 * Return DockAreaPos of tool-window instance of form 
 * <code>form_name</code>, or 0 (DOCKAREAPOS_NONE) if 
 * tool-window is not docked. Set <code>to_mdi_wid</code> if you
 * only want the tool-window pos on a specific mdi window. Note 
 * that if <code>to_mdi_wid</code> is not specified, then the 
 * current mdi-window is always checked first. 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return DockAreaPos 
 */
DockAreaPos tw_dock_area_of_form(_str form_name, int to_mdi_wid=0)
{
   int mdi_wid = to_mdi_wid > 0 ? to_mdi_wid : _MDICurrent();
   int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
   if ( wid > 0 ) {
      apos := (DockAreaPos)wid.p_DockingArea;
      if ( apos != DOCKAREAPOS_NONE ) {
         return apos;
      }
   }

   if ( to_mdi_wid > 0 ) {
      // Caller specified mdi-window to check
      return DOCKAREAPOS_NONE;
   }

   // Check all mdi windows
   int mwids[];
   int mwid;
   _MDIGetMDIWindowList(mwids);
   foreach ( mwid in mwids ) {
      if ( mwid == mdi_wid ) {
         // We already checked the current window
         continue;
      }
      //say('tw_dock_area_of_form : mwid='mwid'  p_visible='mwid.p_visible);
      wid = _MDIFindFormObject(mwid, form_name, 'n');
      if ( wid > 0 ) {
         apos := (DockAreaPos)wid.p_DockingArea;
         if ( apos != DOCKAREAPOS_NONE ) {
            return apos;
         }
      }
   }

   // Not docked
   return DOCKAREAPOS_NONE;
}

void tw_enable(int wid, bool enable=true)
{
   if ( wid <= 0 || !_iswindow_valid(wid) || !wid.p_isToolWindow ) {
      return;
   }
   // v19 tool-window support makes it safe to enable/disable child windows.
   // For now it is the same as setting p_enabled.
   wid.p_enabled = enable;
}

// Convenience class for testing whether tool-window meets supported feature requirements.
class ToolWindowFeatures {
   private int m_rmask;
   ToolWindowFeatures() {
      m_rmask = 0;
      m_rmask |= _haveBuild()          ? TW_REQUIRE_BUILD           : 0;
      m_rmask |= _haveDebugging()      ? TW_REQUIRE_DEBUGGING       : 0;
      m_rmask |= _haveContextTagging() ? TW_REQUIRE_CONTEXT_TAGGING : 0;
      m_rmask |= _haveVersionControl() ? TW_REQUIRE_VERSION_CONTROL : 0;
      m_rmask |= _haveProMacros()      ? TW_REQUIRE_PRO_MACROS      : 0;
      m_rmask |= _haveBeautifiers()    ? TW_REQUIRE_BEAUTIFIER      : 0;
      m_rmask |= _haveRefactoring()    ? TW_REQUIRE_REFACTORING     : 0;
      m_rmask |= _haveRealTimeErrors() ? TW_REQUIRE_REALTIMEERRORS  : 0;
      m_rmask |= _haveProDiff()        ? TW_REQUIRE_PRO_DIFF        : 0;
      m_rmask |= _haveMerge()          ? TW_REQUIRE_MERGE           : 0;
      m_rmask |= _haveDefsToolWindow() ? TW_REQUIRE_DEFS            : 0;
      m_rmask |= _haveFTP()            ? TW_REQUIRE_FTP             : 0;
      m_rmask |= _haveBackupHistory()  ? TW_REQUIRE_BACKUP_HISTORY  : 0;
      m_rmask |= _haveFileTabsWindow() ? TW_REQUIRE_BUFFTABS        : 0;
   }
   /**
    * Test requirement flag(s) and return true if all 
    * <code>rflags</code> are supported. 
    * 
    * @param rflags One or more ToolWindowRequireFlag. 
    */
   bool testFlags(int rflags) {
      return (m_rmask & rflags) == rflags;
   }
   bool testForm(_str formName) {
      ToolWindowInfo* twinfo = tw_find_info(formName);
      if ( twinfo ) {
         return (m_rmask & twinfo->rflags) == twinfo->rflags;
      }
      return false;
   }
};

bool tw_is_allowed(_str form_name, ToolWindowInfo* twinfo=null)
{
   if ( isEclipsePlugin() ) {
      return false;
   }

   twinfo = twinfo == null ? tw_find_info(form_name) : twinfo;
   if ( null == twinfo || !twinfo ) {
      return true;
   }

   ToolWindowFeatures features;
   if ( !isinteger(twinfo->rflags) ) twinfo->rflags = 0;
   if ( !features.testFlags(twinfo->rflags) ) {
      return false;
   }

   // rb - I think the idea here is that, if the form does not
   // exist, you will get a more descriptive error when returning
   // true for (index == 0) case.
   int index = find_index(form_name, oi2type(OI_FORM));
   if ( index == 0 ) {
      return true;
   }

   //list="Output,Slick-C Stack";
   typeless list = _default_option(VSOPTIONZ_SUPPORTED_TOOLBARS_LIST);
   if ( list._isempty() ) {
      return true;
   }
   list = ','list',';
   if ( 0 == pos(','index.p_caption',', list, 1, 'i') ) {
      return false;
   }

   return true;
}

static void _post_set_focus(int wid=-1)
{
   if ( wid == -1 ) {
      _post_call(_post_set_focus, p_window_id);
   } else {
      p_window_id = wid;
      _set_focus();
   }
}

/**
 * Show tool-window by <code>form_name</code> and return window
 * id. If the tool-window was part of a tabgroup, then it is
 * restored to the tabgroup and form_name made active. Set
 * <code>restore_others=true</code> to restore all tabs in the
 * tabgroup.
 * 
 * @param form_name 
 * @param restore_others 
 *
 * @return Window id of tool-window, <0 on error.
 */
int tw_show_tabgroup(_str form_name, bool restore_others=false)
{
   if( !tw_is_allowed(form_name) ) {
      return 0;
   }
   ToolWindowInfo* twinfo = tw_find_info(form_name);
   if ( !twinfo ) {
      return 0;
   }

   result := 0;
   RestoreGroupInfo info;

   int current_mdi = _MDICurrent();
   current_mdi = current_mdi <= 0 ? _mdi : current_mdi;
   ff := -1;
   // If a tool-window does not support duplicates, then we want to be sure
   // to find any instance regardless of which mdi-window it belongs to.
   if ( testFlag(twinfo->flags, TWF_SUPPORTS_MULTIPLE) ) {
      ff &= ~(TWFF_ANY);
   }
   wid := tw_find_form(form_name, current_mdi, ff);

   if ( wid > 0 && tw_is_visible_window(wid) ) {
      if ( !tw_is_current(wid) ) {
         tw_set_active(wid);
         wid.call_event(wid, ON_GOT_FOCUS, 'W');
      }
      return wid;
   }
   if ( wid > 0 && tw_is_auto(wid) ) {
      // Raise auto-hide window
      tw_auto_raise(wid);
      wid.call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
      tw_set_active(wid);
      wid.call_event(wid, ON_GOT_FOCUS, 'W');
      result = wid;

   } else {
      // Show

      // Note that if we got here, then the tool-window is not visible/active/autohide,
      // so we must restore it.

      // Restore the group (if any)
      if ( current_mdi == _mdi ) {
         // Docked - restore to last position, docked or floating, since
         // the user would be surprised if he floated a tool-window, closed
         // it, then restored it and it restored docked instead of floating.
         tw_get_restore_info(form_name, RESTORE_LAST, info);
      } else {
         // Floating - restore floating since we are in a floating window
         tw_get_restore_info(form_name, RESTORE_FLOATING, info);
         if ( info.items._length() == 0 ) {
            // Try for anything
            tw_get_restore_info(form_name, RESTORE_LAST, info);
         }
      }
      if ( info.items._length() > 0 ) {

         int i, n = info.items._length();
         for ( i = 0; i < n; ++i ) {
            if ( info.items[i].wid == 0 ) {
               if ( restore_others || info.items[i].name == form_name ) {
                  wid = tw_load_form(info.items[i].name);
                  wid.p_tile_id = _create_tile_id();
                  tw_restore(wid, info.position);
                  restore_focus := false;
                  wid._on_create_tool_window(restore_focus);
                  if ( !restore_others ) {
                     // Only restoring form_name, so done
                     break;
                  }
               }
            }
         }

      } else {
         show_tool_window(form_name);
      }
      wid = tw_is_visible(form_name);
      if ( wid > 0 ) {
         tw_set_active(wid);
         wid.call_event(wid, ON_GOT_FOCUS, 'W');
         result = wid;
      }
   }
   return result;
}

/**
 * Hide tool-window by window id <code>wid</code>. If the 
 * tool-window is part of a tabgroup, then the entire tabgroup 
 * is hidden. If <code>hide_others=true</code>, then all 
 * tool-windows in group except <code>wid</code> are hidden. If 
 * tool-window is auto-hidden, then it is lowered. 
 * 
 * @param wid 
 * @param hide_others 
 */
void tw_hide_tabgroup_window(int wid, bool hide_others=false)
{
   int current_mdi = _MDICurrent();
   current_mdi = current_mdi <= 0 ? _mdi : current_mdi;

   if ( wid == 0 || !wid.p_isToolWindow || !tw_is_visible_window(wid) ) {
      // Nothing to do
      return;
   }
   if ( wid > 0 && tw_is_auto(wid) ) {
      // Lower auto-hide window

      tw_auto_lower(wid);
      int child_wid = _MDICurrentChild(current_mdi);
      if ( child_wid > 0 ) {
         p_window_id = child_wid;
         _set_focus();
      }

   } else if( wid > 0 ) {
      // Hide

      // Hide all windows grouped (e.g. tabgroup) with this one
      int group[];
      int first_wid = wid;
      do {
         group[group._length()] = wid;
         wid = tw_next_window(wid, '1', false);
      } while ( wid > 0 && wid != first_wid );
      int i, n = group._length();
      for ( i = 0; i < n; ++i ) {
         if ( !hide_others || group[i] != first_wid ) {
            tw_hide_window(group[i]);
         }
      }
      // If we do not do this, then focus will switch to previous tool-window
      int child_wid = _MDICurrentChild(current_mdi);
      if ( child_wid ) {
         child_wid._post_set_focus();
      }
   }
}

/**
 * Hide tool-window by <code>form_name</code>. If the 
 * tool-window is part of a tabgroup, then the entire tabgroup 
 * is hidden. If <code>hide_others=true</code>, then all 
 * tool-windows in group except <code>form_name</code> are 
 * hidden. If tool-window is auto-hidden, then it is lowered. 
 * 
 * @param form_name 
 * @param hide_others 
 */
void tw_hide_tabgroup(_str form_name, bool hide_others=false)
{
   int current_mdi = _MDICurrent();
   current_mdi = current_mdi <= 0 ? _mdi : current_mdi;
   int ff = -1 & ~(TWFF_ANY);
   wid := tw_find_form(form_name, current_mdi, ff);
   tw_hide_tabgroup_window(wid, hide_others);
}

/**
 * Toggle tool-window by <code>form_name</code>. If the 
 * tool-window is part of a tabgroup, then the entire tabgroup 
 * is toggled. If tool-window is auto-hidden, then it is raised.
 * When toggling ON, optionally put focus on
 * <code>focus_control_name</code> and return window id of
 * tool-window.
 * 
 * @param form_name 
 * @param focus_control_name 
 * @param toggle_pinned 
 *
 * @return Window id of tool-window if toggled ON, 0 if toggled
 *         OFF, &lt;0 on error.
 */
int tw_toggle_tabgroup(_str form_name, _str focus_control_name='', bool toggle_pinned=false)
{
   if( !tw_is_allowed(form_name) ) {
      return 0;
   }

   result := 0;
   RestoreGroupInfo info;

   int current_mdi = _MDICurrent();
   current_mdi = current_mdi <= 0 ? _mdi : current_mdi;
   int ff = -1 & ~(TWFF_ANY);
   wid := tw_find_form(form_name, current_mdi, ff);

   if ( wid > 0 && tw_is_auto(wid) ) {
      // Raise or lower auto-hide window

      if ( tw_is_auto_raised(wid) ) {
         // Lower
         tw_auto_lower(wid);
         int child_wid = _MDICurrentChild(current_mdi);
         if ( child_wid > 0 ) {
            p_window_id = child_wid;
            _set_focus();
         }
      } else {
         if (toggle_pinned) {
            // Pin
            autorestore_tool_window(wid);
         } else {
            // Raise
            tw_auto_raise(wid);
         }
         wid.call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
         tw_set_active(wid);
         if( focus_control_name != '' ) {
            ctlwid := wid._find_control(focus_control_name);
            if( ctlwid > 0 ) {
               ctlwid._set_focus();
            }
         }
         result = wid;
      }

   } else if ( wid > 0 && toggle_pinned && tw_is_dockable_window(wid)) {

      // if not already docked, dock it
      if (!tw_is_docked_window(wid)) {
         dock_tool_window(wid);
      }

      // Pin
      autohide_tool_window(wid);

   } else if( wid > 0 ) {
      // Hide

      // Hide all windows grouped (e.g. tabgroup) with this one
      int group[];
      int first_wid = wid;
      do {
         group[group._length()] = wid;
         wid = tw_next_window(wid, '1', false);
      } while ( wid > 0 && wid != first_wid );
      int i, n = group._length();
      for ( i = 0; i < n; ++i ) {
         hide_tool_window(group[i]);
      }
      // If we do not do this, then focus will switch to previous tool-window
      int child_wid = _MDICurrentChild(current_mdi);
      if ( child_wid ) {
         child_wid._post_set_focus();
      }

   } else {
      // Show

      // Note that if we got here, then the tool-window is not visible/active/autohide,
      // so we must restore it.

      // Restore the group (if any)
      if ( current_mdi == _mdi ) {
         // Docked - restore to last position, docked or floating, since
         // the user would be surprised if he floated a tool-window, closed
         // it, then restored it and it restored docked instead of floating.
         tw_get_restore_info(form_name, RESTORE_LAST, info);
      } else {
         // Floating - restore floating since we are in a floating window
         tw_get_restore_info(form_name, RESTORE_FLOATING, info);
         if ( info.items._length() == 0 ) {
            // Try for anything
            tw_get_restore_info(form_name, RESTORE_LAST, info);
         }
      }
      if ( info.items._length() > 0 ) {

         int i, n = info.items._length();
         for ( i = 0; i < n; ++i ) {
            if ( info.items[i].wid == 0 ) {
               wid = tw_load_form(info.items[i].name);
               wid.p_tile_id = _create_tile_id();
               tw_restore(wid, info.position);
            }
         }

      } else {
         show_tool_window(form_name);
      }

      // if pinning, and not already docked, dock it
      if (toggle_pinned) {
         wid = tw_is_visible(form_name);
         if (tw_is_dockable_window(wid)) {
            if (wid > 0 && !tw_is_docked_window(wid)) {
               dock_tool_window(wid);
            }
         }
      }

      wid = tw_is_visible(form_name);
      if ( wid > 0 ) {
         tw_set_active(wid);
         if( focus_control_name != '' ) {
            ctlwid := wid._find_control(focus_control_name);
            if( ctlwid > 0 ) {
               ctlwid._set_focus();
            }
         }
         result = wid;
      }
   }
   return result;
}

/**
 * Toggle a single tool-window by <code>form_name</code> on/off.
 * If the tool-window is showing, it is closed. If the 
 * tool-window is not showing, it is shown. 
 * 
 * @param form_name 
 */
void tw_toggle(_str form_name)
{
   if( !tw_is_allowed(form_name) ) {
      return;
   }

   int wid = tw_is_visible(form_name);
   if( wid == 0 ) {
      // Show
      show_tool_window(form_name);

   } else if( tw_is_auto_raised(wid) ) {
      // Auto hide
      tw_auto_lower(wid);

   } else {
      // Hide
      hide_tool_window(wid);
   }
}

static int tw_make_docking_flags(bool insertAfter, bool edge)
{
   dFlags := 0;
   dFlags |= insertAfter ? TWD_INSERTAFTER : 0;
   dFlags |= edge ? TWD_EDGE : 0;
   return dFlags;
}

#if 1
static int tw_add_form(int mdi_wid, _str formName, 
                       DockAreaPos apos=DOCKAREAPOS_NONE, 
                       bool edge=false)
{
   int dFlags;
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      switch ( apos ) {
      case DOCKAREAPOS_TOP:
         if ( !(tw_find_info(formName)->flags & TWF_FIXEDHEIGHT) ) {
            wid.p_height = TWDEFAULT_DOCKED_HEIGHT;
         }
         dFlags = tw_make_docking_flags(false, edge);
         tw_new_horizontal_tile(mdi_wid, wid, dFlags);
         break;
      case DOCKAREAPOS_BOTTOM:
         if ( !(tw_find_info(formName)->flags & TWF_FIXEDHEIGHT) ) {
            wid.p_height = TWDEFAULT_DOCKED_HEIGHT;
         }
         dFlags = tw_make_docking_flags(true, edge);
         tw_new_horizontal_tile(mdi_wid, wid, dFlags);
         break;
      case DOCKAREAPOS_LEFT:
         if ( !(tw_find_info(formName)->flags & TWF_FIXEDWIDTH) ) {
            wid.p_width = TWDEFAULT_DOCKED_WIDTH;
         }
         dFlags = tw_make_docking_flags(false, edge);
         tw_new_vertical_tile(mdi_wid, wid, dFlags);
         break;
      case DOCKAREAPOS_RIGHT:
         if ( !(tw_find_info(formName)->flags & TWF_FIXEDWIDTH) ) {
            wid.p_width = TWDEFAULT_DOCKED_WIDTH;
         }
         dFlags = tw_make_docking_flags(true, edge);
         tw_new_vertical_tile(mdi_wid, wid, dFlags);
         break;
      case DOCKAREAPOS_NONE:
      default:
         tw_add(mdi_wid, wid, 0);
      }
   }
   return wid;
}

static int tw_add_form_above(int mdi_wid, _str formName, bool edge=false)
{
   return tw_add_form(mdi_wid, formName, DOCKAREAPOS_TOP, edge);
}

static int tw_add_form_below(int mdi_wid, _str formName, bool edge=false)
{
   return tw_add_form(mdi_wid, formName, DOCKAREAPOS_BOTTOM, edge);
}

static int tw_add_form_left(int mdi_wid, _str formName, bool edge=false)
{
   return tw_add_form(mdi_wid, formName, DOCKAREAPOS_LEFT, edge);
}

static int tw_add_form_right(int mdi_wid, _str formName, bool edge=false)
{
   return tw_add_form(mdi_wid, formName, DOCKAREAPOS_RIGHT, edge);
}
#else
static int tw_add_form(int mdi_wid, _str formName)
{
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      tw_add(mdi_wid, wid, 0);
   }
   return wid;
}

static int tw_add_form_above(int mdi_wid, _str formName, bool edge=false)
{
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      if ( !(tw_find_info(formName)->flags & TWF_FIXEDHEIGHT) ) {
         wid.p_height = TWDEFAULT_DOCKED_HEIGHT;
      }
      int dFlags = tw_make_docking_flags(false, edge);
      tw_new_horizontal_tile(mdi_wid, wid, dFlags);
   }
   return wid;
}

static int tw_add_form_below(int mdi_wid, _str formName, bool edge=false)
{
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      if ( !(tw_find_info(formName)->flags & TWF_FIXEDHEIGHT) ) {
         wid.p_height = TWDEFAULT_DOCKED_HEIGHT;
      }
      int dFlags = tw_make_docking_flags(true, edge);
      tw_new_horizontal_tile(mdi_wid, wid, dFlags);
   }
   return wid;
}

static int tw_add_form_left(int mdi_wid, _str formName, bool edge=false)
{
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      if ( !(tw_find_info(formName)->flags & TWF_FIXEDWIDTH) ) {
         wid.p_width = TWDEFAULT_DOCKED_WIDTH;
      }
      int dFlags = tw_make_docking_flags(false, edge);
      tw_new_vertical_tile(mdi_wid, wid, dFlags);
   }
   return wid;
}

static int tw_add_form_right(int mdi_wid, _str formName, bool edge=false)
{
   wid := tw_reload_form(formName);
   if ( wid > 0 ) {
      if ( !(tw_find_info(formName)->flags & TWF_FIXEDWIDTH) ) {
         wid.p_width = TWDEFAULT_DOCKED_WIDTH;
      }
      int dFlags = tw_make_docking_flags(true, edge);
      tw_new_vertical_tile(mdi_wid, wid, dFlags);
   }
   return wid;
}
#endif

void tw_clear(int mdi_wid=0)
{
   if ( !tw_is_docking_allowed() ) {
      // No docking allowed
      return;
   }

   tw_sanity();

   sc.controls.SaveActiveWindow guard;

   int list[];
   tw_get_registered_windows(list, mdi_wid);
   int i, n = list._length();
   for( i=0; i < n; ++i ) {
      if( list[i] > 0) {
         list[i]._delete_window();
      }
   }

   // Force process events so windows that are deleteLater()ed can be
   // processed. Otherwise nothing is the correct size in the layout.
   cancel := false;
   process_events(cancel);

   if ( 0 == mdi_wid ) {
      // Finally reset the tool-window layout to remove hidden floating mdi
      // windows that contain place-holders for docking, clear user properties.
      _MDIRestoreState(null, WLAYOUT_MAINAREA, RESTORESTATE_POSTCLEANUP);
   } else {
      _MDIWindowRestoreLayout(mdi_wid, null, WLAYOUT_MAINAREA,  0, null);
   }
}

void tw_clear_floating()
{
   int wids[];
   int wid;
   _MDIGetMDIWindowList(wids);
   foreach ( wid in wids ) {
      if ( wid == _mdi ) {
         // Skip main mdi
         continue;
      }
      tw_clear(wid);
   }
}

void tw_reset()
{
   focus_wid := _get_focus();
   if ( 0 == focus_wid && !_mdi.p_child._no_child_windows() ) {
      // Default to _mdi.p_child if no previous focus window
      focus_wid = _mdi.p_child;
   }

   tw_clear();

   ToolWindowFeatures features;

   if ( _tbFullScreenQMode() ) {
      _common_fullscreen_settings();
      if ( !_tbDebugQMode() ) {
         return;
      }
   }

   int wid;
   int mdi_wid = _mdi;

   // Bottom
   if ( _tbDebugQMode() ) {

      // Tabgroup : Autos, Locals, Members
      tw_add_form_below(mdi_wid, '_tbdebug_members_form', true);
      tw_add_form(mdi_wid, '_tbdebug_locals_form');
      awid := tw_add_form(mdi_wid, '_tbdebug_autovars_form');
      // Make the Autos tab active
      tw_set_active(awid);

      // Tabgroup : Watches
      tw_add_form_right(mdi_wid, '_tbdebug_watches_form');

      tw_set_active(awid);

   } else {

      awid := 0;

      // File Tabs
      if ( features.testForm('_tbbufftabs_form') && def_tbreset_with_file_tabs ) {
         tw_add_form_below(mdi_wid, '_tbbufftabs_form', true);
      }
      // Tabgroup : Search Results, Preview, References, Build, Message List, Terminal, Output
      // Preferred active : Build, or Output
      if ( features.testForm('_tboutputwin_form') ) {
         awid = tw_add_form(mdi_wid, '_tboutputwin_form', 
                            awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                            false);
      }
      if ( features.testForm('_tbterminal_form') ) {
         awid = tw_add_form(mdi_wid, '_tbterminal_form',
                            awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                            false);
      }
      if ( features.testForm('_tbmessages_browser_form') ) {
         int w = tw_add_form(mdi_wid, '_tbmessages_browser_form',
                             awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                             false);
         awid = awid > 0 ? awid : w;
      }
      if ( features.testForm('_tbshell_form') ) {
         awid = tw_add_form(mdi_wid, '_tbshell_form',
                            awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                            false);
      }
      if ( features.testForm('_tbtagrefs_form') ) {
         int w = tw_add_form(mdi_wid, '_tbtagrefs_form',
                             awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                             false);
         awid = awid > 0 ? awid : w;
      }
      if ( features.testForm('_tbtagwin_form') ) {
         int w = tw_add_form(mdi_wid, '_tbtagwin_form',
                             awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                             false);
         awid = awid > 0 ? awid : w;
      }
      if ( features.testForm('_tbsearch_form') ) {
         int w = tw_add_form(mdi_wid, '_tbsearch_form',
                             awid == 0 ? DOCKAREAPOS_BOTTOM : DOCKAREAPOS_NONE, 
                             false);
         awid = awid > 0 ? awid : w;
      }

      if ( _isMac() && _default_option(VSOPTION_MAC_USE_SCROLL_PERFORMANCE_HACK) ) {
         // 2020-03-10 - rb
         // Fix/hack for paint performance issues since macOS Catalina (10.15):
         // The fix/hack we put in prevented the first window inserted from being painted
         // during a reset if it was not also the active window.
         // Theory: Catalina posts a message to the queue that never gets processed because 
         // the window is no longer visible.
         // Force process events.
         cancel := false;
         process_events(cancel);
      }

      if ( awid > 0 ) {
         tw_set_active(awid);
      }

   }

   // Left
   if ( _tbDebugQMode() ) {

      // Stack
      tw_add_form_left(mdi_wid, '_tbdebug_stack_form', true);
      // Tabgroup : Breakpoints, Exceptions
      tw_add_form_below(mdi_wid, '_tbdebug_exceptions_form');
      awid := tw_add_form(mdi_wid, '_tbdebug_breakpoints_form');

      tw_set_active(awid);

   } else {

      awid := 0;

      // Tabgroup : Projects, Defs, Class, Symbols, Open
      // Preferred active : Projects, or Defs
      if ( features.testForm('_tbopen_form') ) {
         int w = tw_add_form(mdi_wid, '_tbopen_form', 
                             awid == 0 ? DOCKAREAPOS_LEFT : DOCKAREAPOS_NONE, 
                             awid == 0);
         awid = awid > 0 ? awid : w;
      }
      if ( features.testForm('_tbcbrowser_form') ) {
         int w = tw_add_form(mdi_wid, '_tbcbrowser_form', 
                             awid == 0 ? DOCKAREAPOS_LEFT : DOCKAREAPOS_NONE, 
                             awid == 0);
         awid = awid > 0 ? awid : w;
      }
      if ( features.testForm('_tbclass_form') ) {
         int w = tw_add_form(mdi_wid, '_tbclass_form', 
                             awid == 0 ? DOCKAREAPOS_LEFT : DOCKAREAPOS_NONE, 
                             awid == 0);
         awid = awid > awid ? awid : w;
      }
      if ( features.testForm('_tbproctree_form') ) {
         awid = tw_add_form(mdi_wid, '_tbproctree_form', 
                            awid == 0 ? DOCKAREAPOS_LEFT : DOCKAREAPOS_NONE, 
                            awid == 0);
      }
      if ( features.testForm('_tbprojects_form') ) {
         awid = tw_add_form(mdi_wid, '_tbprojects_form', 
                            awid == 0 ? DOCKAREAPOS_LEFT : DOCKAREAPOS_NONE, 
                            awid == 0);
      }

      if ( _isMac() && _default_option(VSOPTION_MAC_USE_SCROLL_PERFORMANCE_HACK) ) {
         // 2020-03-10 - rb
         // Fix/hack for paint performance issues since macOS Catalina (10.15):
         // The fix/hack we put in prevented the first window inserted from being painted
         // during a reset if it was not also the active window.
         // Theory: Catalina posts a message to the queue that never gets processed because 
         // the window is no longer visible.
         // Force process events.
         cancel := false;
         process_events(cancel);
      }

      if ( awid > 0 ) {
         tw_set_active(awid);
      }

   }
   if( focus_wid != 0 && _iswindow_valid(focus_wid) ) {
      //say('tw_reset : focus_wid = 'focus_wid.p_buf_name);
      focus_wid._set_focus();
   }
}

void tw_reset_all()
{
   g_toolwindowtab._makeempty();
   tw_reset();
}

/**
 * Show/hide all floating tool-windows. 
 * 
 * @param visible 
 */
void tw_all_floating_set_visible(bool visible)
{
   focus_wid := _get_focus();
   int wids[];
   _MDIGetMDIWindowList(wids, true);
   int wid;
   foreach ( wid in wids ) {
      //say('tw_all_floating_set_visible : wid='wid'  p_visible='wid.p_visible'  visible='visible);
      //say('tw_all_floating_set_visible : _MDIWindowHasMDIArea='_MDIWindowHasMDIArea(wid));
      //say('tw_all_floating_set_visible : tw_current_window='tw_current_window(wid));
      // Do not set visibility if: 
      // 1. Main mdi-window.
      // 2. Visibility unchanged.
      // 3. Empty mdi-window.
      if ( wid != _mdi && wid.p_visible != visible
           && !_MDIWindowHasMDIArea(wid) && tw_current_window(wid) != 0 ) {

         wid.p_visible = visible;
         //wid._ShowWindow(visible ? SW_SHOW : SW_HIDE);
      }
   }
   if( focus_wid != 0 ) {
      focus_wid._set_focus();
   }
}

int _OnUpdate_float_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   if ( !tw_is_floating(target_wid) ) {
      return MF_ENABLED;
   }
   if( tw_next_window(target_wid, 'N', false) != target_wid ) {
      return MF_ENABLED;
   }
   if ( _mdi.p_child && _MDIFromChild(_mdi.p_child) == _MDIFromChild(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}
_command void float_tool_window(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   //say('float_tool_window : wid='wid'='wid.p_name);
   if ( wid.p_isToolWindow ) {
      wid.tw_save_state(auto state, false);
      if ( !tw_is_floating(wid) && !tw_is_auto(wid) ) {
         tw_restore(wid, RESTORE_FLOATING);
      } else {
         if ( tw_is_auto(wid) ) {
            tw_remove(wid);
         }
         // Simple float
         tw_float(wid);
         // Assume user wants new instance centered on mdi-window they came from
         tw_center_mdi_window(wid);
      }
      wid.tw_restore_state(state, false);
   }
}

int _OnUpdate_dock_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* twinfo = tw_find_info(target_wid.p_name);
   if ( !twinfo || 0 != (twinfo->flags & TWF_NO_DOCKING) ) {
      return MF_GRAYED;
   }
   if ( tw_is_floating(target_wid) ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}
_command void dock_tool_window(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   //say('float_tool_window : wid='wid'='wid.p_name);
   if ( wid.p_isToolWindow ) {
      wid.tw_save_state(auto state, false);
      if ( tw_is_auto(wid) ) {
         tw_remove(wid);
      }
      tw_restore(wid, RESTORE_DOCKED);
      wid.tw_restore_state(state, false);
   }
}

void tw_hide_window(int wid)
{
   if ( wid > 0 && wid.p_isToolWindow ) {

      state := null;
      wid.tw_save_state(state, true);
      if ( state != null ) {
         _SetDialogInfoHt("twState.":+wid.p_name, state, _mdi);
      }

      // Some OEMs rely on ON_CLOSE being called in order to save data
      // associated with their tool window, so call it.
      // IMPORTANT:
      // We use _event_handler() to check for the existence of an
      // ON_CLOSE event handler because the default handler will
      // destroy the form. We do not want that to happen if we can
      // avoid it, since WE want to be the one to dispose of the
      // form.
      // IMPORTANT:
      // The default on_close event handler, _toolwindow_etab2.on_close, eventually
      // calls this function, so DO NOT attempt to call it or you will infinite recurse.
      // The _toolwindow_etab2.on_close handler is only called when the user hits the 'X' 
      // on the tool window.
      _str handler = wid._event_handler(on_close);
      int toolwindowEtab2OnCloseIndex = eventtab_index(defeventtab _toolwindow_etab2, defeventtab _toolwindow_etab2, event2index(on_close));
      if ( handler!=0 && handler != toolwindowEtab2OnCloseIndex ) {
         // Window ids are reused a lot, so it is not enough to check the wid
         form_name := wid.p_name;
         wid.call_event(false, wid, on_close, 'w');
         if( !_iswindow_valid(wid) || wid.p_name != form_name ) {
            // The form's on_close handler deleted the window out from under us!
            return;
         }
      }

      tw_delete(wid);
   }
}

_command void hide_tool_window(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   tw_hide_window(wid);
}

int _OnUpdate_hide_tool_window_all(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* twinfo = tw_find_info(target_wid.p_name);
   if ( !twinfo || 0 != (twinfo->flags & TWF_NO_DOCKING) ) {
      return MF_GRAYED;
   }
   int next = tw_next_window(target_wid, '1', false);
   if ( next > 0 && next != target_wid ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void hide_tool_window_all(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   if ( wid.p_isToolWindow ) {
      tw_hide_tabgroup_window(wid);
   }
}

int _OnUpdate_hide_tool_window_other(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* twinfo = tw_find_info(target_wid.p_name);
   if ( !twinfo || 0 != (twinfo->flags & TWF_NO_DOCKING) ) {
      return MF_GRAYED;
   }
   int next = tw_next_window(target_wid, '1', false);
   if ( next > 0 && next != target_wid ) {
      return MF_ENABLED;
   }
   return MF_GRAYED;
}

_command void hide_tool_window_other(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   if ( wid.p_isToolWindow ) {
      hide_others := true;
      tw_hide_tabgroup_window(wid, hide_others);
   }
}

static int _tw_duplicate_form(_str form_name, int width=-1, int height=-1)
{
   ToolWindowInfo* info = tw_find_info(form_name);
   if ( !info ) {
      return VSRC_FORM_NOT_FOUND;
   }
   if ( !(info->flags & TWF_SUPPORTS_MULTIPLE) ) {

      // If there is no visible or auto-hide instances of the tool-window 
      // anywhere, then no harm no foul. Just load it as normal.
      int wids[];
      tw_get_registered_windows(wids);
      int wid;
      foreach ( wid in wids ) {
         if ( wid.p_name == form_name 
              && (tw_is_visible_window(wid) || tw_is_auto(wid)) ) {

            return VSRC_TOOL_WINDOW_DOES_NOT_SUPPORT_DUPLICATES;
         }
      }
      // Fall thru
      // No visible or auto-hide instances, so treat as a regular show.
      // The only difference is that we force it Floating.
   }

   wid := tw_load_form(form_name);
   wid.p_tile_id = _create_tile_id();
   if ( width != -1 ) {
      wid.p_width = width;
   }
   if ( height != -1 ) {
      wid.p_height = height;
   }
   tw_float(wid);

   // Assume user wants new instance centered on mdi-window they came from
   tw_center_mdi_window(wid);

   return wid;
}

int _OnUpdate_duplicate_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* info = tw_find_info(target_wid.p_name);
   if( !info || !(info->flags & TWF_SUPPORTS_MULTIPLE) ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}
_command void duplicate_tool_window(int from_wid=0)
{
   from_wid = from_wid == 0 ? p_window_id : from_wid;
   if ( !from_wid.p_isToolWindow ) {
      return;
   }
   tw_sanity();
   form_name := from_wid.p_name;
   result := _tw_duplicate_form(form_name, from_wid.p_width, from_wid.p_height);
   if ( result < 0 ) {
      // Error
      switch ( result ) {
      case VSRC_FORM_NOT_FOUND:
         _message_box(get_message(result, '', form_name));
         break;
      case VSRC_TOOL_WINDOW_DOES_NOT_SUPPORT_DUPLICATES:
         _message_box(get_message(result, form_name));
         break;
      }
      return;
   }
}

void _tw_get_tabgroup(int wid, int (&group)[])
{
   group._makeempty();

   if ( !wid || !_iswindow_valid(wid) || !wid.p_isToolWindow ) {
      return;
   }
   // Fetch tabgroup wids in order
   int first_wid = tw_next_window(wid, 'F', false);
   int next_wid = first_wid;
   do {
      group[group._length()] = next_wid;
      next_wid = tw_next_window(next_wid, '1', false);
   } while ( next_wid > 0 && next_wid != first_wid );
}

/**
 * Center the floating mdi-window parent of <code>wid</code> to
 * specified window <code>to_wid</code>. Set
 * <code>to_wid=0</code> to center on current mdi-window. 
 * 
 * @param wid 
 * @param to_wid 
 */
void tw_center_mdi_window(int wid, int to_wid=0)
{
   int mdi_wid = _MDIFromChild(wid);
   if ( mdi_wid != _mdi ) {
      to_wid = to_wid > 0 ? to_wid : _MDICurrent();
      if ( mdi_wid != _MDIFromChild(to_wid) ) {
         mdi_wid._center_window(to_wid);
      }
   }
}


static bool maybe_hide_tool_window(int wid)
{
   if (def_toolwindow_options & TWOPTION_MENU_TOGGLE_SHOW_HIDE) {
      return true;
   }
   return false;

   /*
   if (def_toolwindow_options & TWOPTION_MENU_ALWAYS_SHOW) {
      return false;
   }

   orig_wid := p_window_id;
   tw_name := wid.p_caption;

   choice := textBoxDialog("SlickEdit", // Form caption
                           0,                // Flags
                           0,                // Use default textbox width
                           "",               // Help item
                           "Hide "tw_name",Show "tw_name"\tThe "tw_name" tool window is already active. ",
                           "",               // Retrieve Name
                           "-CHECKBOX Do not show this option again.");
   p_window_id = orig_wid;

   if (_param1 == 1) {
      if (choice == 1) {
         def_toolwindow_options &= ~TWOPTION_MENU_ALWAYS_SHOW;
         def_toolwindow_options |= TWOPTION_MENU_TOGGLE_SHOW_HIDE;
      } else {
         def_toolwindow_options &= ~TWOPTION_MENU_TOGGLE_SHOW_HIDE;
         def_toolwindow_options |= TWOPTION_MENU_ALWAYS_SHOW;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return (choice == IDYES); 
   */ 
}


/**
 * Show tool-window with name <code>form_name</code>. If 
 * tool-window is already showing, then it is set active. See 
 * <code>cmdline</code> for more options. 
 * 
 * @param cmdline A string in the format: [<i>option</i>] <i>form_name</i>
 * 
 * <i>option</i> may be one of following:
 * 
 * <dl>
 * <dt>-new</dt><dd>If tool-window supports duplicates (or has 
 * not been shown yet), then a new floating instance of 
 * tool-window is shown.</dd> 
 * <dt>-current-mdi</dt><dd>Attempt to show tool-window 
 * for current mdi window. If tool-window is already 
 * docked to current mdi window, then it is activated. If 
 * tool-window is floating (no mdiarea), then it is 
 * activated. Otherwise, a new floating instance is shown.</dd> 
 * <dt>-quiet</dt><dd>Do not display errors to user. Check 
 * for return value < 0 on error.</dd> 
 * </dl>
 *
 * @return Window id of tool-window on success, otherwise <0 
 *         error code.
 */
_command int show_tool_window(_str cmdline='') name_info(FORM_ARG',')
{
   options := "";
   form_name := strip_options(strip(cmdline), options);

   maybe_hide  := false;
   quiet := false;
   new_instance := false;
   current_mdi := false;
   tw_wid := 0;

   opt := "";
   for ( ;; ) {
      parse options with opt options;
      if ( opt == '' ) {
         break;
      }
      parse opt with opt '=' auto opt_value;
      switch ( upcase(opt) ) {
      case '-Q':
         quiet = true;
         break;
      case '+NEW':
      case '-NEW':
         new_instance = true;
         current_mdi = false;
         break;
      case '+HIDE':
      case '-HIDE':
         maybe_hide = true;
         break;
      case '+CURRENT-MDI':
      case '-CURRENT-MDI':
         current_mdi = true;
         new_instance = false;
         break;
      case '+TOOLWID':
      case '-TOOLWID':
         if (isinteger(opt_value)) {
            tw_wid = (int)opt_value;
            if (!_iswindow_valid(tw_wid)) {
               tw_wid = 0;
            }
         }
         break;
      }
   }

   tw_sanity();
   ToolWindowInfo* info = tw_find_info(form_name);
   if( !info ) {
      if ( !quiet ) {
         _message_box(get_message(VSRC_FORM_NOT_FOUND, '', form_name));
      }
      return VSRC_FORM_NOT_FOUND;
   }

   if ( !tw_is_allowed(form_name, info) ) {
      popup_message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   dup_supported := 0 != (info->flags & TWF_SUPPORTS_MULTIPLE);

   wid := 0;

   // special case code for File Tabs tool window, to give the user a chance
   // to self-correct and bring up Document Tabs instead.
   // Never prompt if we are in restore or opening a workspace.
   if (form_name == "_tbbufftabs_form" && def_one_file != "") {
      if (!_in_batch_open_or_close_files()) {
         wid = _find_formobj(form_name, 'n');
         if (!wid) {
            if (!_no_child_windows()) {
               editorctl_wid := _MDIGetActiveMDIChild();
               if (_iswindow_valid(editorctl_wid) && editorctl_wid._isEditorCtl()) {
                  if (editorctl_wid.p_window_state == 'M') {
                     mbrc := _message_box("The File Tabs tool window is deprecated.\n\nDo you want to enable Document Tabs?",
                                          "SlickEdit", 
                                          MB_YESNOCANCEL|MB_ICONQUESTION);
                     if (mbrc == IDYES) {
                        zoom_window();
                        return 0;
                     } else if (mbrc == IDCANCEL) {
                        return COMMAND_CANCELLED_RC;
                     }
                  }
               }
            }
         }
      }
   }

   if ( new_instance ) {

      result := _tw_duplicate_form(form_name);
      if ( result < 0 ) {
         // Error
         if ( !quiet ) {
            switch ( result ) {
            case VSRC_TOOL_WINDOW_DOES_NOT_SUPPORT_DUPLICATES:
               _message_box(get_message(result, form_name));
               break;
            default:
               _message_box(get_message(result));
            }
         }
         return result;
      }
      wid = result;

   } else if ( current_mdi ) {

      if ( dup_supported ) {
         wid = tw_is_visible(form_name, _MDICurrent());
      } else {
         wid = tw_is_visible(form_name, 0);
      }
      if ( wid > 0 ) {
         if (maybe_hide && maybe_hide_tool_window(wid)) {
            tw_hide_window(wid);
            return 0;
         }
         tw_set_active(wid);
         wid._set_foreground_window();
         return wid;
      }

      // Check for auto-hide window
      if ( dup_supported ) {
         wid = tw_is_auto_form(form_name, _MDICurrent());
      } else {
         wid = tw_is_auto_form(form_name, -1);
      }
      if ( wid > 0 ) {
         if (maybe_hide && maybe_hide_tool_window(wid)) {
            tw_hide_window(wid);
            return 0;
         }
         tw_auto_raise(wid);
         wid.call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
         return wid;
      }

      // Check for undocked window
      wid = tw_is_undocked(form_name);
      if ( wid > 0 ) {
         if (maybe_hide && maybe_hide_tool_window(wid)) {
            tw_hide_window(wid);
            return 0;
         }
         tw_set_active(wid);
         // rb - If we find ourselves in need of raising certain existing tool-windows
         // in future, then we should add a -RAISE switch. Other commands/functions 
         // may not want an existing instance raised (e.g. Activate Preview in Defs 
         // tool-window).
         //wid._set_foreground_window();
         return wid;
      }

      wid = tw_load_form(form_name);
      wid.p_tile_id = _create_tile_id();
      // TODO: Need RESTORE_UNDOCKED option to restore to last,
      // floating window that does not have an mdiarea.
      //tw_float(wid);
      //tw_restore(wid, RESTORE_FLOATING);
      RestoreGroupInfo rinfo;
      tw_get_restore_info(form_name, RESTORE_FLOATING, rinfo);
      // Restore case:
      // Restore group mdi_wid matches current mdi wid, 
      // Restore group mdi_wid has no mdi-area (floating mdi with only tool-windows).
      //
      // Float case: everything else.
      if (tw_wid > 0) {

         tw_add(tw_wid, wid, 0);

      } else if ( rinfo.items._length() > 0
           && (rinfo.mdi_wid == _MDICurrent() || !_MDIWindowHasMDIArea(rinfo.mdi_wid)) ) {

         tw_restore(wid, RESTORE_FLOATING);

      } else {

         tw_float(wid);
         // Assume user wants new instance centered on mdi-window they came from
         tw_center_mdi_window(wid);
      }

   } else {

      //wid = tw_is_visible(form_name, 0);
      wid = tw_find_form(form_name);
      if ( wid > 0 && tw_is_visible_window(wid) ) {
         if (maybe_hide && maybe_hide_tool_window(wid)) {
            tw_hide_window(wid);
            return 0;
         }
         tw_set_active(wid);
         wid.call_event(wid, ON_GOT_FOCUS, 'W');
         return wid;
      }

      // Check for autohide window
      wid = tw_is_auto_form(form_name, -1);
      if ( wid > 0 ) {
         if (maybe_hide && maybe_hide_tool_window(wid)) {
            tw_hide_window(wid);
            return 0;
         }
         tw_auto_raise(wid);
         wid.call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
         return wid;
      }

      wid = tw_reload_form(form_name);
      tw_restore(wid, RESTORE_LAST);
   }

   if ( wid > 0 ) {
      // If we got here, then a new instance was loaded

      // Set active before we do anything else since it also makes it visible
      tw_set_active(wid);
      // Calling on_create/on_load/on_resize now allows functions
      // that set focus, like activate_tool_window(), to work.
      restore_focus := false;
      wid._on_create_tool_window(restore_focus);
   }

   return wid;
}
int _OnUpdate_show_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   // get the form name from the command
   parse command with . command;
   form_name := strip_options(strip(command), auto options);
   if (form_name == "") {
      return MF_ENABLED;
   }

   // check if form is already visible, auto-hidden, or undocked.
   wid := tw_is_visible(form_name, _MDICurrent());
   if ( !wid ) {
      wid = tw_is_auto_form(form_name, _MDICurrent());
   }
   if ( !wid ) {
      wid = tw_is_undocked(form_name);
   }

   // If the tool window is not docked, just return enabled
   if (!wid) {
      return MF_ENABLED;
   }

   // if this is the same form we are docking with, gray it out
   if (target_wid && name_eq(wid.p_name, target_wid.p_name)) {
      return MF_GRAYED|MF_CHECKED;
   }

   // otherwise, check the form to indicate that it is docked
   return MF_ENABLED|MF_CHECKED;
}


/**
 * Activate the tool-window with name <code>form_name</code> and
 * return the window id. If the tool-window is tab-linked, then 
 * that tab is made active. If the tool-window is auto-hide, 
 * then it is raised. 
 *
 * <p>
 *
 * If <code>set_focus=true</code>, then focus is set to the 
 * tool-window or to control with name 
 * <code>focus_control_name</code> if not ''. 
 *
 * <p>
 *
 * Set <code>restore_group=true</code> to restore all other tabs
 * in the same tabgroup.
 * 
 * @param form_name 
 * @param set_focus 
 * @param focus_control 
 * @param restore_group 
 * 
 * @return Window id of tool-window; 0 if not found. 
 */
int activate_tool_window(_str form_name, bool set_focus=true, _str focus_control_name='', bool restore_group=false)
{
   // RGH - 4/20/06
   // Bypassing this check for some toolwindows in Eclipse
   if( !isEclipsePlugin()
       || !(form_name :== '_tbfind_form'         || 
            form_name :== '_tbregex_form'        || 
            form_name :== '_tbfind_symbol_form'  || 
            form_name :== '_tbclipboard_form'    || 
            form_name :== '_tbnotification_form' || 
            form_name :== '_tbsymbol_args_form'  || 
            form_name :== '_tbsymbol_props_form') ) {

      if ( !tw_is_allowed(form_name) ) {
         return 0;
      }
   }
   focus_wid := _get_focus();
   int wid = tw_show_tabgroup(form_name, restore_group);
   if ( wid > 0 ) {

      if( set_focus ) {
         int focus_to_wid = (focus_control_name != '') ? wid._find_control(focus_control_name) : 0;
         if ( focus_to_wid > 0 ) {
            // focus_to_wid.on_got_focus() will never be called if focus_to_wid already has focus
            if ( _get_focus() != focus_to_wid ) {
               focus_to_wid._set_focus();
            } else {
               focus_to_wid.call_event(focus_to_wid, ON_GOT_FOCUS, 'w');
            }
         } else {
            wid._set_focus();
         }
      } else {
         if ( _iswindow_valid(focus_wid) ) {
            //focus_wid._set_focus();
         }
      }
   }
   return wid;
}

// "Dockable" menu item on tool-window context menu
int _OnUpdate_toggle_dockable_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if (!target_wid) return MF_GRAYED;
   int formwid = target_wid.p_active_form;
   if ( !formwid.p_isToolWindow ) {
      return MF_GRAYED;
   }

   tw_sanity();
   form_name := formwid.p_name;
   ToolWindowInfo* twinfo = tw_find_info(form_name);
   if( !twinfo ) {
      return MF_GRAYED;
   }

   allow_docking := tw_is_docking_allowed();
   if( allow_docking ) {
      allow_docking = 0 == ( twinfo->flags & TWF_NO_DOCKING );
   }
   if( !tw_is_floating(formwid) || allow_docking ) {
      // Dockable.
      // Regardless of whether g_toolwindowtab says this tool-window is
      // dockable, it is in fact docked, so put a check on it.
      return (MF_ENABLED | MF_CHECKED);
   } else {
      // Floating or docking not allowed
      return (MF_ENABLED | MF_UNCHECKED);
   }
}

/**
 * Toggle dockability on tool-window.
 * 
 * @param wid (optional). Window id of tool-window. Uses the 
 *            active form if not specified.
 */
_command void toggle_dockable_tool_window(int wid=0)
{
   if ( isEclipsePlugin() ) {
      return;
   }

   if( wid == 0 ) {
      // Use active form
      wid = p_active_form;
   }
   if ( !wid.p_isToolWindow ) {
      return;
   }

   tw_sanity();
   form_name := wid.p_name;
   ToolWindowInfo* twinfo = tw_find_info(form_name);
   if( !twinfo ) {
      return;
   }

   allow_docking := tw_is_docking_allowed();
   if( allow_docking ) {
      allow_docking = 0 == ( twinfo->flags & TWF_NO_DOCKING );
   }
   // Toggle
   allow_docking = !allow_docking;
   was_docked := 0 != tw_dock_area(wid);
   if( allow_docking ) {
      twinfo->flags &= ~(TWF_NO_DOCKING);
      tw_set_flag(wid, TWF_NO_DOCKING, false);
   } else {
      twinfo->flags |= TWF_NO_DOCKING;
      tw_set_flag(wid, TWF_NO_DOCKING);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   if( (was_docked || tw_is_auto(wid)) && !allow_docking ) {
      if ( tw_is_auto(wid) ) {
         tw_remove(wid);
      }
      tw_float(wid);
      // Assume user wants new instance centered on mdi-window they came from
      tw_center_mdi_window(wid);
   }
}

bool tw_is_supported_mode(_str form_name, ToolWindowInfo* twinfo=null)
{
   twinfo = twinfo == null ? tw_find_info(form_name) : twinfo;
   if ( twinfo && !isinteger(twinfo->rflags) ) twinfo->rflags=0;
   if ( !twinfo || !testFlag(twinfo->rflags, TB_REQUIRE_DEBUGGING) ) {
      return true;
   }
   if ( !_haveDebugging() ) {
      return false;
   }
   session_id := dbg_get_current_session();
   int ToolbarSupported_index = find_index('_'dbg_get_callback_name(session_id)'_ToolbarSupported',PROC_TYPE);
   if ( twinfo->flags & TWF_WHEN_DEBUGGER_STARTED_ONLY ) {
      if ( !_tbDebugQMode() ) {
         return false;
      }
      if ( ToolbarSupported_index &&
          !call_index(form_name, ToolbarSupported_index) ) {
         return false;
      }
   }
   if ( twinfo->flags & TWF_WHEN_DEBUGGER_SUPPORTED_ONLY ) {
      if ( ToolbarSupported_index &&
          !call_index(form_name, ToolbarSupported_index) ) {
         return false;
      }
   }
   return true;
}

bool tw_is_disabled_tool_window(_str form_name, ToolWindowInfo* twinfo)
{
   //if( form_name == '_tbannotations_browser_form' ) {
   //   return true;
   //}
   return false;
}

void tw_append_tool_windows_to_menu(int menu_handle, bool list_debug, int clicked_wid=0)
{
   ToolWindowFeatures features;

   // Debug mode mask
   mask := 0;
   if ( _tbDebugQMode() ) {
      mask = TWF_WHEN_DEBUGGER_STARTED_ONLY | TWF_LIST_WITH_DEBUG_TOOLWINDOWS;
   } else {
      mask = TWF_WHEN_DEBUGGER_STARTED_ONLY;
   }

   // Append tool-windows
   current_mdi_arg := "-current-mdi ";
   if (clicked_wid > 0) {
      current_mdi_arg :+= "-toolwid=";
      current_mdi_arg :+= clicked_wid;
      current_mdi_arg :+= " ";
   }

   // Finagle a _sort() on an array of structs.
   // Items will be sorted into twitem[].
   _str twitem[];
   _str form_name;
   ToolWindowInfo twinfo;
   foreach ( form_name => twinfo in g_toolwindowtab ) {

      display := false;
      if (!isinteger(twinfo.rflags)) twinfo.rflags = 0;
      if ( features.testFlags(twinfo.rflags) ) {
         if( list_debug ) {
            display = ( 0 != (twinfo.flags & mask) && tw_is_supported_mode(form_name, &twinfo) );
         } else {
            display = ( 0 == (twinfo.flags & mask) );
         }
      }
      if ( display ) {

         wid := 0;
         dup_supported := 0 != (twinfo.flags & TWF_SUPPORTS_MULTIPLE);
         if ( dup_supported ) {
            wid = tw_is_visible(form_name, _MDICurrent());
         } else {
            wid = tw_is_visible(form_name, 0);
         }

         // Check for auto-hide window
         if ( !wid ) {
            if ( dup_supported ) {
               wid = tw_is_auto_form(form_name, _MDICurrent());
            } else {
               wid = tw_is_auto_form(form_name, -1);
            }
         }

         // Check for undocked window
         if ( !wid ) {
            wid = tw_is_undocked(form_name);
         }
         // item = caption;enabled;command
         // Note that caption is padded to 30 characters so that sorting
         // is consistent between captions with similar prefixes (e.g. 'FTP'
         // and 'FTP Client').
         item := "";
         enabled := MF_ENABLED;
         if ( wid > 0 ) {
            enabled |= MF_CHECKED;
            hide_arg := (def_toolwindow_options & TWOPTION_MENU_TOGGLE_SHOW_HIDE)? "-hide ":"";
            caption := substr(wid.p_caption, 1, max(30, length(wid.p_caption)));
            item = caption';'(enabled)';':+'show_tool_window ':+hide_arg:+current_mdi_arg:+form_name;
         } else {
            index := find_index(form_name, oi2type(OI_FORM));
            if (index != 0) {
               if( tw_is_disabled_tool_window(form_name, &twinfo) ) {
                  enabled = MF_GRAYED;
               }
               caption := substr(index.p_caption, 1, max(30, length(index.p_caption)));
               item = caption';'(enabled)';':+'show_tool_window ':+current_mdi_arg:+form_name;
            }
         }

         if ( item != '' ) {
            twitem :+= item;
         }
      }
   }

   // Insert sorted tool-windows
   twitem._sort('i');
   n := twitem._length();
   for ( i:=0; i < n; ++i ) {
      parse twitem[i] with auto caption';'auto mf_flags';'auto cmd;
      _menu_insert(menu_handle, -1, (int)mf_flags, strip(caption), cmd);
   }
}

void _on_tool_tab_context_menu(int clicked_wid, _str clicked_caption, int current_wid, _str current_caption, int NofTabs)
{
   //say('_on_tool_tab_context_menu : clicked='clicked_caption'  current='current_caption);

   if ( !clicked_wid.p_isToolWindow ) {
      return;
   }
   ToolWindowInfo* info = tw_find_info(clicked_wid.p_name);
   if ( !info ) {
      return;
   }
   next := tw_next_window(clicked_wid, '1', false);

   // Build a menu from scratch
   index := find_index("_temp_tool_tab_menu", oi2type(OI_MENU));
   if( index ) {
      delete_name(index);
   }
   index = insert_name("_temp_tool_tab_menu", oi2type(OI_MENU));
   _menu_insert(index, -1, 0, 'Dockable', 'toggle_dockable_tool_window 'clicked_wid);
   _menu_insert(index, -1, 0, 'Float', 'float_tool_window 'clicked_wid);
   _menu_insert(index, -1, 0, 'Dock', 'dock_tool_window 'clicked_wid);
   _menu_insert(index, -1, 0, 'Hide', 'hide_tool_window 'clicked_wid);
   if ( next > 0 && next != clicked_wid ) {
      _menu_insert(index, -1, 0, 'Hide All', 'hide_tool_window_all 'clicked_wid);
      _menu_insert(index, -1, 0, 'Hide Others', 'hide_tool_window_other 'clicked_wid);
   }
   //_menu_insert(index, -1, MF_ENABLED, '-');
   _menu_insert(index, -1, 0, 'Duplicate', 'duplicate_tool_window 'clicked_wid);

   _menu_insert(index, -1, MF_ENABLED, '-');
   if ( _tbDebugQMode() ) {
      tw_append_tool_windows_to_menu(index, true, clicked_wid);
      _menu_insert(index, -1, MF_ENABLED, '-');
   }
   tw_append_tool_windows_to_menu(index, false, clicked_wid);

   menu_handle := p_active_form._menu_load(index, 'P');

   _KillToolButtonTimer();

   // Show the menu
   x := 100;
   y := 100;
   _lxy2dxy(SM_TWIP, x, y);
   x = mou_last_x('D') - x;
   y = mou_last_y('D') - y;
   flags := (VPM_LEFTALIGN | VPM_RIGHTBUTTON);
   clicked_wid._set_focus();
   //_menu_set_bindings(menu_handle);
   //_menu_remove_unsupported_commands(menu_handle);
   status := _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
#ifdef not_finished
   // set the focus back
   if (_mdi.p_child._no_child_windows()==0) {
      _mdi.p_child._set_focus();
   }
#endif
}

/**
 * Insert tool-window list into menu <code>menu_handle</code>.
 * 
 * @param menu_handle
 * @param no_child_windows
 */
void _init_menu_tool_windows(int menu_handle, int no_child_windows)
{
   //
   // View>Tool Windows menu
   //

   int submenu_handle, mpos;
   int status = _menu_find(menu_handle, 'customize_tool_windows', submenu_handle,mpos, 'm');
   if ( status != 0 ) {
      // Not in the View>Tool Windows menu
      return;
   }

   // Delete everything after 'customize_tool_windows' command
   ++mpos;
   status = 0;
   while( status == 0 ) {
      status = _menu_delete(submenu_handle, mpos);
   }

   _menu_insert(submenu_handle, -1, MF_ENABLED, '-');
   if ( _tbDebugQMode() ) {
      tw_append_tool_windows_to_menu(submenu_handle, true);
      _menu_insert(submenu_handle, -1, MF_ENABLED, '-');
   }
   tw_append_tool_windows_to_menu(submenu_handle, false);
}

void _on_tool_tab_left_click()
{
   if ( !p_isToolWindow ) {
      return;
   }
   call_event(p_window_id, ON_GOT_FOCUS, 'W');
   //say('_on_tool_tab_left_click : wid='p_name);
}

void _on_tool_tab_middle_click()
{
   if ( !p_isToolWindow ) {
      return;
   }
   //say('_on_tool_tab_middle_click : wid='p_name);
}

void _on_tool_tab_double_click()
{
   if ( !p_isToolWindow ) {
      return;
   }
   //say('_on_tool_tab_double_click : wid='p_name);
}

void _on_tool_action(_str id)
{
   if ( !p_isToolWindow ) {
      return;
   }
   //say('_on_tool_action : wid='p_name', id='id);
   switch ( id ) {
   case 'MENU':
      _on_tool_tab_context_menu(p_window_id, p_window_id.p_caption, p_window_id, p_window_id.p_caption, 0);
      break;
#if 0
   case 'DUPLICATE':
      duplicate_tool_window(p_window_id);
      break;
#endif
   case 'UNPIN':
      autohide_tool_window(p_window_id);
      break;
   case 'PIN':
      autorestore_tool_window(p_window_id);
      break;
   default:
      message(nls('Unsupported action: %s', id));
   }
}

/**
 * Delete the tool-window with name <code>form_name</code>. Do 
 * not save its restore postion. 
 * 
 * @param form_name 
 */
static void _tw_destroy_form(_str form_name)
{
   int wid = tw_is_visible(form_name);
   if ( wid > 0 ) {
      noRestore := true;
      tw_delete(wid, noRestore);
   }
}

/**
 * Update/upgrade old tool-windows. 
 */
void _UpdateToolWindows()
{
   // Called from _firstinit()
#ifdef not_finished
   // TODO: Might need to look for user-added tool-windows in
   // def_toolbartab and move them to g_toolwindowtab.
#endif

   // (18.0) Turn off file tabs tool window, unless they want to
   // restore their configuration including it.
   if ( (!def_tbreset_with_file_tabs || !_haveFileTabsWindow()) && def_one_file != '' ) {
      _post_call(_tw_destroy_form, '_tbbufftabs_form');
   }
   tw_sanity();
}

void _on_create_tool_window(bool restore_focus=true)
{
   wid := p_window_id;
   if ( !wid.p_isToolWindow ) {
      return;
   }
   if ( (wid.p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
      // Probably called by show_tool_window()
      return;
   }
   noBorder := "PN";
   // W = Call on_create(), on_load(), on_resize() for registered window
   // Note: _mdi is passed as parent but not used in the case of 'W' (reloading wid)
   //say('_on_create_tool_window : wid='wid.p_name'='wid);
   int focus_wid = restore_focus ? _get_focus() : 0;
   int current = tw_next_window(wid, 'C', false);
   _load_template(wid, _mdi, 'W':+noBorder);

   // TODO: Save p_tile_id with state info
   typeless state = _GetDialogInfoHt("twState.":+wid.p_name, _mdi);
   wid.tw_restore_state(state, true);
   if ( state != null ) {
      _SetDialogInfoHt("twState.":+wid.p_name, null, _mdi);
   }

   // Restore the current window
   if ( current && current != wid ) {
      tw_set_active(current);
   }
   if ( focus_wid && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
}
