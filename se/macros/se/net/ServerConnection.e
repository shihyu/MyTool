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
#include "debug.sh"
#require "se/net/IServerConnection.e"
#require "se/net/IServerConnectionObserver.e"
#require "se/net/IOnCancelHandler.e"
#require "sc/net/ServerSocket.e"
#require "se/util/Subject.e"
#require "sc/lang/Timer.e"
#endregion

namespace se.net;

using se.util.Subject;

/**
 * Helper class for ServerConnection. Updates watch() observer 
 * on a timer. 
 */
class ServerWatchTimer : sc.lang.Timer {

   private Subject* m_server;
   private IServerConnectionObserver* m_observer;

   // private: Use startWatch instead
   private int start() {
      return sc.lang.Timer.start();
   }

   // private: Use stopWatch instead
   private int kill() {
      return sc.lang.Timer.kill();
   }

   ServerWatchTimer() {
      Timer(1000,-1);
      m_server = null;
      m_observer = null;
   }

   public int startWatch(Subject* server,
                         IServerConnectionObserver* observer,
                         bool startSuspended=false) {

      // Kill any previous timer
      this.kill();

      m_server = server;
      m_observer = observer;
      if( startSuspended ) {
         return 0;
      }
      if( m_observer ) {
         m_server->attachObserver(m_observer);
         m_observer->start();
      }
      return this.start();
   }

   public void stopWatch() {
      if( m_observer ) {
         m_observer->stop();
         m_server->detachObserver(m_observer);
      }
      this.kill();
      m_server = null;
      m_observer = null;
   }

   /**
    * Suspend current watch.
    */
   public void suspendWatch() {
      this.kill();
      if( m_observer ) {
         m_observer->stop();
         m_server->detachObserver(m_observer);
      }
   }

   /**
    * Resume current watch.
    * 
    * @return 0 on success, <0 on error.
    */
   public int resumeWatch() {

      // Do not allow multiple timers to be started inadvertantly
      this.kill();

      if( m_observer ) {
         m_server->attachObserver(m_observer);
         m_observer->start();
      }
      return this.start();
   }

   public int run() {
      //say('ServerWatchTimer::run: _time(B)='_time('B'));
      if( !m_server ) {
         // Timer got killed after timer event fired for last time.
         // Probably not serious.
         return 1;
      }
      m_server->notifyObservers();
      return 0;
   }

};


/**
 * BETA
 *
 * Server connection class. Encapsulates a server socket and
 * provides convenient methods for accepting connections 
 * synchronously and asynchronously with user-provided 
 * observers. 
 */
class ServerConnection : IServerConnection, IOnCancelHandler, Subject {

   private void initialize();
   private void finalize();
   private void resetStats();

   public _str getHost(bool actual=false);
   public _str getPort(bool actual=false);

   // The server that listens for and accepts pending connections
   private sc.net.ServerSocket m_server;
   // Host to listen on passed in by wait or watch
   private _str m_host = "";
   // Port to listen on passed in by wait or watch
   private _str m_port = "";
   // One of SCS_* to indicate current status 
   // of pending connection test. 
   private SERVER_CONNECTION_STATUS m_status = SCS_NONE;
   // Start time
   private double m_start = 0;
   // Time elapsed in milliseconds
   private int m_elapsed = 0;
   // Timeout in milliseconds
   private int m_timeout = -1;
   // Error code (defined when m_status=SCS_ERROR)
   private int m_error = 0;
   // Currently wait()ing?
   private bool m_waiting = false;
   // Cancel wait()?
   private bool m_cancel_wait = false;
   // Timer used by passive watch()
   private ServerWatchTimer m_watch_timer;

   /**
    * Constructor.
    */
   ServerConnection() {
      initialize();
   }

   /**
    * Destructor.
    */
   ~ServerConnection() {
      finalize();
   }

   private void initialize() {

      m_host = "";
      m_port = "";
      m_status = SCS_NONE;
      m_start = 0;
      m_elapsed = 0;
      m_timeout = -1;
      m_error = 0;
      m_waiting = false;
      m_cancel_wait = false;
   }

   public int getNativeSocket() {
      return m_server.getNativeSocket();
   }

   private void finalize() {
      shutdown();
   }

