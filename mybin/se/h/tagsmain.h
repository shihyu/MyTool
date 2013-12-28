////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef TAGS_MAIN_H
#define TAGS_MAIN_H

#include "vsdecl.h"


//////////////////////////////////////////////////////////////////////
// "C" style API for creating and accessing BTREE tag database.
//

//////////////////////////////////////////////////////////////////////
// Database version, corresponding to SlickEdit versions
//
#define VS_TAG_USER_VERSION             3000
#define VS_TAG_USER_VERSION_WIDE_FLAGS  3100
#define VS_TAG_USER_VERSION_FILE_TYPES  4000
#define VS_TAG_USER_VERSION_CASE_FIXED  4100
#define VS_TAG_USER_VERSION_EXCEPTIONS  4200
#define VS_TAG_USER_VERSION_COPY_FILES  4300
#define VS_TAG_USER_VERSION_RELATIVE    4400
#define VS_TAG_USER_VERSION_LARGE_IDS   5000
#define VS_TAG_USER_VERSION_DISK_HASH   5100
#define VS_TAG_USER_VERSION_REFERENCES  5200
#define VS_TAG_USER_VERSION_COMPACT     5300
#define VS_TAG_USER_VERSION_EXTENSIONS  5400
#define VS_TAG_USER_VERSION_OCCURRENCES 5500
#define VS_TAG_USER_VERSION_NO_NEXTPREV 5600
#define VS_TAG_USER_VERSION_UTF8        7000
#define VS_TAG_USER_VERSION_FILECASE    7100
#define VS_TAG_USER_VERSION_TEMPLATES   9200
#define VS_TAG_USER_VERSION_NAMESPACES  9300
#define VS_TAG_USER_VERSION_STATEMENTS 10000
#define VS_TAG_USER_VERSION_QPARENTS   10101
#define VS_TAG_USER_VERSION_ADHOC_REFS 11000
#define VS_TAG_USER_VERSION_CLASS_TAG  11001
#define VS_TAG_USER_VERSION_CASE_SENS  12000
#define VS_TAG_USER_VERSION_UTC_TIMES  12001
#define VS_TAG_USER_VERSION_LESS_DUPS  16000
#define VS_TAG_USER_VERSION_LARGE_KEYS 16001
#define VS_TAG_USER_VERSION_LINE_KEYS  17000
#define VS_TAG_USER_VERSION_REBUILD_17 17001
/**
 * This constant represents the latest version of the tagging database format
 * implemented in the DLL tagsdb.dll.  See {@link tag_current_version}.
 *
 * @categories Tagging_Functions
 */
#define VS_TAG_LATEST_VERSION          17001
#define VS_REF_USER_VERSION             4000
#define VS_REF_USER_VERSION_RELATIVE    4100
#define VS_REF_USER_VERSION_LARGE_IDS   5000
#define VS_REF_USER_VERSION_DISK_HASH   5100
/**
 * This constant represents the latest version of the references database format
 * implemented in the DLL tagsdb.dll.  See {@link tag_current_version}.
 *
 * @categories Tagging_Functions
 */
#define VS_REF_LATEST_VERSION           VS_TAG_LATEST_VERSION


//////////////////////////////////////////////////////////////////////
// Database file types that can be opened using this library
//
#define VS_DBTYPE_tags        0
#define VS_DBTYPE_references  1
#define VS_DBTYPE_msbrowse    2


//////////////////////////////////////////////////////////////////////
// Database flags indicating attributes for this tag database.
// The low sixteen bits are reserved for SlickEdit development.
//
#define VS_DBFLAG_occurrences    0x00000001  // tag occurrences
#define VS_DBFLAG_no_occurrences 0x00000002  // user specifically said no to occurrences
#define VS_DBFLAG_reserved       0x0000fffc  // future expansion, reseerved by SlickEdit
#define VS_DBFLAG_user           0x00010000  // user flags

//////////////////////////////////////////////////////////////////////
// Standard file types, used to distinguish between source files
// pulled in naturally by tagging, object files, class files,
// executables, browser databaser, debug databases, and source files
// referenced by various other items.
//
#define VS_FILETYPE_source      0
#define VS_FILETYPE_references  1
#define VS_FILETYPE_include     2


