////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"
#include "tagsmain.h"


//////////////////////////////////////////////////////////////////////
// "C" style API for tracking current tagging context, including
// all tags in the current file, as well as tracking the heirarchy
// of nested tag contexts.
//
// The context data is inheritently transient.  Since it is relatively
// inexpensive to compute, it is best if not stored, but simply
// recalculated when a new buffer is opened.
//


// Tag match types for speed insert of tag matches
#define VS_TAGMATCH_tag       0
#define VS_TAGMATCH_context   1
#define VS_TAGMATCH_local     2
#define VS_TAGMATCH_match     3
#define VS_TAGMATCH_statement 4

// Options flags used by various functions in context.e
// for example _MatchSymbolInContext()
enum VS_TAGCONTEXT_FLAGS {
   /**
    * Allow local variables to be included in the match set.
    */
   #define VS_TAGCONTEXT_ALLOW_locals        VSDEPRECATEDCONSTANT(0x00000001)
   VS_TAGCONTEXT_ALLOW_locals_deprecated        = 0x00000001,
   /**
    * Allow symbols which have private access level. 
    * <p> 
    * Usually, this is used initially when searching within the current class, 
    * then turned off when the search crosses into parent classes or the 
    * global scope. 
    */
   #define VS_TAGCONTEXT_ALLOW_private       VSDEPRECATEDCONSTANT(0x00000002)
   VS_TAGCONTEXT_ALLOW_private_deprecated       = 0x00000002,
   /**
    * Allow symbols which have protected access level. 
    * <p> 
    * Usually, this is used initially when seaching within the current class 
    * and parent classes, then turned off when the search crosses into the 
    * global scope or imported symbols. 
    */
   #define VS_TAGCONTEXT_ALLOW_protected     VSDEPRECATEDCONSTANT(0x00000004)
   VS_TAGCONTEXT_ALLOW_protected_deprecated     = 0x00000004,
   /**
    * Allow symbols which have package access level.
    * <p> 
    * Usually this is used initially when searching within the current package, 
    * then this flag is turned off when the search crosses into other packages 
    * or the global scope. 
    */
   #define VS_TAGCONTEXT_ALLOW_package       VSDEPRECATEDCONSTANT(0x00000008)
   VS_TAGCONTEXT_ALLOW_package_deprecated       = 0x00000008,
   /**
    * Only include symbols which are defined as volatile. 
    */
   #define VS_TAGCONTEXT_ONLY_volatile       VSDEPRECATEDCONSTANT(0x00000010)
   VS_TAGCONTEXT_ONLY_volatile_deprecated       = 0x00000010,
   /**
    * Only include symbols which are defined as const. 
    */
   #define VS_TAGCONTEXT_ONLY_const          VSDEPRECATEDCONSTANT(0x00000020)
   VS_TAGCONTEXT_ONLY_const_deprecated          = 0x00000020,
   /**
    * Only include symbols which are not defined as static. 
    * This is useful when searching for symbols in a statically qualified 
    * symbol scope, such as "CLASSNAME::" in C++.
    */
   #define VS_TAGCONTEXT_ONLY_static         VSDEPRECATEDCONSTANT(0x00000040)
   VS_TAGCONTEXT_ONLY_static_deprecated         = 0x00000040,
   /**
    * Only include symbols which are not defined as static.
    */
   #define VS_TAGCONTEXT_ONLY_non_static     VSDEPRECATEDCONSTANT(0x00000080)
   VS_TAGCONTEXT_ONLY_non_static_deprecated     = 0x00000080,
   /**
    * Only include variable declarations.
    */
   #define VS_TAGCONTEXT_ONLY_data           VSDEPRECATEDCONSTANT(0x00000100)
   VS_TAGCONTEXT_ONLY_data_deprecated           = 0x00000100,
   /**
    * Only include function and procedures.
    */
   #define VS_TAGCONTEXT_ONLY_funcs          VSDEPRECATEDCONSTANT(0x00000200)
   VS_TAGCONTEXT_ONLY_funcs_deprecated          = 0x00000200,
   /**
    * Only include classes, structs, records, unions, enums, groups, tables, 
    * and other structured type definitions. 
    */
   #define VS_TAGCONTEXT_ONLY_CLASSES        VSDEPRECATEDCONSTANT(0x00000400)
   VS_TAGCONTEXT_ONLY_CLASSES_deprecated        = 0x00000400,
   /**
    * Only include package and namespace symbols.
    */
   #define VS_TAGCONTEXT_ONLY_packages       VSDEPRECATEDCONSTANT(0x00000800)
   VS_TAGCONTEXT_ONLY_packages_deprecated       = 0x00000800,
   /**
    * Only look for symbols actually defined within the scope of the 
    * current search class.  Do not include out-of-line symbol definitions. 
    * This is useful, for example in C++, in order to narrow down the results 
    * to avoid including duplicate symbols (proc and prototype). 
    */
   #define VS_TAGCONTEXT_ONLY_inclass        VSDEPRECATEDCONSTANT(0x00001000)
   VS_TAGCONTEXT_ONLY_inclass_deprecated        = 0x00001000,
   /**
    * Only look for class constructors for the current search class.
    */
   #define VS_TAGCONTEXT_ONLY_constructors   VSDEPRECATEDCONSTANT(0x00002000)
   VS_TAGCONTEXT_ONLY_constructors_deprecated   = 0x00002000,
   /**
    * Only look for this symbol in the current search class.  Do not 
    * look in parent classes or the global scope. 
    */
   #define VS_TAGCONTEXT_ONLY_this_class     VSDEPRECATEDCONSTANT(0x00004000)
   VS_TAGCONTEXT_ONLY_this_class_deprecated     = 0x00004000,
   /**
    * Only look for this symbol in parent classes.  Do not include 
    * matches in the scope of the current class or global scope.
    */
   #define VS_TAGCONTEXT_ONLY_parents        VSDEPRECATEDCONSTANT(0x00008000)
   VS_TAGCONTEXT_ONLY_parents_deprecated        = 0x00008000,
   /**
    * Look for this symbol in classes and interfaces that derive from the 
    * specified search class.  This is used, for example, to find all the 
    * methods that override a virtual method in an interface class. 
    */
   #define VS_TAGCONTEXT_FIND_derived        VSDEPRECATEDCONSTANT(0x00010000)
   VS_TAGCONTEXT_FIND_derived_deprecated        = 0x00010000,
   /**
    * Include anonymous symbols, such as anonymous classes or structs.
    */
   #define VS_TAGCONTEXT_ALLOW_anonymous     VSDEPRECATEDCONSTANT(0x00020000)
   VS_TAGCONTEXT_ALLOW_anonymous_deprecated     = 0x00020000,
   /**
    * Only include local variables.
    */
   #define VS_TAGCONTEXT_ONLY_locals         VSDEPRECATEDCONSTANT(0x00040000)
   VS_TAGCONTEXT_ONLY_locals_deprecated         = 0x00040000,
   /**
    * Allow any symbol type, even friend symbols and import statements.
    */
   #define VS_TAGCONTEXT_ALLOW_any_tag_type  VSDEPRECATEDCONSTANT(0x00080000)
   VS_TAGCONTEXT_ALLOW_any_tag_type_deprecated  = 0x00080000,
   /**
    * Only include symbols which are defined as final.
    */
   #define VS_TAGCONTEXT_ONLY_final          VSDEPRECATEDCONSTANT(0x00100000)
   VS_TAGCONTEXT_ONLY_final_deprecated          = 0x00100000,
   /**
    * Only include symbols which are not defined as final.
    */
   #define VS_TAGCONTEXT_ONLY_non_final      VSDEPRECATEDCONSTANT(0x00200000)
   VS_TAGCONTEXT_ONLY_non_final_deprecated      = 0x00200000,
   /**
    * Only search for matches within the current 
    * (the symbols in the current file).
    */
   #define VS_TAGCONTEXT_ONLY_context        VSDEPRECATEDCONSTANT(0x00400000)
   VS_TAGCONTEXT_ONLY_context_deprecated        = 0x00400000,
   /**
    * Do not look for symbols in the global scope or imported into the global 
    * scope, only look within the current (and derived) class scopes and 
    * local variables. 
    */
   #define VS_TAGCONTEXT_NO_globals          VSDEPRECATEDCONSTANT(0x00800000)
   VS_TAGCONTEXT_NO_globals_deprecated          = 0x00800000,
   /**
    * Include forward class declarations and function declarations in 
    * the set of symbols found. 
    */
   #define VS_TAGCONTEXT_ALLOW_forward       VSDEPRECATEDCONSTANT(0x01000000)
   VS_TAGCONTEXT_ALLOW_forward_deprecated       = 0x01000000,
   /**
    * Find matching symbols without enforcing strict scoping rules.
    */
   #define VS_TAGCONTEXT_FIND_lenient        VSDEPRECATEDCONSTANT(0x02000000)
   VS_TAGCONTEXT_FIND_lenient_deprecated        = 0x02000000,
   /**
    * Find all definitions of this symbol, even after finding the nearest 
    * definition of this symbol in scope. 
    */
   #define VS_TAGCONTEXT_FIND_all            VSDEPRECATEDCONSTANT(0x04000000)
   VS_TAGCONTEXT_FIND_all_deprecated            = 0x04000000,
   /**
    * Look for this symbol in parent classes and interfaces. 
    */
   #define VS_TAGCONTEXT_FIND_parents        VSDEPRECATEDCONSTANT(0x08000000)
   VS_TAGCONTEXT_FIND_parents_deprecated        = 0x08000000,
   /**
    * Only look for symbols that are defined as templates or generics.
    */
   #define VS_TAGCONTEXT_ONLY_TEMPLATES      VSDEPRECATEDCONSTANT(0x10000000)
   VS_TAGCONTEXT_ONLY_TEMPLATES_deprecated      = 0x10000000,
   /**
    * Do not look for selectors (as in Objective-C).
    */
   #define VS_TAGCONTEXT_NO_selectors        VSDEPRECATEDCONSTANT(0x20000000)
   VS_TAGCONTEXT_NO_selectors_deprecated        = 0x20000000,
   /**
    * Only look for symbols in the current file.
    */
   #define VS_TAGCONTEXT_ONLY_this_file      VSDEPRECATEDCONSTANT(0x40000000)
   VS_TAGCONTEXT_ONLY_this_file_deprecated      = 0x40000000,
   /**
    * Do not look for symbols found nested in groups (as in COBOL), 
    * which are anonymous, opaque record types.
    */
   #define VS_TAGCONTEXT_NO_groups           VSDEPRECATEDCONSTANT(0x80000000, )
   VS_TAGCONTEXT_NO_groups_deprecated           = 0x80000000,  
   /**
    * Match symbosl with "private" level access control. 
    * Private level symbols are visible to the current class only, 
    * unless another symbol has a friend relationship with the class. 
    */
   #define VS_TAGCONTEXT_ACCESS_private      VSDEPRECATEDCONSTANT(0x0000000E)
   VS_TAGCONTEXT_ACCESS_private_deprecated      = 0x0000000E,
   /**
    * Match symbols with "protected" level access control. 
    * Protected level symbols are visible to the current class and all 
    * classes derived from it, but not visible to unrelated classes, 
    * unless another symbol has a friend relationship with the class. 
    */
   #define VS_TAGCONTEXT_ACCESS_protected    VSDEPRECATEDCONSTANT(0x0000000C)
   VS_TAGCONTEXT_ACCESS_protected_deprecated    = 0x0000000C,
   /**
    * Match symbols with "package" level access control. 
    * Package level symbols are supposed to be visible within the package 
    * they are defined, but not visible in other packages unless imported.
    */
   #define VS_TAGCONTEXT_ACCESS_package      VSDEPRECATEDCONSTANT(0x00000008)
   VS_TAGCONTEXT_ACCESS_package_deprecated      = 0x00000008,
   /**
    * Match symbols with "public" level access control. 
    * This flag is a no-op, since "public" symbols should always be visible. 
    */
   #define VS_TAGCONTEXT_ACCESS_public       VSDEPRECATEDCONSTANT(0x00000000)
   VS_TAGCONTEXT_ACCESS_public_deprecated       = 0x00000000,
   /**
    * Default context flags, typical flags used for matching any 
    * symbol following normal scoping rules. 
    */
   #define VS_TAGCONTEXT_ANYTHING            VSDEPRECATEDCONSTANT(0x00000000)
   VS_TAGCONTEXT_ANYTHING_deprecated            = 0x00000000,
};


