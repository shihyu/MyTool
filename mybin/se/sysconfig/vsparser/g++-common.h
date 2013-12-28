/**
 * C99 introduces `__func__', and GCC has provided `__FUNCTION__' for a
 * long time.  Both of these are strings containing the name of the
 * current function (there are slight semantic differences; see the GCC
 * manual).  Neither of them is a macro; the preprocessor does not know the
 * name of the current function.  They tend to be useful in conjunction
 * with `__FILE__' and `__LINE__', though.
 */
//#define __func__     "func"
//#define __FUNCTION__ "FUNCTION"
//#define __PRETTY_FUNCTION__ "PRETTY_FUNCTION"

/**
 * These macros are defined by all GNU compilers that use the C
 * preprocessor: C, C++, and Objective-C.  Their values are the major
 * version, minor version, and patch level of the compiler, as integer
 * constants.  For example, GCC 3.2.1 will define `__GNUC__' to 3,
 * `__GNUC_MINOR__' to 2, and `__GNUC_PATCHLEVEL__' to 1.  They are
 * defined only when the entire compiler is in use; if you invoke the
 * preprocessor directly, they are not defined.
 * <p>
 * `__GNUC_PATCHLEVEL__' is new to GCC 3.0; it is also present in the
 * widely-used development snapshots leading up to 3.0 (which identify
 * themselves as GCC 2.96 or 2.97, depending on which snapshot you
 * have).
 * <p>
 * If all you need to know is whether or not your program is being
 * compiled by GCC, you can simply test `__GNUC__'.  If you need to
 * write code which depends on a specific version, you must be more
 * careful.  Each time the minor version is increased, the patch
 * level is reset to zero; each time the major version is increased
 * (which happens rarely), the minor version and patch level are
 * reset.  If you wish to use the predefined macros directly in the
 * conditional, you will need to write it like this:
 * <pre>
 *        // Test for GCC > 3.2.0
 *        #if __GNUC__ > 3 || \
 *            (__GNUC__ == 3 && (__GNUC_MINOR__ > 2 || \
 *                               (__GNUC_MINOR__ == 2 && \
 *                                __GNUC_PATCHLEVEL__ > 0))
 * </pre>
 * <p>
 * Another approach is to use the predefined macros to calculate a
 * single number, then compare that against a threshold:
 * <pre>
 *        #define GCC_VERSION (__GNUC__ * 10000 \
 *                             + __GNUC_MINOR__ * 100 \
 *                             + __GNUC_PATCHLEVEL__)
 *        ...
 *        // Test for GCC > 3.2.0
 *        #if GCC_VERSION > 30200
 * </pre>
 * <p>
 * Many people find this form easier to understand.
 */
#ifndef __GNUC__
#define __GNUC__              3
#endif

#ifndef __GNUC_MINOR__
#define __GNUC_MINOR__        2
#endif

#ifndef __GNUC_PATCHLEVEL__
#define __GNUC_PATCHLEVEL__   2
#endif

/**
 * This macro is defined, with value 1, when the Objective-C compiler
 * is in use.  You can use `__OBJC__' to test whether a header is
 * compiled by a C compiler or a Objective-C compiler.
 */
#ifdef __OBJC__
#undef __OBJC__
#endif

/**
 * The GNU C++ compiler defines this.  Testing it is equivalent to
 * testing `(__GNUC__ && __cplusplus)'.
 */
#ifndef __GNUG__
#define __GNUG__ 1
#endif

/**
 * GCC defines this macro if and only if the `-ansi' switch, or a
 * `-std' switch specifying strict conformance to some version of ISO
 * C, was specified when GCC was invoked.  It is defined to `1'.
 * This macro exists primarily to direct GNU libc's header files to
 * restrict their definitions to the minimal set found in the 1989 C
 * standard.
 */
#ifndef __STRICT_ANSI__
#define __STRICT_ANSI__ 1
#endif

/**
 * This macro expands to the name of the main input file, in the form
 * of a C string constant.  This is the source file that was specified
 * on the command line of the preprocessor or C compiler.
 */
#ifndef __BASE_FILE__
#define __BASE_FILE__ __FILE__
#endif

/**
 * This macro expands to a decimal integer constant that represents
 * the depth of nesting in include files.  The value of this macro is
 * incremented on every `#include' directive and decremented at the
 * end of every included file.  It starts out at 0, it's value within
 * the base file specified on the command line.
 */
#ifndef __INCLUDE_LEVEL__
#define __INCLUDE_LEVEL__ 0
#endif

/**
 * This macro expands to a string constant which describes the
 * version of the compiler in use.  You should not rely on its
 * contents having any particular form, but it can be counted on to
 * version of the compiler in use.  You should not rely on its
 * contents having any particular form, but it can be counted on to
 * contain at least the release number.
 */
#ifndef __VERSION__
#define __VERSION__ "3.2.2"
#endif

/**
 * These macros describe the compilation mode.  `__OPTIMIZE__' is
 * defined in all optimizing compilations.  `__OPTIMIZE_SIZE__' is
 * defined if the compiler is optimizing for size, not speed.
 * `__NO_INLINE__' is defined if no functions will be inlined into
 * their callers (when not optimizing, or when inlining has been
 * specifically disabled by `-fno-inline').
 * <p>
 * These macros cause certain GNU header files to provide optimized
 * definitions, using macros or inline functions, of system library
 * functions.  You should not use these macros in any way unless you
 * make sure that programs will execute with the same effect whether
 * or not they are defined.  If they are defined, their value is 1.
 */
