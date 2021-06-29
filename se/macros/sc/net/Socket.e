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
#include "vsockapi.sh"
#include "rc.sh"
#require "sc/net/ISocketCommon.e"
#require "sc/net/IServerSocket.e"
#require "sc/net/IClientSocket.e"
#endregion

namespace sc.net;

/**
 * BETA
 *
 * This class is used to manage a native TCP socket.
 */
class Socket : IServerSocket, IClientSocket {

   // Prototypes
   public bool alive();
   bool getListeningStatus(int& pending_conn);

   // Native socket handle
   private int m_socket;

   // Connection and receive timeout (in milliseconds)
   private int m_timeout;

   /**
    * Default constructor.
    *
    * @param timeout  Maximum number of milliseconds to wait for a 
    *                 connection or receive operation. Defaults to
    *                 30000 (30 seconds).
    */
   Socket(int timeout=30000) {

      m_socket = INVALID_SOCKET;
      // Sanity please
      if( timeout <= 0 ) {
         timeout = 30000;
      }
      m_timeout = timeout;

      if( !vssIsInit() ) {
         vssInit();
      }
   }

   /**
    * Destructor. 
    */
   ~Socket() {
      //close();
   }

   /**
    * Attach a native socket to this instance. If this instance is 
    * already managing a native socket, then error is returned. 
    *
    * <p>
    * IMPORTANT: It is assumed that the native socket is of type 
    * SOCK_STREAM and protocol IPPROTO_TCP. Anything else will 
    * result in undefined behavior. 
    * 
    * @param s  Native socket handle.
    * 
    * @return 0 on success, <0 on error.
    */
   public int attachNativeSocket(int s) {

      if( s <= INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      } else if( m_socket != INVALID_SOCKET ) {
         return SOCK_IN_USE_RC;
      }
      m_socket = s;
      return 0;
   }

   /**
    * Detach native socket managed by this instance.
    *
    * @return Native socket handle. INVALID_SOCKET is returned if
    *         this instance was not managing a native socket.
    */
   public int detachNativeSocket() {

      int s = m_socket;
      m_socket = INVALID_SOCKET;
      return s;
   }

   /**
    * Return native socket being managed by this instance.
    * 
    * @return Native socket handle.
    */
   public int getNativeSocket() {
      return m_socket;
   }

   /**
    * Return timeout (in milliseconds) for connections and 
    * receiving data. 
    * 
    * @return Timeout in milliseconds.
    */
   public int getTimeout() {
      return m_timeout;
   }

   /**
    * Set timeout (in milliseconds) for connections and receiving 
    * data. 
    * 
    * @param timeout  Timeout in milliseconds.
    */
   public void setTimeout(int timeout) {

      // Sanity please
      if( timeout > 0 ) {
         m_timeout = timeout;
      }
   }

   /**
    * Connect to the given host at the given port, and use the
    * specified timeout value.
    *
    * @param host     The name of the host to connect to ("" 
    *                 implies local host).
    * @param port     The port to connect to. 
    * @param timeout  Number of milliseconds to wait for a reply 
    *                 packet. Set to 0 to use default timeout for
    *                 this socket. Defaults to 0.
    *
    * @return 0 on success, <0 on error.
    */
   public int connect(_str host, _str port, int timeout=0) {

      if( m_socket != INVALID_SOCKET ) {
         // Already in use
         return SOCK_IN_USE_RC;
      }

      if( timeout <=0 ) {
         timeout = m_timeout;
      }
      int status = vssSocketOpen(host,port,m_socket,0,timeout);
      if( status != 0 ) {
         // Error
         return status;
      }
      // Success
      return 0;
   }

   /** 
    * Test if this client socket is connected. 
    *
    * @return true if socket is connected. 
    */
   public bool isConnected() {
      return ( this.alive() && !this.isListening() );
   }

