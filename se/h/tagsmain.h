////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SETagTypes.h"
#include "tags/SETagDocCommentTypes.h"

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
#define VS_TAG_USER_VERSION_CMDATE     19000
#define VS_TAG_USER_VERSION_64GIG      20000
#define VS_TAG_USER_VERSION_OPAQUE     22001
#define VS_TAG_USER_VERSION_XXHASH     24000
#define VS_TAG_USER_VERSION_COMMENTS   25000
#define VS_TAG_USER_VERSION_NAME_BITS  25001
#define VS_TAG_USER_VERSION_GREEDY     25002
/**
 * This constant represents the latest version of the tagging database format
 * implemented in the DLL tagsdb.dll.  See {@link tag_current_version}.
 *
 * @categories Tagging_Functions
 */
#define VS_TAG_LATEST_VERSION          25002
/**
 * This constant represents the descript of the latest version of the tagging 
 * database format.  See {@link VS_TAG_LATEST_VERSION}.
 */
#define VS_TAG_LATEST_VERSION_STR "TAG_DATABASE_25.0.0"

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


// Tag type filtering flags, formerly PUSHTAG_* flags in slick.sh
// Now replaced by SE_TAG_FILTER_* in SETagFilterFlags.h
// 
// NOTE:  These constants are deprecated, use the enumerated type SETagFilterFlags instead.
//
#define VS_TAGFILTER_CASESENSITIVE     VSDEPRECATECONSTANT(SE_TAG_FILTER_CASE_SENSITIVE)
// types of tags
#define VS_TAGFILTER_PROC              VSDEPRECATECONSTANT(SE_TAG_FILTER_PROCEDURE)
#define VS_TAGFILTER_PROTO             VSDEPRECATECONSTANT(SE_TAG_FILTER_PROTOTYPE)
#define VS_TAGFILTER_DEFINE            VSDEPRECATECONSTANT(SE_TAG_FILTER_DEFINE)
#define VS_TAGFILTER_ENUM              VSDEPRECATECONSTANT(SE_TAG_FILTER_ENUM)
#define VS_TAGFILTER_GVAR              VSDEPRECATECONSTANT(SE_TAG_FILTER_GLOBAL_VARIABLE)
#define VS_TAGFILTER_TYPEDEF           VSDEPRECATECONSTANT(SE_TAG_FILTER_TYPEDEF)
#define VS_TAGFILTER_STRUCT            VSDEPRECATECONSTANT(SE_TAG_FILTER_STRUCT)
#define VS_TAGFILTER_UNION             VSDEPRECATECONSTANT(SE_TAG_FILTER_UNION)
#define VS_TAGFILTER_LABEL             VSDEPRECATECONSTANT(SE_TAG_FILTER_LABEL)
#define VS_TAGFILTER_INTERFACE         VSDEPRECATECONSTANT(SE_TAG_FILTER_INTERFACE)
#define VS_TAGFILTER_PACKAGE           VSDEPRECATECONSTANT(SE_TAG_FILTER_PACKAGE)
#define VS_TAGFILTER_VAR               VSDEPRECATECONSTANT(SE_TAG_FILTER_MEMBER_VARIABLE)
#define VS_TAGFILTER_CONSTANT          VSDEPRECATECONSTANT(SE_TAG_FILTER_CONSTANT)
#define VS_TAGFILTER_PROPERTY          VSDEPRECATECONSTANT(SE_TAG_FILTER_PROPERTY)
#define VS_TAGFILTER_LVAR              VSDEPRECATECONSTANT(SE_TAG_FILTER_LOCAL_VARIABLE)
#define VS_TAGFILTER_MISCELLANEOUS     VSDEPRECATECONSTANT(SE_TAG_FILTER_MISCELLANEOUS)
#define VS_TAGFILTER_DATABASE          VSDEPRECATECONSTANT(SE_TAG_FILTER_DATABASE)
#define VS_TAGFILTER_GUI               VSDEPRECATECONSTANT(SE_TAG_FILTER_GUI)
#define VS_TAGFILTER_INCLUDE           VSDEPRECATECONSTANT(SE_TAG_FILTER_INCLUDE)
#define VS_TAGFILTER_SUBPROC           VSDEPRECATECONSTANT(SE_TAG_FILTER_SUBPROCEDURE)
#define VS_TAGFILTER_UNKNOWN           VSDEPRECATECONSTANT(SE_TAG_FILTER_UNKNOWN)
#define VS_TAGFILTER_ANYSYMBOL         VSDEPRECATECONSTANT(SE_TAG_FILTER_ANY_SYMBOL)
#define VS_TAGFILTER_ANYTHING          VSDEPRECATECONSTANT(SE_TAG_FILTER_ANYTHING)
// classes of tag types
#define VS_TAGFILTER_ANYPROC           VSDEPRECATECONSTANT(SE_TAG_FILTER_ANY_PROCEDURE)
#define VS_TAGFILTER_ANYDATA           VSDEPRECATECONSTANT(SE_TAG_FILTER_ANY_DATA)
#define VS_TAGFILTER_ANYSTRUCT         VSDEPRECATECONSTANT(SE_TAG_FILTER_ANY+STRUCT)
// statement types
#define VS_TAGFILTER_STATEMENT         VSDEPRECATECONSTANT(SE_TAG_FILTER_STATEMENT)
// annotation types
#define VS_TAGFILTER_ANNOTATION        VSDEPRECATECONSTANT(SE_TAG_FILTER_ANNOTATION)
// tag scope
#define VS_TAGFILTER_SCOPE_PRIVATE     VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_PRIVATE)
#define VS_TAGFILTER_SCOPE_PROTECTED   VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_PROTECTED)
#define VS_TAGFILTER_SCOPE_PACKAGE     VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_PACKAGE)
#define VS_TAGFILTER_SCOPE_PUBLIC      VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_PUBLIC)
#define VS_TAGFILTER_SCOPE_STATIC      VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_STATIC)
#define VS_TAGFILTER_SCOPE_EXTERN      VSDEPRECATECONSTANT(SE_TAG_FILTER_SCOPE_EXTERN)
#define VS_TAGFILTER_ANYSCOPE          VSDEPRECATECONSTANT(SE_TAG_FILTER_ANY_SCOPE)
// tags in zip, dll, and tag files
#define VS_TAGFILTER_NOBINARY          VSDEPRECATECONSTANT(SE_TAG_FILTER_NO_BINARY)


