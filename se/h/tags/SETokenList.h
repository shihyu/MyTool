////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:        SETokenList.h
// Description: Declaration for the SETokenList class for storing and
//              editing a list of tokens.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "tags/SETokenInterface.h"
#include "tags/SETokenStruct.h"
#include "slickedit/SEArray.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"

namespace slickedit {

/**
 * This class is used to effeciently represent a list of tokens in memory. 
 * <p> 
 * This class also has support for representing preprocessed code sections 
 * and embedded code sections, and for keeping track of a stack of token 
 * lists resulting from parsing preprocessing or embedded sections. 
 * <p> 
 * This class is thread-safe.  It uses a mutex to allow multiple threads to 
 * coordinate access to the token list. 
 * <p> 
 * This is the public interface to the token list class, basically a wrapper 
 * class with the sole purpose of not exposing the implementation details of 
 * the actual token list class.
 * <p>
 * Token lists support tracking of preprocessing expansion by having token 
 * ranges that are expanded to create additional instances of token lists. 
 * You can specify a preprocessing section by calling pushPreprocessedSection()
 * and then finish the section by calling popPreprocessedSection()
 * <p> 
 * In an identical manner, embedded code can be expanded in order to tokenize 
 * a comment or a string or other sequence of tokens which can be parsed 
 * more thoroughly.  A stack is used to keep track of what level of the token 
 * list we are currently inserting tokens into.  You can specify an embedded 
 * section by calling pushEmbeddedSection() and then finish the section by 
 * calling popEmbeddedSection()
 * <p> 
 * A sequence of insertions in a token list can be lumped together in order 
 * to improve performance.  This is done using the transaction-like 
 * beginInsert() and endInsert(). 
 * <p> 
 * The following diagram shows how an SETokenList relates to the other 
 * public token classes. 
 * <pre>
 *           ----------------------
 *          | SETokenList          |
 *          |----------------------|
 *          | tokens <=> token IDs |
 *          | lines  <=> line IDs  |
 *           ----------------------
 *                    |
 *                    o
 *    ----------------------------------- 
 *   | SETokenInterface or SETokenStruct |  
 *   |-----------------------------------|
 *   | token ID (SETokenID)              |
 *   | token type ID, user data          |
 *   | start offset                      |
 *   | text, length                      |
 *   | line number, line offset          |
 *   | file name, buffer ID              |
 *    -----------------------------------
 * </pre>
 *
 * @see SEMainTokenList
 * @see SETokenID 
 * @see SETokenReadInterface 
 * @see SETokenStruct 
 * @see SEParseTree 
 */
class VSDLLEXPORT SETokenList {
public:

   /**
    * Default constructor for a token list.
    */
   SETokenList();
   /**
    * Copy constructor for a token list.  This does a deep copy. 
    * 
    * @param src  token list to copy
    */
   SETokenList(const SETokenList &src);
   /**
    * Move constructor for a token list.  This does a shallow copy. 
    * 
    * @param src  token list to copy
    */
   SETokenList(SETokenList &&src);
   /**
    * Destructor.
    */
   ~SETokenList();

   /**
    * Assignment operator for a token list.  This does a deep copy.
    * 
    * @param src  token list to copy 
    */
   SETokenList &operator = (const SETokenList &src);
   /**
    * Move assignment operator for a token list.  This does a shallow copy.
    * 
    * @param src  token list to copy 
    */
   SETokenList &operator = (SETokenList &&src);

   /**
    * @return 
    * Returns 'true' if this token block exactly matches the given token list.
    */
   bool operator == (const SETokenList &rhs) const;
   /**
    * @return 
    * Returns 'true' if this token block does not match the given token list.
    */
   bool operator != (const SETokenList &rhs) const;

   /**
    * Is this instance allocated?
    */
   bool isNull() const;

   /**
    * Initialize this token list with all the necessary information.
    *  
    * @param filename            Name of file 
    * @param fileBufferID        Unique ID of file in editor
    * @param blockLength         Number of bytes represented by token list
    * 
    * @return 0 on success, &lt;0 on error
    *  
    * @see getFileName()
    * @see setFileName()
    * @see getBlockLength() 
    * @see addLineBreak() 
    * @see addToken() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see deleteToken() 
    * @see deleteTokenRange() 
    * @see deleteTokenRangeAtOffset() 
    */
   int initializeTokenList(const SEString &fileName,
                           const int fileBufferID=0,
                           const unsigned int blockLength=0);

   /**
    * Trim unused memory allocations off of token list.
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int maybeDefragmentOrTrim();

   /**
    * Lock the token list for exclusive access by one thread. 
    * This is useful when searching and traversing over the token list 
    * and you want to be certain that the token list does not change midstream. 
    *  
    * @see tryLockTokenList() 
    * @see unlockTokenList(); 
    */
   void lockTokenList() const;
   /**
    * Try to lock the token list.  Fail if the can not be obtained within 
    * the given timeframe. 
    *  
    * @return Return 'true' if the lock was successfully obtained. 
    *  
    * @see lockTokenList() 
    * @see unlockTokenList(); 
    */
   bool trylockTokenList() const;
   /**
    * Unlock the token list for exclusive access by one thread. 
    * Note that lock/unlock stacks, so the token list is not really 
    * unlocked until the last matching unlock is done. 
    *  
    * @see lockTokenList(); 
    * @see tryLockTokenList() 
    */
   void unlockTokenList() const;

   /**
    * @return Return the name of the file which this list of tokens 
    * originate from. 
    * <p> 
    * Note that some token lists will not have a file name at all, for 
    * example when the source is originating from a string generated from 
    * expanding a preprocessing macro. 
    *  
    * @see setFileName() 
    * @see initializeTokenList() 
    */
   SEString getFileName() const;
   int getFileName(SEString &fileName) const;

   /**
    * @return Return the buffer ID for the file which this list 
    * of tokens originate from. 
    *  
    * @see setFileName() 
    * @see initializeTokenList() 
    */
   const int getFileBufferID() const;

   /**
    * Set the file name (and optional buffer ID) which this list of 
    * tokens originate from. 
    * <p> 
    * Note that some token lists will not have a file name at all, for 
    * example when the source is originating from a string generated from 
    * expanding a preprocessing macro. 
    *  
    * @param fileName   full path of file tokens come from 
    * @param bufferID   editor buffer ID corresponding to file. 
    *  
    * @see getFileName() 
    * @see initializeTokenList() 
    */
   int setFileName(const SEString &fileName, int bufferID=0);

