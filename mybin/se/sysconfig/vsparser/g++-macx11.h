/**
 * Generic g++ system configuration header
 */
#include "g++-common.h"

/**
 * System-specific Predefined Macros
 * <p>
 * The C preprocessor normally predefines several macros that indicate
 * what type of system and machine is in use.  They are obviously
 * different on each target supported by GCC.  This manual, being for all
 * systems and machines, cannot tell you what their names are, but you can
 * use `cpp -dM' to see them all.  *Note Invocation::.  All system-specific
 * predefined macros expand to the constant 1, so you can test them with
 * either `#ifdef' or `#if'.
 * <p>
 * The C standard requires that all system-specific macros be part of
 * the "reserved namespace".  All names which begin with two underscores,
 * or an underscore and a capital letter, are reserved for the compiler and
 * library to use as they wish.  However, historically system-specific
 * macros have had names with no special prefix; for instance, it is common
 * to find `unix' defined on Unix systems.  For all such macros, GCC
 * provides a parallel macro with two underscores added at the beginning
 * and the end.  If `unix' is defined, `__unix__' will be defined too.
 * There will never be more than two underscores; the parallel of `_mips'
 * is `__mips__'.
 * <p>
 * When the `-ansi' option, or any `-std' option that requests strict
 * conformance, is given to the compiler, all the system-specific
 * predefined macros outside the reserved namespace are suppressed.  The
 * parallel macros, inside the reserved namespace, remain defined.
 * <p>
 * We are slowly phasing out all predefined macros which are outside the
 * reserved namespace.  You should never use them in new programs, and we
 * encourage you to correct older code to use the parallel macros whenever
 * you find it.  We don't recommend you use the system-specific macros that
 * are in the reserved namespace, either.  It is better in the long run to
 * check specifically for features you need, using a tool such as
 * `autoconf'.
 */
#define __DBL_MIN_EXP__ (-1021)
#define __FLT_MIN__ 1.17549435e-38F
#define __CHAR_BIT__ 8
#define __WCHAR_MAX__ 2147483647
#define __DBL_DENORM_MIN__ 4.9406564584124654e-324
#define __FLT_EVAL_METHOD__ 0
#define __DBL_MIN_10_EXP__ (-307)
#define __FINITE_MATH_ONLY__ 0
#define __SHRT_MAX__ 32767
#define __LDBL_MAX__ 1.7976931348623157e+308L
#define _ARCH_PPC 1
#define __APPLE_CC__ 1666
#define __LDBL_MAX_EXP__ 1024
#define __SCHAR_MAX__ 127
#define __DBL_DIG__ 15
#define __USER_LABEL_PREFIX__ _
#define __STDC_HOSTED__ 1
#define __FLT_EPSILON__ 1.19209290e-7F
#define __GXX_WEAK__ 0
#define __LDBL_MIN__ 2.2250738585072014e-308L
#define __ppc__ 1
#define __strong 
#define __APPLE__ 1
#define __DECIMAL_DIG__ 17
#define __DYNAMIC__ 1
#define __DBL_MAX__ 1.7976931348623157e+308
#define __DEPRECATED 1
#define __DBL_MAX_EXP__ 1024
#define __LONG_LONG_MAX__ 9223372036854775807LL
#define __GXX_ABI_VERSION 102
#define __FLT_MIN_EXP__ (-125)
#define __DBL_MIN__ 2.2250738585072014e-308
#define __FLT_MIN_10_EXP__ (-37)
#define __FLT_MANT_DIG__ 24
#define __BIG_ENDIAN__ 1
#define _BIG_ENDIAN 1
#define __FLT_RADIX__ 2
#define __LDBL_EPSILON__ 2.2204460492503131e-16L
#define __NATURAL_ALIGNMENT__ 1
#define __FLT_MAX_10_EXP__ 38
#define __LONG_MAX__ 2147483647L
#define __LDBL_MANT_DIG__ 53
#define __FLT_DIG__ 6
#define __INT_MAX__ 2147483647
#define __MACH__ 1
#define __FLT_MAX_EXP__ 128
#define __DBL_MANT_DIG__ 53
#define __LDBL_MIN_EXP__ (-1021)
#define __LDBL_MAX_10_EXP__ 308
#define __DBL_EPSILON__ 2.2204460492503131e-16
#define __FLT_DENORM_MIN__ 1.40129846e-45F
#define __FLT_MAX__ 3.40282347e+38F
#define __DBL_MAX_10_EXP__ 308
#define __LDBL_DENORM_MIN__ 4.9406564584124654e-324L
#define __LDBL_MIN_10_EXP__ (-307)
#define __LDBL_DIG__ 15
#define __POWERPC__ 1
#define __private_extern__ extern

