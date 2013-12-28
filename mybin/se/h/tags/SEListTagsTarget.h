////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef SLICKEDIT_LIST_TAGS_TARGET_H
#define SLICKEDIT_LIST_TAGS_TARGET_H

// File:          SEListTagsTarget.h
// Description:   Declaration of class for collecting symbol information.

#include "vsdecl.h"
#include "tagsmain.h"
#include "tags/SETagInformation.h"
#include "slickedit/SEString.h"

namespace slickedit {

enum SEEmbeddedTaggingOption
{
   // collate all sections with this language ID and parse as one section
   SE_EMBEDDED_COLLATE_AND_TAG,
   // parse each one of these sections individually
   SE_EMBEDDED_TAG_INDIVIDUALLY,
   // parse this embedded section immediately, return error if not possible
   SE_EMBEDDED_TAG_IMMEDIATELY,
   // do not parse this embedded section
   SE_EMBEDDED_DO_NOT_TAG
};

/**
 * This class is used to represent a target for a parsing operation. 
 * <p> 
 * A parsing operation can target either writing to a tag database, 
 * writing to the current context or locals, or assembling a list of 
 * symbols to be written to a tag database later. 
 *  
 * @see SETagInformation 
 */ 
class VSDLLEXPORT SEListTagsTarget : public SEMemory 
{
public:
   /**
    * Default constructor
    */
   SEListTagsTarget();

   /**
    * Simple constructor 
    *  
    * @param fileName      name of file which we are tagging 
    * @param taggingFlags  bitset of VSLTF_* 
    * @param bufferId      buffer ID if tagging from an editor control 
    * @param tagDatabase   name and path of tag database to update 
    * @param startLine     first line to begin parsing on (for local variables) 
    * @param startSeekPos  seek position to start parsing at 
    * @param stopLine      last line to stop parsing at (for local variables) 
    * @param stopSeekPos   seek position to stop parsing at 
    * @param currentLine    line number cursor when parsing starts 
    * @param currentSeekPos position of cursor when parsing starts 
    * @param contextId      context Id of symbol being parsed for locals 
    */
   SEListTagsTarget(const SEString &fileName, 
                    const unsigned int taggingFlags = 0,
                    const unsigned int bufferId = 0,
                    const SEString &tagDatabase = (const char *)0,
                    const unsigned int startLine = 0,
                    const unsigned int startSeekPosition = 0,
                    const unsigned int stopLine = 0,
                    const unsigned int stopSeekPosition = 0,
                    const unsigned int currentLine = 0,
                    const unsigned int currentSeekPosition = 0,
                    const unsigned int contextId = 0);

   /**
    * Copy constructor
    */
   SEListTagsTarget(const SEListTagsTarget& src);

   /**
    * Destructor
    */
   virtual ~SEListTagsTarget();

   /**
    * Assignment operator
    */
   SEListTagsTarget &operator = (const SEListTagsTarget &src);

   /**
    * Comparison operators
    */
   bool operator == (const SEListTagsTarget &lhs) const;
   bool operator != (const SEListTagsTarget &lhs) const;

   /**
    * Hash function for using in SEHashSet 
    */
   unsigned int hash() const;

   /** 
    * Based on the arguments passed into a list-tags or list-locals function, 
    * get the buffer contents and information such as the start and stop 
    * seek position, initial line number and tagging flags, and store that 
    * information within this object. 
    * <p>
    * NOTE: This function is NOT thread-safe. 
    *  
    * @param fileName      name of buffer passed to list-tags function 
    * @param langId        language ID to parse file using 
    * 
    * @return 0 on success, <0 on error. 
    */
   int getListTagsBufferInformation(const SEString &fileName,
                                    const SEString &langId);

   /** 
    * Set up this tagging target to tag the given file on disk using 
    * the language specified's tagging target. 
    * <p>
    * NOTE: This function is thread-safe. 
    *  
    * @param tagDatabase   name and path of tag database to update 
    * @param fileName      name of buffer passed to list-tags function 
    * @param langId        language ID to parse file using 
    * @param taggingFlags  bitset of VSLTF_* 
    * 
    * @return 0 on success, <0 on error. 
    */
   int setListTagsFileInformation(const SEString &tagDatabase,
                                  const SEString &fileName,
                                  const SEString &langId,
                                  unsigned int taggingFlags = 0);

