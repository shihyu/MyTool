////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagTypes.h
// Description:   Declaration of enumerated type representing different
//                symbol types used in SlickEdit tagging model, as well
//                as some utility functions for them.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SETagFlags.h"
#include "tags/SETagFilterFlags.h"
#include "slickedit/SEString.h"
#include "slickedit/SEArray.h"


/**
 * Standard tag types, by default, always present in database
 * standard type name is always "xxx" for SE_TAG_TYPE_XXX,
 * for example, the type name for SE_TAG_TYPE_PROC is "proc".
 * ID's 83-127 are reserved for future use by SlickEdit.
 */
enum SETagType : unsigned short {

   /**
    * procedure or command
    */
   SE_TAG_TYPE_PROC        =  1,
   /**
    * function prototype
    */
   SE_TAG_TYPE_PROTO       =  2,
   /**
    * preprocessor macro definition
    */
   SE_TAG_TYPE_DEFINE      =  3,
   /**
    * type definition
    */
   SE_TAG_TYPE_TYPEDEF     =  4,
   /**
    * global variable declaration
    */
   SE_TAG_TYPE_GVAR        =  5,
   /**
    * structure definition
    */
   SE_TAG_TYPE_STRUCT      =  6,
   /**
    * enumeration value
    */
   SE_TAG_TYPE_ENUMC       =  7,
   /**
    * enumerated type
    */
   SE_TAG_TYPE_ENUM        =  8,
   /**
    * class definition
    */
   SE_TAG_TYPE_CLASS       =  9,
   /**
    * structure / union definition
    */
   SE_TAG_TYPE_UNION       = 10,
   /**
    * label
    */
   SE_TAG_TYPE_LABEL       = 11,
   /**
    * interface, eg, for Java
    */
   SE_TAG_TYPE_INTERFACE   = 12,
   /**
    * class constructor
    */
   SE_TAG_TYPE_CONSTRUCTOR = 13,
   /**
    * class destructor
    */
   SE_TAG_TYPE_DESTRUCTOR  = 14,
   /**
    * package / module / namespace
    */
   SE_TAG_TYPE_PACKAGE     = 15,
   /**
    * member of a class / struct / package
    */
   SE_TAG_TYPE_VAR         = 16,
   /**
    * local variable declaration
    */
   SE_TAG_TYPE_LVAR        = 17,
   /**
    * pascal constant
    */
   SE_TAG_TYPE_CONSTANT    = 18,
   /**
    * function
    */
   SE_TAG_TYPE_FUNCTION    = 19,
   /**
    * property?
    */
   SE_TAG_TYPE_PROPERTY    = 20,
   /**
    * pascal program
    */
   SE_TAG_TYPE_PROGRAM     = 21,
   /**
    * pascal library
    */
   SE_TAG_TYPE_LIBRARY     = 22,
   /**
    * function or procedure parameter
    */
   SE_TAG_TYPE_PARAMETER   = 23,
   /**
    * package import or using
    */
   SE_TAG_TYPE_IMPORT      = 24,
   /**
    * C++ friend relationship
    */
   SE_TAG_TYPE_FRIEND      = 25,
   /**
    * SQL/OO Database
    */
   SE_TAG_TYPE_DATABASE    = 26,
   /**
    * Database Table
    */
   SE_TAG_TYPE_TABLE       = 27,
   /**
    * Database Column
    */
   SE_TAG_TYPE_COLUMN      = 28,
   /**
    * Database index
    */
   SE_TAG_TYPE_INDEX       = 29,
   /**
    * Database view
    */
   SE_TAG_TYPE_VIEW        = 30,
   /**
    * Database trigger
    */
   SE_TAG_TYPE_TRIGGER     = 31,
   /**
    * GUI Form or window
    */
   SE_TAG_TYPE_FORM        = 32,
   /**
    * GUI Menu
    */
   SE_TAG_TYPE_MENU        = 33,
   /**
    * GUI Control or Widget
    */
   SE_TAG_TYPE_CONTROL     = 34,
   /**
    * GUI Event table
    */
   SE_TAG_TYPE_EVENTTAB    = 35,
   /**
    * Prototype for procedure
    */
   SE_TAG_TYPE_PROCPROTO   = 36,
   /**
    * Ada task object
    */
   SE_TAG_TYPE_TASK        = 37,
   /**
    * C++ include, Ada with
    */
   SE_TAG_TYPE_INCLUDE     = 38,
   /**
    * COBOL file descriptor
    */
   SE_TAG_TYPE_FILE        = 39,
   /**
    * Container variable
    */
   SE_TAG_TYPE_GROUP       = 40,
   /**
    * Nested function
    */
   SE_TAG_TYPE_SUBFUNC     = 41,
   /**
    * Nested procedure or cobol paragraph
    */
   SE_TAG_TYPE_SUBPROC     = 42,
   /**
    * Database result set cursor
    */
   SE_TAG_TYPE_CURSOR      = 43,
   /**
    * SGML or XML tag type (like a class)
    */
   SE_TAG_TYPE_TAG         = 44,
   /**
    * SGML or XML tag instance (like an object)
    */
   SE_TAG_TYPE_TAGUSE      = 45,
   /**
    * generic statement
    */
   SE_TAG_TYPE_STATEMENT   = 46,
   /**
    * Java annotation type or C# attribute class
    */
   SE_TAG_TYPE_ANNOTYPE    = 47,
   /**
    * Java annotation or C# attribute instance
    */
   SE_TAG_TYPE_ANNOTATION  = 48,
   /**
    * Function/Method call
    */
   SE_TAG_TYPE_CALL        = 49,
   /**
    * If or switch-case statement
    */
   SE_TAG_TYPE_IF          = 50,
   /**
    * Loop statement
    */
   SE_TAG_TYPE_LOOP        = 51,
   /**
    * Break statement
    */
   SE_TAG_TYPE_BREAK       = 52,
   /**
    * Continue statement
    */
   SE_TAG_TYPE_CONTINUE    = 53,
   /**
    * Return statement
    */
   SE_TAG_TYPE_RETURN      = 54,
   /**
    * Goto statement
    */
   SE_TAG_TYPE_GOTO        = 55,
   /**
    * Try/Catch/Finally statement
    */
   SE_TAG_TYPE_TRY         = 56,
   /**
    * Preprocessing statement
    */
   SE_TAG_TYPE_PP          = 57,
   /**
    * Statement block
    */
   SE_TAG_TYPE_BLOCK       = 58,
   /**
    * D language mixin construct
    */
   SE_TAG_TYPE_MIXIN       = 59,
   /**
    * Ant target
    */
   SE_TAG_TYPE_TARGET      = 60,
   /**
    * Assignment statement
    */
   SE_TAG_TYPE_ASSIGN      = 61,
   /**
    * Objective-C method
    */
   SE_TAG_TYPE_SELECTOR    = 62,
   /**
    * Preprocessor macro #undef
    */
   SE_TAG_TYPE_UNDEF       = 63,
   /**
    * Statement sub-clause
    */
   SE_TAG_TYPE_CLAUSE      = 64,
   /**
    * Database cluster
    */
   SE_TAG_TYPE_CLUSTER     = 65,
   /**
    * Database partition
    */
   SE_TAG_TYPE_PARTITION   = 66,
   /**
    * Database audit policy
    */
   SE_TAG_TYPE_POLICY      = 67,
   /**
    * Database user profile
    */
   SE_TAG_TYPE_PROFILE     = 68,
   /**
    * Database user name
    */
   SE_TAG_TYPE_USER        = 69,
   /**
    * Database role
    */
   SE_TAG_TYPE_ROLE        = 70,
   /**
    * Database sequence
    */
   SE_TAG_TYPE_SEQUENCE    = 71,
   /**
    * Database table space
    */
   SE_TAG_TYPE_TABLESPACE  = 72,
   /**
    * SQL select statement
    */
   SE_TAG_TYPE_QUERY       = 73,
   /**
    * Attribute
    */
   SE_TAG_TYPE_ATTRIBUTE   = 74,
   /**
    * Database link
    */
   SE_TAG_TYPE_DBLINK      = 75,
   /**
    * Database dimension
    */
   SE_TAG_TYPE_DIMENSION   = 76,
   /**
    * Directory
    */
   SE_TAG_TYPE_DIRECTORY   = 77,
   /**
    * Database edition
    */
   SE_TAG_TYPE_EDITION     = 78,
   /**
    * Database constraint
    */
   SE_TAG_TYPE_CONSTRAINT  = 79,
   /**
    * Event monitor
    */
   SE_TAG_TYPE_MONITOR     = 80,
   /**
    * Statement scope block (for local tagging)
    */
   SE_TAG_TYPE_SCOPE       = 81,
   /**
    * Function closure
    */
   SE_TAG_TYPE_CLOSURE     = 82,
   /**
    * class constructor prototype
    */
   SE_TAG_TYPE_CONSTRUCTORPROTO = 83,
   /**
    * class destructor prototype
    */
   SE_TAG_TYPE_DESTRUCTORPROTO  = 84,
   /**
    * overloaded operator
    */
   SE_TAG_TYPE_OPERATOR    = 85,
   /**
    * overloaded operator prototype
    */
   SE_TAG_TYPE_OPERATORPROTO = 86,
   /**
    * miscellaneous tag type
    */
   SE_TAG_TYPE_MISCELLANEOUS = 87,
   /**
    * miscellaneous container tag type
    */
   SE_TAG_TYPE_CONTAINER   = 88,
   /**
    * unknown tag type
    */
   SE_TAG_TYPE_UNKNOWN     = 89,
   /**
    * Objective-C static method
    */
   SE_TAG_TYPE_STATIC_SELECTOR = 90,
   /**
    * Switch/case statement
    */
   SE_TAG_TYPE_SWITCH      = 91,
   /**
    * Source file region (#region ... #endregion)
    */
   SE_TAG_TYPE_REGION     = 92,
   /**
    * Source file generic note (#note)
    */
   SE_TAG_TYPE_NOTE     = 93,
   /**
    * Source file to-do note (#todo)
    */
   SE_TAG_TYPE_TODO     = 94,
   /**
    * Source file warning (#warning)
    */
   SE_TAG_TYPE_WARNING     = 95,
   /**
    * Logic programming rule, Makefile rule, Grammar rule, etc.
    */
   SE_TAG_TYPE_RULE = 96,
   /**
    * Precondition
    */
   SE_TAG_TYPE_PRECONDITION = 97,
   /**
    * Postcondition
    */
   SE_TAG_TYPE_POSTCONDITION = 98,
   /**
    * Guard
    */
   SE_TAG_TYPE_GUARD = 99,
   /**
    * Exported symbol
    */
   SE_TAG_TYPE_EXPORT = 100,
   /**
    * Concept
    */
   SE_TAG_TYPE_CONCEPT = 101,
   /**
    * Module
    */
   SE_TAG_TYPE_MODULE = 102,
   /**
    * Namespace
    */
   SE_TAG_TYPE_NAMESPACE = 103,

