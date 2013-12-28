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
#pragma options(pedantic,on)
#include "se/debug/dbgp/DBGpOptions.e"

namespace se.debug.xdebug;

struct XdebugRemoteFileMapping {
   // Example: /var/www/html/
   _str remoteRoot;
   // Example: c:\inetpub\wwwroot\
   _str localRoot;
};

struct XdebugOptions {
   // Local host to listen on for connection from Xdebug
   _str serverHost;
   // Local port to listen on for connection from Xdebug
   _str serverPort;
   // Start listening in background for an Xdebug connection when project is opened
   boolean listenInBackground;
   // true=do not exit debug mode when last session terminates
   boolean stayInDebugger;
   // What to do when a debugger connection attempt is made:
   // 'prompt' user to accept
   // 'always' accept
   // 'never' accept
   _str acceptConnections;
   // What to do when break into a new debugger session:
   // 'step-into' first line of script
   // 'run' to first breakpoint
   _str breakInSession;
   // remote-root<=>local-root file mappings
   XdebugRemoteFileMapping remoteFileMap[];
   // DBGp features
   se.debug.dbgp.DBGpFeatures dbgp_features;
};
