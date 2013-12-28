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
#import "dlgman.e"
#import "picture.e"
#import "stdprocs.e"
#import "dockchannel.e"
#import "tbdockchannel.e"
#import "tbpanel.e"
#import "toolbar.e"
#require "sc/controls/RubberBand.e"
#require "se/util/MousePointerGuard.e"
#endregion

_TOOLBAR def_toolbartab[];

#define AUTOPANE_FORMNAME "_autopane_form"

static int _gMaybeAutoHideTimerHandle = -2;

definit()
{
   if( arg(1)!='L' ) {
      _gMaybeAutoHideTimerHandle= -2;
   }
}

/**
 * Delay auto hiding the tool window (wid) for duration milliseconds.
 */
void _tbMaybeAutoHideDelayed(_str duration_wid_FormName)
{
   //say('_tbMaybeAutoHideDelayed: in');
   if( _gMaybeAutoHideTimerHandle>=0 ) {
      _kill_timer(_gMaybeAutoHideTimerHandle);
      _gMaybeAutoHideTimerHandle= -2;
   }
   if( duration_wid_FormName == "0" ) {
      // Special case of killing the timer early
      return;
   }
   _str duration_str, wid, FormName;
   parse duration_wid_FormName with duration_str':'wid':'FormName;
   //say('_tbMaybeAutoHideDelayed: duration='duration_str'  wid='wid'  FormName='FormName);
   //say('_tbMaybeAutoHideDelayed: _iswindow_valid='_iswindow_valid((int)wid));
   //say('_tbMaybeAutoHideDelayed: wid.p_name='_iswindow_valid((int)wid)?wid.p_name:"");
   if( !isinteger(duration_str) ||
       !isinteger(wid) || wid<=0 || !_iswindow_valid((int)wid) ||
       wid.p_name!=FormName ) {

      // How did we get here?
      // One way: Window handles are reused A LOT, so the window we are
      // concerned with could have been destroyed, and another created with
      // the same handle. That is why we check FormName.
      return;
   }
   int duration = (int)duration_str;
   if( duration>0 ) {
      // 0.1 seconds between hits
      duration -= 100;
      _gMaybeAutoHideTimerHandle=_set_timer(TBAUTOHIDE_TIMER_INTERVAL,_tbMaybeAutoHideDelayed, duration':'wid':'FormName);
      return;
   }
   // Time to do something
   _tbMaybeAutoHide((int)wid);
}

int _tbAutoPaneFromWid(int wid)
{
   int autopane_wid = _autopaneGetAutoPane();
   if( autopane_wid>0 && autopane_wid._autopaneIsAutoPaneChild(wid) ) {
      return autopane_wid;
   }
   // wid is not in autopane
   return 0;
}

boolean _tbMaybeAutoHide(int wid, boolean hideEvenIfMouseInWindow=false)
{
   if( _tbIsAutoShownWid(wid) ) {

      boolean delayAutoHide = false;

      int container = _tbContainerFromWid(wid);
      int parent_wid = _tbAutoPaneFromWid(wid);
      if( parent_wid==0 ) {
         // Try the container
         parent_wid=container;
      }
      if( !container.p_enabled ) {
         // Do not dare do anything while a modal dialog is up.
         // Return current state, no change.
         // Explanation:
         // Tool window forms can be disabled, but we do not want to confuse
         // that with a modal dialog being up. Instead, check the p_enabled
         // property of the container which will be disabled if there is a
         // modal dialog up.
         // Note:
         // p_modal property does not seem to work for forms shown under _mdi.
         delayAutoHide=true;

      } else if( !_AppHasFocus() ) {
         // We do not want auto shown windows going away just because focus
         // switches away from the app.
         delayAutoHide=true;

      } else if( !hideEvenIfMouseInWindow && _tbMouInWindow(parent_wid) ) {
         // If we got here, then we are still in the tool window panel,
         // so do not re-autohide the window.
         delayAutoHide=true;

      } else if( _tbpanelIsPanel(container) && container._tbpanelHasFocus() /*&& container._tbpanelIsSelected()*/ ) {
         // If we got here, then the panel has focus, so do not dismiss it
         delayAutoHide=true;

      } else if( !hideEvenIfMouseInWindow && dockchanMouInItem(wid.p_name) ) {
         // If we got here, then the mouse is still inside the dock channel item for this
         // tool window, so do not dismiss it.
         delayAutoHide=true;

      } else {
         // Look for a callback to tell us whether we can auto hide yet
         int index = find_index("_autohide_wait_"wid.p_name,PROC_TYPE);
         if( index>0 && index_callable(index) ) {
            int status = call_index(index);
            //say('_tbMaybeAutoHide: callback for 'wid.p_name' returned 'status);
            if( status!=0 ) {
               // If we got here, then the callback wants us to continue waiting (probably busy doing something).
               //say('_tbMaybeAutoHide: NOT NOT NOT BUSY');
               delayAutoHide=true;
            }
         }
      }
      if( delayAutoHide ) {
         // Wait for another ~2 seconds
         _tbMaybeAutoHideDelayed(def_toolbar_autohide_delay':'wid':'wid.p_name);
         return false;
      }
      // Kill the auto hide timer
      _tbMaybeAutoHideDelayed("0");
      _tbAutoHide(wid);
      return true;
   }
   // Kill the auto hide timer
   _tbMaybeAutoHideDelayed("0");
   return false;
}