   /**
    * last tag type ID (plus 1)
    */
   SE_TAG_TYPE_LASTID_PLUS_1,
   /**
    * last tag type ID
    */
   SE_TAG_TYPE_LASTID      = (SE_TAG_TYPE_LASTID_PLUS_1-1),

   /**
    * null (uninitialized) tag type ID
    */
   SE_TAG_TYPE_NULL        = 0,
   /**
    * first tag type ID
    */
   SE_TAG_TYPE_FIRSTID     = 1,

   /**
    * first user-defined tag type ID
    */
   SE_TAG_TYPE_FIRSTRESERVED  = SE_TAG_TYPE_LASTID_PLUS_1,
   /**
    * last user-defined tag type ID (this is the last ID that can be created automatically by vsTagGetTypeID)
    */
   SE_TAG_TYPE_LASTRESERVED   = 127,

   /**
    * first user-defined tag type ID
    */
   SE_TAG_TYPE_FIRSTUSER   = 128,
   /**
    * last user-defined tag type ID (this is the last ID that can be created automatically by vsTagGetTypeID)
    */
   SE_TAG_TYPE_LASTUSER    = 159,

   /**
    * first OEM-defined tag type ID
    */
   SE_TAG_TYPE_FIRSTOEM    = 160,
   /**
    * last OEM-defined tag type ID
    */
   SE_TAG_TYPE_LASTOEM    = 255,