#ifdef __OPTIMIZE__
#undef __OPTIMIZE__
#endif

#ifdef __OPTIMIZE_SIZE__
#undef __OPTIMIZE_SIZE__
#endif

#ifdef __NO_INLINE__
#undef __NO_INLINE__
#endif

/**
 * GCC defines this macro if and only if the data type `char' is
 * unsigned on the target machine.  It exists to cause the standard
 * header file `limits.h' to work correctly.  You should not use this
 * macro yourself; instead, refer to the standard macros defined in
 * `limits.h'.
 */
#ifdef __CHAR_UNSIGNED__
#undef __CHAR_UNSIGNED__
#endif

/**
 * This macro expands to a single token (not a string constant) which
 * is the prefix applied to CPU register names in assembly language
 * for this target.  You can use it to write assembly that is usable
 * in multiple environments.  For example, in the `m68k-aout'
 * environment it expands to nothing, but in the `m68k-coff'
 * environment it expands to a single `%'.
 */
#ifndef __REGISTER_PREFIX__
#define __REGISTER_PREFIX__
#endif

/**
 * This macro expands to a single token which is the prefix applied to
 * user labels (symbols visible to C code) in assembly.  For example,
 * in the `m68k-aout' environment it expands to an `_', but in the
 * `m68k-coff' environment it expands to nothing.
 * <p>
 * This macro will have the correct definition even if
 * `-f(no-)underscores' is in use, but it will not be correct if
 * target-specific options that adjust this prefix are used (e.g. the
 * OSF/rose `-mno-underscores' option).
 */
//#ifndef __USER_LABEL_PREFIX__
//#define __USER_LABEL_PREFIX__ _
//#endif

/**
 * These macros are defined to the correct underlying types for the
 * `size_t', `ptrdiff_t', `wchar_t', and `wint_t' typedefs,
 * respectively.  They exist to make the standard header files
 * `stddef.h' and `wchar.h' work correctly.  You should not use these
 * macros directly; instead, include the appropriate headers and use
 * the typedefs.
 */
#ifndef __SIZE_TYPE__
#define __SIZE_TYPE__      unsigned int
#endif

#ifndef __PTRDIFF_TYPE__
#define __PTRDIFF_TYPE__   unsigned int
#endif

#ifndef __WCHAR_TYPE__
#define __WCHAR_TYPE__     wchar_t
#endif

#ifndef __WINT_TYPE__
#define __WINT_TYPE__      long int
#endif

#ifndef _WCHAR_T_DEFINED
#define _WCHAR_T_DEFINED
#endif

/**
 * This macro is defined, with value 1, if the compiler uses the old
 * mechanism based on `setjmp' and `longjmp' for exception handling.
 */
#ifdef __USING_SJLJ_EXCEPTIONS__
#undef __USING_SJLJ_EXCEPTIONS__
#endif

/**
 * Locally Declared Labels
 * <p>
 * Each statement expression is a scope in which "local labels" can be
 * declared.  A local label is simply an identifier; you can jump to it
 * with an ordinary `goto' statement, but only from within the statement
 * expression it belongs to.
 * <p>
 * A local label declaration looks like this:
 * <pre>
 *    __label__ LABEL;
 * </pre>
 * <p>
 * or
 * <pre>
 *    __label__ LABEL1, LABEL2, ...;
 * </pre>
 * <p>
 * Local label declarations must come at the beginning of the statement
 * expression, right after the `({', before any ordinary declarations.
 * <p>
 * The label declaration defines the label _name_, but does not define
 * the label itself.  You must do this in the usual way, with `LABEL:',
 * within the statements of the statement expression.
 * <p>
 * The local label feature is useful because statement expressions are
 * often used in macros.  If the macro contains nested loops, a `goto' can
 * be useful for breaking out of them.  However, an ordinary label whose
 * scope is the whole function cannot be used: if the macro can be
 * expanded several times in one function, the label will be multiply
 * defined in that function.  A local label avoids this problem.  For
 * example:
 * <pre>
 *   #define SEARCH(array, target)                     \
 *   ({                                                \
 *     __label__ found;                                \
 *     typeof (target) _SEARCH_target = (target);      \
 *     typeof (*(array)) *_SEARCH_array = (array);     \
 *     int i, j;                                       \
 *     int value;                                      \
 *     for (i = 0; i < max; i++)                       \
 *       for (j = 0; j < max; j++)                     \
 *         if (_SEARCH_array[i][j] == _SEARCH_target)  \
 *           { value = i; goto found; }                \
 *     value = -1;                                     \
 *    found:                                           \
 *     value;                                          \
 *   })
 * </pre>
 */
#ifndef __label__
#define __label__ void*
#endif

