////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef TAGS_DB_H
#define TAGS_DB_H

#include "vsdecl.h"


//////////////////////////////////////////////////////////////////////
// "C" style API for creating and accessing BTREE tag database.
//

//////////////////////////////////////////////////////////////////////
// Flags associated with tags, denoting access restrictions and
// and other attributes of class members (proc's, proto's, and var's)
//    NOT virtual and NOT static implies normal class method
//    NOT protected and NOT private implies public
//    NOT const implies normal read/write access
//    NOT volatile implies normal optimizations are safe
//    NOT template implies normal class definition
//
#define VS_TAGFLAG_virtual      0x00000001  // virtual function (instance)
#define VS_TAGFLAG_static       0x00000002  // static method / member (class)
#define VS_TAGFLAG_access       0x0000000C  // access flags (public/protected/private/package)
#define VS_TAGFLAG_public       0x00000000  // public access (test equality with flags&access)
#define VS_TAGFLAG_protected    0x00000004  // protected access
#define VS_TAGFLAG_private      0x00000008  // private access
#define VS_TAGFLAG_package      0x0000000C  // package access (for Java)
#define VS_TAGFLAG_const        0x00000010  // const
#define VS_TAGFLAG_final        0x00000020  // final
#define VS_TAGFLAG_abstract     0x00000040  // abstract/deferred method
#define VS_TAGFLAG_inline       0x00000080  // inline / out-of-line method
#define VS_TAGFLAG_operator     0x00000100  // overloaded operator
#define VS_TAGFLAG_constructor  0x00000200  // class constructor
#define VS_TAGFLAG_volatile     0x00000400  // volatile method
#define VS_TAGFLAG_template     0x00000800  // template class
#define VS_TAGFLAG_inclass      0x00001000  // part of class interface?
#define VS_TAGFLAG_destructor   0x00002000  // class destructor
#define VS_TAGFLAG_const_destr  0x00002200  // class constructor or destructor
#define VS_TAGFLAG_synchronized 0x00004000  // synchronized (thread safe)
#define VS_TAGFLAG_transient    0x00008000  // transient / persistent data
#define VS_TAGFLAG_native       0x00010000  // Java native method?
#define VS_TAGFLAG_macro        0x00020000  // Tag was part of macro expansion?
#define VS_TAGFLAG_extern       0x00040000  // "extern" C prototype (not local)
#define VS_TAGFLAG_maybe_var    0x00080000  // Prototype which could be a variable.
                                            // Anonymous union.  Unnamed structs.
#define VS_TAGFLAG_anonymous    0x00100000  // Anonymous structure or class
#define VS_TAGFLAG_mutable      0x00200000  // mutable C++ class member
#define VS_TAGFLAG_extern_macro 0x00400000  // external macro (COBOL copy file)
#define VS_TAGFLAG_linkage      0x00800000  // 01 level var in COBOL linkage section
#define VS_TAGFLAG_partial      0x01000000  // For C# partial class, struct, or interface
#define VS_TAGFLAG_ignore       0x02000000  // Tagging should ignore this tag
#define VS_TAGFLAG_forward      0x04000000  // Forward class/interface/struct/union declaration
#define VS_TAGFLAG_opaque       0x08000000  // Opaque enumerated type (unlike C/C++ enum)
#define VS_TAGFLAG_restartable  0x10000000  // Can tagging be restarted at this symbol?

//////////////////////////////////////////////////////////////////////
// Flags passed to tag to extract specific information about the
// current tag, using tag_get_detail(), below
//
#define VS_TAGDETAIL_max 256

#define VS_TAGDETAIL_current     (VS_TAGDETAIL_max*0)
#define VS_TAGDETAIL_context     (VS_TAGDETAIL_max*1)
#define VS_TAGDETAIL_local       (VS_TAGDETAIL_max*2)
#define VS_TAGDETAIL_match       (VS_TAGDETAIL_max*3)

