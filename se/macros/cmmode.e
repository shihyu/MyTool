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
#import "stdprocs.e"
#import "stdcmds.e"
#endregion

// User-defined file mode select callback.
// Whenever _SetEditorLanguage() is called, this function is
// called. Retn: 0 successful override
//       1 nothing done, continue to use the default actions in _SetEditorLanguage()
int userSelectEditorLanguage(_str origLang, bool origBypassBufferSetup)
{
   // For data sets only.
   if (_DataSetIsFile(p_buf_name)) {
      // If the lowest qualifier begins with "COBOL", switch the
      // file mode to COBOL. For example, CMAN data set
      // "CMAN.CMAN.Y0DJD.CMM99217.T1404536.COBOL2" last qualifier
      // is "COBOL2" and so the data set is switched to COBOL mode.
      _str lastQualifier = _DataSetQualifier(p_buf_name,-1);
      if (pos("COBOL",upcase(lastQualifier)) == 1) {
         _SetEditorLanguage('cob',origBypassBufferSetup);
         return(0);
      }
   }

   // Continue to do the normal things in _SetEditorLanguage().
   return(1);
}