//////////////////////////////////////////////////////////////////////
// Standard tag types, by default, always present in database
// standard type name is always "xxx" for VS_TAGTYPE_xxx,
// for example, the type name for VS_TAGTYPE_proc is "proc".
// ID's 30-127 are reserved for future use by SlickEdit.
// 
// NOTE:  These constants are deprecated, use the enumerated type SETagType instead.
//
#define VS_TAGTYPE_proc          VSDEPRECATECONSTANT(SE_TAG_TYPE_PROC)          // procedure or command
#define VS_TAGTYPE_proto         VSDEPRECATECONSTANT(SE_TAG_TYPE_PROTO)         // function prototype
#define VS_TAGTYPE_define        VSDEPRECATECONSTANT(SE_TAG_TYPE_DEFINE)        // preprocessor macro definition
#define VS_TAGTYPE_typedef       VSDEPRECATECONSTANT(SE_TAG_TYPE_TYPEDEF)       // type definition
#define VS_TAGTYPE_gvar          VSDEPRECATECONSTANT(SE_TAG_TYPE_GVAR)          // global variable declaration
#define VS_TAGTYPE_struct        VSDEPRECATECONSTANT(SE_TAG_TYPE_STRUCT)        // structure definition
#define VS_TAGTYPE_enumc         VSDEPRECATECONSTANT(SE_TAG_TYPE_ENUMC)         // enumeration value
#define VS_TAGTYPE_enum          VSDEPRECATECONSTANT(SE_TAG_TYPE_ENUM)          // enumerated type
#define VS_TAGTYPE_class         VSDEPRECATECONSTANT(SE_TAG_TYPE_CLASS)         // class definition
#define VS_TAGTYPE_union         VSDEPRECATECONSTANT(SE_TAG_TYPE_UNION)         // structure / union definition
#define VS_TAGTYPE_label         VSDEPRECATECONSTANT(SE_TAG_TYPE_LABEL)         // label
#define VS_TAGTYPE_interface     VSDEPRECATECONSTANT(SE_TAG_TYPE_INTERFACE)     // interface, eg, for Java
#define VS_TAGTYPE_constructor   VSDEPRECATECONSTANT(SE_TAG_TYPE_CONSTRUCTOR)   // class constructor
#define VS_TAGTYPE_destructor    VSDEPRECATECONSTANT(SE_TAG_TYPE_DESTRUCTOR)    // class destructor
#define VS_TAGTYPE_package       VSDEPRECATECONSTANT(SE_TAG_TYPE_PACKAGE)       // package / module / namespace
#define VS_TAGTYPE_var           VSDEPRECATECONSTANT(SE_TAG_TYPE_VAR)           // member of a class / struct / package
#define VS_TAGTYPE_lvar          VSDEPRECATECONSTANT(SE_TAG_TYPE_LVAR)          // local variable declaration
#define VS_TAGTYPE_constant      VSDEPRECATECONSTANT(SE_TAG_TYPE_CONSTANT)      // pascal constant
#define VS_TAGTYPE_function      VSDEPRECATECONSTANT(SE_TAG_TYPE_FUNCTION)      // function
#define VS_TAGTYPE_property      VSDEPRECATECONSTANT(SE_TAG_TYPE_PROPERTY)      // property?
#define VS_TAGTYPE_program       VSDEPRECATECONSTANT(SE_TAG_TYPE_PROGRAM)       // pascal program
#define VS_TAGTYPE_library       VSDEPRECATECONSTANT(SE_TAG_TYPE_LIBRARY)       // pascal library
#define VS_TAGTYPE_parameter     VSDEPRECATECONSTANT(SE_TAG_TYPE_PARAMETER)     // function or procedure parameter
#define VS_TAGTYPE_import        VSDEPRECATECONSTANT(SE_TAG_TYPE_IMPORT)        // package import or using
#define VS_TAGTYPE_friend        VSDEPRECATECONSTANT(SE_TAG_TYPE_FRIEND)        // C++ friend relationship
#define VS_TAGTYPE_database      VSDEPRECATECONSTANT(SE_TAG_TYPE_DATABASE)      // SQL/OO Database
#define VS_TAGTYPE_table         VSDEPRECATECONSTANT(SE_TAG_TYPE_TABLE)         // Database Table
#define VS_TAGTYPE_column        VSDEPRECATECONSTANT(SE_TAG_TYPE_COLUMN)        // Database Column
#define VS_TAGTYPE_index         VSDEPRECATECONSTANT(SE_TAG_TYPE_INDEX)         // Database index
#define VS_TAGTYPE_view          VSDEPRECATECONSTANT(SE_TAG_TYPE_VIEW)          // Database view
#define VS_TAGTYPE_trigger       VSDEPRECATECONSTANT(SE_TAG_TYPE_TRIGGER)       // Database trigger
#define VS_TAGTYPE_form          VSDEPRECATECONSTANT(SE_TAG_TYPE_FORM)          // GUI Form or window
#define VS_TAGTYPE_menu          VSDEPRECATECONSTANT(SE_TAG_TYPE_MENU)          // GUI Menu
#define VS_TAGTYPE_control       VSDEPRECATECONSTANT(SE_TAG_TYPE_CONTROL)       // GUI Control or Widget
#define VS_TAGTYPE_eventtab      VSDEPRECATECONSTANT(SE_TAG_TYPE_EVENTTAB)      // GUI Event table
#define VS_TAGTYPE_procproto     VSDEPRECATECONSTANT(SE_TAG_TYPE_PROCPROTO)     // Prototype for procedure
#define VS_TAGTYPE_task          VSDEPRECATECONSTANT(SE_TAG_TYPE_TASK)          // Ada task object
#define VS_TAGTYPE_include       VSDEPRECATECONSTANT(SE_TAG_TYPE_INCLUDE)       // C++ include, Ada with
#define VS_TAGTYPE_file          VSDEPRECATECONSTANT(SE_TAG_TYPE_FILE)          // COBOL file descriptor
#define VS_TAGTYPE_group         VSDEPRECATECONSTANT(SE_TAG_TYPE_GROUP)         // Container variable
#define VS_TAGTYPE_subfunc       VSDEPRECATECONSTANT(SE_TAG_TYPE_SUBFUNC)       // Nested function
#define VS_TAGTYPE_subproc       VSDEPRECATECONSTANT(SE_TAG_TYPE_SUBPROC)       // Nested procedure or cobol paragraph
#define VS_TAGTYPE_cursor        VSDEPRECATECONSTANT(SE_TAG_TYPE_CURSOR)        // Database result set cursor
#define VS_TAGTYPE_tag           VSDEPRECATECONSTANT(SE_TAG_TYPE_TAG)           // SGML or XML tag type (like a class)
#define VS_TAGTYPE_taguse        VSDEPRECATECONSTANT(SE_TAG_TYPE_TAGUSE)        // SGML or XML tag instance (like an object)
#define VS_TAGTYPE_statement     VSDEPRECATECONSTANT(SE_TAG_TYPE_STATEMENT)     // generic statement
#define VS_TAGTYPE_annotype      VSDEPRECATECONSTANT(SE_TAG_TYPE_ANNOTYPE)      // Java annotation type or C# attribute class
#define VS_TAGTYPE_annotation    VSDEPRECATECONSTANT(SE_TAG_TYPE_ANNOTATION)    // Java annotation or C# attribute instance
#define VS_TAGTYPE_call          VSDEPRECATECONSTANT(SE_TAG_TYPE_CALL)          // Function/Method call
#define VS_TAGTYPE_if            VSDEPRECATECONSTANT(SE_TAG_TYPE_IF)            // If/Switch/Case statement
#define VS_TAGTYPE_loop          VSDEPRECATECONSTANT(SE_TAG_TYPE_LOOP)          // Loop statement
#define VS_TAGTYPE_break         VSDEPRECATECONSTANT(SE_TAG_TYPE_BREAK)         // Break statement
#define VS_TAGTYPE_continue      VSDEPRECATECONSTANT(SE_TAG_TYPE_CONTINUE)      // Continue statement
#define VS_TAGTYPE_return        VSDEPRECATECONSTANT(SE_TAG_TYPE_RETURN)        // Return statement
#define VS_TAGTYPE_goto          VSDEPRECATECONSTANT(SE_TAG_TYPE_GOTO)          // Goto statement
#define VS_TAGTYPE_try           VSDEPRECATECONSTANT(SE_TAG_TYPE_TRY)           // Try/Catch/Finally statement
#define VS_TAGTYPE_pp            VSDEPRECATECONSTANT(SE_TAG_TYPE_PP)            // Preprocessing statement
#define VS_TAGTYPE_block         VSDEPRECATECONSTANT(SE_TAG_TYPE_BLOCK)         // Statement block
#define VS_TAGTYPE_mixin         VSDEPRECATECONSTANT(SE_TAG_TYPE_MIXIN)         // D language mixin construct
#define VS_TAGTYPE_target        VSDEPRECATECONSTANT(SE_TAG_TYPE_TARGET)        // Ant target
#define VS_TAGTYPE_assign        VSDEPRECATECONSTANT(SE_TAG_TYPE_ASSIGN)        // Assignment statement
#define VS_TAGTYPE_selector      VSDEPRECATECONSTANT(SE_TAG_TYPE_SELECTOR)      // Objective-C method
#define VS_TAGTYPE_undef         VSDEPRECATECONSTANT(SE_TAG_TYPE_UNDEF)         // Preprocessor macro #undef
#define VS_TAGTYPE_clause        VSDEPRECATECONSTANT(SE_TAG_TYPE_CLAUSE)        // Statement sub-clause
#define VS_TAGTYPE_cluster       VSDEPRECATECONSTANT(SE_TAG_TYPE_CLUSTER)       // Database cluster
#define VS_TAGTYPE_partition     VSDEPRECATECONSTANT(SE_TAG_TYPE_PARTITION)     // Database partition
#define VS_TAGTYPE_policy        VSDEPRECATECONSTANT(SE_TAG_TYPE_POLICY)        // Database audit policy
#define VS_TAGTYPE_profile       VSDEPRECATECONSTANT(SE_TAG_TYPE_PROFILE)       // Database user profile
#define VS_TAGTYPE_user          VSDEPRECATECONSTANT(SE_TAG_TYPE_USER)          // Database user name
#define VS_TAGTYPE_role          VSDEPRECATECONSTANT(SE_TAG_TYPE_ROLE)          // Database role
#define VS_TAGTYPE_sequence      VSDEPRECATECONSTANT(SE_TAG_TYPE_SEQUENCE)      // Database sequence
#define VS_TAGTYPE_tablespace    VSDEPRECATECONSTANT(SE_TAG_TYPE_TABLESPACE)    // Database table space
#define VS_TAGTYPE_query         VSDEPRECATECONSTANT(SE_TAG_TYPE_QUERY)         // SQL select statement
#define VS_TAGTYPE_attribute     VSDEPRECATECONSTANT(SE_TAG_TYPE_ATTRIBUTE)     // Attribute
#define VS_TAGTYPE_dblink        VSDEPRECATECONSTANT(SE_TAG_TYPE_DBLINK)        // Database link
#define VS_TAGTYPE_dimension     VSDEPRECATECONSTANT(SE_TAG_TYPE_DIMENSION)     // Database dimension
#define VS_TAGTYPE_directory     VSDEPRECATECONSTANT(SE_TAG_TYPE_DIRECTORY)     // Directory
#define VS_TAGTYPE_edition       VSDEPRECATECONSTANT(SE_TAG_TYPE_EDITION)       // Database edition
#define VS_TAGTYPE_constraint    VSDEPRECATECONSTANT(SE_TAG_TYPE_CONSTRAINT)    // Database constraint
#define VS_TAGTYPE_monitor       VSDEPRECATECONSTANT(SE_TAG_TYPE_MONITOR)       // Event monitor
#define VS_TAGTYPE_scope         VSDEPRECATECONSTANT(SE_TAG_TYPE_SCOPE)         // Statement scope block (for local tagging)
#define VS_TAGTYPE_closure       VSDEPRECATECONSTANT(SE_TAG_TYPE_CLOSURE)       // Function closure
#define VS_TAGTYPE_LASTID        VSDEPRECATECONSTANT(SE_TAG_TYPE_LASTID)        // last tag type ID
#define VS_TAGTYPE_FIRSTUSER     VSDEPRECATECONSTANT(SE_TAG_TYPE_FIRSTUSER)     // first user-defined tag type ID
#define VS_TAGTYPE_LASTUSER      VSDEPRECATECONSTANT(SE_TAG_TYPE_LASTUSER)      // last user-defined tag type ID (this is the last ID that can be created automatically by vsTagGetTypeID)
// 160-255 are for OEM use
#define VS_TAGTYPE_FIRSTOEM      VSDEPRECATECONSTANT(SE_TAG_TYPE_FIRSTOEM)      // first OEM-defined tag type ID
#define VS_TAGTYPE_LASTOEM       VSDEPRECATECONSTANT(SE_TAG_TYPE_LASTOEM)       // last OEM-defined tag type ID
#define VS_TAGTYPE_MAXIMUM       VSDEPRECATECONSTANT(SE_TAG_TYPE_MAXIMUM)       // maximum tag type ID (including mapped ids)


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
 * @return 0 on success, &lt;0 on error.  The minimum size cache allowed is 1024k.
 */