#define VS_TAGDETAIL_name           0  // (string) tag name
#define VS_TAGDETAIL_type           1  // (string) tag type
#define VS_TAGDETAIL_type_id        2  // (int) unique id for tag type (VS_TAGTYPE_*)
#define VS_TAGDETAIL_file_name      3  // (string) full path of file the tag is located in
#define VS_TAGDETAIL_file_date      4  // (string) modification data of file when tagged
#define VS_TAGDETAIL_file_line      5  // (int) line number of tag within file
#define VS_TAGDETAIL_file_id        6  // (int) unique id for file the tag is located in
#define VS_TAGDETAIL_class_simple   7  // (string) name of class the tag is present in
#define VS_TAGDETAIL_class_name     8  // (string) name of class with outer classes
#define VS_TAGDETAIL_class_package  9  // (string) package/module/namespace tag belongs to
#define VS_TAGDETAIL_package        9  // (string) package/module/namespace tag belongs to
#define VS_TAGDETAIL_class_id      10  // (int) unique id for class tag belongs to
#define VS_TAGDETAIL_flags         11  // (int) tag flags (see VS_TAGFLAG_* above)
#define VS_TAGDETAIL_return        12  // (string) return type for functions, type of variables
#define VS_TAGDETAIL_arguments     13  // (string) function arguments
#define VS_TAGDETAIL_tagseekloc    14  // (int) PRIVATE
#define VS_TAGDETAIL_fileseekloc   15  // (int) PRIVATE
#define VS_TAGDETAIL_num_tags      17  // (int) number of tags/instances in database
#define VS_TAGDETAIL_num_classes   18  // (int) number of classes in database
#define VS_TAGDETAIL_num_files     19  // (int) number of files in database
#define VS_TAGDETAIL_num_types     20  // (int) number of types in database
#define VS_TAGDETAIL_num_refs      21  // (int) number of references/occurrences in database
#define VS_TAGDETAIL_throws        22  // (string) exceptions thrown by function
#define VS_TAGDETAIL_included_by   23  // (string) full path of parent source file
#define VS_TAGDETAIL_return_only   24  // (string) return type, no default args
#define VS_TAGDETAIL_return_value  25  // (string) default value for variable
#define VS_TAGDETAIL_file_ext      26  // (string) p_LangId property for file
#define VS_TAGDETAIL_language_id   26  // (string) p_LangId property for file
#define VS_TAGDETAIL_context_id    27  // (int) returns same result as tag_current_context()
#define VS_TAGDETAIL_local_id      28  // (int) returns same result as tag_current_local
#define VS_TAGDETAIL_current_file  29  // (int) returns name of file in current context
#define VS_TAGDETAIL_signature     30  // (string) returns the signature
#define VS_TAGDETAIL_class_parents 31  // (string) returns the class parents
#define VS_TAGDETAIL_template_args 32  // (string) returns the template signature
#define VS_TAGDETAIL_LASTID        33  // last tag detail id (plus 1)

#define VS_TAGDETAIL_context_tag_file      (VS_TAGDETAIL_context+0)
#define VS_TAGDETAIL_context_name          (VS_TAGDETAIL_context+1)
#define VS_TAGDETAIL_context_type          (VS_TAGDETAIL_context+2)
#define VS_TAGDETAIL_context_file          (VS_TAGDETAIL_context+3)
#define VS_TAGDETAIL_context_line          (VS_TAGDETAIL_context+4)
#define VS_TAGDETAIL_context_start_linenum (VS_TAGDETAIL_context+4)
#define VS_TAGDETAIL_context_start_seekpos (VS_TAGDETAIL_context+5)
#define VS_TAGDETAIL_context_scope_linenum (VS_TAGDETAIL_context+6)
#define VS_TAGDETAIL_context_scope_seekpos (VS_TAGDETAIL_context+7)
#define VS_TAGDETAIL_context_end_linenum   (VS_TAGDETAIL_context+8)
#define VS_TAGDETAIL_context_end_seekpos   (VS_TAGDETAIL_context+9)
#define VS_TAGDETAIL_context_class         (VS_TAGDETAIL_context+10)
#define VS_TAGDETAIL_context_flags         (VS_TAGDETAIL_context+11)
#define VS_TAGDETAIL_context_args          (VS_TAGDETAIL_context+12)
#define VS_TAGDETAIL_context_return        (VS_TAGDETAIL_context+13)
#define VS_TAGDETAIL_context_outer         (VS_TAGDETAIL_context+14)
#define VS_TAGDETAIL_context_parents       (VS_TAGDETAIL_context+15)
#define VS_TAGDETAIL_context_throws        (VS_TAGDETAIL_context+16)
#define VS_TAGDETAIL_context_included_by   (VS_TAGDETAIL_context+17)
#define VS_TAGDETAIL_context_return_only   (VS_TAGDETAIL_context+18)
#define VS_TAGDETAIL_context_return_value  (VS_TAGDETAIL_context+19)
#define VS_TAGDETAIL_context_template_args (VS_TAGDETAIL_context+20)
#define VS_TAGDETAIL_context_name_linenum  (VS_TAGDETAIL_context+21)
#define VS_TAGDETAIL_context_name_seekpos  (VS_TAGDETAIL_context+22)

