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

//#define USE_FLEX_LICENSING
#define USE_SEAL_LICENSING

enum LICENSE_TYPE {
   LICENSE_TYPE_NONE=-1,
   LICENSE_TYPE_STANDARD=0,
   LICENSE_TYPE_TRIAL=1,
   LICENSE_TYPE_NOT_FOR_RESALE=2,
   LICENSE_TYPE_BETA=3,
   LICENSE_TYPE_CONCURRENT=4,
   LICENSE_TYPE_SUBSCRIPTION=5,
   LICENSE_TYPE_ACADEMIC=6,
   LICENSE_TYPE_FILE=7,
   LICENSE_TYPE_BORROW=8
};

extern int _OEM();
extern LICENSE_TYPE _LicenseType();
extern _str _LicenseExpiration();
extern _str _LicenseFile();
extern _str _SerialNumber();
extern _str _LicenseToInfo();
extern bool _Flexlm();
extern int _LicenseExpirationInDays();
extern int _NotForResale();
extern int _LmRegType();
extern int _trial_serial_number();
extern void vsflexlm_idle(int idleTime,bool doCheckIn);
extern int _FlexlmNofusers();
extern _str _FlexlmVendorString();
extern void vsflexlm_heartbeat();
extern _str _fnpGetLicenseId();
extern int _fnpIsLicenseValid();
extern void _LicenseInit();
extern int _fnpHasActivationSupport();
extern int _LicenseBorrow(_str pszExpires);
extern int _LicenseReturn(_str pszServer);
extern _str _LicenseServerName();