//////////////////////////////////////////////////////////////////////
// Standard tag types, by default, always present in database
// standard type name is always "xxx" for VS_TAGTYPE_xxx,
// for example, the type name for VS_TAGTYPE_proc is "proc".
// ID's 30-127 are reserved for future use by SlickEdit.
//
#define VS_TAGTYPE_proc         1  // procedure or command
#define VS_TAGTYPE_proto        2  // function prototype
#define VS_TAGTYPE_define       3  // preprocessor macro definition
#define VS_TAGTYPE_typedef      4  // type definition
#define VS_TAGTYPE_gvar         5  // global variable declaration
#define VS_TAGTYPE_struct       6  // structure definition
#define VS_TAGTYPE_enumc        7  // enumeration value
#define VS_TAGTYPE_enum         8  // enumerated type
#define VS_TAGTYPE_class        9  // class definition
#define VS_TAGTYPE_union       10  // structure / union definition
#define VS_TAGTYPE_label       11  // label
#define VS_TAGTYPE_interface   12  // interface, eg, for Java
#define VS_TAGTYPE_constructor 13  // class constructor
#define VS_TAGTYPE_destructor  14  // class destructor
#define VS_TAGTYPE_package     15  // package / module / namespace
#define VS_TAGTYPE_var         16  // member of a class / struct / package
#define VS_TAGTYPE_lvar        17  // local variable declaration
#define VS_TAGTYPE_constant    18  // pascal constant
#define VS_TAGTYPE_function    19  // function
#define VS_TAGTYPE_property    20  // property?
#define VS_TAGTYPE_program     21  // pascal program
#define VS_TAGTYPE_library     22  // pascal library
#define VS_TAGTYPE_parameter   23  // function or procedure parameter
#define VS_TAGTYPE_import      24  // package import or using
#define VS_TAGTYPE_friend      25  // C++ friend relationship
#define VS_TAGTYPE_database    26  // SQL/OO Database
#define VS_TAGTYPE_table       27  // Database Table
#define VS_TAGTYPE_column      28  // Database Column
#define VS_TAGTYPE_index       29  // Database index
#define VS_TAGTYPE_view        30  // Database view
#define VS_TAGTYPE_trigger     31  // Database trigger
#define VS_TAGTYPE_form        32  // GUI Form or window
#define VS_TAGTYPE_menu        33  // GUI Menu
#define VS_TAGTYPE_control     34  // GUI Control or Widget
#define VS_TAGTYPE_eventtab    35  // GUI Event table
#define VS_TAGTYPE_procproto   36  // Prototype for procedure
#define VS_TAGTYPE_task        37  // Ada task object
#define VS_TAGTYPE_include     38  // C++ include, Ada with
#define VS_TAGTYPE_file        39  // COBOL file descriptor
#define VS_TAGTYPE_group       40  // Container variable
#define VS_TAGTYPE_subfunc     41  // Nested function
#define VS_TAGTYPE_subproc     42  // Nested procedure or cobol paragraph
#define VS_TAGTYPE_cursor      43  // Database result set cursor
#define VS_TAGTYPE_tag         44  // SGML or XML tag type (like a class)
#define VS_TAGTYPE_taguse      45  // SGML or XML tag instance (like an object)
#define VS_TAGTYPE_statement   46  // generic statement
#define VS_TAGTYPE_annotype    47  // Java annotation type or C# attribute class
#define VS_TAGTYPE_annotation  48  // Java annotation or C# attribute instance
#define VS_TAGTYPE_call        49  // Function/Method call
#define VS_TAGTYPE_if          50  // If/Switch/Case statement
#define VS_TAGTYPE_loop        51  // Loop statement
#define VS_TAGTYPE_break       52  // Break statement
#define VS_TAGTYPE_continue    53  // Continue statement
#define VS_TAGTYPE_return      54  // Return statement
#define VS_TAGTYPE_goto        55  // Goto statement
#define VS_TAGTYPE_try         56  // Try/Catch/Finally statement
#define VS_TAGTYPE_pp          57  // Preprocessing statement
#define VS_TAGTYPE_block       58  // Statement block
#define VS_TAGTYPE_mixin       59  // D language mixin construct
#define VS_TAGTYPE_target      60  // Ant target
#define VS_TAGTYPE_assign      61  // Assignment statement
#define VS_TAGTYPE_selector    62  // Objective-C method
#define VS_TAGTYPE_LASTID      62  // last tag type ID
#define VS_TAGTYPE_FIRSTUSER  128  // first user-defined tag type ID
#define VS_TAGTYPE_LASTUSER   159  // last user-defined tag type ID (this is the last ID that can be created automatically by vsTagGetTypeID)
// 160-255 are for OEM use
#define VS_TAGTYPE_FIRSTOEM   160  // first OEM-defined tag type ID
#define VS_TAGTYPE_LASTOEM    255  // last OEM-defined tag type ID
#define VS_TAGTYPE_MAXIMUM    255  // maximum tag type ID