#define VS_TAGDETAIL_local_tag_file        (VS_TAGDETAIL_local+0)
#define VS_TAGDETAIL_local_name            (VS_TAGDETAIL_local+1)
#define VS_TAGDETAIL_local_type            (VS_TAGDETAIL_local+2)
#define VS_TAGDETAIL_local_file            (VS_TAGDETAIL_local+3)
#define VS_TAGDETAIL_local_line            (VS_TAGDETAIL_local+4)
#define VS_TAGDETAIL_local_start_linenum   (VS_TAGDETAIL_local+4)
#define VS_TAGDETAIL_local_start_seekpos   (VS_TAGDETAIL_local+5)
#define VS_TAGDETAIL_local_scope_linenum   (VS_TAGDETAIL_local+6)
#define VS_TAGDETAIL_local_scope_seekpos   (VS_TAGDETAIL_local+7)
#define VS_TAGDETAIL_local_end_linenum     (VS_TAGDETAIL_local+8)
#define VS_TAGDETAIL_local_end_seekpos     (VS_TAGDETAIL_local+9)
#define VS_TAGDETAIL_local_class           (VS_TAGDETAIL_local+10)
#define VS_TAGDETAIL_local_flags           (VS_TAGDETAIL_local+11)
#define VS_TAGDETAIL_local_args            (VS_TAGDETAIL_local+12)
#define VS_TAGDETAIL_local_return          (VS_TAGDETAIL_local+13)
#define VS_TAGDETAIL_local_outer           (VS_TAGDETAIL_local+14)
#define VS_TAGDETAIL_local_parents         (VS_TAGDETAIL_local+15)
#define VS_TAGDETAIL_local_throws          (VS_TAGDETAIL_local+16)
#define VS_TAGDETAIL_local_included_by     (VS_TAGDETAIL_local+17)
#define VS_TAGDETAIL_local_return_only     (VS_TAGDETAIL_local+18)
#define VS_TAGDETAIL_local_return_value    (VS_TAGDETAIL_local+19)
#define VS_TAGDETAIL_local_template_args   (VS_TAGDETAIL_local+20)
#define VS_TAGDETAIL_local_name_linenum    (VS_TAGDETAIL_local+21)
#define VS_TAGDETAIL_local_name_seekpos    (VS_TAGDETAIL_local+22)

#define VS_TAGDETAIL_match_tag_file        (VS_TAGDETAIL_match+0)
#define VS_TAGDETAIL_match_name            (VS_TAGDETAIL_match+1)
#define VS_TAGDETAIL_match_type            (VS_TAGDETAIL_match+2)
#define VS_TAGDETAIL_match_file            (VS_TAGDETAIL_match+3)
#define VS_TAGDETAIL_match_line            (VS_TAGDETAIL_match+4)
#define VS_TAGDETAIL_match_start_linenum   (VS_TAGDETAIL_match+4)
#define VS_TAGDETAIL_match_start_seekpos   (VS_TAGDETAIL_match+5)
#define VS_TAGDETAIL_match_scope_linenum   (VS_TAGDETAIL_match+6)
#define VS_TAGDETAIL_match_scope_seekpos   (VS_TAGDETAIL_match+7)
#define VS_TAGDETAIL_match_end_linenum     (VS_TAGDETAIL_match+8)
#define VS_TAGDETAIL_match_end_seekpos     (VS_TAGDETAIL_match+9)
#define VS_TAGDETAIL_match_class           (VS_TAGDETAIL_match+10)
#define VS_TAGDETAIL_match_flags           (VS_TAGDETAIL_match+11)
#define VS_TAGDETAIL_match_args            (VS_TAGDETAIL_match+12)
#define VS_TAGDETAIL_match_return          (VS_TAGDETAIL_match+13)
#define VS_TAGDETAIL_match_outer           (VS_TAGDETAIL_match+14)
#define VS_TAGDETAIL_match_parents         (VS_TAGDETAIL_match+15)
#define VS_TAGDETAIL_match_throws          (VS_TAGDETAIL_match+16)
#define VS_TAGDETAIL_match_included_by     (VS_TAGDETAIL_match+17)
#define VS_TAGDETAIL_match_return_only     (VS_TAGDETAIL_match+18)
#define VS_TAGDETAIL_match_return_value    (VS_TAGDETAIL_match+19)
#define VS_TAGDETAIL_match_template_args   (VS_TAGDETAIL_match+20)
#define VS_TAGDETAIL_match_name_linenum    (VS_TAGDETAIL_match+21)
#define VS_TAGDETAIL_match_name_seekpos    (VS_TAGDETAIL_match+22)

//////////////////////////////////////////////////////////////////////
// Characters used as seperators when storing compound strings
// in the database.
//
#define VS_TAGSEPARATOR_class      ':'  // seperates nested class names
#define VS_TAGSEPARATOR_package    '/'  // seperates class from package name