   /**
    * Get the host used by last wait() or watch(). 
    *
    * @param actual  If set to true the socket is queried for the 
    *                actual local ip address that is bound. 
    * 
    * @return Host.
    */
   public _str getHost(bool actual=false) {
      if( actual && m_server.isListening() ) {
         return m_server.getLocalIpAddress();
      }
      return m_host;
   }

   /**
    * Get the port used by last wait() or watch(). 
    * 
    * @param actual  If set to true the socket is queried for the 
    *                actual local port that is bound.
    *
    * @return Port.
    */
   public _str getPort(bool actual=false) {
      if( actual && m_server.isListening() ) {
         return ( (_str)m_server.getLocalPort() );
      }
      return m_port;
   }

   /**
    * Return current timeout in milliseconds of pending connection 
    * test. 
    * 
    * @return Timeout in milliseconds.
    */
   public int getTimeout() {
      return m_timeout;
   }

   /**
    * Return current status of pending connection test.
    * 
    * @return One of SCS_*.
    */
   public SERVER_CONNECTION_STATUS getStatus() {
      updateStatus();
      return m_status;
   }

   public void resetStatus() {
      m_status = SCS_NONE;
      m_error = 0;
   }

   /**
    * Get elapsed time in milliseconds since the server started 
    * listening for a connection, or since the last error, or since 
    * the last stop. 
    * 
    * @return Elapsed time in milliseconds.
    */
   public int getElapsedTime() {
      updateStatus();
      return m_elapsed;
   }

   /**
    * Get the number of pending connections. 
    * 
    * @return Number of pending connections.
    */
   public int getPending() {
      return m_server.pending();
   }

   /**
    * Get the last error code. This is only defined when getStatus 
    * returns SCS_ERROR. 
    * 
    * @return Last error code.
    */
   public int getError() {
      updateStatus();
      return m_error;
   }

   /**
    * Update status of pending connections.
    */
   public void updateStatus() {

      // ERROR and STOP trump all since we have to give the caller
      // a chance to retrieve status and statistics.
      if( m_status == SCS_ERROR || m_status == SCS_STOP ) {
         //say('updateStatus: bypassing on error/stop: m_status='m_status'  m_error='m_error);
         return;
      }

      do {

         m_elapsed = (m_start > 0) ? (int)((double)_time('B') - m_start) : 0;

         // Pending connections ready?
         int nPending = m_server.pending();
         if( nPending > 0 ) {
            // Connection is ready
            m_status = SCS_PENDING;
            break;
         }
   
         // Timed out?
         //say('ServerConnection::updateStatus: m_timeout='m_timeout'  m_elapsed='m_elapsed'  m_start='m_start);
         if( m_timeout >= 0 && m_elapsed >= m_timeout ) {
            m_status = SCS_ERROR;
            m_error = SOCK_TIMED_OUT_RC;
            break;
         }
   
         // Listening for a connection
         m_status = SCS_LISTEN;

      } while( false );
   }

   /**
    * Reset statistics (status, error, elapsed). Note that this
    * does not close the server connection. 
    */
   private void resetStats() {
      m_status = SCS_NONE;
      m_start = 0;
      m_elapsed = 0;
      m_error = 0;
   }