   /**
    * maximum tag type ID (including mapped ids)
    */
   SE_TAG_TYPE_MAXIMUM    = 511,

};


/** 
 * @return 
 * Return the tag type mapped to the given type name. 
 * This function handles both standard tag type names and registered OEM tag types. 
 * 
 * @param tagTypeName      tag type name
 */
VSDLLEXPORT const SETagType SETagTypeGetTypeID(const slickedit::SEString &tagTypeName);

/** 
 * @return 
 * Determine whether the given tag type is a registered OEM tag type ID. 
 * Returns 'true' if so, 'false' otherwise. 
 * 
 * @param tagType    OEM tag type ID
 */
VSDLLEXPORT const bool SETagTypeIsRegistered(const SETagType tagType);
/** 
 * @return 
 * Determine whether the given tag type is a registered OEM tag type name. 
 * Returns 'true' if so, 'false' otherwise. 
 * 
 * @param tagTypeName  tag type name to check
 */
VSDLLEXPORT const bool SETagTypeIsRegistered(const slickedit::SEString &tagTypeName);

/**
 * Register an OEM tag type ID and name
 * 
 * @param requestedTagTypeId  OEM tag type ID, if this is SE_TAG_TYPE_NULL or 
 *                            SE_TAG_TYPE_FIRSTUSER, the next available user tag
 *                            type will be allocated.  If this is SE_TAG_TYPE_FIRSTOEM,
 *                            the next available OEM tag type will be allocated.
 *                            If this tag type ID is already allocated, return
 *                            SE_TAG_TYPE_NULL to indicate the error. 
 * @param tagTypeName         OEM tag type name, if this type name is already 
 *                            registered, or conflicts with a standard type name
 *                            return SE_TAG_TYPE_NULL to indicate the error. 
 * @param isContainer         can a symbol with this tag type have nested symbols
 * @param tagTypeDescription  description of this tag type 
 * @param bitmapName          base name for bitmap associated with this tag type 
 * @param filterFlags         filter flags for this symbol (SE_TAG_FILTER_*)
 * 
 * @return Return the newly registered tag type ID if there is one available. 
 *         Returns SE_TAG_TYPE_NULL if there are no more tag type slots available.
 */