int _tbMaybeAutoShow(_str FormName, _str PutFocusOnCtlName="", boolean killDockChanMouseEvents=false)
{
   int wid = 0;

   DockingArea area;
   int pic;
   _str caption;
   boolean active;
   if( dockchanFind(FormName,area,pic,caption,active) ) {
      // Hide every thing else
      //_tbDockChanHideSide(-1,FormName);
      if( !active ) {
         dockchanSetActive(FormName);
      }
      if( killDockChanMouseEvents ) {
         // We do not want the dock channel telling us the mouse has
         // left the tool window. This can happen when:
         // 1. You hovered the mouse cursor over the tool window you are toggling, AND
         // 2. Your mouse leaves (or is already outside) the tool window area.
         dockchanKillMouseEvents();
      }
      // Remove all other auto shown tool windows
      _tbDockChanHideSide(-1,FormName);
      wid=_tbAutoShow(FormName,area,(PutFocusOnCtlName!=""));
   }
   if( wid>0 && PutFocusOnCtlName!="" ) {
      int ctlwid = wid._find_control(PutFocusOnCtlName);
      if( ctlwid>0 ) {
         ctlwid._set_focus();
      }
   }
   return wid;
}

/**
 * @return Auto shown window. 0 if there are no auto shown windows.
 */
int _tbFindAutoShownWid()
{
   int autopane_wid = _autopaneGetAutoPane();
   if( autopane_wid==0 || !autopane_wid.p_visible ) {
      return 0;
   }

   int wid = autopane_wid._autopaneFindVisibleForm();
   return wid;
}

boolean _tbIsAutoShownWid(int wid)
{
   if( wid<=0 ) {
      return false;
   }
   int autopane_wid = _autopaneGetAutoPane();
   if( autopane_wid==0 || !autopane_wid.p_visible ) {
      return false;
   }
   // Find the panel container
   if( !_tbpanelIsPanel(wid) ) {
      wid=_tbContainerFromWid(wid);
      if( !_tbpanelIsPanel(wid) ) {
         return false;
      }
   }
   if( wid.p_DockingArea==0 && wid.p_parent==autopane_wid && wid==autopane_wid._autopaneFindVisibleForm() ) {
      return true;
   }
   return false;
}

int _tbIsAutoShown(_str FormName)
{
   int wid = _find_formobj(FormName,'n');
   if( _tbIsAutoShownWid(wid) ) {
      return wid;
   }
   // Not auto shown
   return 0;
}

boolean _tbIsAutoHiddenWid(int wid)
{
   if( wid<=0 || !_iswindow_valid(wid) ) {
      return false;
   }
   int autopane_wid = _autopaneGetAutoPane();
   if( autopane_wid==0 ) {
      return false;
   }
   if( autopane_wid._autopaneIsAutoPaneChild(wid) && (!autopane_wid.p_visible || !wid.p_visible) ) {
      // Inside a hidden autopane OR is hidden inside a visible autopane (because the autopane
      // is showing another window right now), so it is auto hidden.
      return true;
   }
   return false;
}

int _tbIsAutoHidden(_str FormName)
{
   int wid = _find_formobj(FormName,'n');
   if( _tbIsAutoHiddenWid(wid) ) {
      return wid;
   }
   // Not auto hidden
   return 0;
}

/**
 * @param wid
 * 
 * Return true if wid is an auto shown or auto hidden window.
 */
boolean _tbIsAutoWid(int wid)
{
   if( wid<=0 || !_iswindow_valid(wid) ) {
      return false;
   }
   int autopane_wid = _autopaneGetAutoPane();
   if( autopane_wid==0 ) {
      return false;
   }
   if( autopane_wid._autopaneIsAutoPaneChild(wid) ) {
      // Inside a autopane, so it is auto shown or hidden
      return true;
   }
   return false;
}

/**
 * @param FormName
 * @param inDockChannel Check if form is in the dock channel, but
 *                      not yet instantiated.  This is useful when
 *                      you want to know if a form WOULD HAVE
 *                      beeen autoshown, but has not been
 *                      autoshown yet.
 * 
 * @return wid>0 if FormName is an auto shown or auto hidden window.
 * Otherwise return 0. Returns -1 if inDockChannel==true and the
 * form has not been created, but WOULD have been autoshown.
 */
int _tbIsAuto(_str FormName, boolean inDockChannel=false)
{
   int wid = _find_formobj(FormName,'n');
   if( _tbIsAutoWid(wid) ) {
      return wid;
   }
   if (inDockChannel) {
      DockingArea area;
      int pic;
      _str caption;
      boolean active;
      if (dockchanFind(FormName,area,pic,caption,active)) {
         return -1;
      }
   }
   // Not an auto hide/show form, but might be in dock channel (just not shown yet)
   return 0;
}

/**
 * @return true if Auto Hide feature is available for this tool window.
 * If ptb==0, then the global setting is returned.
 */
boolean _tbIsAutoHideAllowed(_TOOLBAR* ptb=null)
{
   boolean autoHideAllowed = false;
   if( !isEclipsePlugin() && 0==(def_toolbar_options & TBOPTION_NO_AUTOHIDE) ) {
      // Auto Hide allowed globally
      autoHideAllowed=true;
      if( autoHideAllowed && ptb ) {
         autoHideAllowed= (
                           0==( ptb->tbflags & TBFLAG_NO_AUTOHIDE ) &&
                           0!=( ptb->tbflags & TBFLAG_SIZEBARS ) &&
                           0==( ptb->tbflags & TBFLAG_NO_CAPTION )
                          );
      }
   }
   return autoHideAllowed;
}


