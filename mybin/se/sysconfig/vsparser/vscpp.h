/////////////////////////////////////////////////////////////////////////////
// Microsoft-Specific Predefined Macros
/////////////////////////////////////////////////////////////////////////////

/**
 * _ATL_VER Defines the ATL version.
 */
#define _ATL_VER 0x0300

/**
 * _CHAR_UNSIGNED Default char type is unsigned.  Defined when /J is
 * specified.
 */
#undef _CHAR_UNSIGNED

/**
 * __COUNTER__ Expands to an integer starting with 0 and incrementing by 1
 * every time it is used in a compiland.  __COUNTER__ remembers its state
 * when using precompiled headers.  If the last __COUNTER__ value was 4 after
 * building a precompiled header (PCH), it will start with 5 on each PCH use.
 * <p>
 * __COUNTER__ lets you generate unique variable names.  You can use token
 * pasting with a prefix to make a unique name.  For example:
 * <pre>
 *    #include <stdio.h>
 *    #define FUNC2(x,y) x##y
 *    #define FUNC1(x,y) FUNC2(x,y)
 *    #define FUNC(x) FUNC1(x,__COUNTER__)
 *
 *    int FUNC(my_unique_prefix);
 *    int FUNC(my_unique_prefix);
 *
 *    void main() {
 *       my_unique_prefix0 = 0;
 *       printf("\n%d",my_unique_prefix0);
 *       my_unique_prefix0++;
 *       printf("\n%d",my_unique_prefix0);
 *    }
 * </pre>
 */
#define __COUNTER__ 0

/**
 * Defined if you include any of the C++ Standard Library headers;
 * reports which version of the Dinkumware header files are present.
 */
//#define _CPPLIB_VER 1

/**
 * _CPPRTTI Defined for code compiled with /GR (Enable Run-Time Type
 * Information).
 */
#undef _CPPRTTI

/**
 * _CPPUNWIND Defined for code compiled with /GX (Enable Exception Handling).
 */
#define _CPPUNWIND 1

/**
 * _DEBUG Defined when compiling with /LDd, /MDd, /MLd, and /MTd.
 */
#undef _DEBUG

/**
 * _DLL Defined when /MD or /MDd (Multithread DLL) is specified.
 */
#undef _DLL

/**
 * __FUNCDNAME__ Valid only within a function and returns the decorated name
 * of the enclosing function (as a string).  __FUNCDNAME__ is not expanded if
 * you use the /EP or /P compiler option.
 */
//#define __FUNCDNAME__ ""

/**
 * __FUNCSIG__ Valid only within a function and returns the signature of the
 * enclosing function (as a string).  __FUNCSIG__ is not expanded if you use
 * the /EP or /P compiler option.
 */
//#define __FUNCSIG__ ""

/**
 * __FUNCTION__ Valid only within a function and returns the undecorated name
 * of the enclosing function (as a string).  __FUNCTION__ is not expanded if
 * you use the /EP or /P compiler option.
 */
//#define __FUNCTION__ __func__

/**
 * _M_ALPHA Defined for DEC ALPHA platforms.  It is defined as 1 by the ALPHA
 * compiler, and it is not defined if another compiler is used.
 */
#undef _M_ALPHA

/**
 * _M_IX86 Defined for x86 processors. See Values for _M_IX86 for more details.
 * <p>
 * As shown in following table, the compiler generates a value for the
 * preprocessor identifiers that reflect the processor option specified.
 * <p>
 * Values for _M_IX86
 * <p>
 * Option in Development Environment Command-Line Option Resulting Value
 * <p>
 * Blend /GB _M_IX86 = 600 (Default.  Future compilers will emit a different
 * value to reflect the dominant processor.)
 * <ul>
 * <li>Pentium /G5 _M_IX86 = 500
 * <li>Pentium Pro, Pentium II, and Pentium III /G6 _M_IX86 = 600
 * <li>80386 /G3 _M_IX86 = 300
 * <li>80486 /G4 _M_IX86 = 400
 * </ul>
 */
#define _M_IX86 600
#define _M_I86  600
#define M_I86   600

/**
 * _M_IA64 Defined for 64-bit processors.
 */
