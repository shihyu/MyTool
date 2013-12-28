////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2012 SlickEdit Inc.
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
#import "notifications.e"
#import "recmacro.e"
#import "stdprocs.e"
#require "se/ui/IHotspotMarker.e"
#require "se/ui/IKeyEventCallback.e"
#require "se/ui/ITextChangeListener.e"
#require "se/ui/NavMarker.e"
#import "se/ui/EventUI.e"
#import "se/ui/TextChange.e"
#endregion

namespace se.ui;

class HotspotMarkers : IKeyEventCallback, ITextChangeListener, IHotspotMarker {
   private static int s_markerType = -1;

   private static int getMarkerType()
   {
      if (s_markerType < 0) {
         s_markerType = _MarkerTypeAlloc();
         _MarkerTypeSetFlags(s_markerType, 0);
      }
      return s_markerType;
   }

   static void initMarkerType()
   {
      s_markerType = -1;
   }

   /************************************************************/
   private NavMarker m_markers[];
   private int m_range = -1;

   HotspotMarkers()
   {
   }

   private void onCreate(long (&hotspotOffsets)[])
   {
      long startOffset = hotspotOffsets[0];
      long endOffset = startOffset;

      foreach (auto offset in hotspotOffsets) {
         NavMarker m(offset);
         id := m_markers._length();
         m_markers[id] = m;

         if (offset > endOffset) {
            endOffset = offset;
         }
      }

      updateRange(startOffset, endOffset);
   }

   private void freeMarker()
   {
      foreach (auto marker in m_markers) {
         marker.remove();
      }
      if (m_range >= 0) {
         _StreamMarkerRemove(m_range);
         m_range = -1;
      }
   }

   private void doExit()
   {
      EventUI.removeListener(&this);
   }

   private boolean onEscape()
   {
      doExit();
      return(true);
   }

   private boolean onNextPrev(boolean next)
   {
      current := 0;
      markerCount := m_markers._length();
      if (markerCount > 1) {
         offset := _QROffset();

         int i;
         // find next
         if (next) {
            for (i = 0; i < markerCount; ++i) {
               if (m_markers[i].getOffset() > offset) {
                  break;
               }
            }
            current = i;
            if (current >= markerCount) {
               current = 0;
            }

         } else {
            for (i = 0; i < markerCount; ++i) {
               if (m_markers[i].getOffset() >= offset) {
                  break;
               }
            }
            current = i - 1;
            if (current < 0) {
               current = markerCount - 1;
            }
         }
      }
      m_markers[current].gotoMarker();
      // if jumping to last/only hotspot, remove it
      if (markerCount == 1) {
         doExit();
      }
      return(true);
   }

   boolean onKey(_str &key)
   {
      if (m_markers._isempty() || m_markers._length() == 0) {
         doExit();
         return(false);
      }

      offset := _QROffset();
      if (m_range < 0 || _StreamMarkerGet(m_range, auto info) ||
          info.Length == 0) {
         doExit();
         return(false);
      }
      if (offset < info.StartOffset || offset > info.StartOffset + info.Length) {
         doExit();
         return(false);
      }

      switch (key) {
      case ESC:
         return(onEscape());

      case TAB:
      case S_TAB:
         // special case for Tab key on one and only hotspot
         if (m_markers._length() == 1 &&
             m_markers[0].getOffset() == _QROffset()) {
            doExit();
            return(false);
         }
         return onNextPrev(key :== TAB);
      }
      return(false);
   }

   void onRemove()
   {
      freeMarker();
      TextChangeNotify.removeListener(&this);
      removeMarker(this);
   }

   void onPush()
   {
      _str keyarray[];  // this could be static
      keyarray[0] = ESC;
      if (def_hotspot_allow_tab_navigation) {
         keyarray[1] = TAB;
         keyarray[2] = S_TAB;
      }
      EventUI.setCallbacks(keyarray);

      foreach (auto mark in m_markers) {
         mark.show();
      }
   }

   void onPop()
   {
      foreach (auto mark in m_markers) {
         mark.hide();
      }
   }

   void onTextChange(long startOffset, long endOffset)
   {
      if (p_TextWrapChangeNotify) {
         return;
      }

      VSSTREAMMARKERINFO info;
      if (m_markers._isempty() ||
          m_range < 0 || _StreamMarkerGet(m_range, info) || info.Length == 0 ||
          endOffset < info.StartOffset ||
          startOffset >= info.StartOffset + info.Length) {
         doExit();
         return;
      }

      // somewhere in range, check if at/past end of range
      endRange := info.StartOffset + info.Length;
      if (endOffset >= endRange && _QROffset() >= endRange) {
         doExit();
         return;
      }

      // adjust start range?
      if (endOffset > startOffset && endOffset > 0 && 
          endOffset == info.StartOffset) {
         _StreamMarkerSetStartOffset(m_range, startOffset); 
      }

      int i, id;
      for (i = m_markers._length() - 1; i >= 0; --i) {
         id = m_markers[i].getMarkerID();
         if (_StreamMarkerGet(id, info) || info.Length == 0 || info.StartOffset == endOffset ||
             (startOffset <= info.StartOffset && endOffset >= info.StartOffset + info.Length)) {
            m_markers[i].remove();
            m_markers._deleteel(i);
            continue;
         }
      }

      if (m_markers._length() == 0) {
         doExit();
         return;
      }
   }