EXTERN_C
int VSAPI tag_set_cache_size(int cache_size, int cache_max);

/**
 * @return Return the actual amount of memory being used for the tag file cache. 
 *         The actual tagging cache size is determined dynamically based on
 *         the amount of memory available at startup as well as the
 *         settings for {@link def_tag_cache_size} and {@link
 *         def_tagging_cache_max_ksize}.
 */
EXTERN_C
int VSAPI tag_get_cache_size();

/** 
 * Specify whether or not to use memory mapped files for reading and writing 
 * to tag databases.  Turning this feature on effectively makes the tag file 
 * cache size irrelevent. 
 *
 * @param yes_or_no  'true' to configure database to use memory mapped files
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @note 
 * Note that this feature is not enabled on all 
 * platforms, and can be problematic on 32-bit systems due to limited amounts 
 * or memory mapping space. 
 */
EXTERN_C 
int VSAPI tag_set_use_memory_mapped_files(int yes_or_no);
/**
 * @return Return whether or not to use memory mapped files for reading and 
 * writing to tag databases. 
 *  
 * @note 
 * Note that this feature is not enabled on all 
 * platforms, and can be problematic on 32-bit systems due to limited amounts 
 * or memory mapping space. 
 */
EXTERN_C 
int VSAPI tag_get_use_memory_mapped_files();

