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
#require "se/debug/dbgp/dbgp.e"
#require "se/debug/dbgp/DBGpOptions.e"
#require "se/debug/pydbgp/pydbgputil.e"
#require "se/debug/pydbgp/PydbgpConnectionMonitor.e"
#require "se/net/ServerConnection.e"
#require "se/net/ServerConnectionPool.e"
#require "se/net/ServerConnectionObserver.e"
#require "se/net/ServerConnectionObserverFormInstance.e"
#import "compile.e"
#import "debug.e"
#import "help.e"
#import "main.e"
#import "mprompt.e"
#import "project.e"
#import "projconv.e"
#import "stdprocs.e"
#import "toast.e"
#import "wkspace.e"
#endregion

namespace se.debug.pydbgp;

using se.net.ServerConnectionObserver;
using se.net.ServerConnectionObserverFormInstance;
using se.net.ServerConnection;
using se.net.ServerConnectionPool;

static PydbgpConnectionMonitor g_PydbgpMonitor;

using se.debug.dbgp.dbgp_make_default_features;
using se.debug.dbgp.DBGpOptions;
using se.debug.dbgp.DBGpRemoteFileMapping;

DBGpOptions pydbgp_make_default_options(DBGpOptions& pydbgp_opts=null)
{
   pydbgp_opts.serverHost = "127.0.0.1";
   pydbgp_opts.serverPort = "9000";
   pydbgp_opts.listenInBackground = true;
   pydbgp_opts.remoteFileMap = null;
   se.debug.dbgp.dbgp_make_default_features(pydbgp_opts.dbgp_features);
   // Python debugging is just too ugly when show_hidden=1 (all those __varname__ variables)
   pydbgp_opts.dbgp_features.show_hidden = false;
   return pydbgp_opts;
}

/**
 * Retrieve pydbgp options for project and config.
 * 
 * @param projectHandle        Handle of project.
 * @param config               Configuration to retrieve options 
 *                             for.
 * @param pydbgp_opts          (out) Set to project pydbgp 
 *                             options.
 * @param default_pydbgp_opts  Default options to use in case no
 *                             options present for config.
 */
