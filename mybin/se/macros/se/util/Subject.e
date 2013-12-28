////////////////////////////////////////////////////////////////////////////////////
// $Revision: 41607 $
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
#require "IObserver.e"
#endregion

namespace se.util;

class Subject {

   private IObserver* m_observers[];
   private boolean m_batching;

   Subject() {
      m_batching = false;
   }
   ~Subject() {
      foreach( auto o in m_observers ) {
         if( o != null && *o instanceof se.util.IObserver ) {
            o->removeSubject(&this);
         }
      }
   }

   public void attachObserver(IObserver* observer) {
      // Make sure this observer is not already in the list
      foreach( auto o in m_observers ) {
         if( o == observer ) {
            return;
         }
      }
      m_observers[m_observers._length()] = observer;
   }
   public void detachObserver(IObserver* observer) {
      for( i:=0; i < m_observers._length(); ++i ) {
         if( m_observers[i] == observer ) {
            m_observers._deleteel(i);
            return;
         }
      }
   }

   public void startBatch() {
      m_batching = true;
   }

   public void endBatch() {
      m_batching = false;
   }

   public void notifyObservers() {
      if( m_batching ) {
         return;
      }
      foreach( auto o in m_observers ) {
         if( o != null && *o instanceof se.util.IObserver ) {
            o->update(&this);
         }
      }
   }
};
