////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50034 $
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
#import "dockchannel.e"
#import "bufftabs.e"
#import "dlgeditv.e"
#import "dlgman.e"
#import "main.e"
#import "menu.e"
#import "picture.e"
#import "qtoolbar.e"
#import "sstab.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbcontrols.e"
#import "tbdockchannel.e"
#import "tbpanel.e"
#import "tbgrabbar.e"
#import "tbprops.e"
#import "tbtabgroup.e"
#import "tbview.e"
#require "sc/controls/RubberBand.e"
#require "se/util/MousePointerGuard.e"
#require "sc/util/Point.e"
#require "sc/lang/DelayTimer.e"
#import "dlgman.e"
#endregion

boolean def_tbreset_with_file_tabs=false;

  // This table is modified during editor execution and
  // autorestored.
  _TOOLBAR def_toolbartab[];
  // This table should not be changed during editor execution.
  // def_toolbartab is initialized to this table.
  static _TOOLBAR init_toolbartab[]={
     {"_tbstandard_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbproject_tools_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbtools_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbedit_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbseldisp_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbprops_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbslickc_stack_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbprojects_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbproctree_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbcbrowser_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbfind_symbol_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_DISMISS_LIKE_DIALOG|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbfilelist_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbopen_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbFTPOpen_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbFTPClient_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbunittest_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbsearch_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbtagwin_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbtagrefs_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbshell_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tboutputwin_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbbookmarks_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbxml_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbhtml_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbtagging_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbcontext_form",TBFLAG_ALLOW_DOCKING,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbbufftabs_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS|TBFLAG_NO_CAPTION,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebugbb_form",TBFLAG_LIST_WITH_DEBUG_TOOLBARS|TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_stack_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_locals_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_members_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_watches_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_autovars_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_threads_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_classes_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_regs_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_memory_form",TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_breakpoints_form",TBFLAG_LIST_WITH_DEBUG_TOOLBARS|TBFLAG_WHEN_DEBUGGER_SUPPORTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_exceptions_form",TBFLAG_LIST_WITH_DEBUG_TOOLBARS|TBFLAG_WHEN_DEBUGGER_SUPPORTED_ONLY|TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdebug_sessions_form",TBFLAG_ALLOW_DOCKING|TBFLAG_LIST_WITH_DEBUG_TOOLBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbfind_form",TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbregex_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbdeltasave_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbannotations_browser_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbmessages_browser_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbclass_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbclipboard_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
     {"_tbnotification_form", TBFLAG_ALWAYS_ON_TOP|TBFLAG_SIZEBARS|TBFLAG_DISMISS_LIKE_DIALOG,0,0,0,0,0,0,0,0,0,0,0,0,0},
#if __MACOSX__
     {"_tbunified_form",TBFLAG_NEW_TOOLBAR|TBFLAG_UNIFIED_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
#endif
     {"_tbandroid_form",TBFLAG_NEW_TOOLBAR,0,0,0,0,0,0,0,0,0,0,0,0,0},
  };

static boolean gIgnoreInsertRestoreRow;
// Need this on Mac in order to avoid get_event() on FocusIn when clicking
// on a tool window caption would also activate the application.
static boolean gAppActivated;

int def_toolbar_options=0;
int def_toolbar_autohide_delay=TBAUTOHIDE_DELAY_DEFAULT;
int def_dock_channel_options=0;
int def_dock_channel_delay=DOCKCHANNEL_AUTO_DELAY;

definit()
{
   if( def_toolbartab==null ) {
      def_toolbartab=init_toolbartab;
   }

   gIgnoreInsertRestoreRow=false;
   //def_toolbartab._makeempty();
   //gbbdockinfo._makeempty();
   if( arg(1)!='L' ) {
      gbbdockinfo._makeempty();
      //old_gbbdockinfo._makeempty();
   }

   gAppActivated = _AppActive();
}

//
// Minimum (cx,cy) mouse movement before a drag operation becomes visible
//

#define CXDRAG_MIN  (40 intdiv _twips_per_pixel_x())
#define CYDRAG_MIN  (40 intdiv _twips_per_pixel_y())

void _UpdateToolbars()
{
   // (16.1) Called from _firstinit()
   int i,n=def_toolbartab._length();
   for (i=0; i<n; ++i) {
      if (def_toolbartab[i].FormName=="_tbcontext_form") {
         if (def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) {
            def_toolbartab[i].tbflags &= ~TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED;
            _config_modify_flags(CFGMODIFY_DEFVAR);
         }
         // This is a toolbar
         if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
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
      } 

      // Toolbars have no need for any of this
      if ((def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) == 0) {
         def_toolbartab[i].restore_docked=false;
         def_toolbartab[i].show_x=0;
         def_toolbartab[i].show_y=0;
         def_toolbartab[i].show_width=0;
         def_toolbartab[i].show_height=0;

         def_toolbartab[i].docked_area=0;
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
   }

   // (18.0) Turn off file tabs tool window, unless they want to
   // restore their configuration including it.
   if (!def_tbreset_with_file_tabs && def_one_file != "") {
      _post_call(tbHide, "_tbbufftabs_form");
   }

   _tbNewVersion();
}

/**
 * Return the index of the last palette in the docking info
 * model. If there are no floating palettes, then this will be
 * DOCKINGAREA_LAST. If there are floating palettes, then this will
 * be DOCKINGAREA_LAST + number-of-floating-palettes.
 * 
 * @return The index of last palette.
 */
int _bbdockPaletteLastIndex()
{
   // -1 because we do not count gbbdockinfo[0]
   int index = gbbdockinfo._length() - 1;
   return ( (index < DOCKINGAREA_LAST) ? DOCKINGAREA_LAST : index );
   //return ( gbbdockinfo._length() - 1 );
}

/**
 * Number of elements in a palette.
 * 
 * @param index Palette index of.
 * 
 * @return Number of elements in palette. 0 if no elements or
 *         palette does not exist.
 */
int _bbdockPaletteLength(int index)
{
   if( index <= _bbdockPaletteLastIndex() ) {
      return ( gbbdockinfo[index]._length() );
   }
   // No palette by that index
   return 0;
}

/**
 * Retrieve floating or docked palette parent window of child 
 * window passed in. If childWid=0, then the active window is 
 * used. 
 * 
 * @param wid (optional). Child window for which the parent
 *            palette window is to be retrieved. Set to 0 to
 *            use the active window.
 *            Defaults to 0.
 * 
 * @return Window id of palette.
 */
int _bbdockPaletteGetFromWid(int wid=0)
{
   if( wid == 0 ) {
      wid=p_window_id;
   }
   if( wid.p_DockingArea > 0 ) {
      // Dock palette
      return ( _mdi._bbdockPaletteGet(wid.p_DockingArea) );
   }
   // Floating palette
   int parent = wid;
   while( parent > 0 ) {
      if( parent.p_name == "_dock_palette_form" ) {
         return parent;
      }
      parent=parent.p_parent;
   }
   // No palette parent for this child window
   return 0;
}

/**
 * Retrieve floating or docked palette window by palette index. 
 * If retrieving a docked palette, then index is 
 * DOCKINGAREA_FIRST..DOCKINGAREA_LAST. If retrieving a floating
 * palette, then index is >DOCKINGAREA_LAST.
 * 
 * @param index Palette index of palette window to retrieve.
 * 
 * @return Window id of palette.
 */
int _bbdockPaletteGet(int index)
{
   // Side palettes are managed with _GetDockPalette, _LoadDockPalette APIs, so let
   // them handle this.
   if( index >= DOCKINGAREA_FIRST && index <= DOCKINGAREA_LAST ) {
      // Side palette
      return ( _mdi._GetDockPalette(index) );
   }
   // Floating palette
   if( index <= _bbdockPaletteLastIndex() ) {
      // Floating palette. Figure it out from parent of first window at index.
      int j;
      for( j=0; j<gbbdockinfo[index]._length(); ++j ) {
         if( gbbdockinfo[index][j].wid > 0 ) {
            int parent = _bbdockPaletteGetFromWid(gbbdockinfo[index][j].wid);
            if( parent > 0 ) {
               return parent;
            }
         }
      }
   }
   // No palette window associated with index
   return 0;
}

/**
 * Create a side palette.
 * 
 * @param area One of DOCKINGAREA_*.
 * 
 * @return Window id of new palette.
 */
int _paletteCreateSide(DockingArea area)
{
   int index = find_index("_dock_palette_form",oi2type(OI_FORM));
   int orig_wid = p_window_id;
   _mdi._LoadDockPalette(index,area);
   p_window_id=orig_wid;
   int wid = _bbdockPaletteGet(area);
#ifdef not_finished
   switch( area ) {
   case DOCKINGAREA_TOP:
      wid.p_backcolor = _rgb(255,0,0);
      break;
   case DOCKINGAREA_LEFT:
      wid.p_backcolor = _rgb(0,255,0);
      break;
   case DOCKINGAREA_RIGHT:
      wid.p_backcolor = _rgb(0,0,255);
      break;
   case DOCKINGAREA_BOTTOM:
      wid.p_backcolor = _rgb(255,255,0);
      break;
   }
#endif
   return wid;
}

/**
 * Create a floating palette.
 * 
 * @return Window id of new palette.
 */
int _paletteCreateFloating()
{
   int index = find_index("_dock_palette_form",oi2type(OI_FORM));
   int orig_wid = p_window_id;
   int wid = _load_template(index,_mdi,'H');
   p_window_id=orig_wid;
   return wid;
}

/**
 * Find palette index in docking info model from window id.
 * 
 * @param wid Palette window id or a child window of a palette
 *            window.
 * 
 * @return Index >0 into docking info model array. 0 if not
 *         found.
 */
static int _bbdockPaletteIndexFromWid(int wid)
{
   if( wid <= 0 ) {
      // Invalid window id
      return 0;
   }
   if( wid.p_DockingArea > 0 ) {
      // Side palette
      return ( (int)wid.p_DockingArea );
   }
   // Look for a floating palette
   int paletteWid = _bbdockPaletteGetFromWid(wid);
   int i;
   for( i=DOCKINGAREA_LAST+1; i<=_bbdockPaletteLastIndex(); ++i ) {
      int j;
      for( j=0; j<gbbdockinfo[i]._length(); ++j ) {
         if( gbbdockinfo[i][j].wid > 0 ) {
            int parent = _bbdockPaletteGetFromWid(gbbdockinfo[i][j].wid);
            if( parent == paletteWid ) {
               // Found it
               return i;
            }
         }
      }
   }
   // Palette not found in the docking model
   return 0;
}

/**
 * Determine orientation of palette at index.
 * 
 * @param index Index of palette in docking model.
 * 
 * @return One of TBORIENT_* orientation constants.
 */
static int _bbdockPaletteOrientation(int index)
{
   if( index == DOCKINGAREA_TOP || index == DOCKINGAREA_BOTTOM ) {
      return TBORIENT_HORIZONTAL;
   } else if( index == DOCKINGAREA_LEFT || index == DOCKINGAREA_RIGHT ) {
      return TBORIENT_VERTICAL;
   }
   // Floating palette case
   int palette_wid = _bbdockPaletteGet(index);
   int orient = _GetDialogInfoHt("orientation",palette_wid,true);
   return orient;
}

/**
 * Determine orientation of palette that contains window.
 * 
 * @param wid (optional). Window id to test for orientation. If
 *            set to 0, then current window is used. Defaults to
 *            0.
 * 
 * @return One of TBORIENT_* orientation constants.
 */
static int _bbdockPaletteOrientationFromWid(int wid=0)
{
   if( wid == 0 ) {
      wid=p_window_id;
   }
   if( wid.p_DockingArea == DOCKINGAREA_TOP || wid.p_DockingArea == DOCKINGAREA_BOTTOM ) {
      return TBORIENT_HORIZONTAL;
   } else if( wid.p_DockingArea == DOCKINGAREA_LEFT || wid.p_DockingArea == DOCKINGAREA_RIGHT ) {
      return TBORIENT_VERTICAL;
   }
   // Floating palette case
   int palette_wid = _bbdockPaletteGetFromWid(wid);
   int orient = _GetDialogInfoHt("orientation",palette_wid,true);
   return orient;
}

int _bbdockQRestoreRow(DockingArea area, int i)
{
   for( ;;++i ) {
      if( i>=_bbdockPaletteLength(area) ) {
         return 0;
      }
      if( gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK ) {

         if( 0!=gbbdockinfo[area][i].docked_row ) {
            return (gbbdockinfo[area][i].docked_row);
         }
      }
   }
}

int _bbdockQMaxRestoreRow(DockingArea area)
{
   int i;
   int max_restore_row = 0;
   for( i=_bbdockPaletteLength(area)-1;i>=0;--i ) {

      if( gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK ) {

         if( 0!=gbbdockinfo[area][i].docked_row ) {
            max_restore_row=gbbdockinfo[area][i].docked_row;
            break;
         }
      }
   }
   for( i=0;i<def_toolbartab._length();++i ) {

      if( def_toolbartab[i].docked_area==area ) {

         if( def_toolbartab[i].docked_row>max_restore_row ) {
            max_restore_row=def_toolbartab[i].docked_row;
         }
      }
   }
   return max_restore_row;
}

int _bbdockQMaxTabGroup()
{
   int max_tabgroup = 0;
   int area;
   for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {

      int i;
      for( i=_bbdockPaletteLength(area)-1; i>=0; --i ) {

         int wid = gbbdockinfo[area][i].wid;
         if( wid>0 && wid!=BBDOCKINFO_ROWBREAK ) {

            //say('_bbdockQMaxTabGroup: area='area'  i='i'  wid='wid'='wid.p_name);
            if( gbbdockinfo[area][i].tabgroup > max_tabgroup ) {
               max_tabgroup=gbbdockinfo[area][i].tabgroup;
            }
         }
      }
   }
   int i;
   for( i=0; i<def_toolbartab._length(); ++i ) {

      if( def_toolbartab[i].tabgroup > max_tabgroup ) {
         max_tabgroup=def_toolbartab[i].tabgroup;
      }
   }
   return max_tabgroup;
}

static void _bbdockInsertRestoreRow(DockingArea area, int docked_row)
{
   if( gIgnoreInsertRestoreRow ) {
      return;
   }
   //_message_box('_bbdockInsertRestoreRow docked_row='docked_row' len='_bbdockPaletteLength(area));
   int i;
   for( i=0;;++i ) {
      if( i>=_bbdockPaletteLength(area) ) {
         break;
      }
      if( gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK ) {

         if( gbbdockinfo[area][i].docked_row>=docked_row ) {
            ++gbbdockinfo[area][i].docked_row;
            //_message_box('adjust i='i' new row='gbbdockinfo[area][i].docked_row);
         } else {
            //_message_box('no adjust i='i' row='gbbdockinfo[area][i].docked_row' docked_row='docked_row);
         }
      }
   }
   //_message_box('tbInsertRestoreRow: docked_row='docked_row);
   for( i=0;i<def_toolbartab._length();++i ) {

      if( def_toolbartab[i].docked_area==area ) {

         if( def_toolbartab[i].docked_row>=docked_row ) {
            ++def_toolbartab[i].docked_row;
         }
      }
   }
}

/**
 * Create tool window from resource_index as a child of parent_wid.
 * 
 * @param tbflags
 * @param resource_index
 * @param parent_wid
 * 
 * @return Window id (wid) of loaded tool window.
 */
int _tbLoadTemplate(int tbflags, int resource_index, int parent_wid)
{
   int orig_wid = p_window_id;
   if (0 == (tbflags & TBFLAG_SIZEBARS)) {
      return _tbLoadQToolbar(resource_index, tbflags, true);
   }

   _str noBorder="N";
   int wid = _load_template(resource_index,parent_wid,'HP':+noBorder);
   p_window_id=orig_wid;
   return wid;
}

/**
 * If the tool window being created is sizeable ( tbflags&TBFLAG_SIZEBARS !=0 ),
 * and is not being tab-linked into a tabgroup,
 * then it is loaded as a child of a _tbpanel_form form so that it can be decorated
 * with a title bar, close, autohide buttons. If not sizeable (e.g. button bar),
 * then tool window is created as a child of parent_wid. If tabLink==true, then
 * tool window is tab-linked into a new or existing tabgroup.
 * 
 * @param tbflags        Bitwise flags. See TBFLAG_*.
 * @param resource_index
 * @param parent_wid
 * @param tabLink        true=Create or tab-link into a tabgroup.
 * 
 * @return Window id of loaded tool window.
 * 
 * @see def_toolbar_options
 * @see TBOPTION_OLD_STYLE
 */
int _tbSmartLoadTemplate(int tbflags, int resource_index,
                         int parent_wid, boolean tabLink)
{
   int tbwid = 0;
   if( tabLink ) {
      tbwid=_tbLoadTemplateIntoTabGroup(tbflags,resource_index,parent_wid);

   } else if( 0==(tbflags & TBFLAG_SIZEBARS) ||
       0!=(def_toolbar_options&TBOPTION_OLD_STYLE) ||
       0!=(tbflags & TBFLAG_NO_CAPTION) ) {
      // Button bar OR old-style specified OR TBFLAG_NO_CAPTION tool window.
      // Note:
      // We do not embed button bars into panels since we do not want them to
      // show title bars.
      tbwid=_tbLoadTemplate(tbflags,resource_index,parent_wid);

   } else {
      // Sizeable tool window, so load into a panel
      int panel_wid;
      tbwid=_tbLoadTemplateIntoPanel(tbflags,resource_index,parent_wid,panel_wid);
   }
   return tbwid;
}

/**
 * @param wid Tool window id (the form).
 * 
 * @return The container (e.g. a panel) window id for tool window wid,
 * otherwise return the wid passed in.
 */
int _tbContainerFromWid(int wid)
{
   int container_wid = wid;
#if 1 /* Debug */
   if( wid>0 && !_iswindow_valid(wid) ) {
      say('_tbContainerFromWid: !!!!!! _iswindow_valid('wid') FAILED!');
      _StackDump(1);
   }
#endif
   if( wid>0 && wid!=BBDOCKINFO_ROWBREAK && _iswindow_valid(wid) && !_isContainer(wid) ) {
      int parent = wid.p_parent;
      if( parent>0 ) {
         int parent_form = parent.p_active_form;
         if( parent_form>0 ) {
            if( parent_form.p_name=="_tbpanel_form" || parent_form.p_name=="_bbgrabbar_form" ) {
               container_wid=parent_form;
            }
         }
      }
   }
   return container_wid;
}

int _bbdockContainer(BBDOCKINFO* pdi)
{
   return (_tbContainerFromWid(pdi->wid));
}

int _bbdockTabGroupWid(BBDOCKINFO* pdi)
{
   return (_tbTabGroupWidFromWid(pdi->wid));
}

/**
 * Get the tabgroup at docked location.
 * 
 * @param area
 * @param i
 * @param checkBeforeRowbreak (optional).
 * 
 * @return Tabgroup at docked location. if checkBeforeRowbreak==true, and
 * there is a rowbreak at this location, then the tool window just before
 * the rowbreak is checked for a tabgroup.
 */
static int _bbdockTabGroup(DockingArea area, int i, boolean checkBeforeRowbreak=false)
{
   if( area>=DOCKINGAREA_FIRST && area<=_bbdockPaletteLastIndex() && i>=0 && i<_bbdockPaletteLength(area) ) {

      if( gbbdockinfo[area][i].wid > 0 && gbbdockinfo[area][i].wid!=BBDOCKINFO_ROWBREAK ) {

         return (gbbdockinfo[area][i].tabgroup);

      } else if( checkBeforeRowbreak &&
                 gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK &&
                 (i-1) >= 0 && gbbdockinfo[area][i-1].wid > 0 ) {

         // Check just before rowbreak.
         // This is useful if calling _bbdockInsert just before a rowbreak.

         return (gbbdockinfo[area][i-1].tabgroup);
      }
   }
   return 0;
}

/**
 * Get the tab control child of the specified form.
 * 
 * @param formid
 * 
 * @return Tab control, 0 if no tab control on form.
 */
static int tabControlChild(int formid)
{
   if( !formid.p_child ) {
      return(0);
   }
   int wid = formid.p_child;
   int startwid = wid;
   while( wid!=0 && wid.p_object!=OI_SSTAB ) {
      wid=wid.p_next;
      if( wid==startwid ) break;
   }
   if( wid!=0 && wid.p_object==OI_SSTAB ) {
      return(wid);
   }
   return(0);
}

/**
 * This method operates on MDI objects only.
 * Use _bbdockFindWid to locate a tool window after it is created (useful
 * if you need to find a tabgroup to tab-link into).
 *
 * @param area (in,out). One of DOCKINGAREA_* constants
 *               to indicate which side of MDI frame to dock on,
 *               or >DOCKINGAREA_LAST && <=_bbdockPaletteLastIndex()
 *               to indicate an existing floating palette, or <0
 *               to indicate a new floating palette is to be
 *               created and inserted into. If <0, then area
 *               is set to index in docking model on successful
 *               return.
 * @param i      Insert a dockable tool bar at the index position specified. <br>
 *               i== 0  inserts before first tool bar <br>
 *               i== -1  Inserts after last tool bar <br>
 *               Note: <br>
 *               This parameter is ignored if tab-linking into a tabgroup (tabgroup!=0)
 *               because the natural order of the tabgroup is favored. The actual
 *               index position of the tabgroup is found instead and a new
 *               index position calculated based on the tabOrder given. If the
 *               tabgroup does not exist yet, then it is created at the index
 *               position given.
 * @param doRowBreakBefore
 * @param doRowBreakAfter
 * @param resource_index
 * @param tbflags
 * @param twspaceBefore
 * @param tabgroup (optional). Tabgroup identifer to tab-link tool window into.
 *                 Specify 0 if you do NOT want to tab-link into a tabgroup.
 *                 Specify -1 to insert into current tabgroup at this index position.
 *                 Tabgroup is created if it does not exist. Defaults to 0.
 * @param tabOrder (optional). Determines the tab order in a tabgroup that this
 *                 tool window is displayed. Specify -1 to insert at end of
 *                 tab order. Defaults to -1.
 * 
 * @return Wid of created tool window.
 * 
 * @see _bbdockFindWid
 */
static int _bbdockInsert(int& area, int i, boolean doRowBreakBefore, boolean doRowBreakAfter,
                         int resource_index, int tbflags, int twspaceBefore,
                         int tabgroup=0, int tabOrder=-1)
{
   //say('_bbdockInsert: area='area);
   //say('_bbdockInsert: doRowBreakBefore='doRowBreakBefore);
   //say('_bbdockInsert: doRowBreakAfter='doRowBreakAfter);
   //say('_bbdockInsert: resource_index='resource_index'  name_name('resource_index')='name_name(resource_index));
   //say('_bbdockInsert: tbflags='tbflags);
   //say('_bbdockInsert: twspaceBefore='twspaceBefore);
   //say('_bbdockInsert: tabgroup='tabgroup);
   //say('_bbdockInsert: tabOrder='tabOrder);

   //
   // Case analysis for index i:
   // 
   // * i >= 0
   //   Insert at index i on area.
   // 
   // * i < 0
   //   Insert after last index on area.
   //
   if( i<0 ) {
      i=_bbdockPaletteLength(area);
      if( (i-1) >= 0 && gbbdockinfo[area][i-1].wid==BBDOCKINFO_ROWBREAK) {

         // Insert before the last row break
         if( doRowBreakBefore ) {
            doRowBreakBefore=false;
            doRowBreakAfter=true;
            //_message_box('got here');

         } else {
            --i;
         }
      }
   }

   //
   // Case analysis for tabgroup:
   // 
   // * tabgroup == 0
   //   Dock at index i on area, no tabgroup.
   // 
   // * tabgroup > 0
   //   - If tabgroup does not already exist, then create this tabgroup at
   //     index i.
   //   - If tabgroup already exists on a different side (i.e. not area),
   //     then create a new tabgroup on area at index i.
   //   - If tabgroup already exists on area, then insert into existing
   //     tabgroup at tabOrder. Index i is ignored.
   // 
   // * tabgroup < 0
   //   - If a tabgroup does not already exist at index i, then create new
   //     tabgroup at index i.
   //   - If a tabgroup exists at index i, then insert into existing tabgroup
   //     at tabOrder.
   //
   // Case analysis for tabOrder:
   //
   // * tabOrder >= 0
   //   Insert at tabOrder in tabgroup.
   //
   // * tabOrder < 0
   //   Insert after last index in tabgroup.
   //
   boolean newTabGroup=false;
   int tabgroup_wid = 0;
   if( tabgroup>0 ) {
      // An explicit tabgroup was given, so use it if possible
      //say('_bbdockInsert: case 1');

      DockingArea found_area, first_i, last_i;
      if( _bbdockFindTabGroup(tabgroup,found_area,first_i,last_i,area) ) {
         // This tabgroup already exists
         //say('_bbdockInsert: case 1.a');

         if( area!=found_area ) {
            // This tabgroup already exists on a different area, so we
            // must create a new tabgroup for this tool window.
            // Things have to go pretty wrong for this to happen, so
            // clean this mess up.
            //say('_bbdockInsert: case 1.a.i');

#if 1 /* debug */
            _str msg = "Toolbar internal error: Tabgroup already exists on a different side. Fixing...\n\n":+
                       "toolbar="name_name(resource_index)"\n":+
                       "Input: area="area", i="i", tabgroup="tabgroup", tabOrder="tabOrder"\n":+
                       "Found: found_area="found_area", first_i="first_i", last_i="last_i;
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
#endif
            newTabGroup=true;
            tabgroup=_bbdockQMaxTabGroup()+1;
            tabOrder=0;

         } else {
            // The tabgroup exists on the side we are trying to insert into.
            // We do not care about index i since we want to insert into the
            // the existing tabgroup and we already have the tabOrder to tell
            // us where to insert.
            // One scenario where the index i passed in would be completely wrong:
            // 1. Tool window A, B, and C are part of tabgroup 1.
            // 2. Tool window D is docked below tabgroup 1.
            // 3. Tool window A is closed.
            // 4. Tool window D is redocked above tabgroup 1, causing
            //    order change in gbbdockinfo[][].
            // 5. Attempt to restore/show Tool window A at original
            //    position in gbbdockinfo[][] will not work because
            //    order has changed.

            //say('_bbdockInsert: case 1.a.ii');

            tabgroup_wid=_tbTabGroupWidFromWid(gbbdockinfo[area][first_i].wid);
            if( tabOrder<0 ) {
               // Inserting at the end
               i=last_i+1;
               tabOrder=gbbdockinfo[area][last_i].tabOrder+1;

            } else {
               // Inserting at beginning or middle
               int j;
               for( j=first_i; j<=last_i; ++j ) {

                  if( tabOrder <= gbbdockinfo[area][j].tabOrder ) {
                     break;
                  }
               }
               // Insert at this location
               i=j;
               if( tabOrder==gbbdockinfo[area][j].tabOrder ) {
                  // Cannot have 2 tabs in a tabgroup with the same tabOrder.
                  // Shift tabOrder numbers by +1 for every tab after the
                  // one being inserted.
                  for( ;j<=last_i; ++j ) {
                     gbbdockinfo[area][j].tabOrder += 1;
                  }
               }
            }
         }
      } else {
         // Explicit tabgroup that does not exist yet (probably being
         // restored), so creating a new tabgroup.
         //say('_bbdockInsert: case 1.b');

         newTabGroup=true;
      }

   } else if( tabgroup<0 ) {
      // Insert into existing or new tabgroup
      //say('_bbdockInsert: case 2');

      tabgroup=_bbdockTabGroup(area,i,true);
      if( tabgroup>0 ) {
         // Found existing tabgroup, so use it
         //say('_bbdockInsert: case 2.a');

         DockingArea found_area, first_i, last_i;
         _bbdockFindTabGroup(tabgroup,found_area,first_i,last_i,area);
         tabgroup_wid=_tbTabGroupWidFromWid(gbbdockinfo[area][first_i].wid);
         if( tabOrder<0 ) {
            // Inserting at the end
            i=last_i+1;
            tabOrder=gbbdockinfo[area][last_i].tabOrder+1;

         } else {
            // Inserting at beginning or middle
            int j;
            for( j=first_i; j<=last_i; ++j ) {

               if( tabOrder <= gbbdockinfo[area][j].tabOrder ) {
                  break;
               }
            }
            // Insert at this location
            i=j;
            if( tabOrder==gbbdockinfo[area][j].tabOrder ) {
               // Cannot have 2 tabs in a tabgroup with the same tabOrder.
               // Shift tabOrder numbers by +1 for every tab after the
               // one being inserted.
               for( ;j<=last_i; ++j ) {
                  gbbdockinfo[area][j].tabOrder += 1;
               }
            }
         }

      } else {
         // Create new tabgroup at index i
         //say('_bbdockInsert: 2.b');

         newTabGroup=true;
         tabgroup=_bbdockQMaxTabGroup()+1;
      }
   } else {
      // tabgroup == 0

      // Do not do something dumb like put a toolbar (buttons-only) into
      // a tabgroup.
      if( 0 == (tbflags & (TBFLAG_NO_TABLINK|TBFLAG_NO_CAPTION)) &&
          0 != (tbflags&TBFLAG_SIZEBARS) &&
          !isNoTabLinkToolbar(name_name(resource_index)) ) {
      
         // No tabgroup here yet, so make one
         newTabGroup=true;
         tabgroup = _bbdockQMaxTabGroup()+1;
         tabOrder = -1;
      }
   }
   if( tabgroup>0 ) {
      // We have a tabgroup

      if( tabOrder<0 ) {
         // New tab in a new tabgroup, so give it some order
         tabOrder=0;
      }
      if( !newTabGroup ) {
         // Disallow rowbreaks since we are inserting into an existing tabgroup
         doRowBreakBefore=doRowBreakAfter=false;
      }
   }

   if( doRowBreakBefore && doRowBreakAfter ) {
      doRowBreakAfter=false;
      //_message_box('bad call');
   }
   int ShiftAmount = 0;
   if( doRowBreakBefore ) ++ShiftAmount;
   ++ShiftAmount;
   if( doRowBreakAfter ) ++ShiftAmount;

   // When we insert a rowbreak before, current rowbreak becomes
   // this row's rowbreak, and the new rowbreak is for the
   // previous row.
   int before_restore_row=0;
   if( doRowBreakBefore ) {
      before_restore_row=_bbdockQRestoreRow(area,i);
      if( before_restore_row==0 ) {
         //_message_box('odd case');
         before_restore_row=_bbdockQMaxRestoreRow(area)+1;

      } else {
         //_message_box('Normal case');
         _bbdockInsertRestoreRow(area,before_restore_row);
      }
   }

   // Shift the array at the insertion index to make room for rowbreaks
   // and new tool window.
   // Note:
   // Nothing is shifted if we are inserting at the end of the array.
   int j;
   for( j=_bbdockPaletteLength(area)-1;j>=i;--j ) {
      gbbdockinfo[area][j+ShiftAmount]=gbbdockinfo[area][j];
      // Zero out the indices we are inserting at.
      // Note:
      // Before 12.0 this was necessary in the case of inserting into a tabgroup
      // because tab-linking could destroy and recreate tool windows
      // when the SSTab control must first be created. This caused
      // _tbSmartLoadTemplate to have to look for the index in order
      // to destroy/replace the wid and we did not want to find the
      // wrong/obsolete index!
      // As of 12.0 we support tab controls of 1 tab by hiding the tab row,
      // so that there will always be a tab control for a tabgroup (even a tabgroup
      // of 1), so windows are no longer destroyed/recreated when inserting into a
      // tabgroup. Yay. That said, we will zero the indices out anyway since it
      // cannot hurt.
      gbbdockinfo[area][j].wid=0;
   }

   int index=0;
   int palette_wid=_bbdockPaletteGet(area);
   // If the _dock_palette_form has not been loaded for this side/palette
   if( palette_wid==0 ) {
      index=find_index("_dock_palette_form",oi2type(OI_FORM));
      if( area < DOCKINGAREA_FIRST || area > DOCKINGAREA_LAST ) {
         // Create a floating palette
         area=_bbdockPaletteLastIndex() + 1;
         palette_wid=_paletteCreateFloating();
      } else {
         // Create palette attached to a side
         palette_wid=_paletteCreateSide(area);
      }
   }

   if( doRowBreakBefore ) {
      gbbdockinfo[area][i].wid=BBDOCKINFO_ROWBREAK;
      gbbdockinfo[area][i].twspace=0;
      gbbdockinfo[area][i].docked_row=before_restore_row;
      ++i;
   }

   int parent_wid = palette_wid;
   boolean tabLink = ( tabgroup>0 );
   if( tabLink && tabgroup_wid>0 ) {
      parent_wid=tabgroup_wid;
   }
   int wid = _tbSmartLoadTemplate(tbflags,resource_index,parent_wid,tabLink);
   //say('_bbdockInsert: wid.p_name='wid.p_name'  wid.p_object='wid.p_object);
   //messageNwait("_bbdockInsert: object="wid.p_object" wid="wid);
   gbbdockinfo[area][i].wid=wid;
   gbbdockinfo[area][i].twspace=twspaceBefore;
   gbbdockinfo[area][i].sizebarAfterWid=0;
   gbbdockinfo[area][i].tbflags=tbflags;
   gbbdockinfo[area][i].docked_row=0;
   gbbdockinfo[area][i].tabgroup=tabgroup;
   gbbdockinfo[area][i].tabOrder=tabOrder;
   ++i;

   if( doRowBreakAfter ) {
      gbbdockinfo[area][i].wid=BBDOCKINFO_ROWBREAK;
      gbbdockinfo[area][i].twspace=0;
      int docked_row=_bbdockQRestoreRow(area,i+1);
      //_message_box('doRowBreakAfter i='i' docked_row='docked_row' len='_bbdockPaletteLength(area));
      gbbdockinfo[area][i].docked_row=0;
      if( docked_row==0 ) {
         gbbdockinfo[area][i].docked_row=_bbdockQMaxRestoreRow(area)+1;
      } else {
         _bbdockInsertRestoreRow(area,docked_row);
         gbbdockinfo[area][i].docked_row=docked_row;
      }

   }

   if( tabgroup>0 ) {
      _bbdockSortTabGroup(tabgroup,area);
   }
   _bbdockAdjustRowBreaks(area);
   _bbdockAddRemoveSizeBars(area);
   return wid;
}

/**
 * @param wid      Tool window wid to find.
 * @param area   (output). Side the tool window was found on.
 * @param i        (output). Index the tool window was found at.
 * @param tabgroup (output). Unique tabgroup identifier that this
 *                 tool window is tab-linked into. 0 if no tabgroup.
 * @param tabOrder (output). Tab order in a tabgroup that this
 *                 tool window is displayed.
 *
 * @return true if wid is found in the list of side tool windows.
 * area and are i are set so that _bbdockRemove may be called to
 * delete the tool window.
*/
boolean _bbdockFindWid(int wid, int& area, int& i, int& tabgroup, int& tabOrder)
{
   tabgroup=0;
   tabOrder=0;
   for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {
      int count = _bbdockPaletteLength(area);
      for( i=0;i<count;++i ) {
         int wid2 = gbbdockinfo[area][i].wid;
         if( wid2==wid ||
             (wid2>0 && gbbdockinfo[area][i].sizebarAfterWid==wid) ||
             (wid2==BBDOCKINFO_ROWBREAK && gbbdockinfo[area][i].twspace==wid) ) {

            if( wid2>0 ) {
               tabgroup=gbbdockinfo[area][i].tabgroup;
               tabOrder=gbbdockinfo[area][i].tabOrder;
            }
            return true;
         }
      }
   }
   area=0;
   i=0;
   return false;
}

int _bbdockGetWid(DockingArea area, int i)
{
   if( area<DOCKINGAREA_FIRST || area>_bbdockPaletteLastIndex() ) {
      // Not a valid side
      return 0;
   }
   if( i<0 || i >= _bbdockPaletteLength(area) ) {
      // Not a valid index
      return 0;
   }
   int wid = gbbdockinfo[area][i].wid;
   return wid;
}

/**
 * Find the first and last docked tool windows of a tabgroup.
 * 
 * @param tabgroup  Tabgroup to find.
 * @param area    (output). Area the tabgroup was found on.
 * @param first_i   (output). Index to first tool window in tab group (first in tab order).
 * @param last_i    (output). Index to last tool window in tab group (last in tab order).
 * @param startSide (optional). Docked side to start looking on. Used to speed up searches
 *                  when you know where a tabgroup is docked already.
 *
 * @return true if tabgroup is found in the list of side tool windows.
 * area, first_i, and last_i are set so that _bbdockInsert may be called to
 * order-insert a tool window into a tabgroup of tab-linked tool windows.
*/
boolean _bbdockFindTabGroup(int tabgroup,
                            int& area, int& first_i, int& last_i,
                            int startSide=DOCKINGAREA_FIRST)
{
   if( startSide<DOCKINGAREA_FIRST || startSide>_bbdockPaletteLastIndex() ) {
      startSide=DOCKINGAREA_FIRST;
   }
   area=startSide;
   for( ;; ) {

      int count = _bbdockPaletteLength(area);
      for( first_i=0; first_i<count; ++first_i ) {

         int wid = gbbdockinfo[area][first_i].wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            // Cannot have rowbreaks between tabs, so we are done looking
            // on this row.
            continue;
         }
         int tabgroup2 = gbbdockinfo[area][first_i].tabgroup;
         if( tabgroup2==tabgroup ) {
            // Found the first tab-linked tool window, so now
            // find the last.

            for( last_i=first_i+1; last_i<count; ++last_i ) {

               wid=gbbdockinfo[area][last_i].wid;
               if( wid==BBDOCKINFO_ROWBREAK ) {
                  // Cannot have rowbreaks between tabs, so we are done
                  break;
               }
               tabgroup2=gbbdockinfo[area][last_i].tabgroup;
               if( tabgroup2!=tabgroup ) {
                  break;
               }
            }
            // last_i is always parked +1 past the last tab-linked tool window,
            // back up 1 index.
            --last_i;
            return true;
         }
      }
      ++area;
      if( area>_bbdockPaletteLastIndex() ) {
         area=DOCKINGAREA_FIRST;
      }
      if( area==startSide ) {
         break;
      }
   }
   return false;
}

void _bbdockAddRemoveSizeBars(DockingArea area)
{
   int orient = _bbdockPaletteOrientation(area);
   int count = _bbdockPaletteLength(area);
   int i,j;
   int wid, orig_wid=0;
   int style,mp,border_style;
   for( i=0; i<count; ++i ) {

      wid=gbbdockinfo[area][i].wid;
      if( wid>0 ) {
         // IF there is a tool window after this one which requires SIZEBARS
         // Now make sure the row breaks for this side have the correct
         // SIZEBAR settings.

         j=i+1;
         int tabgroup = _bbdockTabGroup(area,i,false);
         boolean isTabLinked = ( tabgroup>0 );
         boolean nextIsWid = ( j >= 0 &&
                               j < _bbdockPaletteLength(area) &&
                               gbbdockinfo[area][j].wid > 0
                             );
         int nextTabgroup = _bbdockTabGroup(area,j,false);
         boolean nextIsTabLinked = ( nextIsWid && nextTabgroup>0 && nextTabgroup==tabgroup );

         //
         // If there is a tool window after this one that is sizeable,
         // AND it is not tab-linked into the middle of a tabgroup.
         // Explanation:
         // Tab-linked tool windows all belong to the same panel,
         // so it only makes sense to have a sizebar after a
         // tool window IF:
         // 1. This tool window is not tab-linked, OR
         // 2. The next tool window is not tab-linked, which would
         //    mean that this tool window was the last tab-linked
         //    tool window (or not tab-linked).
         //
         if( nextIsWid && (!isTabLinked || !nextIsTabLinked) ) {

            if( gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS ) {

               if( gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS ) {

                  if( orient == TBORIENT_HORIZONTAL ) {
                     style=PSPIC_SIZEVERT;
                     mp = MP_SPLITHORZ;
                  } else {
                     // orient == TBORIENT_VERTICAL
                     style=PSPIC_SIZEHORZ;
                     mp = MP_SPLITVERT;
                  }
                  border_style=BDS_NONE;

               } else {
                  style=PSPIC_DEFAULT;
                  mp=MP_DEFAULT;
                  border_style=BDS_FIXED_SINGLE;
               }
               int sizebarAfterWid=gbbdockinfo[area][i].sizebarAfterWid;
               if( sizebarAfterWid==0 ) {
                  orig_wid=p_window_id;
                  wid=_create_window(OI_IMAGE,_bbdockPaletteGet(area),"",0,0,0,0,CW_HIDDEN|CW_CHILD);
                  p_window_id=orig_wid;
                  wid.p_style=style;
                  wid.p_mouse_pointer=mp;
                  wid.p_border_style=border_style;
                  //messageNwait("_bbdockAdjustRowBreaks: style="wid.p_style" wid="wid);
                  gbbdockinfo[area][i].sizebarAfterWid=wid;

               } else if( sizebarAfterWid.p_style!=style ) {
                  sizebarAfterWid.p_style=style;
                  sizebarAfterWid.p_mouse_pointer=mp;
                  sizebarAfterWid.p_border_style=border_style;
               }

            } else if( (gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS) &&
                       !(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {

               if( gbbdockinfo[area][i].sizebarAfterWid==0 ) {
                  orig_wid=p_window_id;
                  wid=_create_window(OI_IMAGE,_bbdockPaletteGet(area),"",0,0,0,0,CW_HIDDEN|CW_CHILD);
                  p_window_id=orig_wid;
                  wid.p_style=PSPIC_DEFAULT;
                  wid.p_mouse_pointer=MP_DEFAULT;
                  wid.p_border_style=BDS_FIXED_SINGLE;
                  //messageNwait("_bbdockAdjustRowBreaks: style="wid.p_style" wid="wid);
                  gbbdockinfo[area][i].sizebarAfterWid=wid;
               }
            }

         } else if( gbbdockinfo[area][i].sizebarAfterWid!=0 ) {

            gbbdockinfo[area][i].sizebarAfterWid._delete_window();
            gbbdockinfo[area][i].sizebarAfterWid=0;
         }
      }
   }
}

/**
 * Make sure we do not have 2 row breaks in a row.
 * <p>
 * Add/remove row break SIZEBAR where necessary.
 * <p>
 * Add a row break at the end if the last row has
 * a tool window which requires a SIZEBAR.
 * 
 * @param area
 */
void _bbdockAdjustRowBreaks(DockingArea area)
{
   //messageNwait("_bbdockAdjustRowBreaks: IN");
   // Remove leading row breaks
   int j;
   for( j=0;j<_bbdockPaletteLength(area) &&
        gbbdockinfo[area][j].wid==BBDOCKINFO_ROWBREAK;++j ) {

      if( gbbdockinfo[area][j].twspace!=0 ) {
         gbbdockinfo[area][j].twspace._delete_window();
      }
      gbbdockinfo[area]._deleteel(j);--j;
   }
   // Now make sure the row breaks for the entire side/palette have the correct
   // SIZEBAR settings.
   boolean rowNeedsSizebar = false;
   int palette_wid = 0;
   int wid=0, orig_wid=0;
   int style,mp,border_style;
   for( j=0;j<_bbdockPaletteLength(area);++j ) {
      wid=gbbdockinfo[area][j].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {

         // Delete duplicate row breaks
         while( (j+1) < _bbdockPaletteLength(area) &&
                gbbdockinfo[area][j+1].wid==BBDOCKINFO_ROWBREAK ) {

            if( gbbdockinfo[area][j+1].twspace ) {
               gbbdockinfo[area][j+1].twspace._delete_window();
            }
            gbbdockinfo[area]._deleteel(j+1);
         }
         wid=gbbdockinfo[area][j].twspace;
         if( wid==0 ) {
            // Add a row break SIZEBAR
            orig_wid=p_window_id;
            wid=_create_window(OI_IMAGE,palette_wid,"",0,0,0,0,CW_HIDDEN|CW_CHILD);
            p_window_id=orig_wid;
         }
         if( rowNeedsSizebar ) {
            if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
               style=PSPIC_SIZEHORZ;
               mp=MP_SPLITVERT;
            } else {
               style=PSPIC_SIZEVERT;
               mp=MP_SPLITHORZ;
            }
            border_style=BDS_NONE;

         } else {
            style=PSPIC_DEFAULT;
            border_style=BDS_FIXED_SINGLE;
            mp=MP_DEFAULT;
         }
         // Here we sometimes make the image control invisible to
         // prevent paint problems.
         if( wid.p_style!=style ) {
            wid.p_visible=0;
            wid.p_style=style;
         }
         wid.p_mouse_pointer=mp;
         if( wid.p_border_style!=border_style ) {
            wid.p_visible=0;
            wid.p_border_style=border_style;
         }

         gbbdockinfo[area][j].twspace=wid;
         if( (j+1) < _bbdockPaletteLength(area) ) {
            rowNeedsSizebar=false;
         }

      } else if( wid>0 ) {
         // If this tool window is a valid object handle and requires SIZEBARS
         palette_wid=_bbdockPaletteGet(area);
         if( 0!=(gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS) ) {
            rowNeedsSizebar=true;
         }
      }
   }
   {
      j=_bbdockPaletteLength(area)-1;
      // IF there are any tool windows
      if( j>=0 ) {
         // Always place a rowbreak after the last tool window
         if( gbbdockinfo[area][j].wid!=BBDOCKINFO_ROWBREAK ) {
            // Add row break at end
            j=_bbdockPaletteLength(area);
            gbbdockinfo[area][j].wid=BBDOCKINFO_ROWBREAK;
            gbbdockinfo[area][j].twspace=0;
            //_message_box('added row break after last toolbar!!');
            // Setting docked_row=0 before setting it again with _bbdockQMaxRestoreRow()
            // is not a mistake! We must do this so _bbdockQMaxRestoreRow() does not
            // count it when finding the max restore row number.
            gbbdockinfo[area][j].docked_row=0;
            gbbdockinfo[area][j].docked_row=_bbdockQMaxRestoreRow(area)+1;
         }
         wid=gbbdockinfo[area][j].twspace;
         if( wid==0 ) {
            orig_wid=p_window_id;
            wid=_create_window(OI_IMAGE,palette_wid,"",0,0,0,0,CW_HIDDEN|CW_CHILD);
            p_window_id=orig_wid;
            gbbdockinfo[area][j].twspace=wid;
         }
         if( rowNeedsSizebar ) {
            if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
               style=PSPIC_SIZEHORZ;
               mp=MP_SPLITVERT;
            } else {
               style=PSPIC_SIZEVERT;
               mp=MP_SPLITHORZ;
            }
            border_style=BDS_NONE;
            //messageNwait("_bbdockAdjustRowBreaks: rowNeedsSizebar");
         } else {
            style=PSPIC_DEFAULT;
            border_style=BDS_FIXED_SINGLE;
            mp=MP_DEFAULT;
            //messageNwait("_bbdockAdjustRowBreaks: BDS_FIXED_SINGLE");
         }
         // Here we sometimes make the image control invisible to prevent paint
         // problems.
         if( wid.p_style!=style ) {
            wid.p_style=style;
            //messageNwait("_bbdockAdjustRowBreaks: change rowbreak style");
            wid.p_visible=0;
         }
         wid.p_mouse_pointer=mp;
         if( wid.p_border_style!=border_style ) {
            wid.p_border_style=border_style;
            wid.p_visible=0;
         }
      }
   }
}

/**
 * This method operates on MDI objects only.
 * <p>
 * Use the _bbdockFindWid function to get area and i.
 * <p>
 * This function deletes a tool window from a button bar side.  It also removes
 * space to the left and SIZEBARS if necessary.
 * 
 * @param area
 * @param i
 * @param docking this paramater should be true if the toolbar is being docked or undocked
 * 
 * @see _bbdockFindWid
*/
void _bbdockRemove(DockingArea area,int i,boolean docking)
{
   // Prevent on_got_focus2/on_lost_focus2 events to prevent us from attempting
   // to access invalid wids in the model before we have had a chance to update
   // the model.
   boolean old_IgnoreOnGotFocus2 = _tbIgnoreOnGotFocus2(true);
   boolean old_IgnoreOnLostFocus2 = _tbIgnoreOnLostFocus2(true);

   int wid = gbbdockinfo[area][i].wid;
   int sizebarAfterWid = gbbdockinfo[area][i].sizebarAfterWid;
   if( wid!=0 ) {
      wid._tbMaybeDeleteWindow(docking);
   }
   if( sizebarAfterWid!=0 ) {
      sizebarAfterWid._delete_window();
   }
   gbbdockinfo[area]._deleteel(i);
   _bbdockAdjustRowBreaks(area);
   _bbdockAddRemoveSizeBars(area);

   _tbIgnoreOnLostFocus2(old_IgnoreOnLostFocus2);
   _tbIgnoreOnGotFocus2(old_IgnoreOnGotFocus2);
}

/**
 * This method operates on MDI objects only.
 * <p>
 * Delete entire button bar area from an MDI side.
 * 
 * @param area MDI side to delete.
 * @param docking this paramater should be true if the toolbar is being docked or undocked
 */
void _bbdockMaybeRemoveButtonBar(DockingArea area,boolean docking=false)
{
   if( 0==_bbdockPaletteLength(area) ||
       (_bbdockPaletteLength(area)==1 && gbbdockinfo[area][0].wid==BBDOCKINFO_ROWBREAK) ) {

      int palette_wid = _bbdockPaletteGet(area);
      if( palette_wid>0 ) {
         palette_wid._delete_window();
      }
   }
}

static void _bbdockSetMakeAllVisible(DockingArea area)
{
   CMDUI cmdui;
   cmdui.menu_handle=0;
   int target_wid;
   if( _no_child_windows() ) {
      target_wid=0;
   } else {
      target_wid=_mdi.p_child;
   }
   cmdui.button_wid=1;

   _OnUpdateInit(cmdui,target_wid);

   int count = _bbdockPaletteLength(area);
   int tab_index = 1;
   int i;
   for( i=0;i<count;++i ) {
      int wid = gbbdockinfo[area][i].wid;
      if( wid>0 ) {

         int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);

         // Enforce a sequential tab order
         container_wid.p_tab_index=tab_index;++tab_index;

         // Make the container visible
         if( !container_wid.p_visible ) {
            container_wid.p_visible=true;
         }
         // Make embedded tabgroup tab control visible
         int tabgroup_wid = _tbTabGroupWidFromWid(wid);
         if( tabgroup_wid>0 ) {
            int tabcontainer_wid = _tbTabGroupContainerWidFromWid(wid);
            // IMPORTANT:
            // Do NOT set every container visible. The SSTab control only
            // shows the active tab visible, so if you set all containers
            // visible, then you will see whatever the top container is in
            // the z-order.
            if( tabcontainer_wid>0 && tabcontainer_wid.p_ActiveOrder==tabgroup_wid.p_ActiveOrder ) {
               // Tab-linked tool window, so make the SSTab container visible
               tabcontainer_wid.p_visible=true;
            }
            tabgroup_wid.p_visible=true;
         }
         // Make tool window visible
         if( wid!=container_wid && !wid.p_visible ) {
            // This tool window is a child of a panel, so make it visible too
            _tbSetToolbarEnable(wid);
            wid.p_visible=true;
            // Update captions on panels
            container_wid._tbpanelUpdate(0);
         }
         int sizebarAfterWid=gbbdockinfo[area][i].sizebarAfterWid;
         if( sizebarAfterWid!=0 && !sizebarAfterWid.p_visible ) {
            sizebarAfterWid.p_visible=true;
         }

      } else {
         wid=gbbdockinfo[area][i].twspace;
         if( wid!=0 && !wid.p_visible ) {
            wid.p_visible=true;
         }
      }
   }
}

void _bbdockRefresh(DockingArea area)
{
   _bbdockRefresh2(area);
   _bbdockSetMakeAllVisible(area);
}

static void _bbdockAdjustLeadingSpace(DockingArea area)
{
   int last_wid=0;
   int i;
   int wid;
   boolean RemoveSpace=false;
   for( i=0;i<_bbdockPaletteLength(area);++i ) {
      if( last_wid==0 ) {
         RemoveSpace=false;
         if( _bbdockRowHasSizeBars(area,i) ) {
            RemoveSpace=true;
         }
      }
      wid=gbbdockinfo[area][i].wid;
      if( wid>0 && RemoveSpace && 0==(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
         // Not sizeable
         gbbdockinfo[area][i].twspace=0;
      }
      last_wid=wid;
   }
}

int _bbdockRowStart(DockingArea area, int i)
{
   // Make sure we are at the start of this row
   while( i!=0 && gbbdockinfo[area][i-1].wid!=BBDOCKINFO_ROWBREAK ) {
      --i;
   }
   return(i);
}

boolean _bbdockRowHasSizeBars(DockingArea area, int i)
{
   // Make sure we are at the start of this row
   while( i!=0 && gbbdockinfo[area][i-1].wid!=BBDOCKINFO_ROWBREAK ) {
      --i;
   }
   // Check all tool windows on this row.
   // If any tool window is resizable, then the entire row
   // has a sizebar.
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid=gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
         // Sizeable
         return true;
      }
   }
   return false;
}

