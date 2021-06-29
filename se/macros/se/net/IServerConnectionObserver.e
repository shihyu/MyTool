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
#require "se/util/IObserver.e"
#endregion


namespace se.net;

interface IServerConnection;


/**
 * Observer interface for observing an instance of 
 * IServerConnection. 
 */
interface IServerConnectionObserver : se.util.IObserver {

   /**
    * Start up the observer. 
    *
    * @return 0 on success, <0 on error.
    */
   int start();

   /**
    * Shut down the observer. 
    */
   void stop();

   /**
    * Return true if the observer is in a started state (i.e. start
    * has been called). 
    * 
    * @return bool
    */
   bool isStarted();

   /**
    * Default SCS_LISTEN handler. 
    *
    * @param server  IServerConnection instance.
    */
   void onStatusListen(IServerConnection* server);

   /**
    * Default SCS_PENDING handler. 
    *
    * @param server  IServerConnection instance.
    */
   void onStatusPending(IServerConnection* server);

   /**
    * SCS_ERROR handler. 
    *
    * @param server  IServerConnection instance.
    */
   void onStatusError(IServerConnection* server);

};
