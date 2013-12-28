////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46194 $
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
#require "sc/util/Rect.e"
#import "dlgman.e"
#import "files.e"
#import "picture.e"
#import "stdprocs.e"
// main.e for nls()
#import "main.e"
#endregion


// -1 is for the get_event() timer, so use -2
int gDockChannelMouseOverTimer = -2;
// Number of times we have called the timer callback inside the same window
static int gNumMouseOver = 0;
// The last window we were inside
static _str gLastMouseSid = "";

void _dcCtlMouseOverCallback();

/**
 * Save space in the dock channel.
 * <p>
 * <li>0 = Do not save space. All items are the size of longest item.
 * <li>1 = Save space by auto sizing items to just fit the picture and caption.
 * <li>2 = Save space by only showing caption on active item.
 */
static int gDockChannelSaveSpace = 1;

definit()
{
   if( arg(1)!='L' ) {
      gLastMouseSid="";
      gDockChannelMouseOverTimer= -2;
      // _dcCtlKillTimer does other initialization, so still makes sense to call it
      _dcCtlKillTimer();
      dockchanResetAll();
      if( def_dock_channel_delay>0 && def_dock_channel_delay<DOCKCHANNEL_TIMER_INTERVAL ) {
         // Too small
         def_dock_channel_delay=DOCKCHANNEL_AUTO_DELAY;
      }
   }
}


//
// Dock channel model
//

struct DCMODELINFO {

   // String id. It is up to the caller to make this unique.
   // If "", then represents a space.
   _str sid;

   // Picture index to display
   int pic;

   // Caption to display
   _str caption;

   // Indicates whether the picture is active
   boolean active;

   // Called when mouse enters item area
   pfnDockChanMouseInCallback pMouseInCallback;

   // Called when mouse exits item area
   pfnDockChanMouseOutCallback pMouseOutCallback;
};

// First index of this array is with DOCKINGAREA_* 1..4. 0 is null
DCMODELINFO gdcModelInfo[/* 1..4*/][];


static void _dcModelInsert(DockingArea area, int i,
                           _str sid, int pic, _str caption,
                           pfnDockChanMouseInCallback pMouseInCallback,
                           pfnDockChanMouseOutCallback pMouseOutCallback,
                           boolean spaceBefore=false)
{
   if( i<0 ) {
      // Insert at end
      i=gdcModelInfo[area]._length();
   }

   int ShiftAmount = 0;
   if( spaceBefore ) {
      ++ShiftAmount;
   }
   ++ShiftAmount;

   // Make room for new item
   int j;
   for( j=gdcModelInfo[area]._length()-1; j>=i; --j ) {
      gdcModelInfo[area][j+ShiftAmount]=gdcModelInfo[area][j];
   }

   DCMODELINFO* pdcminfo;

   if( spaceBefore ) {
      pdcminfo = &gdcModelInfo[area][i];
      pdcminfo->sid="";
      pdcminfo->pic=0;
      pdcminfo->caption="";
      pdcminfo->pMouseInCallback=null;
      pdcminfo->pMouseOutCallback=null;
      pdcminfo->active=false;
      ++i;
   }

   // Insert into model
   pdcminfo = &gdcModelInfo[area][i];
   pdcminfo->sid=sid;
   pdcminfo->pic=pic;
   pdcminfo->caption=caption;
   pdcminfo->pMouseInCallback=pMouseInCallback;
   pdcminfo->pMouseOutCallback=pMouseOutCallback;
   pdcminfo->active=false;
}

static void _dcModelRemove(DockingArea area, int i)
{
   gdcModelInfo[area]._deleteel(i);
}

static void _dcModelRemoveAll()
{
   int area;
   for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area ) {
      gdcModelInfo[area]._makeempty();
   }
}

/**
 * Guarantee we do not have more than 2 adjacent spaces (sid==""),
 * or spaces at beginning/end of side.
 * 
 * @param area
 */
static void _dcModelAdjustSpaces(DockingArea area)
{
   // Strip spaces at beginning
   while( gdcModelInfo[area]._length()>0 && gdcModelInfo[area][0].sid=="" ) {
      gdcModelInfo[area]._deleteel(0);
   }

   // Strip multiple spaces between items
   int i;
   for( i=0; i<gdcModelInfo[area]._length(); ) {

      if( gdcModelInfo[area][i].sid=="" ) {

         if( (i+1) < gdcModelInfo[area]._length() && gdcModelInfo[area][i+1].sid=="" ) {
            gdcModelInfo[area]._deleteel(i+1);
            continue;
         }
      }
      ++i;
   }

   // Strip spaces at end
   while( gdcModelInfo[area]._length()>0 &&
          gdcModelInfo[area][gdcModelInfo[area]._length()-1].sid=="" ) {

      gdcModelInfo[area]._deleteel(gdcModelInfo[area]._length()-1);
   }
}

static boolean _dcModelFind(_str sid, DockingArea& area, int& i)
{
   if( sid=="" ) {
      // Forget it
      return false;
   }
   int area_i;
   for( area_i=DOCKINGAREA_FIRST; area_i<=DOCKINGAREA_LAST; ++area_i ) {

      for( i=0; i<gdcModelInfo[area_i]._length(); ++i ) {

         if( sid==gdcModelInfo[area_i][i].sid ) {
            // Found it
            area = (DockingArea)area_i;
            return true;
         }
      }
   }
   // Not found
   return false;
}

static boolean _dcModelFindGroup(_str sid, int& area, int& i, int& first_i, int& last_i, int startSide=DOCKINGAREA_FIRST)
{
   if( sid=="" ) {
      // Forget it
      return false;
   }

   if( startSide<DOCKINGAREA_FIRST || startSide>DOCKINGAREA_LAST ) {
      return false;
   }
   DockingArea area_first = startSide;
   for( area=area_first;; ) {

      for( i=0; i<gdcModelInfo[area]._length(); ++i ) {

         if( sid==gdcModelInfo[area][i].sid ) {
            // Found it, now back up and find the first one in the group
            first_i=i;
            for( ; (first_i-1)>=0; --first_i ) {
               if( gdcModelInfo[area][first_i-1].sid=="" ) {
                  break;
               }
            }
            // Now move forward and find the last on in the group
            last_i=i;
            for( ; (last_i+1)<gdcModelInfo[area]._length(); ++last_i ) {
               if( gdcModelInfo[area][last_i+1].sid=="" ) {
                  break;
               }
            }
            return true;
         }
      }
      ++area;
      if( area>DOCKINGAREA_LAST ) {
         area=DOCKINGAREA_FIRST;
      }
      if( area==area_first ) {
         // Done
         break;
      }
   }
   // Not found
   return false;
}

