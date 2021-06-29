////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc. 
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
#pragma option(metadata,"alias.e")
#include "tagsdb.sh"

struct AliasParam {
   _str name;
   _str initial;
   _str prompt;
};

class MI_localFunctionParams_t {
   _str m_param[];
   _str m_ptype[];
   SETagFlags m_flags[];
   _str m_rtype;
   _str m_exception[];
   _str m_existingParamName[];
   _str m_existingParamDesc[];
   _str m_existingRName;
   _str m_existingRDesc;
   _str m_existingSummary;
   _str m_existingException[];
   _str m_signature;
   _str m_procName;
   _str m_className;
   MI_localFunctionParams_t() {
      m_param._makeempty();
      m_ptype._makeempty();
      m_flags._makeempty();
      m_rtype = '';
      m_exception._makeempty();
      m_existingParamName._makeempty();
      m_existingParamDesc._makeempty();
      m_existingRName = '';
      m_existingRDesc = '';
      m_existingSummary = '';
      m_existingException._makeempty();
      m_signature = '';
      m_procName = '';
      m_className = '';
   }
   int paramNum() {
      return m_param._length();
   }
   int returnNum() {
      if (m_rtype != '' && m_rtype != 'void' && m_rtype!='Unit' /* Kotlin, Scala */) {
         return 1;
      }
      return 0;
   }
};

