////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SEListTagsTarget.h
// Description:   Declaration of class for collecting symbol information.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SEContextTaggingInterface.h"
#include "tags/SETagInformation.h"
#include "tags/SETagFlags.h"
#include "tags/SETagTypes.h"
#include "tagsdb.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"


namespace slickedit {

// forward declarations
struct SEFindTagsOptions;
struct SETaggingResultsCache;
struct SEReturnTypeInfo;
struct SEIDExpressionInfo;
class  SETokenList;


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
class VSDLLEXPORT SEListTagsTarget 
{
public:
   /**
    * Default constructor
    */
   SEListTagsTarget();

   /**
    * Simple constructor 
    *  
    * @param fileName            name of file which we are tagging 
    * @param taggingFlags        bitset of VSLTF_* 
    * @param bufferId            buffer ID if tagging from an editor control 
    * @param tagDatabase         name and path of tag database to update 
    * @param startLine           first line to begin parsing on (for local variables) 
    * @param startSeekPosition   seek position to start parsing at 
    * @param stopLine            last line to stop parsing at (for local variables) 
    * @param stopSeekPosition    seek position to stop parsing at 
    * @param currentLine         line number cursor when parsing starts 
    * @param currentSeekPosition position of cursor when parsing starts 
    * @param contextId           context Id of symbol being parsed for locals 
    */
   SEListTagsTarget(const SEString &fileName, 
                    const unsigned int taggingFlags = 0,
                    const unsigned int bufferId = 0,
                    const SEString &tagDatabase = (const char *)nullptr,
                    const unsigned int startLine = 0,
                    const unsigned int startSeekPosition = 0,
                    const unsigned int stopLine = 0,
                    const unsigned int stopSeekPosition = 0,
                    const unsigned int currentLine = 0,
                    const unsigned int currentSeekPosition = 0,
                    const unsigned int contextId = 0);

   /**
    * Construct from a list of tags.
    */
   SEListTagsTarget(const class SETagList &src);
   /**
    * Move-construct from a list of tags.
    */
   SEListTagsTarget(class SETagList &&src);

   /**
    * Copy constructor
    */
   SEListTagsTarget(const SEListTagsTarget& src);
   /**
    * Move constructor
    */
   SEListTagsTarget(SEListTagsTarget && src);

   /**
    * Destructor
    */
   virtual ~SEListTagsTarget();

   /**
    * Assignment operator
    */
   SEListTagsTarget &operator = (const SEListTagsTarget &src);
   /**
    * Move assignment operator
    */
   SEListTagsTarget &operator = (SEListTagsTarget &&src);

   /**
    * Assignment operator from a list of tags. 
    *  
    * Note that this only replaces the list of tags in this object, 
    * not any of it's other properties.  In this respect, this function is 
    * identical to setTagList(). 
    */
   SEListTagsTarget &operator = (const class SETagList &src);
   /**
    * Move assignment operator from a list of tags
    *  
    * Note that this only replaces the list of tags in this object, 
    * not any of it's other properties.  In this respect, this function is 
    * identical to setTagList(). 
    */
   SEListTagsTarget &operator = (class SETagList &&src);

   /**
    * Comparison operators
    */
   bool operator == (const SEListTagsTarget &rhs) const;
   bool operator != (const SEListTagsTarget &rhs) const;
   bool operator == (const SETagList &rhs) const;
   bool operator != (const SETagList &rhs) const;

   /**
    * Is this an unitialized item?
    */
   const bool isNull() const;
   /**
    * Is this an instance that is NOT a shared pointer?
    */
   const bool isUnique() const;

   /**
    * Hash function for using in SEHashSet 
    */
   unsigned int hash() const;

   /**
    * @return 
    * Return an approximation of the number of bytes of storage required for 
    * this object. 
    */
   const size_t getStorageRequired() const; 