#undef _M_IA64

/**
 * _M_MPPC Defined for Power Macintosh platforms (no longer supported).
 */
#undef _M_MPPC

/**
 * _M_MRX000 Defined for MIPS platforms (no longer supported).
 */
#undef _M_MRX000

/**
 * _M_PPC Defined for PowerPC platforms (no longer supported).
 */
#undef _M_PPC

/**
 * _MANAGED Defined to be 1 when /clr is specified.
 */
#undef _MANAGED

/**
 * _MFC_VER Defines the MFC version. For example, 0x0700 represents MFC version 7.
 */
#define _MFC_VER 0x0700

/**
 * _MSC_EXTENSIONS This macro is defined when compiling with the /Ze compiler
 * option (the default).  Its value, when defined, is 1.
 */
#define _MSC_EXTENSIONS 1

/**
 * _MSC_VER Defines the major and minor versions of the compiler.  For
 * example, 1300 for Microsoft Visual C++ .NET.  1300 represents version 13
 * and no point release.  This represents the fact that there have been a
 * total of 13 releases of the compiler.
 * <p>
 * If you type cl /?  at the command line, you will see the full version for
 * the compiler you are using.
 */
#define _MSC_VER 1300

/**
 * __MSVC_RUNTIME_CHECKS Defined when one of the /RTC compiler options is specified.
 */
#undef __MSVC_RUNTIME_CHECKS

/**
 * _MT Defined when /MD or /MDd (Multithreaded DLL) or /MT or /MTd (Multithreaded) is specified.
 */
#define _MT 1

/**
 * _WCHAR_T_DEFINED Defined when wchar_t is defined.  Typically, wchar_t is
 * defined when you use /Zc:wchar_t or when typedef unsigned short wchar_t;
 * is executed in code.
 */
#define _WCHAR_T_DEFINED        1

/**
 * Visual SlickEdit considers wchar_t to be a builtin type.  To revert
 * to the behavior where wchar_t is really an unsigned short, add this
 * #define to your project:  VSE_NO_NATIVE_WCHAR_T
 */
#define VSE_NO_NATIVE_WCHAR_T // For now, mimic the Visual Studio default
#ifdef VSE_NO_NATIVE_WCHAR_T
   #define _NATIVE_WCHAR_T_DEFINED 0
   typedef unsigned short __wchar_t;
   #define wchar_t __wchar_t
#else
   #define _NATIVE_WCHAR_T_DEFINED 1
   typedef wchar_t __wchar_t;
#endif

/**
 * _WIN32 Defined for applications for Win32 and Win64. Always defined.
 */
#define _WIN32 1

/**
 * _WIN64 Defined for applications for Win64.
 */
#undef _WIN64

/**
 * _Wp64 Defined when specifying /Wp64.
 */
#undef _Wp64

/**
 * _INTEGRAL_MAX_BITS Defined as 64 when the __int64 keyword is available,
 */
#define _INTEGRAL_MAX_BITS 64

/////////////////////////////////////////////////////////////////////////////
// Microsoft-Specific Keywords
/////////////////////////////////////////////////////////////////////////////

/**
 * Declares a managed class that cannot be instantiated directly.
 */
#define __abstract

/**
 * Returns a value, of type size_t, that is the alignment requirement of the type.
 */
#define __alignof(type)  2

/**
 * The __asm keyword invokes the inline assembler and can appear wherever
 * a C or C++ statement is legal.  It cannot appear by itself.  It must be
 * followed by an assembly instruction, a group of instructions enclosed
 * in braces, or, at the very least, an empty pair of braces.  The term
 * "__asm block" here refers to any instruction or group of instructions,
 * whether or not in braces.
 */
//#define __asm asm
#define _asm asm

/**
 * The __assume compiler intrinsic passes a hint to the optimizer.  The
 * optimizer assumes that the condition represented by expression is true
 * at the point where the keyword appears and remains true until
 * expression is altered (for example, by assignment to a variable).
 * Selective use of hints passed to the optimizer by __assume can improve
 * optimization.
 */
#define __assume(arg)

/**
 * The __based keyword allows you to declare pointers based on pointers
 * (pointers that are offsets from existing pointers).
 */
