////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47131 $
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
#import "sstab.e"
#import "tbpanel.e"
#import "toolbar.e"
#endregion

_str _tabgroupFormName2ContainerName(_str formName)
{
   return ('_1_':+formName);
}

/**
 * Operates on active window which must be a SSTab control.
 * 
 * @param tabi (optional). Tab index. -1 specifies the active tab.
 * 
 * @return Window id (wid) of tool window at the given tab index.
 */
int _tabgroupFindActiveForm(int tabi= -1)
{
   if( p_object!=OI_SSTAB || tabi>=p_NofTabs ) {
      return 0;
   }
   int form_wid = 0;

   int container = 0;
   if( tabi<0 ) {
      // Active tab
      container=_getActiveWindow();
   } else {
      // Do things a little differently here so we do not have
      // to activate the tab we want the container for.
      SSTABCONTAINERINFO info;
      _getTabInfo(tabi,info);
      container = sstContainerByActiveOrder(info.order);
   }
   if( container>0 ) {
      int child = container.p_child;
      if( child>0 && child.p_object==OI_FORM ) {
         form_wid=child;
      }
   }
   return form_wid;
}

/**
 * 
 * @param tbflags        Bitwise flags. See TBFLAG_*.
 * @param resource_index
 * @param parent_wid     The parent_wid determines the behavior:
 *                       Case 1: p_object==OI_FORM && p_name=="_dock_palette_form" <br>
 *                         First tab of tabgroup, so create tab
 *                         control with p_HideTabRow=true inside
 *                         of a panel.
 *                       Case 2: p_object==OI_SSTAB <br>
 *                         Tab control already exists, so add tool window into
 *                         new tab.
 * 
 * @return Window id of loaded tool window.
 */