   /**
    * Return the list of tags.
    */
   const SETagList &getTagList() const;
   /**
    * Exchange the list of tags for another.
    */
   void setTagList(const class SETagList &tagList);
   void setTagList(class SETagList &&tagList);

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
    *  
    * @note 
    * The arguments read from the interpreter are as follows: 
    * <ol type="1"> 
    * <li>ignored
    * <li>filename_p - If not "", specifies the name of the file
    *     on disk to be tagged.  If NULL or "", tag the current buffer.
    * <li>buffer - Set to input string when reading from a string.
    * <li>ltf_flags - Bit flags of VSLTF_*.
    *     <ul>
    *     <li>VSLTF_SKIP_OUT_OF_SCOPE    - Skip locals that are not in scope
    *     <li>VSLTF_SET_TAG_CONTEXT      - Set tagging context at cursor position
    *     <li>VSLTF_LIST_OCCURRENCES     - Insert references into tags database
    *     <li>VSLTF_START_LOCALS_IN_CODE - Parse locals without first parsing header
    *     <li>VSLTF_READ_FROM_STRING     - Read from string data passed in: arg(3)=buffer, arg(6)=buffer_len
    *     <li>VSLTF_LIST_STATEMENTS      - List statements as well as symbols
    *     <li>VSLTF_LIST_LOCALS          - list local variables in current function
    *     <li>VSLTF_ASYNCHRONOUS         - request to update tags in background thread
    *     <li>VSLTF_READ_FROM_EDITOR     - reading input from an editor control
    *     <li>VSLTF_ASYNCHRONOUS_DONE    - special flag for job to indicate tagging done
    *     <li>VSLTF_BEAUTIFIER           - Set when this is associated with a beautifier job.
    *     <li>VSLTF_SAVE_TOKENLIST       - Set when building current context and saving token list
    *     <li>VSLTF_INCREMENTAL_CONTEXT  - Used for incremental parsing
    *     <li>VSLTF_REMOVE_FILE          - Remove the given file from a tag database
    *     <li>VSLTF_NO_SAVE_COMMENTS     - Do not store documentation comments when tagging
    *     </ul>
    * <li>ignored
    * <li>buffer_len - Length of input string when reading from a string.
    * <li>StartFromCursor - Optional.  IF given, specifies to start scan
    *     from the current offset in the current buffer.
    * <li>StopSeekPos - Optional.  If given, specifices the seek position 
    *     to stop searching at.  At the moment, this only given when looking for locals.
    *     Its purpose is to stop searching for locals after the cursor location
    *     (which is/was StopSeekPos).  This is so that variables declared after the cursor
          do not appear when listing symbols.
    * </dl> 
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
    * Update the range of text modified within this buffer.  This is used to 
    * track where the file has been modified as it is being editing so that 
    * it can be updated incrementally. 
    * <p> 
    * The related function, {@link setIncrementalBuffer()}, is used to set up 
    * a parsing job to parse the incremental file range. 
    * 
    * @param startOffset      position to start parsing at 
    * @param endOffset        position to finish parsing at 
    * @param numBytesInserted the number or bytes inserted or deleted 
    *                         from the buffer (&lt;0 for deleted bytes) 
    */
   void setIncrementalChangeSpan(const unsigned int startOffset,
                                 const unsigned int endOffset,
                                 const int numBytesInserted);
   /** 
    * @return 
    * Return the starting position where first change was made to the buffer.
    */
   const unsigned int getIncrementalChangeStartSeekPosition() const;
   /** 
    * @return 
    * Return the ending position where last change was made to the buffer.
    */
   const unsigned int getIncrementalChangeStopSeekPosition() const;
   /** 
    * @return 
    * Return the number of bytes inserted or deleted from the buffer. 
    * A value less than 0 indicates that text was deleted from the buffer.
    */
   const int getIncrementalChangeNumBytesInserted() const;

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
   SEString getFileName() const;
   /**
    * Set the full, absolute file path for the file being parsed.
    */
   void setFileName(const SEString &fileName);
   void setFileName(SEString &&fileName);

   /**
    * Return the language ID for the tagging callback. 
    * <p> 
    * Because of tagging callback inheritance, this may not be the actual 
    * language ID, it may be the language ID of a parent language whose callback 
    * we are using. 
    */
   SEString getLanguageId() const;
   /**
    * Set the language ID for the tagging callback.
    */
   void setLanguageId(const SEString &langId);

   /**
    * Return the class scope in effect for incremental parsing 
    * to update just part of the current context.
    */
   SEString getIncrementalClassName() const;
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
                slickedit::SETokenID *pTokenID=nullptr);
   int addToken(const class SETokenStruct &tokenInfo,
                slickedit::SETokenID *pTokenID=nullptr);
   /**
    * Save line break information.
    */
   int addLineBreak(const unsigned int lineNumber,
                    const unsigned int seekPosition);

   /**
    * Modify the type for the token at the given seek position.
    * 
    * @param tokenID        ID of token to modify in token list.
    * @param tk             new token type.
    */
   int setTokenType(const SETokenID tokenID, const SETokenType tk);

   /**
    * Indicate tha tthe given seek position has a parsing error.
    * 
    * @param tokenID        ID of token to modify in token list.
    * @param isError        indicate error state
    */
   int setTokenErrorStatus(const SETokenID tokenID, const SETokenErrorStatus isError);

   /** 
    * @return 
    * Find the corresponding token at the given seek position, and return it's 
    * token ID.  Return 0 if the token is not found. 
    * 
    * @param seekPosition   offset in bytes from the beginning of the file. 
    */
   const SETokenID findTokenAtOffset(const unsigned int seekPosition) const;

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
   const int getBufferId() const;
   /**
    * Save the buffer ID for the file being parsed.
    */
   void setBufferId(const int bufferId);

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
    * @return 
    * Return 'true' if the modify flags indicate that this buffer was modified. 
    */
   const bool getBufferIsModified() const;
   /**
    * Update the buffer modify flags for this target to match the buffer modify 
    * flags in the editor control, and append the modify flags to indicate that 
    * this file has been tagged to the buffer modify flags in the editor, if this 
    * target has been updated in the context cache. 
    */
   void updateBufferModifyFlags();

   /**
    * Set the file/buffer information for the file being parsed.
    */
   void setFileInformation( const SEString &fileName,
                            const slickedit::SEString &langId,
                            const VSINT64 fileDate,
                            const unsigned int bufferId=0,
                            const unsigned int lastModified=0,
                            const unsigned int modifyFlags=0 );

   /**
    * Get the file information from the given editor control. 
    * This includes the file name, language mode, buffer ID, date, and 
    * modification information. 
    * 
    * @param editorControlWid    Editor control window ID 
    *  
    * @see setFileInformation 
    * @see getFileInformationFromBuffer 
    *  
    * @note 
    * This method can only be called from the main thread.
    */
   void setFileInformationFromEditor(const int editorControlWid=0);

