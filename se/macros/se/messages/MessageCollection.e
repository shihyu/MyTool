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
#include "slick.sh"
#include "markers.sh"
#include "xml.sh"
#require "se/lineinfo/LineInfoCollection.e"
#require "se/messages/Message.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "wkspace.e"
#endregion

namespace se.messages;


enum MessageAspects {
   MESSAGES = 0
};


class MessageCollection : se.lineinfo.LineInfoCollection {
   /*
   //Messages getters, setters
   public void getMessages(se.messages.Message* (&msgs)[]);
   public void getMessage(se.messages.Message* (&msg), int idx);
   public void setMessage(se.messages.Message& msg, int idx);
   public void newMessageType(se.messages.Message& msgType,
                               _str picFileName="");
   public int newMessage(se.messages.Message& msg);
   public void newMessages(se.messages.Message (&msgs)[]);
   public void removeMessage(int index);
   public void removeMessages(_str creator=null, _str type=null,
                               Message.MSGCLEAR_FLAGS clearFlag=Message.MSGCLEAR_ALWAYS);
   public void removeMessageTypes(_str creator=null, _str type=null);
   //
   public void createDeferredMarkers(int newBuffID, _str bufferName);
   //
   private void rehashMessageIDs();
   private void removeAllMessages();
   private int addSingleMessage(se.messages.Message& note);
     */

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
   protected _str m_freshestType = ""; //The most recent type used.
   protected int m_allMessages[];
   private bool m_freshSourceFiles:[];
   private bool m_initialized;
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
   protected bool m_needsRehash;

   // default picture and marker types are singletons
   static protected int s_defaultPic=0;
   static protected int s_defaultTypeIDX=0;


