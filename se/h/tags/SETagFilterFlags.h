////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagFilterFlags.h
// Description:   Declaration of enumerated type representing filtering flags
//                for filtering symbols by type.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"

/**
 * Tag type filtering flags.  These filters are used by various methods 
 * to narrow down a tagging search to a specific set of symbol types. 
 */
enum SETagFilterFlags : VSUINT64 {

    /**
     * Specifies that we should filter out case-insensitive matches. 
     * Note that this flag is generally obsolete and ignored. 
     */
    SE_TAG_FILTER_CASE_SENSITIVE     = 0x00000001,

    /**
     * Procedure, function, constructor, destructor, operator,
     * or other type of method. 
     */
    SE_TAG_FILTER_PROCEDURE          = 0x00000002,
    /**
     * Forward declaration of procedure, function, constructor, destructor, 
     * operator, or other type of method. 
     */
    SE_TAG_FILTER_PROTOTYPE          = 0x00000004,
    /**
     * Source code preprocessing macro definition.
     */
    SE_TAG_FILTER_DEFINE             = 0x00000008,
    /**
     * Enumerated type, or an enumerator value name.
     */
    SE_TAG_FILTER_ENUM               = 0x00000010,
    /**
     * Global variables.
     */
    SE_TAG_FILTER_GLOBAL_VARIABLE    = 0x00000020,
    /**
     * Type definitions (specifically type aliases, like a typedef).
     */
    SE_TAG_FILTER_TYPEDEF            = 0x00000040,
    /**
     * Structured type (struct or record)
     */
    SE_TAG_FILTER_STRUCT             = 0x00000080,
    /**
     * Structured variant type (union)
     */
    SE_TAG_FILTER_UNION              = 0x00000100,
    /**
     * Label within a code block, or an anchor in XML/HTML.
     */
    SE_TAG_FILTER_LABEL              = 0x00000200,
    /**
     * Abstract class interface type.
     */
    SE_TAG_FILTER_INTERFACE          = 0x00000400,
    /**
     * Namespace or package scope.
     */
    SE_TAG_FILTER_PACKAGE            = 0x00000800,
    /**
     * Struct, union, or class member variable.
     */
    SE_TAG_FILTER_MEMBER_VARIABLE    = 0x00001000,
    /**
     * Read-only constant definition.
     */
    SE_TAG_FILTER_CONSTANT           = 0x00002000,
    /**
     * Class property.
     */
    SE_TAG_FILTER_PROPERTY           = 0x00004000,
    /**
     * Local variable.
     */
    SE_TAG_FILTER_LOCAL_VARIABLE     = 0x00008000,
    /**
     * Miscellaneous symbol, such as a friend declaration.
     */
    SE_TAG_FILTER_MISCELLANEOUS      = 0x00010000,
    /**
     * Database programming related symbol type, such as a table, column, 
     * index, trigger, or query. 
     */
    SE_TAG_FILTER_DATABASE           = 0x00020000,
    /**
     * GUI programming related type, such as a form, control, event, or menu.
     */
    SE_TAG_FILTER_GUI                = 0x00040000,
    /**
     * Source code preprocessing include statement.
     */
    SE_TAG_FILTER_INCLUDE            = 0x00080000,
    /**
     * Nested procedure or closure.
     */
    SE_TAG_FILTER_SUBPROCEDURE       = 0x00100000,
    /**
     * Unidentified symbol.
     */
    SE_TAG_FILTER_UNKNOWN            = 0x00200000,

    /**
     * No tag filters
     */
    SE_TAG_FILTER_NULL               = 0x00000000,
    /**
     * Composite set of flags matching any symbol type.
     */
    SE_TAG_FILTER_ANY_SYMBOL         = 0x003ffffe,
    /**
     * Composite set of flags matching anything.
     */
    SE_TAG_FILTER_ANYTHING           = 0x7ffffffe,