/**
 * @param area
 * @param i
 * 
 * @return Height of tallest tool window between i and end of row.
 */
static int _bbdockRowHeight(DockingArea area, int i)
{
   /*boolean lastRow = false;
   if( area==DOCKINGAREA_BOTTOM ) {
      // Check if this is the last row
      j=i;
      for( ;j<_bbdockPaletteLength(area);++j ) {
         wid=gbbdockinfo[area][j].wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            ++j;
            lastRow = ( j>=_bbdockPaletteLength(area) );
            break;
         }
      }
   }*/

   int largest_height = 0;
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);

      int height;
      if( container_wid!=wid ) {
         // Tool window contained inside a _tbpanel_form form or
         // tab-linked into a SSTab tabgroup, so want the height
         // of the panel, NOT the height of the tool window inside
         // the panel.
         height=container_wid.p_height;

      } else {
         if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
            height=wid.p_height;
         } else {
            // Place border on top of SIZEBAR or picture box border above
            height=wid.p_height; //-_twips_per_pixel_y();
            /*if( LastRow ) {
               height -= _twips_per_pixel_y();
            }*/
            if( height<0 ) {
               height=0;
            }
         }
      }
      // Just to be safe. Make sure this aligns exactly on pixels.
      height=_ly2dy(wid.p_xyscale_mode,height);
      height=_dy2ly(wid.p_xyscale_mode,height);
      if( height>largest_height ) {
         largest_height=height;
      }
   }
   return largest_height;
}

/**
 * @param area
 * @param i
 * 
 * @return Width of largest tool window between i and end of row.
 */
static int _bbdockRowWidth(DockingArea area, int i)
{
   /*boolean lastRow = false;
   if( area==DOCKINGAREA_RIGHT ) {
      // Check if this is the last row
      j=i;
      for( ;j<_bbdockPaletteLength(area);++j ) {
         int wid = gbbdockinfo[area][j].wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            ++j;
            lastRow = ( j>=_bbdockPaletteLength(area) );
            break;
         }
      }
   }*/

   int largest_width = 0;
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);

      int width;
      if( container_wid!=wid ) {
         // Tool window contained inside a _tbpanel_form form, so
         // want the width of the panel, NOT the width of the
         // tool window inside the panel.
         width=container_wid.p_width;

      } else {
         if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
            width=wid.p_width;
         } else {
            // Place border on top of SIZEBAR or picture box border above
            width=wid.p_width; //-_twips_per_pixel_x();
            /*if( lastRow ) {
               width -= _twips_per_pixel_x();
            }*/
            if( width<0 ) {
               width=0;
            }
         }
      }
      // Just to be safe. Make sure this aligns exactly on pixels.
      width=_lx2dx(wid.p_xyscale_mode,width);
      width=_dx2lx(wid.p_xyscale_mode,width);
      if( width>largest_width ) {
         largest_width=width;
      }
   }
   return largest_width;
}

static void _bbdockResetRowAdjustable(DockingArea area, int i)
{
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      if( gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS ) {
         gbbdockinfo[area][i].twspace=0;
      }
   }
}

static void _bbdockAdjustRowWidth(DockingArea area, int i, int ExtraWidth, int AdjustableWidth,
                                  int NofAdjustable, boolean AdjustAll)
{
   int RowWidth = 0;
   int WidthLeft = ExtraWidth;
   int Adjust = 0;
   int start_i = i;
   int width;
   int prev_wid = 0;
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = _bbdockContainer(&gbbdockinfo[area][i]);
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      if( wid==prev_wid ) {
         // This happens with tab-linked tool windows because
         // they all belong to the same container (a panel),
         // so do not make it bigger and bigger!
         continue;
      }

      if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
         // Sizeable

         width = wid.p_width;
         if( AdjustAll || 0 == gbbdockinfo[area][i].twspace ) {
            if( AdjustableWidth == 0 ) {
               Adjust = (ExtraWidth) intdiv NofAdjustable;

            } else {
               Adjust = (width*ExtraWidth) intdiv AdjustableWidth;
            }
            if( (Adjust+width) < 0 ) {
               Adjust= -width;
            }
            width += Adjust;
            // Round twips to nearest pixel
            width = _lx2dx(SM_TWIP,width);
            width = _dx2lx(wid.p_xyscale_mode,width);
            wid.p_visible = false;
            wid.p_width = width;
            WidthLeft -= Adjust;
         }
      }
      prev_wid = wid;
   }
   if( WidthLeft < 0 ) {
      // Add the WidthLeft to one of the SIZEBAR tool windows
      prev_wid = 0;
      for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
         int wid = _bbdockContainer(&gbbdockinfo[area][i]);
         if( wid == BBDOCKINFO_ROWBREAK ) {
            break;
         }
         if( wid == prev_wid ) {
            // This happens with tab-linked tool windows because
            // they all belong to the same container (a panel),
            // so do not make it bigger and bigger!
            continue;
         }
         if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
            // Sizeable
            width = wid.p_width;
            if( (width + WidthLeft) >= 0 ) {
               wid.p_visible = false;
               wid.p_width = width + WidthLeft;
               break;
            }
         }
         prev_wid = wid;
      }

   } else {

      if( WidthLeft != 0 ) {
         // Add the WidthLeft to one of the SIZEBAR tool windows
         prev_wid = 0;
         for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
            int wid = _bbdockContainer(&gbbdockinfo[area][i]);
            if( wid == BBDOCKINFO_ROWBREAK ) {
               break;
            }
            if( wid == prev_wid ) {
               // This happens with tab-linked tool windows because
               // they all belong to the same container (a panel),
               // so do not make it bigger and bigger!
               continue;
            }
            if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               width = wid.p_width;
               if( width > 0 ) {
                  wid.p_visible = false;
                  wid.p_width = width + WidthLeft;
                  WidthLeft = 0;
                  break;
               }
            }
            prev_wid = wid;
         }
      }
      if( WidthLeft != 0 ) {
         // Add the WidthLeft to one of the SIZEBAR tool bars
         prev_wid = 0;
         for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
            int wid = _bbdockContainer(&gbbdockinfo[area][i]);
            if( wid == BBDOCKINFO_ROWBREAK ) {
               break;
            }
            if( wid == prev_wid ) {
               // This happens with tab-linked tool windows because
               // they all belong to the same container (a panel),
               // so do not make it bigger and bigger!
               continue;
            }
            if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               wid.p_visible = 0;
               wid.p_width = width + WidthLeft;
               break;
            }
            prev_wid = wid;
         }
      }
   }

}

static void _bbdockAdjustRowHeight(DockingArea area, int i, int ExtraHeight, int AdjustableHeight,
                                   int NofAdjustable, boolean AdjustAll)
{
   int RowHeight = 0;
   int HeightLeft = ExtraHeight;
   int Adjust = 0;
   int start_i = i;
   int height;
   int prev_wid = 0;
   for( ;i < _bbdockPaletteLength(area); ++i ) {
      int wid = _bbdockContainer(&gbbdockinfo[area][i]);
      if( wid == BBDOCKINFO_ROWBREAK ) {
         break;
      }
      if( wid==prev_wid ) {
         // This happens with tab-linked tool windows because
         // they all belong to the same container (a panel),
         // so do not make it bigger and bigger!
         continue;
      }
      if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
         // Sizeable
         height = wid.p_height;
         if( AdjustAll || 0 == gbbdockinfo[area][i].twspace ) {
            if( AdjustableHeight == 0 ) {
               Adjust = (ExtraHeight) intdiv NofAdjustable;
            } else {
               Adjust = (height*ExtraHeight) intdiv AdjustableHeight;
            }
            if( (height + Adjust) < 0 ) {
               Adjust = -height;
            }
            height += Adjust;
            // Force alignment on pixel boundaries
            height = _ly2dy(SM_TWIP,height);
            height = _dy2ly(wid.p_xyscale_mode,height);
            wid.p_visible = false;
            wid.p_height = height;
            HeightLeft -= Adjust;
         }
      }
      prev_wid = wid;
   }
   if( HeightLeft < 0 ) {
      // Add the HeightLeft to one of the SIZEBAR tool bars
      prev_wid = 0;
      for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
         int wid = _bbdockContainer(&gbbdockinfo[area][i]);
         if( wid == BBDOCKINFO_ROWBREAK ) {
            break;
         }
         if( wid == prev_wid ) {
            // This happens with tab-linked tool windows because
            // they all belong to the same container (a panel),
            // so do not make it bigger and bigger!
            continue;
         }
         if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
            height = wid.p_height;
            if( (height + HeightLeft) >= 0 ) {
               wid.p_visible = false;
               wid.p_height = height + HeightLeft;
               break;
            }
         }
         prev_wid = wid;
      }

   } else {

      if( HeightLeft != 0 ) {
         // Add the HeightLeft to one of the SIZEBAR tool windows
         prev_wid = 0;
         for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
            int wid = _bbdockContainer(&gbbdockinfo[area][i]);
            if( wid == BBDOCKINFO_ROWBREAK ) {
               break;
            }
            if( wid == prev_wid ) {
               // This happens with tab-linked tool windows because
               // they all belong to the same container (a panel),
               // so do not make it bigger and bigger!
               continue;
            }
            if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               height = wid.p_height;
               if( height > 0 ) {
                  wid.p_visible = false;
                  wid.p_height = height + HeightLeft;
                  HeightLeft = 0;
                  break;
               }
            }
            prev_wid = wid;
         }
      }
      if( HeightLeft != 0 ) {
         // Add the WidthLeft to one of the SIZEBAR tool bars
         prev_wid = 0;
         for( i=start_i; i < _bbdockPaletteLength(area); ++i ) {
            int wid = _bbdockContainer(&gbbdockinfo[area][i]);
            if( wid == BBDOCKINFO_ROWBREAK ) {
               break;
            }
            if( wid == prev_wid ) {
               // This happens with tab-linked tool windows because
               // they all belong to the same container (a panel),
               // so do not make it bigger and bigger!
               continue;
            }
            if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               wid.p_visible = false;
               wid.p_height = height + HeightLeft;
               break;
            }
            prev_wid = wid;
         }
      }
   }

}

static void _bbdockGetRowAdjustableWidth(DockingArea area, int i, int& ExtraWidth, int& TotalAdjustableWidth,
                                         int& AdjustableWidth, int& NofAdjustable)
{
   TotalAdjustableWidth=0;
   AdjustableWidth=0;
   NofAdjustable=0;
   int next_x = 0;
   boolean rowNeedsSizebar = false;
   int prev_wid = 0;
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = _bbdockContainer(&gbbdockinfo[area][i]);
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }
      if( wid==prev_wid ) {
         // This happens with tab-linked tool windows because
         // they all belong to the same container (a panel),
         // so do not make it bigger and bigger!
         continue;
      }

      int new_x = next_x;
      int new_width = wid.p_width;
      // Force alignment on pixel boundaries
      new_width=_lx2dx(SM_TWIP,new_width);
      new_width=_dx2lx(SM_TWIP,new_width);
      if( 0!=(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
         // Sizeable
         ++NofAdjustable;
         rowNeedsSizebar=true;
         TotalAdjustableWidth += new_width;
         if( 0==gbbdockinfo[area][i].twspace ) {
            // No initial width for this tool window, so we can mess with it
            AdjustableWidth += new_width;
         }

      } else {
         // Not sizeable

         // IF previous tool window needs SIZEBARS
         if( i>0 && gbbdockinfo[area][i-1].wid>0 &&
             0!=(gbbdockinfo[area][i-1].tbflags & TBFLAG_SIZEBARS) ) {

            // Nothing to do since previous sizeable tool window will fill any
            // gap left by current non-sizeable (e.g. button bar) tool window.

         } else {
            // IF there is space before this tool window
            if( 0!=gbbdockinfo[area][i].twspace ) {
               new_x=next_x+gbbdockinfo[area][i].twspace;
               new_x=_lx2dx(SM_TWIP,new_x);
               new_x=_dx2lx(SM_TWIP,new_x);

            } else {
               // Place left border on top of right border of previous tool bar
               new_x=next_x; //-_twips_per_pixel_x();
            }
         }
      }
      next_x=new_x+new_width;
      int sizebarAfterWid=gbbdockinfo[area][i].sizebarAfterWid;
      if( sizebarAfterWid ) {
         next_x+=sizebarAfterWid.p_width;
      }
      prev_wid=wid;
   }
   if( !rowNeedsSizebar ) {
      ExtraWidth=0;
      return;
   }
   --i;
   // IF the last tool window has a border
   if( i>=0 && i<_bbdockPaletteLength(area) &&
       gbbdockinfo[area][i].wid>0 && 0==(gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
      // Place the border off the screen
      next_x -= _twips_per_pixel_x();
   }
   int palette_wid = _bbdockPaletteGet(area);
   ExtraWidth=palette_wid.p_width-next_x;
}

static void _bbdockGetRowAdjustableHeight(DockingArea area, int i, int& ExtraHeight, int& TotalAdjustableHeight,
                                          int& AdjustableHeight, int& NofAdjustable)
{
   TotalAdjustableHeight=0;
   AdjustableHeight=0;
   NofAdjustable=0;
   int next_y = 0;
   boolean rowNeedsSizebar = false;
   int prev_wid = 0;
   for( ;i<_bbdockPaletteLength(area);++i ) {
      int wid = _bbdockContainer(&gbbdockinfo[area][i]);
      if( wid==BBDOCKINFO_ROWBREAK ) {
         break;
      }

      // Explanation:
      // Tab-linked tool windows all belong to the same container (a panel),
      // so only count the first height toward the total, otherwise it gets
      // bigger and bigger! Note that the sizeBarAfterWid is set on the LAST
      // tool-window of a tabgroup, so we DO still count that (otherwise you
      // tool-window heights "walk" down as you resize the MDI frame.
      if( wid != prev_wid ) {

         int new_y = next_y;
         int new_height = wid.p_height;

         // Round twips to nearest pixel
         new_height = _ly2dy(SM_TWIP,new_height);
         new_height = _dy2ly(wid.p_xyscale_mode,new_height);

         if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
            // Sizeable
            ++NofAdjustable;
            rowNeedsSizebar = true;
            TotalAdjustableHeight += new_height;
            if( 0 == gbbdockinfo[area][i].twspace ) {
               AdjustableHeight += new_height;
            }

         } else {
            // IF previous tool-window needs SIZEBARS
            if( i > 0 && gbbdockinfo[area][i-1].wid > 0 &&
                0 != (gbbdockinfo[area][i-1].tbflags & TBFLAG_SIZEBARS) ) {

            } else {
               // IF there is space before this tool-window
               if( 0 != gbbdockinfo[area][i].twspace ) {
                  new_y = next_y+gbbdockinfo[area][i].twspace;
                  new_y = _ly2dy(SM_TWIP,new_y);
                  new_y = _ly2dy(wid.p_xyscale_mode,new_y);
               } else {
                  // Place left border on top of right border of previous tool-window
                  new_y = next_y; // - _twips_per_pixel_y();
               }
            }
         }
         next_y = new_y + new_height;
      }

      int sizebarAfterWid = gbbdockinfo[area][i].sizebarAfterWid;
      if( sizebarAfterWid ) {
         next_y += sizebarAfterWid.p_height;
      }
      prev_wid = wid;
   }
   if( !rowNeedsSizebar ) {
      ExtraHeight=0;
      return;
   }
   --i;
   // IF the last tool box has a border
   if( i>=0 && i<_bbdockPaletteLength(area) &&
       gbbdockinfo[area][i].wid>0 && 0==(gbbdockinfo[area][i].tbflags&TBFLAG_SIZEBARS) ) {
      // Place the border be off the screen
      next_y -= _twips_per_pixel_y();
   }
   int palette_wid = _bbdockPaletteGet(area);
   ExtraHeight=palette_wid.p_height-next_y;
}

static void ProcessRowBreak(DockingArea area, int next_y, int wid, boolean RowNeedsSizeBar, int& line_height)
{
   int x,y,width,height;
   wid._get_window(x,y,width,height);

   // Just to be safe. Round twips to nearest pixel.
   _lxy2dxy(SM_TWIP,x,y);
   _dxy2lxy(wid.p_xyscale_mode,x,y);
   _lxy2dxy(SM_TWIP,width,height);
   _dxy2lxy(wid.p_xyscale_mode,width,height);

   int new_x = 0;
   int new_width = _bbdockPaletteGet(area).p_width;
   int new_y = 0;
   int new_height = 0;
   //messageNwait("_bbdockRefresh2: new_width="new_width);

   if( RowNeedsSizeBar ) {
      new_height=wid.p_height;
      new_y=next_y;
      line_height=new_height;

   } else {
      line_height=0;
      new_y=next_y; //-_twips_per_pixel_y();
      new_height=0; //=_twips_per_pixel_y();
      if( new_y<0 ) {
         new_y=0;
         line_height=new_height;
      }
      //messageNwait("1 pixel row");
   }
   if( new_x!=x || new_y!=y || new_width!=width || new_height!=height ) {
      //messageNwait("_bbdockRefresh2: move row break new_y="new_y" new_width="new_width);
      wid.p_visible=0;
      wid._move_window(new_x,new_y,new_width,new_height);
   }
}

static void ProcessRowBreakWidth(DockingArea area, int next_x, int wid, boolean RowNeedsSizeBar, int& line_width)
{
   int x,y,width,height;
   wid._get_window(x,y,width,height);

   // Just to be safe. Round twips to nearest pixel.
   _lxy2dxy(SM_TWIP,x,y);
   _dxy2lxy(wid.p_xyscale_mode,x,y);
   _lxy2dxy(SM_TWIP,width,height);
   _dxy2lxy(wid.p_xyscale_mode,width,height);

   int new_x = 0;
   int new_width = 0;
   int new_y = 0;
   int new_height = _bbdockPaletteGet(area).p_height;
   //messageNwait("ProcessRowBreakWidth: ");
   //messageNwait("_bbdockRefresh2: new_width="new_width);

   if( RowNeedsSizeBar ) {
      new_width=wid.p_width;
      new_x=next_x;
      line_width=new_width;

   } else {
      line_width=0;
      new_x=next_x; //-_twips_per_pixel_x();
      new_width=0; //_twips_per_pixel_x();
      if( new_x<0 ) {
         new_x=0;
         line_width=new_width;
      }
      //messageNwait("1 pixel row");
   }
   if( new_x!=x || new_y!=y || new_width!=width || new_height!=height ) {
      //messageNwait("_bbdockRefresh2: move row break new_y="new_y" new_width="new_width);
      wid.p_visible=0;
      wid._move_window(new_x,new_y,new_width,new_height);
      //wid.p_visible=1;messageNwait("ProcessRowBreakWidth: move row break new_x="new_x" new_heigth="new_height);
   }
}

