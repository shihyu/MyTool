#pragma once

#ifndef CMWINDOWS
   #define CMWINDOWS   0
#endif
#ifndef CMUNIX
   #define CMUNIX      0
#endif
#ifndef CMMACOSX
   #define CMMACOSX    0
#endif

#define CMLINUX     0
#define CMAIX       0
#define CMHPUX      0
#define CMSOLARIS   0

#define CMMTYPE_RS6000  0
#define CMMTYPE_HP9000  0
#define CMMTYPE_386     0
#define CMMTYPE_SPARC   0
#define CMMTYPE_PPC     0

// Minimum alignment
#define CMALIGN_SHORT   (CMALIGN>=2)
#define CMALIGN_INT64   (CMALIGN>=8)
// Align on 64 bit byte boundary
#define CMALIGN   8
#define CMBIGENDIAN 0
#define CMFILES_CASE_SENSITIVE 1
#define CMSIZE_OF_WCHAR_T  4
#define CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT 0
#define CMWCHAR_T_IS_4_BYTES_AND_DIFFERS_FROM_INT    1
#define CMSIZE_OF_LONG     4
#define CMPATHSEP ':'
#define CMPATHSEPSTR ":"
#define CMFILESEP '/'
// backslash is allowed in a unix filename!!! so this is a forward slash
#define CMFILESEP2 '/'
#define CMFILESEPSTR "/"
#if defined(VSDEBUG) && !defined(CMDEBUG)
    #define CMDEBUG 1
#endif

#if CMDEBUG
   #define CMASSERT(expr) assert(expr);
   //#define CMASSERT(expr) {if(!(expr)) {char *p=0;*p=0;}}
#else
   #define CMASSERT(expr)
#endif

#if defined(__OBJC__) && !defined(nullptr) && (__cplusplus < 201100)
    #define nullptr NULL
#endif

#define CMSTDCALL
#define CMEOL_CH1 '\n'
#define CMEOL_CH2 '\n'
#define CMEOL_CHARS "\n"
#define CMMESSAGES_FILENAME       ("h/vsmsgdefs.h"_cm)
//#define CMMESSAGES_HEADERS_BUILD_DATE  ("cmmessages.cmmsg_headers_build_date")
#define CMMESSAGES_BINARY_FILENAME  ("vslick.vsb"_cm)
#ifndef CMDLLEXPORT
    #define CMDLLEXPORT
    #define CMDLLIMPORT
#endif
#define CMSIZE_T_IS_NEW_TYPE 0
#define CMNAMEHASDRIVE 0
#define CMMAXFILENAME  1024

#ifndef CMEXTERN_C
   #define CMEXTERN_C extern "C"
#endif

#ifndef CMEXTERN_C_BEGIN
   #define CMEXTERN_C_BEGIN extern "C" {
#endif

#ifndef CMEXTERN_C_END
   #define CMEXTERN_C_END }
#endif
#define CMSIGRESULT void
#define cmOSFileHandle int
#define CMOSGENERICCONFIGSTR "unix"
#define cmftruncate64 ftruncate64
#define cmlseek64 lseek64
#define cmstat64 stat64
#define cmlstat64 lstat64

#define CM_HAVE_STD_MOVE 0


#define CM_STRINGIZE_HELPER(x) #x
#define CM_STRINGIZE(x) CM_STRINGIZE_HELPER(x)
#define CM_WARNING_MESSAGE(desc) message(__FILE__ "(" CM_STRINGIZE(__LINE__) "): warning: " #desc)


#if defined(_WIN32)
    #undef CMMTYPE_386
    #define CMMTYPE_386    1

    //Want to know when line comments ends in trailing backslash
    #pragma warning(3:4010)
    //Want warning for unreferenced local function
    #pragma warning(3:4505)
    // Ignore warning about a typedef enum with no name
    #pragma warning(4:4091)
    //Want to know if class with virtual methods does not have virtual destructor
    #pragma warning(3:4265)
    //Want to know if a function is missing it's return type
    #pragma warning(3:4431)
    //Want to know if a local variable is unused
    #pragma warning(3:4101)

    #undef cmOSFileHandle
    #define cmOSFileHandle void *
    #define CMOSSTR "Windows"
    #define CMOSCONFIGSTR "win"
    #undef CMOSGENERICCONFIGSTR
    #define CMOSGENERICCONFIGSTR "win"

    #undef CMDLLIMPORT
    #define CMDLLIMPORT __declspec(dllimport)
    #undef CMDLLEXPORT 
    #define CMDLLEXPORT __declspec(dllexport)

    #undef CMNAMEHASDRIVE
    #define CMNAMEHASDRIVE 1
    #undef CMPATHSEP
    #define CMPATHSEP ';'
    #undef CMPATHSEPSTR
    #define CMPATHSEPSTR ";"
    #undef CMEOL_CH1
    #undef CMEOL_CH2
    #define CMEOL_CH1 '\r'
    #define CMEOL_CH2 '\n'
    #undef CMEOL_CHARS
    #define CMEOL_CHARS "\r\n"
    #undef CMSTDCALL
    #define CMSTDCALL __stdcall
    #undef CMWINDOWS
    #define CMWINDOWS  1
    #undef CMUNIX
    #define CMUNIX 0
    #undef CMFILES_CASE_SENSITIVE
    #define CMFILES_CASE_SENSITIVE 0
    #undef CMSIZE_OF_WCHAR_T
    #define CMSIZE_OF_WCHAR_T 2
    #undef CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT
    #define CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT 1
    #undef CMFILESEP
    #define CMFILESEP '\\'
    #undef CMFILESEP2
    #define CMFILESEP2 '/'
    #undef CMFILESEPSTR
    #define CMFILESEPSTR "\\"
    #undef CMSIGRESULT
    #define CMSIGRESULT void
