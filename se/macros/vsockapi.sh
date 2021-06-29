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
#pragma option(metadata,"ftp.e")

/**
 * Initializes the OS socket layer subsystem.
 *
 * @return Returns 0 if successful. Common return codes are: SOCK_INIT_FAILED_RC
 * @see vssIsInit
 */
extern int vssInit(...);

/**
 * Exit the OS socket layer subsystem.
 *
 * @return
 * @see vssInit
 */
extern void vssExit();

/**
 * Test initialization of OS socket layer.
 *
 * @return Returns 0 (false) if OS socket layer is not initialized. Otherwise returns
 *         non-zero (true).
 * @see vssInit
 */
extern int vssIsInit();

/**
 * Establish a connection/listen on the host specified on the port
 * specified. hiSock is set to the successfully connected socket
 * number.
 * <P>
 * <B>Please note:</B><BR>
 * If szPort="0" then a port is assigned dynamically to the next available
 * unassigned port.
 * <P>
 * If iListen=non-zero OR port="0" then a listen()ing socket is
 * established. Otherwise a connect()ed socket is established.
 *
 * @param szHost   Host name to connect to/listen on
 *
 * @param szPort   Port on host to connect to/listen on (i.e. 'ftp' or '21')
 *
 * @param hiSock   Set by vssSocketOpen(). Socket to be bound/connected
 *
 * @param iListen  1=listen on socket/host/port combination, 0=no listen
 *
 * @param iTimeout Connection timeout (milliseconds)
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_NET_DOWN_RC,
 *         SOCK_BAD_PORT_RC,
 *         SOCK_BAD_HOST_RC
 * @see vssSocketClose
 * @see vssIsSocketListening
 * @see vssSocketAcceptConn
 * @see vssIsConnectionAlive
 */
extern int vssSocketOpen(_str szHost,_str szPort,int& hiSock,int iListen,int iTimeout);

/**
 * Close the socket iSock.
 * <P>
 * <B>Please note:</B><BR>
 *   The close is "graceful" because any unsent data is sent. This function
 *   returns immediately however.
 * <P>
 * <B>Please note:</B><BR>
 *   Even though the socket is closed, the port associated with the
 *   previously connected/bound socket is unavailable for a system-
 *   specific amount of time (~4 minutes under Windows).
 *
 * @param iSock  iSock - Socket to close
 *
 * @return
 * @see vssSocketOpen
 * @see vssIsSocketListening
 * @see vssSocketAcceptConn
 */
extern void vssSocketClose(int iSock);

/**
 * Sends data contained in buf to socket hiSock.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock MUST be in a connected state for
 * sending to work. If it is currently listening, then any pending
 * connection is accepted before data is sent, and the newly connected
 * socket is stored in hiSock.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * If you want to send arbitrary binary data (e.g. data with 
 * embedded ascii null (0)), then use the _Blob* api and 
 * vssSocketSendBlob instead. 
 *
 * @param hiSock   Socket to send to
 * @param buf      Buffer data to send
 * @param iBufLen  Length of buffer data
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 * @see vssSocketSendBlob
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToView
 */
extern int vssSocketSend(int& hiSock,_str buf,int iBufLen);

/**
 * Sends ascii-z string data (null terminated), to socket hiSock.
 * <P>
 * <B>Note:</B>
 * The socket number stored in hiSock MUST be in a connected state for
 * sending to work. If it is currently listening, then any pending
 * connection is accepted before data is sent, and the newly connected
 * socket is stored in hiSock.
 *
 * @param hiSock Socket to send to
 *
 * @param szBuf  Ascii-z string data to send
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 * @see vssSocketSend
 * @see vssSocketSendFile
 * @see vssSocketSendBlob
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToView
 */
extern int vssSocketSendZ(int& hiSock,_str szBuf);