// "Auto Hide" menu item on _toolbar_menu
int _OnUpdate_tbAutoHideToggle(CMDUI &cmdui,int target_wid,_str command)
{
   int formwid = target_wid.p_active_form;
   if( _tbIsAutoShownWid(formwid) ) {
      return (MF_ENABLED|MF_CHECKED);
   } else {
      _TOOLBAR* ptb = _tbFind(formwid.p_name);
      if( !ptb || !_tbIsAutoHideAllowed(ptb) || formwid.p_DockingArea==0 ) {
         return (MF_GRAYED|MF_UNCHECKED);
      } else {
         return (MF_ENABLED|MF_UNCHECKED);
      }
   }
}

/**
 * Toggle Auto Hide/Show tool window.
 * 
 * @param wid (optional). Window id of tool window. Uses the active form
 *            if not specified.
 */
_command void tbAutoHideToggle(int wid=0)
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
   }
   if( wid==0 ) {
      // Not a valid object on which to operate
      return;
   }
   boolean wasAutoShown = _tbIsAutoShownWid(wid);
   _str FormName = wid.p_name;
   DockingArea area = wid.p_DockingArea;
   if( wasAutoShown ) {

      typeless state = null;
      wid._tbSaveState(state,false);

      _tbAutoHide(wid);

      tbShow(FormName);
      wid=_tbIsVisible(FormName);

      wid._tbRestoreState(state,false);

   } else {

      typeless state = null;
      wid._tbSaveState(state,false);

      _tbAutoHide(wid);
      // Auto show, then auto hide in order to give user visual feedback
      wid = _tbAutoShow(FormName,area,false);
      if( wid>0 ) {
         wid._tbRestoreState(state,false);
         _tbAutoHide(wid);
      }
   }
}

void _tbAutoHide(int wid)
{
   int focus_wid = 0;

   if( _tbIsAutoShownWid(wid) ) {

      // Auto hiding a window should put focus back
      focus_wid = _get_focus();

      int container;
      if( _isContainer(wid) ) {
         // We have a container, so find the active form
         container=wid;
         wid=wid._containerFindActiveForm();
      } else {
         container=_tbContainerFromWid(wid);
      }
      _str FormName = wid.p_name;
      int autopane_wid = _autopaneGetAutoPane();
      DockingArea area = autopane_wid._autopaneGetArea();

      // Save the last auto shown width, height so can restore next time
      // window is auto shown.
      _TOOLBAR* ptb = _tbFind(FormName);
      if( ptb ) {
         //say('_tbAutoHide: area='area);
         switch( area ) {
         case DOCKINGAREA_LEFT:
         case DOCKINGAREA_RIGHT:
            // Only save the width.
            // IMPORTANT:
            // Use the autopane width, NOT the container width since the
            // container is adjusted to accomodate the sizebar in the autopane.
            int width;
            width=autopane_wid.p_width;
            if( width>0 ) {
               ptb->auto_width=width;
            }
            break;
         case DOCKINGAREA_TOP:
         case DOCKINGAREA_BOTTOM:
            // Only save the height.
            // IMPORTANT:
            // Use the autopane height, NOT the container height since the
            // container is adjusted to accomodate the sizebar in the autopane.
            int height;
            height=autopane_wid.p_height;
            if( height>0 ) {
               ptb->auto_height=height;
            }
            break;
         }
      }

      if( container.p_visible ) {
         // We set the tool window inside the autopane invisible for the case:
         // 1. Tool window is auto shown
         // 2. User uses a toggle-* command (e.g. toggle-defs) to toggle another auto hidden tool window visible
         // 3. User then toggles original tool window in #1
         // If the autopane is currently visible because it is showing the tool window for #2,
         // and the tool window originally shown in #1 is still visible inside the autopane,
         // we have no way of knowing that it needs to be positioned to the front and re-shown.
         container.p_visible=false;
         wid.p_visible=false;
      }
      if( autopane_wid.p_visible ) {
         //wid._tbSmartDeleteWindow();
         autopane_wid.p_visible=false;
      }

   } else {
      // Toggle Auto Hide on for all tool windows in the tabgroup
      _str FormName = wid.p_name;
      DockingArea area, i, tabgroup, tabOrder;
      if( !_bbdockFindWid(wid,area,i,tabgroup,tabOrder) ) {
         return;
      }
      if( tabgroup>0 && 0==( def_toolbar_options & TBOPTION_NO_AUTOHIDE_TABGROUP ) ) {
         _tbAutoHideTabGroup(tabgroup,area);
         dockchanSetActive(FormName);
      } else {
         _mdi._bbdockRespaceAndRemove(area,i);
         _mdi._bbdockMaybeRemoveButtonBar(area);
         _mdi._bbdockRefresh(area);
         int pic = 0;
         _str caption = "";
         int index = find_index(FormName,oi2type(OI_FORM));
         if( index>0 ) {
            pic=index.p_picture;
            caption=index.p_caption;
         }
         dockchanAdd(area,FormName,pic,caption,
                     _tbDockChanMouseInCallback,
                     _tbDockChanMouseOutCallback,true);
         dockchanSetActive(FormName);
         // Set auto shown width/height to same as docked width/height
         _TOOLBAR* ptb = _tbFind(FormName);
         if( ptb ) {

            switch( area ) {
            case DOCKINGAREA_LEFT:
            case DOCKINGAREA_RIGHT:
               int width;
               width=ptb->docked_width;
               if( width>0 ) {
                  ptb->auto_width=width;
               }
               break;
            case DOCKINGAREA_TOP:
            case DOCKINGAREA_BOTTOM:
               int height;
               height=ptb->docked_height;
               if( height>0 ) {
                  ptb->auto_height=height;
               }
               break;
            }
         }
      }
   }
   // Note:
   // The focus_wid might not be visible if it was part of auto hidden window. This
   // can happen when auto showing a tool window which causes another auto shown
   // tool window with focus to be auto hidden.
   if( focus_wid>0 && _iswindow_valid(focus_wid) && focus_wid.p_visible && !_tbIsAutoHiddenWid(focus_wid.p_active_form) ) {
      //say('_tbAutoHide: focus_wid.p_active_form='focus_wid.p_active_form'='focus_wid.p_active_form.p_name);
      p_window_id=focus_wid;
   } else if (_no_child_windows()) {
      p_window_id= _cmdline;
   } else {
      p_window_id= _mdi.p_child;
   }
   _set_focus();
}

