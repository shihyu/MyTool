////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44235 $
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
#include "dockchannel.sh"
#import "tbautohide.e"
#import "tbpanel.e"
#import "toolbar.e"
#import "dockchannel.e"
#endregion

/*
 * Tool window dock channel support.
 */


/**
 * Used to keep track of when we are resizing the MDI frame. In that
 * case we do not want to auto hide and auto shown tool window.
 */
static boolean gtbDockChanInResize = false;
/**
 * Used by _tbDockChanMouseInCallback() to know when we are already in
 * a call to _tbDockChanMouseInCallback() so we do not recurse.
 */
static boolean in_tbDockChanMouseInCallback = false;

definit()
{
   if( arg(1)!='L' ) {
      gtbDockChanInResize=false;
      in_tbDockChanMouseInCallback=false;
   }
}

static void _tbShowDockChanGroupCallback(DockingArea area,_str sid, int pic, _str caption, boolean active, typeless extra)
{
   dockchanRemove(sid);
   int wid = _tbIsVisible(sid);
   if( wid>0 ) {
      // How did we get here?
      return;
   }
   // true=delay refresh of side
   _tbShowDocked(sid,-1,true);
}

void _tbDockChanShowGroup(_str FormName)
{
   DockingArea area;
   int pic;
   _str caption;
   boolean active;
   if( !dockchanFind(FormName,area,pic,caption,active) ) {
      return;
   }
   dockchanEnumerateGroup(FormName,_tbShowDockChanGroupCallback);
   _mdi._bbdockRefresh(area);
   activate_toolbar(FormName,"");
}

static void _tbDockChanHideCallback(DockingArea area,_str sid, int pic, _str caption, boolean active, typeless skipFormName)
{
   if( sid==skipFormName) {
      // Skip this form.
      // Probably because we are trying to hide everything but this form.
      return;
   }
   int wid = _tbIsVisible(sid);
   if( wid==0 || !_tbIsAutoShownWid(wid) ) {
      // Not a valid window to operate on
      return;
   }
   _tbAutoHide(wid);
}

void _tbDockChanHideSide(DockingArea area=DOCKINGAREA_UNSPEC, _str skipFormName="")
{
   DockingArea first_area = area;
   DockingArea last_area = area;
   if( first_area == DOCKINGAREA_UNSPEC ) {
      first_area = DOCKINGAREA_FIRST;
   }
   if( last_area == DOCKINGAREA_UNSPEC ) {
      last_area = DOCKINGAREA_LAST;
   }
   int area_i = (int)area;
   for( area_i =first_area; area_i <= last_area; ++area_i ) {
      dockchanEnumerate(area_i,_tbDockChanHideCallback,false,skipFormName);
   }
}

boolean _tbDockChanMouseInCallback(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean clicked)
{
   //say('_tbDockChanMouseInCallback: in_tbDockChanMouseInCallback='in_tbDockChanMouseInCallback);
   if( in_tbDockChanMouseInCallback ) {
      return active;
   }
   in_tbDockChanMouseInCallback=true;

   boolean new_active = active;

   int wid = 0;

   do {

      if( !_AppHasFocus() ) {
         break;
      }

      // Clear the delay timer that keeps track of when our mouse leaves a tool window
      _tbMaybeAutoHideDelayed(0);

      wid = _find_formobj(sid,'n');
      int container = _tbContainerFromWid(wid);

      //say('_tbDockChanMouseInCallback: sid='sid'  wid='wid);
      //say('_tbDockChanMouseInCallback: _tbIsAutoShownWid='_tbIsAutoShownWid(wid));
      if( _tbIsAutoShownWid(wid) ) {
         // Already showing.
         if( 0!=(def_dock_channel_options & DOCKCHANNEL_OPT_NO_MOUSEOVER) ) {
            // Hovering does not auto show, so allow click to hide it if
            // already showing.
            _tbAutoHide(wid);
         } else {
            // Give focus if clicked.
            if( clicked && !container._tbpanelHasFocus() ) {
               // Set focus to embedded form if focus is not already somewhere in the form
               int focus_wid = _get_focus();
               if( focus_wid.p_active_form!=wid ) {
                  wid._set_focus();
               }
               container._tbpanelUpdate(-1);
            }
            // We killed the timer above, so restart it for this window.
            //say('_tbDockChanMouseInCallback: restarting timer for wid.p_name='wid.p_name);
            _tbMaybeAutoHideDelayed(def_toolbar_autohide_delay':'wid':'wid.p_name);
         }
         break;
      }

      // Tool window forms can be disabled, but we do not want to confuse
      // that with a modal dialog being up. Instead, check the p_enabled
      // property of the container which will be disabled if there is a
      // modal dialog up.
      // Note:
      // p_modal property does not seem to work for forms shown under _mdi.
      if( container>0 && !container.p_enabled ) {
         // Do not dare do anything while a modal dialog is up.
         // Return current state, no change.
         break;
      }

      boolean setFocus = clicked;
      if( wid>0 && !_tbIsAutoHiddenWid(wid) ) {
         container = _tbContainerFromWid(wid);
         if(  !clicked && _tbpanelIsPanel(container) && container._tbpanelHasFocus() /*&& container._tbpanelIsSelected()*/ ) {
            // Panel already has focus, so do not take it away
            setFocus=true;
         }
      }
      boolean followsMouseOut = false;
      if( _tbFindAutoShownWid() > 0 ) {
         // There was an auto shown wid already up, so
         // we are just moving out of one a dock channel
         // item into another. Do immediate show.
         followsMouseOut=true;
      }
      //say('_tbDockChanMouseInCallback: setFocus='setFocus);
      _tbDockChanHideSide(-1,sid);
      wid=_tbAutoShow(sid,area,setFocus);
      if( wid>0 ) {
         // Make it active
         new_active=true;
         break;
      }

      // Make it inactive
      new_active=false;

   } while( false );

   in_tbDockChanMouseInCallback=false;

   return new_active;
}