static int dcount = 0;
static void _bbdockRefresh2(DockingArea area)
{
   int ExtraWidth = 0;
   int TotalAdjustableWidth = 0;
   int AdjustableWidth = 0;
   int NofAdjustable = 0;
   int RowBreakLineHeight = 0;
   int x,y,width,height;
   int new_x = 0;
   int new_y = 0;
   int new_width = 0;
   int new_height = 0;
   int wid = 0;

   // If this side has no button bar
   if( _bbdockPaletteGet(area)==0 ) {
      return;
   }

   ++dcount;
   if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
      // Start from upper left corner
      int next_x = 0;
      int next_y = 0;
      int last_wid = BBDOCKINFO_ROWBREAK;
      int line_height = 0;
      boolean rowNeedsSizebar = false;
      int i, j;
      for( i=0;;++i ) {
         if( i >= _bbdockPaletteLength(area) ) {
            next_y += line_height;
            break;
         }
         if( last_wid == BBDOCKINFO_ROWBREAK ) {
            next_y += line_height;
            next_x = 0;
            line_height = _bbdockRowHeight(area,i);
            rowNeedsSizebar = false;
            _bbdockGetRowAdjustableWidth(area,i,ExtraWidth,TotalAdjustableWidth,
                                         AdjustableWidth,NofAdjustable);
            // IF there are any controls with SIZEBARS AND some widths need
            // to be adjusted.
            if( NofAdjustable > 0 ) {
               if( ExtraWidth != 0 ) {
                  // If sum is too small (e.g. resized MDI window, controls deleted, new screen res)
                  if( ExtraWidth > 0 ) {
                     _bbdockAdjustRowWidth(area,i,ExtraWidth,TotalAdjustableWidth,
                                           NofAdjustable,true/* AdjustAll*/);

                  } else {
                     // Tool windows do not fit
                     if( -ExtraWidth >= AdjustableWidth ) {
                        _bbdockAdjustRowWidth(area,i,ExtraWidth,TotalAdjustableWidth,
                                              NofAdjustable,true/* AdjustAll*/);
                     } else {
                        _bbdockAdjustRowWidth(area,i,ExtraWidth,AdjustableWidth,
                                              NofAdjustable,false/* AdjustAll*/);
                     }
                  }
               }
               _bbdockResetRowAdjustable(area,i);
            }
            if( area == DOCKINGAREA_BOTTOM ) {
               // Look ahead for ROWBREAK info and draw SIZEBAR here
               j = i;
               for( ;j < _bbdockPaletteLength(area); ++j ) {

                  wid = gbbdockinfo[area][j].wid;
                  if( wid == BBDOCKINFO_ROWBREAK ) {
                     wid = gbbdockinfo[area][j].twspace;
                     ProcessRowBreak(area,next_y,wid,rowNeedsSizebar,RowBreakLineHeight);
                     next_y += RowBreakLineHeight;
                     break;

                  } else if( wid > 0 && 0 != (gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS) ) {
                     // Sizeable
                     rowNeedsSizebar = true;
                  }
               }
            }
         }
         wid = _bbdockContainer(&gbbdockinfo[area][i]);
         if( wid > 0 ) {

            // Explanation:
            // Tab-linked tool windows all belong to the same
            // container (a panel), so we only count the dimensions
            // of the panel once. We still need to check for a
            // sizebarAfterWid however.
            // IMPORTANT:
            // The only sizebarAfterWid in a tabgroup should be on the
            // last tool window in the tabgroup. _bbdockRefresh2() relies
            // on the fact that the .sizebarAfterWid members are already
            // set correctly when it is called.
            if( wid != last_wid ) {
               wid._get_window(x,y,width,height);

               // Just to be safe. Round twips to nearest pixel.
               _lxy2dxy(wid.p_xyscale_mode,x,y);
               _dxy2lxy(wid.p_xyscale_mode,x,y);
               _lxy2dxy(wid.p_xyscale_mode,width,height);
               _dxy2lxy(wid.p_xyscale_mode,width,height);

               new_width = width;
               new_height = height;
               new_y = next_y;
               if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
                  // Sizeable
                  new_x = next_x;
                  rowNeedsSizebar = true;
                  new_height = line_height;

               } else {
                  // Place border on top of SIZEBAR or picture box border above
                  // IF previous tool box need SIZEBARS
                  if( i > 0 && gbbdockinfo[area][i-1].wid > 0 &&
                      (gbbdockinfo[area][i-1].tbflags & TBFLAG_SIZEBARS) ) {
                     new_x = next_x;

                  } else {
                     // IF there is space before this tool-window
                     if( gbbdockinfo[area][i].twspace ) {
                        new_x = next_x + gbbdockinfo[area][i].twspace;
                        new_x = _lx2dx(SM_TWIP,new_x);
                        new_x = _dx2lx(wid.p_xyscale_mode,new_x);
                     } else {
                        new_x = next_x;
                     }
                  }

               }
               if( new_x!=x || new_y!=y || new_width!=width || new_height!=height ) {
                  wid.p_visible=0;
                  wid._move_window(new_x,new_y,new_width,new_height);
               }
               next_x=new_x+new_width;
            }
            int sizebarAfterWid=gbbdockinfo[area][i].sizebarAfterWid;
            if( sizebarAfterWid!=0 ) {
               new_width=sizebarAfterWid.p_width;
               if( sizebarAfterWid.p_style==PSPIC_DEFAULT ) {
                  new_width=_twips_per_pixel_x();
                  if( new_width!=sizebarAfterWid.p_width ) {
                     sizebarAfterWid.p_visible=0;
                     sizebarAfterWid.p_width=new_width;
                  }
                  if( gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS ) {
                     new_x=next_x;
                  } else {
                     new_x=next_x;
                  }

               } else {
                  new_x=next_x;
               }
               if( sizebarAfterWid.p_x!=new_x ) {
                  sizebarAfterWid.p_visible=0;
                  sizebarAfterWid.p_x=new_x;
               }
               if( sizebarAfterWid.p_y!=next_y ) {
                  sizebarAfterWid.p_visible=0;
                  sizebarAfterWid.p_y=next_y;
               }
               if( sizebarAfterWid.p_height!=line_height ) {
                  sizebarAfterWid.p_visible=0;
                  sizebarAfterWid.p_height=line_height;
               }
               next_x=new_x+sizebarAfterWid.p_width;
            }

         } else {
            // Process row break
            // Explanation:
            // The top dock-palette must show the last sizebar.
            // The bottom dock-palette must NOT show the last sizebar.
            int bwid = gbbdockinfo[area][i].twspace;
            if( bwid > 0 && area == DOCKINGAREA_TOP ) {
               ProcessRowBreak(area,next_y+line_height,bwid,rowNeedsSizebar,RowBreakLineHeight);
               next_y += RowBreakLineHeight;
            }
         }
         last_wid=wid;
      }
      height = _bbdockPaletteGet(area).p_height;
      height = _ly2dy(SM_TWIP,height);
      height = _dy2ly(SM_TWIP,height);

      if( height != next_y ) {
         _bbdockPaletteGet(area).p_height = next_y;
      }
      return;
   }

   //
   // DOCKINGAREA_LEFT, DOCKINGAREA_RIGHT case
   //

   // Start from upper left corner
   int next_x = 0;
   int next_y = 0;
   int last_wid = 0;
   int line_height = 0;
   boolean rowNeedsSizebar = false;
   int i, j;
   for( i=0;; ++i ) {

      if( i >= _bbdockPaletteLength(area) ) {
         next_x += line_height;
         break;
      }
      if( last_wid == BBDOCKINFO_ROWBREAK ) {
         next_x += line_height;
         next_y = 0;
         line_height = _bbdockRowWidth(area,i);
         rowNeedsSizebar = false;
         _bbdockGetRowAdjustableHeight(area,i,ExtraWidth,TotalAdjustableWidth,
                                       AdjustableWidth,NofAdjustable);
         // IF the are any controls with SIZEBARS AND some widths need
         // to be adjusted.
         //++dcount;
         if( NofAdjustable != 0 ) {
            if( ExtraWidth != 0 ) {
               // If sum is too small. (Resized MDI window,controls deleted, new screen res)
               if( ExtraWidth > 0 ) {
                  _bbdockAdjustRowHeight(area,i,ExtraWidth,TotalAdjustableWidth,
                                         NofAdjustable,true/* AdjustAll*/);

               } else {
                  // Tool bars don't fit
                  if( -ExtraWidth >= AdjustableWidth ) {
                     _bbdockAdjustRowHeight(area,i,ExtraWidth,TotalAdjustableWidth,
                                            NofAdjustable,true/* AdjustAll*/);

                  } else {
                     _bbdockAdjustRowHeight(area,i,ExtraWidth,AdjustableWidth,
                                            NofAdjustable,false/* AdjustAll*/);
                  }
               }
            }
            _bbdockResetRowAdjustable(area,i);
         }
         if( area == DOCKINGAREA_RIGHT ) {
            // Look ahead for ROWBREAK info and draw SIZEBAR here
            j = i;
            for( ; j < _bbdockPaletteLength(area); ++j ) {
               wid = gbbdockinfo[area][j].wid;
               if( wid == BBDOCKINFO_ROWBREAK ) {
                  wid = gbbdockinfo[area][j].twspace;
                  ProcessRowBreakWidth(area,next_x,wid,rowNeedsSizebar,RowBreakLineHeight);
                  next_x += RowBreakLineHeight;
                  break;

               } else if( wid > 0 && (gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS) ) {
                  rowNeedsSizebar = true;
               }
            }
         }
      }
      wid = _bbdockContainer(&gbbdockinfo[area][i]);
      if( wid > 0 ) {

         // Explanation:
         // Tab-linked tool windows all belong to the same
         // container (a panel), so we only count the dimensions
         // of the panel once. We still need to check for a
         // sizebarAfterWid however.
         // IMPORTANT:
         // The only sizebarAfterWid in a tabgroup should be on the
         // last tool window in the tabgroup. _bbdockRefresh2() relies
         // on the fact that the .sizebarAfterWid members are already
         // set correctly when it is called.
         if( wid != last_wid ) {
            wid._get_window(x,y,width,height);

            // Just to be safe. Round twips to nearest pixel.
            _lxy2dxy(SM_TWIP,x,y);
            _dxy2lxy(SM_TWIP,x,y);
            _lxy2dxy(SM_TWIP,width,height);
            _dxy2lxy(SM_TWIP,width,height);

            new_width = width;
            new_height = height;
            new_x = next_x;
            if( 0 != (gbbdockinfo[area][i].tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               new_y = next_y;
               rowNeedsSizebar = true;
               new_width = line_height;

            } else {
               // Place border on top of SIZEBAR or picture box border above

               // IF previous tool-window needs SIZEBARS
               if( i > 0 && gbbdockinfo[area][i-1].wid > 0 &&
                   (gbbdockinfo[area][i-1].tbflags & TBFLAG_SIZEBARS) ) {

                  new_y = next_y;

               } else {
                  // IF there is space before this tool-window
                  if( gbbdockinfo[area][i].twspace ) {
                     new_y = next_y + gbbdockinfo[area][i].twspace;
                     new_y = _ly2dy(SM_TWIP,new_y);
                     new_y = _dy2ly(SM_TWIP,new_y);

                  } else {
                     new_y = next_y;
                  }
               }

            }
            if( new_x != x || new_y != y || new_width != width || new_height != height ) {
               wid.p_visible = false;
               wid._move_window(new_x,new_y,new_width,new_height);
            }
            if( !wid.p_visible ) {
               //wid.p_visible=true;
            }
            next_y = new_y+new_height;
         }
         int sizebarAfterWid = gbbdockinfo[area][i].sizebarAfterWid;
         if( sizebarAfterWid != 0 ) {
            new_height = sizebarAfterWid.p_height;
            if( sizebarAfterWid.p_style == PSPIC_DEFAULT ) {
               new_height = 0;
               if( new_height != sizebarAfterWid.p_height ) {
                  sizebarAfterWid.p_visible = false;
                  sizebarAfterWid.p_height = new_height;
               }
               new_y = next_y;

            } else {
               new_y=next_y;
            }
            if( sizebarAfterWid.p_y != new_y ) {
               sizebarAfterWid.p_visible = false;
               sizebarAfterWid.p_y = new_y;
            }
            if( sizebarAfterWid.p_x != next_x ) {
               sizebarAfterWid.p_visible = false;
               sizebarAfterWid.p_x = next_x;
            }
            if( sizebarAfterWid.p_width != line_height ) {
               sizebarAfterWid.p_visible = false;
               sizebarAfterWid.p_width = line_height;
            }
            next_y = new_y + sizebarAfterWid.p_height;
         }

      } else {
         // Process row break
         // Explanation:
         // The left dock-palette must show the last sizebar.
         // The right dock-palette must NOT show the last sizebar.
         int bwid = gbbdockinfo[area][i].twspace;
         // IF this is a SIZEBAR on the left
         if( bwid > 0 && area == DOCKINGAREA_LEFT ) {
            ProcessRowBreakWidth(area,next_x+line_height,bwid,rowNeedsSizebar,RowBreakLineHeight);
            next_x += RowBreakLineHeight;
         }
      }
      last_wid = wid;
   }
   width = _bbdockPaletteGet(area).p_width;
   width = _lx2dx(SM_TWIP,width);
   width = _dx2lx(SM_TWIP,width);
   if( width != next_x ) {
      _bbdockPaletteGet(area).p_width = next_x;
   }
   return;
}

enum_flags TBType {
   TBT_TOOL_WINDOW,
   TBT_TOOLBAR,
};

static void _tbAppendToolbarsToMenu(int menu_handle, boolean list_debug_toolbars, int toolbarTypes)
{
   int mask = 0;
   if( _tbDebugQMode() ) {
      mask=TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_LIST_WITH_DEBUG_TOOLBARS;
   } else {
      mask=TBFLAG_WHEN_DEBUGGER_STARTED_ONLY;
   }

   // Append toolbars

   // Finagle a _sort() on an array of structs.
   // Items will be sorted into tbitem[] for toolbars (e.g. all buttons),
   // and twitem[] for tool windows (e.g. sizeable).
   _str twitem[]; twitem._makeempty();
   _str tbitem[]; tbitem._makeempty();
   int i;
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      boolean bool;
      if( list_debug_toolbars ) {
         bool= ( 0!=(ptb->tbflags & mask) && _tbDebugListToolbar(ptb) );
      } else {
         bool= ( 0==(ptb->tbflags & mask) );
      }
      if( bool ) {
         int index = find_index(ptb->FormName,oi2type(OI_FORM));
         int wid = _tbIsVisible(ptb->FormName);
         int tbflags = ptb->tbflags;
         _str item = "";
         if( wid!=0 ) {
            item=wid.p_caption';'(MF_ENABLED|MF_CHECKED)';':+"tbClose "wid;
         } else {
            index = find_index(ptb->FormName,oi2type(OI_FORM));
            if( index!=0 ) {
               int enabled = MF_ENABLED;
               if( _tbIsDisabledToolbar(ptb) ) {
                  enabled = MF_GRAYED;
               }
               item=index.p_caption';'(enabled)';':+"tbSmartShow "ptb->FormName;
            }
         }

         if( item!="" ) {

            if( isToolbar(tbflags) ) {
               // Toolbar
               tbitem[tbitem._length()]=item;
            } else {
               // Tool window
               twitem[twitem._length()]=item;
            }
         }
      }
   }

   // Insert sorted tool windows
   if( toolbarTypes & TBT_TOOL_WINDOW ) {
      twitem._sort('i');
      for( i=0; i<twitem._length(); ++i ) {
         _str caption, mf_flags, cmd;
         parse twitem[i] with caption';'mf_flags';'cmd;
         _menu_insert(menu_handle,-1,(int)mf_flags,caption,cmd);
      }
   }

   // Insert a separator if we are doing both types in this menu
   if (toolbarTypes & TBT_TOOL_WINDOW && toolbarTypes & TBT_TOOLBAR) {
      _menu_insert(menu_handle,-1,MF_ENABLED,"-");
   }

   // Insert sorted toolbars
   if( toolbarTypes & TBT_TOOLBAR ) {
      tbitem._sort('i');
      for( i=0; i<tbitem._length(); ++i ) {
         _str caption, mf_flags, cmd;
         parse tbitem[i] with caption';'mf_flags';'cmd;
         _menu_insert(menu_handle,-1,(int)mf_flags,caption,cmd);
      }
   }
}

/** 
 * Populate toolbaritems array with current toolbars and 
 * toolwindows for use in context menu. 
 * 
 * @param toolbarTypes  0x2 for Toolbar items 
 *                      0x1 for Tool Window items 
 *                      
 * @param toolbaritems reference to array of strings to populate 
 *       [0] caption;visible;command 
 *       [n] caption;visible;command
 * 
 *       caption: menu item caption
 *       visible: 0 (not visible) or 1 (visible)
 *       command: slick-c command to execute
 */
void _tbGetToolbarMenuItems(int toolbarTypes, _str (&toolbaritems)[])
{
   int i;
   boolean debugMode = _tbDebugQMode();
   int mask = 0;
   if (debugMode) {
      mask = TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_LIST_WITH_DEBUG_TOOLBARS;
   } else {
      mask = TBFLAG_WHEN_DEBUGGER_STARTED_ONLY;
   }

   _str standarditems[];
   _str debugitems[];

   // list debug toolbars/windows first
   if (debugMode) {
      for (i = 0; i < def_toolbartab._length(); ++i) {
         _TOOLBAR* ptb = &def_toolbartab[i];
         int index = find_index(ptb->FormName,oi2type(OI_FORM));
         int wid = _tbIsVisible(ptb->FormName);
         int tbflags = ptb->tbflags;
         boolean istoolbar = isToolbar(tbflags);
         boolean bool = (0 != (ptb->tbflags & mask) && _tbDebugListToolbar(ptb));
         if (!bool) {
            continue;
         }

         _str item = "";
         if (wid != 0) {
            item = wid.p_caption';1;':+"tbClose "wid;
         } else {
            item = index.p_caption';0;':+"tbSmartShow "ptb->FormName;
         }
         if (istoolbar && (toolbarTypes & TBT_TOOLBAR)) {
            debugitems[debugitems._length()] = item;
         } else if (!istoolbar && (toolbarTypes & TBT_TOOL_WINDOW)) {
            debugitems[debugitems._length()] = item;
         }
      }
      debugitems._sort('i');
   }

   // get standard tool items
   for (i = 0; i < def_toolbartab._length(); ++i) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      int index = find_index(ptb->FormName,oi2type(OI_FORM));
      int wid = _tbIsVisible(ptb->FormName);
      int tbflags = ptb->tbflags;
      boolean istoolbar = isToolbar(tbflags);
      boolean bool = (0 == (tbflags & mask));
      if (!bool) {
         continue;
      }

      _str item = "";
      if (wid != 0) {
         item = wid.p_caption';1;':+"tbClose "wid;
      } else {
         item = index.p_caption';0;':+"tbSmartShow "ptb->FormName;
      }
      if (istoolbar && (toolbarTypes & TBT_TOOLBAR)) {
         standarditems[standarditems._length()] = item;
      } else if (!istoolbar && (toolbarTypes & TBT_TOOL_WINDOW)) {
         standarditems[standarditems._length()] = item;
      }
   }
   standarditems._sort('i');

   for (i = 0; i < debugitems._length(); ++i) {
      toolbaritems[toolbaritems._length()] = debugitems[i];
   }
   for (i = 0; i < standarditems._length(); ++i) {
      toolbaritems[toolbaritems._length()] = standarditems[i];
   }
}

boolean isToolbar(int tbflags)
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
int _tbContextMenu(boolean list_toolbars=true, int wid=0)
{
   _tbNewVersion();

   int orig_wid = p_window_id;
   if( wid==0 ) {
      // Use the active form
      wid = orig_wid;
   }

   // ignore sizebars
   if (wid.p_object==OI_IMAGE && wid.p_caption=="" && !wid.p_picture && 
       (wid.p_style==PSPIC_SIZEHORZ || wid.p_style==PSPIC_SIZEVERT)) {
      return 0;
   }

   int formWid = wid.p_active_form;
   int index = find_index("_toolbar_menu",oi2type(OI_MENU));
   if( index==0 ) {
      return STRING_NOT_FOUND_RC;
   }

   // Delete "Properties..." item if this is not a toolbar button
   boolean isButtonBarButton = false;
   if (wid.p_object==OI_IMAGE && !wid._ImageIsSpace() && wid.p_eventtab==0) {
      isButtonBarButton=true;
   }
   int menu_handle = formWid._menu_load(index,'P');
   if (isButtonBarButton) {
      int mpos = 0;
      _menu_insert(menu_handle, mpos++, MF_ENABLED, "Properties...", "tbControlProperties "orig_wid);
      _menu_insert(menu_handle, mpos++, MF_ENABLED, "-");
   }

   if (!list_toolbars) {
      int i, nofItems;
      int mf_flags = 0;
      _str caption = '';
      nofItems = _menu_info(menu_handle, 'c');
      for (i = nofItems - 1; i >= 0; --i) {
         _menu_get_state(menu_handle, i, mf_flags, 'P', caption);
         if (mf_flags & MF_SUBMENU) {
            if (caption == 'Toolbars' || caption == 'Tool Windows') {
               _menu_delete(menu_handle, i);
            }
         }
      }
 
   } else {
      _init_menu_toolbars(menu_handle, 0);
      _init_menu_tool_windows(menu_handle, 0);
   }

   if (formWid > 0) {
      _TOOLBAR* ptb = _tbFind(formWid.p_name);
      if (ptb) {
         int mpos = 0;
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Dockable", "tbDockableToggle "formWid);
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Floating", "tbFloatingToggle "formWid);
         if (_IsQToolbar(formWid) && !_QToolbarGetFloating(formWid)) {
            _menu_insert(menu_handle, mpos++, MF_ENABLED, "Movable", "tbMovableToggle "formWid);
         }
         if (_tbIsAutoHideAllowed(ptb) && (formWid.p_DockingArea!=0 || _tbIsAutoShownWid(formWid))) {
            _menu_insert(menu_handle, mpos++, MF_ENABLED,"Auto-hide", "tbAutoHideToggle "formWid);
         }
         _menu_insert(menu_handle, mpos++, MF_ENABLED, "Hide", "tbClose "formWid);
         if (list_toolbars) {
            // There are toolbars listed underneath these items,
            // so insert a separator.
            _menu_insert(menu_handle, mpos++,MF_ENABLED,"-");
         }
      }
   }

   // Show the menu
   int x = 100;
   int y = 100;
   x = wid.mou_last_x('M') - x;
   y = wid.mou_last_y('M') - y;
   _lxy2dxy(wid.p_scale_mode,x,y);
   _map_xy(wid,0,x,y,SM_PIXEL);
   int flags=VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   _KillToolButtonTimer();
   p_window_id = formWid;
   int status=_menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   // Might have selected Hide on a tool-window, so check if still valid
   if( _iswindow_valid(orig_wid) ) {
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
   int status = _menu_find(menu_handle,"toolbars",menuItem,mpos,'m');
   if( status!=0 ) {
      // Not in the View>Toolbars menu
      return;
   }

   // Delete everything after "toolbars" command
   ++mpos;
   status=0;
   while( status==0 ) {
      status=_menu_delete(menuItem, mpos);
   }

   if( _tbDebugQMode() ) {
      _tbAppendToolbarsToMenu(menuItem,true,TBT_TOOLBAR);
   }
   _tbAppendToolbarsToMenu(menuItem,false,TBT_TOOLBAR);

}

/**
 * Insert toolbar list.
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
   int status = _menu_find(menu_handle,"customize_tool_windows",submenu_handle,mpos,'m');
   if( status!=0 ) {
      // Not in the View>Tool Windows menu
      return;
   }

   // Delete everything after "customize_tool_windows" command
   ++mpos;
   status=0;
   while( status==0 ) {
      status=_menu_delete(submenu_handle,mpos);
   }

   if( _tbDebugQMode() ) {
      _tbAppendToolbarsToMenu(submenu_handle,true,TBT_TOOL_WINDOW);
   }
   _tbAppendToolbarsToMenu(submenu_handle,false,TBT_TOOL_WINDOW);
}


//
// _dock_palette_form
//

defeventtab _dock_palette_form;

static boolean onCreateDone(int newValue=-1)
{
   if( newValue != -1 ) {
      _SetDialogInfoHt('onCreateDone',(newValue!=0),0,true);
   }
   typeless val = _GetDialogInfoHt('onCreateDone',0,true);
   val = val == null ? false : val;
   return val;
}

_dock_palette_form.rbutton_up()
{
   if (!isEclipsePlugin()) {
      boolean list_toolbars = ( arg(1)=="" );
      //_tbContextMenu(list_toolbars);
      _str args = list_toolbars','p_window_id;
      _post_call(_tbPostedContextMenu,args);
   }
}

void _dock_palette_form.on_create()
{
   switch( p_DockingArea ) {
   case DOCKINGAREA_TOP:
   case DOCKINGAREA_BOTTOM:
      // Setting orientation is redundant because of p_DockingArea, but what the heck
      _SetDialogInfoHt("orientation",TBORIENT_HORIZONTAL,0,true);
      p_height=700;
      break;
   case DOCKINGAREA_LEFT:
   case DOCKINGAREA_RIGHT:
      _SetDialogInfoHt("orientation",TBORIENT_VERTICAL,0,true);
      p_width=700;
      break;
   default:
      // Floating palette
      _SetDialogInfoHt("orientation",TBORIENT_NONE,0,true);
      p_width=700;
   }
   p_old_width=p_width;
   p_old_height=p_height;
   //messageNwait("_dock_palette_form.on_create: width="p_width" height="p_height);
   onCreateDone(1);
}

static boolean inOnResize(int newValue=-1)
{
   if( newValue != -1 ) {
      _SetDialogInfoHt('inOnResize',(newValue!=0),0,true);
   }
   typeless val = _GetDialogInfoHt('inOnResize',0,true);
   val = val == null ? false : val;
   return val;
}

void _dock_palette_form.on_resize()
{
   // If on_create not processed
   if( !onCreateDone() || p_DockingArea==0 ) {
      return;
   }
   if( inOnResize() ) {
      // No infinite recursion!
      return;
   }
   inOnResize(1);
   int mdi=_mdi;
   mdi._bbdockRefresh(p_DockingArea);
   inOnResize(0);
}

void _dock_palette_form.lbutton_double_click()
{
   toolbars();
}

void _dock_palette_form.lbutton_down()
{
   if( p_style != PSPIC_SIZEVERT && p_style != PSPIC_SIZEHORZ ) {
      // Not clicking on a sizebar, so quietly fail
      return;
   }

   // User clicked on line or SIZEBAR

   int focus_wid = _get_focus();

   int mdiclient_x = 0;
   int mdiclient_y = 0;
   int mdiclient_width = 0;
   int mdiclient_height = 0;
   _mdi._MDIClientGetWindow(mdiclient_x,mdiclient_y,mdiclient_width,mdiclient_height);
   boolean tb = ( p_DockingArea == DOCKINGAREA_TOP || p_DockingArea == DOCKINGAREA_BOTTOM );
   DockingArea area = DOCKINGAREA_NONE;
   int i = 0;
   int j = 0;
   int tabgroup = 0;
   int tabOrder = 0;
   _bbdockFindWid(p_window_id,area,i,tabgroup,tabOrder);
   // IF user clicked on row SIZEBAR
   int style = p_style;
   int selected_wid = p_window_id;
   // Limit the range of movement of the mouse to form or frame
   //p_window_id = selected_wid.p_parent;
   int capture_wid = selected_wid.p_parent;
   int wid = 0;
   int x1 = 0, x2 = 0;
   int y1 = 0, y2 = 0;
   if( style == PSPIC_SIZEVERT && tb ) {
      // Do not let mouse move before left control or after right control
      x1 = _bbdockContainer(&gbbdockinfo[area][i]).p_x;
      wid = _bbdockContainer(&gbbdockinfo[area][i+1]);
      x2 = wid.p_x + wid.p_width;
      x1 = _lx2dx(SM_TWIP,x1);
      x2 = _lx2dx(SM_TWIP,x2);
      capture_wid.mou_limit(x1,0,x2,capture_wid.p_client_height);

   } else if( style == PSPIC_SIZEHORZ  && !tb ) {
      // Do not let mouse move before left control or after right control
      y1 = _bbdockContainer(&gbbdockinfo[area][i]).p_y;
      wid = _bbdockContainer(&gbbdockinfo[area][i+1]);
      y2 = wid.p_y + wid.p_height;
      y1 = _ly2dy(SM_TWIP,y1);
      y2 = _ly2dy(SM_TWIP,y2);
      capture_wid.mou_limit(0,y1,capture_wid.p_client_width,y2);

   } else if( style == PSPIC_SIZEVERT && !tb ) {
      //p_window_id = _mdi;
      capture_wid = _mdi;

   } else if( style == PSPIC_SIZEHORZ  && tb ) {
      //p_window_id = _mdi;
      capture_wid = _mdi;

   } else {
      // ???
      return;
   }

   mou_mode(1);
   capture_wid.mou_capture();
   _KillToolButtonTimer();
   int morig_x = capture_wid.mou_last_x('M');
   int morig_y = capture_wid.mou_last_y('M');
   boolean done = false;
   int orig_x, orig_y, orig_width, orig_height;
   selected_wid._get_window(orig_x,orig_y,orig_width,orig_height);
   if( capture_wid.p_object == OI_MDI_FORM ) {
      _lxy2dxy(selected_wid.p_xyscale_mode,orig_x,orig_y);
      _lxy2dxy(selected_wid.p_xyscale_mode,orig_width,orig_height);
      //_lxy2dxy(selected_wid.p_xyscale_mode,morig_x,morig_y);
      _map_xy(selected_wid.p_parent,_mdi,orig_x,orig_y,SM_PIXEL);
   }

   x1 = orig_x;
   y1 = orig_y;
   x2 = x1 + orig_width;
   y2 = y1 + orig_height;

   int orig_x1 = x1;
   int orig_y1 = y1;
   int orig_x2 = x2;
   int orig_y2 = y2;

   _str event = '';
   int new_x1 = x1;
   int new_y1 = y1;
   int new_x2 = x2;
   int new_y2 = y2;
   int width = 0;
   int height = 0;

   // Did we move the mouse a minimal amount to justify drawing the
   // rubber-band window?
   boolean checkMinDrag = true;

   // Did we actually move the sizebar from its original position?
   boolean moved = false;

   sc.controls.RubberBand rubberBand(capture_wid);
   rubberBand.setWindow(orig_x1,orig_y1,orig_width,orig_height);

   se.util.MousePointerGuard mousePointerSentry(MP_DEFAULT,capture_wid);
   switch( style ) {
   case PSPIC_SIZEHORZ:
      mousePointerSentry.setMousePointer(MP_SPLITVERT);
      break;
   case PSPIC_SIZEVERT:
      mousePointerSentry.setMousePointer(MP_SPLITHORZ);
      break;
   }

   do {

      event = capture_wid.get_event();
      switch( event ) {
      case MOUSE_MOVE:

         new_x1 = x1;
         new_y1 = y1;
         new_x2 = x2;
         new_y2 = y2;

         switch( style ) {
         case PSPIC_SIZEVERT:
            width = x2 - x1;
            new_x1 = orig_x1 + capture_wid.mou_last_x('M') - morig_x;
            new_x2 = new_x1 + width;
            moved = new_x1 != orig_x1;
            rubberBand.move(new_x1,orig_y1);
            break;

         case PSPIC_SIZEHORZ:
            height = y2 - y1;
            new_y1 = orig_y1 + capture_wid.mou_last_y('M') - morig_y;
            new_y2 = new_y1 + height;
            moved = new_y1 != orig_y1;
            rubberBand.move(orig_x1,new_y1);
         }

         x1 = new_x1;
         y1 = new_y1;
         x2 = new_x2;
         y2 = new_y2;

         // Remember coordinates are relative to the desktop and in pixels
         if( checkMinDrag ) {
            if( moved ) {
               checkMinDrag=false;
               if( !rubberBand.isVisible() ) {
                  rubberBand.setVisible(true);
               }
            }
         }

         break;

      case LBUTTON_UP:
      case ESC:
         done = true;
      }

   } while( !done );

   capture_wid.mou_limit(0,0,0,0);
   mou_mode(0);
   selected_wid.mou_release();

   int wid1 = 0;
   int wid2 = 0;
   int adjust_x = 0;
   int adjust_y = 0;
   int row_start = 0;
   int sizebar_wid = 0;
   int RowHeight = 0;

   if( moved ) {

      if( event != ESC ) {

         if( style == PSPIC_SIZEVERT && tb ) {
            wid1 = _bbdockContainer(&gbbdockinfo[area][i]);
            wid2 = _bbdockContainer(&gbbdockinfo[area][i+1]);
            adjust_x=x1-orig_x1;

            // Round twips to nearest pixel
            adjust_x = _lx2dx(SM_TWIP,adjust_x);
            adjust_x = _dx2lx(SM_TWIP,adjust_x);

            if( (wid1.p_width+adjust_x) < 0 ) {
               adjust_x = -wid1.p_width;
            }
            if( (wid2.p_width-adjust_x) < 0 ) {
               adjust_x = wid2.p_width;
            }
            wid1.p_width = wid1.p_width + adjust_x;
            wid2.p_x = wid2.p_x + adjust_x;
            wid2.p_width = wid2.p_width - adjust_x;
            selected_wid.p_x += adjust_x;

         } else if( style == PSPIC_SIZEHORZ  && !tb ) {
            wid1 = _bbdockContainer(&gbbdockinfo[area][i]);
            wid2 = _bbdockContainer(&gbbdockinfo[area][i+1]);
            adjust_y = y1 - orig_y1;

            // Round twips to nearest pixel
            adjust_y = _ly2dy(SM_TWIP,adjust_y);
            adjust_y = _dy2ly(SM_TWIP,adjust_y);

            if( (wid1.p_height+adjust_y) < 0 ) {
               adjust_y =- wid1.p_height;
            }
            if( (wid2.p_height-adjust_y) < 0 ) {
               adjust_y = wid2.p_height;
            }
            wid1.p_height = wid1.p_height + adjust_y;
            wid2.p_y = wid2.p_y + adjust_y;
            wid2.p_height = wid2.p_height - adjust_y;
            selected_wid.p_y += adjust_y;

         } else if( style == PSPIC_SIZEVERT && !tb ) {
            adjust_x = x1 - orig_x1;
            adjust_x = _dx2lx(SM_TWIP,adjust_x);
            // Find the beginning of this row
            row_start = i - 1;
            sizebar_wid = 0;
            for( ;row_start >= 0 && gbbdockinfo[area][row_start].wid != BBDOCKINFO_ROWBREAK; --row_start ) {
               wid = gbbdockinfo[area][row_start].wid;
               if( wid > 0 &&
                   0 != (gbbdockinfo[area][row_start].tbflags&TBFLAG_SIZEBARS) ) {

                  sizebar_wid = wid;
               }
            }
            ++row_start;
            RowHeight = _bbdockRowWidth(area,row_start);
            if( sizebar_wid != 0 ) {
               //adjust_x = _lx2dx(SM_TWIP,adjust_x); adjust_x = _dx2lx(SM_TWIP,adjust_x);
               if( area == DOCKINGAREA_RIGHT ) {
                  adjust_x = -adjust_x;
               }
               if( (RowHeight+adjust_x) < 0 ) {
                  adjust_x = -RowHeight;
               }
               // Make sure there is some client area left
               if( adjust_x > 0 && _lx2dx(SM_TWIP,adjust_x) > mdiclient_width ) {
                  //message("got here "_lx2dx(SM_TWIP,adjust_x)" "mdiclient_height);
                  adjust_x = _dx2lx(SM_TWIP,mdiclient_width);
               }
               RowHeight += adjust_x;
               for( j=row_start; gbbdockinfo[area][j].wid != BBDOCKINFO_ROWBREAK; ++j ) {
                  wid = _bbdockContainer(&gbbdockinfo[area][j]);
                  if( wid > 0 &&
                      0 != (gbbdockinfo[area][j].tbflags&TBFLAG_SIZEBARS) ) {

                     wid.p_width = RowHeight;
                  }
               }
               _mdi._bbdockRefresh(area);
            }

         } else if( style == PSPIC_SIZEHORZ  && tb ) {

            adjust_y = y1 - orig_y1;
            adjust_y = _dy2ly(SM_TWIP,adjust_y);
            // Find the beginning of this row
            row_start = i - 1;
            sizebar_wid = 0;
            for( ;row_start >= 0 && gbbdockinfo[area][row_start].wid != BBDOCKINFO_ROWBREAK; --row_start ) {
               wid = gbbdockinfo[area][row_start].wid;
               if( wid > 0 &&
                   0 != (gbbdockinfo[area][row_start].tbflags &TBFLAG_SIZEBARS) ) {

                  sizebar_wid = wid;
               }
            }
            ++row_start;
            if( sizebar_wid != 0 ) {
               int orig_adjust_y = adjust_y;
               int orig_row_start = row_start;
               for( ;; ) {

                  //adjust_y = _ly2dy(SM_TWIP,adjust_y); adjust_y = _dy2ly(SM_TWIP,adjust_y);
                  RowHeight = _bbdockRowHeight(area,row_start);
                  if( area == DOCKINGAREA_BOTTOM ) {
                     adjust_y = -adjust_y;
                  }
                  if( (RowHeight+adjust_y) < 0 ) {
                     adjust_y = -RowHeight;
                  }
                  // Make sure there is some client area left
                  if( adjust_y > 0 && _ly2dy(SM_TWIP,adjust_y) > mdiclient_height ) {
                     //message("got here "_ly2dy(SM_TWIP,adjust_y)" "mdiclient_height);
                     adjust_y = _dy2ly(SM_TWIP,mdiclient_height);
                  }
                  RowHeight += adjust_y;
                  boolean snappedBack = true;
                  for( j=row_start; gbbdockinfo[area][j].wid != BBDOCKINFO_ROWBREAK; ++j ) {
                     wid = _bbdockContainer(&gbbdockinfo[area][j]);
                     if( wid > 0 &&
                         0 != (gbbdockinfo[area][j].tbflags & TBFLAG_SIZEBARS) ) {

                        int orig_wid_height = wid.p_height;
                        wid.p_height = RowHeight;
                        // Test to see if the tool window tried to adjust its height in the direction we wanted.
                        // If the tool window tried to adjust its height in the direction we wanted, then we
                        // are happy (i.e. snappedBack=false).
                        if( sign(wid.p_height - orig_wid_height) == sign(adjust_y) || wid.p_height == RowHeight ) {
                           snappedBack = false;
                        }
                     }
                  }
                  // if the toolbar did not accept the resize request
                  if( snappedBack ) {
                     if( area == DOCKINGAREA_BOTTOM && (j+1) < _bbdockPaletteLength(area) ) {
                        row_start = j + 1;
                        adjust_y = orig_adjust_y;
                        continue;
                     }
                     if (area != DOCKINGAREA_BOTTOM && orig_row_start > 1) {
                        row_start = _bbdockRowStart(area,row_start-2);
                        adjust_y = orig_adjust_y;
                        orig_row_start = row_start;
                        continue;
                     }
                  }
                  break;
               }

               _mdi._bbdockRefresh(area);
            }

         } else {
            return;
         }
         //selected_wid._move_window(x1,y1,x2-x1,y2-y1)
      }
   }

   if( focus_wid != 0 ) {
      focus_wid._set_focus();
   }
}

/**
 * Reset all tool windows to a default layout.
 */
void _bbdockReset()
{
   if( !_tbIsDockingAllowed() ) {
      // Docking disallowed globally
      return;
   }

   // Remove all side and floating palettes
   int i;
   int wid;
   for( i=DOCKINGAREA_FIRST; i<=_bbdockPaletteLastIndex(); ++i ) {
      wid = _bbdockPaletteGet(i);
      if( wid > 0 ) {
         wid._delete_window();
      }
   }
   gbbdockinfo._makeempty();

   if( _tbFullScreenQMode() ) {
      _tbcommon_fullscreen_settings();
      if (!_tbDebugQMode()) {
         return;
      }
   }

   int focus_wid = _get_focus();

   _str form_name = '';

//#define NO_DOCKINGAREA_TOP
//#define NO_DOCKINGAREA_LEFT
//#define NO_DOCKINGAREA_BOTTOM
//#define NO_DOCKINGAREA_RIGHT

#ifndef NO_DOCKINGAREA_TOP
   _tbResetDefaultQToolbars();

   // DOCKINGAREA_TOP
   _mdi._bbdockRefresh(DOCKINGAREA_TOP);
#endif /* NO_DOCKINGAREA_TOP */

#ifndef NO_DOCKINGAREA_LEFT
   // DOCKINGAREA_LEFT
   if( _tbDebugQMode() ) {
      form_name="_tbdebug_stack_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         0,-1);
      form_name="_tbdebug_breakpoints_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         0,-1);
      form_name="_tbdebug_exceptions_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
   } else {

      // Start of tab-linked: Projects, Defs, Class, Symbols, Open
      form_name="_tbprojects_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbproctree_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbclass_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbcbrowser_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbopen_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_LEFT,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      // End of tab-linked: Projects, Defs, Class, Symbols, Open
   }
   _mdi._bbdockRefresh(DOCKINGAREA_LEFT);
   if( _tbDebugQMode() ) {
      // Make the Build tab active
      activate_toolbar("_tbdebug_breakpoints_form","");
   } else {
      // Make the Projects tab active
      activate_toolbar("_tbprojects_form","");
   }
#endif /* NO_DOCKINGAREA_LEFT */

#ifndef NO_DOCKINGAREA_BOTTOM
   // DOCKINGAREA_BOTTOM
   if( _tbDebugQMode() ) {
      //say('no existing toolbar data');
      //say('put default debug toolbar settings here');
      //form_name="_tbdebug_stack_form";
      //wid=_find_formobj(form_name,'N');
      //if (wid) wid._delete_window();
      //_mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
      //                          find_index(form_name,oi2type(OI_FORM)),
      //                          TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0);

      form_name="_tbdebug_autovars_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbdebug_locals_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);
      form_name="_tbdebug_members_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         -1,-1);

      form_name="_tbdebug_watches_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0,
                         0,-1);

      // Start of tab-linked: Search, Symbol, References, Build, Output
      form_name="_tbsearch_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,true,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbtagwin_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbtagrefs_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbshell_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbmessages_browser_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tboutputwin_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      // End of tab-linked: Search, Symbol, References, Build, Message List, Output

      // Make the Autos tab active
      activate_toolbar("_tbdebug_autovars_form","");

      // Make the Build tab active
      activate_toolbar("_tbshell_form","");

   } else {
      form_name="_tbbufftabs_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,true,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS|TBFLAG_NO_CAPTION,0);

      // Start of tab-linked: Search, Symbol, References, Build, Output
      form_name="_tbsearch_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,true,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbtagwin_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbtagrefs_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbshell_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tbmessages_browser_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      form_name="_tboutputwin_form";
      wid=_find_formobj(form_name,'N');
      wid=_tbContainerFromWid(wid);
      if( wid!=0 ) wid._delete_window();
      _mdi._bbdockInsert(DOCKINGAREA_BOTTOM,-1,false,false,
                         find_index(form_name,oi2type(OI_FORM)),
                         TBFLAG_ALWAYS_ON_TOP|TBFLAG_ALLOW_DOCKING|TBFLAG_SIZEBARS,0
                         -1,-1);
      // End of tab-linked: Search, Symbol, References, Build, Message List, Output

      // Make the Build tab active
      activate_toolbar("_tbshell_form","");
   }
   _mdi._bbdockRefresh(DOCKINGAREA_BOTTOM);
#endif /* NO_DOCKINGAREA_BOTTOM */

   // Pick up other toolbars that are supposed to be docked
   for( i=0;i<def_toolbartab._length();++i ) {

      if( def_toolbartab[i].restore_docked && !_tbIsVisible(def_toolbartab[i].FormName) ) {
         int debug_flags = TBFLAG_WHEN_DEBUGGER_STARTED_ONLY|TBFLAG_WHEN_DEBUGGER_SUPPORTED_ONLY;
         if( (_tbDebugQMode() && 0!=(def_toolbartab[i].tbflags & debug_flags) ) ||
             (!_tbDebugQMode() && 0==(def_toolbartab[i].tbflags & debug_flags)) ) {

            wid = _tbIsAutoHidden(def_toolbartab[i].FormName);
            if( wid>0 ) {
               wid._tbSmartDeleteWindow();
            }
            if( 0!=def_toolbartab[i].docked_area ) {
               // Dock this toolbar
               _mdi._bbdockInsert(def_toolbartab[i].docked_area,-1,false,false,
                                  find_index(def_toolbartab[i].FormName,oi2type(OI_FORM)),
                                  def_toolbartab[i].tbflags,0);
               _mdi._bbdockRefresh(def_toolbartab[i].docked_area);
            } else {
               // Just display this toolbar
               def_toolbartab[i].restore_docked=false;
               tbShow(def_toolbartab[i].FormName);
            }
         }
      }
   }

   if( focus_wid!=0 ) {
      focus_wid._set_focus();
   }

   // Update panel captions to reflect current focus
   _tbpanelUpdateAllPanels();
}

