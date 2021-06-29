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
#require "sc/net/Socket.e"
#require "sc/net/ClientSocket.e"
#endregion

namespace sc.net;

/**
 * BETA
 *
 * This class is used to listen for and accept connections from 
 * clients over TCP sockets. It is a wrapper around the Socket 
 * class and provides a simpler subset of listener-oriented 
 * functionality. 
 */
class ServerSocket : IServerSocket {

   // Listening socket
   private Socket m_socket;

   /**
    * Constructor.
    */
   ServerSocket() {
   }

   /**
    * Destructor.
    */
   ~ServerSocket() {
      close();
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
      return m_socket.attachNativeSocket(s);
   }

   /**
    * Detach native socket managed by this instance.
    *
    * @return Native socket handle. INVALID_SOCKET is returned if
    *         this instance was not managing a native socket.
    */
   public int detachNativeSocket() {
      return m_socket.detachNativeSocket();
   }

   /**
    * Return native socket being managed by this instance.
    * 
    * @return Native socket handle.
    */
   public int getNativeSocket() {
      return m_socket.getNativeSocket();
   }

   /** 
    * Test if server socket is listening.
    *
    * @return true if socket is listening.
    */
   public bool isListening() {
      return m_socket.isListening();
   }

   /** 
    * Return number of pending connections. 
    *
    * @return Number of pending connections >=0.
    */
   public int pending() {
      return m_socket.pending();
   }

   /**
    * Return the local IP address that this server socket is bound
    * to. 
    *
    * @return Returns ip address string, null if socket is not
    *         bound.
    */
   public _str getLocalIpAddress() {
      return m_socket.getLocalIpAddress();
   }

   /**
    * Return the local port that this server socket is bound to. 
    *
    * @return Returns >0 port, 0 if this socket is not bound.
    */
   public int getLocalPort() {
      return m_socket.getLocalPort();
   }

   /**
    * Start this server socket listening on a specific address and 
    * port. When specifying 0 for the port, use getPort to retrieve 
    * the actual bound port. Use accept to accept a connection. 
    *
    * @param host     Host to listen on.
    * @param port     Port to listen on. Set to 0 to use any 
    *                 available port. Defaults to 0.
    *
    * @return 0 on success, <0 on error.
    */
   public int listen(_str host, _str port="0") {
      return m_socket.listen(host,port);
   }

   /**
    * Close this server socket.
    *
    * @return 0 on success, <0 on error.
    */
   public int close() {
      return m_socket.close();
   }

   /** 
    * Accept a connection. Note that server socket must be 
    * listening. Server socket is *not* closed after connection is 
    * accepted. Use pending to check for pending connections. Use 
    * the accept method if you want a simple native socket handle 
    * accepted and returned. 
    *
    * @param accepted_socket (out) Set to accepted client 
    *                        socket connection.
    *
    * @return 0 on success, <0 on error.
    *
    * @see accept
    */
   public int acceptClient(IClientSocket& accepted_socket) {
      return m_socket.acceptClient(accepted_socket);
   }

   /**
    * Accept a pending connection. Use pending to check for pending
    * connections. 
    * 
    * @param accepted_socket (out) Set to accepted connection 
    *                        socket handle.
    *
    * @return 0 on success, <0 on error.
    */
   int accept(int& accepted_socket) {
      return m_socket.accept(accepted_socket);
   }

   /**
    * Test if this server socket is valid. Note that this is not
    * the same as testing for alive'ness. 
    * 
    * @return True if server socket is valid.
    */
   public bool valid() {
      return m_socket.valid();
   }

};