//////////////////////////////////////////////////////////////////////
// Tag type filtering flags, formerly PUSHTAG_* flags in slick.sh
//
#define VS_TAGFILTER_CASESENSITIVE     0x00000001
// types of tags
#define VS_TAGFILTER_PROC              0x00000002
#define VS_TAGFILTER_PROTO             0x00000004
#define VS_TAGFILTER_DEFINE            0x00000008
#define VS_TAGFILTER_ENUM              0x00000010
#define VS_TAGFILTER_GVAR              0x00000020
#define VS_TAGFILTER_TYPEDEF           0x00000040
#define VS_TAGFILTER_STRUCT            0x00000080
#define VS_TAGFILTER_UNION             0x00000100
#define VS_TAGFILTER_LABEL             0x00000200
#define VS_TAGFILTER_INTERFACE         0x00000400
#define VS_TAGFILTER_PACKAGE           0x00000800
#define VS_TAGFILTER_VAR               0x00001000
#define VS_TAGFILTER_CONSTANT          0x00002000
#define VS_TAGFILTER_PROPERTY          0x00004000
#define VS_TAGFILTER_LVAR              0x00008000
#define VS_TAGFILTER_MISCELLANEOUS     0x00010000
#define VS_TAGFILTER_DATABASE          0x00020000
#define VS_TAGFILTER_GUI               0x00040000
#define VS_TAGFILTER_INCLUDE           0x00080000
#define VS_TAGFILTER_SUBPROC           0x00100000
#define VS_TAGFILTER_UNKNOWN           0x00200000
#define VS_TAGFILTER_ANYSYMBOL         0x003ffffe
#define VS_TAGFILTER_ANYTHING          0x7ffffffe
// classes of tag types
#define VS_TAGFILTER_ANYPROC           (VS_TAGFILTER_PROTO|VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC)
#define VS_TAGFILTER_ANYDATA           (VS_TAGFILTER_GVAR|VS_TAGFILTER_VAR|VS_TAGFILTER_LVAR|VS_TAGFILTER_PROPERTY|VS_TAGFILTER_CONSTANT)
#define VS_TAGFILTER_ANYSTRUCT         (VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE)
// statement types
#define VS_TAGFILTER_STATEMENT         0x00400000
// annotation types
#define VS_TAGFILTER_ANNOTATION        0x00800000
// tag scope
#define VS_TAGFILTER_SCOPE_PRIVATE     0x01000000
#define VS_TAGFILTER_SCOPE_PROTECTED   0x02000000
#define VS_TAGFILTER_SCOPE_PACKAGE     0x04000000
#define VS_TAGFILTER_SCOPE_PUBLIC      0x08000000
#define VS_TAGFILTER_SCOPE_STATIC      0x10000000
#define VS_TAGFILTER_SCOPE_EXTERN      0x20000000
#define VS_TAGFILTER_ANYSCOPE          0x7f000000
// tags in zip, dll, and tag files
#define VS_TAGFILTER_NOBINARY          0x80000000


///////////////////////////////////////////////////////////////////////////
// administrative functions

/** 
 * Specify the amount of memory to use for the database cache.
 *
 * @param cache_size       amount of memory in bytes
 * @param cache_max        maximum amount of memory to allow cache to use
 *                         dynamically set depending on the machine's
 *                         available memory.
 *
 * @return 0 on success, <0 on error.  The minimum size cache allowed is 1024k.
 */
EXTERN_C
int VSAPI tag_set_cache_size(int cache_size, int cache_max);

/**
 * @return Return the actual amount of memory being used for the tag file cache. 
 *         The actual tagging cache size is determined dynamically based on
 *         the amount of memory available at startup as well as the
 *         settings for {@link def_tag_cache_size} and {@link def_tag_cache_max}. 
 */
EXTERN_C
int VSAPI tag_get_cache_size();

/**
  Create a tag database, with standard tables, index, and types.

  @param file_name        file path where to create new database
                          If file_name exists, it will be truncated.
  @param db_type          (optional) if not given, creates tag database.
                          if (db_type==VS_DBTYPE_references), then creates
                          a tag references database.

  @return database handle >= 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_create_db(VSPSZ file_name /*, int db_type */);