int _tbLoadTemplateIntoTabGroup(int tbflags, int resource_index,
                                int parent_wid)
{
   int tbwid = 0;
   if( parent_wid.p_object==OI_FORM ) {

      if( parent_wid.p_name=="_dock_palette_form" ) {
         // Case 1: p_object==OI_FORM && p_name=="_dock_palette_form"
         //   First tab of tabgroup, so create tab control with p_HideTabRow=true inside of panel.

         int orig_wid = p_window_id;

         //say('_tbLoadTemplateIntoTabGroup: case 1');
         // Create an empty panel
         int panel_wid = 0;
         _tbLoadTemplateIntoPanel(tbflags,0,parent_wid,panel_wid);

         // Create an embedded tabgroup tab control. Do not worry about
         // geometry of the tab control because that will be handled in
         // the panel's on_resize() event later. There will be no flashing
         // because we create it invisible.
         int width = parent_wid.p_width;
         int height = parent_wid.p_height;
         // Note: SSTab is created with p_Noftabs==0
         int tabgroup_wid = _create_window(OI_SSTAB,panel_wid,"",0,0,width,height,CW_HIDDEN|CW_CHILD);
         // Hide the tab row until we have more than 1 tab
         tabgroup_wid.p_HideTabRow = true;
         tabgroup_wid.p_eventtab = defeventtab _tabgroup_etab;
         tabgroup_wid.p_eventtab2 = defeventtab _ul2_sstabb;
         tabgroup_wid.p_mouse_pointer = MP_DEFAULT;
         tabgroup_wid.p_BestFit = true;
         tabgroup_wid.p_Orientation = SSTAB_OBOTTOM;
         tabgroup_wid.p_PictureOnly = false;
         tabgroup_wid.p_DocumentMode = true;

         // Add the new tool window as next tab
         tabgroup_wid.p_NofTabs += 1;
         // Find the sstab_container wid of the tab we just added
         SSTABCONTAINERINFO info;
         tabgroup_wid._getTabInfo(tabgroup_wid.p_NofTabs-1,info);
         int sstab_container = tabgroup_wid.sstContainerByActiveOrder(info.order);
         //say('_tbLoadTemplateIntoTabGroup: sstab_container='sstab_container);
         //say('_tbLoadTemplateIntoTabGroup: sstab_container.p_object='sstab_container.p_object);
         // Load the the tool window as a child of the SSTab container
         tbwid=_load_template(resource_index,sstab_container,'HPN');
         // Each SSTab container's name is derived from the tool window it contains
         sstab_container.p_name=_tabgroupFormName2ContainerName(name_name(resource_index));
         tabgroup_wid.p_ActiveCaption=tbwid.p_caption;
         tabgroup_wid.p_ActivePicture=tbwid.p_picture;

         p_window_id=orig_wid;

      } else {
         // Should never get here
         _str msg = "_tbLoadTemplateIntoTabGroup: Toolbar internal error.\n\n":+
                    "Unknown p_name="parent_wid.p_name;
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }

   } else if( parent_wid.p_object==OI_SSTAB ) {
      // Case 2: p_object==OI_SSTAB
      //   Tab control already exists, so add tool window into
      //   new tab.
      //say('_tbLoadTemplateIntoTabGroup: case 3');

      int orig_wid = p_window_id;

      // Add the new tool window as next tab
      parent_wid.p_NofTabs += 1;
      if( parent_wid.p_NofTabs > 1 ) {
         // Make the tab row visible now that we have more than 1 tab
         parent_wid.p_HideTabRow=false;
      }
      SSTABCONTAINERINFO info;
      parent_wid._getTabInfo(parent_wid.p_NofTabs-1,info);
      int sstab_container = parent_wid.sstContainerByActiveOrder(info.order);
      tbwid=_load_template(resource_index,sstab_container,'HPN');
      // Each SSTab container's name is derived from the tool window it contains
      sstab_container.p_name=_tabgroupFormName2ContainerName(name_name(resource_index));
      parent_wid.p_ActiveCaption=tbwid.p_caption;
      parent_wid.p_ActivePicture=tbwid.p_picture;

      // The panel this tabgroup exists inside of already exists,
      // so the SSTab will not get resized unless we explicitly
      // resize the panel here.
      // Note:
      // At this point we could assume that, because the tabgroup already
      // exists, we do not have to resize the panel. We will do it anyway
      // just to be safe.
      int panel_wid = _tbFindParentPanel(tbwid);
      if( panel_wid>0 ) {
         panel_wid.call_event(panel_wid,ON_RESIZE,'W');
      }

      p_window_id=orig_wid;

   } else {
      // Should never get here
      _str msg = "_tbLoadTemplateIntoTabGroup: Toolbar internal error.\n\n":+
                 "Unknown p_object="parent_wid.p_object;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return tbwid;
}

/**
 * From the tool window wid, find the parent SSTab container that the tool
 * window is a child of.
 * 
 * @param wid Window id of tool window.
 * 
 * @return SSTab container wid, or 0 if the tool window is not a child of
 * a SSTab container.
 */
int _tbTabGroupContainerWidFromWid(int wid)
{
   //_StackDump();
   int tabcontainer_wid = 0;
   if( wid>0 ) {

      int parent = wid.p_parent;
      if( parent>0 && parent.p_object==OI_SSTAB_CONTAINER ) {

         // Each tab container has p_name derived from the name of tool window it contains
         if( parent.p_name==_tabgroupFormName2ContainerName(wid.p_name) ) {
            tabcontainer_wid=parent;
         }
      }
   }
   return tabcontainer_wid;
}

/**
 * From the tool window wid, find the parent SSTab control wid for the tabgroup.
 * Since a tabgroup with only 1 tool window does not have a tab control, this
 * function will return the panel wid in that case.
 * 
 * @param wid Window id of tool window.
 * 
 * @return Tabgroup tab control wid, or the panel wid in the case of only
 * 1 tool window in the tabgroup.
 */
int _tbTabGroupWidFromWid(int wid)
{
   int tabgroup_wid = 0;
   if( wid>0 ) {
      int tabcontainer_wid = _tbTabGroupContainerWidFromWid(wid);
      if( tabcontainer_wid>0 ) {
         int parent = tabcontainer_wid.p_parent;
         if( parent>0 && parent.p_object==OI_SSTAB ) {
            tabgroup_wid=parent;
         }

      } else {
         tabgroup_wid=_tbFindParentPanel(wid);
      }
   }
   return tabgroup_wid;
}


/**
 * From the tabgroup number, find the SSTab control wid for the tabgroup.
 * Since a tabgroup with only 1 tool window does not have a tab control, this
 * function will return the panel wid in that case.
 * 
 * @param tabgroup Tabgroup number.
 * 
 * @return Tabgroup tab control wid, or the panel wid in the case of only
 * 1 tool window in the tabgroup.
 */
static int _tbTabGroupWidFromTabGroup(int tabgroup)
{
   int tabgroup_wid = 0;
   DockingArea area, first_i, last_i;
   if( _bbdockFindTabGroup(tabgroup,area,first_i,last_i) ) {
      tabgroup_wid=_bbdockTabGroupWid(&gbbdockinfo[area][first_i]);
   }
   return tabgroup_wid;
}

/**
 * Get the tabgroup of a tool window, docked or floating.
 * 
 * @param wid
 * 
 * @return Tabgroup of tool window.
 */
int _tbTabGroupFromWid(int wid)
{
   if( wid>0 ) {
      DockingArea area, i;
      int tabgroup, tabOrder;
      int tbflags;
      boolean hasEntireRow=false;
      boolean found = wid._tbGetActiveInfo(area,i,tbflags,hasEntireRow,tabgroup,tabOrder);
      if( found ) {
         return tabgroup;
      }
   }
   return 0;
}

/**
 * @return Is the given form in the same tab group as this form?
 * @param FormName
 * @param ThisForm
 */
boolean tbIsSameTabGroup(_str FormName, _str ThisForm="")
{
   if (ThisForm == "") {
      ThisForm = p_active_form.p_name;
   }

   int this_wid = _tbGetWid(ThisForm);
   int form_wid = _tbGetWid(FormName);
   if (form_wid > 0 && this_wid > 0) {
      boolean docked = (tbIsWidDocked(form_wid) && tbIsWidDocked(this_wid));
      return docked && (_tbTabGroupFromWid(form_wid) == _tbTabGroupFromWid(this_wid));
   }
   return false;
}

//
// _tabgroup_etab is used by tool window tab groups for tear-off tabs feature.
//

defeventtab _tabgroup_etab;


/**
 * Handles moving between tabs in a tabgroup.
 */
void _tabgroup_etab.'c-tab','s-c-tab'()
{
   call_event(defeventtab _ainh_dlg_manager,last_event(),'e');
}

// Gap between the tool-window form and the tab-container in pixels
#define TABGAP_XY 0

static void _tabgroupOnResize()
{
   int startTab = 0;
   int endTab = p_NofTabs-1;

   // Resize ONLY the active tab's tool window
   // Note:
   // Only doing the resize for the active tab means
   // that when we destroy the panel (e.g. exit the
   // editor, etc.), the size of the non-active tool windows
   // would not be correct. Since a tab-linked tool window
   // gets saved with the dimensions of the panel this is
   // not important.
   boolean onlyActiveTab = true;
   if( onlyActiveTab ) {
      startTab=endTab=p_ActiveTab;
   }

   SSTABCONTAINERINFO info;
   int i;
   for( i=startTab; i <= endTab; ++i ) {
      _getTabInfo(i,info);
      int container = sstContainerByActiveOrder(info.order);
      if( container>0 ) {
         int child = container.p_child;
         if( child>0 && child.p_object==OI_FORM ) {
            int new_x = (-child._frame_width() + TABGAP_XY) * _twips_per_pixel_x();
            int new_y = (-child._frame_width() + TABGAP_XY) * _twips_per_pixel_y();
            int new_width = container.p_width - 2*new_x;
            int new_height = container.p_height - 2*new_y;
            boolean resize = false;
            if( new_x!=child.p_x ) {
               child.p_x=new_x;
               child.p_y=new_y;
               resize=true;
            }
            if( new_width!=child.p_width ) {
               child.p_width=new_width;
               resize=true;
            }
            if( new_height!=child.p_height ) {
               child.p_height=new_height;
               resize=true;
            }
            if( resize ) {
               child.call_event(child,ON_RESIZE,'W');
            }
         }
      }
   }
}

void _tabgroup_etab.on_resize()
{
   //say('_tabgroup_etab.ON_RESIZE: in');
   _tabgroupOnResize();
}

void _tabgroup_etab.on_destroy()
{
   //say('_tabgroup_etab.ON_DESTROY: in');
   // Note:
   // ON_DESTROY can be called from _tbpanel_form.ON_DESTROY.
   int i;
   for( i=0; i<p_NofTabs; ++i ) {
      int form_wid = _tabgroupFindActiveForm(i);
      if( form_wid>0 ) {
         form_wid.call_event(form_wid,ON_DESTROY,'W');
      }
   }
}

void _tabgroup_etab.on_change(int reason)
{
   //say('_tabgroup_etab.ON_CHANGE: in - reason='reason);
   if( !_tbpanelIsPanel(p_active_form) ) {
      return;
   }
   if( reason==CHANGE_TABACTIVATED ) {
      // Only the active tab is resized (more efficient),
      // so we need to resize now.
      _tabgroupOnResize();
      p_active_form._tbpanelUpdate(1);
      // Just in case
      p_active_form._tbpanelSetFocus(true);
   }
}

void _tabgroup_etab.rbutton_up()
{
   if( p_object!=OI_SSTAB ) {
      // Fail quietly
      return;
   }

   // Make sure the tab we clicked on is the active tab
   int tabi = mou_tabid();
   if( tabi<0 ) {
      // Did not click on tab.
      // Probably clicked in the area to the right of the tab, so
      // show the toolbar context menu because they probably want
      // to show a toolbar.
      _tbContextMenu();
      return;
   }
   if( p_ActiveTab!=tabi ) {
      p_ActiveTab=tabi;
   }

   // Set "focus" to this panel for visual feedback
   _tbpanelUpdateAllPanels();
   p_active_form._tbpanelSetFocus(true);

   // Show context menu for this tab
   int tbwid = _tabgroupFindActiveForm();
   if( tbwid>0 ) {
      // Calling with '1' for arg(1) so that we do not list
      // toolbars.
      tbwid._tbContextMenu(false);
      //tbwid.call_event(1,defeventtab _toolbar_etab2,RBUTTON_UP,'E');
   }
}

void _tabgroup_etab.lbutton_double_click()
{
   //say('_tabgroup_etab.LBUTTON_DOUBLE_CLICK: in');
   if( p_object!=OI_SSTAB ) {
      // Fail quietly
      return;
   }
   int tabi = mou_tabid();
   if( tabi<0 ) {
      // Did not click on a tab
      return;
   }
   // LBUTTON_DOUBLE_CLICK event is called _after_ the tab
   // is activated, so it is safe to operate on the active
   // tab now (i.e. we do not need to find it).
   int tbwid = _tabgroupFindActiveForm();
   tbFloatingToggle(tbwid);
}

/**
 * Used to: <br>
 * <ol>
 *   <li>
 *     Activate the tool window tab-linked in the selected tab.
 *   </li>
 *   <li>
 *     Use the mouse to drag the active tab to a new tab order
 *     in the tab control.
 *   </li>
 * </ol>
 */
void _tabgroup_etab.lbutton_down()
{
   //say('_tabgroup_etab.LBUTTON_DOWN: in');
   // If the current window is not a tab control, then find it
   int first_wid = p_window_id;
   int ctlsstab = first_wid;
   while( ctlsstab.p_object!=OI_SSTAB ) {
      ctlsstab=ctlsstab.p_next;
      if( ctlsstab==first_wid ) break;
   }
   if( ctlsstab.p_object!=OI_SSTAB ) {
      // Fail quietly
      return;
   }
   // Use mou_tabid() instead of p_ActiveTab since the tab
   // we clicked could be disabled, in which case it would
   // not have been made active. We _want_ to be able to
   // drag-drop and change the active order of the tab we
   // _clicked_ on; otherwise you see really strange results
   // like the wrong tab changing order, etc.
   int tabi = ctlsstab.mou_tabid();
   if( tabi<0 ) {
      // Not clicking on a tab, so bail.
      // Probably clicked on horizontal scroll arrow.
      return;
   }
   boolean wasDisabled = false;
   if( tabi!=ctlsstab.p_ActiveTab ) {
      wasDisabled=true;
   } else {
      // There are cases where a disabled tab will be active.
      // For example: dragging a tool window into a tabgroup.
      wasDisabled= ( !ctlsstab.p_ActiveEnabled );
   }
   if( wasDisabled ) {
      // Temporarily make the disabled tab active in order
      // to safely perform operations (i.e. drag-drop, order change).
      ctlsstab._setEnabled(tabi,(int)true);
      if( tabi!=ctlsstab.p_ActiveTab ) {
         ctlsstab.p_ActiveTab=tabi;
      }
   }

   // The LBUTTON_DOWN is processed after the tab is activated,
   // so it is safe to get the tab-linked tool window now.
   int tbwid = ctlsstab._tabgroupFindActiveForm();
   if( tbwid==0 ) {
      // How did we get here?
      return;
   }
   if( wasDisabled ) {
      // Normally, a disabled tab's contents are not visible, so
      // make the tool window temporarily invisible; otherwise it
      // looks a little strange.
      tbwid.p_visible=false;
   }
   DockingArea area = tbwid.p_DockingArea;

   // The tabgroup number for this tabgroup so we know what to sort
   // later if the tab order is changed.
   int tabgroup = _tbTabGroupFromWid(tbwid);

   // Set active caption to give user visual feedback
   _tbpanelUpdateAllPanels();
   int container_wid = _tbContainerFromWid(tbwid);
   if( container_wid>0 ) {
      container_wid._containerUpdate();
   }
   //p_active_form._tbpanelSetFocus(true);

   //say('_tabgroup_etab.lbutton_down: tabi='tabi'  p_ActiveCaption='ctlsstab.p_ActiveCaption);
   //SSTABCONTAINERINFO info;
   //ctlsstab._getTabInfo(tabi,info);
   //int orig_tabo = info.order;
   int orig_tabo = ctlsstab.p_ActiveOrder;
   //say('_tabgroup_etab.lbutton_down: entering tab control');
   // Current tab order
   int tabo = orig_tabo;
   // Last tab order so we can tell if we have moved the mouse to another tab
   int last_tabo = orig_tabo;

   mou_mode(1);
   container_wid.mou_capture(1);
   boolean done = false;
   _str e = MOUSE_MOVE;
   for( ;; ) {

      switch( e ) {
      case MOUSE_MOVE:
         //int mx, my;
         //mou_get_xy(mx,my);
         //say('_tabgroup_etab.lbutton_down: mx='mx'  my='my);
         last_tabo=tabo;
         tabi=ctlsstab.mou_tabid();
         if( tabi<0 ) {
            // We have moved ouside the tab control
            //say('_tabgroup_etab.lbutton_down: exiting tab control');
            done=true;

         } else {
            SSTABCONTAINERINFO info;
            ctlsstab._getTabInfo(tabi,info);
            tabo = info.order;
            //say('_tabgroup_etab.lbutton_down: tabo='tabo'  last_tabo='last_tabo);
            if( tabo != last_tabo ) {
               // Change the order of the active tab to be at tab index under the mouse
               ctlsstab.p_ActiveOrder = tabo;
            }
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
      e=get_event();
   }
   mou_mode(0);
   container_wid.mou_release();

   if( e==LBUTTON_UP || e==ESC ) {
      // User cancelled OR was activating the tab OR was changing
      // the tab order, so set caption active.
      if( ctlsstab.p_ActiveOrder!=orig_tabo ) {

         if( e==LBUTTON_UP ) {
            // Tab order changed, so must sort gbbdockinfo[][] to match new order
            _bbdockSortTabGroupByActiveOrder(tabgroup,area);
            // Re-arranging gbbdockinfo[][] messed up the .sizebarAfterWid members,
            // so fix it.
            // Explanation:
            // Only the _last_ tab-linked tool window should have a sizebar.
            _mdi._bbdockAddRemoveSizeBars(area);
            _mdi._bbdockRefresh(area);

         } else if( e==ESC ) {
            // User cancelled, so put tab order back
            ctlsstab.p_ActiveOrder=orig_tabo;
         }
      }
      // Set focus to active tab-linked tool window
      if( tbwid>0 ) {
         tbwid._set_focus();
      }
      _tbpanelUpdateAllPanels();
      container_wid._tbpanelSetFocus(true);
      if( wasDisabled ) {
         tbwid.p_visible=true;
         ctlsstab.p_ActiveEnabled=false;
      }
      return;
   }
   //say('_tabgroup_etab.lbutton_down: mou_tabid='mou_tabid());
   if( ctlsstab.mou_tabid() < 0 ) {
      // We dragged outside the tab row, so go into drag-drop mode
      DockOperation dop;
      _dockOpInit(dop,tbwid);
      _dockOpDragDropExecute(dop);
      if( dop.newarea<0 ) {
         if( ctlsstab.p_ActiveOrder!=orig_tabo ) {
            // Put tab order back
            ctlsstab.p_ActiveOrder=orig_tabo;
         }
         // User cancelled
         if( wasDisabled ) {
            tbwid.p_visible=true;
            ctlsstab.p_ActiveEnabled=false;
         }
      }
   }
}
