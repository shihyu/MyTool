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
#include "eclipse.sh"
#include "dockchannel.sh"
#import "dockchannel.e"
#import "files.e"
#import "listbox.e"
#import "main.e"
#import "mprompt.e"
#import "qtoolbar.e"
#import "stdprocs.e"
#import "tbview.e"
#import "se/ui/toolwindow.e"
#import "toolbar.e"
#endregion

//using namespace se.ui;

static int LAYOUT_VERSION = 1;

// View containing full screen layout auto-restore information
static int _fullscreen_layout_view_id;
// View containing standard toolbar auto-restore information
static int _standard_layout_view_id;
// View containing full screen debug toolbar auto-restore information
static int _fullscreen_debug_layout_view_id;
// View containing debug toolbar auto-restore information
static int _debug_layout_view_id;
// View containing full screen slick-c debug toolbar auto-restore information
static int _fullscreen_slickc_debug_layout_view_id;
// View containing slick-c debug toolbar auto-restore information
static int _slickc_debug_layout_view_id;

definit()
{
   if ( arg(1) != 'L' ) {
      // Editor initialization case

      // Indicate we are not in debug mode
      _tbDebugSetMode(false);

      // Indicate we are not in full screen mode
      _tbFullScreenSetMode(false);
   }

   // Indicated that we do not have a view containing 
   // standard layout auto-restore information
   _standard_layout_view_id = 0;
   int window_group_view_id;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   int status = find_view("._layout_standard");
   if ( status==0 ) {
      get_window_id(_standard_layout_view_id);
   }

   // Indicated that we do not have a view containing 
   // debug layout auto-restore information
   _debug_layout_view_id = 0;
   status = find_view("._layout_debug");
   if ( status == 0 ) {
      get_window_id(_debug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we do not have a view containing 
   // slickc debug layout auto-restore information
   _slickc_debug_layout_view_id = 0;
   status = find_view("._layout_slickc_debug");
   if ( status == 0 ) {
      get_window_id(_slickc_debug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we do not have a view containing 
   // full screen layout auto-restore information
   _fullscreen_layout_view_id = 0;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   status = find_view("._layout_fullscreen");
   if ( status == 0 ) {
      get_window_id(_fullscreen_layout_view_id);
   }

   // Indicated that we do not have a view containing
   // full screen debug layout auto-restore information
   _fullscreen_debug_layout_view_id = 0;
   status=find_view("._layout_fullscreen_debug");
   if ( status == 0 ) {
      get_window_id(_fullscreen_debug_layout_view_id);
   }

   // Indicated that we do not have a view containing
   // full screen slickc debug layout auto-restore information
   _fullscreen_slickc_debug_layout_view_id = 0;
   status=find_view("._layout_fullscreen_slickc_debug");
   if ( status == 0 ) {
      get_window_id(_fullscreen_slickc_debug_layout_view_id);
   }
}

static void autorestore_layout(_str option, _str info="", _str restoreName="", bool restoreOnlyFloating=false)
{
   tw_sanity();
   option = lowcase(option);

   focus_wid := 0;

   /*
   APP_LAYOUT: (nRestoreLines) (version) (nRestoreToolWindow) (windowState) (isFullScreen)
   _tbprojects_form (flags) (visible)
   ...
   _tboutput_form (flags) (visible)
   AAAAAgAAAAIAAAAB2gAAAAIAMAAAAAAAAAAV.../////AAA=
   */

   if ( option == 'r' || option == 'n' ) {

      if ( restoreOnlyFloating ) {
         // Clear all floating tool-windows now, or else you
         // end up with extra windows stuffed into main mdi.
         tw_clear_floating();
      }

      typeless nRestoreLines, version;
      typeless nRestoreToolWindowInfo;
      typeless nRestoreToolWindow;
      typeless nRestoreToolbarLines;
      typeless windowState, isFullscreen;

      parse info with nRestoreLines version nRestoreToolWindowInfo nRestoreToolWindow nRestoreToolbarLines windowState isFullscreen;

      if ( version != LAYOUT_VERSION ) {
         down(nRestoreLines);
         reset_window_layout();
         return;
      }

      if( restoreName == "APP_LAYOUT" && isFullscreen != "" ) {
         _tbFullScreenSetMode(isFullscreen !=0 );
      }
      
      focus_wid = _get_focus();

      success := true;

      if ( success && isinteger(nRestoreToolbarLines) && nRestoreToolbarLines > 0 && !restoreOnlyFloating ) {
         save_pos(auto orig_pos);
         down(nRestoreToolWindowInfo+nRestoreToolWindow+1);
         p_window_id.autorestore_qtoolbars(option, nRestoreToolbarLines);
         restore_pos(orig_pos);
      }

      if( isinteger(nRestoreToolWindowInfo) && nRestoreToolWindowInfo > 0 ) {

         while ( nRestoreToolWindowInfo-- ) {

            down();
            get_line(auto line);
            _str formName;
            typeless flags;
            parse line with formName " F="flags .;
            flags = (isinteger(flags) && flags >=0) ? flags : 0;
            ToolWindowInfo* twinfo = tw_find_info(formName);
            if ( twinfo ) {
               // Only allow user-settable flags.
               // This allows us to add feature support later (e.g. duplicate support)
               // without the user's flags clobbering it.
               twinfo->flags &= TWF_SYSTEM_MASK;
               twinfo->flags |= flags & ~(TWF_SYSTEM_MASK);
            }
         }

      }

      if( isinteger(nRestoreToolWindow) && nRestoreToolWindow > 0 ) {

         dockingAllowed := tw_is_docking_allowed();

         while ( nRestoreToolWindow-- ) {

            down();
            get_line(auto line);
            _str formName;
            typeless tile_id;
            parse line with formName " T="tile_id .;
            tile_id = (isinteger(tile_id) && tile_id >= 0) ? tile_id : 0;
            ToolWindowInfo* twinfo = tw_find_info(formName);
            if ( twinfo ) {
               //say('autorestore_layout : formName='formName'  allowed='tw_is_allowed(formName, twinfo));
               if ( dockingAllowed && tw_is_allowed(formName, twinfo) ) {
                  orig_wid := p_window_id;
                  wid := tw_load_form(formName);
                  // Windows get p_tile_id=0 by default
                  if ( tile_id > 0 ) {
                     wid.p_tile_id = tile_id;
                  }
#ifdef not_finished
                  // TODO: Might need to delay _tbRestoreState() until after state applied
                  typeless state = _GetDialogInfoHt("tbState.":+formName, _mdi);
                  wid._tbRestoreState(state,false);
                  if( state != null ) {
                     _SetDialogInfoHt("tbState.":+formName, null, _mdi);
                  }
#endif
                  p_window_id = orig_wid;
               }
            }
         }
      }
      // Apply the encoded state
      // Note that encoded state still contains docking information (e.g PlaceHolders)
      // even if there are no tool-windows to restore.
      down();
      get_line(auto state);
      // Save and restore active window so autorestore_qtoolbars() operates
      // on the correct view.
      orig_wid := p_window_id;
      int flags = restoreOnlyFloating ? RESTORESTATE_ONLYFLOATING : 0;
      flags |= RESTORESTATE_POSTCLEANUP;
      success = _MDIRestoreState(state, WLAYOUT_MAINAREA, flags);
      //say('autorestore_layout : success='success);
      p_window_id = orig_wid;

      if ( success && isinteger(nRestoreToolbarLines) && nRestoreToolbarLines > 0 ) {
         if ( !restoreOnlyFloating ) {
            autorestore_qtoolbars(option, nRestoreToolbarLines);
         } else {
            down(nRestoreToolbarLines);
         }
      }

      if ( !success ) {
         reset_window_layout();
      }

      // Make sure tool-windows have ON_CREATE/ON_LOAD called, since some
      // features require it. Examples:
      // 1. find_refs() pre-populates an auto-hide Refs window before raising it.
      // 2. Open commands of project will show the Build window on startup.
      int wids[];
      tw_get_registered_windows(wids);
      int wid;
      foreach ( wid in wids ) {
         wid._on_create_tool_window(false);
      }

      if ( focus_wid > 0 && _iswindow_valid(focus_wid) ) {
         focus_wid._set_focus();
      }

   } else {

      save_pos(auto p);

      nRestoreLines := 0;
      _str formName;
      ToolWindowInfo twinfo;

      // Tool-window info
      nRestoreToolWindowInfo := g_toolwindowtab._length();
      foreach ( formName => twinfo in g_toolwindowtab ) {
         insert_line(formName" F="twinfo.flags);
      }

      // Visible tool-windows
      int wids[];
      tw_get_registered_windows(wids);
      nRestoreToolWindows := 0;
      int i, n = wids._length();
      for ( i = 0; i < n; ++i ) {
         ++nRestoreToolWindows;
         insert_line(wids[i].p_name" T="wids[i].p_tile_id);
      }

      _str state;
      _MDISaveState(state, WLAYOUT_MAINAREA);
      insert_line(state);
      // +1 for encoded state
      nRestoreLines += nRestoreToolWindowInfo + nRestoreToolWindows + 1;

      // Toolbars
      nRestoreToolbarLines := 0;
      autorestore_qtoolbars(option, nRestoreToolbarLines);
      nRestoreLines += nRestoreToolbarLines;

      orig_line := p_line;
      restore_pos(p);
      insert_line(restoreName": "(nRestoreLines)" "LAYOUT_VERSION" "(nRestoreToolWindowInfo)" "(nRestoreToolWindows)" "(nRestoreToolbarLines)" "_mdi.p_window_state" "_tbFullScreenQMode());
      p_line = orig_line + 1;
   }
}

static int autorestore_layout_view(_str view_name, int& view_id, 
                                   bool isCurrentLayout,
                                   _str option="", _str info="")
{
   option = lowcase(option);
   if ( option == "r" || option == "n" ) {
      typeless Noflines;
      parse info with Noflines .;
      // Copy the layout from our view if there is one
      _copy_into_view(view_name, view_id, (Noflines + 1), false);
      down(Noflines);
   } else {
      if ( isCurrentLayout ) {
         // Write the debug layout
         name := "";
         parse view_name with "._layout_"name;
         autorestore_layout("", "", upcase(name)"_LAYOUT");
      } else {
         // Copy the layout from the temp view if there is one
         if ( view_id ) {
            typeless NoflinesCopied;
            _copy_from_view(view_id, NoflinesCopied);
            //down(NoflinesCopied - 1); Already on last line of what was copied.
         }
      }
   }
   return 0;
}

int _srmon_fullscreen_layout(_str option="", _str info="")
{
   isCurrent := !_tbDebugQMode() && _tbFullScreenQMode();
   return (autorestore_layout_view("._layout_fullscreen",
                                   _fullscreen_layout_view_id,
                                   isCurrent,
                                   option, info));
}


int _srmon_standard_layout(_str option="", _str info="")
{
   isCurrent := !_tbDebugQMode() && !_tbFullScreenQMode();
   return (autorestore_layout_view("._layout_standard",
                                   _standard_layout_view_id,
                                   isCurrent,
                                   option, info));
}

int _srmon_debug_layout(_str option="", _str info="")
{
   isCurrent := _tbDebugQMode() && !_tbFullScreenQMode() && !_tbDebugQSlickCMode();
   return (autorestore_layout_view("._layout_debug",
                                   _debug_layout_view_id,
                                   isCurrent,
                                   option, info));
}

int _srmon_fullscreen_debug_layout(_str option="", _str info="")
{
   isCurrent := _tbDebugQMode() && _tbFullScreenQMode() && !_tbDebugQSlickCMode();
   return (autorestore_layout_view("._layout_fullscreen_debug",
                                   _fullscreen_debug_layout_view_id,
                                   isCurrent,
                                   option, info));
}

int _srmon_slickc_debug_layout(_str option="", _str info="")
{
   isCurrent := _tbDebugQMode() && !_tbFullScreenQMode() && _tbDebugQSlickCMode();
   return (autorestore_layout_view("._layout_slickc_debug",
                                   _slickc_debug_layout_view_id,
                                   isCurrent,
                                   option, info));
}

int _srmon_fullscreen_slickc_debug_layout(_str option="", _str info="")
{
   isCurrent := _tbDebugQMode() && _tbFullScreenQMode() && _tbDebugQSlickCMode();
   return (autorestore_layout_view("._layout_fullscreen_slickc_debug",
                                   _fullscreen_slickc_debug_layout_view_id,
                                   isCurrent,
                                   option, info));
}

static void _save_autorestore_layout_in_view(_str view_buf_name, int& temp_view_id, _str restoreName)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   // Save current layout
   if ( temp_view_id ) {
      activate_window(temp_view_id);
      _lbclear();
   } else {
      _create_temp_view(temp_view_id);
      p_buf_name = view_buf_name;
   }
   autorestore_layout("", "", restoreName);
   activate_window(orig_view_id);
}

/**
 * Should fullscreen mode show the MDI menu?
 * Set to false to hide the MDI menu in fullscreen mode.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_fullscreen_show_mdimenu = true;

/**
 * Should fullscreen mode maximize the editor to use the
 * entire screen?  If disabled, fullscreen just swaps in the
 * fullscreen toolbars, but the editor maintains the same
 * size and position.
 * <p>
 * NOTE:  On Unix, maximize is not guaranteed to work since
 * the window manager controls sizing.
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_fullscreen_maximize_mdi = true;

static int gfsrestore_x,gfsrestore_y,gfsrestore_width,gfsrestore_height;

void _common_fullscreen_settings()
{
   if (_isUnix()) {
      if (def_fullscreen_maximize_mdi) {
         _mdi.p_window_state = 'F';
      }
   } else {
      if ( def_fullscreen_maximize_mdi ) {

         // Note:
         // Maximizing does not work if the border style is none.  We still need to tell windows
         // we are maximized even though we reconfigure the window afterwards.
         _mdi.p_window_state = 'R';

         _mdi._get_window(gfsrestore_x, gfsrestore_y, gfsrestore_width, gfsrestore_height);
         _mdi.p_border_style = BDS_NONE;
         int screen_x, screen_y, screen_width, screen_height;
         _mdi._GetScreen(screen_x, screen_y, screen_width, screen_height);
         int caption_height = GetSystemMetrics(VSM_CYMENU);
         if ( def_fullscreen_show_mdimenu ) {
            caption_height = 0;
         }
         _mdi._move_window(screen_x, screen_y - caption_height, screen_width, screen_height + caption_height,'F');
      }
   }
}

/**
 * Clear floating mdi-window <code>mdi_wid</code> if it has no 
 * mdi child editor windows. Set <code>mdi_wid=-1</code> to 
 * check all floating mdi-windows. Set <code>mdi_wid=0</code> to 
 * check current mdi-window. 
 * 
 * @param mdi_wid 
 */
static void _clear_if_no_mdi_child(int mdi_wid=-1)
{
   int wids[];
   if ( mdi_wid == -1 ) {
      _MDIGetMDIWindowList(wids);
   } else if ( mdi_wid == 0 ) {
      wids[wids._length()] = _MDICurrent();
   } else {
      wids[wids._length()] = mdi_wid;
   }
   int wid;
   foreach ( wid in wids ) {
      if ( wid != _mdi 
           && _MDIWindowHasMDIArea(wid) 
           && _MDICurrentChild(wid) == 0 ) {

         tw_clear(wid);
      }
   }
}

static void _autorestore_from_view(int temp_view_id, bool restoreWindowState)
{
   focus_wid := 0;
   if (_isUnix()) {
      focus_wid = _get_focus();
      if ( focus_wid == 0 && !_no_child_windows() ) {
         // This is a bit of Kludge
         // We need this for when the user selects Stop debugging from the menu and
         // the focus most likely came from the MDI child.
         // I think the root of the problem is that focus events are dispatched
         // when you destroy windows even if the windows did not have focus.
         focus_wid = _mdi.p_child;
      }
   }

#if 1
   // rb - Tool-windows getting deleted causes unnesting which can cause the
   // active editor window to be incorrect after the dust settles.
   int orig_view_id = _MDIGetActiveMDIChild();
#else
   int orig_view_id;
   get_window_id(orig_view_id);
#endif

   // Clear all dock channels
   dc_reset_all();
   // Clear all toolbars
   //_tbDeleteAllQToolbars();

   line := "";
   rtype := "";
   info := "";
   typeless nRestoreLines;
   typeless nRestoreToolWindowInfo;
   typeless nRestoreToolWindows;
   typeless nRestoreToolbarLines;
   typeless windowState;
   typeless isFullscreen;
   formName := "";
   _str name;

   if( temp_view_id != 0 ) {
      activate_window(temp_view_id);
      top();
      get_line(line);
      parse line with rtype info;
      parse info with nRestoreLines version nRestoreToolWindowInfo nRestoreToolWindows nRestoreToolbarLines windowState isFullscreen .;

      if( windowState != "" && restoreWindowState ) {
         parse p_buf_name with "._layout_" name;
         if( name == "fullscreen" ) {
            //_mdi.p_window_state = 'M';
         } else {
            if( windowState != 'M' && windowState != 'N' ) {
               _mdi.p_window_state = 'N';
            } else {
               _mdi.p_window_state = windowState;
            }
         }
      }

      // Close tool-windows that will not be restored
      down(nRestoreToolWindowInfo);
      if( !tw_is_docking_allowed() ) {

         down(nRestoreToolWindows);

      } else {

         int reg_wids[];
         tw_get_registered_windows(reg_wids);
         // Hash table of wid[]
         INTARRAY to_close:[];
         foreach ( auto wid in reg_wids ) {
            to_close:[wid.p_name][to_close:[wid.p_name]._length()] = wid;
         }
#if 1
         down(nRestoreToolWindows);
#else
         // THIS DOES NOT WORK.
         // GREAT IDEA THOUGH.
         while ( nRestoreToolWindows-- ) {
            down();
            get_line(line);
            parse line with formName .;
            // Do not close the tool-window(s) if it/they would be restored
            if ( tw_find_info(formName) 
                 && to_close._indexin(formName) ) {
               if ( to_close:[formName]._length() > 0 ) {
                  to_close:[formName]._deleteel(0);
               }
            }
         }
#endif

         // Windows left in the list are not restored
         int wids[];
         foreach ( formName => wids in to_close ) {
            // Remove all instances
            orig_wid := p_window_id;
            int i, n = wids._length();
            for ( i = 0; i < n; ++i ) {
               //wids[i]._delete_window();
               noRestore := true;
               tw_delete(wids[i], noRestore);
            }
            p_window_id = orig_wid;
         }
         // Force process events so windows that are deleteLater()ed can be
         // processed. Otherwise nothing is the correct size in the layout.
         cancel := false;
         process_events(cancel);
      }
   }

   // If the original window was a child of a tool-window, then it
   // might be gone after the layout is restored. For example, unit testing
   // will run commands in the Build tool-window before stopping the debugger,
   // which makes the editor control child of the Build tool-window the active
   // window.
   if ( !_iswindow_valid(orig_view_id) ) {
      orig_view_id = _mdi.p_child;
   }
   activate_window(orig_view_id);
   _set_focus();
   if ( temp_view_id == 0 ) {
      _tbResetDefaultQToolbars();
      tw_reset();
      if (_isUnix()) {
         if ( focus_wid != 0 && _iswindow_valid(focus_wid) ) {
            focus_wid._set_focus();
         }
      }
      return;
   }
   activate_window(temp_view_id);
   top();
   get_line(line);
   parse line with rtype info;
   parse p_buf_name with "._layout_" name;
   autorestore_layout('r', info, upcase(name)"_LAYOUT");
   // If you start debugging from a toolbar button, and it goes
   // away, then you now have an invalid window to activate.
   if ( !_iswindow_valid(orig_view_id) ) {
      orig_view_id = _mdi.p_child;
   }
   activate_window(orig_view_id);
   _set_focus();

   // Scenario:
   // * Floating window group with an editor window + tool-windows
   // * Go fullscreen
   // * Close floating window group (which closes editor window)
   // * Exit fullscreen
   // Previous floating window group is restored but with no editor window
   // since it was closed during fullscreen. If def_mdi_close_if_no_child_windows=true,
   // then we should treat that as if you closed it.
   if ( def_mdi_close_if_no_child_windows ) {
      _clear_if_no_mdi_child(-1);
   }

   if (_isUnix()) {
      if( focus_wid!=0 && _iswindow_valid(focus_wid) ) {
         focus_wid._set_focus();
      }
   }
   if( _tbFullScreenQMode() ) {
      _common_fullscreen_settings();
   } else {
      _mdi.p_border_style = BDS_SIZABLE;
   }
}

int _srmon_app_layout(_str option="", _str info="", _str restoreFromInvocation="", _str relativeToDir=null,int restoreOnlyFloatingLayout=-1)
{
   //return 0;
   option = lowcase(option);
   if ( option == 'r' || option == 'n' ) {
      autorestore_layout(option, info, "APP_LAYOUT", restoreOnlyFloatingLayout==1);
   } else {

      if ( !_tbDebugQMode() ) {
         // Write the layout info
         autorestore_layout("", "", "APP_LAYOUT");
      } else {
         // Copy the layout settings from the temp view if there is one
         if ( _standard_layout_view_id ) {
            NoflinesCopied := 0;
            _copy_from_view(_standard_layout_view_id, NoflinesCopied);
            down(NoflinesCopied - 1);
         }
      }
   }
   return 0;
}

_command void fullscreen(_str onoff="")
{
   if ( isEclipsePlugin() ) {
      _eclipse_full_screen();
      return;
   }
   if ( !isinteger(onoff) ) {
      onoff = !_tbFullScreenQMode();
   }
   if ( !onoff ) {
      if ( !_tbFullScreenQMode() ) {
         return;
      }
      _tbFullScreenSetMode(false);
      if (_isWindows()) {
         if ( def_fullscreen_maximize_mdi ) {
            _mdi.p_window_state = 'N';
            _mdi._move_window(gfsrestore_x, gfsrestore_y, gfsrestore_width, gfsrestore_height);
         }
      }
      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _save_autorestore_layout_in_view("._layout_fullscreen_slickc_debug", 
                                             _fullscreen_slickc_debug_layout_view_id, 
                                             "FULLSCREEN_SLICKC_DEBUG_LAYOUT");
         } else {
            _save_autorestore_layout_in_view("._layout_fullscreen_debug", 
                                             _fullscreen_debug_layout_view_id, 
                                             "FULLSCREEN_DEBUG_LAYOUT");
         }
      } else {
         _save_autorestore_layout_in_view("._layout_fullscreen", 
                                          _fullscreen_layout_view_id, 
                                          "FULLSCREEN_LAYOUT");
      }

      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_slickc_debug_layout_view_id, true);
         } else {
            _autorestore_from_view(_debug_layout_view_id, true);
         }
      } else {
         _autorestore_from_view(_standard_layout_view_id, true);
      }
      return;
   }
   if ( _tbFullScreenQMode() ) {
      return;
   }
   if ( _tbDebugQMode() ) {
      if ( _tbDebugQSlickCMode() ) {
         _save_autorestore_layout_in_view("._layout_slickc_debug", 
                                           _slickc_debug_layout_view_id, 
                                           "SLICKC_DEBUG_LAYOUT");
      } else {
         _save_autorestore_layout_in_view("._layout_debug", 
                                           _debug_layout_view_id, 
                                           "DEBUG_LAYOUT");
      }
   } else {
      _save_autorestore_layout_in_view("._layout_standard", 
                                        _standard_layout_view_id, 
                                        "STANDARD_LAYOUT");
   }
   _tbFullScreenSetMode(true);
   if ( _tbDebugQMode() ) {
      if ( _tbDebugQSlickCMode() ) {
         _autorestore_from_view(_fullscreen_slickc_debug_layout_view_id, true);
      } else {
         _autorestore_from_view(_fullscreen_debug_layout_view_id, true);
      }
   } else {
      _autorestore_from_view(_fullscreen_layout_view_id, true);
   }
}

