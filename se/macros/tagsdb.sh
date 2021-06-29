////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#ifndef TAGSDB_SH
#define TAGSDB_SH
#pragma option(metadata,"tags.e")

//////////////////////////////////////////////////////////////////////
// Database file types that can be opened using this library
//
const VS_DBTYPE_tags=        0;
const VS_DBTYPE_references=  1;
const VS_DBTYPE_msbrowse=    2;

//////////////////////////////////////////////////////////////////////
// Database flags indicating attributes for this tag database.
// The low sixteen bits are reserved for Visual SlickEdit development.
//
const VS_DBFLAG_occurrences=    0x00000001;  // tag occurrences
const VS_DBFLAG_no_occurrences= 0x00000002;  // user specifically said no to occurrences
const VS_DBFLAG_reserved=       0x0000fffc;  // future expansion, reseerved by Visual SlickEdit
const VS_DBFLAG_user=           0x00010000;  // user flags

//////////////////////////////////////////////////////////////////////
// Database version, correspond to version of Visual SlickEdit, release 3.0
//
const VS_TAG_USER_VERSION=             3000;
const VS_TAG_USER_VERSION_WIDE_FLAGS=  3100;
const VS_TAG_USER_VERSION_FILE_TYPES=  4000;
const VS_TAG_USER_VERSION_CASE_FIXED=  4100;
const VS_TAG_USER_VERSION_EXCEPTIONS=  4200;
const VS_TAG_USER_VERSION_COPY_FILES=  4300;
const VS_TAG_USER_VERSION_RELATIVE=    4400;
const VS_TAG_USER_VERSION_LARGE_IDS=   5000;
const VS_TAG_USER_VERSION_DISK_HASH=   5100;
const VS_TAG_USER_VERSION_REFERENCES=  5200;
const VS_TAG_USER_VERSION_COMPACT=     5300;
const VS_TAG_USER_VERSION_EXTENSIONS=  5400;
const VS_TAG_USER_VERSION_OCCURRENCES= 5500;
const VS_TAG_USER_VERSION_NO_NEXTPREV= 5600;
const VS_TAG_USER_VERSION_UTF8=        7000;
const VS_TAG_USER_VERSION_FILECASE=    7100;
const VS_TAG_USER_VERSION_TEMPLATES=   9200;
const VS_TAG_USER_VERSION_NAMESPACES=  9300;
const VS_TAG_USER_VERSION_STATEMENTS= 10000;
const VS_TAG_USER_VERSION_QPARENTS=   10101;
const VS_TAG_USER_VERSION_ADHOC_REFS= 11000;
const VS_TAG_USER_VERSION_CLASS_TAG=  11001;
const VS_TAG_USER_VERSION_CASE_SENS=  12000;
const VS_TAG_USER_VERSION_UTC_TIMES=  12001;
const VS_TAG_USER_VERSION_LESS_DUPS=  16000;
const VS_TAG_USER_VERSION_LARGE_KEYS= 16001;
const VS_TAG_USER_VERSION_LINE_KEYS=  17000;
const VS_TAG_USER_VERSION_REBUILD_17= 17001;
const VS_TAG_USER_VERSION_CMDATE=     19000;
const VS_TAG_USER_VERSION_64GIG=      20000;
const VS_TAG_USER_VERSION_OPAQUE=     22001;
const VS_TAG_USER_VERSION_XXHASH=     24000;
const VS_TAG_USER_VERSION_COMMENTS=   25000;
const VS_TAG_USER_VERSION_NAME_BITS=  25001;
const VS_TAG_USER_VERSION_GREEDY=     25002;
/**
 * This constant represents the latest version of the tagging database format implemented in the DLL tagsdb.dll.
 *
 * @see tag_current_version
 */
const VS_TAG_LATEST_VERSION=          25002;


/**
 * Standard tag types, by default, always present in database
 * standard type name is always "xxx" for SE_TAG_TYPE_XXX,
 * for example, the type name for SE_TAG_TYPE_PROC is "proc".
 * ID's 83-127 are reserved for future use by SlickEdit.
 */
enum SETagType {

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
    * If or switch-sase statement
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
    * Switch statement
    */
   SE_TAG_TYPE_SWITCH          = 91,
   /**
    * Source file region (#region ... #endregion)
    */
   SE_TAG_TYPE_REGION     = 92,
   /**
    * Source file general note (#note)
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


/**
 * Tag type filtering flags.  These filters are used by various methods 
 * to narrow down a tagging search to a specific set of symbol types. 
 */
enum_flags SETagFilterFlags {

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
    SE_TAG_FILTER_NULL            = 0x00000000,
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
    * Future flag to be used for an additional scope type.
    * @see SE_TAG_FLAG_EXTERN
    * @see SE_TAG_FLAG_STATIC
    */
   SE_TAG_FILTER_SCOPE_FUTURE        = 0x40000000,
    /**
     * Composite set of flags for any scope, public, private, protected, extern.
     */
   SE_TAG_FILTER_ANY_SCOPE          = (SE_TAG_FILTER_SCOPE_STATIC    |
                                       SE_TAG_FILTER_SCOPE_EXTERN    |
                                       SE_TAG_FILTER_SCOPE_FUTURE    |
                                       SE_TAG_FILTER_ANY_ACCESS),

   /**
    * Allows symbols from binary files to match, for example, 
    * tags in zip, dll, and tag files 
    *  
    * @deprecated This flag had to be moved to prevent sign-extension.  See below. 
    */
   SE_TAG_FILTER_NO_BINARY_OLD      = 0x80000000,
   /**
    * Allows symbols from binary files to match, for example, 
    * tags in zip, dll, and tag files
    */
   SE_TAG_FILTER_NO_BINARY          = 0x100000000,

};

//////////////////////////////////////////////////////////////////////
// Tag type filtering flags, formerly PUSHTAG_* flags in slick.sh
//
#define VS_TAGFILTER_CASESENSITIVE     VSDEPRECATECONSTANT(0x00000001)
// types of tags
#define VS_TAGFILTER_PROC              VSDEPRECATECONSTANT(0x00000002)
#define VS_TAGFILTER_PROTO             VSDEPRECATECONSTANT(0x00000004)
#define VS_TAGFILTER_DEFINE            VSDEPRECATECONSTANT(0x00000008)
#define VS_TAGFILTER_ENUM              VSDEPRECATECONSTANT(0x00000010)
#define VS_TAGFILTER_GVAR              VSDEPRECATECONSTANT(0x00000020)
#define VS_TAGFILTER_TYPEDEF           VSDEPRECATECONSTANT(0x00000040)
#define VS_TAGFILTER_STRUCT            VSDEPRECATECONSTANT(0x00000080)
#define VS_TAGFILTER_UNION             VSDEPRECATECONSTANT(0x00000100)
#define VS_TAGFILTER_LABEL             VSDEPRECATECONSTANT(0x00000200)
#define VS_TAGFILTER_INTERFACE         VSDEPRECATECONSTANT(0x00000400)
#define VS_TAGFILTER_PACKAGE           VSDEPRECATECONSTANT(0x00000800)
#define VS_TAGFILTER_VAR               VSDEPRECATECONSTANT(0x00001000)
#define VS_TAGFILTER_CONSTANT          VSDEPRECATECONSTANT(0x00002000)
#define VS_TAGFILTER_PROPERTY          VSDEPRECATECONSTANT(0x00004000)
#define VS_TAGFILTER_LVAR              VSDEPRECATECONSTANT(0x00008000)
#define VS_TAGFILTER_MISCELLANEOUS     VSDEPRECATECONSTANT(0x00010000)
#define VS_TAGFILTER_DATABASE          VSDEPRECATECONSTANT(0x00020000)
#define VS_TAGFILTER_GUI               VSDEPRECATECONSTANT(0x00040000)
#define VS_TAGFILTER_INCLUDE           VSDEPRECATECONSTANT(0x00080000)
#define VS_TAGFILTER_SUBPROC           VSDEPRECATECONSTANT(0x00100000)
#define VS_TAGFILTER_UNKNOWN           VSDEPRECATECONSTANT(0x00200000)
#define VS_TAGFILTER_ANYSYMBOL         VSDEPRECATECONSTANT(0x003ffffe)
#define VS_TAGFILTER_ANYTHING          VSDEPRECATECONSTANT(0x7ffffffe)
// classes of tag xtypes
#define VS_TAGFILTER_ANYPROC_NO_PROTO  VSDEPRECATECONSTANT(VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC)
#define VS_TAGFILTER_ANYPROC           VSDEPRECATECONSTANT(VS_TAGFILTER_PROTO|VS_TAGFILTER_PROC|VS_TAGFILTER_SUBPROC)
#define VS_TAGFILTER_ANYDATA           VSDEPRECATECONSTANT(VS_TAGFILTER_GVAR|VS_TAGFILTER_VAR|VS_TAGFILTER_LVAR|VS_TAGFILTER_PROPERTY|VS_TAGFILTER_CONSTANT)
#define VS_TAGFILTER_ANYSTRUCT         VSDEPRECATECONSTANT(VS_TAGFILTER_STRUCT|VS_TAGFILTER_UNION|VS_TAGFILTER_INTERFACE)
#define VS_TAGFILTER_ANYCONSTANT       VSDEPRECATECONSTANT(VS_TAGFILTER_DEFINE|VS_TAGFILTER_ENUM|VS_TAGFILTER_CONSTANT)
// statement types
#define VS_TAGFILTER_STATEMENT         VSDEPRECATECONSTANT(0x00400000)
// annotation types
#define VS_TAGFILTER_ANNOTATION        VSDEPRECATECONSTANT(0x00800000)
// tag scope
#define VS_TAGFILTER_SCOPE_PRIVATE     VSDEPRECATECONSTANT(0x01000000)
#define VS_TAGFILTER_SCOPE_PROTECTED   VSDEPRECATECONSTANT(0x02000000)
#define VS_TAGFILTER_SCOPE_PACKAGE     VSDEPRECATECONSTANT(0x04000000)
#define VS_TAGFILTER_SCOPE_PUBLIC      VSDEPRECATECONSTANT(0x08000000)
#define VS_TAGFILTER_SCOPE_STATIC      VSDEPRECATECONSTANT(0x10000000)
#define VS_TAGFILTER_SCOPE_EXTERN      VSDEPRECATECONSTANT(0x20000000)
#define VS_TAGFILTER_ANYACCESS         VSDEPRECATECONSTANT(0x0f000000)
#define VS_TAGFILTER_ANYSCOPE          VSDEPRECATECONSTANT(0x7f000000)
// tags in zip, dll, and tag files
#define VS_TAGFILTER_NOBINARY          VSDEPRECATECONSTANT(0x80000000)


//////////////////////////////////////////////////////////////////////
// Update flags for updating current context, statements, all locals
//
const VS_UPDATEFLAG_context=   0x0001;  // Find all the context tags in a context or a file
const VS_UPDATEFLAG_statement= 0x0002;  // Find all statement tags in a context or a file
const VS_UPDATEFLAG_list_all=  0x0004;  // List all locals in the function rather just those in scope
const VS_UPDATEFLAG_tokens=    0x0008;  // Save the token list
const VS_UPDATEFLAG_test_only= 0x0010;  // Test if context is up-to-date only


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
enum_flags SETagFlags {
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
    * Unique flag for public access, only used by Symbol Coloring
    */
   SE_TAG_FLAG_UNIQ_PUBLIC       = 0x10000000,
   /**
    * Unique flag for package access, only used by Symbol Coloring
    */
   SE_TAG_FLAG_UNIQ_PACKAGE      = 0x20000000,

   /**
    * Ignore this symbol for any purpose other than the Defs tool window.
    */
   SE_TAG_FLAG_OUTLINE_ONLY      = 0x0000000100000000,
   /**
    * Hide this symbol when displaying in the Defs tool window
    */
   SE_TAG_FLAG_OUTLINE_HIDE      = 0x0000000200000000,

   /**
    * This symbol overrides an earlier definition of the same symbol. 
    */
   SE_TAG_FLAG_OVERRIDE          = 0x0000000400000000,
   /**
    * This local variable shadows an earlier definition of the same symbol, 
    * or an be shadowed by another subsequent local variable. 
    */
   SE_TAG_FLAG_SHADOW            = 0x0000000800000000,

   /**
    * This flag indicates that for this language, the logic to propagate tag 
    * flags, such as static, inline, virtual, public, private, protected, etc., 
    * from declarations to definitinos (and vice-versa), is never required. 
    * Using this flag can improve tag file build performance by eliminating 
    * any attempt to propagate tag flags. 
    */
   SE_TAG_FLAG_NO_PROPAGATE      = 0x0000001000000000,

   /**
    * internal access
    */
   SE_TAG_FLAG_INTERNAL          = 0x0000002000000000,

   /**
    * access flags including internal (public/protected/private/package/internal)
    */
   SE_TAG_FLAG_INTERNAL_ACCESS   = 0x000000200000000C,

   /**
    * This flag indicates that the return type of a variable is inferred 
    * from the type of the varible's initializer value.  For example, 
    * "auto xxx = yyy;" "xxx" assumes the return type of "yyy".    
    */
   SE_TAG_FLAG_INFERRED          = 0x0000004000000000,

   /**
    * C++ constexpr
    */
   SE_TAG_FLAG_CONSTEXPR         = 0x0000008000000000,

   /**
    * Indicates that this symbol has not documentation comment. 
    * This is set to handle the negative case for documentation comment lookup 
    * optimization using a minimal amount of memory. 
    */
   SE_TAG_FLAG_NO_COMMENT        = 0x0000010000000000,

   /**
    * C++ consteval
    */
   SE_TAG_FLAG_CONSTEVAL         = 0x0000020000000000,
   /**
    * C++ constinit
    */
   SE_TAG_FLAG_CONSTINIT         = 0x0000040000000000,
   /**
    * Export symbol from module (C++ 20)
    */
   SE_TAG_FLAG_EXPORT            = 0x0000080000000000,

};

//////////////////////////////////////////////////////////////////////
// Flags associated with tags, denoting access restrictions and
// and other attributes of class members (proc's, proto's, and var's)
//    NOT virtual and NOT static implies normal class method
//    NOT protected and NOT private implies public
//    NOT const implies normal read/write access
//    NOT volatile implies normal optimizations are safe
//    NOT template implies normal class definition
//
#define VS_TAGFLAG_virtual      VSDEPRECATECONSTANT(SE_TAG_FLAG_VIRTUAL)        // virtual function (instance)
#define VS_TAGFLAG_static       VSDEPRECATECONSTANT(SE_TAG_FLAG_STATIC)         // static method / member (class)
#define VS_TAGFLAG_access       VSDEPRECATECONSTANT(SE_TAG_FLAG_ACCESS)         // access flags (public/protected/private/package)
#define VS_TAGFLAG_public       VSDEPRECATECONSTANT(SE_TAG_FLAG_PUBLIC)         // public access (test equality with flags&access)
#define VS_TAGFLAG_protected    VSDEPRECATECONSTANT(SE_TAG_FLAG_PROTECTED)      // protected access
#define VS_TAGFLAG_private      VSDEPRECATECONSTANT(SE_TAG_FLAG_PRIVATE)        // private access
#define VS_TAGFLAG_package      VSDEPRECATECONSTANT(SE_TAG_FLAG_PACKAGE)        // package access (for Java)
#define VS_TAGFLAG_const        VSDEPRECATECONSTANT(SE_TAG_FLAG_CONST)          // const
#define VS_TAGFLAG_final        VSDEPRECATECONSTANT(SE_TAG_FLAG_FINAL)          // final
#define VS_TAGFLAG_abstract     VSDEPRECATECONSTANT(SE_TAG_FLAG_ABSTRACT)       // abstract/deferred method
#define VS_TAGFLAG_inline       VSDEPRECATECONSTANT(SE_TAG_FLAG_INLINE)         // inline / out-of-line method
#define VS_TAGFLAG_operator     VSDEPRECATECONSTANT(SE_TAG_FLAG_OPERATOR)       // overloaded operator
#define VS_TAGFLAG_constructor  VSDEPRECATECONSTANT(SE_TAG_FLAG_CONSTRUCTOR)    // class constructor
#define VS_TAGFLAG_volatile     VSDEPRECATECONSTANT(SE_TAG_FLAG_VOLATILE)       // volatile method or data
#define VS_TAGFLAG_template     VSDEPRECATECONSTANT(SE_TAG_FLAG_TEMPLATE)       // template class
#define VS_TAGFLAG_inclass      VSDEPRECATECONSTANT(SE_TAG_FLAG_INCLASS)        // part of class interface?
#define VS_TAGFLAG_destructor   VSDEPRECATECONSTANT(SE_TAG_FLAG_DESTRUCTOR)     // class destructor
#define VS_TAGFLAG_const_destr  VSDEPRECATECONSTANT(SE_TAG_FLAG_CONST_DESTR)    // class constructor or destructor
#define VS_TAGFLAG_synchronized VSDEPRECATECONSTANT(SE_TAG_FLAG_SYNCHRONIZED)   // synchronized (thread safe)
#define VS_TAGFLAG_transient    VSDEPRECATECONSTANT(SE_TAG_FLAG_TRANSIENT)      // transient / persistent data
#define VS_TAGFLAG_native       VSDEPRECATECONSTANT(SE_TAG_FLAG_NATIVE)         // Java native method?
#define VS_TAGFLAG_macro        VSDEPRECATECONSTANT(SE_TAG_FLAG_MACRO)          // Tag was part of macro expansion?
#define VS_TAGFLAG_extern       VSDEPRECATECONSTANT(SE_TAG_FLAG_EXTERN)         // "extern" C prototype (not local)
#define VS_TAGFLAG_maybe_var    VSDEPRECATECONSTANT(SE_TAG_FLAG_MAYBE_VAR)      // Prototype which could be a variable.
                                                                                // Anonymous union.  Unnamed structs.
#define VS_TAGFLAG_anonymous    VSDEPRECATECONSTANT(SE_TAG_FLAG_ANONYMOUS)      // Anonymous structure or class
#define VS_TAGFLAG_mutable      VSDEPRECATECONSTANT(SE_TAG_FLAG_MUTABLE)        // mutable C++ class member
#define VS_TAGFLAG_extern_macro VSDEPRECATECONSTANT(SE_TAG_FLAG_EXTERN_MACRO)   // external macro (COBOL copy file)
#define VS_TAGFLAG_linkage      VSDEPRECATECONSTANT(SE_TAG_FLAG_LINKAGE)        // 01 level var in COBOL linkage section
#define VS_TAGFLAG_partial      VSDEPRECATECONSTANT(SE_TAG_FLAG_PARTIAL)        // For C# partial class, struct, or interface
#define VS_TAGFLAG_ignore       VSDEPRECATECONSTANT(SE_TAG_FLAG_IGNORE)         // Tagging should ignore this tag
#define VS_TAGFLAG_forward      VSDEPRECATECONSTANT(SE_TAG_FLAG_FORWARD)        // Forward class/interface/struct/union declaration
#define VS_TAGFLAG_opaque       VSDEPRECATECONSTANT(SE_TAG_FLAG_OPAQUE)         // Opaque enumerated type (unlike C/C++ enum)
#define VS_TAGFLAG_restartable  VSDEPRECATECONSTANT(SE_TAG_FLAG_RESTARTABLE)    // Can tagging be restarted at this symbol?
#define VS_TAGFLAG_implicit     VSDEPRECATECONSTANT(SE_TAG_FLAG_IMPLICIT)       // Implicitely declared local variable
#define VS_TAGFLAG_unscoped     VSDEPRECATECONSTANT(SE_TAG_FLAG_UNSCOPED)       // Local variable is visible to entire function

#define VS_TAGFLAG_maybe_proto     VS_TAGFLAG_maybe_var                         // variable which could be a prototype
#define VS_TAGFLAG_anonymous_union VS_TAGFLAG_maybe_var                         // Anononymous union or unnamed struct

// These two are needed only for Symbol coloring
#define VS_TAGFLAG_uniq_public  VSDEPRECATECONSTANT(SE_TAG_FLAG_UNIQ_PUBLIC)    // Unique flag for public access
#define VS_TAGFLAG_uniq_package VSDEPRECATECONSTANT(SE_TAG_FLAG_UNIQ_PACKAGE)   // Unique flag for package access

//////////////////////////////////////////////////////////////////////
// Flags passed to tag to extract specific information about the
// current tag, using tag_get_detail(), below
//
const VS_TAGDETAIL_max= 256;

const VS_TAGDETAIL_current=     (VS_TAGDETAIL_max*0);
const VS_TAGDETAIL_context=     (VS_TAGDETAIL_max*1);
const VS_TAGDETAIL_local=       (VS_TAGDETAIL_max*2);
const VS_TAGDETAIL_match=       (VS_TAGDETAIL_max*3);
const VS_TAGDETAIL_statement=   (VS_TAGDETAIL_max*4);

const VS_TAGDETAIL_name=           0;  // (string) tag name
const VS_TAGDETAIL_type=           1;  // (string) tag type
const VS_TAGDETAIL_type_id=        2;  // (int) unique id for tag type (SE_TAG_TYPE_*)
const VS_TAGDETAIL_file_name=      3;  // (string) full path of file the tag is located in
const VS_TAGDETAIL_file_date=      4;  // (string) modification data of file when tagged
const VS_TAGDETAIL_file_line=      5;  // (int) line number of tag within file
const VS_TAGDETAIL_file_id=        6;  // (int) unique id for file the tag is located in
const VS_TAGDETAIL_class_simple=   7;  // (string) name of class the tag is present in
const VS_TAGDETAIL_class_name=     8;  // (string) name of class with outer classes
const VS_TAGDETAIL_class_package=  9;  // (string) package/module/namespace tag belongs to
const VS_TAGDETAIL_package=        9;  // (string) package/module/namespace tag belongs to
const VS_TAGDETAIL_class_id=      10;  // (int) unique id for class tag belongs to
const VS_TAGDETAIL_flags=         11;  // (int) tag flags (see SE_TAG_FLAG_* above)
const VS_TAGDETAIL_return=        12;  // (string) return type for functions, type of variables
const VS_TAGDETAIL_arguments=     13;  // (string) function arguments
const VS_TAGDETAIL_num_tags=      17;  // (int) number of tags/instances in database
const VS_TAGDETAIL_num_classes=   18;  // (int) number of classes in database
const VS_TAGDETAIL_num_files=     19;  // (int) number of files in database
const VS_TAGDETAIL_num_types=     20;  // (int) number of types in database
const VS_TAGDETAIL_num_refs=      21;  // (int) number of references/occurrences in database
const VS_TAGDETAIL_throws=        22;  // (string) exceptions thrown by function
const VS_TAGDETAIL_included_by=   23;  // (string) full path of parent source file
const VS_TAGDETAIL_return_only=   24;  // (string) return type, no default args
const VS_TAGDETAIL_return_value=  25;  // (string) default value for variable
const VS_TAGDETAIL_file_ext=      26;  // (string) p_LangId property for file
const VS_TAGDETAIL_language_id=   26;  // (string) p_LangId property for file
const VS_TAGDETAIL_context_id=    27;  // (int) returns same result as tag_current_context()
const VS_TAGDETAIL_local_id=      28;  // (int) returns same result as tag_current_local
const VS_TAGDETAIL_current_file=  29;  // (int) returns name of file in current context
const VS_TAGDETAIL_signature=     30;  // (string) returns the signature
const VS_TAGDETAIL_class_parents= 31;  // (string) returns the class parents
const VS_TAGDETAIL_template_args= 32;  // (string) returns the template signature
const VS_TAGDETAIL_statement_id=  33;  // (int) returns same result as tag_current_statement()
const VS_TAGDETAIL_doc_type=      34;  // (int) type of documentation comment
const VS_TAGDETAIL_doc_comments=  35;  // (string) returns the documentation comment text
const VS_TAGDETAIL_LASTID=        36;  // last tag detail id (plus 1)

const VS_TAGDETAIL_context_tag_file=      (VS_TAGDETAIL_context+0);
const VS_TAGDETAIL_context_name=          (VS_TAGDETAIL_context+1);
const VS_TAGDETAIL_context_type=          (VS_TAGDETAIL_context+2);
const VS_TAGDETAIL_context_file=          (VS_TAGDETAIL_context+3);
const VS_TAGDETAIL_context_line=          (VS_TAGDETAIL_context+4);
const VS_TAGDETAIL_context_start_linenum= (VS_TAGDETAIL_context+4);
const VS_TAGDETAIL_context_start_seekpos= (VS_TAGDETAIL_context+5);
const VS_TAGDETAIL_context_scope_linenum= (VS_TAGDETAIL_context+6);
const VS_TAGDETAIL_context_scope_seekpos= (VS_TAGDETAIL_context+7);
const VS_TAGDETAIL_context_end_linenum=   (VS_TAGDETAIL_context+8);
const VS_TAGDETAIL_context_end_seekpos=   (VS_TAGDETAIL_context+9);
const VS_TAGDETAIL_context_class=         (VS_TAGDETAIL_context+10);
const VS_TAGDETAIL_context_flags=         (VS_TAGDETAIL_context+11);
const VS_TAGDETAIL_context_args=          (VS_TAGDETAIL_context+12);
const VS_TAGDETAIL_context_return=        (VS_TAGDETAIL_context+13);
const VS_TAGDETAIL_context_outer=         (VS_TAGDETAIL_context+14);
const VS_TAGDETAIL_context_parents=       (VS_TAGDETAIL_context+15);
const VS_TAGDETAIL_context_throws=        (VS_TAGDETAIL_context+16);
const VS_TAGDETAIL_context_included_by=   (VS_TAGDETAIL_context+17);
const VS_TAGDETAIL_context_return_only=   (VS_TAGDETAIL_context+18);
const VS_TAGDETAIL_context_return_value=  (VS_TAGDETAIL_context+19);
const VS_TAGDETAIL_context_template_args= (VS_TAGDETAIL_context+20);
const VS_TAGDETAIL_context_name_linenum=  (VS_TAGDETAIL_context+21);
const VS_TAGDETAIL_context_name_seekpos=  (VS_TAGDETAIL_context+22);
const VS_TAGDETAIL_context_language_id=   (VS_TAGDETAIL_context+23);
const VS_TAGDETAIL_context_doc_type=      (VS_TAGDETAIL_context+24);
const VS_TAGDETAIL_context_doc_comments=  (VS_TAGDETAIL_context+25);

const VS_TAGDETAIL_local_tag_file=        (VS_TAGDETAIL_local+0);
const VS_TAGDETAIL_local_name=            (VS_TAGDETAIL_local+1);
const VS_TAGDETAIL_local_type=            (VS_TAGDETAIL_local+2);
const VS_TAGDETAIL_local_file=            (VS_TAGDETAIL_local+3);
const VS_TAGDETAIL_local_line=            (VS_TAGDETAIL_local+4);
const VS_TAGDETAIL_local_start_linenum=   (VS_TAGDETAIL_local+4);
const VS_TAGDETAIL_local_start_seekpos=   (VS_TAGDETAIL_local+5);
const VS_TAGDETAIL_local_scope_linenum=   (VS_TAGDETAIL_local+6);
const VS_TAGDETAIL_local_scope_seekpos=   (VS_TAGDETAIL_local+7);
const VS_TAGDETAIL_local_end_linenum=     (VS_TAGDETAIL_local+8);
const VS_TAGDETAIL_local_end_seekpos=     (VS_TAGDETAIL_local+9);
const VS_TAGDETAIL_local_class=           (VS_TAGDETAIL_local+10);
const VS_TAGDETAIL_local_flags=           (VS_TAGDETAIL_local+11);
const VS_TAGDETAIL_local_args=            (VS_TAGDETAIL_local+12);
const VS_TAGDETAIL_local_return=          (VS_TAGDETAIL_local+13);
const VS_TAGDETAIL_local_outer=           (VS_TAGDETAIL_local+14);
const VS_TAGDETAIL_local_parents=         (VS_TAGDETAIL_local+15);
const VS_TAGDETAIL_local_throws=          (VS_TAGDETAIL_local+16);
const VS_TAGDETAIL_local_included_by=     (VS_TAGDETAIL_local+17);
const VS_TAGDETAIL_local_return_only=     (VS_TAGDETAIL_local+18);
const VS_TAGDETAIL_local_return_value=    (VS_TAGDETAIL_local+19);
const VS_TAGDETAIL_local_template_args=   (VS_TAGDETAIL_local+20);
const VS_TAGDETAIL_local_name_linenum=    (VS_TAGDETAIL_local+21);
const VS_TAGDETAIL_local_name_seekpos=    (VS_TAGDETAIL_local+22);
const VS_TAGDETAIL_local_language_id=     (VS_TAGDETAIL_local+23);
const VS_TAGDETAIL_local_doc_type=        (VS_TAGDETAIL_local+24);
const VS_TAGDETAIL_local_doc_comments=    (VS_TAGDETAIL_local+25);

const VS_TAGDETAIL_match_tag_file=        (VS_TAGDETAIL_match+0);
const VS_TAGDETAIL_match_name=            (VS_TAGDETAIL_match+1);
const VS_TAGDETAIL_match_type=            (VS_TAGDETAIL_match+2);
const VS_TAGDETAIL_match_file=            (VS_TAGDETAIL_match+3);
const VS_TAGDETAIL_match_line=            (VS_TAGDETAIL_match+4);
const VS_TAGDETAIL_match_start_linenum=   (VS_TAGDETAIL_match+4);
const VS_TAGDETAIL_match_start_seekpos=   (VS_TAGDETAIL_match+5);
const VS_TAGDETAIL_match_scope_linenum=   (VS_TAGDETAIL_match+6);
const VS_TAGDETAIL_match_scope_seekpos=   (VS_TAGDETAIL_match+7);
const VS_TAGDETAIL_match_end_linenum=     (VS_TAGDETAIL_match+8);
const VS_TAGDETAIL_match_end_seekpos=     (VS_TAGDETAIL_match+9);
const VS_TAGDETAIL_match_class=           (VS_TAGDETAIL_match+10);
const VS_TAGDETAIL_match_flags=           (VS_TAGDETAIL_match+11);
const VS_TAGDETAIL_match_args=            (VS_TAGDETAIL_match+12);
const VS_TAGDETAIL_match_return=          (VS_TAGDETAIL_match+13);
const VS_TAGDETAIL_match_outer=           (VS_TAGDETAIL_match+14);
const VS_TAGDETAIL_match_parents=         (VS_TAGDETAIL_match+15);
const VS_TAGDETAIL_match_throws=          (VS_TAGDETAIL_match+16);
const VS_TAGDETAIL_match_included_by=     (VS_TAGDETAIL_match+17);
const VS_TAGDETAIL_match_return_only=     (VS_TAGDETAIL_match+18);
const VS_TAGDETAIL_match_return_value=    (VS_TAGDETAIL_match+19);
const VS_TAGDETAIL_match_template_args=   (VS_TAGDETAIL_match+20);
const VS_TAGDETAIL_match_name_linenum=    (VS_TAGDETAIL_match+21);
const VS_TAGDETAIL_match_name_seekpos=    (VS_TAGDETAIL_match+22);
const VS_TAGDETAIL_match_language_id=     (VS_TAGDETAIL_match+23);
const VS_TAGDETAIL_match_doc_type=        (VS_TAGDETAIL_match+24);
const VS_TAGDETAIL_match_doc_comments=    (VS_TAGDETAIL_match+25);

const VS_TAGDETAIL_statement_tag_file=      (VS_TAGDETAIL_statement+0);
const VS_TAGDETAIL_statement_name=          (VS_TAGDETAIL_statement+1);
const VS_TAGDETAIL_statement_type=          (VS_TAGDETAIL_statement+2);
const VS_TAGDETAIL_statement_file=          (VS_TAGDETAIL_statement+3);
const VS_TAGDETAIL_statement_line=          (VS_TAGDETAIL_statement+4);
const VS_TAGDETAIL_statement_start_linenum= (VS_TAGDETAIL_statement+4);
const VS_TAGDETAIL_statement_start_seekpos= (VS_TAGDETAIL_statement+5);
const VS_TAGDETAIL_statement_scope_linenum= (VS_TAGDETAIL_statement+6);
const VS_TAGDETAIL_statement_scope_seekpos= (VS_TAGDETAIL_statement+7);
const VS_TAGDETAIL_statement_end_linenum=   (VS_TAGDETAIL_statement+8);
const VS_TAGDETAIL_statement_end_seekpos=   (VS_TAGDETAIL_statement+9);
const VS_TAGDETAIL_statement_class=         (VS_TAGDETAIL_statement+10);
const VS_TAGDETAIL_statement_flags=         (VS_TAGDETAIL_statement+11);
const VS_TAGDETAIL_statement_args=          (VS_TAGDETAIL_statement+12);
const VS_TAGDETAIL_statement_return=        (VS_TAGDETAIL_statement+13);
const VS_TAGDETAIL_statement_outer=         (VS_TAGDETAIL_statement+14);
const VS_TAGDETAIL_statement_parents=       (VS_TAGDETAIL_statement+15);
const VS_TAGDETAIL_statement_throws=        (VS_TAGDETAIL_statement+16);
const VS_TAGDETAIL_statement_included_by=   (VS_TAGDETAIL_statement+17);
const VS_TAGDETAIL_statement_return_only=   (VS_TAGDETAIL_statement+18);
const VS_TAGDETAIL_statement_return_value=  (VS_TAGDETAIL_statement+19);
const VS_TAGDETAIL_statement_template_args= (VS_TAGDETAIL_statement+20);
const VS_TAGDETAIL_statement_name_linenum=  (VS_TAGDETAIL_statement+21);
const VS_TAGDETAIL_statement_name_seekpos=  (VS_TAGDETAIL_statement+22);
const VS_TAGDETAIL_statement_language_id=   (VS_TAGDETAIL_statement+23);
const VS_TAGDETAIL_statement_doc_type=      (VS_TAGDETAIL_statement+24);
const VS_TAGDETAIL_statement_doc_comments=  (VS_TAGDETAIL_statement+25);

//////////////////////////////////////////////////////////////////////
// Standard file types, used to distinguish between source files
// pulled in naturally by tagging, object files, class files,
// executables, browser databaser, debug databases, and source files
// referenced by various other items.
//
const VS_FILETYPE_source=      0;
const VS_FILETYPE_references=  1;
const VS_FILETYPE_include=     2;

//////////////////////////////////////////////////////////////////////
// Flags associated with tags, denoting access restrictions and
// and other attributes of class members (proc's, proto's, and var's)
//    NOT virtual and NOT static implies normal class method
//    NOT const implies normal read/write access
//    NOT volatile implies normal optimizations are safe
//
const VS_INSTFLAG_static=       0x01;
const VS_INSTFLAG_virtual=      0x02;
const VS_INSTFLAG_volatile=     0x04;
const VS_INSTFLAG_const=        0x08;

//////////////////////////////////////////////////////////////////////
// Standard reference types, by default, always present in database
// standard type name is always "xxx" for VS_REFTYPE_xxx,
// for example, the type name for VS_REFTYPE_proc is "proc".
//
const VS_REFTYPE_unknown=    0;     // unspecified
const VS_REFTYPE_macro=      1;     // use of #define'd macro
const VS_REFTYPE_call=       2;     // function or procedure call
const VS_REFTYPE_var=        3;     // use of a variable
const VS_REFTYPE_import=     4;     // use of a package
const VS_REFTYPE_derive=     5;     // class derivation
const VS_REFTYPE_type=       6;     // use of abstract type
const VS_REFTYPE_class=      7;     // instantiantion of class
const VS_REFTYPE_constant=   8;     // use of constant value or enum value
const VS_REFTYPE_label=      9;     // use of label for goto

//////////////////////////////////////////////////////////////////////
// Characters used as separators when storing compound strings
// in the database.
//

/**
 * This constant represents the character used to separate
 * inner classes from outer classes in class names.  For
 * example, if you have a class B nested inside a class A,
 * the class name used in the database is <b>A:B</b>.
 *
 * @see tag_find_class
 * @see tag_get_class
 * @see tag_next_class
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_class  ":"
/**
 * This constant represents the character used to separate class names from package names.  For example, if you have a class B in a package A, the class name used in the
 * database is<b>A/B</b>.
 *
 * @see tag_find_class
 * @see tag_get_class
 * @see tag_next_class
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_package  "/"
/**
 * This constant represents the character used to separate
 * arguments from the return type in the signature for of a
 * function, template class, or #define.  For example, for
 * the C function <b>char *strdup(const char *s)</b>, the signature
 * is "<b>char*\1const char*</b>".
 *
 * @see tag_get_detail
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_args   "\1"
/**
 * This constant represents the character used to separate
 * the return type and arguments to a function from the list
 * of exceptions thrown by a function.
 *
 * @see tag_get_detail
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_throws   "\2"
/**
 * This constant represents the character used to separate class names in the list of parent classes that a class derives from.  For example, if a class derives from class A, and implements interfaces B and C, the list would be <b>A;B;C</b>.
 *
 * @see tag_get_inheritance
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_parents   ";"
/**
 * This constant represents the character used to
 * separate the return type of a typed constant from its
 * value.  For example, for the Pascal <b>constant A:integer:=3</b>,
 * the signature is "<b>integer=3</b>".
 *
 * @see tag_get_detail
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
#define VS_TAGSEPARATOR_equals    "="
/**
 * This constant represents the character used to
 * separate identifiers in the list of occurrences found
 * in a file when tagging references.
 */
#define VS_TAGSEPARATOR_occurrences  "\t"


/////////////////////////////////////////////////////////////////////
// Tag match types for speed insert of tag matches
const VS_TAGMATCH_tag=          0;
const VS_TAGMATCH_context=      1;
const VS_TAGMATCH_local=        2;
const VS_TAGMATCH_match=        3;
const VS_TAGMATCH_statement=    4;

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////


/**
 * Tag context/property filtering flags.  These filters are used by 
 * various methods to narrow down a tagging search to a specific set of symbols 
 * with certain properties. 
 *  
 * @see tag_list_in_class() 
 * @see tag_find_contxt_tags() 
 * @see _c_find_context_tags() 
 * @see _Embeddedfind_context_tags()
 */
enum_flags SETagContextFlags {

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
    *  
    * @deprecated This flag had to be moved to prevent sign-extension.  See below. 
    */
   SE_TAG_CONTEXT_NO_GROUPS_OLD       = 0x80000000,  
   /**
    * Do not look for symbols found nested in groups (as in COBOL), 
    * which are anonymous, opaque record types.
    */
   SE_TAG_CONTEXT_NO_GROUPS           = 0x0000001000000000,  
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
   SE_TAG_CONTEXT_MATCH_PREFIX        = 0x0000000000000000,
   /**
    * This pattern matching strategy is basic stone skipping with the 
    * restriction that matches must be at the start of a subword, or adjacent 
    * to the last letter matched.  This search strategy allows one retry, in 
    * case if the pattern specifies two subwords in the wrong order. 
    */
   SE_TAG_CONTEXT_MATCH_STSK_SUBWORD  = 0x0000000100000000,
   /**
    * This pattern matching strategy is stone skipping with the restriction 
    * that each letter matched must be the first letter of a subword. 
    * This search strategy allows one retry, in case if the pattern specifies 
    * two characters of the acronym in the wrong order.
    */
   SE_TAG_CONTEXT_MATCH_STSK_ACRONYM  = 0x0000000200000000,
   /**
    * This is the most general pattern matching strategy, purely working from 
    * left-to-right through the identifier, ignoring subword boundaries or 
    * adjacency. 
    */
   SE_TAG_CONTEXT_MATCH_STSK_PURE     = 0x0000000300000000,
   /**
    * This is simple substring matching.  The substring may start in the middle 
    * of a subword.  It is zero-hop stone skipping, every character matched 
    * after the initial match just be adjacent. 
    */
   SE_TAG_CONTEXT_MATCH_SUBSTRING     = 0x0000000400000000,
   /**
    * This is simple substring matching with the restriction that the match 
    * must start at the beginning of a subword.  It can be considered as a 
    * specialization of stone skipping with subword boundaries where only 
    * one subword is matched (potentially along with adjacent subwords). 
    */
   SE_TAG_CONTEXT_MATCH_SUBWORD       = 0x0000000500000000,
   /**
    * Simply determine if the symbol contains all the characters that are 
    * in the pattern, in any order, with no word boundaries.  If the pattern 
    * repeats a character, it must repeat at least as many times in the symbol 
    * name in order to match. 
    */
   SE_TAG_CONTEXT_MATCH_CHAR_BITSET   = 0x0000000600000000,
   /**
    * All context tagging pattern matching strategy flags.  Currently we 
    * support the following strategies, but more could be added later. 
    *  
    * <ul> 
    * <li>[default] Stone-skipping with word boundaries</li>
    * <li>Acronym-based stone-skipping</li>
    * <li>Pure stone-skipping</li>
    * <li>Simple substring matching</li>
    * <li>Subword prefix matching.</li>
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
   SE_TAG_CONTEXT_MATCH_FIRST_CHAR     = 0x0000000800000000,
   /**
    * Only look for symbols in the current workspace
    */
   SE_TAG_CONTEXT_ONLY_WORKSPACE       = 0x0000001000000000,
   /**
    * Only look for symbols in the current workspace (including auto-update tag files).
    */
   SE_TAG_CONTEXT_INCLUDE_AUTO_UPDATED = 0x0000002000000000,
   /**
    * Only look for symbols in the current workspace (including compiler tag files).
    */
   SE_TAG_CONTEXT_INCLUDE_COMPILER     = 0x0000004000000000,
   /**
    * Relax pattern matching order constraints to allow for possibility that 
    * the pattern could have one or two subwords or characters out or order. 
    * When pattern matching reaches the end of the pattern without matching 
    * the entire pattern, it will do a one-time restart from the beginning 
    * of the symbol the pattern is being matched against. 
    */
   SE_TAG_CONTEXT_MATCH_RELAX_ORDER    = 0x0000008000000000,

   /**
    * Only include symbols which are marked for export.  (SE_TAG_FLAG_EXPORT)
    */
   SE_TAG_CONTEXT_ONLY_EXPORT          = 0x0000010000000000,

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
                                          SE_TAG_CONTEXT_ONLY_WORKSPACE       |
                                          SE_TAG_CONTEXT_NO_GROUPS            |
                                          SE_TAG_CONTEXT_ONLY_EXPORT          ),

