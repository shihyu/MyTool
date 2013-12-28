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
#import "vi.e"
#require "se/ui/IKeyEventCallback.e"
#endregion

namespace se.ui;

class EventUI {
   private IKeyEventCallback *m_eventList[];

   EventUI()
   {
   }

   private void add(IKeyEventCallback *ui)
   {
      if (m_eventList._length() > 0) {
         IKeyEventCallback *ev = m_eventList._lastel();
         ev->onPop();
      }
      m_eventList[m_eventList._length()] = ui;
      ui->onPush();
   }

   private void remove(IKeyEventCallback *ui)
   {
      push := false;
      for (id := 0; id < m_eventList._length(); ++id) {
         if (m_eventList[id] == ui) {
            push = (id == m_eventList._length() - 1);
            (*m_eventList[id]).onRemove();
            m_eventList[id] = null;
            m_eventList._deleteel(id);
            break;
         }
      }
      if (m_eventList._isempty() || m_eventList._length() == 0) {
         setCallbacks(null);

      } else if (push) {
         IKeyEventCallback *ev = m_eventList._lastel();
         ev->onPush();
      }
   }

   void removeAll()
   {
      foreach (auto ev in m_eventList) {
         ev->onRemove();
      }
      m_eventList._makeempty();
      setCallbacks(null);
   }

   boolean onKey(_str &key)
   {
      if (m_eventList._isempty()) {
         return(false);
      }
      status := false;
      cnt := m_eventList._length();
      id := m_eventList._length() - 1;
      while (!status && id >= 0) {
         status = m_eventList[id]->onKey(key);
         --id;
      }
      if (status) {
         if (key :== ESC && def_keys == 'vi-keys' && def_vim_esc_codehelp) {
            vi_escape();
         }
      }
      return(status);
   }

   /************************************************************/
   private static EventUI s_buffers:[];
   private static boolean s_enabled = true;

   static void init()
   {
      s_buffers._makeempty();
   }

   static void removeBuffer(int bufID)
   {
      if (s_buffers._indexin(bufID)) {
         s_buffers:[bufID].removeAll();
         s_buffers._deleteel(bufID);
      }
   }

   static void addListener(IKeyEventCallback *ui)
   {
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID)) {
         EventUI ev;
         s_buffers:[bufID] = ev;
      }
      s_buffers:[bufID].add(ui);
   }

   static void removeListener(IKeyEventCallback *ui)
   {
      bufID := p_buf_id;
      if (s_buffers._indexin(bufID) && !s_buffers:[bufID]._isempty()) {
         s_buffers:[bufID].remove(ui);
      }
   }

   static IKeyEventCallback* get()
   {
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID) || s_buffers:[bufID]._isempty() ||
          s_buffers:[bufID].m_eventList._isempty() ||
          s_buffers:[bufID].m_eventList._length() == 0) {
         return null;
      }
      return s_buffers:[bufID].m_eventList._lastel();
   }

   static void beautifySave(IKeyEventCallback* (&cb)[], int (&markerIndex)[], long (&markers)[], long startOffset, long endOffset)
   {
      cb._makeempty();
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID) || s_buffers:[bufID]._isempty() ||
          s_buffers:[bufID].m_eventList._isempty() ||
          s_buffers:[bufID].m_eventList._length() == 0) {
         return;
      }

      id := s_buffers:[bufID].m_eventList._length() - 1;
      while (id >= 0) {
         IKeyEventCallback* ev = s_buffers:[bufID].m_eventList[id];
         len := markers._length();
         if (ev->save(markers, startOffset, endOffset)) {
            markerIndex[markerIndex._length()] = len;
            cb[cb._length()] = ev;
         }
         --id;
      }
   }

   static void beautifyRestore(IKeyEventCallback* (&cb)[],  int (&markerIndex)[], long (&markers)[])
   {
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID) || s_buffers:[bufID]._isempty() || cb._isempty()) {
         return;
      }

      i := 0;
      len := cb._length();
      id := s_buffers:[bufID].m_eventList._length() - 1;
      while (id >= 0) {
         IKeyEventCallback* ev = s_buffers:[bufID].m_eventList[id];
         if (ev == cb[i]) {
            ev->restore(markers, markerIndex[i]);
            ++i;
            if (i >= len) {
               break;
            }
         }
         --id;
      }
      }

   static boolean enableKeyEvents(boolean newValue)
   {
      oldValue := s_enabled;
      s_enabled = newValue;
      return oldValue;
   }

   private static boolean onKeyCallback(_str key)
   {
      if (!s_enabled) {
         return(false);
      }
      bufID := p_buf_id;
      if (!s_buffers._indexin(bufID) || s_buffers:[bufID]._isempty()) {
         return(false);
      }
      return(s_buffers:[bufID].onKey(key));
   }

   static void setCallbacks(_str (&keyarray)[], _str option = '')
   {
      _kbd_add_callback(find_index('se.ui.EventUI.onKeyCallback', PROC_TYPE), keyarray, option);
   }

   static void initCallbacks()
   {
      _kbd_add_callback(find_index('se.ui.EventUI.onKeyCallback', PROC_TYPE), null);
   }
};

namespace default;
using namespace se.ui.EventUI;

definit()
{
   EventUI.init();
}

void _exit_se_ui_EventUI()
{
   EventUI.init();
}

void _cbquit_se_ui_EventUI(int bufID, _str name)
{
   EventUI.removeBuffer(bufID);
}

void setEventUICallbacks()
{
   EventUI.initCallbacks();
}