   /**
    * @return 
    * Return the start offset in bytes of this token list from the 
    * beginning of the file. 
    *  
    * @see initializeTokenList() 
    * @see setStartOffset() 
    * @see getStartLineNumber() 
    * @see getStartLineOffset() 
    * @see getStartPosition() 
    * @see getEndOffset() 
    */
   const unsigned int getStartOffset() const;
   /**
    * @return 
    * Return the offset in bytes to the end of this token list from the 
    * beginning of the file. 
    *  
    * @see getStartOffset() 
    * @see getStartLineNumber() 
    * @see getStartLineOffset() 
    * @see getEndPosition() 
    * @see getBlockLength() 
    */
   const unsigned int getEndOffset() const;

   /** 
    * @return 
    * Return the line number of the first line contained in this token list.
    *  
    * @see getStartOffset() 
    * @see getStartPosition() 
    * @see getStartLineOffset(); 
    * @see setStartLineNumber(); 
    */
   const unsigned int getStartLineNumber() const;
   /**
    * @return 
    * Return the offset in bytes from the start of the first line contained 
    * in this token list to the start of this token list. 
    *  
    * @see getStartOffset() 
    * @see getStartPosition() 
    * @see getStartLineNumber(); 
    * @see setStartLineNumber(); 
    */
   const unsigned int getStartLineOffset() const;
   /** 
    * @return 
    * Return the line number of the last line contained in this token list.
    *  
    * @see getEndOffset() 
    * @see getEndPosition() 
    * @see getEndLineOffset(); 
    * @see getStartOffset() 
    * @see getBlockLength() 
    */
   const unsigned int getEndLineNumber() const;
   /**
    * @return 
    * Return the offset in bytes from the start of the last line contained 
    * in this token list to the end of this token list. 
    *  
    * @see getEndOffset() 
    * @see getEndPosition() 
    * @see getEndLineNumber(); 
    * @see getStartOffset() 
    * @see getBlockLength() 
    */
   const unsigned int getEndLineOffset() const;

   /**
    * @return 'true' if the token spans the given offset 
    *  
    * @see getStartOffset()
    * @see getEndOffset()
    */
   const bool isSpanningOffset(const unsigned int offset) const;
   /**
    * @return 'true' if the token spans the given line number 
    *  
    * @see getStartLineNumber() 
    * @see getEndLineNumber() 
    */
   const bool isSpanningLine(const unsigned int lineNumber) const;

   /**
    * Get the start position information for this token list.
    * 
    * @param startOffset      [output] set to token list start offset
    * @param startLineNumber  [output] set to token list start line number
    * @param startLineOffset  [output] set to token list start line offset
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getStartOffset() 
    * @see getStartLineNumber() 
    * @see getStartLineOffset() 
    */
   int getStartPosition(unsigned int &startOffset,
                        unsigned int &startLineNumber,
                        unsigned int &startLineOffset) const;

   /**
    * Get the end position information for this token list.
    * 
    * @param endOffset      [output] set to token list end offset
    * @param endLineNumber  [output] set to token list end line number
    * @param endLineOffset  [output] set to token list end line offset 
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getEndOffset() 
    * @see getEndLineNumber() 
    * @see getEndLineOffset() 
    */
   int getEndPosition(unsigned int &endOffset,
                      unsigned int &endLineNumber,
                      unsigned int &endLineOffset) const;

   /** 
    * @return 
    * Return the number of tokens in this token list. 
    * It is possible for a token list to have zero tokens. 
    * <p> 
    * Note that this function will sum up all the tokens in all the token blocks 
    * and the token groups below each block, so it is not very effecient to 
    * call this function frequently unless necessary.  If you are calling this 
    * just to check if there are any tokens in the token list, it would be more 
    * effecient to just check if ({@link getFirstTokenID()} != 0). 
    *  
    * @see addToken() 
    * @see deleteToken() 
    * @see deleteTokenRange() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()
    */
   const unsigned int getNumTokens() const;

   /** 
    * @return 
    * Return the unique ID of the first token in this token list. 
    *  
    * @see getFirstToken()
    * @see getLastToken()
    * @see getLastTokenID()
    * @see addToken() 
    * @see getNumTokens() 
    * @see SETokenID 
    */
   const SETokenID getFirstTokenID() const;
   /** 
    * @return 
    * Return the unique ID of the last token in this token list. 
    *  
    * @see getFirstToken()
    * @see getLastToken()
    * @see getFirstTokenID() 
    * @see addToken()
    * @see getNumTokens() 
    * @see SETokenID 
    */
   const SETokenID getLastTokenID() const;

   /** 
    * @return 
    * Return the unique ID of the next token after the given token.
    * Returns NULL if the given token is the last token in the token list.
    *  
    * @param currTokenID   unique ID of current token 
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getPrevTokenID()
    */
   const SETokenID getNextTokenID(const SETokenID currTokenID) const;
   /** 
    * @return 
    * Return the unique ID of the previous token after the given token.
    * Returns NULL if the given token is the first token in the token list.
    *  
    * @param currTokenID   unique ID of current token 
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getPrevTokenID()
    */
   const SETokenID getPrevTokenID(const SETokenID currTokenID) const;

   /**
    * Prepare the token list to insert tokens and line breaks for a 
    * block of code.  This is used for building and updating the token list 
    * effeciently.
    * 
    * @param startOffset      start offset to begin inserting at 
    * @param startLineNumber  line number to start inserting at
    * @param startLineOffset  offset in bytes from start of line
    * @param newText          content of text to insert
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see addToken() 
    * @see addLineBreak() 
    * @see endInsert() 
    * @see stageTokenGroup() 
    * @see stageTokenBlock() 
    * @see commitTokenGroup() 
    * @see commitTokenBlock() 
    */
   int beginInsert(const unsigned int startOffset,
                   const unsigned int startLineNumber,
                   const unsigned int startLineOffset,
                   const SEString &newText);
   /**
    * Finish inserting the block of tokens and line breaks that we started 
    * inserting using {@link beginInsert()}. 
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see addToken() 
    * @see addLineBreak() 
    * @see beginInsert() 
    * @see stageTokenGroup() 
    * @see stageTokenBlock() 
    * @see commitTokenGroup() 
    * @see commitTokenBlock() 
    */
   int endInsert();

   /**
    * @return 
    * Return the current preprocessed code section, embedded code section, 
    * or code section block insert parsing depth. 
    *  
    * @see beginInsert() 
    * @see endInsert()
    * @see pushEmbeddededSection()
    * @see popEmbeddededSection() 
    * @see pushPreprocessedSection()
    * @see popPreprocessedEmbeddededSection() 
    */
   const size_t getParsingStackDepth() const;

