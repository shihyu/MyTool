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
#include "markers.sh"
#include "slick.sh"
#require "se/lineinfo/LineInfo.e"
#import "files.e"
#endregion

namespace se.messages;



class MenuItem {
   _str m_callback;
   _str m_menuText;

   MenuItem ()
   {
      m_callback = '';
      m_menuText = '';
   }
   ~MenuItem () {}
};



class Message : se.lineinfo.LineInfo {
   enum_flags MSGCLEAR_FLAGS {
      MSGCLEAR_NEVER =    0x00000000,   // Never auto-clear (future).
      MSGCLEAR_BUFFER =   0x00000001,   // Auto-clear on buffer switch.
      MSGCLEAR_PROJECT=   0x00000002,   // Auto-clear on project close.
      MSGCLEAR_WKSPACE=   0x00000004,   // Auto-clear on workspace close.
      MSGCLEAR_EDITOR=    0x00000008,   // Auto-clear on editor close.
      MSGCLEAR_ALWAYS=    0x0000000F,   // Always auto-clear.
   };
   public void makeCaption ();
   public void removeMarker ();
   public void delete ();

   _str m_creator;
   _str m_date;
   _str m_description;
   _str m_deleteCallback;
   int m_origLineNumber;
   int m_lineNumber;
   int m_origColNumber;
   int m_colNumber;
   int m_length;
   int m_markerPic;
   int m_markerType; // returned by _MarkerTypeAlloc()
   MSGCLEAR_FLAGS m_autoClear; // MSGCLEAR flag
   bool m_markerTypeAllocated;
   typeless m_attributes:[]; // Attribute/value pairs that are available for any
                             // use.
   MenuItem m_menuItems[];

   // number of times this exact messages is repeated
   int m_repeatCount;

   Message ()
   {
      m_creator = "";
      m_date = "";
      m_description = "";
      m_deleteCallback = "";
      m_origLineNumber = 0;
      m_lineNumber = 0;
      m_origColNumber = 0;
      m_colNumber = 0;
      m_length = 1;
      m_markerPic = 0;
      m_markerType = -1;
      m_autoClear = MSGCLEAR_WKSPACE;
      m_markerTypeAllocated = false;
      m_repeatCount = 1;
   }
   ~Message ()
   {
   }

   
   public void makeCaption ()
   {
      m_preview :+= '<code>Creator:</code><br>'m_creator'<br><br>';
      m_preview :+= '<code>Type:</code><br>'m_type'<br><br>';
      m_preview :+= '<code>Date:</code><br>'m_date'<br><br>';
      if (m_repeatCount > 1) {
         m_preview :+= '<code>Repeated 'm_repeatCount' times<br><br>';
      }
      m_preview :+= '<code>Description:</code><br>'m_description'<br>';
   }


   public _str getDescription()
   {
      if (m_repeatCount > 1) {
        return "(repeated "m_repeatCount" times) " :+ m_description;
      }
      return m_description;
   }



   public void removeMarker ()
   {
      if (m_lmarkerID > -1) {
         _LineMarkerRemove(m_lmarkerID);
      }
      if (m_smarkerID > -1) {
         _StreamMarkerRemove(m_smarkerID);
      }
   }


   public void delete ()
   {
      callbackIDX := find_index(m_deleteCallback, COMMAND_TYPE|PROC_TYPE);
      if (callbackIDX && index_callable(callbackIDX)) {
         call_index(&this, callbackIDX);
      }
   }
};