   /**
    * Get the file information from the given editor buffer.
    * This includes the file name, language mode, buffer ID, date, and 
    * modification information. 
    * 
    * @param bufferId      Editor buffer ID
    *  
    * @see setFileInformation 
    * @see getFileInformationFromEditor
    *  
    * @note 
    * This method is thread-safe.
    */
   void setFileInformationFromBuffer(const int bufferId=0);

   /** 
    * @return 
    * Return 'true' if the file information for this file matches the file
    * information for the given object.
    * 
    * @param rhs     object to compare to
    */
   bool isFileInformationEqual(const SEListTagsTarget& rhs) const;

   /** 
    * @return 
    * Return 'true' if the date information for this file matches the date 
    * information for the given object.
    * 
    * @param rhs     object to compare to
    */
   bool isFileDateEqual(const SEListTagsTarget& rhs) const;

   /**
    * Clear all the information related to the the file this tagging job 
    * is assocated with. 
    *  
    * @see setFileInformation() 
    * @see setIncrementalChangeSpan() 
    * @see setParseStartLocation() 
    * @see setParseStopLocation() 
    * @see setParseCurrentLocation() 
    * @see setTaggingFLags()
    */
   void clearFileInformation();

   /**
    * @return 
    * Return the file encoding flag for loading this file buffer from disk. 
    */
   const int getFileEncoding() const;
   /**
    * Set the file encoding flag for loading this file buffer from disk. 
    * This should be one of VSENCODING_AUTO*, usually VSENCODING_AUTOXML. 
    */
   void setFileEncoding(int encoding);

   /**
    * Return the file contents which we are going to be parsing.
    */
   SEString getFileContents() const;
   /**
    * Return a pointer to the the file contents which we are going to be parsing.
    */
   const char * getFileContentsPointer() const;
   /**
    * Return the length of the file contents which we are going to be parsing.
    */
   const size_t getFileContentsLength() const;
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
    *  
    * @param maybeAlloc    Allocate token list if this object is null. 
    */
   const SETokenList *getTokenList(const bool maybeAlloc=false) const;
   /**
    * Plug in a specific token list object.  This should be used with care 
    * because the token list that is built when the file is parsed is the 
    * 'correct' token list for this object. 
    */
   void setTokenList(const SETokenList &tokenList);
   void setTokenList(SETokenList &&tokenList);
    
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
    *    <li><b>remove</b>   -- remove tags and references for the given file from the tag database
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
    *    <li><b>remove</b>   -- remove tags and references for the given file from the tag database
    * </ul> 
    */
   void setTaggingFlags(const unsigned int ltfFlags);
   /** 
    * @return 
    * Return the tagging update mode flags. 
    * This is a bitset of the constants SE_UPDATEFLAG_* (VS_UPDATEFLAG_* in Slick-C). 
    * The update flags are derived from the tagging flags. 
    * <ul> 
    * <li><b>SE_UPDATEFLAG_context  </b> - Find all the context tags in a context or a file
    * <li><b>SE_UPDATEFLAG_statement</b> - Find all statement tags in a context or a file
    * <li><b>SE_UPDATEFLAG_list_all </b> - List all locals in the function rather just those in scope
    * <li><b>SE_UPDATEFLAG_tokens   </b> - Save the token list
    * </ul>
    *  
    * @see setUpdateFlags() 
    * @see getTaggingFlags() 
    * @see setTaggingFlags() 
    */
   const unsigned int getUpdateFlags() const;
   /** 
    * Set the tagging update mode flags. 
    * This is a bitset of the constants SE_UPDATEFLAG_* (VS_UPDATEFLAG_* in Slick-C). 
    * The update flags are derived from the tagging flags. 
    * <ul> 
    * <li><b>SE_UPDATEFLAG_context  </b> - Find all the context tags in a context or a file
    * <li><b>SE_UPDATEFLAG_statement</b> - Find all statement tags in a context or a file
    * <li><b>SE_UPDATEFLAG_list_all </b> - List all locals in the function rather just those in scope
    * <li><b>SE_UPDATEFLAG_tokens   </b> - Save the token list
    * </ul>
    *  
    * @see getUpdateFlags() 
    * @see getTaggingFlags() 
    * @see setTaggingFlags() 
    */
   void setUpdateFlags(const unsigned int updateFlags);

   /**
    * Return the full, absolute file path to the tagging database to be updated.
    */
   SEString getTagDatabase() const;
   /**
    * Set the absolute file path to the tagging database to be updated.
    */
   void setTagDatabase(const SEString &fileName);
   void setTagDatabase(SEString &&fileName);

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

   /**
    * Return 'true' if the tagging target is to update the tags found in 
    * the current file, including statement level tagging.
    */
   bool isTargetStatements() const;
   void setTargetStatements();