   /**
    * Set up information for doing an incremental update of the 
    * tags for the current buffer. 
    *  
    * @param startOffset      position to start parsing at 
    * @param endOffset        position to finish parsing at 
    * @param numBytesInserted the number or bytes inserted or deleted 
    *                         from the buffer (&lt;0 for deleted bytes) 
    * @param className        class scope to start parsing in 
    *  
    * @return 0 on success, <0 on error.
    */
   int setIncrementalBuffer(const unsigned int startOffset,
                            const unsigned int endOffset,
                            const int numBytesInserted,
                            const SEString &className);

   /**
    * Generic function for listing tags in the given file and language. 
    * You must first call getListTagsBufferInformation() or otherwise 
    * set up the context information, including the filename and language ID. 
    *  
    * return 0 on success, <0 on error. 
    */
   int doGenericListTags();

   /**
    * Return the full, absolute file path for the file being parsed.
    */
   const SEString &getFileName() const;
   /**
    * Set the full, absolute file path for the file being parsed.
    */
   void setFileName(const SEString &fileName);

   /**
    * Return the language ID for the tagging callback. 
    * <p> 
    * Because of tagging callback inheritance, this may not be the actual 
    * langauge ID, it may be the language ID of a parent language whose callback 
    * we are using. 
    */
   const SEString &getLanguageId() const;
   /**
    * Set the language ID for the tagging callback.
    */
   void setLanguageId(const SEString &langId);

   /**
    * Return the class scope in effect for incremental parsing 
    * to update just part of the current context.
    */
   const SEString &getIncrementalClassName() const;
   /**
    * Set the class scope in effect for incremental parsing 
    * to update just part of the current context.
    */
   void setIncrementalClassName(const SEString &className);

   /**
    * Add the given file to the list of files which are 
    * considered as include files or sub-files but that were tagged
    * independently, so they should be factored out of the results 
    * when we updated tagging for this file. 
    */
   int addNestedFile(const SEString &fileName);

   /**
    * Save the token information for the given token.
    * 
    * @param tokenInfo     token information
    * 
    * @return 0 on success, <0 on error.
    */
   int addToken(const class SETokenReadInterface &tokenInfo,
                slickedit::SETokenID *pTokenID=NULL);
   int addToken(const class SETokenStruct &tokenInfo,
                slickedit::SETokenID *pTokenID=NULL);
   /**
    * Save line break information.
    */
   int addLineBreak(const unsigned int lineNumber,
                    const unsigned int seekPosition);

   /**
    * Set up to start inserting tokens for an preprocessed section starting 
    * at the first given token and ending with the last token, inclusive. 
    * This will call beginInsert() to prepare the token list for inserts. 
    * 
    * @param firstTokenID     unique ID of first token in preprocessed section
    * @param lastTokenID      unique ID of last token in preprocessed section
    * @param fileName         file name of source of preprocessed text
    * @param fileBufferID     buffer buffer ID for preprocessed text
    * @param startOffset      start offset within file containing preprocessed text
    * @param startLineNumber  start line number of preprocessed text
    * @param startLineOffset  start line offset of preprocessed text
    * @param newText          preprocessed text to begin parsing
    * 
    * @return 0 on success, <0 on error 
    */
   int pushPreprocessedSection(const SETokenID firstTokenID, 
                               const SETokenID lastTokenID,
                               const SEString &fileName,
                               const int fileBufferID,
                               const unsigned int startOffset,
                               const unsigned int startLineNumber,
                               const unsigned int startLineOffset,
                               const SEString &newText);

   /**
    * Finish parsing an preprocessed code section.  This will call endInsert() 
    * to commit the changes to the token list, and pop the token list off of 
    * the parse stack. 
    * 
    * @return 0 on success, <0 on error 
    */
   int popPreprocessedSection();

   /**
    * Return the date of the file at the time it was parsed.
    */
   const VSINT64 getFileDate() const;
   /**
    * Set the date of the file at the time it was parsed. 
    * <p> 
    * The file date is a binary date string, as returned by p_file_date. 
    */
   void setFileDate(const VSINT64 fileDate);

   /**
    * Return the date of the file at the time it was last tagged.
    */
   const VSINT64 getTaggedDate() const;
   /**
    * Set the date of the file at the time it was last tagged. 
    * <p> 
    * The file date is a binary date string, as returned by p_file_date. 
    */
   void setTaggedDate(const VSINT64 fileDateInDatabase);

   /**
    * Return the buffer ID for the file being parsed.
    */
   const unsigned int getBufferId() const;
   /**
    * Save the buffer ID for the file being parsed.
    */
   void setBufferId(const unsigned int bufferId);

