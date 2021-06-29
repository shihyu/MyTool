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
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#import "stdprocs.e"
#import "picture.e"
#endregion

void _autohide_tool_window(int wid, bool autohide_group=false, bool restoreFocus=true)
{
   if ( !wid || !_iswindow_valid(wid) || !wid.p_isToolWindow ) {
      return;
   }

   int mdi_wid = _MDIFromChild(wid);
   focus_wid := _get_focus();

   if ( tw_is_auto(wid) ) {

      // If wid is not currently raised, then tw_auto_lower() is a no-op
      tw_auto_lower(wid);

   } else {
      tw_auto_hide(wid, autohide_group);
   }

   if ( restoreFocus ) {
      // The focus_wid might not be visible if it was an auto-hide window
      if ( focus_wid > 0 && _iswindow_valid(focus_wid) && focus_wid.p_visible && !tw_is_auto(focus_wid.p_active_form) ) {
         p_window_id = focus_wid;
      } else if ( _no_child_windows() ) {
         p_window_id = _cmdline;
      } else {
         int current = _MDICurrentChild(mdi_wid);
         if ( current > 0 ) {
            p_window_id = current;
         } else {
            p_window_id = _cmdline;
         }
      }

      // 2020-06-08 - rb
      // Linux.
      // Force process events before setting focus to active window since
      // prior events may have been delayed on Linux (e.g. Show, Activate).
      cancel := false;
      process_events(cancel);
      _set_focus();
   }
}

int _OnUpdate_autohide_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* info = tw_find_info(target_wid.p_name);
   if( !info || (info->flags & TWF_NO_UNPIN) ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}
_command void autohide_tool_window(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   autohide_tabgroup := !(def_toolwindow_options & TWOPTION_NO_AUTOHIDE_TABGROUP);
   restore_focus := true;
   wid.tw_save_state(auto state,false);
   _autohide_tool_window(wid, autohide_tabgroup, restore_focus);
   wid.tw_restore_state(state,false);
}

int _OnUpdate_autorestore_tool_window(CMDUI& cmdui, int target_wid, _str command)
{
   if ( isEclipsePlugin() ) {
      return MF_GRAYED;
   }
   if ( !target_wid || !target_wid.p_isToolWindow || !tw_is_auto(target_wid) ) {
      return MF_GRAYED;
   }
   ToolWindowInfo* info = tw_find_info(target_wid.p_name);
   if( !info /*|| (info->flags & TWF_NO_UNPIN)*/ ) {
      return MF_GRAYED;
   }
   return MF_ENABLED;
}
_command void autorestore_tool_window(int wid=0)
{
   wid = wid == 0 ? p_window_id : wid;
   if ( !wid.p_isToolWindow || !tw_is_auto(wid) ) {
      return;
   }

   wid.tw_save_state(auto state,false);
   restore_tabgroup := !(def_toolwindow_options & TWOPTION_NO_AUTOHIDE_TABGROUP);
   tw_auto_restore(wid, restore_tabgroup);
   wid.tw_restore_state(state, false);
}

void _on_dockchannel_tab_click(DockAreaPos area, int wid)
{
   mdi_wid := p_window_id;
   //say('_on_dockchannel_tab_click : area='area'  wid='wid'  mdi_wid='mdi_wid);
   hover := 0 != (VSOPTION_DOCKCHANNEL_HOVER & _default_option(VSOPTION_DOCKCHANNEL_FLAGS));
   if ( tw_is_auto_raised(wid) && !hover ) {
      tw_auto_lower(wid);
      // Window is no longer visible, so give focus back to MDI child
      int child_wid = _MDICurrentChild(mdi_wid);
      if ( child_wid ) {
         p_window_id = child_wid;
         _set_focus();
      }
   } else {
      tw_auto_raise(wid);
      call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
      tw_set_active(wid);
      call_event(wid, ON_GOT_FOCUS, 'W');
   }
}

