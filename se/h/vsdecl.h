////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include <stddef.h>
#if !__sparc__
#include <stdint.h>
#endif

#undef EXTERN_C
#undef CMEXTERN_C
#undef EXTERN_C_BEGIN
#undef CMEXTERN_C_BEGIN
#undef EXTERN_C_END
#undef CMEXTERN_C_END
#undef VSDEFAULT
#undef VSREF
#undef CMWINDOWS
#undef CMUNIX
#undef CMPOINTER64


#define EXTERN_C extern "C"
#define CMEXTERN_C extern "C"
#define EXTERN_C_BEGIN extern "C" {
#define CMEXTERN_C_BEGIN extern "C" {
#define EXTERN_C_END }
#define CMEXTERN_C_END }
#define VSDEFAULT(a) =a
#define VSREF(a) &a

#if defined(_WIN32) 
   #define VSAPI  __stdcall
   #if SE_STANDARD || SE_COMMUNITY
      #define VSDLLEXPORT
      #define VSDLLIMPORT
   #else
      #define VSDLLEXPORT __declspec(dllexport)
      #define VSDLLIMPORT __declspec(dllimport)
   #endif
   #define CMDLLEXPORT __declspec(dllexport)
   #define CMDLLIMPORT __declspec(dllimport)
   #define VSUNIX     0
   #define CMUNIX     0
   #define VSWINDOWS  1
   #define CMWINDOWS  1
   #define VSOS2      0
   #define VSNT       1
   #define VSMACOSX   0
   #define CMMACOSX   0
   #ifdef _WIN64
       #define VSPOINTER64 1
   #else
       #define VSPOINTER64 0
   #endif
   #define CMPOINTER64 VSPOINTER64
#else
   #if defined(VSPOINTER64)
      #undef  VSPOINTER64
      #undef  CMPOINTER64
   #endif
   // GNU C++ hopefully defines __WORDSIZE
   #if defined(__WORDSIZE)
       #if __WORDSIZE==64
           #define VSPOINTER64 1
       #else
           #define VSPOINTER64 0
       #endif
   #elif defined(__LP64__)
       #define VSPOINTER64 1
   #else
       #define VSPOINTER64 0
   #endif
   #define CMPOINTER64 VSPOINTER64

   #define VSDLLEXPORT
   #define CMDLLEXPORT
   #define VSDLLIMPORT
   #define CMSDLLIMPORT
   #define VSAPI
   #define VSUNIX     1
   #define CMUNIX     1
   #define VSWINDOWS  0
   #define CMWINDOWS  0
   #define VSOS2      0
   #define VSNT       0
   #if defined(MACOSX11APP)
      #define VSMACOSX   1
      #define CMMACOSX   1
   #else
      #define VSMACOSX   0
      #define CMMACOSX   0
   #endif
   #define _stricmp  strcasecmp
   #define strnicmp strncasecmp
#endif

/* IF lstr.h was not included */
#define VSMAXLSTR  1024
#ifndef VSLSTR_DEFINED
#define VSLSTR_DEFINED
  struct VSLSTR {
     int len;
     unsigned char str[VSMAXLSTR];
  };
  typedef const struct VSLSTR *VSPLSTR;
#endif // VSLSTR_DEFINED

#if defined(_WIN32)
   #define VSINT64 _int64
   #define VSUINT64 unsigned _int64
#elif defined(_INT64_T)
   #define VSINT64 int64_t
   #define VSUINT64 uint64_t
#else
   #define VSINT64 long long
   #define VSUINT64 unsigned long long
#endif

#ifndef seSeekPos_defined
#define seSeekPos_defined
typedef long long int seSeekPosRet;
typedef long long int seSeekPos;
#if VSPOINTER64
  typedef const seSeekPos seSeekPosParam;
  typedef const VSINT64   VSINT64Param;
  typedef const VSUINT64  VSUINT64Param;
  typedef const double    VSDOUBLEParam;
#else
  typedef const seSeekPos &seSeekPosParam;
  typedef const VSINT64   &VSINT64Param;
  typedef const VSUINT64  &VSUINT64Param;
  typedef const double    &VSDOUBLEParam;
#endif
#define seLineOffset int
#define seStringLen int
#endif

#ifndef VSINT
   #if VSPOINTER64
      #define VSINT  VSINT64
   #else
      #define VSINT  int
   #endif
#endif

