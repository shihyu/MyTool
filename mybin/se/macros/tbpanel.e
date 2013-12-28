////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46862 $
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
#import "picture.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbtabgroup.e"
#import "toolbar.e"
// Needed for _rgb()
#import "dlgman.e"
#endregion

/**
 * Create tool window from resource_index as a child of a _tbpanel_form form.
 * The _tbpanel_form form supports additional decoration like a title bar,
 * close, and autohide buttons. The _tbpanel_form form is a child of the
 * parent_wid.
 * 
 * @param tbflags
 * @param resource_index If >0, then load resource as a child of the created
 *                       panel. If ==0, then only create the panel. 0 is returned
 *                       for the tool window.
 * @param parent_wid
 * @param panel_wid      (output). Window id (wid) of _tbpanel_form that is
 *                       the parent of the tool window and the child of the
 *                       parent_wid.
 * 
 * @return Window id (wid) of loaded tool window (not the _tbpanel_form, that
 * is returned in output variable panel_wid). If resource_index==0, then 0 is
 * returned.
 */
int _tbLoadTemplateIntoPanel(int tbflags, int resource_index, int parent_wid, int& panel_wid)
{
   panel_wid=0;
   _str panelFormName = "_tbpanel_form";
   int panel_index = find_index(panelFormName,oi2type(OI_FORM));
   if( panel_index==0 ) {
      // Big problem
      _str msg = get_message(VSRC_FORM_NOT_FOUND,"",panelFormName);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return 0;
   }
   int orig_wid = p_window_id;
   if( parent_wid==0 ) {
      // A child of the MDI frame
      panel_wid=_load_template(panel_index);
      panel_wid.p_visible=false;
   } else {
      _str asChild = '';
      _str noBorder = 'N';
      if( parent_wid!=_mdi ) {
         asChild='P';
      }
      panel_wid=_load_template(panel_index,parent_wid,'H':+asChild:+noBorder);
   }
   p_window_id=orig_wid;

   int tbwid = 0;
   if( resource_index>0 ) {
      tbwid=_tbLoadTemplate(tbflags,resource_index,panel_wid);
   }
   return tbwid;
}

//
// _tbpanel_form is used to encapsulate a tool window and provide title bar,
// close, autohide controls.
//

defeventtab _tbpanel_form;

boolean _tbpanelIsPanel(int wid)
{
   if( wid>0 && _iswindow_valid(wid) && wid.p_name=="_tbpanel_form" ) {
      return true;
   }
   return false;
}

/**
 * Operates on a _tbpanel_form wid.
 * 
 * @return The first child window. If no tabgroup, then this will be a tool
 * window wid. If there is a tabgroup in this panel, then the wid of the SSTAb
 * control is returned.
 */
int _tbpanelFindChild()
{
   int child = 0;
   // Find the tool window or SSTab tabgroup embedded in this form
   int wid = p_child;
   int first_wid = wid;
   while( wid!=0 ) {
      if( wid.p_object==OI_FORM ||
          wid.p_object==OI_SSTAB ) {

         child=wid;
         break;
      }
      wid=wid.p_next;
      if( wid==first_wid ) {
         child=0;
         break;
      }
   }
   return child;
}

/**
 * Operates on a _tbpanel_form wid.
 * 
 * @return The active child window that is a tool window. If there is a
 * tabgroup in this panel, then the tool window wid of the active tab
 * of the SSTab control is returned.
 */
int _tbpanelFindActiveForm()
{
   int form_wid = 0;
   int child = _tbpanelFindChild();
   if( child>0 ) {
      if( child.p_object==OI_FORM ) {
         // Child is the tool window (i.e. no tabgroup in this panel)
         form_wid = child;
      } else if( child.p_object==OI_SSTAB ) {
         // Find the tool window in the active tab
         form_wid=child._tabgroupFindActiveForm();
      }
   }
   return form_wid;
}