/**
  Open an existing tag database and return a handle to the database.
  This function opens the database for read-write access.

  @param file_name        file name of tag database to open.

  @return database handle >= 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_open_db(VSPSZ file_name);

/**
  Open an existing tag database and return a handle to the database.
  This function opens the database for read-only access.

  @param file_name        file name of tag database to open.

  @return database handle >= 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_read_db(VSPSZ file_name);

/**
  Flush all unwritten data to disk for the database.

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_flush_db();

/**
 * Return the name of the database currently open
 *
 * @return name of database, or the empty string on error.
 */
EXTERN_C
VSPSZ VSAPI tag_current_db();

/**
  Close the current tag database.

  @param file_name        (optional) explicite filename of database to close
                          otherwise the current open database is closed.
  @param leave_open       (optional) leave the tag file open read-only

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_close_db(/*VSPSZ file_name="", int leave_open=0*/);

/**
 * Set a thread synchronization lock on the given tag database. 
 * This is an reader lock which keeps all other threads from 
 * modifying the database. 
 */
EXTERN_C 
int VSAPI tag_lock_db(VSPSZ file_name, int ms=0);

/**
 * Try to get a thread synchronization lock on the given tag database. 
 * This is an reader lock which keeps all other threads from 
 * modifying the database. 
 *  
 * @return Returns 'true' if we were able to get the lock. 
 */
EXTERN_C 
int VSAPI tag_trylock_db(VSPSZ file_name);

/**
 * Release the thread synchronization lock on the given database. 
 * Note that write locks are automatically released when the database 
 * is closed or re-opened for reading. 
 */
EXTERN_C 
int VSAPI tag_unlock_db(VSPSZ file_name);

/**
  Close all open tag databases.

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_close_all_db();

/**
  Display the effective version of the tagsdb.dll

  @return nothing.
*/
EXTERN_C
void VSAPI tagsdb_version();

/**
  Return the version of the tags database currently open.

  @return VS_TAG_USER_VERSION or higher.
*/
EXTERN_C
int VSAPI tag_current_version();

/**
  Return the database description/title.

  @return database description, null terminated, or the empty string on error.
*/
EXTERN_C
VSPSZ VSAPI tag_get_db_comment();

/**
  Sets the database description/title.

  @param comment          description or title of this database

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_set_db_comment(VSPSZ comment);

/**
  Return the database flags VS_DBFLAG_*

  @return <0 on error, flags bitset on success.
*/
EXTERN_C
int VSAPI tag_get_db_flags();

/**
  Sets the database flags VS_DBFLAG_*

  @param flags            bitset of VS_DBFLAG_*

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_set_db_flags(int flags);


///////////////////////////////////////////////////////////////////////////
// insertion and removal of tags

/**
  Set up for inserting a series of tags from a single file for
  update.  Doing this allows the tag database engine to detect
  and handle updates more effeciently, even in the presence of
  duplicates.

  @param file_name        full path of file the tags are located in

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_insert_file_start(VSPSZ file_name);

/**
  Clean up after inserting a series of tags from a single file
  for update.  Doing this allows the tag database engine to
  remove any tags from the database that are no longer valid.

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_insert_file_end();

/**
  Remove all references from the given references (browse database or
  object) file from the database.  This is an effective, but costly way
  to perform an incremental update of the data imported from a
  references file.  First remove all items associated with that file,
  then insert them again.

  @param file_name        full path of file the reference info came from
  @param remove_file      if non-zero, the file is removed from the database

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_remove_from_file(VSPSZ file_name /*, int remove_file */);


///////////////////////////////////////////////////////////////////////////
// file name handling functions

/**
  Rename the given file.

  @param file_name        name of file to update date of tagging for
  @param new_file_name    new file name

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_rename_file(VSPSZ file_name,VSPSZ new_file_name);

/**
  Modify the date of tagging for the given file.  Since date of tagging
  is not involved in indexing, this is safe to do in the record, in place.
  This method always uses the current date when setting the date of tagging.

  @param file_name        name of file to update date of tagging for
  @param modify_date      (optional) modification date when tagged, read from disk
                          if modify_date is NULL.  Format is YYYYMMDDHHMMSSmmm.
  @param file_type        (optional) type of file
  @param included_by      (optoinal) path of file including this file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_set_date(VSPSZ file_name /*,VSPSZ modify_date,int file_type,VSPSZ included_by*/);