static void _dcModelSetActive(_str sid, boolean active)
{
   DockingArea area, i;
   if( _dcModelFind(sid,area,i) ) {
      gdcModelInfo[area][i].active=active;
   }
}

static void _dcModelSetActiveInGroup(_str sid, boolean active)
{
   DockingArea area, i, first_i, last_i;
   if( _dcModelFindGroup(sid,area,i,first_i,last_i) ) {
      int j;
      for( j=first_i; j<=last_i; ++j ) {

         if( !active ) {
            // Set them all inactive
            gdcModelInfo[area][j].active=active;
         } else if( j==i ) {
            // This is the active item
            gdcModelInfo[area][j].active=active;
         } else {
            // This is not the active item, so set inactive
            gdcModelInfo[area][j].active=!active;
         }
      }
   }
}

static boolean _dcModelFindActive(DockingArea area, int& i)
{
   for( i=0; i<gdcModelInfo[area]._length(); ++i ) {

      if( gdcModelInfo[area][i].active ) {
         // Found the active item
         return true;
      }
   }
   // Not found
   return false;
}


//
// Dock channel view
//

#define DCVIEW_FRAMELESS_PICS 0

#if DCVIEW_FRAMELESS_PICS
   // Pixels. Gap in between pictures of the same group
   #define DCVIEW_GAP_XY 2
   // Border-style
   #define DCVIEW_PIC_BORDERSTYLE BDS_NONE
#else
   #define DCVIEW_GAP_XY 0
   #define DCVIEW_PIC_BORDERSTYLE BDS_ROUNDED
#endif

// Pixels. Width/height of the channel.
// Note: Dock-channel pictures are 16x16, so we have a 7 pixel gap.
#define DCVIEW_CHANNEL_WH 23
// Pixels. Gap in between groups of pictures and channel edge
#define DCVIEW_GROUPGAP_XY 10

#define DC_FORMNAME "_dock_channel_form"

static int _dcViewCreateChannel(DockingArea area)
{
   int dc_wid = _mdi._GetDockChannel(area);
   if( dc_wid==0 ) {
      // Create it
      int index = find_index(DC_FORMNAME,oi2type(OI_FORM));
      if( index<=0 ) {
         _str msg = get_message(VSRC_FORM_NOT_FOUND,"",DC_FORMNAME);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      _mdi._LoadDockChannel(index,area);
      dc_wid=_mdi._GetDockChannel(area);
#ifdef not_finished
      switch( area ) {
      case DOCKINGAREA_TOP:
         dc_wid.p_backcolor = _rgb(255,255,0);
         break;
      case DOCKINGAREA_LEFT:
         dc_wid.p_backcolor = _rgb(255,0,0);
         break;
      case DOCKINGAREA_RIGHT:
         dc_wid.p_backcolor = _rgb(0,255,0);
         break;
      case DOCKINGAREA_BOTTOM:
         dc_wid.p_backcolor = _rgb(0,0,255);
         break;
      }
#endif
   }
   return dc_wid;
}

static int _dcViewMaybeCreateChannel(DockingArea area)
{
   if( gdcModelInfo[area]._length() == 0 ) {
      // Nothing to do
      return 0;
   }

   int dc_wid = _dcViewCreateChannel(area);
   return dc_wid;
}

static void _dcViewRemoveChannel(DockingArea area)
{
   int dc_wid = _mdi._GetDockChannel(area);
   if( dc_wid!=0 ) {
      dc_wid._delete_window();
   }
}

static void _dcViewMaybeRemoveChannel(DockingArea area)
{
   if( 0==gdcModelInfo[area]._length() ||
       (gdcModelInfo[area]._length()==1 && gdcModelInfo[area][0].sid=="") ) {

      _dcViewRemoveChannel(area);
   }
}

/**
 * Clear all pics from a side, but do not remove the channel.
 * 
 * @param area
 */
static void _dcViewClear(DockingArea area)
{
   int dc_wid = _mdi._GetDockChannel(area);
   if( dc_wid==0 ) {
      // Nothing to do
      return;
   }
   int child = dc_wid.p_child;
   while( child>0 ) {
      child._delete_window();
      child=dc_wid.p_child;
   }
}

/**
 * Clear all pics from all sides, but do not remove channels.
 */
static void _dcViewClearAll()
{
   int area;
   for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area ) {
      _dcViewClear((DockingArea)area);
   }
}