#elif defined(LINUXAPP) || defined(LINUXAPP64) || defined(CMLINUXAPP) 
    #pragma GCC diagnostic ignored "-Wstrict-aliasing"
    #define CMOSSTR "Linux"
    #define CMOSCONFIGSTR "linux"
    #ifdef RPI4
       // Not setting a processor type here for ARM, as all the 
       // heavy lifting is done in machine.h.  But we do want to 
       // avoid defining CMMTYPE_386, because that ARM alignment
       // is not that relaxed.
    #else
       #undef CMMTYPE_386
       #define CMMTYPE_386 1
    #endif
    #undef CMLINUX
    #define CMLINUX 1
    #undef CMUNIX
    #define CMUNIX 1
#elif defined(SOLARISX86APP) || defined(SOLARISX64APP)
    #define CMOSSTR "Solaris"
    #define CMOSCONFIGSTR "intelsolaris"
    #undef CMMTYPE_386
    #define CMMTYPE_386 1
    #undef CMSOLARIS
    #define CMSOLARIS 1
    #undef CMUNIX
    #define CMUNIX 1
#elif defined(SUNSPARC21APP)
    #define CMOSSTR "Solaris"
    #define CMOSCONFIGSTR "sparcsolaris"
    #undef CMSOLARIS
    #define CMSOLARIS 1
    #undef CMUNIX
    #define CMUNIX 1
    #undef CMMTYPE_SPARC
    #define CMMTYPE_SPARC 1
    #undef CMBIGENDIAN
    #define CMBIGENDIAN 1
#elif defined(AIXRS6000APP)
    #define CMOSSTR "Aix"
    #define CMOSCONFIGSTR "aix"
    #undef CMMTYPE_RS6000
    #define CMMTYPE_RS6000 1
    #undef CMAIX
    #define CMAIX  1
    #undef CMUNIX
    #define CMUNIX 1
    #undef CMBIGENDIAN
    #define CMBIGENDIAN 1
    #undef CMSIZE_OF_WCHAR_T
    #define CMSIZE_OF_WCHAR_T 2
    #undef CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT
    #define CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT 1
#elif defined(HP9000APP)
    #define CMOSSTR "HP/UX"
    #define CMOSCONFIGSTR "hpux"
    #undef CMMTYPE_HP9000
    #define CMMTYPE_HP9000
    #undef CMHPUX
    #define CMHPUX  1
    #undef CMUNIX
    #define CMUNIX 1
    #undef CMBIGENDIAN
    #define CMBIGENDIAN 1
    #if defined(HPUX64APP)
        #undef cmftruncate64
        #define cmftruncate64 ftruncate
        #undef cmlseek64
        #define cmlseek64 lseek
        #undef cmstat64
        #define cmstat64 stat
        #undef cmlstat64
        #define cmlstat64 lstat
        #ifndef F_SETLK64
            #define F_SETLK64 F_SETLK
        #endif
        #ifndef O_LARGEFILE
            #define O_LARGEFILE 0
        #endif
    #endif
#elif defined(MACOSX11APP)
    #ifdef __clang__
    #pragma clang diagnostic ignored "-Wc++11-extensions"
    #endif
    #define CMOSSTR "Mac"
    #define CMOSCONFIGSTR "mac"
    #undef CMOSGENERICCONFIGSTR
    #define CMOSGENERICCONFIGSTR "mac"
    #undef CMMACOSX
    #define CMMACOSX 1
    #undef CMUNIX
    #define CMUNIX 1
    #if defined(__BIG_ENDIAN__)
        #undef CMMTYPE_PPC
        #define CMMTYPE_PPC 1
        #undef CMBIGENDIAN
        #define CMBIGENDIAN 1
    #else
        #undef CMMTYPE_386
        #define CMMTYPE_386    1
    #endif
    #undef cmftruncate64
    #define cmftruncate64 ftruncate
    #undef cmlseek64
    #define cmlseek64 lseek
    #undef cmstat64
    #define cmstat64 stat
    #undef cmlstat64
    #define cmlstat64 lstat
    #define flock64 flock
    #ifndef F_SETLK64
        #define F_SETLK64 F_SETLK
    #endif
    #ifndef O_LARGEFILE
        #define O_LARGEFILE 0
    #endif
    #undef CMFILES_CASE_SENSITIVE
    #define CMFILES_CASE_SENSITIVE 0
#else
    #error OS not defined
#endif

// Allow byte alignment for x86 machines
#if CMMTYPE_386
    #undef CMALIGN
    #define CMALIGN 1
