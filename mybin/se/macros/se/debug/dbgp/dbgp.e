////////////////////////////////////////////////////////////////////////////////////
// $Revision: 43807 $
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
#require "se/net/ServerConnection.e"
#require "se/net/ServerConnectionPool.e"
#require "se/net/ServerConnectionObserver.e"
#import "compile.e"
#include "se/debug/dbgp/DBGpOptions.e"
#endregion

namespace se.debug.dbgp;

using se.net.ServerConnection;
using se.net.ServerConnectionPool;
using se.net.ServerConnectionObserver;
using namespace se.net;

/**
 * Create a unique id that allows us to retrieve DBGp-protocol 
 * server connections and shut down servers opened for a 
 * project. 
 * 
 * @param proto        Specific DBGp protocol implementer (e.g. 
 *                     "xdebug", "pydbgp", etc.). This is used
 *                     to associate an id uniquely with a
 *                     specific debugger implementation.
 * @param projectName 
 * @param host 
 * @param port 
 * 
 * @return Unique server id.
 */
_str proto_server_id(_str proto, _str projectName, _str host, _str port)
{
   _str id = _parse_project_command("%rn","",projectName,"")':'proto':'host':'port;
   return id;
}

/**
 * Test for a pending connection from DBGp-protocol debugger 
 * engine on host:port. 
 *
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   Host to wait on.
 * @param port   Port to wait on.
 * 
 * @return True if there is a connection pending.
 */
boolean proto_is_pending(_str proto, _str host, _str port)
{
   _str id = proto_server_id(proto,_project_name,host,port);
   ServerConnection* server = ServerConnectionPool.find(id);
   if( !server ) {
      return false;
   }
   se.net.SERVER_CONNECTION_STATUS status = server->getStatus();
   return ( status == SCS_PENDING );
}

/**
 * Actively wait for a pending connection from DBGp-protocol 
 * debugger engine on host:port for timeout milliseconds. 
 *
 * @param proto     Specific DBGp protocol implementer (e.g. 
 *                  "xdebug", "pydbgp", etc.). This is used to
 *                  associate an id uniquely with a specific
 *                  debugger implementation.
 * @param host      Host to wait on.
 * @param port      Port to wait on.
 * @param timeout   Time in milliseconds to wait for a pending 
 *                  connection to become available.
 * @param observer  Observer instance.
 * @param close_on_error  Set to true if you want the server 
 *                        closed on error.
 * 
 * @return 0 on success, <0 on error.
 */
int proto_wait(_str proto,
               _str host, _str port, int timeout,
               ServerConnectionObserver* observer,
               boolean close_on_error)
{
   // Actively wait for a pending connection from DBGp-type debugger engine
   _str id = proto_server_id(proto,_project_name,host,port);
   ServerConnection* server = ServerConnectionPool.allocate(id);
   int status = 0;
   if( observer ) {
      // Cancel-able server
      observer->setOnCancelHandler(server);
      status = server->wait(host,port,timeout,observer);
      observer->setOnCancelHandler(null);
   } else {
      status = server->wait(host,port,timeout,observer);
   }
   if( status != 0 && close_on_error ) {
      server->shutdown();
      ServerConnectionPool.release(id);
   }
   return status;
}

/**
 * Actively wait for a pending connection from DBGp-protocol 
 * debugger engine on host:port for timeout milliseconds. If 
 * connection is pending before timeout then connection is 
 * accepted and returned. 
 *
 * @param proto     Specific DBGp protocol implementer (e.g. 
 *                  "xdebug", "pydbgp", etc.). This is used to
 *                  associate an id uniquely with a specific
 *                  debugger implementation.
 * @param host      Host to wait on.
 * @param port      Port to wait on.
 * @param timeout   Time in milliseconds to wait for a pending 
 *                  connection to become available.
 * @param observer  Observer instance.
 * @param close_if_first  Set to true if you want the server
 *                        closed after first use. If the server
 *                        already existed (e.g. current watch),
 *                        then it is left open/listening.
 * 
 * @return >0 socket handle on success, <0 on error.
 */
