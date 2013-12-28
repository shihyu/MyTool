////////////////////////////////////////////////////////////////////////////////////
// $Revision:  $
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
#include "slick.sh"
#include "se/debug/dbgp/DBGpOptions.e"
#import "se/debug/dbgp/dbgp.e"
#include "se/debug/rdbgp/RdbgpOptions.e"
#import "debug.e"
#import "main.e"
#import "stdprocs.e"
#require "se/net/ServerConnection.e"
#require "se/net/ServerConnectionPool.e"
#require "se/net/ServerConnectionObserver.e"
#require "se/debug/rdbgp/RdbgpConnectionMonitor.e"
#require "se/net/ServerConnectionObserverFormInstance.e"
#import "wkspace.e"
#import "project.e"
#import "projconv.e"
#import "compile.e"
#import "mprompt.e"
#import "toast.e"
#endregion

namespace se.debug.rdbgp;

using se.net.ServerConnectionObserver;
using se.net.ServerConnectionObserverFormInstance;
using se.net.ServerConnection;
using se.net.ServerConnectionPool;

static RdbgpConnectionMonitor g_RdbgpMonitor;

using se.debug.dbgp.dbgp_make_default_features;

RdbgpOptions rdbgp_make_default_options(RdbgpOptions& rdbgp_opts=null)
{
   rdbgp_opts.serverHost = "127.0.0.1";
   rdbgp_opts.serverPort = "9000";
   rdbgp_opts.listenInBackground = true;
   rdbgp_opts.remoteFileMap = null;
   se.debug.dbgp.dbgp_make_default_features(rdbgp_opts.dbgp_features);
   // Default show_hidden variables to false for Ruby
   rdbgp_opts.dbgp_features.show_hidden = false;
   return rdbgp_opts;
}

/**
 * Retrieve rdbgp options for project and config.
 * 
 * @param projectHandle        Handle of project.
 * @param config               Configuration to retrieve options 
 *                             for.
 * @param rdbgp_opts          (out) Set to project rdbgp 
 *                             options.
 * @param default_rdbgp_opts  Default options to use in case no
 *                             options present for config.
 */
void rdbgp_project_get_options_for_config(int projectHandle, _str config, RdbgpOptions& rdbgp_opts, RdbgpOptions& default_rdbgp_opts=null)
{
   if( default_rdbgp_opts == null ) {
      rdbgp_make_default_options(default_rdbgp_opts);
   }
   _str serverHost = default_rdbgp_opts.serverHost;
   _str serverPort = default_rdbgp_opts.serverPort;
   boolean listenInBackground = default_rdbgp_opts.listenInBackground;
   RdbgpRemoteFileMapping remoteFileMap[] = default_rdbgp_opts.remoteFileMap;
   se.debug.dbgp.DBGpFeatures dbgp_features = default_rdbgp_opts.dbgp_features;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='rdbgp Options']",node);
      if( opt_node >= 0 ) {

         // ServerHost
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerHost']",opt_node);
         if( node >=0  ) {
            serverHost = _xmlcfg_get_attribute(projectHandle,node,"Value",serverHost);
         }

         // ServerPort
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ServerPort']",opt_node);
         if( node >=0  ) {
            serverPort = _xmlcfg_get_attribute(projectHandle,node,"Value",serverPort);
         }

         // ListenInBackground
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='ListenInBackground']",opt_node);
         if( node >=0  ) {
            listenInBackground = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)listenInBackground) );
         }

         // Remote file mappings
         _str nodes[];
         if( 0 == _xmlcfg_find_simple_array(projectHandle,"List[@Name='Map']",nodes,opt_node,0) ) {
            _str remoteRoot, localRoot;
            foreach( auto map_node in nodes ) {
               remoteRoot = "";
               localRoot = "";
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='RemoteRoot']",(int)map_node);
               if( node >=0  ) {
                  remoteRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               node = _xmlcfg_find_simple(projectHandle,"Item[@Name='LocalRoot']",(int)map_node);
               if( node >=0  ) {
                  localRoot = _xmlcfg_get_attribute(projectHandle,node,"Value","");
               }
               int i = remoteFileMap._length();
               remoteFileMap[i].remoteRoot = remoteRoot;
               remoteFileMap[i].localRoot = localRoot;
            }
         }

         // DBGp features
         node = _xmlcfg_find_simple(projectHandle,"Item[@Name='show_hidden']",opt_node);
         if( node >=0  ) {
            dbgp_features.show_hidden = ( 0 != _xmlcfg_get_attribute(projectHandle,node,"Value",(int)dbgp_features.show_hidden) );
         }
      }
   }
   rdbgp_opts.serverHost = serverHost;
   rdbgp_opts.serverPort = serverPort;
   rdbgp_opts.listenInBackground = listenInBackground;
   rdbgp_opts.remoteFileMap   = remoteFileMap;
   rdbgp_opts.dbgp_features = dbgp_features;
}