#define __based(base)

/**
 * Creates a managed copy of a __value class object.
 */
#define __box(object)  object

/**
 * This is the default calling convention for C and C++ programs.  Because
 * the stack is cleaned up by the caller, it can do vararg functions.  The
 * __cdecl calling convention creates larger executables than __stdcall,
 * because it requires each function call to include stack cleanup code.
 * The following list shows the implementation of this calling convention.
 */
#define __cdecl
#define _cdecl

/**
 * The extended attribute syntax for specifying storage-class information
 * uses the __declspec keyword, which specifies that an instance of a
 * given type is to be stored with a Microsoft-specific storage-class
 * attribute listed below.  Examples of other storage-class modifiers
 * include the static and extern keywords.  However, these keywords are
 * part of the ANSI specification of the C and C++ languages, and as such
 * are not covered by extended attribute syntax.  The extended attribute
 * syntax simplifies and standardizes Microsoft-specific extensions to the
 * C and C++ languages.
 */
#define __declspec(modifiers)
#define _declspec(modifiers)

/**
 * Defines a reference type that can be used to encapsulate a method
 * with a specific signature.
 */
#define __delegate

/**
 * Declares an event.
 */
#define __event

/**
 * The try-except statement is a Microsoft extension to the C and C++
 * languages that enables 32-bit target applications to gain control when
 * events that normally terminate program execution occur.  Such events
 * are called exceptions, and the mechanism that deals with exceptions is
 * called structured exception handling.
 */
//#define __try     try
//#define __except  catch
//#define __finally
//#define finally __finally

/**
 * The __fastcall calling convention specifies that arguments to functions
 * are to be passed in registers, when possible.
 */
#define __fastcall
#define _fastcall

/**
 * This is the default calling convention used by C++ member functions
 * that do not use variable arguments. Under __thiscall, the callee cleans
 * the stack, which is impossible for vararg functions. Arguments are pushed
 * on the stack from right to left, with the this pointer being passed via
 * register ECX on the x86 architecture.
 */
#define __thiscall

/**
 * The inline and __inline specifiers instruct the compiler to insert a copy
 * of the function body into each place the function is called.
 */
#define _inline       inline
#define __inline      inline
#define __forceinline inline

/**
 * A __gc type is a C++ language extension that simplifies .NET Framework
 * programming by providing features such as interoperability and garbage
 * collection.
 */
#define __gc

/**
 * Associates a handler method with an event.
 */
#define __hook(method,source,handler,receiver)
#define __hook(interface,source)

/**
 * The __identifier keyword enables the use of C++ keywords as identifiers.
 * The main purpose of this keyword is to allow managed classes to access
 * and use external classes that may use a C++ keyword as an identifier.
 *
 * NOTE:  The Refactoring Engine handles this language extension.
 */
//#define __identifier(id)  id

/**
 * __if_exists allows you to conditionally include code depending on
 * whether the specified symbol exists.
 *
 * NOTE:  The Refactoring Engine handles this language extension.
 */
//#define __if_exist(variable)

/**
 * __if_not_exists allows you to conditionally include code depending
 * on whether the specified symbol does not exist.
 *
 * NOTE:  The Refactoring Engine handles this language extension.
 */
//#define __if_not_exist(variable)

/**
 * Microsoft C/C++ features support for sized integer types.  You can
 * declare 8-, 16-, 32-, or 64-bit integer variables by using the __intn
 * type specifier, where n is 8, 16, 32, or 64.
 */
#define __int8    char
#define __int16   short
#define __int32   int
#define __int64   long long

#define _int8     char
#define _int16    short
#define _int32    int
#define _int64    long long

/**
 * Needed for Visual Studio 2005
 */
#define __ptr64

/**
 * A Visual C++ interface can be defined as follows:
 * <ul>
 * <li>Can inherit from zero or more base interfaces.
 * <li>Cannot inherit from a base class.
 * <li>Can only contain public, pure virtual methods.
 * <li>Cannot contain constructors, destructors, or operators.
 * <li>Cannot contain static methods.
 * <li>Cannot contain data members; properties are allowed.
 * </ul>
 */
#define __interface struct
#define interface   struct

