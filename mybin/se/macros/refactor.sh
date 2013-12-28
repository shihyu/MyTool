////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47099 $
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
#ifndef REFACTOR_SH
#define REFACTOR_SH

#define ctlOriginalFile   _ctlfile1
#define ctlRefactoredFile _ctlfile2

///////////////////////////////////////////////////////////////////////////
// General DLL entry points
///////////////////////////////////////////////////////////////////////////
int def_refactor_option_flags = 0;
boolean gcanceled_finding_children = false;

struct DependencyInfo
{
   _str description;
   int  memberIndex;
   boolean isAGlobal;

   _str symbolName;
   _str typeName;
   _str defFilename;
   int defSeekPosition;

   // This dependency should also be a dependency
   // of the member at this index unless the index is -1.
   int crossDependencyMemberIndex;
};

struct MemberInfo
{
   _str memberName;
   _str typeName;
   _str fileName;
   int lineNo;

   _str memberType;
   _str description;

   int memberIndex;
   int treeIndex;

   boolean hidden;

   boolean explicitRefOutsideClass;

   DependencyInfo dependencies[];

   boolean files:[];

   int referred_to_in_class[];
}

struct ExtractClassMI
{
   int   m_nTreeIdx;
   int   m_tAccess;
   int   m_nMemberIdx;
   _str  m_sMember;
   _str  m_sSymbolName;
   _str  m_sTypeName;
   _str  m_sLocation;
   _str  m_sLineNumber;

   DependencyInfo m_dependencies[];
}

struct CompilerConfiguration
{
   _str configuarationName;
   _str systemHeader;
   _str systemIncludes[];
}

struct JavaCompilerConfiguration
{
   _str name;
   _str root;
   _str jars[];
}

// flags used in def_refactor_option_flags
#define REFACTOR_GO_TO_NEXT_FILE    0x0001   // go to next file after last diff
#define REFACTOR_GO_TO_PREV_FILE    0x0002   // go to prev file after first diff
#define REFACTOR_SYSTEM_INCLUDES    0x0004   // allow refactoring engine to do system includes

#define REFACTOR_PUSH_DOWN_CHECK    1
#define REFACTOR_PULL_UP_CHECK      2

/**
 * Display the version of the vsrefactor.dll
 *
 * @categories Refactoring_Functions
 */
extern void vsrefactor_version();
/**
 * Display the copyright notice for the vsrefactor.dll
 *
 * @categories Refactoring_Functions
 */
extern void vsrefactor_copyright();

/**
 * Initialize the refactoring library.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Refactoring_Functions
 */
extern int vsrefactor_initialize();

/**
 * Close all existing refactoring, and free all memory
 * and files associated with the refactoring library.
 *
 * @categories Refactoring_Functions
 */
extern void vsrefactor_finalize();


///////////////////////////////////////////////////////////////////////////
// Refactoring configuration file handling
///////////////////////////////////////////////////////////////////////////

