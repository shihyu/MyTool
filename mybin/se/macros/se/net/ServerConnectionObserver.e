////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#require "se/net/IServerConnectionObserver.e"
#require "se/net/IServerConnection.e"
#require "se/net/IOnCancelHandler.e"
#endregion

namespace se.net;

/**
 * Observer class that observes an instance of ServerConnection 
 * and updates the user of the status of the pending connection 
 * via status-specific handler methods that are designed to be 
 * overridden. 
 */
class ServerConnectionObserver : IServerConnectionObserver {

   // TODO: This might need to be an array ala se.util.Subject if
   // we want more than one Cancel observer. For now we don't.
   private IOnCancelHandler* m_onCancelHandler;

   /**
    * Constructor.
    */
   ServerConnectionObserver() {
      m_onCancelHandler = null;
   }

   /**
    * Destructor.
    */
   ~ServerConnectionObserver() {
   }

   /**
    * Set the Cancel eventt handler. 
    * 
    * @param observer 
    */
   public void setOnCancelHandler(IOnCancelHandler* handler) {
      m_onCancelHandler = handler;
   }

   /**
    * Notify the onCancel handler of a Cancel event. 
    */
   public void notifyOnCancel() {
      if( m_onCancelHandler ) {
         m_onCancelHandler->onCancel();
      }
   }

   /**
    * Override me.
    *
    * <p>
    *
    * Start up this observer. What actually happens is
    * observer-defined, so this method must be overridden. 
    *
    * @return 0 on success, <0 on error.
    */
   public int start() {
      _assert(false,"ServerConnectionObserver.start must be overridden");
      return 0;
   }

   /**
    * Override me.
    *
    * <p>
    *
    * Shut down this observer. What actually happens is
    * observer-defined, so this method must be overridden. 
    */
   public void stop() {
      _assert(false,"ServerConnectionObserver.stop must be overridden");
   }

   /**
    * Override me.
    *
    * <p>
    *
    * Return true if this observer is in a started state (i.e. 
    * start has been called). 
    * 
    * @return boolean 
    */
   public boolean isStarted() {
      _assert(false,"ServerConnectionObserver.isStarted must be overridden");
      return false;
   }

   /**
    * Override me.
    *
    * <p>
    *
    * Default SCS_LISTEN handler. 
    *
    * @param server  ServerConnection instance.
    */
   private void onStatusListen(IServerConnection* server) {
      _assert(false,"ServerConnectionObserver.onStatusListen must be overridden");
   }

   /**
    * Override me.
    *
    * <p>
    *
    * Default SCS_PENDING handler. 
    *
    * @param server  ServerConnection instance.
    */
   private void onStatusPending(IServerConnection* server) {
      _assert(false,"ServerConnectionObserver.onStatusPending must be overridden");
   }

   /**
    * Override me.
    *
    * <p>
    *
    * SCS_ERROR handler. 
    *
    * @param server  ServerConnection instance.
    */
   private void onStatusError(IServerConnection* server) {
      _assert(false,"ServerConnectionObserver.onStatusError must be overridden");
   }

   public void update(se.util.Subject* subject) {

      if( !isStarted() ) {
         // This observer is not taking updates right now
         return;
      }

      // Hocus pocus
      IServerConnection* server = (typeless*)subject;

      SERVER_CONNECTION_STATUS status = server->getStatus();
      switch( status ) {
      case SCS_LISTEN:
         onStatusListen(server);
         break;
      case SCS_PENDING:
         onStatusPending(server);
         break;
      case SCS_ERROR:
         onStatusError(server);
         break;
      }
   }

   public void removeSubject(se.util.Subject* subject) {
   }

};