/**
  Retrieve the date of tagging for the given file.
  The string returned by this function is structured such
  that consecutive dates are ordered lexicographically,
  and is reported in local time cooridinates (YYYYMMDDHHMMSSmmm).
  This function has the side effect of finding and position the file iterator
  on the given file name, returns BT_RECORD_NOT_FOUND_RC if file_name is not
  in the database.

  @param file_name        name of file to update date of tagging for
  @param modify_date      (reference) returns the file's modification date when tagged
  @param included_by      (optional) path of file including this file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_get_date(VSPSZ file_name, VSHREFVAR modify_date /*,VSPSZ included_by*/);

/**
 * API function for setting the language type for the given 
 * filename.  This corresponds to the p_LangId property of 
 * 'file_name', not necessarily the literal file extension. 
 *  
 * @param file_name        name of file to set language type for 
 * @param lang             p_LangId property for file_name 
 *  
 * @return 0 on success, <0 on error. 
 * @deprecated Use {@link tag_set_language()}. 
 */
EXTERN_C
int VSAPI tag_set_extension(VSPSZ file_name, VSPSZ lang);

/** 
 * API function for retrieving the language type for the given
 * filename.  This corresponds to the p_LangId property of
 * 'file_name', not necessarily the literal file extension.
 * 
 * @param file_name     name of file to get language type for 
 * @param lang          (reference) p_LangId property for file_name
 * 
 * @return 0 on success, <0 on error.
 * @deprecated Use {@link tag_get_language()}. 
 */
EXTERN_C
int VSAPI tag_get_extension(VSPSZ file_name, VSHREFVAR lang);

/**
 * API function for setting the language type for the given 
 * filename.  This corresponds to the p_LangId property of 
 * 'file_name', not necessarily the literal file extension.
 *  
 * @param file_name     name of file to set language type for 
 * @param lang          p_LangId property for file_name 
 *  
 * @return 0 on success, <0 on error. 
 */
EXTERN_C
int VSAPI tag_set_language(VSPSZ file_name, VSPSZ lang);

/** 
 * API function for retrieving the language type for the given
 * filename.  This corresponds to the p_LangId property of
 * 'file_name', not necessarily the literal file extension.
 * 
 * @param file_name  name of file to set language type for
 * @param lang       (reference) p_LangId property for file_name
 * 
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_get_language(VSPSZ file_name, VSHREFVAR lang);

/**
  Retreive the name of the next file included in this tag database.

  @param file_id          id of file, from tag_get_detail()
  @param file_name        (reference) full path of file containing tags

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_get_file(int file_id, VSHREFVAR file_name);

/**
  Retreive the name of the first file included in this tag database.

  @param file_name        (reference) full path of file containing tags
  @param search_for       (optional) specific file to search for (prefix search)

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_find_file(VSHREFVAR file_name /*, VSPSZ search_for*/);

/**
  Retreive the name of the next file included in this tag database.

  @param file_name        (reference) full path of file containing tags

  @return 0 on success, <0 on error
*/
EXTERN_C
int VSAPI tag_next_file(VSHREFVAR file_name);

/**
 * Reset the file name iterator.  This should be called after 
 * using tag_find_file() or tag_next_file() to release the file 
 * iterator. 
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_reset_find_file();

/**
  Retrieve the name of the first file included by file_name

  @param file_name        full path of "main" source file
  @param include_name     (reference) full path of included file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_find_include_file(VSPSZ file_name, VSHREFVAR include_name);

/**
  Retrieve the name of the next file included by file_name

  @param file_name        full path of "main" source file
  @param include_name     (reference) full path of included file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_next_include_file(VSPSZ file_name, VSHREFVAR include_name);

/**
  Retreive the name of first the source file that included (directly
  or indirectly), the given file (expected to be an include file).

  @param file_name        full path of file that was included
  @param included_by      (reference) full path of source file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_find_included_by(VSPSZ file_name, VSHREFVAR included_by);

/**
  Retreive the name of next the source file that included (directly
  or indirectly), the given file (expected to be an include file).

  @param file_name        full path of file that was included
  @param included_by      (reference) full path of source file

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_next_included_by(VSPSZ file_name, VSHREFVAR included_by);


///////////////////////////////////////////////////////////////////////////
// Language type name handling functions

/** 
 * API function for finding what languages are tagged in this
 * database, typically, there is only one.  Note that if files 
 * are added and removed from a project, stale language types 
 * may be left around. Languages are determined by the language 
 * ID for the file, as represented by {@link p_LangId}. 
 * 
 * @param lang         (reference) set to first language found 
 * @param search_for   (optional) language ID to search for 
 * 
 * @return 0 on success, <0 on error. 
 * @deprecated Use {@link tag_find_language()}. 
 */ 