/**
 * Retrieve rdbgp options for all project configs.
 * 
 * @param projectHandle        Handle of project.
 * @param config               List of configurations to 
 *                             retrieve options for.
 * @param rdbgp_opts_list     (out) Hash table of project
 *                             rdbgp options indexed by config
 *                             name.
 * @param default_rdbgp_opts  Default options to use in case no 
 *                             options present for config.
 */
void rdbgp_project_get_options(int projectHandle, _str (&configList)[], RdbgpOptions (&rdbgp_opts_list):[], RdbgpOptions& default_rdbgp_opts=null)
{
   foreach( auto config in configList ) {
      RdbgpOptions opts;
      rdbgp_project_get_options_for_config(projectHandle,config,opts,default_rdbgp_opts);
      rdbgp_opts_list:[config] = opts;
   }
}

/**
 * Create a unique id that allows us to retrieve server 
 * connections and shut down servers opened for this project. 
 * 
 * @param projectName 
 * @param host 
 * @param port 
 * 
 * @return _str 
 */
static _str rdbgp_server_id(_str projectName, _str host, _str port)
{
   return se.debug.dbgp.proto_server_id("rdbgp",projectName,host,port);
}

/**
 * Test for a pending connection from rdbgp engine on 
 * host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return True if there is a connection pending.
 */
boolean rdbgp_is_pending(_str host, _str port)
{
   return se.debug.dbgp.proto_is_pending("rdbgp",host,port);
}

/**
 * Actively wait for a pending connection from rdbgp engine on 
 * host:port for timeout milliseconds. 
 *
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
int rdbgp_wait(_str host, _str port, int timeout, ServerConnectionObserver* observer, boolean close_on_error)
{
   return se.debug.dbgp.proto_wait("rdbgp",host,port,timeout,observer,close_on_error);
}

/**
 * Actively wait for a pending connection from rdbgp engine on 
 * host:port for timeout milliseconds. If connection is pending 
 * before timeout then connection is accepted and returned. 
 *
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
int rdbgp_wait_and_accept(_str host, _str port, int timeout, ServerConnectionObserver* observer, boolean close_if_first)
{
   return se.debug.dbgp.proto_wait_and_accept("rdbgp",host,port,timeout,observer,close_if_first);
}

/**
 * Passively watch for a pending connection from rdbgp engine 
 * on host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return 0 on success, <0 on error.
 */
int rdbgp_watch(_str host, _str port)
{
   return se.debug.dbgp.proto_watch("rdbgp",host,port,&g_RdbgpMonitor);
}

/**
 * Do we have a server provisioned and listening on host:port?
 * 
 * @param host  Host to test.
 * @param port  Port to test.
 * 
 * @return True if there is a server listening on host:port.
 */
boolean rdbgp_is_listening(_str host, _str port)
{
   return se.debug.dbgp.proto_is_listening("rdbgp",host,port);
}

/**
 * Retrieve the actual server host:port address that is 
 * listening. This is useful when the server was started with a 
 * port of 0 (dynamically assigned port). 
 * 
 * @param host  (in,out) Host to lookup/retrieve.
 * @param port  (in,out) Port to lookup/retrieve.
 * 
 * @return True if server exists and host, port are set to 
 *         address found. Note that the server can exist (is
 *         provisioned) but still not be listening. Use
 *         rdbgp_is_listening to test for a listening server.
 */
boolean rdbgp_get_server_address(_str& host, _str& port)
{
   return se.debug.dbgp.proto_get_server_address("rdbgp",host,port);
}

/**
 * Shut down the server listening on host:port.
 * 
 * @param host  Host identifying server to shutdown.
 * @param port  Port identifying server to shutdown.
 *
 * @return 0 on success, <0 on error.
 */
int rdbgp_shutdown(_str host, _str port)
{
   return se.debug.dbgp.proto_shutdown("rdbgp",host,port);
}

/**
 * Clear the last error for server listening on host:port.
 * 
 * @param host  Host identifying server to clear.
 * @param port  Port identifying server to clear.
 *
 * @return 0 on success, <0 on error.
 */
int rdbgp_clear_last_error(_str host, _str port)
{
   return se.debug.dbgp.proto_clear_last_error("rdbgp",host,port);
}