/** 
 * Specify whether or not to use independent file caches for each database 
 * session rather than using a single shared multiple-file database cache.
 *
 * @param yes_or_no  'true' to configure database to use independent cacahing
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @note 
 * Note that enabling this feature can lead to larger amounts of memory use 
 * because the amount of memory used is no longer limited by a single cache. 
 */
EXTERN_C 
int VSAPI tag_set_use_independent_file_caching(int yes_or_no); 
/**
 * @return Return whether or not to use independent file caches for each 
 * database session rather than using a single shared multiple-file 
 * database cache.
 *  
 * @note 
 * Note that enabling this feature can lead to larger amounts of memory use 
 * because the amount of memory used is no longer limited by a single cache. 
 */
EXTERN_C 
int VSAPI tag_get_use_independent_file_caching(); 

/**
 * Create a tag database, with standard tables, index, and types.
 *
 * @param file_name        file path where to create new database
 *                         If file_name exists, it will be truncated.
 * @param db_type          (optional) if not given, creates tag database.
 *                         if (db_type==VS_DBTYPE_references), then creates
 *                         a tag references database.
 *
 * @return database handle &gt;= 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_create_db(VSPSZ file_name /*, int db_type */);

/**
 * Open an existing tag database and return a handle to the database.
 * This function opens the database for read-write access.
 *
 * @param file_name        file name of tag database to open.
 *
 * @return database handle &gt;= 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_open_db(VSPSZ file_name);

/**
 * Open an existing tag database and return a handle to the database.
 * This function opens the database for read-only access.
 *
 * @param file_name        file name of tag database to open.
 *
 * @return database handle &gt;= 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_read_db(VSPSZ file_name);

/**
 * Flush all unwritten data to disk for the database.
 *
 * @return 0 on success, &lt;0 on error.
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
 * Close the current tag database.
 *
 * @param file_name        (optional) explicite filename of database to close
 *                         otherwise the current open database is closed.
 * @param leave_open       (optional) leave the tag file open read-only
 *
 * @return 0 on success, &lt;0 on error.
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
 * Close all open tag databases.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_close_all_db();

/**
 * Display the effective version of the tagsdb.dll
 */
