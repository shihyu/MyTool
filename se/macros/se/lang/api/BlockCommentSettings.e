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


namespace se.lang.api;

/**
 * Struct holding the language extension comment settings
 */
class BlockCommentSettings {
   _str m_tlc;
   _str m_trc;
   _str m_blc;
   _str m_brc;
   _str m_bhside;
   _str m_thside;
   _str m_lvside;
   _str m_rvside;
   _str m_comment_left;
   _str m_comment_right;
   int  m_comment_col;
   bool m_firstline_is_top;
   bool m_lastline_is_bottom;
   COMMENT_LINE_MODE m_mode;
   BlockCommentSettings() {
      m_tlc='';m_trc='';m_blc='';m_brc='';m_bhside='';m_thside='';m_lvside='';m_rvside='';
      m_comment_left='';m_comment_right='';m_comment_col=0;
      m_firstline_is_top=false;m_lastline_is_bottom=false;
      m_mode=LEFT_MARGIN;
   }
   _str getPropertyAttr(_str member,_str value) {
      if (member=='comment_col' || member=='firstline_is_top' || member=='lastline_is_bottom' || member=='mode') {
         if (value==0) {
            return null;
         }
         return value;
      }
      if (value=='') {
         return null;
      }
      return value;
   }
};