int macLionFullscreenMode();

int _OnUpdate_fullscreen(CMDUI& cmdui, int target_wid, _str command)
{
   if (_isMac()) {
      if (!_MacFullScreenSupported()) {
         return MF_GRAYED;
      }
      /*index := find_index("macLionFullScreenMode", PROC_TYPE);
      if (index <= 0) {
         return MF_GRAYED;
      }
      if ( macLionFullscreenMode() ) {
         return MF_GRAYED;
      } */
   }
   if ( _tbFullScreenQMode() ) {
      return (MF_CHECKED | MF_ENABLED);
   }
   return (MF_ENABLED | MF_UNCHECKED);
}

void debug_switch_mode(bool onoff, bool slickc=false)
{
   if ( !isinteger(onoff) ) {
      onoff = !_tbDebugQMode();
   }
   restoreWindowState := _tbFullScreenQMode();
   if ( onoff ) {
      if ( _tbDebugQMode() ) {
         // we are already in debug mode
         return;
      }
      if ( _tbFullScreenQMode() ) {
         _save_autorestore_layout_in_view("._layout_fullscreen", 
                                          _fullscreen_layout_view_id, 
                                          "FULLSCREEN_LAYOUT");
      } else {
         _save_autorestore_layout_in_view("._layout_standard", 
                                          _standard_layout_view_id, 
                                          "STANDARD_LAYOUT");
      }
      _tbDebugSetMode(true, slickc);
      if ( _tbFullScreenQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_fullscreen_slickc_debug_layout_view_id, restoreWindowState);
         } else {
            _autorestore_from_view(_fullscreen_debug_layout_view_id, restoreWindowState);
         }
      } else {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_slickc_debug_layout_view_id, restoreWindowState);
         } else {
            _autorestore_from_view(_debug_layout_view_id, restoreWindowState);
         }
      }
      return;
   }
   if ( !_tbDebugQMode() ) {
      // Currently, we are not in debug mode
      return;
   }
   if ( _tbFullScreenQMode() ) {
      if ( _tbDebugQSlickCMode() ) {
         _save_autorestore_layout_in_view("._layout_fullscreen_slickc_debug", 
                                          _fullscreen_slickc_debug_layout_view_id, 
                                          "FULLSCREEN_SLICKC_DEBUG_LAYOUT");
      } else {
         _save_autorestore_layout_in_view("._layout_fullscreen_debug", 
                                          _fullscreen_debug_layout_view_id, 
                                          "FULLSCREEN_DEBUG_LAYOUT");
      }
   } else {
      if ( _tbDebugQSlickCMode() ) {
         _save_autorestore_layout_in_view("._layout_slickc_debug", 
                                          _slickc_debug_layout_view_id, 
                                          "SLICKC_DEBUG_LAYOUT");
      } else {
         _save_autorestore_layout_in_view("._layout_debug", 
                                          _debug_layout_view_id, 
                                          "DEBUG_LAYOUT");
      }
   }
   _tbDebugSetMode(false, false);
   if ( _tbFullScreenQMode() ) {
      _autorestore_from_view(_fullscreen_layout_view_id, restoreWindowState);
   } else {
      _autorestore_from_view(_standard_layout_view_id, restoreWindowState);
   }
}

