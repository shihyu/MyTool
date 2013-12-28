////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48511 $
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
#ifndef PERFORCE_SH
#define PERFORCE_SH

#if __UNIX__
   #define P4_EXE_NAME "p4"
#else
   #define P4_EXE_NAME "p4.exe"
#endif 

#define P4_NO_FILES_OPENED    "File(s) not opened for edit."
#define P4_FILES_NOT_OPENED   "file(s) not opened on this client."
#define P4_UP_TO_DATE_MESSAGE "File(s) up-to-date."

struct PERFORCE_SETUP_INFO {
   _str p4_exe_name;
   boolean userSpecifiesChangeNumber;
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
PERFORCE_SETUP_INFO def_perforce_info=null;

#endif