/**
 * Restricting Pointer Aliasing
 * <p>
 * As with gcc, g++ understands the C99 feature of restricted pointers,
 * specified with the `__restrict__', or `__restrict' type qualifier.
 * Because you cannot compile C++ by specifying the `-std=c99' language
 * flag, `restrict' is not a keyword in C++.
 * <p>
 * In addition to allowing restricted pointers, you can specify
 * restricted references, which indicate that the reference is not aliased
 * in the local context.
 * <pre>
 *    void fn (int *__restrict__ rptr, int &__restrict__ rref)
 *    {
 *       ...
 *    }
 * </pre>
 * <p>
 * In the body of `fn', RPTR points to an unaliased integer and RREF
 * refers to a (different) unaliased integer.
 * <p>
 * You may also specify whether a member function's THIS pointer is
 * unaliased by using `__restrict__' as a member function qualifier.
 * <p>
 * void T::fn () __restrict__
 * {
 *    ...
 * }
 * <p>
 * Within the body of `T::fn', THIS will have the effective definition
 * `T *__restrict__ const this'.  Notice that the interpretation of a
 * `__restrict__' member function qualifier is different to that of
 * `const' or `volatile' qualifier, in that it is applied to the pointer
 * rather than the object.  This is consistent with other compilers which
 * implement restricted pointers.
 * <p>
 * As with all outermost parameter qualifiers, `__restrict__' is
 * ignored in function definition matching.  This means you only need to
 * specify `__restrict__' in a function definition, rather than in a
 * function prototype as well.
 */
#ifndef __restrict
#define __restrict   restrict
#endif

#ifndef __restrict__
#define __restrict__ restrict
#endif

/**
 * Constructing Function Calls
 * <p>
 * Using the built-in functions described below, you can record the
 * arguments a function received, and call another function with the same
 * arguments, without knowing the number or types of the arguments.
 * <p>
 * You can also record the return value of that function call, and
 * later return that value, without knowing what data type the function
 * tried to return (as long as your caller expects that data type).
 * <ul>
 * <li>Built-in Function: void * __builtin_apply_args ()
 * <p>
 * This built-in function returns a pointer to data describing how to
 * perform a call with the same arguments as were passed to the
 * current function.
 * <p>
 * The function saves the arg pointer register, structure value
 * address, and all registers that might be used to pass arguments to
 * a function into a block of memory allocated on the stack.  Then it
 * returns the address of that block.
 * <ul>
 * Built-in Function:
 * void * __builtin_apply (void (*FUNCTION)(), void *ARGUMENTS, size_t SIZE)
 * <p>
 * This built-in function invokes FUNCTION with a copy of the
 * parameters described by ARGUMENTS and SIZE.
 * <p>
 * The value of ARGUMENTS should be the value returned by
 * `__builtin_apply_args'.  The argument SIZE specifies the size of
 * the stack argument data, in bytes.
 * <p>
 * This function returns a pointer to data describing how to return
 * whatever value was returned by FUNCTION.  The data is saved in a
 * block of memory allocated on the stack.
 * <p>
 * It is not always simple to compute the proper value for SIZE.  The
 * value is used by `__builtin_apply' to compute the amount of data
 * that should be pushed on the stack and copied from the incoming
 * argument area.
 * <ul>
 * Built-in Function: void __builtin_return (void *RESULT)
 * <p>
 * This built-in function returns the value described by RESULT from
 * the containing function.  You should specify, for RESULT, a value
 * returned by `__builtin_apply'.
 */
void* __builtin_apply_args();
void* __builtin_apply(void (*FUNCTION)(), void *ARGUMENTS, __SIZE_TYPE__ SIZE);
void __builtin_return(void *RESULT);

/**
 * Complex Numbers
 * <p>
 * ISO C99 supports complex floating data types, and as an extension GCC
 * supports them in C89 mode and in C++, and supports complex integer data
 * types which are not part of ISO C99.  You can declare complex types
 * using the keyword `_Complex'.  As an extension, the older GNU keyword
 * `__complex__' is also supported.
 * <p>
 * For example, `_Complex double x;' declares `x' as a variable whose
 * real part and imaginary part are both of type `double'.  `_Complex
 * short int y;' declares `y' to have real and imaginary parts of type
 * `short int'; this is not likely to be useful, but it shows that the set
 * of complex types is complete.
 * <p>
 * To write a constant with a complex data type, use the suffix `i' or
 * `j' (either one; they are equivalent).  For example, `2.5fi' has type
 * `_Complex float' and `3i' has type `_Complex int'.  Such a constant
 * always has a pure imaginary value, but you can form any complex value
 * you like by adding one to a real constant.  This is a GNU extension; if
 * you have an ISO C99 conforming C library (such as GNU libc), and want
 * to construct complex constants of floating type, you should include
 * `<complex.h>' and use the macros `I' or `_Complex_I' instead.
 * <p>
 * To extract the real part of a complex-valued expression EXP, write
 * `__real__ EXP'.  Likewise, use `__imag__' to extract the imaginary
 * part.  This is a GNU extension; for values of floating type, you should
 * use the ISO C99 functions `crealf', `creal', `creall', `cimagf',
 * `cimag' and `cimagl', declared in `<complex.h>' and also provided as
 * built-in functions by GCC.
 * <p>
 * The operator `~' performs complex conjugation when used on a value
 * with a complex type.  This is a GNU extension; for values of floating
 * type, you should use the ISO C99 functions `conjf', `conj' and `conjl',
 * declared in `<complex.h>' and also provided as built-in functions by
 * GCC.
 * <p>
 * GCC can allocate complex automatic variables in a noncontiguous
 * fashion; it's even possible for the real part to be in a register while
 * the imaginary part is on the stack (or vice-versa).  None of the
 * supported debugging info formats has a way to represent noncontiguous
 * allocation like this, so GCC describes a noncontiguous complex variable
 * as if it were two separate variables of noncomplex type.  If the
 * variable's actual name is `foo', the two fictitious variables are named
 * `foo$real' and `foo$imag'.  You can examine and set these two
 * fictitious variables with your debugger.
 * <p>
 * A future version of GDB will know how to recognize such pairs and
 * treat them as a single variable with a complex type.
 */
