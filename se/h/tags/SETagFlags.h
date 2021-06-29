////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagFlags.h
// Description:   Declaration of enumerated type for tag flags (properties).
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"

/**
 * Flags associated with tags, denoting access restrictions and
 * and other attributes of class members (proc's, proto's, and var's).
 * 
 * There are a few special cases:
 * <ul>
 * <li>NOT virtual and NOT static implies normal class method
 * <li>NOT protected and NOT private implies public
 * <li>NOT const implies normal read/write access
 * <li>NOT volatile implies normal optimizations are safe
 * <li>NOT template implies normal class definition
 * </ul>
 */
enum SETagFlags : VSUINT64 {
   /**
    * null/default/empty/unset tag flags
    */
   SE_TAG_FLAG_NULL = 0,

   /**
    * virtual function (instance)
    */
   SE_TAG_FLAG_VIRTUAL           = 0x00000001,
   /**
    * static method / member (class)
    */
   SE_TAG_FLAG_STATIC            = 0x00000002,
   /**
    * access flags (public/protected/private/package)
    */
   SE_TAG_FLAG_ACCESS            = 0x0000000C,
   /**
    * public access (test equality with flags&access)
    */
   SE_TAG_FLAG_PUBLIC            = 0x00000000,
   /**
    * protected access
    */
   SE_TAG_FLAG_PROTECTED         = 0x00000004,
   /**
    * private access
    */
   SE_TAG_FLAG_PRIVATE           = 0x00000008,
   /**
    * package access (for Java)
    */
   SE_TAG_FLAG_PACKAGE           = 0x0000000C,
   /**
    * const
    */
   SE_TAG_FLAG_CONST             = 0x00000010,
   /**
    * final
    */
   SE_TAG_FLAG_FINAL             = 0x00000020,
   /**
    * abstract/deferred method
    */
   SE_TAG_FLAG_ABSTRACT          = 0x00000040,
   /**
    * inline / out-of-line method
    */
   SE_TAG_FLAG_INLINE            = 0x00000080,
   /**
    * overloaded operator
    */
   SE_TAG_FLAG_OPERATOR          = 0x00000100,
   /**
    * class constructor
    */
   SE_TAG_FLAG_CONSTRUCTOR       = 0x00000200,
   /**
    * volatile method
    */
   SE_TAG_FLAG_VOLATILE          = 0x00000400,
   /**
    * Template class or template function. 
    * This flag can also used for template parameters. 
    */
   SE_TAG_FLAG_TEMPLATE          = 0x00000800,
   /**
    * part of class interface?
    */
   SE_TAG_FLAG_INCLASS           = 0x00001000,
   /**
    * class destructor
    */
   SE_TAG_FLAG_DESTRUCTOR        = 0x00002000,
   /**
    * class constructor or destructor
    */
   SE_TAG_FLAG_CONST_DESTR       = 0x00002200,
   /**
    * synchronized (thread safe)
    */
   SE_TAG_FLAG_SYNCHRONIZED      = 0x00004000,
   /**
    * transient / persistent data
    */
   SE_TAG_FLAG_TRANSIENT         = 0x00008000,
   /**
    * Java native method?
    */
   SE_TAG_FLAG_NATIVE            = 0x00010000,
   /**
    * Tag was part of macro expansion?
    */
   SE_TAG_FLAG_MACRO             = 0x00020000,
   /**
    * "extern" C prototype (not local)
    */
   SE_TAG_FLAG_EXTERN            = 0x00040000,
   /**
    * Prototype which could be a variable, or variable which could be a prototye. 
    * Anonymous union.  Unnamed structs.
    */
   SE_TAG_FLAG_MAYBE_VAR         = 0x00080000,
   /**
    * Anonymous structure or class
    */
   SE_TAG_FLAG_ANONYMOUS         = 0x00100000,
   /**
    * mutable C++ class member
    */
   SE_TAG_FLAG_MUTABLE           = 0x00200000,
   /**
    * external macro (COBOL copy file)
    */
   SE_TAG_FLAG_EXTERN_MACRO      = 0x00400000,
   /**
    * 01 level var in COBOL linkage section
    */
   SE_TAG_FLAG_LINKAGE           = 0x00800000,
   /**
    * For C# partial class, struct, or interface
    */
   SE_TAG_FLAG_PARTIAL           = 0x01000000,
   /**
    * Tagging should ignore this tag
    */
   SE_TAG_FLAG_IGNORE            = 0x02000000,
   /**
    * Forward class/interface/struct/union declaration
    */
   SE_TAG_FLAG_FORWARD           = 0x04000000,
   /**
    * Opaque enumerated type (unlike C/C++ enum) 
    * Also used for opaque namespace import. 
    */
   SE_TAG_FLAG_OPAQUE            = 0x08000000,
   /**
    * Can tagging be restarted at this symbol?
    */
   SE_TAG_FLAG_RESTARTABLE       = 0x10000000,
   /**
    * Implicitely declared local variable
    */
   SE_TAG_FLAG_IMPLICIT          = 0x20000000,
   /**
    * Local variable is visible to entire function
    */
   SE_TAG_FLAG_UNSCOPED          = 0x40000000,
   /**
    * variable which could be a prototype
    */
   SE_TAG_FLAG_MAYBE_PROTO       = SE_TAG_FLAG_MAYBE_VAR,
   /**
    * Anononymous union or unnamed struct
    */
   SE_TAG_FLAG_ANONYMOUS_UNION   = SE_TAG_FLAG_MAYBE_VAR,