static int rdbgp_get_options(_str projectName, RdbgpOptions& rdbgp_opts)
{
   if( projectName != "" ) {
      // Pull rdbgp options from project
      rdbgp_project_get_options_for_config(_ProjectHandle(projectName),GetCurrentConfigName(projectName),rdbgp_opts);
   } else {
      // Prompt user for rdbgp server parameters
      // arg(2)=true : just retrieve host:port, do not start listening
      typeless status = show("-modal _debug_rdbgp_remote_form",true);
      if( status == "" ) {
         // User cancelled
         return COMMAND_CANCELLED_RC;
      }
      rdbgp_opts.serverHost = _param1;
      rdbgp_opts.serverPort = _param2;
   }

   // Sanity please
   if( rdbgp_opts.serverHost == null || rdbgp_opts.serverHost == "" ||
       rdbgp_opts.serverPort == null || rdbgp_opts.serverPort == "" ) {

      return INVALID_ARGUMENT_RC;
   }

   // All good
   return 0;
}

/**
 * Start passively listening for connection from rdbgp. If 
 * projectName!="" then rdbgp options are pulled from the 
 * project; otherwise the user is prompted for host:port 
 * settings. 
 * 
 * @param projectName              Name of project to pull 
 *                                 rdbgp options from. Defaults
 *                                 to current project name.
 * @param honorListenInBackground  If set to true, then the 
 *                                 ListenInBackground setting of
 *                                 the rdbgp options are
 *                                 checked. If the
 *                                 ListenInBackground setting is
 *                                 false, then listener is not
 *                                 started. Ignored if there is
 *                                 no current project. Defaults
 *                                 to false.
 * 
 * @return 0 on success, <0 on error.
 */
