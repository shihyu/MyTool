////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44444 $
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
#ifndef ANDROID_SH
#define ANDROID_SH

#if __UNIX__
#define VSANDROIDRUN_EXE 'vsandroidrun'
#else
#define VSANDROIDRUN_EXE 'vsandroidrun.exe'
#endif

#define ANDROID_TOOL "android"
#define EMU_TOOL "emulator"
#define ADB "adb"
#define ANDROID_JAR "android.jar"

struct EMULATOR_INFO {
   _str port;
   _str serial;
   _str name;
   _str state;
   _str target;
   _str api_level;
};

#endif