   /**
    * All "find" context tagging flags.
    */
   SE_TAG_CONTEXT_FIND_FLAGS          = ( SE_TAG_CONTEXT_FIND_ALL             |
                                          SE_TAG_CONTEXT_FIND_DERIVED         |
                                          SE_TAG_CONTEXT_FIND_LENIENT         |
                                          SE_TAG_CONTEXT_FIND_PARENTS         ),

};

/**
 * Allow local variables to be included in the match set.
 */
#define VS_TAGCONTEXT_ALLOW_locals VSDEPRECATEDCONSTANT(0x00000001)
/**
 * #define symbolVSDEPRECATEDCONSTANT(which have private access level.)
 * <p> 
 * #definely, thiVSDEPRECATEDCONSTANT(is used initially when searching within the current class,)
 * #defineturned ofVSDEPRECATEDCONSTANT(when the search crosses into parent classes or the)
 * global scope. 
 */
#define VS_TAGCONTEXT_ALLOW_private VSDEPRECATEDCONSTANT(0x00000002)
/**
 * #define symbolVSDEPRECATEDCONSTANT(which have protected access level.)
 * <p> 
 * #definely, thiVSDEPRECATEDCONSTANT(is used initially when seaching within the current class)
 * #definearent classesVSDEPRECATEDCONSTANT(then turned off when the search crosses into the)
 * #definel scopVSDEPRECATEDCONSTANT(or imported symbols.)
 */
#define VS_TAGCONTEXT_ALLOW_protected VSDEPRECATEDCONSTANT(0x00000004)
/**
 * #define symbolVSDEPRECATEDCONSTANT(which have package access level)
 * <p> 
 * #definely thiVSDEPRECATEDCONSTANT(is used initially when searching within the current package,)
 * #definethis flaVSDEPRECATEDCONSTANT(is turned off when the search crosses into other packages)
 * #definee globaVSDEPRECATEDCONSTANT(scope.)
 */
#define VS_TAGCONTEXT_ALLOW_package VSDEPRECATEDCONSTANT(0x00000008)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are defined as volatile.)
 */
#define VS_TAGCONTEXT_ONLY_volatile VSDEPRECATEDCONSTANT(0x00000010)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are defined as const.)
 */
#define VS_TAGCONTEXT_ONLY_const VSDEPRECATEDCONSTANT(0x00000020)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are not defined as static.)
 * #defineis usefuVSDEPRECATEDCONSTANT(when searching for symbols in a statically qualified)
 * #definel scopeVSDEPRECATEDCONSTANT(such as "CLASSNAME::" in C++)
 */
#define VS_TAGCONTEXT_ONLY_static VSDEPRECATEDCONSTANT(0x00000040)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are not defined as static)
 */
#define VS_TAGCONTEXT_ONLY_non_static VSDEPRECATEDCONSTANT(0x00000080)
/**
 * #defineinclude variablVSDEPRECATEDCONSTANT(declarations)
 */
#define VS_TAGCONTEXT_ONLY_data VSDEPRECATEDCONSTANT(0x00000100)
/**
 * #defineinclude functioVSDEPRECATEDCONSTANT(and procedures)
 */
#define VS_TAGCONTEXT_ONLY_funcs VSDEPRECATEDCONSTANT(0x00000200)
/**
 * #defineinclude classesVSDEPRECATEDCONSTANT(structs, records, unions, enums, groups, tables,)
 * #definether structureVSDEPRECATEDCONSTANT(type definitions.)
 */
#define VS_TAGCONTEXT_ONLY_classes VSDEPRECATEDCONSTANT(0x00000400)
/**
 * #defineinclude packagVSDEPRECATEDCONSTANT(and namespace symbols)
 */
#define VS_TAGCONTEXT_ONLY_packages VSDEPRECATEDCONSTANT(0x00000800)
/**
 * #definelook foVSDEPRECATEDCONSTANT(symbols actually defined within the scope of the)
 * #definent searcVSDEPRECATEDCONSTANT(class.  Do not include out-of-line symbol definitions.)
 * #defineis usefulVSDEPRECATEDCONSTANT(for example in C++, in order to narrow down the results)
 * #defineoid includinVSDEPRECATEDCONSTANT(duplicate symbols (proc and prototype).)
 */
#define VS_TAGCONTEXT_ONLY_inclass VSDEPRECATEDCONSTANT(0x00001000)
/**
 * #definelook foVSDEPRECATEDCONSTANT(class constructors for the current search class)
 */
#define VS_TAGCONTEXT_ONLY_constructors VSDEPRECATEDCONSTANT(0x00002000)
/**
 * #definelook foVSDEPRECATEDCONSTANT(this symbol in the current search class.  Do not)
 * #definein parenVSDEPRECATEDCONSTANT(classes or the global scope.)
 */
#define VS_TAGCONTEXT_ONLY_this_class VSDEPRECATEDCONSTANT(0x00004000)
/**
 * #definelook foVSDEPRECATEDCONSTANT(this symbol in parent classes.  Do not include)
 * #definees iVSDEPRECATEDCONSTANT(the scope of the current class or global scope)
 */
#define VS_TAGCONTEXT_ONLY_parents VSDEPRECATEDCONSTANT(0x00008000)
/**
 * #definefor thiVSDEPRECATEDCONSTANT(symbol in classes and interfaces that derive from the)
 * #definefied searcVSDEPRECATEDCONSTANT(class.  This is used, for example, to find all the)
 * #defineds thaVSDEPRECATEDCONSTANT(override a virtual method in an interface class.)
 */
#define VS_TAGCONTEXT_FIND_derived VSDEPRECATEDCONSTANT(0x00010000)
/**
 * #definede anonymouVSDEPRECATEDCONSTANT(symbols, such as anonymous classes or structs)
 */
#define VS_TAGCONTEXT_ALLOW_anonymous VSDEPRECATEDCONSTANT(0x00020000)
/**
 * #defineinclude locaVSDEPRECATEDCONSTANT(variables)
 */
#define VS_TAGCONTEXT_ONLY_locals VSDEPRECATEDCONSTANT(0x00040000)
/**
 * #define anVSDEPRECATEDCONSTANT(symbol type, even friend symbols and import statements)
 */
#define VS_TAGCONTEXT_ALLOW_any_tag_type VSDEPRECATEDCONSTANT(0x00080000)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are defined as final)
 */
#define VS_TAGCONTEXT_ONLY_final VSDEPRECATEDCONSTANT(0x00100000)
/**
 * #defineinclude symbolVSDEPRECATEDCONSTANT(which are not defined as final)
 */
#define VS_TAGCONTEXT_ONLY_non_final VSDEPRECATEDCONSTANT(0x00200000)
/**
 * #definesearch foVSDEPRECATEDCONSTANT(matches within the current)
 * #definesymbols iVSDEPRECATEDCONSTANT(the current file))
 */
#define VS_TAGCONTEXT_ONLY_context VSDEPRECATEDCONSTANT(0x00400000)
/**
 * #definet looVSDEPRECATEDCONSTANT(for symbols in the global scope or imported into the global)
 * #define, onlVSDEPRECATEDCONSTANT(look within the current (and derived) class scopes and)
 * local variables. 
 */
#define VS_TAGCONTEXT_NO_globals VSDEPRECATEDCONSTANT(0x00800000)
/**
 * #definede forwarVSDEPRECATEDCONSTANT(class declarations and function declarations in)
 * #defineet oVSDEPRECATEDCONSTANT(symbols found.)
 */
#define VS_TAGCONTEXT_ALLOW_forward VSDEPRECATEDCONSTANT(0x01000000)
/**
 * #definematching symbolVSDEPRECATEDCONSTANT(without enforcing strict scoping rules)
 */
#define VS_TAGCONTEXT_FIND_lenient VSDEPRECATEDCONSTANT(0x02000000)
/**
 * #defineall definitionVSDEPRECATEDCONSTANT(of this symbol, even after finding the nearest)
 * #defineition oVSDEPRECATEDCONSTANT(this symbol in scope.)
 */
#define VS_TAGCONTEXT_FIND_all VSDEPRECATEDCONSTANT(0x04000000)
/**
 * #definefor thiVSDEPRECATEDCONSTANT(symbol in parent classes and interfaces.)
 */
#define VS_TAGCONTEXT_FIND_parents VSDEPRECATEDCONSTANT(0x08000000)
/**
 * #definelook foVSDEPRECATEDCONSTANT(symbols that are defined as templates or generics)
 */
#define VS_TAGCONTEXT_ONLY_templates VSDEPRECATEDCONSTANT(0x10000000)
/**
 * #definet looVSDEPRECATEDCONSTANT(for selectors (as in Objective-C))
 */
#define VS_TAGCONTEXT_NO_selectors VSDEPRECATEDCONSTANT(0x20000000)
/**
 * #definelook foVSDEPRECATEDCONSTANT(symbols in the current file)
 */
#define VS_TAGCONTEXT_ONLY_this_file VSDEPRECATEDCONSTANT(0x40000000)
/**
 * #definet looVSDEPRECATEDCONSTANT(for symbols found nested in groups (as in COBOL),)
 * #define arVSDEPRECATEDCONSTANT(anonymous, opaque record types)
 */
#define VS_TAGCONTEXT_NO_groups VSDEPRECATEDCONSTANT(0x80000000; )
/**
 * #define symbosVSDEPRECATEDCONSTANT(with "private" level access control.)
 * #definete leveVSDEPRECATEDCONSTANT(symbols are visible to the current class only,)
 * #defines anotheVSDEPRECATEDCONSTANT(symbol has a friend relationship with the class.)
 */
#define VS_TAGCONTEXT_ACCESS_private VSDEPRECATEDCONSTANT(0x0000000E)
/**
 * #define symbolVSDEPRECATEDCONSTANT(with "protected" level access control.)
 * #definected leveVSDEPRECATEDCONSTANT(symbols are visible to the current class and all)
 * #definees deriveVSDEPRECATEDCONSTANT(from it, but not visible to unrelated classes,)
 * #defines anotheVSDEPRECATEDCONSTANT(symbol has a friend relationship with the class.)
 */
#define VS_TAGCONTEXT_ACCESS_protected VSDEPRECATEDCONSTANT(0x0000000C)
/**
 * #define symbolVSDEPRECATEDCONSTANT(with "package" level access control.)
 * #definege leveVSDEPRECATEDCONSTANT(symbols are supposed to be visible within the package)
 * #defineare definedVSDEPRECATEDCONSTANT(but not visible in other packages unless imported)
 */
#define VS_TAGCONTEXT_ACCESS_package VSDEPRECATEDCONSTANT(0x00000008)
/**
 * #define symbolVSDEPRECATEDCONSTANT(with "public" level access control.)
 * #defineflag iVSDEPRECATEDCONSTANT(a no-op, since "public" symbols should always be visible.)
 */
#define VS_TAGCONTEXT_ACCESS_public VSDEPRECATEDCONSTANT(0x00000000)
/**
 * #definelt contexVSDEPRECATEDCONSTANT(flags, typical flags used for matching any)
 * #definel followinVSDEPRECATEDCONSTANT(normal scoping rules.)
 */
#define VS_TAGCONTEXT_ANYTHING VSDEPRECATEDCONSTANT(0x00000000)
/**
 * #definext flagVSDEPRECATEDCONSTANT(with restrictions that SlickEdit Standard can not handle)
 */
#define VS_TAGCONTEXT_ONLY_RESTRICTIONS VSDEPRECATEDCONSTANT(0xF0F4FFF0)


/**
 * Flags for {@link tag_remove_duplicate_symbols_from_matches}
 */