   /**
    * Add a new token to this token list.
    * <p> 
    * Line breaks are inferred from the token's start and end line number and 
    * offsets and catalogued in order to keep track of line information. 
    * 
    * @param tokenInfo     specification of token to add 
    * @param pNewTokenID   [optional] set to ID of token added
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see beginInsert() 
    * @see endInsert() 
    * @see deleteToken() 
    * @see deleteTokenRange() 
    */
   int addToken(const SETokenStruct &tokenInfo, SETokenID *pNewTokenID=nullptr);
   int addToken(const SETokenReadInterface &tokenInfo, SETokenID *pNewTokenID=nullptr);

   /**
    * Delete the given token from this token list. 
    * 
    * @param tokenID             unique ID of token to delete
    * @param adjustedStartOffset (output) set to the start offset of the token
    * @param adjustedNumBytes    (output) set to the length of the token 
    * @param deleteTokenText     if true, the token's text (adjustedNumBytes) 
    *                            is removed, reducing the list length.
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see deleteTokenRange() 
    * @see deleteTokenRangeAtOffset() 
    */
   int deleteToken(const SETokenID tokenID,
                   unsigned int &adjustedStartOffset, 
                   unsigned int &adjustedNumBytes,
                   const bool deleteTokenText = true);

   /**
    * Delete the given range of tokens from this token list. 
    * 
    * @param startTokenID        unique ID of first token to delete
    * @param endTokenID          unique ID of last token to delete
    * @param adjustedStartOffset (output) set to the start offset of the 
    *                            first token
    * @param adjustedNumBytes    (output) set to the number of bytes spanned 
    *                            by the first and last token deleted 
    * @param deleteTokenText     if true, the text (adjustedNumBytes) 
    *                            is removed, reducing the list length.
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see deleteToken() 
    * @see deleteTokenRangeAtOffset() 
    * @see deleteTokenGroups() 
    */
   int deleteTokenRange(const SETokenID startTokenID,
                        const SETokenID endTokenID,
                        unsigned int &adjustedStartOffset, 
                        unsigned int &adjustedNumBytes,
                        const bool deleteTokenText = true);

   /**
    * Delete the given range of tokens and text starting at the given 
    * start offset and spanning the given number of bytes. 
    * 
    * @param startOffset         start offset to begin deleting tokens
    * @param numBytes            number of bytes to delete
    * @param adjustedStartOffset actual start offset deleted from.
    *                            The start offset may be adjusted to an earlier
    *                            point if the given offset would slice a
    *                            token in half. 
    * @param adjustedNumBytes    actual number of bytes deleted. 
    *                            The start offset may be adjusted to an earlier
    *                            point if the given offset would slice a
    *                            token in half.  Likewise, the end position may
    *                            be adjusted if the given position would slice
    *                            a token in half. 
    * @param deleteText          if true, the text (adjustedNumBytes) 
    *                            is removed from the token list. reducing the
    *                            list length of the token list. 
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see deleteToken() 
    * @see deleteTokenRange() 
    * @see splitTokenGroupAtOffset() 
    * @see splitTokenGroupAtIndex() 
    */
   int deleteTokenRangeAtOffset(const unsigned int startOffset,
                                const unsigned int numBytes,
                                unsigned int &adjustedStartOffset, 
                                unsigned int &adjustedNumBytes,
                                const bool deleteTokenText = true);
       
   /**
    * Merge the given token list with this one.  The token list may be
    * from an embedded section, or contain a collection of embedded sections.
    * 
    * @param rhsTokenList                 token list to merge in
    * @param isEmbeddedSection            is 'rhsTokenList' from embedded code?
    * @param pEmbeddedStartSeekPositions  array of start offsets of embedded sections
    * @param pEmbeddedEndSeekPositions    parallel array of end offsets for embedded sections
    * @param numEmbeddedSections          number of embedded sections
    * @param pTokenIDMap                  (optional, output) maps token ID's from 
    *                                     source token list to this token list       
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see pushEmbeddedSection 
    * @see popEmbeddedSection 
    * @see beginInsert 
    * @see endInsert 
    * @see addToken 
    */
   int mergeTokenList(const SETokenList &rhsTokenList, 
                      const bool isEmbeddedSection = false,
                      const unsigned int *pEmbeddedStartSeekPositions = nullptr,
                      const unsigned int *pEmbeddedEndSeekPositions = nullptr,
                      const size_t numEmbeddedSections = 0,
                      SEArray<SETokenPair> *pTokenIDMap = nullptr);
                            
   /** 
    * @return 
    * Return the unique token ID of the token overlapping the given offset 
    * or ending at the given offset.  Return 0 if no matching token is found. 
    * 
    * @param offset   start offset to begin searching at
    * 
    * @see SETokenID 
    * @see findLastTokenOnLine() 
    * @see findTokenBlockAtOffset() 
    * @see findTokenAtOrBeforeOffset() 
    * @see findTokenAtOrAfterOffset() 
    */
   const SETokenID findTokenAtOffset(const unsigned int offset) const;

   /** 
    * @return 
    * Return the unique token ID of the embedded token overlapping the given offset 
    * or ending at the given offset.  Return 0 if no matching token is found. 
    * 
    * @param offset   start offset to begin searching at
    * 
    * @see SETokenID 
    * @see findTokenAtOffset() 
    * @see findLastTokenOnLine() 
    * @see findTokenBlockAtOffset() 
    * @see findTokenAtOrBeforeOffset() 
    * @see findTokenAtOrAfterOffset() 
    */
   const  SETokenID findEmbeddedTokenAtOffset(const unsigned int offset) const;

   /** 
    * @return 
    * Return the unique token ID of the token overlapping the given offset 
    * or the first token ending before the given offset. 
    * Return 0 if no matching token is found. 
    * 
    * @param offset     start offset to begin searching at 
    * @param onSameLine only look for tokens on the same line from offset
    * 
    * @see SETokenID 
    * @see findTokenAtOffset() 
    * @see findLastTokenOnLine() 
    * @see findTokenBlockAtOffset()
    */
   const SETokenID findTokenAtOrBeforeOffset(const unsigned int offset,
                                             const bool onSameLine=false) const;
   /** 
    * @return 
    * Return the unique token ID of the token overlapping the given offset 
    * or the first token starting after the given offset. 
    * Return 0 if no matching token is found. 
    * 
    * @param offset     start offset to begin searching at 
    * @param onSameLine only look for tokens on the same line from offset
    * 
    * @see SETokenID 
    * @see findTokenAtOffset() 
    * @see findLastTokenOnLine() 
    * @see findTokenBlockAtOffset()
    */
   const SETokenID findTokenAtOrAfterOffset(const unsigned int offset,
                                            const bool onSameLine=false) const;

