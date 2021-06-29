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
#import "stdprocs.e"
#endregion

namespace se.net;

/**
 * BETA
 *
 * Singleton server connection pool class. Maintains a pool of
 * server connections. 
 */
class ServerConnectionPool {

   // So we do not have to keep creating a temp copy
   private ServerConnection m_server_prototype;
   private ServerConnection m_servers:[];

   /**
    * private: Constructor.
    */
   private ServerConnectionPool() {
   }

   /**
    * Destructor.
    */
   ~ServerConnectionPool() {
   }

   static private ServerConnectionPool* getServerConnectionPool() {

      pool_key := "ServerConnectionPool";
      ServerConnectionPool* pool = (ServerConnectionPool*)_GetDialogInfoHtPtr(pool_key,_mdi);
      if( !pool ) {
         // First call, so "anchor" the pool in the _mdi window. This makes
         // the instance persistent only for the life of the application. We
         // do not have to worry about cleaning up a global variable or having
         // a static variable inadvertantly saved in the state file. Nothing
         // persists beyond the life of the application and the pool and all
         // its ServerConnection's are closed on destruction.
         //say('ServerConnectionPool::getServerConnectionPool: creating pool');
         ServerConnectionPool proto_pool;
         _SetDialogInfoHt(pool_key,proto_pool,_mdi);
         pool = (ServerConnectionPool*)_GetDialogInfoHtPtr(pool_key,_mdi);
         // Make sure we know how bad things are if we failed to set the pool
         _assert(pool != null,"Failed to create/get persistent ServerConnectionPool instance");
      }
      return pool;
   }

   /**
    * Allocate a server indexed by unique id. If server already 
    * exists with matching id, then existing server is returned. If 
    * you only want to check if a server exists with unique id, 
    * then use the find method. 
    * 
    * @param id  Unique id used to retrieve ServerConnection 
    *            instance.
    * 
    * @return ServerConnection instance.
    */
   static public ServerConnection* allocate(_str id) {
      ServerConnectionPool* pool = ServerConnectionPool.getServerConnectionPool();
      ServerConnection* server = pool->m_servers._indexin(id);
      if( !server ) {
         // Create it
         pool->m_servers:[id] = pool->m_server_prototype;
         server = pool->m_servers._indexin(id);
      }
      return server;
   }

   /**
    * Release the server indexed by unique id.
    * 
    * @param id  Unique id of server.
    */
   static public void release(_str id) {
      ServerConnectionPool* pool = ServerConnectionPool.getServerConnectionPool();
      ServerConnection* server = pool->m_servers._indexin(id);
      if( server ) {
         pool->m_servers._deleteel(id);
      }
   }

   /**
    * Find first server indexed by id. Returns an instance pointer 
    * to ServerConnection. 
    * 
    * @param id      Id to match.
    * @param prefix  Set to true to prefix match on id. Defaults to 
    *                false.
    * 
    * @return ServerConnection instance.
    */
   static public ServerConnection* find(_str id, bool prefix=false, _str& id_found=null) {

      ServerConnectionPool* pool = ServerConnectionPool.getServerConnectionPool();

      if( !prefix ) {
         // Simple unique match
         ServerConnection* server = pool->m_servers._indexin(id);
         if( server ) {
            id_found = id;
            return server;
         }
      }

      // Prefix match
      typeless i;
      for( i._makeempty();; ) {
         pool->m_servers._nextel(i);
         if( i._isempty() ) {
            break;
         }
         if( substr(i,1,length(id)) == id ) {
            // Found a prefix match
            id_found = i;
            return &(pool->m_servers._el(i));
         }
      }

      // No match
      return null;
   }

   /**
    * Find server bound to host:port. Specify "" for host or port 
    * (not both) to search on only one parameter. 
    * 
    * @param host  Host to search on.
    * @param port  Port to search on.
    * @param id    (out) Optional. If specified, set to id of 
    *              server found.
    * 
    * @return ServerConnection instance.
    */
   static public ServerConnection* findByAddr(_str host, _str port, _str& id=null) {

      id = "";

      if( host == "" && port == "" ) {
         // Don't be silly
         return null;
      }

      ServerConnectionPool* pool = ServerConnectionPool.getServerConnectionPool();

      ServerConnection* server = null;

      typeless i;
      for( i._makeempty();; ) {
         server = null;
         pool->m_servers._nextel(i);
         if( i._isempty() ) {
            break;
         }
         server = &(pool->m_servers._el(i));
         if( host != "" &&
             server->getHost(false) != host && server->getHost(true) != host ) {

            // No match on host
            continue;
         }
         if( port != "" &&
             server->getPort(false) != port && server->getPort(true) != port ) {

            // No match on port
            continue;
         }
         // Found a match
         id = i;
         break;
      }
      return server;
   }

   static public void getAllIds(_str (&list)[]) {

      ServerConnectionPool* pool = ServerConnectionPool.getServerConnectionPool();

      list._makeempty();
      typeless i;
      for( i._makeempty();; ) {
         pool->m_servers._nextel(i);
         if( i._isempty() ) {
            break;
         }
         list[list._length()] = i;
      }
   }

};

namespace default;

using se.net.ServerConnectionPool;
using se.net.ServerConnection;

/**
 * Called when application exits. Guarantees that all servers 
 * are shut down before application exits. 
 * 
 * @return 0
 */
int _exit_ServerConnectionPool()
{
   _str list[];
   ServerConnectionPool.getAllIds(list);
   foreach( auto id in list ) {
      ServerConnection* server = ServerConnectionPool.find(id);
      server->shutdown();
      ServerConnectionPool.release(id);
   }
   return 0;
}