EXTERN_C
int VSAPI tag_find_extension(VSHREFVAR lang /*, VSPSZ search_for*/);

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_extension} (above). 
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, <0 on error.
 * @deprecated Use {@link tag_next_language()}. 
 */
EXTERN_C
int VSAPI tag_next_extension(VSHREFVAR lang);

/** 
 * API function for finding what languages are tagged in this
 * database, typically, there is only one.  Note that if files 
 * are added and removed from a project, stale language types 
 * may be left around. Languages are determined by the language 
 * ID for the file, as represented by {@link p_LangId}. 
 * 
 * @param lang         (reference) set to first language found 
 * @param search_for   (optional) language ID to search for 
 * 
 * @return 0 on success, <0 on error. 
 * @deprecated Use {@link tag_find_language()}. 
 */ 
EXTERN_C
int VSAPI tag_find_language(VSHREFVAR lang, VSPSZ search_for VSDEFAULT(0));

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_language} (above). 
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_next_language(VSHREFVAR lang);

/** 
 * Reset the find language iterator.
 * 
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_reset_find_language();


///////////////////////////////////////////////////////////////////////////
// type name handling functions

/**
  Retreive the name of the next type included in this tag database.

  @param type_id          id of type, from tag_get_detail()
  @param type_name        (reference) full path of type containing tags

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_get_type(int type_id, VSHREFVAR type_name);

/**
  Retreive the name of the first type included in this tag database.

  @param type_name        (reference) full path of type containing tags
  @param search_for       (optional) specific type to search for (prefix search)

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_find_type(VSHREFVAR type_name /*, VSPSZ search_for*/);

/**
  Retreive the name of the next type included in this tag database.

  @param type_name        (reference) full path of type containing tags

  @return 0 on success, <0 on error.
*/
EXTERN_C
int VSAPI tag_next_type(VSHREFVAR type_name);
/**
 * Reset the type iterator
 */
EXTERN_C
int VSAPI tag_reset_find_type();

/**
  Filter the given tag type based on the given filter flags

  @param type_id          tag type ID
  @param filter_flags     VS_TAGFILTER_*
  @param type_name        (optional) look up type ID using this name
  @param tag_flags        (optional) check tag flags for VS_TAGFLAG_maybe_var

  @return 1 if the type is allowed according to the flags, 0 if not.
*/
EXTERN_C
int VSAPI tag_filter_type(int type_id, int filter_flags /*, VSPSZ type_name, int tag_flags*/);

/**
 * Register a new OEM-defined type.
 *
 * @param type_id              Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 * @param pszTypeName          Tag type name
 * @param is_container         1=tag type is a container (i.e. can have members) 
 * @param description          (optional) description of the new tag type
 * @param filterFlags          (optional) VS_TAGFILTER_* 
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI tag_register_type(int type_id, VSPSZ pszTypeName, int is_container);

/**
 * Unregister a OEM-defined type.
 *
 * @param type_id Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 */
EXTERN_C
void VSAPI tag_unregister_type(int type_id);

/**
 * Get the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range 0-VS_TAGTYPE_MAXIMUM
 *
 * @return Filter flags for type ID.
 */
EXTERN_C
int VSAPI tag_type_get_filter(int type_id);

/**
 * Set the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 * @param filter_flags New filter flags. See VS_TAGFILTER_*
 */
EXTERN_C
void VSAPI tag_type_set_filter(int type_id,int filter_flags);

/** 
 * Get the optional text description of the given type ID (for screen display) 
 *
 * @param type_id Tag type ID, in range 0-VS_TAGTYPE_MAXIMUM 
 *  
 * @return Description of the given type ID 
 */
EXTERN_C
VSPSZ VSAPI tag_type_get_description(int type_id);

/**
 * Set the description for the given type ID.
 *
 * @param type_id       Tag type ID, in range VS_TAGTYPE_OEM <= type_id <= VS_TAGTYPE_MAXIMUM
 * @param description   Tag type description
 */
EXTERN_C
void VSAPI tag_type_set_description(int type_id, VSPSZ description);

