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
#require "se/ui/ITextChangeListener.e"
#endregion

namespace se.ui;

class TextChangeNotify {
   private ITextChangeListener *m_list[];

   private void add(ITextChangeListener *ui)
   {
      if (m_list._length() == 0) {
         addCallbacks();
      }
      m_list[m_list._length()] = ui;
   }

   private void remove(ITextChangeListener *ui)
   {
      for (id := 0; id < m_list._length(); ++id) {
         if (m_list[id] == ui) {
            m_list[id] = null;
            m_list._deleteel(id);
            break;
         }
      }
      if (m_list._length() == 0) {
         removeCallbacks();
      }
   }

   void onTextChange(long startOffset, long endOffset)
   {
      id := m_list._length() - 1;
      while (id >= 0) {
         m_list[id]->onTextChange(startOffset, endOffset);
         --id;
      }
   }

   void onTextChangeUpdate()
   {
      id := m_list._length() - 1;
      while (id >= 0) {
         m_list[id]->onTextChangeUpdate();
         --id;
      }
   }

   /************************************************************/
   private static TextChangeNotify s_buffers:[];
   private static bool s_enabled = true;

   private static void removeCallbacks()
   {
      _RemoveTextChangeCallback(p_window_id, find_index('se.ui.TextChangeNotify.onTextChangeCallback', PROC_TYPE));
   }

   private static void addCallbacks()
   {
      _AddTextChangeCallback(p_window_id, find_index('se.ui.TextChangeNotify.onTextChangeCallback', PROC_TYPE));
   }

   static void init()
   {
      s_buffers._makeempty();
   }

   static void removeBuffer(int bufID)
   {
      if (s_buffers._indexin(bufID)) {
         s_buffers._deleteel(bufID);
      }
   }

   static void addListener(ITextChangeListener *ui)
   {
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID)) {
         TextChangeNotify ev;
         s_buffers:[bufID] = ev;
      }
      s_buffers:[bufID].add(ui);
   }

   static void removeListener(ITextChangeListener *ui, int bufID = -1)
   {
      if (bufID < 0) {
         bufID = p_buf_id;
      }
      if (s_buffers._indexin(bufID) && !s_buffers:[bufID]._isempty()) {
         s_buffers:[bufID].remove(ui);
      }
   }

   static bool enableTextChange(bool newValue)
   {
      oldValue := s_enabled;
      s_enabled = newValue;
      return oldValue;
   }

   private static void onTextChangeCallback(long startOffset, long endOffset)
   {
      if (!s_enabled) {
         return;
      }
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID)) {
         return;
      }
      s_buffers:[bufID].onTextChange(startOffset, endOffset);
   }

   static void updateTextChange()
   {
      if (!s_enabled) {
         return;
      }
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID)) {
         return;
      }
      s_buffers:[bufID].onTextChangeUpdate();
   }
};

namespace default;
using namespace se.ui.TextChangeNotify;

definit()
{
   TextChangeNotify.init();
}

void _exit_se_ui_TextChange()
{
   TextChangeNotify.init();
}

void _cbquit_se_ui_TextChange(int bufID, _str name)
{
   TextChangeNotify.removeBuffer(bufID);
}

