#ifndef SE_ID_EXPRESSION_INFO_H
#define SE_ID_EXPRESSION_INFO_H

#include "slickedit/SEString.h"
#include "slickedit/SEArray.h"
#include "tags/SETokenList.h"

namespace slickedit {

/**
 * This enumerated type is used to represent the flags used for 
 * constructing and evaluating the expression information under 
 * the cursor. 
 */
enum SETagExpressionInfoFlags {

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

   // SlickEdit reserves the first 28 bits.  You may
   // use the other 4 bits for anything you want.
   VSAUTOCODEINFO_USER1                               = 0x10000000,
   VSAUTOCODEINFO_USER2                               = 0x20000000,
   VSAUTOCODEINFO_USER3                               = 0x40000000,
   VSAUTOCODEINFO_USER4                               = 0x80000000
};

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
    * Array of strings for error message arguments. 
    * Refer to codehelp.e VSCODEHELPRC_*.
    */
   SEArray<SEString> *mpErrorArgs;
   /**
    * set to prefix expression
    */
   SEString mPrefixExpr;
   /**
    * set to last identifier
    */
   SEString mLastID;
   /**
    * last identifier start column
    */
   unsigned int mLastIDStartCol;
   /**
    * last identifier start offset
    */
   unsigned int mLastIDStartOffset;
   /**
    * bitset of VSAUTOCODEINFO_*
    */
   VSUINT64 mInfoFlags;
   /**
    * start offset of prefix expression
    */
   unsigned int mPrefixStartOffset;
   /**
    * supplementary information (lang specific)
    */
   SEString mOtherExprInfo;

   /**
    * Copy the contents of this struct out to the given Slick-C 
    * struct VS_TAG_IDEXP_INFO.
    * 
    * @param idexp_info    Slick-C struct to copy out contents to
    */
   void copyOut(VSHREFVAR idexp_info) const;

};


} // namespace slickedit

#endif

