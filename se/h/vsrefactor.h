////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#pragma once

#include "vsdecl.h"
#include <string.h>


///////////////////////////////////////////////////////////////////////////
// General DLL entry points
///////////////////////////////////////////////////////////////////////////

/**
 * Display the version of the vsrefactor.dll
 */
EXTERN_C void VSAPI vsrefactor_version();
/**
 * Display the copyright notice for the vsrefactor.dll
 */
EXTERN_C void VSAPI vsrefactor_copyright();

/**
 * Initialize the refactoring library.
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C int VSAPI vsrefactor_initialize();

/**
 * Initialize the refactoring library.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorInitialize();

/**
 * Close all existing refactoring, and free all memory
 * and files associated with the refactoring library.
 */
EXTERN_C void VSAPI vsrefactor_finalize();

/**
 * Close all existing refactoring, and free all memory
 * and files associated with the refactoring library.
 *
 * @categories Refactoring_Functions
 */
EXTERN_C void VSAPI vsRefactorFinalize();


///////////////////////////////////////////////////////////////////////////
// Messaging and progress feedback callbacks
///////////////////////////////////////////////////////////////////////////

/**
 * Post a progress message about the current file being parsed.
 *
 * @param filename   name of file being parsed
 * @param i          (optional) index of file being parsed (1 is first)
 * @param n          (optional) number of files to process
 *
 * @return 0 on success, <0 on cancellation.
 */
extern int vsRefactorFileMessage(const char *filename, 
                                 size_t i VSDEFAULT(1), 
                                 size_t n VSDEFAULT(1));

/**
 * Post a progress message while parsing or doing a refactoring operation.
 *
 * @param message    Message to display.
 * @param isFilename Is 'message' a file name?
 *
 * @return 0 on success, <0 on cancellation.
 *
 * @categories Refactoring_Functions
 */
extern int vsRefactorMessage(const char *message, 
                             bool isFilename VSDEFAULT(false));

/**
 * Update the caller on our progress when doing a refactoring operation.
 * If the progress callback returns < 0, it must indicate a cancellation.
 *
 * @param progress   Progress factor between 0 .. maximum
 * @param maximum    Number that progress is computed relative to
 *
 * @return 0 on success, <0 on cancellation.
 *
 * @categories Refactoring_Functions
 */
extern int vsRefactorProgress(size_t progress, size_t maximum);

/**
 * Attempt to locate a header file by searching project files
 * also prompting the user to select a file, and allowing them
 * to add the include path to the end of their user include path
 * for this project.
 *
 * @param handle        Handle to transaction
 * @param fileName      File being parsed
 * @param headerName    Path used in #include directive
 * @param foundFile     [reference] set to absolute path of file that was located
 * @param foundFileMax  sizeof(foundFIle)
 *
 * @return 0 on success, <0 on error or cancellation.
 */
extern int vsRefactorLocateFile(int handle, 
                                const char *fileName,
                                const char *headerName,
                                char *foundFile, int foundFileMax);

/**
 * Prompt user if they want to continue or not after a parsing failure.
 * If the failure was COMMAND_CANCELLED_RC, do not prompt, just pass through.
 *
 * @param handle     Refactoring transaction handle
 * @param filename   Name of file which errors were found in
 * @param status     pass-thru status (if callback not found)
 *
 * @return <ul>
 *         <li>COMMAND_CANCELLED_RC if 'status' is COMMAND_CANCELLED_RC
 *         <li>COMMAND_CANCELLED_RC if they say 'no'
 *         <li>status if we can not find the callback
 *         <li>0 if 'yes'
 *         <li>1 if 'yestoall'
 *         </ul>
 */
EXTERN_C int VSAPI vsRefactorPromptToSkip(int handle, 
                                          const char *filename, 
                                          int status);

/**
 * Prompt user if they want to continue or not after a parsing failure.
 * Show the errors in the specified refactoring transaction
 * in the output toolbar
 *
 * @param handle     Refactoring transaction handle
 * @param filename   show refactoring errors for the given file
 *
 * @return the number of errors reported
 */
EXTERN_C int VSAPI vsRefactorShowErrors(int handle, const char *filename);


///////////////////////////////////////////////////////////////////////////
// VSAPI hook functions
//

/**
 * Insert the given text into an editor control.
 *
 * @param wid     Window ID
 * @param text    text to insert
 *
 * @return 0 on success, <0 on error
 *
 * @see vsInsertText
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorInsertText(int wid, const char *text, int textLen);

/**
 * Get the entire source file text from the given editor control.
 *
 * @param wid        Window ID
 * @param text       text to insert
 * @param textLen    number of bytes allocated to 'text'
 *
 * @return number of bytes copied on success,
 *         if text is NULL, return the number of bytes required.
 *         If text is not NULL, but textLen is less than the buffer size,
 *         return INSUFFICIENT_MEMORY_RC.
 *
 * @see vsInsertText
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorGetRText(int wid, char *text, int textLen);

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
 */
EXTERN_C int VSAPI refactor_config_is_open(VSPSZ xmlConfigFile);

/**
 * See if the config file exists and is open
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigSave
 * @see vsRefactorConfigClose
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigIsOpen(VSPSZ xmlConfigFile);


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
 *
 */
EXTERN_C int VSAPI refactor_config_open(VSPSZ xmlConfigFile);

/**
 * Open the master refactoring [compiler] configuration file,
 * either for reading or editing.  The configuration file is an
 * XML file conforming to vsrefactor.dtd.
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigSave
 * @see vsRefactorConfigClose
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigOpen(const char *xmlConfigFile);

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
 */
EXTERN_C int VSAPI refactor_config_save(VSPSZ xmlConfigFile VSDEFAULT(nullptr));

/**
 * Save the master refactoring [compiler] configuration file.
 * An alternate configuration file path may be specified.
 *
 * @param xmlConfigFile    Fully qualified path to XML configuration file
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigOpen
 * @see vsRefactorConfigClose
 *
 * @categories Refactoring_Functions
 *
 */
EXTERN_C int VSAPI vsRefactorConfigSave(const char *xmlConfigFile VSDEFAULT(nullptr));

/**
 * Close the master refactoring [compiler] configuration file.
 * If there are modifications, they will be discarded, unless
 * you call {@link refactor_config_save} first.
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_open
 *
 */
EXTERN_C int VSAPI refactor_config_close();

/**
 * Close the master refactoring [compiler] configuration file.
 * If there are modifications, they will be discarded, unless
 * you call {@link vsRefactorConfigSave} first.
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigOpen
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigClose();

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
 */
EXTERN_C int VSAPI refactor_config_count();

/**
 * Return the number of compiler configurations stored in the
 * master refactoring configuration file.
 *
 * @return number of configurations, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigDelete
 * @see vsRefactorConfigDeleteAll
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigCount();

/**
 * Add a new compiler configuration to the master refactoring
 * configuration file.
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
 */
EXTERN_C int VSAPI refactor_config_add(VSPSZ configName,
                                       VSPSZ configHeader,
                                       VSPSZ includePath);