#ifndef VSMAXUNSIGNED
    #define VSMAXUNSIGNED  (0xffffffffU) 
#endif
#ifndef SESIZE_MAX
    #define SESIZE_MAX     (4294967295U)
#endif

#define VSNOXLATDLLNAMES
#ifndef VSSTATIC
   #define VSSTATIC static
#endif

#define HVAR   int
#define VSHVAR  int
#define VSHREFVAR VSHVAR         // Do not change this to intptr_t
#define VSHREFINT VSHREFVAR
#define VSHREFSTR VSHREFVAR
//typedef void *VSPVOID;
//typedef char *VSPSZ;
#define VSPVOID void *
#define VSPSZ const char *
#define SEStringConst const slickedit::SEString &
#define SEStringByRef slickedit::SEString &
#define SEStringRet   slickedit::SEString

#ifndef seintptr_t
#define seintptr_t intptr_t
#endif 

// Dirty, cheap, rotten casts...
#ifndef sestrlen32
#define sestrlen32(s)	(static_cast<int>(strlen(s)))
#endif
#ifndef sewcslen32
#define sewcslen32(s)	(static_cast<int>(wcslen(s)))
#endif
#ifndef PTR_DIFF32
#define PTR_DIFF32(f,l) (static_cast<int>(f-l))
#endif 

namespace slickedit {
   class VSDLLEXPORT SEString;
   //class VSDLLEXPORT SEAllocator;
   class VSDLLEXPORT SEIterator;
}

typedef int seTagSeekPos;

enum cmEncoding {
    CMCP_ACTIVE_CODE_PAGE = 0,
    cmEncoding_AutoUnicode  = 0x1,     // Use signature encoding if present. Default to Utf-8 if ACP is Utf-8, otherwise CMCP_ACTIVE_CODE_PAGE.
    cmEncoding_AutoText     = 0x2,     // If the default encoding is Utf-8, use cmEncoding_Utf8. Otherwise, use CMCP_ACTIVE_CODE_PAGE.
    cmEncoding_AutoEbcdic   = 0x4,     // Use signature encoding if pressent. If text looks like EBCDIC, then EBCDIC. Default to Utf-8 if ACP is Utf-8, otherwise CMCP_ACTIVE_CODE_PAGE.
    cmEncoding_AutoUnicode2 = 0x8,     // Determine by signature or contents. Default to Utf-8 if ACP is Utf-8, otherwise CMCP_ACTIVE_CODE_PAGE.
    cmEncoding_AutoXml      = 0x11,     // Check for signature and look for <?xml ... encoding, default to cmEncoding_Utf8
    cmEncoding_AutoHtml     = 0x12,     // Check for signature and look for HTML encoding, default to CMCP_ACTIVE_CODE_PAGE
    cmEncoding_AutoHtml5    = 0x13,     // Check for signature and look for HTML encoding, default to cmEncoding_Utf8
    cmEncoding_AutoTextUnicode = 0x14,    // Use signature encoding if present. If the default encoding is Utf-8, use cmEncoding_Utf8. Otherwise, use cmCharUtil::getACP()
    cmEncoding_AutoUnicodeUtf8 = 0x15,    // Same as AutoUnicode but default encoding is always Utf-8
    cmEncoding_AutoUnicode2Utf8 = 0x16,    // Same as AutoUnicode2 but default encoding is always Utf-8
    cmEncoding_AutoEbcdic_And_Unicode = (cmEncoding_AutoEbcdic | cmEncoding_AutoUnicode),
    cmEncoding_AutoEbcdic_And_Unicode2 = (cmEncoding_AutoEbcdic | cmEncoding_AutoUnicode2),
    cmEncoding_AutoUnicode_And_Unicode2 = (cmEncoding_AutoUnicode | cmEncoding_AutoUnicode2),
    cmEncoding_AutoFirst = cmEncoding_AutoUnicode,
    cmEncoding_AutoFirstFlag = cmEncoding_AutoUnicode,
    cmEncoding_AutoLastFlag = cmEncoding_AutoUnicode2|cmEncoding_AutoEbcdic|cmEncoding_AutoText|cmEncoding_AutoUnicode,
    cmEncoding_AutoFirstIndex = cmEncoding_AutoXml,
    cmEncoding_AutoLastIndex = cmEncoding_AutoUnicode2Utf8,
    cmEncoding_AutoLast = cmEncoding_AutoUnicode2Utf8,