   /**
    * Test is server is currently listening. Even if the server is 
    * listening it does not necessarily indicate that a watch or 
    * wait is in progress, only that the underlying server socket 
    * is in a listening state. 
    * 
    * @return True if server is listening.
    */
   public bool isListening() {
      return m_server.isListening();
   }

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
   public int wait(_str host, _str port, int timeout,
                   IServerConnectionObserver* observer=null) {

      // Start the server if not already started on this host:port
      if( !m_server.isListening() ||
          m_host != host || m_port != port ) {

         int status = m_server.listen(host,port);
         if( status != 0 && status != SOCK_IN_USE_RC ) {
            // Error
            m_status = SCS_ERROR;
            m_error = SOCK_BAD_SOCKET_RC;
            return status;
         }
      }

      // Attempt to short-circuit everything by checking for
      // a pending connection immediately.
      updateStatus();
      if( m_status == SCS_PENDING ) {
         return 0;
      }

      // Suspend the watch() timer while we wait() and save stats
      double suspend_start = m_start;
      int suspend_timeout = m_timeout;
      m_watch_timer.suspendWatch();

      // It's a whole new wait
      resetStats();
      m_host = host;
      m_port = port;
      m_start = (double)_time('B');
      m_timeout = timeout;
      m_waiting = true;
      m_cancel_wait = false;
      if( observer ) {
         attachObserver(observer);
         int status = observer->start();
      }

      while( m_status != SCS_ERROR && m_status != SCS_STOP ) {

         if( m_status == SCS_PENDING ) {
            break;
         }

         // Process events
         not_used := false;
         // 'T' is important since the .process buffer reads/writes
         // on a timer. Adding 'T' was necessary for the PHP and Python
         // debuggers that would stall outputting to stdout before
         // getting a chance to make the debugger connection.
         process_events(not_used,'T');
         if( m_cancel_wait ) {
            // Probably a user hitting Cancel
            break;
         }

         // Yield
         delay(1);

         //updateStatus();
         notifyObservers();
      }

      // We are done with the wait()ing
      m_waiting = false;
      if( observer ) {
         observer->stop();
         detachObserver(observer);
      }

      // Resume the watch() and restore stats
      m_start = suspend_start;
      m_timeout = suspend_timeout;
      m_watch_timer.resumeWatch();

      // Is there a pending connection?
      if( m_status != SCS_PENDING ) {
         status := 0;
         if( m_status == SCS_ERROR ) {
            // Error
            status = m_error;
         } else if( m_cancel_wait ) {
            // The observer might have called resetStatus(), but we
            // still want to return status indicating what actually
            // happened.
            status = COMMAND_CANCELLED_RC;
         } else {
            // SCS_STOP
            status = 0;
         }
         return status;
      }

      // Success
      return 0;
   }

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
   public int watch(_str host, _str port, int timeout=-1,
                    IServerConnectionObserver* observer=null) {

      // Start the server if not already started on this host:port
      if( !m_server.isListening() ||
          m_host != host || m_port != port ) {

         int status = m_server.listen(host,port);
         if( status != 0 && status != SOCK_IN_USE_RC ) {
            // Error
            m_status = SCS_ERROR;
            m_error = SOCK_BAD_SOCKET_RC;
            return status;
         }
      }

      // It's a whole new watch
      resetStats();
      m_host = host;
      m_port = port;
      m_start = (double)_time('B');
      m_timeout = timeout;
      if( observer ) {
         // Note: If we are in the middle of a wait(), then the watch() will
         // be started when the wait() is finished.
         m_watch_timer.startWatch(&this,observer,m_waiting);
      }

      // That's it. Since we are passively watching, some outside
      // agent/observer will need to be keeping an eye on the status
      // of pending connections.

      // Success
      return 0;
   }

   /**
    * IOnCancelHandler::onCancel event handler. Called externally 
    * when the user cancels (e.g. from active observer dialog). 
    */
   public void onCancel() {

      if( m_waiting ) {
         // Inject Cancel into the wait()
         m_cancel_wait = true;
      } else {
         // Cancel the watch()
         m_watch_timer.stopWatch();
      }
   }

   /**
    * Stop the current wait() and watch(). The server is not 
    * closed. Call wait() or watch() to resume observing the 
    * server. 
    */
   public void stop() {

      // Inject STOP into the wait()
      if( m_waiting ) {
         m_status = SCS_STOP;
         m_error = 0;
      }
      // Cancel the watch()
      m_watch_timer.stopWatch();
   }

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
   public int acceptClient(sc.net.IClientSocket& accepted_socket) {
      return m_server.acceptClient(accepted_socket);
   }

   /**
    * Accept a pending connection. Use getPending to check for 
    * pending connections. 
    * 
    * @return >=0 socket handle on success, <0 on error.
    */
   int accept() {

      int accepted_socket = INVALID_SOCKET;
      int status_or_socket = m_server.accept(accepted_socket);
      if( 0 == status_or_socket ) {
         status_or_socket = accepted_socket;
      }
      return status_or_socket;
   }

   /**
    * Shut down the server, terminating any wait()s or watch()s. 
    */
   public void shutdown() {
      this.stop();
      m_server.close();
   }

   /**
    * Override Subject::notifyObservers in order to wedge in a call
    * to updateStatus before observers are notified so they can get
    * most up-to-date status.
    */
   public void notifyObservers() {
      updateStatus();
      Subject.notifyObservers();
   }

};