   /**
    * Ignore this symbol for any purpose other than the Defs tool window.
    */
   SE_TAG_FLAG_OUTLINE_ONLY      = 0x0000000100000000ULL,
   /**
    * Hide this symbol when displaying in the Defs tool window
    */
   SE_TAG_FLAG_OUTLINE_HIDE      = 0x0000000200000000ULL,

   /**
    * This symbol overrides an earlier definition of the same symbol. 
    */
   SE_TAG_FLAG_OVERRIDE          = 0x0000000400000000ULL,
   /**
    * This local variable shadows an earlier definition of the same symbol, 
    * or an be shadowed by another subsequent local variable. 
    */
   SE_TAG_FLAG_SHADOW            = 0x0000000800000000ULL,

   /**
    * This flag indicates that for this language, the logic to propagate tag 
    * flags, such as static, inline, virtual, public, private, protected, etc., 
    * from declarations to definitinos (and vice-versa), is never required. 
    * Using this flag can improve tag file build performance by eliminating 
    * any attempt to propagate tag flags. 
    */
   SE_TAG_FLAG_NO_PROPAGATE      = 0x0000001000000000ULL,

   /**
    * internal access
    */
   SE_TAG_FLAG_INTERNAL          = 0x0000002000000000ULL,

   /**
    * access flags (public/protected/private/package/internal)
    */
   SE_TAG_FLAG_INTERNAL_ACCESS   = 0x000000200000000CULL,

   SE_TAG_FLAG_INTERNAL_PUBLIC   = 0x0000002000000000ULL,
   SE_TAG_FLAG_INTERNAL_PROTECTED= 0x0000002000000004ULL,
   SE_TAG_FLAG_INTERNAL_PRIVATE  = 0x0000002000000008ULL,
   SE_TAG_FLAG_INTERNAL_PACKAGE  = 0x000000200000000CULL,

   /**
    * This flag indicates that the return type of a variable is inferred 
    * from the type of the varible's initializer value.  For example, 
    * "auto xxx = yyy;" "xxx" assumes the return type of "yyy".    
    */
   SE_TAG_FLAG_INFERRED          = 0x0000004000000000ULL,

   /**
    * C++ constexpr
    */
   SE_TAG_FLAG_CONSTEXPR         = 0x0000008000000000ULL,

   /**
    * Indicates that this symbol has not documentation comment. 
    * This is set to handle the negative case for documentation comment lookup 
    * optimization using a minimal amount of memory. 
    */
   SE_TAG_FLAG_NO_COMMENT        = 0x0000010000000000ULL,

   /**
    * C++20 consteval
    */
   SE_TAG_FLAG_CONSTEVAL         = 0x0000020000000000ULL,
   /**
    * C++20 constinit
    */
   SE_TAG_FLAG_CONSTINIT         = 0x0000040000000000ULL,
   /**
    * Export symbol from module (C++ 20)
    */
   SE_TAG_FLAG_EXPORT            = 0x0000080000000000ULL,
};

////////////////////////////////////////////////////////////////////////////////

#ifdef __cplusplus
static inline SETagFlags& operator |= (SETagFlags &lhs, const SETagFlags rhs)
{
   lhs = static_cast<SETagFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
   return lhs;
}
static inline SETagFlags& operator &= (SETagFlags &lhs, const SETagFlags rhs)
{
   lhs = static_cast<SETagFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
   return lhs;
}

static inline constexpr SETagFlags operator | (const SETagFlags lhs, const SETagFlags rhs)
{
   return static_cast<SETagFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagFlags operator & (const SETagFlags lhs, const SETagFlags rhs)
{
   return static_cast<SETagFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagFlags operator ~(const SETagFlags rhs)
{
   return static_cast<SETagFlags>(~static_cast<VSUINT64>(rhs));
}
#endif

////////////////////////////////////////////////////////////////////////////////

/** 
 * @return
 * Return the string representing the symbol name or expression for the given 
 * set of tag flags.
 * 
 * @param tagFlags         bitset of tag flags (SE_TAG_FLAG_*) 
 * @param useCompactNames  (optional, default false) use short names
 */
VSDLLEXPORT const slickedit::SEString SETagFlagsGetSymbolName(const SETagFlags tag_flags, const bool useCompactNames=false);