/**
 * Flags for SEListTagstarget::removeDuplicateSymbols()
 */
enum VSTagRemoveDuplicatesOptionFlags {
   /**
    * Remove forward declarations of functions if the corresponding function 
    * definition is also in the match set.
    */
   VS_TAG_REMOVE_DUPLICATE_PROTOTYPES = 0x0001,
   /**
    * Remove forward or extern declarations of global and namespace level 
    * variables if the actual variable definition is also in the match set.
    */
   VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS = 0x0002,
   /**
    * Remove forward declarations of classes, structs, and 
    * interfaces if the actual definition is in the match set.
    */
   VS_TAG_REMOVE_DUPLICATE_CLASSES = 0x0004,
   /**
    * Remove all import statements from the match set.
    */
   VS_TAG_REMOVE_DUPLICATE_IMPORTS = 0x0008,
   /**
    * Remove all duplicate symbol definitions.
    */
   VS_TAG_REMOVE_DUPLICATE_SYMBOLS = 0x0010,
   /**
    * Remove tag matches that are found in the current symbol context.
    */
   VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE = 0x0020,
   /**
    * [not implemented here] 
    * Attempt to filter out function signatures that do not match.
    */
   VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES = 0x0040,
   /**
    * Filter out anonymous class names in preference of typedef.
    * for cases like typedef struct { ... } name_t;
    */
   VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES = 0x0080,
   /**
    * Filter out tags of type 'taguse'.  For cases of mixed language
    * Android projects, which have duplicate symbol names in the XML and Java.
    */
   VS_TAG_REMOVE_DUPLICATE_TAG_USES = 0x0100,
   /**
    * Filter out tags of type 'attribute'.  For cases of mixed language
    * Android projects, which have duplicate symbol names in the XML and Java.
    */
   VS_TAG_REMOVE_DUPLICATE_TAG_ATTRIBUTES = 0x0200,
   /** 
    * Filter out tags of type 'annotation' so that annotations
    * do not conflict with other symbols with the same name.
    */
   VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS = 0x0400,
   /** 
    * Filter out tags from files in languages which could not be referenced by 
    * the originating symbol.
    */
   VS_TAG_REMOVE_INVALID_LANG_REFERENCES = 0x0800,
   /** 
    * Filter out tags from files which were loaded using a binary load tags 
    * method, such as jar files or .NET dll files.
    */
   VS_TAG_REMOVE_BINARY_LOADED_TAGS = 0x1000,
};


///////////////////////////////////////////////////////////////////////////
//  Context tracking related functions.

/**
 * Set a thread synchronization lock on the contents of the current context, 
 * that is, the symbols found in the current file. 
 */
EXTERN_C int VSAPI tag_lock_context(int doWrite=false);
/**
 * Release the thread synchronization lock on the contents of the 
 * current context, that is, the symbols found in the current file. 
 */
EXTERN_C int VSAPI tag_unlock_context();

/**
 * Mark changes to the current context as complete. 
 *  
 * @param list_tags_flags (optional) statement level tagging option 
 * @return 0 on success, &lt;0 on error 
 */
EXTERN_C int VSAPI tag_commit_cached_context(int list_tags_flags);
/**
 * Mark changes to the current set of local variables as complete.
 *  
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locals in
 * @param list_all_option  list all locals, or only in scope?
 * 
 * @return 0 on success, &lt;0 on error 
 */
EXTERN_C int VSAPI tag_commit_cached_locals(int start_seekpos, int end_seekpos,
                                            int context_id, int update_flags);

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_context(). 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *  
 * @param outer_context    context ID for the outer context (eg. class/struct)
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type
 * @param file_name        full path of file the tag is located in
 * @param start_line_no    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_line_no    start line number of start of tag inner scope
 * @param scope_seekpos    start seek position of tag inner scope
 * @param end_line_no      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) end seek position of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see SE_TAG_FLAG_*
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_context(int outer_context,
                             VSPSZ tag_name, VSPSZ tag_type,
                             VSPSZ file_name,
                             int start_line_no, int start_seekpos,
                             int scope_line_no, int scope_seekpos,
                             int end_line_no, int end_seekpos,
                             VSPSZ class_name, int tag_flags,
                             VSPSZ signature);

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_context(). 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *  
 * @param outer_context    context ID for the outer context (eg. class/struct)
 * @param cm         Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                   This contains all the information about the symbol. 
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_context_browse_info(int outer_context, VSHREFVAR cm);

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_context(). 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *  
 * @param outer_context    context ID for the outer context (eg. class/struct)
 * @param symbolInfo Instance of Slick-C <code>class se.tags.SymbolInfo</code> to insert. 
 *                   This contains all the information about the symbol. 
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_context_symbol_info(int outer_context, VSHREFVAR symbolInfo);

/**
 * Set the end positions of the context with the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       id for the context to modify
 * @param end_line_no      ending line number of tag within file
 * @param end_seekpos      end seek position of tag within file
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_end_context(int context_id, int end_line_no, int end_seekpos);

/**
 * Set the name and line number positions for the symbol name 
 * of the context with the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       Context ID [ from 1 to {@link tag_get_num_of_context}() ] of
 *                         context tag to set end position of.
 * @param name_line_no     line number that symbol name is located on
 * @param name_seekpos     Seek position of the first character of the symbol name 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_context 
 * @see tag_end_context 
 * @see tag_get_detail2 
 */
EXTERN_C
int VSAPI tag_set_context_name_location(int context_id, int name_line_no, int name_seekpos);

/**
 * Set the class inheritance for the given context tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       id for the context to modify
 * @param parents          parents of the context item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_context_parents(int context_id, VSPSZ parents);

/**
 * Set the template signature for the given context tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       id for the context to modify
 * @param template_sig     template signature of the context item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_context_template_signature(int context_id, VSPSZ template_sig);

/**
 * Revise the type signature for the given item in the current context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param tag_name         name of variable to modify
 * @param type_name        type signature of the local item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_context_type_signature(VSPSZ tag_name, VSPSZ type_name, int case_sensitive VSDEFAULT(false));

/**
 * Clear all context information.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param file_name           (optional) optional file name to set context to 
 * @param preserveTokenList   (optional) preserve token list 
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_clear_context(/*VSHREFVAR file_name, bool preserveTokenList=false*/);

/**
 * Return the total number of context tags including statements.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return the total number of context tags including statements.
 */
EXTERN_C
int VSAPI tag_get_num_of_statements();

/**
 * Return the total number of context tags.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return the total number of context tags.
 */
EXTERN_C
int VSAPI tag_get_num_of_context();

/**
 * Retrieve information about the given context ID. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id       context ID to look up (from tag_insert_context)
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param start_line_no    (reference) start line number of tag within file
 * @param start_seekpos    (reference) start seek position of tag within file
 * @param scope_line_no    (reference)start line number of start of tag inner scope
 * @param scope_seekpos    (reference) start seek position of tag inner scope
 * @param end_line_no      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) end seek position of tag within file
 * @param class_name       (reference) name of class that tag is present in,
 *                         uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 * @param tag_flags        (reference) see SE_TAG_FLAG_*
 * @param signature        (reference) arguments or formal parameters
 * @param return_type      (reference) constant value or return type
 *
 * @return 0 on success. 
 *  
 * @see tag_insert_context 
 * @see tag_get_context_simple 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_get_statement_browse_info 
 * @see tag_get_statement_symbol_info 
 */
EXTERN_C
int VSAPI tag_get_context(int context_id,
                          VSHREFVAR tag_name, VSHREFVAR type_name,
                          VSHREFVAR file_name,
                          VSHREFVAR start_line_no, VSHREFVAR start_seekpos,
                          VSHREFVAR scope_line_no, VSHREFVAR scope_seekpos,
                          VSHREFVAR end_line_no,   VSHREFVAR end_seekpos,
                          VSHREFVAR class_name, VSHREFVAR tag_flags,
                          VSHREFVAR signature, VSHREFVAR return_type);

/**
 * Retrieve minimal information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id       context ID to look up (from tag_insert_context)
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param start_line_no    (reference) start line number of tag within file
 * @param class_name       (reference) name of class that tag is present in,
 *                         uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 * @param tag_flags        (reference) see SE_TAG_FLAG_*
 * @param signature        (reference) arguments or formal parameters
 * @param return_type      (reference) constant value or return type
 *
 * @return 0 on success. 
 *  
 * @see tag_get_context 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_get_statement_browse_info 
 * @see tag_get_statement_symbol_info 
 */
EXTERN_C
int VSAPI tag_get_context_simple(int context_id,
                                 VSHREFVAR tag_name, VSHREFVAR type_name,
                                 VSHREFVAR file_name, VSHREFVAR start_line_no,
                                 VSHREFVAR class_name, VSHREFVAR tag_flags,
                                 VSHREFVAR signature, VSHREFVAR return_type);


/**
 * Retrieve information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                   of context tag to retrieve information about.
 * @param cm         (Output) Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 */
EXTERN_C
int VSAPI tag_get_context_browse_info(int context_id, VSHREFVAR cm);

/**
 * Retrieve information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                   of context tag to retrieve information about.
 * @param cm         (Output) Instance of Slick-C <code>class se.tags.SymbolInfo</code> to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 */