VSDLLEXPORT const SETagType SETagTypeRegisterType(const SETagType requestedTagTypeId, 
                                                  const slickedit::SEString &tagTypeName,
                                                  const bool isContainer = false,
                                                  const slickedit::SEString tagTypeDescription=(const char*)0,
                                                  const slickedit::SEString bitmapName=(const char*)0,
                                                  const SETagFilterFlags filterFlags = SE_TAG_FILTER_ANYTHING);

/**
 * Unregister the given OEM tag type ID.
 * 
 * @param tagTypeId   OEM tag type ID
 * 
 * @return 0 on success, INVALID_ARGUMENT_RC if the tag type is invalid.
 */
VSDLLEXPORT int SETagTypeUnregister(const SETagType tagTypeId);

/** 
 * @return
 * Return the tag type name corresponding to the given tag type ID. 
 * Returns a null string if the tag type is invalid. 
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT const slickedit::SEString SETagTypeGetName(const SETagType tagType);

/** 
 * @return
 * Return the tag type name corresponding to the given tag type ID. 
 * Returns a null string if the tag type is invalid. 
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT const char * const SETagTypeGetNamePointer(const SETagType tagType);

/** 
 * @return
 * Return the string representing the symbol name for the given tag type. 
 * This generally only works with built-in tag types.
 * Returns a null string if the tag type is invalid. 
 * 
 * @param tagType    tag type ID
 */
const slickedit::SEString VSDLLEXPORT SETagTypeGetSymbolName(const SETagType tagType);

/** 
 * @return 
 * Return the tag type description corresponding to the given tag type ID. 
 * Returns a null string if the tag type is invalid.  
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT const slickedit::SEString SETagTypeGetDescription(const SETagType tagType);

/**
 * Set the tag description for a given tag type.
 * 
 * @param tagType    tag type ID
 * @param desc       tag type description.
 * 
 * @return 0 on success, &lt;0 for an invalid tag type
 */
VSDLLEXPORT int SETagTypeSetDescription(const SETagType tagType, const slickedit::SEString &desc);

/** 
 * @return 
 * Return the filter flags for given type ID.
 *
 * @param tagType    tag type ID, in range 0 ..SE_TAG_TYPE_MAXIMUM
 */
VSDLLEXPORT const SETagFilterFlags SETagTypeGetFilter(const SETagType tagType);

/**
 * Set the filter flags for given type ID.
 *
 * @param tagType       tag type ID, in range SE_TAG_TYPE_FIRSTOEM .. SE_TAG_TYPE_MAXIMUM
 * @param filterFlags   New filter flags. See SE_TAG_FILTER_*
 */
VSDLLEXPORT int SETagTypeSetFilter(const SETagType tagType, const SETagFilterFlags filterFlags);


/** 
 * Initialize the filter-by-tag-type array into local storage. 
 * The filter-by-types array is used to screen individual tags 
 * strictly by tag type (true=allowed; false=disallowed). 
 * It can be customized for OEM tag types.
 */
VSDLLEXPORT void SETagTypeLoadFilterByTypesArray();