/**
 * See if the config file exists and is open
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_save
 * @see refactor_config_close
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_is_open(_str xmlConfigFile);

/**
 * Open the master refactoring [compiler] configuration file,
 * either for reading or editing.  The configuration file is an
 * XML file conforming to vsrefactor.dtd.
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_save
 * @see refactor_config_close
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_open(_str xmlConfigFile);

/**
 * Save the master refactoring [compiler] configuration file.
 * An alternate configuration file path may be specified.
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_open
 * @see refactor_config_close
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_save(_str xmlConfigFile=null);

/**
 * Close the master refactoring [compiler] configuration file.
 * If there are modifications, they will be discarded, unless
 * you call {@link refactor_config_save} first.
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_open
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_close();

/**
 * Return the number of compiler configurations stored in the
 * master refactoring configuration file.
 *
 * @return number of configurations, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_delete
 * @see refactor_config_delete_all
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_count();

/**
 * Add a new C++ compiler configuration to the master 
 * refactoring configuration file. 
 *
 * @param configName    name for this configuration
 * @param configHeader  header file to configure the compiler
 * @param includePath   PATHSEP deliminated include file path
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_count
 * @see refactor_config_delete
 * @see refactor_config_delete_all
 * @see refactor_config_get_name
 * @see refactor_config_set_name
 * @see refactor_config_get_header
 * @see refactor_config_set_header
 * @see refactor_config_count_includes
 * @see refactor_config_get_include
 * @see refactor_config_add_include
 * @see refactor_config_delete_include
 * @see refactor_config_delete_all_includes
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_add(_str configName, _str configHeader, _str includePath);

/**
 * Add a new Java compiler configuration to the master 
 * refactoring configuration file. 
 *
 * @param configName    name for this configuration
 * @param sourcePath    path to root of the JDK 
 * @param jarPath       PATHSEP deliminated system JAR list 
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_count
 * @see refactor_config_delete
 * @see refactor_config_delete_all
 * @see refactor_config_get_name
 * @see refactor_config_set_name
 * @see refactor_config_get_jar
 * @see refactor_config_count_jars
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_add_java(_str configName, _str sourcePath, _str jarPath);

/**
 * Delete the named configuration
 *
 * @param configName
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_count
 * @see refactor_config_delete_all
 * @see refactor_config_add
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete(_str configName);


/**
 * Delete all configurations of type
 *
 * @see refactor_config_delete
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_all_type(_str type);

/**
 * Delete all configurations
 *
 * @see refactor_config_delete
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_all();

/**
 * Retrieve the name of the given configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    [reference] set to name of configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count
 * @see refactor_config_set_name
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_name(int configIndex, _str& configName);

/**
 * Retrieve the type of the given configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configType    [reference] set to type of configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_add_java
 * @see refactor_config_count
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_type(int configIndex, _str& configType);

/**
 * Retrieve the root directory of the given Java configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param src           [reference] set to root directory of 
 *                      Java configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 * @see refactor_config_count
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_java_source(_str name, _str& src);

/**
 * Rename the given configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    new name of configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count
 * @see refactor_config_get_name
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_set_name(int configIndex, _str configName);

/**
 * Retrieve the full path to the configuration header for the given configuration.
 *
 * @param configName    name of configuration to query
 * @param configHeader  [reference] set to full path to configuration header
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count
 * @see refactor_config_set_header
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_header(_str configName, _str& configHeader);

/**
 * Save the full path to the configuration header for the given configuration.
 *
 * @param configName    name of configuration to query
 * @param configHeader  new path to configuration header
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count
 * @see refactor_config_get_header
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_set_header(_str configName, _str configHeader);

/**
 * Return the number of include paths associated with the given configuration.
 *
 * @param configName    name of configuration to query
 *
 * @return number of include paths on success, <0 on error
 *
 * @see refactor_config_add
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_count_includes(_str configName);

/**
 * Return the number of system JARs associated with the given 
 * configuration. 
 *
 * @param configName    name of configuration to query
 *
 * @return number of JARs on success, <0 on error
 *
 * @see refactor_config_add_java
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_count_jars(_str configName);

/**
 * Get the full path to the specified include path
 *
 * @param configName    name of configuration to query
 * @param includeIndex  index within include path to query
 * @param includePath   set to include path
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_add_include
 * @see refactor_config_delete_include
 * @see refactor_config_delete_all_includes
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_include(_str configName, int includeIndex, _str& includePath);

/**
 * Get the full path to the specified system JAR 
 *
 * @param configName    name of configuration to query
 * @param jarIndex      index within system JAR list to query
 * @param jarPath       set to JAR path
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_get_jar(_str configName, int jarIndex, _str& jarPath);

/**
 * Add a path to the include path
 *
 * @param configName    name of configuration to modify
 * @param includePath   include path to add
 * @param includeIndex  where to insert path, -1 to insert at end of list
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_includes
 * @see refactor_config_delete_include
 * @see refactor_config_delete_all_includes
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_add_include(_str configName, _str includePath, int includeIndex=-1);

/**
 * Add a JAR to the system JAR list for the configuration 
 *
 * @param configName    name of configuration to modify
 * @param jarPath       path to JAR to add
 * @param jarIndex      where to insert JAR in list, -1 to 
 *                      insert at end
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 * @see refactor_config_count_jars
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_add_jar(_str configName, _str jarPath, int jarIndex=-1);

/**
 * Delete an include path from the given configuration.
 *
 * @param configName    name of configuration to modify
 * @param includePath   include path to remove
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_includes
 * @see refactor_config_add_include
 * @see refactor_config_delete_all_includes
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_include(_str configName, _str includePath);

/**
 * Delete a JAR from the given configuration.
 *
 * @param configName    name of configuration to modify
 * @param jarPath       path to JAR to remove
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_jar
 * @see refactor_config_count_jars
 * @see refactor_config_add_jar
 * @see refactor_config_delete_all_jars
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_jar(_str configName, _str jarPath);

/**
 * Delete all include paths from the given configuration.
 *
 * @param configName    name of configuration to modify
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_includes
 * @see refactor_config_add_include
 * @see refactor_config_delete_include
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_all_includes(_str configName);

/**
 * Delete all system JARS from the given configuration.
 *
 * @param configName    name of configuration to modify
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 * @see refactor_config_count_jars
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 *
 * @categories Refactoring_Functions
 */