   /**
    * Return the generation counter indicating when the buffer was last modified 
    * at the time in which it was parsed. 
    */
   const unsigned int getBufferLastModified() const;
   /**
    * Save the generation counter indicating when the buffer was last modified 
    * at the time in which it was parsed. 
    */
   void setBufferLastModified(const unsigned int lastModified);

   /**
    * Return the buffer modify flags at the time in which it was parsed. 
    */
   const unsigned int getBufferModifyFlags() const;
   /**
    * Save the buffer modify flags at the time in which it was parsed. 
    */
   void setBufferModifyFlags(const unsigned int modifyFlags);

   /**
    * Set the file/buffer information for the file being parsed.
    */
   void setFileInformation( const SEString &fileName,
                            const VSINT64 fileDate,
                            const unsigned int bufferId=0,
                            const unsigned int lastModified=0,
                            const unsigned int modifyFlags=0 );

   /**
    * Set the file encoding flag for loading this file buffer from disk. 
    * This should be one of VSENCODING_AUTO*, usually VSENCODING_AUTOXML. 
    */
   void setFileEncoding(int encoding);

   /**
    * Return the file contents which we are going to be parsing.
    */
   const SEString &getFileContents() const;
   /**
    * Save the file contents for the buffer or file we will be parsing.
    */
   void setFileContents(const SEString &fileContents);
   /**
    * Load the file contents from disk (for asynchronous parsing)
    */
   int loadFileContents();

   /**
    * @return Return a pointer to the token list for this file. 
    */
   const SETokenList *getTokenList() const;
    
   /**
    * Return the line number to start parsing at.
    */
   const unsigned int getParseStartLineNumber() const;
   /**
    * Set the line number to start parsing at.  Default is 0. 
    */
   void setParseStartLineNumber(const unsigned int lineNumber);

   /**
    * Return the seek position to start parsing at.
    */
   const unsigned int getParseStartSeekPosition() const;
   /**
    * Set the seek position to start parsing at.  Default is 0. 
    */
   void setParseStartSeekPosition(const unsigned int seekPos);

   /**
    * Set the seek position and line number to start parsing at. 
    */
   void setParseStartLocation(const unsigned int seekPos, const unsigned int lineNumber);

   /**
    * Return the line number to stop parsing at or near. 
    * The actual position the parse stops searching for locals at can 
    * vary depending on language specific scoping rules. 
    */
   const unsigned int getParseStopLineNumber() const;
   /**
    * Set the seek position to stop parsing at.  Default is 0, which 
    * means to parse to the end of the file. 
    */
   void setParseStopLineNumber(const unsigned int lineNumber);

   /**
    * Return the seek position to stop parsing at or near. 
    * The actual position the parse stops searching for locals at can 
    * vary depending on language specific scoping rules. 
    */
   const unsigned int getParseStopSeekPosition() const;
   /**
    * Set the seek position to stop parsing at.  Default is 0, which 
    * means to parse to the end of the file. 
    */
   void setParseStopSeekPosition(const unsigned int seekPos);

   /**
    * Set the seek position and line number to stop parsing at. 
    */
   void setParseStopLocation(const unsigned int seekPos, const unsigned int lineNumber);

   /**
    * Return the line number where the cursor is sitting when this local 
    * variable tagging job starts.
    */
   const unsigned int getParseCurrentLineNumber() const;
   /**
    * Set the line number where the cursor is sitting when this local 
    * variable tagging job starts.
    */
   void setParseCurrentLineNumber(const unsigned int lineNumber);

   /**
    * Return the seek position where the cursor is sitting when this local 
    * variable tagging job starts.
    */
   const unsigned int getParseCurrentSeekPosition() const;
   /**
    * Set the seek position where the cursor is sitting when this local 
    * variable tagging job starts.
    */
   void setParseCurrentSeekPosition(const unsigned int seekPos);

   /**
    * Set the seek position and line number where the cursor is 
    * sitting when this local variable tagging job starts.
    */
   void setParseCurrentLocation(const unsigned int seekPos, const unsigned int lineNumber);

   /**
    * Return the context ID of the symbol being parsed for local variables. 
    */
   const unsigned int getParseCurrentContextId() const;
   /**
    * Set the context ID of the symbol being parsed for local variables. 
    */
   void setParseCurrentContextId(const unsigned int contextId);

