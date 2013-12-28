////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44490 $
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
#import "main.e"
#import "stdprocs.e"
#endregion

/**
 * Retrieves the caption from a tab in a tab control.
 * 
 * @param tabNumber           which tab to retrieve information for (0 - 
 *                            p_NofTabs - 1)
 * 
 * @return _str               caption of tab
 *
 * @appliesTo  SSTab
 *
 * @categories SSTab_Methods
 */
_str sstGetTabCaption(int tabNumber)
{
   _str result = '';
   SSTABCONTAINERINFO info;
   if( _getTabInfo(tabNumber,info) ) {
      result = info.caption;
   }
   return result;
}

/**
 * Retrieves all captions from tabs in a tab control.
 * 
 * @param tabCaptions  (out) Tab captions array indexed by tab 
 *                     number.
 *
 * @appliesTo  SSTab
 *
 * @categories SSTab_Methods
 */
void sstGetAllTabCaptions(_str (&tabCaptions)[])
{
   int i, n=p_NofTabs;
   for( i=0; i < n; ++i ) {
      tabCaptions[tabCaptions._length()] = sstGetTabCaption(i);
   }
}

/**
 * Find the tab in the current tab control window that matches
 * specified caption. Matching is case-insensitive by default. 
 * 
 * @param caption  Caption to match.
 * @param caseSensitive  Set to true for case-sensitive 
 *                       matching. Defaults to false.
 * 
 * @return Tab-index of matching tab if found, -1 if not found.
 */
int sstFindTab(_str caption, boolean caseSensitive=false)
{
   int result = -1;
   int i, n=p_NofTabs;
   for( i=0; i < n; ++i ) {
      if( !caseSensitive && strieq(caption,sstGetTabCaption(i)) ) {
         result = i;
         break;
      } else if( caption :== sstGetTabCaption(i) ) {
         result = i;
         break;
      }
   }
   return result;
}

/**
 * Find and activate the tab in the current tab control window
 * that matches specified caption. Matching is case-insensitive 
 * by default. 
 * 
 * @param caption  Caption to match.
 * @param caseSensitive  Set to true for case-sensitive 
 *                       matching. Defaults to false.
 * 
 * @return true on success, false if tab not found.
 */
boolean sstActivateTabByCaption(_str caption, boolean caseSensitive=false)
{
   int index = sstFindTab(caption,caseSensitive);
   if( index >= 0 ) {
      p_ActiveTab = index;
   }
   return ( index >= 0 ? true : false );
}

/**
 * Test whether a tab exists in the current tab control window 
 * that matches specified caption. Matching is case-insensitive 
 * by default. 
 * 
 * @param caption  Caption to match.
 * @param caseSensitive  Set to true for case-sensitive 
 *                       matching. Defaults to false.
 * 
 * @return true if caption matches a tab in the tab control.
 */
boolean sstTabExists(_str caption, boolean caseSensitive=false)
{
   return ( sstFindTab(caption,caseSensitive) != -1 );
}

/**
 * Retrieves the help from a tab in a tab control.
 * 
 * @param tabNumber           which tab to retrieve information for (0 - 
 *                            p_NofTabs - 1)
 * 
 * @return _str               help of tab
 *
 * @appliesTo  SSTab
 *
 * @categories SSTab_Methods
 */
_str sstGetTabHelp(int tabNumber)
{
   _str result = '';
   SSTABCONTAINERINFO info;
   if( _getTabInfo(tabNumber,info) ) {
      result = info.help;
   }
   return result;
}

/**
 * Retrieves the tooltip from a tab in a tab control.
 * 
 * @param tabNumber           which tab to retrieve information for (0 - 
 *                            p_NofTabs - 1)
 * 
 * @return _str               tooltip of tab
 *
 * @appliesTo  SSTab
 *
 * @categories SSTab_Methods
 */