enum_flags VSTagRemoveDuplicatesOptionFlags {
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


/////////////////////////////////////////////////////////////////////

enum_flags VSCodeHelpCommentFlags {
   VSCODEHELP_COMMENTFLAG_HTML=     0x01,
   VSCODEHELP_COMMENTFLAG_JAVADOC=  0x02,
   VSCODEHELP_COMMENTFLAG_XMLDOC=   0x04,
   VSCODEHELP_COMMENTFLAG_DOXYGEN=  0x08,
   VSCODEHELP_COMMENTFLAG_TEXT=     0x10,
   VSCODEHELP_COMMENTFLAG_RAW=      0x80,
};

/** 
 * Documentation comment types
 */
enum SETagDocCommentType {
   /**
    * No documentation comment for this symbol.
    */
   SE_TAG_DOCUMENTATION_NULL,
   /**
    * Plain text, no comment characters, can have newlines.
    */
   SE_TAG_DOCUMENTATION_PLAIN_TEXT,
   /**
    * Plain text, expecting fixed-space font, no comment characters, can have newlines.
    */
   SE_TAG_DOCUMENTATION_FIXED_FONT_TEXT,
   /**
    * HTML formatted text, can have newlines.
    */
   SE_TAG_DOCUMENTATION_HTML,
   /**
    * Raw JavaDoc comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_JAVADOC,
   /**
    * Raw Doxygen comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_DOXYGEN,
   /**
    * Raw XMLDoc comment, including comment characters and newlines.
    */
   SE_TAG_DOCUMENTATION_RAW_XMLDOC,
   /**
    * JavaDoc comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_JAVADOC,
   /**
    * Doxygen comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_DOXYGEN,
   /**
    * XMLDoc comment with comment characters stripped, can have newlines.
    */
   SE_TAG_DOCUMENTATION_XMLDOC,
   /**
    * Invalid comment type
    */
   SE_TAG_DOCUMENTATION_INVALID
};


/////////////////////////////////////////////////////////////////////

/**
 * Symbol information.  This can come from multiple sources, including the
 * current context, local variables, a tagging search match set, a tag database,
 * the Defs tool window, the Symbols tool window, the References tool window,
 * the Find Symbol tool window, the Class tool window, etc.
 * 
 * This is also used to represent symbol information in much of the symbol
 * analysis code and return type parsing code.
 *
 * Use the following methods provided in cbrowser.e for
 * initializing and comparing instances of this structure.
 * <ul>
 * <li>{@link tag_browse_info_init}(cm)
 * <li>{@link tag_browse_info_equal}(cm1,cm2,case_sensitive)
 * <li>{@link tag_get_context_browse_info}(match_id, cm)
 * </ul>
 * 
 * @categories Tagging_Functions
 */
struct VS_TAG_BROWSE_INFO {
   _str tag_database;      // filename of tag file (database)
   _str category;          // caption of tag category (see CB_*, above)
   _str class_name;        // class name for this tag
   _str member_name;       // the tag name
   _str qualified_name;    // qualified class name (if the tag is a class)
   _str type_name;         // tag type
   _str file_name;         // absolute path of file the tag is located in
   _str language;          // p_LangId property for 'file_name'
   int  line_no;           // line number tag should be found on
   long seekpos;           // seek position of tag
   int  name_line_no;      // line number of tag's name/identifier
   long name_seekpos;      // seek position of tag's name/identifier
   int  scope_line_no;     // line number of tag's scope start
   long scope_seekpos;     // seek position of tag's scope start
   int  end_line_no;       // line number of tag's end
   long end_seekpos;       // seek position of tag's end
   int  column_no;         // column position on line (p_col)
   SETagFlags flags;       // bit flags for tag attributes (see tagsdb.sh)
   _str return_type;       // tag return type (unused)
   _str arguments;         // tag signature (function arguments)
   _str exceptions;        // exceptions throws by function or method
   _str class_parents;     // class parents (inheritance)
   _str template_args;     // template signature
   _str doc_comments;      // documentation comments to display
   SETagType type_id;      // tag type ID
   int tagged_line_no;     // line number as found in tag database
   SETagDocCommentType doc_type; // documentation comment type (null, javadoc, etc)
   long tagged_date;       // date which the ifle was tagged YYYYMMDDhhmmssppp
};

/**
 * This struct is filled out by a call to _<lang_id>_get_expression_info, which 
 * is called from {@link _Embeddedget_expression_info}()
 *  
 * Use the following methods provided in cbrowser.e for
 * initializing and comparing instances of this structure.
 * <ul>
 * <li>{@link tag_idexp_info_init}(cm)
 * <li>{@link tag_idexp_info_equal}(cm1,cm2,case_sensitive)
 * </ul>
 * 
 * @categories Tagging_Functions
 */
struct VS_TAG_IDEXP_INFO {
   _str     errorArgs[];            // array of strings for error message arguments
                                    // refer to codehelp.e VSCODEHELPRC_*
   _str     prefixexp;              // set to prefix expression
   _str     lastid;                 // set to last identifier
   int      lastidstart_col;        // last identifier start column
   int      lastidstart_offset;     // last identifier start offset
   int      info_flags;             // bitset of VSAUTOCODEINFO_*
   typeless otherinfo;              // supplementary information (lang specific)
   int      prefixexpstart_offset;  // start offset of prefix expression
   int      cursor_col;             // cursor column
};


/** 
 * Bit flags for _lang_get_return_type_of_prefix related functions. 
 * Stored in VS_TAG_RETURN_TYPE.return_flags, and used in the 
 * _lang_find_context_tags() callbacks to narrow down matches. 
 */
enum_flags SECodeHelpReturnTypeFlags {
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
   VSCODEHELP_RETURN_TYPE_REF             = 0x00000400,
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


///////////////////////////////////////////////////////////////////////////
// Context Tagging(R) information retrieved by analyzing return type of a tag.
// This is determined by calling the function _[ext]_analyze_return_type
// where [ext] is the current file extension.
//
// These return types can be compared using the extension specific
// callback _[ext]_match_return_type, or the default function
// _do_default_match_return_type, which just looks for identical types.
//
// Use the following methods provided in cbrowser.e for
// initializing and comparing instances of this structure.
//    tag_return_type_init(rt)
//    tag_return_type_equal(rt1,rt2,case_sensitive)
//
struct VS_TAG_RETURN_TYPE {
   // what is the base type for this item
   _str return_type;
   // tag information for tag declaring this return type
   _str taginfo;
   _str filename;
   int  line_number;
   // is this a pointer type or array?
   int pointer_count;
   // Is this a template, and what are the template arguments
   bool istemplate;
   _str template_args:[];
   // bit flags of VSCODEHELP_RETURN_TYPE_*
   SECodeHelpReturnTypeFlags return_flags;
   // ordered list of template argument names
   _str template_names[];
   // return types of template arguments
   VS_TAG_RETURN_TYPE template_types:[];
   // alternate return types for symbols with multiple definitions
   VS_TAG_RETURN_TYPE alt_return_types[];
   // is this a variadic template argument list
   bool isvariadic;
};
struct VS_TAG_RETURN_TYPE gnull_return_type; //see main.e

/**
 * Function pointer callback type used for comparing argument lists.
 * This used when {@link tag_tree_compare_args} does not work
 * for a particular language.  Should return true if the argument 
 * lists match, false otherwise. 
 */
typedef bool (*VS_TAG_COMPARE_ARGS_PFN)(_str argList1, _str argList2);

///////////////////////////////////////////////////////////////////////////

int def_tag_max_function_help_protos;
int def_tag_max_list_members_symbols;
int def_tag_max_list_matches_symbols;
int def_tag_max_list_matches_time;
int def_tag_max_list_members_time;
int def_tag_max_find_context_tags;
bool def_tag_hover_preview;
int def_tag_hover_delay;

const VSCODEHELP_MAXFUNCTIONHELPPROTOS=   100;
const VSCODEHELP_MAXLISTGLOBALSYMBOLS=    100;
const VSCODEHELP_MAXLISTMEMBERSSYMBOLS=  1000;
const VSCODEHELP_MAXLISTMATCHESSYMBOLS=   200;
const VSCODEHELP_MAXLISTMATCHESTIME=     1000;  /* milliseconds */
const VSCODEHELP_MAXLISTMEMBERSTIME=     1000;  /* milliseconds */
const VSCODEHELP_MAXFINDCONTEXTTAGS=     1000;
const VSCODEHELP_MAXSKIPPREPROCESSING=    100;
const VSCODEHELP_MAXRECURSIVETYPESEARCH=   64;

enum_flags AutoCodeInfoFlags {

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

   // The final 32-bits of this set of flags are also reserved for SlickEdit's use
   VSAUTOCODEINFO_FUTURE_64_BIT_FLAGS                 = 0xFFFFFFFF00000000,
};

// BIT FLAGS for _c_get_type_of_prefix
enum_flags CodeHelpExpressionPrefixFlags {
   VSCODEHELP_PREFIX_NULL                 = 0x0000,
   VSCODEHELP_PREFIX_OBJECTIVEC_MESSAGE   = 0x0001,
   VSCODEHELP_PREFIX_EXPECT_POINTER       = 0x0002,
   VSCODEHELP_PREFIX_EXPECT_NO_POINTER    = 0x0004,
};

struct VSAUTOCODE_ARG_INFO {
   _str prototype;
   int argstart[];    // 0..# of arguments in prototype.  Start pos of this arg
                      // argstart[0] is start of function name.
   int arglength[];   // 0..# of arguments in prototype.  Start pos of this arg
                      // arglength[0] is length of function name.
                      // arglength[i]==0 indicates nothing to do.

   int ParamNum;      // 0..# of arguments -1.  Argument to highlight
                      // -1 indicates highlight nothing.

   _str ParamName;    // Name of current argument

   _str ParamType;    // declared type of current argument (ParamNum)

   _str ParamKeyword; // keyword required at function call point (e.g., ref or out in C#)

   struct {
      _str filename;     // Filename containing a tag
      int linenum;       // line number of a tag.
      VSCodeHelpCommentFlags comment_flags; // ORed VSCODEHELP_COMMENTFLAG_?? flags or 0
      _str comments;     // Comments of a tag.  Set this to null
                         // and set taginfo if you want to defer retrieving
                         // the comments like we typically do.
      _str taginfo;      // Typically this is tag specification built by
                         // tag_tree_compose_tag or tag_tree_compose_fast.
      VS_TAG_BROWSE_INFO browse_info;  // (optional) better tag information
      VS_TAG_RETURN_TYPE class_type;   // (optional) evaluated tag class information
                                       // useful for template arguments, in particular

   } tagList[];   // Array of information for retrieving comments
                  // The first element in this array is for this tag.
                  // Subsequent entries are for duplicates.  For
                  // example, a proc and a proto with the same signature
                  // may both has comments.
};

///////////////////////////////////////////////////////////////////////////

/** 
 * Used with def_activate_preview to keep track of which windows activate 
 * the preview window automatically
 */
_metadata enum_flags ActivatePreviewFlags {
   APF_ON,
   APF_REFERENCES,
   APF_SYMBOLS,
   APF_FIND_SYMBOL,
   APF_CLASS,
   APF_DEFS,
   APF_BOOKMARKS,
   APF_SEARCH_RESULTS,
   APF_FILES,
   APF_ANNOTATIONS,
   APF_BREAKPOINTS,
   APF_MESSAGE_LIST,
   APF_UNIT_TEST,
   APF_SELECT_SYMBOL,

   // all flags set
   APF_NULL_FLAGS = 0,
   APF_ALL_FLAGS = -1
};

/**
 * Determines if the preview tool window should highlight the current line.
 */
_metadata enum_flags PreviewCurrentLineFlags {
   PREVIEW_CURRENT_LINE_BOX       = 0x01,
   PREVIEW_CURRENT_LINE_HIGHLIGHT = 0x02,
   PREVIEW_CURRENT_LINE_LANG      = 0x04,
};

///////////////////////////////////////////////////////////////////////////
// Prototypes for the tagging function.

/**
 * Returns next tag name which is a prefix match of 'name'.
 * 'find_first' must be 1 to initialize matching.
 * Returns "" when no more matches are found.  find_first
 * must be 2 to terminate matching so that this procedure
 * may remove its temporary buffers.
 *
 * @param name   tag name or tag prefix to search for
 * @param find_first Find first item (1) or find next (0), or terminate (2).
 * @param lang   language ID (p_LangId)
 * @return 0 on success, nonzero on error.
 * @see tag_find_prefix()
 * @see tag_next_prefix()
 * @see f_match()
 * @see mt_match()
 * @since 2.0
 *
 * @categories Tagging_Functions
 */
extern _str tag_match(_str name,int find_first,_str lang="");


///////////////////////////////////////////////////////////////////////////
// administrative functions

/**
 * Specify the amount of memory to use for the database cache.
 *
 * @param cache_size       Amount of memory in bytes.
 * @param cache_max        maximum amount of memory to allow cache to use
 *                         dynamically set depending on the machine's
 *                         available memory.
 *
 * @return 0 on success, &lt;0 on error.
 *         The minimum size cache allowed is 512k.
 * 
 * @since 3.0
 * @categories Tagging_Functions
 */
extern int tag_set_cache_size(int cache_size, int cache_max);

/**
 * @return Return the actual amount of memory being used for the tag file cache. 
 *         The actual tagging cache size is determined dynamically based on
 *         the amount of memory available at startup as well as the settings for
 *         {@link def_tagging_cache_ksize} and {@link def_tagging_cache_max_ksize}.
 *  
 * @since 14.0.2
 * @categories Tagging_Functions
 */
extern int tag_get_cache_size();

/** 
 * Specify whether or not to use memory mapped files for reading and writing 
 * to tag databases.  Turning this feature on effectively makes the tag file 
 * cache size irrelevent. 
 *  
 * This feature is not enabled on all platforms, and can be problematic 
 * on 32-bit systems due to limited amounts or memory mapping space. 
 *
 * @param yes_or_no  'true' to configure databse to use memory mapped files
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @since 20.0
 * @categories Tagging_Functions
 */
extern int tag_set_use_memory_mapped_files(int yes_or_no);
/**
 * @return Return whether or not to use memory mapped files for reading and 
 * writing to tag databases. 
 *  
 * This feature is not enabled on all platforms, and can be problematic 
 * on 32-bit systems due to limited amounts or memory mapping space. 
 *  
 * @since 20.0
 * @categories Tagging_Functions
 */
extern int tag_get_use_memory_mapped_files();

/** 
 * Specify whether or not to use independent file caches for each database 
 * session rather than using a single shared multiple-file database cache.
 *
 * @param yes_or_no  'true' to configure databse to use independent cacahing
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @note 
 * Note that enabling this feature can lead to larger amounts of memory use 
 * because the amount of memory used is no longer limited by a single cache. 
 *  
 * @since 21.0
 * @categories Tagging_Functions
 */
extern int tag_set_use_independent_file_caching(int yes_or_no); 
/**
 * @return Return whether or not to use independent file caches for each 
 * database session rather than using a single shared multiple-file 
 * database cache.
 *  
 * @note 
 * Note that enabling this feature can lead to larger amounts of memory use 
 * because the amount of memory used is no longer limited by a single cache. 
 *  
 * @since 21.0
 * @categories Tagging_Functions
 */
extern int tag_get_use_independent_file_caching(); 

/**
 * Create a tag database, with standard tables, index, and types.
 *
 * @param file_name file path where to create new database
 *                  If file_name exists, it will be truncated.
 * @param db_type  if not given, creates tag database.
 *                if (db_type==VS_DBTYPE_references), then creates
 *                a tag references database.
 * @return Returns database handle &gt;= 0 on success, &lt;0 on error.
 *
 * @since 3.0
 *
 * @see tag_close_all_db
 * @see tag_close_db
 * @see tag_current_db
 * @see tag_flush_db
 * @see tag_open_db
 * @see tag_read_db
 *
 * @categories Tagging_Functions
 */
extern int tag_create_db(_str file_name, int db_type=VS_DBTYPE_tags);

/**
 * Open an existing tag database and return a handle to the database.
 * This function opens the database for read-write access.
 * .  BSC files can not be opened read-write, use {@link tag_read_db} instead.
 *
 * @param file_name File name of tag database to open.
 *
 * @return database handle &gt;= 0 on success, &lt;0 on error.
 * @see tag_create_db()
 * @see tag_read_db()
 * @see tag_close_db()
 * @see tag_flush_db()
 * @see tag_current_db()
 * @see tag_close_all_db()
 * @since 3.0
 *
 * @categories Tagging_Functions
 */
extern int tag_open_db(_str file_name);

/**
 * Open an existing tag database and return a handle to the database.
 * This function opens the database for read-only access.
 * The database type (tags, references, BSC file) is automatically detected.
 *
 * @param file_name file name of tag database to open.
 *
 * @return database handle &gt;= 0 on success, &lt;0 on error.
 * @see tag_close_all_db
 * @see tag_close_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_current_version
 * @see tag_flush_db
 * @see tag_open_db
 *
 * @categories Tagging_Functions
 */
extern int tag_read_db(_str file_name);

/**
 * Flush all unwritten data to disk for the database.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_close_all_db
 * @see tag_close_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_open_db
 * @see tag_read_db
 *
 * @categories Tagging_Functions
 */
extern int tag_flush_db();

/**
 * Return the name of the database currently open
 *
 * @return name of database, or the empty string on error.
 *
 * @categories Tagging_Functions
 */
extern _str tag_current_db();

/**
 * @return Returns 'true' if the current database is open for writing.
 *
 * @categories Tagging_Functions
 */
extern bool tag_current_db_writable();

/**
 * Close the current or specified tag database.
 *
 * @param file_name        Explicite filename of database to close
 *                         otherwise the current open database is closed.
 * @param leave_open       Leave the tag file open read-only
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_close_all_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_flush_db
 * @see tag_open_db
 * @see tag_read_db
 *
 * @categories Tagging_Functions
 */
extern int tag_close_db(_str file_name=null,bool leave_open=false);

/**
 * Closes all open tag databases.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_close_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_current_version
 * @see tag_flush_db
 * @see tag_open_db
 * @see tag_read_db
 *
 * @categories Tagging_Functions
 */
extern int tag_close_all_db();

/**
 * Set a thread synchronization lock on the given tag database. 
 * This is an exclusive lock which keeps all other threads out of the database. 
 *
 * @categories Tagging_Functions
 */
int tag_lock_db(_str file_name, int ms=0);

/**
 * Try to get a thread synchronization lock on the given tag database. 
 * This is an exclusive lock which keeps all other threads out of the database. 
 *  
 * @return Returns 'true' if we were able to get the lock. 
 *
 * @categories Tagging_Functions
 */
int tag_trylock_db(_str file_name);

/**
 * Release the thread synchronization lock on the given database. 
 * Note that write locks are automatically released when the database 
 * is closed or re-opened for reading. 
 *
 * @categories Tagging_Functions
 */
int tag_unlock_db(_str file_name);

/**
 * Display the effective version of the tagsdb.dll
 *
 * @categories Tagging_Functions
 */
extern void tagsdb_version();

/**
 * Return the version of the tags database currently open.
 *
 * @return Return the version of the tags database currently open.  Returns
 *         <b>VS_TAG_USER_VERSION</b> or higher.  If the current version is
 *         {@link VS_TAG_LATEST_VERSION}, then the tag database was created by
 *         the most recent version of tagsdb.dll installed.  The latest version of
 *         the references database is represented by the constant
 *    		See {@link VS_REF_LATEST_VERSION}.
 *
 * @see tag_close_all
 * @see tag_close_db
 * @see tag_create_db
 * @see tag_current_db
 * @see tag_flush_db
 * @see tag_open_db
 * @see tagsdb_version
 *
 * @categories Tagging_Functions
 */
extern int tag_current_version();

/**
 * Return the database description/title.
 *
 * @return database description, null terminated, or the empty string on error.
 *
 * @see tag_set_db_comment
 *
 * @categories Tagging_Functions
 */
extern _str tag_get_db_comment();

/**
 * Sets the database description/title for the currently open
 * database
 *
 * @param comment Description or title of this database
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_get_db_comment
 *
 * @categories Tagging_Functions
 */
extern int tag_set_db_comment(_str comment);

/**
 * Return the database flags VS_DBFLAG_*
 *
 * @return &lt;0 on error, flags bitset on success.
 *
 * @categories Tagging_Functions
 */
extern int tag_get_db_flags();

/**
 * Sets the database flags VS_DBFLAG_*
 *
 * @param flags            bitset of VS_DBFLAG_*
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_set_db_flags(int flags);


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
 *
 * @see tag_insert_file_end
 * @see tag_insert_instance
 * @see tag_insert_reference
 * @see tag_insert_simple
 * @see tag_insert_tag
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 * @see tag_remove_from_file
 * @see tag_transfer_context
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_file_start(_str file_name);

/**
 * Clean up after inserting a series of tags from a single file
 * for update.  Doing this allows the tag database engine to
 * remove any tags from the database that are no longer valid.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_start
 * @see tag_insert_instance
 * @see tag_insert_reference
 * @see tag_insert_simple
 * @see tag_insert_tag
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 * @see tag_remove_from_file
 * @see tag_transfer_context
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_file_end();

/**
 * Remove all references from the given references (browse database or
 * object) file from the database.  This is an effective, but costly way
 * to perform an incremental update of the data imported from a
 * references file.  First remove all items associated with that file,
 * then insert them again.
 *
 * @param file_name full path of file the reference info came from
 * @param remove_file
 *                  if non-zero, the file is removed from the database
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_start
 * @see tag_insert_file_end
 * @see tag_insert_instance
 * @see tag_insert_reference
 * @see tag_insert_simple
 * @see tag_insert_tag
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 * @see tag_transfer_context
 *
 * @categories Tagging_Functions
 */
extern int tag_remove_from_file(_str file_name, bool remove_file=true);


///////////////////////////////////////////////////////////////////////////
// file name handling functions

/**
 * Rename the given file.
 *
 * @param file_name        name of file to update date of tagging for
 * @param new_file_name    new file name
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_rename_file(_str file_name, _str new_file_name);

/**
 * Modify the date of tagging for the given file.  Since date of tagging
 * is not involved in indexing, this is safe to do in the record, in place.
 * This method always uses the current date when setting the date of tagging.
 *
 * @param file_name File path of source file to set tagging date for.  See
 *                  {@link VS_TAGSEPARATOR_file} for more details about
 *                  constructing this value.
 * @param modify_date
 *                  Modification date when tagged, read from disk
 *                  if modify_date is NULL.  Format is YYYYMMDDHHMMSSmmm (year, month, day, hour, minute, second, ms).
 * @param file_type type of file, (0 for a source file, 1 for include)
 * @param included_by
 *                  name of file that 'file_name' was included by
 * @param lang_id   Language ID of file
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_get_date
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 *
 * @categories Tagging_Functions
 */
extern int tag_set_date(_str file_name, 
                        _str modify_date=null,
                        int file_type=0,
                        _str included_by=null,
                        _str lang_id=null);

/**
 * Retrieve the date of tagging for the given file.
 * The string returned by this function is structured such
 * that consecutive dates are ordered lexicographically,
 * and is reported in local time cooridinates (YYYYMMDDHHMMSSmmm).
 * This function has the side effect of finding and position the file iterator
 * on the given file name, returns BT_RECORD_NOT_FOUND_RC if file_name is not
 * in the database.
 *
 * @param file_name name of file to update date of tagging for
 * @param modify_date
 *                  (Output) Modification date of file when tagged.  Format is YYYYMMDDHHMMSSmmm (year, month, day, hour, minute, second, ms).
 * @param included_by
 *                  name of file that 'file_name' was included by
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 * @see tag_set_date
 *
 * @categories Tagging_Functions
 */
extern int tag_get_date(_str file_name, _str &modify_date, _str included_by=null);

/**
 * API function for setting the language type for the given filename. 
 * This corresponds to the {@link p_LangId} property of 'file_name', 
 * not necessarily the literal file extension.
 *
 * @param file_name  File path of source file to set language property for. 
 *                   See {@link VS_TAGSEPARATOR_file} for more
 *                   details about constructing this value.
 * @param lang       {@link p_LangId} property for <i>file_name</i>.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see p_LangId 
 * @see tag_get_extension
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 *
 * @categories Tagging_Functions
 * @deprecated Use {@link tag_set_language()}
 */
extern int tag_set_extension(_str file_name, _str lang);

/**
 * API function for retrieving the language type for the given filename.
 * This corresponds to the {@link p_LangId} property of <i>file_name</i>, 
 * not necessarily the literal file extension.
 *
 * @param file_name        Name of file to set language property for
 * @param lang             (Output) {@link p_LangId} property for file_name
 *
 * @return 0 on success, &lt;0 on error,
 *         BT_RECORD_NOT_FOUND_RC if the file is not found.
 * 
 * @see p_LangId
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 * @see tag_set_extension
 *
 * @categories Tagging_Functions
 * @deprecated Use {@link tag_get_language()}
 */
extern int tag_get_extension(_str file_name, _str &lang);

/**
 * API function for setting the language type for the given filename. 
 * This corresponds to the {@link p_LangId} property of 'file_name', 
 * not necessarily the literal file extension.
 *
 * @param file_name  File path of source file to set language property for. 
 *                   See {@link VS_TAGSEPARATOR_file} for more
 *                   details about constructing this value.
 * @param lang       {@link p_LangId} property for <i>file_name</i>.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see p_LangId 
 * @see tag_get_language
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 *
 * @categories Tagging_Functions
 * @since 13.0
 */
extern int tag_set_language(_str file_name, _str lang);

/**
 * API function for retrieving the language type for the given filename.
 * This corresponds to the {@link p_LangId} property of <i>file_name</i>, 
 * not necessarily the literal file extension.
 *
 * @param file_name        Name of file to set language property for
 * @param lang             (Output) {@link p_LangId} property for file_name
 *
 * @return 0 on success, &lt;0 on error,
 *         BT_RECORD_NOT_FOUND_RC if the file is not found.
 * 
 * @see p_LangId
 * @see tag_get_file
 * @see tag_find_file
 * @see tag_next_file
 * @see tag_set_language
 *
 * @categories Tagging_Functions
 * @since 13.0
 */
extern int tag_get_language(_str file_name, _str &lang);

/**
 * Retreive the name of the file with the given file ID.
 *
 * @param file_id          ID of file, from {@link tag_get_detail}()
 * @param file_name        (Output) Full path of file containing tags
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_get_detail
 * @see tag_find_file
 * @see tag_next_file
 * @see tag_set_date
 *
 * @categories Tagging_Functions
 */
extern int tag_get_file(int file_id, _str &file_name);

/**
 * Retrieve the name of the first file included in this tag database, or optionally, the
 * name of a specific file, either to check if the file is in the database or to
 * position the file iterator at a specific point. Files are ordered lexicographically,
 * case-sensitive on UNIX platforms, case insensitive on DOS/OS2/Windows platforms.
 *
 * @param file_name        (Output) Full path of file containing tags
 * @param search_for       Specific file to search for (prefix search)
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_get_file
 * @see tag_find_in_file
 * @see tag_next_file
 * @see tag_reset_find_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_file(_str &file_name, _str search_file=null);

/**
 * Retreive the name of the next file included in this tag database.
 *
 * @param file_name        (Output) full path of file containing tags
 *
 * @return 0 on success, &lt;0 on error
 *  
 * @see tag_get_file 
 * @see tag_find_file 
 * @see tag_reset_find_file 
 *  
 * @categories Tagging_Functions
 */
extern int tag_next_file(_str &file_name);

/**
 * Reset the file name iterator.  Call this to indicate that you
 * are done searching for files in the current database. 
 * 
 * @return 0 on success, &lt;0 on error
 *
 * @see tag_get_file
 * @see tag_find_in_file
 * @see tag_next_file 
 * @see tag_find_included_by 
 * @see tag_next_included_by 
 * @see tag_find_include_file 
 * @see tag_next_include_file 
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_file();

/**
 * Retrieve the name of the first file included by <i>file_name</i>
 *
 * @param file_name        Full path of "main" source file
 * @param include_name     (Output) Full path of included file
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_find_included_by
 * @see tag_set_date
 * @see tag_insert_tag
 * @see tag_next_include_file
 * @see tag_next_included_by
 * @see tag_reset_find_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_include_file(_str file_name, _str &include_name);

/**
 * Retrieve the name of the next file included by <i>file_name</i>.
 *
 * @param file_name Full path of "main" source file
 * @param include_name
 *                  (Output) full path of included file
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_next_included_by
 * @see tag_find_include_file
 * @see tag_find_included_by
 * @see tag_set_date
 * @see tag_insert_tag
 * @see tag_reset_find_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_next_include_file(_str file_name, _str &include_name);

/**
 * Retreive the name of first the source file that included (directly
 * or indirectly), the given file (expected to be an include file).
 *
 * @param file_name        Full path of file that was included
 * @param included_by      (Output) full path of source file
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_find_include_file
 * @see tag_set_date
 * @see tag_insert_tag
 * @see tag_next_include_file
 * @see tag_next_included_by
 * @see tag_reset_find_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_included_by(_str file_name, _str &included_by);

/**
 * Retreive the name of next the source file that included (directly
 * or indirectly), the given file (expected to be an include file).
 *
 * @param file_name Full path of file that was included
 * @param included_by
 *                  (Output) Full path of source file including <i>file_name</i>.
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_find_include_file
 * @see tag_next_include_file
 * @see tag_next_included_by
 * @see tag_set_date
 * @see tag_insert_tag
 * @see tag_reset_find_file 
 *
 * @categories Tagging_Functions 
 */
extern int tag_next_included_by(_str file_name, _str &included_by);


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
 *
 * @see p_LangId 
 * @see tag_get_extension
 * @see tag_next_extension
 * @see tag_set_extension
 *
 * @categories Tagging_Functions
 * @deprecated Use {@link tag_find_language()}. 
 */ 
extern int tag_find_extension(_str &lang , _str search_for=null);

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_extension} (above). 
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see p_LangId 
 * @see tag_find_extension
 * @see tag_get_extension
 * @see tag_set_extension
 *
 * @categories Tagging_Functions
 * @deprecated Use {@link tag_next_language()}. 
 */
extern int tag_next_extension(_str &lang);

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
 *
 * @see p_LangId 
 * @see tag_get_language
 * @see tag_next_language
 * @see tag_set_language
 *
 * @categories Tagging_Functions
 * @since 13.0
 */ 
extern int tag_find_language(_str &lang, _str search_for=null);

/** 
 * API function for finding the next language tagged in this
 * database.  See {@link tag_find_language} (above).
 * 
 * @param language   (reference) set to next language ID found 
 * 
 * @return 0 on success, &lt;0 on error.
 *  
 * @see p_LangId 
 * @see tag_find_language
 * @see tag_get_language
 * @see tag_set_language
 *
 * @categories Tagging_Functions
 * @since 13.0
 */
extern int tag_next_language(_str &lang);

/** 
 * Reset the find language iterator.  Call this to indicate that 
 * you are done searching for language types in the current 
 * database. 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see p_LangId 
 * @see tag_find_language
 * @see tag_get_language
 * @see tag_set_language
 *
 * @categories Tagging_Functions
 * @since 16.0
 */
extern int tag_reset_find_language();


///////////////////////////////////////////////////////////////////////////
// type name handling functions

/**
 * Retrieve the tag type name for the given type ID.
 *
 * @param type_id Unique integer ID of type, from tag_get_detail.  The standard tag types
 *                (below) are by default always inserted in the database.  Tag type ID's
 *                30-127 are reserved for future use in Visual SlickEdit.  Tag type ID's
 *                128-255 are for user defined tag types.
 * <pre>
 *     SE_TAG_TYPE_NULL             0/null         unspecified tag type
 *     SE_TAG_TYPE_PROC             1/proc         procedure or command
 *     SE_TAG_TYPE_PROTO            2/proto        function prototype
 *     SE_TAG_TYPE_DEFINE           3/define       preprocessor macro definition
 *     SE_TAG_TYPE_TYPEDEF          4/typedef      type definition
 *     SE_TAG_TYPE_GVAR             5/gvar         global variable declaration
 *     SE_TAG_TYPE_STRUCT           6/struct       record or structure definition
 *     SE_TAG_TYPE_ENUMC            7/enumc        enumeration value
 *     SE_TAG_TYPE_ENUM             8/enum         enumerated type
 *     SE_TAG_TYPE_CLASS            9/class        class definition
 *     SE_TAG_TYPE_UNION            10/union       structure / union definition
 *     SE_TAG_TYPE_LABEL            11/label       label
 *     SE_TAG_TYPE_INTERFACE        12/interface   interface, e.g., for Java
 *     SE_TAG_TYPE_CONSTRUCTOR      13/constr      class constructor
 *     SE_TAG_TYPE_DESTRUCTOR       14/destr       class destructor
 *     SE_TAG_TYPE_PACKAGE          15/package     package / module / namespace
 *     SE_TAG_TYPE_VAR              16/var         member of a struct or package
 *     SE_TAG_TYPE_LVAR             17/lvar        local variable declaration
 *     SE_TAG_TYPE_CONSTANT         18/const       Pascal constant
 *     SE_TAG_TYPE_FUNCTION         19/func        function
 *     SE_TAG_TYPE_PROPERTY         20/prop        property?
 *     SE_TAG_TYPE_PROGRAM          21/prog        Pascal program
 *     SE_TAG_TYPE_LIBRARY          22/lib         Pascal library
 *     SE_TAG_TYPE_PARAMETER        23/param       function parameter
 *     SE_TAG_TYPE_IMPORT           24/import      package import or using
 *     SE_TAG_TYPE_FRIEND           25/friend      C++ friend relationship
 *     SE_TAG_TYPE_DATABASE         26/database    SQL/OO Database
 *     SE_TAG_TYPE_TABLE            27/table       database Table
 *     SE_TAG_TYPE_COLUMN           28/column      database Column
 *     SE_TAG_TYPE_INDEX            29/index       database index
 *     SE_TAG_TYPE_VIEW             30/view        database view
 *     SE_TAG_TYPE_TRIGGER          31/trigger     database trigger
 *     SE_TAG_TYPE_FORM             32/form        GUI Form or window
 *     SE_TAG_TYPE_MENU             33/menu        GUI Menu
 *     SE_TAG_TYPE_CONTROL          34/control     GUI Control or Widget
 *     SE_TAG_TYPE_EVENTTAB         35/eventtab    GUI Event table
 *     SE_TAG_TYPE_PROCPROTO        36/procproto   Prototype for procedure
 *     SE_TAG_TYPE_TASK             37/task        Ada task object
 *     SE_TAG_TYPE_INCLUDE          38/include     C++ include, COBOL copy
 *     SE_TAG_TYPE_FILE             38/file        COBOL file descriptor
 *     SE_TAG_TYPE_GROUP            40/group       COBOL group variable
 *     SE_TAG_TYPE_SUBFUNC          41/subfunc     Nested function
 *     SE_TAG_TYPE_SUBPROC          42/subproc     Nested procedure type_name
 *     SE_TAG_TYPE_CURSOR           43/cursor      Database result set cursor
 *     SE_TAG_TYPE_TAG              44/tag         SGML or XML tag type (like a class)
 *     SE_TAG_TYPE_TAGUSE           45/taguse      SGML or XML tag instance (like an object)
 *     SE_TAG_TYPE_STATEMENT        46/statements  generic statement
 *     SE_TAG_TYPE_ANNOTYPE         47/annotype    Java annotation type or C# attribute class
 *     SE_TAG_TYPE_ANNOTATION       48/annotation  Java annotation or C# attribute instance
 *     SE_TAG_TYPE_CALL             49/call        Function/Method call
 *     SE_TAG_TYPE_IF               50/if          If or switch-case statement
 *     SE_TAG_TYPE_LOOP             51/loop        Loop statement
 *     SE_TAG_TYPE_BREAK            52/break       Break statement
 *     SE_TAG_TYPE_CONTINUE         53/continue    Continue statement
 *     SE_TAG_TYPE_RETURN           54/return      Return statement
 *     SE_TAG_TYPE_GOTO             55/goto        Goto statement
 *     SE_TAG_TYPE_TRY              56/try         Try/Catch/Finally statement
 *     SE_TAG_TYPE_PP               57/pp          Preprocessing statement
 *     SE_TAG_TYPE_BLOCK            58/block       Statement block
 *     SE_TAG_TYPE_MIXIN            59/mixin       D language mixin construct
 *     SE_TAG_TYPE_TARGET           60/target      Ant build target
 *     SE_TAG_TYPE_ASSIGN           61/assign      Assignment statement
 *     SE_TAG_TYPE_SELECTOR         62/selector    Objective-C method
 *     SE_TAG_TYPE_UNDEF            63/undef       Preprocessor macro #undef
 *     SE_TAG_TYPE_CLAUSE           64/clause      Statement sub-clause
 *     SE_TAG_TYPE_CLUSTER          65/cluster     Database cluster
 *     SE_TAG_TYPE_PARTITION        66/partition   Database partition
 *     SE_TAG_TYPE_POLICY           67/policy      Database audit policy
 *     SE_TAG_TYPE_PROFILE          68/profile     Database user profile
 *     SE_TAG_TYPE_USER             69/user        Database user name
 *     SE_TAG_TYPE_ROLE             70/role        Database role
 *     SE_TAG_TYPE_SEQUENCE         71/sequence    Database sequence
 *     SE_TAG_TYPE_TABLESPACE       72/tablespace  Database table space
 *     SE_TAG_TYPE_QUERY            73/query       SQL select statement
 *     SE_TAG_TYPE_ATTRIBUTE        74/attr        Attribute
 *     SE_TAG_TYPE_DBLINK           75/dblink      Database link
 *     SE_TAG_TYPE_DIMENSION        76/dimension   Database dimension
 *     SE_TAG_TYPE_DIRECTORY        77/dir         Directory
 *     SE_TAG_TYPE_EDITION          78/edition     Database edition
 *     SE_TAG_TYPE_CONSTRAINT       79/constraint  Database constraint
 *     SE_TAG_TYPE_MONITOR          80/monitor     Event monitor
 *     SE_TAG_TYPE_SCOPE            81/scope       Statement scope block (for local tagging)
 *     SE_TAG_TYPE_CLOSURE          82/closure     Function closure
 *     SE_TAG_TYPE_CONSTRUCTORPROTO 83/constrproto Class constructor prototype
 *     SE_TAG_TYPE_DESTRUCTORPROTO  84/destrproto  Class destructor prototype
 *     SE_TAG_TYPE_OPERATOR         85/operator    Overloaded operator
 *     SE_TAG_TYPE_OPERATORPROTO    86/operproto   Overloaded operator prototype
 *     SE_TAG_TYPE_MISCELLANEOUS    87/misc        Miscellaneous tag type
 *     SE_TAG_TYPE_CONTAINER        88/container   Miscellaneous container tag type
 *     SE_TAG_TYPE_UNKNOWN          89/unknown     Unknown tag type
 *     SE_TAG_TYPE_STATIC_SELECTOR  90/selector    Objective-C static method
 *     SE_TAG_TYPE_SWITC            91/switch      Switch statement
 * </pre>
 * @param type_name (Output) full path of type containing tags
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_get_detail
 * @see tag_find_type
 * @see tag_next_type
 *
 * @categories Tagging_Functions
 */
extern int tag_get_type(SETagType type_id, _str &type_name);

/**
 * Retrieve the name of the first tag type included in this tag database,
 * or optionally, the name of a specific tag type, either to check if it
 * is in the database or to position the iterator at a specific point.
 *
 * @param type_name        (Output) full path of type containing tags
 * @param search_for       Specific type to search for (prefix search)
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_get_type
 * @see tag_next_type
 * @see tag_reset_find_type
 *
 * @categories Tagging_Functions
 */
extern int tag_find_type(_str &type_name, _str search_for=null);
/**
 * Retreive the name of the next type included in this tag database.
 *
 * @param type_name (Output) Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if no more.
 *
 * @see tag_get_type
 * @see tag_find_type
 * @see tag_reset_find_type
 *
 * @categories Tagging_Functions
 */
extern int tag_next_type(_str &type_name);
/**
 * Reset the type iterator.  Call this to indicate that you are 
 * done searching through the tag type table. 
 *  
 * @see tag_find_type
 * @see tag_next_type
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_type();

/**
 * Filter the given tag type based on the given filter flags
 *
 * @param type_id   tag type ID
 * @param filter_flags
 *                  Union of the following filtering flags:
 *                  <dl compact>
 *                  <dt>SE_TAG_FILTER_PROCEDURE<dd style="margin-left:150pt">			proc, func, constr, destr, trigger
 *                  <dt>SE_TAG_FILTER_PROTOTYPE<dd style="margin-left:150pt">		proto, procproto
 *                  <dt>SE_TAG_FILTER_DEFINE<dd style="margin-left:150pt">		define
 *                  <dt>SE_TAG_FILTER_ENUM<dd style="margin-left:150pt">			enum, enumc
 *                  <dt>SE_TAG_FILTER_GLOBAL_VARIABLE<dd style="margin-left:150pt">			gvar
 *                  <dt>SE_TAG_FILTER_TYPEDEF<dd style="margin-left:150pt">		typedef
 *                  <dt>SE_TAG_FILTER_STRUCT<dd style="margin-left:150pt">		struct, class
 *                  <dt>SE_TAG_FILTER_UNION<dd style="margin-left:150pt">		union
 *                  <dt>SE_TAG_FILTER_LABEL<dd style="margin-left:150pt">		label
 *                  <dt>SE_TAG_FILTER_INTERFACE<dd style="margin-left:150pt">		interface
 *                  <dt>SE_TAG_FILTER_PACKAGE<dd style="margin-left:150pt">		package, program, library
 *                  <dt>SE_TAG_FILTER_MEMBER_VARIABLE<dd style="margin-left:150pt">			var
 *                  <dt>SE_TAG_FILTER_CONSTANT<dd style="margin-left:150pt">		const
 *                  <dt>SE_TAG_FILTER_PROPERTY<dd style="margin-left:150pt">		prop
 *                  <dt>SE_TAG_FILTER_LOCAL_VARIABLE<dd style="margin-left:150pt">			lvar, param
 *                  <dt>SE_TAG_FILTER_MISCELLANEOUS<dd style="margin-left:150pt">	Misc. + user defined tag types
 *                  <dt>SE_TAG_FILTER_DATABASE<dd style="margin-left:150pt">		database, table, column, index
 *                  <dt>SE_TAG_FILTER_GUI<dd style="margin-left:150pt">			form, eventtab, menu, control
 *                  <dt>SE_TAG_FILTER_INCLUDE<dd style="margin-left:150pt"> 		include
 *                  <dt>SE_TAG_FILTER_SUBPROCEDURE<dd style="margin-left:150pt"> 		nested procedure or function
 *                  </dl>
 *                  <p>Common combinations of tag filters.
 *                  <dl compact>
 *                  <dt>SE_TAG_FILTER_ANYTHING<dd style="margin-left:150pt">	Any tag type
 *                  <dt>SE_TAG_FILTER_ANY_PROCEDURE<dd style="margin-left:150pt">	PROC,PROTO, SUBPROC
 *                  <dt>SE_TAG_FILTER_ANY_DATA<dd style="margin-left:150pt">	VAR, LVAR, GVAR, PROPERTY
 *                  <dt>SE_TAG_FILTER_ANY_STRUCT<dd style="margin-left:150pt">	STRUCT, UNION, INTERFACE
 *                  </dl>
 * @param type_name Look up type ID using this name
 * @param tag_flags Check tag flags for SE_TAG_FLAG_MAYBE_VAR
 *
 * @return Returns 1 if the type is allowed according to the flags, 0 if not.
 * @see tag_get_type
 * @see tag_find_type
 * @see tag_next_type
 *
 * @categories Tagging_Functions
 */
extern int tag_filter_type(SETagType type_id, SETagFilterFlags filter_flags, _str type_name=null, int tag_flags=0);

/** 
 * @return 
 * Return the bitmap index for the given tag type with the given set of flags.
 * 
 * @param tag_type    tag type ID (SE_TAG_TYPE_*)
 * @param tag_flags   tag flags (bitset of SE_TAG_FLAG_*)
 *
 * @categories Tagging_Functions
 */
extern int tag_get_bitmap_for_type(SETagType tag_type_id, SETagFlags tag_flags=0, int &pic_overlay=0);

/**
 * @return 
 * Return the tag type ID of the first tag type that uses the given bitmap.
 * 
 * @param pic_member    symbol bitmap index (from find_index) 
 * @param first_type_id start searching at the given type index (SE_TAG_TYPE_*)
 *
 * @categories Tagging_Functions
 */
extern SETagType tag_get_type_for_bitmap(int pic_member, SETagType first_type_id=0);


///////////////////////////////////////////////////////////////////////////
// NOTE: administrative functions are now in tagsmain.h
//
// insertion and removal of tags

/**
 * Insert the given tag with accompanying information into the database.  The only
 * difference between this function and tag_insert_simple is that in this
 * function, <i>type_name</i> is a string, allowing you to insert tags with user
 * defined tag types.
 *
 * @param tag_name   tag string
 * @param type_name  string specifying tag type.  If the string
 *                   is not a standard type, a new type will be
 *                   created and inserted in the tag database.
 *                   See {@link tag_get_type}.
 * @param file_name  File path of source file the tag is located in.  See
 *                   {@link VS_TAGSEPARATOR_file} for more details about
 *                   constructing this value.
 * @param line_no    (optional) line number of tag within file
 * @param class_name Name of class or package or other container that the
 *                   tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about
 *                   constructing this value.  If the tag is not in a
 *                   class scope, simple pass the empty string for this value.
 * @param tag_flags  Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param signature  (optional) Tag signature, includes type, value, and
 *                   arguments for the symbol being inserted.  See
 *                   {@link VS_TAGSEPARATOR_args} and {@link VS_TAGSEPARATOR_equals}
 *                   for more details about constructing this value.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_simple
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 *
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_tag_browse_info()} instead
 */
extern int tag_insert_tag(_str tag_name, _str type_name, _str file_name,
                          int line_no, _str class_name, int tag_flags, _str signature);

/**
 * Insert the given tag with accompanying information into the database. 
 * The symbol is inserted into the current tag database, ignoring whatever 
 * <code>cm.tag_database</code> is set to. 
 *
 * @param cm      Instance of {@link VS_TAG_BROWSE_INFO} to insert. 
 *                This contains all the information about the symbol. 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_tag
 * @see tag_insert_simple
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_tag_browse_info(VS_TAG_BROWSE_INFO &cm);

/**
 * Insert the given tag with the accompanying information into the
 * database.  This function is identical to vsTagInsert, except
 * that rather than passing in a tag type, you pass in an int, using
 * one of the standard types defined above (see SE_TAG_TYPE_*).
 *
 * If a record with the same tag name, type, file, *and* class
 * already exists in the database, the line number will be updated.
 *
 * @param tag_name   tag string
 * @param type_id    Tag type ID.  See {@link tag_get_type} for a list of all standard tag types.
 *                   Will return an error
 *                   if (tag_type &lt;= 0 || tag_type > VSTAGTYPE_LASTID).
 * @param file_name  full path of file the tag is located in
 * @param line_no    (optional) line number of tag within file
 * @param class_name (optional) name of class that tag is present in,
 *                   use concatenation (as defined by language rules)
 *                   to specify names of inner classes.
 * @param tag_flags  (optional) Tag flags indicating symbol attributes.
 *                   <dl compact>
 *                   <dt>SE_TAG_FLAG_VIRTUAL<dd style="margin-left:135pt">      virtual function (instance)
 *                   <dt>SE_TAG_FLAG_STATIC<dd style="margin-left:135pt">       static method / member (class)
 *                   <dt>SE_TAG_FLAG_ACCESS<dd style="margin-left:135pt">       public/protected/private/package
 *                   <dt>SE_TAG_FLAG_PUBLIC<dd style="margin-left:135pt">       test equality with (flags & access)
 *                   <dt>SE_TAG_FLAG_PROTECTED<dd style="margin-left:135pt">    protected access
 *                   <dt>SE_TAG_FLAG_PRIVATE<dd style="margin-left:135pt">      private access
 *                   <dt>SE_TAG_FLAG_PACKAGE<dd style="margin-left:135pt">      Java package access
 *                   <dt>SE_TAG_FLAG_CONST<dd style="margin-left:135pt">        C++ const method
 *                   <dt>SE_TAG_FLAG_CONSTEXPR<dd style="margin-left:135pt">    C++11 constexpr
 *                   <dt>SE_TAG_FLAG_CONSTEVAL<dd style="margin-left:135pt">    C++20 consteval
 *                   <dt>SE_TAG_FLAG_CONSTINIT<dd style="margin-left:135pt">    C++20 constinit
 *                   <dt>SE_TAG_FLAG_EXPORT<dd style="margin-left:135pt">       Export symbol from module (C++20)
 *                   <dt>SE_TAG_FLAG_FINAL<dd style="margin-left:135pt">        Java final method or member
 *                   <dt>SE_TAG_FLAG_ABSTRACT<dd style="margin-left:135pt">     abstract/deferred method
 *                   <dt>SE_TAG_FLAG_INLINE<dd style="margin-left:135pt">       inline / out-of-line method
 *                   <dt>SE_TAG_FLAG_OPERATOR<dd style="margin-left:135pt">     overloaded operator
 *                   <dt>SE_TAG_FLAG_CONSTRUCTOR<dd style="margin-left:135pt">  class constructor
 *                   <dt>SE_TAG_FLAG_VOLATILE<dd style="margin-left:135pt">     volatile method or data
 *                   <dt>SE_TAG_FLAG_TEMPLATE<dd style="margin-left:135pt">     template class
 *                   <dt>SE_TAG_FLAG_INCLASS<dd style="margin-left:135pt">      part of class interface?
 *                   <dt>SE_TAG_FLAG_DESTRUCTOR<dd style="margin-left:135pt">   class destructor
 *                   <dt>SE_TAG_FLAG_CONST_DESTR<dd style="margin-left:135pt">  class constructor or destructor
 *                   <dt>SE_TAG_FLAG_SYNCHRONIZED<dd style="margin-left:135pt"> synchronized (thread safe)
 *                   <dt>SE_TAG_FLAG_TRANSIENT<dd style="margin-left:135pt">    transient / persistent data
 *                   <dt>SE_TAG_FLAG_NATIVE<dd style="margin-left:135pt">       Java native method
 *                   <dt>SE_TAG_FLAG_MACRO<dd style="margin-left:135pt">        Tag was part of macro expansion
 *                   <dt>SE_TAG_FLAG_EXTERN<dd style="margin-left:135pt">       "extern" C prototype (not local)
 *                   <dt>SE_TAG_FLAG_MAYBE_VAR<dd style="margin-left:135pt">    Proto may be a var.  Anonymous union.
 *                   <dt>SE_TAG_FLAG_ANONYMOUS<dd style="margin-left:135pt">    Anonymous structure or class
 *                   <dt>SE_TAG_FLAG_MUTABLE<dd style="margin-left:135pt">      mutable C++ class member
 *                   <dt>SE_TAG_FLAG_EXTERN_MACRO<dd style="margin-left:135pt"> external macro (COBOL copy file)
 *                   <dt>SE_TAG_FLAG_LINKAGE<dd style="margin-left:135pt">      01 level var in COBOL linkage section
 *                   <dt>SE_TAG_FLAG_PARTIAL<dd style="margin-left:135pt">      For C# partial class, struct, or interface
 *                   <dt>SE_TAG_FLAG_IGNORE<dd style="margin-left:135pt">       Tagging should ignore this tag/statement
 *                   <dt>SE_TAG_FLAG_FORWARD<dd style="margin-left:135pt">      Forward class/interface/struct/union declaration
 *                   <dt>SE_TAG_FLAG_OPAQUE<dd style="margin-left:135pt">       Opaque enumerated type (unlike C/C++ enum)
 *                   <dt>SE_TAG_FLAG_OVERRIDE<dd style="margin-left:135pt">     Symbol overrides an earlier definition
 *                   <dt>SE_TAG_FLAG_SHADOW<dd style="margin-left:135pt">       Symbol shadows or may be shadowed by another local
 *                   <dt>SE_TAG_FLAG_INFERRED<dd style="margin-left:135pt">     Symbol's return type is inferred from value (auto)
 *                   <dt>SE_TAG_FLAG_NO_COMMENT<dd style="margin-left:135pt">   Symbol has no documentation comment
 *                   </dl>
 * 
 * @param signature  (optional) Tag signature, includes type, value, and arguments for
 *                   the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                   {@link VS_TAGSEPARATOR_equals} for more details about constructing this value.
 *
 * @return 0 on success, &lt;0 on error.
 * @example The following example illustrates tagging some sample Java source code.
 * <pre>
 * package java.lang;
 * /**
 *  * This interface imposes a total ordering on the objects of each class that
 *  * implements it.  This ordering is referred to as the class's <i>natural
 *  * ordering</i>, and the class's <tt>compareTo</tt> method is referred to as
 *  * its <i>natural comparison method</i>.<p>
 *  */
 *  public interface Comparable {
 *         public int compareTo(Object o);
 * }
 * </pre>
 * For the Java code fragment above, {@link tag_insert_simple} would be invoked as
 * follows in order to insert tags into the database.
 * <pre>
 * tag_insert_simple(
 * 			"java.lang", SE_TAG_TYPE_PACKAGE,
 * 			"/usr/jdk1.2/src/java/lang/Comparable.java", 1,
 * 			"", 0, "");
 * tag_insert_simple(
 * 			"Comparable", SE_TAG_TYPE_INTERFACE,
 * 			"/usr/jdk1.2/src/java/lang/Comparable.java", 8,
 * 			"java.lang", SE_TAG_FLAG_INCLASS, "");
 * tag_insert_simple(
 * 			"compareTo", SE_TAG_TYPE_PROTO,
 * 			"/usr/jdk1.2/src/java/lang/Comparable.java", 9,
 * 			"java.lang/Comparable", SE_TAG_FLAG_INCLASS,
 * "int\1Object o");
 * </pre>
 * <p>Note that that tag flags denote access restrictions and other attributes of  class members (proc's, proto's, and var's).  Certain combinations of tag flags are not sensible, others have special meanings.  NOT virtual and NOT static implies normal class method.  NOT protected and NOT private implies public access.  BOTH protected and private implies package access.  NOT const implies normal read/write access.  NOT volatile implies normal optimizations are safe.  NOT template implies normal class definition.
 * <p>Members of an anonymous union have the maybe_var tag flag which in C and C++ implies special rules need to be followed when determining the variable's visibility for Context Tagging&reg;.  For prototypes, the maybe_var flag is set when it is ambiguous whether a tag is a variable declaration (using a class constructor) or a function prototype.
 * <p>Members of a class, struct, package, etc. should have the SE_TAG_FLAG_INCLASS flag set if the member is declared within the scope of the class, etc.  If a class member does not have this flag, it indicates that it is being defined outside of the class definition.  This situation arises in languages such as C++ where a method prototype appears inside the class definition, but the actual function (definition) is outside the class definition.  Distinguishing what is in the class from other tags makes it easy to find the tags belonging to a class without appearing to list duplicates for definitions and declarations.
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_tag
 * @see tag_insert_tag_browse_info
 * @see tag_insert_tag_symbol_info
 *
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_tag_browse_info()} instead
 */
extern int tag_insert_simple(_str tag_name, int type_id, _str file_name, int line_no,
                             _str class_name, int tag_flags, _str signature);

/**
 * Remove the current tag (most recently retrieved tag) from the database.
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_remove_from_file
 * @see tag_remove_from_class
 * @deprecated
 *
 * @categories Tagging_Functions
 */
extern int tag_remove_tag();

/**
 * Remove all tags associated with the given class from the database.
 *
 * @param class_name Full name of the class the tag is associated with
 *                   if NULL, all non-class tags are removed.
 * @param remove_class
 *                   if non-zero, the class is removed from the database,
 *                   in addition to the tags associated with the class.
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_remove_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_remove_from_class(_str class_name, bool remove_class=false);

/**
 * Modify the set of parent classes for a given class.
 * Use the NULL or empty string to indicate that class_name is a base class.
 *
 * @param class_name Qualified name of class or interface to update inheritance
 *                   information for.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for details on constructing this
 *                   string.
 * @param parents    Delimited list of immediate class ancestors.  It is
 *                   important to remember that for some languages, all classes
 *                   have a default ancestor, such as java.lang/Object in Java.
 *                   Otherwise, use the empty string to indicate that class_name
 *                   is a base class.  See {@link VS_TAGSEPARATOR_parents} for more
 *                   details on constructing this string.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_set_inheritance(_str class_name, _str parents);

/**
 * Retrieve the set of parent classes for a given class.
 *
 * <p>This function has the side effect of position the class iterator on the
 * given class.  Returns BT_RECORD_NOT_FOUND_RC if class_name is not
 * in the database.
 *
 * @param class_name       Qualified name of class or interface to update inheritance
 *                         information for.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for details on constructing this string.
 * @param parents          Delimited list of immediate class ancestors. See
 *                         {@link VS_TAGSEPARATOR_parents} for more details on
 *                         decomposing this string.
 *
 * @return 0 on success, &lt;0 on error. Returns BT_RECORD_NOT_FOUND_RC if <i>class_name</i> is
 *         not in the database.
 *
 * @categories Tagging_Functions
 */
extern int tag_get_inheritance(_str class_name, _str &parents);


///////////////////////////////////////////////////////////////////////////
// Retrieval functions

/**
 * Retrieve first tag with the given tag name, type, and class
 * (all are necessary to uniquely identify a tag).  If class_name
 * is unknown, simply use NULL.
 * Use {@link tag_get_info} to extract the details about the tag.
 *
 * @param tag_name         name of tag to search for
 * @param type_name        Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param class_name       name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param arguments        (optional) function arguments to attempt to
 *                         match.  Ignored if they result in no matches.
 * @param file_name        (optional) file to expect tag to be in
 * 
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_find_equal
 * @see tag_find_prefix
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_tag
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_find_tag(_str tag_name, 
                        _str type_name, 
                        _str class_name, 
                        _str arguments=null, 
                        _str file_name=null);

/**
 * Retrieve the next tag with the given name, type, and
 * class (to uniquely identify a tag).  After calling
 * {@link tag_find_tag}, use this function to find other candidates
 * (overloads or duplicates).   Use {@link tag_get_info} to extract
 * the details about the tag.
 *
 * @param tag_name         Name of tag to search for
 * @param type_name        Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param class_name       name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param arguments        (optional) Function parameters to attempt to match to resolve
 *                         overloading.  Ignored if there are no matches.
 * @param file_name        (optional) file to expect tag to be in
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_find_equal
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_next_tag(_str tag_name, 
                        _str type_name, 
                        _str class_name, 
                        _str arguments=null, 
                        _str file_name=null);

/**
 * Reset the tag name iterator.  Call this to indicate that 
 * you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, &lt;0 on error
 *
 * @see tag_get_tag_info
 * @see tag_find_tag
 * @see tag_next_tag
 * @see tag_find_prefix
 * @see tag_next_prefix
 * @see tag_find_equal
 * @see tag_next_equal 
 * @see tag_find_regex
 * @see tag_next_regex 
 * @see tag_match 
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_tag();

/**
 * Retrieve tag in the given file closest to the given line number.  Use {@link tag_get_info}
 * to extract the details about the tag.
 *
 * @param tag_name         Tag name to search for
 * @param file_name        Full path to file containing tag
 * @param line_no          Line that tag is expected to be present on
 *
 * @return 0 on success, &lt;0 on error, or BT_RECORD_NOT_FOUND_RC if no such tag.
 *
 * @see tag_find_equal
 * @see tag_next_equal
 * @see tag_reset_find_tag
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_find_closest(_str tag_name, _str file_name, int line_no, bool case_sensitive=false);

/**
 * Retrieve the first tag with the given tag name. 
 * Use {@link tag_get_tag_browse_info()} to extract the details about the tag.
 *
 * @param tag_name         Name of tag to search for
 * @param case_sensitive   Case sensitive tag name comparison
 * @param class_name       Class name to search for tag in
 *
 * @return 0 on success, &lt;0 on error, or BT_RECORD_NOT_FOUND_RC if no such tag.
 *
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_equal
 * @see tag_next_prefix
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_find_equal(_str tag_name, bool case_sensitive=false, _str class_name=null);

/**
 * Retrieve the next tag with the same tag name as the last one retrieved.
 * Should be called only after calling {@link tag_find_equal} or {@link tag_find_tag}.
 *
 * @param case_sensitive
 *                   Case sensitive tag name comparison
 * @param class_name Class name to search for tag in
 * @param skip_duplicates
 *                   Skip tags with same name, type and class.
 *
 * @return 0 on success, &lt;0 on error, or if no such tag. 
 *  
 * @see tag_find_equal
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_prefix
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_next_equal(bool case_sensitive=false, _str class_name=null,
                          bool skip_duplicates=false);

/**
 * Retrieve the first tag with the given tag name (case-insensitive).
 * Use {@link tag_get_info} to extract the details about the tag.
 *
 * @param tag_prefix       tag name prefix to search for
 * @param case_sensitive   Case sensitive tag name comparison
 * @param class_name       Class name to search for tag in
 *
 * @return 0 on success, &lt;0 on error, or if no such tag.
 *
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_equal
 * @see tag_next_prefix
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_find_prefix(_str tag_prefix, bool case_sensitive=false, _str class_name=null);

/**
 * Retrieve the next tag with the given prefix (case-insensitive).
 * Should be called only after calling vsTagGetTagPrefix().
 * Should be called only after calling {@link tag_find_prefix}.  Use
 * {@link tag_get_info} to extract the details about the tag.
 *
 * @param tag_prefix Prefix of tag name to search for.
 * @param case_sensitive
 *                   Specifies search case sensitivity.
 * @param class_name Name of class that tag belongs to.
 * @param skip_duplicates
 *                   Skip tags with same name, type and class.
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found. 
 *  
 * @see tag_find_equal
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_equal
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_next_prefix(_str tag_prefix, bool case_sensitive=false,
                           _str class_name=null, bool skip_duplicates=false);

/**
 * Retrieve the next tag with the a tag name matching the given
 * regular expression with the given matching options.
 * Use {@link tag_get_info} to extract the details about the tag. 
 *  
 * This function also supports using 's' for search options to indicate 
 * that we should use symbol pattern subword matching instead of a regex. 
 *
 * @param tag_regex        tag name regular expression to search for
 * @param search_options   search options, passed on to {@link pos}()
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see pos
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail 
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_equal
 * @see tag_next_prefix
 * @see tag_next_regex
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_find_regex(_str tag_regex, _str options="");

/**
 * Retrieve the next tag with the a tag name matching the given
 * regular expression with the given matching options.
 * Should be called only after calling {@link tag_find_regex}().
 *  
 * This function also supports using 's' for search options to indicate 
 * that we should use symbol pattern subword matching instead of a regex. 
 *
 * @param tag_regex Regular expression for tag name to search for
 * @param search_options   search options, passed on to {@link pos}()
 *
 * @return 0 on success, &lt;0 on error, or if no such tag. 
 *  
 * @see pos
 * @see tag_find_prefix
 * @see tag_find_tag
 * @see tag_get_detail
 * @see tag_get_info 
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_equal
 * @see tag_next_prefix
 * @see tag_next_regex
 * @see tag_reset_find_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_next_regex(_str tag_regex, _str search_options="");

/**
 * Retrieve general information about the current tag (as
 * defined by calls to <i>tag_find_equal</i>, <i>tag_find_prefix</i>, <i>tag_find_in_file</i>,
 * <i>tag_find_in_class</i>, etc.).  If the current tag is not defined, such as
 * immediately after opening a database or a failed search), all strings
 * will be set to '', and line_no and tag_flags will be set to 0.
 *
 * @param tag_name   (Output) Tag string (native case)
 * @param type_name  (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name  (Output) Full path of file the tag is located in
 * @param line_no    (Output) line number of tag within file
 *                   set to 0 if not defined.
 * @param class_name (Output) name of class that tag is present in,
 *                   uses concatenation (as defined by language rules)
 *                   to specify names of inner classes (see insert, above).
 *                   set to empty string if not defined.
 * @param tag_flags  (Output) Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 *
 * @see tag_get_detail
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_find_equal
 * @see tag_find_in_class
 * @see tag_find_in_file
 * @see tag_find_prefix
 * @see tag_next_equal
 * @see tag_next_in_class
 * @see tag_next_in_file
 * @see tag_next_prefix
 *
 * @categories Tagging_Functions
 *  
 * @deprecated Use {@link tag_get_tag_browse_info()} instead. 
 */
extern void tag_get_info(_str &tag_name, _str &type_name, _str &file_name,
                         int &line_no, _str &class_name, SETagFlags &tag_flags);

/**
 * Retrieve general information about the current tag (as
 * defined by calls to <i>tag_find_equal</i>, <i>tag_find_prefix</i>, 
 * <i>tag_find_in_file</i>, <i>tag_find_in_class</i>, etc.). 
 * If the current tag is not defined, such as
 * immediately after opening a database or a failed search), all strings
 * will be set to "", and line_no and tag_flags will be set to 0.
 *
 * @param cm         (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in. 
 *
 * @see tag_get_info 
 * @see tag_get_detail
 * @see tag_find_equal
 * @see tag_find_in_class
 * @see tag_find_in_file
 * @see tag_find_prefix
 * @see tag_next_equal
 * @see tag_next_in_class
 * @see tag_next_in_file
 * @see tag_next_prefix
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_tag_browse_info(VS_TAG_BROWSE_INFO &cm);

/**
 * Retrieve specific information about the current tag (as defined by calls to
 * <i>tag_find_equal</i>, <i>tag_find_prefix</i>, <i>tag_find_in_file</i>, <i>tag_find_in_class</i>, etc.).
 * This function complements <i>tag_get_info</i>, or can be used in its place for efficiency
 * when only very specific information is needed.
 *
 * @param tag_detail ID of default to extract.  One of the following:
 *
 *                   <dl compact>
 *                   <dt>VS_TAGDETAIL_name<dd style="margin-left:150pt">		(string) tag name
 *                   <dt>VS_TAGDETAIL_type<dd style="margin-left:150pt">	(string) tag type name, see tag_get_type.
 *                   <dt>VS_TAGDETAIL_type_id<dd style="margin-left:150pt">(int) unique id for tag type.
 *                   <dt>VS_TAGDETAIL_file_name<dd style="margin-left:150pt">(string) full path of file the tag is in
 *                   <dt>VS_TAGDETAIL_file_date<dd style="margin-left:150pt">(string) date of file when tagged
 *                   <dt>VS_TAGDETAIL_file_line<dd style="margin-left:150pt">(int) line number of tag within file
 *                   <dt>VS_TAGDETAIL_file_id<dd style="margin-left:150pt">	(int) unique id for file the tag is located in
 *                   <dt>VS_TAGDETAIL_class_simple<dd style="margin-left:150pt">(string) name of class the tag is present in
 *                   <dt>VS_TAGDETAIL_class_name<dd style="margin-left:150pt">(string) name of class with outer classes
 *                   <dt>VS_TAGDETAIL_class_package<dd style="margin-left:150pt">(string) package/namespace tag belongs to
 *                   <dt>VS_TAGDETAIL_class_id<dd style="margin-left:150pt">(int) unique id for class tag belongs to
 *                   <dt>VS_TAGDETAIL_flags<dd style="margin-left:150pt">	(int) tag flags, see tag_insert_simple
 *                   <dt>VS_TAGDETAIL_return<dd style="margin-left:150pt">	(string) value or type of var/function
 *                   <dt>VS_TAGDETAIL_arguments<dd style="margin-left:150pt">(string) function or template arguments
 *                   <dt>VS_TAGDETAIL_tagseekloc<dd style="margin-left:150pt">(int) PRIVATE
 *                   <dt>VS_TAGDETAIL_fileseekloc<dd style="margin-left:150pt">(int) PRIVATE
 *                   <dt>VS_TAGDETAIL_classseekloc<dd style="margin-left:150pt">(int) PRIVATE
 *                   <dt>VS_TAGDETAIL_num_tags<dd style="margin-left:150pt">(int) number of tags in database
 *                   <dt>VS_TAGDETAIL_num_classes<dd style="margin-left:150pt">(int) number of classes in database
 *                   <dt>VS_TAGDETAIL_num_files<dd style="margin-left:150pt">(int) number of files in database
 *                   <dt>VS_TAGDETAIL_num_types<dd style="margin-left:150pt">(int) number of types in database
 *                   <dt>VS_TAGDETAIL_num_refs<dd style="margin-left:150pt">(int) number of references in database
 *                   <dt>VS_TAGDETAIL_throws<dd style="margin-left:150pt">(string) function/proc exceptions.
 *                   <dt>VS_TAGDETAIL_included_by<dd style="margin-left:150pt">(string) file including this macro.
 *                   <dt>VS_TAGDETAIL_return_only<dd style="margin-left:150pt">(string) just the return type of variable.
 *                   <dt>VS_TAGDETAIL_return_value<dd style="margin-left:150pt">(string) default value of variable.
 *                   </dl>
 * @param result     (Output) Set to tag detail after successful completion of function.
 *                   If the current tag is not defined, this will be set to either ''
 *                   or 0, depending on if the detail is a string or numeric.
 *
 * @see tag_get_detail2
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_find_equal
 * @see tag_find_in_class
 * @see tag_find_in_file
 * @see tag_find_prefix
 * @see tag_next_equal
 * @see tag_next_in_class
 * @see tag_next_in_file
 * @see tag_next_prefix
 *
 * @categories Tagging_Functions
 */
extern void tag_get_detail(int tag_detail, var result);


///////////////////////////////////////////////////////////////////////////
// file-name based retrieval functions

/**
 * Find the first tag in the given file.
 * Tags are returned unsorted.
 * Use {@link tag_get_info} to extract the details about the tag.
 *
 * @param file_name        full path of file containing tags
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_get_detail
 * @see tag_get_file
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_in_file
 * @see tag_next_file
 * @see tag_reset_find_in_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_in_file(_str file_name);

/**
 * Find the next tag in the current file. Should be
 * called only after calling {@link tag_find_in_file}.  Tags are
 * returned unsorted. Use {@link tag_get_info} to extract the
 * details about the tag.
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_get_detail
 * @see tag_get_file
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_find_in_file
 * @see tag_next_file 
 * @see tag_reset_find_in_file 
 *
 * @categories Tagging_Functions
 */
extern int tag_next_in_file();

/**
 * Reset the tag find-in-file iterator.  Call this to indicate 
 * that you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, &lt;0 on error 
 *  
 * @see tag_find_in_file
 * @see tag_next_in_file
 * @see tag_get_detail
 * @see tag_get_file
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_in_file();

///////////////////////////////////////////////////////////////////////////
// class-name based retrieval functions

/**
 * Retreive the name of the first class included in this tag database.
 *
 * @param class_id         id of class/package, from {@link tag_get_detail}()
 * @param class_name       (Output) name of class
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_get_detail
 * @see tag_find_class
 * @see tag_next_class
 *
 * @categories Tagging_Functions
 */
extern int tag_get_class(int class_id, _str &class_name);

/**
 * Retrieve the name of the first class included in this tag database, or optionally, the
 * name of a specific class, either to check if the file is in the database or to position
 * the class iterator at a specific point.  If <i>normalize</i> is non-zero, then <i>search_class_name</i>
 * is a simple class name and the search attempts to qualify it with its outer class name
 * or package name, etc., before returning result.  The default search is case-sensitive.
 *
 * @param class_name (Output) Name of class
 * @param search_class_name
 *                   Specific class to search for (prefix search)
 * @param normalize  Attempt to qualify <i>search_class_name</i>
 * @param case_sensitive
 * @param cur_class_name
 *                   Name of current class in context
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_get_class
 * @see tag_next_class
 *
 * @categories Tagging_Functions
 */
extern int tag_find_class(_str &class_name, _str search_class_name=null,
                   bool normalize=false, bool case_sensitive=true,
                   _str cur_class_name=null);

/**
 * Retreive the name of the next class included in this tag database.
 *
 * @param class_name       (Output) Name of class
 * @param search_for       class name to search for (prefix search)
 * @param normalize        Normalize the class name (find what package it belongs to)
 * @param ignore_case      Specifies search case sensitivity.
 * @param cur_class_name   name of current class in context
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_find_class
 * @see tag_get_class
 *
 * @categories Tagging_Functions
 */
extern int tag_next_class(_str &class_name, _str search_class=null,
                   bool normalize=false,bool case_sensitive=true,
                   _str cur_class_name=null);

/**
 * Reset the class name iterator.  Call this to indicate that 
 * you are done searching for class names in the current 
 * database. 
 * 
 * @return 0 on success, &lt;0 on error
 *
 * @see tag_get_class
 * @see tag_find_in_class
 * @see tag_find_class
 * @see tag_next_class
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_class();

/**
 * Find the first tag belonging to the given class.
 * Use {@link tag_get_info} to extract the details about the tag.
 *
 * @param class_name       name of class, containing tags
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_get_class
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_in_class
 * @see tag_next_class
 * @see tag_reset_find_in_class 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_in_class(_str class_name);

/**
 * Find the next tag in the given class. Tags are returned
 * unsorted.  Should be called only after calling
 * {@link tag_find_in_class}. Use tag_get_info to extract the
 * details about the tag.
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_get_class
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_next_in_class
 * @see tag_next_class 
 * @see tag_reset_find_in_class 
 *
 * @categories Tagging_Functions
 */
extern int tag_next_in_class();

/**
 * Reset the tag find-in-class iterator.  Call this to indicate that 
 * you are done searching for tag names in the current database. 
 * 
 * @return 0 on success, &lt;0 on error 
 *  
 * @see tag_find_in_class
 * @see tag_next_in_class
 * @see tag_find_global
 * @see tag_next_global
 * @see tag_get_detail
 * @see tag_get_class
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 *
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_reset_find_in_class();


///////////////////////////////////////////////////////////////////////////
// global identifier retrieval functions

/**
 * Retrieve the first tag included in this tag database with global
 * scope that is one of the given type (type_id) and that
 * matches the given tag flag mask (mask & tag.mask != 0).
 * Tag names are ordered lexicographically, case insensitive.
 * Use {@link tag_get_info} to extract the details about the tag.
 *
 * @param type_id Tag type ID.  See {@link tag_get_type} for a list of all standard tag types.
 *                if (type_id&lt;0), returns tags with ID>SE_TAG_TYPE_LASTID
 * @param mask    Tag flags indicating symbol attributes, see
 *                {@link tag_insert_simple} for details.
 * @param nzero   if 1, succeed if mask & tag.flags != 0
 *                if 0, succeed if mask & tag.flags == 0
 *
 * @return 0 on success, &lt;0 on error.
 * @example The following would be used to find the first inline global function.
 * <pre>
 *   tag_find_global(SE_TAG_TYPE_FUNCTION, SE_TAG_FLAG_INLINE, true);
 * </pre>
 *
 * @see tag_get_type
 * @see tag_next_global
 * @see tag_reset_find_in_class 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_global(int type_id, int mask, int nzero);

/**
 * Retrieve the next tag included in this tag database
 * with global scope that is one of the given type
 * (type_id) and that matches the given tag flag mask
 * ((mask & tag_flags) != 0) == non_zero. Should be
 * called only after calling {@link tag_find_global}.  Use
 * {@link tag_get_info} to extract the details about the tag.
 *
 * @param type_id  First tag type ID.  See {@link tag_get_type} for a list of all standard tag types.
 *                 if (type_id&lt;0), returns tags with ID>SE_TAG_TYPE_LASTID
 * @param mask     Tag flags indicating symbol attributes, see
 *                 {@link tag_insert_simple} for details.
 * @param non_zero if 1, succeed if mask & tag.flags != 0
 *                 if 0, succeed if mask & tag.flags == 0
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_get_type
 * @see tag_find_equal 
 * @see tag_find_global 
 * @see tag_reset_find_in_class 
 *
 * @categories Tagging_Functions
 */
extern int tag_next_global(int type_id, int mask, int non_zero);


///////////////////////////////////////////////////////////////////////////
// Symbol browser related functions

/**
 * Speed-demon way to determine if the given type is a variable type.
 * (var, gvar, lvar, param, prop).
 *
 * @param type_name       string specifying tag's type name
 *
 * @return Returns 1 if the item is a func, 0, otherwise.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_data(_str type_name);

/**
 * Speed-demon way to determine if the given type is a function or
 * procedure type. (proc, proto, func, constr, or destr).
 *
 * @param type_name string specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is a func, 0, otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_func(_str type_name);

/**
 * Determine whether the type is a statement
 *
 * @param type_name        string specifying tag's type name
 *
 * @return 1 if the item is a statement, 0, otherwise.
 *
 * @categories Tagging_Functions
 */
extern int  tag_tree_type_is_statement(_str type_name);

/**
 * Speed-demon way to determine if the given type is a class, struct,
 * or union (class, struct, union).
 *
 * @param type_name String specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is a class, 0, otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_class(_str type_name);

/**
 * Speed-demon way to determine if the given type is a package,
 * library, or program (package, lib, prog).
 *
 * @param type_name String specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is a package, 0 otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_package(_str type_name);

/**
 * Speed-demon way to determine if the given type is an annotation, 
 * #note, #todo, #warning, or #region (annotation, note, todo, warning, region).
 *
 * @param type_name String specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is an annotation, 0 otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_annotation(_str type_name);

/**
 * Speed-demon way to determine if the given type is a function or
 * procedure type. (proc, proto, func, constr, or destr).
 *
 * @param type_name String specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is a database object, 0, otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_database(_str type_name);

/**
 * Speed-demon way to determine if the given type is a constant, enumerator 
 * or #define constant. (constant, enumc, define).
 *
 * @param type_name String specifying tag's type name (from {@link tag_get_info})
 *
 * @return 1 if the item is a constant symbol, 0, otherwise.
 * @see tag_get_type
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_type_is_constant(_str type_name);

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
 *
 * @categories Tagging_Functions
 */
extern int tag_can_be_definition_or_declaration(SETagType tag_type, SETagFlags tag_flags);

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
 *
 * @categories Tagging_Functions
 */
extern int tag_can_have_locals(SETagType tag_type, SETagFlags tag_flags, _str signature=""); 

/**
 * Encode class name, member name, signature, etc. in order to make
 * caption for tree item very quickly.  Returns the resulting tree caption
 * as a NULL terminated string.
 *
 * The output string is generally formatted as follows:
 * <PRE>
 *    member_name[()] &lt;tab&gt; [class_name::member_name[(arguments)]
 * </PRE>
 * Parenthesis are added only for function types (proc, proto, constr, destr, func).
 * The result is returned as a pointer to a static character array.
 *
 * <p>This function is highly optimized, since it is one of the most
 * critical code paths used by the symbol browser.
 *
 * @param member_name
 *                   Name of tag (symbol).
 * @param type_name  Tag type (from {@link tag_get_type}).
 * @param class_name Name of class or package or other container that the tag
 *                   belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about constructing
 *                   this value.  If the tag is not in a class scope, simple
 *                   pass the empty string for this value.
 * @param flags      Set of tag attribute flags.  See {@link tag_insert_simple} for more information about the tag flags.
 * @param arguments  Tag argumetns (from {@link tag_get_detail}).
 * @param include_tab
 *                   append class name after signature if 1,
 *                   prepend class name with :: if 0.
 *
 * @return 
 * Caption formatted in standard form as normally presented in symbol browser.
 * 
 * @example 
 * The following example illustrates constructing a caption for the following C++ class member prototype:
 * <pre>
 * 	static void MyClass::myMember(int a, bool x);
 * </pre>
 * The function would be invoked as follows:
 * <pre>
 * 	tag_tree_make_caption("myMember", "func", "MyClass",
 *         SE_TAG_FLAG_STATIC, "int a, bool x", include_tab);
 * </pre>
 * producing the following caption if include_tab is true:
 * <pre>
 * 	myMember()&lt;tab&gt;MyClass::myMember(int a, bool x)
 * </pre>
 * and the following if include_tab is false.
 * <pre>
 * 	MyClass::myMember(int a, bool x)
 * </pre>
 *
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_instance_info
 * @see tag_tree_make_caption_fast 
 * @see tag_make_caption_from_browse_info 
 * @see tag_make_caption_from_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern _str tag_tree_make_caption(_str member_name, _str type_name, _str class_name,
                                  int flags, _str arguments, bool include_tab=false);

/**
 * For the current tag, local, context, or match item,
 * encode class name, member name, signature, etc. in order
 * to make caption for tree item very quickly.  Returns the
 * resulting tree caption as a NULL terminated string.  See
 * {@link tag_tree_make_caption}() for further details about
 * the output
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 *
 * @param match_type          VS_TAGMATCH_*
 * @param local_or_context_id 0 if inserting current tag from database, 
 *                            otherwise, specifies the unique integer ID of the item from the context,
 *                            locals, or match set, as specified by <i>match_type</i>.
 * @param include_class       if 'false', does not include class name
 * @param include_args        if 'false', does not include function or template signature
 * @param include_tab         append class name after signature if 'true',
 *                            prepend class name with :: if 'false'.
 *
 * @return Caption formatted in standard form as normally presented in
 *         symbol browser.
 * 
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_instance_info
 * @see tag_insert_match_fast
 * @see tag_tree_make_caption
 *
 * @categories Tagging_Functions
 */
extern _str tag_tree_make_caption_fast(int match_type,int local_or_context_id,
                                       bool include_class=true,bool include_args=true,
                                       bool include_tab=false);

/**
 * Encode class name, member name, signature, etc. in order to make
 * caption for a symbol very quickly.  Returns the resulting tree caption
 * as a NULL terminated string.
 *
 * The output string is generally formatted as follows:
 * <PRE>
 *    member_name[()] &lt;tab&gt; [class_name::member_name[(arguments)]
 * </PRE>
 * Parenthesis are added only for function types (proc, proto, constr, destr, func).
 * The result is returned as a pointer to a static character array.
 *
 * <p>This function is highly optimized, since it is one of the most
 * critical code paths used by the symbol browser.
 *
 * @param cm            symbol information
 * @param include_class if 'false', does not include class name
 * @param include_args  if 'false', does not include function or template signature
 * @param include_tab   append class name after signature if 'true',
 *                      prepend class name with :: if 'false'.
 *
 * @return Caption formatted in standard form as normally presented in symbol browser.
 * 
 * @example 
 * The following example illustrates constructing a caption for the following C++ class member prototype:
 * <pre>
 * 	static void MyClass::myMember(int a, bool x);
 * </pre>
 * The function would be invoked as follows:
 * <pre>
 *    tag_init_tag_browse_info(auto cm);
 *    cm.member_name = "myMember";
 *    cm.type_name = "func";
 *    cm.class_name = "MyClass";
 *    cm.flags = SE_TAG_FLAG_STATIC;
 *    cm.arguments = "int a, bool x";
 * 	caption := tag_make_caption_from_browse_info(cm, true, true, include_tab);
 * </pre>
 * producing the following caption:
 * <pre>
 * 	myMember()&lt;tab&gt;MyClass::myMember(int a, bool x)
 * </pre>
 * and the following if include_tab is false.
 * <pre>
 * 	MyClass::myMember(int a, bool x)
 * </pre>
 *
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_instance_info 
 * @see tag_tree_make_caption 
 * @see tag_tree_make_caption_fast
 *
 * @categories Tagging_Functions
 */
extern _str tag_make_caption_from_browse_info(VS_TAG_BROWSE_INFO &cm,
                                              bool include_class=true,
                                              bool include_args=true,
                                              bool include_tab=false);

/**
 * Parse member name out of caption generated using tag_tree_make_caption().
 *
 * @param caption         generated tag caption
 * @param member_name     (Output) tag name only
 * @param class_name      Class name
 * @param arguments       Function arguments
 * @param template_args   Template arguments 
 * @param return_value    Constant or variable initializer value 
 *
 * @categories Tagging_Functions
 */
extern void tag_tree_decompose_caption(_str caption, 
                                       _str &member_name, 
                                       _str &class_name=null,
                                       _str &arguments=null, 
                                       _str &template_args=null, 
                                       _str &return_value=null);

/**
 * Filter the given item based on the given filtering flags,
 * and determine the access level and member type.  Though
 * this function is typically used by the symbol browser for filtering
 * items, it can also be used simply to determine the access level and
 * bitmap type for the tag, just ignore the return value in this case.
 * This function is deprecated, use {@link tag_tree_filter_member2}
 * instead.
 *
 * @param filter_flags
 *                  Filtering options flags, see {@link tag_tree_filter_member2}.
 * @param type_name Tag type, See {@link tag_get_type}.
 * @param in_class  if 1, treat as a class member, (class_name != '')
 * @param tag_flags Set of tag attribute flags.  See {@link tag_insert_simple} for
 *                  more information about the tag flags.
 * @param i_access  (Output) Access level (public, package, protected, or
 *                  private) of tag, see {@link tag_tree_filter_member2}.
 * @param i_type    (Output) Tag bitmap type to use to represent tag, see
 *                  {@link tag_tree_filter_member2}.
 *
 * @return 0 if the item is filtered out, 1 if it passes the filters.
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_type
 * @see tag_tree_filter_member2
 * @see tag_tree_insert_tag 
 *  
 * @deprecated Use {@link tag_tree_filter_member2}
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_filter_member(int filter_flags, 
                                  _str type_name, int in_class,
                                  SETagFlags tag_flags, 
                                  int &i_access, int &i_type);

/**
 * Filter the given item based on the given filtering flags,
 * and determine the access level and member type.  Though
 * this function is typically used by the symbol browser for filtering
 * items, it can also be used simply to determine the access level and
 * bitmap type for the tag, just ignore the return value in this case.
 *
 * @param filter_flags_1
 *                  Filtering options flags, combination of the following:
 *                  <dl compact>
 *                  <dt>CB_SHOW_class_data<dd style="margin-left:150pt">		      static class data members
 *                  <dt>CB_SHOW_instance_data<dd style="margin-left:150pt"> 	      non-static class data members
 *                  <dt>CB_SHOW_out_of_line<dd style="margin-left:150pt"> 		      not inline functions
 *                  <dt>CB_SHOW_inline<dd style="margin-left:150pt">              	inline functions
 *                  <dt>CB_SHOW_static<dd style="margin-left:150pt">              	static functions
 *                  <dt>CB_SHOW_non_virtual<dd style="margin-left:150pt">         	not virtual member functions
 *                  <dt>CB_SHOW_virtual<dd style="margin-left:150pt">             	virtual member functions
 *                  <dt>CB_SHOW_abstract<dd style="margin-left:150pt">            	abstract member functions
 *                  <dt>CB_SHOW_operators<dd style="margin-left:150pt">           	overloaded operators
 *                  <dt>CB_SHOW_constructors<dd style="margin-left:150pt">        	class constructors
 *                  <dt>CB_SHOW_final_members<dd style="margin-left:150pt">       	final class members (Java)
 *                  <dt>CB_SHOW_non_final_members<dd style="margin-left:150pt">   	not final class members
 *                  <dt>CB_SHOW_const_members<dd style="margin-left:150pt">       	const class (C++)
 *                  <dt>CB_SHOW_non_const_members<dd style="margin-left:150pt">   	not const class members
 *                  <dt>CB_SHOW_volatile_members<dd style="margin-left:150pt">    	volatile variables and functions
 *                  <dt>CB_SHOW_non_volatile_members<dd style="margin-left:150pt">  not volatile variables and functions
 *                  <dt>CB_SHOW_template_classes<dd style="margin-left:150pt">    	template (parameterized) classes
 *                  <dt>CB_SHOW_non_template_classes<dd style="margin-left:150pt">	standard (not template) classes
 *                  <dt>CB_SHOW_package_members<dd style="margin-left:150pt">     	members with package scope (Java)
 *                  <dt>CB_SHOW_private_members<dd style="margin-left:150pt">     	members with private scope
 *                  <dt>CB_SHOW_protected_members<dd style="margin-left:150pt">   	members with protected scope
 *                  <dt>CB_SHOW_public_members<dd style="margin-left:150pt">      	members with public scope
 *                  <dt>CB_SHOW_inherited_members<dd style="margin-left:150pt">   	inherited members
 *                  <dt>CB_SHOW_class_members<dd style="margin-left:150pt">       	class member functions
 *                  <dt>CB_SHOW_data_members<dd style="margin-left:150pt">        	class data members
 *                  <dt>CB_SHOW_other_members<dd style="margin-left:150pt">       	other members, not functions or data
 *                  <dt>CB_SHOW_non_abstract<dd style="margin-left:150pt">        	not abstract functions
 *                  <dt>CB_SHOW_non_special<dd style="margin-left:150pt">         	not special functions
 *                  <dt>CB_SHOW_transient_data<dd style="margin-left:150pt">      	transient data members (Java)
 *                  <dt>CB_SHOW_persistent_data<dd style="margin-left:150pt">     	persistent data members (Java)
 *                  <dt>CB_SHOW_synchronized<dd style="margin-left:150pt">        	synchronized functions (Java)
 *                  <dt>CB_SHOW_non_synchronized<dd style="margin-left:150pt">    	not synchronized functions (Java)
 *                  </dl>
 * @param filter_flags_2
 *                  Extended filtering options flags, from the following:
 *                  <dl compact>
 *                  <dt>CB_SHOW_native<dd style="margin-left:120pt">          native functions (Java, others)
 *                  <dt>CB_SHOW_non_native<dd style="margin-left:120pt">      non-native functions (Java, others)
 *                  <dt>CB_SHOW_extern<dd style="margin-left:120pt">          external functions
 *                  <dt>CB_SHOW_non_extern<dd style="margin-left:120pt">      tags not declared extern
 *                  <dt>CB_SHOW_macros<dd style="margin-left:120pt">          tags declared in expanded macro
 *                  <dt>CB_SHOW_non_macros<dd style="margin-left:120pt">      tag not declared in expanded macros
 *                  <dt>CB_SHOW_anonymous<dd style="margin-left:120pt">       anonymous structs, classes, or unions
 *                  <dt>CB_SHOW_non_anonymous<dd style="margin-left:120pt">	named structs, classes, or unions
 *                  </dl>
 * @param type_name tag type (from {@link tag_get_type})
 * @param in_class  if 1, treat as a class member, (class_name != '')
 * @param tag_flags Set of tag attribute flags.  See
 *                  {@link tag_insert_simple} for more information about the tag flags.
 * @param i_access  (Output) access level of tag
 *                  <dl compact>
 *                  <dt>CB_access_public<dd style="margin-left:120pt">    	   public or global scope
 *                  <dt>CB_access_protected<dd style="margin-left:120pt"> 	   protected scope
 *                  <dt>CB_access_private<dd style="margin-left:120pt">   	   private scope
 *                  <dt>CB_access_package<dd style="margin-left:120pt">       package scope (Java)
 *                  </dl>
 * @param i_type    (Output) Tag bitmap type to use to represent tag.
 *                  <dl compact>
 *                  <dt>CB_type_function<dd style="margin-left:120pt">     	function
 *                  <dt>CB_type_prototype<dd style="margin-left:120pt">    	function prototype
 *                  <dt>CB_type_data<dd style="margin-left:120pt">         	variable, global, local, class member
 *                  <dt>CB_type_operator<dd style="margin-left:120pt">     	overloaded operator (C++)
 *                  <dt>CB_type_constructor<dd style="margin-left:120pt">  	class constructor
 *                  <dt>CB_type_destructor<dd style="margin-left:120pt">   	class destructor
 *                  <dt>CB_type_enumeration<dd style="margin-left:120pt">  	value in enumerated type
 *                  <dt>CB_type_typedef<dd style="margin-left:120pt">      	type definition
 *                  <dt>CB_type_define<dd style="margin-left:120pt">       	macro definition
 *                  <dt>CB_type_property<dd style="margin-left:120pt">     	class property (Delphi Object Pascal)
 *                  <dt>CB_type_constant<dd style="margin-left:120pt">     	constant
 *                  <dt>CB_type_label<dd style="margin-left:120pt">        	label (for goto statement)
 *                  <dt>CB_type_import<dd style="margin-left:120pt">       	import statement
 *                  <dt>CB_type_friend<dd style="margin-left:120pt">       	friend relationship (C++)
 *                  <dt>CB_type_index<dd style="margin-left:120pt">        	database index
 *                  <dt>CB_type_trigger<dd style="margin-left:120pt">      	database trigger
 *                  <dt>CB_type_control<dd style="margin-left:120pt">      	GUI control
 *                  <dt>CB_type_menu<dd style="margin-left:120pt">         	GUI menu
 *                  <dt>CB_type_param<dd style="margin-left:120pt">        	function or procedure parameter
 *                  <dt>CB_type_proc<dd style="margin-left:120pt">         	procedure
 *                  <dt>CB_type_procproto<dd style="margin-left:120pt">    	procedure prototype
 *                  <dt>CB_type_include<dd style="margin-left:120pt">      	include statement
 *                  <dt>CB_type_file<dd style="margin-left:120pt">            file descriptor
 *                  <dt>CB_type_subfunc<dd style="margin-left:120pt">         nested function
 *                  <dt>CB_type_subproc<dd style="margin-left:120pt">         nested procedure
 *                  <dt>CB_type_annotation<dd style="margin-left:120pt">      annotation or attribute
 *                  <dt>CB_type_miscellaneous<dd style="margin-left:120pt">	miscellaneous tag type
 *                  <dt>CB_type_undef<dd style="margin-left:120pt">           preprocessing undefine
 *                  <dt>CB_type_user<dd style="margin-left:120pt">            user
 *                  <dt>CB_type_directory<dd style="margin-left:120pt">       directory
 *                  <dt>CB_type_constr_proto<dd style="margin-left:120pt">    prototype for class constructor
 *                  <dt>CB_type_destr_proto<dd style="margin-left:120pt">     prototype for class destructor
 *                  <dt>CB_type_target<dd style="margin-left:120pt">          ANT build target
 *                  <dt>CB_type_operator_proto<dd style="margin-left:120pt">  prototype for operator
 *                  </dl>
 *                  Container types:
 *                  <dl compact>
 *                  <dt>CB_type_struct<dd style="margin-left:120pt">       	struct or record
 *                  <dt>CB_type_enum<dd style="margin-left:120pt">         	enumerated type
 *                  <dt>CB_type_class<dd style="margin-left:120pt">        	class type
 *                  <dt>CB_type_template<dd style="margin-left:120pt">     	template class
 *                  <dt>CB_type_base_class<dd style="margin-left:120pt">   	base class
 *                  <dt>CB_type_package<dd style="margin-left:120pt">      	package, library, program, module
 *                  <dt>CB_type_union<dd style="margin-left:120pt">        	union or variant type
 *                  <dt>CB_type_database<dd style="margin-left:120pt">     	database definition
 *                  <dt>CB_type_table<dd style="margin-left:120pt">        	database table
 *                  <dt>CB_type_form<dd style="margin-left:120pt">         	GUI form or dialog
 *                  <dt>CB_type_eventtab<dd style="margin-left:120pt">     	GUI event table
 *                  <dt>CB_type_task<dd style="margin-left:120pt">         	task (Ada)
 *                  <dt>CB_type_group<dd style="margin-left:120pt">           group variable/structure
 *                  <dt>CB_type_misc<dd style="margin-left:120pt">            miscellaneous container
 *                  <dt>CB_type_tag<dd style="margin-left:120pt">             HTML/XML tag
 *                  <dt>CB_type_statement<dd style="margin-left:120pt">       general statement type
 *                  <dt>CB_type_annotype<dd style="margin-left:120pt">        annotation class type
 *                  <dt>CB_type_assign<dd style="margin-left:120pt">          assignment statement
 *                  <dt>CB_type_call<dd style="margin-left:120pt">            function call statement
 *                  <dt>CB_type_if<dd style="margin-left:120pt">              if or switch statement
 *                  <dt>CB_type_loop<dd style="margin-left:120pt">            for/while/do loop statement   
 *                  <dt>CB_type_break<dd style="margin-left:120pt">           break or exit statement
 *                  <dt>CB_type_continue<dd style="margin-left:120pt">        continue statement
 *                  <dt>CB_type_return<dd style="margin-left:120pt">          return or throw statement
 *                  <dt>CB_type_goto<dd style="margin-left:120pt">            goto statement
 *                  <dt>CB_type_try<dd style="margin-left:120pt">             try statement
 *                  <dt>CB_type_preprocessing<dd style="margin-left:120pt">   preprocessing statement
 *                  <dt>CB_type_interface<dd style="margin-left:120pt">       class interface 
 *                  <dt>CB_type_assign<dd style="margin-left:120pt">          assignment statement
 *                  <dt>CB_type_selector<dd style="margin-left:120pt">        Objective-C selector function
 *                  <dt>CB_type_selector_static<dd style="margin-left:120pt"> Objective-C static selector
 *                  <dt>CB_type_clause<dd style="margin-left:120pt">          statement clause
 *                  <dt>CB_type_query<dd style="margin-left:120pt">           SQL query statement
 *                  <dt>CB_type_block<dd style="margin-left:120pt">           statement block
 *                  </dl>
 *
 * @return 0 if the item is filtered out, 1 if it passes the filters.
 * 
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_type
 * @see tag_tree_insert_tag
 * @see tag_tree_select_bitmap
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_filter_member2(int filter_flags_1, 
                                   int filter_flags_2,
                                   _str type_name, 
                                   int in_class, 
                                   SETagFlags tag_flags,
                                   int &i_access, int &i_type);

/**
 * This function is called to prepare this module for inserting a large
 * number of tags from a common class or category.  It copies a number
 * of options and parameters into globals where they are accessed only
 * by vsTagTreeAddClassMember().  This mitigates the parameter passing
 * overhead normally required by vsTagTreeAddClassMember.
 *
 * @param form_wid          Window ID of form containing the class tree view
 * @param tree_index        Tree parent node index which items will be inserted under.
 * @param tree_wid          Window ID of symbol browser tree control.
 * @param in_refresh non-zero if we are in a refresh operation
 * @param class_filter
 *                   Regular expression for class filtering
 * @param member_filter
 *                   Regular expression for member filtering
 * @param exception_name
 *                   Name of tag to be allowed as an exception even
 *                   if class/member/attribute filtration fails.
 * @param filter_flags
 *                   Attribute (flag-based) filtration flags.  For details, see
 *                   {@link tag_tree_filter_member2}.
 * @param icons      (obsolete, ignored) Two-dimensional array of tag bitmaps.
 * @param filter_flags2  Extended filter flags.  For details, see
 *                   {@link tag_tree_filter_member2}.
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_tree_add_members_in_category
 * @see tag_tree_add_members_in_section
 * @see tag_tree_add_members_of
 * @see tag_tree_insert_tag
 * @see tag_tree_select_bitmap
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_prepare_expand(int form_wid, int tree_index, int tree_wid, int in_refresh,
                            _str class_filter, _str member_filter,
                            _str exception_name, int filter_flags,
                            var icons, int filter_flags2=0);

/**
 * This function is used to get the picture indexes of the icons
 * corresponding to the given i_access level and i_type category.
 * You must call {@link tag_tree_prepare_expand}() prior to calling this function.
 * i_access and i_type are typically obtained from {@link tag_tree_filter_member}.
 *
 * @param i_access   Nenber access level, see {@link tag_tree_filter_member2}.
 * @param i_type     Item type for selecting bitmap, see {@link tag_tree_filter_member2}.
 * @param leaf_flag  (Output) is this item a container or leaf?
 * @param pic_member (Output) picture index for bitmap
 *
 * @see _TreeAddItem
 * @see tag_tree_prepare_expand
 * @see tag_tree_insert_tag
 *
 * @categories Tagging_Functions
 *  
 * @deprecated Use tag_get_bitmap_for_type() instead. 
 */
extern void tag_tree_select_bitmap(int i_access, int i_type, int &leaf_flag, int &pic_member);

/**
 * Simple to use, but very fast entry point for selecting the bitmap
 * to be displayed in the tree control corresponding to the given
 * tag information.  You must call tag_tree_prepare_expand() prior to
 * calling this function.
 *
 * @param filter_flags_1  first part of symbol browser filter flags
 * @param filter_flags_2  second part of symbol browser filter flags
 * @param type_name       tag type name
 * @param class_name      tag class name, just checked for null/empty
 * @param tag_flags       Tag flags indicating symbol attributes, see
 *                        {@link tag_insert_simple} for details.
 * @param leaf_flag       (Output) -1 implies leaf item, 0 or 1 container
 * @param pic_member      (Output) set to picture index of bitmap
 *
 * @return 0 on success, &lt;0 on error, &gt;0 if filtered out.
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_get_bitmap_for_type() instead. 
 */
extern int tag_tree_get_bitmap(int filter_flags_1, int filter_flags_2,
                               _str type_name, 
                               _str class_name, 
                               SETagFlags tag_flags,
                               int &leaf_flag, int &pic_member);

/**
 * Add the members of the given class to the tree view, as
 * configured using tag_tree_prepare_expand.  This function
 * makes the assumption that the same qualified class name
 * will not be used twice in one file to define separate
 * classes.  Languages having preprocessing like C++ can have
 * this problem, the result is that the members of both
 * classes will be merged. The number of items inserted
 * without prompting is defined by the following interpreter
 * variables:
 * <dl compact>
 * <dt><b>def_cbrowser_low_refresh</b><dd style="margin-left:120pt">	During a refresh operation, stop at this many items.
 * <dt><b>def_cbrowser_high_refresh</b><dd style="margin-left:120pt"> 	First prompt at this level, if not refresh operation.
 * <dt><b>def_cbrowser_flood_refresh</b><dd style="margin-left:120pt"> 	Prompt at every multiple of this level.
 * </dl>
 *
 * @param class_name Name of class to add members of, case-sensitive.
 * @param in_file_name
 *                   Only add class members located in this file, use empty string to ignore this constraint.
 * @param tag_file_id
 *                   Unique numeric ID for tag file, 0 for 'current' tag file.
 *                   See {@link tag_tree_set_user_info} for more information about the
 *                   use of this parameter.
 * @param in_count   (Input/Output) Number of items inserted.
 *
 * @return 0 on success, &lt;0 on error.
 * @see tag_tree_add_members_in_category
 * @see tag_tree_add_members_in_section
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 * @see tag_tree_set_user_info
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_add_members_of(_str class_name, _str in_file_name,
                                   int tag_file_id, int &in_count);

/**
 * Add globals with the given type the given category, as set
 * up using {@link tag_tree_prepare_expand}.  Refer to
 * {@link tag_find_global} for details about the parameters <i>type_id</i>,
 * mask, and non_zero.
 *
 * @param type_id  Type id (see {@link tag_get_type})  If <i>(type_id</i>&lt;0), inserts
 *                 global tags with any user defined tag types.
 * @param mask     Tag flags indicating symbol attributes, see
 *                 {@link tag_insert_simple} for details.
 * @param nzero    add member if (mask & tag_flags) is zero or nonzero?
 * @param category_name
 *                 tag category to add members from
 * @param in_count (reference, input, output), number of items inserted
 *
 * @return 0 on error, &lt;0 on error.
 * @see tag_find_global
 * @see tag_get_type
 * @see tag_tree_add_members_in_section
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 * @see tag_tree_set_user_info
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_add_members_in_category(int type_id, int mask, int nzero,
                                            _str category_name, int &in_count);

/**
 * Add globals with the given type the given section of a
 * category, as set up using {@link tag_tree_prepare_expand}.  Refer
 * to {@link tag_find_global} for details about the parameters
 * type_id, mask, and non_zero.  Categories are divided into
 * sections when they have so many items that it would be
 * impractical to attempt to view all the items in the
 * category under one tree node.  Currently sections are not
 * subdivided into subsections, even if they contain
 * thousands of items.
 *
 * @param prefix   Tag name prefix to search for.  If given the specific
 *                 string "[Misc]", it will insert all tags starting with
 *                 characters that are not identifier start characters.
 * @param type_id  Type id (see {@link tag_get_type})  If (<i>type_id</i>&lt;0), inserts global
 *                 tags with any user defined tag types.
 * @param mask     Tag flags indicating symbol attributes, see
 *                 {@link tag_insert_simple} for details.
 * @param nzero    add member if (mask & tag_flags) is zero or nonzero?
 * @param category_name
 *                 tag category to add members from
 * @param in_count (Input, Output), number of items inserted.
 *                 See {@link tag_tree_add_members_of} for more information about how
 *                 this relates to refresh operations and prompting.
 *
 * @return 0 on error, &lt;0 on error.
 * @see tag_find_global
 * @see tag_get_type
 * @see tag_tree_add_members_in_category
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 * @see tag_tree_set_user_info
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_add_members_in_section(_str prefix, int type_id, int mask, int nzero,
                                           _str category_name, int &in_count);

/**
 * Encode the given tag as a string.  The format of the entire string is as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 * <p>The class_name is optional, if not given the string may be encoded as follows, indicating that the tag is a global:
 * <pre>
 *       <i>tag_name</i> ( <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 *
 * <p>The type_name, arguments, and return_type are also optional.  If both the arguments and return_type are omitted, the tag is encoded as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i>
 * </pre>
 * <p>Furthermore, if tag_flags is 0, it is omitted.
 *
 * <p>Note that the encoding format is not resilient against names that contain special characters, however, within the argument list, it is allowed to have parenthesis, as long as they are balanced.
 *
 * <p>The extension specific procedure and local variable search functions (_[ext]_proc_search) return tags using the format described above.  This function may be used to easily and efficiently implement that part of a proc search function
 *
 * @param tag_name   Name of  tag (symbol) to encode.
 * @param class_name Name of class or package or other container that the tag belongs
 *                   to.  See {@link VS_TAGSEPARATOR_class} and {@link VS_TAGSEPARATOR_package} for
 *                   more details about constructing this value.  If the tag is not
 *                   in a class scope, simple pass the empty string for this value.
 * @param type_name  Tag type name, see {@link tag_get_type} for standard tag types
 * @param tag_flags  Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param arguments  Arguments, such as function or template class parameters.
 * @param return_type
 *                   Return type of symbol or value of constant or both
 *                   separated by {@link VS_TAGSEPARATOR_equals}.
 *
 * @return String representation for the tag passed in.
 * @see tag_tree_decompose_tag
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_compose_tag_browse_info() instead. 
 */
extern _str tag_tree_compose_tag(_str tag_name, 
                                 _str class_name, 
                                 _str type_name,
                                 SETagFlags tag_flags=SE_TAG_FLAG_NULL,
                                 _str arguments="",
                                 _str return_type="", 
                                 ...);

/**
 * Initialize a tag browse info structure. 
 *  
 * @param cm               (output) symbol information (VS_TAG_BROWSE_INFO)
 * @param tag_name         name of symbol 
 * @param class_name       name of class that tag belongs to
 * @param type_name        type of tag, (see SE_TAG_TYPE_*)
 * @param tag_flags        tag attributes (see SE_TAG_FLAG_*)
 * @param file_name        path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param seekpos          file offset that tag is positioned on
 * @param arguments        function arguments
 * @param return_type      function/variable return type 
 *
 * @see tag_decompose_tag_browse_info
 * @see tag_compose_tag_browse_info
 *
 * @categories Tagging_Functions 
 */
extern void tag_init_tag_browse_info(VS_TAG_BROWSE_INFO &cm,
                                     _str tag_name="",
                                     _str class_name="",
                                     _str type_name_or_id="",
                                     SETagFlags tag_flags=SE_TAG_FLAG_NULL,
                                     _str file_name="",
                                     int line_no=0, long seekpos=0,
                                     _str arguments="",
                                     _str return_type="");

/**
 * Encode the given tag as a string.  The format of the entire string is as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 * <p>The class_name is optional, if not given the string may be encoded as follows, indicating that the tag is a global:
 * <pre>
 *       <i>tag_name</i> ( <i>type_name</i> ) <i>tag_flags</i> ( <i>arguments</i> ) <i>return_type</i>
 * </pre>
 *
 * <p> 
 * The type_name, arguments, and return_type are also optional. 
 * If both the arguments and return_type are omitted, the tag is encoded as follows:
 * <pre>
 *       <i>tag_name</i> ( <i>class_name</i> : <i>type_name</i> ) <i>tag_flags</i>
 * </pre>
 * <p>Furthermore, if tag_flags is 0, it is omitted.
 *
 * <p> 
 * Note that the encoding format is not resilient against names that contain special characters, 
 * however, within the argument list, it is allowed to have parenthesis, as long as they are balanced.
 *
 * <p> 
 * The extension specific procedure and local variable search functions (_[ext]_proc_search) 
 * return tags using the format described above. 
 * This function may be used to easily and efficiently implement that part of a proc search function.
 *
 * @param cm   (input) symbol information
 *
 * @return String representation for the tag passed in.
 * @see tag_decompose_tag_browse_info
 *
 * @categories Tagging_Functions 
 */
extern _str tag_compose_tag_browse_info(VS_TAG_BROWSE_INFO &cm);

/**
 * Decode the given proc_name into the components of the tag.  See
 * {@link tag_tree_compose_tag} for details about how tags are encoded as strings.
 *
 * @param proc_name  Encoded tag from {@link tag_tree_compose_tag} on an extension specific tag search function.
 * @param tag_name   (Output) the name of the tag
 * @param class_name (Output) class/container the tag belongs to
 * @param type_name  (Output) Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param tag_flags  (Output) Tag flags indicating symbol attributes, see
 *                   (Output) {@link tag_insert_simple} for details.
 * @param arguments  Arguments, such as function or template class parameters.
 * @param return_type
 *                   (Output) Return type of symbol or value of constant or both,
 *                   separated by {@link VS_TAGSEPARATOR_equals}.
 *
 * @see tag_tree_compose_tag
 *
 * @categories Tagging_Functions
 *  
 * @deprecated Use tag_compose_tag_browse_info() instead. 
 */
extern void tag_tree_decompose_tag(_str proc_name, _str &tag_name, _str &class_name,
                                   _str &type_name, int &tag_flags,
                                   _str &arguments=null, _str &return_type=null,
                                   _str &template_args=null);

/**
 * Decode the given proc_name into the components of the tag.  See
 * {@link tag_tree_compose_tag} for details about how tags are encoded as strings.
 *
 * @param proc_name  Encoded tag from {@link tag_tree_compose_tag} on an extension specific tag search function.
 * @param cm         (output) symbol information
 *
 * @see tag_compose_tag_browse_info
 *
 * @categories Tagging_Functions
 */
extern void tag_decompose_tag_browse_info(_str proc_name, VS_TAG_BROWSE_INFO &cm);

/**
 * Pretty-print function arguments to output buffer
 *
 * @param signature Return type and parameters of tag, as stored in the
 *                  database, including {@link VS_TAGSEPARATOR_args} to separate the
 *                  return type from the parameters.
 *
 * @return The output is returned in a staticly allocated string pointer.
 * @see tag_get_detail
 * @see tag_tree_make_caption
 *
 * @categories Tagging_Functions
 */
extern _str tag_tree_format_args(_str signature);

/**
 * API function for inserting a tag entry with supporting info into
 * the given tree control.
 *
 * @param tree_wid   Window ID of the tree control to insert into.
 * @param tree_index Parent tree node index to insert item under.
 * @param include_tab
 *                   append class name after signature if 1,
 *                   prepend class name with :: if 0.
 *                   See {@link tag_tree_make_caption} for further explanation.
 * @param force_leaf if &lt;0, force leaf node, otherwise choose by type.
 *                   Normally "container" tag types, such as classes or structs are automatically inserted as non-leaf nodes.
 * @param tree_flags flags passed to {@link _TreeAddItem}.
 * @param tag_name   Name of  tag (symbol) to add to database.
 * @param type_name  Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 *                   Generally the tag type is a single word, all lowercase.  If the string given is not a standard type, a new user defined type will be inserted into the database.
 * @param file_name  Path to file that is located in
 * @param line_no    Line number that tag is positioned on.
 *                   Use 0 to represent an unknown line number.
 * @param class_name Name of class or package or other container that the tag
 *                   belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about
 *                   constructing this value.  If the tag is not in a class
 *                   scope, simple pass the empty string for this value.
 * @param tag_flags  Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param signature  Tag signature, includes type, value, and arguments for
 *                   the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                   {@link VS_TAGSEPARATOR_equals} for more details about constructing
 *                   this value.
 * @param user_info  Per-node user data for tree control 
 *
 * @return tree index of new item on success, &lt;0 on error. 
 *  
 * @see _TreeAddItem
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_type
 * @see tag_insert_tag
 * @see tag_tree_insert_fast
 * @see tag_tree_make_caption
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_insert_tag(int tree_wid, int tree_index, int include_tab,
                               int force_leaf, int tree_flags, _str tag_name,
                               _str type_name, _str file_name, int line_no,
                               _str class_name, int tag_flags, _str signature,
                               ... /*, typeless user_info=null */ );