   /**
    * Return the tagging mode flags.  This is a bitset of the constants VSLTF_* 
    * <p> 
    * There are three general tagging modes possible: 
    * <ul> 
    *    <li><b>context</b>  -- load the tags and statement information for the current buffer
    *    <li><b>locals</b>   -- parse for local variables in the current function context
    *    <li><b>database</b> -- parse for tags and references to update the current buffer in the tag database
    * </ul> 
    */
   const unsigned int getTaggingFlags() const;
   /**
    * Set the tagging mode flags.  This is a bitset of the constants VSLTF_*
    * <p> 
    * There are three general tagging modes possible: 
    * <ul> 
    *    <li><b>context</b>  -- load the tags and statement information for the current buffer
    *    <li><b>locals</b>   -- parse for local variables in the current function context
    *    <li><b>database</b> -- parse for tags and references to update the current buffer in the tag database
    * </ul> 
    */
   void setTaggingFlags(const unsigned int ltfFlags);


   /**
    * Return the full, absolute file path to the tagging database to be updated.
    */
   const SEString &getTagDatabase() const;
   /**
    * Return the full, absolute file path to the tagging database to be updated.
    */
   void setTagDatabase(const SEString &fileName);

   /**
    * Return 'true' if the tagging target is to insert tags into a tag database.
    */
   bool isTargetDatabase() const;
   void setTargetDatabase();

   /**
    * Return 'true' if the tagging target is to update the tags found in 
    * the current file. 
    */
   bool isTargetContext() const;
   void setTargetContext();
   void setTargetStatements();

   /**
    * Return 'true' if the tagging target is to update the current list of 
    * local variables. 
    */
   bool isTargetLocals() const;
   void setTargetLocals();


   /**
    * Return 'true' if the tagging job is currently running. 
    */
   bool isTargetRunning() const;
   /**
    * Indicate that the target is being operated on by a thread. 
    */
   void setTargetRunning();
   /**
    * Indicate that the target is no longer being operated on by a thread
    */
   void setTargetIdle();
   /**
    * Return '1' if the tagging job is completely finished 
    * and the context, locals, statements, or tag database have also 
    * been updated (on the thread). 
    * <p> 
    * Return EMBEDDED_TAGGING_NOT_SUPPORTED_RC if the tagging job is 
    * not finished and the context, locals, or tag database still need 
    * to be updated synchronously.  This is typically because the file 
    * contains embedded code. 
    * <p> 
    * Return an error code <0 if the file can not be tagged in the 
    * background, either because it's language does not support background 
    * tagging, or because the file does not exist. 
    */
   int isUpdateFinished() const;
   /** 
    * Flag target to indicate that file corresponding to the tagging job 
    * is being read from disk.
    */
   void setFileReadingRunning();
   /** 
    * Flag target to indicate that file corresponding to the tagging job 
    * has been read from disk.
    */
   void setFileReadingFinished();
   /** 
    * Flag target to indicate that the parsing job has started running.
    */
   void setParsingRunning();
   /** 
    * Flag target to indicate that tagging job has finished 
    * parsing, but it still needs to insert tags in the database.
    */
   void setParsingFinished();
   /** 
    * Flag target to indicate that tagging job has started running.
    */
   void setTaggingRunning();
   /** 
    * Flag target to indicate that tagging job has completely finished.
    */
   void setTaggingFinished();
   /**
    * Return 'true' if the tagging job is completely finished. 
    */
   bool isTaggingFinished() const;
   /**
    * Flag target to indicate that the tagging job is completely finished, 
    * including updating the context, locals, statements, or tag database. 
    * <p> 
    * Pass in a FILE_NOT_FOUND_RC to indicate that the file does not exist 
    * and that it was removed from the tag file. 
    * <p> 
    * Pass in BACKGROUND_TAGGING_NOT_SUPPORTED_RC to indicate that the file does 
    * not support background tagging and needs to be tagged synchronously. 
    * <p> 
    * Pass in EMBEDDED_TAGGING_NOT_SUPPORTED_RC to indicate that the file 
    * has been parsed and contains embedded sections which need to be 
    * tagged synchronously. 
    * <p> 
    * Pass in a status < 0 to indicate that the file could not be tagged 
    * in the background. 
    */
   void setUpdateFinished(int status=1);

   /**
    * Indicate that a tagging remove was started for this file. 
    * At this time, this only effects tagging logging.
    */
   void setTaggingRemoveStarted();
   /**
    * Indicate that a tagging remove is finished for this file. 
    * At this time, this only effects tagging logging.
    */
   void setTaggingRemoveFinished(int status=0);

   /**
    * Set a specific message code for this job.  This is used to differentiate 
    * this job from others with the same filename and a different message code.
    */
   void setMessageCode(int status);
   /**
    * Return the specific message code for this job.
    */
   int getMessageCode() const;

   /**
    * Set a flag to indicate that this item is the last one to be finished 
    * in a multi-part tag file build. 
    */
   void setLastItemScheduled(bool isLastItem=true);
   /**
    * Is this tagging target the last item of a multi-part tag file build?
    */
   bool isLastItemScheduled() const;