static void _tbAutoHideTabGroup(int tabgroup, int startArea=DOCKINGAREA_FIRST)
{
   if( tabgroup<=0 ) {
      return;
   }
   // 1. Store up the form names before the windows get deleted.
   // 2. Delete all windows in tabgroup.
   // 3. Add dock channel items for all form names.
   DockingArea area, first_i, last_i;
   if( _bbdockFindTabGroup(tabgroup,area,first_i,last_i,startArea) ) {
      _str FormNames[];
      int i;
      for( i=first_i; i<=last_i; ++i ) {
         int wid = _bbdockGetWid(area,i);
         if( wid>0 && _iswindow_valid(wid) ) {
            FormNames[FormNames._length()] = wid.p_name;
         }
      }
      _tbCloseTabGroup(tabgroup,startArea);

      // Keep auto hidden tool windows with their tabgroup in the dock channel
      _str addAfterFormName = "";
      for( i=0; i<def_toolbartab._length(); ++i ) {

         if( def_toolbartab[i].tabgroup==tabgroup ) {
            _str FormName = def_toolbartab[i].FormName;
            DockingArea area_found;
            _str group[];
            if( dockchanFindGroup(FormName,area_found,group) ) {
               addAfterFormName = group[group._length()-1];
            }
         }
      }

      for( i=0; i<FormNames._length(); ++i ) {
         _str FormName = FormNames[i];
         int index = find_index(FormName,oi2type(OI_FORM));
         int pic = index.p_picture;
         _str caption = index.p_caption;
         boolean newGroup = (i==0);
         dockchanAdd(area,FormName,pic,caption,
                     _tbDockChanMouseInCallback,
                     _tbDockChanMouseOutCallback,newGroup,true,addAfterFormName);
         addAfterFormName=FormName;

         // Set auto shown width/height to same as docked width/height for each tool window
         _TOOLBAR* ptb = _tbFind(FormName);
         if( ptb ) {

            switch( area ) {
            case DOCKINGAREA_LEFT:
            case DOCKINGAREA_RIGHT:
               int width;
               width=ptb->docked_width;
               if( width>0 ) {
                  ptb->auto_width=width;
               }
               break;
            case DOCKINGAREA_TOP:
            case DOCKINGAREA_BOTTOM:
               int height;
               height=ptb->docked_height;
               if( height>0 ) {
                  ptb->auto_height=height;
               }
               break;
            }
         }
      }
      dockchanRefresh(area);
   }
}

/**
 * Refresh the following:
 * <li>All editor windows
 * <li>All dock-channels
 * <li>All dock-palettes
 */
static void _RefreshApp()
{
   // Refresh all children of the MDI client area
   int first_child = _mdi.p_child;
   int child = first_child;
   while( child>0 ) {
      child.refresh('w');
      child=child.p_next;
      if( child==first_child ) {
         break;
      }
   }
   // Refresh all dock palettes, dock channels
   int area;
   for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area  ) {
      int wid = _mdi._GetDockPalette(area);
      if( wid>0 ) {
         wid.refresh('w');
      }
      wid=_mdi._GetDockChannel(area);
      if( wid>0 ) {
         wid.refresh('w');
      }
   }
   // Refresh MDI frame.
   // This will redraw the border areas that are not part of the MDI client area.
   _mdi.refresh('r');
}

/**
 * Acts on the active window which must be _autopane_form.
 * <p>
 * Set all children of the autopane window invisible.
 */
