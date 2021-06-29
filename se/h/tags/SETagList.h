////////////////////////////////////////////////////////////////////////////////
// Copyright 2019 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagList.h
// Description:   Declaration of class for collecting symbol information.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SETagInformation.h"
#include "tags/SETagFlags.h"
#include "tags/SETagTypes.h"
#include "tagsdb.h"
#include "slickedit/SESharedPointer.h"
#include "slickedit/SEString.h"


namespace slickedit {

// forward declarations
class SETokenList;

/**
 * This class is used to represent a set of symbols stored in memory. 
 * The set of symbols can be created from a parsing operation, or from 
 * a Context Tagging&reg; symbol search.
 *  
 * @see SETagInformation 
 * @see SEListTagsTarget 
 */
class VSDLLEXPORT SETagList 
{
public:
   /**
    * Default constructor
    */
   SETagList();

   /**
    * Copy constructor
    */
   SETagList(const SETagList& src);
   /**
    * Move constructor
    */
   SETagList(SETagList && src);

   /**
    * Destructor
    */
   virtual ~SETagList();

   /**
    * Assignment operator
    */
   SETagList &operator = (const SETagList &src);
   /**
    * Move assignment operator
    */
   SETagList &operator = (SETagList &&src);

   /**
    * Comparison operators
    */
   bool operator == (const SETagList &rhs) const;
   bool operator != (const SETagList &rhs) const;

   /**
    * Is this an unitialized item?
    */
   const bool isNull() const;
   /**
    * Is this an empty list of symbols?
    */
   const bool isEmpty() const;

   /**
    * @return 
    * Return an approximation of the number of bytes of storage required for 
    * this object. 
    */
   const size_t getStorageRequired() const; 

   /**
    * @return Return a pointer to the token list for this file. 
    *  
    * @param maybeAlloc    Allocate token list if this object is null. 
    */
   const SETokenList *getTokenList(const bool maybeAlloc=false) const;
   SETokenList *getTokenList(const bool maybeAlloc=false);
   /**
    * Plug in a specific token list object.  This should be used with care 
    * because the token list that is built when the file is parsed is the 
    * 'correct' token list for this object. 
    */
   void setTokenList(const SETokenList &tokenList);
   void setTokenList(SETokenList &&tokenList);
   
   /**
    * Initialize the token list if it was not already initialized.
    * 
    * @param fileName     file name corresponding to token list
    * @param bufferId     file buffer ID
    * @param bufferSize   number of bytes in buffer
    * 
    * @return 0 on success, &lt;0 on error.
    */
   int initializeTokenList(const slickedit::SEString &fileName,
                           const unsigned int bufferId,
                           const unsigned int bufferSize);

   /**
    * Save the token information for the given token.
    * 
    * @param tokenInfo     token information
    * 
    * @return 0 on success, &lt;0 on error.
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
    */
   int popPreprocessedSection();

   /** 
    * @return 
    * Find the corresponding token at the given seek position, and return it's 
    * token ID.  Return 0 if the token is not found. 
    * 
    * @param seekPosition   offset in bytes from the beginning of the file. 
    */
   const SETokenID findTokenAtOffset(const unsigned int seekPosition) const;

   /**
    * Merge the tagging information from the given file into this items 
    * tagging information.  Note that this method does not merge the token 
    * list for the respective symbols. 
    * 
    * @param tagList       tagging information to merge in 
    * @param pTokenIDMap   (optional) maps token ID's from original list to this list       
    * 
    * @return 0 on success, &lt;0 on error. 
    */
   int mergeTagList(const SETagList &tagList,
                    const SEArray<SETokenPair> *pTokenIDMap = nullptr);

   /**
    * Merge the given token list with this item.  The token list may be
    * from an embedded section, or contain a collection of embedded sections.
    * 
    * @param rhsTokenList                 token list to merge in
    * @param isEmbeddedSection            is 'rhsTokenList' from embedded code?
    * @param pEmbeddedStartSeekPositions  array of start offsets of embedded sections
    * @param pEmbeddedEndSeekPositions    parallel array of end offsets for embedded sections
    * @param numEmbeddedSections          number of embedded sections
    * @param pTokenIDMap                  (output) maps token ID's from original list to this list       
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
    * Insert a tag into the list of tags collected.
    * 
    * @param tagInfo             symbol information to add to the tag list.
    * @param checkForDuplicates  check if this symbol is already in the symbol list?
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         If tagging locals or the current tag list, this will return
    *         the tag list ID or local ID on success. 
    */
   int insertTag(const SETagInformation &tagInfo, const bool checkForDuplicates=false);
   int insertTag(SETagInformation &&tagInfo, const bool checkForDuplicates=false);
   /**
    * Insert a tag into the list of tags collected.
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
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         If tagging locals or the current tag list, this will return
    *         the tag list ID or local ID on success. 
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
                 const SEString &tagSignature = (const char *)0,
                 const SEString &classParents = (const char *)0,
                 const SEString &templateSignature = (const char *)0, 
                 const SEString &tagExceptions = (const char *)0 ); 

   /**
    * Copy and insert a tag from another tag list.
    * This method is primarily used for building search match sets. 
    *  
    * @param src                 instance to copy symbol from 
    * @param i                   index of symbol to copy 
    * @param checkForDuplicates  check if this symbol is already in the symbol list?
    * 
    * @return &gt;= 0 on success, &lt;0 on error. 
    *         This will return the tag list ID or local ID on success.
    */
   int insertTagFrom(const SETagList &src, const size_t i, const bool checkForDuplicate=false);