EXTERN_C
int VSAPI tag_get_context_symbol_info(int context_id, VSHREFVAR symbolInfo);

/**
 * Retrieve information about the given statement ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param statement_id  Statement ID [ from 1 to {@link tag_get_num_of_statements}() ] 
 *                      of statement context tag to retrieve information about.
 * @param cm            (Output) Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 */
EXTERN_C
int VSAPI tag_get_statement_browse_info(int statement_id, VSHREFVAR cm);

/**
 * Retrieve information about the given statement ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param statement_id  Statement ID [ from 1 to {@link tag_get_num_of_statements}() ] 
 *                      of statement context tag to retrieve information about.
 * @param cm            (Output) Instance of Slick-C <code>class se.tags.SymbolInfo</code> to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 */
EXTERN_C
int VSAPI tag_get_statement_symbol_info(int statement_id, VSHREFVAR symbolInfo);

/**
 * Check if the current buffer position is still within the current context
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return One of the following codes:
 * <PRE>
 *     0 -- the context is not set or totally wrong
 *    -1 -- context info loaded, but the cursor is out of context
 *     1 -- the context is within the tag definition
 *     2 -- the context is within the scope of the tag/function
 * </PRE>
 */
EXTERN_C
int VSAPI tag_check_context();

/**
 * Check if the list of symbols for the current file are
 * already up-to-date.  Switch to one of the cached file lists
 * if necessary.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param list_tags_flags (optional) statement level tagging option 
 * @return 1 if the context is up-to-date, 0 otherwise.
 *
 * @see tag_current_context
 * @see tag_get_context
 * @see tag_check_cached_locals
 */
EXTERN_C
int VSAPI tag_check_cached_context(int list_tags_flags /*=VS_UPDATEFLAG_context*/);

/**
 * Calculate the start and end offset of the portion of the file 
 * that was modified since the last time this file was tagged. 
 * Then retag that portion and replace those items in the current 
 * context. 
 * <p> 
 * This code depends on the tagging having built a token list 
 * and the tagging engine supporting restartable tagging. 
 * 
 * @param start_offset  [output] offset in bytes from the beginning 
 *                      of the file to start incremental parsing at.
 * @param end_offset    [output] offset in bytes from beginning of file 
 *                      to stop incremental parsing at. 
 * 
 * @return 0 on success, &lt;0 on error. 
 *         An error indicates that the whole file should be parsed.
 *  
 * @see tag_check_context
 * @see tag_check_cached_context 
 * @see SETagGetContextTokenList 
 */
EXTERN_C
int VSAPI tag_update_context_incrementally(VSHREFVAR start_offset,
                                           VSHREFVAR end_offset);

/**
 * Check if the list of symbols for the current file and position
 * are already up-to-date.  Switch to one of the cached local
 * variable lists if necessary.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locas in
 * @param update_flags     bitset of VS_UPDATEFLAG_*, option to find all locals, 
 *                         or just up to cursor position? 
 * 
 * @return 1 if the locals are up-to-date, 0 otherwise.
 *
 * @see tag_check_cached_context
 * @see tag_get_local
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 */
EXTERN_C
int VSAPI tag_check_cached_locals(int start_seekpos, int end_seekpos, 
                                  int context_id, int update_flags);

/**
 * Sort the items in the current context by seek position.
 * The precise sort order is first by non-descrasing starting
 * seekpos, and for items with identical start seek positions,
 * non-increasing end seek position, and for items with identical
 * span, the original insertion order for the items.
 * <p>
 * In addition to sorting the items in the current context, this
 * function computes the outer contexts for each item in the
 * current context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_sort_context();

/**
 * Return the index of the current context item whose name and 
 * name location matches the symbol under the cursor. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current context.
 */
EXTERN_C
int VSAPI tag_current_context_name();

/**
 * Return the index of the current context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current context.
 */
EXTERN_C
int VSAPI tag_current_context();

/**
 * Return the index of the current context item,
 * including statements and preprocessing.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current context.
 */
EXTERN_C
int VSAPI tag_current_statement();

/**
 * Return the index of the nearest context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param linenum          line number to check context on
 *
 * @return &lt;0 on error, 0 if no such context.
 */
EXTERN_C
int VSAPI tag_nearest_context(int linenum);

/**
 * Return the index of the nearest statement context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param linenum          line number to check context on
 *
 * @return &lt;0 on error, 0 if no such statement.
 */
EXTERN_C 
int VSAPI tag_nearest_statement(int linenum, VSUINT64Param filter_flags=SE_TAG_FILTER_ANYTHING, int findTagAfter=0);

/**
 * Find a the first context entry with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anon       (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found. 
 *  
 * @deprecated Use tag_find_context_iterator 
 */
EXTERN_C VSDEPRECATED 
int VSAPI tag_find_context(VSPSZ tag_prefix, int exact, int case_sensitive /*,int allow_anon=0, VSPSZ class_name=NULL*/);

/**
 * Find a the next context entry with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anon       (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found.
 */
EXTERN_C
int VSAPI tag_next_context(VSPSZ tag_prefix, int exact, int case_sensitive /*,int allow_anon=0, VSPSZ class_name=NULL*/);

/**
 * Find a the first context entry with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anonymous  (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found.
 */
EXTERN_C
int VSAPI tag_find_context_iterator(VSPSZ tag_prefix, 
                                    int exact, int case_sensitive,
                                    int allow_anonymous=0, 
                                    VSPSZ class_name=0);

/**
 * Find a the next context entry with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param startIndex       start searching after the given context ID
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anonymous  (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found.
 */
EXTERN_C
int VSAPI tag_next_context_iterator(VSPSZ tag_prefix, int startIndex,
                                    int exact, int case_sensitive,
                                    int allow_anonymous=0, 
                                    VSPSZ class_name=0);

/**
 * Insert all the context items into the given tree.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param treeWID          tree widget to load info into
 * @param treeIndex        tree index to insert into
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       force item to be inserted as a leaf item
 * @param tree_flags       tree flags to set for this item
 * @param pushtag_flags    PUSHTAG_*, see slick.sh
 * @param show_statements  Show statements in proctree
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_tree_insert_context(int treeWID, int treeIndex,
                                  VSUINT64Param pushtag_flags, 
                                  int include_tab, 
                                  int force_leaf,
                                  int tree_flags, 
                                  int show_statements );

/**
 * Insert all the context items into the given tree using the outline view 
 * rendering style. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param treeWID          tree widget to load info into
 * @param treeIndex        tree index to insert into
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       force item to be inserted as a leaf item
 * @param tree_flags       tree flags to set for this item
 * @param pushtag_flags    PUSHTAG_*, see slick.sh
 * @param show_statements  Show statements in proctree
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C 
int VSAPI tag_tree_insert_context_outline(int treeWID, int treeIndex,
                                          int include_tab, int force_leaf,
                                          int tree_flags, 
                                          VSUINT64Param pushtag_flags, 
                                          int show_statements );

/**
 * This function is the default implementation of the outline 
 * view, where a node is inserted in the tag tree for eveny node
 * in the xml.  the rest of the tree node is popuated with an 
 * enumerated list of attribute / value pairs.
 * 
 * @param tree_id : tree widget to load info into
 * @param tree_index : tree index to insert into
 * @param proctree_flags : SE_TAG_FILTER_*
 * @param include_tab : append class name after signature if 1, prepend
 *                    class name with :: if 0
 * @param force_leaf : force item to be inserted as a leaf item
 * @param tree_flags : tree flags to set for this item
 * 
 * @return Returns tree index on success, &lt;0 on error.
 */
EXTERN_C 
int VSAPI tag_tree_insert_default_outline(int treeWID, int treeIndex,
                                          int include_tab, int force_leaf,
                                          int tree_flags, 
                                          VSUINT64Param pushtag_flags, 
                                          int show_statements );

/**
 * @return Return 1 if the given context ID should be included in the 
 *         XML outline.  Return 0 otherwise.
 * 
 * @param context_id    ID of item in current context (1..n)
 */
EXTERN_C 
int VSAPI tag_tree_filter_outline(int context_id);

/**
 * Insert all the tags from the current context into the currently
 * open tag file.  Assumes that the context is up-to-date at the
 * time that this function is called.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param file_name        typically p_buf_name, absolute path of buffer
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_transfer_context(VSPSZ file_name);

/**
 * Get the basic information about the given token ID in the current context. 
 * The current context has to be built with the token list for this to work. 
 * 
 * @param token_id      token ID
 * @param token_type    token type (SETokenType) 
 * @param token_text    token contents
 * @param offset        seek position of token
 * @param linenum       line number token starts at
 * 
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_token_info(int token_id, 
                   VSHREFVAR token_type,
                   VSHREFVAR token_text,
                   VSHREFVAR offset,
                   VSHREFVAR linenum);

/**
 * Get the token type for the given token ID in the current context. 
 * The current context has to be built with the token list for this to work. 
 * 
 * @param token_id      token ID
 * 
 * @return token type (SETokenType) &gt;=0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI
tag_get_token_type(int token_id);

/** 
 * @return 
 * Return the name for the given token type.
 * 
 * @param token_type    token type (SETokenType)
 */
EXTERN_C VSPSZ VSAPI
tag_get_token_type_name(int token_type);

/**
 * Get the token parsing error status for the given token ID in the current context. 
 * The current context has to be built with the token list for this to work. 
 * 
 * @param token_id      token ID
 * 
 * @return parse error status (SETokenErrorStatus) &gt;=0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI
tag_get_token_status(int token_id);

/**
 * @return 
 * Return the token ID of the token at the given seek position in the current context. 
 * Return's 0 if the given seekpos is whitespace or a comment (not a token). 
 * 
 * @param seekpos    seek position to look for token at
 */
EXTERN_C int VSAPI
tag_get_current_token(int seekpos);