/**
 * The __leave keyword is valid within a try-finally statement block.  The
 * effect of __leave is to jump to the end of the try-finally block.  The
 * termination handler is immediately executed.  Although a goto statement
 * can be used to accomplish the same result, a goto statement causes
 * stack unwinding.  The __leave statement is more efficient because it
 * does not involve stack unwinding.
 */
//#define __leave break

/**
 * The __m64 data type, for use with the MMX and 3DNow! intrinsics.
 * data_types__m64.cpp
 */
union __m64
{
   unsigned __int64 m64_u64;
   float m64_f32[2];
   __int8 m64_i8[8];
   __int16 m64_i16[4];
   __int32 m64_i32[2];
   __int64 m64_i64;
   unsigned __int8 m64_u8[8];
   unsigned __int16 m64_u16[4];
   unsigned __int32 m64_u32[2];
};

/**
 * The __m128 data type, for use with the Streaming SIMD Extensions and
 * Streaming SIMD Extensions 2 instructions intrinsics.
 */
struct __m128 {
   float m128_f32[4];
};

/**
 * The __m128d data type, for use with the Streaming SIMD Extensions
 * 2 instructions intrinsics
 */
struct __m128d {
   double m128d_f64[2];
};

/**
 * The __m128i data type, for use with the Streaming SIMD Extensions 2
 * (SSE2) instructions intrinsics:
 */
 union __m128i {
   __int8 m128i_i8[16];
   __int16 m128i_i16[8];
   __int32 m128i_i32[4];
   __int64 m128i_i64[2];
   unsigned __int8 m128i_u8[16];
   unsigned __int16 m128i_u16[8];
   unsigned __int32 m128i_u32[4];
   unsigned __int64 m128i_u64[2];
};

/**
 * C++ allows you to declare a pointer to a class member prior
 * to the definition of the class.
 * <pre>
 *    class S;
 *    int S::*p;
 * </pre>
 * <p>
 * In the code above, p is declared to be a "pointer to integer member of
 * class S".  However, class S has not yet been defined in this code; it
 * has only been declared.  When the compiler encounters such a pointer,
 * it must make a generalized representation of the pointer.  The size of
 * the representation is dependent on the inheritance model specified.
 * There are four ways to specify an inheritance model to the compiler:
 */
#define __multiple_inheritance
#define __single_inheritance
#define __virtual_inheritance

/**
 * Explicitly declares an unmanaged type.
 */
#define __nogc

/**
 * The __noop intrinsic specifies that a function should be ignored and
 * the argument list unevaluated.  It is intended for use in global debug
 * functions that take a variable number of arguments.
 */
int __noop(...);

/**
 * Prevents an object or embedded object of a managed class from being
 * moved by the common language runtime during garbage collection.
 */
#define __pin

/**
 * The __pragma macro is commonly used during parsing in ATL.
 */
#define __pragma(x)

/**
 * The _Pragma macro is part of the C99 standard
 */
#define _Pragma(x)

/**
 * Declares either a scalar or indexed property for the managed class.
 */
#define __property

/**
 * Emphasizes the call site of an event.
 */
#define __raise

/**
 * Prevents a method from being overridden or a class from being a base class.
 */
#define __sealed

/**
 * The __stdcall calling convention is used to call Win32 API functions.
 * The callee cleans the stack, so the compiler makes vararg functions
 * __cdecl.  Functions that use this calling convention require a function
 * prototype.
 */
#define __stdcall
#define _stdcall

/**
 * The __super keyword allows you to explicitly state that you are calling
 * a base-class implementation for a function that you are overriding.
 * All accessible base-class methods are considered during the overload
 * resolution phase, and the function that provides the best match is the
 * one that is called.
 */
#define __super

/**
 * Performs the specified cast or throws an exception if the cast fails.
 */
#define __try_cast dynamic_cast

/**
 * Dissociates a handler method from an event.
 */
#define __hook(method,source,handler,receiver)
#define __hook(interface,source)

/**
 * The __uuidof keyword retrieves the GUID attached to the expression.
 */
#define __uuidof(expression) (*((GUID*)0))

/**
 * Declares a class to be a __value type.
 */
#define __value