/**
 * Add a new java compiler configuration to the master refactoring
 * configuration file.
 *
 * @param configName    name for this configuration
 * @param sourcePath    root dir for this configuration 
 * @param jarPath       PATHSEP deliminated list of the system jars
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_count
 * @see refactor_config_delete
 * @see refactor_config_delete_all
 * @see refactor_config_get_name
 * @see refactor_config_set_name
 * @see refactor_config_count_jars
 * @see refactor_config_get_jar
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 */
EXTERN_C int VSAPI refactor_config_add_java(VSPSZ configName,
                                            VSPSZ sourcePath,
                                            VSPSZ jarPath);

/**
 * Add a new C/C++ compiler configuration to the master refactoring
 * configuration file.
 *
 * @param configName    name for this configuration
 * @param configHeader  header file to configure the compiler
 * @param includePath   PATHSEP deliminated include file path
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigDelete
 * @see vsRefactorConfigDeleteAll
 * @see vsRefactorConfigGetName
 * @see vsRefactorConfigSetName
 * @see vsRefactorConfigGetHeader
 * @see vsRefactorConfigSetHeader
 * @see vsRefactorConfigCountIncludes
 * @see vsRefactorConfigGetInclude
 * @see vsRefactorConfigAddInclude
 * @see vsRefactorConfigDeleteInclude
 * @see vsRefactorConfigDeleteAllIncludes
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigAdd(const char *configName, 
                                       const char *configHeader, 
                                       const char *includePath);

/**
 * Add a new java compiler configuration to the master refactoring
 * configuration file.
 *
 * @param configName    name for this configuration
 * @param sourcePath    root dir for this configuration 
 * @param jarPath       PATHSEP deliminated list of the system jars
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigGetName
 * @see vsRefactorConfigSetName
 * @see vsRefactorConfigCountJARS
 * @see vsRefactorConfigGetJAR
 * @see vsRefactorConfigAddJAR
 * @see vsRefactorConfigDeleteJAR
 * @see vsRefactorConfigDeleteAllJARs
 *  
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigJavaAdd(const char *configName, 
                                           const char *sourcePath, 
                                           const char *jarPath);

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
 */
EXTERN_C int VSAPI refactor_config_delete(VSPSZ configName);

/**
 * Delete the named configuration
 *
 * @param configName
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigDeleteAll
 * @see vsRefactorConfigAdd
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDelete(const char *configName);

/**
 * Delete all configurations of specified type
 *
 * @see refactor_config_delete
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_config_delete_all_type(VSPSZ type);

/**
 * Delete all configurations of specified type
 *
 * @see vsRefactorConfigDelete
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteAllType(const char *type);

/**
 * Delete all configurations
 *
 * @see refactor_config_delete
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_config_delete_all();

/**
 * Delete all configurations
 *
 * @see vsRefactorConfigDelete
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteAll();

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
 */
EXTERN_C int VSAPI refactor_config_get_name(int configIndex, VSHREFVAR configName);

/**
 * Retrieve the type of the given configuration. Currently will return "c" for C/C++ and "java"
 * for Java.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    [reference] set to name of configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count
 * @see refactor_config_set_type
 *
 */
EXTERN_C int VSAPI refactor_config_get_type(int configIndex, VSHREFVAR configType);

/**
 * Retrieve the name of the given configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    [reference] set to name of configuration
 * @param maxLength     length of the configName buffer
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigSetName
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigGetName(int configIndex, 
                                           char *configName, int maxLength);

/**
 * Retrieve the type of the given configuration. Currently will return "c" for C/C++ and
 * "java" for Java.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    [reference] set to name of configuration
 * @param maxLength     length of the configName buffer
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCount
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigGetType(int configIndex, 
                                           char *configType, int maxLength);

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
 */
EXTERN_C int VSAPI refactor_config_set_name(int configIndex, VSPSZ configName);

/**
 * Rename the given configuration.
 *
 * @param configIndex   index of configuration to query name of [0..n-1]
 * @param configName    new name of configuration
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigGetName
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigSetName(int configIndex, const char *configName);

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
 */
EXTERN_C int VSAPI refactor_config_get_header(VSPSZ configName, VSHREFVAR configHeader);

/**
 * Retrieve the full path to the configuration header for the given configuration.
 *
 * @param configName    name of configuration to query
 * @param configHeader  [reference] set to full path to configuration header
 * @param maxLength     length of configHeader buffer
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigSetHeader
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigGetHeader(const char *configName,
                                             char *configHeader, int maxLength);

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
 */
EXTERN_C int VSAPI refactor_config_set_header(VSPSZ configName, VSPSZ configHeader);

/**
 * Save the full path to the configuration header for the given configuration.
 *
 * @param configName    name of configuration to query
 * @param configHeader  new path to configuration header
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCount
 * @see vsRefactorConfigGetHeader
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigSetHeader(const char *configName, 
                                             const char *configHeader);

/**
 * Return the number of include paths associated with the given configuration.
 *
 * @param configName    name of configuration to query
 *
 * @return number of include paths on success, <0 on error
 *
 * @see refactor_config_add
 *
 */
EXTERN_C int VSAPI refactor_config_count_includes(VSPSZ configName);

/**
 * Return the number of system jars associated with the given configuration.
 *
 * @param configName    name of configuration to query
 *
 * @return number of system jars on success, <0 on error
 *
 * @see refactor_config_add_java
 *
 */
EXTERN_C int VSAPI refactor_config_count_jars(VSPSZ configName);

/**
 * Return the number of include paths associated with the given configuration.
 *
 * @param configName    name of configuration to query
 *
 * @return number of includes on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigCountIncludes(const char *configName);

/**
 * Return the number of system jars associated with the given configuration.
 *
 * @param configName    name of configuration to query
 *
 * @return number of jars on success, <0 on error
 *
 * @see vsRefactorConfigJavaAdd
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigCountJARs(const char *configName);

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
 */
EXTERN_C int VSAPI refactor_config_get_include(VSPSZ configName,
                                               int includeIndex, 
                                               VSHREFVAR includePath);

/**
 * Get the full path to the specified system jar 
 *
 * @param configName    name of configuration to query
 * @param jarIndex      index within include path to query
 * @param jarPath       set to include path
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 */
EXTERN_C int VSAPI refactor_config_get_jar(VSPSZ configName, 
                                           int jarIndex, 
                                           VSHREFVAR jarPath);

/**
 * Get the full path to the specified include path
 *
 * @param configName    name of configuration to query
 * @param includeIndex  index within include path to query
 * @param includePath   set to include path
 * @param maxLength     length of includePath buffer
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigAddInclude
 * @see vsRefactorConfigDeleteInclude
 * @see vsRefactorConfigDeleteAllIncludes
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigGetInclude(const char *configName, 
                                              int includeIndex, 
                                              char *includePath, int maxLength);

/**
 * Get the full path to the specified system jar 
 *
 * @param configName    name of configuration to query
 * @param jarIndex      index within include path to query
 * @param jarPath       set to jar path
 * @param maxLength     length of includePath buffer
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigAddJAR
 * @see vsRefactorConfigDeleteJAR
 * @see vsRefactorConfigDeleteAllJARs
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigGetJAR(const char *configName, 
                                          int jarIndex, 
                                          char *jarPath, int maxLength);

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
 */
