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
#require "se/ui/IHotspotMarker.e"
#require "se/ui/IKeyEventCallback.e"
#require "se/ui/IOvertypeListener.e"
#require "se/ui/ITextChangeListener.e"
#require "se/ui/NavMarker.e"
#require "se/ui/OvertypeMarker.e"
#require "se/ui/EventUI.e"
#require "se/ui/TextChange.e"
#import "files.e"
#import "hotspots.e"
#import "notifications.e"
#import "stdprocs.e"
#import "recmacro.e"
#endregion

namespace se.ui;

class AutoBracketMarker : IKeyEventCallback, IOvertypeListener, ITextChangeListener, IHotspotMarker {
   private static int s_openMarkerType = -1;

   private static int openMarkerType()
   {
      if (s_openMarkerType < 0) {
         s_openMarkerType = _MarkerTypeAlloc();
         _MarkerTypeSetFlags(s_openMarkerType, 0);
      }
      return s_openMarkerType;
   }

   /************************************************************/
   private int m_start = -1;     // start marker for text range
   private int m_close = -1;     // close bracket marker
   private int m_open = -1;      // open bracket marker [optional]
   private NavMarker m_exitMarker;
   private int m_mode_keys = -1;    // Like def_autobracket_mode_keys, but may have some keys masked out in some contexts.

   AutoBracketMarker()
   {
   }

   private void onCreate(_str close_ch, long startOffset, long startLen, long closeOffset, long closeLen)
   {
      m_start = _StreamMarkerAdd(p_window_id, startOffset, startLen, true, 0, openMarkerType(), null);
      m_close = OvertypeMarker.createMarker(closeOffset, closeLen);

      if (m_mode_keys == -1) {
         // ie, m_mode_keys wasn't already poplated by a restoreStateFrom() call.
         m_mode_keys = contextMaskedModeKeys(p_LangId, close_ch, def_autobracket_mode_keys);
      }

      if (def_autobracket_mode_keys) {
         msg := "Auto Close: ";

         switch (m_mode_keys) {
         case AUTO_BRACKET_KEY_ENTER:
            msg :+= "Press Enter";
            break;
         case AUTO_BRACKET_KEY_TAB:
            msg :+= "Press Tab";
            break;
         case AUTO_BRACKET_KEY_ENTER|AUTO_BRACKET_KEY_TAB:
            msg :+= "Press Tab or Enter";
            break;
         }
         msg :+= " to jump past auto-inserted character.";  // this could be static
         m_exitMarker.setMarker(closeOffset + closeLen - 1, 1, msg);

         // show a toast message for the new marker
         notifyUserOfFeatureUse(NF_AUTO_CLOSE_COMPLETION);
      }
   }

   private void setOpenMarker(long offset, long len)
   {
      m_open = OvertypeMarker.createMarker(offset, len);
   }

   /**
    * @param keys Mode key mask.  @see def_autobracket_mode_keys
    *
    * @return int Mode keys that might possibly have some keys
    *         masked out in certain contexts.
    */
   private int contextMaskedModeKeys(_str langID, _str close_ch, int keys) {
      index := _FindLanguageCallbackIndex('_%s_auto_bracket_key_mask', langID);
      if (index) {
         call_index(close_ch, &keys, index);
      }
      return keys;
   }

   private void freeMarker()
   {
      if (m_start >= 0) {
         _StreamMarkerRemove(m_start);
      }
      if (m_close >= 0) {
         OvertypeMarker.removeMarker(m_close);
      }
      if (m_open >= 0) {
         OvertypeMarker.removeMarker(m_open);
      }
      m_start = -1; m_close = -1; m_open = -1;
      m_exitMarker.remove();
   }

   private void doExit()
   {
      EventUI.removeListener(&this);
   }

   private bool onEscape()
   {
      doExit();
      return(def_display_nav_hints != 0);
   }

   private bool onComplete(VSSTREAMMARKERINFO &info)
   {
      m_exitMarker.gotoMarker();
      doExit();
      return(true);
   }