/**
 * This constant represents the character used to separate the real source file
 * name from the name of the souce file that an external macro was included
 * from.class names in the list of parent classes that a class derives from.
 * 
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_file       '\1' // seperates file name from included by
#define VS_TAGSEPARATOR_args       '\1' // seperates arguments from return type
// seperates arguments from exceptions
#define VS_TAGSEPARATOR_throws     '\2' 
/**
 * seperates list of class parents
 */
#define VS_TAGSEPARATOR_parents    ';'  
#define VS_TAGSEPARATOR_equals     '='  // seperates type of constant from value

#define VS_TAGSEPARATOR_zclass     ":"  // seperates nested class names
#define VS_TAGSEPARATOR_zpackage   "/"  // seperates class from package name
#define VS_TAGSEPARATOR_zfile      "\1" // seperates file name from included by
#define VS_TAGSEPARATOR_zargs      "\1" // seperates arguments from return type
#define VS_TAGSEPARATOR_zthrows    "\2" // seperates arguments from exceptions
#define VS_TAGSEPARATOR_zparents   ";"  // seperates list of class parents
#define VS_TAGSEPARATOR_zequals    "="  // seperates type of constant from value

/**
 * This constant represents the character used to
 * separate identifiers in the list of occurrences found
 * in a file when tagging references.
 */
#define VS_TAGSEPARATOR_occurrences '\t'

///////////////////////////////////////////////////////////////////////////
// NOTE: administrative functions are now in tagsmain.h
//
// insertion and removal of tags

/**
 * Insert the given tag with accompanying information into the
 * the database.  This is the easiest to use version of insert,
 * since you do not need to know the ID of the tag type, you
 * simply pass a string.
 *
 * If a record with the same tag name, type, file, *and* class
 * already exists in the database, the line number will be updated.
 * Returns
 *
 * @param tag_name         tag string
 * @param tag_type         string specifying tag_type (see above for
 *                         list of standard type names).  If the string
 *                         is not a standard type, a new type will be
 *                         created and inserted in the tag database.
 * @param file_name        full path of file the tag is located in
 * @param line_no          (optional) line number of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see VS_TAGFLAG_* above.
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_insert_tag(VSPSZ tag_name, VSPSZ tag_type,
                         VSPSZ file_name, int line_no,
                         VSPSZ class_name, int tag_flags,
                         VSPSZ signature);

/**
 * Insert the given tag with the accompanying information into the
 * database.  This function is identical to vsTagInsert, except
 * that rather than passing in a tag type, you pass in an int, using
 * one of the standard types defined above (see VS_TAGTYPE_*).
 *
 * If a record with the same tag name, type, file, *and* class
 * already exists in the database, the line number will be updated.
 *
 * @param tag_name         tag string
 * @param type_id          tag type (see VS_TAGTYPE_*), will return an error
 *                         if (tag_type <= 0 || tag_type > VSTAGTYPE_LASTID).
 * @param file_name        full path of file the tag is located in
 * @param line_no          (optional) line number of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (optional) see VS_TAGFLAG_* above.
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_insert_simple(VSPSZ tag_name, int type_id,
                            VSPSZ file_name, int line_no,
                            VSPSZ class_name, int tag_flags,
                            VSPSZ signature);

/**
 * Remove the current tag (most recently retrieved tag) from the database.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_remove_tag();

/**
 * Remove all tags associated with the given class from the database.
 *
 * @param class_name       full name of the class the tag is associated with
 *                         if NULL, all non-class tags are removed.
 * @param remove_class     if non-zero, the class is removed from the database,
 *                         in addition to the tags associated with the class.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_remove_from_class(VSPSZ class_name /*, int remove_class */);

/**
 * Modify the set of parent classes for a given class.
 * Use the NULL or empty string to indicate that class_name is a base class.
 *
 * @param class_name       class to modify parent relationships for
 * @param parents          classes that 'class_name' inherits from, semicolon separated
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_set_inheritance(VSPSZ class_name, VSPSZ parents);

/**
 * Modify the file and line number of the current tag.
 *
 * @param file_name        new file name to be set
 * @param nLineNum         new line number to be set
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_set_fileline(VSPSZ file_name, int nLineNum);

/**
 * Retrieve the set of parent classes for a given class.
 *
 * This function has the side effect of position the class iterator on the
 * given class.  Returns BT_RECORD_NOT_FOUND_RC if class_name is not
 * in the database.
 *
 * @param class_name       class to modify parent relationships for
 * @param parents          classes that 'class_name' inherits from, semicolon separated
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_get_inheritance(VSPSZ class_name, VSHREFVAR parents);


///////////////////////////////////////////////////////////////////////////
// Retrieval functions

/**
 * Retrieve first tag with the given tag name, type, and class
 * (all are necessary to uniquely identify a tag).  If class_name
 * is unknown, simply use NULL.
 * Use vsTagGetInfo (below) to extract the details about the tag.
 *
 * @param tag_name         name of tag to search for
 * @param tag_type         tag type name (see VS_TAGTYPE_*)
 * @param class_name       name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param arguments        (optional) function arguments to attempt to
 *                         match.  Ignored if they result in no matches.
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_find_tag(VSPSZ tag_name, VSPSZ tag_type, VSPSZ class_name /*,VSPSZ arguments*/);

