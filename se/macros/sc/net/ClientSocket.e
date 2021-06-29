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
#require "sc/net/IClientSocket.e"
#require "sc/net/Socket.e"
#endregion

namespace sc.net;


/**
 * BETA
 *
 * This class is used to make client connections to 
 * servers/listeners over TCP sockets. It is a wrapper around 
 * the Socket class and provides a simpler subset of 
 * connection-oriented functionality. 
 */
class ClientSocket : IClientSocket {

   private Socket m_socket;

   /**
    * Default constructor. Creates an unconnected client socket. 
    *
    * @param timeout  Maximum number of milliseconds to wait for a 
    *                 connection or receive operation. Defaults to
    *                 30000 (30 seconds).
    */
   ClientSocket(int timeout=30000) {

      m_socket.setTimeout(timeout);
   }

   /**
    * Destructor. Closes this client socket connection. 
    */
   ~ClientSocket() {
      m_socket.close();
   }

   /**
    * Attach a native socket handle to this instance. If this 
    * instance is already managing a native socket, then error is 
    * returned. 
    * 
    * @param s  Native socket handle.
    * 
    * @return 0 on success, <0 on error.
    */
   public int attachNativeSocket(int s) {
      return m_socket.attachNativeSocket(s);
   }

   /**
    * Detach native socket handle managed by this instance.
    *
    * @return Native socket handle. INVALID_SOCKET is returned if
    *         this instance was not managing a native socket.
    */
   public int detachNativeSocket() {
      return m_socket.detachNativeSocket();
   }

   /**
    * Return native socket handle managed by this instance.
    * 
    * @return Native socket handle.
    */
   public int getNativeSocket() {
      return m_socket.getNativeSocket();
   }

   /**
    * Attach a Socket to this instance. If this instance is 
    * already managing a socket, then error is returned. 
    * 
    * @param socket  Socket instance.
    * 
    * @return 0 on success, <0 on error.
    */
   public int attachSocket(Socket& socket) {

      if( m_socket.valid() ) {
         return SOCK_IN_USE_RC;
      }
      m_socket = socket;
      return 0;
   }

   /**
    * Detach Socket managed by this instance.
    *
    * @return Socket instance. null is returned if this 
    *         instance was not managing a Socket.
    */
   public Socket detachSocket() {

      if( !m_socket.valid() ) {
         return null;
      }
      Socket copy_socket = m_socket;
      m_socket.detachNativeSocket();
      return copy_socket;
   }

   /**
    * Return Socket being managed by this instance.
    * 
    * @return Socket instance.
    */
   public Socket* getSocket() {
      return &m_socket;
   }

   /**
    * Return timeout (in milliseconds) for connections and 
    * receiving data. 
    * 
    * @return Timeout in milliseconds.
    */
   public int getTimeout() {
      return m_socket.getTimeout();
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
         m_socket.setTimeout(timeout);
      }
   }

   /**
    * Connect to the given host at the given port, and use the
    * specified timeout value. 
    *
    * @param host     The name of the host to connect to ("" 
    *                 implies local host).
    * @param port     The port to attach at. 
    * @param timeout  Number of milliseconds to wait for a 
    *                 connection. Set to 0 to use default timeout.
    *                 Defaults to 0.
    *
    * @return 0 on success, <0 on error. 
    */
   public int connect(_str host, _str port, int timeout=0) {
      return m_socket.connect(host,port,timeout);
   }

   /** 
    * Test if this client socket is connected. 
    *
    * @return true if socket is connected. 
    */
   public bool isConnected() {
      return m_socket.isConnected();
   }

   /**
    * Test if underlying native socket handle is valid. Note that 
    * this is not the same as calling isConnected. 
    * 
    * @return True if underlying native socket handle is valid.
    */
   public bool valid() {
      return m_socket.valid();
   }

   /**
    * Close this client socket connection. 
    *
    * @return 0 on success, <0 on error. 
    */
   public int close() {
      return m_socket.close();
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
      return m_socket.send(data,len);
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
      return m_socket.sendBlob(hblob,len);
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
      return m_socket.receive(data,peek,timeout);
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
      return m_socket.receive_if_pending(data);
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
    * @param timeout    Number of milliseconds to wait for a 
    *                   response on the socket.
    *
    * @return 0 on success, <0 on error.
    *
    * @see receive
    * @see receieveToBlob
    */
   public int receiveToFile(_str filename, XLAT_FLAGS xlatFlags=XLATFLAG_NONE, int timeout=0) {
      return m_socket.receiveToFile(filename,xlatFlags,timeout);
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
    * @param timeout  Number of milliseconds to wait for a response
    *                 on the socket.
    *
    * @return 0 on success, <0 on error.
    *
    * @see receive
    * @see receieveToFile
    */
   public int receiveToBlob(int hblob, bool peek=false, int timeout=0) {
      return m_socket.receiveToBlob(hblob,peek,timeout);
   }

   /**
    * Poll for data on the socket. Data is left on socket. Returns 
    * immediately. 
    *
    * @return True if there is data waiting on the socket.
    */
   public bool poll() {
      return m_socket.poll();
   }

   /**
    * Return the local endpoint IP address that this socket 
    * is bound to. 
    *
    * @return Local endpoint IP address as string, null if socket 
    *         is not bound.
    */
   public _str getLocalIpAddress() {
      return m_socket.getLocalIpAddress();
   }

   /**
    * Return the local endpoint port that this socket is bound to. 
    *
    * @return >0 port on success, 0 if this socket is not bound.
    */
   public int getLocalPort() {
      return m_socket.getLocalPort();
   }

   /**
    * Return the remote endpoint IP address that this socket is
    * connected to. 
    *
    * @return Remote endpoint IP address as string, null if socket 
    *         is not connected.
    */
   public _str getRemoteIpAddress() {
      return m_socket.getRemoteIpAddress();
   }

   /**
    * Return the remote endpoint port that this socket is connected 
    * to. 
    *
    * @return >0 port, 0 if this socket is not connected.
    */
   public int getRemotePort() {
      return m_socket.getRemotePort();
   }

};
