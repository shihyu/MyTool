////////////////////////////////////////////////////////////////////////////////////
// $Revision: 46554 $
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
#pragma option(pedantic, on)
#region Imports
#import "slick.sh"
#import "markers.sh"
#import "xml.sh"
#import "stdcmds.e"
#import "stdprocs.e"
#import "wkspace.e"
#require "se/lineinfo/LineInfoCollection.e"
#require "Message.e"
#endregion

namespace se.messages;


enum MessageAspects {
   MESSAGES = 0
};


class MessageCollection : se.lineinfo.LineInfoCollection {
   //Messages getters, setters
   public void getMessages(se.messages.Message* (&msgs)[]);
   public void getMessage(se.messages.Message* (&msg), int idx);
   public void setMessage(se.messages.Message& msg, int idx);
   public void newMessageType(se.messages.Message& msgType,
                               _str picFileName='');
   public int newMessage(se.messages.Message& msg);
   public void newMessages(se.messages.Message (&msgs)[]);
   public void removeMessage(int index);
   public void removeMessages(_str creator=null, _str type=null,
                               int clearFlag=MSGCLEAR_ALWAYS);
   public void removeMessageTypes(_str creator=null, _str type=null);
   //
   public void createDeferredMarkers(int newBuffID, _str bufferName);
   //
   private void rehashMessageIDs();
   private void removeAllMessages();
   private int addSingleMessage(se.messages.Message& note);
   

   public int m_orphanedMessagePic = 0;
   public int m_messageMarkerType = 0;
   public int m_orphanedNoteMarkerType = 0;
   public int m_lMarkers:[];
   public int m_sMarkers:[];
   //The messages
   protected Message m_messages[];
   //
   protected Message m_messageTypeInfo:[]:[];
   protected _str m_fieldTypes:[]:[]; //the field types for :[message type]:[field name]
   protected _str m_freshestType = ''; //The most recent type used.
   protected int m_allMessages[];
   private boolean m_freshSourceFiles:[];
   private boolean m_initialized;
   //Messages that haven't yet made stream markers.
   protected int m_deferredMessages:[][];
   //Arrays for indexing the messages.
   protected int m_lastMessages[];
   protected int m_activeMessages:[];
   protected int m_creators:[][];
   protected int m_dates:[][];
   protected int m_sourceFiles:[][];
   protected int m_shortSourceFiles:[][];
   protected int m_types:[][];
   //protected int m_customFields:[][];
   //protected int m_messageIndices:[]:[];
   // default picture and marker types are singletons
   static protected int s_defaultPic=0;
   static protected int s_defaultTypeIDX=0;