/**
 * Retrieve next tag with the given tag name, type, and class
 * (all are necessary to uniquely identify a tag).  If class_name
 * is unknown, simply use NULL.
 * Use vsTagGetInfo (below) to extract the details about the tag.
 * Should be called only after calling tag_find_tag.
 *
 * @param tag_name         name of tag to search for
 * @param tag_type         tag type name (see VS_TAGTYPE_*)
 * @param class_name       name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param arguments        (optional) function arguments to attempt to
 *                         match.  Ignored if they result in no matches.
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_next_tag(VSPSZ tag_name, VSPSZ tag_type, VSPSZ class_name /*,VSPSZ arguments*/);

/**
 * Reset the tag name iterator.  Call this to indicate that 
 * you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_reset_find_tag();

/**
 * Retrieve first with the given tag name.
 * Use tag_get_info (below) to extract the details about the tag.
 *
 * @param tag_name         name of tag to search for
 * @param file_name        full path to file containing tag
 * @param line_no          line that tag is expected to be present on
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_find_closest(VSPSZ tag_name, VSPSZ file_name, int line_no);

/**
 * Retrieve first tag with the given tag name (case-insensitive).
 * Use vsTagGetInfo (below) to extract the details about the tag.
 *
 * @param tag_name         name of tag to search for
 * @param case_sensitive   (optional, default false) case sensitive tag name comparison
 * @param class_name       (optional) class name to search for tag in
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_find_equal(VSPSZ tag_name /*,int case_sensitive, VSPSZ class_name*/);

/**
 * Retrieve the next tag with the same tag name as the last one retrieved.
 * Should be called only after calling tag_find_equal or tag_find_tag.
 *
 * @param case_sensitive   (optional, default false) case sensitive tag name comparison
 * @param class_name       (optional) class name to search for tag in
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_next_equal(/*int case_sensitive, VSPSZ class_name*/);

/**
 * Retrieve the first tag with the given tag name (case-insensitive).
 *
 * @param tag_prefix       tag name prefix to search for
 * @param case_sensitive   (optional, default false) case sensitive tag name comparison
 * @param class_name       (optional) class name to search for tag in
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_find_prefix(VSPSZ tag_prefix /*,int case_sensitive, VSPSZ class_name*/);

/**
 * Retrieve the next tag with the given prefix (case-insensitive).
 * Should be called only after calling vsTagGetTagPrefix().
 *
 * @param tag_prefix       tag name prefix to search for
 * @param case_sensitive   (optional, default false) case sensitive tag name comparison
 * @param class_name       (optional) class name to search for tag in
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_next_prefix(VSPSZ tag_prefix /*,int case_sensitive, VSPSZ class_name*/);

/**
 * Retrieve the next tag with the a tag name matching the given
 * regular expression with the given matching options.
 *
 * @param tag_regex        tag name regular expression to search for
 * @param search_options   search options, passed on to vsStrPos()
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_find_regex(VSPSZ tag_regex, VSPSZ search_options);

/**
 * Retrieve the next tag with the a tag name matching the given
 * regular expression with the given matching options.
 * Should be called only after calling tag_find_regex().
 *
 * @param tag_regex        tag name regular expression to search for
 * @param search_options   search options, passed on to vsStrPos()
 *
 * @return 0 on success, <0 on error, or if no such tag.
 */
EXTERN_C
int VSAPI tag_next_regex(VSPSZ tag_regex, VSPSZ search_options);

/**
 * Retrieve information about the current tag (as defined by calls
 * to getTagEQ, getTagPrefix, getNextEQ, getNextPrefix).  If no such
 * tag, all strings will be set to the empty string, and line_no will
 * be set to 0.
 *
 * @param tag_name         (reference) tag string (native case)
 * @param type_name        (reference) string specifying tag_type
 *                         (see above for list of standard type names).
 * @param file_name        (reference) full path of file the tag is located in
 * @param line_no          (reference) line number of tag within file
 *                         set to 0 if not defined.
 * @param class_name       (reference) name of class that tag is present in,
 *                         uses concatenation (as defined by language rules)
 *                         to specify names of inner classes (see insert, above).
 *                         set to empty string if not defined.
 * @param tag_flags        (reference) see VS_TAGFLAG_* above.
 *
 * @return nothing.
 */