EXTERN_C int VSAPI refactor_config_add_include(VSPSZ configName, 
                                               VSPSZ includePath, 
                                               int includeIndex VSDEFAULT(-1));

/**
 * Add a jar to the system jars for a configuration
 *
 * @param configName    name of configuration to modify
 * @param jarPath       jar to add
 * @param jarIndex      where to insert jar, -1 to insert at end of list
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_jars
 * @see refactor_config_delete_jar
 * @see refactor_config_delete_all_jars
 *
 */
EXTERN_C int VSAPI refactor_config_add_jar(VSPSZ configName, 
                                           VSPSZ jarPath, 
                                           int jarIndex VSDEFAULT(-1));

/**
 * Retrieve the full path to the configuration root.
 *
 * @param configName    name of configuration to query
 * @param src           (Output) path to configuration root 
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add_java
 *
 */
EXTERN_C int VSAPI refactor_config_get_java_source(VSPSZ configName, VSHREFVAR src);

/**
 * Add a path to the include path
 *
 * @param configName    name of configuration to modify
 * @param includePath   include path to add
 * @param includeIndex  where to insert path, -1 to insert at end of list
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCountIncludes
 * @see vsRefactorConfigDeleteInclude
 * @see vsRefactorConfigDeleteAllIncludes
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigAddInclude(const char *configName, 
                                              const char *includePath, 
                                              int includeIndex VSDEFAULT(-1));

/**
 * Add a jar to the system jars for a configuration
 *
 * @param configName    name of configuration to modify
 * @param jarPath       jar to add
 * @param jarIndex      where to insert jar, -1 to insert at end of list
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigJavaAdd
 * @see vsRefactorConfigCountJARs
 * @see vsRefactorConfigDeleteJAR
 * @see vsRefactorConfigDeleteAllJARs
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigAddJAR(const char *configName, 
                                          const char *jarPath, 
                                          int jarIndex VSDEFAULT(-1));

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
 */
EXTERN_C int VSAPI refactor_config_delete_include(VSPSZ configName, VSPSZ includePath);

/**
 * Delete a jar from the given configuration.
 *
 * @param configName    name of configuration to modify
 * @param jarPath       path to jar to remove
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_jars
 * @see refactor_config_add_jar
 * @see refactor_config_delete_all_jars
 *
 */
EXTERN_C int VSAPI refactor_config_delete_jar(VSPSZ configName, VSPSZ jarPath);

/**
 * Delete an include path from the given configuration.
 *
 * @param configName    name of configuration to modify
 * @param includePath   include path to remove
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCountIncludes
 * @see vsRefactorConfigAddInclude
 * @see vsRefactorConfigDeleteAllIncludes
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteInclude(const char *configName, 
                                                 const char *includePath);

/**
 * Delete a jar from the given configuration.
 *
 * @param configName    name of configuration to modify
 * @param jarPath       path to jar to remove
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigJavaAdd
 * @see vsRefactorConfigCountJARs
 * @see vsRefactorConfigAddJAR
 * @see vsRefactorConfigDeleteAllJARs
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteJAR(const char *configName, 
                                             const char *jarPath);

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
 */
EXTERN_C int VSAPI refactor_config_delete_all_includes(VSPSZ configName);

/**
 * Delete all system jars from the given configuration.
 *
 * @param configName    name of configuration to modify
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_config_add
 * @see refactor_config_count_jars
 * @see refactor_config_add_jar
 * @see refactor_config_delete_jar
 *
 */
EXTERN_C int VSAPI refactor_config_delete_all_jars(VSPSZ configName);

/**
 * Delete all include paths from the given configuration.
 *
 * @param configName    name of configuration to modify
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigAdd
 * @see vsRefactorConfigCountIncludes
 * @see vsRefactorConfigAddInclude
 * @see vsRefactorConfigDeleteInclude
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteAllIncludes(const char *configName);

/**
 * Delete all system jars from the given configuration.
 *
 * @param configName    name of configuration to modify
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorConfigJavaAdd
 * @see vsRefactorConfigCountJARs
 * @see vsRefactorConfigAddJAR
 * @see vsRefactorConfigDeleteJAR
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorConfigDeleteAllJARs(const char *configName);


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
 */
EXTERN_C int VSAPI refactor_begin_transaction();

/**
 * Begin a refactoring transaction.
 *
 * @return Handle to transaction on success (>= 0), <0 on error
 *
 * @see vsRefactorCommitTransaction
 * @see vsRefactorCancelTransaction
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorBeginTransaction();

/**
 * Commit a refactoring transaction.
 *
 * @param handle Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @see refactor_begin_transaction
 * @see refactor_cancel_transaction
 *
 */
EXTERN_C int VSAPI refactor_commit_transaction(int handle);

/**
 * Commit a refactoring transaction.
 *
 * @param handle Handle to transaction
 *
 * @see vsRefactorBeginTransaction
 * @see vsRefactorCancelTransaction
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCommitTransaction(int handle);

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
 */
EXTERN_C int VSAPI refactor_cancel_transaction(int handle);