/**
 * This optimized version of tag_tree_insert_tag is used to
 * quickly insert an item from the current tag database,
 * context, locals, or match set into a tree control at the
 * specified location.  Use {@link tag_tree_prepare_expand} prior to
 * calling this function in order to configure the browser
 * bitmap set.
 *
 * @param tree_wid   Window ID of the tree control to insert into.
 * @param tree_index Parent tree node index to insert item under.
 * @param match_type Specifies where the tag to insert comes from:
 *                   <dl>
 *                   <dt>VS_TAGMATCH_tag<dd style="margin-left:120pt">		current tag from database
 *                   <dt>VS_TAGMATCH_context<dd style="margin-left:120pt">	item in current context (buffer)
 *                   <dt>VS_TAGMATCH_local<dd style="margin-left:120pt">  		item in local variable set (function)
 *                   <dt>VS_TAGMATCH_match<dd style="margin-left:120pt">  	item in match set
 *                   </dl>
 * @param local_or_context_id
 *                   0 if inserting current tag from database, otherwise,
 *                   specifies the unique integer ID of the item from the
 *                   context, locals, or match set, as specified by <i>match_type</i>.
 * @param include_tab
 *                   append class name after signature if 1,
 *                   prepend class name with :: if 0.
 *                   See {@link tag_tree_make_caption} for further explanation.
 * @param force_leaf If &lt;0, force leaf node, otherwise choose by tag type.
 *                   Normally "container" tag types, such as classes or structs
 *                   are automatically inserted as non-leaf nodes.
 * @param tree_flags Flags passed to {@link _TreeAddItem}.
 * @param include_sig
 *                   include function/define/template signature
 * @param include_class
 *                   include class name
 * @param user_info  Per-node user data for tree control 
 *
 * @return tree index on success, &lt;0 on error.
 * @see _TreeAddItem
 * @see tag_insert_context
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_tree_insert_tag
 * @see tag_tree_make_caption
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_insert_fast(int tree_wid, int tree_index, int match_type,
                                int local_or_context_id, int include_tab, int force_leaf,
                                int tree_flags, int include_sig, int include_class,
                                ... /*, typeless user_info=null */ );