/**
 * Sends a file, specified by szFilename, to connected socket iSock.
 * <P>
 * <B>Note:</B>
 *   The socket number stored in hiSock must be in a connected state for
 *   sending to work.
 * <P>
 * <B>Note:</B>
 *   The socket hiSock is not closed by this function under any
 *   any circumstances. It is the responsibility of the caller to
 *   close the socket.
 *
 * @param hiSock Socket to send to
 *
 * @param szFilename Name of file to send
 *
 * @param iXlatFlags Newline translation flags. This determines how newlines
 *                   will be translated before being sent. A value of 0
 *                   indicates no translation. The following flags are
 *                   available:
 *
 *                   XLATFLAG_DOS   - Translate all newlines to \r\n
 *                   XLATFLAG_UNIX  - Translate all newlines to \n
 *                   XLATFLAG_LOCAL - Translate all newlines to the local
 *                   newline (i.e. \r\n for DOS or \n for
 *                   UNIX)
 *
 * @return Returns 0 if successful. Common return codes are:
 *         FILE_NOT_FOUND_RC,
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendBlob
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToView
 */
extern int vssSocketSendFile(int& hiSock,_str szFilename,int iXlatFlags);

/**
 * Send data from internal "blob" to connected socket iSock. 
 * Writing starts from the current blob offset. The current blob 
 * offset is not changed. 
 * 
 * <p>
 *
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. It is especially useful for data that may 
 * contain ascii null (0) bytes which Slick-C does not handle. 
 * Use the Slick-C _Blob* api to get, set, and manipulate 
 * specific types of data. 
 * 
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock must be in a connected
 * state for sending to work.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * The socket hiSock is not closed by this function under any 
 * any circumstances. It is the responsibility of the caller to 
 * close the socket. 
 *
 * @param hiSock Socket to send to
 * @param hblob  Handle to blob returned by _BlobAlloc.
 * @param iLen   Number of bytes to write from blob.
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToView
 * @see vssSocketRecvToBlob
 */
extern int vssSocketSendBlob(int& hiSock, int hBlob, int iLen);

/**
 * Test iSock for a listening state. If iSock is listening then 
 * set hiPendingConn equal to the number of pending connections 
 * on the queue. Use vssSocketAcceptConn to accept a connection 
 * and close the listening socket. Use vssSocketAcceptConn2 to 
 * accept a connection and leave the listening socket open. 
 *
 * @param iSock  Socket to test for listening AND a pending 
 *               connection.
 *
 * @param hiPendingConn  Set by vssIsSocketListening(). Number 
 *                       of pending connection attempts on the
 *                       queue.
 *
 * @return Returns 1 (true) if listening. Otherwise 0 (false) is
 *         returned.
 *
 * @see vssSocketOpen
 * @see vssSocketClose
 * @see vssSocketAcceptConn
 * @see vssSocketAcceptConn2
 */
extern int vssIsSocketListening(int iSock,int& hiPendingConn);

/**
 * If hiSock is in a listening state AND there are pending connections
 * queued, then 1 pending connection is accepted and hiSock is set to the
 * newly connected socket descriptor.
 * <P>
 * <B>Note:</B>
 * The original listening socket is closed. Use vsockSocketAcceptConn2()
 * if you want to leave the original listening socket in a listening state.
 *
 * @param hiSock Set by vssSocketAcceptConn(). Socket on which to accept connection.
 *
 * @return Returns 0 on success. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC,
 *         SOCK_NOT_LISTENING_RC,
 *         SOCK_NO_CONN_PENDING_RC
 * @see vssSocketAcceptConn2
 * @see vssSocketOpen
 * @see vssSocketClose
 * @see vssIsSocketListening
 */
extern int vssSocketAcceptConn(int& hiSock);

/**
 * If iSock is in a listening state AND there are pending connections
 * queued, then 1 pending connection is accepted and the newly connected
 * socket descriptor is returned.
 * <P>
 * <B>Note:</B>
 * The original listening socket is left open.
 *
 * @param iSock Socket on which to accept connection.
 *
 * @return Returns an accepted socket descriptor on success, or return
 * code indicating error. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC,
 *         SOCK_NOT_LISTENING_RC,
 *         SOCK_NO_CONN_PENDING_RC
 * @see vssSocketAcceptConn
 * @see vssSocketOpen
 * @see vssSocketClose
 * @see vssIsSocketListening
 */
extern int vssSocketAcceptConn2(int iSock);

