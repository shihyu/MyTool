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
#import "eclipse.e"
#import "files.e"
#import "listbox.e"
#import "qtoolbar.e"
#import "stdprocs.e"
#import "toolbar.e"
#import "dockchannel.e"
#import "se/ui/mainwindow.e"
#endregion

_TOOLBAR def_toolbartab[];
// Indicates whether the current toolbars settings are for the debug toolbars
bool _tbdebug_mode;
// Indicates whether the current toolbars settings are for the slick-c debug toolbars
bool _tbslickc_debug_mode;
// Indicates whether we are using the full screen toolbars
bool _tbfullscreen_mode;

definit()
{
   if ( arg(1) != 'L' ) {
      // Editor initialization case

      // Indicate we are not in debug mode
      _tbDebugSetMode(false);

      // Indicate we are not in full screen mode.
      _tbFullScreenSetMode(false);
   }
}

int _srg_fullscreen_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}


int _srg_standard_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}

int _srg_debug_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}

int _srg_fullscreen_debug_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}

int _srg_slickc_debug_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}

int _srg_fullscreen_slickc_debug_toolbars(_str option='', _str info='')
{
#ifdef not_finished
   // TODO: Support autorestoring old restore info
#endif
   return 0;
}

/**
 * Restores the MDI window to its size before being iconized.
 * 
 * @categories Window_Functions
 * 
 */ 
_command void restore_mdi() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   if ( _tbFullScreenQMode() ) {
      return;
   }
   _mdi.p_window_state = 'N';
}

bool _tbFullScreenQMode()
{
   return _tbfullscreen_mode;
}

void _tbFullScreenSetMode(bool onoff)
{
   _tbfullscreen_mode = onoff;
}

bool _tbDebugQMode()
{
   if (!_haveDebugging()) return false;
   return _tbdebug_mode;
}

bool _tbDebugQSlickCMode()
{
   if (!_haveDebugging()) return false;
   return _tbslickc_debug_mode;
}

void _tbDebugSetMode(bool onoff, bool slickc=false)
{
   _tbdebug_mode = onoff;
   _tbslickc_debug_mode = slickc;
}

/**
 * Legacy.
 */
void tbDebugSwitchMode(bool onoff, bool slickc=false)
{
   debug_switch_mode(onoff, slickc);
}