   /**
    * Return 'true' if the tagging target is to insert tags in a match set 
    * (a set of symbols found by a context tagging search). 
    */
   bool isTargetMatches() const;
   void setTargetMatches();

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
    * Return 'true' if the parsing is finished.
    */
   bool isParsingFinished() const;
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
    * Return 'true' if the tagging remove job is completely finished. 
    */
   bool isTaggingRemoveFinished() const;
   /**
    * Indicate that a tagging remove was started for this file. 
    * At this time, this only effects tagging logging.
    */
   void setTaggingRemoveRunning();
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
    * Return 'true' if the token list is supported for this language.
    */
   bool isTokenListSupported() const;

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
    * If we are operating on a tag database, return 'true' if a request 
    * was made to remove the file from the given tag database.
    */
   bool getRemoveFileMode() const;
   /**
    * Turn on remove file mode.  This is used to set up a tagging job whose 
    * responsiblility is to remove a file from the tag database. 
    */
   void setRemoveFileMode(const bool yesno);
    
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
    * Parse the embedded sections that we can parse directly.
    * 
    * @return 0 on success, <0 on error
    */
   int parseEmbeddedSections();

   /**
    * Set a callback function for listing tags from the current file.
    */
   void setParsingCallback(SETagParsingCallbackType parseFun);
   /**
    * Check if we have a parsing callback for this target language. 
    * You must set the target language first. 
    */
   bool hasParsingCallback() const;
   /**
    * Return the function pointer for the parsing callback to be used 
    * to scan for tags in the current file. 
    */
   const SETagParsingCallbackType getParsingCallback() const;

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
    * @param context             tagging information to merge in 
    * @param isEmbeddedSection   are we merging an embedded code fragement?
    * 
    * @return 0 on success, <0 on error. 
    */
   int mergeTarget(const SEListTagsTarget &context, const bool isEmbeddedSection=false);

public:

   /**
    * Insert a tag into the list of tags collected.
    * <p> 
    * Depending on the tagging mode, and whether we are doing synchronous 
    * or asynchronous tagging, this will either insert an item into the current 
    * context, the locals, the tag database, or cache the information to be 
    * inserted synchronously into the database later.
    * 
    * @param tagInfo             symbol information to add to the context.
    * @param checkForDuplicates  check if this symbol is already in the symbol list?
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         If tagging locals or the current context, this will return
    *         the context ID or local ID on success. 
    */
   int insertTag(const SETagInformation &tagInfo, const bool checkForDuplicates=false);
   int insertTag(SETagInformation &&tagInfo, const bool checkForDuplicates=false);
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
    * @param tagType             type of symbol (SE_TAG_TYPE_*)
    * @param tagFlags            tag flags (bitset of SE_TAG_FLAG_*)
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
    * @param doctype             documentation comment type (null, javadoc, etc) 
    * @param docComments         documentation comment text
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         If tagging locals or the current context, this will return
    *         the context ID or local ID on success. 
    */
   int insertTag(const SEString &tagName,
                 const SEString &tagClass,
                 const SETagType tagType,
                 const SETagFlags tagFlags,
                 const SEString &fileName,
                 unsigned int startLineNumber, unsigned int startSeekPosition,
                 unsigned int nameLineNumber,  unsigned int nameSeekPosition,
                 unsigned int scopeLineNumber, unsigned int scopeSeekPosition,
                 unsigned int endLineNumber,   unsigned int endSeekPosition,
                 const SEString &tagSignature = (const char *)nullptr,
                 const SEString &classParents = (const char *)nullptr,
                 const SEString &templateSignature = (const char *)nullptr, 
                 const SEString &tagExceptions = (const char *)nullptr,
                 const SETagDocCommentType docType = SE_TAG_DOCUMENTATION_NULL, 
                 const SEString &docComments   = (const char *)nullptr );

   /**
    * Copy and insert a tag from another list tags target. 
    * This method always inserts the symbol as if we are doing asynchronous 
    * tagging.  This method is primarily used for building search match sets. 
    *  
    * @param src                 instance to copy symbol from 
    * @param i                   index of symbol to copy 
    * @param checkForDuplicates  check if this symbol is already in the symbol list?
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         This will return the context ID or local ID on success.
    */
   int insertTagFrom(const SEListTagsTarget &src, const size_t i, const bool checkForDuplicate=false);

   /**
    * Returns negative status or error code if there was an error status 
    * returned by insertTag() when inserting tags into a tagging database. 
    */
   const int getInsertTagStatus() const;
   void setInsertTagStatus(const int status);

   /**
    * Return the number of tags collected.
    */
   const size_t getNumTagsQueued() const;

   /**
    * Return the n'th tag collected, starting with 0 for the first tag.
    * Return NULL if there is no such tag. 
    */
   const SETagInformation *getTagInfo(const size_t tagIndex) const;

   /**
    * Replace the n'th tag, starting with 0 for the first tag.
    */
   void setTagInfo(const size_t tagIndex, const SETagInformation &tagInfo);
   void setTagInfo(const size_t tagIndex, SETagInformation &&tagInfo);

   /**
    * Remove the n'th tag collected from the list of tags, starting with 0 
    * for the first tag.  Does nothing if 'tagInfo' is out of range. 
    * Remove all tags from tagIndex to the end of the array if 'removeToEnd' 
    * is true. 
    */
   void removeTagInfo(const size_t tagIndex, const bool removeToEnd=false);

