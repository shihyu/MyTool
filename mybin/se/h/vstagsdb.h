////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef VS_TAGSDB_H
#define VS_TAGSDB_H

#include "tagsmain.h"
#include "tagsdb.h"
#include "tagscntx.h"
#include "slickedit/SEString.h"
#include "tags/SEListTagsTarget.h"

/*
   Maximum Storage requirements for different string types.
   If you don't use these constants, you risk overwriting memory
   bounds when you retrieve data using vsTagGetDetail* or
   vsTagGetTagInfo, etc.
*/
#define VS_TAG_MAX_WORDNAME   4096
#define VS_TAG_MAX_SIGNATURE  2048
#define VS_TAG_MAX_TAGNAME     255
#define VS_TAG_MAX_FILENAME   1024
#define VS_TAG_MAX_FILEEXT     255
#define VS_TAG_MAX_CLASSNAME  1024
#define VS_TAG_MAX_TYPENAME     64
#define VS_TAG_MAX_PARENTS    2048
#define VS_TAG_MAX_MATCHES     128
#define VS_TAG_MAX_INSTANCES  1000
#define VS_TAG_MAX_OCCURRENCES 1600
#define VS_TAG_MAX_OCCURRENCES_NAME_LIST  6000


/**
 * Return the name of the database currently open
 *
 * @return name of database, or the empty string on error.
 */
EXTERN_C
int VSAPI SETagGetCurrentDatabase(slickedit::SEString & databaseFileName);

/** 
 * Return the handle for the database currently open
 * 
 * @return >=0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagGetCurrentDatabaseHandle();


/**
 * This function is used to look up a language-specific
 * callback function.
 * <p>
 * Return the names table index for the callback function for the
 * current language, or an inherited language. The current
 * object should be an editor control.
 *
 * @param callback_name  name of callback to look up, with a
 *                       '%s' marker in place where the language
 *                       ID would be normally located.
 * @param ext            current language ID
 *                       (default={@link p_LangId})
 *
 * @return Names table index for the callback.
 *         0 if the callback is not found or not callable.
 *
 * @categories Tagging_Functions
 * @deprecated use {@link vsFindLanguageCallbackIndex()} 
 */
EXTERN_C
int VSAPI vsTagFindExtCallback(const char *callback_name, 
                               const char *language_id VSDEFAULT(0));

/**
 * Retrieve the date of tagging for the given file.
 * The string returned by this function is structured
 * such that consecutive dates are ordered lexicographically,
 * and is reported in local time coordinates (YYYYMMDDHHMMSSmmm).
 * This function has the side effect of positioning the file
 * iterator on the given file name, and may be used to test
 * for the existence of a file in the database.
 *
 * @param pszFilename      File path of source file to retrieve tagging date for.
 * @param pszDate          (20 bytes, optional) Modification date of file when tagged.
 *                         Format is YYYYMMDDHHMMSSmmm
 *                         (year, month, day, hour, minute, second, ms)
 * @param pszIncludedBy    File path of source file which includes pszFilename
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetDate(const char *pszFilename, char *pszDate VSDEFAULT(0),const char *pszIncludedBy VSDEFAULT(0));

/**
 * Set the date of tagging for the given file.  If the date is not
 * specified, use the file modification time found on disk.
 * This function has the side effect of positioning the file
 * iterator on the given file name.
 *
 * @param pszFilename      File path of source file to setting tagging date for.
 * @param pszDate          (20 bytes, optional) Modification date of file when tagged.
 *                         Format is YYYYMMDDHHMMSSmmm
 *                         (year, month, day, hour, minute, second, ms)
 * @param file_type        Type of file to search for, source vs. reference
 * @param pszIncludedBy    File path of source file which includes pszFilename
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagSetDate(const char *pszFilename, const char *pszDate VSDEFAULT(0),
                       int file_type VSDEFAULT(0), const char *pszIncludedBy VSDEFAULT(0));

/**
 * Set the date of tagging for the given file.  If the date is not
 * specified, use the file modification time found on disk.
 * This function has the side effect of positioning the file
 * iterator on the given file name.
 *
 * @param dbHandle         database handle 
 * @param fileName         File path of source file to setting tagging date for.
 * @param fileDate         (20 bytes, optional) Modification date of file when tagged.
 *                         Format is YYYYMMDDHHMMSSmmm
 *                         (year, month, day, hour, minute, second, ms)
 * @param fileType         Type of file to search for, source vs. reference
 * @param includedBy       (optional) File path of source file which includes pszFilename
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI SETagSetFileDate(int dbHandle,
                           const slickedit::SEString &fileName, 
                           const VSINT64 fileDate = 0,
                           int fileType = 0, 
                           const slickedit::SEString &includedBy = (const char *)0);

/**
 * Retrieve the {@link p_LangId} property for the given file. 
 * This function has the side effect of positioning the file 
 * iterator on the given file name, and may be used to test for 
 * the existence of a file in the database. 
 *
 * @param pszFilename      File path of source file
 * @param pszLangId        (256 bytes) Set to language ID for the file
 *
 * @return 0 on success, < 0 on error, 
 *         BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 * @deprecated Use {@link vsTagGetLanguage}
 */
EXTERN_C
int VSAPI vsTagGetExtension(const char *pszFilename, 
                            char *pszLangId VSDEFAULT(0));

/**
 * Retrieve the {@link p_LangId} property for the given file. 
 * This function has the side effect of positioning the file 
 * iterator on the given file name, and may be used to test for 
 * the existence of a file in the database. 
 *
 * @param pszFilename      File path of source file
 * @param pszLangId        Set to language ID for the file
 * @param maxLangId        Number of bytes allocated to pszLangId
 *
 * @return 0 on success, < 0 on error, 
 *         BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetLanguage(const char *pszFilename, 
                           char *pszLangId VSDEFAULT(0),
                           int   maxLangId VSDEFAULT(VS_TAG_MAX_FILEEXT));

/**
 * API function for setting the language type for the given 
 * filename.  This corresponds to the p_LangId property of 
 * 'file_name', not necessarily the literal file extension.
 *  
 * @param file_name     name of file to set language type for 
 * @param lang          p_LangId property for file_name 
 *  
 * @return 0 on success, <0 on error.
 * 
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagSetLanguage(VSPSZ pszFilename, VSPSZ pszLangId);

/**
 * Set the language ID for the given file.  
 *
 * @param dbHandle        database handle 
 * @param fileName        File path of source file to setting tagging date for.
 * @param langId          p_LangId property for file_name 
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if the file is not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI SETagSetFileLanguage(int dbHandle,
                               const slickedit::SEString &fileName, 
                               const slickedit::SEString &langId);

/**
 * Retrieve an language ID from the language name table. 
 * This function has the side effect of positioning the language
 * iterator on the given language type, and may be used to test 
 * the existence of a language type in the database.
 *
 * @param pszLangId      Language ID found
 * @param pszSearchFor   Language ID to search for
 * @param pszFindFirst   Find first language, or find next?
 *
 * @return 0 on success, <0 on error, 
 * BT_RECORD_NOT_FOUND_RC if the language is not found.
 *
 * @categories Tagging_Functions 
 * @deprecated Use {@link vsTagFindLanguage} 
 */
EXTERN_C
int VSAPI vsTagFindExtension(char *pszLangId, 
                             const char *pszSearchFor VSDEFAULT(0), 
                             int find_first VSDEFAULT(1));

/**
 * Retrieve a language ID from the language name table. 
 * This function has the side effect of positioning the language
 * iterator on the given language type, and may be used to test 
 * the existence of a language type in the database.
 *
 * @param pszLangId      Language ID found
 * @param pszSearchFor   Language ID to search for
 * @param pszFindFirst   Find first language, or find next?
 *
 * @return 0 on success, <0 on error, 
 * BT_RECORD_NOT_FOUND_RC if the language is not found.
 *
 * @categories Tagging_Functions 
 */
EXTERN_C
int VSAPI vsTagFindLanguage(char *pszLangId, 
                            const char *pszSearchFor VSDEFAULT(0), 
                            int find_first VSDEFAULT(1));

/**
 * Retrieve the name of the first file included in this tag database,
 * or optionally, the name of a specific file, either to check if the
 * file is in the database or to position the file iterator at a
 * specific point. Files are ordered lexicographically, case-sensitive
 * on UNIX platforms, case insensitive on DOS/OS2/Windows platforms.
 *
 * @param pszFilename      (Output, 1024 bytes) File name as stored in database.
 *                         Allocate VS_TAG_MAX_FILENAME characters.
 * @param pszPrefix        (Optional) File name/path prefix to search for.
 *                         Ignored if find_first==0
 * @param find_first       (Optional) Find first match or next natch?
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindFile(char *pszFilename,const char *pszPrefix VSDEFAULT(0), int find_first VSDEFAULT(1));

/**
 * Retrieve the name of the first file included by 'pszFileName'.
 *
 * @param pszFilename    "outer" filename, for example, src.jar
 * @param find_first     Find first included file, or find next?
 * @param pszIncludeName (reference) pointer to buffer to copy include file name into
 * @param include_max    size of buffer for 'pszIncludeName'
 *
 * @return 0 on sucess, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagFindIncludeFile(const char *pszFilename, int find_first,
                                        char *pszIncludeName, int include_max);

/**
 * Retrieve the name of a file that includes 'pszFileName'.
 *
 * @param pszFileName   name of included file
 * @param find_first    find first item, or next
 * @param pszIncludedBy (reference) set to name of included file
 * @param included_max  size of buffer for 'pszIncluded'
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagFindIncludedBy(const char *pszFileName, int find_first,
                                       char *pszIncludedBy, int included_max);

/**
 * Open an existing database for read-only or read-write access.
 * The database type (tags, references) is automatically detected.
 * BSC files can not be opened read-write, use tag_read_db instead.
 *
 * @param pszFilename      File path of database to open.
 * @param read_only        (default true) open the database for read access
 *
 * @return database handle >= 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagOpenDB(const char *pszFilename, int read_only VSDEFAULT(1));

/** 
 * Open an existing tag database for thread-safe write access.
 * This function is specifically designed for the background tagging threads.
 * 
 * @param pszFilename      File path of databsae to open.
 * 
 * @return database handle >= 0 on success, <0 on error.
 * 
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagOpenWriterDB(const char *pszFilename);

/**
 * Discard the results of the given tag database which was opened for 
 * thread-safe write access.  This is necessary if we encounter a situation 
 * where obtaining a write lock to flush the changes made to a database 
 * using a reader-writer database would cause a deadlock situation because 
 * there is another thread waiting for a write lock. 
 * 
 * @author dbrueni (9/26/2011)
 * 
 * @param dbHandle 
 * 
 * @return int VSAPI 
 */
EXTERN_C
int VSAPI vsTagDiscardWriterDB(int dbHandle);