_str _current_layout_export_settings(_str& path)
{
   error := "";

   // first create a temp view where we can stash our info
   tempView := 0;
   origView := _create_temp_view(tempView);
   if (origView == "") {
      return "Error creating temp view.";
   }
   call_list('_srmon_');
   /*_srmon_app_layout();
   _srmon_standard_layout();
   _srmon_fullscreen_layout();
   _srmon_debug_layout();
   _srmon_fullscreen_debug_layout();
   _srmon_slickc_debug_layout();
   _srmon_fullscreen_slickc_debug_layout();*/

   // save the file
   _maybe_append_filesep(path);
   filename := "tbLayout.slk";
   status := save_as(_maybe_quote_filename(path:+filename));
   if (!status) {
      path = filename;
   } else {
      error = "Error saving toolbar layout file "path :+ filename".  Error code = "status".";
   }

   // delete the temp view, we are done with it
   _delete_temp_view(tempView);
   p_window_id = origView;

   return error;
}

_str _current_layout_import_settings(_str file)
{
   error := "";

   // open up our file
   tempView := 0;
   origView := 0;
   status := _open_temp_view(file, tempView, origView);
   if (status) {
      return "Error opening layout file "file".  Error code = "status".";
   }

   typeless count = 0;
   typeless line = "";
   type := "";
   for (;;) {
      // get the line - it will tell us what this section is for
      get_line(line);
      parse line with type line;

      name := "_srmon_" :+ strip(lowcase(type), "", ":");
      index := find_index(name, PROC_TYPE);

      // IF there is a callable function
      if (index_callable(index)) {

         // just call the callback for this one
         status = call_index('R', line, index);

         if (status) {
            error = "Error applying layout type "type".  Error code = "status".";
            break;
         }
      } else {
         error = "No callback to apply layout type "type"." :+ OPTIONS_ERROR_DELIMITER;
         // we can't process these lines, so skip 'em
         parse line with count .;
         if (isnumber(count)) {
            down(count);
         }
      }

      activate_window(tempView);
      if ( down()) {
         break;
      }
   }


   // at last, let's see some results!
   if ( _tbFullScreenQMode() ) {
      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_fullscreen_slickc_debug_layout_view_id, true);
         } else {
            _autorestore_from_view(_fullscreen_debug_layout_view_id, true);
         }
      } else {
         _autorestore_from_view(_fullscreen_layout_view_id, true);
      }
   } else {
      if ( _tbDebugQMode() ) {
         if ( _tbDebugQSlickCMode() ) {
            _autorestore_from_view(_slickc_debug_layout_view_id, true);
         } else {
            _autorestore_from_view(_debug_layout_view_id, true);
         }
      } else {
         _autorestore_from_view(_standard_layout_view_id, true);
      }
   }

   // delete the temp view
   _delete_temp_view(tempView);
   p_window_id = origView;

   return error;
}