/**
 * Cancel a refactoring transaction.
 *
 * @param handle Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @see vsRefactorBeginTransaction
 * @see vsRefactorCommitTransaction
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCancelTransaction(int handle);

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
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_add_file(int handle, 
                                     VSPSZ filename,
                                     VSPSZ userIncludePath, 
                                     VSPSZ systemIncludePath,
                                     VSPSZ defineOptions, 
                                     VSPSZ compilerConfig);


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
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorAddFile(int handle, 
                                     const char *filename,
                                     const char *userIncludePath, 
                                     const char *systemIncludePath,
                                     const char *defineOptions, 
                                     const char *compilerConfig);

EXTERN_C int VSAPI refactor_set_file_encoding(int handle, 
                                              VSPSZ filename, 
                                              VSPSZ encoding);

EXTERN_C int VSAPI refactor_get_file_encoding(int handle, 
                                              VSPSZ filename, 
                                              VSHREFVAR encoding);

/**
 * Add a file to the refactoring transaction.
 *
 * @param handle              Handle to transaction
 * @param filename            Filename to add
 *
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_remove_file(int handle, VSPSZ filename);

/**
 * Remove a file to the refactoring transaction.
 *
 * @param handle              Handle to transaction
 * @param filename            Filename to add
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorRemoveFile(int handle, const char *filename);

/**
 * Get the number of files that were modified
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_count_modified_files(int handle);

/**
 * Get the number of files that were modified
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCountModifiedFiles(int handle);

/**
 * Get the name of the modified file from the
 * refactoring transaction.
 *
 * @param handle    Handle to transaction
 * @param index     Index of file
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_get_modified_file_name(int handle, int index, 
                                                   VSHREFVAR filename);

/**
 * Get the name of the modified file from the
 * refactoring transaction.
 *
 * @param handle    Handle to transaction
 * @param index     Index of file
 * @param filename  Filename of file that was modified
 * @param maxLength Maximum filename length
 *
 * @return Length of error string on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorGetModifiedFileName(int handle, int index,
                                                 char *filename, int maxLength);

/**
 * Get the contents of the modified file from the
 * refactoring transaction and insert it into the given editor control.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_get_modified_file_contents(int wid, int handle, 
                                                       VSPSZ filename);

/**
 * Get the contents of the modified file from the
 * refactoring transaction and insert it into the given editor control.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return Length of error string on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorGetModifiedFileContents(int wid, int handle, 
                                                     const char *filename);

/**
 * Set the contents of the modified file from the given editor control
 * and store it back with the refactoring transaction.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_set_modified_file_contents(int wid, int handle, 
                                                       VSPSZ filename);

/**
 * Set the contents of the modified file from the given editor control
 * and store it back with the refactoring transaction.
 *
 * @param wid       Editor control window ID
 * @param handle    Handle to transaction
 * @param filename  Filename of file that was modified
 *
 * @return Length of error string on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorSetModifiedFileContents(int wid, int handle, 
                                                     const char *filename);

/**
 * Get the number of files that failed to parse
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_count_error_files(int handle);

/**
 * Get the number of files that were filed to parse
 * in the refactoring transaction.
 *
 * @param handle   Handle to transaction
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCountErrorFiles(int handle);

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
EXTERN_C int VSAPI refactor_get_error_file_name(int handle, int index, 
                                                VSHREFVAR filename);

/**
 * Get the name of the file while failed to parse from the
 * refactoring transaction.
 *
 * @param handle    Handle to transaction
 * @param index     Index of file
 * @param filename  Filename of file that was modified
 * @param maxLength Maximum filename length
 *
 * @return Length of error string on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorGetErrorFileName(int handle, int index,
                                              char *filename, int maxLength);

/**
 * Get the number of errors that are in the
 * refactoring error log.
 *
 * @param handle      Handle to transaction
 * @param filename    Filename of file that failed to parse
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_count_errors(int handle, VSPSZ filename);

/**
 * Get the number of errors that are in the
 * refactoring error log.
 *
 * @param handle      Handle to transaction
 * @param filename    Filename of file that failed to parse
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCountErrors(int handle, 
                                         const char *filename VSDEFAULT(nullptr));

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
 *
 */
EXTERN_C int VSAPI refactor_get_error(int handle, 
                                      VSPSZ filename, 
                                      int errorIndex, 
                                      VSHREFVAR errorString);

/**
 * Get the specified error string from the
 * refactoring transaction.
 *
 * @param handle      Handle to transaction
 * @param filename    Filename of file that failed to parse
 * @param errorIndex  Index of error
 * @param errorString Error string
 * @param maxLength   Maximum error string length
 *
 * @return Length of error string on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorGetError(int handle,
                                      const char *filename, 
                                      int errorIndex,
                                      char *errorString, int maxLength);

/**
 * Add a path to the end of the list for the given filename in a transaction.
 *
 * @param handle                Handle to transaction
 * @param filename              Filename being parsed
 * @param userIncludePath       Include path to add
 *
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_add_user_include_directory(int handle, 
                                                       VSPSZ filename, 
                                                       VSPSZ userIncludePath);

/**
 * Add a path to the end of the list for the given filename in a transaction.
 *
 * @param handle                Handle to transaction
 * @param filename              Filename being parsed
 * @param userIncludePath       Include path to add
 *
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI vsRefactorAddUserIncludeDirectory(int handle, 
                                                     const char *filename, 
                                                     const char *userIncludePath);

/**
 * Parse the files in the refactoring transaction
 *
 * @param handle       Handle to transaction
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_parse(int handle, int flags);

/**
 * Parse the files in the refactoring transaction
 *
 * @param handle       Handle to transaction
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCParse(int handle, int flags);

/**
 * Preprocess the files in the refactoring transaction
 *
 * @param handle           Handle to transaction
 * @param wid              Window to insert results into
 * @param addLineMarkers   Add #line markers
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_preprocess(int handle, int wid, 
                                         int addLineMarkers=1);

/**
 * Parse the files in the refactoring transaction
 *
 * @param handle           Handle to transaction
 * @param wid              Window to insert results into
 * @param addLineMarkers   Add #line markers
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCPreprocess(int handle, int wid, 
                                         int addLineMarkers=1);

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

#define VSREFACTOR_FORMAT_K_AND_R_STYLE_BRACES                0x00000100 // style 1
#define VSREFACTOR_FORMAT_ALIGNED_STYLE_BRACES                0x00000200 // style 2
#define VSREFACTOR_FORMAT_INDENTED_STYLE_BRACES               0x00000400 // style 3
#define VSREFACTOR_FORMAT_FUNCTION_BRACES_ON_NEW_LINE         0x00000800 // function option
#define VSREFACTOR_FORMAT_INDENT_FIRST_LEVEL_OF_CODE          0x00001000 // indent first level
#define VSREFACTOR_FORMAT_USE_CONTINUATION_INDENT             0x00002000 // use continuation indent
#define VSREFACTOR_FORMAT_INDENT_WITH_TABS                    0x00004000 // indent with tabs
#define VSREFACTOR_FORMAT_PAD_PARENS                          0x00008000 // pad around parens
#define VSREFACTOR_FORMAT_INSERT_SPACE_AFTER_COMMA            0x00010000 // space after comma

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

#define VSREFACTOR_ACCESS_PUBLIC                               0x00000100
#define VSREFACTOR_ACCESS_PROTECTED                            0x00000200
#define VSREFACTOR_ACCESS_PRIVATE                              0x00000400


/**
 * Add class browse info to transaction
 *
 * @param handle       Handle to transaction
 * @param className    Class name
 * @param filename     Filename to find symbol in
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_c_add_class_info( int handle, 
                                              VSPSZ className, 
                                              VSPSZ filename, 
                                              seSeekPosParam startSeekPos, 
                                              seSeekPosParam endSeekPos );

/**
 * Add class browse info to transaction
 *
 * @param handle       Handle to transaction
 * @param className    Class name
 * @param filename     Filename to find symbol in
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCAddClassInfo( int handle, 
                                            const char *className, 
                                            const char *filename,
                                            seSeekPos startSeekPos, 
                                            seSeekPos endSeekPos );

/**
 * Rename a symbol
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param newName      New name for symbol
 * @param flags        Optional flags, bitset of VSREFACTOR_RENAME_* (above)
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_rename(int handle,
                                     VSPSZ filename,
                                     VSPSZ symbolName,
                                     seSeekPosParam startSeekPos,
                                     seSeekPosParam endSeekPos,
                                     VSPSZ newName,
                                     int flags);

/**
 * Rename a symbol
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param newName      New name for symbol
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCRename(int handle, 
                                     const char *filename, 
                                     const char *symbolPath,
                                     seSeekPos startSeekPos, 
                                     seSeekPos endSeekPos,
                                     const char *newName, 
                                     int flags);

/**
 * Analyze what is necessary to do in order to extract the code between
 * 'startSeekPos' and 'endSeekPos' into a separate function and replace
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
 * @param startSeekPos Seek position to begin extraction at
 * @param endSeekPos   Seek position to end extraction at
 * @param returnType   [reference] Set to return type of extracted function
 * @param paramInfo    [reference] Set to list of parameters for new function
 * @param flags        Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_extract_method(int handle, 
                                             VSPSZ filename,
                                             VSPSZ symbolName, 
                                             VSHREFINT createCall,
                                             seSeekPosParam startSeekPos, 
                                             seSeekPosParam endSeekPos,
                                             VSHREFSTR returnType, 
                                             VSHREFSTR paramInfo,
                                             int flags, 
                                             int syntaxIndent);

/**
 * Analyze what is necessary to do in order to extract the code between
 * 'startSeekPos' and 'endSeekPos' into a separate function and replace
 * the code with a call to the mew function.
 * <p>
 * Each line of parameter inforomation is a string of the form:
 * <pre>
 *    name [tab] return_type [tab] reference [tab] required [newline]
 * </pre>
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to find symbol in
 * @param symbolName            Name of symbol to extract method from
 * @param createMethodCall      [output] < 0 if there is a problem creating a function call, 0 otherwise
 * @param startSeekPos          Seek position to begin extraction at
 * @param endSeekPos            Seek position to end extraction at
 * @param returnType            [output] set to return type of function
 * @param returnTypeMaxLength   number of bytes allocated to returnType
 * @param paramInfo             [output] set to list of function parameters
 * @param paramInfoMaxLength    number of bytes allocated to paramInfo
 * @param flags                 Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent          Syntax indent amount
 *
 * @return 0 on success, <0 on error.
 *         If paramInfoLen is not long enough, this method will return
 *         INSUFFICIENT_MEMORY_RC, you should allocate at least 4K to paramInfoLen.
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCExtractMethod(int handle, 
                                            const char *filename,
                                            const char *symbolName, 
                                            int &createMethodCall,
                                            seSeekPos startSeekPos, 
                                            seSeekPos endSeekPos,
                                            char *returnType, int returnTypeMaxLength,
                                            char *paramInfo, int paramInfoMaxLength,
                                            int flags, 
                                            int syntaxIndent);

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
 */