static void _dcViewAdjustPics(DockingArea area)
{
   int dc_wid = _dcViewMaybeCreateChannel(area);
   if( dc_wid==0 ) {
      return;
   }

   // Create images where needed

   // The longest item with picture+caption. We size the active item
   // to this width/height in order to keep the mouse well inside
   // the item area without causing stupid behavior where the item
   // size keeps getting bigger as you move toward the trailing edge.
   int longest = 0;

   int i;
   for( i=0; i<gdcModelInfo[area]._length(); ++i ) {
      _str sid = gdcModelInfo[area][i].sid;
      if( sid!="" ) {

         int pic = gdcModelInfo[area][i].pic;
         _str caption = gdcModelInfo[area][i].caption;
         boolean active = gdcModelInfo[area][i].active;

         int picWid = _dcViewFind(sid,area);
         if( picWid==0 ) {
            int orig_wid = p_window_id;
            picWid=_create_window(OI_IMAGE,dc_wid,"",0,0,0,0,CW_CHILD|CW_HIDDEN,BDS_FIXED_SINGLE);
            p_window_id=orig_wid;

         } else {
            picWid.p_visible=false;
         }

         // This is how we know which sid is associated with the image
         picWid.p_user=sid;

         // Styles
         picWid.p_style=PSPIC_DEFAULT;
         //picWid.p_style=PSPIC_PARTIAL_BUTTON;
         picWid.p_border_style = DCVIEW_PIC_BORDERSTYLE;
         picWid.p_mouse_pointer=MP_DEFAULT;

#if __UNIX__
         // Color - dark shadow.
         // Note:
         // This is actually the color we use for disabled text, but it
         // is a little darker than the dark shadow color, so use it
         // instead.
         picWid.p_forecolor=0x80000011;
#else
         // Color - dark shadow
         picWid.p_forecolor=0x80000030;
#endif

         // Size.
         // Max out the size of this image and set auto-size to true
         // in order to get a sane size, then turn it off because
         // we may need to adjust sizes to contain the mouse cursor.
         // Orientation.
         // If on left/right, then orient vertical.
         // If on top/bottom, then orient horizontal.
         // 2/25/2005 - RB
         // We now show captions on all images, but we will keeep
         // this code around anyway in case we decide to make the
         // active caption bold or something similar that would
         // cause a size change, or we decide to make saving space
         // in the dock channel by only showing the caption on the
         // active item an option (gDockChannelSaveSpace).
         picWid.p_picture=pic;
         picWid.p_caption=caption;
         // Bold is a lot easier to see in the "gray" forecolor
         picWid.p_font_bold=true;
         picWid.p_auto_size=true;
         switch( area ) {
         case DOCKINGAREA_LEFT:
         case DOCKINGAREA_RIGHT:
            picWid.p_Orientation=PSPIC_OVERTICAL;
            if( picWid.p_height>longest ) {
               longest=picWid.p_height;
            }
            break;
         case DOCKINGAREA_TOP:
         case DOCKINGAREA_BOTTOM:
            picWid.p_Orientation=PSPIC_OHORIZONTAL;
            if( picWid.p_width>longest ) {
               longest=picWid.p_width;
            }
            break;
         }
         picWid.p_picture=0;
         picWid.p_caption="";
         picWid.p_auto_size=false;

         // Picture, caption
         picWid.p_picture=pic;
         if( picWid.p_picture==0 ) {
            // We have to see SOMETHING. Set the caption.
            picWid.p_caption=caption;
         } else {
            if( active ) {
               // We always show the caption on the active item
               picWid.p_caption=caption;

            } else if( gDockChannelSaveSpace==0 || gDockChannelSaveSpace==1 ) {
               // Show the picture AND picture.
               // IMPORTANT:
               // In order to center the picture inside the image control,
               // text is required, so set to 1 space.
               picWid.p_caption=caption;
            }
            if( picWid.p_caption:=="" ) {
               // IMPORTANT:
               // In order to center the picture inside the image control,
               // text is required, so set to 1 space.
               picWid.p_caption=" ";
            }
         }
         // Set to longest item we have seen so far
         picWid.p_auto_size=true;
         picWid.p_auto_size=false;
         if( active ) {
            switch( area ) {
            case DOCKINGAREA_LEFT:
            case DOCKINGAREA_RIGHT:
               if( gDockChannelSaveSpace==0 && longest>picWid.p_height ) {
                  // Size to longest item
                  picWid.p_height=longest;
               }
               break;
            case DOCKINGAREA_TOP:
            case DOCKINGAREA_BOTTOM:
               if( gDockChannelSaveSpace==0 && longest>picWid.p_width ) {
                  // Size to longest item
                  picWid.p_width=longest;
               }
               break;
            }
         }
      }
   }
   if( gDockChannelSaveSpace==0 ) {
      // One more pass through created images to set size of all items to longest
      int first_child = dc_wid.p_child;
      int child = first_child;
      while( child>0 ) {

         switch( area ) {
         case DOCKINGAREA_LEFT:
         case DOCKINGAREA_RIGHT:
            child.p_height=longest;
            break;
         case DOCKINGAREA_TOP:
         case DOCKINGAREA_BOTTOM:
            child.p_width=longest;
            break;
         }
         child=child.p_next;
         if( child==first_child ) {
            break;
         }
      }
   }
}

/**
 * Adjust position of images in view and space between images on a side.
 * Call _dcViewAdjustPics before calling this function to have the
 * images created.
 * 
 * @param area
 */
static void _dcViewAdjustSpaces(DockingArea area)
{
   int dc_wid = _dcViewMaybeCreateChannel(area);
   if( dc_wid==0 ) {
      return;
   }
   int clientW = _dx2lx(SM_TWIP,dc_wid.p_client_width);
   int clientH = _dy2ly(SM_TWIP,dc_wid.p_client_height);

   // All pictures should be same height
   int picH = 0;
   // The amount to adjust in order to truncate the relative-bottom
   // of an item. This makes it appear like a Tab.
   int adjust = 0;
   if( gdcModelInfo[area]._length() > 0 ) {
      _str sid = gdcModelInfo[area][0].sid;
      int picWid = _dcViewFind(sid,area);
      if( picWid > 0 ) {
         if( area == DOCKINGAREA_TOP || area == DOCKINGAREA_BOTTOM ) {
            picH = picWid.p_height;
            adjust = (picH - 16*_twips_per_pixel_y()) intdiv 2;
         } else if( area == DOCKINGAREA_LEFT || area == DOCKINGAREA_RIGHT ) {
            picH = picWid.p_width;
            adjust = (picH - 16*_twips_per_pixel_x()) intdiv 2;
         }
      }
   }

   // Adjust spacing
   int next_x = 0;
   int next_y = 0;
   switch( area ) {
   case DOCKINGAREA_TOP:
      next_x = 1 * _twips_per_pixel_x();
      next_y = -adjust;
      break;
   case DOCKINGAREA_BOTTOM:
      next_x = 1 * _twips_per_pixel_x();
      next_y = clientH - picH + adjust;
      if( next_y<0 ) {
         next_y=0;
      }
      break;
   case DOCKINGAREA_LEFT:
      next_x = -adjust;
      next_y = _twips_per_pixel_y() * 1;
      break;
   case DOCKINGAREA_RIGHT:
      next_x = clientW - picH + adjust;
      if( next_x < 0 ) {
         next_x = 0;
      }
      next_y = 1 * _twips_per_pixel_y();
      break;
   }
   int i;
   for( i=0; i<gdcModelInfo[area]._length(); ++i ) {
      _str sid = gdcModelInfo[area][i].sid;
      if( sid!="" ) {

         int picWid = _dcViewFind(sid,area);
         if( picWid==0 ) {
            // How did we get here?
            continue;
         }
         picWid._move_window(next_x,next_y,picWid.p_width,picWid.p_height);
         // Set up for next pic
         if( area==DOCKINGAREA_LEFT || area==DOCKINGAREA_RIGHT ) {
            // Back it up so next image border is right on top of the previous
            next_y += picWid.p_height - 1*picWid._frame_width()*_twips_per_pixel_y() + DCVIEW_GAP_XY*_twips_per_pixel_y();
         } else if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
            // Back it up so next image border is right on top of the previous
            next_x += picWid.p_width - 1*picWid._frame_width()*_twips_per_pixel_x() + DCVIEW_GAP_XY*_twips_per_pixel_x();
         }

      } else {
         // Space
         if( area==DOCKINGAREA_LEFT || area==DOCKINGAREA_RIGHT ) {
            next_y += DCVIEW_GROUPGAP_XY*_twips_per_pixel_y();
         } else if( area==DOCKINGAREA_TOP || area==DOCKINGAREA_BOTTOM ) {
            next_x += DCVIEW_GROUPGAP_XY*_twips_per_pixel_x();
         }
      }
   }
}