int proto_wait_and_accept(_str proto,
                          _str host, _str port, int timeout,
                          ServerConnectionObserver* observer,
                          boolean close_if_first)
{
   _str id = proto_server_id(proto,_project_name,host,port);
   ServerConnection* server = ServerConnectionPool.find(id);
   boolean first = ( server == null );

   int status_or_socket = proto_wait(proto,host,port,timeout,observer,(first&&close_if_first));
   if( status_or_socket != 0 ) {
      // Error
      return status_or_socket;
   }
   // We have a pending connection
   if( !server ) {
      // New server
      id = proto_server_id(proto,_project_name,host,port);
      server = ServerConnectionPool.find(id);
   }
   status_or_socket = server->accept();
   if( first && close_if_first ) {
      // A one-shot server, so shut it down
      server->shutdown();
      ServerConnectionPool.release(id);
   }
   return status_or_socket;
}

/**
 * Passively watch for a pending connection from DBGp-protocol 
 * debugger engine on host:port. 
 *
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   Host to wait on.
 * @param port   Port to wait on.
 * 
 * @return 0 on success, <0 on error.
 */
int proto_watch(_str proto, _str host, _str port, ServerConnectionObserver* observer)
{
   // Passively listen for a connection from DBGp-type debugger engine
   _str id = proto_server_id(proto,_project_name,host,port);
   ServerConnection* server = ServerConnectionPool.allocate(id);
   int status = server->watch(host,port,-1,observer);
   return status;
}

/**
 * Do we have a DBGp-protocol server provisioned and listening 
 * on host:port? 
 * 
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   Host to test.
 * @param port   Port to test.
 * 
 * @return True if there is a server listening on host:port.
 */
boolean proto_is_listening(_str proto, _str host, _str port)
{
   ServerConnection* server = ServerConnectionPool.findByAddr(host,port);
   return ( server != null && server->isListening() );
}

/**
 * Retrieve the actual server host:port address that is 
 * listening. This is useful when the server was started with a 
 * port of 0 (dynamically assigned port). 
 * 
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   (in,out) Host to lookup/retrieve.
 * @param port   (in,out) Port to lookup/retrieve.
 * 
 * @return True if server exists and host, port are set to 
 *         address found. Note that the server can exist (is
 *         provisioned) but still not be listening. Use
 *         proto_is_listening to test for a listening server.
 */
boolean proto_get_server_address(_str proto, _str& host, _str& port)
{
   ServerConnection* server = ServerConnectionPool.findByAddr(host,port);
   if( !server ) {
      return false;
   }

   // Success
   host = server->getHost(true);
   port = server->getPort(true);
   return true;
}

/**
 * Shut down the DBGp-protocol server listening on host:port.
 * 
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   Host identifying server to shutdown.
 * @param port   Port identifying server to shutdown.
 *
 * @return 0 on success, <0 on error.
 */
int proto_shutdown(_str proto, _str host, _str port)
{
   _str id_found = null;
   ServerConnection* server = ServerConnectionPool.findByAddr(host,port,id_found);
   if( server ) {
      server->shutdown();
      ServerConnectionPool.release(id_found);
   }
   return 0;
}

/**
 * Clear the last error for DBGp-protocol server listening on 
 * host:port. 
 * 
 * @param proto  Specific DBGp protocol implementer (e.g. 
 *               "xdebug", "pydbgp", etc.). This is used to
 *               associate an id uniquely with a specific
 *               debugger implementation.
 * @param host   Host identifying server to clear.
 * @param port   Port identifying server to clear.
 *
 * @return 0 on success, <0 on error.
 */
int proto_clear_last_error(_str proto, _str host, _str port)
{
   ServerConnection* server = ServerConnectionPool.findByAddr(host,port);
   if( server ) {
      server->resetStatus();
   }
   return 0;
}

DBGpFeatures dbgp_make_default_features(DBGpFeatures& dbgp_features=null)
{
   dbgp_features.show_hidden = true;
   dbgp_features.max_children = 32;
   return dbgp_features;
}


namespace default;

// DEBUG
_command void dbgp_list_all()
{
   _str list[];
   ServerConnectionPool.getAllIds(list);
   foreach( auto id in list ) {
      say('dbgp_list_all: id='id);
   }
}

// DEBUG
_command void dbgp_release_all()
{
   _str list[];
   ServerConnectionPool.getAllIds(list);
   foreach( auto id in list ) {
      ServerConnection* server = ServerConnectionPool.find(id);
      server->shutdown();
      ServerConnectionPool.release(id);
   }
}