   /**
    * Return 'true' if statement tagging is supported for this language.
    */
   bool isStatementTaggingSupported() const;
   /**
    * Return 'true' if local variable tagging is supported for this language.
    */
   bool isLocalTaggingSupported() const;
   /**
    * Flag target to indicate that statement tagging is supported for this language.
    */
   void setStatementTaggingSupported();
   /**
    * Flag target to indicate that local variable tagging is supported for this language.
    */
   void setLocalTaggingSupported();


   /**
    * If we are tagging the current context, return 'true' if statement-level 
    * tagging is enabled and we should insert tags for control statements. 
    */
   bool getStatementTaggingMode() const;

   /**
    * If we are inserting tags into a tag database, return 'true' if we need 
    * to list occurrences of identifiers for building the symbol cross-reference. 
    */
   bool getListOccurrencesMode() const;

   /**
    * If we are tagging the current context, return true if we are 
    * also saving the token list for the current context.  
    */
   bool getSaveTokenListMode() const;
    
   /**
    * If we are tagging the current context, return true if we are 
    * incrementally tagging only the section of the buffer that has changed. 
    */
   bool getIncrementalMode() const;
    
   /**
    * Return 'true' if listing local variables and we should skip locals which 
    * have fallen out of scope per the language specific local variable 
    * scoping rules. 
    */
   bool getSkipOutOfScopeLocals() const;

   /**
    * Return 'true' if listing local variables and we need to start right 
    * from where the cursor is located rather than parsing from the beginning 
    * of a function. 
    */
   bool getStartLocalsInCode() const;

   /** 
    * Return 'true' if we are reading input data from a string rather than 
    * a file or an editor buffer. 
    */
   bool getReadFromStringMode() const;
   /** 
    * Return 'true' if we are reading input data from an editor control
    */
   bool getReadFromEditorMode() const;
   /** 
    * Return 'true' if we are reading input data from a file.
    */
   bool getReadFromFileMode() const;

   /**
    * Return 'true' if the tagging information is being updated asynchronously. 
    */
   const bool getAsynchronousMode() const;
   /**
    * Turn on asynchronous tagging.  This can only be done as an initial setup, 
    * not after parsing and tagging has already started. 
    */
   void setAsynchronousMode(const bool async);

   /**
    * Parse the contents of the current file for tags. 
    * This will call the parsing callback function configured for this object. 
    */
   int parseFileForTags();

   /**
    * Typedef for type of the parsing function callback.
    */
   typedef int (*ParsingCallbackType)(SEListTagsTarget &context);

   /**
    * Set a callback function for listing tags from the current file.
    */
   void setParsingCallback(ParsingCallbackType parseFun);
   /**
    * Check if we have a parsing callback for this target language. 
    * You must set the target language first. 
    */
   bool hasParsingCallback() const;
   static bool hasParsingCallback(const SEString &langId);
   /**
    * Register a callback function for listing tags for the given language type.
    */
   static int registerParsingCallback(const char *langId, ParsingCallbackType parseFun); 
   /**
    * Clear out all parsing callbacks (this is done to reset the DLL).
    */
   static int clearRegisteredParsingCallbacks();

   /**
    * If tagging is writing to a tagging database, make sure the database 
    * is open for writing. 
    *  
    * @return 0 on success, <0 on error. 
    */
   int openTagDatabase();
   /**
    * Close the tag database (actually, just switch to read mode) after we are 
    * finished writing to an open tag database. 
    *  
    * @return 0 on success, <0 on error. 
    */
   int closeTagDatabase();

   /**
    * Merge the tagging information from the given file into this items 
    * tagging information. 
    * 
    * @param context 
    * 
    * @return 0 on success, <0 on error. 
    */
   int mergeTarget(const SEListTagsTarget &context);

public:

   /**
    * Insert a tag into the list of tags collected.
    * <p> 
    * Depending on the tagging mode, and whether we are doing synchronous 
    * or asynchronous tagging, this will either insert an item into the current 
    * context, the locals, the tag database, or cache the information to be 
    * inserted synchronously into the database later.
    * 
    * @param tagInfo    symbol information to add to the context. 
    * 
    * @return >= 0 on success, <0 on error. 
    *         If tagging locals or the current context, this will return
    *         the context ID or local ID on success. 
    */
   int insertTag(const SETagInformation &tagInfo);

