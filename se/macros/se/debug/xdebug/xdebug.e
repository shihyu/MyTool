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
#require "se/debug/xdebug/xdebugprojutil.e"
#require "se/debug/xdebug/XdebugOptions.e"
#require "se/net/ServerConnection.e"
#require "se/net/ServerConnectionPool.e"
#require "se/net/ServerConnectionObserver.e"
#require "se/debug/xdebug/XdebugConnectionMonitor.e"
#require "se/net/ServerConnectionObserverFormInstance.e"
#import "compile.e"
#import "help.e"
#import "main.e"
#import "project.e"
#import "projconv.e"
#import "toast.e"
#import "wkspace.e"
#endregion

namespace se.debug.xdebug;

const XDEBUG_ATTACH_NOTE= '' :+
          '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">'        :+
          'When debugging PHP you will typically want to set up a PHP '      :+
          'project in order to take advantage of managed breakpoints, file ' :+
          'organization, and Context Tagging. '                              :+
          '</p>' :+
          '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">'           :+
          'This dialog allows you to initiate an Xdebug debugging session '     :+
          'in the absence of an active PHP project. This can be useful when:'   :+
          '<ul>'                                                                :+
          '<li>Your current project is not a PHP project, and </li>'            :+
          '<li>You want to step-into the first statement of a script, or '      :+
          '<li>You want to capture the stack from an unhandled exception, or '  :+
          '<li>You have inserted manual breaks into your PHP code '             :+
          '(e.g. ''xdebug_break'') which will break execution in the debugger.' :+
          '</ul>'                                                               :+
          '</p>' :+
          '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">'         :+
          'Otherwise you are better served by creating a PHP project.'        :+
          '</p>' :+
          '<p style="font-family:'VSDEFAULT_DIALOG_FONT_NAME'; font-size:10pt">'         :+
          'The PHP debugger uses the <a href="http://xdebug.org">Xdebug</a> ' :+
          'extension for PHP. Set the local host and port to the host:port '  :+
          'that Xdebug will attempt to connect to when initiating a debug '   :+
          'sesson. <a href="slickc:help Running and Debugging PHP">See the help ' :+
          'for more information about setting up debugging with Xdebug</a>.'  :+
          '</p>';

using se.net.ServerConnectionObserver;
using se.net.ServerConnectionObserverFormInstance;
using se.net.ServerConnection;
using se.net.ServerConnectionPool;
using se.debug.dbgp.dbgp_make_default_features;

static XdebugConnectionMonitor g_XdebugMonitor;

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
static _str xdebug_server_id(_str projectName, _str host, _str port)
{
   return se.debug.dbgp.proto_server_id("xdebug",projectName,host,port);
}

/**
 * Test for a pending connection from Xdebug engine on 
 * host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return True if there is a connection pending.
 */
bool xdebug_is_pending(_str host, _str port)
{
   return se.debug.dbgp.proto_is_pending("xdebug",host,port);
}

/**
 * Actively wait for a pending connection from Xdebug engine on 
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
int xdebug_wait(_str host, _str port, int timeout, ServerConnectionObserver* observer, bool close_on_error)
{
   return se.debug.dbgp.proto_wait("xdebug",host,port,timeout,observer,close_on_error);
}

/**
 * Actively wait for a pending connection from Xdebug engine on 
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
int xdebug_wait_and_accept(_str host, _str port, int timeout, ServerConnectionObserver* observer, bool close_if_first)
{
   return se.debug.dbgp.proto_wait_and_accept("xdebug",host,port,timeout,observer,close_if_first);
}

/**
 * Passively watch for a pending connection from Xdebug engine 
 * on host:port. 
 *
 * @param host     Host to wait on.
 * @param port     Port to wait on.
 * 
 * @return 0 on success, <0 on error.
 */