static void _dcViewSetVisible(DockingArea area)
{
   int dc_wid = _mdi._GetDockChannel(area);
   if( dc_wid==0 ) {
      // Nothing to do
      return;
   }
   int first_child = dc_wid.p_child;
   int child = first_child;
   while( child>0 ) {

      if( !child.p_visible ) {
         child.p_visible=true;
      }
      child=child.p_next;
      if( child==first_child ) {
         break;
      }
   }
   // Need this on UNIX
   dc_wid.refresh('w');
}

/**
 * Refresh the entire side of item pictures, captions.
 * 
 * @param area Side to refresh. See DOCKINGAREA_* constants.
 */
static void _dcViewRefresh(DockingArea area)
{
   boolean old_IgnoreMouseMove = _dcCtlIgnoreMouseMove(true);

   // Clear all pics on this side
   _dcViewClear(area);
   // Recreate pics on this side
   _dcViewAdjustPics(area);
   // Position and space pics on this side
   _dcViewAdjustSpaces(area);
   // Make all pics visible on this side
   _dcViewSetVisible(area);

   _dcCtlIgnoreMouseMove(old_IgnoreMouseMove);
}

static void _dcViewRefreshAll()
{
   int area;
   for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area ) {
      _dcViewRefresh((DockingArea)area);
   }
}

static int _dcViewFind(_str sid, DockingArea startArea=DOCKINGAREA_FIRST)
{
   if( startArea<DOCKINGAREA_FIRST || startArea>DOCKINGAREA_LAST ) {
      return 0;
   }
   int area_first = startArea;
   int area;
   for( area=area_first;; ) {
      int dc_wid = _mdi._GetDockChannel(area);
      if( dc_wid!=0 ) {
         int first_child = dc_wid.p_child;
         int child = first_child;
         while( child!=0 ) {
            if( child.p_user==sid ) {
               // Found it
               return child;
            }
            child=child.p_next;
            if( child==first_child ) {
               break;
            }
         }
      }
      ++area;
      if( area>DOCKINGAREA_LAST ) {
         area=DOCKINGAREA_FIRST;
      }
      if( area==area_first ) {
         // Done
         break;
      }
   }
   // Not found
   return 0;
}


//
// Dock channel controller
//

defeventtab _dock_channel_form;

void _dock_channel_form.on_create()
{
   int dcside = _GetDockChannelArea();
   switch( dcside ) {
   case DOCKINGAREA_LEFT:
   case DOCKINGAREA_RIGHT:
      p_width = DCVIEW_CHANNEL_WH * _twips_per_pixel_x();
      break;
   case DOCKINGAREA_TOP:
   case DOCKINGAREA_BOTTOM:
      p_height = DCVIEW_CHANNEL_WH * _twips_per_pixel_y();
      break;
   default:
      // Should only get here if testing. Use DOCKINGAREA_BOTTOM case.
      p_height = DCVIEW_CHANNEL_WH * _twips_per_pixel_y();
   }
}

void _dock_channel_form.on_destroy()
{
}

static void _dcCtlContextMenu()
{
   int index;
   index=find_index("_temp_dock_channel_menu",oi2type(OI_MENU));
   if( index>0 ) {
      delete_name(index);
   }
   int dcside = _GetDockChannelArea();
   if( dcside<DOCKINGAREA_FIRST || dcside>DOCKINGAREA_LAST || gdcModelInfo[dcside]._length() == 0 ) {
      // Nothing to do
      return;
   }
   index=insert_name("_temp_dock_channel_menu",oi2type(OI_MENU));
   int i;
   for( i=0; i<gdcModelInfo[dcside]._length(); ++i ) {
      _str sid = gdcModelInfo[dcside][i].sid;
      if( sid=="" ) {
         // Space
         continue;
      }
      _str caption = gdcModelInfo[dcside][i].caption;
      _menu_insert(index,-1,0,caption,"dockchanSelect "dcside':'sid);
   }

   int menu_handle = p_active_form._menu_load(index,'P');
   // Show the menu
   int x = 100;
   int y = 100;
   x = mou_last_x('M') - x;
   y = mou_last_y('M') - y;
   _lxy2dxy(p_scale_mode,x,y);
   _map_xy(p_window_id,0,x,y,SM_PIXEL);
   int flags = VPM_LEFTALIGN|VPM_RIGHTBUTTON;
   _KillToolButtonTimer();
   int status = _menu_show(menu_handle,flags,x,y);
   _menu_destroy(menu_handle);
   // Delete temporary menu resource
   delete_name(index);
}

/**
 * Called when item clicked or selected from context menu.
 * 
 * @param dcside Dock channel side.
 * @param sid    String id.
 */
_command void dockchanSelect(_str dcside_sid="")
{
   if( dcside_sid=="" ) {
      // How did we get here?
      return;
   }
   _str dcside, sid;
   parse dcside_sid with dcside':'sid;
   _dcModelSetActiveInGroup(sid,true);
   if( dcside>0 ) {
      _dcViewRefresh((int)dcside);
   } else {
      // Should only get here when testing, use DOCKINGAREA_BOTTOM case
      _dcViewRefresh(DOCKINGAREA_BOTTOM);
   }
   _dcCtlOnMouseIn(sid,true);
}