#endif

#if CMUNIX && !CMMACOSX
   #if __GNUC__ < 4 || (__GNUC__ == 4 && __GNUC_MINOR__ < 7)
   // No support for override keyword in older versions of g++
   #define override 
   #endif
#endif

// Note: 1 is used and later adjusted because g++ reports a warning when 0 is used.
#define cmOffsetOf(STRUCTNAME,FIELD) (((cmint)((char*)&((STRUCTNAME*)1)->FIELD))-1)


// Used to inject compiler specific macros into #defines
#if CMMACOSX
#define cmClangPragma(msg)  _Pragma(msg)
#define cmGCCPragma(msg)
#define cmMSVCPragma(msg)
#elif CMUNIX
#define cmClangPragma(msg)
#define cmGCCPragma(msg)    _Pragma(msg)
#define cmMSVCPragma(msg)
#else
#define cmClangPragma(msg)
#define cmGCCPragma(msg)
#define cmMSVCPragma(msg)   __pragma(msg)
#endif

/**
 * <p>This macro give type safe enough flag support without any hit in performance or code size.
 *
 * <p>This macro gives you the ability to use OR(|), AND(&), XOR(^), and ONES COMPLIMENT(~) operators
 * without losing your enum type.  These functions will NOT  effect
 * performance or code size (as long inline functions are inline).
 *
 * <p> NOTE: Since C++ automatically converts enums to int, you can assign
 * your enum to an int.
 */
#define CM_DECLARE_OPERATORS_FOR_ENUM_FLAGS(F) \
cmClangPragma("clang diagnostic ignored \"-Wunused-function\"") \
static inline constexpr F operator |(const F f1,const F f2) { return (F)((int)f1|(int)f2); } \
static inline constexpr F operator &(const F f1,const F f2) { return((F)((int)f1&(int)f2)); }\
static inline constexpr F operator ^(const F f1,const F f2) { return((F)((int)f1^(int)f2)); }\
static inline constexpr F operator ~(const F f1) { return((F)( ~((int)f1))); }\
static inline F operator |=(F &f1,const F f2) { f1=(F)((int)f1|(int)f2); return(f1); }\
static inline F operator &=(F &f1,const F f2) { f1=(F)((int)f1&(int)f2); return(f1); }\
static inline F operator ^=(F &f1,const F f2) { f1=(F)((int)f1^(int)f2); return(f1); }

#define CM_DECLARE_OPERATORS_FOR_ENUM_FLAGS64(F) \
cmClangPragma("clang diagnostic ignored \"-Wunused-function\"") \
static inline constexpr F operator |(const F f1,const F f2) { return (F)((cmUInt64)f1|(cmUInt64)f2); } \
static inline constexpr F operator &(const F f1,const F f2) { return((F)((cmUInt64)f1&(cmUInt64)f2)); }\
static inline constexpr F operator ^(const F f1,const F f2) { return((F)((cmUInt64)f1^(cmUInt64)f2)); }\
static inline constexpr F operator ~(const F f1) { return((F)( ~((cmUInt64)f1))); }\
static inline F operator |=(F &f1,const F f2) { f1=(F)((cmUInt64)f1|(cmUInt64)f2); return(f1); }\
static inline F operator &=(F &f1,const F f2) { f1=(F)((cmUInt64)f1&(cmUInt64)f2); return(f1); }\
static inline F operator ^=(F &f1,const F f2) { f1=(F)((cmUInt64)f1^(cmUInt64)f2); return(f1); }

#if CMWINDOWS
    typedef __int64 cmInt64;
    typedef unsigned __int64 cmUInt64;
// Ignore--> nonstandard extension used : 'extern' before template explicit instantiation
// Need this for explicit template instantiation
    #pragma warning(4:4231)
#elif CMUNIX
    typedef long long int cmInt64;
    typedef unsigned long long int cmUInt64;
#endif
/*
Type Usage 
    cmint   array index, string offset, compare result, error status
    cmuint  memory allocation, readFile bufsize, writeFile bufsize
    int     milliTimeout -1 is infinite
    int     process exit code
 
    cmCharUtil and other character functions use smaller types like
        int,unsigned, short, etc.  --like cmUtf32 
 
*/
#ifndef CMPOINTER64
    #if defined(_WIN32)
        #ifdef _WIN64
            #define CMPOINTER64 1
        #else
            #define CMPOINTER64 0
        #endif
    #else
        // GNU C++ hopefully defines __WORDSIZE
        #if defined(__WORDSIZE)
            #if __WORDSIZE==64
                #define CMPOINTER64 1
            #else
                #define CMPOINTER64 0
            #endif
        #elif defined(__LP64__) ||  defined(SUNSPARC64APP) || defined(LINUXAPP64) || defined(SOLARISX64APP)
            #define CMPOINTER64 1
        #else
            #define CMPOINTER64 0
        #endif
    #endif
#endif

#if CMPOINTER64
    #define cmint cmInt64
    #define cmuint cmUInt64
    #define cmUIntPtr cmUInt64
    #define cmIntPtr cmInt64

    #define CMPTRSIZE 8
    #define CMMAXCMINT 0x7fffffffffffffffLL
    #if CMUNIX
        #undef CMSIZE_T_IS_NEW_TYPE
        #define CMSIZE_T_IS_NEW_TYPE 1
        #include <sys/types.h>
    #endif