/**
 * Create a tags database, with standard tables, index, and types.
 *
 * @param pszFilename      File path where to create new database.
 *                         If the file already exists, it will be truncated.
 * @param dbFlags          Bitset of VS_DBFLAG_* 
 * @param dbDescription    database comment 
 *
 * @return database handle >= 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagCreateDB(const char *pszFilename, 
                        int dbFlags VSDEFAULT(0),
                        const char *dbDescription VSDEFAULT(0));

/**
 * Return the database flags associated with the given database.
 * 
 * @param dbHandle   tag database handle 
 * 
 * @return Bitset of VS_DBFLAG_* 
 */
EXTERN_C int VSAPI vsTagGetDatabaseFlags(int dbHandle);

/**
 * Return the user database version 
 * associated with the given database.
 * 
 * @param dbHandle   tag database handle 
 * 
 * @return Bitset of VS_DBFLAG_* 
 */
EXTERN_C int VSAPI vsTagGetDatabaseVersion(int dbHandle);

/**
 * Close the current database.
 *
 * @param pszFilename      (optional) File path of database to close.
 * @param leave_open       (optional) If true, do not really close the file,
 *                         instead flush the buffer if open read-write, then
 *                         leave the file open read-only.
 * @param dbHandle         (optional) Explicit database handle to close. 
 *                         If this is given, pszFilename is ignored.
 * @param releaseExtraWriteLock (optional) If this database was opened using 
 *                         {@link vsTagOpenWriterDB()}, and then locked for
 *                         writing in advance using {@link vsTagWriteLockDB()},
 *                         release the extra write lock now.  This is done to
 *                         prevent a race condition that could lead to deadlock.
 *
 * @return database handle >= 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagCloseDB(const char *pszFilename VSDEFAULT(0), 
                       int leave_open VSDEFAULT(0), 
                       int dbHandle VSDEFAULT(-1),
                       bool releaseExtraWriteLock VSDEFAULT(false));

/**
 * Flush unwritten blocks out to disk for the given database. 
 *  
 * @param dbHandle    Explicit database handle to close. 
 *
 * @return database handle >= 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFlushDB(int dbHandle VSDEFAULT(-1));

/**
 * Lock the given database to prevent other threads from accessing it. 
 * This will obtain a write lock on the database, blocking all other 
 * reader and writer threads until it is released().
 *  
 * @param dbHandle          database handle returned from vsTagOpenDB() 
 * @param ms                millisecond timeout to wait before giving 
 *                          up on obtaining the write lock. 
 *  
 * @return 0 on success, <0 on error 
 *
 * @see vsTagOpenDB() 
 * @see vsTagCloseDB() 
 * @see vsTagWriteLockDB() 
 * @see vsTagReadLockDB() 
 * @see vsTagUnlockDB() 
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagWriteLockDB(int dbHandle, int ms=0);

/**
 * Lock the given database to prevent other threads from writing to it.
 * This will obtain a read lock on the database, blocking writer threads, 
 * but permitting other read threads to continue to use the database.  
 *  
 * @param dbHandle          database handle returned from vsTagOpenDB() 
 * @param ms                millisecond timeout to wait before giving 
 *                          up on obtaining the reader lock. 
 *  
 * @return 0 on success, <0 on error 
 *
 * @see vsTagOpenDB() 
 * @see vsTagCloseDB() 
 * @see vsTagWriteLockDB() 
 * @see vsTagReadLockDB() 
 * @see vsTagUnlockDB() 
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagReadLockDB(int dbHandle, int ms=0);

/**
 * Unlock the given database to allow other threads to access it. 
 * <p> 
 * You can do this with a database which is open for writing in order 
 * to leave the database in a writable state and allow other threads 
 * to search it and perform transactions and do whatever they want 
 * to the state of the database.  In this case, you should use 
 * vsTagOpenDB() to relock the database. The advantage is that you can 
 * avoid needing to flush the modifications to the database to disk 
 * which would normally happen if you called vsTagCloseDB() to release 
 * the lock you have on the database. 
 *  
 * @param dbHandle          database handle returned from vsTagOpenDB() 
 *  
 * @return 0 on success, <0 on error 
 *  
 * @see vsTagOpenDB() 
 * @see vsTagCloseDB() 
 * @see vsTagWriteLockDB() 
 * @see vsTagReadLockDB() 
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagUnlockDB(int dbHandle, int justReleaseWriteLock=false);

/** 
 * Check if there is a writer (i.e., the main thread) waiting for a write 
 * lock on this database. 
 * 
 * @return 0 on success, <0 on error, >0 if there are writers waiting.
 *  
 * @see vsTagOpenDB() 
 * @see vsTagCloseDB() 
 * @see vsTagWriteLockDB() 
 * @see vsTagReadLockDB() 
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagDatabaseHasWriterWaiting();

/**
 * Retag the given file, using the given extension-specific parser.
 *
 * @param pszFilename      Name/Path to source file to tag
 * @param pszExt           File extension to use for tagging this source code
 * @param reserved         future expansion
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagRetagFile(const char *pszFilename,const char *pszExt VSDEFAULT(0),int reserved VSDEFAULT(0));


/**
 * Set up for inserting a series of tags from a single file for
 * update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param file_name        full path of file the tags are located in
 *
 * @return 0 on success, <0 on error.int VSAPI
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertFileStart(const char *file_name);

/**
 * Clean up after inserting a series of tags from a single file
 * for update.  Doing this allows the tag database engine to
 * remove any tags from the database that are no longer valid.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertFileEnd();

/**
 * Set up for inserting a series of tags from a single file for
 * update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param dbHandle            database handle 
 * @param fileName            full path of file the tags are located in 
 * @param excludeNestedFiles  set of file names of files which may be 
 *                            nested in this file, but are going to be
 *                            tagged independently, so they should be
 *                            excluded from the file update because they
 *                            will be updated when the nested file is
 *                            updated. 
 *
 * @return 0 on success, <0 on error.int VSAPI
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI SETagInsertFileStart(int dbHandle, 
                               const slickedit::SEString &fileName,
                               slickedit::SEHashSet<slickedit::SETagInformation> &oldTags,
                               const slickedit::SEStringSet *pExcludeNestedFiles = NULL);

/**
 * Clean up after inserting a series of tags from a single file
 * for update.  Doing this allows the tag database engine to
 * remove any tags from the database that are no longer valid.
 *
 * @param dbHandle            database handle 
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI SETagInsertFileEnd(int dbHandle, 
                             slickedit::SEHashSet<slickedit::SETagInformation> &oldTags);

/**
 * API function for inserting a tag entry with supporting info
 *
 * @param tag_name            name of entry
 * @param tag_type            type of tag, (see VS_TAGTYPE_*)
 * @param file_name           path to file that is located in
 * @param line_no             line number that tag is positioned on
 * @param class_name          name of class that tag belongs to
 * @param tag_flags           tag attributes (see VS_TAGFLAG_*)
 * @param signature           (optional) arguments and return type
 * @param class_parents       (optional) class parents
 * @param template_signature  (optional) template signature
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertTag(const char *tag_name, const char *tag_type,
                         const char *file_name, int line_no,
                         const char *class_name, int tag_flags,
                         const char *signature VSDEFAULT(0),
                         const char *class_parents VSDEFAULT(0),
                         const char *template_signature VSDEFAULT(0));

/**
 * API function for inserting a tag entry with supporting info
 *
 * @param tag_name            name of entry
 * @param type_id             type of tag, (see VS_TAGTYPE_*)
 * @param file_name           path to file that is located in
 * @param line_no             line number that tag is positioned on
 * @param class_name          name of class that tag belongs to
 * @param tag_flags           tag attributes (see VS_TAGFLAG_*)
 * @param signature           (optional) arguments and return type
 * @param class_parents       (optional) class parents
 * @param template_signature  (optional) template signature
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertSimpleTag(const char *tag_name, int type_id,
                               const char *file_name, int line_no,
                               const char *class_name, int tag_flags,
                               const char *signature VSDEFAULT(0),
                               const char *class_parents VSDEFAULT(0),
                               const char *template_signature VSDEFAULT(0));

/**
 * API function for inserting a tag entry with supporting info
 *  
 * @param dbHandle            database handle 
 * @param tag_name            name of entry
 * @param type_id             type of tag, (see VS_TAGTYPE_*)
 * @param file_name           path to file that is located in
 * @param line_no             line number that tag is positioned on
 * @param class_name          name of class that tag belongs to
 * @param tag_flags           tag attributes (see VS_TAGFLAG_*)
 * @param signature           (optional) arguments and return type
 * @param class_parents       (optional) class parents
 * @param template_signature  (optional) template signature
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C 
int VSAPI SETagInsertInDatabase(int dbHandle,
                                slickedit::SEHashSet<slickedit::SETagInformation> *oldTags,
                                const slickedit::SEString &tag_name,   unsigned short tag_type,
                                const slickedit::SEString &file_name,  unsigned int line_no,
                                const slickedit::SEString &class_name, unsigned int tag_flags,
                                const slickedit::SEString &signature = (const char *)0,
                                const slickedit::SEString &class_parents = (const char *)0,
                                const slickedit::SEString &template_sig  = (const char *)0 );


/**
 * API function for inserting a tag entry with supporting info
 *  
 * @param dbHandle            database handle 
 * @param oldTags             old tag information (from SETagFileInsertStart()) 
 * @param tagInfo             tag information to insert into database 
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C 
int VSAPI SETagInsertInfoInDatabase(int dbHandle,
                                    slickedit::SEHashSet<slickedit::SETagInformation> *oldTags,
                                    const slickedit::SETagInformation &tagInfo);

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
 * @param tag_flags        (optional) see VS_TAGFLAG_* above.
 * @param signature        (optional) tag signature (return type, arguments, etc)
 * @param class_parents    (optional) classes that this class inherits from
 * @param template_sig     (optional) template signature
 * @param name_line_no     (optional) line number that symbol name is located on
 * @param name_seekpos     (optional) Seek position of the first character of the symbol name 
 *
 * @return sequence number (context_id) of tag context on success, or <0 on error.
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertContext(int outer_context,
                             const char *tag_name, const char *tag_type,
                             const char *file_name,
                             int start_line_no, int start_seekpos,
                             int scope_line_no, int scope_seekpos,
                             int end_line_no,   int end_seekpos,
                             const char *class_name VSDEFAULT(0),
                             int tag_flags VSDEFAULT(0),
                             const char *signature VSDEFAULT(0),
                             const char *class_parents VSDEFAULT(0),
                             const char *template_sig VSDEFAULT(0),
                             int name_line_no VSDEFAULT(0), 
                             int name_seekpos VSDEFAULT(0)
                             );

EXTERN_C int VSAPI
SETagInsertContext(int outer_context,
                   const slickedit::SEString &tag_name, 
                   unsigned short tag_type, 
                   const slickedit::SEString &file_name,
                   int start_linenum, int start_seekpos,
                   int name_linenum, int name_seekpos,
                   int scope_linenum, int scope_seekpos,
                   int end_linenum, int end_seekpos,
                   const slickedit::SEString &class_name, 
                   int tag_flags,
                   const slickedit::SEString &signature = (const char *)0,
                   const slickedit::SEString &class_parents = (const char *)0,
                   const slickedit::SEString &template_sig  = (const char *)0 );

EXTERN_C int VSAPI
SETagSetContextTokenList(slickedit::SETokenList *pTokenList);

EXTERN_C slickedit::SETokenList * VSAPI
SETagGetContextTokenList();

EXTERN_C int VSAPI
vsTagCurrentContext(int bufferId, const char *fileName, int lineNum, int seekPos);

EXTERN_C int VSAPI
vsTagCurrentLocal(int bufferId, const char *fileName, int lineNum, int seekPos);

/**
 * Clear the set of tags for the current file (the context). 
 * Optionally, also clear out the token list saved for the current file. 
 * 
 * @param preserveTokenList   (optional) save token list
 */
