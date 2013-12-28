////////////////////////////////////////////////////////////////////////////////////
// $Revision: 45236 $
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
#import "optionsxml.e"
#endregion

//static typeless _settings:[];

/**
 * The <b>setup_file_options</b> command displays various file
 * options.
 *
 * @param showTab    tab number to display initially
 *                   (load, save, backup, autosave, filters)
 *
 * @categories Miscellaneous_Functions
 */
_command setup_file_options(_str showTab='')
{
   switch (lowcase(showTab)) {
   case 'load':      showTab='Load'; break;
   case 'save':      showTab='Save'; break;
   case 'backup':    showTab='Backup'; break;
   case 'autosave':  showTab='AutoSave'; break;
   case 'filters':   showTab='File Filters'; break;
   }

   config('File Options > 'showTab);
}

#define SMALLEST_INTERVAL   10
