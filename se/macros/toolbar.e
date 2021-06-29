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
#include "se/ui/toolwindow.sh"
#import "bufftabs.e"
#import "dlgeditv.e"
#import "dlgman.e"
#import "main.e"
#import "menu.e"
#import "picture.e"
#import "qtoolbar.e"
#import "sstab.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbprops.e"
#import "tbview.e"
#import "dlgman.e"
#import "help.e"
#import "se/ui/toolwindow.e"
#import "se/ui/twevent.e"
#endregion

bool def_tbreset_with_file_tabs = false;

// This table is modified during editor execution and
// autorestored.
_TOOLBAR def_toolbartab[];
// This table should not be changed during editor execution.
// def_toolbartab is initialized to this table.
static _TOOLBAR init_toolbartab[] = {
   {'_tbstandard_form',       TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbproject_tools_form',  TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_BUILD},
   {'_tbtools_form',          TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbedit_form',           TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbseldisp_form',        TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbxml_form',            TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_XML_VALIDATION},
   {'_tbhtml_form',           TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbtagging_form',        TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_CONTEXT_TAGGING},
   {'_tbcontext_form',        TBFLAG_ALLOW_DOCKING, false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_CURRENT_CONTEXT},
   {'_tbdebugbb_form',        TBFLAG_LIST_WITH_DEBUG_TOOLBARS | TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_DEBUGGING},
   {'_tbdebug_sessions_form', TBFLAG_ALLOW_DOCKING | TBFLAG_LIST_WITH_DEBUG_TOOLBARS, false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_DEBUGGING},
   {'_tbvc_form',             TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_VERSION_CONTROL},
   {'_tbunified_form',        TBFLAG_NEW_TOOLBAR | TBFLAG_UNIFIED_TOOLBAR, false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
   {'_tbandroid_form',        TBFLAG_NEW_TOOLBAR,   false, 0, 0, 0, 0, DOCKINGAREA_NONE, 0, 0, 0, 0, 0, 0, 0, 0, 0, TB_REQUIRE_BUILD},
};

int def_toolbar_options = 0;

definit()
{
   /*
      Changed so state file is identical on Windows and Unix platforms.
   */
   if ( def_toolbartab == null ) {
      def_toolbartab = init_toolbartab;
   }
   if ( !_isMac() ) {
      if ( arg(1) == 'L' ) {
         // Removed _tbunified_form since not on Mac
         int i;
         for ( i=0; i < def_toolbartab._length(); ++i ) {
            if ( def_toolbartab[i].FormName == '_tbunified_form') {
               def_toolbartab._deleteel(i);
               break;
            }
         }
      }
   }
}

void _UpdateToolbars()
{
   // Need this in order to weed out tool-windows that now live in g_toolwindowtab:[]
   tw_sanity();
   ToolWindowInfo* twinfo;

   // (16.1) Called from _firstinit()
   int i, n = def_toolbartab._length();
   for ( i = 0; i < n; ) {
      if ( def_toolbartab[i].FormName == "_tbcontext_form" ) {
         if ( def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED ) {
            def_toolbartab[i].tbflags &= ~(TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED);
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         // This is a toolbar
         if ( def_toolbartab[i].tbflags & TBFLAG_SIZEBARS ) {
            def_toolbartab[i].tbflags &= ~TBFLAG_SIZEBARS;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      } else if (def_toolbartab[i].FormName=="_tbdebug_sessions_form") {
         if (def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) {
            def_toolbartab[i].tbflags &= ~TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         // This is a toolbar
         if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
            def_toolbartab[i].tbflags &= ~TBFLAG_SIZEBARS;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      } else if ( tw_find_info(def_toolbartab[i].FormName) ) {
         // This tool-window has been moved to g_toolwindowtab:[]
         def_toolbartab._deleteel(i);
         --n;
         continue;
      }

      // Toolbars have no need for any of this
      if ((def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) == 0) {
         def_toolbartab[i].restore_docked=false;
         def_toolbartab[i].show_x=0;
         def_toolbartab[i].show_y=0;
         def_toolbartab[i].show_width=0;
         def_toolbartab[i].show_height=0;

         def_toolbartab[i].docked_area=DOCKINGAREA_NONE;
         def_toolbartab[i].docked_row=0;
         def_toolbartab[i].docked_x=0;
         def_toolbartab[i].docked_y=0;
         def_toolbartab[i].docked_width=0;
         def_toolbartab[i].docked_height=0;

         def_toolbartab[i].tabgroup=0;
         def_toolbartab[i].tabOrder= -1;

         def_toolbartab[i].auto_width=0;
         def_toolbartab[i].auto_height=0;
           
         def_toolbartab[i].tbflags &= ~(TBFLAG_ALWAYS_ON_TOP|TBFLAG_NO_CAPTION);
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      ++i;
   }

   _tbNewVersion();
}

/**
 * Create toolbar from resource_index as a child of parent_wid.
 * 
 * @param tbflags
 * @param resource_index
 * 
 * @return Window id (wid) of loaded tool window.
 */
int _tbLoadTemplate(int tbflags, int resource_index)
{
   if ( 0 == (tbflags & TBFLAG_SIZEBARS) ) {
      return _tbLoadQToolbar(resource_index, tbflags, true);
   }
   return 0;
}

static void _tbAppendToolbarsToMenu(int menu_handle, bool list_debug_toolbars)
{
   ToolWindowFeatures features;

   mask := 0;
   if ( _tbDebugQMode() ) {
      mask = TBFLAG_WHEN_DEBUGGER_STARTED_ONLY | TBFLAG_LIST_WITH_DEBUG_TOOLBARS;
   } else {
      mask = TBFLAG_WHEN_DEBUGGER_STARTED_ONLY;
   }

   // Append toolbars

   // Finagle a _sort() on an array of structs.
   // Items will be sorted into tbitem[] for toolbars (e.g. all buttons).
   _str tbitem[];
   tbitem._makeempty();
   int i;
   for ( i = 0; i < def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      display := false;
      if ( features.testFlags(ptb->rflags) ) {
         if ( list_debug_toolbars ) {
            display = ( 0 != (ptb->tbflags & mask) && _tbDebugListToolbar(ptb) );
         } else {
            display = ( 0 == (ptb->tbflags & mask) );
         }
      }
      if ( display ) {
         int index = find_index(ptb->FormName, oi2type(OI_FORM));
         wid := _tbGetWid(ptb->FormName);
         int tbflags = ptb->tbflags;
         // item = caption;enabled;command
         // Note that caption is padded to 30 characters so that sorting
         // is consistent between captions with similar prefixes.
         item := "";
         if ( wid != 0 ) {
            caption := substr(wid.p_caption, 1, max(30, length(wid.p_caption)));
            item = caption';'(MF_ENABLED|MF_CHECKED)';':+"tbClose "wid;
         } else {
            index = find_index(ptb->FormName, oi2type(OI_FORM));
            if ( index != 0 ) {
               int enabled = MF_ENABLED;
               if ( _tbIsDisabledToolbar(ptb) ) {
                  enabled = MF_GRAYED;
               }
               caption := substr(index.p_caption, 1, max(30, length(index.p_caption)));
               item = caption';'(enabled)';':+"tbSmartShow "ptb->FormName;
            }
         }

         if( item != '' ) {

            if( isToolbar(tbflags) ) {
               // Toolbar
               tbitem[tbitem._length()]=item;
            }
         }
      }
   }

   // Insert sorted toolbars
   tbitem._sort('i');
   for ( i = 0; i < tbitem._length(); ++i ) {
      _str caption, mf_flags, cmd;
      parse tbitem[i] with caption';'mf_flags';'cmd;
      _menu_insert(menu_handle, -1, (int)mf_flags, strip(caption), cmd);
   }
}

bool isToolbar(int tbflags)
{
   return (tbflags & TBFLAG_SIZEBARS) ? false : true;
}

/**
 * Operates on the active object.
 * <p>
 * Show the toolbar context menu.
 * 
 * @param list_toolbars (optional). true=list toolbars on the context
 *                      menu. Default is true.
 * @param wid           (optional). If >0, then wid is used for toolbar
 *                      menu operations: Dockable, Hide, Floating, AutoHide.
 *                      Otherwise, if =0, then the active form is used.
 *                      Defaults to 0.
 * 
 * @return 0 on success, <0 on failure.
 */
int _tbContextMenu(bool list_toolbars=true, int wid=0)
{
   _tbNewVersion();

   orig_wid := p_window_id;
   if ( wid == 0 ) {
      // Use the active form
      wid = orig_wid;
   }

   // ignore sizebars
   if ( wid.p_object==OI_IMAGE && wid.p_caption == '' && !wid.p_picture && 
       (wid.p_style == PSPIC_SIZEHORZ || wid.p_style == PSPIC_SIZEVERT)) {
      return 0;
   }

   int formWid = wid.p_active_form;
   int index = find_index('_toolbar_menu',oi2type(OI_MENU));
   if ( index == 0 ) {
      return STRING_NOT_FOUND_RC;
   }

   // Delete "Properties..." item if this is not a toolbar button
   isButtonBarButton := false;
   if ( wid.p_object==OI_IMAGE && !wid._ImageIsSpace() && wid.p_eventtab == 0 ) {
      isButtonBarButton = true;
   }
   int menu_handle = formWid._menu_load(index, 'P');
   if ( isButtonBarButton ) {
      mpos := 0;
      _menu_insert(menu_handle, mpos++, MF_ENABLED, "Properties...", "tbControlProperties "orig_wid);
      _menu_insert(menu_handle, mpos++, MF_ENABLED, "-");
   }

   if ( !list_toolbars ) {
      int i, nofItems;
      mf_flags := 0;
      caption := "";
      nofItems = _menu_info(menu_handle, 'c');
      for ( i = nofItems - 1; i >= 0; --i ) {
         _menu_get_state(menu_handle, i, mf_flags, 'P', caption);
         if ( mf_flags & MF_SUBMENU ) {
            if ( caption == 'Toolbars' || caption == 'Tool Windows' ) {
               _menu_delete(menu_handle, i);
            }
         }
      }
 
   } else {
      _init_menu_toolbars(menu_handle, 0);
      _init_menu_tool_windows(menu_handle, 0);
   }

   if ( formWid > 0 ) {
      _TOOLBAR* ptb = _tbFind(formWid.p_name);
      if ( ptb ) {
         mpos := 0;
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Dockable", "tbDockableToggle "formWid);
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Floating", "tbFloatingToggle "formWid);
         if ( _IsQToolbar(formWid) && !_QToolbarGetFloating(formWid) ) {
            _menu_insert(menu_handle, mpos++, MF_ENABLED, "Movable", "tbMovableToggle "formWid);
         }
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Hide", "tbClose "formWid);
         if ( list_toolbars ) {
            // There are toolbars listed underneath these items,
            // so insert a separator.
            _menu_insert(menu_handle, mpos++, MF_ENABLED, '-');
         }
      }
   }

   // Show the menu
   x := 100;
   y := 100;
   x = wid.mou_last_x('M') - x;
   y = wid.mou_last_y('M') - y;
   _lxy2dxy(wid.p_scale_mode, x, y);
   _map_xy(wid, 0, x, y, SM_PIXEL);
   int flags = VPM_LEFTALIGN | VPM_RIGHTBUTTON;
   _KillToolButtonTimer();
   p_window_id = formWid;
   int status = _menu_show(menu_handle, flags, x, y);
   _menu_destroy(menu_handle);
   // Might have selected Hide on a tool-window, so check if still valid
   if ( _iswindow_valid(orig_wid) ) {
      p_window_id = orig_wid;
   }

   return 0;
}

void _tbPostedContextMenu(_str args)
{
   typeless a;
   typeless vargs[];
   while( args != '' ) {
      parse args with a','args;
      vargs[vargs._length()] = a;
   }
   // Return value ignored when posted
   switch( vargs._length() ) {
   case 0:
      _tbContextMenu();
      break;
   case 1:
      _tbContextMenu(vargs[0]);
      break;
   default:
      _tbContextMenu(vargs[0],vargs[1]);
      break;
   }
}

/**
 * Insert toolbar list.
 * 
 * @param menu_handle
 * @param no_child_windows
 */
void _init_menu_toolbars(int menu_handle, int no_child_windows)
{
   //
   // View>Toolbars menu
   //

   int menuItem, mpos;
   int status = _menu_find(menu_handle, 'toolbars', menuItem, mpos, 'm');
   if ( status != 0 ) {
      // Not in the View>Toolbars menu
      return;
   }

   // Delete everything after "toolbars" command
   ++mpos;
   status = 0;
   while( status == 0 ) {
      status = _menu_delete(menuItem, mpos);
   }

   if ( _tbDebugQMode() ) {
      _tbAppendToolbarsToMenu(menuItem, true);
   }
   _tbAppendToolbarsToMenu(menuItem, false);

}

/**
 * Delete the active toolbar.
 */
void _tbSmartDeleteWindow()
{
   if ( _IsQToolbar(p_window_id) ) {
      _tbDeleteQToolbar(p_window_id);
   }
}

/**
 * Close toolbar window <code>wid</code>. 
 * 
 * @param wid 
 */
void _tbClose(int wid)
{
   if ( _IsQToolbar(wid) ) {
      _tbDeleteQToolbar(wid);
      return;
   }
}

/**
 * @param wid window id of toolbar to close
 * @param docking this parameter should be true if the toolbar is being docked or undocked
 */
_command void tbClose(...)
{
   // preventing stack
   if (arg() == 0) return;

   _tbNewVersion();
   int wid = arg(1);
   docking := false;
   if ( arg() > 1 ) {
      docking = arg(2);
   }
   //say('tbClose: wid='wid'  wid.p_name='wid.p_name);

   if ( !docking ) {
      // User is closing this toolbar (e.g. hitting 'X')
      state := null;
      wid._tbSaveState(state, true);
      if ( state != null ) {
         _SetDialogInfoHt("tbState.":+wid.p_active_form.p_name, state, _mdi);
      }
   }
   _tbClose(wid);
}

/**
 * @return If ptb==null, then the global setting is returned. If ptb!=null, and 
 * docking is allowed globally, the per-tool-window setting is returned. 
 */
bool _tbIsDockingAllowed(_TOOLBAR* ptb=null)
{
   dockingAllowed := false;
   if ( 0 != (_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_TOOLBAR_DOCKING) ) {
      // Docking allowed globally
      dockingAllowed = true;
      if ( dockingAllowed && ptb ) {
         dockingAllowed= 0 != ( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
      }
   }
   return dockingAllowed;
}

int _tbShow(_str FormName, int x, int y, int width, int height, bool forceUndock=false)
{
   wid := _tbGetWid(FormName);
   if ( wid != 0 ) {
      return wid;
   }
   _TOOLBAR* ptb = _tbFind(FormName);
   int tbflags = TBFLAG_NEW_TOOLBAR;
   if ( ptb ) {
      tbflags = ptb->tbflags;
   }

   if ( 0 == (tbflags & TBFLAG_SIZEBARS) ) {
      wid = _tbLoadQToolbarName(FormName);
   }
   return wid;
}

_command void tbShow(_str FormName="") name_info(FORM_ARG',')
{
   // Legacy support for showing tool-window
   ToolWindowInfo* twinfo = tw_find_info(FormName);
   if ( twinfo ) {
      show_tool_window(FormName);
      return;
   }

   // Fall through to toolbar case

   _tbNewVersion();
   _TOOLBAR* ptb = _tbFind(FormName);
   int index = find_index(FormName, oi2type(OI_FORM));
   if ( !ptb || index == 0 ) {
      _message_box(get_message(VSRC_FORM_NOT_FOUND, '', FormName));
      return;
   }

   if ( !tbIsAllowed(FormName, ptb) ) {
      popup_message(get_message(VSRC_FEATURE_REQUIRES_PRO_EDITION));
      return;
   }

   //int wid = _find_formobj(FormName,"n");
   wid := _tbGetWid(FormName);
   if ( !_tbIsDockingAllowed(ptb) ) {
      // Docking not allowed
      ptb->restore_docked = false;
   }

   int old_wid = wid;
   if ( ptb->show_width != 0 ) {
      //say('case1 show 'ptb->show_x' 'ptb->show_y' 'ptb->show_width' 'ptb->show_height);
      wid = _tbShow(FormName, ptb->show_x, ptb->show_y, ptb->show_width, ptb->show_height);
   } else {
      //say('case2 show 'ptb->show_x' 'ptb->show_y' 'ptb->show_width' 'ptb->show_height);
      wid = _tbShow(FormName, 0, 0, 0, 0);
   }
   if ( wid && old_wid != wid ) {
      // New toolbar shown, so inform it
      typeless state = _GetDialogInfoHt("tbState.":+FormName, _mdi);
      wid._tbRestoreState(state, true);
      if ( state != null ) {
         _SetDialogInfoHt("tbState.":+FormName, null, _mdi);
      }
   }
}

_command void tbSmartShow(_str FormName='') name_info(FORM_ARG',')
{
   tbShow(FormName);
}

// show/hide floaters
void _tbVisible(bool Show)
{
   focus_wid := _get_focus();
   int i;
   for ( i = 0; i < def_toolbartab._length(); ++i ) {
      wid := _tbGetWid(def_toolbartab[i].FormName);
      if ( !wid ) {
         continue;
      }

      if (_IsQToolbar(wid)) {
         int isFloating = _QToolbarGetFloating(wid);
         if ( !isFloating ) {
            continue;
         }
      }
      wid.p_visible = Show;
   }
   if ( focus_wid != 0 ) {
      focus_wid._set_focus();
   }
}

_TOOLBAR* _tbFind2(_str FormName, int& i)
{
   for ( i = 0; i < def_toolbartab._length(); ++i ) {
      if ( FormName == def_toolbartab[i].FormName ) {
         return (&def_toolbartab[i]);
      }
   }
   return null;
}

_TOOLBAR* _tbFind(_str FormName)
{
   i := 0;
   return (_tbFind2(FormName, i));
}

_TOOLBAR* _tbFindCaption(_str name, int& index)
{
   int i;
   for ( i=0; i < def_toolbartab._length(); ++i ) {
      index = find_index(def_toolbartab[i].FormName, oi2type(OI_FORM));
      if ( index != 0 && strieq(index.p_caption, name) ) {
         return (&def_toolbartab[i]);
      }
   }
   return null;
}

/**
 * Add a user-supplied form to 'def_toolbartab'.
 * Will not add a form that is already on the list,
 * or a form name that does not exist in the system.
 *
 * @param FormName Name of form to add to toolbar list
 * @param tbFlags  toolbar flags, bitset of TBFLAG_
 * @param defaultVisible
 *                 When the toolbars are first initialized and displayed,
 *                 should this toolbar be made visible and/or docked.
 * @param area     If the toolbar is to be made visible, where 
 *                 should it be docked?  0 means show the
 *                 toolbar, but do not dock.
 */
void _tbAddForm(_str FormName, int tbFlags,
                bool defaultVisible=false, DockingArea area=DOCKINGAREA_NONE, bool doReplace=false)
{
   // already in list?
   _TOOLBAR* ptb = _tbFind(FormName);
   if( !doReplace && ptb ) {
      return;
   }
   // Does the form really exist?
   int index = find_index(FormName,oi2type(OI_FORM));
   if ( index == 0 ) {
      return;
   }

   // Create toolbar record
   _TOOLBAR tb;
   tb.FormName = FormName;
   tb.tbflags = tbFlags;
   tb.restore_docked = defaultVisible;
   tb.show_x = 0;
   tb.show_y = 0;
   tb.show_width  = 0;
   tb.show_height = 0;
   tb.docked_area = area;
   tb.docked_row = 0;
   tb.docked_x = 0;
   tb.docked_y = 0;
   tb.docked_width  = 0;
   tb.docked_height = 0;
   tb.tabgroup = 0;
   tb.tabOrder = 0;
   tb.auto_width = 0;
   tb.auto_height = 0;
   tb.rflags = 0;

   // Already in list?
   if ( ptb ) {
      // Replace item with new copy
      *ptb = tb;

   } else {
      // Append to list of toolbars
      def_toolbartab[def_toolbartab._length()] = tb;
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
}

// "Dockable" menu item on _toolbar_menu
int _OnUpdate_tbDockableToggle(CMDUI &cmdui, int target_wid, _str command)
{
   if (!target_wid) return MF_GRAYED;
   int formwid = target_wid.p_active_form;
   if ( !_IsQToolbar(formwid) ) {
      return MF_GRAYED;
   }

   _tbNewVersion();
   FormName := formwid.p_name;
   _TOOLBAR* ptb = _tbFind(FormName);
   if ( !ptb ) {
      return MF_GRAYED;
   }
   allow_docking := _tbIsDockingAllowed(ptb);
   if ( allow_docking ) {
      allow_docking = 0 != ( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
   }
   if ( allow_docking ) {
      return (MF_ENABLED | MF_CHECKED);
   } else {
      // Floating or docking not allowed
      return (MF_ENABLED | MF_UNCHECKED);
   }
}

/**
 * Toggle dockability on tool window.
 * 
 * @param wid (optional). Window id of tool window. Uses the active form
 *            if not specified.
 */
_command void tbDockableToggle(int wid=0)
{
   if( isEclipsePlugin() ) {
      return;
   }

   if( wid == 0 ) {
      // Use active form
      wid = p_active_form;
   }
   if ( !_IsQToolbar(wid) ) {
      return;
   }

   _tbNewVersion();
   FormName := wid.p_name;
   _TOOLBAR* ptb = _tbFind(FormName);
   if ( !ptb ) {
      return;
   }

   allow_docking := _tbIsDockingAllowed(ptb);
   if ( allow_docking ) {
      allow_docking = 0 != ( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
   }
   // Toggle
   allow_docking = !allow_docking;
   _tbQToolbarSetDockable(wid, allow_docking);
   if ( allow_docking ) {
      ptb->tbflags |= TBFLAG_ALLOW_DOCKING;
   } else {
      ptb->tbflags &= ~(TBFLAG_ALLOW_DOCKING);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

// "Floating" menu item on _toolbar_menu
int _OnUpdate_tbFloatingToggle(CMDUI& cmdui, int target_wid, _str command)
{
   if (!target_wid) return MF_GRAYED;
   int formwid = target_wid.p_active_form;
   if ( !_IsQToolbar(formwid) ) {
      return (MF_GRAYED | MF_UNCHECKED);
   }
   return _tbQToolbarOnUpdateFloatingToggle(formwid);
}

/**
 * Toggle between floating/docked toolbar.
 * 
 * @param wid (optional). Window id of toolbar. Uses the active
 *            form if not specified.
 */
_command void tbFloatingToggle(int wid=0)
{
   if ( isEclipsePlugin() ) {
      return;
   }

   if ( wid==0 ) {
      // Use active form
      wid = p_active_form;
   }
   if ( !_IsQToolbar(wid) ) {
      return;
   }

   _tbNewVersion();
   FormName := wid.p_name;
   _TOOLBAR* ptb = _tbFind(FormName);
   if ( !ptb ) {
      return;
   }
   _tbQToolbarFloatingToggle(wid);
}

// "Movable" menu item on _toolbar_menu
int _OnUpdate_tbMovableToggle(CMDUI& cmdui, int target_wid, _str command)
{
   if (!target_wid) return MF_GRAYED;
   int formwid = target_wid.p_active_form;
   if ( !_IsQToolbar(formwid) ) {
      return MF_GRAYED;
   }
   return _tbQToolbarOnUpdateMovableToggle(formwid);
}

/**
 * Toggle movable toolbar.
 * 
 * @param wid (optional). Window id of toolbar. Uses the active 
 *            form if not specified.
 */
_command void tbMovableToggle(int wid=0)
{
   if ( isEclipsePlugin() ) {
      return;
   }

   if ( wid == 0 ) {
      // Use active form
      wid = p_active_form;
   }
   if ( !_IsQToolbar(wid) ) {
      return;
   }

   _tbNewVersion();
   FormName := wid.p_name;
   _TOOLBAR* ptb = _tbFind(FormName);
   if ( !ptb ) {
      return;
   }
   _tbQToolbarMovableToggle(wid);
}

int _tbGetWid(_str FormName)
{
   int wid = _find_formobj(FormName, 'n');
   return wid;
}

void _tbAdjustTabIndexes(int toolbar_wid,int tab_index,int adjust)
{
   child := 0;
   first_child := 0;
   first_child=child=toolbar_wid.p_child;
   if (child) {
      // Adjust tab indexes
      for (;;) {
         if (child.p_tab_index>=tab_index) {
            child.p_tab_index+=adjust;
         }
         child=child.p_next;
         if(child==first_child) break;
      }
   }
}

void _tbRedisplay(int toolbar_wid)
{
   FormName := toolbar_wid.p_name;
   if ( !_IsQToolbar(toolbar_wid) ) {
      return;
   }

   tbstate := "";
   _QToolbarGetState(tbstate);
   toolbar_wid._tbSmartDeleteWindow();
   // Correct the parent
   tbShow(FormName);
   _QToolbarSetState(tbstate);
   //toolbar_wid = _tbIsVisible(FormName);
   toolbar_wid = _tbGetWid(FormName);
   if ( toolbar_wid ) {
      _QToolbarUpdateSize(toolbar_wid);
   }
}

int _tbGetFlags(_str tbName)
{
   for ( i := 0; i < def_toolbartab._length(); ++i ) {
      if ( def_toolbartab[i].FormName == tbName ) {
         return def_toolbartab[i].tbflags;
      }
   }
   return 0;
}

bool _tbIsCustomizeableToolbar(int index)
{
   if ( !_default_option(VSOPTION_LOCALSTA) ) {
      return false;
   }
   name := name_name(index);
   if ( substr(name,1,3) != '-tb' ) {
      return false;
   }
   name = translate(name, '_', '-');
   int i;
   for ( i = 0; i < init_toolbartab._length(); ++i ) {
      if ( !_isMac() && init_toolbartab[i].FormName == '_tbunified_form') {
         continue;
      }
      if ( init_toolbartab[i].FormName == name &&
           0 != (init_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) ) {
         return true;
      }
   }
   return false;
}

// Convenience class for testing whether toolbar meets supported feature requirements.
class ToolbarFeatures {
   private int m_rmask;
   ToolbarFeatures() {
      m_rmask = 0;
      m_rmask |= _haveBuild()                 ? TB_REQUIRE_BUILD           : 0;
      m_rmask |= _haveDebugging()             ? TB_REQUIRE_DEBUGGING       : 0;
      m_rmask |= _haveContextTagging()        ? TB_REQUIRE_CONTEXT_TAGGING : 0;
      m_rmask |= _haveVersionControl()        ? TB_REQUIRE_VERSION_CONTROL : 0;
      m_rmask |= _haveProMacros()             ? TB_REQUIRE_PRO_MACROS      : 0;
      m_rmask |= _haveBeautifiers()           ? TB_REQUIRE_BEAUTIFIER      : 0;
      m_rmask |= _haveRefactoring()           ? TB_REQUIRE_REFACTORING     : 0;
      m_rmask |= _haveRealTimeErrors()        ? TB_REQUIRE_REALTIMEERRORS  : 0;
      m_rmask |= _haveProDiff()               ? TB_REQUIRE_PRO_DIFF        : 0;
      m_rmask |= _haveMerge()                 ? TB_REQUIRE_MERGE           : 0;
      m_rmask |= _haveCurrentContextToolBar() ? TB_REQUIRE_CURRENT_CONTEXT : 0;
      m_rmask |= _haveXMLValidation()         ? TB_REQUIRE_XML_VALIDATION  : 0;
   }
   /**
    * Test requirement flag(s) and return true if all 
    * <code>rflags</code> are supported. 
    * 
    * @param rflags One or more ToolbarRequireFlag. 
    */
   bool testFlags(int rflags) {
      return (m_rmask & rflags) == rflags;
   }
   bool testForm(_str formName) {
      _TOOLBAR* tb = _tbFind(formName);
      if ( tb ) {
         return (m_rmask & tb->rflags) == tb->rflags;
      }
      return false;
   }
};

bool tbIsAllowed(_str form_name, _TOOLBAR* tb=null)
{
   if ( isEclipsePlugin() ) {
      return false;
   }

   tb = tb == null ? _tbFind(form_name) : tb;
   if ( null == tb ) {
      return false;
   }
   ToolbarFeatures features;
   if ( !features.testFlags(tb->rflags) ) {
      return false;
   }

   int index = find_index(form_name, oi2type(OI_FORM));
   if ( !index ) {
      return false;
   }
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

void toggle_toolbar(_str FormName, _str PutFocusOnCtlName="")
{
   if (!tbIsAllowed(FormName)) {
      return;
   }
   wid := _tbGetWid(FormName);
   if (wid > 0) {
      tbHide(FormName);
   } else {
      tbShow(FormName);
      wid = _tbGetWid(FormName);
      if (wid && (PutFocusOnCtlName != '')) {
         ctlwid := wid._find_control(PutFocusOnCtlName);
         if (ctlwid > 0) {
            ctlwid._set_focus();
         }
      }
   }
}

/**
 * Activate the toolbar and put focus on the control given.
 * 
 * @param FormName          Name of the toolbar form to 
 *                          activate.
 * @param PutFocusOnCtlName The child control in the tool window to
 *                          give focus to after activation.
 * @param DoSetFocus        default true, if false, do not change focus
 * 
 * @return The wid of the toolbar; otherwise 0.
 */
int activate_toolbar(_str FormName, _str PutFocusOnCtlName, bool DoSetFocus=true)
{
   if ( !tbIsAllowed(FormName) ) {
      return 0;
   }
   wid := _tbGetWid(FormName);
   if ( 0 == wid ) {
      tbShow(FormName);
      wid = _tbGetWid(FormName);
   }
   if ( wid > 0 && DoSetFocus ) {
      ctlwid := wid._find_control(PutFocusOnCtlName);
      if ( ctlwid > 0 ) {
         ctlwid._set_focus();
      }
   }
   return wid;
}

_command void toggle_docked(...)  name_info(','VSARG2_EDITORCTL)
{
   FormName := strip(lowcase(arg(1)));
   wid := 0;
   _TOOLBAR* ptb = null;
   int i;
   for( i = 0; i < def_toolbartab._length(); ++i ) {
      ptb = &def_toolbartab[i];
      wid = find_index(ptb->FormName, oi2type(OI_FORM));
      if( wid != 0 ) {
         if ( strieq(wid.p_caption, FormName) ) {
            break;
         }
      }
      ptb = null;
      wid = 0;
   }

   _tbNewVersion();
   if ( wid != 0 ) {
      FormName = wid.p_name;
   }
   wid = _find_formobj(FormName, 'n');
   if ( wid == 0 ) {
      _message_box('Toolbar 'FormName' not found');
      return;
   }
   was_floating := 0 != _QToolbarGetFloating(wid);
   _QToolbarSetFloating(wid, (int)!was_floating);
}

_command void tbHide(_str FormName='', bool quiet=true) name_info(FORM_ARG',')
{
   focus_wid := _get_focus();
   FormName = arg(1);
   index := 0;

   _TOOLBAR* ptb = _tbFind(FormName);
   if ( !ptb ) {
      if ( !quiet ) {
         _message_box('Toolbar 'FormName' not found');
      }
      return;
   }
   //int wid = _tbIsVisible(FormName);
   wid := _tbGetWid(FormName);
   if ( wid == 0 ) {
      if ( !quiet ) {
         _message_box('This toolbar is not visible');
      }
      return;
   }
   tbClose(wid);
   if ( focus_wid != 0 && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
}

/**
 * For the current list of toolbars, guarantee:<br>
 * <ol>
 *   <li>All toolbars have sane data for docked/undocked states. </li>
 *   <li>All available toolbars are in the list of current toolbars. </li>
 * </ol>
 */
void _tbNewVersion()
{
   int FormName_hashtab:[];
   int i;
   for( i=0;i<def_toolbartab._length();++i ) {
      // IF we have multiple occurrences of the same toolbar
      if( 0!=FormName_hashtab._indexin(def_toolbartab[i].FormName) ) {
         def_toolbartab._deleteel(i);
         continue;
      }
      FormName_hashtab:[def_toolbartab[i].FormName]=i;
      if( !isinteger(def_toolbartab[i].restore_docked) ||
          !isinteger(def_toolbartab[i].tabgroup) ||
          !isinteger(def_toolbartab[i].auto_width) ) {
         //say('fixed it i='i);
         def_toolbartab[i].restore_docked=false;
         def_toolbartab[i].show_x=0;
         def_toolbartab[i].show_y=0;
         def_toolbartab[i].show_width=0;
         def_toolbartab[i].show_height=0;

         def_toolbartab[i].docked_area=DOCKINGAREA_NONE;
         def_toolbartab[i].docked_row=0;
         def_toolbartab[i].docked_x=0;
         def_toolbartab[i].docked_y=0;
         def_toolbartab[i].docked_width=0;
         def_toolbartab[i].docked_height=0;

         def_toolbartab[i].tabgroup=0;
         def_toolbartab[i].tabOrder= -1;

         def_toolbartab[i].auto_width=0;
         def_toolbartab[i].auto_height=0;
      }
      // .rflags is a new member for v19.0.2.
      // This check covers the case of a user-added toolbar that gets
      // migrated without the new .rflags member. If it is one of our
      // own (system) toolbars, then it will get reset a little later.
      if ( !isinteger(def_toolbartab[i].rflags) ) {
         //say('fixed it i='i);
         def_toolbartab[i].rflags=0;
      }
   }
   // Make sure all available toolbars are in the users
   // list of toolbars
   for( i=0;i<init_toolbartab._length();++i ) {
      if ( !_isMac() && init_toolbartab[i].FormName == '_tbunified_form') {
         continue;
      }

      if( 0==FormName_hashtab._indexin(init_toolbartab[i].FormName) ) {
         def_toolbartab[def_toolbartab._length()]=init_toolbartab[i];
      } else {
         j := FormName_hashtab:[init_toolbartab[i].FormName];
         def_toolbartab[j].rflags = init_toolbartab[i].rflags;
      }
   }
}

void _tbSetToolbarEnable(int wid, CMDUI &cmdui=null)
{
   orig_view_id := p_window_id;
   int target_wid;
   if ( _no_child_windows() ) {
      target_wid = 0;
   } else {
      target_wid = _mdi.p_child;
   }
   if ( cmdui._isempty() ) {
      cmdui.menu_handle = 0;
      cmdui.button_wid = 1;
      _OnUpdateInit(cmdui, target_wid);
   }

   //say('found 'wid.p_name);
   int first_child, child;
   first_child = child = wid.p_child;
   if( child ) {
      for( ;; ) {
         if( child.p_object == OI_IMAGE &&
             (child.p_caption != '' || child.p_picture) ) {
            cmdui.button_wid = child;
            //say('got here target_wid='target_wid);
            int mfflags = _OnUpdate(cmdui, target_wid, child.p_command);
            if( mfflags ) {
               enabled := !testFlag(mfflags, MF_GRAYED);
               if ( child.p_enabled != enabled ) {
                  child.p_enabled = enabled;
               }
               visible := !testFlag(mfflags, MF_REQUIRES_PRO);
               if ( child.p_visible != visible ) {
                  child.p_visible = visible;
               }
            }
         }
         child = child.p_next;
         if( child == first_child ) {
            break;
         }
      }
      // Update image controls
      //wid.refresh('w');
   }
   activate_window(orig_view_id);
}

void _tbOnUpdate(bool alwaysUpdate=false)
{
   if (!alwaysUpdate && (_idle_time_elapsed()<250 || !_tbQRefreshBy())) {
      return;
   }
   if (!alwaysUpdate && _tbDragDropMode()) {
      return;
   }
   /*
        _tbQRefreshBy and the VSTBREFRESHBY_??? constants
        for debugging a problem where _tbOnUpdate does
        processing where no processing should be necessary.

        The undo, redo, and switching buffers cause _tbOnUpdate
        processing on every key stroke.  There are other commands
        where processing is required but they are more obvious
        and less important.

        The idle time check correct performance problems
        where a particular keystroke cause _tbOnUpdate
        processing.
   */
   //say('RefreshBy='_tbQRefreshBy());
   bool hashtab:[];
   int i;
   for (i=0;i<def_toolbartab._length();++i) {
      if (def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) {
         hashtab:[def_toolbartab[i].FormName]=true;
      }
   }
   CMDUI cmdui;
   cmdui.menu_handle=0;
   target_wid := 0;
   if (_no_child_windows()) {
      target_wid=0;
   } else {
      target_wid=_mdi.p_child;
   }
   cmdui.button_wid=1;

   _OnUpdateInit(cmdui,target_wid);
   int wid;
   for( wid=1;wid<=_last_window_id();++wid ) {
      if( _iswindow_valid(wid) ) {
         if( wid.p_object==OI_FORM &&
             hashtab._indexin(wid.p_name) ) {

            _tbSetToolbarEnable(wid,cmdui);
         }
      }
   }
   _tbSetRefreshBy(0);
   refresh();
}

void _switchbuf_toolbars()
{
}

/**
 * Save/serialize state of tool window.
 * <p>
 * State is saved for a tool window just before a tool window is
 * destroyed. Examples include closing the tool window, a
 * drag-drop operation, or Auto Hide toggle (i.e. toggling Auto
 * Hide off on a tool window). When the tool window is
 * recreated, the state information is passed to its restore
 * callback (see explanation of callbacks below).
 * <p>
 * If it is important for your tool window to distinguish between a
 * close operation (e.g. hitting the 'X') and an operation that would
 * destroy and immediately recreate the tool window (e.g. dock/undock,
 * autohide, autoshow), then your callback must act on the 'closing'
 * argument. For example, your tool window may not want to save the
 * state of the tool window if the user is simply closing it, in which
 * case the callback would return immediately if closing==true. The
 * 'state' output argument is ignored when closing==true, since it
 * would be the callback's responsibility to save/cache any state
 * data long-term.
 * <p>
 * Tool windows can register a callback to save/restore
 * state by defining 2 global functions:
 * <pre>
 * void _tbSaveState_&lt;ToolWindowFormName&gt;(typeless& state, bool closing)
 * void _tbRestoreState_&lt;ToolWindowFormName&gt;(typeless& state, bool opening)
 * </pre>
 * For example, callbacks registered for the References tool
 * window would be: _twSaveState__tbtagrefs_form,
 * _twRestoreState__tbtagrefs_form. When a save/restore callback
 * is called, the active window is always the wid of the
 * saved/restored tool window.
 * 
 * @param state   (out). Tool window defined state information.
 * @param closing true=Tool window is being closed (not docked,
 *                undocked, autohidden, or autoshown).
 */
void _tbSaveState(typeless& state, bool closing)
{
   state._makeempty();
   formName := p_window_id.p_name;
   if( formName != "" ) {
      index := find_index('_tbSaveState_':+formName,PROC_TYPE);
      if( index > 0 && index_callable(index) ) {
         call_index(state,closing,index);
      }
   }
}

/**

 */
void _tbRestoreState(typeless& state, bool opening)
{
   formName := p_window_id.p_name;
   if( formName != "" ) {
      index := find_index('_tbRestoreState_':+formName,PROC_TYPE);
      if( index > 0 && index_callable(index) ) {
         call_index(state,opening,index);
      }
   }
}