#ifndef __complex__
#define __complex__ // double
#endif

#ifndef __real__
#define __real__
#endif

#ifndef __imag__
#define __imag__
#endif

/**
 * Declaring Attributes of Functions
 * <p>
 * In GNU C, you declare certain things about functions called in your
 * program which help the compiler optimize function calls and check your
 * code more carefully.
 * <p>
 * The keyword `__attribute__' allows you to specify special attributes when
 * making a declaration.  This keyword is followed by an attribute
 * specification inside double parentheses.  The following attributes are
 * currently defined for functions on all targets: `noreturn', `noinline',
 * `always_inline', `pure', `const', `format', `format_arg',
 * `no_instrument_function', `section', `constructor', `destructor', `used',
 * `unused', `deprecated', `weak', `malloc', and `alias'.  Several other
 * attributes are defined for functions on particular target systems.  Other
 * attributes, including `section' are supported for variables declarations
 * (*note Variable Attributes::) and for types (*note Type Attributes::).
 * <p>
 * You may also specify attributes with `__' preceding and following each
 * keyword.  This allows you to use them in header files without being
 * concerned about a possible macro of the same name.  For example, you may
 * use `__noreturn__' instead of `noreturn'.
 */
#ifndef __attribute__
#define __attribute__(x)
#endif

#ifndef __attribute
#define __attribute(x)
#endif

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#ifndef _POSIX_SOURCE
#define _POSIX_SOURCE
#endif

/**
 * Enable ISO C++ 14882: 19.1  Exception classes
 */
#ifndef __EXCEPTIONS
#define __EXCEPTIONS 1
#endif

#ifndef __stdcall
#define __stdcall
#endif

#ifndef __fastcall
#define __fastcall
#endif

#ifndef __stdcall__
#define __stdcall__
#endif

#ifndef __fastcall__
#define __fastcall__
#endif

#ifndef __cdecl
#define __cdecl
#endif

#ifndef __cdecl__
#define __cdecl__
#endif

#ifndef _stdcall
#define _stdcall
#endif

#ifndef _fastcall
#define _fastcall
#endif

#ifndef _cdecl
#define _cdecl
#endif

#ifndef __declspec
#define __declspec(x)
#endif


/**
 * Inquiring on Alignment of Types or Variables
 * <p>
 * The keyword `__alignof__' allows you to inquire about how an object
 * is aligned, or the minimum alignment usually required by a type.  Its
 * syntax is just like `sizeof'.
 * <p>
 * For example, if the target machine requires a `double' value to be
 * aligned on an 8-byte boundary, then `__alignof__ (double)' is 8.  This
 * is true on many RISC machines.  On more traditional machine designs,
 * `__alignof__ (double)' is 4 or even 2.
 * <p>
 * Some machines never actually require alignment; they allow reference
 * to any data type even at an odd addresses.  For these machines,
 * `__alignof__' reports the _recommended_ alignment of a type.
 * <p>
 * If the operand of `__alignof__' is an lvalue rather than a type, its
 * value is the required alignment for its type, taking into account any
 * minimum alignment specified with GCC's `__attribute__' extension (*note
 * Variable Attributes::).  For example, after this declaration:
 * <pre>
 *    struct foo { int x; char y; } foo1;
 * </pre>
 * the value of `__alignof__ (foo1.y)' is 1, even though its actual
 * alignment is probably 2 or 4, the same as `__alignof__ (int)'.
 * <p>
 * It is an error to ask for the alignment of an incomplete type.
 */
#define __alignof__(x) 2
#define __alignof(x) 2

/**
 * Referring to a Type with `typeof'
 * <p>
 * Another way to refer to the type of an expression is with `typeof'.
 * The syntax of using of this keyword looks like `sizeof', but the
 * construct acts semantically like a type name defined with `typedef'.
 * <p>
 * There are two ways of writing the argument to `typeof': with an
 * expression or with a type.  Here is an example with an expression:
 * <pre>
 *    typeof (x[0](1))
 * </pre>
 * <p>
 * This assumes that `x' is an array of pointers to functions; the type
 * described is that of the values of the functions.
 * <p>
 * Here is an example with a typename as the argument:
 * <pre>
 *    typeof (int *)
 * </pre>
 * <p>
 * Here the type described is that of pointers to `int'.
 * <p>
 * If you are writing a header file that must work when included in ISO
 * C programs, write `__typeof__' instead of `typeof'.  *Note Alternate
 * Keywords::.
 * <p>
 * A `typeof'-construct can be used anywhere a typedef name could be
 * used.  For example, you can use it in a declaration, in a cast, or
 * inside of `sizeof' or `typeof'.
 * <p>
 * This declares `y' with the type of what `x' points to.
 * <pre>
 *    typeof (*x) y;
 * </pre>
 * <p>
 * This declares `y' as an array of such values.
 * <pre>
 *    typeof (*x) y[4];
 * </pre>
 * <p>
 * This declares `y' as an array of pointers to characters:
 * <pre>
 *    typeof (typeof (char *)[4]) y;
 * </pre>
 * <p>
 * It is equivalent to the following traditional C declaration:
 * <pre>
 *    char *y[4];
 * </pre>
 * <p>
 * To see the meaning of the declaration using `typeof', and why it
 * might be a useful way to write, let's rewrite it with these macros:
 * <pre>
 *    #define pointer(T)  typeof(T *)
 *    #define array(T, N) typeof(T [N])
 * <pre>
 * <p>
 * Now the declaration can be rewritten this way:
 * <pre>
 *    array (pointer (char), 4) y;
 * </pre>
 * <p>
 * Thus, `array (pointer (char), 4)' is the type of arrays of 4
 * pointers to `char'.
 */