EXTERN_C int VSAPI 
vsTagClearContext(bool preserveTokenList=false);

/**
 * Clear all tag lists for all buffers and all local variable sets and all 
 * match sets.  This should only be called when we are completely closing 
 * or resetting the tag database library. 
 */
EXTERN_C void VSAPI 
vsTagClearAllContext();

/**
 * Add a local variable tag and its information to the locals list.
 * The context for the a local tag includes all tag information,
 * as well as the ending line number and begin/scope/end seek
 * positions in the file.  If unknown, the end line number/seek
 * position may be deferred, see tag_end_local().
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(true)
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
 * @param tag_flags        (optional) see VS_TAGFLAG_* above.
 * @param signature        (optional) tag signature (return type, arguments, etc)
 * @param class_parents    (optional) classes that this class inherits from
 * @param template_sig     (optional) template signature
 * @param name_line_no     (optional) line number that symbol name is located on
 * @param name_seekpos     (optional) Seek position of the first character of the symbol name 
 *
 * @return sequence number (local_id) of local variable on success, or <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertLocal(const char *tag_name, const char *tag_type, const char *file_name,
                           int start_linenum, int start_seekpos,
                           int scope_linenum, int scope_seekpos,
                           int end_linenum,   int end_seekpos,
                           const char *class_name VSDEFAULT(0),
                           int tag_flags VSDEFAULT(0),
                           const char *signature VSDEFAULT(0),
                           const char *class_parents VSDEFAULT(0),
                           const char *template_sig VSDEFAULT(0),
                           int name_line_no VSDEFAULT(0), 
                           int name_seekpos VSDEFAULT(0)
                           );

EXTERN_C int VSAPI
SETagInsertLocal(const slickedit::SEString &tag_name, 
                 unsigned short tag_type, 
                 const slickedit::SEString &file_name,
                 int start_linenum, int start_seekpos,
                 int name_linenum, int name_seekpos,
                 int scope_linenum, int scope_seekpos,
                 int end_linenum, int end_seekpos,
                 const slickedit::SEString &class_name, 
                 int tag_flags,
                 const slickedit::SEString &signature = (const char *)0,
                 const slickedit::SEString &class_parents = (const char *)0,
                 const slickedit::SEString &template_sig  = (const char *)0 );

/**
 * Add a search match tag and its information to the matches list.
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
 * @param tag_flags         (optional) see VS_TAGFLAG_* above.
 * @param signature         (optional) tag signature (return type, arguments, etc)
 * @param class_parents    (optional) classes that this class inherits from
 * @param template_sig     (optional) template signature
 *
 * @return sequence number (match_id) of matching tag on success, or <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagInsertMatch(const char *tag_file,
                           const char *tag_name, const char *tag_type,
                           const char *file_name,
                           int start_linenum, int start_seekpos,
                           int scope_linenum, int scope_seekpos,
                           int end_linenum, int end_seekpos,
                           const char *class_name VSDEFAULT(0),
                           int tag_flags VSDEFAULT(0),
                           const char *signature VSDEFAULT(0),
                           const char *class_parents VSDEFAULT(0),
                           const char *template_sig VSDEFAULT(0));

/**
 * Speedy version of tag_insert_match that simply clones a context,
 * local, or current tag match
 *
 * @param match_type       match type, VS_TAGMATCH_*, local, context, tag
 * @param local_or_ctx_id  ID of local variable or tag in current context
 * @param checkDuplicates  check for duplicates before inserting item
 *
 * @return sequence number (match_id) of matching tag on success, or <0 on error.
 */
EXTERN_C
int VSAPI vsTagInsertMatchFast(int match_type, int local_or_ctx_id,
                               int checkDuplicates VSDEFAULT(0));


/**
 * Update the tags in the current context if necessary.  The context needs
 * to be updated if we switch buffers, or if it is modified.
 *
 * @return 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagUpdateContext();

/**
 * Update the list of local variables found in the current function,
 * if necessary.  The locals need to be updated if the cursor moves
 * or if the buffer is modified, or if we switch buffers.
 *
 * @param list_all
 *
 * @return 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagUpdateLocals(int list_all VSDEFAULT(0));


/**
 * Check if we are in an embedded context and enter embedded language
 * mode if necessary.
 *
 * @param orig_values   HVAR used to save the original mode name
 *                      extension, and related information.
 *
 * @return
 * <UL>
 * <LI><B>0</B> --
 *   Returns 0 if there is no embedded language
 * <LI><B>1</B> --
 *   Return 1,  indicates that the mode has been
 *   switch to the embedded language.  Caller must
 *   call vsTagEmbeddedEnd(orig_values)
 * <LI><B>2</B> --
 *   Returns 2 to indicate that there is embedded language
 *   code, but in comment/in string like default processing
 *   should be performed.
 * <LI><B>3</B> --
 *   Returns 3 if mode name is the same.
 * </UL>
 *
 * @see vsTagEmbeddedEnd()
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagEmbeddedStart(VSHREFVAR orig_values);

/**
 * If we are in embedded mode, leave it, and restore the embedded
 * mode back to what it was before.
 *
 * @param orig_values   HVAR used to restore the original mode.
 *
 * @see vsTagEmbeddedStart()
 *
 * @categories Tagging_Functions
 */
EXTERN_C
void VSAPI vsTagEmbeddedEnd(VSHREFVAR orig_values);

