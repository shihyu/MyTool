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
#pragma option(metadata,"error.e")

// Auto severity means we try to determine the severity by looking for
// common keywords in the message.  This is the default value that is used
// if the severity is not specified.
const ERRORRE_SEVERITY_AUTO = "<Auto>";

struct ERRORRE_INFO {
   _str m_name;
   //int m_position;
   bool m_enabled;
   _str m_macro;
   _str m_re;
   _str m_test_case;
   _str m_severity;
};

struct ERRORRE_FOLDER_INFO {
    _str m_name;
    //int m_position;
    bool m_enabled;
    ERRORRE_INFO m_errorre_array[];
};