#else
    #define cmint int
    #define cmuint unsigned
    #define CMMAXCMINT 0x7fffffff
    #undef CMSIZE_T_IS_NEW_TYPE
    #define CMSIZE_T_IS_NEW_TYPE 0

    #define cmUIntPtr unsigned
    #define cmIntPtr int
    #define CMPTRSIZE 4
    #if CMUNIX
        #include <sys/types.h>
    #endif
#endif

#define CMPTR_DIFF32(f,l) ((int)(f-l))

#define cmSeekPos cmInt64

typedef void (*cmProcAddr)();


#define CMMAXUNSIGNED   0xffffffffU
#define CMMAXSHORT      (short)0x7fff
#define CMMAXUSHORT     (unsigned short)0xffff
#define CMMAXINT        0x7fffffff
#define CMMININT        (-CMMAXINT-1)
#define CMMAXINT64      0x7fffffffffffffffLL
#define CMMAXUINT64     0xFfffffffffffffffULL
#define CMMININT64      (-CMMAXINT64-1)
#define CMMAXSEEKPOS    CMMAXINT64


#define cmMin(a,b)  (((a)<=(b))?(a):(b))
#define cmMax(a,b)  (((a)>(b))?(a):(b))
#define cmAbs(a)    (((a)>=0)?(a):(-(a)))


template <class T,class T2>
static inline T cmRoundDown(T offset, T2 size) {
    return(offset- (offset%size ));
}
template <class T,class T2>
static inline T cmRoundUp(T offset, T2 size) {
    return(cmRoundDown(offset+size-1,size));
}

cmint cmMapError(cmint error,cmint default_error);

#ifdef __GNUC__
#define CMNORETURN __attribute__ ((noreturn))
#else
#define CMNORETURN
#endif

void cmThrow(cmint status) CMNORETURN;
void cmThrow(cmint status,const char *psz0) CMNORETURN;

// current limit of the number of wait objects is 64 (same as Windows for simplicity)
enum cmWaitStatus {
    cmWaitStatus_Success=0,   // Object is signled
    cmWaitStatus_Abandoned=0x80,  //Not  supported yet, Can only happen with a Mutex - WAIT_ABANDONED_0
    cmWaitStatus_IO_Completion=0xc0,  // Not supported yet - WAIT_IO_COMPLETION
    cmWaitStatus_Timeout=0x102,       // -WAIT_TIMEOUT
    cmWaitStatus_Interupt= -1,    // Not supported yet
    cmWaitStatus_WaitListTooLarger=-2, // This limit may eventually be removed.
    cmWaitStatus_WaitListContainsDuplicates=-3,
    cmWaitStatus_MonitorNotLockedByThisThread=-4,
    cmWaitStatus_InsufficientMemory=-5  // Only occurs in cmMonitor.wait
};

#if CMPOINTER64 && CMUNIX
   #undef CMSIZE_OF_LONG
   #define CMSIZE_OF_LONG 8
#endif

//typedef unsigned char cmByte;
//typedef unsigned char cmUtf8;
//typedef unsigned char cmAcp;
//typedef unsigned char cmAscii;  // 7-bit ascii operations, code page does not matter and ignore utf8
cmint cmStrLen(const char *psz);
cmint cmStrLen(const unsigned char *psz);
cmint cmStrLen(const wchar_t *psz);
typedef unsigned short cmUtf16;
typedef int cmUtf32;
#if CMSIZE_OF_WCHAR_T==4 || CMWCHAR_T_IS_2_BYTES_AND_DIFFERS_FROM_USHORT
   cmint cmStrLen(const cmUtf16 *psz);
#endif
#if CMSIZE_OF_WCHAR_T==2 || CMWCHAR_T_IS_4_BYTES_AND_DIFFERS_FROM_INT
   cmint cmStrLen(const cmUtf32 *psz);
#endif

enum cmFindEncoding {
    cmFindEncoding_Utf8 = 0,
    cmFindEncoding_ACP = 1,
    cmFindEncoding_Binary = 2
};
#define cmFindWordChars_RE_ACP  "[\\p{Ll}\\p{Lu}\\p{Lt}\\p{Lo}\\p{Nd}\\p{Pc}\\p{Lm}]"
#define cmFindWordChars_RE_Utf8 cmFindWordChars_RE_ACP