/**
 * Remove all tags or references from the given source file.
 * This is an effective, but costly way to perform an incremental
 * update of the database.  First remove all items associated with
 * that file, then insert them again.
 *
 * @param pszFilename      File path of source file to remove from tag file.
 * @param RemoveFile       If true, remove file_name from the tag database
 *                         completely, not just the tags in that file.  Default is false.
 *
 * @return 0 on success, < 0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagRemoveFromFile(const char *pszFilename,int RemoveFile VSDEFAULT(0));

/**
 * Find the first tag in the given file.  Tags are returned unsorted.
 * Use vsTagGetTagInfo to extract the details about the tag.
 *
 * @param pszFilename      File name as stored in database.
 * @param find_first       find first match or next match
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindInFile(const char *pszFilename, int find_first VSDEFAULT(1));

/**
 * Retrieve tag in the given file closest to the given line number.
 * Use vsTagGetTagInfo to extract the details about the tag.
 *
 * @param pszTagName       Name of tag to search for.
 * @param pszFilename      Full path to file containing tag.
 * @param line_no          Line that tag is expected to be at or near.
 * @param case_sensitive   case sensitive tag name comparison?
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindClosest(const char *pszTagName, const char *pszFilename, int line_no, int case_sensitive VSDEFAULT(0));

/**
 * Retrieve the first tag with the given tag name or tag name prefix.
 * Use vsTagGetTagInfo to extract the details about the tag.
 *
 * @param pszTagName       Name of tag to search for.
 * @param pszClassName     (optional) class name to search for tag_name having
 * @param exact_match      (optional) exact match or prefix match of pszTagName
 * @param case_sensitive   (optional) default search is case-insensitive.
 * @param find_first       (optional) find first match, or next match
 * @param skip_duplicates  (optional) skip duplicate tags
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindEqual(const char *pszTagName, const char *pszClassName VSDEFAULT(0),
                         int exact_match VSDEFAULT(1), int case_sensitive VSDEFAULT(1),
                         int find_first VSDEFAULT(1), int skip_duplicates VSDEFAULT(0));

/**
 * Retrieve the first tag included in this tag database with global scope
 * that is one of the given type (type_id) and that matches the given tag
 * flag mask ((mask & tag_flags) != 0) == non_zero.  Use vsTagGetInfo
 * and/or vsTagGetDetail to extract the details about the tag.
 *
 * @param type_id          Type id (VS_TAGTYPE_*)
 *                         If (type_id<0), returns tags with any user defined tag types.
 * @param mask             Tag attribute flags set (VS_TAGFLAG_*).
 *                         The intersection of  this set of flags and those
 *                         for each tag found (tag_flags) will be calculated.
 * @param nzero            Accept tag if (mask & tag_flags) is non-zero
 * @param find_first       find first match or next match
 *
 * @return 0 on success, < 0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @example  find the first inline global function.
 * <PRE>
 *      vsTagFindGlobalOfType(VS_TAGTYPE_function, VS_TAGFLAG_inline, 1);
 * </PRE>
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindGlobal(int type_id, int mask VSDEFAULT(0), int nzero VSDEFAULT(0), int find_first VSDEFAULT(1));

/**
 * Starting with the currently selected tag, compare the
 * tag name with the given regular expression.
 *
 * @param pszTagRegex      regular expression to search for tags matching
 * @param pszSearchOptions search options, passed to vsStrPos()
 * @param find_first       find first match or next match
 *
 * @return 0 if a match is found, <0 on error or not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindRegex(const char *pszTagRegex,
                         const char *pszSearchOptions VSDEFAULT(0), int find_first VSDEFAULT(1));

/**
 * Find the first tag with the given, name, type and class.
 *
 * @param pszTagName       tag name to find, exact match
 * @param type_id          tag type to search for tag_name having (VS_TAGTYPE_*)
 * @param pszClassName     class name to search for tag_name having
 * @param find_first       find first match, or next match
 * @param signature        function signature, ignored if no match found
 *
 * @return 0 on success, <0 on error or not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindTag(const char *pszTagName, int type_id,
                       const char *pszClassName VSDEFAULT(0),
                       int find_first VSDEFAULT(1), const char *signature VSDEFAULT(0));

/**
 * Return the first class name in the database,
 * matching 'search_class', normalize the class name if necessary
 * (find the class/package scope that this class belongs to).
 * If (normalize==1) attempt to normalize the class name, finding a
 * package scope that this class could belong to.
 *
 * @param pszClassName     (output) output buffer for full class name (1024 bytes)
 *                         Allocate VS_TAG_MAX_CLASSNAME characters
 * @param pszSearch        (optional) name of class to look for, can be NULL
 * @param normalize        attempt to normalize class name found?
 * @param case_sensitive   case sensitive search?
 * @param find_first       find first match or next match
 * @param cur_class_name   name of current class context
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindClass(char *pszClassName, const char *pszSearch VSDEFAULT(0),
                         int normalize VSDEFAULT(0), int case_sensitive VSDEFAULT(1),
                         int find_first VSDEFAULT(1), const char *cur_class_name VSDEFAULT(0));

/**
 * Retrieve the first tag included in this tag database which belongs
 * to the given class name, and if specified, comes from the given file.
 * Use vsTagGetInfo and/or vsTagGetDetail to extract the details
 * about the tag.
 *
 * @param pszClassName     Class name to search for members of
 * @param pszFilename      (optional), tag must come from this file name
 * @param find_first       find first match or next match
 *
 * @return 0 on success, <0 on error, BT_RECORD_NOT_FOUND_RC if not found.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagFindMember(const char *pszClassName, const char *pszFilename VSDEFAULT(0), int find_first VSDEFAULT(1));

/**
 * Specify what classes and interfaces a given file
 * derives from.  This will create an entry for 'class_name'
 * if it does not already exist.
 * <p>
 * Fully qualified class names are preferred, but un-qualified class
 * names may be used also, however, they may not be resolved correctly
 * if there are duplicates with the same name.
 *
 * @param class_name       Fully qualified class name
 * @param class_parents    a semi-colon seperated list of class names.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagSetClassParents(const char *class_name, const char *class_parents);

/**
 * Specify what classes and interfaces a given file
 * derives from.  This will create an entry for 'class_name'
 * if it does not already exist.
 * <p>
 * Fully qualified class names are preferred, but un-qualified class
 * names may be used also, however, they may not be resolved correctly
 * if there are duplicates with the same name.
 *
 * @param dbHandle         database handle 
 * @param class_name       Fully qualified class name
 * @param class_parents    a semi-colon seperated list of class names.
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI SETagSetClassParents(int dbHandle,
                                        const slickedit::SEString &class_name, 
                                        const slickedit::SEString &class_parents);

/**
 * Return the list of parents for the given class name.  The parents are
 * returned as an array of null-terminated character strings.
 * This function has the side effect of positioning the class iterator
 * on the given class.  Since tagging usually cannot resolve the scope
 * of parent classes, you will normally have to use this in conjunction
 * with vsTagFindClass to get the qualified name for the parent class.
 *
 * @param pszClassName     Qualified name of class or interface to update
 *                         inheritance information for.  See VS_TAGSEPARATOR_class
 *                         and VS_TAGSEPARATOR_package for details on constructing
 *                         this string.
 *
 * @return 0 on failure, otherwise it returns the list of parent classes.
 *         Note that the list returned is allocated statically, and NULL terminated.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
const char ** VSAPI vsTagGetClassParents(const char *pszClassName);

/**
 * Set the class inheritance for the given context tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       id for the context to modify
 * @param parents          parents of the context item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetContextParents(int context_id, const slickedit::SEString &parents);

/**
 * Set the template signature for the given context tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_id       id for the context to modify
 * @param template_sig     template signature of the context item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetContextTemplateSignature(int context_id, const slickedit::SEString &template_sig);

/**
 * Revise the type signature for the given context variable.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param context_name     name of context variable to modify
 * @param type_name        type signature of the context item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetContextTypeSignature(const slickedit::SEString &context_name, 
                                     const slickedit::SEString &type_name, 
                                     bool case_sensitive=false);

/**
 * Set the class inheritance for the given local tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local to modify
 * @param parents          parents of the local item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetLocalParents(int local_id, const slickedit::SEString &parents);

/**
 * Set the template signature for the given local tag.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_id         id for the local to modify
 * @param template_sig     template signature of the local item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetLocalTemplateSignature(int local_id, const slickedit::SEString &template_sig);

/**
 * Revise the type signature for the given local variable.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(true) 
 * prior to invoking this function.
 *
 * @param local_name       name of local variable to modify
 * @param type_name        type signature of the local item
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C
int VSAPI SETagSetLocalTypeSignature(const slickedit::SEString &local_name, 
                                     const slickedit::SEString &type_name, 
                                     bool case_sensitive=false);


/**
 * Create a caption for the tag, given the following tag information
 * and specifications about the caption style.
 * The output string is generally formatted as follows:
 *    <PRE>
 *    member_name[(arguments)] ['in' class_name]
 *    </PRE>
 *    Parenthesis are added only for function types (proc, proto,
 *    constr, destr, func) and parameterized classes.  The result is
 *    returned as a pointer to a static character array.
 *
 *    Example:  for the C++ class member prototype
 *    <PRE>
 *      static void MyClass::myMember(int a, bool x);
 *    </PRE>
 *    the function would be invoked as follows:
 *    <PRE>
 *      tag_tree_make_caption(myMember, func, MyClass,
 *          VS_TAGFLAG_static, int a, bool x, include_tab);
 *    </PRE>
 *    producing the following caption if include_tab is true:
 *    <PRE>
 *      myMember(int a, bool x) in MyClass
 *    </PRE>
 *    and the following if include_tab is false.
 *    <PRE>
 *      MyClass::myMember(int a, bool x)
 *    </PRE>
 *
 * Caption formatted in standard form as normally presented in class browser.
 *
 * @param pszTagName       Name of  tag (symbol).
 * @param pszTypeName      Tag type, corresponding to VS_TAGTYPE_*
 * @param pszClassName     (Optional) Name of class or package or other container
 *                         that the tag belongs to.  See VS_TAGSEPARATOR_class
 *                         and VS_TAGSEPARATOR_package for more details about
 *                         constructing this value.  If the tag is not in a class
 *                         scope, simple pass the empty string for this value.
 * @param tag_flags        Set of tag attribute flags, VS_TAGFLAG_*.
 * @param pszArguments     (Optional) Arguments, such as function or template class parameters.
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param pszFileName      Path to tag, this is needed for packages
 * @param pszTemplateArgs  Tempalte signature
 *
 * @return Returns the resulting tree caption as a NULL terminated string.
 *         Note the result is returned is a statically allocated string.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
const char * VSAPI vsTagMakeCaption(const char *pszTagName, const char *pszTypeName,
                                    const char *pszClassName, int tag_flags,
                                    const char *pszArguments VSDEFAULT(0),
                                    int include_tab VSDEFAULT(0),
                                    const char *pszFileName VSDEFAULT(0),
                                    const char *pszTemplateArgs VSDEFAULT(0));

/**
 * API function for inserting a tag entry with supporting info into
 * the given tree control.
 *
 * @param tree_wid         window ID of the tree control
 * @param tree_index       parent index to insert item under
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       if < 0, force leaf node, otherwise choose by type
 * @param tree_flags       flags passed to vsTreeAddItem
 * @param pszTagName       name of entry
 * @param pszTypeName      type of tag, (see VS_TAGTYPE_*)
 * @param pszFileName      path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param pszClassName     name of class that tag belongs to
 * @param tag_flags        tag attributes (see VS_TAGFLAG_*)
 * @param pszSignature     arguments and return type
 * @param pszTemplateArgs  template signature 
 * @param hvarUserInfo     per-node user data for tree control 
 *
 * @return tree index on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagTreeInsertTag(int tree_wid, int tree_index,
                             int include_tab, int force_leaf, int tree_flags,
                             const char *pszTagName,
                             const char *pszTypeName,
                             const char *pszFileName, int line_no,
                             const char *pszClassName VSDEFAULT(0),
                             int tag_flags VSDEFAULT(0),
                             const char *pszSignature VSDEFAULT(0),
                             const char *pszTemplateArgs VSDEFAULT(0),
                             VSHVAR hvarUserInfo VSDEFAULT(0));

/**
 * Internal function for inserting a tag entry with supporting info
 * into the given tree control using the outline view rendering 
 * style. 
 *
 * @param tree_wid         window ID of the tree control
 * @param tree_index       parent index to insert item under
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       if < 0, force leaf node, otherwise choose by type
 * @param tree_flags       flags passed to vsTreeAddItem
 * @param pszTagName       name of entry
 * @param pszTypeName      type of tag, (see VS_TAGTYPE_*)
 * @param pszFileName      path to file that is located in
 * @param line_no          line number that tag is positioned on
 * @param pszClassName     name of class that tag belongs to
 * @param tag_flags        tag attributes (see VS_TAGFLAG_*)
 * @param pszSignature     arguments and return type
 * @param pszTemplateArgs  template signature 
 * @param hvarUserInfo     per-node user data for tree control 
 *
 * @return tree index on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
int tag_tree_insert_tag_outline(int tree_wid, int tree_index,
                                int include_tab, int tree_flags,
                                const char *pszTagName,
                                const char *pszTypeName,
                                const char *pszFileName, int line_no,
                                const char *pszClassName VSDEFAULT(0),
                                int tag_flags VSDEFAULT(0),
                                const char *pszSignature VSDEFAULT(0),
                                const char *pszTemplateArgs VSDEFAULT(0),
                                const char *pszNodeText VSDEFAULT(0),
                                VSHVAR hvarUserInfo VSDEFAULT(0));

/**
 * Insert the given context, local, match, or current tag
 * into the given tree.
 *
 * @param tree_id          tree widget to load info into
 * @param tree_index       tree index to insert into
 * @param match_type       VS_TAGMATCH_*
 * @param local_or_ctx_id  local, context, or match ID, 0 for current tag
 * @param include_tab      append class name after signature if 1,
 *                         prepend class name with :: if 0
 * @param force_leaf       force item to be inserted as a leaf item
 * @param tree_flags       tree flags to set for this item
 * @param include_sig      include function/define/template signature
 * @param include_class    include class name
 * @param user_info        per node user data for tree control 
 *
 * @return tree index on success, <0 on error.
 */
EXTERN_C
int VSAPI vsTagTreeInsertFast(int tree_id, int tree_index,
                               int match_type, int local_or_ctx_id,
                               int include_tab, int force_leaf, int tree_flags,
                               int include_sig, int include_class,
                               VSHVAR hvarUserInfo VSDEFAULT(0));

