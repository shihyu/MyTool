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
namespace se.debug.dbgp;

struct DBGpFeatures {
   // show_hidden feature: 1=show hidden/private variables
   bool show_hidden;
   // How many children to grab from array/hash at once
   int max_children;
};

struct DBGpRemoteFileMapping {
   // Example: /var/www/cgi-bin/
   _str remoteRoot;
   // Example: c:\inetpub\wwwroot\cgi\
   _str localRoot;
};

struct DBGpOptions {
   // Local host to listen on for connection from.
   _str serverHost;
   // Local port to listen on for connection from.
   _str serverPort;
   // Start listening in background for an dbgp connection when project is opened
   bool listenInBackground;
   // remote-root<=>local-root file mappings
   DBGpRemoteFileMapping remoteFileMap[];
   // DBGp features
   se.debug.dbgp.DBGpFeatures dbgp_features;
};
