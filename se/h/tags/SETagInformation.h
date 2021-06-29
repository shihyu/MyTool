////////////////////////////////////////////////////////////////////////////////
// Copyright 2017 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////
// File:          SETagInformation.h
// Description:   Declaration of class for storing symbol information.
////////////////////////////////////////////////////////////////////////////////
#pragma once
#include "vsdecl.h"
#include "tags/SETagTypes.h"
#include "tags/SETagFlags.h"
#include "tags/SETagFilterFlags.h"
#include "tags/SETokenInterface.h"
#include "tags/SETagDocCommentTypes.h"
#include "slickedit/SEString.h"
#include "slickedit/SEHashSet.h"
#include "slickedit/SESharedPointer.h"

namespace slickedit {

// forward declarations
class SETokenList;

/**
 * This class represents a symbol, also known as a "tag" that is identified 
 * by the symbol parsing system as a declaration of a symbol, definition of 
 * a symbol, or a general statement as discovered by the language specific 
 * parsing engine. 
 *  
 * The class is used to represent the symbol in memory, and also to 
 * set and query it's properties.  It can also map itself to the tag information 
 * used in the interpreter. 
 */
class VSDLLEXPORT SETagInformation 
{
public:
   /**
    * Default constructor
    */
   SETagInformation();

   /**
    * Simple constructor
    */
   SETagInformation(const SEString &tagName, 
                    const SEString &tagClass, 
                    const SETagType tagType,
                    const SETagFlags tagFlags=SE_TAG_FLAG_NULL);

   /**
    * All information constructor 
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
    */
   SETagInformation( const SEString &tagName,
                     const SEString &tagClass,
                     const SETagType tagType,
                     const SETagFlags tagFlags,
                     const SEString &fileName,
                     const unsigned int startLineNumber, 
                     const unsigned int startSeekPosition,
                     const unsigned int nameLineNumber,  
                     const unsigned int nameSeekPosition,
                     const unsigned int scopeLineNumber, 
                     const unsigned int scopeSeekPosition,
                     const unsigned int endLineNumber,   
                     const unsigned int endSeekPosition,
                     const SEString &tagSignature      = (const char *)nullptr,
                     const SEString &classParents      = (const char *)nullptr,
                     const SEString &templateSignature = (const char *)nullptr, 
                     const SEString &tagExceptions     = (const char *)nullptr,
                     const SETagDocCommentType docType = SE_TAG_DOCUMENTATION_NULL, 
                     const SEString &docComments       = (const char *)nullptr );

   /**
    * Copy constructor
    */
   SETagInformation(const SETagInformation& src);

   /**
    * Move constructor
    */
   SETagInformation(SETagInformation&& src);

   /**
    * Destructor
    */
   virtual ~SETagInformation();

   /**
    * Assignment operator
    */
   SETagInformation &operator = (const SETagInformation &src);
   /**
    * Move assignment operator
    */
   SETagInformation &operator = (SETagInformation &&src);

   /**
    * Comparison operators
    */
   bool operator == (const SETagInformation &src) const;
   bool operator != (const SETagInformation &src) const;
   bool operator <  (const SETagInformation &src) const;
   bool operator <= (const SETagInformation &src) const;
   bool operator >  (const SETagInformation &src) const;
   bool operator >= (const SETagInformation &src) const;

   /**
    * Return the space required for this symbol.
    */
   const size_t getStorageRequired() const;

   /**
    * Hash function,used by SEHashSet
    */
   unsigned int hash() const;

   /**
    * Clear the contents of this symbol.
    */
   void clear();
   /**
    * @return Return 'true' if this object is in it's initial state.
    */
   const bool isEmpty() const;

   /**
    * Compare two tag information objects by seek position and containment.
    * 
    * @param c1   tag information
    * @param c2   tag information
    */
   static int compareTags(const SETagInformation *c1, const SETagInformation *c2);