/**
 * Get the first token in the current context, or in the given 
 * embedded code block. 
 * 
 * @param embedded_token_id   token ID of embedded code block 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_first_token(int embedded_token_id VSDEFAULT(0));

/**
 * Get the last token in the current context, or in the given 
 * embedded code block. 
 * 
 * @param embedded_token_id   token ID of embedded code block 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_last_token(int embedded_token_id VSDEFAULT(0));

/**
 * Get the next token after the given token.
 * 
 * @param token_id   token ID 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_next_token(int token_id);

/**
 * Get the previous token before the given token.
 * 
 * @param token_id   token ID 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_prev_token(int token_id);

/**
 * Get the first token in the current context, or in the given 
 * preprocessed code block. 
 * 
 * @param pp_token_id   token ID of embedded code block 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_first_pptoken(int pp_token_id VSDEFAULT(0));

/**
 * Get the last token in the current context, or in the given 
 * preprocessed code block. 
 * 
 * @param pp_token_id   token ID of embedded code block 
 *  
 * @return token ID > 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_last_pptoken(int pp_token_id VSDEFAULT(0));


///////////////////////////////////////////////////////////////////////////
// Local declarations related tracking functions

/**
 * Add a local variable tag and its information to the locals list.
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_local().
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type
 * @param file_name        full path of file the tag is located in
 * @param line_no          start line number of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see SE_TAG_FLAG_*
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_local(VSPSZ tag_name, VSPSZ tag_type,
                           VSPSZ file_name, int line_no,
                           VSPSZ class_name, int tag_flags,
                           VSPSZ signature);

/**
 * Add a local variable tag and its information to the locals list.
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_local().
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type
 * @param file_name        full path of file the tag is located in
 * @param start_linenum    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_linenum    start line number of start of tag inner scope
 * @param scope_seekpos    start seek position of tag inner scope
 * @param end_linenum      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) end seek position of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see SE_TAG_FLAG_*
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_local2(VSPSZ tag_name, VSPSZ tag_type, VSPSZ file_name,
                            int start_linenum, int start_seekpos,
                            int scope_linenum, int scope_seekpos,
                            int end_linenum,   int end_seekpos,
                            VSPSZ class_name, int tag_flags, VSPSZ signature);

/**
 * Add a local variable tag and its information to the locals list.
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_local().
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param cm               Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                         This contains all the information about the symbol. 
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_local_browse_info(VSHREFVAR cm);

/**
 * Add a local variable tag and its information to the locals list.
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_local().
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param symbolInfo          Instance of {@link se.tags.SymbolInfo} to insert. 
 *                            This contains all the information about the symbol. 
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_local_symbol_info(VSHREFVAR symbolInfo);

/**
 * Set the end positions of the local with the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local to modify
 * @param end_line_no      ending line number of tag within file
 * @param end_seekpos      end seek position of tag within file
 *
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C
int VSAPI tag_end_local(int local_id, int end_line_no, int end_seekpos);

/**
 * Sort the local variables in the current context by seek position.
 * The precise sort order is first by non-descrasing starting
 * seekpos, and for items with identical start seek positions,
 * non-increasing end seek position, and for items with identical
 * span, the original insertion order for the items.
 * <p>
 * In addition to sorting the local variables, this function computes
 * the outer contexts.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_sort_locals();

/**
 * Return the index of the current local variable.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current local variable.
 */
EXTERN_C
int VSAPI tag_current_local();

/**
 * Return the index of the current local item whose name and 
 * name location matches the symbol under the cursor. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current context.
 */
EXTERN_C
int VSAPI tag_current_local_name();

/**
 * Set the name and line number positions for the local symbol name 
 * with the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id       Local ID [ from 1 to {@link tag_get_num_of_locals}() ]
 * @param name_line_no   line number that symbol name is located on
 * @param name_seekpos   Seek position of the first character of the symbol name 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_local 
 * @see tag_end_local 
 * @see tag_get_detail2 
 */
EXTERN_C
int VSAPI tag_set_local_name_location(int local_id, int name_line_no, int name_seekpos);

/**
 * Set the class inheritance for the given local tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local to modify
 * @param parents          parents of the local item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_local_parents(int local_id, VSPSZ parents);

/**
 * Set the template signature for the given local tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local to modify
 * @param template_sig     template signature of the local item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_local_template_signature(int local_id, VSPSZ template_sig);

/**
 * Revise the type signature for the given local variable.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_name       name of local variable to modify
 * @param type_name        type signature of the local item
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_local_type_signature(VSPSZ local_name, VSPSZ type_name, int case_sensitive VSDEFAULT(false));

/**
 * Return the total number of local variables
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return the number of local variables
 */
EXTERN_C
int VSAPI tag_get_num_of_locals();

/**
 * Is the given local variable in scope at the current seek position?
 * 
 * @param local_id   local variable ID (1..n)
 * @param seekpos    seek position within current file/function
 * 
 * @return 'true' if the variable is in scope, false otherwise
 */
EXTERN_C
int VSAPI tag_is_local_in_scope(int local_id, int seekpos);

/**
 * Kill all locals after 'local_id', not including 'local_id'
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local variable to start removing at
 *                         Use '0' to remove all locals and reset the date tagged. 
 *                         Use '1' to remove all locals.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_clear_locals(int local_id);

/**
 * Retrieve information about the given local variable or parameter.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id         local ID to look up (from tag_insert_local)
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) start line number of tag within file
 * @param class_name       (reference) name of class that tag is present in,
 * @param tag_flags        uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 *                         (reference) see SE_TAG_FLAG_*
 * @param signature        (reference) arguments or formal parameters
 * @param return_type      (reference) constant value or return type
 *
 * @return 0 on success.
 */
EXTERN_C
int VSAPI tag_get_local(int local_id,
                        VSHREFVAR tag_name, VSHREFVAR type_name,
                        VSHREFVAR file_name, VSHREFVAR line_no,
                        VSHREFVAR class_name, VSHREFVAR tag_flags,
                        VSHREFVAR signature, VSHREFVAR return_type);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id       local ID to look up (from tag_insert_local)
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param start_linenum    (reference) start line number of tag within file
 * @param start_seekpos    (reference) start seek position of tag within file
 * @param scope_linenum    (reference)start line number of start of tag inner scope
 * @param scope_seekpos    (reference) start seek position of tag inner scope
 * @param end_linenum      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) end seek position of tag within file
 * @param class_name       (reference) name of class that tag is present in,
 *                         uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 * @param tag_flags        (reference) see SE_TAG_FLAG_*
 * @param signature        (reference) arguments or formal parameters
 * @param return_type      (reference) constant value or return type
 *
 * @return 0 on success.
 */
EXTERN_C
int VSAPI tag_get_local2(int local_id,
                         VSHREFVAR tag_name, VSHREFVAR type_name,
                         VSHREFVAR file_name,
                         VSHREFVAR start_linenum, VSHREFVAR start_seekpos,
                         VSHREFVAR scope_linenum, VSHREFVAR scope_seekpos,
                         VSHREFVAR end_linenum,   VSHREFVAR end_seekpos,
                         VSHREFVAR class_name, VSHREFVAR tag_flags,
                         VSHREFVAR signature, VSHREFVAR return_type);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id         local ID to look up (from tag_insert_local)
 * @param cm               (Output) Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to fill in. 
 *
 * @return 0 on success.
 */
EXTERN_C
int VSAPI tag_get_local_browse_info(int local_id, VSHREFVAR cm);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id         local ID to look up (from tag_insert_local)
 * @param symbolInfo       (Output) Instance of Slick-C <code>class se.tags.SymbolInfo</code> to fill in. 
 *
 * @return 0 on success.
 */
EXTERN_C
int VSAPI tag_get_local_symbol_info(int local_id, VSHREFVAR symbolInfo);

/**
 * Find a the first local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anon       (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return local ID of tag if found, &lt;0 on error or not found. 
 *  
 * @deprecated Use tag_find_local_iterator() 
*/
EXTERN_C VSDEPRECATED 
int VSAPI tag_find_local(VSPSZ tag_prefix, int exact, int case_sensitive /*,int allow_anon=0, VSPSZ class_name=NULL*/);

/**
 * Find a the next local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anon       (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return local ID of tag if found, &lt;0 on error or not found. 
 *  
 * @deprecated Use tag_next_local_iterator() 
 */
EXTERN_C VSDEPRECATED 
int VSAPI tag_next_local(VSPSZ tag_prefix, int exact, int case_sensitive /*,int allow_anon=0, VSPSZ class_name=NULL*/);

/**
 * Find a the first local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anonymous  (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return local ID of tag if found, &lt;0 on error or not found.
*/
EXTERN_C
int VSAPI tag_find_local_iterator(VSPSZ tag_prefix, 
                                  int exact, int case_sensitive,
                                  int allow_anonymous=0, 
                                  VSPSZ class_name=0);

/**
 * Find a the next local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       tag name or prefix of tag name 
 * @param startIndex       start searching after the given local ID
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param allow_anonymous  (optional) pass through anonymous classes
 * @param class_name       (optional) class to find item in
 *
 * @return local ID of tag if found, &lt;0 on error or not found.
 */
EXTERN_C
int VSAPI tag_next_local_iterator(VSPSZ tag_prefix, int startIndex,
                                  int exact, int case_sensitive,
                                  int allow_anonymous=0, 
                                  VSPSZ class_name=0);


///////////////////////////////////////////////////////////////////////////
// Search match tracking related functions

/**
 * Set a thread synchronization lock on the current set of matches.
 */
EXTERN_C void VSAPI tag_lock_matches(int doWrite=false);
/**
 * Release the thread synchronization lock on the current set of matches.
 */
EXTERN_C int VSAPI tag_unlock_matches();

/**
 * Add a search match tag and its information to the matches list.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param tag_file         (optional) full path of tag file match came from
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type
 * @param file_name        full path of file the tag is located in
 * @param line_no          start line number of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see SE_TAG_FLAG_*
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_match(VSPSZ tag_file,
                           VSPSZ tag_name, VSPSZ tag_type,
                           VSPSZ file_name, int line_no,
                           VSPSZ class_name, int tag_flags,
                           VSPSZ signature);

/**
 * Add a search match tag and its information to the matches list.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param tag_file         (optional) full path of tag file match came from
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type
 * @param file_name        full path of file the tag is located in
 * @param start_linenum    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_linenum    start line number of start of tag inner scope
 * @param scope_seekpos    start seek position of tag inner scope
 * @param end_linenum      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) end seek position of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags         (optional) see SE_TAG_FLAG_*
 * @param signature         (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_match2(VSPSZ tag_file,
                            VSPSZ tag_name, VSPSZ tag_type, VSPSZ file_name,
                            int start_linenum, int start_seekpos,
                            int scope_linenum, int scope_seekpos,
                            int end_linenum, int end_seekpos,
                            VSPSZ class_name, int tag_flags,
                            VSPSZ signature);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of tags
 * very efficiently through the match set.  This is useful when searching for specific
 * tags.  Many of the Context Tagging&reg; functions are designed to insert directly into
 * the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param cm                  Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                            This contains all the information about the symbol. 
 * @param checkForDuplicates  Before inserting, verify that the symbol is not 
 *                            already in the match set, return match_id if so. 
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 */
EXTERN_C int 
VSAPI tag_insert_match_browse_info(VSHREFVAR cm, int checkForDuplicates/*=true*/);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of tags
 * very efficiently through the match set.  This is useful when searching for specific
 * tags.  Many of the Context Tagging&reg; functions are designed to insert directly into
 * the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param cm                  Instance of Slick-C <code>class se.tags.SymbolInfo</code> to insert. 
 *                            This contains all the information about the symbol. 
 * @param checkForDuplicates  Before inserting, verify that the symbol is not 
 *                            already in the match set, return match_id if so. 
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 */
EXTERN_C 
int VSAPI tag_insert_match_symbol_info(VSHREFVAR symbolInfo, int checkForDuplicates/*=true*/);

