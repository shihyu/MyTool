////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SEIDExpressionInfo.h
// Description:   Declaration of class for representing the symbol under the
//                cursor and the expression context leading up to it.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"
#include "tags/SETokenList.h"

namespace slickedit {

/**
 * This enumerated type is used to represent the flags used for 
 * constructing and evaluating the expression information under 
 * the cursor. 
 */
enum SETagExpressionInfoFlags : VSUINT64 {

   // No flags set
   VSAUTOCODEINFO_NULL                                = 0x0,

   // Do function argument help
   VSAUTOCODEINFO_DO_FUNCTION_HELP                    = 0x1,

   // Do auto-list members of class or list-symbols
   VSAUTOCODEINFO_DO_LIST_MEMBERS                     = 0x2,

   // the identifier is followed by a parenthesis
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN            = 0x4,

   // Indicate function argument help has been 
   // requested for template class type declaration.
   //    stack<...
   VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST                 = 0x8,

   // C++ class initializer list
   //    MYCLASS::MYCLASS(..): a(
   VSAUTOCODEINFO_IN_INITIALIZER_LIST                 = 0x10,

   // Argument list for call using function pointer
   //    (*pfn)(a,b...
   VSAUTOCODEINFO_IN_FUNCTION_POINTER_ARGLIST         = 0x10,

   // May be in C++ class initializer list
   //    MYCLASS(..): a(
   VSAUTOCODEINFO_MAYBE_IN_INITIALIZER_LIST           = 0x20,

   // Either var with parenthesized initializer
   // or a prototype declaration.
   //    MYCLASS a(
   VSAUTOCODEINFO_VAR_OR_PROTOTYPE_DECL               = 0x40,

   // Option to _c_fcthelp_get to just check in
   // cursor is inside template declaration.
   VSAUTOCODEINFO_IN_TEMPLATE_ARGLIST_TEST            = 0x80,

   // True if an operator was typed rather than an 
   // explicit list-members or function argument 
   // help command.
   VSAUTOCODEINFO_OPERATOR_TYPED                      = 0x100,

   // True if context is after goto keyword
   //    goto label;
   VSAUTOCODEINFO_IN_GOTO_STATEMENT                   = 0x200,

   // True if context is after throw keyword
   //    throw excepshun;
   VSAUTOCODEINFO_IN_THROW_STATEMENT                  = 0x400,

   // Needed for BASIC like languages like SABL
   VSAUTOCODEINFO_ALLOW_SPACE_IN_LIST_MEMBERS         = 0x800,

   // List syntax expansion choices (kind of obsolete)
   VSAUTOCODEINFO_DO_SYNTAX_EXPANSION                 = 0x1000,

   // void foo::bar(), foo refers to class only
   VSAUTOCODEINFO_NOT_A_FUNCTION_CALL                 = 0x2000,

   // #<here>
   VSAUTOCODEINFO_IN_PREPROCESSING                    = 0x4000,

   // In javadoc comment or XMLDoc comment
   VSAUTOCODEINFO_IN_JAVADOC_COMMENT                  = 0x8000,

   // auto list parameters (type analysis)
   VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS                 = 0x10000,

   // in string or numeric argument
   //    "string %<printf escape here> rest of string"
   //    "string \<escape sequence here> rest of string"
   VSAUTOCODEINFO_IN_STRING_OR_NUMBER                 = 0x20000,

   // has '*' or '&' as part of prefixexp
   VSAUTOCODEINFO_HAS_REF_OPERATOR                    = 0x40000,

   // has [] array accessor after lastid
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACKET          = 0x80000,

   // import MYCLASS;
   VSAUTOCODEINFO_IN_IMPORT_STATEMENT                 = 0x100000,

   // class CName; struct tm; union Boss;
   VSAUTOCODEINFO_HAS_CLASS_SPECIFIER                 = 0x200000,

   // x * y, cursor on *
   VSAUTOCODEINFO_CPP_OPERATOR                        = 0x400000,

   // #include <here>
   VSAUTOCODEINFO_IN_PREPROCESSING_ARGS               = 0x800000,

   // mask for context tagging actions
   VSAUTOCODEINFO_DO_ACTION_MASK = (VSAUTOCODEINFO_DO_AUTO_LIST_PARAMS|VSAUTOCODEINFO_DO_FUNCTION_HELP|VSAUTOCODEINFO_DO_LIST_MEMBERS|VSAUTOCODEINFO_OPERATOR_TYPED),

