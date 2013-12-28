////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#include "markers.sh"
#import "recmacro.e"
#import "stdprocs.e"
#require "se/ui/IOvertypeListener.e"
#require "se/ui/StreamMarkerGroup.e"
#endregion

namespace se.ui;

class OvertypeMarker {
   private static StreamMarkerGroup s_markers = null;
   private static int s_markerType = -1;

   private static int getMarkerType()
   {
      if (s_markerType < 0) {
         s_markerType = _MarkerTypeAlloc();
         _MarkerTypeSetFlags(s_markerType, 0);
      }
      return s_markerType;
   }

   static void init()
   {
      StreamMarkerGroup sm;
      s_markerType = -1;
      s_markers = sm;
   }

   static void exit()
   {
      s_markers.makeEmpty();
   }

   static int createMarker(long offset, long len)
   {
      markerID := _StreamMarkerAdd(p_window_id, offset, len, true, 0, getMarkerType(), null);
      if (s_markers.isEmpty(p_buf_id)) {
         enableCallback(true);
      }
      s_markers.addMarker(p_buf_id, markerID, null);
      return(markerID);
   }

   static void removeMarker(int markerID)
   {
      _StreamMarkerRemove(markerID);
      s_markers.removeMarker(p_buf_id, markerID);
      if (s_markers.isEmpty(p_buf_id)) {
         enableCallback(false);
      }
   }

   private static boolean testKey(_str& key)
   {
      ch := get_text();
      if (key != ch) {
         return(false);
      }
      offset := _QROffset();
      _StreamMarkerFindList(auto list, p_window_id, offset, 1, offset, getMarkerType());
      if (list._isempty()) {
         return(false);
      }
      doDelete := false;
      result := false;
      foreach (auto id in list) {
         if (_StreamMarkerGet(id, auto info)) {
            continue;
         }
         if (info.Length > 0) {
            doDelete = true;
         }
         if (length(key) >= info.Length) {
            IOvertypeListener *ui_p = s_markers.getMarker(p_buf_id, id);
            if (ui_p != null) {
               if (ui_p->onOvertype(key)) {
                  result = true;
               }
            } else {
               removeMarker(id);
            }
         }
      }
      if (doDelete) {
         _delete_char();
         _macro('m', _macro('s'));
         _macro_call('delete_char');
      }
      return(result);
   }

   private static boolean onKey(_str key)
   {
      result := testKey(key);
      if (result) {
         call_key(key, '', '1'); // ensure that base key is called
      }
      return(result);
   }

   static boolean onKeyin(_str key)
   {
      result := testKey(key);
      if (result) {
         keyin(key);
      }
      return(result);
   }

   private static void enableCallback(boolean enable)
   {
      _str keyarray[];
      _str option = (enable) ? 'K' : '';
      _kbd_add_callback(find_index('se.ui.OvertypeMarker.onKey', PROC_TYPE), keyarray, option);
   }

   static void initCallbacks()
   {
      _kbd_add_callback(find_index('se.ui.OvertypeMarker.onKey', PROC_TYPE), null);
   }

   static void addListener(IOvertypeListener *marker, int markerID)
   {
      bufID := p_buf_id;
      s_markers.addMarker(bufID, markerID, marker);
   }

   static void removeListener(int markerID)
   {
      bufID := p_buf_id;
      s_markers.removeMarker(bufID, markerID);
   }

   static void removeBuffer()
   {
      _StreamMarkerRemoveType(p_window_id, getMarkerType());
      enableCallback(false);
      s_markers.removeBuffer(p_buf_id);
   }

   static boolean callbackPending()
   {
      return(!s_markers.isEmpty(p_buf_id));
   }
   
};

namespace default;
using namespace se.ui.OvertypeMarker;

definit()
{
   OvertypeMarker.init();
}

void _exit_se_ui_OvertypeMarker()
{
   OvertypeMarker.exit();
}

void _cbquit_se_ui_OvertypeMarker(int bufID, _str name)
{
   OvertypeMarker.removeBuffer();
}

void setOvertypeMarkerCallbacks()
{
   OvertypeMarker.initCallbacks();
}

boolean OvertypeListenerKeyin(_str key)
{
   if (command_state() || !_isEditorCtl() || !OvertypeMarker.callbackPending()) {
      return(false);
   }
   return(OvertypeMarker.onKeyin(key));
}