/**
 * Receives ascii-z string data (null terminated) into hszBuf from
 * connected socket hiSock.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * If you need to receive data that contains ascii null (0) 
 * characters, then use vssSocketRecvToBlob instead. 
 * 
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock must be in a connected 
 * state for receiving to work. If the socket stored in hiSock 
 * is in a listening state, then this call will accept a 
 * connection and change the descriptor stored in hiSock to an 
 * accepted socket descriptor AND CLOSE THE LISTENING SOCKET.
 *
 * @param hiSock     Set by vssSocketRecvToZStr(). Socket to 
 *                   receive from.
 * @param hszBuf     Ascii-z buffer to receive data into
 * @param iWaitmsec  Number of milliseconds to wait for a 
 *                   response on the socket
 * @param iPeek      Non-zero=peek at the data instead of 
 *                   reading it. Data is copied into hszBuf
 *                   without being removed from the queue.
 *
 * @return Returns 0 on success. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketRecvToBlob
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToView
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 */
extern int vssSocketRecvToZStr(int& hiSock,
                               _str& hszBuf,
                               int iWaitmsec,
                               int iPeek);

/**
 * Receives data from connected socket hiSock and stores in a 
 * VSBLOB object. This function is useful when the data you 
 * receive may contain ascii null (0) bytes which prevent you
 * from using vssSocketRecvToZStr. Use the Slick-C _Blob* api to 
 * manipulate data in the blob after calling this function. 
 *
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock must be in a connected 
 * state for receiving to work. If the socket stored in hiSock 
 * is in a listening state, then this call will accept a 
 * connection and change the descriptor stored in hiSock to an 
 * accepted socket descriptor AND CLOSE THE LISTENING SOCKET.
 *
 * @param hiSock      Set by vssSocketRecvToBlob(). Socket to 
 *                    receive from.
 * @param hBlob       Handle to blob that will receive data.
 * @param iWaitmsec   Number of milliseconds to wait for a 
 *                    response on the socket.
 * @param iPeek       Non-zero=peek at the data instead of 
 *                    reading it. Data is copied into hszBuf
 *                    without being removed from the socket.
 *
 * @return Returns 0 on success. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToView
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 */
extern int vssSocketRecvToBlob(int& hiSock,
                               int hBlob,
                               int iWaitmsec,
                               int iPeek);

/**
 * Receives data from connected socket hiSock and stores it in a file
 * given by szFilename.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock must be in a connected 
 * state for receiving to work. If the socket stored in hiSock 
 * is in a listening state, then this call will accept a 
 * connection and change the descriptor stored in hiSock to an 
 * accepted socket descriptor AND CLOSE THE LISTENING SOCKET.
 *
 * @param hiSock      Set by vssSocketRecvToFile(). Socket to 
 *                    receive from.
 * @param szFilename  Name of file in which to store received 
 *                    data
 * @param iWaitmsec   Number of milliseconds to wait for a 
 *                    response on the socket
 * @param iXlatFlags  Newline translation flags. This determines how newlines
 *                    will be translated before being written to file. A value
 *                    of 0 indicates no translation. The following flags are
 *                    available:
 *                    
 *                    XLATFLAG_DOS   - Translate all newlines to \r\n
 *                    XLATFLAG_UNIX  - Translate all newlines to \n
 *                    XLATFLAG_LOCAL - Translate all newlines to the local
 *                    newline (i.e. \r\n for DOS or \n for
 *                    UNIX)
 *
 * @return Returns 0 on success. Common return codes are:
 *         FILE_NOT_FOUND_RC,
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketRecvToBlob
 * @see vssSocketRecvToZStr
 * @see vssSocketRecvToView
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 */
extern int vssSocketRecvToFile(int& hiSock,
                               _str szFilename,
                               int iWaitmsec,
                               int iXlatFlags);

/**
 * Receives data from connected socket hiSock and outputs it to a view
 * given by iViewId.
 *
 * <p>
 *
 * <b>Note:</b><br>
 * The socket number stored in hiSock must be in a connected 
 * state for receiving to work. If the socket stored in hiSock 
 * is in a listening state, then this call will accept a 
 * connection and change the descriptor stored in hiSock to an 
 * accepted socket descriptor AND CLOSE THE LISTENING SOCKET.
 *
 * @param hiSock      Set by vssSocketRecvToView(). Socket to 
 *                    receive from.
 * @param iViewId     View id that will receive data
 * @param iWaitmsec   Number of milliseconds to wait for a 
 *                    response on the socket
 * @param iXlatFlags  Newline translation flags. This determines how newlines
 *                    will be translated before being written to file. A value
 *                    of 0 indicates no translation. The following flags are
 *                    available:
 *                    
 *                    XLATFLAG_DOS   - Translate all newlines to \r\n
 *                    XLATFLAG_UNIX  - Translate all newlines to \n
 *                    XLATFLAG_LOCAL - Translate all newlines to the local
 *                    newline (i.e. \r\n for DOS or \n for
 *                    UNIX)
 *
 * @return Returns 0 on success. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_TIMED_OUT_RC,
 *         SOCK_BAD_SOCKET_RC,
 *         SOCK_SOCKET_NOT_CONNECTED_RC
 *
 * @see vssSocketRecvToBlob
 * @see vssSocketRecvToFile
 * @see vssSocketRecvToZStr
 * @see vssSocketSend
 * @see vssSocketSendZ
 * @see vssSocketSendFile
 */