   MessageCollection()
   {
      m_initialized = false;
   }
   ~MessageCollection() {
      foreach (auto creator in m_messageTypeInfo) {
         foreach (auto type in creator) {
            if (type.m_markerTypeAllocated) {
               _MarkerTypeFree(type.m_markerType);
            }
         }
      }
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void initMessageCollection()
   {
      s_defaultTypeIDX=0;
      if (!m_initialized) {
         m_initialized = true;
         removeAllMessages();
      }
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void getMessages(se.messages.Message* (&msgs)[])
   {
      int i;
      for (i = 0; i < m_messages._length(); ++i) {
         msgs[i] = &m_messages[i];
      }
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void getMessage(se.messages.Message* (&msg), int idx)
   {
      if ((idx >= 0) && (idx < m_messages._length())) {
         msg = &m_messages[idx];
      } else {
         msg = null;
      }
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void setMessage(se.messages.Message& note, int idx)
   {
      if ((idx >= 0) && (idx < m_messages._length())) {
         m_messages[idx] = note;
      } else {
         return;
      }
      notifyObservers();
   }


   /**
    * 
    * 
    * 
    * 
    */
   void newMessageType(se.messages.Message& msgType, _str picFileName='')
   {
      if (msgType.m_markerPic <= 0) {
         int picIndex = -1;
         if (picFileName != '') {
            picIndex = _update_picture(-1, picFileName);
         }
         if (picIndex < 0) {
            if (s_defaultPic <= 0) {
               s_defaultPic = _update_picture(-1, '_errmark.ico');
            }
            msgType.m_markerPic = s_defaultPic;
         } else {
            msgType.m_markerPic = picIndex;
         }
      }
      if (msgType.m_markerType <= 0) {
         msgType.m_markerType = _MarkerTypeAlloc();
         msgType.m_markerTypeAllocated = true;
      }

      m_messageTypeInfo:[msgType.m_creator]:[msgType.m_type] = msgType;
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   int newMessage(se.messages.Message& note)
   {
      int i = addSingleMessage(note);
      if (i < 0) return i;
      notifyObservers();

      return i;
   }


   /**
    * Author: nbeddes
    * Date:   12/5/2007
    * 
    * 
    * 
    * 
    */
   void newMessages(se.messages.Message (&msgs)[])
   {
      int i;
      for (i = 0; i < msgs._length(); ++i) {
         addSingleMessage(msgs[i]);
      }
      notifyObservers();
   }


   /**
    * Author: nbeddes
    * Date:   11/30/2007
    * 
    * 
    * 
    * 
    */
   void removeAllMessages()
   {
      int i;
      for (i = 0; i < m_messages._length(); ++i) {
         m_messages[i].removeMarker();
         m_messages[i].delete();
      }
      m_messages._makeempty();
      m_activeMessages._makeempty();
      m_allMessages._makeempty();
      m_creators._makeempty();
      m_dates._makeempty();
      m_lastMessages._makeempty();
      m_shortSourceFiles._makeempty();
      m_sourceFiles._makeempty();
      m_types._makeempty();
      m_files._makeempty();
      m_messageTypeInfo._makeempty();
      notifyObservers();
   }


   /**
    * Author: nbeddes
    * Date:   11/13/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void removeMessage(int index)
   {
      if ((index >= 0) && (index < m_messages._length())) {
         m_messages[index].removeMarker();
         m_messages[index].delete();
         m_messages._deleteel(index);
         rehashMessageIDs();
      }
      notifyObservers();
   }


   /**
    * Author: nbeddes
    * Date:   11/30/2007
    * 
    * When asked to remove by creator AND by type, only the 
    * messages matching both the creator and type are removed. 
    * Otherwise, remove remove all messages of by that creator or 
    * of that type. 
    *  
    */
   void removeMessages(_str creator=null, _str type=null,
                        int clearFlag=MSGCLEAR_ALWAYS)
   {
      int i;
      int messageCount = (m_messages._length() - 1);
      if (creator == null) {
         if (type == null) {
            for (i = messageCount; i >= 0; --i) {
               if (m_messages[i].m_autoClear & clearFlag) {
                  m_messages[i].removeMarker();
                  m_messages[i].delete();
                  m_messages._deleteel(i);
               }
            }
         } else {
            //Remove by type alone.
            for (i = messageCount; i >= 0; --i) {
               if (m_messages[i].m_type == type) {
                  m_messages[i].removeMarker();
                  m_messages[i].delete();
                  m_messages._deleteel(i);
               }
            }
         }
      } else if (type == null) {
         //Remove by creator alone.
         for (i = messageCount; i >= 0; --i) {
            if (m_messages[i].m_creator == creator) {
               m_messages[i].removeMarker();
               m_messages[i].delete();
               m_messages._deleteel(i);
            }
         }
      } else {
         //Remove by both creator and type.
         for (i = messageCount; i >= 0; --i) {
            if ((m_messages[i].m_type == type) &&
                (m_messages[i].m_creator == creator)){
               m_messages[i].removeMarker();
               m_messages[i].delete();
               m_messages._deleteel(i);
            }
         }
      }

      rehashMessageIDs();
      notifyObservers();
   }


   /**
    * Author: nbeddes
    * Date:   6/24/2008
    *
    * 
    * 
    * @param creator 
    * @param type 
    */
   void removeMessageTypes(_str creator=null, _str type=null)
   {
      if (creator==null) {
         if (type==null) {
            // Remove all message types
            typeless c;
            for (c._makeempty();;) {
               m_messageTypeInfo._nextel(c);
               if (c._isempty()) break;
               typeless t;
               for (t._makeempty();;) {
                  m_messageTypeInfo:[c]._nextel(t);
                  if (t._isempty()) break;
                  if (m_messageTypeInfo:[c]:[t].m_markerTypeAllocated) {
                     _MarkerTypeFree(m_messageTypeInfo:[c]:[t].m_markerType);
                  }
                  m_messageTypeInfo:[c]._deleteel(t);
               }
               m_messageTypeInfo._deleteel(c);
            }
         } else {
            // Remove a message type across creators
            typeless c;
            for (c._makeempty();;) {
               m_messageTypeInfo._nextel(c);
               if (c._isempty()) break;
               if (m_messageTypeInfo:[c]._indexin(type)) {
                  if (m_messageTypeInfo:[c]:[type].m_markerTypeAllocated) {
                     _MarkerTypeFree(m_messageTypeInfo:[c]:[type].m_markerType);
                  }
                  m_messageTypeInfo:[c]._deleteel(type);
               }
            }
         }
      } else {
         if ((type==null) &&
             (m_messageTypeInfo._indexin(creator))) {
            // Delete all message types from the specified creator.
            typeless t;
            for (t._makeempty();;) {
               m_messageTypeInfo:[creator]._nextel(t);
               if (t._isempty()) break;
               if (m_messageTypeInfo:[creator]:[t].m_markerTypeAllocated) {
                  _MarkerTypeFree(m_messageTypeInfo:[creator]:[t].m_markerType);
               }
               m_messageTypeInfo:[creator]._deleteel(t);
            }
         } else {
            // Delete a specific type from a specific creator 
            if (m_messageTypeInfo._indexin(creator) &&
                m_messageTypeInfo:[creator]._indexin(type)) {
               if (m_messageTypeInfo:[creator]:[type].m_markerTypeAllocated) {
                  _MarkerTypeFree(m_messageTypeInfo:[creator]:[type].m_markerType);
               }
               m_messageTypeInfo:[creator]._deleteel(type);
            }
         }
      }
   }


   /**
    * Author: nbeddes
    * Date:   11/8/2007
    * 
    * 
    * 
    * @param   
    * 
    * @return  
    */
   void rehashMessageIDs()
   {
      m_lMarkers._makeempty();
      m_sMarkers._makeempty();
      m_allMessages._makeempty();
      m_lastMessages._makeempty();
      m_activeMessages._makeempty();
      m_creators._makeempty();
      m_dates._makeempty();
      m_sourceFiles._makeempty();
      m_shortSourceFiles._makeempty();
      m_types._makeempty();
      m_deferredMessages._makeempty();

      _str shortSourceFile;
      _str date;
      int i;
      int noteCount = m_messages._length();
      for (i = 0; i < noteCount; ++i) {
         if (m_messages[i].m_lmarkerID != -1) {
            m_lMarkers:[m_messages[i].m_lmarkerID] = i;
         }
         if (m_messages[i].m_smarkerID != -1) {
            m_sMarkers:[m_messages[i].m_smarkerID] = i;
         }
         m_allMessages[i] = i;
         m_activeMessages:[i] = i;
         m_creators:[m_messages[i].m_creator][m_creators:[m_messages[i].m_creator]._length()] = i;
         parse m_messages[i].m_date with date " " . ;
         m_dates:[date][m_dates:[date]._length()] = i;
         m_sourceFiles:[maybe_quote_filename(m_messages[i].m_sourceFile)][m_sourceFiles:[maybe_quote_filename(m_messages[i].m_sourceFile)]._length()] = i;
         shortSourceFile = maybe_quote_filename(stranslate(_strip_filename(m_messages[i].m_sourceFile, "P"), '', '"'));
         m_shortSourceFiles:[shortSourceFile][m_shortSourceFiles:[shortSourceFile]._length()] = i;
         m_types:[lowcase(m_messages[i].m_type)][m_types:[lowcase(m_messages[i].m_type)]._length()] = i;
         if (m_messages[i].m_deferred) {
            m_deferredMessages:[m_messages[i].m_sourceFile][m_deferredMessages:[m_messages[i].m_sourceFile]._length()] = i;
         }
      }
   }


   void createDeferredMarkers(int newBuffID, _str bufferName)
   {
      typeless p;
      save_pos(p);

      long offset;
      int i;
      for (i = 0; i < m_deferredMessages:[bufferName]._length(); ++i) {
         p_RLine = m_messages[i].m_lineNumber;
         if ( isinteger(m_messages[i].m_colNumber) ) {
            p_col = m_messages[i].m_colNumber;
         }
         offset = _QROffset();
         m_messages[i].m_smarkerID = _StreamMarkerAddB(bufferName, offset,
                                                       m_messages[i].m_length, 1,
                                                       m_messages[i].m_markerPic,
                                                       m_messages[i].m_markerType,
                                                       m_messages[i].m_description);
         m_messages[i].m_deferred = false;
      }
      m_deferredMessages:[bufferName]._makeempty();

      restore_pos(p);
      notifyObservers();
   }


   void removeDeferredMarker(_str bufferName, int index)
   {
   }


   int addSingleMessage(se.messages.Message& note)
   {
      int i = m_messages._length();
      if ( i >= _default_option(VSOPTION_WARNING_ARRAY_SIZE) ) {
         return WARNINGARRAYSIZE_RC;
      }

      if (note.m_date == '') {
         _str year;
         _str month;
         _str day;
         parse _date() with month'/'day'/'year;
         if (length(month) < 2) {
            month = '0'month;
         }
         if (length(day) < 2) {
            day = '0'day;
         }
         note.m_date = year'/'month'/'day' '_time('M');
         //note.m_date = _time('B'); //'binary' date and time.
      }

      Message tmpMTI = null;
      if (m_messageTypeInfo._indexin(note.m_creator) && 
          m_messageTypeInfo:[note.m_creator]._indexin(note.m_type)) {
         tmpMTI = m_messageTypeInfo:[note.m_creator]:[note.m_type];
      }
      
      if (tmpMTI != null) {
         //There was special type information registered with the collection,
         //finish filling out the message.
         note.m_markerPic = tmpMTI.m_markerPic;
         note.m_deleteCallback = tmpMTI.m_deleteCallback;
         note.m_markerType = tmpMTI.m_markerType;
         note.m_autoClear = tmpMTI.m_autoClear;
      } else {
         //No special type specified, give the message the generic bitmap if 
         //the message hasn't specified it either:
         if (note.m_markerPic <= 0) {
            if (s_defaultPic <= 0) {
               s_defaultPic = _update_picture(-1, '_errmark.ico');
            }
            note.m_markerPic = s_defaultPic;
         }
         if (s_defaultTypeIDX <= 0) {
            s_defaultTypeIDX = _MarkerTypeAlloc();
            note.m_markerTypeAllocated = true;
         }
         note.m_markerType = s_defaultTypeIDX;
      }

      //Check to see if we need to make a line or stream marker for the new
      //message.
      if ((note.m_lmarkerID == -1) &&
          (note.m_smarkerID == -1) &&
          (note.m_lineNumber != 0)) {
         if (note.m_colNumber == 0) {
            //Make a line marker
            note.m_lmarkerID = _LineMarkerAddB(note.m_sourceFile,
                                               note.m_lineNumber, 0, 0,
                                               note.m_markerPic,
                                               note.m_markerType,
                                               note.m_description);
         } else {
            //Make a stream marker.
            _str buf_id;
            buf_id = buf_match(note.m_sourceFile, 1, 'IX');
            if (buf_id == '') {
               //The file isn't open, defer creation of the stream marker
               int defCount;
               defCount = m_deferredMessages:[note.m_sourceFile]._length();
               m_deferredMessages:[note.m_sourceFile][defCount] = i;
               note.m_deferred = true;
            } else {
               int orig_wid;
               int temp_wid;

               orig_wid = p_window_id;
               //_open_temp_view('', temp_wid, orig_wid, '+bi 'wid);
               _open_temp_view('', temp_wid, orig_wid, '+bi 'buf_id);
               p_RLine = note.m_lineNumber;
               if ( isinteger(note.m_colNumber) ) p_col = note.m_colNumber;
               long offset = _QROffset();
               note.m_smarkerID = _StreamMarkerAddB(note.m_sourceFile,
                                                    offset, note.m_length,
                                                    1, note.m_markerPic,
                                                    note.m_markerType,
                                                    note.m_description);
               p_window_id = orig_wid;
               _delete_temp_view(temp_wid);
            }
         }
      }

      //Add the note.
      m_messages[i] = note;

      //Add all the indexing.
      if (m_messages[i].m_lmarkerID != -1) {
         m_lMarkers:[m_messages[i].m_lmarkerID] = i;
      }
      if (m_messages[i].m_smarkerID != -1) {
         m_sMarkers:[m_messages[i].m_smarkerID] = i;
      }
      _str shortNoteFile;
      _str shortSourceFile;
      _str date;
      m_allMessages[i] = i;
      m_activeMessages:[i] = i;
      m_creators:[m_messages[i].m_creator][m_creators:[m_messages[i].m_creator]._length()] = i;
      parse m_messages[i].m_date with date " " . ;
      m_dates:[date][m_dates:[date]._length()] = i;
      m_sourceFiles:[maybe_quote_filename(m_messages[i].m_sourceFile)][m_sourceFiles:[maybe_quote_filename(m_messages[i].m_sourceFile)]._length()] = i;
      shortSourceFile = maybe_quote_filename(_strip_filename(m_messages[i].m_sourceFile, "P"));
      m_shortSourceFiles:[shortSourceFile][m_shortSourceFiles:[shortSourceFile]._length()] = i;
      m_types:[lowcase(m_messages[i].m_type)][m_types:[m_messages[i].m_type]._length()] = i;
      //m_messageIndices:[maybe_quote_filename(_mdi.p_child.p_buf_name)]:[_mdi.p_child.p_RLine] = i;

      return i;
   }
};

namespace default;

se.messages.MessageCollection* get_messageCollection()
{
   // sometimes this is called after the mdi window has been DESTROYED!!!!
   if (_iswindow_valid(_mdi)) {
      se.messages.MessageCollection* mCollection = _GetDialogInfoHtPtr("messageCollection", _mdi);
      if (mCollection) {
         return mCollection;
      }

      se.messages.MessageCollection msgCollection;
      _SetDialogInfoHt("messageCollection", msgCollection, _mdi);
      mCollection = _GetDialogInfoHtPtr("messageCollection", _mdi);
      mCollection->initMessageCollection();
      return mCollection;
   }

   return null;
}



void _buffer_add_message_markers(int newBuffID, _str name, int flags = 0)
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->createDeferredMarkers(newBuffID, name);
   }
}



void _cbquit_Messages(int buf_id, _str buf_name)
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->removeMessages(null, null, MSGCLEAR_BUFFER);
   }
}
void _project_close_Messages()
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->removeMessages(null, null, MSGCLEAR_PROJECT);
   }
}
void _wkspace_close_Messages()
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->removeMessages(null, null, MSGCLEAR_WKSPACE);
   }
}