   /** 
    * @return 
    * Return the unique token ID of the first token on the given line. 
    * Return 0 if no matching token is found. 
    * 
    * @param lineNumber    line number to look for token on.
    *  
    * @see SETokenID 
    * @see findLastTokenOnLine() 
    * @see findTokenAtOffset()
    * @see findFirstTokenBlockOnLine() 
    */
   const SETokenID findFirstTokenOnLine(const unsigned int lineNumber) const;
   /** 
    * @return 
    * Return the unique token ID of the last token on the given line. 
    * Return 0 if no matching token is found. 
    * 
    * @param lineNumber    line number to look for token on.
    *  
    * @see SETokenID 
    * @see findFirstTokenOnLine() 
    * @see findTokenAtOffset()
    * @see findLastTokenBlockOnLine() 
    */
   const SETokenID findLastTokenOnLine(const unsigned int lineNumber) const;

   /** 
    * @return 
    * Return the unique ID of the next token on the same line as the given 
    * token.  Returns 0 if the given token is the last token on the line. 
    *  
    * @param currTokenID   unique ID of current token 
    * @param lineNumber    line number to continue searching at
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getNextTokenID()
    * @see getPrevTokenID()
    */
   const SETokenID getNextTokenOnLine(const SETokenID currTokenID,
                                      const unsigned int lineNumber=0) const;
   /** 
    * @return 
    * Return the unique ID of the previous token on the same line as the given 
    * token.  Returns 0 if the given token is the first token on the line.
    *  
    * @param currTokenID   unique ID of current token 
    * @param lineNumber    line number to continue searching at
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getPrevTokenID()
    */
   const SETokenID getPrevTokenOnLine(const SETokenID currTokenID,
                                      const unsigned int lineNumber=0) const;

   /**
    * Find a token which overlaps the given offset, or if there is no such 
    * token, find the whitespace living living in the hole between tokens 
    * overlapping the given offset.  If whitespace is found, the token type 
    * will be set to SETOKEN_WHITESPACE and the token ID will be set to the 
    * token FOLLOWING the whitespace, or 0 if there is no such token.
    * 
    * @param offset     start offset to begin searching at
    * @param tokenInfo  [output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see findTokenAtOffset() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int findTokenOrWhitespaceAtOffset(const unsigned int startOffset,
                                     SETokenStruct &tokenInfo) const;
   int findTokenOrWhitespaceAtOffset(const unsigned int startOffset,
                                     SETokenWriteInterface &tokenInfo) const;

   /** 
    * Return the whitespace living before the first token in the token list, 
    * or if there is no whitespace before the first token, return the first 
    * token in the token list.  If whitespace is found, the token type 
    * will be set to SETOKEN_WHITESPACE and the token ID will be set to the 
    * token FOLLOWING the whitespace, or 0 if there is no such token. 
    * 
    * @param offset     start offset to begin searching at
    * @param tokenInfo  [output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getFirstTokenOrWhitespace(SETokenStruct &tokenInfo) const;
   int getFirstTokenOrWhitespace(SETokenWriteInterface &tokenInfo) const;
   /** 
    * Return the whitespace living after the last token in the token list, 
    * or if there is no whitespace after the last token, return the last 
    * token in the token list.  If whitespace is found, the token type 
    * will be set to SETOKEN_WHITESPACE and the token ID will be set to the 
    * token PRECEEDING the whitespace, or 0 if there is no such token. 
    * 
    * @param offset     start offset to begin searching at
    * @param tokenInfo  [output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getFirstTokenID()
    * @see getLastTokenID()
    * @see getFirstTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getLastTokenOrWhitespace(SETokenStruct &tokenInfo) const;
   int getLastTokenOrWhitespace(SETokenWriteInterface &tokenInfo) const;

   /**
    * Find the next token or whitespace following the given token. 
    * Uses the token offset and token ID of the input token to determine 
    * the starting point, then finds either the adjacent token or whitespace.
    * If whitespace is found, the token type will be set to SETOKEN_WHITESPACE 
    * and the token ID will be set to the token FOLLOWING the whitespace, 
    * or 0 if there is no such token.
    * 
    * @param nextToken 
    * 
    * @param tokenInfo  [input/output] set to token information
    * 
    * @return 0 on success, &lt;0 on error
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getFirstTokenOrWhitespaceOnLine()
    * @see getLastTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getNextTokenOrWhitespace(SETokenStruct &tokenInfo) const;
   int getNextTokenOrWhitespace(SETokenWriteInterface &tokenInfo) const;
   /**
    * Find the previous token or whitespace preceeding the given token. 
    * Uses the token offset and token ID of the input token to determine 
    * the starting point, then finds either the adjacent token or whitespace.
    * If whitespace is found, the token type will be set to SETOKEN_WHITESPACE 
    * and the token ID will be set to the token PRECEEDING the whitespace, 
    * or 0 if there is no such token.
    * 
    * @param nextToken 
    * 
    * @param tokenInfo  [input/output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getFirstTokenOrWhitespaceOnLine()
    * @see getLastTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getPrevTokenOrWhitespace(SETokenStruct &tokenInfo) const;
   int getPrevTokenOrWhitespace(SETokenWriteInterface &tokenInfo) const;
   
   /**
    * Find the first token on the given line, or if there is no such 
    * token, find the whitespace living living in the hole before the first 
    * token on the given line.  If whitespace is found, the token type 
    * will be set to SETOKEN_WHITESPACE and the token ID will be set to the 
    * token FOLLOWING the whitespace, or 0 if there is no such token. 
    * 
    * @param offset     start offset to begin searching at
    * @param tokenInfo  [output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getLastTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int findFirstTokenOrWhitespaceOnLine(const unsigned int lineNumber,
                                        SETokenStruct &tokenInfo) const;
   int findFirstTokenOrWhitespaceOnLine(const unsigned int lineNumber,
                                        SETokenWriteInterface &tokenInfo) const;
   /**
    * Find the last token on the given line, or if there is no such 
    * token, find the whitespace living living in the hole after the last 
    * token on the given line.  If whitespace is found, the token type 
    * will be set to SETOKEN_WHITESPACE and the token ID will be set to the 
    * token PRECEEDING the whitespace, or 0 if there is no such token. 
    * 
    * @param offset     start offset to begin searching at
    * @param tokenInfo  [output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getFirstTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int findLastTokenOrWhitespaceOnLine(const unsigned int lineNumber,
                                       SETokenStruct &tokenInfo) const;
   int findLastTokenOrWhitespaceOnLine(const unsigned int lineNumber,
                                       SETokenWriteInterface &tokenInfo) const;

   /**
    * Find the next token or whitespace following the given token on the same 
    * line.  Uses the token offset and token ID of the input token to determine 
    * the starting point, then finds either the adjacent token or whitespace.
    * If whitespace is found, the token type will be set to SETOKEN_WHITESPACE 
    * and the token ID will be set to the token FOLLOWING the whitespace, 
    * or 0 if there is no such token.
    * 
    * @param lineNumber line number to continue searching at
    * @param tokenInfo  [input/output] set to token information
    * 
    * @return 0 on success, &lt;0 on error
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getFirstTokenOrWhitespaceOnLine()
    * @see getLastTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getNextTokenOrWhitespaceOnLine(SETokenStruct &tokenInfo,
                                      const unsigned int lineNumber=0) const;
   int getNextTokenOrWhitespaceOnLine(SETokenWriteInterface &tokenInfo,
                                      const unsigned int lineNumber=0) const;
   /**
    * Find the previous token or whitespace preceeding the given token on the 
    * same line.  Uses the token offset and token ID of the input token to 
    * determine the starting point, then finds either the adjacent token or 
    * whitespace.  If whitespace is found, the token type will be set to 
    * SETOKEN_WHITESPACE and the token ID will be set to the token PRECEEDING 
    * the whitespace, or 0 if there is no such token.
    * 
    * @param lineNumber line number to continue searching at
    * @param tokenInfo  [input/output] set to token information
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see findFirstTokenOnLine() 
    * @see findLastTokenOnLine() 
    * @see getFirstTokenOrWhitespaceOnLine()
    * @see getLastTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine() 
    * @see getFirstTokenOrWhitespace()
    * @see getLastTokenOrWhitespace()
    * @see getNextTokenOrWhitespace()
    * @see getPrevTokenOrWhitespace() 
    * @see SETokenStruct 
    */
   int getPrevTokenOrWhitespaceOnLine(SETokenStruct &tokenInfo,
                                      const unsigned int lineNumber=0) const;
   int getPrevTokenOrWhitespaceOnLine(SETokenWriteInterface &tokenInfo,
                                      const unsigned int lineNumber=0) const;
   