extern int vssSocketRecvToView(int& hiSock,
                               int iViewId,
                               int iWaitmsec,
                               int iXlatFlags);

/**
 * Poll connected socket for data available on socket. 
 *
 * @param iSock  Socket to poll.
 *
 * @return Returns 1 (true) if there is data on the socket, 0 
 *         (false) otherwise.
 */
extern int vssSocketPoll(int iSock);

/**
 * Tests whether a socket connection is alive.
 * <P>
 * <B>Note:</B>
 * If iSock is in a listen()ing state, then it is considered alive.
 *
 * @param iSock  Socket to query connection status on
 *
 * @return Returns non-zero if socket's connection is alive. Otherwise returns 0.
 * @see vssIsSocketListening
 */
extern int vssIsConnectionAlive(int iSock);

/**
 * Get the host name of the local machine.
 *
 * @param hszName Set by vssGetMyHostName(). Host name of the local machine.
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC
 * @see vssGetHostAddress
 */
extern int vssGetMyHostName(_str& hszName);

/**
 * Resolve a host name to an ip address.
 * 
 * @param szHostName Host name.
 * @param hszAddr    Set by vssGetHostAddress(). Address of the
 *                   host.
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 * @see vssGetMyHostName
 */
extern int vssGetHostAddress(_str szHostName, _str& hszAddr);

/**
 * Retrieve local host and port associations of connected/bound
 * socket iSock.
 *
 * @param iSock   Bound/connected socket to retrieve information about
 * @param hszHost Set by vssGetLocalSocketInfo(). Name of local host
 *                connected/bound to iSock.
 * @param hiPort  Set by vssGetLocalSocketInfo(). Port of local host
 *                connected/bound to iSock.
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_BAD_SOCKET_RC
 *
 * @see vssGetRemoteSocketInfo
 */
extern int vssGetLocalSocketInfo(int iSock, _str& hszHost, int& hiPort);

/**
 * Retrieve remote host and port associations of connected or bound
 * socket iSock. This function is especially useful when you connect()ed
 * a socket without first bind()ing it because you can then retrieve
 * the remote host name and port number of the connection.
 *
 * <p>
 * <b>Note:</b><br>
 * Best if used on a connected (not listening), socket.
 *
 * @param iSock    Bound/connected socket to retrieve 
 *                 information about
 * @param hszHost  Set by vssGetRemoteSocketInfo(). Name of 
 *                 remote host bound/connected to iSock.
 * @param hiPort   Set by vssGetRemoteSocketInfo(). Port of 
 *                 remote host bound/connected to iSock.
 *
 * @return Returns 0 if successful. Common return codes are:
 *         SOCK_NOT_INIT_RC,
 *         SOCK_BAD_SOCKET_RC
 *
 * @see vssGetLocalSocketInfo
 */
extern int vssGetRemoteSocketInfo(int iSock, _str& hszHost, int& hiPort);

/**
 * Translate the service name stored in szService into a port 
 * number. 
 *
 * @param szService  Name of service to translate into port 
 *                   number.
 *
 * @return Returns >=0 port number on success, <0 on error. 
 *         Common return codes are: SOCK_BAD_PORT_RC.
 */
extern int vssServiceNameToPort(_str szService);

extern int vssDecrypt(_str szCiphertext, _str &hszPlaintext);
extern int vssEncrypt(_str szPlaintext, _str &hszCiphertext);

const INVALID_SOCKET= (-1);

/** Default connection timeout (milliseconds). */
const SOCKDEF_CONNECT_TIMEOUT= (30000);