   MessageCollection()
   {
      m_initialized = false;
      m_needsRehash = false;
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
    * Find all the messages for the given source file.
    * 
    * @param sourceFile     source file name (usually p_buf_name) 
    * @param msgs           (output) pointers to messages for the source file
    * @param ids            (output) message index for each one found
    */
   void getMessagesInFile(_str sourceFile, se.messages.Message* (&msgs)[], int (&ids)[])
   {
      if (m_needsRehash) rehashMessageIDs();
      ids = m_sourceFiles:[_file_case(sourceFile)];
      msgs._makeempty();
      index := 0;
      foreach (index in ids) {
         if (index < 0 || index >= m_messages._length()) continue;
         msg := m_messages[index];
         if (msg == null) continue;
         if (!file_eq(sourceFile, msg.m_sourceFile)) {
            continue;
         }
         msgs :+= &m_messages[index];;
      }
   }

   // Remove all of the messages for a given file/buffer name 
   // in one batch.
   void removeMessagesForBuffer(_str buf)
   {
      // Initially thought to use getMessageInFile() and removeMessage()
      // to do this.  But getting the ordering right with the index is a pain,
      // and removeMsg() does a notifyObserver() for each call, which we 
      // definitely do not want, so we remove things manually in a batch, 
      // and then do a single rehash and notify.
      int messageCount = (m_messages._length() - 1);
      test := _file_case(buf);
      for (i := messageCount; i >= 0; --i) {
         if (m_messages[i] != null && file_eq(m_messages[i].m_sourceFile, test)) {
            m_messages[i].removeMarker();
            m_messages[i].delete();
            m_messages._deleteel(i);
            m_needsRehash=true;
         }
      }

      if (m_needsRehash) {
         rehashMessageIDs();
         notifyObservers();
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
      n := m_messages._length();
      for (i := 0; i < n; ++i) {
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
      m_needsRehash=true;
      notifyObservers();
   }


   /**
    * 
    * 
    * 
    * 
    */
   void newMessageType(se.messages.Message& msgType, _str picFileName="")
   {
      if (msgType.m_markerPic <= 0) {
         picIndex := -1;
         if (picFileName != "") {
            picIndex = _find_or_add_picture(picFileName);
         }
         if (picIndex < 0) {
            if (s_defaultPic <= 0) {
               s_defaultPic = _find_or_add_picture("_ed_error.svg");
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
      m_needsRehash = false;
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
         m_needsRehash=true;
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
                        Message.MSGCLEAR_FLAGS clearFlag=Message.MSGCLEAR_ALWAYS)
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
                  m_needsRehash=true;
               }
            }
         } else {
            //Remove by type alone.
            for (i = messageCount; i >= 0; --i) {
               if (m_messages[i].m_type == type) {
                  m_messages[i].removeMarker();
                  m_messages[i].delete();
                  m_messages._deleteel(i);
                  m_needsRehash=true;
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
               m_needsRehash=true;
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
               m_needsRehash=true;
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
   void rehashMessageIDs(bool force=false)
   {
      if (!m_needsRehash && !force) return;

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

      noteCount := m_messages._length();
      for (i := 0; i < noteCount; ++i) {
         if (m_messages[i].m_lmarkerID != -1) {
            m_lMarkers:[m_messages[i].m_lmarkerID] = i;
         }
         if (m_messages[i].m_smarkerID != -1) {
            m_sMarkers:[m_messages[i].m_smarkerID] = i;
         }
         m_allMessages[i] = i;
         m_activeMessages:[i] = i;
         m_creators:[m_messages[i].m_creator] :+= i;
         parse m_messages[i].m_date with auto date " " . ;
         m_dates:[date] :+= i;
         m_sourceFiles:[_file_case(m_messages[i].m_sourceFile)] :+= i;
         shortSourceFile := _file_case(stranslate(_strip_filename(m_messages[i].m_sourceFile, "P"), "", '"'));
         m_shortSourceFiles:[shortSourceFile] :+= i;
         m_types:[lowcase(m_messages[i].m_type)] :+= i;
         if (m_messages[i].m_deferred) {
            m_deferredMessages:[m_messages[i].m_sourceFile] :+= i;
         }
      }
      m_needsRehash = false;
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
                                                       m_messages[i].m_length, true,
                                                       m_messages[i].m_markerPic,
                                                       m_messages[i].m_markerType,
                                                       m_messages[i].getDescription());
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
      i := m_messages._length();
      if ( i >= _default_option(VSOPTION_WARNING_ARRAY_SIZE) ) {
         return WARNINGARRAYSIZE_RC;
      }

      if (note.m_date == "") {
         _str year;
         _str month;
         _str day;
         parse _date() with month"/"day"/"year;
         if (length(month) < 2) {
            month = "0"month;
         }
         if (length(day) < 2) {
            day = "0"day;
         }
         note.m_date = year"/"month"/"day" "_time('M');
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
               s_defaultPic = _find_or_add_picture("_ed_error.svg");
            }
            note.m_markerPic = s_defaultPic;
         }
         if (s_defaultTypeIDX <= 0) {
            s_defaultTypeIDX = _MarkerTypeAlloc();
            note.m_markerTypeAllocated = true;
         }
         note.m_markerType = s_defaultTypeIDX;
      }

      // keep track of the original line number information they gave us
      note.m_origLineNumber = note.m_lineNumber;
      note.m_origColNumber  = note.m_colNumber;

      // if they already gave us a note like this one, just increment the repeat count
      if (note.m_sourceFile != "") {
         if (m_needsRehash) rehashMessageIDs();
         int messagesInFile[] = m_sourceFiles:[_file_case(note.m_sourceFile)];
         foreach (auto index in messagesInFile) {
            pmsg := &m_messages[index];
            if ( pmsg->m_origLineNumber   == note.m_origLineNumber &&
                 pmsg->m_origColNumber    == note.m_origColNumber &&
                 pmsg->m_creator          == note.m_creator &&
                 pmsg->m_date             == note.m_date &&
                 pmsg->m_description      == note.m_description &&
                 pmsg->m_length           == note.m_length &&
                 pmsg->m_markerPic        == note.m_markerPic &&
                 pmsg->m_markerType       == note.m_markerType &&
                 file_eq(pmsg->m_sourceFile, note.m_sourceFile) ) {
               pmsg->m_repeatCount++;
               return index;
            }
         }
      }

      //Check to see if we need to make a line or stream marker for the new message.
      if ((note.m_lmarkerID == -1) &&
          (note.m_smarkerID == -1) &&
          (note.m_lineNumber != 0)) {
         if (note.m_colNumber == 0) {
            //Make a line marker
            note.m_lmarkerID = _LineMarkerAddB(note.m_sourceFile,
                                               note.m_lineNumber, 0, 0,
                                               note.m_markerPic,
                                               note.m_markerType,
                                               note.getDescription());
         } else {
            //Make a stream marker.
            _str buf_id;
            buf_id = buf_match(note.m_sourceFile, 1, 'IX');
            if (buf_id == "") {
               //The file isn't open, defer creation of the stream marker
               m_deferredMessages:[note.m_sourceFile] :+= i;
               note.m_deferred = true;
            } else {
               int orig_wid;
               int temp_wid;

               orig_wid = p_window_id;
               //_open_temp_view('', temp_wid, orig_wid, '+bi 'wid);
               _open_temp_view("", temp_wid, orig_wid, '+bi 'buf_id);
               p_RLine = note.m_lineNumber;
               if ( isinteger(note.m_colNumber) ) p_col = note.m_colNumber;
               offset := _QROffset();
               note.m_smarkerID = _StreamMarkerAddB(note.m_sourceFile,
                                                    offset, note.m_length,
                                                    true, note.m_markerPic,
                                                    note.m_markerType,
                                                    note.getDescription());
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

      m_allMessages[i] = i;
      m_activeMessages:[i] = i;
      m_creators:[m_messages[i].m_creator] :+= i;
      parse m_messages[i].m_date with auto date " " . ;
      m_dates:[date] :+= i;
      m_sourceFiles:[_file_case(m_messages[i].m_sourceFile)] :+= i;
      shortSourceFile := _file_case(_strip_filename(m_messages[i].m_sourceFile, "P"));
      m_shortSourceFiles:[shortSourceFile] :+= i;
      m_types:[lowcase(m_messages[i].m_type)] :+= i;
      //m_messageIndices:[_maybe_quote_filename(_mdi.p_child.p_buf_name)]:[_mdi.p_child.p_RLine] = i;

      return i;
   }

   /**
    * Maps an error line and optional column to the adjusted 
    * error line and column (tracked by stream markers).
    *  
    * @return Returns true if the message's location was updated.
    */
   public bool mapCodeLocation(_str sourceFile,
                               int &newLineNumber, int &newColumn,
                               int origLineNumber, int origColumn=0)
   {
      if (m_needsRehash) rehashMessageIDs();
      if (!m_sourceFiles._indexin(_file_case(sourceFile))) {
         return false;
      }
      int messagesInFile[] = m_sourceFiles:[_file_case(sourceFile)];

      found_it := false;
      index := 0;
      foreach (index in messagesInFile) {
         if (index < 0 || index >= m_messages._length()) continue;
         msg := m_messages[index];
         if (msg == null) continue;
         // verify that file/line/column match
         if ((msg.m_origLineNumber && msg.m_origLineNumber != origLineNumber) ||
             (origColumn && msg.m_origColNumber && msg.m_origColNumber != origColumn) ||
             (!file_eq(msg.m_sourceFile, sourceFile))) {
            continue;
         }
         // Prefer stream markers to line markers.
         if (msg.m_smarkerID >= 0) {
            found_it = true;
            break;
         } else if (msg.m_lmarkerID >= 0) {
            found_it = true;
            break;
         }
      }

      // try again, ignoring column number
      if (!found_it && origColumn) {
         index = 0;
         foreach (index in messagesInFile) {
            if (index < 0 || index >= m_messages._length()) continue;
            msg := m_messages[index];
            if (msg == null) continue;
            // verify that file/line/column match
            if ((msg.m_origLineNumber && msg.m_origLineNumber != origLineNumber) ||
                !file_eq(msg.m_sourceFile, sourceFile)) {
               continue;
            }
            // Prefer stream markers to line markers.
            if (msg.m_smarkerID >= 0) {
               found_it = true;
               break;
            } else if (msg.m_lmarkerID >= 0) {
               found_it = true;
               break;
            }
         }
      }

      // Prefer stream markers to line markers.
      if (found_it && m_messages[index].m_smarkerID > -1) {
         VSSTREAMMARKERINFO sInfo;
         if (_StreamMarkerGet(m_messages[index].m_smarkerID, sInfo)) {
            return false;
         }
         status := _open_temp_view(sourceFile, auto temp_wid,  auto orig_wid);
         if (status < 0) {
            return false;
         }
         temp_wid._GoToROffset(sInfo.StartOffset);
         newLineNumber = temp_wid.p_RLine;
         newColumn     = temp_wid.p_col;
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
         return true;

      }

      if (found_it && m_messages[index].m_lmarkerID > -1) {
         VSLINEMARKERINFO lInfo;
         if (_LineMarkerGet(m_messages[index].m_lmarkerID, lInfo)) {
            return false;
         }
         newLineNumber = lInfo.LineNum;
         newColumn     = origColumn? origColumn : 1;
         return true;
      }

      // did not find the message
      return false;
   }

   /**
    * Maps an error line and optional column to the adjusted 
    * error line and column (tracked by stream markers).
    *  
    * @return Returns true if the message's location was updated.
    */
   public bool mapCodeLocationForMessage(int index, int &newLineNumber, int &newColumn)
   {
      se.messages.Message *pmsg = null;
      getMessage(pmsg, index);
      if (pmsg == null) {
         return false;
      }

      // Prefer stream markers to line markers.
      if (pmsg->m_smarkerID > -1) {
         VSSTREAMMARKERINFO sInfo;
         if (_StreamMarkerGet(pmsg->m_smarkerID, sInfo)) {
            return false;
         }
         status := _open_temp_view(pmsg->m_sourceFile, auto temp_wid,  auto orig_wid);
         if (status < 0) {
            return false;
         }
         temp_wid._GoToROffset(sInfo.StartOffset);
         newLineNumber = temp_wid.p_RLine;
         newColumn     = temp_wid.p_col;
         _delete_temp_view(temp_wid);
         activate_window(orig_wid);
         return true;

      }

      if (pmsg->m_lmarkerID > -1) {
         VSLINEMARKERINFO lInfo;
         if (_LineMarkerGet(pmsg->m_lmarkerID, lInfo)) {
            return false;
         }
         newLineNumber = lInfo.LineNum;
         newColumn     = 1;
         return true;
      }

      // no line or stream markers for this message.
      return false;
   }

};

namespace default;

using se.messages.Message;

se.messages.MessageCollection* get_messageCollection()
{
   // Just in case this is called after the app window has been destroyed
   if (_iswindow_valid(_app)) {
      se.messages.MessageCollection* mCollection = _GetDialogInfoHtPtr("messageCollection", _app);
      if (mCollection) {
         return mCollection;
      }

      se.messages.MessageCollection msgCollection;
      _SetDialogInfoHt("messageCollection", msgCollection, _app);
      mCollection = _GetDialogInfoHtPtr("messageCollection", _app);
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
      mCollection->removeMessages(null, null, Message.MSGCLEAR_BUFFER);
   }
}
void _prjclose_Messages()
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->removeMessages(null, null, Message.MSGCLEAR_PROJECT);
   }
}
void _wkspace_close_Messages()
{
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection != null) {
      mCollection->removeMessages(null, null, Message.MSGCLEAR_WKSPACE);
   }
}


/**
 * Save the messages in the current file, optionally restricting 
 * to a range of lines, and saving relocation information.
 * <p> 
 * This function is used to save message information before we do 
 * something that heavily modifies a buffer, such as refactoring, 
 * beautification, or auto-reload.  It uses the relocatable marker 
 * information to attempt to restore the messages back to their 
 * original line, even if the actual line number has changed because 
 * lines were inserted or deleted. 
 * 
 * @param messageSaves     Saved messages           
 * @param startRLine       First line in region to save
 * @param endRLine         Last line in region to save
 * @param relocatable      Save relocation marker information? 
 *  
 * @see _RestoreMessagesInFile 
 * @categories Miscellaneous_Functions
 */
void _SaveMessagesInFile(MessageSaveInfo (&messageSaves)[],
                         int startRLine=0, int endRLine=0,
                         bool relocatable=true)
{
   if (!_haveBuild()) {
      return;
   }
   if (!_isEditorCtl()) {
      return;
   }
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection == null) {
      return;
   }

   // clear the list
   messageSaves._makeempty();

   // determine the start and end offsets
   startROffset := 0L;
   endROffset   := (long) p_buf_size;
   save_pos(auto p);
   if (startRLine) {
      p_RLine = startRLine;
      _begin_line();
      startROffset = _QROffset();
   }
   if (endRLine) {
      p_RLine = endRLine;
      _end_line();
      endROffset = _QROffset();
   }


   int ids[];
   se.messages.Message *msgs[];
   mCollection->getMessagesInFile(p_buf_name, msgs, ids);

   n := ids._length();
   for (i:=0; i<n; i++) {
      pmsg := msgs[i];
      MessageSaveInfo msi;
      msi.index = ids[i];
      msi.origLineNumber = msgs[i]->m_origLineNumber;
      msi.origColNumber  = msgs[i]->m_origColNumber;
      msi.origLength     = msgs[i]->m_length;
      mCollection->mapCodeLocationForMessage(ids[i], msi.origLineNumber, msi.origColNumber);
      if (startRLine > 0 && msi.origLineNumber-1 < startRLine) continue;
      if (endRLine   > 0 && msi.origLineNumber+1 > endRLine) continue;
      msi.relocationInfo = null;
      if (relocatable) {
         p_RLine = msi.origLineNumber;
         p_col   = msi.origColNumber;
         _BuildRelocatableMarker(msi.relocationInfo);
      }
      messageSaves :+= msi;
   }

   // get back to where you once belonged
   restore_pos(p);
}

/**
 * Restore saved messages from the current file and relocate them
 * if the message information includes relocation information. 
 * 
 * @param messageSaves     Saved messages           
 * @param adjustLinesBy    Number of lines to adjust start line by
 *  
 * @see _SaveMessagesInFile 
 * @categories Miscellaneous_Functions
 */
void _RestoreMessagesInFile(MessageSaveInfo (&messageSaves)[], int adjustLinesBy=0)
{
   if (!_haveContextTagging()) {
      return;
   }
   if (!_isEditorCtl()) {
      return;
   }
   se.messages.MessageCollection* mCollection = get_messageCollection();
   if (mCollection == null) {
      return;
   }

   resetTokens := true;
   save_pos(auto p);
   foreach (auto msi in messageSaves) {

      // adjust the start line if we were asked to
      if (adjustLinesBy && msi.origLineNumber + adjustLinesBy > 0) {
         msi.origLineNumber += adjustLinesBy;
         if (msi.relocationInfo != null) {
            msi.relocationInfo.origLineNumber += adjustLinesBy;
         }
      }

      // relocate the marker, presuming the file has changed
      origRLine := msi.origLineNumber;
      if (msi.relocationInfo != null) {
         origRLine = _RelocateMarker(msi.relocationInfo, resetTokens);
         resetTokens = false;
         if (origRLine < 0) {
            origRLine = msi.relocationInfo.origLineNumber;
         }
      }

      // Move the stream marker where we need it.
      p_RLine = origRLine;
      _begin_line();
      if (msi.origColNumber > 0) {
         p_col = msi.origColNumber;
      }

      // update the stream marker and/or line marker
      se.messages.Message *pmsg = null;
      mCollection->getMessage(pmsg, msi.index);


      // Prefer stream markers to line markers.
      if (pmsg->m_smarkerID >= 0) {
         _StreamMarkerSetStartOffset(msi.index, _QROffset());
         _StreamMarkerSetLength(msi.index, msi.origLength);
      }

      if (pmsg->m_lmarkerID >= 0) {
         //Move the line marker to the cursor's line.
         _LineMarkerGet(pmsg->m_lmarkerID, auto lInfo);
         _LineMarkerRemove(pmsg->m_lmarkerID);
         k := _LineMarkerAdd(p_window_id, origRLine, true, lInfo.NofLines, lInfo.BMIndex, lInfo.type, lInfo.msg);
         pmsg->m_lmarkerID = k;
      }
   }

   restore_pos(p);
}

void _buffer_renamed_messagecoll(int buf_id, _str buf_name, _str new_name, 
                                 int flags)
{
   coll := get_messageCollection();

   if (coll) {
      coll->removeMessagesForBuffer(buf_name);
   }
}