/**
 * Get the database type id corresponding to the given string.
 * 
 * @param type_name    type name to look up 
 * 
 * @return <0 if not found, type ID > 0 on success
 */
EXTERN_C
int VSAPI tag_get_type_id(VSPSZ type_name);


///////////////////////////////////////////////////////////////////////////
// tag file rebuilding functions

enum VS_TAG_REBUILD_FLAGS {
   /**
    * Rebuild the tag file from scratch using the given file list. 
    * Otherwise, the tag file is rebuilt incrementally. 
    */
   VS_TAG_REBUILD_FROM_SCRATCH = 0x0001,
   /**
    * Check dates of files and only rebuild ones that are out of date, 
    * if false, all the files will be retagged.
    */
   VS_TAG_REBUILD_CHECK_DATES= 0x0002,
   /**
    * Build a symbol cross-reference.
    */
   VS_TAG_REBUILD_DO_REFS = 0x0004,
   /**
    * Retag the files in the foreground rather than queuing the 
    * files for the background tagging threads to finish. 
    */
   VS_TAG_REBUILD_SYNCHRONOUS = 0x0008,
   /**
    * Remove files from the database which no longer exist.
    */
   VS_TAG_REBUILD_REMOVE_MISSING_FILES = 0x0010,
   /**
    * Remove leftover files that are no long in the file list 
    * specified to be rebuilt. 
    */
   VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES = 0x0020
};