EXTERN_C
void VSAPI tagsdb_version();

/**
 * Return the version of the tags database currently open.
 *
 * @return VS_TAG_USER_VERSION or higher.
 */
EXTERN_C
int VSAPI tag_current_version();

/**
 * @return Return 'true' if the tag database is current open for writing. 
 */
EXTERN_C
int VSAPI tag_current_db_writable();

/**
 * Return the database description/title.
 *
 * @return database description, null terminated, or the empty string on error.
 */
EXTERN_C
VSPSZ VSAPI tag_get_db_comment();

/**
 * Sets the database description/title.
 *
 * @param comment          description or title of this database
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_db_comment(VSPSZ comment);

/**
 * Return the database flags VS_DBFLAG_*
 *
 * @return &lt;0 on error, flags bitset on success.
 */
EXTERN_C
int VSAPI tag_get_db_flags();

/**
 * Sets the database flags VS_DBFLAG_*
 *
 * @param flags            bitset of VS_DBFLAG_*
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_db_flags(int flags);


///////////////////////////////////////////////////////////////////////////
// insertion and removal of tags

/**
 * Set up for inserting a series of tags from a single file for
 * update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param file_name        full path of file the tags are located in
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_file_start(VSPSZ file_name);

/**
 * Clean up after inserting a series of tags from a single file
 * for update.  Doing this allows the tag database engine to
 * remove any tags from the database that are no longer valid.
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_insert_file_end();

/**
 * Remove all references from the given references (browse database or
 * object) file from the database.  This is an effective, but costly way
 * to perform an incremental update of the data imported from a
 * references file.  First remove all items associated with that file,
 * then insert them again.
 *
 * @param file_name        full path of file the reference info came from
 * @param remove_file      if non-zero, the file is removed from the database
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_remove_from_file(VSPSZ file_name /*, int remove_file */);


///////////////////////////////////////////////////////////////////////////
// file name handling functions

/**
 * Rename the given file.
 *
 * @param file_name        name of file to update date of tagging for
 * @param new_file_name    new file name
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_rename_file(VSPSZ file_name,VSPSZ new_file_name);

/**
 * Modify the date of tagging for the given file.  Since date of tagging
 * is not involved in indexing, this is safe to do in the record, in place.
 * This method always uses the current date when setting the date of tagging.
 *
 * @param file_name        name of file to update date of tagging for
 * @param modify_date      (optional) modification date when tagged, read from disk
 *                         if modify_date is NULL.  Format is YYYYMMDDHHMMSSmmm.
 * @param file_type        (optional) type of file
 * @param included_by      (optional) path of file including this file
 * @param lang_id          (optional) language id for file whose date is being set
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_set_date(VSPSZ file_name /*,VSPSZ modify_date,int file_type,VSPSZ included_by,VSPSZ lang_id*/);

/**
 * Retrieve the date of tagging for the given file.
 * The string returned by this function is structured such
 * that consecutive dates are ordered lexicographically,
 * and is reported in local time cooridinates (YYYYMMDDHHMMSSmmm).
 * This function has the side effect of finding and position the file iterator
 * on the given file name, returns BT_RECORD_NOT_FOUND_RC if file_name is not
 * in the database.
 *
 * @param file_name        name of file to update date of tagging for
 * @param modify_date      (reference) returns the file's modification date when tagged
 * @param included_by      (optional) path of file including this file
 *
 * @return 0 on success, &lt;0 on error.
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
 * @return 0 on success, &lt;0 on error. 
 * @deprecated Use {@link tag_set_language()}. 
 */
EXTERN_C VSDEPRECATED 
int VSAPI tag_set_extension(VSPSZ file_name, VSPSZ lang);

