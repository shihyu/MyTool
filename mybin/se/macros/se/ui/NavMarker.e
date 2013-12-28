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
#import "stdprocs.e"
#import "recmacro.e"
#endregion

/**
 * def_display_nav_hints:
 *    0: none
 *    1: display caret
 *    2: display vertical pipe
 *
 */
int def_display_nav_hints = 1;

namespace se.ui;

class NavMarker {
   private static int s_markerTypeRight = -1;
   private static int s_markerTypeLeft = -1;
   private static int s_hiddenType = -1;

   static void initMarkerType()
   {
      s_markerTypeRight = -1;
      s_markerTypeLeft = -1;
      s_hiddenType = -1;
   }

   private static int getMarkerType(int side)
   {
      int type = (side) ? s_markerTypeRight : s_markerTypeLeft;
      if (type < 0) {
         if (side) {
            s_markerTypeRight = _MarkerTypeAlloc();
         } else {
            s_markerTypeLeft = _MarkerTypeAlloc();
         }
         type = (side) ? s_markerTypeRight : s_markerTypeLeft;
         updateMarkerStyle(side);
      }
      return type;
   }

   static void updateMarkerStyle(int side)
   {
      int type = (side) ? s_markerTypeRight : s_markerTypeLeft;
      if (type > 0) {
         int markerStyle = 0;
         switch (def_display_nav_hints) {
         case 1:
            markerStyle |= (side) ? VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_RIGHT : VSMARKERTYPEFLAG_DRAW_TRIANGLE_BOTTOM_LEFT;
            break;
         case 2:
            markerStyle |= (side) ? VSMARKERTYPEFLAG_DRAW_LINE_RIGHT : VSMARKERTYPEFLAG_DRAW_LINE_LEFT;
            break;
         }
        _MarkerTypeSetFlags(type, markerStyle);
      }
   }

   private static int getHiddenType()
   {
      if (s_hiddenType < 0) {
         s_hiddenType = _MarkerTypeAlloc();
         _MarkerTypeSetFlags(s_hiddenType, 0);
      }
      return s_hiddenType;
   }

   static void removeBuffer()
   {
      if (s_markerTypeRight > 0) {
         _StreamMarkerRemoveType(p_window_id, s_markerTypeRight);
      }
      if (s_markerTypeLeft > 0) {
         _StreamMarkerRemoveType(p_window_id, s_markerTypeLeft);
      }
      if (s_hiddenType > 0) {
         _StreamMarkerRemoveType(p_window_id, s_hiddenType);
      }
   }

   static void updateMarkerColor(int fg_color)
   {
      if(s_markerTypeRight < 0 && s_markerTypeLeft < 0) {
         return;
      }
      get_window_id(auto orig_view_id);
      activate_window(VSWID_HIDDEN);
      _safe_hidden_window();
      int orig_buf_id = p_buf_id;
      int first_buf_id = _mdi.p_child.p_buf_id;
      p_buf_id = first_buf_id;
      for (;;) {
         int list[];
         if (s_markerTypeRight > 0) {
            _StreamMarkerFindList(list, p_window_id, 0, p_buf_size, VSNULLSEEK, s_markerTypeRight);
            if (!list._isempty()) {
               foreach (auto id in list) {
                  _StreamMarkerSetStyleColor(id, fg_color);
               }
            }
         }
         if (s_markerTypeLeft > 0) {
            _StreamMarkerFindList(list, p_window_id, 0, p_buf_size, VSNULLSEEK, s_markerTypeLeft);
            if (!list._isempty()) {
               foreach (auto id in list) {
                  _StreamMarkerSetStyleColor(id, fg_color);
               }
            }
         }
         _next_buffer('hr');
         if (p_buf_id == first_buf_id) {
            break;
         }
      }
      p_buf_id = orig_buf_id;
      activate_window(orig_view_id);
   }

   /************************************************************/
   private int m_marker = -1;
   private int m_side = 0;

   NavMarker(long offset = -1, int side = 0, _str msg = '')
   {
      if (offset < 0) {
         return;
      }
      setMarker(offset, side, msg);
   }

   void setMarker(long offset, int side = 0, _str msg = '')
   {
      m_side = side;
      if (m_marker < 0 || _StreamMarkerGet(m_marker, auto info) < 0) {
         m_marker = _StreamMarkerAdd(p_window_id, offset, 1, true, 0, getMarkerType(m_side), (def_display_nav_hints) ? msg : '');
         parse _default_color(CFG_NAVHINT) with auto fg_color .;
         _StreamMarkerSetStyleColor(m_marker, (int)fg_color);

      } else {
         _StreamMarkerSetStartOffset(m_marker, offset);
         _StreamMarkerSetLength(m_marker, 1);
      }
   }

   void resetColor(int fg_color)
   {
      if (m_marker > -1) {
         _StreamMarkerSetStyleColor(m_marker, fg_color);
      }
   }

   void hide()
   {
       if (m_marker >= 0) {
          _StreamMarkerSetType(m_marker, getHiddenType());
       }
   }

   void show()
   {
       if (m_marker >= 0) {
          _StreamMarkerSetType(m_marker, getMarkerType(m_side));
       }
   }

   void remove()
   {
       if (m_marker >= 0) {
         _StreamMarkerRemove(m_marker);
         m_marker = -1;
       }
   }

   void gotoMarker()
   {
      if (m_marker < 0 || !_isEditorCtl()) {
         return;
      }
      if (_StreamMarkerGet(m_marker, auto info)) {
         return;
      }
      if (info.isDeferred || info.buf_id != p_buf_id) {
         return;
      }
      if (info.StartOffset > 0 && info.Length > 0) {
         line := p_line; col := p_col;
         long offset = m_side ? info.StartOffset + info.Length : info.StartOffset;
         _GoToROffset(offset);

         _macro('m', _macro('s'));
         if (p_line != line) {
            _macro_append("p_line += "p_line - line";");
         }
         if (p_col != col) {
            _macro_append("p_col += "p_col - col";");
         }
      }
   }

   long getOffset()
   {
      if (m_marker >= 0) {
         if (!_StreamMarkerGet(m_marker, auto info)) {
            return info.StartOffset;
         }
      }
      return -1;
   }

   int getMarkerID()
   {
      return m_marker;
   }
};

namespace default;
using namespace se.ui.NavMarker;

definit()
{
   NavMarker.initMarkerType();
}

void _reset_se_ui_NavMarker()
{
   NavMarker.updateMarkerStyle(0);
   NavMarker.updateMarkerStyle(1);
}

void _cbquit_se_ui_NavMarker(int bufID, _str name)
{
   NavMarker.removeBuffer();
}