/**
 * Close floating mdi window if the last mdi child editor window
 * was closed? 
 * 
 * @default true
 * @categories Configuration_Variables
 */
bool def_mdi_close_if_no_child_windows = true;

void _on_mdi_child_removed()
{
   // If last mdichild editor was removed from floating mdi, then clear/close the floating mdi
   mdi_wid := p_window_id;
   if ( def_mdi_close_if_no_child_windows
        && mdi_wid != _mdi ) {

      _clear_if_no_mdi_child(mdi_wid);
   }
}

/**
 * Return MDI child editor window id for current MDI window. 
 * 
 * @return Window id.
 */
int _MDIGetActiveMDIChild()
{
   int mdi_wid = _MDIFromChild(p_active_form);
   if ( !mdi_wid ) {
      mdi_wid = _MDICurrent();
      if ( !mdi_wid ) {
         if ( _mdi.p_child == VSWID_HIDDEN ) {
            return 0;
         }
         return _mdi.p_child;
      }
   }
   int child_wid = _MDICurrentChild(mdi_wid);
   if ( !child_wid ) {
      mdi_with_cmdline := _MDIWindowHasMDIArea(mdi_wid);
      if ( mdi_with_cmdline ) {
         return 0;
      }

      if ( _mdi.p_child == VSWID_HIDDEN ) {
         return 0;
      }
      child_wid = _mdi.p_child;
   }
   return child_wid;
}

void _on_mdi_move(int mdi_wid)
{
   call_list("_mdi_move_",mdi_wid);
}

