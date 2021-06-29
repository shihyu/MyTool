////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

// this file contains version information for slickedit.  this version
// info is used in all resource files and should also be used whenever version
// messages are needed.  this provides a single place to update the version for
// all things pertaining to the product.

#define VSE_VERSION_YEAR               "2020"

// numerical representation of version
#define VSE_VERSION_MAJOR              25
#define VSE_VERSION_MINOR              0
#define VSE_VERSION_SUB                2
#define VSE_VERSION_BUILD              0
#define VSE_VERSION_BUILD_SHIPPED      VSE_VERSION_BUILD
#define VSE_VERSION_LICENSE_MAJOR      25
#define VSE_VERSION_LICENSE_MINOR      0

// set for beta builds, 0 otherwise
// the build scripts (bvswin.bat, bvsunix) extract this number from here
#define VSE_VERSION_BETA_NUMBER        0

#define VSE_ECLIPSE_VERSION_MAJOR      3
#define VSE_ECLIPSE_VERSION_MINOR      7 
#define VSE_ECLIPSE_VERSION_SUB        1

#define VSE_MAJOR_STR(major) #major
#define VSE_MAJOR1(major) VSE_MAJOR_STR(major)
#define VSE_MAJOR_MINOR2_STR(major,minor) #major "." #minor
#define VSE_MAJOR_MINOR2(major,minor) VSE_MAJOR_MINOR2_STR(major,minor)
#define VSE_MAJOR_MINOR3_STR(m1,m2,m3) #m1 "." #m2 "." #m3
#define VSE_MAJOR_MINOR3(m1,m2,m3) VSE_MAJOR_MINOR3_STR(m1,m2,m3)
#define VSE_MAJOR_MINOR4_STR(m1,m2,m3,m4) #m1 "." #m2 "." #m3 "." #m4
#define VSE_MAJOR_MINOR4(m1,m2,m3,m4) VSE_MAJOR_MINOR4_STR(m1,m2,m3,m4)

#define VSE_MAJOR_MINOR4_DEMO_STR(m1,m2,m3,m4) #m1 "." #m2 "." #m3 "." #m4 " demo"
#define VSE_MAJOR_MINOR4_DEMO(m1,m2,m3,m4) VSE_MAJOR_MINOR4_DEMO_STR(m1,m2,m3,m4)

// core requires this to be major.minor
// slickedit only requires this to be major.minor if minor > 0 
#define VSE_LICENSE_VERSION            VSE_MAJOR1(VSE_VERSION_LICENSE_MAJOR)
// core requires this to be major.minor.sub (ie. 3.7.1)
// slickedit requires only major.minor (ie. 17.0)
#define VSE_LICENSE_VERSION_CHECKOUT   VSE_MAJOR_MINOR2(VSE_VERSION_LICENSE_MAJOR,VSE_VERSION_LICENSE_MINOR)

// MAJOR.MINOR only for FLEXlm!
#define VSE_LICENSE_VERSION_STR        VSE_MAJOR_MINOR2(VSE_VERSION_LICENSE_MAJOR,VSE_VERSION_LICENSE_MINOR)
#define VSE_VERSION_STR                VSE_MAJOR_MINOR4(VSE_VERSION_MAJOR,VSE_VERSION_MINOR,VSE_VERSION_SUB,VSE_VERSION_BUILD)
#define VSE_VERSION_CONFIG_DIR_STR     VSE_MAJOR_MINOR3(VSE_VERSION_MAJOR,VSE_VERSION_MINOR,VSE_VERSION_SUB)
#define VSE_VERSION_PATCH_STR          VSE_VERSION_STR
#define VSE_DEMO_VERSION_PATCH_STR     VSE_MAJOR_MINOR4_DEMO(VSE_VERSION_MAJOR,VSE_VERSION_MINOR,VSE_VERSION_SUB,VSE_VERSION_BUILD)

#define VSECLIPSE_LICENSE_VERSION_STR  VSE_MAJOR_MINOR2(VSE_ECLIPSE_VERSION_MAJOR,VSE_ECLIPSE_VERSION_MINOR)
#define VSE_ECLIPSE_VERSION_STR        VSE_MAJOR_MINOR3(VSE_ECLIPSE_VERSION_MAJOR,VSE_ECLIPSE_VERSION_MINOR,VSE_ECLIPSE_VERSION_SUB)

#define VSE_VERSION_HEX                ((VSE_VERSION_MAJOR<<24)|(VSE_VERSION_MINOR<<16)|(VSE_VERSION_SUB<<8)|VSE_VERSION_BUILD)              
#define VSE_ECLIPSE_VERSION_HEX        ((VSE_ECLIPSE_VERSION_MAJOR<<24)|(VSE_ECLIPSE_VERSION_MINOR<<16)|(VSE_ECLIPSE_VERSION_SUB<<8)|VSE_VERSION_BUILD)              
#define VSE_VERSION_INTERNAL_BUILD     "Build " VSE_VERSION_BUILD

#if SE_STANDARD
   #define VSE_VERSION_PRODUCT_NAME       "SlickEdit Standard"
   #define VSE_VERSION_UNIX_INSTALLDIR_PART "slickedit-standard" VSE_VERSION_YEAR
#elif SE_COMMUNITY
   #define VSE_VERSION_PRODUCT_NAME       "SlickEdit Community"
   #define VSE_VERSION_UNIX_INSTALLDIR_PART "slickedit-community" VSE_VERSION_YEAR
#else
   #define VSE_VERSION_PRODUCT_NAME       "SlickEdit Pro"
   #define VSE_VERSION_UNIX_INSTALLDIR_PART "slickedit-pro" VSE_VERSION_YEAR
   //#define VSE_VERSION_UNIX_INSTALLDIR_PART "slickedit-pro"
   //#define VSE_VERSION_PRODUCT_NAME       "SlickEdit"
   //#define VSE_VERSION_UNIX_INSTALLDIR_PART "slickedit"
#endif
#define VSE_VERSION_PRODUCT_NAME_SHORT "VSE"
#define VSE_VERSION_BUNDLE_ID          "com.slickedit.SlickEdit"
#define VSE_VERSION_LICENSE_FILE       "slickedit.lic"

#define VSE_VERSION_COMPANY_NAME       "SlickEdit Inc."
#define VSE_VERSION_COPYRIGHT          "Copyright 1988-" VSE_VERSION_YEAR " " VSE_VERSION_COMPANY_NAME
#define VSE_VERSION_TRADEMARK          ""


// these defaults are used for all files that have no individual version
// tracking.  this ensures that they are always set to the same version
// as the product.  the reason for having a second set of defines
// that mirror the product set is to draw distinction between what
// values are to be used for the product and what values are to be
// used for individual files.
#define VSE_VERSION_FILE_STR           VSE_VERSION_STR

#define VSE_VERSION_FILE_MAJOR         VSE_VERSION_MAJOR
#define VSE_VERSION_FILE_MINOR         VSE_VERSION_MINOR
#define VSE_VERSION_FILE_SUB           VSE_VERSION_SUB
#define VSE_VERSION_FILE_BUILD         VSE_VERSION_BUILD


//#define VSE_BITMAPS_DIR ("bitmaps.zip" CMFILESEPSTR "bitmaps")
#define VSE_BITMAPS_DIR ("bitmaps")