void _dock_channel_form.lbutton_up()
{
   if( p_object!=OI_IMAGE ) {
      // Not clicking on icon
      return;
   }
   _str sid = p_user;
   int dcside = _GetDockChannelArea();
   dockchanSelect(dcside':'sid);
}

void _dock_channel_form.rbutton_up()
{
   //Display context menu
   _dcCtlContextMenu();
}

static boolean _dcCtlOnMouseIn(_str sid, boolean clicked=false, boolean doRefresh=false)
{
   DockingArea area, i;
   if( !_dcModelFind(sid,area,i) ) {
      // How did we get here?
      return false;
   }
   DCMODELINFO* pdcminfo = &gdcModelInfo[area][i];
   pfnDockChanMouseInCallback pMouseInCallback = pdcminfo->pMouseInCallback;
   boolean active = (*pMouseInCallback)(area,sid,pdcminfo->pic,pdcminfo->caption,pdcminfo->active,clicked);
   if( pdcminfo->active!=active ) {
      _dcModelSetActiveInGroup(sid,active);
      _dcModelAdjustSpaces(area);
      if( doRefresh ) {
         _dcViewRefresh(area);
      }
   }
   return active;
}

static boolean _dcCtlOnMouseOut(_str sid, boolean doRefresh=false, boolean precedesMouseIn=false)
{
   DockingArea area, i;
   if( !_dcModelFind(sid,area,i) ) {
      // How did we get here?
      return false;
   }
   DCMODELINFO* pdcminfo = &gdcModelInfo[area][i];
   pfnDockChanMouseOutCallback pMouseOutCallback = pdcminfo->pMouseOutCallback;
   boolean active = (*pMouseOutCallback)(area,sid,pdcminfo->pic,pdcminfo->caption,pdcminfo->active,precedesMouseIn);
   // Make sure item was not deleted out of model by callback
   if( _dcModelFind(sid,area,i) ) {
      // Address into array could have changed as a result of the callback,
      // so get it again.
      pdcminfo = &gdcModelInfo[area][i];
      if( pdcminfo->active!=active ) {
         pdcminfo->active=active;
         _dcModelAdjustSpaces(area);
         if( doRefresh ) {
            _dcViewRefresh(area);
         }
      }
   }
   return active;
}

static void _dcCtlOnResize()
{
   call_list("_dockchan_resize_");
}

static void _dcCtlStartTimer(_str arg1)
{
   if( gDockChannelMouseOverTimer>=0 ) {
      // Already started
      return;
   }
   gDockChannelMouseOverTimer=_set_timer(DOCKCHANNEL_TIMER_INTERVAL,_dcCtlMouseOverCallback,arg1);
   //say('_dcCtlStartTimer: started timer='gDockChannelMouseOverTimer);
}

static void _dcCtlKillTimer()
{
   if( gDockChannelMouseOverTimer>=0 ) {
      //say('_dcCtlKillTimer: killing timer='gDockChannelMouseOverTimer);
      _kill_timer(gDockChannelMouseOverTimer);
   }
   // -1 is for the get_event() timer, so use -2
   gDockChannelMouseOverTimer= -2;
   gNumMouseOver=0;
}

// Global so address does not change in names table when module reloaded
void _dcCtlMouseOverCallback()
{
   //say('_dcCtlMouseOverCallback: in - gLastMouseSid='gLastMouseSid'  sid='arg(1));
   _str sid = arg(1);
   if( sid=="" ) {
      // How did we get here?
      //say('_dcCtlMouseOverCallback: h0');
      _dcCtlKillTimer();
      return;
   }
   if( 0!=(def_dock_channel_options & DOCKCHANNEL_OPT_NO_MOUSEOVER) ) {
      // How did we get here?
      _dcCtlKillTimer();
      return;
   }

   ++gNumMouseOver;
   //say('_dcCtlMouseOverCallback: gNumMouseOver*DOCKCHANNEL_TIMER_INTERVAL='(gNumMouseOver*DOCKCHANNEL_TIMER_INTERVAL));
   if( (gNumMouseOver*DOCKCHANNEL_TIMER_INTERVAL) < def_dock_channel_delay ) {
      // Not time to do anything yet
      return;
   }
   //say('_dcCtlMouseOverCallback: h0 interval elapsed - gLastMouseSid='gLastMouseSid'  sid='arg(1));
   gNumMouseOver=0;

   //say('_dcCtlMouseOverCallback: h1 - gLastMouseSid='gLastMouseSid'  sid='sid);
   if( gLastMouseSid!=sid ) {
      // We are now in a different item, so start over
      //say('_dcCtlMouseOverCallback: h2');
      _dcCtlOnMouseOut(gLastMouseSid);
      gLastMouseSid="";
      //_dcCtlKillTimer();
      //_dcCtlConsider(sid);
      return;
   }

   // Last mouse coordinates in pixels relative to screen
   int mx, my;
   mou_get_xy(mx,my);

   // Is the mouse still inside the image?
   int wid = _dcViewFind(gLastMouseSid);
   if( wid==0 || !_iswindow_valid(wid) ) {
      // Nope.
      // A callback probably removed the item.
      _dcCtlOnMouseOut(gLastMouseSid);
      //say('_dcCtlMouseOverCallback: h3');
      _dcCtlKillTimer();
      gLastMouseSid="";
      return;
   }
   int pic_width, pic_height;
   pic_width=_lx2dx(SM_TWIP,wid.p_width);
   pic_height=_ly2dy(SM_TWIP,wid.p_height);
   int pic_x1, pic_y1, pic_x2, pic_y2;
   pic_x1=_lx2dx(SM_TWIP,wid.p_x);
   pic_x2=pic_x1+pic_width;
   pic_y1=_ly2dy(SM_TWIP,wid.p_y);
   pic_y2=pic_y1+pic_height;
   _map_xy(wid.p_xyparent,0,pic_x1,pic_y1);
   _map_xy(wid.p_xyparent,0,pic_x2,pic_y2);
   if( mx>=pic_x1 && mx<pic_x2 &&
       my>=pic_y1 && my<pic_y2 ) {

      // Mouse in!

      // If we got here, then we are still in the same window we started in
      //say('_dcCtlMouseOverCallback: h4 - considering gLastMouseSid'gLastMouseSid);
      DockingArea area, i;
      if( !_dcModelFind(gLastMouseSid,area,i) ) {
         // How did we get here?
         return;
      }
      // _dcCtlOnMouseIn() will set the active property in the model, so
      // save off old active state.
      boolean old_active = gdcModelInfo[area][i].active;
      boolean active = _dcCtlOnMouseIn(gLastMouseSid);
      // Start the count over or else moving mouse in and out of item
      // will cause callbacks to be called too quickly.
      gNumMouseOver=0;
      // IMPORTANT:
      // Do NOT kill the timer since we will want to know if the mouse
      // has passed outside the item later.

      if( old_active != active) {
         // Active state changed. Only refresh when we have to in order
         // to cut down on flash.
         _dcViewRefresh(area);
      }
      return;
   }

   // Mouse out!

   // Mouse is no longer inside the item we started in. _dcCtlOnMouseOut() will
   // determine what to do.
   boolean active = _dcCtlOnMouseOut(gLastMouseSid);
   if( active ) {
      // Mouse is outside item, but callback told us to keep it active (shrug).
      // Start the count over.
      gNumMouseOver=0;
   }
   DockingArea area, i;
   if( _dcModelFind(gLastMouseSid,area,i) ) {
      if( gdcModelInfo[area][i].active != active) {
         // MouseOut callback told us to change the active state
         gdcModelInfo[area][i].active=active;
         _dcViewRefresh(area);
      }
   }
   // Clear last mouse sid so dock channel does not think we moved immediately
   // from one item to another after moving out then moving into another item.
   // Otherwise, the item would be activated too quickly.
   gLastMouseSid="";
   _dcCtlKillTimer();
}