_command void tbResetAll(...)
{
   def_toolbartab._makeempty();
   _tbNewVersion();
   dockchanResetAll();
   _tbDeleteAllQToolbars();
   _bbdockReset();
   if (!def_tbreset_with_file_tabs) {
      _tbToggleTabGroupToolbar('_tbbufftabs_form');
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

/**
 * Operates on a tool window wid.
 * <p>
 * Deletes the active tool window.
 * <p>
 * If the tool window is the child of a panel, then the panel is deleted.
 * If the tool window is the child of a SSTab container tabgroup, then
 * the tab that contains the tool window is deleted. If the tool
 * window is autoshown, then it is autohidden (unless overridden
 * by deleteAutoShown parameter).
 * 
 * @param deleteAutoShown Set to true if you want autoshown tool
 *                        windows deleted instead of autohidden.
 *                        Defaults to false.
 */
void _tbSmartDeleteWindow(boolean deleteAutoShown=false)
{
   int wid = _tbContainerFromWid(p_window_id);
   if( _tbpanelIsPanel(wid) && (deleteAutoShown || !_tbIsAutoShownWid(wid)) ) {
      int child = wid._tbpanelFindChild();
      if( child.p_object==OI_SSTAB ) {
         // Delete the tab that this tool window is a child of
         int tabgroupcontainer = _tbTabGroupContainerWidFromWid(p_window_id);
         int old_ActiveTab = child.p_ActiveTab;
         tabgroupcontainer._makeActive();
         int deleted_ActiveTab = child.p_ActiveTab;
         // Call the ON_DESTROY event for the tool window on this tab
         // since _deleteActive() will not do it. We do this in order
         // to have the tool window save its info in def_toolbartab
         // so we can perform smart-redocking later.
         call_event(p_window_id,ON_DESTROY,'W');
         child._deleteActive();
         if( old_ActiveTab!=deleted_ActiveTab ) {
            child.p_ActiveTab=old_ActiveTab;
         }
         if( child.p_NofTabs > 0 ) {
            // We still have tab(s) remaining
            if( child.p_NofTabs == 1 ) {
               // Down to 1 tab, so hide the tab row
               child.p_HideTabRow = true;
            }
            // We still have a SSTab control. Since _deleteActive() does not
            // send ON_CHANGE to indicate that the active tab has changed,
            // we have to do it. We do this so the tool window will get
            // resized to fill its tab container.
            child.call_event(CHANGE_TABACTIVATED,child,ON_CHANGE,'W');
         } else {
            // That was the last tab, so delete the tab control
            wid._delete_window();
         }

      } else {
         if( _tbIsAutoShownWid(wid) ) {
            // Hide it quickly
            _tbAutoHide(wid);
         }
         wid._delete_window();
      }

   } else if( _tbIsAutoShownWid(wid) ) {
      // Hide it quickly
      _tbAutoHide(wid);

   } else if (_IsQToolbar(wid)) {
      _tbDeleteQToolbar(wid);

   } else {
      int child_wid=0;
      if (!_no_child_windows()) {
         child_wid=_mdi.p_child;
      }
      // Toolbar or caption-less tool window, so just delete it
      wid.p_active_form._delete_window();
      if (child_wid) {
         child_wid._set_focus();
      }
   }
}

/**
 * Operates on a tool window wid.
 * <p>
 * Deletes the active tool window.
 * @param docking this parameter should be true if the toolbar is being docked or undocked
 */
static void _tbMaybeDeleteWindow(boolean docking)
{
   int wid = p_window_id;
   _str form_name = p_name;
   //say('_tbMaybeDeleteWindow: form_name='form_name);
   //say('_tbMaybeDeleteWindow: wid.p_DockingArea='wid.p_DockingArea);
   if( _tbIsRecyclable(form_name) ) {
      return;
   }

   //_message_box('delete');
   // Some OEMs rely on ON_CLOSE being called in order to save data
   // associated with their tool window, so call it.
   // IMPORTANT:
   // We use _event_handler() to check for the existence of an
   // ON_CLOSE event handler because the default handler will
   // destroy the form. We do not want that to happen if we can
   // avoid it, since WE want to be the one to dispose of the
   // form.
   // 1/31/2007 - rb
   // IMPORTANT:
   // Do NOT call on_close event handler if it is the default _toolbar_etab2.on_close
   // event handler since that one will delete the active form. The _toolbar_etab2.on_close
   // handler is only called when the user hits the 'X' on the tool window.
   _str handler = wid._event_handler(on_close);
   int toolbarEtab2OnCloseIndex = eventtab_index(defeventtab _toolbar_etab2,defeventtab _toolbar_etab2,event2index(on_close));
   //say('_tbMaybeDeleteWindow: handler='handler'  toolbarEtab2OnCloseIndex='toolbarEtab2OnCloseIndex);
   if( handler!=0 && handler != toolbarEtab2OnCloseIndex ) {
      // Save the container since on_close might rip this tool window
      // out from under us!
      int container = _tbContainerFromWid(wid);
      // Window ids are reused a lot, so it is not enough to check the wid
      _str FormName = wid.p_name;
      wid.call_event(docking,wid,on_close,'w');
      if( !_iswindow_valid(wid) || wid.p_name!=FormName ) {

         // The window is gone, so delete its container too
         if( container!=wid && _iswindow_valid(container) ) {
            container._delete_window();
         }
         return;
      }
   }
   wid._tbSmartDeleteWindow();
}

/**
 * No frills.
 * <p>
 * Close this tool window and no other. Need this for auto
 * restore where we restore tool windows in a tabgroup and we do
 * not want the smart version that uses the
 * TBOPTION_CLOSE_TABGROUP option to restore ALL tool windows in
 * the tabgroup.
 * 
 * @param wid Tool window to close.
 */
void _tbClose(int wid,boolean docking=false)
{
   if (_IsQToolbar(wid)) {
      _tbDeleteQToolbar(wid);
      return;

   } else if( wid.p_DockingArea!=0 ) {
      DockingArea area, i, tabgroup, tabOrder;
      boolean wasFound=_bbdockFindWid(wid,area,i,tabgroup,tabOrder);
      _mdi._bbdockRespaceAndRemove(area,i,docking);
      if( _tbIsNoRefreshArea(area) ) {
         //say('skipped refresh');
         return;
      }
      _mdi._bbdockMaybeRemoveButtonBar(area,docking);
      _mdi._bbdockRefresh(area);

      // Update panel captions to reflect current focus
      _tbpanelUpdateAllPanels(/*area*/);
      return;

   } else if( _tbIsAutoShownWid(wid) || _tbIsAutoHiddenWid(wid) ) {
      _str FormName = wid.p_name;
      wid._tbSmartDeleteWindow(true);
      // User hit the X, so remove from dock channel item too
      dockchanRemove(FormName);
      return;
   }
   wid._tbMaybeDeleteWindow(docking);
}

/**
 * @param wid window id of toolbar to close
 * @param docking this parameter should be true if the toolbar is being docked or undocked
 */
_command void tbClose(...) name_info(FORM_ARG',')
{
   _tbNewVersion();
   int wid = arg(1);
   boolean docking=false;
   if ( arg()>1 ) {
      docking=arg(2);
   }
   //say('tbClose: wid='wid'  wid.p_name='wid.p_name);

   if( !docking ) {
      // User is closing this tool window (e.g. hitting 'X')
      typeless state = null;
      wid._tbSaveState(state,true);
      if( state != null ) {
         _SetDialogInfoHt("tbState.":+wid.p_active_form.p_name, state, _mdi);
      }
   }

   DockingArea area, i, tabgroup, tabOrder;
   if( wid.p_DockingArea!=0 && _bbdockFindWid(wid,area,i,tabgroup,tabOrder) ) {
      //say('tbClose: tabgroup='tabgroup);
      if( tabgroup>0 && 0!=(def_toolbar_options & TBOPTION_CLOSE_TABGROUP) ) {
         // Close all tab-linked tool windows in this tabgroup
         _tbCloseTabGroup(tabgroup,area,docking);
         return;
      }
      // Fall through to default processing
   }
   _tbClose(wid,docking);
}

static void _tbShowFinishUp(int wid, boolean hasSizeBars, _TOOLBAR *ptb, DockingArea area, int docked_row, boolean delayRefresh=false)
{
   int i = 0;
   int tabgroup = 0;
   int tabOrder = 0;
   _mdi._bbdockFindWid(wid,area,i,tabgroup,tabOrder);
   int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);

   int height = 0;
   int width = 0;
   if( hasSizeBars ) {
      height=ptb->docked_height;
      width=ptb->docked_width;
      //messageNwait('h1');
      container_wid.p_height=height;
      //messageNwait('h2 n='wid.p_name' h='height);
      container_wid.p_width=width;
      if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
         gbbdockinfo[area][i].twspace=width;
      } else {
         gbbdockinfo[area][i].twspace=height;
      }
   }
   gbbdockinfo[area][i].docked_row= docked_row;
   for( ;;++i ) {
      if( i>=_bbdockPaletteLength(area) ) {
         break;
      }
      if( gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK ) {
         //_message_box('restore docked_row='docked_row);
         gbbdockinfo[area][i].docked_row=docked_row;
         break;
      }
   }

   _bbdockAdjustLeadingSpace(area);
   if( !delayRefresh ) {
      _mdi._bbdockRefresh(area);
   }
}

void _tbShowDocked(_str FormName, int default_area= -1, boolean delayRefresh=false)
{
   _tbNewVersion();
   _TOOLBAR *ptb = _tbFind(FormName);
   int index = find_index(FormName,oi2type(OI_FORM));
   if( !ptb || index==0 ) {
      _message_box('Form 'FormName' not found');
      return;
   }

   // Remove from dock channel.
   // Need to do this for the case of tool window auto hidden and user
   // shows tool window (with context menu, tbShow, etc.).
   dockchanRemove(FormName);

   int wid = _find_formobj(FormName,'n');
   if( _tbIsAutoWid(wid) ) {
      // Destroy it first
      wid._tbSmartDeleteWindow();
      wid=0;
   }
   if( wid!=0 ) {
      if( wid.p_DockingArea!=0 ) {
         // This is already docked
         return;
      }
      _tbClose(wid,true);
   }
   boolean hasSizeBars = 0!=( ptb->tbflags & TBFLAG_SIZEBARS );
   DockingArea area = ptb->docked_area;
   if( area==0 ) {
      if( default_area<0 ) {
         if( hasSizeBars ) {
            area=DOCKINGAREA_BOTTOM;
         } else {
            area=DOCKINGAREA_TOP;
         }

      } else {
         area=default_area;
      }
   }
   int tb_width = 0;
   int tb_height = 0;
   int adjust_docked_x = 0;
   int adjust_docked_y = 0;
   if( hasSizeBars ) {

      if( ptb->docked_area==0 ) {
         tb_width=TBDEFAULT_DOCK_WIDTH*_twips_per_pixel_x();
         tb_height=TBDEFAULT_DOCK_HEIGHT*_twips_per_pixel_y();
         ptb->docked_width=tb_width;
         ptb->docked_height=tb_height;

      } else {
         // Add one side of border
         //ptb->docked_width-=_twips_per_pixel_x();
         //ptb->docked_height-=_twips_per_pixel_y();
      }
      adjust_docked_x= -_twips_per_pixel_x();
      adjust_docked_y= -_twips_per_pixel_y();

   } else {

      if( ptb->docked_area==0 ) {
         tb_width=TBDEFAULT_DOCK_WIDTH*_twips_per_pixel_x();
         tb_height=TBDEFAULT_DOCK_HEIGHT*_twips_per_pixel_y();

      } else {
         // Remove one side of border
         tb_width=ptb->docked_width-_twips_per_pixel_x();
         tb_height=ptb->docked_height-_twips_per_pixel_y();
      }
      ptb->docked_width=tb_width;
      ptb->docked_height=tb_height;
   }
   if( ptb->docked_area==0 ) {
      ptb->docked_area=area;
      ptb->docked_row=_bbdockQMaxRestoreRow(area)+1;
      ptb->docked_x=0;
      ptb->docked_y=0;
      ptb->docked_width=tb_width;
      ptb->docked_height=tb_height;
   }
   area=ptb->docked_area;
   // IF there is nothing docked on this side
   int docked_row = 0;
   int i = 0;
   int tabgroup = 0;
   int tabOrder = 0;
   if( 0==_mdi._bbdockPaletteGet(area) ) {
      docked_row=ptb->docked_row;
      ptb->docked_area=0;
      gIgnoreInsertRestoreRow=true;
      wid=_mdi._bbdockInsert(area,-1,false,false,
                             index,ptb->tbflags,0,
                             ptb->tabgroup,ptb->tabOrder);
      gIgnoreInsertRestoreRow=false;
      _bbdockFindWid(wid,area,i,tabgroup,tabOrder);
      if( !hasSizeBars ) {
         if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
            gbbdockinfo[area][i].twspace=ptb->docked_x;

         } else {
            gbbdockinfo[area][i].twspace=ptb->docked_y;
         }
      }
      _tbShowFinishUp(wid,hasSizeBars,ptb,area,docked_row,delayRefresh);
      return;
   }
   // Find the row
   int max_restore_row=0;
   for( i=_bbdockPaletteLength(area)-1;i>=0;--i ) {
      if( gbbdockinfo[area][i].wid==BBDOCKINFO_ROWBREAK ) {
         if( 0!=gbbdockinfo[area][i].docked_row ) {
            max_restore_row=gbbdockinfo[area][i].docked_row;
            break;
         }
      }
   }
   if( ptb->docked_row>max_restore_row ) {
      docked_row=ptb->docked_row;
      gIgnoreInsertRestoreRow=true;
      wid=_mdi._bbdockInsert(area,-1,true,false,
                             index,ptb->tbflags,0,
                             ptb->tabgroup,ptb->tabOrder);
      gIgnoreInsertRestoreRow=false;
      _bbdockFindWid(wid,area,i,tabgroup,tabOrder);
      if( !hasSizeBars ) {
         if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
            gbbdockinfo[area][i].twspace=ptb->docked_x;

         } else {
            gbbdockinfo[area][i].twspace=ptb->docked_y;
         }
      }
      _tbShowFinishUp(wid,hasSizeBars,ptb,area,docked_row,delayRefresh);
      return;
   }

   // This row already exists. Determine where
   // to insert this tool window.

   int arearect_x1, arearect_y1, arearect_x2, arearect_y2;
   int x,y,width,height;

   wid=_mdi._bbdockPaletteGet(area);
   if( wid!=0 ) {
      wid._get_window(x,y,width,height);
      _lxy2dxy(wid.p_xyscale_mode,x,y);
      _lxy2dxy(wid.p_xyscale_mode,width,height);
      _map_xy(_mdi,0,x,y,SM_PIXEL);
      arearect_x1=x;
      arearect_y1=y;
      arearect_x2=arearect_x1+width;
      arearect_y2=arearect_y1+height;
   }

   int orig_area = 0;
   int orig_i = -1;
   boolean rowBreakAfter = false;
   boolean rowBreakBefore = false;
   int new_x1 = 0;
   int new_y1 = 0;
   int new_x2 = 0;
   int new_y2 = 0;
   int new_i = -2;  // Nothing to do
   int new_twspace, new_twspace2;
   boolean putInRowBreakAfter = false;

   if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
      new_x1=_lx2dx(SM_TWIP,ptb->docked_x);
      int junk_y=0;
      _map_xy(wid,0,new_x1,junk_y);
      new_x2=_lx2dx(SM_TWIP,ptb->docked_x+ptb->docked_width);
      _map_xy(wid,0,new_x2,junk_y);
      _mdi._bbdockPositionTB(area,arearect_x2,arearect_y1,
                             orig_area,orig_i,hasSizeBars,
                             new_i,new_twspace,new_twspace2,
                             new_x1+adjust_docked_x,new_y1,
                             new_x2+adjust_docked_x,new_y2,
                             ptb->docked_row,putInRowBreakAfter);

   } else {
      new_y1=wid._ly2dy(SM_TWIP,ptb->docked_y);
      int junk_x=0;
      _map_xy(wid,0,junk_x,new_y1);
      new_y2=wid._ly2dy(SM_TWIP,ptb->docked_y+ptb->docked_height);
      _map_xy(wid,0,junk_x,new_y2);
      _mdi._bbdockPositionLR(area,arearect_y2,arearect_x1,
                             orig_area,orig_i,hasSizeBars,
                             new_i,new_twspace,new_twspace2,
                             new_x1,new_y1+adjust_docked_y,
                             new_x2,new_y2+adjust_docked_y,
                             ptb->docked_row,putInRowBreakAfter);
   }
   //_message_box('new_i='new_i' new_twspace='new_twspace' 2='new_twspace2);
   if( new_i < -1 ) {
      _message_box('toolbar internal error');
      return;
   }
   if( new_twspace2>=0 ) {
      gbbdockinfo[area][new_i].twspace=new_twspace2;
   }
   if( putInRowBreakAfter ) {
      //_message_box('PutInRowBreakAfter new_i='new_i' rowBreakBefore='rowBreakBefore);

      if( !hasSizeBars ) {
         if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
            new_twspace=ptb->docked_x;
         } else {
            new_twspace=ptb->docked_y;
         }
      }
   }
   // Existing container wid for the tabgroup of tool window being inserted
   int container = 0;
   if( ptb->tabgroup > 0 ) {
      int DOCKINGAREA_found, first_i, last_i;
      if( _bbdockFindTabGroup(ptb->tabgroup,DOCKINGAREA_found,first_i,last_i,area) &&
          DOCKINGAREA_found==area ) {

         container=_bbdockContainer(&gbbdockinfo[area][first_i]);
      }
   }
   docked_row=ptb->docked_row;
   gIgnoreInsertRestoreRow=true;
   wid=_mdi._bbdockInsert(area,new_i,
                          rowBreakBefore,
                          putInRowBreakAfter,
                          index,
                          ptb->tbflags,
                          new_twspace,
                          ptb->tabgroup,ptb->tabOrder);
   gIgnoreInsertRestoreRow=false;
   if( container>0 && _tbContainerFromWid(wid) == container ) {
       // We inserted into an already existing tabgroup, so do not
       // size it again!
       ptb->docked_width=container.p_width;
       ptb->docked_height=container.p_height;
   }
   _tbShowFinishUp(wid,hasSizeBars,ptb,area,docked_row,delayRefresh);
}

/**
 * @return If ptb==null, then the global setting is returned. If ptb!=null, and 
 * docking is allowed globally, the per-tool-window setting is returned. 
 */