extern int refactor_config_delete_all_jars(_str configName);


///////////////////////////////////////////////////////////////////////////
// Refactoring transaction operations
///////////////////////////////////////////////////////////////////////////

/**
 * Begin a refactoring transaction.
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_commit_transaction
 * @see refactor_cancel_transaction
 *
 * @categories Refactoring_Functions
 */
extern int refactor_begin_transaction();

/**
 * End a refactoring transaction.
 *
 * @param handle Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_begin_transaction
 * @see refactor_cancel_transaction
 *
 * @categories Refactoring_Functions
 */
extern int refactor_commit_transaction(int handle);

/**
 * Cancel a refactoring transaction.
 *
 * @param handle Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_begin_transaction
 * @see refactor_commit_transaction
 *
 * @categories Refactoring_Functions
 */
extern int refactor_cancel_transaction(int handle);

/**
 * Add a file to the refactoring transaction.
 *
 * @param handle              Handle to transaction
 * @param filename            Filename to add
 * @param userIncludePath     User include path for this file
 * @param systemIncludePath   System include path for this file
 * @param defineOptions       #defines and #undefs for this file
 * @param compilerConfig      Compiler configuration name
 *
 * @return 0 on succes, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_add_file(int handle, _str filename,
                      _str userIncludePath, _str systemIncludePath,
                      _str defineOptions, _str compilerConfig);

/**
 * Add a file to the refactoring transaction.
 *
 * @param handle              Handle to transaction
 * @param filename            Filename to add
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_remove_file(int handle, _str filename);

/**
 * Get the number of files that were modified
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_count_modified_files(int handle);

/**
 * Get the name of the modified file from the
 * refactoring transaction.
 *
 * @param handle    Handle to transaction
 * @param index     Index of file
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_get_modified_file_name(int handle, int index, _str& filename);

/**
 * Get the contents of the modified file from the
 * refactoring transaction and insert it into the given editor control.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_get_modified_file_contents(int wid, int handle, _str filename);

/**
 * Set the contents of the modified file from the given editor control
 * and store it back with the refactoring transaction.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_set_modified_file_contents(int wid, int handle, _str filename);


/**
 * Get the number of files that failed to parse
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 */
extern int refactor_count_error_files(int handle);

/**
 * Get the name of the file which failed to parse from the
 * refactoring transaction.
 *
 * @param handle    Handle to transaction
 * @param index     Index of file
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 *
 */
extern int refactor_get_error_file_name(int handle, int index, _str &filename);

/**
 * Get the number of errors that are in the
 * refactoring error log.  If 'filename' is not
 * specified, it will return the total for all files
 * with errors.
 *
 * @param handle      Handle to transaction
 * @param filename    Filename of file that failed to parse
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_count_errors(int handle, _str filename='');

/**
 * Get the specified error string from the
 * refactoring transaction.
 *
 * @param handle      Handle to transaction
 * @param filename    Filename of file that failed to parse
 * @param errorIndex  Index of error
 * @param errorString Error string
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_get_error(int handle, _str filename, int errorIndex, _str& errorString);

/**
 * Add a path to the end of the list for the given filename in a transaction.
 *
 * @param handle                Handle to transaction
 * @param filename              Filename being parsed
 * @param userIncludePath       Include path to add
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_add_user_include_directory(int handle, _str filename, _str userIncludePath);

extern int refactor_set_file_encoding(int handle, _str filename, _str encoding);
extern int refactor_get_file_encoding(int handle, _str filename, _str& encoding);

/**
 * Parse the files in the refactoring transaction
 *
 * @param handle       Handle to transaction
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_c_parse(int handle, int flags);

/**
 * Preprocess the files in the refactoring transaction
 *
 * @param handle           Handle to transaction
 * @param wid              Editor control to insert results into
 * @param addLineMarkers   Add #line markers
 *
 * @return 0 on success, <0 on error
 */