    /**
     * Composite set of flags matching any function, procedure or prototype.
     */
    SE_TAG_FILTER_ANY_PROCEDURE      = (SE_TAG_FILTER_PROTOTYPE         |
                                        SE_TAG_FILTER_PROCEDURE         |
                                        SE_TAG_FILTER_SUBPROCEDURE      ),
    /**
     * Composite set of flags matching any procedure or function, 
     * but not prototypes.
     */
    SE_TAG_FILTER_ANY_PROCEDURE_NO_PROTOTYPE = (
                                        SE_TAG_FILTER_PROCEDURE         |
                                        SE_TAG_FILTER_SUBPROCEDURE      ),
    /**
     * Composite set of flags matching any variable, whether global, local, 
     * a member of a class or struct, a property, or a constant.
     */
    SE_TAG_FILTER_ANY_DATA           = (SE_TAG_FILTER_GLOBAL_VARIABLE   | 
                                        SE_TAG_FILTER_MEMBER_VARIABLE   | 
                                        SE_TAG_FILTER_LOCAL_VARIABLE    | 
                                        SE_TAG_FILTER_PROPERTY          | 
                                        SE_TAG_FILTER_CONSTANT),
    /**
     * Composite set of flags matching any structured type (struct, union, interface)
     */
    SE_TAG_FILTER_ANY_STRUCT         = (SE_TAG_FILTER_STRUCT            |
                                        SE_TAG_FILTER_UNION             |
                                        SE_TAG_FILTER_INTERFACE         ),
    /**
     * Composite set of flags matching any constant type (define, enum, constant)
     */
    SE_TAG_FILTER_ANY_CONSTANT       = (SE_TAG_FILTER_DEFINE            |
                                        SE_TAG_FILTER_ENUM              |
                                        SE_TAG_FILTER_CONSTANT          ),
 
    /**
     * Any statement type.
     */
    SE_TAG_FILTER_STATEMENT          = 0x00400000,

    /**
     * Any annotation type or code annotation.
     */
    SE_TAG_FILTER_ANNOTATION         = 0x00800000,

    /**
     * Allows matching of symbols which have a private access level.
     * @see SE_TAG_FLAG_PRIVATE
     */
    SE_TAG_FILTER_SCOPE_PRIVATE      = 0x01000000,
    /**
     * Allows matching of symbols which have a protected access level.
     * @see SE_TAG_FLAG_PROTECTED
     */
    SE_TAG_FILTER_SCOPE_PROTECTED    = 0x02000000,
    /**
     * Allows matching of symbols which have a package-scope-only access level.
     * @see SE_TAG_FLAG_PACKAGE
     */
    SE_TAG_FILTER_SCOPE_PACKAGE      = 0x04000000,
    /**
     * Allows matching of symbols which have a public access level.
     * @see SE_TAG_FLAG_PUBLIC
     */
    SE_TAG_FILTER_SCOPE_PUBLIC       = 0x08000000,
    /**
     * Composite set of flags for any scope, public, private, protected, package.
     */
    SE_TAG_FILTER_ANY_ACCESS         = (SE_TAG_FILTER_SCOPE_PRIVATE   |
                                        SE_TAG_FILTER_SCOPE_PUBLIC    |
                                        SE_TAG_FILTER_SCOPE_PROTECTED |
                                        SE_TAG_FILTER_SCOPE_PACKAGE),
    /**
     * Matches symbols which are static. 
     * @see SE_TAG_FLAG_STATIC
     */
    SE_TAG_FILTER_SCOPE_STATIC       = 0x10000000,
    /**
     * Matches symbols which are marked extern.
     * @see SE_TAG_FLAG_EXTERN
     */
    SE_TAG_FILTER_SCOPE_EXTERN       = 0x20000000,
    /**
     * Composite set of flags for any scope, public, private, protected, extern.
     */
    SE_TAG_FILTER_ANY_SCOPE          = 0x7f000000,

    /**
     * Allows symbols from binary files to match, for example, 
     * tags in zip, dll, and tag files 
     *  
     * @deprecated This flag had to be moved to prevent sign-extension.  See below. 
     */
    SE_TAG_FILTER_NO_BINARY_OLD      = 0x80000000ull,
    /**
     * Allows symbols from binary files to match, for example, 
     * tags in zip, dll, and tag files
     */
    SE_TAG_FILTER_NO_BINARY          = 0x100000000ull,

};

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
static inline SETagFilterFlags& operator |= (SETagFilterFlags &lhs, const SETagFilterFlags rhs)
{
   lhs = static_cast<SETagFilterFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
   return lhs;
}
static inline SETagFilterFlags& operator &= (SETagFilterFlags &lhs, const SETagFilterFlags rhs)
{
   lhs = static_cast<SETagFilterFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
   return lhs;
}