int xdebug_watch(_str host, _str port)
{
   if (!_haveDebugging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   return se.debug.dbgp.proto_watch("xdebug",host,port,&g_XdebugMonitor);
}

/**
 * Do we have a server provisioned and listening on host:port?
 * 
 * @param host  Host to test.
 * @param port  Port to test.
 * 
 * @return True if there is a server listening on host:port.
 */
bool xdebug_is_listening(_str host, _str port)
{
   return se.debug.dbgp.proto_is_listening("xdebug",host,port);
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
 *         xdebug_is_listening to test for a listening server.
 */
bool xdebug_get_server_address(_str& host, _str& port)
{
   return se.debug.dbgp.proto_get_server_address("xdebug",host,port);
}

/**
 * Shut down the server listening on host:port.
 * 
 * @param host  Host identifying server to shutdown.
 * @param port  Port identifying server to shutdown.
 *
 * @return 0 on success, <0 on error.
 */
int xdebug_shutdown(_str host, _str port)
{
   return se.debug.dbgp.proto_shutdown("xdebug",host,port);
}

/**
 * Clear the last error for server listening on host:port.
 * 
 * @param host  Host identifying server to clear.
 * @param port  Port identifying server to clear.
 *
 * @return 0 on success, <0 on error.
 */
int xdebug_clear_last_error(_str host, _str port)
{
   return se.debug.dbgp.proto_clear_last_error("xdebug",host,port);
}

static int xdebug_get_options(_str projectName, XdebugOptions& xdebug_opts)
{
   if( projectName != "" ) {
      // Pull Xdebug options from project
      xdebug_project_get_options_for_config(_ProjectHandle(projectName),GetCurrentConfigName(projectName),xdebug_opts);
   } else {
      // Prompt user for Xdebug server parameters
      // arg(2)=true : just retrieve host:port, do not start listening
      typeless status = show("-modal _debug_xdebug_remote_form",XDEBUG_ATTACH_NOTE,true);
      if( status == "" ) {
         // User cancelled
         return COMMAND_CANCELLED_RC;
      }
      xdebug_opts.serverHost = _param1;
      xdebug_opts.serverPort = _param2;
   }

   // Sanity please
   if( xdebug_opts.serverHost == null || xdebug_opts.serverHost == "" ||
       xdebug_opts.serverPort == null || xdebug_opts.serverPort == "" ) {

      return INVALID_ARGUMENT_RC;
   }

   // All good
   return 0;
}

/**
 * Start passively listening for connection from Xdebug. If 
 * projectName!="" then Xdebug options are pulled from the 
 * project; otherwise the user is prompted for host:port 
 * settings. 
 * 
 * @param projectName              Name of project to pull 
 *                                 Xdebug options from. Defaults
 *                                 to current project name.
 * @param honorListenInBackground  If set to true, then the 
 *                                 ListenInBackground setting of
 *                                 the Xdebug options are
 *                                 checked. If the
 *                                 ListenInBackground setting is
 *                                 false, then listener is not
 *                                 started. Ignored if there is
 *                                 no current project. Defaults
 *                                 to false.
 * 
 * @return 0 on success, <0 on error.
 */
_command int xdebug_project_watch(_str projectName=_project_name, bool honorListenInBackground=false) name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveDebugging()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Debugging");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if( honorListenInBackground && projectName == "" ) {
      // You have to have a project to honor the ListenInBackground options
      return 0;
   }
   XdebugOptions xdebug_opts;
   int status = xdebug_get_options(projectName,xdebug_opts);
   if( status != 0 ) {
      if( status != COMMAND_CANCELLED_RC ) {
         msg := "Invalid Xdebug host/port. Cannot listen for connection.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      }
      return status;
   }
   if( projectName != "" ) {
      if( honorListenInBackground && !xdebug_opts.listenInBackground ) {
         // ListenInBackground is off, so bail
         return 0;
      }
   }

   timeout := -1;

   // Passively listen for a connection from Xdebug
   _str id = xdebug_server_id(projectName,xdebug_opts.serverHost,xdebug_opts.serverPort);
   ServerConnection* server = ServerConnectionPool.allocate(id);
   status = server->watch(xdebug_opts.serverHost,xdebug_opts.serverPort,timeout,&g_XdebugMonitor);
   if( status != 0 ) {
      _str msg = nls("Failed to start Xdebug server on %s:%s. %s.",xdebug_opts.serverHost,xdebug_opts.serverPort,get_message(status));
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }
   return status;
}

/**
 * Shut down listener for Xdebug. 
 * 
 * @param projectName  Name of project to shut down Xdebug 
 *                     listener for. Defaults to current project
 *                     name.
 */
_command void xdebug_project_shutdown(_str projectName=_project_name) name_info(','VSARG2_REQUIRES_PRO_EDITION)
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
   ServerConnection* server = ServerConnectionPool.find(prefix':xdebug:',true,id_found);
   while( server ) {
      server->shutdown();
      ServerConnectionPool.release(id_found);
      server = ServerConnectionPool.find(prefix':',true,id_found);
   }
}

namespace default;

using namespace se.debug.xdebug;