// Additional string options FM N , + < E 8 A Y
enum cmFindFlags:cmUInt64 {
    cmFindFlag_None                 = 0x00000000,   // I or FI
    cmFindFlag_IgnoreCase           = 0x00000001,   // I or FI
    cmFindFlag_E_Selection          = 0x00000002,   // M or S
    cmFindFlag_E_PlaceCursorAtEnd   = 0x00000004,   // >
    cmFindFlag_E_Backward           = 0x00000008,   // -
    // SlickEdit syntax regex, \n matches new-line sequence. Same in editor and grep but not string 
    // functions (like Slick-C pos())
    // For strings, this will match <CR><LF> <CR> and <LF> the way you expect.
    // For the editor and cmgrep, this will match that documents determined new-line seqence (not all new-line seqences).
    // Note that cmStrFindParseOptionString uses this RE flag for SlickEdit syntax regex
    cmFindFlag_BackslashN_Matches_NLChars_RE = 0x00000010,
    cmFindFlag_Word               = 0x00000020,   // W     Match whole word
    //cmFindFlag_UnixRE           = 0x00000040,   // U
    cmFindFlag_VIMRE              = 0x00000040,   // ~
    cmFindFlag_E_NoMessage        = 0x00000080,   // @     (Quiet) No status message
    cmFindFlag_Go                 = 0x00000100,   // *
    cmFindFlag_ReplaceAll = cmFindFlag_Go,
    cmFindFlag_E_Incremental      = 0x00000200,   // Editor internal option, not string option letter
    cmFindFlag_E_Wrap             = 0x00000400,   // P
    cmFindFlag_E_HiddenText       = 0x00000800,   // H
    cmFindFlag_E_ScrollStyle      = 0x00001000,   // S   When specified, use editor scroll style. Default is Center scroll style.
    cmFindFlag_E_Binary           = 0x00002000,   // Y
    //cmFindFlag_BriefRE          = 0x00004000,   // B
    cmFindFlag_E_PreserveCase     = 0x00008000,   // V
    cmFindFlag_WordPrefix         = 0x00010000,   // W:P   Match prefix
    cmFindFlag_WordSuffix         = 0x00020000,   // W:S   Match suffix
    cmFindFlag_WordStrict         = 0x00040000,   // W:SS or W:PS   Strict suffix or prefix match
    cmFindFlag_E_HiddenTextOnly   = 0x00080000,   // CH
    cmFindFlag_E_NoSaveText       = 0x00100000,   // (Off by default)
    cmFindFlag_E_NoSaveTextOnly   = 0x00200000,   // CV
    cmFindFlag_E_PromptWhenWrap   = 0x00400000,   // ?
    cmFindFlag_E_HighlightFind    = 0x00800000,   // #
    cmFindFlag_E_HighlightReplace = 0x01000000,   // $
    cmFindFlag_WildcardRE         = 0x02000000,   // &    Support ? * # \ same as Visual Studio
    cmFindFlag_PerlRE             = 0x04000000|0x4000,   // L, U, B, Perl syntax. /* old Brief specify Perl too */
    cmFindFlag_E_ScrollHighlight  = 0x08000000,   // %
    cmFindFlag_E_SelectionOnlyCheckBeginning  = 0x10000000, // (
    cmFindFlag_E_MultiSelect     = 0x20000000, // |
    cmFindFlag_IsWord             =  cmFindFlag_Word|cmFindFlag_WordPrefix|cmFindFlag_WordSuffix,


    // Only affects SlickEdit syntax regex.
    // Force \n in SlickEdit regex to match the single byte \x0a instead of any new-line sequence.
    // Needed for backward compaitibility with old SlickEdit syntax string (not buffer or grep) searching.
    // For backward compatibility, Slick-C string functions must use this option.
    // Use \R to match any new-line sequence. Used by most string functions. 
    // Note that cmStrFindParseOptionString will never add this flag!
    cmFindFlag_BackslashN_Matches_Byte= 0x100000000, 
    // SlickEdit syntax regex, \n matches byte 0x0a. For backward compatibility with old code for string functions. 
    // Use \R to match any new-line sequence. Used by most string functions. 
    // For backward compatibility, Slick-C string functions must use this option.
    // Note that cmStrFindParseOptionString will not select these flags!
    cmFindFlag_BackslashN_Matches_Byte_RE    = cmFindFlag_BackslashN_Matches_NLChars_RE|cmFindFlag_BackslashN_Matches_Byte,


    //FM  When on, $ matches EOL
    //    When on, ^ matches BOL
    //    When off, ^ matches BOF and not BOL
    //    When off, $ matches EOF and not EOL
    cmFindFlag_PerlMultiLine          = 0x0200000000,    // FM
    //FS  When on (flag not present), .+ matches across line boundaries
    //    When on (flag not present), . matches an any character including \r and \n bytes
    cmFindFlag_PerlNotSingleLine      = 0x0400000000,    // FS
    cmFindFlag_MultiLine = cmFindFlag_PerlMultiLine|cmFindFlag_PerlNotSingleLine,
    cmFindFlag_ExplicitCapture        = 0x0800000000,    //FN
    cmFindFlag_IgnoreComments         = 0x1000000000,   
    cmFindFlag_IgnorePatternWhiteSpace  = 0x2000000000|cmFindFlag_IgnoreComments, // FX

    /* This is reserved for internal use by the regex engine.
       This is used for look behind assertions and for
       for searching backwards when possible.
    */
    cmFindFlag_Internal_CompileRev     = 0x4000000000,
    /* This is reserved for internal use by the regex engine.
       This is used for look ahead assertions. Can't
       use reverse compiled code for a subroutine
       defined in a positive assertion.
          (?=(?<sub1>...))
    */
    cmFindFlag_Internal_CompileForward = 0x8000000000,
    /* This is reserved for internal use by the regex engine.
       To handle (?&foo) and (?digits).
       Could implement this a different way and remove this
       flag.
    */
    cmFindFlag_Internal_TagNameLookAhead=0x010000000000,