   /**
    * Populate the given token information struct with all the details about 
    * this token, including it's start offset, length, line number, type, 
    * user data, and token text. 
    * 
    * @param tokenID    unique ID of token
    * @param tokenInfo (output) token object to populate
    * @return 0 on success, &lt;0 on error 
    *  
    * @see SETokenStruct
    * @see addToken() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenInfo()
    */
   int getTokenInfo(const SETokenID tokenID, SETokenStruct &tokenInfo) const;
   int getTokenInfo(const SETokenID tokenID, SETokenWriteInterface &tokenInfo) const;

   /**
    * @return Return the name of the file the given token comes from. 
    * 
    * @param tokenID    unique ID of token
    *  
    * @see getFileName() 
    * @see getFileBufferID() 
    * @see getTokenFileBufferID(); 
    * @see SETokenInterface 
    * @see SETokenInterface.getFileName() 
    * @see SETokenInterface.getFileBufferID() 
    */
   SEString getTokenFileName(const SETokenID tokenID) const;
   int getTokenFileName(const SETokenID tokenID, SEString &fileName) const;
   /**
    * @return Return the buffer ID for the file the given token comes from. 
    * 
    * @param tokenID    unique ID of token
    *  
    * @see getFileName() 
    * @see getFileBufferID() 
    * @see getTokenFileName(); 
    * @see SETokenInterface 
    * @see SETokenInterface.getFileName() 
    * @see SETokenInterface.getFileBufferID() 
    */
   const int getTokenFileBufferID(const SETokenID tokenID) const;

   /**
    * @return Return the token type for the given token. 
    * <p> 
    * The token type is represented using an unsigned short integer, 
    * which usually maps to an enumerated type defined by the lexical analyzer. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see setTokenType()
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenType()
    */
   const SETokenType getTokenType(const SETokenID tokenID) const;
   /**
    * Set the token type for the given token.
    * <p>
    * The token type is represented using an unsigned short integer,
    * which usually maps to an enumerated type defined by the lexical analyzer.
    *  
    * @param tokenID    unique ID of token 
    * @param tokenType  token type value
    * @return 0 on success, &lt;0 on error 
    *  
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getTokenType()
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenType()
    * @see SETokenWriteInterface 
    * @see SETokenWriteInterface.setTokenType()
    */
   int setTokenType(const SETokenID tokenID, const SETokenType tokenType);

   /**
    * @return Return status indicating if the token is flagged with a parsing error.
    *
    * @param tokenID    unique ID of token 
    *  
    * @see setTokenErrorFlag()
    * @see setTokenType()
    */
   const SETokenErrorStatus getTokenErrorStatus(const SETokenID tokenID) const;
   /**
    * Set or clear the flag indicating that the token is flagged with a parsing error.
    *
    * @param tokenID    unique ID of token 
    * @param isError    indicate type of parsing error
    * @return 0 on success, &lt;0 on error
    *
    * @see getTokenErrorFlag()
    * @see getTokenType()
    * @see SETokenSource
    * @see SETokenizer
    */
   int setTokenErrorStatus(const SETokenID tokenID, const SETokenErrorStatus isError);

   /**
    * @return Return a copy of the text represented by the token. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see setTokenText() 
    * @see getTokenLength() 
    * @see getText() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenText()
    */
   SEString getTokenText(const SETokenID tokenID) const;
   /**
    * Copy the text represented by the token into the given string. 
    *  
    * @param tokenID    unique ID of token
    * @param text       (reference) string to copy text into
    *  
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see setTokenText() 
    * @see getTokenLength() 
    * @see getText() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenText()
    */
   int getTokenText(const SETokenID tokenID, SEString &text) const;

   /**
    * Replace the token text for the given token with the given string. 
    * This can cause the token list to grow or shrink in size if the 
    * replacement text is longer or shorter than the original token text. 
    * 
    * @param tokenID    unique ID of token to modify
    * @param text       text to replace token's original text with
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getTokenText() 
    * @see getTokenLength() 
    * @see getText() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenText()
    * @see SETokenWriteInterface 
    * @see SETokenWriteInterface.setTokenText()
    */
   int setTokenText(const SETokenID tokenID, const SEString &text);
   /**
    * Replace the token text for the given token with the given string. 
    * This can cause the token list to grow or shrink in size if the 
    * replacement text is longer or shorter than the original token text. 
    * <p> 
    * Note that the token information is expected to be either the token 
    * information for an actual token in the tree, or for whitespace between 
    * tokens.  An error will be returned if the token info overlaps both 
    * tokens and whitespace. 
    * 
    * @param tokenInfo  token information, can be whitespace
    * @param text       text to replace token's original text with
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getTokenText() 
    * @see getTokenLength() 
    * @see getText() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenText()
    * @see SETokenWriteInterface 
    * @see SETokenWriteInterface.setTokenText()
    */
   int setTokenText(const SETokenStruct &tokenInfo, const SEString &text);

