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
#pragma option(pedantic, on)
#region Imports
#require "sc/net/ISocketCommon.e"
#require "sc/net/IServerSocket.e"
#require "sc/net/IClientSocket.e"
#endregion

namespace sc.net;

/**
 * BETA
 *
 * Server socket interface.
 */
interface IServerSocket : ISocketCommon {

   /** 
    * Test if server socket is listening.
    *
    * @return true if socket is listening.
    */
   boolean isListening();

   /** 
    * Return number of pending connections. 
    *
    * @return Number of pending connections >=0.
    */
   int pending();

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
   int listen(_str host, _str port="0");

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
   int acceptClient(IClientSocket& accepted_socket);

   /**
    * Accept a pending connection. Use pending to check for pending
    * connections. 
    * 
    * @param accepted_socket (out) Set to accepted connection 
    *                        socket handle.
    *
    * @return 0 on success, <0 on error.
    */
   int accept(int& accepted_socket);

};