    // Default string searching to single line to handle binary data.
    // Note: Editor buffer searching defaults to multi-line
    cmFindFlag_Default            = cmFindFlag_E_HiddenText,
    cmFindFlag_Null              = (cmUInt64)-1,
    cmFindFlag_IsRE               = cmFindFlag_BackslashN_Matches_NLChars_RE | cmFindFlag_PerlRE | cmFindFlag_WildcardRE| cmFindFlag_VIMRE,
};
CM_DECLARE_OPERATORS_FOR_ENUM_FLAGS64(cmFindFlags);

CMEXTERN_C void xprintf(const char *s, ...);
CMEXTERN_C void mprintf(const char *s, ...);
CMEXTERN_C void dfprintf(const char *s,...);

#if CMPATHSEP==':'
    #define CMPATHSEP_RE "\\:~(//)"
#else
    #define CMPATHSEP_RE ";"
#endif

#if CMWINDOWS
    #ifndef CM_HAVE_ATOMIC
        #define CM_HAVE_ATOMIC 1
    #endif
    #ifndef CM_ATOMIC_INTEGER_DEFINED
    #define CM_ATOMIC_INTEGER_DEFINED
        typedef long cmAtomicInt32;
        typedef long long cmAtomicInt64;
    #endif
#elif CMMACOSX
    #ifndef CM_HAVE_ATOMIC
        #define CM_HAVE_ATOMIC 1
    #endif
    #ifndef CM_ATOMIC_INTEGER_DEFINED
    #define CM_ATOMIC_INTEGER_DEFINED
        typedef signed int cmAtomicInt32;
        typedef int64_t    cmAtomicInt64;
    #endif
#elif CMUNIX
    #ifndef CM_HAVE_ATOMIC
        #define CM_HAVE_ATOMIC 1
    #endif
    #ifndef CM_ATOMIC_INTEGER_DEFINED
    #define CM_ATOMIC_INTEGER_DEFINED
        typedef signed int cmAtomicInt32;
        typedef signed long long int cmAtomicInt64;
    #endif
#else
    #ifndef CM_HAVE_ATOMIC
        #define CM_HAVE_ATOMIC 0
    #endif
#endif

#if CM_HAVE_STD_MOVE
    #include <type_traits>
    #define cmMove(x)    std::move(x)
    #define cmSwap(x,y)  std::swap(x,y)
    #define cmForward(x) std::forward<decltype(x)>(x)