#define typeof(p)     __typeof(p)
#define __typeof__(p) __typeof(p)

/**
 * Alternate Keywords
 * <p>
 * The option `-traditional' disables certain keywords; `-ansi' and the
 * various `-std' options disable certain others.  This causes trouble
 * when you want to use GNU C extensions, or ISO C features, in a
 * general-purpose header file that should be usable by all programs,
 * including ISO C programs and traditional ones.  The keywords `asm',
 * `typeof' and `inline' cannot be used since they won't work in a program
 * compiled with `-ansi' (although `inline' can be used in a program
 * compiled with `-std=c99'), while the keywords `const', `volatile',
 * `signed', `typeof' and `inline' won't work in a program compiled with
 * `-traditional'.  The ISO C99 keyword `restrict' is only available when
 * `-std=gnu99' (which will eventually be the default) or `-std=c99' (or
 * the equivalent `-std=iso9899:1999') is used.
 * <p>
 * The way to solve these problems is to put `__' at the beginning and
 * end of each problematical keyword.  For example, use `__asm__' instead
 * of `asm', `__const__' instead of `const', and `__inline__' instead of
 * `inline'.
 * <p>
 * Other C compilers won't accept these alternative keywords; if you
 * want to compile with another compiler, you can define the alternate
 * keywords as macros to replace them with the customary keywords.  It
 * looks like this:
 * <pre>
 *    #ifndef __GNUC__
 *    #define __asm__ asm
 *    #endif
 * </pre>
 * <p>
 * `-pedantic' and other options cause warnings for many GNU C
 * extensions.  You can prevent such warnings within one expression by
 * writing `__extension__' before the expression.  `__extension__' has no
 * effect aside from this.
 */
//#define __asm__ asm
//#define __inline__ inline
//#define __inline inline
//#define __const__ const
//#define __const const
//#define __volatile__ volatile
//#define __volatile volatile
//#define __signed__ signed
#define __extension__

/**
 * Getting the Return or Frame Address of a Function
 * <p>
 * These functions may be used to get information about the callers of a
 * function.
 * <ul>
 * <li>
 * Built-in Function:
 * <pre>
 *    void * __builtin_return_address (unsigned int LEVEL)
 * </pre>
 * <p>
 * This function returns the return address of the current function, or of
 * one of its callers.  The LEVEL argument is number of frames to scan up
 * the call stack.  A value of `0' yields the return address of the current
 * function, a value of `1' yields the return address of the caller of the
 * current function, and so forth.
 * <p>
 * The LEVEL argument must be a constant integer.
 * <p>
 * On some machines it may be impossible to determine the return address of
 * any function other than the current one; in such cases, or when the top
 * of the stack has been reached, this function will return `0' or a random
 * value.  In addition, `__builtin_frame_address' may be used to determine
 * if the top of the stack has been reached.
 * <p>
 * This function should only be used with a nonzero argument for debugging
 * purposes.
 * <p>
 * <li>Built-in Function:
 * <pre>
 *    void * __builtin_frame_address (unsigned int LEVEL)
 * </pre>
 * <p>
 * This function is similar to `__builtin_return_address', but it returns
 * the address of the function frame rather than the return address of the
 * function.  Calling `__builtin_frame_address' with a value of `0' yields
 * the frame address of the current function, a value of `1' yields the
 * frame address of the caller of the current function, and so forth.
 * <p>
 * The frame is the area on the stack which holds local variables and saved
 * registers.  The frame address is normally the address of the first word
 * pushed on to the stack by the function.  However, the exact definition
 * depends upon the processor and the calling convention.  If the processor
 * has a dedicated frame pointer register, and the function has a frame,
 * then `__builtin_frame_address' will return the value of the frame pointer
 * register.
 * <p>
 * On some machines it may be impossible to determine the frame address of
 * any function other than the current one; in such cases, or when the top
 * of the stack has been reached, this function will return `0' if the first
 * frame pointer is properly initialized by the startup code.
 * <p>
 * This function should only be used with a nonzero argument for debugging
 * purposes.
 */
extern void* __builtin_return_address(unsigned int LEVEL);
extern void* __builtin_frame_address(unsigned int LEVEL);

/**
 * Other built-in functions provided by GCC
 * <p>
 * GCC provides a large number of built-in functions other than the ones
 * mentioned above.  Some of these are for internal use in the processing
 * of exceptions or variable-length argument lists and will not be
 * documented here because they may change from time to time; we do not
 * recommend general use of these functions.
 * <p>
 * The remaining functions are provided for optimization purposes.
 * <p>
 * GCC includes built-in versions of many of the functions in the
 * standard C library.  The versions prefixed with `__builtin_' will
 * always be treated as having the same meaning as the C library function
 * even if you specify the `-fno-builtin' option. (*note C Dialect
 * Options::) Many of these functions are only optimized in certain cases;
 * if they are not optimized in a particular case, a call to the library
 * function will be emitted.
 * <p>
 * The functions `abort', `exit', `_Exit' and `_exit' are recognized
 * and presumed not to return, but otherwise are not built in.  `_exit' is
 * not recognized in strict ISO C mode (`-ansi', `-std=c89' or
 * `-std=c99').  `_Exit' is not recognized in strict C89 mode (`-ansi' or
 * `-std=c89').
 * <p>
 * Outside strict ISO C mode, the functions `alloca', `bcmp', `bzero',
 * `index', `rindex', `ffs', `fputs_unlocked', `printf_unlocked' and
 * `fprintf_unlocked' may be handled as built-in functions.  All these
 * functions have corresponding versions prefixed with `__builtin_', which
 * may be used even in strict C89 mode.
 */