_str sstGetTabToolTip(int tabNumber)
{
   _str result = '';
   SSTABCONTAINERINFO info;
   if( _getTabInfo(tabNumber,info) ) {
      result = info.tooltip;
   }
   return result;
}

static void sstab_after_switch_tab()
{
   if( !p_tab_stop ) {
      int focus = _get_focus();
      if( focus &&
          (focus.p_object == OI_TEXT_BOX || focus.p_object == OI_COMBO_BOX) &&
          focus.p_auto_select ) {

         focus._set_sel(1,length(focus.p_text)+1);
      }
   }
}

defeventtab _ul2_sstabb;
void _ul2_sstabb.left,'C-J','C-S-TAB'()
{
   int active, newActive;
   int count;
   newActive = -1;
   active = p_ActiveTab;
   count = p_NofTabs;
   if ( count < 2 ) return;

   int oriActive = active;
   while( true ) {
      if( active == 0 ) {
         newActive = count - 1;
      } else {
         newActive = active - 1;
      }
      if( newActive == oriActive ) {
         return;
      }

      // Make sure next tab is enabled:
      SSTABCONTAINERINFO info;
      _getTabInfo(newActive,info);
      if( info.enabled ) {
         break;
      }
      active = newActive;
   }

   if( newActive < 0 ) {
      return;
   }
   p_ActiveTab = newActive;
   sstab_after_switch_tab();
   if( _jaws_mode() ) {
      _set_focus();
   }
}

void _ul2_sstabb.right,'C-L','C-TAB'()
{
   int active, newActive;
   int count;
   newActive = -1;
   active = p_ActiveTab;
   count = p_NofTabs;
   if( count < 2 ) {
      return;
   }

   int oriActive = active;
   while( true ) {
      if( active == (count-1) ) {
         newActive = 0;
      } else {
         newActive = active + 1;
      }
      if( newActive == oriActive) {
         return;
      }

      // Make sure next tab is enabled
      SSTABCONTAINERINFO info;
      _getTabInfo(newActive,info);
      if( info.enabled ) {
         break;
      }
      active = newActive;
   }
   if( newActive < 0 ) {
      return;
   }
   p_ActiveTab = newActive;
   sstab_after_switch_tab();
   if( _jaws_mode() ) {
      p_window_id._set_focus();
   }
}

/**
 * Returns the tab control tab-index under the specified global 
 * (x,y) coordinates. Specify (-1,-1) for current mouse 
 * coordinates. 
 *
 * @param x
 * @param y
 *
 * @return Tab-index or -1 if not over a tab.
 */
int mou_tabid(int x = -1, int y = -1)
{
   if( x < 0 || y < 0 ) {
      mou_get_xy(x,y);
   }

   int location = _xyHitTest(x,y);
   return location;
}

/**
 * Operates on the active object which must be a SSTab control.
 * <p>
 * Get the SSTab container wid for tab order given. Use _getTabInfo
 * to get the tab order number for a tab index.
 * 
 * @param tabo Tab order number.
 * 
 * @return Window id of SSTab container, or 0 if not found.
 * 
 * @see _getTabInfo
 */