#else

    /**
     * Utility class for evaluating an integral constant of type T at compile time. 
     * Primarily used to define {@link cmTrueType} and {@link cmFalseType}. 
     */
    template <class T, T v>
    struct cmIntegralConstant
    {
        static constexpr T value = v;
        typedef T value_type;
        typedef cmIntegralConstant type;
        constexpr operator value_type() const {return value;}
    };
    template <class T, T v>
    const T cmIntegralConstant<T, v>::value;

    /**
     * cmTrueType::value === true
     */
    typedef cmIntegralConstant<bool, true>  cmTrueType;
    /**
     * cmFalseType::value === false
     */
    typedef cmIntegralConstant<bool, false> cmFalseType;

    struct cmSubstutionFailureIsNotAnError
    {
        typedef char t_one;
        typedef struct { char m_arr[2]; } t_two;
    };

    /**
     * Utility template class to test if a type is an array (or pointer) type.
     * @param <T>   type to test
     */
    template<typename T> struct cmInArray : public cmSubstutionFailureIsNotAnError
    {
    private:
        template<typename _Up> static t_one m_test(_Up(*)[1]);
        template<typename>     static t_two m_test(...);

    public:
        static const bool value = sizeof(m_test<T>(0)) == 1;
    };

    /**
     * Helper Utility class to test if a type is a union or class type.
     * @param <T>   type to test
     */
    template<typename T>
    struct cmIsUnionOrClassHelper : public cmSubstutionFailureIsNotAnError
    {
    private:
        template<typename _Up> static t_one m_test(int _Up::*);
        template<typename>     static t_two m_test(...);
    public:
        static const bool value = sizeof(m_test<T>(0)) == 1;
    };

    /**
     * Utility template class to test if a type is a union or class type.
     * @param <T>   type to test
     */
    template<typename T> 
    struct cmIsUnionOrClass : public cmIntegralConstant<bool, cmIsUnionOrClassHelper<T>::value>
    { 
    };

    /**
     * Utility template class to test if a type is abstract (and therefore, 
     * can not be instantiated). 
     * @param <T>   type to test
     */
    template<typename T> struct cmIsAbstract : public cmIntegralConstant<bool, (!cmInArray<T>::value && cmIsUnionOrClass<T>::value)> 
    { 
    };

    /**
     * Utility template class for testing if a type is a l-value reference type. 
     * @example 
     * <pre> 
     *      cmIsLValueReference&lt;int&gt;::value === false
     *      cmIsLValueReference&lt;int&amp;&gt;::value === true
     *      cmIsLValueReference&lt;void*&gt;::value === false
     *      cmIsLValueReference&lt;cmStringUtf8&amp;&gt;::value === true
     * </pre>
     */
    template <class T> struct cmIsLValueReference     : public cmFalseType {};
    template <class T> struct cmIsLValueReference<T&> : public cmTrueType  {};

    /**
     * Utility template class for testing if a type is a r-value reference type. 
     * @example 
     * <pre> 
     *      cmIsRValueReference&lt;int&gt;::value === false
     *      cmIsRValueReference&lt;int&amp;&gt;::value === false
     *      cmIsRValueReference&lt;int&amp;&amp;&gt;::value === true
     *      cmIsRValueReference&lt;void*&gt;::value === false
     *      cmIsRValueReference&lt;cmStringUtf8&amp;&amp;&gt;::value === true
     * </pre>
     */
    template <class T> struct cmIsRValueReference      : public cmFalseType {};
    template <class T> struct cmIsRValueReference<T&&> : public cmTrueType  {};

    /**
     * Utility template class for testing if a type is a reference type. 
     * @example 
     * <pre> 
     *      cmIsReference&lt;int&gt;::value === false
     *      cmIsReference&lt;int&amp;&gt;::value === true
     *      cmIsReference&lt;int&amp;&amp;&gt;::value === true
     *      cmIsReference&lt;void*&gt;::value === false
     *      cmIsReference&lt;cmStringUtf8&amp;&gt;::value === true
     *      cmIsReference&lt;cmStringUtf8&amp;&amp;&gt;::value === true
     * </pre>
     */
    template <class T> struct cmIsReference            : public cmFalseType {};
    template <class T> struct cmIsReference<T&>        : public cmTrueType  {};
    template <class T> struct cmIsReference<T&&>       : public cmTrueType  {};

    /**
     * Utility template class for removing any reference qualification from a type. 
     * @example 
     * <pre> 
     *      cmRemoveReference&lt;int&gt;::type === int
     *      cmRemoveReference&lt;int&amp;&gt;::type === int
     *      cmRemoveReference&lt;int&amp;&amp;&gt;::type === int
     *      cmRemoveReference&lt;void*&gt;::type === void*
     *      cmRemoveReference&lt;cmStringUtf8&amp;&gt;::type === cmStringUtf8
     *      cmRemoveReference&lt;cmStringUtf8&amp;&amp;&gt;::type === cmStringUtf8
     * </pre>
     */
    template <class T> struct cmRemoveReference      {typedef T type;};
    template <class T> struct cmRemoveReference<T&>  {typedef T type;};
    template <class T> struct cmRemoveReference<T&&> {typedef T type;};

    /**
     * Template function for forcing an item to be treated as an r-value reference. 
     * This allows code to select the move constructor or move assignemnt operator 
     * to improve effeciency.
     * @example 
     * <pre> 
     *     void add_guitar_strings(cmArray&lt;cmArray&lt;cmStringUtf8&gt;&gt; &arrayOfArrays) {
     *         cmArray&lt;cmStringUtf8&gt; a;
     *         a.add("this is one string"_cm); 
     *         a.add("this is another string"_cm); 
     *         a.add("this is yet another string"_cm); 
     *         a.add("this is a fourth string"_cm); 
     *         a.add("this is a fifth string"_cm); 
     *         a.add("with this string, we have enough to make a guitar"_cm);
     *         anotherArray.add(cmMove(a));
     *     }
     * </pre>
     */
    template<class T> 
    typename cmRemoveReference<T>::type && cmMove(T&& a) noexcept
    {
        typedef typename cmRemoveReference<T>::type&& RValueReferenceForT;
        return static_cast<RValueReferenceForT>(a);
    } 

    /**
     * Template function to make use of move constructor and move assignment 
     * operators to swap the values of two items. 
     */
    template <class T>
    inline void cmSwap(T& x, T& y) {
        T tmp(cmMove(x));
        x = cmMove(y);
        y = cmMove(tmp);
    }

    /**
     * Utility template class to either enable or disable whether a particular 
     * template is selected based on the statically evaluate value of a condition. 
     */
    template <bool, class T=void> struct cmEnableIf {};
    template <class T> struct cmEnableIf<true,T> {typedef T type;};

    /**
     * Utility template class to either enable or disable whether a particular 
     * template is selected based on the statically evaluate value of a condition. 
     */
    template <bool, class T=void> struct cmDisableIf {};
    template <class T> struct cmDisableIf<false,T> {typedef T type;};

    /**
     * Utility template class to determine if two types are the same. 
     * @example 
     * <pre> 
     *     cmIsSame&lt;int,int&gt;>::value === true
     *     cmIsSame&lt;int,int&amp;&gt;>::value === false
     *     cmIsSame&lt;int,float&gt;>::value === false
     * </pre>
     */
    template <class T,class U> struct cmIsSame      : public cmFalseType {};
    template <class T>         struct cmIsSame<T,T> : public cmTrueType  {};

    /**
     * Utility class to check if a type is const qualified
     * @example 
     * <pre> 
     *     cmIsConst&lt;const char&gt;>::value === true
     *     cmIsConst&lt;float&gt;>::value === false
     * </pre>
     */
    template <class T> struct cmIsConst          : public cmFalseType {};
    template <class T> struct cmIsConst<T const> : public cmTrueType  {};

    /**
     * Utility class to check if a type is volatile qualified
     * @example 
     * <pre> 
     *     cmIsVolatile&lt;volatile char&gt;>::value === true
     *     cmIsVolatile&lt;float&gt;>::value === false
     * </pre>
     */
    template <class T> struct cmIsVolatile             : public cmFalseType {};
    template <class T> struct cmIsVolatile<T volatile> : public cmTrueType  {};

    /**
     * Utility template for remove const qualification from a type. 
     * @example 
     * <pre> 
     *     cmRemoveConst&lt;const char&gt;>::type === char
     *     cmRemoveConst&lt;float&gt;>::type === float
     * </pre>
     */
    template<typename _Tp> struct cmRemoveConst            { typedef _Tp type; };
    template<typename _Tp> struct cmRemoveConst<_Tp const> { typedef _Tp type; };

    /**
     * Utility template for remove volatile qualification from a type. 
     * @example 
     * <pre> 
     *     cmRemoveVolatile&lt;volatile char&gt;>::type === char
     *     cmRemoveVolatile&lt;float&gt;>::type === float
     * </pre>
     */
    template<typename _Tp> struct cmRemoveVolatile               { typedef _Tp type; };
    template<typename _Tp> struct cmRemoveVolatile<_Tp volatile> { typedef _Tp type; };

    /**
     * Utility template for removing both const and volatile qualification from a type.
     * @example 
     * <pre> 
     *     cmRemoveCV&lt;const char&gt;>::type === char
     *     cmRemoveCV&lt;volatile char&gt;>::type === char
     *     cmRemoveCV&lt;float&gt;>::type === float
     * </pre>
     */
    template<typename _Tp>
    struct cmRemoveCV {
      typedef typename cmRemoveConst<typename cmRemoveVolatile<_Tp>::type>::type type;
    };

    /**
     * Utility template for adding const qualification to a type.
     */
    template<typename _Tp> struct cmAddConst    { typedef _Tp const type; };

    /**
     * Utility template for adding volatile qualification to a type.
     */
    template<typename _Tp> struct cmAddVolatile { typedef _Tp volatile type; };

    /**
     * Utility template for adding both const and volatile qualification to a type.
     */
    template<typename _Tp> 
    struct cmAddCV {
        typedef typename cmAddConst<typename cmAddVolatile<_Tp>::type>::type type;
    };
    
    /**
     * Utility template for removing any reference qualification and any const 
     * or volatile qualification from a type. 
     * @example 
     * <pre>
     *     cmBaseType&lt;const char&amp;&gt;::type ==== char
     *     cmBaseType&lt;float&amp;&amp;&gt;::type ==== float
     *     cmBaseType&lt;cmFatStringUtf8&gt;::type ==== cmFatStringUtf8
     * </pre>
     */
    template <class T>
    struct cmBaseType
    {
        typedef typename cmRemoveCV<typename cmRemoveReference<T>::type>::type type;
    };

    /**
     * Utility template function to test if a pointer is convertable to a 
     * given base type.
     */
    template <typename B> cmTrueType  cmIsPointerConvertible(const volatile B*);
    template <typename>   cmFalseType cmIsPointerConvertible(const volatile void*);

    /**
     * Utility template class to determine if two pointer types are the same or 
     * related by inheritance. 
     * 
     * @param <Base>       base class to check for compatibility with
     * @param <Derived>    candidate class to check if it is derived
     */
    template<typename, typename> struct cmIsBaseOf;
