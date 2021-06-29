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
#endregion

// CMFileInfo contains all information regarding the file and/or
// data set given by ChangeMan via cmedit().
struct CMFileInfo
{
   _str filename; // file or data set name
   int exitCode;  // Flag: 1=nothing changed & don't need save changes, 0=file modified & need to check in changes
   _str semFile;  // semaphore file
};
static CMFileInfo cmfiles[];
static int cmDebugState = 0; // Flag: 1=debug on; 0=off

int gexit_code;

definit()
{
   cmfiles._makeempty();
   cmDebugState = 0;
}