   private void updateRange(long startOffset, long endOffset)
   {
      if (m_range < 0 || _StreamMarkerGet(m_range, auto info) < 0) {
         m_range = _StreamMarkerAdd(p_window_id, startOffset, endOffset - startOffset, true, 0, getMarkerType(), null);

      } else {
         _StreamMarkerSetStartOffset(m_range, startOffset);
         _StreamMarkerSetLength(m_range, endOffset - startOffset);
      }
   }

   // Save/restore stream markers for beautifer
   boolean save(long (&markers)[], long startOffset, long endOffset)
   {
      if (m_range < 0 || _StreamMarkerGet(m_range, auto rangeinfo) < 0) {
         doExit();
         return(false);
      }

      if (!_ranges_overlap(rangeinfo.StartOffset, rangeinfo.StartOffset + rangeinfo.Length, 
                          startOffset, endOffset)) {
         return(false);
      }

      if (def_beautifier_debug > 1) say("beautify: ["startOffset","endOffset"], hotspot range ["rangeinfo.StartOffset","rangeinfo.StartOffset + rangeinfo.Length"]");

      index := markers._length();
      markers[index++] = rangeinfo.StartOffset;
      markers[index++] = rangeinfo.StartOffset + rangeinfo.Length;
      foreach (auto mark in m_markers) {
         markers[index++] = mark.getOffset();
         if (def_beautifier_debug > 1) say("beautify: hotspot save offset: "mark.getOffset());
      }
      return(true);
   }

   void restore(long (&markers)[], int index)
   {
      if (index + 2 + m_markers._length() > markers._length()) {
         doExit();
         return;
      }

      startOffset := markers[index++];
      endOffset := markers[index++];
      if (def_beautifier_debug > 1) say("beautify: restore hotspot range ["startOffset","endOffset"]");

      long offset;
      foreach (auto mark in m_markers) {
         offset = markers[index++];
         if (def_beautifier_debug > 1) say("beautify: restore hotspot offset: "offset);
         mark.setMarker(offset);
      }

      updateRange(startOffset, endOffset);
   }

   /************************************************************/
   private static HotspotMarkers s_marker[];
   private static int s_tempMarkers[];

   static void createMarker(long (&offsets)[])
   {
      _updateTextChange();
      if (!offsets._length()) {
         return;
      }

      HotspotMarkers marker;
      offsets._sort('N');
      marker.onCreate(offsets);
      id := s_marker._length();
      s_marker[id] = marker;
      TextChangeNotify.addListener(&s_marker[id]);
      EventUI.addListener(&s_marker[id]);
   }

   private static void removeMarker(HotspotMarkers &marker)
   {
      for (id := 0; id < s_marker._length(); ++id) {
         if (s_marker[id] == marker) {
            s_marker[id] = null;
            s_marker._deleteel(id);
            break;
         }
      }
   }

   static void clearHotspots()
   {
      // remove temp markers
      foreach (auto id in s_tempMarkers) {
         _StreamMarkerRemove(id);
      }
      s_tempMarkers._makeempty();
   }

   static void addHotspot(long offset)
   {
      if (offset > 0) {
         // add temp marker -- reusing range marker here
         index := _StreamMarkerAdd(p_window_id, offset, 1, true, 0, getMarkerType(), null);
         if (index >= 0) {
            s_tempMarkers[s_tempMarkers._length()] = index;
         }
      }
   }

   static void showHotspots()
   {
      VSSTREAMMARKERINFO info;
      long offsets[];
      foreach (auto id in s_tempMarkers) {
         if (!_StreamMarkerGet(id, info) && info.Length) {
            offsets[offsets._length()] = info.StartOffset;
         }
         _StreamMarkerRemove(id);
      }

      if (offsets._length() > 1) {
         createMarker(offsets);
      }
      s_tempMarkers._makeempty();
   }

   // Support for next_hotspot/prev_hotspot command
   static boolean active()
   {
      typeless event = EventUI.get();
      return (event != null && ((*event) instanceof se.ui.IHotspotMarker));
   }

   static void nextPrevHotspot(boolean next)
   {
      typeless event = EventUI.get();
      if (event != null && ((*event) instanceof se.ui.IHotspotMarker)) {
         IHotspotMarker* hm = (IHotspotMarker*)event;
         hm->onNextPrev(next);
      }
   }

   static void init()
   {
      HotspotMarkers.initMarkerType();
      s_tempMarkers._makeempty();
   }

   static void exit()
   {
      s_marker._makeempty();
      s_tempMarkers._makeempty();
   }
};

namespace default;
using namespace se.ui.HotspotMarkers;

boolean def_hotspot_allow_tab_navigation = true;

definit()
{
   HotspotMarkers.init();
}

void _exit_se_ui_AutoBracketMarker()
{
   HotspotMarkers.exit();
}