   /**
    * Insert a tag into the list of tags collected.
    * <p> 
    * Depending on the tagging mode, and whether we are doing synchronous 
    * or asynchronous tagging, this will either insert an item into the current 
    * context, the locals, the tag database, or cache the information to be 
    * inserted synchronously into the database later.
    * 
    * @param tagName             symbol name
    * @param tagClass            current package and class name
    * @param tagType             type of symbol (VS_TAGTYPE_*)
    * @param tagFlags            tag flags (bitset of VS_TAGFLAG_*)
    * @param fileName            name of file being tagged 
    * @param startLineNumber     start line number        
    * @param startSeekPosition   start seek position      
    * @param nameLineNumber      name line number         
    * @param nameSeekPosition    name seek position       
    * @param scopeLineNumber     scope start line number  
    * @param scopeSeekPosition   scope start seek position
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    * @param tagSignature        function return type and arguments
    * @param classParents        parents of class (inheritance)
    * @param templateSignature   template signature for template classes and functions
    * @param tagExceptions       function exceptions clause
    * 
    * @return >= 0 on success, <0 on error. 
    *         If tagging locals or the current context, this will return
    *         the context ID or local ID on success. 
    */
   int insertTag(const SEString &tagName,
                 const SEString &tagClass,
                 unsigned short tagType,
                 unsigned int tagFlags,
                 const SEString &fileName,
                 unsigned int startLineNumber, unsigned int startSeekPosition,
                 unsigned int nameLineNumber,  unsigned int nameSeekPosition,
                 unsigned int scopeLineNumber, unsigned int scopeSeekPosition,
                 unsigned int endLineNumber,   unsigned int endSeekPosition,
                 const SEString &tagSignature = (const char *)0,
                 const SEString &classParents = (const char *)0,
                 const SEString &templateSignature = (const char *)0, 
                 const SEString &tagExceptions = (const char *)0 ); 

   /**
    * Returns negative status or error code if there was an error status 
    * returned by insertTag() when inserting tags into a tagging database. 
    */
   const int getInsertTagStatus() const;
   void setInsertTagStatus(const int status);

   /**
    * Return the number of tags collected.
    */
   const size_t getNumTags() const;

   /**
    * Return the n'th tag collected, starting with 0 for the first tag.
    * Return NULL if there is no such tag. 
    */
   const SETagInformation *getTagInfo(size_t tagIndex) const;

   /**
    * Insert an embedded code section found in the current tagging target.
    * 
    * @param startLineNumber  start line number of embedded section
    * @param startSeekPosition   start seek position      
    * @param endLineNumber    end line number of embedded section
    * @param endSeekPosition     end seek position        
    * @param fileName            name of file being tagged 
    * @param langId              language ID for embedded code 
    * @param parseOption         collate, tag later, tag now, or ignore? 
    * 
    * @return 0 on success, <0 on error. 
    */
   int insertEmbeddedSection(unsigned int startLineNumber,
                             unsigned int startSeekPosition,
                             unsigned int endLineNumber,
                             unsigned int endSeekPosition,
                             const SEString &fileName,
                             const SEString &langId = (const char *)0,
                             const SEEmbeddedTaggingOption parseOption = SE_EMBEDDED_COLLATE_AND_TAG);

   /**
    * @return Return the number of embedded sections in the current context.
    */
   size_t getNumEmbeddedSections() const;

   /**
    * @return Return the number of embedded sections in the current context.
    */
   size_t getNumUnparsedEmbeddedSections() const;


   /**
    * Returns info for the embedded section indexed by 'index'
    *  
    * @param index            index of embedded section 
    *                         [0..getNumEmbeddedSections()]
    * @param startLineNumber  start line number of embedded section
    * @param endLineNumber    end line number of embedded section
    * @param startSeekPosition start seek position
    * @param endSeekPosition  end seek position
    * @param langid           language ID for embedded code
    * @param parseOption      collate, tag, or ignore? 
    * @param taggingFinished  does this section still require tagging?
    */
   void getEmbeddedSectionInfo(size_t index,
                               unsigned int& startLineNumber,
                               unsigned int& endLineNumber,
                               unsigned int& startSeekPosition,
                               unsigned int& endSeekPosition,
                               SEString& langid,
                               SEEmbeddedTaggingOption &parseOption,
                               bool &taggingFinished);

   /**
    * Insert information about the date of an included file. 
    * 
    * @param fileName         name of file to insert file date information for
    * @param fileDate         date of the file (17 character string)
    * @param parentFileName   name of source file this was included by
    * @param fileType         type of file (include, source, or references)
    * 
    * @return 0 on success, <0 on error. 
    */
   int insertFileDate(const SEString &fileName,
                      const VSINT64 fileDate,
                      const SEString &parentFileName,
                      unsigned int fileType=VS_FILETYPE_include);