EXTERN_C int VSAPI refactor_c_extract_method_finish(int handle, 
                                                    VSPSZ filename,
                                                    VSPSZ newName, 
                                                    int createMethodCall,
                                                    VSPSZ paramInfo, 
                                                    VSPSZ commentInfo,
                                                    int flags, 
                                                    int syntaxIndent);

/**
 * Finish the extract method operation
 *
 * @param handle       Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param newName      Name for new function
 * @param createMethodCall      should the refactoring replace the selected code with a method call?
 * @param paramInfo    List of parameters for new function
 * @param commentInfo  Comments to insert for the new function
 * @param flags        Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsCRefactorCExtractMethodFinish(int handle, 
                                                   const char *filename,
                                                   const char *newName, 
                                                   int createMethodCall,
                                                   const char *paramInfo, 
                                                   const char *commentInfo,
                                                   int flags, int syntaxIndent);

/**
 * Encapsulate a field. Make a field private and make public getter and setter functions.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to encapsulate
 * @param getterName       Name of getter function to create
 * @param setterName       Name of setter function to create
 * @param startSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 * @param formattingFlags  Flags for how generated code should be formatted
 * @param syntaxIndent     Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_encapsulate(int handle, 
                                          VSPSZ filename, 
                                          VSPSZ symbolName, 
                                          VSPSZ getterName, 
                                          VSPSZ setterName,
                                          VSPSZ methodName,
                                          seSeekPosParam startSeekPos, 
                                          seSeekPosParam endSeekPos, 
                                          int formattingFlags, 
                                          int syntaxIndent );

/**
 * Encapsulate a field. Make a field private and make public getter and setter functions.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to encapsulate
 * @param getterName       Name of getter function to create
 * @param setterName       Name of setter function to create
 * @param startSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 * @param formattingFlags  Flags for how generated code should be formatted
 * @param syntaxIndent     Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCEncapsulate(int handle, 
                                          const char *filename, 
                                          const char *symbolName, 
                                          const char *getterName,
                                          const char *setterName, 
                                          const char *methodName, 
                                          seSeekPos startSeekPos,
                                          seSeekPos endSeekPos, 
                                          int formattingFlags, 
                                          int syntaxIndent );

/**
 * Convert local variable to a field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param szFieldName  Name of field
 * @param flags        Flags for access modifiers and make field static
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCLocalToField(int    handle,
                                           VSPSZ  filename,
                                           VSPSZ  symbolName,
                                           seSeekPos startSeekPos,
                                           seSeekPos endSeekPos,
                                           VSPSZ  szFieldName,
                                           int    flags);

/**
 * Convert local variable to a field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param szFieldName  Name of field
 * @param flags        Flags for access modifiers and make field static
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_local_to_field(int    handle,
                                             VSPSZ  filename,
                                             VSPSZ  symbolName,
                                             seSeekPosParam startSeekPos,
                                             seSeekPosParam endSeekPos,
                                             VSPSZ  szFieldName,
                                             int    flags);

/**
 * Convert global variable to a field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param szFieldName  Name of field
 * @param flags        Flags for access modifiers and make field static
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCGlobalToField(int    handle,
                                            VSPSZ  filename,
                                            VSPSZ  symbolName,
                                            seSeekPos startSeekPos,
                                            seSeekPos endSeekPos,
                                            VSPSZ  szClassFileName,
                                            VSPSZ  szClassName,
                                            VSPSZ  szFieldName,
                                            int    flags);

/**
 * Convert global variable to a field
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param symbolName   Name of symbol to rename
 * @param startSeekPos Seek position of symbol or position to start search
 * @param endSeekPos   Seek position to end symbol search (0 if begin is actual symbol)
 * @param szFieldName  Name of field
 * @param flags        Flags for access modifiers and make field static
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_global_to_field(int    handle,
                                              VSPSZ  filename,
                                              VSPSZ  symbolName,
                                              seSeekPosParam startSeekPos,
                                              seSeekPosParam endSeekPos,
                                              VSPSZ  szClassFileName,
                                              VSPSZ  szClassName,
                                              VSPSZ  szFieldName,
                                              int    flags);

/**
 * Move a field. Move a static field from one class to another and fix all references.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to move
 * @param className        Name of class to move symbol to.
 * @param classFileName    Name of file that the class is declared in.
 * @param classDefFileName Name of file that the class is defined in.
 * @param startSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_move_field(int handle, 
                                         VSPSZ filename, 
                                         VSPSZ symbolName, 
                                         VSPSZ className, 
                                         VSPSZ classFileName, 
                                         VSPSZ classDefFileName,
                                         seSeekPosParam startSeekPos, 
                                         seSeekPosParam endSeekPos);

/**
 * Move a field. Move a static field from one class to another and fix all references.
 *
 * @param handle           Handle to transaction
 * @param filename         Filename to find symbol in
 * @param symbolName       Name of symbol to move
 * @param className        Name of class to move symbol to.
 * @param classFileName    File that contains the class declaration to move symbol to.
 * @param classDefFileName File that contains the class definition to move symbol to.
 * @param startSeekPos     Seek position of symbol or position to start search
 * @param endSeekPos       Seek position to end symbol search (0 if begin is actual symbol)
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCMoveField(int handle, 
                                        const char *filename, 
                                        const char *symbolName, 
                                        const char *className,
                                        const char *classFileName, 
                                        const char *classDefFileName, 
                                        seSeekPos startSeekPos, 
                                        seSeekPos endSeekPos);

/**
 * Replace a literal with a constant
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param literalName  Name of literal to convert to a constant
 * @param constantName Name of constant variable
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_replace_literal(int handle, 
                                              VSPSZ filename, 
                                              VSPSZ literalName, 
                                              VSPSZ constantName, 
                                              int flags);

/**
 * Replace a literal with a constant
 *
 * @param handle       Handle to transaction
 * @param filename     Filename to find symbol in
 * @param literalName  Name of literal to convert to a constant
 * @param constantName Name of constant variable
 * @param flags        Optional flags
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCReplaceLiteral(int handle, 
                                             const char *filename, 
                                             const char *literalName,
                                             const char *constantName, 
                                             int flags);


EXTERN_C int VSAPI refactor_c_static_to_instance_method(int    nHandle,
                                                        VSPSZ  szMethodName,
                                                        VSPSZ  szClassName,
                                                        VSPSZ  szFileName,
                                                        seSeekPosParam nSeekPosition,
                                                        int    nFlags);

EXTERN_C int VSAPI vsRefactorCStaticToInstanceMethod(int    nHandle,
                                                     VSPSZ  szMethodName,
                                                     VSPSZ  szClassName,
                                                     VSPSZ  szFileName,
                                                     seSeekPos nSeekPosition,
                                                     int    nFlags);

/**
 * Move a method. Move a method from one class to another and fix all references.
 *
 * @param nHandle          Handle to transaction
 * @param szSrcMethodName  Name of method to move
 * @param szSrcClassName   Name of class to move method from.
 * @param szDstMethodName  Name of destination method
 * @param nReceiver        The index of the delegate chosen.
 * @param nFlags           Flags for access modifiers
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_move_method(int         nHandle,
                                          VSPSZ       szSrcMethodName,
                                          VSPSZ       szSrcClassName,
                                          VSPSZ       szDstMethodName,
                                          VSPSZ       szDstClassName,
                                          int         nSrcIdx,
                                          int         nDstIdx,
                                          VSHREFVAR   fileList,
                                          int         nReceiver,
                                          int         nFlags);

/**
 * Move a method. Move a method from one class to another and fix all references.
 *
 * @param nHandle          Handle to transaction
 * @param szSrcMethodName  Name of method to move
 * @param szSrcClassName   Name of class to move method from.
 * @param szDstMethodName  Name of destination method
 * @param nReceiver        The index of the delegate chosen.
 * @param nFlags           Flags for access modifiers
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCMoveMethod(int          nHandle,
                                         VSPSZ        szSrcMethodName,
                                         VSPSZ        szSrcClassName,
                                         VSPSZ        szDstMethodName,
                                         VSPSZ        szDstClassName,
                                         int          nSrcIdx,
                                         int          nDstIdx,
                                         char**       files,
                                         int          nFiles,
                                         int          nReceiver,
                                         int          nFlags);

EXTERN_C int VSAPI refactor_c_move_method_find_delegates(int nHandle, 
                                                         VSPSZ szMethod, 
                                                         VSPSZ szClass);

EXTERN_C int VSAPI refactor_c_move_method_num_delegates(int nHandle);

EXTERN_C int VSAPI refactor_c_move_method_get_delegate(int nHandle,
                                                       int nDelegate,
                                                       VSHREFVAR szDelegate,
                                                       VSHREFVAR szDelegateClass,
                                                       VSHREFVAR nType,
                                                       VSHREFVAR nAccess,
                                                       VSHREFVAR nReferences);

/**
* Analyzes a symbol to determine it's class and determine which of the standard methods
* are already implemented for that class.
*
* @param handle                 Handle to transaction
* @param filename               Filename to find symbol in
* @param symbolName             Name selected symbol
* @param startSeekPos           Start seek position of symbol
* @param endSeekPos             End seek position of symbol
* @param className              Returns the name of the class that symbolName refers to
* @param existingClassMethods   Returns flags indicating which methods are already implemented in the class. Uses
*                               bitset of VSREFACTOR_METHOD_* (above)
*
* @return 0 on success, <0 on error
*
* @categories Refactoring_Functions
*/
EXTERN_C int VSAPI vsRefactorCStandardMethods(int handle, 
                                              const char *filename, 
                                              const char *symbolName,
                                              seSeekPos startSeekPos, 
                                              seSeekPos endSeekPos, 
                                              char** className, 
                                              int &existingClassMethods );

