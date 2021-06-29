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
#include "vsockapi.sh"
#require "se/net/IServerConnection.e"
#require "se/net/ServerConnectionObserver.e"
#import "se/debug/xdebug/xdebugutil.e"
#import "se/debug/xdebug/xdebugprojutil.e"
#import "compile.e"
#import "debug.e"
#import "main.e"
#import "stdprocs.e"
#import "mprompt.e"
#import "wkspace.e"
#import "project.e"
#import "toast.e"
#endregion

namespace se.debug.xdebug;

using se.net.ServerConnectionObserver;
using se.net.IServerConnection;

/**
 * Observe server for pending connection. Start debugging when
 * pending connection becomes available.
 */
class XdebugConnectionMonitor : ServerConnectionObserver {

   private bool m_started = false;
   private _str m_message = '';

   /**
    * Constructor.
    */
   XdebugConnectionMonitor() {
      this.start();
   }

   /**
    * Destructor.
    */
   ~XdebugConnectionMonitor() {
      this.stop();
   }

   private void onStatusListen(IServerConnection* server) {
      if( debug_active() ) {
         // Do not bother user if we are already debugging
         return;
      }
      _str host = server->getHost(true);
      _str port = server->getPort(true);
      _str msg = nls("Listening for Xdebug connection on %s:%s...",host,port);
      if( msg != m_message ) {
         // A change in listening status, so update the alert
         m_message = msg;
         _ActivateAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS,ALERT_STARTED,m_message, '', 0);
      }
   }

   private void onStatusPending(IServerConnection* server) {

      if (!_haveDebugging()) {
         return;
      }
      if( xdebug_almost_active() ) {
         // We do not want to attempt to start debugging while in the
         // middle of starting debugging.
         //say('onStatusPending: BAILING!');
         return;
      }

      // A process wants to initiate a debug session. Should we let it?

      // Default to not accepting new connection
      accept := false;
      // Check project for user's wishes
      _str accept_connections = xdebug_project_get_option("AcceptConnections",'prompt');
      if( accept_connections == 'prompt' ) {
         // User wants to be prompted
         xdebug_almost_active(1);
         caption1 := "Another process is attempting to initiate a debug session.";
         caption2 := "Allow?";
         int result = textBoxDialog("Debug connection requested",
                                    0,
                                    0,
                                    "",
                                    nls("Yes,No\t-html %s\n-html %s",caption1,caption2),
                                    "",
                                    '-checkbox Do not ask me again:0');
         xdebug_almost_active(0);
         if( result == 1 ) {
            // Always accept new connections
            accept = true;
         } else if( result == 2 ) {
            // Never accept new connections
            accept = false;
         } else {
            // ???
            // Make sure we do not save whatever this is
            _param1 = 0;
         }
         if( _param1 != 0 ) {
            // User does not want to be asked again
            if( accept ) {
               // Always accept new connections
               xdebug_project_set_option('AcceptConnections','always');
            } else {
               // Never accept new connections
               xdebug_project_set_option('AcceptConnections','never');
            }
         }
      } else {
         accept = (accept_connections == 'always');
      }
      if( !accept ) {
         // Do not accept the connection
         // Accept and close
         int socket = server->accept();
         if( socket >=0  ) {
            vssSocketClose(socket);
         }
         return;
      }
      // Fall through to starting a new session

      sticky_message("Xdebug connection pending. Starting debugger...");
      // Start debugging
      if( !debug_active() && _project_DebugCallbackName == "xdebug" ) {
         xdebug_almost_active(1);
         int status = project_debug();
         xdebug_almost_active(0);
         if( status != 0 ) {
            // Aborted
            // Accept and close
            int socket = server->accept();
            if( socket >=0  ) {
               vssSocketClose(socket);
            }
         }
      } else {
         // Additional session or non-project-based debugging
         int socket = server->accept();
         if( socket < 0 ) {
            // Error
            _str msg = nls("Failed to accept an Xdebug connection. %s",socket);
            sticky_message(msg);
            // Shut down everything on error
            server->shutdown();
            return;
         }

         // Peek for the <init> packet so we can give this session a good name
         int handle = xdebug_peek_packet(socket);
         if( handle < 0 ) {
            // Error
            _str msg = nls("Could not parse <init> packet. %s",handle);
            sticky_message(msg);
            server->shutdown();
            vssSocketClose(socket);
            return;
         }
         int node = _xmlcfg_find_simple(handle,"/init");
         // <init ... fileuri="file:///C:/inetpub/wwwroot/index.php" ...>...</init>
         _str fileuri = _xmlcfg_get_attribute(handle,node,"fileuri","UNKNOWN");
         _xmlcfg_close(handle);

         if( debug_active() ) {
            session_id := dbg_get_current_session();
            if( session_id > 0 && dbg_get_callback_name(session_id) == "xdebug" ) {
               // Add this connection as a new DBGp session in the current debug session

               cmdline := "";
               reply := "";
               err_msg := "";

               cmdline = '-add-dbgp-session -socket='socket;

               // Do we step-into the first line of script or run to first breakpoint?
               break_in_session := "step-into";
               // Remote-to-local file mappings for this DBGp session
               map_args := "";
               if( _project_DebugCallbackName == "xdebug" ) {
                  // The current project is Xdebug, so use its settings
                  XdebugOptions xdebug_opts;
                  xdebug_project_get_options_for_config(_ProjectHandle(_project_name),GetCurrentConfigName(_project_name),xdebug_opts);
                  break_in_session = xdebug_opts.breakInSession;
                  XdebugRemoteFileMapping map;
                  foreach( map in xdebug_opts.remoteFileMap ) {
                     if( map.remoteRoot != "" && map.localRoot != "" ) {
                        map_args :+= ' -map='map.remoteRoot':::'map.localRoot;
                     }
                  }
               } else {
                  // Use default Xdebug settings
                  break_in_session = xdebug_make_default_options().breakInSession;
               }
               // File mappings
               if( map_args != '' ) {
                  cmdline :+= ' 'map_args;
               }
               // 'run' or 'step-into'
               if( break_in_session == 'run' ) {
                  cmdline :+= ' -run';
               } else {
                  cmdline :+= ' -step-into';
               }

               int status = dbg_session_do_command(session_id,cmdline,reply,err_msg,false);
               //say('onStatusPending: status='status'  cmdline='cmdline);
               if( status != 0 ) {
                  // Error
                  vssSocketClose(socket);
                  _str msg = nls("Failed to attach to Xdebug connection. %s\n\nThe listener will be stopped.",get_message(status));
                  // Complain loudly
                  _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
                  // Shut down everything on error
                  server->shutdown();
               }
               return;
            }
         }
         // Fall through to starting a new session

         //say('onStatusPending: fileuri='fileuri);
         _str attach_info = 'file='fileuri',,path=,args=-socket='socket' -step-into';
         xdebug_almost_active(1);
         int status = debug_remote("xdebug",attach_info);
         xdebug_almost_active(0);
         if( status != 0 ) {
            // Error
            server->shutdown();
            vssSocketClose(socket);
            return;
         }
      }
   }

   private void onStatusError(IServerConnection* server) {

      if( debug_active() ) {
         return;
      }
      
      int error_rc = server->getError();
      
      // Shut down everything on error
      server->shutdown();

      msg :=  "Error waiting for Xdebug connection: ":+get_message(error_rc);
      
      // Complain loudly
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }

   public int start() {
      m_started = true;
      m_message = '';
      return 0;
   }

   public void stop() {
      _DeactivateAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS,ALERT_STARTED,'Not listening', '', 0);
      m_started = false;
      m_message = '';
   }

   public bool isStarted() {
      return m_started;
   }

};