static void _tbpanelGetActiveCaptionColor(int& fg, int& bg)
{
   // Dialog caption foreground
   //fg=_rgb(255,255,255);
   fg=0x80000023;

   // Dialog caption background
   //bg=_rgb(0,0,255);
   bg=0x80000024;
}

static void _tbpanelGetInactiveCaptionColor(int& fg, int& bg)
{
   // Dialog foreground
   //fg=_rgb(0,0,0);
   //fg=0x80000008;
   fg=0x80000025;

   // Dialog background
   //bg=_rgb(192,192,192);
   //bg=0x80000005;
   bg=0x80000026;
}

void _tbpanelSetFocus(boolean setFocus=true)
{
   int fg, bg;
   int autohide_index;

   // Focus background color
   if( setFocus ) {
      // Set focus
      _tbpanelGetActiveCaptionColor(fg,bg);
   } else {
      // Unset focus
      _tbpanelGetInactiveCaptionColor(fg,bg);
   }

   // Autohide button picture
   autohide_index=ctl_autohide.p_picture;
   if( autohide_index==_pic_pinin_mono ) {
      autohide_index=_pic_pinin_mono;
   } else if( autohide_index==_pic_pinout_mono ) {
      autohide_index=_pic_pinout_mono;
   }

   boolean old_p_visible = ctl_caption.p_visible;
   boolean changeColor = ( ctl_caption.p_backcolor!=bg );
   ctl_caption.p_visible=false;
   if( changeColor ) {
      ctl_caption.p_backcolor=bg;
      ctl_caption.p_forecolor=fg;
      ctl_caption_text.p_backcolor=bg;
      ctl_caption_text.p_forecolor=fg;
      ctl_close.p_backcolor=bg;
      ctl_close.p_forecolor=fg;
      ctl_autohide.p_backcolor=bg;
      ctl_autohide.p_forecolor=fg;
   }
   if( ctl_autohide.p_picture!=autohide_index ) {
      ctl_autohide.p_picture=autohide_index;
   }
   ctl_caption.p_visible=old_p_visible;

   // Finally, set p_user to indicate whether this panel has "focus"
   ctl_caption.p_user=setFocus;
}

/**
 * Operates on current panel window.
 * 
 * @return true if focus is in the panel or a child of the panel.
 */
boolean _tbpanelHasFocus()
{
   if( !_tbpanelIsPanel(p_window_id) ) {
      return false;
   }
   int focus_form = 0;
   int parent_focus_form = 0;
   int focus_wid = _get_focus();
   if( focus_wid!=0 ) {
      focus_form=focus_wid.p_active_form;
      if( focus_form!=0 ) {
         if( focus_form.p_parent!=0 ) {
            parent_focus_form=focus_form.p_parent.p_active_form;
         }
      }
   }
   return ( p_active_form==focus_form || p_active_form==parent_focus_form );
}

/**
 * Operates on current panel window.
 * 
 * @return true if the panel is selected (i.e. caption title bar has been clicked or been activated).
 */
boolean _tbpanelIsSelected()
{
   if( !_tbpanelIsPanel(p_window_id) ) {
      return false;
   }
   int ctl = _find_control("ctl_caption");
   if( ctl>0 ) {
      return ( ctl.p_user != 0 );
   }
   // Not selected
   return false;
}

/**
 * Acts on the active window which must be a _tbpanel_form.
 */
static void _tbpanelAutoSetFocus()
{
   boolean setFocus = p_active_form._tbpanelHasFocus();
   _tbpanelSetFocus(setFocus);
}

/**
 * Acts on the active window which must be a _tbpanel_form.
 * <p>
 * Update the panel caption to reflect focus set or unset.
 * 
 * @param setFocus (optional). Defaults to -1 which means that focus will
 *                 be calculated. Pass 0 to explicitly unset focus. Pass 1
 *                 to explicitly set focus.
 */
