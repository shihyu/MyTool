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
#include "slick.sh"
#require "ILabelFetcher.e"
#import "VCInfo.e"
#include "pipe.sh"
#import "pipe.e"
#import "stdprocs.e"
#import "varedit.e"
#endregion

_command void test_show_mode() name_info(',')
{
   say('test_show_mode p_mode_name='p_mode_name);
}

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class CVSLabelFetcher : ILabelFetcher {

   CVSLabelFetcher() {
   }
   /**
    * @return 0 if successful
    */
   int getLabels(_str (&labels):[],_str lastUpdateDate="") {
      status := 0;
      do {
         se.vc.VCInfo vcInfo;
         cmdline := vcInfo.getExePath("cvs");
         if ( cmdline=="" || !file_exists(cmdline) ) {
            status = FILE_NOT_FOUND_RC;break;
         }
         dateOption := "";
         if ( lastUpdateDate!="" ) {
            dateOption = " -D":+lastUpdateDate;
         }
         cmdline = cmdline:+" history  -T -a":+dateOption;
         int hprocess = _PipeProcess(cmdline,auto appStdout,auto appStdin,auto appStderr,"");
         for ( ;; ) {
            stdOutData := "";stdErrData := "";

            statusStdOut := _PipeReadLine(stdOutData,appStdout);
            statusStdErr := _PipeReadLine(stdErrData,appStderr);
            if ( stdOutData!="" ) {
               if ( substr(stdOutData,1,19)=="No records selected" ) {
                  break;
               }
               parse stdOutData with auto type auto year'-'auto month'-'auto day . . . . '[' auto curTag ':' auto info ']' . ;
               labels:[curTag] = year:+month:+day;
            }
            if ( _PipeIsProcessExited(hprocess) || (statusStdOut && statusStdErr) ) break;
         }
         _PipeClose(hprocess);
      } while ( false );
      return status;
   }
};

_command void test_cvs_label_fetcher() name_info(',')
{
   CVSLabelFetcher lf(/*"slickedit"*/);
   lf.getLabels(auto labels);
}