   /**
    * Modify the end line number and end seek position for the given tag.
    * 
    * @param tagIndex            index of tag to modify (starting with 0 for the first tag)
    * @param endLineNumber       end line number within file
    * @param endSeekPosition     end seek position within file
    * 
    * @return 0 on success, &lt;0 on error. 
    */
   int setTagEndLocation(const size_t tagIndex, 
                         const unsigned int endLineNumber, 
                         const unsigned int endSeekPosition); 

   /**
    * Return the number of tags collected.
    */
   const size_t getNumTags() const;

   /**
    * Return the n'th tag collected, starting with 0 for the first tag.
    * Return NULL if there is no such tag. 
    */
   const SETagInformation *getTagInfo(const size_t tagIndex) const;
   SETagInformation *getTagInfo(const size_t tagIndex);

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
    * Find the current tag list ID given the current file name and seek position.
    * 
    * @param fileName              full path to current file
    * @param currentLineNumber     current real line number
    * @param currentSeekPosition   current seek position of cursor within file
    * @param allowStatements       allow a statement to be the current item? 
    * @param allowOutlineOnly      allow symbols that are flagged as outline only
    * 
    * @return Returns the tag ID of the symbol (index+1) which the location 
    *         corresponds to.  Returns 0 if no symbol is found. 
    *  
    * @see isInCurrentTag() 
    */
   const unsigned int findCurrentTagId(const SEString &fileName, 
                                       const unsigned int currentLineNumber, 
                                       const unsigned int currentSeekPosition, 
                                       const bool allowStatements=false,
                                       const bool allowOutlineOnly=false) const;
   /** 
    * @return 
    * Return 'true' if the the given offset within the current file is 
    * within the symbol which had been recognized as the current tag list? 
    *  
    * @param seekPosition  offset within file 
    *  
    * @see findCurrentTagId() 
    * @see getCurrentTagId() 
    * @see getTagInfo() 
    */
   const bool isInCurrentTag(const unsigned int seekPosition) const;

   /**
    * @return 
    * Return the last symbol found using {@link findCurrentTagId()}. 
    */
   const unsigned int getCurrentTagId() const;

