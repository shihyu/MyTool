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
#region Imports
#import "WWTSLine.e"
#import "WWTSFile.e"
#import "stdprocs.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSModel {
   static private WWTSFile s_fileModel:[]=null; 
   WWTSModel() {
   }

   static public WWTSFile getFile(_str filename) {
      return s_fileModel:[_file_case(filename)];
   }
   static public void setFile(_str filename,WWTSFile file) {
      s_fileModel:[_file_case(filename)] = file;
   }
   static public void removeFile(_str filename) {
      s_fileModel:[_file_case(filename)] = null;
   }
   static public void removeAllFiles() {
      s_fileModel = null;
   }
};