/**
 * The __w64 keyword lets you mark variables, such that when you compile
 * with /Wp64 the compiler will report any warnings that would be reported
 * if you were compiling with a 64-bit compiler.
 */
#define __w64

/////////////////////////////////////////////////////////////////////////////
// Microsoft-Specific Preprocessor Macros
/////////////////////////////////////////////////////////////////////////////

/**
 * Always defined for 16-bit compilation environments.
 * Identifies target machine as a member of the 8086 family.
 */
#undef M_I86
#undef _M_I86

/**
 * Always defined for 16-bit compilation environments.
 * Always defined. Identifies target operating system as MS-DOS.
 */
#undef MSDOS
#undef _MSDOS

/**
 * Always defined for 16-bit compilation environments.
 * Member of the I86 processor family.
 * <ul>
 * <li>m = T   Tiny
 * <li>S   Small (default)
 * <li>C   Compact model
 * <li>M   Medium model
 * <li>L   Large model
 * <li>H   Huge model
 * </ul>
 * <p>
 * Macros defined by /AT, /AS, /AC, /AM, /AL, and /AH respectively.
 */
#undef M_I86mM
#undef _M_I86mM

/**
 * 8088 or 8086 processor; default or defined when /G0 is specified.
 */
#undef M_I8086
#undef _M_I8086

/**
 * 80286 processor. Macro defined when /G1 or /G2 is specified.
 */
#undef M_I286
#undef _M_I286

/**
 * Disables Microsoft-specific language extensions
 * and extended keywords; defined only with /Za option.
 */
#undef NO_EXT_KEYS

/**
 * Supported for compatibility with Microsoft C version
 * 6.0. The _FAST macro (or /f) is the default and is
 * the recommended alternative.
 */
#undef _QC

/**
 * Code for run-time library as a dynamic-link library.
 * Defined when /MD is specified.
 */
#undef _DLL

/**
 * Fast-Compile. Macro defined when /f is specified
 * Supersedes _QC, which is still supported but not
 * recommended. Using /Od causes CL to compile your
 * program with /f. The /f option compiles source files
 * without any default optimizations.
 */
#undef _FAST

/**
 * Full conformance with the ANSI C standard. Defined
 * the integer constant 1 only if the /Za command-line
 * option is given; otherwise is undefined.
 */
#define __STDC__ 0

/**
 * Defined for sections of code that are compiled as
 * p-code. Macro defined when /Oq is enabled.
 */
#undef _PCODE

/**
 * Windows protected-mode dynamic-link library is
 * selected with /GD.
 */
#undef _WINDLL

/**
 * Windows protected-mode is selected with /GA, /Gw,
 * /GW, /Mq, or /GD.
 */
#undef _WINDOWS


/////////////////////////////////////////////////////////////////////////////
// Microsoft-Specific Preprocessor Macros
/////////////////////////////////////////////////////////////////////////////

/**
 * Most function prototypes in the standard CRT header files are prefaced
 * with the _CRTIMP symbol.  When code is compiled without the /MD switch
 * and the _DLL symbol is not defined, _CRTIMP is therefore defined to be
 * nothing.  However, when code is compiled with the /MD switch and _DLL
 * is defined, _CRTIMP is defined to be __declspec(dllimport).  The
 * __declspec(dllimport) tells the compiler that this routine actually
 * resides in a DLL.  For example, the following is the prototype in IO.H
 * for the _commit CRT function:
 */
#define _CRTIMP

/////////////////////////////////////////////////////////////////////////////
// #defines from WinResrc.h
/////////////////////////////////////////////////////////////////////////////

//#define WINVER 0x0500
//#define _WIN32_IE 0x0501
//#define _WIN32_WINDOWS 0x0410
//#define _WIN32_WINNT 0x0500

/////////////////////////////////////////////////////////////////////////////
// Default global operator new and delete
/////////////////////////////////////////////////////////////////////////////
void*operator new[](unsigned int);
void*operator new(unsigned int);
void operator delete[](void*);
void operator delete(void*);

/////////////////////////////////////////////////////////////////////////////
// Forward declaration of type_info
/////////////////////////////////////////////////////////////////////////////
class type_info;
