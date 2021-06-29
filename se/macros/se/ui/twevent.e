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
#include "toolwindow.sh"
#include "vsevents.sh"
#require "sc/lang/ScopedValueGuard.e"
#import "toolwindow.e"
#import "dlgman.e"
#import "stdprocs.e"
#import "bind.e"
#endregion

using sc.lang.ScopedValueGuard;

//
// _toolwindow_etab2
//

defeventtab _toolwindow_etab2;

static bool s_ignore_on_lost_focus2 = false;
static bool _tw_ignore_on_lost_focus2(bool onoff)
{
   old_val := s_ignore_on_lost_focus2;
   s_ignore_on_lost_focus2 = onoff;
   return old_val;
}

/**
 * Acts on the current tool-window.
 */
static void _tw_on_lost_focus2()
{
   if( s_ignore_on_lost_focus2 ) {
      return;
   }
   static bool in_on_lost_focus2;

   if( in_on_lost_focus2 ) {
      // Do not recurse!
      return;
   }

   ScopedValueGuard guard(in_on_lost_focus2);
   in_on_lost_focus2 = true;
   // Nothing to do here yet
}

/**
 * If there is already an on_lost_focus2() event for the form,
 * this event will NOT be called. This is generally not an issue 
 * since tool windows do not hook ON_LOST_FOCUS2, but it should 
 * be noted. 
 */
void _toolwindow_etab2.on_lost_focus2()
{
   _tw_on_lost_focus2();
}

static bool _maybe_do_dialog_hotkey(_str event) {

   if ( p_DockingArea || !_default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS) ) {
      return false;
   }
   int index = event2index(event);
   if ( (index & VSEVFLAG_ALL_SHIFT_FLAGS) != VSEVFLAG_COMMAND ) {
      return false;
   }
   int chIndex = index & ~(VSEVFLAG_ALL_SHIFT_FLAGS);
   if ( chIndex >= _asc('A') && chIndex <= _asc('Z') ) {
      return _dmDoDialogHotkey();
   }
   return false;
}