void _tbpanelUpdate(int setFocus=-1)
{
   // Set or unset focus on the caption
   if( setFocus<0 ) {
      _tbpanelAutoSetFocus();
   } else {
      _tbpanelSetFocus(setFocus!=0);
   }

   // Update caption text
   int tabgroup_wid = 0;
   boolean old_p_visible = ctl_caption.p_visible;
   ctl_caption.p_visible=false;
   _str caption_text = "";
   int autohide_pic_index = _pic_pinin_mono;
   int form_wid = p_active_form._tbpanelFindChild();
   // Note:
   // form_wid could be a SSTab tabgroup
   if( form_wid>0 ) {

      if( form_wid.p_object==OI_SSTAB ) {

         // Tool windows are tab-linked inside SSTab tabgroup,
         // so take note of the wid for later.
         tabgroup_wid=form_wid;

         form_wid=form_wid._tabgroupFindActiveForm();
         if( form_wid==0 ) {
            // No tool window on the active tab yet? Hmm...
            ctl_caption.p_visible = old_p_visible;
            return;
         }
      }
      caption_text=form_wid.p_caption;
      _TOOLBAR* ptb = _tbFind(form_wid.p_name);
      if( !_tbIsAutoHideAllowed(ptb) ) {
         // Auto Hide disallowed, so hide the button
         ctl_autohide.p_visible=false;
         autohide_pic_index=0;
      } else if( _tbIsAutoShownWid(form_wid) ) {
         // This panel is auto shown, so untack the pin
         autohide_pic_index=_pic_pinout_mono;
      }
      // Note:
      // p_modal is not reliable, so check if the MDI frame is disabled instead.
      if( !form_wid.p_enabled && _mdi.p_enabled ) {
         // Tool window is disabled, so make it obvious
         caption_text=caption_text" (disabled)";
      }
   }
   if( ctl_caption_text.p_caption!=caption_text ) {
      ctl_caption_text.p_caption=caption_text;
   }
   if( ctl_autohide.p_visible && ctl_autohide.p_picture!=autohide_pic_index ) {
      ctl_autohide.p_picture=autohide_pic_index;
   }
   ctl_caption.p_visible=old_p_visible;
   ctl_caption.refresh('w');

   if( form_wid>0 && tabgroup_wid>0 ) {
      // Enable/disable the active tab
      if( tabgroup_wid.p_ActiveEnabled!=form_wid.p_enabled ) {
         // Only set p_ActiveEnabled if changed to avoid flash
         tabgroup_wid.p_ActiveEnabled=form_wid.p_enabled;
      }
   }
}

/**
 * Find the panel that wid exists inside.
 * 
 * @param wid
 * 
 * @return Panel wid if exists, otherwise 0.
 */
int _tbFindParentPanel(int wid)
{
   int parent_panel = 0;
   if( wid>0 && _iswindow_valid(wid) ) {
      int parent_form = wid.p_active_form;
      while( parent_form>0 ) {
         if( parent_form.p_name=="_tbpanel_form" ) {
            parent_panel=parent_form;
            break;
         }
         int parent = parent_form.p_parent;
         parent_form=0;
         if( parent>0 ) {
            parent_form=parent.p_active_form;
         }
      }
   }
   return parent_panel;
}

/**
 * Iterate through all docked panels on a side and set/unset focus based on
 * current focus.
 * 
 * @param area (optional). Defaults to DOCKINGAREA_UNSPEC which 
 *               means to iterate through all areas. Specifies
 *               area to set/unset focus for.
 */