/** 
 * API function for retrieving the language type for the given
 * filename.  This corresponds to the p_LangId property of
 * 'file_name', not necessarily the literal file extension.
 * 
 * @param file_name     name of file to get language type for 
 * @param lang          (reference) p_LangId property for file_name
 * 
 * @return 0 on success, &lt;0 on error.
 * @deprecated Use {@link tag_get_language()}. 
 */
EXTERN_C VSDEPRECATED 
int VSAPI tag_get_extension(VSPSZ file_name, VSHREFVAR lang);

/**
 * API function for setting the language type for the given 
 * filename.  This corresponds to the p_LangId property of 
 * 'file_name', not necessarily the literal file extension.
 *  
 * @param file_name     name of file to set language type for 
 * @param lang          p_LangId property for file_name 
 *  
 * @return 0 on success, &lt;0 on error. 
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
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_get_language(VSPSZ file_name, VSHREFVAR lang);

/**
 * Retreive the name of the next file included in this tag database.
 *
 * @param file_id          id of file, from tag_get_detail()
 * @param file_name        (reference) full path of file containing tags
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_get_file(int file_id, VSHREFVAR file_name);

/**
 * Retreive the name of the first file included in this tag database.
 *
 * @param file_name        (reference) full path of file containing tags
 * @param search_for       (optional) specific file to search for (prefix search)
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_find_file(VSHREFVAR file_name /*, VSPSZ search_for*/);

/**
 * Retreive the name of the next file included in this tag database.
 *
 * @param file_name        (reference) full path of file containing tags
 *
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C
int VSAPI tag_next_file(VSHREFVAR file_name);

/**
 * Reset the file name iterator.  This should be called after 
 * using tag_find_file() or tag_next_file() to release the file 
 * iterator. 
 * 
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI tag_reset_find_file();

/**
 * Retrieve the name of the first file included by file_name
 *
 * @param file_name        full path of "main" source file
 * @param include_name     (reference) full path of included file
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_find_include_file(VSPSZ file_name, VSHREFVAR include_name);

/**
 * Retrieve the name of the next file included by file_name
 *
 * @param file_name        full path of "main" source file
 * @param include_name     (reference) full path of included file
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_next_include_file(VSPSZ file_name, VSHREFVAR include_name);

/**
 * Retreive the name of first the source file that included (directly
 * or indirectly), the given file (expected to be an include file).
 *
 * @param file_name        full path of file that was included
 * @param included_by      (reference) full path of source file
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_find_included_by(VSPSZ file_name, VSHREFVAR included_by);

/**
 * Retreive the name of next the source file that included (directly
 * or indirectly), the given file (expected to be an include file).
 *
 * @param file_name        full path of file that was included
 * @param included_by      (reference) full path of source file
 *
 * @return 0 on success, &lt;0 on error.
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
 * @return 0 on success, &lt;0 on error. 
 * @deprecated Use {@link tag_find_language()}. 
 */ 
EXTERN_C VSDEPRECATED 
int VSAPI tag_find_extension(VSHREFVAR lang /*, VSPSZ search_for*/);

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_extension} (above). 
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, &lt;0 on error.
 * @deprecated Use {@link tag_next_language()}. 
 */
EXTERN_C VSDEPRECATED 
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
 * @return 0 on success, &lt;0 on error. 
 */ 
EXTERN_C
int VSAPI tag_find_language(VSHREFVAR lang, VSPSZ search_for VSDEFAULT(0));

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_language} (above). 
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_next_language(VSHREFVAR lang);

/** 
 * Reset the find language iterator.
 * 
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_reset_find_language();


///////////////////////////////////////////////////////////////////////////
// type name handling functions

/**
 * Retreive the name of the next type included in this tag database.
 *
 * @param type_id          id of type, from tag_get_detail()
 * @param type_name        (reference) full path of type containing tags
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_get_type(int type_id, VSHREFVAR type_name);

/**
 * Retreive the name of the first type included in this tag database.
 *
 * @param type_name        (reference) full path of type containing tags
 * @param search_for       (optional) specific type to search for (prefix search)
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_find_type(VSHREFVAR type_name /*, VSPSZ search_for*/);

/**
 * Retreive the name of the next type included in this tag database.
 *
 * @param type_name        (reference) full path of type containing tags
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_next_type(VSHREFVAR type_name);
/**
 * Reset the type iterator
 */
EXTERN_C
int VSAPI tag_reset_find_type();

/**
 * Filter the given tag type based on the given filter flags
 *
 * @param type_id          tag type ID
 * @param filter_flags     SE_TAG_FILTER_*
 * @param type_name        (optional) look up type ID using this name
 * @param tag_flags        (optional) check tag flags for SE_TAG_FLAG_MAYBE_VAR
 *
 * @return 1 if the type is allowed according to the flags, 0 if not.
 */
EXTERN_C
int VSAPI tag_filter_type(int type_id, int filter_flags /*, VSPSZ type_name, int tag_flags*/);

/**
 * Register a new OEM-defined type.
 *
 * @param type_id              Tag type ID, in range SE_TAG_TYPE_OEM <= type_id <= SE_TAG_TYPE_MAXIMUM
 * @param pszTypeName          Tag type name
 * @param is_container         1=tag type is a container (i.e. can have members) 
 * @param description          (optional) description of the new tag type
 * @param filterFlags          (optional) SE_TAG_FILTER_* 
 *
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C
int VSAPI tag_register_type(int type_id, VSPSZ pszTypeName, int is_container /*, VSPSZ description=NULL, int filterFlags=0*/);