/**
 * Analyzes a symbol to determine it's class and determine which of the standard methods
 * are already implemented for that class.
 *
 * @param handle                 Handle to transaction
 * @param filename               Filename to find symbol in
 * @param symbolName             Name selected symbol
 * @param startSeekPos           Start seek position of symbol
 * @param endSeekPos             End seek position of symbol
 * @param className              Returns the name of the class that symbolName refers to
 * @param existingClassMethods   Returns flags indicating which methods are already implemented in the class. Uses
 *                               bitset of VSREFACTOR_METHOD_* (above)
 *
 * @return 0 on success, <0 on error
 *
 */

EXTERN_C int VSAPI refactor_c_standard_methods(int handle, 
                                               VSPSZ filename, 
                                               VSPSZ symbolName,
                                               seSeekPosParam startSeekPos, 
                                               seSeekPosParam endSeekPos, 
                                               VSHREFSTR className, 
                                               VSHREFINT existingClassMethods );

/**
 * Finish the create standard methods
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param className             Name of class to add standard methods to
 * @param startSeekPos          Start seek position of symbol
 * @param endSeekPos            End seek position of symbol
 * @param methodsToCreate       Which methods to create, bitset of VSREFACTOR_METHOD_* (above)
 * @param formattingFlags       Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent          Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCStandardMethodsFinish(int handle, 
                                                    const char *filename, 
                                                    const char *symbolName,
                                                    seSeekPos startSeekPos, 
                                                    seSeekPos endSeekPos, 
                                                    int methodsToCreate, 
                                                    int formattingFlags, 
                                                    int syntaxIndent);

/**
 * Finish the create standard methods
 *
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param className             Name of class to add standard methods to
 * @param methodsToCreate       Which methods to create, bitset of VSREFACTOR_METHOD_* (above)
 * @param formattingFlags       Optional flags, bitset of VSREFACTOR_FORMAT_* (above)
 * @param syntaxIndent          Syntax indent amount
 *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_standard_methods_finish(int handle, 
                                                      VSPSZ filename, 
                                                      VSPSZ symbolName,
                                                      seSeekPosParam startSeekPos, 
                                                      seSeekPosParam endSeekPos, 
                                                      int methodsToCreate, 
                                                      int formattingFlags, 
                                                      int syntaxIndent);

/**
 * Find the class methods in the given file.
 * 
 * @param handle                Handle to transaction
 * @param filename              Filename to do refactoring within
 * @param symbolName            symbol name to look for
 * @param startSeekPos          Start seek position of symbol
 * @param endSeekPos            End seek position of symbol
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_c_find_class_methods( int handle, 
                                                  VSPSZ filename, 
                                                  VSPSZ symbolName, 
                                                  seSeekPosParam startSeekPos, 
                                                  seSeekPosParam endSeekPos );
/**
 * Return the number of class methods in the refactoring operation.
 * 
 * @param handle                Handle to transaction
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_c_get_num_class_methods( int handle );

/**
 * Return the name of the n'th class method in the refactoring operation.
 * 
 * @param handle                Handle to transaction
 * @param index                 index of class method
 * @param methodName            [output] set to method name
 * 
 * @return 0 on success, <0 on error
 */