   private bool onBackspace(long offset, VSSTREAMMARKERINFO &startInfo, VSSTREAMMARKERINFO &endInfo)
   {
      if (startInfo.StartOffset + startInfo.Length == offset && endInfo.StartOffset == offset && startInfo.Length == 1) {
         doExit();
         _delete_char();

         _macro('m', _macro('s'));
         _macro_call('_delete_char');
      }
      return(false);
   }

   bool onKey(_str &key)
   {
      if (m_start < 0 || m_close < 0 ||
          _StreamMarkerGet(m_start, auto startInfo) ||
          _StreamMarkerGet(m_close, auto endInfo) ||
          startInfo.Length == 0 || endInfo.Length == 0) {

         doExit();
         return(false);
      }

      offset := _QROffset();
      if (offset < startInfo.StartOffset ||
          offset >= endInfo.StartOffset + endInfo.Length) {

         doExit();
         return(false);
      }

      switch (key) {
      case ESC:
         return(onEscape());

      case ENTER:
      case TAB:
         return(onComplete(endInfo));

      case BACKSPACE:
         return(onBackspace(offset, startInfo, endInfo));
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
      if (m_start < 0 || m_close < 0 ||
          _StreamMarkerGet(m_start, auto startInfo) ||
          _StreamMarkerGet(m_close, auto endInfo) ||
          startInfo.Length == 0 || endInfo.Length == 0) {
         return;
      }
      _str keyarray[];  // this could be static
      keyarray[0] = BACKSPACE;
      if (def_autobracket_mode_keys) {
         keyarray[1] = ESC;
      }

      if (m_mode_keys & AUTO_BRACKET_KEY_ENTER) {
         keyarray[keyarray._length()] = ENTER;
      }
      if (m_mode_keys & AUTO_BRACKET_KEY_TAB) {
         keyarray[keyarray._length()] = TAB;
      }
      EventUI.setCallbacks(keyarray);
      m_exitMarker.show();
   }

   void onPop()
   {
      m_exitMarker.hide();
   }

   bool onOvertype(_str &key, int id)
   {
      if (id == m_open) {
         OvertypeMarker.removeMarker(id);
         m_open = -1;
      }
      if (id == m_close) {
         doExit();
      }
      return(true);
   }

   void onTextChange(long startOffset, long endOffset)
   {
      if (!_StreamMarkerGet(m_start, auto startInfo) && !_StreamMarkerGet(m_close, auto endInfo)) {
         if (p_TextWrapChangeNotify) {
            return;
         }
         if (startInfo.Length > 0 && endInfo.Length > 0 &&
             startOffset >= startInfo.StartOffset &&
             endOffset <= endInfo.StartOffset + endInfo.Length) {
            return;
         }
      }
      doExit();
   }

   void onTextChangeUpdate() 
   {
      if (m_start < 0 || m_close < 0 ||
          _StreamMarkerGet(m_start, auto startInfo) ||
          _StreamMarkerGet(m_close, auto endInfo) ||
          startInfo.Length == 0 || endInfo.Length == 0) {

         doExit();
         return;
      }

      offset := _QROffset();
      if (offset < startInfo.StartOffset ||
          offset >= endInfo.StartOffset + endInfo.Length) {

         doExit();
         return;
      }
   }

   private void onDeleteText()
   {
      if (_StreamMarkerGet(m_start, auto startInfo) || _StreamMarkerGet(m_close, auto endInfo)) {
         doExit();
         return;
      }
      if (startInfo.buf_id == p_buf_id && startInfo.Length == 0) {
         if (endInfo.Length > 0) {
            long offset = endInfo.StartOffset;
            save_pos(auto p);
            _GoToROffset(offset);
            _delete_char();
            restore_pos(p);
         }
         doExit();
      }
   }

   // added for next/prev hotspot command (IHotspotMarker)
   private bool onNextPrev(bool next)
   {
      m_exitMarker.gotoMarker();
      doExit();
      return(true);
   }

   // Save/restore stream markers for beautifer
   bool save(long (&markers)[], long (&cursorMarkerIndices)[], long startOffset, long endOffset)
   {
      if (m_start < 0 || m_close < 0 ||
          _StreamMarkerGet(m_start, auto startinfo) < 0 ||
          _StreamMarkerGet(m_close, auto endinfo) < 0) {

         doExit();
         return(false);
      }

      if (!_ranges_overlap(startinfo.StartOffset, endinfo.StartOffset + endinfo.Length, 
                           startOffset, endOffset)) {
         return(false);
      }

      index := markers._length();
      markers[index++] = startinfo.StartOffset;
      markers[index++] = startinfo.StartOffset + startinfo.Length;
      markers[index++] = endinfo.StartOffset;
      markers[index++] = endinfo.StartOffset + endinfo.Length;
      if (m_open >= 0) {
         _StreamMarkerGet(m_open, auto openinfo);
         markers[index++] = openinfo.StartOffset;
         markers[index++] = openinfo.StartOffset + openinfo.Length;
      } else {
         // Dummy values.  We're not reading them back on restore, 
         // but we want to keep them in the range of the bracket markers
         // since the beautifier adjusts the leading-context/beautify
         // range based on the min/max of these offsets.
         markers[index++] = startinfo.StartOffset;
         markers[index++] = startinfo.StartOffset;
      }

      if (def_beautifier_debug > 1) say("beautify: ["startOffset","endOffset"], autobracket range ["startinfo.StartOffset","endinfo.StartOffset + endinfo.Length"]");
      return(true);
   }

   void restore(long (&markers)[], int index)
   {
      if (index + 6 > markers._length()) {
         doExit();
         return;
      }

      long offset, len;
      offset = markers[index++];
      len = markers[index++] - offset;
      _StreamMarkerSetStartOffset(m_start, offset);  
      _StreamMarkerSetLength(m_start, len);

      offset = markers[index++];
      len = markers[index++] - offset;
      _StreamMarkerSetStartOffset(m_close, offset);
      _StreamMarkerSetLength(m_close, len);
      m_exitMarker.setMarker(offset + len - 1, 1);

      offset = markers[index++];
      len = markers[index++] - offset;
      if (m_open >= 0) {
         _StreamMarkerSetStartOffset(m_open, offset);
         _StreamMarkerSetLength(m_open, len);
      }
   }

   /************************************************************/
   private static AutoBracketMarker s_marker[];

   public static int createMarker(_str close_ch, long openOffset, long openLen, long closeOffset, long closeLen, int mode_keys=-1, long leadingOffset=-1, long leadingLen=-1)
   {
      if (_MultiCursor()) return -1;
      _updateTextChange();
      AutoBracketMarker marker;
      marker.m_mode_keys = mode_keys;
      marker.onCreate(close_ch, openOffset, openLen, closeOffset, closeLen);
      if (leadingOffset > 0) {
         marker.setOpenMarker(leadingOffset, leadingLen);
      }
      id := s_marker._length();
      s_marker[id] = marker;
      OvertypeMarker.addListener(&s_marker[id], s_marker[id].m_close);
      TextChangeNotify.addListener(&s_marker[id]);
      EventUI.addListener(&s_marker[id]);
      if (s_marker[id].m_open >= 0) {
         OvertypeMarker.addListener(&s_marker[id], s_marker[id].m_open);
      }
      return id;
   }


   static void checkDeletedMarkers()
   {
      id := s_marker._length() - 1;
      while (id >= 0) {
         s_marker[id].onDeleteText();
         --id;
      }
   }

   private static void removeMarker(AutoBracketMarker &marker)
   {
      for (id := 0; id < s_marker._length(); ++id) {
         if (s_marker[id] == marker) {
            s_marker[id] = null;
            s_marker._deleteel(id);
            break;
         }
      }
   }

   static void init()
   {
      s_openMarkerType = -1;
   }

   static void exit()
   {
      s_marker._makeempty();
   }
};

namespace default;
using namespace se.ui.AutoBracketMarker;

definit()
{
   AutoBracketMarker.init();
}

void _exit_se_ui_AutoBracketMarker()
{
   AutoBracketMarker.exit();
}

