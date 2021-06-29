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
#require "RelocatableMarker.e"
#endregion

namespace se.lineinfo;

class LineInfo {
   bool m_deferred;
   bool m_lineVisited;
   bool m_lineModified;
   // Only one marker ID will be used.
   int m_lmarkerID; // line marker ID
   int m_smarkerID; // stream marker ID
   _str m_preview; // The caption when mousing-over the gutter glyph.
   _str m_sourceFile;
   _str m_type;
   RelocatableMarker m_marker; // Relocatable code marker.

   LineInfo ()
   {
      m_deferred = false;
      m_lineVisited = false;
      m_lineModified = false;
      m_lmarkerID = -1;
      m_smarkerID = -1;
      m_preview = "";
      m_sourceFile = "";
      m_type = "";
   }
   ~LineInfo () {}
};

