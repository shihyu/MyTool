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
#import "bind.e"
#import "stdprocs.e"
#require "se/ui/IKeyEventCallback.e"
#require "se/ui/ITextChangeListener.e"
#require "se/ui/EventUI.e"
#require "se/ui/TextChange.e"
#endregion

namespace se.ui;

class DocSearchForm : IKeyEventCallback, ITextChangeListener {
   static _str s_command_key:[] = null;
   static bool s_events_loaded = false;

   static private void addCommandBindings(_str command)
   {
      ktab_index := find_index("default_keys", EVENTTAB_TYPE);

      VSEVENT_BINDING list[];
      list._makeempty();
      index := find_index(command, COMMAND_TYPE);
      list_bindings(ktab_index, list, index);
      int i, n = list._length();
      for (i = 0; i < n; ++i) {
         if (list[i].binding == index) {
            if (!vsIsOnEvent(list[i].iEvent)) {
               if (list[i].iEvent == list[i].iEndEvent) {
                  id := index2event(list[i].iEvent);
                  s_command_key:[id] = command;
               }
            }
         }
      }
   }

   static private void loadCommandKeys()
   {
      if (s_events_loaded) {
         return;
      }
      s_command_key._makeempty();
      addCommandBindings("find_next");
      addCommandBindings("search_again");
      addCommandBindings("find_prev");
      s_events_loaded = true;
   }

   private int m_form_wid = -1;
   private int m_wid = -1;
   private int m_buf_id = -1;
   private _str m_buf_name = '';
   private int m_key_callback_index = 0;
   private int m_text_change_callback_index = 0;

   /************************************************************/
   public DocSearchForm()
   {
   }

   public ~DocSearchForm()
   {
   }

   private void add(int form_wid, int editorctl_wid, int key_callback_index, int text_change_callback_index)
   {
      if (m_wid > 0) {
         remove();
      }  
      if (!_iswindow_valid(editorctl_wid) || !editorctl_wid._isEditorCtl()) {
         return;
      }

      loadCommandKeys();

      get_window_id(auto wid);
      activate_window(editorctl_wid);
      EventUI.addListener(&this);
      TextChangeNotify.addListener(&this);
      activate_window(wid);

      m_form_wid = form_wid;
      m_wid = editorctl_wid;
      m_buf_id = editorctl_wid.p_buf_id;
      m_buf_name = editorctl_wid.p_buf_name;

      m_key_callback_index = key_callback_index;
      m_text_change_callback_index = text_change_callback_index;
   }

   private void remove()
   {
      m_form_wid = -1;
      if (m_wid < 0 || !_iswindow_valid(m_wid) || !m_wid._isEditorCtl()) {
         m_wid = -1;
         return;
      }
      get_window_id(auto wid);
      activate_window(m_wid);
      EventUI.removeListener(&this, m_buf_id);
      TextChangeNotify.removeListener(&this, m_buf_id);
      activate_window(wid);
      m_wid = -1;
      m_key_callback_index = 0;
      m_text_change_callback_index = 0;
   }

   bool onKey(_str &key)
   {
      if (m_form_wid < 0 || !_iswindow_valid(m_form_wid) || m_form_wid.p_object != OI_FORM) {
         remove();
         return(false);
      }
      if (m_key_callback_index && index_callable(m_key_callback_index)) {
         command := '';
         if (s_command_key._indexin(key)) {
            command = s_command_key:[key];
         }
         return call_index(m_form_wid, key, command, m_key_callback_index);
      }
      return(false);
   }

   void onPush()
   {
      _str keyarray[];  // this could be static
      keyarray[0] = ESC;

      foreach (auto event => auto id in s_command_key) {
         keyarray[keyarray._length()] = event;
      }  
      EventUI.setCallbacks(keyarray);
   }

   void onPop()
   {
   }

   void onRemove()
   {
   }

   // Save/restore stream markers for beautifer
   bool save(long (&markers)[], long (&cursorMarkerIndices)[], long startOffset, long endOffset)
   {
      return(true);
   }

   void restore(long (&markers)[], int index)
   {
   }

   // text change notifications
   void onTextChange(long startOffset, long endOffset)
   {
      if (p_TextWrapChangeNotify) {
         return;
      }
      if (m_text_change_callback_index && index_callable(m_text_change_callback_index)) {
         call_index(m_form_wid, p_window_id, startOffset, endOffset, m_text_change_callback_index);
      }
   }

   void onTextChangeUpdate() 
   {
      offset := _QROffset();
      if (m_text_change_callback_index && index_callable(m_text_change_callback_index)) {
         call_index(m_form_wid, p_window_id, offset, offset, m_text_change_callback_index);
      }
   }

   static DocSearchForm s_inst = null;
   static void init(int form_wid, int editorctl_wid, int key_callback_index, int text_change_callback_index)
   {
      if (s_inst == null) {
         s_inst._construct("se.ui.DocSearchForm");
      }
      s_inst.add(form_wid, editorctl_wid, key_callback_index, text_change_callback_index);
   }

   static void destroy()
   {
      if (s_inst != null) {
         s_inst.remove();
      }
      s_inst = null;
   }

   static bool switchBuffer(int wid, int buf_id, _str buf_name)
   {
      if (s_inst == null) {
         return false;
      }

      if (wid != s_inst.m_wid) {
         return false;
      }

      if (buf_id != s_inst.m_buf_id || buf_name != s_inst.m_buf_name) {
         return true;
      }
      return false;
   }
};

namespace default;
using namespace se.ui.DocSearchForm;

definit()
{
   DocSearchForm.s_events_loaded = false;
}

void _eventtab_modify_se_ui_DocSearchForm(typeless keytab_used, _str event="")
{
   DocSearchForm.s_events_loaded = false;
}