/**
 * Simple to use, but very fast entry point for selecting the bitmap
 * to be displayed in the tree control corresponding to the given
 * tag information.  You must call tag_tree_prepare_expand() prior to
 * calling this function.
 *
 * @param filter_flags_1 first part of class browser filter flags
 * @param filter_flags_2 second part of class browser filter flags
 * @param type_name      tag type name
 * @param class_name     tag class name, just checked for null/empty
 * @param tag_flags      tag flags, bitset of VS_TAGFLAG_*
 * @param leaf_flag      (reference) -1 implies leaf item, 0 or 1 container
 * @param pic_member     (reference) set to picture index of bitmap
 *
 * @return 0 on success, <0 on error, >0 if filtered out.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagGetBitmap(int filter_flags_1, int filter_flags_2,
               const char *type_name, const char *class_name, int tag_flags,
               int VSREF(leaf_flag), int VSREF(pic_member));

/**
 * Retrieve general information about the current tag (as defined
 * by calls to vsTagFindGlobal or vsTagFindMember.  If the current tag
 * is not defined, such as immediately after opening a database or a
 * failed search), all strings will be set to "", and line_no and tag_flags
 * will be set to 0.  Any of the string arguments, except pszTagName, may be
 * passed as 0, and then will not be retrieved.
 *
 * @param pszTagName       (Output, required) Name of tag or symbol
 * @param pszTypeName      (Output, optional) Tag type name, see tag_get_type.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, VS_TAGFLAG_*
 * @param pszFilename      (Output, optional) File name as stored in database.
 * @param line_no          (Output) Line number that tag occurs on in file_name.
 * @param pszClassName     (Output, optional) Name of class that tag belongs to.
 * @param pszReturnType    (Output, optional) Declared type/value of symbol or function
 * @param pszArguments     (Output, optional) Function/Macro arguments.
 * @param pszExceptions    (Output, optional) Exceptions thrown or other function details
 * @param pszClassParents  (Output, optional) Class parents
 * @param pszTmplSignature (Output, optional) Template signature
 *
 * @return 0 on success.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetTagInfo(char *pszTagName, char *pszTypeName, int VSREF(tag_flags),
                           char *pszFilename, int VSREF(line_no),
                           char *pszClassName VSDEFAULT(0), char *pszReturnType VSDEFAULT(0),
                           char *pszArguments VSDEFAULT(0), char *pszExceptions VSDEFAULT(0),
                           char *pszClassParents VSDEFAULT(0),
                           char *pszTmplSignature VSDEFAULT(0));

/**
 * Retrieve general information about the given tag in the current context.
 * If the context is not loaded, all strings will be set to "", and
 * integers will be set to 0.  Any of the string arguments, except pszTagName,
 * may be passed as 0, and then will not be retrieved.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * prior to invoking this function.
 *
 * @param context_id       Unique ID of context item, 1..num_of_context
 * @param pszTagName       (Output, required) Name of tag or symbol
 * @param pszTypeName      (Output, optional) Tag type name, see tag_get_type.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, VS_TAGFLAG_*
 * @param pszFilename      (Output, optional) File name as stored in database.
 * @param start_line_no    (Output) Line number that tag occurs on in file_name.
 * @param start_seekpos    (Output) Seek position where the tag begin in file_name.
 * @param scope_line_no    (Output) Line number that tag scope begins, eg. function scope
 * @param scope_seekpos    (Output) Seek position where the tag scope begins.
 * @param end_line_no      (Output) Line number that tag ends on in file_name.
 * @param end_seekpos      (Output) Seek position where the tag ends in file_name.
 * @param pszClassName     (Output, optional) Name of class that tag belongs to.
 * @param pszReturnType    (Output, optional) Declared type/value of symbol or function
 * @param pszArguments     (Output, optional) Function/Macro arguments.
 * @param pszExceptions    (Output, optional) Exceptions thrown or other function details
 * @param pszClassParents  (Output, optional) Class parents
 * @param pszTmplSignature (Output, optional) Template signature
 *
 * @return 0 on success.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetContextInfo(int context_id,
                              char *pszTagName, char *pszTypeName,
                              int VSREF(tag_flags), char *pszFilename,
                              int VSREF(start_line_no), int VSREF(start_seekpos),
                              int VSREF(scope_line_no), int VSREF(scope_seekpos),
                              int VSREF(end_line_no),   int VSREF(end_seekpos),
                              char *pszClassName VSDEFAULT(0), char *pszReturnType VSDEFAULT(0),
                              char *pszArguments VSDEFAULT(0), char *pszExceptions VSDEFAULT(0),
                              char *pszClassParents VSDEFAULT(0),
                              char *pszTmplSignature VSDEFAULT(0));

/**
 * Retrieve general information about the given local variable.
 * If the locals are not loaded, all strings will be set to "", and
 * integers will be set to 0.  Any of the string arguments, except pszTagName,
 * may be passed as 0, and then will not be retrieved.
 *
 * @param local_id         Unique ID of local variable, 1..num_of_locals
 * @param pszTagName       (Output, required) Name of tag or symbol
 * @param pszTypeName      (Output, optional) Tag type name, see tag_get_type.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, VS_TAGFLAG_*
 * @param pszFilename      (Output, optional) File name as stored in database.
 * @param start_line_no    (Output) Line number that tag occurs on in file_name.
 * @param start_seekpos    (Output) Seek position where the tag begin in file_name.
 * @param scope_line_no    (Output) Line number that tag scope begins, eg. function scope
 * @param scope_seekpos    (Output) Seek position where the tag scope begins.
 * @param end_line_no      (Output) Line number that tag ends on in file_name.
 * @param end_seekpos      (Output) Seek position where the tag ends in file_name.
 * @param pszClassName     (Output, optional) Name of class that tag belongs to.
 * @param pszReturnType    (Output, optional) Declared type/value of symbol or function
 * @param pszArguments     (Output, optional) Function/Macro arguments.
 * @param pszExceptions    (Output, optional) Exceptions thrown or other function details
 * @param pszClassParents  (Output, optional) Class parents
 * @param pszTmplSignature (Output, optional) Template signature
 *
 * @return int VSAPI
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetLocalInfo(int local_id,
                            char *pszTagName, char *pszTypeName,
                            int VSREF(tag_flags), char *pszFilename,
                            int VSREF(start_line_no), int VSREF(start_seekpos),
                            int VSREF(scope_line_no), int VSREF(scope_seekpos),
                            int VSREF(end_line_no),   int VSREF(end_seekpos),
                            char *pszClassName VSDEFAULT(0), char *pszReturnType VSDEFAULT(0),
                            char *pszArguments VSDEFAULT(0), char *pszExceptions VSDEFAULT(0),
                            char *pszClassParents VSDEFAULT(0),
                            char *pszTmplSignature VSDEFAULT(0));

/**
 * Retrieve information about the given search match.
 *
 * @param match_id         match ID to look up (from tag_insert_match)
 * @param pszTagName       (Output, required) Name of tag or symbol
 * @param pszTypeName      (Output, optional) Tag type name, see tag_get_type.
 * @param tag_flags        (Output) Tag flags indicating symbol attributes, VS_TAGFLAG_*
 * @param pszFilename      (Output, optional) File name as stored in database.
 * @param start_line_no    (Output) Line number that tag occurs on in file_name.
 * @param start_seekpos    (Output) Seek position where the tag begin in file_name.
 * @param scope_line_no    (Output) Line number that tag scope begins, eg. function scope
 * @param scope_seekpos    (Output) Seek position where the tag scope begins.
 * @param end_line_no      (Output) Line number that tag ends on in file_name.
 * @param end_seekpos      (Output) Seek position where the tag ends in file_name.
 * @param pszClassName     (Output, optional) Name of class that tag belongs to.
 * @param pszReturnType    (Output, optional) Declared type/value of symbol or function
 * @param pszArguments     (Output, optional) Function/Macro arguments.
 * @param pszExceptions    (Output, optional) Exceptions thrown or other function details
 * @param pszClassParents  (Output, optional) Class parents
 * @param pszTmplSignature (Output, optional) Template signature
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetMatchInfo(int match_id, char *pszTagFile,
                            char *pszTagName, char *pszTypeName,
                            int VSREF(tag_flags), char *pszFilename,
                            int VSREF(start_line_no), int VSREF(start_seekpos),
                            int VSREF(scope_line_no), int VSREF(scope_seekpos),
                            int VSREF(end_line_no),   int VSREF(end_seekpos),
                            char *pszClassName VSDEFAULT(0), char *pszReturnType VSDEFAULT(0),
                            char *pszArguments VSDEFAULT(0), char *pszExceptions VSDEFAULT(0),
                            char *pszClassParents VSDEFAULT(0),
                            char *pszTmplSignature VSDEFAULT(0));

/**
 * Retrieve specific integer information about the given tag, context item or
 * local variable.  This function complements vsTagGetTagInfo(),
 * vsTagGetContextInfo() and vsTagGetLocalInfo(), but is capable of getting
 * much more specific information about the given tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(false)
 * or tag_lock_matches(false) prior to invoking this function.
 *
 * @param detail_id        ID of detail to extract, one of:
 * <PRE>
 *       VS_TAGDETAIL_type_id                (int) unique id for tag type.
 *       VS_TAGDETAIL_file_line              (int) line number of tag within file
 *       VS_TAGDETAIL_file_id                (int) unique id for file the tag is located in
 *       VS_TAGDETAIL_class_id               (int) unique id for class tag belongs to
 *       VS_TAGDETAIL_flags                  (int) tag flags, see tag_insert_simple
 *       VS_TAGDETAIL_num_tags               (int) number of tags in database
 *       VS_TAGDETAIL_num_classes            (int) number of classes in database
 *       VS_TAGDETAIL_num_files              (int) number of files in database
 *       VS_TAGDETAIL_num_types              (int) number of types in database
 *       VS_TAGDETAIL_num_refs               (int) number of references in database
 *       VS_TAGDETAIL_tag_id                 (int) unique ID for tag instance
 *       VS_TAGDETAIL_context_id             (int) returns same result as tag_current_context()
 *       VS_TAGDETAIL_local_id               (int) returns same result as tag_current_local
 *       VS_TAGDETAIL_current_file           (int) returns name of file in current context
 *
 *       VS_TAGDETAIL_context_line           (int) start line number of tag.
 *       VS_TAGDETAIL_context_start_linenum  (int) same as *_line, above.
 *       VS_TAGDETAIL_context_start_seekpos  (int) seek position tag starts at
 *       VS_TAGDETAIL_context_name_linenum   (int) line number symbol name is on
 *       VS_TAGDETAIL_context_name_seekpos   (int) seek position of symbol name
 *       VS_TAGDETAIL_context_scope_linenum  (int) line number body starts at.
 *       VS_TAGDETAIL_context_scope_seekpos  (int) seek position body starts at.
 *       VS_TAGDETAIL_context_end_linenum    (int) line number tag ends on.
 *       VS_TAGDETAIL_context_end_seekpos    (int) seek position tag ends at.
 *       VS_TAGDETAIL_context_flags          (int) tag attribute flags.
 *       VS_TAGDETAIL_context_outer          (int) ID of first enclosing tag.
 *
 *       VS_TAGDETAIL_local_line             (int) start line number of tag.
 *       VS_TAGDETAIL_local_start_linenum    (int) same as *_line, above.
 *       VS_TAGDETAIL_local_start_seekpos    (int) seek position tag starts at
 *       VS_TAGDETAIL_local_name_linenum   (int) line number symbol name is on
 *       VS_TAGDETAIL_local_name_seekpos   (int) seek position of symbol name
 *       VS_TAGDETAIL_local_scope_linenum    (int) line number body starts at.
 *       VS_TAGDETAIL_local_scope_seekpos    (int) seek position body starts at.
 *       VS_TAGDETAIL_local_end_linenum      (int) line number tag ends on.
 *       VS_TAGDETAIL_local_end_seekpos      (int) seek position tag ends at.
 *       VS_TAGDETAIL_local_flags            (int) tag attribute flags.
 *       VS_TAGDETAIL_local_outer            (int) ID of first enclosing tag.
 *
 *       VS_TAGDETAIL_match_line             (int) start line number of tag.
 *       VS_TAGDETAIL_match_start_linenum    (int) same as *_line, above.
 *       VS_TAGDETAIL_match_start_seekpos    (int) seek position tag starts at
 *       VS_TAGDETAIL_match_name_linenum   (int) line number symbol name is on
 *       VS_TAGDETAIL_match_name_seekpos   (int) seek position of symbol name
 *       VS_TAGDETAIL_match_scope_linenum    (int) line number body starts at.
 *       VS_TAGDETAIL_match_scope_seekpos    (int) seek position body starts at.
 *       VS_TAGDETAIL_match_end_linenum      (int) line number tag ends on.
 *       VS_TAGDETAIL_match_end_seekpos      (int) seek position tag ends at.
 *       VS_TAGDETAIL_match_flags            (int) tag attribute flags.
 *       VS_TAGDETAIL_match_outer            (int) ID of first enclosing tag.
 * </PRE>
 * @param item_id          ID of local variable, context item to get
 *                         information about, ignored if the detail is
 *                         for the current tag in the tag database.
 * @param iValue           (Output) Set to tag detail value.  If the given
 *                         tag does not exist, this will be set to 0.
 *
 * @return 0 on success.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetDetailI(int detail_id, int item_id, int VSREF(iValue));

/**
 * Retrieve specific string information about the given tag, context item or
 * local variable.  This function complements vsTagGetTagInfo(),
 * vsTagGetContextInfo() and vsTagGetLocalInfo(), but is capable of getting
 * more specific information about the given tag.
 * <p> 
 * For synchronization, macros should perform a tag_lock_context(false)
 * or tag_lock_matches(false) prior to invoking this function.
 *
 * @param detail_id        ID of detail to extract, one of:
 * <PRE>
 *       VS_TAGDETAIL_name                   (string) tag name
 *       VS_TAGDETAIL_type                   (string) tag type name, see tag_get_type.
 *       VS_TAGDETAIL_file_name              (string) full path of file the tag is in
 *       VS_TAGDETAIL_file_date              (string) date of file when tagged
 *       VS_TAGDETAIL_class_simple           (string) name of class the tag is present in
 *       VS_TAGDETAIL_class_name             (string) name of class with outer classes
 *       VS_TAGDETAIL_class_package          (string) package/namespace tag belongs to
 *       VS_TAGDETAIL_return                 (string) value or type of var/function
 *       VS_TAGDETAIL_arguments              (string) function or template arguments
 *       VS_TAGDETAIL_throws                 (string) function/proc exceptions.
 *       VS_TAGDETAIL_included_by            (string) file including this macro.
 *       VS_TAGDETAIL_return_only            (string) just the return type of variable.
 *       VS_TAGDETAIL_return_value           (string) default value of variable.
 *       VS_TAGDETAIL_file_ext               (string) p_LangId for file name
 *       VS_TAGDETAIL_language_id            (string) p_language_id for file name 
 *       VS_TAGDETAIL_template_args          (string) template signature
 *
 *       VS_TAGDETAIL_context_tag_file       (string) tag file match is from.
 *       VS_TAGDETAIL_context_name           (string) tag name.
 *       VS_TAGDETAIL_context_type           (string) tag type name.
 *       VS_TAGDETAIL_context_file           (string) file that the tag is in.
 *       VS_TAGDETAIL_context_class          (string) name of class.
 *       VS_TAGDETAIL_context_args           (string) tag arguments.
 *       VS_TAGDETAIL_context_return         (string) value or type of symbol.
 *       VS_TAGDETAIL_context_parents        (string) class derivation.
 *       VS_TAGDETAIL_context_throws         (string) function/proc exceptions.
 *       VS_TAGDETAIL_context_included_by    (string) file including this macro.
 *       VS_TAGDETAIL_context_return_only    (string) just the type of variable.
 *       VS_TAGDETAIL_context_return_value   (string) default value of variable.
 *       VS_TAGDETAIL_context_template_args  (string) template signature
 *
 *       VS_TAGDETAIL_local_tag_file         (string) tag file match is from.
 *       VS_TAGDETAIL_local_name             (string) tag name.
 *       VS_TAGDETAIL_local_type             (string) tag type name.
 *       VS_TAGDETAIL_local_file             (string) file that the tag is in.
 *       VS_TAGDETAIL_local_class            (string) name of class.
 *       VS_TAGDETAIL_local_args             (string) tag arguments.
 *       VS_TAGDETAIL_local_return           (string) value or type of symbol.
 *       VS_TAGDETAIL_local_parents          (string) class derivation.
 *       VS_TAGDETAIL_local_throws           (string) function/proc exceptions.
 *       VS_TAGDETAIL_local_included_by      (string) file including this macro.
 *       VS_TAGDETAIL_local_return_only      (string) just the type of variable.
 *       VS_TAGDETAIL_local_return_value     (string) default value of variable.
 *       VS_TAGDETAIL_local_template_args    (string) template signature
 * </PRE>
 * @param item_id          ID of local variable or context item to get
 *                         information about, ignored if the detail is for
 *                         the current tag in the tag database.
 * @param pszValue         (Output, 1024 bytes allocated) Set to tag detail
 *                         after successful completion of function.  If the
 *                         given tag does not exist, this will be set to "".
 * @param max_len          (optional, default is VS_TAG_MAX_FILENAME), number of bytes
 *                         allocated to pszValue.
 *
 * @return 0 on success.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int VSAPI vsTagGetDetailZ(int detail_id, int item_id, char *pszValue, int max_len VSDEFAULT(VS_TAG_MAX_FILENAME));


///////////////////////////////////////////////////////////////////////////
// word index/occurrences index related functions

/**
 * Set up for inserting a series of occurrencess from a single file
 * for update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param file_name        full path of file
 *
 * @return 0 on success, <0 on error.int VSAPI
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagOccurrencesStart(const char *file_name);

/**
 * Clean up after inserting a series of occurrencess from a single
 * file for update.  Doing this allows the tag database engine to
 * remove any occurrences from the database that are no longer valid.
 *
 * @param file_name        full path of file
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI vsTagOccurrencesEnd(const char *file_name);

/**
 * Set up for inserting a series of occurrencess from a single file
 * for update.  Doing this allows the tag database engine to detect
 * and handle updates more effeciently, even in the presence of
 * duplicates.
 *
 * @param dbHandle         database handle 
 * @param file_name        full path of file 
 * @param occurHashTable   hash table mapping file names to a 
 *                         hash set of symbol names 
 *                         this is used to cache results and avoid
 *                         inserting the same symbol twice. 
 *
 * @return 0 on success, <0 on error.int VSAPI
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI SETagOccurrencesStart(int dbHandle,
                                         const slickedit::SEString &file_name,
                                         slickedit::SEHashTable<int, slickedit::SEStringSet> &occurHashTable);
                     

/**
 * Clean up after inserting a series of occurrencess from a single
 * file for update.  Doing this allows the tag database engine to
 * remove any occurrences from the database that are no longer valid.
 *
 * @param dbHandle            database handle 
 * @param file_name        full path of file 
 * @param occurHashTable   hash table mapping file names to a 
 *                         hash set of symbol names 
 *                         this is used to cache results and avoid
 *                         inserting the same symbol twice.
 *  
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI SETagOccurrencesEnd(int dbHandle,
                                       const slickedit::SEString &file_name,
                                       slickedit::SEHashTable<int, slickedit::SEStringSet> &occurHashTable);

/**
 * Insert a new occurrence into the word index.
 *
 * @param occur_name      Word to be indexed
 * @param file_name       Path of file occurrence is located in
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagInsertOccurrence(const char *occur_name,const char *file_name);

/**
 * Insert a new occurrence into the word index.
 *
 * @param dbHandle         database handle 
 * @param occur_name       Word to be indexed
 * @param file_name        Path of file occurrence is located in 
 * @param occurHashTable   hash table mapping file names to a 
 *                         hash set of symbol names 
 *                         this is used to cache results and avoid
 *                         inserting the same symbol twice. 
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
SETagInsertOccurrence(int dbHandle,
                      const slickedit::SEString &occur_name,
                      const slickedit::SEString &file_name=(const char *)0,
                      slickedit::SEHashTable<int, slickedit::SEStringSet> *occurHashTable=NULL);

/**
 * Find the first/next occurrence with the given tag name or tag prefix.
 * Use tag_get_occurrence (below) to get details about the occurrence.
 *
 * @param tag_name        Tag name or prefix to search for
 * @param exact_match     Exact (word) match or prefix match (0)
 * @param case_sensitive  Case sensitive search?
 * @param find_first      find first match or next match?
 *
 * @return 0 on success, BT_RECORD_NOT_FOUND_RC if not found, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagFindOccurrence(const char *tag_name, int exact_match VSDEFAULT(0),
                    int case_sensitive VSDEFAULT(0), int find_first VSDEFAULT(1));

/**
 * Retrieve information about the current occurrence, as defined by
 * tag_find_occurrence/tag_next_occurrence.
 *
 * @param occur_name      (output, VS_TAG_MAX_TAGNAME) Word to be indexed
 * @param file_name       (output, VS_TAG_MAX_FILENAME) Path of file
 *                        occurrence is located in
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagGetOccurrence(char *occur_name, char *file_name);


/**
 * Use context_match_tags to locate the tag matches for the
 * occurrence in the given file at the given seek position.
 * If the seek position is 0, then use the current buffer,
 * otherwise, open the given file in a temporary view and
 * seek to the given position.
 *
 * @param errorArgs       Array of strings for return code
 * @param file_name       Path of file occurrence is located in
 * @param rseekpos        Real seek position of occurrence
 * @param tag_name        Name of occurrence to match against
 * @param case_sensitive  Case sensitive tag search?
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagContextMatchOccurrence(VSHREFVAR errorArgs,
                            const char *file_name, int rseekpos,
                            const char *tag_name, int case_sensitive,
                            int VSREF(num_matches), int max_matches VSDEFAULT(VS_TAG_MAX_MATCHES));

/**
 * The current object must be an editor control positioned on
 * the tag that you wish to find matches for, with the edit
 * mode selected.
 *
 * @param errorArgs       Array of strings for return code
 * @param tag_name        Name of occurrence to match against
 * @param max_tag_name    Amount of space allocated to tag_name
 * @param exact_match     Exact match or prefix match?
 * @param case_sensitive  Case sensitive tag search?
 * @param find_parents    Find instances of the tag in parent classes
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagContextMatchTags(VSHREFVAR errorArgs,
                      char *tag_name, int max_tag_name,
                      int exact_match, int case_sensitive, int find_parents,
                      int VSREF(num_matches), int max_matches VSDEFAULT(VS_TAG_MAX_MATCHES),
                      int filter_flags VSDEFAULT(VS_TAGFILTER_ANYTHING), 
                      int context_flags VSDEFAULT(VS_TAGCONTEXT_ALLOW_locals),
                      VSHREFVAR visited VSDEFAULT(0), int depth VSDEFAULT(0));

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
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagListFileOccurrences(int tree_wid, int tree_index,
                         const char *tag_name,
                         int exact_match, int case_sensitive,
                         int VSREF(num_refs), int max_refs,
                         VSPSZ restrictToLangId=NULL);

/**
 * Use context_match tags to locate the tag matches for the
 * occurrence in the given file at the given seek position.
 * If a file name is not given, then use the current buffer.
 * If a file name is given, but the seek position is -1, then
 * use the current buffer position.  Otherwise, open the given
 * file in a temporary view and seek to the given position.
 *
 * @param errorArgs       Array of strings for return code
 * @param tree_wid        Window ID of tree control to insert into
 * @param tree_index      tree index to insert under
 * @param tag_name        Name of occurrence to match against
 * @param case_sensitive  Case sensitive tag search?
 * @param file_name       Path of file tag to search for is in
 * @param line_no         Line number tag is located on
 * @param filter_flags    bitset of VS_TAGFILTER_*
 * @param src_file_name   name of source file to search
 * @param start_seekpos   starting seek position
 * @param stop_seekpos    ending seek position
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 * @param visited         (optional, reference) hash table of past tagging results 
 * @param depth           (optional) search depth, to cap recursion 
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagMatchOccurrencesInFile(VSHREFVAR errorArgs,
                            int tree_wid, int tree_index,
                            const char *tag_name, int case_sensitive,
                            const char *file_name, int line_no,
                            int filter_flags, const char *source_file_name,
                            int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                            int VSREF(num_matches), int max_matches,
                            VSHREFVAR visited VSDEFAULT(0), int depth VSDEFAULT(0));

/**
 * Use context_match tags to locate the tag matches for the
 * occurrence in the given file at the given seek position.
 * If a file name is not given, then use the current buffer.
 * If a file name is given, but the seek position is -1, then
 * use the current buffer position.  Otherwise, open the given
 * file in a temporary view and seek to the given position.
 *
 * @param errorArgs       Array of strings for return code
 * @param seekPositions   Array on ints for occurrence seek positions
 * @param tree_index      tree index to insert under
 * @param tag_name        Name of occurrence to match against
 * @param case_sensitive  Case sensitive tag search?
 * @param file_name       Path of file tag to search for is in
 * @param line_no         Line number tag is located on
 * @param filter_flags    bitset of VS_TAGFILTER_*
 * @param src_file_name   name of source file to search
 * @param start_seekpos   starting seek position
 * @param stop_seekpos    ending seek position
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success, <0 on error.
 */