   /**
    * Return 'true' if this tagging target should stop parsing now 
    * because the tagging job was cancelled. 
    */
   bool isTargetCancelled() const;
   /**
    * Indicate that tagging needs to be stopped because we are aborting 
    * this tagging operation. 
    */
   void cancelTarget();

   /**
    * Turn on tagging logging for this item.
    */
   void enableTaggingLogging();

   /**
    * Return 'true' if tagging logging is turned on.
    */
   bool isTaggingLogging() const;

   /**
    * Returns 'true' if the tagging should allow dupliate global 
    * declarations (variables with the same name in the same scope). 
    * <p> 
    * If this option is disabled, then only the first variable with a 
    * unique name will be retained. 
    */
   const bool allowDuplicateGlobalVariables() const;
   void setAllowDuplicateGlobalVariables(const bool onOff);

   /**
    * Returns 'true' if the tagging should allow dupliate local 
    * declarations (local variables with the same name). 
    * <p> 
    * If this option is disabled, then only the first variable with a 
    * unique name will be retained. 
    */
   const bool allowDuplicateLocalVariables() const;
   void setAllowDuplicateLocalVariables(const bool onOff);

   /**
    * Set's the last local variable ID.
    */
   void setLastLocalVariableId(unsigned int localId);

   /**
    * Add the given identifier to the list of identifiers
    * 
    * @return 0 on success, <0 on error.
    */
   int insertIdOccurrence(const SEString &idName);
   int insertIdOccurrence(const SEString &idName, const SEString &fileName);


   /**
    * Some symbols need to be inserted before they are entirely parsed, in which 
    * case, we will need to stack them up and then adjust their end positions 
    * when we are done parsing them.  This call indicates that the given symbol 
    * still needs and ending seek position to be set later. 
    * 
    * @param contextId  ID of symbol to push onto context stack. 
    */
   int pushContext(int contextId);
   /**
    * After a symbol has been pushed onto the symbol stack, when we are done 
    * parsing it and we know it's end location, we call popContext() to patch 
    * in the end location and complete the symbol. 
    * 
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   void popContext(unsigned int endLineNumber, unsigned int endSeekPosition);
   /**
    * If we need to adjust the end seek position of a specific context item 
    * which was not pushed onto the context stack, we can do it using this 
    * function.  This only applies in the context and locals modes of tagging. 
    *  
    * @param contextId           ID of symbol already inserted
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   void endContext(int contextId, 
                   unsigned int endLineNumber, 
                   unsigned int endSeekPosition);

   /**
    * Some preprocessing statementss need to be inserted before they are entirely 
    * parsed, in which case, we will need to stack them up and then adjust their 
    * end positions when we are done parsing them.  This call indicates that the 
    * given preprocessing statement still needs and ending seek position. 
    * 
    * @param contextId  ID of preprocessing statement to push onto context stack. 
    */
   int pushPPContext(int contextId);
   /**
    * After a preprocessing statement has been pushed onto the symbol stack, when 
    * we are done parsing it and we know it's end location, we call popPPContext() 
    * to patch in the end location and complete the statement. 
    * 
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   void popPPContext(unsigned int endLineNumber, unsigned int endSeekPosition);

   /**
    * Push the local variable scope onto the stack.  This allows us to capitate 
    * off local variables when they go out of scope. 
    */
   int pushLocals();
   /**
    * Pop the local variable scope from the stack.  If we are skipping out of 
    * scope variables, all the variables inserted since the last pushLocals() 
    * will be removed from the local variable list. 
    */
   void popLocals();

   /**
    * Set the class inheritance information for the given class name.
    * 
    * @param className        name of class to save class inheritance information for     
    * @param classNarents     list of parent classes to store for this class
    * 
    * @return 0 on success, <0 on error. 
    */
   int setClassInheritance(const SEString &className, 
                           const SEString &classParents);

   /**
    * Set the type signature for the given symbol.
    * 
    * @param tagName         name of variable to modify
    * @param typeName        type signature of the local item 
    * @param caseSensitive   use case-sensitive search to find tag name? 
    * 
    * @return 0 on success, <0 on error. 
    */
   int setTypeSignature(const SEString &tagName, 
                        const SEString &typeName,
                        bool caseSensitive=false);

   /**
    * Start parsing a statement. 
    *  
    * @param tagType       tag type of statement (VS_TAGTYPE_*) 
    * @param tokenType     language specific token associated with statement 
    * @param lineNumber    start line number        
    * @param seekPosition  start seek position      
    */
   int startStatement(int tagType, int tokenType,
                      int lineNumber, int seekPosition);
   