extern int refactor_c_preprocess(int handle, int wid, boolean addLineMarkers=true);


///////////////////////////////////////////////////////////////////////////
// Refactoring operations
///////////////////////////////////////////////////////////////////////////
#define VSREFACTOR_DEFTYPE_CONSTANT                            1
#define VSREFACTOR_DEFTYPE_STATIC                              2
#define VSREFACTOR_DEFTYPE_DEFINE                              3

#define VSREFACTOR_RENAME_DEFINE                               0x00000001
#define VSREFACTOR_RENAME_VIRTUAL_METHOD_IN_BASE_CLASSES       0x00000002
#define VSREFACTOR_RENAME_VIRTUAL_METHOD_IN_DERIVED_CLASSES    0x00000004
#define VSREFACTOR_RENAME_OVERLOADED_METHODS                   0x00000008

#define VSREFACTOR_ACCESS_PUBLIC                               0x00000100
#define VSREFACTOR_ACCESS_PROTECTED                            0x00000200
#define VSREFACTOR_ACCESS_PRIVATE                              0x00000400

#define VSREFACTOR_FORMAT_K_AND_R_STYLE_BRACES                 0x00000100 // style 1
#define VSREFACTOR_FORMAT_ALIGNED_STYLE_BRACES                 0x00000200 // style 2
#define VSREFACTOR_FORMAT_INDENTED_STYLE_BRACES                0x00000400 // style 3
#define VSREFACTOR_FORMAT_FUNCTION_BRACES_ON_NEW_LINE          0x00000800 // function option
#define VSREFACTOR_FORMAT_INDENT_FIRST_LEVEL_OF_CODE           0x00001000 // indent first level
#define VSREFACTOR_FORMAT_USE_CONTINUATION_INDENT              0x00002000 // use continuation indent
#define VSREFACTOR_FORMAT_INDENT_WITH_TABS                     0x00004000 // indent with tabs
#define VSREFACTOR_FORMAT_PAD_PARENS                           0x00008000 // pad around parens
#define VSREFACTOR_FORMAT_INSERT_SPACE_AFTER_COMMA             0x00010000 // space after comma

// Bits describing properties to create a method or describe a method
#define VSREFACTOR_METHOD_CREATE                              0x00000001 // create this method or this method exists.
#define VSREFACTOR_METHOD_VIRTUAL                             0x00000002 // make the method virtual or this method is.
#define VSREFACTOR_METHOD_PUBLIC                              0x00000004 // make the method public or this method is.
#define VSREFACTOR_METHOD_PROTECTED                           0x00000008 // make the method protected or this method is.
#define VSREFACTOR_METHOD_PRIVATE                             0x00000010 // make the method private or this method is.
#define VSREFACTOR_METHOD_REPLACEABLE                         0x00000020 // should this method be allowed to be replaced.
#define VSREFACTOR_METHOD_STATIC                              0x00000040 // make the method static or this method is.

// Standard method types
#define VSREFACTOR_FLAGS_MASK                                 63  // Mask out lowest six bits
#define VSREFACTOR_METHOD_DEFAULT_CONSTRUCTOR                 0   // bitshift to start of default constructor flags
#define VSREFACTOR_METHOD_COPY_CONSTRUCTOR                    6   // bitshift to start of default constructor flags
#define VSREFACTOR_METHOD_ASSIGNMENT_OPERATOR                 12  // bitshift to start of default constructor flags
#define VSREFACTOR_METHOD_DESTRUCTOR                          18  // bitshift to start of default constructor flags