void _smart_toolwindow_hotkey()
{
   _str key = last_event();
   if ( key :== F7 ) {
      _retrieve_next_form('-', 1);
      return;
   } else if (key :== F8) {
      _retrieve_next_form('', 1);
      return;
   } else if ( key :== F1 ) {
      // pass through to default eventtabs
      active_form_wid := p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      active_form_wid.p_eventtab = 0;
      call_key(key);
      active_form_wid.p_eventtab = old_eventtab;
      return;
   }

   if ( p_object != OI_EDITOR && _maybe_do_dialog_hotkey(last_event()) ) {
      return;
   }

   if ( p_object == OI_EDITOR ) {
      // Key that was actually pressed
      kt_index := last_index('', 'k');
      // Check if the window event table does not have a binding for this key
      if( p_eventtab == 0 || 0 == eventtab_index(p_eventtab, p_eventtab, event2index(key)) ) {
         int command_index = eventtab_index(_default_keys, p_mode_eventtab, event2index(key));
         _str arg2;
         parse name_info(command_index) with ',' arg2 ',' ;
         if ( arg2 == '' ) {
            arg2 = 0;
         }
         iscommand := 0 != ( name_type(command_index) & COMMAND_TYPE );
         if ( iscommand && ( 0 == ((int)arg2 & VSARG2_EDITORCTL) ||   // not allowed in editor control
                             // Or command requires MDI window
                             ( ((int)arg2 & VSARG2_REQUIRES_MDI) &&
                               0 == (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
                             )
                           ) ) {

            if ( p_DockingArea ) {
               int child_wid=_MDICurrentChild(_MDICurrent());
               if ( child_wid ) {
                  p_window_id = child_wid;
                  call_key(last_event());
               }
            } else {
               if( _maybe_do_dialog_hotkey(last_event()) ) {
                  return;
               }
            }
            return;
         }
      }
      int command_index = eventtab_index(_default_keys, p_mode_eventtab, event2index(key));
      if ( !command_index && _maybe_do_dialog_hotkey(last_event()) ) {
         return;
      }
      active_form_wid := p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      int old_eventtab2 = active_form_wid.p_eventtab2;
      active_form_wid.p_eventtab = 0;
      active_form_wid.p_eventtab2 = 0;
      call_key(key);
      if( _iswindow_valid(active_form_wid) ) {
         active_form_wid.p_eventtab = old_eventtab;
         active_form_wid.p_eventtab2 = old_eventtab2;
      }
      return;

   } else if ( p_object == OI_TEXT_BOX || p_object == OI_COMBO_BOX ) {
      keytab_index:=p_object==OI_TEXT_BOX?defeventtab _ul2_textbox:defeventtab _ul2_combobx;
      int command_index=_eventtab_index_with_inheritance(keytab_index,event2index(key));
      //say('got here command_index='command_index);
      if (command_index) {
         //say('ul2_textbox or combo box path');
         call_event(keytab_index,key,'e');
         return;
      }
      /*
         It would be better if _ul2_textbox2 bindings were calculated based on
         the options "CUA text box" and "Mac use command+<key> for hot keys".
      */
      if (def_cua_textbox) {
         // Key that was actually pressed
         kt_index := last_index('', 'k');
         switch (key) {
         case name2event('M-X'):
            command_index=find_index('cut',COMMAND_TYPE);
            break;
         case name2event('M-C'):
            command_index=find_index('copy_to_clipboard',COMMAND_TYPE);
            break;
         case name2event('M-V'):
            command_index=find_index('paste',COMMAND_TYPE);
            break;
         }
         if (command_index) {
            if (key:==name2event('M-C') || (!p_ReadOnly || !(p_object==OI_COMBO_BOX && p_style==PSCBO_NOEDIT))) {
               call_index(command_index);
               return;
            }
         }
      }
      command_index = eventtab_index(_default_keys, _default_keys, event2index(key));
      _str arg2;
      parse name_info(command_index) with ',' arg2 ',' ;
      if ( arg2 == '' ) {
         arg2 = 0;
      }
      iscommand := 0 != ( name_type(command_index) & COMMAND_TYPE );
      iscombo_key := ( key :== F4 && p_object == OI_COMBO_BOX );
      //say('cmd='name_name(command_index));

      //say('arg2_text_box='((int)arg2 & VSARG2_TEXT_BOX)' !iscombo_key='(!iscombo_key)' isc='iscommand);
      if ( !iscombo_key && iscommand &&
           0 == ((int)arg2 & VSARG2_TEXT_BOX)   // not allowed in text box
         ) {
         //say('Pass key to app');
         if ( p_DockingArea || tw_is_auto_raised(p_active_form, _MDICurrent()) ) {
            //say('h2 Pass key to app');
            int child_wid = _MDICurrentChild(_MDICurrent());
            if ( child_wid ) {
               p_window_id = child_wid;
               call_key(last_event());
            }
         }
         return;
      }
      active_form_wid := p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      int old_eventtab2 = active_form_wid.p_eventtab2; // avoid infinite recursion with eventtab2
      active_form_wid.p_eventtab = 0;
      active_form_wid.p_eventtab2 = 0;
      call_event(_default_keys,key,'e');
      /*if ( p_object == OI_COMBO_BOX && !iscombo_key ) {
            call_event(p_window_id, key);
      } else {
            call_key(key);
      } */

      active_form_wid.p_eventtab = old_eventtab;
      active_form_wid.p_eventtab2 = old_eventtab2;
      return;
   }
   if ( p_DockingArea || tw_is_auto_raised(p_active_form, _MDICurrent()) ) {
      int child_wid = _MDICurrentChild(_MDICurrent());
      if ( child_wid ) {
         p_window_id = child_wid;
         call_key(last_event());
      }
   }
}

void _toolwindow_etab2./*'C-A'-'C-Z', */C_O, F1-F12,C_F12,A_F1-A_F12,S_F1-S_F12,'c-s-/','c-0'-'c-9','c-s-0'-'c-s-9','c-s-=','c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9'()
{
   _smart_toolwindow_hotkey();
}

// Events added by user request
void _toolwindow_etab2.'A-,'()
{
   _smart_toolwindow_hotkey();
}

// Events added by user request
void _toolwindow_etab2.'M-,'()
{
   _smart_toolwindow_hotkey();
}

void _toolwindow_etab2.F1()
{
   _dmhelp();
}

void _toolwindow_etab2.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if ( !_no_child_windows() ) {
      p_window_id = _mdi.p_child;
      _set_focus();
   }
}

void tw_dismiss(int active_form, bool force=false)
{
   if ( !active_form.p_isToolWindow ) {
      return;
   }

   // Get the current mdi child BEFORE hiding the tool-window.
   // Explanation: On some platforms (Windows), since the owner
   // is the mainmdi window, then focus will go back to it instead
   // of the previous mdiwindow after tw_delete() is called.
   int child_wid = _MDICurrentChild(0);

   // Note that is_docked also covers auto-hide window case
   was_docked := _MDIWindowHasMDIArea(active_form);
   if ( tw_is_auto_raised(active_form) ) {
      tw_auto_lower(active_form);
   } else if ( tw_is_visible_window(active_form) && !was_docked ) {
      solo := active_form == tw_next_window(active_form, 'N', false);
      if ( solo ) {
         // Floating, solo tool-window
         ToolWindowInfo* twinfo = tw_find_info(active_form.p_name);
         if ( force ||  (twinfo && (twinfo->flags & TWF_DISMISS_LIKE_DIALOG)) ) {
            // Dismiss like a dialog
            hide_tool_window(active_form);
         }
      }
   }

   // Fall through default behavior

   // In case the child_wid was yanked out from under us
   if ( child_wid > 0 
        && (!_iswindow_valid(child_wid) || !child_wid.p_mdi_child) ) {

      child_wid = _MDICurrentChild(0);
   }
   if ( child_wid ) {
      p_window_id = child_wid;
      _set_focus();
   } else if( was_docked ) {
      _cmdline._set_focus();
   }
}