void pydbgp_project_get_options_for_config(int projectHandle, _str config, DBGpOptions& pydbgp_opts, DBGpOptions& default_pydbgp_opts=null)
{
   if( default_pydbgp_opts == null ) {
      pydbgp_make_default_options(default_pydbgp_opts);
   }
   _str serverHost = default_pydbgp_opts.serverHost;
   _str serverPort = default_pydbgp_opts.serverPort;
   listenInBackground := default_pydbgp_opts.listenInBackground;
   DBGpRemoteFileMapping remoteFileMap[] = default_pydbgp_opts.remoteFileMap;
   se.debug.dbgp.DBGpFeatures dbgp_features = default_pydbgp_opts.dbgp_features;

   int node = _ProjectGet_ConfigNode(projectHandle,config);
   if( node >= 0 ) {
      int opt_node = _xmlcfg_find_simple(projectHandle,"List[@Name='pydbgp Options']",node);
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
               i := remoteFileMap._length();
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
   pydbgp_opts.serverHost = serverHost;
   pydbgp_opts.serverPort = serverPort;
   pydbgp_opts.listenInBackground = listenInBackground;
   pydbgp_opts.remoteFileMap   = remoteFileMap;
   pydbgp_opts.dbgp_features = dbgp_features;
}

/**
 * Retrieve pydbgp options for all project configs.
 * 
 * @param projectHandle        Handle of project.
 * @param config               List of configurations to 
 *                             retrieve options for.
 * @param pydbgp_opts_list     (out) Hash table of project
 *                             pydbgp options indexed by config
 *                             name.
 * @param default_pydbgp_opts  Default options to use in case no 
 *                             options present for config.
 */
void pydbgp_project_get_options(int projectHandle, _str (&configList)[], DBGpOptions (&pydbgp_opts_list):[], DBGpOptions& default_pydbgp_opts=null)
{
   foreach( auto config in configList ) {
      DBGpOptions opts;
      pydbgp_project_get_options_for_config(projectHandle,config,opts,default_pydbgp_opts);
      pydbgp_opts_list:[config] = opts;
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
static _str pydbgp_server_id(_str projectName, _str host, _str port)
{
   return se.debug.dbgp.proto_server_id("pydbgp",projectName,host,port);
}

/**
 * Test for a pending connection from pydbgp engine on 
 * host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return True if there is a connection pending.
 */
bool pydbgp_is_pending(_str host, _str port)
{
   return se.debug.dbgp.proto_is_pending("pydbgp",host,port);
}

/**
 * Actively wait for a pending connection from pydbgp engine on 
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
int pydbgp_wait(_str host, _str port, int timeout, ServerConnectionObserver* observer, bool close_on_error)
{
   return se.debug.dbgp.proto_wait("pydbgp",host,port,timeout,observer,close_on_error);
}

/**
 * Actively wait for a pending connection from pydbgp engine on 
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
int pydbgp_wait_and_accept(_str host, _str port, int timeout, ServerConnectionObserver* observer, bool close_if_first)
{
   return se.debug.dbgp.proto_wait_and_accept("pydbgp",host,port,timeout,observer,close_if_first);
}

/**
 * Passively watch for a pending connection from pydbgp engine 
 * on host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return 0 on success, <0 on error.
 */
int pydbgp_watch(_str host, _str port)
{
   return se.debug.dbgp.proto_watch("pydbgp",host,port,&g_PydbgpMonitor);
}

/**
 * Do we have a server provisioned and listening on host:port?
 * 
 * @param host  Host to test.
 * @param port  Port to test.
 * 
 * @return True if there is a server listening on host:port.
 */
bool pydbgp_is_listening(_str host, _str port)
{
   return se.debug.dbgp.proto_is_listening("pydbgp",host,port);
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
 *         pydbgp_is_listening to test for a listening server.
 */
bool pydbgp_get_server_address(_str& host, _str& port)
{
   return se.debug.dbgp.proto_get_server_address("pydbgp",host,port);
}

/**
 * Shut down the server listening on host:port.
 * 
 * @param host  Host identifying server to shutdown.
 * @param port  Port identifying server to shutdown.
 *
 * @return 0 on success, <0 on error.
 */
int pydbgp_shutdown(_str host, _str port)
{
   return se.debug.dbgp.proto_shutdown("pydbgp",host,port);
}

/**
 * Clear the last error for server listening on host:port.
 * 
 * @param host  Host identifying server to clear.
 * @param port  Port identifying server to clear.
 *
 * @return 0 on success, <0 on error.
 */
int pydbgp_clear_last_error(_str host, _str port)
{
   return se.debug.dbgp.proto_clear_last_error("pydbgp",host,port);
}

static int pydbgp_get_options(_str projectName, DBGpOptions& pydbgp_opts)
{
   if( projectName != "" ) {
      // Pull pydbgp options from project
      pydbgp_project_get_options_for_config(_ProjectHandle(projectName),GetCurrentConfigName(projectName),pydbgp_opts);
   } else {
      // Prompt user for pydbgp server parameters
      // arg(2)=true : just retrieve host:port, do not start listening
      typeless status = show("-modal _debug_pydbgp_remote_form",true);
      if( status == "" ) {
         // User cancelled
         return COMMAND_CANCELLED_RC;
      }
      pydbgp_opts.serverHost = _param1;
      pydbgp_opts.serverPort = _param2;
   }

   // Sanity please
   if( pydbgp_opts.serverHost == null || pydbgp_opts.serverHost == "" ||
       pydbgp_opts.serverPort == null || pydbgp_opts.serverPort == "" ) {

      return INVALID_ARGUMENT_RC;
   }

   // All good
   return 0;
}

/**
 * Start passively listening for connection from pydbgp. If 
 * projectName!="" then pydbgp options are pulled from the 
 * project; otherwise the user is prompted for host:port 
 * settings. 
 * 
 * @param projectName              Name of project to pull 
 *                                 pydbgp options from. Defaults
 *                                 to current project name.
 * @param honorListenInBackground  If set to true, then the 
 *                                 ListenInBackground setting of
 *                                 the pydbgp options are
 *                                 checked. If the
 *                                 ListenInBackground setting is
 *                                 false, then listener is not
 *                                 started. Ignored if there is
 *                                 no current project. Defaults
 *                                 to false.
 * 
 * @return 0 on success, <0 on error.
 */
_command int pydbgp_project_watch(_str projectName=_project_name, bool honorListenInBackground=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( honorListenInBackground && projectName == "" ) {
      // You have to have a project to honor the ListenInBackground options
      return 0;
   }
   DBGpOptions pydbgp_opts;
   int status = pydbgp_get_options(projectName,pydbgp_opts);
   if( status != 0 ) {
      if( status != COMMAND_CANCELLED_RC ) {
         msg := "Invalid pydbgp host/port. Cannot listen for connection.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return status;
   }
   if( projectName != "" ) {
      if( honorListenInBackground && !pydbgp_opts.listenInBackground ) {
         // ListenInBackground is off, so bail
         return 0;
      }
   }

   timeout := -1;

   // Passively listen for a connection from pydbgp
   _str id = pydbgp_server_id(projectName,pydbgp_opts.serverHost,pydbgp_opts.serverPort);
   ServerConnection* server = ServerConnectionPool.allocate(id);
   g_PydbgpMonitor.setCb('pydbgp');
   status = server->watch(pydbgp_opts.serverHost,pydbgp_opts.serverPort,timeout,&g_PydbgpMonitor);
   if( status != 0 ) {
      _str msg = nls("Failed to start pydbgp server on %s:%s. %s.",pydbgp_opts.serverHost,pydbgp_opts.serverPort,get_message(status));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return status;
}

// Generic listener shutdown based on debug callback name.
void dbgp_project_shutdown(_str cbName, _str projectName=_project_name) 
{
   if (!_haveDebugging()) {
      return;
   }
   _str id_found = null;
   prefix := "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':'cbName':',true,id_found);
   while( server ) {
      server->shutdown();
      ServerConnectionPool.release(id_found);
      server = ServerConnectionPool.find(prefix':',true,id_found);
   }
}
/**
 * Shut down listener for pydbgp. 
 * 
 * @param projectName  Name of project to shut down pydbgp 
 *                     listener for. Defaults to current project
 *                     name.
 */
_command void pydbgp_project_shutdown(_str projectName=_project_name) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   dbgp_project_shutdown('pydbgp', projectName);
}

namespace default;

using namespace se.debug.pydbgp;

void _init_menu_pydbgp(int menu_handle, int no_child_windows)
{
   output_menu_handle := 0;
   menu_pos := 0;

   // Verify that the menu item is not already there
   int status = _menu_find(menu_handle,'pydbgp_project_watch_toggle',output_menu_handle,menu_pos,'m');
   if( 0 == status ) {
      // Already there
      if( _project_DebugCallbackName != "pydbgp" ) {
         // Remove it if we do not have a server provisioned
         _str id_found = null;
         _str prefix = _parse_project_command("%rn","",_project_name,"");
         ServerConnection* server = ServerConnectionPool.find(prefix':pydbgp:',true,id_found);
         if( !server ) {
            // Delete the command
            _menu_delete(output_menu_handle,menu_pos);
            // Delete the separator
            _menu_delete(output_menu_handle,--menu_pos);
         }
      }
      return;
   }

   if( _project_DebugCallbackName != "pydbgp" ) {
      // Not a project that supports pydbgp
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
   _menu_insert(output_menu_handle,menu_pos,MF_ENABLED,'&pydbgp Listen in Background','pydbgp_project_watch_toggle','','popup-imessage Toggle listening in background for pydbgp connection','Toggle listening in background for pydbgp connection');
   // Insert separator before command
   _menu_insert(output_menu_handle,menu_pos,0,'-');
}

int _OnUpdate_pydbgp_project_watch_toggle(CMDUI cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      return MF_GRAYED|MF_REQUIRES_PRO;
   }

   _str id_found = null;
   prefix := "";
   if( _project_name != "" ) {
      prefix = _parse_project_command("%rn","",_project_name,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':pydbgp:',true,id_found);
   if( server ) {
      if( server->isListening() ) {
         return ( MF_CHECKED|MF_ENABLED );
      } else {
         return ( MF_UNCHECKED|MF_ENABLED );
      }
   } else {
      return ( MF_UNCHECKED|MF_ENABLED );
   }
   return(MF_ENABLED);
}

_command void pydbgp_project_watch_toggle(_str projectName=_project_name) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return;
   }
   _str id_found = null;
   prefix := "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':pydbgp:',true,id_found);
   if( server ) {
      if( server->isListening() ) {
         // Toggle off
         pydbgp_project_shutdown(projectName);
      } else {
         // Toggle on
         if( projectName != "" ) {
            // Clear the existing entry in case the project pydbgp host:port
            // has changed.
            ServerConnectionPool.release(id_found);
            // New watch
            pydbgp_project_watch(projectName,false);
         } else {
            // There is no project associated with this server, so
            // use previous settings. This avoids having to re-prompt
            // the user for settings.
            _str host = server->getHost();
            _str port = server->getPort();
            server->watch(host,port,-1,&g_PydbgpMonitor);
         }
      }
   } else {
      // Toggle on
      pydbgp_project_watch(projectName,false);
   }
}

bool pydbgp_server_project_is_listening(_str projectName)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return false;
   }
   _str id_found = null;
   prefix := "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':pydbgp:',true,id_found);
   if (server && server->isListening()) {
      return true;
   }
   return false;
}

bool dbgp_server_is_listening(_str projectName, _str callbackName, _str& host, _str& port)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return false;
   }
   _str id_found = null;
   prefix := "";
   if( projectName != "" ) {
      prefix = _parse_project_command("%rn","",projectName,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':'callbackName':',true,id_found);
   if (server && server->isListening()) {
      host = server->getHost();
      port = server->getPort();
      return true;
   }
   return false;
}

bool pydbgp_server_is_listening(_str projectName, _str& host, _str& port)
{
   return dbgp_server_is_listening(projectName, 'pydbgp', host, port);
}