/**
 * Unregister a OEM-defined type.
 *
 * @param type_id Tag type ID, in range SE_TAG_TYPE_OEM <= type_id <= SE_TAG_TYPE_MAXIMUM
 */
EXTERN_C
void VSAPI tag_unregister_type(int type_id);

/**
 * Get the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range 0-SE_TAG_TYPE_MAXIMUM
 *
 * @return Filter flags for type ID.
 */
EXTERN_C
int VSAPI tag_type_get_filter(int type_id);

/**
 * Set the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range SE_TAG_TYPE_OEM <= type_id <= SE_TAG_TYPE_MAXIMUM
 * @param filter_flags New filter flags. See SE_TAG_FILTER_*
 */
EXTERN_C
void VSAPI tag_type_set_filter(int type_id,int filter_flags);

/** 
 * Get the optional text description of the given type ID (for screen display) 
 *
 * @param type_id Tag type ID, in range 0-SE_TAG_TYPE_MAXIMUM 
 *  
 * @return Description of the given type ID 
 */
EXTERN_C
VSPSZ VSAPI tag_type_get_description(int type_id);

/**
 * Set the description for the given type ID.
 *
 * @param type_id       Tag type ID, in range SE_TAG_TYPE_OEM <= type_id <= SE_TAG_TYPE_MAXIMUM
 * @param description   Tag type description
 */
EXTERN_C
void VSAPI tag_type_set_description(int type_id, VSPSZ description);

/**
 * Get the database type id corresponding to the given string.
 * 
 * @param type_name    type name to look up 
 * 
 * @return &lt;0 if not found, type ID > 0 on success
 */
EXTERN_C
int VSAPI tag_get_type_id(VSPSZ type_name);

/** 
 * @return 
 * Return the bitmap index for the given tag type with the given set of flags.
 * 
 * @param tag_type    tag type ID (SE_TAG_TYPE_*)
 * @param tag_flags   tag flags (bitset of SE_TAG_FLAG_*)
 */
EXTERN_C 
int VSAPI tag_get_bitmap_for_type(int tag_type_id, VSINT64Param tag_flags=SE_TAG_FLAG_NULL, VSHREFVAR pic_overlay=0);

/**
 * @return 
 * Return the tag type ID of the first tag type that uses the given bitmap.
 * 
 * @param pic_member    symbol bitmap index (from find_index) 
 * @param first_type_id start searching at the given type index (SE_TAG_TYPE_*)
 */
EXTERN_C 
int VSAPI tag_get_type_for_bitmap(int pic_member, int first_type_id=0);


///////////////////////////////////////////////////////////////////////////
// language support query functions

/**
 * Check if there is a parsing callback registered for the given language, 
 * or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_list_tags(VSPLSTR langId);

/**
 * @return 
 * Return 'true' if local variable tagging is supported for the given language. 
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_list_locals(VSPLSTR langId);

/**
 * @return 
 * Return 'true' if statement-level tagging is supported for the given language.
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_list_statements(VSPLSTR langId);

/**
 * @return 
 * Return 'true' if tokenization is supported for the given language. 
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_tokenlist_support(VSPLSTR langId);

/**
 * @return 
 * Return 'true' if the given language's parser creates positional keywords tokens.
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_positional_keywords_support(VSPLSTR langId);

/**
 * @return 
 * Return 'true' if the given language's parser supports incremental tagging.
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_incremental_support(VSPLSTR langId);

/**
 * Check if there is an expression info callback registered for the 
 * given language, or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_get_id_expr_info(VSPLSTR langId);

/**
 * Check if there is a find tags callback registered for the 
 * given language, or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 */
EXTERN_C int VSAPI tag_lang_has_find_tags(VSPLSTR langId);


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
   VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES = 0x0020,
   /**
    * Skip files that are not already in the tag file.
    */
   VS_TAG_REBUILD_SKIP_MISSING_FILES = 0x0040,
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
 * @return 0 on success, &lt;0 on error. 
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
 * @return 0 on success, &lt;0 on error. 
 */
EXTERN_C int VSAPI tag_build_workspace_tag_file(VSPSZ pszWorkspaceFile, 
                                                VSPSZ pszTagDatabase, 
                                                int rebuildFlags);

/** 
 * Retag all the files in the given project-specific tag file.
 * <p> 
 * This function will start a thread which will retrieve the file list 
 * from the given project and schedule all the files which need to be 
 * retagged to be retagged in the background.
 * <p> 
 * If the SYNCHRONOUS option is on, it will retrieve the file list in 
 * the foreground instead of doing that work in the background. 
 * 
 * @param pszWorkspaceFile name of workspace the project belongs to
 * @param pszWorkspaceFile name of project file to get source file list from 
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
 * @return 0 on success, &lt;0 on error. 
 */
