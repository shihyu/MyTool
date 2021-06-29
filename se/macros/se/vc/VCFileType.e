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
#include "cvs.sh"
#import "stdprocs.e"
#import "main.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class VCFileType {
   _str m_filename;
   VCFileType(_str filename="") {
      m_filename = filename;
   }

   private static bool isCVSFIle(_str filename) {
      curFileIssCVSFile := false; 
      do {
         path := _file_path(filename);
   
         // Look to see if this is a CVS file
         CVSPath := path:+CVS_CHILD_DIR_NAME;
         _maybe_append_filesep(CVSPath);
         
         EntriesFilename := CVSPath:+CVS_ENTRIES_FILENAME;
         status := _open_temp_view(EntriesFilename,auto temp_wid,auto orig_wid);
         if ( status ) break;
         top();up();
         justFilename := _strip_filename(filename,'P');
         status = search("^/":+justFilename:+"/","@r");
         foundFile := !status;
         p_window_id = orig_wid;
         _delete_temp_view(temp_wid);
         if ( foundFile ) {
            curFileIssCVSFile = true;
         }
      } while ( false );
      return curFileIssCVSFile;
   }

   /**
    * Get the file type for <B>m_filename</B>
    * 
    * @return version control system for this file, name will
    *         always be lowcased
    */
   _str getVCType() {
      VCType := "";
      do {
         if ( isCVSFIle(m_filename) ) {
            VCType = "cvs";
            break;
         }
      } while ( false );
      return VCType;
   }
}