#if !CMWINDOWS
    template <typename Base, typename Derived>
    struct cmIsBaseOf : public cmIntegralConstant<bool, decltype(cmIsPointerConvertible<Base>(static_cast<typename cmBaseType<Derived>::type *>(nullptr)))::value> { };
#else
    template <typename Base, typename Derived>
    struct cmIsBaseOf : public cmIntegralConstant<bool, __is_base_of(Base,Derived)> { };
#endif

    /**
     * Utility function for performing perfect forwarding of an r-value type to 
     * a function that takes an r-value type as an argument. 
     *  
     * @example 
     * <pre> 
     *     void addItem(Item &amp;&amp; it) {
     *         m_queue.add(cmForward(it));
     *     }
     * </pre>
     */
    template <class T, class U,
              class = typename cmEnableIf<(cmIsLValueReference<T>::value ? cmIsLValueReference<U>::value : true) &&
                                          cmIsSame<typename cmBaseType<T>::type, typename cmBaseType<U>::type>::value
                                          >::type>
    inline T&& cmForward(U&& u)
    {
        static_assert(!cmIsRValueReference<U>::value,
                      "Can not forward an rvalue as an lvalue.");
        return static_cast<T&&>(u);
    }

    /**
     * Convenience macro so that you can forward without specifying the 
     * type name argument, for the common case where you are not forwarding 
     * a dissimilar type. 
     */
    #define cmForward(x) cmForward<decltype(x)>(x)

     
#endif

