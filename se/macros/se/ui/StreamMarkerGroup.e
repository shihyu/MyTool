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
#endregion

namespace se.ui;

class StreamMarkerGroup {
   protected typeless m_markerList:[]:[];
   protected bool m_autoRemove = false;

   StreamMarkerGroup(bool autoRemove = false)
   {
      m_autoRemove = autoRemove;
   }

   void makeEmpty()
   {
      m_markerList._makeempty();
   }

   bool isEmpty(int bufID)
   {
      if (m_markerList._indexin(bufID)) {
         return(m_markerList:[bufID]._isempty() || m_markerList:[bufID]._length() == 0);
      }
      return(true);
   }

   typeless getMarker(int bufID, int markerID)
   {
      if (m_markerList._indexin(bufID) && m_markerList:[bufID]._indexin(markerID)) {
         return m_markerList:[bufID]:[markerID];
      }
      return(null);
   }

   void addMarker(int bufID, int markerID, typeless &markerData)
   {
      if (!m_markerList._indexin(bufID)) {
         m_markerList:[bufID]._makeempty();
      }
      m_markerList:[bufID]:[markerID] = markerData;
   }

   void removeMarker(int bufID, int markerID)
   {
      if (m_markerList._indexin(bufID) && m_markerList:[bufID]._indexin(markerID)) {
         if (m_autoRemove) {
            _StreamMarkerRemove(markerID);
         }
         m_markerList:[bufID]:[markerID] = null;
         m_markerList:[bufID]._deleteel(markerID);
      }
   }

   void removeBuffer(int bufID)
   {
      if (m_markerList._indexin(bufID) && m_autoRemove) {
         int markerID;
         foreach (markerID => auto markType in m_markerList:[bufID]) {
            _StreamMarkerRemove(markerID);
         }
         m_markerList._deleteel(bufID);
      }
   }
};