    cmEncoding_Utf8                =70,
    cmEncoding_Utf8WithSignature   =71,
    cmEncoding_Utf16LE             =72,
    cmEncoding_Utf16LEWithSignature=73,
    cmEncoding_Utf16BE             =74,
    cmEncoding_Utf16BEWithSignature=75,
    cmEncoding_Utf32LE             =76,
    cmEncoding_Utf32LEWithSignature=77,
    cmEncoding_Utf32BE             =78,
    cmEncoding_Utf32BEWithSignature=79,

    cmEncoding_Max= 100,
    CMCP_Japanese_Shift_JIS = 932,
    CMCP_Chinese_Traditional_Big5 = 950,
    CMCP_Chinese_Simplified_GB_2312   = 20936, // The old code page was 936 but conflicts with the Windows code page 936
    //CMCP_Korean_ksc_5601 = 949, not same as old VSCP_KSC_5601 which can't be supported
    CMCP_Cyrillic_Windows_1251 = 1251,
    CMCP_Western_European_Windows_1252 = 1252,
    CMCP_Chinese_Simplified_GB2312 = 20936,
    CMCP_EBCDIC_SBCS = 29999,  // This is not a real code page
    CMCP_Cyrillic_KOI8_R = 30000, //Cyrillic (KOI8-R) Windows-20866
    CMCP_ISO_8859_1 = 30001, //Latin 1 (ISO 8859-1) Windows-28591
    CMCP_ISO_8859_2 = 30002, //Central European (ISO 8859-2) Windows-28592
    CMCP_ISO_8859_3 = 30003, //Latin 3  (ISO 8859-3) Windows-28593
    CMCP_ISO_8859_4 = 30004, //Baltic (ISO 8859-4) Windows-28594
    CMCP_ISO_8859_5 = 30005, //Cyrillic (ISO 8859-5) Windows-28595
    CMCP_ISO_8859_6 = 30006, //Arabic (ISO 8859-6) Windows-28596
    CMCP_ISO_8859_7 = 30007, //Greek (ISO 8859-7) Windows-28597
    CMCP_ISO_8859_8 = 30008, // Hebrew (ISO 8859-8) Windows-28598
    CMCP_ISO_8859_9 = 30009, //Latin 5 (ISO 8859-9) Windows-28599
    CMCP_ISO_8859_10 = 30010,  //Latin 6 (ISO 8859-10)
    CMCP_ISO_8859_13 = 30013,  //Latin 7 (ISO 8859-13)  Estonian Windows-28603
    CMCP_ISO_8859_14 = 30014,  //Latin 8 (ISO 8859-13)
    CMCP_ISO_8859_15 = 30015, //Latin 9 (ISO 8859-15) Windows-28605
    CMCP_ISO_8859_16 = 30016,  //Latin 10 (ISO 8859-16)
    CMCP_Cyrillic_KOI8_U = 30100, //Cyrillic (KOI8-U) Windows-21866
    CMCP_Thai_TIS620 = 30105,
    CMCP_MACROMAN = 30113,  //Latin Matintosh (macRoman) Windows-10000
    CMCP_Chinese_Simplified_EUC = 30121, // Windows-51936
    CMCP_Japanese_EUC = 30122, // Japanese (EUC) Windows-51932
    CMCP_Korean_EUC = 30123,  // Windows-51949
    CMCP_Symbol      = 30200,
    CMCP_Dingbats    = 30201,
    CMCP_MAX_WINDOWS_CODE_PAGE = 66000,  // 65001 is the last but we assume higher code pages are valid anyway
    CMCP_Dingbats_Mac= 70001,

    // Allow 999 user defined code pages.
    // Using one for active code page right now so it can be
    // dynamically defined at run-time
    CMCP_FIRST_USERDEFINED_CODE_PAGE = 80000,
};

#if VSDEBUG
   #define VSASSERT(expr) assert(expr);
#else
   #define VSASSERT(expr)
#endif

#if !defined(nullptr) && (defined(__OBJC__) || !defined(__cplusplus))
    #define nullptr NULL
#endif

#if VSUNIX
#define VSDEPRECATED __attribute__((deprecated))
#define VSDEPRECATECONSTANT(n) (VSDeprecatedConstantZero? n:n)
#else
#define VSDEPRECATED __declspec(deprecated)
#define VSDEPRECATECONSTANT(n) n
#endif

enum VSDEPRECATED {
    VSDeprecatedConstantZero = 0
};