static void _dcCtlConsider(_str sid)
{
   if( sid=="" ) {
      return;
   }

   _dcCtlKillTimer();

   //say('_dcCtlConsider: gLastMouseSid='gLastMouseSid'  sid='sid);
   if( gLastMouseSid!="" && gLastMouseSid!=sid ) {
      _dcCtlOnMouseOut(gLastMouseSid,false,true);
      // If we do not set gLastMouseSid="" then we will never know when
      // the mouse exits an item, then enters the same item.
      gLastMouseSid="";
      // Mouse-in immediately
      _dcCtlOnMouseIn(sid,false,true);
   } else if( gLastMouseSid==sid ) {
      // In the same item, so do nothing
      //return;
   }

   // If we got here, then we are considering a new item or the same item
   gLastMouseSid=sid;
   _dcCtlStartTimer(sid);
}

static boolean gIgnoreMouseMove = false;
static boolean _dcCtlIgnoreMouseMove(boolean onoff)
{
   boolean old_IgnoreMouseMove = gIgnoreMouseMove;
   gIgnoreMouseMove=onoff;
   return old_IgnoreMouseMove;
}

void _dock_channel_form.mouse_move()
{
   if( gIgnoreMouseMove ) {
      return;
   }
   if( 0!=(def_dock_channel_options & DOCKCHANNEL_OPT_NO_MOUSEOVER) ) {
      // Force user to click to show
      return;
   }

   // Wait a little. The user may have just been moving the mouse to
   // get to where they were going. Otherwise, switching from one
   // item to another is a little too fast.
   int old_mode = mou_mode(-1);
   // Must turn on mouse mode so that delay with 'k' does not eat MOUSE-MOVE events
   mou_mode(1);
   //delay(10,'k');
   delay(10);
   mou_mode(old_mode);
   if( _IsEventPending(EVENTPENDING_MOUSE_MOVE) ) {
      return;
   }

   if( p_object!=OI_IMAGE ) {
      // Not moving over item
      return;
   }
   //say('_dock_channel_form.mouse_move: p_window_id='p_window_id'  p_user='p_user'  mx='mou_last_x()'  my='mou_last_y());
   _str sid = p_user;
   _dcCtlConsider(sid);
}

void _dock_channel_form.on_resize()
{
   _dcCtlOnResize();
}


//
// Public functions
//

/**
 * Reset the dock channels for all sides. This clears all items and removes
 * the channel.
 */
void dockchanResetAll()
{
   // Model
   _dcModelRemoveAll();
   // View
   int dcside;
   for( dcside=DOCKINGAREA_FIRST; dcside<=DOCKINGAREA_LAST; ++dcside ) {
      int dc_wid = _mdi._GetDockChannel(dcside);
      if( dc_wid>0 ) {
         dc_wid._delete_window();
      }
   }
}

/**
 * Add a new item to dock channel area.
 * 
 * @param area
 * @param sid
 * @param pic
 * @param caption
 * @param pMouseInCallback
 * @param pMouseOutCallback
 * @param newGroup
 * @param delayRefresh      Delay refreshing the dock channel. Used by autorestore to be more efficient.
 * @param addAfterSid       Add after sid in dock channel order. If sid does not exist, then add at end of dock channel.
 */
void dockchanAdd(DockingArea area, _str sid, int pic, _str caption,
                 pfnDockChanMouseInCallback pMouseInCallback,
                 pfnDockChanMouseOutCallback pMouseOutCallback,
                 boolean newGroup=false, boolean delayRefresh=false,
                 _str addAfterSid="")
{
   // Insert before index
   int i = -1;

   DockingArea area_found, found_i;
   if( addAfterSid!="" && _dcModelFind(addAfterSid,area_found,found_i) ) {
      newGroup=false;
      i=found_i+1;
   }
   _dcModelInsert(area,i,sid,pic,caption,pMouseInCallback,pMouseOutCallback,newGroup);
   if( !delayRefresh ) {
      // Must also delay adjusting spaces since there may be adds after this one
      _dcModelAdjustSpaces(area);
      _dcViewRefresh(area);
   }
}

/**
 * Remove item by sid.
 * 
 * @param sid
 */
void dockchanRemove(_str sid)
{
   DockingArea area, i;
   if( _dcModelFind(sid,area,i) ) {
      _dcModelRemove(area,i);
      _dcModelAdjustSpaces(area);
      _dcViewMaybeRemoveChannel(area);
      _dcViewRefresh(area);
   }
}