/** 
 * Retag all the files in the given tag file. 
 * <p> 
 * This function will start a thread which will retrieve the file list 
 * from the given tag database and schedule all the files which need to be 
 * retagged to be retagged in the background. 
 * <p> 
 * If the SYNCHRONOUS option is on, it will retrieve the file list in 
 * the foreground instead of doing that work in the background. 
 * 
 * @param pszTagDatabase   name of tag file to rebuild 
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no long in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_tag_file(VSPSZ pszTagDatabase, int rebuildFlags);

/** 
 * Retag all the files in the given workspace tag file. 
 * <p> 
 * This function will start a thread which will retrieve the file list 
 * from the given workspace and schedule all the files which need to be 
 * retagged to be retagged in the background.
 * <p> 
 * If the SYNCHRONOUS option is on, it will retrieve the file list in 
 * the foreground instead of doing that work in the background. 
 * 
 * @param pszWorkspaceFile name of workspace to get source file list from 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no long in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_workspace_tag_file(VSPSZ pszWorkspaceFile, 
                                                VSPSZ pszTagDatabase, 
                                                int rebuildFlags);

/**
 * Rebuild the tag file using the given array of source files.
 * 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no long in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * @param sourceFileArray  Array of files to retag 
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_tag_file_from_array(VSPSZ pszTagDatabase, 
                                                 int rebuildFlags,
                                                 VSHREFVAR sourceFileArray );

/**
 * Rebuild the tag file using the given list of source files.
 * 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no long in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * @param sourceFileWid    Editor control containing a list of source files, one per line
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_tag_file_from_view(VSPSZ pszTagDatabase,
                                                int rebuildFlags,
                                                int sourceFileWid );

/**
 * Rebuild the tag file using the given list of source files.
 * 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no long in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * @param pszFilename      name of file on disk containing list of 
 *                         source files to tag. 
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_tag_file_from_list_file(VSPSZ pszTagDatabase,
                                                     int rebuildFlags,
                                                     VSPSZ pszFilename );

/**
 * Rebuild the tag file using the given list of wildcards.
 * 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_FROM_SCRATCH --
 *                         Rebuild the tag file from scratch using the
 *                         given file list.  Otherwise, the tag file is
 *                         rebuilt incrementally. 
 *                         <li>VS_TAG_REBUILD_CHECK_DATES --
 *                         Check dates of files and only rebuild ones 
 *                         that are out of date, if false, all
 *                         the files will be retagged.
 *                         <li>VS_TAG_REBUILD_DO_REFS --
 *                         Build a symbol cross-reference
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Retag the files in the foreground instead
 *                         of queuing the files for the background
 *                         tagging threads to finish.
 *                         <li>VS_TAG_REBUILD_REMOVE_MISSING_FILES --
 *                         Remove files from the database which
 *                         no longer exist on disk.
 *                         <li>VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES --
 *                         Remove leftover files that are no longer in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * @param pszDirectoryPath base path to search for wildcards in    
 * @param pszWildcardOpts  command line options for wildcards 
 *                         <ul> 
 *                         <li><b>filespec</b> -- wildcard path/file specification 
 *                         <li><b>-T</b> -- find files recursively in subdirectories
 *                         <li><b>-X filespec</b> -- exclude files matching this spec
 *                         </ul>
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_build_tag_file_from_wildcards(VSPSZ pszTagDatabase, 
                                                     int rebuildFlags,
                                                     VSPSZ pszDirectoryPath, 
                                                     VSPSZ pszWildcardOpts);

/**
 * Remove all the files in the given array from the tag file. 
 * 
 * @param pszTagDatabase   name of tag file to update
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Remove the files in the foreground instead
 *                         of finishing the work using a background thread.
 *                         </ul>
 * @param sourceFileWid    Editor control containing a list of source files, one per line
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_remove_files_from_tag_file_in_array(VSPSZ pszTagDatabase, 
                                                           int rebuildFlags,
                                                           VSHREFVAR sourceFileArray );

/**
 * Remove all the files listed in the given editor control from the tag file.
 * 
 * @param pszTagDatabase   name of tag file to update
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Remove the files in the foreground instead
 *                         of finishing the work using a background thread.
 *                         </ul>
 * @param sourceFileWid    Editor control containing a list of source files, one per line
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_remove_files_from_tag_file_in_view(VSPSZ pszTagDatabase, 
                                                          int rebuildFlags, 
                                                          int sourceFileWid);

/**
 * Remove all the files listed in the given list file from the tag file.
 * 
 * @param pszTagDatabase   name of tag file to update
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Remove the files in the foreground instead
 *                         of finishing the work using a background thread.
 *                         </ul>
 * @param pszFilename      name of file on disk containing list of 
 *                         source files to remove. 
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_remove_files_from_tag_file_in_list_file(VSPSZ pszTagDatabase, 
                                                               int rebuildFlags, 
                                                               VSPSZ pszFilename);

/**
 * Remove all the files matching the given wildcards from the tag file. 
 * 
 * @param pszTagDatabase   name of tag file to rebuild
 * @param rebuildFlags     bitset of VS_TAG_REBUILD_* 
 *                         <ul> 
 *                         <li>VS_TAG_REBUILD_SYNCHRONOUS --
 *                         Remove the files in the foreground instead
 *                         of finishing the work using a background thread.
 *                         </ul>
 * @param pszDirectoryPath base path to search for wildcards in    
 * @param pszWildcardOpts  command line options for wildcards 
 *                         <ul> 
 *                         <li><b>filespec</b> -- wildcard path/file specification 
 *                         <li><b>-T</b> -- find files recursively in subdirectories
 *                         <li><b>-X filespec</b> -- exclude files matching this spec
 *                         </ul>
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_remove_files_from_tag_file_in_wildcards(VSPSZ pszTagDatabase,
                                                               int rebuildFlags, 
                                                               VSPSZ pszDirectoryPath, 
                                                               VSPSZ pszWildcardOpts);

/**
 * Cancel a tag file build or rebuild that is currently running in the background.
 * 
 * @param pszTagDatabase   name of tag file to cancel build/rebuild for 
 * @param waitForMS        set to 'true' if you want to wait for the specified 
 *                         amount of time for any existing tag file builder thread
 *                         to stop after it gets the 'cancel' signal
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_cancel_async_tag_file_build(VSPSZ pszTagDatabase, int waitForMS=0);

/**
 * Cancel all running background tag file builds or rebuilds.
 * 
 * @return 0 on success, <0 on error. 
 */
EXTERN_C int VSAPI tag_cancel_all_async_tag_file_builds();

/**
 * Get a list of all tag files currently being built or rebuilt 
 * in the background. 
 * 
 * @param tagDatabaseArray    [output] set to array of tag file names 
 * 
 * @return number of tag files returned on success, <0 on error.
 */
EXTERN_C int VSAPI tag_get_async_tag_file_builds(VSHREFVAR tagDatabaseArray);

/**
 * Check the status of the given asynchronous tag file build or rebuild.
 * 
 * @param pszTagDatabase   name of tag file to check build progress for
 * @param isRunning        set to 'true' if the build is still running
 * @param percentProgress  set to the percentage 0-100 of progres for the build
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI tag_check_async_tag_file_build(VSPSZ pszTagDatabase, 
                                                  VSHREFVAR isRunning, 
                                                  VSHREFVAR percentProgress);

#endif
// TAGS_MAIN_H