EXTERN_C
void VSAPI tag_get_info(VSHREFVAR tag_name, VSHREFVAR type_name,
                        VSHREFVAR file_name, VSHREFVAR line_no,
                        VSHREFVAR class_name, VSHREFVAR tag_flags);

/**
 * Retrieve specific details about the current tag (as defined by calls
 * to getTagEQ, getTagPrefix, getNextEQ, getNextPrefix).  If no such
 * tag, all strings will be set to the empty string, and ints to 0.
 * See VS_TAGDETAIL_*, above.
 *
 * @param tag_detail       ID of detail to extract (VS_TAGDETAIL_*)
 * @param result           (reference) set to value of requested tag detail
 *
 * @return nothing
 */
EXTERN_C
void VSAPI tag_get_detail(int tag_detail, VSHREFVAR result);

/**
 * Return the tag ID for the current tag.  Returns 0 if there
 * is no tag ID (earlier database version), or <0 on error.
 *
 * @return int VSAPI
 */
//EXTERN_C
//int VSAPI tag_get_tag_id();

/**
 * Find the tag having the given tag ID in the database.
 *
 * @param tag_id           tag ID to search for
 *
 * @return 0 on success, <0 on error.
 */
//EXTERN_C
//int VSAPI tag_find_tag_by_id(int tag_id);


///////////////////////////////////////////////////////////////////////////
// file-name based retrieval functions

/**
 * Find the first tag in the given file.
 *
 * @param file_name        full path of file containing tags
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_in_file(VSPSZ file_name);

/**
 * Find the next tag in the current file.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_in_file();

/**
 * Reset the tag find-in-file iterator.  Call this to indicate 
 * that you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_reset_find_in_file();


///////////////////////////////////////////////////////////////////////////
// class-name based retrieval functions

/**
 * Retreive the name of the first class included in this tag database.
 *
 * @param class_id         id of class/package, from tag_get_detail()
 * @param class_name       (reference) name of class
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_get_class(int class_id, VSHREFVAR class_name);

/**
 * Retreive the name of the first class included in this tag database.
 *
 * @param class_name       (reference) name of class
 * @param search_for       (optional) specific class to search for (prefix search)
 * @param normalize        (optional) normalize the class name (find what package it belongs to)
 * @param ignore_case      (optional) perform case-insensitive search? (default is case-sensitive)
 * @param cur_class_name   (optional) name of current class in context
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_class(VSHREFVAR class_name /*, search_for, normalize, ignore_case*/);

/**
 * Retreive the name of the next class included in this tag database.
 *
 * @param class_name       (reference) name of class
 * @param search_for       (optional) specific class to search for (prefix search)
 * @param normalize        (optional) normalize the class name (find what package it belongs to)
 * @param ignore_case      (optional) perform case-insensitive search? (default is case-sensitive)
 * @param cur_class_name   (optional) name of current class in context
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_class(VSHREFVAR class_name /*,search_for, normalize, ignore_case*/);

/**
 * Reset the class name iterator.  Call this to indicate that 
 * you are done searching for class names in the current 
 * database. 
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_reset_find_class();

/**
 * Find the first class in the given class.
 *
 * @param class_name       name of class, containing tags
 *
 * @return
 */
EXTERN_C
int VSAPI tag_find_in_class(VSPSZ class_name);