extern void* __builtin_alloca(__SIZE_TYPE__ size);
extern int __builtin_bcmp(const void *s1, const void *s2, __SIZE_TYPE__ n);
extern int __builtin_bzero(void *s, __SIZE_TYPE__ n);
extern char *__builtin_index(const char *s, int c);
extern char *__builtin_rindex(const char *s, int c);
extern int __builtin_ffs(int i);
extern int __builtin_fputc_unlocked(int c, void *stream);
extern int __builtin_fputs_unlocked(const char *s, void *stream);
extern int __builtin_printf_unlocked(const char *format, ...);
extern int __builtin_fprintf_unlocked(void* stream, const char *format, ...);

/**
 * The ISO C99 functions `conj', `conjf', `conjl', `creal', `crealf',
 * `creall', `cimag', `cimagf', `cimagl', `llabs' and `imaxabs' are
 * handled as built-in functions except in strict ISO C89 mode.  There are
 * also built-in versions of the ISO C99 functions `cosf', `cosl',
 * `fabsf', `fabsl', `sinf', `sinl', `sqrtf', and `sqrtl', that are
 * recognized in any mode since ISO C89 reserves these names for the
 * purpose to which ISO C99 puts them.  All these functions have
 * corresponding versions prefixed with `__builtin_'.
 */
#define __builtin_conj(a)     (a)
#define __builtin_conjf(a)    (a)
#define __builtin_conjl(a)    (a)
#define __builtin_creal(a)    (a)
#define __builtin_crealf(a)   (a)
#define __builtin_creall(a)   (a)
#define __builtin_cimag(a)    (a)
#define __builtin_cimagf(a)   (a)
#define __builtin_cimagl(a)   (a)
#define __builtin_llabs(a)    (a)
#define __builtin_imaxabs(a)  (a)

#define __builtin_cosf(a)     (a)
#define __builtin_cosl(a)     (a)
#define __builtin_fabsf(a)    (a)
#define __builtin_fabsl(a)    (a)
#define __builtin_sinf(a)     (a)
#define __builtin_sinl(a)     (a)
#define __builtin_sqrtf(a)    (a)
#define __builtin_sqrtl(a)    (a)

/**
 * Undocumented floating point builtin functions.
 */
#define __builtin_huge_val()  1.7976931348623157e+308
#define __builtin_huge_valf() 3.40282347e+38F
#define __builtin_huge_vall() 1.18973149535723176502e+4932L
#define __builtin_nan(s)      0.0
#define __builtin_nanf(s)     0.0f
#define __builtin_nanl(s)     0.0L
#define __builtin_nans(s)     0.0
#define __builtin_nansf(s)    0.0f
#define __builtin_nansl(s)    0.0L

/**
 * The ISO C89 functions `abs', `cos', `fabs', `fprintf', `fputs',
 * `labs', `memcmp', `memcpy', `memset', `printf', `sin', `sqrt', `strcat',
 * `strchr', `strcmp', `strcpy', `strcspn', `strlen', `strncat',
 * `strncmp', `strncpy', `strpbrk', `strrchr', `strspn', and `strstr' are
 * all recognized as built-in functions unless `-fno-builtin' is specified
 * (or `-fno-builtin-FUNCTION' is specified for an individual function).
 * All of these functions have corresponding versions prefixed with
 * `__builtin_'.
 */
extern int __builtin_abs(int a);
extern double __builtin_cos(double a);
extern double __builtin_fabs(double a);
extern long int __builtin_labs(long int a);
extern double __builtin_sin(double a);
extern double __builtin_sqrt(double a);
extern int   __builtin_memcmp(const void* s1,const void* s2,__SIZE_TYPE__ n);
extern void* __builtin_memcpy(void* dest,const void* src,__SIZE_TYPE__ n);
extern void* __builtin_memset(void* s,int c,__SIZE_TYPE__ n);
extern char* __builtin_strcat(char* dest,const char* src);
extern char* __builtin_strchr(const char* s,int c);
extern int   __builtin_strcmp(const char* s1,const char *s2);
extern char* __builtin_strcpy(char* dest,const char* src);
extern __SIZE_TYPE__ __builtin_strcspn(const char* s, const char* reject);
extern __SIZE_TYPE__ __builtin_strlen(const char* s);
extern char* __builtin_strncat(char* dest,const char* src,__SIZE_TYPE__ n);
extern int   __builtin_strncmp(const char* s1,const char* s2,__SIZE_TYPE__ n);
extern char* __builtin_strncpy(char* dest,const char* src,__SIZE_TYPE__ n);
extern char* __builtin_strpbrk(const char* s,const char* accept);
extern char* __builtin_strrchr(const char* s,int c);
extern __SIZE_TYPE__ __builtin_strspn(const char* s,const char* accept);
extern char* __builtin_strstr(const char* haystack,const char* needle);