EXTERN_C int VSAPI
vsTagMatchOccurrencesInFileGetPositions(VSHREFVAR errorArgs,
                            VSHREFVAR seekPositions,
                            const char *tag_name, int case_sensitive,
                            const char *file_name, int line_no,
                            int filter_flags, const char *source_file_name,
                            int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                            int VSREF(num_matches), int max_matches,
                            VSHREFVAR visited, int depth);

/**
 * Use context_match tags to locate the tag matches for the
 * occurrence in the given file at the given seek position.
 * If a file name is not given, then use the current buffer.
 * If a file name is given, but the seek position is -1, then
 * use the current buffer position.  Otherwise, open the given
 * file in a temporary view and seek to the given position.
 *
 * @param errorArgs       Array of strings for return code
 * @param tree_wid        Window ID of tree control to insert into
 * @param tree_index      tree index to insert under
 * @param case_sensitive  Case sensitive tag search?
 * @param file_name       Path of file tag to search for is in
 * @param line_no         Line number tag is located on
 * @param alt_file_name   Alternate path of file tag to search for is in
 * @param alt_line_no     Alternate line number tag is located on
 * @param filter_flags    bitset of VS_TAGFILTER_*
 * @param caller_id       Context ID for item to find uses in
 * @param start_seekpos   starting seek position
 * @param stop_seekpos    ending seek position
 * @param num_matches     (output) number of matches found
 * @param max_matches     maximum number of matches to find
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagMatchUsesInFile(VSHREFVAR errorArgs,
                     int tree_wid, int tree_index,
                     int case_sensitive,
                     const char *file_name, int line_no,
                     const char *alt_file_name, int alt_line_no,
                     int filter_flags, int caller_id,
                     const char *source_file_name,
                     int start_seekpos/*=0*/, int stop_seekpos/*=0*/,
                     int VSREF(num_matches), int max_matches);


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
 * @param normal_parents  list of normalized class names
 * @param max_parents_len number of bytes allocated to normal_parents
 * @param normal_types    list of tag types found for normalized class names
 * @param max_type_len    number of bytes allocated to normal_types
 * @param normal_files    list of tag files parent classes are found in
 * @param max_file_len    number of bytes allocated to normal_files
 * @param template_args   Slick-C&reg; hash table of template arguments
 * @param visited         Slick-C&reg; hash table of prior results
 * @param depth           depth of recursive search
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagNormalizeClasses(const char *class_parents,
                      const char *cur_class_name, const char *file_name,
                      VSHREFVAR tag_files, int allow_locals, int case_sensitive,
                      char *normal_parents, int max_parents_len,
                      char *normal_types VSDEFAULT(0), int max_type_len VSDEFAULT(0),
                      char *normal_files VSDEFAULT(0), int max_file_len VSDEFAULT(0),
                      VSHREFVAR template_args VSDEFAULT(0),
                      VSHREFVAR visited VSDEFAULT(0), int depth VSDEFAULT(0));