static inline constexpr SETagFilterFlags operator | (const SETagFilterFlags lhs, const SETagFilterFlags rhs)
{
   return static_cast<SETagFilterFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagFilterFlags operator & (const SETagFilterFlags lhs, const SETagFilterFlags rhs)
{
   return static_cast<SETagFilterFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagFilterFlags operator ~(const SETagFilterFlags rhs)
{
   return static_cast<SETagFilterFlags>(~static_cast<VSUINT64>(rhs));
}
#endif

////////////////////////////////////////////////////////////////////////////////

/**
 * Tag context/property filtering flags.  These filters are used by 
 * various methods to narrow down a tagging search to a specific set of symbols 
 * with certain properties.
 */
enum SETagContextFlags : VSUINT64 {

   /**
    * No flags
    */
   SE_TAG_CONTEXT_NULL                = 0x00000000,

   /**
    * Allow local variables to be included in the match set.
    */
   SE_TAG_CONTEXT_ALLOW_LOCALS        = 0x00000001,
   /**
    * Allow symbols which have private access level. 
    * <p> 
    * Usually, this is used initially when searching within the current class, 
    * then turned off when the search crosses into parent classes or the 
    * global scope. 
    */
   SE_TAG_CONTEXT_ALLOW_PRIVATE       = 0x00000002,
   /**
    * Allow symbols which have protected access level. 
    * <p> 
    * Usually, this is used initially when seaching within the current class 
    * and parent classes, then turned off when the search crosses into the 
    * global scope or imported symbols. 
    */
   SE_TAG_CONTEXT_ALLOW_PROTECTED     = 0x00000004,
   /**
    * Allow symbols which have package access level.
    * <p> 
    * Usually this is used initially when searching within the current package, 
    * then this flag is turned off when the search crosses into other packages 
    * or the global scope. 
    */
   SE_TAG_CONTEXT_ALLOW_PACKAGE       = 0x00000008,
   /**
    * Only include symbols which are defined as volatile. 
    */
   SE_TAG_CONTEXT_ONLY_VOLATILE       = 0x00000010,
   /**
    * Only include symbols which are defined as const. 
    */
   SE_TAG_CONTEXT_ONLY_CONST          = 0x00000020,
   /**
    * Only include symbols which are not defined as static. 
    * This is useful when searching for symbols in a statically qualified 
    * symbol scope, such as "CLASSNAME::" in C++.
    */
   SE_TAG_CONTEXT_ONLY_STATIC         = 0x00000040,
   /**
    * Only include symbols which are not defined as static.
    */
   SE_TAG_CONTEXT_ONLY_NON_STATIC     = 0x00000080,
   /**
    * Only include variable declarations.
    */
   SE_TAG_CONTEXT_ONLY_DATA           = 0x00000100,
   /**
    * Only include function and procedures.
    */
   SE_TAG_CONTEXT_ONLY_FUNCS          = 0x00000200,
   /**
    * Only include classes, structs, records, unions, enums, groups, tables, 
    * and other structured type definitions. 
    */
   SE_TAG_CONTEXT_ONLY_CLASSES        = 0x00000400,
   /**
    * Only include package and namespace symbols.
    */
   SE_TAG_CONTEXT_ONLY_PACKAGES       = 0x00000800,
   /**
    * Only look for symbols actually defined within the scope of the 
    * current search class.  Do not include out-of-line symbol definitions. 
    * This is useful, for example in C++, in order to narrow down the results 
    * to avoid including duplicate symbols (proc and prototype). 
    */
   SE_TAG_CONTEXT_ONLY_INCLASS        = 0x00001000,
   /**
    * Only look for class constructors for the current search class.
    */
   SE_TAG_CONTEXT_ONLY_CONSTRUCTORS   = 0x00002000,
   /**
    * Only look for this symbol in the current search class.  Do not 
    * look in parent classes or the global scope. 
    */
   SE_TAG_CONTEXT_ONLY_THIS_CLASS     = 0x00004000,
   /**
    * Only look for this symbol in parent classes.  Do not include 
    * matches in the scope of the current class or global scope.
    */
   SE_TAG_CONTEXT_ONLY_PARENTS        = 0x00008000,
   /**
    * Look for this symbol in classes and interfaces that derive from the 
    * specified search class.  This is used, for example, to find all the 
    * methods that override a virtual method in an interface class. 
    */
   SE_TAG_CONTEXT_FIND_DERIVED        = 0x00010000,
   /**
    * Include anonymous symbols, such as anonymous classes or structs.
    */
   SE_TAG_CONTEXT_ALLOW_ANONYMOUS     = 0x00020000,
   /**
    * Only include local variables.
    */
   SE_TAG_CONTEXT_ONLY_LOCALS         = 0x00040000,
   /**
    * Allow any symbol type, even friend symbols and import statements.
    */
   SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE  = 0x00080000,
   /**
    * Only include symbols which are defined as final.
    */
   SE_TAG_CONTEXT_ONLY_FINAL          = 0x00100000,
   /**
    * Only include symbols which are not defined as final.
    */
   SE_TAG_CONTEXT_ONLY_NON_FINAL      = 0x00200000,
   /**
    * Only search for matches within the current 
    * (the symbols in the current file).
    */
   SE_TAG_CONTEXT_ONLY_CONTEXT        = 0x00400000,
   /**
    * Do not look for symbols in the global scope or imported into the global 
    * scope, only look within the current (and derived) class scopes and 
    * local variables. 
    */
   SE_TAG_CONTEXT_NO_GLOBALS          = 0x00800000,
   /**
    * Include forward class declarations and function declarations in 
    * the set of symbols found. 
    */
   SE_TAG_CONTEXT_ALLOW_FORWARD       = 0x01000000,
   /**
    * Find matching symbols without enforcing strict scoping rules.
    */
   SE_TAG_CONTEXT_FIND_LENIENT        = 0x02000000,
   /**
    * Find all definitions of this symbol, even after finding the nearest 
    * definition of this symbol in scope. 
    */
   SE_TAG_CONTEXT_FIND_ALL            = 0x04000000,
   /**
    * Look for this symbol in parent classes and interfaces. 
    */
   SE_TAG_CONTEXT_FIND_PARENTS        = 0x08000000,
   /**
    * Only look for symbols that are defined as templates or generics.
    */
   SE_TAG_CONTEXT_ONLY_TEMPLATES      = 0x10000000,
   /**
    * Do not look for selectors (as in Objective-C).
    */
   SE_TAG_CONTEXT_NO_SELECTORS        = 0x20000000,
   /**
    * Only look for symbols in the current file.
    */
   SE_TAG_CONTEXT_ONLY_THIS_FILE      = 0x40000000,
   /**
    * Do not look for symbols found nested in groups (as in COBOL), 
    * which are anonymous, opaque record types.
    */
   SE_TAG_CONTEXT_NO_GROUPS_OLD       = 0x80000000,
   /**
    * Do not look for symbols found nested in groups (as in COBOL), 
    * which are anonymous, opaque record types.
    */
   SE_TAG_CONTEXT_NO_GROUPS           = 0x0000001000000000ull,  
   /**
    * Match symbosl with "private" level access control. 
    * Private level symbols are visible to the current class only, 
    * unless another symbol has a friend relationship with the class. 
    */
   SE_TAG_CONTEXT_ACCESS_PRIVATE      = 0x0000000E,
   /**
    * Match symbols with "protected" level access control. 
    * Protected level symbols are visible to the current class and all 
    * classes derived from it, but not visible to unrelated classes, 
    * unless another symbol has a friend relationship with the class. 
    */
   SE_TAG_CONTEXT_ACCESS_PROTECTED    = 0x0000000C,
   /**
    * Match symbols with "package" level access control. 
    * Package level symbols are supposed to be visible within the package 
    * they are defined, but not visible in other packages unless imported.
    */
   SE_TAG_CONTEXT_ACCESS_PACKAGE      = 0x00000008,
   /**
    * Match symbols with "public" level access control. 
    * This flag is a no-op, since "public" symbols should always be visible. 
    */
   SE_TAG_CONTEXT_ACCESS_PUBLIC       = 0x00000000,
   /**
    * Default context flags, typical flags used for matching any 
    * symbol following normal scoping rules. 
    */
   SE_TAG_CONTEXT_ANYTHING            = SE_TAG_CONTEXT_NULL,


   /**
    * This pattern matching strategy is traditional prefix matching.  
    */
   SE_TAG_CONTEXT_MATCH_PREFIX        = 0x0000000000000000ull,
   /**
    * This pattern matching strategy is basic stone skipping with the 
    * restriction that matches must be at the start of a subword, or adjacent 
    * to the last letter matched. 
    */
   SE_TAG_CONTEXT_MATCH_STSK_SUBWORD  = 0x0000000100000000ull,
   /**
    * This pattern matching strategy is stone skipping with the restriction 
    * that each letter matched must be the first letter of a subword. 
    */
   SE_TAG_CONTEXT_MATCH_STSK_ACRONYM  = 0x0000000200000000ull,
   /**
    * This is the most general pattern matching strategy, purely working from 
    * left-to-right through the identifier, ignoring subword boundaries or 
    * adjacency. 
    */
   SE_TAG_CONTEXT_MATCH_STSK_PURE     = 0x0000000300000000ull,
   /**
    * This is simple substring matching.  The substring may start in the middle 
    * of a subword.  It is zero-hop stone skipping, every character matched 
    * after the initial match just be adjacent. 
    */
   SE_TAG_CONTEXT_MATCH_SUBSTRING     = 0x0000000400000000ull,
   /**
    * This is simple substring matching with the restriction that the match 
    * must start at the beginning of a subword.  It can be considered as a 
    * specialization of stone skipping with subword boundaries where only 
    * one subword is matched (potentially along with adjacent subwords). 
    */
   SE_TAG_CONTEXT_MATCH_SUBWORD       = 0x0000000500000000ull,
   /**
    * Simply determine if the symbol contains all the characters that are 
    * in the pattern, in any order, with no word boundaries.  If the pattern 
    * repeats a character, it must repeat at least as many times in the symbol 
    * name in order to match. 
    */
   SE_TAG_CONTEXT_MATCH_CHAR_BITSET   = 0x0000000600000000ull,
   /**
    * All context tagging pattern matching strategy flags.  Currently we 
    * support the following strategies, but more could be added later. 
    *  
    * <ul> 
    * <li>[default] Stone-skipping with word boundaries</li>
    * <li>Acronym-based stone-skipping</li>
    * <li>Pure stone-skipping</li>
    * <li>Simple substring matching</li>
    * <li>Subword prefix matching</li>
    * <li>Character matching in any order</li>
    * </ul> 
    *  
    * Stone-skipping is a pattern matching strategy that involves moving from 
    * the left to right across an identifier and plucking a letter here and 
    * there matching the search expression, potentially skipping letters in 
    * between, but always moving forward.  All the other strategies are kinds 
    * of stone-skipping strategies with additional requirements.
    *  
    * The default is stone skipping with subword boundaries.  This is generally 
    * the most useful strategy because it limits matches to subword prefixes 
    * without being excessively restrictive like the acronym strategy and the 
    * subword prefix strategy. 
    *  
    * All of these pattern matching strategies can be interpreted as 
    * case-sensitive or case-insensitive, but generally, it makes the most sense 
    * for them to be treated as case-insensitive.
    */
   SE_TAG_CONTEXT_MATCH_STRATEGY_FLAGS = ( SE_TAG_CONTEXT_MATCH_PREFIX        |
                                           SE_TAG_CONTEXT_MATCH_STSK_SUBWORD  |
                                           SE_TAG_CONTEXT_MATCH_STSK_ACRONYM  |
                                           SE_TAG_CONTEXT_MATCH_STSK_PURE     |
                                           SE_TAG_CONTEXT_MATCH_SUBSTRING     |
                                           SE_TAG_CONTEXT_MATCH_SUBWORD       |
                                           SE_TAG_CONTEXT_MATCH_CHAR_BITSET   ),

   /**
    * Attempt to find pattern matches assuming the first character of the 
    * pattern matches the first character of the symbol.  This allows us to 
    * narrow down the search field to symbols that start with a certain 
    * character, even though the pattern does not specify a prefix match 
    * as such.  This gives us a fast first pass for finding pattern matches. 
    */
   SE_TAG_CONTEXT_MATCH_FIRST_CHAR     = 0x0000000800000000ull,

   /**
    * Only look for symbols in the current workspace
    */
   SE_TAG_CONTEXT_ONLY_WORKSPACE       = 0x0000001000000000ull,
   /**
    * Only look for symbols in the current workspace (including auto-update tag files).
    */
   SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED = 0x0000002000000000ull,
   /**
    * Only look for symbols in the current workspace (including compiler tag files).
    */
   SE_TAG_CONTEXT_INCLUDE_COMPILER     = 0x0000004000000000ull,
   /**
    * Relax pattern matching order constraints to allow for possibility that 
    * the pattern could have one or two subwords or characters out or order. 
    * When pattern matching reaches the end of the pattern without matching 
    * the entire pattern, it will do a one-time restart from the beginning 
    * of the symbol the pattern is being matched against. 
    */
   SE_TAG_CONTEXT_MATCH_RELAX_ORDER    = 0x0000008000000000ull,


   /**
    * Only include symbols which are marked for export.  (SE_TAG_FLAG_EXPORT)
    */
   SE_TAG_CONTEXT_ONLY_EXPORT          = 0x0000010000000000ull,


   /**
    * All "allow" context tagging flags.
    */
   SE_TAG_CONTEXT_ALLOW_FLAGS         = ( SE_TAG_CONTEXT_ALLOW_LOCALS         |
                                          SE_TAG_CONTEXT_ALLOW_PRIVATE        |
                                          SE_TAG_CONTEXT_ALLOW_PROTECTED      |
                                          SE_TAG_CONTEXT_ALLOW_PACKAGE        |
                                          SE_TAG_CONTEXT_ALLOW_ANONYMOUS      |
                                          SE_TAG_CONTEXT_ALLOW_FORWARD        |
                                          SE_TAG_CONTEXT_ALLOW_ANY_TAG_TYPE   ),

   /**
    * All "restrictive" context tagging flags.
    */
   SE_TAG_CONTEXT_RESTRICTIVE_FLAGS   = ( SE_TAG_CONTEXT_ONLY_VOLATILE        |
                                          SE_TAG_CONTEXT_ONLY_CONST           |
                                          SE_TAG_CONTEXT_ONLY_STATIC          |
                                          SE_TAG_CONTEXT_ONLY_NON_STATIC      |
                                          SE_TAG_CONTEXT_ONLY_DATA            |
                                          SE_TAG_CONTEXT_ONLY_FUNCS           |
                                          SE_TAG_CONTEXT_ONLY_CLASSES         |
                                          SE_TAG_CONTEXT_ONLY_PACKAGES        |
                                          SE_TAG_CONTEXT_ONLY_INCLASS         |
                                          SE_TAG_CONTEXT_ONLY_CONSTRUCTORS    |
                                          SE_TAG_CONTEXT_ONLY_THIS_CLASS      |
                                          SE_TAG_CONTEXT_ONLY_PARENTS         |
                                          SE_TAG_CONTEXT_ONLY_LOCALS          |
                                          SE_TAG_CONTEXT_ONLY_FINAL           |
                                          SE_TAG_CONTEXT_ONLY_NON_FINAL       |
                                          SE_TAG_CONTEXT_ONLY_CONTEXT         |
                                          SE_TAG_CONTEXT_NO_GLOBALS           |
                                          SE_TAG_CONTEXT_ONLY_TEMPLATES       |
                                          SE_TAG_CONTEXT_NO_SELECTORS         |
                                          SE_TAG_CONTEXT_ONLY_THIS_FILE       |
                                          SE_TAG_CONTEXT_ONLY_EXPORT          |
                                          SE_TAG_CONTEXT_NO_GROUPS            ),


   /**
    * All "find" context tagging flags.
    */
   SE_TAG_CONTEXT_FIND_FLAGS          = ( SE_TAG_CONTEXT_FIND_ALL             |
                                          SE_TAG_CONTEXT_FIND_DERIVED         |
                                          SE_TAG_CONTEXT_FIND_LENIENT         |
                                          SE_TAG_CONTEXT_FIND_PARENTS         ),

};

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
static inline SETagContextFlags& operator |= (SETagContextFlags &lhs, const SETagContextFlags rhs)
{
   lhs = static_cast<SETagContextFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
   return lhs;
}
static inline SETagContextFlags& operator &= (SETagContextFlags &lhs, const SETagContextFlags rhs)
{
   lhs = static_cast<SETagContextFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
   return lhs;
}

static inline constexpr SETagContextFlags operator | (const SETagContextFlags lhs, const SETagContextFlags rhs)
{
   return static_cast<SETagContextFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagContextFlags operator & (const SETagContextFlags lhs, const SETagContextFlags rhs)
{
   return static_cast<SETagContextFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagContextFlags operator ~(const SETagContextFlags rhs)
{
   return static_cast<SETagContextFlags>(~static_cast<VSUINT64>(rhs));
}
#endif