EXTERN_C int VSAPI refactor_c_get_class_method( int handle, 
                                                int index, 
                                                VSHREFVAR methodName );

/**
 * Get the parameter info for a function
 *
 * @param handle          Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param startSeekPos     Seek position of beginning of function reference
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
 *    next parameter's values ( see above ) *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCModifyParamsGetInfo(int handle, 
                                                  const char *symbolName,
                                                  const char *filename, 
                                                  seSeekPos startSeekPos, 
                                                  seSeekPos endSeekPos,
                                                  char *paramInfo);

/**
 * Get the parameter info for a function
 *
 * @param handle           Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param startSeekPos     Seek position of beginning of function reference
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
 *    next parameter's values ( see above ) *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_modify_params_get_info(int handle, 
                                                     VSPSZ symbolName,
                                                     VSPSZ filename, 
                                                     seSeekPosParam startSeekPos, 
                                                     seSeekPosParam endSeekPos,
                                                     VSHREFVAR paramInfo);

/**
 * Perform the modify parameters
 *
 * @param handle          Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param startSeekPos     Seek position of beginning of function reference
 * @param endSeekPos       Seek position of end of function reference
 * @param oldParamInfo     Original parameter info
 * @param newParamInfo     What the user wants to change the parameters too.
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
 *    next parameter's values ( see above ) *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCModifyParams(int handle, 
                                           const char *symbolName,
                                           const char *filename, 
                                           seSeekPosParam startSeekPos, 
                                           seSeekPosParam endSeekPos,
                                           const char *oldParamInfo, 
                                           const char *newParamInfo);

/**
 * Get the parameter info for a function
 *
 * @param handle           Handle to transaction
 * @param symbolName       Name of function
 * @param filename         Name of file containing function
 * @param startSeekPos     Seek position of beginning of function reference
 * @param endSeekPos       Seek position of end of function reference
 * @param oldParamInfo     Original parameters
 * @param newParamInfo     What the user wants to change the parameters too.
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
 *    next parameter's values ( see above ) *
 * @return 0 on success, <0 on error
 *
 */
EXTERN_C int VSAPI refactor_c_modify_params(int handle,
                                            VSPSZ symbolName,
                                            VSPSZ filename,
                                            seSeekPosParam startSeekPos,
                                            seSeekPosParam endSeekPos,
                                            VSPSZ oldParamInfo,
                                            VSPSZ newParamInfo);

/**
 * Get a list of the super classes that are associated with a given symbol's class
 *
 * @param handle        Handle to transaction
 * @param symbolName    Name of function
 * @param filename      Name of file containing function
 * @param startSeekPos  Seek position of beginning of function reference
 * @param endSeekPos    Seek position of end of function reference
 * @param superClasses  String containing all super classes deliminated with @ and starts with number of classes.
 * 
 * superClasses is in the form:
 *    number of classes [@]
 *    super_class_name [@] parent_class_name [@]
 *    super_class_name [@] parent_class_name [@] *    
 *    ...
 *
 * @return 0 on success, <0 on error
 *
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCGetSuperClasses(int handle,
                                              const char *symbolName,
                                              const char *filename,
                                              seSeekPos startSeekPos,
                                              seSeekPos endSeekPos, 
                                              char *superClassInfo);

/**
 * Get a list of the super classes that are associated with a given symbol's class
 *
 * @param handle        Handle to transaction
 * @param className     Name of class
 * @param filename      Name of file containing class
 * @param startSeekPos  Seek position of beginning of class reference
 * @param endSeekPos    Seek position of end of class reference
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
 */
EXTERN_C int VSAPI refactor_c_get_super_classes(int handle, 
                                                VSPSZ className, 
                                                VSPSZ filename,
                                                seSeekPosParam startSeekPos, 
                                                seSeekPosParam endSeekPos, 
                                                VSHREFVAR superClasses);
/**
 * Pull Up class member(s) to a super class
 *
 * @param handle                 Handle to transaction
 * @param className              Name of class
 * @param filename               Name of file containing class
 * @param startSeekPos           Seek position of beginning of class reference
 * @param endSeekPos             Seek position of end of class reference
 * @param superClass             Name of superclass to move symbol to
 * @param membersToMove          Members of class to move to superclass
 * @param memberWorkingOn        (out)This is used for errors. This is the member being worked when error occurs 
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
EXTERN_C int VSAPI vsRefactorCPullUp(int handle, 
                                     const char *filename, 
                                     const char *className,
                                     seSeekPos startSeekPos, 
                                     seSeekPos endSeekPos, 
                                     const char *superClass, 
                                     const char *membersToMove, 
                                     char *memberWorkingOn, 
                                     const char *superClassDefFilename);

/**
 * Pull Up class member(s) to a super class
 *
 * @param handle                 Handle to transaction
 * @param className              Name of class
 * @param filename               Name of file containing class
 * @param startSeekPos           Seek position of beginning of class reference
 * @param endSeekPos             Seek position of end of class reference
 * @param superClass             Name of superclass to move symbol to
 * @param membersToMove          Members of class to move to superclass
 * @param memberWorkingOn        (out)This is used for errors. This is the member being worked when error occurs
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
 */