/**
 * Set the class inheritance for the given match.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param match_id   Match ID [ from 1 to {@link tag_get_num_of_matches}() ] of
 *                   match tag representing class or struct to set inheritance relationships for.
 * @param parents    Delimited list of immediate class ancestors.  It is
 *                   important to remember that for some languages, all classes
 *                   have a default ancestor, such as <i>java.lang/Object</i> in Java.
 *                   Otherwise, use the empty string to indicate that class_name
 *                   is a base class.  See {@link VS_TAGSEPARATOR_parents} for
 *                   more details on constructing this string.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C 
int VSAPI tag_set_match_parents(int match_id, VSPSZ parents);

/**
 * Set the template signature for the given match.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 * 
 * @param match_id   Match ID [ from 1 to {@link tag_get_num_of_matches}() ] of
 *                   match tag representing class or struct to set inheritance relationships for.
 * @param template_signature
 *                   Template signature for the tag, in language
 *                   specific format, normally delimited by commas.
 * 
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_match_template_signature(int match_id, VSPSZ template_args);

/**
 * Speedy version of tag_insert_match that simply clones a context,
 * local, or current tag match
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param match_type       match type, VS_TAGMATCH_*, local, context, tag
 * @param local_or_ctx_id  ID of local variable or tag in current context
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_match_fast(int match_type, int local_or_ctx_id);

/**
 * Return the total number of search matches
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(false) 
 * prior to invoking this function.
 *
 * @return the total number of matches
 */
EXTERN_C
int VSAPI tag_get_num_of_matches();

/**
 * Remove one match from the match set.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param match_id      ID of match to remove from match set
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_remove_match(int match_id);

/**
 * Kill all search matches.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_clear_matches();

/**
 * Push the current match set onto the stack of match sets and
 * initialize the new stack top to an empty match set
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_push_matches();

/**
 * Clear the current match set and pop it off of the stack.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 */
EXTERN_C
void VSAPI tag_pop_matches();

/**
 * Transfer the contents of the current match set to the
 * previous match set, and pop it off of the stack.
 * This is similar to tag_pop_matches(), except that
 * the contents of the match set are not thrown away.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 */
EXTERN_C
void VSAPI tag_join_matches();

/**
 * Push the current match set onto the stack of match sets and
 * transfer the context set to the top of the match set stack.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(true) prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_push_context();

/**
 * Transfers the current match set to the context set and
 * pop it off of the match set stack.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(true) prior to invoking this function.
 */
EXTERN_C
void VSAPI tag_pop_context();

/**
 * Retrieve information about the given search match.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(false) 
 * prior to invoking this function.
 *
 * @param match_id         match ID to look up (from tag_insert_match)
 * @param tag_file         (reference) tag file that match came from
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) start line number of tag within file
 * @param class_name       (reference) name of class that tag is present in,
 *                         uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 * @param tag_flags        (reference) see SE_TAG_FLAG_*
 * @param signature        (reference) arguments or formal parameters
 * @param return_type      (reference) constant value or return type
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_get_match(int match_id, VSHREFVAR tag_file,
                        VSHREFVAR tag_name, VSHREFVAR type_name,
                        VSHREFVAR file_name, VSHREFVAR line_no,
                        VSHREFVAR class_name, VSHREFVAR tag_flags,
                        VSHREFVAR signature, VSHREFVAR return_type);

/**
 * Retrieve information about the given tag match.  Though this function is highly
 * optimized, it is often more efficient to use {@link tag_get_detail2} to retrieve only
 * specific information about a match rather than everything.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(false) 
 * prior to invoking this function.
 *
 * @param match_id   Match ID [ from 1 to {@link tag_get_num_of_matches}() ] of tag
 *                   match to retrieve information about.
 * @param cm         (Output) Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to fill in. 
 *
 * @return 0 on success, &lt;0 on error.
 *  
 * @see tag_get_match 
 * @see tag_clear_matches
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_pop_matches
 * @see tag_push_matches
 */
EXTERN_C 
int VSAPI tag_get_match_browse_info(int match_id, VSHREFVAR cm);

/**
 * Retrieve information about the given tag match.  Though this function is highly
 * optimized, it is often more efficient to use {@link tag_get_detail2} to retrieve only
 * specific information about a match rather than everything.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(false) 
 * prior to invoking this function.
 *
 * @param match_id         Match ID [ from 1 to {@link tag_get_num_of_matches}() ] of tag
 *                         match to retrieve information about.
 * @param symbolInfo       (Output) Instance of Slick-C <code>class se.tags.SymbolInfo</code> to fill in.
 *
 * @return 0 on success, &lt;0 on error.
 *  
 * @see tag_get_match 
 * @see tag_clear_matches
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_pop_matches
 * @see tag_push_matches
 */
EXTERN_C 
int VSAPI tag_get_match_symbol_info(int match_id, VSHREFVAR symbolInfo);


/**
 * Walk through all the matches in the current set of symbol matches and 
 * compute the longest common case-insenstivie prefix match. 
 * 
 * @param lastid                       identifier (maybe prefix) being matched
 * @param longest_prefix               (output) set to longest prefix match
 * @param longest_case_prefix          (output) set to longest prefix with matches 'lastid' case-sensitive
 * @param longest_caption              (output) set to longest caption in match set
 * @param longest_prefix_case_is_same  (output) set to true if all the prefixes match in the same case
 * 
 * @return 0 if there are no matches in the match set, 1 otherwise.
 */
EXTERN_C
int VSAPI tag_find_longest_prefix_match(SEStringConst lastid, 
                                        SEStringByRef longest_prefix,
                                        SEStringByRef longest_case_prefix,
                                        SEStringByRef longest_caption,
                                        bool &longest_prefix_case_is_same);

/** 
 * Walk through all teh matches in the current set of symbol pattern matches 
 * and compute the longest common prefix match, and also determine if it is 
 * unique, and if for all prefix matches of the same length, if they have 
 * the same casing. 
 *  
 * @param lastid                       identifier (maybe prefix) being matched 
 * @param case_sensitive               case-sensitive pattern matching? 
 * @param pattern_flags                symbol pattern matching options 
 * @param longest_prefix               (output) set to longest prefix match
 * @param longest_prefix_is_unique     (output) is the longest prefix match unique?
 * @param longest_prefix_case_is_same  (output) set to true if all the prefixes match in the same case
 * 
 * @return Return the number of matches found, return 0 if none are found. 
 *         Return 1 if there was one unique match found.
 */ 
EXTERN_C 
int VSAPI tag_find_longest_pattern_match(SEStringConst lastid, 
                                         bool case_sensitive,
                                         VSUINT64Param i_pattern_flags,
                                         SEStringByRef longest_prefix,
                                         SEStringByRef longest_caption,
                                         bool &longest_prefix_case_is_same);

/** 
 * Walk through all teh matches in the current set of fuzzy symbol matches 
 * and compute the longest common prefix match, and also determine if it is 
 * unique, and if for all prefix matches of the same length, if they have 
 * the same casing. 
 *  
 * @param lastid                       identifier (maybe prefix) being matched 
 * @param case_sensitive               case-sensitive pattern matching? 
 * @param start_col                    start column within tag name
 * @param longest_prefix               (output) set to longest prefix match
 * @param longest_prefix_is_unique     (output) is the longest prefix match unique?
 * @param longest_prefix_case_is_same  (output) set to true if all the prefixes match in the same case
 * 
 * @return Return the number of matches found, return 0 if none are found. 
 *         Return 1 if there was one unique match found.
 */ 
EXTERN_C
int VSAPI tag_find_longest_fuzzy_match(SEStringConst lastid, 
                                       bool case_sensitive,
                                       int start_col,
                                       SEStringByRef longest_prefix,
                                       SEStringByRef longest_caption,
                                       bool &longest_prefix_case_is_same);


///////////////////////////////////////////////////////////////////////////
// Utility functions for grabbing individual attributes of a symbol in
// the current context, locals, matches, or tag databse.

/**
 * Get the given detail type for the given item either as a
 * context tag, local tag, or part of a match set.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * or tag_lock_matches(false) prior to invoking this function.
 *
 * @param detail_id        VS_TAGDETAIL_* (see tagsdb.h)
 * @param item_id          context_id, local_id, or match_id
 * @param result           (reference) value of detail is returned here
 */
EXTERN_C
void VSAPI tag_get_detail2(int detail_id, int item_id, VSHREFVAR result);


///////////////////////////////////////////////////////////////////////////
// Utility functions for implementing Context Tagging(R) functions,
// optimized version of former components of context.e

/**
 * Returns true if at the current access level, we have access to the member
 * with the given flags at our access level.
 *
 * @param context_flags    SE_TAG_CONTEXT_*
 * @param tag_flags        SE_TAG_FLAG_* (from tag details)
 *
 * @return 1 if we have access to the tag, 0 if not
 */
EXTERN_C
int VSAPI tag_check_access_level(VSUINT64Param context_flags, VSUINT64Param tag_flags);

/**
 * Returns true if the tag having the given tag_flags and type matches the
 * requirements set by the given context flags.
 *
 * @param context_flags    SE_TAG_CONTEXT_*
 * @param tag_flags        SE_TAG_FLAG_* (from tag details)
 * @param type_name        tag type (from tag details)
 *
 * @return Returns 1 if the tag with the given type and flags passes
 *         the context flags, otherwise, returns 0.
 */
EXTERN_C
int VSAPI tag_check_context_flags(VSUINT64Param context_flags, VSUINT64Param tag_flags, VSPSZ type_name);

/**
 * Decompose a class name into its outer component and
 * inner class name only.  This is strictly a string function,
 * no file I/O or searching is involved.
 *
 * @param class_name       class name to decompose
 * @param inner_name       (reference) 'inner' class name (class name only)
 * @param outer_name       (reference) 'outer' class name (class_name - inner_name)
 * @param outer_first_only (optional, default 0) make outer name first identifier only
 */
EXTERN_C
void VSAPI tag_split_class_name(VSPSZ class_name, VSHREFVAR inner_name,
                                VSHREFVAR outer_name /*, int outer_first_only=0*/);

/**
 * Determine whether the class name and outer class name should be
 * joined using a package seperator or class seperator and return
 * the resulting string.  This involves searching for the outer
 * class name as a package, if found, then use package string.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param class_name       name of class to join (inner_class)
 * @param outer_class      name of outer class or package to join
 * @param tag_files        (reference, read-only array of strings)
 *                         list of tag files to search
 * @param case_sensitive   1/0 for case-sensitive or case-insensitve search
 * @param allow_anonymous (optional, default false) allow anonymous classes?
 *
 * @return Returns static string if outer_class :: class_name was found in
 *         the context or tag database, otherwise returns '';
 */
EXTERN_C
VSPSZ VSAPI tag_join_class_name(VSPSZ class_name, VSPSZ outer_class,
                                VSHREFVAR tag_files, int case_sensitive
                                /*, int allow_anonymous=0*/);