/**
 * Find the next tag in the given class.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_in_class();

/**
 * Reset the tag find-in-class name iterator.  Call this to indicate 
 * that you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_reset_find_in_class();


///////////////////////////////////////////////////////////////////////////
// global identifier retrieval functions

/**
 * Retrieve the first tag included in this tag database with global
 * scope that is one of the given type (type_id) and that
 * matches the given tag flag mask (mask & tag.mask != 0).
 * Tag names are ordered lexicographically, case insensitive
 *
 * @param type_id          first type id (see VS_TAGTYPE_*, above)
 *                         if (type_id<0), returns tags with ID>VS_TAGTYPE_LASTID
 * @param mask             flag mask (see VS_TAGFLAG_*, above)
 * @param nzero            if 1, succeed if mask & tag.flags != 0
 *                         if 0, succeed if mask & tag.flags == 0
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_global(int type_id, int mask, int nzero);

/**
 * Retrieve the next tag included in this tag database with global
 * scope that is one of the given type (type_id) and that
 * matches the given tag flag mask (mask & tag.mask != 0).
 * Tag names are ordered lexicographically, case insensitive
 *
 * @param type_id          first type id (see VS_TAGTYPE_*, above)
 *                         if (type_id<0), returns tags with ID>VS_TAGTYPE_LASTID
 * @param mask             flag mask (see VS_TAGFLAG_*, above)
 * @param nzero            if 1, succeed if mask & tag.flags != 0
 *                         if 0, succeed if mask & tag.flags == 0
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_global(int type_id, int mask, int nzero);


///////////////////////////////////////////////////////////////////////////
// Word index (references) table maintenance functions.

/**
 * Set up for inserting a series of occurrences from a single file
 * for update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param file_name        full path of file the tags are located in
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_occurrences_start(VSPSZ file_name);

/**
 * Clean up after inserting a series of occurrences from a single
 * file for update.  Doing this allows the tag database engine to
 * remove any occurrences from the database that are no longer valid.
 *
 * @return 0 on success, <0 on error.int VSAPI
 */
EXTERN_C
int VSAPI tag_occurrences_end(VSPSZ file_name);

/**
 * Insert a new occurrence into the word index.
 *
 * @param occur_name      Word to be indexed
 * @param file_name       Path of file occurrence is located in
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_insert_occurrence(VSPSZ occur_name, VSPSZ file_name);

/**
 * Find the first occurrence with the given tag name or tag prefix.
 * Use tag_get_occurrence (below) to get details about the occurrence.
 *
 * @param tag_name        Tag name or prefix to search for
 * @param exact_match     Exact (word) match or prefix match (0)
 * @param case_sensitive  Case sensitive search?
 *
 * @return 0 on success, BT_RECORD_NOT_FOUND_RC if not found, <0 on error.
 */
EXTERN_C
int VSAPI tag_find_occurrence(VSPSZ tag_name,
                              int exact_match VSDEFAULT(1), int case_sensitive VSDEFAULT(0));

/**
 * Find the next occurrence with the given tag name or tag prefix.
 * Use tag_get_occurrence (below) to get details about the occurrence.
 *
 * @param tag_name        Tag name or prefix to search for
 * @param exact_match     Exact (word) match or prefix match (0)
 * @param case_sensitive  Case sensitive search?
 *
 * @return 0 on success, BT_RECORD_NOT_FOUND_RC if not found, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_occurrence(VSPSZ tag_name,
                              int exact_match VSDEFAULT(1), int case_sensitive VSDEFAULT(0));

/**
 * Retrieve information about the current occurrence, as defined by
 * tag_find_occurrence/tag_next_occurrence.
 *
 * @param occur_name      (output) Word to be indexed
 * @param file_name       (output) Path of file occurrence is located in
 *
 * @return nothing.
 */
EXTERN_C
void VSAPI tag_get_occurrence(VSHREFVAR occur_name, VSHREFVAR file_name);

/**
 * Reset the tag occurrence iterator.  Call this function after you are 
 * done searching through tag occurrences in the current database. 
 * 
 * @return 0 on success, <0 on error.
 */
EXTERN_C int VSAPI tag_reset_find_occurrence();

/**
 * Default function for matching occurrences and inserting them into
 * the database.  Simply searches for words that are not in comments,
 * strings, numbers, keywords, line numbers, or preprocessing, using
 * the color coding engine.
 *
 * @param file_name        Name of buffer to search for occurrences in
 * @param tag_name         Name of identifier to search for, null of anything
 * @param case_sensitive   Case sensitive identifier search?
 * @param start_seekpos    Seek position to start searching at, 0 means TOP
 * @param stop_seekpos     Seek position to end searching at, 0 means EOF
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_list_occurrences(VSPSZ file_name,
                               VSPSZ tag_name, int case_sensitive,
                               int start_seekpos, int stop_seekpos);

/**
 * The current object must be an editor control positioned on
 * the tag that you wish to find matches for, with the edit
 * mode selected.
 *
 * @param errorArgs       Array of strings for return code
 * @param tag_name        Name of occurrence to match against
 * @param exact_match     Exact match or prefix match?
 * @param case_sensitive  Case sensitive tag search?
 * @param find_parents    Find instances of this tag in parent classes
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success, <0 on error, >0 on Context Tagging&reg; error.
 */
EXTERN_C int VSAPI
tag_context_match_tags(VSHREFVAR errorArgs, VSHREFVAR tag_name,
                       int exact_match, int case_sensitive, int find_parents,
                       VSHREFVAR num_matches, int max_matches);

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 *
 * @param errorArgs       (reference) error message parameters
 * @param tree_wid        window ID of tree control to insert into
 * @param tree_index      index of item in tree to insert under
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param filter_flags    item filter flags
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (reference) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 *
 * @return 0 on success, <0 on error, >0 on Context Tagging &reg; error.
 */