void _init_menu_xdebug(int menu_handle, int no_child_windows)
{
   if (!_haveDebugging()) {
      return;
   }
   output_menu_handle := 0;
   menu_pos := 0;

   // Verify that the menu item is not already there
   int status = _menu_find(menu_handle,'xdebug_project_watch_toggle',output_menu_handle,menu_pos,'m');
   if( 0 == status ) {
      // Already there
      if( _project_DebugCallbackName != "xdebug" ) {
         // Remove it if we do not have a server provisioned
         _str id_found = null;
         _str prefix = _parse_project_command("%rn","",_project_name,"");
         ServerConnection* server = ServerConnectionPool.find(prefix':xdebug:',true,id_found);
         if( !server ) {
            // Delete the command
            _menu_delete(output_menu_handle,menu_pos);
            // Delete the separator
            _menu_delete(output_menu_handle,--menu_pos);
         }
      }
      return;
   }

   if( _project_DebugCallbackName != "xdebug" ) {
      // Not a project that supports Xdebug
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
   _menu_insert(output_menu_handle,menu_pos,MF_ENABLED,'&Xdebug Listen in Background','xdebug_project_watch_toggle','','popup-imessage Toggle listening in background for Xdebug connection','Toggle listening in background for Xdebug connection');
   // Insert separator before command
   _menu_insert(output_menu_handle,menu_pos,0,'-');
}

int _OnUpdate_xdebug_project_watch_toggle(CMDUI cmdui, int target_wid, _str command)
{
   if (!_haveDebugging()) {
      return MF_GRAYED|MF_REQUIRES_PRO;
   }
   _str id_found = null;
   prefix := "";
   if( _project_name != "" ) {
      prefix = _parse_project_command("%rn","",_project_name,"");
   }
   ServerConnection* server = ServerConnectionPool.find(prefix':xdebug:',true,id_found);
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

_command void xdebug_project_watch_toggle(_str projectName=_project_name) name_info(','VSARG2_REQUIRES_PRO_EDITION)
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
   ServerConnection* server = ServerConnectionPool.find(prefix':xdebug:',true,id_found);
   if( server ) {
      if( server->isListening() ) {
         // Toggle off
         xdebug_project_shutdown(projectName);
      } else {
         // Toggle on
         if( projectName != "" ) {
            // Clear the existing entry in case the project Xdebug host:port
            // has changed.
            ServerConnectionPool.release(id_found);
            // New watch
            xdebug_project_watch(projectName,false);
         } else {
            // There is no project associated with this server, so
            // use previous settings. This avoids having to re-prompt
            // the user for settings.
            _str host = server->getHost();
            _str port = server->getPort();
            server->watch(host,port,-1,&g_XdebugMonitor);
         }
      }
   } else {
      // Toggle on
      xdebug_project_watch(projectName,false);
   }
}

/**
 * Called when a project active config is changed. Shut down any
 * existing Xdebug servers for this project and start the server
 * for the active config. 
 */
void _prjconfig_xdebug()
{
   if (!_haveDebugging()) {
      return;
   }
   // Case: Switching projects.
   // _prjconfig_* callbacks called between the close of the old project 
   // and the open of the new project. We cannot rely on 
   // _project_DebugCallbackName to be correct. Shutting down the old
   // project server will be taken care of in _prjclose_* callback
   // in this case, so we are safe.
   //
   // Case: Switching configs inside same project.
   // The current project is not being closed, so we must make make sure the
   // server for the old config is shut down. _project_DebugCallbackName is
   // still not reliable in this case, so we have to query 'DebugCallbackName'
   // for the active config in this case.

   // Shut down servers from old active config
   xdebug_project_shutdown(_project_name);

   // Start up servers for new active config.
   // Be sure a project is open.  There is the invoked with directory case
   projectHandle := _ProjectHandle(_project_name);
   if ( projectHandle>=0 ) {
      DebugCallbackName := _ProjectGet_DebugCallbackName(projectHandle);
      if( DebugCallbackName == "xdebug" ) {
         xdebug_project_watch(_project_name,true);
      }
   }
}

/**
 * Called when a project is opened. Start up any Xdebug servers 
 * for this project. 
 */
void _prjopen_xdebug()
{
   if (!_haveDebugging()) {
      return;
   }
   if( _project_DebugCallbackName != "xdebug" ) {
      return;
   }

   // Register alert for server
   _RegisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   // Start up servers for active config
   xdebug_project_watch(_project_name,true);
}

/**
 * Called when a project is closed. Shut down any Xdebug servers 
 * for this project. 
 *
 * @param projectName  Name of project being closed.
 */
void _prjclose_xdebug()
{
   if (!_haveDebugging()) {
      return;
   }
   if( _project_DebugCallbackName != "xdebug" ) {
      return;
   }

   // Unregister alert for server
   _UnregisterAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS);

   xdebug_project_shutdown(_project_name);
}

/**
 * As far as we can tell Xdebug wants the message from the
 * exceptions and does not understand a class derived from the 
 * PHP Exception class, so (for now) we return a hard coded list
 * of well-known exception messages. 
 */
void dbg_xdebug_list_exceptions(_str (&exception_list)[])
{
   exception_list[exception_list._length()] = "Fatal error";
   exception_list[exception_list._length()] = "Parse error";
   exception_list[exception_list._length()] = "Unknown error";
}
