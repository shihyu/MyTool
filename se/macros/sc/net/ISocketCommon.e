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
#endregion

namespace sc.net;

/**
 * BETA
 *
 * Interface to socket operations common to both client and 
 * server sockets. 
 */
interface ISocketCommon {

   /**
    * Attach a native socket handle to the instance. If the 
    * instance is already managing a native socket, then error is 
    * returned. 
    * 
    * @param s  Native socket handle.
    * 
    * @return 0 on success, <0 on error.
    */
   int attachNativeSocket(int s);

   /**
    * Detach native socket handle.
    *
    * @return Native socket handle. INVALID_SOCKET is returned if
    *         the instance was not managing a native socket.
    */
   int detachNativeSocket();

   /**
    * Return native socket handle.
    * 
    * @return Native socket handle.
    */
   int getNativeSocket();

   /**
    * Test if socket is valid. Note that this is not the same as
    * testing for alive'ness. 
    * 
    * @return True if native socket handle is valid.
    */
   bool valid();

   /**
    * Close the socket.
    *
    * @return 0 on success, <0 on error.
    */
   int close();

   /**
    * Return the local endpoint IP address that the socket is bound
    * to. 
    *
    * @return Local endpoint IP address as string, null if socket 
    *         is not bound.
    */
   _str getLocalIpAddress();

   /**
    * Return the local endpoint port that the socket is bound to. 
    *
    * @return >0 port on success, 0 if socket is not bound.
    */
   int getLocalPort();

};
