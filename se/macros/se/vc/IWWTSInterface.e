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
#import "WWTSLine.e"
#import "WWTSFile.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

interface IWWTSInterface {
   /**
    * Get already retrieved and processed data from the version 
    * control system.  Return -1 if this data is not available.
    */
   int getData(_str filename,WWTSFile &fileInfo);

   /**
    * Retrieve data for <B>filename</B> from the version control 
    * system. This split allows for the retrieveData method to 
    * start a thread and save data as long as it does not call any 
    * VSAPI function that are not threadsafe. 
    */
   int retrieveData(_str filename);

   /**
    * Process data retrieved previously.  This function has to move 
    * data into Slick-C and therefore cannot be threaded 
    */
   int processData(_str filename);
};
