////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SEReturnTypeInfo.h
// Description:   Declaration of class for representing a return type.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"
#include "tags/SETagInformation.h"

namespace slickedit {

/** 
 * Bit flags for _lang_get_return_type_of_prefix related functions. 
 * Stored in VS_TAG_RETURN_TYPE.return_flags, and used in the 
 * _lang_find_context_tags() callbacks to narrow down matches. 
 */
enum SETagReturnTypeFlags : unsigned int {
   /**
    * Empty set of return type flags
    */
   VSCODEHELP_RETURN_TYPE_NULL            = 0x00000000,
   /**
    * Indicates that access to private members of this type is permitted.
    */
   VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS  = 0x00000002,
   /**
    * Indicates that only "const" members of this type should be listed.
    */
   VSCODEHELP_RETURN_TYPE_CONST_ONLY      = 0x00000004,
   /**
    * Indicates that only "volatile" members of this type should be listed.
    */
   VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY   = 0x00000008,
   /**
    * Indicates that only static class members (and constants and subtypes) 
    * should be listed. 
    */
   VSCODEHELP_RETURN_TYPE_STATIC_ONLY     = 0x00000010,
   /**
    * Indicates that only global symbols should be listed.  Members of 
    * the current class and local variables should be omitted. 
    */
   VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY    = 0x00000020,
   /**
    * Indicates that the return type evaluated to an array type.
    */
   VSCODEHELP_RETURN_TYPE_ARRAY           = 0x00000040,
   /**
    * Indicates that the return type evaluated to a hash table 
    * or associative array type.
    */
   VSCODEHELP_RETURN_TYPE_HASHTABLE       = 0x00000080,
   /**
    * Indicates that the return type evaluated to a hash table 
    * or associative array type.
    */
   VSCODEHELP_RETURN_TYPE_HASHTABLE2      = 0x00000100,
   /**
    * Indicates that the return type is a language-specific 
    * builtin array or hash table collection type.
    */
   VSCODEHELP_RETURN_TYPE_ARRAY_TYPES     = (VSCODEHELP_RETURN_TYPE_ARRAY|
                                             VSCODEHELP_RETURN_TYPE_HASHTABLE|
                                             VSCODEHELP_RETURN_TYPE_HASHTABLE2),
   /**
    * Indicates that the return type is an "output" parameter.
    */
   VSCODEHELP_RETURN_TYPE_OUT             = 0x00000200,
   /**
    * Indicates that the return type is a pass-by-reference parameter.
    */
   VSCODEHELP_RETURN_TYPE_REFERENCE       = 0x00000400,
   VSCODEHELP_RETURN_TYPE_REF             = VSCODEHELP_RETURN_TYPE_REFERENCE,
   /**
    * Indicates that only members of the current class should be listed.
    */
   VSCODEHELP_RETURN_TYPE_INCLASS_ONLY    = 0x00000800,
   /**
    * Indicates that only files should be listed.  This applies when 
    * completing #iclude statements. 
    */
   VSCODEHELP_RETURN_TYPE_FILES_ONLY      = 0x00001000,
   /**
    * Indicates that only function names should be listed. 
    * Usually this is set when the symbol in question is followed by 
    * an open parenthesis. 
    */
   VSCODEHELP_RETURN_TYPE_FUNCS_ONLY      = 0x00002000,
   /**
    * Indicates that only variables should be listed.
    */
   VSCODEHELP_RETURN_TYPE_DATA_ONLY       = 0x00004000,
   /**
    * Indicates that the return type evaluated to a language builtin type.
    */
   VSCODEHELP_RETURN_TYPE_BUILTIN         = 0x00008000,
   /**
    * Indicates that only members of the evaluated class should be listed, 
    * that is, we should not look for overrides of this symbol in derived 
    * classes.  However, symbols in parent classes are permitted. 
    */
   VSCODEHELP_RETURN_TYPE_THIS_CLASS_ONLY = 0x00010000,
   /**
    * Indicates that only non-static class members 
    * (and constants and subtypes) should be listed. 
    */
   VSCODEHELP_RETURN_TYPE_NON_STATIC_ONLY = 0x00020000,
   /**
    * Indicates that the return type is a pass-by-value (input only) parameter.
    */
   VSCODEHELP_RETURN_TYPE_IN              = 0x00040000,
   /**
    * Indicates that the return type is only a placeholder -- so we should 
    * ignore it if we find it in the return type results cache (visited).
    */
   VSCODEHELP_RETURN_TYPE_IS_FAKE         = 0x00080000,
   /**
    * Indicates that the return type is a pointer to another type
    */
   VSCODEHELP_RETURN_TYPE_POINTER         = 0x00100000,
   /**
    * Indicates that the return type is a template type or template instance
    */
   VSCODEHELP_RETURN_TYPE_TEMPLATE        = 0x00200000,
   /**
    * Indicates that the return type is a function call type
    */
   VSCODEHELP_RETURN_TYPE_FUNCTION        = 0x00400000,
   /**
    * Indicates that the return type is a type alias, such as a C/C++ typedef.
    */
   VSCODEHELP_RETURN_TYPE_TYPEDEF         = 0x00800000,
   /**
    * Indicates that the return type is a pointer, array, hash table, template, 
    * function, typedef, or other structured return type. 
    */
   VSCODEHELP_RETURN_TYPE_SPECIAL = (VSCODEHELP_RETURN_TYPE_ARRAY|
                                     VSCODEHELP_RETURN_TYPE_HASHTABLE|
                                     VSCODEHELP_RETURN_TYPE_HASHTABLE2|
                                     VSCODEHELP_RETURN_TYPE_POINTER|
                                     VSCODEHELP_RETURN_TYPE_REF|
                                     VSCODEHELP_RETURN_TYPE_TYPEDEF|
                                     VSCODEHELP_RETURN_TYPE_TEMPLATE|
                                     VSCODEHELP_RETURN_TYPE_FUNCTION),
};

////////////////////////////////////////////////////////////////////////////////

static inline SETagReturnTypeFlags& operator |= (SETagReturnTypeFlags &lhs, const SETagReturnTypeFlags rhs)
{
   lhs = static_cast<SETagReturnTypeFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
   return lhs;
}
static inline SETagReturnTypeFlags& operator &= (SETagReturnTypeFlags &lhs, const SETagReturnTypeFlags rhs)
{
   lhs = static_cast<SETagReturnTypeFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
   return lhs;
}

static inline constexpr SETagReturnTypeFlags operator | (const SETagReturnTypeFlags lhs, const SETagReturnTypeFlags rhs)
{
   return static_cast<SETagReturnTypeFlags>(static_cast<VSUINT64>(lhs) | static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagReturnTypeFlags operator & (const SETagReturnTypeFlags lhs, const SETagReturnTypeFlags rhs)
{
   return static_cast<SETagReturnTypeFlags>(static_cast<VSUINT64>(lhs) & static_cast<VSUINT64>(rhs));
}
static inline constexpr SETagReturnTypeFlags operator ~(const SETagReturnTypeFlags rhs)
{
   return static_cast<SETagReturnTypeFlags>(~static_cast<VSUINT64>(rhs));
}

////////////////////////////////////////////////////////////////////////////////

/** 
 * This class is used to represent evaluated return type information when 
 * doing context tagging code analysis.  The relationships between prefix 
 * expressions, symbol information, and return type information is as follows. 
 * <ul> 
 * <li>In a Context Tagging&reg; expression, the prefix expression is the 
 *     part of an expression before the current identifier under the cursor.
 *     A prefix expression is evaluated and the type that is found is
 *     represented as a return type (this class).
 * <li>Symbols have return types (or declared types).  When the return type 
 *     of a symbol is evaluated, it is represented as a return type (this class).
 * <li>In the course of evaluating an return type or evaluating a prefix 
 *     expression, symbols will be looked up and identified as the symbols
 *     which declare or define the variables, functions, or types involved in
 *     the expression.  The return types of these symbols will be evaluated
 *     and represented as a return type (this class).
 * </ul> 
 *  
 * The data flow is like this:
 * <pre> 
 *     ---------------          -----------------          ---------------
 *    |  Expression   |        |  Symbol (tag)   |        |  Return Type  |
 *    |     prefix    |  ====> |    name         |        |     type      |
 *    |     id        |        |    return type  |  ===>  |     args      |
 *    |     location  |        |    location     |        |     flags     |
 *     ---------------          -----------------          ---------------
 * </pre> 
 *  
 * The key components of return type information is the return type string, 
 * which is an class name string, as it is known within the tag database, 
 * using package separators between components of the package name and nested 
 * class names.  It also includes a set of flags indicating properties of the 
 * return type.  Most of these are gathered from properties of the symbol or 
 * the context in which the symbol was referenced (id expression info). 
 * Finally, for function pointer types and template types, it can include 
 * argument information. 
 *  
 * @see SETagInformation 
 * @see SEIDExpressionInfo 
 * @see SETagReturnTypeFlags
 */
struct VSDLLEXPORT SEReturnTypeInfo { 
public:

   /**
    * Default constructor (creates a null return type object).
    */
   SEReturnTypeInfo();
   /**
    * Default constructor (creates an empty return type object, if allocate=true).
    */
   SEReturnTypeInfo(const bool allocate);
   /**
    * Copy constructor
    */
   SEReturnTypeInfo(const SEReturnTypeInfo& src);
   /**
    * Move constructor
    */
   SEReturnTypeInfo(SEReturnTypeInfo&& src);
   /** 
    * Destructor
    */
   ~SEReturnTypeInfo();
   /**
    * Assignment operator
    */
   SEReturnTypeInfo & operator = (const SEReturnTypeInfo& src);
   /**
    * Move assignment operator
    */
   SEReturnTypeInfo & operator = (SEReturnTypeInfo&& src);

   /**
    * Equality comparison operator
    */
   bool operator == (const SEReturnTypeInfo& src) const;
   /**
    * Inequality comparison operator
    */
   bool operator != (const SEReturnTypeInfo& src) const;

   /**
    * Reset everything to inital state. 
    * If the object was originally null, this method will make it non-null. 
    */
   void clear();
   /**
    * Is this a null or empty (uninitialized) return type?
    */
   const bool isEmpty() const;
   /**
    * Is this a null return type object?
    */
   const bool isNull() const;

   /**
    * @return Returns the undecorated, fully resolved, class name for 
    *         this return type.
    */
   const SEString getReturnType() const;
   /**
    * Use this to set the fully resolved class name for this return tyupe.
    * 
    * @param classname     undecorated, fully qualified class name 
    */
   void setReturnType(const SEString &className);
   /**
    * Append a class or package name to the fully resolved class name 
    * for this this return type.  This method will automatically append 
    * VS_TAGSEPARATOR_package if necessary. 
    * 
    * @param s             symbol name to append to qualified class name
    */
   void appendReturnType(const SEString &s);
   /**
    * @return Returns the decorated return type, as you might see it in a 
    *         type expression in source code.  The options can be configured
    *         in order to override language-specific notations.  By default,
    *         the return type is formatted as a C/C++ style type expression.
    *  
    * @param options       A multi-line string specifying a table of options 
    *                      list of options, <b>"name value"</b>, separated by
    *                      line endings for language-specific notation options.
    *                      Each value contains a string with a %s indicating
    *                      where the rest of the type expression goes.
    *                      The following options are supported, and are
    *                      expanded in the order listed.
    *        <ul> 
    *        <li><b>template</b>          - (default <b>"%s&lt;%args&gt;"</b>) - template type</li>
    *        <li><b>pointer</b>           - (default <b>"%s *"</b>)            - pointer type</li>
    *        <li><b>reference</b>         - (default <b>"%s &"</b>)            - reference type</li>
    *        <li><b>hashtable</b>         - (default <b>"%s:[]"</b>)           - hash table (associative array), also supports <b>%key</b></li>
    *        <li><b>hashtable2</b>        - (default <b>"%s:[]"</b>)           - alternate hash table, also supports <b>%key</b></li>
    *        <li><b>hashtable_no_key</b>  - (default <b>"%s:[]"</b>)           - hash table (associative array) when no key specified</li>
    *        <li><b>hashtable2_no_key</b> - (default <b>"%s:[]"</b>)           - alternate hash table, when no key type is specified</li>
    *        <li><b>array</b>             - (default <b>"%s[%size]"</b>)       - array type, also supports <b>%lower</b> and <b>%uppper</b></li>
    *        <li><b>array_no_bounds</b>   - (default <b>"%s[]"</b>)            - array type, with no bounds specified</b>
    *        <li><b>function</b>          - (default <b>"%s (*%name)(%args)()  - function type</li>
    *        <li><b>inout</b>             - (default <b>"inout %s"</b>)        - input/output parameter</li>
    *        <li><b>in</b>                - (default <b>"in %s"</b>)           - input-only parameter</li>
    *        <li><b>out</b>               - (default <b>"out %s"</b>)          - output-only parameter</li>
    *        <li><b>volatile</b>          - (default <b>"volatile %s"</b>)     - volatile type expression</li>
    *        <li><b>const</b>             - (default <b>"const %s"</b>)        - const (read-only) type expression</li>
    *        <li><b>static</b>            - (default <b>"static %s"</b>)       - static member reference</li>
    *        <li><b>typedef</b>           - (default <b>"typedef %s"</b>)      - aliased typedef type</li>
    *        <li><b>comma</b>             - (default <b>", "</b>)              - separator between template and function arguments</li>
    *        <li><b>package</b>           - (default <b>"::"</b>)              - tag database class/package separators are replaced with this</li>
    *        <li><b>string</b>            - (default <b>"string"</b>)          - default string tyhpe</li>
    *        </ul>
    */
   const SEString getReturnTypeDecorated(const SEString &options = "") const;

   /** 
    * @return Returns the tag information object for the symbol associated 
    *         with this return type.  This can be an effectively null object.
    */
   const SETagInformation getTagInfo() const;
   /**
    * Saves the tag information object corresponding to the symbol associated 
    * with this return type.  For example, for a class, this would be the 
    * tag information for the class definition. 
    * 
    * @param tagInfo       symbol information
    */
   void setTagInfo(const SETagInformation& tagInfo);

   /**
    * @return Returns the encoded tag information string for the symbol 
    *         associated with this return type.  This string is derived
    *         from the tag information object. 
    */
   const SEString getTagInfoString() const;
   /**
    * Sets the encoded symbol information for the symbol associated with 
    * this return type.  For example, for a class named 'Al' in a namespace 
    * named 'Bundy', the information would be 'Al(bundy:class)'.
    *  
    * Use of this method is discouraged.  It is better to use 
    * {@link setTagInfo()}.  This method will construct a rather incomplete 
    * symbol information object, and {@link getTagInfoString()} will return 
    * an encoded name for the object which may not be identical to the 
    * string passed to this function. 
    * 
    * @param tagInfo       encoded symbol information
    */
   void setTagInfoString(const SEString& tagInfo);

   /**
    * Sets the path and name of the file at the location where
    * this return type is being referenced and evaluated. 
    * Also set the line number and optional seek offset within file.
    * 
    * @param fileName      fully qualified file name
    * @param lineNumber    line number of symbol within source file
    * @param offset        seek position of symbol within source file
    */
   void setLocation(const SEString &fileName, 
                    const unsigned int lineNumber, 
                    const unsigned int offset=0);
   /**
    * @return Returns the path and name of the file at the location where
    *         this return type is being referenced and evaluated.
    */
   const SEString getFilename() const;
   /**
    * Sets the path and name of the file at the location where
    * this return type is being referenced and evaluated.
    * 
    * @param fileName      fully qualified file name
    */
   void setFilename(const SEString &fileName);

   /** 
    * @return Returns the line number in the file at the location where
    *         this return type is being referenced and evaluated.
    */
   const unsigned int getLineNumber() const;
   /**
    * Sets the line number in the file at the location where
    * this return type is being referenced and evaluated.
    * 
    * @param lineNumber    line number of symbol within source file
    */
   void setLineNumber(const unsigned int lineNumber);

   /** 
    * @return Returns the seek position (offset) in the file at the location
    *         where this return type is being referenced and evaluated.
    */
   const unsigned int getSeekPosition() const;
   /**
    * Sets the seek position (offset) in the file at the location where
    * this return type is being referenced and evaluated.
    * 
    * @param offset        seek position of symbol within source file
    */
   void setSeekPosition(const unsigned int offset);

   /**
    * @return Returns the number of pointer references encapsulated by this 
    *         return type.  0 for a non-pointer, 1 for a simple pointer,
    *         2 for a pointer to a pointer, etc.  Using C-style type notation,
    *         array types can also be considered as pointer types.
    *         <p>
    *         Note that this technique is somewhat antiquated.  It is better
    *         to use the {@link isPointerType}, {@link isReferenceType},
    *         {@link isArrayType} or {@link isHashTableType} methods below
    *         in order to interrogate a return type's nature.  It only remains
    *         for backward compatibility.
    */
   const unsigned short getPointerCount() const;
   /**
    * Sets the number of pointer references encapsulated by this return type. 
    * 0 for a non-pointer (the default), 1 for a simple pointer,
    * 2 for a pointer to a pointer, etc.  Using C-style type notation,
    * array types can also be considered as pointer types.
    * <p>
    * Note that this technique is somewhat antiquated.  Is is better to use 
    * the more strutured methods {@link setPointerToType}, 
    * {@link setReferenceToType}, {@link setArrayOfType} or 
    * {@link setHashTableOfType} methods below in order to encapsulate 
    * a return type's nature.  It only remains for backward compatibility. 
    *  
    * @param n             pointer count 
    */
   void setPointerCount(const unsigned short n);

   /**
    * @return Returns 'true' if this is a pointer type.
    */
   const bool isPointerType() const;
   /**
    * @return Returns the type pointed to if this is a pointer type. 
    */
   const SEReturnTypeInfo getPointerType() const;
   /**
    * Sets a return type flag indicating that this is a pointer type and 
    * also stores the return type which is pointed to. 
    *  
    * @param returnType    type which is pointed to
    */
   void setPointerToType(const SEReturnTypeInfo &returnType);
   /**
    * Clear any pointer type information.
    */
   void clearPointerType();

   /**
    * @return Returns 'true' if this is a reference type.
    */
   const bool isReferenceType() const;
   /**
    * @return Returns the type pointed to if this is a reference type. 
    */
   const SEReturnTypeInfo getReferenceType() const;
   /**
    * Sets a return type flag indicating that this is a reference type and 
    * also stores the return type which is referenced. 
    *  
    * @param returnType    type being referenced / aliased. 
    */
   void setReferenceToType(const SEReturnTypeInfo &returnType);
   /**
    * Clear any reference type information.
    */
   void clearReferenceType();

   /**
    * @return Returns 'true' if this is a type alias, for example, a typedef 
    *         in C/C++ or a using statement that behaves like a typedef. 
    */
   const bool isAliasedType() const;
   /**
    * @return Returns the type which is being aliased by this type.
    */
   const SEReturnTypeInfo getAliasedType() const;
   /**
    * Sets a return type flag indicating that this is typedef and 
    * also stores the return type which we are creating a type alias for.
    *  
    * @param returnType    typedef'd type.
    */
   void setAliasedType(const SEReturnTypeInfo &returnType);
   /**
    * Clear any typedef (alias) type information.
    */
   void clearAliasedType();

   /**
    * @return Returns 'true' if this is an array type.
    */
   const bool isArrayType() const;
   /**
    * @return Returns the type of the array elements if this is an array type. 
    */
   const SEReturnTypeInfo getArrayItemType() const;
   /**
    * @return Returns the lower bound of the array type. 
    *         Returns 0 by default, or if the current type is not an array type.
    */
   const VSINT64 getArrayTypeLowerBound() const;
   /**
    * @return Returns the upper bound of the array type. 
    *         Returns VSMAXUNSIGNED by default, or if the current type is not 
    *         an array type.
    */
   const VSINT64 getArrayTypeUpperBound() const;
   /**
    * @return Return the number of elements that can be in this array 
    */
   const VSUINT64 getArrayTypeSize() const;
   /**
    * Sets a return type flag indicating that this is an array type and 
    * also stores the return type which we are creating an array of, as 
    * well as the lower and upper bounds. 
    *  
    * @param returnType    array item return type 
    * @param lowerBound    lower bound of array indexes 
    * @param upperBound    upper bound of array indexes 
    */
   void setArrayOfType(const SEReturnTypeInfo &returnType, 
                       const VSINT64 lowerBound=0, 
                       const VSINT64 upperBound=VSMAXUNSIGNED);
   /**
    * Clear any array type information.
    */
   void clearArrayType();

   /**
    * @return Returns 'true' if this is a hash table type.
    */
   const bool isHashTableType() const;
   /**
    * @return Returns the key type for a hash table. 
    *         This can return a null return type object if the key
    *         type was not defined, or if the current type is not a hash table.
    */
   const SEReturnTypeInfo getHashTableKeyType() const;
   /**
    * @return Return the value type for a hash table. 
    */
   const SEReturnTypeInfo getHashTableValueType() const;
   /**
    * Sets a return type flag indicating that this is a hash table type and 
    * also stores the key and value return types which we are creating a 
    * hash table of.  If not specified, the key is assumed to be a string type. 
    *  
    * @param valueType     hash table value return type 
    * @param pKeyType      (optional, assumed to be string) key type
    */
   void setHashTableOfType(const SEReturnTypeInfo &valueType,
                           const SEReturnTypeInfo *pKeyType = nullptr); 
   /**
    * Clear any hash table type information.
    */
   void clearHashTableType();

   /**
    * @return Return the bitset of return type flags for this return type. 
    * @see SETagReturnTypeFlags
    */
   const SETagReturnTypeFlags getReturnTypeFlags() const;
   /**
    * @return Returns 'true' if the given return flag is a special type, such 
    *         as a pointer, reference, array, hash table, template or function.
    */
   const bool isReturnTypeSpecial() const;
   /**
    * @return Returns 'true' if the given return type is a builtin type for the 
    *         current language mode.
    */
   const bool isReturnTypeBuiltin() const;
   /**
    * @return Returns 'true' if the given return type is a placeholder. 
    */
   const bool isReturnTypeFake() const;
   /**
    * @return Returns 'true' if the given return flag is set.
    * @param flag          return type flag to test 
    */
   const bool isReturnTypeFlagSet(const SETagReturnTypeFlags flag) const;
   /**
    * @return Returns 'true' if the all of the given return flags are set. 
    * @param flags         return type flags to test 
    */
   const bool areAllReturnTypeFlagsSet(const SETagReturnTypeFlags flags) const;
   /**
    * @return Returns 'true' if the any of the given return flags are set. 
    * @param flags         return type flags to test 
    */
   const bool areAnyReturnTypeFlagsSet(const SETagReturnTypeFlags flags) const;
   /**
    * Set the bitset of return type flags for this return type.
    * 
    * @param flags         return type flags    
    * @see SETagReturnTypeFlags
    */
   void setReturnTypeFlags(const SETagReturnTypeFlags flags);
   /**
    * Set additional return type flags.
    * 
    * @param flags         return type flags
    */
   void addReturnTypeFlags(const SETagReturnTypeFlags flags);
   /**
    * Unset return type flags if they are already set.
    * 
    * @param flags         return type flags
    */
   void removeReturnTypeFlags(const SETagReturnTypeFlags flags);

   /**
    * @return Returns 'true' if this is a template type or a template type instance.
    */
   const bool isTemplateType() const;
   /**
    * Return the number of template arguments for this return type. 
    */
   const unsigned int getNumTemplateArgs() const;
   /**
    * Sets a return type flag indicating that this is a template type.
    * 
    * @param yesno         'true' or 'false' indicating if this is a template. 
    * @param numArgs       number of template arguments
    */
   void setTemplateType(const bool yesno, const unsigned int numArgs=0);
   /**
    * Sets a return type flag indicating that this is a template type, 
    * and fills in the template argument names and template argument types.
    *  
    * @param templateArgNames    ordered list of template argument names 
    * @param templateArgExprs    ordered list of template argument values
    *                            (corresponding to template argument names)
    * @param templateArgTypes    ordered list of template argument types 
    *                            (corresponding to template argument names)
    */
   void setTemplateType(const SEArray<SEString>         &templateArgNames,
                        const SEArray<SEString>         &templateArgExprs,
                        const SEArray<SEReturnTypeInfo> &templateArgTypes);

   /**
    * @return Return the i'th template argument name. 
    *  
    * @param i          index 0 .. {@link getNumTemplateArgs()} 
    */
   const SEString getTemplateArgName(const size_t i) const;
   /**
    * @return Return the template argument expression corresponding to 
    *         i'th template argument name.
    *  
    * @param i          index 0 .. {@link getNumTemplateArgs()} 
    */
   const SEString getTemplateArgValue(const size_t i) const;
   /**
    * @return Return the template argument expression corresponding to 
    *         given template argument name.
    *  
    * @param argName    template argument name.
    */
   const SEString getTemplateArgValue(const SEString &argName) const;
   /**
    * @return Return the template argument type corresponding to 
    *         i'th template argument name.
    *  
    * @param i          index 0 .. {@link getNumTemplateArgs()} 
    */
   const SEReturnTypeInfo getTemplateArgType(const size_t i) const;
   /**
    * @return Return the template argument type corresponding to 
    *         given template argument name.
    *  
    * @param argName    template argument name.
    */
   const SEReturnTypeInfo getTemplateArgType(const SEString &argName) const;
   /**
    * Set the i'th template argument name and type. 
    *  
    * @param i          template argument name index 
    * @param argName    template argument name 
    * @param argValue   template argument value (expression) 
    * @param argType    evaluated template argument type
    */
   void setTemplateArg(const size_t i, 
                       const SEString &argName, 
                       const SEString &argValue, 
                       const SEReturnTypeInfo &argType);
   /**
    * Set the i'th template argument name. 
    *  
    * @param i          template argument name index 
    * @param argName    template argument name 
    */
   void setTemplateArgName(const size_t i, const SEString &argName);
   /**
    * Set the template argument value (expression) for the given 
    * template argument name. 
    *  
    * @param argName    template argument name 
    * @param argValue   template argument value (expression) 
    */
   void setTemplateArgValue(const SEString &argName, const SEString &argValue);
   /**
    * Set the template argument type for the given template argument name.
    *  
    * @param argName    template argument name 
    * @param argType    evaluated template argument type
    */
   void setTemplateArgType(const SEString &argName, const SEReturnTypeInfo &argType);
   /**
    * Clear the list of template argument names and types for this return type.
    */
   void clearTemplateArgs();

   /**
    * @return Returns 'true' if this is a function call or function pointer.
    */
   const bool isFunctionType() const;
   /**
    * Return the number of function arguments for this return type. 
    */
   const unsigned int getNumFunctionArgs() const;
   /**
    * Sets a return type flag indicating that this is a function type.
    * 
    * @param yesno         'true' or 'false' indicating if this is a function. 
    * @param returnType    function return type 
    * @param numArgs       number of function arguments
    */
   void setFunctionType(const bool yesno, 
                        const SEReturnTypeInfo &returnType, 
                        const unsigned int numArgs=0);
   /**
    * Sets a return type flag indicating that this is a function type, 
    * and fills in the function argument names and function argument types.
    *  
    * @param returnType          function return type 
    * @param functionArgNames    ordered list of function argument names 
    * @param functionArgExprs    ordered list of function argument values
    *                            (corresponding to function argument names)
    * @param functionArgTypes    ordered list of function argument types 
    *                            (corresponding to function argument names)
    */
   void setFunctionType(const SEReturnTypeInfo &returnType, 
                        const SEArray<SEString>         &functionArgNames,
                        const SEArray<SEString>         &functionArgExprs,
                        const SEArray<SEReturnTypeInfo> &functionArgTypes);

   /**
    * @return Returns the function return type if this is a function type. 
    */
   const SEReturnTypeInfo getFunctionReturnType() const;
   /**
    * @return Return the i'th function argument name. 
    *  
    * @param i          index 0 .. {@link getNumFunctionArgs()} 
    */
   const SEString getFunctionArgName(const size_t i) const;
   /**
    * @return Return the function argument expression corresponding to 
    *         i'th function argument name.
    *  
    * @param i          index 0 .. {@link getNumFunctionArgs()} 
    */
   const SEString getFunctionArgValue(const size_t i) const;
   /**
    * @return Return the function argument expression corresponding to 
    *         given function argument name.
    *  
    * @param argName    function argument name.
    */
   const SEString getFunctionArgValue(const SEString &argName) const;
   /**
    * @return Return the function argument type corresponding to 
    *         i'th function argument name.
    *  
    * @param i          index 0 .. {@link getNumFunctionArgs()} 
    */
   const SEReturnTypeInfo getFunctionArgType(const size_t i) const;
   /**
    * @return Return the function argument type corresponding to 
    *         given function argument name.
    *  
    * @param argName    function argument name.
    */
   const SEReturnTypeInfo getFunctionArgType(const SEString &argName) const;
   /**
    * Set the i'th function argument name and type. 
    *  
    * @param i          function argument name index 
    * @param argName    function argument name 
    * @param argValue   function argument value (expression) 
    * @param argType    evaluated function argument type
    */
   void setFunctionArg(const size_t i, 
                       const SEString &argName, 
                       const SEString &argValue, 
                       const SEReturnTypeInfo &argType);
   /**
    * Set the i'th function argument name. 
    *  
    * @param i          function argument name index 
    * @param argName    function argument name 
    */
   void setFunctionArgName(const size_t i, const SEString &argName);
   /**
    * Set the function argument value (expression) for the given 
    * function argument name. 
    *  
    * @param argName    function argument name 
    * @param argValue   function argument value (expression) 
    */
   void setFunctionArgValue(const SEString &argName, const SEString &argValue);
   /**
    * Set the function argument type for the given function argument name.
    *  
    * @param argName    function argument name 
    * @param argType    evaluated function argument type
    */
   void setFunctionArgType(const SEString &argName, const SEReturnTypeInfo &argType);
   /**
    * Clear the list of function argument names and types for this return type.
    */
   void clearFunctionArgs();

   /**
    * @return Return the number of alternate return types for this symbol.
    */
   const unsigned int getNumAltReturnTypes() const;
   /**
    * @return Return the i'th alternate return type object for this return type. 
    *         Sometimes the return type of a symbol can evaluate in multiple
    *         ways due to ambiguities, leading to alternate interpretions of
    *         a symbol's return type.
    *  
    * @param i          index 0 ... {@link getNumAltReturnTypes()} 
    */
   const SEReturnTypeInfo getAltReturnType(const size_t i) const;
   /**
    * Sometimes the return type of a symbol can evaluate in multiple ways 
    * due to ambiguities, leading to alternate interpretions of a symbol's 
    * return type.  Use this method to add an additional alternate return 
    * type to the list of alternates. 
    */
   void addAltReturnType(const SEReturnTypeInfo &returnType);
   /**
    * Clear the list of alternate return types for this symbol.
    */
   void clearAltReturnTypes();


   /**
    * Copy the contents of this struct out to the given Slick-C 
    * struct VS_TAG_RETURN_TYPE.
    * 
    * @param rt_info       Slick-C struct to copy out contents to 
    */
   void copyOut(VSHREFVAR rt_info) const;

   /**
    * Copy the contents of this struct out from the given Slick-C 
    * struct VS_TAG_RETURN_TYPE.
    * 
    * @param rt_info       Slick-C struct to copy out contents to 
    */
   void copyIn(VSHREFVAR rt_info);


private:

   SESharedPointer<struct SEPrivateReturnTypeInfo> mpReturnTypeInfo;
   friend struct SEPrivateReturnTypeInfo;
};

};