void _tbpanelUpdateAllPanels(DockingArea area=DOCKINGAREA_UNSPEC)
{
   //say('_tbpanelUpdateAllPanels: in');
   int focus_wid = _get_focus();
   int focus_panel = _tbFindParentPanel(focus_wid);

   // Update all docked panels
   DockingArea first_area, last_area;
   if( area<0 ) {
      // Iterate through all sides
      first_area=DOCKINGAREA_FIRST;
      last_area=_bbdockPaletteLastIndex();

   } else {
      // Only process one side
      first_area=last_area=area;
   }
   int area_i = (int)area;
   for( area_i=first_area; area_i <= last_area; ++area_i ) {
      int i;
      int count = _bbdockPaletteLength(area_i);
      for( i=0;i<count;++i ) {
         int wid = gbbdockinfo[area_i][i].wid;
         if( wid==BBDOCKINFO_ROWBREAK ) {
            continue;
         }
         int container_wid = _bbdockContainer(&gbbdockinfo[area_i][i]);
         if( container_wid>0 && container_wid!=wid && _iswindow_valid(container_wid) ) {
            // We have a panel
            container_wid._tbpanelUpdate( (int)(container_wid==focus_panel) );
         }
      }
   }
   int wid = _tbFindAutoShownWid();
   if( wid>0 && _tbpanelIsPanel(wid) ) {
      wid._tbpanelUpdate(-1);
   }
}

void _tbpanel_form.on_create()
{
   //say('_tbpanel_form.ON_CREATE: in');
   // When we need to catch LBUTTON_DOWN events for the label text on the
   // caption.
   ctl_caption_text.p_MouseActivate=MA_ACTIVATE;
   //p_backcolor = _rgb(0,0,255);
   // Resize the embedded form
   //_tbpanelOnResize();
}

void _tbpanel_form.on_load()
{
   //say('_tbpanel_form.ON_LOAD: in');
   // Update the caption after everything is loaded.
   // Note:
   // More than likely the tool window child has not been
   // loaded yet, but calling the update now will at least
   // get the caption sized correctly.
   _tbpanelUpdate();
}

#define TBPANEL_MINIMIZE_SPACE 1
#if TBPANEL_MINIMIZE_SPACE
   #define CAPTION_GAP_X 1*_twips_per_pixel_x()
   #define CAPTION_GAP_Y 1*_twips_per_pixel_y()
#else
   #define CAPTION_GAP_X 1*_twips_per_pixel_x()
   #define CAPTION_GAP_Y 2*_twips_per_pixel_y()
#endif
#define CAPTION_BUTTON_GAP_X 3*_twips_per_pixel_x()

static void _tbpanelOnResize()
{
   // Find the embedded form.
   // Note:
   // This code works for both a child form and a child SSTab control.
   int form_wid = _tbpanelFindChild();
   if( form_wid==0 ) {
      return;
   }

   int client_width = _dx2lx(p_xyscale_mode,p_client_width);
   int client_height = _dy2ly(p_xyscale_mode,p_client_height);

   form_wid.p_visible=false;

   int sizebarWid = 0;
   int adjust_x = 0;
   int adjust_width = 0;
   int adjust_y = 0;
   int adjust_height = 0;

   // Autosize button heights can be quite different on different platforms.
   // Adjusting here prevents us from having a title bar caption that is too thick.
   //ctl_caption.p_height = max(ctl_caption_text.p_height,ctl_close.p_height);
   ctl_caption.p_height = max(ctl_caption_text.p_height + 4*_twips_per_pixel_y(),
                              ctl_close.p_height);

   // First we do some gross sizing of the embedded form in order to
   // determine whether the form wants to be smaller/bigger than what
   // we size it to.
   // 2*CAPTION_GAP_X = left/right gap
   int form_width = client_width - 2*CAPTION_GAP_X - adjust_x - adjust_width;
   if( form_width<0 ) {
      form_width=0;
   }
   // 3*CAPTION_GAP_Y = top/bottom gap + gap between caption and embedded form
   int form_height = client_height - ctl_caption.p_height - 3*CAPTION_GAP_Y - adjust_y - adjust_height;
   if( form_height<0 ) {
      form_height=0;
   }
   form_wid.p_width = form_width;
   form_wid.p_height = form_height;
   int diff_width = 0;
   int diff_height = 0;
   if( form_wid.p_width!=form_width ) {
      diff_width=form_wid.p_width-form_width;
      p_width += diff_width;
      client_width=_dx2lx(p_xyscale_mode,p_client_width);
   }
   if( form_wid.p_height!=form_height ) {
      diff_height=form_wid.p_height-form_height;
      p_height += diff_height;
      client_height=_dy2ly(p_xyscale_mode,p_client_height);
   }

   //
   // Title bar caption, close, autohide buttons, caption text label
   //

   // Caption bar
   ctl_caption.p_x = CAPTION_GAP_X + adjust_x;
   ctl_caption.p_y = CAPTION_GAP_Y + adjust_y;
   ctl_caption.p_width = client_width - 2*ctl_caption.p_x - adjust_width;

   // Close
   ctl_close.p_x = ctl_caption.p_width - ctl_close.p_width - CAPTION_BUTTON_GAP_X;
   ctl_close.p_y = (ctl_caption.p_height - ctl_close.p_height) intdiv 2;

   // Pin
   ctl_autohide.p_x = ctl_close.p_x - ctl_autohide.p_width - CAPTION_BUTTON_GAP_X;
   ctl_autohide.p_y = ctl_close.p_y;

   // Caption text
   ctl_caption_text.p_x = CAPTION_BUTTON_GAP_X;
   ctl_caption_text.p_y = (ctl_caption.p_height - ctl_caption_text.p_height) intdiv 2;
   ctl_caption_text.p_width = ctl_autohide.p_x - CAPTION_BUTTON_GAP_X;

   // Position the embedded form just below the caption
   int new_x = ctl_caption.p_x;
   int new_y = ctl_caption.p_y + ctl_caption.p_height + CAPTION_GAP_Y;
   form_wid.p_x=new_x + adjust_x;
   form_wid.p_y=new_y + adjust_y;

   if( form_wid.p_object==OI_SSTAB ) {
      // SSTab tabgroup, so must resize all the tab-linked tool windows
      form_wid.call_event(defeventtab _tabgroup_etab,ON_RESIZE,'E');
   }

   form_wid.p_visible=true;
}