   /**
    * Start this server socket listening on a specific address and 
    * port. When specifying 0 for the port, use getLocalPort to 
    * retrieve the actual bound port. Use accept to accept a 
    * connection. 
    *
    * @param host  Host to listen on.
    * @param port  Port to listen on. Set to 0 to use any 
    *              available port. Defaults to 0.
    *
    * @return 0 on success, <0 on error.
    */
   public int listen(_str host, _str port="0") {

      if( m_socket != INVALID_SOCKET ) {
         // Already bound
         return SOCK_IN_USE_RC;
      }

      int status = vssSocketOpen(host,port,m_socket,1,0);
      if( status != 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /** 
    * Test if server socket is listening.
    *
    * @param pending_conn  (out) Set to number of pending 
    *                      connections >=0. Undefined if socket is
    *                      not listening.
    *
    * @return true if socket is listening.
    */
   bool getListeningStatus(int& pending_conn) {

      int status = vssIsSocketListening(m_socket,pending_conn);
      return ( status != 0 );
   }

   /** 
    * Test if server socket is listening.
    *
    * @return true if socket is listening.
    */
   bool isListening() {

      int not_used;
      return getListeningStatus(not_used);
   }

   /** 
    * Return number of pending connections. 
    *
    * @return Number of pending connections >=0.
    */
   int pending() {

      int nPending;
      if( !getListeningStatus(nPending) ) {
         return 0;
      }
      return nPending;
   }

   /** 
    * Accept a connection. Note that socket must be in a listening 
    * state. Listening socket is *not* closed after connection is 
    * accepted. Use pending to check for pending connections. Use 
    * the accept method if you want a simple native socket handle 
    * accepted and returned. 
    *
    * @param accepted_socket (out) Set to accepted connection.
    *
    * @return 0 on success, <0 on error.
    *
    * @see accept
    */
   public int acceptClient(IClientSocket& accepted_socket) {

      int s;
      int status = this.accept(s);
      if( status != 0 ) {
         // Error
         return status;
      }

      // Success
      accepted_socket.attachNativeSocket(s);
      return 0;
   }

   /** 
    * Accept a connection. Note that server socket must be 
    * listening. Server socket is *not* closed after connection is 
    * accepted. 
    *
    * @param accepted_socket (out) Set to accepted connection 
    *                        socket handle.
    *
    * @return 0 on success, <0 on error.
    */
   public int accept(int& accepted_socket) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      int status_or_socket = vssSocketAcceptConn2(m_socket);
      if( status_or_socket < 0 ) {
         // Error
         return status_or_socket;
      }

      // Success
      accepted_socket = status_or_socket;
      return 0;
   }

   /**
    * Send the given data over the socket.
    *
    * @param data  Data to send. 
    * @param len   Number of bytes to send. Set to -1 to send all 
    *              bytes. Defaults to -1.
    *
    * @return 0 on success, <0 on error.
    *
    * @see sendBlob
    */
   public int send(_str data, int len=-1) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      status := 0;
      if( len < 0 ) {
         status = vssSocketSendZ(m_socket,data);
      } else {
         status = vssSocketSend(m_socket,data,len);
      }
      if( status < 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /**
    * Send data from internal "blob" over the socket. Writing 
    * starts from the current blob offset. The current blob offset 
    * is not changed. 
    * 
    * <p>
    *
    * A blob is an internal binary buffer for reading and writing
    * arbitrary data. It is especially useful for data that may 
    * contain ascii null (0) bytes which Slick-C does not handle. 
    * Use the Slick-C _Blob* api to get, set, and manipulate 
    * specific types of data. 
    *
    * @param hblob  Handle to blob returned by _BlobAlloc.
    * @param len    Number of bytes to send from blob. Set to -1 to 
    *               send all bytes. Defaults to -1.
    *
    * @return 0 on success, <0 on error.
    *
    * @see send
    */
   public int sendBlob(int hblob, int len=-1) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      int status = vssSocketSendBlob(m_socket,hblob,len);
      if( status < 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /**
    * Receive data over the socket.
    *
    * @param data     (out) String to receive data. 
    * @param peek     Set to true to peek the data without reading 
    *                 it off the socket. Defaults to false.
    * @param timeout  Milliseconds to wait for data. Set to 0 to 
    *                 use default timeout for this socket. Defaults
    *                 to 0.
    *
    * @return 0 on success, <0 on error.
    */
   public int receive(_str& data, bool peek=false, int timeout=0) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      if( timeout <= 0 ) {
         timeout = m_timeout;
      }
      int status = vssSocketRecvToZStr(m_socket,data,timeout,(int)peek);
      if( status < 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /**
    * If there is data pending on the socket, then receive the 
    * data. Use this method when you do not want to wait on the 
    * socket. 
    *
    * @param data  (out) String to receive data. 
    *
    * @return 0 on success, <0 on error, SOCK_NO_MORE_DATA_RC if no 
    *         data is pending on socket.
    */
   public int receive_if_pending(_str& data) {

      if( poll() ) {
         return this.receive(data,false,m_timeout);
      }
      return SOCK_NO_MORE_DATA_RC;
   }

   /**
    * Receive data over the socket and store in a file.
    *
    * @param filename   Name of file in which to store received 
    *                   data.
    * @param xlatFlags  Newline translation flags. This determines 
    *                   how newlines will be translated before
    *                   being written to file. A value of 0
    *                   indicates no translation. Defaults to 0.
    *                   The following flags are available:
    *                    
    *                   <dt>XLATFLAG_DOS</dt><dd>Translate all
    *                   newlines to \r\n</dd>
    *                   <dt>XLATFLAG_UNIX</dt><dd>Translate all
    *                   newlines to \n</dd>
    *                   <dt>XLATFLAG_LOCAL</dt><dd>Translate all
    *                   newlines to the local newline (i.e. \r\n
    *                   for DOS or \n for UNIX)<dd>
    * @param timeout    Milliseconds to wait for data. Set to 0 to 
    *                   use default timeout for this socket.
    *                   Defaults to 0.
    *
    * @return 0 on success, <0 on error.
    *
    * @see receive
    * @see receieveToBlob
    */
   public int receiveToFile(_str filename, XLAT_FLAGS xlatFlags=XLATFLAG_NONE, int timeout=0) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      if( timeout <= 0 ) {
         timeout = m_timeout;
      }
      int status = vssSocketRecvToFile(m_socket,filename,timeout,xlatFlags);
      if( status < 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /**
    * Receive data over the socket and store in a blob. This method
    * is useful when the data you receive may contain ascii null
    * (0) bytes which prevent you from using receive. Use the
    * Slick-C _Blob* api to manipulate data in the blob after
    * calling this function. 
    *
    * @param hblob    Handle to blob.
    * @param peek     Set to true to peek the data without reading 
    *                 it off the socket. Defaults to false.
    * @param timeout  Milliseconds to wait for data. Set to 0 to 
    *                 use default timeout for this socket. Defaults
    *                 to 0.
    *
    * @return 0 on success, <0 on error.
    *
    * @see receive
    * @see receieveToFile
    */
   public int receiveToBlob(int hblob, bool peek=false, int timeout=0) {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      if( timeout <= 0 ) {
         timeout = m_timeout;
      }
      int status = vssSocketRecvToBlob(m_socket,hblob,timeout,(int)peek);
      if( status < 0 ) {
         // Error
         return status;
      }

      // Success
      return 0;
   }

   /**
    * Poll for data on the socket. Data is left on socket. Returns 
    * immediately. 
    *
    * @return True if there is data waiting on the socket.
    */
   public bool poll() {

      int status = vssSocketPoll(m_socket);
      return ( status != 0 );
   }

   /**
    * Test socket for alive'ness. A socket is alive if it is 
    * listening or in a connected state. 
    *
    * @return true if the socket is still alive.
    */
   public bool alive() {

      int status = vssIsConnectionAlive(m_socket);
      return ( status != 0 );
   }

   /**
    * Test if native socket handle is valid. Note that this is not 
    * the same as testing for alive'ness. 
    * 
    * @return True if native socket handle is valid.
    */
   public bool valid() {
      return ( m_socket != INVALID_SOCKET );
   }

   /**
    * Close the connection.
    *
    * @return 0 on success, <0 on error.
    */
   public int close() {

      if( m_socket == INVALID_SOCKET ) {
         return SOCK_BAD_SOCKET_RC;
      }

      vssSocketClose(m_socket);
      m_socket = INVALID_SOCKET;
      return 0;
   }

   /**
    * Return the local endpoint IP address that this socket 
    * is bound to. 
    *
    * @return Local endpoint IP address as string, null if socket 
    *         is not bound.
    */
   public _str getLocalIpAddress() {

      host := "";
      port := 0;
      int status = vssGetLocalSocketInfo(m_socket,host,port);
      if( status != 0 ) {
         // Error
         return null;
      }

      // Success
      return host;
   }

   /**
    * Return the local endpoint port that this socket is bound to. 
    *
    * @return >0 port on success, 0 if this socket is not bound.
    */
   public int getLocalPort() {

      host := "";
      port := 0;
      int status = vssGetLocalSocketInfo(m_socket,host,port);
      if( status != 0 ) {
         // Error
         return 0;
      }

      // Success
      return port;
   }

   /**
    * Return the remote endpoint IP address that this socket is
    * connected to. 
    *
    * @return Remote endpoint IP address as string, null if socket 
    *         is not connected.
    */
   public _str getRemoteIpAddress() {

      host := "";
      port := 0;
      int status = vssGetRemoteSocketInfo(m_socket,host,port);
      if( status != 0 ) {
         // Error
         return null;
      }

      // Success
      return host;
   }

   /**
    * Return the remote endpoint port that this socket is connected 
    * to. 
    *
    * @return >0 port, 0 if this socket is not connected.
    */
   public int getRemotePort() {

      host := "";
      port := 0;
      int status = vssGetRemoteSocketInfo(m_socket,host,port);
      if( status != 0 ) {
         // Error
         return 0;
      }

      // Success
      return port;
   }

};