static void _autopaneHideAllChildren()
{
   int first_child = p_child;
   int child = first_child;
   while( child > 0 ) {
      child.p_visible = false;
      if( !child.p_enabled ) {
         // 3/29/2007 - rb
         // Explanation:
         // When a modal dialog is shown from an autoshown window, the active
         // form is disabled. If the modal dialog in turn autoshows another
         // tool window, then the currently autoshown tool window is set invisible,
         // which effectively orphans it from the modal dialog. This results in a
         // autohidden tool window that can never be autoshown again because it has
         // been disabled.
         child.p_enabled = true;
         // Must re-enable child forms too, since the modal dialog may have been
         // shown from somewhere inside the tool window.
         int first_child2 = child.p_child;
         int child2 = first_child2;
         while( child2 > 0 ) {
            if( child2.p_object == OI_FORM ) {
               child2.p_enabled = true;
            }
            child2 = child2.p_next;
            if( child2 == first_child2 ) {
               break;
            }
         }
      }
      child = child.p_next;
      if( child == first_child ) {
         break;
      }
   }
}

/**
 * Acts on the active window which must be _autopane_form.
 * <p>
 * Set up the area for the autopane. One of DOCKINGAREA_*.
 */
static void _autopaneSetArea(DockingArea area)
{
   _SetDialogInfoHt("area",area,p_window_id);
}

/**
 * Acts on the active window which must be _autopane_form.
 * <p>
 * Get the area for the autopane. One of DOCKINGAREA_*.
 */
DockingArea _autopaneGetArea()
{
   return _GetDialogInfoHt("area",p_window_id);
}

static int _autopaneLoadAutoPane(DockingArea area=DOCKINGAREA_NONE)
{
   int wid = _find_formobj(AUTOPANE_FORMNAME,'n');
   if( wid>0 ) {
      // Already have one
   } else {
      int index = find_index(AUTOPANE_FORMNAME,oi2type(OI_FORM));
      if( index<=0 ) {
         // We need to be loud about this
         _str msg = get_message(VSRC_FORM_NOT_FOUND,"",AUTOPANE_FORMNAME);
         _message_box("Toolbar internal error: "msg". "get_message(index),"",MB_OK|MB_ICONEXCLAMATION);
         return 0;
      }
      // Child of MDI frame
      wid=_load_template(index,_mdi,'NHPM');
      if( wid==0 ) {
         // We need to be loud about this
         _str msg = "Failed to load "AUTOPANE_FORMNAME;
         _message_box("Toolbar internal error: "msg,"",MB_OK|MB_ICONEXCLAMATION);
         return 0;
      }
      // On top of all other MDI frame children
      wid._set_zorder(0);
   }
   // Set the area we will be on
   wid._autopaneSetArea(area);
   // Make the pane invisible by default
   wid.p_visible=false;
   // Make all child forms invisible
   wid._autopaneHideAllChildren();
   return wid;
}

static int _autopaneGetAutoPane()
{
   int wid = _find_formobj(AUTOPANE_FORMNAME,'n');
   return wid;
}

/**
 * Acts on the active window which must be _autopane_form.
 */
boolean _autopaneIsAutoPaneChild(int wid)
{
   if( wid<=0 ) {
      return false;
   }
   int found_wid = _autopaneFindForm(wid.p_name);
   return (found_wid==wid);
}

