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
#ifndef WWTS_H
#define WWTS_H

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party version control 
 * systems. 
 */
namespace default;

struct WWTS_USER_INFO {
   _str userName;
   _str description;
   int bgcolor;
   int fgcolor;
};

struct WWTS_VERSION_LIST_INFO {
   _str caption;
   _str description;
   int bgcolor;
   int fgcolor;
   int indexList[];
};

struct TAG_IDENTIFIER_VERSION_INFO {
   _str startTag;
   _str endTag;
   _str curFilename;
   _str description;

   _str startVersion;
   _str endVersion;
   _str startBranch;
   _str endBranch;
   _str strippedStartVersion;
   _str strippedEndVersion;

   boolean calculatedStartEnd;
   int fgcolor;
   int bgcolor;
};

struct INT_DATE_RANGE{
   int ageInDays;
   int bgcolor,fgcolor;
   _str description;
};

struct WWTS_TOOLWINDOW_INFO {
   _str name;
   _str description;
   int indexList[];
};
#endif