   /**
    * @return Return the length of the token in bytes. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getTokenText() 
    * @see setTokenText() 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenText()
    */
   const unsigned int getTokenLength(const SETokenID tokenID) const;

   /**
    * @return Return the start seek position (in bytes) of the token relative 
    * to the start of the text buffer it belongs to. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getEndOffset(); 
    * @see getStartLineNumber(); 
    * @see getStartLineOffset(); 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenStartOffset()
    */
   const unsigned int getTokenStartOffset(const SETokenID tokenID) const;
   /** 
    * @return Return the starting line number for the given token. 
    *  
    * @see getStartOffset(); 
    * @see getStartLineOffset(); 
    * @see getEndLineNumber();
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenStartLineNumber()
    */
   const unsigned int getTokenStartLineNumber(const SETokenID tokenID) const;
   /**
    * @return Return the offset in bytes from the start of the given token to the 
    * start of the first line containing the given token. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getStartOffset(); 
    * @see getStartLineNumber(); 
    * @see getEndLineOffset(); 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenStartLineOffset()
    */
   const unsigned int getTokenStartLineOffset(const SETokenID tokenID) const;
   /**
    * @return Return the end seek position (in bytes) of the token relative 
    * to the start of the text buffer it belongs to.  This can be calculated 
    * by adding the token length to the start offset of the token. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getStartOffset(); 
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenEndOffset()
    */
   const unsigned int getTokenEndOffset(const SETokenID tokenID) const;
   /**
    * @return Return the ending line number for the given token. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getEndOffset(); 
    * @see getEndLineOffset();
    * @see getStartLineNumber();
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenEndLineNumber()
    */
   const unsigned int getTokenEndLineNumber(const SETokenID tokenID) const;
   /**
    * @return Return the offset in bytes from the end of the given token to the 
    * start of the last line containing the given token. 
    *  
    * @param tokenID    unique ID of token
    *  
    * @see getEndOffset(); 
    * @see getStartLineOffset(); 
    * @see getEndLineNumber();
    * @see SETokenInterface 
    * @see SETokenInterface.getTokenEndLineOffset()
    */
   const unsigned int getTokenEndLineOffset(const SETokenID tokenID) const;

   /**
    * @return Return 'true' if the given token spans the given seek position.
    * 
    * @param tokenID   unique Id of token
    * @param seekpos   seek position within file
    */
   const bool isTokenSpanningOffset(const SETokenID tokenID, const unsigned int seekpos) const;

   /**
    * Retrieve the string user data stored for this token with the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * @param userData   [output] set to user data value
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int getTokenUserData(const SETokenID tokenID, const SEString &key, VSINT64 &userData) const;
   /**
    * Save string user data stored for this token using the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * @param userData   user data value
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int setTokenUserData(const SETokenID tokenID, const SEString &key, const VSINT64 userData);

   /**
    * Retrieve the string user data stored for this token with the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * @param userData   [output] set to user data string
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int getTokenUserData(const SETokenID tokenID, const SEString &key, SEString &userData) const;
   /**
    * Save string user data stored for this token using the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * @param userData   user data string
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int setTokenUserData(const SETokenID tokenID, const SEString &key, const SEString &userData);

   /**
    * Retrieve the pointer user data stored for this token with the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * 
    * @return 0 on success, &lt;0 on error.
    */
   const void *getTokenUserData(const SETokenID tokenID, const SEString &key) const;
   /**
    * Save pointer user data stored for this token using the given key.
    * 
    * @param tokenID    unique ID of token
    * @param key        lookup key
    * @param userData   user data pointer
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int setTokenUserData(const SETokenID tokenID, const SEString &key, const void* userData);

   /**
    * @return 
    * Return the number of line breaks in this entire token list. 
    *  
    * @see addLineBreak() 
    * @see addToken() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see getStartLineNumber() 
    * @see getEndLineNumber() 
    * @see getLineNumberAtOffset() 
    * @see getStartOffsetAtLineNumber() 
    * @see getLineLengthAtLineNumber() 
    * @see findFirstTokenOnLine()
    * @see findLastTokenOnLine()
    * @see getNextTokenOnLine()
    * @see getPrevTokenOnLine()
    * @see findFirstTokenOrWhitespaceOnLine()
    * @see findLastTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine()
    */
   const unsigned int getNumLineBreaks() const;

   /**
    * Add a line break at the given offset.
    * 
    * @param lineNumber    line number from the start of file
    * @param startOffset   start offset in bytes 
    * @param minLineLength [optional] min length of line being added 
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see getNumLineBreaks() 
    * @see addToken() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see getStartLineNumber() 
    * @see getEndLineNumber() 
    * @see getLineNumberAtOffset() 
    * @see getStartOffsetAtLineNumber() 
    * @see getLineLengthAtLineNumber() 
    * @see findFirstTokenOnLine()
    * @see findLastTokenOnLine()
    * @see getNextTokenOnLine()
    * @see getPrevTokenOnLine()
    * @see findFirstTokenOrWhitespaceOnLine()
    * @see findLastTokenOrWhitespaceOnLine()
    * @see getNextTokenOrWhitespaceOnLine()
    * @see getPrevTokenOrWhitespaceOnLine()
    */
   int addLineBreak(const unsigned int lineNumber,
                    const unsigned int startOffset,
                    const unsigned int minLineLength=0);