int _tbAutoShow(_str FormName, DockingArea area, boolean setFocus=false)
{
   _tbNewVersion();
   _TOOLBAR* ptb = _tbFind(FormName);
   if( !ptb ) {
      // How did we get here?
      return 0;
   }

   int focus_wid = _get_focus();

   int autopane_wid = _autopaneLoadAutoPane(area);
   // Note: autopane is always loaded hidden

   int panel_wid = 0;
   int wid = _find_formobj(FormName,'n');
   if( wid>0 ) {

      if( _tbIsAutoShownWid(wid) ) {
         // Already auto shown
         return wid;
      }

      if( !autopane_wid._autopaneIsAutoPaneChild(wid) ) {
         // Hmm
         return wid;
      }

      // Found a previously auto hidden window, so use it.
      panel_wid=_tbContainerFromWid(wid);

      // Fall through.

   } else {

      // Create the panel inside the autopane window
      int index = find_index(FormName,oi2type(OI_FORM));
      if( index<=0 ) {
         // How did we get here?
         return 0;
      }
      wid=_tbLoadTemplateIntoPanel(ptb->tbflags,index,autopane_wid,panel_wid);
   }
   if( wid==0 ) {
      // Uh oh
      return wid;
   }

   int x=0, y=0, width=0, height=0;

   // Get dock channel coordinates. These are in pixels, so will have
   // to convert to twips.
   sc.util.Rect dcareas[];
   dockchanGetAreas(dcareas,true);
   switch( area ) {
   case DOCKINGAREA_LEFT:
      // Only restore the width
      width=ptb->auto_width;
      if( width<=0 ) {
         width=ptb->docked_width;
         if( width<=0 ) {
            width=TBDEFAULT_DOCK_WIDTH;
         }
      }
      height = _dy2ly(SM_TWIP,dcareas[area].height());
      x = dcareas[area].rightX();
      y = dcareas[area].y();
      _dxy2lxy(SM_TWIP,x,y);
      break;
   case DOCKINGAREA_RIGHT:
      // Only restore the width
      width=ptb->auto_width;
      if( width<=0 ) {
         width=ptb->docked_width;
         if( width<=0 ) {
            width=TBDEFAULT_DOCK_WIDTH;
         }
      }
      height = _dy2ly(SM_TWIP,dcareas[area].height());
      x = dcareas[area].x() - _lx2dx(SM_TWIP,width);
      y = dcareas[area].y();
      _dxy2lxy(SM_TWIP,x,y);
      break;
   case DOCKINGAREA_TOP:
      width = _dx2lx(SM_TWIP,dcareas[area].width());
      // Only restore the height
      height=ptb->auto_height;
      if( height<=0 ) {
         height=ptb->docked_height;
         if( height<=0 ) {
            height=TBDEFAULT_DOCK_HEIGHT;
         }
      }
      x = dcareas[area].x();
      y = dcareas[area].bottomY();
      _dxy2lxy(SM_TWIP,x,y);
      break;
   case DOCKINGAREA_BOTTOM:
      width=_dx2lx(SM_TWIP,dcareas[area].width());
      // Only restore the height
      height=ptb->auto_height;
      if( height<=0 ) {
         height=ptb->docked_height;
         if( height<=0 ) {
            height=TBDEFAULT_DOCK_HEIGHT;
         }
      }
      x = dcareas[area].x();
      y = dcareas[area].y() - _ly2dy(SM_TWIP,height);
      _dxy2lxy(SM_TWIP,x,y);
      break;
   }

   // CHANGE_AUTO_SHOW event to let tool window know it is about to be shown.
   // This gives the tool window a chance to look pretty for the user.
   wid.call_event(CHANGE_AUTO_SHOW,wid,ON_CHANGE,'w');

   // Now is the time to set p_mouse_pointer for the sizebar on the panel,
   // BEFORE the resize.
   int ctl = autopane_wid._find_control("ctl_sizebar");
   if( ctl>0 ) {
      if( area==DOCKINGAREA_LEFT || area==DOCKINGAREA_RIGHT ) {
         ctl.p_mouse_pointer=MP_SIZEHORZ;
      } else {
         // DOCKINGAREA_TOP, DOCKINGAREA_BOTTOM
         ctl.p_mouse_pointer=MP_SIZEVERT;
      }
      ctl.p_visible=true;
   }

   // Move autopane into position, resize child form, make visible to user
   autopane_wid._move_window(x,y,width,height);
   wid.p_visible=true;
   panel_wid.p_visible=true;
   autopane_wid.call_event(autopane_wid,ON_RESIZE,'w');
   autopane_wid.p_visible=true;

   if( setFocus ) {
      if( !panel_wid._tbpanelHasFocus() ) {
         // Set focus to embedded form if focus is not already somewhere in the form
         if( (focus_wid==0 || !_iswindow_valid(focus_wid)) || focus_wid.p_active_form!=wid ) {
            wid._set_focus();
         }
      }
      panel_wid._tbpanelUpdate(1);

   } else if( focus_wid>0 && _iswindow_valid(focus_wid) ) {
      // Put focus back where we found it
      focus_wid._set_focus();
      panel_wid._tbpanelUpdate(-1);
   } else {
      if( p_window_id!=_mdi.p_child ) {
         p_window_id=_mdi.p_child;
         _set_focus();
      }
      panel_wid._tbpanelUpdate(-1);
   }

   // Camp out on this tool window until it is time to auto hide it again
   _tbMaybeAutoHideDelayed(def_toolbar_autohide_delay':'wid':'wid.p_name);

   return wid;
}

static int _autopaneFindForm(_str FormName)
{
   int first_child = p_child;
   int child = first_child;
   while( child>0 ) {
      int form_wid = child;
      _str child_name = child.p_name;
      if( child_name!=FormName && _isContainer(child) ) {
         // Try the active form in this container
         int wid = child._containerFindActiveForm();
         if( wid>0 ) {
            form_wid=wid;
            child_name=wid.p_name;
         }
      }
      if( child_name==FormName ) {
         // Found it
         return form_wid;
      }
      child=child.p_next;
      if( child==first_child ) {
         break;
      }
   }
   // Not found
   return 0;
}

/**
 * Acts on the active window which must be _autopane_form.
 * <p>
 * Get the visible form inside the autopane container.
 */
static int _autopaneFindVisibleForm()
{
   int first_child = p_child;
   int child = first_child;
   while( child>0 ) {
      if( child.p_visible && child.p_object==OI_FORM ) {
         // Found it
         return child;
      }
      child=child.p_next;
      if( child==first_child ) {
         break;
      }
   }
   // Not found
   return 0;
}


//
// _autopane_form
// A container for auto hide tool windows.
//

defeventtab _autopane_form;

void _autopane_form.on_create()
{
}

static boolean _ObjectIsSizebar()
{
   if( p_object==OI_IMAGE && (p_style==PSPIC_SIZEHORZ || p_style==PSPIC_SIZEVERT) && p_name=="ctl_sizebar" ) {
      return true;
   }
   return false;
}