   // Objective-C specific tagging case
   VSAUTOCODEINFO_OBJECTIVEC_CONTEXT                  = 0x1000000,

   // sub foo; func bar; proc boogity;
   VSAUTOCODEINFO_HAS_FUNCTION_SPECIFIER              = 0x2000000,

   // has assignment operator after the identifier
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_ASSIGNMENT       = 0x4000000,

   // has C++ {} universal initializer after the identifier
   VSAUTOCODEINFO_LASTID_FOLLOWED_BY_BRACES           = 0x8000000,

   // SlickEdit reserves the first 28 bits.  You may
   // use the other 4 bits for anything you want.
   VSAUTOCODEINFO_USER1                               = 0x10000000,
   VSAUTOCODEINFO_USER2                               = 0x20000000,
   VSAUTOCODEINFO_USER3                               = 0x40000000,
   VSAUTOCODEINFO_USER4                               = 0x80000000,

   // The final 30-bits of this set of flags are also reserved for SlickEdit's use
   VSAUTOCODEINFO_FUTURE_64_BIT_FLAGS                 = 0xFFFFFFFF00000000UL,
};


////////////////////////////////////////////////////////////////////////////////

static inline SETagExpressionInfoFlags& operator |= (SETagExpressionInfoFlags &lhs, const SETagExpressionInfoFlags rhs)
{
   lhs = static_cast<SETagExpressionInfoFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
   return lhs;
}
static inline SETagExpressionInfoFlags& operator &= (SETagExpressionInfoFlags &lhs, const SETagExpressionInfoFlags rhs)
{
   lhs = static_cast<SETagExpressionInfoFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
   return lhs;
}

static inline constexpr SETagExpressionInfoFlags operator | (const SETagExpressionInfoFlags lhs, const SETagExpressionInfoFlags rhs)
{
   return static_cast<SETagExpressionInfoFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagExpressionInfoFlags operator & (const SETagExpressionInfoFlags lhs, const SETagExpressionInfoFlags rhs)
{
   return static_cast<SETagExpressionInfoFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagExpressionInfoFlags operator ~(const SETagExpressionInfoFlags rhs)
{
   return static_cast<SETagExpressionInfoFlags>(~static_cast<VSUINT64>(rhs));
}


////////////////////////////////////////////////////////////////////////////////

/**
 * This struct is filled in by the language specific 
 * vs[lang]_get_expression_info() callback function. 
 */
struct VSDLLEXPORT SEIDExpressionInfo {

   /**
    * Default constructor.
    */
   SEIDExpressionInfo();
   /**
    * Copy constructor
    */
   SEIDExpressionInfo(const SEIDExpressionInfo& src);
   /**
    * Move constructor
    */
   SEIDExpressionInfo(SEIDExpressionInfo&& src);
   /** 
    * Destructor
    */
   ~SEIDExpressionInfo();
   /**
    * Assignment operator
    */
   SEIDExpressionInfo & operator = (const SEIDExpressionInfo& src);
   /**
    * Move assignment operator
    */
   SEIDExpressionInfo & operator = (SEIDExpressionInfo&& src);

   /**
    * Reset everything to inital state.
    */
   void clear();
   /**
    * @return Return 'true' if this object is in it's initial NULL state.
    */
   const bool isNull() const;
   /**
    * @return Return 'true' if this object is in it's initial state.
    */
   const bool isEmpty() const;

   /**
    * @return Return the prefix expression.  This is generally the expression 
    *         immediately to the left of the identifier under the cursor.
    *         This expression is evaluated in order to determine what class
    *         to list members of when completing the identifier under the cursor. 
    */
   SEString getPrefixExpression() const;
   /**
    * Set the prefix expression.
    */
   void setPrefixExpression(const SEString &prefixExpr);
   /**
    * Append the given text to the end of the prefix expression.
    */
   void appendPrefixExpression(const SEString &s);
   /**
    * Prepend the given text to the end of the prefix expression.
    */
   void prependPrefixExpression(const SEString &s);

   /**
    * @return Return the start offset of the entire prefix expression.
    */
   const unsigned int getPrefixStartOffset() const;
   /**
    * Set the start offset of the entire prefix expression.
    */
   void setPrefixStartOffset(const unsigned int seekPosition);

   /**
    * @return Return the start token ID for the prefix expression.
    */
   const SETokenID getPrefixStartTokenID() const;
   /**
    * Set the start token ID for the prefix expression.
    */
   void setPrefixStartTokenID(const SETokenID tokenId);

   /**
    * @return Return the last identifier in the prefix expression. 
    *         This is generally the identifier under the cursor.
    */
   SEString getLastIdentifier() const;
   /**
    * @return 
    * Return the prefix of the last identifier in the prefix expression, up to
    * the cursor position.  This is generally the identifier under the cursor.
    */
   SEString getLastIdentifierPrefix() const;
   /**
    * Set the last identifier in the prefix expression. 
    * This is generally the identifier under the cursor.
    */
   void setLastIdentifier(const SEString &id);

   /**
    * @return 
    * Return the last identifier start column (the offset from the 
    * beginning of the line the last identifier is located on). 
    */
   const int getLastIdStartColumn() const;
   /**
    * @return 
    * Return the last identifier start column (imaginary editor column). 
    * This method requires an editor control and is not thread-safe.
    */
   const unsigned int getLastIdStartColumn(int editorctl_wid) const;
   /**
    * Set the last identifier start column (the offset from the 
    * beginning of the line the last identifier is located on). 
    * A negative number indicates an imaginary column offset. 
    * A positive number indicates a real offset from the start of the line. 
    */
   void setLastIdStartColumn(int col);

   /**
    * @return Return the last identifier token ID
    */
   const SETokenID getLastIdStartTokenID() const;
   /**
    * Set the last identifier start offset
    */
   void setLastIdStartTokenID(const SETokenID tokenId);

   /**
    * @return Return the last identifier start offset
    */
   const unsigned int getLastIdStartOffset() const;
   /**
    * Set the last identifier start offset
    */
   void setLastIdStartOffset(const unsigned int seekPosition);

   /**
    * @return Return the seek position that the cursor is at.
    */
   const unsigned int getCursorOffset() const;
   /**
    * @return Return the column that the cursor is in.
    */
   const unsigned int getCursorLineOffset() const;
   /**
    * @return Return the column that the cursor is in (imaginary editor column). 
    * This method requires an editor control and is not thread-safe.
    */
   const unsigned int getCursorColumn(int editorctl_wid=0) const;
   /**
    * Set the column that the cursor is in
    */
   void setCursorOffset(const unsigned int seekPosition);

   /**
    * @return Return a bitset of VSAUTOCODEINFO_* flags, which indicate 
    * various attrributes about the prefix expression. 
    *  
    * @see SETagExpressionInfoFlags 
    */
   const SETagExpressionInfoFlags getInfoFlags() const;
   /**
    * Set the bitset of VSAUTOCODEINFO_* flags, which indicate 
    * various attrributes about the prefix expression. 
    *  
    * @see SETagExpressionInfoFlags 
    */
   void setInfoFlags(const SETagExpressionInfoFlags flags);
   /**
    * Set additional bits in VSAUTOCODEINFO_* flags. 
    *  
    * @see setInfoFlags
    * @see SETagExpressionInfoFlags 
    */
   void addInfoFlags(const SETagExpressionInfoFlags flags);
   /**
    * Clear specified bits of VSAUTOCODEINFO_* flags. 
    *  
    * @see setInfoFlags
    * @see SETagExpressionInfoFlags 
    */
   void removeInfoFlags(const SETagExpressionInfoFlags flags);

   /**
    * @return Return the supplementary information (language specific)
    */
   SEString getOtherExprInfo() const;
   /**
    * Set the supplementary information (language specific)
    */
   void setOtherExprInfo(const SEString &info);

   /**
    * Copy the contents of this struct out to the given Slick-C 
    * struct VS_TAG_IDEXP_INFO.
    * 
    * @param idexp_info    Slick-C struct to copy out contents to 
    * @param editorctl_wid current editor control wid 
    */
   void copyOut(VSHREFVAR idexp_info, int editorctl_wid=0) const;

   /**
    * Compute a hash value for this class instance.
    */
   const unsigned int hash() const;

private:

   SESharedPointer<struct SEPrivateIDExprInfo> mpIDExprInfo;
};


} // namespace slickedit

extern unsigned cmHashKey(const slickedit::SEIDExpressionInfo &idexp);