/**
 * GCC provides built-in versions of the ISO C99 floating point
 * comparison macros that avoid raising exceptions for unordered operands.
 * They have the same names as the standard macros ( `isgreater',
 * `isgreaterequal', `isless', `islessequal', `islessgreater', and
 * `isunordered') , with `__builtin_' prefixed.  We intend for a library
 * implementor to be able to simply `#define' each standard macro to its
 * built-in equivalent.
 */
#define __builtin_isgreater(a,b)       ((a) >  (b))
#define __builtin_isgreaterequal(a,b)  ((a) >= (b))
#define __builtin_isless(a,b)          ((a) <  (b))
#define __builtin_islessequal(a,b)     ((a) <= (b))
#define __builtin_islessgreater(a,b)   ((a) != (b))
#define __builtin_isunordered(a,b)     ((a) == (b))

/*
 * Built-in Function:
 * <pre>
 *    int __builtin_types_compatible_p (TYPE1, TYPE2)
 * </pre>
 * <p>
 * You can use the built-in function `__builtin_types_compatible_p' to
 * determine whether two types are the same.
 * <p>
 * This built-in function returns 1 if the unqualified versions of the
 * types TYPE1 and TYPE2 (which are types, not expressions) are
 * compatible, 0 otherwise.  The result of this built-in function can
 * be used in integer constant expressions.
 * <p>
 * This built-in function ignores top level qualifiers (e.g., `const',
 * `volatile').  For example, `int' is equivalent to `const int'.
 * <p>
 * The type `int[]' and `int[5]' are compatible.  On the other hand, `int'
 * and `char *' are not compatible, even if the size of their types, on the
 * particular architecture are the same.  Also, the amount of pointer
 * indirection is taken into account when determining similarity.
 * Consequently, `short *' is not similar to `short **'.  Furthermore, two
 * types that are typedefed are considered compatible if their underlying
 * types are compatible.
 * <p>
 * An `enum' type is considered to be compatible with another `enum' type.
 * For example, `enum {foo, bar}' is similar to `enum {hot, dog}'.
 * <p>
 * You would typically use this function in code whose execution
 * varies depending on the arguments' types.  For example:
 * <pre>
 *    #define foo(x)                                                  \
 *      ({                                                           \
 *        typeof (x) tmp;                                             \
 *        if (__builtin_types_compatible_p (typeof (x), long double)) \
 *          tmp = foo_long_double (tmp);                              \
 *        else if (__builtin_types_compatible_p (typeof (x), double)) \
 *          tmp = foo_double (tmp);                                   \
 *                        else if (__builtin_types_compatible_p (typeof (x), double)) \
 *          tmp = foo_double (tmp);                                   \
 *        else if (__builtin_types_compatible_p (typeof (x), float))  \
 *          tmp = foo_float (tmp);                                    \
 *        else                                                        \
 *          abort ();                                                 \
 *        tmp;                                                        \
 *      })
 * </pre>
 * <p>
 * _Note:_ This construct is only available for C.
 */
#define __builtin_types_compatable_p(TYPE1,TYPE2)  true
#define __builtin_classify_type(TYPE) 8

/**
 * Built-in Function:
 * <pre>
 *    TYPE __builtin_choose_expr (CONST_EXP, EXP1, EXP2)
 * </pre>
 * <p>
 * You can use the built-in function `__builtin_choose_expr' to evaluate
 * code depending on the value of a constant expression.  This built-in
 * function returns EXP1 if CONST_EXP, which is a constant expression that
 * must be able to be determined at compile time, is nonzero.  Otherwise it
 * returns 0.
 * <p>
 * This built-in function is analogous to the `? :' operator in C,
 * except that the expression returned has its type unaltered by
 * promotion rules.  Also, the built-in function does not evaluate
 * the expression that was not chosen.  For example, if CONST_EXP
 * evaluates to true, EXP2 is not evaluated even if it has
 * side-effects.
 * <p>
 * This built-in function can return an lvalue if the chosen argument
 * is an lvalue.
 * <p>
 * If EXP1 is returned, the return type is the same as EXP1's type.
 * Similarly, if EXP2 is returned, its return type is the same as EXP2.
 * <p>
 * _Note:_ This construct is only available for C.  Furthermore, the
 * unused expression (EXP1 or EXP2 depending on the value of
 * CONST_EXP) may still generate syntax errors.  This may change in
 * future revisions.
 */
#define __builtin_choose_expr(CONST_EXP,EXP1,EXP2)  ((CONST_EXP)? (EXP1):(EXP2))