   /**
    * Return the depth of the statement parsing stack. 
    */
   size_t getStatementStackDepth() const;

   /**
    * Returns the token type of the topmost statement on the statement stack. 
    * i.e. FOR_TLTK
    * 
    * @param depth   default is to get the one on top of the stack 
    */
   unsigned int getStatementToken(size_t depth=0) const;
   /**
    * Set the token type for the topmost statement on the statement stack.
    * i.e. FOR_TLTK
    * 
    * @param tokenType  language specific token associated with statement 
    */
   void setStatementToken(unsigned int tokenType);

   /**
    * Return the type of statement tag (VS_TAGTYPE_*) 
    * for a statement on the statement stack. 
    *  
    * @param depth   default is to get the one on top of the stack 
    */
   int getStatementTagType(size_t depth=0) const;
   /**
    * Set the type of statement tag (VS_TAGTYPE_*) 
    * for the topmost statement on the statement stack. 
    * 
    * @param tag_type 
    */
   void setStatementTagType(int tagType);
   
   /**
    * Append text to the topmost statement on the statement stack.
    */
   void setStatementString(const SEString& str);
   /**
    * Append text to the topmost statement on the statement stack.
    */
   void appendStatementString(const SEString& str);
   
   /**
    * Save the statement start location for the topmost statement on 
    * the statement stack. 
    * 
    * @param lineNumber    start line number        
    * @param seekPosition  start seek position      
    */
   void setStatementStartLocation(int lineNumber, int seekPosition);
   
   /**
    * Save the statement scope start location for the topmost statement on 
    * the statement stack. 
    * 
    * @param lineNumber    scope line number        
    * @param seekPosition  scope seek position      
    */
   void setStatementScopeLocation(int lineNumber, int seekPosition);
   
   /**
    * Set the end of the statement at the top of the stack to the 
    * given location and then call insertTag and pop this statement 
    * off the stack. 
    * 
    * @param lineNumber    scope line number        
    * @param seekPosition  scope seek position      
    */
   void finishStatement(int lineNumber, int seekPosition);

   /**
    * Cancel parsing and tagging the topmost statement and 
    * pop it off of the stateement stack.
    */
   void cancelStatement();
   
   
   /**
    * Clear all statement labels inserted during local variable search.
    */
   void clearStatementLabels();

   /**
    * Insert a statement label.  Used only during local variable search. 
    *  
    * @param labelName 
    * @param startLineNumber     start line number        
    * @param startSeekPosition   start seek position      
    * @param nameLineNumber      name line number         
    * @param nameSeekPosition    name seek position       
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   int insertStatementLabel(const SEString &labelName,
                            const SEString &fileName,
                            unsigned int startLineNumber, unsigned int startSeekPosition,
                            unsigned int nameLineNumber,  unsigned int nameSeekPosition,
                            unsigned int endLineNumber,   unsigned int endSeekPosition);

   /**
    * Insert all the statement labels found during local variable search. 
    * Statement labels may operate outside of the normal scoping rules. 
    * This is why they can not be treated the same way that local variables 
    * are handled. 
    */
   void insertAllStatementLabels();

   /**
    * Sort the list of tags by seek position.
    */
   int sortAsynchronousTags();

   /**
    * Insert all the tags which were cached to be inserted later asynchrounously. 
    */
   int insertAsynchronousTags(bool (*pfnIsCancelled)(void* data)=NULL, void *userData=NULL) const;
   int insertAsynchronousTagsInDatabase(bool (*pfnIsCancelled)(void* data)=NULL, void *userData=NULL) const;
   int insertAsynchronousTagsInContext(bool (*pfnIsCancelled)(void* data)=NULL, void *userData=NULL) const;
   int insertAsynchronousTagsInLocals(bool (*pfnIsCancelled)(void* data)=NULL, void *userData=NULL) const;

   /**
    * Clear all the tags which were cached to be inserted later asynchronously.
    */
   void clearAsynchronousTags();


private:

   // Pointer to private implementation of tagging target
   class SEPrivateListTagsTarget * const mpContext;
   friend class SEPrivateListTagsTarget;
};


EXTERN_C
int VSAPI SETagCheckCachedContext(const SEListTagsTarget &context);

EXTERN_C int VSAPI
SETagCheckCachedLocals(const SEListTagsTarget &context, int contextId);


}

#endif // SLICKEDIT_LIST_TAGS_TARGET_H