void _tbpanel_form.on_resize()
{
   //say('_tbpanel_form.ON_RESIZE: in');
   _tbpanelOnResize();
}

void _tbpanel_form.on_got_focus()
{
   //say('_tbpanel_form.ON_GOT_FOCUS: in - p_active_form.p_name='p_active_form.p_name);
   _tbpanelUpdate();
}

void _tbpanel_form.on_lost_focus()
{
   //say('_tbpanel_form.ON_LOST_FOCUS: in - p_active_form.p_name='p_active_form.p_name);
   p_active_form._tbpanelUpdate();
   int wid = p_active_form._tbpanelFindActiveForm();
   if( wid>0 ) {
      //say('_tbpanel_form.on_lost_focus: calling on-lost-focus2 for 'wid.p_name);
      wid.call_event(wid,ON_LOST_FOCUS2,'w');
   }
}

void _tbpanel_form.on_destroy()
{
   //say('_tbpanel_form.ON_DESTROY: in');
   if( _tbIsAutoWid(p_active_form) ) {
      // We do not save state for auto shown tool windows
      return;
   }
   // The ON_DESTROY event is not called for child forms (p_object==OI_FORM)
   // when the parent form (_tbpanel_form) is _delete_window()'ed, so we
   // must call it explicity for the child tool window so that docking state, etc.
   // is saved in def_toolbartab.
   // Note:
   // tbwid might be an SSTab tabgroup in which case the _tabgroup_etab.ON_DESTROY
   // will take care of saving state for all tab-linked tool windows.
   int wid = p_active_form._tbpanelFindChild();
   if( wid>0 ) {
      wid.call_event(wid,ON_DESTROY,'W');
   }
}

static boolean _ObjectIsCaption()
{
   if( p_object==OI_PICTURE_BOX && p_name=="ctl_caption" ) {
      return true;
   } else if( p_object==OI_LABEL && p_name=="ctl_caption_text" ) {
      return true;
   }
   return false;
}