#define VSREFACTOR_GET_METHOD_FLAGS( FLAGS, STANDARD_METHOD_TYPE ) ( ( FLAGS >> STANDARD_METHOD_TYPE ) & VSREFACTOR_FLAGS_MASK )
#define VSREFACTOR_ENABLE_METHOD_FLAG( FLAGS, STANDARD_METHOD_TYPE, SETTING ) ( FLAGS | ( SETTING << STANDARD_METHOD_TYPE ) )
#define VSREFACTOR_DISABLE_METHOD_FLAG( FLAGS, STANDARD_METHOD_TYPE, SETTING ) ( FLAGS & ~( SETTING << STANDARD_METHOD_TYPE ) )


/**
 * Add class browse info to transaction
 *
 * @param handle       Handle to transaction
 * @param className    Class name
 * @param filename     Filename to find symbol in
 * @param beginSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_add_class_info(int handle, _str className, _str filename, int beginSeekPos, int endSeekPos);

/**
 * Rename a symbol
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param beginSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param newName      New name for symbol
 * @param flags        Optional flags, bitset of VSREFACTOR_RENAME_* (above)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_rename(int handle, _str filename, _str symbolName,
                      int beginSeekPos, int endSeekPos, _str newName, int flags);

/**
 * Analyze what is necessary to do in order to extract the code between
 * 'beginSeekPos' and 'endSeekPos' into a separate function and replace
 * the code with a call to the mew function.
 * <p>
 * Each line of parameter inforomation is a string of the form:
 * <pre>
 *    name [tab] return_type [tab] reference [tab] required [newline]
 * </pre>
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to extract method from
 * @param createCall   [reference] Set to 1/0, if function call can be created
 * @param beginSeekPos Seek position to begin extraction at
 * @param endSeekPos   Seek position to end extraction at
 * @param returnType   [reference] Set to return type of extracted function
 * @param paramInfo    [reference] Set to list of parameters for new function
 * @param flags        Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_extract_method(int handle, _str filename,
                              _str symbolName, int &createCall,
                              int beginSeekPos, int endSeekPos,
                              _str &returnType, _str &paramInfo,
                              int flags, int syntaxIndent);

/**
 * Finish the extract method operation
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param newName               Name for new function
 * @param createMethodCall      should the refactoring replace the selected code with a method call?
 * @param paramInfo             List of parameters for new function
 * @param commentInfo           Comments to insert for the new function
 * @param flags                 Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent          Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_extract_method_finish(int handle, _str filename, _str newName, int createMethodCall,
                                     _str paramInfo, _str commentInfo, int flags, int syntaxIndent);

/**
 * Encapsulate a field. Make a field private and make public getter and setter functions.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to encapsulate
 * @param getterName       Name of getter function to create
 * @param setterName       Name of setter function to create
 * #param methodName       Name of method declaration to insert getter and setter after
 * @param beginSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 * @param formattingFlags  formatting flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent     Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_encapsulate(int handle, _str filename, _str symbolName, _str getterName, _str setterName,
                           _str methodName, int beginSeekPos, int endSeekPos, int formattingFlags, int syntaxIndent );

/**
 * Convert local variable to a field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of lvar to convert to field
 * @param beginSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param fieldName    New name for field
 * @param flags        Flags for access modifiers and make field static
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_local_to_field(int handle, _str filename, _str symbolName,
                              int beginSeekPos, int endSeekPos, _str fieldName, int flags);

/**
 * Convert global variable to a static field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of gvar to convert to static field
 * @param beginSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param fieldName    New name for field
 * @param flags        Flags for access modifiers
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_global_to_field(int handle, _str filename, _str symbolName,
                               int beginSeekPos, int endSeekPos, _str classFileName,
                               _str className, _str fieldName, int flags);

/**
 * Move a field. Move a static field from one class to another and fix all references.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to move
 * @param className        Name of class to move symbol to.
 * @param classFileName    Name of file that class declaration is in.
 * @param classDefFileName Name of file that class definition is in.
 * @param beginSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_move_field(int handle, _str filename, _str symbolName, _str className, _str classFileName, _str classDefFileName,
                           int beginSeekPos, int endSeekPos);

/**
 * Replace a literal with a constant
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param literalName  Name of literal to convert to a constant
 * @param constantName Name of constant
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_replace_literal(int handle, _str filename, _str literalName, _str constantName, int flags);

/**
 * Replace a static method with an instance method.
 *
 * @param nHandle          Handle to transaction
 * @param szMethodName     Name of static method to be converted to an instance method.
 * @param szClassName      Name of class the method is a member of.
 * @param szFilename       Filename to find the method in
 * @param nSeekPosition    Seek position of the method or position to start search
 * @param nFlags           Flags for access modifiers
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_static_to_instance_method(int nHandle, _str szMethodName, _str szClassName, _str szFileName, int nSeekPosition, int nFlags);

/**
 * Analyzes a symbol to determine it's class and determine which of the standard methods
 * are already implemented for that class.
 *
 * @param handle                 Handle to transaction
 * @param filename               Filename to find symbol in
 * @param symbolName             Name selected symbol
 * @param seekPos                Start seek position of symbol
 * @param seekPos                End seek position of symbol
 * @param className              Returns the name of the class that symbolName refers to
 * @param existingClassMethods   Returns flags indicating which methods are already implemented in the class. Uses
 *                               bitset of VSREFACTOR_METHOD_* (above)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_standard_methods(int handle, _str filename, _str symbolName, int startSeekPos, int endSeekPos,
                                _str &className, int &existingClassMethods );

/**
 * Finish the create standard methods
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param symbolName            Name of reference to class to add standard methods to
 * @param seekPosition          Start seek position of reference
 * @param seekPosition          End seek position of reference
 * @param methodsToCreate       Which methods to create, bitset of VSREFACTOR_METHOD_* (above)
 * @param formattingFlags       Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent          Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_standard_methods_finish(int handle, _str filename, _str symbolName, int startSeekPos, int endSeekPos,
                                       int methodsToCreate, int formattingFlags, int syntaxIndent);

/**
 * Find methods that are members of this symbol's class
 * The methods are stored internally and can be retrieved using refactor_c_get_num_class_methods() and
 * refactor_c_get_class_method()
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param symbolName            Name of reference to class
 * @param beginSeekPos          Begin Seek position of reference
 * @param endSeekPos            End Seek position of reference
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_find_class_methods( int handle, _str filename, _str symbolName, int beginSeekPos, int endSeekPos );

/**
 * Return number of class methods found by call to refactor_c_find_class_methods
 *
 * @param handle                Handle to transaction
 *
 * @return number of class methods, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_get_num_class_methods( int handle );

/**
 * Return signature of class i found by call to refactor_c_find_class_methods
 *
 * @param handle                 Handle to transaction
 * @param index                  Index into internal list of class methods found by refactor_c_find_class_methods
 * @param methodName             Signature of name of method
 *
 * @return number of class methods, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_get_class_method( int handle, int index, _str& methodName );

/**
 * Move a method. Move a method from one class to another and fix all references.
 *
 * @param nHandle          Handle to transaction
 * @param szSrcMethodName  Name of method to move
 * @param szSrcClassName   Name of class to move method from.
 * @param szDstMethodName  Name of destination method
 * @param szDstClassName   Name of class to move method to.
 * @param nFlags           Flags for access modifiers
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_move_method(int  nHandle,
                           _str szSrcMethodName,
                           _str szSrcClassName,
                           _str szDstMethodName,
                           _str szDstClassName,
                           int  nSrcIdx,
                           int  nDstIdx,
                           _str tag_files[],
                           int  nReceiver,
                           int  nFlags);
extern int refactor_c_move_method_find_delegates(int nHandle, _str szMethod, _str szClass);
extern int refactor_c_move_method_num_delegates(int nHandle);
extern int refactor_c_move_method_get_delegate(int nHandle, int nDelegate, _str& szDelegate, _str& szDelegateClass, int& nType, int& nAccess, int& nReferences);


/**
 *
 */