   /**
    * Search the set of symbols for a tag with the given name. 
    * This method will build a dictionary of tags for each name to make 
    * subsequent searches faster. 
    * 
    * @param tagListIdIterator   Index to resume search from, starts with 0.
    * @param tagName             Symbol name to search for
    * @param exactNameMatch      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive       Search for case-sensitive tag name match 
    * @param contextFlags        Specifies advanced tag name pattern matching options 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findTagWithName(const unsigned int tagListIdIterator,
                                      const SEString &tagName, 
                                      const bool exactNameMatch=true,
                                      const bool caseSensitive=true,
                                      const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;
   /**
    * Search the set of symbols for a tag in the given class. 
    * This method will build a dictionary of tags for each class name to make 
    * subsequent searches faster.
    * 
    * @param tagListIdIterator   Index to resume search from, starts with 0.
    * @param tagName             Symbol name to search for
    * @param className           Symbol class name to search for
    * @param exactNameMatch      Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive       Search for case-sensitive class name match 
    * @param contextFlags        Specifies advanced tag name pattern matching options 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findTagInClass(const unsigned int tagListIdIterator,
                                     const SEString &tagName, 
                                     const SEString &className, 
                                     const bool exactNameMatch = true,
                                     const bool caseSensitive=true,
                                     const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;
   /**
    * Search the set of symbols for a tag with the given tag type.
    * This method will build a dictionary of tags for each tag type to make 
    * subsequent searches faster.
    * 
    * @param tagListIdIterator   Index to resume search from, starts with 0.
    * @param tagType             Tag type to search for
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findTagWithTagType(const unsigned int tagListIdIterator, 
                                         const SETagType tagType) const;

   /**
    * Find a tag at the given start location.
    * 
    * @param tagListIdIterator   Index to resume search from, starts with 0.
    * @param startLineNumber     Line number of item to search for, ignored if 0.
    * @param startSeekPosition   Seek position of item to search for, ignored if 0. 
    * 
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findTagStartingAt(const unsigned int tagListIdIterator,
                                        const unsigned int startLineNumber,
                                        const unsigned int startSeekPosition) const;

   /**
    * Search the set of symbols for a tag matching the given tag name, class name, 
    * and other properties. 
    *  
    * @param tagListIdIterator      Symbol ID iterator used to iterate though multiple matches 
    * @param tagPrefix              Tag name prefix to search for matches to
    * @param className              Class name to search for matches in 
    * @param exactNameMatch         Search for exact tag name match (rather than prefix match) 
    * @param caseSensitive          Search for case-sensitive tag name match 
    * @param passThroughAnonymous   Pass through all anonymous (unnamed) symbols 
    * @param passThroughTransparent Pass through all transparent / opaque symbols, 
    *                               such as enumerated types which do not have to be qualified
    * @param skipIgnored            Skip symbols with SE_TAG_FLAG_ignore tag flag set
    * @param contextFlags           Specifies advanced tag name pattern matching options 
    *  
    * @return 
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findTag(unsigned int tagListIdIterator,
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
    * @param tagListIdIterator      Symbol ID iterator used to iterate though multiple matches 
    * @param tagInfo                Symbol to search for a match to
    * @param lineMustMatch          Check if line number matches exactly
    * 
    * @return
    * Returns 0 if no more symbols are found.  Returns the index+1 
    * (tag list ID) of the symbol if it finds a match.
    */
   const unsigned int findMatchingTag(unsigned int tagListIdIterator,
                                      const slickedit::SETagInformation &tagInfo, 
                                      const bool lineMustMatch=true) const;

   /**
    * Locate the tag list ID of the symbol which encloses the given symbol, 
    * which is expected to be a symbol in this set of symbols. 
    * 
    * @param tagInfo     symbol information
    * 
    * @return Returns the index+1 (tag list ID) of the symbol it finds. 
    *         Returns 0 for top-level symbols. 
    */
   const int findOuterTagId(const slickedit::SETagInformation &tagInfo) const;
   /**
    * @return 
    * Return the tag list ID of the symbol which encloses the given symbol, 
    * which is expected to be a symbol in this set of symbols. 
    * 
    * @param pTagInfo   pointer to symbol information.
    */
   const unsigned int getOuterTagId(slickedit::SETagInformation *pTagInfo) const;
   /** 
    * @return 
    * Returns the next sibling of the given item in the set of symbols which 
    * is enclosed by the same 'outer' symbol. 
    * Returns 0 if there is no such symbol.
    * 
    * @param tagId      Tag ID (index+1) of starting symbol.
    */
   const unsigned int findNextSiblingTagId(const unsigned int tagId) const;
   /** 
    * @return 
    * Returns the previous sibling of the given item in the set of symbols which 
    * is enclosed by the same 'outer' symbol. 
    * Returns 0 if there is no such symbol.
    * 
    * @param tagId      Tag ID (index+1) of starting symbol.
    */
   const unsigned int findPrevSiblingTagId(const unsigned int tagId) const;

   /**
    * Sort the list of tags by seek position.
    */
   int sortTags();

   /**
    * Based on symbol start and seek positions, as well as symbol types, 
    * conpute the symbol nesting (aka, outer tag list ids) for all the symbols 
    * in the list. 
    */
   void computeOuterTagIds();

   /**
    * Set the date which each symbol was tagged.
    */
   void setDateTaggedForAllSymbols(const VSUINT64 taggedDate);

   /**
    * Clear all the tags in this list.
    */
   void clearTags();

   /**
    * Clear the token list.
    */
   void clearTokenList();

   /**
    * Reset the context tagging find method caches.
    */
   void resetFindCaches();

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
    *            Remove tag matches that are found in the current symbol tag list.
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


protected:

   /**
    * Add the given symbol's name to the tag name index if the tag name index 
    * is active. 
    * 
    * @param tagInfo       symbol information (including tag name)
    * @param tagId         index+1 of tag name in list of tags 
    *  
    * @see findTagWithName() 
    * @see insertTag() 
    */
   void addToTagNameIndex(const cmROStringUtf8 &tagName, const cmROStringUtf8 &className, const unsigned int tagId);


private:

   const class SEPrivateTagList &getConstReference() const;
   class SEPrivateTagList &getWriteReference();

   // Pointer to private implementation of tagging target
   SESharedPointer<SEPrivateTagList> mpTagList;

};

} // namespace slickedit


extern const slickedit::SETagList gNullTagList;