   /**
    * Compare two tags for file-position independent equality 
    * (including all fields except line numbers and seek positions). 
    * <p> 
    * It also does not compare language ID, tag file name, 
    * and the tag flags set. 
    */
   static int compareExceptLocations(const SETagInformation &lhs, const SETagInformation &rhs);

   /**
    * Compare two tag information objects for sorting by insert order in 
    * the Defs tool window. 
    */
   static int compareByLocations(const SETagInformation &lhs, const SETagInformation &rhs);

   /**
    * Get symbol tag name
    */
   SEString getTagName() const;
   /**
    * Get a native reference to the symbol tag name
    */
   const cmStringUtf8 & getTagNameRef() const;
   /**
    * Get a null-terminated Utf-8 string pointer to the symbol tag name
    */
   const char * getTagNamePointer() const;
   /**
    * Get the length of the tag name string.
    */
   const size_t getTagNameLength() const;
   /**
    * Is the symbol tag name empty?
    */
   const bool isTagNameEmpty() const;
   /**
    * Set symbol tag name 
    */
   void setTagName(const SEString &tagName);
   void setTagName(const char *tagName);
   void setTagName(const cmROStringUtf8 &tagName);
   void setTagName(const cmROFatStringUtf8 &tagName);
   void setTagName(const cmThinStringUtf8 &tagName);
   void setTagName(const cmStringUtf8 &tagName);
   void setTagName(cmStringUtf8 &&tagName);
   /**
    * Append text to the tag name, typically used for statement tagging.
    */
   void appendTagName(const SEString &str);
   void appendTagName(const char *tagName);
   void appendTagName(const cmROStringUtf8 &tagName);
   void appendTagName(const cmROFatStringUtf8 &tagName);
   void appendTagName(const cmThinStringUtf8 &tagName);
   
   /**
    * Get the symbol class and namespace name
    */
   SEString getClassName() const;
   /**
    * Get a native reference to the symbol class and namespace name
    */
   const cmThinStringUtf8 & getClassNameRef() const;
   /**
    * Get a null-terminated Utf-8 string pointer to the symbol class and namespace name
    */
   const char * getClassNamePointer() const;
   /**
    * Get the length of the class name string.
    */
   const size_t getClassNameLength() const;
   /**
    * Is the symbol class/namespace name empty (global scope)?
    */
   const bool isClassNameEmpty() const;
   /**
    * Set the symbol class and namespace name
    */
   void setClassName(const SEString &className);
   void setClassName(const char *className);
   void setClassName(const cmROStringUtf8 &className);
   void setClassName(const cmROFatStringUtf8 &className);
   void setClassName(const cmThinStringUtf8 &className);
   void setClassName(cmThinStringUtf8 &&className);
   /**
    * Get just the package name part of the class name 
    */
   SEString getPackageNamePart() const;
   /**
    * Get just the class name part of the class name
    */
   SEString getClassNamePart() const;
   /**
    * Get just the last identifier in the package name part of the class name 
    */
   SEString getPackageNameOnly() const;
   /**
    * Get just the last identifier in the class name part of the class name
    */
   SEString getClassNameOnly() const;

   /*
    * Get the qualified class name for this symbol. 
    * For non-class and non-package types, this will simply be the class name. 
    * For class and package types, this will be the class name with the 
    * current symbols name appended appropriately. 
    */
   SEString getQualifiedClassname() const;

   /**
    * Get the symbol tag type SE_TAG_TYPE_*
    */
   const SETagType getTagType() const;
   /**
    * Get the symbol string associatated with the given tag type
    */
   SEString getTagTypeName() const;
   const char *getTagTypeNamePointer() const;
   /**
    * Set the symbol tag type
    */
   void setTagType(const SETagType tagType);
   void setTagType(const SEString &tagTypeName);
   /**
    * Is this a statement tag?
    */
   bool isStatementType() const;
   /**
    * Is the given type a statement tag?
    */
   static bool isStatementType(const SETagType tagType);