   /**
    * Find the current context ID given the current file name and seek position.
    * 
    * @param fileName              full path to current file
    * @param currentLineNumber     current real line number
    * @param currentSeekPosition   current seek position of cursor within file
    * @param allowStatements       allow a statement to be the current item? 
    * @param allowOutlineOnly      allow symbols that are flagged as outline only
    * 
    * @return Returns the tag index of the symbol which the location corresponds to. 
    *  
    * @see isInCurrentContext() 
    */
   const unsigned int findCurrentContextId(const SEString &fileName, 
                                           const unsigned int currentLineNumber, 
                                           const unsigned int currentSeekPosition, 
                                           const bool allowStatements=false,
                                           const bool allowOutlineOnly=false) const;
   /** 
    * @return 
    * Return 'true' if the the given offset within the current file is 
    * within the symbol which had been recognized as the current context? 
    *  
    * @param seekPosition  offset within file 
    *  
    * @see findCurrentContextId() 
    * @see getTagInfo() 
    */
   const bool isInCurrentContext(const unsigned int seekPosition) const;

   /**
    * Search the set of symbols for a tag with the given name. 
    * This method will build a dictionary of tags for each name to make 
    * subsequent searches faster. 
    * 
    * @param contextIdIterator   Index to resume search from, starts with 0.
    * @param tagName             Symbol name to search for
    * @param exactNameMatch      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive       Search for case-sensitive tag name match 
    * @param contextFlags        Specifies advanced tag name pattern matching options 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findTagWithName(const unsigned int contextIdIterator,
                                      const SEString &tagName, 
                                      const bool exactNameMatch=true,
                                      const bool caseSensitive=true,
                                      const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;
   /**
    * Search the set of symbols for a tag in the given class. 
    * This method will build a dictionary of tags for each class name to make 
    * subsequent searches faster.
    * 
    * @param contextIdIterator   Index to resume search from, starts with 0.
    * @param tagName             Symbol name to search for
    * @param className           Symbol class name to search for
    * @param exactNameMatch      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive       Search for case-sensitive class name match 
    * @param contextFlags        Specifies advanced tag name pattern matching options 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findTagInClass(const unsigned int contextIdIterator,
                                     const SEString &tagName, 
                                     const SEString &className, 
                                     const bool exactNameMatch=true,
                                     const bool caseSensitive=true,
                                     const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;
   /**
    * Search the set of symbols for a tag with the given tag type.
    * This method will build a dictionary of tags for each tag type to make 
    * subsequent searches faster.
    * 
    * @param contextIdIterator   Index to resume search from, starts with 0.
    * @param tagType             Tag type to search for
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findTagWithTagType(const unsigned int contextIdIterator, 
                                         const SETagType tagType) const;

   /**
    * Find a tag at the given start location.
    * 
    * @param contextIdIterator   Index to resume search from, starts with 0.
    * @param startLineNumber     Line number of item to search for, ignored if 0.
    * @param startSeekPosition   Seek position of item to search for, ignored if 0. 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findTagStartingAt(const unsigned int contextIdIterator,
                                        const unsigned int startLineNumber,
                                        const unsigned int startSeekPosition) const;

   /**
    * Search the set of symbols for a tag matching the given tag name, class name, 
    * and other properties. 
    *  
    * @param contextIdIterator      Context ID iterator used to iterate though multiple matches 
    * @param tagPrefix              Tag name prefix to search for matches to
    * @param className              Class name to search for matches in 
    * @param exactNameMatch         Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive          Search for case-sensitive tag name match 
    * @param passThroughAnonymous   Pass through all anonymous (unnamed) symbols 
    * @param passThroughTransparent Pass through all transparent / opaque symbols, 
    *                               such as enumerated types which do not have to be qualified
    * @param skipIgnored            Skip symbols with SE_TAG_FLAG_ignore tag flag set
    *  
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findTag(unsigned int contextIdIterator,
                              const SEString &tagPrefix, 
                              const SEString &className = (const char*)0,
                              const bool exactNameMatch=true, 
                              const bool caseSensitive=true,
                              const bool passThroughAnonymous=false,
                              const bool passThroughTransparent=false,
                              const bool skipIgnored=false,
                              const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;

   /**
    * Search the set of symbols for a tag that matches the given tag exactly. 
    * This can be used to eliminate duplicates when creating a set of symbol 
    * matches to a query. 
    * 
    * @param contextIdIterator      Context ID iterator used to iterate though multiple matches 
    * @param tagInfo                Symbol to search for a match to
    * @param lineMustMatch          Check if line number matches exactly
    * 
    * @return
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (context ID) of the symbol if it finds a match.
    */
   const unsigned int findMatchingTag(unsigned int contextIdIterator,
                                      const slickedit::SETagInformation &tagInfo, 
                                      const bool lineMustMatch=true) const;