/** 
 * @return 
 * This function is used to get the filter-by-types array. 
 * The filter-by-types array is used to screen individual tags 
 * strictly by tag type (true=allowed; false=disallowed). 
 * It can be customized for OEM tag types.
 */
VSDLLEXPORT const slickedit::SEArray<bool> SETagTypeGetFilterByTypesArray();

/**
 * Filter the given tag type based on the given filter flags
 * 
 * @param tagType          tag type ID, SE_TAG_TYPE_*
 * @param tagFlags         tag flags, SE_TAG_FLAG_*
 * @param filterFlags      SE_TAG_FILTER_*
 * @param filter_by_types  (optional) array of filter-by-type settings 
 *                         for each tag type ID (1=allowed; 0=disallowed) 
 * 
 * @return 
 * Returns 'true' if the type is allowed according to the flags, 'false' if not.
 */
VSDLLEXPORT bool SETagTypeFilterByType(const SETagType  tagType, 
                                       const SETagFlags tagFlags,
                                       const SETagFilterFlags filterFlags,
                                       const bool *pFilterByTypes = nullptr);


/**
 * @return 
 * Return if the given tag type is considered as a container, that is, other 
 * symbols can be nested within it.  To support statement tagging, most tags are 
 * considered as containers. 
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT const bool SETagTypeIsContainer(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a function, procedure, constructor, 
 * destructor, or a function prototype..
 * Return 'false' otherwise.
 * 
 * @param tagType          tag type ID 
 * @param allowPrototypes  include function prototypes (declarations)
 */
VSDLLEXPORT bool SETagTypeIsFunction(const SETagType tagType, const bool allowPrototypes=true);

/**
 * @return 
 * Return 'true' if the given type is a prototype for a function, 
 * procedure, constructor, destructor, or overloaded operator.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsPrototype(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a variable, global variable, member variable, 
 * function parameter, property, or other symbol type that is treated like data.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsData(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a database table, index, column, trigger, 
 * or other symbol specific to database query language programming. 
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsDatabase(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a constant, enumerator, or #define symbol.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsConstant(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is any statement type (loop, if, block, etc.)
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsStatement(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a class, struct, union, or interface.
 * Return 'false' otherwise.
 * 
 * @param tagType   tag type name
 */