boolean _tbIsDockingAllowed(_TOOLBAR* ptb=null)
{
   boolean dockingAllowed = false;
   if( 0!=(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_TOOLBAR_DOCKING) ) {
      // Docking allowed globally
      dockingAllowed=true;
      if( dockingAllowed && ptb ) {
         dockingAllowed= 0!=( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
      }
   }
   return dockingAllowed;
}

/**
 * Show tool window in last known docked or floating state.
 * 
 * @param FormName Name of tool window to show.
 * @param arg(2)   (optional). Pass non-zero if you ONLY want to restore
 *                 the form name passed in, and NOT the entire tabgroup
 *                 or dock channel group.
 */
_command void tbShow(_str FormName="") name_info(FORM_ARG',')
{
   boolean noRestoreGroup = ( arg(2)!="" && arg(2)!="0" );

   _tbNewVersion();
   _TOOLBAR *ptb = _tbFind(FormName);
   int index = find_index(FormName,oi2type(OI_FORM));
   if( !ptb || index==0 ) {
      _message_box(get_message(VSRC_FORM_NOT_FOUND,"",FormName));
      return;
   }
   //int wid = _find_formobj(FormName,"n");
   int wid = _tbIsVisible(FormName);
   //say('tbShow: FormName='FormName);
   //say('tbShow: ptb->restore_docked='ptb->restore_docked);
   //say('tbShow: ptb->docked_area='ptb->docked_area);
   if( !_tbIsDockingAllowed(ptb) ) {
      // Docking not allowed
      ptb->restore_docked=false;
   }
   if( wid!=0 || ptb->docked_area==0 || !ptb->restore_docked || ((ptb->tbflags & TBFLAG_SIZEBARS) == 0)) {
      // _tbIsVisible() returns 0 if the tool window is autohidden.
      // We want the wid regardless so we can know whether a window
      // was created or not.
      int old_wid = _tbGetWid(FormName);
      if( ptb->show_width!=0 ) {
         //say('case1 show 'ptb->show_x' 'ptb->show_y' 'ptb->show_width' 'ptb->show_height);
         wid = _tbShow(FormName,ptb->show_x,ptb->show_y,ptb->show_width,ptb->show_height);
      } else {
         //say('case2 show 'ptb->show_x' 'ptb->show_y' 'ptb->show_width' 'ptb->show_height);
         wid = _tbShow(FormName,0,0,0,0);
      }
      if( old_wid != wid ) {
         // New tool window shown, so inform it
         typeless state = _GetDialogInfoHt("tbState.":+FormName, _mdi);
         wid._tbRestoreState(state,true);
         if( state != null ) {
            _SetDialogInfoHt("tbState.":+FormName, null, _mdi);
         }
      }
      return;
   }

   // _tbIsVisible() returns 0 if the tool window is autohidden.
   // We want to know whether a window was already created or not.
   boolean alreadyCreated = ( _tbGetWid(FormName) > 0 );
   int tabgroup = ptb->tabgroup;
   if( tabgroup>0 && !noRestoreGroup ) {
      DockingArea area;
      int pic;
      _str caption;
      boolean active;
      if( 0==(def_toolbar_options & TBOPTION_NO_AUTOHIDE_TABGROUP) && dockchanFind(FormName,area,pic,caption,active) ) {
         // Restore group items in dock channel and activate the tool window
         _tbDockChanShowGroup(FormName);
      } else if( 0!=(def_toolbar_options & TBOPTION_CLOSE_TABGROUP) ) {
         // Restore the entire tabgroup and activate the tool window
         _tbShowTabGroup(tabgroup,FormName);
      } else {
         _tbShowDocked(FormName);
      }
   } else {
      _tbShowDocked(FormName);
   }
   if( !alreadyCreated ) {
      wid = _tbGetWid(FormName);
      typeless state = _GetDialogInfoHt("tbState.":+FormName, _mdi);
      wid._tbRestoreState(state,true);
      if( state != null ) {
         _SetDialogInfoHt("tbState.":+FormName, null, _mdi);
      }
   }

   // Update panel captions to reflect current focus
   _tbpanelUpdateAllPanels();
}

_command void tbSmartShow(_str FormName="") name_info(FORM_ARG',')
{
   DockingArea area;
   int pic;
   _str caption;
   boolean active;
   if( dockchanFind(FormName,area,pic,caption,active) ) {
      // true=give focus to tool window
      _tbAutoShow(FormName,area,true);
      dockchanSetActive(FormName);
   } else {
      tbShow(FormName);
   }
}

// show/hide floaters
void _tbVisible(boolean Show)
{
   int wid = _get_focus();
   int i;
   for (i = 0; i < def_toolbartab._length(); ++i) {
      int toolid = _tbIsVisible(def_toolbartab[i].FormName);
      if (!toolid) {
         continue;
      }

      if (_IsQToolbar(toolid)) {
         int isFloating = _QToolbarGetFloating(toolid);
         if (!isFloating) {
            continue;
         }
         
      } else if (toolid.p_DockingArea) {
         continue;
      } else if (_tbIsAutoShownWid(toolid)) {
         continue;
      }
      toolid.p_visible = Show;
   }
   if( wid!=0 ) {
      wid._set_focus();
   }
}

int _tbShow(_str FormName, int x, int y, int width, int height, boolean forceUndock=false)
{
   // _isloaded does not work for tool window attached to mdi side
   int wid = _find_formobj(FormName,'n');
   if( _tbIsAutoHiddenWid(wid) ) {
      // Destroy it first
      wid._tbSmartDeleteWindow();
      wid=0;
   }
   if( wid!=0 ) {
      DockingArea area, i;
      int tabgroup, tabOrder;
      if( forceUndock && _bbdockFindWid(wid,area,i,tabgroup,tabOrder) ) {
         // Changing behavior to close a docked tool window so that it
         // can be shown floating.
         _tbClose(wid);
      } else {
         return wid;
      }
   }

   // Remove from dock channel.
   // Need to do this for the case of tool window auto hidden and user
   // shows tool window (with context menu, tbShow, etc.).
   dockchanRemove(FormName);

   //_tbSetRefreshBy(VSTBREFRESHBY_USER);
   _TOOLBAR *ptb = _tbFind(FormName);
   int tbflags = TBFLAG_NEW_TOOLBAR;
   if( ptb ) {
      tbflags=ptb->tbflags;
   }

   if (0 == (tbflags & TBFLAG_SIZEBARS)) {
      wid = _tbLoadQToolbarName(FormName);
      return wid;
   }

   _str owner='';
   if( 0!=(tbflags & TBFLAG_ALWAYS_ON_TOP) ) {
      owner=" -mdi ";
   } else {
      owner=" -app ";
   }
   boolean isGrabbarSystem = (__UNIX__) ? true : false;
   if( isGrabbarSystem && 0!=(tbflags & TBFLAG_SIZEBARS) && 0==(tbflags & TBFLAG_NO_CAPTION) ) {

      // Show form inside a form with a grabbar on it.
      // We do this because the panel form can add a grabbar
      // if needed (e.g. UNIX where we have no control over
      // the title bar for drag-drop docking).
      int container_wid = 0;
      _str containerFormName = "_bbgrabbar_form";
      int container_index = find_index(containerFormName,oi2type(OI_FORM));
      if( container_index==0 ) {
         // Big problem
         _str msg = "Could not find form '"containerFormName"'";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 0;
      }
      container_wid=_mdi.show("-xy -hidden -new "owner:+containerFormName);
      if( container_wid<=0 ) {
         // Error
         return container_wid;
      }
      int index = find_index(FormName,oi2type(OI_FORM));
      wid=_tbLoadTemplate(tbflags,index,container_wid);
      if( wid<=0 ) {
         // Uh oh
         container_wid._delete_window();
      }

   } else {
      wid=_mdi.show("-xy -hidden "owner:+FormName);
   }
   if( wid<=0 ) {
      // Error
      return wid;
   }

   int container_wid=_tbContainerFromWid(wid);
   if( width>0 && height>0 ) {
      container_wid._move_window(x,y,width,height);
      // Make sure this form is visible on any monitor
      container_wid._CenterIfFormNotVisible();
   } else {
      int ww = _dx2lx(wid.p_xyscale_mode,wid.p_client_width);
      int hh = _dy2ly(wid.p_xyscale_mode,wid.p_client_height);
      container_wid._move_window(x,y,ww,hh);
   }
#if __UNIX__
   // Turn on grabbar on the toolbar without tab control
   if( 0!=(tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) ) {
      wid.p_ToolbarBorder=VSTBBORDER_GRABBARS;
   }
#endif
   wid.p_visible=true;
   // If tool window is inside a panel, then make that visible too
   if( container_wid!=wid ) {
      container_wid.p_visible=true;
      // Must call ON_RESIZE so form has a chance to resize its child form
      container_wid.call_event(1,container_wid,ON_RESIZE,'w');
   }
   return wid;
}

_TOOLBAR* _tbFind2(_str FormName, int& i)
{
   for( i=0;i<def_toolbartab._length();++i ) {
      if( FormName==def_toolbartab[i].FormName ) {
         return (&def_toolbartab[i]);
      }
   }
   return null;
}

_TOOLBAR* _tbFind(_str FormName)
{
   int i=0;
   return (_tbFind2(FormName,i));
}

_TOOLBAR* _tbFindCaption(_str name, int& index)
{
   int i;
   for( i=0;i<def_toolbartab._length();++i ) {
      index = find_index(def_toolbartab[i].FormName,oi2type(OI_FORM));
      if (index!=0 && strieq(index.p_caption,name) ) {
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
                boolean defaultVisible=false, DockingArea area=0,boolean doReplace=false)
{
   // already in list?
   _TOOLBAR* ptb = _tbFind(FormName);
   if( !doReplace && ptb ) {
      return;
   }
   // Does the form really exist?
   int index = find_index(FormName,oi2type(OI_FORM));
   if( index==0 ) {
      return;
   }

   // Create toolbar record
   _TOOLBAR tb;
   tb.FormName = FormName;
   tb.tbflags = tbFlags;
   tb.restore_docked = defaultVisible;
   tb.show_x=0;
   tb.show_y=0;
   tb.show_width=0;
   tb.show_height=0;
   tb.docked_area=area;
   tb.docked_row=0;
   tb.docked_x=0;
   tb.docked_y=0;
   tb.docked_width=0;
   tb.docked_height=0;
   tb.tabgroup=0;
   tb.tabOrder=0;
   tb.auto_width=0;
   tb.auto_height=0;

   // Already in list?
   if( ptb ) {
      // Replace item with new copy
      *ptb = tb;

   } else {
      // Append to list of toolbars
      def_toolbartab[def_toolbartab._length()]=tb;
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
}


//
// _toolbar_etab2
// Define lbutton_down and default on_resize event
//

defeventtab _toolbar_etab2;

static boolean _tb_ignore_on_got_focus2 = false;
static boolean _tbIgnoreOnGotFocus2(boolean onoff)
{
   boolean old_val = _tb_ignore_on_got_focus2;
   _tb_ignore_on_got_focus2=onoff;
   return old_val;
}

/**
 * Acts on the current tool window.
 */
static void _tbOnGotFocus2()
{
   if( _tb_ignore_on_got_focus2 ) {
      return;
   }
   static boolean in_on_got_focus2;

   if( in_on_got_focus2 ) {
      // Do not recurse!
      return;
   }
   in_on_got_focus2=true;
   _tbpanelUpdateAllPanels();
   in_on_got_focus2=false;
}

/**
 * If there is already an on_got_focus2() event for the form,
 * this event will NOT be called and will not update panels.
 * This is generally not an issue since tool windows do not
 * hook ON_GOT_FOCUS2, but it should be noted.
 */
void _toolbar_etab2.on_got_focus2()
{
   //say('_toolbar_etab2.ON_GOT_FOCUS2: in');
   _tbOnGotFocus2();
}

static boolean _tb_ignore_on_lost_focus2 = false;
static boolean _tbIgnoreOnLostFocus2(boolean onoff)
{
   boolean old_val = _tb_ignore_on_lost_focus2;
   _tb_ignore_on_lost_focus2=onoff;
   return old_val;
}

/**
 * Acts on the current tool window.
 */
static void _tbOnLostFocus2()
{
   //say('******************************************');
   //say('_tbOnLostFocus2: p_active_form.p_name='p_active_form.p_name);
   if( _tb_ignore_on_lost_focus2 ) {
      //say('_tbOnLostFocus2: IGNORING YOU!!!');
      return;
   }
   //say('_tbOnLostFocus2: NOT NOT NOT IGNORING YOU!!!');
   static boolean in_on_lost_focus2;

   if( in_on_lost_focus2 ) {
      // Do not recurse!
      return;
   }
   in_on_lost_focus2=true;
   if( _tbIsAutoShownWid(p_active_form) ) {
      // Delay auto hiding for ~2 seconds
      //say('_tbOnLostFocus2: maybe auto hide on form='p_active_form.p_name);
      _tbMaybeAutoHideDelayed(def_toolbar_autohide_delay':'p_active_form':'p_active_form.p_name);
   }
   _tbpanelUpdateAllPanels();
   // Update the current panel
   if( !tbIsWidDocked(p_active_form) ) {
      int focus_panel = _tbFindParentPanel(p_active_form);
      if( focus_panel>0 ) {
         // Probably an auto shown window
         focus_panel._tbpanelUpdate(-1);
      }
   }
   in_on_lost_focus2=false;
}

/**
 * If there is already an on_lost_focus2() event for the form,
 * this event will NOT be called and will not update panels.
 * This is generally not an issue since tool windows do not
 * hook ON_LOST_FOCUS2, but it should be noted.
 */
void _toolbar_etab2.on_lost_focus2()
{
   //say('_toolbar_etab2.ON_LOST_FOCUS2: in');
   _tbOnLostFocus2();
}

boolean _maybe_do_dialog_hotkey(_str event) {

   if (p_DockingArea!=0 || !_default_option(VSOPTION_MAC_USE_COMMAND_KEY_FOR_DIALOG_HOT_KEYS)) {
      return false;
   }
   int index=event2index(event);
   if ((index & VSEVFLAG_ALL_SHIFT_FLAGS)!=VSEVFLAG_COMMAND) {
      return false;
   }
   int chIndex=index&~VSEVFLAG_ALL_SHIFT_FLAGS;
   if (chIndex>=_asc('A') && chIndex<=_asc('Z')) {
      _dmDoDialogHotkey();
       return true;
   }
   return false;
}

void _smart_toolbar_hotkey()
{
   _str key=last_event();
   if (key :== F7) {
      _retrieve_next_form('-',1); return;
   } else if (key :== F8) {
      _retrieve_next_form('',1); return;
   } else if (key :== F1) {
      // pass through to default eventtabs
      int active_form_wid = p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      active_form_wid.p_eventtab = 0;
      call_key(key);
      active_form_wid.p_eventtab = old_eventtab;
      return;
   }

   if(p_object!=OI_EDITOR && _maybe_do_dialog_hotkey(last_event())) {
      return;
   }

   if( p_object==OI_EDITOR ) {
      // Key that was actually pressed
      int kt_index = last_index('','k');
      // Check if the window event table does not have a binding for this key
      if( p_eventtab==0 || 0==eventtab_index(p_eventtab,p_eventtab,event2index(key)) ) {
         int command_index = eventtab_index(_default_keys,p_mode_eventtab,event2index(key));
         _str arg2;
         parse name_info(command_index) with ',' arg2 ',' ;
         if( arg2=="" ) {
            arg2=0;
         }
         boolean iscommand = 0!=( name_type(command_index) & COMMAND_TYPE );
         if( iscommand && ( 0==((int)arg2&VSARG2_EDITORCTL) ||   // not allowed in editor control
                            // Or command requires MDI window
                            ( ((int)arg2&VSARG2_REQUIRES_MDI) &&
                              0==(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_WINDOW)
                            )
                          ) ) {

            if( p_DockingArea!=0 ) {
               p_window_id=_mdi.p_child;
               call_key(last_event());
            } else {
               if(_maybe_do_dialog_hotkey(last_event())) {
                  return;
               }
            }
            return;
         }
      }
      int command_index = eventtab_index(_default_keys,p_mode_eventtab,event2index(key));
      if(!command_index && _maybe_do_dialog_hotkey(last_event())) {
         return;
      }
      int active_form_wid = p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      int old_eventtab2 = active_form_wid.p_eventtab2;
      active_form_wid.p_eventtab=0;
      active_form_wid.p_eventtab2=0;
      call_key(key);
      if( _iswindow_valid(active_form_wid) ) {
         active_form_wid.p_eventtab=old_eventtab;
         active_form_wid.p_eventtab2=old_eventtab2;
      }
      return;

   } else if( p_object==OI_TEXT_BOX || p_object==OI_COMBO_BOX ) {
      // Key that was actually pressed
      int kt_index = last_index('','k');
      int command_index = eventtab_index(_default_keys,_default_keys,event2index(key));
      _str arg2;
      parse name_info(command_index) with ',' arg2 ',' ;
      if( arg2=="" ) {
         arg2=0;
      }
      boolean iscommand = 0!=( name_type(command_index) & COMMAND_TYPE );
      boolean iscombo_key = ( key:==F4 && p_object==OI_COMBO_BOX );

      if( !iscombo_key &&  iscommand &&
          0==((int)arg2 & VSARG2_TEXT_BOX)   // not allowed in text box
        ) {

         if( p_DockingArea!=0 ) {
            p_window_id=_mdi.p_child;
            call_key(last_event());
         }
         return;
      }
      int active_form_wid = p_active_form;
      int old_eventtab = active_form_wid.p_eventtab;
      int old_eventtab2 = active_form_wid.p_eventtab2; // avoid infinite recursion with eventtab2
      active_form_wid.p_eventtab=0;
      active_form_wid.p_eventtab2=0;
      if( p_object==OI_COMBO_BOX && !iscombo_key ) {
         call_event(p_window_id,key);
      } else {
         call_key(key);
      }
      active_form_wid.p_eventtab=old_eventtab;
      active_form_wid.p_eventtab2=old_eventtab2;
      return;
   }
   if( p_DockingArea!=0 ) {
      p_window_id=_mdi.p_child;
      call_key(last_event());
   }
}

//void _toolbar_etab2.'C-A'-'C-Z',F2-F4,f6-F12,C_F12,'c-a-a'-'c-a-z','a-0'-'a-9'()
//void _toolbar_etab2.'C-A'-'C-Z',F2-F12,C_F12,A_F1-A_F12,'c-a-a'-'c-a-z','c-s-a'-'c-s-z','a-0'-'a-9'()
void _toolbar_etab2.'C-A'-'C-Z', F1-F12,C_F12,A_F1-A_F12,S_F1-S_F12,'c-0'-'c-9','c-s-0'-'c-s-9','c-a-0'-'c-a-9','a-0'-'a-9','M-A'-'M-Z','M-0'-'M-9','S-M-A'-'S-M-Z','S-M-0'-'S-M-9'()
{
   _smart_toolbar_hotkey();
}

// Events added by user request
void _toolbar_etab2.'A-,'()
{
   _smart_toolbar_hotkey();
}

// Events added by user request
void _toolbar_etab2.'M-,'()
{
   _smart_toolbar_hotkey();
}

void _toolbar_etab2.F1()
{
   _dmhelp();
}

void _toolbar_etab2.'C-W',A_LEFT,A_RIGHT,A_UP()
{
   if( !_no_child_windows() ) {
      p_window_id=_mdi.p_child;
      _set_focus();
   }
}

void _tbDismiss(int active_form, boolean force = false)
{
   boolean wasDocked=tbIsWidDocked(active_form) || _tbIsAutoShownWid(active_form);
   if( _tbIsAutoShownWid(active_form) ) {
      _tbAutoHide(active_form);
   } else if( _tbIsVisible(active_form.p_name) && !tbIsWidDocked(active_form) ) {
      // Floating tool window
      _TOOLBAR* ptb = _tbFind(active_form.p_name);
      if(force ||  ptb && (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
         // Dismiss like a dialog
         tbClose(active_form);
      }
   }
   // Fall through default behavior
   if( !_no_child_windows() ) {
      p_window_id=_mdi.p_child;
      _set_focus();
   } else if( wasDocked ) {
      _cmdline._set_focus();
   }
}

void _toolbar_etab2.ESC()
{
   //say('_toolbar_etab2.ESC: in');
   _tbDismiss(p_active_form);
}

/**
 * Handles moving between tabs in a tabgroup (if we are in a tabgroup).
 */
void _toolbar_etab2.'c-tab','s-c-tab'()
{
   int wid = _tbTabGroupWidFromWid(p_active_form);
   if( wid>0 && wid.p_object==OI_SSTAB ) {
      wid.call_event(defeventtab _tabgroup_etab,last_event(),'e');
   } else {
      // Allow tool windows with non-tabgroup tab controls to get the event
      call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
   }
}

void _toolbar_etab2.on_create()
{
   _tbSetToolbarEnable(p_window_id);
   int child = p_child;
   if( child!=0 ) {

      int first_child;
      for( first_child=child;; ) {

         if( child.p_object==OI_IMAGE ) {

            if( child.p_caption!="" ) {

               if( child.p_style!=PSPIC_FLAT_BUTTON ) {
                  child.p_style=PSPIC_FLAT_BUTTON;
               }

            } else if( child.p_picture!=0 ) {

               boolean pb=file_eq(substr(name_name(child.p_picture),1,2),"pb");
               if( !pb && (child.p_style==PSPIC_AUTO_BUTTON || child.p_style==PSPIC_BUTTON) ) {
                  child.p_style=PSPIC_FLAT_BUTTON;

               } else if( pb && child.p_style==PSPIC_FLAT_BUTTON ) {
                  child.p_style=PSPIC_BUTTON;
               }
            }
         }
         child=child.p_next;
         if( child==first_child ) {
            break;
         }
      }
   }
}

/**
 * ON_CLOSE only gets called when the user hits the 'X'. There
 * are specific checks in the code to prevent calling this event
 * otherwise.
 */
void _toolbar_etab2.on_close()
{
   //say('_toolbar_etab2.on_close: in');
   typeless state = null;
   p_active_form._tbSaveState(state,true);
   if( state != null ) {
      _SetDialogInfoHt("tbState.":+p_active_form.p_name, state, _mdi);
   }
   int child_wid=0;
   if (!_no_child_windows()) {
      child_wid=_mdi.p_child;
   }
   p_active_form._delete_window();
   if (child_wid) {
      child_wid._set_focus();
   }
}

void _toolbar_etab2.on_destroy()
{
   _TOOLBAR *ptb = _tbFind(p_name);
   if( ptb ) {

      // Get the container wid for this tool window so that we can
      // save dimensions of the container instead of the embedded
      // tool window.
      int container_wid = _tbContainerFromWid(p_window_id);

      if( _tbIsAutoWid(p_active_form) ) {
         // We do not save state for auto shown windows, except for the
         // auto show width, height.
         int autopane_wid = _tbAutoPaneFromWid(container_wid);
         if( autopane_wid>0 ) {

            DockingArea area = autopane_wid._autopaneGetArea();
            switch( area ) {
            case DOCKINGAREA_LEFT:
            case DOCKINGAREA_RIGHT:
               // Only save the width
               ptb->auto_width=container_wid.p_width;
               break;
            case DOCKINGAREA_TOP:
            case DOCKINGAREA_BOTTOM:
               // Only save the height
               ptb->auto_height=container_wid.p_height;
               break;
            }
         }

      } else if( p_DockingArea==0 ) {
         // Tool window is not docked
         ptb->restore_docked=false;
         ptb->show_x=container_wid.p_x;
         ptb->show_y=container_wid.p_y;
         ptb->show_width=container_wid.p_width;
         ptb->show_height=container_wid.p_height;

      } else {
         ptb->restore_docked=true;
         DockingArea area, sidei;
         int tabgroup, tabOrder;
         _mdi._bbdockFindWid(p_window_id,area,sidei,tabgroup,tabOrder);
         ptb->docked_area=p_DockingArea;
         area=p_DockingArea;
         int count = _bbdockPaletteLength(area);
         int row = 1;
         int i;
         for( i=0;i<count;++i ) {
            int wid = gbbdockinfo[area][i].wid;
            if( p_window_id==wid ) {
               break;
            }
            //say('_toolbar_etab2.on_destroy: wid='wid'  row='row);
            if( wid==BBDOCKINFO_ROWBREAK ) {
               ++row;
            }
         }
         if( i>=count ) {
            // Odd case: we never found this docked tool window in the global
            // list of tool windows. Guarantee that it does not get docked
            // next time.
            ptb->docked_area=0;
         }
         ptb->docked_row=_bbdockQRestoreRow(area,sidei);
         ptb->docked_x=container_wid.p_x;
         ptb->docked_y=container_wid.p_y;
         ptb->docked_width=container_wid.p_width;
         ptb->docked_height=container_wid.p_height;

         ptb->tabgroup=tabgroup;
         ptb->tabOrder=tabOrder;
      }
      //say('show 'ptb->show_x' 'ptb->show_y' 'ptb->show_width' 'ptb->show_height);
   }
   if( p_DockingArea!=0 ) {
      return;
   }
   int list = _find_object("_toolbars_prop_form.list1",'n');
   if( list!=0 ) {
      list.call_event(CHANGE_SELECTED,1,list,ON_CHANGE,"");
   }
}

void _toolbar_etab2.on_load()
{
   p_old_width=0;
   p_old_height=0;
   call_event(p_window_id,ON_RESIZE);
   _TOOLBAR *ptb = _tbFind(p_name);

   onCreateDone(1);
   if( ptb && 0==(ptb->tbflags & TBFLAG_SIZEBARS) ) {
      // Button bar
      _tbResizeButtonBar(p_DockingArea);
   }

   int list = _find_object("_toolbars_prop_form.list1",'n');
   if( list!=0 ) {
      list.call_event(CHANGE_SELECTED,list,ON_CHANGE, "");
   }
}

void _toolbar_etab2.on_resize()
{
   // If on_load not processed
   if( !onCreateDone() || p_DockingArea!=0 || p_object!=OI_FORM ) {
      return;
   }
   if( p_width==p_old_width && p_height==p_old_height ) {
      return;
   }
   p_old_width=p_width;
   p_old_height=p_height;
   _TOOLBAR *ptb = _tbFind(p_name);
   if( ptb && 0!=(ptb->tbflags & TBFLAG_SIZEBARS) ) {
      // Sizeable
      return;
   }
   p_active_form._tbResizeButtonBar(p_DockingArea);
   p_old_width=p_width;
   p_old_height=p_height;
}

void _toolbar_etab2."c-s- "()
{
   int container = _tbContainerFromWid(p_active_form);
   if( _bbgrabbarIsGrabbarForm(container) ) {
      // Ctrl+Shift+Space will edit the form contained in a grabbar form,
      // but leave the empty grabbar form hanging around. _bbgrabbar_form
      // knows what to do, so pass the event on to it.
      container.call_event(container,name2event('C-S- '),'w');
   } else {
      // Not in a grabbar case, but we still need to call automatical inheritance.
      // Otherwise, we would never be able to edit a tool window.
      call_event(defeventtab _ainh_dlg_manager,name2event('C-S- '),'e');
   }
}

static int gDragMousePointerTab[/*0..4*/] = {

   MP_LEFTARROW,
   MP_LEFTARROW_DROP_LEFT,
   MP_LEFTARROW_DROP_TOP,
   MP_LEFTARROW_DROP_RIGHT,
   MP_LEFTARROW_DROP_BOTTOM,
};

void _WinRectInit(WINRECT& r)
{
   r.wid= -1;
   r.x1=r.y1=r.x2=r.y2=0;
}

void _WinRectSet(WINRECT& r, int wid, int toWid=0, int scale_mode=SM_PIXEL)
{
   _WinRectInit(r);
   if( wid>=0 ) {
      r.wid=wid;
      int width, height;
      int x1, y1, x2, y2;
      wid._get_window(x1,y1,width,height);
      _lxy2dxy(wid.p_xyscale_mode,x1,y1);
      _lxy2dxy(wid.p_xyscale_mode,width,height);
      x2=x1+width;
      y2=y1+height;
      _map_xy(wid.p_xyparent,toWid,x1,y1,scale_mode);
      _map_xy(wid.p_xyparent,toWid,x2,y2,scale_mode);
      r.x1=x1;
      r.y1=y1;
      r.x2=x2;
      r.y2=y2;
   }
}

void _WinRectSetSubRect(WINRECT& r, int wid, int x1, int y1, int x2, int y2)
{
   r.wid=wid;
   r.x1=x1;
   r.y1=y1;
   r.x2=x2;
   r.y2=y2;
}

boolean _WinRectPointInside(WINRECT r, int wid, int x, int y)
{
   if( wid!=r.wid ) {
      return false;
   }
   return ( x>=r.x1 && x<r.x2 && y>=r.y1 && y<r.y2 );
}

void _WinRectDebug(WINRECT r)
{
   say('=======================================================');
   _str wid_name = "";
   int wid_object = 0;
   if( r.wid>0 ) {
      wid_name=r.wid.p_name;
      wid_object=r.wid.p_object;
   }
   say('r.wid='r.wid' ('wid_name'), p_object='wid_object);
   say('r.x1='r.x1);
   say('r.y1='r.y1);
   say('r.x2='r.x2);
   say('r.y2='r.y2);
   say('=======================================================');
}


void _toolbar_etab2."c-lbutton_down"()
{
   call_event(0,p_window_id,LBUTTON_DOWN,"");
}

static int dockPaletteWidth(DockingArea area)
{
   int x, y, width, height;
   _mdi._GetDockPaletteGeometry(area,x,y,width,height);
   return width;
}
static int dockPaletteHeight(DockingArea area)
{
   int x, y, width, height;
   _mdi._GetDockPaletteGeometry(area,x,y,width,height);
   return height;
}

/**
 * Get area rectangle windows for all sides and store in output array. Geometry
 * returned is relative to the desktop and in SM_PIXEL scale mode. If a side does
 * not exist (i.e. there are no docked tool windows), then the geometry is still
 * calculated.
 * 
 * @param arearect (output). Array of RECT that stores wid and geometry of
 *                   a side. Sides are DOCKINGAREA_LEFT, DOCKINGAREA_TOP, DOCKINGAREA_RIGHT, DOCKINGAREA_BOTTOM.
 */
static void _bbGetSides(WINRECT (&arearect)[])
{
   int mdiclient_x, mdiclient_y, mdiclient_width, mdiclient_height;
   _mdi._MDIClientGetWindow(mdiclient_x,mdiclient_y,mdiclient_width,mdiclient_height);

   int wid = 0;
   int x, y, width, height;
   int unused = 0;

   int i, n=_bbdockPaletteLastIndex();
   for( i=DOCKINGAREA_FIRST; i <= n; ++i ) {
      arearect[i].wid = wid = _mdi._bbdockPaletteGet(i);
      if( wid ) {
         _mdi._GetDockPaletteGeometry(i,x,y,width,height);
         _map_xy(_mdi,0,x,y,SM_PIXEL);
         arearect[i].x1 = x;
         arearect[i].y1 = y;
         arearect[i].x2 = arearect[i].x1 + width;
         arearect[i].y2 = arearect[i].y1 + height;
      } else {
         switch( i ) {
         case DOCKINGAREA_TOP:
            x = 0;
            y = _mdi.p_y;
            // Note that _mdi.p_y is already in desktop coordinates
            _map_xy(_mdi,0,x,unused,SM_PIXEL);
            width = _mdi.p_width;
            height = _mdi._top_height();
            break;
         case DOCKINGAREA_BOTTOM:
            x = mdiclient_x;
            y = mdiclient_y + mdiclient_height;
            _map_xy(_mdi,0,x,y,SM_PIXEL);
            width = _mdi.p_width - dockPaletteWidth(DOCKINGAREA_LEFT);
            height = (_mdi.p_y + _mdi.p_height) - y;
            break;
         case DOCKINGAREA_LEFT:
            x = 0;
            y = mdiclient_y;
            _map_xy(_mdi,0,x,y,SM_PIXEL);
            width = _mdi._left_width();
            height = mdiclient_height + dockPaletteHeight(DOCKINGAREA_BOTTOM);
            break;
         case DOCKINGAREA_RIGHT:
            x = mdiclient_x + mdiclient_width;
            y = mdiclient_y;
            _map_xy(_mdi,0,x,y,SM_PIXEL);
            width = _mdi._left_width();
            height = mdiclient_height;
            break;
         }
         if( width < 0 ) {
            width = 0;
         }
         if( height < 0 ) {
            height = 0;
         }
         arearect[i].x1 = x;
         arearect[i].y1 = y;
         arearect[i].x2 = arearect[i].x1 + width;
         arearect[i].y2 = arearect[i].y1 + height;
      }
   }
}

/**
 * Operates on the active window.
 * <p>
 * Get info about the active tool window. Works for docked and floating tool
 * windows. Used by _toolbar_etab2 event table for purposes of
 * docking/undocking tool windows.
 * 
 * @param area       (output). Docked side. 0 if not docked, otherwise one of
 *                     DOCKINGAREA_* constants.
 * @param i            (output). Docked order index into gbbdockinfo[][] array
 *                     for a docked side. 0 if tool window is not docked.
 * @param tbflags      (output). Flags for currently showing tool window. See
 *                     TBFLAG_* constants.
 * @param hasEntireRow (output). true when docked tool window takes up the
 *                     entire row of a side.
 * @param tabgroup     (output). Unique tabgroup identifier that this
 *                     tool window is tab-linked into. 0 if no tabgroup.
 * @param tabOrder     (output). Tab order in a tabgroup that this
 *                     tool window is displayed.
 * 
 * @return true if active window is a tool window.
 */
boolean _tbGetActiveInfo(int& area, int& i, int& tbflags, boolean& hasEntireRow,
                         int& tabgroup, int& tabOrder)
{
   area=p_DockingArea;
   i = 0;
   tbflags=TBFLAG_NEW_TOOLBAR;
   hasEntireRow=false;
   tabgroup=0;
   tabOrder=0;
   if( area==0 ) {

      hasEntireRow=false;
      _TOOLBAR* ptb =_tbFind(p_name);
      if( !ptb ) {
         // Not a floating tool window
         return false;
      }
      tbflags=ptb->tbflags;

   } else {
      if( !_bbdockFindWid(p_window_id,area,i,tabgroup,tabOrder) ) {
         // Not a docked tool window
         return false;
      }
      tbflags=gbbdockinfo[area][i].tbflags;
      hasEntireRow = ( (i==0 || gbbdockinfo[area][i-1].wid==BBDOCKINFO_ROWBREAK) &&
                       (i+1)<_bbdockPaletteLength(area) &&
                       gbbdockinfo[area][i+1].wid==BBDOCKINFO_ROWBREAK );
   }
   return true;
}

/**
 * Operates on the active window.
 * <p>
 * Create drag-drop rectangles that will be drawn on screen to give user a
 * preview of where a tool window will be docked/undocked.
 * 
 * @param area The area (DOCKINGAREA_*) we are dragging from.
 * @param hasSizeBars True if the tool window we are dragging is sizeable.
 * @param ddrect (output). Array of drag-drop rectangles where 
 *               each array index corresponds to a docking area
 *               (see DOCKINGAREA_* constants) of the MDI frame
 *               or a free floating tool palette.
 * @param padX   (output). The amount of x-padding decoration around the tool
 *               window we are dragging. Only applies to floating tool windows
 *               on UNIX. 0 otherwise. This amount is included in the width of
 *               of each drag-drop rectangle.
 * @param padY   (output). The amount of y-padding decoration around the tool
 *               window we are dragging. Only applies to floating tool windows
 *               on UNIX. 0 otherwise. This amount is included in the height of
 *               of each drag-drop rectangle.
 */
static void _bbCreateDragDropRects(DockingArea area, boolean hasSizeBars,
                                   DDRECT (&ddrect)[], int& padX, int& padY)
{
   ddrect._makeempty();
   padX = 0;
   padY = 0;
   int width = 0;
   int height = 0;

   int frameWidth = hasSizeBars ? GetSystemMetrics(VSM_CXFRAME) : GetSystemMetrics(VSM_CXDLGFRAME);
   int frameHeight = hasSizeBars ? GetSystemMetrics(VSM_CYFRAME) : GetSystemMetrics(VSM_CYDLGFRAME);
   int captionHeight = GetSystemMetrics(VSM_CYSMCAPTION);
   if( area == 0 ) {

      _get_window(auto x,auto y,width,height,'O');
      ddrect[0].width = width + padX;
      ddrect[0].height = height + padY;

      // Reused current width when docking on top and on bottom
      ddrect[DOCKINGAREA_TOP].width = ddrect[DOCKINGAREA_BOTTOM].width = p_client_width;

      // Reused current height when docking on left and on right
      ddrect[DOCKINGAREA_LEFT].height = ddrect[DOCKINGAREA_RIGHT].height = p_client_height;

      ddrect[DOCKINGAREA_LEFT].width = ddrect[DOCKINGAREA_RIGHT].width = TBDEFAULT_DOCK_WIDTH;
      ddrect[DOCKINGAREA_TOP].height = ddrect[DOCKINGAREA_BOTTOM].height = TBDEFAULT_DOCK_HEIGHT;

   } else if( area == DOCKINGAREA_TOP || area == DOCKINGAREA_BOTTOM ) {

      ddrect[0].width = TBDEFAULT_UNDOCK_WIDTH + 2*frameWidth;
      ddrect[0].height = TBDEFAULT_UNDOCK_HEIGHT + captionHeight + 2*frameHeight;
      //message("_toolbar_etab2.lbutton_down: ddrect[0].height="ddrect[0].height);
      // Reused width and height opposite side
      ddrect[DOCKINGAREA_TOP].width = ddrect[DOCKINGAREA_BOTTOM].width = TBDEFAULT_DOCK_WIDTH;

      // Reused current height when docking on left and on right
      ddrect[DOCKINGAREA_TOP].height = ddrect[DOCKINGAREA_BOTTOM].height = p_client_height;

      ddrect[DOCKINGAREA_LEFT].width = ddrect[DOCKINGAREA_RIGHT].width = TBDEFAULT_DOCK_WIDTH;
      ddrect[DOCKINGAREA_LEFT].height = ddrect[DOCKINGAREA_RIGHT].height = TBDEFAULT_DOCK_HEIGHT;

   } else {

      // area==DOCKINGAREA_LEFT || area==DOCKINGAREA_RIGHT
      ddrect[0].width = TBDEFAULT_UNDOCK_WIDTH + 2*frameWidth;
      ddrect[0].height = TBDEFAULT_UNDOCK_HEIGHT + captionHeight + 2*frameHeight;
      // Reused width and height opposite side
      ddrect[DOCKINGAREA_LEFT].width = ddrect[DOCKINGAREA_RIGHT].width = p_client_width;

      // Reused current height when docking on left and on right
      ddrect[DOCKINGAREA_LEFT].height = ddrect[DOCKINGAREA_RIGHT].height = TBDEFAULT_DOCK_HEIGHT;

      ddrect[DOCKINGAREA_TOP].width = ddrect[DOCKINGAREA_BOTTOM].width = TBDEFAULT_DOCK_WIDTH;
      ddrect[DOCKINGAREA_TOP].height = ddrect[DOCKINGAREA_BOTTOM].height = TBDEFAULT_DOCK_HEIGHT;

   }
}

/**
 * Initialize a DockOperation object.
 * 
 * @param dop (output). DockOperation structure.
 * @param tbwid Window id of the tool window we are docking. 0 specifies
 *              the active window (p_active_form).
 */
void _dockOpInit(DockOperation& dop, int tbwid=0)
{
   // Insure sanity in the current toolbar list before we begin
   _tbNewVersion();

   // Rectangles for all sides. If the side is not present,
   // then a side is still computed.
   // Geometry is relative to desktop, in pixels.
   _bbGetSides(dop.dockPaletteRect);

   // Active tool window
   if( tbwid==0 ) {
      tbwid=p_active_form;
   }
   dop.tbwid=tbwid;

   // Is the mouse captured?
   dop.mouCaptured=false;

   // Gather starting info about tool window that was clicked on
   dop.orig_area=0;
   dop.orig_i=0;
   dop.orig_tbflags=0;
   dop.orig_hasEntireRow=false;
   dop.tbwid._tbGetActiveInfo(dop.orig_area, dop.orig_i, dop.orig_tbflags, dop.orig_hasEntireRow,
                              dop.orig_tabgroup, dop.orig_tabOrder);
   dop.orig_hasSizeBars=( (dop.orig_tbflags&TBFLAG_SIZEBARS)!=0 );
   dop.orig_tabLinked=( _tbTabGroupWidFromWid(dop.tbwid)!=0 );

   // Allow docking?
   dop.allowDocking= ( _tbIsDockingAllowed() && 0!=(dop.orig_tbflags&TBFLAG_ALLOW_DOCKING) );
   // The TBFLAG_NO_VERT_DOCKING and TBFLAG_NO_HORZ_DOCKING don't work yet.  It
   // caused a Slick-C stack error when redocking the breakpoint toolbar from the left side to
   // the right side.
   dop.allowVertDocking=true; //dop.AllowDocking && !(dop.orig_tbflags & TBFLAG_NO_VERT_DOCKING);
   dop.allowHorzDocking=true; //dop.AllowDocking && !(dop.orig_tbflags & TBFLAG_NO_HORZ_DOCKING);

   // Create drag-drop rectangles used to preview where active tool window will dock/undock
   int container_wid = _tbContainerFromWid(dop.tbwid);
   container_wid._bbCreateDragDropRects(dop.orig_area, dop.orig_hasSizeBars,
                                        dop.ddrect, dop.padX, dop.padY);

   // Mouse-click coordinates relative to tool window in pixels.
   // Used to determine desktop-relative edges of tool window.
   // These coordinates are set during drag-drop mode (e.g. in _dockOpDragDropMode).
   dop.mx=dop.my=0;

   // Desktop-relative coordinates of current drag-drop rectangle for
   // tool window (in pixels). These coordinates are set during drag-drop
   // mode (e.g. in _dockOpDragDropMode).
   dop.x1=dop.y1=dop.x2=dop.y2=0;
   // Is the tool window currently tab-linkable?
   dop.tabLinkable=false;

   // Resulting top-left coordinate of a drag-drop operation (floating tool window case)
   dop.dst_x = 0;
   dop.dst_y = 0;
   // Resulting size of a drag-drop operation (floating tool window case)
   dop.dst_width = 0;
   dop.dst_height = 0;
   // Resulting docked side, index, and rowbreak and spacing info of a drag-drop
   // operation (docked tool window case).
   // -1 indicates that a drag-drop operation has not taken place yet.
   dop.newarea= -1;
   dop.new_i=0;
   dop.rowBreakAfter=false;
   dop.rowBreakBefore=false;
   dop.new_twspace=0;
   dop.new_twspace2=0;
   dop.new_tabgroup=0;;
   dop.new_tabOrder= -1;

   // true=Do not change mouse pointer to indicate docking until the mouse has moved
   // the minimum amount.
   dop.checkMinDragMousePointer=false;

   // The last event that caused us to exit drag-drop mode (e.g. ESC, LBUTTON_UP, etc.)
   dop.lastEvent="";
}

/**
 * Find the area that the mouse is currently docking to. This 
 * would be the destination area if the user were doing a 
 * drag-drop operation with a tool window. 
 * 
 * @param dop       DockOperation object representing current 
 *                  dock operation.
 * @param x         Mouse x coordinate relative to desktop in pixels.
 * @param y         Mouse y coordinate relative to desktop in pixels.
 * @param startArea (optional). We move around the areas in 
 *                  order when determining if the mouse
 *                  coordinates are contained in a side. By
 *                  default we start on the first side
 *                  (DOCKINGAREA_FIRST), but you can override
 *                  this by setting this argument. See
 *                  DOCKINGAREA_* constants.
 * 
 * @return Destination area in the range 
 * DOCKINGAREA_FIRST.._bbdockPaletteLastIndex(). 0 is returned
 * if not floating. 
 */
static int _dockOpMouSide(DockOperation& dop, int x, int y, DockingArea startArea=DOCKINGAREA_FIRST)
{
   int newarea = 0;

   // Check if the mouse is touching one of the sides
   int i;
   for( i=DOCKINGAREA_FIRST;i<=_bbdockPaletteLastIndex();++i ) {
      if( x>=dop.dockPaletteRect[i].x1 && x<dop.dockPaletteRect[i].x2 &&
          y>=dop.dockPaletteRect[i].y1 && y<dop.dockPaletteRect[i].y2 ) {

         newarea=i;
         break;
      }
   }
   int diff = 0;
   if( newarea==0 ) {
      int width, height;
      width=dop.x2-dop.x1;
      height=dop.y2-dop.y1;
      // Check if current and new rectangles touches side
      if( startArea<DOCKINGAREA_FIRST || startArea>_bbdockPaletteLastIndex() ) {
         startArea=DOCKINGAREA_FIRST;
      }
      i=startArea;
      for( ;; ) {
         if( i==DOCKINGAREA_TOP || i==DOCKINGAREA_BOTTOM ) {
            int new_y1 = y-dop.my;
            int new_y2 = new_y1+height;
            if( (x>=dop.dockPaletteRect[i].x1 && x<dop.dockPaletteRect[i].x2) &&
                new_y1<dop.dockPaletteRect[i].y2 && new_y2>dop.dockPaletteRect[i].y1 ) {

               newarea=i;
               height = dop.ddrect[newarea].height;
               if( y < dop.dockPaletteRect[newarea].y1 ) {
                  diff=dop.dockPaletteRect[newarea].y1-y;
                  if( diff>height ) {
                     newarea=0;
                  }

               } else if( y>=dop.dockPaletteRect[newarea].y2 ) {
                  diff=y-dop.dockPaletteRect[newarea].y2+1;
                  if (diff>=height) {
                     newarea=0;
                  }
               }
               if( newarea!=0 ) {
                  break;
               }
            }
         } else {
            int new_x1 = x-dop.mx;
            int new_x2 = new_x1+width;
            if( (y>=dop.dockPaletteRect[i].y1 && y<dop.dockPaletteRect[i].y2) &&
                new_x1<dop.dockPaletteRect[i].x2 && new_x2>dop.dockPaletteRect[i].x1 ) {

               newarea=i;
               width = dop.ddrect[newarea].width;
               if( x<dop.dockPaletteRect[newarea].x1 ) {
                  diff=dop.dockPaletteRect[newarea].x1-x;
                  if( diff>width ) {
                     newarea=0;
                  }

               } else if( x>=dop.dockPaletteRect[newarea].x2 ) {
                  diff=x-dop.dockPaletteRect[newarea].x2+1;
                  if( diff>=width ) {
                     newarea=0;
                  }
               }
               if( newarea!=0 ) {
                  break;
               }
            }
         }
         ++i;
         if( i>_bbdockPaletteLastIndex() ) {
            i=DOCKINGAREA_FIRST;
         }
         if( i==startArea ) {
            break;
         }
      }
   }

   return newarea;
}

/**
 * Determine if the mouse (x,y) coordinates are inside the tab-link region of
 * a tool window (i.e. the caption or the tab row of the SSTab 
 * control) in an area. 
 * 
 * @param dop        DockOperation object representing current 
 *                   docking operation.
 * @param area       The area we are checking. See DOCKINGAREA_*
 *                   constants.
 * @param tablink_i  (output). Index at which to insert 
 *                   tab-linked tool window.
 * 
 * @return true if mouse is inside tab-link region, tablink_i is set to
 * gbbdockinfo[][] insertion index.
 */
static boolean _dockOpTabLinkable(DockOperation& dop, DockingArea area, int& tablink_i)
{
   if( 0!=(dop.orig_tbflags & (TBFLAG_NO_TABLINK|TBFLAG_NO_CAPTION)) ) {
      // Tab-link not allowed on the tool window we are docking
      return false;
   }
   if( !dop.orig_hasSizeBars) {
      // Tool window we are docking is not sizeable, so
      // we certainly do not want to put it into a sizeable
      // tabgroup.
      return false;
   }
   if( isNoTabLinkToolbar(dop.tbwid.p_name) ) {
      return false;
   }

   // Save the tool window that was originally clicked and perform
   // all drag-drop operations relative to the desktop.
   //int selected_wid = dop.tbwid;
   int selected_wid = _tbContainerFromWid(dop.tbwid);
   int orig_wid = p_window_id;

   // Original mouse-click coordinates relative to desktop
   int orig_mx = _desktop.mou_last_x();
   int orig_my = _desktop.mou_last_y();

#define insidePanel(x, y) _WinRectPointInside(panelRect,panelRect.wid,x,y)
#define insideCaption(x, y) _WinRectPointInside(captionRect,captionRect.wid,x,y)
#define insideTabRow(x, y) _WinRectPointInside(tabrowRect,tabrowRect.wid,x,y)

   WINRECT panelRect;
   WINRECT captionRect;
   WINRECT tabrowRect;
   _WinRectInit(panelRect);
   _WinRectInit(captionRect);
   _WinRectInit(tabrowRect);

   // First determine if we are within a tab-linkable panel
   int lastPanelWid = 0;
   int i;
   for( i=0; i<_bbdockPaletteLength(area); ++i ) {

      int wid = gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         continue;
      }
      int tbflags = gbbdockinfo[area][i].tbflags;
      if( 0==(tbflags & TBFLAG_SIZEBARS) ) {
         // This tool window is not sizeable
         continue;
      }
      if( 0!=(tbflags & TBFLAG_NO_TABLINK) ) {
         // Tab-linking into this tool window not allowed.
         // Note:
         // This could be 1 tool window of a tabgroup. We assume
         // that if this 1 tool window is not tab-link'able, then
         // none of the other tool windows are.
         continue;
      }
      if( isNoTabLinkToolbar(wid.p_name) ) {
         continue;
      }
      int panelWid = _tbContainerFromWid(wid);
      if( !_tbpanelIsPanel(panelWid) ) {
         continue;
      }
      if( panelWid==selected_wid ) {
         // We are in the same panel that we started in
         continue;
      }
      if( panelWid==lastPanelWid ) {
         // This happens with tab-linked tool windows that are
         // part of the same panel. We have already checked this
         // panel, so skip it.
         continue;
      }
      lastPanelWid=panelWid;
      // Get dimensions of panel
      _WinRectSet(panelRect,panelWid);
      //_WinRectDrawRect(panelRect,_rgb(255,0,0),'N');
      //_WinRectDebug(panelRect);
      if( insidePanel(orig_mx,orig_my) ) {

         // Get dimensions of caption bar
         int captionWid = panelWid._find_control("ctl_caption");
         if( captionWid>0 ) {
            _WinRectSet(captionRect,captionWid);
         }
         if( insideCaption(orig_mx,orig_my) ) {
            // We are already inside the caption bar, so no
            // point in checking the tab row.
            break;
         }
         int tabWid = panelWid._tbpanelFindChild();
         if( tabWid>0 && tabWid.p_object==OI_SSTAB ) {
            // We have a tabgroup

            if( tabWid.p_child==0 ) {
               // No tab containers
               continue;
            }
            // The height of the tab row is the difference
            // between the height of the SSTab control and
            // its child container.
            _WinRectSet(tabrowRect,tabWid.p_child);
            int x1 = tabrowRect.x1;
            int y1 = tabrowRect.y2;
            int x2 = tabrowRect.x2;
            int rowHeight = tabWid.p_height - tabWid.p_child.p_height;
            rowHeight=_ly2dy(tabWid.p_xyscale_mode,rowHeight);
            int y2 = y1+rowHeight;
            _WinRectSetSubRect(tabrowRect,tabWid,x1,y1,x2,y2);
            //_WinRectDrawRect(tabrowRect,_rgb(0,255,0),'N');
         }
         if( insideTabRow(orig_mx,orig_my) ) {
            // We are inside the tab row
            break;
         }
      }
   }

   p_window_id=orig_wid;

   if( i >= _bbdockPaletteLength(area) ) {
      // Never found a panel to tab-link into
      return false;
   }

   // We have a winner!
   tablink_i=i;
   return true;
}

struct SSTABINFO {

   // SSTab control geometry
   int width, height;

   // Geometry of tab row (i.e. not the container area)
   // for the tallest tab in the row.
   int tabRowW, tabRowH;

   // Geometry of container area (i.e. not the tab row)
   // for the shortest container in the row.
   int containerW, containerH;

   // Geometry of tab part of active tab (i.e. p_ActiveTab)
   int activeTabW, activeTabH;

   // Geometry of container part of active tab (i.e. p_ActiveTab)
   int activeContainerW, activeContainerH;
};

/**
 * Operates on active window which must be SSTab control.
 * <p>
 * Gather information into SSTABINFO structure. All geometry is
 * in parent scale mode.
 *
 * @param ssti (output). SSTABINFO struct.
 */
static void sstGetInfo(SSTABINFO& ssti)
{
   // Init
   ssti.width = 0;
   ssti.height = 0;
   //
   ssti.tabRowW = 0;
   ssti.tabRowH = 0;
   //
   ssti.containerW = 0;
   ssti.containerH = 0;
   //
   ssti.activeTabW = 0;
   ssti.activeTabH = 0;
   //
   ssti.activeContainerW = 0;
   ssti.activeContainerH = 0;

   ssti.width = p_width;
   ssti.height = p_height;

   // These never change
   ssti.containerW = ssti.width;

   // Height of tallest tab (and therefore the height of the tab row)
   int tallest = 0;
   int shortest = MAXINT;
   int widest = 0;
   int thinnest = MAXINT;
   SSTABCONTAINERINFO info;
   int i, n=p_NofTabs;
   for( i=0; i < n; ++i ) {
      _getTabInfo(i,info);
      _dxy2lxy(p_xyscale_mode,info.tx,info.ty);
      _dxy2lxy(p_xyscale_mode,info.bx,info.by);
      int tabH = info.by - info.ty;
      if( tabH > tallest ) {
         tallest = tabH;
         ssti.containerH = ssti.height - tabH;
         ssti.tabRowH = tabH;
      }
      if( tabH < shortest ) {
         shortest = tabH;
      }
      int tabW = info.bx - info.tx;
      if( tabW > widest ) {
         widest = tabW;
      }
      if( tabW < thinnest ) {
         thinnest = tabW;
      }
      ssti.tabRowW += tabW;
      if( i == p_ActiveTab ) {
         ssti.activeTabW = tabW;
         ssti.activeTabH = tabH;
         ssti.activeContainerW = ssti.width;
         ssti.activeContainerH = ssti.height - ssti.activeTabH;
      }
   }
}

static void _bbdockDrawTabRectangle(sc.controls.RubberBand& rubberBand, DockingArea area, int i)
{
   // Geometry of tab part of tab rectangle
   int tx_offset = 0;
   int tw = 0;
   int th = 0;
   // Gap of about 5 pixels on either side of tab
   int tx_gap = 5 * _twips_per_pixel_x();

   int relativeToWid = _bbdockContainer(&gbbdockinfo[area][i]);
   int tabgroup = _bbdockTabGroup(area,i,false);
   if( tabgroup > 0 ) {
      int tabgroupWid = _bbdockTabGroupWid(&gbbdockinfo[area][i]);
      if( tabgroupWid > 0 && tabgroupWid.p_object == OI_SSTAB ) {
         relativeToWid = tabgroupWid;
         // Find the last tab in the row and draw tab rectangle
         // past it.
         SSTABINFO ssti;
         tabgroupWid.sstGetInfo(ssti);
         tx_offset = ssti.tabRowW + tx_gap;
         tw = ssti.activeTabW - tx_gap;
         // Make sure the the tab will fit in the remaining space
         // of the tab row.
         //say('_bbdockDrawTabRectangle: relativeToWid.p_x='relativeToWid.p_x);
         //say('_bbdockDrawTabRectangle: tx_offset='tx_offset'  tw='tw'  tx_offset+tw='(tx_offset+tw));
         //say('_bbdockDrawTabRectangle: ssti.x='ssti.x'  ssti.width='ssti.width'  ssti.width+ssti.width='(ssti.x+ssti.width));
         th = ssti.activeTabH;
      }
   }
   if( tx_offset == 0 ) {
      // Just a panel so use default
      tx_offset = 300;
   }
   // Enforce a minimum width, height
   if( tw == 0 ) {
      // Just a panel, so use default
      tw = 600;
   } else if( tw < 100 ) {
      // The user needs to see _something_
      tw = 100;
   }
   if( (tx_offset+tw) > relativeToWid.p_width ) {
      tx_offset = relativeToWid.p_width - tw;
      if( tw > tx_gap ) {
         tw -= tx_gap;
      }
   }
   if( th < 300 ) {
      // Just a panel, so use default
      th = 300;
   }

   //
   // Calculate rectangles to draw
   //

   int cx = relativeToWid.p_x;
   int cy = relativeToWid.p_y;
   int cw = relativeToWid.p_width;
   int ch = relativeToWid.p_height;

   int xyparent = relativeToWid.p_xyparent;
   int xyscale_mode = relativeToWid.p_xyscale_mode;

   // Need pixels for the desktop
   _lxy2dxy(xyscale_mode,cx,cy);
   _lxy2dxy(xyscale_mode,cw,ch);
   //_lxy2dxy(xyscale_mode,tx,ty);
   _lxy2dxy(xyscale_mode,tw,th);
   tx_offset = _lx2dx(xyscale_mode,tx_offset);

   // Map to origin to desktop coordinates
   _map_xy(xyparent,0,cx,cy,SM_PIXEL);
   //_map_xy(xyparent,0,tx,ty,SM_PIXEL);

   // Put it all together into a tab-shape
   int org_x, org_y, org_w, org_h;
   rubberBand.getWindow(org_x,org_y,org_w,org_h);
   // 2/20/2012 - rb
   // Qt 4.7.4, Mac, QTBUG-4028 workaround.
   // Cannot be lazy and continually set the mask since bug on Mac
   // requires temporarily setting window invisible to get mask set
   // correctly. For that reason we make sure we only set it once, 
   // otherwise you get a flickery rubber-band window.
   if( cx != org_x || cy != org_y || cw != org_w || ch != org_h ) {

      sc.util.Point pts[];
      pts[pts._length()] = sc.util.Point.create(0,0);
      pts[pts._length()] = sc.util.Point.create(0,ch-th);
      pts[pts._length()] = sc.util.Point.create(tx_offset,ch-th);
      pts[pts._length()] = sc.util.Point.create(tx_offset,ch);
      pts[pts._length()] = sc.util.Point.create(tx_offset+tw,ch);
      pts[pts._length()] = sc.util.Point.create(tx_offset+tw,ch-th);
      pts[pts._length()] = sc.util.Point.create(cw,ch-th);
      pts[pts._length()] = sc.util.Point.create(cw,0);

      //rubberBand.clearMask();
      rubberBand.setMaskFromPolygon(pts);
#if __MACOSX__ /* QTBUG-4028 */
      rubberBand.setVisible(false);
#endif

      rubberBand.setWindow(cx,cy,cw,ch);

#if __MACOSX__ /* QTBUG-4028 */
      rubberBand.setVisible(true);
#endif

   }
}

void _dockOpDragDropMode(DockOperation& dop)
{
   // Save the tool window that was originally clicked and perform
   // all drag-drop operations relative to the desktop.
   //int selected_wid = dop.tbwid;
   int selected_wid = _tbContainerFromWid(dop.tbwid);

   // Original mouse-click coordinates relative to desktop.
   // Used to check if we have moved the minimum amount.
   int orig_mx = _desktop.mou_last_x();
   int orig_my = _desktop.mou_last_y();

   // Original mouse-click coordinates relative to tool window in pixels.
   // Used to determine desktop-relative edges of tool window.
   dop.mx = selected_wid.mou_last_x()+_lx2dx(selected_wid.p_xyscale_mode,selected_wid._left_width());
   dop.my = selected_wid.mou_last_y()+_ly2dy(selected_wid.p_xyscale_mode,selected_wid._top_height());

   // Drag-drop rectangle settings
   boolean PutInrowBreakAfter=false;
   boolean AllowDocking=false;
   boolean tabLinkable=false;
   

   int old_mou_mode = mou_mode(-1);
   mou_mode(1);
   boolean mouWasCaptured=dop.mouCaptured;
   if( !mouWasCaptured ) {
      selected_wid.mou_capture(true);
      dop.mouCaptured=true;
   }

   _KillToolButtonTimer();
   int newarea = dop.orig_area;
   int new_i = 0;
   boolean rowBreakAfter, rowBreakBefore;
   int new_twspace, new_twspace2;

   se.util.MousePointerGuard mousePointerSentry(selected_wid.p_mouse_pointer,selected_wid);

   int mp = gDragMousePointerTab[newarea];
   if( !dop.checkMinDragMousePointer ) {
      mou_set_pointer(mp);
      selected_wid.p_mouse_pointer=mp;
   }

   boolean done = false;

   // Original top-left coordinates of window frame
   int orig_x, orig_y;
   // Original client area size (does NOT include frame/titlebar decorations)
   int orig_width, orig_height;
   selected_wid._get_window(orig_x,orig_y,orig_width,orig_height);
   _lxy2dxy(selected_wid.p_xyscale_mode,orig_x,orig_y);
   _lxy2dxy(selected_wid.p_xyscale_mode,orig_width,orig_height);
   // Relative to desktop
   _map_xy(selected_wid.p_xyparent,0,orig_x,orig_y,SM_PIXEL);

   // Coordinates used to draw moving rectangles.
   // dop.x1,y1,x2,y2 are the current drag-drop rectangle that is drawn.
   // new_x1,y1,x2,y2 is a candidate drag-drop rectangle that the current
   // drag-drop rectangle will become.
   int new_x1, new_y1, new_x2, new_y2;
   // Are we currently tab-linkable?
   boolean new_tabLinkable = false;
   dop.x1 = orig_x;
   dop.y1 = orig_y;
   dop.x2 = dop.x1 + dop.ddrect[dop.orig_area].width;
   dop.y2 = dop.y1 + dop.ddrect[dop.orig_area].height;
   dop.tabLinkable=false;
   //int orig_x1, orig_y1, orig_x2, orig_y2;
   //orig_x1=x1;orig_y1=y1;orig_x2=x2;orig_y2=y2;

   // Drag-drop rectangle size
   int width = dop.ddrect[dop.orig_area].width;
   int height = dop.ddrect[dop.orig_area].height;

   _str event = MOUSE_MOVE;

   //boolean CheckMinDrag = (dop.orig_area!=0);
   boolean checkMinDrag = true;

   sc.controls.RubberBand rubberBand;
   rubberBand.setWindow(dop.x1,dop.y1,width,height);

   OUTER_LOOP:
   for (;;) {

      switch( event ) {

      case MOUSE_MOVE:
         int prev_area;
         int prev_i;
         prev_area=newarea;
         prev_i=new_i;
         newarea=0;
         // Remember coordinates are relative to the desktop and in pixels
         int x = _desktop.mou_last_x();
         int y = _desktop.mou_last_y();
         if( checkMinDrag ) {
            if( abs(orig_mx-x)>CXDRAG_MIN ) {
               checkMinDrag=false;
            }
            if( abs(orig_my-y)>CYDRAG_MIN ) {
               checkMinDrag=false;
            }
         }
         if( checkMinDrag ) {
            // We have not moved enough, so bail
            break;
         }
         if( !rubberBand.isVisible() ) {
            rubberBand.setVisible(true);
         }
         if( dop.allowDocking ) {

            // Find the side that the mouse is currently docking to
            newarea=_dockOpMouSide(dop,x,y,prev_area);

            new_tabLinkable=false;

            //say("newarea="newarea);
            if( newarea!=0 ) {
               rowBreakBefore=false;
               rowBreakAfter=false;
               new_twspace=0;
               new_twspace2= -1;
               new_i= -2;  // Nothing to do

               // Determine how this tool window will be inserted

               new_tabLinkable=_dockOpTabLinkable(dop,newarea,new_i);
               if( new_tabLinkable ) {
                  int panelWid = _bbdockContainer(&gbbdockinfo[newarea][new_i]);
                  WINRECT panelRect;
                  _WinRectSet(panelRect,panelWid);
                  new_x1=panelRect.x1;
                  new_y1=panelRect.y1;
                  new_x2=panelRect.x2;
                  new_y2=panelRect.y2;

               } else if( dop.allowHorzDocking && (newarea==DOCKINGAREA_TOP || newarea==DOCKINGAREA_BOTTOM) ) {

                  // Make sure mouse pointer is inside new rectangle

                  // Height of destination-area
                  height = dop.ddrect[newarea].height;
                  // y      : Desktop-relative last-mouse-y
                  // dop.my : Tool-window-relative original-mouse-y (tool window y-coord where
                  //          we originally clicked)
                  // new_y1 : Desktop-relative top edge of drag-drop rectangle
                  new_y1=y-dop.my;

                  if( dop.my>=height ) {
                     dop.my=height-1;
                     new_y1=y-dop.my;
                  }

                  if( new_y1+height<=dop.dockPaletteRect[newarea].y1 ) {
                     new_y1=dop.dockPaletteRect[newarea].y1-height+1;
                     dop.my=y-new_y1;
                  } else if( new_y1>=dop.dockPaletteRect[newarea].y2 ) {
                     new_y1=dop.dockPaletteRect[newarea].y2-1;
                     dop.my=y-new_y1;
                  }

                  // new_y2 : Desktop-relative bottom edge of drag-drop rectangle
                  new_y2=new_y1+height;
                  boolean NewRow;
                  NewRow=false;
                  if( _mdi._bbdockPaletteGet(newarea) ) {
                     // Determine whether this will create a new row
                     // New row means less than 1/2 of drag-drop rect inside
                     // AND entire side NOT inside drag-drop rect.
                     int ty1;
                     ty1=new_y1;
                     if( ty1<dop.dockPaletteRect[newarea].y1 ) {
                        ty1=dop.dockPaletteRect[newarea].y1;
                     }
                     int ty2;
                     ty2=new_y2;
                     if( ty2>dop.dockPaletteRect[newarea].y2 ) {
                        ty2=dop.dockPaletteRect[newarea].y2;
                     }

                     // IF
                     // Less than half of the drag-drop rectangle is inside
                     // area window,
                     // AND
                     // Part of the drag-drop window lies inside the area
                     // window,
                     // THEN
                     // Create a new row.
                     if( (ty2-ty1) < ((new_y2-new_y1) intdiv 2) &&
                         (ty1>dop.dockPaletteRect[newarea].y1 || ty2<dop.dockPaletteRect[newarea].y2) ) {
                        NewRow=true;
                     }
                     //NewRow2 = !(
                     //           (ty2-ty1) >= ((new_y2-new_y1) intdiv 2) ||
                     //           (ty1<=dop.arearect[newarea].y1 && ty2>=dop.arearect[newarea].y2)
                     //          );

                  } else {
                     // There are no docked tool windows on this side yet,
                     // so create first (new) row.
                     NewRow=true;
                  }
                  if( !NewRow || !dop.orig_hasSizeBars ) {
                     // Drag-drop rectangle is somewhere inside an existing row
                     // OR
                     // this is a button bar.
                     // Width will set to fit inside the existing row.
                     width = dop.ddrect[newarea].width;
                     if( dop.mx>=width ) {
                        dop.mx=width-1;
                     }
                     new_x1=x-dop.mx;
                     new_x2=new_x1+width;

                  } else {
                     // New row, so the width will take the entire side
                     new_x1=dop.dockPaletteRect[newarea].x1;
                     new_x2=dop.dockPaletteRect[newarea].x2;
                  }
                  if( NewRow ) {

                     int DOCKINGAREA_mid_y = (dop.dockPaletteRect[newarea].y1+dop.dockPaletteRect[newarea].y2)/2;
                     int new_mid_y = (new_y1+new_y2)/2;
                     if( new_mid_y < DOCKINGAREA_mid_y ) {
                        // User drag-dropped closer to the area edge, so insert new row
                        // on the area edge. Insert a rowbreak after this new row in
                        // order to push all other rows aside.
                        new_i=0;
                        rowBreakAfter=true;

                     } else {
                        // User drag-dropped closer to the last row on this area, so
                        // insert new row after all other rows. Insert a row break before
                        // this new row to separate it from previous rows.
                        new_i=-1;
                        rowBreakBefore=true;
                     }

                  } else {
                     _mdi._bbdockPositionTB(newarea,
                                            dop.dockPaletteRect[newarea].x2,dop.dockPaletteRect[newarea].y1,
                                            dop.orig_area,dop.orig_i,dop.orig_hasSizeBars,
                                            new_i,new_twspace,new_twspace2,
                                            new_x1,new_y1,new_x2,new_y2,0,PutInrowBreakAfter);

                     if( dop.orig_hasSizeBars && dop.orig_area==newarea &&
                         (new_i-1)==dop.orig_i && dop.orig_hasEntireRow ) {

                        new_x1=dop.dockPaletteRect[newarea].x1;
                        new_x2=dop.dockPaletteRect[newarea].x2;

                     } else if( dop.orig_hasSizeBars && dop.orig_area==newarea && !dop.orig_tabLinked &&
                                _bbdockRowStart(newarea,new_i)==_bbdockRowStart(newarea,dop.orig_i) ) {

                        width=_lx2dx(SM_TWIP,selected_wid.p_width);
                        if( dop.mx>=width ) {
                           dop.mx=width-1;
                        }
                        new_x1=x-dop.mx;
                        new_x2=new_x1+width;
                     }
                  }

               } else if( dop.allowVertDocking && (newarea==DOCKINGAREA_LEFT || newarea==DOCKINGAREA_RIGHT) ) {

                  // Make sure mouse pointer is inside new rectangle

                  // Width of destination-area
                  width = dop.ddrect[newarea].width;
                  // x      : Desktop-relative last-mouse-x
                  // dop.mx : Tool-window-relative original-mouse-x (tool window x-coord where
                  //          we originally clicked)
                  // new_x1 : Desktop-relative left edge of drag-drop rectangle
                  new_x1=x-dop.mx;

                  if( dop.mx>=width ) {
                     dop.mx=width-1;
                     new_x1=x-dop.mx;
                  }

                  if( (new_x1+width) <= dop.dockPaletteRect[newarea].x1 ) {
                     new_x1=dop.dockPaletteRect[newarea].x1-width+1;
                     dop.mx=x-new_x1;
                  } else if( new_x1 >= dop.dockPaletteRect[newarea].x2 ) {
                     new_x1=dop.dockPaletteRect[newarea].x2-1;
                     dop.mx=x-new_x1;
                  }

                  // new_x2 : Desktop-relative right edge of drag-drop rectangle
                  new_x2=new_x1+width;
                  boolean NewRow;
                  NewRow=false;
                  if( _mdi._bbdockPaletteGet(newarea) ) {
                     // Determine whether this will create a new row
                     // New row means less than 1/2 of drag-drop rect inside
                     // AND entire side NOT inside drag-drop rect.
                     int tx1;
                     tx1=new_x1;
                     if( tx1<dop.dockPaletteRect[newarea].x1 ) {
                        tx1=dop.dockPaletteRect[newarea].x1;
                     }
                     int tx2;
                     tx2=new_x2;
                     if( tx2>dop.dockPaletteRect[newarea].x2 ) {
                        tx2=dop.dockPaletteRect[newarea].x2;
                     }

                     // IF
                     // Less than half of the drag-drop rectangle is inside
                     // area window,
                     // AND
                     // Part of the drag-drop window lies inside the area
                     // window,
                     // THEN
                     // Create a new row.
                     if( (tx2-tx1) < ((new_x2-new_x1) intdiv 2) &&
                         (tx1>dop.dockPaletteRect[newarea].x1 || tx2<dop.dockPaletteRect[newarea].x2) ) {
                        NewRow=true;
                     }
                     //NewRow2 = !(
                     //           (tx2-tx1) >= ((new_x2-new_x1) intdiv 2) ||
                     //           (tx1<=dop.arearect[newarea].x1 && tx2>=dop.arearect[newarea].x2)
                     //          );
                     //say('_toolbar_etab2.lbutton_down: NewRow='NewRow'  NewRow2='NewRow2);
                     //if( NewRow!=NewRow2 ) {
                     //   _beep(2000,100);
                     //}

                  } else {
                     // There are no docked tool windows on this side yet,
                     // so create first (new) row.
                     NewRow=true;
                  }
                  if( !NewRow || !dop.orig_hasSizeBars ) {
                     // Drag-drop rectangle is somewhere inside an existing row
                     // OR
                     // this is a button bar.
                     // Height will set to fit inside the existing row.
                     height = dop.ddrect[newarea].height;
                     if( dop.my>=height ) {
                        dop.my=height-1;
                     }
                     new_y1=y-dop.my;
                     new_y2=new_y1+height;

                  } else {
                     // New row, so the height will take the entire side
                     new_y1=dop.dockPaletteRect[newarea].y1;
                     new_y2=dop.dockPaletteRect[newarea].y2;
                  }
                  if( NewRow ) {

                     int DOCKINGAREA_mid_x = (dop.dockPaletteRect[newarea].x1+dop.dockPaletteRect[newarea].x2)/2;
                     int new_mid_x = (new_x1+new_x2)/2;
                     if( new_mid_x < DOCKINGAREA_mid_x ){
                        // User drag-dropped closer to the area edge, so insert new row
                        // on the area edge. Insert a rowbreak after this new row in
                        // order to push all other rows aside.
                        new_i=0;rowBreakAfter=true;

                     } else {
                        // User drag-dropped closer to the last row on this area, so
                        // insert new row after all other rows. Insert a row break before
                        // this new row to separate it from previous rows.
                        new_i=-1;rowBreakBefore=true;
                     }

                  } else {
                     _mdi._bbdockPositionLR(newarea,
                                            dop.dockPaletteRect[newarea].y2,dop.dockPaletteRect[newarea].x1,
                                            dop.orig_area,dop.orig_i,dop.orig_hasSizeBars,
                                            new_i,new_twspace,new_twspace2,
                                            new_x1,new_y1,new_x2,new_y2,0,PutInrowBreakAfter);

                     if( dop.orig_hasSizeBars && dop.orig_area==newarea &&
                         (new_i-1)==dop.orig_i && dop.orig_hasEntireRow ) {

                        new_y1=dop.dockPaletteRect[newarea].y1;
                        new_y2=dop.dockPaletteRect[newarea].y2;

                     } else if( dop.orig_hasSizeBars && dop.orig_area==newarea && !dop.orig_tabLinked &&
                                _bbdockRowStart(newarea,new_i)==_bbdockRowStart(newarea,dop.orig_i) ) {

                        height=_ly2dy(SM_TWIP,selected_wid.p_height);
                        if( dop.my>=height ) {
                           dop.my=height-1;
                        }
                        new_y1=y-dop.my;
                        new_y2=new_y1+height;
                     }
                  }

               } else {
                  // Make sure mouse pointer is inside new rectangle.
                  new_y1=y-dop.my;
                  new_y2=new_y1+height;
                  new_x1=x-dop.mx;
                  new_x2=new_x1+width;

                  if( !dop.orig_hasSizeBars ) {
                     new_x1=x-dop.mx;
                     new_x2=new_x1+width;
                     new_y1=y-dop.my;
                     new_y2=new_y1+height;
                  }
                  if( dop.allowVertDocking ) {
                     _mdi._bbdockPositionTB(newarea,
                                            dop.dockPaletteRect[newarea].x2,dop.dockPaletteRect[newarea].y1,
                                            dop.orig_area,dop.orig_i,dop.orig_hasSizeBars,
                                            new_i,new_twspace,new_twspace2,
                                            new_x1,new_y1,new_x2,new_y2,0,PutInrowBreakAfter);

                  } else {
                     _mdi._bbdockPositionLR(newarea,
                                            dop.dockPaletteRect[newarea].y2,dop.dockPaletteRect[newarea].x1,
                                            dop.orig_area,dop.orig_i,dop.orig_hasSizeBars,
                                            new_i,new_twspace,new_twspace2,
                                            new_x1,new_y1,new_x2,new_y2,0,PutInrowBreakAfter);
                  }
               }
            }
         }
         if( newarea==0 ) {
            width = dop.ddrect[newarea].width;
            height = dop.ddrect[newarea].height;
            if( dop.mx>width ) {
               dop.mx=width-1;
            }
            if( dop.my>height ) {
               dop.my=height-1;
            }
            new_x1=x-dop.mx;
            new_y1=y-dop.my;
            new_x2=new_x1+width;
            new_y2=new_y1+height;
            //new_x2=new_x1+width+leftWidth*2;new_y2=new_y1+height+topHeight+leftWidth;
            if( prev_area!=0 ) {
               // Make sure we do not intersect with side we just moved out of
               if( y<dop.dockPaletteRect[prev_area].y1 ) {
                  if( new_y2>dop.dockPaletteRect[prev_area].y1 ) {
                     new_y2=dop.dockPaletteRect[prev_area].y1;
                     new_y1=new_y2-height;
                     dop.my=y-new_y1;
                  }
               }
               if( y>=dop.dockPaletteRect[prev_area].y2 ) {
                  if( new_y1<dop.dockPaletteRect[prev_area].y2 ) {
                     new_y1=dop.dockPaletteRect[prev_area].y2;
                     new_y2=new_y1+height;
                     dop.my=y-new_y1;
                  }
               }
            }
         }
         if( newarea!=prev_area ) {
            mp=gDragMousePointerTab[newarea];
            mou_set_pointer(mp);
            selected_wid.p_mouse_pointer=mp;
         }
         //say("newarea="newarea);

         dop.x1=new_x1;dop.y1=new_y1;dop.x2=new_x2;dop.y2=new_y2;
         dop.tabLinkable=new_tabLinkable;
         if( dop.tabLinkable ) {
            _bbdockDrawTabRectangle(rubberBand,newarea,new_i);
         } else {
            int w = dop.x2 - dop.x1;
            int h = dop.y2 - dop.y1;
            // Must clear the mask in case the last drag-drop
            // rectangle was for tabgroup.
            rubberBand.clearMask();
            rubberBand.setWindow(dop.x1,dop.y1,w,h);
            #if 0 /* debug */
            sc.util.Point pts[];
            pts[pts._length()] = sc.util.Point.create(0,   0);
            pts[pts._length()] = sc.util.Point.create(w-1, 0);
            pts[pts._length()] = sc.util.Point.create(w-1, h-1);
            pts[pts._length()] = sc.util.Point.create(0,   h-1);

            pts[pts._length()] = sc.util.Point.create(0,   2*h/3);
            pts[pts._length()] = sc.util.Point.create(w/3, 2*h/3);
            pts[pts._length()] = sc.util.Point.create(w/3, h/3);
            pts[pts._length()] = sc.util.Point.create(0,   h/3);
            //say(nls('_dockOpDragDropMode : 0 : (%s,%s)',pts[0].x(),pts[0].y()));
            //say(nls('_dockOpDragDropMode : 0 : (%s,%s)',pts[1].x(),pts[1].y()));
            rubberBand.setVisible(false);
            rubberBand.setMaskFromPolygon(pts);
            rubberBand.setWindow(dop.x1,dop.y1,w,h);
            rubberBand.setVisible(true);
            #endif
         }
         break;

      case ON_KEYSTATECHANGE:
         if( !_tbIsDockingAllowed() ) {
            dop.allowDocking=false;
            continue;
         } else {
            if (_IsKeyDown(CTRL)) {
               dop.allowDocking=false;
               event=MOUSE_MOVE;
               continue;
            } else {
               dop.allowDocking = ( (dop.orig_tbflags&TBFLAG_ALLOW_DOCKING)!=0 );
               event=MOUSE_MOVE;
               continue;
            }
         }

      case LBUTTON_UP:
      case ESC:
         dop.lastEvent=event;
         done=true;
      }

      if( done ) {
         break;
      }

      tabLinkable = false;
      event = selected_wid.get_event();
   }
   mou_mode(old_mou_mode);
   if( !mouWasCaptured ) {
      // We captured the mouse (i.e. it was not already captured),
      // so release it.
      selected_wid.mou_release();
      dop.mouCaptured=false;
   }
   if( checkMinDrag ) {
      event=ESC;
   }

   p_window_id=selected_wid;

   if( event != ESC ) {
      // All good, so set up dop structure to signify a successful drag-drop operation
      //say(nls('_bbDipDragDropMode: done-(%s,%s)-(%s,%s)',dop.x1,dop.y1,dop.x2,dop.y2));
      //say(nls('_bbDipDragDropMode: done-(%s,%s)-(%s,%s)',dop.x1,dop.y1,dop.x2-dop.x1,dop.y2-dop.y1));
      dop.newarea=newarea;
      dop.dst_x = dop.x1;
      dop.dst_y = dop.y1;
      if( dop.newarea == 0 ) {
         // Floating keeps original size
         dop.dst_width = orig_width;
         dop.dst_height = orig_height;
      } else {
         // Docked
         dop.dst_width = dop.x2 - dop.x1;
         dop.dst_height = dop.y2 - dop.y1;
      }
      dop.new_i=new_i;
      dop.new_twspace=new_twspace;
      dop.new_twspace2=new_twspace2;
      dop.rowBreakBefore=rowBreakBefore;
      dop.rowBreakAfter=rowBreakAfter;
      dop.tabLinkable=new_tabLinkable;
      if( dop.tabLinkable ) {
         int tabgroup = _bbdockTabGroup(dop.newarea,dop.new_i);
         if( tabgroup<=0 ) {
            // No tabgroup here yet, so make one
            tabgroup=_bbdockQMaxTabGroup()+1;
            gbbdockinfo[dop.newarea][dop.new_i].tabgroup=tabgroup;
            gbbdockinfo[dop.newarea][dop.new_i].tabOrder=0;
         }
         dop.new_tabgroup=tabgroup;
         dop.new_tabOrder= -1;
      } else {
         if( 0 == (dop.orig_tbflags & (TBFLAG_NO_TABLINK|TBFLAG_NO_CAPTION)) &&
             dop.orig_hasSizeBars &&
             !isNoTabLinkToolbar(dop.tbwid.p_name) ) {

            // Not docking into an existing tabgroup, so create a new tabgroup
            dop.new_tabgroup=_bbdockQMaxTabGroup()+1;
            dop.new_tabOrder= -1;
         }
      }
   }
}

void _dockOpDropExecute(DockOperation& dop)
{
   if( dop.newarea<0 ) {
      // This only happens when:
      // 1. a drag-drop operation was cancelled (user hit ESC), or
      // 2. a drag-drop operation has not taken place yet.
      return;
   }

   int selected_wid = _tbContainerFromWid(dop.tbwid);

   DockingArea area = 0;
   int i = 0;
   int tabgroup = 0;
   int tabOrder = 0;
   int x,y,width,height;

   _str formName = dop.tbwid.p_name;
   if( dop.newarea==0 ) {
      _dxy2lxy(selected_wid.p_xyscale_mode,dop.dst_x,dop.dst_y);
      _dxy2lxy(selected_wid.p_xyscale_mode,dop.dst_width,dop.dst_height);
      if( dop.orig_area ) {
         typeless state = null;
         dop.tbwid._tbSaveState(state,false);
         _mdi._bbdockRespaceAndRemove(dop.orig_area,dop.orig_i,true);
         _mdi._bbdockMaybeRemoveButtonBar(dop.orig_area,true);
         _mdi._bbdockRefresh(dop.orig_area);
         int new_tbwid = _tbShow(formName,dop.dst_x,dop.dst_y,dop.dst_width,dop.dst_height);
         // Crash hard and fast if new_tbwid == 0
         new_tbwid._tbRestoreState(state,false);

      } else {
         selected_wid._move_window(dop.dst_x,dop.dst_y,
                                   dop.dst_width-_dx2lx(SM_TWIP,dop.padX),
                                   dop.dst_height-_dy2ly(SM_TWIP,dop.padY));
      }

   } else {

      // Docking to a side

      typeless state = null;
      dop.tbwid._tbSaveState(state,false);

      // If the tool window was originally docked on a different side
      if( dop.orig_area!=0 ) {

         // IF we are docking this toolbar in the same place
         if( dop.orig_area==dop.newarea && (dop.orig_i+1)==dop.new_i &&
             !dop.rowBreakBefore && !dop.rowBreakAfter &&
             (dop.orig_i==0 || gbbdockinfo[dop.orig_area][dop.orig_i-1].wid==BBDOCKINFO_ROWBREAK) &&
             ((dop.orig_i+1)==gbbdockinfo[dop.orig_area]._length() ||
              gbbdockinfo[dop.orig_area][dop.orig_i+1].wid==BBDOCKINFO_ROWBREAK) ) {

            dop.rowBreakAfter=true;
         }
         _mdi._bbdockRespaceAndRemove(dop.orig_area,dop.orig_i,true);
         if( dop.orig_area!=dop.newarea ) {
            _mdi._bbdockRefresh(dop.orig_area);
            _mdi._bbdockMaybeRemoveButtonBar(dop.orig_area,true);

         } else if( dop.new_i>dop.orig_i ) {
            --dop.new_i;
         }

      } else {
         // Some OEMs rely on ON_CLOSE being called in order to save data
         // associated with their tool window, so call it.
         // IMPORTANT:
         // We use _event_handler() to check for the existence of an
         // ON_CLOSE event handler because the default handler will
         // destroy the form. We do not want that to happen if we can
         // avoid it, since WE want to be the one to dispose of the
         // form.
         // 1/31/2007 - rb
         // IMPORTANT:
         // Do NOT call on_close event handler if it is the default _toolbar_etab2.on_close
         // event handler since that one will delete the active form. The _toolbar_etab2.on_close
         // handler is only called when the user hits the 'X' on the tool window.
         _str handler = dop.tbwid._event_handler(on_close);
         int toolbarEtab2OnCloseIndex = eventtab_index(defeventtab _toolbar_etab2,defeventtab _toolbar_etab2,event2index(on_close));
         //say('_bbDipDropExecute: handler='handler'  toolbarEtab2OnCloseIndex='toolbarEtab2OnCloseIndex);
         int container = _tbContainerFromWid(selected_wid);
         _str FormName = container.p_name;
         if( handler!=0 && handler != toolbarEtab2OnCloseIndex ) {
            dop.tbwid.call_event(true,dop.tbwid,ON_CLOSE,'w');
         }
         // The on_close() event might have ripped the window out
         // from under us, so make sure it is still valid.
         // Note:
         // Window ids are reused a lot, so check the form name too.
         if( _iswindow_valid(container) && container.p_name==FormName ) {
            container._delete_window();
         }
      }
      if( dop.new_twspace2>=0 ) {
         gbbdockinfo[dop.newarea][dop.new_i].twspace=dop.new_twspace2;
      }

      // maybe reorient the buff tabs...
      if (formName == '_tbbufftabs_form') buff_maybe_reorient(dop.orig_area, dop.newarea);

      int index = find_index(formName,oi2type(OI_FORM));
      int wid = _mdi._bbdockInsert(dop.newarea,dop.new_i,
                                   dop.rowBreakBefore,
                                   dop.rowBreakAfter,
                                   index,
                                   dop.orig_tbflags,
                                   dop.new_twspace,
                                   dop.new_tabgroup,dop.new_tabOrder);
      if( dop.orig_hasSizeBars ) {
         _mdi._bbdockFindWid(wid,area,i,tabgroup,tabOrder);
         width = _dx2lx(SM_TWIP,dop.dst_width);
         height = _dy2ly(SM_TWIP,dop.dst_height);
         int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);
         container_wid.p_width=width;
         container_wid.p_height=height;
         if( dop.newarea==DOCKINGAREA_TOP || dop.newarea==DOCKINGAREA_BOTTOM ) {
            gbbdockinfo[dop.newarea][i].twspace= width;

         } else {
            gbbdockinfo[dop.newarea][i].twspace= height;
         }
      }
      _bbdockAdjustLeadingSpace(dop.newarea);
      _mdi._bbdockRefresh(dop.newarea);

      // Crash hard and fast if wid == 0
      wid._tbRestoreState(state,false);
   }
   int wid = _get_focus();
   if( wid!=0 && wid.p_DockingArea!=0 ) {
      // We docked onto a side, set focus back to the current edit window
      // or the command line if there is no edit window currently open.
      if( _mdi._no_child_windows() ) {
         _cmdline._set_focus();

      } else {
         _mdi.p_child._set_focus();
      }
   }

   // Update panel captions to reflect current focus
   _tbpanelUpdateAllPanels();
}

void _dockOpDragDropExecute(DockOperation& dop)
{
   _dockOpDragDropMode(dop);
   if( dop.newarea>=0 ) {
      // We successfully performed a drag-drop operation, so now
      // we can dock/undock the tool window based on the results
      // stored in the dop object.
      _dockOpDropExecute(dop);
   }
}

void _toolbar_etab2.lbutton_down()
{
   if( p_object!=OI_FORM && !_ImageIsSpace() ) {

      // Check to make sure we did not click on tab-linked tool window.
      if( p_object != OI_SSTAB ||
          (mou_tabid() >= 0 && _tabgroupFindActiveForm() == 0) ||
          mou_tabid() < 0 ) {

         // Not a valid object to operate on.
         // Fail quietly.
         return;
      }

      // Fall through to drag-drop operation
   }

   DockOperation dop;
   p_active_form._dockOpInit(dop);
   // If arg(1)!="" then always disallow docking
   dop.allowDocking = ( dop.allowDocking && arg(1)=="" );
   _dockOpDragDropExecute(dop);
}

/**
 * Remove the tool window on side area and at index i. Respace the surrounding
 * tool windows.
 * 
 * @param area MDI side where tool window exists.
 * @param i      Index of tool window to delete.
 * @param docking set this parameter to true if the toolbar is being docked/undocked
 */
void _bbdockRespaceAndRemove(DockingArea area, int i,boolean docking=false)
{
   if( !_bbdockRowHasSizeBars(area,i) &&
       ((i+1) < _bbdockPaletteLength(area) && gbbdockinfo[area][i+1].wid!=BBDOCKINFO_ROWBREAK) ) {

      // This is a row of toolbars, so maintain any existing
      // gaps between the toolbars.

      // Add this toolbar space to next toolbar in this row
      if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
         int twspace = 0;
         int wid = _bbdockContainer(&gbbdockinfo[area][i]);
         if( 0==gbbdockinfo[area][i].twspace && wid.p_x<0 ) {
            twspace -= _twips_per_pixel_x();
         }
         twspace += wid.p_width+gbbdockinfo[area][i].twspace;
         twspace=_lx2lx(SM_TWIP,SM_TWIP,twspace);
         gbbdockinfo[area][i+1].twspace += twspace;

      } else {
         int twspace = 0;
         int wid = _bbdockContainer(&gbbdockinfo[area][i]);
         if( 0==gbbdockinfo[area][i].twspace && wid.p_y<0 ) {
            twspace -= _twips_per_pixel_y();
         }
         twspace += wid.p_height+gbbdockinfo[area][i].twspace;
         twspace=_ly2ly(SM_TWIP,SM_TWIP,twspace);
         gbbdockinfo[area][i+1].twspace += twspace;
      }
   }
   _mdi._bbdockRemove(area,i,docking);
}

void _bbdockPositionTB(DockingArea area, int DOCKINGAREA_x2, int DOCKINGAREA_y1,
                       int orig_area, int orig_i, boolean HasSizeBars,
                       int& new_i, int& new_twspace, int& new_twspace2,
                       int x1, int y1, int x2, int y2,
                       int putInRow, /* 0 specifies NULL */
                       boolean& putInRowBreakAfter)
{
   //say('positionTB: x1='x1' width='(x2-x1));
   new_twspace=0;
   new_twspace2= -1;

   // Determine which row rect will go in
   int middle=(y1+y2) intdiv 2;
   int RowStart=0;
   int next_y=DOCKINGAREA_y1;
   int last_wid=0;
   putInRowBreakAfter=0;
   int line_height=0;
   int docked_row=_bbdockQRestoreRow(area,0);
   if( docked_row==0 ) {
      docked_row=_bbdockQMaxRestoreRow(area);
   }
   int i;
   int wid = 0;
   for( i=0;;++i ) {

      if( putInRow && docked_row>putInRow ) {
         // Insert this tool before this toolbar.
         new_i=i;
         putInRowBreakAfter=true;
         return;
      }
      if( i>=_bbdockPaletteLength(area) ) {
         next_y+=line_height;
         break;
      }
      if( last_wid==0 ) {
         RowStart=i;
         next_y+=line_height;
         line_height=_ly2dy(SM_TWIP,_bbdockRowHeight(area,i));
         if( putInRow ) {
            if( putInRow==docked_row ) {
               break;
            }

         } else {
            if( middle < (next_y+line_height) ) {
               break;
            }
         }
      }
      wid=gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         //_message_box('i='i' count='count);
         docked_row=_bbdockQRestoreRow(area,i+1);
         if( docked_row==0 ) {
            docked_row=_bbdockQMaxRestoreRow(area);
         }
      }
      last_wid=wid;
   }
   // The row this will go in is RowStart
   // Determine where in this row and what the new spacing
   // will be.
   boolean RowHasSizeBars=_bbdockRowHasSizeBars(area,RowStart);
   int x = 0;
   int junk = 0;
   int space = 0;
   int space_x = 0;
   int add_space = 0;
   int adjust = 0;
   int tempx = 0;
   int tempy = 0;
   int diff = 0;
   for( i=RowStart;;++i ) {
      if( i>=_bbdockPaletteLength(area) ) {
         break;
      }
      wid=_bbdockContainer(&gbbdockinfo[area][i]);
      //wid=gbbdockinfo[area][i].wid;
      if( wid>0 ) {
         x=_lx2dx(wid.p_xyscale_mode,wid.p_x);junk=0;
         _map_xy(wid.p_xyparent,0,x,junk,SM_PIXEL);
         if( x1<x && !(area==orig_area && i==orig_i) ) {
            new_i=i;
            // The original tool window is seen as leading space
            add_space=0;
            if( area==orig_area && (i-1)==orig_i && !HasSizeBars ) {
               add_space += _lx2dx(wid.p_xyscale_mode,gbbdockinfo[area][orig_i].twspace);
               add_space += _lx2dx(wid.p_xyscale_mode,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_width);
            }
            // IF this tool bar has leading space
            if( !HasSizeBars && !RowHasSizeBars &&
                (gbbdockinfo[area][i].twspace+add_space)!=0 ) {

               space=_lx2dx(wid.p_xyscale_mode,gbbdockinfo[area][i].twspace);
               space += add_space;
               space_x=x-space;
               if( x1<space_x ) {
                  adjust=space_x-x1;
                  x1 += adjust;
                  x2 += adjust;
               }
               // IF this new tool bar fits totally in this space
               if( x2<=x ) {
                  new_twspace=x1-space_x;
                  new_twspace2=x-x2-1;
                  if( new_twspace==0 ) {
                     ++new_twspace2;

                  } else if( add_space!=0 && new_twspace!=0 && gbbdockinfo[area][orig_i].twspace==0 ) {
                     --new_twspace2;
                     //say("got here");
                  }
                  if( new_twspace2<0 ) {
                     new_twspace2=0;
                  }
                  if( new_twspace2!=0 && add_space!=0 && gbbdockinfo[area][i].twspace==0 ) {
                     --new_twspace2;
                  }
                  if( add_space && _bbdockContainer(&gbbdockinfo[area][orig_i]).p_x<0 ) {
                     tempx=_lx2dx(SM_TWIP,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_x);
                     tempy=0;
                     _map_xy(_bbdockContainer(&gbbdockinfo[area][orig_i]),0,tempx,tempy,SM_PIXEL);
                     // If this control has not moved.
                     if( tempx==x1 ) {
                        if( new_twspace>0 ) {
                           --new_twspace;
                        } else {
                           --new_twspace2;
                        }
                     }
                  }
                  //say("new_twspace="new_twspace" new_twspace2="new_twspace2);
               } else {
                  new_twspace=x1-space_x;
                  new_twspace2=0;
               }
               new_twspace=_dx2lx(SM_TWIP,new_twspace);
               new_twspace2=_dx2lx(SM_TWIP,new_twspace2);
            }
            break;
         }
         if( (i+1) >= _bbdockPaletteLength(area) ||
             gbbdockinfo[area][i+1].wid==BBDOCKINFO_ROWBREAK) {
            // We are inserting after the last control.
            new_i=i+1;
            if( !HasSizeBars && !RowHasSizeBars ) {

               if( area==orig_area && (new_i-1)==orig_i && !HasSizeBars) {
                  space_x=_lx2dx(wid.p_xyscale_mode,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_x-gbbdockinfo[area][orig_i].twspace);
                  //say("APPEND leading space from self");

               } else {
                  //say("APPEND case");
                  wid=_bbdockContainer(&gbbdockinfo[area][i]);
                  space_x=_lx2dx(wid.p_xyscale_mode,wid.p_x+wid.p_width);
               }
               junk=0;
               _map_xy(wid.p_xyparent,0,space_x,junk,SM_PIXEL);
               if( x2>DOCKINGAREA_x2 ) {
                  diff=x2-DOCKINGAREA_x2;
                  x1 -= diff;
                  x2 -= diff;
               }
               if( x1>space_x ) {
                  new_twspace=_dx2lx(SM_TWIP,x1-space_x);
               }
            }
            break;
         }
      }
   }
}

void _bbdockPositionLR(DockingArea area, int DOCKINGAREA_y2, int DOCKINGAREA_x1,
                       int orig_area, int orig_i, boolean HasSizeBars,
                       int& new_i, int& new_twspace, int& new_twspace2,
                       int x1, int y1, int x2, int y2,
                       int putInRow, /* 0 specifies NULL */
                       boolean& putInRowBreakAfter)
{
   new_twspace=0;
   new_twspace2= -1;

   // Determine which row rect will go in
   int middle=(x1+x2) intdiv 2;
   int RowStart=0;
   int next_x=DOCKINGAREA_x1;
   int last_wid=0;
   putInRowBreakAfter=0;
   int line_width=0;
   int docked_row=_bbdockQRestoreRow(area,0);
   if( docked_row==0 ) {
      docked_row=_bbdockQMaxRestoreRow(area);
   }
   int wid = 0;
   int i;
   for( i=0;;++i ) {
      if( putInRow && docked_row>putInRow ) {
         // Insert this tool before this toolbar.
         new_i=i;
         putInRowBreakAfter=true;
         return;
      }
      if( i>=_bbdockPaletteLength(area) ) {
         next_x += line_width;
         break;
      }
      if( last_wid==0 ) {
         RowStart=i;
         next_x += line_width;
         line_width=_lx2dx(SM_TWIP,_bbdockRowWidth(area,i));
         if( putInRow ) {
            if( putInRow==docked_row ) {
               break;
            }

         } else {
            if( middle < (next_x+line_width) ) {
               break;
            }
         }
      }
      wid=gbbdockinfo[area][i].wid;
      if( wid==BBDOCKINFO_ROWBREAK ) {
         //_message_box('i='i' count='count);
         docked_row=_bbdockQRestoreRow(area,i+1);
         if (!docked_row) {
            docked_row=_bbdockQMaxRestoreRow(area);
         }
      }
      last_wid=wid;
   }

   int y = 0;
   int junk = 0;
   int add_space = 0;
   int space = 0;
   int space_y = 0;
   int adjust = 0;
   int tempx = 0;
   int tempy = 0;
   int diff = 0;

   // The row this will go in is RowStart
   // Determine where in this row and what the new spacing
   // will be.
   boolean RowHasSizeBars=_bbdockRowHasSizeBars(area,RowStart);
   for( i=RowStart;;++i ) {
      if( i>=_bbdockPaletteLength(area) ) {
         break;
      }
      wid=_bbdockContainer(&gbbdockinfo[area][i]);
      if( wid>0 ) {
         y=_ly2dy(wid.p_xyscale_mode,wid.p_y);junk=0;
         _map_xy(wid.p_xyparent,0,junk,y,SM_PIXEL);
         if( y1<y && !(area==orig_area && i==orig_i) ) {
            new_i=i;
            // The original tool window is seen as leading space
            add_space=0;
            if( area==orig_area && (i-1)==orig_i && !HasSizeBars ) {
               add_space += _ly2dy(wid.p_xyscale_mode,gbbdockinfo[area][orig_i].twspace);
               add_space += _ly2dy(wid.p_xyscale_mode,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_height);
            }
            // IF this tool bar has leading space
            if( !HasSizeBars && !RowHasSizeBars &&
                (gbbdockinfo[area][i].twspace+add_space)!=0 ) {

               space=_ly2dy(wid.p_xyscale_mode,gbbdockinfo[area][i].twspace);
               space += add_space;
               space_y=y-space;
               if( y1<space_y ) {
                  adjust=space_y-y1;
                  y1 += adjust;
                  y2 += adjust;
               }
               // IF this new tool bar fits totally in this space
               if( y2<=y ) {
                  new_twspace=y1-space_y;
                  new_twspace2=y-y2-1;
                  if( new_twspace==0 ) {
                     ++new_twspace2;
                  } else if( add_space!=0 && new_twspace!=0 && gbbdockinfo[area][orig_i].twspace==0 ) {
                     --new_twspace2;
                  }
                  if( new_twspace2<0 ) {
                     new_twspace2=0;
                  }
                  if( new_twspace2!=0 && add_space!=0 && gbbdockinfo[area][i].twspace==0 ) {
                     --new_twspace2;
                  }
                  if( add_space!=0 && _bbdockContainer(&gbbdockinfo[area][orig_i]).p_y<0 ) {
                     tempy=_ly2dy(SM_TWIP,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_y);
                     tempx=0;
                     _map_xy(_bbdockContainer(&gbbdockinfo[area][orig_i]),0,tempx,tempy,SM_PIXEL);
                     // If this control has not moved.
                     if( tempy==y1 ) {
                        if( new_twspace>0 ) {
                           --new_twspace;
                        } else {
                           --new_twspace2;
                        }
                     }
                  }

               } else {
                  new_twspace=y1-space_y;
                  new_twspace2=0;
               }
               new_twspace=_dy2ly(SM_TWIP,new_twspace);
               new_twspace2=_dy2ly(SM_TWIP,new_twspace2);
            }
            break;
         }
         if( (i+1) >= _bbdockPaletteLength(area) ||
             gbbdockinfo[area][i+1].wid==BBDOCKINFO_ROWBREAK ) {

            //We are inserting after the last control.
            new_i=i+1;
            if( !HasSizeBars && !RowHasSizeBars ) {
               if( area==orig_area && (new_i-1)==orig_i && !HasSizeBars ) {
                  space_y=_ly2dy(wid.p_xyscale_mode,_bbdockContainer(&gbbdockinfo[area][orig_i]).p_y-gbbdockinfo[area][orig_i].twspace);
                  //say("APPEND leading space from self");

               } else {
                  //say("APPEND case");
                  wid=_bbdockContainer(&gbbdockinfo[area][i]);
                  space_y=_ly2dy(wid.p_xyscale_mode,wid.p_y+wid.p_height);
               }
               junk=0;
               _map_xy(wid.p_xyparent,0,junk,space_y,SM_PIXEL);
               if( y2>DOCKINGAREA_y2 ) {
                  diff=y2-DOCKINGAREA_y2;
                  y1 -= diff;
                  y2 -= diff;
               }
               if( y1>space_y ) {
                  new_twspace=_dy2ly(SM_TWIP,y1-space_y);
               }
            }
            break;
         }
      }
   }
}

// "Dockable" menu item on _toolbar_menu
int _OnUpdate_tbDockableToggle(CMDUI &cmdui,int target_wid,_str command)
{
   int formwid = target_wid.p_active_form;
   _tbNewVersion();
   _str FormName = formwid.p_name;
   _TOOLBAR *ptb = _tbFind(FormName);
   boolean is_qtoolbar = _IsQToolbar(formwid);

   if(!is_qtoolbar && _tbpanelIsPanel(formwid) ) {
      formwid=formwid._tbpanelFindActiveForm();
      if( formwid==0 ) {
         // Uh oh
         return MF_GRAYED;
      }
   }
   //say('_OnUpdate_tbDockableToggle: formwid.p_name='formwid.p_name);
   if( !ptb ) {
      return MF_GRAYED;
   }
   boolean allow_docking = _tbIsDockingAllowed(ptb);
   if( allow_docking ) {
      allow_docking= 0!=( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
   }
   if((!is_qtoolbar && formwid.p_DockingArea!=0) || allow_docking ) {
      // Docked.
      // Regardless of whether def_toolbartab says this tool window is
      // dockable, it is in fact docked, so put a check on it.
      return (MF_ENABLED|MF_CHECKED);
   } else {
      // Floating or docking not allowed
      return (MF_ENABLED|MF_UNCHECKED);
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

   if( wid==0 ) {
      // Use active form
      wid=p_active_form;
   }

   if( _isContainer(wid) ) {
      wid=wid._containerFindActiveForm();
      if( wid==0 ) {
         // Uh oh
         return;
      }
   }
   _tbNewVersion();
   _str FormName = wid.p_name;
   _TOOLBAR *ptb = _tbFind(FormName);
   if( !ptb ) {
      return;
   }

   boolean allow_docking = _tbIsDockingAllowed(ptb);
   if( allow_docking ) {
      allow_docking= 0!=( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
   }
   // Toggle
   allow_docking = !allow_docking;
   if (_IsQToolbar(wid)) {
      _tbQToolbarSetDockable(wid, allow_docking);
      if( allow_docking ) {
         ptb->tbflags |= TBFLAG_ALLOW_DOCKING;
      } else {
         ptb->tbflags &= ~(TBFLAG_ALLOW_DOCKING);
      }
      return;
   }

   boolean was_docked = ( wid.p_DockingArea!=0 );
   if( was_docked && !allow_docking ) {
      _tbClose(wid);
      ptb->restore_docked=false;
      ptb->tbflags &= ~(TBFLAG_ALLOW_DOCKING);
      tbShow(FormName);
      _config_modify_flags(CFGMODIFY_DEFVAR);
      return;
   }
   if( allow_docking ) {
      ptb->tbflags |= TBFLAG_ALLOW_DOCKING;
   } else {
      ptb->tbflags &= ~(TBFLAG_ALLOW_DOCKING);
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
}

// "Floating" menu item on _toolbar_menu
int _OnUpdate_tbFloatingToggle(CMDUI &cmdui,int target_wid,_str command)
{
   int formwid = target_wid.p_active_form;
   if (_IsQToolbar(formwid)) {
      return _tbQToolbarOnUpdateFloatingToggle(formwid);
   }

   if( formwid.p_DockingArea!=0 ) {
      // Docked
      return (MF_ENABLED|MF_UNCHECKED);
   } else {
      // Floating
      return (MF_ENABLED|MF_CHECKED);
   }
}

/**
 * Toggle between floating/docked tool window.
 * 
 * @param wid (optional). Window id of tool window. Uses the active form
 *            if not specified.
 */
_command void tbFloatingToggle(int wid=0)
{
   if( isEclipsePlugin() ) {
      return;
   }

   if( wid==0 ) {
      // Use active form
      wid=p_active_form;
   }

   if( _isContainer(wid) ) {
      wid=wid._containerFindActiveForm();
      if( wid==0 ) {
         // Uh oh
         return;
      }
   }
   _tbNewVersion();
   _str FormName = wid.p_name;
   _TOOLBAR *ptb = _tbFind(FormName);
   if( !ptb ) {
      return;
   }
   if (_IsQToolbar(wid)) {
      _tbQToolbarFloatingToggle(wid);
      return;
   }
   boolean was_docked = ( wid.p_DockingArea!=0 );
   boolean allow_docking = _tbIsDockingAllowed(ptb);
   if( allow_docking ) {
      allow_docking= 0!=( ptb->tbflags & TBFLAG_ALLOW_DOCKING );
   }
   if( was_docked ) {

      typeless state = null;
      wid._tbSaveState(state,false);

      _tbClose(wid,true);
      ptb->restore_docked=false;
      //tbShow(FormName);
      if( ptb->show_width!=0 ) {
         _tbShow(FormName,ptb->show_x,ptb->show_y,ptb->show_width,ptb->show_height);
      } else {
         _tbShow(FormName,0,0,0,0);
      }

      wid=_tbIsVisible(FormName);
      wid._tbRestoreState(state,false);

   } else if( !was_docked && allow_docking ) {

      typeless state = null;
      wid._tbSaveState(state,false);

      _tbClose(wid,true);
      ptb->restore_docked=true;
      _tbShowDocked(FormName);

      wid=_tbIsVisible(FormName);
      wid._tbRestoreState(state,false);

   } else {
      // Tool window was not docked AND is NOT dockable
   }
}

// "Movable" menu item on _toolbar_menu
int _OnUpdate_tbMovableToggle(CMDUI &cmdui,int target_wid,_str command)
{
   int formwid = target_wid.p_active_form;
   if (_IsQToolbar(formwid)) {
      return _tbQToolbarOnUpdateMovableToggle(formwid);
   }

   // not implemented
   return MF_GRAYED;
}

/**
 * Toggle movable tool window.
 * 
 * @param wid (optional). Window id of tool window. Uses the active form
 *            if not specified.
 */
_command void tbMovableToggle(int wid=0)
{
   if( isEclipsePlugin() ) {
      return;
   }

   if( wid==0 ) {
      // Use active form
      wid=p_active_form;
   }

   if( _isContainer(wid) ) {
      wid=wid._containerFindActiveForm();
      if( wid==0 ) {
         // Uh oh
         return;
      }
   }
   _tbNewVersion();
   _str FormName = wid.p_name;
   _TOOLBAR *ptb = _tbFind(FormName);
   if( !ptb ) {
      return;
   }
   if (_IsQToolbar(wid)) {
      _tbQToolbarMovableToggle(wid);
      return;
   }

   // not implemented
}

void _toolbar_etab2.lbutton_double_click()
{
   if( p_window_id!=p_active_form && !_ImageIsSpace() ) {
      // Not a valid area to toggle from
      return;
   }
   tbFloatingToggle(p_active_form);
}

void _toolbar_etab2.rbutton_up()
{
   call_event(defeventtab _dock_palette_form,RBUTTON_UP,'e');
}

int _tbGetWid(_str FormName)
{
   int wid = _find_formobj(FormName,'n');
   return wid;
}

int _tbIsVisible(_str FormName)
{
   int wid = _find_formobj(FormName,'n');
   if( wid>0 && _tbIsAutoHiddenWid(wid) ) {
      // The form is hidden inside the autopane container,
      // but not visible (because it is auto hidden).
      return 0;
   }
   return wid;
}

int _tbIsActive(_str FormName)
{
   int wid = _tbIsVisible(FormName);
   if( wid==0 || !_tbIsWidActive(wid) ) {
      return 0;
   }
   return wid;
}

boolean _tbIsWidActive(int wid)
{
   if( wid<=0 ) {
      return false;
   }
   int tabContainerWid = _tbTabGroupContainerWidFromWid(wid);
   if( tabContainerWid>0 ) {
      _str containerName = tabContainerWid.p_name;
      if( containerName==_tabgroupFormName2ContainerName(wid.p_name) ) {
         // Names match, so this is definitely a tab-linked tool window

         // Compare ActiveOrder for the tabgroup (i.e. active tab) with that
         // of the container. If they are not equal, then this container is
         // not the active tab.
         int tabWid = _tbTabGroupWidFromWid(wid);
         if( tabWid.p_ActiveOrder==tabContainerWid.p_ActiveOrder ) {
            return true;
         }
      }
      // If we got here, then this is not a tab-link tab or the tab was
      // not active.
      return false;
   }
   return (!_tbIsAutoHiddenWid(wid));
}

boolean tbIsWidDocked(int wid)
{
   if( wid<=0 ) {
      return false;
   }
   return (wid.p_DockingArea!=0);
}

boolean tbIsDocked(_str FormName)
{
   int wid = _find_formobj(FormName,'n');
   return (tbIsWidDocked(wid));
}

void _tbexiting_editor()
{
   // _append_retrieve changes the active view in
   // the hidden window.  Here we save and restore
   // the active window.
   int orig_wid;
   get_window_id(orig_wid);
   int Noftoolbars=0;
   int i;
   for( i=0;i<def_toolbartab._length();++i ) {
      int wid = _find_formobj(def_toolbartab[i].FormName,'n');
      // DJB (08/22/2006
      // Auto-hidden toolbars still need on_destory to save settings
      if( wid>0 /*&& !_tbIsAutoWid(wid)*/ ) {
         wid.call_event(wid,ON_DESTROY);
      }
   }
   activate_window(orig_wid);
}

boolean isNoTabLinkToolbar(_str FormName)
{
   switch( FormName ) {
   case "_tbdebug_watches_form":
   case "_tbFTPClient_form":
   case "_tbprops_form":
      return true;
      break;
   }
   return false;
}

/**
 * Restore row numbers tend to get large over time, so we need to
 * normalize (shrink) them before they overflow.
 */
void _tbShrinkRestoreRowNumbers()
{
   int area;
   int restore_row=0;
   for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {
      int max_restore_row = _bbdockQMaxRestoreRow(area);
      int xlat[];
      int i;
      for( i=0; i<=max_restore_row; ++i ) {
         xlat[i]=0;
      }
      for( i=0; i<_bbdockPaletteLength(area); ++i ) {
         BBDOCKINFO* pbbdockinfo;
         pbbdockinfo=&gbbdockinfo[area][i];
         int wid = pbbdockinfo->wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            xlat[pbbdockinfo->docked_row]=1;
         }
      }
      for( i=0; i<def_toolbartab._length(); ++i ) {
         _TOOLBAR* ptb = &def_toolbartab[i];
         if( ptb->docked_area==area ) {
            xlat[ptb->docked_row]=1;
         }
      }
      restore_row=1;
      for( i=0; i<=max_restore_row; ++i ) {
         if( xlat[i]!=0 ) {
            xlat[i]=restore_row;
            ++restore_row;
         }
      }
      for( i=0; i<_bbdockPaletteLength(area); ++i ) {
         BBDOCKINFO* pbbdockinfo;
         pbbdockinfo=&gbbdockinfo[area][i];
         int wid = pbbdockinfo->wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            pbbdockinfo->docked_row=xlat[pbbdockinfo->docked_row];
         }
      }
      for( i=0; i<def_toolbartab._length(); ++i ) {
         _TOOLBAR* ptb;
         ptb=&def_toolbartab[i];
         if( ptb->docked_area==area ) {
            ptb->docked_row=xlat[ptb->docked_row];
         }
      }
   }
}

/**
 * Tabgroup numbers tend to get large over time, so we need to
 * normalize (shrink) them before they overflow.
 */
static void _tbShrinkTabGroupNumbers()
{
   int max_tabgroup = _bbdockQMaxTabGroup();
   int xlat[];
   int i;
   int area;
   int tabgroup;

   // Initialize tabgroup mapping array
   for( i=0; i<=max_tabgroup; ++i ) {
      xlat[i]=0;
   }

   // Mark docked tool windows that are part of a tabgroup
   for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {

      for( i=0; i<_bbdockPaletteLength(area); ++i ) {
         BBDOCKINFO* pbbdockinfo;
         pbbdockinfo=&gbbdockinfo[area][i];
         int wid = pbbdockinfo->wid;
         if( wid>0 && wid!=BBDOCKINFO_ROWBREAK ) {
            tabgroup=pbbdockinfo->tabgroup;
            if( tabgroup>0 ) {
               xlat[pbbdockinfo->tabgroup]=1;
            }
         }
      }
   }

   // Mark stored tool windows that were part of a tabgroup
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      if( ptb->tabgroup>0 ) {
         xlat[ptb->tabgroup]=1;
      }
   }

   // Map marked tabgroups numbers to new set of tabgroup numbers
   tabgroup=1;
   for( i=0; i<=max_tabgroup; ++i ) {
      if( xlat[i]!=0 ) {
         xlat[i]=tabgroup;
         ++tabgroup;
      }
   }

   // Change tabgroup numbers for docked tool windows to new (shrunk) tabgroup numbers
   for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {

      for( i=0; i<_bbdockPaletteLength(area); ++i ) {
         BBDOCKINFO* pbbdockinfo;
         pbbdockinfo=&gbbdockinfo[area][i];
         int wid = pbbdockinfo->wid;
         if( wid>0 && wid!=BBDOCKINFO_ROWBREAK ) {
            tabgroup=pbbdockinfo->tabgroup;
            if( tabgroup>0 ) {
               pbbdockinfo->tabgroup=xlat[pbbdockinfo->tabgroup];
            }
         }
      }
   }

   // Change tabgroup numbers for stored tool windows to new (shrunk) tabgroup numbers
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb;
      ptb=&def_toolbartab[i];
      if( ptb->tabgroup>0 ) {
         ptb->tabgroup=xlat[ptb->tabgroup];
      }
   }
}

/**
 * Taborder numbers of a tabgroup tend to get large over time, so we need to
 * normalize (shrink) them before they overflow.
 */
static void _tbShrinkTabOrderNumbers(int tabgroup)
{
   int max_tabOrder = 0;
   int tabOrder;
   int i;

   DockingArea area, first_i, last_i;

   // Find the max tabOrder for docked tool windows of this tabgroup
   if( _bbdockFindTabGroup(tabgroup,area,first_i,last_i) ) {

      for( i=first_i; i<=last_i; ++i ) {
         tabOrder=gbbdockinfo[area][i].tabOrder;
         if( tabOrder>max_tabOrder ) {
            max_tabOrder=tabOrder;
         }
      }
   }

   // Find the max tabOrder for saved tool windows
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      if( ptb->tabgroup == tabgroup && ptb->tabOrder > max_tabOrder ) {
         max_tabOrder=tabOrder;
      }
   }

   int xlat[];

   // Initialize tabOrder mapping array
   for( i=0; i<=max_tabOrder; ++i ) {
      xlat[i]=0;
   }

   // Mark docked tool windows that are part of this tabgroup
   for( i=first_i; i<=last_i; ++i ) {
      tabOrder=gbbdockinfo[area][i].tabOrder;
      xlat[tabOrder]=1;
   }

   // Mark stored tool windows that were part of this tabgroup
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      if( ptb->tabgroup == tabgroup ) {
         xlat[ptb->tabOrder]=1;
      }
   }

   // Map marked tabOrder numbers for this tabgroup to new set of
   // tabOrder numbers.
   tabOrder=1;
   for( i=0; i<=max_tabOrder; ++i ) {
      if( xlat[i]!=0 ) {
         xlat[i]=tabOrder;
         ++tabOrder;
      }
   }

   // Change tabOrder numbers for docked tool windows of this tabgroup
   // to new (shrunk) tabOrder numbers.
   for( i=first_i; i<=last_i; ++i ) {
      gbbdockinfo[area][i].tabOrder=xlat[ gbbdockinfo[area][i].tabOrder ];
   }

   // Change tabOrder numbers for stored tool windows of this tabgroup
   // to new (shrunk) tabOrder numbers
   for( i=0; i<def_toolbartab._length(); ++i ) {
      _TOOLBAR* ptb = &def_toolbartab[i];
      if( ptb->tabgroup == tabgroup ) {
         ptb->tabOrder=xlat[ptb->tabOrder];
      }
   }
}