/**
 * API function for inserting a tag entry with supporting info into
 * the given list control.
 *
 * @param list_wid   Window ID of the list control.
 * @param include_tab
 *                   If 0, does not create separate tab for details, see
 *                   {@link tag_tree_make_caption} for further explanation.
 * @param indent_x   Indent after bitmap, if 0, use default of 60 (TWIPS)
 * @param tag_name   Name of tag (symbol) to add to database.
 * @param type_name   Tag type name.  See {@link tag_get_type} for a list of all
 *                   standard tag types.  Generally the tag type is a single
 *                   word, all lowercase.  If the string given is not a
 *                   standard type, a new user defined type will be inserted
 *                   into the database.
 * @param file_name  Full path to source file the tag is located in.
 * @param line_no    Line number where the tag begins in <i>file_name</i>.  Use 0 to
 *                   represent an unknown line number.
 * @param class_name Name of class or package or other container that the
 *                   tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about
 *                   constructing this value.  If the tag is not in a
 *                   class scope, simple pass the empty string for this value.
 * @param tag_flags  Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param signature  Tag signature, includes type, value, and arguments for
 *                   the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                   {@link VS_TAGSEPARATOR_equals} for more details about
 *                   constructing this value.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see _lbadd_item
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_get_type
 * @see tag_insert_tag
 * @see tag_tree_insert_tag
 * @see tag_tree_make_caption
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_insert_tag(int list_wid, int include_tab, int indent_x,
                               _str tag_name, _str type_name, _str file_name,
                               int line_no, _str class_name, int tag_flags, _str signature);

/**
 * Compare the two argument lists, this method works for both
 * Delphi/Pascal/Ada style arguments and C/C++/Java style arguments.
 *
 * @param arg_list1 Argument list number 1
 * @param arg_list2 Argument list number 2
 * @param unqualify Loose comparison, peel off class qualifications
 *
 * @return 0 if they match, nonzero otherwise.
 *
 * @see tag_get_detail
 * @see tag_tree_format_args
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_compare_args(_str arg_list1, _str arg_list2, bool unqualify);

/**
 * <p>This function sets the user data for the given node in the given
 * tree calculated using the algorithm designed for the symbol browser,
 * creating a (potentially) large integer that may be decomposed to
 * reveal a tag file ID, file ID, and line number.
 * <p>The formula used to compute the integer stored is as follows:
 * <pre>
 *     <i>tag_file_id</i> * CB_MAX_LINE_NUMBER * CB_MAX_FILE_NUMBER
 *       + <i>file_id</i> * CB_MAX_LINE_NUMBER + line_no
 * </pre>
 * <p>In most cases, tag_file_id is 0, allowing the result to fit in a
 * normal 32-bit unsigned integer providing that the file_id is
 * sufficiently small.
 *
 * <p>The tag_file_id, file_id, and line_no identify the tag file name
 * and location in source code for the given tag.  This information,
 * together with the name of the tag from the caption is normally
 * adequate to uniquely identify a tag in a tag database.  The reason
 * for encoding them into a single integer is simply for efficiency and
 * space-savings.  If this information were stored and not encoded in
 * this manner, a tree with 10,000 or more tags displayed would require
 * megabytes of memory, whereas using this scheme it only requires a few
 * hundred kilobytes, as well as mitigating memory fragmentation
 *
 * @param tree_wid   Window ID of the tree control to set user info for
 * @param tree_index Parent tree node index of node in tree to set info at
 * @param tag_file_id
 *                   Unique numeric ID for tag file, 0 for 'current' tag file.
 *                   Each tag file displayed in the symbol browser is
 *                   assigned a unique integer ID, simply numbering them
 *                   sequentially. The need for the tag file ID stems
 *                   from using the raw <i>file_id</i>, which only makes
 *                   sense in the context of a particular tag file.
 * @param file_id    file ID from {@link tag_get_detail} of item being added to tree (0 for current)
 * @param line_no    line number at which tag occurs
 *
 * @see _TreeSetUserInfo
 * @see tag_get_detail
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern void tag_tree_set_user_info(int tree_wid, int tree_index, int tag_file_id,
                                   int file_id, int line_no);


/**
 * Format the given comment text as an HTML comment for displaying as 
 * documentation comment help or function parameter help, or in the 
 * Preview tool window.
 * 
 * @param html_text                [output] html formatted comment
 * @param comment_flags            bitset of VSCODEHELP_COMMENTFLAG_*
 * @param comment_text             comment text extracted from source code
 * @param param_name               current function parameter name
 * @param lang_id                  current function's language mode
 * @param return_type              current function's return type
 * @param make_categories_links    make help links for Slick-C comment categories
 * @param doxygen_all              process all Doxygen style tags
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_make_html_comment(_str &html_text,
                                      int comment_flags, 
                                      _str comment_text,
                                      _str param_name="",
                                      _str return_type="",
                                      _str lang_id="",
                                      bool make_categories_links=false,
                                      bool doxygen_all=def_doxygen_all);

/**
 * Format the given comment link text as a HTML hyperlink.
 * 
 * @param html_text             [output] html formatted comment
 * @param href_text             contents of link tag 
 * @param comment_flags         bitset of VSCODEHELP_COMMENTFLAG_*
 * 
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_make_html_seeinfo(_str &html_text, _str href_text, int comment_flags=0);

/**
 * Parse the given JavaDoc comment into it's components and return them in 
 * a hash table for easier handling. 
 * 
 * @param member_msg    [input/output] text of JavaDoc comment with comment delimeters removed
 * @param description   [output] Set to leading description portion of JavaDoc comment
 * @param tagStyle      [output] Set to '@' or '\' for JavaDOc or Doxygen style comment delimeters
 * @param hashtab       [output] hash table of comment segments
 * @param tagList       [output[ array of JavaDoc tags (keys of 'hashtab')
 * @param TranslateThrowsToException  Translate '@throws' to '@exception'
 * @param isDoxygen     Process doxygen tags and formatting instructions
 * @param skipBrief     Skip comment summary (@brief)
 * 
 * @return 0 on success, &lt; 0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_parse_javadoc_comment(_str &member_msg,
                                          _str &description,
                                          _str &tagStyle, 
                                          _str (&hashtab):[][],
                                          _str (&tagList)[],
                                          bool TranslateThrowsToException=true,
                                          bool isDoxygen=false, 
                                          bool skipBrief=true);


/**
 * Parse a multi-line comment and strip off comment delimeters and determine 
 * the documentation comment type. 
 * 
 * @param comment_lines                Slick-C array of strings (lines of comment)
 * @param line_comment_indent_col      line comment indent column
 * @param first_line                   first line number of comment lines
 * @param last_line                    last line number of commment lines
 * @param line_limit                   comment line parsing limit
 * @param comment_flags                [output] set to comment flags to indicate comment type
 * @param comments                     [output] set to contents of processed comment
 * @param line_prefix                  [output] set to comment line prefix
 * @param doxygen_comment_start        [output] set to doxygen comment start chars (/ *! or //!)
 * @param blanks                       [output] indexes blank lines with javadoc comments
 * @param langId                       language ID of file comment was extracted from
 * @param word_chars                   word_chars (and extra word chars) for current file
 * @param isDBCS                       true of the current buffer is DBCS content
 * 
 * @return 0 on success, &lt; 0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_parse_multiline_comment(_str (&comment_lines)[],
                                           int line_comment_indent_col,
                                           int first_line,
                                           int last_line,
                                           int line_limit,
                                           int &comment_flags,
                                           _str &comments,
                                           _str &line_prefix,
                                           _str &doxygen_comment_start,
                                           int (&blanks):[][],
                                           _str langId,
                                           _str word_chars,
                                           int isDBCS);


///////////////////////////////////////////////////////////////////////////
// Functions for tracking tag instances

/**
 * Insert the given tag instance into a references database. If an exact match already exists in the database, then just return the existing ID.  This function is comparable to tag_insert_simple and tag_insert_tag, except that it is specifically tuned for references database.  The most specific difference is the fact that this function returns a unique ID for the instance which is stored in the database as a key, which is not needed for tag databases.  However in a references database, this key is required in order to efficiently index and store huge cross references databases.
 *
 * @param inst_name  name of tag instance (case insensitive)
 * @param inst_type  Tag type name.  See {@link tag_get_type} for a list of
 *                   all standard tag types.
 * @param inst_flags Set of the following instance attribute flags, as applicable.
 *                   <dl compact>
 *                   <dt>VS_INSTFLAG_virtual<dd style="margin-left:120pt">		virtual function (instance)
 *                   <dt>VS_INSTFLAG_static<dd style="margin-left:120pt">		static method / member (class)
 *                   <dt>VS_INSTFLAG_const<dd style="margin-left:120pt">		C++ const method
 *                   <dt>VS_INSTFLAG_volatile<dd style="margin-left:120pt">		C/C++ volatile method
 *
 *                   </dl>
 * @param inst_class Name of class or package or other container that the
 *                   tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about
 *                   constructing this value.  If the tag is not in a
 *                   class scope, simple pass the empty string for this value.
 * @param inst_args  arguments associated with tag (eg. function args)
 * @param file_name  name of file where tag instance is located
 * @param line_no    Line number where the tag begins in <i>file_name</i>.  Use 0 to
 *                   represent an unknown line number.
 *
 * @return tag instance ID (&gt;0) on success, &lt;0 on error.
 * @example The following example illustrates tagging references.
 * <pre>
 * static void foo(int a) {
 *     printf("a=%d\n",a);
 *     bar(a+1);
 * }
 * static void bar(int ap1) {
 *      if (a&gt;1000) return;
 *      foo(a*2);
 * }
 * int main(int argc, char *argv[]) {
 *      foo( 0 );
 *      return 0;
 * }
 * </pre>
 * <p>For the C code fragment above, {@link tag_insert_instance} and {@link tag_insert_reference}
 *  would be invoked as follows in order to create a references database.
 *
 * <pre>
 * tag_insert_instance(
 * 			"foo", "func", VS_INSTFLAG_static,
 * 			"", "int a", "/home/vslick/docs/testrefs.c", 1);   // returns 1
 * tag_insert_instance(
 * 			"bar", "func", VS_INSTFLAG_static,
 * 			"", "int ap1", "/home/vslick/docs/testrefs.c", 5);  // returns 2
 * tag_insert_instance(
 * 			"main", "func", 0,
 * 			"", "int argc, char*argv[]",
 *          "/home/vslick/docs/testrefs.c", 9);  // returns 3
 * tag_insert_instance(
 * 			"printf", "func", 0,
 * 			"", "const char*, . . . "/usr/include/stdio.h", 312);  // returns 4
 *
 * tag_insert_reference(
 * 			4, 1, "/home/vslick/docs/testrefs.c",
 * 			VS_REFTYPE_call, "/home/vslick/docs/testrefs.c", 2);
 * tag_insert_reference(
 * 			2, 1, "/home/vslick/docs/testrefs.c",
 * 			VS_REFTYPE_call, "/home/vslick/docs/testrefs.c", 3);
 * tag_insert_reference(
 * 			1, 2, "/home/vslick/docs/testrefs.c",
 * 			VS_REFTYPE_call, "/home/vslick/docs/testrefs.c", 7);
 * tag_insert_reference(
 * 			1, 3, "/home/vslick/docs/testrefs.c",
 * 			VS_REFTYPE_call, "/home/vslick/docs/testrefs.c", 10);
 * </pre>
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_reference
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_instance(_str inst_name, _str inst_type, int inst_flags,
                               _str inst_class, _str inst_args, _str file_name, int line_no);

/**
 * Extract the supplementary information associated with a tag instance.
 *
 * @param inst_id          Unique ID of instance to get info about.
 *                         Use {@link tag_match_instance()} to get this ID.
 * @param inst_name        (Output) Name of tag instance (case insensitive)
 * @param inst_type        (Output) Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param inst_flags       (Output) Reference attributes (see VS_REFFLAG_*)
 * @param inst_class       (Output) class associated with tag (zero for global)
 * @param inst_args        (Output) Arguments associated with tag (eg. function args)
 * @param file_name        (Output) Name of file where tag instance is located
 * @param line_no          (Output) Line which tag instance is on
 *
 * @see tag_find_refer_by
 * @see tag_find_refer_to
 * @see tag_insert_instance
 * @see tag_match_instance
 * @see tag_next_refer_by
 * @see tag_next_refer_to
 *
 * @categories Tagging_Functions
 */
extern void tag_get_instance_info(int inst_id, _str & inst_name, _str &inst_type,
                                  SETagFlags &inst_flags, _str &inst_class, _str &inst_args,
                                  _str &file_name,  int &line_no);

/**
 * Locate the tag instance matching the given parameters.
 * Instances are matched by tag name first (which must match),
 * then class, type, flags, arguments, and finally file and
 * line proximity.
 *
 * @param inst_name  Name of tag (symbol) instance (case insensitive)
 * @param inst_type  Tag type name.  See {@link tag_get_type} for a list of all
 *                   standard tag types.
 * @param inst_flags Set of the following instance attribute flags, as
 *                   applicable.  See {@link tag_insert_instance} for more
 *                   information.
 * @param inst_class Name of class or package or other container that the
 *                   tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details about
 *                   constructing this value.  If the tag is not in a
 *                   class scope, simple pass the empty string for this value.
 * @param inst_args  Arguments associated with tag (eg. function args)
 * @param file_name  Name of file where tag instance is located
 * @param line_no    line which tag instace is on
 * @param case_sensitive
 *                   Specifies search case sensitivity.
 *
 * @return The ID of the the most exact match available, or &lt;0 on error.
 * @see tag_find_refer_by
 * @see tag_insert_instance
 * @see tag_next_refer_by
 * @see tag_next_refer_to
 *
 * @categories Tagging_Functions
 */
extern int tag_match_instance(_str inst_name, _str inst_type, int inst_flags,
                              _str inst_class, _str inst_args, _str file_name,
                              int line_no, int case_sensitive);


///////////////////////////////////////////////////////////////////////////
// Functions for tracking tag references

/**
 * Add a tag reference located in the given file name and
 * line number representing that the tag instance
 * (ref_to_id) used within the context (ref_by_id), also
 * a tag instance.  See {@link tag_insert_instance} for an example
 * showing how this function is used.
 *
 * @param refto_id  unique ID of tag referenced from {@link tag_insert_instance} or {@link tag_match_instance}.
 * @param refby_id  Unique ID of the context (where the reference occurred)
 *                  of  from {@link tag_insert_instance} or {@link tag_match_instance}.
 *                  Use 0 to represent the global context or if the context is unknown.
 * @param ref_file  name of references (browse database or object) file
 * @param ref_type  type of reference.  One of the following:
 *                  <dl compact>
 *                  <dt>VS_REFTYPE_unknown<dd style="margin-left:120pt">		unspecified type of reference
 *                  <dt>VS_REFTYPE_macro<dd style="margin-left:120pt">		use of #define'd macro
 *                  <dt>VS_REFTYPE_call<dd style="margin-left:120pt">		function or procedure call
 *                  <dt>VS_REFTYPE_var<dd style="margin-left:120pt">		use of a variable
 *                  <dt>VS_REFTYPE_import<dd style="margin-left:120pt">		use/import of a package
 *                  <dt>VS_REFTYPE_derive<dd style="margin-left:120pt">		class derivation
 *                  <dt>VS_REFTYPE_type<dd style="margin-left:120pt">		use of abstract type
 *                  <dt>VS_REFTYPE_class<dd style="margin-left:120pt">		instantiation of class
 *                  <dt>VS_REFTYPE_constant<dd style="margin-left:120pt">		use of constant value or enum value
 *                  <dt>VS_REFTYPE_label<dd style="margin-left:120pt">		use of label for goto
 *                  </dl>
 * @param file_name name of file where reference occurs
 * @param line_no   Line number where the reference begins in <i>file_name</i>.
 *                  Use 0 to represent an unknown line number.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_instance
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_reference(int refto_id, int refby_id, _str ref_file,
                                int ref_type, _str file_name, int line_no);

/**
 * Find the first tag instance referenced by the given tag instance.
 * The tag is identified by its unique ID, see {@link tag_match_instance}().
 * This is typically used with functions (caller/callee relationship)
 * or structures (container/item relationships).
 *
 * @param inst_id          Unique ID of tag instance.
 * @param ref_type         (Output) reference type (see VS_REFTYPE_*)
 * @param file_name        (Output) Full path of file the tag is located in
 * @param line_no          (Output) Line number of tag within file
 *
 * @return Returns instance ID (&gt;0) of tag referenced in context
 *   represented by <i>inst_id</i> or &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_get_instance_info
 * @see tag_match_instance
 * @see tag_next_refer_to
 *
 * @categories Tagging_Functions
 */
extern int tag_find_refer_to(int inst_id, int &ref_type, _str &file_name, int &line_no);

/**
 * Find the next tag instance referenced by the given tag
 * instance.  The tag is identified by its unique ID, see
 * {@link tag_match_instance}.  This is typically used with functions
 * (caller/callee relationship) or structures and classes
 * (container/item relationships).  Should be called only
 * after calling {@link tag_find_refer_to}.
 *
 * @param inst_id   Unique ID of tag instance.
 * @param ref_type  (Output) Type of reference, see {@link tag_insert_reference}.
 * @param file_name (Output) Full path of file the tag is located in
 * @param line_no   (Output) Line number of tag within file
 *
 * @return Returns instance ID (&gt;0) of tag referenced in context
 *         represented by inst_id or &lt;0 on error,
 *         BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_get_instance_info
 * @see tag_match_instance
 * @see tag_find_refer_to
 *
 * @categories Tagging_Functions
 */
extern int tag_next_refer_to(int inst_id, int &ref_type, _str &file_name, int &line_no);

/**
 * Find the first location in which the given tag is referenced.
 * The tag is identified by its unique ID, see {@link tag_match_instance}().
 *
 * @param inst_id          Unique ID of tag instance.
 * @param ref_type         (Output) Reference type (see VS_REFTYPE_*)
 * @param file_name        (Output) Full path of file the tag is located in
 * @param line_no          (Output) Line number of tag within file
 *
 * @return Returns instance ID (&gt;0) of context of reference, 0 if
 *    unknown, or &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @see tag_get_instance_info
 * @see tag_match_instance
 * @see tag_next_refer_by
 *
 * @categories Tagging_Functions
 */
extern int tag_find_refer_by(int inst_id, int &ref_type, _str &file_name, int &line_no);

/**
 * Find the next location in which the given tag is
 * referenced.  The tag is identified by its unique ID, see
 * {@link tag_match_instance}.  Should be called only after calling
 * {@link tag_find_refer_by}.
 *
 * @param inst_id   Unique identifier of calling function.
 * @param ref_type  (Output) Type of reference, see {@link tag_insert_reference}.
 * @param file_name (Output) Full path of file the tag is located in
 * @param line_no   (Output) Line number of tag within file
 *
 * @return Returns instance ID (&gt;0) of context of reference, 0 if unknown, or
 * &lt;0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 * @see tag_get_instance_info
 * @see tag_match_instance
 * @see tag_find_refer_by
 *
 * @categories Tagging_Functions
 */
extern int tag_next_refer_by(int inst_id, int &ref_type, _str &file_name, int &line_no);



///////////////////////////////////////////////////////////////////////////
//  Context tracking related functions.

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_context}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param outer_context    Unique ID of outer context tag, such as a class the
 *                         current tag is nested inside.  If not applicable or unknown, use 0
 * @param tag_name         tag string
 * @param type_name         Tag type name. See {@link tag_get_type}.
 * @param file_name        full path of file the tag is located in ({@link p_buf_name})
 * @param start_line_no    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_line_no    Line number where the scope of the tag begins in <i>file_name</i>.
 *                         For example, this is the line on which opening brace is
 *                         found in a C function.  For tags where scope is not
 *                         applicable, simply the same value as <i>start_line_no</i>.
 * @param scope_seekpos    Seek position where the scope of the tag begins in <i>file_name</i>.
 *                         See explanation above
 * @param end_line_no      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) Line number where the tag ends in <i>file_name</i>.
 *                         Technically, this is the seek position of the last character
 *                         in the tag.  Using a C function for example, this is the
 *                         seek position of the close brace ending the function body.
 * @param class_name       (optional) Name of class or package or other container that
 *                         the tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about constructing
 *                         this value.  If the tag is not in a class scope, simple pass the empty string for this value.
 * @param tag_flags        (optional) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (optional) Tag signature, includes type, value,
 *                         and arguments for the symbol being inserted.  See
 *                         {@link VS_TAGSEPARATOR_args} and {@link VS_TAGSEPARATOR_equals} for
 *                         more details about constructing this value.
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 *
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_end_context
 * @see tag_find_context
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_context
 * @see tag_set_context_parents 
 * @see tag_set_context_name_location 
 *
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_context_browse_info()} instead
 */
extern int tag_insert_context(int outer_context, _str tag_name, _str type_name,
                              _str file_name, int start_line_no, int start_seekpos,
                              int scope_line_no, int scope_seekpos,
                              int end_line_no, int end_seekpos,
                              _str class_name, int tag_flags, _str signature);

/**
 * Add a tag and its context information to the context list.
 * The context for the current tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_context}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param outer_context    context ID for the outer context (eg. class/struct)
 * @param cm               Instance of {@link VS_TAG_BROWSE_INFO} to insert. 
 *                         This contains all the information about the symbol. 
 *
 * @return sequence number (context_id) of tag context on success, or &lt;0 on error.
 *
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_end_context
 * @see tag_find_context
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_context
 * @see tag_set_context_parents 
 * @see tag_set_context_name_location 
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_context_browse_info(int outer_context, VS_TAG_BROWSE_INFO &cm);

/**
 * Set the end positions of the context with the given context ID.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param context_id       Context ID [ from 1 to {@link tag_get_num_of_context}() ] of
 *                         context tag to set end position of.
 * @param end_line_no      ending line number of tag within file
 * @param end_seekpos      Line number where the tag ends.  Technically, this is the
 *                         seek position of the last character in the tag.  Using a
 *                         C function for example, this is the seek position of the
 *                         close brace ending the function body.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_end_context(int context_id,int end_line_no, int end_seekpos);

/**
 * Set the name and line number positions for the symbol name 
 * of the context with the given context ID.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param context_id       Context ID [ from 1 to {@link tag_get_num_of_context}() ]
 * @param name_line_no     line number that symbol name is located on
 * @param name_seekpos     Seek position of the first character of the symbol name 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_context 
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_end_context 
 * @see tag_get_detail2 
 *
 * @categories Tagging_Functions
 */
extern int tag_set_context_name_location(int context_id,int name_line_no, int name_seekpos);

/**
 * Set the class inheritance for the given context tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] of
 *                   context tag representing class or struct to set inheritance relationships for.
 * @param parents    Delimited list of immediate class ancestors.  It is
 *                   important to remember that for some languages, all classes
 *                   have a default ancestor, such as <i>java.lang/Object</i> in Java.
 *                   Otherwise, use the empty string to indicate that class_name
 *                   is a base class.  See {@link VS_TAGSEPARATOR_parents} for
 *                   more details on constructing this string.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_get_context
 * @see tag_get_detail2
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_context_parents(int context_id, _str parents);

/**
 * Set the template signature for the given context tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 * 
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] of
 *                   context tag representing class or struct to set inheritance relationships for.
 * @param template_signature
 *                   Template signature for the tag, in language
 *                   specific format, normally delimited by commas.
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @see tag_get_context
 * @see tag_get_detail2
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_context_template_signature(int context_id, _str template_args);

/**
 * Clears all context information.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_context(true) prior to invoking this function. 
 *
 * @param file_name        Name of file to initialize context for 
 * @param preserveTokens   Preserve the token list for this file
 *
 * @return 0 on success, &lt;0 or error.
 *
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_clear_context(_str file_name=null, bool preseveTokenList=false);

/**
 * Return the total number of context tags.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 *
 * @return The total number of context tags.
 *
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_get_num_of_statements
 *
 * @categories Tagging_Functions
 */
extern int tag_get_num_of_context();

/**
 * Return the total number of context tags including statements.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 *
 * @return The total number of context tags including statements.
 *
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 * @see tag_get_num_of_context 
 *
 * @categories Tagging_Functions
 */
extern int tag_get_num_of_statements();

/**
 * Retrieve information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                   of context tag to retrieve information about.
 * @param tag_name   (Output) tag string (native case)
 * @param type_name  (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name  (Output) Full path of file the tag is located in
 * @param start_line_no
 *                   (Output) Start line number of tag within file
 * @param start_seekpos
 *                   (Output) Start seek position of tag within file
 * @param scope_line_no
 *                   (Output) Line number where the scope of the tag begins
 *                   in <i>file_name</i>.  For example, this is the line on which
 *                   opening brace is found in a C function.  For tags
 *                   where scope is not applicable, simply the same value
 *                   as <i>start_line_no</i>.
 * @param scope_seekpos
 *                   (Output) Start seek position of tag inner scope
 * @param end_line_no
 *                   (Output) ending line number of tag within file
 * @param end_seekpos
 *                   (Output) Line number where the tag ends in
 *                   <i>file_name</i>.  Technically, this is the seek
 *                   position of the last character in the tag.  Using a
 *                   C function for example, this is the seek position of
 *                   the close brace ending the function body
 * @param class_name (Output) Name of class or package or other container
 *                   that the tag belongs to.  See <i>VS_TAGSEPARATOR_class</i> and
 *                   <i>VS_TAGSEPARATOR_package</i> for more details about
 *                   constructing this value.  If the tag is not in a class
 *                   scope, simple pass the empty string for this value.
 * @param tag_flags  (Output)Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param arguments  (Output) arguments or formal parameters
 * @param return_type
 *                   (Output) Return type and/or value of symbol or constant.
 *                   See <i>VS_TAGSEPARATOR_equals</i> for more details.
 *
 * @return  0 on success, or &lt;0 on error.
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_find_context
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_next_context 
 * @see tag_get_context_simple 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use {@link tag_get_context_browse_info()} instead. 
 */
extern int tag_get_context(int context_id, _str &tag_name, 
                           _str &type_name, _str &file_name,
                           int &start_line_no, long &start_seekpos,
                           int &scope_line_no, long &scope_seekpos,
                           int &end_line_no, long &end_seekpos,
                           _str &class_name, SETagFlags &tag_flags,
                           _str &arguments, _str &return_type);

/**
 * Retrieve minimal information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a 
 * tag_lock_context(false) prior to invoking this function. 
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                   of context tag to retrieve information about.
 * @param tag_name   (Output) tag string (native case)
 * @param type_name  (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name  (Output) Full path of file the tag is located in
 * @param start_line_no
 *                   (Output) Start line number of tag within file
 * @param class_name (Output) Name of class or package or other container
 *                   that the tag belongs to.  See <i>VS_TAGSEPARATOR_class</i> and
 *                   <i>VS_TAGSEPARATOR_package</i> for more details about
 *                   constructing this value.  If the tag is not in a class
 *                   scope, simple pass the empty string for this value.
 * @param tag_flags  (Output)Tag flags indicating symbol attributes, see
 *                   {@link tag_insert_simple} for details.
 * @param arguments  (Output) arguments or formal parameters
 * @param return_type
 *                   (Output) Return type and/or value of symbol or constant.
 *                   See <i>VS_TAGSEPARATOR_equals</i> for more details.
 *
 * @return  0 on success, or &lt;0 on error.
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_find_context
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_next_context 
 * @see tag_get_context 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use {@link tag_get_context_browse_info()} instead. 
 */
extern int tag_get_context_simple(int context_id, _str &tag_name, _str &type_name, 
                                  _str &file_name, int &line_no,
                                  _str &class_name, SETagFlags &tag_flags,
                                  _str &arguments, _str &return_type);

/**
 * Retrieve information about the given context ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id Context ID [ from 1 to {@link tag_get_num_of_context}() ] 
 *                   of context tag to retrieve information about.
 * @param cm         (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 *  
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_find_context
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_next_context 
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_context_browse_info(int context_id, VS_TAG_BROWSE_INFO &cm);

/**
 * Retrieve information about the given statement ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param statement_id  Statement ID [ from 1 to {@link 
 *                      tag_get_num_of_statements}() ] of
 *                      statement context tag to retrieve
 *                      information about.
 * @param cm            (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in. 
 *
 * @return  0 on success, or &lt;0 on error. 
 *  
 * @see tag_clear_context
 * @see tag_current_context
 * @see tag_find_context
 * @see tag_get_detail2
 * @see tag_get_num_of_context
 * @see tag_next_context 
 * @see tag_get_context 
 * @see tag_get_context_simple 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_statement_browse_info(int context_id, VS_TAG_BROWSE_INFO &cm);

/**
 * Check if the current buffer position is still within the current context
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return One of the following codes:
 * <dl compact>
 *    <dt> 0<dd>The context is not set or totally wrong (maybe changed buffers)
 *    <dt>-1<dd>The context info loaded, but the cursor is out of "current" context
 *    <dt> 1<dd>The context is within the tag definition
 *    <dt> 2<dd>The context is within the scope of the tag/function
 * </dl>
 *
 * @see tag_current_context
 * @see tag_get_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_check_context();

/**
 * Check if the list of symbols for the current file are
 * already up-to-date.  Switch to one of the cached file lists
 * if necessary.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param list_tags_flags (optional) statement level tagging option 
 * @return 1 if the context is up-to-date, 0 otherwise.
 *
 * @see tag_current_context
 * @see tag_get_context
 * @see tag_check_cached_locals
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_check_cached_context(int list_tags_flags/*=VS_UPDATEFLAG_context*/);

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
 *
 * @categories Tagging_Functions
 */
extern int tag_update_context_incrementally(long &start_offset,
                                            long &end_offset);

