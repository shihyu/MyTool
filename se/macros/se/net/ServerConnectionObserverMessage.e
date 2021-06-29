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
#require "se/net/ServerConnectionObserver.e"
#endregion

namespace se.net;

/**
 * Convenience class.
 *
 * Generic observer class that observes an instance of 
 * ServerConnection and updates the user of the status of the 
 * pending connection via message line. Provides convenience 
 * methods: printMessage and printCriticalMessage. You must 
 * derive from this class and override onStatus* methods. 
 */
class ServerConnectionObserverMessage : ServerConnectionObserver {

   private bool m_quiet;

   /**
    * Constructor.
    */
   ServerConnectionObserverMessage() {
      m_quiet = true;
   }

   /**
    * Destructor.
    */
   ~ServerConnectionObserverMessage() {
   }

   /**
    * Display message on message line only if there is currently no
    * message being displayed. 
    * 
    * @param msg  Message to display.
    */
   protected void printMessage(_str msg) {
      if( !m_quiet ) {
         if( get_message() == "" ) {
            sticky_message(msg);
         }
      }
   }

   /**
    * Display message on message line. 
    * 
    * @param msg  Message to display.
    */
   protected void printCriticalMessage(_str msg) {
      if( !m_quiet ) {
         sticky_message(msg);
      }
   }

   public int start() {
      m_quiet = false;
      return 0;
   }

   public void stop() {
      m_quiet = true;
      clear_message();
      return;
   }

   public bool isStarted() {
      return !m_quiet;
   }

};