void _bbdockInsertControlPositionTB(DockingArea area,int DOCKINGAREA_y1,
                                    int x1,int y1,int x2,int y2,
                                    int &toolbar_wid,
                                    int &tab_index /* 1 means insert before first*/)
{
   toolbar_wid= 0;
   tab_index=0;

   // Determine which row rect will go in
   int middle=(y1+y2) intdiv 2;
   int RowStart=0;
   int next_y=DOCKINGAREA_y1;
   int last_wid=0;
   int line_height=0;
   int i;
   for (i=0;;++i) {
      if (i>=_bbdockPaletteLength(area)) {
         next_y+=line_height;
         break;
      }
      if (!last_wid) {
         RowStart=i;
         next_y+=line_height;
         line_height=_ly2dy(SM_TWIP,_bbdockRowHeight(area,i));
         if (middle<next_y+line_height) {
            break;
         }
      }
      int wid = gbbdockinfo[area][i].wid;
      last_wid=wid;
   }

   int sx1,sy1,swidth,sheight;
   int sx2,sy2;
   int child = 0;
   int first_child = 0;

   // The row this will go in is RowStart
   for (i=RowStart;;++i) {
      if (i>=_bbdockPaletteLength(area)) {
         break;
      }
      int wid = gbbdockinfo[area][i].wid;
      if (wid>0 && (gbbdockinfo[area][i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED)) {

         wid._get_window(sx1,sy1,swidth,sheight);
         _lxy2dxy(wid.p_xyscale_mode,sx1,sy1);
         _lxy2dxy(wid.p_xyscale_mode,swidth,sheight);
         _map_xy(wid.p_xyparent,0,sx1,sy1,SM_PIXEL);
         sy2=sy1+sheight;
         sx2=sx1+swidth;
         // IF left side of rect of this rect inside this toolbar OR
         //    right side of rect of this rect inside this toolbar
         if ((x1>=sx1&& x1<sx2)||
             (x2>sx1&& x2<sx2)) {
            toolbar_wid=wid;
            // Now determine where in this tool bar to insert this control
            first_child=child=wid.p_child;
            tab_index=1;
            if (child) {
               for(; ;++tab_index) {
                  child._get_window(sx1,sy1,swidth,sheight);
                  _lxy2dxy(child.p_xyscale_mode,sx1,sy1);
                  _lxy2dxy(child.p_xyscale_mode,swidth,sheight);
                  _map_xy(child.p_xyparent,0,sx1,sy1,SM_PIXEL);
                  sy2=sy1+sheight;
                  sx2=sx1+swidth;
                  // IF left side of rect to left of this control
                  if (x1<=sx1) {
                     break;
                  }
                  // IF left side of rect inside this control
                  if (x1>=sx1&& x1<sx2) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }
                  // IF right side of rect of this rect inside this toolbar
                  if ((x2>sx1&& x2<sx2)) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }
                  child=child.p_next;
                  if (child==first_child) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }

               }
            }
            break;

         }
      }
   }
   //say("toolbar_wid="toolbar_wid" tab_index="tab_index);
}

