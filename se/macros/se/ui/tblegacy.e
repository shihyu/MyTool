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
#import "toolbar.e"
#import "qtoolbar.e"
#import "tbview.e"
#import "stdprocs.e"
#endregion

#ifdef not_finished
// View containing full screen layout auto-restore information
static int _tbfullscreen_layout_view_id;
// View containing standard toolbar auto-restore information
static int _tbstandard_layout_view_id;
// View containing full screen debug toolbar auto-restore information
static int _tbfullscreen_debug_layout_view_id;
// View containing debug toolbar auto-restore information
static int _tbdebug_layout_view_id;
// View containing full screen slick-c debug toolbar auto-restore information
static int _tbfullscreen_slickc_debug_layout_view_id;
// View containing slick-c debug toolbar auto-restore information
static int _tbslickc_debug_layout_view_id;

definit()
{
   // Indicated that we don't have a view containing 
   // standard toolbar auto-restore information
   _tbstandard_layout_view_id = 0;
   int window_group_view_id;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   int status = find_view('._tbstandard_layout');
   if ( status == 0 ) {
      get_window_id(_tbstandard_layout_view_id);
   }

   // Indicated that we don't have a view containing 
   // debug toolbar auto-restore information
   _tbdebug_layout_view_id = 0;
   status = find_view('._tbdebug_layout');
   if ( status == 0 ) {
      get_window_id(_tbdebug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we don't have a view containing 
   // slickc debug toolbar auto-restore information
   _tbslickc_debug_layout_view_id=0;
   status = find_view('._tbslickc_debug_layout');
   if ( status == 0 ) {
      get_window_id(_tbslickc_debug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we don't have a view containing 
   // full screen toolbar auto-restore information
   _tbfullscreen_layout_view_id = 0;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   status = find_view('._tbfullscreen_layout');
   if ( status == 0 ) {
      get_window_id(_tbfullscreen_layout_view_id);
   }

   // Indicated that we don't have a view containing
   // full screen debug toolbar auto-restore information
   _tbfullscreen_debug_layout_view_id = 0;
   status = find_view('._tbfullscreen_debug_layout');
   if ( status == 0 ) {
      get_window_id(_tbfullscreen_debug_layout_view_id);
   }

   // Indicated that we don't have a view containing
   // full screen slickc debug toolbar auto-restore information
   _tbfullscreen_slickc_debug_layout_view_id = 0;
   status = find_view('._tbfullscreen_slickc_debug_layout');
   if ( status == 0 ) {
      get_window_id(_tbfullscreen_slickc_debug_layout_view_id);
   }
}
#endif

static int autorestore_toolbars(_str option, _str info='', _str restoreName='')
{
   _tbNewVersion();
   option = lowcase(option);

   focus_wid := 0;
   line := "";
   typeless Noftoolbars;
   typeless bbdockNoflines;
   typeless tbrestoreNoflines;
   typeless dockchanNoflines;
   typeless qtoolbarNoflines;
   typeless MaximizeWindow;
   typeless fullscreen_mode;
   typeless docked_row;
   typeless tabgroup;
   typeless tabOrder;
   typeless auto_width;
   typeless auto_height;
   typeless width, height;
   typeless area;
   typeless i;
   typeless FormNameOrIntInfo;
   typeless twspace;
   typeless tbflags;
   typeless activeTab;

   if ( option == 'r' || option == 'n' ) {

      parse info with . version Noftoolbars bbdockNoflines tbrestoreNoflines dockchanNoflines MaximizeWindow fullscreen_mode qtoolbarNoflines;

      if ( restoreName == 'TOOLBARS5' && fullscreen_mode != '' ) {
         _tbFullScreenSetMode(fullscreen_mode != 0);
      }
      
      focus_wid = _get_focus();

      // Skip floating tool-windows
      if ( !isinteger(Noftoolbars) || (int)Noftoolbars < 0 ) {
         return 1;
      }
      down((int)Noftoolbars);

      // Skip tool-window restore info
      if ( !isinteger(tbrestoreNoflines) || (int)tbrestoreNoflines < 0 ) {
         return 1;
      }
      down((int)tbrestoreNoflines);

      // Docked tool-windows
      // pre-v16 docked toolbars are mixed in with tool-winodws, so have to tease them out
      _str pre16Toolbars[];
      while ( bbdockNoflines-- ) {
         down();
         get_line(line);
         parse line with area i FormNameOrIntInfo twspace tbflags width height docked_row tabgroup tabOrder activeTab auto_width auto_height .;

         // (16.1.0) Check for old toolbars
         if ( version == '1' ) {
            _TOOLBAR* ptb = _tbFind(FormNameOrIntInfo);
            if ( ptb ) {
               if ( 0 == (ptb->tbflags & TBFLAG_SIZEBARS) ) {
                  pre16Toolbars[pre16Toolbars._length()] = FormNameOrIntInfo;
               }
            }
         }
      }

      // Skip dock-channel
      if ( !isinteger(dockchanNoflines) || dockchanNoflines < 0 ) {
         return 1;
      }
      down(dockchanNoflines);

      // restoring from old version
      if ( version == '1' ) {
         // (16.1.0) restore old toolbar as new toolbar
         if ( pre16Toolbars._length() > 0 ) {
            n := pre16Toolbars._length();
            for ( i = 0; i < n; ++i ) {
               name := pre16Toolbars[i];
               if (_isMac()) {
                  if ( restoreName == 'TOOLBARS5' ) {
                     if ( name == '_tbstandard_form' ) {
                        // replace standard toolbar here
                        name = '_tbunified_form';
                     }
                     if ( name == '_tbcontext_form' ) {
                        // combined in unified toolbar
                        continue;
                     }
                  }
               }
               _tbLoadQToolbarName(name);
            }

         }
      }

      // (16.1.0) new toolbar restore method
      if ( qtoolbarNoflines != '' && isinteger(qtoolbarNoflines) ) {
         autorestore_qtoolbars(option, qtoolbarNoflines);
      }

      if( focus_wid != 0 ) {
         focus_wid._set_focus();
      }

   } else {

      // Legacy support does not need to save

   }

   return 0;
}

/**
* Legacy support for restoring pre-v19 toolbars (not 
* tool-windows). 
* 
* @param option 
* @param info 
* 
* @return int 
*/
int _srg_toolbars5(_str option='', _str info='')
{
   option = lowcase(option);
   if ( option == 'r' || option == 'n' ) {
      autorestore_toolbars(option, info, 'TOOLBARS5');
   } else {
      // Legacy support does not need to save
   }
   return 0;
}

#ifdef not_finished
static int autorestore_toolbar_layout(_str view_name, int& view_id, bool isCurrentToolbarLayout,
                                      _str option='', _str info='')
{
   option = lowcase(option);
   if ( option == 'r' || option == 'n' ) {
      typeless Noflines;
      parse info with Noflines .;
      // Copy the toolbar settings from our view if there is one
      _copy_into_view(view_name, view_id, Noflines + 1, false);
      down(Noflines);
   } else {

      // Legacy support does not need to save

   }
   return 0;
}

int _srg_fullscreen_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_layout',
                                      _tbfullscreen_layout_view_id,
                                      !_tbDebugQMode() && _tbFullScreenQMode(),
                                      option, info));
}


int _srg_standard_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbstandard_layout', _tbstandard_layout_view_id,
                                      !_tbDebugQMode() && !_tbFullScreenQMode(),
                                      option, info));
}

int _srg_debug_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbdebug_layout', _tbdebug_layout_view_id,
                                      _tbDebugQMode() && !_tbFullScreenQMode() && !_tbDebugQSlickCMode(),
                                      option, info));
}

int _srg_fullscreen_debug_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_debug_layout',
                                      _tbfullscreen_debug_layout_view_id,
                                      _tbDebugQMode() && _tbFullScreenQMode() && !_tbDebugQSlickCMode(),
                                      option, info));
}

int _srg_slickc_debug_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbslickc_debug_layout', _tbslickc_debug_layout_view_id,
                                      _tbDebugQMode() && !_tbFullScreenQMode() && _tbDebugQSlickCMode(),
                                      option, info));
}

int _srg_fullscreen_slickc_debug_toolbars(_str option='', _str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_slickc_debug_layout',
                                      _tbfullscreen_slickc_debug_layout_view_id,
                                      _tbDebugQMode() && _tbFullScreenQMode() && _tbDebugQSlickCMode(),
                                      option, info));
}
#endif