/**
 * Find a dock channel item by unique sid.
 * 
 * @param sid
 * @param bbside  (output). Side item found on.
 * @param pic     (output). Picture index of item.
 * @param caption (output). Caption of item.
 * @param active  (output). true if item is active.
 * 
 * @return true if item is found.
 */
boolean dockchanFind(_str sid, int& area, int& pic, _str& caption, boolean& active)
{
   int i;
   if( _dcModelFind(sid,area,i) ) {
      DCMODELINFO* pdcminfo = &gdcModelInfo[area][i];
      pic=pdcminfo->pic;
      caption=pdcminfo->caption;
      active=pdcminfo->active;
      return true;
   }
   // Not found
   return false;
}

/**
 * Find dock channel group of items that contain unique sid.
 * 
 * @param sid
 * @param bbside Side group was found on. One of BBSIDE_*.
 * @param sidArray Array of sids found, in dock channel order.
 * 
 * @return true if group found.
 */
boolean dockchanFindGroup(_str sid, int& area, _str (&sidArray)[])
{
   int i, first_i, last_i;
   if( _dcModelFindGroup(sid,area,i,first_i,last_i) ) {

      sidArray._makeempty();
      for( i=first_i; i<=last_i; ++i ) {
         sidArray[sidArray._length()]=gdcModelInfo[area][i].sid;
      }
      return true;
   }
   // Not found
   return false;
}

/**
 * Set item identified by sid as the active item. If item is part of a group,
 * all other items in the group will be set inactive.
 * 
 * @param delayRefresh      Delay refreshing the dock channel. Used by autorestore to be more efficient.
 */
void dockchanSetActive(_str sid, boolean delayRefresh=false)
{
   DockingArea area, i;
   if( _dcModelFind(sid,area,i) ) {
      _dcModelSetActiveInGroup(sid,true);
      if( !delayRefresh ) {
         _dcViewRefresh(area);
      }
   }
}

/**
 * Enumerate the dock channel items on a side in order.
 * The pDockChanEnumCallback callback is called for each item on the side.
 * 
 * @param area  Area to enumerate. See DOCKINGAREA_* contstants.
 * @param pDockChanEnumCallback Caller-defined. Enumeration callback.
 * @param enumSpaces (optional). When true, space items are returned to enumeration callback
 *                   in addition to regular items. Space items are those with a sid="" and
 *                   represent a space/gap between adjacent items. Defaults to false.
 * @param extra      Caller-defined data to be passed to callback.
 */
void dockchanEnumerate(DockingArea area, pfnDockChanEnumCallback pDockChanEnumCallback, boolean enumSpaces=false, typeless extra=null)
{
   int i;
   for( i=0; i<gdcModelInfo[area]._length(); ++i ) {
      DCMODELINFO* pdcminfo = &gdcModelInfo[area][i];
      _str sid = pdcminfo->sid;
      int pic = 0;
      _str caption = "";
      boolean active = false;
      if( sid!="" ) {
         pic=pdcminfo->pic;
         caption=pdcminfo->caption;
         active=pdcminfo->active;
      }
      if( sid!="" || enumSpaces ) {
         (*pDockChanEnumCallback)(area,sid,pic,caption,active,extra);
      }
   }
}

/**
 * Enumerate the dock channel items of the same group on a side in order.
 * The pDockChanEnumCallback callback is called for each item on the side.
 * 
 * @param sid String id of item in group to enumerate. This will be used to find the group.
 * @param pDockChanEnumCallback Caller-defined. Enumeration callback.
 */
void dockchanEnumerateGroup(_str sid, pfnDockChanEnumCallback pDockChanEnumCallback)
{
   // We have to continue requerying in case the callback removes an item
   // out from under us.
   DockingArea area = DOCKINGAREA_FIRST;
   int i, first_i, last_i;
   _str next_sid = sid;
   while( _dcModelFindGroup(next_sid,area,i,first_i,last_i,area) ) {

      // Save the next sid now in case the callack deletes this item
      // out from under us. It does not matter that we give it the last
      // item, since we always go in order from the first item found in
      // the group.
      next_sid=gdcModelInfo[area][last_i].sid;

      DCMODELINFO* pdcminfo = &gdcModelInfo[area][first_i];
      sid = pdcminfo->sid;
      if( sid=="" ) {
         // How did we get here?
         break;
      }
      int pic = pdcminfo->pic;
      _str caption = pdcminfo->caption;
      boolean active = pdcminfo->active;

      (*pDockChanEnumCallback)(area,sid,pic,caption,active,null);
   }
}

int dockchanGetDockChannel(DockingArea area)
{
   return (_mdi._GetDockChannel(area));
}

/**
 * Get rectangular coordinates of each dock channel. Coordinates
 * are in pixels, relative to the desktop unless relativeToMDI=true.
 * 
 * @param areas (output). Array of Rect. Each Rect is a dock 
 *              channel rectanglular area, indexed by
 *              DOCKINGAREA_*.
 * @param relativeToMDI (optional). true gets coordinates relative to MDI frame.
 *                      Defaults to false.
 */
void dockchanGetAreas(sc.util.Rect (&areas)[], boolean relativeToMDI=false)
{
   areas._makeempty();
   sc.util.Rect nullRect;
   int area;
   int x, y, width, height;
   for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area ) {

      areas[area] = nullRect;
      _mdi._GetDockChannelGeometry(area,x,y,width,height);
      areas[area].setRect(x,y,width,height);
      if( !relativeToMDI ) {
         // Map to desktop
         _map_xy(_mdi,0,x,y);
         areas[area].setX(x);
         areas[area].setY(y);
      }
      //say('dockchanGetAreas : area='area'  rect='areas[area].toString());
   }
}

/**
 * Refresh items view in a dock channel area.
 * 
 * @param area  (optional). If DOCKINGAREA_UNSPEC, all areas 
 *               are refreshed. Defaults to DOCKINGAREA_UNSPEC.
 */
void dockchanRefresh(DockingArea area=DOCKINGAREA_UNSPEC)
{
   if( area == DOCKINGAREA_UNSPEC ) {
      int i;
      for( i=DOCKINGAREA_FIRST; i<=DOCKINGAREA_LAST; ++i ) {
         _dcModelAdjustSpaces(i);
      }
      _dcViewRefreshAll();
   } else {
      _dcModelAdjustSpaces(area);
      _dcViewRefresh(area);
   }
}