VSDLLEXPORT bool SETagTypeIsClass(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a variable, global variable, member variable, 
 * function parameter, property, or other symbol type that is treated like data.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsVariable(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a package, namespace, program, library, 
 * or other high-level package organization symbol type.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsPackage(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is an annotation, #region, #note, #todo, or #warning.
 * or other symbol type that is merely there for informational purposes.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsAnnotation(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given type is a preprecessing control statement.
 * Return 'false' otherwise.
 * 
 * @param tagType    tag type ID
 */
VSDLLEXPORT bool SETagTypeIsPreprocessing(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given symbol is opaque, meaning that symbols defined 
 * within it's scope are visible outside of it's scope without qualification 
 * (for example, a COBOL group, or a C++ enumerated type). 
 * Return 'false' otherwise. 
 * 
 * @param tagType    tag type ID
 * @param tagFlags   tag flags
 */
VSDLLEXPORT bool SETagTypeIsOpaque(const SETagType type_id, const SETagFlags tagFlags);

/**
 * @return 
 * Return 'true' if the given type is preprocessig, a #include, an annotation, 
 * or some other symbol type which should not participate in symbol name 
 * pattern matching.
 */
VSDLLEXPORT bool SETagTypeIsNotPatternMatchingCandidate(const SETagType tagType);

/**
 * @return 
 * Return 'true' if the given symbol type has arguments, or should be expected 
 * to have arguments, based on it's tag type and tag flags (and it's actual argument list). 
 * Return 'false' otherwise. 
 * 
 * @param tagType    tag type ID
 * @param argList    argument list for symbol in question
 */
VSDLLEXPORT bool SETagTypeHasArguments(const SETagType tagType, const slickedit::SEString &argList);

/** 
 * @return 
 * Return 'true' if a symbol with the given tag type, flags, 
 * and signature is likely to require local variable parsing. 
 * <p> 
 * This function looks for the following: 
 * <ul> 
 *     <li>functions, procedures, methods, and prototypes</li>
 *     <li>any database tag type (table, query, index)</li>
 *     <li>#define macro definitions with arguments</li>
 *     <li>Ada, VHDL, or verilog tasks</li>
 *     <li>stand-alone code blocks</li>
 *     <li>closures, delegates, and anonymous functions</li>
 *     <li>friend functions or classes with arguments or template arguments</li>
 *     <li>typedefs for function pointers with arguments or template arguments</li>
 *     <li>variables for function pointers with arguments</li>
 *     <li>primary class constructors</li>
 *     <li>template classes, variables, and generic packages</li>
 * </ul>
 * 
 * @param tag_type        the tag type, (see SE_TAG_TYPE_*)
 * @param tag_flags       tag flags (see SE_TAG_FLAG_*)
 * @param signature       function signature
 */
VSDLLEXPORT bool SETagCanHaveLocalVariables(const SETagType tag_type,
                                            const SETagFlags tag_flags,
                                            const slickedit::SEString &signature);

/**
 * @return 
 * Return 'true' if a symbol with the given tag type and flags can be 
 * a definition or declaration. 
 * <p> 
 * This function filters out the following: 
 * <ul> 
 *     <li>friend declarations</li>
 *     <li>import statements</li>
 *     <li>tag uses (in XML, for example)</li>
 *     <li>annotations</li>
 *     <li>inline mixins</li>
 *     <li>extern declarations</li>
 *     <li>anonymous symbols</li>
 *     <li>symbols marked as ignored</li>
 *     <li>symbols designated for the outline view only</li>
 *     <li>forward class or structure declarations</li>
 * </ul> 
 */
VSDLLEXPORT bool SETagCanBeDefinitionOrDeclaration(const SETagType tag_type,
                                                   const SETagFlags tag_flags);

/** 
 * Initialize the picture index for all the tag types and tag flag modifiers. 
 * This only initializes standard tag types, however OEM tag types can be 
 * customized separately.
 */
VSDLLEXPORT void SETagTypeLoadPictureIndexesArray();

/**
 * Return the specific picture index for a tag type with a specific modifier option.
 * 
 * @param tagType       tag type ID
 * @param tagFlags      tag flags
 * @param pOverlay      (optional) pointer to index of overlay bitmap to use 
 * 
 * @return picture index &gt; 0 on success, &lt; 0 on error.
 */
VSDLLEXPORT int SETagTypeGetPictureIndex(const SETagType tagType, 
                                         const SETagFlags tagFlags=SE_TAG_FLAG_NULL, 
                                         int *pOverlay=nullptr);

/**
 * Register a specific picture index for a tag type with a specific modifier option.
 * 
 * @param tagType       tag type ID
 * @param modifierIndex picture modifier option (private, public, static, protected, template)
 * @param pictureIndex  bitmap index (from vsFindIndex())
 * 
 * @return 0 on success, &lt; 0 on error (for example, an invalid tag type ID)
 */
VSDLLEXPORT int SETagTypeSetPictureIndex(const SETagType tagType, const int pictureIndex);

/** 
 * Return the specific picture index for the overlay for specific modifer options.
 * 
 * @param tagFlags      tag flags
 * 
 * @return picture index &gt; 0 on success, &lt; 0 on error.
 */
VSDLLEXPORT int SETagTypeGetModifierPictureIndex(const SETagFlags tagFlags);

/**
 * Register a specific picture index for the overlay for specific modifier settings. 
 * 
 * @param tagFlags      tag flags
 * @param pictureIndex  bitmap index (from vsFindIndex())
 * 
 * @return 0 on success, &lt; 0 on error (for example, an invalid tag type ID)
 */
VSDLLEXPORT int SETagTypeSetModifierPictureIndex(const SETagFlags tagFlags, const int pictureIndex);

/**
 * Member filtration using tag flags for Symbols tool window.
 * 
 * This function collects flags that apply to the given tag, defined by
 * its type, in_class, and flags, and the checks the applicable flags with the
 * display mask.
 *
 * This is a very critical function to class browser performance, and
 * therefore is as highly optimized as possible.
 * 
 * @param filterFlags1  current active tag type filtration flags
 * @param filterFlags2  current active tag scope filtration flags
 * @param tagType       tag type ID
 * @param tagFlags      tag flags
 * @param inClass       is this symbol in a class or namespace or other container?
 * 
 * @return 
 * The function returns 'false' if the tag does not meet filtration criteria,
 * and 'true' if the tag does meet criteria.
 */
VSDLLEXPORT bool SETagTypeFilterSymbol(const int filterFlags1,
                                       const int filterFlags2,
                                       const SETagType  tagType,
                                       const SETagFlags tagFlags = SE_TAG_FLAG_NULL,
                                       const bool inClass = false);

