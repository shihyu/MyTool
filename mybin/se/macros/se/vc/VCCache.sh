////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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

#ifndef VCCACHE_SH
#define VCCACHE_SH

#define CACHE_DB_VERSION 3

#if __UNIX__
#define VCCACHEUPDATER_EXE 'vccacheupdtr'
#else
#define VCCACHEUPDATER_EXE 'vccacheupdtr.exe'
#endif

int def_svn_use_new_history = 1;
boolean def_vccache_debug = false;
int def_vccache_synchro_update_limit = 14;

#endif