EXTERN_C int VSAPI tag_build_project_tag_file(VSPSZ pszWorkspaceFile, 
                                              VSPSZ pszProjectFile,
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
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param sourceFileArray  Array of files to retag 
 * 
 * @return 0 on success, &lt;0 on error. 
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
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param sourceFileWid    Editor control containing a list of source files, one per line
 * 
 * @return 0 on success, &lt;0 on error. 
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
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param pszFilename      name of file on disk containing list of 
 *                         source files to tag. 
 * 
 * @return 0 on success, &lt;0 on error. 
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
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param pszDirectoryPath base path to search for wildcards in    
 * @param pszWildcardOpts  command line options for wildcards 
 *                         <ul> 
 *                         <li><b>filespec</b> -- wildcard path/file specification 
 *                         <li><b>-T</b> -- find files recursively in subdirectories
 *                         <li><b>-X filespec</b> -- exclude files matching this spec
 *                         </ul>
 * 
 * @return 0 on success, &lt;0 on error. 
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
 * @param sourceFileArray  Slick-C array of source files
 * 
 * @return 0 on success, &lt;0 on error. 
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
 * @return 0 on success, &lt;0 on error. 
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
 * @return 0 on success, &lt;0 on error. 
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
 * @return 0 on success, &lt;0 on error. 
 */
EXTERN_C int VSAPI tag_remove_files_from_tag_file_in_wildcards(VSPSZ pszTagDatabase,
                                                               int rebuildFlags, 
                                                               VSPSZ pszDirectoryPath, 
                                                               VSPSZ pszWildcardOpts);

/**
 * Copy all the data from an older version of the tag database to a newer version. 
 * The function will also adjust filenames to correspond to the directory which 
 * the new tag database is located in. 
 * 
 * @param pszOldTagDatabase        tag database to copy data from
 * @param pszNewTagDatabase        tag database to create 
 * @param slickcProgressCallback   index of Slick-C function to call to report progress 
 * @param startPercent             start percentage of progress at (0-100) 
 * @param finalPercent             final percentage of progress at (0-100)
 * 
 * @return 0 on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_update_tag_file_to_latest_version(VSPSZ pszOldTagDatabase,
                                                         VSPSZ pszNewTagDatabase,
                                                         int slickcProgressCallback=0,
                                                         int startPercent=0,
                                                         int finalPercent=100);

/**
 * Cancel a tag file build or rebuild that is currently running in the background.
 * 
 * @param pszTagDatabase   name of tag file to cancel build/rebuild for 
 * @param waitForMS        set to 'true' if you want to wait for the specified 
 *                         amount of time for any existing tag file builder thread
 *                         to stop after it gets the 'cancel' signal
 * 
 * @return 0 on success, &lt;0 on error. 
 */
EXTERN_C int VSAPI tag_cancel_async_tag_file_build(VSPSZ pszTagDatabase, int waitForMS=0);

/**
 * Cancel all running background tag file builds or rebuilds.
 * 
 * @return 0 on success, &lt;0 on error. 
 */
EXTERN_C int VSAPI tag_cancel_all_async_tag_file_builds();

/**
 * Get a list of all tag files currently being built or rebuilt 
 * in the background. 
 * 
 * @param tagDatabaseArray    [output] set to array of tag file names 
 * 
 * @return number of tag files returned on success, &lt;0 on error.
 */
EXTERN_C int VSAPI tag_get_async_tag_file_builds(VSHREFVAR tagDatabaseArray);

/**
 * Check the status of the given asynchronous tag file build or rebuild.
 * 
 * @param pszTagDatabase   name of tag file to check build progress for
 * @param isRunning        set to 'true' if the build is still running
 * @param percentProgress  set to the percentage 0-100 of progres for the build
 * 
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI tag_check_async_tag_file_build(VSPSZ pszTagDatabase, 
                                                  VSHREFVAR isRunning, 
                                                  VSHREFVAR percentProgress);

/**
 * Initialize search results context table.
 * 
 * @param buffer_id     buffer id for file
 * 
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI tag_search_result_context_start(int buffer_id);
/**
 * Free search results context helper data.
 * 
 * @param buffer_id     buffer id for file
 * 
 */
EXTERN_C void VSAPI tag_search_result_context_end(int buffer_id);
/**
 * For search results, return context index for the starting 
 * linenum, seekpos.  Index is *not* equivalent to the context 
 * id returned from tagging. index is offset into cached tagging
 * table optimized for search results. 
 * 
 * @param buffer_id     buffer id for file
 * @param linenum       linenum to start search
 * @param seekpos       seek positions to start search
 * 
 * @return 0 on success, &lt;0 on no context found
 */
EXTERN_C int VSAPI tag_search_result_context_find(int buffer_id, int linenum, int seekpos);
/**
 * See {@link tag_search_result_context_find}.
 * 
 * @param buffer_id     buffer id for file
 * @param context_index 
 * @param context_type  [output] type of context
 * @param context_line  [output] starting linenum for context
 * @param context_name  [output] caption for context
 * 
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI tag_search_result_context_get_info(int buffer_id, int context_index, VSHREFVAR context_type, VSHREFVAR context_line, VSHREFVAR context_name);
/**
 * For search result context index, return parent context ids. 
 * See {@link tag_search_result_context_find}.
 * 
 * @param buffer_id     buffer id for file
 * @param context_index
 * @param context_ids   [output] set to array of parent context
 * 
 * @return 0 on success, &lt;0 on error
 */
EXTERN_C int VSAPI tag_search_result_context_get_contexts(int buffer_id, int context_index, VSHREFVAR context_ids);
/**
 * Set context types to show in search results. 
 * See {@link tag_search_result_context_find}.
 * 
 * @param buffer_id     array of context types to show in 
 *                      results
 * 
 */
EXTERN_C void VSAPI tag_search_result_context_set_types(VSHREFVAR context_types);