void _toolwindow_etab2.ESC()
{
   tw_dismiss(p_active_form);
}

/**
 * Handles moving between tabs in a tabgroup (if we are in a tabgroup).
 */
void _toolwindow_etab2.'c-tab','s-c-tab'()
{
   _str option = event2name(last_event()) == 'C-TAB' ? '1' : '2';
   int wid = tw_next_window(p_active_form, option, false);
   // If wid==p_active_form that means that this tool window is not part of 
   // tabbed tool window group. In that case, pass the Ctrl+Tab or  Ctrl+Shift+Tab to
   // the dialog manager.
   if ( wid > 0 && wid!=p_active_form) {
      tw_set_active(wid);
      call_event(wid, ON_GOT_FOCUS, 'W');
   } else {
      // Allow tool windows with non-tabgroup tab controls to get the event
      call_event(defeventtab _ainh_dlg_manager, last_event(), 'e');
   }
}

void _toolwindow_etab2.on_create()
{
}

/**
 * Save/serialize state of tool-window.
 *
 * <p>
 *
 * State is saved for a tool-window just before a tool-window is
 * destroyed. Examples include closing the tool-window, a
 * drag-drop operation, or Auto Hide toggle (i.e. toggling Auto
 * Hide off on a tool-window). When the tool-window is 
 * recreated, the state information is passed to its restore 
 * callback (see explanation of callbacks below). 
 *
 * <p>
 *
 * If it is important for your tool-window to distinguish 
 * between a close operation (e.g. hitting the 'X') and an 
 * operation that would destroy and immediately recreate the 
 * tool window (e.g. dock/undock, autohide, autoshow), then your 
 * callback must act on the 'closing' argument. For example, 
 * your tool-window may not want to save the state of the tool 
 * window if the user is simply closing it, in which case the 
 * callback would return immediately if closing==true. The 
 * 'state' output argument is ignored when closing==true, since 
 * it would be the callback's responsibility to save/cache any 
 * state data long-term. 
 *
 * <p>
 *
 * Tool-windows can register a callback to save/restore state by
 * defining 2 global functions: 
 * <pre>
 * void _twSaveState_&lt;ToolWindowFormName&gt;(typeless& state, bool closing) 
 * void _twRestoreState_&lt;ToolWindowFormName&gt;(typeless& state, bool opening) 
 * </pre>
 * For example, callbacks registered for the References 
 * tool-window would be: _twSaveState__tbtagrefs_form, 
 * _twRestoreState__tbtagrefs_form. When a save/restore callback
 * is called, the active window is always the wid of the 
 * saved/restored tool-window. 
 * 
 * @param state   (out). Tool-window defined state information.
 * @param closing true=Tool-window is being closed (not docked,
 *                undocked, autohidden, or autoshown).
 */
void tw_save_state(typeless& state, bool closing)
{
   state._makeempty();
   form_name := p_window_id.p_name;
   if ( form_name != '' ) {
      index := find_index('_twSaveState_':+form_name, PROC_TYPE);
      // Changed the prefix for the callback in v19, so be forgiving
      index = index > 0 ? index : find_index('_tbSaveState_':+form_name, PROC_TYPE);
      if ( index > 0 && index_callable(index) ) {
         call_index(state, closing, index);
      }
   }
}