void _tbpanel_form.lbutton_down()
{
#if __MACOSX__
   if( !_tbIsAppActivated() ) {
      // Not active yet. We need this on Mac in order to avoid using
      // get_event() while the app is becoming active. If auto-reload
      // kicks in and shows a dialog, then get_event() gets stuck.
      return;
   }
#endif
   if( p_object!=OI_FORM && !_ImageIsSpace() && !_ObjectIsCaption() ) {
      // Not a valid object to operate on.
      // Fail quietly.
      //say('_tbpanel_form.LBUTTON_DOWN: FAILING!!!');
      return;
   }
   if( _tbIsAutoShownWid(p_active_form) ) {
      // No drag-drop allowed on auto shown windows.
      // Just set focus.
      _set_focus();
      return;
   }

   int form_wid = p_active_form;
   //say('_tbpanel_form.lbutton_down: form_wid='form_wid'  p_name='form_wid.p_name);
   //_set_focus();
   //form_wid._tbpanelUpdate();

   int tbwid = form_wid._tbpanelFindActiveForm();
   if( tbwid==0 ) {
      // Uh oh
      _message_box("_tbpanel_form.lbutton_down: Tool window error");
      return;
   }

   if( !_ObjectIsCaption() ) {
      // Only allow drag-drop operations from caption
      tbwid._set_focus();
      _tbpanelUpdateAllPanels();
      form_wid._tbpanelSetFocus(true);
      return;
   }

   if( _ObjectIsCaption() ) {
      // Camp out on the caption until the mouse leaves it.
      // We do this in order to know when we can start a
      // docking action. We do not want the user to inadvertantly
      // start a docking action just because they jogged their
      // mouse inside the caption.

      int selected_wid = p_window_id;
      if( selected_wid.p_object==OI_LABEL ) {
         // Get the picture control parent
         selected_wid=selected_wid.p_parent;
      }

      // 3/29/2005 - RB
      // IMPORTANT:
      // Do NOT call _set_focus() before capturing the mouse. It really
      // messes up the capture. Maybe because the on_got_focus[2] event
      // gets captured too. Not sure, just do not do it. This only seems
      // to affect UNIX, but will disable for all platforms for now since
      // it can be argued that focus should not go to a tool window that
      // is being moved anyway. If the user lets off the mouse without
      // leaving the caption, then focus _will_ get set later.
      // Need focus for visual feedback
      //selected_wid._set_focus();

      WINRECT crect;
      _WinRectSet(crect,selected_wid);
      int mx, my;

      mou_mode(1);
      selected_wid.mou_capture(1);
      boolean done = false;
      _str e = MOUSE_MOVE;
      for( ;; ) {

         switch( e ) {
         case MOUSE_MOVE:
            mou_get_xy(mx,my);
            if( !_WinRectPointInside(crect,crect.wid,mx,my) ) {
               // We have moved outside the caption
               done=true;
            }
            break;
         case LBUTTON_UP:
         case ESC:
            done=true;
            break;
         }
         if( done ) {
            break;
         }
         e = selected_wid.get_event();
      }
      selected_wid.mou_release();
      mou_mode(0);

      if( e==LBUTTON_UP || e==ESC ) {
         // User ESCaped or was simply clicking on the caption.
         // Update all panel captions to reflect that this panel is the one
         // with focus.
         tbwid._set_focus();
         _tbpanelUpdateAllPanels();
         form_wid._tbpanelSetFocus(true);
         return;
      }
   }

   // If we got here, then the user started a docking operation by
   // dragging the mouse cursor outside the caption OR by drag-dropping
   // from somewhere other than the caption.
   DockOperation dop;
   tbwid._dockOpInit(dop);
   // If arg(1)!="" then always disallow docking
   dop.allowDocking = ( dop.allowDocking && arg(1)=="" );
   // Only change the mouse pointer if the user moves the mouse a minimum
   // amount. Sometimes the user just wanted to select the caption, not
   // drag it.
   // User definitely dragged mouse cursor outside the caption, so start
   // docking operation immediately.
   dop.checkMinDragMousePointer=false;
   _dockOpDragDropMode(dop);
   //say('_tbpanel_form.lbutton_down: dop.newarea='dop.newarea);
   if( dop.newarea<0 ) {
      // User ESCaped or was simply clicking on the caption.
      // Update all panel captions to reflect that this panel is the one
      // with focus.
      tbwid._set_focus();
      _tbpanelUpdateAllPanels();
      form_wid._tbpanelSetFocus(true);
      return;
   }
   _dockOpDropExecute(dop);
}