EXTERN_C int VSAPI
tag_match_occurrences_in_file(VSHREFVAR errorArgs,
                              int tree_wid, int tree_index,
                              VSPSZ tag_name, int case_sensitive,
                              VSPSZ file_name, int line_no,
                              int filter_flags,
                              int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                              VSHREFVAR num_matches, int max_matches);

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 *
 * @param errorArgs       (reference) error message parameters
 * @param seekPositions   (reference) seek positions of occurrences
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param filter_flags    item filter flags
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (reference) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 *
 * @return 0 on success, <0 on error, >0 on Context Tagging&reg; error.
 */
EXTERN_C int VSAPI
tag_match_occurrences_in_file_get_positions(VSHREFVAR errorArgs,
                              VSHREFVAR seekPositions,
                              VSPSZ tag_name, int case_sensitive,
                              VSPSZ file_name, int line_no,
                              int filter_flags,
                              int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                              VSHREFVAR num_matches, int max_matches);


/**
 * Match occurrences of the given tag name in the current buffer,
 * Return whether any occurrences of the tag in the current buffer have a class_name
 * that matches any of the classes passed in through class_list.
 *
 * @param errorArgs       (reference) error message parameters
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param class_list      list of class names to compare tag's class_name against
 * @param num_classes     number of classes in class_list
 * @param filter_flags    item filter flags
 * @param has_match       (reference) at least of the tags in this buffer matches
 * @param max_matches     maximum number of occurrences to find
 *
 * @return 0 on success, <0 on error, >0 on Context Tagging&reg; error.
 */
EXTERN_C int VSAPI
tag_match_multiple_occurrences_in_file(VSHREFVAR errorArgs,
                              VSPSZ tag_name, int case_sensitive,
                              VSHREFVAR class_list, int num_classes,
                              int filter_flags,
                              VSHREFVAR has_match, int max_matches);

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 *
 * @param errorArgs       (reference) error message parameters
 * @param tree_wid        window ID of tree control to insert into
 * @param tree_index      index of item in tree to insert under
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param alt_file_name   alternate path of file match tag is in
 * @param alt_line_no     alternate real line number match tag is located on
 * @param filter_flags    item filter flags
 * @param caller_id       context ID of item to look for uses in
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (reference) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 *
 * @return 0 on success, <0 on error, >0 on Context Tagging&reg; error.
 */
EXTERN_C int VSAPI
tag_match_uses_in_file(VSHREFVAR errorArgs,
                       int tree_wid, int tree_index,
                       int case_sensitive, VSPSZ file_name, int line_no,
                       VSPSZ alt_file_name, int alt_line_no,
                       int filter_flags, int caller_id,
                       int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                       VSHREFVAR num_matches, int max_matches);

/**
 * List the files containing 'tag_name', matching by prefix or
 * case-sensitive, as specified.  Terminates search if a total
 * of max_refs are hit.  Items are inserted into the tree, with
 * the user data set to the file path.
 *
 * @param tree_wid        window id of tree control to insert into
 * @param tree_index      index, usually TREE_ROOT_INDEX to insert under
 * @param tag_name        name of tag to search for
 * @param exact_match     exact match or prefix match
 * @param case_sensitive  case sensitive match, or case-insensitive
 * @param num_refs        (reference) number of references found so far
 * @param max_refs        maximum number of items to insert
 * @param restrictToLangId restrict references to files of the 
 *                         given language, or related language.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C int VSAPI
tag_list_file_occurrences(int tree_wid, int tree_index,
                          VSPSZ tag_name, int exact_match,
                          int case_sensitive,
                          VSHREFVAR num_refs, int max_refs,
                          VSPSZ restrictToLangId=NULL);


///////////////////////////////////////////////////////////////////////////
// utility routines for tagging support

/**
 * This function is used to look up an extension-specific
 * callback function.
 * <p>
 * Return the names table index for the callback function for the
 * current language, or a language we inherit behavior from.
 * The current object should be an editor control.
 *
 * @param callback_name    name of callback to look up, with
 *                         a '%s' marker in place where the
 *                         extension would be normally located.
 * @param lang             current language ID
 *                         (default={@link p_LangId})
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 *  
 * @deprecated use {@link vsFindLanguageCallbackIndex()} 
 */
EXTERN_C int VSAPI
tag_find_ext_callback(VSPSZ callback_name, VSPSZ lang);


#endif
// TAGS_DB_H