int sstContainerByActiveOrder(int tabo)
{
   if( p_object!=OI_SSTAB || p_NofTabs<1 ) {
      return 0;
   }
   int first_child = p_child;
   int child = first_child;
   for( ;; ) {

      if( child.p_ActiveOrder==tabo ) {
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

/**
 * Operates on the active object which must be a SSTab control.
 * <p>
 * Get the SSTab container wid matching name property given.
 * 
 * @param name Name property to match with p_name of container.
 * 
 * @return Window id of SSTab container, or 0 if not found.
 */
int sstContainerByName(_str name)
{
   if( p_object != OI_SSTAB || p_NofTabs < 1 ) {
      return 0;
   }
   int first_child = p_child;
   int child = first_child;
   while( true ) {

      if( child.p_name == name ) {
         return child;
      }
      child = child.p_next;
      if( child == first_child ) {
         break;
      }
   }
   // Not found
   return 0;
}

void _ul2_sstabb.on_change2(int reason)
{
   switch (reason) {
   case CHANGE_TAB_DROP_DOWN_CLICK:
      // we need to build a menu with all our tab names as items
      sstDropDownList(sstGetTabInfoForDropDownList);
      break;
   }
}

void sstDropDownList(typeless pfnGetTabInfoCallback)
{
   menuName := '_temp_sstab_drop_down_menu';

   // see if the menu is already open
   index := find_index(menuName,oi2type(OI_MENU));
   if( index > 0 ) {
      // yes!  just toggle it off, don't reshow it
      delete_name(index);
      return;
   }

   index = insert_name("_temp_sstab_drop_down_menu",oi2type(OI_MENU));

   // go through the list of tabs and add each caption to our menu
   _str tabCaptions[];
   for( i:=0; i < p_NofTabs; ++i ) {

      _str tabCaption, tabToolTip;
      (*pfnGetTabInfoCallback)(i,tabCaption,tabToolTip);

      tabCaptions[i] = '"'tabCaption'" "'tabToolTip'" 'i;
   }

   tabCaptions._sort('I');

   for( i=0; i < tabCaptions._length(); ++i ) {
      parse tabCaptions[i] with . '"' auto tabCaption '"' '"' auto tabToolTip '"' auto tabNum;

      _menu_insert(index,-1,0,tabCaption,"sstDropDownListSelectTab "tabNum, "","",tabToolTip);
   }

   int menu_handle = p_active_form._menu_load(index,'P');
   // Show the menu
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags = VPM_RIGHTALIGN|VPM_LEFTBUTTON;
   int status = _menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
}

void sstGetTabInfoForDropDownList(int tabNum, _str& tabCaption, _str& tabToolTip)
{
   SSTABCONTAINERINFO info;
   if( _getTabInfo(tabNum,info) ) {
      tabCaption = info.caption;
      tabToolTip = info.tooltip;
   } else {
      tabCaption = '';
      tabToolTip = '';
   }
}

_command void sstDropDownListSelectTab(int newActiveTab = -1) name_info(',')
{
   if( newActiveTab >= 0 && newActiveTab < p_NofTabs ) {
      p_ActiveTab = newActiveTab;
      call_event(CHANGE_TABACTIVATED,p_window_id,ON_CHANGE,'W');
   }
}

/**
 * When using the SSTab control as a simple TabBar (i.e. no 
 * contents), some platforms (Mac OSX) require a one-time height
 * adjustment. 
 *
 * <p>
 *
 * Note that _SetDialogInfoHt() is used to set whether the 
 * adjustment has already been done, so do not use p_user raw 
 * because it will be overwritten. 
 */
void sstAdjustHeightForNoContent()
{
#if __MACOSX__
   // MacOSX will leave a sliver of Tab content area, so size the tab control
   // once to eliminate it.
   if( p_NofTabs > 0 ) {
      typeless heightAdjustDone = _GetDialogInfoHt('heightAdjustDone');
      heightAdjustDone = (heightAdjustDone == null ? false : heightAdjustDone);
      if( !heightAdjustDone ) {
         SSTABCONTAINERINFO tabInfo;
         // Use the ActiveTab since it might be taller
         _getTabInfo(p_ActiveTab,tabInfo);
         // _getTabInfo() gives Tab rect in screen coordinates
         _map_xy(0,p_window_id,tabInfo.tx,tabInfo.ty);
         _map_xy(0,p_window_id,tabInfo.bx,tabInfo.by);
         tabInfo.ty = _dy2ly(p_xyscale_mode,tabInfo.ty);
         tabInfo.by = _dy2ly(p_xyscale_mode,tabInfo.by);
         p_height = tabInfo.by - tabInfo.ty + _dy2ly(p_xyscale_mode,1);
         _SetDialogInfoHt('heightAdjustDone',true);
      }
   }
#endif
}