static void _autopaneOnSizebar()
{
   if( !_ObjectIsSizebar() ) {
      // Not clicking on a sizebar, so quietly fail
      return;
   }
   int sizerWid = p_window_id;
   int sizerW = _lx2dx(SM_TWIP,sizerWid.p_width);
   int sizerH = _ly2dy(SM_TWIP,sizerWid.p_height);

   int wid = p_active_form._autopaneFindVisibleForm();
   if( wid == 0 ) {
      return;
   }
   _str FormName = wid.p_name;

   DockingArea area = p_active_form._autopaneGetArea();

   int focus_wid = _get_focus();

   int selected_wid = p_active_form;
   int capture_wid = _mdi;

   int x, y, width, height;
   selected_wid._get_window(x,y,width,height);
   _lxy2dxy(selected_wid.p_xyscale_mode,x,y);
   _lxy2dxy(selected_wid.p_xyscale_mode,width,height);
   // Note: autopane is a child of _mdi, so no need to map coordinates
   switch( area ) {
   case DOCKINGAREA_LEFT:
      x = x + width - sizerW;
      width = sizerW;
      break;
   case DOCKINGAREA_RIGHT:
      width = sizerW;
      break;
   case DOCKINGAREA_TOP:
      y = y + height - sizerH;
      height = sizerH;
      break;
   case DOCKINGAREA_BOTTOM:
      height = sizerH;
      break;
   }

   int orig_x = x;
   int orig_y = y;


   mou_mode(1);
   capture_wid.mou_capture();
   _KillToolButtonTimer();
   int morig_x = capture_wid.mou_last_x('m');
   int morig_y = capture_wid.mou_last_y('m');

   sc.controls.RubberBand rb(capture_wid);
   rb.setWindow(x,y,width,height);

   se.util.MousePointerGuard mousePointerSentry(MP_DEFAULT,capture_wid);
   switch( area ) {
   case DOCKINGAREA_TOP:
   case DOCKINGAREA_BOTTOM:
      mousePointerSentry.setMousePointer(MP_SIZEVERT);
      break;
   case DOCKINGAREA_LEFT:
   case DOCKINGAREA_RIGHT:
      mousePointerSentry.setMousePointer(MP_SIZEHORZ);
      break;
   }

   boolean done = false;
   boolean checkMinDrag = true;
   boolean moved = false;
   _str event = MOUSE_MOVE;

   do {

      event = capture_wid.get_event();
      switch( event ) {
      case MOUSE_MOVE:
         int new_x = x;
         int new_y = y;
         if( area == DOCKINGAREA_LEFT || area == DOCKINGAREA_RIGHT ) {
            new_x = orig_x + capture_wid.mou_last_x('m') - morig_x;
            moved = new_x != orig_x;
            rb.move(new_x,orig_y);

         } else {
            new_y = orig_y + capture_wid.mou_last_y('m') - morig_y;
            moved = new_y != orig_y;
            rb.move(orig_x,new_y);
         }

         if( checkMinDrag ) {
            if( moved ) {
               checkMinDrag = false;
               if( !rb.isVisible() ) {
                  rb.setVisible(true);
               }
            }
         }

         x = new_x;
         y = new_y;
         break;
      case LBUTTON_UP:
      case ESC:
         done = true;
      }

   } while( !done );

   //selected_wid.mou_limit(0,0,0,0);
   mou_mode(0);
   capture_wid.mou_release();
   if( moved ) {

      if( event != ESC ) {

         int adjust_x = 0;
         int adjust_y = 0;
         int adjust_width = 0;
         int adjust_height = 0;

         if( area == DOCKINGAREA_LEFT ) {
            adjust_width = x - orig_x;
            if( (selected_wid.p_width+adjust_width) < 0 ) {
               adjust_width = -selected_wid.p_width;
            }

         } else if( area == DOCKINGAREA_RIGHT ) {
            adjust_width = orig_x-x;
            if( (selected_wid.p_width+adjust_width) < 0 ) {
               adjust_width= -selected_wid.p_width;
            }
            adjust_x = -adjust_width;

         } else if( area == DOCKINGAREA_TOP ) {
            adjust_height = y-orig_y;
            if( (selected_wid.p_height+adjust_height) < 0 ) {
               adjust_height = -selected_wid.p_height;
            }

         } else if( area == DOCKINGAREA_BOTTOM ) {
            adjust_height = orig_y-y;
            if( (selected_wid.p_height+adjust_height) < 0 ) {
               adjust_height = -selected_wid.p_height;
            }
            adjust_y = -adjust_height;

         } else {
            return;
         }
         // Translate back to twips
         _dxy2lxy(SM_TWIP,adjust_x,adjust_y);
         _dxy2lxy(SM_TWIP,adjust_width,adjust_height);
         selected_wid.p_x += adjust_x;
         selected_wid.p_y += adjust_y;
         selected_wid.p_width += adjust_width;
         selected_wid.p_height += adjust_height;
      }
   }

   if( focus_wid != 0 ) {
      focus_wid._set_focus();
   }
}

static boolean _autopane_ignore_resize = false;
static boolean _autopaneIgnoreResize(boolean onoff)
{
   boolean old_value = _autopane_ignore_resize;
   _autopane_ignore_resize=onoff;
   return old_value;
}

