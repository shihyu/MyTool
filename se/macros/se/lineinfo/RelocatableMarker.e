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
#pragma option(pedantic, on)
#region Imports
#include "slick.sh"
#endregion

namespace se.lineinfo;


class RelocatableMarker {
   int m_origLineNumber;
   int m_n;
   int m_aboveCount;
   int m_belowCount;
   int m_totalCount;
   _str m_sourceFile;
   _str m_origText[];
   _str m_textAbove[][];
   _str m_textBelow[][];

   RelocatableMarker () 
   {
      m_origLineNumber = 0;
      m_n = 0;
      m_aboveCount = 5;
      m_belowCount = 5;
      m_totalCount = 10;
      m_sourceFile = "";
   }
   ~RelocatableMarker () {}
};