/**
 * Check if the list of symbols for the current file and position
 * are already up-to-date.  Switch to one of the cached local
 * variable lists if necessary.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locals in
 * @param list_all_option  list all locals, or only in scope?
 * 
 * @return 1 if the locals are up-to-date, 0 otherwise.
 *
 * @see tag_check_cached_context
 * @see tag_get_local
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_check_cached_locals(int start_seekpos, int end_seekpos, 
                                   int context_id, int list_all_option);

/**
 * Sort the items in the current context by seek position.
 * The precise sort order is first by non-descrasing starting
 * seekpos, and for items with identical start seek positions,
 * non-increasing end seek position, and for items with identical
 * span, the original insertion order for the items.
 *
 * <p>In addition to sorting the items in the current context, this
 * function computes the outer contexts for each item in the
 * current context.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_insert_context
 * @see tag_insert_context_browse_info 
 * @see tag_insert_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_sort_context();

/**
 * Return the index of the current context item whose name and 
 * name location matches the symbol under the cursor. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current context.
 *  
 * @see tag_current_context 
 * @see tag_set_context_name_location 
 *  
 * @categories Tagging_Functions
 */
extern int tag_current_context_name();

/**
 * Return the index of the current context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *  
 * @param allow_outline_only    Allow tags that are only intended to be 
 *                              displayed in the Defs tool window and
 *                              current context. 
 *  
 * @return Returns the index of the current context tag, calculated using the current
 *         buffer seek position.  Returns &lt;0 on error or 0 if no current context.
 *
 * @see tag_check_cached_context
 * @see tag_get_context
 * @see tag_nearest_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_current_context(bool allow_outline_only=false);

/**
 * Return the index of the current context item,
 * including statements and preprocessing.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 * 
 * @return Returns the index of the current context tag, calculated
 *         using the current buffer seek position. Returns &lt;0 on error
 *         or 0 if no current context.
 * 
 * @see tag_check_cached_context
 * @see tag_get_context
 * @see tag_nearest_context
 * @see tag_current_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_current_statement();

/**
 * Return the index of the nearest context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param linenum line number to check context on
 * @param filter_flags
 *                Tag filter flags.
 *                See {@link tag_filter_type} for more details.
 * @param find_tag_below  find the nearest context item <i>below</i> 
 *                        the current line
 * @param filter_by_types filter out symbols turned off by
 *                        'def_cb_filter_by_types' 
 * 
 * @return Return the index of the context tag starting closest
 *         to the given line number.  This differs from the current
 *         context because the nearest context is not necessarily
 *         the context that you are currently inside.  For example,
 *         if the given <i>linenum</i> falls between two class members,
 *         the current context would be the class, but the nearest
 *         context would be the second class member.
 *         Returns &lt;0 on error or 0 if no current context.
 *
 * @see tag_check_cached_context
 * @see tag_current_context
 * @see tag_get_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_nearest_context(int linenum, 
                               SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING, 
                               bool find_tag_below=false,
                               bool filter_by_types=false);

/**
 * Return the index of the nearest statement context item.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param linenum line number to check context on
 * @param filter_flags
 *                Tag filter flags.
 *                See {@link tag_filter_type} for more details.
 * @param find_tag_below  find the nearest context item <i>below</i> 
 *                        the current line
 * 
 * @return Return the index of the statement context tag starting closest
 *         to the given line number.  This differs from the current
 *         statement because the nearest context is not necessarily
 *         the context that you are currently inside.  For example,
 *         if the given <i>linenum</i> falls between two class members,
 *         the current statement would be the class, but the nearest
 *         statement would be the second class member.
 *         Returns &lt;0 on error or 0 if no current statement.
 *
 * @see tag_check_cached_context
 * @see tag_current_statement
 * @see tag_get_statement_browse_info 
 * @see tag_get_statement_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_nearest_statement(int linenum, 
                                 SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING, 
                                 bool find_tag_below=false);

/**
 * Retrieve information about the given statement ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param statement_id  Statement ID [ from 1 to {@link tag_get_num_of_statements}() ] 
 *                      of statement context tag to retrieve information about.
 * @param cm            (Output) Instance of Slick-C 
 *                      <code>struct VS_TAG_BROWSE_INFO</code>
 *                      to fill in.
 *
 * @return  0 on success, or &lt;0 on error.
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_statement_symbol_info(int statement_id, VS_TAG_BROWSE_INFO &cm);

/**
 * Find the first context entry with the given tag prefix. 
 * Use {@link tag_get_context_browse_info} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_name         Tag name or prefix of tag name
 * @param exact            Search for exact match or prefix match
 * @param case_sensitive   Case sensitive string comparison?
 * @param pass_through_anonymous       Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return Returns context ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_get_class
 * @see tag_next_class
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_find_context_iterator(), which is re-entrant. 
 */
extern int tag_find_context(_str tag_name, 
                            bool exact, bool case_sensitive,
                            bool pass_through_anonymous=false, 
                            _str class_name=null);

/**
 * Find the next context entry with the given tag prefix, or if
 * <i>exact</i>, with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.  Should be called only after
 * first calling {@link tag_find_context}. 
 * Use {@link tag_get_context_browse_info} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_name         tag name or prefix of tag name
 * @param exact            Specifies exact match or prefix match
 * @param case_sensitive   Specifies search case sensitivity.
 * @param pass_through_anonymous    Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_find_context
 * @see tag_get_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_next_context_iterator(), which is re-entrant. 
 */
extern int tag_next_context(_str tag_name, bool exact, bool case_sensitive,
                            bool pass_through_anonymous=false, _str class_name=null);

/**
 * Find the first context entry with the given tag prefix. 
 * Use {@link tag_get_context_browse_info} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         Tag name or prefix of tag name
 * @param exact            Search for exact match or prefix match
 * @param case_sensitive   Case sensitive string comparison?
 * @param pass_through_anonymous       Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return Returns context ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_get_class
 * @see tag_next_class
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_context_iterator(_str tag_name, 
                                     bool exact, bool case_sensitive,
                                     bool pass_through_anonymous=false, 
                                     _str class_name=null);

/**
 * Find the next context entry with the given tag prefix, or if
 * <i>exact</i>, with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.  Should be called only after
 * first calling {@link tag_find_context}. 
 * Use {@link tag_get_context_browse_info} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         tag name or prefix of tag name 
 * @param startIndex       start searching after the given context ID 
 * @param exact            Specifies exact match or prefix match
 * @param case_sensitive   Specifies search case sensitivity.
 * @param pass_through_anonymous    Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return context ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_find_context
 * @see tag_get_context
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern int tag_next_context_iterator(_str tag_name, int startIndex, 
                                     bool exact, bool case_sensitive,
                                     bool pass_through_anonymous=false, 
                                     _str class_name=null);

/**
 * Insert all the context tags passing through the tag filter
 * flags into the given tree.  Use {@link tag_tree_prepare_expand}
 * prior to calling this function in order to configure the
 * browser bitmap set.
 * <p> 
 * For synchronization, perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tree_wid   Window ID of the tree control to insert into.
 * @param treeIndex  Parent tree node index to insert item under.
 * @param filter_flags
 *                   Tag filter flags, only insert tags passing this filter.
 *                   See {@link tag_filter_type} for more details.
 * @param include_tab
 *                   append class name after signature if 1,
 *                   prepend class name with :: if 0.
 *                   See {@link tag_tree_make_caption} for further explanation.
 * @param force_leaf If &lt;0, force leaf node, if equal to 0, choose by tag type.
 *                   Normally "container" tag types, such as classes or structs
 *                   are automatically inserted as non-leaf nodes.  If &gt;0,
 *                   insert the items from the current context as a tree,
 *                   displaying the heirarchy of inner/outer nesting of tags,
 *                   going by the positions calculated by {@link tag_sort_context}().
 * @param tree_flags tree flags to set for this item
 * @param show_statements
 *                   show statements in "Defs" tab
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see _TreeAddItem
 * @see tag_filter_type
 * @see tag_insert_context
 * @see tag_tree_insert_tag
 * @see tag_tree_make_caption
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions 
 */
extern int tag_tree_insert_context(int tree_wid, int treeIndex, 
                                   SETagFilterFlags filter_flags,
                                   int include_tab, int force_leaf, 
                                   int tree_flags, int show_statements );

/**
 * Register a new OEM-defined CB type.
 *
 * @param type_id              Tag type ID, in range SE_TAG_TYPE_OEM &lt;= type_id &lt;= SE_TAG_TYPE_MAXIMUM
 * @param cb_type              Symbol browser type index for picture
 *                             indices, in range CB_type_LAST+1 ...
 * @param pic_member_public    Picture index of bitmap for public scope symbol
 * @param pic_member_protected Picture index of bitmap for protected scope symbol
 * @param pic_member_private   Picture index of bitmap for private scope symbol
 * @param pic_member_package   Picture index of bitmap for package scope symbol
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_tree_register_cb_type(int type_id, int cb_type,
                                     int pic_member_public=0, int pic_member_protected=0,
                                     int pic_member_private=0, int pic_member_package=0);

/**
 * Unregister a OEM-defined CB type.
 *
 * @param type_id Tag type ID, in range SE_TAG_TYPE_OEM &lt;= type_id &lt;= SE_TAG_TYPE_MAXIMUM
 *
 * @categories Tagging_Functions
 */
extern void tag_tree_unregister_cb_type(int type_id);


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
 * @param filter_flags    PUSHTAG_*, see slick.sh
 * @param show_statements  Show statements in proctree
 *
 * @return 0 on success, &lt;0 on error.
 *  
 * @see tag_tree_insert_context 
 * @see tag_tree_filter_outline
 * 
 * @categories Tagging_Functions
 */
extern int tag_tree_insert_context_outline(int treeWID, int treeIndex,
                                           int include_tab, int force_leaf,
                                           int tree_flags, 
                                           SETagFilterFlags filter_flags, 
                                           int show_statements );

extern int tag_tree_insert_default_outline(int treeWID, int treeIndex,
                                           int include_tab, int force_leaf,
                                           int tree_flags, 
                                           SETagFilterFlags filter_flags, 
                                           int show_statements );

/**
 * @return Return 1 if the given context ID should be included in the 
 *         XML outline.  Return 0 otherwise.
 * 
 * @param context_id    ID of item in current context (1..n)
 *  
 * @see tag_filter_type 
 * @see tag_tree_insert_context_outline 
 *  
 * @categories Tagging_Functions
 */
extern int tag_tree_filter_outline(int context_id);

/**
 * Insert all the tags from the current context into the currently
 * open tag file.  Assumes that the context is up-to-date at the
 * time that this function is called.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param file_name typically {@link p_buf_name}, absolute path of buffer
 *
 * @return 0 on success, &lt;0 on error, BT_RECORD_NOT_FOUND_RC if the 
 *         context info is not set or from the wrong file or buffer. 
 *  
 * @see tag_insert_context
 * @see tag_insert_file_end
 * @see tag_insert_file_start
 * @see tag_insert_tag
 *
 * @categories Tagging_Functions
 */
extern int tag_transfer_context(_str file_name);

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
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_type
 * @see tag_get_token_type_name 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_token_info(int token_id, 
                              int &token_type,
                              _str&token_text,
                              int &offset,
                              int &linenum);

/**
 * Get the token type for the given token ID in the current context. 
 * The current context has to be built with the token list for this to work. 
 * 
 * @param token_id      token ID
 * 
 * @return token type (SETokenType) &gt;=0 on success, &lt;0 on error
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type_name
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_token_type(int token_id);

/** 
 * @return 
 * Return the name for the given token type.
 * 
 * @param token_type   token type (SETokenType) 
 *  
 * @see tag_get_current_token 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 *  
 * @categories Tagging_Functions
 */
extern _str tag_get_token_type_name(int token_type);

/**
 * Get the token parsing error status for the given token ID in the current context. 
 * The current context has to be built with the token list for this to work. 
 * 
 * @param token_id      token ID
 * 
 * @return token error status (SETokenErrorStatus) &gt;=0 on success, &lt;0 on error
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type
 * @see tag_get_token_type_name
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_token_status(int token_id);

/**
 * @return 
 * Return the token ID of the token at the given seek position in the current context. 
 * Return's 0 if the given seekpos is whitespace or a comment (not a token). 
 * 
 * @param seekpos    seek position to look for token at 
 *  
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status 
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_current_token(int seekpos);

/**
 * Get the first token in the current context, or in the given 
 * embedded code block. 
 * 
 * @param embedded_token_id   token ID of embedded code block 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_first_token(int embedded_token_id=0);

/**
 * Get the last token in the current context, or in the given 
 * embedded code block. 
 * 
 * @param embedded_token_id   token ID of embedded code block 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_last_token(int embedded_token_id=0);

/**
 * Get the next token after the given token.
 * 
 * @param token_id   token ID 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_next_token(int token_id);

/**
 * Get the previous token before the given token.
 * 
 * @param token_id   token ID 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *  
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_first_pptoken 
 * @see tag_get_last_pptoken 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_prev_token(int token_id);

/**
 * Get the first token in the given preprocessed code block. 
 * 
 * @param pp_token_id   token ID of preprocessed code block 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_first_pptoken(int pp_token_id=0);

/**
 * Get the last token in the given preprocessed code block. 
 * 
 * @param pp_token_id   token ID of preprocessed code block 
 *  
 * @return token ID &gt;0 on success, &lt;0 on error.
 *
 * @see tag_get_current_token 
 * @see tag_get_first_token 
 * @see tag_get_last_token 
 * @see tag_get_next_token 
 * @see tag_get_prev_token 
 * @see tag_get_token_info 
 * @see tag_get_token_type 
 * @see tag_get_token_status
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_last_pptoken(int pp_token_id=0);


///////////////////////////////////////////////////////////////////////////
// Local declarations related tracking functions

/**
 * Add a tag and its context information to the local variables list, which is the list
 * of tags found in the current function or procedure, accounting for scope and the
 * current cursor position.
 * instead.
 * <p>
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_local}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param tag_name         tag string
 * @param type_name         Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param file_name        full path of file the tag is located in ({@link p_buf_name})
 * @param line_no          start line number of tag within file
 * @param class_name       (optional) Name of class or package or other container that
 *                         the tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about
 *                         constructing this value.  If the tag is not in a class
 *                         scope, simple pass the empty string for this value.
 * @param tag_flags        (optional) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (optional) Tag signature, includes type, value, and arguments
 *                         for the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                         {@link VS_TAGSEPARATOR_equals} for more details about constructing this value.
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_num_of_locals
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local2
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_local
 * @see tag_set_local_parents
 * @see tag_end_local
 *
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_local_browse_info()} instead.
 */
extern int tag_insert_local(_str tag_name,_str type_name,_str file_name,int line_no,
                            _str class_name,int tag_flags,_str signature);

/**
 * Add a tag and its context information to the local variables list, which is
 * the list of tags found in the current function or procedure, accounting for
 * scope and the current cursor position.
 * <p>
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_local}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param tag_name         tag string
 * @param type_name        Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param file_name        full path of file the tag is located in ({@link p_buf_name})
 * @param start_linenum    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_linenum    Line number where the scope of the tag begins in <i>file_name</i>.
 *                         For example, this is the line on which opening brace is found in
 *                         a C function.  For tags where scope is not applicable, simply
 *                         the same value as <i>start_linenum</i>.
 * @param scope_seekpos    Seek position where the scope of the tag begins in <i>file_name</i>.
 *                         See explanation above.
 * @param end_linenum      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) Line number where the tag ends in <i>file_name</i>.  Technically,
 *                         this is the seek position of the last character in the tag.  Using
 *                         a C function for example, this is the seek position of the close
 *                         brace ending the function body.
 * @param class_name       (optional) Name of class or package or other container that the tag
 *                         belongs to.  See {@link VS_TAGSEPARATOR_class} and {@link VS_TAGSEPARATOR_package}
 *                         for more details about constructing this value.  If the tag is not
 *                         in a class scope, simple pass the empty string for this value.
 * @param tag_flags        (optional) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (optional) Tag signature, includes type, value, and arguments
 *                         for the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                         {@link VS_TAGSEPARATOR_equals} for more details about constructing
 *                         this value.
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_num_of_locals
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_local
 * @see tag_set_local_parents
 * @see tag_set_local_name_location 
 * @see tag_end_local
 *
 * @categories Tagging_Functions 
 * 
 * @deprecated Use {@link tag_insert_local_browse_info()} instead.
 */
extern int tag_insert_local2(_str tag_name,_str type_name,_str file_name,
                             int line_no,int seekpos,
                             int scope_line_no,int scope_seekpos,
                             int end_line_no,int end_seekpos,
                             _str class_name,int tag_flags,_str signature);

/**
 * Add a tag and its context information to the local variables list, which is
 * the list of tags found in the current function or procedure, accounting for
 * scope and the current cursor position.
 * <p>
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see {@link tag_end_local}().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param cm         Instance of Slick-C <code>struct VS_TAG_BROWSE_INFO</code> to insert. 
 *                   This contains all the information about the symbol. 
 *
 * @return sequence number (local_id) of local variable on success, or &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_num_of_locals
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_next_local
 * @see tag_set_local_parents
 * @see tag_set_local_name_location 
 * @see tag_end_local
 *
 * @categories Tagging_Functions 
 * @since 21.0 
 */
extern int tag_insert_local_browse_info(VS_TAG_BROWSE_INFO &cm);

/**
 * Set the end positions of the local with the given local ID.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param local_id         Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of
 *                         local tag to set end position of.
 * @param end_line_no      ending line number of tag within file
 * @param end_seekpos      seek position where the tag ends.  Technically, this is the
 *                         seek position of the last character in the tag.  Using a
 *                         C local variable, "int a;" for example, this is the seek
 *                         position of the of the semicolon.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_local
 * @see tag_insert_local2
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_end_local(int context_id, int end_line_no, int end_seekpos);

/**
 * Sort the local variables in the current context by seek position.
 * The precise sort order is first by non-descrasing starting
 * seekpos, and for items with identical start seek positions,
 * non-increasing end seek position, and for items with identical
 * span, the original insertion order for the items.
 *
 * <p>In addition to sorting the local variables, this function computes
 * the outer contexts.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_insert_local2
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_sort_locals();

/**
 * Return the index of the current local variable.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return Returns the index of the current local variable tag, calculated 
 * using the current buffer seek position. 
 * Returns &lt;0 on error or 0 if no current local variable.
 *
 * @see tag_get_local2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_local2
 *
 * @categories Tagging_Functions
 */
extern int tag_current_local();

/**
 * Return the index of the current local item whose name and 
 * name location matches the symbol under the cursor. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return &lt;0 on error, 0 if no current local.
 *  
 * @see tag_current_local 
 * @see tag_set_local_name_location 
 *  
 * @categories Tagging_Functions
 */
extern int tag_current_local_name();

/**
 * Set the class inheritance for the given local tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param local_id Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                 variable tag representing class or struct to set
 *                 inheritance relationships for.
 * @param parents  Delimited list of immediate class ancestors.  It is
 *                 important to remember that for some languages, all classes
 *                 have a default ancestor, such as java.lang/Object in Java.
 *                 Otherwise, use the empty string to indicate that class_name
 *                 is a base class.  See {@link VS_TAGSEPARATOR_parents} for more details
 *                 on constructing this string.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_get_local2
 * @see tag_get_detail2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_local
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_local_parents(int local_id, _str parents);

/**
 * Set the name and line number positions for the local symbol name 
 * with the given local ID.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param local_id       Local ID [ from 1 to {@link tag_get_num_of_locals}() ]
 * @param name_line_no   line number that symbol name is located on
 * @param name_seekpos   Seek position of the first character of the symbol name 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_local 
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 * @see tag_end_local 
 * @see tag_get_detail2 
 *
 * @categories Tagging_Functions
 */
extern int tag_set_local_name_location(int local_id, int name_line_no, int name_seekpos);

/**
 * Set the template signature for the given local tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 * 
 * @param local_id Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                 variable tag representing class or struct to set
 *                 inheritance relationships for.
 * @param template_signature
 *                 Template signature for this local tag, in language
 *                 specific format, normally delimited by commas.
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @see tag_get_local2
 * @see tag_get_detail2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_insert_local
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_local_template_signature(int local_id, _str template_args);

/**
 * Return the total number of local variables
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @return the number of local variables
 *
 * @see tag_insert_local
 * @see tag_insert_local2
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_get_num_of_locals();

/**
 * Is the given local variable in scope at the current seek position?
 * 
 * @param local_id   Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local symbol
 * @param seekpos    seek position within current file/function
 * 
 * @return 'true' if the variable is in scope, false otherwise
 *
 * @categories Tagging_Functions 
 * @since 21.0
 */
extern int tag_is_local_in_scope(int local_id, int seekpos);

/**
 * Kill all locals after 'local_id', not including 'local_id'
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
 * prior to invoking this function.
 *
 * @param local_id         id for the local variable to start removing at
 *                         Use '0' to remove all locals.
 *                         Use -1 to remove all locals and reset the date tagged. 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_get_num_of_locals
 * @see tag_insert_local
 * @see tag_insert_local2
 * @see tag_insert_local_browse_info
 * @see tag_insert_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_clear_locals(int local_id);

/**
 * Retrieve information about the given local variable tag.  Though this function
 * is highly optimized, it is often more efficient to use {@link tag_get_detail2} to
 * retrieve only specific information about a local variable rather than everything.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id         Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                         variable to retrieve information about.
 * @param tag_name         (Output) tag string (native case)
 * @param type_name        (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name        (Output) full path of file the tag is located in
 * @param line_no          (Output) start line number of tag within file
 * @param class_name       (Output) Name of class or package or other container that the
 *                         tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about constructing
 *                         this value.  If the tag is not in a class scope, simple pass
 *                         the empty string for this value.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param arguments        (Output) arguments or formal parameters
 * @param return_type      (Output) constant value or return type
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_detail2
 * @see tag_get_local2
 * @see tag_get_num_of_locals
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_next_local
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use {@link tag_get_local_browse_info()} instead. 
 */