/**
 * Compare the two class names, ignore class and package separators.
 *
 * @param c1               first class name
 * @param c2               second class name
 * @param case_sensitive   compare names using a case sensitive algorithm?
 *
 * @return Returns <0 if the 'c1' is less than 'c2', 0 if they match,
 *         and >0 if 'c1' is greater than 'c2', much like strcmp().
 */
EXTERN_C int VSAPI
vsTagCompareClasses(const char *c1, const char *c2, bool case_sensitive VSDEFAULT(true));

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
 * if (num_matches >= max_matches) there may be more matches, but
 * the search terminated early.  Returns 1 if the definition of the given
 * class 'search_class' is found, othewise returns 0, indicating
 * that no matches were found.
 *
 * The current object must be an editor control or the current buffer.
 *
 * @param treewid         window id of tree control to insert into,
 *                        0 indicates to insert into a match set
 * @param tree_index      tree index to insert items under, ignored
 *                        if (treewid == 0)
 * @param tag_files       (reference to _str[]) tag files to search
 * @param prefix          symbol prefix to match
 * @param search_class    name of class to search for matches
 * @param pushtag_flags   VS_TAGFILTER_*, tag filter flags
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param num_matches     (reference) number of matches
 * @param max_matches     maximum number of matches allowed
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param depth           Recursive call depth, bails out at 32
 * @param find_all        find all instances, for each level of inheritance
 * @param template_args   Slick-C&reg; hash table of template arguments
 * @param friend_list     list of classes that are friendly with
 *                        the context the tags are being listed in
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 *
 * @return 1 if the definition of the symbol is found, 0 otherwise, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagListSymbolsInClass(int treewid, int tree_index, VSHREFVAR tag_files,
                        const char *prefix, const char *search_class,
                        int pushtag_flags, int context_flags,
                        int VSREF(num_matches), int max_matches,
                        int exact_match, int case_sensitive,
                        int depth VSDEFAULT(0), int find_all VSDEFAULT(1),
                        VSHREFVAR template_args VSDEFAULT(0),
                        const char *friend_list VSDEFAULT(0),
                        VSHREFVAR visited VSDEFAULT(0));

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
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return qualified name if successful, 'search_name' on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagQualifySymbolName(char *qualified_name, int qualified_max,
                       const char *search_name, 
                       const char *context_class,
                       const char *context_file, 
                       VSHREFVAR tag_files,
                       int case_sensitive,
                       VSHREFVAR visited VSDEFAULT(0), int depth VSDEFAULT(0) );

/**
 * Determine the name of the current class or package context.
 * The current object needs to be an editor control.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * and tag_lock_matches(true) prior to invoking this function.
 *
 * @param cur_tag_name    name of the current tag in context
 *                        (allocate VS_TAG_MAX_TAGNAME bytes)
 * @param cur_flags       type (VS_TAGTYPE_*) of the current tag
 * @param cur_type_name   type ID (VS_TAGTYPE_*) of the current tag
 *                        (allocate VS_TAG_MAX_TYPENAME bytes)
 * @param cur_type_id     bitset of VS_TAGFLAG_* for the current tag
 * @param cur_context     class name representing current context
 *                        (allocate VS_TAG_MAX_CLASSNAME bytes)
 * @param cur_class       cur_context minus the package name
 *                        (allocate VS_TAG_MAX_CLASSNAME bytes)
 * @param cur_package     only package name for the current context
 *                        (allocate VS_TAG_MAX_CLASSNAME bytes)
 *
 * @return 0 if no context, context ID >0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagGetCurrentContext(char *cur_tag_name, int VSREF(cur_flags),
                       char *cur_type_name, int VSREF(cur_type_id),
                       char *cur_context, char *cur_class,
                       char *cur_package);


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
 * @param pushtag_flags   VS_TAGFILTER_*, tag filter flags
 * @param context_flags   VS_TAGCONTEXT_*, tag context filter flags
 * @param exact_match     exact match or prefix match (0)
 * @param case_sensitive  case sensitive (1) or case insensitive (0)
 * @param strict          strict match, or allow any match?
 * @param find_parents    find parents of the given class?
 * @param find_all        find all instances, for each level of scope
 * @param search_file     file context to search for matches in (for imports) 
 * @param template_args   template arguments (Slick-C hash table) 
 * @param visited         (optional) Slick-C&reg; hash table of prior results
 * @param depth           (optional) depth of recursive search
 *
 * @return 0 on success, <0 on error.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagMatchSymbolInContext(const char *prefix, const char *search_class,
                          int treewid, int tree_index, VSHREFVAR tag_files,
                          int VSREF(num_matches),int max_matches,
                          int pushtag_flags, int context_flags,
                          int exact_match VSDEFAULT(0), int case_sensitive VSDEFAULT(1),
                          int strict VSDEFAULT(1),
                          int find_parents VSDEFAULT(0), int find_all VSDEFAULT(0),
                          const char *search_file VSDEFAULT(0),
                          VSHREFVAR template_args VSDEFAULT(0),
                          VSHREFVAR visited VSDEFAULT(0), int depth VSDEFAULT(0) );

/**
 * List any symbols, reguardless of context or scope
 * matching the given prefix expression.
 *
 * @param treewid          window id of tree control to insert into,
 *                         0 indicates to insert into a match set
 * @param tree_index       tree index to insert matches under
 * @param prefix           symbol prefix to match
 * @param tag_files        (reference to _str[]) tag files to search
 * @param pushtag_flags    VS_TAGFILTER_*, tag filter flags
 * @param context_flags    VS_TAGCONTEXT_*, tag context filter flags
 * @param num_matches      (reference) number of matches
 * @param max_matches      maximum number of matches allowed
 * @param exact_match      exact match or prefix match (0)
 * @param case_sensitive   case sensitive (1) or case insensitive (0)
 *
 * @return nothing.
 */
