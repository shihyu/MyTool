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
#require "sc/net/ClientSocket.e"
#endregion


namespace se.net;

enum SERVER_CONNECTION_STATUS {
   SCS_NONE    = 0,  // No status (e.g. not listening yet)
   SCS_LISTEN  = 1,  // Listening for a connection, no connections pending
   SCS_PENDING = 2,  // Connection pending
   SCS_STOP    = 3,  // Server stopped
   SCS_ERROR   = 4   // There was an error, use getError to retrieve it
};


/**
 * BETA
 *
 * Server connection interface. 
 */
interface IServerConnection {

   /**
    * Update status of pending connections.
    */
   void updateStatus();

   /**
    * Get the host used by last wait() or watch(). 
    *
    * @param actual  If set to true the connection is queried for 
    *                the actual host.
    * 
    * @return Host.
    */
   _str getHost(bool actual=false);
   /**
    * Get the port used by last wait() or watch(). 
    * 
    * @param actual  If set to true the connection is queried for
    *                the actual port.
    *
    * @return Port.
    */
   _str getPort(bool actual=false);

   /**
    * Return current timeout in milliseconds of pending connection 
    * test. 
    * 
    * @return Timeout in milliseconds.
    */
   int getTimeout();

   /**
    * Return current status of pending connection test.
    * 
    * @return One of SCS_*.
    */
   SERVER_CONNECTION_STATUS getStatus();

   /**
    * Reset status. Use this to clear a non-fatal error condition.
    */
   void resetStatus();

   /**
    * Get elapsed time in milliseconds since the server started 
    * listening for a connection, or since the last error, or since 
    * the last stop. 
    * 
    * @return Elapsed time in milliseconds.
    */
   int getElapsedTime();

   /**
    * Get the number of pending connections. 
    * 
    * @return Number of pending connections.
    */
   int getPending();

   /**
    * Get the last error code. This is only defined when getStatus 
    * returns SCS_ERROR. 
    * 
    * @return Last error code.
    */
   int getError();

   /**
    * Test is server is currently listening. Even if the server is 
    * listening it does not necessarily indicate that a watch or 
    * wait is in progress, only that the underlying server socket 
    * is in a listening state. 
    * 
    * @return True if server is listening.
    */
   bool isListening();

   /**
    * Actively wait for a pending connection. If successful, the 
    * connection can be accepted by calling accept. 
    *
    * @param host      Host to wait on.
    * @param port      Port to wait on.
    * @param timeout   Milliseconds to wait for a connection. Set 
    *                  to -1 for infinite wait.
    * @param observer  Optional observer. Defaults to null.
    * 
    * @return 0 if waiting was successful, <0 on error. 
    */
   int wait(_str host, _str port, int timeout, IServerConnectionObserver* observer=null);

   /**
    * Passively watch for a connection. The caller is responsible 
    * for checking if a pending connection is available. This can 
    * be done by specifying an observer or otherwise periodically 
    * checking (e.g. on a timer). 
    *
    * @param host      Host to watch on.
    * @param port      Port to watch on.
    * @param timeout   Milliseconds to watch for a connection. Set 
    *                  to -1 for infinite watch. Defaults to -1.
    * @param observer  Optional observer. Defaults to null.
    * 
    * @return 0 on success, <0 on error. Note that a watch can 
    *         still fail later on.
    */
   int watch(_str host, _str port, int timeout=-1, IServerConnectionObserver* observer=null);

   /**
    * Stop the current wait() or watch(). The server is not closed.
    * Call wait() or watch() to resume observing the server. 
    */
   void stop();

   /**
    * Shut down the server, terminating any wait()s or watch()s. 
    */
   void shutdown();

   /**
    * Accept a pending connection. Use getPending to check for 
    * pending connections. Use the accept method if you want a 
    * simple native socket handle accepted and returned. 
    *
    * @param accepted_socket  (out) Accepted client socket 
    *                         connection.
    * 
    * @return 0 on success, <0 on error.
    *
    * @see accept
    */
   int acceptClient(sc.net.IClientSocket& accepted_socket);

   /**
    * Accept a pending connection. Use getPending to check for 
    * pending connections. 
    * 
    * @return >=0 socket handle on success, <0 on error.
    */
   int accept();

   /**
    * Returns the socket used to accept connections.
    * @return int 
    */
   int getNativeSocket();
};