extern int tag_get_local(int local_id,_str &tag_name,_str &type_name,_str &file_name,
                         int &line_no,_str & class_name,SETagFlags &tag_flags,
                         _str &arguments,_str &return_type);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id         Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                         symbol to retrieve information about.
 * @param tag_name         (Output) tag string (native case)
 * @param type_name        (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name        (Output) full path of file the tag is located in
 * @param start_linenum    (Output) start line number of tag within file
 * @param start_seekpos    (Output) start seek position of tag within file
 * @param scope_linenum    (Output) Line number where the scope of the tag begins in
 *                         <i>file_name</i>.  For example, this is the line on which
 *                         opening brace is found in a C function.  For tags where scope
 *                         is not applicable, simply the same value as <i>start_linenum</i>.
 * @param scope_seekpos    (Output) Seek position where the scope of the tag begins in
 *                         <i>file_name</i>.  See explanation above.
 * @param end_linenum      (Output) ending line number of tag within file
 * @param end_seekpos      (Output) Line number where the tag ends in file_name.  Technically,
 *                         this is the seek position of the last character in the tag.
 *                         Using a C function for example, this is the seek position of
 *                         the close brace ending the function body.
 * @param class_name       (Output) Name of class or package or other container that
 *                         the tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about constructing
 *                         this value.  If the tag is not in a class scope, pass the
 *                         empty string for this value.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (Output) arguments or formal parameters
 * @param return_type      (Output) Return type and/or value of symbol or
 *                         constant.  See {@link VS_TAGSEPARATOR_equals} for more details.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_get_num_of_locals
 * @see tag_next_local
 *
 * @categories Tagging_Functions
 *  
 * @deprecated Use {@link tag_get_local_browse_info()} instead. 
 */
extern int tag_get_local2(int local_id, _str &tag_name, _str &type_name,
                          _str &file_name, int &start_line_no, int &start_seekpos,
                          int &scope_line_no, int &scope_seekpos,
                          int &end_line_no, int &end_seekpos,
                          _str &class_name, SETagFlags &tag_flags, _str &signature, _str &return_type);

/**
 * Retrieve complete information about the given local ID.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param local_id      Local ID [ from 1 to {@link tag_get_num_of_locals}() ] of local
 *                      symbol to retrieve information about.
 * @param cm            (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_clear_locals
 * @see tag_current_local
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_detail2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_get_num_of_locals
 * @see tag_next_local
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_local_browse_info(int local_id, VS_TAG_BROWSE_INFO &cm);

/**
 * Find the first local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * Use {@link tag_get_local2} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param pass_through_anonymous   Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return Local ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_get_local
 * @see tag_get_local2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 * @see tag_next_local
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_find_local_iterator() because it is reentrant. 
 */
extern int tag_find_local(_str tag_prefix, bool exact, bool case_sensitive,
                          bool pass_through_anonymous=false, _str class_name=null);

/**
 * Find a the next local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0. Should be called only after calling
 * {@link tag_find_local}.  Use {@link tag_get_local2}
 * to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.  This is considered as a write operation 
 * because it uses an iterator to traverse the items in the context. 
 *
 * @param tag_prefix             Tag name or prefix of tag name
 * @param exact                  Specifies exact match or prefix match
 * @param case_sensitive         Specifies search case sensitivity. 
 * @param pass_through_anonymous Pass through anonymous classes? 
 * @param class_name             Name of class that tag belongs to. 
 *
 * @return Local ID of tag if found, &lt;0 on error or not found. 
 *  
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_local2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_next_local_iterator() because it is reentrant. 
 */
extern int tag_next_local(_str tag_prefix, bool exact, bool case_sensitive,
                          bool pass_through_anonymous=false, _str class_name=null);

/**
 * Find the first local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0.
 * Use {@link tag_get_local2} to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       tag name or prefix of tag name
 * @param exact            search for exact match or prefix match
 * @param case_sensitive   case sensitive string comparison?
 * @param pass_through_anonymous   Pass through anonymous classes
 * @param class_name       Class to find item in
 *
 * @return Local ID of tag if found, &lt;0 on error or not found.
 *
 * @see tag_get_local
 * @see tag_get_local2
 * @see tag_next_local
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_find_local_iterator(_str tag_prefix, 
                                   bool exact, bool case_sensitive,
                                   bool pass_through_anonymous=false, 
                                   _str class_name=null);

/**
 * Find a the next local tag with the given tag prefix, or if
 * 'exact', with the exact tag name.  Use case-sensitive match if
 * case_sensitive != 0. Should be called only after calling
 * {@link tag_find_local}.  Use {@link tag_get_local2}
 * to extract details about the tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_prefix       Tag name or prefix of tag name 
 * @param startIndex       start searching after the given context ID 
 * @param exact            Specifies exact match or prefix match
 * @param case_sensitive   Specifies search case sensitivity. 
 * @param pass_through_anonymous
 *                   Pass through anonymous classes?
 * @param lass_name        Name of class that tag belongs to. 
 *
 * @return Local ID of tag if found, &lt;0 on error or not found. 
 *  
 * @see tag_find_local
 * @see tag_get_local
 * @see tag_get_local2
 * @see tag_get_local_browse_info
 * @see tag_get_local_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_next_local_iterator(_str tag_prefix, int startIndex,
                                   bool exact, bool case_sensitive,
                                   bool pass_through_anonymous=false, 
                                   _str class_name=null);

///////////////////////////////////////////////////////////////////////////
// Search match tracking related functions

/**
 * Add a search match tag and its information to the matches list.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param tag_file         (optional) full path of tag file match came from
 * @param tag_name         tag string
 * @param type_name        Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param file_name        full path of file the tag is located in
 * @param line_no          start line number of tag within file
 * @param class_name       (optional) name of class that tag is present in,
 *                         use concatenation (as defined by language rules)
 *                         to specify names of inner classes.
 * @param tag_flags        (Optional) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (optional) tag signature (return type, arguments, etc)
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 * 
 * @see tag_insert_match2
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * 
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_match_browse_info()} instead.
 */
extern int tag_insert_match(_str tag_file, _str tag_name, _str type_name,
                            _str file_name, int line_no, _str class_name,
                            int tag_flags, _str signature);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of tags
 * very efficiently through the match set.  This is useful when searching for specific
 * tags.  Many of the Context Tagging&reg; functions are designed to insert directly into
 * the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param tag_file         (optional) full path of tag file match came from
 * @param tag_name         tag string
 * @param type_name        Tag type name.  See {@link tag_get_type} for a list of all standard tag types.
 * @param file_name        full path of file the tag is located in ({@link p_buf_name})
 * @param start_linenum    start line number of tag within file
 * @param start_seekpos    start seek position of tag within file
 * @param scope_linenum    Line number where the scope of the tag begins in <i>file_name</i>.
 *                         For example, this is the line on which opening brace is found in a
 *                         C function.  For tags where scope is not applicable, simply the
 *                         same value as <i>start_linenum</i>.
 * @param scope_seekpos    Seek position where the scope of the tag begins in <i>file_name</i>.
 *                         See explanation above.
 * @param end_linenum      (optional) ending line number of tag within file
 * @param end_seekpos      (optional) Line number where the tag ends in <i>file_name</i>.
 *                         Technically, this is the seek position of the last character in
 *                         the tag.  Using a C function for example, this is the seek
 *                         position of the close brace ending the function body.
 * @param class_name       (optional) Name of class or package or other container that
 *                         the tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about
 *                         constructing this value.  If the tag is not in a class
 *                         scope, simple pass the empty string for this value.
 * @param tag_flags        (optional) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param signature        (optional) Tag signature, includes type, value, and arguments
 *                         for the symbol being inserted.  See {@link VS_TAGSEPARATOR_args} and
 *                         {@link VS_TAGSEPARATOR_equals} for more details about constructing this value.
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 *
 * @see tag_clear_matches
 * @see tag_get_match
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local2
 * @see tag_insert_match
 * @see tag_insert_match_browse_info
 * @see tag_insert_match_symbol_info
 * @see tag_insert_tag
 * @see tag_list_any_symbols
 * @see tag_list_class_context
 * @see tag_list_class_locals
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_list_context_packages
 * @see tag_list_globals_of_type
 * @see tag_list_in_file
 *
 * @categories Tagging_Functions
 * 
 * @deprecated Use {@link tag_insert_match_browse_info()} instead.
 */
extern int tag_insert_match2(_str tag_file, _str tag_name,_str type_name,
                             _str file_name,int line_no,int seekpos,
                             int scope_line_no,int scope_seekpos,
                             int end_line_no,int end_seekpos,
                             _str class_name,int tag_flags,_str signature);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of tags
 * very efficiently through the match set.  This is useful when searching for specific
 * tags.  Many of the Context Tagging&reg; functions are designed to insert directly into
 * the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param cm                  Instance of {@link VS_TAG_BROWSE_INFO} to insert. 
 *                            This contains all the information about the symbol.
 * @param checkForDuplicates  Before inserting, verify that the symbol is not 
 *                            already in the match set, return match_id if so. 
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 *
 * @see tag_clear_matches
 * @see tag_get_match
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local2
 * @see tag_insert_match
 * @see tag_insert_tag
 * @see tag_list_any_symbols
 * @see tag_list_class_context
 * @see tag_list_class_locals
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_list_context_packages
 * @see tag_list_globals_of_type
 * @see tag_list_in_file
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_insert_match_browse_info(VS_TAG_BROWSE_INFO &cm, bool checkForDuplicates=true);

/**
 * Add a tag to the match set.  The tag database allows you to maintain a list of
 * tags very efficiently through the match set.  This is useful when searching
 * for specific tags.  Many of the Context Tagging&reg; functions are designed to
 * insert directly into the match set and use this function to do so for efficiency.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) and 
 * tag_lock_context(false) prior to invoking this function. 
 *
 * @param match_type Specifies where the tag to insert comes from:
 *                   <dl compact>
 *                   <dt>VS_TAGMATCH_tag<dd style="margin-left:120pt">		current tag from database
 *                   <dt>VS_TAGMATCH_context<dd style="margin-left:120pt">	item in current context (buffer)
 *                   <dt>VS_TAGMATCH_local<dd style="margin-left:120pt">  		item in local variable set (function)
 *                   <dt>VS_TAGMATCH_match<dd style="margin-left:120pt">  	item in match set
 *                   </dl>
 * @param local_or_context_id
 *                   0 if inserting current tag from database, otherwise, specifies the
 *                   unique integer ID of the item from the context, locals, or match
 *                   set, as specified by match_type.
 *
 * @return sequence number (match_id) of matching tag on success, or &lt;0 on error.
 *
 * @see tag_clear_matches
 * @see tag_get_match
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_context
 * @see tag_insert_local2
 * @see tag_insert_match
 * @see tag_insert_match_browse_info
 * @see tag_insert_match_symbol_info
 * @see tag_insert_tag
 * @see tag_list_any_symbols
 * @see tag_list_class_context
 * @see tag_list_class_locals
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_list_context_packages
 * @see tag_list_globals_of_type
 * @see tag_list_in_file
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_match_fast(int match_type, int local_or_context_id);

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
 *  
 * @see tag_get_match
 * @see tag_get_detail2
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_match_parents(int context_id, _str parents);

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
 * 
 * @see tag_get_match
 * @see tag_get_detail2
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_set_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_set_match_template_signature(int local_id, _str template_args);

/**
 * Return the total number of search matches
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(false) prior to invoking this function. 
 *
 * @return the total number of matches
 *
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_get_num_of_matches();

/**
 * Clears all tags out of the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_clear_matches();

/**
 * Remove one match from the match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @param match_id      ID of match to remove from match set
 *
 * @return 0 on success, &lt;0 on error.
 *  
 * @see tag_get_num_of_matches 
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 *
 * @categories Tagging_Functions
 */
extern int tag_remove_match(int i);

/**
 * Push the current match set onto the stack of match sets and
 * initialize the new stack top to an empty match set
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_get_match
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_pop_context
 * @see tag_pop_matches
 * @see tag_push_context
 *
 * @categories Tagging_Functions
 */
extern int tag_push_matches();

/**
 * Clear the current match set and pop it off of the stack.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 *
 * @see tag_get_match
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_pop_context
 * @see tag_push_context
 * @see tag_push_matches
 *
 * @categories Tagging_Functions
 */
extern void tag_pop_matches();

/**
 * Transfer the contents of the current match set to the
 * previous match set, and pop it off of the stack.
 * This is similar to tag_pop_matches(), except that
 * the contents of the match set are not thrown away.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * prior to invoking this function.
 * 
 * @see tag_get_match
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_pop_matches
 * @see tag_pop_context
 * @see tag_push_context
 * @see tag_push_matches
 *
 * @categories Tagging_Functions
 */
extern void tag_join_matches();

/**
 * Push the current match set onto the stack of match sets and
 * transfer the context set to the top of the match set stack.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(true) and tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_get_match
 * @see tag_get_match_browse_info
 * @see tag_get_match_symbol_info
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_pop_context
 * @see tag_pop_matches
 * @see tag_push_matches
 *
 * @categories Tagging_Functions
 */
extern int tag_push_context();

/**
 * Transfers the current match set to the context set and
 * pop it off of the match set stack.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(true) and tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_pop_matches
 * @see tag_push_matches
 *
 * @categories Tagging_Functions
 */
extern void tag_pop_context();

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
 * @param tag_file         (Output) tag file that match came from
 * @param tag_name         (Output) Tag string (native case)
 * @param type_name        (Output) Tag type name, see {@link tag_get_type}.
 * @param file_name        (Output) Full path of file the tag is located in
 * @param line_no          (Output) Start line number of tag within file
 * @param class_name       (Output) Name of class or package or other container that
 *                         the tag belongs to.  See {@link VS_TAGSEPARATOR_class} and
 *                         {@link VS_TAGSEPARATOR_package} for more details about constructing
 *                         this value.  If the tag is not in a class scope, simple pass
 *                         the empty string for this value.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param arguments        (Output) arguments or formal parameters
 * @param return_type      (Output) constant value or return type
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @see tag_clear_matches
 * @see tag_insert_match
 * @see tag_insert_match_fast
 * @see tag_insert_match_browse_info 
 * @see tag_insert_match_symbol_info
 * @see tag_get_detail2
 * @see tag_get_num_of_matches
 * @see tag_get_match_browse_info 
 * @see tag_get_match_symbol_info 
 * @see tag_pop_matches
 * @see tag_push_matches
 *
 * @categories Tagging_Functions 
 *  
 * @deprecated Use tag_get_match_browse_info() or tag_get_match_symbol_info() instead. 
 */
extern int tag_get_match(int match_id, _str &tag_file, _str &tag_name, _str &type_name,
                         _str &file_name, int &line_no, _str &class_name, SETagFlags &tag_flags,
                         _str &arguments, _str &return_type);

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
 * @param cm               (Output) Instance of {@link VS_TAG_BROWSE_INFO} to fill in.
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
 *
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_match_browse_info(int match_id, VS_TAG_BROWSE_INFO &cm);

/**
 * Get the given detail type for the given item either as a
 * context tag, local tag, or part of a match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(false) 
 * or tag_lock_context(false) prior to invoking this function. 
 *
 * @param tag_detail ID of detail to extract. One of the following:
 *                   <dl compact>
 *                   <dt>VS_TAGDETAIL_context_tag_file<dd style="margin-left:240pt">(string) tag file match is from.
 *                   <dt>VS_TAGDETAIL_context_name<dd style="margin-left:240pt">    (string) tag name.
 *                   <dt>VS_TAGDETAIL_context_type<dd style="margin-left:240pt">    (string) tag type name.
 *                   <dt>VS_TAGDETAIL_context_file<dd style="margin-left:240pt">    (string) file that the tag is in.
 *                   <dt>VS_TAGDETAIL_context_line<dd style="margin-left:240pt">    (int) start line number of tag.
 *                   <dt>VS_TAGDETAIL_context_start_linenum<dd style="margin-left:240pt"> (int) same as *_line, above.
 *                   <dt>VS_TAGDETAIL_context_start_seekpos<dd style="margin-left:240pt"> (int) seek position tag starts at
 *                   <dt>VS_TAGDETAIL_context_name_linenum<dd style="margin-left:240pt"> (int) line number symbol name is on
 *                   <dt>VS_TAGDETAIL_context_name_seekpos<dd style="margin-left:240pt"> (int) seek position of symbol name
 *                   <dt>VS_TAGDETAIL_context_scope_linenum<dd style="margin-left:240pt"> (int) line number body starts at.
 *                   <dt>VS_TAGDETAIL_context_scope_seekpos<dd style="margin-left:240pt"> (int) seek position body starts at.
 *                   <dt>VS_TAGDETAIL_context_end_linenum<dd style="margin-left:240pt">(int) line number tag ends on.
 *                   <dt>VS_TAGDETAIL_context_end_seekpos<dd style="margin-left:240pt">(int) seek position tag ends at.
 *                   <dt>VS_TAGDETAIL_context_class<dd style="margin-left:240pt">      (string) name of class.
 *                   <dt>VS_TAGDETAIL_context_flags<dd style="margin-left:240pt">         (int) tag attribute flags.
 *                   <dt>VS_TAGDETAIL_context_args<dd style="margin-left:240pt">          (string) tag arguments.
 *                   <dt>VS_TAGDETAIL_context_return<dd style="margin-left:240pt">     (string) value or type of symbol.
 *                   <dt>VS_TAGDETAIL_context_outer<dd style="margin-left:240pt">         (int) ID of first enclosing tag.
 *                   <dt>VS_TAGDETAIL_context_parents<dd style="margin-left:240pt">       (string) class derivation.
 *                   <dt>VS_TAGDETAIL_context_throws<dd style="margin-left:240pt">        (string) function/proc exceptions.
 *                   <dt>VS_TAGDETAIL_context_included_by<dd style="margin-left:240pt">(string) file including this macro.
 *                   <dt>VS_TAGDETAIL_context_return_only<dd style="margin-left:240pt">(string) just the type of variable.
 *                   <dt>VS_TAGDETAIL_context_return_value<dd style="margin-left:240pt">(string) default value of variable.
 *                   <dt>VS_TAGDETAIL_context_language_id<dd style="margin-left:240pt">(string) language mode for symbol.
 *                   <dt>VS_TAGDETAIL_local_tag_file<dd style="margin-left:240pt">     	(string) tag file match is from.
 *                   <dt>VS_TAGDETAIL_local_name<dd style="margin-left:240pt">         	(string) tag name.
 *                   <dt>VS_TAGDETAIL_local_type<dd style="margin-left:240pt">	(string) tag type name.
 *                   <dt>VS_TAGDETAIL_local_file<dd style="margin-left:240pt">         		(string) file that the tag is in.
 *                   <dt>VS_TAGDETAIL_local_line<dd style="margin-left:240pt">        		(int) start line number of tag.
 *                   <dt>VS_TAGDETAIL_local_start_linenum<dd style="margin-left:240pt">(int) same as *_line, above.
 *                   <dt>VS_TAGDETAIL_local_start_seekpos<dd style="margin-left:240pt">(int) seek position tag starts at
 *                   <dt>VS_TAGDETAIL_local_name_linenum<dd style="margin-left:240pt"> (int) line number symbol name is on
 *                   <dt>VS_TAGDETAIL_local_name_seekpos<dd style="margin-left:240pt"> (int) seek position of symbol name
 *                   <dt>VS_TAGDETAIL_local_scope_linenum<dd style="margin-left:240pt">(int) line number body starts at.
 *                   <dt>VS_TAGDETAIL_local_scope_seekpos<dd style="margin-left:240pt">(int) seek position body starts at.
 *                   <dt>VS_TAGDETAIL_local_end_linenum<dd style="margin-left:240pt">(int) line number tag ends on.
 *                   <dt>VS_TAGDETAIL_local_end_seekpos<dd style="margin-left:240pt">(int) seek position tag ends at.
 *                   <dt>VS_TAGDETAIL_local_class<dd style="margin-left:240pt">    		(string) name of class.
 *                   <dt>VS_TAGDETAIL_local_flags<dd style="margin-left:240pt">       		(int) tag attribute flags.
 *                   <dt>VS_TAGDETAIL_local_args<dd style="margin-left:240pt">         	(string) tag arguments.
 *                   <dt>VS_TAGDETAIL_local_return<dd style="margin-left:240pt">  		(string) value or type of symbol.
 *                   <dt>VS_TAGDETAIL_local_outer<dd style="margin-left:240pt">        	(int) ID of first enclosing tag.
 *                   <dt>VS_TAGDETAIL_local_parents<dd style="margin-left:240pt">     	(string) class derivation.
 *                   <dt>VS_TAGDETAIL_local_throws<dd style="margin-left:240pt">     	(string) function/proc exceptions.
 *                   <dt>VS_TAGDETAIL_local_included_by<dd style="margin-left:240pt">(string) file including this macro.
 *                   <dt>VS_TAGDETAIL_local_return_only<dd style="margin-left:240pt">(string) just the type of variable.
 *                   <dt>VS_TAGDETAIL_local_return_value<dd style="margin-left:240pt">(string) default value of variable.
 *                   <dt>VS_TAGDETAIL_local_language_id<dd style="margin-left:240pt">(string) language mode for symbol.
 *                   <dt>VS_TAGDETAIL_match_tag_file<dd style="margin-left:240pt">     	(string) tag file match is from.
 *                   <dt>VS_TAGDETAIL_match_name<dd style="margin-left:240pt">         	(string) tag name.
 *                   <dt>VS_TAGDETAIL_match_type<dd style="margin-left:240pt">	(string) tag type name.
 *                   <dt>VS_TAGDETAIL_match_file<dd style="margin-left:240pt">         	(string) file that the tag is in.
 *                   <dt>VS_TAGDETAIL_match_line<dd style="margin-left:240pt">        	(int) start line number of tag.
 *                   <dt>VS_TAGDETAIL_match_start_linenum<dd style="margin-left:240pt">(int) same as *_line, above.
 *                   <dt>VS_TAGDETAIL_match_start_seekpos<dd style="margin-left:240pt">(int) seek position tag starts at
 *                   <dt>VS_TAGDETAIL_match_name_linenum<dd style="margin-left:240pt"> (int) line number symbol name is on
 *                   <dt>VS_TAGDETAIL_match_name_seekpos<dd style="margin-left:240pt"> (int) seek position of symbol name
 *                   <dt>VS_TAGDETAIL_match_scope_linenum<dd style="margin-left:240pt">(int) line number body starts at.
 *                   <dt>VS_TAGDETAIL_match_scope_seekpos<dd style="margin-left:240pt">(int) seek position body starts at.
 *                   <dt>VS_TAGDETAIL_match_end_linenum<dd style="margin-left:240pt">(int) line number tag ends on.
 *                   <dt>VS_TAGDETAIL_match_end_seekpos<dd style="margin-left:240pt">(int) seek position tag ends at.
 *                   <dt>VS_TAGDETAIL_match_class<dd style="margin-left:240pt">    		(string) name of class.
 *                   <dt>VS_TAGDETAIL_match_flags<dd style="margin-left:240pt">       	(int) tag attribute flags.
 *                   <dt>VS_TAGDETAIL_match_args<dd style="margin-left:240pt">         	(string) tag arguments.
 *                   <dt>VS_TAGDETAIL_match_return<dd style="margin-left:240pt">   	(string) value or type of symbol.
 *                   <dt>VS_TAGDETAIL_match_outer<dd style="margin-left:240pt">        	(int) ID of first enclosing tag.
 *                   <dt>VS_TAGDETAIL_match_parents<dd style="margin-left:240pt">     	(string) class derivation.
 *                   <dt>VS_TAGDETAIL_match_throws<dd style="margin-left:240pt">     	(string) function/proc exceptions.
 *                   <dt>VS_TAGDETAIL_match_included_by<dd style="margin-left:240pt">(string) file including this macro.
 *                   <dt>VS_TAGDETAIL_match_return_only<dd style="margin-left:240pt">(string) just the type of variable.
 *                   <dt>VS_TAGDETAIL_match_return_value<dd style="margin-left:240pt">(string) default value of variable.
 *                   <dt>VS_TAGDETAIL_match_language_id<dd style="margin-left:240pt">(string) language mode for symbol.
 * @param item_id    context_id, local_id, or match_id
 * @param result     (Output) value of detail is returned here
 *
 * @see tag_get_detail
 * @see tag_get_info
 * @see tag_get_tag_browse_info
 * @see tag_get_tag_symbol_info
 * @see tag_find_equal
 * @see tag_next_equal
 * @see tag_find_prefix
 * @see tag_next_prefix
 * @see tag_find_context
 * @see tag_next_context
 * @see tag_get_context 
 * @see tag_get_context_browse_info 
 * @see tag_get_context_symbol_info 
 * @see tag_find_local
 * @see tag_next_local 
 * @see tag_get_local 
 * @see tag_get_local_browse_info 
 * @see tag_get_local_symbol_info 
 * @see tag_get_match 
 * @see tag_get_match_browse_info 
 * @see tag_get_match_symbol_info 
 *
 * @categories Tagging_Functions
 */
extern void tag_get_detail2(int tag_detail, int item_id, var result);


/**
 * Remove duplicate symbols from the set of tags in a match set.
 * 
 * @param pszMatchExactSymbolName   (optional) look for exact matches to this symbol only 
 * @param pszCurrentFileName        (optional) current file name
 * @param pszCurrentFileName        (optional) current language mode
 * @param removeDuplicatesOptions   set of bit flags of options for what kinds of duplicates to remove. 
 *        <ul>
 *        <li>VS_TAG_REMOVE_DUPLICATE_PROTOTYPES -
 *            Remove forward declarations of functions if the corresponding function 
 *            definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_GLOBAL_VARS -              
 *            Remove forward or extern declarations of global and namespace level 
 *            variables if the actual variable definition is also in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CLASSES -              
 *            Remove forward declarations of classes, structs, and 
 *            interfaces if the actual definition is in the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_IMPORTS -
 *            Remove all import statements from the match set.
 *        <li>VS_TAG_REMOVE_DUPLICATE_SYMBOLS -
 *            Remove all duplicate symbol definitions.
 *        <li>VS_TAG_REMOVE_DUPLICATE_CURRENT_FILE -
 *            Remove tag matches that are found in the current symbol context.
 *        <li>VS_TAG_REMOVE_DUPLICATE_FUNCTION_SIGNATURES -              
 *            [not implemented here] 
 *            Attempt to filter out function signatures that do not match.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANONYMOUS_CLASSES -              
 *            Filter out anonymous class names in preference of typedef.
 *            for cases like typedef struct { ... } name_t;
 *        <li>VS_TAG_REMOVE_DUPLICATE_TAG_USES -              
 *            Filter out tags of type 'taguse'.  For cases of mixed language
 *            Android projects, which have duplicate symbol names in the XML and Java.
 *        <li>VS_TAG_REMOVE_DUPLICATE_ANNOTATIONS -              
 *            Filter out tags of type 'annotation' so that annotations
 *            do not conflict with other symbols with the same name.
 *        <li>VS_TAG_REMOVE_BINARY_LOADED_TAGS -
 *            Filter out tags from files which were loaded using a binary
 *            load tags method, such as jar files or .NET dll files.
 *        </ul>
 *  
 * @see tag_list_symbols_in_context 
 * @see tag_list_in_class
 * @see tag_list_in_file
 * @see tag_list_globals_of_type 
 * @see tag_list_context_globals
 * @see tag_list_context_imports
 * @see tag_list_context_packages
 * @see tag_list_duplicate_matches 
 * @see tag_list_duplicate_tags 
 * @see tag_remove_duplicate_symbols_from_matches_with_function_argument_matching 
 * @see tag_remove_duplicate_symbol_matches 
 *
 * @categories Tagging_Functions
 */
extern void tag_remove_duplicate_symbols_from_matches(_str pszMatchExactSymbolName,
                                                      _str pszCurrentFileName,
                                                      _str pszCurrentLangId,
                                                      VSTagRemoveDuplicatesOptionFlags removeDuplicatesOptions);

/**
 * Filter out the symbols in the current match set that do not
 * match the given set of filters.  If none of the symbols in the
 * match set match the filters, do no filtering.
 * 
 * @param filter_flags  bitset of VS_TAGFILTER_*
 * @param filter_all    if 'true', allow all the matches to be filtered out
 *
 * @categories Tagging_Functions
 */
extern void tag_filter_symbols_from_matches(SETagFilterFlags filter_flags, bool filter_all=false);

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
 *
 * @categories Tagging_Functions
 *  
 * @see _do_complete() 
 * @see tag_find_longest_prefix_match 
 * @see tag_find_longest_pattern_match 
 * @see tag_find_longest_fuzzy_match 
 */
extern int tag_find_longest_prefix_match(_str lastid, 
                                         _str &longest_prefix,
                                         _str &longest_case_prefix,
                                         _str &longest_caption,
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
 * @param longest_caption              (output) set to longest caption in match set
 * @param longest_prefix_case_is_same  (output) set to true if all the prefixes match in the same case
 * 
 * @return Return the number of matches found, return 0 if none are found. 
 *         Return 1 if there was one unique match found.
 *
 * @categories Tagging_Functions
 *  
 * @see _do_complete() 
 * @see tag_find_longest_prefix_match 
 * @see tag_find_longest_pattern_match 
 * @see tag_find_longest_fuzzy_match 
 */ 
extern int tag_find_longest_pattern_match(_str lastid, 
                                          bool case_sensitive,
                                          SETagContextFlags pattern_flags,
                                          _str &longest_prefix,
                                          _str &longest_caption,
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
 * @param longest_caption              (output) set to longest caption in match set
 * @param longest_prefix_case_is_same  (output) set to true if all the prefixes match in the same case
 * 
 * @return Return the number of matches found, return 0 if none are found. 
 *         Return 1 if there was one unique match found.
 *
 * @categories Tagging_Functions 
 *  
 * @see _do_complete() 
 * @see tag_find_longest_prefix_match 
 * @see tag_find_longest_pattern_match 
 * @see tag_find_longest_fuzzy_match 
 */ 
extern int tag_find_longest_fuzzy_match(_str lastid, 
                                        bool case_sensitive,
                                        int start_col,
                                        _str &longest_prefix,
                                        _str &longest_caption,
                                        bool &longest_prefix_case_is_same);


///////////////////////////////////////////////////////////////////////////
// Utility functions for implementing Context Tagging(R) functions,
// optimized version of former components of context.e

/**
 * Determines access to a tag
 *
 * @param context_flags    VS_TAGCONTEXT_*
 * @param tag_flags        Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 *
 * @return Returns <b>true</b> if at the current access level (represented by context_flags), we have access to the member with the given access restrictions (represented by <i>tag_flags</i>), <b>false</b> if not.
 * @see tag_check_context_flags
 * @see tag_insert_simple
 *
 * @categories Tagging_Functions
 */
extern int tag_check_access_level(SETagContextFlags context_flags, SETagFlags tag_flags);

/**
 * Returns <b>true</b> if the tag having the given tag_flags and type matches the
 * requirements set by the given context flags.
 *
 * @param context_flags    VS_TAGCONTEXT_*
 * @param tag_flags        Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param type_name        tag type (from tag details)
 *
 * @return Returns <b>true</b> if the tag with the given type and flags passes
 *         the context flags, otherwise, returns <b>false</b>.
 *
 * @see tag_check_access_level
 * @see tag_get_type
 * @see tag_insert_simple
 *
 * @categories Tagging_Functions
 */
extern bool tag_check_context_flags(SETagContextFlags context_flags, SETagFlags tag_flags, _str type_name);


/**
 * Determine if the given tag name pattern matches the given symbol name 
 * in accordance with the options specified for symbol matching strategies. 
 * 
 * @param tag_name_pattern     tag name pattern to search for (must be non-null)
 * @param symbol_name          symbol name to check (must be non-null)
 * @param exact_match          do we expect to match the entire symbol?
 * @param case_sensitive       are we looking for a case-sensitive or case-insensitive match?
 * @param context_flags        bitset of pattern matching flags (SE_TAG_CONTEXT_MATCH_*)
 * 
 * @return Returns 'true' if the symbol matches the given pattern.
 *
 * @categories Tagging_Functions
 */
extern bool tag_matches_symbol_name_pattern(_str tag_name_pattern,
                                            _str symbol_name,
                                            bool exact_match = true, 
                                            bool case_sensitive = true,
                                            SETagContextFlags context_flags=SE_TAG_CONTEXT_MATCH_PREFIX);

/** 
 * Determine if the given identifier matches the given symbol name after 
 * correcting a transposed character, missing character, or repeated character. 
 *  
 * @param identifier_prefix    identifier prefix to attempt to correct
 * @param symbol_name          symbol name to check (must be non-null)
 * @param case_sensitive       are we looking for a case-sensitive or case-insensitive match? 
 * @param start_col            column to start corrections at 
 *                             (assumes prefix up to that point matches) 
 * 
 * @return Return 'true' if the symbol matches the given identifier.
 *
 * @categories Tagging_Functions
 */
extern bool tag_matches_prefix_with_corrections(_str identifier_prefix, 
                                                _str symbol_name,
                                                bool case_sensitive=true,
                                                int start_col=0);

/**
 * Decompose a class name into its outer component and
 * inner class name only.  This is strictly a string function,
 * no file I/O or searching is involved.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param class_name Class name to split.  See {@link VS_TAGSEPARATOR_class} and
 *                   {@link VS_TAGSEPARATOR_package} for more details.
 * @param inner_name (Output) 'inner' class name (class name only)
 * @param outer_name (Output) 'outer' class name (class_name - inner_name)
 * @param outer_first_only  When <b>true</b>, set outer_name to just the name of the outer class
 *                          rather than the qualified class name.
 *
 * @see tag_join_class_name
 *
 * @categories Tagging_Functions
 */
extern void tag_split_class_name(_str class_name, var inner_name, var outer_name,bool outer_first_only=false);

/**
 * Determine whether the class name and outer class name
 * should be joined using a package separator or class
 * separator and return the resulting string.  This involves
 * searching for the outer class name as a package, if found,
 * then use the package separator {@link VS_TAGSEPARATOR_package},
 * otherwise use the class separator {@link VS_TAGSEPARATOR_class}.
 * The current object must be an editor control or current
 * buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param class_name name of class to join (inner_class)
 * @param outer_class
 *                   name of outer class or package to join
 * @param tag_files  (reference, read-only array of strings)
 *                   list of tag files to search
 * @param case_sensitive
 *                   Specifies search case sensitivity.
 * @param allow_anonymous  (optional) Allow <i>class_name</i> to be an anonymous class. 
 * @param only_opaque      (optional) only opaque classes 
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return Returns static string if <i>outer_class</i> :: <i>class_name</i> was found in
 *         the context or tag database, otherwise returns '';
 *
 * @see tag_split_class_name
 *
 * @categories Tagging_Functions
 */
extern _str tag_join_class_name(_str class_name, _str outer_class, 
                                _str (&tag_files)[],
                                bool case_sensitive,
                                bool allow_anonymous=false,
                                bool only_opaque=false,
                                typeless &visited=null, int depth=0);

/**
 * Determine if <i>parent_class</i> is a parent of <i>child_class</i>, that is, does
 * <i>child_class</i> derive either directly or transitively from <i>parent_class</i>.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param parent_class     class to check if it is a parent (base class)
 * @param child_class      class to check if it is derived from parent
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param normalize        attempt to normalize class name or take as-is?
 * @param parent_file      (optional) path to file containing the parent class
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if 'child_class' derives from 'search_class', otherwise 0.
 *
 * @see tag_find_class
 * @see tag_get_inheritance
 *
 * @categories Tagging_Functions
 */
extern int tag_is_parent_class(_str parent_class, _str child_class,
                               _str (&tag_files)[], 
                               bool case_sensitive, bool normalize, 
                               _str parent_file=null,
                               typeless &visited=null, int depth=0);

/**
 * Lookup <i>tag_name</i> and see if it could be a typedef symbol.  If so,
 * return 1, otherwise return 0.
 *
 * <p>This function ignores class scope.  Simply put, if <i>tag_name</i> is a typedef,
 * anywhere, this function may return true.  Thus, it's should really be used
 * only as an arbiter prior to attempting to match <i>symbol</i> in context as a
 * typedef.  The reason that this function behaves in this was is for speed
 * and simplicity.  Otherwise, it would have to search all parent and outer
 * class scopes, in addition to locals, context and tag files.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         Tag name to check if it is a typedef
 * @param tag_files        (Input) Tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param namespace_name   namespace or class to search
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return Returns 1 if <i>tag_name</i> could be a typedef. Returns 0 if <i>tag_name</i> is not a typedef.
 *         &lt;0 on error.
 *
 * @see tag_check_for_define
 * @see tag_check_for_package
 * @see tag_check_for_template
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_typedef(_str symbol, _str (&tag_files)[],
                                 bool case_sensitive, _str namesapce_name=null,
                                 typeless &visited=null, int depth=0);

/**
 * Lookup 'symbol' and see if it could be an enumerated type.
 * If so, return 1, otherwise return 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           symbol to investigate
 * @param class_name       namespace or class to search
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if 'symbol' could be an enum, 0 otherwise, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_enum(_str symbol,  _str class_name,
                              _str (&tag_files)[], bool case_sensitive,
                              typeless &visited=null, int depth=0);

/**
 * Lookup 'symbol' and see if it could be an import.
 * If so, return 1, otherwise return 0.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param symbol           symbol to investigate
 * @param class_name       namespace or class to search
 * @param tag_files        (reference to _str[]) tag files to search
 * @param case_sensitive   use case-sensitive comparisons?
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if 'symbol' could be an import, 0 otherwise, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_import(_str symbol,  _str class_name,
                                _str (&tag_files)[], bool case_sensitive,
                                typeless &visited=null, int depth=0);

/**
 * Look up <i>tag_name</i> and see if it is a macro preprocessing symbol (#define). 
 * If so, return the value of symbol in <i>alt_tag_name</i>.  Note that this function
 * does not normally support complex macros, that is, macros having arguments or 
 * defined to something more complicated than a simple identifier or empty string. 
 * However, if the 'arglist' variable is passed in, then it will return more complex 
 * macro definitions if one is found. 
 * <p>
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name      Tag name to check if it is a macro define.
 * @param line_no       If found in current context, define must be before 'line'
 * @param tag_files     (onput) Tag files to search
 * @param id_defined_to (output) Returns value of #define macro.
 * @param arglist       (output) Returns the argument list of the #define macro
 *
 * @return Returns the number of matches was found, 0 of none found.
 *
 * @see tag_check_for_package
 * @see tag_check_for_template
 * @see tag_check_for_enum
 * @see tag_check_for_typedef
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_define(_str tag_name, int line_no, _str (&tag_files)[], _str &id_defined_to, ... /*_str &arglist*/);

/**
 * Look up <i>tag_name</i> and see if it is a class or struct 
 * name. If so, return the signature of the template in 
 * template_sig. The current object must be an editor control or 
 * current buffer. 
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         Tag name to check if it is a template class.
 * @param outer_class      Name of class that tag belongs to.
 * @param case_sensitive   Speciifies case_sensitive comparison
 * @param tag_files        (input) Tag files to search 
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if a match was found, 0 of none found.
 *  
 * @see tag_check_for_template 
 * @see tag_check_for_define
 * @see tag_check_for_package
 * @see tag_check_for_typedef
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_class(_str tag_name, _str outer_class,
                               bool case_sensitive, _str (&tag_files)[],
                               typeless &visited=null, int depth=0);

/**
 * Look up <i>tag_name</i> and see if it is a template class.
 * If so, return the signature of the template in template_sig.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         Tag name to check if it is a template class.
 * @param outer_class      Name of class that tag belongs to.
 * @param case_sensitive   Speciifies case_sensitive comparison
 * @param tag_files        (Input) Tag files to search
 * @param template_sig     (Output) returns signature of template_sig
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if a match was found and sets template_sig, 0 of none found.
 *  
 * @see tag_check_for_class 
 * @see tag_check_for_define
 * @see tag_check_for_package
 * @see tag_check_for_typedef
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_template(_str tag_name, _str outer_class,
                                  bool case_sensitive, _str (&tag_files)[], 
                                  _str &template_sig,
                                  typeless &visited=null, int depth=0);

/**
 * Look up <i>tag_name</i> and see if it is a package, namespace, module or unit.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param tag_name         Tag name to check if it is a package or package prefix.
 * @param tag_files        (reference to _str[]) list of tag files to search
 * @param exact_match      Look for exact match rather than prefix match
 * @param case_sensitive   Specifies case sensitive comparison
 * @param aliased_to       (optional, output) set to package alias name if found 
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return Returns non-zero value if the given tag is a package name or the prefix of a package name. 
 *         Otherwise returns <b>0</b>.
 *
 * @see tag_check_for_define
 * @see tag_check_for_template
 * @see tag_check_for_typedef
 * @see tag_tree_type_is_package
 *
 * @categories Tagging_Functions
 */
extern int tag_check_for_package(_str tag_name, _str (&tag_files)[],
                                 bool exact_match, bool case_sensitive,
                                 _str &aliased_to=null,
                                 typeless &visited=null, int depth=0);

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
 * @return <b>true</b> if two classes are in the same package scope, otherwise <b>false</b>.
 *
 * @see tag_check_for_package
 *
 * @categories Tagging_Functions
 */
extern bool tag_is_same_package(_str class1, _str class2, bool case_sensitive);

/**
 * List the global symbols of the given type. See
 * {@link tag_find_global} for more details.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true)
 * and tag_lock_context(false) prior to invoking this function. 
 *
 * @param tree_wid         Window ID of tree control to insert into,
 *                         0 indicates to insert into a match set, see {@link tag_insert_match}.
 * @param tree_index       Parent tree node index to insert item under, ignored if <i>tree_wid</i> is zero.
 * @param tag_files        (Input) Tag files to search
 * @param type_id          Tag type ID.  See {@link tag_get_type} for a list of all standard tag types.
 *                         if (type_id&lt;0), returns tags with ID>SE_TAG_TYPE_LASTID
 * @param mask             Tag flags indicating symbol attributes, see
 *                         {@link tag_insert_simple} for details.
 * @param nonzero          if 1, succeed if mask & tag.flags != 0
 *                         if 0, succeed if mask & tag.flags == 0
 * @param vnum_matches     (Input, Output) number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *  
 * @see tag_find_global
 * @see tag_get_type
 * @see tag_insert_match
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_globals_of_type(int tree_wid, int tree_index, _str (&tag_files)[],
                                    int type_id, int mask, int nonzero,
                                    var vnum_matches, int max_matches,
                                    typeless &visited=null, int depth=0);

/**
 * List the packages matching the given prefix expression.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param tree_wid         window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param vnum_matches     (Output) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *
 * @categories Tagging_Functions
 */
extern int tag_list_context_packages(int tree_wid, int tree_index,
                                     _str prefix, _str (&tag_files)[],
                                     var vnum_matches, int max_matches,
                                     bool exact_match, bool case_sensitive,
                                     typeless &visited=null, int depth=0);

/**
 * List any symbols, reguardless of context or scope (excluding locals)
 * matching the given prefix expression.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid         Window ID of the tree control to insert into, if 0,
 *                         insert tags into the match set, see {@link tag_insert_match}.
 * @param tree_index       Parent tree node index to insert item under, ignored if
 *                         <i>tree_wid</i> is zero.
 * @param tag_name         Tag name or prefix of tag name to search for.
 * @param tag_files        (Input) tag files to search
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match
 * @param case_sensitive   Specifies search case sensitivity
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *
 * @see tag_insert_match
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_any_symbols(int tree_wid,int tree_index, 
                                _str tag_name, 
                                _str (&tag_files)[], 
                                SETagFilterFlags filter_flags,
                                SETagContextFlags context_flags,
                                var vnum_matches,int max_matches,
                                bool exact_match,bool case_sensitive,
                                typeless &visited=null, int depth=0);

/**
 * List the symbols found in files having the given 'base' filename
 * and passing the given pushtag and context flags.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param tree_wid         window id of tree control to insert into,
 *                         0 indicates to insert into a match set, see {@link tag_insert_match}.
 * @param tree_index       Parent tree node index to insert item under, ignored if <i>tree_wid</i> is zero.
 * @param prefix           Tag name or prefix of tag name to search for.
 * @param tag_files        (Input) Tag files to search
 * @param file_name        Only list tags coming from file with this "base" name.
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) Number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match (0)
 * @param case_sensitive   Specifies search case sensitivity.
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *
 * @see tag_insert_match
 * @see tag_list_any_symbols
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_in_file(int tree_wid,int tree_index,
                            _str prefix,
                            _str (&tag_files)[],
                            _str file_name,
                            SETagFilterFlags filter_flags,
                            SETagContextFlags context_flags,
                            var vnum_matches,int max_matches,
                            bool exact_match,bool case_sensitive,
                            typeless &visited=null, int depth=0);

/**
 * List the global symbols visible in the given list of tag files
 * matching the given tag filters and context flags.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid         Window ID of tree control to insert into,
 *                         0 indicates to insert into a match set, see {@link tag_insert_match}.
 * @param tree_index       Parent tree node index to insert item under, ignored if <i>tree_wid</i> is zero.
 * @param tag_name         Tag name or prefix of tag name to search for.
 * @param check_context    check for symbols in the current context?
 * @param tag_files        (Input) Tag files to search
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) Number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match (0)
 * @param case_sensitive   Specifies search case sensitivity.
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *
 * @see tag_insert_match
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_context_globals(int tree_wid, int tree_index, 
                                    _str tag_name,
                                    bool check_context, 
                                    _str (&tag_files)[],
                                    SETagFilterFlags filter_flags, 
                                    SETagContextFlags context_flags,
                                    var vnum_matches, int max_matches,  
                                    bool exact_match, bool case_sensitive,
                                    typeless &visited=null, int depth=0);

/**
 * List the symbols imported into this context
 * matching the given tag filters and context flags.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * and tag_lock_context(false) prior to invoking this function.
 *
 * @param tree_wid         Window ID of tree control to insert into,
 *                         0 indicates to insert into a match set, see {@link tag_insert_match}.
 * @param tree_index       Parent tree node index to insert item under, ignored if tree_wid is zero.
 * @param tag_name         Tag name or prefix of tag name to search for.
 * @param tag_files        (Input) Tag files to search
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) Number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match (0)
 * @param case_sensitive   Specifies search case sensitivity.
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *  
 * @return Returns 0 on success, &lt;0 on error. 
 *
 * @see tag_insert_match
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_context_imports(int tree_wid, int tree_index, 
                                    _str tag_name, 
                                    _str (&tag_files)[],
                                    SETagFilterFlags filter_flags, 
                                    SETagContextFlags context_flags,
                                    var vnum_matches, int max_matches,  
                                    bool exact_match, bool case_sensitive,
                                    typeless &visited=null, int depth=0);

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
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid         window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param tag_files        symbol prefix to match
 * @param tag_name         name of class to search for matches
 * @param class_name       (reference to _str[]) tag files to search
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    VS_TAGCONTEXT_*, tag context filter flags
 * @param vnum_matches     (Input, Output) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 * @param friend_list      (optional) List of friends to the current context
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class <i>class_name</i> is found,
 *         othewise returns 0, indicating that no matches were found.
 *
 * @see tag_find_class
 * @see tag_insert_match
 * @see tag_list_class_context
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_class_locals(int tree_wid, int tree_index, 
                                 _str (&tag_files)[],
                                 _str tag_name, 
                                 _str class_name,
                                 SETagFilterFlags filter_flags, 
                                 SETagContextFlags context_flags,
                                 var vnum_matches, int max_matches,
                                 bool exact_match, bool case_sensitive,
                                 _str friend_list=null,
                                 typeless &visited=null, int depth=0);

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
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid         window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       Parent tree node index to insert item under, ignored if tree_wid is zero.
 * @param tag_files        (Input) List of tags files to search.
 * @param tag_name         Name of class to search for matches
 * @param class_name       Name of class context to search for tags belonging to.
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.
 *                         See {@link tag_filter_type} for more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) Number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match (0)
 * @param case_sensitive   Specifies search case sensitivity.
 * @param friend_list      (optional) List of friends to the current context
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class <i>class_name</i> is found,
 *         othewise returns 0, indicating that no matches were found.
 *
 * @see tag_find_class
 * @see tag_insert_match
 * @see tag_list_class_locals
 * @see tag_list_class_tags
 * @see tag_list_context_globals
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_class_context(int tree_wid, int tree_index, 
                                  _str (&tag_files)[],
                                  _str tag_name, _str class_name,
                                  SETagFilterFlags filter_flags, 
                                  SETagContextFlags context_flags,
                                  var vnum_matches, int max_matches,
                                  bool exact_match, bool case_sensitive,
                                  _str friend_list=null,
                                  typeless &visited=null, int depth=0);

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
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid         Window ID of tree control to insert into,
 *                         0 indicates to insert into a match set, see {@link tag_insert_match}
 * @param tree_index       Parent tree node index to insert item under, ignored if <i>tree_wid</i>
 *                         is zero.
 * @param tag_files        (Input) List of tag files to search.
 * @param tag_name         Tag name or prefix of tag name to search for.
 * @param class_name       Name of class context to search for tags belonging to.
 * @param filter_flags     Tag filter flags, only insert tags passing this filter.  See {@l;ink tag_filter_type} for
 *                         more details.
 * @param context_flags    Context flags representing what to allow or restrict to.
 *                         See {@link tag_check_context_flags} for more details.
 * @param vnum_matches     (Input, Output) Number of matches
 * @param max_matches      Maximum number of matches allowed
 * @param exact_match      Specifies exact match or prefix match (0)
 * @param case_sensitive   Specifies search case sensitivity.
 * @param visited          (optional) hash table of prior results
 * @param depth            (optional) depth of recursive search
 *
 * @return 1 if the definition of the given class <i>class_name</i> is found,
 *         othewise returns 0, indicating that no matches were found.
 *  
 * @see tag_find_class
 * @see tag_insert_match
 * @see tag_list_class_context
 * @see tag_list_class_locals
 * @see tag_list_context_globals
 * @see tag_tree_insert_tag
 * @see tag_tree_prepare_expand
 *
 * @categories Tagging_Functions
 */
extern int tag_list_class_tags(int tree_wid, int tree_index, 
                               _str (&tag_files)[],
                               _str tag_name, _str class_name,
                               SETagFilterFlags filter_flags, 
                               SETagContextFlags context_flags,
                               var vnum_matches, int max_matches,
                               bool exact_match, bool case_sensitive,
                               typeless &visited=null, int depth=0);


///////////////////////////////////////////////////////////////////////////
// Word index (references) table maintenance functions.
//

/**
 * Set up for inserting a series of occurrences from a single file
 * for update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param file_name        full path of file the tags are located in
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_occurrences_start(_str file_name);

/**
 * Clean up after inserting a series of occurrences from a single
 * file for update.  Doing this allows the tag database engine to
 * remove any occurrences from the database that are no longer valid.
 *
 * @param file_name        full path of file the tags are located in
 *
 * @return 0 on success, &lt;0 on error.int VSAPI
 *
 * @categories Tagging_Functions
 */
extern int tag_occurrences_end(_str file_name);

/**
 * Insert a new occurrence into the word index.
 *
 * @param occur_name      Word to be indexed
 * @param file_name       Path of file occurrence is located in
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_occurrence(_str occur_name, _str file_name);

/**
 * Find the first occurrence with the given tag name or tag prefix.
 * Use tag_get_occurrence (below) to get details about the occurrence.
 *
 * @param tag_name        Tag name or prefix to search for
 * @param exact_match     Exact (word) match or prefix match (0)
 * @param case_sensitive  Case sensitive search?
 *
 * @return 0 on success, BT_RECORD_NOT_FOUND_RC if not found, &lt;0 on error.
 *
 * @see tag_next_occurrence 
 * @see tag_get_occurrence 
 * @see tag_reset_find_occurrence 
 *  
 * @categories Tagging_Functions
 */
extern int tag_find_occurrence(_str tag_name,
                        bool exact_match=true,
                        bool case_sensitive=false);

/**
 * Find the next occurrence with the given tag name or tag prefix.
 * Use tag_get_occurrence (below) to get details about the occurrence.
 *
 * @param tag_name        Tag name or prefix to search for
 * @param exact_match     Exact (word) match or prefix match (0)
 * @param case_sensitive  Case sensitive search?
 *
 * @return 0 on success, BT_RECORD_NOT_FOUND_RC if not found, &lt;0 on error.
 *
 * @see tag_find_occurrence 
 * @see tag_get_occurrence 
 * @see tag_reset_find_occurrence 
 *  
 * @categories Tagging_Functions
 */
extern int tag_next_occurrence(_str tag_name,
                        bool exact_match=true,
                        bool case_sensitive=false);

/**
 * Retrieve information about the current occurrence, as defined by
 * tag_find_occurrence/tag_next_occurrence.
 *
 * @param occur_name      (output) Word to be indexed
 * @param file_name       (output) Path of file occurrence is located in
 *  
 * @see tag_find_occurrence 
 * @see tag_next_occurrence 
 * @see tag_get_occurrence 
 * @see tag_reset_find_occurrence 
 *  
 * @categories Tagging_Functions
 */
extern void tag_get_occurrence(_str &occur_name, _str &file_name);

/**
 * Reset the tag occurrence iterator.  Call this function after you are 
 * done searching through tag occurrences in the current database. 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @see tag_find_occurrence 
 * @see tag_next_occurrence 
 * @see tag_get_occurrence 
 * @see tag_list_occurrences 
 *  
 * @categories Tagging_Functions 
 * @since 16.0 
 */
extern int tag_reset_find_occurrence();

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
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_list_occurrences(_str file_name, _str tag_name=null,
                                bool case_sensitive=true,
                                int start_seekpos=0, int stop_seekpos=0);

/**
 * The current object must be an editor control positioned on
 * the tag that you wish to find matches for, with the edit
 * mode selected.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       Array of strings for return code
 * @param tag_name        Name of occurrence to match against
 * @param exact_match     Exact match or prefix match?
 * @param case_sensitive  Case sensitive tag search?
 * @param find_parents    Find instances of this tag in parent classes
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 * @param filter_flags    Tag filter flags, only insert tags passing this 
 *                        filter. See {@link tag_filter_type} for more details.
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *
 * @categories Tagging_Functions
 */
extern int tag_context_match_tags(var errorArgs, _str &tag_name, bool exact_match,
                                  bool case_sensitive, bool find_parents,
                                  int &num_matches, int max_matches,
                                  /* typeless &visited=null, int depth=0,
                                     SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                                     SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS|SE_TAG_FILTER_ALLOW_forward,*/ ... );

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (Output) error message parameters
 * @param tree_wid        window ID of tree control to insert into
 * @param tree_index      index of item in tree to insert under
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param filter_flags
 *                   Tag filter flags, only insert tags passing this filter.
 *                   See {@link tag_filter_type} for more details.
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (Output) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *
 * @see tag_match_symbol_occurrences_in_file 
 * @categories Tagging_Functions 
 * @deprecated Use {@link tag_match_symbol_occurrences_in_file()} instead. 
 */
extern int tag_match_occurrences_in_file(var errorArgs,
                                         int tree_wid, int tree_index,
                                         _str tag_name, bool case_sensitive,
                                         _str file_name, int line_no,
                                         SETagFilterFlags filter_flags,
                                         int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                                         int &num_matches, int max_matches,
                                         typeless &visited=null, int depth=0,
                                         SETagContextFlags context_flags=0);

/**
 * Match occurrences of the given symbol in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (Output) error message parameters
 * @param tree_wid        window ID of tree control to insert into
 * @param tree_index      index of item in tree to insert under
 * @param symbol_info     information about symbol to look for
 * @param case_sensitive  case sensitive search?
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (Output) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *
 * @categories Tagging_Functions
 */
extern int tag_match_symbol_occurrences_in_file(var errorArgs,
                                                int tree_wid, int tree_index,
                                                VS_TAG_BROWSE_INFO &symbol_info,
                                                bool case_sensitive,
                                                SETagFilterFlags filter_flags, 
                                                SETagContextFlags context_flags,
                                                int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                                                int &num_matches, int max_matches,
                                                typeless &visited=null, int depth=0,
                                                bool for_callers_tree=false);

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (Output) error message parameters
 * @param seekPositions   (Output) seek positions of occurrences
 * @param tree_index      index of item in tree to insert under
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (Output) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *  
 * @see tag_match_symbol_occurrences_in_file 
 * @see tag_match_symbol_occurrences_in_file_get_positions 
 * @categories Tagging_Functions
 */
extern int tag_match_occurrences_in_file_get_positions(var errorArgs,
                                                       var seekPositions,
                                                       _str tag_name, bool case_sensitive,
                                                       _str file_name, int line_no,
                                                       SETagFilterFlags filter_flags,
                                                       int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                                                       int &num_matches, int max_matches,
                                                       typeless &visited=null, int depth=0);

/**
 * Match occurrences of the given symbol in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (Output) error message parameters
 * @param seekPositions   (Output) seek positions of occurrences
 * @param tree_index      index of item in tree to insert under
 * @param symbol_info     information about symbol to look for
 * @param case_sensitive  case sensitive search?
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (Output) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *  
 * @categories Tagging_Functions
 */
extern int tag_match_symbol_occurrences_in_file_get_positions(var errorArgs,
                                                              var seekPositions,
                                                              VS_TAG_BROWSE_INFO &symbol_info,
                                                              bool case_sensitive,
                                                              SETagFilterFlags filter_flags, 
                                                              SETagContextFlags context_flags,
                                                              int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                                                              int &num_matches, int max_matches,
                                                              typeless &visited=null, int depth=0);

/**
 * Match occurrences of the given tag name in the current buffer,
 * Return whether any occurrences of the tag in the current buffer have a class_name
 * that matches any of the classes passed in through class_list.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (reference) error message parameters
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param class_list      list of class names to compare tag's class_name against
 * @param num_classes     number of classes in class_list
 * @param filter_flags    item filter flags
 * @param has_match       (reference) at least of the tags in this buffer matches
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 */
extern int tag_match_multiple_occurrences_in_file(var errorArgs,
                                                  _str tag_name, bool case_sensitive,
                                                  _str class_list[], int num_classes,
                                                  SETagFilterFlags filter_flags,
                                                  bool &has_match, int max_matches,
                                                  typeless &visited=null, int depth=0);

/**
 * Match occurrences of the given tag name in the current buffer,
 * Return whether any occurrences of the tag in the current buffer have a class_name
 * that matches any of the classes passed in through class_list.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (reference) error message parameters
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param class_list      list of class names to compare tag's class_name against
 * @param num_classes     number of classes in class_list
 * @param filter_flags    item filter flags
 * @param has_match       (reference) at least of the tags in this buffer matches
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 */
extern int tag_match_multiple_symbol_occurrences_in_file(var errorArgs,
                                                         VS_TAG_BROWSE_INFO (&symbols)[], 
                                                         bool case_sensitive,
                                                         SETagFilterFlags filter_flags, 
                                                         SETagContextFlags context_flags,
                                                         bool &has_match, 
                                                         int &num_matches, int max_matches,
                                                         typeless &visited=null, int depth=0);

/**
 * Match the single symbol under the cursor against the given symbol information. 
 *  
 * @param errorArgs       (reference) error message parameters
 * @param symbol_info     instance of Slick-C VS_TAG_BROWSE_INFO with symbol info
 * @param case_sensitive  case sensitive search?
 * @param filter_flags    item filter flags
 * @param context_flags 
 * @param max_matches     maximum number of occurrences to find
 * @param visited         hash table of past context tagging results
 * @param depth           recursive context tagging call depth
 * 
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *
 * @categories Tagging_Functions
 */
extern int tag_match_single_symbol_occurrence_in_file(var errorArgs,
                                                      VS_TAG_BROWSE_INFO &symbol, 
                                                      bool case_sensitive,
                                                      SETagFilterFlags filter_flags, 
                                                      SETagContextFlags context_flags,
                                                      int max_matches,
                                                      typeless &visited, int depth);

/**
 * Match occurrences of the given tag name in the current buffer,
 * starting at the specified start seek position and continuing
 * until the specified stop seek position.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param errorArgs       (Output) error message parameters
 * @param tree_wid        window ID of tree control to insert into
 * @param tree_index      index of item in tree to insert under
 * @param tag_name        name of tag to search for
 * @param case_sensitive  case sensitive search?
 * @param file_name       path of file match tag is in
 * @param line_no         real line number match tag is located on
 * @param alt_file_name   alternate path of file match tag is in
 * @param alt_line_no     alternate real line number match tag is located on
 * @param filter_flags
 *                   Tag filter flags, only insert tags passing this filter.
 *                   See {@link tag_filter_type} for more details.
 * @param caller_id       context ID of item to look for uses in
 * @param start_seekpos   starting seekpos, 0 means beginning of file
 * @param stop_seekpos    ending seekpos, 0 means EOF
 * @param num_matches     (Input, Output) number of occurrence matches found
 * @param max_matches     maximum number of occurrences to find
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error, &gt;0 on Context Tagging&reg; error.
 *
 * @categories Tagging_Functions
 */
extern int tag_match_uses_in_file(var errorArgs,
                                  int tree_wid, int tree_index,
                                  bool case_sensitive,
                                  _str file_name, int line_no,
                                  _str alt_file_name, int alt_line_no,
                                  SETagFilterFlags filter_flags, 
                                  int caller_id,
                                  int start_seekpos, int stop_seekpos,
                                  int &num_matches, int max_matches
                                  /*, typeless &visited=null, int depth=0 */, ...);

/**
 * List the files containing 'tag_name', matching by prefix or
 * case-sensitive, as specified.  Terminates search if a total
 * of max_refs are hit.  Items are inserted into the tree, with
 * the user data set to the file path.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid        window id of tree control to insert into
 * @param tree_index      index, usually TREE_ROOT_INDEX to insert under
 * @param tag_name        name of tag to search for
 * @param exact_match     exact match or prefix match
 * @param case_sensitive  case sensitive match, or case-insensitive
 * @param num_refs        (Input, Output) number of references found so far
 * @param max_refs        maximum number of items to insert 
 * @param restrictToLangId restrict references to files of the 
 *                         given language, or related language.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_list_file_occurrences(int tree_wid, int tree_index,
                                     _str tag_name, int exact_match,
                                     int case_sensitive,
                                     int &num_refs, int max_refs,
                                     _str restrictToLangId="");

/**
 * Find the next occurrence of the symbol 'tag_name' in the current file, 
 * starting at the specified start seek position, and continuing as far 
 * as the specified stop seek position. 
 * 
 * @param tag_name           symbol name to search for (regex word search is constructed from this)
 * @param case_sensitive     case-sensitive?
 * @param lang_id            current language mode
 * @param start_seekpos      start at this seek position, 0 to start at beginning of file
 * @param stop_seekpos       stop at this seek position, 0 to stop at end of file, 
 *                           also used as the starting point when searching backwards. 
 * @param search_backwards   search backwards from stop_seekpos?
 * @param include_strings    include matches in strings
 * @param include_comments   include matches in comments
 * @param include_numbers    include matches in numbers
 * @param depth              recursive call stack depth
 * 
 * @return 0 on success, &lt;0 on error. 
 *         Current seek position is left at the end of the tag found. 
 *
 * @categories Tagging_Functions
 */
extern int tag_find_next_symbol_in_file(_str tag_name, 
                                        bool case_sensitive,
                                        _str lang_id,
                                        int start_seekpos=0, int stop_seekpos=0,
                                        bool search_backwards=false,
                                        bool include_strings=false,
                                        bool include_comments=false,
                                        bool include_numbers=false,
                                        int depth=0);

/**
 * For each item in 'class_parents', normalize the class and place it in
 * 'normal_parents', along with the tag type, placed in 'normal_types'.
 *
 * @param class_parents   list of class names, seperated by semicolons
 * @param cur_class_name  class context in which to normalize class name
 * @param file_name       source file where reference to class name is
 * @param tag_files       Array of tag files to search
 * @param allow_locals    allow local classes in list
 * @param case_sensitive  case sensitive tag search?
 * @param normal_parents  (output) list of normalized class names
 * @param normal_types    (output) list of tag types found for normalized class names
 * @param normal_files    (output) list of tag files parent classes are found in
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_normalize_classes(_str class_parents,
                                 _str cur_class_name, _str file_name, _str (&tag_files)[],
                                 bool allow_locals, bool case_sensitive,
                                 _str &normal_parents, _str &normal_types, _str &normal_files
                                 /*, typeless &visited=null, int depth=0 */, ...);

/**
 * Compare the two class names, ignore class and package separators.
 * 
 * @param c1               first class name
 * @param c2               second class name
 * @param case_sensitive   compare names using a case sensitive algorithm?
 * 
 * @return Returns &lt;0 if the 'c1' is less than 'c2', 0 if they match,
 *         and &gt;0 if 'c1' is greater than 'c2', much like strcmp().
 */
extern int tag_compare_classes(_str c1, _str c2, bool case_sensitive=true);

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
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param tree_wid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (tree_wid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param num_matches     (Input, Output) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param filter_flags    Tag filter flags, only insert tags passing this 
 *                        filter. See {@link tag_filter_type} for more details.
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param template_args   (Input) hash table of template arguments
 * @param friend_list     (Input) List of friends to the current context
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 1 if the definition of the symbol is found, 0 otherwise, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_list_in_class(_str prefix, _str search_class,
                             int tree_wid, int tree_index, 
                             _str (&tag_files)[],
                             int &num_matches, int max_matches,
                             SETagFilterFlags filter_flags, 
                             SETagContextFlags context_flags,
                             bool exact_match, bool case_sensitive,
                             _str (&template_args):[]=null,
                             _str friend_list=null,
                             typeless &visited=null, int depth=0);

/**
 * Qualify the given class symbol by searching for symbols with
 * its name in the current context/scope.  This is used to resolve
 * partial class names, often found in class inheritance specifications.
 * The current object must be an editor control or current buffer.
 *
 * @param qualified_name  (output) "qualified" symbol name
 * @param qualified_max   number of bytes allocated to qualified_name
 * @param search_name     name of symbol to search for
 * @param context_class   current class context (class name)
 * @param context_file    current file name
 * @param tag_files       list of tag files to search
 * @param case_sensitive  case sensitive tag search?
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return qualified name if successful, 'search_name' on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_qualify_symbol_name(_str &qualified_name,
                                   _str search_name, _str context_class,
                                   _str context_file, _str (&tag_files)[],
                                   bool case_sensitive,
                                   typeless &visited=null, int depth=0);

/**
 * Determine the name of the current class or package context.
 * The current object needs to be an editor control.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param cur_tag_name    name of the current tag in context
 * @param cur_flags       Tag flags indicating symbol attributes, see
 *                        {@link tag_insert_simple} for details.
 * @param cur_type_name   type (SE_TAG_TYPE_*) of the current tag
 * @param cur_type_id     type ID (SE_TAG_TYPE_*) of the current tag
 * @param cur_context     class name representing current context
 * @param cur_class       This parameter is broken.  It only returns
 *                        the class if the class is in a package.
 *                        cur_context minus the package name
 * @param cur_package     only package name for the current context
 * @param visited         (optional) hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 if no context, context ID &gt;0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_get_current_context(_str &cur_tag_name,  
                                   SETagFlags &cur_flags,
                                   _str &cur_type_name, 
                                   SETagType &cur_type_id,
                                   _str &cur_context, 
                                   _str &cur_class,
                                   _str &cur_package,
                                   typeless &visited=null, int depth=0);

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
 * Failing that, it repeats steps (1-6) with filter_flags set to -1,
 * thus disabling any filtering, unless 'strict' is true.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param tree_wid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (tree_wid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param num_matches     (Input, Output) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param filter_flags
 *                   Tag filter flags, only insert tags passing this filter.
 *                   See {@link tag_filter_type} for more details.
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param strict          strict match, or allow any match?
 * @param find_parents    find parents of the given class?
 * @param find_all        find all instances, for each level of scope
 * @param search_file     (optional) file to search for matches in (for imports)
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 * 
 * @deprecated
 * @see tag_list_symbols_in_context
 */
extern int tag_match_symbol_in_context(_str prefix, _str search_class,
                                       int tree_wid, int tree_index, 
                                       _str (&tag_files)[],
                                       int &num_matches,int max_matches,
                                       SETagFilterFlags filter_flags, 
                                       SETagContextFlags context_flags,
                                       bool exact_match, bool case_sensitive,
                                       bool strict, bool find_parents, bool find_all,
                                       /* _str search_file=null */ ... );

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
 * Failing that, it repeats steps (1-6) with filter_flags set to -1,
 * thus disabling any filtering, unless 'strict' is true.
 * The current object must be an editor control or current buffer.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param tree_wid        window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (treewid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param search_file     file to search for matches in (for imports)
 * @param num_matches     (reference) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param filter_flags   VS_TAGFILTER_*, tag filter flags
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param visited         hash table of prior results
 * @param depth           depth of recursive search 
 * @param template_args   [optional] hash table of template arguments 
 *
 * @categories Tagging_Functions
 * 
 * @return 0 on success, &lt;0 on error.
 */
extern int tag_list_symbols_in_context(_str prefix, _str search_class,
                                       int tree_wid, int tree_index, 
                                       _str (&tag_files)[], _str search_file,
                                       int &num_matches, int max_matches,
                                       SETagFilterFlags filter_flags, 
                                       SETagContextFlags context_flags,
                                       bool exact_match, bool case_sensitive,
                                       typeless &visited=null, int depth=0,
                                       _str (&template_args):[] = null);

/**
 * Match symbols in all tag files against the given member and class filters.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param tree_wid        Window ID of the tree control
 * @param tree_index      Tree index to insert items under
 * @param progress_wid    Window id of progress label
 * @param member_filter   Prefix or regular expression for symbols
 * @param class_filter    Regex or prefix for class names
 * @param tag_files       list of tag files to search
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 * @param num_matches     (Input, Output) number of matches found
 * @param max_matches     maximum number of matches to find
 * @param regex_match     perform regular expression match?
 * @param exact_match     exact match or prefix match?
 * @param case_sensitive  Case sensitive match or case-insensitive?
 *
 * @return 0 on success, 1 if list was truncated,
 *         &lt;0 on error.
 * @see tag_match
 * @since 5.0a
 *
 * @categories Tagging_Functions
 */
extern int tag_pushtag_match(int tree_wid, int tree_index, 
                             int progress_wid,
                             _str member_filter, _str class_filter,
                             _str (&tag_files)[], 
                             SETagFilterFlags filter_flags/*=SE_TAG_FILTER_ANYTHING*/,
                             int &num_matches, int max_matches,
                             bool regex_match/*=false*/, 
                             bool exact_match/*=false*/,
                             bool case_sensitive/*=false*/);


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
 *
 * @categories Tagging_Functions
 */
extern int tag_list_duplicate_tags(_str (&taglist)[], 
                                   _str (&filelist)[],
                                   _str proc_name, 
                                   _str (&tag_files)[],
                                   ... 
                                   /*int max_matches,*/
                                   /*SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING*/ );

/**
 * Find all tags in the given tag databases matching
 * the given tag name, and possibly class or type
 * specification.  Places matches in the current match set.
 * <p> 
 * For synchronization, macros should perform a tag_lock_matches(true) 
 * prior to invoking this function. 
 *
 * @param proc_name       Composed tag name to search for
 * @param tag_files       List of tag files to search 
 * @param max_matches     Maximum number of symbols to find 
 * @param filter_flags    Tag filter flags, only insert tags passing this filter.
 *                        See {@link tag_filter_type} for more details.
 *
 * @return 0 on succes, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_list_duplicate_matches(_str proc_name, 
                                      _str (&tag_files)[], 
                                      ...
                                      /*int max_matches,*/
                                      /*SETagFilterFlags filter_flags-SE_TAG_FILTER_ANYTHING*/ );


/**
 * Update the tags in the current context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_update_context();

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
 *
 * @categories Tagging_Functions
 */
extern int tag_update_locals(int find_all);

/**
 * Update the locals in the current function or set of nested functions.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locals in
 * @param find_all         Find all locals, or just up to cursor position? 
 * @param cur_seekpos      Current seek position to find local variables at 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_parse_and_update_locals(int start_seekpos, int end_seekpos, int context_id, int cur_seekpos, int ltf_flags);

/**
 * Insert the start and end seek positions, and
 * optionally the file extension information for an
 * embedded context.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param start_seekpos start seek position of embedded context
 * @param end_seekpos   end seek position of embedded context
 *
 * @return 0 on success, &lt;0 on error
 *
 * @categories Tagging_Functions
 */
extern int tag_insert_embedded(int start_seekpos, int end_seekpos);

/**
 * Clear the list of embedded context information.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @categories Tagging_Functions
 */
extern void tag_clear_embedded();

/**
 * Retrieve the embedded context information for
 * the given position 'i' (first is 0).
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param i             index of embedded context to retrieve
 * @param start_seekpos (Output) set to start seek position for embedded context
 * @param end_seekpos   (Output) set to end seekposition for embedded context
 *
 * @return 0 on success, &lt;0 on error
 *
 * @categories Tagging_Functions
 */
extern int tag_get_embedded(int i, int &start_seekpos, int &end_seekpos);

/**
 * @return Return the number of embedded contexts in the current buffer.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *  
 * @param countUnparsedOnly   If 'true' only return the number of embedded 
 *                            sections that have not yet been parsed, otherwise
 *                            return all the embedded code sections. 
 *  
 * @categories Tagging_Functions
 */
extern int tag_get_num_of_embedded(bool countUnparsedOnly=false);

/**
 * Register a new OEM-defined type.
 *
 * @param type_id              Tag type ID, in range SE_TAG_TYPE_OEM &lt;= type_id &lt;= SE_TAG_TYPE_MAXIMUM
 * @param pszTypeName          Tag type name
 * @param is_container         1=tag type is a container (i.e. can have members)
 * @param description          (optional) description of the new tag type
 * @param filterFlags          (optional) VS_TAGFILTER_* 
 * @param bitmapName           (optional) name of bitmap to use for this tag 
 *
 * @return 0 on success, &lt;0 on error.
 *
 * @categories Tagging_Functions
 */
extern int tag_register_type(int type_id, 
                             _str pszTypeName, 
                             int is_container=0,
                             _str description=null, 
                             SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                             _str bitmapName=null);

/**
 * Unregister a OEM-defined type.
 *
 * @param type_id Tag type ID, in range SE_TAG_TYPE_OEM &lt;= type_id &lt;= SE_TAG_TYPE_MAXIMUM
 *
 * @categories Tagging_Functions
 */
extern void tag_unregister_type(int type_id);

/**
 * Get the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range 0-SE_TAG_TYPE_MAXIMUM
 *
 * @return Filter flags for type ID.
 *
 * @categories Tagging_Functions
 */
extern SETagFilterFlags tag_type_get_filter(int type_id);

/**
 * Set the filter flags for given type ID.
 *
 * @param type_id Tag type ID, in range SE_TAG_TYPE_OEM &lt;= type_id &lt;= SE_TAG_TYPE_MAXIMUM
 * @param filter_flags
 *                   New tag filter flags, only insert tags passing this filter.
 *                   See {@link tag_filter_type} for more details.
 *
 * @categories Tagging_Functions
 */
extern void tag_type_set_filter(int type_id,SETagFilterFlags filter_flags);

/** 
 * Get the optional text description of the given type ID (for screen display) 
 *
 * @param type_id Tag type ID, in range 0-SE_TAG_TYPE_MAXIMUM 
 *  
 * @return Description of the given type ID 
 *
 * @categories Tagging_Functions
 */
extern _str tag_type_get_description(int type_id);

/**
 * Set the description for the given type ID.
 *
 * @param type_id       Tag type ID, in range SE_TAG_TYPE_OEM (greater than or 
 *                      equal to) type_id (greater than or equal to)
 *                      SE_TAG_TYPE_MAXIMUM
 * @param description   Tag type description
 *
 * @categories Tagging_Functions
 */
extern void tag_type_set_description(int type_id, _str description);

/**
 * Get the database type id corresponding to the given string.
 * 
 * @param type_name    type name to look up 
 * 
 * @return &lt;0 if not found, type ID &gt;0 on success
 *
 * @categories Tagging_Functions
 */
extern SETagType tag_get_type_id(_str type_name);


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
 * @param ext              current language (default=p_LangId)
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 *
 * @categories Tagging_Functions
 * @deprecated use {@link _FindLanguageCallbackIndex()} 
 */
extern int tag_find_ext_callback(_str callback_name, _str ext=null);

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
 * @param argument      [output] set to the next argument in the argument list
 * @param ext           current file extension
 * 
 * @return Returns the position where the argument begins in 'params'.
 *         Note, this may differ from the original value of 'arg_pos'
 *         if there are leading spaces.  Returns STRING_NOT_FOUND_RC 
 *         and sets 'argument' to the empty string if there are no more
 *         arguments in the parameter list.
 *
 * @categories Tagging_Functions
 */
extern int tag_get_next_argument(_str params, int &arg_pos, _str &argument, _str ext=null);

/**
 * Does the current extension match or
 * inherit from the given extension?
 * <p>
 * If 'ext' is not specified, the current object
 * must be an editor control.
 *
 * @param parent     extension to compare to
 * @param ext        current language (default=p_LangId)
 * 
 * @return 'true' if the extension matches, 'false' otherwise.
 *
 * @categories Tagging_Functions
 * @deprecated use {@link _LanguageInheritsFrom()} 
 */
extern int tag_ext_inherits_from(_str parent, _str ext=null);

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
 * @categories Tagging_Functions
 */
extern int tag_find_friends_to_tag(_str tag_name, _str class_name,
                            _str (&tag_files)[], _str &friend_list);

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
 * @categories Tagging_Functions
 */
extern int tag_find_friends_of_class(_str class_name,
                                     _str (&tag_files)[], _str &friend_list);

/**
 * @return
 * Returns true if the given given class is among the friends on the
 * given friend list.  Otherwise it returns false.  Since this language
 * feature is specific to C++, the check is always case sensitive.
 * 
 * @param class_name    class which tag is coming from
 * @param friend_list   list of classes that are friendly to our context
 *
 * @categories Tagging_Functions
 */
extern int tag_check_friend_relationship(_str class_name, _str friend_list);

/**
 * Reset the internal reference locations variable. For 
 * SlickEdit Tools 
 *
 * @categories Tagging_Functions
 */
extern void tag_locations_clear();


/** 
 * @return 
 * Return the number of background tagging jobs queued, finished, and running. 
 * 
 * @param jobKind    The kind of job to return the number of. 
 *                   Currently, only "A" (All) is supported. 
 *                   <ul>
 *                   <li>"A" for all jobs
 *                   <li>"U" for unfinished jobs
 *                   <li>"Q" for just queued jobs
 *                   <li>"F" for finished jobs
 *                   <li>"P" for finished jobs which were postponed to avoid delays
 *                   <li>"R" for running jobs
 *                   <li>"L" for jobs waiting for file to be read from disk
 *                   <li>"T" for the number of threads running 
 *                   <li>"W" for the number of jobs waiting to be placed in the tagging queues
 *                   </ul>
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_num_async_tagging_jobs(_str jobKind="A");

/**
 * Queue up an asynchronous database tagging job to finish tagging the given 
 * file.  The tags to insert are contained in the taglist, and they are 
 * presumed to come from using a synchronous Slick-C language-specific 
 * "proc_search" function to find the tags. 
 * <p> 
 * This function will queue up the job to be completed by the database 
 * tagging thread, so that the main thread does not have to be slowed down 
 * writing to the database, or for that matter, getting write access to the 
 * tag database. 
 * 
 * @param fileName         Name of file to update tagging results for 
 * @param taggingFlags     tagging options flags (bitset of VSLTF_*)
 * @param bufferId         ID of editor buffer to update tagging for
 * @param languageId       p_lang_id for the file being tagged
 * @param tagDatabase      tag database to insert tags into
 * @param fileDate         current date of file at time of parsing
 * @param lastModified     p_lastModified at time of parsing
 * @param modifyFlags      p_modifyFlags at time of parsing
 * @param taglist          list of tags found by lang_proc_search()
 * @param linelist         parallel array of lines where tags were found
 * @param wordlist         list of words found in file (if tagging references)
 * 
 * @return 0 on success, &lt;0 on error
 *  
 * @since 19.0.1 
 * @categories Tagging_Functions
 */
extern int tag_queue_async_database_job(_str fileName,
                                        int taggingFlags,
                                        int bufferId,
                                        _str languageId,
                                        _str tagDatabase,
                                        _str fileDate,
                                        int lastModified,
                                        int modifyFlags,
                                        _str (&taglist)[],
                                        int  (&linelist)[],
                                        _str (&wordlist)[]);

/**
 * Check the result of an asynchronous tagging operation, in order to report 
 * our progress as we create a tag file in the background, or update the 
 * current context or locals in the background, or update the tagging for 
 * other buffers in the background. 
 * 
 * @param fileName         (output) set to name of file tagged 
 * @param taggingFlags     (output) set to tagging flags (VSLTF_*) for operation 
 * @param bufferId         (output) set to buffer Id of file which was tagged 
 * @param lastModified     (output) set to the generation count of the file 
 *                         which was tagged
 * @param updateFinished   (output) set to true if the context, locals, 
 *                         statements, or tag database was already updated
 *                         on the thread.
 * @param tagDatabase      (output) tag database being updated (can be empty string) 
 * @param waitTimeInMS     (input) time to wait for result to appear on queue 
 * @param deferSlowerJobs  (input) if 'true', defer slower jobs that 
 *                         that require foreground processing until later. 
 * 
 * @return 0 on success, &lt;0 on error 
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_async_tagging_result(_str &fileName, int &taggingFlags, 
                                        int &bufferId, int &lastModified,
                                        int &updateFinished,
                                        _str &tagDatabase,
                                        int waitTimeInMS=0,
                                        int deferSlowerJobs=0);

/**
 * Get the start and end seek position bounds for the last completed tagging job. 
 * This is only needed, in general, for local variable tagging. 
 * 
 * @param startSeekpos  (output) start seek position
 * @param endSeekpos    (output) end seek position
 * 
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_async_locals_bounds(int &startSeekpos, int &endSeekpos);
/**
 * Return the tag database to be updated, associated with last completed 
 * tagging job. 
 * 
 * @param tagDatabase   full path to tag database to open and update 
 * 
 * @return 0 on success, &lt;0 on error.
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_async_tag_database(_str &tagDatabase);

/**
 * Insert the tags which were gathered by the asynchronous parsing for this 
 * tagging job.  This applies to updating tag databse, the current context, 
 * or for updating local variables.  Note that because of embedded code 
 * sections, there may be more work still required after this method is 
 * complete if there are embedded code blocks which also require tagging 
 * work. 
 * 
 * @param fileName         Name of file to update tagging results for 
 * @param taggingFlags     tagging options flags (bitset of VSLTF_*)
 * @param bufferId         ID of editor buffer to update tagging for
 * 
 * @return 0 on success, &lt;0 on error 
 * 
 * @categories Tagging_Functions
 */
extern int tag_insert_async_tagging_result(_str fileName, int taggingFlags, int bufferId);

/**
 * Dispose of the last asynchronous tagging job which was completed.
 * 
 * @param fileName   Name of file to dispose of results for
 * @param bufferId   ID of editor buffer
 * 
 * @return 0 on success, &lt;0 on error
 * 
 * @categories Tagging_Functions
 */
extern int tag_dispose_async_tagging_result(_str fileName, int bufferId);

/**
 * Check if there is an asynchronous tagging operation already queued 
 * for the given file.  If there is a job running or queued then cancel 
 * the job if the file has been modified.
 * 
 * @categories Tagging_Functions
 */
extern int tag_get_async_tagging_job(_str fileName, 
                                     int taggingFlags,
                                     int bufferId, 
                                     _str fileDate, 
                                     int lastModify,
                                     _str tagDatabase = null,
                                     int startLine = 1,
                                     int startSeekPos = 0,
                                     int stopSeekPos = 0);

/**
 * Stop background tagging threads.
 * 
 * @categories Tagging_Functions
 */
extern void tag_stop_async_tagging();
/**
 * Restart background tagging threads.
 * 
 * @categories Tagging_Functions
 */
extern void tag_restart_async_tagging();

/**
 * Set a thread synchronization lock on the contents of the current context, 
 * that is, the symbols found in the current file. 
 * 
 * @categories Tagging_Functions
 */
extern int tag_lock_context(bool doWrite=false);
/**
 * Release the thread synchronization lock on the contents of the 
 * current context, that is, the symbols found in the current file. 
 * 
 * @categories Tagging_Functions
 */
extern int tag_unlock_context();

/**
 * Mark changes to the current context as complete. 
 *  
 * @param list_tags_flags (optional) statement level tagging option 
 * @return 0 on success, &lt;0 on error 
 *  
 * @see tag_check_cached_context 
 * @categories Tagging_Functions
 */
extern int tag_commit_cached_context(int list_tags_flags);
/**
 * Mark changes to the current set of local variables as complete.
 *  
 * @param start_seekpos    start seek position of function to search
 * @param end_seekpos      end seek position of function to search
 * @param context_id       context item to search for locals in
 * @param list_all_option  list all locals, or only in scope?
 * 
 * @return 0 on success, &lt;0 on error 
 *  
 * @see tag_check_cached_locals 
 * @categories Tagging_Functions
 */
extern int tag_commit_cached_locals(int start_seekpos, int end_seekpos,
                                    int context_id, int update_flags);

/**
 * Set a thread synchronization lock on the current set of matches.
 * 
 * @categories Tagging_Functions
 */
extern void tag_lock_matches(bool doWrite=false);
/**
 * Release the thread synchronization lock on the current set of matches.
 * 
 * @categories Tagging_Functions
 */
extern int tag_unlock_matches();


///////////////////////////////////////////////////////////////////////////
// language support query functions

/**
 * Check if there is a parsing callback registered for the given language, 
 * or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 * 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_list_tags(_str langId);

/**
 * @return 
 * Return 'true' if local variable tagging is supported for the given language. 
 * 
 * @param langId     language mode identifier
 * 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_list_locals(_str langId);

/**
 * @return 
 * Return 'true' if statement-level tagging is supported for the given language.
 * 
 * @param langId     language mode identifier
 * 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_list_statements(_str langId);

/**
 * @return 
 * Return 'true' if tokenization is supported for the given language. 
 * 
 * @param langId     language mode identifier
 * 
 * @see tag_lang_has_list_tags()
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_tokenlist_support(_str langId);

/**
 * @return 
 * Return 'true' if the given language's parser creates positional keywords tokens.
 * 
 * @param langId     language mode identifier
 * 
 * @see tag_lang_has_list_tags()
 * @see tag_lang_has_tokenlist_support() 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_positional_keywords_support(_str langId);

/**
 * @return 
 * Return 'true' if the given language's parser supports incremental tagging.
 * 
 * @param langId     language mode identifier
 * 
 * @see tag_lang_has_list_tags()
 * @see tag_lang_has_tokenlist_support() 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_incremental_support(_str langId);

/**
 * Check if there is an expression info callback registered for the 
 * given language, or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 *  
 * @see tag_lang_has_list_tags()
 * @see tag_lang_has_tokenlist_support() 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_get_id_expr_info(_str langId);

/**
 * Check if there is a find tags callback registered for the 
 * given language, or inherited by the given language. 
 * 
 * @param langId     language mode identifier
 *  
 * @see tag_lang_has_get_id_expr_info() 
 * @categories Tagging_Functions
 */
extern bool tag_lang_has_find_tags(_str langId);


///////////////////////////////////////////////////////////////////////////
// tag file build functions

enum_flags TagRebuildFlags {
   /**
    * Rebuild the tag file from scratch using the given file list. 
    * Otherwise, the tag file is rebuilt incrementally. 
    */
   VS_TAG_REBUILD_FROM_SCRATCH,
   /**
    * Check dates of files and only rebuild ones that are out of date, 
    * if false, all the files will be retagged.
    */
   VS_TAG_REBUILD_CHECK_DATES,
   /**
    * Build a symbol cross-reference.
    */
   VS_TAG_REBUILD_DO_REFS,
   /**
    * Retag the files in the foreground rather than queuing the 
    * files for the background tagging threads to finish. 
    */
   VS_TAG_REBUILD_SYNCHRONOUS,
   /**
    * Remove files from the database which no longer exist on disk.
    */
   VS_TAG_REBUILD_REMOVE_MISSING_FILES,
   /**
    * Remove leftover files that are no longer in the file list 
    * specified to be rebuilt. 
    */
   VS_TAG_REBUILD_REMOVE_LEFTOVER_FILES,
   /**
    * Skip files that are not already in the tag file.
    */
   VS_TAG_REBUILD_SKIP_MISSING_FILES,
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
 *                         Remove leftover files that are no longer in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions 
 * @since 16.0 
 */
extern int tag_build_tag_file(_str pszTagDatabase, int rebuildFlags);

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
 *                         Remove leftover files that are no longer in
 *                         the file list specified to be rebuilt. 
 *                         </ul>
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_build_workspace_tag_file(_str pszWorkspaceFile, _str pszTagDatabase, int rebuildFlags);


/** 
 * Retag all the files in the given project tag file. 
 * <p> 
 * This function will start a thread which will retrieve the file list 
 * from the given project and schedule all the files which need to be 
 * retagged to be retagged in the background.
 * <p> 
 * If the SYNCHRONOUS option is on, it will retrieve the file list in 
 * the foreground instead of doing that work in the background. 
 * 
 * @param pszWorkspaceFile name of workspace the project belongs to
 * @param pszProjectFile   name of project to get source file list from 
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
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 19.0 
 */
extern int tag_build_project_tag_file(_str pszWorkspaceFile, 
                                      _str pszProjectFile, 
                                      _str pszTagDatabase, 
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
 *                         Remove leftover files that are no longer in
 *                         the file list specified to be rebuilt. 
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param sourceFileArray  Array of files to retag 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_build_tag_file_from_array( _str pszTagDatabase, int rebuildFlags, _str (&sourceFileArray)[] );

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
 *                         Remove leftover files that are no longer in
 *                         the file list specified to be rebuilt. 
 *                         <li>VS_TAG_REBUILD_SKIP_MISSING_FILES --
 *                         Skip files that are not already in the tag file.
 *                         </ul>
 * @param sourceFileWid    Editor control containing a list of source files, one per line
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_build_tag_file_from_view( _str pszTagDatabase, int rebuildFlags, int sourceFileWid );

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
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_build_tag_file_from_list_file(_str pszTagDatabase,
                                             int rebuildFlags,
                                             _str pszFilename );
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
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_build_tag_file_from_wildcards(_str pszTagDatabase, int rebuildFlags,
                                             _str pszDirectoryPath, _str pszWildcardOpts);

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
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_remove_files_from_tag_file_in_array(_str pszTagDatabase, 
                                                   int rebuildFlags,
                                                   _str (&sourceFileArray)[] );

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
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_remove_files_from_tag_file_in_view(_str pszTagDatabase, 
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
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_remove_files_from_tag_file_in_list_file(_str pszTagDatabase, 
                                                       int rebuildFlags, 
                                                       _str pszFilename);

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
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_remove_files_from_tag_file_in_wildcards(_str pszTagDatabase,
                                                       int rebuildFlags, 
                                                       _str pszDirectoryPath, 
                                                       _str pszWildcardOpts);

/**
 * Copy all the data from an older version of the tag database to a newer version. 
 * The function will also adjust filenames to correspond to the directory which 
 * the new tag database is located in. 
 * 
 * @param pszOldTagDatabase     tag database to copy data from
 * @param pszNewTagDatabase     tag database to create
 * @param slickcProgressCallback   index of Slick-C function to call to report progress 
 * @param startPercent             start percentage of progress at (0-100) 
 * @param finalPercent             final percentage of progress at (0-100)
 * 
 * @return 0 on success, &lt;0 on error.
 *  
 * @categories Tagging_Functions
 * @since 20.0 
 */
extern int tag_update_tag_file_to_latest_version(_str pszOldTagDatabase,
                                                 _str pszNewTagDatabase,
                                                 int slickcProgressCallback=0,
                                                 int startPercent=0,
                                                 int finalPercent=100);

/**
 * Cancel a tag file build or rebuild that is currently running in the background.
 * 
 * @param pszTagDatabase   name of tag file to cancel build/rebuild for 
 * @param waitForMS        time in MS to wait for the thread to stop 
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_cancel_async_tag_file_build(_str pszTagDatabase, int waitForMS=0);

/**
 * Cancel all running background tag file builds or rebuilds.
 * 
 * @return 0 on success, &lt;0 on error. 
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_cancel_all_async_tag_file_builds();

/**
 * Get a list of all tag files currently being built or rebuilt 
 * in the background. 
 * 
 * @param tagDatabaseArray    [output] set to array of tag file names 
 * 
 * @return number of tag files returned on success, &lt;0 on error.
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_get_async_tag_file_builds( _str (&tagDatabaseArray)[] );

/**
 * Check the status of the given asynchronous tag file build or rebuild.
 * 
 * @param pszTagDatabase   name of tag file to check build progress for
 * @param isRunning        set to 'true' if the build is still running
 * @param percentProgress  set to the percentage 0-100 of progress for the build
 * 
 * @return 0 on success, &lt;0 on error
 *  
 * @categories Tagging_Functions
 * @since 16.0 
 */
extern int tag_check_async_tag_file_build(_str pszTagDatabase, 
                                          bool &isRunning, 
                                          int &percentProgress);

/** 
 * xmloutlineview_profiles are cached so the Defs tool window 
 * can be filled in faster. If one of this profiles is modified, 
 * this function must be called. 
 */
extern void tag_recache_xmloutlineview_profiles();

/**
 * Set the maximum number of current context, statements, local variables, 
 * and search result match sets to cache.
 * 
 * @param num_context_jobs    Maximum number of items to store in cache. 
 *  
 * @return 0 on success, &lt;0 on error.
 *  
 * @see def_context_tagging_max_cache 
 * @see tag_get_context_tagging_cache_size() 
 *  
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_set_context_tagging_cache_size(int num_context_jobs);
/** 
 * @return 
 * Return the maximum number of current context, statements, local variables, 
 * and search result match sets to cache.
 *  
 * @see def_context_tagging_max_cache 
 * @see tag_set_context_tagging_cache_size() 
 *  
 * @categories Tagging_Functions
 * @since 21.0 
 */
extern int tag_get_context_tagging_cache_size();

/**
 * Clear the context tagging class and package name resolution caches, 
 * and optionally reset the maximum number of items each one can cache. 
 * 
 * @param max_cache_size    (optional, ignored if 0) 
 *                          sets maximum number of items for cache
 *  
 * @see tag_qualify_symbol_name() 
 * @see tag_join_class_name() 
 * @see tag_check_for_class() 
 * @see tag_check_for_package() 
 * @see tag_is_parent_class() 
 * @see tag_normalize_classes() 
 *  
 * @categories Tagging_Functions
 * @since 24.0 
 */
extern void tag_clear_class_name_caches(int max_cache_size=0);

/** 
 * @return 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern int tag_search_result_context_start(int buffer_id);
/** 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern void tag_search_result_context_end(int buffer_id);
/** 
 * @return 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern int tag_search_result_context_find(int buffer_id, int linenum, int seekpos);
/** 
 * @return 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern int tag_search_result_context_get_info(int buffer_id, int context_id, int& context_type, int& context_line, _str& context_name);
/** 
 * @return 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern int tag_search_result_context_get_contexts(int buffer_id, int context_id, int (&context_ids)[]);
/** 
 *  
 * @categories Tagging_Functions
 * @since 23.0 
 */
extern void tag_search_result_context_set_types(int (&context_types)[]);

/**
 * @deprecated 
 * This command is no longer supported.  Use tag_dump_matches() instead. 
 */
extern void tag_dump_debug_info();

//////////////////////////////////////////////////////////////////////////////
// Built-in limits for symbol browser
//
const CB_MAX_REFERENCES=        0x400;     // 1024    -- max references to list
/**
 * 1048576 -- lines per file
 *
 * <p>This constant represents the highest line number that
 * can be encoded into the user information for an item in
 * the tree control.  See {@link tag_tree_set_user_info} for more
 * information.
 *
 * @see tag_tree_set_user_info
 * @see tag_tree_insert_fast
 * @see tag_tree_insert_tag
 */
const CB_MAX_LINE_NUMBER=       0x100000;
/**
 * 1048576 -- file ID
 *
 * <p>This constant represents the highest file name ID that
 * can be encoded into the user information for an item in
 * the tree control.  See {@link tag_tree_set_user_info} for more
 * information.
 *
 * @see tag_tree_set_user_info
 * @see tag_tree_insert_fast
 * @see tag_tree_insert_tag
 */
const CB_MAX_FILE_NUMBER=       0x100000;
const CB_MAX_INHERITANCE_DEPTH= 0x20;      // 32/CB   -- max depth of inheritance tree

const CB_LOW_WATER_MARK=         16000;    // max items to refresh
const CB_HIGH_WATER_MARK=        32000;    // max items to insert w/o prompting
const CB_FLOOD_WATER_MARK=      128000;    // max items to insert w/o prompting twice
const CB_NOAHS_WATER_MARK=      500000;    // max items to insert under a category


//////////////////////////////////////////////////////////////////////////////
struct AUTOTAG_BUILD_INFO {
   _str configName;
   _str langId;
   _str tagDatabase;
   _str directoryPath;
   _str wildcardOptions;
};


#endif