boolean _tbDockChanMouseOutCallback(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean precedesMouseIn)
{
   //say('_tbDockChanMouseOutCallback: sid='sid);
   if( !_AppHasFocus() ) {
      return active;
   }
   //say('_tbDockChanMouseOutCallback: ***********************************************');
   int wid = _tbIsVisible(sid);
   //say('_tbDockChanMouseOutCallback: wid='wid);
   if( wid==0 ) {
      // Is not showing or is auto hidden already
      return active;
   }

   // Tool window forms can be disabled, but we do not want to confuse
   // that with a modal dialog being up. Instead, check the p_enabled
   // property of the container which will be disabled if there is a
   // modal dialog up.
   // Note:
   // p_modal property does not seem to work for forms shown under _mdi.
   int container = _tbContainerFromWid(wid);
   if( !container.p_enabled ) {
      // Do not dare do anything while a modal dialog is up.
      // Return current state, no change.
      return active;
   }
   //say('_tbDockChanMouseOutCallback: gtbDockChanInResize='gtbDockChanInResize);
   if( gtbDockChanInResize ) {
      // Do not auto hide an auto shown tool window just because the user
      // resizes the MDI frame.
      return active;
   }
   // Sanity
   if( wid.p_DockingArea!=0 ) {
      // Auto shown tool windows should never have a side
      return false;
   }

   // Note:
   // We do not call tbClose() because we are re-autohiding, not closing,
   // the tool window. Closing the tool window would remove it from the
   // dock channel.
   boolean didAutoHide;
   //say('_tbDockChanMouseOutCallback: precedesMouseIn='precedesMouseIn);
   if( precedesMouseIn ) {
      // We are entering another item in the docking channel, so hide it immediately

      // Kill the auto hide timer
      _tbMaybeAutoHideDelayed("0");
      _tbAutoHide(wid);
      didAutoHide=true;
   } else {
      didAutoHide=_tbMaybeAutoHide(wid);
   }
   //say('_tbDockChanMouseOutCallback: didAutoHide='didAutoHide);
   //if( !didAutoHide ) {
   //   // _tbMaybeAutoHide uses it's own timer to wait for user to leave tool window,
   //   // so kill the dock channel timer for efficiency.
   //   dockchanKillMouseEvents();
   //}
   // Return whatever active state was passed to us. We want the user to
   // see the last item that the mouse was over.
   return active;
}

/**
 * Call-list callback that is called when a dock channel is moved/resized.
 */
void _dockchan_resize_toolbars()
{
   gtbDockChanInResize=true;

   // Do not allow auto shown windows to stay up while resizing MDI
   int wid = _tbFindAutoShownWid();
   if( wid==0 ) {
      // Nothing to do
      gtbDockChanInResize=false;
      return;
   }
   _tbAutoHide(wid);

   gtbDockChanInResize=false;
}