void _autopane_form.on_resize()
{
   if( _autopane_ignore_resize ) {
      return;
   }

   int formwid = _autopaneFindVisibleForm();
   if( formwid==0 ) {
      return;
   }

   int clientW = _dx2lx(p_xyscale_mode,p_client_width);
   int clientH = _dy2ly(p_xyscale_mode,p_client_height);
   
   int sizebarWid = _find_control("ctl_sizebar");
   if( sizebarWid>0 ) {
      sizebarWid.p_auto_size=true;
      int x=0, y=0;
      int width = sizebarWid.p_width;
      int height = sizebarWid.p_height;
      int form_x=0, form_y=0;
      int formW=0, formH=0;
      switch( _autopaneGetArea() ) {
      case DOCKINGAREA_LEFT:
         if( sizebarWid.p_style!=PSPIC_SIZEVERT ) {
            sizebarWid.p_style=PSPIC_SIZEVERT;
            sizebarWid.p_mouse_pointer=MP_SIZEWE;
         }
         x=clientW - sizebarWid.p_width;
         y=0;
         height=clientH;
         form_x=0;
         form_y=0;
         formW=clientW - sizebarWid.p_width;
         formH=clientH;
         break;
      case DOCKINGAREA_RIGHT:
         if( sizebarWid.p_style!=PSPIC_SIZEVERT ) {
            sizebarWid.p_style=PSPIC_SIZEVERT;
            sizebarWid.p_mouse_pointer=MP_SIZEWE;
         }
         x=0;
         y=0;
         height=clientH;
         form_x=sizebarWid.p_width;
         form_y=0;
         formW=clientW - sizebarWid.p_width;
         formH=clientH;
         break;
      case DOCKINGAREA_TOP:
         if( sizebarWid.p_style!=PSPIC_SIZEHORZ ) {
            sizebarWid.p_style=PSPIC_SIZEHORZ;
            sizebarWid.p_mouse_pointer=MP_SIZENS;
         }
         x=0;
         y=clientH - sizebarWid.p_height;
         width=clientW;
         form_x=0;
         form_y=0;
         formW=clientW;
         formH=clientH - sizebarWid.p_height;
         break;
      case DOCKINGAREA_BOTTOM:
         if( sizebarWid.p_style!=PSPIC_SIZEHORZ ) {
            sizebarWid.p_style=PSPIC_SIZEHORZ;
            sizebarWid.p_mouse_pointer=MP_SIZENS;
         }
         x=0;
         y=0;
         width=clientW;
         form_y=sizebarWid.p_height;
         formW=clientW;
         formH=clientH - sizebarWid.p_height;
         break;
      }
      formwid._move_window(form_x,form_y,formW,formH);
      sizebarWid._move_window(x,y,width,height);
      // We must call ON_RESIZE explicitly for the embedded form
      formwid.call_event(formwid,ON_RESIZE,'w');
   }
}

void _autopane_form.lbutton_down()
{
   if( !_ObjectIsSizebar() ) {
      return;
   }

   _autopaneOnSizebar();
}

/**
 * Called automatically when the editor exits. Destroys autopane 
 * window before MDI is destroyed so that tool-windows can have 
 * access to _mdi. 
 *
 * @return 0
 */
int _exit_autohide()
{
   int wid = _autopaneGetAutoPane();
   if( wid > 0 ) {
      wid._delete_window();
   }
   return 0;
}


//
// Debug
//

#if 0
_command void tbatest1()
{
   int wid = _find_formobj('_tbprops_form','n');
   say('tbatest1: wid='wid);
   if( wid>0 ) {
      int autopane_wid = _autopaneGetAutoPane();
      say('tbatest1: autopane_wid='autopane_wid);
      if( autopane_wid>0 ) {
         boolean found = autopane_wid._autopaneIsAutoPaneChild(wid);
         say('tbatest1: found='found);
      }
   }
}
_command void tbatest2()
{
   _str form_name = arg(1);
   if( form_name=="" ) {
      message("Usage: tbatest2 form-name");
      return;
   }
   int last = _last_window_id();
   int i;
   for( i=1; i<=last; ++i ) {
      if( _iswindow_valid(i) && i.p_object==OI_FORM && !i.p_edit ) {
         if( name_eq(i.p_name,form_name) ) {
            say('tbatest2: found i='i'  i.p_name='i.p_name);
         }
      }
   }
}
_command void tbatest3()
{
   say('tbatest3: ************************************************');
   say('tbatest3: ************************************************');
   say('tbatest3: ************************************************');
   int wid = _autopaneGetAutoPane();
   if( wid>0 ) {
      int first_child = wid.p_child;
      int child = first_child;
      while( child>0 ) {
         int formwid = child;
         if( _isContainer(formwid) ) {
            formwid=formwid._containerFindActiveForm();
         }
         mywininfo(formwid);
         child=child.p_next;
         if( child==first_child ) {
            break;
         }
      }
   }
}
_command void tbatest4()
{
   _str FormName = "_tbFTPOpen_form";
   int wid = _find_formobj(FormName,'n');
   if( wid>0 ) {
      say('tbatest3: _tbIsAutoShownWid='_tbIsAutoShownWid(wid));
      say('tbatest3: _tbIsAutoHiddenWid='_tbIsAutoHiddenWid(wid));
      say('tbatest3: _tbIsAutoWid='_tbIsAutoWid(wid));
   }
}
_command void tbatest5()
{
   DCSIDERECT dcareas[];
   dockchanGetSides(dcareas);
   DockingArea area = DOCKINGAREA_BOTTOM;
   int x1, y1, x2, y2;
   x1=dcareas[area].x1;
   y1=dcareas[area].y1;
   x2=dcareas[area].x2;
   y2=dcareas[area].y2;
   WINRECT r;
   _WinRectSetSubRect(r,0,x1,y1,x2,y2);
   _desktop._WinRectDrawRect(r,_rgb(255,0,0),'n');

   area=DOCKINGAREA_RIGHT;
   x1=dcareas[area].x1;
   y1=dcareas[area].y1;
   x2=dcareas[area].x2;
   y2=dcareas[area].y2;
   _WinRectSetSubRect(r,0,x1,y1,x2,y2);
   _desktop._WinRectDrawRect(r,_rgb(0,255,0),'n');
}
#endif