void ctl_caption.lbutton_down()
{
   //say('ctl_caption.LBUTTON_DOWN: in');
   p_active_form.call_event(p_active_form,LBUTTON_DOWN,'W');
}

#if 0
void ctl_caption_text.lbutton_down()
{
   //say('ctl_caption_text.LBUTTON_DOWN: in');
   // Remember that we set p_MouseActivate for the label so that we would
   // get events, but this does not include focus events, so we must
   // explicitly set focus. This causes a ON_LOST_FOCUS to be sent so that
   // all panels' captions are updated, and an ON_GOT_FOCUS to this panel.
   p_active_form._set_focus();
   p_active_form.call_event(p_active_form,LBUTTON_DOWN,'W');
}
#endif

void _tbpanel_form.lbutton_double_click()
{
   int tbwid = p_active_form._tbpanelFindActiveForm();
   tbFloatingToggle(tbwid);
}

void _tbpanel_form.rbutton_up()
{
   if( !_ObjectIsCaption() ) {
      // We are not clicking in the caption, so fail quietly
      return;
   }
   int tbwid = p_active_form._tbpanelFindActiveForm();
   if( tbwid>0 ) {
      tbwid.call_event(defeventtab _toolbar_etab2,RBUTTON_UP,'E');
   }
}

void ctl_caption_text.rbutton_up()
{
   // Remember that we set p_MouseActivate for the label so that we would
   // get events, but this does not include focus events, so we must
   // explicitly set focus. This causes a ON_LOST_FOCUS to be sent so that
   // all panels' captions are updated, and an ON_GOT_FOCUS to this panel.
   _set_focus();
   call_event(p_active_form,RBUTTON_UP,'W');
}

void ctl_close.lbutton_up()
{
   //say('ctl_close.LBUTTON_UP: in');
   // Set the caption active before we commit suicide for visual feedback
   //p_active_form._tbpanelUpdate(1);

   int form_wid = p_active_form;
   int tbwid = form_wid._tbpanelFindActiveForm();

   // We are about to delete the tool window, so set focus to a place
   // we want to be after the form is gone.
   if( _mdi._no_child_windows() ) {
      _cmdline._set_focus();
   } else {
      _mdi.p_child._set_focus();
   }

   //say('ctl_close.lbutton_up: tbwid='tbwid);
   if( tbwid>0 ) {
      //say('ctl_close.lbutton_up: tbwid.p_name='tbwid.p_name);
      tbClose(tbwid);
   } else {
      // Odd case of no embedded tool window, so clean this mess up
      form_wid._delete_window();
   }
   return;
   // We are about to get destroyed so do not do
   // anything else!
}

void ctl_autohide.lbutton_up()
{
   //say('ctl_autohide.LBUTTON_UP: in');

   // Give some visual feedback. If it's not right, then it will
   // get fixed up when _tbpanelUpdateAllPanels() is called at
   // the end.
   p_active_form._tbpanelSetFocus(true);
   int wid = p_active_form._tbpanelFindActiveForm();
   int pic_index=_pic_pinout_mono;
   if( _tbIsAutoShownWid(wid) ) {
      pic_index=_pic_pinin_mono;
   } else {
      pic_index=_pic_pinout_mono;
   }
   if( ctl_autohide.p_picture!=pic_index ) {
      ctl_autohide.p_picture=pic_index;
   }

   // Toggle Auto Hide
   tbAutoHideToggle(wid);
   //p_active_form._tbpanelAutoHide();

   _tbpanelUpdateAllPanels();
}