EXTERN_C
int VSAPI vsTagListAnySymbols(int treewid,int tree_index,
                              const char *prefix,VSHREFVAR tag_files,
                              int pushtag_flags,int context_flags,
                              int VSREF(num_matches),int max_matches,
                              int exact_match VSDEFAULT(0),
                              int case_sensitive VSDEFAULT(1));
/**
 * Create the canonical tag display string of the form:
 * <pre>
 *    tag_name<template_signature>(class_name:type_name)flags(signature)return_type
 * </pre>
 * <p>
 * This is used to speed up find-tag and maketags for languages that
 * do not insert tags from DLLs.
 *
 * @param proc_name       output string for "composed" tag
 * @param proc_name_max   number of bytes allocated to proc_name
 * @param tag_name        the name of the tag
 * @param class_name      class/container the tag belongs to
 * @param type_name       the tag type, (see VS_TAGTYPE_*)
 * @param tag_flags       (optional) integer tag flags (see VS_TAGFLAG_*)
 * @param signature       (optional) function signature
 * @param return_type     (optional) function return type
 * @param template_signature (optional) template signature
 *
 * @return nothing.
 *
 * @categories Tagging_Functions
 */
EXTERN_C void VSAPI
vsTagComposeTag(char *proc_name, int proc_name_max,
                const char *tag_name, const char *class_name,
                const char *type_name, int tag_flags VSDEFAULT(0),
                const char *signature VSDEFAULT(0),
                const char *return_type VSDEFAULT(0),
                const char *template_signature VSDEFAULT(0));

/**
 * Decompose the canonical tag display string of the form:
 * <pre>
 *    tag_name<template_signature>(class_name:type_name)flags(signature)return_type
 * </pre>
 * <p>
 * This is used to speed up find-tag and maketags for languages that
 * do not insert tags from DLLs.
 * All output strings are set to the empty string if they do not match,
 * tag_flags is set to 0 if there is no match.
 *
 * @param pszProcName     tag display string
 * @param pszTagName      (reference) the name of the tag
 * @param pszClassName    (reference) class/container the tag belongs to
 * @param pszTypeName     (reference) the tag type, (see VS_TAGTYPE_*)
 * @param tag_flags       (reference) integer tag flags (see VS_TAGFLAG_*)
 * @param pszSignature    (optional reference) arguments/signature of tag
 * @param pszReturnType   (optional reference) return type / value of tag
 * @param pszTmplSignature (optional) template signature
 *
 * @return 0 on success.
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagDecomposeTag(const char *pszProcName, char *pszTagName,
                  char *pszClassName, char *pszTypeName,
                  int VSREF(tag_flags),
                  char *pszSignature VSDEFAULT(0),
                  char *pszReturnType VSDEFAULT(0),
                  char *pszTmplSignature VSDEFAULT(0));

/**
 * Return the string associated with the standard tag type ID
 *
 * @param type_id tag type ID
 *
 * @return 0 if type_id is not a registered type. "" if (type_id == 0).
 *
 * @categories Tagging_Functions
 */
EXTERN_C VSPSZ VSAPI
vsTagGetType(int type_id);


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
 * @param arg_max       number of byte allocated to 'argument'
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
EXTERN_C int VSAPI
vsTagGetNextArgument(const char *params, int *arg_pos,
                     char *argument, int arg_max,
                     const char *ext VSDEFAULT(0));

/**
 * Does the current source language match or
 * inherit from the given language?
 * <p>
 * If 'lang' is not specified, the current object must be an 
 * editor control. 
 *
 * @param parent     extension to compare to
 * @param lang       current source language
 *                   (default={@link p_LangId})
 *
 * @return 'true' if the extension matches, 'false' otherwise.
 *
 * @categories Tagging_Functions 
 * @deprecated use {@link vsLanguageInheritsFrom()} 
 */
EXTERN_C int VSAPI
vsTagExtInheritsFrom(const char *parent, const char *lang VSDEFAULT(0));

/**
 * Look up 'symbol' and see if it is a package, namespace, module or unit.
 * <p> 
 * For synchronization, threads should perform a tag_lock_context(false) 
 * and tag_lock_matches(true) prior to invoking this function.
 *
 * @param symbol           current symbol to look for
 * @param tag_files        (reference to _str[]) list of tag files to search
 * @param exact_match      look for exact match rather than prefix match
 * @param case_sensitive   case sensitive comparison? 
 * @param aliased_to       set to namespace alias name, if applicable 
 * @param aliased_to_len   number of bytes allocated to 'aliased_to' 
 *
 * @return >0 if 'symbol' or prefix of matches package, otherwise returns 0.
 *         A value of 1 indicates the item was found in a tag file, a value of
 *         greater than 1 indicates that that item was found in the context.
 *
 * @categories Tagging_Functions
 */
EXTERN_C
int vsTagCheckForPackage(const char* symbol, VSHREFVAR tag_files,
                         int exact_match, int case_sensitive,
                         char *aliased_to VSDEFAULT(0), int aliased_to_len VSDEFAULT(0));

/**
 * Find all the classes which are friendly towards the given tag
 * name or it's class or outer classes.
 *
 * @param szCurTagName     tag to find friends to
 * @param szCurClassName   class to find friends to
 * @param tag_files        list of tag files to search
 * @param szFriendList     (reference) set to list of friends,
 *                         separated by {@link VS_TAGSEPARATOR_parents}
 * @param maxFriendList    number of bytes allocated to szFriendList
 *
 * @return 0 on success, <0 on error.
 *         Having no friends is considered as a success.
 *
 * @see vsTagListSymbolsInClass
 * @see vsTagCheckFriendRelationship
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagFindFriendsToTag(const char *szCurTagName, const char *szClassName,
                      VSHREFVAR tag_files, char* szFriendList, int maxFriendList);

/**
 * Find all the friends of the given class in the current context
 * and tag files.
 *
 * @param szClassName      class to find friends of
 * @param tag_files        list of tag files to search
 * @param szFriendList     (reference) set to list of friends,
 *                         separated by {@link VS_TAGSEPARATOR_parents}
 * @param maxFriendList    number of bytes allocated to szFriendList
 *
 * @return 0 on success, <0 on error.
 *         Having no friends is considered as a success.
 *
 * @see vsTagListSymbolsInClass
 * @see vsTagCheckFriendRelationship
 *
 * @categories Tagging_Functions
 */
EXTERN_C int VSAPI
vsTagFindFriendsOfClass(const char *szClassName, VSHREFVAR tag_files,
                        char* szFriendList, int maxFriendList);

/**
 * @return
 * Returns true if the given given class is among the friends on the
 * given friend list.  Otherwise it returns false.  Since this language
 * feature is specific to C++, the check is always case sensitive.
 *
 * @param szClassName      class which tag is coming from
 * @param szFriendList     list of classes that are friendly to our context
 *
 * @see vsTagFindFriendsToTag
 * @see vsTagFindFriendsOfClass
 *
 * @categories Tagging_Functions
 */
EXTERN_C bool VSAPI
vsTagCheckFriendRelationship(const char *szClassName, const char *szFriendList);

///////////////////////////////////////////////////
// Utility routines for SlickEdit Tools
//////////////////////////////////////////////////

/**
 * Returns # of location entries
 *
 * @return int VSAPI
 */
EXTERN_C int VSAPI
vsTagLocationGetCount();

/**
 * Returns information about the given location entry
 *
 * @param index 0-based index
 * @param fileName Pass in a char array and make sure it's allocated to something large enough
 * @param caption
 * @param lineNum Output line #
 * @param columnNum Output column #
 * @param tagTypeName Output name of tag type
 *
 * @return int VSAPI 0 on success; anything else indicates failure
 */
EXTERN_C int VSAPI
vsTagLocationGetInfo(int index, char *fileName, char *caption, int &lineNum, int &columnNum, char *tagTypeName);

///////////////////////////////////////////////////
// End utility routines for SlickEdit Tools
//////////////////////////////////////////////////

/**
 * Queue an asynchronous tagging target to be started in the background.
 */
EXTERN_C int VSAPI vsTagQueueAsyncTarget(const slickedit::SEListTagsTarget &context);

/**
 * Queue an asynchronous tagging target which is already completed.
 */
EXTERN_C int VSAPI vsTagQueueFinishedTarget(const slickedit::SEListTagsTarget &context);

/**
 * Cancel an asynchronous tagging target if we are about to tag the same 
 * item synchronously. 
 */
EXTERN_C int VSAPI vsTagCancelAsyncTarget(const slickedit::SEListTagsTarget &context);

/**
 * Completely shut down all asynchronous tagging operations which are 
 * currently going on. 
 */
EXTERN_C void VSAPI vsTagStopAsyncTagging();
/**
 * Restart the background tagging threads if they are not already running.
 */
EXTERN_C void VSAPI vsTagRestartAsyncTagging();

/**
 * Return the number of background tagging jobs queued, finished, and running. 
 * 
 * @param jobKind    The kind of job to return the number of. 
 *                   Currently, only "A" (All) is supported. 
 *                   <ul>
 *                   <li>"A" for all jobs
 *                   <li>"U" for unfinished jobs
 *                   <li>"Q" for just queued jobs
 *                   <li>"D" for jobs waiting for database insert
 *                   <li>"F" for finished jobs
 *                   <li>"R" for running jobs
 *                   <li>"L" for jobs waiting for file to be read from disk
 *                   <li>"T" for the number of threads running 
 *                   </ul>
 * 
 * @return int 
 */
EXTERN_C int VSAPI vsTagGetNumAsyncTaggingJobs(VSPSZ jobKind);

#endif
