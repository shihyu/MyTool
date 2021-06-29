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
#pragma option(metadata,"svc.e")

struct PERFORCE_OTHER_INFO {
   // This is really a boolean field, but there is a case where it can end
   // up null and keep vusrdefs.e from compiling can keep ppl's configuration
   // from transferring.  For that reason, we have changed it to typeless.
   typeless userSpecifiesChangeNumber;
   _str userName;
   _str clientName;
   _str clientHost;
   _str clientRoot;
   _str currentDirectory;
   _str peerAddress;
   _str clientAddress;
   _str serverAddress;
   _str serverRoot;
   _str serverDate;
   _str serverUptTime;
   _str serverVersion;
   _str serverLicense;
   _str caseHandling;
   _str clientVersion;
};

PERFORCE_OTHER_INFO _perforce_info=null;


_str def_perforce_exe_path;
_str _perforce_cached_exe_path;