//int refactor_c_extract_class(int nHandle, _str szClass, _str szHFile, _str szCPPFile, int memberIdxs[]);
//int refactor_c_extract_class_generate_member_list(int nHandle, _str szClass);
//int refactor_c_extract_class_num_members(int nHandle);
//int refactor_c_extract_class_get_member(int nHandle, int nMemberIdx, _str& szMember);

/**
 * Get the parameter info for a function
 *
 * @param nHandle          Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param beginSeekPos     Seek position of beginning of function reference
 * @param endSeekPos       Seek position of end of function reference
 * @param paramInfo        String containing information about parameters
 *
 * paramInfo is in the form:
 *    number of parameters                                  [@]
 *    return_type of function
 *    [$]
 *    original parameter position( 0..numParameters-1)      [@]
 *    parameter type string                                 [@]
 *    parameter name string                                 [@]
 *    default value                                         [@]
 *    'has_refs' or 'no_refs'                               [@]
 *    'old' or 'new' (whether the parameter originally existed or was added through modify_params
 *    [$]
 *    next parameter's values ( see above )
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_modify_params_get_info(int handle, _str symbolName, _str filename, int beginSeekPos,
                                      int endSeekPos, _str& paramInfo);

/**
 * Perform modify parameters
 *
 * @param nHandle          Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param beginSeekPos     Seek position of beginning of function reference
 * @param endSeekPos       Seek position of end of function reference
 * @param oldParamInfo     Original parameter info
 * @param newParamInfo     String containing information about parameters
 *
 * paramInfo is in the form:
 *    number of parameters                                  [@]
 *    return_type of function
 *    [$]
 *    original parameter position( 0..numParameters-1)      [@]
 *    parameter type string                                 [@]
 *    parameter name string                                 [@]
 *    default value                                         [@]
 *    'has_refs' or 'no_refs'                               [@]
 *    'old' or 'new' (whether the parameter originally existed or was added through modify_params
 *    [$]
 *    next parameter's values ( see above )
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_modify_params(int handle, _str symbolName, _str filename, int beginSeekPos,
                                      int endSeekPos, _str oldParamInfo, _str newParamInfo);

/**
 * Get a list of the super classes that are associated with a given symbol's class
 *
 * @param handle        Handle to transaction
 * @param symbolName    Name of function
 * @param filename      Name of file containing function
 * @param beginSeekPos  Seek position of beginning of function reference
 * @param endSeekPos    Seek position of end of function reference
 * @param superClasses  String containing all super classes deliminated with @ and starts with number of classes.
 *
 * superClasses is in the form:
 *    number of classes [@]
 *    super_class_name [@] parent_class_name [@]
 *    super_class_name [@] parent_class_name [@]
 *    ...
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_get_super_classes(int handle, _str symbolName, _str filename,
                                     int beginSeekPos, int endSeekPos, _str& superClasses);

/**
 * Pull Up class member(s) to a super class
 *
 * @param handle                 Handle to transaction
 * @param className              Name of class
 * @param filename               Name of file containing class
 * @param beginSeekPos           Seek position of beginning of class reference
 * @param endSeekPos             Seek position of end of class reference
 * @param superClass             Name of superclass to move symbol to
 * @param membersToMove          Class members to move to super class
 * @param memberWorkingOn        (out)This is used for errors. This is the member being worked when error occurs.
 * @param superClassDefFilename  File to move function definiitions into.
 *
 * membersToMove is in the form:
 *    number of members [@]
 *    member [@]
 *    member [@]
 *    ...
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */

extern int refactor_c_pull_up(int handle, _str filename, _str className,
         int beginSeekPos, int endSeekPos, _str superClass, _str membersToMove,
                       _str& memberWorkingOn, _str superClassDefFilename);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle        Handle to transaction
 * @param className     Name of class
 * @param filename      Name of file containing class.
 * @param beginSeekPos  Seek position of beginning of class reference.
 * @param endSeekPos    Seek position of end of class reference.
 * @param destClassName Name of class to move to.
 * @param members       (out)String containing members of class along with dependency information.
 * @param dependencyFiles  Files that contain function body definitions.
 *
 * @return 0 on success, <0 on error
 *
 * members is in the form:
 *    number of members                   [@]
 *    memberIndex [@] memberDescription  [@] memberType [@]
 *       number of dependents [@]
 *       dependent index [@] isADependency(true or false) [@] dependentDescription [@]
 *       ...
 *    ...
 *
 *  dependent index will be -1 if it is a global dependency that cannot be moved.
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_pull_up_find_members(int handle, _str filename, _str className,
                                     int beginSeekPos, int endSeekPos, _str destClassName,
                                    _str& members, _str dependencyFiles);

/**
 * Push Down class member(s) to a derived class
 *
 * @param handle                 Handle to transaction
 * @param className              Name of class
 * @param filename               Name of file containing class
 * @param beginSeekPos           Seek position of beginning of class reference
 * @param endSeekPos             Seek position of end of class reference
 * @param derivedClass           Name of superclass to move symbol to
 * @param membersToMove          Class members to move to super class
 * @param memberWorkingOn        (out)This is used for errors. This is the member being worked when error occurs.
 * @param classDefInfoList       Classes and Files to move members to.
 *        Format: NumOfClasses @ className0 @ classFile0 @ classNameN @ classFileN @
 * @param origClassDefFiles      Files that contain the original class's function definitions and static initializers
 *        Format: NumOfFiles @ defFile0 @ defFileN @
 *
 * membersToMove is in the form:
 *    number of members [@]
 *    member [@]
 *    member [@]
 *    ...
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */

extern int refactor_c_push_down(int handle, _str filename, _str className,
         int beginSeekPos, int endSeekPos, _str derivedClass, _str membersToMove,
                       _str& memberWorkingOn, _str class_def_info_list, _str origClassDefFiles);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle        Handle to transaction
 * @param className     Name of class
 * @param filename      Name of file containing class.
 * @param beginSeekPos  Seek position of beginning of class reference.
 * @param endSeekPos    Seek position of end of class reference.
 * @param destClassName Name of class to move to.
 * @param members       (out)String containing members of class along with dependency information.
 * @param dependencyFiles  Files that contain function body definitions.
 *
 * @return 0 on success, <0 on error
 *
 * members is in the form:
 *    number of members                   [@]
 *    memberIndex [@] memberDescription  [@] memberType [@]
 *       number of dependents [@]
 *       dependent index [@] isADependency(true or false) [@] dependentDescription [@]
 *       ...
 *    ...
 *
 *  dependent index will be -1 if it is a global dependency that cannot be moved.
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_push_down_find_members(int handle, _str filename, _str className,
                                     int beginSeekPos, int endSeekPos, _str destClassName,
                                    _str& members, _str dependencyFiles);

/**
 * Find a symbol with className in the compilation unit created by filename.
 *
 * @param handle           Handle to transaction
 * @param className        Name of class
 * @param filename         Name of file containing class.
 * @param found            (out)boolean indicating whether a symbol of className was found in the compilation unit
 *                         created using filename.
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
extern int refactor_c_push_down_find_class_in_file(int handle, _str className, _str filename, boolean& found);

/*
   get parent class. go through filenames for all instances of that tag
   if any of the filenames contain the child class then
*/
extern _str tagGetClassFilename(typeless &tag_files, _str class_name, _str &inner_class, _str fileTypeExtension);


extern int tag_get_class_detail(_str class_name, int tag_detail, var result);

/*
   get information about the currently active compiler/refactor config.

   @param header_file      returns the current active confi's header file.
   @param includes         returns a list of include files in a string separated by path separators. PATHSEP
   @param project_handle   optional handle of project to look for active config in. -1 mean active project.

   @return 0 on success otherwise returns an error code.
*/
extern int refactor_get_active_config( _str &header_file, _str &includes, int project_handle=-1 );

extern int refactor_c_extract_class(int nHandle,_str szClass,_str szHFile,_str szCPPFile,int (&memberIdxs)[],boolean bExtractSuper);
extern int refactor_c_extract_class_generate_member_list(int nHandle,_str szClass,_str szClassFileName,int nBeginSeek,int nEndSeek,_str (&dependency_files)[]);
extern int refactor_c_extract_class_num_members(int nHandle);
extern int refactor_c_extract_class_get_member(int nHandle,int nMemberInfoIdx,int& nMemberIdx,_str& szMember,_str& szSymbol,_str& szTypeName,_str& szLocation,_str& szLineNumber,int& nAccess);
extern int refactor_c_extract_class_num_dependencies(int nHandle, int nMemberInfoIdx);
extern int refactor_c_extract_class_get_dependency(int nHandle, int nMemberInfoIdx, int nDependencyIdx, int& nMemberIdx, _str& szName, _str& szDescription, _str& szTypeName, boolean& bIsAGlobal);

extern boolean refactor_c_is_valid_id( _str id_name );
// simplified version of select_text from surround_with
extern void get_limited_selection(int &start_pos,int &end_pos);
extern void vsRefactorOutput(_str szText);

#endif