   /**
    * @return 
    * Return the line number at the given offset from the start of the file. 
    * Optionally, also return the offset within the current line. 
    * 
    * @param offset           start offset in bytes from start of file 
    * @param pLineOffset      (optional, output) set to the number of bytes 
    *                         from the start of the current line at the
    *                         given offset. 
    *  
    * @see addLineBreak() 
    * @see getStartOffsetAtLineNumber() 
    * @see getLineLengthAtLineNumber() 
    * @see getLineOffsetAtOffset() 
    */
   const unsigned int getLineNumberAtOffset(const unsigned int offset,
                                            unsigned int *pLineOffset=nullptr) const;
   /**
    * @return 
    * Return the line offset at the given offset from the start of the file. 
    * This is the number of bytes from the start of the line at the given offset. 
    * 
    * @param offset           start offset in bytes from start of file 
    *  
    * @see addLineBreak() 
    * @see getStartOffsetAtLineNumber() 
    * @see getLineLengthAtLineNumber() 
    * @see getLineNumbertAtOffset() 
    */
   const unsigned int getLineOffsetAtOffset(const unsigned int offset) const;
   /**
    * @return 
    * Return the start offset in bytes from the beginning of the file at the 
    * given line number. 
    * 
    * @param lineNumber    line number 
    *  
    * @see addLineBreak() 
    * @see getLineNumberAtOffset() 
    * @see getLineLengthAtLineNumber() 
    * @see getLineNumberAtOffset() 
    */
   const unsigned int getStartOffsetAtLineNumber(const unsigned int lineNumber) const;

   /**
    * @return 
    * Return the length of the given line.
    *  
    * @param lineNumber    line number
    *  
    * @see addLineBreak() 
    * @see getLineNumberAtOffset() 
    * @see getStartOffsetAtLineNumber() 
    * @see getLineNumberAtOffset() 
    */
   const unsigned int getLineLengthAtLineNumber(const unsigned int lineNumber) const;

   /**
    * Return the number of bytes represented by this token list. 
    *  
    * @see setStartOffset()
    * @see setEndOffset()
    */
   const unsigned int getBlockLength() const;

   /** 
    * @return 
    * Return the block of text of the given length starting at the given offset.
    * 
    * @param startOffset   start offset in bytes
    * @param numBytes      number of bytes of text to retrieve
    * 
    * @see addToken() 
    * @see beginInsert() 
    * @see getText() 
    * @see setTokenText() 
    */
   SEString getText(const unsigned int startOffset,
                    const unsigned int numBytes) const;

   /** 
    * Retrieve the block of text of the given length starting at the given offset.
    * 
    * @param startOffset   start offset in bytes
    * @param numBytes      number of bytes of text to retrieve
    * 
    * @return 0 on success, &lt;0 on error.
    *  
    * @see addToken() 
    * @see beginInsert() 
    * @see getText() 
    * @see setTokenText() 
    */
   int getText(SEString &text,
               const unsigned int startOffset,
               const unsigned int numBytes) const;

   /**
    * Set of options for getting the text contents between two tokens 
    * @see getTokenRangeText 
    */
   enum TextRangeFlags {
      /** 
       *    Get everything between the two tokens, verbatim
       */ 
      TEXT_EVERYTHING,
      /** 
       *  Skip comments and collapse whitespace between tokens to a single space
       */
      TEXT_SKIP_COMMENTS_AND_WHITESPACE,
      /**
       * Extract preprocessed token text.
       * This option also implies skipping comments and whitespace.
       */
      TEXT_PREPROCESSED
   };

   /** 
    * @return 
    * Return the text betwen two tokens, inclusively, optionally filtering 
    * out comments and whitespace or preprocessing.
    * 
    * @param firstTokenID  retrieve text starting with this token
    * @param lastTokenID   retrieve text ending at this token
    * @param textFlags     text range options (TEXT_EVERYTHING, 
    *                      TEXT_SKIP_COMMENTS_AND_WHITESPACE,
    *                      or TEXT_PREPROCESSED)
    *  
    * @see addToken() 
    * @see beginInsert() 
    * @see getText() 
    * @see setTokenText() 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see TextRangeFlags 
    * @see TextRangeFlags.TEXT_EVERYTHING 
    * @see TextRangeFlags.TEXT_PREPROCESSED
    * @see TextRangeFlags.TEXT_SKIP_COMMENTS_AND_WHITESPACE
    */
   SEString getTokenRangeText(const SETokenID firstTokenID,
                              const SETokenID lastTokenID,
                              TextRangeFlags textFlags=TEXT_EVERYTHING) const;

   /** 
    * Retrieve the text betwen two tokens, inclusively, optionally filtering 
    * out comments and whitespace or preprocessing.
    * 
    * @param firstTokenID  retrieve text starting with this token
    * @param lastTokenID   retrieve text ending at this token 
    * @param text          [output] set to the text retrieved 
    * @param textFlags     text range options (TEXT_EVERYTHING, 
    *                      TEXT_SKIP_COMMENTS_AND_WHITESPACE,
    *                      or TEXT_PREPROCESSED)
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see addToken() 
    * @see beginInsert() 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getText() 
    * @see setTokenText() 
    * @see TextRangeFlags 
    * @see TextRangeFlags.TEXT_EVERYTHING 
    * @see TextRangeFlags.TEXT_PREPROCESSED
    * @see TextRangeFlags.TEXT_SKIP_COMMENTS_AND_WHITESPACE
    */
   int getTokenRangeText(const SETokenID firstTokenID,
                         const SETokenID lastTokenID,
                         SEString &text,
                         TextRangeFlags textFlags=TEXT_EVERYTHING) const;

   /**
    * Set up to start inserting tokens for an embedded section starting 
    * at the first given token and ending with the last token, inclusive. 
    * This will call beginInsert() to prepare the token list for inserts. 
    * 
    * @param firstTokenID  unique ID of first token in embedded section
    * @param lastTokenID   unique ID of last token in embedded section
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see popEmbeddedSection() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see addToken() 
    * @see addLineBreak() 
    * @see insertEmbeddedTokenList() 
    * @see getNumEmbeddedTokenLists() 
    * @see getEmbeddedTokenList() 
    * @see pushPreprocessedSection()
    * @see popPreprocessedSection() 
    */
   int pushEmbeddedSection(const SETokenID firstTokenID, 
                           const SETokenID lastTokenID);

   /**
    * Finish parsing an embedded code section.  This will call endInsert() 
    * to commit the changes to the token list, and pop the token list off of 
    * the parse stack. 
    * 
    * @return 0 on success, &lt;0 on error 
    *  
    * @see pushEmbeddedSection() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see addToken() 
    * @see addLineBreak() 
    * @see insertEmbeddedTokenList() 
    * @see getNumEmbeddedTokenLists() 
    * @see getEmbeddedTokenList() 
    * @see pushPreprocessedSection()
    * @see popPreprocessedSection() 
    */
   int popEmbeddedSection();

   /**
    * Delete all the embedded token lists between the given start offset 
    * and end offset.  Any embedded code section overlapping this section 
    * will be deleted.
    * 
    * @param startOffset   start offset in bytes from the beginning of file
    * @param endOffset     end offset in bytes from the beginning of file
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see getEmbeddedTokenList() 
    * @see pushEmbeddedSection() 
    * @see popEmbeddedSection() 
    */
   int deleteEmbeddedTokenLists(const unsigned int startOffset,
                                const unsigned int endOffset);