void _on_dockchannel_tab_hover(DockAreaPos area, int wid)
{
   mdi_wid := p_window_id;
   //say('_on_dockchannel_tab_hover : area='area'  wid='wid'  mdi_wid='mdi_wid);
   if ( !tw_is_auto_raised(wid) ) {
      // Raise but do not set active
      tw_auto_raise(wid);
      call_event(CHANGE_AUTO_SHOW, wid, ON_CHANGE, 'W');
   }
}

_command void tw_dc_select_tab(_str info='')
{
   parse info with auto mdi_wid auto area auto wid;
   //say('tw_dc_select_tab : mdi_wid='mdi_wid'  area='area'  wid='wid);
   mdi_wid._on_dockchannel_tab_click((DockAreaPos)area, (int)wid);
}

void _on_dockchannel_context_menu(DockAreaPos area)
{
   //say('_on_dockchannel_context_menu : area='area);
   mdi_wid := p_window_id;

   DockChannelInfo dcinfo;
   dc_get_info(mdi_wid, area, dcinfo);
   if ( dcinfo.tabs._length() == 0 ) {
      // Nothing to do
      return;
   }

   // Build a menu from scratch
   int index = find_index("_temp_dockchannel_menu", oi2type(OI_MENU));
   if( index ) {
      delete_name(index);
   }
   index = insert_name("_temp_dockchannel_menu", oi2type(OI_MENU));
   int i, n = dcinfo.tabs._length();
   for ( i = 0; i < n; ++i ) {
      _menu_insert(index, -1, 0, dcinfo.tabs[i].caption, 'tw_dc_select_tab 'mdi_wid' 'area' 'dcinfo.tabs[i].wid);
   }

   int menu_handle = _menu_load(index, 'P');

   _KillToolButtonTimer();

   // Show the menu
   x := 100;
   y := 100;
   _lxy2dxy(SM_TWIP, x, y);
   x = mou_last_x('D') - x;
   y = mou_last_y('D') - y;
   int flags = (VPM_LEFTALIGN | VPM_RIGHTBUTTON);
   int status = _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
}

/**
 * Return auto-hide tool-window wid for form 
 * <code>form_name</code>, or 0 if no auto-hide window. Set 
 * <code>to_mdi_wid</code> if you only want the wid on a 
 * specific mdi window, set to 0 for current mdi window, set to 
 * -1 for any mdi window (starting with current mdi window). 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_auto_form(_str form_name, int to_mdi_wid=0)
{
   int mdi_wid = to_mdi_wid <= 0 ? _MDICurrent() : to_mdi_wid;
   int wid = _MDIFindFormObject(mdi_wid, form_name, 'n');
   if ( wid > 0 && tw_is_auto(wid, mdi_wid) ) {
      return wid;
   }
   if ( to_mdi_wid >= 0 ) {
      // Not an autohide window
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
      if ( wid > 0 && tw_is_auto(wid, mwid) ) {
         return wid;
      }
   }
   // Not an autohide window
   return 0;
}

bool tw_is_auto_lowered(int wid)
{
   if ( !wid || !wid.p_isToolWindow ) {
      return false;
   }
   return tw_is_auto(wid) && !tw_is_auto_raised(wid);
}

/**
 * Return auto-hide tool-window wid for form 
 * <code>form_name</code> that is currently not raised, or 0 if 
 * no auto-hide window. Set <code>to_mdi_wid</code> if you only 
 * want the wid on a specific mdi window, set to 0 for current 
 * mdi window, set to -1 for any mdi window (starting with 
 * current mdi window). 
 * 
 * @param form_name 
 * @param to_mdi_wid 
 * 
 * @return Window id.
 */
int tw_is_auto_lowered_form(_str form_name, int to_mdi_wid=0)
{
   wid := tw_is_auto_form(form_name, to_mdi_wid);
   if ( wid > 0 && tw_is_auto_lowered(wid) ) {
      return wid;
   }
   return 0;
}

int tw_maybe_auto_raise(_str form_name, _str focus_control_name='')
{
   wid := tw_is_auto_form(form_name);
   if ( wid > 0 && focus_control_name != '' ) {
      ctlwid := wid._find_control(focus_control_name);
      if ( ctlwid > 0 ) {
         ctlwid._set_focus();
      }
   }
   return wid;
}