   /**
    * Get the symbol tag flags, which are a bitset of SE_TAG_FLAG_*
    */
   const SETagFlags getTagFlags() const;
   /**
    * Set the symbol tag flags, which are a bitset of SE_TAG_FLAG_*
    */
   void setTagFlags(const SETagFlags tagFlags);
   /**
    * Set the given tag flags if they are not already set (OR them in to bitset).
    */
   void addTagFlags(const SETagFlags tagFlags);
   /**
    * Unset the given tag flags if they are set (NAND them out of bitset).
    */
   void removeTagFlags(const SETagFlags tagFlags);

   /**
    * Get the symbol token type SETOKEN_*. 
    * This is used for statement tagging only. 
    */
   const SETokenType getTokenType() const;
   /**
    * Set the statement token type.
    * This is used for statement tagging only. 
    */
   void setTokenType(const SETokenType tokenType);

   /**
    * Set general symbol information
    */
   void setSymbolInformation(const SEString &tagName, 
                             const SEString &tagClass, 
                             const SETagType tagType,
                             const SETagFlags tagFlags=SE_TAG_FLAG_NULL,
                             const SEString &tagSignature = (const char *)nullptr);

   /**
    * All information setter
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
    */
   void setTagInformation( const SEString &tagName,
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
    * Return the ID of the symbol which encloses this symbol. 
    * This only applies to locals and the current context. 
    */
   const int getOuterContextId() const;
   /**
    * Set the ID of the symbol which encloses this symbol.
    * This only applies to locals and the current context. 
    */
   void setOuterContextId(const int contextId);
   /**
    * Reset the the ID of the symbol which encloses this symbol.
    * This only applies to locals and the current context. 
    */
   void resetOuterContextId();
   /** 
    * @return 
    * Return 'true' if the context ID of the outer container for this item 
    * has been determined.
    */
   const bool isOuterContextKnown() const;
   /**
    * @return 
    * Returns 'true' if this symbol can serve as a container for other symbols. 
    * Returns 'false' if we have not determinded if this symbol can be a container. 
    */
   const bool isContainer() const;
   /**
    * @return 
    * Returns 'true' if this symbol can serve as a container for other symbols. 
    * Returns 'true' if we have not determinded if this symbol can be a container. 
    * Returns 'false' if this symbol is definately not a container. 
    */
   const bool isContainerMaybe() const;
   /**
    * @return 
    * Return 'true' if we have determined if this symbol can be a container. 
    */
   const bool isContainerKnown() const;
   /**
    * Indicate that we do not know if this item is a container or not.
    */
   void resetIsContainer(const bool true_or_false=true);
   /**
    * Indicate if this symbol can serve as a container (that is, an outer context) 
    * for other symbols.
    */
   void setIsContainer(const bool true_or_false=true);

   /**
    * Return the seek position of the statement (or symbol) 
    * used to pull in the file containing this symbol. 
    * For example, a #include in C/C++ or a COPY statement in COBOL. 
    *  
    * This only applies to locals and the current context. 
    */
   const unsigned int getIncludeStatementSeekPosition() const;
   /**
    * Saves the seek position of the statement (or symbol) used to pull in 
    * the file containing this symbol.  For example, if this symbol comes 
    * form expanding a #include in C/C++ or a COPY statement in COBOL. 
    *  
    * This only applies to locals and the current context. 
    */
   void setIncludeStatementSeekPosition(const unsigned int startSeekPosition);

   /**
    * Return the file name which this symbol belongs to. 
    * <p> 
    * Note that a file name can have multiple parts, an originating file, 
    * and a current file. 
    */
   SEString getFileName() const;
   /**
    * Get a native reference to the file name which this symbol belongs to
    */
   const cmThinStringUtf8 & getFileNameRef() const;
   /**
    * Get a null-terminated Utf-8 string pointer to the file name which this symbol belongs to
    */
   const char * getFileNamePointer() const;
   /**
    * Get the length of the file name string.
    */
   const size_t getFileNameLength() const;
   /**
    * Is the file name not set?
    */
   const bool isFileNameEmpty() const;
   /**
    * Return the just the name of the current file which this symbol belongs to. 
    * @see getFileName() 
    */
   SEString getFileNameOnly() const;
   /**
    * Return the name of the originating file which ultimately included 
    * the current file which this symbol belongs to. 
    * @see getFileName() 
    */
   SEString getFileNameIncludedBy() const;
   /**
    * Set the file name which this symbol belongs to.
    * <p> 
    * Note that a file name can have multiple parts, an originating file, 
    * and a current file. 
    */
   void setFileName(const SEString &fileName);
   void setFileName(const char *fileName);
   void setFileName(const cmROStringUtf8 &fileName);
   void setFileName(const cmROFatStringUtf8 &fileName);
   void setFileName(const cmThinStringUtf8 &fileName);
   void setFileName(cmThinStringUtf8 &&fileName);

   /**
    * Return the language ID for the source code this symbol is in.
    */
   SEString getLanguageId() const;
   /**
    * Set the language ID for the source code this symbol is in.
    */
   void setLanguageId(const SEString &langId); 
   void setLanguageId(const cmROStringUtf8 &langId); 

   /**
    * Get the start token ID for this symbol 
    */
   SETokenID getStartTokenID() const;
   /**
    * Get the start seek position of this symbol 
    */
   unsigned int getStartSeekPosition() const;
   unsigned int getStartSeekPosition(const class SETokenList &tokenList) const;
   /**
    * Get the start line number of this symbol
    */
   unsigned int getStartLineNumber() const;
   unsigned int getStartLineNumber(const class SETokenList &tokenList) const;
   /**
    * Set the start location for this symbol 
    *  
    * @param seekPosition seek position within file 
    * @param lineNumber   line number 
    * @param tokenID      unique identifier for this token in 'pTokenList' 
    */
   void setStartLocation(unsigned int seekPosition, unsigned int lineNumber, SETokenID tokenID=0);
   /**
    * Set the start token ID and token list for this symbol.
    *  
    * @param tokenID      unique identifier for this token in 'pTokenList' 
    * @param pTokenList   Pointer to token list.  This pointer must be a pointer 
    *                     acquired from {@link SEListTagsTarget}. 
    */
   void setStartTokenID(SETokenID tokenID);
   /**
    * Use the given token to record the start location for this symbol 
    * and save the token list for this symbol.
    *  
    * @param tokenInfo    information about the current token
    * @param pTokenList   Pointer to token list.  This pointer must be a pointer 
    *                     acquired from {@link SEListTagsTarget}. 
    */
   void setStartToken(const class SETokenReadInterface &tokenInfo);
                                                       
   /**
    * Get the token ID for the start of the name of this symbol.
    */
   SETokenID getNameTokenID() const;
   /**
    * Get the seek position of the name of this symbol
    */
   unsigned int getNameSeekPosition() const;
   unsigned int getNameSeekPosition(const class SETokenList &tokenList) const;
   /**
    * Get the line number where the name of this symbol is located.
    */
   unsigned int getNameLineNumber() const;
   unsigned int getNameLineNumber(const class SETokenList &tokenList) const;
   /**
    * Set the location of the name of this symbol
    */
   void setNameLocation(unsigned int seekPosition, unsigned int lineNumber, SETokenID tokenID=0);
   /**
    * Set the token ID indicating the location of the name of this symbol.
    */
   void setNameTokenID(SETokenID tokenID);
   /**
    * Use the given token to record the location of the name of this symbol.
    */
   void setNameToken(const class SETokenReadInterface &tokenInfo);

   /**
    * Get the token ID for the start of scope for this symbol
    */
   SETokenID getScopeTokenID() const;
   /**
    * Get the scope seek position for this symbol.  This is the seek position 
    * where the scope of a symbol begins, such as the open brace for a C/C++ 
    * function definition. 
    */
   unsigned int getScopeSeekPosition() const;
   unsigned int getScopeSeekPosition(const class SETokenList &tokenList) const;
   /**
    * Get the scope line number for this symbol.
    */
   unsigned int getScopeLineNumber() const;
   unsigned int getScopeLineNumber(const class SETokenList &tokenList) const;
   /**
    * Set the start scope location for this symbol.
    */
   void setScopeLocation(unsigned int seekPosition, unsigned int lineNumber, SETokenID tokenID=0);
   /**
    * Set the token ID indicating the start scope location of this symbol.
    */
   void setScopeTokenID(SETokenID tokenID);
   /**
    * Use the given token to record the start scope location of this symbol.
    */
   void setScopeToken(const class SETokenReadInterface &tokenInfo);

   /**
    * Get the end token ID for this symbol 
    */
   SETokenID getEndTokenID() const;
   /**
    * Get the end seek position for this symbol.
    */
   unsigned int getEndSeekPosition() const;
   unsigned int getEndSeekPosition(const class SETokenList &tokenList) const;
   /**
    * Get the end line number for this symbol.
    */
   unsigned int getEndLineNumber() const;
   unsigned int getEndLineNumber(const class SETokenList &tokenList) const;
   /**
    * Set the end location for this symbol 
    */
   void setEndLocation(unsigned int seekPosition, unsigned int lineNumber, SETokenID tokenID=0);
   /**
    * Set the token ID indicating the end location for this symbol.
    */
   void setEndTokenID(SETokenID tokenID);
   /**
    * Use the given token to record the end location for this symbol.
    */
   void setEndToken(const class SETokenReadInterface &tokenInfo);

   /**
    * Get the start line number for this symbol according to the database.
    */
   const unsigned int getTaggedLineNumber() const;
   /**
    * Set the start line number for this symbol according to the database.
    */
   void setTaggedLineNumber(const unsigned int lineNumber);

   /**
    * Get the date and time which this file was last tagged. 
    * The result is a number of the form YYYYMMDDhhmmssppp. 
    */
   const VSUINT64 getTaggedDate() const;
   /**
    * Set the date which the file this symbol is in was last tagged.
    * The date is a 64-bit number of the form YYYYMMDDhhmmssppp. 
    */
   void setTaggedDate(const VSUINT64 date);

   /**
    * Update the token IDs for this symbol (if they are not already set). 
    *  
    * @param pTokenList   token list for the current file 
    * @param force        force recalculation even if symbol already has token IDs. 
    */
   void updateTokenIds(const SETokenList *pTokenList, const bool force=false);

   /**
    * @return 'true' if the tag spans the given offset 
    *  
    * @see getStartSeekPosition()
    * @see getEndSeekPosition()
    */
   const bool isSpanningOffset(const unsigned int offset) const;
   const bool isSpanningOffset(const unsigned int offset, const class SETokenList &tokenList) const;
   /**
    * @return 'true' if the tag spans the given line number 
    *  
    * @see getStartLineNumber() 
    * @see getEndLineNumber() 
    */
   const bool isSpanningLine(const unsigned int lineNumber) const;
   const bool isSpanningLine(const unsigned int lineNumber, const class SETokenList &tokenList) const;

   /**
    * Get the name of the tag database which this symbol was discovered 
    * in (used when searching for symbols).
    */
   SEString getTagFileName() const;
   /**
    * Set the name of the tag database which this symbol was discovered in 
    * and optionally the line number it is located at according to the tag 
    * database. 
    */
   void setTagFileName(const SEString &tagFileName, const unsigned int line_no=0);
   void setTagFileName(const char *tagFileName, const unsigned int line_no=0);
   void setTagFileName(const cmROStringUtf8 &className, const unsigned int line_no=0);
   void setTagFileName(const cmROFatStringUtf8 &className, const unsigned int line_no=0);
   void setTagFileName(const cmThinStringUtf8 &className, const unsigned int line_no=0);
   void setTagFileName(cmThinStringUtf8 &&className, const unsigned int line_no=0);

   /**
    * Get the contents of the documentation comment for this symbol.
    */
   const bool hasDocumentationComment() const;
   /**
    * Get the contents of the documentation comment for this symbol.
    */
   SEString getDocumentationCommentText() const;
   /**
    * Get the raw contents of the documentation comment for this symbol.
    */
   SEString getCompositeDocumentationComment() const;
   /**
    * Translate the given documentation comment to HTML and return it as HTML. 
    */
   SEString getDocumentationCommentAsHTML() const;
   /**
    * Get the type of the documentation comment for this symbol.
    */
   const SETagDocCommentType getDocumentationCommentType() const;
   /**
    * Set the documentation comment for this symbol.
    *  
    * @param commentType   documentation comment type
    * @param commentText   documentation comment text (including comment characters and newlines for JavaDoc and XMLDoc) 
    */
   void setDocumentationComment(const SETagDocCommentType commentType, const SEString &commentText);

   /**
    * Retrieve all location information for this symbol
    */
   void getLocationInformation(SEString &fileName,
                               SEString &langId,
                               unsigned int &startSeekPosition, unsigned int &startLineNumber,
                               unsigned int &nameSeekPosition,  unsigned int &nameLineNumber,
                               unsigned int &scopeSeekPosition, unsigned int &scopeLineNumber,
                               unsigned int &endSeekPosition,   unsigned int &endLineNumber,
                               SEString &tagFileName, unsigned int &taggedLineNumber,
                               VSUINT64 &taggedDate) const;

   /**
    * Set all location information for this symbol
    */
   void setLocationInformation(const SEString &fileName,
                               const SEString &langId,
                               unsigned int startSeekPosition, unsigned int startLineNumber,
                               unsigned int nameSeekPosition,  unsigned int nameLineNumber,
                               unsigned int scopeSeekPosition, unsigned int scopeLineNumber,
                               unsigned int endSeekPosition,   unsigned int endLineNumber,
                               const SEString &tagFileName = (const char *)nullptr,
                               unsigned int taggedLineNumber=0,
                               VSUINT64 taggedDate=0);

   /**
    * Get the symbol signature or argument list 
    *  
    * @param prettyPrint   add spaces to make argument list look better. 
    */
   SEString getSignature(const bool prettyPrint=false) const;
   /**
    * Set the symbol signature or argument list
    */
   void setSignature(const SEString &argumentList);

   /**
    * Get the template signature or template argument list
    *  
    * @param prettyPrint   add spaces to make argument list look better. 
    */
   SEString getTemplateSignature(const bool prettyPrint=false) const;
   /**
    * Set the template signature or argument list
    */
   void setTemplateSignature(const SEString &templateSignature);

   /**
    * Get the symbol return type
    */
   SEString getReturnType() const;
   /**
    * Get the symbol return type only (without initializer expression)
    */
   SEString getReturnTypeOnly() const;
   /**
    * Get the symbol return type initializer expression. 
    * This is used for type inference. 
    */
   SEString getReturnTypeValue() const;
   /**
    * Set the symbol return type or declared symbol type
    */
   void setReturnType(const SEString &returnType);

   /**
    * Get the function exception list
    */
   SEString getExceptions() const;
   /**
    * Set the function exception list
    */
   void setExceptions(const SEString &exceptions);

   /**
    * Get composite return type and signature and exceptions information.
    */
   SEString getCompositeSignature() const;
   /**
    * Save composit return type and signature and exceptions information.
    */
   void setCompositeSignature(const SEString &signature);

   /**
    * Get the symbol class parents (separated by semicolons)
    */
   SEString getClassParents() const;
   /**
    * Set the symbol class parents (separated by semicolons)
    */
   void setClassParents(const SEString &classParents);

   /**
    * Copy the given Slick-C tag information to this object. 
    *  
    * @param hvar 
    * The hvar given can be either a string, encoded as a tag info string, 
    * or an instance of the class se.tags.SymbolInfo or an instance of 
    * the struct VS_TAG_BROWSE_INFO. 
    *  
    * @return Returns 0 on success, &lt;0 on error. 
    *  
    * @see loadFromSymbolInfo() 
    * @see loadFromTagBrowseInfo() 
    * @see loadFromTagInfoString() 
    */
   int loadFromHvar(VSHREFVAR hvar);

   /**
    * Initialize the given Slick-C VS_TAG_BROWSE_INFO struct.
    */
   static void initTagBrowseInfo(VSHREFVAR browseInfoHvar); 
   /**
    * Export this object to the given Slick-C VS_TAG_BROWSE_INFO struct 
    */
   void saveAsTagBrowseInfo(VSHREFVAR browseInfoHvar) const;
   /**
    * Copy the given Slick-C VS_TAG_BROWSE_INFO struct to this object.
    */
   void loadFromTagBrowseInfo(VSHREFVAR browseInfoHvar);

   /**
    * Initialize the given Slick-C se.tags.SymbolInfo class.
    */
   static void initSymbolInfo(VSHREFVAR symbolInfoHvar);
   /**
    * Export this object to the given Slick-C se.tags.SymbolInfo class.
    */
   void saveAsSymbolInfo(VSHREFVAR symbolInfoHvar) const;
   /**
    * Copy the given Slick-C se.tags.SymbolInfo class instance to this object.
    */
   void loadFromSymbolInfo(VSHREFVAR symbolInfoHvar);

   /**
    * Create the canonical tag display string of the form:
    * <PRE>
    *    tag_name(class_name:type_name)flags(signature)return_type
    * </PRE>
    * This is used to speed up find-tag and maketags for languages that
    * do not insert tags from DLLs.
    *
    * @param proc_name     (output) set to tag info string
    */
   void saveToTagInfoString(SEString &proc_name) const;

   /**
    * Decompose the canonical tag display string of the form:
    * <PRE>
    *    tag_name(class_name:type_name)flags(signature)return_type
    * </PRE>
    * This is used to speed up find-tag and maketags for languages that
    * do not insert tags from DLLs.
    *
    * @param proc_name        tag display string
    */
   void loadFromTagInfoString(const SEString &proc_name);

   /**
    * Load this symbol from the tag database. 
    *  
    * @param dbHandle    database session handle 
    * @param recordLoc   encoded database record seek position on disk 
    */
   int loadTagFromDatabase(int dbHandle, size_t recordLoc);

   /**
    * Insert the symbol into the tagging database for the currently open database.
    *  
    * @param dbHandle    database sessio handle 
    * @param pRecordLoc  set to encoded database record seek position on disk 
    */
   int insertTagInDatabase(int dbHandle, size_t *pRecordLoc=nullptr) const;

   /**
    * Propagate tag flags from this symbol to other related symbols, and vice-versa
    */
   int propagateTagFlagsInDatabase(int dbHandle, 
                                   SETagFlags &newTagFlags,
                                   const SEHashSet<SETagInformation> *oldTags = nullptr,
                                   SEHashSet<SETagInformation> *relatedTags = nullptr) const;

   /**
    * Propagate tag flags from this symbol to other related symbols, and vice-versa
    */
   int propagateTagFlagsInContext(class SEListTagsTarget &context);
   int propagateTagFlagsInContext(class SETagList &context);

   /**
    * Find an exact match for this tag in the tagging database.
    * 
    * @param dbHandle   tag database handle 
    * @param recordLoc  (output) set to record location in database on success
    * 
    * @return 0 on success, <0 on error. 
    */
   int findInDatabase(int dbHandle, size_t &recordLoc) const;

   /**
    * Remove one tag from the database exactly matching this tag.
    * 
    * @param dbHandle   tag database handle
    * 
    * @return 0 on success, <0 on error. 
    */
   int removeFromDatabase(int dbHandle) const;

   /**
    * Update the file location for this tag in the database. 
    * This is used only to change the tag's start line number. 
    * Since that doesn't effect any indexing, it is done in place 
    * on the database for effeciency. 
    * 
    * @param dbHandle   tag database handle 
    * @param line_no    new line number to plug in 
    * @param tag_flags  new tag flags set to plug in 
    * 
    * @return 0 on success, <0 on error. 
    */
   int updateLineAndFlagsInDatabase(int dbHandle, const int line_no, const SETagFlags tag_flags) const;


   /**
    * Insert the symbol into the current context.
    */
   int insertTagInContext(bool allowStatements=true) const;

   /**
    * Insert the symbol into the set of locals.
    */
   int insertTagInLocals() const;

   /**
    * Insert the symbol into a tree control.
    */
   int insertInTree(int treeWid, 
                    int treeIndex,
                    int treeFlags,
                    bool includeTab, 
                    int forceLeafNode, 
                    bool includeSignature, 
                    bool includeClassName, 
                    VSHVAR user_info=0) const;

   /**
    * Insert the symbol into a tree control for XML outline mode.
    */
   int insertInTreeOutline(int treeId, 
                           int treeIndex,
                           int treeFlags,
                           bool includeTab, 
                           bool includeSignature,
                           bool includeClassName,
                           const char *pszNodeText=0,
                           VSHVAR userInfo=0 ) const;

   /** 
    * @return 
    * Returns 'true' if the given file/line/seekpos is still within the context 
    * of this symbol.  Returns 'false' otherwise.
    * 
    * @param fileName        Source filename to compare against
    * @param linenum         Current line number
    * @param seekpos         Current real offset within current buffer
    * @param allowStatements Allow statement types?   
    */
   const bool isCurrentContext(const SEString &fileName,
                               const unsigned int linenum, 
                               const unsigned int seekpos,
                               const bool allowStatements=false) const;

   /** 
    * @return 
    * Return 'true' if the tag filters match for the this symbol.
    * 
    * @param contextFlags        Context tagging search options.
    * @param filterFlags         Tag filtering options.
    * @param localScopeSeekpos   Local variable scope seek position.
    */
   const bool isFilterMatch(const SETagContextFlags contextFlags = SE_TAG_CONTEXT_ANYTHING,
                            const SETagFilterFlags  filterFlags  = SE_TAG_FILTER_ANYTHING) const;

   /**
    * @return 
    * Return 'true' if the given tag name pattern matches this symbol name
    * in accordance with the options specified for symbol matching strategies. 
    * 
    * @param tagNamePattern      tag name pattern to search for (must be non-null)
    * @param exactNameMatch      do we expect to match the entire symbol?
    * @param caseSensitive       are we looking for a case-sensitive or case-insensitive match?
    * @param contextFlags        bitset of pattern matching flags (SE_TAG_CONTEXT_MATCH_*)
    */
   const bool isPatternMatch(const slickedit::SEString &tagNamePattern,
                             const bool exactNameMatch=true,
                             const bool caseSensitive=true,
                             const SETagContextFlags contextFlags=SE_TAG_CONTEXT_NULL) const;

   /** 
    * @return 
    * Return 'true' if the given identifier matches this symbol name after 
    * correcting a transposed character, missing character, or repeated character. 
    *  
    * @param identifier_prefix    identifier prefix to attempt to correct
    * @param case_sensitive       are we looking for a case-sensitive or case-insensitive match? 
    * @param start_col            column to start corrections at 
    *                             (assumes prefix up to that point matches) 
    */
   const bool isCorrectableMatch(const slickedit::SEString &identifierPrefix,
                                 const bool caseSensitive=true,
                                 const int start_col=0) const;


private:

   // all access to the private data goes through these functions
   const struct SEPrivateTagInformation &getConstReference() const;
   struct SEPrivateTagInformation &getWriteReference();

   // Pointer to private implementation of tag information
   SESharedPointer<SEPrivateTagInformation> mpTagInformation;

};

} // namespace slickedit