   /** 
    * @return 
    * Return the number of embedded token lists.
    */
   const size_t getNumEmbeddedTokenLists() const;
   /** 
    * @return 
    * Return the first token in this token list of the given embedded token list.
    * 
    * @param i    index of embedded token list (0 .. getNumEmbeddedTokenLists)
    */
   const SETokenID getEmbeddedTokenListFirstTokenID(const size_t i) const;
   /** 
    * @return 
    * Return the last token in this token list of the given embedded token list.
    * 
    * @param i    index of embedded token list (0 .. getNumEmbeddedTokenLists)
    */
   const SETokenID getEmbeddedTokenListLastTokenID(const size_t i) const;

   /** 
    * @return 
    * Return 'true' if the given token is part of a embedded code section.
    * 
    * @see pushEmbeddedSection() 
    * @see popEmbeddedSection() 
    * @see getNumEmbeddedTokenLists() 
    * @see insertEmbeddedTokenList() 
    * @see getFirstTokenIDEmbedded() 
    * @see getLastTokenIDEmbedded()  
    * @see getNextTokenIDEmbedded() 
    * @see getPrevTokenIDEmbedded() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const bool isEmbeddedAt(const SETokenID tokenID) const;

   /** 
    * @return 
    * Return the first token in the embedded section under the given token. 
    * Return 0 if there are no embedded tokens at the given location.
    * 
    * @see pushEmbeddedSection() 
    * @see popEmbeddedSection() 
    * @see getNumEmbeddedTokenLists() 
    * @see insertEmbeddedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getFirstTokenIDEmbeddedAt(const SETokenID tokenID) const;
   /** 
    * @return 
    * Return the last token in the embedded section under the given token.
    * Return 0 if there are no embedded tokens at the given location.
    * 
    * @see pushEmbeddedSection() 
    * @see popEmbeddedSection() 
    * @see getNumEmbeddedTokenLists() 
    * @see insertEmbeddedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getLastTokenIDEmbeddedAt(const SETokenID tokenID) const;

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
    * @return 0 on success, &lt;0 on error 
    *  
    * @see popPreprocessedSection() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see addToken() 
    * @see addLineBreak() 
    * @see insertPreprocessedTokenList() 
    * @see getNumPreprocessedTokenLists() 
    * @see getPreprocessedTokenList() 
    * @see pushEmbeddededSection()
    * @see popEmbeddededSection() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
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
    * @return 0 on success, &lt;0 on error 
    *  
    * @see pushPreprocessedSection() 
    * @see beginInsert() 
    * @see endInsert() 
    * @see addToken() 
    * @see addLineBreak() 
    * @see insertPreprocessedTokenList() 
    * @see getNumPreprocessedTokenLists() 
    * @see getPreprocessedTokenList() 
    * @see pushEmbeddededSection()
    * @see popEmbeddededSection() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    */
   int popPreprocessedSection();

   /**
    * Delete all the preprocessed token lists between the given start offset 
    * and end offset.  Any preprocessed code section overlapping this section 
    * will be deleted.
    * 
    * @param startOffset   start offset in bytes from the beginning of file
    * @param endOffset     end offset in bytes from the beginning of file
    * 
    * @return 0 on success, &lt;0 on error. 
    *  
    * @see getPreprocessedTokenList() 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    */
   int deletePreprocessedTokenLists(const unsigned int startOffset,
                                    const unsigned int endOffset);  

   /** 
    * @return 
    * Return 'true' if the given token is part of a preprocessed code section.
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const bool isPreprocessedAt(const SETokenID tokenID) const;

   /** 
    * @return 
    * Return the first token in the preprocessed section under the given token. 
    * Return 0 if there are no preprocessed tokens at the given location.
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getFirstTokenIDPreprocessedAt(const SETokenID tokenID) const;
   /** 
    * @return 
    * Return the last token in the preprocessed section under the given token.
    * Return 0 if there are no preprocessed tokens at the given location.
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getLastTokenIDPreprocessedAt(const SETokenID tokenID) const;

   /** 
    * @return 
    * Return the first token in this token list, accounting for traversing 
    * preprocessed sections, which are searched in a depth-first manner. 
    * Return 0 if there are no tokens in this token list. 
    * <p> 
    * This function will ignore preprocessing if the search depth exceeds 
    * the depth limit of 256 levels. 
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getFirstTokenIDPreprocessed() const;
   /** 
    * @return 
    * Return the last token in this token list, accounting for traversing 
    * preprocessed sections, which are searched in a depth-first manner. 
    * Return 0 if there are no tokens in this token list. 
    * <p> 
    * This function will ignore preprocessing if the search depth exceeds 
    * the depth limit of 256 levels. 
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getLastTokenIDPreprocessed() const;
   /** 
    * @return 
    * Return the next token after the given token in this token list, 
    * accounting for traversing preprocessed sections, which are searched in 
    * a depth-first manner.  Return 0 if there are no tokens in this token list. 
    * <p> 
    * This function will ignore preprocessing if the search depth exceeds 
    * the depth limit of 256 levels. 
    * 
    * @param currTokenID   unique ID of token to continue after 
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getNextTokenIDPreprocessed(const SETokenID currTokenID) const;
   /** 
    * @return 
    * Return the previous token before the given token in this token list, 
    * accounting for traversing preprocessed sections, which are searched in 
    * a depth-first manner.  Return 0 if there are no tokens in this token list. 
    * <p> 
    * This function will ignore preprocessing if the search depth exceeds 
    * the depth limit of 256 levels. 
    *  
    * @param currTokenID   unique ID of token to continue after 
    * 
    * @see pushPreprocessedSection() 
    * @see popPreprocessedSection() 
    * @see getNumPreprocessedTokenLists() 
    * @see insertPreprocessedTokenList() 
    * @see getFirstTokenIDPreprocessed() 
    * @see getLastTokenIDPreprocessed()  
    * @see getNextTokenIDPreprocessed() 
    * @see getPrevTokenIDPreprocessed() 
    * @see getFirstTokenID() 
    * @see getLastTokenID()  
    * @see getNextTokenID() 
    * @see getPrevTokenID() 
    */
   const SETokenID getPrevTokenIDPreprocessed(const SETokenID currTokenID) const;
    
private:

   const class SEMainTokenList &getConstReference() const;
   class SEMainTokenList &getWriteReference();

   /**
    * Token list allocated at class construction.
    */
   SESharedPointer<SEMainTokenList> mpMainTokenList;

};

} // namespace slickedit