/**
 * Built-in Function:
 * <pre>
 *    int __builtin_constant_p (EXP)
 * </pre>
 * <p>
 * You can use the built-in function `__builtin_constant_p' to
 * determine if a value is known to be constant at compile-time and
 * hence that GCC can perform constant-folding on expressions
 * involving that value.  The argument of the function is the value
 * to test.  The function returns the integer 1 if the argument is
 * known to be a compile-time constant and 0 if it is not known to be
 * a compile-time constant.  A return of 0 does not indicate that the
 * value is _not_ a constant, but merely that GCC cannot prove it is
 * a constant with the specified value of the `-O' option.
 * <p>
 * You would typically use this function in an embedded application
 * where memory was a critical resource.  If you have some complex
 * calculation, you may want it to be folded if it involves
 * constants, but need to call a function if it does not.  For
 * example:
 * <pre>
 *    #define Scale_Value(X)      \
 *       (__builtin_constant_p (X) \
 *       ? ((X) * SCALE + OFFSET) : Scale (X))
 * </pre>
 * <p>
 * You may use this built-in function in either a macro or an inline
 * function.  However, if you use it in an inlined function and pass
 * an argument of the function as the argument to the built-in, GCC
 * will never return 1 when you call the inline function with a
 * string constant or compound literal (*note Compound Literals::)
 * and will not return 1 when you pass a constant numeric value to
 * the inline function unless you specify the `-O' option.
 * <pre>
 * You may also use `__builtin_constant_p' in initializers for static
 * data.  For instance, you can write
 * <pre>
 *    static const int table[] = {
 *          __builtin_constant_p (EXPRESSION) ? (EXPRESSION) : -1,
 *          /* ... * /
 *    };
 * </pre>
 * This is an acceptable initializer even if EXPRESSION is not a
 * constant expression.  GCC must be more conservative about
 * evaluating the built-in in this case, because it has no
 * opportunity to perform optimization.
 * <p>
 * Previous versions of GCC did not accept this built-in in data
 * initializers.  The earliest version where it is completely safe is
 * 3.0.1.
 */
#define __builtin_constant_p(EXP) false

/**
 * Built-in Function:
 * <pre>
 *    long __builtin_expect (long EXP, long C)
 * </pre>
 * You may use `__builtin_expect' to provide the compiler with branch
 * prediction information.  In general, you should prefer to use
 * actual profile feedback for this (`-fprofile-arcs'), as
 * programmers are notoriously bad at predicting how their programs
 * actually perform.  However, there are applications in which this
 * data is hard to collect.
 * <p>
 * The return value is the value of EXP, which should be an integral
 * expression.  The value of C must be a compile-time constant.  The
 * semantics of the built-in are that it is expected that EXP == C.
 * For example:
 * <pre>
 *    if (__builtin_expect (x, 0))
 *       foo ();
 * </pre>
 * <p>
 * would indicate that we do not expect to call `foo', since we
 * expect `x' to be zero.  Since you are limited to integral
 * expressions for EXP, you should use constructions such as
 * <pre>
 *    if (__builtin_expect (ptr != NULL, 1))
 *       error ();
 * </pre>
 * <p>
 * when testing pointer or floating-point values.
 */
#define __builtin_expect(EXP,C) (EXP)

/**
 * Built-in Function:
 * <pre>
 *    void __builtin_prefetch (const void *ADDR, ...)
 * </pre>
 * <p>
 * This function is used to minimize cache-miss latency by moving
 * data into a cache before it is accessed.  You can insert calls to
 * `__builtin_prefetch' into code for which you know addresses of
 * data in memory that is likely to be accessed soon.  If the target
 * supports them, data prefetch instructions will be generated.  If
 * the prefetch is done early enough before the access then the data
 * will be in the cache by the time it is accessed.
 * <p>
 * The value of ADDR is the address of the memory to prefetch.  There
 * are two optional arguments, RW and LOCALITY.  The value of RW is a
 * compile-time constant one or zero; one means that the prefetch is
 * preparing for a write to the memory address and zero, the default,
 * means that the prefetch is preparing for a read.  The value
 * LOCALITY must be a compile-time constant integer between zero and
 * three.  A value of zero means that the data has no temporal
 * locality, so it need not be left in the cache after the access.  A
 * value of three means that the data has a high degree of temporal
 * locality and should be left in all levels of cache possible.
 * Values of one and two mean, respectively, a low or moderate degree
 * of temporal locality.  The default is three.
 * <pre>
 *    for (i = 0; i < n; i++)
 *    {
 *       a[i] = a[i] + b[i];
 *       __builtin_prefetch (&a[i+j], 1, 1);
 *       __builtin_prefetch (&b[i+j], 0, 1);
 *       /* ... * /
 *    }
 * </pre>
 * <p>
 * Data prefetch does not generate faults if ADDR is invalid, but the
 * address expression itself must be valid.  For example, a prefetch
 * of `p->next' will not fault if `p->next' is not a valid address,
 * but evaluation will fault if `p' is not a valid address.
 * <p>
 * If the target does not support data prefetch, the address
 * expression is evaluated if it includes side effects but no other
 * code is generated and GCC does not issue a warning.
 * </ul>
 */
#define __builtin_prefetch(ADDR,...)

/**
 * The pseudo keyword `__builtin_va_list` is a special built-in type.
 */
#define __builtin_va_list char*

/**
 * The pseudo keyword '__builtin_va_arg' should be treated as a cast
 */
#define __builtin_va_arg(ap,t) ((t)0)

/**
 * The pseudo keywords '__builtin_stdarg_start' and '__builtin_stdarg_end'
 * should be ignored.
 */
#define __builtin_stdarg_start(ap,i)

/**
 * The pseudo keywords '__builtin_stdarg_start' and '__builtin_stdarg_end'
 * should be ignored.
 */
#define __builtin_va_end(ap)

/**
 * (void *)0 is no longer considered a null pointer constant; NULL in
 * <stddef.h> is now defined as __null, a magic constant of type (void *)
 * normally, or (size_t) with -ansi.
 */
#define __null 0

/**
 * The _Pragma macro is part of the C99 standard
 */
#define _Pragma(x)

/////////////////////////////////////////////////////////////////////////////
// Forward declaration of type_info
/////////////////////////////////////////////////////////////////////////////
class type_info;