/**
 * Determine if 'parent_class' is a parent of 'child_class', that is, does
 * 'child_class' derive either directly or transitively from 'parent_class'?
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param parent_class     class to check if it is a parent (base class)
 * @param child_class      class to check if it is derived from parent
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param normalize        attempt to normalize class name or take as-is?
 * @param parent_file      path to file containing the parent class
 * @param visited          Slick-C&reg; hash table of prior results
 * @param depth            depth of recursive search
 *
 * @return 1 if 'child_class' derives from 'search_class', otherwise 0.
 */
EXTERN_C
int VSAPI tag_is_parent_class(VSPSZ parent_class, VSPSZ child_class,
                              VSHREFVAR tag_files, int case_sensitive,
                              int normalize
                              /*, VSPSZ parent_file=NULL, */
                              /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Lookup 'symbol' and see if it could be a typedef symbol.  If so,
 * return 1, otherwise return 0.
 * <p>
 * This function ignores class scope.  Simply put, if 'symbol' is a typedef,
 * anywhere, this function may return true.  Thus, it's should really be used
 * only as an arbiter prior to attempting to match 'symbol' in context as a
 * typedef.  The reason that this function behaves in this was is for speed
 * and simplicity.  Otherwise, it would have to search all parent and outer
 * class scopes, in addition to locals, context and tag files.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           symbol to investigate
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param namespace_name   (optional) namespace to search for typedef in
 * @param visited          Slick-C&reg; hash table of prior results
 * @param depth            depth of recursive search
 *
 * @return 1 if 'symbol' could be a typedef, 0 otherwise, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_check_for_typedef(VSPSZ symbol, 
                                VSHREFVAR tag_files,
                                int case_sensitive 
                                /*, VSPSZ namespace_name */
                                /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Lookup 'symbol' and see if it could be an import. 
 * If so, return 1, otherwise return 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           symbol to investigate
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param namespace_name   (optional) namespace to search for typedef in
 * @param visited          Slick-C&reg; hash table of prior results
 * @param depth            depth of recursive search
 *
 * @return 1 if 'symbol' could be a typedef, 0 otherwise, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_check_for_import(VSPSZ symbol, VSPSZ class_name,
                               VSHREFVAR tag_files, int case_sensitive,
                               VSHREFVAR visited=0, int depth=0);

/**
 * Lookup 'symbol' and see if it could be an enumerated type.
 * If so, return 1, otherwise return 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           symbol to investigate
 * @param class_name       namespace to search for typedef in
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param visited          Slick-C&reg; hash table of prior results
 * @param depth            depth of recursive search
 *
 * @return 1 if 'symbol' could be a typedef, 0 otherwise, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_check_for_enum(VSPSZ symbol, VSPSZ class_name,
                             VSHREFVAR tag_files, int case_sensitive
                             /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Look up 'symbol' and see if it is a simple preprocessing symbol.
 * If so, return the value of symbol in alt_symbol.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           current symbol to look for
 * @param line_no          if found in current context, define must be before 'line'
 * @param tag_files        (reference to _str[]) list of tag files to search
 * @param id_defined_to    (reference) returns value of #define
 * @param arglist          (reference) returns argument list of #define
 * @param visited          Slick-C&reg; hash table of prior results
 * @param depth            depth of recursive search
 *
 * @return the number of matches found, 0 if none found, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_check_for_define(VSPSZ symbol, int line_no,
                               VSHREFVAR tag_files, 
                               VSHREFVAR id_defined_to /*, VSHREFVAR arglist*/);

/**
 * Look up 'symbol' and see if it is a class name.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           current symbol to look for
 * @param outer_class      class that 'symbol' must be in
 * @param case_sensitive   case_sensitive symbol comparison?
 * @param tag_files        (reference to _str[]) tag files to search
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if a match was found, 0 of none found.
 */
EXTERN_C
int VSAPI tag_check_for_class(VSPSZ symbol, VSPSZ outer_class,
                              int case_sensitive, VSHREFVAR tag_files
                              /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Look up 'symbol' and see if it is a template class.
 * If so, return the signature of the template in template_sig.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           current symbol to look for
 * @param outer_class      class that 'symbol' must be in
 * @param case_sensitive   case_sensitive symbol comparison?
 * @param tag_files        (reference to _str[]) tag files to search
 * @param template_sig     (reference) returns signature of template_sig
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if a match was found and sets template_sig, 0 of none found.
 */
EXTERN_C
int VSAPI tag_check_for_template(VSPSZ symbol, VSPSZ outer_class, int case_sensitive,
                                 VSHREFVAR tag_files, VSHREFVAR template_sig
                                 /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Look up 'symbol' and see if it is a package, namespace, module or unit.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           current symbol to look for
 * @param tag_files        (reference to _str[]) list of tag files to search
 * @param exact_match      look for exact match rather than prefix match
 * @param case_sensitive   case sensitive comparison?
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return &gt;0 if 'symbol' or prefix of matches package, otherwise returns 0.
 *         A value of 1 indicates the item was found in a tag file, a value of
 *         greater than 1 indicates that that item was found in the context.
 */
EXTERN_C
int VSAPI tag_check_for_package(VSPSZ symbol, VSHREFVAR tag_files,
                                int exact_match, int case_sensitive
                                /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Check if the given class is in the same package as the other class.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param class1           first class name, qualified
 * @param class2           second class name, qualified
 * @param case_sensitive   case sensitive comparison for package names?
 *
 * @return true of so, false otherwise.
 */
EXTERN_C
int VSAPI tag_is_same_package(VSPSZ class1, VSPSZ class2, int case_sensitive);

/**
 * List the global symbols of the given type
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param tag_files        (reference to _str[]) tag files to search
 * @param type_id          first type id (see SE_TAG_TYPE_*, above)
 *                         if (type_id&lt;0), returns tags with ID>SE_TAG_TYPE_LASTID
 * @param mask             flag mask (see SE_TAG_FLAG_*)
 * @param nonzero          if 1, succeed if mask & tag.flags != 0
 *                         if 0, succeed if mask & tag.flags == 0
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return nothing
 */
EXTERN_C
int VSAPI tag_list_globals_of_type(int treewid, int tree_index, VSHREFVAR tag_files,
                                   int type_id, int mask, int nonzero,
                                   VSHREFVAR vnum_matches, int max_matches
                                   /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * List the packages matching the given prefix expression.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return nothing
 */
EXTERN_C
int VSAPI tag_list_context_packages(int treewid, int tree_index,
                                    VSPSZ prefix, VSHREFVAR tag_files,
                                    VSHREFVAR vnum_matches, int max_matches,
                                    int exact_match, int case_sensitive
                                    /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * List any symbols, reguardless of context or scope (excluding locals)
 * matching the given prefix expression.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return nothing.
 */
EXTERN_C
int VSAPI tag_list_any_symbols(int treewid,int tree_index, 
                               VSPSZ prefix, VSHREFVAR tag_files, 
                               VSUINT64Param pushtag_flags,
                               VSUINT64Param context_flags,
                               VSHREFVAR vnum_matches,int max_matches,
                               int exact_match,int case_sensitive
                               /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * List the symbols found in files having the given 'base' filename
 * and passing the given pushtag and context flags.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param search_file_name (optional) file name to search for tags in
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return nothing.
 */
EXTERN_C
int VSAPI tag_list_in_file(int treewid, int tree_index, 
                           VSPSZ prefix,
                           VSHREFVAR tag_files, 
                           VSPSZ search_file_name,
                           VSUINT64Param pushtag_flags, 
                           VSUINT64Param context_flags,
                           VSHREFVAR vnum_matches, int max_matches,
                           int exact_match, int case_sensitive
                           /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * List the global symbols visible in the given list of tag files
 * matching the given tag filters and context flags.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param check_context    check for symbols in the current context?
 * @param tag_files        (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return nothing.
 */
EXTERN_C
int VSAPI tag_list_context_globals(int treewid, int tree_index, 
                                   VSPSZ prefix,
                                   int check_context, 
                                   VSHREFVAR tag_files,
                                   VSUINT64Param pushtag_flags, 
                                   VSUINT64Param context_flags,
                                   VSHREFVAR vnum_matches, int max_matches,
                                   int exact_match, int case_sensitive
                                   /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * List the symbols imported into this context
 * matching the given tag filters and context flags.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return the number of import statements in the current context.
 */
EXTERN_C
int VSAPI tag_list_context_imports(int treewid, int tree_index,
                                   VSPSZ prefix, 
                                   VSHREFVAR tag_files,
                                   VSUINT64Param pushtag_flags, 
                                   VSUINT64Param context_flags,
                                   VSHREFVAR vnum_matches, int max_matches,
                                   int exact_match, int case_sensitive
                                   /* VSHREFVAR visited=0, int depth=0 */ );

/**
 * Attempt to locate the given symbol in the given class by searching
 * local variables.  Recursively looks for symbols in enumerated
 * types and anonymous unions (designated by having *both* the anonymous
 * and 'maybe_var' tag flags).
 * <p>
 * Look at num_matches to see if any matches were found.  Generally
 * if (num_matches &gt;= max_matches) there may be more matches, but
 * the search terminated early.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param tag_files        symbol prefix to match
 * @param prefix           name of class to search for matches
 * @param search_class     (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param friend_list     (optional) List of friends to the current context
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class 'search_class_name' is found,
 *         othewise returns 0, indicating that no matches were found.
 */
EXTERN_C
int VSAPI tag_list_class_locals(int treewid, int tree_index, 
                                VSHREFVAR tag_files,
                                VSPSZ prefix, VSPSZ search_class,
                                VSUINT64Param pushtag_flags, 
                                VSUINT64Param context_flags,
                                VSHREFVAR vnum_matches, int max_matches,
                                int exact_match, int case_sensitive
                                /* VSPSZ friend_list=0, */
                                /* VSHREFVAR visited=0, int depth=0 */
                                );

/**
 * Attempt to locate the given symbol in the given class by searching
 * the current context.  Recursively looks for symbols in enumerated
 * types and anonymous unions (designated by having *both* the anonymous
 * and 'maybe_var' tag flags).
 * <p>
 * Look at num_matches to see if any matches were found.  Generally
 * if (num_matches &gt;= max_matches) there may be more matches, but
 * the search terminated early.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param tag_files        symbol prefix to match
 * @param prefix           name of class to search for matches
 * @param search_class     (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param friend_list     (optional) List of friends to the current context
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class 'search_class_name' is found,
 *         othewise returns 0, indicating that no matches were found.
 */
EXTERN_C
int VSAPI tag_list_class_context(int treewid, int tree_index, 
                                 VSHREFVAR tag_files,
                                 VSPSZ prefix, VSPSZ search_class,
                                 VSUINT64Param pushtag_flags, 
                                 VSUINT64Param context_flags,
                                 VSHREFVAR vnum_matches, int max_matches,
                                 int exact_match, int case_sensitive
                                 /* VSPSZ friend_list=0, */
                                 /* VSHREFVAR visited=0, int depth=0 */
                                 );

/**
 * Attempt to locate the given symbol in the given class by searching
 * the given tag files.  Recursively looks for symbols in enumerated
 * types and anonymous unions (designated by having *both* the anonymous
 * and 'maybe_var' tag flags).
 * <p>
 * Look at num_matches to see if any matches were found.  Generally
 * if (num_matches &gt;= max_matches) there may be more matches, but
 * the search terminated early.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param tag_files        symbol prefix to match
 * @param prefix           name of class to search for matches
 * @param search_class     (reference to _str[]) tag files to search
 * @param pushtag_flags    SE_TAG_FILTER_*, tag filter flags
 * @param context_flags    SE_TAG_CONTEXT_*, tag context filter flags
 * @param vnum_matches     (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) Slick-C&reg; hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class 'search_class_name' is found,
 *         othewise returns 0, indicating that no matches were found.
 */
EXTERN_C
int VSAPI tag_list_class_tags(int treewid, int tree_index, 
                              VSHREFVAR tag_files,
                              VSPSZ prefix, VSPSZ search_class,
                              VSUINT64Param pushtag_flags, VSUINT64Param context_flags,
                              VSHREFVAR vnum_matches, int max_matches,
                              int exact_match, int case_sensitive
                              /* VSHREVAR visited=0, int depth=0*/ );


/**
 * For each item in 'class_parents', normalize the class and place it in
 * 'normal_parents', along with the tag type, placed in 'normal_types'.
 *
 * @param class_parents   list of class names, seperated by semicolons
 * @param cur_class_name  class context in which to normalize class name
 * @param file_name       source file where reference to class name is
 * @param tag_files       list of tag files to search
 * @param allow_locals    allow local classes in list
 * @param case_sensitive  case sensitive tag search?
 * @param normal_parents  (output) list of normalized class names
 * @param normal_types    (output) list of tag types found for normalized class names
 * @param normal_files    (output) list of tag files parent classes are found in
 * @param depth           (optional) depth of recursive search
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_normalize_classes(VSPSZ class_parents,
                      VSPSZ cur_class_name, VSPSZ file_name,
                      VSHREFVAR tag_files, int allow_locals, int case_sensitive,
                      VSHREFVAR normal_parents, VSHREFVAR normal_types, VSHREFVAR normal_files
                      /*, int depth=0, VSHREFVAR visited=0 */);

/**
 * Compare the two class names, ignore class and package separators.
 * 
 * @param c1               first class name
 * @param c2               second class name
 * @param case_sensitive   compare names using a case sensitive algorithm?
 * 
 * @return Returns &lt;0 if the 'c1' is less than 'c2', 0 if they match,
 *         and >0 if 'c1' is greater than 'c2', much like strcmp().
 */
EXTERN_C int VSAPI
tag_compare_classes(VSPSZ c1, VSPSZ c2, int case_sensitive=1);

/**
 * Attempt to locate the given symbol in the given class by searching
 * first locals, then the current file, then tag files, looking strictly
 * for the class definition, not just class members.  Recursively
 * looks for symbols in inherited classes and resolves items in
 * enumerated types to the correct class scope (since enums do not form
 * a namespace).  The order of searching parent classes is depth-first,
 * preorder (root node searched before children).
 * <p>
 * Look at num_matches to see if any matches were found.  Generally
 * if (num_matches &gt;= max_matches) there may be more matches, but
 * the search terminated early.  Returns 1 if the definition of the given
 * class 'search_class' is found, othewise returns 0, indicating
 * that no matches were found.
 * <p>
 * The current object must be an editor control or the current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param treewid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (treewid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param pushtag_flags   SE_TAG_FILTER_*, tag filter flags
 * @param context_flags   SE_TAG_CONTEXT_*, tag context filter flags
 * @param num_matches     (reference) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param depth           Recursive call depth, bails out at 32
 * @param template_args   (optional) Slick-C&reg; hash table of template arguments
 * @param friend_list     (optional) List of friends to the current context
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 1 if the definition of the symbol is found, 0 otherwise, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_list_in_class(VSPSZ prefix, VSPSZ search_class,
                  int treewid, int tree_index, VSHREFVAR tag_files,
                  VSHREFVAR num_matches, int max_matches,
                  VSINT64Param pushtag_flags, VSINT64Param context_flags,
                  int exact_match, int case_sensitive
                  /* VSHREFVAR template_args=0, VSPSZ friend_list=0, */
                  /* VSHREFVAR visited=0, int depth=0 */ );

/**
 * Qualify the given class symbol by searching for symbols with
 * its name in the current context/scope.  This is used to resolve
 * partial class names, often found in class inheritance specifications.
 * The current object must be an editor control or current buffer.
 *
 * @param qualified_name  (output) "qualified" symbol name
 * @param search_name     name of symbol to search for
 * @param context_class   current class context (class name)
 * @param context_file    current file name
 * @param tag_files       list of tag files to search
 * @param case_sensitive  case sensitive tag search?
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return qualified name if successful, 'search_name' on error.
 */
EXTERN_C int VSAPI
tag_qualify_symbol_name(VSHREFVAR qualified_name,
                        VSPSZ search_name, VSPSZ context_class,
                        VSPSZ context_file, VSHREFVAR tag_files,
                        int case_sensitive
                        /* VSHREFVAR visited=0, int depth=0 */ );

/**
 * Determine the name of the current class or package context.
 * The current object needs to be an editor control.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param cur_tag_name    name of the current tag in context
 * @param cur_flags       bitset of SE_TAG_FLAG_* for the current tag
 * @param cur_type_name   type (SE_TAG_TYPE_*) of the current tag
 * @param cur_type_id     type ID (SE_TAG_TYPE_*) of the current tag
 * @param cur_context     class name representing current context
 * @param cur_class       cur_context minus the package name
 * @param cur_package     only package name for the current context
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 if no context, context ID >0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_get_current_context(VSHREFVAR cur_tag_name,  VSHREFVAR cur_flags,
                        VSHREFVAR cur_type_name, VSHREFVAR cur_type_id,
                        VSHREFVAR cur_context,   VSHREFVAR cur_class,
                        VSHREFVAR cur_package
                        /*, VSHREFVAR visited=0, int depth=0 */);

/**
 * Match the given symbol based on the current context information.
 * Order of searching is:
 * <OL>
 * <LI> local variables in current function
 * <LI> members of current class, including inherited members
 * <LI> globals found in the current file
 * <LI> globals imported explicitely from current file
 * <LI> globals, (not static variables), found in other files
 * <LI> any symbol found in this file
 * <LI> any symbol found in any tag file
 * </OL>
 * Failing that, it repeats steps (1-6) with pushtag_flags set to -1,
 * thus disabling any filtering, unless 'strict' is true.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param treewid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (treewid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param num_matches     (reference) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param pushtag_flags   SE_TAG_FILTER_*, tag filter flags
 * @param context_flags   SE_TAG_CONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param strict          strict match, or allow any match?
 * @param find_parents    find parents of the given class?
 * @param find_all        find all instances, for each level of scope
 * @param search_file     file to search for matches in (for imports)
 *
 * @return 0 on success, &lt;0 on error.
 * 
 * @deprecated
 * @see tag_list_symbols_in_context
 */
EXTERN_C VSDEPRECATED int VSAPI
tag_match_symbol_in_context(VSPSZ prefix, VSPSZ search_class,
                            int treewid, int tree_index, 
                            VSHREFVAR tag_files,
                            VSHREFVAR num_matches,int max_matches,
                            VSUINT64Param pushtag_flags, 
                            VSUINT64Param context_flags,
                            int exact_match, int case_sensitive, 
                            int strict, int find_parents, int find_all
                            /*, VSPSZ search_file = NULL */ );

/**
 * Match the given symbol based on the current context information.
 * Order of searching is:
 * <OL>
 * <LI> local variables in current function
 * <LI> members of current class, including inherited members
 * <LI> globals found in the current file
 * <LI> globals imported explicitely from current file
 * <LI> globals, (not static variables), found in other files
 * <LI> any symbol found in this file
 * <LI> any symbol found in any tag file
 * </OL>
 * Failing that, it repeats steps (1-6) with pushtag_flags set to -1,
 * thus disabling any filtering, unless 'strict' is true.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param treewid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (treewid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param search_file     file to search for matches in (for imports)
 * @param num_matches     (reference) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param pushtag_flags   SE_TAG_FILTER_*, tag filter flags
 * @param context_flags   SE_TAG_CONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param visited         Slick-C&reg; hash table of prior results
 * @param depth           depth of recursive search
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_list_symbols_in_context(VSPSZ prefix, VSPSZ search_class,
                            int treewid, int tree_index, 
                            VSHREFVAR tag_files, VSPSZ search_file,
                            VSHREFVAR num_matches,int max_matches,
                            VSUINT64Param pushtag_flags, 
                            VSUINT64Param context_flags,
                            int exact_match, int case_sensitive,
                            VSHREFVAR visited=0, int depth=0);

/**
 * @return  Returns next tag name which is a prefix match of <i>name</i>.
 * <i>find_first</i> must be non-zero to initialize matching.
 * Returns '' when no more matches are found.
 * 
 * @param name          tag name to search for
 * @param find_first    'true' to find first, 'false' to find next
 */
EXTERN_C
VSPSZ VSAPI tag_match(VSPSZ name, int find_first /*, VSPSZ lang=null*/);

/**
 * Match symbols in all tag files against the given member and class filters.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param tree_wid        Window ID of the tree control
 * @param tree_index      Tree index to insert items under
 * @param progress_wid    Window id of progress label
 * @param member_filter   Prefix or regular expression for symbols
 * @param class_filter    Regex or prefix for class names
 * @param tag_files       list of tag files to search
 * @param filter_flags    Symbol filter flags (SE_TAG_FILTER_*)
 * @param num_matches     (reference) number of matches found
 * @param max_matches     maximum number of matches to find
 * @param regex_match     perform regular expression match?
 * @param exact_match     exact match or prefix match?
 * @param case_sensitive  Case sensitive match or case-insensitive?
 *
 * @return Returns 0 on success, 1 if list was truncated,
 *         &lt;0 on error.
 * @see tag_match
 * @since 5.0a
 */
EXTERN_C int VSAPI
tag_pushtag_match(int tree_wid, int tree_index, int progress_wid,
                  VSPSZ member_filter, VSPSZ class_filter,
                  VSHREFVAR tag_files, 
                  VSUINT64Param filter_flags,
                  VSHREFVAR num_matches, int max_matches,
                  int regex_match=0, 
                  int exact_match=0, 
                  int case_sensitive=0);

/**
 * Find all tags in the given tag databases matching
 * the given tag name, and possibly class or type
 * specification.  Places matches in taglist and
 * filelist, which are parallel arrays.
 *
 * @param taglist         List of tag information, composed
 * @param filelist        List of corresponding filenames
 * @param proc_name       Composed tag name to search for
 * @param tag_files       List of tag files to search
 * @param max_matches     Maximum number of symbols to find
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 *
 * @return 0 on succes, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_list_duplicate_tags(VSHREFVAR taglist, VSHREFVAR filelist,
                        VSPSZ proc_name, VSHREFVAR tag_files
                        /*, int max_matches*/
                        /*, int filter_flags=SE_TAG_FILTER_ANYTHING*/);

/**
 * Find all tags in the given tag databases matching
 * the given tag name, and possibly class or type
 * specification.  Places matches in the current match set.
 * <p> 
 * For synchronization, threads should perform a tag_lock_matches(true) 
 * prior to invoking this function.
 *
 * @param proc_name       Composed tag name to search for
 * @param tag_files       List of tag files to search
 * @param max_matches     Maximum number of symbols to find 
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 *
 * @return 0 on succes, &lt;0 on error.
 */
EXTERN_C int VSAPI
tag_list_duplicate_matches(VSPSZ proc_name, 
                           VSHREFVAR tag_files
                           /*, int max_matches*/
                           /*, int filter_flags=SE_TAG_FILTER_ANYTHING*/);

/**
 * Remove duplicate symbols from the set of tags in a match set.
 * 
 * @param pszMatchExactSymbolName   (optional) look for exact matches to this symbol only 
 * @param pszCurrentFileName        (optional) current file name
 * @param pszCurrentFileName        (optional) current language mode
 * @param removeDuplicatesOptions   set of bit flags of options for what kinds of duplicates to remove. 
 *        <ul>
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_PROTOTYPES} - *  
 *            Remove forward declarations of functions if the corresponding function 
 *            definition is also in the match set.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS} -              
 *            Remove forward or extern declarations of global and namespace level 
 *            variables if the actual variable definition is also in the match set.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_CLASSES} -              
 *            Remove forward declarations of classes, structs, and 
 *            interfaces if the actual definition is in the match set.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_IMPORTS} -
 *            Remove all import statements from the match set.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_SYMBOLS} -
 *            Remove all duplicate symbol definitions.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE} -
 *            Remove tag matches that are found in the current symbol context.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES} -              
 *            [not implemented here] 
 *            Attempt to filter out function signatures that do not match.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES} -              
 *            Filter out anonymous class names in preference of typedef.
 *            for cases like typedef struct { ... } name_t;
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_TAG_USES} -              
 *            Filter out tags of type 'taguse'.  For cases of mixed language
 *            Android projects, which have duplicate symbol names in the XML and Java.
 *        <li>{@link VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS} -              
 *            Filter out tags of type 'annotation' so that annotations
 *            do not conflict with other symbols with the same name.
 *        </ul>
 * 
 */
EXTERN_C
void VSAPI tag_remove_duplicate_symbols_from_matches(VSPSZ pszMatchExactSymbolName,
                                                     VSPSZ pszCurrentFileName,
                                                     VSPSZ pszCurrentLangId,
                                                     int removeDuplicatesOptions);

/**
 * Filter out the symbols in the current match set that do not
 * match the given set of filters.  If none of the symbols in the
 * match set match the filters, do no filtering.
 * 
 * @param filter_flags  bitset of SE_TAG_FILTER_*
 * @param filter_all    if 'true', allow all the matches to be filtered out
 */
EXTERN_C 
void VSAPI tag_filter_symbols_from_matches(int filter_flags, int filter_all=0);


/**
 * Update the tags in the current context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_update_context();

/**
 * Update the locals in the current function or set
 * of nested functions.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param find_all Find all locals, or just up to cursor position? 
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_update_locals(int find_all);

/**
 * Update the locals in the current function or set of nested functions.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locals in
 * @param cur_seekpos      Current seek position to find local variables at 
 * @param update_flags     bitset of VS_UPDATEFLAG_*, option to find all locals, 
 *                         or just up to cursor position? 
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_parse_and_update_locals(int start_seekpos, int end_seekpos, int context_id, int cur_seekpos, int update_flags);

/**
 * Insert the start and end seek positions of an embedded context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param start_seekpos start seek position of embedded context
 * @param end_seekpos   end seek position of embedded context
 *
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI
tag_insert_embedded(int start_seekpos, int end_seekpos);

/**
 * Clear the list of embedded context information.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
EXTERN_C void VSAPI
tag_clear_embedded();

/**
 * Retrieve the embedded context information for
 * the given position 'i' (first is 0).
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param i             index of embedded context to retrieve
 * @param start_seekpos (reference) set to start seek position for embedded context
 * @param end_seekpos   (reference) set to end seekposition for embedded context
 *
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI
tag_get_embedded(int i, VSHREFVAR start_seekpos, VSHREFVAR end_seekpos);

/**
 * Return the number of embedded contexts in the current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 */
EXTERN_C int VSAPI
tag_get_num_of_embedded();

EXTERN_C void VSAPI
tag_context_fix_vb_ifs( );

EXTERN_C void VSAPI
tag_context_fix_vb_trys( );


/**
 * Disect the next argument (starting at 'arg_pos') from the
 * given parameter list (params).  Place the result in 'argument'.
 * This is designed to handle both C/C++ style, comma separated argument
 * lists, and Pascal/Ada semicolon separated argument lists.
 * <p>
 * If you do not know the number of bytes to allocate to 'argument',
 * call this with 'argument' as NULL, and calculate ('arg_pos' - 'orig_pos' + 1).
 * 
 * @param params        complete parameter list to parse
 * @param arg_pos       current position in argument list
 *                      use 0 to find first argument
 * @param arg_string    [output] set to the next argument in the argument list
 * @param ext           current file extension
 * 
 * @return Returns the position where the argument begins in 'params'.
 *         Note, this may differ from the original value of 'arg_pos'
 *         if there are leading spaces.  Returns STRING_NOT_FOUND_RC 
 *         and sets 'argument' to the empty string if there are no more
 *         arguments in the parameter list.
 */
EXTERN_C int VSAPI
tag_get_next_argument(VSPSZ params, VSHREFVAR arg_pos,
                      VSHREFVAR arg_string /*,VSPSZ ext=NULL*/);

/**
 * Does the current language match or
 * inherit from the given language?
 * <p>
 * If 'lang' is not specified, the current object
 * must be an editor control.
 *
 * @param parent  language ID to compare to
 * @param lang    current language ID 
 *                (default={@link p_language_id})
 * 
 * @return 'true' if the extension matches, 'false' otherwise.
 * @deprecated use {@link vsLanguageInheritsFrom()} 
 */
EXTERN_C VSDEPRECATED int VSAPI
tag_ext_inherits_from(VSPSZ parent, VSPSZ lang/*=NULL*/);


/**
 * Find all the classes which are friendly towards the given tag
 * name or it's class or outer classes.
 * 
 * @param tag_name      tag to find friends to
 * @param class_name    class to find friends to
 * @param tag_files     List of tag files to search
 * @param friend_list   (reference) set to list of friends,
 *                      separated by {@link VS_TAGSEPARATOR_parents}
 * 
 * @return 0 on success, &lt;0 on error.
 *         Having no friends is considered as a success.
 * 
 * @see tag_check_friend_relationship
 * @see tag_list_in_class
 */
EXTERN_C int VSAPI
tag_find_friends_to_tag(VSPSZ tag_name, VSPSZ class_name,
                        VSHREFVAR tag_files,
                        VSHREFVAR friend_list);

/**
 * Find all the friends of the given class in the current context
 * and tag files.
 * 
 * @param class_name    class to find friends of
 * @param tag_files     List of tag files to search
 * @param friend_list   (reference) set to list of friends,
 *                      separated by {@link VS_TAGSEPARATOR_parents}
 * 
 * @return 0 on success, &lt;0 on error.
 *         Having no friends is considered as a success.
 * 
 * @see tag_check_friend_relationship
 * @see tag_list_in_class
 */
EXTERN_C int VSAPI
tag_find_friends_of_class(VSPSZ class_name,
                          VSHREFVAR tag_files,
                          VSHREFVAR friend_list);

/**
 * @return
 * Returns true if the given given class is among the friends on the
 * given friend list.  Otherwise it returns false.  Since this language
 * feature is specific to C++, the check is always case sensitive.
 * 
 * @param class_name    class which tag is coming from
 * @param friend_list   list of classes that are friendly to our context
 * 
 * @see tag_find_friends_of_class
 * @see tag_find_friends_to_tag
 * @see tag_list_in_class
 */
EXTERN_C int VSAPI
tag_check_friend_relationship(VSPSZ class_name, VSPSZ friend_list);

/**
 * @deprecated 
 * This command is no longer supported.  Use tag_dump_matches() instead. 
 */
EXTERN_C VSDEPRECATED void VSAPI
tag_dump_debug_info(void);


////////////////////////////////////////
// Utility routines for SlickEdit Tools

/**
 * Return the number of entries in glocations. If everything has been
 * done correctly, this should tell you the # of references that were found
 * to a given symbol.
 */
EXTERN_C int VSAPI
tag_locations_count();

/**
 * Returns a vsTagLocation structure from glocations at the given index
 *
 * @param index Entry # to retrieve.
 *
 * @return NULL on failure
 */
EXTERN_C struct vsTagLocation* VSAPI
tag_locations_entry(int index);

/**
 * Clear out glocations
 */
EXTERN_C void VSAPI
tag_locations_clear();

/**
 * Add a new vsTagLocation to glocations.
 *
 * @param entry New vsTagLocation to append to glocations
 */
EXTERN_C void VSAPI
tag_locations_add(const struct vsTagLocation &entry);

/** 
 * xmloutlineview_profiles are cached so the Defs tool window 
 * can be filled in faster. If one of this profiles is modified, 
 * this function must be called. 
 */
EXTERN_C
void VSAPI tag_recache_xmloutlineview_profiles();


/**
 * Set the maximum number of current context, statements, local variables, 
 * and search result match sets to cache.
 * 
 * @param num_context_jobs    Maximum number of items to store in cache. 
 *  
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_set_context_tagging_cache_size(int num_context_jobs);

/** 
 * @return 
 * Return the maximum number of current context, statements, local variables, 
 * and search result match sets to cache.
 */
EXTERN_C int VSAPI tag_get_context_tagging_cache_size();

/**
 * Clear the context tagging class and package name resolution caches, 
 * and optionally reset the maximum number of items each one can cache. 
 * 
 * @param max_cache_size    (optional, ignored if 0) 
 *                          sets maximum number of items for cache
 */
EXTERN_C void VSAPI tag_clear_class_name_caches(int max_cache_size=0);


// TAGS_CONTEXT_H