/**
 * Kill the mouse event timer. This will prevent any MouseIn or MouseOut
 * callbacks from being called until the next time the mouse moves into
 * an item.
 */
void dockchanKillMouseEvents()
{
   _dcCtlKillTimer();
   gLastMouseSid="";
}

/**
 * @param String id.
 * 
 * @return true if current mouse cursor is inside dock channel item
 * identified by sid.
 */
boolean dockchanMouInItem(_str sid)
{
   // Is the mouse still inside the image?
   int wid = _dcViewFind(sid);
   if( wid==0 || !_iswindow_valid(wid) ) {
      // Not an item in any dock channel
      return false;
   }

   // Last mouse coordinates in pixels relative to screen
   int mx, my;
   mou_get_xy(mx,my);

   int pic_width, pic_height;
   pic_width=_lx2dx(SM_TWIP,wid.p_width);
   pic_height=_ly2dy(SM_TWIP,wid.p_height);
   int pic_x1, pic_y1, pic_x2, pic_y2;
   pic_x1=_lx2dx(SM_TWIP,wid.p_x);
   pic_x2=pic_x1+pic_width;
   pic_y1=_ly2dy(SM_TWIP,wid.p_y);
   pic_y2=pic_y1+pic_height;
   _map_xy(wid.p_xyparent,0,pic_x1,pic_y1);
   _map_xy(wid.p_xyparent,0,pic_x2,pic_y2);
   if( mx>=pic_x1 && mx<pic_x2 &&
       my>=pic_y1 && my<pic_y2 ) {

      // Mouse inside item!
      return true;
   }

   // Mouse outside item
   return false;
}


//
// Debug
//

#if 0
static int _myGetDockChannel(DockingArea area)
{
   int wid = _find_formobj(DC_FORMNAME,'n');
   return wid;
}
static int _myLoadDockChannel(int index, DockingArea area)
{
   int wid = show("-xy "DC_FORMNAME);
   return wid;
}

boolean dummyMouseInCallback(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean clicked)
{
   say('dummyMouseInCallback: in - area='area'  sid='sid);
   return true;
}
boolean dummyMouseOutCallback(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean precedesMouseIn)
{
   say('dummyMouseOutCallback: in - area='area'  sid='sid);
   return false;
}
_command void dctest1()
{
   _dcModelRemoveAll();
   _dcViewClearAll();
   DockingArea area = DOCKINGAREA_BOTTOM;
   _str sid;
   int index;
   int pic;
   _str caption;

   sid="_tbprojects_form";
   index=find_index(sid,oi2type(OI_FORM));
   pic=index.p_picture;
   caption=index.p_caption;
   _dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);

   //sid="_tbproctree_form";
   //index=find_index(sid,oi2type(OI_FORM));
   //pic=index.p_picture;
   //caption=index.p_caption;
   //_dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);
   //
   //sid="_tbcbrowser_form";
   //index=find_index(sid,oi2type(OI_FORM));
   //pic=index.p_picture;
   //caption=index.p_caption;
   //_dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);
   //
   //sid="_tbopen_form";
   //index=find_index(sid,oi2type(OI_FORM));
   //pic=index.p_picture;
   //caption=index.p_caption;
   //_dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);
   //
   //sid="_tbFTPOpen_form";
   //index=find_index(sid,oi2type(OI_FORM));
   //pic=index.p_picture;
   //caption=index.p_caption;
   //_dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);
   //
   //sid="";
   //_dcModelInsert(area,-1,sid,0,"",0,0);
   //
   //sid="_tbdebug_breakpoints_form";
   //index=find_index(sid,oi2type(OI_FORM));
   //pic=index.p_picture;
   //caption=index.p_caption;
   //_dcModelInsert(area,-1,sid,pic,caption,dummyMouseInCallback,dummyMouseOutCallback);

   _dcModelAdjustSpaces(area);
   _dcViewRefresh(area);
}
_command void dctest2()
{
   _dcModelRemoveAll();
   _dcViewMaybeRemoveChannel(DOCKINGAREA_BOTTOM);
   int wid = _find_formobj('_dock_channel_form','n');
   say('dctest2: wid='wid);
   _dcViewRefresh(DOCKINGAREA_BOTTOM);
}
_command void dctest3()
{
   say('dctest3: *********************************************');
   int dc_wid = dockchanGetDockChannel(DOCKINGAREA_LEFT);
   if( dc_wid>0 ) {
      int first_child = dc_wid.p_child;
      int child = first_child;
      while( child>0 ) {
         say('dctest3: child.p_user='child.p_user);
         child=child.p_next;
         if( child==first_child ) {
            break;
         }
      }
   }
}
_command void dctest4()
{
   int mx, my;
   int dc_wid = _mdi._GetDockChannel(DOCKINGAREA_BOTTOM);
   if( dc_wid>0 ) {
      int picWid = _dcViewFind("_tbtagwin_form",DOCKINGAREA_BOTTOM);
      if( picWid>0 ) {
         mou_get_xy(mx,my);
         int x1 = _lx2dx(SM_TWIP,picWid.p_x);
         int width = _lx2dx(SM_TWIP,picWid.p_width);
         int x2 = x1 + width;
         int y1 = _ly2dy(SM_TWIP,picWid.p_y);
         int height = _ly2dy(SM_TWIP,picWid.p_height);
         int y2 = y1 + height;
         _map_xy(picWid.p_xyparent,0,x1,y1);
         _map_xy(picWid.p_xyparent,0,x2,y2);
         say('dctest4: mx='mx'  my='my);
         say('dctest4: x1='x1'  x2='x2);
         say('dctest4: y1='y1'  y2='y2);
      }
   }
}
_command void dctest5()
{
   _dcCtlKillTimer();
}
_command void dctest6()
{
   DCSIDERECT dcsides[];
   dockchanGetSides(dcsides);
   WINRECT r;
   _WinRectSetSubRect(r,0,dcsides[DOCKINGAREA_BOTTOM].x1,dcsides[DOCKINGAREA_BOTTOM].y1,dcsides[DOCKINGAREA_BOTTOM].x2,dcsides[DOCKINGAREA_BOTTOM].y2);
   _desktop._WinRectDrawRect(r,_rgb(255,0,0),'n');
}
#endif