void _bbdockInsertControlPositionLR(DockingArea area,int DOCKINGAREA_x1,
                                    int x1,int y1,int x2,int y2,
                                    int &toolbar_wid,
                                    int &tab_index /* 1 means insert before first*/)
{
   toolbar_wid= 0;
   tab_index=0;

   // Determine which row rect will go in
   int middle=(x1+x2) intdiv 2;
   int RowStart=0;
   int next_x=DOCKINGAREA_x1;
   int last_wid=0;
   int line_width=0;
   int i;
   for (i=0;;++i) {
      if (i>=_bbdockPaletteLength(area)) {
         next_x+=line_width;
         break;
      }
      if (!last_wid) {
         RowStart=i;
         next_x+=line_width;
         line_width=_lx2dx(SM_TWIP,_bbdockRowWidth(area,i));
         if (middle<next_x+line_width) {
            break;
         }
      }
      int wid = gbbdockinfo[area][i].wid;
      last_wid=wid;
   }

   int sx1,sy1,swidth,sheight;
   int sx2,sy2;
   int child = 0;
   int first_child = 0;

   // The row this will go in is RowStart
   for (i=RowStart;;++i) {
      if (i>=_bbdockPaletteLength(area)) {
         break;
      }
      int wid = gbbdockinfo[area][i].wid;
      if (wid>0 && (gbbdockinfo[area][i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED)) {

         wid._get_window(sx1,sy1,swidth,sheight);
         _lxy2dxy(wid.p_xyscale_mode,sx1,sy1);
         _lxy2dxy(wid.p_xyscale_mode,swidth,sheight);
         _map_xy(wid.p_xyparent,0,sx1,sy1,SM_PIXEL);
         sy2=sy1+sheight;
         sx2=sx1+swidth;
         // IF left side of rect of this rect inside this toolbar OR
         //    right side of rect of this rect inside this toolbar
         if ((y1>=sy1&& y1<sy2)||
             (y2>sy1&& y2<sy2)) {
            toolbar_wid=wid;
            // Now determine where in this tool bar to insert this control
            first_child=child=wid.p_child;
            tab_index=1;
            if (child) {
               for(; ;++tab_index) {
                  child._get_window(sx1,sy1,swidth,sheight);
                  _lxy2dxy(child.p_xyscale_mode,sx1,sy1);
                  _lxy2dxy(child.p_xyscale_mode,swidth,sheight);
                  _map_xy(child.p_xyparent,0,sx1,sy1,SM_PIXEL);
                  sy2=sy1+sheight;
                  sx2=sx1+swidth;
                  // IF left side of rect to left of this control
                  if (y1<=sy1) {
                     break;
                  }
                  // IF left side of rect inside this control
                  if (y1>=sy1&& y1<sy2) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }
                  // IF right side of rect of this rect inside this toolbar
                  if ((y2>sy1&& y2<sy2)) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }
                  child=child.p_next;
                  if (child==first_child) {
                     // Insert after last child
                     ++tab_index;
                     break;
                  }

               }
            }
            break;

         }
      }
   }
   //say("toolbar_wid="toolbar_wid" tab_index="tab_index);
}

void _tbAdjustTabIndexes(int toolbar_wid,int tab_index,int adjust)
{
   int child = 0;
   int first_child = 0;
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
   _str FormName = toolbar_wid.p_name;
   if( toolbar_wid.p_DockingArea!=0 ) {
      int palette_wid = _mdi._bbdockPaletteGet(toolbar_wid.p_DockingArea);
      DockingArea area, i;
      int tabgroup, tabOrder;
      if( _bbdockFindWid(toolbar_wid,area,i,tabgroup,tabOrder) ) {

         // This tool window might be a child of a container, so make
         // sure we delete the container window.
         int container_wid = _bbdockContainer(&gbbdockinfo[area][i]);
         int parent_wid = palette_wid;
         boolean tabLink = ( tabgroup>0 );
         int old_ActiveTab = -1;
         if( tabLink ) {
            int tabgroup_wid = _tbTabGroupWidFromWid(toolbar_wid);
            if( tabgroup_wid>0 && tabgroup_wid.p_object==OI_SSTAB ) {
               // Tab-link this tool window into a tabgroup
               parent_wid=tabgroup_wid;
               // Make the container be the SSTab container we want to delete
               container_wid=_tbTabGroupContainerWidFromWid(toolbar_wid);
               old_ActiveTab=tabgroup_wid.p_ActiveTab;
            }
         }

         // Delete the container for this tool window
         if( container_wid.p_object==OI_SSTAB_CONTAINER ) {
            container_wid._makeActive();
            parent_wid._deleteActive();

         } else {
            container_wid.p_visible=false;
            container_wid._delete_window();
         }

         // Recreate the tool window
         int tbflags = gbbdockinfo[area][i].tbflags;
         int resource_index = find_index(FormName,oi2type(OI_FORM));
         int wid = _tbSmartLoadTemplate(tbflags,resource_index,parent_wid,tabLink);
         if( wid!=0 ) {
            if( old_ActiveTab>=0 ) {
               // Refetch the SSTab control (if any) and reset the old ActiveTab index
               int tabgroup_wid=_tbTabGroupWidFromWid(wid);
               if( tabgroup_wid>0 && tabgroup_wid.p_object==OI_SSTAB &&
                   old_ActiveTab!=tabgroup_wid.p_ActiveTab && old_ActiveTab<tabgroup_wid.p_NofTabs ) {

                  tabgroup_wid.p_ActiveTab=old_ActiveTab;
               }
            }
         }

         // Refresh this side
         gbbdockinfo[area][i].wid=wid;
         _mdi._bbdockRefresh(area);
      }

   } else {
      boolean wasAutoWid = _tbIsAutoWid(toolbar_wid);
      boolean isQToolbar = _IsQToolbar(toolbar_wid);
      _str tbstate = '';
      if (isQToolbar) {
         // need to restore toolbar state
         _QToolbarGetState(tbstate);
      }
      if( _tbIsAutoShownWid(toolbar_wid) ) {
         // Hide it immediately
         _tbAutoHide(toolbar_wid);
      }
      //toolbar_wid._delete_window();
      toolbar_wid._tbSmartDeleteWindow();
      // Do not reshow an auto shown/hidden tool window floating
      if( !wasAutoWid ) {
         // Correct the parent
         tbShow(FormName);
         if (isQToolbar) {
            _QToolbarSetState(tbstate);
            toolbar_wid = _tbIsVisible(FormName);
            if (toolbar_wid) {
               _QToolbarUpdateSize(toolbar_wid);
            }
         }
      }
   }
}

