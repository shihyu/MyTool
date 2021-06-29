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
#import "se/debug/rdbgp/rdbgputil.e"
#import "compile.e"
#import "debug.e"
#import "main.e"
#import "stdprocs.e"
#import "toast.e"
#endregion

namespace se.debug.rdbgp;

using se.net.ServerConnectionObserver;
using se.net.IServerConnection;

/**
 * Observe server for pending connection. Start debugging when
 * pending connection becomes available.
 */
class RdbgpConnectionMonitor : ServerConnectionObserver {

   private bool m_started = false;
   private _str m_message = '';

   /**
    * Constructor.
    */
   RdbgpConnectionMonitor() {
      this.start();
   }

   /**
    * Destructor.
    */
   ~RdbgpConnectionMonitor() {
      this.stop();
   }

   private void onStatusListen(IServerConnection* server) {
      if( debug_active() ) {
         // Do not bother user if we are already debugging
         return;
      }
      _str host = server->getHost(true);
      _str port = server->getPort(true);
      _str msg = nls("Listening for rdbgp connection on %s:%s...",host,port);
      if( msg != m_message ) {
         // A change in listening status, so update the alert
         m_message = msg;
         _ActivateAlert(ALERT_GRP_DEBUG_LISTENER_ALERTS,ALERT_STARTED,m_message, '', 0);
      }
   }

   private void onStatusPending(IServerConnection* server) {

      if( rdbgp_almost_active() ) {
         // We do not want to attempt to start debugging while in the
         // middle of starting debugging.
         //say('onStatusPending: BAILING!');
         return;
      }

      if( debug_active() ) {
         // Already debugging and another process/thread wants to
         // initiate a debug session. Should we let it?
         msg := "Another process/thread is attempting to initiate a debug session.\n\nAllow?";
         int status = _message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
         if( status != IDYES ) {
            // Accept and close
            int socket = server->accept();
            if( socket >=0  ) {
               vssSocketClose(socket);
            }
            return;
         }
         // Fall through to starting a new session
      }
      sticky_message("rdbgp connection pending. Starting debugger...");
      // Start debugging
      if( !debug_active() && _project_DebugCallbackName == "rdbgp" ) {
         rdbgp_almost_active(1);
         int status = project_debug();
         rdbgp_almost_active(0);
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
            _str msg = nls("Failed to accept an rdbgp connection. %s",socket);
            sticky_message(msg);
            // Shut down everything on error
            server->shutdown();
            return;
         }

         // Peek for the <init> packet so we can give this session a good name
         int handle = rdbgp_peek_packet(socket);
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

         //say('onStatusPending: fileuri='fileuri);
         _str attach_info = 'file='fileuri',,path=,args=-socket='socket' -step-into';
         rdbgp_almost_active(1);
         int status = debug_remote("rdbgp",attach_info);
         rdbgp_almost_active(0);
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
      
      msg :=  "Error waiting for rdbgp connection: ":+get_message(error_rc);

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
