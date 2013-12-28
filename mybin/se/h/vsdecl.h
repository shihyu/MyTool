////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef VSDECL_H
#define VSDECL_H
#include <stddef.h>
#if !__sparc__
#include <stdint.h>
#endif

#undef EXTERN_C
#undef EXTERN_C_BEGIN
#undef EXTERN_C_END
#undef VSDEFAULT
#undef VSREF

#if __cplusplus
   #define EXTERN_C extern "C"
   #define EXTERN_C_BEGIN extern "C" {
   #define EXTERN_C_END }
   #define VSDEFAULT(a) =a
   #define VSREF(a) &a
#else
   #define EXTERN_C extern
   #define EXTERN_C_BEGIN
   #define EXTERN_C_END
   #define VSDEFAULT(a)
   #define VSREF(a) *a
#endif

#if defined(_WIN32) 
   #define VSAPI  __stdcall
   #define VSDLLEXPORT __declspec(dllexport)
   #define VSDLLIMPORT __declspec(dllimport)
   #define VSUNIX     0
   #define VSWINDOWS  1
   #define VSOS2      0
   #define VSNT       1
   #ifdef _WIN64
       #define VSPOINTER64 1
   #else
       #define VSPOINTER64 0
   #endif
#else
   #if defined(VSPOINTER64)
    #undef  VSPOINTER64
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

   #define VSDLLEXPORT
   #define VSDLLIMPORT
   #define VSAPI
   #define VSUNIX     1
   #define VSWINDOWS  0
   #define VSOS2      0
   #define VSNT       0
   #if defined(S390APP)
      #undef EXTERN_C
      #undef EXTERN_C_BEGIN
      #undef EXTERN_C_END
      #define EXTERN_C
      #define EXTERN_C_BEGIN
      #define EXTERN_C_END
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
  typedef struct VSLSTR *VSPLSTR;
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
#else
  typedef const seSeekPos &seSeekPosParam;
  typedef const VSINT64   &VSINT64Param;
  typedef const VSUINT64  &VSUINT64Param;
#endif
#define seLineOffset int
#define seStringLen int
#endif

#ifndef VSMAXUNSIGNED
    #define VSMAXUNSIGNED  (0xffffffff) 
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

#ifndef seintptr_t
#define seintptr_t intptr_t
#endif 

// Dirty, cheap, rotten casts...
#ifndef sestrlen32
#define sestrlen32(s)	(int)(strlen(s))
#endif
#ifndef sewcslen32
#define sewcslen32(s)	(int)(wcslen(s))
#endif
#ifndef PTR_DIFF32
#define PTR_DIFF32(f,l) ((int)(f-l))
#endif 

namespace slickedit {
   class VSDLLEXPORT SEString;
   class VSDLLEXPORT SEAllocator;
   class VSDLLEXPORT SEIterator;
}

typedef int seTagSeekPos;

#endif // VSDECL_H