/**
 * Restore/unserialize state of tool window.
 * <p>
 * State is saved for a tool window just before a tool window is
 * destroyed. Examples include closing the tool window, a
 * drag-drop operation, or Auto Hide toggle (i.e. toggling Auto
 * Hide off on a tool window). When the tool window is
 * recreated, the state information is passed to its restore
 * callback (see explanation of callbacks below).
 * <p>
 * If it is important for your tool-window to distinguish 
 * between a simple show operation (e.g. showing a tool window 
 * some time after it has been closed) and an operation that 
 * would immediately recreate the tool window after it had been 
 * destroyed (e.g. dock/undock, autohide, autoshow), then your 
 * callback must act on the 'opening' argument. For example, 
 * your tool window may not want to restore the state of the 
 * tool window if the user is simply showing it, in which case 
 * the callback would return immediately if opening==true. The 
 * 'state' input argument is ignored when opening==true, since 
 * it would be the callback's responsibility to restore any 
 * state data from long-term storage/cache. 
 *
 * <p>
 *
 * Tool-windows can register a callback to save/restore state by
 * defining 2 global functions:
 * <pre>
 * void _twSaveState_&lt;ToolWindowFormName&gt;(typeless& state, bool closing) 
 * void _twRestoreState_&lt;ToolWindowFormName&gt;(typeless& state, bool opening) 
 * </pre> 
 * For example, callbacks registered for the References
 * tool window would be: _twSaveState__tbtagrefs_form,
 * _twRestoreState__tbtagrefs_form. When a save/restore callback
 * is called, the active window is always the wid of the
 * saved/restored tool window.
 * 
 * @param state   (in). Tool-window defined state information to
 *                restore.
 * @param opening true=Tool-window is being simply opened (i.e.
 *                opened some time after having been closed).
 */
void tw_restore_state(typeless& state, bool opening)
{
   form_name := p_window_id.p_name;
   if ( form_name != '' ) {
      index := find_index('_twRestoreState_':+form_name, PROC_TYPE);
      // Changed the prefix for the callback in v19, so be forgiving
      index = index > 0 ? index : find_index('_tbRestoreState_':+form_name, PROC_TYPE);
      if ( index > 0 && index_callable(index) ) {
         call_index(state, opening, index);
      }
   }
}

/**
 * ON_CLOSE only gets called when the user hits the 'X'. There
 * are specific checks in the code to prevent calling this event
 * otherwise.
 */
void _toolwindow_etab2.on_close()
{
   //say('_toolwindow_etab2.on_close: in');
   if ( !p_isToolWindow ) {
      return;
   }

   wid := p_active_form;

   child_wid := 0;
   if ( !_no_child_windows() ) {
      child_wid = _mdi.p_child;
   }
   if ( tw_is_auto_raised(wid) ) {
      tw_auto_lower(wid);
   }
   if ( testFlag(def_toolwindow_options, TWOPTION_CLOSE_TABGROUP) ) {
      tw_hide_tabgroup_window(wid);
   } else {
      tw_hide_window(wid);
   }
   if ( child_wid > 0 ) {
      child_wid._set_focus();
   }
}

void _toolwindow_etab2.on_destroy()
{
   ToolWindowInfo* twinfo = tw_find_info(p_name);
   if ( !twinfo ) {
      return;
   }
   if ( p_DockingArea != 0 ) {
      return;
   }
   int list = _find_object("_tool_windows_prop_form.list1", 'n');
   if ( list > 0 ) {
      list.call_event(CHANGE_SELECTED, 1, list, ON_CHANGE, '');
   }
}

void _toolwindow_etab2.on_load()
{
   p_old_width = 0;
   p_old_height = 0;
   call_event(p_window_id, ON_RESIZE);

   int list = _find_object('_tool_windows_prop_form.list1', 'n');
   if ( list > 0 ) {
      list.call_event(CHANGE_SELECTED, list, ON_CHANGE, '');
   }
}

void _toolwindow_etab2.on_resize()
{
   if( !tw_is_floating(p_window_id) || p_object != OI_FORM ) {
      return;
   }
   if ( p_width == p_old_width && p_height == p_old_height ) {
      return;
   }
   p_old_width = p_width;
   p_old_height = p_height;
}

void _toolwindow_etab2."c-s- "()
{
   // Need to call automatical inheritance; otherwise we would 
   // never be able to edit a tool-window.
   call_event(defeventtab _ainh_dlg_manager, name2event('C-S- '), 'e');
}

void _toolwindow_etab2."c-lbutton_down"()
{
   call_event(0, p_window_id, LBUTTON_DOWN, '');
}

void _toolwindow_etab2.lbutton_down()
{
}

void _toolwindow_etab2.lbutton_double_click()
{
}

void _toolwindow_etab2.rbutton_up()
{
}

void _tw_exiting_editor()
{
   // _append_retrieve changes the active view in
   // the hidden window.  Here we save and restore
   // the active window.
   int orig_wid;
   get_window_id(orig_wid);
   int wids[];
   tw_get_registered_windows(wids);
   int i, n = wids._length();
   for( i=0; i < n; ++i ) {
      if( wids[i] > 0 /*&& !_tbIsAutoWid(wid)*/ ) {
         // Only call ON_DESTROY if the wid's ON_CREATE has been called.
         // Auto-hide windows that have never been raised would not have had ON_CREATE called.
         if ( (wids[i].p_window_flags & VSWFLAG_ON_CREATE_ALREADY_CALLED) ) {
            wids[i].call_event(wids[i], ON_DESTROY);
         }
      }
   }
   activate_window(orig_wid);
}