_command int rdbgp_project_watch(_str projectName=_project_name, boolean honorListenInBackground=false)
{
   if( honorListenInBackground && projectName == "" ) {
      // You have to have a project to honor the ListenInBackground options
      return 0;
   }
   RdbgpOptions rdbgp_opts;
   int status = rdbgp_get_options(projectName,rdbgp_opts);
   if( status != 0 ) {
      if( status != COMMAND_CANCELLED_RC ) {
         _str msg = "Invalid rdbgp host/port. Cannot listen for connection.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return status;
   }
   if( projectName != "" ) {
      if( honorListenInBackground && !rdbgp_opts.listenInBackground ) {
         // ListenInBackground is off, so bail
         return 0;
      }
   }

   int timeout = -1;

   // Passively listen for a connection from rdbgp
   _str id = rdbgp_server_id(projectName,rdbgp_opts.serverHost,rdbgp_opts.serverPort);
   ServerConnection* server = ServerConnectionPool.allocate(id);
   status = server->watch(rdbgp_opts.serverHost,rdbgp_opts.serverPort,timeout,&g_RdbgpMonitor);
   if( status != 0 ) {
      _str msg = nls("Failed to start rdbgp server on %s:%s. %s.",rdbgp_opts.serverHost,rdbgp_opts.serverPort,get_message(status));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return status;
}

/**
 * Shut down listener for rdbgp. 
 * 
 * @param projectName  Name of project to shut down rdbgp 
 *                     listener for. Defaults to current project
 *                     name.
 */
_command void rdbgp_project_shutdown(_str projectName=_project_name)
{
   _str id_found = null;
   _str prefix = "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':rdbgp:',true,id_found);
   while( server ) {
      server->shutdown();
      ServerConnectionPool.release(id_found);
      server = ServerConnectionPool.find(prefix':',true,id_found);
   }
}

namespace default;

using namespace se.debug.rdbgp;

void _init_menu_rdbgp(int menu_handle, int no_child_windows)
{
   int output_menu_handle = 0;
   int menu_pos = 0;

   // Verify that the menu item is not already there
   int status = _menu_find(menu_handle,'rdbgp_project_watch_toggle',output_menu_handle,menu_pos,'m');
   if( 0 == status ) {
      // Already there
      if( _project_DebugCallbackName != "rdbgp" ) {
         // Remove it if we do not have a server provisioned
         _str id_found = null;
         _str prefix = _parse_project_command("%rn","",_project_name,"");
         ServerConnection* server = ServerConnectionPool.find(prefix':rdbgp:',true,id_found);
         if( !server ) {
            // Delete the command
            _menu_delete(output_menu_handle,menu_pos);
            // Delete the separator
            _menu_delete(output_menu_handle,--menu_pos);
         }
      }
      return;
   }

   if( _project_DebugCallbackName != "rdbgp" ) {
      // Not a project that supports rdbgp
      return;
   }

   // Insert before separator following 'debug_restart' command
   status = _menu_find(menu_handle,'debug_restart',output_menu_handle,menu_pos,'m');
   if( status != 0 ) {
      // Try '-' instead of '_'
      status = _menu_find(menu_handle,'debug-restart',output_menu_handle,menu_pos,'m');
      if( status != 0 ) {
         // Not the menu we are waiting for
         return;
      }
   }
   // Walk down to the next separator
   int mf_flags;
   _str caption;
   while( true ) {
      status = _menu_get_state(output_menu_handle,++menu_pos,mf_flags,'p',caption);
      if( status < 0 ) {
         // Insert at end
         menu_pos = -1;
         break;
      }
      if( caption == "-" ) {
         // Found it
         break;
      }
   }

   // Insert command
   _menu_insert(output_menu_handle,menu_pos,MF_ENABLED,'&rdbgp Listen in Background','rdbgp_project_watch_toggle','','popup-imessage Toggle listening in background for rdbgp connection','Toggle listening in background for rdbgp connection');
   // Insert separator before command
   _menu_insert(output_menu_handle,menu_pos,0,'-');
}

int _OnUpdate_rdbgp_project_watch_toggle(CMDUI cmdui, int target_wid, _str command)
{
   _str id_found = null;
   _str prefix = "";
   if( _project_name != "" ) {
      prefix = _parse_project_command("%rn","",_project_name,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':rdbgp:',true,id_found);
   if( server ) {
      if( server->isListening() ) {
         return ( MF_CHECKED|MF_ENABLED );
      } else {
         return ( MF_UNCHECKED|MF_ENABLED );
      }
   } else {
      return ( MF_UNCHECKED|MF_ENABLED );
   }
}

_command void rdbgp_project_watch_toggle(_str projectName=_project_name)
{
   _str id_found = null;
   _str prefix = "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':rdbgp:',true,id_found);
   if( server ) {
      if( server->isListening() ) {
         // Toggle off
         rdbgp_project_shutdown(projectName);
      } else {
         // Toggle on
         if( projectName != "" ) {
            // Clear the existing entry in case the project rdbgp host:port
            // has changed.
            ServerConnectionPool.release(id_found);
            // New watch
            rdbgp_project_watch(projectName,false);
         } else {
            // There is no project associated with this server, so
            // use previous settings. This avoids having to re-prompt
            // the user for settings.
            _str host = server->getHost();
            _str port = server->getPort();
            server->watch(host,port,-1,&g_RdbgpMonitor);
         }
      }
   } else {
      // Toggle on
      rdbgp_project_watch(projectName,false);
   }
}

/**
 * Called when a project active config is changed. Shut down any
 * existing rdbgp servers for this project and start the server
 * for the active config. 
 */
void _prjconfig_rdbgp()
{
   // Case: Switching projects.
   // _prjconfig_* callbacks called between the close of the old project 
   // and the open of the new project. We cannot rely on 
   // _project_DebugCallbackName to be correct. Shutting down the old
   // project server will be taken care of in _project_close_* callback
   // in this case, so we are safe.
   //
   // Case: Switching configs inside same project.
   // The current project is not being closed, so we must make make sure the
   // server for the old config is shut down. _project_DebugCallbackName is
   // still not reliable in this case, so we have to query 'DebugCallbackName'
   // for the active config in this case.

   // Shut down servers from old active config
   rdbgp_project_shutdown(_project_name);

   // Start up servers for new active config.
   _str DebugCallbackName = _ProjectGet_DebugCallbackName(_ProjectHandle(_project_name));
   if( DebugCallbackName == "rdbgp" ) {
      rdbgp_project_watch(_project_name,true);
   }
}

/**
 * Called when a project is opened. Start up any rdbgp servers 
 * for this project. 
 */
void _prjopen_rdbgp()
{
   if( _project_DebugCallbackName != "rdbgp" ) {
      return;
   }

   // Register alert for server
   _RegisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   // Start up servers for active config
   rdbgp_project_watch(_project_name,true);
}

/**
 * Called when a project is closed. Shut down any rdbgp servers 
 * for this project. 
 *
 * @param projectName  Name of project being closed.
 */
void _project_close_rdbgp(_str projectName)
{
   if( _project_DebugCallbackName != "rdbgp" ) {
      return;
   }

   // Unregister alert for server
   _UnregisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   rdbgp_project_shutdown(projectName);
}
