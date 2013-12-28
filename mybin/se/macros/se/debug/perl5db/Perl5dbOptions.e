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
#pragma option(pedantic,on)
#include "se/debug/dbgp/DBGpOptions.e"

namespace se.debug.perl5db;

struct Perl5dbRemoteFileMapping {
   // Example: /var/www/cgi-bin/
   _str remoteRoot;
   // Example: c:\inetpub\wwwroot\cgi\
   _str localRoot;
};

struct Perl5dbOptions {
   // Local host to listen on for connection from perl5db
   _str serverHost;
   // Local port to listen on for connection from perl5db
   _str serverPort;
   // Start listening in background for an perl5db connection when project is opened
   boolean listenInBackground;
   // remote-root<=>local-root file mappings
   Perl5dbRemoteFileMapping remoteFileMap[];
   // DBGp features
   se.debug.dbgp.DBGpFeatures dbgp_features;
};