EXTERN_C int VSAPI refactor_c_pull_up(int handle,
                                      VSPSZ filename,
                                      VSPSZ className,
                                      seSeekPosParam startSeekPos,
                                      seSeekPosParam endSeekPos, VSPSZ superClass, 
                                      VSPSZ membersToMove,
                                      VSHREFVAR memberWorkingOn,
                                      VSPSZ superClassDefFilename);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle        Handle to transaction
 * @param className     Name of class
 * @param filename      Name of file containing class.
 * @param startSeekPos  Seek position of beginning of class reference.
 * @param endSeekPos    Seek position of end of class reference.
 * @param destClassName Name of class to move members to.
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
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCPullUpFindMembers(int handle, 
                                                const char *filename, 
                                                const char *symbolName,
                                                seSeekPos startSeekPos,
                                                seSeekPos endSeekPos,
                                                const char *destClassName, 
                                                char *members, 
                                                const char *dependencyFiles);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle           Handle to transaction
 * @param className        Name of class
 * @param filename         Name of file containing class.
 * @param startSeekPos     Seek position of beginning of class reference.
 * @param endSeekPos       Seek position of end of class reference.
 * @param destClassName    Name of class to move members to.
 * @param members          (out)String containing members of class along with dependency information.
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
 */
EXTERN_C int VSAPI refactor_c_pull_up_find_members(int handle,
                                                   VSPSZ filename,
                                                   VSPSZ className,
                                                   seSeekPosParam startSeekPos,
                                                   seSeekPosParam endSeekPos,
                                                   VSPSZ destClassName, 
                                                   VSHREFVAR members,
                                                   VSPSZ dependencyFiles);

/**
 * Push Down class member(s) to a derived class
 *
 * @param handle                    Handle to transaction
 * @param className                 Name of class
 * @param filename                  Name of file containing class
 * @param startSeekPos              Seek position of beginning of class reference
 * @param endSeekPos                Seek position of end of class reference
 * @param derivedClass              Name of derivedclass to move symbol to
 * @param membersToMove             Members of class to move to superclass
 * @param memberWorkingOn           (out)This is used for errors. This is the member being worked when error occurs 
 * @param classDefInfoList          Classesand Files to move members to. 
 *        Format: NumOfClasses @ className0 @ classFile0 @ classNameN @ classFileN @
 * @param origClassDefFiles         
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
EXTERN_C int VSAPI vsRefactorCPushDown(int handle, 
                                       const char *filename, 
                                       const char *className,
                                       seSeekPos startSeekPos, 
                                       seSeekPos endSeekPos, 
                                       const char *derivedClass, 
                                       const char *membersToMove, 
                                       char *memberWorkingOn, 
                                       const char *classDefInfoList, 
                                       const char *origClassDefFiles);

/**
 * Push down class member(s) to a derived class
 *
 * @param handle                    Handle to transaction
 * @param className                 Name of class
 * @param filename                  Name of file containing class
 * @param startSeekPos              Seek position of beginning of class reference
 * @param endSeekPos                Seek position of end of class reference
 * @param derivedClass              Name of derived class to move symbol to
 * @param membersToMove             Members of class to move to derived class
 * @param memberWorkingOn           (out)This is used for errors. This is the member being worked when error occurs
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
 */
EXTERN_C int VSAPI refactor_c_push_down(int handle,
                                        VSPSZ filename,
                                        VSPSZ className,
                                        seSeekPosParam startSeekPos, 
                                        seSeekPosParam endSeekPos, 
                                        VSPSZ derivedClass, 
                                        VSPSZ membersToMove, 
                                        VSHREFVAR memberWorkingOn,
                                        VSPSZ classDefInfoList, 
                                        VSPSZ origClassDefFiles);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle           Handle to transaction
 * @param className        Name of class
 * @param filename         Name of file containing class.
 * @param startSeekPos     Seek position of beginning of class reference.
 * @param endSeekPos       Seek position of end of class reference.
 * @param destClassName    Name of class to move members to.
 * @param members          (out)String containing members of class along with dependency information.
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
 * @categories Refactoring_Functions
 */
EXTERN_C int VSAPI vsRefactorCPushDownFindMembers(int handle, 
                                                  const char *filename, 
                                                  const char *symbolName,
                                                  seSeekPos startSeekPos, 
                                                  seSeekPos endSeekPos,
                                                  const char *destClassName, 
                                                  char *members, 
                                                  const char *dependencyFiles);

/**
 * Find the members of the given class and check for dependencies.
 *
 * @param handle           Handle to transaction
 * @param className        Name of class
 * @param filename         Name of file containing class.
 * @param startSeekPos     Seek position of beginning of class reference.
 * @param endSeekPos       Seek position of end of class reference.
 * @param destClassName    Name of class to move members to.
 * @param members          (out)String containing members of class along with dependency information.
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
 */
EXTERN_C int VSAPI refactor_c_push_down_find_members(int handle, 
                                                     VSPSZ filename, 
                                                     VSPSZ className,
                                                     seSeekPosParam startSeekPos, 
                                                     seSeekPosParam endSeekPos, 
                                                     VSPSZ destClassName, 
                                                     VSHREFVAR members, 
                                                     VSPSZ dependencyFiles);

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
EXTERN_C int VSAPI vsRefactorCPushDownFindClassInFile(int handle,
                                                      const char *className, 
                                                      const char *filename, 
                                                      int &foundClass);

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
 */
EXTERN_C int VSAPI refactor_c_push_down_find_class_in_file(int handle,
                                                           VSPSZ className,
                                                           VSPSZ filename,
                                                           VSHREFVAR found);

EXTERN_C int VSAPI refactor_c_extract_class(int nHandle, 
                                            VSPSZ szClass, 
                                            VSPSZ szHFile, 
                                            VSPSZ szCPPFile, 
                                            VSHREFVAR memberIdxs, 
                                            VSHREFVAR bExtractSuper);

EXTERN_C int VSAPI refactor_c_extract_class_generate_member_list(int nHandle, 
                                                                 VSPSZ szClass, 
                                                                 VSPSZ szClassFileName, 
                                                                 int nBeginSeek, 
                                                                 int nEndSeek,
                                                                 VSHREFVAR depFileNames);

EXTERN_C int VSAPI refactor_c_extract_class_num_members(int nHandle);

EXTERN_C int VSAPI refactor_c_extract_class_get_member(int nHandle,
                                                       int nMemberInfoIdx,
                                                       VSHREFVAR nMemberIdx,
                                                       VSHREFVAR szMember,
                                                       VSHREFVAR szSymbol,
                                                       VSHREFVAR szTypeName,
                                                       VSHREFVAR szLocation,
                                                       VSHREFVAR szLineNumber,
                                                       VSHREFVAR nAccess);

EXTERN_C int VSAPI refactor_c_extract_class_num_dependencies(int nHandle, int nMemberInfoIdx);

EXTERN_C int VSAPI refactor_c_extract_class_get_dependency(int       nHandle,
                                                           int       nMemberInfoIdx,
                                                           int       nDependencyIdx,
                                                           VSHREFVAR nMemberIdx,
                                                           VSHREFVAR szName,
                                                           VSHREFVAR szDescription,
                                                           VSHREFVAR szType,
                                                           VSHREFVAR bIsAGlobal);


/** 
 * Utility Functions for SlickEdit Tools
 */ 
EXTERN_C void VSAPI vsRefactorSetOutputCB(void (VSAPI *callback)(const char*));
EXTERN_C void VSAPI vsRefactorOutput(const char *szText);