   /**
    * Locate the context ID of the symbol which encloses the given symbol, 
    * which is expected to be a symbol in this set of symbols. 
    * 
    * @param tagInfo     symbol information
    * 
    * @return 
    * Returns the index+1 (context ID) of the symbol it finds. 
    */
   const int findOuterContextId(const slickedit::SETagInformation &tagInfo) const;
   /**
    * @return 
    * Return the context ID of the symbol which encloses the given symbol, 
    * which is expected to be a symbol in this set of symbols. 
    * 
    * @param pTagInfo   pointer to symbol information.
    */
   const unsigned int getOuterContextId(slickedit::SETagInformation *pTagInfo) const;
   /** 
    * @return 
    * Returns the next sibling of the given item in the set of symbols which 
    * is enclosed by the same 'outer' symbol. 
    * Returns 0 if there is no such symbol.
    * 
    * @param contextId   Context ID (index+1) of starting symbol.
    */
   const unsigned int findNextSiblingContextId(const unsigned int contextId) const;
   /** 
    * @return 
    * Returns the previous sibling of the given item in the set of symbols which 
    * is enclosed by the same 'outer' symbol. 
    * Returns 0 if there is no such symbol.
    * 
    * @param contextId   Context ID (index+1) of starting symbol.
    */
   const unsigned int findPrevSiblingContextId(const unsigned int contextId) const;

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
                             const SEString &langId = (const char *)nullptr,
                             const SEEmbeddedTaggingOption parseOption = SE_EMBEDDED_COLLATE_AND_TAG);

   /**
    * @return Return the number of embedded sections in the current context.
    */
   size_t getNumEmbeddedSections() const;

   /**
    * @return Return the number of embedded sections in the current context
    *         that have not yet been parsed for tags.
    */
   size_t getNumUnparsedEmbeddedSections() const;

   /**
    * Remove all embedded code sections catalogued for this file.
    */
   void clearEmbeddedSections();

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
    *  
    * @return Returns 0 on success, &lt;0 on error (INVALID_ARGUMENT_RC) 
    */
   int getEmbeddedSectionInfo(size_t index,
                              unsigned int& startLineNumber,
                              unsigned int& endLineNumber,
                              unsigned int& startSeekPosition,
                              unsigned int& endSeekPosition,
                              SEString& langid,
                              SEEmbeddedTaggingOption &parseOption,
                              bool &taggingFinished) const;

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
    * Sets the last local variable ID.
    */
   void setLastLocalVariableId(unsigned int localId);

   /**
    * Sets the seek position of the statement that triggered 
    * a file to be read in and parsed recursively 
    * (for example, #include or Cobol COPY statement). 
    */
   void setCurrentIncludeSeekPosition(const unsigned int startSeekPosition);

   /**
    * Add the given identifier to the list of identifiers
    * 
    * @return 0 on success, <0 on error.
    */
   int insertIdOccurrence(SEString &&idName);
   int insertIdOccurrence(const SEString &idName);
   int insertIdOccurrence(const SEString &idName, const SEString &fileName);
   int insertIdOccurrence(const SEString &idName, const cmStringUtf8 &fileName);
   int insertIdOccurrence(const cmROStringUtf8 &idName);
   int insertIdOccurrence(const cmROStringUtf8 &idName, const SEString &fileName);
   int insertIdOccurrence(const cmROStringUtf8 &idName, const cmStringUtf8 &fileName);
   int insertIdOccurrence(const cmStringUtf8 &idName);
   int insertIdOccurrence(const cmStringUtf8 &idName, const SEString &fileName);
   int insertIdOccurrence(const cmStringUtf8 &idName, const cmStringUtf8 &fileName);
   int insertIdOccurrence(cmStringUtf8 &&idName);
   int insertIdOccurrence(cmStringUtf8 &&idName, const SEString &fileName);
   int insertIdOccurrence(cmStringUtf8 &&idName, const cmStringUtf8 &fileName);


   /** 
    * @return
    * Return the number of items on the context stack.
    */
   size_t getContextStackDepth() const;
   /**
    * Some symbols need to be inserted before they are entirely parsed, in which 
    * case, we will need to stack them up and then adjust their end positions 
    * when we are done parsing them.  This call indicates that the given symbol 
    * still needs and ending seek position to be set later. 
    * 
    * @param contextId  ID of symbol to push onto context stack. 
    *                   If 0, this will use the last item inserted 
    */
   int pushContext(int contextId=0);
   /**
    * After a symbol has been pushed onto the symbol stack, when we are done 
    * parsing it and we know it's end location, we call popContext() to patch 
    * in the end location and complete the symbol. 
    * 
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   int popContext(unsigned int endLineNumber, unsigned int endSeekPosition);
   /**
    * If we need to adjust the end seek position of a specific context item 
    * which was not pushed onto the context stack, we can do it using this 
    * function.  This only applies in the context and locals modes of tagging. 
    *  
    * @param contextId           ID of symbol already inserted
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position        
    */
   int endContext(int contextId, 
                  unsigned int endLineNumber, 
                  unsigned int endSeekPosition);

   /** 
    * @return
    * Return the number of items on the preprocessing stack.
    */
   size_t getPPContextStackDepth() const;
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
   int popPPContext(unsigned int endLineNumber, unsigned int endSeekPosition);

   /**
    * Push the local variable scope onto the stack, and insert a scope tag to 
    * track where the scope starts.  This is designed for the local variable 
    * list-all technique, not for skip-out-of-scope. 
    *  
    * @param startLineNumber     start line number for local scope
    * @param startSeekPosition   start seek position for local scope
    * @param blockName           Name to use for local variable block 
    * @param fileName            current source file name
    */
   int pushLocals(const unsigned int startLineNumber,
                  const unsigned int startSeekPosition,
                  const slickedit::SEString &blockName="",
                  const slickedit::SEString &fileName=""); 
   /**
    * Push the local variable scope onto the stack.  This allows us to capitate 
    * off local variables when they go out of scope. 
    * 
    * @param localId  ID of symbol to push onto local stack. 
    *                 Will use the last local set, or the last local inserted
    *                 if not specified.
    *  
    * @deprecated Instead, use the version that passes in the start location. 
    */
   int pushLocals(int localId=0);
   /**
    * Pop the local variable scope from the stack.  If we are skipping out of 
    * scope variables, all the variables inserted since the last pushLocals() 
    * will be removed from the local variable list. 
    *  
    * @param endLineNumber       end line number          
    * @param endSeekPosition     end seek position 
    * @param removeEmptyScopeTag if pushLocals() inserted a scope tag, but 
    *                            nothing has been added since then, remove the
    *                            scope tag as it does nothing. 
    */
   int popLocals(const unsigned int endLineNumber, const unsigned int endSeekPosition, const bool removeEmptyScopeTag=true);
   /**
    * Pop the local variable scope from the stack.  If we are skipping out of 
    * scope variables, all the variables inserted since the last pushLocals() 
    * will be removed from the local variable list. 
    *  
    * @deprecated Instead, use the version that passes in the end location. 
    */
   int popLocals();
   /**
    * Undo the last pushLocals() as if it never happened. 
    * Any local variables inserted into the context are retained as they 
    * would be if pushLocals() had never been called. 
    */
   int unpushLocals();
   /**
    * Deterimine if the given local variable is in scope at the given seek 
    * position.  This is used to filter out local variable matches that are 
    * not in scope when traversing through the set of all local variable 
    * declarations for an entire function. 
    *  
    * @param localId       local variable ID (0..n-1) 
    * @param seekPosition  seek position within current file
    */
   const bool isLocalInScope(const size_t localId, const unsigned int seekPosition) const;

   /**
    * Set the class inheritance information for the given class name.
    * 
    * @param className        name of class to save class inheritance information for     
    * @param classParents     list of parent classes to store for this class
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
    * Set the type signature for the given symbol. 
    * This is done after context tagging is complete. 
    * 
    * @param tagName         name of variable to modify
    * @param typeName        type signature of the local item 
    * @param caseSensitive   use case-sensitive search to find tag name? 
    * 
    * @return 0 on success, &lt;0 on error. 
    */
   int applyTypeSignature(const SEString &tagName, 
                          const SEString &typeName,
                          bool caseSensitive=false);

   /**
    * Start parsing a statement. 
    *  
    * @param tagType       tag type of statement (SE_TAG_TYPE_*) 
    * @param tokenType     language specific token associated with statement 
    * @param lineNumber    start line number        
    * @param seekPosition  start seek position 
    * @param tagFlags      Optional tag flags 
    */
   int startStatement(const SETagType tagType,
                      const SETokenType tokenType,
                      const unsigned int lineNumber, 
                      const unsigned int seekPosition,
                      const SETagFlags tagFlags=SE_TAG_FLAG_NULL);
   
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
   SETokenType getStatementToken(size_t depth=0) const;
   /**
    * Set the token type for the topmost statement on the statement stack.
    * i.e. FOR_TLTK
    * 
    * @param tokenType  language specific token associated with statement 
    */
   void setStatementToken(SETokenType tokenType);

   /**
    * Return the type of statement tag (SE_TAG_TYPE_*) 
    * for a statement on the statement stack. 
    *  
    * @param depth   default is to get the one on top of the stack 
    */
   const SETagType getStatementTagType(size_t depth=0) const;
   /**
    * Set the type of statement tag (SE_TAG_TYPE_*) 
    * for the topmost statement on the statement stack. 
    * 
    * @param tagType    tag type of statement (SE_TAG_TYPE_*)
    */
   void setStatementTagType(const SETagType tagType);
   
   /**
    * Append text to the topmost statement on the statement stack.
    */
   void setStatementString(const SEString& str);
   void setStatementString(SEString && str);
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
   void setStatementStartLocation(const unsigned int lineNumber, const unsigned int seekPosition);
   
   /**
    * Save the statement name start location for the topmost statement on 
    * the statement stack.  This location is meaningful primarily for function 
    * calls to indicate the name of the function, and assignment statements 
    * to indicate the name of the variable being assigned to. 
    * 
    * @param lineNumber    name line number        
    * @param seekPosition  name seek position      
    */
   void setStatementNameLocation(const unsigned int lineNumber, const unsigned int seekPosition);
   
   /**
    * Save the statement scope start location for the topmost statement on 
    * the statement stack. 
    * 
    * @param lineNumber    scope line number        
    * @param seekPosition  scope seek position      
    */
   void setStatementScopeLocation(const unsigned int lineNumber, const unsigned int seekPosition);
   
   /**
    * Set the end of the statement at the top of the stack to the 
    * given location and then call insertTag and pop this statement 
    * off the stack. 
    * 
    * @param lineNumber    scope line number        
    * @param seekPosition  scope seek position      
    */
   const unsigned int finishStatement(const unsigned int lineNumber, const unsigned int seekPosition);

   /**
    * Cancel parsing and tagging the topmost statement and 
    * pop it off of the statement stack.
    */
   void cancelStatement();
   
   
   /**
    * Clear all statement labels inserted during local variable search.
    */
   void clearStatementLabels();

   /**
    * Insert a statement label.  Used only during local variable search. 
    *  
    * @param labelName           label name
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
    * Based on symbol start and seek positions, as well as symbol types, 
    * conpute the symbol nesting (aka, outer context ids) for all the symbols 
    * in the list. 
    */
   void computeOuterContextIds();

   /**
    * Set the date which each symbol was tagged.
    */
   void setDateTaggedForAllSymbols();

   /**
    * Optimize symbol occurrence information to cut down overhead when 
    * inserting into the tag database. 
    *  
    * This code makes assumptions about the way references are stored 
    * in the database. 
    */
   int optimizeReferences();

   /**
    * Insert all the tags which were cached to be inserted later asynchrounously. 
    */
   int insertAsynchronousTags(bool (*pfnIsCancelled)(void* data)=nullptr, void *userData=nullptr);
   int insertAsynchronousTagsInDatabase(bool (*pfnIsCancelled)(void* data)=nullptr, void *userData=nullptr) const;
   int insertAsynchronousTagsInContext();
   int insertAsynchronousTagsInLocals();
   int removeFileFromDatabase(bool (*pfnIsCancelled)(void* data)=nullptr, void *userData=nullptr) const;

   /**
    * Release our lock on the database and let other threads use it temporarily.
    * 
    * @param dbHandle   (in/out) database handle  
    * @param startTime  (in/out) start time in ms
    * @param timeSlice  (in) time slice to check
    * 
    * @return 0 on success, <0 on error or cancellation
    */
   int yieldDatabaseAndCheckForCancel(int &dbHandle, 
                                      size_t &startTime, size_t timeSlice,
                                      bool (*pfnIsCancelled)(void* data) = nullptr, 
                                      void *userData = nullptr,
                                      bool isClonedWriterDB = false) const;
      
   /**
    * Utility functions for implementing insertAsynchronousTagsInDatabase()
    */
   static int openAsynchronousTagDatabase(const slickedit::SEString &tagDatabase, 
                                          bool& isClonedWriterDB);
   static int closeAsynchronousTagDatabase(const slickedit::SEString &tagDatabase,
                                           const int dbHandle,
                                           const bool isClonedWriterDB);
   int insertAsynchronousTagsInDatabase(int &dbHandle, 
                                        const bool isClonedWriterDB,
                                        bool (*pfnIsCancelled)(void* data)=nullptr, 
                                        void *userData=nullptr) const;  
   int removeFileFromDatabase(int &dbHandle, 
                              const bool isClonedWriterDB,
                              bool (*pfnIsCancelled)(void* data)=nullptr, 
                              void *userData=nullptr) const;  

   /**
    * Clear all the tags which were cached to be inserted later asynchronously.
    */
   void clearAsynchronousTags();

   /**
    * Remove duplicate symbols from the set of tags in a match set.
    * 
    * @param matchExactSymbolName      (optional) look for exact matches to this symbol only 
    * @param currentFileName           (optional) current file name
    * @param currentLangId             (optional) current language id where symbol search started
    * @param removeDuplicatesOptions   set of bit flags of options for what kinds of duplicates to remove. 
    *        <ul>
    *        <li>{@link VS_TAG_REMOVE_DUPLICATE_PROTOTYPES} -
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
   void removeDuplicateSymbols(const slickedit::SEString & matchExactSymbolName,
                               const slickedit::SEString & currentFileName,
                               const slickedit::SEString & currentLangId,
                               const unsigned int removeDuplicatesOptions);

   /**
    * Filter out the symbols in the current match set that do not
    * match the given set of filters.  If none of the symbols in the 
    * match set match the filters, do no filtering.
    * 
    * @param filter_flags  bitset of SE_TAG_FILTER_*
    * @param filter_all    if 'true', allow all the matches to be filtered out
    */
   void filterSymbolMatches(const SETagFilterFlags filter_flags, bool remove_all);

   /**
    * Obtain a lock on this object so that other threads can not access it.
    * A lock on a non-const instance will guarantee uniqueness.
    */
   void writeLock();
   /**
    * Obtain a lock on this object so that other threads can not access it.
    * A lock on a const instance can be on a shared reference.
    */
   void readLock() const;
   /**
    * Try to obtain a lock for thread synchronization. 
    * A lock on a non-const instance will guarantee uniqueness.
    * @return 
    * Return 'true' if the lock was successfully obtained, false otherwise. 
    */
   bool tryWriteLock();
   /**
    * Try to obtain a lock for thread synchronization. 
    * A lock on a const instance can be on a shared reference.
    * @return 
    * Return 'true' if the lock was successfully obtained, false otherwise. 
    */
   bool tryReadLock() const;
   /**
    * Release the lock.
    */
   void unlock() const;


protected:

   /**
    * Parse one embedded section. 
    *  
    * @param sect          embedded section to parse
    * @param embeddedText  text found in this section 
    * 
    * @return 0 on success, <0 on error
    */
   int parseEmbeddedText(struct EmbeddedSectionInformation &sect,
                         const cmROStringUtf8 &embeddedText);

private:

   // Pointer to private implementation of tagging target
   SESharedPointer<class SEPrivateListTagsTarget> mpContext;

};


EXTERN_C
int VSAPI SETagCheckCachedContext(const SEListTagsTarget &context);

EXTERN_C int VSAPI
SETagCheckCachedLocals(const SEListTagsTarget &context, int contextId);


} // namespace slickedit


extern unsigned cmHashKey(const slickedit::SEListTagsTarget &context);

extern const slickedit::SEListTagsTarget gNullTarget;