boolean _tbIsCustomizeableToolbar(int index)
{
   if( !def_localsta ) {
      return false;
   }
   _str name = name_name(index);
   if( substr(name,1,3)!="-tb" ) {
      return false;
   }
   name=translate(name,'_','-');
   int i;
   for( i=0;i<init_toolbartab._length();++i ) {
      if( init_toolbartab[i].FormName==name &&
          0!=(init_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) ) {
         return true;
      }
   }
   return false;
}

void activate_tab(_str ActiveTabCaption, _str PutFocusOnCtlName,
                  _str FormName, _str TabControlName)
{
   if( !_IsToolbarAllowed(FormName) ) {
      return;
   }
   _str toolbar = FormName;
   int wid = _find_formobj(toolbar,'n');
   if( wid == 0 ) {
      // This will restore the users last location of the toolbar
      tbShow(FormName);
   }
   wid=_find_formobj(toolbar,'n');
   if( wid != 0 ) {
      int tabid = wid._find_control(TabControlName);
      SSTABCONTAINERINFO info;
      int i, n=tabid.p_NofTabs;
      for( i=0; i < n; ++i ) {
         tabid._getTabInfo(i,info);
         if( stranslate(info.caption,'','&') == ActiveTabCaption ) {
            tabid.p_ActiveTab = i;
            p_window_id = tabid;
            int ctlwid = wid._find_control(PutFocusOnCtlName);
            if( ctlwid > 0 ) {
               ctlwid._set_focus();
            }
         }
      }
      if( ActiveTabCaption == '' ) {
         wid._set_focus();
      }
   }
}

void tbWidEnable(int wid, boolean enable)
{
   if( wid<=0 || !_iswindow_valid(wid) ) {
      return;
   }
   // Set the form p_enabled property if inside a container. The container
   // for the tool window will pick this up and enable/disable appropriately
   // if it is the active tab.
   // Note:
   // Not a good idea to disable floating tool windows, since you would
   // not be able to move or close the window after it is disabled. However,
   // if the tool window is inside a container (e.g. panel, grabbar form),
   // then it is safe because the outer container is not disabled.
   int container_wid = _tbContainerFromWid(wid);
   if( _isContainer(container_wid) ) {
      wid.p_enabled=enable;
      int tabgroup_wid = _tbTabGroupWidFromWid(wid);
      int tabcontainer_wid = _tbTabGroupContainerWidFromWid(wid);
      if( tabgroup_wid>0 && tabcontainer_wid>0 ) {
         tabgroup_wid._setEnabled(tabcontainer_wid.p_ActiveOrder,(int)enable);
      }
      container_wid._containerUpdate();
   }
}

void tbEnable(_str FormName, boolean enable)
{
   int formwid = _find_formobj(FormName,'n');
   if( formwid>0 ) {
      tbWidEnable(formwid,enable);
   }
}

/**
 * Activate the tool window and put focus on the control given.
 * If the tool window is tab-linked, then that tab is made active.
 * 
 * @param FormName          Name of the tool window form to activate.
 * @param PutFocusOnCtlName The child control in the tool window to
 *                          give focus to after activation.
 * @param DoSetFocus        default true, if false, do not change focus
 * 
 * @return The wid of the tool window; otherwise 0.
 */
int activate_toolbar(_str FormName, _str PutFocusOnCtlName, boolean DoSetFocus=true)
{

   // RGH - 4/20/06
   // Bypassing this check for some toolwindows in Eclipse
   if(!isEclipsePlugin() || !(FormName:=='_tbfind_form' || FormName:=='_tbregex_form' || FormName :== '_tbfind_symbol_form' || FormName:=='_tbclipboard_form' || FormName:=='_tbnotification_form' || FormName :== '_tbprops_form')){
      if ( !_IsToolbarAllowed(FormName) ) {
         return 0;
      }
   }
   int wid = _find_formobj(FormName,'n');
   if( wid==0 || _tbIsAutoHiddenWid(wid) ) {
      // Check for auto hidden tool window
      wid=_tbMaybeAutoShow(FormName,"",true);
      if( wid==0 ) {
         // This will restore the users last location of the tool window
         tbShow(FormName);
      }
   }
   wid=_find_formobj(FormName,'n');
   if( wid!=0 ) {

      // If the tool window is tab-linked, then we must make it
      // the active tab of its tab control parent.
      int tabContainerWid = _tbTabGroupContainerWidFromWid(wid);
      if( tabContainerWid>0 ) {
         int tabWid = _tbTabGroupWidFromWid(wid);
         int oldActiveTab = tabWid.p_ActiveTab;
         tabContainerWid._makeActive();
         if( oldActiveTab!=tabWid.p_ActiveTab ) {
            // _makeActive() does not send ON_CHANGE with CHANGE_TABACTIVATED
            // when the active tab changes, so we must do it here.
            tabWid.call_event(CHANGE_TABACTIVATED,tabWid,ON_CHANGE,'W');
         }
      }
      if( PutFocusOnCtlName!="" ) {
         // Now find the control we want to have initial focus
         int ctlwid = wid._find_control(PutFocusOnCtlName);
         if( ctlwid>0 && DoSetFocus ) {
            ctlwid._set_focus();
         }

      } else if( tabContainerWid>0 ) {
         // Tab-linked tool windows' focus is handled in _tabgroup_etab.ON_CHANGE,
         // so nothing to do here.

      } else if (DoSetFocus) {
         // Give focus to the form
         wid._set_focus();
      }
   }
   return wid;
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
int activate_toolbar_tabgroup(_str FormName)
{
   if( !_IsToolbarAllowed(FormName) ) {
      return 0;
   }
   int wid = _find_formobj(FormName,'n');
   if( wid==0 || _tbIsAutoHiddenWid(wid) ) {

      // Check for last shown dock channel item.
      // Note:
      // We do this since the dock channel item might be all there
      // is if the user has not hovered over the item to auto show
      // the tool window yet.
      DockingArea area;
      int pic;
      _str caption;
      boolean active;
      dockchanFind(FormName,area,pic,caption,active);
      if( !active ) {
         // Only show the last auto shown wid
         return 0;
      }
      wid=_tbMaybeAutoShow(FormName,"",true);
   }
   wid=_find_formobj(FormName,'n');
   if( wid!=0 ) {

      // If the tool window is tab-linked, then we must return
      // the active window in the tabgroup (not necessarily the
      // same as the wid we found.
      int tabContainerWid = _tbTabGroupContainerWidFromWid(wid);
      if( tabContainerWid>0 ) {
         int tabWid = _tbTabGroupWidFromWid(wid);
         wid=tabWid._tabgroupFindActiveForm();
      }

      // Give focus to the form
      wid._set_focus();
   }

   return wid;
}

boolean _IsToolbarAllowed(_str FormName)
{
   if( isEclipsePlugin() ) {
      return false;
   }
   int index=find_index(FormName,oi2type(OI_FORM));
   if( index==0 ) {
      return true;
   }
   //list="Output,Slick-C Stack";
   typeless list=_default_option(VSOPTIONZ_SUPPORTED_TOOLBARS_LIST);
   if( list._isempty() ) {
      return true;
   }
   list=','list',';
   if( 0==pos(','index.p_caption',',list,1,'i') ) {
      return false;
   }
   return true;
}

_command void toggle_docked(...)  name_info(','VSARG2_EDITORCTL)
{
   _str FormName = strip(lowcase(arg(1)));
   int wid = 0;
   _TOOLBAR* ptb = null;
   int i;
   for( i=0; i<def_toolbartab._length(); ++i ) {
      ptb = &def_toolbartab[i];
      wid=find_index(ptb->FormName,oi2type(OI_FORM));
      if( wid!=0 ) {
         if( strieq(wid.p_caption,FormName) ) {
            break;
         }
      }
      ptb=null;
      wid=0;
   }

   _tbNewVersion();
   if( wid!=0 ) {
      FormName=wid.p_name;
   }
   wid=_find_formobj(FormName,'n');
   if( wid==0 ) {
      _message_box('Toolbar 'FormName' not found');
      return;
   }
   boolean was_docked = tbIsWidDocked(wid);
   tbClose(wid,true);
   if( was_docked ) {
      ptb->restore_docked=false;
      tbShow(FormName);
      return;
   }
   ptb->restore_docked=true;
   _tbShowDocked(FormName);
}

_command void dock(...)  name_info(FORM_ARG','VSARG2_EDITORCTL)
{
   _tbNewVersion();
   int focus_wid=_get_focus();
   //ToolbarCaption=lowcase(arg(1));
   _str FormName=arg(1);
   typeless side=arg(2);

   _TOOLBAR *ptb=_tbFind(FormName);
   int index=find_index(FormName,oi2type(OI_FORM));
   if( !ptb || index==0 ) {
      // This should not happen so it is OK to display form name
      _message_box('Toolbar 'FormName' not found');
      return;
   }
   _str toolbar=FormName;

   int wid = _find_formobj(toolbar,'n');
   if( wid>0 ) {
      if( tbIsWidDocked(wid) ) {
         _message_box("This toolbar is already visible");
         return;
      } else {
         wid._tbSmartDeleteWindow();
      }
   }
   if( !isinteger(side) ) {

      if( toolbar:=="_tbprojects_form" || toolbar:=="_tbproctree_form" ||
          toolbar:=="_tbcbrowser_form" || toolbar:=="_tbopen_form" ||
          toolbar:=="tbftpopen_form" ) {

         side=DOCKINGAREA_LEFT;
      } else if( toolbar:=="_tbfind_symbol_form" || toolbar:=="_tbfind_form" || 
                 toolbar:=="_tbfilelist_form" ) {
         side=DOCKINGAREA_RIGHT;
      } else if( toolbar:=="_tbsearch_form" || toolbar:=="_tbtagwin_form" ||
                 toolbar:=="_tbtagrefs_form" || toolbar:=="_tbshell_form" ||
                 toolbar:=="_tboutputwin_form" ) {
         side=DOCKINGAREA_BOTTOM;
      } else if( 0==(ptb->tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) ) {
         // Debug toolbars
         side=DOCKINGAREA_BOTTOM;
      } else {
         side=DOCKINGAREA_TOP;
      }
   }
   _mdi._bbdockInsert(side,-1,0,0,index,ptb->tbflags,0);
   _mdi._bbdockRefresh(side);
   if( focus_wid!=0 && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
}

_command void tbHide(_str FormName="", boolean quiet=true) name_info(FORM_ARG',')
{
   int focus_wid = _get_focus();
   FormName=arg(1);
   int index = 0;

   _TOOLBAR *ptb = _tbFind(FormName);
   if( !ptb ) {
      if (!quiet) _message_box('Toolbar 'FormName' not found');
      return;
   }
   int wid = _tbIsVisible(FormName);
   if( wid==0 ) {
      if (!quiet) _message_box("This toolbar is not visible");
      return;
   }
   tbClose(wid);
   if( focus_wid!=0 && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
}

/**
 * Toggle toolbar/tool window by FormName. If the tool window
 * is part of a tabgroup, then the entire tabgroup is toggled.
 * 
 * @param FormName          Tool window to toggle on/off.
 * @param PutFocusOnCtlName (optional). Applies to toggling on tool window.
 *                          Focus is put on control once tool window
 *                          is activated.
 */
void _tbToggleTabGroupToolbar(_str FormName, _str PutFocusOnCtlName="")
{
   if( !_IsToolbarAllowed(FormName) ) {
      return;
   }

   int wid = _tbIsVisible(FormName);
   //say('_tbToggleTabGroupToolbar: wid='wid'  FormName='FormName);
   if( wid>0 ) {
      int tabgroup = _tbTabGroupFromWid(wid);
      if( tabgroup > 0 ) {
         _tbCloseTabGroup(tabgroup);
      } else {
         _tbToggleToolbar(FormName);
         //tbClose(wid);
      }

   } else {
      _TOOLBAR* ptb = _tbFind(FormName);
      if( ptb ) {

         // First check for auto hidden tool window
         wid = _tbMaybeAutoShow(FormName,PutFocusOnCtlName,true);
         if( wid == 0 ) {
            int tabgroup = ptb->restore_docked ? ptb->tabgroup : 0;
            if( tabgroup > 0 ) {
               _tbShowTabGroup(tabgroup,FormName);
            } else {
               _tbToggleToolbar(FormName);
               //tbShow(FormName);
            }
            wid = activate_toolbar(FormName,"");
         }
         if( wid > 0 && PutFocusOnCtlName != "" ) {
            int ctlwid = wid._find_control(PutFocusOnCtlName);
            if( ctlwid > 0 ) {
               ctlwid._set_focus();
            }
         }
      }
   }
}

/**
 * Toggle a single toolbar/tool window on/off. If the tool window
 * is showing, it is closed. If the tool window is not showing, it
 * is shown.
 * 
 * @param FormName Toolbar or tool window to toggle on/off.
 */
static int _tbToggleToolbar(_str FormName, ...)
{
   if( !_IsToolbarAllowed(FormName) ) {
      return 0;
   }

   int wid = _find_formobj(FormName,'n');
   if( wid==0 ) {
      tbShow(FormName);

   } else if( _tbIsAutoHiddenWid(wid) ) {
      // Auto show
      DockingArea area;
      int pic;
      _str caption;
      boolean active;
      if( dockchanFind(FormName,area,pic,caption,active) ) {
         _tbAutoShow(FormName,area);
      } else {
         // How did we get here?
         tbShow(FormName);
      }

   } else if( _tbIsAutoShownWid(wid) ) {
      // Auto hide
      _tbAutoHide(wid);

   } else {
      // Simple hide
      tbHide(FormName);
   }
   return 0;
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
   boolean FormName_hashtab:[];
   int i;
   for( i=0;i<def_toolbartab._length();++i ) {
      // IF we have multiple occurrences of the same toolbar
      if( 0!=FormName_hashtab._indexin(def_toolbartab[i].FormName) ) {
         def_toolbartab._deleteel(i);
         continue;
      }
      FormName_hashtab:[def_toolbartab[i].FormName]=true;
      if( !isinteger(def_toolbartab[i].restore_docked) ||
          !isinteger(def_toolbartab[i].tabgroup) ||
          !isinteger(def_toolbartab[i].auto_width) ) {
         //say('fixed it i='i);
         def_toolbartab[i].restore_docked=false;
         def_toolbartab[i].show_x=0;
         def_toolbartab[i].show_y=0;
         def_toolbartab[i].show_width=0;
         def_toolbartab[i].show_height=0;

         def_toolbartab[i].docked_area=0;
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
   }
   // Make sure all available toolbars are in the users
   // list of toolbars
   for( i=0;i<init_toolbartab._length();++i ) {

      if( 0==FormName_hashtab._indexin(init_toolbartab[i].FormName) ) {
         def_toolbartab[def_toolbartab._length()]=init_toolbartab[i];
      }
   }
}

void _tbSetToolbarEnable(int wid, CMDUI &cmdui=null)
{
   int orig_view_id = p_window_id;
   int target_wid;
   if( _no_child_windows() ) {
      target_wid=0;
   } else {
      target_wid=_mdi.p_child;
   }
   if( cmdui._isempty() ) {
      cmdui.menu_handle=0;
      cmdui.button_wid=1;
      _OnUpdateInit(cmdui,target_wid);
   }

   //say('found 'wid.p_name);
   int first_child, child;
   first_child=child=wid.p_child;
   if( child ) {
      for( ;; ) {
         if( child.p_object==OI_IMAGE &&
             (child.p_caption!="" ||child.p_picture) ) {
            cmdui.button_wid=child;
            //say('got here target_wid='target_wid);
            int mfflags=_OnUpdate(cmdui,target_wid,child.p_command);
            if( mfflags ) {
               boolean value=false;
               if( 0!=(mfflags & MF_GRAYED) ) {
                  // Disabled
                  value=false;
               } else {
                  // Enabled
                  value=true;
               }
               if( child.p_enabled!=value ) {
                  child.p_enabled=value;
                  //_tbSetRefreshBy(0);
                  //return;
               }
            }
         }
         child=child.p_next;
         if( child==first_child ) break;
      }
      // Update image controls
      //wid.refresh('w');
   }
   activate_window(orig_view_id);
}

void _tbOnUpdate(boolean alwaysUpdate=false)
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
   boolean hashtab:[];
   int i;
   for (i=0;i<def_toolbartab._length();++i) {
      if (def_toolbartab[i].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) {
         hashtab:[def_toolbartab[i].FormName]=true;
      }
   }
   CMDUI cmdui;
   cmdui.menu_handle=0;
   int target_wid=0;
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
}

void _switchbuf_toolbars()
{
#if __UNIX__
   // Sledge hammer. Panels do not get ON_LOST_FOCUS events when switching
   // to an edit window from a menu.
   _tbpanelUpdateAllPanels();
   int wid = _tbFindAutoShownWid();
   if( wid>0 ) {
      _tbMaybeAutoHideDelayed(def_toolbar_autohide_delay':'wid.p_active_form':'wid.p_active_form.p_name);
   }
#endif
}

boolean _isContainer(int wid)
{
   return (_tbpanelIsPanel(wid) || _bbgrabbarIsGrabbarForm(wid));
}

/**
 * Operates on the active window.
 */
int _containerFindActiveForm()
{
   if( _tbpanelIsPanel(p_window_id) ) {
      return (_tbpanelFindActiveForm());
   } else if( _bbgrabbarIsGrabbarForm(p_window_id) ) {
      return (_bbgrabbarChildForm());
   }
   // Not a container
   return 0;
}

/**
 * Acts on the active window which must be a container.
 * Valid containers: _tbpanel_form, _bbgrabbar_form.
 */
void _containerUpdate()
{
   if( _tbpanelIsPanel(p_window_id) ) {
      _tbpanelUpdate();
   } else if( _bbgrabbarIsGrabbarForm(p_window_id) ) {
      _bbgrabbarUpdate();
   }
}

/**
 * Sort the entries in gbbdockinfo for tabgroup by tabOrder. Reorder
 * SSTab tabgroup to match gbbdockinfo order.
 * 
 * @param tabgroup
 * @param startSide (optional). The side to start looking for this tabgroup.
 */
void _bbdockSortTabGroup(int tabgroup, int startSide=DOCKINGAREA_FIRST)
{
   DockingArea area, first_i, last_i;
   if( !_bbdockFindTabGroup(tabgroup,area,first_i,last_i,startSide) ) {
      return;
   }
   // The number of tabs in a tabgroup will be few, so this is
   // a simple selection-sort.
   int i;
   for( i=first_i; i<last_i; ++i ) {

      int swap = i;
      int j;
      for( j=i+1; j<=last_i; ++j ) {

         // Find the smallest .tabOrder value from j..last_i
         if( gbbdockinfo[area][j].tabOrder < gbbdockinfo[area][swap].tabOrder ) {
            swap=j;
         }
      }
      if( swap>i ) {
         // Swap
         BBDOCKINFO temp = gbbdockinfo[area][i];
         gbbdockinfo[area][i]=gbbdockinfo[area][swap];
         gbbdockinfo[area][swap]=temp;
      }
   }

   // Now sort the tabgroup window tabs.
   // A tabgroup with 1 tab will not have a tab control
   // and does not need to be sorted.
   if( last_i>first_i ) {

      int tabgroupWid = _bbdockTabGroupWid(&gbbdockinfo[area][first_i]);

      // Save the active tab so we can make it active again after sorting.
      // Note:
      // sstContainerByActiveOrder Uses p_ActiveOrder instead of p_ActiveTab because
      // we can query a SSTab tab container child's p_ActiveOrder property.
      // Also, you cannot always rely on p_ActiveOrder being equal to
      // p_ActiveTab, especially after using _create_window to create the
      // SSTab control and adding tabs to it.
      int activeTabContainerWid = tabgroupWid.sstContainerByActiveOrder(tabgroupWid.p_ActiveOrder);

      int ActiveOrder = 0;
      for( i=first_i; i<=last_i; ++i ) {
         int tabContainerWid = gbbdockinfo[area][i].wid.p_parent;
         // Sanity-check
         if( tabContainerWid==0 || tabContainerWid.p_object!=OI_SSTAB_CONTAINER ) {
            // Uh oh
            break;
         }
         tabContainerWid._makeActive();
         if( tabgroupWid.p_ActiveOrder!=ActiveOrder ) {
            tabgroupWid.p_ActiveOrder=ActiveOrder;
         }
         ++ActiveOrder;
      }

      if( activeTabContainerWid>0 ) {
         activeTabContainerWid._makeActive();
      }
   }
}

/**
 * Force the tab-linked tool windows in gbbdockinfo[][] to match the
 * actual order of the tabs in the SSTab tabgroup.
 */
void _bbdockSortTabGroupByActiveOrder(int tabgroup, int startSide=DOCKINGAREA_FIRST)
{
   DockingArea area, first_i, last_i;
   if( !_bbdockFindTabGroup(tabgroup,area,first_i,last_i,startSide) ) {
      return;
   }

   // A tabgroup with 1 tab will not have a tab control
   // and does not need to be sorted.
   if( last_i==first_i ) {
      return;
   }

   int tabgroupWid = _bbdockTabGroupWid(&gbbdockinfo[area][first_i]);
   if( tabgroupWid==0 ) {
      // Uh oh
      return;
   }

   // Array of tabOrder numbers to re-use when sorting.
   // We do this so that any saved tool windows in def_toolbartab
   // will not get redocked in a strange order because they have
   // old tabOrder numbers stored.
   int tabOrderArray[];
   int i;
   for( i=first_i; i<=last_i; ++i ) {
      tabOrderArray[tabOrderArray._length()]=gbbdockinfo[area][i].tabOrder;
   }
   tabOrderArray._sort('n');

   // Now re-assign tabOrder numbers to gbbdockinfo[][] entries
   // to match order of SSTab control tabs.
   int tabOrder = 0;
   int NofTabs = tabgroupWid.p_NofTabs;
   for( i=0; i<NofTabs; ++i ) {

      int formWid = tabgroupWid._tabgroupFindActiveForm(i);
      if( formWid==0 ) {
         // Uh oh
         continue;
      }
      int found_area, found_i, found_tabgroup, found_tabOrder;
      if( !_bbdockFindWid(formWid,found_area,found_i,found_tabgroup,found_tabOrder) ) {
         // Uh oh
         continue;
      }
      if( found_area!=area || found_i<first_i || found_i>last_i || found_tabgroup!=tabgroup ) {
         // Uh oh
         continue;
      }
      gbbdockinfo[found_area][found_i].tabOrder=tabOrderArray[tabOrder];
      ++tabOrder;
   }

   // Now sort gbbdockinfo[][] by new tabOrder values
   _bbdockSortTabGroup(tabgroup,area);
}

/**
 * Activate the tab in the tabgroup with the given tabOrder.
 * 
 * @param tabgroup
 * @param tabOrder 0 will always set the first tab active.
 * 
 * @return true if we found the tabOrder within the tabgroup; false otherwise.
 */
boolean _bbdockActivateTabGroupTabOrder(int tabgroup, int tabOrder)
{
   DockingArea area, first_i, last_i;
   if( !_bbdockFindTabGroup(tabgroup,area,first_i,last_i) ) {
      return false;
   }
   if( last_i==first_i ) {
      // Tabgroups with only 1 tool window do not have a SSTab control
      return true;
   }
   if( tabOrder==0 ) {
      // Set the first tab active
      int tabgroupWid = _bbdockTabGroupWid(&gbbdockinfo[area][first_i]);
      if( tabgroupWid>0 ) {
         tabgroupWid.p_ActiveTab=0;
      }
      return true;
   }
   int i;
   for( i=first_i; i<=last_i; ++i ) {
      int wid = gbbdockinfo[area][i].wid;
      if( wid>0 ) {
         if( gbbdockinfo[area][i].tabOrder==tabOrder ) {
            // Found it, now activate it
            int tabcontainerWid = _tbTabGroupContainerWidFromWid(wid);
            if( tabcontainerWid>0 ) {
               tabcontainerWid._makeActive();
               // _makeActive() does not cause ON_CHANGE to be called
               // with CHANGE_TABACTIVATED, so we must do it.
               int tabgroupWid = _bbdockTabGroupWid(&gbbdockinfo[area][i]);
               tabgroupWid.call_event(CHANGE_TABACTIVATED,tabgroupWid,ON_CHANGE,'W');
               return true;
            }
            break;
         }
      }
   }

   // Not found
   return false;
}

void _tbCloseTabGroup(int tabgroup, int startSide=DOCKINGAREA_FIRST,boolean docking=false)
{
   if( tabgroup<=0 ) {
      return;
   }

   // Elements are deleted from gbbdockinfo[][] as we remove them,
   // so we must always re-query for the tabgroup.
   DockingArea area, first_i, not_used;
   boolean found = _bbdockFindTabGroup(tabgroup,area,first_i,not_used,startSide);
   if( found ) {
      // No point in looking on the wrong side each time
      startSide=area;
      // Hide the SSTab control to reduce flashing
      int tabgroup_wid = _tbTabGroupWidFromWid(gbbdockinfo[area][first_i].wid);
      tabgroup_wid.p_visible=false;
   }
   while( found ) {
      _str FormName = gbbdockinfo[area][first_i].wid.p_name;
      _mdi._bbdockRespaceAndRemove(area,first_i,docking);
      if( _tbIsNoRefreshArea(area) ) {
         return;
      }
      found=_bbdockFindTabGroup(tabgroup,area,first_i,not_used,startSide);
   }
   _mdi._bbdockMaybeRemoveButtonBar(area,docking);
   _mdi._bbdockRefresh(area);
}

static void _tbShowTabGroup(int tabgroup, _str activeFormName="")
{
   if( tabgroup<=0 ) {
      return;
   }
   _tbNewVersion();
   int i;
   for( i=0; i<def_toolbartab._length(); ++i ) {

      if( def_toolbartab[i].tabgroup == tabgroup ) {
         _str FormName = def_toolbartab[i].FormName;
         int wid = _tbIsVisible(FormName);
         if( wid!=0 ) {
            // Already showing
            continue;
         }
         if( !_tbIsDockingAllowed(&def_toolbartab[i]) ) {
            // Docking not allowed on this tool window
            continue;
         }
         if( def_toolbartab[i].docked_area==0 ) {
            // Was not docked?
            continue;
         }
         // true=delay refreshing side
         _tbShowDocked(FormName,-1,true);
      }
   }
   DockingArea area, not_used;
   if( _bbdockFindTabGroup(tabgroup,area,not_used,not_used) ) {
      // Refresh now
      _mdi._bbdockRefresh(area);
   }
   if( activeFormName!="" ) {
      activate_toolbar(activeFormName,"");
   }
}

/**
 * Check whether mouse cursor is inside current tool window.
 * This includes any container (e.g. panel, grabbar form, etc.).
 * 
 * @param wid Window to test.
 * 
 * @return true if mouse cursor is inside tool window.
 */
boolean _tbMouInWindow(int wid)
{
   if( wid<=0 || !_iswindow_valid(wid) ) {
      return false;
   }

   // Last mouse coordinates in pixels relative to screen
   int mx, my;
   mou_get_xy(mx,my);

   // Check if mouse inside window
   //say('_tbMouInWindow: wid='wid'='wid.p_name);
   int container = _tbContainerFromWid(wid);
   //say('_tbMouInWindow: container='container'='container.p_name);
   int autopane_wid = _tbAutoPaneFromWid(container);
   //say('_tbMouInWindow: autopane_wid='autopane_wid);
   if( autopane_wid>0 ) {
      // Have to do this so mouse-over edge of autopane (including sizebar)
      // will not auto hide the tool window.
      container=autopane_wid;
   }
   //say('_tbMouInWindow: container.p_parent='container.p_parent);
   int width, height;
   width=_lx2dx(SM_TWIP,container.p_width);
   height=_ly2dy(SM_TWIP,container.p_height);
   int x1, y1, x2, y2;
   x1=_lx2dx(SM_TWIP,container.p_x);
   x2=x1+width;
   y1=_ly2dy(SM_TWIP,container.p_y);
   y2=y1+height;
   if( container.p_parent==0 ) {
      // Probably the autopane which is a child of the MDI frame
      _map_xy(_mdi,0,x1,y1);
      _map_xy(_mdi,0,x2,y2);
   } else {
      _map_xy(container,0,x1,y1);
      _map_xy(container,0,x2,y2);
   }
   //say('_tbMouInWindow: mx='mx'  x1='x1'  x2='x2);
   //say('_tbMouInWindow: my='my'  y1='y1'  y2='y2);
   if( mx>=x1 && mx<x2 &&
       my>=y1 && my<y2 ) {

      return true;
   }
   // Not inside window
   return false;
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
 * void _tbSaveState_&lt;ToolWindowFormName&gt;(typeless& state, boolean closing)
 * void _tbRestoreState_&lt;ToolWindowFormName&gt;(typeless& state, boolean opening)
 * </pre>
 * For example, callbacks registered for the References tool
 * window would be: _tbSaveState__tbtagrefs_form,
 * _tbRestoreState__tbtagrefs_form. When a save/restore callback
 * is called, the active window is always the wid of the
 * saved/restored tool window.
 * 
 * @param state   (out). Tool window defined state information.
 * @param closing true=Tool window is being closed (not docked,
 *                undocked, autohidden, or autoshown).
 */
void _tbSaveState(typeless& state, boolean closing)
{
   state._makeempty();
   _str formName = p_window_id.p_name;
   if( formName != "" ) {
      int index = find_index('_tbSaveState_':+formName,PROC_TYPE);
      if( index > 0 && index_callable(index) ) {
         call_index(state,closing,index);
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
 * If it is important for your tool window to distinguish between a
 * simple show operation (e.g. showing a tool window some time after
 * it has been closed) and an operation that would immediately recreate
 * the tool window after it had been destroyed (e.g. dock/undock,
 * autohide, autoshow), then your callback must act on the 'opening'
 * argument. For example, your tool window may not want to restore the
 * state of the tool window if the user is simply showing it, in which
 * case the callback would return immediately if opening==true. The
 * 'state' input argument is ignored when opening==true, since it
 * would be the callback's responsibility to restore any state
 * data from long-term storage/cache.
 * <p>
 * Tool windows can register a callback to save/restore state by
 * defining 2 global functions:
 * <pre>
 * void _tbSaveState_&lt;ToolWindowFormName&gt;(typeless& state, boolean closing)
 * void _tbRestoreState_&lt;ToolWindowFormName&gt;(typeless& state, boolean opening)
 * </pre> For example,
 * callbacks registered for the References tool window would be:
 * _tbSaveState__tbtagrefs_form,
 * _tbRestoreState__tbtagrefs_form. When a save/restore callback
 * is called, the active window is always the wid of the
 * saved/restored tool window.
 * 
 * @param state   (in). Tool window defined state information to
 *                restore.
 * @param opening true=Tool window is being simply opened (i.e. opened some
 *                time after having been closed).
 */
void _tbRestoreState(typeless& state, boolean opening)
{
   _str formName = p_window_id.p_name;
   if( formName != "" ) {
      int index = find_index('_tbRestoreState_':+formName,PROC_TYPE);
      if( index > 0 && index_callable(index) ) {
         call_index(state,opening,index);
      }
   }
}

boolean _tbIsAppActivated()
{
   return gAppActivated;
}

void _actapp_toolwindow(_str gettingFocus='')
{
   gAppActivated = ( gettingFocus != 0 );
}

//
// Debug
//

#if 0
_command void area,print_area()
{
   _str result = prompt(arg(1),"area","");
   if( !isinteger(result) || result<DOCKINGAREA_FIRST || result>DOCKINGAREA_LAST ) {
      _str msg="Invalid area value";
      message(msg);
      return;
   }
   _str sidenames[];
   sidenames[DOCKINGAREA_LEFT]="LEFT";
   sidenames[DOCKINGAREA_TOP]="TOP";
   sidenames[DOCKINGAREA_RIGHT]="RIGHT";
   sidenames[DOCKINGAREA_BOTTOM]="BOTTOM";

   DockingArea area = (int)result;
   say('area = 'sidenames[area]' ===========================================');

   int i;
   for( i=0; i<_bbdockPaletteLength(area); ++i ) {
      if( i>0 ) {
         say('-------------------------------------------------------------');
      }
      if( gbbdockinfo[area][i]._isempty() ) {
         // How did we get here?
         say('['i']=<empty> !!!');
         continue;
      }
      int wid, twspace, sizebarAfterWid, tbflags, docked_row, tabgroup, tabOrder;
      wid=gbbdockinfo[area][i].wid;
      _str wid_name = (wid==0) ? "" : wid.p_name;
      twspace=gbbdockinfo[area][i].twspace;
      sizebarAfterWid=gbbdockinfo[area][i].sizebarAfterWid;
      tbflags=gbbdockinfo[area][i].tbflags;
      docked_row=gbbdockinfo[area][i].docked_row;
      tabgroup=gbbdockinfo[area][i].tabgroup;
      tabOrder=gbbdockinfo[area][i].tabOrder;
      say('['i'].wid='wid' ('wid_name')');
      say('['i'].twspace='twspace);
      if( wid>0 ) {
         say('['i'].sizebarAfterWid='sizebarAfterWid);
         say('['i'].tbflags='tbflags);
      }
      say('['i'].docked_row='docked_row);
      if( wid>0 ) {
         say('['i'].tabgroup='tabgroup);
         say('['i'].tabOrder='tabOrder);
      }
   }

   say('=============================================================');
}
_command tbtest1()
{
   _tbpanelUpdateAllPanels();
}
_command tbtest2()
{
   int resource_index;
   _TOOLBAR* ptb;
   int wid;
   DockingArea area;
   _str FormName;
   int tabgroup, tabOrder;

   say('tbtest2: *****************************************************');

   FormName="tbform_sample2a";
   say('tbtest2: FormName='FormName);
   wid=_find_formobj(FormName,'N');
   //say('tbtest2: wid='wid);
   if( wid==0 ) {
      ptb=_tbFind(FormName);
      //say('tbtest2: ptb='ptb);
      if( ptb!=0 ) {
         area=DOCKINGAREA_RIGHT;
         resource_index=find_index(FormName,oi2type(OI_FORM));
         //say('tbtest2: resource_index='resource_index);
         tabgroup= -1;
         tabOrder= -1;
         int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0,tabgroup,tabOrder);
         //int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0);
         //say('tbtest2: tbwid='tbwid);
         _mdi._bbdockRefresh(area);
      }
   }
}
_command tbtest3()
{
   int resource_index;
   _TOOLBAR* ptb;
   int wid;
   DockingArea area;
   _str FormName;
   int tabgroup, tabOrder;

   say('tbtest3: *****************************************************');

   FormName="tbform_sample2b";
   say('tbtest3: FormName='FormName);
   wid=_find_formobj(FormName,'N');
   //say('tbtest3: wid='wid);
   if( wid==0 ) {
      ptb=_tbFind(FormName);
      //say('tbtest3: ptb='ptb);
      if( ptb!=0 ) {
         area=DOCKINGAREA_RIGHT;
         resource_index=find_index(FormName,oi2type(OI_FORM));
         //say('tbtest3: resource_index='resource_index);
         tabgroup= -1;
         tabOrder= -1;
         int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0,tabgroup,tabOrder);
         //int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0);
         //say('tbtest3: tbwid='tbwid);
         _mdi._bbdockRefresh(area);
      }
   }
}
_command tbtest4()
{
   int resource_index;
   _TOOLBAR* ptb;
   int wid;
   DockingArea area;
   _str FormName;
   int tabgroup, tabOrder;

   say('tbtest4: *****************************************************');

   FormName="tbform_sample1";
   say('tbtest4: FormName='FormName);
   wid=_find_formobj(FormName,'N');
   //say('tbtest4: wid='wid);
   if( wid==0 ) {
      ptb=_tbFind(FormName);
      //say('tbtest4: ptb='ptb);
      if( ptb!=0 ) {
         area=DOCKINGAREA_RIGHT;
         resource_index=find_index(FormName,oi2type(OI_FORM));
         //say('tbtest4: resource_index='resource_index);
         tabgroup= -1;
         tabOrder= -1;
         int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0,tabgroup,tabOrder);
         //int tbwid = _mdi._bbdockInsert(area,-1,false,true,resource_index,ptb->tbflags,0);
         //say('tbtest4: tbwid='tbwid);
         _mdi._bbdockRefresh(area);
      }
   }
}
_command tbtest5()
{
   tbtest2();
   tbtest3();
   tbtest4();
}
_command tbtest6()
{
   _mdi._bbdockRefresh(DOCKINGAREA_BOTTOM);
}
#endif
